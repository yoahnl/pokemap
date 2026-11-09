import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/battle_command_menu_model.dart';

import 'file:///Users/karim/Project/Pokemon HeartGold/creation/jusqua-oeuf-mystere/revision-scenario-20261026/parcours_scenario_test.dart'
    show HeartGoldJourney;
import 'file:///Users/karim/Project/pokemonProject/packages/map_runtime/test/source_converted_gym_reward_journey_test.dart'
    show installConvertedQaHeadlessAudio;
import 'file:///Users/karim/Project/Pokemon HeartGold/creation/ecorcia-chapitre7-annexes/c7_05_runtime_test.dart'
    show NorthSaveRepository;

const work =
    '/Users/karim/Project/Pokemon HeartGold/creation/ecorcia-chapitre7-annexes';
const qa =
    '/Users/karim/Library/Caches/AveluneQA/ecorcia-chapitre7-annexes/c7-08';
const originalPath =
    '/Users/karim/Project/Pokemon HeartGold/creation/ecorcia-chapitre7/preuves/parcours-complet/final-porte-bois.save.json';
const laprasId = 'ch7-lokhlass-154-3';
const laprasScene = 'hgss-ch7-c708-lokhlass';
const vanessaFact = 'fact_hgss_vanessa_pic_venin_recu';
final live = Platform.environment['HGSS_C708_SOURCE'] == '1';
final project = live
    ? '/Users/karim/Project/Pokemon HeartGold/jeu'
    : '$qa/project';

class CalendarJourney {
  CalendarJourney(
    this.label, {
    required this.cave,
    required this.day,
    this.failWrites = false,
    this.projectOverride,
    this.contactId,
  });
  final String label;
  final bool cave;
  DateTime day;
  bool failWrites;
  final String? projectOverride;
  final String? contactId;
  var writes = 0;
  late HeartGoldJourney journey;
  late NorthSaveRepository repository;
  late SaveEnvelope original;
  late GameState initial;
  final captureCommandCounts = <String, int>{};

  SaveEnvelope envelope(GameState state) =>
      const GameStateSaveEnvelopeMapper().create(
        identity: journey.identity,
        profileId: original.profileId,
        slotId: original.slotId,
        saveId: state.saveId,
        createdAt: original.createdAt,
        updatedAt: original.updatedAt,
        status: SaveStatus.active,
        playTimeSeconds: original.playTimeSeconds,
        gameState: state,
      );

