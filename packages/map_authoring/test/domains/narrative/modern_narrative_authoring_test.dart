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

    test('Event V2 registry mode is activated through the canonical action',
        () {
      final projected = const EventV2Actions().setRegistryMode(
        _manifest(),
        maps: const [],
        mode: EventSystemMode.dualRead,
      );

      expect(projected.eventRegistry?.mode, EventSystemMode.dualRead);
      expect(projected.eventRegistry?.records, isEmpty);
      expect(projected.eventRegistry?.legacyClaims, isEmpty);
    });

    test('Event V2 only mode refuses owned migration state', () {
      final project = _manifest(
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.legacyOnly,
          records: [
            NarrativeEventRecord.draft(
              NarrativeEventDraft(
                id: 'evt_018f0f8c-7b8a-7def-8000-000000000003',
                name: 'Owned event',
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
        () => const EventV2Actions().setRegistryMode(
          project,
          maps: const [],
          mode: EventSystemMode.v2Only,
        ),
        throwsA(
          isA<NarrativeAuthoringException>().having(
            (error) => error.code,
            'code',
            'event_v2.registry_mode_unsafe',
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
          'scene.character_animation.set',
          'event_v2.record_upsert',
          'event_v2.registry_mode.set',
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

    test('semantic Scene action sets a bounded character animation command',
        () {
      final command = CharacterCustomAnimationRuntimeCommand(
        actorId: 'player',
        definitionId: 'wave',
      );
      final projected = const SceneActions().setCharacterAnimationCommand(
        _manifest(scenes: <SceneAsset>[_scene()]),
        maps: const <MapData>[],
        sceneId: 'intro_scene',
        nodeId: 'action',
        command: command,
      );
      final action = projected.scenes.single.graph.nodes
          .singleWhere((node) => node.id == 'action')
          .payload as SceneActionPayload;

      expect(
        action.interactiveCommand,
        SceneInteractiveCommand.playCharacterAnimation(
          runtimeCommand: command,
        ),
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
      characterStudioCatalog: const ProjectCharacterStudioCatalog(
        customAnimationDefinitions: <CharacterCustomAnimationDefinition>[
          CharacterCustomAnimationDefinition(
            id: 'wave',
            displayName: 'Saluer',
            mode: CharacterCustomAnimationMode.single,
          ),
        ],
      ),
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
          SceneNode(
            id: 'action',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.interactive(
              SceneInteractiveCommand.openPc(),
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'start_action',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'action',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'action_end',
            fromNodeId: 'action',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted,
          ),
        ],
      ),
    );
