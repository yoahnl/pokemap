import 'package:map_core/map_core_domain.dart';

import '../../project_session/domain/project_session.dart';

final class ProjectVisualsState {
  const ProjectVisualsState({
    required this.profile,
    required this.revision,
    this.receiptId,
  });
  final SpatialVisualPatch profile;
  final String revision;
  final String? receiptId;
}

abstract interface class ProjectVisualsPort {
  Future<ProjectVisualsState> loadVisuals(
    ProjectSession session, {
    ProjectMapEntry? map,
  });
  Future<ProjectVisualsState> saveVisuals(
    ProjectSession session,
    SpatialVisualPatch profile,
    String expectedRevision, {
    ProjectMapEntry? map,
  });
  Future<ProjectVisualsState> undoVisuals(
    ProjectSession session,
    String receiptId,
    String expectedRevision, {
    ProjectMapEntry? map,
  });
}
