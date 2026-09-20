import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_panel.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_search_field.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_tabs.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_choice.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_notice.dart';
import 'package:avelune_studio/features/scenes/application/scene_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_builder_view_state.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_graph_canvas.dart';

class SceneLibraryPanel extends StatefulWidget {
  const SceneLibraryPanel({
    super.key,
    required this.controller,
    required this.views,
    required this.blocks,
    required this.onAdd,
    required this.onCreate,
    required this.changed,
  });
  final SceneWorkspaceController controller;
  final SceneBuilderViewStore views;
  final List<SceneBlockDragData> blocks;
  final ValueChanged<SceneBlockDragData> onAdd;
  final VoidCallback onCreate, changed;
  @override
  State<SceneLibraryPanel> createState() => _SceneLibraryPanelState();
}

class _SceneLibraryPanelState extends State<SceneLibraryPanel> {
  late final search = TextEditingController(text: widget.views.search);
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = widget.views.search.toLowerCase();
    final scenes = <String, SceneAsset>{
      for (final scene in widget.controller.project.scenes) scene.id: scene,
      for (final session in widget.controller.sessions.values)
        session.current.id: session.current,
    };
    final filtered = scenes.values
        .where((s) => s.name.toLowerCase().contains(query))
        .toList();
    return StudioPanel(
      compact: true,
      children: [
        StudioTabs(
          items: const {false: 'Bibliothèque', true: 'Scènes'},
          selected: widget.views.sceneLibrary,
          onChanged: (value) {
            widget.views.sceneLibrary = value;
            widget.changed();
          },
        ),
        const SizedBox(height: 12),
        StudioSearchField(
          controller: search,
          label: widget.views.sceneLibrary
              ? 'Rechercher une scène'
              : 'Rechercher un bloc',
          onChanged: (value) {
            widget.views.search = value;
            widget.changed();
          },
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: widget.views.sceneLibrary
                ? [
                    StudioButton(
                      label: 'Nouvelle scène',
                      icon: Icons.add,
                      onPressed: widget.onCreate,
                    ),
                    const SizedBox(height: 12),
                    if (widget.controller.active != null &&
                        !filtered.any(
                          (s) => s.id == widget.controller.active!.current.id,
                        ))
                      const StudioNotice(
                        'La scène ouverte est masquée par la recherche.',
                      ),
                    for (final scene in filtered)
                      StudioChoice(
                        label: scene.name,
                        subtitle:
                            '${scene.graph.nodes.length} blocs${widget.controller.sessions[scene.id]?.dirty == true ? ' · Modifiée' : ''}',
                        selected:
                            widget.controller.active?.current.id == scene.id,
                        onTap: () {
                          widget.controller.open(scene.id);
                          widget.changed();
                        },
                      ),
                    if (filtered.isEmpty)
                      const Text('Aucune scène dans cette recherche.'),
                  ]
                : [
                    Text(
                      'Assembler une scène',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Cliquez ou déposez un bloc sur le graphe.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    for (final block in widget.blocks.where(
                      (b) => b.label.toLowerCase().contains(query),
                    ))
                      Draggable<SceneBlockDragData>(
                        data: block,
                        feedback: Material(
                          child: SizedBox(
                            width: 210,
                            child: StudioChoice(
                              label: block.label,
                              leading: Icon(sceneBlockIcon(block.kind)),
                              onTap: null,
                            ),
                          ),
                        ),
                        child: StudioChoice(
                          key: ValueKey('scene-palette-${block.kind.name}'),
                          label: block.label,
                          leading: Icon(
                            sceneBlockIcon(block.kind),
                            color: sceneBlockColor(context, block.kind),
                            size: 20,
                          ),
                          onTap: widget.controller.active == null
                              ? null
                              : () => widget.onAdd(block),
                        ),
                      ),
                    const SizedBox(height: 20),
                    const StudioNotice(
                      'Reliez les sorties nommées à l’entrée du bloc suivant. Échap annule le geste.',
                    ),
                  ],
          ),
        ),
      ],
    );
  }
}
