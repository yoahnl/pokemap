import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../editor/state/editor_notifier.dart';
import '../editor/tools/editor_tool.dart';
import 'surface_catalog_availability.dart';
import 'surface_to_gameplay_zone_action.dart';
import 'surface_to_gameplay_zone_dialog.dart';
import '../../ui/shared/cupertino_editor_widgets.dart';

/// Minimal Surface palette for map placement authoring.
///
/// The palette intentionally selects a `ProjectSurfacePreset.id`, not an atlas
/// or animation id. The map placement model stores only `surfacePresetId`; frame
/// resolution, autotile roles and visual preview are future Surface Engine lots.
class SurfacePalettePanel extends StatelessWidget {
  const SurfacePalettePanel({
    super.key,
    required this.availability,
    required this.presets,
    required this.selectedSurfacePresetId,
    required this.onPresetSelected,
    this.onOpenSurfaceStudio,
  });

  final SurfaceCatalogAvailability availability;
  final List<ProjectSurfacePreset> presets;
  final String? selectedSurfacePresetId;
  final ValueChanged<String> onPresetSelected;
  final VoidCallback? onOpenSurfaceStudio;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Surfaces',
          style: TextStyle(
            color: label,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        _SurfaceCatalogCounts(availability: availability),
        const SizedBox(height: 8),
        Text(
          availability.primaryMessage,
          style: TextStyle(
            color: availability.canPaint ? subtle : label,
            fontSize: 13,
            fontWeight:
                availability.canPaint ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          availability.secondaryMessage,
          style: TextStyle(color: subtle, fontSize: 12),
        ),
        if (presets.isEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Les presets sont les surfaces que vous pouvez peindre sur la map.',
            style: TextStyle(color: subtle, fontSize: 12),
          ),
          if (onOpenSurfaceStudio != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                onPressed: onOpenSurfaceStudio,
                child: Text(availability.recommendedActionLabel),
              ),
            ),
          ],
        ] else ...[
          const SizedBox(height: 10),
          Text(
            'Sélectionner une surface',
            style: TextStyle(color: subtle, fontSize: 12),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < presets.length; i++) ...[
            _SurfacePresetTile(
              preset: presets[i],
              selected: presets[i].id == selectedSurfacePresetId,
              onSelected: onPresetSelected,
            ),
            if (i < presets.length - 1) const SizedBox(height: 6),
          ],
        ],
      ],
    );
  }
}

/// Small editor-facing wrapper that wires the palette to `EditorNotifier`.
///
/// It creates/selects a SurfaceLayer as an authoring target but still does not
/// render the resulting placements. In Lot 84 the visible map remains unchanged;
/// the saved map data gains sparse SurfaceCellPlacement entries.
class SurfacePainterPanel extends ConsumerWidget {
  const SurfacePainterPanel({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final map = state.activeMap;
    final catalog = state.project?.surfaceCatalog ?? ProjectSurfaceCatalog();
    final availability = SurfaceCatalogAvailability.fromCatalog(catalog);
    final presets =
        state.project?.surfaceCatalog.presets ?? const <ProjectSurfacePreset>[];
    final surfaceLayers =
        map?.layers.whereType<SurfaceLayer>().toList(growable: false) ??
            const <SurfaceLayer>[];
    final activeLayer = _activeSurfaceLayer(map, state.activeLayerId);
    final generationLayer =
        activeLayer ?? (surfaceLayers.length == 1 ? surfaceLayers.first : null);
    final canPaint = map != null &&
        availability.canPaint &&
        (state.selectedSurfacePresetId?.trim().isNotEmpty ?? false);
    final subtle = EditorChrome.subtleLabel(context);

    final content = Padding(
      padding: EdgeInsets.all(embedded ? 0 : 10),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _SurfaceLayerTargetBlock(
              surfaceLayers: surfaceLayers,
              activeLayer: activeLayer,
              onSelect: notifier.setActiveLayer,
              onCreate: () => notifier.activateFirstSurfaceLayer(
                createIfMissing: true,
              ),
            ),
          const SizedBox(height: 12),
          SurfacePalettePanel(
            availability: availability,
            presets: presets,
            selectedSurfacePresetId: state.selectedSurfacePresetId,
            onPresetSelected: notifier.selectSurfacePreset,
            onOpenSurfaceStudio: notifier.selectSurfaceStudioWorkspace,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CupertinoButton.filled(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                onPressed: canPaint ? notifier.selectSurfacePaintMode : null,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.paintbrush, size: 16),
                    SizedBox(width: 6),
                    Text('Peindre Surface'),
                  ],
                ),
              ),
              CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                onPressed: activeLayer == null
                    ? null
                    : () => notifier.selectTool(EditorToolType.eraser),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.delete_left, size: 16),
                    SizedBox(width: 6),
                    Text('Effacer Surface'),
                  ],
                ),
              ),
              CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                onPressed: map == null
                    ? null
                    : () async {
                        final plan = await showCupertinoDialog<
                            SurfaceGameplayZoneGenerationPlan>(
                          context: context,
                          builder: (dialogContext) {
                            return SurfaceToGameplayZoneDialog(
                              map: map,
                              surfaceLayer: generationLayer,
                              surfacePresetId: state.selectedSurfacePresetId,
                              presets: presets,
                              encounterTables:
                                  state.project?.encounterTables ?? const [],
                              onConfirm: (plan) =>
                                  Navigator.of(dialogContext).pop(plan),
                            );
                          },
                        );
                        if (plan == null) return;
                        applyTallGrassEncounterGameplayZonePlan(
                          notifier: notifier,
                          plan: plan,
                        );
                      },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.add_circled, size: 16),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text('Créer une zone de rencontre'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _statusLine(
              activeLayer: activeLayer,
              hasSurfaceLayer: surfaceLayers.isNotEmpty,
              presetSelected:
                  state.selectedSurfacePresetId?.trim().isNotEmpty ?? false,
              availability: availability,
            ),
            style: TextStyle(color: subtle, fontSize: 12),
          ),
        ],
      ),
    ),
  );

    if (embedded) {
      return content;
    }
    return Container(
      decoration: BoxDecoration(color: EditorChrome.islandFill(context)),
      child: content,
    );
  }

  SurfaceLayer? _activeSurfaceLayer(MapData? map, String? activeLayerId) {
    if (map == null || activeLayerId == null) {
      return null;
    }
    for (final layer in map.layers) {
      if (layer.id == activeLayerId && layer is SurfaceLayer) {
        return layer;
      }
    }
    return null;
  }

  String _statusLine({
    required SurfaceLayer? activeLayer,
    required bool hasSurfaceLayer,
    required bool presetSelected,
    required SurfaceCatalogAvailability availability,
  }) {
    if (!availability.canPaint) {
      if (hasSurfaceLayer) {
        return 'Un calque Surface existe, mais aucune surface n’est encore peignable.';
      }
      return availability.secondaryMessage;
    }
    if (!presetSelected) {
      return 'Sélectionnez une surface, puis peignez sur la map.';
    }
    if (activeLayer == null) {
      return 'Le premier clic créera un calque Surface automatiquement.';
    }
    return 'Calque actif : ${activeLayer.name}';
  }
}

