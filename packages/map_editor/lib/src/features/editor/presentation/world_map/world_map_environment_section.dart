import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../../application/models/tile_layer_environment_attachment_read_model.dart';
import '../../../../application/services/tile_layer_environment_attachment_read_model_builder.dart';
import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';
import '../../state/editor_notifier.dart';
import '../../state/environment_generated_placement_add_element_provider.dart';
import '../../tools/editor_tool.dart';

/// The authoring chain for the environment attached to the selected TileLayer:
/// pick a preset and open a zone, paint its mask, then generate.
///
/// These controls used to live in `MapInspectorPanel`, which the shell no
/// longer mounts. The canvas still honours every mask edit mode, so only the
/// façade was missing — this is the minimal path from an empty attachment to
/// generated elements, kept next to the layer list the author already uses.
class WorldMapEnvironmentSection extends ConsumerStatefulWidget {
  const WorldMapEnvironmentSection({
    super.key,
    this.embedded = false,
  });

  /// Drops the surrounding card when the section already sits inside the card
  /// of the layer that owns the environment.
  final bool embedded;

  @override
  ConsumerState<WorldMapEnvironmentSection> createState() =>
      _WorldMapEnvironmentSectionState();
}

class _WorldMapEnvironmentSectionState
    extends ConsumerState<WorldMapEnvironmentSection> {
  String? _presetIdForNewArea;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final map = state.activeMap;
    final activeLayer = map?.layers
        .where((layer) => layer.id == state.activeLayerId)
        .firstOrNull;
    if (map == null || activeLayer is! TileLayer) {
      return const SizedBox.shrink();
    }

    final model = buildTileLayerEnvironmentAttachmentReadModel(
      manifest: state.project,
      map: map,
      selectedLayerId: state.activeLayerId,
      selectedEnvironmentAreaId: state.selectedEnvironmentAreaId,
      selectedGeneratedPlacementElementId:
          ref.watch(environmentGeneratedPlacementAddElementProvider),
    );
    if (!model.hasAttachment) {
      return const SizedBox.shrink();
    }

    final presets = state.project?.environmentPresets ?? const [];
    final maskMode = state.environmentMaskEditMode;
    final isPainting = maskMode == EnvironmentMaskEditMode.paint;
    final isErasing = maskMode == EnvironmentMaskEditMode.erase;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
          if (widget.embedded)
            Text(
              model.emptyStateTitle.isEmpty
                  ? model.selectedEnvironmentAreaName ?? 'Environnement'
                  : model.emptyStateTitle,
              style: TextStyle(
                color: context.pokeMapColors.textSecondary,
                fontSize: 11,
              ),
            )
          else
            PokeMapSectionHeader(
              title: 'Environnement du calque',
              description: model.emptyStateTitle.isEmpty
                  ? model.selectedEnvironmentAreaName
                  : model.emptyStateTitle,
            ),
          for (final error in model.errors) ...[
            const SizedBox(height: 8),
            PokeMapDiagnosticCallout(
              severity: PokeMapDiagnosticSeverity.error,
              message: error,
            ),
          ],
          for (final warning in model.warnings) ...[
            const SizedBox(height: 8),
            PokeMapDiagnosticCallout(
              severity: PokeMapDiagnosticSeverity.warning,
              message: warning,
            ),
          ],
          if (model.areaSummaries.isEmpty)
            ..._buildAreaCreation(
              context: context,
              notifier: notifier,
              model: model,
              presets: presets,
            )
          else
            ..._buildAreaAuthoring(
              context: context,
              notifier: notifier,
              model: model,
              isPainting: isPainting,
          isErasing: isErasing,
        ),
      ],
    );

    if (widget.embedded) {
      return KeyedSubtree(
        key: const ValueKey<String>('world-map-environment-section'),
        child: body,
      );
    }
    return PokeMapPanel(
      key: const ValueKey<String>('world-map-environment-section'),
      borderRadius: 8,
      accentTone: PokeMapTone.success,
      padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 12),
      child: body,
    );
  }

  List<Widget> _buildAreaCreation({
    required BuildContext context,
    required EditorNotifier notifier,
    required TileLayerEnvironmentAttachmentReadModel model,
    required List<EnvironmentPreset> presets,
  }) {
    if (presets.isEmpty) {
      return <Widget>[
        const SizedBox(height: 8),
        const PokeMapEmptyState(
          key: ValueKey<String>('world-map-environment-no-preset'),
          icon: Icon(Icons.park_outlined),
          title: 'Aucun preset d’environnement',
          description: 'Créez-en un dans Environment Studio, puis revenez '
              'ouvrir une zone ici.',
          compact: true,
        ),
      ];
    }
    // One preset needs no choosing; more than one does, and the author has not
    // opened a zone yet so there is nothing to fall back on.
    final presetId = presets.length == 1
        ? presets.single.id
        : (_presetIdForNewArea ?? presets.first.id);
    return <Widget>[
      const SizedBox(height: 8),
      if (presets.length > 1)
        PokeMapDropdownField<String>(
          key: const ValueKey<String>('world-map-environment-preset'),
          label: 'Preset',
          value: presetId,
          compact: true,
          items: <PokeMapDropdownItem<String>>[
            for (final preset in presets)
              PokeMapDropdownItem<String>(
                value: preset.id,
                label: preset.name,
              ),
          ],
          onChanged: (value) => setState(() => _presetIdForNewArea = value),
        ),
      if (presets.length > 1) const SizedBox(height: 8),
      PokeMapButton(
        key: const ValueKey<String>('world-map-environment-create-area'),
        onPressed: model.hasErrors
            ? null
            : () => notifier.createEnvironmentAreaForActiveTileLayer(
                  presetId: presetId,
                ),
        variant: PokeMapButtonVariant.primary,
        size: PokeMapButtonSize.compact,
        leading: const Icon(Icons.add_circle_outline),
        child: const Text('Ouvrir une zone'),
      ),
    ];
  }

  List<Widget> _buildAreaAuthoring({
    required BuildContext context,
    required EditorNotifier notifier,
    required TileLayerEnvironmentAttachmentReadModel model,
    required bool isPainting,
    required bool isErasing,
  }) {
    final isEditingMask = isPainting || isErasing;
    final selectedAreaId = model.selectedEnvironmentAreaId;
    return <Widget>[
      const SizedBox(height: 8),
      if (model.areaSummaries.length > 1)
        PokeMapDropdownField<String>(
          key: const ValueKey<String>('world-map-environment-area'),
          label: 'Zone',
          value: selectedAreaId ?? model.areaSummaries.first.id,
          compact: true,
          items: <PokeMapDropdownItem<String>>[
            for (final area in model.areaSummaries)
              PokeMapDropdownItem<String>(
                value: area.id,
                label: area.name,
              ),
          ],
          onChanged: notifier.selectEnvironmentAreaForActiveTileLayer,
        ),
      if (model.areaSummaries.length > 1) const SizedBox(height: 8),
      Text(
        '${model.maskActiveCellCount} cellule(s) peinte(s) · '
        '${model.generatedPlacementCount} élément(s) généré(s)',
        key: const ValueKey<String>('world-map-environment-counts'),
        style: TextStyle(
          color: context.pokeMapColors.textSecondary,
          fontSize: 11,
        ),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: PokeMapButton(
              key: const ValueKey<String>('world-map-environment-mask-paint'),
              onPressed: isPainting
                  ? notifier.stopEnvironmentMaskPainting
                  : model.canPaintMask && !model.hasErrors && !isErasing
                      ? notifier.startEnvironmentMaskPaintingForActiveTileLayer
                      : null,
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.compact,
              isSelected: isPainting,
              leading: const Icon(Icons.brush_outlined),
              child: Text(isPainting ? 'Terminer' : 'Peindre'),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: PokeMapButton(
              key: const ValueKey<String>('world-map-environment-mask-erase'),
              onPressed: isErasing
                  ? notifier.stopEnvironmentMaskPainting
                  : model.canPaintMask && !model.hasErrors && !isPainting
                      ? notifier.startEnvironmentMaskErasingForActiveTileLayer
                      : null,
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.compact,
              isSelected: isErasing,
              leading: const Icon(Icons.cleaning_services_outlined),
              child: Text(isErasing ? 'Terminer' : 'Effacer'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      PokeMapButton(
        key: const ValueKey<String>('world-map-environment-generate'),
        // Generating under an open mask gesture would commit half a stroke.
        onPressed: isEditingMask || model.hasErrors
            ? null
            : model.hasGeneratedPlacements
                ? model.canRegenerate
                    ? notifier
                        .regenerateEnvironmentAreaPlacementsForActiveTileLayer
                    : null
                : model.canGenerate
                    ? notifier
                        .generateEnvironmentAreaPlacementsForActiveTileLayer
                    : null,
        variant: PokeMapButtonVariant.primary,
        size: PokeMapButtonSize.compact,
        leading: const Icon(Icons.auto_awesome_outlined),
        child: Text(
          model.hasGeneratedPlacements ? 'Régénérer' : 'Générer',
        ),
      ),
    ];
  }
}
