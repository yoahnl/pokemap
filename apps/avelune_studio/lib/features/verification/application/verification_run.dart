part of 'verification_workspace_controller.dart';

extension VerificationRun on VerificationWorkspaceController {
  /// One identified control. A second click while one runs is ignored rather
  /// than queued, so two reports can never contradict each other.
  Future<bool> run() async {
    if (_closed || running) return false;
    final ticket = ++_generation;
    final session = _sessionId;
    phase = VerificationPhase.reading;
    error = null;
    changed();
    try {
      if (await flushEdits?.call() == false) {
        return _interrupted(ticket, session) == VerificationStop.none
            ? _fail(
                const VerificationFailure(
                  'Corrigez les saisies refusées avant de lancer le contrôle. '
                  'Aucune saisie refusée n’a été publiée.',
                ),
              )
            : false;
      }
      final snapshot = await _prepare(ticket, session);
      if (snapshot == null) return _stopped(ticket, session);
      phase = VerificationPhase.analysing;
      changed();
      final job = port.analyse(
        project: snapshot.project,
        maps: snapshot.maps,
        sources: snapshot.sources,
      );
      _job = job;
      final analysis = await job.result;
      if (_interrupted(ticket, session) != VerificationStop.none) {
        return _stopped(ticket, session);
      }
      final evidence = await _evidence(snapshot);
      if (_interrupted(ticket, session) != VerificationStop.none) {
        return _stopped(ticket, session);
      }
      report = _assemble(ticket, snapshot, analysis, evidence);
      _keepSelection();
      return true;
    } on Object catch (failure) {
      return _interrupted(ticket, session) == VerificationStop.none
          ? _fail(failure)
          : _stopped(ticket, session);
    } finally {
      _recover(ticket);
    }
  }

  String get _sessionId => narrative.workspace.session.sessionId;

  /// Why a request may not adopt its result. A new revision of the same
  /// project is not one of them: its snapshot simply became old.
  VerificationStop _interrupted(int ticket, String session) {
    if (_closed) return VerificationStop.closed;
    if (ticket != _generation) return VerificationStop.replaced;
    if (_sessionId != session) return VerificationStop.projectChanged;
    return VerificationStop.none;
  }

  /// A replaced or closed request leaves the state to whoever owns it now. A
  /// project that really changed is refused with its reason, and the page can
  /// be launched again.
  bool _stopped(int ticket, String session) =>
      _interrupted(ticket, session) == VerificationStop.projectChanged
      ? _fail(
          const VerificationFailure(
            'Le projet a changé pendant le contrôle : son résultat a été '
            'refusé. Relancez la vérification.',
          ),
        )
      : false;

  /// Every exit frees the page, and never touches a newer request.
  void _recover(int ticket) {
    if (_closed || ticket != _generation) return;
    _job = null;
    if (phase == VerificationPhase.reading ||
        phase == VerificationPhase.analysing) {
      phase = report == null ? VerificationPhase.idle : VerificationPhase.ready;
    }
    changed();
  }

