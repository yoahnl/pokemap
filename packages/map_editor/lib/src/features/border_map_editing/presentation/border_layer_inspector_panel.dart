import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../editor/state/editor_notifier.dart';
import '../../editor/tools/editor_tool.dart';
import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';
import '../../../ui/shared/cupertino_editor_widgets.dart';
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

  @override
  Widget build(BuildContext context) {
    final editor = ref.watch(editorNotifierProvider);
    final selection = ref.watch(activeBorderFeatureControllerProvider);
    final previewState = ref.watch(borderPreviewControllerProvider);
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

    final activeFeature = selection.activeLayerId == activeLayer.id
        ? activeLayer.content.featureById(selection.activeFeatureId ?? '')
        : null;
    final createBlueprintId =
        publishedBlueprints.any((record) => record.id == _createBlueprintId)
            ? _createBlueprintId!
            : publishedBlueprints.firstOrNull?.id;
    final pendingBlueprintId = activeFeature != null &&
            _pendingFeatureId == activeFeature.id &&
            _pendingBeforeBlueprintId == activeFeature.blueprintId
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
          )
        : null;
    final toolAvailability = assessBorderToolAvailability(
      manifest: editor.project,
      map: map,
      activeLayerId: activeLayer.id,
      activeFeatureId: activeFeature?.id,
    );

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
              if (publishedBlueprints.isNotEmpty) ...[
                const SizedBox(height: 14),
                const PokeMapSectionHeader(
                  title: 'Changer de blueprint',
                  description:
                      'Le sélecteur prépare un aperçu structurel avant/après. La résolution visuelle sera recalculée séparément.',
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
    final confirmed = await showMacosEditorPromptSheet(
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
    final confirmed = await showMacosEditorPromptSheet(
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
    final confirmed = await showMacosEditorTwoChoiceAlert(
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
    final confirmed = await showMacosEditorTwoChoiceAlert(
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
    final confirmed = await showMacosEditorPromptSheet(
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
    final confirmed = await showMacosEditorTwoChoiceAlert(
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
