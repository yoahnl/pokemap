import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/map_border_editing_commands.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../resources/resource_catalog.dart';
import '../resources/resource_filter_button.dart';
import 'map_workspace_view_state.dart';

class MapBorderToolPanel extends StatelessWidget {
  const MapBorderToolPanel({
    super.key,
    required this.document,
    required this.project,
    required this.view,
    required this.onChanged,
    required this.onCreateModel,
  });

  final EditableMapDocument document;
  final ProjectManifest project;
  final MapWorkspaceViewState view;
  final VoidCallback onChanged;
  final VoidCallback onCreateModel;

  Widget _existingBorders(BuildContext context) {
    final map = document.current;
    final features = [
      for (final layer in map.layers.whereType<BorderLayer>())
        for (final feature in layer.content.features)
          if (layer.isVisible && feature.geometry is BorderStrokeGeometry)
            (layer: layer, feature: feature),
    ];
    if (features.isEmpty) {
      return view.borderEditingMode == BorderStrokeEditingMode.erase
          ? const StudioNotice('Aucun tracé visible. Affichez un calque Bordures ou revenez au mode Tracer.')
          : const SizedBox.shrink();
    }
    final explicitSelection =
        features
            .where(
              (item) =>
                  item.feature.id == view.borderFeature?.featureId &&
                  item.layer.id == view.borderFeature?.layerId,
            )
            .firstOrNull;
    final selectionRequired =
        view.borderEditingMode == BorderStrokeEditingMode.erase &&
        explicitSelection == null;
    final selected = explicitSelection ?? features.first;
    var stale = false;
    final missing = selected.feature.materialization == null;
    String? diagnostic;
    try {
      if (map.spatialScene != null) {
      final report = diagnoseSpatialBorderFeature(
        manifest: project,
        map: map,
        layerId: selected.layer.id,
        featureId: selected.feature.id,
      );
      stale = report.diagnostics.any(
        (issue) => issue.code == 'border.spatial.materialization_stale',
      );
      if (report.hasErrors) {
        diagnostic = 'Cette bordure doit être corrigée avant régénération.';
      }
      } else {
        final proposed = MapBorderEditingCommands(document, project)
            .previewExisting(
              layerId: selected.layer.id,
              featureId: selected.feature.id,
            );
        stale = proposed != map;
      }
    } on Object {
      diagnostic =
          'La bordure ne peut pas être préparée. Vérifiez ses pièces sources.';
    }
    final preview = view.borderPreview;
    final ready =
        !selectionRequired && preview != null &&
        preview.validFor(map, project) &&
        preview.layerId == selected.layer.id &&
        preview.featureId == selected.feature.id;
    void action(VoidCallback operation) {
      try {
        operation();
        document.error = null;
      } on Object catch (error) {
        document.error = error.toString();
      }
      onChanged();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 7),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 210,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<({String layerId, String featureId})>(
                  key: const ValueKey('border-feature-picker'),
                  isExpanded: true,
                  value: selectionRequired ? null : (
                    layerId: selected.layer.id,
                    featureId: selected.feature.id,
                  ),
                  hint: const Text('Choisir un tracé visible'),
                  items: [
                    for (final item in features)
                      DropdownMenuItem(
                        value: (
                          layerId: item.layer.id,
                          featureId: item.feature.id,
                        ),
                        child: Text(
                          '${item.feature.name} · ${item.layer.name}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: view.borderDraft != null
                      ? null
                      : (id) {
                          view.borderFeature = id;
                          view.borderPreview = null;
                          onChanged();
                        },
                ),
              ),
            ),
            StudioButton(
              key: const ValueKey('border-stroke-erase-mode'),
              label: 'Gommer une partie',
              icon: Icons.auto_fix_normal,
              secondary: view.borderEditingMode != BorderStrokeEditingMode.erase,
              onPressed: view.borderDraft != null || selectionRequired ? null : () {
                view.borderEditingMode = BorderStrokeEditingMode.erase;
                view.borderFeature = (layerId: selected.layer.id, featureId: selected.feature.id);
                view.borderPreview = null;
                view.tool = StudioMapTool.border;
                onChanged();
              },
            ),
            if (map.spatialScene == null)
              StudioButton(
                key: const ValueKey('border-layer-foreground-button'),
                label: selected.layer.renderInForeground ? 'Calque au premier plan' : 'Calque à l’arrière-plan',
                icon: Icons.layers_outlined,
                secondary: !selected.layer.renderInForeground,
                onPressed: view.borderDraft != null || selectionRequired ? null : () => action(() {
                  MapBorderEditingCommands(document, project).setForeground(
                      layerId: selected.layer.id,
                      renderInForeground: !selected.layer.renderInForeground);
                  view.borderPreview = null;
                }),
              ),
            StudioButton(
              key: const ValueKey('border-regeneration-preview'),
              label: 'Préparer la régénération',
              icon: Icons.refresh,
              secondary: true,
              onPressed: view.borderDraft != null || selectionRequired || diagnostic != null
                  ? null
                  : () => action(() {
                      final result = MapBorderEditingCommands(document, project)
                          .previewExisting(
                            layerId: selected.layer.id,
                            featureId: selected.feature.id,
                          );
                      view.borderPreview = MapBorderRegenerationPreview(
                        source: map,
                        project: project,
                        result: result,
                        layerId: selected.layer.id,
                        featureId: selected.feature.id,
                      );
                    }),
            ),
            if (ready) ...[
              StudioButton(
                key: const ValueKey('border-regeneration-apply'),
                label: 'Appliquer',
                icon: Icons.check,
                onPressed: () => action(() {
                  MapBorderEditingCommands(document, project).applyExisting(
                    preview.result,
                    source: preview.source,
                    sourceProject: preview.project,
                  );
                  view.borderPreview = null;
                }),
              ),
              StudioButton(
                label: 'Annuler l’aperçu',
                icon: Icons.close,
                secondary: true,
                onPressed: () {
                  view.borderPreview = null;
                  onChanged();
                },
              ),
            ],
            StudioButton(
              key: const ValueKey('border-feature-delete'),
              label: 'Supprimer le tracé',
              icon: Icons.delete_outline,
              secondary: true,
              onPressed: view.borderDraft != null || selectionRequired
                  ? null
                  : () => action(() {
                      MapBorderEditingCommands(document, project).delete(
                        layerId: selected.layer.id,
                        featureId: selected.feature.id,
                      );
                      view.borderPreview = null;
                      view.borderFeature = null;
                    }),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (map.spatialScene != null && !selectionRequired) _BorderSpatialOffsetEditor(
          key: ObjectKey(selected.feature),
          feature: selected.feature,
          enabled: view.borderDraft == null,
          onSave: (offset) => action(() {
            MapBorderEditingCommands(document, project).setSpatialOffset(
              layerId: selected.layer.id,
              featureId: selected.feature.id,
              offset: offset,
              source: selected.feature,
            );
            view.borderPreview = null;
          }),
        ),
        if (view.borderEditingMode == BorderStrokeEditingMode.erase) ...[
          const SizedBox(height: 6),
          StudioNotice(selectionRequired
              ? 'Le tracé sélectionné n’est plus visible. Choisissez un tracé visible pour continuer à gommer.'
              : 'Glissez sur le tracé sélectionné pour gommer une partie. Relâchez pour appliquer ; Échap annule. Les autres tracés restent inchangés.'),
        ],
        if (!selectionRequired && (stale || missing || diagnostic != null || ready)) ...[
          const SizedBox(height: 6),
          StudioNotice(
            diagnostic ??
                (ready
                    ? 'Aperçu prêt. Appliquez pour remplacer les pièces de ce tracé.'
                    : missing
                    ? 'Ce tracé n’a pas encore ses pièces. Préparez puis appliquez la génération.'
                    : 'Le tracé ou une pièce source a changé. Préparez puis appliquez la régénération pour actualiser ses pièces.'),
            isError: diagnostic != null,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final eligible = MapBorderEditingCommands.publishedLines(project);
    final eligibleIds = eligible.map((model) => model.id).toSet();
    final models = filterResourceCatalog(
      project,
      resourceCatalog(
        project,
      ).where((item) => item.border != null && eligibleIds.contains(item.id)),
      view.resourceFilters,
      activeMapId: document.current.id,
      forMapPicker: true,
    ).map((item) => item.border!).toList();
    Widget contextFilters() => ResourceFilterButton(
      filters: view.resourceFilters,
      activeMapName: document.current.name,
      forMapPicker: true,
      onChanged: onChanged,
      countResults: (draft, _) => filterResourceCatalog(
        project,
        resourceCatalog(
          project,
        ).where((item) => item.border != null && eligibleIds.contains(item.id)),
        draft,
        activeMapId: document.current.id,
        forMapPicker: true,
      ).length,
    );
    final selected = models.any((item) => item.id == view.borderBlueprintId)
        ? view.borderBlueprintId
        : null;
    final straightOnly =
        eligible
            .where((item) => item.id == view.borderBlueprintId)
            .firstOrNull
            ?.latestPublished
            ?.definition
            .straightOnly ==
        true;
    final draft = view.borderDraft?.mapId == document.current.id
        ? view.borderDraft
        : null;
    final spatial = document.current.spatialScene != null;
    final controls = <Widget>[
      SizedBox(
        width: 210,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            key: const ValueKey('border-model-picker'),
            isExpanded: true,
            value: selected,
            hint: const Text('Choisir une bordure'),
            items: [
              for (final model in models)
                DropdownMenuItem(
                  value: model.id,
                  child: Text(
                    model.latestPublished!.definition.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: draft != null
                ? null
                : (id) {
                    view.borderBlueprintId = id;
                    onChanged();
                  },
          ),
        ),
      ),
      contextFilters(),
      if (!spatial || draft == null) ...[
        Text(
          view.borderEditingMode == BorderStrokeEditingMode.erase
              ? 'Gomme locale · choisissez un tracé existant ci-dessous.'
              : straightOnly
              ? 'Tracés droits uniquement · Entrée pour terminer.'
              : draft == null
              ? 'Cliquez pour commencer, puis cliquez pour placer les angles.'
              : '${draft.anchors.length} points · ${draft.alignment == BorderStrokeAlignment.gridEdges ? 'lignes de grille' : 'cases'} · clic = angle · départ = fermer · Entrée = terminer.',
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: spatial ? 1 : null,
        ),
        StudioButton(
          label: 'Créer un autre modèle',
          icon: Icons.add,
          secondary: true,
          onPressed: onCreateModel,
        ),
      ],
      if (draft != null) ...[
        StudioButton(
          label: 'Retirer le dernier angle',
          icon: Icons.undo,
          secondary: true,
          onPressed: () {
            if (spatial) view.clearBorderDraftFailure(document);
            view.borderDraft = draft.removeLastAngle();
            onChanged();
          },
        ),
        StudioButton(
          label: 'Annuler le tracé',
          icon: Icons.close,
          secondary: true,
          onPressed: () {
            if (spatial) view.clearBorderDraftFailure(document);
            view.borderDraft = null;
            onChanged();
          },
        ),
        StudioButton(
          label: 'Terminer le tracé',
          icon: Icons.check,
          onPressed: draft.canFinish
              ? () {
                  try {
                    MapBorderEditingCommands(
                      document,
                      project,
                    ).finish(draft);
                    if (spatial) view.clearBorderDraftFailure(document);
                    view.borderDraft = null;
                  } catch (error) {
                    if (spatial) {
                      view.failBorderDraft(draft, document, error);
                    } else {
                      document.error = error.toString();
                    }
                  }
                  onChanged();
                }
              : null,
        ),
      ],
    ];
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (view.borderEditingMode == BorderStrokeEditingMode.erase)
              StudioButton(key: const ValueKey('border-stroke-draw-mode'),
                label: 'Tracer une bordure', icon: Icons.edit,
                secondary: true, onPressed: () {
                  view.borderEditingMode = BorderStrokeEditingMode.draw;
                  view.borderPreview = null;
                  onChanged();
                }),
            models.isEmpty
                ? Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      contextFilters(),
                      Text(eligible.isEmpty
                        ? 'Aucun modèle de bordure linéaire n’est publié dans ce projet.'
                        : 'Aucune bordure ne correspond aux filtres.'),
                      StudioButton(
                        label: 'Créer un modèle',
                        icon: Icons.add,
                        onPressed: onCreateModel,
                      ),
                    ],
                  )
                : spatial
                ? Row(
                    children: [
                      controls.first,
                      const SizedBox(width: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var i = 1; i < controls.length; i++) ...[
                                if (i > 1) const SizedBox(width: 10),
                                controls[i],
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: controls,
                  ),
            _existingBorders(context),
          ],
        ),
      ),
    );
  }
}

class _BorderSpatialOffsetEditor extends StatefulWidget {
  const _BorderSpatialOffsetEditor({
    super.key,
    required this.feature,
    required this.enabled,
    required this.onSave,
  });

