import 'package:flutter/cupertino.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';
import 'package:map_core/map_core.dart';

import '../../application/models/tile_layer_environment_attachment_read_model.dart';
import '../../features/editor/state/environment_mask_brush_size_provider.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_embedded_widgets.dart';

class TileLayerEnvironmentInspectorSection extends StatelessWidget {
  const TileLayerEnvironmentInspectorSection({
    super.key,
    required this.readModel,
    this.onEnableEnvironment,
    this.availablePresets = const [],
    this.selectedPresetIdForNewArea,
    this.onSelectPresetForNewArea,
    this.onCreateArea,
    this.onSelectEnvironmentArea,
    this.onRenameEnvironmentArea,
    this.onDeleteEnvironmentArea,
    this.isMaskPaintingActive = false,
    this.isMaskErasingActive = false,
    this.isDeletingGeneratedPlacement = false,
    this.isAddingGeneratedPlacement = false,
    this.onStartMaskPainting,
    this.onStartMaskErasing,
    this.onStopMaskPainting,
    this.onSelectGeneratedPlacementElement,
    this.onStartAddGeneratedPlacement,
    this.onStopAddGeneratedPlacement,
    this.onStartDeleteGeneratedPlacement,
    this.onStopDeleteGeneratedPlacement,
    this.environmentMaskBrushSize = kDefaultEnvironmentMaskBrushSize,
    this.onSetEnvironmentMaskBrushSize,
    this.onSetGenerationParams,
    this.onResetGenerationParams,
    this.onSetSeed,
    this.onGenerateEnvironment,
    this.onClearGeneratedPlacements,
    this.onRegenerateEnvironment,
    this.onShuffleEnvironment,
  });

  final TileLayerEnvironmentAttachmentReadModel readModel;
  final VoidCallback? onEnableEnvironment;
  final List<TileLayerEnvironmentPresetOption> availablePresets;
  final String? selectedPresetIdForNewArea;
  final ValueChanged<String>? onSelectPresetForNewArea;
  final VoidCallback? onCreateArea;
  final ValueChanged<String>? onSelectEnvironmentArea;
  final ValueChanged<String>? onRenameEnvironmentArea;
  final VoidCallback? onDeleteEnvironmentArea;
  final bool isMaskPaintingActive;
  final bool isMaskErasingActive;
  final bool isDeletingGeneratedPlacement;
  final bool isAddingGeneratedPlacement;
  final VoidCallback? onStartMaskPainting;
  final VoidCallback? onStartMaskErasing;
  final VoidCallback? onStopMaskPainting;
  final ValueChanged<String>? onSelectGeneratedPlacementElement;
  final VoidCallback? onStartAddGeneratedPlacement;
  final VoidCallback? onStopAddGeneratedPlacement;
  final VoidCallback? onStartDeleteGeneratedPlacement;
  final VoidCallback? onStopDeleteGeneratedPlacement;
  final int environmentMaskBrushSize;
  final ValueChanged<int>? onSetEnvironmentMaskBrushSize;
  final ValueChanged<EnvironmentGenerationParams>? onSetGenerationParams;
  final VoidCallback? onResetGenerationParams;
  final ValueChanged<int>? onSetSeed;
  final VoidCallback? onGenerateEnvironment;
  final VoidCallback? onClearGeneratedPlacements;
  final VoidCallback? onRegenerateEnvironment;
  final VoidCallback? onShuffleEnvironment;

  @override
  Widget build(BuildContext context) {
    final isMaskEditingActive = isMaskPaintingActive || isMaskErasingActive;
    final isEnvironmentActionActive = isMaskEditingActive ||
        isDeletingGeneratedPlacement ||
        isAddingGeneratedPlacement;
    final showSetupActions = _shouldShowSetupActions(readModel);
    final showMaskTools =
        readModel.canPaintMask || isMaskPaintingActive || isMaskErasingActive;
    final showGenerationActions = _shouldShowGenerationActions(readModel);
    final showManualRefinement = _shouldShowManualRefinement(
      readModel,
      isEnvironmentActionActive: isEnvironmentActionActive,
    );

    return SingleChildScrollView(
      padding: kInspectorTileBodyPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GenerationFeedbackSection(readModel: readModel),
          const SizedBox(height: 12),
          _SummaryRows(readModel: readModel),
          if (readModel.areaSummaries.isNotEmpty) ...[
            const SizedBox(height: 12),
            _EnvironmentAreaSummaryList(
              summaries: readModel.areaSummaries,
              onSelectEnvironmentArea: onSelectEnvironmentArea,
              onRenameEnvironmentArea: onRenameEnvironmentArea,
              onDeleteEnvironmentArea: onDeleteEnvironmentArea,
            ),
          ],
          if (showSetupActions) ...[
            const SizedBox(height: 12),
            _SetupActionsSection(
              readModel: readModel,
              onEnableEnvironment: onEnableEnvironment,
              availablePresets: availablePresets,
              selectedPresetIdForNewArea: selectedPresetIdForNewArea,
              onCreateArea: onCreateArea,
            ),
          ],
          if (_shouldShowCreateAreaGate(readModel)) ...[
            const SizedBox(height: 12),
            _CreateAreaPresetGate(
              availablePresets: availablePresets,
              selectedPresetIdForNewArea: selectedPresetIdForNewArea,
              onSelectPresetForNewArea: onSelectPresetForNewArea,
            ),
          ],
          if (showMaskTools) ...[
            const SizedBox(height: 12),
            _MaskEditingSection(
              isMaskPaintingActive: isMaskPaintingActive,
              isMaskErasingActive: isMaskErasingActive,
              environmentMaskBrushSize: environmentMaskBrushSize,
              onStartMaskPainting: onStartMaskPainting,
              onStartMaskErasing: onStartMaskErasing,
              onStopMaskPainting: onStopMaskPainting,
              onSetEnvironmentMaskBrushSize: onSetEnvironmentMaskBrushSize,
              readModel: readModel,
            ),
          ],
          if (_shouldShowGenerationParamsSection(readModel)) ...[
            const SizedBox(height: 12),
            _GenerationParamsSection(
              readModel: readModel,
              onSetGenerationParams: onSetGenerationParams,
              onResetGenerationParams: onResetGenerationParams,
              onSetSeed: onSetSeed,
            ),
          ],
          if (showGenerationActions) ...[
            const SizedBox(height: 12),
            _GenerationActionsSection(
              readModel: readModel,
              onGenerateEnvironment: onGenerateEnvironment,
              onClearGeneratedPlacements: onClearGeneratedPlacements,
              onRegenerateEnvironment: onRegenerateEnvironment,
              onShuffleEnvironment: onShuffleEnvironment,
            ),
          ],
          if (showManualRefinement) ...[
            const SizedBox(height: 12),
            _ManualRefinementSection(
              readModel: readModel,
              isMaskEditingActive: isMaskEditingActive,
              isDeletingGeneratedPlacement: isDeletingGeneratedPlacement,
              isAddingGeneratedPlacement: isAddingGeneratedPlacement,
              onSelectGeneratedPlacementElement:
                  onSelectGeneratedPlacementElement,
              onStartAddGeneratedPlacement: onStartAddGeneratedPlacement,
              onStopAddGeneratedPlacement: onStopAddGeneratedPlacement,
              onStartDeleteGeneratedPlacement: onStartDeleteGeneratedPlacement,
              onStopDeleteGeneratedPlacement: onStopDeleteGeneratedPlacement,
            ),
          ],
          if (readModel.issues.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DiagnosticsSection(issues: readModel.issues),
          ],
        ],
      ),
    );
  }
}

