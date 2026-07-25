import '../models/project_manifest.dart';
import '../models/scene_asset.dart';
import '../models/scene_consequence.dart';
import '../models/map_data.dart';
import '../read_models/linked_asset_public_contracts.dart';

enum SceneDiagnosticSeverity {
  error,
  warning,
  info,
}

enum SceneDiagnosticCode {
  missingStartNode,
  startNodeNotFound,
  startNodeNotStartKind,
  missingEndNode,
  unknownFromNode,
  unknownToNode,
  layoutUnknownNode,
  layoutMissingNode,
  declaredOutcomeUnused,
  endOutcomeUndeclared,
  endOutcomeMissing,
  conditionSourceMissing,
  conditionSourceUnknown,
  conditionOperatorMissing,
  conditionOperatorUnsupported,
  conditionValueMissing,
  conditionSourceRequiresPicker,
  conditionUsesFutureSource,
  conditionUsesRawTechnicalId,
  conditionSourceMigratesToFactRegistry,
  conditionFactRefUnknown,
  conditionWorldRuleRefUnknown,
  consequenceUnknownFact,
  consequenceUnknownEvent,
  consequenceUnknownStoryStep,
  consequenceAmbiguousStoryStep,
  consequenceUnknownStarterOption,
  consequenceUnknownBadge,
  consequenceMissingTarget,
  consequenceInvalidValue,
  consequenceLegacyPokemonHpFallback,
  consequenceWouldApplyWorldRuleDirectly,
  actionPayloadLegacyUnsupported,
  consequenceRuntimeUnsupported,
  edgeFromPortUnsupported,
  edgeKindUnsupportedForPort,
  duplicateOutgoingPortEdge,
  requiredOutputPortMissing,
  unreachableNode,
  unreachableEndNode,
  cycleUnsupported,
  actionNodeUnsupported,
  branchByOutcomeUnsupported,
  branchSourceMissing,
  branchSourceUnknown,
  branchSourceHasNoOutcomes,
  dialogueRefUnknown,
  dialogueExpectedOutcomeUnknown,
  battleTrainerRefUnknown,
  battleTemplateRefMissing,
  cinematicRefUnknown,
  emptyGraph,
  legacyScenarioLeak,
}

enum SceneDiagnosticTarget {
  scene,
  graph,
  node,
  edge,
  layout,
  outcome,
}

final class SceneDiagnostic {
  const SceneDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    required this.sceneId,
    required this.target,
    this.nodeId,
    this.edgeId,
    this.outcomeId,
    this.suggestedFixLabel,
  });

  final SceneDiagnosticCode code;
  final SceneDiagnosticSeverity severity;
  final String message;
  final String sceneId;
  final SceneDiagnosticTarget target;
  final String? nodeId;
  final String? edgeId;
  final String? outcomeId;
  final String? suggestedFixLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneDiagnostic &&
          other.code == code &&
          other.severity == severity &&
          other.message == message &&
          other.sceneId == sceneId &&
          other.target == target &&
          other.nodeId == nodeId &&
          other.edgeId == edgeId &&
          other.outcomeId == outcomeId &&
          other.suggestedFixLabel == suggestedFixLabel;

  @override
  int get hashCode => Object.hash(
        code,
        severity,
        message,
        sceneId,
        target,
        nodeId,
        edgeId,
        outcomeId,
        suggestedFixLabel,
      );
}

final class SceneDiagnosticsReport {
  SceneDiagnosticsReport({
    required List<SceneDiagnostic> diagnostics,
  }) : _diagnostics = List<SceneDiagnostic>.unmodifiable(diagnostics);

  final List<SceneDiagnostic> _diagnostics;

  List<SceneDiagnostic> get diagnostics => _diagnostics;

  int get count => _diagnostics.length;

  int get errorCount => _diagnostics
      .where(
          (diagnostic) => diagnostic.severity == SceneDiagnosticSeverity.error)
      .length;

  int get warningCount => _diagnostics
      .where(
        (diagnostic) => diagnostic.severity == SceneDiagnosticSeverity.warning,
      )
      .length;

  int get infoCount => _diagnostics
      .where(
          (diagnostic) => diagnostic.severity == SceneDiagnosticSeverity.info)
      .length;

  bool get hasDiagnostics => _diagnostics.isNotEmpty;

  bool get hasErrors => errorCount > 0;

  List<SceneDiagnostic> byCode(SceneDiagnosticCode code) {
    return List<SceneDiagnostic>.unmodifiable(
      _diagnostics.where((diagnostic) => diagnostic.code == code),
    );
  }
}

