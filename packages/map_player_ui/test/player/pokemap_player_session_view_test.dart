import 'dart:async';
import 'dart:ui'
    as ui
    show
        KeyData,
        KeyEventType,
        KeyEventDeviceType,
        PointerDeviceKind,
        ViewFocusEvent,
        ViewFocusState,
        ViewFocusDirection;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/player/runtime_player_options.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets(
    'stable overworld action stays opaque across hardware input and session updates',
    (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(
        _snapshot(revision: 1, phase: RuntimePlayerPhase.playing),
      );
      final interactions = ValueNotifier(_overworldSnapshot());
      final dispatched = <RuntimeOverworldInteractionRequest>[];
      addTearDown(controller.dispose);
      addTearDown(interactions.dispose);
      await _pumpMeasuredSessionWidget(
        tester,
        _app(
          _view(
            controller,
            overworldInteractions: interactions,
            onOverworldInteraction: (request) {
              dispatched.add(request);
              return true;
            },
            gameplayInputRoute: (_) => true,
          ),
        ),
      );
      final capsule = find.byType(PlayerOverworldActionCapsule);
      RuntimePlayerInputSourceNotification(PlayerInputSource.keyboard).dispatch(
        tester.element(capsule),
      );
      await tester.pumpAndSettle();
      final initialElement = tester.element(capsule);
      final appearance = find.descendant(
        of: capsule,
        matching: find.byType(Opacity),
      );
      expect(tester.widget<Opacity>(appearance).opacity, 1);
      final obsoleteActivation = tester
          .widget<PlayerOverworldActionCapsule>(capsule)
          .onPressed!;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      controller.publish(
        _snapshot(revision: 2, phase: RuntimePlayerPhase.playing),
      );
      await tester.idle();
      await tester.pump();
      expect(
        tester
            .widget<RuntimePlayerSurfaceRouter>(
              find.byType(RuntimePlayerSurfaceRouter),
            )
            .snapshot
            .revision,
        2,
      );
      expect(tester.widget<Opacity>(appearance).opacity, 1);
      expect(tester.element(capsule), same(initialElement));
      expect(capsule.hitTestable(), findsOneWidget);
      obsoleteActivation();
      expect(dispatched, isEmpty);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      final oldGesture = await tester.startGesture(tester.getCenter(capsule));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      controller.publish(
        _snapshot(revision: 3, phase: RuntimePlayerPhase.playing),
      );
      await tester.idle();
      await tester.pump();
      await oldGesture.up();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(dispatched, isEmpty);
      await tester.tap(capsule);
      expect(dispatched, [interactions.value.primaryAction!.request]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('touch pause entry routes the first Options PageDown without manual focus', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1920, 1080);
    addTearDown(tester.view.reset);
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(
      revision: 86,
      phase: RuntimePlayerPhase.paused,
      actions: [for (final action in RuntimePlayerAction.values)
        RuntimePlayerActionAvailability.enabled(action)],
      preferences: const PlayerPreferencesSnapshot(
        locale: 'fr', accessibility: GameSessionAccessibilityOptions()),
    ));
    addTearDown(controller.dispose);
    await _pumpMeasuredSessionWidget(tester, _app(_view(
      controller,
      touchControlsAvailable: true,
      controllerInputEnabled: false,
      pausePresentation: const PlayerPausePresentation(
        style: ProjectPauseMenuStyle.nightIllustrated,
      ),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.byWidgetPredicate(
      (widget) => widget is PlayerMenuSelectableRow && widget.id == 'pause.options',
    ));
    await tester.pumpAndSettle();
    expect(controller.commands.single.action, RuntimePlayerAction.openOptions);
    controller.publish(_pausedOptionsSnapshot());
    await tester.pumpAndSettle();
    final returnRow = find.byWidgetPredicate(
      (widget) => widget is PlayerMenuSelectableRow && widget.id == 'pause-frame-return',
    );
    expect(tester.widget<PlayerMenuSelectableRow>(returnRow).showFocusHighlight, isFalse);
    expect(find.byKey(const ValueKey('options-text-speed-choice')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('options-menu-effects-choice')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('options-text-speed-choice')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(1920, 1080), const Size(390, 844)]) {
    for (final normalized in [false, true]) {
      testWidgets(
        'composed illustrated options route tabs from frame focus at $size normalized=$normalized',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          addTearDown(tester.view.reset);
          final controller = _FakeRuntimePlayerCoordinator(_pausedOptionsSnapshot());
          final events = StreamController<RuntimeInputEvent>.broadcast();
          final gameplay = <RuntimeInputEvent>[];
          addTearDown(controller.dispose);
          addTearDown(events.close);
          await _pumpMeasuredSessionWidget(tester, _app(_view(
            controller,
            controllerInputEvents: events.stream,
            controllerInputEnabled: normalized,
            pausePresentation: const PlayerPausePresentation(
              style: ProjectPauseMenuStyle.nightIllustrated,
            ),
            gameplayInputRoute: (event) { gameplay.add(event); return true; },
          )));
          await tester.pumpAndSettle();
          final returnRow = find.byWidgetPredicate(
            (widget) => widget is PlayerMenuSelectableRow &&
              widget.id == 'pause-frame-return',
          );
          void focusReturn() => tester.widget<PlayerMenuSelectableRow>(returnRow)
            .focusNode!.requestFocus();
          void focusHeader() {
            final node = FocusManager.instance.rootScope.descendants.firstWhere(
              (node) => node.context?.findAncestorWidgetOfExactType<IconButton>()
                ?.key == const ValueKey('options-category-picker'),
            );
            node.requestFocus();
          }
          expect(tester.widget<PlayerMenuSelectableRow>(returnRow)
            .focusNode!.hasPrimaryFocus, isTrue);
          await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('options-menu-effects-choice')), findsOneWidget);
          focusReturn();
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('options-text-speed-choice')), findsOneWidget);
          focusReturn();
          await tester.pump();
          await _hardwareGamepadPress(tester,
            LogicalKeyboardKey.gameButtonRight1, PhysicalKeyboardKey.gameButtonRight1,
            whileHeld: normalized ? () async {
              events.add(const RuntimeInputEvent.press(RuntimeInputControl.nextTab));
              await tester.pump();
            } : null,
          );
          if (normalized) events.add(const RuntimeInputEvent.release(RuntimeInputControl.nextTab));
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('options-menu-effects-choice')), findsOneWidget);
          focusHeader();
          await tester.pump();
          if (normalized) {
            events.add(const RuntimeInputEvent.press(RuntimeInputControl.previousTab));
            await tester.pump();
            events.add(const RuntimeInputEvent.release(RuntimeInputControl.previousTab));
          } else {
            await _hardwareGamepadPress(tester,
              LogicalKeyboardKey.gameButtonLeft1, PhysicalKeyboardKey.gameButtonLeft1);
          }
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('options-text-speed-choice')), findsOneWidget);
          await tester.tap(find.byKey(const ValueKey('options-text-speed-choice')));
          await tester.pumpAndSettle();
          expect(controller.commands.single.action, RuntimePlayerAction.updatePreferences);
          await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('options-menu-effects-choice')), findsOneWidget);
          focusHeader();
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
          await tester.pumpAndSettle();
          final slider = find.byKey(const ValueKey('options-master-slider'));
          expect(slider, findsOneWidget);
          tester.widget<Slider>(slider).focusNode!.requestFocus();
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
          await tester.pumpAndSettle();
          expect(tester.widget<Slider>(slider).focusNode!.hasPrimaryFocus, isTrue);
          expect(controller.commands.last.action, RuntimePlayerAction.updatePreferences);
          focusReturn();
          await tester.pump();
          if (normalized) {
            events.add(const RuntimeInputEvent.press(RuntimeInputControl.secondary));
            await tester.pump();
            events.add(const RuntimeInputEvent.release(RuntimeInputControl.secondary));
          } else {
            await _hardwareGamepadPress(tester,
              LogicalKeyboardKey.gameButtonB, PhysicalKeyboardKey.gameButtonB);
          }
          await tester.pumpAndSettle();
          expect(controller.commands.where((command) =>
            command.action == RuntimePlayerAction.returnToPauseRoot), hasLength(1));
          expect(controller.commands.where((command) =>
            command.action == RuntimePlayerAction.resume), isEmpty);
          expect(gameplay, isEmpty);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('composed illustrated options preserve authored frame binding collisions', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final data = PlayerControlProfile.standard.toJson();
    for (final device in ['keyboard', 'gamepad', 'touch']) {
      final bindings = data[device] as Map<String, String>;
      bindings.remove('previousTab');
      bindings.remove('nextTab');
    }
    (data['keyboard'] as Map<String, String>)['bicycle'] = 'pageDown';
    (data['gamepad'] as Map<String, String>)['sprint'] = 'rightBumper';
    final controller = _FakeRuntimePlayerCoordinator(_pausedOptionsSnapshot());
    addTearDown(controller.dispose);
    final gameplay = <RuntimeInputEvent>[];
    await _pumpMeasuredSessionWidget(tester, _app(_view(
      controller,
      controlProfile: PlayerControlProfile.fromJson(data),
      pausePresentation: const PlayerPausePresentation(
        style: ProjectPauseMenuStyle.nightIllustrated,
      ),
      gameplayInputRoute: (event) { gameplay.add(event); return true; },
    )));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('options-text-speed-choice')), findsOneWidget);
    await _hardwareGamepadPress(tester,
      LogicalKeyboardKey.gameButtonRight1, PhysicalKeyboardKey.gameButtonRight1);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('options-text-speed-choice')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('runtime-player-text-scale-slider')), findsOneWidget);
    expect(controller.commands, isEmpty);
    expect(gameplay, isEmpty);
    expect(tester.takeException(), isNull);
  });

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets(
      'portrait $platform routes key-only bumpers and normalized bumpers from bag body',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.reset);
        final detail = RuntimePlayerPauseDetailSnapshot(
          section: RuntimePlayerPauseSection.bag,
          title: 'Sac',
          bagPockets: const [
            RuntimePlayerBagPocketSnapshot(id: 'medicine', label: 'Soins'),
            RuntimePlayerBagPocketSnapshot(id: 'balls', label: 'Balls'),
            RuntimePlayerBagPocketSnapshot(id: 'key', label: 'Objets clés'),
          ],
          entries: [
            for (final pocket in ['medicine', 'balls', 'key'])
              RuntimePlayerDetailEntrySnapshot(
                id: pocket,
                title: pocket,
                bagItem: RuntimePlayerBagItemSnapshot(
                  itemId: pocket,
                  quantity: 1,
                  sortOrder: 0,
                  pocketId: pocket,
                  description: 'Objet publié',
                ),
              ),
          ],
        );
        final controller = _FakeRuntimePlayerCoordinator(
          RuntimePlayerSnapshot(
            revision: 12,
            phase: RuntimePlayerPhase.paused,
            gameTitle: 'Aube',
            pauseSection: RuntimePlayerPauseSection.bag,
            actions: [
              for (final action in RuntimePlayerAction.values)
                RuntimePlayerActionAvailability.enabled(action),
            ],
            pauseDetails: {RuntimePlayerPauseSection.bag: detail},
          ),
        );
        final events = StreamController<NormalizedGamepadEvent>.broadcast();
        final connected = ValueNotifier<Set<String>>({'pad'});
        final gameplay = <RuntimeInputEvent>[];
        addTearDown(connected.dispose);
        addTearDown(controller.dispose);
        addTearDown(events.close);
        await _pumpMeasuredSessionWidget(
          tester,
          _app(
            _view(
              controller,
              normalizedControllerInputEvents: events.stream,
              connectedControllerIds: connected,
              gameplayInputRoute: (event) {
                gameplay.add(event);
                return true;
              },
            ),
            platform: platform,
          ),
        );
        await tester.pumpAndSettle();
        void focusItem(String id) => tester
            .widget<PlayerMenuSelectableRow>(
              find.byKey(ValueKey('bag-item-$id')),
            )
            .focusNode!
            .requestFocus();
        focusItem('medicine');
        await tester.pump();
        await _hardwareGamepadPress(
          tester,
          LogicalKeyboardKey.gameButtonRight1,
          PhysicalKeyboardKey.gameButtonX,
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<PlayerMenuSelectableRow>(
                find.byKey(const ValueKey('bag-pocket-balls')),
              )
              .selected,
          isTrue,
        );
        focusItem('balls');
        await tester.pump();
        final focusedItem = tester.widget<PlayerMenuSelectableRow>(
          find.byKey(const ValueKey('bag-item-balls')),
        ).focusNode!;
        expect(focusedItem.context, isNotNull);
        expect(focusedItem.hasPrimaryFocus, isTrue,
          reason: 'The current pocket owns body focus after its transition.');
        events.add(_padInput(button: GamepadButton.leftBumper));
        await tester.pump();
        events.add(_padInput(button: GamepadButton.leftBumper, value: 0));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<PlayerMenuSelectableRow>(
                find.byKey(const ValueKey('bag-pocket-medicine')),
              )
              .selected,
          isTrue,
        );
        focusItem('medicine');
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<PlayerMenuSelectableRow>(
                find.byKey(const ValueKey('bag-pocket-balls')),
              )
              .selected,
          isTrue,
        );
        focusItem('balls');
        await tester.pump();
        events.add(_padInput(button: GamepadButton.rightBumper));
        await tester.pump();
        await _hardwareGamepadPress(
          tester,
          LogicalKeyboardKey.gameButtonRight1,
          PhysicalKeyboardKey.gameButtonX,
        );
        events.add(_padInput(button: GamepadButton.dpadDown));
        await tester.pump();
        connected.value = {};
        await tester.pump();
        events.add(_padInput(button: GamepadButton.rightBumper, value: 0));
        events.add(_padInput(button: GamepadButton.dpadDown, value: 0));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<PlayerMenuSelectableRow>(
                find.byKey(const ValueKey('bag-pocket-key')),
              )
              .selected,
          isTrue,
        );
        expect(gameplay, isEmpty);
        controller.publish(_snapshot(revision: 13, phase: RuntimePlayerPhase.playing));
        await tester.pumpAndSettle();
        connected.value = {'pad'};
        events.add(_padInput(button: GamepadButton.dpadDown));
        await tester.pump();
        events.add(_padInput(button: GamepadButton.dpadDown, value: 0));
        await tester.pump();
        expect(gameplay, const [RuntimeInputEvent.press(RuntimeInputControl.down), RuntimeInputEvent.release(RuntimeInputControl.down)]);
        expect(controller.commands, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final enabled in [false, true]) {
    testWidgets(
      'portrait options has one early input owner with normalized enabled=$enabled',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.reset);
        final controller = _FakeRuntimePlayerCoordinator(
          _titleOptionsSnapshot(),
        );
        final events = StreamController<NormalizedGamepadEvent>.broadcast();
        addTearDown(controller.dispose);
        addTearDown(events.close);
        await _pumpMeasuredSessionWidget(
          tester,
          _app(
            _view(
              controller,
              controllerInputEnabled: enabled,
              normalizedControllerInputEvents: events.stream,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await _selectOptionsCategory(tester, 'audio');
        tester
            .widget<Slider>(find.byKey(const ValueKey('options-master-slider')))
            .focusNode!
            .requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
        await tester.pumpAndSettle();
        expect(find.text('Commandes'), findsWidgets);
        expect(
          find.byKey(const ValueKey('options-language-choice')),
          findsNothing,
        );
        await _hardwareGamepadPress(
          tester,
          LogicalKeyboardKey.gameButtonLeft1,
          PhysicalKeyboardKey.gameButtonX,
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('options-master-slider')),
          findsOneWidget,
        );
        expect(controller.commands, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'key-only controller B keeps gameplay sprint press and held release semantics',
    (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(
        _snapshot(revision: 1, phase: RuntimePlayerPhase.playing),
      );
      final events = StreamController<NormalizedGamepadEvent>.broadcast();
      final routed = <RuntimeInputEvent>[];
      addTearDown(controller.dispose);
      addTearDown(events.close);
      await _pumpMeasuredSessionWidget(
        tester,
        _app(
          _view(
            controller,
            normalizedControllerInputEvents: events.stream,
            gameplayInputRoute: (event) {
              routed.add(event);
              return true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _hardwareGamepadPress(
        tester,
        LogicalKeyboardKey.gameButtonB,
        PhysicalKeyboardKey.gameButtonB,
      );
      await tester.pump();
      expect(routed, const [
        RuntimeInputEvent.press(RuntimeInputControl.sprint),
        RuntimeInputEvent.release(RuntimeInputControl.sprint),
      ]);
      expect(tester.takeException(), isNull);
    },
  );

  for (final first in ['hardware', 'normalized']) {
    testWidgets(
      'portrait modal consumes $first plus duplicate controller A once without gameplay leakage',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.reset);
        final controller = _FakeRuntimePlayerCoordinator(
          _snapshot(revision: 1, phase: RuntimePlayerPhase.playing),
        );
        final events = StreamController<NormalizedGamepadEvent>.broadcast();
        final gameplay = <RuntimeInputEvent>[];
        var confirmations = 0;
        addTearDown(controller.dispose);
        addTearDown(events.close);
        await _pumpMeasuredSessionWidget(
          tester,
          _app(
            _view(
              controller,
              normalizedControllerInputEvents: events.stream,
              gameplayInputRoute: (event) {
                gameplay.add(event);
                return true;
              },
              gameSceneBuilder: (_) => Builder(
                builder: (sceneContext) => Center(
                  child: TextButton(
                    key: const ValueKey('input-open-modal'),
                    onPressed: () => showDialog<void>(
                      context: sceneContext,
                      builder: (modalContext) => RuntimePlayerActions(
                        onBack: () => Navigator.of(modalContext).pop(),
                        onMenu: () {},
                        onInputSourceChanged: (_) {},
                        child: AlertDialog(
                          title: const Text('Confirmation'),
                          actions: [
                            TextButton(
                              key: const ValueKey('input-confirm-modal'),
                              autofocus: true,
                              onPressed: () {
                                confirmations++;
                                Navigator.of(modalContext).pop();
                              },
                              child: const Text('Confirmer'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    child: const Text('Ouvrir'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('input-open-modal')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('input-confirm-modal')).hitTestable(),
          findsOneWidget,
        );
        await _hardwareGamepadPress(
          tester,
          LogicalKeyboardKey.arrowDown,
          PhysicalKeyboardKey.arrowDown,
          whileHeld: () async {
            if (first == 'normalized') {
              events.add(_padInput(button: GamepadButton.a));
              await tester.pump();
            }
            await _hardwareGamepadPress(
              tester,
              LogicalKeyboardKey.gameButtonA,
              PhysicalKeyboardKey.gameButtonA,
              whileHeld: () async {
                if (first == 'hardware')
                  events.add(_padInput(button: GamepadButton.a));
                await tester.pump();
              },
            );
            events.add(_padInput(button: GamepadButton.a, value: 0));
            await tester.pumpAndSettle();
            final authority = tester.widget<Focus>(
              find.byKey(
                const ValueKey('runtime-player-keyboard-input-authority'),
              ),
            );
            authority.onKeyEvent!(
              FocusManager.instance.primaryFocus!,
              const KeyRepeatEvent(
                physicalKey: PhysicalKeyboardKey.arrowDown,
                logicalKey: LogicalKeyboardKey.arrowDown,
                timeStamp: Duration(milliseconds: 500),
                deviceType: ui.KeyEventDeviceType.gamepad,
              ),
            );
            await tester.pump();
            expect(gameplay, isEmpty);
          },
        );
        await tester.pump();
        expect(confirmations, 1);
        expect(find.byType(AlertDialog), findsNothing);
        expect(gameplay, isEmpty);
        expect(controller.commands, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final source in ['keyboard', 'controller', 'physical-controller']) {
    testWidgets('battle info owns $source without selecting a move', (
      tester,
    ) async {
      final inputs = StreamController<RuntimeInputEvent>.broadcast();
      final physicalInputs = StreamController<NormalizedGamepadEvent>.broadcast();
      addTearDown(inputs.close);
      addTearDown(physicalInputs.close);
      final battle = ValueNotifier<BattleCommandOverlaySnapshot?>(
        _moveBattleSnapshot(),
      );
      addTearDown(battle.dispose);
      final controller = _FakeRuntimePlayerCoordinator(
        _snapshot(revision: 90, phase: RuntimePlayerPhase.playing),
      );
      addTearDown(controller.dispose);
      final gameplay = <RuntimeInputEvent>[];
      final selections = <BattlePresentationCommand>[];
      await _pumpMeasuredSessionWidget(
        tester,
        _app(
          _view(
            controller,
            battlePresentation: battle,
            onBattleCommand: selections.add,
            controllerInputEvents: source == 'physical-controller' ? null : inputs.stream,
            normalizedControllerInputEvents: source == 'physical-controller'
                ? physicalInputs.stream
                : null,
            gameplayInputRoute: (event) {
              gameplay.add(event);
              return true;
            },
          ),
        ),
      );
      if (source == 'keyboard') {
        await tester.sendKeyEvent(LogicalKeyboardKey.shiftLeft);
      } else if (source == 'physical-controller') {
        physicalInputs.add(_padInput(button: GamepadButton.y));
        physicalInputs.add(_padInput(button: GamepadButton.y, value: 0));
      } else {
        inputs.add(const RuntimeInputEvent.press(RuntimeInputControl.sprint));
        inputs.add(const RuntimeInputEvent.release(RuntimeInputControl.sprint));
      }
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('battle-move-info-dialog')), findsOneWidget);
      if (source == 'keyboard') {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      } else if (source == 'physical-controller') {
        for (final button in [GamepadButton.dpadDown, GamepadButton.b]) {
          physicalInputs.add(_padInput(button: button));
          physicalInputs.add(_padInput(button: button, value: 0));
          await tester.pumpAndSettle();
        }
      } else {
        for (final control in [RuntimeInputControl.down, RuntimeInputControl.secondary]) {
          inputs.add(RuntimeInputEvent.press(control));
          inputs.add(RuntimeInputEvent.release(control));
          await tester.pumpAndSettle();
        }
      }
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('battle-move-info-dialog')), findsNothing);
      expect(gameplay.where((event) => event.isPress), isEmpty);
      expect(selections.whereType<BattleSelectEntryCommand>(), isEmpty);
      if (source == 'keyboard') {
        await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
      } else if (source == 'physical-controller') {
        physicalInputs.add(_padInput(button: GamepadButton.a));
        physicalInputs.add(_padInput(button: GamepadButton.a, value: 0));
      } else {
        inputs.add(const RuntimeInputEvent.press(RuntimeInputControl.primary));
        inputs.add(const RuntimeInputEvent.release(RuntimeInputControl.primary));
      }
      await tester.pumpAndSettle();
      expect(
        gameplay.where((event) => event.isPress).map((event) => event.control),
        [RuntimeInputControl.primary],
      );
      expect(tester.takeException(), isNull);
    });
  }
  for (final (source, style) in [
    for (final source in ['keyboard', 'controller'])
      for (final style in ProjectPauseMenuStyle.values) (source, style),
  ]) {
    testWidgets('modal exit owns $source in ${style.name} without resuming the paused session', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final events = StreamController<RuntimeInputEvent>.broadcast();
      addTearDown(events.close);
      final controller = _FakeRuntimePlayerCoordinator(
        _snapshot(
          revision: 30,
          phase: RuntimePlayerPhase.paused,
          actions: const [
            RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.resume),
            RuntimePlayerActionAvailability.enabled(
              RuntimePlayerAction.returnToTitle,
            ),
          ],
        ),
      );
      addTearDown(controller.dispose);
      final gameplay = <RuntimeInputEvent>[];
      await _pumpMeasuredSessionWidget(
        tester,
        _app(
          _view(
            controller,
            controllerInputEvents: events.stream,
            pausePresentation: PlayerPausePresentation(style: style),
            gameplayInputRoute: (event) {
              gameplay.add(event);
              return true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final exit = find.byKey(const ValueKey('pause.returnToTitle'));
      await _revealPagedTarget(tester, exit);
      await tester.tap(exit);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('runtime-exit-dialog')), findsOneWidget);
      if (source == 'keyboard') {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      } else {
        events.add(const RuntimeInputEvent.press(RuntimeInputControl.right));
        events.add(const RuntimeInputEvent.release(RuntimeInputControl.right));
      }
      await tester.pumpAndSettle();
      if (source == 'keyboard') {
        await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      } else {
        events.add(const RuntimeInputEvent.press(RuntimeInputControl.menu));
        events.add(const RuntimeInputEvent.release(RuntimeInputControl.menu));
      }
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('runtime-exit-dialog')), findsOneWidget);
      expect(controller.commands, isEmpty);
      expect(controller.backRequests, isEmpty);
      expect(gameplay, isEmpty);
      if (source == 'keyboard') {
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      } else {
        events.add(
          const RuntimeInputEvent.press(RuntimeInputControl.secondary),
        );
        events.add(
          const RuntimeInputEvent.release(RuntimeInputControl.secondary),
        );
      }
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('runtime-exit-dialog')), findsNothing);
      expect(controller.commands, isEmpty);
      expect(controller.backRequests, isEmpty);
      expect(controller.snapshot.phase, RuntimePlayerPhase.paused);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(controller.commands.single.action, RuntimePlayerAction.resume);
    });
  }


  for (final source in [PlayerInputSource.keyboard, PlayerInputSource.controller]) {
    testWidgets('dialogue pages consume ${source.name} before the final runtime advance', (tester) async {
      tester.view.physicalSize = const Size(640, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final authority = ValueNotifier(const RuntimeInputAuthoritySnapshot(
        context: RuntimeInputContext.dialogue));
      final text = List.filled(22, 'Chaque ligne du récit reste accessible avant de continuer.').join('\n');
      final dialogue = ValueNotifier<DialoguePresentationSnapshot?>(DialoguePresentationSnapshot(
        revision: 17, mode: DialoguePresentationMode.line, nodeTitle: 'story',
        speaker: 'Guide', text: text, fullText: text,
        isCurrentLineFullyRevealed: true, isLastContent: true, choices: const []));
      final inputs = StreamController<RuntimeInputEvent>.broadcast();
      final controller = _FakeRuntimePlayerCoordinator(_snapshot(
        revision: 26, phase: RuntimePlayerPhase.playing));
      final routed = <RuntimeInputEvent>[];
      final commands = <DialoguePresentationCommand>[];
      addTearDown(authority.dispose);
      addTearDown(dialogue.dispose);
      addTearDown(inputs.close);
      addTearDown(controller.dispose);
      await _pumpMeasuredSessionWidget(tester, _app(_view(controller,
        gameplayInputAuthority: authority, dialoguePresentation: dialogue,
        onDialogueCommand: commands.add, controllerInputEvents: inputs.stream,
        gameplayInputRoute: (event) { routed.add(event); return true; },
        hapticFeedback: () async {})));
      await tester.pumpAndSettle();
      Future<void> confirm() async {
        if (source == PlayerInputSource.keyboard) {
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        } else {
          inputs.add(const RuntimeInputEvent.press(RuntimeInputControl.primary));
          await tester.pump();
          inputs.add(const RuntimeInputEvent.release(RuntimeInputControl.primary));
        }
        await tester.pumpAndSettle();
      }
      final count = find.byKey(const ValueKey('dialogue-page-count'));
      final first = tester.widget<Text>(count).data;
      await confirm();
      expect(tester.widget<Text>(count).data, isNot(first));
      expect(routed, isEmpty);
      final pages = <String>[first!];
      for (var step = 0; step < 100 && routed.isEmpty; step++) {
        pages.add(tester.widget<Text>(count).data!);
        await confirm();
      }
      expect(pages.length, greaterThan(2));
      expect(routed.where((event) => event.isPress && event.control == RuntimeInputControl.primary), hasLength(1));
      expect(routed.where((event) => !event.isPress && event.control == RuntimeInputControl.primary), hasLength(1));
      expect(commands, isEmpty);
      expect(tester.takeException(), isNull);
      await _pumpMeasuredSessionWidget(tester, const SizedBox.shrink());
    });
  }
  testWidgets('fishing keeps cancel reachable while the world is locked and blocks menus', (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(revision: 1,
      phase: RuntimePlayerPhase.playing, actions: const [
        RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.openMenu),
      ]));
    final authority = ValueNotifier(const RuntimeInputAuthoritySnapshot(
      context: RuntimeInputContext.overworld));
    final events = <RuntimeInputEvent>[];
    addTearDown(controller.dispose);
    addTearDown(authority.dispose);
    await _pumpMeasuredSessionWidget(tester, _app(_view(controller, gameplayInputAuthority: authority,
      gameplayInputRoute: (event) { events.add(event); return true; },
      hapticFeedback: () async {})));
    await tester.pump();
    authority.value = const RuntimeInputAuthoritySnapshot(
      context: RuntimeInputContext.blocked, canCancelWorldAction: true);
    await tester.pump();
    final cancel = find.byKey(const ValueKey('runtime-player-cancel-world-action'));
    expect(cancel, findsOneWidget);
    await tester.tap(cancel);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(events.where((event) => event.isPress && event.control == RuntimeInputControl.secondary), hasLength(2));
    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    await tester.pump();
    expect(controller.commands, isEmpty);
    authority.value = const RuntimeInputAuthoritySnapshot(context: RuntimeInputContext.overworld);
    await tester.pump();
    expect(cancel, findsNothing);
    await _pumpMeasuredSessionWidget(tester, const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
  for (final relayed in [false, true]) {
    testWidgets(
        '${relayed ? 'companion relay' : 'primary owner'} controller input while inactive and unfocused',
        (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(RuntimePlayerSnapshot(
        revision: 7,
        phase: RuntimePlayerPhase.paused,
        gameTitle: 'Aube',
        pauseSection: RuntimePlayerPauseSection.root,
        logicalSelectionId: 'pause.party',
        actions: const [
          RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.resume),
          RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.openParty),
          RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.openBag),
        ],
      ));
      final inputs = StreamController<RuntimeInputEvent>.broadcast();
      addTearDown(controller.dispose);
      addTearDown(inputs.close);
      addTearDown(() {
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        tester.binding.handleViewFocusChanged(ui.ViewFocusEvent(
          viewId: tester.view.viewId,
          state: ui.ViewFocusState.focused,
          direction: ui.ViewFocusDirection.undefined,
        ));
      });
      await _pumpMeasuredSessionWidget(tester, _app(_view(
        controller,
        controllerInputEvents: inputs.stream,
        relayedControllerInput: relayed,
        hapticFeedback: () async {},
      )));
      await tester.pumpAndSettle();
      final focus = tester.widget<RuntimePlayerPauseShell>(
          find.byType(RuntimePlayerPauseShell)).focusController!;
      expect(focus.logicalSelectionId, 'pause.party');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleViewFocusChanged(ui.ViewFocusEvent(
        viewId: tester.view.viewId,
        state: ui.ViewFocusState.unfocused,
        direction: ui.ViewFocusDirection.undefined,
      ));
      await tester.pump();

      inputs.add(const RuntimeInputEvent.press(RuntimeInputControl.down));
      await tester.pump();
      inputs.add(const RuntimeInputEvent.release(RuntimeInputControl.down));
      await tester.pump();
      final selected = focus.logicalSelectionId;
      expect(controller.commands, isEmpty);
      if (relayed) {
        expect(selected, isNot('pause.party'));
        expect(selected, anyOf('pause.resume', 'pause.bag'));
      } else {
        expect(selected, 'pause.party');
      }

      inputs.add(const RuntimeInputEvent.press(RuntimeInputControl.primary));
      await tester.pump();
      inputs.add(const RuntimeInputEvent.release(RuntimeInputControl.primary));
      await tester.pump();

      if (relayed) {
        expect(controller.commands, hasLength(1));
        expect(controller.commands.single.action,
            selected == 'pause.bag' ? RuntimePlayerAction.openBag : RuntimePlayerAction.resume);
        expect(controller.commands.single.snapshotRevision, 7);
      } else {
        expect(controller.commands, isEmpty);
      }
      await _pumpMeasuredSessionWidget(tester, const SizedBox.shrink());
    });
  }

  testWidgets('companion command ingress preserves the battle menu guard', (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
    final commands = RuntimePlayerSessionCommandController();
    final authority = ValueNotifier(const RuntimeInputAuthoritySnapshot(context: RuntimeInputContext.battle));
    final blocked = ValueNotifier(false);
    addTearDown(controller.dispose);
    addTearDown(authority.dispose);
    addTearDown(blocked.dispose);
    await _pumpMeasuredSessionWidget(tester, _app(_view(controller, commandController: commands, gameplayInputAuthority: authority, menuInteractionBlocked: blocked, hapticFeedback: () async {})));
    final rejected = await commands.dispatch(const RuntimePlayerCommand(action: RuntimePlayerAction.openMenu, snapshotRevision: 1));
    expect(rejected.status, RuntimePlayerCommandStatus.unavailable);
    expect(controller.commands, isEmpty);
    authority.value = const RuntimeInputAuthoritySnapshot(context: RuntimeInputContext.overworld);
    blocked.value = true;
    final curtain = await commands.dispatch(const RuntimePlayerCommand(action: RuntimePlayerAction.openMenu, snapshotRevision: 1));
    expect(curtain.status, RuntimePlayerCommandStatus.unavailable);
    expect(controller.commands, isEmpty);
    blocked.value = false;
    final stale = await commands.dispatch(const RuntimePlayerCommand(action: RuntimePlayerAction.openMenu, snapshotRevision: 0));
    expect(stale.status, RuntimePlayerCommandStatus.stale);
    final accepted = await commands.dispatch(const RuntimePlayerCommand(action: RuntimePlayerAction.openMenu, snapshotRevision: 1));
    expect(accepted.status, RuntimePlayerCommandStatus.accepted);
    expect(controller.commands.single.action, RuntimePlayerAction.openMenu);
    await _pumpMeasuredSessionWidget(tester, const SizedBox.shrink());
    final detached = await commands.dispatch(const RuntimePlayerCommand(action: RuntimePlayerAction.openMenu, snapshotRevision: 1));
    expect(detached.status, RuntimePlayerCommandStatus.unavailable);
  });

  testWidgets(
    'confirmed narrative owner receives A once and disconnect restores primary scene',
    (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(
        _snapshot(revision: 1, phase: RuntimePlayerPhase.playing),
      );
      final inputs = StreamController<RuntimeInputEvent>.broadcast();
      final lifecycle = _SceneLifecycle();
      final viewportKey = GlobalKey();
      final text = List.filled(
        20,
        'La narration possède ses propres pages.',
      ).join(' ');
      final dialogue = ValueNotifier<DialoguePresentationSnapshot?>(
        DialoguePresentationSnapshot(
          revision: 8,
          mode: DialoguePresentationMode.line,
          nodeTitle: 'intro',
          speaker: 'Guide',
          text: text,
          fullText: text,
          isCurrentLineFullyRevealed: true,
          isLastContent: false,
          choices: const [],
        ),
      );
      final forwarded = <RuntimeInputEvent>[];
      final gameplay = <RuntimeInputEvent>[];
      final commands = <DialoguePresentationCommand>[];
      addTearDown(controller.dispose);
      addTearDown(inputs.close);
      addTearDown(dialogue.dispose);
      Widget build(bool attached) => _app(
        _view(
          controller,
          lifecycle: lifecycle,
          gameplayViewportKey: viewportKey,
          controllerInputEvents: inputs.stream,
          companionNarrativeAttached: attached,
          dialoguePresentation: dialogue,
          onDialogueCommand: commands.add,
          onCompanionInput: (event) {
            forwarded.add(event);
            return true;
          },
          gameplayInputRoute: (event) {
            gameplay.add(event);
            return true;
          },
        ),
      );
      await _pumpMeasuredSessionWidget(tester, build(true));
      expect(find.byKey(const ValueKey('dialogue-tap-zone')), findsNothing);
      for (final event in [
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
        const RuntimeInputEvent.release(RuntimeInputControl.primary),
      ]) {
        inputs.add(event);
        await tester.pump();
      }
      expect(forwarded, [
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
        const RuntimeInputEvent.release(RuntimeInputControl.primary),
      ]);
      expect(commands, isEmpty);
      expect(gameplay, isEmpty);
      await _pumpMeasuredSessionWidget(tester, build(false));
      expect(find.byKey(const ValueKey('dialogue-tap-zone')), findsOneWidget);
      expect(lifecycle.mounts, 1);
      expect(lifecycle.disposals, 0);
    },
  );

  testWidgets(
    'confirmed pre-session owner hides only interaction and restores it on disconnect',
    (tester) async {
      final request = SceneInteractionRequest.confirmation(
        requestId: 'train',
        revision: 4,
        prompt: SceneInteractionPrompt(
          localizationKey: 'train',
          fallbackText: 'Partir ?',
        ),
      );
      final controller = _FakeRuntimePlayerCoordinator(
        RuntimePlayerSnapshot(
          revision: 12,
          phase: RuntimePlayerPhase.preSession,
          gameTitle: 'Aube',
          preSessionRequest: request,
          actions: const [
            RuntimePlayerActionAvailability.enabled(
              RuntimePlayerAction.resolvePreSessionInteraction,
            ),
          ],
        ),
      );
      addTearDown(controller.dispose);
      await _pumpMeasuredSessionWidget(
        tester,
        _app(_view(controller, companionNarrativeAttached: true)),
      );
      expect(
        find.byKey(const ValueKey('scene-interaction-confirm-yes')),
        findsNothing,
      );
      expect(controller.commands, isEmpty);
      await _pumpMeasuredSessionWidget(tester, _app(_view(controller)));
      await tester.tap(
        find.byKey(const ValueKey('scene-interaction-confirm-yes')),
      );
      await tester.pump();
      expect(controller.commands, hasLength(1));
      final command = controller.commands.single;
      expect(command.snapshotRevision, 12);
      expect(
        command.payload,
        SceneInteractionResult.confirmed(
          requestId: 'train',
          revision: 4,
          value: true,
        ),
      );
    },
  );

  testWidgets('companion pagination consumes local A pages before one canonical advance', (tester) async {
    tester.view.physicalSize = const Size(496, 432);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(revision: 4, phase: RuntimePlayerPhase.playing));
    final inputs = StreamController<RuntimeInputEvent>.broadcast();
    final text = List.filled(24, 'Chaque page reste lisible sur le compagnon.').join(' ');
    final dialogue = ValueNotifier<DialoguePresentationSnapshot?>(DialoguePresentationSnapshot(
      revision: 8, mode: DialoguePresentationMode.line, nodeTitle: 'intro', speaker: 'Guide',
      text: text, fullText: text, isCurrentLineFullyRevealed: true, isLastContent: false, choices: const []));
    final commands = <DialoguePresentationCommand>[];
    addTearDown(controller.dispose);
    addTearDown(inputs.close);
    addTearDown(dialogue.dispose);
    await _pumpMeasuredSessionWidget(tester, _app(_view(controller,
      controllerInputEvents: inputs.stream, relayedControllerInput: true,
      dialoguePresentation: dialogue, onDialogueCommand: commands.add)));
    await tester.pumpAndSettle();
    Future<void> confirm() async {
      inputs.add(const RuntimeInputEvent.press(RuntimeInputControl.primary));
      await tester.pump();
      inputs.add(const RuntimeInputEvent.release(RuntimeInputControl.primary));
      await tester.pumpAndSettle();
    }
    final count = find.byKey(const ValueKey('dialogue-page-count'));
    final first = tester.widget<Text>(count).data;
    await confirm();
    expect(tester.widget<Text>(count).data, isNot(first));
    expect(commands, isEmpty);
    for (var i = 0; i < 100 && commands.isEmpty; i++) {
      await confirm();
    }
    expect(commands, hasLength(1));
    expect(commands.single, isA<DialogueAdvanceCommand>().having((command) => command.snapshotRevision, 'revision', 8));
    expect(controller.commands, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('companion menu disconnect restores primary menu without remounting game', (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(revision: 1, phase: RuntimePlayerPhase.paused));
    final lifecycle = _SceneLifecycle();
    final viewportKey = GlobalKey();
    addTearDown(controller.dispose);
    await _pumpMeasuredSessionWidget(tester, _app(_view(controller, lifecycle: lifecycle, gameplayViewportKey: viewportKey, companionMenusAttached: true)));
    expect(tester.widget<RuntimePlayerSurfaceRouter>(find.byType(RuntimePlayerSurfaceRouter)).showPlayerOverlay, isFalse);
    expect(lifecycle.mounts, 1);
    await _pumpMeasuredSessionWidget(tester, _app(_view(controller, lifecycle: lifecycle, gameplayViewportKey: viewportKey)));
    expect(tester.widget<RuntimePlayerSurfaceRouter>(find.byType(RuntimePlayerSurfaceRouter)).showPlayerOverlay, isTrue);
    expect(lifecycle.mounts, 1);
    expect(lifecycle.disposals, 0);
  });

  for (final serviceActive in [false, true]) {
    testWidgets(
      'companion owner receives held tab release on disconnect with service $serviceActive',
      (tester) async {
        final controller = _FakeRuntimePlayerCoordinator(
          _snapshot(
            revision: 1,
            phase: serviceActive
                ? RuntimePlayerPhase.playing
                : RuntimePlayerPhase.paused,
            worldService: serviceActive
                ? RuntimeWorldServiceSnapshot(
                    revision: 1,
                    request: const OpenPcService(
                      interactionId: 'pc',
                      storageId: 'box',
                    ),
                    stage: RuntimeWorldServiceStage.active,
                  )
                : null,
          ),
        );
        final inputs = StreamController<RuntimeInputEvent>.broadcast();
        final connected = ValueNotifier<Set<String>>({'pad'});
        final forwarded = <RuntimeInputEvent>[];
        final gameplay = <RuntimeInputEvent>[];
        addTearDown(controller.dispose);
        addTearDown(inputs.close);
        addTearDown(connected.dispose);
        await _pumpMeasuredSessionWidget(
          tester,
          _app(
            _view(
              controller,
              controllerInputEvents: inputs.stream,
              connectedControllerIds: connected,
              companionMenusAttached: true,
              onCompanionInput: (event) {
                forwarded.add(event);
                return true;
              },
              gameplayInputRoute: (event) {
                gameplay.add(event);
                return true;
              },
            ),
          ),
        );
        inputs.add(const RuntimeInputEvent.press(RuntimeInputControl.nextTab));
        await tester.pump();
        connected.value = {};
        await tester.pump();
        expect(forwarded, const [
          RuntimeInputEvent.press(RuntimeInputControl.nextTab),
          RuntimeInputEvent.release(RuntimeInputControl.nextTab),
        ]);
        expect(gameplay, isEmpty);
        inputs.add(const RuntimeInputEvent.release(RuntimeInputControl.nextTab));
        await tester.pump();
        expect(forwarded, hasLength(2));
        expect(gameplay, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('companion owner forwards paused controller input and retains overworld input', (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(revision: 1, phase: RuntimePlayerPhase.paused));
    final inputs = StreamController<RuntimeInputEvent>.broadcast();
    final forwarded = <RuntimeInputEvent>[];
    final gameplay = <RuntimeInputEvent>[];
    addTearDown(controller.dispose);
    addTearDown(inputs.close);
    await _pumpMeasuredSessionWidget(tester, _app(_view(controller,
      controllerInputEvents: inputs.stream, companionMenusAttached: true,
      onCompanionInput: (event) { forwarded.add(event); return true; },
      gameplayInputRoute: (event) { gameplay.add(event); return true; },
    )));
    inputs.add(const RuntimeInputEvent.press(RuntimeInputControl.down));
    await tester.pump();
    expect(forwarded, [const RuntimeInputEvent.press(RuntimeInputControl.down)]);
    expect(gameplay, isEmpty);
    inputs.add(const RuntimeInputEvent.release(RuntimeInputControl.down));
    await tester.pump();
    controller.publish(_snapshot(revision: 2, phase: RuntimePlayerPhase.playing));
    await tester.pump();
    forwarded.clear();
    gameplay.clear();
    inputs.add(const RuntimeInputEvent.press(RuntimeInputControl.right));
    await tester.pump();
    expect(forwarded, isEmpty);
    expect(gameplay, contains(const RuntimeInputEvent.press(RuntimeInputControl.right)));
  });
  testWidgets('OW006 hidden item world tap dispatches once without a capsule',
      (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(
        revision: 1, phase: RuntimePlayerPhase.playing));
    final interactions = ValueNotifier(_overworldSnapshot(tapOnly: true));
    final requests = <RuntimeOverworldInteractionRequest>[];
    final inputs = <RuntimeInputEvent>[];
    final viewportKey = GlobalKey();
    addTearDown(controller.dispose);
    addTearDown(interactions.dispose);
    await _pumpMeasuredSessionWidget(tester, _app(_view(controller,
        gameplayViewportKey: viewportKey,
        gameSceneBuilder: (_) => SizedBox.expand(key: viewportKey),
        touchControlsAvailable: true,
        gameplayInputRoute: (event) { inputs.add(event); return true; },
        overworldInteractions: interactions,
        hitTestOverworldInteraction: (point) =>
            const Rect.fromLTWH(580, 80, 40, 40).contains(point)
                ? interactions.value.tapAction?.request : null,
        onOverworldInteraction: (request) { requests.add(request); return true; })));
    expect(interactions.value.primaryAction, isNull);
    expect(find.byType(PlayerOverworldActionCapsule), findsNothing);
    final pointer = await tester.startGesture(const Offset(600, 100),
        kind: ui.PointerDeviceKind.touch);
    expect(requests, isEmpty);
    await pointer.up();
    await tester.pump();
    expect(requests, [interactions.value.tapAction!.request]);
    expect(inputs, isEmpty);
    expect(find.byType(PlayerOverworldActionCapsule), findsNothing);
    expect(find.byKey(const ValueKey('runtime-player-touch-primary-button')),
        findsNothing);
  });

  for (final interruption in ['drag', 'A B A', 'authority', 'Menu']) {
    testWidgets('OW006 hidden item tap is cancelled by $interruption',
        (tester) async {
      final menuTransition = Completer<RuntimePlayerCommandResult>();
      final controller = _FakeRuntimePlayerCoordinator(_snapshot(
          revision: 1, phase: RuntimePlayerPhase.playing,
          actions: const [RuntimePlayerActionAvailability.enabled(
              RuntimePlayerAction.openMenu)]),
          commandCompleter: interruption == 'Menu' ? menuTransition : null);
      final interactions = ValueNotifier(_overworldSnapshot(tapOnly: true));
      final authority = ValueNotifier(const RuntimeInputAuthoritySnapshot(
          context: RuntimeInputContext.overworld));
      final requests = <RuntimeOverworldInteractionRequest>[];
      final viewportKey = GlobalKey();
      addTearDown(controller.dispose);
      addTearDown(interactions.dispose);
      addTearDown(authority.dispose);
      await _pumpMeasuredSessionWidget(tester, _app(_view(controller,
          gameplayViewportKey: viewportKey,
          gameSceneBuilder: (_) => SizedBox.expand(key: viewportKey),
          touchControlsAvailable: true,
          gameplayInputRoute: (_) => true,
          gameplayInputAuthority: authority,
          hapticFeedback: () async {},
          overworldInteractions: interactions,
          hitTestOverworldInteraction: (point) =>
              const Rect.fromLTWH(580, 80, 40, 40).contains(point)
                  ? interactions.value.tapAction?.request : null,
          onOverworldInteraction: (request) { requests.add(request); return true; })));
      final pointer = await tester.startGesture(const Offset(600, 100),
          kind: ui.PointerDeviceKind.touch);
      switch (interruption) {
        case 'drag':
          await pointer.moveBy(const Offset(20, 0));
          await pointer.moveTo(const Offset(600, 100));
        case 'A B A':
          interactions.value = _overworldSnapshot(target: 'other', tapOnly: true);
          interactions.value = _overworldSnapshot(tapOnly: true);
        case 'authority':
          authority.value = const RuntimeInputAuthoritySnapshot(
              context: RuntimeInputContext.dialogue);
          authority.value = const RuntimeInputAuthoritySnapshot(
              context: RuntimeInputContext.overworld);
        case 'Menu':
          await tester.tap(find.byType(PlayerOverworldMenuButton));
          await tester.pump();
          expect(controller.commands, hasLength(1));
      }
      await pointer.up();
      await tester.pump();
      expect(requests, isEmpty);
      expect(find.byType(PlayerOverworldActionCapsule), findsNothing);
      if (interruption == 'Menu') {
        menuTransition.complete(const RuntimePlayerCommandResult(
            status: RuntimePlayerCommandStatus.accepted));
        await tester.idle();
        await tester.pump();
        expect(tester.widget<RuntimePlayerTouchControls>(
            find.byType(RuntimePlayerTouchControls)).showControls, isTrue);
      }
      final fresh = await tester.startGesture(const Offset(600, 100),
          kind: ui.PointerDeviceKind.touch);
      await fresh.up();
      await tester.pump();
      expect(requests, [interactions.value.tapAction!.request]);
      expect(find.byType(PlayerOverworldActionCapsule), findsNothing);
    });
  }

  testWidgets('OW006 capsule and transformed world tap dispatch the same target', (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(revision: 1,
      phase: RuntimePlayerPhase.playing, preferences: const PlayerPreferencesSnapshot(locale: 'fr', accessibility: GameSessionAccessibilityOptions()),
      actions: const [RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.openMenu)]));
    final interactions = ValueNotifier(_overworldSnapshot());
    final requests = <RuntimeOverworldInteractionRequest>[];
    final canvasPoints = <Offset>[];
    final viewportKey = GlobalKey();
    addTearDown(controller.dispose);
    addTearDown(interactions.dispose);
    await _pumpMeasuredSessionWidget(tester, _app(_view(controller,
      gameplayViewportKey: viewportKey,
      gameSceneBuilder: (_) => Stack(children: [Positioned(left: 100, top: 40,
        child: Transform.scale(scale: .5, alignment: Alignment.topLeft,
          child: SizedBox(key: viewportKey, width: 400, height: 600)))]),
      touchControlsAvailable: true, gameplayInputRoute: (_) => true,
      overworldInteractions: interactions,
      hitTestOverworldInteraction: (point) { canvasPoints.add(point); return interactions.value.primaryAction?.request; },
      onOverworldInteraction: (request) { requests.add(request); return true; },
    )));
    expect(find.text('Parler'), findsOneWidget);
    expect(tester.widget<PlayerOverworldActionCapsule>(find.byType(PlayerOverworldActionCapsule)).glyph, isNull);
    final tap = await tester.startGesture(const Offset(150, 90), kind: ui.PointerDeviceKind.touch);
    await tap.up();
    await tester.pump();
    expect(canvasPoints, everyElement(const Offset(100, 100)));
    expect(requests, [interactions.value.primaryAction!.request]);
    final capsule = await tester.startGesture(tester.getCenter(find.byType(PlayerOverworldActionCapsule)), kind: ui.PointerDeviceKind.touch);
    await capsule.up();
    await tester.pump();
    expect(requests, [interactions.value.primaryAction!.request, interactions.value.primaryAction!.request]);
    expect(find.byKey(const ValueKey('runtime-player-touch-primary-button')), findsNothing);
    expect(find.byKey(const ValueKey('runtime-player-touch-secondary-button')), findsNothing);
  });

  testWidgets('OW006 capsule never retargets a press across A B A availability', (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(revision: 1,
      phase: RuntimePlayerPhase.playing,
      actions: const [RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.openMenu)]));
    final interactions = ValueNotifier(_overworldSnapshot());
    final requests = <RuntimeOverworldInteractionRequest>[];
    addTearDown(controller.dispose);
    addTearDown(interactions.dispose);
    await _pumpMeasuredSessionWidget(tester, _app(_view(controller, touchControlsAvailable: true,
      gameplayInputRoute: (_) => true, overworldInteractions: interactions,
      onOverworldInteraction: (request) { requests.add(request); return true; })));
    final tap = await tester.startGesture(tester.getCenter(find.byType(PlayerOverworldActionCapsule)), kind: ui.PointerDeviceKind.touch);
    interactions.value = _overworldSnapshot(target: 'other');
    interactions.value = _overworldSnapshot();
    await tap.up();
    await tester.pump();
    expect(requests, isEmpty);
    interactions.value = _overworldSnapshot(hasAction: false);
    await tester.pump();
    expect(find.byType(PlayerOverworldActionCapsule), findsNothing);
  });

  for (final enabled in [false, true]) {
    testWidgets('OW005 accepted sprint haptic respects preference $enabled', (tester) async {
      var haptics = 0;
      final controller = _FakeRuntimePlayerCoordinator(_snapshot(revision: 1,
        phase: RuntimePlayerPhase.playing,
        preferences: PlayerPreferencesSnapshot(locale: 'fr',
          accessibility: GameSessionAccessibilityOptions(hapticsEnabled: enabled))));
      final authority = ValueNotifier(const RuntimeInputAuthoritySnapshot(
        context: RuntimeInputContext.overworld, sprintAllowed: true));
      addTearDown(controller.dispose);
      addTearDown(authority.dispose);
      await _pumpMeasuredSessionWidget(tester, _app(_view(controller,
        touchControlsAvailable: true, gameplayInputAuthority: authority,
        gameplayInputRoute: (_) => true,
        hapticFeedback: () async { haptics++; throw MissingPluginException(); },
      )));
      final pointer = await tester.startGesture(const Offset(100, 400), kind: ui.PointerDeviceKind.touch);
      await pointer.moveBy(const Offset(20, 0));
      await tester.pump();
      final beforeSprint = haptics;
      await pointer.moveBy(const Offset(30, 0));
      await tester.pump();
      expect(haptics, beforeSprint);
      authority.value = const RuntimeInputAuthoritySnapshot(
        context: RuntimeInputContext.overworld, sprintAllowed: true, sprintAccepted: true);
      await tester.pump();
      expect(haptics, beforeSprint + (enabled ? 1 : 0));
      await pointer.moveBy(const Offset(5, 0));
      await tester.pump();
      expect(haptics, beforeSprint + (enabled ? 1 : 0));
      expect(tester.takeException(), isNull);
      await pointer.up();
    });
  }

  testWidgets('OW005 authority revocation releases sprint synchronously without revival', (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
    final authority = ValueNotifier(const RuntimeInputAuthoritySnapshot(
      context: RuntimeInputContext.overworld, sprintAllowed: true));
    final events = <RuntimeInputEvent>[];
    addTearDown(controller.dispose);
    addTearDown(authority.dispose);
    await _pumpMeasuredSessionWidget(tester, _app(_view(controller,
      touchControlsAvailable: true, gameplayInputAuthority: authority,
      gameplayInputRoute: (event) { events.add(event); return true; })));
    final pointer = await tester.startGesture(const Offset(100, 400), kind: ui.PointerDeviceKind.touch);
    await pointer.moveBy(const Offset(60, 0));
    expect(events.where((e) => e.control == RuntimeInputControl.sprint),
      const [RuntimeInputEvent.press(RuntimeInputControl.sprint)]);
    authority.value = const RuntimeInputAuthoritySnapshot(context: RuntimeInputContext.dialogue);
    expect(events.where((e) => e.control == RuntimeInputControl.sprint), const [
      RuntimeInputEvent.press(RuntimeInputControl.sprint), RuntimeInputEvent.release(RuntimeInputControl.sprint)]);
    authority.value = const RuntimeInputAuthoritySnapshot(context: RuntimeInputContext.overworld, sprintAllowed: true);
    await tester.pump();
    await pointer.moveBy(const Offset(50, 0));
    await pointer.up();
    expect(events.where((e) => e.control == RuntimeInputControl.sprint), hasLength(2));
  });

  testWidgets('OW005 hardware sprint preserves its existing route and haptic', (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
    final input = StreamController<RuntimeInputEvent>.broadcast();
    final events = <RuntimeInputEvent>[];
    var haptics = 0;
    addTearDown(controller.dispose);
    addTearDown(input.close);
    await _pumpMeasuredSessionWidget(tester, _app(_view(controller,
      controllerInputEvents: input.stream,
      gameplayInputRoute: (event) { events.add(event); return true; },
      hapticFeedback: () async => haptics++)));
    input.add(const RuntimeInputEvent.press(RuntimeInputControl.sprint));
    await tester.pump();
    input.add(const RuntimeInputEvent.release(RuntimeInputControl.sprint));
    await tester.pump();
    expect(events, const [RuntimeInputEvent.press(RuntimeInputControl.sprint),
      RuntimeInputEvent.release(RuntimeInputControl.sprint)]);
    expect(haptics, 1);
  });

  testWidgets('contextual capsule follows locale and disabled hardware hints', (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(revision: 1,
      phase: RuntimePlayerPhase.playing,
      preferences: const PlayerPreferencesSnapshot(locale: 'en',
        accessibility: GameSessionAccessibilityOptions(), showInputHints: false)));
    final interactions = ValueNotifier(_overworldSnapshot());
    addTearDown(controller.dispose);
    addTearDown(interactions.dispose);
    await _pumpMeasuredSessionWidget(tester, _app(_view(controller,
      overworldInteractions: interactions, onOverworldInteraction: (_) => true)));
    var capsule = tester.widget<PlayerOverworldActionCapsule>(find.byType(PlayerOverworldActionCapsule));
    expect(capsule.label, 'Talk');
    expect(capsule.glyph, isNull);
    controller.publish(_snapshot(revision: 2, phase: RuntimePlayerPhase.playing,
      preferences: const PlayerPreferencesSnapshot(locale: 'fr',
        accessibility: GameSessionAccessibilityOptions(), showInputHints: true)));
    await tester.pump();
    capsule = tester.widget<PlayerOverworldActionCapsule>(find.byType(PlayerOverworldActionCapsule));
    expect(capsule.label, 'Parler');
    expect(capsule.glyph, 'E');
    controller.publish(_snapshot(revision: 3, phase: RuntimePlayerPhase.playing,
      preferences: const PlayerPreferencesSnapshot(locale: 'en',
        accessibility: GameSessionAccessibilityOptions(), showInputHints: false)));
    await tester.pump();
    capsule = tester.widget<PlayerOverworldActionCapsule>(find.byType(PlayerOverworldActionCapsule));
    expect(capsule.label, 'Talk');
    expect(capsule.glyph, isNull);
  });

  testWidgets('OW004 measures scaled gameplay viewport in session coordinates', (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
    final viewportKey = GlobalKey();
    final events = <RuntimeInputEvent>[];
    addTearDown(controller.dispose);
    await _pumpMeasuredSessionWidget(tester, _app(_view(controller,
      gameplayViewportKey: viewportKey,
      gameSceneBuilder: (_) => Stack(children: [Positioned(left: 100, top: 40,
        child: Transform.scale(scale: .5, alignment: Alignment.topLeft,
          child: SizedBox(key: viewportKey, width: 400, height: 600)))]),
      touchControlsAvailable: true,
      gameplayInputRoute: (event) { events.add(event); return true; },
    )));
    for (final origin in [const Offset(350, 240), const Offset(120, 400)]) {
      final pointer = await tester.startGesture(origin, kind: ui.PointerDeviceKind.touch);
      await pointer.moveBy(const Offset(50, 0));
      await pointer.up();
    }
    expect(events, isEmpty);
    final pointer = await tester.startGesture(const Offset(120, 240), kind: ui.PointerDeviceKind.touch);
    await pointer.moveBy(const Offset(50, 0));
    expect(events.single, const RuntimeInputEvent.press(RuntimeInputControl.right));
    await pointer.up();
    expect(events.last, const RuntimeInputEvent.release(RuntimeInputControl.right));
  });

  testWidgets('OW004 viewport translation cancels stationary pointer without session rebuild', (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
    final viewportKey = GlobalKey();
    final events = <RuntimeInputEvent>[];
    var offset = 0.0;
    late StateSetter moveViewport;
    addTearDown(controller.dispose);
    await _pumpMeasuredSessionWidget(tester, _app(_view(controller,
      gameplayViewportKey: viewportKey,
      gameSceneBuilder: (_) => StatefulBuilder(builder: (context, setState) {
        moveViewport = setState;
        return Stack(children: [Positioned(left: offset, top: 0,
          child: SizedBox(key: viewportKey, width: 500, height: 600))]);
      }),
      touchControlsAvailable: true,
      gameplayInputRoute: (event) { events.add(event); return true; },
    )));
    final pointer = await tester.startGesture(const Offset(100, 400), kind: ui.PointerDeviceKind.touch);
    await pointer.moveBy(const Offset(50, 0));
    await tester.pump();
    expect(events.single, const RuntimeInputEvent.press(RuntimeInputControl.right));
    moveViewport(() => offset = 30);
    await tester.pump();
    expect(events.last, const RuntimeInputEvent.release(RuntimeInputControl.right));
    await pointer.moveBy(const Offset(50, 0));
    await pointer.up();
    expect(events, hasLength(2));
  });

  testWidgets('OW004 authority change immediately releases and cancels the gesture', (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
    final authority = ValueNotifier(const RuntimeInputAuthoritySnapshot(context: RuntimeInputContext.overworld));
    final events = <RuntimeInputEvent>[];
    addTearDown(controller.dispose);
    addTearDown(authority.dispose);
    await _pumpMeasuredSessionWidget(tester, _app(_view(controller,
      touchControlsAvailable: true, gameplayInputAuthority: authority,
      gameplayInputRoute: (event) { events.add(event); return true; },
    )));
    final pointer = await tester.startGesture(const Offset(100, 400), kind: ui.PointerDeviceKind.touch);
    await pointer.moveBy(const Offset(50, 0));
    expect(events.single, const RuntimeInputEvent.press(RuntimeInputControl.right));
    authority.value = const RuntimeInputAuthoritySnapshot(context: RuntimeInputContext.dialogue);
    expect(events.last, const RuntimeInputEvent.release(RuntimeInputControl.right));
    authority.value = const RuntimeInputAuthoritySnapshot(context: RuntimeInputContext.overworld);
    await tester.pump();
    await pointer.moveBy(const Offset(50, 0));
    await pointer.up();
    expect(events, hasLength(2));
  });

  testWidgets('OW004 lifecycle snapshot preserves accepted touch release while blocked', (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
    final events = <RuntimeInputEvent>[];
    addTearDown(controller.dispose);
    await _pumpMeasuredSessionWidget(tester, _app(_view(controller,
      touchControlsAvailable: true,
      gameplayInputRoute: (event) { events.add(event); return true; },
    )));
    final pointer = await tester.startGesture(const Offset(100, 400), kind: ui.PointerDeviceKind.touch);
    await pointer.moveBy(const Offset(50, 0));
    controller.publish(_snapshot(revision: 2, phase: RuntimePlayerPhase.lifecyclePaused));
    await tester.pump();
    expect(events, const [RuntimeInputEvent.press(RuntimeInputControl.right),
      RuntimeInputEvent.release(RuntimeInputControl.right)]);
    controller.publish(_snapshot(revision: 3, phase: RuntimePlayerPhase.playing));
    await tester.pump();
    await pointer.moveBy(const Offset(50, 0));
    await pointer.up();
    expect(events, hasLength(2));
  });

  testWidgets('OW004 measured Menu excludes gesture capture and cancels first finger', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(revision: 1,
      phase: RuntimePlayerPhase.playing,
      preferences: const PlayerPreferencesSnapshot(locale: 'fr',
        accessibility: GameSessionAccessibilityOptions(), leftHandedTouchControls: true),
      actions: const [RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.openMenu)]));
    final viewportKey = GlobalKey();
    final events = <RuntimeInputEvent>[];
    addTearDown(controller.dispose);
    await _pumpMeasuredSessionWidget(tester, _app(_view(controller,
      gameplayViewportKey: viewportKey,
      gameSceneBuilder: (_) => SizedBox.expand(key: viewportKey),
      touchControlsAvailable: true,
      gameplayInputRoute: (event) { events.add(event); return true; },
    )));
    final first = await tester.startGesture(const Offset(320, 600), pointer: 1, kind: ui.PointerDeviceKind.touch);
    await first.moveBy(const Offset(-30, 0));
    expect(events.single, const RuntimeInputEvent.press(RuntimeInputControl.left));
    final menuPosition = tester.getCenter(find.byType(PlayerOverworldMenuButton));
    expect(menuPosition.dy, greaterThan(700));
    final menu = await tester.startGesture(menuPosition, pointer: 2, kind: ui.PointerDeviceKind.touch);
    await menu.up();
    await tester.pump();
    expect(controller.commands.single.action, RuntimePlayerAction.openMenu);
    expect(events.last, const RuntimeInputEvent.release(RuntimeInputControl.left));
    await first.moveBy(const Offset(80, 0));
    await first.up();
    expect(events, hasLength(2));
    expect(tester.takeException(), isNull);
  });

  for (final replaceController in [true, false]) {
    testWidgets('OW004 replacement releases old owner when controller changes $replaceController', (tester) async {
      final oldController = _FakeRuntimePlayerCoordinator(_snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
      final newController = _FakeRuntimePlayerCoordinator(_snapshot(revision: 2, phase: RuntimePlayerPhase.playing));
      final oldAuthority = ValueNotifier(const RuntimeInputAuthoritySnapshot(context: RuntimeInputContext.overworld));
      final newAuthority = ValueNotifier(const RuntimeInputAuthoritySnapshot(context: RuntimeInputContext.overworld));
      final viewportKey = GlobalKey();
      final oldEvents = <RuntimeInputEvent>[];
      final newEvents = <RuntimeInputEvent>[];
      addTearDown(oldController.dispose);
      addTearDown(newController.dispose);
      addTearDown(oldAuthority.dispose);
      addTearDown(newAuthority.dispose);
      await _pumpMeasuredSessionWidget(tester, _app(_view(oldController,
        gameplayViewportKey: viewportKey, gameplayInputAuthority: oldAuthority,
        touchControlsAvailable: true,
        gameplayInputRoute: (event) { oldEvents.add(event); return true; },
      )));
      final held = await tester.startGesture(const Offset(100, 400), kind: ui.PointerDeviceKind.touch);
      await held.moveBy(const Offset(50, 0));
      expect(oldEvents.single, const RuntimeInputEvent.press(RuntimeInputControl.right));
      await _pumpMeasuredSessionWidget(tester, _app(_view(replaceController ? newController : oldController,
        gameplayViewportKey: viewportKey,
        gameplayInputAuthority: replaceController ? oldAuthority : newAuthority,
        touchControlsAvailable: true,
        gameplayInputRoute: (event) { newEvents.add(event); return true; },
      )));
      expect(oldEvents, const [RuntimeInputEvent.press(RuntimeInputControl.right),
        RuntimeInputEvent.release(RuntimeInputControl.right)]);
      expect(newEvents, isEmpty);
      await held.moveBy(const Offset(-100, 0));
      await held.up();
      expect(newEvents, isEmpty);
      final fresh = await tester.startGesture(const Offset(100, 400), kind: ui.PointerDeviceKind.touch);
      await fresh.moveBy(const Offset(-30, 0));
      expect(newEvents.single, const RuntimeInputEvent.press(RuntimeInputControl.left));
      await fresh.up();
      expect(newEvents.last, const RuntimeInputEvent.release(RuntimeInputControl.left));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('OW004 ordinary route closure rebuild preserves the active gesture', (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
    final viewportKey = GlobalKey();
    final events = <RuntimeInputEvent>[];
    addTearDown(controller.dispose);
    Widget view() => _app(_view(controller,
      gameplayViewportKey: viewportKey, touchControlsAvailable: true,
      gameplayInputRoute: (event) { events.add(event); return true; },
    ));
    await _pumpMeasuredSessionWidget(tester, view());
    final held = await tester.startGesture(const Offset(100, 400), kind: ui.PointerDeviceKind.touch);
    await held.moveBy(const Offset(50, 0));
    await _pumpMeasuredSessionWidget(tester, view());
    expect(events.single, const RuntimeInputEvent.press(RuntimeInputControl.right));
    await held.moveBy(const Offset(20, 0));
    expect(events, hasLength(1));
    await held.up();
    expect(events.last, const RuntimeInputEvent.release(RuntimeInputControl.right));
  });

  group('OW002 adaptive input', () {
    for (final initiallyConnected in [false, true]) {
      testWidgets(
          'starts mobile with controller availability $initiallyConnected',
          (tester) async {
        final controller = _FakeRuntimePlayerCoordinator(
            _snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
        final connected =
            ValueNotifier<Set<String>>(initiallyConnected ? {'pad'} : {});
        final events = StreamController<NormalizedGamepadEvent>.broadcast();
        addTearDown(controller.dispose);
        addTearDown(connected.dispose);
        addTearDown(events.close);
        await _pumpMeasuredSessionWidget(tester, _app(_view(controller,
            touchControlsAvailable: true,
            connectedControllerIds: connected,
            normalizedControllerInputEvents: events.stream,
            gameplayInputRoute: (_) => true)));
        _expectTouchControls(tester, !initiallyConnected);
        expect(find.byKey(const ValueKey('runtime-player-touch-movement-zone')),
            findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
        'executes first controller and touch gestures once while connected',
        (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(
          _snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
      final connected = ValueNotifier<Set<String>>({'pad'});
      final events = StreamController<NormalizedGamepadEvent>.broadcast();
      final routed = <RuntimeInputEvent>[];
      addTearDown(controller.dispose);
      addTearDown(connected.dispose);
      addTearDown(events.close);
      await _pumpMeasuredSessionWidget(tester, _app(_view(controller,
          touchControlsAvailable: true,
          connectedControllerIds: connected,
          normalizedControllerInputEvents: events.stream,
          gameplayInputRoute: (event) {
        routed.add(event);
        return true;
      })));
      events.add(_padInput(button: GamepadButton.a));
      events.add(_padInput(button: GamepadButton.a));
      await tester.pump();
      expect(
          routed, const [RuntimeInputEvent.press(RuntimeInputControl.primary)]);
      events.add(_padInput(button: GamepadButton.a, value: 0));
      await tester.pump();
      final zone =
          find.byKey(const ValueKey('runtime-player-touch-movement-zone'));
      final gesture = await tester.startGesture(tester.getCenter(zone),
          kind: ui.PointerDeviceKind.touch);
      await tester.pump();
      await gesture.moveBy(const Offset(55, 0));
      await tester.pump(const Duration(milliseconds: 80));
      _expectTouchControls(tester, true);
      expect(
          routed.where((event) =>
              event ==
              const RuntimeInputEvent.press(RuntimeInputControl.right)),
          hasLength(1));
      await gesture.up();
      await tester.pump();
      events.add(_padInput(button: GamepadButton.a));
      await tester.pump();
      await tester.pump();
      _expectTouchControls(tester, false);
      expect(
          routed.where((event) =>
              event ==
              const RuntimeInputEvent.press(RuntimeInputControl.primary)),
          hasLength(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('ignores drift releases unmapped keys and pointer hover',
        (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(
          _snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
      final connected = ValueNotifier<Set<String>>({});
      final events = StreamController<NormalizedGamepadEvent>.broadcast();
      final routed = <RuntimeInputEvent>[];
      addTearDown(controller.dispose);
      addTearDown(connected.dispose);
      addTearDown(events.close);
      await _pumpMeasuredSessionWidget(tester, _app(_view(controller,
          touchControlsAvailable: true,
          connectedControllerIds: connected,
          normalizedControllerInputEvents: events.stream,
          gameplayInputRoute: (event) {
        routed.add(event);
        return true;
      })));
      final touch = await tester.startGesture(const Offset(100, 400), kind: ui.PointerDeviceKind.touch);
      await touch.moveBy(const Offset(20, 0));
      await touch.up();
      await tester.pump();
      routed.clear();
      connected.value = {'pad'};
      events.add(_padInput(axis: GamepadAxis.leftStickX, value: .12));
      events.add(_padInput(axis: GamepadAxis.leftStickX, value: 0));
      events.add(_padInput(button: GamepadButton.a, value: 0));
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      final mouse =
          await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(300, 200));
      await mouse.moveTo(const Offset(330, 200));
      await tester.pump();
      _expectTouchControls(tester, true);
      expect(routed, isEmpty);
      await mouse.removePointer();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'disconnect neutralizes owned direction and sprint without replay',
        (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(
          _snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
      final connected = ValueNotifier<Set<String>>({'pad'});
      final events = StreamController<NormalizedGamepadEvent>.broadcast();
      final routed = <RuntimeInputEvent>[];
      addTearDown(controller.dispose);
      addTearDown(connected.dispose);
      addTearDown(events.close);
      await _pumpMeasuredSessionWidget(tester, _app(_view(controller,
          touchControlsAvailable: true,
          connectedControllerIds: connected,
          normalizedControllerInputEvents: events.stream,
          gameplayInputRoute: (event) {
        routed.add(event);
        return true;
      })));
      events.add(_padInput(axis: GamepadAxis.leftStickX, value: .8));
      events.add(_padInput(button: GamepadButton.y));
      await tester.pump();
      routed.clear();
      connected.value = {};
      await tester.pump();
      expect(
          routed,
          unorderedEquals(const [
            RuntimeInputEvent.release(RuntimeInputControl.right),
            RuntimeInputEvent.release(RuntimeInputControl.sprint)
          ]));
      _expectTouchControls(tester, true);
      routed.clear();
      connected.value = {'pad'};
      events.add(_padInput(axis: GamepadAxis.leftStickX, value: .8));
      events.add(_padInput(button: GamepadButton.y));
      await tester.pump();
      expect(routed, isEmpty);
      _expectTouchControls(tester, true);
    });

    testWidgets('late controller release leaves new touch movement owned',
        (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(
          _snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
      final connected = ValueNotifier<Set<String>>({'pad'});
      final events = StreamController<NormalizedGamepadEvent>.broadcast();
      final routed = <RuntimeInputEvent>[];
      addTearDown(controller.dispose);
      addTearDown(connected.dispose);
      addTearDown(events.close);
      await _pumpMeasuredSessionWidget(tester, _app(_view(controller,
          touchControlsAvailable: true,
          connectedControllerIds: connected,
          normalizedControllerInputEvents: events.stream,
          gameplayInputRoute: (event) {
        routed.add(event);
        return true;
      })));
      events.add(_padInput(axis: GamepadAxis.leftStickX, value: .8));
      await tester.pump();
      final gesture = await tester.startGesture(
          tester.getCenter(
              find.byKey(const ValueKey('runtime-player-touch-movement-zone'))),
          kind: ui.PointerDeviceKind.touch);
      await tester.pump();
      await gesture.moveBy(const Offset(55, 0));
      await tester.pump(const Duration(milliseconds: 80));
      expect(routed, const [
        RuntimeInputEvent.press(RuntimeInputControl.right),
        RuntimeInputEvent.release(RuntimeInputControl.right),
        RuntimeInputEvent.press(RuntimeInputControl.right)
      ]);
      routed.clear();
      events.add(_padInput(axis: GamepadAxis.leftStickX, value: 0));
      await tester.pump();
      expect(routed, isEmpty);
      _expectTouchControls(tester, true);
      await gesture.up();
      await tester.pump();
      expect(
          routed, const [RuntimeInputEvent.release(RuntimeInputControl.right)]);
    });

    testWidgets(
        'prompts follow remapping and normalized controller input owns duplicates',
        (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(_snapshot(
          revision: 1,
          phase: RuntimePlayerPhase.playing,
          preferences: const PlayerPreferencesSnapshot(
              locale: 'fr',
              accessibility: GameSessionAccessibilityOptions(),
              showInputHints: true)));
      final connected = ValueNotifier<Set<String>>({});
      final events = StreamController<NormalizedGamepadEvent>.broadcast();
      final routed = <RuntimeInputEvent>[];
      final profile = PlayerControlProfile.standard
          .rebind(
              device: PlayerControlDevice.keyboard,
              control: RuntimeInputControl.primary,
              inputId: 'keyZ')
          .profile
          .rebind(
              device: PlayerControlDevice.gamepad,
              control: RuntimeInputControl.primary,
              inputId: 'x')
          .profile;
      final interactions = ValueNotifier(_overworldSnapshot());
      addTearDown(interactions.dispose);
      addTearDown(controller.dispose);
      addTearDown(connected.dispose);
      addTearDown(events.close);
      await _pumpMeasuredSessionWidget(tester, _app(_view(controller,
          overworldInteractions: interactions, onOverworldInteraction: (_) => true,
          connectedControllerIds: connected,
          normalizedControllerInputEvents: events.stream,
          controlProfile: profile, gameplayInputRoute: (event) {
        routed.add(event);
        return true;
      })));
      expect(tester.widget<PlayerOverworldActionCapsule>(find.byType(PlayerOverworldActionCapsule)).glyph, 'Z');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      expect(routed, const [
        RuntimeInputEvent.press(RuntimeInputControl.primary),
        RuntimeInputEvent.release(RuntimeInputControl.primary)
      ]);
      routed.clear();
      connected.value = {'pad'};
      final authority = tester.widget<Focus>(find
          .byKey(const ValueKey('runtime-player-keyboard-input-authority')));
      final node = FocusNode();
      addTearDown(node.dispose);
      expect(
          authority.onKeyEvent!(
              node,
              const KeyDownEvent(
                  physicalKey: PhysicalKeyboardKey.gameButtonX,
                  logicalKey: LogicalKeyboardKey.gameButtonX,
                  timeStamp: Duration.zero,
                  deviceType: ui.KeyEventDeviceType.gamepad)),
          KeyEventResult.handled);
      events.add(_padInput(button: GamepadButton.x));
      await tester.pump();
      await tester.pump();
      expect(
          authority.onKeyEvent!(
              node,
              const KeyUpEvent(
                  physicalKey: PhysicalKeyboardKey.gameButtonX,
                  logicalKey: LogicalKeyboardKey.gameButtonX,
                  timeStamp: Duration.zero,
                  deviceType: ui.KeyEventDeviceType.gamepad)),
          KeyEventResult.handled);
      expect(
          routed, const [RuntimeInputEvent.press(RuntimeInputControl.primary)]);
      expect(tester.widget<PlayerOverworldActionCapsule>(find.byType(PlayerOverworldActionCapsule)).glyph, 'Bouton ouest');
      events.add(_padInput(button: GamepadButton.x, value: 0));
      await tester.pump();
      expect(routed, const [
        RuntimeInputEvent.press(RuntimeInputControl.primary),
        RuntimeInputEvent.release(RuntimeInputControl.primary)
      ]);
    });
    testWidgets(
        'keyboard repeat and release do not retake an active touch gesture',
        (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(
          _snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
      final routed = <RuntimeInputEvent>[];
      addTearDown(controller.dispose);
      await _pumpMeasuredSessionWidget(tester, _app(_view(controller,
          touchControlsAvailable: true, gameplayInputRoute: (event) {
        routed.add(event);
        return true;
      })));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyE);
      await tester.pump();
      _expectTouchControls(tester, false);
      final gesture = await tester.startGesture(
          tester.getCenter(
              find.byKey(const ValueKey('runtime-player-touch-movement-zone'))),
          kind: ui.PointerDeviceKind.touch);
      await tester.pump();
      await gesture.moveBy(const Offset(55, 0));
      await tester.pump(const Duration(milliseconds: 80));
      _expectTouchControls(tester, true);
      routed.clear();
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.keyE);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyE);
      await tester.pump();
      _expectTouchControls(tester, true);
      expect(routed.where((event) => event.isPress), isEmpty);
      await gesture.up();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'focused text and composing IME keep gameplay and presentation idle',
        (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(
          _snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
      final focus = FocusNode();
      final text = TextEditingController();
      final connected = ValueNotifier<Set<String>>({'pad'});
      final events = StreamController<NormalizedGamepadEvent>.broadcast();
      final routed = <RuntimeInputEvent>[];
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      addTearDown(text.dispose);
      addTearDown(connected.dispose);
      addTearDown(events.close);
      await _pumpMeasuredSessionWidget(tester, _app(PokeMapPlayerSessionView(
          controller: controller,
          titlePresentation: const RuntimePlayerTitlePresentation(
              author: 'Studio Test', description: 'Une aventure de test.'),
          gameSceneBuilder: (_) => Align(
              alignment: Alignment.topCenter,
              child: Material(
                  child: TextField(focusNode: focus, controller: text))),
          touchControlsAvailable: true,
          controllerInputEnabled: true,
          connectedControllerIds: connected,
          normalizedControllerInputEvents: events.stream,
          gameplayInputRoute: (event) {
            routed.add(event);
            return true;
          })));
      focus.requestFocus();
      await tester.pump();
      tester.testTextInput.updateEditingValue(const TextEditingValue(
          text: 'é', composing: TextRange(start: 0, end: 1)));
      await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(text.text, 'é');
      expect(routed, isEmpty);
      _expectTouchControls(tester, false);
      expect(tester.takeException(), isNull);
    });

    testWidgets('held touch timer cannot reclaim input after hardware resumes',
        (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(
          _snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
      final connected = ValueNotifier<Set<String>>({});
      final events = StreamController<NormalizedGamepadEvent>.broadcast();
      final routed = <RuntimeInputEvent>[];
      addTearDown(controller.dispose);
      addTearDown(connected.dispose);
      addTearDown(events.close);
      await _pumpMeasuredSessionWidget(tester, _app(_view(controller,
          touchControlsAvailable: true,
          connectedControllerIds: connected,
          normalizedControllerInputEvents: events.stream,
          gameplayInputRoute: (event) {
        routed.add(event);
        return true;
      })));
      final gesture = await tester.startGesture(
          tester.getCenter(
              find.byKey(const ValueKey('runtime-player-touch-movement-zone'))),
          kind: ui.PointerDeviceKind.touch);
      await gesture.moveBy(const Offset(55, 0));
      await tester.pump(const Duration(milliseconds: 80));
      expect(
          routed, const [RuntimeInputEvent.press(RuntimeInputControl.right)]);
      connected.value = {'pad'};
      events.add(_padInput(axis: GamepadAxis.leftStickX, value: .8));
      await tester.pump();
      await tester.pump();
      _expectTouchControls(tester, false);
      expect(routed, const [
        RuntimeInputEvent.press(RuntimeInputControl.right),
        RuntimeInputEvent.release(RuntimeInputControl.right),
        RuntimeInputEvent.press(RuntimeInputControl.right),
      ]);
      routed.clear();
      await tester.pump(const Duration(milliseconds: 180));
      await gesture.moveBy(const Offset(-90, 0));
      await tester.pump(const Duration(milliseconds: 80));
      _expectTouchControls(tester, false);
      expect(routed, isEmpty);
      await gesture.up();
      await tester.pump();
      expect(routed, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('synthesized mapped key down neither selects keyboard nor acts',
        (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(
          _snapshot(revision: 1, phase: RuntimePlayerPhase.playing));
      final routed = <RuntimeInputEvent>[];
      addTearDown(controller.dispose);
      await _pumpMeasuredSessionWidget(tester, _app(_view(controller,
          touchControlsAvailable: true, gameplayInputRoute: (event) {
        routed.add(event);
        return true;
      })));
      HardwareKeyboard.instance.handleKeyEvent(const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyE,
        logicalKey: LogicalKeyboardKey.keyE,
        timeStamp: Duration.zero,
        synthesized: true,
      ));
      await tester.pump();
      _expectTouchControls(tester, true);
      expect(routed, isEmpty);
      HardwareKeyboard.instance.handleKeyEvent(const KeyUpEvent(
        physicalKey: PhysicalKeyboardKey.keyE,
        logicalKey: LogicalKeyboardKey.keyE,
        timeStamp: Duration.zero,
        synthesized: true,
      ));
      await tester.pump();
      _expectTouchControls(tester, true);
      expect(routed, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'controller identity refreshes reliable family prompts between pads',
        (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(_snapshot(
        revision: 1,
        phase: RuntimePlayerPhase.playing,
        preferences: const PlayerPreferencesSnapshot(
            locale: 'fr',
            accessibility: GameSessionAccessibilityOptions(),
            showInputHints: true),
      ));
      final connected = ValueNotifier<Set<String>>({'xbox', 'sony'});
      final events = StreamController<NormalizedGamepadEvent>.broadcast();
      final routed = <RuntimeInputEvent>[];
      final interactions = ValueNotifier(_overworldSnapshot());
      addTearDown(interactions.dispose);
      addTearDown(controller.dispose);
      addTearDown(connected.dispose);
      addTearDown(events.close);
      await _pumpMeasuredSessionWidget(tester, _app(_view(controller,
          overworldInteractions: interactions, onOverworldInteraction: (_) => true,
        touchControlsAvailable: true,
        connectedControllerIds: connected,
        normalizedControllerInputEvents: events.stream,
        gameplayInputRoute: (event) {
          routed.add(event);
          return true;
        },
      )));
      events.add(_padInput(
          gamepadId: 'xbox',
          button: GamepadButton.a,
          vendorId: 0x045e,
          productId: 0x0b0c));
      await tester.pump();
      await tester.pump();
      expect(tester.widget<PlayerOverworldActionCapsule>(find.byType(PlayerOverworldActionCapsule)).glyph, 'A');
      events.add(_padInput(
          gamepadId: 'xbox',
          button: GamepadButton.a,
          value: 0,
          vendorId: 0x045e,
          productId: 0x0b0c));
      events.add(_padInput(
          gamepadId: 'sony',
          button: GamepadButton.a,
          vendorId: 0x054c,
          productId: 0x0ba0));
      await tester.pump();
      await tester.pump();
      expect(tester.widget<PlayerOverworldActionCapsule>(find.byType(PlayerOverworldActionCapsule)).glyph, '×');
      events.add(_padInput(
          gamepadId: 'sony',
          button: GamepadButton.a,
          value: 0,
          vendorId: 0x054c,
          productId: 0x0ba0));
      await tester.pump();
      expect(
          routed.where((event) =>
              event ==
              const RuntimeInputEvent.press(RuntimeInputControl.primary)),
          hasLength(2));
      final gesture = await tester.startGesture(
          tester.getCenter(
              find.byKey(const ValueKey('runtime-player-touch-movement-zone'))),
          kind: ui.PointerDeviceKind.touch);
      await tester.pump();
      await gesture.moveBy(const Offset(55, 0));
      await tester.pump(const Duration(milliseconds: 80));
      _expectTouchControls(tester, true);
      await gesture.up();
      await tester.pump();
      events.add(_padInput(
          gamepadId: 'xbox',
          button: GamepadButton.a,
          vendorId: 0x045e,
          productId: 0x0b0c));
      await tester.pump();
      await tester.pump();
      _expectTouchControls(tester, false);
      expect(tester.widget<PlayerOverworldActionCapsule>(find.byType(PlayerOverworldActionCapsule)).glyph, 'A');
      expect(tester.takeException(), isNull);
    });

    testWidgets('a direct choice touch action takes over from keyboard navigation',
        (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(_titleOptionsSnapshot());
      addTearDown(controller.dispose);
      await _pumpMeasuredSessionWidget(tester, _app(_view(controller)));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<RuntimePlayerOptions>(
                  find.byType(RuntimePlayerOptions, skipOffstage: false))
              .activeInputSource,
          PlayerInputSource.keyboard);
      await tester.tap(find.byKey(const ValueKey('options-text-speed-choice')),
          kind: ui.PointerDeviceKind.touch);
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<RuntimePlayerOptions>(find.byType(RuntimePlayerOptions))
              .activeInputSource,
          PlayerInputSource.touch);
      expect(controller.commands, hasLength(1));
      expect(controller.commands.single.action,
          RuntimePlayerAction.updatePreferences);
      expect(
          (controller.commands.single.payload! as PlayerPreferencesSnapshot)
              .dialogueTextSpeed,
          RuntimeDialogueTextSpeed.fast);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('routes one canonical surface for every player phase',
      (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(
      revision: 1,
      phase: RuntimePlayerPhase.title,
      actions: <RuntimePlayerActionAvailability>[
        const RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.continueGame,
        ),
      ],
    ));
    addTearDown(controller.dispose);

    await _pumpMeasuredSessionWidget(tester, _app(_view(controller)));
    expect(_surfaceFinder(RuntimePlayerPhase.title), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('test-game-scene')), findsNothing);

    for (final phase in <RuntimePlayerPhase>[
      RuntimePlayerPhase.preSession,
      RuntimePlayerPhase.preparingSession,
      RuntimePlayerPhase.loadingSession,
      RuntimePlayerPhase.playing,
      RuntimePlayerPhase.paused,
      RuntimePlayerPhase.saving,
      RuntimePlayerPhase.lifecyclePaused,
      RuntimePlayerPhase.completing,
      RuntimePlayerPhase.result,
      RuntimePlayerPhase.credits,
      RuntimePlayerPhase.disposingSession,
      RuntimePlayerPhase.externalExit,
      RuntimePlayerPhase.error,
    ]) {
      controller.publish(_snapshot(revision: 2 + phase.index, phase: phase));
      await tester.pump();
      await tester.pump();

      expect(
        _surfaceFinder(phase),
        findsOneWidget,
        reason: 'The ${phase.name} phase must have one canonical surface.',
      );
      expect(_allCanonicalSurfaces(), findsOneWidget);
    }
  });

  testWidgets(
    'renders the active Presentation frame through the shared Player renderer',
    (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(
        _snapshot(revision: 15, phase: RuntimePlayerPhase.playing),
      );
      final frame = _presentationFrame();
      final presentation = ValueNotifier<RuntimePresentationFrameSnapshot?>(
        RuntimePresentationFrameSnapshot(
          assetRevision: 'opening-revision-7',
          frame: frame,
          orientation: PresentationFrameOrientation.portrait,
          mediaBindings: const <PresentationFrameMediaBinding>[
            PresentationFrameMediaBinding(
              clipId: 'opening-visual',
              kind: PresentationFrameMediaKind.image,
              landscapeResourceId: 'opening-landscape',
              portraitResourceId: 'opening-portrait',
            ),
          ],
        ),
      );
      final contentPort = _PresentationContentPort();
      var skipCalls = 0;
      addTearDown(controller.dispose);
      addTearDown(presentation.dispose);

      await _pumpMeasuredSessionWidget(tester,
        _app(
          _view(
            controller,
            presentationFrame: presentation,
            presentationContentPort: contentPort,
            onPresentationSkip: () async => skipCalls += 1,
            touchControlsAvailable: true,
            gameplayInputRoute: (_) => true,
          ),
        ),
      );

      expect(
        find.byKey(
          const ValueKey<String>('runtime-presentation-frame-surface'),
        ),
        findsOneWidget,
      );
      final renderer = tester.widget<PresentationFrameRenderer>(
        find.byType(PresentationFrameRenderer),
      );
      expect(identical(renderer.frame, frame), isTrue);
      expect(
        identical(
          (renderer.contentPort as PresentationResponsiveFrameContentPort)
              .delegate,
          contentPort,
        ),
        isTrue,
      );
      expect(renderer.orientation, PresentationFrameOrientation.portrait);
      expect(contentPort.visualRequests, <String>['opening-portrait']);
      expect(find.byKey(const ValueKey<String>('test-game-scene')),
          findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('runtime-player-touch-movement-zone')),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('runtime-presentation-skip')),
      );
      await tester.pump();
      expect(skipCalls, 1);

      presentation.value = null;
      await tester.pump();

      expect(find.byType(PresentationFrameRenderer), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('runtime-player-touch-movement-zone')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('dispatches title actions with the current snapshot revision',
      (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(
      revision: 7,
      phase: RuntimePlayerPhase.title,
      actions: <RuntimePlayerActionAvailability>[
        const RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.continueGame,
        ),
        RuntimePlayerActionAvailability.disabled(
          RuntimePlayerAction.newGame,
          reason: 'Profil requis',
        ),
      ],
    ));
    addTearDown(controller.dispose);

    await _pumpMeasuredSessionWidget(tester, _app(_view(controller)));
    await _revealPagedTarget(tester, find.text('Continuer'));
    await tester.tap(find.text('Continuer'));

    expect(controller.commands, hasLength(1));
    expect(controller.commands.single.action, RuntimePlayerAction.continueGame);
    expect(controller.commands.single.snapshotRevision, 7);

    final newGameButton = tester.widget<PlayerActionButton>(
      find.byKey(const ValueKey('title.newGame')),
    );
    expect(newGameButton.onPressed, isNull);
    expect(controller.commands, hasLength(1));
  });

  testWidgets(
    'renders title options without a game scene and returns on Escape',
    (tester) async {
      tester.view.physicalSize = const Size(390, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(
        tester.platformDispatcher.clearTextScaleFactorTestValue,
      );
      final controller = _FakeRuntimePlayerCoordinator(
        RuntimePlayerSnapshot(
          revision: 8,
          phase: RuntimePlayerPhase.title,
          gameTitle: 'Aube',
          pauseSection: RuntimePlayerPauseSection.options,
          defaultPreferences: const PlayerPreferencesSnapshot(
            locale: 'en',
            accessibility: GameSessionAccessibilityOptions(),
            audioMix: RuntimeAudioMix(musicVolume: 0.8, effectsVolume: 0.8),
          ),
          preferences: const PlayerPreferencesSnapshot(
            locale: 'fr',
            accessibility: GameSessionAccessibilityOptions(),
          ),
          actions: const <RuntimePlayerActionAvailability>[
            RuntimePlayerActionAvailability.enabled(
              RuntimePlayerAction.openOptions,
            ),
            RuntimePlayerActionAvailability.enabled(
              RuntimePlayerAction.updatePreferences,
            ),
            RuntimePlayerActionAvailability.enabled(
              RuntimePlayerAction.returnToTitle,
            ),
          ],
        ),
      );
      addTearDown(controller.dispose);

      await _pumpMeasuredSessionWidget(tester, _app(_view(controller)));

      final options = tester.widget<RuntimePlayerOptions>(
        find.byType(RuntimePlayerOptions),
      );
      expect(options.defaultPreferences.locale, 'en');
      expect(options.defaultPreferences.audioMix.musicVolume, 0.8);

      expect(
        find.byKey(
          const ValueKey<String>('runtime-player-title-options'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('options-text-speed-choice'),
        ),
        findsOneWidget,
      );
      expect(
          find.byKey(const ValueKey<String>('test-game-scene')), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(controller.backRequests, <int>[8]);
      expect(controller.commands, isEmpty);
    },
  );

  testWidgets(
      'title options route controller slider changes and back through the coordinator',
      (tester) async {
    final events = StreamController<RuntimeInputEvent>.broadcast();
    addTearDown(events.close);
    final controller = _FakeRuntimePlayerCoordinator(_titleOptionsSnapshot());
    addTearDown(controller.dispose);
    await _pumpMeasuredSessionWidget(tester,
        _app(_view(controller, controllerInputEvents: events.stream)));
    await _selectOptionsCategory(tester, 'audio');
    final slider = find.byKey(const ValueKey('options-master-slider'));
    await tester.ensureVisible(slider);
    tester.widget<Slider>(slider).focusNode!.requestFocus();
    await tester.pumpAndSettle();
    events.add(const RuntimeInputEvent.press(RuntimeInputControl.left));
    await tester.pumpAndSettle();
    expect(controller.commands, hasLength(1));
    expect(controller.commands.single.action,
        RuntimePlayerAction.updatePreferences);
    expect(controller.commands.single.snapshotRevision, 86);
    expect(
        (controller.commands.single.payload! as PlayerPreferencesSnapshot)
            .audioMix
            .masterVolume,
        .95);
    expect(tester.widget<Slider>(slider).value, .95);
    events.add(const RuntimeInputEvent.press(RuntimeInputControl.right));
    await tester.pumpAndSettle();
    expect(controller.commands, hasLength(2));
    expect(
        (controller.commands.last.payload! as PlayerPreferencesSnapshot)
            .audioMix
            .masterVolume,
        1);
    events.add(const RuntimeInputEvent.press(RuntimeInputControl.secondary));
    await tester.pumpAndSettle();
    expect(controller.commands, hasLength(3));
    expect(controller.commands.last.action, RuntimePlayerAction.returnToTitle);
    expect(controller.commands.last.snapshotRevision, 86);
    controller.publish(controller.snapshot.next(clearPauseSection: true));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('runtime-player-title-options')),
        findsNothing);
    expect(find.byKey(const ValueKey('test-game-scene')), findsNothing);
  });

  testWidgets(
      'title options receive controller keyboard and touch source changes',
      (tester) async {
    final events = StreamController<RuntimeInputEvent>.broadcast();
    addTearDown(events.close);
    final controller = _FakeRuntimePlayerCoordinator(_titleOptionsSnapshot());
    addTearDown(controller.dispose);
    await _pumpMeasuredSessionWidget(tester,
        _app(_view(controller, controllerInputEvents: events.stream)));
    await _selectOptionsCategory(tester, 'controls');
    events.add(const RuntimeInputEvent.press(RuntimeInputControl.sprint));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<RuntimePlayerOptions>(find.byType(RuntimePlayerOptions))
            .activeInputSource,
        PlayerInputSource.controller);
    expect(
      tester.widget<PlayerMenuSelectableRow>(find.byKey(const ValueKey('options-binding-primary-choice'), skipOffstage: false)).semanticValue,
      PlayerControlProfile.standard.glyphFor(PlayerControlDevice.gamepad, RuntimeInputControl.primary),
    );
    expect(find.descendant(
      of: find.byKey(const ValueKey('options-binding-primary-choice'), skipOffstage: false),
      matching: find.text(PlayerControlProfile.standard.glyphFor(PlayerControlDevice.gamepad, RuntimeInputControl.primary), skipOffstage: false),
      skipOffstage: false,
    ), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<RuntimePlayerOptions>(find.byType(RuntimePlayerOptions))
            .activeInputSource,
        PlayerInputSource.keyboard);
    expect(
      tester.widget<PlayerMenuSelectableRow>(find.byKey(const ValueKey('options-binding-primary-choice'), skipOffstage: false)).semanticValue,
      PlayerControlProfile.standard.glyphFor(PlayerControlDevice.keyboard, RuntimeInputControl.primary),
    );
    expect(find.descendant(
      of: find.byKey(const ValueKey('options-binding-primary-choice'), skipOffstage: false),
      matching: find.text(PlayerControlProfile.standard.glyphFor(PlayerControlDevice.keyboard, RuntimeInputControl.primary), skipOffstage: false),
      skipOffstage: false,
    ), findsOneWidget);
    await tester.tapAt(
        tester.getTopLeft(find.byKey(const ValueKey('options-settings'))) +
            const Offset(8, 8),
        kind: ui.PointerDeviceKind.touch);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<RuntimePlayerOptions>(find.byType(RuntimePlayerOptions))
            .activeInputSource,
        PlayerInputSource.keyboard);
    await _selectOptionsCategory(tester, 'controls');
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<RuntimePlayerOptions>(find.byType(RuntimePlayerOptions))
            .activeInputSource,
        PlayerInputSource.touch);
    expect(find.byKey(const ValueKey('options-touch-run-mode-choice')), findsOneWidget);
    expect(find.byKey(const ValueKey('options-binding-primary-choice')), findsNothing);
    expect(controller.commands, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('title binding popups consume duplicate hardware gamepad events', (tester) async {
    final events = StreamController<RuntimeInputEvent>.broadcast();
    addTearDown(events.close);
    final controller = _FakeRuntimePlayerCoordinator(_titleOptionsSnapshot());
    final profiles = <PlayerControlProfile>[];
    addTearDown(controller.dispose);
    await _pumpMeasuredSessionWidget(tester, _app(_view(controller,
      controllerInputEvents: events.stream, onControlProfileChanged: profiles.add)));
    await tester.sendKeyEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    await _selectOptionsCategory(tester, 'controls', mouse: true);
    final binding = find.byKey(const ValueKey('options-binding-primary-choice'));
    await _revealPagedTarget(tester, binding,
      scope: find.byKey(const ValueKey('options-settings')), mouse: true);
    await tester.tap(binding, kind: ui.PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    final choice = find.byKey(const ValueKey('options-choice-keyW'));
    await _revealPagedTarget(tester, choice, scope: find.byType(Dialog), mouse: true);
    Focus.of(tester.element(find.descendant(of: choice, matching: find.byType(GestureDetector)).first)).requestFocus();
    await tester.pump();
    await _hardwareGamepadPress(
      tester,
      LogicalKeyboardKey.gameButtonA,
      PhysicalKeyboardKey.gameButtonA,
      whileHeld: () async {
        events.add(const RuntimeInputEvent.press(RuntimeInputControl.primary));
        await tester.pump();
      },
    );
    events.add(const RuntimeInputEvent.release(RuntimeInputControl.primary));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('options-choice-back')), findsNothing);
    expect(profiles, hasLength(1));
    expect(profiles.single.bindingFor(PlayerControlDevice.keyboard, RuntimeInputControl.primary), 'keyW');
    expect(controller.commands, isEmpty);
    await _revealPagedTarget(tester, binding,
      scope: find.byKey(const ValueKey('options-settings')), mouse: true);
    await tester.tap(binding, kind: ui.PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    expect(
      FocusManager.instance.primaryFocus!.context!
        .findAncestorWidgetOfExactType<RuntimePlayerInputBindings>(),
      isNotNull,
      reason: 'The binding dialog owns input immediately after opening.',
    );
    events.add(const RuntimeInputEvent.press(RuntimeInputControl.secondary));
    await tester.pumpAndSettle();
    events.add(const RuntimeInputEvent.release(RuntimeInputControl.secondary));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('options-choice-back')), findsNothing);
    expect(profiles, hasLength(1));
    expect(controller.commands, isEmpty);
    expect(controller.backRequests, isEmpty);
  });

  testWidgets('projects readability preferences and accessible input hints',
      (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(
      RuntimePlayerSnapshot(
        revision: 81,
        phase: RuntimePlayerPhase.title,
        gameTitle: 'Aube',
        preferences: const PlayerPreferencesSnapshot(
          locale: 'fr',
          accessibility: GameSessionAccessibilityOptions(
            reducedMotion: true,
            textScale: 1.4,
            hapticsEnabled: false,
          ),
          highContrast: true,
          showInputHints: false,
        ),
      ),
    );
    addTearDown(controller.dispose);

    await _pumpMeasuredSessionWidget(tester,
      _app(
        MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(1.25),
          ),
          child: _view(controller),
        ),
      ),
    );

    final accessibilityContext = tester.element(
      find.byKey(
        const ValueKey<String>('runtime-player-session-accessibility'),
      ),
    );
    expect(
      MediaQuery.of(accessibilityContext).textScaler.scale(10),
      closeTo(17.5, 0.001),
    );
    expect(MediaQuery.of(accessibilityContext).disableAnimations, isTrue);
    expect(
      Theme.of(accessibilityContext)
          .extension<PokeMapPlayerColors>()
          ?.highContrast,
      isTrue,
    );
    expect(
      Theme.of(accessibilityContext).extension<PokeMapPlayerMotion>()?.fast,
      Duration.zero,
    );
    expect(
      find.byKey(const ValueKey<String>('runtime-player-input-hints')),
      findsNothing,
    );

    controller.publish(
      RuntimePlayerSnapshot(
        revision: 82,
        phase: RuntimePlayerPhase.title,
        gameTitle: 'Aube',
        preferences: const PlayerPreferencesSnapshot(
          locale: 'fr',
          accessibility: GameSessionAccessibilityOptions(
            reducedMotion: true,
            textScale: 1.4,
            hapticsEnabled: false,
          ),
          highContrast: true,
          showInputHints: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final hints = find.byKey(
      const ValueKey<String>('runtime-player-input-hints'),
    );
    expect(hints, findsOneWidget);
    expect(tester.getSemantics(hints).label, 'E · M Pause');
  });

  testWidgets('pause hides the contextual world capsule', (tester) async {
    const preferences = PlayerPreferencesSnapshot(
      locale: 'fr',
      accessibility: GameSessionAccessibilityOptions(),
      showInputHints: true,
    );
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(
        revision: 1,
        phase: RuntimePlayerPhase.playing,
        preferences: preferences,
      ),
    );
    final interactions = ValueNotifier(_overworldSnapshot());
      addTearDown(interactions.dispose);
      addTearDown(controller.dispose);
    await _pumpMeasuredSessionWidget(tester, _app(_view(controller,
          overworldInteractions: interactions, onOverworldInteraction: (_) => true,)));
    await tester.pumpAndSettle();
    final capsule = find.byType(PlayerOverworldActionCapsule);
    expect(capsule, findsOneWidget);

    controller.publish(
      _snapshot(
        revision: 2,
        phase: RuntimePlayerPhase.paused,
        preferences: preferences,
      ),
    );
    await tester.pumpAndSettle();
    expect(capsule, findsNothing);
    expect(find.byKey(const ValueKey('runtime-player-input-hints')), findsNothing);
  });

  testWidgets('runtime haptics follow the projected preference',
      (tester) async {
    var hapticCalls = 0;
    var acceptsAction = true;
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(
        revision: 83,
        phase: RuntimePlayerPhase.playing,
        preferences: const PlayerPreferencesSnapshot(
          locale: 'fr',
          accessibility: GameSessionAccessibilityOptions(
            hapticsEnabled: false,
          ),
        ),
      ),
    );
    final interactions = ValueNotifier(_overworldSnapshot());
      addTearDown(interactions.dispose);
      addTearDown(controller.dispose);

    await _pumpMeasuredSessionWidget(tester,
      _app(
        _view(controller,
          overworldInteractions: interactions, onOverworldInteraction: (_) => acceptsAction,
          gameplayInputRoute: (_) => true,
          touchControlsAvailable: true,
          hapticFeedback: () async => hapticCalls++,
        ),
      ),
    );
    final primary = find.byType(PlayerOverworldActionCapsule);
    await tester.tap(primary);
    expect(hapticCalls, 0);

    controller.publish(
      _snapshot(
        revision: 84,
        phase: RuntimePlayerPhase.playing,
        preferences: const PlayerPreferencesSnapshot(
          locale: 'fr',
          accessibility: GameSessionAccessibilityOptions(
            hapticsEnabled: true,
          ),
        ),
      ),
    );
    await tester.pump();
    acceptsAction = false;
    await tester.tap(primary);
    expect(hapticCalls, 0);
    acceptsAction = true;
    await tester.tap(primary);
    expect(hapticCalls, 1);
  });

  for (final platform in [TargetPlatform.macOS, TargetPlatform.android]) {
    testWidgets(
        'title options expose supported accessibility preferences on $platform',
        (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(
        RuntimePlayerSnapshot(
          revision: 85,
          phase: RuntimePlayerPhase.title,
          gameTitle: 'Aube',
          pauseSection: RuntimePlayerPauseSection.options,
          preferences: const PlayerPreferencesSnapshot(
            locale: 'fr',
            accessibility: GameSessionAccessibilityOptions(),
          ),
          actions: const <RuntimePlayerActionAvailability>[
            RuntimePlayerActionAvailability.enabled(
              RuntimePlayerAction.updatePreferences,
            ),
          ],
        ),
      );
      addTearDown(controller.dispose);

      await _pumpMeasuredSessionWidget(tester, _app(_view(controller), platform: platform));
      await _selectOptionsCategory(tester, 'accessibility');

      final settings = find.byKey(const ValueKey('options-settings'));
      for (final key in [
        'runtime-player-reduced-motion-toggle',
        'runtime-player-high-contrast-toggle',
        if (platform == TargetPlatform.android) 'runtime-player-haptics-toggle',
        'runtime-player-text-scale-slider',
      ]) {
        final control = find.byKey(ValueKey(key));
        await _revealPagedTarget(tester, control, scope: settings);
        expect(control.hitTestable(), findsOneWidget);
      }
      if (platform == TargetPlatform.macOS) {
        expect(find.byKey(const ValueKey('runtime-player-haptics-toggle')), findsNothing);
      }
      final contrast = find.byKey(const ValueKey('runtime-player-high-contrast-toggle'));
      await _revealPagedTarget(tester, contrast, scope: settings);
      await tester.tap(contrast);
      await tester.pumpAndSettle();
      final command = controller.commands.single;
      expect(command.action, RuntimePlayerAction.updatePreferences);
      expect(
        (command.payload! as PlayerPreferencesSnapshot).highContrast,
        isTrue,
      );
      await _selectOptionsCategory(tester, 'controls');
      final deviceSwitch = find.byKey(const ValueKey('options-control-device-switch'));
      if (deviceSwitch.evaluate().isNotEmpty) {
        await tester.tap(deviceSwitch);
        await tester.pumpAndSettle();
      }
      final hints = find
          .byKey(const ValueKey<String>('runtime-player-input-hints-toggle'));
      await _revealPagedTarget(tester, hints, scope: settings);
      expect(hints.hitTestable(), findsOneWidget);
      await tester.tap(hints);
      await tester.pumpAndSettle();
      expect(controller.commands, hasLength(2));
      expect(controller.commands.last.action,
          RuntimePlayerAction.updatePreferences);
      final updated =
          controller.commands.last.payload! as PlayerPreferencesSnapshot;
      expect(updated.showInputHints, isFalse);
      expect(updated.highContrast, isTrue);
    });
  }

  testWidgets('shows localized title credits before game completion',
      (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(
      RuntimePlayerSnapshot(
        revision: 10,
        phase: RuntimePlayerPhase.credits,
        gameTitle: 'Aube',
        actions: const <RuntimePlayerActionAvailability>[
          RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.finishCredits,
          ),
          RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.returnToTitle,
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);

    await _pumpMeasuredSessionWidget(tester, _app(_view(controller)));

    expect(find.text('Studio Test'), findsOneWidget);
    expect(find.text('Une aventure de test.'), findsOneWidget);
    await tester.tap(find.text('Retour au titre'));

    expect(controller.commands, hasLength(1));
    expect(
      controller.commands.single.action,
      RuntimePlayerAction.returnToTitle,
    );
  });

  testWidgets(
    'dispatches New Game without a host identity dialog',
    (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(
        _snapshot(
          revision: 9,
          phase: RuntimePlayerPhase.title,
          actions: const <RuntimePlayerActionAvailability>[
            RuntimePlayerActionAvailability.enabled(
              RuntimePlayerAction.newGame,
            ),
          ],
        ),
      );
      addTearDown(controller.dispose);

      await _pumpMeasuredSessionWidget(tester,
        _app(
          MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2),
            ),
            child: _view(
              controller,
              payloadForAction: (_) => const RuntimePlayerLoadSlot(
                profileId: 'player',
                slotId: 'slot_1',
              ),
            ),
          ),
        ),
      );

      await _revealPagedTarget(tester, find.text('Nouveau jeu'));
    await tester.tap(find.text('Nouveau jeu'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey<String>('player-new-game-identity-dialog'),
        ),
        findsNothing,
      );

      expect(controller.commands, hasLength(1));
      final command = controller.commands.single;
      expect(command.action, RuntimePlayerAction.newGame);
      expect(command.snapshotRevision, 9);
      final slot = command.payload! as RuntimePlayerLoadSlot;
      expect(slot.profileId, 'player');
      expect(slot.slotId, 'slot_1');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shows runtime loading progress and dispatches cancellation',
      (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(
      revision: 11,
      phase: RuntimePlayerPhase.loadingSession,
      loadingProgress: const GameSessionLoadingProgress(
        stage: 'catalogues',
        current: 2,
        total: 4,
      ),
      actions: const <RuntimePlayerActionAvailability>[
        RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.cancel),
      ],
    ));
    addTearDown(controller.dispose);

    await _pumpMeasuredSessionWidget(tester, _app(_view(controller)));

    expect(find.text('catalogues'), findsOneWidget);
    expect(find.byKey(const ValueKey('runtime-player-loading-art')),
        findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.byKey(const ValueKey('runtime-player-loading-progress')), findsOneWidget);

    await tester.tap(find.text('Annuler'));
    expect(controller.commands.single.action, RuntimePlayerAction.cancel);
    expect(controller.commands.single.snapshotRevision, 11);
  });

  testWidgets('uses host artwork while loading and mounting the first map',
      (tester) async {
    const logo = AssetImage(
      'assets/splash/eclipse_disc.png',
      package: 'map_player_ui',
    );
    const wordmark = AssetImage(
      'assets/splash/eclipse_orbit_soft.png',
      package: 'map_player_ui',
    );
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(
      revision: 1,
      phase: RuntimePlayerPhase.loadingSession,
    ));
    final authority = ValueNotifier(const RuntimeInputAuthoritySnapshot(
      context: RuntimeInputContext.blocked,
    ));
    addTearDown(controller.dispose);
    addTearDown(authority.dispose);

    await _pumpMeasuredSessionWidget(tester, _app(_view(
      controller,
      gameplayInputAuthority: authority,
      loadingLogo: logo,
      loadingWordmark: wordmark,
    )));

    expect(
      (tester.widget<Image>(find.byKey(const ValueKey('runtime-player-loading-logo'))).image
              as ResizeImage)
          .imageProvider,
      logo,
    );
    expect(
      (tester.widget<Image>(find.byKey(const ValueKey('runtime-player-loading-wordmark'))).image
              as ResizeImage)
          .imageProvider,
      wordmark,
    );
    expect(find.text('A V E L U N E'), findsNothing);

    controller.publish(_snapshot(
      revision: 2,
      phase: RuntimePlayerPhase.playing,
      actions: const [
        RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.openMenu),
      ],
    ));
    await _settleMeasuredSession(tester);

    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('runtime-player-loading-logo')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('runtime-player-loading-wordmark')),
        findsOneWidget);

    authority.value = const RuntimeInputAuthoritySnapshot(
      context: RuntimeInputContext.overworld,
    );
    await _settleMeasuredSession(tester);
    expect(find.byKey(const ValueKey('runtime-player-loading-art')),
        findsNothing);
  });

  testWidgets('names the real map mounting stage in the player language',
      (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(
      revision: 12,
      phase: RuntimePlayerPhase.loadingSession,
      loadingProgress: const GameSessionLoadingProgress(
        stage: 'mount',
        current: 3,
        total: 7,
      ),
    ));
    addTearDown(controller.dispose);

    await _pumpMeasuredSessionWidget(tester, _app(_view(controller)));

    expect(find.text('Construction de la scène'), findsOneWidget);
    expect(find.text('43%'), findsOneWidget);
  });

  testWidgets('keeps loading artwork until the first map accepts the menu',
      (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(
      revision: 1,
      phase: RuntimePlayerPhase.loadingSession,
      loadingProgress: const GameSessionLoadingProgress(
        stage: 'mount',
        current: 3,
        total: 7,
      ),
    ));
    final authority = ValueNotifier(const RuntimeInputAuthoritySnapshot(
      context: RuntimeInputContext.blocked,
    ));
    addTearDown(controller.dispose);
    addTearDown(authority.dispose);

    await tester.pumpWidget(_app(_view(controller,
        gameplayInputAuthority: authority)));
    controller.publish(_snapshot(
      revision: 2,
      phase: RuntimePlayerPhase.playing,
      actions: const [
        RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.openMenu),
      ],
    ));
    await _settleMeasuredSession(tester);

    expect(find.byKey(const ValueKey('runtime-player-loading-art')),
        findsOneWidget);
    expect(find.text('Activation de la carte'), findsOneWidget);
    expect(find.text('100%'), findsNothing);
    expect(find.byKey(const ValueKey('runtime-player-touch-menu-open')),
        findsNothing);

    authority.value = const RuntimeInputAuthoritySnapshot(
      context: RuntimeInputContext.overworld,
    );
    await _settleMeasuredSession(tester);

    expect(find.byKey(const ValueKey('runtime-player-loading-art')),
        findsNothing);
    expect(find.byKey(const ValueKey('runtime-player-touch-menu-open')),
        findsOneWidget);
  });

  testWidgets('reveals an opening dialogue without waiting for the menu',
      (tester) async {
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(
      revision: 1,
      phase: RuntimePlayerPhase.loadingSession,
    ));
    final authority = ValueNotifier(const RuntimeInputAuthoritySnapshot(
      context: RuntimeInputContext.blocked,
    ));
    addTearDown(controller.dispose);
    addTearDown(authority.dispose);

    await _pumpMeasuredSessionWidget(tester, _app(_view(controller,
        gameplayInputAuthority: authority)));
    controller.publish(_snapshot(revision: 2, phase: RuntimePlayerPhase.playing));
    await tester.pump();
    expect(find.byKey(const ValueKey('runtime-player-loading-art')),
        findsOneWidget);

    authority.value = const RuntimeInputAuthoritySnapshot(
      context: RuntimeInputContext.dialogue,
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('runtime-player-loading-art')),
        findsNothing);
  });

  testWidgets('routes a preSession result through the Player command',
      (tester) async {
    final request = SceneInteractionRequest.message(
      requestId: 'pre-session-intro',
      revision: 3,
      prompt: SceneInteractionPrompt(
        localizationKey: 'test.pre_session.intro',
        fallbackText: 'Bienvenue à Avelune.',
      ),
    );
    final controller = _FakeRuntimePlayerCoordinator(
      RuntimePlayerSnapshot(
        revision: 12,
        phase: RuntimePlayerPhase.preSession,
        gameTitle: 'Aube',
        preSessionRequest: request,
        actions: const <RuntimePlayerActionAvailability>[
          RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.resolvePreSessionInteraction,
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);

    await _pumpMeasuredSessionWidget(tester, _app(_view(controller)));
    final tapZone =
        find.byKey(const ValueKey<String>('dialogue-tap-zone')).first;
    await tester.tap(tapZone);
    await tester.pump();
    expect(
      find.text('Bienvenue à Avelune.'),
      findsOneWidget,
      reason: 'the first press completed the typewriter',
    );
    await tester.tap(tapZone);
    await tester.pump();

    final command = controller.commands.single;
    expect(
      command.action,
      RuntimePlayerAction.resolvePreSessionInteraction,
    );
    expect(command.snapshotRevision, 12);
    expect(
      command.payload,
      isA<SceneAcknowledgedInteractionResult>()
          .having((result) => result.requestId, 'requestId', request.requestId)
          .having((result) => result.revision, 'revision', request.revision),
    );
  });

  testWidgets(
    'keeps a Presentation cue interaction above the active frame',
    (tester) async {
      final request = SceneInteractionRequest.message(
        requestId: 'presentation-cue',
        revision: 4,
        prompt: SceneInteractionPrompt(
          localizationKey: 'test.pre_session.cue',
          fallbackText: 'Quel est ton prénom ?',
        ),
      );
      final controller = _FakeRuntimePlayerCoordinator(
        RuntimePlayerSnapshot(
          revision: 18,
          phase: RuntimePlayerPhase.preSession,
          gameTitle: 'Aube',
          preSessionRequest: request,
          actions: const <RuntimePlayerActionAvailability>[
            RuntimePlayerActionAvailability.enabled(
              RuntimePlayerAction.resolvePreSessionInteraction,
            ),
          ],
        ),
      );
      final presentation = ValueNotifier<RuntimePresentationFrameSnapshot?>(
        RuntimePresentationFrameSnapshot(
          assetRevision: 'opening-revision-8',
          frame: _presentationFrame(),
          orientation: PresentationFrameOrientation.portrait,
        ),
      );
      addTearDown(controller.dispose);
      addTearDown(presentation.dispose);

      await _pumpMeasuredSessionWidget(tester,
        _app(
          _view(
            controller,
            presentationFrame: presentation,
            presentationContentPort: _PresentationContentPort(),
          ),
        ),
      );

      final tapZone =
          find.byKey(const ValueKey<String>('dialogue-tap-zone')).first;
      await tester.tap(tapZone);
      await tester.pump();
      expect(find.text('Quel est ton prénom ?'), findsOneWidget);
      await tester.tap(tapZone);
      await tester.pump();

      expect(controller.commands, hasLength(1));
      expect(
        controller.commands.single.action,
        RuntimePlayerAction.resolvePreSessionInteraction,
      );
      expect(controller.commands.single.snapshotRevision, 18);
    },
  );

  testWidgets('keyboard selects and confirms a preSession Presentation choice',
      (tester) async {
    SceneInteractionPrompt prompt(String text) => SceneInteractionPrompt(
      localizationKey: 'test.$text', fallbackText: text,
    );
    final request = SceneInteractionRequest.choice(
      requestId: 'identity-choice', revision: 4, prompt: prompt('Choisissez'),
      options: [
        SceneInteractionOption(id: 'first', label: prompt('Premier')),
        SceneInteractionOption(id: 'second', label: prompt('Deuxième')),
      ],
    );
    final controller = _FakeRuntimePlayerCoordinator(RuntimePlayerSnapshot(
      revision: 18, phase: RuntimePlayerPhase.preSession, gameTitle: 'Voyage',
      preSessionRequest: request,
      actions: const [RuntimePlayerActionAvailability.enabled(
        RuntimePlayerAction.resolvePreSessionInteraction)],
    ));
    final presentation = ValueNotifier<RuntimePresentationFrameSnapshot?>(
      RuntimePresentationFrameSnapshot(assetRevision: 'opening',
        frame: _presentationFrame(),
        orientation: PresentationFrameOrientation.portrait),
    );
    addTearDown(controller.dispose);
    addTearDown(presentation.dispose);
    await _pumpMeasuredSessionWidget(tester, _app(_view(controller,
      presentationFrame: presentation,
      presentationContentPort: _PresentationContentPort(),
    )));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(controller.commands, hasLength(1));
    expect(controller.commands.single.action,
      RuntimePlayerAction.resolvePreSessionInteraction);
    expect(controller.commands.single.payload,
      isA<SceneChoiceSelectedInteractionResult>().having(
        (result) => result.selectedOptionId, 'selected option', 'second'));
    controller.publish(RuntimePlayerSnapshot(
      revision: 19, phase: RuntimePlayerPhase.preSession, gameTitle: 'Voyage',
      preSessionRequest: SceneInteractionRequest.confirmation(
        requestId: 'confirm-identity', revision: 5, prompt: prompt('Valider ?')),
      actions: const [RuntimePlayerActionAvailability.enabled(
        RuntimePlayerAction.resolvePreSessionInteraction)],
    ));
    await tester.pump();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(controller.commands, hasLength(2));
    expect(controller.commands.last.snapshotRevision, 19);
    expect(controller.commands.last.payload,
      isA<SceneConfirmedInteractionResult>().having(
        (result) => result.value, 'confirmation', isFalse));
  });

  testWidgets(
    'keeps preSession presentation chrome out of the cinematic',
    (tester) async {
      final controller = _FakeRuntimePlayerCoordinator(
        RuntimePlayerSnapshot(
          revision: 19,
          phase: RuntimePlayerPhase.preSession,
          gameTitle: 'Aube',
          preferences: const PlayerPreferencesSnapshot(
            locale: 'fr',
            accessibility: GameSessionAccessibilityOptions(),
            showInputHints: true,
          ),
        ),
      );
      final presentation = ValueNotifier<RuntimePresentationFrameSnapshot?>(
        RuntimePresentationFrameSnapshot(
          assetRevision: 'opening-revision-9',
          frame: _presentationFrame(),
          orientation: PresentationFrameOrientation.landscape,
        ),
      );
      var skipCalls = 0;
      addTearDown(controller.dispose);
      addTearDown(presentation.dispose);

      await _pumpMeasuredSessionWidget(tester,
        _app(
          _view(
            controller,
            presentationFrame: presentation,
            presentationContentPort: _PresentationContentPort(),
            onPresentationSkip: () async => skipCalls += 1,
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('runtime-presentation-skip')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('runtime-player-input-hints')),
        findsNothing,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(skipCalls, 0);
    },
  );

  testWidgets('leaves keyboard letters to a focused preSession text field',
      (tester) async {
    final request = SceneInteractionRequest.text(
      requestId: 'player-name',
      revision: 1,
      prompt: SceneInteractionPrompt(
        localizationKey: 'newGame.playerName.prompt',
        fallbackText: 'Quel est ton prénom ?',
      ),
      constraints: SceneTextInputConstraints(
        minGraphemes: 1,
        maxGraphemes: 24,
      ),
    );
    final controller = _FakeRuntimePlayerCoordinator(
      RuntimePlayerSnapshot(
        revision: 20,
        phase: RuntimePlayerPhase.preSession,
        gameTitle: 'Aube',
        preSessionRequest: request,
        actions: const <RuntimePlayerActionAvailability>[
          RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.resolvePreSessionInteraction,
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);

    await _pumpMeasuredSessionWidget(tester, _app(_view(controller)));
    await tester.tap(
      find.byKey(const ValueKey<String>('scene-interaction-text-field')),
    );
    await tester.pumpAndSettle();

    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'Scene interaction text',
    );
    final inputAuthority = tester.widget<Focus>(
      find.byKey(
        const ValueKey<String>('runtime-player-keyboard-input-authority'),
      ),
    );
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    for (final key in const <(PhysicalKeyboardKey, LogicalKeyboardKey)>[
      (PhysicalKeyboardKey.keyW, LogicalKeyboardKey.keyW),
      (PhysicalKeyboardKey.keyA, LogicalKeyboardKey.keyA),
      (PhysicalKeyboardKey.keyS, LogicalKeyboardKey.keyS),
      (PhysicalKeyboardKey.keyD, LogicalKeyboardKey.keyD),
    ]) {
      expect(
        inputAuthority.onKeyEvent!(
          focusNode,
          KeyDownEvent(
            physicalKey: key.$1,
            logicalKey: key.$2,
            timeStamp: Duration.zero,
          ),
        ),
        KeyEventResult.ignored,
      );
    }

    expect(controller.commands, isEmpty);
  });

  testWidgets('keeps the game scene mounted only across live session phases',
      (tester) async {
    final lifecycle = _SceneLifecycle();
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(revision: 1, phase: RuntimePlayerPhase.loadingSession),
    );
    addTearDown(controller.dispose);

    await _pumpMeasuredSessionWidget(tester, _app(_view(controller, lifecycle: lifecycle)));
    expect(lifecycle.mounts, 1);
    expect(lifecycle.disposals, 0);

    for (final phase in <RuntimePlayerPhase>[
      RuntimePlayerPhase.playing,
      RuntimePlayerPhase.paused,
      RuntimePlayerPhase.saving,
      RuntimePlayerPhase.lifecyclePaused,
      RuntimePlayerPhase.completing,
      RuntimePlayerPhase.disposingSession,
    ]) {
      controller.publish(_snapshot(revision: phase.index + 10, phase: phase));
      await tester.pump();
      expect(lifecycle.mounts, 1);
      expect(lifecycle.disposals, 0);
    }

    controller.publish(_snapshot(
      revision: 30,
      phase: RuntimePlayerPhase.result,
    ));
    await tester.pump();
    expect(lifecycle.disposals, 1);
  });

  testWidgets('renders a contextual shop over the mounted runtime scene',
      (tester) async {
    final lifecycle = _SceneLifecycle();
    final service = RuntimeWorldServiceSnapshot(
      revision: 4,
      request: const OpenShopService(
        interactionId: 'npc.merchant',
        shopId: 'mart',
      ),
      stage: RuntimeWorldServiceStage.active,
      content: RuntimeShopServiceContent(
        title: 'Boutique du Port',
        message: 'Bienvenue !',
        money: 500,
        entries: const <RuntimeShopEntrySnapshot>[
          RuntimeShopEntrySnapshot(
            itemId: 'potion',
            label: 'Potion',
            unitPrice: 60,
          ),
        ],
        selectedItemId: 'potion',
        totalPrice: 60,
      ),
      actions: const <RuntimeWorldServiceActionAvailability>[
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.confirm,
        ),
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.close,
        ),
      ],
    );
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(
        revision: 18,
        phase: RuntimePlayerPhase.playing,
        worldService: service,
      ),
    );
    addTearDown(controller.dispose);

    await _pumpMeasuredSessionWidget(tester, _app(_view(controller, lifecycle: lifecycle)));

    expect(
        find.byKey(const ValueKey<String>('test-game-scene')), findsOneWidget);
    expect(find.text('Boutique du Port'), findsOneWidget);
    expect(lifecycle.mounts, 1);

    await tester.tap(find.byKey(const ValueKey<String>('shop-close')));
    expect(controller.worldServiceCommands.single.action,
        RuntimeWorldServiceAction.close);
    expect(controller.worldServiceCommands.single.snapshotRevision, 4);
  });

  testWidgets('renders contextual healing over the mounted runtime scene',
      (tester) async {
    final lifecycle = _SceneLifecycle();
    final service = RuntimeWorldServiceSnapshot(
      revision: 12,
      request: const OpenHealService(interactionId: 'npc.nurse'),
      stage: RuntimeWorldServiceStage.active,
      content: RuntimeHealServiceContent(
        title: 'Centre Pokémon',
        message: 'Soigner l’équipe ?',
        members: const <RuntimeHealPartyMemberSnapshot>[
          RuntimeHealPartyMemberSnapshot(
            partyIndex: 0,
            label: 'Sproutle',
            currentHp: 3,
            maxHp: 24,
            hasStatus: true,
            depletedMoveCount: 1,
          ),
        ],
      ),
      actions: const <RuntimeWorldServiceActionAvailability>[
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.confirm,
        ),
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.cancel,
        ),
      ],
    );
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(
        revision: 21,
        phase: RuntimePlayerPhase.playing,
        worldService: service,
      ),
    );
    addTearDown(controller.dispose);

    await _pumpMeasuredSessionWidget(tester, _app(_view(controller, lifecycle: lifecycle)));

    expect(
        find.byKey(const ValueKey<String>('test-game-scene')), findsOneWidget);
    expect(find.text('Centre Pokémon'), findsOneWidget);
    expect(lifecycle.mounts, 1);
    await tester.tap(find.byKey(const ValueKey<String>('heal-confirm')));
    expect(controller.worldServiceCommands.single.action,
        RuntimeWorldServiceAction.confirm);
    expect(controller.worldServiceCommands.single.snapshotRevision, 12);
  });

  testWidgets('renders the contextual PC over the mounted runtime scene',
      (tester) async {
    final lifecycle = _SceneLifecycle();
    final service = RuntimeWorldServiceSnapshot(
      revision: 14,
      request: const OpenPcService(
        interactionId: 'terminal.harbor',
        storageId: 'box-a',
      ),
      stage: RuntimeWorldServiceStage.active,
      content: RuntimePcServiceContent(
        title: 'PC Pokémon',
        message: 'Organisez votre équipe.',
        selectedBoxId: 'box-a',
        boxes: const <RuntimePcBoxSnapshot>[
          RuntimePcBoxSnapshot(
            boxId: 'box-a',
            label: 'Box A',
            count: 0,
            capacity: 30,
          ),
        ],
      ),
      actions: const <RuntimeWorldServiceActionAvailability>[
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.select,
        ),
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.close,
        ),
      ],
    );
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(
        revision: 22,
        phase: RuntimePlayerPhase.playing,
        worldService: service,
      ),
    );
    addTearDown(controller.dispose);

    await _pumpMeasuredSessionWidget(tester, _app(_view(controller, lifecycle: lifecycle)));

    expect(
        find.byKey(const ValueKey<String>('test-game-scene')), findsOneWidget);
    expect(find.text('PC Pokémon'), findsOneWidget);
    expect(lifecycle.mounts, 1);
    await tester.tap(find.byKey(const ValueKey<String>('pc-close')));
    expect(controller.worldServiceCommands.single.action,
        RuntimeWorldServiceAction.close);
    expect(controller.worldServiceCommands.single.snapshotRevision, 14);
  });

  testWidgets('keeps an actionable new game error readable on a phone',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(
      revision: 19,
      phase: RuntimePlayerPhase.error,
      failure: const GameSessionFailure(
        code: GameSessionFailureCode.runtime,
        diagnosticCode: 'new_game.seed_commit_stale_project',
        recoverability: GameSessionFailureRecoverability.retry,
        safeMessage: 'Le contenu du jeu a changé pendant la préparation. '
            'Relancez la création de la partie.',
      ),
      actions: const [
        RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.retry),
        RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.cancel),
      ],
    ));
    addTearDown(controller.dispose);
    await _pumpMeasuredSessionWidget(tester, _app(_view(controller)));
    await tester.pump(const Duration(seconds: 30));
    expect(find.textContaining('changé'), findsOneWidget);
    expect(find.text('new_game.seed_commit_stale_project'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Fermer'));
    await tester.tap(find.text('Fermer'));
    expect(controller.commands.single.action, RuntimePlayerAction.cancel);
  });

  testWidgets('shows safe error context and optional diagnostics',
      (tester) async {
    var diagnosticCalls = 0;
    final controller = _FakeRuntimePlayerCoordinator(_snapshot(
      revision: 19,
      phase: RuntimePlayerPhase.error,
      loadingProgress: const GameSessionLoadingProgress(
        stage: 'project',
        current: 1,
        total: 3,
      ),
      failure: const GameSessionFailure(
        code: GameSessionFailureCode.integrity,
        recoverability: GameSessionFailureRecoverability.repair,
        safeMessage: 'Un fichier du jeu est invalide.',
      ),
      actions: const <RuntimePlayerActionAvailability>[
        RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.retry),
      ],
    ));
    addTearDown(controller.dispose);

    await _pumpMeasuredSessionWidget(tester, _app(_view(
      controller,
      onShowDiagnostics: () => diagnosticCalls++,
    )));

    expect(find.text('Un fichier du jeu est invalide.'), findsOneWidget);
    expect(find.textContaining('project'), findsOneWidget);
    expect(find.textContaining('integrity'), findsOneWidget);
    expect(find.textContaining('réparez'), findsOneWidget);

    await tester.tap(find.text('Diagnostics'));
    expect(diagnosticCalls, 1);
  });

  testWidgets(
      'owns responsive virtual controls in portrait and landscape gameplay',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final gameplayEvents = <RuntimeInputEvent>[];
    final interactionsDispatched = <RuntimeOverworldInteractionRequest>[];
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(
        revision: 23,
        phase: RuntimePlayerPhase.playing,
        actions: const <RuntimePlayerActionAvailability>[
          RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.openMenu,
          ),
        ],
      ),
    );
    final interactions = ValueNotifier(_overworldSnapshot());
      addTearDown(interactions.dispose);
      addTearDown(controller.dispose);

    await _pumpMeasuredSessionWidget(tester,
      _app(
        _view(controller,
          overworldInteractions: interactions, onOverworldInteraction: (request) { interactionsDispatched.add(request); return true; },
          touchControlsAvailable: true,
          gameplayInputRoute: (event) {
            gameplayEvents.add(event);
            return true;
          },
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('runtime-player-touch-movement-zone')),
      findsOneWidget,
    );
    expect(
      find.byType(PlayerOverworldActionCapsule),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('runtime-player-touch-secondary-button'),
      ),
      findsNothing,
    );

    await tester.tap(
      find.byType(PlayerOverworldActionCapsule),
    );
    expect(interactionsDispatched, [interactions.value.primaryAction!.request]);
    expect(gameplayEvents, isEmpty);

    tester.view.physicalSize = const Size(844, 390);
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('runtime-player-touch-movement-zone')),
      findsOneWidget,
    );
    expect(find.byType(PlayerOverworldActionCapsule), findsOneWidget);
    await tester.tap(find.byType(PlayerOverworldActionCapsule));
    expect(interactionsDispatched, hasLength(2));
    expect(gameplayEvents, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'hides every touch affordance outside authoritative overworld input',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final authority = ValueNotifier<RuntimeInputAuthoritySnapshot>(
      const RuntimeInputAuthoritySnapshot(
        context: RuntimeInputContext.overworld,
      ),
    );
    addTearDown(authority.dispose);
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(
        revision: 25,
        phase: RuntimePlayerPhase.playing,
        actions: const <RuntimePlayerActionAvailability>[
          RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.openMenu,
          ),
        ],
      ),
    );
    final interactions = ValueNotifier(_overworldSnapshot());
      addTearDown(interactions.dispose);
      addTearDown(controller.dispose);

    await _pumpMeasuredSessionWidget(tester,
      _app(
        _view(controller,
          overworldInteractions: interactions, onOverworldInteraction: (_) => true,
          touchControlsAvailable: true,
          gameplayInputRoute: (_) => true,
          gameplayInputAuthority: authority,
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('runtime-player-touch-movement-zone')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('runtime-player-touch-menu-open')),
      findsOneWidget,
    );

    expect(find.byType(PlayerOverworldActionCapsule), findsOneWidget);
    authority.value = const RuntimeInputAuthoritySnapshot(
      context: RuntimeInputContext.battle,
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('runtime-player-touch-movement-zone')),
      findsNothing,
    );
    expect(
      find.byType(PlayerOverworldActionCapsule),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey<String>('runtime-player-touch-secondary-button'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('runtime-player-touch-menu-open')),
      findsNothing,
    );

    authority.value = const RuntimeInputAuthoritySnapshot(
      context: RuntimeInputContext.dialogue,
    );
    await tester.pump();
    expect(
      find.byType(PlayerOverworldActionCapsule),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('runtime-player-touch-menu-open')),
      findsNothing,
    );

    authority.value = const RuntimeInputAuthoritySnapshot(
      context: RuntimeInputContext.overworld,
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('runtime-player-touch-movement-zone')),
      findsOneWidget,
    );
    expect(
      find.byType(PlayerOverworldActionCapsule),
      findsOneWidget,
    );
  });

  for (final context in [RuntimeInputContext.dialogue, RuntimeInputContext.cinematic]) {
  testWidgets('renders the ${context.name} dialogue overlay and routes a mobile panel tap',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final authority = ValueNotifier<RuntimeInputAuthoritySnapshot>(
      RuntimeInputAuthoritySnapshot(
        context: context,
      ),
    );
    final dialogue = ValueNotifier<DialoguePresentationSnapshot?>(
      const DialoguePresentationSnapshot(
        revision: 8,
        mode: DialoguePresentationMode.line,
        nodeTitle: 'intro',
        speaker: 'Lysa',
        text: 'Appuie ici pour continuer.',
        fullText: 'Appuie ici pour continuer.',
        isCurrentLineFullyRevealed: true,
        isLastContent: false,
        choices: <DialoguePresentationChoice>[],
      ),
    );
    addTearDown(authority.dispose);
    addTearDown(dialogue.dispose);
    final commands = <DialoguePresentationCommand>[];
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(
        revision: 26,
        phase: RuntimePlayerPhase.playing,
      ),
    );
    addTearDown(controller.dispose);

    await _pumpMeasuredSessionWidget(tester,
      _app(
        _view(
          controller,
          touchControlsAvailable: true,
          gameplayInputRoute: (_) => true,
          gameplayInputAuthority: authority,
          dialoguePresentation: dialogue,
          onDialogueCommand: commands.add,
        ),
      ),
    );

    expect(find.text('Appuie ici pour continuer.'), findsOneWidget);
    expect(find.byKey(const ValueKey('runtime-player-touch-movement-zone')), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey<String>('dialogue-tap-zone')),
    );
    expect(
      commands.single,
      isA<DialogueAdvanceCommand>().having(
        (command) => command.snapshotRevision,
        'revision',
        8,
      ),
    );
    final preservedDialogue = dialogue.value;
    controller
        .publish(_snapshot(revision: 27, phase: RuntimePlayerPhase.paused));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dialogue-tap-zone')), findsNothing);
    expect(dialogue.value, same(preservedDialogue));
    controller
        .publish(_snapshot(revision: 28, phase: RuntimePlayerPhase.playing));
    await tester.pumpAndSettle();
    expect(find.text('Appuie ici pour continuer.'), findsOneWidget);
    expect(commands, hasLength(1));
  });
  }

  testWidgets('renders the canonical battle overlay and routes its command',
      (tester) async {
    final battle = ValueNotifier<BattleCommandOverlaySnapshot?>(
      const BattleCommandOverlaySnapshot(
        revision: 12,
        mode: BattleCommandOverlayMode.root,
        viewportSize: Size(800, 600),
        panelRect: Rect.fromLTWH(0, 300, 800, 300),
        enemyHud: BattleCommandOverlayHudSnapshot(
          rect: Rect.fromLTWH(20, 20, 240, 80),
          ownerLabel: 'Adversaire',
          speciesLabel: 'Roucool',
          level: 7,
          currentHp: 20,
          maxHp: 20,
          isPlayerSide: false,
        ),
        playerHud: BattleCommandOverlayHudSnapshot(
          rect: Rect.fromLTWH(540, 200, 240, 80),
          ownerLabel: 'Joueur',
          speciesLabel: 'Brindibou',
          level: 8,
          currentHp: 24,
          maxHp: 24,
          isPlayerSide: true,
        ),
        battleLabel: 'Combat sauvage',
        title: 'Roucool sauvage',
        prompt: 'Que doit faire Brindibou ?',
        narrationLines: <String>[],
        entries: <BattleCommandOverlayEntry>[
          BattleCommandOverlayEntry(
            index: 0,
            kind: BattleCommandOverlayEntryKind.root,
            primaryLabel: 'Attaque',
            secondaryLabel: 'Choisir une capacité',
            enabled: true,
            selected: true,
            tone: BattleCommandOverlayEntryTone.attack,
          ),
        ],
        interactionsEnabled: true,
        canGoBack: false,
      ),
    );
    addTearDown(battle.dispose);
    final commands = <BattlePresentationCommand>[];
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(
        revision: 27,
        phase: RuntimePlayerPhase.playing,
        actions: const <RuntimePlayerActionAvailability>[
          RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.openMenu),
        ],
        preferences: const PlayerPreferencesSnapshot(
          locale: 'fr',
          accessibility: GameSessionAccessibilityOptions(),
          showInputHints: true,
        ),
      ),
    );
    final interactions = ValueNotifier(_overworldSnapshot());
      addTearDown(interactions.dispose);
      addTearDown(controller.dispose);

    await _pumpMeasuredSessionWidget(tester,
      _app(
        _view(controller,
          overworldInteractions: interactions, onOverworldInteraction: (_) => true,
          battlePresentation: battle,
          onBattleCommand: commands.add,
        ),
      ),
    );

    expect(find.byType(PlayerBattleOverlay), findsOneWidget);
    expect(
      find.byType(PlayerOverworldActionCapsule),
      findsNothing,
    );
    expect(find.text('Roucool'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    await tester.pump();
    expect(controller.commands, isEmpty);
    await tester.tap(
      find.byKey(const ValueKey<String>('battle-entry-0')),
    );
    expect(
      commands,
      hasLength(2),
    );
    expect(
      commands.first,
      isA<BattleSetCommandPanelPlacementCommand>()
          .having((command) => command.snapshotRevision, 'revision', 12)
          .having((command) => command.expectedMode, 'mode', BattleCommandOverlayMode.root)
          .having((command) => command.placement, 'placement', BattleCommandPanelPlacement.end),
    );
    expect(
      commands.last,
      isA<BattleSelectEntryCommand>()
          .having((command) => command.snapshotRevision, 'revision', 12)
          .having((command) => command.entryIndex, 'entry', 0),
    );

    battle.value = null;
    await tester.pump();
    expect(
      find.byType(PlayerOverworldActionCapsule),
      findsOneWidget,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    await tester.pump();
    expect(controller.commands.single.action, RuntimePlayerAction.openMenu);
  });

  testWidgets('applies touch opacity and clamps floating visual inside viewport',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(
        revision: 27,
        phase: RuntimePlayerPhase.playing,
        preferences: const PlayerPreferencesSnapshot(
          locale: 'fr',
          accessibility: GameSessionAccessibilityOptions(),
          touchControlsOpacity: .45,
        ),
        actions: const <RuntimePlayerActionAvailability>[
          RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.openMenu,
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);

    await _pumpMeasuredSessionWidget(tester,
      _app(
        _view(
          controller,
          touchControlsAvailable: true,
          gameplayInputRoute: (_) => true,
        ),
      ),
    );

    final gesture = await tester.startGesture(const Offset(20, 820), kind: ui.PointerDeviceKind.touch);
    await tester.pump();
    expect(
      tester
          .getBottomLeft(
            find.byKey(
              const ValueKey<String>('runtime-player-touch-joystick'),
            ),
          )
          .dy,
      lessThanOrEqualTo(844),
    );
    expect(
      tester
          .widget<Opacity>(
            find.byKey(
              const ValueKey<String>('runtime-player-touch-controls-opacity'),
            ),
          )
          .opacity,
      .45,
    );
    await gesture.up();
  });

  testWidgets('rejects exploration menu input while battle owns input',
      (tester) async {
    final authority = ValueNotifier<RuntimeInputAuthoritySnapshot>(
      const RuntimeInputAuthoritySnapshot(
          context: RuntimeInputContext.overworld),
    );
    final controllerEvents = StreamController<RuntimeInputEvent>.broadcast();
    final gameplayEvents = <RuntimeInputEvent>[];
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(
        revision: 24,
        phase: RuntimePlayerPhase.playing,
        actions: const <RuntimePlayerActionAvailability>[
          RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.openMenu),
        ],
      ),
    );
    addTearDown(authority.dispose);
    addTearDown(controllerEvents.close);
    addTearDown(controller.dispose);
    await _pumpMeasuredSessionWidget(tester, _app(_view(
      controller,
      touchControlsAvailable: true,
      gameplayInputAuthority: authority,
      controllerInputEvents: controllerEvents.stream,
      gameplayInputRoute: (event) {
        gameplayEvents.add(event);
        return true;
      },
    )));

    authority.value = const RuntimeInputAuthoritySnapshot(
      context: RuntimeInputContext.battle,
    );
    await tester.tap(find.byKey(
      const ValueKey<String>('runtime-player-touch-menu-open'),
    ));
    await tester.pump();
    expect(controller.commands, isEmpty);

    for (final context in [
      RuntimeInputContext.battle,
      RuntimeInputContext.transition,
    ]) {
      authority.value = RuntimeInputAuthoritySnapshot(context: context);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      controllerEvents.add(
        const RuntimeInputEvent.press(RuntimeInputControl.menu),
      );
      await tester.pump();
      expect(controller.commands, isEmpty, reason: context.name);
    }
    authority.value = const RuntimeInputAuthoritySnapshot(
      context: RuntimeInputContext.battle,
    );
    controllerEvents.add(
      const RuntimeInputEvent.press(RuntimeInputControl.primary),
    );
    await tester.pump();
    expect(gameplayEvents.last.control, RuntimeInputControl.primary);

    authority.value = const RuntimeInputAuthoritySnapshot(
      context: RuntimeInputContext.overworld,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    await tester.pump();
    expect(controller.commands.single.action, RuntimePlayerAction.openMenu);
  });

  testWidgets('preserves exploration pause during dialogue', (tester) async {
    final authority = ValueNotifier<RuntimeInputAuthoritySnapshot>(
      const RuntimeInputAuthoritySnapshot(
          context: RuntimeInputContext.dialogue),
    );
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(
        revision: 24,
        phase: RuntimePlayerPhase.playing,
        actions: const <RuntimePlayerActionAvailability>[
          RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.openMenu),
        ],
      ),
    );
    addTearDown(authority.dispose);
    addTearDown(controller.dispose);
    await _pumpMeasuredSessionWidget(tester, _app(_view(
      controller,
      gameplayInputAuthority: authority,
    )));
    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    await tester.pump();
    expect(controller.commands.single.action, RuntimePlayerAction.openMenu);
  });

  testWidgets('routes controller gameplay and reserves Start for pause',
      (tester) async {
    final controllerEvents = StreamController<RuntimeInputEvent>.broadcast();
    addTearDown(controllerEvents.close);
    final gameplayEvents = <RuntimeInputEvent>[];
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(
        revision: 24,
        phase: RuntimePlayerPhase.playing,
        actions: const <RuntimePlayerActionAvailability>[
          RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.openMenu,
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);

    await _pumpMeasuredSessionWidget(tester,
      _app(
        _view(
          controller,
          controllerInputEvents: controllerEvents.stream,
          gameplayInputRoute: (event) {
            gameplayEvents.add(event);
            return true;
          },
        ),
      ),
    );

    controllerEvents.add(
      const RuntimeInputEvent.press(RuntimeInputControl.right),
    );
    await tester.pump();
    expect(
      gameplayEvents,
      const <RuntimeInputEvent>[
        RuntimeInputEvent.press(RuntimeInputControl.right),
      ],
    );

    controllerEvents.add(
      const RuntimeInputEvent.press(RuntimeInputControl.menu),
    );
    await tester.pump();
    expect(gameplayEvents, hasLength(2));
    expect(
      gameplayEvents.skip(1),
      const <RuntimeInputEvent>[
        RuntimeInputEvent.release(RuntimeInputControl.right),
      ],
    );
    expect(controller.commands.single.action, RuntimePlayerAction.openMenu);
    expect(controller.commands.single.snapshotRevision, 24);
  });

  testWidgets('routes keyboard gameplay and Menu through one player ingress',
      (tester) async {
    final gameplayEvents = <RuntimeInputEvent>[];
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(
        revision: 31,
        phase: RuntimePlayerPhase.playing,
        actions: const <RuntimePlayerActionAvailability>[
          RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.openMenu,
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);

    await _pumpMeasuredSessionWidget(tester,
      _app(
        _view(
          controller,
          controllerInputEnabled: true,
          gameplayInputRoute: (event) {
            gameplayEvents.add(event);
            return true;
          },
        ),
      ),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    await tester.pump();

    expect(
      gameplayEvents,
      const <RuntimeInputEvent>[
        RuntimeInputEvent.press(RuntimeInputControl.right),
        RuntimeInputEvent.release(RuntimeInputControl.right),
      ],
    );
    expect(controller.commands, hasLength(1));
    expect(controller.commands.single.action, RuntimePlayerAction.openMenu);
    expect(controller.commands.single.snapshotRevision, 31);
  });

  testWidgets('routes a remapped keyboard profile through the canonical seam',
      (tester) async {
    final gameplayEvents = <RuntimeInputEvent>[];
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(revision: 32, phase: RuntimePlayerPhase.playing),
    );
    addTearDown(controller.dispose);
    final profile = PlayerControlProfile.standard
        .rebind(
          device: PlayerControlDevice.keyboard,
          control: RuntimeInputControl.primary,
          inputId: 'keyZ',
        )
        .profile;

    await _pumpMeasuredSessionWidget(tester,
      _app(
        _view(
          controller,
          controlProfile: profile,
          gameplayInputRoute: (event) {
            gameplayEvents.add(event);
            return true;
          },
        ),
      ),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
    await tester.pump();

    expect(
      gameplayEvents,
      const <RuntimeInputEvent>[
        RuntimeInputEvent.press(RuntimeInputControl.primary),
        RuntimeInputEvent.release(RuntimeInputControl.primary),
      ],
    );
  });

  testWidgets('consumes repeated Menu while raw controller A works with either normalized setting',
      (tester) async {
    final gameplayEvents = <RuntimeInputEvent>[];
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(
        revision: 32,
        phase: RuntimePlayerPhase.playing,
        actions: const <RuntimePlayerActionAvailability>[
          RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.openMenu,
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);

    await _pumpMeasuredSessionWidget(tester,
      _app(
        _view(
          controller,
          controllerInputEnabled: true,
          gameplayInputRoute: (event) {
            gameplayEvents.add(event);
            return true;
          },
        ),
      ),
    );

    final inputAuthority = tester.widget<Focus>(
      find.byKey(
        const ValueKey<String>('runtime-player-keyboard-input-authority'),
      ),
    );
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    expect(
      inputAuthority.onKeyEvent!(
        focusNode,
        const KeyRepeatEvent(
          physicalKey: PhysicalKeyboardKey.keyM,
          logicalKey: LogicalKeyboardKey.keyM,
          timeStamp: Duration.zero,
        ),
      ),
      KeyEventResult.handled,
    );
    expect(
      inputAuthority.onKeyEvent!(
        focusNode,
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.gameButtonA,
          logicalKey: LogicalKeyboardKey.gameButtonA,
          timeStamp: Duration.zero,
          deviceType: ui.KeyEventDeviceType.gamepad,
        ),
      ),
      KeyEventResult.handled,
    );
    await tester.pump();

    expect(gameplayEvents, const [RuntimeInputEvent.press(RuntimeInputControl.primary)]);
    inputAuthority.onKeyEvent!(
      focusNode,
      const KeyUpEvent(
        physicalKey: PhysicalKeyboardKey.gameButtonA,
        logicalKey: LogicalKeyboardKey.gameButtonA,
        timeStamp: Duration.zero,
        deviceType: ui.KeyEventDeviceType.gamepad,
      ),
    );
    await tester.pump();
    expect(gameplayEvents, const [
      RuntimeInputEvent.press(RuntimeInputControl.primary),
      RuntimeInputEvent.release(RuntimeInputControl.primary),
    ]);
    gameplayEvents.clear();
    expect(controller.commands, isEmpty);

    await _pumpMeasuredSessionWidget(tester,
      _app(
        _view(
          controller,
          controllerInputEnabled: false,
          gameplayInputRoute: (event) {
            gameplayEvents.add(event);
            return true;
          },
        ),
      ),
    );
    final hardwareFallback = tester.widget<Focus>(
      find.byKey(
        const ValueKey<String>('runtime-player-keyboard-input-authority'),
      ),
    );
    expect(
      hardwareFallback.onKeyEvent!(
        focusNode,
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.gameButtonA,
          logicalKey: LogicalKeyboardKey.gameButtonA,
          timeStamp: Duration.zero,
          deviceType: ui.KeyEventDeviceType.gamepad,
        ),
      ),
      KeyEventResult.handled,
    );
    await tester.pump();
    expect(
      gameplayEvents,
      const <RuntimeInputEvent>[
        RuntimeInputEvent.press(RuntimeInputControl.primary),
      ],
      reason: 'Raw controller input remains available without normalized events.',
    );
    hardwareFallback.onKeyEvent!(
      focusNode,
      const KeyUpEvent(
        physicalKey: PhysicalKeyboardKey.gameButtonA,
        logicalKey: LogicalKeyboardKey.gameButtonA,
        timeStamp: Duration.zero,
        deviceType: ui.KeyEventDeviceType.gamepad,
      ),
    );
    await tester.pump();
    expect(gameplayEvents, const [
      RuntimeInputEvent.press(RuntimeInputControl.primary),
      RuntimeInputEvent.release(RuntimeInputControl.primary),
    ]);
  });

  testWidgets('blocks gameplay while an asynchronous Menu transition settles',
      (tester) async {
    final menuTransition = Completer<RuntimePlayerCommandResult>();
    final gameplayEvents = <RuntimeInputEvent>[];
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(
        revision: 33,
        phase: RuntimePlayerPhase.playing,
        actions: const <RuntimePlayerActionAvailability>[
          RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.openMenu,
          ),
        ],
      ),
      commandCompleter: menuTransition,
    );
    addTearDown(controller.dispose);

    await _pumpMeasuredSessionWidget(tester,
      _app(
        _view(
          controller,
          gameplayInputRoute: (event) {
            gameplayEvents.add(event);
            return true;
          },
        ),
      ),
    );
    final inputAuthority = tester.widget<Focus>(
      find.byKey(
        const ValueKey<String>('runtime-player-keyboard-input-authority'),
      ),
    );
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    final menuPosition = tester.getCenter(find.byKey(
      const ValueKey<String>('runtime-player-touch-menu-open'),
    ));
    inputAuthority.onKeyEvent!(
      focusNode,
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyM,
        logicalKey: LogicalKeyboardKey.keyM,
        timeStamp: Duration.zero,
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('runtime-player-touch-menu-open')), findsNothing);
    await tester.tapAt(menuPosition);
    await tester.pump();
    inputAuthority.onKeyEvent!(
      focusNode,
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowRight,
        logicalKey: LogicalKeyboardKey.arrowRight,
        timeStamp: Duration.zero,
      ),
    );
    await tester.pump();

    expect(controller.commands, hasLength(1));
    expect(
      gameplayEvents,
      isEmpty,
      reason: 'No new gameplay press may enter while Menu is opening.',
    );

    controller.publish(
      _snapshot(
        revision: 34,
        phase: RuntimePlayerPhase.paused,
        actions: const <RuntimePlayerActionAvailability>[
          RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.resume,
          ),
        ],
      ),
    );
    menuTransition.complete(
      const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.accepted,
      ),
    );
    await tester.pump();
  });
}

