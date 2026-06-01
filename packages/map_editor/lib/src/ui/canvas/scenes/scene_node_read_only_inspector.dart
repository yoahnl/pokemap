import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../features/narrative/application/narrative_workspace_projection.dart';
import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';
import 'scene_cinematic_picker.dart';

typedef SceneConditionSourceDraftUpdater = Future<bool> Function({
  required String nodeId,
  required SceneConditionSource source,
});

typedef SceneYarnDialoguePayloadDraftUpdater = Future<bool> Function({
  required String nodeId,
  required String dialogueId,
  String? yarnNodeName,
});

typedef SceneBattlePayloadDraftUpdater = Future<bool> Function({
  required String nodeId,
  required String trainerId,
});

typedef SceneCinematicPayloadDraftUpdater = Future<bool> Function({
  required String nodeId,
  required String cinematicId,
});

typedef SceneActionConsequenceDraftUpdater = Future<bool> Function({
  required String nodeId,
  required SceneConsequence consequence,
});

final class SceneConditionSourcePickerOption {
  const SceneConditionSourcePickerOption({
    required this.sourceKind,
    required this.sourceId,
    required this.label,
    required this.debugTechnicalLabel,
    this.description = '',
    this.category = '',
  });

  final SceneConditionSourceKind sourceKind;
  final String sourceId;
  final String label;
  final String debugTechnicalLabel;
  final String description;
  final String category;
}

final class SceneConsequenceFactPickerOption {
  const SceneConsequenceFactPickerOption({
    required this.factId,
    required this.label,
    this.description = '',
    this.category = '',
    this.debugTechnicalLabel = '',
  });

  final String factId;
  final String label;
  final String description;
  final String category;
  final String debugTechnicalLabel;
}

final class SceneConsequenceEventPickerOption {
  const SceneConsequenceEventPickerOption({
    required this.mapId,
    required this.mapLabel,
    required this.eventId,
    required this.eventLabel,
    this.debugTechnicalLabel = '',
  });

  final String mapId;
  final String mapLabel;
  final String eventId;
  final String eventLabel;
  final String debugTechnicalLabel;
}

class SceneNodeReadOnlyInspector extends StatelessWidget {
  const SceneNodeReadOnlyInspector({
    super.key,
    required this.scene,
    required this.selectedNodeId,
    this.selectedEdgeId,
    this.onRemoveEdgeDraft,
    this.onRemoveNodeDraft,
    this.conditionSourceOptions = const [],
    this.onUpdateConditionSource,
    this.linkedAssetContracts,
    this.cinematicsLibrary,
    this.onUpdateYarnDialoguePayload,
    this.onUpdateBattlePayload,
    this.onUpdateCinematicPayload,
    this.consequenceFactOptions = const [],
    this.consequenceEventOptions = const [],
    this.onUpdateActionConsequence,
  });

  final NarrativeSceneSummary scene;
  final String? selectedNodeId;
  final String? selectedEdgeId;
  final ValueChanged<String>? onRemoveEdgeDraft;
  final ValueChanged<String>? onRemoveNodeDraft;
  final List<SceneConditionSourcePickerOption> conditionSourceOptions;
  final SceneConditionSourceDraftUpdater? onUpdateConditionSource;
  final LinkedAssetContractsSnapshot? linkedAssetContracts;
  final CinematicsLibraryReadModel? cinematicsLibrary;
  final SceneYarnDialoguePayloadDraftUpdater? onUpdateYarnDialoguePayload;
  final SceneBattlePayloadDraftUpdater? onUpdateBattlePayload;
  final SceneCinematicPayloadDraftUpdater? onUpdateCinematicPayload;
  final List<SceneConsequenceFactPickerOption> consequenceFactOptions;
  final List<SceneConsequenceEventPickerOption> consequenceEventOptions;
  final SceneActionConsequenceDraftUpdater? onUpdateActionConsequence;

  @override
  Widget build(BuildContext context) {
    final edge = _selectedEdge;
    final node = _selectedNode;
    return PokeMapInspectorPanel(
      key: const ValueKey('scene-node-read-only-inspector'),
      padding: const EdgeInsets.all(12),
      header: _InspectorHeader(
        title: edge == null ? 'Détails du nœud' : 'Détails du lien',
        chipLabel: edge == null && node != null
            ? _nodeInspectorModeLabel(node, linkedAssetContracts)
            : 'Lecture seule',
      ),
      child: edge != null
          ? _EdgeInspectorBody(
              scene: scene,
              edge: edge,
              onRemoveEdgeDraft: onRemoveEdgeDraft,
            )
          : node == null
              ? const _NodeInspectorEmptyState()
              : _NodeInspectorBody(
                  scene: scene,
                  node: node,
                  onRemoveNodeDraft: onRemoveNodeDraft,
                  conditionSourceOptions: conditionSourceOptions,
                  onUpdateConditionSource: onUpdateConditionSource,
                  linkedAssetContracts: linkedAssetContracts,
                  cinematicsLibrary: cinematicsLibrary,
                  onUpdateYarnDialoguePayload: onUpdateYarnDialoguePayload,
                  onUpdateBattlePayload: onUpdateBattlePayload,
                  onUpdateCinematicPayload: onUpdateCinematicPayload,
                  consequenceFactOptions: consequenceFactOptions,
                  consequenceEventOptions: consequenceEventOptions,
                  onUpdateActionConsequence: onUpdateActionConsequence,
                ),
    );
  }

  SceneEdge? get _selectedEdge {
    final id = selectedEdgeId;
    if (id == null) {
      return null;
    }
    for (final edge in scene.graph.edges) {
      if (edge.id == id) {
        return edge;
      }
    }
    return null;
  }

  SceneNode? get _selectedNode {
    final id = selectedNodeId;
    if (id == null) {
      return null;
    }
    for (final node in scene.graph.nodes) {
      if (node.id == id) {
        return node;
      }
    }
    return null;
  }
}

class _InspectorHeader extends StatelessWidget {
  const _InspectorHeader({
    required this.title,
    required this.chipLabel,
  });

  final String title;
  final String chipLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 9),
      child: Row(
        children: [
          const PokeMapIconTile(
            icon: CupertinoIcons.sidebar_right,
            tone: PokeMapTone.narrative,
            size: 30,
            iconSize: 15,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _InspectorChip(label: chipLabel),
        ],
      ),
    );
  }
}

class _NodeInspectorEmptyState extends StatelessWidget {
  const _NodeInspectorEmptyState();

  @override
  Widget build(BuildContext context) {
    return const PokeMapEmptyState(
      key: ValueKey('scene-node-inspector-empty'),
      icon: Icon(CupertinoIcons.cursor_rays),
      title: 'Sélectionnez un nœud',
      description: 'Le détail read-only du nœud apparaîtra ici.',
    );
  }
}

class _NodeInspectorBody extends StatelessWidget {
  const _NodeInspectorBody({
    required this.scene,
    required this.node,
    required this.onRemoveNodeDraft,
    required this.conditionSourceOptions,
    required this.onUpdateConditionSource,
    required this.linkedAssetContracts,
    required this.cinematicsLibrary,
    required this.onUpdateYarnDialoguePayload,
    required this.onUpdateBattlePayload,
    required this.onUpdateCinematicPayload,
    required this.consequenceFactOptions,
    required this.consequenceEventOptions,
    required this.onUpdateActionConsequence,
  });