  Future<void> boot({
    GameState? saved,
    bool fullBag = false,
    bool capturePreparation = false,
  }) async {
    final root = projectOverride ?? project;
    original = const SaveEnvelopeCodec().decode(
      await File(originalPath).readAsString(),
    );
    final authentic = const GameStateSaveEnvelopeMapper().restore(original);
    final contactFixture = switch (contactId) {
      'auffray' => ('route-32', 'ch7-36-7', 'hgss-ch7-trainer-57'),
      'elisabeth' => ('route-32', 'ch7-36-4', 'hgss-ch7-trainer-27'),
      'olwen' => ('route-33', 'ch7-37-0', 'hgss-ch7-trainer-61'),
      _ => null,
    };
    var position = cave
        ? const GridPos(x: 19, y: 88)
        : const GridPos(x: 30, y: 122);
    var facing = cave ? EntityFacing.south : EntityFacing.east;
    final mapId =
        contactFixture?.$1 ?? (cave ? 'caves-jumelles-sous-sol2' : 'route-32');
    final catalog = await RuntimeProjectCatalog.open('$root/project.json');
    journey = HeartGoldJourney('hgss-joueur', 'chikorita', caseLabel: label)
      ..copy = Directory(root);
    try {
      final map = await catalog.loadMapData(mapId);
      if (contactFixture != null) {
        final entity = map.entities.singleWhere(
          (row) => row.id == contactFixture.$2,
        );
        final neighbors = [
          (entity.pos.x, entity.pos.y + 1, EntityFacing.north),
          (entity.pos.x + 1, entity.pos.y, EntityFacing.west),
          (entity.pos.x - 1, entity.pos.y, EntityFacing.east),
          (entity.pos.x, entity.pos.y - 1, EntityFacing.south),
        ];
        final candidate = neighbors.firstWhere(
          (point) => !map.spatialScene!.navigation.blockedAreas.any(
            (area) =>
                point.$1 + .5 >= area.x &&
                point.$1 + .5 < area.x + area.width &&
                point.$2 + .5 >= area.z &&
                point.$2 + .5 < area.z + area.depth,
          ),
        );
        position = GridPos(x: candidate.$1, y: candidate.$2);
        facing = candidate.$3;
      }
      journey.manifest = await catalog.manifestForMaps(
        [map],
        extraCharacterIds: const ['hgss-joueur', 'hgss-joueuse'],
      );
    } finally {
      catalog.dispose();
    }
    final surfData = jsonDecode(
      await File('$work/revisites/surf-fixture-recipe.json').readAsString(),
    ) as Map;
    var swimmer = PlayerPokemon.fromJson(
      Map<String, dynamic>.from(surfData['completeFixturePokemon'] as Map),
    );
    if (capturePreparation) {
      swimmer = swimmer.copyWith(
        level: 50,
        experience: 125000,
        currentHp: 150,
        knownMoveIds: ['surf', 'tackle', 'yawn', 'water_gun'],
        currentPpByMoveId: {
          'surf': 15,
          'tackle': 35,
          'yawn': 10,
          'water_gun': 25,
        },
      );
    }
    final supplies = <String, int>{'ultra-ball': 99, 'super-potion': 20};
    var state =
        saved ??
        authentic.copyWith(
          currentMapId: mapId,
          playerPosition: position,
          playerSpatialPosition: PlayerSpatialPosition(
            x: position.x + .5,
            z: position.y + .5,
          ),
          playerFacing: facing,
          playerMovementMode: cave ? MovementMode.surf : MovementMode.walk,
          storyFlags: authentic.storyFlags.copyWith(
            activeFlags: {
              ...authentic.storyFlags.activeFlags,
              if (contactFixture != null)
                'trainer_defeated:${contactFixture.$3}',
            },
          ),
          spatialWorldState: const SpatialWorldState.empty(),
          mapInstanceWorldState: const MapInstanceWorldState.empty(),
          party: authentic.party.copyWith(
            members: [swimmer, ...authentic.party.members],
          ),
          progression: authentic.progression.copyWith(
            unlockedFieldAbilities: [
              ...authentic.progression.unlockedFieldAbilities,
              FieldAbility.surf,
            ],
          ),
          bag: authentic.bag.copyWith(
            entries: [
              ...authentic.bag.entries.where(
                (row) => !supplies.containsKey(row.itemId),
              ),
              for (final entry in supplies.entries)
                BagEntry(itemId: entry.key, quantity: entry.value),
            ],
          ),
        );
    if (fullBag) {
      final items = decodeProjectItemCatalog(
        jsonDecode(
          await File('$root/data/pokemon/catalogs/items.json').readAsString(),
        ) as Map<String, dynamic>,
      );
      state = state.copyWith(
        bag: state.bag.copyWith(
          entries: [
            for (final item in items.entries)
              BagEntry(itemId: item.id, quantity: 99),
          ],
        ),
      );
    }
    initial = state;
    await Directory('$qa/states').create(recursive: true);
    repository = NorthSaveRepository(
      '$qa/states/${live ? 'source-' : 'qa-'}$label.save.json',
    );
    await journey.boot(
      save: envelope(state),
      civilNow: () => day,
      additionalCapabilities: AveluneRuntimeCompatibility.host().capabilities,
      commitCheckpoint: (request) async {
        if (failWrites) {
          throw const FileSystemException('Declared C708 write failure');
        }
        final candidate = gameStateFromStrictSaveJson(request.checkpoint.state);
        expect(await SaveGameUseCase(repository).execute(candidate), isTrue);
        writes++;
      },
    );
    if (capturePreparation) installCaptureCommands();
  }

