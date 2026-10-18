import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/narrative_scene_runtime_execution.dart';

void main() {
  for (final eventV2 in [false, true]) {
    test('party condition is intercepted before any pending write eventV2=$eventV2', () async {
      final initial = GameState(saveId: 'transaction', currentMapId: 'room',
          party: PlayerParty(members: [_pokemon('member')]));
      final result = await _run(initial: initial, eventV2: eventV2, consequence: null,
          source: SceneConditionSource.partyKnowsMove(moveId: 'fixture-move'));
      expect(result!.trainerProfile.money, initial.trainerProfile.money + 10);
    });

    test('field unlock is visible to the following party condition eventV2=$eventV2', () async {
      final initial = GameState(saveId: 'transaction', currentMapId: 'room',
          party: PlayerParty(members: [_pokemon('member').copyWith(knownMoveIds: ['surf'], currentPpByMoveId: {'surf': 0})]));
      final result = await _run(initial: initial, eventV2: eventV2,
          consequence: SceneConsequence.unlockFieldAbility(ability: FieldAbility.surf),
          source: SceneConditionSource.partyCanUseFieldAbility(ability: FieldAbility.surf));
      expect(result!.trainerProfile.money, initial.trainerProfile.money + 10);
      expect(result.progression.unlockedFieldAbilities, contains(FieldAbility.surf));
      expect(initial.progression.unlockedFieldAbilities, isEmpty);
    });
    for (final rollback in [false, true]) {
      test(
        'gift changes reception capacity privately eventV2=$eventV2 rollback=$rollback',
        () async {
          final initial = GameState(
            saveId: 'transaction',
            currentMapId: 'room',
            party: PlayerParty(
              members: [for (var i = 0; i < 5; i++) _pokemon('member-$i')],
            ),
            pokemonStorage: PokemonStorage(
              boxes: [
                PokemonBox(
                  id: 'box',
                  label: 'Box',
                  capacity: 1,
                  pokemon: [_pokemon('stored')],
                ),
              ],
            ),
          );
          expect(
            evaluateScenePartyCondition(
              source: SceneConditionSource.partyCanReceivePokemon(),
              gameState: initial,
            ),
            isTrue,
          );
          final result = await _run(
            initial: initial,
            eventV2: eventV2,
            rollback: rollback,
            consequence: SceneConsequence.givePokemon(
              speciesId: 'fixture-species',
              formId: 'fixture-form',
              level: 1,
              currentHp: 1,
            ),
            source: SceneConditionSource.partyCanReceivePokemon(),
          );
          if (rollback) {
            expect(result, isNull);
          } else {
            expect(result!.party.members, hasLength(6));
            expect(
              result.trainerProfile.money,
              initial.trainerProfile.money + 20,
            );
            expect(
              evaluateScenePartyCondition(
                source: SceneConditionSource.partyCanReceivePokemon(),
                gameState: GameState.fromJson(result.toJson()),
              ),
              isFalse,
            );
          }
          expect(initial.party.members, hasLength(5));
        },
      );
    }

    test(
      'healing updates PP before the next condition eventV2=$eventV2',
      () async {
        final initial = GameState(
          saveId: 'transaction',
          currentMapId: 'room',
          party: PlayerParty(
            members: [
              _pokemon('member')
                  .copyWith(currentPpByMoveId: {'fixture-move': 0}),
            ],
          ),
        );
        final result = await _run(
          initial: initial,
          eventV2: eventV2,
          consequence: SceneConsequence.healParty(),
          source: SceneConditionSource.partyHasUsableMove(
            moveId: 'fixture-move',
          ),
        );
        expect(
          result!.party.members.single.currentPpByMoveId!['fixture-move'],
          5,
        );
        expect(result.trainerProfile.money, initial.trainerProfile.money + 10);
        expect(
          initial.party.members.single.currentPpByMoveId!['fixture-move'],
          0,
        );
      },
    );
  }
}

