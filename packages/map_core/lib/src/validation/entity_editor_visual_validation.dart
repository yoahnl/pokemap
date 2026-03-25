import '../exceptions/map_exceptions.dart';
import '../models/map_data.dart';
import '../models/project_manifest.dart';

void assertEntityEditorVisualAgainstProject(
  MapEntity entity,
  ProjectManifest project,
) {
  final v = entity.editorVisual;
  if (v == null) {
    return;
  }
  final id = v.elementId.trim();
  if (id.isEmpty) {
    throw ValidationException(
      'Entity ${entity.id} has editorVisual with empty elementId',
    );
  }
  final ok = project.elements.any((e) => e.id == id);
  if (!ok) {
    throw ValidationException(
      'Entity ${entity.id} editorVisual references unknown element: $id',
    );
  }
}
