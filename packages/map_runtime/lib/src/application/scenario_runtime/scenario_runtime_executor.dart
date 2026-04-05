import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../story_flags_manager.dart';
import 'scenario_runtime_models.dart';

/// Presets source partagés avec l'authoring.
///
/// IMPORTANT:
/// On garde ces chaînes centralisées ici pour éviter les fautes de frappe
/// et garder la correspondance explicite avec les presets de l'éditeur.
const String kScenarioSourceMapEnter = 'sourceMapEnter';
const String kScenarioSourceTriggerEnter = 'sourceTriggerEnter';
const String kScenarioSourceEntityInteract = 'sourceEntityInteract';
const String kScenarioSourceOutcome = 'sourceOutcome';

/// Action kinds réellement supportés par l'exécuteur runtime MVP.
const String kScenarioActionRunScript = 'runScript';
const String kScenarioActionOpenDialogue = 'openDialogue';
const String kScenarioActionShowMessage = 'showMessage';
const String kScenarioActionMoveCharacter = 'moveCharacter';
const String kScenarioActionFollowCharacter = 'followCharacter';
const String kScenarioActionFaceCharacter = 'faceCharacter';
const String kScenarioActionTransitionMap = 'transitionMap';
const String kScenarioActionSetFlag = 'setFlag';
const String kScenarioActionClearFlag = 'clearFlag';
const String kScenarioActionEmitOutcome = 'emitOutcome';

/// Jonction pure graphe après compilation d’un embranchement (Cutscene Studio).
///
/// Ce n’est **pas** une attente temporelle: l’exécuteur avance immédiatement
/// vers le nœud suivant, sans effet gameplay. L’authoring l’introduit pour
/// fusionner Oui/Non avant la suite, sans mentir avec `waitMs` à 0 ms.
const String kScenarioActionFlowMerge = 'flowMerge';

/// Blocs encore non branchés dans l’exécuteur MVP mais présents au graphe.
///
/// Comportement: pas d’effet, passage immédiat au suivant, message explicite
/// (honêteté produit — évite `waitMs` factice).
const String kScenarioActionAuthoringPlaceholder = 'authoringPlaceholder';

/// Préfixe de flag persistant pour les outcomes scénario.
///
/// Le MVP reste volontairement simple: un outcome local est persisté en tant
/// que story flag. Cela permet:
/// - la persistance save/load immédiate,
/// - la réutilisation des conditions existantes (flagIsSet / flagIsUnset),
/// - un pont stable vers la progression globale.
const String kScenarioOutcomeFlagPrefix = 'scenario.outcome.';

String scenarioOutcomeFlagName(String outcomeId) {
  final normalized = outcomeId.trim();
  return '$kScenarioOutcomeFlagPrefix$normalized';
}

/// Bridge d'exécution runtime du Scenario Graph (MVP).
///
/// Ce composant répond à une contrainte produit claire :
/// "on a un graphe authoré, il faut déclencher des effets réels en jeu".
///
/// Portée volontairement limitée du MVP :
/// - sources supportées: map enter / trigger enter / entity interact
///   + outcome reçu (pont local -> global),
/// - nodes supportés: start, reference(source uniquement), dialogue, action,
///   condition simple (via ScriptConditionEvaluator), end
/// - choice/reference non-source restent non supportés pour éviter de
///   promettre une exécution plus large que la réalité actuelle.
class ScenarioRuntimeExecutor {
  const ScenarioRuntimeExecutor({
    this.conditionEvaluator = const ScriptConditionEvaluator(),
    this.storyFlags = const StoryFlagsManager(),
    this.maxTraversalSteps = 48,
  });

  final ScriptConditionEvaluator conditionEvaluator;
  final StoryFlagsManager storyFlags;
  final int maxTraversalSteps;

  /// Résout les trigger IDs couvrant [pos] sur [map].
  ///
  /// Utilisé côté runtime pour détecter les "entrées dans trigger" en
  /// comparant la couverture avant/après déplacement.
  Set<String> triggerIdsAtPosition({
    required MapData map,
    required GridPos pos,
  }) {
    final out = <String>{};
    for (final trigger in map.triggers) {
      if (_rectContains(trigger.area, pos)) {
        final id = trigger.id.trim();
        if (id.isNotEmpty) {
          out.add(id);
        }
      }
    }
    return out;
  }

  /// Tente l'exécution d'un scénario à partir d'un événement source runtime.
  ///
  /// Ordre de résolution déterministe :
  /// - ordre des scénarios dans le manifest,
  /// - ordre des nodes dans le scénario.
  ///
  /// On s'arrête au premier scénario/source correspondant.
  ScenarioRuntimeExecutionResult dispatch({
    required List<ScenarioAsset> scenarios,
    required ScenarioRuntimeSourceEvent sourceEvent,
    required ScenarioRuntimeExecutionContext context,
  }) {
    return _dispatchInternal(
      scenarios: scenarios,
      sourceEvent: sourceEvent,
      context: context,
      depth: 0,
    );
  }

