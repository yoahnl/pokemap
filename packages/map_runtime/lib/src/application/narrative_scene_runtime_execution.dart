import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'scene_runtime/scene_consequence_runtime_writer.dart';
import 'scene_runtime/scene_runtime_host_callbacks.dart';

/// Executes the configured Event V2 Scene against the coordinator snapshot.
///
/// Consequences are buffered until the Scene completes. A failed Scene never
/// leaks a partial GameState update to the F1 transaction coordinator.
Future<NarrativeSceneExecutionResult> executeNarrativeEventScene({
  required NarrativeSceneExecutionRequest request,
  required ProjectManifest project,
  required Map<String, MapData> mapsById,
  required GameState Function() currentGameState,
  required SceneRuntimeHostCallbacks callbacks,
  SceneConsequenceRuntimeWriter? consequenceWriter,
  List<NarrativeOutcomeRef> hostedBattleOutcomes = const [],
  int maxSteps = 100,
}) async {
  if (currentGameState() != request.gameState) {
    return NarrativeSceneExecutionResult.failed(
      StateError(
        'Event V2 Scene "${request.sceneId}" has an initial GameState '
        'conflict.',
      ),
    );
  }

  final matchingScenes = project.scenes
      .where((scene) => scene.id == request.sceneId)
      .toList(growable: false);
  if (matchingScenes.length != 1) {
    return NarrativeSceneExecutionResult.failed(
      StateError(
        matchingScenes.isEmpty
            ? 'Event V2 Scene "${request.sceneId}" was not found.'
            : 'Event V2 Scene "${request.sceneId}" is ambiguous.',
      ),
    );
  }
  final scene = matchingScenes.single;
  final diagnostics = diagnoseSceneAgainstProject(
    scene,
    project,
    mapsById: mapsById,
  );
  if (diagnostics.hasErrors) {
    return NarrativeSceneExecutionResult.failed(
      StateError(
        'Event V2 Scene "${request.sceneId}" has blocking diagnostics.',
      ),
    );
  }
  final planResult = buildSceneRuntimePlan(scene);
  if (!planResult.canBuild) {
    return NarrativeSceneExecutionResult.failed(
      StateError(
        'Event V2 Scene "${request.sceneId}" cannot build a runtime plan.',
      ),
    );
  }

  // Only Scene consequences are buffered for the coordinator transaction.
  // Host callbacks (battle/dialogue) own their runtime side effects; once the
  // Scene completes, those authoritative writes are kept by rebasing the
  // buffered consequences onto the latest host GameState.
  final pendingConsequences = <SceneConsequence>[];
  final pendingPokemonGrantOperationIds = <String?>[];
  final pendingRailProgressionOperationIds = <String?>[];
  final writer = consequenceWriter ??
      SceneConsequenceRuntimeWriter(
        project: project,
        mapsById: mapsById,
      );
  var validationState = request.gameState;
  final execution = await SceneRuntimeExecutor(
    callbacks: callbacks.toExecutionCallbacks(
      applyConsequence: (consequence) {
        throw UnsupportedError('Scene node id is required for consequences.');
      },
      applyConsequenceWithNodeId: (nodeId, consequence) {
        final grantOperationId = scenePokemonGrantOperationId(
          sceneId: request.sceneId,
          executionId: request.executionId,
          nodeId: nodeId,
          consequence: consequence,
        );
        final railProgressionOperationId = sceneRailProgressionOperationId(
          sceneId: request.sceneId,
          executionId: request.executionId,
          nodeId: nodeId,
          consequence: consequence,
        );
        final validation = writer.applyOne(
          validationState,
          consequence,
          pokemonGrantOperationId: grantOperationId,
          railProgressionOperationId: railProgressionOperationId,
        );
        if (!validation.success) {
          throw StateError(
            validation.message ??
                'Scene consequence ${consequence.kind.name} was rejected.',
          );
        }
        validationState = validation.gameState;
        pendingConsequences.add(consequence);
        pendingPokemonGrantOperationIds.add(grantOperationId);
        pendingRailProgressionOperationIds.add(railProgressionOperationId);
        return 'completed';
      },
    ),
    maxSteps: maxSteps,
  ).execute(planResult.plan!);
  if (execution.status != SceneRuntimeExecutionStatus.completed) {
    return NarrativeSceneExecutionResult.failed(
      StateError(
        execution.message ??
            'Event V2 Scene "${request.sceneId}" failed during execution.',
      ),
    );
  }

  final writeResult = writer.applyAll(
    currentGameState(),
    pendingConsequences,
    pokemonGrantOperationIds: pendingPokemonGrantOperationIds,
    railProgressionOperationIds: pendingRailProgressionOperationIds,
  );
  if (!writeResult.success) {
    return NarrativeSceneExecutionResult.failed(
      StateError(
        writeResult.message ??
            'Event V2 Scene "${request.sceneId}" consequence commit failed.',
      ),
    );
  }

  final sceneOutcomeId = execution.sceneOutcomeId;
  return NarrativeSceneExecutionResult.completed(
    updatedGameState: writeResult.gameState,
    gameCompletion: writeResult.gameCompletion,
    qualifiedOutcomes: <NarrativeOutcomeRef>[
      ...hostedBattleOutcomes,
      if (sceneOutcomeId != null)
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: scene.id,
          outcomeId: sceneOutcomeId,
        ),
    ],
  );
}
