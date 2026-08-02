import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../../ui/design_system/design_system.dart';
import '../../application/map_canvas_object_hit_test.dart';
import '../../application/world_map_inspector_projector.dart';
import '../../application/world_map_tool_family.dart';
import '../../state/editor_notifier.dart';
import 'world_map_cell_inspector.dart';
import 'world_map_erase_inspector.dart';
import 'world_map_layers_inspector.dart';
import 'world_map_paint_inspection_intent.dart';
import 'world_map_paint_inspector.dart';
import 'world_map_place_inspector.dart';
import 'world_map_selection_inspector.dart';
import 'world_map_workspace_session.dart';

class AdaptiveMapInspector extends ConsumerWidget {
  const AdaptiveMapInspector({
    super.key,
    this.onLayerContextMenuRequested,
    this.onClose,
    this.focusNode,
    this.debugOnBuild,
    this.debugOnBodyBuild,
    this.debugOnPaletteBuild,
  });

  final WorldMapLayerContextMenuRequested? onLayerContextMenuRequested;
  final VoidCallback? onClose;
  final FocusNode? focusNode;
  @visibleForTesting
  final VoidCallback? debugOnBuild;
  @visibleForTesting
  final ValueChanged<WorldMapInspectorKind>? debugOnBodyBuild;
  @visibleForTesting
  final VoidCallback? debugOnPaletteBuild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(() {
      debugOnBuild?.call();
      return true;
    }());
    final snapshot = ref.watch(worldMapInspectorSnapshotProvider);
    final title = _titleFor(snapshot.kind);
    final canPin = ref.watch(worldMapInspectorCanPinProvider);
    final session = ref.read(worldMapWorkspaceSessionProvider.notifier);

    void returnToLayers() {
      final result = session.activateLayers(
        ref.read(editorNotifierProvider.notifier),
      );
      if (!result.accepted) return;
      session.pinInspector(null);
      ref.read(worldMapPaintInspectionIntentProvider.notifier).clear();
      session.setInspectorVisible(true);
    }

    final inspector = Semantics(
      container: true,
      label: 'Inspecteur de carte : $title',
      child: PokeMapPanel(
        key: const ValueKey<String>('adaptive-map-inspector'),
        expandChild: true,
        borderRadius: 8,
        padding: EdgeInsets.zero,
        header: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
          child: Row(
            children: [
              if (snapshot.kind == WorldMapInspectorKind.paint) ...[
                PokeMapIconButton(
                  key: const ValueKey<String>(
                    'world-map-inspector-back-to-layers',
                  ),
                  size: 36,
                  tooltip: 'Retour à la liste des calques',
                  onPressed: returnToLayers,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: PokeMapSectionHeader(
                  title: title,
                  description: snapshot.activeLayerId == null
                      ? null
                      : 'Calque : ${snapshot.activeLayerId}',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PokeMapIconButton(
                        key: const ValueKey<String>(
                          'world-map-inspector-pin',
                        ),
                        size: 36,
                        tooltip: snapshot.pinned
                            ? 'Désépingler l’inspecteur'
                            : 'Épingler l’inspecteur',
                        isSelected: snapshot.pinned,
                        onPressed: canPin
                            ? () => session.pinInspector(
                                  snapshot.pinned ? null : snapshot.kind,
                                )
                            : null,
                        icon: Icon(
                          snapshot.pinned
                              ? Icons.push_pin
                              : Icons.push_pin_outlined,
                        ),
                      ),
                      const SizedBox(width: 4),
                      PokeMapIconButton(
                        key: const ValueKey<String>(
                          'world-map-inspector-close',
                        ),
                        size: 36,
                        tooltip: 'Fermer l’inspecteur',
                        onPressed:
                            onClose ?? () => session.setInspectorVisible(false),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey<String>(
            'world-map-inspector-body-${snapshot.kind.name}',
          ),
          child: _bodyFor(
            snapshot,
            onLayerContextMenuRequested: onLayerContextMenuRequested,
            debugOnBodyBuild: debugOnBodyBuild,
            debugOnPaletteBuild: debugOnPaletteBuild,
          ),
        ),
      ),
    );
    return Focus(
      key: const ValueKey<String>('adaptive-map-inspector-focus'),
      focusNode: focusNode,
      child: inspector,
    );
  }
}

Widget _bodyFor(
  WorldMapInspectorSnapshot snapshot, {
  WorldMapLayerContextMenuRequested? onLayerContextMenuRequested,
  ValueChanged<WorldMapInspectorKind>? debugOnBodyBuild,
  VoidCallback? debugOnPaletteBuild,
}) {
  assert(() {
    debugOnBodyBuild?.call(snapshot.kind);
    return true;
  }());
  return switch (snapshot.kind) {
    WorldMapInspectorKind.paint => WorldMapPaintInspector(
        debugOnPaletteBuild: debugOnPaletteBuild,
      ),
    WorldMapInspectorKind.erase => const WorldMapEraseInspector(),
    WorldMapInspectorKind.place => const WorldMapPlaceInspector(),
    WorldMapInspectorKind.objectSelection => WorldMapSelectionInspector(
        target: _requiredObjectTarget(snapshot),
      ),
    WorldMapInspectorKind.cellSelection => WorldMapCellInspector(
        cell: _requiredCell(snapshot),
        layerId: snapshot.activeLayerId,
      ),
    WorldMapInspectorKind.layers => WorldMapLayersInspector(
        onContextMenuRequested: onLayerContextMenuRequested,
      ),
    WorldMapInspectorKind.empty => const PokeMapEmptyState(
        icon: Icon(Icons.ads_click_outlined),
        title: 'Aucune sélection',
        description:
            'Sélectionnez un objet ou une cellule sur la carte, ou choisissez '
            'un outil pour afficher ses réglages.',
      ),
  };
}

MapCanvasObjectTarget _requiredObjectTarget(
  WorldMapInspectorSnapshot snapshot,
) {
  final target = snapshot.objectTarget;
  if (target == null) {
    throw StateError(
      'Object selection inspector requires a resolved object target.',
    );
  }
  return target;
}

GridPos _requiredCell(WorldMapInspectorSnapshot snapshot) {
  final cell = snapshot.cell;
  if (cell == null) {
    throw StateError('Cell selection inspector requires a resolved cell.');
  }
  return cell;
}

String _titleFor(WorldMapInspectorKind kind) {
  return switch (kind) {
    WorldMapInspectorKind.paint => 'Peindre',
    WorldMapInspectorKind.erase => 'Effacer',
    WorldMapInspectorKind.place => 'Placer',
    WorldMapInspectorKind.objectSelection => 'Objet sélectionné',
    WorldMapInspectorKind.cellSelection => 'Cellule sélectionnée',
    WorldMapInspectorKind.layers => 'Calques',
    WorldMapInspectorKind.empty => 'Aucune sélection',
  };
}
