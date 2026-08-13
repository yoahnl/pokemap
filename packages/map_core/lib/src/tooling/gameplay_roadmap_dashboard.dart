import 'gameplay_roadmap_evidence.dart';

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
  malformedEvidenceReceipt,
  evidenceReceiptUnknownLot,
  evidenceStatusContradiction,
  conflictingEvidenceReceipts,
  staleEvidenceReceipt,
  failedEvidenceCommand,
  missingFreshEvidence,
}

enum GameplayRoadmapDiagnosticSeverity { warning, error }

final class GameplayRoadmapDashboardDiagnostic {
  const GameplayRoadmapDashboardDiagnostic({
    required this.code,
    required this.message,
    this.severity = GameplayRoadmapDiagnosticSeverity.error,
    this.lotId,
    this.lineNumber,
  });

  final GameplayRoadmapDiagnosticCode code;
  final String message;
  final GameplayRoadmapDiagnosticSeverity severity;
  final String? lotId;
  final int? lineNumber;
}

final class GameplayRoadmapDashboardEntry {
  GameplayRoadmapDashboardEntry({
    required this.id,
    required this.title,
    required this.status,
    required Iterable<String> evidencePaths,
    required Iterable<String> structuredEvidencePaths,
    required Iterable<String> structuredEvidenceCandidateShas,
    required Iterable<String> structuredEvidenceCommands,
    required Iterable<String> structuredEvidenceSourcePaths,
    required this.evidenceState,
  })  : evidencePaths = List.unmodifiable(
          evidencePaths.toList(growable: false)..sort(),
        ),
        structuredEvidencePaths = List.unmodifiable(
          structuredEvidencePaths.toList(growable: false)..sort(),
        ),
        structuredEvidenceCandidateShas = List.unmodifiable(
          structuredEvidenceCandidateShas.toSet().toList(growable: false)
            ..sort(),
        ),
        structuredEvidenceCommands = List.unmodifiable(
          structuredEvidenceCommands.toSet().toList(growable: false)..sort(),
        ),
        structuredEvidenceSourcePaths = List.unmodifiable(
          structuredEvidenceSourcePaths.toSet().toList(growable: false)..sort(),
        );

  final String id;
  final String title;
  final GameplayRoadmapStatus status;
  final List<String> evidencePaths;
  final List<String> structuredEvidencePaths;
  final List<String> structuredEvidenceCandidateShas;
  final List<String> structuredEvidenceCommands;
  final List<String> structuredEvidenceSourcePaths;
  final GameplayRoadmapEvidenceState evidenceState;
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
    Map<String, String> structuredEvidenceReceipts = const {},
    String? candidateSha,
    bool requireFreshEvidence = false,
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

    final diagnostics = <GameplayRoadmapDashboardDiagnostic>[];
    final receiptEvidence = <String, List<_StructuredReceiptEvidence>>{};
    for (final source in structuredEvidenceReceipts.entries) {
      try {
        final receipt =
            GameplayRoadmapEvidenceReceipt.fromJsonString(source.value);
        for (final lotId in receipt.lotIds) {
          receiptEvidence.putIfAbsent(lotId, () => []).add(
                _StructuredReceiptEvidence(
                  path: source.key,
                  receipt: receipt,
                ),
              );
        }
      } on Object catch (error) {
        diagnostics.add(
          GameplayRoadmapDashboardDiagnostic(
            code: GameplayRoadmapDiagnosticCode.malformedEvidenceReceipt,
            message: '${source.key} is not a valid FG evidence receipt: $error',
          ),
        );
      }
    }

    final parsedLots = <_ParsedCanonicalLot>[];
    final canonicalIds = <String>{};
    var insideCodeFence = false;
    var insideFgSummaryTable = false;
    final lines = roadmapMarkdown.split('\n');
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (_isCodeFence(line)) {
        insideFgSummaryTable = false;
        insideCodeFence = !insideCodeFence;
        continue;
      }
      if (insideCodeFence) continue;

      final cells = _splitMarkdownTableRow(line);
      final candidateId = cells.length > 1 ? cells[1] : '';
      final nextLine = index + 1 < lines.length ? lines[index + 1] : null;
      if (_isFgSummaryTableHeader(cells, nextLine)) {
        insideFgSummaryTable = true;
        continue;
      }
      if (insideFgSummaryTable) {
        if (_isFgSummaryTableRow(cells)) {
          continue;
        }
        insideFgSummaryTable = false;
      }
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

