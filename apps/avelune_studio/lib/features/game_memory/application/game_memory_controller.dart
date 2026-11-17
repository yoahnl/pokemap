import 'dart:async';

import 'package:map_core/map_core_domain.dart';

import '../../events/domain/event_record_view.dart';
import '../../story_draft/domain/story_dialogue_source.dart';

import '../../story_draft/application/story_draft_fact_identity.dart';
import '../../story_draft/domain/story_draft_entry.dart';
import '../domain/narrative_index_port.dart';
import 'game_memory_fact_rows.dart';
import 'game_memory_draft_usages.dart';
import 'game_memory_names.dart';
import 'game_memory_resource.dart';
import 'game_memory_rules.dart';
import 'game_memory_staging.dart';
import 'game_memory_usage_targets.dart';

part 'game_memory_usage_loading.dart';
part 'game_memory_owner_names.dart';

enum GameMemorySection { facts, rules }

final class GameMemoryController {
  GameMemoryController({
    required this.port,
    required this.staging,
    required this.changed,
  });

  final NarrativeIndexPort port;
  final GameMemoryStaging staging;
  final void Function() changed;
  final facts = GameMemoryResource<List<NarrativeTitle>>();
  final usagesFilter = GameMemoryResource<bool>();
  final details = <String, NarrativeFactDefinition>{};
  final _savedUsages = <String, NarrativeUsages>{};
  late final usages = GameMemoryDraftUsages(staging.draft, () => _savedUsages);
  final _requested = <String>{};
  final _usagesRequested = <String>{};
  final _usagePending = <String>{};
  final _usageErrors = <String, String>{};
  final _usageStories = <String, Future<StorylineAsset?>>{};
  Timer? _usageBatch;
  late final names = GameMemoryNames(port, changed);
  late final rules = GameMemoryRules(this);
  var section = GameMemorySection.facts;
  var query = '';
  final filters = <GameMemoryFactFilter>{};
  String? selectedFact;
  Object? detailsError;
  Timer? _batch;
  final _pending = <String>{};

  Object? _revision;
  var _generation = 0;

  Future<void> open() {
    sync();
    return facts.load(() => port.titles(NarrativeTitleKind.facts), changed);
  }

  void sync() {
    _followSelectedIdentity();
    final revision = staging.revision;
    if (identical(revision, _revision)) return;
    _revision = revision;
    if (!facts.ready && !facts.loading) return;
    _generation++;
    facts.invalidate();
    details.clear();
    detailsError = null;
    _pending.clear();
    _batch?.cancel();
    _batch = null;
    _requested.clear();
    _usagesRequested.clear();
    _usagePending.clear();
    _usageErrors.clear();
    _usageStories.clear();
    _usageBatch?.cancel();
    _usageBatch = null;
    _savedUsages.clear();
    usages.reset();
    usagesFilter.invalidate();
    names.clear();
    unawaited(retry());
    if (selectedFact case final id?) {
      reveal(id);
      unawaited(_selectUsages(id));
    }
    if (rules.saved.ready) unawaited(rules.retry());
  }

  void _followSelectedIdentity() {
    final id = selectedFact;
    final draft = staging.draft;
    if (id == null || current(id) != null) return;
    for (final identity in {
      ...draft.nextStepIdentities(redo: false),
      ...draft.nextStepIdentities(redo: true),
    }) {
      final other = identity.from.id == id
          ? identity.to
          : identity.to.id == id
          ? identity.from
          : null;
      if (other == null ||
          other.kind != StoryDraftKind.fact ||
          draft.currentOf(StoryDraftKind.fact, other.id) == null) {
        continue;
      }
      selectedFact = other.id;
      reveal(other.id);
      unawaited(_selectUsages(other.id));
      changed();
      return;
    }
  }

  Future<void> retry() async {
    final generation = _generation;
    await facts.load(
      () => port.titles(NarrativeTitleKind.facts),
      changed,
      force: true,
    );
    if (generation == _generation && facts.ready && filters.isNotEmpty) {
      await _loadFilterUsages(force: true);
    }
  }

  List<GameMemoryFactRow> get rows => gameMemoryFactRows(
    titles: facts.value ?? const [],
    draft: staging.draft,
    details: details,
    usages: usages,
    query: query,
    filters: usagesFilter.ready ? filters : const {},
  );

  List<GameMemoryFactRow> get allFacts => gameMemoryFactRows(
    titles: facts.value ?? const [],
    draft: staging.draft,
    details: details,
    usages: usages,
  );

