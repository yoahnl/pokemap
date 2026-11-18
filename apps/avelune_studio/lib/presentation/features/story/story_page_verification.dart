part of 'story_page.dart';

extension _StoryPageVerification on _StoryPageState {
  StudioBadge? _verificationMarker() {
    final verification = widget.verification;
    if (verification == null) return null;
    final snapshot = verification.snapshot;
    final state = switch (verification.phase) {
      ProjectVerificationPhase.idle => 'idle',
      _ when verification.running => 'running',
      _ when verification.freshness == VerificationFreshness.stale => 'stale',
      _
          when snapshot?.complete != true ||
              verification.freshness != VerificationFreshness.current =>
        'incomplete',
      _ => 'done',
    };
    return StudioBadge(
      state == 'done'
          ? '${snapshot!.problems.length}'
          : context.l10n.verificationNavState(state),
      key: const ValueKey('verification-nav-status'),
      tone: switch (state) {
        'stale' || 'incomplete' => StudioTone.warning,
        'done' when snapshot!.errors > 0 => StudioTone.danger,
        _ => StudioTone.neutral,
      },
    );
  }

  Future<bool> Function()? _destination(VerificationProblem problem) {
    final identifiable = switch (problem.destination) {
      NarrativeProjectDiagnosticDestination.event => problem.eventId != null,
      NarrativeProjectDiagnosticDestination.scene => problem.sceneId != null,
      NarrativeProjectDiagnosticDestination.storyline =>
        problem.storylineId != null || problem.stepId != null,
      NarrativeProjectDiagnosticDestination.fact => problem.factId != null,
      NarrativeProjectDiagnosticDestination.worldRule =>
        problem.worldRuleId != null,
      NarrativeProjectDiagnosticDestination.dialogue =>
        problem.dialogueId != null,
      NarrativeProjectDiagnosticDestination.map => problem.mapId != null,
      _ => false,
    };
    final report = widget.verification?.snapshot;
    return identifiable && report != null
        ? () => _openVerificationDestination(problem, report)
        : null;
  }

