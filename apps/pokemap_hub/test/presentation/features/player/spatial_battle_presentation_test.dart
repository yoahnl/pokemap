import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

void main() {
  testWidgets(
    'spatial battles use canonical touch commands and reject stale taps',
    (tester) async {
      final fixture = (await tester.runAsync(_fixture))!;
      final runtime = SpatialBattleRuntime(
        readGameState: () => fixture.state,
        commitGameState: (expected, next) => true,
      );
      addTearDown(runtime.dispose);
      late Future<bool> completion;
      await tester.runAsync(() async {
        completion = runtime.start(
          bundle: fixture.bundle,
          request: _wild('canonical-touch'),
        );
        await _ready(runtime);
      });
      await _pump(tester, runtime);
      await _mount(tester, runtime);
      expect(find.byType(PlayerBattleOverlay), findsOneWidget);
      final root = runtime.battlePresentationListenable.value!;
      expect(root.mode, BattleCommandOverlayMode.root);

      await tester.tap(find.byKey(const ValueKey('battle-entry-0')));
      await tester.pump();
      expect(
        runtime.battlePresentationListenable.value!.mode,
        BattleCommandOverlayMode.fight,
      );
      expect(
        runtime.dispatchBattlePresentationCommand(
          BattleSelectEntryCommand(
            snapshotRevision: root.revision,
            expectedMode: root.mode,
            entryIndex: 3,
          ),
        ),
        false,
      );
      await tester.tap(find.byKey(const ValueKey('battle-back')));
      await tester.pump();
      final resumed = runtime.battlePresentationListenable.value!;
      expect(resumed.mode, BattleCommandOverlayMode.root);
      runtime.pause();
      expect(
        runtime.dispatchBattlePresentationCommand(
          BattleSelectEntryCommand(
            snapshotRevision: resumed.revision,
            expectedMode: resumed.mode,
            entryIndex: 0,
          ),
        ),
        false,
      );
      runtime.resume();
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('battle-entry-0')));
      await tester.pump();
      expect(
        runtime.battlePresentationListenable.value!.mode,
        BattleCommandOverlayMode.fight,
      );

      final oldOverlay = runtime.battleOverlay!;
      await tester.pumpWidget(const SizedBox.shrink());
      expect(await tester.runAsync(() => completion), false);
      expect(runtime.battlePresentationListenable.value, isNull);
      oldOverlay.onGameResize(oldOverlay.size);
      await tester.pump();
      expect(runtime.battlePresentationListenable.value, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a deferred frame snapshot never overwrites a newer publication',
    (tester) async {
      final fixture = (await tester.runAsync(_fixture))!;
      final runtime = SpatialBattleRuntime(
        readGameState: () => fixture.state,
        commitGameState: (expected, next) => true,
      );
      addTearDown(runtime.dispose);
      await tester.runAsync(() async {
        unawaited(
          runtime.start(bundle: fixture.bundle, request: _wild('frame-race')),
        );
        await _ready(runtime);
      });
      await _pump(tester, runtime);
      await _mount(tester, runtime);
      final revisions = <int>[];
      runtime.battlePresentationListenable.addListener(() {
        final snapshot = runtime.battlePresentationListenable.value;
        if (snapshot != null) revisions.add(snapshot.revision);
      });
      tester.binding.addPostFrameCallback((_) {
        runtime.setViewSafeAreaPadding(const EdgeInsets.only(bottom: 80));
      });
      var built = false;
      await _pump(
        tester,
        runtime,
        onBuild: () {
          if (built) return;
          built = true;
          runtime.setViewSafeAreaPadding(const EdgeInsets.only(bottom: 40));
        },
      );
      final current = runtime.battlePresentationListenable.value!;
      expect(
        current.panelRect,
        runtime.battleOverlay!.currentCommandOverlaySnapshot!.panelRect,
      );
      expect(revisions, orderedEquals([...revisions]..sort()));
      expect(
        runtime.dispatchBattlePresentationCommand(
          BattleSelectEntryCommand(
            snapshotRevision: current.revision,
            expectedMode: current.mode,
            entryIndex: 0,
          ),
        ),
        true,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('victory XP and decisions stay in the canonical battle scene', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(_victoryFixture))!;
    var state = fixture.state;
    var commits = 0;
    final runtime = SpatialBattleRuntime(
      readGameState: () => state,
      commitGameState: (expected, next) {
        if (state != expected) return false;
        state = next;
        commits++;
        return true;
      },
    );
    addTearDown(runtime.dispose);
    late Future<bool> completion;
    await tester.runAsync(() async {
      completion = runtime.start(
        bundle: fixture.bundle,
        request: _wild('scene-victory'),
      );
      await _ready(runtime);
    });
    await _pump(tester, runtime);
    await _mount(tester, runtime);
    expect(
      runtime.battlePresentationListenable.value!.playerHud.experienceProgress,
      isNotNull,
    );
    var sawXp = false;
    var decisions = 0;
    for (var i = 0; i < 1000 && runtime.isActive; i++) {
      final snapshot = runtime.battlePresentationListenable.value;
      expect(find.byType(PlayerPostBattleOverlay), findsNothing);
      if (snapshot != null && snapshot.playerHud.hasXpTween && !sawXp) {
        sawXp = true;
        expect(find.byType(PlayerBattleOverlay), findsOneWidget);
        expect(commits, 0);
        runtime.pause();
        await tester.pump(const Duration(seconds: 1));
        expect(runtime.battlePresentationListenable.value, snapshot);
        runtime.resume();
      }
      if (snapshot != null &&
          snapshot.interactionsEnabled &&
          snapshot.entries.any((entry) => entry.enabled) &&
          tester
                  .widget<PlayerBattleOverlay>(find.byType(PlayerBattleOverlay))
                  .snapshot
                  .revision ==
              snapshot.revision) {
        final index =
            snapshot.mode == BattleCommandOverlayMode.decision
                ? (snapshot.entries.length > 2 ? 1 : 0)
                : snapshot.entries.firstWhere((entry) => entry.enabled).index;
        await tester.tap(find.byKey(ValueKey('battle-entry-$index')));
        if (snapshot.mode == BattleCommandOverlayMode.decision) {
          decisions++;
          await tester.pump();
          expect(
            runtime.dispatchBattlePresentationCommand(
              BattleSelectEntryCommand(
                snapshotRevision: snapshot.revision,
                expectedMode: snapshot.mode,
                entryIndex: index,
              ),
            ),
            false,
          );
        }
      }
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1)),
      );
    }
    expect(sawXp, true);
    expect(decisions, 3);
    expect(await tester.runAsync(() => completion), true);
    expect(commits, 1);
    expect(state.party.members.first.level, greaterThan(4));
    expect(state.party.members.first.knownMoveIds, contains('vine_whip'));
    expect(state.party.members.first.speciesId, 'sparkitten');
    expect(state.playerSpatialPosition, fixture.state.playerSpatialPosition);
    expect(state.completedBattleRequestIds, contains('scene-victory'));
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('spatial result stays in scene and commits under the exit fade', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(_fixture))!;
    var state = fixture.state;
    var commits = 0;
    late final SpatialBattleRuntime runtime;
    runtime = SpatialBattleRuntime(
      readGameState: () => state,
      commitGameState: (expected, next) {
        expect(runtime.exitTransition!.isHoldingBlack, true);
        if (state != expected) return false;
        state = next;
        commits++;
        return true;
      },
    );
    addTearDown(runtime.dispose);
    late Future<bool> completion;
    await tester.runAsync(() async {
      completion = runtime.start(
        bundle: fixture.bundle,
        request: _wild('canonical-result'),
      );
      await _ready(runtime);
    });
    await _pump(tester, runtime);
    await _mount(tester, runtime);
    for (
      var i = 0;
      i < 400 && runtime.phase != SpatialBattlePhase.postBattle;
      i++
    ) {
      final snapshot = runtime.battlePresentationListenable.value;
      if (snapshot?.mode == BattleCommandOverlayMode.root &&
          snapshot!.interactionsEnabled) {
        await tester.tap(find.byKey(const ValueKey('battle-entry-3')));
      }
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1)),
      );
    }
    expect(runtime.phase, SpatialBattlePhase.postBattle);
    expect(find.byType(PlayerPostBattleOverlay), findsNothing);
    expect(find.byType(PlayerBattleOverlay), findsOneWidget);
    expect(commits, 0);
    runtime.pause();
    final paused = runtime.battlePresentationListenable.value;
    await tester.pump(const Duration(seconds: 1));
    expect(runtime.battlePresentationListenable.value, paused);
    expect(commits, 0);
    runtime.resume();
    var sawFade = false;
    for (var i = 0; i < 200 && runtime.isActive; i++) {
      final curtain = runtime.exitTransition;
      if (curtain != null && !sawFade) {
        sawFade = true;
        runtime.pause();
        final alpha = curtain.debugScreenAlpha;
        await tester.pump(const Duration(seconds: 1));
        expect(curtain.debugScreenAlpha, alpha);
        expect(commits, 0);
        runtime.resume();
      }
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1)),
      );
    }
    expect(sawFade, true);
    expect(runtime.isActive, false, reason: '${runtime.error}');
    expect(await tester.runAsync(() => completion), true);
    expect(commits, 1);
    expect(state.playerSpatialPosition, fixture.state.playerSpatialPosition);
    expect(state.completedBattleRequestIds, contains('canonical-result'));
    expect(runtime.battlePresentationListenable.value, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester,
  SpatialBattleRuntime runtime, {
  VoidCallback? onBuild,
}) => tester.pumpWidget(
  MaterialApp(
    locale: const Locale('fr'),
    supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
    localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
    theme: PokeMapPlayerTheme.dark(),
    home: Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          onBuild?.call();
          return Stack(
            fit: StackFit.expand,
            children: [
              SpatialBattleView(runtime: runtime),
              ValueListenableBuilder<BattleCommandOverlaySnapshot?>(
                valueListenable: runtime.battlePresentationListenable,
                builder:
                    (context, snapshot, _) =>
                        snapshot == null
                            ? const SizedBox.shrink()
                            : PlayerBattleOverlay(
                              snapshot: snapshot,
                              onCommand:
                                  runtime.dispatchBattlePresentationCommand,
                            ),
              ),
            ],
          );
        },
      ),
    ),
  ),
);

