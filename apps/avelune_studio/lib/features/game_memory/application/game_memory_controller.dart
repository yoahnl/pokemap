import 'dart:async';

import 'package:map_core/map_core_domain.dart';

import '../../story_draft/domain/story_draft_entry.dart';
import '../domain/narrative_index_port.dart';
import 'game_memory_fact_rows.dart';
import 'game_memory_names.dart';
import 'game_memory_resource.dart';
import 'game_memory_rules.dart';
import 'game_memory_staging.dart';

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
  final usages = <String, NarrativeUsages>{};
  final _requested = <String>{};
  final _usagesRequested = <String>{};
  late final names = GameMemoryNames(port, changed);
  late final rules = GameMemoryRules(this);
  var section = GameMemorySection.facts;
  var query = '';
  final filters = <GameMemoryFactFilter>{};
  String? selectedFact;
  String? usagesError;
  Object? detailsError;
  Timer? _batch;
  final _pending = <String>{};

  Object? _revision;
  var _generation = 0;

  Future<void> open() {
    _revision = staging.revision;
    return facts.load(() => port.titles(NarrativeTitleKind.facts), changed);
  }

  void sync() {
    final revision = staging.revision;
    if (identical(revision, _revision)) return;
    _revision = revision;
    if (!facts.ready) return;
    _generation++;
    details.clear();
    _requested.clear();
    usages.clear();
    usagesFilter.value = null;
    names.clear();
    unawaited(retry());
    if (filters.isNotEmpty) unawaited(_loadFilterUsages(force: true));
    if (selectedFact case final id?) unawaited(_selectUsages(id));
    if (rules.saved.ready) unawaited(rules.retry());
  }

  Future<void> retry() => facts.load(
    () => port.titles(NarrativeTitleKind.facts),
    changed,
    force: true,
  );

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

  void retryUsages() => unawaited(_loadFilterUsages(force: true));

  Future<void> _loadFilterUsages({bool force = false}) => usagesFilter.load(
    () async {
      await _loadUsages([for (final title in facts.value!) title.id]);
      return true;
    },
    changed,
    force: force,
  );

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
      detailsError = failure;
    }
    changed();
  }

  NarrativeFactDefinition? current(String id) =>
      staging.draft.entryOf(StoryDraftKind.fact, id)?.current ?? details[id];

  void select(String id) {
    selectedFact = id;
    section = GameMemorySection.facts;
    reveal(id);
    unawaited(_selectUsages(id));
    changed();
  }

  Future<void> _selectUsages(String id) async {
    if (facts.value?.any((title) => title.id == id) != true) return;
    try {
      usagesError = null;
      await _loadUsages([id]);
      for (final owner in usages[id]?.owners ?? const <NarrativeOwner>[]) {
        unawaited(names.ensure(owner.kind.titles));
      }
    } on NarrativeIndexPreparationRequired catch (failure) {
      usagesError = failure.scope;
    } on Object catch (failure) {
      usagesError = '$failure';
    }
    changed();
  }

  Future<void> _loadUsages(List<String> ids) async {
    final missing = [
      for (final id in ids)
        if (!usages.containsKey(id) && _usagesRequested.add(id)) id,
    ];
    if (missing.isEmpty) return;
    try {
      usages.addAll(await port.factUsers(missing));
    } finally {
      _usagesRequested.removeAll(missing);
    }
  }

  String? createFact(String label, NarrativeValueKind kind) {
    if (!staging.editable || label.trim().isEmpty) return null;
    final known = <String>{
      for (final title in facts.value ?? const <NarrativeTitle>[]) title.id,
      ...staging.draft.touched(StoryDraftKind.fact),
    };
    final fact = addNarrativeFact(
      ProjectManifest(
        name: 'facts',
        maps: const [],
        tilesets: const [],
        facts: [
          for (final id in known) NarrativeFactDefinition(id: id, label: id),
        ],
      ),
      label: label,
      initialValue: kind == NarrativeValueKind.integer
          ? NarrativeValue.integer(0)
          : const NarrativeValue.boolean(false),
    ).createdFact;
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

  bool discardCreated(String id) {
    final entry = staging.draft.entryOf(StoryDraftKind.fact, id);
    if (!staging.editable || entry == null || !entry.creation) return false;
    staging.stage((draft) => draft.remove(StoryDraftKind.fact, id));
    if (selectedFact == id) selectedFact = null;
    changed();
    return true;
  }

  void dispose() => _batch?.cancel();
}