void _expectTouchControls(WidgetTester tester, bool visible) {
  final opacity = tester
      .widget<Opacity>(
          find.byKey(const ValueKey('runtime-player-touch-controls-opacity')))
      .opacity;
  expect(opacity, visible ? greaterThan(0) : 0);
  expect(tester.widget<RuntimePlayerTouchControls>(find.byType(RuntimePlayerTouchControls)).showControls, visible);
  expect(find.byKey(const ValueKey('runtime-player-touch-primary-button')), findsNothing);
  expect(find.byKey(const ValueKey('runtime-player-touch-secondary-button')), findsNothing);
}

NormalizedGamepadEvent _padInput(
        {GamepadButton? button,
        GamepadAxis? axis,
        double value = 1,
        String gamepadId = 'pad',
        int? vendorId,
        int? productId}) =>
    NormalizedGamepadEvent(
      gamepadId: gamepadId,
      timestamp: 1,
      value: value,
      button: button,
      axis: axis,
      rawEvent: GamepadEvent(
          gamepadId: gamepadId,
          vendorId: vendorId,
          productId: productId,
          timestamp: 1,
          type: button == null ? KeyType.analog : KeyType.button,
          key: (button?.name ?? axis!.name),
          value: value),
    );

PokeMapPlayerSessionView _view(
  RuntimePlayerViewController controller, {
  _SceneLifecycle? lifecycle,
  GlobalKey? gameplayViewportKey,
  WidgetBuilder? gameSceneBuilder,
  VoidCallback? onShowDiagnostics,
  bool touchControlsAvailable = false,
  PlayerGameplayInputRoute? gameplayInputRoute,
  Stream<RuntimeInputEvent>? controllerInputEvents,
  Stream<NormalizedGamepadEvent>? normalizedControllerInputEvents,
  ValueListenable<Set<String>>? connectedControllerIds,
  ValueListenable<RuntimeInputAuthoritySnapshot>? gameplayInputAuthority,
  ImageProvider? loadingLogo,
  ImageProvider? loadingWordmark,
  ValueListenable<RuntimeOverworldInteractionSnapshot>? overworldInteractions,
  RuntimeOverworldInteractionRequest? Function(Offset)? hitTestOverworldInteraction,
  bool Function(RuntimeOverworldInteractionRequest)? onOverworldInteraction,
  ValueListenable<DialoguePresentationSnapshot?>? dialoguePresentation,
  ValueChanged<DialoguePresentationCommand>? onDialogueCommand,
  ValueListenable<BattleCommandOverlaySnapshot?>? battlePresentation,
  ValueChanged<BattlePresentationCommand>? onBattleCommand,
  bool? controllerInputEnabled,
  RuntimePlayerActionPayloadBuilder? payloadForAction,
  Future<void> Function()? hapticFeedback,
  PlayerControlProfile? controlProfile,
  PlayerPausePresentation? pausePresentation,
  FutureOr<void> Function(PlayerControlProfile)? onControlProfileChanged,
  ValueListenable<RuntimePresentationFrameSnapshot?>? presentationFrame,
  PresentationFrameContentPort? presentationContentPort,
  Future<void> Function()? onPresentationSkip,
  RuntimePlayerSessionCommandController? commandController,
  bool companionMenusAttached = false,
  bool companionNarrativeAttached = false,
  bool Function(RuntimeInputEvent)? onCompanionInput,
  bool relayedControllerInput = false,
  ValueListenable<bool>? menuInteractionBlocked,
}) {
  final viewportKey = gameplayViewportKey ?? GlobalKey();
  return PokeMapPlayerSessionView(
    commandController: commandController,
    companionMenusAttached: companionMenusAttached,
    companionNarrativeAttached: companionNarrativeAttached,
    onCompanionInput: onCompanionInput,
    relayedControllerInput: relayedControllerInput,
    menuInteractionBlocked: menuInteractionBlocked,
    gameplayViewportKey: viewportKey,
    controller: controller,
    titlePresentation: const RuntimePlayerTitlePresentation(
      author: 'Studio Test',
      description: 'Une aventure de test.',
    ),
    payloadForAction: payloadForAction,
    gameSceneBuilder: gameSceneBuilder ?? (_) => SizedBox.expand(key: viewportKey, child: _SceneProbe(
      key: const ValueKey<String>('test-game-scene'),
      lifecycle: lifecycle ?? _SceneLifecycle(),
    )),
    touchControlsAvailable: touchControlsAvailable,
    gameplayInputRoute: gameplayInputRoute,
    gameplayInputAuthority: gameplayInputAuthority,
    loadingLogo: loadingLogo,
    loadingWordmark: loadingWordmark,
    overworldInteractions: overworldInteractions,
    hitTestOverworldInteraction: hitTestOverworldInteraction,
    onOverworldInteraction: onOverworldInteraction,
    dialoguePresentation: dialoguePresentation,
    onDialogueCommand: onDialogueCommand,
    battlePresentation: battlePresentation,
    onBattleCommand: onBattleCommand,
    controllerInputEvents: controllerInputEvents,
    normalizedControllerInputEvents: normalizedControllerInputEvents,
    connectedControllerIds: connectedControllerIds,
    controllerInputEnabled: controllerInputEnabled ??
        (controllerInputEvents != null ||
            normalizedControllerInputEvents != null),
    onShowDiagnostics: onShowDiagnostics,
    hapticFeedback: hapticFeedback,
    controlProfile: controlProfile,
    pausePresentation: pausePresentation,
    onControlProfileChanged: onControlProfileChanged,
    presentationFrame: presentationFrame,
    presentationContentPort: presentationContentPort,
    onPresentationSkip: onPresentationSkip,
  );
}

