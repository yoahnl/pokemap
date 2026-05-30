import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('World rule authoring operations', () {
    test('adds a world rule with stable id without mutating manifest', () {
      final manifest = _manifest(
        facts: [
          NarrativeFactDefinition(
            id: 'fact_actor_hidden',
            label: 'Acteur masque',
          ),
        ],
      );
      final map = _mapWithNpc();

      final result = addWorldRule(
        manifest,
        label: 'Masquer acteur apres fact',
        description: 'Projection visible du monde.',
        source: const WorldRuleSource(
          kind: WorldRuleSourceKind.fact,
          sourceId: 'fact_actor_hidden',
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
        priority: 3,
        tags: const ['world', 'world'],
        maps: [map],
      );

      expect(manifest.worldRules, isEmpty);
      expect(result.createdRule.id, 'world_rule_masquer_acteur_apres_fact');
      expect(result.createdRule.label, 'Masquer acteur apres fact');
      expect(result.createdRule.priority, 3);
      expect(result.createdRule.tags, ['world']);
      expect(result.updatedProject.worldRules, [result.createdRule]);
    });

    test('adds suffixed ids on collisions and rejects empty labels', () {
      final manifest = _manifest(
        facts: [
          NarrativeFactDefinition(id: 'fact_known', label: 'Known'),
        ],
        worldRules: [
          _rule(
            id: 'world_rule_same_label',
            label: 'Same label',
          ),
        ],
      );

      final result = addWorldRule(
        manifest,
        label: 'Same label',
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
        effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityVisible),
        maps: [_mapWithNpc()],
      );

      expect(result.createdRule.id, 'world_rule_same_label_2');
      expect(
        () => addWorldRule(
          manifest,
          label: '   ',
          source: _factSource('fact_known'),
          target: _entityTarget,
          effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden),
        ),
        throwsArgumentError,
      );
    });

    test('updates and removes a rule without mutating other project data', () {
      final existing = _rule(id: 'world_rule_existing', label: 'Existing');
      final scene = _scene();
      final manifest = _manifest(
        facts: [
          NarrativeFactDefinition(id: 'fact_known', label: 'Known'),
        ],
        scenes: [scene],
        worldRules: [existing],
      );

      final update = updateWorldRule(
        manifest,
        ruleId: existing.id,
        label: 'Updated rule',
        description: 'Updated description',
        source: _factSource('fact_known'),
        target: _entityTarget,
        effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityVisible),
        priority: 8,
        maps: [_mapWithNpc()],
      );

      expect(manifest.worldRules.single.label, 'Existing');
      expect(update.updatedRule.id, existing.id);
      expect(update.updatedRule.label, 'Updated rule');
      expect(update.updatedRule.priority, 8);
      expect(update.updatedProject.scenes, [scene]);

      final removal = removeWorldRule(
        update.updatedProject,
        ruleId: existing.id,
      );

      expect(removal.removedRule.id, existing.id);
      expect(removal.updatedProject.worldRules, isEmpty);
      expect(update.updatedProject.worldRules, [update.updatedRule]);
      expect(
        () => removeWorldRule(manifest, ruleId: 'unknown_rule'),
        throwsArgumentError,
      );
    });

    test('refuses unknown sources and structural target/effect mismatches', () {
      final manifest = _manifest();

      expect(
        () => addWorldRule(
          manifest,
          label: 'Unknown fact',
          source: _factSource('fact_missing'),
          target: _entityTarget,
          effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden),
          maps: [_mapWithNpc()],
        ),
        throwsArgumentError,
      );
      expect(
        () => addWorldRule(
          _manifest(
            facts: [
              NarrativeFactDefinition(id: 'fact_known', label: 'Known'),
            ],
          ),
          label: 'Bad predicate',
          source: const WorldRuleSource(
            kind: WorldRuleSourceKind.fact,
            sourceId: 'fact_known',
            predicate: WorldRuleSourcePredicate.completed,
          ),
          target: _entityTarget,
          effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden),
          maps: [_mapWithNpc()],
        ),
        throwsArgumentError,
      );
      expect(
        () => addWorldRule(
          _manifest(
            facts: [
              NarrativeFactDefinition(id: 'fact_known', label: 'Known'),
            ],
            dialogues: const [
              ProjectDialogueEntry(
                id: 'dialogue_known',
                name: 'Known',
                relativePath: 'dialogues/known.yarn',
              ),
            ],
          ),
          label: 'Mismatched effect',
          source: _factSource('fact_known'),
          target: _entityTarget,
          effect: const WorldRuleEffect(
            kind: WorldRuleEffectKind.npcDialogueOverride,
            dialogueId: 'dialogue_known',
          ),
          maps: [_mapWithNpc()],
        ),
        throwsArgumentError,
      );
    });
  });
}

ProjectManifest _manifest({
  List<NarrativeFactDefinition> facts = const [],
  List<ProjectDialogueEntry> dialogues = const [],
  List<SceneAsset> scenes = const [],
  List<WorldRuleDefinition> worldRules = const [],
}) {
  return ProjectManifest(
    name: 'World rules test',
    maps: const [
      ProjectMapEntry(
        id: 'map_test',
        name: 'Map test',
        relativePath: 'maps/map_test.json',
      ),
    ],
    tilesets: const [],
    dialogues: dialogues,
    facts: facts,
    scenes: scenes,
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

SceneAsset _scene() {
  return SceneAsset(
    id: 'scene_test',
    name: 'Scene test',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: const [],
    ),
  );
}

WorldRuleDefinition _rule({
  required String id,
  required String label,
}) {
  return WorldRuleDefinition(
    id: id,
    label: label,
    source: _factSource('fact_known'),
    target: _entityTarget,
    effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden),
  );
}

WorldRuleSource _factSource(String factId) {
  return WorldRuleSource(
    kind: WorldRuleSourceKind.fact,
    sourceId: factId,
    predicate: WorldRuleSourcePredicate.isTrue,
  );
}

const WorldRuleTarget _entityTarget = WorldRuleTarget(
  kind: WorldRuleTargetKind.mapEntity,
  mapId: 'map_test',
  entityId: 'npc_test',
);
