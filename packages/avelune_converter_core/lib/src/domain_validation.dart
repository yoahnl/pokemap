part of '../avelune_converter_core.dart';

void _unique(Iterable<Object?> values, String path) {
  final seen = <Object?>{};
  var i = 0;
  for (final value in values) {
    if (!seen.add(value)) {
      throw ContractError(
          'domain.duplicate', '$path[$i]', 'Duplicate identity $value');
    }
    i++;
  }
}

void _require(bool condition, String code, String path, String message) {
  if (!condition) {
    throw ContractError(code, path, message);
  }
}

void _relativePath(String value, String path, {bool singleSegment = false}) {
  final segments = value.split('/');
  _require(
      value.isNotEmpty &&
          !value.contains('\\') &&
          !value.contains(':') &&
          !value.runes.any((r) => r < 32 || r == 127) &&
          segments.every((s) => s.isNotEmpty && s != '.' && s != '..') &&
          (!singleSegment || segments.length == 1),
      'domain.path',
      path,
      'Expected a safe relative path');
}

void _locator(SourceLocator locator, String path) {
  _relativePath(locator.file, '$path.file');
}

void _validateDomain(ConverterDocument document) {
  switch (document) {
    case SourceMapIr():
      final map = document.map;
      _unique(map.layers.map((l) => l.sourceZ), r'$.map.layers');
      for (var i = 0; i < map.layers.length; i++) {
        _require(
            map.layers[i].cells.length == map.width * map.height,
            'domain.cells',
            '\$.map.layers[$i].cells',
            'Layer length must equal width × height');
      }
      _unique(map.events.map((e) => e.sourceEventId), r'$.map.events');
      _unique(map.unknownDataRefs, r'$.map.unknownDataRefs');
      for (var i = 0; i < map.events.length; i++) {
        final event = map.events[i];
        final path = '\$.map.events[$i]';
        _require(event.x < map.width && event.y < map.height,
            'domain.eventBounds', path, 'Event is outside its map');
        _unique(event.pages.map((p) => p.originalPageIndex), '$path.pages');
        for (var j = 0; j < event.pages.length; j++) {
          final page = event.pages[j];
          final pagePath = '$path.pages[$j]';
          _unique(
              page.commands.map((c) => c.originalIndex), '$pagePath.commands');
          for (var k = 0; k < page.commands.length; k++) {
            final command = page.commands[k];
            final locator = command.sourceLocator;
            final commandPath = '$pagePath.commands[$k].sourceLocator';
            _locator(locator, commandPath);
            _require(
                (locator.mapId == null || locator.mapId == map.sourceMapId) &&
                    (locator.eventId == null ||
                        locator.eventId == event.sourceEventId) &&
                    (locator.pageIndex == null ||
                        locator.pageIndex == page.originalPageIndex) &&
                    (locator.commandIndex == null ||
                        locator.commandIndex == command.originalIndex),
                'domain.locator',
                commandPath,
                'Locator disagrees with its containing source entity');
          }
        }
      }
    case AssetCandidate():
      _unique(document.sources.map((s) => s.fileId), r'$.sources');
      _unique(document.parts.map((p) => p.partId), r'$.parts');
      final sources = {for (final s in document.sources) s.fileId: s};
      for (var i = 0; i < document.parts.length; i++) {
        final part = document.parts[i];
        final path = '\$.parts[$i]';
        final source = sources[part.sourceFileId];
        _require(source != null, 'domain.sourceReference', '$path.sourceFileId',
            'Unknown source image');
        final rect = part.sourceRect;
        _require(
            rect.x + rect.width <= source!.pixelWidth &&
                rect.y + rect.height <= source.pixelHeight,
            'domain.sourceRect',
            '$path.sourceRect',
            'Rectangle exceeds source image');
        final width = part.quarterTurns.isOdd ? rect.height : rect.width;
        final height = part.quarterTurns.isOdd ? rect.width : rect.height;
        _require(
            part.destinationOffset.x >= 0 &&
                part.destinationOffset.y >= 0 &&
                part.destinationOffset.x + width <= document.canvasSize.width &&
                part.destinationOffset.y + height <= document.canvasSize.height,
            'domain.destinationRect',
            '$path.destinationOffset',
            'Transformed part exceeds canvas');
        _locator(part.locator, '$path.locator');
      }
      final anchor = document.anchor;
      final size = document.canvasSize;
      _require(anchor.x <= size.width && anchor.y <= size.height,
          'domain.anchor', r'$.anchor', 'Anchor exceeds canvas boundary');
      final conventionValid = switch (anchor.convention) {
        AnchorConvention.topLeft => anchor.x == 0 && anchor.y == 0,
        AnchorConvention.bottomLeft => anchor.x == 0 && anchor.y == size.height,
        AnchorConvention.bottomCenter =>
          anchor.x * 2 == size.width && anchor.y == size.height,
        AnchorConvention.explicit => true,
      };
      _require(conventionValid, 'domain.anchorConvention', r'$.anchor',
          'Anchor disagrees with convention');
      _require(
          document.state == CandidateState.approved
              ? document.approvedRevision == document.revision
              : document.approvedRevision == null,
          'domain.approvalRevision',
          r'$.approvedRevision',
          'Approval must belong to the current approved revision');
    case ReviewDecisions():
      _unique(document.decisions.map((d) => d.decisionId), r'$.decisions');
      for (var i = 0; i < document.decisions.length; i++) {
        final decision = document.decisions[i];
        _unique(decision.replacementCandidateIds,
            '\$.decisions[$i].replacementCandidateIds');
        _require(
            !decision.replacementCandidateIds.contains(decision.candidateId),
            'domain.selfReplacement',
            '\$.decisions[$i]',
            'Candidate cannot replace itself');
        _require(
            decision.action != ReviewAction.supersede ||
                decision.replacementCandidateIds.isNotEmpty,
            'domain.replacement',
            '\$.decisions[$i]',
            'Superseding requires a replacement');
      }
    case VisionResponse():
      _unique(
          document.suggestions.map((s) => s.suggestionId), r'$.suggestions');
      for (var i = 0; i < document.suggestions.length; i++) {
        _unique(document.suggestions[i].candidateIds,
            '\$.suggestions[$i].candidateIds');
        _unique(document.suggestions[i].sourceRegionIds,
            '\$.suggestions[$i].sourceRegionIds');
      }
    case TargetCapabilities():
      _unique(
          document.capabilities.map((c) => c.capabilityId), r'$.capabilities');
      for (var i = 0; i < document.capabilities.length; i++) {
        final capability = document.capabilities[i];
        if (capability.status == CapabilityStatus.supported) {
          _require(
              capability.scope.trim().isNotEmpty &&
                  capability.evidence.any((e) =>
                      (e.type == EvidenceType.test ||
                          e.type == EvidenceType.human) &&
                      e.summary.trim().isNotEmpty &&
                      e.reference.trim().isNotEmpty),
              'domain.supportEvidence',
              '\$.capabilities[$i].evidence',
              'Supported behavior requires scoped test or human verification evidence');
        }
      }
    case ConversionPlan():
      _unique(document.selectedSourceMapIds, r'$.selectedSourceMapIds');
      _unique(document.dependencySourceMapIds, r'$.dependencySourceMapIds');
      _require(
          !document.selectedSourceMapIds
              .any(document.dependencySourceMapIds.contains),
          'domain.mapScope',
          r'$.dependencySourceMapIds',
          'Selected maps and dependencies must be distinct');
      _unique(document.operations.map((o) => o.operationId), r'$.operations');
      _relativePath(document.outputPolicy.destinationFolderName,
          r'$.outputPolicy.destinationFolderName',
          singleSegment: true);
      for (var i = 0; i < document.operations.length; i++) {
        final operation = document.operations[i];
        final path = '\$.operations[$i]';
        _unique(operation.sourceEntityIds, '$path.sourceEntityIds');
        _unique(operation.targetEntityIds, '$path.targetEntityIds');
        _unique(operation.evidenceRefs, '$path.evidenceRefs');
      }
      _diagnostics(document.findings);
    case ConversionReport():
      _unique(document.coverage.map((c) => c.family), r'$.coverage');
      _unique(document.artifacts.map((a) => a.relativePath), r'$.artifacts');
      for (var i = 0; i < document.coverage.length; i++) {
        final c = document.coverage[i];
        _require(
            c.extracted <= c.observed &&
                c.adapted <= c.extracted &&
                c.preservedOnly <= c.observed &&
                c.excluded <= c.observed &&
                c.unverified <= c.observed,
            'domain.coverage',
            '\$.coverage[$i]',
            'Count exceeds its family denominator');
      }
      for (var i = 0; i < document.artifacts.length; i++) {
        _relativePath(document.artifacts[i].relativePath,
            '\$.artifacts[$i].relativePath');
      }
      final ai = document.aiUsage;
      _require(ai.usageStatus != AiUsageStatus.notUsed || ai.requestCount == 0,
          'domain.aiUsage', r'$.aiUsage', 'Unused AI cannot have requests');
      _diagnostics(document.findings);
      _successfulReport(document);
  }
}

