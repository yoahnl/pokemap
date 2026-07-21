enum GameplayRoadmapStatus {
  done,
  partial,
  todo,
}

final class GameplayRoadmapDashboardEntry {
  GameplayRoadmapDashboardEntry({
    required this.id,
    required this.title,
    required this.status,
    required Iterable<String> evidencePaths,
  }) : evidencePaths = List.unmodifiable(
          evidencePaths.toList(growable: false)..sort(),
        );

  final String id;
  final String title;
  final GameplayRoadmapStatus status;
  final List<String> evidencePaths;
}

/// Read-only projection of canonical roadmap lots and report status proposals.
final class GameplayRoadmapDashboard {
  GameplayRoadmapDashboard._(Iterable<GameplayRoadmapDashboardEntry> entries)
      : entries = List.unmodifiable(entries);

  factory GameplayRoadmapDashboard.build({
    required String roadmapMarkdown,
    required Map<String, String> gameplayReports,
  }) {
    final reportEvidence = <String, List<_ReportEvidence>>{};
    for (final entry in gameplayReports.entries) {
      final lotId = _lotIdFromReportPath(entry.key);
      if (lotId == null) continue;
      reportEvidence.putIfAbsent(lotId, () => []).add(
            _ReportEvidence(
              path: entry.key,
              proposedStatus: _proposedStatus(entry.value),
            ),
          );
    }

    final entries = <GameplayRoadmapDashboardEntry>[];
    for (final line in roadmapMarkdown.split('\n')) {
      final cells = line.split('|').map((cell) => cell.trim()).toList();
      if (cells.length < 5 || !RegExp(r'^FG-\d{3}$').hasMatch(cells[1])) {
        continue;
      }
      final id = cells[1];
      final roadmapStatus = _roadmapStatus(cells[3]);
      if (roadmapStatus == null) continue;
      final reports = reportEvidence[id] ?? const <_ReportEvidence>[];
      entries.add(
        GameplayRoadmapDashboardEntry(
          id: id,
          title: cells[2],
          status: _effectiveStatus(roadmapStatus, reports),
          evidencePaths: reports.map((report) => report.path),
        ),
      );
    }
    entries.sort((left, right) => left.id.compareTo(right.id));
    return GameplayRoadmapDashboard._(entries);
  }

  final List<GameplayRoadmapDashboardEntry> entries;

  int count(GameplayRoadmapStatus status) =>
      entries.where((entry) => entry.status == status).length;

  String get markdown {
    final buffer = StringBuffer()
      ..writeln('# Gameplay Roadmap Dashboard')
      ..writeln()
      ..writeln(
        'DONE: ${count(GameplayRoadmapStatus.done)} · '
        'PARTIAL: ${count(GameplayRoadmapStatus.partial)} · '
        'TODO: ${count(GameplayRoadmapStatus.todo)}',
      )
      ..writeln()
      ..writeln('| ID | Lot | Status | Evidence reports |')
      ..writeln('|---|---|---|---:|');
    for (final entry in entries) {
      buffer.writeln(
        '| ${entry.id} | ${_escapeCell(entry.title)} | '
        '${entry.status.name.toUpperCase()} | ${entry.evidencePaths.length} |',
      );
    }
    return buffer.toString().trimRight();
  }
}

final class _ReportEvidence {
  const _ReportEvidence({
    required this.path,
    required this.proposedStatus,
  });

  final String path;
  final GameplayRoadmapStatus? proposedStatus;
}

String? _lotIdFromReportPath(String path) {
  final match = RegExp(
    r'(?:^|/)fg_(\d{3})(?:_|\.)',
    caseSensitive: false,
  ).firstMatch(path.replaceAll('\\', '/'));
  return match == null ? null : 'FG-${match.group(1)}';
}

GameplayRoadmapStatus? _proposedStatus(String report) {
  final match = RegExp(
    r'Proposed status:\s*(?:\*\*)?(DONE|PARTIAL|TODO|BLOCKED)',
    caseSensitive: false,
  ).firstMatch(report);
  if (match == null) return null;
  return _statusFromName(match.group(1)!);
}

GameplayRoadmapStatus? _roadmapStatus(String cell) {
  for (final name in const <String>['DONE', 'PARTIAL', 'BLOCKED', 'TODO']) {
    if (cell.toUpperCase().contains(name)) return _statusFromName(name);
  }
  return null;
}

GameplayRoadmapStatus _statusFromName(String name) {
  return switch (name.toUpperCase()) {
    'DONE' => GameplayRoadmapStatus.done,
    'PARTIAL' || 'BLOCKED' => GameplayRoadmapStatus.partial,
    _ => GameplayRoadmapStatus.todo,
  };
}

GameplayRoadmapStatus _effectiveStatus(
  GameplayRoadmapStatus roadmapStatus,
  List<_ReportEvidence> reports,
) {
  final proposals = reports
      .map((report) => report.proposedStatus)
      .whereType<GameplayRoadmapStatus>()
      .toSet();
  if (proposals.isEmpty) return roadmapStatus;
  if (proposals.length > 1) return GameplayRoadmapStatus.partial;
  return proposals.single;
}

String _escapeCell(String value) =>
    value.replaceAll('|', r'\|').replaceAll('\n', ' ').trim();
