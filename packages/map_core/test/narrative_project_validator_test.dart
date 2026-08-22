import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _eventA = 'evt_019abcde-4000-7000-8000-000000000071';
const _eventB = 'evt_019abcde-4000-7000-8000-000000000072';
const _eventC = 'evt_019abcde-4000-7000-8000-000000000073';

void main() {
  group('interpolation references in authored player text',
      _presentationTextReferenceTests);

  group('Narrative project validator', () {
    test('aggregates a playable project and exposes its map Event view', () {
      final fixture = _fixture();

      final report = validateNarrativeProject(
        fixture.project,
        maps: [fixture.map],
      );

      expect(report.isPlayable, isTrue);
      expect(report.errorCount, 0);
      expect(report.mapEventViews, hasLength(1));
      final mapView = report.mapEventViews.single;
      expect(mapView.mapId, 'map_port');
      expect(mapView.events, hasLength(1));
      expect(mapView.events.single.eventId, _eventA);
      expect(mapView.events.single.sourceConnected, isTrue);
      expect(mapView.events.single.sourceEntityKind, MapEntityKind.npc);
      expect(mapView.events.single.sourceOwnerLabel, 'Guide');
      expect(mapView.events.single.sceneConnected, isTrue);
      expect(mapView.events.single.sceneLabel, 'Introduction');
      expect(mapView.events.single.conditionCount, 0);
    });

    test('reports an impossible Step and a required Fact never produced', () {
      final fixture = _fixture(
        completeStep: false,
        requireFact: true,
      );

      final report = validateNarrativeProject(
        fixture.project,
        maps: [fixture.map],
      );

      expect(report.isPlayable, isFalse);
      expect(
        report.byCode('storylineStepNeverCompleted').single.stepId,
        'step_intro',
      );
      final factDiagnostic = report.byCode('requiredFactNeverProduced').single;
      expect(factDiagnostic.factId, 'fact_gate');
      expect(
        factDiagnostic.destination,
        NarrativeProjectDiagnosticDestination.fact,
      );
      expect(
        report.byDomain(NarrativeProjectDiagnosticDomain.storyline),
        isNotEmpty,
      );
    });

    test('ignores Fact producers that are unreachable inside a Scene', () {
      final fixture = _fixture(requireFact: true);
      final scene = fixture.project.scenes.single;
      final unreachableProducer = SceneNode(
        id: 'unreachable_fact',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.setFact(factId: 'fact_gate', value: true),
        ),
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          scenes: [
            SceneAsset(
              id: scene.id,
              name: scene.name,
              description: scene.description,
              storylineId: scene.storylineId,
              chapterId: scene.chapterId,
              tags: scene.tags,
              graph: SceneGraph(
                startNodeId: scene.graph.startNodeId,
                nodes: [...scene.graph.nodes, unreachableProducer],
                edges: scene.graph.edges,
              ),
              declaredOutcomes: scene.declaredOutcomes,
              metadata: scene.metadata,
            ),
          ],
        ),
        maps: [fixture.map],
      );

      expect(report.byCode('requiredFactNeverProduced'), hasLength(1));
    });

    test('does not let an Event unlock itself with its own Scene Fact', () {
      final fixture = _fixture(requireFact: true);
      final scene = fixture.project.scenes.single;
      final selfProducer = SceneNode(
        id: 'self_fact',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.setFact(factId: 'fact_gate', value: true),
        ),
      );
      final selfGatedScene = SceneAsset(
        id: scene.id,
        name: scene.name,
        graph: SceneGraph(
          startNodeId: scene.graph.startNodeId,
          nodes: [...scene.graph.nodes, selfProducer],
          edges: [
            SceneEdge(
              id: 'start_self_fact',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'self_fact',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'self_fact_complete',
              fromNodeId: 'self_fact',
              fromPortId: 'completed',
              toNodeId: 'complete_step',
              kind: SceneEdgeKind.actionCompleted,
            ),
            ...scene.graph.edges.where(
              (edge) => edge.id != 'start_action',
            ),
          ],
        ),
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(scenes: [selfGatedScene]),
        maps: [fixture.map],
      );

      expect(report.byCode('requiredFactNeverProduced'), hasLength(1));
      expect(report.byCode('storylineStepInaccessible'), hasLength(1));
    });

    test(
        'does not apply Storyline effects from an outcome the reachable Scene cannot emit',
        () {
      final fixture = _fixture(
        completeStep: false,
        requireFact: true,
      );
      final scene = _outcomeScene(
        id: 'scene_intro',
        emittedOutcomeId: 'available_outcome',
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          scenes: [scene],
          eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: [
              _record(id: _eventA, entityId: 'npc_guide'),
              _record(
                id: _eventB,
                entityId: 'npc_guide',
                conditions: [NarrativeEventCondition.fact('fact_gate', true)],
              ),
            ],
            legacyClaims: const [],
          ),
          storylines: [
            _storylineWithOutcomeEffects(
              base: fixture.project.storylines.single,
              sceneId: scene.id,
              outcomeId: 'impossible_outcome',
            ),
          ],
        ),
        maps: [fixture.map],
      );

      expect(report.byCode('requiredFactNeverProduced'), hasLength(1));
      expect(report.byCode('storylineStepNeverCompleted'), hasLength(1));
    });

    test('does not apply Storyline effects from an unreachable Scene producer',
        () {
      final fixture = _fixture(
        completeStep: false,
        requireFact: true,
      );
      final hiddenScene = _outcomeScene(
        id: 'scene_hidden',
        emittedOutcomeId: 'completed',
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          scenes: [...fixture.project.scenes, hiddenScene],
          storylines: [
            _storylineWithOutcomeEffects(
              base: fixture.project.storylines.single,
              sceneId: hiddenScene.id,
              outcomeId: 'completed',
            ),
          ],
        ),
        maps: [fixture.map],
      );

      expect(report.byCode('requiredFactNeverProduced'), hasLength(1));
      expect(report.byCode('storylineStepNeverCompleted'), hasLength(1));
    });

    test('applies Storyline effects from an exact reachable Scene outcome', () {
      final fixture = _fixture(
        completeStep: false,
        requireFact: true,
      );
      final scene = _outcomeScene(
        id: 'scene_intro',
        emittedOutcomeId: 'completed',
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          scenes: [scene],
          eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: [
              _record(id: _eventA, entityId: 'npc_guide'),
              _record(
                id: _eventB,
                entityId: 'npc_guide',
                conditions: [NarrativeEventCondition.fact('fact_gate', true)],
              ),
            ],
            legacyClaims: const [],
          ),
          storylines: [
            _storylineWithOutcomeEffects(
              base: fixture.project.storylines.single,
              sceneId: scene.id,
              outcomeId: 'completed',
            ),
          ],
        ),
        maps: [fixture.map],
      );

      expect(report.byCode('requiredFactNeverProduced'), isEmpty);
      expect(report.byCode('storylineStepNeverCompleted'), isEmpty);
    });

    test('legacy reachability stops at the first applicable disabled page', () {
      final fixture = _fixture(
        completeStep: false,
        requireFact: true,
      );
      final hiddenProducer = _factProducingScene('scene_legacy_hidden');
      final map = fixture.map.copyWith(
        events: [
          MapEventDefinition(
            id: 'legacy_gate',
            pages: const [
              MapEventPage(pageNumber: 0, isDisabled: true),
              MapEventPage(
                pageNumber: 1,
                sceneTarget: MapEventSceneTarget(
                  sceneId: 'scene_legacy_hidden',
                ),
              ),
            ],
            position: const EventPosition(layerId: 'events', x: 5, y: 5),
          ),
        ],
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          scenes: [...fixture.project.scenes, hiddenProducer],
        ),
        maps: [map],
      );

      expect(report.byCode('requiredFactNeverProduced'), hasLength(1));
    });

    test(
        'legacy reachability keeps the fallback when a typed Fact condition can become false',
        () {
      final fixture = _fixture(completeStep: false);
      final map = fixture.map.copyWith(
        events: [
          MapEventDefinition(
            id: 'legacy_conditional_gate',
            pages: [
              MapEventPage(
                pageNumber: 0,
                condition: ScriptConditionFactory.factEquals(
                  'fact_gate',
                  const NarrativeValue.boolean(true),
                ),
                isDisabled: true,
              ),
              const MapEventPage(
                pageNumber: 1,
                sceneTarget: MapEventSceneTarget(
                  sceneId: 'scene_legacy_fallback',
                ),
              ),
            ],
            position: const EventPosition(layerId: 'events', x: 5, y: 5),
          ),
        ],
      );
      final project = fixture.project.copyWith(
        facts: [
          NarrativeFactDefinition(
            id: 'fact_gate',
            label: 'Gate initially open',
            defaultValue: true,
          ),
          NarrativeFactDefinition(
            id: 'fact_unlock',
            label: 'Fallback reached',
          ),
        ],
        scenes: [
          _factScene(
            id: 'scene_intro',
            factId: 'fact_gate',
            value: false,
          ),
          _factScene(
            id: 'scene_legacy_fallback',
            factId: 'fact_unlock',
            value: true,
          ),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            _record(id: _eventA, entityId: 'npc_guide'),
            _record(
              id: _eventB,
              entityId: 'npc_guide',
              conditions: [
                NarrativeEventCondition.fact('fact_unlock', true),
              ],
            ),
          ],
          legacyClaims: const [],
        ),
      );

      final report = validateNarrativeProject(project, maps: [map]);

      expect(report.byCode('requiredFactNeverProduced'), isEmpty);
    });

    test('legacy reachability does not invent a jointly impossible fallback',
        () {
      final fixture = _fixture(completeStep: false);
      final map = fixture.map.copyWith(
        events: [
          MapEventDefinition(
            id: 'legacy_exhaustive_gate',
            pages: [
              MapEventPage(
                pageNumber: 0,
                condition: ScriptConditionFactory.flagIsSet('fact_gate'),
              ),
              MapEventPage(
                pageNumber: 1,
                condition: ScriptConditionFactory.flagIsUnset('fact_gate'),
              ),
              const MapEventPage(
                pageNumber: 2,
                sceneTarget: MapEventSceneTarget(
                  sceneId: 'scene_impossible_fallback',
                ),
              ),
            ],
            position: const EventPosition(layerId: 'events', x: 5, y: 5),
          ),
        ],
      );
      final project = fixture.project.copyWith(
        facts: [
          NarrativeFactDefinition(
            id: 'fact_gate',
            label: 'Gate',
            defaultValue: true,
          ),
          NarrativeFactDefinition(
            id: 'fact_unlock',
            label: 'Impossible fallback',
          ),
        ],
        scenes: [
          _factScene(
            id: 'scene_intro',
            factId: 'fact_gate',
            value: false,
          ),
          _factScene(
            id: 'scene_impossible_fallback',
            factId: 'fact_unlock',
            value: true,
          ),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            _record(id: _eventA, entityId: 'npc_guide'),
            _record(
              id: _eventB,
              entityId: 'npc_guide',
              conditions: [
                NarrativeEventCondition.fact('fact_unlock', true),
              ],
            ),
          ],
          legacyClaims: const [],
        ),
      );

      final report = validateNarrativeProject(project, maps: [map]);

      expect(report.byCode('requiredFactNeverProduced'), hasLength(1));
    });

    test('legacy reachability fails closed within a bounded state search', () {
      final fixture = _fixture(completeStep: false);
      final branchingFactIds = [
        for (var index = 0; index < 14; index++) 'fact_branch_$index',
      ];
      final map = fixture.map.copyWith(
        events: [
          MapEventDefinition(
            id: 'legacy_large_condition_gate',
            pages: [
              MapEventPage(
                pageNumber: 0,
                condition: ScriptConditionFactory.anyOf([
                  for (final factId in branchingFactIds)
                    ScriptConditionFactory.flagIsUnset(factId),
                ]),
                isDisabled: true,
              ),
              const MapEventPage(
                pageNumber: 1,
                sceneTarget: MapEventSceneTarget(
                  sceneId: 'scene_large_condition_fallback',
                ),
              ),
            ],
            position: const EventPosition(layerId: 'events', x: 5, y: 5),
          ),
        ],
      );
      final project = fixture.project.copyWith(
        facts: [
          for (final factId in branchingFactIds)
            NarrativeFactDefinition(id: factId, label: factId),
          NarrativeFactDefinition(
            id: 'fact_unlock',
            label: 'Large fallback reached',
          ),
        ],
        scenes: [
          ...fixture.project.scenes,
          _manyFactScene('scene_many_fact_values', branchingFactIds),
          _factScene(
            id: 'scene_large_condition_fallback',
            factId: 'fact_unlock',
            value: true,
          ),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            ...fixture.project.eventRegistry!.records,
            _record(
              id: _eventC,
              entityId: 'npc_guide',
              sceneId: 'scene_many_fact_values',
            ),
            _record(
              id: _eventB,
              entityId: 'npc_guide',
              conditions: [
                NarrativeEventCondition.fact('fact_unlock', true),
              ],
            ),
          ],
          legacyClaims: const [],
        ),
      );

      final report = validateNarrativeProject(project, maps: [map]);

      expect(report.byCode('requiredFactNeverProduced'), hasLength(1));
    });

    test('does not traverse a statically impossible Scene condition port', () {
      final fixture = _fixture(completeStep: false);
      final project = fixture.project.copyWith(
        facts: [
          NarrativeFactDefinition(id: 'fact_never', label: 'Never true'),
          NarrativeFactDefinition(id: 'fact_unlock', label: 'Unlock'),
        ],
        scenes: [
          _conditionalFactScene(
            conditionFactId: 'fact_never',
            trueFactId: 'fact_unlock',
          ),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            _record(id: _eventA, entityId: 'npc_guide'),
            _record(
              id: _eventB,
              entityId: 'npc_guide',
              conditions: [
                NarrativeEventCondition.fact('fact_unlock', true),
              ],
            ),
          ],
          legacyClaims: const [],
        ),
      );

      final report = validateNarrativeProject(project, maps: [fixture.map]);

      expect(report.byCode('requiredFactNeverProduced'), hasLength(1));
    });

    test('does not emit an outcome behind an impossible Scene condition port',
        () {
      final fixture = _fixture(completeStep: false);
      final project = fixture.project.copyWith(
        facts: [
          NarrativeFactDefinition(id: 'fact_never', label: 'Never true'),
          NarrativeFactDefinition(id: 'fact_unlock', label: 'Unlock'),
        ],
        scenes: [
          _conditionalOutcomeScene(conditionFactId: 'fact_never'),
          _factScene(
            id: 'scene_outcome_consumer',
            factId: 'fact_unlock',
            value: true,
          ),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            _record(id: _eventA, entityId: 'npc_guide'),
            NarrativeEventRecord.configuredStructurallyUnchecked(
              NarrativeEventDefinition(
                id: _eventB,
                name: 'Impossible outcome consumer',
                source: NarrativeEventSourceRef.outcomeReceived(
                  NarrativeOutcomeRef(
                    producerKind: NarrativeOutcomeProducerKind.scene,
                    producerId: 'scene_intro',
                    outcomeId: 'success',
                  ),
                ),
                conditions: const [],
                sceneId: 'scene_outcome_consumer',
                reusePolicy: NarrativeEventReusePolicy.oneShot,
                priority: 0,
                order: 1,
              ),
              enabled: true,
            ),
            _record(
              id: _eventC,
              entityId: 'npc_guide',
              conditions: [
                NarrativeEventCondition.fact('fact_unlock', true),
              ],
            ),
          ],
          legacyClaims: const [],
        ),
      );

      final report = validateNarrativeProject(project, maps: [fixture.map]);

      expect(report.byCode('requiredFactNeverProduced'), hasLength(1));
    });

    test('reports a missing configured New Game start spawn on its map', () {
      final fixture = _fixture();

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          newGame: const ProjectNewGameConfig(
            enabled: true,
            startMapId: 'map_port',
            startSpawnId: 'spawn_missing',
          ),
        ),
        maps: [fixture.map],
      );

      final diagnostic =
          report.byCode('runtimeNewGameStartSpawnMissing').single;
      expect(diagnostic.severity, NarrativeProjectDiagnosticSeverity.error);
      expect(diagnostic.destination, NarrativeProjectDiagnosticDestination.map);
      expect(diagnostic.mapId, 'map_port');
      expect(diagnostic.path, contains('spawn_missing'));
    });

    test('reports a configured New Game start entity that is not playerStart',
        () {
      final fixture = _fixture();

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          newGame: const ProjectNewGameConfig(
            enabled: true,
            startMapId: 'map_port',
            startSpawnId: 'npc_guide',
          ),
        ),
        maps: [fixture.map],
      );

      final diagnostic =
          report.byCode('runtimeNewGameStartSpawnNotPlayerStart').single;
      expect(diagnostic.destination, NarrativeProjectDiagnosticDestination.map);
      expect(diagnostic.mapId, 'map_port');
    });

    test('reports a configured New Game start spawn outside map bounds', () {
      final fixture = _fixture();
      final map = fixture.map.copyWith(
        entities: [
          for (final entity in fixture.map.entities)
            if (entity.id == 'spawn_player')
              entity.copyWith(pos: const GridPos(x: 16, y: 1))
            else
              entity,
        ],
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          newGame: const ProjectNewGameConfig(
            enabled: true,
            startMapId: 'map_port',
            startSpawnId: 'spawn_player',
          ),
        ),
        maps: [map],
      );

      final diagnostic =
          report.byCode('runtimeNewGameStartSpawnOutOfBounds').single;
      expect(diagnostic.destination, NarrativeProjectDiagnosticDestination.map);
      expect(diagnostic.mapId, 'map_port');
    });

    test('accepts an in-bounds configured playerStart spawn', () {
      final fixture = _fixture();

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          newGame: const ProjectNewGameConfig(
            enabled: true,
            startMapId: 'map_port',
            startSpawnId: 'spawn_player',
          ),
        ),
        maps: [fixture.map],
      );

      expect(report.byCode('runtimeNewGameStartSpawnMissing'), isEmpty);
      expect(report.byCode('runtimeNewGameStartSpawnNotPlayerStart'), isEmpty);
      expect(report.byCode('runtimeNewGameStartSpawnOutOfBounds'), isEmpty);
    });

    test('reports an unknown trainer referenced only by a Scene battle', () {
      final fixture = _fixture();

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          scenes: [
            _battleScene(
              battleKind: 'trainer',
              trainerId: 'trainer_missing',
            ),
          ],
        ),
        maps: [fixture.map],
      );

      final diagnostic = report.byCode('battleTrainerRefUnknown').single;
      expect(
          diagnostic.destination, NarrativeProjectDiagnosticDestination.scene);
      expect(diagnostic.sceneId, 'scene_intro');
    });

    test('reports an empty Scene-only static boss team', () {
      final fixture = _fixture();

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          scenes: [
            _battleScene(
              battleKind: 'static',
              trainerId: 'trainer_boss',
            ),
          ],
          trainers: const [
            ProjectTrainerEntry(
              id: 'trainer_boss',
              name: 'Gardien',
              trainerClass: 'Static boss',
            ),
          ],
        ),
        maps: [fixture.map],
      );

      final diagnostic = report.byCode('sceneBattleTrainerHasEmptyTeam').single;
      expect(diagnostic.severity, NarrativeProjectDiagnosticSeverity.error);
      expect(
          diagnostic.destination, NarrativeProjectDiagnosticDestination.scene);
      expect(diagnostic.sceneId, 'scene_intro');
    });

    test('reports missing authoritative species and moves in a Scene opponent',
        () {
      final fixture = _fixture();

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          scenes: [
            _battleScene(
              battleKind: 'trainer',
              trainerId: 'trainer_invalid_team',
            ),
          ],
          trainers: const [
            ProjectTrainerEntry(
              id: 'trainer_invalid_team',
              name: 'Dresseur incomplet',
              trainerClass: 'Trainer',
              team: [
                ProjectTrainerPokemonEntry(speciesId: '', level: 5),
              ],
            ),
          ],
        ),
        maps: [fixture.map],
      );

      expect(
        report.byCode('sceneBattleTrainerPokemonMissingSpecies'),
        hasLength(1),
      );
      expect(
        report.byCode('sceneBattleTrainerPokemonMissingMoves'),
        hasLength(1),
      );
    });

    test('reports unknown catalog IDs in a Scene-only opponent', () {
      final fixture = _fixture();

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          scenes: [
            _battleScene(
              battleKind: 'trainer',
              trainerId: 'trainer_unknown_catalog_ids',
            ),
          ],
          trainers: const [
            ProjectTrainerEntry(
              id: 'trainer_unknown_catalog_ids',
              name: 'Dresseur invalide',
              trainerClass: 'Trainer',
              team: [
                ProjectTrainerPokemonEntry(
                  speciesId: 'missing_species',
                  level: 5,
                  moves: ['missing_move'],
                ),
              ],
            ),
          ],
        ),
        maps: [fixture.map],
        knownSpeciesIds: const {'bulbasaur'},
        knownMoveIds: const {'tackle'},
      );

      expect(
        report.byCode('sceneBattleTrainerPokemonSpeciesUnknown'),
        hasLength(1),
      );
      expect(
        report.byCode('sceneBattleTrainerPokemonMoveUnknown'),
        hasLength(1),
      );
    });

    test('reports unknown catalog IDs in every New Game starter option', () {
      final fixture = _fixture();
      final project = fixture.project.copyWith(
        newGame: ProjectNewGameConfig(
          enabled: true,
          startMapId: fixture.map.id,
          starterOptions: const [
            ProjectStarterOption(
              id: 'starter_missing',
              label: 'Starter invalide',
              pokemon: PlayerPokemon(
                speciesId: 'missing_species',
                natureId: 'hardy',
                abilityId: 'missing_ability',
                knownMoveIds: ['missing_move'],
                level: 5,
                currentHp: 20,
              ),
            ),
          ],
        ),
      );

      final report = validateNarrativeProject(
        project,
        maps: [fixture.map],
        knownSpeciesIds: const <String>{},
        knownMoveIds: const <String>{},
      );

      expect(report.byCode('runtimeMissingPokemonSpecies'), hasLength(1));
      expect(report.byCode('runtimeMissingPokemonMove'), hasLength(1));
    });

    test('fails closed when required Pokemon catalogs were not loaded', () {
      final fixture = _fixture();

      final report = validateNarrativeProject(
        fixture.project,
        maps: [fixture.map],
        requirePokemonCatalogs: true,
      );

      expect(
        report.byCode('runtimePokemonSpeciesCatalogUnavailable'),
        hasLength(1),
      );
      expect(
        report.byCode('runtimePokemonMoveCatalogUnavailable'),
        hasLength(1),
      );
    });

    test('reports a dependency cycle as an impossible narrative branch', () {
      final fixture = _fixture(eventDependencyCycle: true);

      final report = validateNarrativeProject(
        fixture.project,
        maps: [fixture.map],
      );

      expect(report.isPlayable, isFalse);
      expect(
        report.diagnostics.any(
          (diagnostic) =>
              diagnostic.domain == NarrativeProjectDiagnosticDomain.event &&
              diagnostic.code.toLowerCase().contains('cycle'),
        ),
        isTrue,
      );
    });

    test('keeps an orphaned map source visible and navigable', () {
      final fixture = _fixture(orphanSource: true);

      final report = validateNarrativeProject(
        fixture.project,
        maps: [fixture.map],
      );

      final event = report.mapEventViews.single.events.single;
      expect(event.sourceConnected, isFalse);
      expect(event.sourceOwnerId, 'npc_missing');
      expect(event.diagnosticCount, greaterThan(0));
      final diagnostic = report.diagnostics.firstWhere(
        (item) => item.eventId == _eventA && item.mapId == 'map_port',
      );
      expect(diagnostic.destination, NarrativeProjectDiagnosticDestination.map);
    });

    test('reports Storylines without a beginning or an ending', () {
      final fixture = _fixture();
      final emptyStoryline = StorylineAsset(
        id: 'story_empty',
        type: StorylineType.sideQuest,
        status: StorylineStatus.active,
        title: 'Quête vide',
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          storylines: [...fixture.project.storylines, emptyStoryline],
        ),
        maps: [fixture.map],
      );

      expect(report.byCode('storylineMissingBeginning'), hasLength(1));
      expect(report.byCode('storylineMissingEnding'), hasLength(1));
      expect(
        report.byCode('storylineImpossible').single.storylineId,
        'story_empty',
      );
    });

    test('keeps a superseded Global Story authoring Scenario as a warning only',
        () {
      final fixture = _fixture();
      const legacyAuthoringGraph = ScenarioAsset(
        id: 'global_story',
        name: 'Global Story',
        scope: ScenarioScope.globalStory,
        entryNodeId: 'start',
        nodes: [
          ScenarioNode(id: 'start', type: ScenarioNodeType.start),
          ScenarioNode(id: 'end', type: ScenarioNodeType.end),
        ],
        edges: [
          ScenarioEdge(
            id: 'start_end',
            fromNodeId: 'start',
            toNodeId: 'end',
          ),
        ],
        metadata: {
          'authoring.globalStoryStudioSchema': 'global_story_studio_v1.1',
        },
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(scenarios: const [legacyAuthoringGraph]),
        maps: [fixture.map],
      );

      final diagnostic = report.byCode('scenarioGraphHasNoSource').single;
      expect(
        diagnostic.severity,
        NarrativeProjectDiagnosticSeverity.warning,
      );
      expect(report.isPlayable, isTrue);
    });

    test('reports a one-shot Event that owns an explicitly retryable ending',
        () {
      final fixture = _fixture();
      final retryableScene = _withEndPolicy(
        fixture.project.scenes.single,
        sceneOutcomeId: 'the_player_may_continue',
        policy: SceneOutcomePolicy.retryable,
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(scenes: [retryableScene]),
        maps: [fixture.map],
      );

      final diagnostic =
          report.byCode('oneShotRetryableOutcomeSoftlock').single;
      expect(diagnostic.eventId, _eventA);
      expect(diagnostic.sceneId, retryableScene.id);
      expect(diagnostic.severity, NarrativeProjectDiagnosticSeverity.error);
    });

    test('accepts a narratively reachable reusable source for retry', () {
      final fixture = _fixture();
      final retryableScene = _withEndPolicy(
        fixture.project.scenes.single,
        sceneOutcomeId: 'try_again',
        policy: SceneOutcomePolicy.retryable,
      );
      final reusableRetry = _record(
        id: _eventB,
        entityId: 'npc_guide',
        reusePolicy: NarrativeEventReusePolicy.reusable,
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(
          scenes: [retryableScene],
          eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: [
              ...fixture.project.eventRegistry!.records,
              reusableRetry,
            ],
            legacyClaims: const [],
          ),
        ),
        maps: [fixture.map],
      );

      expect(report.byCode('oneShotRetryableOutcomeSoftlock'), isEmpty);
    });

    test('accepts an explicitly terminal failure without a retry source', () {
      final fixture = _fixture();
      final terminalScene = _withEndPolicy(
        fixture.project.scenes.single,
        sceneOutcomeId: 'permanent_failure',
        policy: SceneOutcomePolicy.terminalFailureAccepted,
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(scenes: [terminalScene]),
        maps: [fixture.map],
      );

      expect(report.byCode('oneShotRetryableOutcomeSoftlock'), isEmpty);
      expect(report.byCode('sceneOutcomePolicyIndeterminate'), isEmpty);
    });

    test('keeps an unannotated outcome indeterminate without label heuristics',
        () {
      final fixture = _fixture();
      final unannotated = _withEndPolicy(
        fixture.project.scenes.single,
        sceneOutcomeId: 'defeat_retry_softlock',
        policy: null,
      );

      final report = validateNarrativeProject(
        fixture.project.copyWith(scenes: [unannotated]),
        maps: [fixture.map],
      );

      final diagnostic =
          report.byCode('sceneOutcomePolicyIndeterminate').single;
      expect(diagnostic.sceneId, unannotated.id);
      expect(diagnostic.severity, NarrativeProjectDiagnosticSeverity.warning);
      expect(report.byCode('oneShotRetryableOutcomeSoftlock'), isEmpty);
    });
  });
}


