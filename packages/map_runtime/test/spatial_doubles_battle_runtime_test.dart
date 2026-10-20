import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/presentation/flame/runtime_input_event.dart';
import 'package:map_runtime/src/presentation/flutter/battle_command_overlay_snapshot.dart';
import 'package:map_runtime/src/spatial/spatial_battle_runtime.dart';
import 'package:map_runtime/src/spatial/spatial_battle_view.dart';
import 'package:path/path.dart' as p;

void main() {
  for (final useItem in [false, true]) {
    testWidgets(
      'spatial doubles preserves four slots and two choices, item=$useItem',
      (tester) async {
        final fixture = (await tester.runAsync(_fixture))!;
        var commits = 0;
        final runtime = SpatialBattleRuntime(
          readGameState: () => fixture.state,
          commitGameState: (_, _) {
            commits++;
            return true;
          },
        );
        addTearDown(runtime.dispose);
        final completion = runtime.start(
          bundle: fixture.bundle,
          request: _request,
        );
        await tester.pumpWidget(
          MaterialApp(home: SpatialBattleView(runtime: runtime)),
        );
        await _until(
          tester,
          runtime,
          () =>
              runtime.battlePresentationListenable.value?.interactionsEnabled ==
              true,
        );
        expect(runtime.context!.playerPartySlotIndicesByLineupIndex, [1, 2, 0]);
        final initial = runtime.battlePresentationListenable.value!;
        expect(
          initial.combatantHuds.map((hud) => hud.effectiveSlot).toSet(),
          hasLength(4),
        );
        expect(
          initial.actorSlot,
          const BattleSlotRef.active(BattleSideId.player),
        );
        final originalPp = runtime.engineState!
            .battlerAt(psdkPlayerSlot)
            .moves[0]
            .currentPp;
        if (useItem) {
          expect(_select(runtime, 1), isTrue);
          expect(_select(runtime, 0), isTrue);
          expect(_select(runtime, 0), isTrue);
        } else {
          _selectFightTargetOne(runtime);
        }
        await _until(
          tester,
          runtime,
          () =>
              runtime.battlePresentationListenable.value?.actorSlot ==
              const BattleSlotRef(side: BattleSideId.player, slotIndex: 1),
        );
        expect(runtime.engineState!.turnNumber, 0);
        expect(
          runtime.engineState!.battlerAt(psdkPlayerSlot).moves[0].currentPp,
          originalPp,
        );
        expect(
          runtime.dispatchBattlePresentationCommand(
            BattleSelectEntryCommand(
              snapshotRevision: initial.revision,
              expectedMode: initial.mode,
              entryIndex: 0,
            ),
          ),
          isFalse,
        );
        _selectFightTargetOne(runtime);
        await _until(
          tester,
          runtime,
          () =>
              runtime.engineState!.turnNumber == 1 &&
              runtime.battlePresentationListenable.value?.actorSlot ==
                  const BattleSlotRef.active(BattleSideId.player) &&
              runtime.battlePresentationListenable.value?.phase ==
                  BattlePresentationPhase.choosingCommand &&
              runtime.battlePresentationListenable.value?.interactionsEnabled ==
                  true,
        );
        expect(runtime.error, isNull);
        final rightFoe = runtime.engineState!.battlerAt(
          const PsdkBattleSlotRef(bank: 1, position: 1),
        );
        final leftFoe = runtime.engineState!.battlerAt(psdkOpponentSlot);
        expect(rightFoe.currentHp, lessThan(leftFoe.currentHp));
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump();
        if (useItem) {
          expect(
            runtime.engineState!.battlerAt(psdkPlayerSlot).moves[0].currentPp,
            originalPp,
          );
          expect(
            _select(runtime, 1),
            isTrue,
            reason:
                '${runtime.battlePresentationListenable.value!.mode} / ${runtime.battlePresentationListenable.value!.phase} / ${runtime.error}',
          );
          expect(runtime.battlePresentationListenable.value!.entries, isEmpty);
        }
        expect(commits, 0);
        expect(
          const BagOperations().quantityOf(fixture.state.bag, 'potion'),
          1,
        );
        runtime.cancel();
        expect(await completion, isFalse);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}

bool _select(SpatialBattleRuntime runtime, int index) {
  final snapshot = runtime.battlePresentationListenable.value!;
  return runtime.dispatchBattlePresentationCommand(
    BattleSelectEntryCommand(
      snapshotRevision: snapshot.revision,
      expectedMode: snapshot.mode,
      entryIndex: index,
    ),
  );
}

void _selectFightTargetOne(SpatialBattleRuntime runtime) {
  expect(_select(runtime, 0), isTrue);
  expect(_select(runtime, 0), isTrue);
  expect(
    runtime.battlePresentationListenable.value!.mode,
    BattleCommandOverlayMode.moveTarget,
  );
  expect(_select(runtime, 1), isTrue);
}

Future<void> _until(
  WidgetTester tester,
  SpatialBattleRuntime runtime,
  bool Function() ready,
) async {
  for (var index = 0; index < 2500 && !ready(); index++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1)),
    );
    if (runtime.battlePresentationListenable.value?.phase ==
        BattlePresentationPhase.presentingTurn) {
      runtime.handleInput(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      );
    }
    if (runtime.error != null) break;
  }
  expect(runtime.error, isNull);
  expect(ready(), isTrue);
}

