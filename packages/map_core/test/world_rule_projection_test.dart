import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('World rule projection', () {
    test('projects enabled matching fact rules without mutating inputs', () {
      final project = _manifest(
        facts: [
          NarrativeFactDefinition(id: 'fact_known', label: 'Known'),
        ],
        worldRules: [
          _entityRule(
            id: 'world_rule_hide',
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.entityHidden,
            ),
          ),
          _entityRule(
            id: 'world_rule_disabled',
            enabled: false,
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.entityVisible,
            ),
          ),
        ],
      );
      final state = GameState(
        saveId: 'save',
        storyFlags: const StoryFlags(activeFlags: {'fact_known'}),
      );

      final effects = projectWorldRuleEffects(
        project,
        state,
        maps: [_mapWithNpc()],
        mapId: 'map_test',
      );

      expect(effects, hasLength(1));
      expect(effects.single.ruleId, 'world_rule_hide');
      expect(effects.single.effect.kind, WorldRuleEffectKind.entityHidden);
      expect(project.worldRules, hasLength(2));
      expect(state.storyFlags.activeFlags, {'fact_known'});
    });

    test('supports story step completion and consumed event sources', () {
      final project = _manifest(
        storylines: [
          StorylineAsset(
            id: 'storyline_test',
            type: StorylineType.main,
            title: 'Storyline test',
            chapters: [
              StorylineChapter(
                id: 'chapter_test',
                title: 'Chapter test',
                order: 0,
                steps: [
                  StorylineStep(
                    id: 'step_intro',
                    title: 'Intro',
                    order: 0,
                  ),
                ],
              ),
            ],
          ),
        ],
        worldRules: [
          _eventRule(
            id: 'world_rule_step',
            source: const WorldRuleSource(
              kind: WorldRuleSourceKind.storyStepCompletion,
              sourceId: 'step_intro',
              predicate: WorldRuleSourcePredicate.completed,
            ),
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.eventEnabled,
            ),
          ),
          _eventRule(
            id: 'world_rule_consumed',
            source: const WorldRuleSource(
              kind: WorldRuleSourceKind.consumedEvent,
              sourceId: 'event_test',
              predicate: WorldRuleSourcePredicate.consumed,
            ),
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.eventHidden,
            ),
            priority: 2,
          ),
        ],
      );
      final state = GameState(
        saveId: 'save',
        progression: const PlayerProgression(
          completedStepIds: ['step_intro'],
        ),
        consumedEventIds: const {'event_test'},
      );

      final effects = projectWorldRuleEffects(
        project,
        state,
        maps: [_mapWithNpc()],
      );

      expect(
        effects.map((effect) => effect.ruleId),
        ['world_rule_step', 'world_rule_consumed'],
      );
      expect(
        effects.map((effect) => effect.effect.kind),
        [
          WorldRuleEffectKind.eventEnabled,
          WorldRuleEffectKind.eventHidden,
        ],
      );
    });

    test('skips invalid rules with diagnostic errors', () {
      final project = _manifest(
        facts: [
          NarrativeFactDefinition(id: 'fact_known', label: 'Known'),
        ],
        worldRules: [
          _entityRule(
            id: 'world_rule_valid',
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.entityVisible,
            ),
          ),
          WorldRuleDefinition(
            id: 'world_rule_invalid',
            label: 'Invalid',
            source: const WorldRuleSource(
              kind: WorldRuleSourceKind.fact,
              sourceId: 'fact_missing',
              predicate: WorldRuleSourcePredicate.isTrue,
            ),
            target: const WorldRuleTarget(
              kind: WorldRuleTargetKind.mapEntity,
              mapId: 'map_test',
              entityId: 'npc_test',
            ),
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.entityHidden,
            ),
          ),
        ],
      );
      final state = GameState(
        saveId: 'save',
        storyFlags: const StoryFlags(activeFlags: {'fact_known'}),
      );

      final effects = projectWorldRuleEffects(
        project,
        state,
        maps: [_mapWithNpc()],
      );

      expect(effects.map((effect) => effect.ruleId), ['world_rule_valid']);
    });
  });
}

ProjectManifest _manifest({
  List<NarrativeFactDefinition> facts = const [],
  List<StorylineAsset> storylines = const [],
  List<WorldRuleDefinition> worldRules = const [],
}) {
  return ProjectManifest(
    name: 'Projection project',
    maps: const [
      ProjectMapEntry(
        id: 'map_test',
        name: 'Map test',
        relativePath: 'maps/map_test.json',
      ),
    ],
    tilesets: const [],
    facts: facts,
    storylines: storylines,
    worldRules: worldRules,
  );
}

MapData _mapWithNpc() {
  return const MapData(
    id: 'map_test',
    name: 'Map test',
    size: GridSize(width: 10, height: 8),
    entities: [
      MapEntity(
        id: 'npc_test',
        name: 'NPC test',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 2, y: 3),
        npc: MapEntityNpcData(displayName: 'NPC test'),
      ),
    ],
    events: [
      MapEventDefinition(
        id: 'event_test',
        title: 'Event test',
        pages: [
          MapEventPage(pageNumber: 0),
        ],
        position: EventPosition(layerId: 'events', x: 1, y: 1),
      ),
    ],
  );
}

WorldRuleDefinition _entityRule({
  required String id,
  bool enabled = true,
  required WorldRuleEffect effect,
}) {
  return WorldRuleDefinition(
    id: id,
    label: id,
    enabled: enabled,
    source: const WorldRuleSource(
      kind: WorldRuleSourceKind.fact,
      sourceId: 'fact_known',
      predicate: WorldRuleSourcePredicate.isTrue,
    ),
    target: const WorldRuleTarget(
      kind: WorldRuleTargetKind.mapEntity,
      mapId: 'map_test',
      entityId: 'npc_test',
    ),
    effect: effect,
  );
}

WorldRuleDefinition _eventRule({
  required String id,
  required WorldRuleSource source,
  required WorldRuleEffect effect,
  int priority = 0,
}) {
  return WorldRuleDefinition(
    id: id,
    label: id,
    source: source,
    target: const WorldRuleTarget(
      kind: WorldRuleTargetKind.mapEvent,
      mapId: 'map_test',
      eventId: 'event_test',
    ),
    effect: effect,
    priority: priority,
  );
}
