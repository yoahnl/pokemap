import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../editor/state/editor_notifier.dart';
import '../../editor/tools/editor_tool.dart';
import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';
import '../application/border_feature_authoring_controller.dart';
import '../application/border_preview_transaction.dart';
import '../application/border_tool_availability.dart';
import 'border_diagnostic_presentation.dart';
import '../state/border_map_editing_providers.dart';
import '../state/border_preview_providers.dart';

/// Dedicated no-code authoring controls for one World Maps Border layer.
class BorderLayerInspectorPanel extends ConsumerStatefulWidget {
  const BorderLayerInspectorPanel({super.key});

  @override
  ConsumerState<BorderLayerInspectorPanel> createState() =>
      _BorderLayerInspectorPanelState();
}

class _BorderLayerInspectorPanelState
    extends ConsumerState<BorderLayerInspectorPanel> {
  String? _createBlueprintId;
  String? _pendingBlueprintId;
  String? _pendingFeatureId;
  String? _pendingBeforeBlueprintId;
  String? _correctionSlotKey;
  String? _replacementPrimitiveId;
  String _movePresetId = 'right-1';
  int _keepOutRadiusCells = 0;

  @override
  Widget build(BuildContext context) {
    final editor = ref.watch(editorNotifierProvider);
    final selection = ref.watch(activeBorderFeatureControllerProvider);
    final previewState = ref.watch(borderPreviewControllerProvider);
    final resizeFeedback = ref.watch(borderResizeFeedbackProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final map = editor.activeMap;
    if (map == null) {
      return _withSafetyMessage(
        context,
        const PokeMapEmptyState(
          title: 'Aucune carte active',
          description: 'Ouvrez une carte pour authorer ses bordures.',
          icon: Icon(CupertinoIcons.waveform_path),
        ),
      );
    }

    final borderLayers = map.layers.whereType<BorderLayer>().toList();
    final activeLayer = borderLayers
        .where((layer) => layer.id == editor.activeLayerId)
        .firstOrNull;
    final publishedBlueprints = _publishedBlueprints(editor.project);

    if (borderLayers.isEmpty) {
      return _withSafetyMessage(
        context,
        PokeMapEmptyState(
          title: 'Aucun calque de bordures',
          description:
              'Créez un calque dédié pour dessiner sans modifier les règles de déplacement.',
          icon: const Icon(CupertinoIcons.waveform_path),
          action: PokeMapButton(
            key: const ValueKey('border-create-layer-button'),
            onPressed: () => notifier.addMapLayer(
              kind: MapLayerKind.border,
              name: 'Bordures',
            ),
            leading: const Icon(CupertinoIcons.add),
            child: const Text('Créer un calque de bordures'),
          ),
        ),
      );
    }

    if (activeLayer == null) {
      return _withSafetyMessage(
        context,
        PokeMapEmptyState(
          title: 'Calque de bordures inactif',
          description:
              'Sélectionnez le calque de bordures pour accéder à ses features et outils.',
          icon: const Icon(CupertinoIcons.layers),
          action: PokeMapButton(
            key: const ValueKey('border-select-layer-button'),
            onPressed: () => notifier.setActiveLayer(borderLayers.last.id),
            variant: PokeMapButtonVariant.secondary,
            child: const Text('Sélectionner un calque de bordures'),
          ),
        ),
      );
    }

    final resizeDiagnostics = resizeFeedback?.appliesTo(map) == true
        ? resizeFeedback!.diagnosticReport.diagnostics
        : const <BorderDiagnostic>[];

    final activeFeature = selection.activeLayerId == activeLayer.id
        ? activeLayer.content.featureById(selection.activeFeatureId ?? '')
        : null;
    final createBlueprintId =
        publishedBlueprints.any((record) => record.id == _createBlueprintId)
            ? _createBlueprintId!
            : publishedBlueprints.firstOrNull?.id;
    final pendingBlueprintId = activeFeature != null &&
            _pendingFeatureId == activeFeature.id &&
            _pendingBeforeBlueprintId == activeFeature.blueprintId &&
            _pendingBlueprintId != activeFeature.blueprintId
        ? _pendingBlueprintId
        : null;
    final targetBlueprint = publishedBlueprints
        .where((record) => record.id == pendingBlueprintId)
        .firstOrNull;
    final blueprintPreview = activeFeature != null && targetBlueprint != null
        ? const BorderFeatureAuthoringController().previewBlueprintChange(
            map: map,
            layerId: activeLayer.id,
            featureId: activeFeature.id,
            sourceBlueprint: editor.project?.borderCatalog
                .recordById(activeFeature.blueprintId),
            targetBlueprint: targetBlueprint,
            visualSnapshots: editor.project!.borderCatalog.visualSnapshots,
            tileSizePx: GridSize(
              width: editor.project!.settings.tileWidth,
              height: editor.project!.settings.tileHeight,
            ),
          )
        : null;
    final toolAvailability = assessBorderToolAvailability(
      manifest: editor.project,
      map: map,
      activeLayerId: activeLayer.id,
      activeFeatureId: activeFeature?.id,
    );
    final activePreview = previewState.transaction;
    final previewTargetsFeature = activeFeature != null &&
        activePreview?.layerId == activeLayer.id &&
        activePreview?.featureId == activeFeature.id;
    final correctionDraft =
        previewTargetsFeature ? activePreview!.proposedFeature : activeFeature;
    final correctionMaterialization = previewTargetsFeature
        ? activePreview!.result?.materialization ??
            activeFeature.materialization
        : activeFeature?.materialization;
    final correctionPlacements = correctionMaterialization?.placements ??
        const <BorderResolvedPlacement>[];
    final correctionSlotKey = correctionPlacements.any(
      (placement) => placement.slotKey == _correctionSlotKey,
    )
        ? _correctionSlotKey
        : correctionPlacements.firstOrNull?.slotKey;
    final selectedCorrectionPlacement = correctionPlacements
        .where((placement) => placement.slotKey == correctionSlotKey)
        .firstOrNull;
    final activeRevision = activeFeature == null
        ? null
        : editor.project?.borderCatalog
            .recordById(activeFeature.blueprintId)
            ?.latestPublished;
    final replacementPrimitives = _compatibleReplacementPrimitives(
      activeRevision,
      selectedCorrectionPlacement,
    );
    final replacementPrimitiveId = replacementPrimitives.any(
      (primitive) => primitive.id == _replacementPrimitiveId,
    )
        ? _replacementPrimitiveId
        : replacementPrimitives.firstOrNull?.id;
    final movePreset = _borderMovePresets
            .where((preset) => preset.id == _movePresetId)
            .firstOrNull ??
        _borderMovePresets.first;

    return _withSafetyMessage(
      context,
      SingleChildScrollView(
        primary: false,
        padding: const EdgeInsets.fromLTRB(2, 2, 2, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _layerControls(context, notifier, activeLayer),
            const SizedBox(height: 10),
            _toolStatus(
              context,
              notifier,
              toolAvailability,
              lineGeometry: activeFeature?.geometry is BorderStrokeGeometry,
            ),
            if (activeFeature != null &&
                activeRevision != null &&
                borderTemplateSupportsLineSide(
                  activeRevision.definition.template,
                )) ...[
              const SizedBox(height: 10),
              _lineSideControls(
                notifier,
                activeLayer,
                correctionDraft!,
                template: activeRevision.definition.template,
                canToggleSide: previewState.phase == BorderPreviewPhase.idle ||
                    (previewTargetsFeature &&
                        (previewState.phase == BorderPreviewPhase.resolved ||
                            previewState.phase == BorderPreviewPhase.invalid)),
              ),
            ],
            if (resizeDiagnostics.isNotEmpty) ...[
              const SizedBox(height: 10),
              _resizeDiagnosticsCard(context, resizeDiagnostics),
            ],
            if (previewState.transaction case final preview?) ...[
              const SizedBox(height: 10),
              _previewActions(
                context,
                notifier,
                previewState,
                preview,
                activeLayer: activeLayer,
                activeFeature: activeFeature,
              ),
            ],
            const SizedBox(height: 14),
            const PokeMapSectionHeader(
              title: 'Blueprint publié',
              description:
                  'Seules les révisions publiées et non obsolètes sont proposées.',
            ),
            if (publishedBlueprints.isEmpty)
              const PokeMapEmptyState(
                title: 'Aucun blueprint disponible',
                description:
                    'Publiez un blueprint dans Border Studio avant de créer une bordure.',
                icon: Icon(CupertinoIcons.archivebox),
              )
            else ...[
              PokeMapDropdownField<String>(
                key: const ValueKey('border-blueprint-create-picker'),
                label: 'Blueprint pour une nouvelle bordure',
                value: createBlueprintId!,
                items: _blueprintItems(publishedBlueprints),
                onChanged: (id) => setState(() {
                  _createBlueprintId = id;
                }),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: PokeMapButton(
                  key: const ValueKey('border-create-feature-button'),
                  onPressed: () => _createFeature(
                    context,
                    notifier,
                    activeLayer,
                    createBlueprintId,
                  ),
                  size: PokeMapButtonSize.small,
                  leading: const Icon(CupertinoIcons.add),
                  child: const Text('Créer une bordure'),
                ),
              ),
            ],
            const SizedBox(height: 14),
            PokeMapSectionHeader(
              title: 'Bordures du calque',
              description:
                  'La première carte affichée est la plus haute visuellement.',
              trailing: PokeMapBadge(
                label: '${activeLayer.content.features.length}',
              ),
            ),
            if (activeLayer.content.features.isEmpty)
              const PokeMapEmptyState(
                title: 'Aucune bordure',
                description:
                    'Choisissez un blueprint publié, puis créez une feature nommée.',
                icon: Icon(CupertinoIcons.waveform_path),
              )
            else ...[
              for (final feature in activeLayer.content.features.reversed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _featureCard(
                    context,
                    notifier,
                    activeLayer,
                    feature,
                    selected: feature.id == activeFeature?.id,
                    manifest: editor.project,
                  ),
                ),
            ],
            if (activeFeature != null) ...[
              const SizedBox(height: 8),
              _featureActions(
                context,
                notifier,
                activeLayer,
                activeFeature,
              ),
              const SizedBox(height: 8),
              _materializationLifecycleActions(
                notifier,
                activeLayer,
                activeFeature,
              ),
              const SizedBox(height: 8),
              _localCorrectionActions(
                notifier,
                map: map,
                layer: activeLayer,
                persistedFeature: activeFeature,
                draftFeature: correctionDraft!,
                placements: correctionPlacements,
                selectedPlacement: selectedCorrectionPlacement,
                selectedSlotKey: correctionSlotKey,
                replacementPrimitives: replacementPrimitives,
                replacementPrimitiveId: replacementPrimitiveId,
                movePreset: movePreset,
              ),
              if (publishedBlueprints.isNotEmpty) ...[
                const SizedBox(height: 14),
                const PokeMapSectionHeader(
                  title: 'Changer de blueprint',
                  description:
                      'Le sélecteur prépare un aperçu résolu avant/après sans modifier la carte.',
                ),
                PokeMapDropdownField<String>(
                  key: const ValueKey('border-blueprint-change-picker'),
                  label: 'Révision publiée cible',
                  value: pendingBlueprintId ?? activeFeature.blueprintId,
                  items: _blueprintItems(publishedBlueprints),
                  onChanged: (id) => setState(() {
                    _pendingBlueprintId = id;
                    _pendingFeatureId = activeFeature.id;
                    _pendingBeforeBlueprintId = activeFeature.blueprintId;
                  }),
                ),
              ],
              if (blueprintPreview != null) ...[
                const SizedBox(height: 8),
                _blueprintPreview(
                  context,
                  notifier,
                  blueprintPreview,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _withSafetyMessage(BuildContext context, Widget child) {
    final colors = context.pokeMapColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: child),
        const SizedBox(height: 8),
        PokeMapCard(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.eye,
                size: 15,
                color: colors.info,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  borderVisualOnlySafetyMessage,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _layerControls(
    BuildContext context,
    EditorNotifier notifier,
    BorderLayer layer,
  ) {
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PokeMapSectionHeader(
            title: layer.name,
            description: 'Calque de bordures actif',
            trailing: PokeMapBadge(
              label: layer.isVisible ? 'Visible' : 'Masqué',
              variant: layer.isVisible
                  ? PokeMapBadgeVariant.success
                  : PokeMapBadgeVariant.neutral,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: PokeMapButton(
              key: const ValueKey('border-layer-visibility-button'),
              onPressed: () =>
                  notifier.setMapLayerVisibility(layer.id, !layer.isVisible),
              size: PokeMapButtonSize.small,
              variant: PokeMapButtonVariant.secondary,
              leading: Icon(
                layer.isVisible ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
              ),
              child: Text(
                  layer.isVisible ? 'Masquer le calque' : 'Afficher le calque'),
            ),
          ),
          const SizedBox(height: 10),
          KeyedSubtree(
            key: const ValueKey('border-layer-opacity-slider'),
            child: PokeMapGuidedSlider(
              label: 'Opacité du calque',
              value: (layer.opacity * 100).round(),
              onChanged: (percent) =>
                  notifier.setMapLayerOpacity(layer.id, percent / 100),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolStatus(
    BuildContext context,
    EditorNotifier notifier,
    BorderToolAvailability availability, {
    required bool lineGeometry,
  }) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PokeMapBadge(
            label: availability.isEnabled
                ? 'Prêt à peindre'
                : 'Outil indisponible',
            variant: availability.isEnabled
                ? PokeMapBadgeVariant.success
                : PokeMapBadgeVariant.warning,
          ),
          if (availability.disabledReason case final reason?) ...[
            const SizedBox(height: 6),
            Text(
              reason,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              PokeMapButton(
                key: const ValueKey('border-inspector-paint-button'),
                onPressed: availability.isEnabled
                    ? () => notifier.selectTool(EditorToolType.borderPaint)
                    : null,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.paintbrush),
                child: Text(
                  lineGeometry ? 'Tracer la ligne' : 'Peindre le contour',
                ),
              ),
              PokeMapButton(
                key: const ValueKey('border-inspector-erase-button'),
                onPressed: availability.isEnabled
                    ? () => notifier.selectTool(EditorToolType.borderErase)
                    : null,
                size: PokeMapButtonSize.small,
                variant: PokeMapButtonVariant.secondary,
                leading: const Icon(CupertinoIcons.clear_circled),
                child: Text(
                  lineGeometry ? 'Créer une ouverture' : 'Effacer la bordure',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _previewActions(
    BuildContext context,
    EditorNotifier notifier,
    BorderPreviewState previewState,
    BorderPreviewTransaction preview, {
    required BorderLayer activeLayer,
    required BorderFeature? activeFeature,
  }) {
    final colors = context.pokeMapColors;
    final diagnostics = preview.result?.diagnosticReport.diagnostics ??
        const <BorderDiagnostic>[];
    final targetIsActive = preview.layerId == activeLayer.id &&
        preview.featureId == activeFeature?.id;
    final canApply = previewState.phase == BorderPreviewPhase.resolved &&
        preview.result?.canApply == true &&
        targetIsActive;
    final canCancel = previewState.phase != BorderPreviewPhase.applying;
    final canVary = preview.request != null &&
        (previewState.phase == BorderPreviewPhase.resolved ||
            previewState.phase == BorderPreviewPhase.invalid);
    final status = switch (previewState.phase) {
      BorderPreviewPhase.idle => ('Aucun aperçu', PokeMapBadgeVariant.neutral),
      BorderPreviewPhase.drawing => (
          'Geste en cours',
          PokeMapBadgeVariant.mapAccent
        ),
      BorderPreviewPhase.resolved => (
          'Aperçu prêt à appliquer',
          PokeMapBadgeVariant.success
        ),
      BorderPreviewPhase.invalid => (
          'Aperçu invalide',
          PokeMapBadgeVariant.error
        ),
      BorderPreviewPhase.applying => (
          'Application en cours',
          PokeMapBadgeVariant.mapAccent
        ),
    };
    final disabledReason = previewState.phase == BorderPreviewPhase.invalid
        ? 'Corrigez les diagnostics avant d’appliquer.'
        : !targetIsActive
            ? 'Resélectionnez la bordure ciblée pour appliquer cet aperçu.'
            : null;

    return PokeMapCard(
      key: const ValueKey('border-preview-actions'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PokeMapSectionHeader(
            title: 'Aperçu de bordure',
            description:
                'Les changements restent temporaires jusqu’à leur application.',
            trailing: PokeMapBadge(
              label: status.$1,
              variant: status.$2,
            ),
          ),
          if (diagnostics.isNotEmpty) ...[
            Text(
              '${diagnostics.length} diagnostic${diagnostics.length > 1 ? 's' : ''}',
              style: TextStyle(
                color: previewState.phase == BorderPreviewPhase.invalid
                    ? colors.error
                    : colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            for (final diagnostic in diagnostics)
              Text(
                localizeEditorBorderDiagnostic(diagnostic),
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 10,
                ),
              ),
          ],
          if (disabledReason != null) ...[
            const SizedBox(height: 6),
            Text(
              disabledReason,
              style: TextStyle(
                color: previewState.phase == BorderPreviewPhase.invalid
                    ? colors.error
                    : colors.warning,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 9),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              PokeMapButton(
                key: const ValueKey('border-preview-apply-button'),
                onPressed: canApply ? notifier.applyPendingBorderPreview : null,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.check_mark),
                child: const Text('Appliquer'),
              ),
              PokeMapButton(
                key: const ValueKey('border-preview-cancel-button'),
                onPressed: canCancel
                    ? ref.read(borderPreviewControllerProvider.notifier).cancel
                    : null,
                size: PokeMapButtonSize.small,
                variant: PokeMapButtonVariant.secondary,
                child: const Text('Annuler'),
              ),
              PokeMapButton(
                key: const ValueKey('border-preview-variation-button'),
                onPressed: canVary
                    ? ref
                        .read(borderPreviewControllerProvider.notifier)
                        .newVariation
                    : null,
                size: PokeMapButtonSize.small,
                variant: PokeMapButtonVariant.secondary,
                leading: const Icon(CupertinoIcons.shuffle),
                child: const Text('Nouvelle variation'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _lineSideControls(
    EditorNotifier notifier,
    BorderLayer layer,
    BorderFeature feature, {
    required BorderBlueprintTemplate template,
    required bool canToggleSide,
  }) {
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PokeMapSectionHeader(
            title: 'Orientation visuelle',
            description: template == BorderBlueprintTemplate.stoneChainLine
                ? 'Déplace les pierres de l\'autre côté du tracé sans retourner leurs pixels.'
                : 'Change le côté occupé par les rochers sans redessiner la ligne.',
            trailing: PokeMapBadge(
              label: switch (feature.lineSide) {
                BorderLineSide.primary => 'Côté principal',
                BorderLineSide.inverted => 'Côté inversé',
              },
              variant: PokeMapBadgeVariant.info,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: PokeMapButton(
              key: const ValueKey('border-invert-side-button'),
              onPressed: canToggleSide
                  ? () => notifier.previewBorderFeatureLineSideToggle(
                        layerId: layer.id,
                        featureId: feature.id,
                      )
                  : null,
              size: PokeMapButtonSize.small,
              variant: PokeMapButtonVariant.secondary,
              leading: const Icon(CupertinoIcons.arrow_left_right),
              child: const Text('Inverser le côté'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resizeDiagnosticsCard(
    BuildContext context,
    List<BorderDiagnostic> diagnostics,
  ) {
    final colors = context.pokeMapColors;
    final hasErrors = diagnostics.any(
      (diagnostic) => diagnostic.severity == BorderDiagnosticSeverity.error,
    );
    final hasWarnings = diagnostics.any(
      (diagnostic) => diagnostic.severity == BorderDiagnosticSeverity.warning,
    );
    final badgeVariant = hasErrors
        ? PokeMapBadgeVariant.error
        : hasWarnings
            ? PokeMapBadgeVariant.warning
            : PokeMapBadgeVariant.info;

    return PokeMapCard(
      key: const ValueKey('border-resize-diagnostics'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PokeMapSectionHeader(
            title: 'Redimensionnement de la carte',
            description:
                'Vérifiez les adaptations automatiques avant de poursuivre.',
            trailing: PokeMapBadge(
              label:
                  '${diagnostics.length} diagnostic${diagnostics.length > 1 ? 's' : ''}',
              variant: badgeVariant,
            ),
          ),
          for (var index = 0; index < diagnostics.length; index++) ...[
            if (index > 0) const SizedBox(height: 6),
            Row(
              key: ValueKey('border-resize-diagnostic-$index'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  switch (diagnostics[index].severity) {
                    BorderDiagnosticSeverity.error =>
                      CupertinoIcons.exclamationmark_circle,
                    BorderDiagnosticSeverity.warning =>
                      CupertinoIcons.exclamationmark_triangle,
                    BorderDiagnosticSeverity.info => CupertinoIcons.info_circle,
                  },
                  size: 14,
                  color: switch (diagnostics[index].severity) {
                    BorderDiagnosticSeverity.error => colors.error,
                    BorderDiagnosticSeverity.warning => colors.warning,
                    BorderDiagnosticSeverity.info => colors.info,
                  },
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    localizeEditorBorderDiagnostic(diagnostics[index]),
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _featureCard(
    BuildContext context,
    EditorNotifier notifier,
    BorderLayer layer,
    BorderFeature feature, {
    required bool selected,
    required ProjectManifest? manifest,
  }) {
    final record = manifest?.borderCatalog.recordById(feature.blueprintId);
    final revision = record?.latestPublished;
    final stoneMetrics = revision?.definition.template ==
                BorderBlueprintTemplate.stoneChainLine &&
            revision!.definition.defaults.depthRows == 2
        ? _twoTierStoneMetrics(feature.materialization)
        : null;
    return PokeMapCard(
      key: ValueKey('border-feature-${feature.id}'),
      selected: selected,
      onTap: () => notifier.selectBorderFeature(
        layerId: layer.id,
        featureId: feature.id,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          const Icon(CupertinoIcons.waveform_path, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  revision == null
                      ? 'Blueprint indisponible'
                      : revision.definition.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.pokeMapColors.textMuted,
                    fontSize: 10,
                  ),
                ),
                if (stoneMetrics case final metrics?) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Sommet : ${metrics.topCount} pierres',
                    key: const ValueKey('border-stone-top-count'),
                    style: TextStyle(
                      color: context.pokeMapColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Gap maximal du sommet : ${metrics.topMaximumGapPx} px',
                    key: const ValueKey('border-stone-top-gap'),
                    style: TextStyle(
                      color: context.pokeMapColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    'Face : ${metrics.faceCount} pierres',
                    key: const ValueKey('border-stone-face-count'),
                    style: TextStyle(
                      color: context.pokeMapColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Profondeur médiane : ${metrics.medianFaceDepthPx} px',
                    key: const ValueKey('border-stone-face-depth'),
                    style: TextStyle(
                      color: context.pokeMapColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    'Gap maximal de la face : ${metrics.faceMaximumGapPx} px',
                    key: const ValueKey('border-stone-face-gap'),
                    style: TextStyle(
                      color: context.pokeMapColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (selected)
            const PokeMapBadge(
              label: 'Active',
              variant: PokeMapBadgeVariant.mapAccent,
            ),
        ],
      ),
    );
  }

  Widget _featureActions(
    BuildContext context,
    EditorNotifier notifier,
    BorderLayer layer,
    BorderFeature feature,
  ) {
    final index = layer.content.features.indexOf(feature);
    return PokeMapCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Actions pour « ${feature.name} »',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.pokeMapColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          PokeMapIconButton(
            key: const ValueKey('border-rename-feature-button'),
            onPressed: () => _renameFeature(context, notifier, layer, feature),
            icon: const Icon(CupertinoIcons.pencil),
            tooltip: 'Renommer la bordure',
          ),
          PokeMapIconButton(
            key: const ValueKey('border-move-feature-up-button'),
            onPressed: index < layer.content.features.length - 1
                ? () => notifier.reorderBorderFeature(
                      layerId: layer.id,
                      featureId: feature.id,
                      newIndex: index + 1,
                    )
                : null,
            icon: const Icon(CupertinoIcons.arrow_up),
            tooltip: 'Monter la bordure',
          ),
          PokeMapIconButton(
            key: const ValueKey('border-move-feature-down-button'),
            onPressed: index > 0
                ? () => notifier.reorderBorderFeature(
                      layerId: layer.id,
                      featureId: feature.id,
                      newIndex: index - 1,
                    )
                : null,
            icon: const Icon(CupertinoIcons.arrow_down),
            tooltip: 'Descendre la bordure',
          ),
          PokeMapIconButton(
            key: const ValueKey('border-delete-feature-button'),
            onPressed: () => _deleteFeature(context, notifier, layer, feature),
            icon: const Icon(CupertinoIcons.trash),
            tooltip: 'Supprimer la bordure',
            variant: PokeMapIconButtonVariant.danger,
          ),
        ],
      ),
    );
  }

  Widget _materializationLifecycleActions(
    EditorNotifier notifier,
    BorderLayer layer,
    BorderFeature feature,
  ) {
    return PokeMapCard(
      key: const ValueKey('border-materialization-lifecycle'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PokeMapSectionHeader(
            title: 'Matérialisation',
            description:
                'Préparez une mise à jour sans remplacer le visuel enregistré.',
            trailing: PokeMapBadge(
              label: feature.materialization == null ? 'Absente' : 'Conservée',
              variant: feature.materialization == null
                  ? PokeMapBadgeVariant.warning
                  : PokeMapBadgeVariant.success,
            ),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              PokeMapButton(
                key: const ValueKey('border-update-preview-button'),
                onPressed: () => notifier.previewBorderFeatureUpdate(
                  layerId: layer.id,
                  featureId: feature.id,
                ),
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.arrow_clockwise),
                child: const Text('Update preview'),
              ),
              PokeMapButton(
                key: const ValueKey('border-keep-materialized-button'),
                onPressed: notifier.keepBorderFeatureMaterialized,
                size: PokeMapButtonSize.small,
                variant: PokeMapButtonVariant.secondary,
                leading: const Icon(CupertinoIcons.pin),
                child: const Text('Conserver la matérialisation'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _localCorrectionActions(
    EditorNotifier notifier, {
    required MapData map,
    required BorderLayer layer,
    required BorderFeature persistedFeature,
    required BorderFeature draftFeature,
    required List<BorderResolvedPlacement> placements,
    required BorderResolvedPlacement? selectedPlacement,
    required String? selectedSlotKey,
    required List<BorderPublishedPrimitive> replacementPrimitives,
    required String? replacementPrimitiveId,
    required _BorderMovePreset movePreset,
  }) {
    const controller = BorderFeatureAuthoringController();
    void preview(BorderFeature draft) {
      notifier.previewBorderFeatureDraft(
        layerId: layer.id,
        featureId: persistedFeature.id,
        draft: draft,
      );
    }

    return PokeMapCard(
      key: const ValueKey('border-local-corrections'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PokeMapSectionHeader(
            title: 'Corrections locales',
            description:
                'Sélectionnez un emplacement matérialisé. Chaque action reste dans l’aperçu jusqu’à Appliquer.',
            trailing: PokeMapBadge(
              label: '${draftFeature.overrides.length} correction(s)',
            ),
          ),
          if (placements.isEmpty ||
              selectedPlacement == null ||
              selectedSlotKey == null)
            const PokeMapEmptyState(
              title: 'Aucun emplacement matérialisé',
              description:
                  'Utilisez Update preview pour obtenir des emplacements corrigibles.',
              icon: Icon(CupertinoIcons.square),
            )
          else ...[
            PokeMapDropdownField<String>(
              key: const ValueKey('border-local-slot-picker'),
              label: 'Emplacement à corriger',
              value: selectedSlotKey,
              items: <PokeMapDropdownItem<String>>[
                for (var index = 0; index < placements.length; index += 1)
                  PokeMapDropdownItem<String>(
                    value: placements[index].slotKey,
                    label: 'Emplacement ${index + 1} · case '
                        '${placements[index].anchorCell.x + 1}, '
                        '${placements[index].anchorCell.y + 1}',
                  ),
              ],
              onChanged: (slotKey) => setState(() {
                _correctionSlotKey = slotKey;
                _replacementPrimitiveId = null;
              }),
            ),
            const SizedBox(height: 8),
            if (replacementPrimitives.isNotEmpty &&
                replacementPrimitiveId != null) ...[
              PokeMapDropdownField<String>(
                key: const ValueKey('border-local-replacement-picker'),
                label: 'Alternative compatible',
                value: replacementPrimitiveId,
                items: <PokeMapDropdownItem<String>>[
                  for (var index = 0;
                      index < replacementPrimitives.length;
                      index += 1)
                    PokeMapDropdownItem<String>(
                      value: replacementPrimitives[index].id,
                      label: 'Alternative ${index + 1} · '
                          '${_primitiveRoleLabel(replacementPrimitives[index].role)}',
                    ),
                ],
                onChanged: (primitiveId) => setState(() {
                  _replacementPrimitiveId = primitiveId;
                }),
              ),
              const SizedBox(height: 8),
            ],
            PokeMapDropdownField<String>(
              key: const ValueKey('border-local-move-picker'),
              label: 'Déplacement guidé',
              value: movePreset.id,
              items: <PokeMapDropdownItem<String>>[
                for (final preset in _borderMovePresets)
                  PokeMapDropdownItem<String>(
                    value: preset.id,
                    label: preset.label,
                  ),
              ],
              onChanged: (presetId) => setState(() {
                _movePresetId = presetId;
              }),
            ),
            const SizedBox(height: 8),
            PokeMapDropdownField<int>(
              key: const ValueKey('border-local-keep-out-size-picker'),
              label: 'Taille de la zone interdite',
              value: _keepOutRadiusCells,
              items: const <PokeMapDropdownItem<int>>[
                PokeMapDropdownItem<int>(value: 0, label: '1 case'),
                PokeMapDropdownItem<int>(value: 1, label: '3 × 3 cases'),
                PokeMapDropdownItem<int>(value: 2, label: '5 × 5 cases'),
              ],
              onChanged: (radius) => setState(() {
                _keepOutRadiusCells = radius;
              }),
            ),
            const SizedBox(height: 9),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                PokeMapButton(
                  key: const ValueKey('border-local-variation-button'),
                  onPressed: () => preview(
                    controller.previewLocalVariation(
                      feature: draftFeature,
                      slotKey: selectedSlotKey,
                    ),
                  ),
                  size: PokeMapButtonSize.small,
                  variant: PokeMapButtonVariant.secondary,
                  leading: const Icon(CupertinoIcons.shuffle),
                  child: const Text('Nouvelle variation locale'),
                ),
                PokeMapButton(
                  key: const ValueKey('border-local-replace-button'),
                  onPressed: replacementPrimitiveId == null
                      ? null
                      : () => preview(
                            controller.previewReplacement(
                              feature: draftFeature,
                              slotKey: selectedSlotKey,
                              primitiveId: replacementPrimitiveId,
                            ),
                          ),
                  size: PokeMapButtonSize.small,
                  variant: PokeMapButtonVariant.secondary,
                  leading: const Icon(CupertinoIcons.arrow_2_circlepath),
                  child: const Text('Remplacer'),
                ),
                PokeMapButton(
                  key: const ValueKey('border-local-move-button'),
                  onPressed: () => preview(
                    controller.previewMove(
                      feature: draftFeature,
                      slotKey: selectedSlotKey,
                      offset: BorderPixelOffset(
                        x: movePreset.x,
                        y: movePreset.y,
                      ),
                    ),
                  ),
                  size: PokeMapButtonSize.small,
                  variant: PokeMapButtonVariant.secondary,
                  leading: const Icon(CupertinoIcons.move),
                  child: const Text('Déplacer'),
                ),
                PokeMapButton(
                  key: const ValueKey('border-local-remove-button'),
                  onPressed: () => preview(
                    controller.previewRemoval(
                      feature: draftFeature,
                      slotKey: selectedSlotKey,
                    ),
                  ),
                  size: PokeMapButtonSize.small,
                  variant: PokeMapButtonVariant.secondary,
                  leading: const Icon(CupertinoIcons.clear),
                  child: const Text('Retirer'),
                ),
                PokeMapButton(
                  key: const ValueKey('border-local-lock-button'),
                  onPressed: () => preview(
                    controller.previewLock(
                      feature: draftFeature,
                      placement: selectedPlacement,
                    ),
                  ),
                  size: PokeMapButtonSize.small,
                  variant: PokeMapButtonVariant.secondary,
                  leading: const Icon(CupertinoIcons.lock),
                  child: const Text('Verrouiller'),
                ),
                PokeMapButton(
                  key: const ValueKey('border-local-keep-out-button'),
                  onPressed: () => preview(
                    controller.previewKeepOut(
                      feature: draftFeature,
                      placement: selectedPlacement,
                      mapSize: map.size,
                      radiusCells: _keepOutRadiusCells,
                    ),
                  ),
                  size: PokeMapButtonSize.small,
                  variant: PokeMapButtonVariant.secondary,
                  leading: const Icon(CupertinoIcons.nosign),
                  child: const Text('Zone interdite'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _blueprintPreview(
    BuildContext context,
    EditorNotifier notifier,
    BorderBlueprintChangePreview preview,
  ) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Avant : ${preview.before.blueprintName}',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Après : ${preview.after.blueprintName}',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          PokeMapCard(
            key: const ValueKey('border-blueprint-before-state'),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            child: Text(
              _featurePreviewStateLabel(preview.before),
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 10,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 5),
          PokeMapCard(
            key: const ValueKey('border-blueprint-after-state'),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            child: Text(
              _featurePreviewStateLabel(preview.after),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 10,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            preview.consequence,
            key: const ValueKey('border-blueprint-consequence'),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11,
              height: 1.3,
            ),
          ),
          if (preview.losses.isNotEmpty) ...[
            const SizedBox(height: 7),
            PokeMapCard(
              key: const ValueKey('border-relink-losses'),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              child: Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  for (final loss in preview.losses)
                    KeyedSubtree(
                      key: ValueKey('border-relink-loss-${loss.name}'),
                      child: PokeMapBadge(
                        label: _relinkLossLabel(loss),
                        variant: PokeMapBadgeVariant.warning,
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (preview.blockedReason case final reason?) ...[
            const SizedBox(height: 7),
            Text(
              reason,
              style: TextStyle(
                color: colors.warning,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 9),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              PokeMapButton(
                key: const ValueKey('border-confirm-blueprint-change'),
                onPressed: preview.canApply
                    ? () => _confirmBlueprintChange(
                          context,
                          notifier,
                          preview,
                        )
                    : null,
                size: PokeMapButtonSize.small,
                child: const Text('Confirmer le changement'),
              ),
              if (preview.canCreateNewFeature && preview.canReset)
                PokeMapButton(
                  key: const ValueKey(
                    'border-create-feature-from-blueprint-change',
                  ),
                  onPressed: () => _createFeatureFromBlueprintChange(
                    context,
                    notifier,
                    preview,
                  ),
                  size: PokeMapButtonSize.small,
                  variant: PokeMapButtonVariant.secondary,
                  child: const Text('Créer une bordure séparée'),
                ),
              if (preview.canReset)
                PokeMapButton(
                  key: const ValueKey('border-reset-blueprint-change'),
                  onPressed: () => _confirmBlueprintReset(
                    context,
                    notifier,
                    preview,
                  ),
                  size: PokeMapButtonSize.small,
                  variant: PokeMapButtonVariant.danger,
                  child: const Text('Remise à zéro…'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _createFeature(
    BuildContext context,
    EditorNotifier notifier,
    BorderLayer layer,
    String blueprintId,
  ) async {
    final controller = TextEditingController(
      text: 'Bordure ${layer.content.features.length + 1}',
    );
    final confirmed = await showPokeMapPromptDialog(
      context,
      title: 'Créer une bordure',
      controller: controller,
      placeholder: 'Nom de la bordure',
      cancelLabel: 'Annuler',
      confirmLabel: 'Créer',
    );
    final name = controller.text.trim();
    controller.dispose();
    if (!confirmed || name.isEmpty) return;
    notifier.createBorderFeature(
      layerId: layer.id,
      blueprintId: blueprintId,
      name: name,
    );
  }

  Future<void> _renameFeature(
    BuildContext context,
    EditorNotifier notifier,
    BorderLayer layer,
    BorderFeature feature,
  ) async {
    final controller = TextEditingController(text: feature.name);
    final confirmed = await showPokeMapPromptDialog(
      context,
      title: 'Renommer la bordure',
      controller: controller,
      placeholder: 'Nom de la bordure',
      cancelLabel: 'Annuler',
      confirmLabel: 'Renommer',
    );
    final name = controller.text.trim();
    controller.dispose();
    if (!confirmed || name.isEmpty) return;
    notifier.renameBorderFeature(
      layerId: layer.id,
      featureId: feature.id,
      name: name,
    );
  }

  Future<void> _deleteFeature(
    BuildContext context,
    EditorNotifier notifier,
    BorderLayer layer,
    BorderFeature feature,
  ) async {
    final confirmed = await showPokeMapConfirmationDialog(
      context,
      title: 'Supprimer la bordure',
      message: 'Supprimer « ${feature.name} » de ce calque ?',
      secondaryLabel: 'Annuler',
      primaryLabel: 'Supprimer',
      primaryIsDestructive: true,
    );
    if (!confirmed) return;
    notifier.deleteBorderFeature(
      layerId: layer.id,
      featureId: feature.id,
    );
  }

  Future<void> _confirmBlueprintChange(
    BuildContext context,
    EditorNotifier notifier,
    BorderBlueprintChangePreview preview,
  ) async {
    final confirmed = await showPokeMapConfirmationDialog(
      context,
      title: 'Confirmer le changement de blueprint',
      message:
          'Avant : ${preview.before.blueprintName}\nAprès : ${preview.after.blueprintName}\n\n${preview.consequence}',
      secondaryLabel: 'Annuler',
      primaryLabel: 'Changer le blueprint',
      icon: CupertinoIcons.arrow_2_circlepath,
    );
    if (!confirmed) return;
    notifier.changeBorderFeatureBlueprint(preview);
    _clearPendingBlueprintChange();
  }

  Future<void> _createFeatureFromBlueprintChange(
    BuildContext context,
    EditorNotifier notifier,
    BorderBlueprintChangePreview preview,
  ) async {
    final controller = TextEditingController(
      text: '${preview.before.feature.name} — ${preview.after.blueprintName}',
    );
    final confirmed = await showPokeMapPromptDialog(
      context,
      title: 'Créer une nouvelle bordure',
      controller: controller,
      placeholder: 'Nom de la nouvelle bordure',
      cancelLabel: 'Annuler',
      confirmLabel: 'Créer séparément',
    );
    final name = controller.text.trim();
    controller.dispose();
    if (!confirmed || name.isEmpty) return;
    notifier.createBorderFeatureFromBlueprintChange(
      preview: preview,
      name: name,
    );
    _clearPendingBlueprintChange();
  }

  Future<void> _confirmBlueprintReset(
    BuildContext context,
    EditorNotifier notifier,
    BorderBlueprintChangePreview preview,
  ) async {
    final confirmed = await showPokeMapConfirmationDialog(
      context,
      title: 'Remettre la bordure à zéro',
      message:
          'Avant : ${preview.before.blueprintName}\nAprès : ${preview.after.blueprintName}\n\n${preview.consequence}',
      secondaryLabel: 'Annuler',
      primaryLabel: 'Remettre à zéro',
      primaryIsDestructive: true,
      icon: CupertinoIcons.exclamationmark_triangle,
    );
    if (!confirmed) return;
    notifier.resetBorderFeatureBlueprint(preview);
    _clearPendingBlueprintChange();
  }

  void _clearPendingBlueprintChange() {
    if (!mounted) return;
    setState(() {
      _pendingBlueprintId = null;
      _pendingFeatureId = null;
      _pendingBeforeBlueprintId = null;
    });
  }
}

_TwoTierStoneMetrics _twoTierStoneMetrics(
  BorderMaterialization? materialization,
) {
  final placements =
      materialization?.placements ?? const <BorderResolvedPlacement>[];
  final top = <BorderResolvedPlacement>[
    for (final placement in placements)
      if (placement.stableOrderKey.passIndex == 0) placement,
  ];
  final face = <BorderResolvedPlacement>[
    for (final placement in placements)
      if (placement.stableOrderKey.passIndex == 1) placement,
  ];
  final faceDepths = <int>[
    for (final placement in face)
      placement.opaqueWorldBoundsPx.width > placement.opaqueWorldBoundsPx.height
          ? placement.opaqueWorldBoundsPx.width
          : placement.opaqueWorldBoundsPx.height,
  ]..sort();
  return _TwoTierStoneMetrics(
    topCount: top.length,
    faceCount: face.length,
    medianFaceDepthPx: _integerMedian(faceDepths),
    topMaximumGapPx: _maximumPlacementGap(top),
    faceMaximumGapPx: _maximumPlacementGap(face),
  );
}

int _integerMedian(List<int> sortedValues) {
  if (sortedValues.isEmpty) return 0;
  final middle = sortedValues.length ~/ 2;
  if (sortedValues.length.isOdd) return sortedValues[middle];
  return (sortedValues[middle - 1] + sortedValues[middle]) ~/ 2;
}

int _maximumPlacementGap(List<BorderResolvedPlacement> placements) {
  if (placements.length < 2) return 0;
  final ordered = List<BorderResolvedPlacement>.of(placements)
    ..sort(
        (left, right) => left.stableOrderKey.compareTo(right.stableOrderKey));
  var maximum = 0;
  for (var index = 1; index < ordered.length; index += 1) {
    final previous = ordered[index - 1].opaqueWorldBoundsPx;
    final current = ordered[index].opaqueWorldBoundsPx;
    final previousCenterX = previous.x * 2 + previous.width;
    final currentCenterX = current.x * 2 + current.width;
    final previousCenterY = previous.y * 2 + previous.height;
    final currentCenterY = current.y * 2 + current.height;
    final horizontal = (currentCenterX - previousCenterX).abs() >=
        (currentCenterY - previousCenterY).abs();
    final gap = horizontal
        ? _intervalGap(
            previous.x,
            previous.x + previous.width,
            current.x,
            current.x + current.width,
          )
        : _intervalGap(
            previous.y,
            previous.y + previous.height,
            current.y,
            current.y + current.height,
          );
    if (gap > maximum) maximum = gap;
  }
  return maximum;
}

int _intervalGap(int firstStart, int firstEnd, int secondStart, int secondEnd) {
  if (firstEnd < secondStart) return secondStart - firstEnd;
  if (secondEnd < firstStart) return firstStart - secondEnd;
  return 0;
}

final class _TwoTierStoneMetrics {
  const _TwoTierStoneMetrics({
    required this.topCount,
    required this.faceCount,
    required this.medianFaceDepthPx,
    required this.topMaximumGapPx,
    required this.faceMaximumGapPx,
  });

  final int topCount;
  final int faceCount;
  final int medianFaceDepthPx;
  final int topMaximumGapPx;
  final int faceMaximumGapPx;
}

List<BorderBlueprintRecord> _publishedBlueprints(ProjectManifest? manifest) {
  final records = <BorderBlueprintRecord>[
    for (final record
        in manifest?.borderCatalog.records ?? const <BorderBlueprintRecord>[])
      if (record.latestPublished != null && !record.isDeprecated) record,
  ];
  records.sort((a, b) {
    final aDefinition = a.latestPublished!.definition;
    final bDefinition = b.latestPublished!.definition;
    final byOrder = aDefinition.sortOrder.compareTo(bDefinition.sortOrder);
    if (byOrder != 0) return byOrder;
    final byName = aDefinition.name.compareTo(bDefinition.name);
    if (byName != 0) return byName;
    return a.id.compareTo(b.id);
  });
  return records;
}

List<PokeMapDropdownItem<String>> _blueprintItems(
  List<BorderBlueprintRecord> records,
) =>
    <PokeMapDropdownItem<String>>[
      for (final record in records)
        PokeMapDropdownItem<String>(
          value: record.id,
          label:
              '${record.latestPublished!.definition.name} · ${_templateLabel(record.latestPublished!.definition.template)}',
        ),
    ];

String _templateLabel(BorderBlueprintTemplate template) => switch (template) {
      BorderBlueprintTemplate.organicEdge => 'Contour organique',
      BorderBlueprintTemplate.masonryLine => 'Muret linéaire',
      BorderBlueprintTemplate.postAndRailLine => 'Clôture linéaire',
      BorderBlueprintTemplate.connectedLine => 'Ligne connectée',
      BorderBlueprintTemplate.stoneChainLine => 'Chaîne de pierres',
    };

String _featurePreviewStateLabel(BorderBlueprintFeaturePreviewState state) {
  final template = state.template == null
      ? 'Template indisponible'
      : _templateLabel(state.template!);
  final geometry = switch (state.feature.geometry) {
    BorderRegionGeometry region => 'Région ${region.width} × ${region.height}',
    BorderStrokeGeometry stroke => 'Ligne · ${stroke.strokes.length} tracé(s)',
  };
  final materialization =
      state.isMaterialized ? 'Matérialisée' : 'Non matérialisée';
  return '$template\n$geometry\n$materialization · '
      '${state.feature.overrides.length} correction(s) · '
      '${state.feature.keepOutRegions.length} zone(s) d’exclusion';
}

List<BorderPublishedPrimitive> _compatibleReplacementPrimitives(
  BorderBlueprintRevision? revision,
  BorderResolvedPlacement? placement,
) {
  if (revision == null || placement == null) {
    return const <BorderPublishedPrimitive>[];
  }
  final source = revision.definition.primitives
      .where((primitive) => primitive.id == placement.primitiveId)
      .firstOrNull;
  if (source == null) {
    return const <BorderPublishedPrimitive>[];
  }
  return <BorderPublishedPrimitive>[
    for (final primitive in revision.definition.primitives)
      if (primitive.role == source.role && primitive.id != source.id) primitive,
  ];
}

String _primitiveRoleLabel(BorderPrimitiveRole role) => switch (role) {
      BorderPrimitiveRole.structureLarge => 'Grande structure',
      BorderPrimitiveRole.structureMedium => 'Structure moyenne',
      BorderPrimitiveRole.filler => 'Remplissage',
      BorderPrimitiveRole.accent => 'Accent',
      BorderPrimitiveRole.post => 'Poteau',
      BorderPrimitiveRole.span => 'Traverse',
      BorderPrimitiveRole.surfacePatch => 'Surface',
      BorderPrimitiveRole.outerAccent => 'Accent extérieur',
      BorderPrimitiveRole.lineCap => 'Extrémité',
      BorderPrimitiveRole.lineStraight => 'Segment droit',
      BorderPrimitiveRole.lineCorner => 'Angle',
    };

String _relinkLossLabel(BorderRelinkLoss loss) => switch (loss) {
      BorderRelinkLoss.geometry => 'Géométrie',
      BorderRelinkLoss.parameters => 'Paramètres personnalisés',
      BorderRelinkLoss.overrides => 'Corrections locales',
      BorderRelinkLoss.keepOutRegions => 'Zones d’exclusion',
      BorderRelinkLoss.materialization => 'Matérialisation',
    };

final class _BorderMovePreset {
  const _BorderMovePreset({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
  });

  final String id;
  final String label;
  final int x;
  final int y;
}

const List<_BorderMovePreset> _borderMovePresets = <_BorderMovePreset>[
  _BorderMovePreset(id: 'right-1', label: '1 px vers la droite', x: 1, y: 0),
  _BorderMovePreset(id: 'left-1', label: '1 px vers la gauche', x: -1, y: 0),
  _BorderMovePreset(id: 'down-1', label: '1 px vers le bas', x: 0, y: 1),
  _BorderMovePreset(id: 'up-1', label: '1 px vers le haut', x: 0, y: -1),
  _BorderMovePreset(id: 'right-4', label: '4 px vers la droite', x: 4, y: 0),
  _BorderMovePreset(id: 'left-4', label: '4 px vers la gauche', x: -4, y: 0),
  _BorderMovePreset(id: 'down-4', label: '4 px vers le bas', x: 0, y: 4),
  _BorderMovePreset(id: 'up-4', label: '4 px vers le haut', x: 0, y: -4),
];