  void installCaptureCommands() {
    final battle = journey.runtime.battle!;
    int? lastYawnTurn;
    journey.driveBattle = (pilot) async {
      pilot.game.update(1 / 60);
      pilot.observe();
      await Future<void>.delayed(const Duration(milliseconds: 1));
      if (battle.error case final error?) {
        throw StateError('Battle failed: $error');
      }
      final snapshot = battle.battlePresentationListenable.value;
      if (snapshot == null || !snapshot.interactionsEnabled) {
        if (battle.battleOverlay?.isTurnPresentationActive == true) {
          battle.handleInput(
            const RuntimeInputEvent.press(RuntimeInputControl.primary),
          );
          battle.handleInput(
            const RuntimeInputEvent.release(RuntimeInputControl.primary),
          );
        }
        return;
      }
      final state = battle.engineState;
      if (state == null) {
        return;
      }
      if (state.outcome != null &&
          snapshot.mode != BattleCommandOverlayMode.continueOnly) {
        return;
      }
      final asleep =
          state.battlerAt(psdkOpponentSlot).majorStatus ==
          PsdkBattleMajorStatus.sleep;
      final heal = snapshot.playerHud.currentHp * 2 < snapshot.playerHud.maxHp;
      final weaken = snapshot.enemyHud.currentHp == snapshot.enemyHud.maxHp;
      final needsYawn =
          !asleep &&
          (lastYawnTurn == null || state.turnNumber - lastYawnTurn! > 2);
      final wantsFight = !heal && (needsYawn || weaken);
      final enabled = snapshot.entries.where((entry) => entry.enabled);
      int? selected;
      switch (snapshot.mode) {
        case BattleCommandOverlayMode.root:
          selected = wantsFight
              ? BattleCommandRootAction.fight.index
              : BattleCommandRootAction.bag.index;
        case BattleCommandOverlayMode.fight:
          if (!wantsFight) {
            battle.dispatchBattlePresentationCommand(
              BattleBackCommand(
                snapshotRevision: snapshot.revision,
                expectedMode: snapshot.mode,
              ),
            );
            return;
          }
          final moveId = needsYawn ? 'yawn' : 'tackle';
          final choices = battle.displaySession!.decisionRequest.allowedChoices
              .whereType<PlayerBattleChoiceFight>()
              .toList();
          final candidate = enabled
              .where(
                (entry) =>
                    state
                        .battlerAt(psdkPlayerSlot)
                        .moves[choices[entry.index].moveIndex]
                        .id ==
                    moveId,
              )
              .firstOrNull;
          if (candidate == null) {
            throw StateError(
              jsonEncode({
                'captureMoveUnavailable': moveId,
                'commands': captureCommandCounts,
                'actor': state.battlerAt(psdkPlayerSlot).speciesId,
                'moves': [
                  for (final move in state.battlerAt(psdkPlayerSlot).moves)
                    {
                      'id': move.id,
                      'symbol': move.dbSymbol,
                      'pp': move.currentPp,
                    },
                ],
                'choices': [for (final choice in choices) choice.moveIndex],
                'enabled': [
                  for (final entry in enabled)
                    {'index': entry.index, 'label': entry.primaryLabel},
                ],
              }),
            );
          }
          selected = candidate.index;
        case BattleCommandOverlayMode.bag:
          if (wantsFight) {
            battle.dispatchBattlePresentationCommand(
              BattleBackCommand(
                snapshotRevision: snapshot.revision,
                expectedMode: snapshot.mode,
              ),
            );
            return;
          }
          selected = enabled
              .firstWhere(
                (entry) =>
                    entry.primaryLabel ==
                    (heal ? 'Super Potion' : 'Hyper Ball'),
              )
              .index;
        case BattleCommandOverlayMode.bagMedicineTarget:
          selected = enabled
              .firstWhere(
                (entry) =>
                    entry.primaryLabel == snapshot.playerHud.speciesLabel,
              )
              .index;
        case BattleCommandOverlayMode.continueOnly:
        case BattleCommandOverlayMode.pokemon:
        case BattleCommandOverlayMode.decision:
          selected = enabled.first.index;
        default:
          return;
      }
      final accepted = battle.dispatchBattlePresentationCommand(
        BattleSelectEntryCommand(
          snapshotRevision: snapshot.revision,
          expectedMode: snapshot.mode,
          entryIndex: selected,
        ),
      );
      if (!accepted) return;
      final command =
          '${snapshot.mode.name}:${snapshot.entries.singleWhere((entry) => entry.index == selected).primaryLabel}';
      captureCommandCounts.update(
        command,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      if (command == 'fight:Bâillement') lastYawnTurn = state.turnNumber;
      if (snapshot.mode == BattleCommandOverlayMode.bag && !heal) {
        pilot.captureBallCommands++;
      }
    };
  }

  bool visible(String id) => journey.runtime.session!
      .frames(0)
      .keys
      .any((key) => key.endsWith(':npc:$id'));

  Future<GameState> disk() async =>
      (await NorthSaveRepository(repository.path).load())!;
  Future<void> save() async {
    final checkpoint = (await journey.runtime.captureCheckpoint())!;
    expect(
      await SaveGameUseCase(repository)
          .execute(gameStateFromStrictSaveJson(checkpoint.state)),
      isTrue,
    );
  }

  Future<void> interact(String id) async {
    await journey.settle();
    expect(
      journey
          .runtime
          .overworldInteractionSnapshot
          ?.primaryAction
          ?.request
          .targetId,
      id,
    );
    journey.press(RuntimeInputControl.primary);
    await journey.settle();
  }

  Future<void> close() async {
    journey.driveBattle = null;
    await journey.disposeRuntime();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => installConvertedQaHeadlessAudio(completePlayback: true));
  test('C708 configuration contains both sourced actors and reusable event policies', () async {
    final catalog = await RuntimeProjectCatalog.open('$project/project.json');
    try {
      final cave = await catalog.loadMapData('caves-jumelles-sous-sol2');
      final route = await catalog.loadMapData('route-32');
      expect(cave.entities.map((row) => row.id), contains(laprasId));
      expect(
        route.entities.singleWhere((row) => row.id == 'ch7-36-14').pos,
        const GridPos(x: 31, y: 122),
      );
      final manifest = await catalog.manifestForMaps([cave, route]);
      final scene = manifest.scenes.singleWhere(
        (scene) => scene.id == laprasScene,
      );
      final battle =
          scene.graph.nodes.singleWhere((node) => node.id == 'battle').payload
              as SceneBattlePayload;
      expect(
        battle.periodicEncounter!.consumeOnOutcomes,
        PeriodicEncounterOutcome.values.toSet(),
      );
      expect(
        manifest.contactDevice!.contacts
            .map((row) => row.id)
            .where(
              (id) => ['auffray', 'elisabeth', 'olwen', 'fargas'].contains(id),
            )
            .toSet()
            .length,
        4,
      );
    } finally {
      catalog.dispose();
    }
  });
  test(
    'C708 actual civil Friday presence refreshes without a hidden save',
    () async {
      for (final cave in [true, false]) {
        final host = CalendarJourney(
          'calendar-$cave',
          cave: cave,
          day: DateTime(2026, 11, 12, 23, 59),
        );
        try {
          await host.boot();
          final id = cave ? laprasId : 'ch7-36-14';
          expect(host.visible(id), isFalse);
          host.day = DateTime(2026, 11, 13);
          await host.journey.settle();
          expect(host.visible(id), isTrue);
          host.day = DateTime(2026, 11, 14);
          await host.journey.settle();
          expect(host.visible(id), isFalse);
          expect(host.writes, 0);
        } finally {
          await host.close();
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
  test('C708 actual Lapras flee consumes Friday and returns next Friday after Continue', () async {
    final host = CalendarJourney(
      'lapras-flee',
      cave: true,
      day: DateTime(2026, 11, 13, 12),
    );
    try {
      await host.boot();
      expect(host.visible(laprasId), isTrue);
      await host.interact(laprasId);
      expect(
        (host.journey.wildBattles.last['requestId'] as String),
        contains('hgss-revisite-lokhlass-vendredi'),
      );
      expect(host.journey.wildBattles.last['outcome'], 'runaway');
      final saved = await host.disk();
      expect(
        saved.periodicRewardState,
        isNot(host.initial.periodicRewardState),
      );
      expect(host.visible(laprasId), isFalse);
      await host.close();
      await host.boot(saved: saved);
      expect(host.visible(laprasId), isFalse);
      host.day = DateTime(2026, 11, 20, 12);
      await host.journey.settle();
      expect(host.visible(laprasId), isTrue);
    } finally {
      await host.close();
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
  test(
    'C708 actual Vanessa gives one Pic Venin and persists the sibling count',
    () async {
      final host = CalendarJourney(
        'vanessa-gift',
        cave: false,
        day: DateTime(2026, 11, 13, 12),
      );
      try {
        await host.boot();
        final quantity = host.journey.itemQuantity('poison-barb');
        await host.interact('ch7-36-14');
        expect(host.journey.itemQuantity('poison-barb'), quantity + 1);
        await host.save();
        final saved = await host.disk();
        expect(
          saved.narrativeFactRuntimeState.valueFor(vanessaFact)!.boolValue,
          isTrue,
        );
        expect(
          saved.narrativeFactRuntimeState
              .valueFor('fact_hgss_fratrie_jours_rencontres')!
              .intValue,
          1,
        );
        await host.interact('ch7-36-14');
        expect(host.journey.itemQuantity('poison-barb'), quantity + 1);
        await host.close();
        await host.boot(saved: saved);
        await host.interact('ch7-36-14');
        expect(host.journey.itemQuantity('poison-barb'), quantity + 1);
      } finally {
        await host.close();
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
  test(
    'C708 actual Lapras capture is durable and cannot repeat after Continue',
    () async {
      final host = CalendarJourney(
        'lapras-capture',
        cave: true,
        day: DateTime(2026, 11, 13, 12),
      );
      try {
        await host.boot(capturePreparation: true);
        expect(host.initial.party.members.first.level, 50);
        expect(host.initial.party.members.first.currentHp, 150);
        host.journey.captureNextWild = true;
        final originalPartySize = host.initial.party.members.length;
        await host.interact(laprasId);
        expect(
          (host.journey.wildBattles.last['requestId'] as String),
          contains('hgss-revisite-lokhlass-vendredi'),
        );
        expect(host.journey.wildBattles.last['outcome'], 'captured');
        expect(host.journey.wildBattles.last['outcomeInjected'], isFalse);
        final saved = await host.disk();
        expect(saved.party.members.length, originalPartySize + 1);
        expect(saved.party.members.last.speciesId, 'lapras');
        expect(saved.party.members.last.level, 20);
        expect(
          saved.periodicRewardState,
          isNot(host.initial.periodicRewardState),
        );
        stderr.writeln(
          jsonEncode({'capturePreparationCommands': host.captureCommandCounts}),
        );
        expect(host.captureCommandCounts['fight:Bâillement'], greaterThan(0));
        expect(host.captureCommandCounts['fight:Charge'], greaterThan(0));
        expect(host.captureCommandCounts['bag:Hyper Ball'], greaterThan(0));
        await host.close();
        await host.boot(saved: saved);
        expect(host.visible(laprasId), isFalse);
        expect(
          host.journey.runtime.gameStateSnapshot.party.members.where(
            (member) => member.speciesId == 'lapras',
          ),
          hasLength(1),
        );
      } catch (error) {
        stderr.writeln(
          jsonEncode({
            'captureFailure': '$error',
            'battleError': '${host.journey.runtime.battle?.error}',
            'requestId':
                host.journey.runtime.battle?.context?.request.requestId,
            'captureCommands': host.journey.battlePilot?.captureBallCommands,
            'actualOutcome': host.journey.battlePilot?.outcome?.name,
          }),
        );
        rethrow;
      } finally {
        await host.close();
      }
    },
    timeout: const Timeout(Duration(minutes: 7)),
  );
  test(
    'C708 Vanessa refuses a full declared bag then grants once after equipping',
    () async {
      final host = CalendarJourney(
        'vanessa-full',
        cave: false,
        day: DateTime(2026, 11, 13, 12),
        projectOverride: '$qa/bag-capacity-project',
      );
      try {
        await host.boot(fullBag: true);
        expect(
          host
              .journey
              .manifest
              .bagCapacity
              .pockets['items']!
              .maxQuantityPerItem,
          99,
        );
        await host.interact('ch7-36-14');
        expect(host.journey.itemQuantity('poison-barb'), 99);
        expect(
          host.journey.runtime.gameStateSnapshot.narrativeFactRuntimeState
                  .valueFor(vanessaFact)
                  ?.boolValue ??
              false,
          isFalse,
        );
        expect(
          host.journey.runtime.gameStateSnapshot.narrativeFactRuntimeState
                  .valueFor('fact_hgss_fratrie_jours_rencontres')
                  ?.intValue ??
              0,
          0,
        );
        final menu = await host.journey.runtime.readCompanionMenuData();
        final target = menu
            .pauseDetails[RuntimePlayerPauseSection.party]!
            .entries
            .first
            .pokemonSummary!
            .targetId;
        await host.journey.runtime.pause();
        final response = await host.journey.runtime.dispatchPauseCommand(
          RuntimePlayerPauseCommand.equipHeldItem(
            itemTargetId: 'poison-barb',
            partyTargetId: target,
          ),
        );
        expect(response.status, RuntimePlayerPauseCommandStatus.accepted);
        await host.journey.runtime.resume();
        expect(host.journey.itemQuantity('poison-barb'), 98);
        await host.interact('ch7-36-14');
        expect(host.journey.itemQuantity('poison-barb'), 99);
        await host.save();
        final saved = await host.disk();
        expect(
          saved.narrativeFactRuntimeState.valueFor(vanessaFact)!.boolValue,
          isTrue,
        );
        expect(
          saved.narrativeFactRuntimeState
              .valueFor('fact_hgss_fratrie_jours_rencontres')!
              .intValue,
          1,
        );
      } finally {
        await host.close();
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
  for (final entry in [
    ('auffray', 'ch7-36-7'),
    ('elisabeth', 'ch7-36-4'),
    ('olwen', 'ch7-37-0'),
  ]) {
    test(
      'C708 real contact refusal registration repeat and outgoing ${entry.$1}',
      () async {
        final host = CalendarJourney(
          'contact-${entry.$1}',
          cave: false,
          day: DateTime(2026, 11, 13, 12),
          contactId: entry.$1,
        );
        try {
          await host.boot();
          final contact = host.journey.manifest.contactDevice!.contacts
              .singleWhere((contact) => contact.id == entry.$1);
          expect(
            host.initial.narrativeFactRuntimeState
                    .valueFor(contact.registeredFactId)
                    ?.boolValue ??
                false,
            isFalse,
          );
          host.journey.choiceOverride = 'Non';
          await host.interact(entry.$2);
          expect(
            host.journey.runtime.gameStateSnapshot.narrativeFactRuntimeState
                    .valueFor(contact.registeredFactId)
                    ?.boolValue ??
                false,
            isFalse,
          );
          host.journey.choiceOverride = 'Oui';
          await host.interact(entry.$2);
          expect(
            host.journey.runtime.gameStateSnapshot.narrativeFactRuntimeState
                .valueFor(contact.registeredFactId)!
                .boolValue,
            isTrue,
          );
          final beforeRepeat =
              host.journey.runtime.gameStateSnapshot.narrativeFactRuntimeState;
          await host.interact(entry.$2);
          expect(
            host.journey.runtime.gameStateSnapshot.narrativeFactRuntimeState,
            beforeRepeat,
          );
          await host.save();
          final saved = await host.disk();
          await host.close();
          await host.boot(saved: saved);
          await host.journey.runtime.pause();
          final response = await host.journey.runtime.dispatchPauseCommand(
            RuntimePlayerPauseCommand.callContact(contactId: entry.$1),
          );
          expect(response.status, RuntimePlayerPauseCommandStatus.accepted);
          await host.journey.runtime.resume();
          await host.journey.settle();
          expect(
            host.journey.runtime.gameStateSnapshot.narrativeFactRuntimeState,
            saved.narrativeFactRuntimeState,
          );
          expect(
            host.journey.manifest.contactDevice!.contacts.where(
              (contact) => contact.id == entry.$1,
            ),
            hasLength(1),
          );
        } finally {
          await host.close();
        }
      },
      timeout: const Timeout(Duration(minutes: 4)),
    );
  }
  test(
    'C708 actual Fargas outgoing preserves the authentic registration',
    () async {
      final host = CalendarJourney(
        'contacts',
        cave: false,
        day: DateTime(2026, 11, 13, 12),
      );
      try {
        await host.boot();
        final before = host.journey.runtime.gameStateSnapshot;
        final contacts = host.journey.manifest.contactDevice!.contacts;
        expect(
          contacts.map((contact) => contact.id).toSet().length,
          contacts.length,
        );
        for (final id in ['fargas']) {
          final contact = contacts.singleWhere((contact) => contact.id == id);
          expect(
            before.narrativeFactRuntimeState
                .valueFor(contact.registeredFactId)
                ?.boolValue,
            isTrue,
            reason:
                '$id must already be registered in the authentic chapter save',
          );
          await host.journey.runtime.pause();
          final response = await host.journey.runtime.dispatchPauseCommand(
            RuntimePlayerPauseCommand.callContact(contactId: id),
          );
          expect(response.status, RuntimePlayerPauseCommandStatus.accepted);
          await host.journey.runtime.resume();
          await host.journey.settle();
        }
        expect(
          host.journey.runtime.gameStateSnapshot.narrativeFactRuntimeState,
          before.narrativeFactRuntimeState,
        );
        expect(host.journey.runtime.gameStateSnapshot.bag, before.bag);
      } finally {
        await host.close();
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
