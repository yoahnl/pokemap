import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'scene_runtime/scene_consequence_runtime_writer.dart';
import 'scene_runtime/scene_consequence_runtime_write_result.dart';
import 'scene_runtime/scene_fact_condition_runtime_resolver.dart';
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
  void Function(GameState Function()? projector)? onSceneStateProjection,
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
        mapsById: mapsById);
  final retiredInstanceScopes = <MapInstanceRef>{};
  SceneConsequenceRuntimeWriteResult projectPending(
    GameState state, {
    SceneConsequence? additional,
    String? grantOperationId,
    String? railOperationId,
  }) {
    final indices = <int>[
      for (var index = 0; index < pendingConsequences.length; index++)
        if (pendingConsequences[index]
                is! SceneSetMapEventInstanceBooleanConsequence ||
            !retiredInstanceScopes.contains(
              writer.mapInstanceScopes[(pendingConsequences[index]
                      as SceneSetMapEventInstanceBooleanConsequence)
                  .mapId],
            ))
          index,
    ];
    return writer.applyAll(
      state,
      [
        for (final index in indices) pendingConsequences[index],
        ?additional,
      ],
      pokemonGrantOperationIds: [
        for (final index in indices) pendingPokemonGrantOperationIds[index],
        if (additional != null) grantOperationId,
      ],
      railProgressionOperationIds: [
        for (final index in indices) pendingRailProgressionOperationIds[index],
        if (additional != null) railOperationId,
      ],
    );
  }

  final factResolver = NarrativeFactRuntimeResolver.fromFacts(project.facts);
  bool? uniqueBattleConsumed;
  var blockedUniqueBattle = false;
  final consumedUniqueTableIds = <String>{};
  try {
    onSceneStateProjection?.call(() {
      final projected = projectPending(currentGameState());
      if (!projected.success) {
        throw StateError(projected.message ?? 'Scene state projection failed.');
      }
      return projected.gameState;
    });
    final execution = await SceneRuntimeExecutor(
      callbacks: SceneRuntimeHostCallbacks(
        evaluateCondition: (intent) {
          final source = intent.conditionSource;
          if (pendingConsequences.isEmpty ||
              source == null ||
              !const {
                SceneConditionSourceKind.inventoryItem,
                SceneConditionSourceKind.badge,
                SceneConditionSourceKind.fact,
                    SceneConditionSourceKind.mapEventInstanceBoolean,
                  }.contains(source.sourceKind)) {
            return callbacks.evaluateCondition(intent);
          }
          final projected = projectPending(currentGameState());
          if (!projected.success) {
            throw StateError(
              projected.message ?? 'Scene condition projection failed.',
            );
          }
          final matched = switch (source.sourceKind) {
                SceneConditionSourceKind.mapEventInstanceBoolean =>
                  evaluateSceneMapEventInstanceBoolean(
                    source: source,
                    gameState: projected.gameState,
                    map:
                        mapsById[source.mapId] ??
                        (throw StateError(
                          'Scene condition map is unavailable.',
                        )),
                    scope:
                        writer.mapInstanceScopes[source.mapId] ??
                        (throw StateError(
                          'Scene condition instance scope is unavailable.',
                        )),
                  ),
                SceneConditionSourceKind.badge => evaluateSceneBadgeCondition(
                source: source,
                gameState: projected.gameState,
              ),
            SceneConditionSourceKind.fact => evaluateCanonicalNarrativeFactSceneCondition(
                source: source,
                gameState: projected.gameState,
                resolver: factResolver,
              ),
            _ => evaluateSceneInventoryCondition(
                source: source,
                gameState: projected.gameState,
              ),
          };
          return matched ? 'true' : 'false';
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
        executeInteractiveCommand: (intent) async {
              final command = intent.interactiveCommand;
              if (command is! SceneGiveItemInteractiveCommand) {
                final callback = callbacks.executeInteractiveCommand;
                if (callback == null) {
                  throw StateError(
                    'No interactive Scene command executor is installed.',
                  );
                }
                final before = currentGameState().mapInstanceWorldState;
                final port = await callback(intent);
                if (command is SceneWarpInteractiveCommand &&
                    port == 'completed' &&
                    currentGameState().currentMapId ==
                        command.destinationMapId) {
                  final after = currentGameState().mapInstanceWorldState;
                  for (final scope in writer.mapInstanceScopes.values) {
                    if (before.instanceRef(scope.mapId) == scope &&
                        after.instanceRef(scope.mapId) != scope) {
                      retiredInstanceScopes.add(scope);
                    }
                  }
                }
                return port;
              }
              final projected = projectPending(currentGameState());
              if (!projected.success) {
                throw StateError(
                  projected.message ?? 'Item gift projection failed.',
                );
              }
              final result = executeSceneItemGift(
                command: command,
                gameState: projected.gameState,
              );
              if (result.outcome == SceneItemGiftOutcome.received) {
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
        requestStructuredInteraction: callbacks.requestStructuredInteraction,
      ).toExecutionCallbacks(
        applyConsequence: (consequence) {
          throw UnsupportedError('Scene node id is required for consequences.',
              );
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
          final validation = projectPending(
            currentGameState(),
            additional: consequence,
            grantOperationId: grantOperationId,
            railOperationId: railProgressionOperationId,
          );
          if (!validation.success) {
            throw StateError(
              validation.message ??
                  'Scene consequence ${consequence.kind.name} was rejected.',
            );
          }
          pendingConsequences.add(consequence);
          pendingPokemonGrantOperationIds.add(grantOperationId);
          pendingRailProgressionOperationIds.add(railProgressionOperationId,
              );
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

    final writeResult = projectPending(currentGameState());
    if (!writeResult.success) {
      return NarrativeSceneExecutionResult.failed(
        StateError(
          writeResult.message ??
              'Event V2 Scene "${request.sceneId}" consequence commit failed.',
        ),
      );
    }

    final sceneOutcomeId = execution.sceneOutcomeId;
    final retryableEnd = planResult.plan!.nodes.any(
      (node) => node.id == execution.finalNodeId &&
          node.intent.outcomePolicy == SceneOutcomePolicy.retryable,
    );
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
      consumeOneShot: !retryableEnd && (uniqueBattleConsumed ?? true),
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
  } finally {
    onSceneStateProjection?.call(null);
  }
}

String uniqueEncounterConsumedFlag(String tableId) =>
    'studio:unique_encounter:${Uri.encodeComponent(tableId)}:consumed';
