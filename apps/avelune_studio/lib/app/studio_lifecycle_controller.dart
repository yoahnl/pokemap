import 'dart:async';

import '../features/project_session/application/project_session_controller.dart';
import '../features/project_session/application/studio_exit_guard.dart';
import '../features/rendering/coordination/studio_rendering_preferences.dart';
import '../platform/mcp/studio_mcp_service.dart';

class StudioLifecycleController {
  StudioLifecycleController({
    required this.session,
    required this.mcp,
    required this.renderingPreferences,
    required this.exitGuard,
  });

  final ProjectSessionController session;
  final StudioMcpService mcp;
  final StudioRenderingPreferences renderingPreferences;
  final StudioExitGuard exitGuard;
  Future<void>? _starting;
  Future<void>? _closing;
  bool _creatorVisible = false;
  bool _historyMaintenanceBusy = false;
  bool _updatePrepared = false;
  bool _listening = false;

  Future<void> start() => _starting ??= _start();

  Future<void> _start() async {
    if (_closing != null) return;
    session.addListener(_synchronizeMcpProject);
    _listening = true;
    _synchronizeMcpProject();
    await Future.wait([mcp.start(), renderingPreferences.load()]);
  }

  void _synchronizeMcpProject() {
    unawaited(mcp.setProjectRoot(session.state.project?.directoryPath));
  }

  void setCreatorVisible(bool visible) => _creatorVisible = visible;

  void setHistoryMaintenanceBusy(bool busy) => _historyMaintenanceBusy = busy;

  Future<bool> _canRestart() async {
    if (_creatorVisible || _historyMaintenanceBusy) return false;
    return exitGuard.confirmLeave();
  }

  Future<bool> prepareForUpdate() async {
    if (!await _canRestart()) return false;
    await mcp.stop();
    if (mcp.state != StudioMcpState.stopped) return false;
    _updatePrepared = true;
    return true;
  }

  Future<void> resumeAfterUpdateFailure() async {
    if (!_updatePrepared || _closing != null) return;
    _updatePrepared = false;
    await mcp.start();
  }

  Future<bool> prepareForExit() async {
    if (!await _canRestart()) return false;
    await mcp.stop();
    if (mcp.state != StudioMcpState.stopped) return false;
    await session.dispose();
    return true;
  }

  Future<void> close() => _closing ??= _close();

  Future<void> _close() async {
    if (_listening) {
      session.removeListener(_synchronizeMcpProject);
      _listening = false;
    }
    await mcp.stop();
    await session.dispose();
  }
}
