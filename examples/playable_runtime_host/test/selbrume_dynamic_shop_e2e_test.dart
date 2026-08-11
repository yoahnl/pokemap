import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/in_game_shop_page.dart';

import 'support/selbrume_player_service_test_host.dart';

final _itemCatalog = ItemCatalogSnapshot.fromCatalog(mvpItemCatalog);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProjectManifest project;
  late ShopDefinition shop;
  late ScriptEvaluationContext conditionContext;

  setUpAll(() {
    project = _loadSelbrumeProject();
    shop = project.shops.singleWhere(
      (candidate) => candidate.id == 'shop_port_supplies',
    );
    conditionContext = ScriptEvaluationContext(
      narrativeFactResolver: NarrativeFactRuntimeResolver.fromFacts(
        project.facts,
      ),
    );
  });

  test('default profile buys the real authored Poké Ball', () async {
    final initial = _state(money: 1000);
    final host = SelbrumePlayerServiceTestHost()
      ..queueShopPurchase('poke-ball');
    final harness = _ShopRuntimeHarness(
      initialState: initial,
      host: host,
      conditionContext: conditionContext,
    );

    final result = await harness.controller.openShop(shop);

    expect(result.status, PlayerServiceRuntimeStatus.completed);
    expect(harness.commits, 1);
    expect(harness.inputLocks, <bool>[true, false]);
    expect(harness.state.trainerProfile.money, 800);
    expect(_bagQuantity(harness.state, 'poke-ball'), 1);
    expect(
      harness.state.progression
          .shopPurchaseCounts['shop_port_supplies::poke-ball'],
      1,
    );
    _expectResolvedProfile(
      host.shopRequests.single.resolvedState,
      stateId: ShopStateResolver.defaultStateId,
      entries: const <String, int>{
        'potion': 300,
        'poke-ball': 200,
      },
    );
  });

  test('after-Lysa stock and price survive a production file reload', () async {
    final directory = await Directory.systemTemp.createTemp(
      'selbrume_dynamic_shop_e2e_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final repository = _TestFileGameSaveRepository(directory);
    final firstHost = SelbrumePlayerServiceTestHost()
      ..queueShopPurchase('potion');
    final firstHarness = _ShopRuntimeHarness(
      initialState: _state(
        money: 1000,
        facts: const <String, bool>{
          'fact_rival_port_defeated': true,
        },
      ),
      host: firstHost,
      conditionContext: conditionContext,
      repository: repository,
    );

    final firstResult = await firstHarness.controller.openShop(shop);
    final firstReload = await repository.load();

    expect(firstResult.status, PlayerServiceRuntimeStatus.completed);
    expect(firstReload, isNotNull);
    expect(firstReload!.trainerProfile.money, 750);
    expect(_bagQuantity(firstReload, 'potion'), 1);
    expect(
      firstReload.progression
          .shopPurchaseCounts['shop_port_supplies::after-lysa::potion'],
      1,
    );
    _expectResolvedProfile(
      firstHost.shopRequests.single.resolvedState,
      stateId: 'after-lysa',
      entries: const <String, int>{
        'potion': 250,
        'poke-ball': 200,
        'antidote': 100,
      },
    );

    final secondHost = SelbrumePlayerServiceTestHost()
      ..queueShopPurchase('potion');
    final secondHarness = _ShopRuntimeHarness(
      initialState: firstReload,
      host: secondHost,
      conditionContext: conditionContext,
      repository: repository,
    );

    final secondResult = await secondHarness.controller.openShop(shop);
    final secondReload = await repository.load();

    expect(secondResult.status, PlayerServiceRuntimeStatus.completed);
    expect(secondReload, isNotNull);
    expect(secondReload!.trainerProfile.money, 500);
    expect(_bagQuantity(secondReload, 'potion'), 2);
    expect(
      secondReload.progression
          .shopPurchaseCounts['shop_port_supplies::after-lysa::potion'],
      2,
    );
    expect(
      secondHost.shopRequests.single.resolvedState.stateId,
      'after-lysa',
    );
  });

  test('lighthouse alert overrides after-Lysa and cannot commit a purchase',
      () async {
    final initial = _state(
      money: 1000,
      facts: const <String, bool>{
        'fact_rival_port_defeated': true,
        'fact_lighthouse_reached': true,
      },
    );
    final host = SelbrumePlayerServiceTestHost()..queueShopPurchase('potion');
    final harness = _ShopRuntimeHarness(
      initialState: initial,
      host: host,
      conditionContext: conditionContext,
    );

    final result = await harness.controller.openShop(shop);
    final resolved = host.shopRequests.single.resolvedState;

    expect(result.status, PlayerServiceRuntimeStatus.failed);
    expect(result.error, isA<StateError>());
    expect(result.error.toString(), contains('shopClosed'));
    expect(harness.commits, 0);
    expect(harness.state, same(initial));
    expect(harness.inputLocks, <bool>[true, false]);
    expect(resolved.stateId, 'lighthouse-alert');
    expect(resolved.matchedStateIds, <String>[
      'lighthouse-alert',
      'after-lysa',
    ]);
    expect(resolved.isOpen, isFalse);
    expect(resolved.entries, isEmpty);
    expect(
      resolved.message,
      'Le comptoir reste fermé pendant l’alerte du phare.',
    );
    expect(host.purchasedItemIds, isEmpty);
  });

  test('finished story wins and buys from the final catalogue', () async {
    final host = SelbrumePlayerServiceTestHost()
      ..queueShopPurchase('poke-ball');
    final harness = _ShopRuntimeHarness(
      initialState: _state(
        money: 1000,
        facts: const <String, bool>{
          'fact_rival_port_defeated': true,
          'fact_lighthouse_reached': true,
          'fact_main_story_completed': true,
        },
      ),
      host: host,
      conditionContext: conditionContext,
    );

    final result = await harness.controller.openShop(shop);
    final resolved = host.shopRequests.single.resolvedState;

    expect(result.status, PlayerServiceRuntimeStatus.completed);
    expect(harness.state.trainerProfile.money, 850);
    expect(_bagQuantity(harness.state, 'poke-ball'), 1);
    expect(
      harness.state.progression
          .shopPurchaseCounts['shop_port_supplies::story-finished::poke-ball'],
      1,
    );
    expect(resolved.matchedStateIds, <String>[
      'story-finished',
      'after-lysa',
    ]);
    _expectResolvedProfile(
      resolved,
      stateId: 'story-finished',
      entries: const <String, int>{
        'potion': 200,
        'super-potion': 700,
        'poke-ball': 150,
      },
    );
  });

  testWidgets('real Selbrume UI refreshes a stale after-Lysa catalogue',
      (tester) async {
    var latest = _state(
      money: 1000,
      facts: const <String, bool>{
        'fact_rival_port_defeated': true,
      },
    );
    var commits = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: InGameShopPage(
          gameState: latest,
          itemCatalog: _itemCatalog,
          currentGameState: () => latest,
          shops: <ShopDefinition>[shop],
          conditionContext: conditionContext,
          onStateCommitted: (_) async => commits += 1,
        ),
      ),
    );

    expect(
      find.text(
        'Lysa a rouvert les routes : le comptoir est mieux approvisionné.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('250'), findsOneWidget);
    expect(find.text('Antidote'), findsOneWidget);

    latest = _state(
      money: 1000,
      facts: const <String, bool>{
        'fact_rival_port_defeated': true,
        'fact_main_story_completed': true,
      },
    );
    await tester.tap(find.byKey(const Key('shop-buy-potion')));
    await tester.pumpAndSettle();

    expect(commits, 0);
    expect(latest.trainerProfile.money, 1000);
    expect(find.text('Comptoir de Selbrume'), findsOneWidget);
    expect(find.text('Super Potion'), findsOneWidget);
    expect(find.textContaining('catalogue a été actualisé'), findsOneWidget);
  });
}

