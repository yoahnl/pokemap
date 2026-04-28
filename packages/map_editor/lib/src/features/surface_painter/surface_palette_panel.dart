import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../editor/state/editor_notifier.dart';
import '../editor/tools/editor_tool.dart';
import '../../ui/shared/cupertino_editor_widgets.dart';

/// Minimal Surface palette for map placement authoring.
///
/// The palette intentionally selects a `ProjectSurfacePreset.id`, not an atlas
/// or animation id. The map placement model stores only `surfacePresetId`; frame
/// resolution, autotile roles and visual preview are future Surface Engine lots.
class SurfacePalettePanel extends StatelessWidget {
  const SurfacePalettePanel({
    super.key,
    required this.presets,
    required this.selectedSurfacePresetId,
    required this.onPresetSelected,
  });

  final List<ProjectSurfacePreset> presets;
  final String? selectedSurfacePresetId;
  final ValueChanged<String> onPresetSelected;

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
        if (presets.isEmpty)
          Text(
            'Aucune surface disponible',
            style: TextStyle(color: subtle, fontSize: 13),
          )
        else ...[
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
    final presets =
        state.project?.surfaceCatalog.presets ?? const <ProjectSurfacePreset>[];
    final surfaceLayers =
        map?.layers.whereType<SurfaceLayer>().toList(growable: false) ??
            const <SurfaceLayer>[];
    final activeLayer = _activeSurfaceLayer(map, state.activeLayerId);
    final canPaint = map != null &&
        presets.isNotEmpty &&
        (state.selectedSurfacePresetId?.trim().isNotEmpty ?? false);
    final subtle = EditorChrome.subtleLabel(context);

    final content = Padding(
      padding: EdgeInsets.all(embedded ? 0 : 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
            presets: presets,
            selectedSurfacePresetId: state.selectedSurfacePresetId,
            onPresetSelected: notifier.selectSurfacePreset,
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
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _statusLine(
              activeLayer: activeLayer,
              presetSelected:
                  state.selectedSurfacePresetId?.trim().isNotEmpty ?? false,
              hasPresets: presets.isNotEmpty,
            ),
            style: TextStyle(color: subtle, fontSize: 12),
          ),
        ],
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
    required bool presetSelected,
    required bool hasPresets,
  }) {
    if (!hasPresets) {
      return 'Créez des surfaces dans Surface Studio avant de peindre.';
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
