import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_image_picker.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/platform/playtest/studio_playtest_session.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_runtime/map_runtime.dart';

import '../../tool/example_project_assets.dart';
import '../support/resource_map_journey_fixture.dart';

void main() {
  testWidgets('real import decor terrain save reload and runtime journey', (
    tester,
  ) async {
    final f = (await tester.runAsync(ResourceMapJourneyFixture.create))!;
    final original = f.workspace.active!;
    final tree = f.workspace.project!.elements.singleWhere(
      (element) => element.name == 'Arbre du jardin',
    );
    expect(
      MapEditingCommands(
        original,
        f.workspace.project!,
      ).place(tree, const GridPos(x: 4, y: 4)),
      isNotNull,
    );
    expect(original.dirty, isTrue);
    final beforeResources = original.current;
    final undoBeforeResources = original.undoCount;
    late File source;
    await tester.runAsync(() async {
      source = File('${f.root.path}/source-m2.png');
      await source.writeAsBytes(exampleAtlasPng());
      await f.navigation.import(
        ResourceImageImport(
          sourcePath: source.path,
          name: 'Planche M2',
          tileWidth: 16,
          tileHeight: 16,
        ),
        intent: ResourceImportIntent.source,
      );
    });
    expect(f.navigation.error, isNull);
    final imported = f.navigation.importedSource!;
    f.navigation.edit(imported);
    final draft = f.navigation.decor!;
    draft.selection = const TilesetSourceRect(x: 2, y: 0, width: 2, height: 3);
    draft.name = 'Bosquet M2';
    for (var y = 0; y < 3; y++) {
      for (var x = 0; x < 2; x++) {
        draft.paintCollisionCell(GridPos(x: x, y: y), solid: true);
      }
    }
    expect(draft.blocked, hasLength(6));
    await tester.runAsync(() => f.navigation.saveDecor(draft.build()));
    final savedDecor = f.workspace.project!.elements.singleWhere(
      (element) => element.name == 'Bosquet M2',
    );
    expect(savedDecor.frames.single.source, draft.selection);
    expect(savedDecor.collisionProfile!.cells, unorderedEquals(draft.blocked));
    expect(f.navigation.library.selectedIdentity, 'element:${savedDecor.id}');
    expect(f.workspace.active, same(original));
    expect(original.current, same(beforeResources));
    expect(original.undoCount, undoBeforeResources);
    final commands = MapEditingCommands(original, f.workspace.project!);
    for (var instance = 0; instance < 2; instance++) {
      expect(commands.place(savedDecor, const GridPos(x: 7, y: 4)), isNotNull);
    }
    expect(
      original.current.placedElements.where(
        (entry) => entry.elementId == savedDecor.id,
      ),
      hasLength(2),
    );
    commands.reorder(forward: false);
    f.navigation.prepareTerrain(imported);
    final terrain = f.navigation.terrain!;
    for (var rule = 0; rule < 16; rule++) {
      terrain.selectedRule = rule;
      terrain.assign(rule % 10, rule ~/ 10);
    }
    expect(terrain.complete, isTrue);
    final published = await tester.runAsync(
      () => terrain.save(f.navigation.mutate, publish: true),
    );
    expect(published, isTrue, reason: terrain.error);
    f.navigation.completeTerrainPublication(terrain.publishedPreset!);
    f.paintTerrain(const GridPos(x: 4, y: 10), const GridPos(x: 12, y: 10));
    expect(original.current.layers.whereType<SmartTileLayer>(), isNotEmpty);
    final saved = await tester.runAsync(() => f.workspace.save(original));
    expect(saved, isTrue, reason: original.error);
    expect(original.dirty, isFalse);
    await tester.runAsync(() async {
      final fresh = LocalMapWorkspaceAdapter();
      final project = await fresh.loadProject(f.session);
      final loaded = await fresh.loadMap(f.session, project.maps.first);
      expect(loaded.map, original.current);
      expect(project.smartTileCatalog.presets, isNotEmpty);
      expect(
        project.elements.singleWhere((e) => e.id == savedDecor.id),
        savedDecor,
      );
      expect(await source.readAsBytes(), exampleAtlasPng());
    });
    final bundle = (await tester.runAsync(
      () => loadRuntimeMapBundle(
        projectFilePath: '${f.root.path}/project.json',
        mapId: original.current.id,
      ),
    ))!;
    expect(bundle.map, original.current);
    final game = PlayableMapGame(
      bundle: bundle,
      projectFilePath: '${f.root.path}/project.json',
      saveRepository: StudioPlaytestSession(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GameWidget<PlayableMapGame>(game: game)),
      ),
    );
    for (
      var frame = 0;
      frame < 240 &&
          (!game.isLoaded || game.debugCompletedMapActivationDispatchCount == 0);
      frame++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(game.isLoaded, isTrue);
    expect(game.debugCompletedMapActivationDispatchCount, greaterThan(0));
    expect(game.debugPlayerGridPosition, const GridPos(x: 8, y: 9));
    for (final y in [8, 7, 7]) {
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.up),
        ),
        isTrue,
      );
      game.update(.016);
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.release(RuntimeInputControl.up),
      );
      game.update(.3);
      expect(game.debugPlayerGridPosition, GridPos(x: 8, y: y));
    }
    expect(f.workspace.active, same(original));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  test(
    'large resource library finds and selects a late imported source',
    () async {
      final f = await ResourceMapJourneyFixture.create(stress: true);
      expect(f.workspace.project!.tilesets.length, greaterThan(128));
      final library = f.navigation.library;
      library.selectFamily(ResourceLibraryFamily.images);
      library.query = 'atlas tardif 132';
      final results = library.visibleItems(
        resourceCatalog(f.workspace.project!),
      );
      expect(results.single.id, 'stress-atlas-131');
      expect(library.reconcileSelection(results)!.id, 'stress-atlas-131');
      expect(library.selectedIdentity, 'tileset:stress-atlas-131');
    },
  );
}
