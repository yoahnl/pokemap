part of 'verification_workspace_controller.dart';

/// A document the control could not represent, with the reason. Naming it is
/// not enough on its own: the report never claims to cover what it lists here.
class VerificationExclusion {
  const VerificationExclusion({
    required this.owner,
    required this.label,
    required this.reason,
  });

  final String owner;
  final String label;
  final String reason;
}

/// The frozen input of one analysis. The report, the graph, the limits and the
/// fingerprint all describe this object and nothing else.
class VerificationSnapshot {
  VerificationSnapshot({
    required this.project,
    required this.maps,
    required this.sources,
    required this.savedRevision,
    required this.revision,
    required this.fingerprint,
    required this.exclusions,
    required this.blockers,
    required this.scope,
    required this.drafted,
  });

  final ProjectManifest project;
  final List<MapData> maps;

  /// The Yarn texts actually handed to the compiler, with their provenance.
  final List<VerificationDialogueSource> sources;
  final String savedRevision;
  final String revision;
  final String fingerprint;
  final List<VerificationExclusion> exclusions;
  final List<VerificationDraftBlocker> blockers;
  final List<String> scope;

  /// True as soon as one unsaved document is part of the analysed version.
  final bool drafted;
}

extension VerificationSnapshots on VerificationWorkspaceController {
  /// The version the author is working on: every owner contributes its own
  /// working documents through its existing accessor, so a shared document is
  /// read once and never duplicated for the control.
  /// The dialogue entries the working version carries.
  List<ProjectDialogueEntry> workingDialogueEntries() =>
      dialogues?.call()?.entries ?? narrative.project.dialogues;

  /// The version an editor holds for a dialogue, through the resolver the
  /// dialogue feature already owns: a read-only advanced source is kept as it
  /// stands, and two incompatible drafts are a named conflict, not a choice.
  DialogueWorkingSource openSource(String dialogueId) =>
      resolveDialogueWorkingSource(
        narrative: narrative,
        dialogueId: dialogueId,
        dialogues: dialogues?.call(),
      );

  /// The version the author is working on: every owner contributes its own
  /// working documents through its existing accessor, so a shared document is
  /// read once and never duplicated for the control.
  ///
  /// Returns null when a dialogue opened or closed while the sources were
  /// read: the caller prepares again rather than mixing two versions.
  VerificationSnapshot? capture(
    List<MapData> loaded,
    String savedRevision,
    List<VerificationDialogueSource> saved,
  ) {
    final revision = workingRevision();
    final maps = [
      for (final map in loaded)
        narrative.workspace.documents[map.id]?.current ?? map,
    ];
    final owner = world?.call();
    final eventOwner = events?.call();
    final base = eventOwner?.project ?? narrative.project;
    final project = base.copyWith(
      facts: narrative.facts,
      storylines: narrative.stories,
      scenes: scenes?.call()?.scenes ?? base.scenes,
      worldRules: owner?.rules ?? base.worldRules,
      dialogues: dialogues?.call()?.entries ?? base.dialogues,
      cinematics: cinematics?.call()?.entries ?? base.cinematics,
      presentationCinematics:
          presentations?.call()?.entries ?? base.presentationCinematics,
    );
    final exclusions = _exclusions();
    final sources = <VerificationDialogueSource>[];
    final readable = {for (final item in saved) item.entry.id: item};
    for (final entry in project.dialogues) {
      final held = openSource(entry.id);
      if (held.problem case final problem?) {
        exclusions.add(
          VerificationExclusion(
            owner: 'Dialogues',
            label: entry.id,
            reason: problem,
          ),
        );
        continue;
      }
      if (held.source case final source?) {
        sources.add(
          VerificationDialogueSource(
            entry: source.entry,
            text: source.source,
            origin: held.dirty ? 'brouillon ouvert' : 'session ouverte',
            revision: source.revision,
          ),
        );
        continue;
      }
      final stored = readable[entry.id];
      if (stored == null) return null;
      if (!stored.readable) {
        exclusions.add(
          VerificationExclusion(
            owner: 'Dialogues',
            label: entry.id,
            reason: stored.problem!,
          ),
        );
        continue;
      }
      sources.add(stored);
    }
    return VerificationSnapshot(
      project: project,
      maps: maps,
      sources: sources,
      savedRevision: savedRevision,
      revision: revision,
      fingerprint: _inputFingerprint(project, maps, sources),
      exclusions: exclusions,
      blockers: [
        if (owner != null)
          for (final draft in owner.pendingRules.values)
            if (draft.complete == null)
              VerificationDraftBlocker(
                ruleId: draft.id,
                label: draft.label,
                missing: draft.missing,
              ),
      ],
      scope: [
        '${maps.length} carte(s) analysée(s)',
        '${project.storylines.length} histoire(s)',
        '${project.scenes.length} scène(s)',
        '${sources.length} source(s) de dialogue compilée(s)',
        '${project.facts.length} état(s) du monde',
        '${project.worldRules.length} règle(s) du monde',
      ],
      drafted: _drafted(),
    );
  }