const _request = TrainerBattleStartRequest(
  requestId: 'spatial-doubles',
  createdAtEpochMs: 1,
  returnContext: OverworldReturnContext(
    mapId: 'golden_field',
    playerPos: GridPos(x: 1, y: 1),
    playerFacing: Direction.east,
  ),
  trainerId: 'trainer_rookie',
  npcEntityId: 'rookie',
  mapId: 'golden_field',
  playerPos: GridPos(x: 1, y: 1),
);

Future<({RuntimeMapBundle bundle, GameState state})> _fixture() async {
  final root = p.normalize(
    p.join(
      Directory.current.path,
      '..',
      '..',
      'examples',
      'playable_runtime_host',
      'golden_battle_slice',
    ),
  );
  final bundle = await loadRuntimeMapBundle(
    projectFilePath: p.join(root, 'project.json'),
    mapId: 'golden_field',
  );
  final temporary = await Directory.systemTemp.createTemp(
    'avelune-spatial-doubles-',
  );
  addTearDown(() => temporary.delete(recursive: true));
  for (final file in Directory(
    root,
  ).listSync(recursive: true).whereType<File>()) {
    final target = File(
      p.join(temporary.path, p.relative(file.path, from: root)),
    );
    await target.parent.create(recursive: true);
    await file.copy(target.path);
  }
  const items = ProjectItemCatalog(
    schemaVersion: 1,
    entries: [
      ProjectItemDefinition(
        id: 'potion',
        displayName: 'Potion',
        pocketId: 'medicine',
        uses: [
          ProjectItemUseDefinition(
            contexts: {ProjectItemUseContext.battle},
            target: ProjectItemTargetKind.partyMember,
            consumption: ProjectItemConsumptionPolicy.onApplied,
            effect: ProjectItemEffectDefinition.healHp(
              mode: ProjectItemAmountMode.flat,
              amount: 20,
            ),
          ),
        ],
      ),
    ],
  );
  await File(p.join(temporary.path, 'items.json'))
      .writeAsString(jsonEncode(items.toJson()));
  final evolutions = Directory(
    p.join(temporary.path, bundle.manifest.pokemon.evolutionsDir),
  );
  await evolutions.create(recursive: true);
  for (final species in ['sproutle', 'sparkitten']) {
    await File(p.join(evolutions.path, '$species.json')).writeAsString(
      jsonEncode({'schemaVersion': 1, 'speciesId': species, 'evolutions': []}),
    );
  }
  final trainer = bundle.manifest.trainers.single;
  final portable = bundle.copyWith(
    projectRootDirectory: temporary.path,
    map: MapData(
      version: ProjectVersion.v9,
      id: bundle.map.id,
      name: bundle.map.name,
      size: bundle.map.size,
      spatialScene: MapSpatialScene(
        width: bundle.map.size.width,
        depth: bundle.map.size.height,
      ),
    ),
    manifest: bundle.manifest.copyWith(
      version: ProjectVersion.v9,
      settings: bundle.manifest.settings.copyWith(
        dimension: ProjectDimension.threeD,
      ),
      trainers: [
        trainer.copyWith(
          battleFormat: BattleFormat.doubles,
          team: [trainer.team.single, trainer.team.single],
        ),
      ],
      pokemon: bundle.manifest.pokemon.copyWith(
        ruleset: PokemonRulesetProfile.standardV1,
        catalogFiles: {
          ...bundle.manifest.pokemon.catalogFiles,
          'items': 'items.json',
        },
      ),
    ),
  );
  final save = SaveData.fromJson(
    jsonDecode(
      await File(p.join(root, 'runtime_host_launch_save.json')).readAsString(),
    ) as Map<String, dynamic>,
  );
  final original = gameStateFromSaveData(save);
  final members = original.party.members;
  final state = original.copyWith(
    bag: const Bag(entries: [BagEntry(itemId: 'potion', quantity: 1)]),
    party: PlayerParty(
      members: [
        members[0].copyWith(individualId: 'ko', currentHp: 0),
        for (var index = 0; index < members.length; index++)
          members[index].copyWith(
            individualId: 'living-$index',
            currentHp: members[index].currentHp - 4,
          ),
      ],
    ),
    playerSpatialPosition: PlayerSpatialPosition(x: 1.25, z: 1.5),
  );
  return (bundle: portable, state: state);
}
