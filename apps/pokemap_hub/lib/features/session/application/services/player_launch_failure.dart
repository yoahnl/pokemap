import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';
import 'package:pokemap_hub/features/session/domain/entities/installed_game_launch_context.dart';

/// Records why a launch failed, both for the player and the diagnostics log.

final class PlayerLaunchFailure {
const PlayerLaunchFailure({
  required this.code,
  required this.details,
  required this.logPath,
});

final String code;
final String details;
final String? logPath;
}

Future<PlayerLaunchFailure> recordPlayerLaunchFailure(
  Object error,
  StackTrace stackTrace, {
  required String event,
  required InstalledGame game,
  required Directory supportRoot,
  File? diagnosticLogFile,
}) async {
  final cause = switch (error) {
    InstalledGameLaunchException(:final cause) => cause,
    _ => null,
  };
  final details = <String>[
    error.toString(),
    if (cause != null) 'Cause: $cause',
    stackTrace.toString(),
  ].join('\n');
  final logFile = diagnosticLogFile ??
      File(
        p.join(
          supportRoot.path,
          'logs',
          'hub-player.log',
        ),
      );
  String? logPath;
  try {
    await logFile.parent.create(recursive: true);
    await logFile.writeAsString(
      '${jsonEncode(<String, Object?>{
            'timestamp': DateTime.now().toUtc().toIso8601String(),
            'event': event,
            'gameId': game.gameId,
            'gameVersion': game.current.gameVersion.toString(),
            'errorType': error.runtimeType.toString(),
            'error': error.toString(),
            if (cause != null) 'cause': cause.toString(),
            'stackTrace': stackTrace.toString(),
          })}\n',
      mode: FileMode.append,
      flush: true,
    );
    logPath = logFile.path;
  } on Object {
    // The player-safe error remains available if log persistence fails.
  }
  return PlayerLaunchFailure(
    code: switch (error) {
      InstalledGameLaunchException(:final code) => code.name,
      _ => 'unexpected',
    },
    details: details,
    logPath: logPath,
  );
}
