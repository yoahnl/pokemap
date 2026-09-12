import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets('OW007 updating one service preserves its navigation owner', (tester) async {
    final harness = _OverlayHarness();
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app);
    harness.enter(_OverlayOwner.shop);
    await tester.idle();
    await tester.pump();
    harness.hardware.add(const RuntimeInputEvent.press(RuntimeInputControl.right));
    await tester.idle();
    await tester.pump();
    harness.events.clear();
    final service = harness.controller.snapshot.worldService!;
    harness.controller.publish(_playingSnapshot(revision: 3,
      service: service.next(stage: RuntimeWorldServiceStage.applying)));
    await tester.idle();
    await tester.pump();
    expect(harness.events, isEmpty);
    harness.hardware.add(const RuntimeInputEvent.release(RuntimeInputControl.right));
    await tester.idle();
    await tester.pumpWidget(const SizedBox());
  });

  for (final owner in _OverlayOwner.values) {
    for (final touch in [true, false]) {
      testWidgets(
          'OW007 ${owner.name} releases held movement and sprint for ${touch ? 'touch' : 'controller'}',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 600));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final harness = _OverlayHarness();
        addTearDown(harness.dispose);
        await tester.pumpWidget(harness.app);
        await tester.pump();

        TestGesture? gesture;
        if (touch) {
          gesture = await tester.startGesture(const Offset(100, 400),
              kind: ui.PointerDeviceKind.touch);
          await gesture.moveBy(const Offset(50, 0));
        } else {
          harness.hardware
              .add(const RuntimeInputEvent.press(RuntimeInputControl.right));
          harness.hardware
              .add(const RuntimeInputEvent.press(RuntimeInputControl.sprint));
        }
        await tester.pump();
        expect(
            harness.events,
            unorderedEquals(const [
              RuntimeInputEvent.press(RuntimeInputControl.right),
              RuntimeInputEvent.press(RuntimeInputControl.sprint),
            ]));
        final glyph = tester
            .widget<PlayerOverworldActionCapsule>(
                find.byType(PlayerOverworldActionCapsule))
            .glyph;
        expect(glyph, touch ? isNull : 'Bouton sud');

        harness.enter(owner);
        await tester.pump();
        expect(
            harness.events.skip(2),
            unorderedEquals(const [
              RuntimeInputEvent.release(RuntimeInputControl.right),
              RuntimeInputEvent.release(RuntimeInputControl.sprint),
            ]));
        expect(find.byType(RuntimePlayerTouchControls), findsNothing);
        expect(find.byType(PlayerOverworldActionCapsule), findsNothing);
        expect(find.byKey(const ValueKey('runtime-player-touch-menu-open')),
            findsNothing);
        switch (owner) {
          case _OverlayOwner.dialogue || _OverlayOwner.choices:
            expect(find.byType(PlayerDialogueOverlay), findsOneWidget);
          case _OverlayOwner.battle:
            expect(find.byType(PlayerBattleOverlay), findsOneWidget);
          case _OverlayOwner.shop:
            expect(find.text('Boutique matrice'), findsOneWidget);
          case _OverlayOwner.healing:
            expect(find.text('Soin matrice'), findsOneWidget);
          case _OverlayOwner.pc:
            expect(find.text('PC matrice'), findsOneWidget);
          case _OverlayOwner.cinematic:
            expect(
                find.byType(RuntimePresentationFrameSurface), findsOneWidget);
        }
        if (!touch) {
          harness.repeatHeld();
          await tester.pump();
          expect(harness.events, hasLength(4));
        }

        harness.leave();
        await tester.idle();
        await tester.pump();
        final renderedRouter = tester.widget<RuntimePlayerSurfaceRouter>(
            find.byType(RuntimePlayerSurfaceRouter));
        final restoredState = {
          'renderedRevision': renderedRouter.snapshot.revision,
          'controllerRevision': harness.controller.snapshot.revision,
          'renderedPhase': renderedRouter.snapshot.phase,
          'renderedService': renderedRouter.snapshot.worldService?.request.kind,
          'controllerService':
              harness.controller.snapshot.worldService?.request.kind,
          'authority': harness.authority.value.context,
          'acceptsOverworldInput':
              harness.authority.value.acceptsOverworldInput,
          'dialogue': harness.dialogue.value?.mode,
          'battle': harness.battle.value?.mode,
          'cinematic': harness.presentation.value?.frame.cinematicId,
          'target': harness.interactions.value.primaryAction?.request.targetId,
        };
        expect(
            restoredState,
            {
              'renderedRevision': harness.controller.snapshot.revision,
              'controllerRevision': harness.controller.snapshot.revision,
              'renderedPhase': RuntimePlayerPhase.playing,
              'renderedService': null,
              'controllerService': null,
              'authority': RuntimeInputContext.overworld,
              'acceptsOverworldInput': true,
              'dialogue': null,
              'battle': null,
              'cinematic': null,
              'target': 'matrix-npc',
            },
            reason: 'State after leaving ${owner.name}');
        expect(renderedRouter.gameplayAction, isNotNull,
            reason:
                '$restoredState; source=${renderedRouter.activeInputSource}; '
                'menuEnabled=${renderedRouter.gameplayTouchMenuEnabled}');
        expect(find.byType(PlayerOverworldActionCapsule), findsOneWidget);
        expect(
            tester
                .widget<PlayerOverworldActionCapsule>(
                    find.byType(PlayerOverworldActionCapsule))
                .glyph,
            glyph);
        expect(find.byType(PlayerOverworldJoystickVisual), findsNothing);
        if (touch) {
          await gesture!.moveBy(const Offset(20, 0));
          await gesture.up();
        } else {
          harness.repeatHeld();
          harness.hardware
              .add(const RuntimeInputEvent.press(RuntimeInputControl.right));
          harness.hardware
              .add(const RuntimeInputEvent.press(RuntimeInputControl.sprint));
        }
        await tester.pump();
        expect(harness.events, hasLength(4));

        if (touch) {
          final fresh = await tester.startGesture(const Offset(100, 400),
              kind: ui.PointerDeviceKind.touch);
          await fresh.moveBy(const Offset(50, 0));
          await tester.pump();
          expect(
              harness.events.skip(4),
              unorderedEquals(const [
                RuntimeInputEvent.press(RuntimeInputControl.right),
                RuntimeInputEvent.press(RuntimeInputControl.sprint),
              ]));
          await fresh.up();
        } else {
          harness.hardware
              .add(const RuntimeInputEvent.release(RuntimeInputControl.right));
          harness.hardware
              .add(const RuntimeInputEvent.release(RuntimeInputControl.sprint));
          await tester.pump();
          expect(harness.events, hasLength(4));
          harness.hardware
              .add(const RuntimeInputEvent.press(RuntimeInputControl.right));
          harness.hardware
              .add(const RuntimeInputEvent.press(RuntimeInputControl.sprint));
          await tester.pump();
          expect(
              harness.events.skip(4),
              unorderedEquals(const [
                RuntimeInputEvent.press(RuntimeInputControl.right),
                RuntimeInputEvent.press(RuntimeInputControl.sprint),
              ]));
          harness.hardware
              .add(const RuntimeInputEvent.release(RuntimeInputControl.right));
          harness.hardware
              .add(const RuntimeInputEvent.release(RuntimeInputControl.sprint));
        }
        await tester.pump();
        expect(
            harness.events.skip(6),
            unorderedEquals(const [
              RuntimeInputEvent.release(RuntimeInputControl.right),
              RuntimeInputEvent.release(RuntimeInputControl.sprint),
            ]));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}

