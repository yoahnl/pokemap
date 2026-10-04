import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/map_border_editing_commands.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import 'map_workspace_view_state.dart';

class MapBorderToolPanel extends StatelessWidget {
  const MapBorderToolPanel({
    super.key,
    required this.document,
    required this.project,
    required this.view,
    required this.onChanged,
    required this.onCreateModel,
  });

  final EditableMapDocument document;
  final ProjectManifest project;
  final MapWorkspaceViewState view;
  final VoidCallback onChanged;
  final VoidCallback onCreateModel;

  @override
  Widget build(BuildContext context) {
    final models = MapBorderEditingCommands.publishedLines(project);
    final selected = models.any((item) => item.id == view.borderBlueprintId)
        ? view.borderBlueprintId
        : null;
    final draft = view.borderDraft?.mapId == document.current.id
        ? view.borderDraft
        : null;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: models.isEmpty
            ? Wrap(
                spacing: 12,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Aucun modèle de bordure linéaire n’est publié dans ce projet.',
                  ),
                  StudioButton(
                    label: 'Créer un modèle',
                    icon: Icons.add,
                    onPressed: onCreateModel,
                  ),
                ],
              )
            : Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 210,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        key: const ValueKey('border-model-picker'),
                        isExpanded: true,
                        value: selected,
                        hint: const Text('Choisir une bordure'),
                        items: [
                          for (final model in models)
                            DropdownMenuItem(
                              value: model.id,
                              child: Text(
                                model.latestPublished!.definition.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: draft != null
                            ? null
                            : (id) {
                                view.borderBlueprintId = id;
                                onChanged();
                              },
                      ),
                    ),
                  ),
                  Text(
                    draft == null
                        ? 'Cliquez pour commencer, puis cliquez pour placer les angles.'
                        : '${draft.anchors.length} points · ${draft.alignment == BorderStrokeAlignment.gridEdges ? 'lignes de grille' : 'cases'} · clic = angle · départ = fermer · Entrée = terminer.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  StudioButton(
                    label: 'Créer un autre modèle',
                    icon: Icons.add,
                    secondary: true,
                    onPressed: onCreateModel,
                  ),
                  if (draft != null) ...[
                    StudioButton(
                      label: 'Retirer le dernier angle',
                      icon: Icons.undo,
                      secondary: true,
                      onPressed: () {
                        view.borderDraft = draft.removeLastAngle();
                        onChanged();
                      },
                    ),
                    StudioButton(
                      label: 'Annuler le tracé',
                      icon: Icons.close,
                      secondary: true,
                      onPressed: () {
                        view.borderDraft = null;
                        onChanged();
                      },
                    ),
                    StudioButton(
                      label: 'Terminer le tracé',
                      icon: Icons.check,
                      onPressed: draft.canFinish
                          ? () {
                              try {
                                MapBorderEditingCommands(
                                  document,
                                  project,
                                ).finish(draft);
                                view.borderDraft = null;
                              } catch (error) {
                                document.error = error.toString();
                              }
                              onChanged();
                            }
                          : null,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
