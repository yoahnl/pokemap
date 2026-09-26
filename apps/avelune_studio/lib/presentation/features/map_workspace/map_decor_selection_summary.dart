import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/map_editing_commands.dart';
import '../../shared/widgets/layout/studio_asset_preview.dart';
import 'map_workspace_visuals.dart';

class MapDecorSelectionSummary extends StatelessWidget {
  const MapDecorSelectionSummary({
    super.key,
    required this.document,
    required this.project,
    required this.visuals,
  });

  final EditableMapDocument document;
  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;

  @override
  Widget build(BuildContext context) {
    final selected = document.selected!;
    final definition = project.elements
        .where((element) => element.id == selected.elementId)
        .firstOrNull;
    final category = project.elementCategories
        .where((item) => item.id == definition?.categoryId)
        .firstOrNull;
    final stack = MapEditingCommands(
      document,
      project,
    ).stack(document.stackPosition ?? selected.pos);
    final rank = stack.indexWhere((item) => item.id == selected.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Élément sélectionné',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        StudioAssetPreview(
          height: 112,
          child: definition == null
              ? const Text('Ressource manquante')
              : visuals.thumbnail(definition, size: 96),
        ),
        const SizedBox(height: 8),
        Text(
          definition?.name ?? 'Ressource manquante',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        if (category != null)
          Text(
            'Décor · ${category.name}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        Text(
          'Position : ${selected.pos.x}, ${selected.pos.y}'
          '${rank < 0 ? '' : ' · ordre ${rank + 1}/${stack.length}'}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
