import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/narrative_scene_runtime_execution.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Selbrume terminal Scene commits victory and returns to the Hub',
      () async {
    final project = _loadSelbrumeProject();
    final eventRecord = project.eventRegistry!.records.singleWhere(
      (record) => record.definitionOrNull?.sceneId == 'scene_ending_port',
    );
    final event = eventRecord.definitionOrNull!;
    final scene = project.scenes.singleWhere(
      (candidate) => candidate.id == event.sceneId,
    );
    final finishNodes = scene.graph.nodes.where(
      (node) =>
          node.payload is SceneActionPayload &&
          (node.payload as SceneActionPayload).consequence
              is SceneFinishGameConsequence,
    );

    expect(eventRecord.enabledOrNull, isTrue);
    expect(event.reusePolicy, NarrativeEventReusePolicy.oneShot);
    expect(event.source.toJson(), {
      'kind': 'triggerEnter',
      'mapId': 'map_port_brisants',
      'triggerId': 'zone_port_center',
    });
    expect(
      event.conditions.single.toJson(),
      {
        'kind': 'fact',
        'factId': 'fact_mist_source_resolved',
        'expectedValue': true,
      },
    );
    expect(finishNodes, hasLength(1));
    expect(buildSceneRuntimePlan(scene).canBuild, isTrue);

    final finish = (finishNodes.single.payload as SceneActionPayload)
        .consequence as SceneFinishGameConsequence;
    expect(finish.endingId, 'ending.selbrume-sauvee');
    expect(finish.outcome, SceneGameCompletionOutcome.victory);
    expect(
      finish.commitPolicy,
      SceneFinishGameCommitPolicy.persistBeforePresentation,
    );
    expect(finish.postGamePolicy, ScenePostGamePolicy.returnToHub);
    expect(finish.credits, isNotNull);
    expect(finish.credits!.skippable, isTrue);

    final initial = const GameState(
      saveId: 'save_selbrume_terminal_contract',
      currentMapId: 'map_port_brisants',
    ).copyWith(
      storyFlags: const StoryFlags(
        activeFlags: {'fact_mist_source_resolved'},
      ),
      narrativeFactRuntimeState: NarrativeFactRuntimeState(
        overridesByFactId: const {'fact_mist_source_resolved': true},
      ),
    );
    final playedCinematics = <String>[];
    final playedDialogues = <String>[];

    final result = await executeNarrativeEventScene(
      request: NarrativeSceneExecutionRequest(
        eventId: event.id,
        sceneId: scene.id,
        executionId: 'execution_selbrume_terminal_contract',
        gameState: initial,
      ),
      project: project,
      mapsById: const <String, MapData>{},
      currentGameState: () => initial,
      callbacks: SceneRuntimeHostCallbacks(
        evaluateCondition: (_) => throw StateError(
          'The canonical terminal Scene has no runtime condition node.',
        ),
        showDialogue: (intent) {
          playedDialogues.add(intent.dialogueId!);
          return 'completed';
        },
        startBattle: (_) => throw StateError(
          'The canonical terminal Scene has no battle node.',
        ),
        playCinematic: (intent) {
          playedCinematics.add(intent.cinematicId!);
          return 'completed';
        },
      ),
    );

    expect(
      result,
      isA<NarrativeSceneExecutionCompleted>(),
      reason: result is NarrativeSceneExecutionFailed
          ? result.failure.toString()
          : null,
    );
    final completed = result as NarrativeSceneExecutionCompleted;
    expect(playedDialogues, ['dialogue_ending_port']);
    expect(
      playedCinematics,
      ['cinematic_port_celebration', 'cinematic_lighthouse_final_beam'],
    );
    expect(
      completed.updatedGameState.narrativeFactRuntimeState.overridesByFactId,
      containsPair('fact_main_story_completed', true),
    );
    expect(
      completed.updatedGameState.narrativeFactRuntimeState.overridesByFactId,
      containsPair('fact_ending_seen', true),
    );
    expect(
      completed.updatedGameState.progression.completedStepIds,
      containsAll({'step_return_to_port', 'step_main_story_completed'}),
    );
    expect(
      completed.updatedGameState.metadata[sceneGameCompletionEndingMetadataKey],
      'ending.selbrume-sauvee',
    );
    expect(completed.gameCompletion!.endingId, 'ending.selbrume-sauvee');
    expect(
      completed.gameCompletion!.outcome,
      SceneGameCompletionOutcome.victory,
    );
    expect(
      completed.gameCompletion!.postGamePolicy,
      ScenePostGamePolicy.returnToHub,
    );
    expect(completed.gameCompletion!.credits!.skippable, isTrue);
  });
}

ProjectManifest _loadSelbrumeProject() {
  final root = _repositoryRoot();
  return ProjectManifest.fromJson(
    jsonDecode(
      File(p.join(root.path, 'selbrume', 'project.json')).readAsStringSync(),
    ) as Map<String, dynamic>,
  );
}

Directory _repositoryRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(p.join(current.path, 'selbrume', 'project.json')).existsSync()) {
      return current;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Repository root containing Selbrume was not found.');
    }
    current = parent;
  }
}