  /// Reads the entries, the maps and the dialogue sources, then freezes them
  /// together. A publication during those reads restarts the preparation
  /// rather than mixing two versions of the same document.
  Future<VerificationSnapshot?> _prepare(int ticket, String session) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      final manifest = project;
      final savedRevision = await port.projectRevision();
      if (_interrupted(ticket, session) != VerificationStop.none) return null;
      final loaded = await port.loadMaps();
      if (_interrupted(ticket, session) != VerificationStop.none) return null;
      final entries = workingDialogueEntries();
      final saved = await port.readDialogueSources([
        for (final entry in entries)
          if (attempt > 0 || openSource(entry.id).source == null) entry,
      ]);
      if (_interrupted(ticket, session) != VerificationStop.none) return null;
      if (!identical(project, manifest)) continue;
      final snapshot = capture(loaded, savedRevision, saved);
      if (snapshot != null) return snapshot;
    }
    throw const VerificationFailure(
      'Le projet a changé pendant la préparation du contrôle. '
      'Relancez la vérification.',
    );
  }

  Future<VerificationRuntimeEvidence> _evidence(
    VerificationSnapshot snapshot,
  ) => port.readRuntimeEvidence(selbrumeReleaseV1Profile);

  /// A new report keeps the selection when its key survives. A key that is
  /// gone says so: it includes the severity, so its absence proves nothing.
  void _keepSelection() {
    final key = selectedKey;
    if (key == null) return;
    if (report!.diagnostics.any((item) => item.stableKey == key)) {
      selectionNotice = null;
      return;
    }
    selectedKey = null;
    selectionNotice =
        'Le diagnostic sélectionné n’est plus présent dans ce rapport. '
        'Sa clé inclut sa gravité : son absence ne prouve pas qu’il est '
        'résolu.';
  }

  VerificationReport _assemble(
    int ticket,
    VerificationSnapshot snapshot,
    VerificationAnalysis analysis,
    VerificationRuntimeEvidence evidence,
  ) => VerificationReport(
    requestId: ticket,
    savedRevision: snapshot.savedRevision,
    generatedAt: DateTime.now(),
    validatorVersion: VerificationWorkspaceController.validatorVersion,
    inputFingerprint: snapshot.fingerprint,
    freshnessKey: snapshot.revision,
    isolateName: analysis.isolateName,
    project: analysis.validation,
    dependencies: analysis.dependencies,
    dimensions: _dimensions(analysis, snapshot, evidence),
    runtime: evidence,
    scope: snapshot.scope,
    limitations: _limitations(snapshot, evidence),
    blockers: snapshot.blockers,
    exclusions: snapshot.exclusions,
    labels: {
      for (final map in snapshot.maps)
        verificationKeyId(
          NarrativeDependencyKey(
            NarrativeDependencyTargetKind.sourceMap,
            map.id,
          ),
        ): map.name.isEmpty
            ? map.id
            : map.name,
      for (final definition in analysis.dependencies.definitions)
        verificationKeyId(definition.key): definition.label,
    },
    drafted: snapshot.drafted,
  );

  NarrativeMultidimensionalValidationReport _dimensions(
    VerificationAnalysis analysis,
    VerificationSnapshot snapshot,
    VerificationRuntimeEvidence evidence,
  ) {
    final validation = analysis.validation;
    bool narrativeCode(String code) =>
        code.startsWith('narrative') ||
        code == 'oneShotRetryableOutcomeSoftlock';
    final structural = [
      for (final item in validation.diagnostics)
        if (!narrativeCode(item.code)) _multidimensional(item),
    ];
    final narrativeItems = [
      for (final item in validation.diagnostics)
        if (narrativeCode(item.code)) _multidimensional(item),
    ];
    final structuralFails = validation.diagnostics.any(
      (item) =>
          item.severity == NarrativeProjectDiagnosticSeverity.error &&
          !narrativeCode(item.code),
    );
    final symbolic = validation.symbolicReachability;
    return NarrativeMultidimensionalValidationReport(
      validatorVersion: VerificationWorkspaceController.validatorVersion,
      profileId: selbrumeReleaseV1Profile.id,
      profileVersion: selbrumeReleaseV1Profile.version,
      projectFingerprint: snapshot.fingerprint,
      generatedAt: DateTime.now().toUtc(),
      structurallyValid: NarrativeValidationDimensionResult(
        status: structuralFails
            ? NarrativeValidationStatus.fail
            : NarrativeValidationStatus.pass,
        diagnostics: structural,
      ),
      narrativelySolvable: NarrativeValidationDimensionResult(
        status: switch (symbolic?.verdict) {
          NarrativeSymbolicVerdict.pass => NarrativeValidationStatus.pass,
          NarrativeSymbolicVerdict.fail => NarrativeValidationStatus.fail,
          NarrativeSymbolicVerdict.indeterminate =>
            NarrativeValidationStatus.indeterminate,
          null => NarrativeValidationStatus.notRun,
        },
        diagnostics: narrativeItems,
        evidenceRefs: symbolic == null
            ? const []
            : ['symbolic-states:${symbolic.exploredStateCount}'],
        limitations: symbolic == null
            ? const ['La preuve symbolique n’a pas été exécutée.']
            : [for (final issue in symbolic.issues) issue.message],
      ),
      physicallyReachable: analysis.physical,
      runtimeSmokeVerified: _runtime(snapshot, evidence),
    );
  }

  /// A receipt describes the project as it was written on disk. It cannot
  /// speak for a version that carries unsaved documents, so the runtime
  /// dimension of the working version stays unexecuted and says why.
  NarrativeValidationDimensionResult _runtime(
    VerificationSnapshot snapshot,
    VerificationRuntimeEvidence evidence,
  ) => NarrativeValidationDimensionResult(
    status: snapshot.drafted
        ? NarrativeValidationStatus.notRun
        : evidence.status,
    limitations: [
      if (snapshot.drafted)
        'Le contrôle porte sur des documents non enregistrés. La preuve '
            'd’exécution ne décrit que la version enregistrée du projet : '
            'elle ne certifie pas ces entrées.',
      'Version enregistrée · ${evidence.reason}',
    ],
    evidenceRefs: [
      if (evidence.receipt case final receipt?)
        'receipt:${receipt.completedAt.toIso8601String()}',
    ],
  );

  NarrativeMultidimensionalDiagnostic _multidimensional(
    NarrativeProjectDiagnostic item,
  ) => NarrativeMultidimensionalDiagnostic(
    id: item.stableKey,
    code: item.code,
    severity: item.severity.name,
    message: item.message,
    path: item.path,
  );

  List<String> _limitations(
    VerificationSnapshot snapshot,
    VerificationRuntimeEvidence evidence,
  ) => [
    'Catalogues Pokémon non contrôlés : le Studio ne les lit pas, leurs '
        'références ne sont donc ni validées ni déclarées valides.',
    'Fraîcheur : un fichier modifié hors du Studio n’est vu qu’au prochain '
        'contrôle explicite.',
    if (snapshot.drafted)
      'Périmètre : version de travail, documents enregistrés et brouillons '
          'représentables compris.'
    else
      'Périmètre : version enregistrée, aucun brouillon n’était ouvert.',
    for (final exclusion in snapshot.exclusions)
      'Hors contrôle · ${exclusion.owner} · ${exclusion.label} : '
          '${exclusion.reason}',
    if (snapshot.blockers.isNotEmpty)
      'Les règles incomplètes sont listées à part : elles ne sont pas des '
          'définitions et n’atteignent pas le validateur.',
    'Preuve d’exécution · ${evidence.reason}',
  ];
}
