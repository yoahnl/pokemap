import 'dart:async';

import 'package:map_core/map_core_domain.dart';

import '../../story_draft/domain/story_draft_entry.dart';
import '../domain/narrative_index_port.dart';
import 'game_memory_controller.dart';
import 'game_memory_resource.dart';
import 'world_rule_sentence.dart';

typedef GameMemoryCharacter = ({String id, String name});

typedef GameMemoryRuleCondition = ({
  String factId,
  NarrativeFactOperator operator,
  NarrativeValue value,
});

final class GameMemoryRuleRow {
  const GameMemoryRuleRow(this.rule, {this.unsaved = false});

  final WorldRuleDefinition rule;
  final bool unsaved;
}

List<GameMemoryCharacter> gameMemoryCharacters(MapData map) => [
  for (final entity in map.entities)
    if (entity.kind == MapEntityKind.npc)
      (
        id: entity.id,
        name: switch (entity.npc?.displayName.trim()) {
          final name? when name.isNotEmpty => name,
          _ => entity.name,
        },
      ),
]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

final class GameMemoryRules implements WorldRuleNames {
  GameMemoryRules(this._memory);

  final GameMemoryController _memory;
  final saved = GameMemoryResource<List<WorldRuleDefinition>>();
  String? selected;
  String? Function(String mapId)? mapName;

  Future<void> open() async {
    unawaited(_memory.names.ensure(NarrativeTitleKind.events));
    await saved.load(_memory.port.worldRules, _memory.changed);
  }

  Future<void> retry() =>
      saved.load(_memory.port.worldRules, _memory.changed, force: true);

  List<GameMemoryRuleRow> get rows {
    const kind = StoryDraftKind.worldRule;
    final draft = _memory.staging.draft;
    final ids = <String>{};
    return [
      for (final rule in saved.value ?? const <WorldRuleDefinition>[])
        if (ids.add(rule.id))
          if (draft.entryOf(kind, rule.id) case final entry)
            if (entry == null || entry.current != null)
              GameMemoryRuleRow(entry?.current ?? rule, unsaved: entry != null),
      for (final id in draft.touched(kind))
        if (!ids.contains(id))
          if (draft.entryOf(kind, id)?.current case final rule?)
            GameMemoryRuleRow(rule, unsaved: true),
    ];
  }

  WorldRuleDefinition? rule(String id) =>
      rows.where((row) => row.rule.id == id).firstOrNull?.rule;

  WorldRuleSentence sentence(WorldRuleDefinition rule) =>
      describeWorldRule(rule, this);

  void select(String id) {
    selected = id;
    _memory.section = GameMemorySection.rules;
    if (rule(id) case final value?
        when value.source.kind == WorldRuleSourceKind.fact) {
      _memory.reveal(value.source.sourceId);
    }
    unawaited(open());
    _memory.changed();
  }

  String? create({
    required String label,
    required GameMemoryRuleCondition condition,
    required ProjectMapEntry map,
    required GameMemoryCharacter character,
    required bool visible,
  }) {
    final fact = _memory.current(condition.factId);
    if (!_memory.staging.editable || fact == null) return null;
    final created = addWorldRule(
      ProjectManifest(
        name: 'rules',
        maps: [map],
        tilesets: const [],
        facts: [fact],
        worldRules: [for (final row in rows) row.rule],
      ),
      label: label,
      source: _source(condition),
      target: WorldRuleTarget(
        kind: WorldRuleTargetKind.mapEntity,
        mapId: map.id,
        entityId: character.id,
        label: character.name,
      ),
      effect: WorldRuleEffect(
        kind: visible
            ? WorldRuleEffectKind.entityVisible
            : WorldRuleEffectKind.entityHidden,
      ),
    ).createdRule;
    _memory.staging.stage((draft) {
      draft.load(StoryDraftKind.worldRule, created.id, null);
      draft.put(StoryDraftKind.worldRule, created);
    });
    select(created.id);
    return created.id;
  }

  bool update(
    String id, {
    String? label,
    bool? enabled,
    GameMemoryRuleCondition? condition,
    WorldRuleEffectKind? effect,
  }) {
    final before = rule(id);
    if (!_memory.staging.editable || before == null) return false;
    final nextEffect = effect ?? before.effect.kind;
    if (!isWorldRuleEffectCompatibleWithTarget(
      before.target.kind,
      nextEffect,
    )) {
      return false;
    }
    final nextLabel = label?.trim();
    final next = WorldRuleDefinition(
      id: id,
      label: nextLabel == null || nextLabel.isEmpty ? before.label : nextLabel,
      description: before.description,
      enabled: enabled ?? before.enabled,
      source: condition == null ? before.source : _source(condition),
      target: before.target,
      effect: nextEffect == before.effect.kind
          ? before.effect
          : WorldRuleEffect(kind: nextEffect),
      priority: before.priority,
      tags: before.tags,
      debugTechnicalLabel: before.debugTechnicalLabel,
    );
    if (next == before) return true;
    final stored = saved.value?.where((rule) => rule.id == id).firstOrNull;
    if (stored != null) _memory.staging.rememberRule(stored);
    _memory.staging.stage((draft) {
      if (!draft.isLoaded(StoryDraftKind.worldRule, id)) {
        draft.load(StoryDraftKind.worldRule, id, stored);
      }
      draft.put(StoryDraftKind.worldRule, next);
    });
    return true;
  }

  WorldRuleSource _source(GameMemoryRuleCondition condition) {
    final kind = _memory.current(condition.factId)?.valueKind;
    final fits = kind == null || kind == condition.value.kind;
    return WorldRuleSource.factValue(
      factId: condition.factId,
      operator: fits ? condition.operator : NarrativeFactOperator.equals,
      expectedValue: fits
          ? condition.value
          : kind == NarrativeValueKind.integer
          ? NarrativeValue.integer(0)
          : const NarrativeValue.boolean(true),
    );
  }

  @override
  String? fact(String id) => _memory.current(id)?.label ?? _title(id);

  String? _title(String id) => switch (_memory.facts.value
      ?.where((title) => title.id == id)
      .firstOrNull
      ?.title
      .trim()) {
    final title? when title.isNotEmpty => title,
    _ => null,
  };

  @override
  String? event(String id) => _memory.names.name(NarrativeTitleKind.events, id);

  @override
  String? map(String id) => mapName?.call(id);
}
