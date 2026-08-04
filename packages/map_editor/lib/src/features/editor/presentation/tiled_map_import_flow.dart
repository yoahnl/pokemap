import 'package:flutter/cupertino.dart';

import '../../../application/authoring_api/authoring_mutation_adapter.dart';
import '../../../application/authoring_api/authoring_query_adapter.dart';
import '../../../ui/design_system/design_system.dart';
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
    final inspection = await TiledMapImportService(
      mutations: mutations,
      queries: queries,
    ).inspect(
      projectRootPath: projectRootPath,
      tmxPath: tmxPath,
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
    return await TiledMapImportService(
      mutations: mutations,
      queries: queries,
    ).apply(inspection);
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
