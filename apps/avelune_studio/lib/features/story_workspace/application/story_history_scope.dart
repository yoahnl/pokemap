import 'package:map_core/map_core_domain.dart';

import '../../story_draft/application/story_draft.dart';
import '../../story_draft/domain/story_draft_entry.dart';
import '../../story_draft/domain/story_dialogue_source.dart';

enum StoryHistoryDecision { allowed, empty, outsideSelection }

final class StoryHistoryScope {
  StoryHistoryScope(Iterable<StoryDraftRef> roots)
    : roots = Set.unmodifiable(roots);

  const StoryHistoryScope.empty() : roots = const {};

  final Set<StoryDraftRef> roots;

  StoryHistoryDecision decision(StoryDraft draft, {required bool redo}) {
    final next = draft.nextStep(redo: redo);
    if (next.isEmpty) return StoryHistoryDecision.empty;
    if (roots.isEmpty) return StoryHistoryDecision.outsideSelection;
    if (next.every(roots.contains)) return StoryHistoryDecision.allowed;
    final candidates = {...roots, ...next};
    final versions = <StoryDraftRef, List<Object>>{};
    final entries = <StoryDraftRef, List<StoryDraftEntry<Object>>>{};
    void add(StoryDraftRef ref, Object? value) {
      if (value != null) versions.putIfAbsent(ref, () => []).add(value);
    }

    for (final ref in roots) {
      add(ref, draft.baseOf(ref.kind, ref.id));
      add(ref, draft.currentOf(ref.kind, ref.id));
    }
    for (final entry in draft.nextStepEntries(redo: redo)) {
      add(entry.ref, entry.current);
      entries.putIfAbsent(entry.ref, () => []).add(entry);
    }
    final related = <StoryDraftRef, Set<StoryDraftRef>>{};
    void relate(StoryDraftRef from, StoryDraftRef to) {
      related.putIfAbsent(from, () => {}).add(to);
      related.putIfAbsent(to, () => {}).add(from);
    }

    for (final identity in draft.nextStepIdentities(redo: redo)) {
      relate(identity.from, identity.to);
    }
    final removed = <StoryDraftRef, Set<StoryDraftRef>>{};
    final added = <StoryDraftRef, Set<StoryDraftRef>>{};
    for (final MapEntry(:key, :value) in entries.entries) {
      final before = _dependencies(value.first.current).toSet();
      final after = _dependencies(value.last.current).toSet();
      for (final ref in before.difference(after)) {
        removed.putIfAbsent(ref, () => {}).add(key);
      }
      for (final ref in after.difference(before)) {
        added.putIfAbsent(ref, () => {}).add(key);
      }
    }
    for (final MapEntry(:key, :value) in removed.entries) {
      for (final from in value) {
        for (final to in added[key] ?? const <StoryDraftRef>{}) {
          relate(from, to);
        }
      }
    }
    final reached = {...roots};
    final pending = [...roots];
    while (pending.isNotEmpty) {
      final ref = pending.removeLast();
      for (final linked in related[ref] ?? const <StoryDraftRef>{}) {
        if (candidates.contains(linked) && reached.add(linked)) {
          pending.add(linked);
        }
      }
      for (final value in versions[ref] ?? const <Object>[]) {
        for (final dependency in _dependencies(value)) {
          if (candidates.contains(dependency) && reached.add(dependency)) {
            pending.add(dependency);
          }
        }
      }
    }
    return next.every(reached.contains)
        ? StoryHistoryDecision.allowed
        : StoryHistoryDecision.outsideSelection;
  }

  @override
  bool operator ==(Object other) =>
      other is StoryHistoryScope &&
      other.roots.length == roots.length &&
      roots.every(other.roots.contains);

  @override
  int get hashCode => Object.hashAllUnordered(roots);
}

Iterable<StoryDraftRef> _dependencies(Object? value) {
  if (value is StoryDialogueSource) {
    try {
      return [
        for (final id in dialogueTextFactIds(value.source))
          (kind: StoryDraftKind.fact, id: id),
      ];
    } on FormatException {
      return const [];
    }
  }
  if (value is! SceneAsset &&
      value is! StorylineAsset &&
      value is! WorldRuleDefinition &&
      value is! NarrativeEventRecord) {
    return const [];
  }
  final project = ProjectManifest(
    name: 'history-scope',
    maps: const [],
    tilesets: const [],
    scenes: [if (value is SceneAsset) value],
    storylines: [if (value is StorylineAsset) value],
    worldRules: [if (value is WorldRuleDefinition) value],
    eventRegistry: value is NarrativeEventRecord
        ? NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: [value],
            legacyClaims: const [],
          )
        : null,
  );
  return [
    for (final usage in buildNarrativeDependencyIndex(project: project).usages)
      ?_reference(usage.target),
  ];
}

StoryDraftRef? _reference(NarrativeDependencyKey key) {
  final kind = switch (key.kind) {
    NarrativeDependencyTargetKind.eventV2 => StoryDraftKind.event,
    NarrativeDependencyTargetKind.scene => StoryDraftKind.scene,
    NarrativeDependencyTargetKind.dialogue => StoryDraftKind.dialogue,
    NarrativeDependencyTargetKind.fact => StoryDraftKind.fact,
    NarrativeDependencyTargetKind.storyline => StoryDraftKind.story,
    NarrativeDependencyTargetKind.worldRule => StoryDraftKind.worldRule,
    _ => null,
  };
  return kind == null ? null : (kind: kind, id: key.id);
}
