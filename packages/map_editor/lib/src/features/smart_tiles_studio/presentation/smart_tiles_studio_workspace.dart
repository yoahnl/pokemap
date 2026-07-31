import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/design_system/design_system.dart';
import '../../editor/state/editor_notifier.dart';
import '../../editor/state/editor_selectors.dart';
import 'smart_tiles_studio_panel.dart';

/// Point d'entrée Riverpod du studio natif unifié.
///
/// Le shell ne lit que le manifest en mémoire. Les écritures restent
/// transactionnelles et seront raccordées par le lot de publication.
class SmartTilesStudioWorkspace extends ConsumerWidget {
  const SmartTilesStudioWorkspace({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manifest = ref.watch(editorProjectManifestProvider);
    final projectRootPath = ref.watch(editorProjectRootPathProvider);
    if (manifest == null) {
      return const Center(
        child: PokeMapEmptyState(
          key: Key('smart-tiles-studio-missing-project'),
          title: 'Aucun projet chargé',
          description:
              'Chargez un projet pour ouvrir la bibliothèque Smart Tiles.',
          icon: Icon(CupertinoIcons.square_grid_3x2),
        ),
      );
    }
    return SmartTilesStudioPanel(
      manifest: manifest,
      projectRootPath: projectRootPath,
      onManifestChanged: (next) {
        ref.read(editorNotifierProvider.notifier).applyInMemoryProjectManifest(
              next,
              statusMessage: 'Brouillon Smart Tile ajouté au projet.',
            );
      },
      onAddToActiveMap: (preset) {
        ref.read(editorNotifierProvider.notifier).addSmartTileLayer(
              presetId: preset.id,
              usage: preset.usage,
              defaultMaterialId: preset.defaultMaterialId,
              name: preset.name,
              layerSeed: preset.seedSalt,
            );
      },
    );
  }
}
