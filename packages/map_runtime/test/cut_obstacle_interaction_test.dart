import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:map_runtime/src/presentation/flame/dialogue_overlay_component.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/cut_obstacle_interaction.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';

void main() {
  test('a native Cut interaction opens a dated closed yes no programme', () {
    final state = _ready();
    final interaction = prepareCutObstacleInteraction(
      map: _map(),
      gameState: state,
      stateRevision: 7,
      entityId: 'tree',
    )!;
    expect(interaction.ticket!.fieldAction.issuedAtStateRevision, 7);
    expect(interaction.ticket!.fieldAction.ability, FieldAbility.cut);
    expect(
      interaction.ticket!.instance,
      state.mapInstanceWorldState.instanceRef('route'),
    );
    final prompt = interaction.session.state as DialogueShowingLine;
    expect(prompt.text, contains('Coupe'));
    final choices = interaction.session.advance()!;
    expect(
      (choices.state as DialogueWaitingForChoice).choices.map((v) => v.text),
      ['Oui', 'Non'],
    );
    expect(choices.choiceCancellationOutcomeId, 'cut-declined');
  });

  test('yes commits only after the closed dialogue completes', () {
    final state = _ready();
    final interaction = prepareCutObstacleInteraction(
      map: _map(),
      gameState: state,
      stateRevision: 7,
      entityId: 'tree',
    )!;
    final choices = interaction.session.advance()!;
    final outcome =
        (choices.state as DialogueWaitingForChoice).choices.first.outcomeId;
    expect(choices.confirmChoice(), isNull);
    expect(
      state.mapInstanceWorldState.isFieldObstacleCleared(
        interaction.ticket!.instance,
        'tree',
      ),
      isFalse,
    );
    final result = interaction.complete(
      outcomeId: outcome,
      map: _map(),
      gameState: state,
      currentStateRevision: 7,
    ) as CutObstacleApplied;
    final projected = applyFieldObstacleWorldStateToMap(
      map: _map(),
      instances: result.gameState.mapInstanceWorldState,
      instance: interaction.ticket!.instance,
    );
    final world = GameplayWorldState.initial(
      map: projected,
      playerPos: state.playerPosition,
      playerFacing: Direction.east,
    );
    expect(
      stepGameplayWorld(world, const MoveIntent(Direction.east)),
      isA<Moved>(),
    );
    expect(result.gameState.party, state.party);
    expect(result.gameState.progression, state.progression);
  });

  test('the real dialogue overlay returns the closed confirmation outcome', () {
    final state = _ready();
    final interaction = prepareCutObstacleInteraction(
      map: _map(),
      gameState: state,
      stateRevision: 7,
      entityId: 'tree',
    )!;
    CutObstacleCommit? result;
    final overlay = DialogueOverlayComponent(
      session: interaction.session.advance()!,
      viewportSize: Vector2(320, 240),
      onFinished: (outcome) {
        result = interaction.complete(
          outcomeId: outcome,
          map: _map(),
          gameState: state,
          currentStateRevision: 7,
        );
      },
    );
    expect(overlay.confirmChoice(), isFalse);
    expect(result, isA<CutObstacleApplied>());
  });

  for (final outcome in [null, 'cut-declined', 'unknown']) {
    test(
      'refusal cancellation or invalid outcome $outcome cannot mutate state',
      () {
        final state = _ready();
        final interaction = prepareCutObstacleInteraction(
          map: _map(),
          gameState: state,
          stateRevision: 7,
          entityId: 'tree',
        )!;
        final choices = interaction.session.advance()!;
        expect(choices.moveChoiceCursor(1).confirmChoice(), isNull);
        expect(choices.cancelChoice(), isNull);
        expect(
          interaction.complete(
            outcomeId: outcome,
            map: _map(),
            gameState: state,
            currentStateRevision: 7,
          ),
          isNull,
        );
        expect(
          state.mapInstanceWorldState.isFieldObstacleCleared(
            interaction.ticket!.instance,
            'tree',
          ),
          isFalse,
        );
      },
    );
  }

  for (final mode in ['emptyParty', 'fainted', 'locked']) {
    test('unavailable $mode has a refusal line and cannot issue a ticket', () {
      var state = _ready();
      if (mode == 'emptyParty') {
        state = state.copyWith(party: const PlayerParty());
      }
      if (mode == 'fainted') {
        state = state.copyWith(
          party: PlayerParty(
            members: [state.party.members.single.copyWith(currentHp: 0)],
          ),
        );
      }
      if (mode == 'locked') {
        state = state.copyWith(progression: const PlayerProgression());
      }
      final interaction = prepareCutObstacleInteraction(
        map: _map(),
        gameState: state,
        stateRevision: 7,
        entityId: 'tree',
      )!;
      expect(interaction.ticket, isNull);
      expect(interaction.session.state, isA<DialogueShowingLine>());
      expect(interaction.session.advance(), isNull);
      expect(
        interaction.complete(
          outcomeId: 'cut-confirmed',
          map: _map(),
          gameState: state,
          currentStateRevision: 7,
        ),
        isNull,
      );
    });
  }

  test('a stale confirmation refuses and leaves the obstacle intact', () {
    final state = _ready();
    final interaction = prepareCutObstacleInteraction(
      map: _map(),
      gameState: state,
      stateRevision: 7,
      entityId: 'tree',
    )!;
    final result = interaction.complete(
      outcomeId: 'cut-confirmed',
      map: _map(),
      gameState: state,
      currentStateRevision: 8,
    ) as CutObstacleRefused;
    expect(result.refusal, FieldActionRefusal.staleStateRevision);
    expect(
      state.mapInstanceWorldState.isFieldObstacleCleared(
        interaction.ticket!.instance,
        'tree',
      ),
      isFalse,
    );
  });

  test('invalid targets never open a field dialogue', () {
    expect(
      prepareCutObstacleInteraction(
        map: _map(),
        gameState: _ready(),
        stateRevision: 7,
        entityId: 'missing',
      ),
      isNull,
    );
    expect(
      prepareCutObstacleInteraction(
        map: _map(),
        gameState: _ready().copyWith(
          mapInstanceWorldState: MapInstanceWorldState(instancesByMapId: {}),
        ),
        stateRevision: 7,
        entityId: 'tree',
      ),
      isNull,
    );
    expect(
      prepareCutObstacleInteraction(
        map: _map(),
        gameState: _ready().copyWith(playerFacing: EntityFacing.west),
        stateRevision: 7,
        entityId: 'tree',
      ),
      isNull,
    );
  });
}

MapData _map() => const MapData(
  id: 'route',
  name: 'Route',
  size: GridSize(width: 5, height: 4),
  entities: [
    MapEntity(
      id: 'tree',
      kind: MapEntityKind.custom,
      pos: GridPos(x: 2, y: 1),
      fieldObstacle: MapEntityFieldObstacleData(),
    ),
  ],
);
GameState _ready() => GameState(
  saveId: 'cut-runtime',
  currentMapId: 'route',
  playerPosition: const GridPos(x: 1, y: 1),
  playerFacing: EntityFacing.east,
  party: const PlayerParty(
    members: [
      PlayerPokemon(
        speciesId: 'scyther',
        natureId: 'hardy',
        abilityId: 'swarm',
        level: 20,
        currentHp: 30,
        knownMoveIds: ['cut'],
      ),
    ],
  ),
  progression: const PlayerProgression(
    unlockedFieldAbilities: [FieldAbility.cut],
  ),
  mapInstanceWorldState: MapInstanceWorldState(
    instancesByMapId: {'route': MapInstanceRuntimeState(instanceId: 'route-1')},
  ),
);
