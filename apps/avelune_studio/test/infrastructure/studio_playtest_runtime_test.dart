import 'dart:io';

import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/platform/playtest/studio_playtest_view.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_layout.dart';

import '../../tool/create_example_project.dart';

void main() {
  late StudioPlaytestControls controls;
  setUp(() => controls = StudioPlaytestControls());

  testWidgets('saved example mounts real runtime, walks, and returns', (
    tester,
  ) async {
    late Directory directory;
    late ProjectSession session;
    late ProjectManifest project;
    late MapWorkspaceDocument document;
    final port = LocalMapWorkspaceAdapter();
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp('studio_playtest_');
      await writeExampleProject(directory);
      session = ProjectSession(
        sessionId: 'native-runtime',
        name: 'Example',
        directoryPath: await directory.resolveSymbolicLinks(),
      );
      project = await port.loadProject(session);
      document = await port.loadMap(session, project.maps.first);
    });
    addTearDown(() => directory.delete(recursive: true));
    var returned = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudioPlaytestView(
            controls: controls,
            session: session,
            entry: project.maps.first,
            expectedRevision: document.revision,
            port: port,
            onClose: () => returned = true,
          ),
        ),
      ),
    );
    PlayableMapGame? game;
    for (var attempt = 0; attempt < 300; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 16));
      final finder = find.byType(GameWidget<PlayableMapGame>);
      if (finder.evaluate().isNotEmpty) {
        game = tester.widget<GameWidget<PlayableMapGame>>(finder).game;
        if (game!.isLoaded && !game.debugIsMapActivationDispatchInFlight) break;
      }
    }
    expect(game, isNotNull);
    expect(game!.isLoaded, isTrue);
    expect(game.testSpeed.value, PlaytestSpeed.normal);
    for (final speed in PlaytestSpeed.values.reversed) {
      controls.setTestSpeed(speed);
      await tester.pump();
      expect(game.testSpeed.value, speed);
      expect(
        tester
            .widget<GameWidget<PlayableMapGame>>(
              find.byType(GameWidget<PlayableMapGame>),
            )
            .focusNode!
            .hasFocus,
        isTrue,
      );
      expect(find.textContaining('Vitesse du test'), findsNothing);
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final size in const [Size(960, 810), Size(700, 620)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pump(const Duration(milliseconds: 32));
      final viewport = game.camera.viewport.size;
      game.debugPublishBattleCommandOverlaySnapshotForTest(
        _battleSnapshot(Size(viewport.x, viewport.y)),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byType(PlayerBattleOverlay), findsOneWidget);
      expect(
        find.byKey(const ValueKey('battle-hud-target-player')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('battle-hud-target-enemy')),
        findsOneWidget,
      );
      expect(
        find.text('Que doit faire Charmander ?'),
        findsOneWidget,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((text) => text.data)
            .join(' | '),
      );
      expect(find.byKey(const ValueKey('battle-entry-0')), findsOneWidget);
      final viewportRect = tester.getRect(
        find.byType(GameWidget<PlayableMapGame>),
      );
      expect(tester.getRect(find.byType(PlayerBattleOverlay)), viewportRect);
      for (final key in [
        'battle-hud-target-player',
        'battle-hud-target-enemy',
        'battle-entry-0',
      ]) {
        final rect = tester.getRect(find.byKey(ValueKey(key)));
        expect(rect.left, greaterThanOrEqualTo(viewportRect.left));
        expect(rect.top, greaterThanOrEqualTo(viewportRect.top));
        expect(rect.right, lessThanOrEqualTo(viewportRect.right));
        expect(rect.bottom, lessThanOrEqualTo(viewportRect.bottom));
      }
      final battle = tester.widget<PlayerBattleOverlay>(
        find.byType(PlayerBattleOverlay),
      );
      expect(battle.onCommand, equals(game.dispatchBattlePresentationCommand));
      game.debugPublishBattleCommandOverlaySnapshotForTest(null);
      await tester.pump();
      await tester.pump();
      expect(find.byType(PlayerBattleOverlay), findsNothing);
    }
    final pcResult = game.debugOpenPlayerServicePc();
    for (var attempt = 0; attempt < 100; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 16));
      if (find.byType(PlayerPcOverlay).evaluate().isNotEmpty) break;
    }
    expect(find.byType(PlayerPcOverlay), findsOneWidget);
    expect(game.inputAuthorityListenable.value.acceptsOverworldInput, isFalse);
    await tester.tap(find.byKey(const ValueKey('pc-close')));
    await tester.pump();
    await tester.runAsync(
      () async =>
          expect((await pcResult).status, PlayerServiceRuntimeStatus.completed),
    );
    await tester.pump();
    expect(find.byType(PlayerPcOverlay), findsNothing);
    expect(game.inputAuthorityListenable.value.acceptsOverworldInput, isTrue);
    expect(game.debugPlayerGridPosition, const GridPos(x: 8, y: 9));
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    game.update(.016);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    game.update(.3);
    expect(game.debugPlayerGridPosition, const GridPos(x: 9, y: 9));
    await tester.runAsync(controls.save);
    await tester.pump();
    expect(
      controls.status.message,
      'Test enregistré en mémoire pour cette session.',
    );
    controls.requestClose();
    expect(returned, isTrue);
    await tester.pumpWidget(const SizedBox());
    expect(game.isPaused, isTrue);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
  });
}

BattleCommandOverlaySnapshot _battleSnapshot(Size viewport) {
  final layout = BattleSceneLayout.forViewport(viewportSize: viewport);
  return BattleCommandOverlaySnapshot(
    revision: 12,
    mode: BattleCommandOverlayMode.root,
    viewportSize: viewport,
    panelRect: layout.commandPanelRect,
    enemyHud: BattleCommandOverlayHudSnapshot(
      rect: layout.enemyHudRect,
      ownerLabel: 'Heidi',
      speciesLabel: 'Pikachu',
      level: 20,
      currentHp: 45,
      maxHp: 60,
      isPlayerSide: false,
    ),
    playerHud: BattleCommandOverlayHudSnapshot(
      rect: layout.playerHudRect,
      ownerLabel: 'Yoahn',
      speciesLabel: 'Charmander',
      level: 25,
      currentHp: 55,
      maxHp: 70,
      isPlayerSide: true,
    ),
    battleLabel: 'Heidi',
    title: 'COMMANDS',
    prompt: 'Que doit faire Charmander ?',
    narrationLines: const [],
    entries: const [
      BattleCommandOverlayEntry(
        index: 0,
        kind: BattleCommandOverlayEntryKind.root,
        primaryLabel: 'Attaquer',
        secondaryLabel: '',
        enabled: true,
        selected: true,
        tone: BattleCommandOverlayEntryTone.attack,
      ),
    ],
    interactionsEnabled: true,
    canGoBack: false,
  );
}
