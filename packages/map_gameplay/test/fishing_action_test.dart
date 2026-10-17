import 'dart:math';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

ProjectItemDefinition rod(ProjectFishingRodKind kind) => ProjectItemDefinition(
      id: 'tool',
      displayName: 'Outil',
      pocketId: 'custom',
      tags: {'key-item'},
      uses: [
        ProjectItemUseDefinition(
          contexts: {ProjectItemUseContext.overworld},
          target: ProjectItemTargetKind.world,
          consumption: ProjectItemConsumptionPolicy.never,
          effect: ProjectItemEffectDefinition.fishing(rodKind: kind),
        )
      ],
    );

GameState state({MovementMode mode = MovementMode.walk}) => GameState(
      saveId: 'fishing',
      currentMapId: 'shore',
      playerPosition: const GridPos(x: 2, y: 2),
      playerFacing: EntityFacing.east,
      playerMovementMode: mode,
      bag: const Bag(entries: [BagEntry(itemId: 'tool', quantity: 1)]),
      repelState: RepelState.active(itemId: 'repel', steps: 8),
      escapeReturnPoint: const EscapeReturnPoint(
          dungeonId: 'cave',
          mapId: 'outside',
          position: GridPos(x: 1, y: 1),
          facing: EntityFacing.south),
    );

MapData waterMap({bool water = true}) => MapData(
      id: 'shore',
      name: 'Shore',
      size: const GridSize(width: 8, height: 8),
      gameplayZones: [
        if (water)
          const MapGameplayZone(
            id: 'water',
            name: 'Water',
            kind: GameplayZoneKind.movement,
            area: MapRect(
                pos: GridPos(x: 3, y: 2), size: GridSize(width: 1, height: 1)),
            movement: MovementZonePayload(requiredMode: MovementMode.surf),
          ),
        for (final kind in ProjectFishingRodKind.values)
          MapGameplayZone(
              id: kind.name,
              name: kind.name,
              kind: GameplayZoneKind.encounter,
              area: const MapRect(
                  pos: GridPos(x: 3, y: 2),
                  size: GridSize(width: 1, height: 1)),
              encounter: EncounterZonePayload(
                  encounterTableId: kind.name,
                  encounterKind: kind.encounterKind)),
      ],
    );

ProjectManifest project(
        {double chance = 1, List<ScriptCondition> conditions = const []}) =>
    ProjectManifest(
      name: 'Fishing',
      maps: [],
      tilesets: [],
      encounterTables: [
        for (final kind in ProjectFishingRodKind.values)
          ProjectEncounterTable(
              id: kind.name,
              name: kind.name,
              encounterKind: kind.encounterKind,
              chancePerStep: chance,
              conditions: conditions,
              entries: [
                ProjectEncounterEntry(
                    speciesId: kind.name,
                    minLevel: 5,
                    maxLevel: 7,
                    weight: 3,
                    pokemonOverrides: const ProjectEncounterPokemonOverrides(
                        shinyPolicy: ProjectEncounterShinyPolicy.never))
              ])
      ],
    );

GameplayWorldState world(MapData map, GameState current) =>
    GameplayWorldState.initial(
      map: map,
      playerPos: current.playerPosition,
      playerFacing: current.playerFacing.asDirection,
      playerMovementMode: current.playerMovementMode,
    );

FishingActionTicket ticket(
        {required MapData map,
        required GameState current,
        required ProjectManifest manifest,
        required ProjectItemDefinition item}) =>
    FishingActionTicket(
      attemptId: 'attempt-1',
      map: map,
      project: manifest,
      gameState: current,
      item: item,
      issuedAtStateRevision: 4,
      mapActivationId: 'activation-1',
    );

