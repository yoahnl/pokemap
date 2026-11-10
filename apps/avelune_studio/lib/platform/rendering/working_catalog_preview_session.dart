import '../../features/project_session/domain/project_session.dart';
import '../../features/resources/domain/working_catalog_port.dart';
import 'contracts/map_workspace_visuals.dart';
import 'studio_map_resources.dart';

class WorkingCatalogPreviewSession {
  WorkingCatalogPreviewSession({LoadWorkspaceVisuals? loadVisuals})
    : _loadVisuals = loadVisuals ?? StudioMapResources.load;

  final LoadWorkspaceVisuals _loadVisuals;
  MapWorkspaceVisuals? resources;
  String? error;
  int _generation = 0;
  bool _disposed = false;

  Future<void> load(ProjectSession session, WorkingCatalogDetail detail) async {
    if (_disposed) return;
    final generation = ++_generation;
    final previous = resources;
    resources = null;
    error = null;
    if (previous != null) await previous.dispose();
    if (_disposed || generation != _generation) return;
    try {
      final next = await _loadVisuals(session, detail.definitions);
      if (_disposed || generation != _generation) {
        await next.dispose();
        return;
      }
      resources = next;
    } catch (failure) {
      if (!_disposed && generation == _generation) error = '$failure';
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    final previous = resources;
    resources = null;
    if (previous != null) await previous.dispose();
  }
}
