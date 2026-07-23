import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('commits a completed shop overlay and always releases input', () async {
    const initial = GameState(saveId: 'services');
    final next = initial.copyWith(
      trainerProfile: const TrainerProfile(name: 'Leaf', money: 700),
    );
    final locks = <bool>[];
    GameState? committed;
    final host = _Host(
      onShop: (request) async {
        expect(request.shop.id, 'mart');
        expect(request.gameState, same(initial));
        return PlayerServiceHostResult.completed(next);
      },
    );
    final controller = PlayerServiceRuntimeController(
      currentGameState: () => initial,
      host: host,
      commitAndSave: (state) async => committed = state,
      setInputLocked: locks.add,
      loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(
        maxHpByPartyIndex: <int, int>{},
      ),
    );

    final result = await controller.openShop(
      const ShopDefinition(id: 'mart', label: 'Boutique'),
    );

    expect(result.status, PlayerServiceRuntimeStatus.completed);
    expect(result.gameState, same(next));
    expect(committed, same(next));
    expect(locks, <bool>[true, false]);
  });

  test('cancellation does not commit and concurrent overlays are rejected',
      () async {
    const state = GameState(saveId: 'services');
    final pending = Completer<PlayerServiceHostResult>();
    var commits = 0;
    final host = _Host(onPc: (_) => pending.future);
    final controller = PlayerServiceRuntimeController(
      currentGameState: () => state,
      host: host,
      commitAndSave: (_) async => commits += 1,
      setInputLocked: (_) {},
      loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(
        maxHpByPartyIndex: <int, int>{},
      ),
    );

    final first = controller.openPc();
    final concurrent = await controller.openHealCenter();
    expect(concurrent.status, PlayerServiceRuntimeStatus.busy);
    expect(host.pcCalls, 1);
    expect(host.healCalls, 0);

    pending.complete(const PlayerServiceHostResult.cancelled());
    final cancelled = await first;
    expect(cancelled.status, PlayerServiceRuntimeStatus.cancelled);
    expect(commits, 0);
  });

  test('host and transaction exceptions fail closed and release input',
      () async {
    const state = GameState(saveId: 'services');
    final locks = <bool>[];
    final throwingHost = _Host(
      onHeal: (_) => Future<PlayerServiceHostResult>.error(
        StateError('navigator failed'),
      ),
    );
    final controller = PlayerServiceRuntimeController(
      currentGameState: () => state,
      host: throwingHost,
      commitAndSave: (_) async {},
      setInputLocked: locks.add,
      loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(
        maxHpByPartyIndex: <int, int>{},
      ),
    );

    final hostFailure = await controller.openHealCenter();
    expect(hostFailure.status, PlayerServiceRuntimeStatus.failed);
    expect(hostFailure.error, isA<StateError>());
    expect(locks, <bool>[true, false]);

    final transactionController = PlayerServiceRuntimeController(
      currentGameState: () => state,
      host: _Host(
        onPc: (_) async => PlayerServiceHostResult.completed(
          state.copyWith(currentMapId: 'port'),
        ),
      ),
      commitAndSave: (_) => Future<void>.error(StateError('disk failed')),
      setInputLocked: locks.add,
      loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(
        maxHpByPartyIndex: <int, int>{},
      ),
    );
    final transactionFailure = await transactionController.openPc();
    expect(transactionFailure.status, PlayerServiceRuntimeStatus.failed);
    expect(transactionFailure.error, isA<StateError>());
    expect(locks, <bool>[true, false, true, false]);
  });
}

final class _Host implements PlayerServiceOverlayHost {
  _Host({this.onShop, this.onPc, this.onHeal});

  final Future<PlayerServiceHostResult> Function(PlayerServiceShopRequest)?
      onShop;
  final Future<PlayerServiceHostResult> Function(PlayerServicePcRequest)? onPc;
  final Future<PlayerServiceHostResult> Function(PlayerServiceHealRequest)?
      onHeal;
  int pcCalls = 0;
  int healCalls = 0;

  @override
  Future<PlayerServiceHostResult> openShop(PlayerServiceShopRequest request) =>
      onShop?.call(request) ??
      Future<PlayerServiceHostResult>.value(
        const PlayerServiceHostResult.cancelled(),
      );

  @override
  Future<PlayerServiceHostResult> openPc(PlayerServicePcRequest request) {
    pcCalls += 1;
    return onPc?.call(request) ??
        Future<PlayerServiceHostResult>.value(
          const PlayerServiceHostResult.cancelled(),
        );
  }

  @override
  Future<PlayerServiceHostResult> openHealCenter(
    PlayerServiceHealRequest request,
  ) {
    healCalls += 1;
    return onHeal?.call(request) ??
        Future<PlayerServiceHostResult>.value(
          const PlayerServiceHostResult.cancelled(),
        );
  }
}
