import 'dart:io';

import 'package:pokemap_hub/features/control/domain/avelune_control_models.dart';
import 'package:pokemap_hub/features/dashboard/application/notifiers/hub_dashboard_state.dart';
import 'package:pokemap_hub/features/session/application/services/hub_session_controller.dart';

final class AveluneControlService {
  AveluneControlService({
    required HubDashboardSnapshot Function() readDashboard,
    required HubSessionController sessionController,
    required Future<void> Function(File package) installPackage,
  }) : _readDashboard = readDashboard,
       _sessionController = sessionController,
       _installPackage = installPackage;

  final HubDashboardSnapshot Function() _readDashboard;
  final HubSessionController _sessionController;
  final Future<void> Function(File package) _installPackage;
  var _installGeneration = 0;
  var _installStatus = AveluneControlInstallStatus.idle;
  String? _installMessage;
  var _installInFlight = false;

  void observeDashboard(HubDashboardSnapshot snapshot) {
    if (snapshot.status == HubDashboardStatus.installing) {
      _installInFlight = true;
      _installStatus = AveluneControlInstallStatus.running;
      _installMessage = null;
      return;
    }
    if (!_installInFlight ||
        snapshot.status != HubDashboardStatus.ready &&
            snapshot.status != HubDashboardStatus.error) {
      return;
    }
    _installInFlight = false;
    _installGeneration += 1;
    if (snapshot.status == HubDashboardStatus.ready) {
      _installStatus = AveluneControlInstallStatus.succeeded;
      _installMessage = null;
    } else {
      _installStatus = AveluneControlInstallStatus.failed;
      _installMessage = snapshot.safeErrorMessage ?? 'Installation failed.';
    }
  }

  AveluneControlState state() {
    final dashboard = _readDashboard();
    final activeGame = _sessionController.activeGame;
    return AveluneControlState(
      dashboardStatus: dashboard.status.name,
      surface:
          activeGame == null
              ? AveluneControlSurface.hub
              : AveluneControlSurface.player,
      activeGameId: activeGame?.game.gameId,
      install: AveluneControlInstallState(
        generation: _installGeneration,
        status: _installStatus,
        message: _installMessage,
      ),
      games: <AveluneControlGame>[
        for (final view in dashboard.games)
          AveluneControlGame(
            gameId: view.game.gameId,
            title: view.game.title,
            gameVersion: view.game.current.gameVersion.toString(),
            canContinue: view.activity.canContinue,
            installationHealthy: view.activity.installationHealthy,
          ),
      ],
    );
  }

  AveluneControlState launch(String gameId) {
    final dashboard = _readDashboard();
    if (dashboard.status != HubDashboardStatus.ready) {
      throw const AveluneControlException(
        AveluneControlErrorCode.hubNotReady,
        'The Avelune Hub is not ready.',
      );
    }
    HubGameView? selected;
    for (final game in dashboard.games) {
      if (game.game.gameId == gameId) {
        selected = game;
        break;
      }
    }
    if (selected == null) {
      throw AveluneControlException(
        AveluneControlErrorCode.gameNotFound,
        'The installed game "$gameId" does not exist.',
      );
    }
    if (!selected.activity.installationHealthy) {
      throw AveluneControlException(
        AveluneControlErrorCode.gameUnavailable,
        'The installed game "$gameId" is not healthy.',
      );
    }
    _sessionController.open(selected);
    return state();
  }

  Future<AveluneControlState> install(File package) async {
    if (_readDashboard().status != HubDashboardStatus.ready) {
      throw const AveluneControlException(
        AveluneControlErrorCode.hubNotReady,
        'The Avelune Hub is not ready.',
      );
    }
    try {
      await _installPackage(package);
    } on Object {
      throw const AveluneControlException(
        AveluneControlErrorCode.installFailed,
        'Avelune could not install the package.',
      );
    }
    final result = state();
    if (result.install.status == AveluneControlInstallStatus.failed) {
      throw AveluneControlException(
        AveluneControlErrorCode.installFailed,
        result.install.message ?? 'Avelune rejected the package.',
      );
    }
    if (result.install.status != AveluneControlInstallStatus.succeeded) {
      throw const AveluneControlException(
        AveluneControlErrorCode.installFailed,
        'Avelune did not report a completed installation.',
      );
    }
    return result;
  }

  Future<AveluneControlState> returnToHub() async {
    await _sessionController.returnToHub();
    return state();
  }
}