SceneDiagnosticsReport diagnoseScene(SceneAsset scene) {
  final diagnostics = <SceneDiagnostic>[];
  final nodeById = {
    for (final node in scene.graph.nodes) node.id: node,
  };
  final nodeIds = nodeById.keys.toSet();

  if (scene.graph.nodes.isEmpty) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.emptyGraph,
        severity: SceneDiagnosticSeverity.error,
        message: 'La scène ne contient aucun nœud.',
        sceneId: scene.id,
        target: SceneDiagnosticTarget.graph,
        suggestedFixLabel: 'Créer un nœud de début et un nœud de fin.',
      ),
    );
  }

  if (scene.graph.startNodeId.trim().isEmpty) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.missingStartNode,
        severity: SceneDiagnosticSeverity.error,
        message: 'La scène n’a pas de nœud de départ.',
        sceneId: scene.id,
        target: SceneDiagnosticTarget.graph,
        suggestedFixLabel: 'Définir un nœud de départ.',
      ),
    );
  } else {
    final startNode = nodeById[scene.graph.startNodeId];
    if (startNode == null) {
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.startNodeNotFound,
          severity: SceneDiagnosticSeverity.error,
          message: 'Le nœud de départ est introuvable.',
          sceneId: scene.id,
          nodeId: scene.graph.startNodeId,
          target: SceneDiagnosticTarget.node,
          suggestedFixLabel: 'Choisir un nœud de départ existant.',
        ),
      );
    } else if (startNode.kind != SceneNodeKind.start) {
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.startNodeNotStartKind,
          severity: SceneDiagnosticSeverity.error,
          message: 'Le nœud de départ doit être de type début.',
          sceneId: scene.id,
          nodeId: startNode.id,
          target: SceneDiagnosticTarget.node,
          suggestedFixLabel: 'Utiliser un nœud de type début.',
        ),
      );
    }
  }

  if (!scene.graph.nodes.any((node) => node.kind == SceneNodeKind.end)) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.missingEndNode,
        severity: SceneDiagnosticSeverity.error,
        message: 'La scène n’a pas de fin.',
        sceneId: scene.id,
        target: SceneDiagnosticTarget.graph,
        suggestedFixLabel: 'Ajouter un nœud de fin.',
      ),
    );
  }

  if (scene.graph.nodes.length == 1 && scene.graph.edges.isEmpty) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.emptyGraph,
        severity: SceneDiagnosticSeverity.info,
        message: 'La scène contient seulement un nœud isolé.',
        sceneId: scene.id,
        nodeId: scene.graph.nodes.single.id,
        target: SceneDiagnosticTarget.graph,
        suggestedFixLabel: 'Ajouter au moins un chemin vers une fin.',
      ),
    );
  }

  for (final edge in scene.graph.edges) {
    if (!nodeIds.contains(edge.fromNodeId)) {
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.unknownFromNode,
          severity: SceneDiagnosticSeverity.error,
          message: 'Un lien part d’un nœud inconnu.',
          sceneId: scene.id,
          edgeId: edge.id,
          nodeId: edge.fromNodeId,
          target: SceneDiagnosticTarget.edge,
          suggestedFixLabel: 'Reconnecter le lien depuis un nœud existant.',
        ),
      );
    }
    if (!nodeIds.contains(edge.toNodeId)) {
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.unknownToNode,
          severity: SceneDiagnosticSeverity.error,
          message: 'Un lien pointe vers un nœud inconnu.',
          sceneId: scene.id,
          edgeId: edge.id,
          nodeId: edge.toNodeId,
          target: SceneDiagnosticTarget.edge,
          suggestedFixLabel: 'Reconnecter le lien vers un nœud existant.',
        ),
      );
    }
  }

  _diagnosePorts(scene, nodeById, diagnostics);
  _diagnoseReachability(scene, nodeById, diagnostics);
  _diagnoseCycles(scene, nodeById, diagnostics);

  for (final node in scene.graph.nodes) {
    if (node.kind == SceneNodeKind.condition) {
      _diagnoseConditionNode(scene, node, diagnostics);
    } else if (node.kind == SceneNodeKind.action) {
      _diagnoseActionNode(scene, node, diagnostics);
    } else if (node.kind == SceneNodeKind.branchByOutcome) {
      _diagnoseBranchByOutcomeNode(scene, node, nodeById, diagnostics);
    }
  }

  final layoutNodeIds = {
    for (final layout in scene.layout.nodeLayouts) layout.nodeId,
  };
  for (final layoutNodeId in layoutNodeIds) {
    if (!nodeIds.contains(layoutNodeId)) {
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.layoutUnknownNode,
          severity: SceneDiagnosticSeverity.warning,
          message: 'Le layout référence un nœud inconnu.',
          sceneId: scene.id,
          nodeId: layoutNodeId,
          target: SceneDiagnosticTarget.layout,
          suggestedFixLabel: 'Retirer cette position de layout.',
        ),
      );
    }
  }
  for (final node in scene.graph.nodes) {
    if (!layoutNodeIds.contains(node.id)) {
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.layoutMissingNode,
          severity: SceneDiagnosticSeverity.warning,
          message: 'Un nœud n’a pas de position sauvegardée.',
          sceneId: scene.id,
          nodeId: node.id,
          target: SceneDiagnosticTarget.layout,
          suggestedFixLabel: 'Sauvegarder une position de layout.',
        ),
      );
    }
  }

  final declaredOutcomeIds = {
    for (final outcome in scene.declaredOutcomes) outcome.id,
  };
  final emittedSceneOutcomeIds = <String>{};
  for (final node in scene.graph.nodes) {
    final payload = node.payload;
    if (payload is! SceneEndPayload) {
      continue;
    }
    final outcomeId = payload.sceneOutcomeId;
    if (outcomeId == null) {
      if (declaredOutcomeIds.isNotEmpty) {
        diagnostics.add(
          SceneDiagnostic(
            code: SceneDiagnosticCode.endOutcomeMissing,
            severity: SceneDiagnosticSeverity.error,
            message: 'Une fin doit émettre un outcome déclaré.',
            sceneId: scene.id,
            nodeId: node.id,
            target: SceneDiagnosticTarget.outcome,
            suggestedFixLabel: 'Choisir un outcome de scène pour cette fin.',
          ),
        );
      }
      continue;
    }
    emittedSceneOutcomeIds.add(outcomeId);
    if (!declaredOutcomeIds.contains(outcomeId)) {
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.endOutcomeUndeclared,
          severity: SceneDiagnosticSeverity.error,
          message: 'Une fin émet un outcome non déclaré.',
          sceneId: scene.id,
          nodeId: node.id,
          outcomeId: outcomeId,
          target: SceneDiagnosticTarget.outcome,
          suggestedFixLabel: 'Déclarer cet outcome de scène.',
        ),
      );
    }
  }
  for (final outcome in scene.declaredOutcomes) {
    if (!emittedSceneOutcomeIds.contains(outcome.id)) {
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.declaredOutcomeUnused,
          severity: SceneDiagnosticSeverity.warning,
          message: 'Un outcome déclaré n’est émis par aucune fin.',
          sceneId: scene.id,
          outcomeId: outcome.id,
          target: SceneDiagnosticTarget.outcome,
          suggestedFixLabel: 'Utiliser cet outcome dans un nœud de fin.',
        ),
      );
    }
  }

  return SceneDiagnosticsReport(diagnostics: diagnostics);
}

