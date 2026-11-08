part of 'map_workspace_controller.dart';

extension MapWorkspaceResourceReferences on MapWorkspaceController {
  void acceptResourceMaps(
    Map<String, MapWorkspaceDocument> updated, {
    bool replaceContent = false,
  }) {
    if (_disposed) return;
    for (final entry in updated.entries) {
      final document = documents[entry.key];
      if (replaceContent) {
        document?.acceptCatalogContent(entry.value);
      } else {
        document?.acceptResourceContent(entry.value);
      }
    }
    for (final id in updated.keys) {
      _mapEpochs[id] = (_mapEpochs[id] ?? 0) + 1;
      _previews.remove(id);
      _loading.remove(id);
    }
  }
}
