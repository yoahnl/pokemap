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
  bool? uniqueBattleConsumed;
  var blockedUniqueBattle = false;
  final consumedUniqueTableIds = <String>{};
  final execution = await SceneRuntimeExecutor(
    callbacks: SceneRuntimeHostCallbacks(
      evaluateCondition: (intent) {
        final source = intent.conditionSource;
        if (source?.sourceKind != SceneConditionSourceKind.inventoryItem ||
            pendingConsequences.isEmpty) {
          return callbacks.evaluateCondition(intent);
        }
        final projected = writer.applyAll(
          currentGameState(),
          pendingConsequences,
          pokemonGrantOperationIds: pendingPokemonGrantOperationIds,
          railProgressionOperationIds: pendingRailProgressionOperationIds,
        );
        if (!projected.success) {
          throw StateError(
              projected.message ?? 'Scene inventory projection failed.');
        }
        return evaluateSceneInventoryCondition(
          source: source!,
          gameState: projected.gameState,
        )
            ? 'true'
            : 'false';
      },
      showDialogue: callbacks.showDialogue,
      startBattle: (intent) async {
        final uniqueTable = project.encounterTables.any(
          (table) =>
              table.id == intent.battleTemplateId &&
              table.tags.contains('studio:unique'),
        );
        if (intent.battleKind == 'wild' &&
            uniqueTable &&
            (consumedUniqueTableIds.contains(intent.battleTemplateId) ||
                currentGameState().storyFlags.activeFlags.contains(
                      uniqueEncounterConsumedFlag(intent.battleTemplateId!),
                    ))) {
          blockedUniqueBattle = true;
          throw StateError('Cette rencontre unique a déjà eu lieu.');
        }
        final outcome = await callbacks.startBattle(intent);
        if (intent.battleKind == 'wild' && uniqueTable) {
          final consumed = outcome == 'victory' || outcome == 'captured';
          uniqueBattleConsumed = (uniqueBattleConsumed ?? false) || consumed;
          if (consumed) consumedUniqueTableIds.add(intent.battleTemplateId!);
        }
        return outcome;
      },
      playCinematic: callbacks.playCinematic,
      playPresentationCinematic: callbacks.playPresentationCinematic,
      executeInteractiveCommand: callbacks.executeInteractiveCommand,
      requestStructuredInteraction: callbacks.requestStructuredInteraction,
    ).toExecutionCallbacks(
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
    if (blockedUniqueBattle) {
      return NarrativeSceneExecutionResult.cancelled(
        StateError('Cette rencontre unique a déjà eu lieu.'),
      );
    }
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
  var completedState = writeResult.gameState;
  for (final tableId in consumedUniqueTableIds) {
    completedState = const GameStateMutations().setFlag(
      completedState,
      uniqueEncounterConsumedFlag(tableId),
    );
  }
  return NarrativeSceneExecutionResult.completed(
    updatedGameState: completedState,
    gameCompletion: writeResult.gameCompletion,
    consumeOneShot: uniqueBattleConsumed ?? true,
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

String uniqueEncounterConsumedFlag(String tableId) =>
    'studio:unique_encounter:${Uri.encodeComponent(tableId)}:consumed';
