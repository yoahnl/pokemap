import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

Future<(String, String)?> showCharacterStudioCreateDialog(
  BuildContext context,
  ProjectManifest project,
) async {
  final tilesets = compatibleCharacterStudioTilesets(project);
  if (tilesets.isEmpty) return null;
  final name = TextEditingController();
  var tilesetId = tilesets.first.id;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, update) => AlertDialog(
        title: const Text('Nouveau personnage'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              DropdownButtonFormField<String>(
                initialValue: tilesetId,
                decoration: const InputDecoration(labelText: 'Planche source'),
                items: [
                  for (final entry in tilesets)
                    DropdownMenuItem(value: entry.id, child: Text(entry.name)),
                ],
                onChanged: (value) =>
                    update(() => tilesetId = value ?? tilesetId),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Créer'),
          ),
        ],
      ),
    ),
  );
  final result = confirmed == true && name.text.trim().isNotEmpty
      ? (name.text.trim(), tilesetId)
      : null;
  name.dispose();
  return result;
}

List<ProjectTilesetEntry> compatibleCharacterStudioTilesets(
  ProjectManifest project,
) => project.tilesets.where((entry) {
  final source = entry.source;
  return source is ProjectRegularAtlasTilesetSource &&
      source.pixelWidth >= project.settings.tileWidth * 2 &&
      source.pixelHeight >= project.settings.tileHeight * 2 &&
      source.marginX == 0 &&
      source.marginY == 0 &&
      source.spacingX == 0 &&
      source.spacingY == 0;
}).toList();
