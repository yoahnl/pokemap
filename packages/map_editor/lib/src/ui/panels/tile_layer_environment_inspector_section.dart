import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
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
    this.isMaskPaintingActive = false,
    this.isMaskErasingActive = false,
    this.onStartMaskPainting,
    this.onStartMaskErasing,
    this.onStopMaskPainting,
    this.environmentMaskBrushSize = kDefaultEnvironmentMaskBrushSize,
    this.onSetEnvironmentMaskBrushSize,
    this.onSetGenerationParams,
    this.onResetGenerationParams,
    this.onSetSeed,
  });

  final TileLayerEnvironmentAttachmentReadModel readModel;
  final VoidCallback? onEnableEnvironment;
  final List<TileLayerEnvironmentPresetOption> availablePresets;
  final String? selectedPresetIdForNewArea;
  final ValueChanged<String>? onSelectPresetForNewArea;
  final VoidCallback? onCreateArea;
  final ValueChanged<String>? onSelectEnvironmentArea;
  final bool isMaskPaintingActive;
  final bool isMaskErasingActive;
  final VoidCallback? onStartMaskPainting;
  final VoidCallback? onStartMaskErasing;
  final VoidCallback? onStopMaskPainting;
  final int environmentMaskBrushSize;
  final ValueChanged<int>? onSetEnvironmentMaskBrushSize;
  final ValueChanged<EnvironmentGenerationParams>? onSetGenerationParams;
  final VoidCallback? onResetGenerationParams;
  final ValueChanged<int>? onSetSeed;

  @override
  Widget build(BuildContext context) {
    const accent = EditorChrome.inspectorJoyMint;
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final isMaskEditingActive = isMaskPaintingActive || isMaskErasingActive;

    return SingleChildScrollView(
      padding: kInspectorTileBodyPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  _stateTitle(readModel),
                  style: TextStyle(
                    color: label,
                    fontSize: 14,
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
          if (readModel.emptyStateMessage.trim().isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              readModel.emptyStateMessage,
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                height: 1.32,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _SummaryRows(readModel: readModel),
          if (readModel.areaSummaries.isNotEmpty) ...[
            const SizedBox(height: 12),
            _EnvironmentAreaSummaryList(
              summaries: readModel.areaSummaries,
              onSelectEnvironmentArea: onSelectEnvironmentArea,
            ),
          ],
          if (readModel.issues.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...readModel.issues.map(
              (issue) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _IssueBanner(issue: issue),
              ),
            ),
          ],
          if (isMaskEditingActive) ...[
            const SizedBox(height: 12),
            _ActiveMaskEditingBanner(isErasing: isMaskErasingActive),
          ],
          if (readModel.canPaintMask || isMaskEditingActive) ...[
            const SizedBox(height: 12),
            _BrushSizeSelector(
              selectedSize: environmentMaskBrushSize,
              onChanged: onSetEnvironmentMaskBrushSize,
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
          const SizedBox(height: 12),
          if (_shouldShowCreateAreaGate(readModel)) ...[
            _CreateAreaPresetGate(
              availablePresets: availablePresets,
              selectedPresetIdForNewArea: selectedPresetIdForNewArea,
              onSelectPresetForNewArea: onSelectPresetForNewArea,
            ),
            const SizedBox(height: 12),
          ],
          _FutureActions(
            readModel: readModel,
            onEnableEnvironment: onEnableEnvironment,
            availablePresets: availablePresets,
            selectedPresetIdForNewArea: selectedPresetIdForNewArea,
            onCreateArea: onCreateArea,
            isMaskPaintingActive: isMaskPaintingActive,
            isMaskErasingActive: isMaskErasingActive,
            onStartMaskPainting: onStartMaskPainting,
            onStartMaskErasing: onStartMaskErasing,
            onStopMaskPainting: onStopMaskPainting,
          ),
          const SizedBox(height: 8),
          const InspectorEmbeddedFootnote(
            text:
                'Section de lecture uniquement : les actions seront activées dans un prochain lot.',
            accent: accent,
          ),
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

class _ActiveMaskEditingBanner extends StatelessWidget {
  const _ActiveMaskEditingBanner({required this.isErasing});

  final bool isErasing;

  @override
  Widget build(BuildContext context) {
    final title = isErasing ? 'Effacement actif' : 'Peinture active';
    final message = isErasing
        ? 'Mode effacement actif : cliquez sur la carte pour retirer des cellules du masque.'
        : 'Mode peinture actif : cliquez sur la carte pour peindre le masque.';
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
  });

  final List<TileLayerEnvironmentAreaSummary> summaries;
  final ValueChanged<String>? onSelectEnvironmentArea;

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
        ],
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

class _FutureActions extends StatelessWidget {
  const _FutureActions({
    required this.readModel,
    required this.onEnableEnvironment,
    required this.availablePresets,
    required this.selectedPresetIdForNewArea,
    required this.onCreateArea,
    required this.isMaskPaintingActive,
    required this.isMaskErasingActive,
    required this.onStartMaskPainting,
    required this.onStartMaskErasing,
    required this.onStopMaskPainting,
  });

  final TileLayerEnvironmentAttachmentReadModel readModel;
  final VoidCallback? onEnableEnvironment;
  final List<TileLayerEnvironmentPresetOption> availablePresets;
  final String? selectedPresetIdForNewArea;
  final VoidCallback? onCreateArea;
  final bool isMaskPaintingActive;
  final bool isMaskErasingActive;
  final VoidCallback? onStartMaskPainting;
  final VoidCallback? onStartMaskErasing;
  final VoidCallback? onStopMaskPainting;

  @override
  Widget build(BuildContext context) {
    final actions = <_ActionData>[];
    final isMaskEditingActive = isMaskPaintingActive || isMaskErasingActive;
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
    if (isMaskEditingActive) {
      actions.add(
        _ActionData(
          icon: CupertinoIcons.stop_circle,
          label: 'Arrêter la peinture',
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
    if (readModel.canGenerate) {
      actions.add(
        const _ActionData(
          icon: CupertinoIcons.play,
          label: 'Générer dans ce layer',
        ),
      );
    }
    if (readModel.canClearGeneratedPlacements) {
      actions.add(
        const _ActionData(
          icon: CupertinoIcons.trash,
          label: 'Effacer les placements générés',
        ),
      );
    }

    if (actions.isEmpty) {
      return InspectorEmbeddedSecondaryCapsule(
        accent: EditorChrome.inspectorJoyMint,
        icon: CupertinoIcons.clock,
        label: 'Actions bientôt disponibles',
        enabled: false,
        onPressed: () {},
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final action in actions)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: InspectorEmbeddedPrimaryCapsule(
              accent: EditorChrome.inspectorJoyMint,
              icon: action.icon,
              label: action.label,
              enabled: action.enabled,
              onPressed: action.onPressed ?? () {},
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
    this.enabled = false,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback? onPressed;
}

bool _shouldShowCreateAreaGate(TileLayerEnvironmentAttachmentReadModel model) {
  return model.hasAttachment &&
      (model.state == TileLayerEnvironmentAttachmentState.noArea ||
          model.state ==
              TileLayerEnvironmentAttachmentState.areaSelectionRequired);
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