      parsedLots.add(
        _ParsedCanonicalLot(
          id: candidateId,
          title: cells[2],
          status: roadmapStatus,
        ),
      );
    }

    for (final lotId in receiptEvidence.keys) {
      if (canonicalIds.contains(lotId)) continue;
      diagnostics.add(
        GameplayRoadmapDashboardDiagnostic(
          code: GameplayRoadmapDiagnosticCode.evidenceReceiptUnknownLot,
          message: 'Structured evidence references unknown lot $lotId.',
          lotId: lotId,
        ),
      );
    }

    final entries = <GameplayRoadmapDashboardEntry>[];
    for (final lot in parsedLots) {
      final candidateId = lot.id;
      final roadmapStatus = lot.status;
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

      final receipts =
          receiptEvidence[candidateId] ?? const <_StructuredReceiptEvidence>[];
      final evidenceState = _diagnoseStructuredEvidence(
        lot: lot,
        receipts: receipts,
        candidateSha: candidateSha,
        requireFreshEvidence: requireFreshEvidence,
        diagnostics: diagnostics,
      );
      entries.add(
        GameplayRoadmapDashboardEntry(
          id: candidateId,
          title: lot.title,
          status: roadmapStatus,
          evidencePaths: reports.map((report) => report.path),
          structuredEvidencePaths: receipts.map((receipt) => receipt.path),
          structuredEvidenceCandidateShas:
              receipts.map((receipt) => receipt.receipt.candidateSha),
          structuredEvidenceCommands: receipts.expand(
            (receipt) => receipt.receipt.commands.map(
              (command) => '${command.command} (exit ${command.exitCode}, '
                  '${command.outputDigest})',
            ),
          ),
          structuredEvidenceSourcePaths:
              receipts.expand((receipt) => receipt.receipt.sourcePaths),
          evidenceState: evidenceState,
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

  bool get hasBlockingDiagnostics => diagnostics.any(
        (diagnostic) =>
            diagnostic.severity == GameplayRoadmapDiagnosticSeverity.error,
      );

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
      ..writeln(
        '| ID | Lot | Status | Evidence | Receipts / reports | '
        'Covered paths | Candidate | Commands | Freshness |',
      )
      ..writeln('|---|---|---|---:|---|---|---|---|---|');
    for (final entry in entries) {
      final sources = [
        ...entry.evidencePaths,
        ...entry.structuredEvidencePaths,
      ];
      buffer.writeln(
        '| ${entry.id} | ${_escapeCell(entry.title)} | '
        '${entry.status.name.toUpperCase()} | '
        '${entry.evidencePaths.length + entry.structuredEvidencePaths.length} | '
        '${_escapeCell(sources.isEmpty ? '—' : sources.join('<br>'))} | '
        '${_escapeCell(entry.structuredEvidenceSourcePaths.isEmpty ? '—' : entry.structuredEvidenceSourcePaths.join('<br>'))} | '
        '${_escapeCell(entry.structuredEvidenceCandidateShas.isEmpty ? '—' : entry.structuredEvidenceCandidateShas.join('<br>'))} | '
        '${_escapeCell(entry.structuredEvidenceCommands.isEmpty ? '—' : entry.structuredEvidenceCommands.join('<br>'))} | '
        '${entry.evidenceState.name.toUpperCase()} |',
      );
    }
    return buffer.toString().trimRight();
  }
}

final class _ParsedCanonicalLot {
  const _ParsedCanonicalLot({
    required this.id,
    required this.title,
    required this.status,
  });

  final String id;
  final String title;
  final GameplayRoadmapStatus status;
}

final class _StructuredReceiptEvidence {
  const _StructuredReceiptEvidence({
    required this.path,
    required this.receipt,
  });

  final String path;
  final GameplayRoadmapEvidenceReceipt receipt;
}

final class _ReportEvidence {
  const _ReportEvidence({
    required this.path,
    required this.proposedStatus,
  });

  final String path;
  final GameplayRoadmapStatus? proposedStatus;
}

GameplayRoadmapEvidenceState _diagnoseStructuredEvidence({
  required _ParsedCanonicalLot lot,
  required List<_StructuredReceiptEvidence> receipts,
  required String? candidateSha,
  required bool requireFreshEvidence,
  required List<GameplayRoadmapDashboardDiagnostic> diagnostics,
}) {
  if (receipts.isEmpty) {
    if (lot.status == GameplayRoadmapStatus.done && candidateSha != null) {
      diagnostics.add(
        GameplayRoadmapDashboardDiagnostic(
          code: GameplayRoadmapDiagnosticCode.missingFreshEvidence,
          severity: requireFreshEvidence
              ? GameplayRoadmapDiagnosticSeverity.error
              : GameplayRoadmapDiagnosticSeverity.warning,
          message: '${lot.id} is DONE but has no structured evidence receipt '
              'for candidate $candidateSha.',
          lotId: lot.id,
        ),
      );
    }
    return GameplayRoadmapEvidenceState.missing;
  }

  final candidateReceipts = candidateSha == null
      ? receipts
      : receipts
          .where((evidence) => evidence.receipt.candidateSha == candidateSha)
          .toList(growable: false);
  final staleReceipts = candidateSha == null
      ? const <_StructuredReceiptEvidence>[]
      : receipts
          .where((evidence) => evidence.receipt.candidateSha != candidateSha)
          .toList(growable: false);
  for (final evidence in staleReceipts) {
    diagnostics.add(
      GameplayRoadmapDashboardDiagnostic(
        code: GameplayRoadmapDiagnosticCode.staleEvidenceReceipt,
        severity: GameplayRoadmapDiagnosticSeverity.warning,
        message: '${evidence.path} proves '
            '${evidence.receipt.candidateSha}, not candidate $candidateSha.',
        lotId: lot.id,
      ),
    );
  }
  if (candidateReceipts.isEmpty) {
    if (lot.status == GameplayRoadmapStatus.done && candidateSha != null) {
      diagnostics.add(
        GameplayRoadmapDashboardDiagnostic(
          code: GameplayRoadmapDiagnosticCode.missingFreshEvidence,
          severity: requireFreshEvidence
              ? GameplayRoadmapDiagnosticSeverity.error
              : GameplayRoadmapDiagnosticSeverity.warning,
          message: '${lot.id} is DONE without a successful receipt for '
              'candidate $candidateSha.',
          lotId: lot.id,
        ),
      );
    }
    return staleReceipts.isEmpty
        ? GameplayRoadmapEvidenceState.missing
        : GameplayRoadmapEvidenceState.stale;
  }

  // Historical receipts document older candidates. They must not contradict
  // or poison evidence for the exact candidate currently being certified.
  final statuses = {
    for (final evidence in candidateReceipts)
      evidence.receipt.statusByLot[lot.id]!,
  };
  if (statuses.length > 1) {
    diagnostics.add(
      GameplayRoadmapDashboardDiagnostic(
        code: GameplayRoadmapDiagnosticCode.conflictingEvidenceReceipts,
        message: 'Structured receipts propose conflicting statuses for '
            '${lot.id}: ${statuses.join(', ')}.',
        lotId: lot.id,
      ),
    );
    return GameplayRoadmapEvidenceState.contradictory;
  }

  final expectedStatus = lot.status.name.toUpperCase();
  final fresh = <_StructuredReceiptEvidence>[];
  var sawFailed = false;
  for (final evidence in candidateReceipts) {
    final receipt = evidence.receipt;
    if (!receipt.commandsSucceeded) {
      sawFailed = true;
      diagnostics.add(
        GameplayRoadmapDashboardDiagnostic(
          code: GameplayRoadmapDiagnosticCode.failedEvidenceCommand,
          message: '${evidence.path} contains a failed command for ${lot.id}.',
          lotId: lot.id,
        ),
      );
      continue;
    }
    if (receipt.statusByLot[lot.id] != expectedStatus) {
      diagnostics.add(
        GameplayRoadmapDashboardDiagnostic(
          code: GameplayRoadmapDiagnosticCode.evidenceStatusContradiction,
          message: '${evidence.path} proves '
              '${receipt.statusByLot[lot.id]} for ${lot.id}, but the roadmap '
              'says $expectedStatus.',
          lotId: lot.id,
        ),
      );
      continue;
    }
    fresh.add(evidence);
  }

  if (fresh.isNotEmpty) return GameplayRoadmapEvidenceState.fresh;
  if (lot.status == GameplayRoadmapStatus.done && candidateSha != null) {
    diagnostics.add(
      GameplayRoadmapDashboardDiagnostic(
        code: GameplayRoadmapDiagnosticCode.missingFreshEvidence,
        severity: requireFreshEvidence
            ? GameplayRoadmapDiagnosticSeverity.error
            : GameplayRoadmapDiagnosticSeverity.warning,
        message: '${lot.id} is DONE without a successful receipt for '
            'candidate $candidateSha.',
        lotId: lot.id,
      ),
    );
  }
  if (sawFailed) return GameplayRoadmapEvidenceState.failed;
  if (staleReceipts.isNotEmpty) {
    return GameplayRoadmapEvidenceState.stale;
  }
  return GameplayRoadmapEvidenceState.contradictory;
}

bool _isCodeFence(String line) => RegExp(r'^\s*(?:`{3,}|~{3,})').hasMatch(line);

bool _isFgSummaryTableRow(List<String> cells) =>
    cells.length == 5 && cells.first.isEmpty && cells.last.isEmpty;

bool _isFgSummaryTableHeader(List<String> cells, String? nextLine) {
  if (nextLine == null ||
      cells.length != 5 ||
      cells.first.isNotEmpty ||
      cells.last.isNotEmpty ||
      cells[1].toUpperCase() != 'FG' ||
      !cells[2].toLowerCase().startsWith('statut') ||
      !cells[3].toLowerCase().startsWith('preuve')) {
    return false;
  }

  final dividerCells = _splitMarkdownTableRow(nextLine);
  return dividerCells.length == cells.length &&
      dividerCells.first.isEmpty &&
      dividerCells.last.isEmpty &&
      dividerCells
          .skip(1)
          .take(dividerCells.length - 2)
          .every((cell) => RegExp(r'^:?-{3,}:?$').hasMatch(cell));
}

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