/// BETA-CIN-086 — un placeholder malformé ne doit plus atteindre un joueur.
///
/// L'interpolateur laisse littérale toute référence qu'il ne reconnaît pas,
/// exprès. Mais rien ne relisait ce texte avant la certification, et la fixture
/// Night Watch a été packagée, certifiée, installée et jouée avec
/// `{draft.playerName}` affiché brut. Le Validator regarde maintenant.
void _presentationTextReferenceTests() {
  SceneAsset sceneWithPrompt(String fallbackText) => SceneAsset(
        id: 'presession',
        name: 'Pre-session',
        executionProfile: SceneExecutionProfile.preSession,
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: <SceneNode>[
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'confirm',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload(
                preSessionInteraction:
                    ScenePreSessionInteractionSpec.confirmation(
                  prompt: SceneInteractionPrompt(
                    localizationKey: 'confirm',
                    fallbackText: fallbackText,
                  ),
                ),
              ),
            ),
          ],
          edges: const <SceneEdge>[],
        ),
      );

  test('a single-brace reference is an error the export refuses', () {
    final fixture = _fixture();
    final report = validateNarrativeProject(
      fixture.project.copyWith(
        scenes: <SceneAsset>[
          ...fixture.project.scenes,
          sceneWithPrompt('Le registre dira donc {draft.playerName}.'),
        ],
      ),
      maps: <MapData>[fixture.map],
    );

    final issues = report.byCode('presentationTextReferenceUnresolvable');
    expect(issues, hasLength(1));
    expect(issues.single.severity, NarrativeProjectDiagnosticSeverity.error);
    expect(
      issues.single.path,
      'scenes.presession.nodes.confirm.preSessionInteraction.prompt',
    );
    expect(
      report.isPlayable,
      isFalse,
      reason: 'an error diagnostic is what makes the export refuse; a '
          'diagnostic nobody consumes was the original defect',
    );
  });

  test('the canonical form is accepted', () {
    final fixture = _fixture();
    final report = validateNarrativeProject(
      fixture.project.copyWith(
        scenes: <SceneAsset>[
          ...fixture.project.scenes,
          sceneWithPrompt('Le registre dira donc {{draft.playerName}}.'),
        ],
      ),
      maps: <MapData>[fixture.map],
    );

    expect(report.byCode('presentationTextReferenceUnresolvable'), isEmpty);
  });

  test('an option label is audited too, not only the prompt', () {
    final fixture = _fixture();
    final scene = SceneAsset(
      id: 'presession',
      name: 'Pre-session',
      executionProfile: SceneExecutionProfile.preSession,
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'pick',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload(
              preSessionInteraction: ScenePreSessionInteractionSpec.choice(
                prompt: SceneInteractionPrompt(
                  localizationKey: 'pick',
                  fallbackText: 'Qui prend la veille ?',
                ),
                options: <SceneInteractionOption>[
                  SceneInteractionOption(
                    id: 'dawn',
                    label: SceneInteractionPrompt(
                      localizationKey: 'dawn',
                      fallbackText: 'Celle que {draft.playerName} attend.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        edges: const <SceneEdge>[],
      ),
    );
    final report = validateNarrativeProject(
      fixture.project.copyWith(
        scenes: <SceneAsset>[...fixture.project.scenes, scene],
      ),
      maps: <MapData>[fixture.map],
    );

    expect(
      report.byCode('presentationTextReferenceUnresolvable').single.path,
      'scenes.presession.nodes.pick.preSessionInteraction.options[0].label',
    );
  });
}

({ProjectManifest project, MapData map}) _fixture({
  bool completeStep = true,
  bool requireFact = false,
  bool eventDependencyCycle = false,
  bool orphanSource = false,
}) {
  final map = MapData(
    id: 'map_port',
    name: 'Port',
    size: const GridSize(width: 16, height: 16),
    layers: const [MapLayer.object(id: 'events', name: 'Events')],
    mapMetadata: const MapMetadata(defaultSpawnId: 'spawn_player'),
    entities: const [
      MapEntity(
        id: 'spawn_player',
        name: 'Départ',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 1, y: 1),
        spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart),
      ),
      MapEntity(
        id: 'npc_guide',
        name: 'Guide',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 3, y: 4),
      ),
    ],
  );
  final scene = _scene(completeStep: completeStep);
  final records = <NarrativeEventRecord>[
    _record(
      id: _eventA,
      entityId: orphanSource ? 'npc_missing' : 'npc_guide',
      conditions: [
        if (requireFact) NarrativeEventCondition.fact('fact_gate', true),
        if (eventDependencyCycle)
          NarrativeEventCondition.narrativeEventConsumed(_eventB, true),
      ],
    ),
    if (eventDependencyCycle)
      _record(
        id: _eventB,
        entityId: 'npc_guide',
        conditions: [
          NarrativeEventCondition.narrativeEventConsumed(_eventA, true),
        ],
      ),
  ];

  return (
    map: map,
    project: ProjectManifest(
      name: 'Validator fixture',
      maps: const [
        ProjectMapEntry(
          id: 'map_port',
          name: 'Port',
          relativePath: 'maps/map_port.json',
        ),
      ],
      tilesets: const [],
      scenes: [scene],
      facts: [
        NarrativeFactDefinition(id: 'fact_gate', label: 'Passage ouvert'),
      ],
      storylines: [
        StorylineAsset(
          id: 'story_main',
          type: StorylineType.main,
          status: StorylineStatus.active,
          title: 'Histoire principale',
          chapters: [
            StorylineChapter(
              id: 'chapter_intro',
              title: 'Introduction',
              order: 0,
              steps: [
                StorylineStep(
                  id: 'step_intro',
                  title: 'Rencontrer le guide',
                  order: 0,
                  sceneLinkIds: const ['scene_intro'],
                ),
              ],
            ),
          ],
        ),
      ],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: records,
        legacyClaims: const [],
      ),
    ),
  );
}