  /// Reprend l'exécution d'un flow scénario après un node déjà exécuté.
  ///
  /// Cas d'usage:
  /// - un node dialogue a été ouvert depuis le bridge scénario;
  /// - une fois le dialogue fermé, on veut continuer vers le node suivant.
  ///
  /// Le contrat est volontairement strict pour éviter les reprises ambiguës:
  /// - scénario + source + node courant doivent exister;
  /// - la reprise part du `next` du node `resumeAfterNodeId`.
  ScenarioRuntimeExecutionResult dispatchContinuation({
    required List<ScenarioAsset> scenarios,
    required String scenarioId,
    required String sourceNodeId,
    required String resumeAfterNodeId,
    required ScenarioRuntimeExecutionContext context,
  }) {
    final normalizedScenarioId = scenarioId.trim();
    final normalizedSourceNodeId = sourceNodeId.trim();
    final normalizedResumeNodeId = resumeAfterNodeId.trim();
    if (normalizedScenarioId.isEmpty ||
        normalizedSourceNodeId.isEmpty ||
        normalizedResumeNodeId.isEmpty) {
      return const ScenarioRuntimeExecutionResult(
        status: ScenarioRuntimeExecutionStatus.blocked,
        effect: ScenarioRuntimeEffect.none(),
        message: 'Continuation invalide: identifiants manquants.',
      );
    }

    ScenarioAsset? scenario;
    for (final candidate in scenarios) {
      if (candidate.id == normalizedScenarioId) {
        scenario = candidate;
        break;
      }
    }
    if (scenario == null) {
      return ScenarioRuntimeExecutionResult(
        status: ScenarioRuntimeExecutionStatus.blocked,
        effect: const ScenarioRuntimeEffect.none(),
        scenarioId: normalizedScenarioId,
        sourceNodeId: normalizedSourceNodeId,
        stopNodeId: normalizedResumeNodeId,
        message: 'Continuation impossible: scénario introuvable.',
      );
    }

    ScenarioNode? sourceNode;
    for (final node in scenario.nodes) {
      if (node.id == normalizedSourceNodeId) {
        sourceNode = node;
        break;
      }
    }
    if (sourceNode == null) {
      return ScenarioRuntimeExecutionResult(
        status: ScenarioRuntimeExecutionStatus.blocked,
        effect: const ScenarioRuntimeEffect.none(),
        scenarioId: normalizedScenarioId,
        sourceNodeId: normalizedSourceNodeId,
        stopNodeId: normalizedResumeNodeId,
        message: 'Continuation impossible: source node introuvable.',
      );
    }

    final nextNodeId = _pickLinearNextNodeId(
      nodeId: normalizedResumeNodeId,
      edges: scenario.edges,
    );
    if (nextNodeId == null || nextNodeId.isEmpty) {
      return ScenarioRuntimeExecutionResult(
        status: ScenarioRuntimeExecutionStatus.reachedEnd,
        effect: const ScenarioRuntimeEffect.none(),
        scenarioId: normalizedScenarioId,
        sourceNodeId: normalizedSourceNodeId,
        stopNodeId: normalizedResumeNodeId,
        message: 'Continuation: aucun node suivant, flow terminé.',
      );
    }

    return _executeScenarioFromSource(
      scenarios: scenarios,
      scenario: scenario,
      sourceNode: sourceNode,
      sourceEvent: ScenarioRuntimeSourceEvent.mapEnter(mapId: ''),
      context: context,
      depth: 0,
      startNodeId: nextNodeId,
    );
  }

  ScenarioRuntimeExecutionResult _dispatchInternal({
    required List<ScenarioAsset> scenarios,
    required ScenarioRuntimeSourceEvent sourceEvent,
    required ScenarioRuntimeExecutionContext context,
    required int depth,
  }) {
    // Garde-fou de récursion: évite les boucles outcome -> outcome.
    if (depth > 8) {
      return const ScenarioRuntimeExecutionResult(
        status: ScenarioRuntimeExecutionStatus.blocked,
        effect: ScenarioRuntimeEffect.none(),
        message: 'Recursion limit reached while dispatching scenario outcomes.',
      );
    }

    for (final scenario in _candidateScenarios(
      scenarios: scenarios,
      sourceEvent: sourceEvent,
    )) {
      if (!_scenarioActivationPasses(scenario, context.gameState)) {
        continue;
      }
      final sourceNode = _findMatchingSourceNode(
        scenario: scenario,
        sourceEvent: sourceEvent,
      );
      if (sourceNode == null) {
        continue;
      }
      return _executeScenarioFromSource(
        scenario: scenario,
        sourceNode: sourceNode,
        sourceEvent: sourceEvent,
        context: context,
        scenarios: scenarios,
        depth: depth,
      );
    }
    return const ScenarioRuntimeExecutionResult(
      status: ScenarioRuntimeExecutionStatus.noMatchingSource,
      effect: ScenarioRuntimeEffect.none(),
      message: 'Aucune source scénario ne correspond à cet événement runtime.',
    );
  }

  Iterable<ScenarioAsset> _candidateScenarios({
    required List<ScenarioAsset> scenarios,
    required ScenarioRuntimeSourceEvent sourceEvent,
  }) {
    // Story-centric layering:
    // - hooks monde => privilégier les scénarios locaux
    // - outcomes => privilégier le graphe global
    switch (sourceEvent.type) {
      case ScenarioRuntimeSourceType.mapEnter:
      case ScenarioRuntimeSourceType.triggerEnter:
      case ScenarioRuntimeSourceType.entityInteract:
        final locals = scenarios
            .where((scenario) => scenario.scope == ScenarioScope.localEventFlow)
            .toList(growable: false);
        return locals.isEmpty ? scenarios : locals;
      case ScenarioRuntimeSourceType.outcomeReceived:
        final globals = scenarios
            .where((scenario) => scenario.scope == ScenarioScope.globalStory)
            .toList(growable: false);
        return globals.isEmpty ? scenarios : globals;
    }
  }

