import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_panel.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_commit_field.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_notice.dart';
import 'package:avelune_studio/features/scenes/application/scene_edit_session.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_graph_canvas.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_action_form.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_condition_form.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_linked_document.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';

part 'scene_inspector_fields.dart';

SceneAsset replaceSceneNode(SceneAsset scene, SceneNode node) =>
    SceneAsset.fromJson({
      ...scene.toJson(),
      'graph': {
        ...scene.graph.toJson(),
        'nodes': [
          for (final current in scene.graph.nodes)
            (current.id == node.id ? node : current).toJson(),
        ],
      },
    });

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
    this.documents,
    this.narrative,
  });
  final SceneLinkedDocuments? documents;
  final NarrativeWorkspaceController? narrative;
  final SceneEditSession session;
  final ProjectManifest project;
  final String? nodeId, edgeId;
  final VoidCallback changed, onDelete, onDuplicate;
  final ValueChanged<SceneNode> onDocument;

  void edit(SceneAsset Function(SceneAsset) mutation) {
    session.mutate(mutation);
    changed();
  }

  void payload(SceneNode node, SceneNodePayload value) => edit(
    (scene) => replaceSceneNode(
      scene,
      SceneNode(
        id: node.id,
        kind: node.kind,
        title: node.title,
        description: node.description,
        payload: value,
      ),
    ),
  );

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
                const SizedBox(height: 20),
                Text('Sorties', style: Theme.of(context).textTheme.titleSmall),
                for (final port in authorableSceneOutputPortsForNodeInGraph(
                  node,
                  scene.graph,
                ))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '● ${switch (port.id) {
                        'true' => 'Oui',
                        'false' => 'Non',
                        'completed' => 'Continuer',
                        _ => port.id,
                      }}',
                    ),
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
    edit((scene) {
      var suffix = scene.declaredOutcomes.length + 1;
      while (scene.declaredOutcomes.any((o) => o.id == 'result_$suffix')) {
        suffix++;
      }
      return SceneAsset.fromJson({
        ...scene.toJson(),
        'declaredOutcomes': [
          ...scene.declaredOutcomes.map((o) => o.toJson()),
          SceneOutcome(id: 'result_$suffix', label: name).toJson(),
        ],
      });
    });
  }
}