final class _ShopRuntimeHarness {
  _ShopRuntimeHarness({
    required GameState initialState,
    required this.host,
    required ScriptEvaluationContext conditionContext,
    this.repository,
  }) : state = initialState {
    controller = PlayerServiceRuntimeController(
      currentGameState: () => state,
      host: host,
      commitAndSave: (nextState) async {
        commits += 1;
        state = nextState;
        final saveRepository = repository;
        if (saveRepository != null) {
          await saveRepository.save(nextState);
        }
      },
      setInputLocked: inputLocks.add,
      loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(
        maxHpByPartyIndex: <int, int>{},
      ),
      conditionContext: conditionContext,
      itemCatalog: _itemCatalog,
    );
  }

  final SelbrumePlayerServiceTestHost host;
  final FileGameSaveRepository? repository;
  final List<bool> inputLocks = <bool>[];
  late final PlayerServiceRuntimeController controller;
  GameState state;
  int commits = 0;
}

final class _TestFileGameSaveRepository extends FileGameSaveRepository {
  _TestFileGameSaveRepository(this.directory);

  final Directory directory;

  @override
  Future<String> getSaveFilePath() async =>
      p.join(directory.path, 'game_save.json');
}

ProjectManifest _loadSelbrumeProject() {
  final root = _findRepositoryRoot();
  final projectFile = File(p.join(root.path, 'selbrume', 'project.json'));
  return ProjectManifest.fromJson(
    (jsonDecode(projectFile.readAsStringSync()) as Map).cast<String, dynamic>(),
  );
}

Directory _findRepositoryRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(p.join(current.path, 'AGENTS.md')).existsSync() &&
        File(p.join(current.path, 'selbrume', 'project.json')).existsSync()) {
      return current;
    }
    if (current.parent.path == current.path) {
      throw StateError('pokemonProject repository root not found.');
    }
    current = current.parent;
  }
}

GameState _state({
  required int money,
  Map<String, bool> facts = const <String, bool>{},
}) =>
    GameState(
      saveId: 'selbrume-dynamic-shop-e2e',
      trainerProfile: TrainerProfile(name: 'Leaf', money: money),
      narrativeFactRuntimeState: NarrativeFactRuntimeState(
        overridesByFactId: facts,
      ),
    );

int _bagQuantity(GameState state, String itemId) => state.bag.entries
    .where((entry) => entry.itemId == itemId)
    .fold(0, (total, entry) => total + entry.quantity);

void _expectResolvedProfile(
  ResolvedShopState resolved, {
  required String stateId,
  required Map<String, int> entries,
}) {
  expect(resolved.stateId, stateId);
  expect(resolved.isOpen, isTrue);
  expect(
    <String, int>{
      for (final entry in resolved.entries) entry.itemId: entry.price,
    },
    entries,
  );
}
