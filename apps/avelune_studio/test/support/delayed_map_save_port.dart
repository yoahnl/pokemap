import 'dart:async';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:map_core/map_core_domain.dart';

class DelayedMapSavePort implements MapWorkspacePort {
  DelayedMapSavePort(this.delegate);
  final MapWorkspacePort delegate;
  final entered = Completer<void>();
  final release = Completer<void>();
  final finished = Completer<void>();
  @override
  Future<ProjectManifest> loadProject(ProjectSession session) =>
      delegate.loadProject(session);
  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) => delegate.loadMap(session, entry);
  @override
  Future<String> saveMap(
    ProjectSession session,
    MapWorkspaceDocument base,
    MapData current,
  ) async {
    entered.complete();
    await release.future;
    try {
      return await delegate.saveMap(session, base, current);
    } finally {
      finished.complete();
    }
  }
}