  bool _scenarioActivationPasses(ScenarioAsset scenario, GameState state) {
    final activation = scenario.activationCondition;
    if (activation == null) {
      return true;
    }
    return conditionEvaluator.evaluate(activation, state);
  }

  ScenarioRuntimeExecutionResult _executeScenarioFromSource({
    required List<ScenarioAsset> scenarios,
    required ScenarioAsset scenario,
    required ScenarioNode sourceNode,
    required ScenarioRuntimeSourceEvent sourceEvent,
    required ScenarioRuntimeExecutionContext context,
    required int depth,
    String? startNodeId,
  }) {
    final nodesById = <String, ScenarioNode>{
      for (final node in scenario.nodes) node.id: node,
    };
    final sourceId = sourceNode.id.trim();

    // Étape 1: passer de la source vers le premier node "exécutable".
    var currentNodeId = startNodeId ??
        _pickLinearNextNodeId(
          nodeId: sourceId,
          edges: scenario.edges,
        );
    if (currentNodeId == null || currentNodeId.isEmpty) {
      return ScenarioRuntimeExecutionResult(
        status: ScenarioRuntimeExecutionStatus.blocked,
        effect: const ScenarioRuntimeEffect.none(),
        scenarioId: scenario.id,
        sourceNodeId: sourceId,
        stopNodeId: sourceId,
        message:
            'Source "${sourceNode.id}" sans sortie: aucun flow exécutable.',
      );
    }

    final visited = <String>{sourceId};
    var steps = 0;
    while (steps < maxTraversalSteps) {
      steps++;
      final node = nodesById[currentNodeId];
      if (node == null) {
        return ScenarioRuntimeExecutionResult(
          status: ScenarioRuntimeExecutionStatus.blocked,
          effect: const ScenarioRuntimeEffect.none(),
          scenarioId: scenario.id,
          sourceNodeId: sourceId,
          stopNodeId: currentNodeId,
          message: 'Node introuvable dans le flow: "$currentNodeId".',
        );
      }
      if (!visited.add(node.id)) {
        return ScenarioRuntimeExecutionResult(
          status: ScenarioRuntimeExecutionStatus.blocked,
          effect: const ScenarioRuntimeEffect.none(),
          scenarioId: scenario.id,
          sourceNodeId: sourceId,
          stopNodeId: node.id,
          message: 'Boucle détectée dans le flow scénario (node "${node.id}").',
        );
      }

      switch (node.type) {
        case ScenarioNodeType.start:
          // Un node start intermédiaire est traité comme un passthrough
          // pour rester tolérant sur les graphes déjà authorés.
          final nextNodeId = _pickLinearNextNodeId(
            nodeId: node.id,
            edges: scenario.edges,
          );
          if (nextNodeId == null) {
            return ScenarioRuntimeExecutionResult(
              status: ScenarioRuntimeExecutionStatus.reachedEnd,
              effect: const ScenarioRuntimeEffect.none(),
              scenarioId: scenario.id,
              sourceNodeId: sourceId,
              stopNodeId: node.id,
              message: 'Flow terminé sur Start sans sortie supplémentaire.',
            );
          }
          currentNodeId = nextNodeId;

        case ScenarioNodeType.end:
          return ScenarioRuntimeExecutionResult(
            status: ScenarioRuntimeExecutionStatus.reachedEnd,
            effect: const ScenarioRuntimeEffect.none(),
            scenarioId: scenario.id,
            sourceNodeId: sourceId,
            stopNodeId: node.id,
            message: 'Flow terminé sur End.',
          );

        case ScenarioNodeType.dialogue:
          final dialogueId = node.binding.dialogueId?.trim();
          if (dialogueId != null && dialogueId.isNotEmpty) {
            final started = context.openDialogue(
              dialogueId,
              startNode: _readStartNodeFromPayload(node),
              runtimeSourceId: _runtimeSourceId(
                scenarioId: scenario.id,
                sourceNodeId: sourceId,
                nodeId: node.id,
              ),
            );
            return ScenarioRuntimeExecutionResult(
              status: started
                  ? ScenarioRuntimeExecutionStatus.executedEffect
                  : ScenarioRuntimeExecutionStatus.blocked,
              effect: ScenarioRuntimeEffect(
                type: ScenarioRuntimeEffectType.dialogue,
                dialogueId: dialogueId,
              ),
              scenarioId: scenario.id,
              sourceNodeId: sourceId,
              stopNodeId: node.id,
              message: started
                  ? 'Dialogue "$dialogueId" déclenché.'
                  : 'Impossible d’ouvrir le dialogue "$dialogueId".',
            );
          }

          final scriptId = node.binding.scriptId?.trim();
          if (scriptId != null && scriptId.isNotEmpty) {
            final started = context.runScript(
              scriptId,
              startNode: _readStartNodeFromPayload(node),
              runtimeSourceId: _runtimeSourceId(
                scenarioId: scenario.id,
                sourceNodeId: sourceId,
                nodeId: node.id,
              ),
            );
            return ScenarioRuntimeExecutionResult(
              status: started
                  ? ScenarioRuntimeExecutionStatus.executedEffect
                  : ScenarioRuntimeExecutionStatus.blocked,
              effect: ScenarioRuntimeEffect(
                type: ScenarioRuntimeEffectType.script,
                scriptId: scriptId,
              ),
              scenarioId: scenario.id,
              sourceNodeId: sourceId,
              stopNodeId: node.id,
              message: started
                  ? 'Script "$scriptId" déclenché depuis node Dialogue.'
                  : 'Impossible de lancer le script "$scriptId".',
            );
          }

          final inlineMessage = node.payload.message?.trim();
          if (inlineMessage != null && inlineMessage.isNotEmpty) {
            context.showMessage(inlineMessage);
            return ScenarioRuntimeExecutionResult(
              status: ScenarioRuntimeExecutionStatus.executedEffect,
              effect: ScenarioRuntimeEffect(
                type: ScenarioRuntimeEffectType.message,
                message: inlineMessage,
              ),
              scenarioId: scenario.id,
              sourceNodeId: sourceId,
              stopNodeId: node.id,
              message: 'Message inline déclenché depuis node Dialogue.',
            );
          }

          return ScenarioRuntimeExecutionResult(
            status: ScenarioRuntimeExecutionStatus.blocked,
            effect: const ScenarioRuntimeEffect.none(),
            scenarioId: scenario.id,
            sourceNodeId: sourceId,
            stopNodeId: node.id,
            message:
                'Node Dialogue "${node.id}" incomplet (dialogue/script/message manquant).',
          );

        case ScenarioNodeType.action:
          final actionKind = node.payload.actionKind?.trim() ?? '';
          if (actionKind.isEmpty) {
            return ScenarioRuntimeExecutionResult(
              status: ScenarioRuntimeExecutionStatus.blocked,
              effect: const ScenarioRuntimeEffect.none(),
              scenarioId: scenario.id,
              sourceNodeId: sourceId,
              stopNodeId: node.id,
              message: 'Node Action "${node.id}" sans actionKind.',
            );
          }

          switch (actionKind) {
            case kScenarioActionRunScript:
              final scriptId = node.binding.scriptId?.trim() ?? '';
              if (scriptId.isEmpty) {
                return ScenarioRuntimeExecutionResult(
                  status: ScenarioRuntimeExecutionStatus.blocked,
                  effect: const ScenarioRuntimeEffect.none(),
                  scenarioId: scenario.id,
                  sourceNodeId: sourceId,
                  stopNodeId: node.id,
                  message: 'Action runScript sans scriptId dans "${node.id}".',
                );
              }
              final started = context.runScript(
                scriptId,
                startNode: _readStartNodeFromPayload(node),
                runtimeSourceId: _runtimeSourceId(
                  scenarioId: scenario.id,
                  sourceNodeId: sourceId,
                  nodeId: node.id,
                ),
              );
              return ScenarioRuntimeExecutionResult(
                status: started
                    ? ScenarioRuntimeExecutionStatus.executedEffect
                    : ScenarioRuntimeExecutionStatus.blocked,
                effect: ScenarioRuntimeEffect(
                  type: ScenarioRuntimeEffectType.script,
                  scriptId: scriptId,
                ),
                scenarioId: scenario.id,
                sourceNodeId: sourceId,
                stopNodeId: node.id,
                message: started
                    ? 'Script "$scriptId" lancé.'
                    : 'Impossible de lancer le script "$scriptId".',
              );

            case kScenarioActionOpenDialogue:
              final dialogueId = node.binding.dialogueId?.trim() ?? '';
              if (dialogueId.isEmpty) {
                return ScenarioRuntimeExecutionResult(
                  status: ScenarioRuntimeExecutionStatus.blocked,
                  effect: const ScenarioRuntimeEffect.none(),
                  scenarioId: scenario.id,
                  sourceNodeId: sourceId,
                  stopNodeId: node.id,
                  message:
                      'Action openDialogue sans dialogueId dans "${node.id}".',
                );
              }
              final started = context.openDialogue(
                dialogueId,
                startNode: _readStartNodeFromPayload(node),
                runtimeSourceId: _runtimeSourceId(
                  scenarioId: scenario.id,
                  sourceNodeId: sourceId,
                  nodeId: node.id,
                ),
              );
              return ScenarioRuntimeExecutionResult(
                status: started
                    ? ScenarioRuntimeExecutionStatus.executedEffect
                    : ScenarioRuntimeExecutionStatus.blocked,
                effect: ScenarioRuntimeEffect(
                  type: ScenarioRuntimeEffectType.dialogue,
                  dialogueId: dialogueId,
                ),
                scenarioId: scenario.id,
                sourceNodeId: sourceId,
                stopNodeId: node.id,
                message: started
                    ? 'Dialogue "$dialogueId" ouvert.'
                    : 'Impossible d’ouvrir le dialogue "$dialogueId".',
              );

            case kScenarioActionShowMessage:
              final text = node.payload.message?.trim() ?? '';
              if (text.isEmpty) {
                return ScenarioRuntimeExecutionResult(
                  status: ScenarioRuntimeExecutionStatus.blocked,
                  effect: const ScenarioRuntimeEffect.none(),
                  scenarioId: scenario.id,
                  sourceNodeId: sourceId,
                  stopNodeId: node.id,
                  message: 'Action showMessage sans message dans "${node.id}".',
                );
              }
              context.showMessage(text);
              return ScenarioRuntimeExecutionResult(
                status: ScenarioRuntimeExecutionStatus.executedEffect,
                effect: ScenarioRuntimeEffect(
                  type: ScenarioRuntimeEffectType.message,
                  message: text,
                ),
                scenarioId: scenario.id,
                sourceNodeId: sourceId,
                stopNodeId: node.id,
                message: 'Message affiché.',
              );

            case kScenarioActionSetFlag:
              final flagName = node.binding.flagName?.trim() ?? '';
              if (flagName.isEmpty) {
                return ScenarioRuntimeExecutionResult(
                  status: ScenarioRuntimeExecutionStatus.blocked,
                  effect: const ScenarioRuntimeEffect.none(),
                  scenarioId: scenario.id,
                  sourceNodeId: sourceId,
                  stopNodeId: node.id,
                  message: 'Action setFlag sans flagName dans "${node.id}".',
                );
              }
              final nextState = storyFlags.set(context.gameState, flagName);
              context.gameState = nextState;
              context.onGameStateUpdated(nextState);
              final nextAfterSet = _pickLinearNextNodeId(
                nodeId: node.id,
                edges: scenario.edges,
              );
              if (nextAfterSet == null) {
                return ScenarioRuntimeExecutionResult(
                  status: ScenarioRuntimeExecutionStatus.reachedEnd,
                  effect: const ScenarioRuntimeEffect.none(),
                  scenarioId: scenario.id,
                  sourceNodeId: sourceId,
                  stopNodeId: node.id,
                  message: 'Flag "$flagName" activé. Fin du flow.',
                );
              }
              currentNodeId = nextAfterSet;

            case kScenarioActionClearFlag:
              final flagName = node.binding.flagName?.trim() ?? '';
              if (flagName.isEmpty) {
                return ScenarioRuntimeExecutionResult(
                  status: ScenarioRuntimeExecutionStatus.blocked,
                  effect: const ScenarioRuntimeEffect.none(),
                  scenarioId: scenario.id,
                  sourceNodeId: sourceId,
                  stopNodeId: node.id,
                  message: 'Action clearFlag sans flagName dans "${node.id}".',
                );
              }
              final nextState = storyFlags.clear(context.gameState, flagName);
              context.gameState = nextState;
              context.onGameStateUpdated(nextState);
              final nextAfterClear = _pickLinearNextNodeId(
                nodeId: node.id,
                edges: scenario.edges,
              );
              if (nextAfterClear == null) {
                return ScenarioRuntimeExecutionResult(
                  status: ScenarioRuntimeExecutionStatus.reachedEnd,
                  effect: const ScenarioRuntimeEffect.none(),
                  scenarioId: scenario.id,
                  sourceNodeId: sourceId,
                  stopNodeId: node.id,
                  message: 'Flag "$flagName" désactivé. Fin du flow.',
                );
              }
              currentNodeId = nextAfterClear;

            case kScenarioActionEmitOutcome:
              final outcomeId = node.binding.outcomeId?.trim() ?? '';
              if (outcomeId.isEmpty) {
                return ScenarioRuntimeExecutionResult(
                  status: ScenarioRuntimeExecutionStatus.blocked,
                  effect: const ScenarioRuntimeEffect.none(),
                  scenarioId: scenario.id,
                  sourceNodeId: sourceId,
                  stopNodeId: node.id,
                  message:
                      'Action emitOutcome sans outcomeId dans "${node.id}".',
                );
              }

              // 1) Persistance immédiate de l'outcome sous forme de flag.
              final nextState = storyFlags.set(
                  context.gameState, scenarioOutcomeFlagName(outcomeId));
              context.gameState = nextState;
              context.onGameStateUpdated(nextState);

              // 2) Tentative de pont vers la couche globale:
              // outcome local -> sourceOutcome global.
              final outcomeDispatch = _dispatchInternal(
                scenarios: scenarios,
                sourceEvent: ScenarioRuntimeSourceEvent.outcomeReceived(
                  outcomeId: outcomeId,
                ),
                context: context,
                depth: depth + 1,
              );
              if (outcomeDispatch.handled) {
                return ScenarioRuntimeExecutionResult(
                  status: outcomeDispatch.status,
                  effect: outcomeDispatch.effect,
                  scenarioId: outcomeDispatch.scenarioId ?? scenario.id,
                  sourceNodeId: outcomeDispatch.sourceNodeId ?? sourceId,
                  stopNodeId: outcomeDispatch.stopNodeId,
                  emittedOutcomeId: outcomeId,
                  message:
                      'Outcome "$outcomeId" émis. ${outcomeDispatch.message}',
                );
              }

              // 3) Si aucun scénario global ne consomme l'outcome, on continue
              // localement de manière linéaire.
              final nextAfterOutcome = _pickLinearNextNodeId(
                nodeId: node.id,
                edges: scenario.edges,
              );
              if (nextAfterOutcome == null) {
                return ScenarioRuntimeExecutionResult(
                  status: ScenarioRuntimeExecutionStatus.reachedEnd,
                  effect: const ScenarioRuntimeEffect.none(),
                  scenarioId: scenario.id,
                  sourceNodeId: sourceId,
                  stopNodeId: node.id,
                  emittedOutcomeId: outcomeId,
                  message:
                      'Outcome "$outcomeId" émis. Fin du flow local (aucune transition globale).',
                );
              }
              currentNodeId = nextAfterOutcome;

            case kScenarioActionMoveCharacter:
              final entityId = node.binding.entityId?.trim() ?? '';
              final targetKind =
                  node.payload.params['targetKind']?.trim() ?? '';
              final targetId = node.payload.params['targetId']?.trim() ?? '';
              final waitForCompletion =
                  (node.payload.params['waitForCompletion'] ?? 'true')
                          .toLowerCase() ==
                      'true';
              if (entityId.isEmpty || targetKind.isEmpty || targetId.isEmpty) {
                return ScenarioRuntimeExecutionResult(
                  status: ScenarioRuntimeExecutionStatus.blocked,
                  effect: const ScenarioRuntimeEffect.none(),
                  scenarioId: scenario.id,
                  sourceNodeId: sourceId,
                  stopNodeId: node.id,
                  message:
                      'Action moveCharacter invalide dans "${node.id}" (entity/target manquant).',
                );
              }
              final started = context.moveCharacter(
                entityId: entityId,
                targetKind: targetKind,
                targetId: targetId,
                waitForCompletion: waitForCompletion,
                runtimeSourceId: _runtimeSourceId(
                  scenarioId: scenario.id,
                  sourceNodeId: sourceId,
                  nodeId: node.id,
                ),
              );
              if (!started) {
                return ScenarioRuntimeExecutionResult(
                  status: ScenarioRuntimeExecutionStatus.blocked,
                  effect: const ScenarioRuntimeEffect.none(),
                  scenarioId: scenario.id,
                  sourceNodeId: sourceId,
                  stopNodeId: node.id,
                  message:
                      'Action moveCharacter impossible pour "$entityId" vers "$targetKind:$targetId".',
                );
              }
              final nextAfterMove = _pickLinearNextNodeId(
                nodeId: node.id,
                edges: scenario.edges,
              );
              if (nextAfterMove == null) {
                return ScenarioRuntimeExecutionResult(
                  status: ScenarioRuntimeExecutionStatus.reachedEnd,
                  effect: const ScenarioRuntimeEffect.none(),
                  scenarioId: scenario.id,
                  sourceNodeId: sourceId,
                  stopNodeId: node.id,
                  message: 'Déplacement lancé. Fin du flow.',
                );
              }
              currentNodeId = nextAfterMove;

            case kScenarioActionFollowCharacter:
              final leaderId = node.payload.params['leaderId']?.trim() ?? '';
              if (leaderId.isEmpty) {
                return ScenarioRuntimeExecutionResult(
                  status: ScenarioRuntimeExecutionStatus.blocked,
                  effect: const ScenarioRuntimeEffect.none(),
                  scenarioId: scenario.id,
                  sourceNodeId: sourceId,
                  stopNodeId: node.id,
                  message:
                      'Action followCharacter invalide dans "${node.id}" (leaderId manquant).',
                );
              }
              final followed = context.followCharacter(
                leaderEntityId: leaderId,
              );
              if (!followed) {
                return ScenarioRuntimeExecutionResult(
                  status: ScenarioRuntimeExecutionStatus.blocked,
                  effect: const ScenarioRuntimeEffect.none(),
                  scenarioId: scenario.id,
                  sourceNodeId: sourceId,
                  stopNodeId: node.id,
                  message:
                      'Action followCharacter impossible pour leader "$leaderId".',
                );
              }
              final nextAfterFollow = _pickLinearNextNodeId(
                nodeId: node.id,
                edges: scenario.edges,
              );
              if (nextAfterFollow == null) {
                return ScenarioRuntimeExecutionResult(
                  status: ScenarioRuntimeExecutionStatus.reachedEnd,
                  effect: const ScenarioRuntimeEffect.none(),
                  scenarioId: scenario.id,
                  sourceNodeId: sourceId,
                  stopNodeId: node.id,
                  message: 'FollowCharacter exécuté. Fin du flow.',
                );
              }
              currentNodeId = nextAfterFollow;

            case kScenarioActionFaceCharacter:
              final entityId = node.binding.entityId?.trim() ?? '';
              final direction = node.payload.params['direction']?.trim() ?? '';
              if (entityId.isEmpty || direction.isEmpty) {
                return ScenarioRuntimeExecutionResult(
                  status: ScenarioRuntimeExecutionStatus.blocked,
                  effect: const ScenarioRuntimeEffect.none(),
                  scenarioId: scenario.id,
                  sourceNodeId: sourceId,
                  stopNodeId: node.id,
                  message:
                      'Action faceCharacter invalide dans "${node.id}" (entityId/direction manquant).',
                );
              }
              final faced = context.faceCharacter(
                entityId: entityId,
                direction: direction,
              );
              if (!faced) {
                return ScenarioRuntimeExecutionResult(
                  status: ScenarioRuntimeExecutionStatus.blocked,
                  effect: const ScenarioRuntimeEffect.none(),
                  scenarioId: scenario.id,
                  sourceNodeId: sourceId,
                  stopNodeId: node.id,
                  message:
                      'Action faceCharacter impossible pour "$entityId" vers "$direction".',
                );
              }
              final nextAfterFace = _pickLinearNextNodeId(
                nodeId: node.id,
                edges: scenario.edges,
              );
              if (nextAfterFace == null) {
                return ScenarioRuntimeExecutionResult(
                  status: ScenarioRuntimeExecutionStatus.reachedEnd,
                  effect: const ScenarioRuntimeEffect.none(),
                  scenarioId: scenario.id,
                  sourceNodeId: sourceId,
                  stopNodeId: node.id,
                  message: 'FaceCharacter exécuté. Fin du flow.',
                );
              }
              currentNodeId = nextAfterFace;

            case kScenarioActionTransitionMap:
              final mapId = node.binding.mapId?.trim() ?? '';
              final warpId = node.binding.warpId?.trim() ?? '';
              if (mapId.isEmpty || warpId.isEmpty) {
                return ScenarioRuntimeExecutionResult(
                  status: ScenarioRuntimeExecutionStatus.blocked,
                  effect: const ScenarioRuntimeEffect.none(),
                  scenarioId: scenario.id,
                  sourceNodeId: sourceId,
                  stopNodeId: node.id,
                  message:
                      'Action transitionMap invalide dans "${node.id}" (mapId/warpId manquant).',
                );
              }
              final transitioned = context.transitionMap(
                mapId: mapId,
                warpId: warpId,
              );
              if (!transitioned) {
                return ScenarioRuntimeExecutionResult(
                  status: ScenarioRuntimeExecutionStatus.blocked,
                  effect: const ScenarioRuntimeEffect.none(),
                  scenarioId: scenario.id,
                  sourceNodeId: sourceId,
                  stopNodeId: node.id,
                  message:
                      'Action transitionMap impossible vers "$mapId" (warp "$warpId").',
                );
              }
              final nextAfterTransition = _pickLinearNextNodeId(
                nodeId: node.id,
                edges: scenario.edges,
              );
              if (nextAfterTransition == null) {
                return ScenarioRuntimeExecutionResult(
                  status: ScenarioRuntimeExecutionStatus.reachedEnd,
                  effect: const ScenarioRuntimeEffect.none(),
                  scenarioId: scenario.id,
                  sourceNodeId: sourceId,
                  stopNodeId: node.id,
                  message: 'TransitionMap exécuté. Fin du flow.',
                );
              }
              currentNodeId = nextAfterTransition;

            case kScenarioActionFlowMerge:
              final nextAfterMerge = _pickLinearNextNodeId(
                nodeId: node.id,
                edges: scenario.edges,
              );
              if (nextAfterMerge == null) {
                return ScenarioRuntimeExecutionResult(
                  status: ScenarioRuntimeExecutionStatus.reachedEnd,
                  effect: const ScenarioRuntimeEffect.none(),
                  scenarioId: scenario.id,
                  sourceNodeId: sourceId,
                  stopNodeId: node.id,
                  message: 'Fusion de branches (aucune suite).',
                );
              }
              currentNodeId = nextAfterMerge;

            case kScenarioActionAuthoringPlaceholder:
              final detail = node.payload.message?.trim();
              final nextAfterPlaceholder = _pickLinearNextNodeId(
                nodeId: node.id,
                edges: scenario.edges,
              );
              if (nextAfterPlaceholder == null) {
                return ScenarioRuntimeExecutionResult(
                  status: ScenarioRuntimeExecutionStatus.reachedEnd,
                  effect: const ScenarioRuntimeEffect.none(),
                  scenarioId: scenario.id,
                  sourceNodeId: sourceId,
                  stopNodeId: node.id,
                  message:
                      'Placeholder authoring "${node.id}"${detail != null && detail.isNotEmpty ? ': $detail' : ''} — fin du flow.',
                );
              }
              currentNodeId = nextAfterPlaceholder;

            default:
              return ScenarioRuntimeExecutionResult(
                status: ScenarioRuntimeExecutionStatus.blocked,
                effect: const ScenarioRuntimeEffect.none(),
                scenarioId: scenario.id,
                sourceNodeId: sourceId,
                stopNodeId: node.id,
                message:
                    'Action "$actionKind" non supportée par l’exécuteur MVP.',
              );
          }

        case ScenarioNodeType.condition:
          final condition = node.payload.condition;
          if (condition == null) {
            return ScenarioRuntimeExecutionResult(
              status: ScenarioRuntimeExecutionStatus.blocked,
              effect: const ScenarioRuntimeEffect.none(),
              scenarioId: scenario.id,
              sourceNodeId: sourceId,
              stopNodeId: node.id,
              message: 'Node Condition "${node.id}" sans condition.',
            );
          }
          final value =
              conditionEvaluator.evaluate(condition, context.gameState);
          final nextNodeId = _pickConditionNextNodeId(
            nodeId: node.id,
            conditionValue: value,
            edges: scenario.edges,
          );
          if (nextNodeId == null || nextNodeId.isEmpty) {
            return ScenarioRuntimeExecutionResult(
              status: ScenarioRuntimeExecutionStatus.blocked,
              effect: const ScenarioRuntimeEffect.none(),
              scenarioId: scenario.id,
              sourceNodeId: sourceId,
              stopNodeId: node.id,
              message:
                  'Condition "${node.id}" sans branche ${value ? 'true' : 'false'} résolue.',
            );
          }
          currentNodeId = nextNodeId;

        case ScenarioNodeType.choice:
          // Les choix joueur demandent un runtime dialogue/choix dédié.
          // On bloque explicitement pour rester honnête dans ce MVP.
          return ScenarioRuntimeExecutionResult(
            status: ScenarioRuntimeExecutionStatus.blocked,
            effect: const ScenarioRuntimeEffect.none(),
            scenarioId: scenario.id,
            sourceNodeId: sourceId,
            stopNodeId: node.id,
            message:
                'Node Choice "${node.id}" non supporté par l’exécuteur MVP.',
          );

        case ScenarioNodeType.reference:
          // Les references non-source restent de l'authoring/liaison.
          // On ne les exécute pas automatiquement pour éviter un faux positif
          // runtime côté gameplay.
          return ScenarioRuntimeExecutionResult(
            status: ScenarioRuntimeExecutionStatus.blocked,
            effect: const ScenarioRuntimeEffect.none(),
            scenarioId: scenario.id,
            sourceNodeId: sourceId,
            stopNodeId: node.id,
            message:
                'Node Reference "${node.id}" hors mode source (authoring-only).',
          );
      }
    }

    return ScenarioRuntimeExecutionResult(
      status: ScenarioRuntimeExecutionStatus.blocked,
      effect: const ScenarioRuntimeEffect.none(),
      scenarioId: scenario.id,
      sourceNodeId: sourceId,
      stopNodeId: currentNodeId,
      message:
          'Arrêt de sécurité: plus de $maxTraversalSteps étapes dans le flow.',
    );
  }

