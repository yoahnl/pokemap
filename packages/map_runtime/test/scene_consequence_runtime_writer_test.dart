import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('SceneConsequenceRuntimeWriter', () {
    test('setFact true activates Fact runtime key', () {
      const state = GameState(saveId: 'save_test');
      final writer = SceneConsequenceRuntimeWriter(
        project: _project(
          facts: [
            NarrativeFactDefinition(
              id: 'fact_gate_open',
              label: 'Gate open',
            ),
          ],
        ),
      );

      final result = writer.applyAll(
        state,
        [
          SceneConsequence.setFact(factId: 'fact_gate_open', value: true),
        ],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.applied);
      expect(
          result.gameState.storyFlags.activeFlags, contains('fact_gate_open'));
      expect(
        result.gameState.narrativeFactRuntimeState.overridesByFactId,
        {'fact_gate_open': true},
      );
      expect(
        result.gameState.progression.storyFlags,
        contains('fact_gate_open'),
      );
      expect(state.storyFlags.activeFlags, isEmpty);
    });

    test('setFact false overrides a true default and clears both flag stores',
        () {
      const state = GameState(
        saveId: 'save_test',
        storyFlags: StoryFlags(
          activeFlags: {'legacy_gate_open', 'runtime_other'},
        ),
        progression: PlayerProgression(
          storyFlags: ['legacy_gate_open', 'progression_other'],
        ),
        consumedEventIds: {'legacy_event'},
      );
      final writer = SceneConsequenceRuntimeWriter(
        project: _project(
          facts: [
            NarrativeFactDefinition(
              id: 'fact_gate_open',
              label: 'Gate open',
              defaultValue: true,
              legacyFlagName: 'legacy_gate_open',
            ),
          ],
        ),
      );

      final result = writer.applyAll(
        state,
        [
          SceneConsequence.setFact(factId: 'fact_gate_open', value: false),
        ],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.applied);
      expect(
        result.gameState.storyFlags.activeFlags,
        {'runtime_other'},
      );
      expect(result.gameState.progression.storyFlags, ['progression_other']);
      expect(
        result.gameState.narrativeFactRuntimeState.overridesByFactId,
        {'fact_gate_open': false},
      );
      expect(result.gameState.consumedEventIds, {'legacy_event'});
      expect(state.storyFlags.activeFlags, contains('legacy_gate_open'));
    });

    test('setFact uses legacyFlagName when present', () {
      final writer = SceneConsequenceRuntimeWriter(
        project: _project(
          facts: [
            NarrativeFactDefinition(
              id: 'fact_gate_open',
              label: 'Gate open',
              legacyFlagName: 'legacy_gate_flag',
            ),
          ],
        ),
      );

      final result = writer.applyAll(
        const GameState(saveId: 'save_test'),
        [
          SceneConsequence.setFact(factId: 'fact_gate_open', value: true),
        ],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.applied);
      expect(
        result.gameState.storyFlags.activeFlags,
        contains('legacy_gate_flag'),
      );
      expect(
        result.gameState.storyFlags.activeFlags,
        isNot(contains('fact_gate_open')),
      );
      expect(
        result.gameState.narrativeFactRuntimeState.overridesByFactId,
        {'fact_gate_open': true},
      );
    });

    test('setFact unknown Fact fails without mutating the original state', () {
      const state = GameState(saveId: 'save_test');
      final writer = SceneConsequenceRuntimeWriter(project: _project());

      final result = writer.applyAll(
        state,
        [
          SceneConsequence.setFact(factId: 'fact_missing', value: true),
        ],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.failed);
      expect(
        result.errorCode,
        SceneConsequenceRuntimeWriteErrorCode.unknownFact,
      );
      expect(result.gameState, state);
      expect(state.storyFlags.activeFlags, isEmpty);
    });

    test('setFact ambiguous Fact fails without choosing a winner', () {
      const state = GameState(saveId: 'save_test');
      final writer = SceneConsequenceRuntimeWriter(
        project: _project(
          facts: [
            NarrativeFactDefinition(id: 'fact_dup', label: 'A'),
            NarrativeFactDefinition(id: 'fact_dup', label: 'B'),
          ],
        ),
      );

      final result = writer.applyAll(
        state,
        [SceneConsequence.setFact(factId: 'fact_dup', value: true)],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.failed);
      expect(
        result.errorCode,
        SceneConsequenceRuntimeWriteErrorCode.ambiguousFact,
      );
      expect(identical(result.gameState, state), isTrue);
    });

    test('rolls back every consequence when a later setFact fails', () {
      const state = GameState(
        saveId: 'save_test',
        storyFlags: StoryFlags(activeFlags: {'original'}),
      );
      final writer = SceneConsequenceRuntimeWriter(
        project: _project(
          facts: [
            NarrativeFactDefinition(id: 'fact_known', label: 'Known'),
          ],
        ),
      );

      final result = writer.applyAll(
        state,
        [
          SceneConsequence.setFact(factId: 'fact_known', value: true),
          SceneConsequence.setFact(factId: 'fact_missing', value: true),
        ],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.failed);
      expect(identical(result.gameState, state), isTrue);
      expect(result.appliedConsequences, isEmpty);
      expect(state.storyFlags.activeFlags, {'original'});
      expect(state.narrativeFactRuntimeState.overridesByFactId, isEmpty);
    });

    test('markEventConsumed adds consumed event id using existing convention',
        () {
      final writer = SceneConsequenceRuntimeWriter(
        project: _project(
          maps: const [
            ProjectMapEntry(
              id: 'map_test',
              name: 'Map Test',
              relativePath: 'maps/map_test.json',
            ),
          ],
        ),
        mapsById: {
          'map_test': _map(events: [_event('event_gate')]),
        },
      );

      final result = writer.applyAll(
        const GameState(saveId: 'save_test'),
        [
          SceneConsequence.markEventConsumed(
            mapId: 'map_test',
            eventId: 'event_gate',
          ),
        ],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.applied);
      expect(result.gameState.consumedEventIds, contains('event_gate'));
      expect(
        result.gameState.consumedEventIds,
        isNot(contains('map_test:event_gate')),
      );
    });

    test('markEventConsumed unknown map fails clearly', () {
      final writer = SceneConsequenceRuntimeWriter(project: _project());

      final result = writer.applyAll(
        const GameState(saveId: 'save_test'),
        [
          SceneConsequence.markEventConsumed(
            mapId: 'map_missing',
            eventId: 'event_gate',
          ),
        ],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.failed);
      expect(
        result.errorCode,
        SceneConsequenceRuntimeWriteErrorCode.unknownMap,
      );
    });

    test('markEventConsumed unknown event fails clearly', () {
      final writer = SceneConsequenceRuntimeWriter(
        project: _project(
          maps: const [
            ProjectMapEntry(
              id: 'map_test',
              name: 'Map Test',
              relativePath: 'maps/map_test.json',
            ),
          ],
        ),
        mapsById: {
          'map_test': _map(events: [_event('event_other')]),
        },
      );

      final result = writer.applyAll(
        const GameState(saveId: 'save_test'),
        [
          SceneConsequence.markEventConsumed(
            mapId: 'map_test',
            eventId: 'event_gate',
          ),
        ],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.failed);
      expect(
        result.errorCode,
        SceneConsequenceRuntimeWriteErrorCode.unknownEvent,
      );
    });

    test('completeStoryStep completes one canonical step idempotently', () {
      final writer = SceneConsequenceRuntimeWriter(
        project: _project(
          storylines: [_storyline('story_main', 'step_rival_battle')],
        ),
      );
      final consequence = SceneConsequence.completeStoryStep(
        stepId: 'step_rival_battle',
      );

      final result = writer.applyAll(
        const GameState(saveId: 'save_test'),
        [consequence, consequence],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.applied);
      expect(
        result.gameState.progression.completedStepIds,
        ['step_rival_battle'],
      );
    });

    test('completeStoryStep unknown id fails without mutation', () {
      const state = GameState(saveId: 'save_test');
      final writer = SceneConsequenceRuntimeWriter(project: _project());

      final result = writer.applyAll(
        state,
        [SceneConsequence.completeStoryStep(stepId: 'step_missing')],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.failed);
      expect(
        result.errorCode,
        SceneConsequenceRuntimeWriteErrorCode.unknownStoryStep,
      );
      expect(identical(result.gameState, state), isTrue);
    });

    test('completeStoryStep ambiguous global id fails without choosing', () {
      const state = GameState(saveId: 'save_test');
      final writer = SceneConsequenceRuntimeWriter(
        project: _project(
          storylines: [
            _storyline('story_a', 'step_duplicate'),
            _storyline('story_b', 'step_duplicate'),
          ],
        ),
      );

      final result = writer.applyAll(
        state,
        [SceneConsequence.completeStoryStep(stepId: 'step_duplicate')],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.failed);
      expect(
        result.errorCode,
        SceneConsequenceRuntimeWriteErrorCode.ambiguousStoryStep,
      );
      expect(identical(result.gameState, state), isTrue);
    });

    test('does not apply World Rules as a side effect of setFact', () {
      final writer = SceneConsequenceRuntimeWriter(
        project: _project(
          facts: [
            NarrativeFactDefinition(
              id: 'fact_gate_open',
              label: 'Gate open',
            ),
          ],
          worldRules: [
            WorldRuleDefinition(
              id: 'world_rule_gate',
              label: 'Gate world rule',
              source: const WorldRuleSource(
                kind: WorldRuleSourceKind.fact,
                sourceId: 'fact_gate_open',
                predicate: WorldRuleSourcePredicate.isTrue,
              ),
              target: const WorldRuleTarget(
                kind: WorldRuleTargetKind.mapEvent,
                mapId: 'map_test',
                eventId: 'event_gate',
              ),
              effect: const WorldRuleEffect(
                kind: WorldRuleEffectKind.eventHidden,
              ),
            ),
          ],
        ),
      );
      const state = GameState(
        saveId: 'save_test',
        progression: PlayerProgression(completedStepIds: ['already_done']),
      );

      final result = writer.applyAll(
        state,
        [
          SceneConsequence.setFact(factId: 'fact_gate_open', value: true),
        ],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.applied);
      expect(result.gameState.progression.completedStepIds, ['already_done']);
      expect(
          result.gameState.storyFlags.activeFlags, contains('fact_gate_open'));
    });

    test('is deterministic and idempotent for repeated same consequence', () {
      final writer = SceneConsequenceRuntimeWriter(
        project: _project(
          facts: [
            NarrativeFactDefinition(
              id: 'fact_gate_open',
              label: 'Gate open',
            ),
          ],
        ),
      );
      final consequence =
          SceneConsequence.setFact(factId: 'fact_gate_open', value: true);

      final first = writer.applyAll(
        const GameState(saveId: 'save_test'),
        [consequence, consequence],
      );
      final second = writer.applyAll(
        const GameState(saveId: 'save_test'),
        [consequence, consequence],
      );

      expect(first.status, SceneConsequenceRuntimeWriteStatus.applied);
      expect(first.gameState, second.gameState);
      expect(first.gameState.storyFlags.activeFlags, hasLength(1));
      expect(
        first.gameState.storyFlags.activeFlags,
        contains('fact_gate_open'),
      );
    });

    test('applies item money and Pokemon consequences through gameplay', () {
      const state = GameState(
        saveId: 'save_gameplay_consequences',
        trainerProfile: TrainerProfile(name: 'Player', money: 100),
        bag: Bag(
          entries: [
            BagEntry(
              itemId: 'item_ticket',
              categoryId: 'items',
              quantity: 2,
            ),
          ],
        ),
      );
      final writer = SceneConsequenceRuntimeWriter(project: _project());

      final result = writer.applyAll(
        state,
        [
          SceneConsequence.giveItem(itemId: 'item_potion', quantity: 3),
          SceneConsequence.takeItem(itemId: 'item_ticket', quantity: 1),
          SceneConsequence.giveMoney(amount: 500),
          SceneConsequence.givePokemon(
            speciesId: 'species_sproutle',
            level: 7,
            currentHp: 23,
          ),
        ],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.applied);
      expect(result.appliedConsequences, hasLength(4));
      expect(result.gameState.trainerProfile.money, 600);
      expect(
        result.gameState.bag.entries
            .singleWhere((entry) => entry.itemId == 'item_potion')
            .quantity,
        3,
      );
      expect(
        result.gameState.bag.entries
            .singleWhere((entry) => entry.itemId == 'item_ticket')
            .quantity,
        1,
      );
      expect(
          result.gameState.party.members.single.speciesId, 'species_sproutle');
      expect(result.gameState.party.members.single.level, 7);
      expect(result.gameState.party.members.single.currentHp, 23);
      expect(state.trainerProfile.money, 100);
      expect(state.party.members, isEmpty);

      final reloaded = GameState.fromJson(result.gameState.toJson());
      expect(reloaded.trainerProfile.money, 600);
      expect(reloaded.bag, result.gameState.bag);
      expect(reloaded.party, result.gameState.party);
    });

    test('takeItem insufficient quantity fails without partial state', () {
      const state = GameState(
        saveId: 'save_take_item',
        bag: Bag(
          entries: [
            BagEntry(
              itemId: 'item_ticket',
              categoryId: 'items',
              quantity: 1,
            ),
          ],
        ),
      );

      final result =
          SceneConsequenceRuntimeWriter(project: _project()).applyAll(
        state,
        [SceneConsequence.takeItem(itemId: 'item_ticket', quantity: 2)],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.failed);
      expect(
        result.errorCode,
        SceneConsequenceRuntimeWriteErrorCode.insufficientItemQuantity,
      );
      expect(identical(result.gameState, state), isTrue);
      expect(result.appliedConsequences, isEmpty);
      expect(result.message, contains('item_ticket'));
    });

    test('givePokemon fails explicitly when the party is full', () {
      final state = GameState(
        saveId: 'save_full_party',
        party: PlayerParty(
          members: [
            for (var index = 0; index < 6; index++) _pokemon('species_$index'),
          ],
        ),
      );

      final result =
          SceneConsequenceRuntimeWriter(project: _project()).applyAll(
        state,
        [
          SceneConsequence.givePokemon(
            speciesId: 'species_reward',
            level: 5,
            currentHp: 20,
          ),
        ],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.failed);
      expect(
        result.errorCode,
        SceneConsequenceRuntimeWriteErrorCode.partyFull,
      );
      expect(identical(result.gameState, state), isTrue);
      expect(state.party.members, hasLength(6));
    });

    test('rolls back earlier gameplay rewards when a later takeItem fails', () {
      const state = GameState(
        saveId: 'save_atomic_rewards',
        trainerProfile: TrainerProfile(name: 'Player', money: 25),
        bag: Bag(
          entries: [
            BagEntry(
              itemId: 'item_ticket',
              categoryId: 'items',
              quantity: 1,
            ),
          ],
        ),
      );

      final result =
          SceneConsequenceRuntimeWriter(project: _project()).applyAll(
        state,
        [
          SceneConsequence.giveMoney(amount: 1000),
          SceneConsequence.giveItem(itemId: 'item_potion', quantity: 2),
          SceneConsequence.takeItem(itemId: 'item_ticket', quantity: 2),
        ],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.failed);
      expect(
        result.errorCode,
        SceneConsequenceRuntimeWriteErrorCode.insufficientItemQuantity,
      );
      expect(identical(result.gameState, state), isTrue);
      expect(result.gameState.trainerProfile.money, 25);
      expect(
        result.gameState.bag.entries.any(
          (entry) => entry.itemId == 'item_potion',
        ),
        isFalse,
      );
      expect(result.appliedConsequences, isEmpty);
    });

    test('rejects missing references and invalid gameplay values explicitly',
        () {
      final cases = <(SceneConsequence, SceneConsequenceRuntimeWriteErrorCode)>[
        (
          SceneConsequence.giveItem(itemId: ' ', quantity: 1),
          SceneConsequenceRuntimeWriteErrorCode.missingItemReference,
        ),
        (
          SceneConsequence.giveItem(itemId: 'item_potion', quantity: 0),
          SceneConsequenceRuntimeWriteErrorCode.invalidQuantity,
        ),
        (
          SceneConsequence.giveMoney(amount: 0),
          SceneConsequenceRuntimeWriteErrorCode.invalidMoneyAmount,
        ),
        (
          SceneConsequence.givePokemon(
            speciesId: ' ',
            level: 5,
            currentHp: 20,
          ),
          SceneConsequenceRuntimeWriteErrorCode.missingPokemonSpeciesReference,
        ),
        (
          SceneConsequence.givePokemon(
            speciesId: 'species_test',
            level: 0,
            currentHp: 20,
          ),
          SceneConsequenceRuntimeWriteErrorCode.invalidPokemonLevel,
        ),
        (
          SceneConsequence.givePokemon(
            speciesId: 'species_test',
            level: 5,
            currentHp: 20,
            natureId: ' ',
          ),
          SceneConsequenceRuntimeWriteErrorCode.invalidPokemonDefinition,
        ),
        (
          SceneConsequence.givePokemon(
            speciesId: 'species_test',
            level: 5,
            currentHp: 0,
          ),
          SceneConsequenceRuntimeWriteErrorCode.invalidPokemonCurrentHp,
        ),
      ];
      const state = GameState(saveId: 'save_invalid_consequences');
      final writer = SceneConsequenceRuntimeWriter(project: _project());

      for (final (consequence, expectedError) in cases) {
        final result = writer.applyAll(state, [consequence]);
        expect(result.status, SceneConsequenceRuntimeWriteStatus.failed);
        expect(result.errorCode, expectedError);
        expect(identical(result.gameState, state), isTrue);
      }
    });

    test('giveConfiguredStarter grants the exact project-owned Pokemon', () {
      const authored = PlayerPokemon(
        speciesId: 'bulbasaur',
        natureId: 'modest',
        abilityId: 'overgrow',
        gender: 'female',
        level: 16,
        currentHp: 40,
        knownMoveIds: <String>['tackle', 'growl', 'vine_whip'],
        heldItemId: 'miracle_seed',
      );
      final writer = SceneConsequenceRuntimeWriter(
        project: _project(
          newGame: const ProjectNewGameConfig(
            starterOptions: <ProjectStarterOption>[
              ProjectStarterOption(
                id: 'starter_bulbasaur',
                label: 'Bulbizarre',
                pokemon: authored,
              ),
            ],
          ),
        ),
      );

      final result = writer.applyAll(
        const GameState(saveId: 'save_configured_starter'),
        <SceneConsequence>[
          SceneConsequence.giveConfiguredStarter(
            starterOptionId: 'starter_bulbasaur',
          ),
        ],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.applied);
      expect(result.gameState.party.members, const <PlayerPokemon>[authored]);
    });

    test('giveConfiguredStarter rejects an option absent from New Game', () {
      const state = GameState(saveId: 'save_unknown_configured_starter');
      final result =
          SceneConsequenceRuntimeWriter(project: _project()).applyAll(
        state,
        <SceneConsequence>[
          SceneConsequence.giveConfiguredStarter(
            starterOptionId: 'starter_missing',
          ),
        ],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.failed);
      expect(
        result.errorCode,
        SceneConsequenceRuntimeWriteErrorCode.unknownStarterOption,
      );
      expect(identical(result.gameState, state), isTrue);
    });
  });
}

