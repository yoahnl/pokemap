import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

Future<(String, String)?> showCharacterStudioCreateDialog(
  BuildContext context,
  ProjectManifest project,
) async {
  final tilesets = compatibleCharacterStudioTilesets(project);
  if (tilesets.isEmpty) return null;
  return showDialog<(String, String)>(
    context: context,
    builder: (context) => _CharacterStudioCreateDialog(tilesets: tilesets),
  );
}

class _CharacterStudioCreateDialog extends StatefulWidget {
  const _CharacterStudioCreateDialog({required this.tilesets});
  final List<ProjectTilesetEntry> tilesets;
  @override
  State<_CharacterStudioCreateDialog> createState() =>
      _CharacterStudioCreateDialogState();
}

class _CharacterStudioCreateDialogState
    extends State<_CharacterStudioCreateDialog> {
  final name = TextEditingController();
  late String tilesetId = widget.tilesets.first.id;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
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
              for (final entry in widget.tilesets)
                DropdownMenuItem(value: entry.id, child: Text(entry.name)),
            ],
            onChanged: (value) =>
                setState(() => tilesetId = value ?? tilesetId),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(
          context,
          name.text.trim().isEmpty ? null : (name.text.trim(), tilesetId),
        ),
        child: const Text('Créer'),
      ),
    ],
  );
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
