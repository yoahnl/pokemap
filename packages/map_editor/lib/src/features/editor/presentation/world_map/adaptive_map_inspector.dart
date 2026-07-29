import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../ui/design_system/design_system.dart';
import '../../application/world_map_inspector_projector.dart';
import '../../application/world_map_tool_family.dart';
import 'world_map_workspace_session.dart';

typedef AdaptiveMapInspectorBodyBuilder = Widget Function(
  BuildContext context,
  WorldMapInspectorSnapshot snapshot,
);

class AdaptiveMapInspector extends ConsumerWidget {
  const AdaptiveMapInspector({
    super.key,
    required this.bodyBuilder,
  });

  final AdaptiveMapInspectorBodyBuilder bodyBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(worldMapInspectorSnapshotProvider);
    final title = _titleFor(snapshot.kind);
    final canPin = snapshot.kind != WorldMapInspectorKind.empty;
    final session = ref.read(worldMapWorkspaceSessionProvider.notifier);

    return Semantics(
      container: true,
      label: 'Inspecteur de carte : $title',
      child: PokeMapPanel(
        key: const ValueKey<String>('adaptive-map-inspector'),
        expandChild: true,
        borderRadius: 8,
        padding: EdgeInsets.zero,
        header: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
          child: PokeMapSectionHeader(
            title: title,
            description: snapshot.activeLayerId == null
                ? null
                : 'Calque : ${snapshot.activeLayerId}',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PokeMapIconButton(
                  key: const ValueKey<String>('world-map-inspector-pin'),
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
                    snapshot.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                  ),
                ),
                const SizedBox(width: 4),
                PokeMapIconButton(
                  key: const ValueKey<String>('world-map-inspector-close'),
                  tooltip: 'Fermer l’inspecteur',
                  onPressed: () => session.setInspectorVisible(false),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        ),
        child: bodyBuilder(context, snapshot),
      ),
    );
  }
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
