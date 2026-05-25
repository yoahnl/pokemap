import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/global_story_chapter_runtime.dart';
import 'package:map_runtime/src/application/map_entity_runtime_predicate_evaluator.dart';
import 'package:map_runtime/src/application/step_studio_world_presence_runtime.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P3 save/load narrative state roundtrip', () {
    test('persists narrative truths and projections after reload', () async {
      final bundle = await _loadBundle();
      final initialState = _narrativeState(
        saveId: 'p3-save-load-positive',
        flags: {
          _flagVisible,
          _scenarioOutcomeFlag,
          _battleVictoryFlag,
          _battleDefeatFlag,
        },
        completedSteps: const [
          _stepVisible,
          _chapterStepA,
          _chapterStepB,
          _worldPresenceStep,
        ],
        completedCutscenes: const [_cutsceneVisible],
        consumedEvents: const {_consumedEvent},
      );

      final loadedState = await _saveAndLoad(initialState);

      expect(loadedState.saveId, 'p3-save-load-positive');
      expect(loadedState.currentMapId, _mapId);
      expect(loadedState.playerPosition, const GridPos(x: 4, y: 5));
      expect(loadedState.playerFacing, EntityFacing.east);
      expect(
        loadedState.storyFlags.activeFlags,
        containsAll(<String>[
          _flagVisible,
          _scenarioOutcomeFlag,
          _battleVictoryFlag,
          _battleDefeatFlag,
        ]),
      );
      expect(
        loadedState.progression.completedStepIds,
        containsAll(<String>[
          _stepVisible,
          _chapterStepA,
          _chapterStepB,
          _worldPresenceStep,
        ]),
      );
      expect(
        loadedState.progression.completedCutsceneIds,
        contains(_cutsceneVisible),
      );
      expect(loadedState.consumedEventIds, contains(_consumedEvent));

      final beforeProjection = loadedState.toJson();
      expect(_isVisible(bundle, 'p3_flag_visible_npc', loadedState), isTrue);
      expect(_isVisible(bundle, 'p3_step_visible_npc', loadedState), isTrue);
      expect(
          _isVisible(bundle, 'p3_cutscene_visible_npc', loadedState), isTrue);
      expect(_isVisible(bundle, 'p3_outcome_visible_npc', loadedState), isTrue);
      expect(_isVisible(bundle, 'p3_battle_visible_npc', loadedState), isTrue);
      expect(_isVisible(bundle, 'p3_chapter_visible_npc', loadedState), isTrue);
      expect(_isWorldPresenceVisible(bundle, loadedState), isTrue);
      expect(
          _resolveConditionalDialogue(bundle, loadedState), 'p3.flag.dialogue');
      expect(loadedState.toJson(), beforeProjection);
    });

    test('keeps projections false or fallback after a negative reload',
        () async {
      final bundle = await _loadBundle();
      final negativeState = _narrativeState(
        saveId: 'p3-save-load-negative',
        flags: const {
          'p3.fact.flag.wrong',
          'scenario.outcome.p3.outcome.wrong',
          _battleDefeatFlag,
        },
        completedSteps: const [
          'p3.step.wrong',
          _chapterStepA,
          'p3.world_presence.wrong',
        ],
        completedCutscenes: const ['p3.cutscene.wrong'],
      );

      final loadedState = await _saveAndLoad(negativeState);

      expect(loadedState.storyFlags.activeFlags,
          containsAll(<String>['p3.fact.flag.wrong', _battleDefeatFlag]));
      expect(loadedState.storyFlags.activeFlags, isNot(contains(_flagVisible)));
      expect(
        loadedState.storyFlags.activeFlags,
        isNot(contains(_scenarioOutcomeFlag)),
      );
      expect(
        loadedState.storyFlags.activeFlags,
        isNot(contains(_battleVictoryFlag)),
      );
      expect(loadedState.progression.completedStepIds, contains(_chapterStepA));
      expect(
        loadedState.progression.completedStepIds,
        isNot(contains(_chapterStepB)),
      );

      final beforeProjection = loadedState.toJson();
      expect(_isVisible(bundle, 'p3_flag_visible_npc', loadedState), isFalse);
      expect(_isVisible(bundle, 'p3_step_visible_npc', loadedState), isFalse);
      expect(
        _isVisible(bundle, 'p3_cutscene_visible_npc', loadedState),
        isFalse,
      );
      expect(
          _isVisible(bundle, 'p3_outcome_visible_npc', loadedState), isFalse);
      expect(_isVisible(bundle, 'p3_battle_visible_npc', loadedState), isFalse);
      expect(
          _isVisible(bundle, 'p3_chapter_visible_npc', loadedState), isFalse);
      expect(_isWorldPresenceVisible(bundle, loadedState), isFalse);
      expect(_resolveConditionalDialogue(bundle, loadedState),
          'p3.default.dialogue');
      expect(loadedState.toJson(), beforeProjection);
    });
  });
}

