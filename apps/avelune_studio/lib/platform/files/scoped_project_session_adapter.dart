import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../features/project_session/domain/project_session.dart';

final class ScopedProjectSessionAdapter implements ProjectSessionPort {
  const ScopedProjectSessionAdapter(
    this._delegate, {
    MethodChannel channel = const MethodChannel('map_editor/file_access'),
  }) : _channel = channel;

  final ProjectSessionPort _delegate;
  final MethodChannel _channel;

  @override
  Future<ProjectSession> open(String directoryPath) async {
    await _invoke('activateProjectDirectory', directoryPath);
    final session = await _delegate.open(directoryPath);
    await _invoke('rememberProjectDirectory', session.directoryPath);
    return session;
  }

  @override
  Future<void> close(ProjectSession session) => _delegate.close(session);

  Future<void> _invoke(String method, String path) async {
    try {
      await _channel.invokeMethod<bool>(method, {'path': path});
    } catch (error) {
      debugPrint('Studio project access $method failed: ${error.runtimeType}');
    }
  }
}
