import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  flyTests();
  test('Fly cannot bypass a validated Dive ascent', () {
    final result = evaluateFlyAttempt(
        sourceMap: sourceMap(),
        sourceRole: MapRole.exterior,
        targetMap: targetMap(),
        gameState:
            readyForFly().copyWith(playerMovementMode: MovementMode.dive),
        catalog: flyCatalog(),
        pointId: 'town.poi');
    expect(result, isA<FlyUnavailable>());
  });
  test('Vol is serializable and remains outside the signed beta abilities', () {
    final ability = FieldAbility.values.byName('fly');
    expect(ability.moveId, 'fly');
    final state = GameState(
      saveId: 'fly',
      currentMapId: 'source',
      playerPosition: const GridPos(x: 1, y: 1),
      progression: PlayerProgression(unlockedFieldAbilities: [ability]),
    );
    expect(
        GameState.fromJson(state.toJson()).progression.unlockedFieldAbilities,
        [ability]);
    final badge = BadgeDefinition(
        id: 'sky', label: 'Badge Ciel', fieldAbilityUnlock: ability);
    expect(
        BadgeDefinition.fromJson(badge.toJson()).fieldAbilityUnlock, ability);
    final trainer = ProjectTrainerEntry(
        id: 'sky-leader',
        name: 'Sky',
        trainerClass: 'Leader',
        rewardFieldAbilityUnlock: ability);
    expect(
        ProjectTrainerEntry.fromJson(trainer.toJson()).rewardFieldAbilityUnlock,
        ability);
    expect(betaSignedFieldAbilities, {FieldAbility.surf});
  });
}

MapData sourceMap() => const MapData(
    id: 'source', name: 'Source', size: GridSize(width: 8, height: 8));
MapData targetMap() => const MapData(
        id: 'town',
        name: 'Town',
        size: GridSize(width: 8, height: 8),
        entities: [
          MapEntity(
              id: 'arrival',
              kind: MapEntityKind.spawn,
              pos: GridPos(x: 3, y: 4),
              blocksMovement: false,
              spawn: MapEntitySpawnData(
                  spawnKey: 'town_gate', facing: EntityFacing.west))
        ]);
ProjectRegionalMapCatalog flyCatalog(
        {bool hidden = false, String spawn = 'arrival'}) =>
    ProjectRegionalMapCatalog(regions: [
      ProjectRegionDefinition(id: 'region', label: 'Region')
    ], pointsOfInterest: [
      ProjectRegionPointOfInterest(
          id: 'town.poi',
          regionId: 'region',
          label: 'Town',
          u: .4,
          v: .5,
          discovery: ProjectRegionPointDiscovery.always,
          visibility: hidden
              ? ProjectRegionPointVisibility.hidden
              : ProjectRegionPointVisibility.always,
          mapIds: ['town'],
          destination: ProjectRegionDestination(mapId: 'town', spawnId: spawn))
    ]);
GameState readyForFly() => GameState(
    saveId: 'fly',
    currentMapId: 'source',
    playerPosition: GridPos(x: 1, y: 1),
    playerMovementMode: MovementMode.surf,
    party: PlayerParty(members: [
      PlayerPokemon(
          speciesId: 'pidgeot',
          natureId: 'hardy',
          abilityId: 'keen_eye',
          currentHp: 25,
          knownMoveIds: ['fly'],
          currentPpByMoveId: {'fly': 0})
    ]),
    progression: PlayerProgression(unlockedFieldAbilities: [FieldAbility.fly]),
    narrativeEventProgress:
        NarrativeEventProgress(visitedNarrativeMapIds: {'town'}));

