import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/text/studio_search_text.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../../theme/studio_tokens.dart';
import 'scene_graph_canvas.dart';
import 'scene_inspector.dart';

List<SceneNode> sceneNodeMatches(SceneAsset scene, String query) => [
  for (final node in scene.graph.nodes)
    if (studioSearchMatches(
      '${sceneNodeName(scene.graph, node.id)} ${sceneKindLabel(node.kind)} ${node.id}',
      query,
    ))
      node,
];

Future<String?> showSceneNodeFinder(BuildContext context, SceneAsset scene) =>
    showDialog<String>(
      context: context,
      builder: (_) => _SceneNodeFinder(scene: scene),
    );

class _SceneNodeFinder extends StatefulWidget {
  const _SceneNodeFinder({required this.scene});

  final SceneAsset scene;

  @override
  State<_SceneNodeFinder> createState() => _SceneNodeFinderState();
}

class _SceneNodeFinderState extends State<_SceneNodeFinder> {
  final _query = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matches = sceneNodeMatches(widget.scene, _query.text);
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: (MediaQuery.sizeOf(context).height - 48).clamp(240, 560),
        ),
        child: Padding(
          padding: const EdgeInsets.all(StudioMetrics.panelPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Trouver un bloc', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Le bloc choisi est sélectionné et centré ; la scène ne change pas.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              StudioSearchField(
                key: const ValueKey('scene-node-finder-search'),
                controller: _query,
                focusNode: _focus,
                label: 'Titre ou type de bloc',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Text(
                '${matches.length} ${matches.length > 1 ? 'blocs' : 'bloc'}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: matches.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun bloc ne correspond à cette recherche.',
                        ),
                      )
                    : ListView.builder(
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          final node = matches[index];
                          return StudioChoice(
                            key: ValueKey('scene-node-finder-${node.id}'),
                            label: sceneNodeName(widget.scene.graph, node.id),
                            subtitle: sceneKindLabel(node.kind),
                            leading: Icon(sceneBlockIcon(node.kind), size: 18),
                            onTap: () => Navigator.of(context).pop(node.id),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: StudioButton(
                  label: 'Annuler',
                  secondary: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