BattleCommandOverlaySnapshot _moveBattleSnapshot() =>
    const BattleCommandOverlaySnapshot(
      revision: 14,
      mode: BattleCommandOverlayMode.fight,
      viewportSize: Size(800, 600),
      panelRect: Rect.fromLTWH(0, 300, 800, 300),
      enemyHud: BattleCommandOverlayHudSnapshot(
        rect: Rect.fromLTWH(20, 20, 240, 80),
        ownerLabel: 'Adversaire',
        speciesLabel: 'Roucool',
        level: 7,
        currentHp: 20,
        maxHp: 20,
        isPlayerSide: false,
      ),
      playerHud: BattleCommandOverlayHudSnapshot(
        rect: Rect.fromLTWH(540, 200, 240, 80),
        ownerLabel: 'Joueur',
        speciesLabel: 'Brindibou',
        level: 8,
        currentHp: 24,
        maxHp: 24,
        isPlayerSide: true,
      ),
      battleLabel: 'Combat sauvage',
      title: 'Capacités',
      prompt: 'Choisir une capacité',
      narrationLines: [],
      entries: [
        BattleCommandOverlayEntry(
          index: 0,
          kind: BattleCommandOverlayEntryKind.move,
          primaryLabel: 'Charge',
          secondaryLabel: 'normal',
          tertiaryLabel: 'Puissance 40 · Précision 100 %',
          trailingLabel: 'PP 30 / 35',
          enabled: true,
          selected: true,
          tone: BattleCommandOverlayEntryTone.attack,
        ),
      ],
      interactionsEnabled: true,
      canGoBack: true,
    );

