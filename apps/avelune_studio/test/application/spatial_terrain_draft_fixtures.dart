import 'package:avelune_studio/features/terrains/application/terrain_draft_controller.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_environment_fixture.dart';

TerrainDraftController spatialPathDraft() {
  final project = spatialEnvironmentProject();
  return TerrainDraftController.spatial(
    manifest: project,
    model: project.models3d.single,
    id: 'grass',
  );
}

ProjectModel3dEntry spatialPathModel(
  String id, {
  String name = 'Herbe locale',
}) {
  final source = spatialEnvironmentProject().models3d.single;
  return ProjectModel3dEntry(
    id: id,
    name: name,
    sourceAssetId: '$id-source',
    relativePath: 'assets/models3d/$id.glb',
    inspection: source.inspection,
  );
}