enum _OverlayOwner { dialogue, choices, battle, cinematic, shop, healing, pc }

final class _OverlayHarness {
  final controller = _MatrixController();
  final hardware = StreamController<RuntimeInputEvent>.broadcast();
  final controllers = ValueNotifier<Set<String>>({'matrix-pad'});
  final authority = ValueNotifier(const RuntimeInputAuthoritySnapshot(
      context: RuntimeInputContext.overworld, sprintAllowed: true));
  final dialogue = ValueNotifier<DialoguePresentationSnapshot?>(null);
  final battle = ValueNotifier<BattleCommandOverlaySnapshot?>(null);
  final presentation = ValueNotifier<RuntimePresentationFrameSnapshot?>(null);
  final interactions = ValueNotifier(RuntimeOverworldInteractionSnapshot(
      sessionId: 'matrix-session',
      mapActivationId: 'matrix-activation',
      mapId: 'matrix-map',
      primaryAction: const RuntimeOverworldInteractionAction(
          request: RuntimeOverworldInteractionRequest(
              sessionId: 'matrix-session',
              mapActivationId: 'matrix-activation',
              mapId: 'matrix-map',
              targetKind: RuntimeOverworldInteractionTargetKind.entity,
              targetId: 'matrix-npc',
              actionId: 'talk'),
          verb: RuntimeOverworldInteractionVerb.talk,
          targetCell: GridPos(x: 1, y: 1),
          targetBounds:
              PixelRect(leftPx: 32, topPx: 32, widthPx: 32, heightPx: 32))));
  final events = <RuntimeInputEvent>[];
  final viewportKey = GlobalKey();
  int _revision = 1;