void _diagnostics(List<ConversionDiagnostic> findings) {
  _unique(findings.map((f) => f.diagnosticId), r'$.findings');
  for (var i = 0; i < findings.length; i++) {
    final finding = findings[i];
    final path = '\$.findings[$i]';
    if (finding.sourceLocator != null) {
      _locator(finding.sourceLocator!, '$path.sourceLocator');
    }
    _require(
        finding.disposition != DiagnosticDisposition.acceptedStudyLoss ||
            (finding.acceptedByDecisionId != null &&
                finding.cause != DiagnosticCause.security &&
                finding.cause != DiagnosticCause.sourceInvalid),
        'domain.acceptedLoss',
        path,
        'Accepted study loss requires a decision and a consentable cause');
  }
}

void _successfulReport(ConversionReport report) {
  if (report.state != ReportState.verified &&
      report.state != ReportState.published) {
    return;
  }
  final checks = report.checks;
  _require(
      checks.sourceUnchanged == CheckStatus.passed &&
          report.artifacts.isNotEmpty &&
          ![
            checks.nativeLoad,
            checks.nativeSaveReload,
            checks.visualParity,
            checks.gameplayTrace,
            checks.sourceUnchanged,
          ].contains(CheckStatus.failed),
      'domain.reportEvidence',
      r'$.checks',
      'Successful report requires artifacts, an unchanged source and no failed check');
  if (report.scope != ReportScope.inventory) {
    _require(
        checks.nativeLoad == CheckStatus.passed &&
            checks.nativeSaveReload == CheckStatus.passed,
        'domain.reportNative',
        r'$.checks',
        'Conversion success requires native load and save/reload checks');
  }
  if (report.scope == ReportScope.playableSlice) {
    _require(
        checks.visualParity == CheckStatus.passed &&
            checks.gameplayTrace == CheckStatus.passed,
        'domain.reportPlayable',
        r'$.checks',
        'Playable-slice success requires visual parity and gameplay trace');
  }
  for (final finding in report.findings) {
    if (finding.disposition == DiagnosticDisposition.acceptedStudyLoss &&
        report.scope == ReportScope.study) {
      continue;
    }
    final blocks = switch (report.scope) {
      ReportScope.inventory => false,
      ReportScope.study => finding.blocksStudy,
      ReportScope.playableSlice => finding.blocksPlayableSlice ||
          finding.disposition == DiagnosticDisposition.acceptedStudyLoss,
    };
    _require(
        !blocks &&
            !(finding.severity == DiagnosticSeverity.error &&
                finding.disposition == DiagnosticDisposition.unresolved),
        'domain.reportBlocked',
        r'$.findings',
        'Successful report retains a blocking finding');
  }
}
