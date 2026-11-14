import 'dart:typed_data';

import 'package:avelune_studio/features/rendering/contracts/map_workspace_visuals.dart';

import '../support/map_workspace_fixture.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

class SpatialTestVisuals extends WorkspaceTestVisuals
    implements SpatialWorkspaceVisuals {
  @override
  Future<Uint8List> readGroundImage(String tilesetId) async => Uint8List(0);
  @override
  Future<Uint8List> readModel(String modelId) async => Uint8List(0);
  @override
  Future<SpatialNpcPreview> spatialPreview(MapData map) async =>
      SpatialNpcPreview({}, () {});
}
