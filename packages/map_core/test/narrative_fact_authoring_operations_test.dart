import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Narrative fact authoring operations', () {
    test('adds a fact with a stable slug id without mutating manifest', () {
      final manifest = _manifest();

      final result = addNarrativeFact(
        manifest,
        label: 'Brume vue au port',
        description: 'Etat narratif lisible.',
        category: 'Port',
        defaultValue: true,
        tags: const ['brume'],
        legacyFlagName: 'story_flag.harbor_fog_seen',
      );

      expect(manifest.facts, isEmpty);
      expect(result.createdFact.id, 'fact_brume_vue_au_port');
      expect(result.createdFact.label, 'Brume vue au port');
      expect(result.createdFact.defaultValue, isTrue);
      expect(result.createdFact.legacyFlagName, 'story_flag.harbor_fog_seen');
      expect(result.updatedProject.facts, [result.createdFact]);
    });

    test('adds suffixed ids on collisions and rejects empty labels', () {
      final manifest = _manifest(
        facts: [
          NarrativeFactDefinition(
            id: 'fact_brume_vue_au_port',
            label: 'Brume vue au port',
          ),
        ],
      );

      final result = addNarrativeFact(
        manifest,
        label: 'Brume vue au port',
      );

      expect(result.createdFact.id, 'fact_brume_vue_au_port_2');
      expect(
        () => addNarrativeFact(manifest, label: '   '),
        throwsArgumentError,
      );
    });

    test('updates a fact without mutating other manifest data', () {
      final scene = _scene();
      final manifest = _manifest(
        facts: [
          NarrativeFactDefinition(id: 'fact_intro', label: 'Intro'),
        ],
        scenes: [scene],
      );

      final result = updateNarrativeFact(
        manifest,
        factId: 'fact_intro',
        label: 'Introduction terminée',
        description: 'La scène initiale est finie.',
        category: 'Progression',
        defaultValue: true,
        tags: const ['story', 'intro'],
        legacyFlagName: 'story_flag.intro_complete',
      );

      expect(manifest.facts.single.label, 'Intro');
      expect(result.updatedFact.label, 'Introduction terminée');
      expect(result.updatedFact.defaultValue, isTrue);
      expect(result.updatedProject.scenes, [scene]);
      expect(result.updatedProject.facts.single.tags, ['story', 'intro']);
    });

    test('removes an unreferenced fact and refuses referenced facts', () {
      final unreferenced = NarrativeFactDefinition(
        id: 'fact_unreferenced',
        label: 'Unreferenced',
      );
      final referenced = NarrativeFactDefinition(
        id: 'fact_referenced',
        label: 'Referenced',
      );
      final manifest = _manifest(
        facts: [unreferenced, referenced],
        scenes: [_sceneReferencingFact('fact_referenced')],
      );

      final result = removeNarrativeFact(
        manifest,
        factId: 'fact_unreferenced',
      );

      expect(result.removedFact, unreferenced);
      expect(result.updatedProject.facts, [referenced]);
      expect(manifest.facts, [unreferenced, referenced]);
      expect(
        () => removeNarrativeFact(manifest, factId: 'fact_referenced'),
        throwsArgumentError,
      );
      expect(
        () => removeNarrativeFact(manifest, factId: 'fact_unknown'),
        throwsArgumentError,
      );
    });
  });
}

ProjectManifest _manifest({
  List<NarrativeFactDefinition> facts = const [],
  List<SceneAsset> scenes = const [],
}) {
  return ProjectManifest(
    name: 'Facts test',
    maps: const [],
    tilesets: const [],
    facts: facts,
    scenes: scenes,
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

SceneAsset _sceneReferencingFact(String factId) {
  return SceneAsset(
    id: 'scene_fact',
    name: 'Scene fact',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'node_condition',
          kind: SceneNodeKind.condition,
          payload: SceneConditionPayload(
            conditionSource: SceneConditionSource(
              sourceKind: SceneConditionSourceKind.fact,
              sourceId: factId,
              operator: SceneConditionOperator.isTrue,
              label: 'Fact referenced',
            ),
          ),
        ),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: const [],
    ),
  );
}
