import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'resource_catalog.dart';
import 'resource_management_dialog.dart';

Future<void> showResourceInformation(
  BuildContext context, {
  required ResourceItem item,
  required ProjectManifest project,
  required Future<String?> Function(String name, String? folderId) save,
  String? fingerprint,
  Size? imageDimensions,
}) async {
  final tileset = item.tileset;
  if (tileset == null) return;
  final name = TextEditingController(text: tileset.name);
  var folder = tileset.folderId;
  final source = tileset.source;
  final dimensions = switch (source) {
    ProjectRegularAtlasTilesetSource() =>
      '${source.pixelWidth} × ${source.pixelHeight} px · '
          'tuiles ${source.tileWidth} × ${source.tileHeight} px',
    ProjectImageCollectionTilesetSource() =>
      source.pages
          .map(
            (page) =>
                '${page.id} : ${page.pixelWidth} × ${page.pixelHeight} px',
          )
          .join(' · '),
    null =>
      imageDimensions == null
          ? 'Dimensions PNG : image non chargée.'
          : '${imageDimensions.width.toInt()} × ${imageDimensions.height.toInt()} px',
  };
  try {
    await showResourceManagementRoute(
      context,
      (_) => ResourceManagementDialog(
        title: 'Modifier les informations',
        submitLabel: 'Enregistrer',
        dirty: () => name.text != tileset.name || folder != tileset.folderId,
        valid: () => name.text.trim().isNotEmpty,
        submit: () => save(name.text, folder),
        fields: (refresh, busy) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const ValueKey('resource-information-name'),
              controller: name,
              enabled: !busy,
              decoration: const InputDecoration(labelText: 'Nom visible'),
              onChanged: (_) => refresh(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: const ValueKey('resource-information-folder'),
              initialValue: folder ?? '',
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Dossier'),
              items: [
                const DropdownMenuItem(value: '', child: Text('Sans dossier')),
                for (final entry in project.tilesetFolders)
                  DropdownMenuItem(value: entry.id, child: Text(entry.name)),
                if (folder != null &&
                    !project.tilesetFolders.any((entry) => entry.id == folder))
                  DropdownMenuItem(
                    value: folder,
                    child: Text('Dossier introuvable · $folder'),
                  ),
              ],
              onChanged: busy
                  ? null
                  : (value) {
                      folder = value == '' ? null : value;
                      refresh();
                    },
            ),
            const SizedBox(height: 20),
            const Text(
              'Le nom et le rangement sont logiques : le fichier, ses '
              'références et son découpage restent inchangés.',
            ),
            const SizedBox(height: 12),
            SelectableText('Identifiant : ${tileset.id}'),
            const SizedBox(height: 8),
            SelectableText('Source : ${tileset.relativePath}'),
            const SizedBox(height: 8),
            SelectableText(
              fingerprint == null
                  ? 'Empreinte : non disponible dans le catalogue actuel.'
                  : 'Empreinte : $fingerprint',
            ),
            const SizedBox(height: 8),
            Text(dimensions),
            const SizedBox(height: 8),
            Text(
              'Grille du projet : ${project.settings.tileWidth} × '
              '${project.settings.tileHeight} px',
            ),
            const SizedBox(height: 12),
            const Text('Cette famille ne possède pas de tags modifiables.'),
          ],
        ),
      ),
    );
  } finally {
    name.dispose();
  }
}
