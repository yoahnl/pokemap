import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

const _startMapId = 'Selbrume';
const _spawnId = 'spawn';
const _saveId = 'p6_03_selbrume_first_narrative_interaction';
const _scenarioId = 'p6_03_first_interaction';
const _interactionEntityId = 'p6_03_intro_sign';
const _interactionFlagId = 'p6.selbrume.first_interaction.seen';
const _interactionStepId = 'p6.selbrume.first_interaction';
const _interactionMessage =
    'Bienvenue à Selbrume. Ceci est la première interaction narrative du golden slice.';

const _initialSpeciesId = 'pidgeotto';
const _initialAbilityId = 'keen_eye';
const _initialMoves = <String>['gust', 'tackle'];
const _captureItemId = 'poke-ball';
const _medicineItemId = 'potion';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'P6-03 triggers repo-local Selbrume first narrative interaction and persists its state',
    () async {
      final repoRoot = _findRepoRoot();
      final projectRoot = Directory(p.join(repoRoot.path, 'selbrume'));
      final projectFilePath = p.join(projectRoot.path, 'project.json');

      expect(await File(projectFilePath).exists(), isTrue);

      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _startMapId,
      );

      expect(bundle.projectRootDirectory, p.normalize(projectRoot.path));
      expect(bundle.map.id, _startMapId);
      expect(bundle.manifest.maps.first.id, 'route 1');
      expect(
        bundle.manifest.maps.map((entry) => entry.id),
        containsAll(<String>['route 1', _startMapId]),
      );

      final spawn = bundle.map.entities.singleWhere(
        (entity) => entity.id == _spawnId,
      );
      expect(spawn.kind, MapEntityKind.spawn);
      expect(spawn.pos, const GridPos(x: 17, y: 24));
      expect(spawn.spawn?.role, EntitySpawnRole.playerStart);
      expect(spawn.spawn?.facing, EntityFacing.south);

      final sign = bundle.map.entities.singleWhere(
        (entity) => entity.id == _interactionEntityId,
      );
      expect(sign.kind, MapEntityKind.sign);
      expect(sign.sign?.plainText, _interactionMessage);
      expect(sign.properties['contentStatus'], 'technical_golden_slice_v0');

      final scenario = bundle.manifest.scenarios.singleWhere(
        (candidate) => candidate.id == _scenarioId,
      );
      expect(scenario.scope, ScenarioScope.localEventFlow);
      expect(scenario.entryNodeId, 'start');
      expect(
        scenario.nodes.where((node) => node.type == ScenarioNodeType.start),
        hasLength(1),
      );
      final sourceNode = scenario.nodes.singleWhere(
        (node) => node.id == 'source',
      );
      expect(sourceNode.type, ScenarioNodeType.reference);
      expect(sourceNode.payload.actionKind, kScenarioSourceEntityInteract);
      expect(sourceNode.binding.mapId, _startMapId);
      expect(sourceNode.binding.entityId, _interactionEntityId);
      expect(
        scenario.nodes.map((node) => node.payload.actionKind),
        containsAll(<String>[
          kScenarioActionSetFlag,
          kScenarioActionCompleteStep,
          kScenarioActionShowMessage,
        ]),
      );

      var state = createNewGameStateFromMap(
        startMap: bundle.map,
        saveId: _saveId,
        playerName: 'P6 Tester',
        tileWidthPx: bundle.manifest.settings.tileWidth,
        tileHeightPx: bundle.manifest.settings.tileHeight,
      );
      state = _seedP6InitialState(state);

      expect(state.currentMapId, _startMapId);
      expect(state.playerPosition, const GridPos(x: 17, y: 24));
      expect(state.playerFacing, EntityFacing.south);
      expect(state.party.members.single.speciesId, _initialSpeciesId);
      expect(state.bag.entries.map((entry) => entry.itemId),
          contains(_captureItemId));
      expect(state.bag.entries.map((entry) => entry.itemId),
          contains(_medicineItemId));
      expect(state.storyFlags.activeFlags, isNot(contains(_interactionFlagId)));
      expect(
        state.progression.completedStepIds,
        isNot(contains(_interactionStepId)),
      );

      final messages = <String>[];
      const executor = ScenarioRuntimeExecutor();
      final result = executor.dispatch(
        scenarios: bundle.manifest.scenarios,
        sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: _startMapId,
          entityId: _interactionEntityId,
        ),
        context: ScenarioRuntimeExecutionContext(
          gameState: state,
          onGameStateUpdated: (next) => state = next,
          openDialogue: (dialogueId, {startNode, runtimeSourceId}) => false,
          runScript: (scriptId, {startNode, runtimeSourceId}) => false,
          showMessage: messages.add,
        ),
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.executedEffect);
      expect(result.effect.type, ScenarioRuntimeEffectType.message);
      expect(result.effect.message, _interactionMessage);
      expect(result.scenarioId, _scenarioId);
      expect(result.sourceNodeId, 'source');
      expect(result.stopNodeId, 'show_intro_message');
      expect(messages, <String>[_interactionMessage]);

      expect(state.storyFlags.activeFlags, contains(_interactionFlagId));
      expect(
        state.progression.completedStepIds,
        contains(_interactionStepId),
      );
      expect(state.party.members.single.speciesId, _initialSpeciesId);
      expect(state.bag.entries.map((entry) => entry.itemId),
          contains(_captureItemId));
      expect(state.bag.entries.map((entry) => entry.itemId),
          contains(_medicineItemId));

      final saveData = saveDataFromGameState(state);
      expect(saveData.progression.storyFlags, contains(_interactionFlagId));
      expect(
        saveData.progression.completedStepIds,
        contains(_interactionStepId),
      );

      final reloaded =
          normalizeLoadedGameState(gameStateFromSaveData(saveData));

      expect(reloaded.saveId, _saveId);
      expect(reloaded.currentMapId, _startMapId);
      expect(reloaded.playerPosition, const GridPos(x: 17, y: 24));
      expect(reloaded.playerFacing, EntityFacing.south);
      expect(reloaded.party.members.single.speciesId, _initialSpeciesId);
      expect(reloaded.party.members.single.knownMoveIds, _initialMoves);
      expect(reloaded.bag.entries.map((entry) => entry.itemId),
          contains(_captureItemId));
      expect(reloaded.bag.entries.map((entry) => entry.itemId),
          contains(_medicineItemId));
      expect(reloaded.storyFlags.activeFlags, contains(_interactionFlagId));
      expect(
        reloaded.progression.completedStepIds,
        contains(_interactionStepId),
      );
    },
  );
}

GameState _seedP6InitialState(GameState state) {
  const mutations = GameStateMutations();
  var next = mutations.givePokemon(
    state,
    pokemon: const PlayerPokemon(
      speciesId: _initialSpeciesId,
      natureId: 'hardy',
      abilityId: _initialAbilityId,
      level: 8,
      currentHp: 24,
      knownMoveIds: _initialMoves,
    ),
  );
  next = mutations.giveItem(next, _captureItemId, 5);
  next = mutations.giveItem(next, _medicineItemId, 2);
  return next;
}

Directory _findRepoRoot() {
  var current = Directory.current.absolute;

  while (true) {
    final candidate = File(
      p.join(current.path, 'selbrume', 'project.json'),
    );
    if (candidate.existsSync()) {
      return current;
    }

    final parent = current.parent.absolute;
    if (parent.path == current.path) {
      throw StateError('Could not find repo-local selbrume/project.json');
    }
    current = parent;
  }
}
