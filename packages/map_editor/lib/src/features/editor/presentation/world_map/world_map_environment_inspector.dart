import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../../application/models/tile_layer_environment_attachment_read_model.dart';
import '../../../../application/services/tile_layer_environment_attachment_read_model_builder.dart';
import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';
import '../../state/editor_notifier.dart';
import '../../state/environment_generated_placement_add_element_provider.dart';
import '../../state/environment_mask_brush_size_provider.dart';
import '../../tools/editor_tool.dart';

/// The dedicated page for the environment carried by the selected layer.
///
/// An environment is authored as a thing of its own — zones, mask, generation —
/// so it gets its own inspector rather than a strip inside the layer list. That
/// it happens to be attached to a Tile layer is a storage detail the author
/// never has to think about here.
class WorldMapEnvironmentInspector extends ConsumerWidget {
  const WorldMapEnvironmentInspector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final map = state.activeMap;
    final layer = map?.layers
        .where((candidate) => candidate.id == state.activeLayerId)
        .firstOrNull;
    if (map == null || layer is! TileLayer) {
      return const PokeMapEmptyState(
        icon: Icon(Icons.park_outlined),
        title: 'Aucun environnement sélectionné',
        description: 'Choisissez un calque qui porte un environnement dans '
            'le panneau Calques.',
      );
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
      return PokeMapEmptyState(
        icon: const Icon(Icons.park_outlined),
        title: 'Aucun environnement sur « ${layer.name} »',
        description: 'Activez l’environnement depuis le panneau Calques.',
      );
    }

    final maskMode = state.environmentMaskEditMode;
    return ListView(
      key: const ValueKey<String>('world-map-environment-inspector'),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
      children: [
        PokeMapSectionHeader(
          title: layer.name,
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
        const SizedBox(height: 10),
        _PresetCard(model: model, notifier: notifier),
        if (model.selectedEnvironmentAreaId != null) ...[
          const SizedBox(height: 10),
          _MaskCard(model: model, maskMode: maskMode, notifier: notifier),
          const SizedBox(height: 10),
          _GenerationCard(
            model: model,
            maskMode: maskMode,
            notifier: notifier,
          ),
          const SizedBox(height: 10),
          _TuningCard(model: model, notifier: notifier),
          if (model.hasGeneratedPlacements) ...[
            const SizedBox(height: 10),
            _GeneratedPlacementsCard(
              model: model,
              maskMode: maskMode,
              notifier: notifier,
            ),
          ],
        ],
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.children,
    this.description,
  });

  final String title;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      borderRadius: 8,
      accentTone: PokeMapTone.success,
      padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          PokeMapSectionHeader(title: title, description: description),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

/// The preset the single zone runs on, plus the way to open that zone.
///
/// A layer carries exactly one zone, so there is nothing to pick between and
/// nothing to name: the preset is the only choice left.
class _PresetCard extends ConsumerWidget {
  const _PresetCard({required this.model, required this.notifier});

  final TileLayerEnvironmentAttachmentReadModel model;
  final EditorNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorNotifierProvider);
    final presets =
        state.project?.environmentPresets ?? const <EnvironmentPreset>[];
    if (presets.isEmpty) {
      return const _Card(
        title: 'Preset',
        children: <Widget>[
          PokeMapEmptyState(
            key: ValueKey<String>('world-map-environment-no-preset'),
            icon: Icon(Icons.park_outlined),
            title: 'Aucun preset d’environnement',
            description: 'Créez-en un dans Environment Studio, puis revenez '
                'ici.',
            compact: true,
          ),
        ],
      );
    }

    final areaId = model.selectedEnvironmentAreaId;
    final presetId = model.selectedPresetId ?? presets.first.id;
    final environmentLayerId = model.attachedEnvironmentLayerId;
    return _Card(
      title: 'Preset',
      description: model.selectedPresetName,
      children: <Widget>[
        PokeMapDropdownField<String>(
          key: const ValueKey<String>('world-map-environment-preset'),
          label: 'Preset',
          value: presets.any((preset) => preset.id == presetId)
              ? presetId
              : presets.first.id,
          compact: true,
          items: <PokeMapDropdownItem<String>>[
            for (final preset in presets)
              PokeMapDropdownItem<String>(
                value: preset.id,
                label: preset.name,
              ),
          ],
          onChanged: areaId == null || environmentLayerId == null
              ? (_) {}
              : (value) => notifier.setEnvironmentAreaPreset(
                    environmentLayerId: environmentLayerId,
                    areaId: areaId,
                    presetId: value,
                  ),
        ),
        if (areaId == null) ...[
          const SizedBox(height: 8),
          PokeMapButton(
            key: const ValueKey<String>('world-map-environment-create-area'),
            onPressed: model.hasErrors
                ? null
                : () => notifier.createEnvironmentAreaForActiveTileLayer(
                      presetId: presetId,
                    ),
            variant: PokeMapButtonVariant.primary,
            size: PokeMapButtonSize.compact,
            leading: const Icon(Icons.play_arrow_rounded),
            child: const Text('Démarrer l’environnement'),
          ),
        ],
      ],
    );
  }
}

