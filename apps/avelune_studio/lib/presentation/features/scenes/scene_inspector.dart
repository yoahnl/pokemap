export '../../../features/scenes/application/scene_labels.dart';

import 'package:flutter/material.dart';

import '../../../features/pokemon/domain/pokemon_workspace_models.dart';

import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_panel.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_section.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_commit_field.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_notice.dart';
import 'package:avelune_studio/features/scenes/application/scene_edit_session.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_graph_canvas.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_action_form.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_condition_form.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_linked_document.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_dialogue_choice_policy_form.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_dialogue_line_policy_form.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';

import 'scene_battle_demonstration_form.dart';

part 'scene_inspector_fields.dart';

class SceneInspector extends StatelessWidget {
  const SceneInspector({
    super.key,
    required this.session,
    required this.project,
    required this.nodeId,
    required this.edgeId,
    required this.changed,
    required this.onDocument,
    required this.onDelete,
    required this.onDuplicate,
    this.onFocusNode,
    this.documents,
    this.narrative,
    this.onCreatePresentation,
    this.loadMap,
    this.loadMoves,
    this.loadItems,
    this.loadCaptureItems,
    this.loadSpecies,
    this.loadVisualMedia,
  });
  final SceneLinkedDocuments? documents;
  final NarrativeWorkspaceController? narrative;
  final SceneEditSession session;
  final ProjectManifest project;
  final String? nodeId, edgeId;
  final VoidCallback changed, onDelete, onDuplicate;
  final ValueChanged<SceneNode> onDocument;
  final ValueChanged<String>? onFocusNode;
  final ValueChanged<SceneNode>? onCreatePresentation;
  final Future<MapData> Function(String)? loadMap;
  final Future<Map<String, String>> Function()? loadMoves;
  final Future<Map<String, String>> Function()? loadItems;
  final Future<Map<String, String>> Function()? loadCaptureItems;
  final Future<List<PokemonSpeciesSummary>> Function()? loadSpecies;
  final Future<ProjectMediaCatalog> Function()? loadVisualMedia;

  void edit(SceneAsset Function(SceneAsset) mutation) {
    session.mutate(mutation);
    changed();
  }

  void payload(SceneNode node, SceneNodePayload value) {
    session.replacePayload(node, value);
    changed();
  }

  Future<void> retargetDialogue(
    BuildContext context,
    SceneNode node,
    SceneYarnDialoguePayload original,
    ProjectDialogueEntry target, {
    required String? start,
    required List<String> outcomes,
  }) async {
    await session.retargetDialogue(
      node: node,
      original: original,
      target: target,
      start: start,
      outcomes: outcomes,
      read: documents == null || narrative == null
          ? null
          : () =>
                documents!.readDialogueDocument(target.id, project, narrative),
      isActive: () => context.mounted,
    );
    if (context.mounted) changed();
  }

