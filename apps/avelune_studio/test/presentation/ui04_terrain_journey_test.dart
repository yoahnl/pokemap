import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/resource_map_journey_fixture.dart';
import '../support/ui04_terrain_atlas.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'source rules trial publication and map preserve the current session',
    () async {
      final f = await ResourceMapJourneyFixture.create();
      final document = f.workspace.active!;
      document.commit(
        document.current.copyWith(name: 'Travail sur carte conservé'),
      );
      final dirtyMap = document.current;
      final undoCount = document.undoCount;
      final navigation = f.navigation;
      final source = File('${f.root.path}/source-terrain-test.png');
      final sourceBytes = ui04TerrainAtlas();
      await source.writeAsBytes(sourceBytes);
      await navigation.accept(
        await f.resources.importImage(
          ResourceImageImport(
            sourcePath: source.path,
            name: 'Chemins — atlas d’essai',
            tileWidth: 24,
            tileHeight: 24,
          ),
        ),
      );
      navigation.prepareTerrain(
        resourceCatalog(f.workspace.project!).singleWhere(
          (item) => item.tileset?.name == 'Chemins — atlas d’essai',
        ),
      );
      expect(navigation.error, isNull);
      final model = navigation.terrain!;
      final id = model.draft.targetPresetId;
      void assign(int rule, int cell) {
        model.selectedRule = rule;
        model.assign(cell % 4, cell ~/ 4);
        expect(model.frameFor(rule)!.column, cell % 4);
        expect(model.frameFor(rule)!.row, cell ~/ 4);
      }

      model.rename('Chemins du jardin');
      for (var mask = 0; mask < 5; mask++) {
        assign(mask, mask * 5 % 16);
      }
      expect(await model.save(navigation.mutate), isTrue, reason: model.error);
      expect(model.dirty, isFalse);
      expect(await model.save(navigation.mutate, publish: true), isFalse);
      expect(f.workspace.project!.smartTileCatalog.presets, isEmpty);
      navigation.showLibrary();
      navigation.resumeTerrain(model.draft);
      expect(navigation.terrain, same(model));
      expect(model.assignedCount, 5);
      for (var mask = 5; mask < 16; mask++) {
        assign(mask, mask * 5 % 16);
      }
      assign(3, 0);
      model.inspect(const GridPos(x: 14, y: 2));
      expect(model.selectedRule, 3);
      assign(3, 15);
      model.undo();
      expect(model.frameFor(3)!.column, 0);
      model.redo();
      expect(model.frameFor(3)!.column, 3);
      model.clearScratch();
      model.paintLine(const GridPos(x: 3, y: 3), const GridPos(x: 12, y: 3));
      model.paintLine(const GridPos(x: 12, y: 3), const GridPos(x: 12, y: 11));
      model.paintLine(const GridPos(x: 7, y: 3), const GridPos(x: 7, y: 8));
      expect(model.scratch.length, 23);
      expect(model.complete, isTrue);
      expect(
        await model.save(navigation.mutate, publish: true),
        isTrue,
        reason: model.error,
      );
      navigation.completeTerrainPublication(model.publishedPreset!);
      expect(f.workspace.active, same(document));
      expect(document.current, same(dirtyMap));
      expect(document.undoCount, undoCount);
      expect(f.view.terrain!.id, id);
      expect(f.view.tool, StudioMapTool.terrain);
      f.paintTerrain(const GridPos(x: 4, y: 4));
      expect(document.current, isNot(same(dirtyMap)));
      document.restore(redo: false);
      expect(document.current, dirtyMap);
      expect(document.dirty, isTrue);
      expect(f.workspace.project!.smartTileCatalog.presets.single.id, id);
      f.paintTerrain(const GridPos(x: 4, y: 6), const GridPos(x: 9, y: 6));
      final firstPath = document.current;
      f.paintTerrain(const GridPos(x: 9, y: 6), const GridPos(x: 9, y: 9));
      final completePath = document.current;
      final layer = completePath.layers.whereType<SmartTileLayer>().single;
      final mapWidth = completePath.size.width;
      for (var x = 4; x <= 9; x++) {
        expect(layer.field.semanticCells[6 * mapWidth + x], isNonZero);
      }
      for (var y = 7; y <= 9; y++) {
        expect(layer.field.semanticCells[y * mapWidth + 9], isNonZero);
      }
      document.restore(redo: false);
      expect(document.current, firstPath);
      document.restore(redo: true);
      expect(document.current, completePath);
      expect(await f.workspace.save(document), isTrue, reason: document.error);
      expect(document.dirty, isFalse);
      final fresh = LocalMapWorkspaceAdapter();
      final project = await fresh.loadProject(f.session);
      final reopened = await fresh.loadMap(f.session, project.maps.first);
      expect(reopened.map, completePath);
      expect(project.smartTileCatalog.presets.single.id, id);
      expect(await source.readAsBytes(), sourceBytes);
    },
  );
}