class _MaskCard extends ConsumerWidget {
  const _MaskCard({
    required this.model,
    required this.maskMode,
    required this.notifier,
  });

  final TileLayerEnvironmentAttachmentReadModel model;
  final EnvironmentMaskEditMode? maskMode;
  final EditorNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPainting = maskMode == EnvironmentMaskEditMode.paint;
    final isErasing = maskMode == EnvironmentMaskEditMode.erase;
    final brushSize = ref.watch(environmentMaskBrushSizeProvider);
    final canEdit = model.canPaintMask && !model.hasErrors;
    return _Card(
      title: 'Masque',
      description: '${model.maskActiveCellCount} cellule(s) peinte(s)',
      children: <Widget>[
        Row(
          children: [
            Expanded(
              child: PokeMapButton(
                key: const ValueKey<String>('world-map-environment-mask-paint'),
                onPressed: isPainting
                    ? notifier.stopEnvironmentMaskPainting
                    : canEdit && !isErasing
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
                    : canEdit && !isPainting
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
        const SizedBox(height: 10),
        // The mask brush only offers odd sizes so a stroke stays centred on the
        // cell under the cursor.
        PokeMapDropdownField<int>(
          key: const ValueKey<String>('world-map-environment-brush'),
          label: 'Taille du pinceau',
          value: brushSize,
          compact: true,
          items: const <PokeMapDropdownItem<int>>[
            PokeMapDropdownItem<int>(value: 1, label: '1 × 1'),
            PokeMapDropdownItem<int>(value: 3, label: '3 × 3'),
            PokeMapDropdownItem<int>(value: 5, label: '5 × 5'),
            PokeMapDropdownItem<int>(value: 7, label: '7 × 7'),
          ],
          onChanged: notifier.setEnvironmentMaskBrushSize,
        ),
      ],
    );
  }
}

class _GenerationCard extends StatelessWidget {
  const _GenerationCard({
    required this.model,
    required this.maskMode,
    required this.notifier,
  });

  final TileLayerEnvironmentAttachmentReadModel model;
  final EnvironmentMaskEditMode? maskMode;
  final EditorNotifier notifier;

  @override
  Widget build(BuildContext context) {
    // Generating under an open mask gesture would commit half a stroke.
    final busy = maskMode != null || model.hasErrors;
    return _Card(
      title: 'Génération',
      description: '${model.generatedPlacementCount} élément(s) posé(s)',
      children: <Widget>[
        PokeMapButton(
          key: const ValueKey<String>('world-map-environment-generate'),
          onPressed: busy
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
          child: Text(model.hasGeneratedPlacements ? 'Régénérer' : 'Générer'),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: PokeMapButton(
                key: const ValueKey<String>('world-map-environment-shuffle'),
                onPressed: busy || !model.canShuffle
                    ? null
                    : notifier.shuffleEnvironmentAreaPlacementsForActiveTileLayer,
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.compact,
                leading: const Icon(Icons.shuffle_rounded),
                child: const Text('Mélanger'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: PokeMapButton(
                key: const ValueKey<String>('world-map-environment-clear'),
                onPressed: busy || !model.canClearGeneratedPlacements
                    ? null
                    : notifier
                        .clearEnvironmentGeneratedPlacementsForActiveTileLayer,
                variant: PokeMapButtonVariant.danger,
                size: PokeMapButtonSize.compact,
                leading: const Icon(Icons.layers_clear_outlined),
                child: const Text('Tout effacer'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TuningCard extends StatelessWidget {
  const _TuningCard({required this.model, required this.notifier});

  final TileLayerEnvironmentAttachmentReadModel model;
  final EditorNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final params = model.selectedAreaEffectiveParams;
    final enabled = model.canEditSelectedAreaGenerationParams;
    if (params == null) return const SizedBox.shrink();

    void update(EnvironmentGenerationParams next) {
      notifier.setEnvironmentAreaParamsOverrideForActiveTileLayer(next);
    }

    return _Card(
      title: 'Réglages',
      description: model.selectedAreaHasParamsOverride
          ? 'Réglages propres à cette zone'
          : 'Valeurs héritées du preset',
      children: <Widget>[
        PokeMapGuidedSlider(
          key: const ValueKey<String>('world-map-environment-density'),
          label: 'Densité',
          value: (params.density * 100).round(),
          onChanged: enabled
              ? (value) => update(
                    EnvironmentGenerationParams(
                      density: value / 100,
                      variation: params.variation,
                      edgeDensity: params.edgeDensity,
                      minSpacingCells: params.minSpacingCells,
                    ),
                  )
              : (_) {},
        ),
        PokeMapGuidedSlider(
          key: const ValueKey<String>('world-map-environment-edge-density'),
          label: 'Densité en bordure',
          description: 'Ce que la génération pose sur le pourtour du masque.',
          value: (params.edgeDensity * 100).round(),
          onChanged: enabled
              ? (value) => update(
                    EnvironmentGenerationParams(
                      density: params.density,
                      variation: params.variation,
                      edgeDensity: value / 100,
                      minSpacingCells: params.minSpacingCells,
                    ),
                  )
              : (_) {},
        ),
        PokeMapGuidedSlider(
          key: const ValueKey<String>('world-map-environment-variation'),
          label: 'Variation',
          value: (params.variation * 100).round(),
          onChanged: enabled
              ? (value) => update(
                    EnvironmentGenerationParams(
                      density: params.density,
                      variation: value / 100,
                      edgeDensity: params.edgeDensity,
                      minSpacingCells: params.minSpacingCells,
                    ),
                  )
              : (_) {},
        ),
        PokeMapGuidedSlider(
          key: const ValueKey<String>('world-map-environment-spacing'),
          label: 'Espacement minimal',
          description: 'En cellules, entre deux éléments posés.',
          value: params.minSpacingCells,
          max: 8,
          onChanged: enabled
              ? (value) => update(
                    EnvironmentGenerationParams(
                      density: params.density,
                      variation: params.variation,
                      edgeDensity: params.edgeDensity,
                      minSpacingCells: value,
                    ),
                  )
              : (_) {},
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Graine : ${model.selectedAreaSeed ?? '—'}',
                key: const ValueKey<String>('world-map-environment-seed'),
                style: TextStyle(
                  color: context.pokeMapColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
            PokeMapButton(
              key: const ValueKey<String>('world-map-environment-reseed'),
              // A new seed is the fastest way to try another layout without
              // touching a single slider.
              onPressed: enabled
                  ? () => notifier.setEnvironmentAreaSeedForActiveTileLayer(
                        (model.selectedAreaSeed ?? 0) + 1,
                      )
                  : null,
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.compact,
              leading: const Icon(Icons.casino_outlined),
              child: const Text('Nouvelle graine'),
            ),
          ],
        ),
        if (model.selectedAreaHasParamsOverride) ...[
          const SizedBox(height: 6),
          PokeMapButton(
            key: const ValueKey<String>('world-map-environment-reset-params'),
            onPressed: enabled
                ? notifier.resetEnvironmentAreaParamsOverrideForActiveTileLayer
                : null,
            variant: PokeMapButtonVariant.secondary,
            size: PokeMapButtonSize.compact,
            leading: const Icon(Icons.restart_alt_rounded),
            child: const Text('Revenir aux valeurs du preset'),
          ),
        ],
      ],
    );
  }
}

class _GeneratedPlacementsCard extends StatelessWidget {
  const _GeneratedPlacementsCard({
    required this.model,
    required this.maskMode,
    required this.notifier,
  });

  final TileLayerEnvironmentAttachmentReadModel model;
  final EnvironmentMaskEditMode? maskMode;
  final EditorNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final isAdding = maskMode == EnvironmentMaskEditMode.generatedAdd;
    final isDeleting = maskMode == EnvironmentMaskEditMode.generatedDelete;
    final idle = maskMode == null;
    return _Card(
      title: 'Retouche',
      description: 'Ajoutez ou retirez des éléments un par un sur la carte.',
      children: <Widget>[
        if (model.selectedAreaPaletteItems.isNotEmpty)
          PokeMapDropdownField<String>(
            key: const ValueKey<String>('world-map-environment-palette'),
            label: 'Élément à poser',
            value: model.selectedAreaPaletteItems
                    .where((item) => item.isSelected)
                    .firstOrNull
                    ?.elementId ??
                model.selectedAreaPaletteItems.first.elementId,
            compact: true,
            items: <PokeMapDropdownItem<String>>[
              for (final item in model.selectedAreaPaletteItems)
                PokeMapDropdownItem<String>(
                  value: item.elementId,
                  label: item.elementName ?? item.elementId,
                ),
            ],
            onChanged: notifier
                .selectEnvironmentGeneratedPlacementElementForActiveTileLayer,
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: PokeMapButton(
                key: const ValueKey<String>('world-map-environment-add'),
                onPressed: isAdding
                    ? notifier.stopAddingGeneratedEnvironmentPlacement
                    : idle && model.canAddGeneratedPlacement
                        ? notifier
                            .startAddingGeneratedEnvironmentPlacementForActiveTileLayer
                        : null,
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.compact,
                isSelected: isAdding,
                leading: const Icon(Icons.add_location_alt_outlined),
                child: Text(isAdding ? 'Terminer' : 'Ajouter'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: PokeMapButton(
                key: const ValueKey<String>('world-map-environment-remove'),
                onPressed: isDeleting
                    ? notifier.stopDeletingGeneratedEnvironmentPlacement
                    : idle && model.hasGeneratedPlacements && !model.hasErrors
                        ? notifier
                            .startDeletingGeneratedEnvironmentPlacementForActiveTileLayer
                        : null,
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.compact,
                isSelected: isDeleting,
                leading: const Icon(Icons.wrong_location_outlined),
                child: Text(isDeleting ? 'Terminer' : 'Retirer'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
