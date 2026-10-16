import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

MapData outside() => const MapData(
    id: 'outside', name: 'Outside', size: GridSize(width: 8, height: 8));
MapData floor(String id,
        {String dungeon = 'cave', bool allowed = true}) =>
    MapData(
        id: id,
        name: id,
        size: const GridSize(width: 8, height: 8),
        mapMetadata: MapMetadata(
            escapeRopeDungeonId: dungeon, allowEscapeRope: allowed));
const rope = ProjectItemDefinition(
    id: 'rope',
    displayName: 'Corde Sortie',
    pocketId: 'items',
    uses: [
      ProjectItemUseDefinition(
          contexts: {ProjectItemUseContext.overworld},
          target: ProjectItemTargetKind.world,
          consumption: ProjectItemConsumptionPolicy.onApplied,
          effect: ProjectItemEffectDefinition.escapeRope())
    ]);
const entry = GameState(
    saveId: 'rope',
    currentMapId: 'outside',
    playerPosition: GridPos(x: 3, y: 3),
    playerFacing: EntityFacing.west,
    bag: Bag(entries: [BagEntry(itemId: 'rope', quantity: 2)]));
GameState enter({MapData? target, GameState state = entry}) {
  final destination = target ?? floor('first');
  return state.copyWith(
      currentMapId: destination.id,
      escapeReturnPoint: escapeReturnPointAfterTransfer(
          sourceMap: outside(), targetMap: destination, sourceState: state));
}

void main() {
  test('outside -> floor 1 -> floor 2 retains exact entry and source facing',
      () {
    final first = enter();
    final anchor = escapeReturnPointAfterTransfer(
        sourceMap: floor('first'),
        targetMap: floor('second'),
        sourceState: first);
    expect(anchor, first.escapeReturnPoint);
    final second =
        first.copyWith(currentMapId: 'second', escapeReturnPoint: anchor);
    final evaluation = evaluateEscapeRopeAttempt(
        sourceMap: floor('second'),
        targetMap: outside(),
        gameState: second,
        item: rope);
    expect(evaluation, isA<CanUseEscapeRope>());
    expect((evaluation as CanUseEscapeRope).arrival.position,
        entry.playerPosition);
    expect(evaluation.arrival.facing, EntityFacing.west);
    expect(second.bag, entry.bag);
  });
  test(
      'exit clears anchor, reentry captures new door, other dungeon never reuses anchor',
      () {
    final first = enter();
    expect(
        escapeReturnPointAfterTransfer(
            sourceMap: floor('first'),
            targetMap: outside(),
            sourceState: first),
        isNull);
    expect(
        escapeReturnPointAfterTransfer(
            sourceMap: floor('first'),
            targetMap: floor('other', dungeon: 'other'),
            sourceState: first),
        isNull);
    final newEntry =
        enter(state: entry.copyWith(playerPosition: const GridPos(x: 5, y: 5)));
    expect(newEntry.escapeReturnPoint!.position, const GridPos(x: 5, y: 5));
  });
  test('forbidden floor preserves anchor but refuses rope', () {
    final state = enter();
    final target = floor('forbidden', allowed: false);
    expect(
        escapeReturnPointAfterTransfer(
            sourceMap: floor('first'), targetMap: target, sourceState: state),
        state.escapeReturnPoint);
    expect(
        (evaluateEscapeRopeAttempt(
                sourceMap: target,
                targetMap: outside(),
                gameState: state.copyWith(currentMapId: target.id),
                item: rope) as EscapeRopeUnavailable)
            .reason,
        EscapeRopeBlockReason.forbiddenMap);
  });
  test(
      'missing anchor, wrong dungeon, zero inventory, water and unsupported map refuse',
      () {
    final state = enter();
    for (final invalid in [
      state.copyWith(escapeReturnPoint: null),
      state.copyWith(bag: const Bag()),
      state.copyWith(playerMovementMode: MovementMode.surf),
      state.copyWith(playerMovementMode: MovementMode.dive),
      state.copyWith(
          escapeReturnPoint: state.escapeReturnPoint == null
              ? null
              : const EscapeReturnPoint(
                  dungeonId: 'other',
                  mapId: 'outside',
                  position: GridPos(x: 3, y: 3),
                  facing: EntityFacing.south))
    ]) {
      expect(
          evaluateEscapeRopeAttempt(
              sourceMap: floor('first'),
              targetMap: outside(),
              gameState: invalid,
              item: rope),
          isA<EscapeRopeUnavailable>());
    }
    expect(
        evaluateEscapeRopeAttempt(
            sourceMap: floor('first').copyWith(version: ProjectVersion.v9),
            targetMap: outside(),
            gameState: state,
            item: rope),
        isA<EscapeRopeUnavailable>());
    expect(
        evaluateEscapeRopeAttempt(
            sourceMap: floor('first'),
            targetMap: null,
            gameState: state,
            item: rope),
        isA<EscapeRopeUnavailable>());
  });
  test('canonical key item tag rejects escape before any consumption', () {
    final state = enter();
    expect(
        (evaluateEscapeRopeAttempt(
                    sourceMap: floor('first'),
                    targetMap: outside(),
                    gameState: state,
                    item: rope.copyWith(tags: {'key-item'}))
                as EscapeRopeUnavailable)
            .reason,
        EscapeRopeBlockReason.invalidItem);
    expect(state.bag, entry.bag);
  });
  test(
      'out of bounds and blocking NPC arrival refuse without a nearby fallback',
      () {
    final state = enter();
    for (final target in [
      outside().copyWith(size: const GridSize(width: 2, height: 2)),
      outside().copyWith(entities: [
        const MapEntity(
            id: 'blocked',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 3, y: 3),
            blocksMovement: true)
      ])
    ]) {
      expect(
          evaluateEscapeRopeAttempt(
              sourceMap: floor('first'),
              targetMap: target,
              gameState: state,
              item: rope),
          isA<EscapeRopeUnavailable>());
    }
  });
  test(
      'confirmation revalidates revision, map and inventory then consumes once',
      () {
    final state = enter(), source = floor('first'), target = outside();
    final evaluation = evaluateEscapeRopeAttempt(
        sourceMap: source,
        targetMap: target,
        gameState: state,
        item: rope) as CanUseEscapeRope;
    final ticket = EscapeRopeActionTicket(
        evaluation: evaluation,
        gameState: state,
        sourceMap: source,
        targetMap: target,
        item: rope,
        issuedAtStateRevision: 7);
    GameState? commit(
            {GameState? current, int revision = 7, MapData? currentTarget}) =>
        commitEscapeRopeAction(
            ticket: ticket,
            sourceMap: source,
            targetMap: currentTarget ?? target,
            gameState: current ?? state,
            item: rope,
            currentStateRevision: revision);
    expect(commit(revision: 8), isNull);
    expect(commit(current: state.copyWith(bag: const Bag())), isNull);
    expect(commit(currentTarget: target.copyWith(name: 'Changed')), isNull);
    final applied = commit()!;
    expect(applied.bag.entries.single.quantity, 1);
    expect(applied.currentMapId, 'outside');
    expect(applied.playerPosition, entry.playerPosition);
    expect(applied.escapeReturnPoint, isNull);
    expect(commit(current: applied), isNull);
  });
}