RuntimeOverworldInteractionSnapshot _overworldSnapshot({String target = 'npc', bool hasAction = true, bool tapOnly = false}) {
  final action = !hasAction ? null : RuntimeOverworldInteractionAction(
        request: RuntimeOverworldInteractionRequest(sessionId: 'session', mapActivationId: 'activation', mapId: 'map',
          targetKind: RuntimeOverworldInteractionTargetKind.entity, targetId: target, actionId: 'talk'),
        verb: RuntimeOverworldInteractionVerb.talk, targetCell: const GridPos(x: 1, y: 1),
        targetBounds: const PixelRect(leftPx: 32, topPx: 32, widthPx: 32, heightPx: 32));
  return RuntimeOverworldInteractionSnapshot(sessionId: 'session', mapActivationId: 'activation', mapId: 'map',
      primaryAction: tapOnly ? null : action, tapAction: action);
}

RuntimePlayerSnapshot _snapshot({
  required int revision,
  required RuntimePlayerPhase phase,
  List<RuntimePlayerActionAvailability> actions =
      const <RuntimePlayerActionAvailability>[],
  GameSessionLoadingProgress? loadingProgress,
  GameSessionFailure? failure,
  RuntimeWorldServiceSnapshot? worldService,
  PlayerPreferencesSnapshot? preferences,
}) {
  return RuntimePlayerSnapshot(
    revision: revision,
    phase: phase,
    gameTitle: 'Aube',
    pauseSection: phase == RuntimePlayerPhase.paused
        ? RuntimePlayerPauseSection.root
        : null,
    actions: actions,
    loadingProgress: loadingProgress,
    failure: failure,
    worldService: worldService,
    preferences: preferences,
    result: phase == RuntimePlayerPhase.result
        ? const GameResultSnapshot(
            title: 'Victoire',
            summary: 'La région est sauvée.',
          )
        : null,
    credits: phase == RuntimePlayerPhase.result ||
            phase == RuntimePlayerPhase.credits
        ? const GameCreditsSnapshot(
            title: 'Aube',
            author: 'Studio Test',
            endingLabel: 'Fin principale',
          )
        : null,
  );
}

