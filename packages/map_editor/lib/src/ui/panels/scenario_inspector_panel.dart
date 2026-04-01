import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../app/providers/core_providers.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_state.dart';
import '../../features/scenario/scenario_authoring_ux.dart';
import '../../features/scenario/scenario_flow_diagnostics.dart';
import '../shared/cupertino_editor_widgets.dart';

enum _ScenarioConditionMode {
  none,
  flagSet,
  flagUnset,
  eventConsumed,
  playerOnMap,
  variableEquals,
  rawJson,
}

enum _ScenarioRecipeLinkMode {
  append,
  replaceOutgoing,
  chain,
}

class _ScenarioRecipePlan {
  const _ScenarioRecipePlan({
    required this.mode,
    required this.replacedOutgoingCount,
    this.chainTargetNodeId,
    this.chainEdgeLabel,
  });

  final _ScenarioRecipeLinkMode mode;
  final int replacedOutgoingCount;
  final String? chainTargetNodeId;
  final String? chainEdgeLabel;
}

String _scenarioRecipeModeLabel(_ScenarioRecipeLinkMode mode) {
  return switch (mode) {
    _ScenarioRecipeLinkMode.append => 'Insérer en parallèle',
    _ScenarioRecipeLinkMode.replaceOutgoing =>
      'Remplacer les sorties existantes',
    _ScenarioRecipeLinkMode.chain => 'Chaîner avant la sortie existante',
  };
}

String _scenarioRecipeModeDescription(_ScenarioRecipeLinkMode mode) {
  return switch (mode) {
    _ScenarioRecipeLinkMode.append =>
      'Garde les sorties actuelles et ajoute une nouvelle branche.',
    _ScenarioRecipeLinkMode.replaceOutgoing =>
      'Supprime les sorties actuelles pour repartir sur un flow propre.',
    _ScenarioRecipeLinkMode.chain =>
      'Insère le nouveau flow puis reconnecte sa fin vers l’ancienne cible.',
  };
}

String _conditionModeLabel(_ScenarioConditionMode mode) {
  return switch (mode) {
    _ScenarioConditionMode.none => 'Aucune condition',
    _ScenarioConditionMode.flagSet => 'Flag actif',
    _ScenarioConditionMode.flagUnset => 'Flag inactif',
    _ScenarioConditionMode.eventConsumed => 'Event consommé',
    _ScenarioConditionMode.playerOnMap => 'Player sur map',
    _ScenarioConditionMode.variableEquals => 'Variable égale',
    _ScenarioConditionMode.rawJson => 'JSON brut (avancé)',
  };
}

String _conditionModeDescription(_ScenarioConditionMode mode) {
  return switch (mode) {
    _ScenarioConditionMode.none => 'Le flux continue sans test conditionnel.',
    _ScenarioConditionMode.flagSet =>
      'Passe sur cette branche si le flag est actif.',
    _ScenarioConditionMode.flagUnset =>
      'Passe sur cette branche si le flag est inactif.',
    _ScenarioConditionMode.eventConsumed =>
      'Passe sur cette branche si cet event a déjà été consommé.',
    _ScenarioConditionMode.playerOnMap =>
      'Passe sur cette branche si le joueur est sur la map ciblée.',
    _ScenarioConditionMode.variableEquals =>
      'Compare une variable persistante à une valeur.',
    _ScenarioConditionMode.rawJson =>
      'Mode avancé pour allOf / anyOf / not et autres conditions composées.',
  };
}

class _ScenarioMapScopedOption {
  const _ScenarioMapScopedOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

class ScenarioInspectorPanel extends ConsumerStatefulWidget {
  const ScenarioInspectorPanel({super.key});

