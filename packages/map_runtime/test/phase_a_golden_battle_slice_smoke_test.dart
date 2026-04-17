import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/encounter_to_battle_request.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_mapper.dart';
import 'package:map_runtime/src/application/trainer_battle_request.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase A golden battle-ready slice smoke', () {
    const mapper = RuntimeBattleSetupMapper();

    test('the versioned golden slice starts a real wild battle', () async {
      final projectFilePath = _goldenProjectFilePath();
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'golden_field',
      );
      final save = await _loadGoldenSave(projectFilePath);
      final gameState = gameStateFromSaveData(save);

      final world = GameplayWorldState.initial(
        map: bundle.map,
        playerPos: gameState.playerPosition,
        playerFacing: Direction.east,
        project: bundle.manifest,
      );
      final movedWorld = stepGameplayWorld(
        world,
        const MoveIntent(Direction.north),
      ).world;
      final encounter = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: bundle.manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      ).encounter;

      expect(encounter, isNotNull);
      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter!,
        world: movedWorld,
        createdAtEpochMs: 1,
      );

      final setup = await mapper.map(
        bundle: bundle,
        gameState: gameState,
        request: request,
      );
      final session = createBattleSession(setup);

      expect(session.state.isFinished, isFalse);
      expect(session.state.player.speciesId, equals('sproutle'));
      expect(session.state.enemy.speciesId, equals('sparkitten'));
    });

    test('the versioned golden slice starts a real trainer battle', () async {
      final projectFilePath = _goldenProjectFilePath();
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'golden_field',
      );
      final save = await _loadGoldenSave(projectFilePath);
      final gameState = gameStateFromSaveData(save);

      final world = GameplayWorldState.initial(
        map: bundle.map,
        playerPos: gameState.playerPosition,
        playerFacing: Direction.east,
        project: bundle.manifest,
      );
      final trainer = bundle.map.entities.firstWhere(
        (entity) => entity.id == 'npc_trainer_rookie',
      );
      final request = buildTrainerBattleRequestFromNpc(
        entity: trainer,
        manifest: bundle.manifest,
        world: world,
        createdAtEpochMs: 1,
      );

      expect(request, isNotNull);

      final setup = await mapper.map(
        bundle: bundle,
        gameState: gameState,
        request: request!,
      );
      expect(setup.isTrainerBattle, isTrue);
      final session = createBattleSession(setup);

      expect(session.state.isFinished, isFalse);
      expect(session.state.player.speciesId, equals('sproutle'));
      expect(session.state.enemy.speciesId, equals('sparkitten'));
    });
  });
}

String _goldenProjectFilePath() {
  // Le smoke doit consommer le vrai slice versionné du repo, pas une fixture
  // temporaire en /tmp. On résout donc explicitement le chemin vers l'example
  // host battleready pour que le test protège cette vérité produit.
  return p.normalize(
    p.join(
      Directory.current.path,
      '..',
      '..',
      'examples',
      'playable_runtime_host',
      'golden_battle_slice',
      'project.json',
    ),
  );
}

Future<SaveData> _loadGoldenSave(String projectFilePath) async {
  final saveFile = File(
    p.join(
      File(projectFilePath).parent.path,
      'runtime_host_launch_save.json',
    ),
  );
  final decoded = jsonDecode(await saveFile.readAsString());
  return SaveData.fromJson(decoded as Map<String, dynamic>).normalized();
}

class _FixedEncounterRandom implements Random {
  _FixedEncounterRandom({
    required this.nextDoubleValues,
    required this.nextIntValues,
  });

  final List<double> nextDoubleValues;
  final List<int> nextIntValues;
  var _doubleIndex = 0;
  var _intIndex = 0;

  @override
  bool nextBool() => nextInt(2) == 0;

  @override
  double nextDouble() {
    final value = nextDoubleValues[_doubleIndex % nextDoubleValues.length];
    _doubleIndex++;
    return value;
  }

  @override
  int nextInt(int max) {
    final value = nextIntValues[_intIndex % nextIntValues.length];
    _intIndex++;
    return max == 0 ? 0 : value % max;
  }
}