NarrativeEventRecord _record({
  required String id,
  required String entityId,
  String sceneId = 'scene_intro',
  List<NarrativeEventCondition> conditions = const [],
  NarrativeEventReusePolicy reusePolicy = NarrativeEventReusePolicy.oneShot,
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: id,
      name: 'Event $id',
      source: NarrativeEventSourceRef.entityInteract('map_port', entityId),
      conditions: conditions,
      sceneId: sceneId,
      reusePolicy: reusePolicy,
      priority: 0,
      order: id == _eventA ? 0 : 1,
    ),
    enabled: true,
  );
}

SceneAsset _withEndPolicy(
  SceneAsset scene, {
  required String? sceneOutcomeId,
  required SceneOutcomePolicy? policy,
}) {
  return SceneAsset(
    id: scene.id,
    name: scene.name,
    description: scene.description,
    storylineId: scene.storylineId,
    chapterId: scene.chapterId,
    tags: scene.tags,
    graph: SceneGraph(
      startNodeId: scene.graph.startNodeId,
      nodes: [
        for (final node in scene.graph.nodes)
          if (node.kind == SceneNodeKind.end)
            SceneNode(
              id: node.id,
              kind: node.kind,
              title: node.title,
              description: node.description,
              payload: SceneEndPayload(
                sceneOutcomeId: sceneOutcomeId,
                outcomePolicy: policy,
              ),
            )
          else
            node,
      ],
      edges: scene.graph.edges,
    ),
    layout: scene.layout,
    declaredOutcomes: sceneOutcomeId == null
        ? scene.declaredOutcomes
        : [SceneOutcome(id: sceneOutcomeId, label: sceneOutcomeId)],
    metadata: scene.metadata,
  );
}