  ScenarioNode? _findMatchingSourceNode({
    required ScenarioAsset scenario,
    required ScenarioRuntimeSourceEvent sourceEvent,
  }) {
    for (final node in scenario.nodes) {
      // Dans ce MVP, seules les references "source*" sont consommées.
      if (node.type != ScenarioNodeType.reference) {
        continue;
      }
      final actionKind = node.payload.actionKind?.trim() ?? '';
      switch (sourceEvent.type) {
        case ScenarioRuntimeSourceType.mapEnter:
          if (actionKind != kScenarioSourceMapEnter) {
            continue;
          }
          if (!_matchesOptionalMap(node.binding.mapId, sourceEvent.mapId)) {
            continue;
          }
          return node;
        case ScenarioRuntimeSourceType.triggerEnter:
          if (actionKind != kScenarioSourceTriggerEnter) {
            continue;
          }
          if (!_matchesOptionalMap(node.binding.mapId, sourceEvent.mapId)) {
            continue;
          }
          final triggerId = node.binding.triggerId?.trim() ?? '';
          if (triggerId.isEmpty || triggerId != (sourceEvent.triggerId ?? '')) {
            continue;
          }
          return node;
        case ScenarioRuntimeSourceType.entityInteract:
          if (actionKind != kScenarioSourceEntityInteract) {
            continue;
          }
          if (!_matchesOptionalMap(node.binding.mapId, sourceEvent.mapId)) {
            continue;
          }
          final entityId = node.binding.entityId?.trim() ?? '';
          if (entityId.isEmpty || entityId != (sourceEvent.entityId ?? '')) {
            continue;
          }
          return node;
        case ScenarioRuntimeSourceType.outcomeReceived:
          if (actionKind != kScenarioSourceOutcome) {
            continue;
          }
          final outcomeId = node.binding.outcomeId?.trim() ?? '';
          if (outcomeId.isEmpty || outcomeId != (sourceEvent.outcomeId ?? '')) {
            continue;
          }
          return node;
      }
    }
    return null;
  }