SceneDiagnosticsReport diagnoseSceneAgainstProject(
  SceneAsset scene,
  ProjectManifest project, {
  Map<String, MapData> mapsById = const {},
}) {
  final diagnostics = diagnoseScene(scene).diagnostics.toList(growable: true);
  final contracts = buildLinkedAssetContractsSnapshot(project);
  final dialogueById = <String, DialoguePublicContract>{
    for (final dialogue in contracts.dialogues) dialogue.id: dialogue,
  };
  final trainerIds =
      contracts.battles.map((battle) => battle.trainerId).toSet();
  final cinematicById = {
    for (final cinematic in contracts.cinematics) cinematic.id: cinematic,
  };
  final factIds = project.facts.map((fact) => fact.id).toSet();
  final worldRuleIds = project.worldRules.map((rule) => rule.id).toSet();
  final projectMapIds = project.maps.map((map) => map.id).toSet();
  final starterOptionIds =
      project.newGame.starterOptions.map((option) => option.id).toSet();
  final badgeIds = project.badges.map((badge) => badge.id).toSet();
  final storyStepCounts = <String, int>{};
  for (final storyline in project.storylines) {
    for (final chapter in storyline.chapters) {
      for (final step in chapter.steps) {
        storyStepCounts.update(step.id, (count) => count + 1,
            ifAbsent: () => 1);
      }
    }
  }

  for (final node in scene.graph.nodes) {
    final payload = node.payload;
    switch (payload) {
      case SceneYarnDialoguePayload():
        final dialogue = dialogueById[payload.dialogueId];
        if (dialogue == null) {
          diagnostics.add(
            SceneDiagnostic(
              code: SceneDiagnosticCode.dialogueRefUnknown,
              severity: SceneDiagnosticSeverity.error,
              message: 'Le dialogue Yarn référencé est absent du projet.',
              sceneId: scene.id,
              nodeId: node.id,
              target: SceneDiagnosticTarget.node,
              suggestedFixLabel: 'Choisir un dialogue existant.',
            ),
          );
        } else {
          final declaredOutcomeIds =
              dialogue.declaredOutcomes.map((outcome) => outcome.id).toSet();
          for (final expectedOutcomeId in payload.expectedOutcomes) {
            if (declaredOutcomeIds.contains(expectedOutcomeId)) continue;
            diagnostics.add(
              SceneDiagnostic(
                code: SceneDiagnosticCode.dialogueExpectedOutcomeUnknown,
                severity: SceneDiagnosticSeverity.error,
                message:
                    'La Scene attend un résultat que ce dialogue ne déclare pas.',
                sceneId: scene.id,
                nodeId: node.id,
                outcomeId: expectedOutcomeId,
                target: SceneDiagnosticTarget.outcome,
                suggestedFixLabel:
                    'Choisir un résultat déclaré par le dialogue.',
              ),
            );
          }
        }
      case SceneBattlePayload():
        if (payload.battleKind == 'trainer' &&
            (payload.trainerId == null ||
                !trainerIds.contains(payload.trainerId))) {
          diagnostics.add(
            SceneDiagnostic(
              code: SceneDiagnosticCode.battleTrainerRefUnknown,
              severity: SceneDiagnosticSeverity.error,
              message:
                  'Le combat référence un profil d’adversaire absent du projet.',
              sceneId: scene.id,
              nodeId: node.id,
              target: SceneDiagnosticTarget.node,
              suggestedFixLabel: 'Choisir un adversaire existant.',
            ),
          );
        }
        if (payload.battleKind == 'static' &&
            (payload.battleTemplateId?.trim().isEmpty ?? true)) {
          diagnostics.add(
            SceneDiagnostic(
              code: SceneDiagnosticCode.battleTemplateRefMissing,
              severity: SceneDiagnosticSeverity.error,
              message:
                  'La rencontre statique doit référencer un template de combat.',
              sceneId: scene.id,
              nodeId: node.id,
              target: SceneDiagnosticTarget.node,
              suggestedFixLabel:
                  'Choisir une espèce ou un template de rencontre statique.',
            ),
          );
        }
      case SceneCinematicPayload():
        final cinematic = cinematicById[payload.cinematicId];
        if (cinematic == null) {
          diagnostics.add(
            SceneDiagnostic(
              code: SceneDiagnosticCode.cinematicRefUnknown,
              severity: SceneDiagnosticSeverity.error,
              message:
                  'La cinématique référencée n’existe pas comme CinematicAsset canonique ni bridge public.',
              sceneId: scene.id,
              nodeId: node.id,
              target: SceneDiagnosticTarget.node,
              suggestedFixLabel:
                  'Choisir une CinematicAsset existante ou un bridge explicitement disponible.',
            ),
          );
        } else if (cinematic.sourceKind ==
            CinematicPublicContractSourceKind.scenarioBridge) {
          diagnostics.add(
            SceneDiagnostic(
              code: SceneDiagnosticCode.legacyScenarioLeak,
              severity: SceneDiagnosticSeverity.warning,
              message:
                  'Cette cinématique référence un bridge Scenario legacy, pas une CinematicAsset canonique.',
              sceneId: scene.id,
              nodeId: node.id,
              target: SceneDiagnosticTarget.node,
              suggestedFixLabel:
                  'Préférer une CinematicAsset canonique quand elle existe.',
            ),
          );
        }
      case SceneConditionPayload():
        final source = payload.conditionSource;
        if (source == null) {
          continue;
        }
        if (source.sourceKind == SceneConditionSourceKind.fact &&
            !factIds.contains(source.sourceId)) {
          diagnostics.add(
            SceneDiagnostic(
              code: SceneDiagnosticCode.conditionFactRefUnknown,
              severity: SceneDiagnosticSeverity.error,
              message: 'La condition référence un Fact absent du projet.',
              sceneId: scene.id,
              nodeId: node.id,
              target: SceneDiagnosticTarget.node,
              suggestedFixLabel: 'Choisir un Fact existant dans la registry.',
            ),
          );
        }
        if (source.sourceKind == SceneConditionSourceKind.worldState &&
            !worldRuleIds.contains(source.sourceId)) {
          diagnostics.add(
            SceneDiagnostic(
              code: SceneDiagnosticCode.conditionWorldRuleRefUnknown,
              severity: SceneDiagnosticSeverity.warning,
              message:
                  'La condition référence une World Rule ou un état monde absent.',
              sceneId: scene.id,
              nodeId: node.id,
              target: SceneDiagnosticTarget.node,
              suggestedFixLabel:
                  'Choisir une World Rule existante quand cette source sera active.',
            ),
          );
        }
      case SceneActionPayload():
        _diagnoseActionConsequenceAgainstProject(
          scene,
          node,
          payload,
          factIds: factIds,
          projectMapIds: projectMapIds,
          storyStepCounts: storyStepCounts,
          starterOptionIds: starterOptionIds,
          badgeIds: badgeIds,
          mapsById: mapsById,
          diagnostics: diagnostics,
        );
      case SceneStartPayload():
      case SceneEndPayload():
      case SceneBranchByOutcomePayload():
      case SceneMergePayload():
        break;
    }
  }

  return SceneDiagnosticsReport(diagnostics: diagnostics);
}

void _diagnoseActionNode(
  SceneAsset scene,
  SceneNode node,
  List<SceneDiagnostic> diagnostics,
) {
  final payload = node.payload;
  if (payload is! SceneActionPayload) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.actionPayloadLegacyUnsupported,
        severity: SceneDiagnosticSeverity.error,
        message: 'ActionNode doit avoir un payload action.',
        sceneId: scene.id,
        nodeId: node.id,
        target: SceneDiagnosticTarget.node,
        suggestedFixLabel: 'Reconfigurer le nœud Action.',
      ),
    );
    return;
  }

  if (payload.interactiveCommand != null) {
    return;
  }

  final consequence = payload.consequence;
  if (consequence == null) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.actionPayloadLegacyUnsupported,
        severity: SceneDiagnosticSeverity.warning,
        message:
            'ActionNode utilise encore un actionKind libre legacy non exécutable.',
        sceneId: scene.id,
        nodeId: node.id,
        target: SceneDiagnosticTarget.node,
        suggestedFixLabel: 'Configurer une conséquence typée V0.',
      ),
    );
    return;
  }

  _diagnoseConsequenceShape(scene, node, consequence, diagnostics);
}

