import 'dart:async';

import 'package:map_core/map_core_domain.dart';

import '../../game_memory/application/game_memory_resource.dart';
import '../../game_memory/domain/narrative_index_port.dart';
import 'game_behaviour_groups.dart';
import 'game_behaviour_rows.dart';
import 'game_behaviour_source.dart';
import 'game_behaviour_summary.dart';

final class GameBehavioursController {
  GameBehavioursController({
    required this.port,
    required this.source,
    required this.changed,
  });

  final NarrativeIndexPort port;
  final GameBehaviourSource Function() source;
  final void Function() changed;
  final saved = GameMemoryResource<List<NarrativeTitle>>();
  final facts = GameMemoryResource<List<NarrativeTitle>>();
  final usages = GameMemoryResource<Map<String, NarrativeUsages>>();
  var grouping = GameBehaviourGrouping.map;
  var query = '';
  final filters = <GameBehaviourFilter>{};
  final refused = <String>{};
  Object? _revision;
  (Object?, Object?, Object?, List<GameBehaviourRow>)? _rows;
  (Object?, Map<String, SceneAsset>)? _scenes;
  (Object?, Map<String, String>)? _factNames;
  final _summaries = Expando<GameBehaviourSummary>();

  Future<void> open() {
    _revision = source().revision;
    unawaited(facts.load(_factTitles, changed));
    return saved.load(_titles, changed);
  }

  Future<List<NarrativeTitle>> _factTitles() =>
      port.titles(NarrativeTitleKind.facts);

  String? factName(String id) {
    final titles = facts.value;
    final cached = _factNames;
    if (cached == null || !identical(cached.$1, titles)) {
      _factNames = (
        titles,
        {
          for (final fact in titles ?? const <NarrativeTitle>[])
            if (fact.title.trim().isNotEmpty) fact.id: fact.title,
        },
      );
    }
    return _factNames!.$2[id];
  }

  Future<List<NarrativeTitle>> _titles() =>
      port.titles(NarrativeTitleKind.events);

  Future<void> retry() => saved.load(_titles, changed, force: true);

  void sync() {
    final revision = source().revision;
    if (identical(revision, _revision)) return;
    _revision = revision;
    if (!saved.ready) return;
    unawaited(retry());
    if (usages.ready) unawaited(_loadFacts(force: true));
  }

  List<GameBehaviourRow> get rows {
    final current = source();
    final cached = _rows;
    if (cached != null &&
        identical(cached.$1, saved.value) &&
        identical(cached.$2, current.registry) &&
        identical(cached.$3, current.maps)) {
      return cached.$4;
    }
    final built = gameBehaviourRows(
      saved: saved.value ?? const [],
      source: current,
    );
    _rows = (saved.value, current.registry, current.maps, built);
    return built;
  }

  List<GameBehaviourGroup> groups({
    String Function(GameBehaviourRow row)? elementLabel,
  }) {
    final visible = filterGameBehaviours(
      rows,
      query: query,
      filters: filters,
      elementLabel: elementLabel,
    );
    return switch (grouping) {
      GameBehaviourGrouping.map => groupGameBehavioursByMap(visible, [
        for (final entry in source().maps) entry.id,
      ]),
      GameBehaviourGrouping.fact => groupGameBehavioursByFact(
        visible,
        facts: facts.value ?? const [],
        usages: usages.value ?? const {},
      ),
    };
  }

  GameBehaviourSummary? summary(GameBehaviourRow row) {
    final record = row.record;
    if (record == null) return null;
    return _summaries[record] ??= summarizeGameBehaviour(record, _scene);
  }

  SceneAsset? _scene(String id) {
    final scenes = source().scenes;
    final cached = _scenes;
    if (cached == null || !identical(cached.$1, scenes)) {
      _scenes = (scenes, {for (final scene in scenes) scene.id: scene});
    }
    return _scenes!.$2[id];
  }

  void search(String value) {
    query = value;
    changed();
  }

  void toggle(GameBehaviourFilter filter) {
    if (!filters.remove(filter)) filters.add(filter);
    changed();
  }

  void group(GameBehaviourGrouping value) {
    grouping = value;
    if (value == GameBehaviourGrouping.fact) unawaited(_loadFacts());
    changed();
  }

  Future<void> retryFacts() => _loadFacts(force: true);

  Future<void> _loadFacts({bool force = false}) {
    if (force) unawaited(facts.load(_factTitles, changed, force: true));
    return usages.load(
      () async {
        final titles = facts.value ?? await _factTitles();
        return port.factUsers([for (final fact in titles) fact.id]);
      },
      changed,
      force: force,
    );
  }

  Future<bool> reach(
    String id,
    Future<bool> Function(String id) navigate,
  ) async {
    refused.remove(id);
    await saved.load(_titles, changed, force: true);
    final present =
        saved.value?.any((title) => title.id == id) == true ||
        source().touched(id);
    if (present && await navigate(id)) return true;
    refused.add(id);
    changed();
    return false;
  }
}
