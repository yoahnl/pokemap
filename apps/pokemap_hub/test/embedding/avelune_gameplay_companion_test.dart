import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_hub/embedding/avelune_gameplay_companion.dart';
import 'package:pokemap_hub/embedding/avelune_gameplay_companion_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'battle input relay uses the attached battle envelope and resets its owner',
    () async {
      final owner = AveluneGameplayCompanionOwner();
      addTearDown(owner.dispose);
      final port = _Port()..battle = _battleFixture();
      owner.start('battle-session');
      owner.bind(port);
      await owner.refresh();
      const press = RuntimeInputEvent.press(RuntimeInputControl.down);
      expect(owner.inputPayload(press), isNull);
      owner.setCompanionAttached('battle-session', true);
      final current = owner.value!;
      final input = owner.inputPayload(press)!;
      expect(input['mode'], 'battle');
      expect(input['battleRevision'], 20);
      expect(input['battleMode'], 'fight');
      final intent = {
        ..._intent(current),
        'kind': 'battleInput',
        'payload': {
          'snapshotRevision': 20,
          'expectedMode': 'fight',
          'control': 'down',
          'phase': 'press',
          'isRepeat': false,
        },
      };
      await owner.applyIntent(intent);
      await owner.applyIntent(intent);
      expect(port.executed, hasLength(1));
      owner.setCompanionAttached('battle-session', false);
      expect(port.battleReleases, 1);
      await expectLater(
        owner.applyIntent({...intent, 'sequence': 2}),
        _error('companionDetached'),
      );
      owner.unbind(port);
      expect(port.battleReleases, 2);
    },
  );

  test('battle inputs wait for a busy command and retain press repeat release order', () async {
    const channel = MethodChannel('avelune.gameplay.test.battle-queue');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    var state = _battleEnvelope();
    final gate = Completer<void>();
    final calls = <Map<String, dynamic>>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'intent') {
        final intent = Map<String, dynamic>.from(call.arguments as Map);
        calls.add(intent);
        if (intent['kind'] == 'battle') {
          await gate.future;
        } else {
          state = _battleEnvelope(
            revision: state.revision + 1,
            battleRevision: state.battle!.revision + 1,
          );
        }
      }
      return state.toPayload();
    });
    final remote = AveluneGameplayCompanionRemote(channel: channel);
    addTearDown(() {
      remote.dispose();
      messenger.setMockMethodCallHandler(channel, null);
    });
    await remote.attach();
    final busy = remote.send('battle', {'action': 'layout'});
    final inputs = [
      remote.sendBattleInput(
        const RuntimeInputEvent.press(RuntimeInputControl.down),
      ),
      remote.sendBattleInput(
        const RuntimeInputEvent.press(RuntimeInputControl.down, isRepeat: true),
      ),
      remote.sendBattleInput(
        const RuntimeInputEvent.release(RuntimeInputControl.down),
      ),
    ];
    await Future<void>.delayed(Duration.zero);
    expect(calls, hasLength(1));
    gate.complete();
    await busy;
    await Future.wait(inputs);
    final forwarded = calls
        .where((call) => call['kind'] == 'battleInput')
        .toList();
    expect(forwarded, hasLength(3));
    expect(forwarded.map((call) => (call['payload'] as Map)['phase']), [
      'press',
      'press',
      'release',
    ]);
    expect(forwarded.map((call) => (call['payload'] as Map)['isRepeat']), [
      false,
      true,
      false,
    ]);
    expect(
      forwarded.map((call) => (call['payload'] as Map)['snapshotRevision']),
      [20, 21, 22],
    );
    expect(calls.map((call) => call['sequence']), [1, 2, 3, 4]);
  });

  test(
    'battle input queued for an obsolete mode cannot activate the next panel',
    () async {
      const channel = MethodChannel('avelune.gameplay.test.battle-stale-queue');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      var state = _battleEnvelope();
      final gate = Completer<void>();
      final kinds = <String>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'intent') {
          kinds.add((call.arguments as Map)['kind'] as String);
          await gate.future;
        }
        return state.toPayload();
      });
      final remote = AveluneGameplayCompanionRemote(channel: channel);
      addTearDown(() {
        remote.dispose();
        messenger.setMockMethodCallHandler(channel, null);
      });
      await remote.attach();
      final busy = remote.send('battle', {'action': 'layout'});
      final queued = remote.sendBattleInput(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      );
      final rejected = expectLater(queued, _error('staleMode'));
      state = _battleEnvelope(revision: 9, mode: BattleCommandOverlayMode.root);
      await _nativeCall(channel, 'stateChanged', state.toPayload());
      gate.complete();
      await busy;
      await rejected;
      expect(kinds, ['battle']);
    },
  );

  test('battle selection revisions preserve held inputs while detach releases them', () async {
    const channel = MethodChannel('avelune.gameplay.test.battle-held');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    var state = _battleEnvelope();
    messenger.setMockMethodCallHandler(channel, (_) async => state.toPayload());
    final remote = AveluneGameplayCompanionRemote(channel: channel);
    final inputs = <RuntimeInputEvent>[];
    final subscription = remote.inputs.listen(inputs.add);
    addTearDown(() async {
      await subscription.cancel();
      remote.dispose();
      messenger.setMockMethodCallHandler(channel, null);
    });
    await remote.attach();
    await _nativeCall(channel, 'input', {
      ..._battleInput(state, RuntimeInputControl.down),
      'battleRevision': 19,
    });
    expect(inputs, isEmpty);
    await _nativeCall(
      channel,
      'input',
      _battleInput(state, RuntimeInputControl.down),
    );
    state = _battleEnvelope(revision: 9, battleRevision: 21);
    await _nativeCall(channel, 'stateChanged', state.toPayload());
    expect(inputs, [const RuntimeInputEvent.press(RuntimeInputControl.down)]);
    await _nativeCall(channel, 'input', {
      ..._battleInput(state, RuntimeInputControl.down),
      'isRepeat': true,
    });
    await _nativeCall(channel, 'stateChanged', {
      ...state.toPayload(),
      'revision': 10,
      'companionAttached': false,
    });
    expect(inputs, [
      const RuntimeInputEvent.press(RuntimeInputControl.down),
      const RuntimeInputEvent.press(RuntimeInputControl.down, isRepeat: true),
      const RuntimeInputEvent.release(RuntimeInputControl.down),
    ]);
    await expectLater(
      remote.sendBattleInput(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      ),
      _error('companionDetached'),
    );
  });

  testWidgets('companion root order crosses layout ACK and retains canonical taps and input releases', (tester) async {
    await _loadPlayerFonts(tester);
    tester.view.physicalSize = const Size(496, 432);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const channel = MethodChannel('com.avelune.runtime/companion');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    var battle = RuntimeCompanionPresentationCodec.decodeBattleCommandOverlaySnapshot({
      ...RuntimeCompanionPresentationCodec.encodeBattleCommandOverlaySnapshot(_battleFixture()),
      'mode': 'root',
      'entries': [for (var index = 0; index < 4; index++)
        RuntimeCompanionPresentationCodec.encodeBattleCommandOverlayEntry(BattleCommandOverlayEntry(
          index: index, kind: BattleCommandOverlayEntryKind.root,
          primaryLabel: ['Attaquer', 'Sac', 'Équipe', 'Fuite'][index], secondaryLabel: '',
          enabled: true, selected: index == 0, tone: BattleCommandOverlayEntryTone.neutral))],
    });
    var state = AveluneGameplayCompanionSnapshot(sessionId: 'battle-session', revision: 8,
      companionAttached: true, mode: AveluneGameplayCompanionMode.battle, battle: battle);
    final calls = <Map<String, dynamic>>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'intent') {
        final intent = Map<String, dynamic>.from(call.arguments as Map);
        calls.add(intent);
        final payload = Map<String, dynamic>.from(intent['payload'] as Map);
        if (intent['kind'] == 'battle' && payload['action'] == 'layout') {
          battle = RuntimeCompanionPresentationCodec.decodeBattleCommandOverlaySnapshot({
            ...RuntimeCompanionPresentationCodec.encodeBattleCommandOverlaySnapshot(battle),
            'revision': battle.revision + 1, 'rootCommandOrder': payload['rootCommandOrder'],
            'collectionColumns': payload['collectionColumns'],
            'commandPanelPlacement': payload['placement'], 'controllerLayout': payload['controllerLayout'],
          });
          state = AveluneGameplayCompanionSnapshot(sessionId: state.sessionId, revision: state.revision + 1,
            companionAttached: true, mode: AveluneGameplayCompanionMode.battle, battle: battle);
        }
      }
      return state.toPayload();
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    await tester.pumpWidget(const AveluneGameplayCompanionApp());
    await tester.pumpAndSettle();
    final layouts = calls.where((call) => call['kind'] == 'battle' && (call['payload'] as Map)['action'] == 'layout');
    expect(layouts, hasLength(1));
    expect((layouts.single['payload'] as Map)['rootCommandOrder'], [0, 2, 1, 3]);
    expect(battle.rootCommandOrder, [0, 2, 1, 3]);
    await tester.tap(find.byKey(const ValueKey('battle-entry-1')));
    await tester.pumpAndSettle();
    final selection = calls.where((call) => call['kind'] == 'battle' && (call['payload'] as Map)['action'] == 'select').single;
    expect((selection['payload'] as Map)['entryIndex'], 1);
    for (final release in [false, true]) {
      await _nativeCall(channel, 'input', _battleInput(state, RuntimeInputControl.down, release: release));
      await tester.pumpAndSettle();
    }
    final inputs = calls.where((call) => call['kind'] == 'battleInput').toList();
    expect(inputs.map((call) => (call['payload'] as Map)['phase']), ['press', 'release']);
    expect(inputs.map((call) => (call['payload'] as Map)['control']), ['down', 'down']);
    expect(layouts, hasLength(1));
    battle = RuntimeCompanionPresentationCodec.decodeBattleCommandOverlaySnapshot({
      ...RuntimeCompanionPresentationCodec.encodeBattleCommandOverlaySnapshot(battle),
      'revision': battle.revision + 1,
      'mode': 'pokemon',
      'collectionColumns': null,
      'entries': [for (var index = 0; index < 6; index++)
        RuntimeCompanionPresentationCodec.encodeBattleCommandOverlayEntry(BattleCommandOverlayEntry(
          index: index, kind: BattleCommandOverlayEntryKind.party,
          primaryLabel: 'Membre $index', secondaryLabel: '12/40 PV',
          enabled: true, selected: index == 0, tone: BattleCommandOverlayEntryTone.neutral))],
    });
    state = AveluneGameplayCompanionSnapshot(sessionId: state.sessionId, revision: state.revision + 1,
      companionAttached: true, mode: AveluneGameplayCompanionMode.battle, battle: battle);
    await _nativeCall(channel, 'stateChanged', state.toPayload());
    await tester.pumpAndSettle();
    expect(layouts, hasLength(2));
    expect((layouts.last['payload'] as Map)['collectionColumns'], 2);
    expect(battle.collectionColumns, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'battle companion owns move info and never forwards its modal inputs',
    (tester) async {
      await _loadPlayerFonts(tester);
      tester.view.physicalSize = const Size(496, 432);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const channel = MethodChannel('com.avelune.runtime/companion');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      var state = _battleEnvelope();
      final calls = <Map<String, dynamic>>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'intent') {
          calls.add(Map<String, dynamic>.from(call.arguments as Map));
        }
        return state.toPayload();
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      await tester.pumpWidget(const AveluneGameplayCompanionApp());
      await tester.pumpAndSettle();
      await _nativeCall(
        channel,
        'input',
        _battleInput(state, RuntimeInputControl.sprint),
      );
      await _nativeCall(
        channel,
        'input',
        _battleInput(state, RuntimeInputControl.sprint, release: true),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('battle-move-info-dialog')),
        findsOneWidget,
      );
      await _nativeCall(
        channel,
        'input',
        _battleInput(state, RuntimeInputControl.down),
      );
      await _nativeCall(
        channel,
        'input',
        _battleInput(state, RuntimeInputControl.down, release: true),
      );
      expect(calls.where((call) => call['kind'] == 'battleInput'), isEmpty);
      await _nativeCall(
        channel,
        'input',
        _battleInput(state, RuntimeInputControl.secondary),
      );
      await _nativeCall(
        channel,
        'input',
        _battleInput(state, RuntimeInputControl.secondary, release: true),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('battle-move-info-dialog')),
        findsNothing,
      );
      await _nativeCall(
        channel,
        'input',
        _battleInput(state, RuntimeInputControl.down),
      );
      await _nativeCall(
        channel,
        'input',
        _battleInput(state, RuntimeInputControl.down, release: true),
      );
      await tester.pumpAndSettle();
      expect(
        calls.where((call) => call['kind'] == 'battleInput'),
        hasLength(2),
      );
      await _nativeCall(
        channel,
        'input',
        _battleInput(state, RuntimeInputControl.sprint),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('battle-move-info-dialog')),
        findsOneWidget,
      );
      state = AveluneGameplayCompanionSnapshot.fromPayload({
        ...state.toPayload(),
        'revision': 9,
        'companionAttached': false,
      });
      await _nativeCall(channel, 'stateChanged', state.toPayload());
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('battle-move-info-dialog')),
        findsNothing,
      );
      expect(
        calls.where((call) => call['kind'] == 'battleInput'),
        hasLength(2),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'battle companion waits for selection ACK before local info and releases its prior hold',
    (tester) async {
      await _loadPlayerFonts(tester);
      tester.view.physicalSize = const Size(496, 432);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const channel = MethodChannel('com.avelune.runtime/companion');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      var state = _battleEnvelope();
      final gate = Completer<void>();
      final inputs = <Map<String, Object?>>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'intent') {
          final intent = Map<String, Object?>.from(call.arguments as Map);
          if (intent['kind'] == 'battleInput') {
            final input = Map<String, Object?>.from(intent['payload'] as Map);
            inputs.add(input);
            if (input['phase'] == 'press') {
              await gate.future;
              state = _battleEnvelope(
                revision: 9,
                battleRevision: 21,
                selectedIndex: 1,
              );
            }
          }
        }
        return state.toPayload();
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      await tester.pumpWidget(const AveluneGameplayCompanionApp());
      await tester.pumpAndSettle();
      await _nativeCall(
        channel,
        'input',
        _battleInput(state, RuntimeInputControl.down),
      );
      await _nativeCall(
        channel,
        'input',
        _battleInput(state, RuntimeInputControl.sprint),
      );
      await tester.pump();
      final modal = find.byKey(const ValueKey('battle-move-info-dialog'));
      expect(modal, findsNothing);
      expect(inputs, hasLength(1));
      gate.complete();
      await tester.pumpAndSettle();
      expect(modal, findsOneWidget);
      expect(
        find.descendant(of: modal, matching: find.text('B')),
        findsOneWidget,
      );
      expect(inputs.map((input) => (input['control'], input['phase'])), [
        ('down', 'press'),
        ('down', 'release'),
      ]);
      await _nativeCall(
        channel,
        'input',
        _battleInput(state, RuntimeInputControl.down, release: true),
      );
      await _nativeCall(
        channel,
        'input',
        _battleInput(state, RuntimeInputControl.primary),
      );
      await _nativeCall(
        channel,
        'input',
        _battleInput(state, RuntimeInputControl.primary, release: true),
      );
      await tester.pumpAndSettle();
      expect(modal, findsNothing);
      expect(inputs, hasLength(2));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test('title handoff versions startup changes and requires a fresh painted owner after reconnect', () async {
    final owner = AveluneGameplayCompanionOwner();
    addTearDown(owner.dispose);
    final port = _Port()
      ..playerOverride = RuntimePlayerSnapshot(
        revision: 7,
        phase: RuntimePlayerPhase.title,
        gameTitle: 'Game',
      )
      ..presentation = {'startupRevision': 20};
    owner.start('title-session');
    owner.bind(port);
    await owner.refresh();
    owner.setCompanionAttached('title-session', true);
    final initial = owner.value!;
    expect(initial.narrativeIdentity, isNotNull);
    await expectLater(
      owner.applyIntent({
        ..._intent(initial),
        'kind': 'player',
        'payload': {
          'action': 'newGame',
          'snapshotRevision': 7,
          'startupRevision': 20,
        },
      }),
      _error('companionUnavailable'),
    );
    await owner.applyIntent({
      ..._intent(initial),
      'kind': 'narrativeReady',
      'payload': {'generation': initial.narrativeGeneration},
    });
    final ready = owner.value!;
    final action = {
      ..._intent(ready, sequence: 2),
      'kind': 'player',
      'payload': {
        'action': 'newGame',
        'snapshotRevision': 7,
        'startupRevision': 20,
      },
    };
    await owner.applyIntent(action);
    await owner.applyIntent(action);
    expect(port.executed, hasLength(1));
    port.presentation = {'startupRevision': 21};
    await owner.refresh();
    expect(owner.value!.narrativeReady, isFalse);
    expect(
      owner.value!.narrativeGeneration,
      greaterThan(initial.narrativeGeneration),
    );
    await expectLater(
      owner.applyIntent({
        ..._intent(owner.value!, sequence: 3),
        'kind': 'narrativeReady',
        'payload': {'generation': initial.narrativeGeneration},
      }),
      _error('staleRevision'),
    );
    final beforeDetach = owner.value!;
    owner.setCompanionAttached('title-session', false);
    owner.setCompanionAttached('title-session', true);
    expect(owner.value!.narrativeReady, isFalse);
    await expectLater(
      owner.applyIntent({
        ..._intent(owner.value!, sequence: 3),
        'kind': 'narrativeReady',
        'payload': {'generation': beforeDetach.narrativeGeneration},
      }),
      _error('staleRevision'),
    );
    expect(port.executed, hasLength(1));
  });

  test('remote title commands include the current startup revision', () async {
    const channel = MethodChannel('avelune.gameplay.test.title-revision');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final state = AveluneGameplayCompanionSnapshot(
      sessionId: 'title',
      revision: 9,
      companionAttached: true,
      mode: AveluneGameplayCompanionMode.menu,
      player: RuntimePlayerSnapshot(
        revision: 7,
        phase: RuntimePlayerPhase.title,
        gameTitle: 'Game',
      ),
      presentation: const {'startupRevision': 20},
      narrativeReady: true,
    );
    final calls = <Map<String, dynamic>>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'intent')
        calls.add(Map<String, dynamic>.from(call.arguments as Map));
      return state.toPayload();
    });
    final remote = AveluneGameplayCompanionRemote(channel: channel);
    addTearDown(() {
      remote.dispose();
      messenger.setMockMethodCallHandler(channel, null);
    });
    await remote.attach();
    await remote.send('player', {
      'action': 'newGame',
      'snapshotRevision': 7,
      'startupRevision': -1,
    });
    expect((calls.single['payload'] as Map)['startupRevision'], 20);
    expect((calls.single['payload'] as Map)['snapshotRevision'], 7);
    expect(remote.busy, isFalse);
  });

  testWidgets(
    'companion title acknowledges its painted generation before exposing canonical actions',
    (tester) async {
      final calls = await _mountMenu(
        tester,
        title: true,
        narrativeReady: false,
      );
      expect(calls, hasLength(1));
      expect(calls.single['kind'], 'narrativeReady');
      expect(find.byKey(const ValueKey('title.newGame')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('title.newGame')));
      await tester.pumpAndSettle();
      expect(calls, hasLength(2));
      expect(calls.last['kind'], 'player');
      expect((calls.last['payload'] as Map)['startupRevision'], 20);
      expect((calls.last['payload'] as Map)['snapshotRevision'], 7);
      expect((calls.last['payload'] as Map)['action'], 'newGame');
      expect(tester.takeException(), isNull);
    },
    variant: const TargetPlatformVariant({TargetPlatform.iOS}),
  );

  test('paint acknowledgement survives text reveal revisions without replaying input', () async {
    final owner = AveluneGameplayCompanionOwner();
    addTearDown(owner.dispose);
    final port = _Port()..dialogue = _narrative(text: 'B');
    owner.start('reveal');
    owner.bind(port);
    await owner.refresh();
    owner.setCompanionAttached('reveal', true);
    final painted = owner.value!;
    port.dialogue = _narrative(revision: 9, text: 'Bo');
    await owner.refresh();
    expect(owner.value!.revision, greaterThan(painted.revision));
    await owner.applyIntent({
      ..._intent(painted),
      'kind': 'narrativeReady',
      'payload': {'generation': painted.narrativeGeneration},
    });
    expect(owner.value!.narrativeReady, isTrue);
    expect(port.executed, isEmpty);
    await expectLater(owner.applyIntent({
      ..._intent(painted, sequence: 2),
      'kind': 'dialogue',
      'payload': RuntimeCompanionPresentationCodec.encodeDialogueCommand(
        const DialogueAdvanceCommand(snapshotRevision: 8),
      ),
    }), _error('staleRevision'));
  });

  testWidgets('companion root has no pause heading or back arrow', (tester) async {
    await _mountMenu(tester, size: const Size(1080, 1240));
    expect(find.byKey(const ValueKey('pause-root-menu-title')), findsNothing);
    expect(find.byType(PlayerMenuBackButton), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: const TargetPlatformVariant({TargetPlatform.iOS}));

  testWidgets('companion transition is an empty black surface and recovers', (tester) async {
    await _mountMenu(tester);
    const channel = MethodChannel('com.avelune.runtime/companion');
    final state = AveluneGameplayCompanionSnapshot(
      sessionId: 'session-grid', revision: 20, companionAttached: true,
      mode: AveluneGameplayCompanionMode.blocked,
    );
    await _nativeCall(channel, 'stateChanged', state.toPayload());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(PlayerEmptyState), findsNothing);
    expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor, Colors.black);
    await _nativeCall(channel, 'stateChanged', {
      ...state.toPayload(), 'revision': 21, 'mode': 'waiting',
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(PlayerEmptyState), findsNothing);
    await _nativeCall(channel, 'stateChanged', {
      ..._savedSnapshot().toPayload(),
      'sessionId': 'session-grid',
      'revision': 22,
    });
    await tester.pumpAndSettle();
    expect(find.byType(PokeMapPlayerSessionView), findsOneWidget);
    expect(find.byType(ErrorWidget), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: const TargetPlatformVariant({TargetPlatform.iOS}));

  test('narrative ownership requires painted generation and rejects stale replay and reconnect', () async {
    final owner = AveluneGameplayCompanionOwner();
    addTearDown(owner.dispose);
    final port = _Port()..dialogue = _narrative();
    owner.start('narrative-session');
    owner.bind(port);
    await owner.refresh();
    owner.setCompanionAttached('narrative-session', true);
    final initial = owner.value!;
    final command = {
      ..._intent(initial),
      'kind': 'dialogue',
      'payload': RuntimeCompanionPresentationCodec.encodeDialogueCommand(
        const DialogueAdvanceCommand(snapshotRevision: 8),
      ),
    };
    await expectLater(
      owner.applyIntent(command),
      _error('companionUnavailable'),
    );
    final ready = {
      ..._intent(initial),
      'kind': 'narrativeReady',
      'payload': {'generation': initial.narrativeGeneration},
    };
    await owner.applyIntent(ready);
    expect(owner.value!.narrativeReady, isTrue);
    expect(port.executed, isEmpty);
    await owner.applyIntent(ready);
    expect(port.executed, isEmpty);
    final active = owner.value!;
    await expectLater(
      owner.applyIntent({...command, 'sequence': 2}),
      _error('staleRevision'),
    );
    final accepted = {...command, 'sequence': 2, 'revision': active.revision};
    await owner.applyIntent(accepted);
    await owner.applyIntent(accepted);
    expect(port.executed, hasLength(1));
    port.dialogue = _narrative(revision: 9, text: 'Bon');
    await owner.refresh();
    expect(owner.value!.narrativeReady, isTrue);
    expect(owner.value!.narrativeGeneration, initial.narrativeGeneration);
    port.dialogue = _narrative(revision: 10, fullText: 'Au revoir');
    await owner.refresh();
    expect(owner.value!.narrativeReady, isFalse);
    expect(
      owner.value!.narrativeGeneration,
      greaterThan(initial.narrativeGeneration),
    );
    await expectLater(
      owner.applyIntent({
        ..._intent(owner.value!, sequence: 3),
        'kind': 'narrativeReady',
        'payload': {'generation': initial.narrativeGeneration},
      }),
      _error('staleRevision'),
    );
    final beforeDetach = owner.value!;
    owner.setCompanionAttached('narrative-session', false);
    expect(owner.value!.narrativeReady, isFalse);
    await expectLater(
      owner.applyIntent({
        ..._intent(owner.value!, sequence: 3),
        'kind': 'narrativeReady',
        'payload': {'generation': owner.value!.narrativeGeneration},
      }),
      _error('companionDetached'),
    );
    owner.setCompanionAttached('narrative-session', true);
    await expectLater(
      owner.applyIntent({
        ..._intent(owner.value!, sequence: 3),
        'kind': 'narrativeReady',
        'payload': {'generation': beforeDetach.narrativeGeneration},
      }),
      _error('staleRevision'),
    );
    await owner.applyIntent({
      ..._intent(owner.value!, sequence: 3),
      'kind': 'narrativeReady',
      'payload': {'generation': owner.value!.narrativeGeneration},
    });
    expect(owner.value!.narrativeReady, isTrue);
    await expectLater(
      owner.applyIntent({
        ..._intent(owner.value!, sequence: 4),
        'sessionId': 'old-session',
        'kind': 'dialogue',
      }),
      _error('staleSession'),
    );
  });

  test('narrative snapshot transports dialogue and defaults legacy readiness safely', () {
    final source = AveluneGameplayCompanionSnapshot(
      sessionId: 'narrative',
      revision: 12,
      companionAttached: true,
      mode: AveluneGameplayCompanionMode.menu,
      player: RuntimePlayerSnapshot(
        revision: 4,
        phase: RuntimePlayerPhase.playing,
        gameTitle: 'Game',
      ),
      dialogue: _narrative(),
      narrativeGeneration: 3,
      narrativeReady: true,
    );
    final decoded = AveluneGameplayCompanionSnapshot.fromPayload(
      source.toPayload(),
    );
    expect(decoded.narrativeIdentity, source.narrativeIdentity);
    expect(decoded.narrativeReady, isTrue);
    expect(decoded.narrativeGeneration, 3);
    final old = {...source.toPayload()}
      ..remove('dialogue')
      ..remove('narrativeGeneration')
      ..remove('narrativeReady');
    final legacy = AveluneGameplayCompanionSnapshot.fromPayload(old);
    expect(legacy.dialogue, isNull);
    expect(legacy.narrativeReady, isFalse);
  });

  testWidgets(
    'ready dialogue stays off the companion and cannot advance there',
    (tester) async {
      final calls = await _mountMenu(tester, dialogue: _narrative());
      expect(calls, isEmpty);
      expect(find.byKey(const ValueKey('dialogue-tap-zone')), findsNothing);
      const channel = MethodChannel('com.avelune.runtime/companion');
      for (final phase in ['press', 'release']) {
        await _nativeCall(channel, 'input', {
          'sessionId': 'session-grid',
          'revision': 8,
          'control': 'primary',
          'phase': phase,
          'isRepeat': false,
        });
        await tester.pumpAndSettle();
      }
      expect(calls, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
    variant: const TargetPlatformVariant({TargetPlatform.iOS}),
  );

  testWidgets(
    'companion never claims an unpainted primary dialogue',
    (tester) async {
      final calls = await _mountMenu(
        tester,
        dialogue: _narrative(),
        narrativeReady: false,
      );
      expect(find.byKey(const ValueKey('dialogue-tap-zone')), findsNothing);
      expect(calls, isEmpty);
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
    variant: const TargetPlatformVariant({TargetPlatform.iOS}),
  );

  testWidgets(
    'dialogue choices stay on the primary screen',
    (tester) async {
      final calls = await _mountMenu(
        tester,
        dialogue: const DialoguePresentationSnapshot(
          revision: 19,
          mode: DialoguePresentationMode.choices,
          nodeTitle: 'station',
          speaker: 'Guide',
          text: 'Où aller ?',
          fullText: 'Où aller ?',
          isCurrentLineFullyRevealed: true,
          isLastContent: false,
          choices: [
            DialoguePresentationChoice(index: 0, label: 'Port', selected: true),
            DialoguePresentationChoice(
              index: 1,
              label: 'Montagne',
              selected: false,
              enabled: false,
            ),
          ],
        ),
      );
      expect(find.byKey(const ValueKey('dialogue-choice-0')), findsNothing);
      expect(find.byKey(const ValueKey('dialogue-choice-1')), findsNothing);
      expect(calls, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
    variant: const TargetPlatformVariant({TargetPlatform.iOS}),
  );

  testWidgets(
    'structured dialogue confirmation stays on the primary screen',
    (tester) async {
      final request = SceneInteractionRequest.confirmation(
        requestId: 'train',
        revision: 4,
        prompt: SceneInteractionPrompt(
          localizationKey: 'train',
          fallbackText: 'Partir ?',
        ),
      );
      final calls = await _mountMenu(tester, interaction: request);
      expect(find.byKey(const ValueKey('scene-interaction-confirm-yes')), findsNothing);
      expect(calls, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
    variant: const TargetPlatformVariant({TargetPlatform.iOS}),
  );

  testWidgets('native companion nickname keeps typed result revisions', (
    tester,
  ) async {
    final interaction = SceneTextInteractionRequest(
      requestId: 'gift:nickname',
      revision: 4,
      prompt: SceneInteractionPrompt(
        localizationKey: 'nickname',
        fallbackText: 'Surnom',
      ),
      initialValue: 'Horloge',
      constraints: SceneTextInputConstraints(maxGraphemes: 10),
    );
    final calls = await _mountMenu(
      tester,
      worldService: RuntimeWorldServiceSnapshot(
        revision: 12,
        request: OpenPokemonGiftInteractionService(
          interactionId: 'gift:nickname',
          interaction: interaction,
          stage: PokemonGiftInteractionStage.nickname,
          pokemon: const PlayerPokemon(
            individualId: 'one',
            speciesId: 'bird',
            natureId: 'hardy',
            abilityId: 'clockwork',
            currentHp: 5,
          ),
          projectedState: const GameState(saveId: 'gift'),
        ),
        content: interaction,
        stage: RuntimeWorldServiceStage.active,
        actions: const [
          RuntimeWorldServiceActionAvailability.enabled(
            RuntimeWorldServiceAction.confirm,
          ),
          RuntimeWorldServiceActionAvailability.enabled(
            RuntimeWorldServiceAction.cancel,
          ),
        ],
      ),
    );
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('scene-interaction-text-field')),
    );
    expect(field.readOnly, isTrue);
    expect(
      find.byKey(const ValueKey('scene-controller-keyboard')),
      findsOneWidget,
    );
    for (final _ in interaction.initialValue.characters) {
      await tester.tap(find.byKey(const ValueKey('scene-keyboard-erase')));
      await tester.pumpAndSettle();
    }
    for (final letter in 'PENDULE'.characters) {
      await _tapKeyboardCharacter(tester, letter);
    }
    expect(field.controller!.text, 'Pendule');
    await tester.tap(
      find.byKey(const ValueKey('scene-interaction-text-submit')),
    );
    await tester.pumpAndSettle();
    expect(calls, hasLength(1));
    expect(calls.single['kind'], 'worldService');
    final payload = Map<String, dynamic>.from(calls.single['payload'] as Map);
    expect(payload['interactionId'], 'gift:nickname');
    final command = RuntimeCompanionPresentationCodec.decodeWorldServiceCommand(
      payload,
    );
    expect(command.snapshotRevision, 12);
    final result =
        command.interactionResult as SceneTextSubmittedInteractionResult;
    expect(result.requestId, 'gift:nickname');
    expect(result.revision, 4);
    expect(result.value, 'Pendule');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: const TargetPlatformVariant({TargetPlatform.iOS}));

  testWidgets(
    'native companion PC sends typed transfer to its current service',
    (tester) async {
      final calls = await _mountMenu(tester, worldService: _pcService());
      expect(find.byType(PlayerPcOverlay), findsOneWidget);
      expect(find.byKey(const ValueKey('pc-grid-6x5')), findsOneWidget);
      expect(find.byType(Scrollable), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey('pc-withdraw-opaque-pokemon')),
      );
      await tester.pumpAndSettle();
      expect(calls, hasLength(1));
      expect(calls.single['kind'], 'worldService');
      final payload = calls.single['payload'] as Map;
      expect(payload['interactionId'], 'terminal');
      expect(payload['snapshotRevision'], 9);
      expect(payload['action'], 'withdraw');
      expect(payload['targetId'], 'opaque-pokemon');
      calls.clear();
      await tester.tap(find.byKey(const ValueKey('pc-party-toggle')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pc-party-slot-0')), findsOneWidget);
      const channel = MethodChannel('com.avelune.runtime/companion');
      for (final phase in ['press', 'release']) {
        await _nativeCall(channel, 'input', {
          'sessionId': 'session-grid',
          'revision': 8,
          'control': 'secondary',
          'phase': phase,
          'isRepeat': false,
        });
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const ValueKey('pc-grid-6x5')), findsOneWidget);
      expect(calls, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
    variant: const TargetPlatformVariant({TargetPlatform.iOS}),
  );

  test('world-service companion rejects stale owner revisions and deduplicates replay', () async {
    final owner = AveluneGameplayCompanionOwner();
    addTearDown(owner.dispose);
    final port = _Port()..service = _pcService();
    owner.start('session-a');
    owner.bind(port);
    await owner.refresh();
    owner.setCompanionAttached('session-a', true);
    final intent = {
      ..._intent(owner.value!),
      'kind': 'worldService',
      'payload': {
        ...RuntimeCompanionPresentationCodec.encodeWorldServiceCommand(
          const RuntimeWorldServiceCommand(
            action: RuntimeWorldServiceAction.withdraw,
            snapshotRevision: 9,
            targetId: 'opaque-pokemon',
          ),
        ),
        'interactionId': 'terminal',
      },
    };
    await owner.applyIntent(intent);
    await owner.applyIntent(intent);
    expect(port.executed, hasLength(1));
    port.service = port.service!.next(stage: RuntimeWorldServiceStage.applying);
    await owner.refresh();
    await expectLater(
      owner.applyIntent({...intent, 'sequence': 2}),
      _error('staleRevision'),
    );
    expect(port.executed, hasLength(1));
  });

  for (final control in ['secondary', 'menu']) {
    testWidgets('companion root resumes via $control', (tester) async {
      final calls = await _mountMenu(tester);
      const channel = MethodChannel('com.avelune.runtime/companion');
      for (final phase in ['press', 'release']) {
        await _nativeCall(channel, 'input', {
          'sessionId': 'session-grid',
          'revision': 8,
          'control': control,
          'phase': phase,
          'isRepeat': false,
        });
        await tester.pumpAndSettle();
      }
      expect(calls, hasLength(1));
      expect(calls.single['kind'], 'player');
      expect((calls.single['payload'] as Map)['action'], 'resume');
      expect((calls.single['payload'] as Map)['snapshotRevision'], 7);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final (size, textScale) in [
    (const Size(538, 468), 1.0),
    (const Size(390, 844), 1.0),
    (const Size(844, 390), 1.0),
    (const Size(538, 468), 1.6),
  ]) {
    testWidgets(
      'companion root keeps all large actions accessible without scrolling $size/$textScale',
      (tester) async {
        final calls = await _mountMenu(
          tester,
          size: size,
          textScale: textScale,
        );
        expect(find.byType(Scrollable), findsNothing);
        expect(find.byType(PlayerPauseSummaryCard), findsNothing);
        expect(find.byType(PlayerMenuHeader), findsNothing);
        expect(find.byType(PlayerMenuFooter), findsOneWidget);
        expect(
          find
              .byWidgetPredicate(
                (widget) =>
                    widget is PlayerMenuSelectableRow &&
                    widget.id == 'pause-frame-return',
              )
              .hitTestable(),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('pause.resume')), findsNothing);
        final viewport = Offset.zero & size;
        final expected = PlayerPauseAction.values
            .where((action) => action != PlayerPauseAction.resume)
            .toSet();
        final seen = <PlayerPauseAction>{};
        for (var page = 0; page < expected.length; page++) {
          for (final action in expected) {
            final button = find.byKey(ValueKey('pause.${action.name}'));
            if (button.evaluate().isEmpty) continue;
            seen.add(action);
            final rect = tester.getRect(button);
            expect(
              rect.width,
              greaterThanOrEqualTo(
                action == PlayerPauseAction.returnToTitle ? 48 : 120,
              ),
            );
            expect(rect.height, greaterThanOrEqualTo(48));
            expect(viewport.contains(rect.topLeft), isTrue);
            expect(viewport.contains(rect.bottomRight), isTrue);
          }
          final next = find.byKey(const ValueKey('player-page-next'));
          if (next.evaluate().isEmpty ||
              tester.widget<IconButton>(next).onPressed == null) {
            break;
          }
          expect(textScale, greaterThan(1));
          await tester.tap(next);
          await tester.pumpAndSettle();
        }
        expect(seen, expected);
        final bag = find.byKey(const ValueKey('pause.bag'));
        while (bag.evaluate().isEmpty) {
          await tester.tap(find.byKey(const ValueKey('player-page-previous')));
          await tester.pumpAndSettle();
        }
        final before = tester.getRect(bag);
        await tester.drag(bag, const Offset(0, -160));
        await tester.pumpAndSettle();
        expect(tester.getRect(bag), before);
        expect(calls, isEmpty);
        await tester.tap(bag);
        await tester.pumpAndSettle();
        expect(calls.map((call) => call['kind']), ['pause', 'player']);
        expect((calls.last['payload'] as Map)['action'], 'openBag');
        expect((calls.last['payload'] as Map)['snapshotRevision'], 7);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
      variant: const TargetPlatformVariant({TargetPlatform.iOS}),
    );
  }

  testWidgets('companion paged root backs out once without a local action', (
    tester,
  ) async {
    final calls = await _mountMenu(tester, textScale: 1.6);
    await tester.tap(find.byKey(const ValueKey('player-page-next')));
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
    const channel = MethodChannel('com.avelune.runtime/companion');
    for (final phase in ['press', 'release']) {
      await _nativeCall(channel, 'input', {
        'sessionId': 'session-grid',
        'revision': 8,
        'control': 'secondary',
        'phase': phase,
        'isRepeat': false,
      });
      await tester.pumpAndSettle();
    }
    expect(calls, hasLength(1));
    expect(calls.single['kind'], 'player');
    expect((calls.single['payload'] as Map)['action'], 'resume');
    expect((calls.single['payload'] as Map)['snapshotRevision'], 7);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: const TargetPlatformVariant({TargetPlatform.iOS}));

  testWidgets('companion action grid repairs an obsolete resume selection', (
    tester,
  ) async {
    final calls = await _mountMenu(tester, logicalSelectionId: 'pause.resume');
    expect(find.byKey(const ValueKey('pause.resume')), findsNothing);
    final party = tester.widget<PlayerMenuSelectableRow>(
      find.byKey(const ValueKey('pause.party')),
    );
    expect(party.selected, isTrue);
    expect(calls, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'companion action grid retains physical direction and confirmation',
    (tester) async {
      final calls = await _mountMenu(tester);
      const channel = MethodChannel('com.avelune.runtime/companion');
      for (final control in ['right', 'primary']) {
        for (final phase in ['press', 'release']) {
          await _nativeCall(channel, 'input', {
            'sessionId': 'session-grid',
            'revision': 8,
            'control': control,
            'phase': phase,
            'isRepeat': false,
          });
          await tester.pumpAndSettle();
        }
        if (control == 'right') {
          final row = tester.widget<PlayerMenuSelectableRow>(
            find.byKey(const ValueKey('pause.bag')),
          );
          expect(row.selected, isTrue);
          expect(calls, isEmpty);
        }
      }
      expect(calls.map((call) => call['kind']), ['pause', 'player']);
      expect((calls.last['payload'] as Map)['action'], 'openBag');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('companion action grid preserves hidden and disabled actions', (
    tester,
  ) async {
    final calls = await _mountMenu(tester, hiddenPokedex: true);
    expect(find.byKey(const ValueKey('pause.pokedex')), findsNothing);
    final map = find.byKey(const ValueKey('pause.map'));
    expect(tester.widget<PlayerMenuSelectableRow>(map).onPressed, isNull);
    await tester.tap(map);
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test(
    'transport starts without opening a menu or creating a player',
    () async {
      final owner = AveluneGameplayCompanionOwner();
      addTearDown(owner.dispose);
      owner.start('session-a');
      expect(owner.value!.mode, AveluneGameplayCompanionMode.waiting);
      expect(owner.value!.player, isNull);
      expect(owner.value!.companionAttached, isFalse);
    },
  );

  test('menu projection preserves the canonical runtime revision', () async {
    final owner = AveluneGameplayCompanionOwner();
    addTearDown(owner.dispose);
    final port = _Port();
    owner.start('session-a');
    owner.bind(port);
    await owner.refresh();
    final state = owner.value!;
    expect(state.mode, AveluneGameplayCompanionMode.menu);
    expect(state.player!.revision, 7);
    expect(port.executed, isEmpty);
    expect(
      AveluneGameplayCompanionSnapshot.fromPayload(state.toPayload())
          .player!
          .revision,
      7,
    );
  });

  test(
    'intent rejects stale session revision mode and detached surfaces',
    () async {
      final owner = AveluneGameplayCompanionOwner();
      addTearDown(owner.dispose);
      owner.start('session-a');
      owner.bind(_Port());
      await owner.refresh();
      final state = owner.value!;
      await expectLater(
        owner.applyIntent(_intent(state)),
        _error('companionDetached'),
      );
      owner.setCompanionAttached('session-a', true);
      final attached = owner.value!;
      await expectLater(
        owner.applyIntent({..._intent(attached), 'sessionId': 'old'}),
        _error('staleSession'),
      );
      await expectLater(
        owner.applyIntent({
          ..._intent(attached),
          'revision': attached.revision - 1,
        }),
        _error('staleRevision'),
      );
      await expectLater(
        owner.applyIntent({..._intent(attached), 'mode': 'battle'}),
        _error('staleMode'),
      );
    },
  );

  test('duplicates and concurrent intentions never dispatch twice', () async {
    final owner = AveluneGameplayCompanionOwner();
    addTearDown(owner.dispose);
    final port = _Port()..gate = Completer<void>();
    owner.start('session-a');
    owner.bind(port);
    await owner.refresh();
    owner.setCompanionAttached('session-a', true);
    final intent = _intent(owner.value!);
    final first = owner.applyIntent(intent);
    await Future<void>.delayed(Duration.zero);
    await expectLater(
      owner.applyIntent({...intent, 'sequence': 2}),
      _error('runtimeBusy'),
    );
    port.gate!.complete();
    await first;
    await owner.applyIntent(_intent(owner.value!, sequence: 1));
    expect(port.executed, hasLength(1));
  });

  test('a stopped owner cannot publish a late read or action reply', () async {
    final owner = AveluneGameplayCompanionOwner();
    addTearDown(owner.dispose);
    final port = _Port();
    owner.start('session-a');
    owner.bind(port);
    await owner.refresh();
    owner.setCompanionAttached('session-a', true);
    port.gate = Completer<void>();
    final action = owner.applyIntent(_intent(owner.value!));
    await Future<void>.delayed(Duration.zero);
    owner.stop('session-a');
    owner.start('session-b');
    port.gate!.complete();
    await expectLater(action, _error('staleSession'));
    expect(owner.value!.sessionId, 'session-b');
    expect(owner.value!.mode, AveluneGameplayCompanionMode.waiting);
  });

  test(
    'input forwards only the paused current owner to the attached companion',
    () async {
      final owner = AveluneGameplayCompanionOwner();
      addTearDown(owner.dispose);
      final port = _Port();
      owner.start('session-a');
      owner.bind(port);
      await owner.refresh();
      owner.setCompanionAttached('session-a', true);
      expect(
        owner.inputPayload(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        isNull,
      );
      port.paused = true;
      final input = owner.inputPayload(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      );
      expect(input!['sessionId'], 'session-a');
      expect(input['control'], 'primary');
      expect(input['phase'], 'press');
      owner.setCompanionAttached('session-a', false);
      expect(
        owner.inputPayload(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        isNull,
      );
    },
  );

  test('notifications coalesce reads and discard the obsolete in-flight projection', () async {
    final owner = AveluneGameplayCompanionOwner();
    addTearDown(owner.dispose);
    final port = _Port()..readGate = Completer<void>();
    owner.start('session-a');
    owner.bind(port);
    owner.invalidate();
    owner.invalidate();
    final completed = owner.refresh();
    expect(port.reads, 1);
    expect(owner.value!.mode, AveluneGameplayCompanionMode.waiting);
    port.readGate!.complete();
    await completed;
    expect(port.maximumConcurrentReads, 1);
    expect(port.reads, 2);
    expect(owner.value!.player!.revision, 7);
  });

  test(
    'stopping invalidates an asynchronous read without resurrecting the menu',
    () async {
      final owner = AveluneGameplayCompanionOwner();
      addTearDown(owner.dispose);
      final port = _Port()..readGate = Completer<void>();
      owner.start('session-a');
      owner.bind(port);
      final completed = owner.refresh();
      owner.stop('session-a');
      owner.start('session-b');
      port.readGate!.complete();
      await completed;
      expect(owner.value!.sessionId, 'session-b');
      expect(owner.value!.mode, AveluneGameplayCompanionMode.waiting);
    },
  );

  test('duplicate native notifications and replies preserve the save receipt instance', () async {
    const channel = MethodChannel('avelune.gameplay.test.receipt');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final state = _savedSnapshot();
    messenger.setMockMethodCallHandler(channel, (_) async => state.toPayload());
    final remote = AveluneGameplayCompanionRemote(channel: channel);
    addTearDown(() {
      remote.dispose();
      messenger.setMockMethodCallHandler(channel, null);
    });
    await remote.attach();
    final receipt = remote.value!.player!.saveReceipt;
    await _nativeCall(channel, 'stateChanged', state.toPayload());
    await remote.send('back', {'snapshotRevision': state.player!.revision});
    expect(remote.value!.player!.saveReceipt, same(receipt));
  });

  test('a canonical null state prevents a late intent reply from restoring the menu', () async {
    const channel = MethodChannel('avelune.gameplay.test.late-reply');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final state = _savedSnapshot();
    final reply = Completer<Object?>();
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'companionReady') return state.toPayload();
      return await reply.future;
    });
    final remote = AveluneGameplayCompanionRemote(channel: channel);
    addTearDown(() {
      remote.dispose();
      messenger.setMockMethodCallHandler(channel, null);
    });
    await remote.attach();
    final action = remote.send('back', {
      'snapshotRevision': state.player!.revision,
    });
    await _nativeCall(channel, 'stateChanged', null);
    reply.complete(state.toPayload());
    await action;
    expect(remote.value, isNull);
  });

  test(
    'menu revision releases held input without accepting stale releases',
    () async {
      const channel = MethodChannel('avelune.gameplay.test.revision-input');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final state = _savedSnapshot();
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => state.toPayload(),
      );
      final remote = AveluneGameplayCompanionRemote(channel: channel);
      final policy = PlayerInputSourcePolicy(touchAvailable: false);
      const owner = PlayerInputOwner(
        PlayerInputSource.controller,
        deviceId: 'owner-input-relay',
      );
      final accepted = <RuntimeInputEvent>[];
      final subscription = remote.inputs.listen((event) {
        accepted.addAll(policy.route(event, owner: owner));
      });
      addTearDown(() async {
        await subscription.cancel();
        remote.dispose();
        messenger.setMockMethodCallHandler(channel, null);
      });
      await remote.attach();
      final input = {
        'sessionId': state.sessionId,
        'revision': state.revision,
        'control': 'down',
        'phase': 'press',
        'isRepeat': false,
      };
      await _nativeCall(channel, 'input', input);
      await _nativeCall(channel, 'stateChanged', {
        ...state.toPayload(),
        'revision': 9,
      });
      await _nativeCall(channel, 'input', {...input, 'revision': 9});
      await _nativeCall(channel, 'input', {...input, 'phase': 'release'});
      expect(accepted, [
        const RuntimeInputEvent.press(RuntimeInputControl.down),
        const RuntimeInputEvent.release(RuntimeInputControl.down),
        const RuntimeInputEvent.press(RuntimeInputControl.down),
      ]);
      await _nativeCall(channel, 'input', {
        ...input,
        'revision': 9,
        'phase': 'release',
      });
      await _nativeCall(channel, 'input', {...input, 'revision': 9});
      expect(accepted, [
        const RuntimeInputEvent.press(RuntimeInputControl.down),
        const RuntimeInputEvent.release(RuntimeInputControl.down),
        const RuntimeInputEvent.press(RuntimeInputControl.down),
        const RuntimeInputEvent.release(RuntimeInputControl.down),
        const RuntimeInputEvent.press(RuntimeInputControl.down),
      ]);
    },
  );

  for (final disconnect in ['detach', 'stop', 'surface']) {
    test('menu $disconnect releases held input', () async {
      final channel = MethodChannel('avelune.gameplay.test.$disconnect-input');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final state = _savedSnapshot();
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => state.toPayload(),
      );
      final remote = AveluneGameplayCompanionRemote(channel: channel);
      final inputs = <RuntimeInputEvent>[];
      final subscription = remote.inputs.listen(inputs.add);
      addTearDown(() async {
        await subscription.cancel();
        remote.dispose();
        messenger.setMockMethodCallHandler(channel, null);
      });
      await remote.attach();
      await _nativeCall(channel, 'input', {
        'sessionId': state.sessionId,
        'revision': state.revision,
        'control': 'menu',
        'phase': 'press',
        'isRepeat': false,
      });
      switch (disconnect) {
        case 'detach':
          remote.detach();
        case 'stop':
          await _nativeCall(channel, 'stateChanged', null);
        case 'surface':
          await _nativeCall(channel, 'stateChanged', {
            ...state.toPayload(),
            'revision': state.revision + 1,
            'companionAttached': false,
          });
      }
      expect(inputs, [
        const RuntimeInputEvent.press(RuntimeInputControl.menu),
        const RuntimeInputEvent.release(RuntimeInputControl.menu),
      ]);
    });
  }

  test('remote input accepts only the active menu envelope', () async {
    const channel = MethodChannel('avelune.gameplay.test.input');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final state = _savedSnapshot();
    messenger.setMockMethodCallHandler(channel, (_) async => state.toPayload());
    final remote = AveluneGameplayCompanionRemote(channel: channel);
    final inputs = <RuntimeInputEvent>[];
    final subscription = remote.inputs.listen(inputs.add);
    addTearDown(() async {
      await subscription.cancel();
      remote.dispose();
      messenger.setMockMethodCallHandler(channel, null);
    });
    await remote.attach();
    final input = {
      'sessionId': state.sessionId,
      'revision': state.revision,
      'control': 'down',
      'phase': 'press',
      'isRepeat': false,
    };
    await _nativeCall(channel, 'input', {
      ...input,
      'revision': state.revision - 1,
    });
    await _nativeCall(channel, 'input', {...input, 'sessionId': 'old-session'});
    await _nativeCall(channel, 'input', input);
    await _nativeCall(channel, 'stateChanged', {
      ...state.toPayload(),
      'revision': state.revision - 1,
    });
    await _nativeCall(channel, 'stateChanged', {
      ...state.toPayload(),
      'sessionId': 'old-session',
      'revision': state.revision + 1,
    });
    await _nativeCall(channel, 'input', {...input, 'isRepeat': true});
    expect(inputs, [
      const RuntimeInputEvent.press(RuntimeInputControl.down),
      const RuntimeInputEvent.press(RuntimeInputControl.down, isRepeat: true),
    ]);
    expect(remote.value!.revision, state.revision);
  });
}

Future<List<Map<String, dynamic>>> _mountMenu(
  WidgetTester tester, {
  Size size = const Size(538, 468),
  double textScale = 1,
  bool hiddenPokedex = false,
  String logicalSelectionId = 'pause.party',
  RuntimeWorldServiceSnapshot? worldService,
  DialoguePresentationSnapshot? dialogue,
  SceneInteractionRequest? interaction,
  bool narrativeReady = true,
  bool title = false,
}) async {
  await _loadPlayerFonts(tester);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  const channel = MethodChannel('com.avelune.runtime/companion');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  var state = AveluneGameplayCompanionSnapshot(
    sessionId: 'session-grid',
    revision: 8,
    dialogue: dialogue,
    narrativeGeneration: 1,
    narrativeReady:
        narrativeReady && (title || dialogue != null || interaction != null),
    presentation: {if (title) 'startupRevision': 20},
    companionAttached: true,
    mode: AveluneGameplayCompanionMode.menu,
    player: RuntimePlayerSnapshot(
      revision: 7,
      phase: title
          ? RuntimePlayerPhase.title
          : interaction != null
          ? RuntimePlayerPhase.preSession
          : worldService != null || dialogue != null
          ? RuntimePlayerPhase.playing
          : RuntimePlayerPhase.paused,
      preSessionRequest: interaction,
      worldService: worldService,
      gameTitle: 'Avelune test',
      pauseSection: RuntimePlayerPauseSection.root,
      logicalSelectionId: logicalSelectionId,
      pauseMenuState: PlayerPauseMenuState(
        visibilityOverrides: {
          if (hiddenPokedex) ProjectPauseActionId.pokedex: false,
        },
      ),
      actions: [
        for (final action in RuntimePlayerAction.values)
          action == RuntimePlayerAction.openMap
              ? RuntimePlayerActionAvailability.disabled(
                  action,
                  reason: 'Carte verrouillée',
                )
              : RuntimePlayerActionAvailability.enabled(action),
      ],
    ),
  );
  final calls = <Map<String, dynamic>>[];
  messenger.setMockMethodCallHandler(channel, (call) async {
    if (call.method == 'intent') {
      calls.add(Map<String, dynamic>.from(call.arguments as Map));
      if (calls.last['kind'] == 'narrativeReady') {
        state = AveluneGameplayCompanionSnapshot.fromPayload({
          ...state.toPayload(),
          'revision': state.revision + 1,
          'narrativeReady': true,
        });
      }
    }
    return state.toPayload();
  });
  addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
  await tester.pumpWidget(const AveluneGameplayCompanionApp());
  await tester.pumpAndSettle();
  return calls;
}

AveluneGameplayCompanionSnapshot _savedSnapshot() {
  const address = RuntimePlayerSaveAddress(
    gameId: 'test-game',
    profileId: 'test-profile',
    slotId: 'test-slot',
  );
  return AveluneGameplayCompanionSnapshot(
    sessionId: 'session-a',
    revision: 8,
    companionAttached: true,
    mode: AveluneGameplayCompanionMode.menu,
    player: RuntimePlayerSnapshot(
      revision: 7,
      phase: RuntimePlayerPhase.paused,
      gameTitle: 'Avelune test',
      activeSaveAddress: address,
      saveReceipt: const RuntimePlayerSaveReceipt(
        address: address,
        trigger: GameSessionCheckpointTrigger.manual,
      ),
    ),
  );
}

Future<Object?> _nativeCall(
  MethodChannel channel,
  String method,
  Object? arguments,
) {
  const codec = StandardMethodCodec();
  final complete = Completer<Object?>();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        channel.name,
        codec.encodeMethodCall(MethodCall(method, arguments)),
        (reply) {
          try {
            if (reply == null) throw MissingPluginException();
            complete.complete(codec.decodeEnvelope(reply));
          } on Object catch (error) {
            complete.completeError(error);
          }
        },
      );
  return complete.future;
}

Map<String, Object?> _intent(
  AveluneGameplayCompanionSnapshot state, {
  int sequence = 1,
}) => {
  'sessionId': state.sessionId,
  'revision': state.revision,
  'mode': state.mode.name,
  'sourceId': 'companion-1',
  'sequence': sequence,
  'kind': 'player',
  'payload': RuntimeCompanionPresentationCodec.encodePlayerCommand(
    RuntimePlayerCommand(
      action: RuntimePlayerAction.openParty,
      snapshotRevision: state.player!.revision,
    ),
  ),
};

Matcher _error(String code) => throwsA(
  isA<PlatformException>().having((error) => error.code, 'code', code),
);

class _Port implements AveluneGameplayCompanionOwnerPort {
  final executed = <Map<String, Object?>>[];
  Completer<void>? gate;
  Completer<void>? readGate;
  int reads = 0;
  int concurrentReads = 0;
  int maximumConcurrentReads = 0;
  bool paused = false;
  RuntimeWorldServiceSnapshot? service;
  DialoguePresentationSnapshot? dialogue;
  RuntimePlayerSnapshot? playerOverride;
  Map<String, Object?> presentation = {};

  int battleReleases = 0;
  BattleCommandOverlaySnapshot? battle;

  @override
  void releaseBattleInputs() => battleReleases++;

  @override
  bool get isPaused => paused;

  @override
  Future<AveluneGameplayCompanionData> read() async {
    reads++;
    concurrentReads++;
    if (concurrentReads > maximumConcurrentReads) {
      maximumConcurrentReads = concurrentReads;
    }
    await readGate?.future;
    concurrentReads--;
    return AveluneGameplayCompanionData(
      mode: battle == null
          ? AveluneGameplayCompanionMode.menu
          : AveluneGameplayCompanionMode.battle,
      battle: battle,
      dialogue: dialogue,
      presentation: presentation,
      player:
          playerOverride ??
          RuntimePlayerSnapshot(
            revision: 7,
            phase: dialogue == null
                ? RuntimePlayerPhase.paused
                : RuntimePlayerPhase.playing,
            worldService: service,
            gameTitle: 'Avelune test',
            actions: const [
              RuntimePlayerActionAvailability.enabled(
                RuntimePlayerAction.openParty,
              ),
            ],
          ),
    );
  }

  @override
  Future<void> execute(
    String kind,
    Map<String, Object?> payload,
    AveluneGameplayCompanionSnapshot expected,
  ) async {
    executed.add(payload);
    await gate?.future;
  }
}

RuntimeWorldServiceSnapshot _pcService() => RuntimeWorldServiceSnapshot(
  revision: 9,
  request: const OpenPcService(interactionId: 'terminal'),
  stage: RuntimeWorldServiceStage.active,
  content: RuntimePcServiceContent(
    title: 'PC companion',
    message: '',
    selectedBoxId: 'box',
    boxes: const [
      RuntimePcBoxSnapshot(boxId: 'box', label: 'Box', count: 1, capacity: 30),
    ],
    stored: [
      RuntimePcPokemonSnapshot(
        targetId: 'opaque-pokemon',
        label: 'Bird',
        speciesId: 'bird',
        level: 7,
        natureId: 'hardy',
        abilityId: 'clockwork',
        currentHp: 5,
        canTransfer: true,
      ),
    ],
  ),
  actions: const [
    RuntimeWorldServiceActionAvailability.enabled(
      RuntimeWorldServiceAction.withdraw,
    ),
    RuntimeWorldServiceActionAvailability.enabled(
      RuntimeWorldServiceAction.close,
    ),
  ],
);

DialoguePresentationSnapshot _narrative({
  int revision = 8,
  String text = 'Bonjour',
  String fullText = 'Bonjour',
}) => DialoguePresentationSnapshot(
  revision: revision,
  mode: DialoguePresentationMode.line,
  nodeTitle: 'station',
  speaker: 'Guide',
  text: text,
  fullText: fullText,
  isCurrentLineFullyRevealed: text == fullText,
  isLastContent: false,
  choices: const [],
);

Future<void>? _playerFonts;

Future<void> _loadPlayerFonts(WidgetTester tester) async {
  await tester.runAsync(() => _playerFonts ??= _loadPlayerFontFiles());
}

Future<void> _loadPlayerFontFiles() async {
  for (final (family, filename) in [
    ('PokeMapSplashDMSans', 'DMSans-Variable.ttf'),
    ('PokeMapSplashMarcellus', 'Marcellus-Regular.ttf'),
  ]) {
    final bytes = await File(
      '../../packages/map_player_ui/assets/fonts/$filename',
    ).readAsBytes();
    final loader = FontLoader('packages/map_player_ui/$family');
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }
}

Future<void> _tapKeyboardCharacter(
  WidgetTester tester,
  String character,
) async {
  final key = find.byKey(ValueKey('scene-keyboard-char-$character'));
  for (var attempt = 0; attempt < 64; attempt++) {
    if (key.evaluate().isNotEmpty) {
      await tester.tap(key);
      await tester.pumpAndSettle();
      return;
    }
    final next = find.byKey(const ValueKey('scene-keyboard-page'));
    expect(next, findsOneWidget, reason: 'Keyboard character $character');
    await tester.tap(next);
    await tester.pumpAndSettle();
  }
  fail('Keyboard character $character was never reachable.');
}

AveluneGameplayCompanionSnapshot _battleEnvelope({
  int revision = 8,
  int battleRevision = 20,
  int selectedIndex = 0,
  BattleCommandOverlayMode mode = BattleCommandOverlayMode.fight,
}) => AveluneGameplayCompanionSnapshot(
  sessionId: 'battle-session',
  revision: revision,
  companionAttached: true,
  mode: AveluneGameplayCompanionMode.battle,
  battle: _battleFixture(
    revision: battleRevision,
    mode: mode,
    selectedIndex: selectedIndex,
  ),
);

Map<String, Object?> _battleInput(
  AveluneGameplayCompanionSnapshot state,
  RuntimeInputControl control, {
  bool release = false,
}) => {
  'sessionId': state.sessionId,
  'revision': state.revision,
  'mode': 'battle',
  'battleRevision': state.battle!.revision,
  'battleMode': state.battle!.mode.name,
  'control': control.name,
  'phase': release ? 'release' : 'press',
  'isRepeat': false,
};

BattleCommandOverlaySnapshot _battleFixture({
  int revision = 20,
  int selectedIndex = 0,
  BattleCommandOverlayMode mode = BattleCommandOverlayMode.fight,
}) => BattleCommandOverlaySnapshot(
  revision: revision,
  mode: mode,
  viewportSize: const Size(496, 432),
  panelRect: const Rect.fromLTWH(0, 0, 496, 432),
  enemyHud: const BattleCommandOverlayHudSnapshot(
    rect: Rect.fromLTWH(0, 0, 100, 48),
    ownerLabel: 'Enemy',
    speciesLabel: 'Bird',
    level: 5,
    currentHp: 20,
    maxHp: 20,
    isPlayerSide: false,
  ),
  playerHud: const BattleCommandOverlayHudSnapshot(
    rect: Rect.fromLTWH(0, 300, 100, 48),
    ownerLabel: 'Player',
    speciesLabel: 'Sprout',
    level: 5,
    currentHp: 20,
    maxHp: 20,
    isPlayerSide: true,
  ),
  battleLabel: 'Battle',
  title: 'Moves',
  prompt: 'Choose a move',
  narrationLines: const [],
  entries: [
    for (final (index, name) in [(0, 'A'), (1, 'B')])
      BattleCommandOverlayEntry(
        index: index,
        kind: BattleCommandOverlayEntryKind.move,
        primaryLabel: name,
        secondaryLabel: 'normal',
        trailingLabel: 'PP 1/5',
        enabled: true,
        selected: index == selectedIndex,
        tone: BattleCommandOverlayEntryTone.neutral,
      ),
  ],
  interactionsEnabled: true,
  canGoBack: true,
);