Future<void> _mount(WidgetTester tester, SpatialBattleRuntime runtime) async {
  for (var i = 0; i < 100 && !runtime.battleOverlay!.isMounted; i++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1)),
    );
  }
  expect(runtime.battleOverlay!.isMounted, true);
  final widget = tester.widget<GameWidget>(
    find.byWidgetPredicate((widget) => widget is GameWidget),
  );
  expect(
    (widget.game! as SpatialBattlePresentation).camera.viewport.children,
    contains(runtime.battleOverlay),
  );
  for (
    var i = 0;
    i < 600 &&
        runtime.battlePresentationListenable.value?.interactionsEnabled != true;
    i++
  ) {
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  expect(runtime.entryTransition, isNull);
  expect(runtime.phase, SpatialBattlePhase.battle);
  expect(runtime.battlePresentationListenable.value?.interactionsEnabled, true);
  await tester.pump();
  final overlay = tester.widget<PlayerBattleOverlay>(
    find.byType(PlayerBattleOverlay),
  );
  expect(overlay.snapshot.interactionsEnabled, true);
  expect(
    overlay.snapshot.revision,
    runtime.battlePresentationListenable.value!.revision,
  );
}

Future<void> _ready(SpatialBattleRuntime runtime) async {
  for (var i = 0; i < 100 && runtime.displaySession == null; i++) {
    if (!runtime.isActive) break;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(runtime.displaySession, isNotNull, reason: '${runtime.error}');
}

WildBattleStartRequest _wild(String id) => WildBattleStartRequest(
  requestId: id,
  createdAtEpochMs: 1,
  returnContext: const OverworldReturnContext(
    mapId: 'golden_field',
    playerPos: GridPos(x: 1, y: 1),
    playerFacing: Direction.east,
  ),
  mapId: 'golden_field',
  encounterSourceId: 'grass',
  encounterSourceKind: EncounterSourceKind.gameplayZone,
  tableId: 'wild',
  encounterKind: EncounterKind.walk,
  speciesId: 'sparkitten',
  level: 2,
  minLevel: 2,
  maxLevel: 2,
  weight: 1,
  playerPos: const GridPos(x: 1, y: 1),
);

Future<({RuntimeMapBundle bundle, GameState state})> _fixture() async {
  final root = p.normalize(
    p.join(
      Directory.current.path,
      '..',
      '..',
      'examples',
      'playable_runtime_host',
      'golden_battle_slice',
    ),
  );
  final bundle = await loadRuntimeMapBundle(
    projectFilePath: p.join(root, 'project.json'),
    mapId: 'golden_field',
  );
  final temporary = await Directory.systemTemp.createTemp(
    'avelune-spatial-battle-ui-',
  );
  addTearDown(() => temporary.delete(recursive: true));
  for (final file
      in Directory(root).listSync(recursive: true).whereType<File>()) {
    final target = File(
      p.join(temporary.path, p.relative(file.path, from: root)),
    );
    await target.parent.create(recursive: true);
    await file.copy(target.path);
  }
  const items = ProjectItemCatalog(
    schemaVersion: 1,
    entries: [
      ProjectItemDefinition(
        id: 'poke-ball',
        displayName: 'Poké Ball',
        pocketId: 'balls',
        capture: ProjectCaptureItemDefinition(
          rateNumerator: 255,
          rateDenominator: 1,
          allowedEncounterKinds: {EncounterKind.walk},
        ),
      ),
    ],
  );
  await File(
    p.join(temporary.path, 'items.json'),
  ).writeAsString(jsonEncode(items.toJson()));
  final evolutions = Directory(
    p.join(temporary.path, bundle.manifest.pokemon.evolutionsDir),
  );
  await evolutions.create(recursive: true);
  for (final species in ['sproutle', 'sparkitten']) {
    await File(p.join(evolutions.path, '$species.json')).writeAsString(
      jsonEncode({'schemaVersion': 1, 'speciesId': species, 'evolutions': []}),
    );
  }
  final portable = bundle.copyWith(
    projectRootDirectory: temporary.path,
    map: MapData(
      version: ProjectVersion.v9,
      id: bundle.map.id,
      name: bundle.map.name,
      size: bundle.map.size,
      spatialScene: MapSpatialScene(
        width: bundle.map.size.width,
        depth: bundle.map.size.height,
      ),
    ),
    manifest: bundle.manifest.copyWith(
      version: ProjectVersion.v9,
      settings: bundle.manifest.settings.copyWith(
        dimension: ProjectDimension.threeD,
      ),
      pokemon: bundle.manifest.pokemon.copyWith(
        catalogFiles: {
          ...bundle.manifest.pokemon.catalogFiles,
          'items': 'items.json',
        },
      ),
    ),
  );
  final save = SaveData.fromJson(
    jsonDecode(
          await File(
            p.join(root, 'runtime_host_launch_save.json'),
          ).readAsString(),
        )
        as Map<String, dynamic>,
  );
  final state = gameStateFromSaveData(
    save,
  ).copyWith(playerSpatialPosition: PlayerSpatialPosition(x: 1.25, z: 1.5));
  return (bundle: portable, state: state);
}

Future<({RuntimeMapBundle bundle, GameState state})> _victoryFixture() async {
  final fixture = await _fixture();
  final curve = PokemonExperienceCurve.fromId('medium_slow');
  final hero = fixture.state.party.members.first.copyWith(
    level: 4,
    experience: curve.totalExperienceForLevel(5) - 1,
    knownMoveIds: ['tackle', 'growl', 'scratch', 'leer'],
    currentPpByMoveId: {'tackle': 35, 'growl': 40, 'scratch': 35, 'leer': 40},
  );
  final movesFile = File(
    p.join(
      fixture.bundle.projectRootDirectory,
      fixture.bundle.manifest.pokemon.catalogFiles['moves']!,
    ),
  );
  final moves =
      jsonDecode(await movesFile.readAsString()) as Map<String, dynamic>;
  moves['entries'].add({
    ...moves['entries'][0] as Map<String, dynamic>,
    'id': 'scratch',
    'name': 'Scratch',
  });
  moves['entries'].add({
    ...moves['entries'][1] as Map<String, dynamic>,
    'id': 'leer',
    'name': 'Leer',
  });
  await movesFile.writeAsString(jsonEncode(moves));
  await File(
    p.join(
      fixture.bundle.projectRootDirectory,
      fixture.bundle.manifest.pokemon.evolutionsDir,
      'sproutle.json',
    ),
  ).writeAsString(
    jsonEncode({
      'schemaVersion': 1,
      'speciesId': 'sproutle',
      'evolutions': [
        {'method': 'level_up', 'targetSpeciesId': 'sparkitten', 'minLevel': 5},
      ],
    }),
  );
  return (
    bundle: fixture.bundle,
    state: fixture.state.copyWith(
      party: fixture.state.party.copyWith(members: [hero]),
    ),
  );
}
