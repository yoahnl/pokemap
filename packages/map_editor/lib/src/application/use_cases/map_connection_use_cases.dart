import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';

class ResolveMapConnectionTargetUseCase {
  ProjectMapEntry execute(
    ProjectManifest project,
    String targetMapId,
  ) {
    final normalizedTargetMapId = targetMapId.trim();
    if (normalizedTargetMapId.isEmpty) {
      throw const EditorValidationException(
        'Connected map cannot be empty',
      );
    }
    for (final mapEntry in project.maps) {
      if (mapEntry.id == normalizedTargetMapId) {
        return mapEntry;
      }
    }
    throw EditorNotFoundException(
      'Connected map not found in project: $normalizedTargetMapId',
    );
  }
}