void _diagnoseBranchByOutcomeNode(
  SceneAsset scene,
  SceneNode node,
  Map<String, SceneNode> nodeById,
  List<SceneDiagnostic> diagnostics,
) {
  final payload = node.payload as SceneBranchByOutcomePayload;
  final sourceNodeId = payload.sourceNodeId;
  if (sourceNodeId == null) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.branchSourceMissing,
        severity: SceneDiagnosticSeverity.error,
        message: 'La branche doit choisir un nœud producteur d’outcome.',
        sceneId: scene.id,
        nodeId: node.id,
        target: SceneDiagnosticTarget.node,
        suggestedFixLabel: 'Choisir un Dialogue, Combat ou autre décision.',
      ),
    );
    return;
  }
  final sourceNode = nodeById[sourceNodeId];
  if (sourceNode == null) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.branchSourceUnknown,
        severity: SceneDiagnosticSeverity.error,
        message: 'Le nœud producteur d’outcome n’existe plus.',
        sceneId: scene.id,
        nodeId: node.id,
        target: SceneDiagnosticTarget.node,
        suggestedFixLabel: 'Choisir un nœud source existant.',
      ),
    );
    return;
  }
  if (_outcomePortIdsForBranchSource(sourceNode).isEmpty) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.branchSourceHasNoOutcomes,
        severity: SceneDiagnosticSeverity.error,
        message: 'Le nœud choisi ne produit aucun outcome routable.',
        sceneId: scene.id,
        nodeId: node.id,
        target: SceneDiagnosticTarget.node,
        suggestedFixLabel: 'Choisir un Dialogue, Combat ou Condition.',
      ),
    );
  }
}

void _diagnoseConsequenceShape(
  SceneAsset scene,
  SceneNode node,
  SceneConsequence consequence,
  List<SceneDiagnostic> diagnostics,
) {
  switch (consequence) {
    case SceneSetFactConsequence():
      if (consequence.factId.trim().isEmpty) {
        diagnostics.add(
          SceneDiagnostic(
            code: SceneDiagnosticCode.consequenceMissingTarget,
            severity: SceneDiagnosticSeverity.error,
            message: 'La conséquence setFact doit cibler un Fact.',
            sceneId: scene.id,
            nodeId: node.id,
            target: SceneDiagnosticTarget.node,
            suggestedFixLabel: 'Choisir un Fact dans la registry.',
          ),
        );
      }
    case SceneMarkEventConsumedConsequence():
      if (consequence.mapId.trim().isEmpty ||
          consequence.eventId.trim().isEmpty) {
        diagnostics.add(
          SceneDiagnostic(
            code: SceneDiagnosticCode.consequenceMissingTarget,
            severity: SceneDiagnosticSeverity.error,
            message:
                'La conséquence markEventConsumed doit cibler une map et un event.',
            sceneId: scene.id,
            nodeId: node.id,
            target: SceneDiagnosticTarget.node,
            suggestedFixLabel: 'Choisir une map et un event existants.',
          ),
        );
      }
    case SceneCompleteStoryStepConsequence():
      if (consequence.stepId.trim().isEmpty) {
        diagnostics.add(
          SceneDiagnostic(
            code: SceneDiagnosticCode.consequenceMissingTarget,
            severity: SceneDiagnosticSeverity.error,
            message:
                'La conséquence completeStoryStep doit cibler une étape narrative.',
            sceneId: scene.id,
            nodeId: node.id,
            target: SceneDiagnosticTarget.node,
            suggestedFixLabel: 'Choisir une étape narrative existante.',
          ),
        );
      }
    case SceneGiveItemConsequence():
      _diagnoseItemConsequenceShape(
        scene,
        node,
        kind: 'giveItem',
        itemId: consequence.itemId,
        quantity: consequence.quantity,
        diagnostics: diagnostics,
      );
    case SceneTakeItemConsequence():
      _diagnoseItemConsequenceShape(
        scene,
        node,
        kind: 'takeItem',
        itemId: consequence.itemId,
        quantity: consequence.quantity,
        diagnostics: diagnostics,
      );
    case SceneGiveMoneyConsequence():
      if (consequence.amount <= 0) {
        diagnostics.add(
          SceneDiagnostic(
            code: SceneDiagnosticCode.consequenceInvalidValue,
            severity: SceneDiagnosticSeverity.error,
            message: 'La conséquence giveMoney exige un montant positif.',
            sceneId: scene.id,
            nodeId: node.id,
            target: SceneDiagnosticTarget.node,
            suggestedFixLabel: 'Saisir un montant supérieur à zéro.',
          ),
        );
      }
    case SceneGivePokemonConsequence():
      if (consequence.speciesId.trim().isEmpty ||
          consequence.natureId.trim().isEmpty ||
          consequence.abilityId.trim().isEmpty) {
        diagnostics.add(
          SceneDiagnostic(
            code: SceneDiagnosticCode.consequenceMissingTarget,
            severity: SceneDiagnosticSeverity.error,
            message:
                'La conséquence givePokemon doit cibler une espèce valide.',
            sceneId: scene.id,
            nodeId: node.id,
            target: SceneDiagnosticTarget.node,
            suggestedFixLabel: 'Choisir un Pokémon dans le catalogue.',
          ),
        );
      } else if (consequence.level < 1 || consequence.level > 100) {
        diagnostics.add(
          SceneDiagnostic(
            code: SceneDiagnosticCode.consequenceInvalidValue,
            severity: SceneDiagnosticSeverity.error,
            message:
                'La conséquence givePokemon exige un niveau entre 1 et 100.',
            sceneId: scene.id,
            nodeId: node.id,
            target: SceneDiagnosticTarget.node,
            suggestedFixLabel: 'Choisir un niveau entre 1 et 100.',
          ),
        );
      } else if (consequence.currentHp <= 0) {
        diagnostics.add(
          SceneDiagnostic(
            code: SceneDiagnosticCode.consequenceInvalidValue,
            severity: SceneDiagnosticSeverity.error,
            message:
                'La conséquence givePokemon exige des PV courants positifs.',
            sceneId: scene.id,
            nodeId: node.id,
            target: SceneDiagnosticTarget.node,
            suggestedFixLabel: 'Saisir des PV courants supérieurs à zéro.',
          ),
        );
      }
      if (consequence.currentHpIsLegacyFallback) {
        diagnostics.add(
          SceneDiagnostic(
            code: SceneDiagnosticCode.consequenceLegacyPokemonHpFallback,
            severity: SceneDiagnosticSeverity.warning,
            message:
                'Cette ancienne conséquence givePokemon utilise encore le niveau comme PV courants de secours.',
            sceneId: scene.id,
            nodeId: node.id,
            target: SceneDiagnosticTarget.node,
            suggestedFixLabel:
                'Réenregistrer la conséquence avec des PV courants explicites.',
          ),
        );
      }
    case SceneGiveConfiguredStarterConsequence():
      if (consequence.starterOptionId.trim().isEmpty) {
        diagnostics.add(
          SceneDiagnostic(
            code: SceneDiagnosticCode.consequenceMissingTarget,
            severity: SceneDiagnosticSeverity.error,
            message:
                'La conséquence giveConfiguredStarter doit cibler une option Nouveau Jeu.',
            sceneId: scene.id,
            nodeId: node.id,
            target: SceneDiagnosticTarget.node,
            suggestedFixLabel: 'Choisir un starter configuré dans le projet.',
          ),
        );
      }
    case SceneHealPartyConsequence():
    case SceneUnlockFieldAbilityConsequence():
      break;
    case SceneAwardBadgeConsequence():
      if (consequence.badgeId.trim().isEmpty) {
        diagnostics.add(
          SceneDiagnostic(
            code: SceneDiagnosticCode.consequenceMissingTarget,
            severity: SceneDiagnosticSeverity.error,
            message: 'La conséquence awardBadge doit cibler un badge.',
            sceneId: scene.id,
            nodeId: node.id,
            target: SceneDiagnosticTarget.node,
            suggestedFixLabel: 'Choisir un badge du projet.',
          ),
        );
      }
  }
}

