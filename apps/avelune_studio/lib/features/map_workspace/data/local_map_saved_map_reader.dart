part of 'local_map_workspace_adapter.dart';

extension LocalSavedMapReader on LocalMapWorkspaceAdapter {
  Future<MapWorkspaceDocument?> readSavedMap(
    ProjectSession session,
    String mapId,
  ) async {
    final entries = _project(session).manifest.maps as ProjectMapEntries;
    final entry = entries.lookup(mapId);
    if (entry == null) return null;
    await _mapPath(session, entry);
    final bytes = await _reader.readBytes(
      projectRoot: session.directoryPath,
      relativePath: entry.relativePath,
    );
    final map = MapData.fromJson(
      Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map),
    );
    if (map.id != mapId) throw const FormatException();
    requireMapDocumentRetention(bytes, map);
    return MapWorkspaceDocument(
      map: map,
      revision: narrativeEventBytesFingerprint(bytes),
      mapId: mapId,
    );
  }
}
