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

  group('P3 fact and world rule runtime projection', () {
    test('loads the disk fixture and projects NPC visibility from truths',
        () async {
      final bundle = await _loadBundle();
      final rules =
          buildStepStudioWorldPresenceRuleList(bundle.manifest.scenarios);

      expect(bundle.map.id, _mapId);
      expect(rules, hasLength(1));

      _expectVisibilityFlip(
        bundle,
        entityId: 'p3_flag_visible_npc',
        inactive: const GameState(saveId: 'p3-fact-world-rule'),
        active: _state(flags: {_flagVisible}),
        wrong: _state(flags: {'p3.fact.flag.wrong'}),
      );

      _expectVisibilityFlip(
        bundle,
        entityId: 'p3_step_visible_npc',
        inactive: const GameState(saveId: 'p3-fact-world-rule'),
        active: _state(completedSteps: [_stepVisible]),
        wrong: _state(completedSteps: ['p3.step.wrong']),
      );

      _expectVisibilityFlip(
        bundle,
        entityId: 'p3_cutscene_visible_npc',
        inactive: const GameState(saveId: 'p3-fact-world-rule'),
        active: _state(completedCutscenes: [_cutsceneVisible]),
        wrong: _state(completedCutscenes: ['p3.cutscene.wrong']),
      );

      _expectVisibilityFlip(
        bundle,
        entityId: 'p3_outcome_visible_npc',
        inactive: const GameState(saveId: 'p3-fact-world-rule'),
        active: _state(flags: {_scenarioOutcomeFlag}),
        wrong: _state(flags: {'scenario.outcome.p3.outcome.wrong'}),
      );

      _expectVisibilityFlip(
        bundle,
        entityId: 'p3_battle_visible_npc',
        inactive: const GameState(saveId: 'p3-fact-world-rule'),
        active: _state(flags: {_battleVictoryFlag}),
        wrong: _state(flags: {'battle:p3_battle_projection:defeat'}),
      );

      _expectVisibilityFlip(
        bundle,
        entityId: 'p3_chapter_visible_npc',
        inactive: _state(completedSteps: ['p3.chapter.step.a']),
        active: _state(completedSteps: [
          'p3.chapter.step.a',
          'p3.chapter.step.b',
        ]),
        wrong: _state(completedSteps: ['p3.chapter.step.wrong']),
      );

      _expectStepStudioPresence(
        bundle,
        rules: rules,
        inactive: const GameState(saveId: 'p3-fact-world-rule'),
        active: _state(completedSteps: [_worldPresenceStep]),
        wrong: _state(completedSteps: ['p3.world_presence.wrong']),
      );
    });

    test('resolves conditional dialogues from existing predicates passively',
        () async {
      final bundle = await _loadBundle();
      final npc = _npc(bundle, 'p3_conditional_dialogue_npc').npc!;

      expect(_resolveDialogue(bundle, npc, const GameState(saveId: 'p3')),
          'p3.default.dialogue');
      expect(_resolveDialogue(bundle, npc, _state(flags: {_flagVisible})),
          'p3.flag.dialogue');
      expect(
          _resolveDialogue(bundle, npc, _state(completedSteps: [_stepVisible])),
          'p3.step.dialogue');
      expect(
          _resolveDialogue(bundle, npc, _state(flags: {_scenarioOutcomeFlag})),
          'p3.outcome.dialogue');
      expect(_resolveDialogue(bundle, npc, _state(flags: {_battleVictoryFlag})),
          'p3.battle.dialogue');
      expect(
          _resolveDialogue(bundle, npc, _state(flags: {'p3.fact.flag.wrong'})),
          'p3.default.dialogue');
    });
  });
}

const _mapId = 'p3_fact_world_rule_map';
const _flagVisible = 'p3.fact.flag.visible';
const _stepVisible = 'p3.step.visible';
const _cutsceneVisible = 'p3.cutscene.visible';
const _scenarioOutcomeFlag = 'scenario.outcome.p3.outcome.visible';
const _battleVictoryFlag = 'battle:p3_battle_projection:victory';
const _worldPresenceStep = 'p3.world_presence.step.visible';

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

GameState _state({
  Set<String> flags = const {},
  List<String> completedSteps = const [],
  List<String> completedCutscenes = const [],
}) {
  return GameState(
    saveId: 'p3-fact-world-rule',
    storyFlags: StoryFlags(activeFlags: flags),
    progression: PlayerProgression(
      completedStepIds: completedSteps,
      completedCutsceneIds: completedCutscenes,
    ),
  );
}

void _expectVisibilityFlip(
  RuntimeMapBundle bundle, {
  required String entityId,
  required GameState inactive,
  required GameState active,
  required GameState wrong,
}) {
  final entity = _npc(bundle, entityId);
  final inactiveBefore = inactive.toJson();
  final activeBefore = active.toJson();
  final wrongBefore = wrong.toJson();

  expect(_isVisible(bundle, entity, inactive), isFalse);
  expect(_isVisible(bundle, entity, wrong), isFalse);
  expect(_isVisible(bundle, entity, active), isTrue);
  expect(inactive.toJson(), inactiveBefore);
  expect(active.toJson(), activeBefore);
  expect(wrong.toJson(), wrongBefore);
}

void _expectStepStudioPresence(
  RuntimeMapBundle bundle, {
  required List<StepStudioWorldPresenceRule> rules,
  required GameState inactive,
  required GameState active,
  required GameState wrong,
}) {
  final entity = _npc(bundle, 'p3_world_presence_npc');
  final inactiveBefore = inactive.toJson();
  final activeBefore = active.toJson();
  final wrongBefore = wrong.toJson();

  expect(
    isNpcRuntimePresentOnMap(
      gameState: inactive,
      manifest: bundle.manifest,
      stepStudioWorldRules: rules,
      mapId: _mapId,
      entity: entity,
    ),
    isFalse,
  );
  expect(
    isNpcRuntimePresentOnMap(
      gameState: wrong,
      manifest: bundle.manifest,
      stepStudioWorldRules: rules,
      mapId: _mapId,
      entity: entity,
    ),
    isFalse,
  );
  expect(
    isNpcRuntimePresentOnMap(
      gameState: active,
      manifest: bundle.manifest,
      stepStudioWorldRules: rules,
      mapId: _mapId,
      entity: entity,
    ),
    isTrue,
  );
  expect(inactive.toJson(), inactiveBefore);
  expect(active.toJson(), activeBefore);
  expect(wrong.toJson(), wrongBefore);
}

bool _isVisible(RuntimeMapBundle bundle, MapEntity entity, GameState state) {
  final evaluator = MapEntityRuntimePredicateEvaluator(
    gameState: state,
    chapterIndex: buildGlobalStoryChapterStepIndex(bundle.manifest.scenarios),
  );
  return evaluator.isNpcPresentOnMap(entity);
}

String? _resolveDialogue(
  RuntimeMapBundle bundle,
  MapEntityNpcData npc,
  GameState state,
) {
  final evaluator = MapEntityRuntimePredicateEvaluator(
    gameState: state,
    chapterIndex: buildGlobalStoryChapterStepIndex(bundle.manifest.scenarios),
  );
  return evaluator.resolveNpcDialogue(npc)?.dialogueId;
}

MapEntity _npc(RuntimeMapBundle bundle, String entityId) {
  return bundle.map.entities.singleWhere((entity) => entity.id == entityId);
}
