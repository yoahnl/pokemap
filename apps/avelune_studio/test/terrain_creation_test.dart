import 'dart:convert';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/terrains/application/terrain_brush.dart';
import 'package:avelune_studio/features/terrains/application/terrain_draft_controller.dart';
import 'package:avelune_studio/features/terrains/domain/terrain_connections.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'support/map_workspace_fixture.dart';

const terrainSource = ProjectTilesetEntry(
  id: 'atlas',
  name: 'Berges',
  relativePath: 'atlas.png',
  source: ProjectTilesetSource.regularAtlas(
    assetId: 'image',
    pixelWidth: 78,
    pixelHeight: 110,
    tileWidth: 16,
    tileHeight: 24,
    marginX: 3,
    marginY: 4,
    spacingX: 2,
    spacingY: 2,
  ),
);

TerrainDraftController terrainDraft() => TerrainDraftController(
  manifest: workspaceProject.copyWith(tilesets: [terrainSource], elements: []),
  atlas: terrainAtlas(terrainSource, 'terrain-atlas'),
  id: 'bank',
  name: 'Berge',
);

void assignAll(TerrainDraftController draft) {
  for (var i = 0; i < 16; i++) {
    draft.selectedRule = i;
    draft.assign(i % 4, i ~/ 4);
  }
}

ProjectManifest publishFixture(TerrainDraftController draft) {
  final result = compileSmartTileAuthoringDraft(
    draft: draft.draft,
    catalog: draft.manifest.smartTileCatalog,
    manifest: draft.manifest,
  );
  expect(
    result,
    isA<SmartTileDraftCompilationSuccess>(),
    reason: result is SmartTileDraftCompilationFailure
        ? result.diagnostics.map((d) => '${d.code}: ${d.message}').join('\n')
        : null,
  );
  final compiled = result as SmartTileDraftCompilationSuccess;
  return draft.manifest.copyWith(
    smartTileCatalog: ProjectSmartTileCatalog(
      atlases: compiled.atlases,
      materials: compiled.materials,
      animations: compiled.animations,
      presets: [compiled.preset],
    ),
  );
}