void _diagnoseItemConsequenceShape(
  SceneAsset scene,
  SceneNode node, {
  required String kind,
  required String itemId,
  required int quantity,
  required List<SceneDiagnostic> diagnostics,
}) {
  if (itemId.trim().isEmpty) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.consequenceMissingTarget,
        severity: SceneDiagnosticSeverity.error,
        message: 'La conséquence $kind doit cibler un objet.',
        sceneId: scene.id,
        nodeId: node.id,
        target: SceneDiagnosticTarget.node,
        suggestedFixLabel: 'Choisir un objet dans le catalogue.',
      ),
    );
  } else if (quantity <= 0) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.consequenceInvalidValue,
        severity: SceneDiagnosticSeverity.error,
        message: 'La conséquence $kind exige une quantité positive.',
        sceneId: scene.id,
        nodeId: node.id,
        target: SceneDiagnosticTarget.node,
        suggestedFixLabel: 'Saisir une quantité supérieure à zéro.',
      ),
    );
  }
}

void _diagnoseActionConsequenceAgainstProject(
  SceneAsset scene,
  SceneNode node,
  SceneActionPayload payload, {
  required Set<String> factIds,
  required Set<String> projectMapIds,
  required Map<String, int> storyStepCounts,
  required Set<String> starterOptionIds,
  required Set<String> badgeIds,
  required Map<String, MapData> mapsById,
  required List<SceneDiagnostic> diagnostics,
}) {
  final consequence = payload.consequence;
  if (consequence == null) {
    return;
  }

  switch (consequence) {
    case SceneSetFactConsequence():
      if (consequence.factId.trim().isEmpty) {
        return;
      }
      if (!factIds.contains(consequence.factId)) {
        diagnostics.add(
          SceneDiagnostic(
            code: SceneDiagnosticCode.consequenceUnknownFact,
            severity: SceneDiagnosticSeverity.error,
            message: 'La conséquence setFact référence un Fact absent.',
            sceneId: scene.id,
            nodeId: node.id,
            target: SceneDiagnosticTarget.node,
            suggestedFixLabel: 'Choisir un Fact existant dans la registry.',
          ),
        );
      }
    case SceneMarkEventConsumedConsequence():
      if (consequence.mapId.trim().isEmpty ||
          consequence.eventId.trim().isEmpty) {
        return;
      }
      final mapData = mapsById[consequence.mapId];
      if (!projectMapIds.contains(consequence.mapId) && mapData == null) {
        diagnostics.add(
          SceneDiagnostic(
            code: SceneDiagnosticCode.consequenceUnknownEvent,
            severity: SceneDiagnosticSeverity.error,
            message: 'La conséquence markEventConsumed cible une map absente.',
            sceneId: scene.id,
            nodeId: node.id,
            target: SceneDiagnosticTarget.node,
            suggestedFixLabel: 'Choisir une map existante.',
          ),
        );
        return;
      }
      if (mapData == null) {
        return;
      }
      final hasEvent =
          mapData.events.any((event) => event.id == consequence.eventId);
      if (!hasEvent) {
        diagnostics.add(
          SceneDiagnostic(
            code: SceneDiagnosticCode.consequenceUnknownEvent,
            severity: SceneDiagnosticSeverity.error,
            message: 'La conséquence markEventConsumed cible un event absent.',
            sceneId: scene.id,
            nodeId: node.id,
            target: SceneDiagnosticTarget.node,
            suggestedFixLabel: 'Choisir un event existant sur la map.',
          ),
        );
      }
    case SceneCompleteStoryStepConsequence():
      if (consequence.stepId.trim().isEmpty) {
        return;
      }
      final count = storyStepCounts[consequence.stepId] ?? 0;
      if (count == 0) {
        diagnostics.add(
          SceneDiagnostic(
            code: SceneDiagnosticCode.consequenceUnknownStoryStep,
            severity: SceneDiagnosticSeverity.error,
            message:
                'La conséquence completeStoryStep référence une étape absente.',
            sceneId: scene.id,
            nodeId: node.id,
            target: SceneDiagnosticTarget.node,
            suggestedFixLabel: 'Choisir une étape narrative existante.',
          ),
        );
      } else if (count > 1) {
        diagnostics.add(
          SceneDiagnostic(
            code: SceneDiagnosticCode.consequenceAmbiguousStoryStep,
            severity: SceneDiagnosticSeverity.error,
            message:
                'La conséquence completeStoryStep référence un ID dupliqué.',
            sceneId: scene.id,
            nodeId: node.id,
            target: SceneDiagnosticTarget.node,
            suggestedFixLabel: 'Rendre les IDs d’étape uniques dans le projet.',
          ),
        );
      }
    case SceneGiveItemConsequence():
    case SceneTakeItemConsequence():
    case SceneGiveMoneyConsequence():
    case SceneGivePokemonConsequence():
      break;
    case SceneGiveConfiguredStarterConsequence():
      if (consequence.starterOptionId.trim().isEmpty) {
        return;
      }
      if (!starterOptionIds.contains(consequence.starterOptionId)) {
        diagnostics.add(
          SceneDiagnostic(
            code: SceneDiagnosticCode.consequenceUnknownStarterOption,
            severity: SceneDiagnosticSeverity.error,
            message:
                'La conséquence giveConfiguredStarter référence une option Nouveau Jeu absente.',
            sceneId: scene.id,
            nodeId: node.id,
            target: SceneDiagnosticTarget.node,
            suggestedFixLabel: 'Choisir un starter configuré dans le projet.',
          ),
        );
      }
    case SceneHealPartyConsequence():
    case SceneUnlockFieldAbilityConsequence():
      break;
    case SceneAwardBadgeConsequence():
      if (consequence.badgeId.trim().isEmpty) return;
      if (!badgeIds.contains(consequence.badgeId)) {
        diagnostics.add(
          SceneDiagnostic(
            code: SceneDiagnosticCode.consequenceUnknownBadge,
            severity: SceneDiagnosticSeverity.error,
            message: 'La conséquence awardBadge référence un badge absent.',
            sceneId: scene.id,
            nodeId: node.id,
            target: SceneDiagnosticTarget.node,
            suggestedFixLabel: 'Choisir un badge existant dans le projet.',
          ),
        );
      }
  }
}