  Widget get app => MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
      home: PokeMapPlayerSessionView(
          controller: controller,
          titlePresentation: const RuntimePlayerTitlePresentation(
              author: 'Test', description: 'Matrice des transitions'),
          gameSceneBuilder: (_) => SizedBox.expand(key: viewportKey),
          gameplayViewportKey: viewportKey,
          touchControlsAvailable: true,
          gameplayInputRoute: (event) {
            events.add(event);
            return true;
          },
          gameplayInputAuthority: authority,
          overworldInteractions: interactions,
          onOverworldInteraction: (_) => true,
          controllerInputEnabled: true,
          controllerInputEvents: hardware.stream,
          connectedControllerIds: controllers,
          dialoguePresentation: dialogue,
          onDialogueCommand: (_) {},
          battlePresentation: battle,
          onBattleCommand: (_) {},
          presentationFrame: presentation,
          presentationContentPort: _MatrixPresentationContent(),
          hapticFeedback: () async {}));

  void repeatHeld() {
    hardware.add(const RuntimeInputEvent.press(RuntimeInputControl.right,
        isRepeat: true));
    hardware.add(const RuntimeInputEvent.press(RuntimeInputControl.sprint,
        isRepeat: true));
  }

  void enter(_OverlayOwner owner) {
    switch (owner) {
      case _OverlayOwner.dialogue || _OverlayOwner.choices:
        dialogue.value = DialoguePresentationSnapshot(
            revision: 1,
            mode: owner == _OverlayOwner.choices
                ? DialoguePresentationMode.choices
                : DialoguePresentationMode.line,
            nodeTitle: 'matrix',
            speaker: 'Guide',
            text: 'Attendez ici.',
            fullText: 'Attendez ici.',
            isCurrentLineFullyRevealed: true,
            isLastContent: false,
            choices: owner == _OverlayOwner.choices
                ? const [
                    DialoguePresentationChoice(
                        index: 0, label: 'Continuer', selected: true)
                  ]
                : const []);
      case _OverlayOwner.battle:
        battle.value = const BattleCommandOverlaySnapshot(
            revision: 1,
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
                isPlayerSide: false),
            playerHud: BattleCommandOverlayHudSnapshot(
                rect: Rect.fromLTWH(540, 200, 240, 80),
                ownerLabel: 'Joueur',
                speciesLabel: 'Brindibou',
                level: 8,
                currentHp: 24,
                maxHp: 24,
                isPlayerSide: true),
            battleLabel: 'Combat matrice',
            title: 'Combat',
            prompt: 'Votre action ?',
            narrationLines: [],
            entries: [
              BattleCommandOverlayEntry(
                  index: 0,
                  kind: BattleCommandOverlayEntryKind.root,
                  primaryLabel: 'Attaque',
                  secondaryLabel: 'Choisir une capacité',
                  enabled: true,
                  selected: true,
                  tone: BattleCommandOverlayEntryTone.attack)
            ],
            interactionsEnabled: true,
            canGoBack: false);
      case _OverlayOwner.cinematic:
        presentation.value = RuntimePresentationFrameSnapshot(
            assetRevision: 'matrix-revision',
            frame: PresentationFrame(
                cinematicId: 'matrix-cinematic',
                timeUs: 0,
                durationUs: 1000000),
            orientation: PresentationFrameOrientation.landscape);
      case _OverlayOwner.shop || _OverlayOwner.healing || _OverlayOwner.pc:
        controller.publish(
            _playingSnapshot(revision: ++_revision, service: _service(owner)));
    }
  }

  void leave() {
    dialogue.value = null;
    battle.value = null;
    presentation.value = null;
    controller.publish(_playingSnapshot(revision: ++_revision));
  }

  Future<void> dispose() async {
    await controller.dispose();
    await hardware.close();
    controllers.dispose();
    authority.dispose();
    dialogue.dispose();
    battle.dispose();
    presentation.dispose();
    interactions.dispose();
  }
}