void main() {
  test(
    'source respects rectangular cells, margins, spacing and exact frame pixels',
    () {
      final atlas = terrainAtlas(terrainSource, 'bank');
      expect((atlas.columns, atlas.rows), (4, 4));
      expect(
        atlas.sourceRectFor(column: 3, row: 2),
        const SmartTileSourceRect(x: 57, y: 56, width: 16, height: 24),
      );
      expect(() => atlas.sourceRectFor(column: 4, row: 0), throwsRangeError);
      expect(
        () => terrainAtlas(workspaceProject.tilesets.first, 'unsupported'),
        throwsStateError,
      );
    },
  );

  test(
    'all 16 native cardinal contexts resolve their own assigned candidate',
    () {
      final draft = terrainDraft();
      expect(draft.complete, isFalse);
      expect(
        draft.resolved.where(
          (r) => r.status == SmartTileResolutionStatus.noCandidate,
        ),
        isNotEmpty,
      );
      assignAll(draft);
      expect(draft.complete, isTrue);
      publishFixture(draft);
      for (var mask = 0; mask < 16; mask++) {
        final point = GridPos(x: 2 + mask % 4 * 4, y: 2 + mask ~/ 4 * 4);
        final result = draft.resolved[point.y * 17 + point.x];
        expect(result.status, SmartTileResolutionStatus.resolved);
        expect(result.ruleId, 'connection-$mask');
        expect(result.candidate!.id, 'piece-$mask');
        expect(result.usedFallback, isFalse);
        draft.inspect(point);
        expect(draft.selectedRule, mask);
      }
      draft.selectedRule = 15;
      draft.assign(0, 0);
      expect(draft.frameFor(15)!.column, 0);
      expect(draft.frameFor(14)!.column, 2);
    },
  );

  test(
    'scratch paint and erase update neighbor rule using canonical resolver',
    () {
      final draft = terrainDraft();
      assignAll(draft);
      const p = GridPos(x: 2, y: 2);
      expect(draft.resolved[p.y * 17 + p.x].ruleId, 'connection-0');
      draft.paint(const GridPos(x: 3, y: 2));
      expect(draft.resolved[p.y * 17 + p.x].ruleId, 'connection-2');
      draft.paint(const GridPos(x: 3, y: 2), erase: true);
      expect(draft.resolved[p.y * 17 + p.x].ruleId, 'connection-0');
    },
  );

  test(
    'incomplete draft saves through existing contract and resumes unchanged',
    () async {
      final draft = terrainDraft();
      draft.assign(2, 1);
      final actions = <String>[];
      await draft.save((action, parameters) async {
        actions.add(action);
        final roundtrip = ProjectSmartTileAuthoringDraft.fromJson(
          jsonDecode(jsonEncode(parameters['draft'])) as Map<String, dynamic>,
        );
        expect(roundtrip, draft.draft);
        return draft.manifest;
      });
      expect(actions, ['smart_tile.preset.draft.upsert']);
      expect(draft.dirty, isFalse);
      final resumed = TerrainDraftController.resume(
        manifest: draft.manifest,
        draft: draft.draft,
      );
      expect(resumed.frameFor(0), draft.frameFor(0));
      expect(
        await draft.save((_, _) async => draft.manifest, publish: true),
        isFalse,
      );
      expect(draft.error, contains('16'));
    },
  );

  test(
    'publication failure retains editable draft and never writes a map',
    () async {
      final draft = terrainDraft();
      assignAll(draft);
      final actions = <String>[];
      expect(
        await draft.save((action, parameters) async {
          actions.add(action);
          expect(parameters.containsKey('layer'), isFalse);
          expect(parameters.containsKey('mapId'), isFalse);
          if (action.endsWith('publish')) throw StateError('conflict');
          return draft.manifest;
        }, publish: true),
        isFalse,
      );
      expect(actions, [
        'smart_tile.preset.draft.upsert',
        'smart_tile.preset.publish',
      ]);
      expect(draft.complete, isTrue);
      expect(draft.error, contains('conflict'));
      expect(draft.busy, isFalse);
    },
  );

  test(
    'one brush gesture creates support, paints, undoes and reloads same resolution',
    () {
      final draft = terrainDraft();
      assignAll(draft);
      final manifest = publishFixture(draft);
      final preset = manifest.smartTileCatalog.presets.single;
      final original = workspaceMap('a');
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: original, revision: 'r1', mapId: 'a'),
      );
      final positions = [const GridPos(x: 2, y: 2), const GridPos(x: 3, y: 2)];
      document.commit(
        applyTerrainStroke(
          map: document.current,
          manifest: manifest,
          preset: preset,
          cells: positions,
        ),
      );
      expect(document.undoCount, 1);
      expect(document.current.layers.whereType<SmartTileLayer>(), hasLength(1));
      final saved = document.current;
      final loaded = MapData.fromJson(
        jsonDecode(jsonEncode(saved.toJson())) as Map<String, dynamic>,
      );
      final layer = loaded.layers.whereType<SmartTileLayer>().single;
      final result = resolveSmartTile(
        preset: preset,
        materials: manifest.smartTileCatalog.materials,
        context: smartTileCellContextForLayerCell(
          layer: layer,
          map: loaded,
          preset: preset,
          x: 2,
          y: 2,
        ),
        x: 2,
        y: 2,
      );
      expect(result.ruleId, 'connection-2');
      expect(
        smartTileSemanticCells(layer).where((value) => value != 0),
        hasLength(2),
      );
      document.restore(redo: false);
      expect(document.current, original);
      document.restore(redo: true);
      expect(document.current, saved);
      document.commit(
        applyTerrainStroke(
          map: document.current,
          manifest: manifest,
          preset: preset,
          cells: [positions.last],
          erase: true,
        ),
      );
      final erased = document.current.layers.whereType<SmartTileLayer>().single;
      expect(
        resolveSmartTile(
          preset: preset,
          materials: manifest.smartTileCatalog.materials,
          context: smartTileCellContextForLayerCell(
            layer: erased,
            map: document.current,
            preset: preset,
            x: 2,
            y: 2,
          ),
          x: 2,
          y: 2,
        ).ruleId,
        'connection-0',
      );
      expect(manifest.smartTileCatalog.presets.single, preset);
    },
  );
}
