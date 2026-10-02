import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../shared/widgets/layout/studio_asset_preview.dart';
import 'resource_catalog.dart';
import 'resource_management_dialog.dart';

Future<void> showResourceReplacement(
  BuildContext context, {
  required ResourceItem item,
  required Uint8List before,
  required Uint8List candidate,
  required int width,
  required int height,
  required int projectTileWidth,
  required int projectTileHeight,
  required List<String> impacts,
  required bool noChange,
  required Future<String?> Function() apply,
  required bool Function() canApply,
}) async {
  var confirmed = false;
  final source = item.tileset!.source;
  await showResourceManagementRoute(
    context,
    (_) => ResourceManagementDialog(
      title: 'Remplacer l’image source',
      submitLabel: noChange
          ? 'Terminer · image identique'
          : 'Remplacer l’image',
      maxWidth: 920,
      dirty: () => false,
      valid: () => canApply() && (confirmed || noChange),
      submit: apply,
      fields: (refresh, busy) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(item.name, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, bounds) {
              final panels = [
                _image('Actuellement', before),
                _image('Après remplacement', candidate),
              ];
              return bounds.maxWidth < 600
                  ? Column(children: panels)
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: panels.first),
                        const SizedBox(width: 16),
                        Expanded(child: panels.last),
                      ],
                    );
            },
          ),
          const SizedBox(height: 16),
          Text('$width × $height px · PNG sans redimensionnement'),
          Text(
            'Grille du projet conservée : $projectTileWidth × $projectTileHeight px.',
          ),
          if (source is ProjectRegularAtlasTilesetSource)
            Text(
              'Découpage conservé : ${source.columns} × ${source.rows} '
              'tuiles de ${source.tileWidth} × ${source.tileHeight} px.',
            ),
          const SizedBox(height: 8),
          SelectableText('Planche : ${item.id}'),
          SelectableText('Source actuelle : ${item.tileset!.relativePath}'),
          const SizedBox(height: 12),
          const Text(
            'Les placements et le découpage restent identiques. '
            'Les sources logiques liées sont actualisées ensemble ; une autre '
            'identité partageant seulement les anciens pixels reste intacte.',
          ),
          const SizedBox(height: 8),
          const Text(
            'Les versions publiées et snapshots restent sur leur ancienne '
            'image. Préparez à nouveau les dérivés depuis leur outil si nécessaire.',
          ),
          for (final impact in impacts)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(impact),
            ),
          if (noChange)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('Les octets sont identiques : aucune publication.'),
            )
          else
            CheckboxListTile(
              key: const ValueKey('resource-replacement-confirm'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Je confirme le remplacement de cette source.'),
              value: confirmed,
              onChanged: busy
                  ? null
                  : (value) {
                      confirmed = value == true;
                      refresh();
                    },
            ),
        ],
      ),
    ),
  );
}

Widget _image(String label, Uint8List bytes) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    Text(label),
    const SizedBox(height: 6),
    StudioAssetPreview(
      height: 220,
      child: Image.memory(
        bytes,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, _, _) => const Text('Aperçu PNG indisponible'),
      ),
    ),
    const SizedBox(height: 12),
  ],
);