Finder _surfaceFinder(RuntimePlayerPhase phase) => find.byKey(
      ValueKey<String>('runtime-player-surface-${phase.name}'),
    );

Finder _allCanonicalSurfaces() => find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          ((widget.key! as ValueKey<String>).value)
              .startsWith('runtime-player-surface-'),
    );

Future<void> _hardwareGamepadPress(WidgetTester tester,
    LogicalKeyboardKey logical, PhysicalKeyboardKey physical, {
    Future<void> Function()? whileHeld,
  }) async {
  Future<bool> send(bool down) async {
    tester.binding.platformDispatcher.onKeyData!(ui.KeyData(
      timeStamp: Duration.zero, type: down ? ui.KeyEventType.down : ui.KeyEventType.up,
      physical: physical.usbHidUsage, logical: logical.keyId,
      character: null, synthesized: false, deviceType: ui.KeyEventDeviceType.gamepad));
    final response = Completer<bool>();
    final data = KeyEventSimulator.getKeyData(logical,
      platform: 'android', isDown: down, physicalKey: physical)..['source'] = 0x00000401;
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.keyEvent.name, SystemChannels.keyEvent.codec.encodeMessage(data), (reply) {
        final value = SystemChannels.keyEvent.codec.decodeMessage(reply) as Map<Object?, Object?>?;
        response.complete(value?['handled'] == true);
      });
    return response.future;
  }
  try {
    expect(await send(true), isTrue);
    await whileHeld?.call();
  } finally {
    await send(false);
  }
}

