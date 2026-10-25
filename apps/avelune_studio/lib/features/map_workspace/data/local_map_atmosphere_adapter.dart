part of 'local_map_workspace_adapter.dart';

extension _LocalMapAtmosphereAdapter on LocalMapWorkspaceAdapter {
  Future<LocalMapAtmosphereAuthoring> _atmosphereAuthoring(
    ProjectSession session,
  ) => _atmosphereServices.putIfAbsent(session.sessionId, () async {
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: _reader,
    );
    return LocalMapAtmosphereAuthoring(policy: policy, reader: _reader);
  });
}
