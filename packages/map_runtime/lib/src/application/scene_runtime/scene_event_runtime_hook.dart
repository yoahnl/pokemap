import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'scene_interactive_pokemon_gift.dart';

import 'scene_consequence_runtime_writer.dart';
import 'scene_consequence_runtime_write_result.dart';
import 'scene_runtime_host_callbacks.dart';
import 'scene_runtime_hook_result.dart';
import 'scene_fact_condition_runtime_resolver.dart';

final class SceneEventRuntimeHook {
  SceneEventRuntimeHook({
    required this.callbacks,
    this.consequenceWriter,
    this.maxSteps = 100,
  }) {
    if (maxSteps < 1) {
      throw ArgumentError.value(
        maxSteps,
        'maxSteps',
        'SceneEventRuntimeHook requires maxSteps >= 1.',
      );
    }
  }

  final SceneRuntimeHostCallbacks callbacks;
  final SceneConsequenceRuntimeWriter? consequenceWriter;
  final int maxSteps;

  Future<SceneEventRuntimeHookResult> runForEventPage({
    required ProjectManifest project,
    required MapData map,
    required MapEventDefinition event,
    required MapEventPage page,
    GameState? gameState,
    GameState Function()? currentGameState,
    String executionId = '',
  }) async {
    final sceneTarget = page.sceneTarget;
    if (sceneTarget == null) {
      return const SceneEventRuntimeHookResult.notHandled();
    }

    final sceneId = sceneTarget.sceneId;
    final scene = _findScene(project, sceneId);
    if (scene == null) {
      return SceneEventRuntimeHookResult.failed(
        errorCode: SceneEventRuntimeHookErrorCode.sceneTargetMissingScene,
        sceneId: sceneId,
        message:
            'Scene V1 "$sceneId" referenced by event "${event.id}" '
            'on map "${map.id}" was not found.',
      );
    }

    final diagnostics = diagnoseSceneAgainstProject(
      scene,
      project,
      mapsById: {map.id: map},
    );
    if (diagnostics.hasErrors) {
      return SceneEventRuntimeHookResult.failed(
        errorCode: SceneEventRuntimeHookErrorCode.sceneTargetDiagnosticsFailed,
        sceneId: sceneId,
        message:
            'Scene V1 "$sceneId" referenced by event "${event.id}" '
            'on map "${map.id}" has blocking diagnostics.',
      );
    }

    final planResult = buildSceneRuntimePlan(scene);
    if (!planResult.canBuild) {
      return SceneEventRuntimeHookResult.failed(
        errorCode: SceneEventRuntimeHookErrorCode.sceneTargetRuntimePlanFailed,
        sceneId: sceneId,
        message:
            'Scene V1 "$sceneId" referenced by event "${event.id}" '
            'on map "${map.id}" cannot build a runtime plan.',
      );
    }

    final pendingConsequences = <SceneConsequence>[];
  final preparedPokemonGifts = <String, PreparedScenePokemonGift>{};
    final pendingPokemonGrantOperationIds = <String?>[];
    final pendingRailProgressionOperationIds = <String?>[];
    final writer =
        consequenceWriter ??
        SceneConsequenceRuntimeWriter(
          project: project,
          mapsById: {map.id: map},
        );
    var validationState = currentGameState?.call() ?? gameState;
    SceneConsequenceRuntimeWriteResult? rejectedConsequenceWrite;
    GameState projectedState() {
      final base = currentGameState?.call() ?? gameState;
      if (base == null) {
        throw StateError('The Scene requires a GameState for its item gift.');
      }
      final projected = writer.applyAll(
        base,
        pendingConsequences,
        pokemonGrantOperationIds: pendingPokemonGrantOperationIds,
        railProgressionOperationIds: pendingRailProgressionOperationIds,
        preparedPokemonGifts: preparedPokemonGifts,
      );
      if (!projected.success) {
        throw StateError(projected.message ?? 'Scene state projection failed.');
      }
      return projected.gameState;
    }

    final transactionalCallbacks = SceneRuntimeHostCallbacks(
      evaluateCondition: (intent) {
        final source = intent.conditionSource;
        if (source?.sourceKind == SceneConditionSourceKind.partyState) {
          return evaluateScenePartyCondition(
            source: source!,
            gameState: projectedState(),
            context: writer.partyConditionContext,
          ) ? 'true' : 'false';
        }
        if (pendingConsequences.isEmpty ||
            source == null ||
            (source.sourceKind != SceneConditionSourceKind.badge &&
                source.sourceKind != SceneConditionSourceKind.inventoryItem &&
                source.sourceKind != SceneConditionSourceKind.mapEventInstanceBoolean &&
                source.sourceKind != SceneConditionSourceKind.fact)) {
          return callbacks.evaluateCondition(intent);
        }
        final projected = projectedState();
        final matched = switch (source.sourceKind) {
          SceneConditionSourceKind.mapEventInstanceBoolean =>
            evaluateSceneMapEventInstanceBoolean(
              source: source,
              gameState: projected,
              map: map,
              scope:
                  writer.mapInstanceScopes[source.mapId] ??
                  (throw StateError(
                    'Scene condition instance scope is unavailable.',
                  )),
            ),
          SceneConditionSourceKind.badge => evaluateSceneBadgeCondition(
            source: source,
            gameState: projected,
          ),
          SceneConditionSourceKind.inventoryItem =>
            evaluateSceneInventoryCondition(
              source: source,
              gameState: projected,
            ),
          _ => evaluateCanonicalNarrativeFactSceneCondition(
            source: source,
            gameState: projected,
            resolver: NarrativeFactRuntimeResolver.fromFacts(project.facts),
          ),
        };
        return matched ? 'true' : 'false';
      },
      showDialogue: callbacks.showDialogue,
      startBattle: callbacks.startBattle,
      playCinematic: callbacks.playCinematic,
      playPresentationCinematic: callbacks.playPresentationCinematic,
      requestStructuredInteraction: callbacks.requestStructuredInteraction,
      executeInteractiveCommand: (intent) async {
        final command = intent.interactiveCommand;
        if (command is SceneReceivePokemonFromCatalogInteractiveCommand) {
          final catalog = writer.pokemonCatalog;
          final presenter = callbacks.presentPokemonGift;
          if (catalog == null || presenter == null) {
            throw StateError(
              'The Pokemon gift catalog or presenter is unavailable.',
            );
          }
          final consequence = SceneGivePokemonFromCatalogConsequence(
            speciesId: command.speciesId,
            formId: command.formId,
            level: command.level,
            moveIds: command.moveIds,
          );
          final operationId = scenePokemonGrantOperationId(
            sceneId: sceneId,
            executionId: executionId,
            nodeId: intent.sourceNodeId ?? '',
            consequence: consequence,
          );
          if (operationId == null) {
            throw StateError('The Pokemon gift source identity is missing.');
          }
          final result = await receiveScenePokemonFromCatalog(
            command: command,
            operationId: operationId,
            project: project,
            readProjectedState: projectedState,
            catalog: catalog,
            present: presenter,
          );
          if (result.prepared case final prepared?) {
            preparedPokemonGifts[operationId] = prepared;
            pendingConsequences.add(consequence);
            pendingPokemonGrantOperationIds.add(operationId);
            pendingRailProgressionOperationIds.add(null);
            validationState = projectedState();
          }
          return result.outputPortId;
        }


        if (command is! SceneGiveItemInteractiveCommand) {
          final callback = callbacks.executeInteractiveCommand;
          if (callback == null) {
            throw StateError(
              'No interactive Scene command executor is installed.',
            );
          }
          return callback(intent);
        }
        final result = executeSceneItemGift(
          command: command,
          gameState: projectedState(),
        );
        if (result.outcome == SceneItemGiftOutcome.received) {
          validationState = result.gameState;
          pendingConsequences.add(
            SceneConsequence.giveItem(
              itemId: command.itemId,
              quantity: command.quantity,
            ),
          );
          pendingPokemonGrantOperationIds.add(null);
          pendingRailProgressionOperationIds.add(null);
        }
        return result.outcome.name;
      },
    );
    final executionResult = await SceneRuntimeExecutor(
      callbacks: transactionalCallbacks.toExecutionCallbacks(
        applyConsequence: (consequence) {
          throw UnsupportedError('Scene node id is required for consequences.');
        },
        applyConsequenceWithNodeId: (nodeId, consequence) {
          final grantOperationId = scenePokemonGrantOperationId(
            sceneId: sceneId,
            executionId: executionId,
            nodeId: nodeId,
            consequence: consequence,
          );
          final railProgressionOperationId = sceneRailProgressionOperationId(
            sceneId: sceneId,
            executionId: executionId,
            nodeId: nodeId,
            consequence: consequence,
          );
          final currentValidationState = validationState;
          if (currentValidationState != null) {
            final validation = writer.applyOne(
              currentValidationState,
              consequence,
              pokemonGrantOperationId: grantOperationId,
              railProgressionOperationId: railProgressionOperationId,
            );
            if (!validation.success) {
              rejectedConsequenceWrite = validation;
              throw StateError(
                validation.message ??
                    'Scene consequence ${consequence.kind.name} was rejected.',
              );
            }
            validationState = validation.gameState;
          }
          pendingConsequences.add(consequence);
          pendingPokemonGrantOperationIds.add(grantOperationId);
          pendingRailProgressionOperationIds.add(railProgressionOperationId);
          return 'completed';
        },
      ),
      maxSteps: maxSteps,
    ).execute(planResult.plan!);

    if (executionResult.status == SceneRuntimeExecutionStatus.completed) {
      if (pendingConsequences.isEmpty) {
        return SceneEventRuntimeHookResult.completed(
          sceneId: sceneId,
          executionResult: executionResult,
        );
      }

      final commitBaseState = currentGameState?.call() ?? gameState;
      if (commitBaseState == null) {
        return SceneEventRuntimeHookResult.failed(
          errorCode: SceneEventRuntimeHookErrorCode.sceneConsequenceWriteFailed,
          sceneId: sceneId,
          message:
              'Scene V1 "$sceneId" produced consequences but no '
              'GameState was provided for a controlled commit.',
          executionResult: executionResult,
        );
      }

      final writeResult = writer.applyAll(
        commitBaseState,
        pendingConsequences,
        pokemonGrantOperationIds: pendingPokemonGrantOperationIds,
        railProgressionOperationIds: pendingRailProgressionOperationIds,
        preparedPokemonGifts: preparedPokemonGifts,
      );
      if (!writeResult.success) {
        return SceneEventRuntimeHookResult.failed(
          errorCode: SceneEventRuntimeHookErrorCode.sceneConsequenceWriteFailed,
          sceneId: sceneId,
          message:
              writeResult.message ??
              'Scene V1 "$sceneId" consequence commit failed.',
          executionResult: executionResult,
          consequenceWriteResult: writeResult,
        );
      }

      return SceneEventRuntimeHookResult.completed(
        sceneId: sceneId,
        executionResult: executionResult,
        updatedGameState: writeResult.gameState,
        consequenceWriteResult: writeResult,
      );
    }

    final rejectedWrite = rejectedConsequenceWrite;
    if (rejectedWrite != null) {
      return SceneEventRuntimeHookResult.failed(
        errorCode: SceneEventRuntimeHookErrorCode.sceneConsequenceWriteFailed,
        sceneId: sceneId,
        message:
            rejectedWrite.message ??
            'Scene V1 "$sceneId" consequence validation failed.',
        executionResult: executionResult,
        consequenceWriteResult: rejectedWrite,
      );
    }

    return SceneEventRuntimeHookResult.failed(
      errorCode: SceneEventRuntimeHookErrorCode.sceneExecutionFailed,
      sceneId: sceneId,
      message:
          executionResult.message ??
          'Scene V1 "$sceneId" referenced by event "${event.id}" '
              'on map "${map.id}" failed during execution.',
      executionResult: executionResult,
    );
  }
}

SceneAsset? _findScene(ProjectManifest project, String sceneId) {
  for (final scene in project.scenes) {
    if (scene.id == sceneId) {
      return scene;
    }
  }
  return null;
}
