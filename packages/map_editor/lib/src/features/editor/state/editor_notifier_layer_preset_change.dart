part of 'editor_notifier.dart';

extension EditorNotifierLayerPresetChange on EditorNotifier {
  bool acceptCanonicalSmartTileLayerPresetChange({
    required String projectRootPath,
    required ProjectManifest manifest,
    required MapData map,
    required String mapRevision,
    required String layerId,
    required String receiptId,
    required String targetPresetId,
    required Map<String, String> materialMappings,
    required String statusMessage,
  }) {
    final accepted = acceptCanonicalSmartTilePublication(
      manifest: manifest,
      map: map,
      mapRevision: mapRevision,
      layerId: layerId,
      statusMessage: statusMessage,
      preservePaintTool: true,
      preserveCanonicalGestureHistory: true,
    );
    if (!accepted) return false;
    _canonicalSmartTileUndoStack.add(
      _CanonicalSmartTileHistoryEntry(
        projectRootPath: projectRootPath,
        receiptId: receiptId,
        mapId: map.id,
        layerId: layerId,
        redoActionId: 'smart_tile.layer.change_preset',
        redoParameters: Map<String, Object?>.unmodifiable(<String, Object?>{
          'mapId': map.id,
          'layerId': layerId,
          'targetPresetId': targetPresetId,
          if (materialMappings.isNotEmpty) 'materialMappings': materialMappings,
        }),
        undoStatusMessage: 'Changement de motif annulé.',
        redoStatusMessage: 'Changement de motif réappliqué.',
      ),
    );
    _canonicalSmartTileRedoStack.clear();
    _syncCanonicalSmartTileHistoryFlags();
    return true;
  }
}
