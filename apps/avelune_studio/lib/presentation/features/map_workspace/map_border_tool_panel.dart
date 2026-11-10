import '../../../features/map_workspace/application/map_border_drawing_draft.dart';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/map_border_editing_commands.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_panel.dart';

import 'package:avelune_studio/features/resources/application/resource_catalog.dart';

import '../resources/resource_filter_button.dart';

import 'package:avelune_studio/features/map_workspace/application/map_border_review.dart';

import 'map_cliff_guide.dart';
import 'map_workspace_view_state.dart';

class MapBorderToolPanel extends StatelessWidget {
  const MapBorderToolPanel({
    super.key,
    required this.document,
    required this.project,
    required this.view,
    required this.onChanged,
    required this.onCreateModel,
    this.modelsLoaded = true,
    this.modelsLoading = false,
    this.piecesLoading = false,
    this.onLoadModels,
  });

  final bool modelsLoaded, modelsLoading, piecesLoading;
  final Future<void> Function()? onLoadModels;
  final EditableMapDocument document;
  final ProjectManifest project;
  final MapWorkspaceViewState view;
  final VoidCallback onChanged;
  final VoidCallback onCreateModel;

  Widget _existingExteriorBorders() {
    final controller = document.exteriorDecoration!;
    final features =
        controller.current?.borders ?? const <ExteriorDecorationBorder>[];
    if (features.isEmpty) return const SizedBox.shrink();
    final selected =
        features
            .where((v) => v.id == view.borderFeature?.featureId)
            .firstOrNull ??
        features.first;
    return StudioPanel(
      compact: true,
      title: 'Tracés du décor extérieur',
      children: [
        StudioSelect(
          label: 'Tracé',
          value: selected.id,
          options: {
            for (final feature in features) feature.id: feature.feature.name,
          },
          onChanged: (id) {
            final feature = features.firstWhere((v) => v.id == id);
            view.borderFeature = (
              layerId: feature.layerId,
              featureId: feature.id,
            );
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StudioButton(
              label: 'Régénérer le tracé',
              secondary: true,
              onPressed: controller.saving
                  ? null
                  : () {
                      try {
                        controller.regenerateBorder(selected.id, project);
                        document.error = null;
                      } catch (error) {
                        document.error = '$error';
                      }
                      onChanged();
                    },
            ),
            StudioButton(
              label: 'Supprimer le tracé',
              secondary: true,
              onPressed: controller.saving
                  ? null
                  : () {
                      controller.removeBorder(selected.id);
                      view.borderFeature = null;
                      onChanged();
                    },
            ),
          ],
        ),
      ],
    );
  }