void _diagnosePorts(
  SceneAsset scene,
  Map<String, SceneNode> nodeById,
  List<SceneDiagnostic> diagnostics,
) {
  final edgeBySourcePort = <String, SceneEdge>{};

  for (final edge in scene.graph.edges) {
    final fromNode = nodeById[edge.fromNodeId];
    if (fromNode == null) {
      continue;
    }
    final portSpecs = _v0OutputPortSpecsForNode(fromNode, nodeById);
    if (portSpecs == null) {
      continue;
    }
    final matchingPort = _findPortSpec(portSpecs, edge.fromPortId);
    if (matchingPort == null) {
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.edgeFromPortUnsupported,
          severity: SceneDiagnosticSeverity.error,
          message: 'Un lien part d’un port non supporté pour ce nœud.',
          sceneId: scene.id,
          nodeId: fromNode.id,
          edgeId: edge.id,
          target: SceneDiagnosticTarget.edge,
          suggestedFixLabel: 'Choisir un port de sortie disponible.',
        ),
      );
      continue;
    }
    if (!matchingPort.edgeKinds.contains(edge.kind)) {
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.edgeKindUnsupportedForPort,
          severity: SceneDiagnosticSeverity.error,
          message: 'Le type de lien ne correspond pas au port source.',
          sceneId: scene.id,
          nodeId: fromNode.id,
          edgeId: edge.id,
          target: SceneDiagnosticTarget.edge,
          suggestedFixLabel: 'Recréer le lien depuis le port source attendu.',
        ),
      );
    }

    final sourcePortKey = '${fromNode.id}|${edge.fromPortId}';
    final previousEdge = edgeBySourcePort[sourcePortKey];
    if (previousEdge == null) {
      edgeBySourcePort[sourcePortKey] = edge;
    } else {
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.duplicateOutgoingPortEdge,
          severity: SceneDiagnosticSeverity.error,
          message: 'Ce port de sortie possède déjà un lien.',
          sceneId: scene.id,
          nodeId: fromNode.id,
          edgeId: edge.id,
          target: SceneDiagnosticTarget.edge,
          suggestedFixLabel:
              'Supprimer un des liens ou utiliser un autre port.',
        ),
      );
    }
  }

  for (final node in scene.graph.nodes) {
    final portSpecs = _v0OutputPortSpecsForNode(node, nodeById);
    if (portSpecs == null) {
      continue;
    }
    for (final port in portSpecs.where((port) => port.required)) {
      final hasPortEdge = scene.graph.edges.any(
        (edge) => edge.fromNodeId == node.id && edge.fromPortId == port.id,
      );
      if (hasPortEdge) {
        continue;
      }
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.requiredOutputPortMissing,
          severity: SceneDiagnosticSeverity.warning,
          message: 'Un port de sortie attendu n’est pas connecté.',
          sceneId: scene.id,
          nodeId: node.id,
          target: SceneDiagnosticTarget.node,
          suggestedFixLabel: 'Connecter le port ${port.id}.',
        ),
      );
    }
  }
}

void _diagnoseReachability(
  SceneAsset scene,
  Map<String, SceneNode> nodeById,
  List<SceneDiagnostic> diagnostics,
) {
  final startNode = nodeById[scene.graph.startNodeId];
  if (startNode == null) {
    return;
  }

  final outgoingByNode = <String, List<SceneEdge>>{};
  for (final edge in scene.graph.edges) {
    outgoingByNode.putIfAbsent(edge.fromNodeId, () => []).add(edge);
  }

  final reachableNodeIds = <String>{};
  final queue = <String>[startNode.id];
  while (queue.isNotEmpty) {
    final nodeId = queue.removeAt(0);
    if (!reachableNodeIds.add(nodeId)) {
      continue;
    }
    for (final edge in outgoingByNode[nodeId] ?? const <SceneEdge>[]) {
      if (nodeById.containsKey(edge.toNodeId)) {
        queue.add(edge.toNodeId);
      }
    }
  }

  for (final node in scene.graph.nodes) {
    if (reachableNodeIds.contains(node.id)) {
      continue;
    }
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.unreachableNode,
        severity: SceneDiagnosticSeverity.warning,
        message: 'Ce nœud n’est pas atteignable depuis le départ.',
        sceneId: scene.id,
        nodeId: node.id,
        target: SceneDiagnosticTarget.node,
        suggestedFixLabel: 'Connecter ce nœud au graphe principal.',
      ),
    );
    if (node.kind == SceneNodeKind.end) {
      diagnostics.add(
        SceneDiagnostic(
          code: SceneDiagnosticCode.unreachableEndNode,
          severity: SceneDiagnosticSeverity.warning,
          message: 'Cette fin de scène n’est pas atteignable.',
          sceneId: scene.id,
          nodeId: node.id,
          target: SceneDiagnosticTarget.node,
          suggestedFixLabel: 'Créer un chemin vers cette fin ou la supprimer.',
        ),
      );
    }
  }

  final hasReachableEnd = scene.graph.nodes.any(
    (node) =>
        node.kind == SceneNodeKind.end && reachableNodeIds.contains(node.id),
  );
  if (!hasReachableEnd &&
      scene.graph.nodes.any((node) => node.kind == SceneNodeKind.end)) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.unreachableEndNode,
        severity: SceneDiagnosticSeverity.error,
        message: 'Aucune fin de scène n’est atteignable depuis le départ.',
        sceneId: scene.id,
        target: SceneDiagnosticTarget.graph,
        suggestedFixLabel: 'Créer au moins un chemin vers une fin.',
      ),
    );
  }
}

