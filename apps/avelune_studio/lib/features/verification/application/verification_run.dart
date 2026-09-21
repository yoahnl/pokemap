part of 'verification_workspace_controller.dart';

extension VerificationRun on VerificationWorkspaceController {
  /// One identified control. A second click while one runs is ignored rather
  /// than queued, so two reports can never contradict each other.
  Future<bool> run() async {
    if (_closed || running) return false;
    if (flushEdits?.call() == false) {
      return _fail(
        const VerificationFailure(
          'Corrigez les saisies refusées avant de lancer le contrôle. '
          'Aucune saisie refusée n’a été publiée.',
        ),
      );
    }
    final ticket = ++_generation;
    final manifest = project;
    phase = VerificationPhase.reading;
    error = null;
    changed();
    try {
      final revision = await port.projectRevision();
      if (_stopped(ticket, manifest)) return false;
      final loaded = await port.loadMaps();
      if (_stopped(ticket, manifest)) return false;
      final evidence = await port.readRuntimeEvidence(selbrumeReleaseV1Profile);
      if (_stopped(ticket, manifest)) return false;
      phase = VerificationPhase.analysing;
      changed();
      final maps = _workingMaps(loaded);
      final analysed = project.copyWith(
        facts: narrative.facts,
        storylines: narrative.stories,
        worldRules: world?.call()?.rules ?? project.worldRules,
      );
      final validation = validateNarrativeProject(analysed, maps: maps);
      final physical = await port.physicalReachability(
        project: analysed,
        maps: maps,
        symbolic: validation.symbolicReachability,
      );
      if (_stopped(ticket, manifest)) return false;
      final built = _assemble(
        ticket,
        revision,
        analysed,
        maps,
        validation,
        physical,
        evidence,
      );
      if (_stopped(ticket, manifest)) return false;
      report = built;
      selectedKey = null;
      phase = VerificationPhase.ready;
      changed();
      return true;
    } on Object catch (failure) {
      return ticket == _generation ? _fail(failure) : false;
    }
  }

  /// The project may have been closed or replaced while a read was pending.
  bool _stopped(int ticket, ProjectManifest manifest) =>
      _closed || ticket != _generation || !identical(project, manifest);

  VerificationReport _assemble(
    int ticket,
    String revision,
    ProjectManifest analysed,
    List<MapData> maps,
    NarrativeProjectValidationReport validation,
    NarrativeValidationDimensionResult physical,
    VerificationRuntimeEvidence evidence,
  ) {
    final owner = world?.call();
    final dependencies = buildNarrativeDependencyIndex(
      project: analysed,
      maps: maps,
    );
    return VerificationReport(
      requestId: ticket,
      sessionId: revision,
      generatedAt: DateTime.now(),
      validatorVersion: VerificationWorkspaceController.validatorVersion,
      inputFingerprint: _fingerprint(analysed, maps),
      freshnessKey: _freshnessKey(),
      project: validation,
      dependencies: dependencies,
      dimensions: _dimensions(validation, physical, evidence),
      runtime: evidence,
      scope: _scope(analysed, maps),
      limitations: _limitations(owner, evidence),
      blockers: _blockers(owner),
      labels: {
        for (final map in maps) map.id: map.name.isEmpty ? map.id : map.name,
        for (final definition in dependencies.definitions)
          definition.key.id: definition.label,
      },
      includesDrafts: true,
    );
  }

  /// The version the author is working on: a map with an unsaved draft is
  /// analysed as it stands on screen, not as it stands on disk.
  List<MapData> _workingMaps(List<MapData> loaded) => [
    for (final map in loaded)
      narrative.workspace.documents[map.id]?.current ?? map,
  ];

  String _fingerprint(ProjectManifest analysed, List<MapData> maps) =>
      computeNarrativeProjectFingerprint([
        NarrativeProjectFingerprintEntry(
          relativePath: 'project.json',
          bytes: utf8.encode(jsonEncode(analysed.toJson())),
        ),
        for (final map in maps)
          NarrativeProjectFingerprintEntry(
            relativePath: 'maps/${map.id}.json',
            bytes: utf8.encode(jsonEncode(map.toJson())),
          ),
      ]);

  NarrativeMultidimensionalValidationReport _dimensions(
    NarrativeProjectValidationReport validation,
    NarrativeValidationDimensionResult physical,
    VerificationRuntimeEvidence evidence,
  ) {
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
      projectFingerprint: evidence.receipt?.projectFingerprint ?? _absentHash,
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
      physicallyReachable: physical,
      runtimeSmokeVerified: NarrativeValidationDimensionResult(
        status: evidence.status,
        limitations: [evidence.reason],
        evidenceRefs: [
          if (evidence.receipt case final receipt?)
            'receipt:${receipt.completedAt.toIso8601String()}',
        ],
      ),
    );
  }

  NarrativeMultidimensionalDiagnostic _multidimensional(
    NarrativeProjectDiagnostic item,
  ) => NarrativeMultidimensionalDiagnostic(
    id: item.stableKey,
    code: item.code,
    severity: item.severity.name,
    message: item.message,
    path: item.path,
  );

  List<String> _scope(ProjectManifest analysed, List<MapData> maps) => [
    '${maps.length} carte(s) analysée(s)',
    '${analysed.storylines.length} histoire(s)',
    '${analysed.scenes.length} scène(s)',
    '${analysed.dialogues.length} dialogue(s)',
    '${analysed.facts.length} état(s) du monde',
    '${analysed.worldRules.length} règle(s) du monde',
  ];

  List<String> _limitations(
    WorldWorkspaceController? owner,
    VerificationRuntimeEvidence evidence,
  ) {
    final sessions = narrative.sessions.values
        .where((session) => session.dirty)
        .length;
    return [
      'Catalogues Pokémon non contrôlés : le Studio ne les lit pas, leurs '
          'références ne sont donc ni validées ni déclarées valides.',
      'Fraîcheur : un fichier modifié hors du Studio n’est vu qu’au prochain '
          'contrôle explicite.',
      if (sessions > 0)
        '$sessions interaction(s) ont un brouillon non représentable dans ce '
            'contrôle : leur version enregistrée a été analysée.',
      if (owner != null && owner.pendingRules.isNotEmpty)
        'Les règles incomplètes sont listées à part : elles ne sont pas des '
            'définitions et n’atteignent pas le validateur.',
      evidence.reason,
    ];
  }

  List<VerificationDraftBlocker> _blockers(WorldWorkspaceController? owner) => [
    if (owner != null)
      for (final draft in owner.pendingRules.values)
        if (draft.complete == null)
          VerificationDraftBlocker(
            ruleId: draft.id,
            label: draft.label,
            missing: draft.missing,
          ),
  ];
}

const _absentHash =
    'sha256:${''
        '0000000000000000000000000000000000000000000000000000000000000000'}';
