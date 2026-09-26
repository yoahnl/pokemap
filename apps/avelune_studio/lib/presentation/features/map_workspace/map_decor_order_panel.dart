import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/map_editing_commands.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'map_workspace_view_state.dart';
import 'map_workspace_visuals.dart';

class MapDecorOrderPanel extends StatelessWidget {
  const MapDecorOrderPanel({
    super.key,
    required this.document,
    required this.project,
    required this.visuals,
    required this.view,
    required this.onChanged,
  });

  final EditableMapDocument document;
  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final MapWorkspaceViewState view;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = document.selected;
    if (selected == null) return const SizedBox();
    final position = document.stackPosition ?? selected.pos;
    final commands = MapEditingCommands(document, project);
    final stack = commands.stack(position);
    final local = stack
        .where((element) => element.layerId == selected.layerId)
        .toList();
    final other = stack
        .where((element) => element.layerId != selected.layerId)
        .toList();
    final definitions = {for (final entry in project.elements) entry.id: entry};
    final layers = {
      for (final layer in document.current.layers) layer.id: layer.name,
    };
    final forwardReason = commands.reorderProblemAt(
      instanceId: selected.id,
      at: position,
      forward: true,
    );
    final backwardReason = commands.reorderProblemAt(
      instanceId: selected.id,
      at: position,
      forward: false,
    );

    Widget entry(MapPlacedElement element, int rank, {bool different = false}) {
      final definition = definitions[element.elementId];
      return StudioChoice(
        label: definition?.name ?? 'Ressource manquante',
        subtitle: different
            ? 'Autre calque · ${layers[element.layerId] ?? element.layerId}'
            : 'Position ${rank + 1} · ${layers[element.layerId] ?? element.layerId}',
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              child: Text(
                different ? '–' : '${rank + 1}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            if (definition != null) visuals.thumbnail(definition, size: 34),
          ],
        ),
        selected: element.id == selected.id,
        onTap: () {
          view.select(document, MapSelectionFamily.decor, element.id);
          onChanged();
        },
      );
    }

    return ListView(
      children: [
        Text(
          'Décors réordonnables ici',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        Text(
          'Devant en haut · seuls les décors du même calque et du même contexte de rendu peuvent échanger leur ordre.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        for (final (index, element) in local.indexed) entry(element, index),
        if (local.length <= 1)
          StudioPanel(
            compact: true,
            children: [
              Text(
                forwardReason ??
                    'Aucun autre décor réordonnable à cet emplacement.',
              ),
            ],
          ),
        if (other.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Autres décors visibles · autres calques',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          for (final (index, element) in other.indexed)
            entry(element, index, different: true),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StudioButton(
                label: 'Monter',
                icon: Icons.arrow_upward,
                onPressed: forwardReason == null
                    ? () {
                        commands.reorderAt(
                          instanceId: selected.id,
                          at: position,
                          forward: true,
                        );
                        onChanged();
                      }
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StudioButton(
                label: 'Descendre',
                icon: Icons.arrow_downward,
                secondary: true,
                onPressed: backwardReason == null
                    ? () {
                        commands.reorderAt(
                          instanceId: selected.id,
                          at: position,
                          forward: false,
                        );
                        onChanged();
                      }
                    : null,
              ),
            ),
          ],
        ),
        if (local.length > 1 &&
            forwardReason != null &&
            backwardReason != null) ...[
          const SizedBox(height: 8),
          Text(forwardReason, style: Theme.of(context).textTheme.bodySmall),
        ],
        const SizedBox(height: 10),
        Text(
          'Le sol et les calques de terrain ne se réorganisent pas ici.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