void _diagnoseCycles(
  SceneAsset scene,
  Map<String, SceneNode> nodeById,
  List<SceneDiagnostic> diagnostics,
) {
  final startNode = nodeById[scene.graph.startNodeId];
  if (startNode == null) {
    return;
  }
  final outgoingByNode = <String, List<SceneEdge>>{};
  for (final edge in scene.graph.edges) {
    outgoingByNode.putIfAbsent(edge.fromNodeId, () => []).add(edge);
  }
  final visiting = <String>{};
  final visited = <String>{};
  String? cycleNodeId;

  bool visit(String nodeId) {
    if (cycleNodeId != null) {
      return true;
    }
    if (visiting.contains(nodeId)) {
      cycleNodeId = nodeId;
      return true;
    }
    if (visited.contains(nodeId)) {
      return false;
    }
    visiting.add(nodeId);
    for (final edge in outgoingByNode[nodeId] ?? const <SceneEdge>[]) {
      if (!nodeById.containsKey(edge.toNodeId)) {
        continue;
      }
      if (visit(edge.toNodeId)) {
        return true;
      }
    }
    visiting.remove(nodeId);
    visited.add(nodeId);
    return false;
  }

  visit(startNode.id);
  if (cycleNodeId == null) {
    return;
  }
  diagnostics.add(
    SceneDiagnostic(
      code: SceneDiagnosticCode.cycleUnsupported,
      severity: SceneDiagnosticSeverity.warning,
      message: 'La scène contient un cycle non supporté en V0.',
      sceneId: scene.id,
      nodeId: cycleNodeId,
      target: SceneDiagnosticTarget.graph,
      suggestedFixLabel:
          'Supprimer la boucle ou attendre le support runtime des cycles.',
    ),
  );
}

void _diagnoseConditionNode(
  SceneAsset scene,
  SceneNode node,
  List<SceneDiagnostic> diagnostics,
) {
  final payload = node.payload;
  if (payload is! SceneConditionPayload) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.conditionSourceMissing,
        severity: SceneDiagnosticSeverity.error,
        message: 'La condition doit avoir un payload condition.',
        sceneId: scene.id,
        nodeId: node.id,
        target: SceneDiagnosticTarget.node,
        suggestedFixLabel: 'Reconfigurer le nœud Condition.',
      ),
    );
    return;
  }

  final source = payload.conditionSource;
  if (source == null) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.conditionSourceMissing,
        severity: SceneDiagnosticSeverity.error,
        message: 'La condition doit choisir une source métier V0.',
        sceneId: scene.id,
        nodeId: node.id,
        target: SceneDiagnosticTarget.node,
        suggestedFixLabel: 'Choisir Fact-like, Story Step ou Event consommé.',
      ),
    );
    return;
  }

  if (!_isConditionSourceKindSupportedV0(source.sourceKind)) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.conditionUsesFutureSource,
        severity: SceneDiagnosticSeverity.error,
        message: 'Cette source de condition est prévue pour un lot futur.',
        sceneId: scene.id,
        nodeId: node.id,
        target: SceneDiagnosticTarget.node,
        suggestedFixLabel: 'Utiliser une source V0 existante.',
      ),
    );
    return;
  }

  if (!_isConditionOperatorSupportedV0(source)) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.conditionOperatorUnsupported,
        severity: SceneDiagnosticSeverity.error,
        message: 'Cet opérateur n’est pas compatible avec la source V0.',
        sceneId: scene.id,
        nodeId: node.id,
        target: SceneDiagnosticTarget.node,
        suggestedFixLabel: 'Choisir un opérateur supporté pour cette source.',
      ),
    );
  }

  if (source.sourceKind == SceneConditionSourceKind.storyStepCompletion &&
      !_isStoryStepCompletionValue(source.value)) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.conditionValueMissing,
        severity: SceneDiagnosticSeverity.error,
        message: 'La condition Story Step doit choisir completed/notCompleted.',
        sceneId: scene.id,
        nodeId: node.id,
        target: SceneDiagnosticTarget.node,
        suggestedFixLabel: 'Choisir la valeur de complétion attendue.',
      ),
    );
  }

  final label = source.label?.trim();
  if (label == null || label.isEmpty || label == source.sourceId) {
    diagnostics.add(
      SceneDiagnostic(
        code: SceneDiagnosticCode.conditionUsesRawTechnicalId,
        severity: SceneDiagnosticSeverity.warning,
        message: 'La condition affiche encore un identifiant technique.',
        sceneId: scene.id,
        nodeId: node.id,
        target: SceneDiagnosticTarget.node,
        suggestedFixLabel: 'Choisir un label lisible via le picker.',
      ),
    );
  }
}

final class _SceneOutputPortSpec {
  const _SceneOutputPortSpec({
    required this.id,
    required this.edgeKinds,
    this.required = false,
  });

  final String id;
  final Set<SceneEdgeKind> edgeKinds;
  final bool required;
}

List<_SceneOutputPortSpec>? _v0OutputPortSpecsForNode(
  SceneNode node,
  Map<String, SceneNode> nodeById,
) {
  return switch (node.kind) {
    SceneNodeKind.start => const [
        _SceneOutputPortSpec(
          id: 'completed',
          edgeKinds: {SceneEdgeKind.defaultFlow},
          required: true,
        ),
      ],
    SceneNodeKind.condition => const [
        _SceneOutputPortSpec(
          id: 'true',
          edgeKinds: {SceneEdgeKind.conditionTrue},
          required: true,
        ),
        _SceneOutputPortSpec(
          id: 'false',
          edgeKinds: {SceneEdgeKind.conditionFalse},
          required: true,
        ),
      ],
    SceneNodeKind.merge => const [
        _SceneOutputPortSpec(
          id: 'completed',
          edgeKinds: {SceneEdgeKind.defaultFlow},
          required: true,
        ),
      ],
    SceneNodeKind.yarnDialogue => _yarnDialogueOutputPortSpecs(node),
    SceneNodeKind.battle => _battleOutputPortSpecs(node),
    SceneNodeKind.action => _actionOutputPortSpecs(node),
    SceneNodeKind.cinematic => const [
        _SceneOutputPortSpec(
          id: 'completed',
          edgeKinds: {SceneEdgeKind.cinematicCompleted},
          required: true,
        ),
      ],
    SceneNodeKind.end => const [],
    SceneNodeKind.branchByOutcome => _branchOutputPortSpecs(node, nodeById),
  };
}