SceneAsset _scene({required bool completeStep}) {
  final nodes = <SceneNode>[
    SceneNode(id: 'start', kind: SceneNodeKind.start),
    if (completeStep)
      SceneNode(
        id: 'complete_step',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.completeStoryStep(stepId: 'step_intro'),
        ),
      ),
    SceneNode(id: 'end', kind: SceneNodeKind.end),
  ];
  return SceneAsset(
    id: 'scene_intro',
    name: 'Introduction',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: nodes,
      edges: completeStep
          ? [
              SceneEdge(
                id: 'start_action',
                fromNodeId: 'start',
                fromPortId: 'completed',
                toNodeId: 'complete_step',
                kind: SceneEdgeKind.defaultFlow,
              ),
              SceneEdge(
                id: 'action_end',
                fromNodeId: 'complete_step',
                fromPortId: 'completed',
                toNodeId: 'end',
                kind: SceneEdgeKind.defaultFlow,
              ),
            ]
          : [
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
}

SceneAsset _outcomeScene({
  required String id,
  required String emittedOutcomeId,
}) {
  return SceneAsset(
    id: id,
    name: id,
    declaredOutcomes: [
      SceneOutcome(id: emittedOutcomeId, label: emittedOutcomeId),
    ],
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: emittedOutcomeId),
        ),
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
}

