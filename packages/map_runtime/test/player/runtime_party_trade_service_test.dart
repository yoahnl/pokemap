import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/player_service_runtime_controller.dart';
import 'package:map_runtime/src/player/runtime_world_service_models.dart';
import 'package:map_runtime/src/player/runtime_player_pause_data.dart';

void main() {
  late Directory directory;
  late GameState state;
  late PlayerServiceRuntimeController controller;
  late List<GameState> commits;
  late List<bool> locks;
  var saveFails = false;
  Completer<void>? saveStarted;
  Completer<void>? saveRelease;
  const config = ProjectPokemonConfig(
    ruleset: PokemonRulesetProfile.pokeMapBetaV1,
    speciesDir: 'native/species',
    evolutionsDir: 'native/evolutions',
  );
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('native-party-trade-');
    final native = jsonDecode(
      await File(
        '../avelune_converter_adapters/assets/native_psdk_trainer_bundle.json',
      ).readAsString(),
    ) as Map<String, dynamic>;
    for (final kind in ['species', 'evolutions']) {
      for (final row in (native[kind] as List).cast<Map>()) {
        final id = row[kind == 'species' ? 'id' : 'speciesId'];
        final file = File('${directory.path}/native/$kind/$id.json');
        await file.parent.create(recursive: true);
        await file.writeAsString(jsonEncode(row));
      }
    }
    state = const GameState(
      saveId: 'native-party-trade',
      party: PlayerParty(
        members: [
          PlayerPokemon(
            individualId: 'first',
            speciesId: 'machoke',
            natureId: 'hardy',
            abilityId: 'guts',
            level: 28,
            currentHp: 40,
            knownMoveIds: ['low_kick'],
            currentPpByMoveId: {'low_kick': 7},
          ),
          PlayerPokemon(
            individualId: 'partner',
            speciesId: 'onix',
            natureId: 'hardy',
            abilityId: 'sturdy',
            level: 25,
            currentHp: 30,
          ),
        ],
      ),
      progression: PlayerProgression(
        seenSpeciesIds: ['machoke', 'onix'],
        caughtSpeciesIds: ['machoke', 'onix'],
      ),
    );
    commits = [];
    locks = [];
    saveFails = false;
    saveStarted = null;
    saveRelease = null;
    controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => state,
      commitAndSave: (next) async {
        saveStarted?.complete();
        await saveRelease?.future;
        if (saveFails) throw StateError('storage unavailable');
        commits.add(next);
        state = next;
      },
      setInputLocked: locks.add,
      loadRecoveryCaps: (_) async => throw StateError('Trade is not healing.'),
      projectRootDirectory: directory.path,
      pokemonConfig: config,
      itemCatalog: ItemCatalogSnapshot.fromCatalog(
        const ProjectItemCatalog(
          schemaVersion: 1,
          entries: [
            ProjectItemDefinition(
              id: 'native-leaf',
              displayName: 'Native evolution stone',
              pocketId: 'items',
              tags: {'evolution'},
            ),
            ProjectItemDefinition(
              id: 'native-guard',
              displayName: 'Evolution Guard',
              pocketId: 'held-items',
              heldEffectId: 'prevent_evolution',
            ),
          ],
        ),
      ),
    );
  });
  tearDown(() async {
    await controller.dispose();
    await directory.delete(recursive: true);
  });
  test('item-use runtime consumes the same native prevention policy without losing either item', () async {
    await File('${directory.path}/native/evolutions/machoke.json')
        .writeAsString(
          jsonEncode({
            'speciesId': 'machoke',
            'evolutions': [
              {
                'targetSpeciesId': 'machamp',
                'method': 'use_item',
                'itemId': 'native-leaf',
              },
            ],
          }),
        );
    state = state.copyWith(
      bag: const Bag(entries: [BagEntry(itemId: 'native-leaf', quantity: 1)]),
      party: state.party.copyWith(
        members: [
          state.party.members.first.copyWith(heldItemId: 'native-guard'),
          state.party.members[1],
        ],
      ),
    );
    final original = state;
    final result = await controller.useBagItemOutsideBattle(
      const RuntimePlayerPauseCommand.useBagItem(
        itemTargetId: 'native-leaf',
        partyTargetId: 'pokemon.first',
      ),
    );
    expect(result.status, RuntimePlayerPauseCommandStatus.unavailable);
    expect(result.safeMessage, contains('objet tenu'));
    expect(state, same(original));
    expect(state.party.members.first.heldItemId, 'native-guard');
    expect(state.bag.entries.single.quantity, 1);
    expect(commits, isEmpty);
  });

  Future<PlayerServiceRuntimeResult> open() => controller.openPartyTrade(
    request: const OpenPartyTradeService(interactionId: 'center.guard.trade'),
  );
  Future<void> ready() async {
    if (controller.worldServiceSnapshot != null) return;
    await controller.worldServiceSnapshots
        .firstWhere((value) => value != null)
        .timeout(const Duration(seconds: 5));
  }

  RuntimePartyTradeServiceContent content() =>
      controller.worldServiceSnapshot!.content
          as RuntimePartyTradeServiceContent;
  Future<RuntimeWorldServiceCommandResult> command(
    RuntimeWorldServiceAction action, {
    String? targetId,
    int? revision,
  }) => controller.dispatchWorldService(
    RuntimeWorldServiceCommand(
      action: action,
      snapshotRevision: revision ?? controller.worldServiceSnapshot!.revision,
      targetId: targetId,
    ),
  );
  Future<void> choose({bool self = false}) async {
    await command(RuntimeWorldServiceAction.select, targetId: 'first');
    await command(
      RuntimeWorldServiceAction.select,
      targetId: self
          ? RuntimePartyTradeServiceContent.samePartnerTarget
          : RuntimePartyTradeServiceContent.otherPartnerTarget,
    );
    if (!self) {
      await command(RuntimeWorldServiceAction.select, targetId: 'partner');
    }
  }

  test('awaits real party choices and close; only the first evolves and saves once', () async {
    final original = state;
    final opening = open();
    await ready();
    expect(content().phase, RuntimePartyTradePhase.selectFirst);
    expect(content().members.map((member) => member.individualId), [
      'first',
      'partner',
    ]);
    var closed = false;
    opening.then((_) => closed = true);
    await choose();
    expect(content().phase, RuntimePartyTradePhase.review);
    expect(commits, isEmpty);
    await command(RuntimeWorldServiceAction.confirm);
    expect(content().phase, RuntimePartyTradePhase.completed);
    expect(closed, isFalse);
    expect(commits, hasLength(1));
    expect(state.party.members.map((pokemon) => pokemon.individualId), [
      'first',
      'partner',
    ]);
    expect(state.party.members.first.speciesId, 'machamp');
    expect(
      state.party.members.first.knownMoveIds,
      original.party.members.first.knownMoveIds,
    );
    expect(state.party.members[1], original.party.members[1]);
    expect(state.progression.caughtSpeciesIds, contains('machamp'));
    expect(state.bag, original.bag);
    expect(state.storyFlags, original.storyFlags);
    await command(RuntimeWorldServiceAction.close);
    expect((await opening).status, PlayerServiceRuntimeStatus.completed);
    expect(locks, [true, false]);
    expect(controller.worldServiceSnapshot, isNull);
    expect(GameState.fromJson(state.toJson()).party, state.party);
  });
  test(
    'cancel at every selection stage preserves party bag progression and save',
    () async {
      for (final steps in [0, 1, 2, 3]) {
        final original = state;
        final opening = open();
        await ready();
        if (steps > 0) {
          await command(RuntimeWorldServiceAction.select, targetId: 'first');
        }
        if (steps > 1) {
          await command(
            RuntimeWorldServiceAction.select,
            targetId: RuntimePartyTradeServiceContent.otherPartnerTarget,
          );
        }
        if (steps > 2) {
          await command(RuntimeWorldServiceAction.select, targetId: 'partner');
        }
        await command(RuntimeWorldServiceAction.cancel);
        expect((await opening).status, PlayerServiceRuntimeStatus.cancelled);
        expect(state, same(original));
        expect(commits, isEmpty);
        expect(controller.worldServiceSnapshot, isNull);
      }
      expect(locks, [true, false, true, false, true, false, true, false]);
    },
  );
  test('same partner branch trades the selected individual with itself without swapping', () async {
    final originalPartner = state.party.members[1];
    final opening = open();
    await ready();
    await choose(self: true);
    expect(content().firstIndividualId, 'first');
    expect(content().partnerIndividualId, 'first');
    await command(RuntimeWorldServiceAction.confirm);
    await command(RuntimeWorldServiceAction.close);
    expect((await opening).status, PlayerServiceRuntimeStatus.completed);
    expect(state.party.members.first.speciesId, 'machamp');
    expect(state.party.members[1], originalPartner);
    expect(commits, hasLength(1));
  });
  test('stale revisions and party changes cannot authorize a trade', () async {
    final opening = open();
    await ready();
    final oldRevision = controller.worldServiceSnapshot!.revision;
    await choose();
    expect(
      (await command(
        RuntimeWorldServiceAction.confirm,
        revision: oldRevision,
      )).status,
      RuntimeWorldServiceCommandStatus.stale,
    );
    state = state.copyWith(
      party: PlayerParty(members: state.party.members.reversed.toList()),
    );
    final changed = state;
    expect(
      (await command(RuntimeWorldServiceAction.confirm)).status,
      RuntimeWorldServiceCommandStatus.stale,
    );
    await command(RuntimeWorldServiceAction.close);
    expect((await opening).status, PlayerServiceRuntimeStatus.failed);
    expect(state, same(changed));
    expect(commits, isEmpty);
  });
  test(
    'the explicit native held capability prevents the real trade evolution',
    () async {
      state = state.copyWith(
        party: state.party.copyWith(
          members: [
            state.party.members.first.copyWith(heldItemId: 'native-guard'),
            state.party.members[1],
          ],
        ),
      );
      final original = state.party;
      final opening = open();
      await ready();
      await choose();
      await command(RuntimeWorldServiceAction.confirm);
      await command(RuntimeWorldServiceAction.close);
      expect((await opening).status, PlayerServiceRuntimeStatus.completed);
      expect(state.party, original);
      expect(commits, hasLength(1));
    },
  );
  test(
    'unknown native evolution data fails without mutation or a save',
    () async {
      final file = File('${directory.path}/native/evolutions/machoke.json');
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      ((json['evolutions'] as List).single as Map)['method'] = 'future_method';
      await file.writeAsString(jsonEncode(json));
      final original = state;
      final opening = open();
      await ready();
      await choose();
      expect(
        (await command(RuntimeWorldServiceAction.confirm)).status,
        RuntimeWorldServiceCommandStatus.failed,
      );
      await command(RuntimeWorldServiceAction.close);
      expect((await opening).status, PlayerServiceRuntimeStatus.failed);
      expect(state, same(original));
      expect(commits, isEmpty);
    },
  );
  test('a failed save never reports a completed trade', () async {
    saveFails = true;
    final original = state;
    final opening = open();
    await ready();
    await choose();
    expect(
      (await command(RuntimeWorldServiceAction.confirm)).status,
      RuntimeWorldServiceCommandStatus.failed,
    );
    await command(RuntimeWorldServiceAction.close);
    expect((await opening).status, PlayerServiceRuntimeStatus.failed);
    expect(state, same(original));
    expect(commits, isEmpty);
    expect(locks, [true, false]);
  });
  test('dispose before metadata resolves cancels without a commit', () async {
    final opening = open();
    await ready();
    await choose();
    final applying = command(RuntimeWorldServiceAction.confirm);
    await controller.dispose();
    await applying;
    expect((await opening).status, PlayerServiceRuntimeStatus.cancelled);
    expect(commits, isEmpty);
    expect(locks, [true, false]);
  });
  for (final fails in [false, true]) {
    test(
      'dispose waits for an already engaged save with failure=$fails',
      () async {
        saveStarted = Completer<void>();
        saveRelease = Completer<void>();
        saveFails = fails;
        final original = state;
        final opening = open();
        await ready();
        await choose();
        final applying = command(RuntimeWorldServiceAction.confirm);
        await saveStarted!.future.timeout(const Duration(seconds: 5));
        var disposed = false;
        var finished = false;
        opening.then((_) => finished = true);
        final disposal = controller.dispose().then((_) => disposed = true);
        await Future<void>.delayed(Duration.zero);
        expect(disposed, isFalse);
        expect(finished, isFalse);
        expect(locks, [true]);
        expect(state, same(original));
        expect(commits, isEmpty);
        saveRelease!.complete();
        await disposal;
        final applied = await applying;
        final result = await opening;
        expect(disposed, isTrue);
        expect(locks, [true, false]);
        expect(controller.worldServiceSnapshot, isNull);
        if (fails) {
          expect(applied.status, RuntimeWorldServiceCommandStatus.failed);
          expect(result.status, PlayerServiceRuntimeStatus.failed);
          expect(state, same(original));
          expect(commits, isEmpty);
        } else {
          expect(applied.status, RuntimeWorldServiceCommandStatus.accepted);
          expect(result.status, PlayerServiceRuntimeStatus.completed);
          expect(commits, hasLength(1));
          expect(state.party.members.first.speciesId, 'machamp');
          expect(state.party.members[1], original.party.members[1]);
        }
      },
    );
  }
  test(
    'duplicate individual identities fail before locking the world',
    () async {
      state = state.copyWith(
        party: state.party.copyWith(
          members: [
            state.party.members.first,
            state.party.members[1].copyWith(individualId: 'first'),
          ],
        ),
      );
      expect((await open()).status, PlayerServiceRuntimeStatus.unavailable);
      expect(locks, isEmpty);
      expect(commits, isEmpty);
    },
  );
}
