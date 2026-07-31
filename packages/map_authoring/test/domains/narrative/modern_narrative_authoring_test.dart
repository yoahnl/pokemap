import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('modern narrative authoring', () {
    test('publication gate uses canonical Scene and runtime diagnostics', () {
      final project = _manifest(
        scenes: [
          SceneAsset(
            id: 'broken_scene',
            name: 'Broken scene',
            graph: SceneGraph(
              startNodeId: 'start',
              nodes: [SceneNode(id: 'start', kind: SceneNodeKind.start)],
              edges: const [],
            ),
          ),
        ],
      );

      final report = const ModernNarrativeInspector().inspect(
        project: project,
        maps: [],
      );

      expect(report.canPublish, isFalse);
      expect(
        report.diagnostics.map((item) => item.code),
        contains('scene.missingEndNode'),
      );
      expect(
        report.runtimeConsumers.map((item) => item.authority),
        containsAll({
          'buildSceneRuntimePlan',
          'NarrativeEventDispatchAuthority',
          'projectWorldRuleEffects',
        }),
      );
    });

    test('Scene deletion is blocked by the canonical dependency index', () {
      final scene = _scene();
      final project = _manifest(
        scenes: [scene],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            NarrativeEventRecord.draft(
              NarrativeEventDraft(
                id: 'evt_018f0f8c-7b8a-7def-8000-000000000001',
                name: 'Uses scene',
                conditions: const [],
                sceneId: scene.id,
                priority: 0,
                order: 0,
              ),
            ),
          ],
          legacyClaims: const [],
        ),
      );

      expect(
        () => const SceneActions().delete(project, sceneId: scene.id),
        throwsA(
          isA<NarrativeAuthoringException>().having(
            (error) => error.code,
            'code',
            'sceneReferenced',
          ),
        ),
      );
    });

    test('Event V2 publication rejects an incomplete draft canonically', () {
      final project = _manifest(
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            NarrativeEventRecord.draft(
              NarrativeEventDraft(
                id: 'evt_018f0f8c-7b8a-7def-8000-000000000002',
                name: 'Incomplete',
                conditions: const [],
                priority: 0,
                order: 0,
              ),
            ),
          ],
          legacyClaims: const [],
        ),
      );

      expect(
        () => const EventV2Actions().publish(
          project,
          maps: const [],
          revision: 'revision-1',
          eventId: 'evt_018f0f8c-7b8a-7def-8000-000000000002',
        ),
        throwsA(
          isA<NarrativeAuthoringException>().having(
            (error) => error.code,
            'code',
            'sourceRequired',
          ),
        ),
      );
    });

    test('Fact type changes require a dependency-safe canonical preview', () {
      final fact = NarrativeFactDefinition(
        id: 'fact_gate',
        label: 'Gate',
      );
      final project = _manifest(
        facts: [fact],
        scenes: [
          SceneAsset(
            id: 'condition_scene',
            name: 'Condition scene',
            graph: SceneGraph(
              startNodeId: 'start',
              nodes: [
                SceneNode(id: 'start', kind: SceneNodeKind.start),
                SceneNode(
                  id: 'condition',
                  kind: SceneNodeKind.condition,
                  payload: SceneConditionPayload(
                    conditionSource: SceneConditionSource(
                      sourceKind: SceneConditionSourceKind.fact,
                      sourceId: fact.id,
                      operator: SceneConditionOperator.isTrue,
                    ),
                  ),
                ),
                SceneNode(id: 'end', kind: SceneNodeKind.end),
              ],
              edges: [
                SceneEdge(
                  id: 'start_condition',
                  fromNodeId: 'start',
                  fromPortId: 'completed',
                  toNodeId: 'condition',
                  kind: SceneEdgeKind.defaultFlow,
                ),
                SceneEdge(
                  id: 'condition_true',
                  fromNodeId: 'condition',
                  fromPortId: 'true',
                  toNodeId: 'end',
                  kind: SceneEdgeKind.conditionTrue,
                ),
                SceneEdge(
                  id: 'condition_false',
                  fromNodeId: 'condition',
                  fromPortId: 'false',
                  toNodeId: 'end',
                  kind: SceneEdgeKind.conditionFalse,
                ),
              ],
            ),
          ),
        ],
      );

      expect(
        () => const FactRuleActions().updateFact(
          project,
          maps: const [],
          fact: NarrativeFactDefinition(
            id: 'fact_gate',
            label: 'Gate',
            initialValue: NarrativeValue.integer(1),
          ),
        ),
        throwsA(isA<NarrativeAuthoringException>()),
      );
    });

    test('canonical dispatcher and reads expose modern narrative resources',
        () {
      final ids = AuthoringMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id)
          .toSet();
      expect(
        ids,
        containsAll({
          'scene.upsert',
          'scene.delete',
          'event_v2.record_upsert',
          'event_v2.publish',
          'event_v2.activate',
          'event_v2.deactivate',
          'event_v2.delete',
          'fact.create',
          'fact.update',
          'fact.delete',
          'world_rule.create',
          'world_rule.update',
          'world_rule.delete',
        }),
      );
      expect(
        AuthoringResourceKindRegistry.canonicalMinimal()
            .resourceKinds
            .map((kind) => kind.id),
        containsAll({'scene', 'eventV2', 'fact', 'worldRule'}),
      );
    });
  });
}

ProjectManifest _manifest({
  List<SceneAsset> scenes = const [],
  List<NarrativeFactDefinition> facts = const [],
  NarrativeEventRegistry? eventRegistry,
}) =>
    ProjectManifest(
      name: 'Modern narrative fixture',
      maps: const [],
      tilesets: const [],
      scenes: scenes,
      facts: facts,
      eventRegistry: eventRegistry,
    );

SceneAsset _scene() => SceneAsset(
      id: 'intro_scene',
      name: 'Intro scene',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'start_end',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      ),
    );