RuntimePlayerSnapshot _pausedOptionsSnapshot() => RuntimePlayerSnapshot(
  revision: 87,
  phase: RuntimePlayerPhase.paused,
  gameTitle: 'Aube',
  pauseSection: RuntimePlayerPauseSection.options,
  preferences: const PlayerPreferencesSnapshot(
    locale: 'fr', accessibility: GameSessionAccessibilityOptions()),
  actions: [for (final action in RuntimePlayerAction.values)
    RuntimePlayerActionAvailability.enabled(action)],
);

RuntimePlayerSnapshot _titleOptionsSnapshot() => RuntimePlayerSnapshot(
      revision: 86,
      phase: RuntimePlayerPhase.title,
      gameTitle: 'Aube',
      pauseSection: RuntimePlayerPauseSection.options,
      preferences: const PlayerPreferencesSnapshot(
          locale: 'fr', accessibility: GameSessionAccessibilityOptions()),
      actions: const [
        RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.openOptions),
        RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.updatePreferences),
        RuntimePlayerActionAvailability.enabled(
            RuntimePlayerAction.returnToTitle),
      ],
    );

Future<void> _selectOptionsCategory(WidgetTester tester, String category, {bool mouse = false}) async {
  final target = find.byKey(ValueKey('options-category-$category'));
  final picker = find.byKey(const ValueKey('options-category-picker'));
  if (target.evaluate().isEmpty && picker.evaluate().isNotEmpty) {
    await tester.tap(picker, kind: mouse ? ui.PointerDeviceKind.mouse : ui.PointerDeviceKind.touch);
    await tester.pumpAndSettle();
  }
  await _revealPagedTarget(tester, target, scope: find.byKey(const ValueKey('options-categories')), mouse: mouse);
  await tester.tap(target, kind: mouse ? ui.PointerDeviceKind.mouse : ui.PointerDeviceKind.touch);
  await tester.pumpAndSettle();
}