SceneAsset _factProducingScene(String id) {
  return SceneAsset(
    id: id,
    name: id,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'set_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: 'fact_gate', value: true),
          ),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'start_fact',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'set_fact',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'fact_end',
          fromNodeId: 'set_fact',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}

SceneAsset _factScene({
  required String id,
  required String factId,
  required bool value,
}) {
  return SceneAsset(
    id: id,
    name: id,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'set_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: factId, value: value),
          ),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'start_fact',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'set_fact',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'fact_end',
          fromNodeId: 'set_fact',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}

SceneAsset _manyFactScene(String id, List<String> factIds) {
  final actionIds = [
    for (var index = 0; index < factIds.length; index++) 'set_fact_$index',
  ];
  return SceneAsset(
    id: id,
    name: id,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        for (var index = 0; index < factIds.length; index++)
          SceneNode(
            id: actionIds[index],
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
              SceneConsequence.setFact(
                factId: factIds[index],
                value: true,
              ),
            ),
          ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'start_to_first',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: actionIds.first,
          kind: SceneEdgeKind.defaultFlow,
        ),
        for (var index = 0; index < actionIds.length - 1; index++)
          SceneEdge(
            id: 'action_${index}_to_${index + 1}',
            fromNodeId: actionIds[index],
            fromPortId: 'completed',
            toNodeId: actionIds[index + 1],
            kind: SceneEdgeKind.defaultFlow,
          ),
        SceneEdge(
          id: 'last_to_end',
          fromNodeId: actionIds.last,
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
}

SceneAsset _conditionalFactScene({
  required String conditionFactId,
  required String trueFactId,
}) {
  return SceneAsset(
    id: 'scene_intro',
    name: 'Conditional fact',
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
              sourceId: conditionFactId,
              operator: SceneConditionOperator.isTrue,
            ),
          ),
        ),
        SceneNode(
          id: 'true_action',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: trueFactId, value: true),
          ),
        ),
        SceneNode(id: 'true_end', kind: SceneNodeKind.end),
        SceneNode(id: 'false_end', kind: SceneNodeKind.end),
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
          toNodeId: 'true_action',
          kind: SceneEdgeKind.conditionTrue,
        ),
        SceneEdge(
          id: 'condition_false',
          fromNodeId: 'condition',
          fromPortId: 'false',
          toNodeId: 'false_end',
          kind: SceneEdgeKind.conditionFalse,
        ),
        SceneEdge(
          id: 'true_action_end',
          fromNodeId: 'true_action',
          fromPortId: 'completed',
          toNodeId: 'true_end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}

SceneAsset _conditionalOutcomeScene({required String conditionFactId}) {
  return SceneAsset(
    id: 'scene_intro',
    name: 'Conditional outcome',
    declaredOutcomes: [SceneOutcome(id: 'success', label: 'Success')],
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
              sourceId: conditionFactId,
              operator: SceneConditionOperator.isTrue,
            ),
          ),
        ),
        SceneNode(
          id: 'success_end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: 'success'),
        ),
        SceneNode(id: 'false_end', kind: SceneNodeKind.end),
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
          toNodeId: 'success_end',
          kind: SceneEdgeKind.conditionTrue,
        ),
        SceneEdge(
          id: 'condition_false',
          fromNodeId: 'condition',
          fromPortId: 'false',
          toNodeId: 'false_end',
          kind: SceneEdgeKind.conditionFalse,
        ),
      ],
    ),
  );
}

