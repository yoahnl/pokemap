import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_gameplay/map_gameplay.dart';

void main() {
  const initial = GameState(
      saveId: 'regional-map',
      currentMapId: 'center',
      playerPosition: GridPos(x: 14, y: 4),
      playerFacing: EntityFacing.north);
  RuntimePlayerPauseDetailSnapshot detail({bool empty = false}) =>
      RuntimePlayerPauseDetailSnapshot(
          section: RuntimePlayerPauseSection.map,
          title: 'Map',
          regionalMap: RuntimePlayerRegionMapSnapshot(regions: [
            if (!empty)
              RuntimePlayerRegionSnapshot(id: 'kanto', label: 'Kanto', points: [
                const RuntimePlayerMapPointSnapshot(
                    id: 'route10',
                    label: 'Route 10',
                    status: RuntimePlayerMapPointStatus.current,
                    u: .6,
                    v: .2)
              ])
          ]));

  test('selection requires fresh confirmation and cancellation leaves state untouched', () async {
    var state = initial;
    var transfers = 0;
    final map = MapData(id: 'center', name: 'Center', size: const GridSize(width: 20, height: 20));
    final ticket = FlyActionTicket(
      evaluation: const CanUseFly(pointId: 'route10', partyIndex: 0,
        arrival: FlyArrival(mapId: 'route10', entityId: 'spawn', position: GridPos(x: 3, y: 4), facing: EntityFacing.west)),
      gameState: state, sourceMap: map, targetMap: map,
      catalog: ProjectRegionalMapCatalog(), issuedAtStateRevision: 1);
    final controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => state,
      commitAndSave: (_) async => fail('Fly uses the normal explicit save flow.'),
      setInputLocked: (_) {}, loadRecoveryCaps: (_) async => throw StateError('No healing'),
    );
    addTearDown(controller.dispose);
    final open = controller.openRegionalMap(
      request: const OpenRegionalMapService(interactionId: 'player.map'), detail: detail(),
      prepareFly: (id) async => (ticket: id == 'route10' ? ticket : null, reason: FlyBlockReason.notVisited),
      applyFly: (_) async {
        transfers++;
        state = state.copyWith(currentMapId: 'route10', playerPosition: const GridPos(x: 3, y: 4),
          playerFacing: EntityFacing.west, playerMovementMode: MovementMode.walk);
        return true;
      });
    Future<RuntimeWorldServiceCommandResult> command(RuntimeWorldServiceAction action, {String? id, int? revision}) =>
      controller.dispatchWorldService(RuntimeWorldServiceCommand(action: action,
        targetId: id, snapshotRevision: revision ?? controller.worldServiceSnapshot!.revision));
    expect((await command(RuntimeWorldServiceAction.select, id: 'missing')).status, RuntimeWorldServiceCommandStatus.unavailable);
    expect((await command(RuntimeWorldServiceAction.select, id: 'route10')).status, RuntimeWorldServiceCommandStatus.accepted);
    final firstConfirmation = controller.worldServiceSnapshot!.revision;
    expect((controller.worldServiceSnapshot!.content as RuntimeRegionalMapServiceContent).selectedPointId, 'route10');
    expect((await command(RuntimeWorldServiceAction.cancel)).status, RuntimeWorldServiceCommandStatus.accepted);
    expect(transfers, 0);
    expect(state, initial);
    expect((await command(RuntimeWorldServiceAction.confirm, revision: firstConfirmation)).status, RuntimeWorldServiceCommandStatus.stale);
    await command(RuntimeWorldServiceAction.select, id: 'route10');
    final confirmation = controller.worldServiceSnapshot!.revision;
    expect((await command(RuntimeWorldServiceAction.confirm)).status, RuntimeWorldServiceCommandStatus.accepted);
    expect(transfers, 1);
    expect(state.currentMapId, 'route10');
    expect((await open).status, PlayerServiceRuntimeStatus.completed);
    expect((await controller.dispatchWorldService(RuntimeWorldServiceCommand(action: RuntimeWorldServiceAction.confirm,
      snapshotRevision: confirmation))).status, isNot(RuntimeWorldServiceCommandStatus.accepted));
  });

  test('awaits map close without save, healing, travel or game-state mutation',
      () async {
    var state = initial;
    final locks = <bool>[];
    final controller = PlayerServiceRuntimeController.contextual(
        currentGameState: () => state,
        commitAndSave: (_) async => fail('Read-only maps cannot save.'),
        setInputLocked: locks.add,
        loadRecoveryCaps: (_) async => throw StateError('No healing requested.'));
    addTearDown(controller.dispose);
    var completed = false;
    final open = controller.openRegionalMap(
        request: const OpenRegionalMapService(interactionId: 'wall.map'),
        detail: detail());
    open.then((_) => completed = true);
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);
    final snapshot = controller.worldServiceSnapshot!;
    expect(snapshot.request.kind, RuntimeWorldServiceKind.regionalMap);
    expect(snapshot.content, isA<RuntimeRegionalMapServiceContent>());
    expect(snapshot.isActionEnabled(RuntimeWorldServiceAction.close), isTrue);
    expect(snapshot.isActionEnabled(RuntimeWorldServiceAction.confirm), isFalse);
    expect(locks, [true]);
    state = state.copyWith(playerFacing: EntityFacing.west);
    final stale = await controller.dispatchWorldService(RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.close,
        snapshotRevision: snapshot.revision + 1));
    expect(stale.status, RuntimeWorldServiceCommandStatus.stale);
    expect(completed, isFalse);
    final close = await controller.dispatchWorldService(RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.close,
        snapshotRevision: snapshot.revision));
    expect(close.status, RuntimeWorldServiceCommandStatus.accepted);
    final result = await open;
    expect(result.status, PlayerServiceRuntimeStatus.completed);
    expect(result.gameState, same(state));
    expect(state.playerPosition, initial.playerPosition);
    expect(locks, [true, false]);
    expect(controller.worldServiceSnapshot, isNull);
  });

  test('configured Back cancels the native map without saving or completing', () async {
    final locks = <bool>[];
    final controller = PlayerServiceRuntimeController.contextual(
        currentGameState: () => initial,
        commitAndSave: (_) async => fail('Read-only maps cannot save.'),
        setInputLocked: locks.add,
        loadRecoveryCaps: (_) async => throw StateError('No healing requested.'));
    addTearDown(controller.dispose);
    final open = controller.openRegionalMap(
        request: const OpenRegionalMapService(interactionId: 'wall.map'),
        detail: detail());
    final snapshot = controller.worldServiceSnapshot!;
    final cancel = await controller.dispatchWorldService(RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.cancel,
        snapshotRevision: snapshot.revision));
    expect(cancel.status, RuntimeWorldServiceCommandStatus.accepted);
    expect((await open).status, PlayerServiceRuntimeStatus.cancelled);
    expect(locks, [true, false]);
    expect(controller.worldServiceSnapshot, isNull);
  });

  test('refuses unavailable maps and denied access before locking input', () async {
    final locks = <bool>[];
    final controller = PlayerServiceRuntimeController.contextual(
        currentGameState: () => initial,
        commitAndSave: (_) async => fail('Read-only maps cannot save.'),
        setInputLocked: locks.add,
        loadRecoveryCaps: (_) async => throw StateError('No healing requested.'));
    addTearDown(controller.dispose);
    for (final request in [
      const OpenRegionalMapService(interactionId: 'empty.map'),
      const OpenRegionalMapService(
          interactionId: 'locked.map', requiredCapabilities: {'ungranted'})
    ]) {
      final result = await controller.openRegionalMap(
          request: request, detail: detail(empty: request.interactionId == 'empty.map'));
      expect(result.status, PlayerServiceRuntimeStatus.unavailable);
    }
    expect(locks, isEmpty);
    expect(controller.worldServiceSnapshot, isNull);
  });

  test('owns one modal and cancels its pending map on disposal', () async {
    final locks = <bool>[];
    final controller = PlayerServiceRuntimeController.contextual(
        currentGameState: () => initial,
        commitAndSave: (_) async => fail('Read-only maps cannot save.'),
        setInputLocked: locks.add,
        loadRecoveryCaps: (_) async => throw StateError('No healing requested.'));
    final open = controller.openRegionalMap(
        request: const OpenRegionalMapService(interactionId: 'wall.map'),
        detail: detail());
    final busy = await controller.openRegionalMap(
        request: const OpenRegionalMapService(interactionId: 'another.map'),
        detail: detail());
    expect(busy.status, PlayerServiceRuntimeStatus.busy);
    await controller.dispose();
    expect((await open).status, PlayerServiceRuntimeStatus.cancelled);
    expect(locks, [true, false]);
    expect(controller.worldServiceSnapshot, isNull);
  });
}
