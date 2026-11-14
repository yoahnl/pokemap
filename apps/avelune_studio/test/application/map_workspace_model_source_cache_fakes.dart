import 'dart:async';

import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:map_core/map_core.dart';

import '../support/scoped_map_workspace_port.dart';

ProjectModel3dEntry sourceModel(String id, double width) => ProjectModel3dEntry(
  id: id,
  name: id,
  sourceAssetId: '$id-source',
  relativePath: 'assets/models3d/$id.glb',
  inspection: Model3dInspection(
    bounds: Model3dBounds(
      min: Model3dVector3.zero,
      max: Model3dVector3(x: width, y: 1, z: 1),
    ),
    meshCount: 1,
    triangleCount: 1,
  ),
);

final class ModelSourcePort extends ScopedTestMapPort
    implements MapWorkspacePreviewSelectionPort {
  ModelSourcePort({int unrelatedMaps = 0})
    : super(
        metadata: ProjectManifest(
          name: 'Sources',
          maps: [
            for (final id in [
              'first',
              'second',
              'preview',
              for (var i = 0; i < unrelatedMaps; i++) 'unrelated-$i',
            ])
              ProjectMapEntry(id: id, name: id, relativePath: '$id.json'),
          ],
          tilesets: const [],
        ),
      );
  List<ProjectMapEntry> get entries => metadata.maps;
  var tree = sourceModel('tree', 1);
  final other = sourceModel('other', 2);
  final selectionReads = <String>[], previewReads = <String>[];
  Completer<void>? gate;
  Completer<void>? previewGate;

  @override
  Future<MapWorkspaceSelection> loadMapSelection(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    selectionReads.add(entry.id);
    final selection = await _selection(session, entry);
    await gate?.future;
    return selection;
  }

  Future<MapWorkspaceSelection> _selection(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async => MapWorkspaceSelection(
    document: await loadMap(session, entry),
    definitions: metadata.copyWith(
      models3d: [entry.id.startsWith('unrelated-') ? other : tree],
    ),
    catalogRevision: 'catalog-1',
    snapshotRevision: 'snapshot-1',
  );

  @override
  Future<MapWorkspaceSelection> loadMapPreviewSelection(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    previewReads.add(entry.id);
    final selection = await _selection(session, entry);
    await previewGate?.future;
    return selection;
  }

  @override
  Future<MapWorkspaceCatalog> loadResourceKind(
    ProjectSession session,
    String canonicalKind, {
    bool placeableOnly = false,
  }) async => MapWorkspaceCatalog(
    metadata: metadata.copyWith(
      models3d: [
        tree,
        other,
        for (final entry in entries.skip(3)) sourceModel(entry.id, 2),
      ],
    ),
    revision: 'catalog-1',
  );
}
