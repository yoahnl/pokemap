import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../features/narrative/application/narrative_workspace_projection.dart';
import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

class SceneNodeReadOnlyInspector extends StatelessWidget {
  const SceneNodeReadOnlyInspector({
    super.key,
    required this.scene,
    required this.selectedNodeId,
  });

  final NarrativeSceneSummary scene;
  final String? selectedNodeId;

  @override
  Widget build(BuildContext context) {
    final node = _selectedNode;
    return PokeMapInspectorPanel(
      key: const ValueKey('scene-node-read-only-inspector'),
      padding: const EdgeInsets.all(12),
      header: const _InspectorHeader(),
      child: node == null
          ? const _NodeInspectorEmptyState()
          : _NodeInspectorBody(scene: scene, node: node),
    );
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
  const _InspectorHeader();

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
              'Détails du nœud',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const _InspectorChip(label: 'Lecture seule'),
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
  });

  final NarrativeSceneSummary scene;
  final SceneNode node;

  @override
  Widget build(BuildContext context) {
    final incoming = scene.graph.edges
        .where((edge) => edge.toNodeId == node.id)
        .toList(growable: false);
    final outgoing = scene.graph.edges
        .where((edge) => edge.fromNodeId == node.id)
        .toList(growable: false);

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
          const _InspectorNote(),
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

class _InspectorNote extends StatelessWidget {
  const _InspectorNote();

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Text(
      'L’édition arrive plus tard. Aucun champ n’est modifiable dans ce lot.',
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
        const _InspectorRow(label: 'Sorties attendues', value: 'true / false'),
      ],
    SceneActionPayload(:final actionKind, :final parameters) => [
        _InspectorRow(label: 'actionKind', value: actionKind),
        _InspectorRow(
          label: 'parameters',
          value: parameters.isEmpty
              ? 'Aucun paramètre.'
              : parameters.entries
                  .map((entry) => '${entry.key}=${entry.value}')
                  .join(', '),
        ),
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
