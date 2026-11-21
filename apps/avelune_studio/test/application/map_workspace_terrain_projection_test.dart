import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../map_workspace/spatial_terrain_painting_fixture.dart' show preset;
import '../support/scoped_map_workspace_port.dart';

void main() {
  test(
    'terrain publication updates the consuming projections in place',
    () async {
      final port = _TerrainPort();
      final controller = MapWorkspaceController(scopedMapSession, port);
      addTearDown(controller.dispose);
      await controller.initialize();
      final document = controller.active!;
      document.commit(document.current.copyWith(name: 'Brouillon du jardin'));
      final unsaved = document.current;
      await controller.activate(secondScopedMap);
      await controller.previewMap(firstScopedMap.id);
      for (final entry in port.metadata.maps.skip(3)) {
        await controller.activate(entry);
        await controller.previewMap(entry.id);
      }
      final unrelated = controller.previewDefinitionsFor('other-0');
      await controller.activate(firstScopedMap);
      await controller.ensureResourceKind('smartTilePreset');
      final original = controller.visualProject!;
      final builds = controller.visualProjectionBuilds;

      final pending = controller.previewMap('preview');
      await port.previewCaptured.future;
      final after = _terrain(column: 1);
      final before = controller.project!;
      controller.acceptResources(
        before,
        before.copyWith(smartTileCatalog: _catalog(after)),
        changedTerrain: after,
      );
      port.resumePreview.complete();
      await pending;

      final presets = controller.visualProject!.smartTileCatalog.presets;
      expect(presets, [after]);
      expect(controller.visualProjectionBuilds, builds);
      expect(controller.terrainWorkshopProjectionsVisited, 3);
      expect(
        controller
            .previewDefinitionsFor(firstScopedMap.id)!
            .smartTileCatalog
            .presets,
        presets,
      );
      expect(
        controller.previewDefinitionsFor('preview')!.smartTileCatalog.presets,
        presets,
      );
      expect(controller.previewDefinitionsFor('other-0'), same(unrelated));
      expect(original.smartTileCatalog.presets.single, _terrain());
      await controller.activate(secondScopedMap);
      expect(controller.project!.smartTileCatalog.presets, presets);
      await controller.activate(firstScopedMap);
      expect(controller.active, same(document));
      expect(document.current, same(unsaved));
      expect(document.dirty, isTrue);
      expect(port.selections.length, 122);
      expect(port.fullReads, 0);
    },
  );

  test('an external refresh keeps a newer terrain publication', () async {
    final port = _TerrainPort();
    final controller = MapWorkspaceController(scopedMapSession, port);
    addTearDown(controller.dispose);
    await controller.initialize();
    port.pauseSelection = true;
    final refresh = controller.acceptExternalMutation({
      (kind: 'smartTilePreset', id: preset.id),
    }, reportFailure: true);
    await port.selectionCaptured.future;
    final before = controller.project!;
    final after = _terrain(column: 2);
    controller.acceptResources(
      before,
      before.copyWith(smartTileCatalog: _catalog(after)),
      changedTerrain: after,
    );
    port.resumeSelection.complete();
    await refresh;
    expect(controller.project!.smartTileCatalog.presets, [after]);
    expect(controller.visualProject!.smartTileCatalog.presets, [after]);
  });
}

ProjectSmartTilePreset _terrain({int column = 0}) => preset.copyWith(
  status: SmartTilePresetStatus.published,
  rules: [
    SmartTileRule(
      id: 'center',
      centerMatch: const SmartTileSlotMatch.material('grass'),
      candidates: [
        SmartTileCandidate(
          id: 'center',
          parts: [
            SmartTileVisualPart(
              source: SmartTileVisualSource.frame(
                frame: SmartTileFrameRef(
                  atlasId: 'grass',
                  column: column,
                  row: 0,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);

ProjectSmartTileCatalog _catalog(ProjectSmartTilePreset terrain) =>
    ProjectSmartTileCatalog(presets: [terrain]);

final class _TerrainPort extends ScopedTestMapPort
    implements
        MapWorkspacePreviewSelectionPort,
        MapWorkspaceExternalMutationPort {
  _TerrainPort()
    : super(
        metadata: scopedMapMetadata.copyWith(
          maps: [
            firstScopedMap,
            secondScopedMap,
            const ProjectMapEntry(
              id: 'preview',
              name: 'Aperçu',
              relativePath: 'preview.json',
            ),
            for (var index = 0; index < 120; index++)
              ProjectMapEntry(
                id: 'other-$index',
                name: 'Autre $index',
                relativePath: 'other-$index.json',
              ),
          ],
        ),
        resourceDefinitions: {
          'smartTilePreset': scopedMapMetadata.copyWith(
            smartTileCatalog: _catalog(_terrain()),
          ),
        },
      );

  final previewCaptured = Completer<void>();
  final resumePreview = Completer<void>();
  final selectionCaptured = Completer<void>();
  final resumeSelection = Completer<void>();
  bool pauseSelection = false;

  @override
  Future<MapWorkspaceSelection> loadMapSelection(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    selections.add(entry.id);
    final selection = await _selection(session, entry);
    if (pauseSelection) {
      selectionCaptured.complete();
      await resumeSelection.future;
    }
    return selection;
  }

  @override
  Future<MapWorkspaceCatalog> refreshExternalBaseline(
    ProjectSession session, {
    required Set<({String kind, String id})> resources,
  }) => loadCatalog(session);

  @override
  Future<String?> readExternalMapRevision(
    ProjectSession session,
    String mapId,
  ) async => 'map-1';

  @override
  Future<MapWorkspaceSelection> loadMapPreviewSelection(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    final selection = await _selection(session, entry);
    if (entry.id == 'preview') {
      previewCaptured.complete();
      await resumePreview.future;
    }
    return selection;
  }

  Future<MapWorkspaceSelection> _selection(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async => MapWorkspaceSelection(
    document: await loadMap(session, entry),
    definitions: metadata.copyWith(
      smartTileCatalog: _catalog(
        entry.id.startsWith('other-')
            ? _terrain().copyWith(id: 'other')
            : _terrain(),
      ),
    ),
    catalogRevision: 'catalog-1',
    snapshotRevision: 'map-state-1',
  );
}
