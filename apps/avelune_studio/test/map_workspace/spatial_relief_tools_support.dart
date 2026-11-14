import 'package:avelune_studio/features/rendering/contracts/map_workspace_visuals.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

MapData reliefMap({bool raised = false}) => MapData(
  id: 'a',
  name: 'Relief',
  version: ProjectVersion.v9,
  size: const GridSize(width: 8, height: 8),
  spatialScene: MapSpatialScene(
    width: 8,
    depth: 8,
    heightLevels: [
      for (var z = 0; z < 8; z++)
        for (var x = 0; x < 8; x++)
          raised && z >= 1 && z <= 2 && x >= 2 && x <= 5 ? 1 : 0,
    ],
  ),
);

class ReliefVisuals extends WorkspaceTestVisuals
    implements SpatialWorkspaceVisuals {
  @override
  Future<Uint8List> readGroundImage(String tilesetId) async => Uint8List(0);
  @override
  Future<Uint8List> readModel(String modelId) async => Uint8List(0);
  @override
  Future<SpatialNpcPreview> spatialPreview(MapData map) async =>
      SpatialNpcPreview({}, () {});
}