  bool _matchesOptionalMap(String? bindingMapId, String eventMapId) {
    final normalizedBinding = bindingMapId?.trim() ?? '';
    if (normalizedBinding.isEmpty) {
      // Tolérance MVP: mapId vide = wildcard.
      return true;
    }
    return normalizedBinding == eventMapId;
  }

  String? _pickLinearNextNodeId({
    required String nodeId,
    required List<ScenarioEdge> edges,
  }) {
    final outgoing = _sortedOutgoing(nodeId: nodeId, edges: edges);
    for (final edge in outgoing) {
      if (edge.kind == ScenarioEdgeKind.next) {
        return edge.toNodeId;
      }
    }
    return outgoing.isEmpty ? null : outgoing.first.toNodeId;
  }

  String? _pickConditionNextNodeId({
    required String nodeId,
    required bool conditionValue,
    required List<ScenarioEdge> edges,
  }) {
    final outgoing = _sortedOutgoing(nodeId: nodeId, edges: edges);
    if (outgoing.isEmpty) {
      return null;
    }
    if (conditionValue) {
      for (final edge in outgoing) {
        if (edge.kind == ScenarioEdgeKind.trueBranch) {
          return edge.toNodeId;
        }
      }
      for (final edge in outgoing) {
        final label = edge.label.trim().toLowerCase();
        if (label == 'true' ||
            label == 'vrai' ||
            label == 'yes' ||
            label == 'oui') {
          return edge.toNodeId;
        }
      }
      // fallback déterministe
      return outgoing.first.toNodeId;
    }

    for (final edge in outgoing) {
      if (edge.kind == ScenarioEdgeKind.falseBranch) {
        return edge.toNodeId;
      }
    }
    for (final edge in outgoing) {
      final label = edge.label.trim().toLowerCase();
      if (label == 'false' ||
          label == 'faux' ||
          label == 'no' ||
          label == 'non') {
        return edge.toNodeId;
      }
    }
    if (outgoing.length >= 2) {
      return outgoing[1].toNodeId;
    }
    return outgoing.first.toNodeId;
  }

  List<ScenarioEdge> _sortedOutgoing({
    required String nodeId,
    required List<ScenarioEdge> edges,
  }) {
    final outgoing =
        edges.where((edge) => edge.fromNodeId == nodeId).toList(growable: true);
    outgoing.sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      if (byOrder != 0) return byOrder;
      return a.id.compareTo(b.id);
    });
    return outgoing;
  }

  String? _readStartNodeFromPayload(ScenarioNode node) {
    final startNode = node.payload.params['startNode']?.trim();
    if (startNode == null || startNode.isEmpty) {
      return null;
    }
    return startNode;
  }

  String _runtimeSourceId({
    required String scenarioId,
    required String sourceNodeId,
    required String nodeId,
  }) {
    return 'scenario:$scenarioId:$sourceNodeId:$nodeId';
  }

  bool _rectContains(MapRect rect, GridPos pos) {
    return pos.x >= rect.pos.x &&
        pos.y >= rect.pos.y &&
        pos.x < rect.pos.x + rect.size.width &&
        pos.y < rect.pos.y + rect.size.height;
  }
}
