import 'dart:convert';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/terrains/application/terrain_brush.dart';
import 'package:avelune_studio/features/terrains/application/terrain_draft_controller.dart';
import 'package:avelune_studio/features/terrains/domain/terrain_connections.dart';
import 'package:avelune_studio/features/terrains/domain/terrain_draft_compatibility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';

import 'resource_fixture.dart';

void main() {
  test(
    'draft, publish, paint, erase, save and fresh reopen use canonical resources',
    () async {
      final fixture = await ResourceFixture.create();
      addTearDown(fixture.dispose);
      final pixels = image.Image(width: 64, height: 96);
      for (var i = 0; i < 16; i++) {
        image.fillRect(
          pixels,
          x1: i % 4 * 16,
          y1: i ~/ 4 * 24,
          x2: i % 4 * 16 + 15,
          y2: i ~/ 4 * 24 + 23,
          color: image.ColorRgb8(30 + i * 12, 190 - i * 8, 60 + i * 9),
        );
      }
      await fixture.source.writeAsBytes(image.encodePng(pixels));
      final controller = MapWorkspaceController(fixture.session, fixture.maps);
      addTearDown(controller.dispose);
      await controller.initialize();
      final document = controller.active!;
      document.commit(document.current.copyWith(name: 'Carte sale conservée'));
      document.stackPosition = const GridPos(x: 1, y: 1);
      final diskMap = await fixture.mapFile.readAsBytes();
      final imported = await fixture.import();
      controller.acceptResources(imported.before, imported.manifest);
      expect(controller.active, same(document));
      expect(document.dirty, isTrue);
      expect(document.undoCount, 1);
      expect(document.stackPosition, const GridPos(x: 1, y: 1));
      final draft = TerrainDraftController(
        manifest: imported.manifest,
        atlas: terrainAtlas(imported.manifest.tilesets.single, 'bank-atlas'),
        id: 'bank',
        name: 'Berge',
      );
      Future<ProjectManifest> mutate(
        String action,
        Map<String, Object?> fields,
      ) async {
        final receipt = await fixture.resources.mutate(action, fields);
        expect(receipt.changedPaths, ['project.json']);
        controller.acceptResources(receipt.before, receipt.manifest);
        return receipt.manifest;
      }

      draft.assign(2, 1);
      expect(await draft.save(mutate), isTrue);
      expect(controller.project!.smartTileCatalog.presets, isEmpty);
      final savedDraftProject = await LocalMapWorkspaceAdapter().loadProject(
        fixture.session,
      );
      final incomplete = TerrainDraftController.resume(
        manifest: savedDraftProject,
        draft: savedDraftProject.smartTileCatalog.drafts.single,
      );
      expect(incomplete.assignedCount, 1);
      expect(incomplete.frameFor(0), draft.frameFor(0));
      expect(incomplete.dirty, isFalse);
      for (var i = 0; i < 16; i++) {
        draft.selectedRule = i;
        draft.assign(i % 4, i ~/ 4);
      }
      expect(await draft.save(mutate, publish: true), isTrue);
      final manifest = controller.project!;
      expect(await fixture.mapFile.readAsBytes(), diskMap);
      final preset = manifest.smartTileCatalog.presets.single;
      final painted = applyTerrainStroke(
        map: document.current,
        manifest: manifest,
        preset: preset,
        cells: const [GridPos(x: 1, y: 1), GridPos(x: 2, y: 1)],
      );
      document.commit(painted);
      expect(document.undoCount, 2);
      expect(_resolve(painted, manifest).ruleId, 'connection-2');
      document.restore(redo: false);
      expect(document.current.layers.whereType<SmartTileLayer>(), isEmpty);
      expect(controller.project!.smartTileCatalog.presets.single, preset);
      document.restore(redo: true);
      expect(document.current, painted);
      final erased = applyTerrainStroke(
        map: painted,
        manifest: manifest,
        preset: preset,
        cells: const [GridPos(x: 2, y: 1)],
        erase: true,
      );
      document.commit(erased);
      expect(_resolve(erased, manifest).ruleId, 'connection-0');
      expect(await controller.save(document), isTrue);
      expect(document.dirty, isFalse);
      final reader = LocalMapWorkspaceAdapter();
      final reopenedManifest = await reader.loadProject(fixture.session);
      final reopened = await reader.loadMap(
        fixture.session,
        ResourceFixture.entry,
      );
      expect(jsonEncode(reopened.map.toJson()), jsonEncode(erased.toJson()));
      expect(reopened.map.layers.whereType<SmartTileLayer>(), hasLength(1));
      expect(reopenedManifest.smartTileCatalog.presets.single, preset);
      final actual = _resolve(reopened.map, reopenedManifest);
      final expected = _resolve(erased, manifest);
      expect(
        (actual.ruleId, actual.status, actual.usedFallback, actual.transform),
        (
          expected.ruleId,
          expected.status,
          expected.usedFallback,
          expected.transform,
        ),
      );
      expect(actual.candidate, expected.candidate);
      expect(reopenedManifest.smartTileCatalog.drafts, isEmpty);
      final resumed = TerrainDraftController.resume(
        manifest: reopenedManifest,
        draft: terrainDraftForPreset(reopenedManifest, preset)!,
      );
      expect(resumed.statusLabel, 'Version publiée');
      expect(resumed.draft.sourcePresetId, preset.id);
      resumed.selectedRule = 0;
      resumed.assign(3, 2);
      final mapBeforeRepublish = await fixture.mapFile.readAsBytes();
      expect(
        await resumed.save((action, fields) async {
          if (action.endsWith('publish')) {
            throw StateError('publication indisponible');
          }
          return mutate(action, fields);
        }, publish: true),
        isFalse,
      );
      expect(
        resumed.statusLabel,
        'Brouillon enregistré ; publication non effectuée',
      );
      expect(resumed.dirty, isFalse);
      final partial = await LocalMapWorkspaceAdapter().loadProject(
        fixture.session,
      );
      expect(partial.smartTileCatalog.presets.single, preset);
      expect(partial.smartTileCatalog.drafts.single.rules, resumed.draft.rules);
      expect(await fixture.mapFile.readAsBytes(), mapBeforeRepublish);
      expect(await resumed.save(mutate, publish: true), isTrue);
      final updated = await LocalMapWorkspaceAdapter().loadProject(
        fixture.session,
      );
      expect(updated.smartTileCatalog.presets, hasLength(1));
      expect(updated.smartTileCatalog.presets.single.id, preset.id);
      expect(updated.smartTileCatalog.drafts, isEmpty);
      final secondResume = TerrainDraftController.resume(
        manifest: updated,
        draft: terrainDraftForPreset(
          updated,
          updated.smartTileCatalog.presets.single,
        )!,
      );
      expect(secondResume.frameFor(0), resumed.frameFor(0));
      expect(secondResume.draft.targetPresetId, draft.draft.targetPresetId);
      expect(await fixture.mapFile.readAsBytes(), mapBeforeRepublish);
    },
  );
}

SmartTileResolution _resolve(MapData map, ProjectManifest manifest) {
  final layer = map.layers.whereType<SmartTileLayer>().single;
  final preset = manifest.smartTileCatalog.presets.single;
  return resolveSmartTile(
    preset: preset,
    materials: manifest.smartTileCatalog.materials,
    context: smartTileCellContextForLayerCell(
      layer: layer,
      map: map,
      preset: preset,
      x: 1,
      y: 1,
    ),
    x: 1,
    y: 1,
  );
}