void flyTests() {
  FlyEvaluation evaluate(
          {GameState? state,
          MapData? source,
          MapData? target,
          ProjectRegionalMapCatalog? catalog,
          MapRole role = MapRole.exterior}) =>
      evaluateFlyAttempt(
          sourceMap: source ?? sourceMap(),
          sourceRole: role,
          targetMap: target ?? targetMap(),
          gameState: state ?? readyForFly(),
          catalog: catalog ?? flyCatalog(),
          pointId: 'town.poi');
  test(
      'Fly resolves an explicit unique spawn without spending PP or mutating state',
      () {
    final state = readyForFly(), catalog = flyCatalog();
    final evaluation = evaluate(state: state, catalog: catalog) as CanUseFly;
    expect(evaluation.arrival.entityId, 'arrival');
    expect(evaluation.arrival.position, const GridPos(x: 3, y: 4));
    expect(evaluation.arrival.facing, EntityFacing.west);
    final ticket = FlyActionTicket(
        evaluation: evaluation,
        gameState: state,
        sourceMap: sourceMap(),
        targetMap: targetMap(),
        catalog: catalog,
        issuedAtStateRevision: 7);
    final result = commitFlyAction(
        ticket: ticket,
        sourceMap: sourceMap(),
        targetMap: targetMap(),
        sourceRole: MapRole.exterior,
        gameState: state,
        catalog: catalog,
        currentStateRevision: 7) as FlyReady;
    expect(result.arrival, evaluation.arrival);
    expect(state.party.members.single.currentPpByMoveId!['fly'], 0);
    expect(state.playerMovementMode, MovementMode.surf);
    expect(
        (evaluate(catalog: flyCatalog(spawn: 'town_gate')) as CanUseFly)
            .arrival,
        evaluation.arrival);
  });
  test('display always does not grant Fly before an actual visit', () {
    final result = evaluate(
        state: readyForFly()
            .copyWith(narrativeEventProgress: NarrativeEventProgress()));
    expect((result as FlyUnavailable).reason, FlyBlockReason.notVisited);
  });
  test('Fly rejects missing, fainted and locked team gates', () {
    for (final change in [
      (
        readyForFly().copyWith(party: const PlayerParty()),
        FlyBlockReason.missingMove
      ),
      (
        readyForFly().copyWith(
            party: PlayerParty(members: [
          readyForFly().party.members.single.copyWith(currentHp: 0)
        ])),
        FlyBlockReason.missingMove
      ),
      (
        readyForFly().copyWith(progression: const PlayerProgression()),
        FlyBlockReason.locked
      ),
    ]) {
      expect((evaluate(state: change.$1) as FlyUnavailable).reason, change.$2);
    }
  });
  test(
      'Fly rejects every existing indoor classification and non native 2D maps',
      () {
    expect((evaluate(role: MapRole.interior) as FlyUnavailable).reason,
        FlyBlockReason.indoor);
    for (final type in [
      MapType.building,
      MapType.interior,
      MapType.cave,
      MapType.facility
    ]) {
      expect(
          (evaluate(
                      source: sourceMap()
                          .copyWith(mapMetadata: MapMetadata(mapType: type)))
                  as FlyUnavailable)
              .reason,
          FlyBlockReason.indoor);
    }
    expect(
        (evaluate(
                    source: sourceMap().copyWith(
                        mapMetadata: const MapMetadata(isIndoor: true)))
                as FlyUnavailable)
            .reason,
        FlyBlockReason.indoor);
    expect(
        (evaluate(target: targetMap().copyWith(version: ProjectVersion.v9))
                as FlyUnavailable)
            .reason,
        FlyBlockReason.unsupportedMap);
  });
  test('Fly rejects hidden, missing, ambiguous and out of bounds arrivals', () {
    expect(
        (evaluate(catalog: flyCatalog(hidden: true)) as FlyUnavailable).reason,
        FlyBlockReason.invalidDestination);
    expect(
        (evaluate(catalog: ProjectRegionalMapCatalog()) as FlyUnavailable)
            .reason,
        FlyBlockReason.invalidDestination);
    expect(
        (evaluate(catalog: flyCatalog(spawn: 'missing')) as FlyUnavailable)
            .reason,
        FlyBlockReason.invalidSpawn);
    expect(
        (evaluate(
                target: targetMap().copyWith(entities: [
          targetMap().entities.single,
          targetMap().entities.single.copyWith(
              id: 'other', spawn: const MapEntitySpawnData(spawnKey: 'arrival'))
        ])) as FlyUnavailable)
            .reason,
        FlyBlockReason.invalidSpawn);
    expect(
        (evaluate(
                target: targetMap().copyWith(entities: [
          targetMap().entities.single.copyWith(pos: const GridPos(x: 8, y: 4))
        ])) as FlyUnavailable)
            .reason,
        FlyBlockReason.invalidSpawn);
  });
  test(
      'Fly confirmation refuses state, source, catalog and arrival changes even at the same revision',
      () {
    final state = readyForFly(), catalog = flyCatalog();
    final ticket = FlyActionTicket(
        evaluation: evaluate() as CanUseFly,
        gameState: state,
        sourceMap: sourceMap(),
        targetMap: targetMap(),
        catalog: catalog,
        issuedAtStateRevision: 7);
    for (final change in [
      (
        state.copyWith(playerFacing: EntityFacing.north),
        sourceMap(),
        targetMap(),
        catalog,
        7
      ),
      (state, sourceMap(), targetMap(), catalog, 8),
      (state, sourceMap(), targetMap(), flyCatalog(hidden: true), 7),
      (state, sourceMap(), targetMap().copyWith(entities: []), catalog, 7),
      (state, sourceMap().copyWith(name: 'Changed'), targetMap(), catalog, 7),
    ]) {
      expect(
          commitFlyAction(
              ticket: ticket,
              sourceMap: change.$2,
              targetMap: change.$3,
              sourceRole: MapRole.exterior,
              gameState: change.$1,
              catalog: change.$4,
              currentStateRevision: change.$5),
          isA<FlyRefused>());
    }
  });
}
