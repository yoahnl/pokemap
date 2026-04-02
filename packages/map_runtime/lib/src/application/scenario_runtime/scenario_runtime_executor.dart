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

/// Action kinds réellement supportés par l'exécuteur runtime MVP.
const String kScenarioActionRunScript = 'runScript';
const String kScenarioActionOpenDialogue = 'openDialogue';
const String kScenarioActionShowMessage = 'showMessage';
const String kScenarioActionSetFlag = 'setFlag';
const String kScenarioActionClearFlag = 'clearFlag';

/// Bridge d'exécution runtime du Scenario Graph (MVP).
///
/// Ce composant répond à une contrainte produit claire :
/// "on a un graphe authoré, il faut déclencher des effets réels en jeu".
///
/// Portée volontairement limitée du MVP :
/// - sources supportées: map enter / trigger enter / entity interact
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
    for (final scenario in scenarios) {
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
      );
    }
    return const ScenarioRuntimeExecutionResult(
      status: ScenarioRuntimeExecutionStatus.noMatchingSource,
      effect: ScenarioRuntimeEffect.none(),
      message: 'Aucune source scénario ne correspond à cet événement runtime.',
    );
  }

  ScenarioRuntimeExecutionResult _executeScenarioFromSource({
    required ScenarioAsset scenario,
    required ScenarioNode sourceNode,
    required ScenarioRuntimeSourceEvent sourceEvent,
    required ScenarioRuntimeExecutionContext context,
  }) {
    final nodesById = <String, ScenarioNode>{
      for (final node in scenario.nodes) node.id: node,
    };
    final sourceId = sourceNode.id.trim();

    // Étape 1: passer de la source vers le premier node "exécutable".
    var currentNodeId = _pickLinearNextNodeId(
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
