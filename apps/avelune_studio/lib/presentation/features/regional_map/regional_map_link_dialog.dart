import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/features/map_workspace/application/map_library_tree.dart';
import 'package:avelune_studio/features/regional_map/application/regional_map_choices.dart';

export 'package:avelune_studio/features/regional_map/application/regional_map_choices.dart' show regionalMapChoiceLabel, RegionalMapLink;

Future<RegionalMapLink?> askRegionalMapLink(
  BuildContext context, {
  required String title,
  required String mapLabel,
  required String confirmLabel,
  required ProjectManifest project,
  String? suggestedMapId,
  bool asksName = false,
}) {
  final folders = mapLibraryFolderLabels(project.groups);
  var name = '';
  String? mapId = regionalSuggestedMapId(project, suggestedMapId);
  return showDialog<RegionalMapLink>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, rebuild) {
        final confirmation = regionalMapLinkConfirmation(
          name: name,
          mapId: mapId,
          asksName: asksName,
        );
        return AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (asksName) ...[
                TextField(
                  autofocus: true,
                  onChanged: (text) => rebuild(() => name = text),
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                const SizedBox(height: 12),
              ],
              StudioSelect(
                label: mapLabel,
                value: mapId,
                options: {
                  for (final map in project.maps)
                    map.id: regionalMapChoiceLabel(map, folders),
                },
                onChanged: (id) => rebuild(() => mapId = id),
              ),
            ],
          ),
        ),
        actions: [
          StudioButton(
            label: 'Annuler',
            secondary: true,
            onPressed: () => Navigator.pop(context),
          ),
          StudioButton(
            label: confirmLabel,
            onPressed: confirmation == null
                ? null
                : () => Navigator.pop(context, confirmation),
          ),
        ],
      );
      },
    ),
  );
}
