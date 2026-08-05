import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../application/authoring_api/authoring_mutation_adapter.dart';
import '../../../application/authoring_api/authoring_query_adapter.dart';
import '../../../ui/design_system/design_system.dart';
import '../../../theme/theme.dart';
import '../application/tiled_map_import_service.dart';

Future<TiledMapImportResult?> showTiledMapImportFlow(
  BuildContext context, {
  required String projectRootPath,
  required AuthoringMutationAdapter mutations,
  required AuthoringQueryAdapter queries,
  TiledMapSourcePicker picker = const FilePickerTiledMapSourcePicker(),
}) async {
  try {
    final tmxPath = await picker.pickTmxPath();
    if (tmxPath == null || !context.mounted) return null;
    final source = await loadTiledMapImportSource(tmxPath);
    if (!context.mounted) return null;
    final layerModes = await _showTiledLayerModeDialog(context, source);
    if (layerModes == null || !context.mounted) return null;
    final service = TiledMapImportService(
      mutations: mutations,
      queries: queries,
    );
    final inspection = await service.inspectSource(
      projectRootPath: projectRootPath,
      source: source,
      layerModes: layerModes,
    );
    if (!context.mounted) return null;
    final confirmed = await showPokeMapBinaryConfirmationDialog(
      context,
      title: 'Importer cette carte Tiled ?',
      message: _inspectionMessage(inspection),
      secondaryLabel: 'Annuler',
      primaryLabel: 'Importer la carte',
      icon: CupertinoIcons.square_grid_3x2_fill,
    );
    if (!confirmed || !context.mounted) return null;
    return await service.apply(inspection);
  } on TiledMapImportServiceException catch (error) {
    if (!context.mounted) return null;
    await showPokeMapNoticeDialog(
      context,
      title: 'Import TMX impossible',
      message: error.message,
      icon: CupertinoIcons.exclamationmark_triangle_fill,
    );
    return null;
  } on Object {
    if (!context.mounted) return null;
    await showPokeMapNoticeDialog(
      context,
      title: 'Import TMX impossible',
      message:
          'Une erreur inattendue a interrompu l’inspection. Aucun fichier du '
          'projet n’a été modifié.',
      icon: CupertinoIcons.exclamationmark_triangle_fill,
    );
    return null;
  }
}

Future<Map<int, TiledMapLayerImportMode>?> _showTiledLayerModeDialog(
  BuildContext context,
  TiledMapImportSource source,
) =>
    showDialog<Map<int, TiledMapLayerImportMode>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _TiledLayerModeDialog(source: source),
    );

class _TiledLayerModeDialog extends StatefulWidget {
  const _TiledLayerModeDialog({required this.source});

  final TiledMapImportSource source;

  @override
  State<_TiledLayerModeDialog> createState() => _TiledLayerModeDialogState();
}

class _TiledLayerModeDialogState extends State<_TiledLayerModeDialog> {
  late final Map<int, TiledMapLayerImportMode> _modes =
      <int, TiledMapLayerImportMode>{
    for (final layer in widget.source.layerChoices)
      layer.sourceLayerId: layer.defaultMode,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final choices = widget.source.layerChoices;
    return PokeMapDialog(
      title: 'Choisir le rôle des calques',
      icon: CupertinoIcons.layers_alt_fill,
      maxWidth: 760,
      footer: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          PokeMapButton(
            onPressed: () => Navigator.of(context).pop(),
            variant: PokeMapButtonVariant.secondary,
            child: const Text('Annuler'),
          ),
          PokeMapButton(
            onPressed: () => Navigator.of(context).pop(
              Map<int, TiledMapLayerImportMode>.unmodifiable(_modes),
            ),
            child: const Text('Inspecter l’import'),
          ),
        ],
      ),
      child: SizedBox(
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PokeMap ne devine pas le sens métier d’un fichier externe. '
              'Indiquez ce qui doit être dessiné, conservé comme donnée, '
              'masqué ou écarté.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: choices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final layer = choices[index];
                  return PokeMapCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          layer.kind == TiledMapImportLayerKind.tile
                              ? CupertinoIcons.square_grid_3x2_fill
                              : CupertinoIcons.cube_box_fill,
                          size: 18,
                          color: colors.brandPrimary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                layer.path,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Calque ${layer.kind == TiledMapImportLayerKind.tile ? 'de tiles' : 'd’objets'} '
                                '· ${layer.sourceVisible ? 'visible dans la source' : 'masqué dans la source'}',
                                style: TextStyle(
                                  color: colors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 220,
                          child: PokeMapDropdownField<TiledMapLayerImportMode>(
                            label: 'Traitement',
                            compact: true,
                            value: _modes[layer.sourceLayerId]!,
                            items: const [
                              PokeMapDropdownItem(
                                value: TiledMapLayerImportMode.render,
                                label: 'Rendu',
                              ),
                              PokeMapDropdownItem(
                                value: TiledMapLayerImportMode.data,
                                label: 'Données techniques',
                              ),
                              PokeMapDropdownItem(
                                value: TiledMapLayerImportMode.hidden,
                                label: 'Masquée',
                              ),
                              PokeMapDropdownItem(
                                value: TiledMapLayerImportMode.ignore,
                                label: 'Ignorée',
                              ),
                            ],
                            onChanged: (mode) => setState(
                              () => _modes[layer.sourceLayerId] = mode,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _inspectionMessage(TiledMapImportInspection inspection) {
  final source = inspection.source;
  final preview = inspection.preview;
  final fidelity = switch (preview['fidelity']) {
    'exactLiteralTiles' => 'exacte pour les tiles',
    'metadataPreserved' => 'compatible, métadonnées préservées',
    'deferredContent' => 'partielle, contenu différé préservé',
    'lossy' => 'avec pertes visuelles signalées',
    final Object? value => value?.toString() ?? 'vérifiée',
  };
  final hasVisualLoss = preview['hasVisualLoss'] == true;
  final diagnostics = (preview['diagnostics'] as List? ?? const <Object?>[])
      .whereType<Map>()
      .map((item) => item['message'])
      .whereType<String>()
      .take(3)
      .toList(growable: false);
  final collectionCount =
      source.tilesets.where((tileset) => tileset.isImageCollection).length;
  return <String>[
    '${source.displayName} · identifiant ${source.mapId}',
    '${source.width} × ${source.height} cases · '
        '${source.tileLayerCount} couche(s) de tiles · '
        '${source.objectLayerCount} couche(s) d’objets',
    '${source.tilesets.length} tileset(s), dont '
        '$collectionCount collection(s) d’images · '
        '${source.objectCount} objet(s)',
    '${preview['dataLayerCount'] ?? 0} couche(s) de données · '
        '${preview['hiddenLayerCount'] ?? 0} couche(s) masquée(s) · '
        '${preview['ignoredLayerCount'] ?? 0} couche(s) ignorée(s)',
    'Fidélité : $fidelity. Écriture : transaction récupérable unique.',
    if (hasVisualLoss)
      'Attention : certaines informations visuelles ne peuvent pas être '
          'reproduites exactement.',
    'Aucune collision n’est inventée : seules les données explicites du '
        'fichier sont importées.',
    if (diagnostics.isNotEmpty) ...[
      '',
      'À vérifier :',
      for (final diagnostic in diagnostics) '• $diagnostic',
    ],
  ].join('\n');
}
