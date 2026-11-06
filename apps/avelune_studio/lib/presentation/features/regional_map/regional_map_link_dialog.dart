import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../map_workspace/map_library_tree.dart';

typedef RegionalMapLink = ({String name, String mapId});

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
  String? mapId = project.maps.any((map) => map.id == suggestedMapId)
      ? suggestedMapId
      : null;
  return showDialog<RegionalMapLink>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, rebuild) => AlertDialog(
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
            onPressed: mapId == null || (asksName && name.trim().isEmpty)
                ? null
                : () => Navigator.pop(context, (
                    name: name.trim(),
                    mapId: mapId!,
                  )),
          ),
        ],
      ),
    ),
  );
}

String regionalMapChoiceLabel(
  ProjectMapEntry map,
  Map<String, String> folders,
) {
  final folder = folders[map.groupId];
  return map.groupId == null || folder == null
      ? map.name
      : '${map.name} · $folder';
}
