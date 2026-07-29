import 'dart:convert';

enum GameplayRoadmapEvidenceState {
  fresh,
  missing,
  stale,
  failed,
  contradictory,
}

final class GameplayRoadmapEvidenceCommand {
  const GameplayRoadmapEvidenceCommand({
    required this.command,
    required this.exitCode,
    required this.outputDigest,
  });

  final String command;
  final int exitCode;
  final String outputDigest;

  bool get succeeded => exitCode == 0;
}

/// Machine-readable proof attached to one or several canonical FG lots.
///
/// Markdown reports remain useful documentation, but only this receipt carries
/// the candidate revision and exact command outcomes needed for freshness.
final class GameplayRoadmapEvidenceReceipt {
  GameplayRoadmapEvidenceReceipt({
    required Iterable<String> lotIds,
    required Map<String, String> statusByLot,
    required this.candidateSha,
    required this.capturedAtUtc,
    required Iterable<GameplayRoadmapEvidenceCommand> commands,
    required Iterable<String> sourcePaths,
  })  : lotIds = List<String>.unmodifiable(lotIds),
        statusByLot = Map<String, String>.unmodifiable(statusByLot),
        commands = List<GameplayRoadmapEvidenceCommand>.unmodifiable(commands),
        sourcePaths = List<String>.unmodifiable(sourcePaths);

  factory GameplayRoadmapEvidenceReceipt.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Evidence receipt root must be an object.');
    }
    return GameplayRoadmapEvidenceReceipt.fromJson(decoded);
  }

  factory GameplayRoadmapEvidenceReceipt.fromJson(
    Map<String, dynamic> json,
  ) {
    if (json['schemaVersion'] != 1) {
      throw const FormatException(
        'Evidence receipt schemaVersion must be 1.',
      );
    }
    final lotIds = _stringList(json['lotIds'], 'lotIds');
    if (lotIds.isEmpty || lotIds.toSet().length != lotIds.length) {
      throw const FormatException(
        'Evidence receipt lotIds must be non-empty and unique.',
      );
    }
    for (final lotId in lotIds) {
      if (!RegExp(r'^FG-\d{3}$').hasMatch(lotId)) {
        throw FormatException('Invalid evidence lot id: $lotId.');
      }
    }

    final rawStatuses = json['statusByLot'];
    if (rawStatuses is! Map<String, dynamic>) {
      throw const FormatException('statusByLot must be an object.');
    }
    final statusByLot = <String, String>{};
    for (final lotId in lotIds) {
      final status = rawStatuses[lotId];
      if (status is! String ||
          !_supportedStatuses.contains(status.toUpperCase())) {
        throw FormatException(
          'statusByLot must define a supported status for $lotId.',
        );
      }
      statusByLot[lotId] = status.toUpperCase();
    }
    if (rawStatuses.keys.toSet().difference(lotIds.toSet()).isNotEmpty) {
      throw const FormatException(
        'statusByLot cannot contain lots absent from lotIds.',
      );
    }

    final candidateSha = _requiredString(json['candidateSha'], 'candidateSha');
    final capturedAtSource =
        _requiredString(json['capturedAtUtc'], 'capturedAtUtc');
    final capturedAt = DateTime.tryParse(capturedAtSource);
    if (capturedAt == null || !capturedAt.isUtc) {
      throw const FormatException(
        'capturedAtUtc must be an ISO-8601 UTC timestamp.',
      );
    }

    final rawCommands = json['commands'];
    if (rawCommands is! List || rawCommands.isEmpty) {
      throw const FormatException('commands must be a non-empty array.');
    }
    final commands = <GameplayRoadmapEvidenceCommand>[];
    for (final rawCommand in rawCommands) {
      if (rawCommand is! Map<String, dynamic>) {
        throw const FormatException('Each command must be an object.');
      }
      final exitCode = rawCommand['exitCode'];
      if (exitCode is! int) {
        throw const FormatException('Command exitCode must be an integer.');
      }
      commands.add(
        GameplayRoadmapEvidenceCommand(
          command: _requiredString(rawCommand['command'], 'command'),
          exitCode: exitCode,
          outputDigest: _requiredString(
            rawCommand['outputDigest'],
            'outputDigest',
          ),
        ),
      );
    }

    return GameplayRoadmapEvidenceReceipt(
      lotIds: lotIds,
      statusByLot: statusByLot,
      candidateSha: candidateSha,
      capturedAtUtc: capturedAt,
      commands: commands,
      sourcePaths: _stringList(json['sourcePaths'], 'sourcePaths'),
    );
  }

  final List<String> lotIds;
  final Map<String, String> statusByLot;
  final String candidateSha;
  final DateTime capturedAtUtc;
  final List<GameplayRoadmapEvidenceCommand> commands;
  final List<String> sourcePaths;

  bool get commandsSucceeded => commands.every((command) => command.succeeded);
}

const _supportedStatuses = <String>{
  'DONE',
  'PARTIAL',
  'BLOCKED',
  'TODO',
  'DEFERRED',
};

List<String> _stringList(Object? value, String field) {
  if (value is! List) {
    throw FormatException('$field must be an array.');
  }
  return [
    for (final item in value)
      if (item is String && item.trim().isNotEmpty)
        item.trim()
      else
        throw FormatException('$field must contain non-empty strings.'),
  ];
}

String _requiredString(Object? value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$field must be a non-empty string.');
  }
  return value.trim();
}
