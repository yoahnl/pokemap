enum GameplayRoadmapStatus {
  done,
  partial,
  blocked,
  todo,
  deferred,
}

enum GameplayRoadmapDiagnosticCode {
  malformedCanonicalLotRow,
  duplicateCanonicalLotId,
  reportRoadmapStatusContradiction,
  conflictingReportStatuses,
}

final class GameplayRoadmapDashboardDiagnostic {
  const GameplayRoadmapDashboardDiagnostic({
    required this.code,
    required this.message,
    this.lotId,
    this.lineNumber,
  });

  final GameplayRoadmapDiagnosticCode code;
  final String message;
  final String? lotId;
  final int? lineNumber;
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
  GameplayRoadmapDashboard._({
    required Iterable<GameplayRoadmapDashboardEntry> entries,
    required Iterable<GameplayRoadmapDashboardDiagnostic> diagnostics,
  })  : entries = List.unmodifiable(entries),
        diagnostics = List.unmodifiable(diagnostics);

  factory GameplayRoadmapDashboard.build({
    required String roadmapMarkdown,
    required Map<String, String> gameplayReports,
  }) {
    final reportEvidence = <String, List<_ReportEvidence>>{};
    for (final report in gameplayReports.entries) {
      final lotId = _lotIdFromReportPath(report.key);
      if (lotId == null) continue;
      reportEvidence.putIfAbsent(lotId, () => []).add(
            _ReportEvidence(
              path: report.key,
              proposedStatus: _proposedStatus(report.value),
            ),
          );
    }

    final entries = <GameplayRoadmapDashboardEntry>[];
    final diagnostics = <GameplayRoadmapDashboardDiagnostic>[];
    final canonicalIds = <String>{};
    var insideCodeFence = false;
    final lines = roadmapMarkdown.split('\n');
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (_isCodeFence(line)) {
        insideCodeFence = !insideCodeFence;
        continue;
      }
      if (insideCodeFence) continue;

      final cells = _splitMarkdownTableRow(line);
      final candidateId = cells.length > 1 ? cells[1] : '';
      if (!candidateId.toUpperCase().startsWith('FG-')) continue;

      final lineNumber = index + 1;
      if (cells.length < 5 || !RegExp(r'^FG-\d{3}$').hasMatch(candidateId)) {
        diagnostics.add(
          GameplayRoadmapDashboardDiagnostic(
            code: GameplayRoadmapDiagnosticCode.malformedCanonicalLotRow,
            message: 'Malformed canonical gameplay lot row at line '
                '$lineNumber: ${line.trim()}',
            lotId: candidateId.isEmpty ? null : candidateId,
            lineNumber: lineNumber,
          ),
        );
        continue;
      }

      final roadmapStatus = _roadmapStatus(cells[3]);
      if (roadmapStatus == null) {
        diagnostics.add(
          GameplayRoadmapDashboardDiagnostic(
            code: GameplayRoadmapDiagnosticCode.malformedCanonicalLotRow,
            message: 'Canonical gameplay lot $candidateId has no valid status '
                'at line $lineNumber.',
            lotId: candidateId,
            lineNumber: lineNumber,
          ),
        );
        continue;
      }

      if (!canonicalIds.add(candidateId)) {
        diagnostics.add(
          GameplayRoadmapDashboardDiagnostic(
            code: GameplayRoadmapDiagnosticCode.duplicateCanonicalLotId,
            message: 'Duplicate canonical gameplay lot $candidateId at line '
                '$lineNumber.',
            lotId: candidateId,
            lineNumber: lineNumber,
          ),
        );
        continue;
      }

      final reports = reportEvidence[candidateId] ?? const <_ReportEvidence>[];
      final proposedStatuses = reports
          .map((report) => report.proposedStatus)
          .whereType<GameplayRoadmapStatus>()
          .toSet();
      if (proposedStatuses.length > 1) {
        diagnostics.add(
          GameplayRoadmapDashboardDiagnostic(
            code: GameplayRoadmapDiagnosticCode.conflictingReportStatuses,
            message: 'Gameplay reports propose conflicting statuses for '
                '$candidateId.',
            lotId: candidateId,
          ),
        );
      }
      for (final report in reports) {
        final proposedStatus = report.proposedStatus;
        if (proposedStatus == null || proposedStatus == roadmapStatus) continue;
        diagnostics.add(
          GameplayRoadmapDashboardDiagnostic(
            code:
                GameplayRoadmapDiagnosticCode.reportRoadmapStatusContradiction,
            message: '${report.path} proposes '
                '${proposedStatus.name.toUpperCase()} for $candidateId, but the '
                'canonical roadmap says ${roadmapStatus.name.toUpperCase()}.',
            lotId: candidateId,
          ),
        );
      }

      entries.add(
        GameplayRoadmapDashboardEntry(
          id: candidateId,
          title: cells[2],
          status: roadmapStatus,
          evidencePaths: reports.map((report) => report.path),
        ),
      );
    }
    entries.sort((left, right) => left.id.compareTo(right.id));
    return GameplayRoadmapDashboard._(
      entries: entries,
      diagnostics: diagnostics,
    );
  }

  final List<GameplayRoadmapDashboardEntry> entries;
  final List<GameplayRoadmapDashboardDiagnostic> diagnostics;

  bool get hasBlockingDiagnostics => diagnostics.isNotEmpty;

  int count(GameplayRoadmapStatus status) =>
      entries.where((entry) => entry.status == status).length;

  String get markdown {
    final buffer = StringBuffer()
      ..writeln('# Gameplay Roadmap Dashboard')
      ..writeln()
      ..writeln(
        'DONE: ${count(GameplayRoadmapStatus.done)} · '
        'PARTIAL: ${count(GameplayRoadmapStatus.partial)} · '
        'BLOCKED: ${count(GameplayRoadmapStatus.blocked)} · '
        'TODO: ${count(GameplayRoadmapStatus.todo)} · '
        'DEFERRED: ${count(GameplayRoadmapStatus.deferred)}',
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

bool _isCodeFence(String line) => RegExp(r'^\s*(?:`{3,}|~{3,})').hasMatch(line);

List<String> _splitMarkdownTableRow(String line) {
  final cells = <String>[];
  final cell = StringBuffer();
  for (var index = 0; index < line.length; index++) {
    final character = line[index];
    if (character == r'\' &&
        index + 1 < line.length &&
        line[index + 1] == '|') {
      cell.write('|');
      index++;
      continue;
    }
    if (character == '|') {
      cells.add(cell.toString().trim());
      cell.clear();
      continue;
    }
    cell.write(character);
  }
  cells.add(cell.toString().trim());
  return cells;
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
    r'Proposed status:\s*(?:\*\*)?'
    r'(DONE|PARTIAL|TODO|BLOCKED|DEFERRED)',
    caseSensitive: false,
  ).firstMatch(report);
  if (match == null) return null;
  return _statusFromName(match.group(1)!);
}

GameplayRoadmapStatus? _roadmapStatus(String cell) {
  final matches = RegExp(
    r'\b(DONE|PARTIAL|BLOCKED|TODO|DEFERRED)\b',
    caseSensitive: false,
  ).allMatches(cell).toList(growable: false);
  if (matches.length != 1) return null;

  final match = matches.single;
  final remainder = cell.replaceRange(match.start, match.end, '');
  if (RegExp(r'[A-Za-z0-9]').hasMatch(remainder)) return null;
  return _statusFromName(match.group(1)!);
}

GameplayRoadmapStatus _statusFromName(String name) {
  return switch (name.toUpperCase()) {
    'DONE' => GameplayRoadmapStatus.done,
    'PARTIAL' => GameplayRoadmapStatus.partial,
    'BLOCKED' => GameplayRoadmapStatus.blocked,
    'DEFERRED' => GameplayRoadmapStatus.deferred,
    _ => GameplayRoadmapStatus.todo,
  };
}

String _escapeCell(String value) =>
    value.replaceAll('|', r'\|').replaceAll('\n', ' ').trim();
