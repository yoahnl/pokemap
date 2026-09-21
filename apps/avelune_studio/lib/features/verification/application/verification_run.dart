part of 'verification_workspace_controller.dart';

extension VerificationRun on VerificationWorkspaceController {
  /// One identified control. A second click while one runs is ignored rather
  /// than queued, so two reports can never contradict each other.
  Future<bool> run() async {
    if (_closed || running) return false;
    final ticket = ++_generation;
    final manifest = project;
    phase = VerificationPhase.reading;
    error = null;
    changed();
    if (await flushEdits?.call() == false) {
      return ticket == _generation
          ? _fail(
              const VerificationFailure(
                'Corrigez les saisies refusées avant de lancer le contrôle. '
                'Aucune saisie refusée n’a été publiée.',
              ),
            )
          : false;
    }
    try {
      final revision = await port.projectRevision();
      if (_stopped(ticket, manifest)) return false;
      final loaded = await port.loadMaps();
      if (_stopped(ticket, manifest)) return false;
      final evidence = await port.readRuntimeEvidence(selbrumeReleaseV1Profile);
      if (_stopped(ticket, manifest)) return false;
      final snapshot = capture(loaded);
      phase = VerificationPhase.analysing;
      changed();
      final job = port.analyse(project: snapshot.project, maps: snapshot.maps);
      _job = job;
      final analysis = await job.result;
      if (_stopped(ticket, manifest)) return false;
      _job = null;
      report = _assemble(ticket, revision, snapshot, analysis, evidence);
      _keepSelection();
      phase = VerificationPhase.ready;
      changed();
      return true;
    } on Object catch (failure) {
      if (ticket != _generation) return false;
      _job = null;
      return _fail(failure);
    }
  }

  /// A reply from a replaced request, a cancelled one or a closed project is
  /// dropped instead of taking the place of the current report.
  bool _stopped(int ticket, ProjectManifest manifest) =>
      _closed || ticket != _generation || !identical(project, manifest);

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
    String savedRevision,
    VerificationSnapshot snapshot,
    VerificationAnalysis analysis,
    VerificationRuntimeEvidence evidence,
  ) => VerificationReport(
    requestId: ticket,
    savedRevision: savedRevision,
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