List<_SceneOutputPortSpec> _actionOutputPortSpecs(SceneNode node) {
  final payload = node.payload;
  final interactiveCommand =
      payload is SceneActionPayload ? payload.interactiveCommand : null;
  final outputPortIds =
      interactiveCommand?.outputPortIds ?? const <String>['completed'];
  return <_SceneOutputPortSpec>[
    for (final outputPortId in outputPortIds)
      _SceneOutputPortSpec(
        id: outputPortId,
        edgeKinds: const {
          SceneEdgeKind.defaultFlow,
          SceneEdgeKind.actionCompleted,
        },
        required: true,
      ),
  ];
}

List<_SceneOutputPortSpec> _branchOutputPortSpecs(
  SceneNode node,
  Map<String, SceneNode> nodeById,
) {
  final payload = node.payload as SceneBranchByOutcomePayload;
  final sourceNodeId = payload.sourceNodeId;
  final sourceNode = sourceNodeId == null ? null : nodeById[sourceNodeId];
  if (sourceNode == null) return const <_SceneOutputPortSpec>[];
  final sourcePorts = _outcomePortIdsForBranchSource(sourceNode);
  final exactPortsRequired =
      payload.fallbackPolicy == SceneBranchOutcomeFallbackPolicy.exact;
  return <_SceneOutputPortSpec>[
    for (final portId in sourcePorts)
      _SceneOutputPortSpec(
        id: portId,
        edgeKinds: const {SceneEdgeKind.branchOutcome},
        required: exactPortsRequired,
      ),
    if (payload.fallbackPolicy ==
            SceneBranchOutcomeFallbackPolicy.defaultRoute &&
        !sourcePorts.contains('default'))
      const _SceneOutputPortSpec(
        id: 'default',
        edgeKinds: {SceneEdgeKind.branchOutcome},
        required: true,
      ),
    if (payload.fallbackPolicy == SceneBranchOutcomeFallbackPolicy.errorRoute &&
        !sourcePorts.contains('error'))
      const _SceneOutputPortSpec(
        id: 'error',
        edgeKinds: {SceneEdgeKind.error},
        required: true,
      ),
  ];
}

List<String> _outcomePortIdsForBranchSource(SceneNode node) {
  return switch (node.payload) {
    SceneYarnDialoguePayload(:final expectedOutcomes) => <String>[
        'completed',
        for (final outcome in expectedOutcomes)
          if (outcome != 'completed') outcome,
      ],
    SceneBattlePayload(:final declaredOutcomes) => declaredOutcomes.isEmpty
        ? const <String>['victory', 'defeat']
        : declaredOutcomes,
    SceneConditionPayload() => const <String>['true', 'false'],
    SceneStartPayload() ||
    SceneActionPayload() ||
    SceneCinematicPayload() ||
    SceneMergePayload() ||
    SceneEndPayload() ||
    SceneBranchByOutcomePayload() =>
      const <String>[],
    _ => const <String>[],
  };
}

List<_SceneOutputPortSpec> _yarnDialogueOutputPortSpecs(SceneNode node) {
  final payload = node.payload as SceneYarnDialoguePayload;
  return [
    const _SceneOutputPortSpec(
      id: 'completed',
      edgeKinds: {SceneEdgeKind.defaultFlow},
      required: true,
    ),
    for (final outcomeId in payload.expectedOutcomes)
      if (outcomeId != 'completed')
        _SceneOutputPortSpec(
          id: outcomeId,
          edgeKinds: const {SceneEdgeKind.dialogueOutcome},
          required: true,
        ),
  ];
}

List<_SceneOutputPortSpec> _battleOutputPortSpecs(SceneNode node) {
  final payload = node.payload as SceneBattlePayload;
  final outcomes = payload.declaredOutcomes.isEmpty
      ? const ['victory', 'defeat']
      : payload.declaredOutcomes;
  return [
    for (final outcomeId in outcomes)
      _SceneOutputPortSpec(
        id: outcomeId,
        edgeKinds: {
          switch (outcomeId) {
            'victory' => SceneEdgeKind.battleVictory,
            'defeat' => SceneEdgeKind.battleDefeat,
            _ => SceneEdgeKind.branchOutcome,
          },
        },
        required: true,
      ),
  ];
}

_SceneOutputPortSpec? _findPortSpec(
  List<_SceneOutputPortSpec> specs,
  String portId,
) {
  for (final spec in specs) {
    if (spec.id == portId) {
      return spec;
    }
  }
  return null;
}

bool _isConditionSourceKindSupportedV0(SceneConditionSourceKind kind) {
  return switch (kind) {
    SceneConditionSourceKind.fact ||
    SceneConditionSourceKind.factLikeStoryFlag ||
    SceneConditionSourceKind.storyStepCompletion ||
    SceneConditionSourceKind.consumedEvent =>
      true,
    SceneConditionSourceKind.storyStepActive ||
    SceneConditionSourceKind.inventoryItem ||
    SceneConditionSourceKind.partyState ||
    SceneConditionSourceKind.trainerDefeated ||
    SceneConditionSourceKind.dialogueOutcome ||
    SceneConditionSourceKind.battleOutcome ||
    SceneConditionSourceKind.scriptVariable ||
    SceneConditionSourceKind.worldState =>
      false,
  };
}

bool _isConditionOperatorSupportedV0(SceneConditionSource source) {
  return switch (source.sourceKind) {
    SceneConditionSourceKind.fact => source.expectedFactValue != null ||
        source.operator == SceneConditionOperator.isTrue ||
        source.operator == SceneConditionOperator.isFalse ||
        source.operator == SceneConditionOperator.equals &&
            (source.value == 'true' || source.value == 'false'),
    SceneConditionSourceKind.factLikeStoryFlag ||
    SceneConditionSourceKind.consumedEvent =>
      source.operator == SceneConditionOperator.isTrue ||
          source.operator == SceneConditionOperator.isFalse,
    SceneConditionSourceKind.storyStepCompletion =>
      source.operator == SceneConditionOperator.equals,
    SceneConditionSourceKind.storyStepActive ||
    SceneConditionSourceKind.inventoryItem ||
    SceneConditionSourceKind.partyState ||
    SceneConditionSourceKind.trainerDefeated ||
    SceneConditionSourceKind.dialogueOutcome ||
    SceneConditionSourceKind.battleOutcome ||
    SceneConditionSourceKind.scriptVariable ||
    SceneConditionSourceKind.worldState =>
      false,
  };
}

bool _isStoryStepCompletionValue(String? value) {
  return value == SceneConditionValues.completed ||
      value == SceneConditionValues.notCompleted;
}