  void show(GameMemorySection value) {
    section = value;
    if (value == GameMemorySection.rules) unawaited(rules.open());
    changed();
  }

  void search(String value) {
    query = value;
    changed();
  }

  void toggle(GameMemoryFactFilter filter) {
    if (!filters.remove(filter)) filters.add(filter);
    if (filters.isNotEmpty) unawaited(_loadFilterUsages());
    changed();
  }

  void reveal(String id) {
    if (details.containsKey(id) || _requested.contains(id)) return;
    if (staging.draft.entryOf(StoryDraftKind.fact, id)?.base == null &&
        staging.draft.isTouched(StoryDraftKind.fact, id)) {
      return;
    }
    _pending.add(id);
    _batch ??= Timer(Duration.zero, _flushDetails);
  }

  Future<void> _flushDetails() async {
    _batch = null;
    final ids = [..._pending];
    final generation = _generation;
    _pending.clear();
    _requested.addAll(ids);
    try {
      final loaded = await port.facts(ids);
      if (generation != _generation) return;
      for (final fact in loaded) {
        details[fact.id] = fact;
      }
    } on Object catch (failure) {
      if (generation != _generation) return;
      detailsError = failure;
    }
    changed();
  }

  NarrativeFactDefinition? current(String id) {
    final entry = staging.draft.entryOf(StoryDraftKind.fact, id);
    return entry == null ? details[id] : entry.current;
  }

  NarrativeValueKind? kindOf(String id) {
    if (staging.draft.isTouched(StoryDraftKind.fact, id)) {
      return current(id)?.valueKind;
    }
    return current(id)?.valueKind ??
        facts.value?.where((fact) => fact.id == id).firstOrNull?.value?.kind;
  }

  void select(String id) {
    selectedFact = id;
    section = GameMemorySection.facts;
    reveal(id);
    unawaited(_selectUsages(id));
    changed();
  }

  String? createFact(String label, NarrativeValueKind kind) {
    if (!staging.editable || label.trim().isEmpty) return null;
    final known = <String>{
      for (final title in facts.value ?? const <NarrativeTitle>[]) title.id,
      ...staging.draft.touched(StoryDraftKind.fact),
    };
    final fact = NarrativeFactDefinition(
      id: canonicalDraftFactId(label, known),
      label: label.trim(),
      initialValue: switch (kind) {
        NarrativeValueKind.integer => NarrativeValue.integer(0),
        NarrativeValueKind.boolean => const NarrativeValue.boolean(false),
        NarrativeValueKind.string => const NarrativeValue.string(''),
      },
    );
    staging.stage((draft) {
      draft.load(StoryDraftKind.fact, fact.id, null);
      draft.put(StoryDraftKind.fact, fact);
    });
    select(fact.id);
    return fact.id;
  }

  bool renameFact(String id, String label) {
    final before = current(id);
    final trimmed = label.trim();
    if (!staging.editable || before == null || trimmed.isEmpty) return false;
    if (trimmed == before.label) return true;
    if (staging.draft.entryOf(StoryDraftKind.fact, id)?.creation == true) {
      return false;
    }
    final saved = details[id];
    if (saved != null) staging.rememberFact(saved);
    staging.stage((draft) {
      if (!draft.isLoaded(StoryDraftKind.fact, id)) {
        draft.load(StoryDraftKind.fact, id, saved);
      }
      draft.put(
        StoryDraftKind.fact,
        NarrativeFactDefinition(
          id: id,
          label: trimmed,
          description: before.description,
          category: before.category,
          initialValue: before.initialValue,
          tags: before.tags,
          legacyFlagName: before.legacyFlagName,
        ),
      );
    });
    return true;
  }

  bool canDiscardCreated(String id) {
    final entry = staging.draft.entryOf(StoryDraftKind.fact, id);
    if (!staging.editable || entry == null || !entry.creation) return false;
    if (!_savedUsages.containsKey(id) ||
        !usages.draftCovered ||
        usages[id]?.owners.isNotEmpty == true) {
      return false;
    }
    return true;
  }

  bool discardCreated(String id) {
    if (!canDiscardCreated(id)) return false;
    staging.stage((draft) => draft.remove(StoryDraftKind.fact, id));
    if (selectedFact == id) selectedFact = null;
    changed();
    return true;
  }

  void dispose() {
    _batch?.cancel();
    _usageBatch?.cancel();
  }
}