  Widget _existingBorders(BuildContext context) {
    if (document.exteriorDecoration?.editingExterior == true) {
      return _existingExteriorBorders();
    }
    final map = document.current;
    final commands = MapBorderEditingCommands(document, project);
    final features = commands.visibleFeatures;
    if (features.isEmpty) {
      return view.borderEditingMode == BorderStrokeEditingMode.erase
          ? const StudioNotice(
              'Aucun tracé visible. Affichez un calque Bordures ou revenez au mode Tracer.',
            )
          : const SizedBox.shrink();
    }
    final explicitSelection = features
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
    final missing = selected.feature.materialization == null;
    final status = commands.regenerationStatus(
      layerId: selected.layer.id,
      featureId: selected.feature.id,
    );
    final stale = status.stale;
    final diagnostic = status.diagnostic;
    final preview = view.borderPreview;
    final ready =
        !selectionRequired &&
        preview != null &&
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
                  value: selectionRequired
                      ? null
                      : (
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
                          view.selectBorderFeature(id);
                          onChanged();
                        },
                ),
              ),
            ),
            StudioButton(
              key: const ValueKey('border-stroke-erase-mode'),
              label: 'Gommer une partie',
              icon: Icons.auto_fix_normal,
              secondary:
                  view.borderEditingMode != BorderStrokeEditingMode.erase,
              onPressed: view.borderDraft != null || selectionRequired
                  ? null
                  : () {
                      view.prepareBorderErase((
                        layerId: selected.layer.id,
                        featureId: selected.feature.id,
                      ));
                      onChanged();
                    },
            ),
            if (map.spatialScene == null)
              StudioButton(
                key: const ValueKey('border-layer-foreground-button'),
                label: selected.layer.renderInForeground
                    ? 'Calque au premier plan'
                    : 'Calque à l’arrière-plan',
                icon: Icons.layers_outlined,
                secondary: !selected.layer.renderInForeground,
                onPressed: view.borderDraft != null || selectionRequired
                    ? null
                    : () => action(() {
                        MapBorderEditingCommands(
                          document,
                          project,
                        ).setForeground(
                          layerId: selected.layer.id,
                          renderInForeground:
                              !selected.layer.renderInForeground,
                        );
                        view.borderPreview = null;
                      }),
              ),
            StudioButton(
              key: const ValueKey('border-regeneration-preview'),
              label: 'Préparer la régénération',
              icon: Icons.refresh,
              secondary: true,
              onPressed:
                  view.borderDraft != null ||
                      selectionRequired ||
                      diagnostic != null
                  ? null
                  : () => action(() {
                      view.borderPreview = commands.prepareExisting(
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
                  commands.applyRegeneration(preview);
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
        if (map.spatialScene != null && !selectionRequired)
          _BorderSpatialOffsetEditor(
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
          StudioNotice(
            selectionRequired
                ? 'Le tracé sélectionné n’est plus visible. Choisissez un tracé visible pour continuer à gommer.'
                : 'Glissez sur le tracé sélectionné pour gommer une partie. Relâchez pour appliquer ; Échap annule. Les autres tracés restent inchangés.',
          ),
        ],
        if (!selectionRequired &&
            (stale || missing || diagnostic != null || ready)) ...[
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
    final choices = mapBorderProfileChoices(project);
    final eligible = choices.ready;
    final drafts = choices.drafts;
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
    final compatible = filterResourceCatalog(
      project,
      resourceCatalog(
        project,
      ).where((item) => item.border != null && eligibleIds.contains(item.id)),
      ResourceCatalogFilterState(
        showComponents: view.resourceFilters.showComponents,
      ),
      activeMapId: document.current.id,
      forMapPicker: true,
    );
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
    final definition = eligible
        .where((item) => item.id == view.borderBlueprintId)
        .firstOrNull
        ?.latestPublished
        ?.definition;
    final straightOnly = definition?.straightOnly == true;
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
              : view.borderMovingAngle != null
              ? 'Cliquez sur la carte pour placer l’angle ${view.borderMovingAngle! + 1}.'
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
        SizedBox(
          width: 170,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              key: const ValueKey('border-move-angle'),
              isExpanded: true,
              value: view.borderMovingAngle,
              hint: const Text('Déplacer un angle'),
              items: [
                for (var index = 0; index < draft.anchors.length; index++)
                  DropdownMenuItem(
                    value: index,
                    child: Text(
                      'Angle ${index + 1} · ${draft.anchors[index].x}, ${draft.anchors[index].y}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (index) {
                view.borderMovingAngle = index;
                onChanged();
              },
            ),
          ),
        ),
        StudioButton(
          label: 'Retirer le dernier angle',
          icon: Icons.undo,
          secondary: true,
          onPressed: () {
            view.removeLastBorderAngle(document);
            onChanged();
          },
        ),
        StudioButton(
          label: 'Annuler le tracé',
          icon: Icons.close,
          secondary: true,
          onPressed: () {
            if (spatial) view.clearBorderDraftFailure(document);
            view.borderMovingAngle = null;
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
                    final exterior = document.exteriorDecoration;
                    if (exterior?.editingExterior == true &&
                        draft.logicalOrigin != null) {
                      final origin = draft.logicalOrigin!;
                      exterior!.drawBorder(
                        manifest: project,
                        blueprintId: draft.blueprintId,
                        logicalPoints: [
                          for (final point in draft.anchors)
                            GridPos(
                              x: point.x + origin.x,
                              y: point.y + origin.y,
                            ),
                        ],
                        seed: draft.seed,
                        borderId: draft.featureId,
                        closed: draft.closed,
                      );
                    } else {
                      MapBorderEditingCommands(document, project).finish(draft);
                    }
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
              StudioButton(
                key: const ValueKey('border-stroke-draw-mode'),
                label: 'Tracer une bordure',
                icon: Icons.edit,
                secondary: true,
                onPressed: () {
                  view.borderEditingMode = BorderStrokeEditingMode.draw;
                  view.borderPreview = null;
                  onChanged();
                },
              ),
            models.isEmpty
                ? Wrap(
                    key: const ValueKey('border-empty-state'),
                    spacing: 12,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: eligible.isEmpty && !modelsLoaded
                        ? modelsLoading
                              ? const [
                                  SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  Text(
                                    'Chargement des modèles de bordure du projet… Leurs pièces se chargent quand vous en choisissez un.',
                                  ),
                                ]
                              : [
                                  const Text(
                                    'Les modèles de bordure du projet ne sont pas encore chargés pour cette carte.',
                                  ),
                                  StudioButton(
                                    label: 'Charger les modèles de bordure',
                                    icon: Icons.download_outlined,
                                    onPressed: onLoadModels,
                                  ),
                                ]
                        : eligible.isEmpty || compatible.isEmpty
                        ? [
                            if (eligible.isNotEmpty)
                              const Text(
                                'Aucun modèle de bordure publié n’est prêt pour cette carte. Préparez-en un dans l’atelier Bordures.',
                              )
                            else
                              Text(
                                'Aucun modèle de bordure linéaire n’est publié dans ce projet.${drafts.isEmpty ? ' Créez-en un dans l’atelier Bordures.' : ' ${drafts.length} ${drafts.length > 1 ? 'modèles en brouillon attendent' : 'modèle en brouillon attend'} d’être publié${drafts.length > 1 ? 's' : ''} dans l’atelier Bordures.'}',
                              ),
                            StudioButton(
                              label: 'Créer un modèle',
                              icon: Icons.add,
                              onPressed: onCreateModel,
                            ),
                          ]
                        : [
                            contextFilters(),
                            const Text(
                              'Aucune bordure ne correspond aux filtres de la palette.',
                            ),
                            StudioButton(
                              label: 'Effacer les filtres',
                              icon: Icons.filter_alt_off_outlined,
                              secondary: true,
                              onPressed: () {
                                view.resourceFilters.reset();
                                onChanged();
                              },
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
            if (piecesLoading && selected != null)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: StudioNotice(
                  'Préparation des pièces de cette bordure… Le tracé sera possible dans un instant.',
                  key: ValueKey('border-pieces-loading'),
                ),
              ),
            if (spatial &&
                models.isNotEmpty &&
                view.borderEditingMode != BorderStrokeEditingMode.erase)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: MapCliffGuide(
                  document: document,
                  view: view,
                  definition: definition,
                  draft: draft,
                  onChanged: onChanged,
                ),
              ),
            if (models.isNotEmpty && (spatial || definition != null))
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _BorderProfileReview(
                  compact: spatial,
                  pieces: definition == null
                      ? 'Choisissez un modèle pour voir ses segments, coins et extrémités.'
                      : mapBorderProfilePieces(definition),
                  drafts: drafts.length,
                  review:
                      definition == null ||
                          draft == null ||
                          draft.anchors.length < 2
                      ? null
                      : mapBorderDraftReview(draft, definition),
                ),
              ),
            _existingBorders(context),
          ],
        ),
      ),
    );
  }
}

class _BorderProfileReview extends StatelessWidget {
  const _BorderProfileReview({
    required this.pieces,
    required this.drafts,
    required this.review,
    required this.compact,
  });

  final String pieces;
  final int drafts;
  final MapBorderReview? review;
  final bool compact;

  String get _draftsNote =>
      '$drafts ${drafts > 1 ? 'modèles en brouillon ne sont' : 'modèle en brouillon n’est'} pas proposé${drafts > 1 ? 's' : ''} : publiez-le${drafts > 1 ? 's' : ''} dans l’atelier Bordures.';

  @override
  Widget build(BuildContext context) {
    final small = Theme.of(context).textTheme.bodySmall;
    if (compact) {
      final review = this.review;
      final warning = review?.warnings.firstOrNull;
      final line = warning ?? review?.facts.first ?? pieces;
      final details = [
        ...?review?.facts,
        if (review == null) pieces,
        ...?review?.warnings,
        if (drafts > 0) _draftsNote,
      ].join('\n');
      return Tooltip(
        key: const ValueKey('border-profile-review'),
        message: details,
        child: Row(
          children: [
            Icon(
              warning == null ? Icons.info_outline : Icons.warning_amber,
              size: 14,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                drafts > 0 && warning == null ? '$line · $_draftsNote' : line,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: small,
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      key: const ValueKey('border-profile-review'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (review == null) Text(pieces, style: small),
        if (review != null)
          for (final fact in review!.facts) Text(fact, style: small),
        if (drafts > 0) Text(_draftsNote, style: small),
        if (review != null)
          for (final warning in review!.warnings) ...[
            const SizedBox(height: 4),
            StudioNotice(warning),
          ],
      ],
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
  late final draft = MapBorderOffsetDraft(widget.feature.spatialOffsetWorld);

  @override
  Widget build(BuildContext context) {
    final valid = draft.value != null;
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
                  value: draft.inputs[axis]!,
                  label: label,
                  enabled: widget.enabled,
                  errorText: draft.number(axis) == null
                      ? 'Nombre fini requis'
                      : null,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  onChanged: (value) =>
                      setState(() => draft.inputs[axis] = value),
                ),
              ),
            StudioButton(
              key: const ValueKey('border-spatial-offset-save'),
              label: 'Enregistrer le décalage',
              icon: Icons.check,
              onPressed: widget.enabled && valid
                  ? () => widget.onSave(draft.value)
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