  Future<bool> _openVerificationDestination(
    VerificationProblem problem,
    VerificationSnapshot report,
  ) async {
    if (!identical(report, widget.verification?.snapshot)) return true;
    final request = ++_memoryNavigation;
    final parent = widget.navigationState?.call();
    bool requestCurrent() =>
        mounted &&
        request == _memoryNavigation &&
        identical(report, widget.verification?.snapshot) &&
        parent == widget.navigationState?.call();
    await widget.beforeNavigation?.call();
    if (!requestCurrent()) return true;
    final revision = widget.staging.revision;
    bool current() =>
        requestCurrent() && identical(revision, widget.staging.revision);

    switch (problem.destination) {
      case NarrativeProjectDiagnosticDestination.event:
        final id = problem.eventId;
        final record = widget.behaviourSource.registry?.records
            .where((record) => record.id == id)
            .firstOrNull;
        final at = record == null ? null : mapStoryLocation(record);
        if (id == null ||
            at == null ||
            (problem.mapId != null && at.$1 != problem.mapId)) {
          return false;
        }
        final catalog = widget.behaviourCatalog;
        if (catalog == null) return widget.behaviours.open(id);
        final opened = await catalog.open(
          id,
          checkSavedMap: true,
          isRequested: requestCurrent,
        );
        if (!requestCurrent()) return true;
        if (!opened ||
            catalog.editor?.selectedBehaviour?.id != id ||
            catalog.editor?.map?.id != at.$1) {
          return false;
        }
        _showVerificationDestination(StorySection.behaviours, () {
          _behaviours?.filterMap(at.$1);
          _creation = false;
          _selectItem(StorySection.behaviours, (
            kind: StoryDraftKind.event,
            id: id,
          ));
        });
        return true;

      case NarrativeProjectDiagnosticDestination.scene:
        final id = problem.sceneId;
        final open = widget.openScene;
        if (id == null || open == null) return false;
        final entry = widget.staging.draft.entryOf(StoryDraftKind.scene, id);
        if (entry != null && entry.current == null) return false;
        _catalog?.documents.invalidate(id);
        if (widget.openSceneDiagnostic case final openDiagnostic?) {
          openDiagnostic(id, problem.sceneNodeId, current);
        } else {
          open(id, null);
        }
        return true;

      case NarrativeProjectDiagnosticDestination.storyline:
        final trame = widget.trame;
        if (trame == null) return false;
        await (trame.outline.ready ? trame.retry() : trame.open());
        if (!current()) return true;
        if (!trame.outline.ready) return false;
        final stepId = problem.stepId;
        final candidates = trame.view?.outline.storylines.where(
          (story) =>
              (problem.storylineId == null ||
                  problem.storylineId == story.id) &&
              (stepId == null
                  ? problem.storylineId != null && problem.chapterId == null
                  : story.chapters.any(
                      (chapter) =>
                          (problem.chapterId == null ||
                              chapter.id == problem.chapterId) &&
                          chapter.milestones.any((step) => step.id == stepId),
                    )),
        );
        final story = candidates?.singleOrNull;
        if (story == null) return false;
        _showVerificationDestination(
          StorySection.trame,
          () => trame.usageFocus = (storylineId: story.id, stepId: stepId),
        );
        return true;

      case NarrativeProjectDiagnosticDestination.fact:
        final id = problem.factId;
        if (id == null || widget.port == null) return false;
        _openSection(StorySection.facts);
        final memory = _memory!;
        memory.sync();
        await memory.retry();
        if (!current()) return true;
        final entry = widget.staging.draft.entryOf(StoryDraftKind.fact, id);
        final exists = entry == null
            ? memory.facts.ready &&
                  memory.facts.value!.any((fact) => fact.id == id)
            : entry.current != null;
        if (!exists) return false;
        _showVerificationDestination(
          StorySection.facts,
          () => memory.select(id),
        );
        return true;

      case NarrativeProjectDiagnosticDestination.worldRule:
        final id = problem.worldRuleId;
        if (id == null || widget.port == null) return false;
        _openSection(StorySection.rules);
        final rules = _memory!.rules;
        await rules.retry();
        if (!current()) return true;
        if (!rules.saved.ready || rules.rule(id) == null) return false;
        _showVerificationDestination(
          StorySection.rules,
          () => rules.select(id),
        );
        return true;

      case NarrativeProjectDiagnosticDestination.dialogue:
        if (!mounted) return true;
        final id = problem.dialogueId;
        final navigation = StoryDialogueNavigation.of(context);
        if (id == null || navigation == null || widget.dialoguePort == null) {
          return false;
        }
        _openSection(StorySection.dialogues);
        final dialogues = _dialogues;
        if (dialogues == null) return false;
        await dialogues.open();
        if (!current()) return true;
        await dialogues.load(id, force: true);
        if (!current()) return true;
        if (!dialogues.resource(id).ready || dialogues.document(id) == null) {
          return false;
        }
        await (navigation.openRequested?.call(id, current) ??
            navigation.open(id));
        return true;

      case NarrativeProjectDiagnosticDestination.map:
        final id = problem.mapId;
        if (id == null) return false;
        try {
          if (widget.loadMap case final load?) {
            final entry = widget.maps.where((map) => map.id == id).firstOrNull;
            if (entry == null) return false;
            final map = await load(entry);
            if (!current()) return true;
            if (map.id != id) return false;
          }
          final opened = await widget.openMapEntry(id, isCurrent: current);
          return opened || !requestCurrent();
        } on Object {
          if (current()) rethrow;
          return true;
        }

      case NarrativeProjectDiagnosticDestination.overview:
      case NarrativeProjectDiagnosticDestination.cinematic:
        return false;
    }
  }

  void _showVerificationDestination(StorySection section, VoidCallback select) {
    widget.rememberVerificationOrigin?.call();
    _showMemorySection(section, select);
  }
}