  @override
  ConsumerState<ScenarioInspectorPanel> createState() =>
      _ScenarioInspectorPanelState();
}

class _ScenarioInspectorPanelState
    extends ConsumerState<ScenarioInspectorPanel> {
  final _scenarioNameController = TextEditingController();
  final _scenarioDescriptionController = TextEditingController();
  final _nodeTitleController = TextEditingController();
  final _nodeDescriptionController = TextEditingController();
  final _nodeActionKindController = TextEditingController();
  final _nodeMessageController = TextEditingController();
  final _nodeConditionJsonController = TextEditingController();
  final _nodeConditionFlagNameController = TextEditingController();
  final _nodeConditionVariableNameController = TextEditingController();
  final _nodeConditionVariableValueController = TextEditingController();
  final _nodeScriptIdController = TextEditingController();
  final _nodeDialogueIdController = TextEditingController();
  final _nodeMapIdController = TextEditingController();
  final _nodeEventIdController = TextEditingController();
  final _nodeEntityIdController = TextEditingController();
  final _nodeWarpIdController = TextEditingController();
  final _nodeTriggerIdController = TextEditingController();
  final _nodeTrainerIdController = TextEditingController();
  final _nodeFlagNameController = TextEditingController();
  final _nodeVariableNameController = TextEditingController();

  final Map<String, MapData?> _mapCache = <String, MapData?>{};

  String? _boundScenarioFingerprint;
  String? _boundNodeFingerprint;
  String? _boundProjectRoot;
  _ScenarioConditionMode _conditionMode = _ScenarioConditionMode.none;
  bool _showAdvancedNodeFields = false;

  @override
  void dispose() {
    _scenarioNameController.dispose();
    _scenarioDescriptionController.dispose();
    _nodeTitleController.dispose();
    _nodeDescriptionController.dispose();
    _nodeActionKindController.dispose();
    _nodeMessageController.dispose();
    _nodeConditionJsonController.dispose();
    _nodeConditionFlagNameController.dispose();
    _nodeConditionVariableNameController.dispose();
    _nodeConditionVariableValueController.dispose();
    _nodeScriptIdController.dispose();
    _nodeDialogueIdController.dispose();
    _nodeMapIdController.dispose();
    _nodeEventIdController.dispose();
    _nodeEntityIdController.dispose();
    _nodeWarpIdController.dispose();
    _nodeTriggerIdController.dispose();
    _nodeTrainerIdController.dispose();
    _nodeFlagNameController.dispose();
    _nodeVariableNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final project = state.project;
    if (project == null) {
      return Center(
        child: Text(
          'No project loaded',
          style: TextStyle(
            color: CupertinoColors.placeholderText.resolveFrom(context),
          ),
        ),
      );
    }

    if (_boundProjectRoot != state.projectRootPath) {
      _boundProjectRoot = state.projectRootPath;
      _mapCache.clear();
    }

    final scenario = notifier.getSelectedScenario();
    if (scenario == null) {
      return Center(
        child: Text(
          'Sélectionne un Scenario Graph dans la colonne de gauche.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: CupertinoColors.placeholderText.resolveFrom(context),
          ),
        ),
      );
    }
    _syncScenarioControllers(scenario);
    final flowReport = analyzeScenarioFlow(
      scenario,
      graphRuntimeConnected: kScenarioGraphRuntimeExecutionConnected,
    );

    ScenarioNode? selectedNode;
    if (state.selectedScenarioNodeId != null &&
        state.selectedScenarioNodeId!.trim().isNotEmpty) {
      for (final node in scenario.nodes) {
        if (node.id == state.selectedScenarioNodeId) {
          selectedNode = node;
          break;
        }
      }
    }
    _syncNodeControllers(selectedNode);

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      children: [
        _buildScenarioHeader(
          context,
          project: project,
          scenario: scenario,
          notifier: notifier,
        ),
        const SizedBox(height: 10),
        _buildScenarioSystemLegend(context),
        const SizedBox(height: 10),
        _buildScenarioBasics(context, notifier, scenario),
        const SizedBox(height: 10),
        _buildScenarioDiagnosticsCard(
          context,
          scenario: scenario,
          report: flowReport,
        ),
        const SizedBox(height: 10),
        _buildScenarioNodesList(
          context,
          notifier: notifier,
          scenario: scenario,
          selectedNodeId: state.selectedScenarioNodeId,
        ),
        const SizedBox(height: 10),
        if (selectedNode == null)
          _buildNoNodeSelectedCard(context)
        else ...[
          _buildNodeInspector(
            context,
            state: state,
            notifier: notifier,
            project: project,
            scenario: scenario,
            node: selectedNode,
            flowReport: flowReport,
          ),
          const SizedBox(height: 10),
          _buildOutgoingEdges(
            context,
            notifier: notifier,
            scenario: scenario,
            node: selectedNode,
          ),
        ],
      ],
    );
  }

  Widget _buildScenarioHeader(
    BuildContext context, {
    required ProjectManifest project,
    required ScenarioAsset scenario,
    required EditorNotifier notifier,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyMint.withValues(alpha: 0.1),
        ),
        border: Border.all(
          color: EditorChrome.inspectorJoyMint.withValues(alpha: 0.55),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Scenario Inspector',
                    style: TextStyle(
                      color: CupertinoColors.label.resolveFrom(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                EditorToolbarIconButton(
                  icon: CupertinoIcons.add,
                  tooltip: 'Créer un Scenario Graph',
                  onPressed: () => _promptCreateScenario(context, notifier),
                ),
                EditorToolbarIconButton(
                  icon: CupertinoIcons.pencil,
                  tooltip: 'Renommer ce scénario',
                  onPressed: () => _promptRenameScenario(
                    context,
                    notifier,
                    scenario,
                  ),
                ),
                EditorToolbarIconButton(
                  icon: CupertinoIcons.delete,
                  tooltip: 'Supprimer ce scénario',
                  onPressed: () => _confirmDeleteScenario(
                    context,
                    notifier,
                    scenario,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Sélectionné: ${scenario.name} (${scenario.id})',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 30),
              color: EditorChrome.largeIslandSurfaceColor(
                context,
                tint: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.1),
              ),
              onPressed: () async {
                final picked = await showCupertinoListPicker<ScenarioAsset>(
                  context: context,
                  title: 'Choisir un Scenario Graph',
                  items: project.scenarios,
                  labelOf: (value) => '${value.name} (${value.id})',
                );
                if (picked == null || !context.mounted) return;
                notifier.selectProjectScenario(picked.id);
                notifier.selectScenarioWorkspace(picked.id);
              },
              child: const Text('Changer de scénario'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioSystemLegend(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.06),
        ),
        border: Border.all(
          color: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.32),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Repères rapides',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            _legendLine(
              context,
              title: 'Scenario Graphs',
              description:
                  'Orchestration visuelle globale (flux, branches, liens monde).',
            ),
            _legendLine(
              context,
              title: 'Scenario Scripts',
              description:
                  'Procédures runtime réutilisables référencées par nodes/events.',
            ),
            _legendLine(
              context,
              title: 'Dialogue Library',
              description: 'Contenu Yarn (texte, nœuds de dialogue, sauts).',
            ),
            _legendLine(
              context,
              title: 'World Maps',
              description:
                  'Contenu concret du monde (events, entités, warps, triggers).',
            ),
            _legendLine(
              context,
              title: 'Exécution runtime',
              description: kScenarioGraphRuntimeExecutionConnected
                  ? 'Le graphe scénario est branché à l’exécution runtime.'
                  : 'Le graphe scénario est actuellement orienté authoring/orchestration (pas d’auto-exécution complète).',
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendLine(
    BuildContext context, {
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$title : $description',
        style: TextStyle(
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
          fontSize: 11,
          height: 1.25,
        ),
      ),
    );
  }

  Widget _buildScenarioBasics(
    BuildContext context,
    EditorNotifier notifier,
    ScenarioAsset scenario,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.06),
        ),
        border: Border.all(
          color: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.38),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Métadonnées scénario',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            CupertinoTextField(
              controller: _scenarioNameController,
              placeholder: 'Nom lisible du scénario',
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            ),
            const SizedBox(height: 6),
            CupertinoTextField(
              controller: _scenarioDescriptionController,
              placeholder:
                  'Résumé auteur (ex: Intro professeur / choix starter)',
              minLines: 2,
              maxLines: 4,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    minimumSize: const Size(0, 32),
                    onPressed: () => notifier.renameProjectScenario(
                      scenarioId: scenario.id,
                      name: _scenarioNameController.text.trim(),
                    ),
                    child: const Text('Appliquer le nom'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Entry node : ${scenario.entryNodeId}',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioDiagnosticsCard(
    BuildContext context, {
    required ScenarioAsset scenario,
    required ScenarioFlowReport report,
  }) {
    final summary = report.summary;
    final errors = report.issues
        .where((issue) => issue.severity == ScenarioFlowIssueSeverity.error)
        .toList(growable: false);
    final warnings = report.issues
        .where((issue) => issue.severity == ScenarioFlowIssueSeverity.warning)
        .toList(growable: false);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyCoral.withValues(alpha: 0.05),
        ),
        border: Border.all(
          color: EditorChrome.inspectorJoyCoral.withValues(alpha: 0.36),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Diagnostic du scénario',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            _legendLine(
              context,
              title: 'Runtime',
              description: summary.graphRuntimeConnected
                  ? 'Le graphe est branché au runtime.'
                  : 'Le graphe est en mode authoring/orchestration (pas d’exécution automatique complète).',
            ),
            _legendLine(
              context,
              title: 'Nœuds',
              description:
                  '${summary.totalNodes} total · ${summary.reachableNodes} atteignables · ${summary.unreachableNodes} non atteignables',
            ),
            _legendLine(
              context,
              title: 'Qualité de flow',
              description:
                  '${summary.incompleteNodes} incomplets · ${summary.deadEndNodes} cul-de-sac · ${summary.isolatedNodes} isolés',
            ),
            _legendLine(
              context,
              title: 'Statut exécution',
              description:
                  '${summary.runtimeConnectedNodes} exécutés · ${summary.runtimeCapableNodes} capables non branchés · ${summary.authoringBridgeNodes} authoring-only · ${summary.plannedNodes} prévus',
            ),
            if (errors.isNotEmpty || warnings.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Alertes principales',
                style: TextStyle(
                  color: CupertinoColors.label.resolveFrom(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              ...[
                ...errors.take(2),
                ...warnings.take(errors.isEmpty ? 2 : 1),
              ].map(
                (issue) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    '• ${issue.message}',
                    style: TextStyle(
                      color: issue.severity == ScenarioFlowIssueSeverity.error
                          ? EditorChrome.inspectorJoyCoral
                          : CupertinoColors.secondaryLabel.resolveFrom(context),
                      fontSize: 10.5,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
            if (scenario.nodes.isEmpty)
              Text(
                'Ajoute au moins un Start et un End pour démarrer.',
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontSize: 10.5,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioNodesList(
    BuildContext context, {
    required EditorNotifier notifier,
    required ScenarioAsset scenario,
    required String? selectedNodeId,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyLilac.withValues(alpha: 0.06),
        ),
        border: Border.all(
          color: EditorChrome.inspectorJoyLilac.withValues(alpha: 0.34),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Nœuds du scénario',
                    style: TextStyle(
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                EditorToolbarIconButton(
                  icon: CupertinoIcons.plus_circle,
                  tooltip: 'Ajouter un nœud',
                  onPressed: () => _promptAddNode(context, notifier, scenario),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (scenario.nodes.isEmpty)
              Text(
                'Aucun nœud.',
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontSize: 11,
                ),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final node in scenario.nodes)
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      minimumSize: const Size(0, 26),
                      color: node.id == selectedNodeId
                          ? EditorChrome.inspectorJoyCyan.withValues(alpha: 0.3)
                          : EditorChrome.largeIslandSurfaceColor(
                              context,
                              tint: EditorChrome.inspectorJoyBlue
                                  .withValues(alpha: 0.12),
                            ),
                      onPressed: () => notifier.selectScenarioNode(node.id),
                      child: Text(
                        '${scenarioNodeTypeLabel(node.type)} · ${node.id}',
                        style: TextStyle(
                          fontSize: 11,
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoNodeSelectedCard(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.06),
        ),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Text(
          'Sélectionne un nœud dans le graphe (ou dans la liste) pour afficher uniquement ses champs utiles.',
          style: TextStyle(
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildNodeInspector(
    BuildContext context, {
    required EditorState state,
    required EditorNotifier notifier,
    required ProjectManifest project,
    required ScenarioAsset scenario,
    required ScenarioNode node,
    required ScenarioFlowReport flowReport,
  }) {
    final isEntryNode = scenario.entryNodeId == node.id;
    final referenceMode = node.type == ScenarioNodeType.reference;
    final actionPreset = scenarioActionPresetById(
      _nodeActionKindController.text.trim(),
      referenceMode: referenceMode,
    );
    final nodeIssues = flowReport.issuesForNode(node.id);
    final summaryNode = node.copyWith(
      title: _nodeTitleController.text.trim(),
      description: _nodeDescriptionController.text.trim(),
      binding: node.binding.copyWith(
        scriptId: _normalizeOptional(_nodeScriptIdController.text),
        dialogueId: _normalizeOptional(_nodeDialogueIdController.text),
        mapId: _normalizeOptional(_nodeMapIdController.text),
        eventId: _normalizeOptional(_nodeEventIdController.text),
        entityId: _normalizeOptional(_nodeEntityIdController.text),
        warpId: _normalizeOptional(_nodeWarpIdController.text),
        triggerId: _normalizeOptional(_nodeTriggerIdController.text),
        trainerId: _normalizeOptional(_nodeTrainerIdController.text),
        flagName: _normalizeOptional(_nodeFlagNameController.text),
        variableName: _normalizeOptional(_nodeVariableNameController.text),
      ),
      payload: node.payload.copyWith(
        actionKind: _normalizeOptional(_nodeActionKindController.text),
        message: _normalizeOptional(_nodeMessageController.text),
      ),
    );
    final summaryPreset = scenarioActionPresetById(
      summaryNode.payload.actionKind,
      referenceMode: summaryNode.type == ScenarioNodeType.reference,
    );
    final executionState = scenarioNodeExecutionState(
      summaryNode,
      actionPreset: summaryPreset,
      graphRuntimeConnected: flowReport.summary.graphRuntimeConnected,
    );
    final intent = scenarioNodeIntent(
      summaryNode,
      actionPreset: summaryPreset,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyCyan.withValues(alpha: 0.08),
        ),
        border: Border.all(
          color: EditorChrome.inspectorJoyCyan.withValues(alpha: 0.42),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Node inspector · ${node.id}',
                    style: TextStyle(
                      color: CupertinoColors.label.resolveFrom(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                EditorToolbarIconButton(
                  icon: CupertinoIcons.play_fill,
                  tooltip: 'Définir comme entry node',
                  onPressed: () => notifier.setScenarioEntryNode(
                    scenarioId: scenario.id,
                    nodeId: node.id,
                  ),
                ),
                EditorToolbarIconButton(
                  icon: CupertinoIcons.delete,
                  tooltip: 'Supprimer ce nœud',
                  onPressed: () => notifier.deleteScenarioNode(
                    scenarioId: scenario.id,
                    nodeId: node.id,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _helpCard(
              context,
              title: scenarioNodeTypeLabel(node.type),
              description: scenarioNodeTypeDescription(node.type),
              accent: _colorForNodeType(node.type),
            ),
            const SizedBox(height: 6),
            _buildNodeSummaryCard(
              context,
              scenario: scenario,
              node: summaryNode,
              actionPreset: summaryPreset,
              nodeIssues: nodeIssues,
              executionState: executionState,
              intent: intent,
            ),
            if (nodeIssues.isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildNodeIssuesCard(
                context,
                issues: nodeIssues,
              ),
            ],
            const SizedBox(height: 6),
            _readonlyLine(
              context,
              'Type',
              scenarioNodeTypeLabel(node.type),
            ),
            _readonlyLine(
              context,
              'Entry',
              isEntryNode ? 'Oui (point de départ)' : 'Non',
            ),
            const SizedBox(height: 6),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 30),
              color: EditorChrome.largeIslandSurfaceColor(
                context,
                tint: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.1),
              ),
              onPressed: () => _pickNodeType(context, notifier, scenario, node),
              child: const Text('Changer le type de node'),
            ),
            const SizedBox(height: 8),
            _labeledField(
              context,
              label: 'Titre',
              controller: _nodeTitleController,
              placeholder: defaultScenarioNodeTitle(node.type),
            ),
            const SizedBox(height: 6),
            _labeledField(
              context,
              label: 'Description',
              controller: _nodeDescriptionController,
              placeholder: 'Décris le rôle narratif de ce node.',
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 8),
            _buildScenarioRecipeSection(
              context,
              state: state,
              notifier: notifier,
              project: project,
              scenario: scenario,
              node: node,
            ),
            const SizedBox(height: 10),
            ..._buildNodeTypeSpecificSections(
              context,
              state: state,
              notifier: notifier,
              project: project,
              scenario: scenario,
              node: node,
              actionPreset: actionPreset,
            ),
            const SizedBox(height: 8),
            _buildAdvancedNodeSection(
              context,
              state: state,
              project: project,
              node: node,
            ),
            const SizedBox(height: 10),
            CupertinoButton.filled(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: const Size(0, 34),
              onPressed: () => _applyNodeChanges(
                context,
                notifier: notifier,
                scenario: scenario,
                node: node,
              ),
              child: const Text('Appliquer les modifications du node'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeSummaryCard(
    BuildContext context, {
    required ScenarioAsset scenario,
    required ScenarioNode node,
    required ScenarioActionPreset? actionPreset,
    required List<ScenarioFlowIssue> nodeIssues,
    required ScenarioNodeExecutionState executionState,
    required ScenarioNodeIntent intent,
  }) {
    final role = scenarioNodeIntentLabel(intent);
    final summary = scenarioNodeHumanSummary(node);
    final support = scenarioNodeExecutionStateLabel(executionState);
    final supportHint = scenarioNodeExecutionStateDescription(executionState);
    final incoming =
        scenario.edges.where((edge) => edge.toNodeId == node.id).length;
    final outgoing =
        scenario.edges.where((edge) => edge.fromNodeId == node.id).length;
    final errorCount = nodeIssues
        .where((issue) => issue.severity == ScenarioFlowIssueSeverity.error)
        .length;
    final warningCount = nodeIssues
        .where((issue) => issue.severity == ScenarioFlowIssueSeverity.warning)
        .length;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyMint.withValues(alpha: 0.08),
        ),
        border: Border.all(
          color: EditorChrome.inspectorJoyMint.withValues(alpha: 0.34),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résumé du node',
              style: TextStyle(
                color: CupertinoColors.label.resolveFrom(context),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              role,
              style: TextStyle(
                color: CupertinoColors.label.resolveFrom(context),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              summary,
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 11,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$support · Entrées $incoming · Sorties $outgoing',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              supportHint,
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 10.5,
              ),
            ),
            if (errorCount > 0 || warningCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Diagnostics node: $errorCount erreur(s) · $warningCount avertissement(s)',
                style: TextStyle(
                  color: errorCount > 0
                      ? EditorChrome.inspectorJoyCoral
                      : CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNodeIssuesCard(
    BuildContext context, {
    required List<ScenarioFlowIssue> issues,
  }) {
    final topIssues = issues.take(3).toList(growable: false);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyCoral.withValues(alpha: 0.07),
        ),
        border: Border.all(
          color: EditorChrome.inspectorJoyCoral.withValues(alpha: 0.36),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Points à corriger sur ce node',
              style: TextStyle(
                color: CupertinoColors.label.resolveFrom(context),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            for (final issue in topIssues)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '• ${issue.message}',
                  style: TextStyle(
                    color: issue.severity == ScenarioFlowIssueSeverity.error
                        ? EditorChrome.inspectorJoyCoral
                        : CupertinoColors.secondaryLabel.resolveFrom(context),
                    fontSize: 10.5,
                    height: 1.2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioRecipeSection(
    BuildContext context, {
    required EditorState state,
    required EditorNotifier notifier,
    required ProjectManifest project,
    required ScenarioAsset scenario,
    required ScenarioNode node,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyHoney.withValues(alpha: 0.07),
        ),
        border: Border.all(
          color: EditorChrome.inspectorJoyHoney.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recettes Blueprint',
              style: TextStyle(
                color: CupertinoColors.label.resolveFrom(context),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Crée un mini-flow concret à partir du node courant.',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 10.5,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _tinyInsertButton(
                  context,
                  label: 'Entrée map → dialogue',
                  onPressed: () => _applyRecipeMapEnterDialogue(
                    context,
                    state: state,
                    notifier: notifier,
                    project: project,
                    scenario: scenario,
                    originNode: node,
                  ),
                ),
                _tinyInsertButton(
                  context,
                  label: 'Entrée trigger → dialogue',
                  onPressed: () => _applyRecipeTriggerEnterDialogue(
                    context,
                    state: state,
                    notifier: notifier,
                    project: project,
                    scenario: scenario,
                    originNode: node,
                  ),
                ),
                _tinyInsertButton(
                  context,
                  label: 'Parler PNJ → script',
                  onPressed: () => _applyRecipeEntityInteractScript(
                    context,
                    state: state,
                    notifier: notifier,
                    project: project,
                    scenario: scenario,
                    originNode: node,
                  ),
                ),
                _tinyInsertButton(
                  context,
                  label: 'Combat dresseur',
                  onPressed: () => _applyRecipeTrainerBattle(
                    context,
                    notifier: notifier,
                    project: project,
                    scenario: scenario,
                    originNode: node,
                  ),
                ),
                _tinyInsertButton(
                  context,
                  label: 'Condition flag A/B',
                  onPressed: () => _applyRecipeFlagBranch(
                    context,
                    notifier: notifier,
                    project: project,
                    scenario: scenario,
                    originNode: node,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildNodeTypeSpecificSections(
    BuildContext context, {
    required EditorState state,
    required EditorNotifier notifier,
    required ProjectManifest project,
    required ScenarioAsset scenario,
    required ScenarioNode node,
    required ScenarioActionPreset? actionPreset,
  }) {
    switch (node.type) {
      case ScenarioNodeType.start:
        return <Widget>[
          _quickHelpCard(
            context,
            title: 'How to use this node',
            lines: const <String>[
              'Le flux doit démarrer ici.',
              'Relie Start vers le premier node réel (Dialogue, Action, Condition).',
              'Un seul Start est autorisé par scénario.',
            ],
          ),
        ];
      case ScenarioNodeType.end:
        return <Widget>[
          _quickHelpCard(
            context,
            title: 'How to use this node',
            lines: const <String>[
              'Fin de séquence.',
              'Évite d’ajouter des liens sortants depuis End.',
              'Utilise plusieurs End si tu as plusieurs conclusions.',
            ],
          ),
        ];
      case ScenarioNodeType.dialogue:
        return <Widget>[
          _bindingPickerField(
            context,
            title: 'Dialogue Yarn',
            helper:
                'Sélectionne un dialogue existant dans la Dialogue Library.',
            value: _optionalValue(_nodeDialogueIdController.text),
            onPick: () => _pickDialogueBinding(context, project),
          ),
          const SizedBox(height: 6),
          _bindingPickerField(
            context,
            title: 'Script scénario',
            helper:
                'Optionnel. Ajoute un script si tu veux une logique runtime après/avant le dialogue.',
            value: _optionalValue(_nodeScriptIdController.text),
            onPick: () => _pickScriptBinding(context, project),
          ),
          const SizedBox(height: 6),
          _labeledField(
            context,
            label: 'Message inline (optionnel)',
            helper:
                'Utilise ce champ pour un texte rapide. Pour des conversations complètes, privilégie Dialogue Yarn.',
            controller: _nodeMessageController,
            placeholder: 'Le professeur n’est pas encore prêt.',
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: 8),
          _quickHelpCard(
            context,
            title: 'Common pattern',
            lines: const <String>[
              'Start -> Dialogue -> End',
            ],
          ),
        ];
      case ScenarioNodeType.action:
        return <Widget>[
          _actionPickerField(
            context,
            referenceMode: false,
            selectedPreset: actionPreset,
          ),
          const SizedBox(height: 6),
          if (actionPreset != null)
            _helpCard(
              context,
              title: actionPreset.label,
              description:
                  '${actionPreset.description}\n${actionPreset.executionHint}\n${scenarioRuntimeSupportLabel(actionPreset.runtimeSupport)}',
              accent: EditorChrome.inspectorJoyCyan,
            ),
          const SizedBox(height: 6),
          _quickHelpCard(
            context,
            title: 'Usages courants',
            lines: const <String>[
              'Entrée zone -> dialogue : Action = Ouvrir un dialogue, puis choisis le dialogue.',
              'Parler à un PNJ -> séquence : Action = Exécuter un script.',
              'Combat dresseur : Action = Démarrer un combat dresseur + Trainer.',
              'Activer quelque chose en map : Action = Trigger / Event / Warp + Map.',
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _tinyInsertButton(
                context,
                label: 'Preset entrée zone → dialogue',
                onPressed: () {
                  _nodeActionKindController.text = 'openDialogue';
                  setState(() {});
                },
              ),
              _tinyInsertButton(
                context,
                label: 'Preset PNJ → script',
                onPressed: () {
                  _nodeActionKindController.text = 'runScript';
                  setState(() {});
                },
              ),
              _tinyInsertButton(
                context,
                label: 'Preset combat dresseur',
                onPressed: () {
                  _nodeActionKindController.text = 'startTrainerBattle';
                  setState(() {});
                },
              ),
            ],
          ),
          if (actionPreset != null) ...[
            const SizedBox(height: 6),
            ..._buildFieldsForActionPreset(
              context,
              state: state,
              project: project,
              preset: actionPreset,
            ),
          ],
          const SizedBox(height: 8),
          _quickHelpCard(
            context,
            title: 'How to use this node',
            lines: const <String>[
              'Choisis une action claire puis remplis uniquement les champs affichés.',
              'Les ressources sont proposées en dropdowns pour éviter la saisie manuelle d’IDs.',
            ],
          ),
        ];
      case ScenarioNodeType.condition:
        return <Widget>[
          _conditionModePicker(context),
          const SizedBox(height: 6),
          _helpCard(
            context,
            title: _conditionModeLabel(_conditionMode),
            description: _conditionModeDescription(_conditionMode),
            accent: EditorChrome.inspectorJoyAmber,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _tinyInsertButton(
                context,
                label: 'Preset flag actif',
                onPressed: () {
                  setState(() {
                    _conditionMode = _ScenarioConditionMode.flagSet;
                  });
                },
              ),
              _tinyInsertButton(
                context,
                label: 'Preset event consommé',
                onPressed: () {
                  setState(() {
                    _conditionMode = _ScenarioConditionMode.eventConsumed;
                  });
                },
              ),
              _tinyInsertButton(
                context,
                label: 'Preset player sur map',
                onPressed: () {
                  setState(() {
                    _conditionMode = _ScenarioConditionMode.playerOnMap;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          ..._buildFieldsForConditionMode(
            context,
            state: state,
            project: project,
          ),
          const SizedBox(height: 8),
          _quickHelpCard(
            context,
            title: 'Common patterns',
            lines: const <String>[
              'Start -> Condition -> branche A / branche B',
              'Flag actif -> branche progression ; flag inactif -> branche blocage',
              'Entrée en zone -> vérifier un flag puis ouvrir un dialogue dans la branche vraie.',
            ],
          ),
        ];
      case ScenarioNodeType.choice:
        return <Widget>[
          _quickHelpCard(
            context,
            title: 'How to use this node',
            lines: const <String>[
              'Ajoute plusieurs liens sortants.',
              'Donne un label clair à chaque lien (ex: Oui, Non, Plus tard).',
              'Le gameplay peut ensuite mapper ces labels à des choix joueur.',
            ],
          ),
        ];
      case ScenarioNodeType.reference:
        return <Widget>[
          _actionPickerField(
            context,
            referenceMode: true,
            selectedPreset: actionPreset,
          ),
          const SizedBox(height: 6),
          if (actionPreset != null)
            _helpCard(
              context,
              title: actionPreset.label,
              description:
                  '${actionPreset.description}\n${actionPreset.executionHint}\n${scenarioRuntimeSupportLabel(actionPreset.runtimeSupport)}',
              accent: EditorChrome.inspectorJoyBlue,
            ),
          const SizedBox(height: 6),
          _quickHelpCard(
            context,
            title: 'Usages courants',
            lines: const <String>[
              'Parler à un PNJ : Référence entité + map.',
              'Lier une entrée de bâtiment : Référence warp + map.',
              'Lier un déclencheur de zone : Référence trigger + map.',
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _tinyInsertButton(
                context,
                label: 'Preset référence PNJ',
                onPressed: () {
                  _nodeActionKindController.text = 'referenceEntity';
                  setState(() {});
                },
              ),
              _tinyInsertButton(
                context,
                label: 'Preset référence event',
                onPressed: () {
                  _nodeActionKindController.text = 'referenceEvent';
                  setState(() {});
                },
              ),
              _tinyInsertButton(
                context,
                label: 'Preset référence trigger',
                onPressed: () {
                  _nodeActionKindController.text = 'referenceTrigger';
                  setState(() {});
                },
              ),
            ],
          ),
          if (actionPreset != null) ...[
            const SizedBox(height: 6),
            ..._buildFieldsForActionPreset(
              context,
              state: state,
              project: project,
              preset: actionPreset,
            ),
          ],
          const SizedBox(height: 8),
          _quickHelpCard(
            context,
            title: 'How to use this node',
            lines: const <String>[
              'Reference peut documenter une ressource monde OU jouer le rôle de source de déclenchement.',
              'Pour un déclencheur explicite, utilise les presets "Déclencheur : ...".',
              'Choisis une map puis un event/entity/warp/trigger si nécessaire.',
            ],
          ),
        ];
    }
  }

  Widget _buildOutgoingEdges(
    BuildContext context, {
    required EditorNotifier notifier,
    required ScenarioAsset scenario,
    required ScenarioNode node,
  }) {
    final outgoing = scenario.edges
        .where((edge) => edge.fromNodeId == node.id)
        .toList(growable: false);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.08),
        ),
        border: Border.all(
          color: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Liens sortants',
                    style: TextStyle(
                      color: CupertinoColors.label.resolveFrom(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                EditorToolbarIconButton(
                  icon: CupertinoIcons.link,
                  tooltip: 'Créer une connexion',
                  onPressed: () =>
                      _pickTargetNodeForLink(context, notifier, scenario, node),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (outgoing.isEmpty)
              Text(
                'Aucun lien sortant.',
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontSize: 11,
                ),
              )
            else
              ...outgoing.map(
                (edge) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: EditorChrome.largeIslandSurfaceColor(
                        context,
                        tint: EditorChrome.inspectorJoyBlue
                            .withValues(alpha: 0.07),
                      ),
                      border: Border.all(
                        color: EditorChrome.editorIslandRim(context),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${edge.id} → ${edge.toNodeId}${edge.label.trim().isEmpty ? '' : ' · ${edge.label}'}',
                              style: TextStyle(
                                color:
                                    CupertinoColors.label.resolveFrom(context),
                                fontSize: 11,
                              ),
                            ),
                          ),
                          EditorToolbarIconButton(
                            icon: CupertinoIcons.delete,
                            tooltip: 'Supprimer la connexion',
                            onPressed: () => notifier.deleteScenarioEdge(
                              scenarioId: scenario.id,
                              edgeId: edge.id,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _readonlyLine(BuildContext context, String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: CupertinoColors.label.resolveFrom(context),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _bindingPickerField(
    BuildContext context, {
    required String title,
    required String helper,
    required String? value,
    required VoidCallback onPick,
    bool enabled = true,
    String? disabledHelper,
  }) {
    final effective = value == null || value.trim().isEmpty ? 'Aucune' : value;
    final effectiveHelper =
        enabled ? helper : (disabledHelper ?? 'Champ indisponible');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          minimumSize: const Size(0, 30),
          color: EditorChrome.largeIslandSurfaceColor(
            context,
            tint: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.12),
          ),
          onPressed: enabled ? onPick : null,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              effective,
              style: TextStyle(
                color: CupertinoColors.label.resolveFrom(context),
                fontSize: 11,
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          effectiveHelper,
          style: TextStyle(
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }

  Widget _labeledField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    String? placeholder,
    String? helper,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          minLines: minLines,
          maxLines: maxLines,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          inputFormatters: const [],
        ),
        if (helper != null && helper.trim().isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            helper,
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              fontSize: 10.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _suggestedTextField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required String helper,
    required List<String> suggestions,
    required String pickerTitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labeledField(
          context,
          label: label,
          controller: controller,
          placeholder: placeholder,
          helper: helper,
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 4),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: const Size(0, 24),
            color: EditorChrome.largeIslandSurfaceColor(
              context,
              tint: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.1),
            ),
            onPressed: () => _pickSuggestedTextValue(
              context,
              title: pickerTitle,
              suggestions: suggestions,
              controller: controller,
            ),
            child: Text(
              'Choisir une valeur existante (${suggestions.length})',
              style: TextStyle(
                fontSize: 10.5,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickSuggestedTextValue(
    BuildContext context, {
    required String title,
    required List<String> suggestions,
    required TextEditingController controller,
  }) async {
    final items = <String?>[null, ...suggestions];
    final picked = await showCupertinoListPicker<String?>(
      context: context,
      title: title,
      items: items,
      labelOf: (value) => value ?? 'Effacer la valeur',
    );
    if (!mounted) return;
    controller.text = picked ?? '';
    setState(() {});
  }

  List<String> _knownFlagSuggestions(ProjectManifest project) {
    final values = <String>{};
    for (final scenario in project.scenarios) {
      for (final node in scenario.nodes) {
        final bindingFlag = node.binding.flagName?.trim() ?? '';
        if (bindingFlag.isNotEmpty) {
          values.add(bindingFlag);
        }
        final paramFlag =
            node.payload.params[ScriptConditionParams.flagName]?.trim() ?? '';
        if (paramFlag.isNotEmpty) {
          values.add(paramFlag);
        }
        _collectConditionSuggestions(
          node.payload.condition,
          flags: values,
          variables: <String>{},
        );
      }
    }
    final sorted = values.toList(growable: false)..sort();
    return sorted;
  }

  List<String> _knownVariableSuggestions(ProjectManifest project) {
    final values = <String>{};
    for (final scenario in project.scenarios) {
      for (final node in scenario.nodes) {
        final bindingVariable = node.binding.variableName?.trim() ?? '';
        if (bindingVariable.isNotEmpty) {
          values.add(bindingVariable);
        }
        final paramVariable =
            node.payload.params[ScriptConditionParams.variableName]?.trim() ??
                '';
        if (paramVariable.isNotEmpty) {
          values.add(paramVariable);
        }
        _collectConditionSuggestions(
          node.payload.condition,
          flags: <String>{},
          variables: values,
        );
      }
    }
    final sorted = values.toList(growable: false)..sort();
    return sorted;
  }

  void _collectConditionSuggestions(
    ScriptCondition? condition, {
    required Set<String> flags,
    required Set<String> variables,
  }) {
    if (condition == null) {
      return;
    }
    final flag = condition.params[ScriptConditionParams.flagName]?.trim() ?? '';
    if (flag.isNotEmpty) {
      flags.add(flag);
    }
    final variable =
        condition.params[ScriptConditionParams.variableName]?.trim() ?? '';
    if (variable.isNotEmpty) {
      variables.add(variable);
    }
    for (final child in condition.children) {
      _collectConditionSuggestions(
        child,
        flags: flags,
        variables: variables,
      );
    }
  }

  bool get _hasSelectedMapBinding =>
      _nodeMapIdController.text.trim().isNotEmpty;

  Widget _helpCard(
    BuildContext context, {
    required String title,
    required String description,
    required Color accent,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: accent.withValues(alpha: 0.09),
        ),
        border: Border.all(color: accent.withValues(alpha: 0.44)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: CupertinoColors.label.resolveFrom(context),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              description,
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 11,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickHelpCard(
    BuildContext context, {
    required String title,
    required List<String> lines,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyMint.withValues(alpha: 0.06),
        ),
        border: Border.all(
          color: EditorChrome.inspectorJoyMint.withValues(alpha: 0.28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: CupertinoColors.label.resolveFrom(context),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '• $line',
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _mapContextCard(
    BuildContext context, {
    required EditorState state,
    required ProjectManifest project,
  }) {
    final mapId = _nodeMapIdController.text.trim();
    if (mapId.isEmpty) {
      return _helpCard(
        context,
        title: 'Contexte map',
        description:
            'Choisis d’abord une map pour afficher les events, entités, warps et triggers disponibles.',
        accent: EditorChrome.inspectorJoyBlue,
      );
    }
    return FutureBuilder<MapData?>(
      future: _loadMapById(state: state, project: project, mapId: mapId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _helpCard(
            context,
            title: 'Contexte map',
            description: 'Chargement de la map "$mapId"...',
            accent: EditorChrome.inspectorJoyBlue,
          );
        }
        final map = snapshot.data;
        if (map == null) {
          return _helpCard(
            context,
            title: 'Contexte map',
            description:
                'Impossible de charger "$mapId". Vérifie la map sélectionnée.',
            accent: EditorChrome.inspectorJoyCoral,
          );
        }
        return _quickHelpCard(
          context,
          title: 'Contenu de map : ${map.name} (${map.id})',
          lines: <String>[
            'Events : ${map.events.length}',
            '  ${_previewMapItemLabels(map.events.map((event) => event.id))}',
            'Entités : ${map.entities.length}',
            '  ${_previewMapItemLabels(map.entities.map((entity) => entity.id))}',
            'Warps : ${map.warps.length}',
            '  ${_previewMapItemLabels(map.warps.map((warp) => warp.id))}',
            'Triggers : ${map.triggers.length}',
            '  ${_previewMapItemLabels(map.triggers.map((trigger) => trigger.id))}',
          ],
        );
      },
    );
  }

  String _previewMapItemLabels(Iterable<String> ids) {
    final nonBlank = ids
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    if (nonBlank.isEmpty) {
      return 'Aucun élément';
    }
    if (nonBlank.length <= 3) {
      return nonBlank.join(', ');
    }
    final first = nonBlank.take(3).join(', ');
    return '$first …';
  }

  Widget _actionPickerField(
    BuildContext context, {
    required bool referenceMode,
    required ScenarioActionPreset? selectedPreset,
  }) {
    final title = referenceMode ? 'Type de référence' : 'Action';
    final helper = referenceMode
        ? 'Le node est de type Reference. Ce champ précise la ressource cible.'
        : 'Le node est de type Action. Ce champ précise l’effet concret.';
    final value = selectedPreset?.label ??
        (_nodeActionKindController.text.trim().isEmpty
            ? 'Aucune'
            : _nodeActionKindController.text.trim());
    return _bindingPickerField(
      context,
      title: title,
      helper: helper,
      value: value,
      onPick: () => _pickActionPreset(context, referenceMode: referenceMode),
    );
  }

  Widget _conditionModePicker(BuildContext context) {
    return _bindingPickerField(
      context,
      title: 'Mode de condition',
      helper: 'Choisis une condition simple ou passe en JSON brut avancé.',
      value: _conditionModeLabel(_conditionMode),
      onPick: () async {
        final picked = await showCupertinoListPicker<_ScenarioConditionMode>(
          context: context,
          title: 'Mode de condition',
          items: _ScenarioConditionMode.values,
          labelOf: (value) =>
              '${_conditionModeLabel(value)} — ${_conditionModeDescription(value)}',
        );
        if (picked == null || !mounted) return;
        setState(() {
          _conditionMode = picked;
        });
      },
    );
  }

  List<Widget> _buildFieldsForActionPreset(
    BuildContext context, {
    required EditorState state,
    required ProjectManifest project,
    required ScenarioActionPreset preset,
  }) {
    final knownFlags = _knownFlagSuggestions(project);
    final knownVariables = _knownVariableSuggestions(project);
    final widgets = <Widget>[];
    if (preset.fields.contains(ScenarioActionField.message)) {
      widgets.add(
        _labeledField(
          context,
          label: 'Message',
          controller: _nodeMessageController,
          placeholder: 'Le professeur n’est pas encore prêt.',
          helper: 'Message court affiché en runtime.',
          minLines: 2,
          maxLines: 4,
        ),
      );
    }
    if (preset.fields.contains(ScenarioActionField.dialogue)) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 6));
      widgets.add(
        _bindingPickerField(
          context,
          title: 'Dialogue',
          helper: 'Choisis un dialogue Yarn existant.',
          value: _optionalValue(_nodeDialogueIdController.text),
          onPick: () => _pickDialogueBinding(context, project),
        ),
      );
    }
    if (preset.fields.contains(ScenarioActionField.script)) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 6));
      widgets.add(
        _bindingPickerField(
          context,
          title: 'Script',
          helper: 'Choisis un script scénario/runtime existant.',
          value: _optionalValue(_nodeScriptIdController.text),
          onPick: () => _pickScriptBinding(context, project),
        ),
      );
    }
    if (preset.fields.contains(ScenarioActionField.trainer)) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 6));
      widgets.add(
        _bindingPickerField(
          context,
          title: 'Trainer',
          helper: 'Choisis le dresseur concerné.',
          value: _optionalValue(_nodeTrainerIdController.text),
          onPick: () => _pickTrainerBinding(context, project),
        ),
      );
    }
    if (preset.fields.contains(ScenarioActionField.map)) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 6));
      widgets.add(
        _bindingPickerField(
          context,
          title: 'Map',
          helper:
              'Les sélecteurs Event / Entity / Warp / Trigger seront filtrés par cette map.',
          value: _optionalValue(_nodeMapIdController.text),
          onPick: () => _pickMapBinding(context, project),
        ),
      );
    }
    if (preset.fields.contains(ScenarioActionField.event)) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 6));
      widgets.add(
        _bindingPickerField(
          context,
          title: 'Event ID',
          helper: 'Choisis un event existant sur la map sélectionnée.',
          enabled: _hasSelectedMapBinding,
          disabledHelper: 'Choisis d’abord une map.',
          value: _optionalValue(_nodeEventIdController.text),
          onPick: () => _pickMapEventBinding(context, state, project),
        ),
      );
    }
    if (preset.fields.contains(ScenarioActionField.entity)) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 6));
      widgets.add(
        _bindingPickerField(
          context,
          title: 'Entity ID',
          helper: 'Choisis une entité existante sur la map sélectionnée.',
          enabled: _hasSelectedMapBinding,
          disabledHelper: 'Choisis d’abord une map.',
          value: _optionalValue(_nodeEntityIdController.text),
          onPick: () => _pickMapEntityBinding(context, state, project),
        ),
      );
    }
    if (preset.fields.contains(ScenarioActionField.warp)) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 6));
      widgets.add(
        _bindingPickerField(
          context,
          title: 'Warp ID',
          helper: 'Choisis un warp existant sur la map sélectionnée.',
          enabled: _hasSelectedMapBinding,
          disabledHelper: 'Choisis d’abord une map.',
          value: _optionalValue(_nodeWarpIdController.text),
          onPick: () => _pickMapWarpBinding(context, state, project),
        ),
      );
    }
    if (preset.fields.contains(ScenarioActionField.trigger)) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 6));
      widgets.add(
        _bindingPickerField(
          context,
          title: 'Trigger ID',
          helper: 'Choisis un trigger existant sur la map sélectionnée.',
          enabled: _hasSelectedMapBinding,
          disabledHelper: 'Choisis d’abord une map.',
          value: _optionalValue(_nodeTriggerIdController.text),
          onPick: () => _pickMapTriggerBinding(context, state, project),
        ),
      );
    }
    if (preset.fields.contains(ScenarioActionField.flagName)) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 6));
      widgets.add(
        _suggestedTextField(
          context,
          label: 'Flag Name',
          controller: _nodeFlagNameController,
          placeholder: 'story.got_starter',
          helper: 'Nom du flag persistant à modifier.',
          suggestions: knownFlags,
          pickerTitle: 'Flags connus (scénarios)',
        ),
      );
    }
    if (preset.fields.contains(ScenarioActionField.variableName)) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 6));
      widgets.add(
        _suggestedTextField(
          context,
          label: 'Variable Name',
          controller: _nodeVariableNameController,
          placeholder: 'quest.professor.progress',
          helper: 'Variable persistante liée à la progression.',
          suggestions: knownVariables,
          pickerTitle: 'Variables connues (scénarios)',
        ),
      );
    }
    if (preset.fields.contains(ScenarioActionField.variableValue)) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 6));
      widgets.add(
        _labeledField(
          context,
          label: 'Variable Value',
          controller: _nodeConditionVariableValueController,
          placeholder: '1',
        ),
      );
    }
    if (preset.fields.contains(ScenarioActionField.map)) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 6));
      widgets.add(
        _mapContextCard(
          context,
          state: state,
          project: project,
        ),
      );
    }
    return widgets;
  }

  List<Widget> _buildFieldsForConditionMode(
    BuildContext context, {
    required EditorState state,
    required ProjectManifest project,
  }) {
    final knownFlags = _knownFlagSuggestions(project);
    final knownVariables = _knownVariableSuggestions(project);
    switch (_conditionMode) {
      case _ScenarioConditionMode.none:
        return <Widget>[
          Text(
            'Aucun champ requis.',
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              fontSize: 11,
            ),
          ),
        ];
      case _ScenarioConditionMode.flagSet:
        return <Widget>[
          _suggestedTextField(
            context,
            label: 'Flag Name',
            controller: _nodeConditionFlagNameController,
            placeholder: 'story.got_starter',
            helper: 'Ex: story.got_starter',
            suggestions: knownFlags,
            pickerTitle: 'Flags connus (scénarios)',
          ),
        ];
      case _ScenarioConditionMode.flagUnset:
        return <Widget>[
          _suggestedTextField(
            context,
            label: 'Flag Name',
            controller: _nodeConditionFlagNameController,
            placeholder: 'story.got_starter',
            helper: 'La condition sera vraie tant que ce flag n’est pas actif.',
            suggestions: knownFlags,
            pickerTitle: 'Flags connus (scénarios)',
          ),
        ];
      case _ScenarioConditionMode.eventConsumed:
        return <Widget>[
          _bindingPickerField(
            context,
            title: 'Map',
            helper:
                'Choisis la map pour filtrer la liste des events existants.',
            value: _optionalValue(_nodeMapIdController.text),
            onPick: () => _pickMapBinding(context, project),
          ),
          const SizedBox(height: 6),
          _bindingPickerField(
            context,
            title: 'Event ID',
            helper: 'Event consommé à tester.',
            enabled: _hasSelectedMapBinding,
            disabledHelper: 'Choisis d’abord une map.',
            value: _optionalValue(_nodeEventIdController.text),
            onPick: () => _pickMapEventBinding(context, state, project),
          ),
          const SizedBox(height: 6),
          _mapContextCard(
            context,
            state: state,
            project: project,
          ),
        ];
      case _ScenarioConditionMode.playerOnMap:
        return <Widget>[
          _bindingPickerField(
            context,
            title: 'Map',
            helper: 'La condition est vraie si le joueur est sur cette map.',
            value: _optionalValue(_nodeMapIdController.text),
            onPick: () => _pickMapBinding(context, project),
          ),
          const SizedBox(height: 6),
          _mapContextCard(
            context,
            state: state,
            project: project,
          ),
        ];
      case _ScenarioConditionMode.variableEquals:
        return <Widget>[
          _suggestedTextField(
            context,
            label: 'Variable Name',
            controller: _nodeConditionVariableNameController,
            placeholder: 'quest.professor.progress',
            helper: 'Variable persistante à comparer.',
            suggestions: knownVariables,
            pickerTitle: 'Variables connues (scénarios)',
          ),
          const SizedBox(height: 6),
          _labeledField(
            context,
            label: 'Value',
            controller: _nodeConditionVariableValueController,
            placeholder: '2',
            helper: 'Comparaison en string. Exemple courant: 0, 1, 2, done.',
          ),
        ];
      case _ScenarioConditionMode.rawJson:
        return <Widget>[
          _labeledField(
            context,
            label: 'Condition JSON',
            controller: _nodeConditionJsonController,
            placeholder:
                '{"type":"flagIsSet","params":{"flagName":"story.got_starter"}}',
            helper:
                'Mode avancé pour allOf / anyOf / not. Colle uniquement un objet ScriptCondition.',
            minLines: 4,
            maxLines: 9,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _tinyInsertButton(
                context,
                label: 'Exemple flag set',
                onPressed: () {
                  _nodeConditionJsonController.text =
                      const JsonEncoder.withIndent(
                    '  ',
                  ).convert(
                    ScriptConditionFactory.flagIsSet('story.got_starter')
                        .toJson(),
                  );
                  setState(() {});
                },
              ),
              _tinyInsertButton(
                context,
                label: 'Exemple not(eventConsumed)',
                onPressed: () {
                  final condition = ScriptConditionFactory.not(
                    ScriptConditionFactory.eventIsConsumed('event_intro'),
                  );
                  _nodeConditionJsonController.text =
                      const JsonEncoder.withIndent(
                    '  ',
                  ).convert(condition.toJson());
                  setState(() {});
                },
              ),
            ],
          ),
        ];
    }
  }

  Widget _tinyInsertButton(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
  }) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      minimumSize: const Size(0, 24),
      color: EditorChrome.largeIslandSurfaceColor(
        context,
        tint: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.1),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: CupertinoColors.label.resolveFrom(context),
        ),
      ),
    );
  }

  Widget _buildAdvancedNodeSection(
    BuildContext context, {
    required EditorState state,
    required ProjectManifest project,
    required ScenarioNode node,
  }) {
    final knownFlags = _knownFlagSuggestions(project);
    final knownVariables = _knownVariableSuggestions(project);
    final referenceMode = node.type == ScenarioNodeType.reference;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.05),
        ),
        border: Border.all(
          color: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.32),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Advanced',
                    style: TextStyle(
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                CupertinoButton(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(0, 24),
                  color: EditorChrome.largeIslandSurfaceColor(
                    context,
                    tint: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.1),
                  ),
                  onPressed: () {
                    setState(() {
                      _showAdvancedNodeFields = !_showAdvancedNodeFields;
                    });
                  },
                  child: Text(
                    _showAdvancedNodeFields ? 'Masquer' : 'Afficher',
                    style: TextStyle(
                      fontSize: 11,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              'Mode avancé assisté: garde les champs raw, mais avec pickers guidés pour éviter la saisie manuelle d’IDs.',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 10.5,
              ),
            ),
            if (_showAdvancedNodeFields) ...[
              const SizedBox(height: 8),
              _quickHelpCard(
                context,
                title: 'Mode assisté + brut',
                lines: const <String>[
                  'Utilise les pickers ci-dessous en priorité.',
                  'Les champs raw restent disponibles pour les cas spéciaux.',
                  'Map sélectionnée = filtrage automatique des Event/Entity/Warp/Trigger.',
                ],
              ),
              const SizedBox(height: 6),
              _bindingPickerField(
                context,
                title: 'Action/Reference preset (assisté)',
                helper: 'Choisis un preset puis ajuste en raw si nécessaire.',
                value: _optionalValue(_nodeActionKindController.text),
                onPick: () =>
                    _pickActionPreset(context, referenceMode: referenceMode),
              ),
              const SizedBox(height: 6),
              _bindingPickerField(
                context,
                title: 'Script (assisté)',
                helper: 'Sélectionne un script connu.',
                value: _optionalValue(_nodeScriptIdController.text),
                onPick: () => _pickScriptBinding(context, project),
              ),
              const SizedBox(height: 6),
              _bindingPickerField(
                context,
                title: 'Dialogue (assisté)',
                helper: 'Sélectionne un dialogue connu.',
                value: _optionalValue(_nodeDialogueIdController.text),
                onPick: () => _pickDialogueBinding(context, project),
              ),
              const SizedBox(height: 6),
              _bindingPickerField(
                context,
                title: 'Map (assisté)',
                helper: 'Débloque les pickers Event/Entity/Warp/Trigger.',
                value: _optionalValue(_nodeMapIdController.text),
                onPick: () => _pickMapBinding(context, project),
              ),
              const SizedBox(height: 6),
              _bindingPickerField(
                context,
                title: 'Event (assisté)',
                helper: 'Filtré par la map sélectionnée.',
                enabled: _hasSelectedMapBinding,
                disabledHelper: 'Choisis d’abord une map.',
                value: _optionalValue(_nodeEventIdController.text),
                onPick: () => _pickMapEventBinding(context, state, project),
              ),
              const SizedBox(height: 6),
              _bindingPickerField(
                context,
                title: 'Entity (assisté)',
                helper: 'Filtré par la map sélectionnée.',
                enabled: _hasSelectedMapBinding,
                disabledHelper: 'Choisis d’abord une map.',
                value: _optionalValue(_nodeEntityIdController.text),
                onPick: () => _pickMapEntityBinding(context, state, project),
              ),
              const SizedBox(height: 6),
              _bindingPickerField(
                context,
                title: 'Warp (assisté)',
                helper: 'Filtré par la map sélectionnée.',
                enabled: _hasSelectedMapBinding,
                disabledHelper: 'Choisis d’abord une map.',
                value: _optionalValue(_nodeWarpIdController.text),
                onPick: () => _pickMapWarpBinding(context, state, project),
              ),
              const SizedBox(height: 6),
              _bindingPickerField(
                context,
                title: 'Trigger (assisté)',
                helper: 'Filtré par la map sélectionnée.',
                enabled: _hasSelectedMapBinding,
                disabledHelper: 'Choisis d’abord une map.',
                value: _optionalValue(_nodeTriggerIdController.text),
                onPick: () => _pickMapTriggerBinding(context, state, project),
              ),
              const SizedBox(height: 6),
              _bindingPickerField(
                context,
                title: 'Trainer (assisté)',
                helper: 'Sélectionne un dresseur connu.',
                value: _optionalValue(_nodeTrainerIdController.text),
                onPick: () => _pickTrainerBinding(context, project),
              ),
              const SizedBox(height: 6),
              _suggestedTextField(
                context,
                label: 'Flag Name (assisté)',
                controller: _nodeFlagNameController,
                placeholder: 'story.got_starter',
                helper: 'Suggestions basées sur les scénarios existants.',
                suggestions: knownFlags,
                pickerTitle: 'Flags connus (scénarios)',
              ),
              const SizedBox(height: 6),
              _suggestedTextField(
                context,
                label: 'Variable Name (assisté)',
                controller: _nodeVariableNameController,
                placeholder: 'quest.professor.progress',
                helper: 'Suggestions basées sur les scénarios existants.',
                suggestions: knownVariables,
                pickerTitle: 'Variables connues (scénarios)',
              ),
              const SizedBox(height: 8),
              Text(
                'Champs raw (fallback expert)',
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              _labeledField(
                context,
                label: 'Script ID (raw)',
                controller: _nodeScriptIdController,
                placeholder: 'script_intro_professor',
              ),
              const SizedBox(height: 6),
              _labeledField(
                context,
                label: 'Dialogue ID (raw)',
                controller: _nodeDialogueIdController,
                placeholder: 'dialogue_intro_lab',
              ),
              const SizedBox(height: 6),
              _labeledField(
                context,
                label: 'Map ID (raw)',
                controller: _nodeMapIdController,
                placeholder: 'vova_center',
              ),
              const SizedBox(height: 6),
              _labeledField(
                context,
                label: 'Event ID (raw)',
                controller: _nodeEventIdController,
                placeholder: 'event_intro_lab',
              ),
              const SizedBox(height: 6),
              _labeledField(
                context,
                label: 'Entity ID (raw)',
                controller: _nodeEntityIdController,
                placeholder: 'npc_professor',
              ),
              const SizedBox(height: 6),
              _labeledField(
                context,
                label: 'Warp ID (raw)',
                controller: _nodeWarpIdController,
                placeholder: 'lab_entry',
              ),
              const SizedBox(height: 6),
              _labeledField(
                context,
                label: 'Trigger ID (raw)',
                controller: _nodeTriggerIdController,
                placeholder: 'trigger_intro_start',
              ),
              const SizedBox(height: 6),
              _labeledField(
                context,
                label: 'Trainer ID (raw)',
                controller: _nodeTrainerIdController,
                placeholder: 'trainer_rival_001',
              ),
              const SizedBox(height: 6),
              _labeledField(
                context,
                label: 'Flag Name (raw)',
                controller: _nodeFlagNameController,
                placeholder: 'story.got_starter',
              ),
              const SizedBox(height: 6),
              _labeledField(
                context,
                label: 'Variable Name (raw)',
                controller: _nodeVariableNameController,
                placeholder: 'quest.professor.progress',
              ),
              const SizedBox(height: 6),
              _labeledField(
                context,
                label: 'Action Kind (raw)',
                controller: _nodeActionKindController,
                placeholder: node.type == ScenarioNodeType.reference
                    ? 'referenceEvent'
                    : 'showMessage',
              ),
              if (node.type == ScenarioNodeType.condition) ...[
                const SizedBox(height: 6),
                _labeledField(
                  context,
                  label: 'Condition JSON (raw)',
                  controller: _nodeConditionJsonController,
                  placeholder: '{"type":"allOf","children":[...]}',
                  minLines: 4,
                  maxLines: 8,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _promptCreateScenario(
    BuildContext context,
    EditorNotifier notifier,
  ) async {
    final controller = TextEditingController();
    final ok = await showMacosEditorPromptSheet(
      context,
      title: 'Nouveau Scenario Graph',
      controller: controller,
      confirmLabel: 'Créer',
      placeholder: 'Nom du scénario',
    );
    if (!ok || !context.mounted) return;
    final name = controller.text.trim();
    if (name.isEmpty) return;
    await notifier.createProjectScenario(name: name);
  }

  Future<void> _promptRenameScenario(
    BuildContext context,
    EditorNotifier notifier,
    ScenarioAsset scenario,
  ) async {
    final controller = TextEditingController(text: scenario.name);
    final ok = await showMacosEditorPromptSheet(
      context,
      title: 'Renommer le scénario',
      controller: controller,
      confirmLabel: 'Enregistrer',
      placeholder: 'Nom',
    );
    if (!ok || !context.mounted) return;
    final name = controller.text.trim();
    if (name.isEmpty) return;
    await notifier.renameProjectScenario(scenarioId: scenario.id, name: name);
  }

  Future<void> _confirmDeleteScenario(
    BuildContext context,
    EditorNotifier notifier,
    ScenarioAsset scenario,
  ) async {
    final confirm = await showMacosEditorTwoChoiceAlert(
      context,
      title: 'Supprimer ce scénario ?',
      message:
          'Cette action supprime "${scenario.name}" et tout son graphe (nœuds + connexions).',
      primaryLabel: 'Supprimer',
      primaryIsDestructive: true,
    );
    if (!confirm || !context.mounted) return;
    await notifier.deleteProjectScenario(scenario.id);
  }

  Future<void> _promptAddNode(
    BuildContext context,
    EditorNotifier notifier,
    ScenarioAsset scenario,
  ) async {
    final type = await showCupertinoListPicker<ScenarioNodeType>(
      context: context,
      title: 'Type de node',
      items: ScenarioNodeType.values,
      labelOf: scenarioNodeTypePickerLabel,
    );
    if (type == null || !context.mounted) return;
    final titleController =
        TextEditingController(text: defaultScenarioNodeTitle(type));
    final ok = await showMacosEditorPromptSheet(
      context,
      title: 'Ajouter un node ${scenarioNodeTypeLabel(type)}',
      controller: titleController,
      confirmLabel: 'Ajouter',
      placeholder: 'Titre du node',
    );
    if (!ok || !context.mounted) return;
    final title = titleController.text.trim();
    if (title.isEmpty) return;
    await notifier.addScenarioNode(
      scenarioId: scenario.id,
      type: type,
      title: title,
    );
  }

  Future<void> _pickNodeType(
    BuildContext context,
    EditorNotifier notifier,
    ScenarioAsset scenario,
    ScenarioNode node,
  ) async {
    final type = await showCupertinoListPicker<ScenarioNodeType>(
      context: context,
      title: 'Type de node',
      items: ScenarioNodeType.values,
      labelOf: scenarioNodeTypePickerLabel,
    );
    if (type == null || !context.mounted) return;
    await notifier.updateScenarioNode(
      scenarioId: scenario.id,
      node: node.copyWith(type: type),
    );
  }

  Future<void> _pickScriptBinding(
    BuildContext context,
    ProjectManifest project,
  ) async {
    final items = <ProjectScriptEntry?>[null, ...project.scripts];
    final picked = await showCupertinoListPicker<ProjectScriptEntry?>(
      context: context,
      title: 'Script binding',
      items: items,
      labelOf: (value) =>
          value == null ? 'Aucun' : '${value.name} (${value.id})',
    );
    if (!mounted) return;
    _nodeScriptIdController.text = picked?.id ?? '';
    setState(() {});
  }

  Future<void> _pickDialogueBinding(
    BuildContext context,
    ProjectManifest project,
  ) async {
    final items = <ProjectDialogueEntry?>[null, ...project.dialogues];
    final picked = await showCupertinoListPicker<ProjectDialogueEntry?>(
      context: context,
      title: 'Dialogue binding',
      items: items,
      labelOf: (value) =>
          value == null ? 'Aucun' : '${value.name} (${value.id})',
    );
    if (!mounted) return;
    _nodeDialogueIdController.text = picked?.id ?? '';
    setState(() {});
  }

  Future<void> _pickTrainerBinding(
    BuildContext context,
    ProjectManifest project,
  ) async {
    final items = <ProjectTrainerEntry?>[null, ...project.trainers];
    final picked = await showCupertinoListPicker<ProjectTrainerEntry?>(
      context: context,
      title: 'Trainer binding',
      items: items,
      labelOf: (value) =>
          value == null ? 'Aucun' : '${value.name} (${value.id})',
    );
    if (!mounted) return;
    _nodeTrainerIdController.text = picked?.id ?? '';
    setState(() {});
  }

  Future<void> _pickMapBinding(
    BuildContext context,
    ProjectManifest project,
  ) async {
    final items = <ProjectMapEntry?>[null, ...project.maps];
    final picked = await showCupertinoListPicker<ProjectMapEntry?>(
      context: context,
      title: 'Map binding',
      items: items,
      labelOf: (value) =>
          value == null ? 'Aucune' : '${value.name} (${value.id})',
    );
    if (!mounted) return;
    final previousMapId = _nodeMapIdController.text.trim();
    final nextMapId = picked?.id ?? '';
    _nodeMapIdController.text = nextMapId;
    if (previousMapId != nextMapId) {
      _nodeEventIdController.clear();
      _nodeEntityIdController.clear();
      _nodeWarpIdController.clear();
      _nodeTriggerIdController.clear();
    }
    setState(() {});
  }

  Future<void> _pickMapEventBinding(
    BuildContext context,
    EditorState state,
    ProjectManifest project,
  ) async {
    final map = await _resolveMapFromCurrentMapBinding(
      context,
      state: state,
      project: project,
      pickerLabel: 'event',
    );
    if (map == null || !context.mounted) return;
    if (map.events.isEmpty) {
      await showCupertinoEditorAlert(
        context,
        title: 'Aucun event',
        message: 'La map "${map.name}" ne contient aucun event.',
      );
      return;
    }
    final options = <_ScenarioMapScopedOption?>[
      null,
      ...map.events.map(
        (event) => _ScenarioMapScopedOption(
          id: event.id,
          label:
              '${event.id} — ${event.type.name} — (${event.position.x},${event.position.y})',
        ),
      ),
    ];
    final picked = await showCupertinoListPicker<_ScenarioMapScopedOption?>(
      context: context,
      title: 'Event ID (${map.id})',
      items: options,
      labelOf: (value) => value?.label ?? 'Aucun',
    );
    if (!mounted) return;
    _nodeEventIdController.text = picked?.id ?? '';
    setState(() {});
  }

  Future<void> _pickMapEntityBinding(
    BuildContext context,
    EditorState state,
    ProjectManifest project,
  ) async {
    final map = await _resolveMapFromCurrentMapBinding(
      context,
      state: state,
      project: project,
      pickerLabel: 'entity',
    );
    if (map == null || !context.mounted) return;
    if (map.entities.isEmpty) {
      await showCupertinoEditorAlert(
        context,
        title: 'Aucune entité',
        message: 'La map "${map.name}" ne contient aucune entité.',
      );
      return;
    }
    final options = <_ScenarioMapScopedOption?>[
      null,
      ...map.entities.map(
        (entity) => _ScenarioMapScopedOption(
          id: entity.id,
          label:
              '${entity.id} — ${entity.kind.name} — (${entity.pos.x},${entity.pos.y})',
        ),
      ),
    ];
    final picked = await showCupertinoListPicker<_ScenarioMapScopedOption?>(
      context: context,
      title: 'Entity ID (${map.id})',
      items: options,
      labelOf: (value) => value?.label ?? 'Aucune',
    );
    if (!mounted) return;
    _nodeEntityIdController.text = picked?.id ?? '';
    setState(() {});
  }

  Future<void> _pickMapWarpBinding(
    BuildContext context,
    EditorState state,
    ProjectManifest project,
  ) async {
    final map = await _resolveMapFromCurrentMapBinding(
      context,
      state: state,
      project: project,
      pickerLabel: 'warp',
    );
    if (map == null || !context.mounted) return;
    if (map.warps.isEmpty) {
      await showCupertinoEditorAlert(
        context,
        title: 'Aucun warp',
        message: 'La map "${map.name}" ne contient aucun warp.',
      );
      return;
    }
    final options = <_ScenarioMapScopedOption?>[
      null,
      ...map.warps.map(
        (warp) => _ScenarioMapScopedOption(
          id: warp.id,
          label:
              '${warp.id} — (${warp.pos.x},${warp.pos.y}) -> ${warp.targetMapId}',
        ),
      ),
    ];
    final picked = await showCupertinoListPicker<_ScenarioMapScopedOption?>(
      context: context,
      title: 'Warp ID (${map.id})',
      items: options,
      labelOf: (value) => value?.label ?? 'Aucun',
    );
    if (!mounted) return;
    _nodeWarpIdController.text = picked?.id ?? '';
    setState(() {});
  }

  Future<void> _pickMapTriggerBinding(
    BuildContext context,
    EditorState state,
    ProjectManifest project,
  ) async {
    final map = await _resolveMapFromCurrentMapBinding(
      context,
      state: state,
      project: project,
      pickerLabel: 'trigger',
    );
    if (map == null || !context.mounted) return;
    if (map.triggers.isEmpty) {
      await showCupertinoEditorAlert(
        context,
        title: 'Aucun trigger',
        message: 'La map "${map.name}" ne contient aucun trigger.',
      );
      return;
    }
    final options = <_ScenarioMapScopedOption?>[
      null,
      ...map.triggers.map(
        (trigger) => _ScenarioMapScopedOption(
          id: trigger.id,
          label:
              '${trigger.id} — ${trigger.type.name} — area (${trigger.area.pos.x},${trigger.area.pos.y},${trigger.area.size.width}x${trigger.area.size.height})',
        ),
      ),
    ];
    final picked = await showCupertinoListPicker<_ScenarioMapScopedOption?>(
      context: context,
      title: 'Trigger ID (${map.id})',
      items: options,
      labelOf: (value) => value?.label ?? 'Aucun',
    );
    if (!mounted) return;
    _nodeTriggerIdController.text = picked?.id ?? '';
    setState(() {});
  }

  Future<MapData?> _resolveMapFromCurrentMapBinding(
    BuildContext context, {
    required EditorState state,
    required ProjectManifest project,
    required String pickerLabel,
  }) async {
    final mapId = _nodeMapIdController.text.trim();
    if (mapId.isEmpty) {
      await showCupertinoEditorAlert(
        context,
        title: 'Map requise',
        message:
            'Sélectionne d’abord une map avant de choisir un $pickerLabel.',
      );
      return null;
    }
    final map =
        await _loadMapById(state: state, project: project, mapId: mapId);
    if (map == null) {
      if (!context.mounted) return null;
      await showCupertinoEditorAlert(
        context,
        title: 'Map introuvable',
        message:
            'Impossible de charger la map "$mapId". Vérifie que le projet est bien chargé et que la map existe.',
      );
      return null;
    }
    return map;
  }

  Future<MapData?> _loadMapById({
    required EditorState state,
    required ProjectManifest project,
    required String mapId,
  }) async {
    final normalized = mapId.trim();
    if (normalized.isEmpty) {
      return null;
    }
    final activeMap = state.activeMap;
    if (activeMap != null && activeMap.id == normalized) {
      return activeMap;
    }
    if (_mapCache.containsKey(normalized)) {
      return _mapCache[normalized];
    }
    ProjectMapEntry? mapEntry;
    for (final entry in project.maps) {
      if (entry.id == normalized) {
        mapEntry = entry;
        break;
      }
    }
    if (mapEntry == null) {
      _mapCache[normalized] = null;
      return null;
    }
    final root = state.projectRootPath;
    if (root == null || root.trim().isEmpty) {
      _mapCache[normalized] = null;
      return null;
    }
    final absolutePath = p.join(root, mapEntry.relativePath);
    final repository = ref.read(mapRepositoryProvider);
    try {
      final map = await repository.loadMap(absolutePath);
      _mapCache[normalized] = map;
      return map;
    } catch (_) {
      _mapCache[normalized] = null;
      return null;
    }
  }

  Future<void> _pickActionPreset(
    BuildContext context, {
    required bool referenceMode,
  }) async {
    final source =
        referenceMode ? scenarioReferencePresets : scenarioActionPresets;
    final picked = await showCupertinoListPicker<ScenarioActionPreset>(
      context: context,
      title: referenceMode ? 'Type de référence' : 'Action',
      items: source,
      labelOf: (value) =>
          '${value.label} — ${value.description} (${scenarioRuntimeSupportLabel(value.runtimeSupport)})',
    );
    if (picked == null || !mounted) return;
    _nodeActionKindController.text = picked.id;
    setState(() {});
  }

  Future<void> _pickTargetNodeForLink(
    BuildContext context,
    EditorNotifier notifier,
    ScenarioAsset scenario,
    ScenarioNode node,
  ) async {
    final targets = scenario.nodes
        .where((candidate) => candidate.id != node.id)
        .toList(growable: false);
    if (targets.isEmpty) {
      return;
    }
    final picked = await showCupertinoListPicker<ScenarioNode>(
      context: context,
      title: 'Connecter vers',
      items: targets,
      labelOf: (value) => '${scenarioNodeTypeLabel(value.type)} · ${value.id}',
    );
    if (picked == null || !context.mounted) return;
    final labelController = TextEditingController();
    final ok = await showMacosEditorPromptSheet(
      context,
      title: 'Label de branche (optionnel)',
      controller: labelController,
      confirmLabel: 'Créer',
      placeholder: 'next / yes / no ...',
      compact: true,
    );
    if (!ok || !context.mounted) return;
    await notifier.addScenarioEdge(
      scenarioId: scenario.id,
      fromNodeId: node.id,
      toNodeId: picked.id,
      label: labelController.text.trim(),
    );
  }

  // Ces helpers implémentent des "recettes" d'authoring.
  // L'objectif est de matérialiser des cas d'usage fréquents sans demander
  // à l'utilisateur de composer manuellement chaque node et chaque edge.
  Future<String?> _addScenarioNodeAndResolveId({
    required EditorNotifier notifier,
    required String scenarioId,
    required ScenarioNodeType type,
    required String title,
    required ScenarioNodePosition position,
  }) async {
    final beforeScenario = notifier.getSelectedScenario();
    final beforeIds = <String>{
      if (beforeScenario != null)
        for (final node in beforeScenario.nodes) node.id,
    };
    await notifier.addScenarioNode(
      scenarioId: scenarioId,
      type: type,
      title: title,
      position: position,
    );
    final afterScenario = notifier.getSelectedScenario();
    if (afterScenario != null) {
      for (final node in afterScenario.nodes.reversed) {
        if (!beforeIds.contains(node.id)) {
          return node.id;
        }
      }
    }
    return null;
  }

  ScenarioNode? _findScenarioNodeById(EditorNotifier notifier, String nodeId) {
    final scenario = notifier.getSelectedScenario();
    if (scenario == null) {
      return null;
    }
    for (final node in scenario.nodes) {
      if (node.id == nodeId) {
        return node;
      }
    }
    return null;
  }

  ScenarioNodePosition _recipeNodePosition(ScenarioNode origin, int step) {
    return ScenarioNodePosition(
      x: origin.position.x + (250 * step),
      y: origin.position.y + (14 * step),
    );
  }

  Future<_ScenarioRecipePlan?> _pickRecipePlan(
    BuildContext context, {
    required EditorNotifier notifier,
    required ScenarioAsset scenario,
    required ScenarioNode originNode,
    required bool allowChain,
  }) async {
    final outgoing = scenario.edges
        .where((edge) => edge.fromNodeId == originNode.id)
        .toList(growable: false);
    if (outgoing.isEmpty) {
      return const _ScenarioRecipePlan(
        mode: _ScenarioRecipeLinkMode.append,
        replacedOutgoingCount: 0,
      );
    }

    final options = <_ScenarioRecipeLinkMode>[
      _ScenarioRecipeLinkMode.replaceOutgoing,
      _ScenarioRecipeLinkMode.append,
      if (allowChain && outgoing.length == 1) _ScenarioRecipeLinkMode.chain,
    ];
    final picked = await showCupertinoListPicker<_ScenarioRecipeLinkMode>(
      context: context,
      title: 'Insertion de recette',
      items: options,
      labelOf: (value) =>
          '${_scenarioRecipeModeLabel(value)} — ${_scenarioRecipeModeDescription(value)}',
    );
    if (picked == null || !context.mounted) {
      return null;
    }

    if (picked == _ScenarioRecipeLinkMode.append) {
      return const _ScenarioRecipePlan(
        mode: _ScenarioRecipeLinkMode.append,
        replacedOutgoingCount: 0,
      );
    }

    if (picked == _ScenarioRecipeLinkMode.chain) {
      final baseEdge = outgoing.first;
      await notifier.deleteScenarioEdge(
        scenarioId: scenario.id,
        edgeId: baseEdge.id,
      );
      return _ScenarioRecipePlan(
        mode: _ScenarioRecipeLinkMode.chain,
        replacedOutgoingCount: 1,
        chainTargetNodeId: baseEdge.toNodeId,
        chainEdgeLabel: baseEdge.label,
      );
    }

    // replaceOutgoing
    for (final edge in outgoing) {
      await notifier.deleteScenarioEdge(
        scenarioId: scenario.id,
        edgeId: edge.id,
      );
    }
    return _ScenarioRecipePlan(
      mode: _ScenarioRecipeLinkMode.replaceOutgoing,
      replacedOutgoingCount: outgoing.length,
    );
  }

  Future<void> _connectRecipeFlow({
    required EditorNotifier notifier,
    required ScenarioAsset scenario,
    required ScenarioNode originNode,
    required _ScenarioRecipePlan plan,
    required String recipeStartNodeId,
    required String originLabel,
    String? recipeEndNodeId,
  }) async {
    await notifier.addScenarioEdge(
      scenarioId: scenario.id,
      fromNodeId: originNode.id,
      toNodeId: recipeStartNodeId,
      label: originLabel,
    );
    if (plan.mode == _ScenarioRecipeLinkMode.chain &&
        plan.chainTargetNodeId != null &&
        recipeEndNodeId != null) {
      final chainLabel = plan.chainEdgeLabel?.trim() ?? '';
      await notifier.addScenarioEdge(
        scenarioId: scenario.id,
        fromNodeId: recipeEndNodeId,
        toNodeId: plan.chainTargetNodeId!,
        label: chainLabel.isEmpty ? 'suite' : chainLabel,
      );
    }
  }

  Future<void> _showRecipeAppliedSummary(
    BuildContext context, {
    required String recipeName,
    required _ScenarioRecipePlan plan,
  }) async {
    if (!context.mounted) {
      return;
    }
    await showCupertinoEditorAlert(
      context,
      title: 'Recette appliquée',
      message:
          '$recipeName\nMode: ${_scenarioRecipeModeLabel(plan.mode)}\nSorties remplacées: ${plan.replacedOutgoingCount}',
    );
  }

  Future<void> _applyRecipeMapEnterDialogue(
    BuildContext context, {
    required EditorState state,
    required EditorNotifier notifier,
    required ProjectManifest project,
    required ScenarioAsset scenario,
    required ScenarioNode originNode,
  }) async {
    // Recette guidée : entrée sur map -> dialogue.
    // Cette recette crée une source de déclenchement (reference/source),
    // puis un node dialogue, puis relie automatiquement les edges.
    final plan = await _pickRecipePlan(
      context,
      notifier: notifier,
      scenario: scenario,
      originNode: originNode,
      allowChain: true,
    );
    if (plan == null) return;
    if (!context.mounted) return;

    final map = await showCupertinoListPicker<ProjectMapEntry>(
      context: context,
      title: 'Choisir la map source',
      items: project.maps,
      labelOf: (value) => '${value.name} (${value.id})',
    );
    if (map == null || !context.mounted) return;
    final dialogue = await showCupertinoListPicker<ProjectDialogueEntry>(
      context: context,
      title: 'Choisir le dialogue',
      items: project.dialogues,
      labelOf: (value) => '${value.name} (${value.id})',
    );
    if (dialogue == null || !context.mounted) return;
    final sourceId = await _addScenarioNodeAndResolveId(
      notifier: notifier,
      scenarioId: scenario.id,
      type: ScenarioNodeType.reference,
      title: 'Entrée map ${map.name}',
      position: _recipeNodePosition(originNode, 1),
    );
    if (sourceId == null) return;
    final sourceNode = _findScenarioNodeById(notifier, sourceId);
    if (sourceNode != null) {
      await notifier.updateScenarioNode(
        scenarioId: scenario.id,
        node: sourceNode.copyWith(
          payload: sourceNode.payload.copyWith(actionKind: 'sourceMapEnter'),
          binding: sourceNode.binding.copyWith(mapId: map.id),
        ),
      );
    }
    final dialogueId = await _addScenarioNodeAndResolveId(
      notifier: notifier,
      scenarioId: scenario.id,
      type: ScenarioNodeType.dialogue,
      title: 'Dialogue entrée map',
      position: _recipeNodePosition(originNode, 2),
    );
    if (dialogueId == null) return;
    final dialogueNode = _findScenarioNodeById(notifier, dialogueId);
    if (dialogueNode != null) {
      await notifier.updateScenarioNode(
        scenarioId: scenario.id,
        node: dialogueNode.copyWith(
          binding: dialogueNode.binding.copyWith(dialogueId: dialogue.id),
        ),
      );
    }
    final endId = await _addScenarioNodeAndResolveId(
      notifier: notifier,
      scenarioId: scenario.id,
      type: ScenarioNodeType.end,
      title: 'Fin après dialogue',
      position: _recipeNodePosition(originNode, 3),
    );
    await _connectRecipeFlow(
      notifier: notifier,
      scenario: scenario,
      originNode: originNode,
      plan: plan,
      recipeStartNodeId: sourceId,
      recipeEndNodeId: endId ?? dialogueId,
      originLabel: 'suite',
    );
    await notifier.addScenarioEdge(
      scenarioId: scenario.id,
      fromNodeId: sourceId,
      toNodeId: dialogueId,
      label: 'onEnterMap',
    );
    if (endId != null) {
      await notifier.addScenarioEdge(
        scenarioId: scenario.id,
        fromNodeId: dialogueId,
        toNodeId: endId,
        label: 'next',
      );
    }
    if (!context.mounted) return;
    await _showRecipeAppliedSummary(
      context,
      recipeName: 'Entrée map → dialogue',
      plan: plan,
    );
  }

  Future<void> _applyRecipeTriggerEnterDialogue(
    BuildContext context, {
    required EditorState state,
    required EditorNotifier notifier,
    required ProjectManifest project,
    required ScenarioAsset scenario,
    required ScenarioNode originNode,
  }) async {
    // Recette guidée : entrée trigger/zone -> dialogue.
    // L'objectif est de rendre explicite la logique "source -> effet".
    final plan = await _pickRecipePlan(
      context,
      notifier: notifier,
      scenario: scenario,
      originNode: originNode,
      allowChain: true,
    );
    if (plan == null) return;
    if (!context.mounted) return;

    final mapEntry = await showCupertinoListPicker<ProjectMapEntry>(
      context: context,
      title: 'Choisir la map du trigger',
      items: project.maps,
      labelOf: (value) => '${value.name} (${value.id})',
    );
    if (mapEntry == null || !context.mounted) return;
    final map = await _loadMapById(
      state: state,
      project: project,
      mapId: mapEntry.id,
    );
    if (!context.mounted) return;
    if (map == null || map.triggers.isEmpty) {
      await showCupertinoEditorAlert(
        context,
        title: 'Trigger indisponible',
        message:
            'La map "${mapEntry.name}" ne contient pas de trigger utilisable.',
      );
      return;
    }
    final trigger = await showCupertinoListPicker<MapTrigger>(
      context: context,
      title: 'Choisir le trigger',
      items: map.triggers,
      labelOf: (value) =>
          '${value.id} — ${value.type.name} — (${value.area.pos.x},${value.area.pos.y})',
    );
    if (trigger == null || !context.mounted) return;
    final dialogue = await showCupertinoListPicker<ProjectDialogueEntry>(
      context: context,
      title: 'Choisir le dialogue',
      items: project.dialogues,
      labelOf: (value) => '${value.name} (${value.id})',
    );
    if (dialogue == null || !context.mounted) return;
    final sourceId = await _addScenarioNodeAndResolveId(
      notifier: notifier,
      scenarioId: scenario.id,
      type: ScenarioNodeType.reference,
      title: 'Entrée trigger ${trigger.id}',
      position: _recipeNodePosition(originNode, 1),
    );
    if (sourceId == null) return;
    final sourceNode = _findScenarioNodeById(notifier, sourceId);
    if (sourceNode != null) {
      await notifier.updateScenarioNode(
        scenarioId: scenario.id,
        node: sourceNode.copyWith(
          payload:
              sourceNode.payload.copyWith(actionKind: 'sourceTriggerEnter'),
          binding: sourceNode.binding.copyWith(
            mapId: mapEntry.id,
            triggerId: trigger.id,
          ),
        ),
      );
    }
    final dialogueId = await _addScenarioNodeAndResolveId(
      notifier: notifier,
      scenarioId: scenario.id,
      type: ScenarioNodeType.dialogue,
      title: 'Dialogue entrée zone',
      position: _recipeNodePosition(originNode, 2),
    );
    if (dialogueId == null) return;
    final dialogueNode = _findScenarioNodeById(notifier, dialogueId);
    if (dialogueNode != null) {
      await notifier.updateScenarioNode(
        scenarioId: scenario.id,
        node: dialogueNode.copyWith(
          binding: dialogueNode.binding.copyWith(dialogueId: dialogue.id),
        ),
      );
    }
    final endId = await _addScenarioNodeAndResolveId(
      notifier: notifier,
      scenarioId: scenario.id,
      type: ScenarioNodeType.end,
      title: 'Fin après trigger',
      position: _recipeNodePosition(originNode, 3),
    );
    await _connectRecipeFlow(
      notifier: notifier,
      scenario: scenario,
      originNode: originNode,
      plan: plan,
      recipeStartNodeId: sourceId,
      recipeEndNodeId: endId ?? dialogueId,
      originLabel: 'suite',
    );
    await notifier.addScenarioEdge(
      scenarioId: scenario.id,
      fromNodeId: sourceId,
      toNodeId: dialogueId,
      label: 'onTriggerEnter',
    );
    if (endId != null) {
      await notifier.addScenarioEdge(
        scenarioId: scenario.id,
        fromNodeId: dialogueId,
        toNodeId: endId,
        label: 'next',
      );
    }
    if (!context.mounted) return;
    await _showRecipeAppliedSummary(
      context,
      recipeName: 'Entrée trigger → dialogue',
      plan: plan,
    );
  }

  Future<void> _applyRecipeEntityInteractScript(
    BuildContext context, {
    required EditorState state,
    required EditorNotifier notifier,
    required ProjectManifest project,
    required ScenarioAsset scenario,
    required ScenarioNode originNode,
  }) async {
    // Recette guidée : interaction PNJ/entité -> script.
    // Ici la source (interaction) est séparée de l'action (runScript).
    final plan = await _pickRecipePlan(
      context,
      notifier: notifier,
      scenario: scenario,
      originNode: originNode,
      allowChain: true,
    );
    if (plan == null) return;
    if (!context.mounted) return;

    final mapEntry = await showCupertinoListPicker<ProjectMapEntry>(
      context: context,
      title: 'Choisir la map du PNJ',
      items: project.maps,
      labelOf: (value) => '${value.name} (${value.id})',
    );
    if (mapEntry == null || !context.mounted) return;
    final map = await _loadMapById(
      state: state,
      project: project,
      mapId: mapEntry.id,
    );
    if (!context.mounted) return;
    if (map == null || map.entities.isEmpty) {
      await showCupertinoEditorAlert(
        context,
        title: 'Entité indisponible',
        message:
            'La map "${mapEntry.name}" ne contient pas d’entité utilisable.',
      );
      return;
    }
    final entity = await showCupertinoListPicker<MapEntity>(
      context: context,
      title: 'Choisir l’entité',
      items: map.entities,
      labelOf: (value) =>
          '${value.id} — ${value.kind.name} — (${value.pos.x},${value.pos.y})',
    );
    if (entity == null || !context.mounted) return;
    final script = await showCupertinoListPicker<ProjectScriptEntry>(
      context: context,
      title: 'Choisir le script',
      items: project.scripts,
      labelOf: (value) => '${value.name} (${value.id})',
    );
    if (script == null || !context.mounted) return;
    final sourceId = await _addScenarioNodeAndResolveId(
      notifier: notifier,
      scenarioId: scenario.id,
      type: ScenarioNodeType.reference,
      title: 'Interaction ${entity.id}',
      position: _recipeNodePosition(originNode, 1),
    );
    if (sourceId == null) return;
    final sourceNode = _findScenarioNodeById(notifier, sourceId);
    if (sourceNode != null) {
      await notifier.updateScenarioNode(
        scenarioId: scenario.id,
        node: sourceNode.copyWith(
          payload:
              sourceNode.payload.copyWith(actionKind: 'sourceEntityInteract'),
          binding: sourceNode.binding.copyWith(
            mapId: mapEntry.id,
            entityId: entity.id,
          ),
        ),
      );
    }
    final actionId = await _addScenarioNodeAndResolveId(
      notifier: notifier,
      scenarioId: scenario.id,
      type: ScenarioNodeType.action,
      title: 'Script interaction PNJ',
      position: _recipeNodePosition(originNode, 2),
    );
    if (actionId == null) return;
    final actionNode = _findScenarioNodeById(notifier, actionId);
    if (actionNode != null) {
      await notifier.updateScenarioNode(
        scenarioId: scenario.id,
        node: actionNode.copyWith(
          payload: actionNode.payload.copyWith(actionKind: 'runScript'),
          binding: actionNode.binding.copyWith(scriptId: script.id),
        ),
      );
    }
    final endId = await _addScenarioNodeAndResolveId(
      notifier: notifier,
      scenarioId: scenario.id,
      type: ScenarioNodeType.end,
      title: 'Fin après script',
      position: _recipeNodePosition(originNode, 3),
    );
    await _connectRecipeFlow(
      notifier: notifier,
      scenario: scenario,
      originNode: originNode,
      plan: plan,
      recipeStartNodeId: sourceId,
      recipeEndNodeId: endId ?? actionId,
      originLabel: 'suite',
    );
    await notifier.addScenarioEdge(
      scenarioId: scenario.id,
      fromNodeId: sourceId,
      toNodeId: actionId,
      label: 'onInteract',
    );
    if (endId != null) {
      await notifier.addScenarioEdge(
        scenarioId: scenario.id,
        fromNodeId: actionId,
        toNodeId: endId,
        label: 'next',
      );
    }
    if (!context.mounted) return;
    await _showRecipeAppliedSummary(
      context,
      recipeName: 'Interaction entité → script',
      plan: plan,
    );
  }

  Future<void> _applyRecipeTrainerBattle(
    BuildContext context, {
    required EditorNotifier notifier,
    required ProjectManifest project,
    required ScenarioAsset scenario,
    required ScenarioNode originNode,
  }) async {
    // Recette guidée : insertion rapide d'un combat trainer.
    final plan = await _pickRecipePlan(
      context,
      notifier: notifier,
      scenario: scenario,
      originNode: originNode,
      allowChain: true,
    );
    if (plan == null) return;
    if (!context.mounted) return;

    final trainer = await showCupertinoListPicker<ProjectTrainerEntry>(
      context: context,
      title: 'Choisir le dresseur',
      items: project.trainers,
      labelOf: (value) => '${value.name} (${value.id})',
    );
    if (trainer == null || !context.mounted) return;
    final actionId = await _addScenarioNodeAndResolveId(
      notifier: notifier,
      scenarioId: scenario.id,
      type: ScenarioNodeType.action,
      title: 'Combat ${trainer.name}',
      position: _recipeNodePosition(originNode, 1),
    );
    if (actionId == null) return;
    final actionNode = _findScenarioNodeById(notifier, actionId);
    if (actionNode != null) {
      await notifier.updateScenarioNode(
        scenarioId: scenario.id,
        node: actionNode.copyWith(
          payload:
              actionNode.payload.copyWith(actionKind: 'startTrainerBattle'),
          binding: actionNode.binding.copyWith(trainerId: trainer.id),
        ),
      );
    }
    final endId = await _addScenarioNodeAndResolveId(
      notifier: notifier,
      scenarioId: scenario.id,
      type: ScenarioNodeType.end,
      title: 'Fin après combat',
      position: _recipeNodePosition(originNode, 2),
    );
    await _connectRecipeFlow(
      notifier: notifier,
      scenario: scenario,
      originNode: originNode,
      plan: plan,
      recipeStartNodeId: actionId,
      recipeEndNodeId: endId ?? actionId,
      originLabel: 'next',
    );
    if (endId != null) {
      await notifier.addScenarioEdge(
        scenarioId: scenario.id,
        fromNodeId: actionId,
        toNodeId: endId,
        label: 'afterBattle',
      );
    }
    if (!context.mounted) return;
    await _showRecipeAppliedSummary(
      context,
      recipeName: 'Combat dresseur',
      plan: plan,
    );
  }

  Future<void> _applyRecipeFlagBranch(
    BuildContext context, {
    required EditorNotifier notifier,
    required ProjectManifest project,
    required ScenarioAsset scenario,
    required ScenarioNode originNode,
  }) async {
    // Recette guidée : condition sur flag avec deux branches
    // (Vrai/Faux) prêtes à remplir.
    final plan = await _pickRecipePlan(
      context,
      notifier: notifier,
      scenario: scenario,
      originNode: originNode,
      allowChain: false,
    );
    if (plan == null) return;
    if (!context.mounted) return;

    final flags = _knownFlagSuggestions(project);
    final pickedFlag = await showCupertinoListPicker<String?>(
      context: context,
      title: 'Choisir un flag',
      items: <String?>[null, ...flags],
      labelOf: (value) => value ?? 'Saisie manuelle',
    );
    if (!context.mounted) return;
    String flag = pickedFlag ?? '';
    if (flag.isEmpty) {
      final controller = TextEditingController();
      final ok = await showMacosEditorPromptSheet(
        context,
        title: 'Nom du flag',
        controller: controller,
        confirmLabel: 'Valider',
        placeholder: 'story.got_starter',
        compact: true,
      );
      if (!ok || !context.mounted) return;
      flag = controller.text.trim();
    }
    if (flag.isEmpty) return;
    final conditionId = await _addScenarioNodeAndResolveId(
      notifier: notifier,
      scenarioId: scenario.id,
      type: ScenarioNodeType.condition,
      title: 'Condition $flag',
      position: _recipeNodePosition(originNode, 1),
    );
    if (conditionId == null) return;
    final conditionNode = _findScenarioNodeById(notifier, conditionId);
    if (conditionNode != null) {
      await notifier.updateScenarioNode(
        scenarioId: scenario.id,
        node: conditionNode.copyWith(
          payload: conditionNode.payload.copyWith(
            condition: ScriptConditionFactory.flagIsSet(flag),
          ),
          binding: conditionNode.binding.copyWith(flagName: flag),
        ),
      );
    }
    final trueEndId = await _addScenarioNodeAndResolveId(
      notifier: notifier,
      scenarioId: scenario.id,
      type: ScenarioNodeType.end,
      title: 'Branche vraie',
      position: _recipeNodePosition(originNode, 2),
    );
    final falseEndId = await _addScenarioNodeAndResolveId(
      notifier: notifier,
      scenarioId: scenario.id,
      type: ScenarioNodeType.end,
      title: 'Branche fausse',
      position: _recipeNodePosition(
        originNode.copyWith(
          position: ScenarioNodePosition(
            x: originNode.position.x,
            y: originNode.position.y + 140,
          ),
        ),
        2,
      ),
    );
    await _connectRecipeFlow(
      notifier: notifier,
      scenario: scenario,
      originNode: originNode,
      plan: plan,
      recipeStartNodeId: conditionId,
      recipeEndNodeId: null,
      originLabel: 'next',
    );
    if (trueEndId != null) {
      await notifier.addScenarioEdge(
        scenarioId: scenario.id,
        fromNodeId: conditionId,
        toNodeId: trueEndId,
        label: 'Vrai',
      );
    }
    if (falseEndId != null) {
      await notifier.addScenarioEdge(
        scenarioId: scenario.id,
        fromNodeId: conditionId,
        toNodeId: falseEndId,
        label: 'Faux',
      );
    }
    if (!context.mounted) return;
    await _showRecipeAppliedSummary(
      context,
      recipeName: 'Condition flag A/B',
      plan: plan,
    );
  }

  Future<void> _applyNodeChanges(
    BuildContext context, {
    required EditorNotifier notifier,
    required ScenarioAsset scenario,
    required ScenarioNode node,
  }) async {
    ScriptCondition? parsedCondition = node.payload.condition;
    if (node.type == ScenarioNodeType.condition) {
      switch (_conditionMode) {
        case _ScenarioConditionMode.none:
          parsedCondition = null;
        case _ScenarioConditionMode.flagSet:
          final flag = _nodeConditionFlagNameController.text.trim();
          if (flag.isEmpty) {
            await showCupertinoEditorAlert(
              context,
              title: 'Flag requis',
              message: 'Renseigne un Flag Name.',
            );
            return;
          }
          parsedCondition = ScriptConditionFactory.flagIsSet(flag);
        case _ScenarioConditionMode.flagUnset:
          final flag = _nodeConditionFlagNameController.text.trim();
          if (flag.isEmpty) {
            await showCupertinoEditorAlert(
              context,
              title: 'Flag requis',
              message: 'Renseigne un Flag Name.',
            );
            return;
          }
          parsedCondition = ScriptConditionFactory.flagIsUnset(flag);
        case _ScenarioConditionMode.eventConsumed:
          final mapId = _nodeMapIdController.text.trim();
          final eventId = _nodeEventIdController.text.trim();
          if (mapId.isEmpty || eventId.isEmpty) {
            await showCupertinoEditorAlert(
              context,
              title: 'Map + event requis',
              message: 'Choisis une map puis un Event ID.',
            );
            return;
          }
          parsedCondition = ScriptConditionFactory.eventIsConsumed(eventId);
        case _ScenarioConditionMode.playerOnMap:
          final mapId = _nodeMapIdController.text.trim();
          if (mapId.isEmpty) {
            await showCupertinoEditorAlert(
              context,
              title: 'Map requise',
              message: 'Choisis une map pour ce test.',
            );
            return;
          }
          parsedCondition = ScriptConditionFactory.playerOnMap(mapId);
        case _ScenarioConditionMode.variableEquals:
          final variableName = _nodeConditionVariableNameController.text.trim();
          final value = _nodeConditionVariableValueController.text.trim();
          if (variableName.isEmpty || value.isEmpty) {
            await showCupertinoEditorAlert(
              context,
              title: 'Variable requise',
              message: 'Renseigne Variable Name et Value.',
            );
            return;
          }
          parsedCondition = ScriptCondition(
            type: ScriptConditionType.variableEquals,
            params: <String, String>{
              ScriptConditionParams.variableName: variableName,
              ScriptConditionParams.value: value,
            },
          );
        case _ScenarioConditionMode.rawJson:
          final rawCondition = _nodeConditionJsonController.text.trim();
          if (rawCondition.isEmpty) {
            parsedCondition = null;
          } else {
            try {
              final dynamic decoded = jsonDecode(rawCondition);
              if (decoded is! Map<String, dynamic>) {
                throw const FormatException(
                  'Condition JSON must be an object',
                );
              }
              parsedCondition = ScriptCondition.fromJson(decoded);
            } catch (e) {
              await showCupertinoEditorAlert(
                context,
                title: 'JSON condition invalide',
                message: '$e',
              );
              return;
            }
          }
      }
    }

    final updatedNode = node.copyWith(
      title: _nodeTitleController.text.trim(),
      description: _nodeDescriptionController.text.trim(),
      binding: node.binding.copyWith(
        scriptId: _normalizeOptional(_nodeScriptIdController.text),
        dialogueId: _normalizeOptional(_nodeDialogueIdController.text),
        mapId: _normalizeOptional(_nodeMapIdController.text),
        eventId: _normalizeOptional(_nodeEventIdController.text),
        entityId: _normalizeOptional(_nodeEntityIdController.text),
        warpId: _normalizeOptional(_nodeWarpIdController.text),
        triggerId: _normalizeOptional(_nodeTriggerIdController.text),
        trainerId: _normalizeOptional(_nodeTrainerIdController.text),
        flagName: _normalizeOptional(_nodeFlagNameController.text),
        variableName: _normalizeOptional(_nodeVariableNameController.text),
      ),
      payload: node.payload.copyWith(
        actionKind: _normalizeOptional(_nodeActionKindController.text),
        message: _normalizeOptional(_nodeMessageController.text),
        condition: parsedCondition,
      ),
    );
    await notifier.updateScenarioNode(
      scenarioId: scenario.id,
      node: updatedNode,
    );
  }

  String? _normalizeOptional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _optionalValue(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _syncScenarioControllers(ScenarioAsset scenario) {
    final fingerprint =
        '${scenario.id}|${scenario.name}|${scenario.description}';
    if (_boundScenarioFingerprint == fingerprint) {
      return;
    }
    _boundScenarioFingerprint = fingerprint;
    _scenarioNameController.text = scenario.name;
    _scenarioDescriptionController.text = scenario.description;
  }

  _ScenarioConditionMode _deriveConditionMode(ScriptCondition? condition) {
    if (condition == null) {
      return _ScenarioConditionMode.none;
    }
    return switch (condition.type) {
      ScriptConditionType.flagIsSet => _ScenarioConditionMode.flagSet,
      ScriptConditionType.flagIsUnset => _ScenarioConditionMode.flagUnset,
      ScriptConditionType.eventIsConsumed =>
        _ScenarioConditionMode.eventConsumed,
      ScriptConditionType.playerOnMap => _ScenarioConditionMode.playerOnMap,
      ScriptConditionType.variableEquals =>
        _ScenarioConditionMode.variableEquals,
      _ => _ScenarioConditionMode.rawJson,
    };
  }

  void _syncNodeControllers(ScenarioNode? node) {
    if (node == null) {
      _boundNodeFingerprint = null;
      _nodeTitleController.clear();
      _nodeDescriptionController.clear();
      _nodeActionKindController.clear();
      _nodeMessageController.clear();
      _nodeConditionJsonController.clear();
      _nodeConditionFlagNameController.clear();
      _nodeConditionVariableNameController.clear();
      _nodeConditionVariableValueController.clear();
      _nodeScriptIdController.clear();
      _nodeDialogueIdController.clear();
      _nodeMapIdController.clear();
      _nodeEventIdController.clear();
      _nodeEntityIdController.clear();
      _nodeWarpIdController.clear();
      _nodeTriggerIdController.clear();
      _nodeTrainerIdController.clear();
      _nodeFlagNameController.clear();
      _nodeVariableNameController.clear();
      _conditionMode = _ScenarioConditionMode.none;
      return;
    }
    final fingerprint = [
      node.id,
      node.type.name,
      node.title,
      node.description,
      node.binding.scriptId ?? '',
      node.binding.dialogueId ?? '',
      node.binding.mapId ?? '',
      node.binding.eventId ?? '',
      node.binding.entityId ?? '',
      node.binding.warpId ?? '',
      node.binding.triggerId ?? '',
      node.binding.trainerId ?? '',
      node.binding.flagName ?? '',
      node.binding.variableName ?? '',
      node.payload.actionKind ?? '',
      node.payload.message ?? '',
      node.payload.condition?.toJson().toString() ?? '',
    ].join('|');
    if (_boundNodeFingerprint == fingerprint) {
      return;
    }
    _boundNodeFingerprint = fingerprint;
    _nodeTitleController.text = node.title;
    _nodeDescriptionController.text = node.description;
    _nodeActionKindController.text = node.payload.actionKind ?? '';
    _nodeMessageController.text = node.payload.message ?? '';
    _nodeConditionJsonController.text = node.payload.condition == null
        ? ''
        : const JsonEncoder.withIndent('  ')
            .convert(node.payload.condition!.toJson());
    _nodeScriptIdController.text = node.binding.scriptId ?? '';
    _nodeDialogueIdController.text = node.binding.dialogueId ?? '';
    _nodeMapIdController.text = node.binding.mapId ?? '';
    _nodeEventIdController.text = node.binding.eventId ?? '';
    _nodeEntityIdController.text = node.binding.entityId ?? '';
    _nodeWarpIdController.text = node.binding.warpId ?? '';
    _nodeTriggerIdController.text = node.binding.triggerId ?? '';
    _nodeTrainerIdController.text = node.binding.trainerId ?? '';
    _nodeFlagNameController.text = node.binding.flagName ?? '';
    _nodeVariableNameController.text = node.binding.variableName ?? '';

    final condition = node.payload.condition;
    _conditionMode = _deriveConditionMode(condition);
    _nodeConditionFlagNameController.text =
        condition?.params[ScriptConditionParams.flagName] ??
            node.binding.flagName ??
            '';
    _nodeConditionVariableNameController.text =
        condition?.params[ScriptConditionParams.variableName] ??
            node.binding.variableName ??
            '';
    _nodeConditionVariableValueController.text =
        condition?.params[ScriptConditionParams.value] ?? '';
    if (_conditionMode == _ScenarioConditionMode.eventConsumed) {
      final eventId = condition?.params[ScriptConditionParams.eventId] ?? '';
      if (eventId.isNotEmpty) {
        _nodeEventIdController.text = eventId;
      }
    }
    if (_conditionMode == _ScenarioConditionMode.playerOnMap) {
      final mapId = condition?.params[ScriptConditionParams.mapId] ?? '';
      if (mapId.isNotEmpty) {
        _nodeMapIdController.text = mapId;
      }
    }
  }
}

Color _colorForNodeType(ScenarioNodeType type) {
  return switch (type) {
    ScenarioNodeType.start => EditorChrome.inspectorJoyMint,
    ScenarioNodeType.dialogue => EditorChrome.inspectorJoyLilac,
    ScenarioNodeType.action => EditorChrome.inspectorJoyCyan,
    ScenarioNodeType.condition => EditorChrome.inspectorJoyAmber,
    ScenarioNodeType.choice => EditorChrome.inspectorJoyHoney,
    ScenarioNodeType.reference => EditorChrome.inspectorJoyBlue,
    ScenarioNodeType.end => EditorChrome.inspectorJoyCoral,
  };
}