class _SurfaceCatalogCounts extends StatelessWidget {
  const _SurfaceCatalogCounts({
    required this.availability,
  });

  final SurfaceCatalogAvailability availability;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catalogue Surface :',
          style: TextStyle(
            color: subtle,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _SurfaceCatalogCount(
              label: 'Atlas',
              value: availability.atlasCount,
            ),
            _SurfaceCatalogCount(
              label: 'Animations',
              value: availability.animationCount,
            ),
            _SurfaceCatalogCount(
              label: 'Presets',
              value: availability.presetCount,
            ),
          ],
        ),
      ],
    );
  }
}

class _SurfaceCatalogCount extends StatelessWidget {
  const _SurfaceCatalogCount({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return Text(
      '$label : $value',
      style: TextStyle(color: subtle, fontSize: 12),
    );
  }
}

class _SurfacePresetTile extends StatelessWidget {
  const _SurfacePresetTile({
    required this.preset,
    required this.selected,
    required this.onSelected,
  });

  final ProjectSurfacePreset preset;
  final bool selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    const accent = EditorChrome.inspectorJoyCyan;

    return CupertinoButton(
      key: Key('surface-palette-preset-${preset.id}'),
      padding: EdgeInsets.zero,
      onPressed: () => onSelected(preset.id),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.16)
              : EditorChrome.elevatedPanelBackground(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? accent : EditorChrome.separator(context),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              preset.name,
              style: TextStyle(
                color: label,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'ID : ${preset.id}',
              style: TextStyle(color: subtle, fontSize: 12),
            ),
            if (selected) ...[
              const SizedBox(height: 5),
              const Text(
                'Surface sélectionnée',
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SurfaceLayerTargetBlock extends StatelessWidget {
  const _SurfaceLayerTargetBlock({
    required this.surfaceLayers,
    required this.activeLayer,
    required this.onSelect,
    required this.onCreate,
  });

  final List<SurfaceLayer> surfaceLayers;
  final SurfaceLayer? activeLayer;
  final ValueChanged<String> onSelect;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Calque Surface',
                style: TextStyle(
                  color: label,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              onPressed: onCreate,
              child: const Text('Créer'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (surfaceLayers.isEmpty)
          Text(
            'Aucun calque Surface',
            style: TextStyle(color: subtle, fontSize: 12),
          )
        else
          for (final layer in surfaceLayers)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => onSelect(layer.id),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${layer.name} — ${layer.placements.length} placement(s)',
                  style: TextStyle(
                    color: layer.id == activeLayer?.id
                        ? EditorChrome.inspectorJoyCyan
                        : label,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