const _mapId = 'p3_fact_world_rule_map';
const _flagVisible = 'p3.fact.flag.visible';
const _stepVisible = 'p3.step.visible';
const _cutsceneVisible = 'p3.cutscene.visible';
const _scenarioOutcomeFlag = 'scenario.outcome.p3.outcome.visible';
const _battleVictoryFlag = 'battle:p3_battle_projection:victory';
const _battleDefeatFlag = 'battle:p3_battle_projection:defeat';
const _chapterStepA = 'p3.chapter.step.a';
const _chapterStepB = 'p3.chapter.step.b';
const _worldPresenceStep = 'p3.world_presence.step.visible';
const _consumedEvent = 'p3.event.consumed';

Future<RuntimeMapBundle> _loadBundle() {
  final projectFilePath = p.join(
    Directory.current.path,
    'test',
    'fixtures',
    'p3_fact_world_rule_projection',
    'project.json',
  );

  return loadRuntimeMapBundle(
    projectFilePath: projectFilePath,
    mapId: _mapId,
  );
}

GameState _narrativeState({
  required String saveId,
  required Set<String> flags,
  required List<String> completedSteps,
  List<String> completedCutscenes = const [],
  Set<String> consumedEvents = const {},
}) {
  return GameState(
    saveId: saveId,
    currentMapId: _mapId,
    playerPosition: const GridPos(x: 4, y: 5),
    playerFacing: EntityFacing.east,
    storyFlags: StoryFlags(activeFlags: flags),
    progression: PlayerProgression(
      completedStepIds: completedSteps,
      completedCutsceneIds: completedCutscenes,
    ),
    consumedEventIds: consumedEvents,
  );
}

Future<GameState> _saveAndLoad(GameState state) async {
  final tempDirectory =
      await Directory.systemTemp.createTemp('p3_save_load_narrative_');
  addTearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  final repository = _TestFileGameSaveRepository(tempDirectory);
  final saved = await SaveGameUseCase(repository).execute(state);
  expect(saved, isTrue);
  expect(await repository.exists(), isTrue);
  expect(await File(await repository.exposedSaveFilePath()).exists(), isTrue);

  final loadedState = await LoadGameUseCase(repository).execute();
  expect(loadedState, isNotNull);
  return loadedState!;
}

bool _isVisible(
  RuntimeMapBundle bundle,
  String entityId,
  GameState state,
) {
  final evaluator = MapEntityRuntimePredicateEvaluator(
    gameState: state,
    chapterIndex: buildGlobalStoryChapterStepIndex(bundle.manifest.scenarios),
  );
  return evaluator.isNpcPresentOnMap(_npc(bundle, entityId));
}

bool _isWorldPresenceVisible(RuntimeMapBundle bundle, GameState state) {
  final rules = buildStepStudioWorldPresenceRuleList(bundle.manifest.scenarios);
  return isNpcRuntimePresentOnMap(
    gameState: state,
    manifest: bundle.manifest,
    stepStudioWorldRules: rules,
    mapId: _mapId,
    entity: _npc(bundle, 'p3_world_presence_npc'),
  );
}

String? _resolveConditionalDialogue(RuntimeMapBundle bundle, GameState state) {
  final evaluator = MapEntityRuntimePredicateEvaluator(
    gameState: state,
    chapterIndex: buildGlobalStoryChapterStepIndex(bundle.manifest.scenarios),
  );
  return evaluator
      .resolveNpcDialogue(_npc(bundle, 'p3_conditional_dialogue_npc').npc!)
      ?.dialogueId;
}

MapEntity _npc(RuntimeMapBundle bundle, String entityId) {
  return bundle.map.entities.singleWhere((entity) => entity.id == entityId);
}

class _TestFileGameSaveRepository extends FileGameSaveRepository {
  _TestFileGameSaveRepository(this._testDirectory);

  final Directory _testDirectory;

  Future<String> exposedSaveFilePath() => getSaveFilePath();

  @override
  Future<String> getSaveFilePath() async {
    final saveDir = Directory('${_testDirectory.path}/pokemonProject');
    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }
    return '${saveDir.path}/game_save.json';
  }
}