void main() {
  for (final kind in ProjectFishingRodKind.values) {
    test(
        '$kind resolves the front source and preserves the real player position',
        () {
      final map = waterMap(),
          current = state(),
          manifest = project(),
          item = rod(kind);
      final random = CountingRandom(42);
      final result = resolveFishingAttempt(
          ticket: ticket(
              map: map, current: current, manifest: manifest, item: item),
          world: world(map, current),
          project: manifest,
          gameState: current,
          item: item,
          currentStateRevision: 4,
          mapActivationId: 'activation-1',
          random: random);
      expect(result.encounterCheck?.triggered, isTrue);
      final encounter = result.encounterCheck!.encounter!;
      expect(encounter.tableId, kind.name);
      expect(encounter.encounterKind, kind.encounterKind);
      expect(encounter.playerPos, current.playerPosition);
      expect(encounter.pokemonOverrides?.shinyPolicy,
          ProjectEncounterShinyPolicy.never);
      expect(random.doubleCalls, 1);
      expect(random.intCalls, 2);
      expect(current.bag.entries.single.quantity, 1);
      expect(current.repelState.remainingSteps, 8);
    });
  }

  test('walking, bicycle and Surf share fishing, while Dive and 3D refuse', () {
    final manifest = project(), item = rod(ProjectFishingRodKind.oldRod);
    for (final mode in [
      MovementMode.walk,
      MovementMode.bicycle,
      MovementMode.surf
    ]) {
      final current = state(mode: mode);
      final map = waterMap();
      final evaluation = evaluateFishingAttempt(
          world: world(map, current),
          project: manifest,
          gameState: current,
          item: item);
      expect(evaluation.isReady, isTrue);
      expect(current.playerMovementMode, mode);
    }
    final diving = state(mode: MovementMode.dive);
    expect(
        evaluateFishingAttempt(
                world: world(waterMap(), diving),
                project: manifest,
                gameState: diving,
                item: item)
            .reason,
        FishingBlockReason.unavailableContext);
    final spatial = waterMap().copyWith(version: ProjectVersion.v9);
    final current = state();
    expect(
        evaluateFishingAttempt(
                world: world(spatial, current),
                project: manifest,
                gameState: current,
                item: item)
            .reason,
        FishingBlockReason.unsupportedMap);
  });

  test('refusals and stale tickets spend no randomness', () {
    final map = waterMap(),
        current = state(),
        manifest = project(),
        item = rod(ProjectFishingRodKind.oldRod);
    final original =
        ticket(map: map, current: current, manifest: manifest, item: item);
    for (final changed in [
      (
        map: waterMap(water: false),
        current: current,
        item: item,
        revision: 4,
        activation: 'activation-1'
      ),
      (
        map: map,
        current: current.copyWith(bag: const Bag()),
        item: item,
        revision: 4,
        activation: 'activation-1'
      ),
      (
        map: map,
        current: current.copyWith(playerFacing: EntityFacing.west),
        item: item,
        revision: 4,
        activation: 'activation-1'
      ),
      (
        map: map,
        current: current,
        item: rod(ProjectFishingRodKind.superRod),
        revision: 4,
        activation: 'activation-1'
      ),
      (
        map: map,
        current: current,
        item: item,
        revision: 5,
        activation: 'activation-1'
      ),
      (
        map: map,
        current: current,
        item: item,
        revision: 4,
        activation: 'activation-2'
      ),
    ]) {
      final random = CountingRandom(1);
      final result = resolveFishingAttempt(
          ticket: original,
          world: world(changed.map, changed.current),
          project: manifest,
          gameState: changed.current,
          item: changed.item,
          currentStateRevision: changed.revision,
          mapActivationId: changed.activation,
          random: random);
      expect(result.reason, FishingBlockReason.staleAttempt);
      expect(random.doubleCalls + random.intCalls, 0);
    }
    expect(
        evaluateFishingAttempt(
                world: world(waterMap(water: false), current),
                project: manifest,
                gameState: current,
                item: item)
            .reason,
        FishingBlockReason.notWater);
    expect(
        evaluateFishingAttempt(
                world: world(map, current.copyWith(bag: const Bag())),
                project: manifest,
                gameState: current.copyWith(bag: const Bag()),
                item: item)
            .reason,
        FishingBlockReason.insufficientQuantity);
    expect(
        evaluateFishingAttempt(
            world: world(map, current),
            project: manifest,
            gameState: current,
            item: item.copyWith(tags: {})).reason,
        FishingBlockReason.invalidItem);
  });

  test('missing, mismatched and conditioned tables refuse before RNG', () {
    final map = waterMap(),
        current = state(),
        item = rod(ProjectFishingRodKind.oldRod);
    for (final manifest in [
      project().copyWith(encounterTables: []),
      project().copyWith(encounterTables: [
        project()
            .encounterTables
            .first
            .copyWith(encounterKind: EncounterKind.walk)
      ]),
      project(conditions: [ScriptConditionFactory.flagIsSet('open')]),
    ]) {
      final random = CountingRandom(1);
      final result = resolveFishingAttempt(
          ticket: ticket(
              map: map, current: current, manifest: manifest, item: item),
          world: world(map, current),
          project: manifest,
          gameState: current,
          item: item,
          currentStateRevision: 4,
          mapActivationId: 'activation-1',
          random: random);
      expect(result.encounterCheck?.triggered ?? false, isFalse);
      expect(random.doubleCalls + random.intCalls, 0);
    }
  });

  test('typed narrative facts are evaluated in the fishing context before RNG',
      () {
    final map = waterMap(),
        current = state(),
        item = rod(ProjectFishingRodKind.oldRod);
    final manifest = project(conditions: [
      ScriptConditionFactory.factEquals(
          'weather', const NarrativeValue.string('rain'))
    ]);
    final context = ScriptEvaluationContext(
        narrativeFactResolver: NarrativeFactRuntimeResolver.fromFacts([
      NarrativeFactDefinition(
          id: 'weather',
          label: 'Weather',
          initialValue: const NarrativeValue.string('rain')),
    ]));
    final random = CountingRandom(1);
    final result = resolveFishingAttempt(
        ticket:
            ticket(map: map, current: current, manifest: manifest, item: item),
        world: world(map, current),
        project: manifest,
        gameState: current,
        item: item,
        currentStateRevision: 4,
        mapActivationId: 'activation-1',
        conditionContext: context,
        random: random);
    expect(result.encounterCheck?.triggered, isTrue);
    expect(random.doubleCalls, 1);
    final blockedRandom = CountingRandom(1);
    final blocked = resolveFishingAttempt(
        ticket:
            ticket(map: map, current: current, manifest: manifest, item: item),
        world: world(map, current),
        project: manifest,
        gameState: current,
        item: item,
        currentStateRevision: 4,
        mapActivationId: 'activation-1',
        random: blockedRandom);
    expect(blocked.encounterCheck?.triggered ?? false, isFalse);
    expect(blockedRandom.doubleCalls + blockedRandom.intCalls, 0);
  });

  test(
      'authored probability is rolled once and no bite consumes no candidate RNG',
      () {
    final map = waterMap(),
        current = state(),
        manifest = project(chance: 0),
        item = rod(ProjectFishingRodKind.oldRod);
    final random = CountingRandom(1);
    final result = resolveFishingAttempt(
        ticket:
            ticket(map: map, current: current, manifest: manifest, item: item),
        world: world(map, current),
        project: manifest,
        gameState: current,
        item: item,
        currentStateRevision: 4,
        mapActivationId: 'activation-1',
        random: random);
    expect(
        result.encounterCheck?.status, GameplayEncounterCheckStatus.rollFailed);
    expect(random.doubleCalls, 1);
    expect(random.intCalls, 0);
  });

  test(
      'flow resolves once after casting and waiting, cancel prevents late callback',
      () {
    var resolutions = 0;
    final flow = FishingAttemptFlow();
    flow.advance(.4, resolve: () {
      resolutions++;
      return const FishingAttemptResult();
    });
    expect(flow.phase, FishingAttemptPhase.waiting);
    expect(resolutions, 0);
    flow.cancel();
    flow.advance(10, resolve: () {
      resolutions++;
      return const FishingAttemptResult();
    });
    expect(flow.phase, FishingAttemptPhase.cancelled);
    expect(resolutions, 0);
    final completed = FishingAttemptFlow();
    for (var i = 0; i < 50; i++) {
      completed.advance(.1, resolve: () {
        resolutions++;
        return const FishingAttemptResult();
      });
    }
    expect(completed.phase, FishingAttemptPhase.finished);
    expect(resolutions, 1);
  });
}

class CountingRandom implements Random {
  CountingRandom(int seed) : delegate = Random(seed);
  final Random delegate;
  int doubleCalls = 0, intCalls = 0;
  @override
  double nextDouble() {
    doubleCalls++;
    return delegate.nextDouble();
  }

  @override
  int nextInt(int max) {
    intCalls++;
    return delegate.nextInt(max);
  }

  @override
  bool nextBool() => delegate.nextBool();
}