Future<GameState?> _run({
  required GameState initial,
  required bool eventV2,
  required SceneConsequence? consequence,
  required SceneConditionSource source,
  bool rollback = false,
}) async {
  final scene = _scene(consequence, source);
  final event = MapEventDefinition(
    id: 'event',
    title: 'Event',
    position: const EventPosition(layerId: 'ground', x: 1, y: 1),
    pages: [
      MapEventPage(
        pageNumber: 0,
        sceneTarget: MapEventSceneTarget(sceneId: scene.id),
      ),
    ],
  );
  final map = MapData(
    id: 'room',
    name: 'Room',
    size: const GridSize(width: 4, height: 4),
    layers: [
      MapLayer.tile(id: 'ground', name: 'Ground', cells: List.filled(16, 0)),
    ],
    events: [event],
  );
  final project = ProjectManifest(
    name: 'Condition transaction',
    maps: const [
      ProjectMapEntry(id: 'room', name: 'Room', relativePath: 'maps/room.json'),
    ],
    tilesets: const [],
    scenes: [scene],
    dialogues: const [
      ProjectDialogueEntry(
        id: 'checkpoint',
        name: 'Checkpoint',
        relativePath: 'dialogues/checkpoint.yarn',
      ),
    ],
  );
  final before = initial.toJson();
  var checkpoints = 0;
  final callbacks = SceneRuntimeHostCallbacks(
    evaluateCondition: (_) => throw StateError(
      'The transactional party condition was not intercepted.',
    ),
    showDialogue: (_) {
      checkpoints++;
      expect(initial.toJson(), before);
      if (rollback) throw StateError('Cancel before the transaction commits.');
      return 'completed';
    },
    startBattle: (_) => throw StateError('Unexpected battle.'),
    playCinematic: (_) => throw StateError('Unexpected cinematic.'),
  );
  final writer = SceneConsequenceRuntimeWriter(
    project: project,
    mapsById: {'room': map},
    maxHpByPartyIndex: {
      for (var i = 0; i < initial.party.members.length; i++) i: 10,
    },
    maxPpByPartyIndex: {
      for (var i = 0; i < initial.party.members.length; i++)
        i: {'fixture-move': 5},
    },
    partyConditionContext: ScenePartyConditionContext(
      availableMoveIds: ['fixture-move'],
      supportedFieldAbilities: [FieldAbility.surf],
    ),
  );
  GameState? updated;
  if (eventV2) {
    final result = await executeNarrativeEventScene(
      request: NarrativeSceneExecutionRequest(
        eventId: event.id,
        sceneId: scene.id,
        executionId: 'transaction',
        gameState: initial,
      ),
      project: project,
      mapsById: {'room': map},
      currentGameState: () => initial,
      callbacks: callbacks,
      consequenceWriter: writer,
    );
    if (rollback) {
      expect(result, isA<NarrativeSceneExecutionFailed>());
    } else {
      expect(
        result,
        isA<NarrativeSceneExecutionCompleted>(),
        reason: result.toString(),
      );
      updated = (result as NarrativeSceneExecutionCompleted).updatedGameState;
    }
  } else {
    final result =
        await SceneEventRuntimeHook(
          callbacks: callbacks,
          consequenceWriter: writer,
        ).runForEventPage(
          project: project,
          map: map,
          event: event,
          page: event.pages.single,
          gameState: initial,
          currentGameState: () => initial,
          executionId: 'transaction',
        );
    expect(result.success, !rollback, reason: result.message);
    updated = result.updatedGameState;
  }
  expect(checkpoints, 1);
  expect(initial.toJson(), before);
  return updated;
}

SceneAsset _scene(SceneConsequence? consequence, SceneConditionSource source) =>
    SceneAsset(
      id: 'party',
      name: 'Party transaction',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          if (consequence != null) SceneNode(
            id: 'prepare',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(consequence),
          ),
          SceneNode(
            id: 'condition',
            kind: SceneNodeKind.condition,
            payload: SceneConditionPayload(conditionSource: source),
          ),
          for (final value in [true, false])
            SceneNode(
              id: '$value',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                SceneConsequence.giveMoney(amount: value ? 10 : 20),
              ),
            ),
          SceneNode(
            id: 'checkpoint',
            kind: SceneNodeKind.yarnDialogue,
            payload: SceneYarnDialoguePayload(dialogueId: 'checkpoint'),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'start',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: consequence == null ? 'condition' : 'prepare',
            kind: SceneEdgeKind.defaultFlow,
          ),
          if (consequence != null) SceneEdge(
            id: 'prepared',
            fromNodeId: 'prepare',
            fromPortId: 'completed',
            toNodeId: 'condition',
            kind: SceneEdgeKind.actionCompleted,
          ),
          for (final value in [true, false]) ...[
            SceneEdge(
              id: 'branch-$value',
              fromNodeId: 'condition',
              fromPortId: '$value',
              toNodeId: '$value',
              kind: value
                  ? SceneEdgeKind.conditionTrue
                  : SceneEdgeKind.conditionFalse,
            ),
            SceneEdge(
              id: 'reward-$value',
              fromNodeId: '$value',
              fromPortId: 'completed',
              toNodeId: 'checkpoint',
              kind: SceneEdgeKind.actionCompleted,
            ),
          ],
          SceneEdge(
            id: 'finish',
            fromNodeId: 'checkpoint',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      ),
    );

PlayerPokemon _pokemon(String id) => PlayerPokemon(
  individualId: id,
  speciesId: 'fixture-species',
  natureId: 'fixture-nature',
  abilityId: 'fixture-ability',
  knownMoveIds: const ['fixture-move'],
  currentPpByMoveId: const {'fixture-move': 1},
);
