import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/shadow/element_auto_shadow_backfill.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';

final class ApplyElementAutoShadowSuggestionsUseCase {
  ApplyElementAutoShadowSuggestionsUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ElementAutoShadowBackfillResult> execute(
    ProjectWorkspace workspace,
    ProjectManifest project,
  ) async {
    final result = applyElementAutoShadowSuggestionsToProject(project);
    if (result.hasChanges) {
      await _repo.saveProject(result.project, workspace.projectManifestPath);
    }
    return result;
  }
}
