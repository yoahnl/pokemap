import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_draft.dart';

final class MapWorkspaceDraft implements ProjectDraftPart {
  const MapWorkspaceDraft(this.maps);

  final MapWorkspaceController maps;

  @override
  bool get unsaved => maps.dirty;

  @override
  bool get saving => maps.saving;

  @override
  Future<bool> save() => maps.saveAll();
}