Widget _app(Widget child, {TargetPlatform? platform}) => MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark().copyWith(platform: platform),
      home: child,
    );

final class _FakeRuntimePlayerCoordinator
    implements RuntimePlayerViewController {
  _FakeRuntimePlayerCoordinator(
    this._snapshot, {
    this.commandCompleter,
  });

  final _snapshots = StreamController<RuntimePlayerSnapshot>.broadcast();
  final Completer<RuntimePlayerCommandResult>? commandCompleter;
  final commands = <RuntimePlayerCommand>[];
  final backRequests = <int>[];
  final worldServiceCommands = <RuntimeWorldServiceCommand>[];
  RuntimePlayerSnapshot _snapshot;

  @override
  RuntimePlayerSnapshot get snapshot => _snapshot;

  @override
  Stream<RuntimePlayerSnapshot> get snapshots => _snapshots.stream;

  void publish(RuntimePlayerSnapshot snapshot) {
    _snapshot = snapshot;
    _snapshots.add(snapshot);
  }

  @override
  Future<RuntimePlayerCommandResult> dispatch(
    RuntimePlayerCommand command,
  ) async {
    commands.add(command);
    final pending = commandCompleter;
    if (pending != null) return pending.future;
    return const RuntimePlayerCommandResult(
      status: RuntimePlayerCommandStatus.accepted,
    );
  }

  @override
  Future<RuntimePlayerCommandResult> requestBack({
    required int snapshotRevision,
  }) async {
    backRequests.add(snapshotRevision);
    return const RuntimePlayerCommandResult(
      status: RuntimePlayerCommandStatus.accepted,
    );
  }

  @override
  Future<RuntimeWorldServiceCommandResult> dispatchWorldService(
    RuntimeWorldServiceCommand command,
  ) async {
    worldServiceCommands.add(command);
    return const RuntimeWorldServiceCommandResult(
      status: RuntimeWorldServiceCommandStatus.accepted,
    );
  }

  Future<void> dispose() => _snapshots.close();
}