StorylineAsset _storylineWithOutcomeEffects({
  required StorylineAsset base,
  required String sceneId,
  required String outcomeId,
}) {
  return StorylineAsset(
    id: base.id,
    type: base.type,
    status: base.status,
    title: base.title,
    chapters: base.chapters,
    sceneLinks: [
      StorylineSceneLink(
        id: 'link_$sceneId',
        chapterId: 'chapter_intro',
        stepId: 'step_intro',
        label: sceneId,
        state: StorylineSceneLinkState.linkedScenario,
        role: StorylineSceneLinkRole.primary,
        sceneRef: StorylineSceneRef(
          kind: StorylineSceneRefKind.scenario,
          targetId: sceneId,
        ),
        order: 0,
        expectedOutcomeIds: [outcomeId],
        outcomeLinks: [
          StorylineSceneOutcomeLink(
            id: 'effect_$outcomeId',
            outcomeId: outcomeId,
            effects: [
              StorylineEffect(
                type: StorylineEffectType.completeStep,
                targetId: 'step_intro',
              ),
              StorylineEffect(
                type: StorylineEffectType.emitFact,
                targetId: 'fact_gate',
                value: 'true',
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

SceneAsset _battleScene({
  required String battleKind,
  required String trainerId,
}) {
  return SceneAsset(
    id: 'scene_intro',
    name: 'Combat',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'battle',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
            battleKind: battleKind,
            trainerId: trainerId,
            declaredOutcomes: const ['victory', 'defeat'],
          ),
        ),
        SceneNode(id: 'victory_end', kind: SceneNodeKind.end),
        SceneNode(id: 'defeat_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'start_battle',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'battle',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'battle_victory',
          fromNodeId: 'battle',
          fromPortId: 'victory',
          toNodeId: 'victory_end',
          kind: SceneEdgeKind.battleVictory,
        ),
        SceneEdge(
          id: 'battle_defeat',
          fromNodeId: 'battle',
          fromPortId: 'defeat',
          toNodeId: 'defeat_end',
          kind: SceneEdgeKind.battleDefeat,
        ),
      ],
    ),
  );
}