RuntimeWorldServiceSnapshot _service(_OverlayOwner owner) =>
    RuntimeWorldServiceSnapshot(
        revision: 2,
        request: switch (owner) {
          _OverlayOwner.shop =>
            const OpenShopService(interactionId: 'shop', shopId: 'mart'),
          _OverlayOwner.healing =>
            const OpenHealService(interactionId: 'nurse'),
          _OverlayOwner.pc =>
            const OpenPcService(interactionId: 'terminal', storageId: 'box'),
          _ => throw StateError('Expected world service'),
        },
        stage: RuntimeWorldServiceStage.active,
        content: switch (owner) {
          _OverlayOwner.shop => RuntimeShopServiceContent(
              title: 'Boutique matrice',
              message: 'Bienvenue.',
              money: 500,
              entries: const [
                RuntimeShopEntrySnapshot(
                    itemId: 'potion', label: 'Potion', unitPrice: 60)
              ],
              selectedItemId: 'potion',
              totalPrice: 60),
          _OverlayOwner.healing => RuntimeHealServiceContent(
              title: 'Soin matrice', message: 'Soigner ?', members: const []),
          _OverlayOwner.pc => RuntimePcServiceContent(
                title: 'PC matrice',
                message: 'Votre équipe.',
                selectedBoxId: 'box',
                boxes: const [
                  RuntimePcBoxSnapshot(
                      boxId: 'box', label: 'Boîte', count: 0, capacity: 30)
                ]),
          _ => throw StateError('Expected world service'),
        },
        actions: const [
          RuntimeWorldServiceActionAvailability.enabled(
              RuntimeWorldServiceAction.close)
        ]);

RuntimePlayerSnapshot _playingSnapshot(
        {int revision = 1, RuntimeWorldServiceSnapshot? service}) =>
    RuntimePlayerSnapshot(
        revision: revision,
        phase: RuntimePlayerPhase.playing,
        gameTitle: 'Matrice OW007',
        worldService: service,
        preferences: const PlayerPreferencesSnapshot(
            locale: 'fr',
            accessibility: GameSessionAccessibilityOptions(),
            showInputHints: true),
        actions: const [
          RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.openMenu)
        ]);

final class _MatrixController implements RuntimePlayerViewController {
  final _snapshots = StreamController<RuntimePlayerSnapshot>.broadcast();
  RuntimePlayerSnapshot _snapshot = _playingSnapshot();

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
          RuntimePlayerCommand command) async =>
      const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.accepted);

  @override
  Future<RuntimePlayerCommandResult> requestBack(
          {required int snapshotRevision}) async =>
      const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.accepted);

  @override
  Future<RuntimeWorldServiceCommandResult> dispatchWorldService(
          RuntimeWorldServiceCommand command) async =>
      const RuntimeWorldServiceCommandResult(
          status: RuntimeWorldServiceCommandStatus.accepted);

  Future<void> dispose() => _snapshots.close();
}

final class _MatrixPresentationContent implements PresentationFrameContentPort {
  @override
  PresentationVisualResolution resolveVisual({
    required PresentationVisualFrameClip clip,
    required PresentationFrameOrientation orientation,
  }) =>
      const PresentationVisualReady(child: SizedBox.expand());

  @override
  PresentationCaptionResolution resolveCaption({
    required PresentationCaptionFrameClip clip,
    required Locale locale,
  }) =>
      const PresentationCaptionReady(text: 'Matrice');
}