final class TileLayerEnvironmentPresetOption {
  const TileLayerEnvironmentPresetOption({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

class _GenerationFeedbackSection extends StatelessWidget {
  const _GenerationFeedbackSection({required this.readModel});

  final TileLayerEnvironmentAttachmentReadModel readModel;

  @override
  Widget build(BuildContext context) {
    const accent = EditorChrome.inspectorJoyMint;
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final title = _stateTitle(readModel);
    final message = _generationFeedbackMessage(readModel);
    final actionHint = _generationActionHint(readModel);
    final chips = _generationFeedbackChips(readModel);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: accent.withValues(alpha: 0.06),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'État de génération',
                  style: TextStyle(
                    color: subtle,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (readModel.isLegacyEnvironmentLayerSelection)
                const _StatusPill(
                  label: 'Mode legacy',
                  accent: accent,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              color: label,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 5),
            Text(
              message,
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                height: 1.32,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final chip in chips)
                  _StatusPill(label: chip, accent: accent),
              ],
            ),
          ],
          if (actionHint != null) ...[
            const SizedBox(height: 8),
            Text(
              actionHint,
              style: TextStyle(
                color: label,
                fontSize: 11.5,
                height: 1.25,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          if (readModel.missingGeneratedPlacementCount > 0) ...[
            const SizedBox(height: 5),
            Text(
              'Effacer ou régénérer nettoiera ces références.',
              style: TextStyle(
                color: subtle,
                fontSize: 11.5,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActiveMaskEditingBanner extends StatelessWidget {
  const _ActiveMaskEditingBanner({required this.isErasing});

  final bool isErasing;

  @override
  Widget build(BuildContext context) {
    final title = isErasing ? 'Effacement actif' : 'Peinture active';
    final message = isErasing
        ? 'Cliquez sur la carte pour retirer des cellules du masque.'
        : 'Cliquez sur la carte pour ajouter des cellules au masque.';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyMint.withValues(alpha: 0.12),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.inspectorJoyMint.withValues(alpha: 0.42),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            message,
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 11,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveGeneratedPlacementDeleteBanner extends StatelessWidget {
  const _ActiveGeneratedPlacementDeleteBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyMint.withValues(alpha: 0.12),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.inspectorJoyMint.withValues(alpha: 0.42),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suppression active',
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Cliquez un élément généré pour le retirer de cette zone.',
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 11,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveGeneratedPlacementAddBanner extends StatelessWidget {
  const _ActiveGeneratedPlacementAddBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyMint.withValues(alpha: 0.12),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.inspectorJoyMint.withValues(alpha: 0.42),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ajout actif',
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Cliquez sur la carte pour ajouter cet élément à cette zone.',
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 11,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRows extends StatelessWidget {
  const _SummaryRows({required this.readModel});

  final TileLayerEnvironmentAttachmentReadModel readModel;

  @override
  Widget build(BuildContext context) {
    final rows = <_SummaryRowData>[];
    final activeTileLayerName = readModel.activeTileLayerName?.trim();
    if (activeTileLayerName != null && activeTileLayerName.isNotEmpty) {
      rows.add(_SummaryRowData('Layer', activeTileLayerName));
    }
    final presetName = readModel.selectedPresetName?.trim();
    final presetId = readModel.selectedPresetId?.trim();
    if (presetName != null && presetName.isNotEmpty) {
      rows.add(_SummaryRowData('Preset', presetName));
    } else if (presetId != null && presetId.isNotEmpty) {
      rows.add(_SummaryRowData('Preset', '$presetId introuvable'));
    }
    final areaName = readModel.selectedEnvironmentAreaName?.trim();
    if (areaName != null && areaName.isNotEmpty) {
      rows.add(_SummaryRowData('Zone', areaName));
    }
    if (readModel.hasAttachment || readModel.maskActiveCellCount > 0) {
      rows.add(
        _SummaryRowData(
          'Masque',
          _paintedCellsLabel(readModel.maskActiveCellCount),
        ),
      );
    }
    if (readModel.hasGeneratedPlacements ||
        readModel.generatedPlacementCount > 0) {
      rows.add(
        _SummaryRowData(
          'Placements générés',
          '${readModel.generatedPlacementCount}',
        ),
      );
    }

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _SummaryRow(row: row),
          ),
      ],
    );
  }
}

class _BrushSizeSelector extends StatelessWidget {
  const _BrushSizeSelector({
    required this.selectedSize,
    required this.onChanged,
  });

  final int selectedSize;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyMint.withValues(alpha: 0.06),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.inspectorJoyMint.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Taille du pinceau',
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final size in kEnvironmentMaskBrushSizes) ...[
                Expanded(
                  child: _BrushSizeButton(
                    size: size,
                    selected: size == selectedSize,
                    onChanged: onChanged,
                  ),
                ),
                if (size != kEnvironmentMaskBrushSizes.last)
                  const SizedBox(width: 6),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _BrushSizeButton extends StatelessWidget {
  const _BrushSizeButton({
    required this.size,
    required this.selected,
    required this.onChanged,
  });

  final int size;
  final bool selected;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    const accent = EditorChrome.inspectorJoyMint;
    final enabled = onChanged != null;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(30, 30),
      onPressed: enabled ? () => onChanged!(size) : null,
      child: Container(
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: enabled ? 0.78 : 0.34)
              : EditorChrome.largeIslandSurfaceColor(
                  context,
                  tint: accent.withValues(alpha: 0.04),
                ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.88)
                : accent.withValues(alpha: enabled ? 0.28 : 0.16),
          ),
        ),
        child: Text(
          '$size',
          style: TextStyle(
            color: selected
                ? CupertinoColors.white
                : EditorChrome.primaryLabel(context),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _GeneratedPlacementPaletteSection extends StatelessWidget {
  const _GeneratedPlacementPaletteSection({
    required this.items,
    required this.onSelectGeneratedPlacementElement,
  });

  final List<TileLayerEnvironmentPaletteItemSummary> items;
  final ValueChanged<String>? onSelectGeneratedPlacementElement;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyMint.withValues(alpha: 0.06),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.inspectorJoyMint.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Palette du preset',
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            items.isEmpty
                ? 'Aucun élément disponible dans le preset.'
                : 'Élément à ajouter',
            style: TextStyle(
              color: subtle,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final item in items)
                  _GeneratedPlacementPaletteItemChip(
                    item: item,
                    onSelectGeneratedPlacementElement:
                        onSelectGeneratedPlacementElement,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GeneratedPlacementPaletteItemChip extends StatelessWidget {
  const _GeneratedPlacementPaletteItemChip({
    required this.item,
    required this.onSelectGeneratedPlacementElement,
  });

  final TileLayerEnvironmentPaletteItemSummary item;
  final ValueChanged<String>? onSelectGeneratedPlacementElement;

  @override
  Widget build(BuildContext context) {
    const accent = EditorChrome.inspectorJoyMint;
    final selected = item.isSelected;
    final enabled =
        !item.hasMissingElement && onSelectGeneratedPlacementElement != null;
    final foreground = enabled
        ? EditorChrome.primaryLabel(context)
        : EditorChrome.subtleLabel(context);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(44, 28),
      onPressed: enabled
          ? () => onSelectGeneratedPlacementElement!(item.elementId)
          : null,
      child: Container(
        constraints: const BoxConstraints(minHeight: 28, maxWidth: 170),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: EditorChrome.largeIslandSurfaceColor(
            context,
            tint: accent.withValues(
              alpha: selected
                  ? 0.18
                  : enabled
                      ? 0.08
                      : 0.03,
            ),
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: accent.withValues(
              alpha: selected
                  ? 0.62
                  : enabled
                      ? 0.28
                      : 0.12,
            ),
          ),
        ),
        child: Text(
          _paletteItemLabel(item),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: foreground,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _GenerationParamsSection extends StatelessWidget {
  const _GenerationParamsSection({
    required this.readModel,
    required this.onSetGenerationParams,
    required this.onResetGenerationParams,
    required this.onSetSeed,
  });

  final TileLayerEnvironmentAttachmentReadModel readModel;
  final ValueChanged<EnvironmentGenerationParams>? onSetGenerationParams;
  final VoidCallback? onResetGenerationParams;
  final ValueChanged<int>? onSetSeed;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final params = readModel.selectedAreaEffectiveParams;
    final canEdit = readModel.canEditSelectedAreaGenerationParams &&
        params != null &&
        onSetGenerationParams != null;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyMint.withValues(alpha: 0.06),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.inspectorJoyMint.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Paramètres de génération',
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            readModel.canEditSelectedAreaGenerationParams && params != null
                ? readModel.selectedAreaHasParamsOverride
                    ? 'Override local'
                    : 'Valeurs du preset'
                : 'Preset introuvable : paramètres non modifiables.',
            style: TextStyle(
              color: subtle,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          if (params != null &&
              readModel.canEditSelectedAreaGenerationParams) ...[
            const SizedBox(height: 9),
            _GenerationParamSlider(
              key: const ValueKey('env-generation-density-slider-row'),
              sliderKey: const ValueKey('env-generation-density-slider'),
              disabledKey:
                  const ValueKey('env-generation-density-slider-disabled'),
              opacityKey:
                  const ValueKey('env-generation-density-slider-opacity'),
              label: 'Densité',
              value: params.density.toStringAsFixed(2),
              sliderValue: params.density,
              enabled: canEdit,
              onChanged: (value) => _emitParams(
                params,
                density: _roundUnit(value),
              ),
            ),
            _GenerationParamSlider(
              key: const ValueKey('env-generation-variation-slider-row'),
              sliderKey: const ValueKey('env-generation-variation-slider'),
              disabledKey:
                  const ValueKey('env-generation-variation-slider-disabled'),
              opacityKey:
                  const ValueKey('env-generation-variation-slider-opacity'),
              label: 'Variation',
              value: params.variation.toStringAsFixed(2),
              sliderValue: params.variation,
              enabled: canEdit,
              onChanged: (value) => _emitParams(
                params,
                variation: _roundUnit(value),
              ),
            ),
            _GenerationParamSlider(
              key: const ValueKey('env-generation-edge-density-slider-row'),
              sliderKey: const ValueKey('env-generation-edge-density-slider'),
              disabledKey: const ValueKey(
                'env-generation-edge-density-slider-disabled',
              ),
              opacityKey:
                  const ValueKey('env-generation-edge-density-slider-opacity'),
              label: 'Densité des bords',
              value: params.edgeDensity.toStringAsFixed(2),
              sliderValue: params.edgeDensity,
              enabled: canEdit,
              onChanged: (value) => _emitParams(
                params,
                edgeDensity: _roundUnit(value),
              ),
            ),
            _GenerationIntSlider(
              key: const ValueKey('env-generation-min-spacing-slider-row'),
              sliderKey: const ValueKey('env-generation-min-spacing-slider'),
              disabledKey:
                  const ValueKey('env-generation-min-spacing-slider-disabled'),
              opacityKey:
                  const ValueKey('env-generation-min-spacing-slider-opacity'),
              label: 'Espacement minimal',
              value: '${params.minSpacingCells}',
              sliderValue: params.minSpacingCells,
              enabled: canEdit,
              onChanged: (value) => _emitParams(
                params,
                minSpacingCells: value,
              ),
            ),
            if (readModel.selectedAreaSeed != null)
              _GenerationParamStepper(
                label: 'Seed',
                value: '${readModel.selectedAreaSeed}',
                decreaseLabel: 'Seed -',
                increaseLabel: 'Seed +',
                canDecrease:
                    onSetSeed != null && readModel.selectedAreaSeed! > 0,
                canIncrease: onSetSeed != null,
                onDecrease: () => onSetSeed!(readModel.selectedAreaSeed! - 1),
                onIncrease: () => onSetSeed!(readModel.selectedAreaSeed! + 1),
              ),
            const SizedBox(height: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(30, 30),
              onPressed: readModel.selectedAreaHasParamsOverride &&
                      onResetGenerationParams != null
                  ? onResetGenerationParams
                  : null,
              child: Container(
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: EditorChrome.largeIslandSurfaceColor(
                    context,
                    tint: EditorChrome.inspectorJoyMint.withValues(
                      alpha:
                          readModel.selectedAreaHasParamsOverride ? 0.12 : 0.04,
                    ),
                  ),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: EditorChrome.inspectorJoyMint.withValues(
                      alpha:
                          readModel.selectedAreaHasParamsOverride ? 0.4 : 0.16,
                    ),
                  ),
                ),
                child: Text(
                  'Réinitialiser les paramètres',
                  style: TextStyle(
                    color: readModel.selectedAreaHasParamsOverride &&
                            onResetGenerationParams != null
                        ? label
                        : subtle,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _emitParams(
    EnvironmentGenerationParams current, {
    double? density,
    double? variation,
    double? edgeDensity,
    int? minSpacingCells,
  }) {
    onSetGenerationParams!(
      EnvironmentGenerationParams(
        density: density ?? current.density,
        variation: variation ?? current.variation,
        edgeDensity: edgeDensity ?? current.edgeDensity,
        minSpacingCells: minSpacingCells ?? current.minSpacingCells,
      ),
    );
  }
}

class _GenerationParamSlider extends StatelessWidget {
  const _GenerationParamSlider({
    super.key,
    required this.sliderKey,
    required this.disabledKey,
    required this.opacityKey,
    required this.label,
    required this.value,
    required this.sliderValue,
    required this.enabled,
    required this.onChanged,
  });

  final Key sliderKey;
  final Key disabledKey;
  final Key opacityKey;
  final String label;
  final String value;
  final double sliderValue;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GenerationParamHeader(
            label: label,
            value: value,
            enabled: enabled,
          ),
          IgnorePointer(
            key: disabledKey,
            ignoring: !enabled,
            child: Opacity(
              key: opacityKey,
              opacity: enabled ? 1 : 0.42,
              child: MacosSlider(
                key: sliderKey,
                value: _clampUnit(sliderValue),
                min: 0,
                max: 1,
                discrete: true,
                splits: 21,
                color: MacosTheme.of(context).primaryColor,
                onChanged: enabled ? onChanged : (_) {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenerationIntSlider extends StatelessWidget {
  const _GenerationIntSlider({
    super.key,
    required this.sliderKey,
    required this.disabledKey,
    required this.opacityKey,
    required this.label,
    required this.value,
    required this.sliderValue,
    required this.enabled,
    required this.onChanged,
  });

  final Key sliderKey;
  final Key disabledKey;
  final Key opacityKey;
  final String label;
  final String value;
  final int sliderValue;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final maxValue = sliderValue > 10 ? sliderValue : 10;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GenerationParamHeader(
            label: label,
            value: value,
            enabled: enabled,
          ),
          IgnorePointer(
            key: disabledKey,
            ignoring: !enabled,
            child: Opacity(
              key: opacityKey,
              opacity: enabled ? 1 : 0.42,
              child: MacosSlider(
                key: sliderKey,
                value: sliderValue.clamp(0, maxValue).toDouble(),
                min: 0,
                max: maxValue.toDouble(),
                discrete: true,
                splits: maxValue + 1,
                color: MacosTheme.of(context).primaryColor,
                onChanged:
                    enabled ? (value) => onChanged(value.round()) : (_) {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenerationParamHeader extends StatelessWidget {
  const _GenerationParamHeader({
    required this.label,
    required this.value,
    required this.enabled,
  });

  final String label;
  final String value;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? EditorChrome.primaryLabel(context)
        : MacosColors.disabledControlTextColor;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: color,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _GenerationParamStepper extends StatelessWidget {
  const _GenerationParamStepper({
    required this.label,
    required this.value,
    required this.decreaseLabel,
    required this.increaseLabel,
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String label;
  final String value;
  final String decreaseLabel;
  final String increaseLabel;
  final bool canDecrease;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: EditorChrome.primaryLabel(context),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: EditorChrome.primaryLabel(context),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _StepButton(
                  label: decreaseLabel,
                  enabled: canDecrease,
                  onPressed: onDecrease,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _StepButton(
                  label: increaseLabel,
                  enabled: canIncrease,
                  onPressed: onIncrease,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(44, 28),
      onPressed: enabled ? onPressed : null,
      child: Container(
        height: 28,
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: EditorChrome.largeIslandSurfaceColor(
            context,
            tint: EditorChrome.inspectorJoyMint.withValues(
              alpha: enabled ? 0.12 : 0.04,
            ),
          ),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: EditorChrome.inspectorJoyMint.withValues(
              alpha: enabled ? 0.36 : 0.14,
            ),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: enabled
                  ? EditorChrome.primaryLabel(context)
                  : EditorChrome.subtleLabel(context),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _EnvironmentAreaSummaryList extends StatelessWidget {
  const _EnvironmentAreaSummaryList({
    required this.summaries,
    required this.onSelectEnvironmentArea,
    required this.onRenameEnvironmentArea,
    required this.onDeleteEnvironmentArea,
  });

  final List<TileLayerEnvironmentAreaSummary> summaries;
  final ValueChanged<String>? onSelectEnvironmentArea;
  final ValueChanged<String>? onRenameEnvironmentArea;
  final VoidCallback? onDeleteEnvironmentArea;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    TileLayerEnvironmentAreaSummary? selectedSummary;
    for (final summary in summaries) {
      if (summary.isSelected) {
        selectedSummary = summary;
        break;
      }
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyMint.withValues(alpha: 0.06),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.inspectorJoyMint.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Zones d’environnement',
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          for (final summary in summaries)
            Padding(
              padding: EdgeInsets.only(
                bottom: summary == summaries.last ? 0 : 8,
              ),
              child: _EnvironmentAreaSummaryRow(
                summary: summary,
                onSelectEnvironmentArea: onSelectEnvironmentArea,
              ),
            ),
          if (selectedSummary != null) ...[
            const SizedBox(height: 10),
            _EnvironmentAreaManagementPanel(
              summary: selectedSummary,
              onRenameEnvironmentArea: onRenameEnvironmentArea,
              onDeleteEnvironmentArea: onDeleteEnvironmentArea,
            ),
          ],
        ],
      ),
    );
  }
}

class _EnvironmentAreaManagementPanel extends StatefulWidget {
  const _EnvironmentAreaManagementPanel({
    required this.summary,
    required this.onRenameEnvironmentArea,
    required this.onDeleteEnvironmentArea,
  });

  final TileLayerEnvironmentAreaSummary summary;
  final ValueChanged<String>? onRenameEnvironmentArea;
  final VoidCallback? onDeleteEnvironmentArea;

  @override
  State<_EnvironmentAreaManagementPanel> createState() =>
      _EnvironmentAreaManagementPanelState();
}

class _EnvironmentAreaManagementPanelState
    extends State<_EnvironmentAreaManagementPanel> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.summary.name);
    _controller.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(_EnvironmentAreaManagementPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.summary.id != widget.summary.id ||
        oldWidget.summary.name != widget.summary.name) {
      _controller.text = widget.summary.name;
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleTextChanged)
      ..dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    setState(() {});
  }

  Future<void> _confirmDeleteArea(BuildContext context) async {
    final shouldDelete = await showMacosEditorTwoChoiceAlert(
      context,
      title: 'Supprimer cette zone ?',
      message:
          'Cette action supprimera la zone, son masque, ses réglages locaux et ses placements générés. Les placements manuels et les autres zones seront conservés.',
      secondaryLabel: 'Annuler',
      primaryLabel: 'Supprimer la zone',
      primaryIsDestructive: true,
    );
    if (!shouldDelete) {
      return;
    }
    widget.onDeleteEnvironmentArea?.call();
  }

  @override
  Widget build(BuildContext context) {
    const accent = EditorChrome.inspectorJoyMint;
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final trimmedName = _controller.text.trim();
    final canRename =
        widget.onRenameEnvironmentArea != null && trimmedName.isNotEmpty;
    final canDelete = widget.onDeleteEnvironmentArea != null;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: accent.withValues(alpha: 0.08),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accent.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Gestion de la zone active',
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nom de la zone',
            style: TextStyle(
              color: subtle,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          CupertinoTextField(
            key: const ValueKey('tile-layer-environment-area-name-field'),
            controller: _controller,
            placeholder: 'Nom de la zone',
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            placeholderStyle: TextStyle(
              color: subtle,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            decoration: BoxDecoration(
              color: EditorChrome.largeIslandSurfaceColor(
                context,
                tint: accent.withValues(alpha: 0.04),
              ),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: accent.withValues(alpha: 0.22),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _AreaManagementButton(
                  label: 'Renommer la zone',
                  accent: accent,
                  enabled: canRename,
                  onPressed: canRename
                      ? () => widget.onRenameEnvironmentArea!(trimmedName)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AreaManagementButton(
                  label: 'Supprimer la zone',
                  accent: CupertinoColors.systemRed,
                  enabled: canDelete,
                  onPressed:
                      canDelete ? () => _confirmDeleteArea(context) : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            'Supprime la zone, son masque, ses réglages et ses placements générés.',
            style: TextStyle(
              color: subtle,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaManagementButton extends StatelessWidget {
  const _AreaManagementButton({
    required this.label,
    required this.accent,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final Color accent;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final textColor = enabled
        ? EditorChrome.primaryLabel(context)
        : EditorChrome.subtleLabel(context);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(0, 30),
      onPressed: enabled ? onPressed : null,
      child: Container(
        height: 30,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: EditorChrome.largeIslandSurfaceColor(
            context,
            tint: accent.withValues(alpha: enabled ? 0.16 : 0.04),
          ),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: accent.withValues(alpha: enabled ? 0.42 : 0.14),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _EnvironmentAreaSummaryRow extends StatelessWidget {
  const _EnvironmentAreaSummaryRow({
    required this.summary,
    required this.onSelectEnvironmentArea,
  });

  final TileLayerEnvironmentAreaSummary summary;
  final ValueChanged<String>? onSelectEnvironmentArea;

  @override
  Widget build(BuildContext context) {
    const accent = EditorChrome.inspectorJoyMint;
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final canSelect = !summary.isSelected && onSelectEnvironmentArea != null;
    final details = _areaSummaryDetails(summary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: summary.isSelected
              ? accent.withValues(alpha: 0.12)
              : accent.withValues(alpha: 0.04),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: summary.isSelected
              ? accent.withValues(alpha: 0.55)
              : accent.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  summary.name.trim().isEmpty ? 'Zone sans nom' : summary.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: label,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (summary.isSelected)
                const _StatusPill(label: 'Zone active', accent: accent)
              else
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(92, 28),
                  onPressed: canSelect
                      ? () => onSelectEnvironmentArea!(summary.id)
                      : null,
                  child: Container(
                    height: 28,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    decoration: BoxDecoration(
                      color: canSelect
                          ? accent.withValues(alpha: 0.2)
                          : EditorChrome.largeIslandSurfaceColor(
                              context,
                              tint: accent.withValues(alpha: 0.04),
                            ),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: accent.withValues(
                          alpha: canSelect ? 0.46 : 0.16,
                        ),
                      ),
                    ),
                    child: Text(
                      'Sélectionner',
                      style: TextStyle(
                        color: canSelect ? label : subtle,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (final detail in details)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subtle,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CreateAreaPresetGate extends StatelessWidget {
  const _CreateAreaPresetGate({
    required this.availablePresets,
    required this.selectedPresetIdForNewArea,
    required this.onSelectPresetForNewArea,
  });

  final List<TileLayerEnvironmentPresetOption> availablePresets;
  final String? selectedPresetIdForNewArea;
  final ValueChanged<String>? onSelectPresetForNewArea;

  @override
  Widget build(BuildContext context) {
    final selectedPreset = _selectedPreset(
      availablePresets,
      selectedPresetIdForNewArea,
    );
    if (availablePresets.isEmpty) {
      return const InspectorEmbeddedFootnote(
        text:
            'Créez d’abord un preset dans Environment Studio avant d’ajouter une zone.',
        accent: EditorChrome.inspectorJoyMint,
      );
    }
    if (availablePresets.length == 1) {
      return _PresetGateText(
          'Preset utilisé : ${availablePresets.single.name}');
    }

    final selectedName = selectedPreset?.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PresetGateText(
          selectedName == null
              ? 'Choisissez un preset avant d’ajouter une zone.'
              : 'Preset pour la nouvelle zone : $selectedName',
        ),
        const SizedBox(height: 8),
        InspectorEmbeddedDropdown(
          accent: EditorChrome.inspectorJoyMint,
          fieldLabel: 'Preset pour la nouvelle zone',
          valueLabel: selectedName ?? 'Choisir un preset',
          orderedIds: availablePresets.map((preset) => preset.id).toList(),
          selectedMenuValue: selectedPreset?.id ?? '',
          selectedIdForCheck: selectedPreset?.id,
          idToLabel: (id) => _presetNameForId(availablePresets, id) ?? id,
          onSelected: onSelectPresetForNewArea ?? (_) {},
          allowUnsetSelection: true,
        ),
      ],
    );
  }
}

class _PresetGateText extends StatelessWidget {
  const _PresetGateText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: EditorChrome.primaryLabel(context),
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.row});

  final _SummaryRowData row;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyMint.withValues(alpha: 0.06),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.inspectorJoyMint.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${row.label} : ${row.value}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: label,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueBanner extends StatelessWidget {
  const _IssueBanner({required this.issue});

  final TileLayerEnvironmentAttachmentIssue issue;

  @override
  Widget build(BuildContext context) {
    final isError =
        issue.severity == TileLayerEnvironmentAttachmentIssueSeverity.error;
    final accent = isError
        ? CupertinoColors.systemRed.resolveFrom(context)
        : CupertinoColors.systemOrange.resolveFrom(context);
    final prefix = isError ? 'Erreur' : 'Attention';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: accent.withValues(alpha: 0.09),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.42)),
      ),
      child: Text(
        '$prefix : ${issue.message}',
        style: TextStyle(
          color: EditorChrome.primaryLabel(context),
          fontSize: 11.5,
          height: 1.28,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SetupActionsSection extends StatelessWidget {
  const _SetupActionsSection({
    required this.readModel,
    required this.onEnableEnvironment,
    required this.availablePresets,
    required this.selectedPresetIdForNewArea,
    required this.onCreateArea,
  });

  final TileLayerEnvironmentAttachmentReadModel readModel;
  final VoidCallback? onEnableEnvironment;
  final List<TileLayerEnvironmentPresetOption> availablePresets;
  final String? selectedPresetIdForNewArea;
  final VoidCallback? onCreateArea;

  @override
  Widget build(BuildContext context) {
    final actions = <_ActionData>[];
    if (readModel.canEnableEnvironment) {
      actions.add(
        _ActionData(
          icon: CupertinoIcons.add_circled,
          label: readModel.primaryActionLabel ?? 'Activer l’environnement',
          enabled: onEnableEnvironment != null,
          onPressed: onEnableEnvironment,
        ),
      );
    }
    if (_shouldShowCreateAreaGate(readModel)) {
      final hasPresetForNewArea =
          _selectedPreset(availablePresets, selectedPresetIdForNewArea) != null;
      actions.add(
        _ActionData(
          icon: CupertinoIcons.add_circled,
          label: readModel.primaryActionLabel ?? 'Ajouter une zone',
          enabled: !readModel.hasErrors &&
              hasPresetForNewArea &&
              onCreateArea != null,
          onPressed: onCreateArea,
        ),
      );
    }
    return _ActionButtonColumn(actions: actions);
  }
}

class _MaskEditingSection extends StatelessWidget {
  const _MaskEditingSection({
    required this.readModel,
    required this.isMaskPaintingActive,
    required this.isMaskErasingActive,
    required this.environmentMaskBrushSize,
    required this.onStartMaskPainting,
    required this.onStartMaskErasing,
    required this.onStopMaskPainting,
    required this.onSetEnvironmentMaskBrushSize,
  });

  final TileLayerEnvironmentAttachmentReadModel readModel;
  final bool isMaskPaintingActive;
  final bool isMaskErasingActive;
  final int environmentMaskBrushSize;
  final VoidCallback? onStartMaskPainting;
  final VoidCallback? onStartMaskErasing;
  final VoidCallback? onStopMaskPainting;
  final ValueChanged<int>? onSetEnvironmentMaskBrushSize;

  @override
  Widget build(BuildContext context) {
    final actions = <_ActionData>[];
    final isMaskEditingActive = isMaskPaintingActive || isMaskErasingActive;
    if (isMaskEditingActive) {
      actions.add(
        _ActionData(
          icon: CupertinoIcons.stop_circle,
          label: 'Arrêter l’édition du masque',
          enabled: onStopMaskPainting != null,
          onPressed: onStopMaskPainting,
        ),
      );
    } else if (readModel.canPaintMask) {
      actions.add(
        _ActionData(
          icon: CupertinoIcons.paintbrush,
          label: 'Peindre le masque',
          enabled: !readModel.hasErrors && onStartMaskPainting != null,
          onPressed: onStartMaskPainting,
        ),
      );
      actions.add(
        _ActionData(
          icon: CupertinoIcons.delete_left,
          label: 'Effacer du masque',
          enabled: !readModel.hasErrors && onStartMaskErasing != null,
          onPressed: onStartMaskErasing,
        ),
      );
    }

    return _EnvironmentSubsection(
      title: 'Éditer le masque',
      children: [
        if (isMaskEditingActive) ...[
          _ActiveMaskEditingBanner(isErasing: isMaskErasingActive),
          const SizedBox(height: 8),
        ],
        if (actions.isNotEmpty) ...[
          _ActionButtonColumn(actions: actions),
          const SizedBox(height: 8),
        ],
        _BrushSizeSelector(
          selectedSize: environmentMaskBrushSize,
          onChanged: onSetEnvironmentMaskBrushSize,
        ),
      ],
    );
  }
}

class _GenerationActionsSection extends StatelessWidget {
  const _GenerationActionsSection({
    required this.readModel,
    required this.onGenerateEnvironment,
    required this.onClearGeneratedPlacements,
    required this.onRegenerateEnvironment,
    required this.onShuffleEnvironment,
  });

  final TileLayerEnvironmentAttachmentReadModel readModel;
  final VoidCallback? onGenerateEnvironment;
  final VoidCallback? onClearGeneratedPlacements;
  final VoidCallback? onRegenerateEnvironment;
  final VoidCallback? onShuffleEnvironment;

  @override
  Widget build(BuildContext context) {
    final actions = <_ActionData>[];
    if (readModel.canGenerate || readModel.canPaintMask) {
      actions.add(
        _ActionData(
          icon: CupertinoIcons.play,
          label: 'Générer dans ce layer',
          enabled: readModel.canGenerate &&
              !readModel.hasErrors &&
              onGenerateEnvironment != null,
          onPressed: readModel.canGenerate ? onGenerateEnvironment : null,
        ),
      );
    }
    if (readModel.canClearGeneratedPlacements || readModel.canPaintMask) {
      actions.add(
        _ActionData(
          icon: CupertinoIcons.trash,
          label: 'Effacer les placements générés',
          helperText:
              'Retire tous les éléments générés de cette zone, sans supprimer le masque ni les réglages.',
          enabled: readModel.canClearGeneratedPlacements &&
              !readModel.hasErrors &&
              onClearGeneratedPlacements != null,
          onPressed: readModel.canClearGeneratedPlacements
              ? onClearGeneratedPlacements
              : null,
        ),
      );
    }
    if (readModel.canRegenerate || readModel.canPaintMask) {
      actions.add(
        _ActionData(
          icon: CupertinoIcons.arrow_clockwise,
          label: 'Régénérer',
          helperText:
              'Remplace les placements générés de cette zone en gardant le seed actuel.',
          enabled: readModel.canRegenerate &&
              !readModel.hasErrors &&
              onRegenerateEnvironment != null,
          onPressed: readModel.canRegenerate ? onRegenerateEnvironment : null,
        ),
      );
    }
    if (readModel.canShuffle || readModel.canPaintMask) {
      actions.add(
        _ActionData(
          icon: CupertinoIcons.shuffle,
          label: 'Shuffle',
          helperText:
              'Remplace les placements générés de cette zone avec un nouveau seed.',
          enabled: readModel.canShuffle &&
              !readModel.hasErrors &&
              onShuffleEnvironment != null,
          onPressed: readModel.canShuffle ? onShuffleEnvironment : null,
        ),
      );
    }

    return _EnvironmentSubsection(
      title: 'Génération',
      children: [_ActionButtonColumn(actions: actions)],
    );
  }
}

class _ManualRefinementSection extends StatelessWidget {
  const _ManualRefinementSection({
    required this.readModel,
    required this.isMaskEditingActive,
    required this.isDeletingGeneratedPlacement,
    required this.isAddingGeneratedPlacement,
    required this.onSelectGeneratedPlacementElement,
    required this.onStartAddGeneratedPlacement,
    required this.onStopAddGeneratedPlacement,
    required this.onStartDeleteGeneratedPlacement,
    required this.onStopDeleteGeneratedPlacement,
  });

  final TileLayerEnvironmentAttachmentReadModel readModel;
  final bool isMaskEditingActive;
  final bool isDeletingGeneratedPlacement;
  final bool isAddingGeneratedPlacement;
  final ValueChanged<String>? onSelectGeneratedPlacementElement;
  final VoidCallback? onStartAddGeneratedPlacement;
  final VoidCallback? onStopAddGeneratedPlacement;
  final VoidCallback? onStartDeleteGeneratedPlacement;
  final VoidCallback? onStopDeleteGeneratedPlacement;

  @override
  Widget build(BuildContext context) {
    final actions = <_ActionData>[];
    if (isAddingGeneratedPlacement) {
      actions.add(
        _ActionData(
          icon: CupertinoIcons.stop_circle,
          label: 'Arrêter l’ajout',
          enabled: onStopAddGeneratedPlacement != null,
          onPressed: onStopAddGeneratedPlacement,
        ),
      );
    } else if (isDeletingGeneratedPlacement) {
      actions.add(
        _ActionData(
          icon: CupertinoIcons.stop_circle,
          label: 'Arrêter la suppression',
          enabled: onStopDeleteGeneratedPlacement != null,
          onPressed: onStopDeleteGeneratedPlacement,
        ),
      );
    } else if (!isMaskEditingActive) {
      if (readModel.hasGeneratedPlacements ||
          readModel.canPaintMask ||
          readModel.selectedAreaPaletteItems.isNotEmpty) {
        actions.add(
          _ActionData(
            icon: CupertinoIcons.plus_circle,
            label: 'Ajouter un élément généré',
            helperText:
                'Choisissez un élément du preset, puis cliquez sur la carte pour l’ajouter à cette zone.',
            enabled: readModel.canAddGeneratedPlacement &&
                !readModel.hasErrors &&
                onStartAddGeneratedPlacement != null,
            onPressed: readModel.canAddGeneratedPlacement
                ? onStartAddGeneratedPlacement
                : null,
          ),
        );
      }
      if (readModel.hasGeneratedPlacements || readModel.canPaintMask) {
        actions.add(
          _ActionData(
            icon: CupertinoIcons.minus_circle,
            label: 'Supprimer un élément généré',
            helperText:
                'Cliquez un élément généré pour le retirer de cette zone.',
            enabled: readModel.hasGeneratedPlacements &&
                !readModel.hasErrors &&
                onStartDeleteGeneratedPlacement != null,
            onPressed: readModel.hasGeneratedPlacements
                ? onStartDeleteGeneratedPlacement
                : null,
          ),
        );
      }
    }

    return _EnvironmentSubsection(
      title: 'Affinage manuel',
      children: [
        if (isDeletingGeneratedPlacement) ...[
          const _ActiveGeneratedPlacementDeleteBanner(),
          const SizedBox(height: 8),
        ],
        if (isAddingGeneratedPlacement) ...[
          const _ActiveGeneratedPlacementAddBanner(),
          const SizedBox(height: 8),
        ],
        if (_shouldShowGeneratedPlacementPalette(readModel)) ...[
          _GeneratedPlacementPaletteSection(
            items: readModel.selectedAreaPaletteItems,
            onSelectGeneratedPlacementElement:
                onSelectGeneratedPlacementElement,
          ),
          const SizedBox(height: 8),
        ],
        _ActionButtonColumn(actions: actions),
      ],
    );
  }
}

class _DiagnosticsSection extends StatelessWidget {
  const _DiagnosticsSection({required this.issues});

  final List<TileLayerEnvironmentAttachmentIssue> issues;

  @override
  Widget build(BuildContext context) {
    return _EnvironmentSubsection(
      title: 'Diagnostics',
      children: [
        for (final issue in issues)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _IssueBanner(issue: issue),
          ),
      ],
    );
  }
}

class _EnvironmentSubsection extends StatelessWidget {
  const _EnvironmentSubsection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: TextStyle(
            color: EditorChrome.primaryLabel(context),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _ActionButtonColumn extends StatelessWidget {
  const _ActionButtonColumn({required this.actions});

  final List<_ActionData> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final action in actions)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InspectorEmbeddedPrimaryCapsule(
                  accent: EditorChrome.inspectorJoyMint,
                  icon: action.icon,
                  label: action.label,
                  enabled: action.enabled,
                  onPressed: action.onPressed ?? () {},
                ),
                if (action.helperText != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    action.helperText!,
                    style: TextStyle(
                      color: EditorChrome.subtleLabel(context),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: accent.withValues(alpha: 0.12),
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.42)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: EditorChrome.primaryLabel(context),
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SummaryRowData {
  const _SummaryRowData(this.label, this.value);

  final String label;
  final String value;
}

class _ActionData {
  const _ActionData({
    required this.icon,
    required this.label,
    this.helperText,
    this.enabled = false,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final String? helperText;
  final bool enabled;
  final VoidCallback? onPressed;
}

bool _shouldShowCreateAreaGate(TileLayerEnvironmentAttachmentReadModel model) {
  return model.hasAttachment &&
      (model.state == TileLayerEnvironmentAttachmentState.noArea ||
          model.state ==
              TileLayerEnvironmentAttachmentState.areaSelectionRequired);
}

bool _shouldShowSetupActions(TileLayerEnvironmentAttachmentReadModel model) {
  return model.canEnableEnvironment || _shouldShowCreateAreaGate(model);
}

bool _shouldShowGenerationActions(
    TileLayerEnvironmentAttachmentReadModel model) {
  return model.canGenerate ||
      model.canPaintMask ||
      model.canClearGeneratedPlacements ||
      model.canRegenerate ||
      model.canShuffle;
}

bool _shouldShowManualRefinement(
  TileLayerEnvironmentAttachmentReadModel model, {
  required bool isEnvironmentActionActive,
}) {
  return isEnvironmentActionActive ||
      model.hasGeneratedPlacements ||
      model.canPaintMask ||
      model.selectedAreaPaletteItems.isNotEmpty;
}

bool _shouldShowGenerationParamsSection(
  TileLayerEnvironmentAttachmentReadModel model,
) {
  return model.selectedEnvironmentAreaId != null &&
      (model.canEditSelectedAreaGenerationParams ||
          model.selectedAreaSeed != null ||
          model.selectedAreaParamsOverride != null ||
          model.state == TileLayerEnvironmentAttachmentState.missingPreset);
}

bool _shouldShowGeneratedPlacementPalette(
  TileLayerEnvironmentAttachmentReadModel model,
) {
  return model.selectedPresetName != null &&
      (model.hasGeneratedPlacements ||
          model.selectedAreaPaletteItems.isNotEmpty);
}

String _paletteItemLabel(TileLayerEnvironmentPaletteItemSummary item) {
  if (item.hasMissingElement) {
    return 'Introuvable (${item.elementId})';
  }
  final name = item.elementName?.trim();
  if (name == null || name.isEmpty) {
    return item.elementId;
  }
  return name;
}

TileLayerEnvironmentPresetOption? _selectedPreset(
  List<TileLayerEnvironmentPresetOption> presets,
  String? selectedPresetId,
) {
  if (presets.length == 1) {
    return presets.single;
  }
  final id = selectedPresetId?.trim();
  if (id == null || id.isEmpty) {
    return null;
  }
  for (final preset in presets) {
    if (preset.id == id) {
      return preset;
    }
  }
  return null;
}

String? _presetNameForId(
  List<TileLayerEnvironmentPresetOption> presets,
  String id,
) {
  for (final preset in presets) {
    if (preset.id == id) {
      return preset.name;
    }
  }
  return null;
}

List<String> _areaSummaryDetails(TileLayerEnvironmentAreaSummary summary) {
  final presetName = summary.presetName?.trim();
  final presetLabel = summary.hasMissingPreset
      ? 'Preset introuvable : ${summary.presetId}'
      : 'Preset : ${presetName == null || presetName.isEmpty ? summary.presetId : presetName}';
  final details = <String>[
    presetLabel,
    'Masque : ${_paintedCellsLabel(summary.maskActiveCellCount)}',
    'Placements : ${summary.generatedPlacementCount}',
  ];
  if (summary.missingGeneratedPlacementCount > 0) {
    final count = summary.missingGeneratedPlacementCount;
    details.add(
        count == 1 ? '1 placement manquant' : '$count placements manquants');
  }
  return details;
}

String? _generationFeedbackMessage(
  TileLayerEnvironmentAttachmentReadModel model,
) {
  return switch (model.state) {
    TileLayerEnvironmentAttachmentState.selectedAreaMissing =>
      'La zone sélectionnée n’existe plus. Sélectionnez une zone valide.',
    TileLayerEnvironmentAttachmentState.missingPreset =>
      'Cette zone référence un preset qui n’existe plus.',
    _ => _trimmedOrNull(model.emptyStateMessage),
  };
}

String? _generationActionHint(TileLayerEnvironmentAttachmentReadModel model) {
  return switch (model.state) {
    TileLayerEnvironmentAttachmentState.noAttachment =>
      'Action recommandée : ${model.primaryActionLabel ?? 'Activer l’environnement'}',
    TileLayerEnvironmentAttachmentState.noArea =>
      'Action recommandée : ${model.primaryActionLabel ?? 'Ajouter une zone'}',
    TileLayerEnvironmentAttachmentState.areaSelectionRequired =>
      'Action recommandée : Sélectionner une zone',
    TileLayerEnvironmentAttachmentState.emptyMask =>
      'Action recommandée : Peindre le masque',
    TileLayerEnvironmentAttachmentState.ready when model.canGenerate =>
      'Action recommandée : Générer dans ce layer',
    TileLayerEnvironmentAttachmentState.generated
        when model.canClearGeneratedPlacements ||
            model.canRegenerate ||
            model.canShuffle =>
      'Actions disponibles : Effacer · Régénérer · Shuffle',
    _ => null,
  };
}

List<String> _generationFeedbackChips(
  TileLayerEnvironmentAttachmentReadModel model,
) {
  final chips = <String>[];
  if (model.maskActiveCellCount > 0) {
    chips.add(_compactCellsLabel(model.maskActiveCellCount));
  }
  if (model.selectedAreaSeed != null) {
    chips.add('Seed ${model.selectedAreaSeed}');
  }
  final params = model.selectedAreaEffectiveParams;
  if (params != null) {
    chips.add('Densité ${params.density.toStringAsFixed(2)}');
  }
  if (model.generatedPlacementCount > 0) {
    chips.add(_compactPlacementsLabel(model.generatedPlacementCount));
  }
  if (model.missingGeneratedPlacementCount > 0) {
    chips.add(
      _compactMissingReferencesLabel(model.missingGeneratedPlacementCount),
    );
  }
  return chips;
}

String? _trimmedOrNull(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

String _compactCellsLabel(int count) {
  if (count == 1) {
    return '1 case';
  }
  return '$count cases';
}

String _compactPlacementsLabel(int count) {
  if (count == 1) {
    return '1 placement';
  }
  return '$count placements';
}

String _compactMissingReferencesLabel(int count) {
  if (count == 1) {
    return '1 référence manquante';
  }
  return '$count références manquantes';
}

String _stateTitle(TileLayerEnvironmentAttachmentReadModel model) {
  final title = model.emptyStateTitle.trim();
  if (title.isNotEmpty) {
    return title;
  }
  return switch (model.state) {
    TileLayerEnvironmentAttachmentState.ready => 'Prêt à générer',
    TileLayerEnvironmentAttachmentState.generated => 'Placements générés',
    TileLayerEnvironmentAttachmentState.emptyMask => 'Masque vide',
    TileLayerEnvironmentAttachmentState.missingPreset => 'Preset introuvable',
    TileLayerEnvironmentAttachmentState.noAttachment =>
      'Aucun environnement sur ce layer',
    TileLayerEnvironmentAttachmentState.noArea => 'Aucune zone d’environnement',
    TileLayerEnvironmentAttachmentState.areaSelectionRequired =>
      'Sélectionnez une zone d’environnement',
    TileLayerEnvironmentAttachmentState.selectedAreaMissing =>
      'Zone introuvable',
    TileLayerEnvironmentAttachmentState.missingTargetTileLayer =>
      'Layer cible manquant',
    TileLayerEnvironmentAttachmentState.targetTileLayerMissing =>
      'Layer cible introuvable',
    TileLayerEnvironmentAttachmentState.targetLayerIsNotTileLayer =>
      'Layer cible incompatible',
    TileLayerEnvironmentAttachmentState.noProject => 'Aucun projet chargé',
    TileLayerEnvironmentAttachmentState.noMap => 'Aucune carte active',
    TileLayerEnvironmentAttachmentState.noLayerSelected =>
      'Aucun layer sélectionné',
    TileLayerEnvironmentAttachmentState.selectedLayerMissing =>
      'Layer introuvable',
    TileLayerEnvironmentAttachmentState.unsupportedLayer =>
      'Sélectionnez un TileLayer',
  };
}

String _paintedCellsLabel(int count) {
  if (count <= 0) {
    return '0 case peinte';
  }
  if (count == 1) {
    return '1 case peinte';
  }
  return '$count cases peintes';
}

double _clampUnit(double value) {
  return value.clamp(0.0, 1.0).toDouble();
}

double _roundUnit(double value) {
  return (_clampUnit(value) * 100).round() / 100;
}
