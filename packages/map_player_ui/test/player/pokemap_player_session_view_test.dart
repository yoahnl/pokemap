import 'dart:async';
import 'dart:ui' as ui show KeyEventDeviceType;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
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

    await tester.pumpWidget(_app(_view(controller)));
    expect(_surfaceFinder(RuntimePlayerPhase.title), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('test-game-scene')), findsNothing);

    for (final phase in <RuntimePlayerPhase>[
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

      expect(
        _surfaceFinder(phase),
        findsOneWidget,
        reason: 'The ${phase.name} phase must have one canonical surface.',
      );
      expect(_allCanonicalSurfaces(), findsOneWidget);
    }
  });

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

    await tester.pumpWidget(_app(_view(controller)));
    await tester.tap(find.text('Continuer'));

    expect(controller.commands, hasLength(1));
    expect(controller.commands.single.action, RuntimePlayerAction.continueGame);
    expect(controller.commands.single.snapshotRevision, 7);

    final newGameButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Nouvelle partie'),
    );
    expect(newGameButton.onPressed, isNull);
    expect(controller.commands, hasLength(1));
  });

  testWidgets(
    'guides identity selection before dispatching New Game at 200% text scale',
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

      await tester.pumpWidget(
        _app(
          MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2),
            ),
            child: _view(
              controller,
              titlePresentation: PlayerNewGameIdentityPresentation(
                defaultName: 'Alex',
                defaultAvatarCharacterId: 'hero_a',
                avatarOptions: const <PlayerNewGameAvatarOption>[
                  PlayerNewGameAvatarOption(
                    characterId: 'hero_a',
                    label: 'Héroïne A',
                  ),
                  PlayerNewGameAvatarOption(
                    characterId: 'hero_b',
                    label: 'Héros B',
                  ),
                ],
              ),
              payloadForAction: (_) => const RuntimePlayerLoadSlot(
                profileId: 'player',
                slotId: 'slot_1',
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Nouvelle partie'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey<String>('player-new-game-identity-dialog'),
        ),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('player-identity-name')),
        'Camille',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('player-identity-avatar')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Héros B').last);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('player-identity-pronouns')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Féminins — elle').last);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('player-identity-confirm')),
      );
      await tester.pumpAndSettle();

      expect(controller.commands, hasLength(1));
      final command = controller.commands.single;
      expect(command.action, RuntimePlayerAction.newGame);
      expect(command.snapshotRevision, 9);
      final setup = command.payload! as RuntimePlayerNewGameSetup;
      expect(setup.slot.profileId, 'player');
      expect(setup.slot.slotId, 'slot_1');
      expect(setup.identity.name, 'Camille');
      expect(setup.identity.avatarCharacterId, 'hero_b');
      expect(setup.identity.pronounSet, PlayerPronounSet.feminine);
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

    await tester.pumpWidget(_app(_view(controller)));

    expect(find.text('catalogues'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator),
          )
          .value,
      .5,
    );

    await tester.tap(find.text('Annuler'));
    expect(controller.commands.single.action, RuntimePlayerAction.cancel);
    expect(controller.commands.single.snapshotRevision, 11);
  });

  testWidgets('keeps the game scene mounted only across live session phases',
      (tester) async {
    final lifecycle = _SceneLifecycle();
    final controller = _FakeRuntimePlayerCoordinator(
      _snapshot(revision: 1, phase: RuntimePlayerPhase.loadingSession),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(_view(controller, lifecycle: lifecycle)));
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

    await tester.pumpWidget(_app(_view(controller, lifecycle: lifecycle)));

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

    await tester.pumpWidget(_app(_view(controller, lifecycle: lifecycle)));

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

    await tester.pumpWidget(_app(_view(controller, lifecycle: lifecycle)));

    expect(
        find.byKey(const ValueKey<String>('test-game-scene')), findsOneWidget);
    expect(find.text('PC Pokémon'), findsOneWidget);
    expect(lifecycle.mounts, 1);
    await tester.tap(find.byKey(const ValueKey<String>('pc-close')));
    expect(controller.worldServiceCommands.single.action,
        RuntimeWorldServiceAction.close);
    expect(controller.worldServiceCommands.single.snapshotRevision, 14);
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

    await tester.pumpWidget(_app(_view(
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
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _app(
        _view(
          controller,
          touchControlsAvailable: true,
          gameplayInputRoute: (event) {
            gameplayEvents.add(event);
            return true;
          },
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('runtime-player-touch-joystick')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('runtime-player-touch-primary-button'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('runtime-player-touch-secondary-button'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('runtime-player-touch-primary-button'),
      ),
    );
    expect(
      gameplayEvents,
      const <RuntimeInputEvent>[
        RuntimeInputEvent.press(RuntimeInputControl.primary),
        RuntimeInputEvent.release(RuntimeInputControl.primary),
      ],
    );

    tester.view.physicalSize = const Size(844, 390);
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('runtime-player-touch-joystick')),
      findsOneWidget,
    );
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
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _app(
        _view(
          controller,
          touchControlsAvailable: true,
          gameplayInputRoute: (_) => true,
          gameplayInputAuthority: authority,
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('runtime-player-touch-joystick')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('runtime-player-touch-menu-open')),
      findsOneWidget,
    );

    authority.value = const RuntimeInputAuthoritySnapshot(
      context: RuntimeInputContext.battle,
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('runtime-player-touch-joystick')),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey<String>('runtime-player-touch-primary-button'),
      ),
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
      find.byKey(
        const ValueKey<String>('runtime-player-touch-primary-button'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('runtime-player-touch-menu-open')),
      findsNothing,
    );
  });

  testWidgets('renders the runtime dialogue overlay and routes a panel tap',
      (tester) async {
    final authority = ValueNotifier<RuntimeInputAuthoritySnapshot>(
      const RuntimeInputAuthoritySnapshot(
        context: RuntimeInputContext.dialogue,
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

    await tester.pumpWidget(
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
  });

  testWidgets('keeps portrait controls above the bottom thumb obstruction',
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

    await tester.pumpWidget(
      _app(
        _view(
          controller,
          touchControlsAvailable: true,
          gameplayInputRoute: (_) => true,
        ),
      ),
    );

    expect(
      tester
          .getBottomLeft(
            find.byKey(
              const ValueKey<String>('runtime-player-touch-joystick'),
            ),
          )
          .dy,
      lessThanOrEqualTo(790),
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

    await tester.pumpWidget(
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
    expect(gameplayEvents, hasLength(5));
    expect(
      gameplayEvents.skip(1),
      const <RuntimeInputEvent>[
        RuntimeInputEvent.release(RuntimeInputControl.up),
        RuntimeInputEvent.release(RuntimeInputControl.down),
        RuntimeInputEvent.release(RuntimeInputControl.left),
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

    await tester.pumpWidget(
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
        RuntimeInputEvent.release(RuntimeInputControl.up),
        RuntimeInputEvent.release(RuntimeInputControl.down),
        RuntimeInputEvent.release(RuntimeInputControl.left),
        RuntimeInputEvent.release(RuntimeInputControl.right),
      ],
    );
    expect(controller.commands, hasLength(1));
    expect(controller.commands.single.action, RuntimePlayerAction.openMenu);
    expect(controller.commands.single.snapshotRevision, 31);
  });

  testWidgets('consumes repeated Menu and plugin-owned hardware gamepad keys',
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

    await tester.pumpWidget(
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

    expect(gameplayEvents, isEmpty);
    expect(controller.commands, isEmpty);

    await tester.pumpWidget(
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
      reason:
          'Standalone embedders can opt into Flutter hardware gamepad keys.',
    );
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

    await tester.pumpWidget(
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

    inputAuthority.onKeyEvent!(
      focusNode,
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyM,
        logicalKey: LogicalKeyboardKey.keyM,
        timeStamp: Duration.zero,
      ),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(
        const ValueKey<String>('runtime-player-touch-menu-open'),
      ),
    );
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
      const <RuntimeInputEvent>[
        RuntimeInputEvent.release(RuntimeInputControl.up),
        RuntimeInputEvent.release(RuntimeInputControl.down),
        RuntimeInputEvent.release(RuntimeInputControl.left),
        RuntimeInputEvent.release(RuntimeInputControl.right),
      ],
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

PokeMapPlayerSessionView _view(
  RuntimePlayerViewController controller, {
  _SceneLifecycle? lifecycle,
  VoidCallback? onShowDiagnostics,
  bool touchControlsAvailable = false,
  PlayerGameplayInputRoute? gameplayInputRoute,
  Stream<RuntimeInputEvent>? controllerInputEvents,
  ValueListenable<RuntimeInputAuthoritySnapshot>? gameplayInputAuthority,
  ValueListenable<DialoguePresentationSnapshot?>? dialoguePresentation,
  ValueChanged<DialoguePresentationCommand>? onDialogueCommand,
  bool? controllerInputEnabled,
  PlayerNewGameIdentityPresentation? titlePresentation,
  RuntimePlayerActionPayloadBuilder? payloadForAction,
}) {
  return PokeMapPlayerSessionView(
    controller: controller,
    titlePresentation: RuntimePlayerTitlePresentation(
      author: 'Studio Test',
      description: 'Une aventure de test.',
      newGameIdentity: titlePresentation,
    ),
    payloadForAction: payloadForAction,
    gameSceneBuilder: (_) => _SceneProbe(
      key: const ValueKey<String>('test-game-scene'),
      lifecycle: lifecycle ?? _SceneLifecycle(),
    ),
    touchControlsAvailable: touchControlsAvailable,
    gameplayInputRoute: gameplayInputRoute,
    gameplayInputAuthority: gameplayInputAuthority,
    dialoguePresentation: dialoguePresentation,
    onDialogueCommand: onDialogueCommand,
    controllerInputEvents: controllerInputEvents,
    controllerInputEnabled:
        controllerInputEnabled ?? controllerInputEvents != null,
    onShowDiagnostics: onShowDiagnostics,
  );
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

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
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
