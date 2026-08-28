enum AveluneControlSurface { hub, player }

enum AveluneControlInstallStatus { idle, running, succeeded, failed }

enum AveluneControlErrorCode {
  hubNotReady,
  installFailed,
  gameNotFound,
  gameUnavailable,
  invalidRequest,
  unauthorized,
  methodNotAllowed,
  routeNotFound,
  internalFailure,
}

final class AveluneControlException implements Exception {
  const AveluneControlException(this.code, this.message);

  final AveluneControlErrorCode code;
  final String message;

  @override
  String toString() => '${code.name}: $message';
}

final class AveluneControlInstallState {
  const AveluneControlInstallState({
    required this.generation,
    required this.status,
    this.message,
  });

  final int generation;
  final AveluneControlInstallStatus status;
  final String? message;

  Map<String, Object?> toJson() => <String, Object?>{
    'generation': generation,
    'status': status.name,
    'message': message,
  };
}

final class AveluneControlGame {
  const AveluneControlGame({
    required this.gameId,
    required this.title,
    required this.gameVersion,
    required this.canContinue,
    required this.installationHealthy,
  });

  final String gameId;
  final String title;
  final String gameVersion;
  final bool canContinue;
  final bool installationHealthy;

  Map<String, Object?> toJson() => <String, Object?>{
    'gameId': gameId,
    'title': title,
    'gameVersion': gameVersion,
    'canContinue': canContinue,
    'installationHealthy': installationHealthy,
  };
}

final class AveluneControlState {
  AveluneControlState({
    required this.dashboardStatus,
    required this.surface,
    required this.activeGameId,
    required this.install,
    required List<AveluneControlGame> games,
  }) : games = List<AveluneControlGame>.unmodifiable(games);

  static const protocolVersion = 1;

  final String dashboardStatus;
  final AveluneControlSurface surface;
  final String? activeGameId;
  final AveluneControlInstallState install;
  final List<AveluneControlGame> games;

  Map<String, Object?> toJson() => <String, Object?>{
    'protocolVersion': protocolVersion,
    'dashboardStatus': dashboardStatus,
    'surface': surface.name,
    'activeGameId': activeGameId,
    'install': install.toJson(),
    'games': <Map<String, Object?>>[for (final game in games) game.toJson()],
  };
}