  final NarrativeSceneSummary scene;
  final SceneNode node;
  final ValueChanged<String>? onRemoveNodeDraft;
  final List<SceneConditionSourcePickerOption> conditionSourceOptions;
  final SceneConditionSourceDraftUpdater? onUpdateConditionSource;
  final LinkedAssetContractsSnapshot? linkedAssetContracts;
  final CinematicsLibraryReadModel? cinematicsLibrary;
  final SceneYarnDialoguePayloadDraftUpdater? onUpdateYarnDialoguePayload;
  final SceneBattlePayloadDraftUpdater? onUpdateBattlePayload;
  final SceneCinematicPayloadDraftUpdater? onUpdateCinematicPayload;
  final List<SceneConsequenceFactPickerOption> consequenceFactOptions;
  final List<SceneConsequenceEventPickerOption> consequenceEventOptions;
  final SceneActionConsequenceDraftUpdater? onUpdateActionConsequence;

  @override
  Widget build(BuildContext context) {
    final incoming = scene.graph.edges
        .where((edge) => edge.toNodeId == node.id)
        .toList(growable: false);
    final outgoing = scene.graph.edges
        .where((edge) => edge.fromNodeId == node.id)
        .toList(growable: false);
    final removalBlocker = sceneNodeDraftRemovalBlocker(scene.graph, node);
    final canRemoveNode = removalBlocker == null && onRemoveNodeDraft != null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InspectorSection(
            title: 'Général',
            children: [
              _InspectorRow(label: 'Kind', value: _nodeKindLabel(node.kind)),
              _InspectorRow(label: 'Node ID', value: node.id),
              _InspectorRow(label: 'Titre', value: node.title ?? 'Sans titre'),
              _InspectorRow(
                label: 'Description',
                value: node.description ?? 'Aucune description.',
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (node.kind == SceneNodeKind.condition) ...[
            _ConditionAuthoringPanel(
              node: node,
              options: conditionSourceOptions,
              onUpdateConditionSource: onUpdateConditionSource,
            ),
            const SizedBox(height: 10),
          ],
          if (node.payload is SceneYarnDialoguePayload &&
              (linkedAssetContracts?.dialogues.isNotEmpty ?? false)) ...[
            _YarnDialoguePayloadAuthoringPanel(
              node: node,
              payload: node.payload as SceneYarnDialoguePayload,
              dialogues: linkedAssetContracts?.dialogues ?? const [],
              onUpdatePayload: onUpdateYarnDialoguePayload,
            ),
            const SizedBox(height: 10),
          ],
          if (node.payload is SceneBattlePayload &&
              (linkedAssetContracts?.battles.isNotEmpty ?? false)) ...[
            _BattlePayloadAuthoringPanel(
              node: node,
              payload: node.payload as SceneBattlePayload,
              battles: linkedAssetContracts?.battles ?? const [],
              onUpdatePayload: onUpdateBattlePayload,
            ),
            const SizedBox(height: 10),
          ],
          if (node.payload is SceneCinematicPayload &&
              cinematicsLibrary != null) ...[
            _CinematicPayloadAuthoringPanel(
              node: node,
              payload: node.payload as SceneCinematicPayload,
              library: cinematicsLibrary!,
              onUpdatePayload: onUpdateCinematicPayload,
            ),
            const SizedBox(height: 10),
          ],
          if (node.kind == SceneNodeKind.action &&
              node.payload is SceneActionPayload) ...[
            _ActionConsequenceAuthoringPanel(
              node: node,
              payload: node.payload as SceneActionPayload,
              factOptions: consequenceFactOptions,
              eventOptions: consequenceEventOptions,
              onUpdatePayload: onUpdateActionConsequence,
            ),
            const SizedBox(height: 10),
          ],
          _InspectorSection(
            title: 'Payload',
            children: _payloadRows(node.payload),
          ),
          const SizedBox(height: 10),
          _DiagnosticsSection(scene: scene),
          const SizedBox(height: 10),
          _EdgesSection(
            key: const ValueKey('scene-node-inspector-incoming'),
            title: 'Entrants',
            emptyLabel: 'Aucun edge entrant',
            edges: incoming,
            selectedNodeId: node.id,
            incoming: true,
          ),
          const SizedBox(height: 10),
          _EdgesSection(
            key: const ValueKey('scene-node-inspector-outgoing'),
            title: 'Sortants',
            emptyLabel: 'Aucun edge sortant',
            edges: outgoing,
            selectedNodeId: node.id,
            incoming: false,
          ),
          const SizedBox(height: 10),
          if (isSceneNodeDraftRemovable(node)) ...[
            _InspectorSection(
              title: 'Zone dangereuse',
              children: [
                PokeMapButton(
                  key: const ValueKey('scene-node-delete-action'),
                  onPressed: !canRemoveNode
                      ? null
                      : () {
                          _confirmAndRemoveNode(context);
                        },
                  variant: PokeMapButtonVariant.danger,
                  size: PokeMapButtonSize.small,
                  leading: const Icon(CupertinoIcons.delete),
                  child: const Text('Supprimer le nœud'),
                ),
                const SizedBox(height: 8),
                _InspectorNote(
                  label: removalBlocker ??
                      'Supprime ce nœud et ses liens entrants/sortants. '
                          'Aucune reconnexion automatique.',
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          const _InspectorNote(),
        ],
      ),
    );
  }

  Future<void> _confirmAndRemoveNode(BuildContext context) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => const _ConfirmNodeDeletionDialog(),
    );
    if (confirmed ?? false) {
      onRemoveNodeDraft?.call(node.id);
    }
  }
}

class _ConfirmNodeDeletionDialog extends StatelessWidget {
  const _ConfirmNodeDeletionDialog();

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      key: const ValueKey('scene-node-delete-confirm-dialog'),
      title: const Text('Supprimer ce nœud ?'),
      content: const Text(
        'Cette action supprime le nœud sélectionné et ses liens '
        'entrants/sortants. Le graph ne sera pas reconnecté automatiquement.',
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('Annuler'),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          child: const Text('Supprimer'),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

class _EdgeInspectorBody extends StatelessWidget {
  const _EdgeInspectorBody({
    required this.scene,
    required this.edge,
    required this.onRemoveEdgeDraft,
  });

  final NarrativeSceneSummary scene;
  final SceneEdge edge;
  final ValueChanged<String>? onRemoveEdgeDraft;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('scene-edge-read-only-inspector'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InspectorSection(
            title: 'Lien sélectionné',
            children: [
              _InspectorRow(label: 'Edge ID', value: edge.id),
              _InspectorRow(
                label: 'Source node',
                value: _nodeLabel(scene, edge.fromNodeId),
              ),
              _InspectorRow(label: 'Source port', value: edge.fromPortId),
              _InspectorRow(
                label: 'Target node',
                value: _nodeLabel(scene, edge.toNodeId),
              ),
              _InspectorRow(label: 'Kind', value: _edgeKindLabel(edge.kind)),
              _InspectorRow(label: 'Label', value: edge.label ?? 'Aucun label'),
            ],
          ),
          const SizedBox(height: 10),
          _InspectorSection(
            title: 'Action',
            children: [
              PokeMapButton(
                key: const ValueKey('scene-edge-delete-action'),
                onPressed: onRemoveEdgeDraft == null
                    ? null
                    : () => onRemoveEdgeDraft!(edge.id),
                variant: PokeMapButtonVariant.danger,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.delete),
                child: const Text('Supprimer le lien'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const _InspectorNote(
            label: 'La suppression retire uniquement ce lien. '
                'Les nœuds, payloads et layouts de nœuds restent inchangés.',
          ),
        ],
      ),
    );
  }
}

class _DiagnosticsSection extends StatelessWidget {
  const _DiagnosticsSection({required this.scene});

  final NarrativeSceneSummary scene;

  @override
  Widget build(BuildContext context) {
    final diagnostics = scene.diagnostics.diagnostics;
    return _InspectorSection(
      title: 'Diagnostics',
      children: [
        _InspectorRow(label: 'Statut', value: scene.diagnosticSummaryLabel),
        if (diagnostics.isEmpty)
          const _InspectorRow(label: 'Résultat', value: 'Aucun diagnostic.')
        else
          for (final diagnostic in diagnostics)
            _DiagnosticMessageRow(diagnostic: diagnostic),
      ],
    );
  }
}

class _DiagnosticMessageRow extends StatelessWidget {
  const _DiagnosticMessageRow({required this.diagnostic});

  final SceneDiagnostic diagnostic;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final color = switch (diagnostic.severity) {
      SceneDiagnosticSeverity.error => colors.error,
      SceneDiagnosticSeverity.warning => colors.warning,
      SceneDiagnosticSeverity.info => colors.textMuted,
    };
    final prefix = switch (diagnostic.severity) {
      SceneDiagnosticSeverity.error => 'Erreur',
      SceneDiagnosticSeverity.warning => 'Warning',
      SceneDiagnosticSeverity.info => 'Info',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(CupertinoIcons.circle_fill, size: 8, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$prefix · ${diagnostic.message}',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectorSection extends StatelessWidget {
  const _InspectorSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _InspectorRow extends StatelessWidget {
  const _InspectorRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _YarnDialoguePayloadAuthoringPanel extends StatelessWidget {
  const _YarnDialoguePayloadAuthoringPanel({
    required this.node,
    required this.payload,
    required this.dialogues,
    required this.onUpdatePayload,
  });

  final SceneNode node;
  final SceneYarnDialoguePayload payload;
  final List<DialoguePublicContract> dialogues;
  final SceneYarnDialoguePayloadDraftUpdater? onUpdatePayload;

  @override
  Widget build(BuildContext context) {
    final currentContract = _dialogueContractFor(payload.dialogueId);
    final authorableDialogues = [
      for (final dialogue in dialogues)
        if (dialogue.id.trim().isNotEmpty) dialogue,
    ];
    return _InspectorSection(
      title: 'Dialogue lié',
      children: [
        _InspectorRow(
          label: 'Dialogue actuel',
          value: currentContract == null
              ? payload.dialogueId
              : '${currentContract.label} · ${currentContract.id}',
        ),
        _InspectorRow(
          label: 'Yarn start',
          value: payload.yarnNodeName ?? 'Start par défaut du dialogue.',
        ),
        _InspectorRow(
          label: 'Outcomes Scene',
          value: _joinOrEmpty(payload.expectedOutcomes),
        ),
        if (currentContract == null)
          const _InspectorRow(
            label: 'Contrat public',
            value: 'Référence actuelle absente des dialogues publics.',
          )
        else
          _InspectorRow(
            label: 'Source',
            value: currentContract.sourceRef,
          ),
        const SizedBox(height: 4),
        PokeMapButton(
          key: const ValueKey('scene-payload-edit-dialogue-action'),
          onPressed: onUpdatePayload == null || authorableDialogues.isEmpty
              ? null
              : () => _pickDialogue(context, authorableDialogues),
          variant: PokeMapButtonVariant.secondary,
          size: PokeMapButtonSize.small,
          leading: const Icon(CupertinoIcons.text_bubble),
          child: const Text('Changer le dialogue'),
        ),
        const SizedBox(height: 8),
        const _InspectorNote(
          label: 'Cette édition modifie uniquement le payload du nœud Scene. '
              'Les outcomes Yarn restent read-only tant que leur contrat '
              'public n’expose pas de mapping fiable.',
        ),
      ],
    );
  }

  DialoguePublicContract? _dialogueContractFor(String dialogueId) {
    for (final dialogue in dialogues) {
      if (dialogue.id == dialogueId) {
        return dialogue;
      }
    }
    return null;
  }

  Future<void> _pickDialogue(
    BuildContext context,
    List<DialoguePublicContract> dialogues,
  ) async {
    final updater = onUpdatePayload;
    if (updater == null) {
      return;
    }
    final contract = await showCupertinoDialog<DialoguePublicContract>(
      context: context,
      builder: (context) => _DialoguePayloadEditDialog(dialogues: dialogues),
    );
    if (contract == null || !context.mounted) {
      return;
    }
    await updater(
      nodeId: node.id,
      dialogueId: contract.id,
      yarnNodeName: contract.defaultStartNode,
    );
  }
}

class _BattlePayloadAuthoringPanel extends StatelessWidget {
  const _BattlePayloadAuthoringPanel({
    required this.node,
    required this.payload,
    required this.battles,
    required this.onUpdatePayload,
  });

  final SceneNode node;
  final SceneBattlePayload payload;
  final List<BattlePublicContract> battles;
  final SceneBattlePayloadDraftUpdater? onUpdatePayload;

  @override
  Widget build(BuildContext context) {
    final currentContract = _battleContractFor(payload.trainerId);
    final authorableBattles = [
      for (final battle in battles)
        if (battle.battleKind == BattlePublicContractKind.trainer &&
            battle.trainerId.trim().isNotEmpty)
          battle,
    ];
    return _InspectorSection(
      title: 'Combat lié',
      children: [
        _InspectorRow(label: 'battleKind', value: payload.battleKind),
        _InspectorRow(
          label: 'Trainer actuel',
          value: currentContract == null
              ? payload.trainerId ?? 'Aucun trainer.'
              : '${currentContract.trainerLabel} · ${currentContract.trainerId}',
        ),
        _InspectorRow(
          label: 'Outcomes Scene',
          value: _joinOrEmpty(payload.declaredOutcomes),
        ),
        if (currentContract == null)
          const _InspectorRow(
            label: 'Contrat public',
            value: 'Référence actuelle absente des combats publics.',
          )
        else
          _InspectorRow(
            label: 'Outcomes contrat',
            value: _joinOrEmpty([
              for (final outcome in currentContract.possibleOutcomes)
                outcome.id,
            ]),
          ),
        const SizedBox(height: 4),
        PokeMapButton(
          key: const ValueKey('scene-payload-edit-battle-action'),
          onPressed: onUpdatePayload == null || authorableBattles.isEmpty
              ? null
              : () => _pickBattle(context, authorableBattles),
          variant: PokeMapButtonVariant.secondary,
          size: PokeMapButtonSize.small,
          leading: const Icon(CupertinoIcons.asterisk_circle),
          child: const Text('Changer le combat'),
        ),
        const SizedBox(height: 8),
        const _InspectorNote(
          label: 'Cette édition modifie uniquement le payload du nœud Scene. '
              'Le runtime, les events et les liens Storyline ne sont pas '
              'modifiés.',
        ),
      ],
    );
  }

  BattlePublicContract? _battleContractFor(String? trainerId) {
    if (trainerId == null) {
      return null;
    }
    for (final battle in battles) {
      if (battle.trainerId == trainerId) {
        return battle;
      }
    }
    return null;
  }

  Future<void> _pickBattle(
    BuildContext context,
    List<BattlePublicContract> battles,
  ) async {
    final updater = onUpdatePayload;
    if (updater == null) {
      return;
    }
    final contract = await showCupertinoDialog<BattlePublicContract>(
      context: context,
      builder: (context) => _BattlePayloadEditDialog(battles: battles),
    );
    if (contract == null || !context.mounted) {
      return;
    }
    await updater(nodeId: node.id, trainerId: contract.trainerId);
  }
}

class _CinematicPayloadAuthoringPanel extends StatelessWidget {
  const _CinematicPayloadAuthoringPanel({
    required this.node,
    required this.payload,
    required this.library,
    required this.onUpdatePayload,
  });

  final SceneNode node;
  final SceneCinematicPayload payload;
  final CinematicsLibraryReadModel library;
  final SceneCinematicPayloadDraftUpdater? onUpdatePayload;

  @override
  Widget build(BuildContext context) {
    final currentEntry = library.entryById(payload.cinematicId);
    final canonicalEntries = library.canonicalEntries;
    return _InspectorSection(
      title: 'Cinématique',
      children: [
        _InspectorRow(label: 'cinematicId', value: payload.cinematicId),
        if (currentEntry == null) ...[
          const _InspectorRow(
            label: 'Statut',
            value: 'Référence inconnue',
          ),
          const _InspectorNote(
            label: 'Cette référence ne pointe vers aucun CinematicAsset '
                'canonique ni bridge legacy public.',
          ),
        ] else if (currentEntry.kind ==
            CinematicsLibraryEntryKind.scenarioBridge) ...[
          const _InspectorRow(label: 'Statut', value: 'Bridge legacy'),
          _InspectorRow(label: 'Titre', value: currentEntry.title),
          const _InspectorNote(
            label: 'Cette référence pointe vers un bridge Scenario/Cutscene '
                'legacy. Elle reste lisible, mais le workflow canonique '
                'utilise CinematicAsset.',
          ),
        ] else ...[
          const _InspectorRow(label: 'Statut', value: 'CinematicAsset'),
          _InspectorRow(label: 'Titre', value: currentEntry.title),
          _InspectorRow(
            label: 'Map',
            value: currentEntry.mapId ?? 'Aucune map.',
          ),
          _InspectorRow(
            label: 'Storyline',
            value: currentEntry.storylineId ?? 'Aucune storyline.',
          ),
          _InspectorRow(
            label: 'Chapitre',
            value: currentEntry.chapterId ?? 'Aucun chapitre.',
          ),
          _InspectorRow(
            label: 'Timeline',
            value: currentEntry.timeline.isEmpty
                ? 'Timeline vide'
                : '${currentEntry.timeline.stepCount} step(s)',
          ),
          _InspectorRow(
            label: 'Acteurs',
            value: currentEntry.requiredActors.isEmpty
                ? 'Aucun acteur requis.'
                : currentEntry.requiredActors
                    .map((actor) => actor.displayLabel)
                    .join(', '),
          ),
          _InspectorRow(
            label: 'Diagnostics',
            value: currentEntry.diagnostics.isEmpty
                ? 'Aucun diagnostic.'
                : currentEntry.diagnostics
                    .map((diagnostic) => diagnostic.code)
                    .join(', '),
          ),
        ],
        const SizedBox(height: 4),
        PokeMapButton(
          key: const ValueKey('scene-payload-edit-cinematic-action'),
          onPressed: onUpdatePayload == null || canonicalEntries.isEmpty
              ? null
              : () => _pickCinematic(context),
          variant: PokeMapButtonVariant.secondary,
          size: PokeMapButtonSize.small,
          leading: const Icon(CupertinoIcons.film),
          child: Text(
            currentEntry?.kind == CinematicsLibraryEntryKind.scenarioBridge ||
                    currentEntry == null
                ? 'Changer vers une cinématique canonique'
                : 'Changer la cinématique',
          ),
        ),
        const SizedBox(height: 8),
        const _InspectorNote(
          label: 'Cette édition modifie uniquement le payload du nœud Scene. '
              'La timeline, le runtime et les bridges legacy ne sont pas '
              'modifiés.',
        ),
      ],
    );
  }

  Future<void> _pickCinematic(BuildContext context) async {
    final updater = onUpdatePayload;
    if (updater == null) {
      return;
    }
    final selected = await showCupertinoDialog<CinematicsLibraryEntry>(
      context: context,
      builder: (context) => SceneCinematicPickerDialog(library: library),
    );
    if (selected == null || !context.mounted) {
      return;
    }
    await updater(nodeId: node.id, cinematicId: selected.id);
  }
}

class _ActionConsequenceAuthoringPanel extends StatelessWidget {
  const _ActionConsequenceAuthoringPanel({
    required this.node,
    required this.payload,
    required this.factOptions,
    required this.eventOptions,
    required this.onUpdatePayload,
  });

  final SceneNode node;
  final SceneActionPayload payload;
  final List<SceneConsequenceFactPickerOption> factOptions;
  final List<SceneConsequenceEventPickerOption> eventOptions;
  final SceneActionConsequenceDraftUpdater? onUpdatePayload;

  @override
  Widget build(BuildContext context) {
    final consequence = payload.consequence;
    return _InspectorSection(
      title: 'Conséquence',
      children: [
        if (consequence == null) ...[
          const _InspectorRow(
            label: 'Type',
            value: 'Aucune conséquence typée.',
          ),
          const _InspectorNote(
            label: 'Les actionKind legacy restent visibles, mais ne sont pas '
                'le contrat final de Scene V1.',
          ),
        ] else if (consequence is SceneSetFactConsequence)
          ..._setFactRows(context, consequence)
        else if (consequence is SceneMarkEventConsumedConsequence)
          ..._markEventRows(context, consequence)
        else
          const _InspectorRow(
            label: 'Type',
            value: 'Conséquence non reconnue.',
          ),
        const SizedBox(height: 8),
        const _InspectorNote(
          label: 'Scene écrit une conséquence explicite. Les World Rules '
              'liront cet état plus tard ; aucun runtime n’est lancé ici.',
        ),
      ],
    );
  }

  List<Widget> _setFactRows(
    BuildContext context,
    SceneSetFactConsequence consequence,
  ) {
    final fact = _factOptionFor(consequence.factId);
    return [
      const _InspectorRow(label: 'Type', value: 'setFact'),
      _InspectorRow(
        label: 'Fact',
        value: fact == null
            ? consequence.factId
            : '${fact.label} · ${fact.factId}',
      ),
      _InspectorRow(label: 'Valeur', value: consequence.value.toString()),
      const SizedBox(height: 4),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          PokeMapButton(
            key: const ValueKey('scene-consequence-edit-fact-action'),
            onPressed: onUpdatePayload == null || factOptions.isEmpty
                ? null
                : () => _pickFact(context, consequence),
            variant: PokeMapButtonVariant.secondary,
            size: PokeMapButtonSize.small,
            leading: const Icon(CupertinoIcons.check_mark_circled),
            child: const Text('Changer le Fact'),
          ),
          PokeMapButton(
            key: const ValueKey('scene-consequence-value-true'),
            onPressed: onUpdatePayload == null || consequence.value
                ? null
                : () => _updateSetFactValue(consequence, true),
            variant: PokeMapButtonVariant.ghost,
            size: PokeMapButtonSize.small,
            child: const Text('true'),
          ),
          PokeMapButton(
            key: const ValueKey('scene-consequence-value-false'),
            onPressed: onUpdatePayload == null || !consequence.value
                ? null
                : () => _updateSetFactValue(consequence, false),
            variant: PokeMapButtonVariant.ghost,
            size: PokeMapButtonSize.small,
            child: const Text('false'),
          ),
        ],
      ),
    ];
  }

  List<Widget> _markEventRows(
    BuildContext context,
    SceneMarkEventConsumedConsequence consequence,
  ) {
    final event = _eventOptionFor(consequence.mapId, consequence.eventId);
    return [
      const _InspectorRow(label: 'Type', value: 'markEventConsumed'),
      _InspectorRow(
        label: 'Map',
        value: event == null
            ? consequence.mapId
            : '${event.mapLabel} · ${event.mapId}',
      ),
      _InspectorRow(
        label: 'Event',
        value: event == null
            ? consequence.eventId
            : '${event.eventLabel} · ${event.eventId}',
      ),
      const SizedBox(height: 4),
      PokeMapButton(
        key: const ValueKey('scene-consequence-edit-event-action'),
        onPressed: onUpdatePayload == null || eventOptions.isEmpty
            ? null
            : () => _pickEvent(context),
        variant: PokeMapButtonVariant.secondary,
        size: PokeMapButtonSize.small,
        leading: const Icon(CupertinoIcons.flag),
        child: const Text('Changer la cible'),
      ),
    ];
  }

  SceneConsequenceFactPickerOption? _factOptionFor(String factId) {
    for (final option in factOptions) {
      if (option.factId == factId) {
        return option;
      }
    }
    return null;
  }

  SceneConsequenceEventPickerOption? _eventOptionFor(
    String mapId,
    String eventId,
  ) {
    for (final option in eventOptions) {
      if (option.mapId == mapId && option.eventId == eventId) {
        return option;
      }
    }
    return null;
  }

  Future<void> _pickFact(
    BuildContext context,
    SceneSetFactConsequence consequence,
  ) async {
    final updater = onUpdatePayload;
    if (updater == null) {
      return;
    }
    final option = await showCupertinoDialog<SceneConsequenceFactPickerOption>(
      context: context,
      builder: (context) => _SceneConsequenceFactEditDialog(
        facts: factOptions,
      ),
    );
    if (option == null || !context.mounted) {
      return;
    }
    await updater(
      nodeId: node.id,
      consequence: SceneConsequence.setFact(
        factId: option.factId,
        value: consequence.value,
      ),
    );
  }

  Future<void> _pickEvent(BuildContext context) async {
    final updater = onUpdatePayload;
    if (updater == null) {
      return;
    }
    final option = await showCupertinoDialog<SceneConsequenceEventPickerOption>(
      context: context,
      builder: (context) => _SceneConsequenceEventEditDialog(
        events: eventOptions,
      ),
    );
    if (option == null || !context.mounted) {
      return;
    }
    await updater(
      nodeId: node.id,
      consequence: SceneConsequence.markEventConsumed(
        mapId: option.mapId,
        eventId: option.eventId,
      ),
    );
  }

  Future<void> _updateSetFactValue(
    SceneSetFactConsequence consequence,
    bool value,
  ) async {
    final updater = onUpdatePayload;
    if (updater == null) {
      return;
    }
    await updater(
      nodeId: node.id,
      consequence: SceneConsequence.setFact(
        factId: consequence.factId,
        value: value,
      ),
    );
  }
}

class _SceneConsequenceFactEditDialog extends StatelessWidget {
  const _SceneConsequenceFactEditDialog({required this.facts});

  final List<SceneConsequenceFactPickerOption> facts;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      key: const ValueKey('scene-consequence-fact-edit-dialog'),
      title: const Text('Choisir un Fact'),
      content: _PayloadEditDialogContent(
        children: [
          for (final fact in facts)
            _PayloadEditOptionButton(
              key: ValueKey(
                'scene-consequence-fact-edit-option-'
                '${_payloadEditKeyPart(fact.factId)}',
              ),
              title: fact.label,
              subtitle: fact.factId,
              details: [
                if (fact.category.isNotEmpty) fact.category,
                if (fact.description.isNotEmpty) fact.description,
              ],
              diagnostics: const [],
              onPressed: () => Navigator.of(context).pop(fact),
            ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('Annuler'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _SceneConsequenceEventEditDialog extends StatelessWidget {
  const _SceneConsequenceEventEditDialog({required this.events});

  final List<SceneConsequenceEventPickerOption> events;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      key: const ValueKey('scene-consequence-event-edit-dialog'),
      title: const Text('Choisir un event'),
      content: _PayloadEditDialogContent(
        children: [
          for (final event in events)
            _PayloadEditOptionButton(
              key: ValueKey(
                'scene-consequence-event-edit-option-'
                '${_payloadEditKeyPart(event.mapId)}-'
                '${_payloadEditKeyPart(event.eventId)}',
              ),
              title: event.eventLabel,
              subtitle: event.eventId,
              details: [
                '${event.mapLabel} · ${event.mapId}',
                if (event.debugTechnicalLabel.isNotEmpty)
                  event.debugTechnicalLabel,
              ],
              diagnostics: const [],
              onPressed: () => Navigator.of(context).pop(event),
            ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('Annuler'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _DialoguePayloadEditDialog extends StatelessWidget {
  const _DialoguePayloadEditDialog({required this.dialogues});

  final List<DialoguePublicContract> dialogues;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      key: const ValueKey('scene-dialogue-payload-edit-dialog'),
      title: const Text('Choisir un dialogue'),
      content: _PayloadEditDialogContent(
        children: [
          for (final dialogue in dialogues)
            _PayloadEditOptionButton(
              key: ValueKey(
                'scene-dialogue-payload-edit-option-${dialogue.id}',
              ),
              title: dialogue.label,
              subtitle: dialogue.id,
              details: [
                dialogue.sourceRef,
                if (dialogue.defaultStartNode != null)
                  'Start: ${dialogue.defaultStartNode}',
              ],
              diagnostics: dialogue.diagnostics,
              onPressed: () => Navigator.of(context).pop(dialogue),
            ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('Annuler'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _BattlePayloadEditDialog extends StatelessWidget {
  const _BattlePayloadEditDialog({required this.battles});

  final List<BattlePublicContract> battles;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      key: const ValueKey('scene-battle-payload-edit-dialog'),
      title: const Text('Choisir un combat'),
      content: _PayloadEditDialogContent(
        children: [
          for (final battle in battles)
            _PayloadEditOptionButton(
              key: ValueKey(
                'scene-battle-payload-edit-option-'
                '${_payloadEditKeyPart(battle.trainerId)}',
              ),
              title: battle.label,
              subtitle: battle.trainerId,
              details: [
                battle.battleKind.name,
                battle.trainerLabel,
                battle.possibleOutcomes
                    .map((outcome) => outcome.id)
                    .join(' / '),
              ],
              diagnostics: battle.diagnostics,
              onPressed: () => Navigator.of(context).pop(battle),
            ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('Annuler'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _PayloadEditDialogContent extends StatelessWidget {
  const _PayloadEditDialogContent({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _PayloadEditOptionButton extends StatelessWidget {
  const _PayloadEditOptionButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.details,
    required this.diagnostics,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final List<String> details;
  final List<LinkedAssetContractDiagnostic> diagnostics;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PokeMapCard(
        onTap: onPressed,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            for (final detail in details.where((value) => value.isNotEmpty))
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            for (final diagnostic in diagnostics)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  diagnostic.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _linkedAssetDiagnosticColor(
                      context,
                      diagnostic.severity,
                    ),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EdgesSection extends StatelessWidget {
  const _EdgesSection({
    super.key,
    required this.title,
    required this.emptyLabel,
    required this.edges,
    required this.selectedNodeId,
    required this.incoming,
  });

  final String title;
  final String emptyLabel;
  final List<SceneEdge> edges;
  final String selectedNodeId;
  final bool incoming;

  @override
  Widget build(BuildContext context) {
    return _InspectorSection(
      title: title,
      children: [
        if (edges.isEmpty)
          _InspectorRow(label: 'Edges', value: emptyLabel)
        else
          for (final edge in edges)
            _InspectorRow(
              label: edge.id,
              value: incoming
                  ? '${_edgeKindLabel(edge.kind)} · '
                      '${edge.fromNodeId} → $selectedNodeId · '
                      '${edge.fromPortId}'
                  : '${_edgeKindLabel(edge.kind)} · '
                      '$selectedNodeId → ${edge.toNodeId} · '
                      '${edge.fromPortId}',
            ),
      ],
    );
  }
}

class _ConditionAuthoringPanel extends StatefulWidget {
  const _ConditionAuthoringPanel({
    required this.node,
    required this.options,
    required this.onUpdateConditionSource,
  });

  final SceneNode node;
  final List<SceneConditionSourcePickerOption> options;
  final SceneConditionSourceDraftUpdater? onUpdateConditionSource;

  @override
  State<_ConditionAuthoringPanel> createState() =>
      _ConditionAuthoringPanelState();
}

class _ConditionAuthoringPanelState extends State<_ConditionAuthoringPanel> {
  late SceneConditionSourceKind _sourceKind;
  String? _sourceId;
  late SceneConditionOperator _operator;
  String? _value;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _initializeFromPayload();
  }

  @override
  void didUpdateWidget(covariant _ConditionAuthoringPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node != widget.node || oldWidget.options != widget.options) {
      _initializeFromPayload();
    }
  }

  void _initializeFromPayload() {
    final payload = widget.node.payload;
    final source =
        payload is SceneConditionPayload ? payload.conditionSource : null;
    _sourceKind = source?.sourceKind ?? _firstAvailableKind();
    _operator = _defaultOperatorForKind(_sourceKind);
    _value = _defaultValueForKind(_sourceKind);
    _sourceId = null;

    if (source != null && _isSourceKindAuthorable(source.sourceKind)) {
      _sourceKind = source.sourceKind;
      _operator = source.operator;
      _value = source.value ?? _defaultValueForKind(_sourceKind);
      if (_optionsForKind(_sourceKind)
          .any((option) => option.sourceId == source.sourceId)) {
        _sourceId = source.sourceId;
      }
    }

    _sourceId ??= _optionsForKind(_sourceKind).firstOrNull?.sourceId;
  }

  @override
  Widget build(BuildContext context) {
    return _InspectorSection(
      title: 'Configurer la condition',
      children: [
        Column(
          key: const ValueKey('scene-condition-authoring-panel'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ConditionButtonRow(
              label: 'Source',
              children: [
                if (_optionsForKind(SceneConditionSourceKind.fact).isNotEmpty)
                  _conditionButton(
                    key: const ValueKey(
                      'scene-condition-source-kind-fact',
                    ),
                    label: 'Fact Registry',
                    selected: _sourceKind == SceneConditionSourceKind.fact,
                    onPressed: () => _selectSourceKind(
                      SceneConditionSourceKind.fact,
                    ),
                  ),
                _conditionButton(
                  key: const ValueKey(
                    'scene-condition-source-kind-factLikeStoryFlag',
                  ),
                  label: 'Fact-like',
                  selected:
                      _sourceKind == SceneConditionSourceKind.factLikeStoryFlag,
                  onPressed: () => _selectSourceKind(
                    SceneConditionSourceKind.factLikeStoryFlag,
                  ),
                ),
                _conditionButton(
                  key: const ValueKey(
                    'scene-condition-source-kind-storyStepCompletion',
                  ),
                  label: 'Story step',
                  selected: _sourceKind ==
                      SceneConditionSourceKind.storyStepCompletion,
                  onPressed: () => _selectSourceKind(
                    SceneConditionSourceKind.storyStepCompletion,
                  ),
                ),
                _conditionButton(
                  key: const ValueKey(
                    'scene-condition-source-kind-consumedEvent',
                  ),
                  label: 'Event consommé',
                  selected:
                      _sourceKind == SceneConditionSourceKind.consumedEvent,
                  onPressed: () => _selectSourceKind(
                    SceneConditionSourceKind.consumedEvent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _ConditionButtonRow(
              label: 'Référence',
              children: _referenceButtons(),
            ),
            if (_sourceKind == SceneConditionSourceKind.fact &&
                _selectedOptionSummary != null) ...[
              const SizedBox(height: 2),
              _ConditionMutedLabel(
                key: const ValueKey('scene-condition-selected-source-summary'),
                label: _selectedOptionSummary!,
              ),
            ],
            const SizedBox(height: 8),
            _ConditionButtonRow(
              label: 'Opérateur',
              children: _operatorButtons(),
            ),
            const SizedBox(height: 10),
            PokeMapButton(
              key: const ValueKey('scene-condition-save-action'),
              onPressed: _canSave ? _save : null,
              variant: PokeMapButtonVariant.primary,
              size: PokeMapButtonSize.small,
              leading: const Icon(CupertinoIcons.check_mark_circled),
              child: Text(_saving ? 'Enregistrement...' : 'Enregistrer'),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _referenceButtons() {
    final options = _optionsForKind(_sourceKind);
    if (options.isEmpty) {
      return const [
        _ConditionMutedLabel(
          key: ValueKey('scene-condition-no-source-options'),
          label: 'Aucune référence existante pour cette source.',
        ),
      ];
    }
    return [
      for (final option in options)
        _conditionButton(
          key: ValueKey(
            'scene-condition-source-option-'
            '${option.sourceKind.name}-${option.sourceId}',
          ),
          label: option.label,
          selected: option.sourceId == _sourceId,
          onPressed: () => setState(() => _sourceId = option.sourceId),
        ),
    ];
  }

  List<Widget> _operatorButtons() {
    if (_sourceKind == SceneConditionSourceKind.storyStepCompletion) {
      return [
        _conditionButton(
          key: const ValueKey('scene-condition-value-completed'),
          label: 'Completed',
          selected: _value == SceneConditionValues.completed,
          onPressed: () => setState(() {
            _operator = SceneConditionOperator.equals;
            _value = SceneConditionValues.completed;
          }),
        ),
        _conditionButton(
          key: const ValueKey('scene-condition-value-notCompleted'),
          label: 'Not completed',
          selected: _value == SceneConditionValues.notCompleted,
          onPressed: () => setState(() {
            _operator = SceneConditionOperator.equals;
            _value = SceneConditionValues.notCompleted;
          }),
        ),
      ];
    }
    return [
      _conditionButton(
        key: const ValueKey('scene-condition-operator-isTrue'),
        label: 'Est vrai',
        selected: _operator == SceneConditionOperator.isTrue,
        onPressed: () => setState(() {
          _operator = SceneConditionOperator.isTrue;
          _value = null;
        }),
      ),
      _conditionButton(
        key: const ValueKey('scene-condition-operator-isFalse'),
        label: 'Est faux',
        selected: _operator == SceneConditionOperator.isFalse,
        onPressed: () => setState(() {
          _operator = SceneConditionOperator.isFalse;
          _value = null;
        }),
      ),
    ];
  }

  Widget _conditionButton({
    required Key key,
    required String label,
    required bool selected,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6, bottom: 6),
      child: PokeMapButton(
        key: key,
        onPressed: onPressed,
        variant: selected
            ? PokeMapButtonVariant.secondary
            : PokeMapButtonVariant.ghost,
        size: PokeMapButtonSize.small,
        child: Text(label),
      ),
    );
  }

  void _selectSourceKind(SceneConditionSourceKind kind) {
    setState(() {
      _sourceKind = kind;
      _operator = _defaultOperatorForKind(kind);
      _value = _defaultValueForKind(kind);
      _sourceId = _optionsForKind(kind).firstOrNull?.sourceId;
    });
  }

  Future<void> _save() async {
    final updater = widget.onUpdateConditionSource;
    final option = _selectedOption;
    if (updater == null || option == null) {
      return;
    }
    setState(() => _saving = true);
    final saved = await updater(
      nodeId: widget.node.id,
      source: SceneConditionSource(
        sourceKind: _sourceKind,
        sourceId: option.sourceId,
        operator: _operator,
        value: _sourceKind == SceneConditionSourceKind.storyStepCompletion
            ? _value
            : null,
        label: option.label,
        debugTechnicalLabel: option.debugTechnicalLabel,
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (!saved) {
      return;
    }
  }

  bool get _canSave =>
      !_saving &&
      widget.onUpdateConditionSource != null &&
      _selectedOption != null &&
      (_sourceKind != SceneConditionSourceKind.storyStepCompletion ||
          _value != null);

  SceneConditionSourcePickerOption? get _selectedOption {
    final selected = _sourceId;
    if (selected == null) {
      return null;
    }
    for (final option in _optionsForKind(_sourceKind)) {
      if (option.sourceId == selected) {
        return option;
      }
    }
    return null;
  }

  String? get _selectedOptionSummary {
    final option = _selectedOption;
    if (option == null) {
      return null;
    }
    final parts = [
      option.category.trim(),
      option.description.trim(),
    ].where((part) => part.isNotEmpty).toList(growable: false);
    return parts.isEmpty ? option.debugTechnicalLabel : parts.join(' · ');
  }

  List<SceneConditionSourcePickerOption> _optionsForKind(
    SceneConditionSourceKind kind,
  ) {
    return [
      for (final option in widget.options)
        if (option.sourceKind == kind) option,
    ];
  }

  SceneConditionSourceKind _firstAvailableKind() {
    for (final kind in const [
      SceneConditionSourceKind.fact,
      SceneConditionSourceKind.factLikeStoryFlag,
      SceneConditionSourceKind.storyStepCompletion,
      SceneConditionSourceKind.consumedEvent,
    ]) {
      if (_optionsForKind(kind).isNotEmpty) {
        return kind;
      }
    }
    return SceneConditionSourceKind.factLikeStoryFlag;
  }

  bool _isSourceKindAuthorable(SceneConditionSourceKind kind) {
    return switch (kind) {
      SceneConditionSourceKind.factLikeStoryFlag ||
      SceneConditionSourceKind.fact ||
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
}

class _ConditionButtonRow extends StatelessWidget {
  const _ConditionButtonRow({
    required this.label,
    required this.children,
  });

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(children: children),
      ],
    );
  }
}

class _ConditionMutedLabel extends StatelessWidget {
  const _ConditionMutedLabel({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Text(
      label,
      style: TextStyle(
        color: colors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _InspectorNote extends StatelessWidget {
  const _InspectorNote({
    this.label =
        'L’édition arrive plus tard. Aucun champ n’est modifiable dans ce lot.',
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Text(
      label,
      style: TextStyle(
        color: colors.textSecondary,
        fontSize: 11,
        height: 1.35,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _InspectorChip extends StatelessWidget {
  const _InspectorChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.controlSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

List<Widget> _payloadRows(SceneNodePayload payload) {
  return switch (payload) {
    SceneStartPayload(:final notes) => [
        const _InspectorRow(label: 'Type', value: 'Début'),
        _InspectorRow(label: 'Notes', value: notes ?? 'Aucune note.'),
        const _InspectorRow(label: 'Sortie attendue', value: 'completed'),
      ],
    SceneEndPayload(:final sceneOutcomeId, :final notes) => [
        const _InspectorRow(label: 'Type', value: 'Fin'),
        _InspectorRow(
          label: 'Scene outcome',
          value: sceneOutcomeId ?? 'Aucun outcome.',
        ),
        _InspectorRow(label: 'Notes', value: notes ?? 'Aucune note.'),
      ],
    SceneYarnDialoguePayload(
      :final dialogueId,
      :final yarnNodeName,
      :final expectedOutcomes,
      :final speakerHints,
    ) =>
      [
        _InspectorRow(label: 'dialogueId', value: dialogueId),
        _InspectorRow(
          label: 'yarnNodeName',
          value: yarnNodeName ?? 'Aucun node Yarn.',
        ),
        _InspectorRow(
          label: 'expectedOutcomes',
          value: _joinOrEmpty(expectedOutcomes),
        ),
        _InspectorRow(label: 'speakerHints', value: _joinOrEmpty(speakerHints)),
      ],
    SceneConditionPayload(
      :final conditionLabel,
      :final conditionRef,
      :final conditionDraft,
      :final conditionSource,
    ) =>
      [
        _InspectorRow(
          label: 'conditionLabel',
          value: conditionLabel ?? 'Aucun label.',
        ),
        _InspectorRow(
          label: 'conditionRef',
          value: conditionRef ?? 'Aucune ref.',
        ),
        _InspectorRow(
          label: 'conditionDraft',
          value: conditionDraft ?? 'Aucun draft.',
        ),
        _InspectorRow(
          label: 'sourceKind',
          value: conditionSource?.sourceKind.name ?? 'Aucune source.',
        ),
        _InspectorRow(
          label: 'sourceId',
          value: conditionSource?.sourceId ?? 'Aucune source.',
        ),
        _InspectorRow(
          label: 'operator',
          value: conditionSource?.operator.name ?? 'Aucun opérateur.',
        ),
        _InspectorRow(
          label: 'value',
          value: conditionSource?.value ?? 'Aucune valeur.',
        ),
        const _InspectorRow(label: 'Sorties attendues', value: 'true / false'),
      ],
    SceneActionPayload(
      :final actionKind,
      :final parameters,
      :final consequence,
    ) =>
      [
        _InspectorRow(
          label: 'actionKind',
          value: actionKind ?? 'Aucune action legacy.',
        ),
        _InspectorRow(
          label: 'parameters',
          value: parameters.isEmpty
              ? 'Aucun paramètre.'
              : parameters.entries
                  .map((entry) => '${entry.key}=${entry.value}')
                  .join(', '),
        ),
        ..._sceneConsequenceRows(consequence),
        const _InspectorRow(label: 'Sortie attendue', value: 'completed'),
      ],
    SceneBattlePayload(
      :final battleKind,
      :final trainerId,
      :final battleTemplateId,
      :final npcEntityId,
      :final declaredOutcomes,
    ) =>
      [
        _InspectorRow(label: 'battleKind', value: battleKind),
        _InspectorRow(label: 'trainerId', value: trainerId ?? 'Aucun trainer.'),
        _InspectorRow(
          label: 'battleTemplateId',
          value: battleTemplateId ?? 'Aucun template.',
        ),
        _InspectorRow(label: 'npcEntityId', value: npcEntityId ?? 'Aucun NPC.'),
        _InspectorRow(
          label: 'declaredOutcomes',
          value: _joinOrEmpty(declaredOutcomes),
        ),
        const _InspectorRow(
            label: 'Sorties attendues', value: 'victory / defeat'),
      ],
    SceneCinematicPayload(:final cinematicId) => [
        _InspectorRow(label: 'cinematicId', value: cinematicId),
        const _InspectorRow(label: 'Sortie attendue', value: 'completed'),
      ],
    SceneBranchByOutcomePayload(
      :final sourceNodeId,
      :final sourceOutcomeSetRef,
      :final fallbackPolicy,
    ) =>
      [
        _InspectorRow(
          label: 'sourceNodeId',
          value: sourceNodeId ?? 'Aucun node source.',
        ),
        _InspectorRow(
          label: 'sourceOutcomeSetRef',
          value: sourceOutcomeSetRef ?? 'Aucun outcome set.',
        ),
        _InspectorRow(
          label: 'fallbackPolicy',
          value: fallbackPolicy ?? 'Aucune policy.',
        ),
      ],
    SceneMergePayload(:final label, :final notes) => [
        _InspectorRow(label: 'label', value: label ?? 'Aucun label.'),
        _InspectorRow(label: 'notes', value: notes ?? 'Aucune note.'),
      ],
    _ => const [
        _InspectorRow(label: 'Payload', value: 'Payload non reconnu.'),
      ],
  };
}

List<Widget> _sceneConsequenceRows(SceneConsequence? consequence) {
  if (consequence == null) {
    return const [
      _InspectorRow(label: 'consequence', value: 'Aucune conséquence typée.'),
    ];
  }
  if (consequence is SceneSetFactConsequence) {
    return [
      const _InspectorRow(label: 'consequence', value: 'setFact'),
      _InspectorRow(label: 'factId', value: consequence.factId),
      _InspectorRow(label: 'value', value: consequence.value.toString()),
    ];
  }
  if (consequence is SceneMarkEventConsumedConsequence) {
    return [
      const _InspectorRow(
        label: 'consequence',
        value: 'markEventConsumed',
      ),
      _InspectorRow(label: 'mapId', value: consequence.mapId),
      _InspectorRow(label: 'eventId', value: consequence.eventId),
    ];
  }
  return const [
    _InspectorRow(label: 'consequence', value: 'Conséquence non reconnue.'),
  ];
}

SceneConditionOperator _defaultOperatorForKind(SceneConditionSourceKind kind) {
  return switch (kind) {
    SceneConditionSourceKind.storyStepCompletion =>
      SceneConditionOperator.equals,
    SceneConditionSourceKind.fact ||
    SceneConditionSourceKind.factLikeStoryFlag ||
    SceneConditionSourceKind.consumedEvent =>
      SceneConditionOperator.isTrue,
    SceneConditionSourceKind.storyStepActive ||
    SceneConditionSourceKind.inventoryItem ||
    SceneConditionSourceKind.partyState ||
    SceneConditionSourceKind.trainerDefeated ||
    SceneConditionSourceKind.dialogueOutcome ||
    SceneConditionSourceKind.battleOutcome ||
    SceneConditionSourceKind.scriptVariable ||
    SceneConditionSourceKind.worldState =>
      SceneConditionOperator.isTrue,
  };
}

String? _defaultValueForKind(SceneConditionSourceKind kind) {
  return switch (kind) {
    SceneConditionSourceKind.storyStepCompletion =>
      SceneConditionValues.completed,
    SceneConditionSourceKind.fact ||
    SceneConditionSourceKind.factLikeStoryFlag ||
    SceneConditionSourceKind.consumedEvent ||
    SceneConditionSourceKind.storyStepActive ||
    SceneConditionSourceKind.inventoryItem ||
    SceneConditionSourceKind.partyState ||
    SceneConditionSourceKind.trainerDefeated ||
    SceneConditionSourceKind.dialogueOutcome ||
    SceneConditionSourceKind.battleOutcome ||
    SceneConditionSourceKind.scriptVariable ||
    SceneConditionSourceKind.worldState =>
      null,
  };
}

String _nodeInspectorModeLabel(
  SceneNode node,
  LinkedAssetContractsSnapshot? linkedAssetContracts,
) {
  return switch (node.kind) {
    SceneNodeKind.condition => 'Authoring V0',
    SceneNodeKind.yarnDialogue =>
      (linkedAssetContracts?.dialogues.isNotEmpty ?? false)
          ? 'Éditable'
          : 'Lecture seule',
    SceneNodeKind.battle => (linkedAssetContracts?.battles.isNotEmpty ?? false)
        ? 'Éditable'
        : 'Lecture seule',
    SceneNodeKind.action => 'Éditable',
    SceneNodeKind.start ||
    SceneNodeKind.end ||
    SceneNodeKind.cinematic ||
    SceneNodeKind.branchByOutcome ||
    SceneNodeKind.merge =>
      'Lecture seule',
  };
}

Color _linkedAssetDiagnosticColor(
  BuildContext context,
  LinkedAssetContractDiagnosticSeverity severity,
) {
  final colors = context.pokeMapColors;
  return switch (severity) {
    LinkedAssetContractDiagnosticSeverity.error => colors.error,
    LinkedAssetContractDiagnosticSeverity.warning => colors.warning,
    LinkedAssetContractDiagnosticSeverity.info => colors.textMuted,
  };
}

String _payloadEditKeyPart(String value) {
  final buffer = StringBuffer();
  var wroteSeparator = false;
  for (final codeUnit in value.trim().toLowerCase().codeUnits) {
    final isDigit = codeUnit >= 48 && codeUnit <= 57;
    final isAsciiLetter = codeUnit >= 97 && codeUnit <= 122;
    if (isDigit || isAsciiLetter) {
      buffer.writeCharCode(codeUnit);
      wroteSeparator = false;
    } else if (!wroteSeparator && buffer.isNotEmpty) {
      buffer.write('_');
      wroteSeparator = true;
    }
  }
  final slug = buffer.toString();
  return slug.endsWith('_') ? slug.substring(0, slug.length - 1) : slug;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    for (final item in this) {
      return item;
    }
    return null;
  }
}

String _joinOrEmpty(List<String> values) {
  return values.isEmpty ? 'Aucun.' : values.join(', ');
}

String _nodeKindLabel(SceneNodeKind kind) {
  return switch (kind) {
    SceneNodeKind.start => 'Début',
    SceneNodeKind.end => 'Fin',
    SceneNodeKind.yarnDialogue => 'Dialogue Yarn',
    SceneNodeKind.condition => 'Condition',
    SceneNodeKind.action => 'Action',
    SceneNodeKind.battle => 'Combat',
    SceneNodeKind.cinematic => 'Cinématique',
    SceneNodeKind.branchByOutcome => 'Branche',
    SceneNodeKind.merge => 'Merge',
  };
}

String _nodeLabel(NarrativeSceneSummary scene, String nodeId) {
  for (final node in scene.graph.nodes) {
    if (node.id == nodeId) {
      final title = node.title;
      if (title == null || title.trim().isEmpty) {
        return nodeId;
      }
      return '$title · $nodeId';
    }
  }
  return nodeId;
}

String _edgeKindLabel(SceneEdgeKind kind) {
  return switch (kind) {
    SceneEdgeKind.defaultFlow => 'default',
    SceneEdgeKind.conditionTrue => 'true',
    SceneEdgeKind.conditionFalse => 'false',
    SceneEdgeKind.dialogueOutcome => 'dialogue',
    SceneEdgeKind.battleVictory => 'victory',
    SceneEdgeKind.battleDefeat => 'defeat',
    SceneEdgeKind.cinematicCompleted => 'cinematic',
    SceneEdgeKind.actionCompleted => 'action',
    SceneEdgeKind.branchOutcome => 'branch',
    SceneEdgeKind.error => 'error',
    SceneEdgeKind.blocked => 'blocked',
  };
}
