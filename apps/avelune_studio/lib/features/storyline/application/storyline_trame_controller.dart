import 'dart:async';

import 'package:map_core/map_core_domain.dart';

import '../../game_behaviours/application/game_behaviour_source.dart';
import '../../game_memory/application/game_memory_resource.dart';
import '../../game_memory/application/game_memory_staging.dart';
import '../../game_memory/domain/narrative_index_port.dart';
import '../../story_draft/domain/story_draft_entry.dart';
import '../domain/storyline_read_port.dart';
import 'storyline_trame_view.dart';

final class StorylineTrameController {
  StorylineTrameController({
    required this.port,
    required this.index,
    required this.staging,
    required this.source,
    required this.changed,
  });

  final StorylineReadPort port;
  final NarrativeIndexPort index;
  final GameMemoryStaging staging;
  final GameBehaviourSource Function() source;
  final void Function() changed;
  final outline = GameMemoryResource<StorylineOutline>();
  final saved = GameMemoryResource<List<StorylineAsset>>();
  final facts = GameMemoryResource<List<NarrativeTitle>>();
  final proposal = GameMemoryResource<StorylineProposalRead>();
  final definitions = <String, NarrativeFactDefinition>{};
  String? refusal;
  String? focus;
  Object? _revision;
  (Object?, Object?, Object?, Object?, StorylineTrameView)? _view;

  Future<void> open() {
    _revision ??= source().revision;
    return outline.load(port.outline, changed);
  }

  Future<void> retry() => outline.load(port.outline, changed, force: true);

  void sync() {
    final revision = source().revision;
    if (identical(revision, _revision)) return;
    _revision = revision;
    if (!outline.ready) return;
    unawaited(retry());
    if (saved.ready) {
      unawaited(saved.load(port.storylines, changed, force: true));
    }
    if (facts.ready) unawaited(_loadFacts(force: true));
  }

  Future<void> _loadFacts({bool force = false}) => facts.load(
    () => index.titles(NarrativeTitleKind.facts),
    changed,
    force: force,
  );

  void ensureFactNames() => unawaited(_loadFacts());

  String? factName(String id) {
    final title = facts.value?.where((fact) => fact.id == id).firstOrNull;
    final name = title?.title.trim();
    return name == null || name.isEmpty ? null : name;
  }

  bool get edited => staging.draft.touched(StoryDraftKind.story).isNotEmpty;

  StorylineTrameView? get view {
    final current = source();
    final saved = outline.value;
    if (saved == null) return null;
    final version = staging.draft.versionOf(StoryDraftKind.story);
    final cached = _view;
    if (cached != null &&
        identical(cached.$1, saved) &&
        identical(cached.$2, current.registry) &&
        cached.$3 == version &&
        identical(cached.$4, this.saved.value)) {
      return cached.$5;
    }
    final built = StorylineTrameView(
      edited && this.saved.ready ? _projected(current) : saved,
      current.registry,
    );
    _view = (saved, current.registry, version, this.saved.value, built);
    return built;
  }

  StorylineOutline _projected(GameBehaviourSource current) =>
      projectStorylineOutline(
        working().copyWith(
          scenes: current.scenes,
          eventRegistry: current.registry,
        ),
        scenes: [
          for (final scene in current.scenes) (id: scene.id, title: scene.name),
        ],
      );

  ProjectManifest working() {
    final draft = staging.draft;
    T effective<T extends Object>(StoryDraftKind<T> kind, T value, String id) =>
        draft.isTouched(kind, id) ? draft.entryOf(kind, id)!.current! : value;
    final stories = [
      for (final story in saved.value ?? const <StorylineAsset>[])
        if (!draft.isTouched(StoryDraftKind.story, story.id) ||
            draft.entryOf(StoryDraftKind.story, story.id)!.current != null)
          effective(StoryDraftKind.story, story, story.id),
      for (final id in draft.touched(StoryDraftKind.story))
        if (draft.entryOf(StoryDraftKind.story, id)!.creation)
          draft.entryOf(StoryDraftKind.story, id)!.current!,
    ];
    final titles = {for (final fact in facts.value ?? const []) fact.id: fact};
    final factList = [
      for (final title in titles.values)
        effective(
          StoryDraftKind.fact,
          definitions[title.id] ??
              NarrativeFactDefinition(
                id: title.id,
                label: title.title.trim().isEmpty ? title.id : title.title,
                category: title.category ?? '',
                initialValue: title.value,
              ),
          title.id,
        ),
      for (final id in draft.touched(StoryDraftKind.fact))
        if (!titles.containsKey(id))
          ?draft.entryOf(StoryDraftKind.fact, id)!.current,
    ];
    return ProjectManifest(
      name: 'trame',
      maps: source().maps,
      tilesets: const [],
      storylines: stories,
      facts: factList,
      scenes: source().scenes,
    );
  }

  Future<bool> prepare() async {
    await Future.wait([saved.load(port.storylines, changed), _loadFacts()]);
    return saved.ready && facts.ready;
  }

  Future<void> loadDefinition(String factId) async {
    if (definitions.containsKey(factId)) return;
    for (final fact in await index.facts([factId])) {
      definitions[fact.id] = fact;
    }
  }

  bool apply(StorylineMilestoneMutation mutation) {
    final result = mutation.result;
    if (result.disposition == StorylineMutationDisposition.rejected) {
      refusal = result.code ?? 'rejected';
      changed();
      return false;
    }
    final before = {for (final s in result.before.storylines) s.id: s};
    final beforeFacts = {for (final f in result.before.facts) f.id: f};
    if (result.after.facts.any(
      (fact) =>
          beforeFacts[fact.id] != null &&
          beforeFacts[fact.id] != fact &&
          definitions[fact.id] == null,
    )) {
      refusal = 'factNotLoaded';
      changed();
      return false;
    }
    refusal = null;
    if (result.disposition == StorylineMutationDisposition.noChange) {
      return true;
    }
    final stored = {for (final s in saved.value ?? const []) s.id: s};
    staging.stage((draft) {
      for (final story in result.after.storylines) {
        if (before[story.id] == story) continue;
        final base = stored[story.id];
        if (base != null) staging.rememberStory(base);
        if (!draft.isLoaded(StoryDraftKind.story, story.id)) {
          draft.load(StoryDraftKind.story, story.id, base);
        }
        draft.put(StoryDraftKind.story, story);
      }
      for (final fact in result.after.facts) {
        final previous = beforeFacts[fact.id];
        if (previous == fact) continue;
        final base = previous == null ? null : definitions[fact.id];
        if (base != null) staging.rememberFact(base);
        if (!draft.isLoaded(StoryDraftKind.fact, fact.id)) {
          draft.load(StoryDraftKind.fact, fact.id, base);
        }
        draft.put(StoryDraftKind.fact, fact);
      }
    });
    return true;
  }
}