  final BorderFeature feature;
  final bool enabled;
  final ValueChanged<Model3dVector3?> onSave;

  @override
  State<_BorderSpatialOffsetEditor> createState() =>
      _BorderSpatialOffsetEditorState();
}

class _BorderSpatialOffsetEditorState
    extends State<_BorderSpatialOffsetEditor> {
  late final inputs = {
    'x': (widget.feature.spatialOffsetWorld?.x ?? 0).toString(),
    'y': (widget.feature.spatialOffsetWorld?.y ?? 0).toString(),
    'z': (widget.feature.spatialOffsetWorld?.z ?? 0).toString(),
  };

  double? number(String axis) {
    final value = double.tryParse(inputs[axis]!.trim().replaceAll(',', '.'));
    return value?.isFinite == true ? value : null;
  }

  @override
  Widget build(BuildContext context) {
    final valid = inputs.keys.every((axis) => number(axis) != null);
    return StudioPanel(
      compact: true,
      children: [
        const Text('Altitude et décalage 3D'),
        const Text(
          'En unités de carte, selon les axes du monde. Enregistrez puis régénérez le tracé pour déplacer ses pièces.',
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final (axis, label) in [
              ('x', 'X · horizontal'),
              ('y', 'Y · altitude'),
              ('z', 'Z · profondeur'),
            ])
              SizedBox(
                width: 150,
                child: StudioDraftField(
                  key: ValueKey('border-spatial-offset-$axis'),
                  value: inputs[axis]!,
                  label: label,
                  enabled: widget.enabled,
                  errorText: number(axis) == null ? 'Nombre fini requis' : null,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  onChanged: (value) => setState(() => inputs[axis] = value),
                ),
              ),
            StudioButton(
              key: const ValueKey('border-spatial-offset-save'),
              label: 'Enregistrer le décalage',
              icon: Icons.check,
              onPressed: widget.enabled && valid
                  ? () => widget.onSave(
                      Model3dVector3(
                        x: number('x')!,
                        y: number('y')!,
                        z: number('z')!,
                      ),
                    )
                  : null,
            ),
            StudioButton(
              key: const ValueKey('border-spatial-offset-clear'),
              label: 'Remettre à zéro',
              icon: Icons.restart_alt,
              secondary: true,
              onPressed:
                  widget.enabled && widget.feature.spatialOffsetWorld != null
                  ? () => widget.onSave(null)
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}