  @override
  Widget build(BuildContext context) {
    final scene = session.current;
    final node = scene.graph.nodes.where((n) => n.id == nodeId).firstOrNull;
    final edge = scene.graph.edges.where((e) => e.id == edgeId).firstOrNull;
    return StudioPanel(
      title: 'Propriétés',
      compact: true,
      children: [
        Expanded(
          child: ListView(
            key: ValueKey(
              'scene-inspector-${node?.id ?? edge?.id ?? scene.id}',
            ),
            children: [
              if (node != null) ...[
                Row(
                  children: [
                    Icon(
                      sceneBlockIcon(node.kind),
                      color: sceneBlockColor(context, node.kind),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sceneBlockLabel(node.kind),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                StudioCommitField(
                  label: 'Nom du bloc',
                  value: node.title ?? '',
                  onCommit: (title) => edit(
                    (current) => replaceSceneNode(
                      current,
                      SceneNode(
                        id: node.id,
                        kind: node.kind,
                        title: title.trim().isEmpty ? null : title.trim(),
                        description: node.description,
                        payload: node.payload,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ..._fields(context, node),
                if (onCreatePresentation != null &&
                    scene.executionProfile ==
                        SceneExecutionProfile.preSession &&
                    node.kind != SceneNodeKind.start) ...[
                  const SizedBox(height: 12),
                  StudioButton(
                    label: 'Créer une présentation liée',
                    secondary: true,
                    onPressed: session.base == null || session.saving
                        ? null
                        : () => onCreatePresentation!(node),
                  ),
                  const Text(
                    'Enregistrer la présentation publiera aussi cette scène.',
                  ),
                ],
                const SizedBox(height: 20),
                SceneNodeLinks(
                  scene: scene,
                  node: node,
                  onFocusNode: onFocusNode,
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StudioButton(
                      label: 'Dupliquer',
                      secondary: true,
                      onPressed: node.kind == SceneNodeKind.start
                          ? null
                          : onDuplicate,
                    ),
                    StudioButton(
                      label: 'Supprimer',
                      secondary: true,
                      onPressed: node.kind == SceneNodeKind.start
                          ? null
                          : onDelete,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SelectableText(
                  'ID : ${node.id}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ] else if (edge != null) ...[
                Text(
                  'Connexion',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  '${scene.graph.nodes.firstWhere((n) => n.id == edge.fromNodeId).title ?? edge.fromNodeId} → ${scene.graph.nodes.firstWhere((n) => n.id == edge.toNodeId).title ?? edge.toNodeId}',
                ),
                Text('Sortie : ${edge.fromPortId}'),
                const SizedBox(height: 16),
                StudioButton(
                  label: 'Déconnecter',
                  secondary: true,
                  icon: Icons.link_off,
                  onPressed: onDelete,
                ),
              ] else ...[
                StudioCommitField(
                  label: 'Nom de la scène',
                  value: scene.name,
                  onCommit: (value) {
                    session.rename(value);
                    changed();
                  },
                ),
                const SizedBox(height: 16),
                const StudioNotice(
                  'Sélectionnez un bloc ou un fil pour le modifier. Les dialogues et cinématiques restent leurs propres documents.',
                ),
                const SizedBox(height: 20),
                Text(
                  'Résultats publics',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                for (final outcome in scene.declaredOutcomes)
                  Text(outcome.label),
                StudioButton(
                  label: 'Ajouter un résultat',
                  secondary: true,
                  onPressed: () => _addOutcome(context),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _addOutcome(BuildContext context) async {
    var text = '';
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau résultat public'),
        content: TextField(
          onChanged: (value) => text = value,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nom'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (text.trim().isNotEmpty) {
                Navigator.pop(context, text.trim());
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    if (name == null) return;
    session.addOutcome(name);
    changed();
  }
}

class SceneNodeLinks extends StatelessWidget {
  const SceneNodeLinks({
    super.key,
    required this.scene,
    required this.node,
    this.onFocusNode,
  });

  final SceneAsset scene;
  final SceneNode node;
  final ValueChanged<String>? onFocusNode;

  @override
  Widget build(BuildContext context) {
    final graph = scene.graph;
    final small = Theme.of(context).textTheme.bodySmall;
    final incoming = [
      for (final edge in graph.edges)
        if (edge.toNodeId == node.id) edge,
    ];
    final ports = authorableSceneOutputPortsForNodeInGraph(node, graph);
    Widget link(String key, String label, String target) => Align(
      alignment: Alignment.centerLeft,
      child: StudioButton(
        key: ValueKey(key),
        label: label,
        icon: Icons.arrow_forward,
        variant: StudioButtonVariant.quiet,
        onPressed: onFocusNode == null ? null : () => onFocusNode!(target),
      ),
    );
    return Column(
      key: ValueKey('scene-node-links-${node.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Entrées', style: Theme.of(context).textTheme.titleSmall),
        if (node.kind == SceneNodeKind.start)
          Text('Point d’entrée de la scène.', style: small)
        else if (incoming.isEmpty)
          Text(
            'Aucun bloc ne mène ici : ce bloc ne sera jamais atteint.',
            style: small,
          )
        else
          for (final edge in incoming)
            link(
              'scene-node-in-${edge.id}',
              '${sceneNodeName(graph, edge.fromNodeId)} · ${scenePortLabel(edge.fromPortId)}',
              edge.fromNodeId,
            ),
        const SizedBox(height: 12),
        Text('Sorties', style: Theme.of(context).textTheme.titleSmall),
        if (ports.isEmpty)
          Text('Fin de la scène : aucune sortie.', style: small),
        for (final port in ports)
          if (graph.edges
                  .where(
                    (edge) =>
                        edge.fromNodeId == node.id &&
                        edge.fromPortId == port.id,
                  )
                  .firstOrNull
              case final edge?)
            link(
              'scene-node-out-${node.id}-${port.id}',
              '${scenePortLabel(port.id)} → ${sceneNodeName(graph, edge.toNodeId)}',
              edge.toNodeId,
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '${scenePortLabel(port.id)} · non reliée',
                key: ValueKey('scene-node-out-${node.id}-${port.id}'),
                style: small,
              ),
            ),
      ],
    );
  }
}
