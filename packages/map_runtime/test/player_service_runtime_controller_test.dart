import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
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

  test('emits the highest-priority resolved shop profile', () async {
    const initial = GameState(
      saveId: 'dynamic-shop',
      storyFlags: StoryFlags(activeFlags: <String>{'story_finished'}),
    );
    final host = _Host(
      onShop: (request) async {
        expect(request.shop.id, 'mart');
        expect(request.gameState, same(initial));
        expect(request.resolvedState.stateId, 'story-finished');
        expect(
          request.resolvedState.storefrontLabel,
          'Grand Comptoir des Brisants',
        );
        return const PlayerServiceHostResult.cancelled();
      },
    );
    final controller = PlayerServiceRuntimeController(
      currentGameState: () => initial,
      host: host,
      commitAndSave: (_) async {},
      setInputLocked: (_) {},
      loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(
        maxHpByPartyIndex: <int, int>{},
      ),
    );

    final result = await controller.openShop(
      ShopDefinition(
        id: 'mart',
        label: 'Boutique',
        states: <ShopStateDefinition>[
          ShopStateDefinition(
            id: 'story-finished',
            label: 'Histoire terminée',
            priority: 30,
            activation: ScriptConditionFactory.flagIsSet('story_finished'),
            storefrontLabel: 'Grand Comptoir des Brisants',
          ),
        ],
      ),
    );

    expect(result.status, PlayerServiceRuntimeStatus.cancelled);
  });

  test('loads and hands the project item catalog to the shop host', () async {
    final root = await Directory.systemTemp.createTemp('shop-item-catalog-');
    addTearDown(() => root.delete(recursive: true));
    final catalogFile = File('${root.path}/data/items.json');
    await catalogFile.parent.create(recursive: true);
    await catalogFile.writeAsString(
      jsonEncode(
        encodeProjectItemCatalog(
          const ProjectItemCatalog(
            schemaVersion: 1,
            entries: [
              ProjectItemDefinition(
                id: 'potion',
                displayName: 'Potion',
                pocketId: 'medicine',
              ),
            ],
          ),
        ),
      ),
    );
    const state = GameState(saveId: 'catalog-shop');
    final host = _Host(
      onShop: (request) async {
        expect(request.itemCatalog.definitionFor('potion'), isNotNull);
        return const PlayerServiceHostResult.cancelled();
      },
    );
    final controller = PlayerServiceRuntimeController(
      currentGameState: () => state,
      host: host,
      commitAndSave: (_) async {},
      setInputLocked: (_) {},
      loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(
        maxHpByPartyIndex: <int, int>{},
      ),
      projectRootDirectory: root.path,
      pokemonConfig: const ProjectPokemonConfig(
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        catalogFiles: {'items': 'data/items.json'},
      ),
    );

    final result = await controller.openShop(
      const ShopDefinition(
        id: 'mart',
        label: 'Boutique',
        entries: [ShopEntryDefinition(itemId: 'potion', price: 300)],
      ),
    );

    expect(result.status, PlayerServiceRuntimeStatus.cancelled);
  });

  test('resolves typed Fact defaults with the project-backed context',
      () async {
    const initial = GameState(saveId: 'typed-fact-shop');
    final conditionContext = ScriptEvaluationContext(
      narrativeFactResolver: NarrativeFactRuntimeResolver.fromFacts(
        <NarrativeFactDefinition>[
          NarrativeFactDefinition(
            id: 'fact_market_open',
            label: 'Marché ouvert',
            initialValue: const NarrativeValue.boolean(true),
          ),
        ],
      ),
    );
    final host = _Host(
      onShop: (request) async {
        expect(request.conditionContext, same(conditionContext));
        expect(request.resolvedState.stateId, 'market-open');
        return const PlayerServiceHostResult.cancelled();
      },
    );
    final controller = PlayerServiceRuntimeController(
      currentGameState: () => initial,
      conditionContext: conditionContext,
      host: host,
      commitAndSave: (_) async {},
      setInputLocked: (_) {},
      loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(
        maxHpByPartyIndex: <int, int>{},
      ),
    );

    final result = await controller.openShop(
      ShopDefinition(
        id: 'mart',
        label: 'Boutique',
        states: <ShopStateDefinition>[
          ShopStateDefinition(
            id: 'market-open',
            label: 'Marché ouvert',
            activation: ScriptConditionFactory.factEquals(
              'fact_market_open',
              const NarrativeValue.boolean(true),
            ),
          ),
        ],
      ),
    );

    expect(result.status, PlayerServiceRuntimeStatus.cancelled);
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

  test('access policy is evaluated before input is locked', () async {
    const state = GameState(saveId: 'services');
    final locks = <bool>[];
    var hostCalls = 0;
    final host = _Host(
      onShop: (_) async {
        hostCalls += 1;
        return const PlayerServiceHostResult.cancelled();
      },
    );
    final controller = PlayerServiceRuntimeController(
      currentGameState: () => state,
      host: host,
      commitAndSave: (_) async {},
      setInputLocked: locks.add,
      loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(
        maxHpByPartyIndex: <int, int>{},
      ),
      grantedCapabilities: const <String>{'service.shop.v1'},
    );

    final missingCapability = await controller.openShop(
      const ShopDefinition(id: 'mart', label: 'Boutique'),
      request: const OpenShopService(
        interactionId: 'npc.mart',
        shopId: 'mart',
        requiredCapabilities: <String>{'service.shop.premium.v1'},
      ),
    );
    final falseFact = await controller.openShop(
      const ShopDefinition(id: 'mart', label: 'Boutique'),
      request: OpenShopService(
        interactionId: 'npc.mart',
        shopId: 'mart',
        availabilityCondition: ScriptConditionFactory.flagIsSet('mart_is_open'),
      ),
    );

    expect(missingCapability.status, PlayerServiceRuntimeStatus.unavailable);
    expect(falseFact.status, PlayerServiceRuntimeStatus.unavailable);
    expect(hostCalls, 0);
    expect(locks, isEmpty);
    expect(controller.isActive, isFalse);
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