PlayerPokemon _pokemon(String speciesId) {
  return PlayerPokemon(
    speciesId: speciesId,
    natureId: 'hardy',
    abilityId: 'unknown',
    level: 5,
    currentHp: 5,
  );
}

ProjectManifest _project({
  List<ProjectMapEntry> maps = const [],
  List<NarrativeFactDefinition> facts = const [],
  List<WorldRuleDefinition> worldRules = const [],
  List<StorylineAsset> storylines = const [],
  ProjectNewGameConfig newGame = const ProjectNewGameConfig(),
}) {
  return ProjectManifest(
    name: 'Scene consequence runtime writer test',
    maps: maps,
    tilesets: const [],
    facts: facts,
    worldRules: worldRules,
    storylines: storylines,
    newGame: newGame,
  );
}

StorylineAsset _storyline(String storylineId, String stepId) {
  return StorylineAsset(
    id: storylineId,
    type: StorylineType.main,
    status: StorylineStatus.active,
    title: storylineId,
    chapters: [
      StorylineChapter(
        id: '${storylineId}_chapter',
        title: 'Chapter',
        order: 0,
        steps: [StorylineStep(id: stepId, title: 'Step', order: 0)],
      ),
    ],
  );
}

MapData _map({List<MapEventDefinition> events = const []}) {
  return MapData(
    id: 'map_test',
    name: 'Map Test',
    size: const GridSize(width: 4, height: 4),
    events: events,
  );
}

MapEventDefinition _event(String id) {
  return MapEventDefinition(
    id: id,
    position: const EventPosition(layerId: 'l_base', x: 1, y: 1),
    pages: const [MapEventPage(pageNumber: 0)],
  );
}
