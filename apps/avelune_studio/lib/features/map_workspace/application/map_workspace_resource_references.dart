part of 'map_workspace_controller.dart';

extension MapWorkspaceResourceReferences on MapWorkspaceController {
  void acceptResourceMaps(Map<String, MapWorkspaceDocument> updated) {
    if (_disposed) return;
    for (final entry in updated.entries) {
      documents[entry.key]?.acceptResourceContent(entry.value);
    }
    for (final id in updated.keys) {
      _mapEpochs[id] = (_mapEpochs[id] ?? 0) + 1;
      _previews.remove(id);
      _loading.remove(id);
    }
  }
}