final class _SceneLifecycle {
  int mounts = 0;
  int disposals = 0;
}

class _SceneProbe extends StatefulWidget {
  const _SceneProbe({
    super.key,
    required this.lifecycle,
  });

  final _SceneLifecycle lifecycle;

  @override
  State<_SceneProbe> createState() => _SceneProbeState();
}

class _SceneProbeState extends State<_SceneProbe> {
  @override
  void initState() {
    super.initState();
    widget.lifecycle.mounts++;
  }

  @override
  void dispose() {
    widget.lifecycle.disposals++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const ColoredBox(color: Colors.black);
}

final class _PresentationContentPort implements PresentationFrameContentPort {
  final visualRequests = <String>[];

  @override
  PresentationVisualResolution resolveVisual({
    required PresentationVisualFrameClip clip,
    required PresentationFrameOrientation orientation,
  }) {
    visualRequests.add(clip.resourceId);
    return const PresentationVisualReady(child: SizedBox.expand());
  }

  @override
  PresentationCaptionResolution resolveCaption({
    required PresentationCaptionFrameClip clip,
    required Locale locale,
  }) =>
      const PresentationCaptionReady(text: 'Sous-titre');
}

PresentationFrame _presentationFrame() => PresentationFrame(
      cinematicId: 'opening',
      timeUs: 750000,
      durationUs: 2000000,
      visuals: <PresentationVisualFrameClip>[
        PresentationVisualFrameClip(
          clipId: 'opening-visual',
          trackId: 'visuals',
          layerId: 'background',
          zIndex: 0,
          resourceId: 'opening-shared',
          startUs: 0,
          durationUs: 2000000,
          elapsedUs: 750000,
          progress: .375,
          easedProgress: .375,
          easing: PresentationEasing.linear,
          composition: PresentationVisualComposition(),
          reducedMotionComposition: PresentationVisualComposition(),
        ),
      ],
    );

Future<void> _pumpMeasuredSessionWidget(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  await _settleMeasuredSession(tester);
}

Future<void> _settleMeasuredSession(WidgetTester tester) async {
  for (var frame = 0; frame < 4; frame++) {
    await tester.pump();
  }
}

Future<void> _revealPagedTarget(WidgetTester tester, Finder target, {Finder? scope, bool mouse = false}) async {
  await tester.pump();
  await tester.pump();
  Finder buttons(String key) => scope == null
      ? find.byKey(ValueKey(key)).hitTestable()
      : find.descendant(of: scope, matching: find.byKey(ValueKey(key))).hitTestable();
  for (final direction in ['player-page-previous', 'player-page-next']) {
    for (var step = 0; step < 40 && target.evaluate().isEmpty; step++) {
      final candidates = buttons(direction);
      final enabled = [for (final element in candidates.evaluate())
        if ((element.widget as IconButton).onPressed != null) element];
      if (enabled.isEmpty) break;
      await tester.tap(find.byElementPredicate((element) => identical(element, enabled.last)), kind: mouse ? ui.PointerDeviceKind.mouse : ui.PointerDeviceKind.touch);
      await tester.pumpAndSettle();
    }
  }
  expect(target, findsOneWidget);
}
