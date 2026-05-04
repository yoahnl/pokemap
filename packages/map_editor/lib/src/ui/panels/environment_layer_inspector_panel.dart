import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../shared/cupertino_editor_widgets.dart';

/// Inspecteur Lot Environment-19/20 : meta layer + cible [TileLayer] pour génération future.
class EnvironmentLayerInspectorPanel extends ConsumerWidget {
  const EnvironmentLayerInspectorPanel({
    super.key,
    required this.map,
    required this.layer,
    this.embedded = false,
  });

  final MapData map;
  final EnvironmentLayer layer;
  final bool embedded;

  List<TileLayer> _tileLayers() {
    final out = <TileLayer>[];
    for (final l in map.layers) {
      if (l is TileLayer) {
        out.add(l);
      }
    }
    return out;
  }

  TileLayer? _resolveTarget() {
    final tid = layer.content.targetTileLayerId;
    if (tid == null) return null;
    for (final l in map.layers) {
      if (l.id == tid && l is TileLayer) {
        return l;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtle = EditorChrome.subtleLabel(context);
    final label = EditorChrome.primaryLabel(context);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final tiles = _tileLayers();
    final target = _resolveTarget();
    final tid = layer.content.targetTileLayerId;
    final invalidTarget = tid != null && target == null;

    return Padding(
      padding: EdgeInsets.fromLTRB(embedded ? 8 : 10, 4, embedded ? 8 : 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Environment Layer',
            key: const Key('map-inspector-environment-layer-title'),
            style: TextStyle(
              color: label,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ce layer servira à dessiner des zones organiques et à générer des '
            'éléments naturels.\n'
            'La configuration des zones arrive dans un prochain lot.',
            key: const Key('map-inspector-environment-layer-body'),
            style: TextStyle(
              color: subtle,
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'TileLayer cible',
            style: TextStyle(
              color: label,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (tiles.isEmpty) ...[
            Text(
              'Aucun TileLayer disponible dans cette map.\n'
              'Ajoutez d’abord un TileLayer pour recevoir les résultats générés.',
              key: const Key('env-layer-inspector-no-tile-layers'),
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else if (invalidTarget) ...[
            Text(
              'La cible configurée est introuvable ou invalide : $tid',
              key: const Key('env-layer-inspector-invalid-target'),
              style: TextStyle(
                color: CupertinoColors.systemOrange.resolveFrom(context),
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            PushButton(
              key: const Key('env-layer-inspector-change-invalid'),
              controlSize: ControlSize.regular,
              onPressed: () => _pickTileLayer(context, notifier, tiles),
              child: const Text('Choisir un autre TileLayer cible'),
            ),
            const SizedBox(height: 8),
            PushButton(
              key: const Key('env-layer-inspector-remove-invalid'),
              controlSize: ControlSize.regular,
              secondary: true,
              onPressed: () => notifier.setEnvironmentLayerTargetTileLayer(
                environmentLayerId: layer.id,
                targetTileLayerId: null,
              ),
              child: const Text('Retirer la cible'),
            ),
          ] else if (target == null) ...[
            Text(
              'Aucun TileLayer cible sélectionné.',
              key: const Key('env-layer-inspector-no-target'),
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            PushButton(
              key: const Key('env-layer-inspector-choose-target'),
              controlSize: ControlSize.regular,
              onPressed: () => _pickTileLayer(context, notifier, tiles),
              child: const Text('Choisir le TileLayer cible'),
            ),
          ] else ...[
            Text(
              'Cible actuelle : ${target.name}',
              key: const Key('env-layer-inspector-current-target-name'),
              style: TextStyle(
                color: label,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Id : ${target.id}',
              key: const Key('env-layer-inspector-current-target-id'),
              style: TextStyle(
                color: subtle,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            PushButton(
              key: const Key('env-layer-inspector-change-target'),
              controlSize: ControlSize.regular,
              onPressed: () => _pickTileLayer(context, notifier, tiles),
              child: const Text('Changer de TileLayer cible'),
            ),
            const SizedBox(height: 8),
            PushButton(
              key: const Key('env-layer-inspector-remove-target'),
              controlSize: ControlSize.regular,
              secondary: true,
              onPressed: () => notifier.setEnvironmentLayerTargetTileLayer(
                environmentLayerId: layer.id,
                targetTileLayerId: null,
              ),
              child: const Text('Retirer la cible'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickTileLayer(
    BuildContext context,
    EditorNotifier notifier,
    List<TileLayer> tiles,
  ) async {
    final picked = await showCupertinoListPicker<TileLayer>(
      context: context,
      title: 'TileLayer cible',
      items: tiles,
      labelOf: (t) => t.name,
    );
    if (picked == null) return;
    notifier.setEnvironmentLayerTargetTileLayer(
      environmentLayerId: layer.id,
      targetTileLayerId: picked.id,
    );
  }
}