  /// Changes of content, not of shape. Every working document is an immutable
  /// value replaced on each edit, so its instance identity moves when its
  /// content does — including a second edit, an undo then another edit, or a
  /// Yarn source that changed on its own.
  String workingRevision() {
    final parts = <Object>[
      identityHashCode(narrative.project),
      for (final entry in _sorted(narrative.pendingFacts))
        identityHashCode(entry),
      for (final entry in _sorted(narrative.pendingStories))
        identityHashCode(entry),
      ...narrative.pendingStoryDeletions.toList()..sort(),
    ];
    for (final session
        in narrative.sessions.entries.toList()
          ..sort((left, right) => left.key.compareTo(right.key))) {
      parts.add('${session.key}:${identityHashCode(session.value.current)}');
    }
    for (final document
        in narrative.workspace.documents.entries.toList()
          ..sort((left, right) => left.key.compareTo(right.key))) {
      parts.add('${document.key}:${identityHashCode(document.value.current)}');
    }
    if (world?.call() case final owner?) {
      for (final draft in owner.pendingRules.values) {
        parts.add(draft.signature);
      }
    }
    _appendOwnerRevision(parts, scenes?.call()?.scenes, (item) => item.id);
    _appendOwnerRevision(parts, dialogues?.call()?.entries, (item) => item.id);
    _appendOwnerRevision(parts, events?.call()?.records, (item) => item.id);
    _appendOwnerRevision(parts, cinematics?.call()?.entries, (item) => item.id);
    _appendOwnerRevision(
      parts,
      presentations?.call()?.entries,
      (item) => item.id,
    );
    for (final source in _dialogueSources()) {
      parts.add(source);
    }
    return parts.join('|');
  }

  List<Object> _sorted(Map<String, Object> values) {
    final keys = values.keys.toList()..sort();
    return [for (final key in keys) values[key]!];
  }

  void _appendOwnerRevision<T>(
    List<Object> parts,
    List<T>? documents,
    String Function(T) identify,
  ) {
    if (documents == null) return;
    final entries = [
      for (final document in documents)
        '${identify(document)}:${identityHashCode(document)}',
    ]..sort();
    parts.addAll(entries);
  }

  /// A Yarn source edited alone changes no document identifier and no count,
  /// so its own text has to be part of the revision.
  List<String> _dialogueSources() {
    final owner = dialogues?.call();
    if (owner == null) return const [];
    final sources = <String>[];
    for (final entry in owner.entries) {
      final source = owner.sourceForDialogue(entry.id);
      if (source != null) sources.add('${entry.id}:${source.hashCode}');
    }
    return sources..sort();
  }

  bool _drafted() =>
      narrative.dirty ||
      narrative.workspace.dirty ||
      world?.call()?.hasRuleDraft == true ||
      scenes?.call()?.dirty == true ||
      dialogues?.call()?.dirty == true ||
      events?.call()?.dirty == true ||
      cinematics?.call()?.dirty == true ||
      presentations?.call()?.dirty == true;

  /// Two owners holding incompatible versions of the same dialogue, and the
  /// interaction drafts that no manifest can carry.
  List<VerificationExclusion> _exclusions() {
    final result = <VerificationExclusion>[];
    final dialogueOwner = dialogues?.call();
    for (final session in narrative.sessions.entries) {
      if (!session.value.dirty) continue;
      final id = session.value.current.dialogue.entry.id;
      final held = dialogueOwner?.accessProblem(id);
      result.add(
        VerificationExclusion(
          owner: 'Interactions',
          label: id,
          reason: held == null
              ? 'Brouillon d’interaction non représentable dans un manifeste : '
                    'la version enregistrée de ce dialogue a été analysée.'
              : 'Deux brouillons incompatibles pour ce dialogue, un dans '
                    'Interactions et un dans Dialogues : aucun des deux n’a '
                    'été choisi à la place de l’autre.',
        ),
      );
    }
    return result;
  }

  /// The exact bytes the analysis received, sources included, so changing one
  /// line of Yarn changes the fingerprint.
  String _inputFingerprint(
    ProjectManifest project,
    List<MapData> maps,
    List<VerificationDialogueSource> sources,
  ) => computeNarrativeProjectFingerprint([
    NarrativeProjectFingerprintEntry(
      relativePath: 'analysed/project.json',
      bytes: utf8.encode(jsonEncode(project.toJson())),
    ),
    for (final map in maps)
      NarrativeProjectFingerprintEntry(
        relativePath: 'analysed/maps/${map.id}.json',
        bytes: utf8.encode(jsonEncode(map.toJson())),
      ),
    for (final source in sources)
      NarrativeProjectFingerprintEntry(
        relativePath: 'analysed/dialogues/${source.entry.id}.yarn',
        bytes: utf8.encode(source.text),
      ),
  ]);
}
