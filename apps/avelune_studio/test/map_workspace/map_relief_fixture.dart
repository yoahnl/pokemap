import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_border_fixture.dart';

ProjectManifest reliefToolProject() {
  final base = spatialBorderProject();
  final raw = encodeBorderBlueprintRecordJson(
    base.borderCatalog.records.single,
    formatVersion: base.borderCatalog.formatVersion,
  );
  for (final key in ['draft', 'latestPublished']) {
    final definition = (raw[key] as Map)['definition'] as Map;
    definition['followContourDirection'] = true;
    final primitives = definition['primitives'] as List;
    for (final primitive in primitives.cast<Map>()) {
      primitive['anchorWorld'] = {'x': 0.0, 'y': 0.0, 'z': 0.0};
    }
    final corner = Map<String, Object?>.from(
      primitives.singleWhere((p) => p['role'] == 'lineCorner') as Map,
    );
    primitives.removeWhere((p) => p['role'] == 'lineCorner');
    primitives.add({...corner, 'id': 'corner-right', 'cornerTurn': 'right'});
    primitives.add({...corner, 'id': 'corner-left', 'cornerTurn': 'left'});
  }
  return base.copyWith(
    models3d: [
      for (final model in base.models3d)
        model.id == 'oak' ? _face(model, depth: -1) : model,
    ],
    borderCatalog: ProjectBorderCatalog(
      formatVersion: base.borderCatalog.formatVersion,
      records: [
        decodeBorderBlueprintRecordJson(
          raw,
          formatVersion: base.borderCatalog.formatVersion,
        ),
      ],
    ),
  );
}

ProjectManifest leftHandedReliefProject() {
  final project = reliefToolProject();
  return project.copyWith(
    models3d: [
      for (final model in project.models3d)
        model.id == 'oak' ? _face(model, depth: -1, landSide: true) : model,
    ],
  );
}

MapData reliefToolMap() {
  final map = spatialBorderMap();
  return map.copyWith(
    spatialScene: map.spatialScene!.copyWith(
      heightLevels: List.filled(map.size.width * map.size.height, 1),
    ),
  );
}

EditableMapDocument reliefDocument(MapData map) => EditableMapDocument(
  MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r0'),
);

List<String> reliefFeatures(MapData map) => [
  for (final layer in map.layers.whereType<BorderLayer>())
    for (final feature in layer.content.features)
      if (feature.materialization != null) feature.id,
];

ProjectModel3dEntry _face(
  ProjectModel3dEntry model, {
  required double depth,
  bool landSide = false,
}) => ProjectModel3dEntry(
  id: model.id,
  name: model.name,
  sourceAssetId: model.sourceAssetId,
  relativePath: model.relativePath,
  inspection: Model3dInspection(
    bounds: Model3dBounds(
      min: Model3dVector3(x: -.2, y: depth, z: landSide ? 0 : -.2),
      max: Model3dVector3(x: .2, y: 0, z: landSide ? 1 : .2),
    ),
    meshCount: 1,
    triangleCount: 1,
  ),
);
