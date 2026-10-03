import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_hub/embedding/avelune_gameplay_companion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('transport starts without opening a menu or creating a player', () async {
    final owner = AveluneGameplayCompanionOwner();
    addTearDown(owner.dispose);
    owner.start('session-a');
    expect(owner.value!.mode, AveluneGameplayCompanionMode.waiting);
    expect(owner.value!.player, isNull);
    expect(owner.value!.companionAttached, isFalse);
  });

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
    expect(AveluneGameplayCompanionSnapshot.fromPayload(state.toPayload()).player!.revision, 7);
  });

  test('intent rejects stale session revision mode and detached surfaces', () async {
    final owner = AveluneGameplayCompanionOwner();
    addTearDown(owner.dispose);
    owner.start('session-a');
    owner.bind(_Port());
    await owner.refresh();
    final state = owner.value!;
    await expectLater(owner.applyIntent(_intent(state)), _error('companionDetached'));
    owner.setCompanionAttached('session-a', true);
    final attached = owner.value!;
    await expectLater(owner.applyIntent({..._intent(attached), 'sessionId': 'old'}), _error('staleSession'));
    await expectLater(owner.applyIntent({..._intent(attached), 'revision': attached.revision - 1}), _error('staleRevision'));
    await expectLater(owner.applyIntent({..._intent(attached), 'mode': 'battle'}), _error('staleMode'));
  });

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
    await expectLater(owner.applyIntent({...intent, 'sequence': 2}), _error('runtimeBusy'));
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

  test('input forwards only the paused current owner to the attached companion', () async {
    final owner = AveluneGameplayCompanionOwner();
    addTearDown(owner.dispose);
    final port = _Port();
    owner.start('session-a');
    owner.bind(port);
    await owner.refresh();
    owner.setCompanionAttached('session-a', true);
    expect(owner.inputPayload(const RuntimeInputEvent.press(RuntimeInputControl.primary)), isNull);
    port.paused = true;
    final input = owner.inputPayload(const RuntimeInputEvent.press(RuntimeInputControl.primary));
    expect(input!['sessionId'], 'session-a');
    expect(input['control'], 'primary');
    expect(input['phase'], 'press');
    owner.setCompanionAttached('session-a', false);
    expect(owner.inputPayload(const RuntimeInputEvent.press(RuntimeInputControl.primary)), isNull);
  });

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

  test('stopping invalidates an asynchronous read without resurrecting the menu', () async {
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
  });

  test('duplicate native notifications and replies preserve the save receipt instance', () async {
    const channel = MethodChannel('avelune.gameplay.test.receipt');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
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
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
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
    final action = remote.send('back', {'snapshotRevision': state.player!.revision});
    await _nativeCall(channel, 'stateChanged', null);
    reply.complete(state.toPayload());
    await action;
    expect(remote.value, isNull);
  });

  test('remote input accepts only the active menu envelope', () async {
    const channel = MethodChannel('avelune.gameplay.test.input');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
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
    final input = {'sessionId': state.sessionId, 'revision': state.revision, 'control': 'primary', 'phase': 'press', 'isRepeat': false};
    await _nativeCall(channel, 'input', {...input, 'revision': state.revision - 1});
    await _nativeCall(channel, 'input', {...input, 'sessionId': 'old-session'});
    await _nativeCall(channel, 'input', input);
    expect(inputs, [const RuntimeInputEvent.press(RuntimeInputControl.primary)]);
  });
}

AveluneGameplayCompanionSnapshot _savedSnapshot() {
  const address = RuntimePlayerSaveAddress(gameId: 'test-game', profileId: 'test-profile', slotId: 'test-slot');
  return AveluneGameplayCompanionSnapshot(
    sessionId: 'session-a', revision: 8, companionAttached: true, mode: AveluneGameplayCompanionMode.menu,
    player: RuntimePlayerSnapshot(
      revision: 7, phase: RuntimePlayerPhase.paused, gameTitle: 'Avelune test', activeSaveAddress: address,
      saveReceipt: const RuntimePlayerSaveReceipt(address: address, trigger: GameSessionCheckpointTrigger.manual),
    ),
  );
}

Future<Object?> _nativeCall(MethodChannel channel, String method, Object? arguments) {
  const codec = StandardMethodCodec();
  final complete = Completer<Object?>();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
    channel.name, codec.encodeMethodCall(MethodCall(method, arguments)), (reply) {
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

Map<String, Object?> _intent(AveluneGameplayCompanionSnapshot state, {int sequence = 1}) => {
  'sessionId': state.sessionId,
  'revision': state.revision,
  'mode': state.mode.name,
  'sourceId': 'companion-1',
  'sequence': sequence,
  'kind': 'player',
  'payload': RuntimeCompanionPresentationCodec.encodePlayerCommand(
    RuntimePlayerCommand(action: RuntimePlayerAction.openParty, snapshotRevision: state.player!.revision),
  ),
};

Matcher _error(String code) => throwsA(isA<PlatformException>().having((error) => error.code, 'code', code));

class _Port implements AveluneGameplayCompanionOwnerPort {
  final executed = <Map<String, Object?>>[];
  Completer<void>? gate;
  Completer<void>? readGate;
  int reads = 0;
  int concurrentReads = 0;
  int maximumConcurrentReads = 0;
  bool paused = false;

  @override
  bool get isPaused => paused;

  @override
  Future<AveluneGameplayCompanionData> read() async {
    reads++;
    concurrentReads++;
    if (concurrentReads > maximumConcurrentReads) maximumConcurrentReads = concurrentReads;
    await readGate?.future;
    concurrentReads--;
    return AveluneGameplayCompanionData(
    mode: AveluneGameplayCompanionMode.menu,
    player: RuntimePlayerSnapshot(
      revision: 7,
      phase: RuntimePlayerPhase.paused,
      gameTitle: 'Avelune test',
      actions: const [RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.openParty)],
    ),
    );
  }

  @override
  Future<void> execute(String kind, Map<String, Object?> payload, AveluneGameplayCompanionSnapshot expected) async {
    executed.add(payload);
    await gate?.future;
  }
}
