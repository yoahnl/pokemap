import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../../ui/design_system/design_system.dart';
import '../../state/editor_notifier.dart';
import '../../state/editor_state.dart';

class WorldMapCollisionInspector extends ConsumerWidget {
  const WorldMapCollisionInspector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(
      editorNotifierProvider.select(
        (state) => (
          mode: state.collisionBrushSizeMode,
          project: state.project,
          map: state.activeMap,
          layerId: state.activeLayerId,
          brush: state.activeBrush,
        ),
      ),
    );
    final notifier = ref.read(editorNotifierProvider.notifier);
    final resolvedSize = notifier.resolveCurrentCollisionBrushFootprint();

    return Semantics(
      container: true,
      label: 'Réglages du pinceau de collision',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PokeMapSectionHeader(
              title: 'Empreinte de collision',
              description:
                  'Choisissez la case unique ou l’empreinte du pinceau actif.',
              trailing: PokeMapBadge(
                key: const ValueKey<String>(
                  'world-map-collision-resolved-size',
                ),
                label: resolvedSize == null
                    ? 'Empreinte indisponible'
                    : _sizeLabel(resolvedSize),
                variant: resolvedSize == null
                    ? PokeMapBadgeVariant.warning
                    : PokeMapBadgeVariant.info,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: PokeMapButton(
                    key: const ValueKey<String>(
                      'world-map-collision-brush-footprint',
                    ),
                    variant: PokeMapButtonVariant.secondary,
                    isSelected:
                        snapshot.mode == CollisionBrushSizeMode.brushFootprint,
                    onPressed: () => notifier.setCollisionBrushSizeMode(
                      CollisionBrushSizeMode.brushFootprint,
                    ),
                    child: const Text('Empreinte du pinceau'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PokeMapButton(
                    key: const ValueKey<String>(
                      'world-map-collision-single-tile',
                    ),
                    variant: PokeMapButtonVariant.secondary,
                    isSelected:
                        snapshot.mode == CollisionBrushSizeMode.singleTile,
                    onPressed: () => notifier.setCollisionBrushSizeMode(
                      CollisionBrushSizeMode.singleTile,
                    ),
                    child: const Text('1 × 1'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (resolvedSize == null)
              const PokeMapDiagnosticCallout(
                severity: PokeMapDiagnosticSeverity.warning,
                title: 'Pinceau indisponible',
                message: 'Le pinceau actif ne peut plus fournir son empreinte. '
                    'Choisissez une source disponible ou utilisez 1 × 1.',
              )
            else
              const PokeMapDiagnosticCallout(
                severity: PokeMapDiagnosticSeverity.info,
                title: 'Réglage temporaire',
                message:
                    'Ce choix règle seulement le prochain tracé de collision. '
                    'Il ne modifie pas la carte et ne crée pas d’historique.',
              ),
          ],
        ),
      ),
    );
  }
}

String _sizeLabel(GridSize size) {
  final suffix = size.width == 1 && size.height == 1 ? 'case' : 'cases';
  return '${size.width} × ${size.height} $suffix';
}
