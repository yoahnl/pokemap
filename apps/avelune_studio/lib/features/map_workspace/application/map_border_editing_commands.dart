import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring_editing.dart' show BorderActions;

import 'editable_map_document.dart';
import 'map_border_drawing_draft.dart';

final class MapBorderRegenerationPreview {
  const MapBorderRegenerationPreview({
    required this.source,
    required this.project,
    required this.result,
    required this.layerId,
    required this.featureId,
  });
  final MapData source;
  final ProjectManifest project;
  final MapData result;
  final String layerId;
  final String featureId;
  bool validFor(MapData map, ProjectManifest manifest) =>
      identical(source, map) && identical(project, manifest);
}

final class MapBorderEditingCommands {
  MapBorderEditingCommands(this.document, this.project);

  final EditableMapDocument document;
  final ProjectManifest project;

  static List<BorderBlueprintRecord> publishedLines(ProjectManifest project) =>
      project.borderCatalog.records
          .where(
            (record) =>
                !record.isDeprecated &&
                record.latestPublished != null &&
                record.latestPublished!.definition.isSpatial ==
                    (project.settings.dimension == ProjectDimension.threeD) &&
                borderTemplateUsesStrokeGeometry(
                  record.latestPublished!.definition.template,
                ),
          )
          .toList()
        ..sort((first, second) {
          final order = first.latestPublished!.definition.sortOrder.compareTo(
            second.latestPublished!.definition.sortOrder,
          );
          return order != 0 ? order : first.id.compareTo(second.id);
        });

  MapData preview(MapBorderDrawingDraft draft) {
    final map = document.current;
    if (draft.mapId != map.id ||
        draft.mapSize != map.size ||
        (draft.sourceMap != null && !identical(draft.sourceMap, map)) ||
        (draft.sourceProject != null &&
            !identical(draft.sourceProject, project)) ||
        (map.spatialScene != null &&
            (draft.sourceMap == null || draft.sourceProject == null))) {
      throw const ValidationException(
        'La carte ou le projet a changé pendant le tracé. Recommencez la bordure.',
      );
    }
    final record = publishedLines(project)
        .where((entry) => entry.id == draft.blueprintId)
        .firstOrNull;
    if (record == null ||
        !project.resourceLibraryCatalog.availableForMap(
          'borderBlueprint',
          draft.blueprintId,
          map.id,
        )) {
      throw const ValidationException(
        'Cette bordure publiée n’est plus disponible.',
      );
    }
    final definition = record.latestPublished!.definition;
    if (definition.isSpatial != (map.spatialScene != null)) {
      throw const ValidationException(
        'Choisissez une bordure adaptée à cette carte.',
      );
    }
    final id = draft.featureId;
    final feature = BorderFeature(
      id: id,
      name: record.latestPublished!.definition.name,
      blueprintId: record.id,
      seed: draft.seed,
      geometry: BorderStrokeGeometry(
        strokes: [draft.stroke],
        alignment: draft.alignment,
      ),
      overrides: const [],
      keepOutRegions: const [],
    );
    final layer = map.layers
        .whereType<BorderLayer>()
        .where((value) => value.isVisible)
        .firstOrNull;
    var proposed = map;
    var layerId = layer?.id ?? 'studio-bordures';
    if (layer == null) {
      var suffix = 2;
      while (map.layers.any((entry) => entry.id == layerId)) {
        layerId = 'studio-bordures-${suffix++}';
      }
      proposed = addBorderLayer(map, id: layerId, name: 'Bordures');
    }
    proposed = upsertBorderFeature(
      proposed,
      layerId: layerId,
      feature: feature,
      template: record.latestPublished!.definition.template,
    );
    if (definition.isSpatial) {
      final result = resolveSpatialBorderFeature(
        manifest: project,
        map: proposed,
        layerId: layerId,
        featureId: id,
      );
      if (!result.result.canApply) {
        throw ValidationException(
          'Cette bordure ne peut pas produire ce tracé (${result.result.diagnostics.first.code}).',
        );
      }
      return applySpatialBorderFeaturePreview(
        proposed,
        manifest: project,
        proposedResult: result,
      );
    }
    final request = BorderResolutionRequest(
      mapSize: map.size,
      tileSizePx: GridSize(
        width: project.settings.tileWidth,
        height: project.settings.tileHeight,
      ),
      blueprintId: record.id,
      blueprintRevision: record.latestPublished,
      feature: feature,
      visualSnapshots: project.borderCatalog.visualSnapshots,
      resolverVersion: borderResolverVersion,
    );
    final result = resolveBorderFeature(request);
    if (!result.canApply) {
      final issue = result.diagnostics.first.code;
      throw ValidationException(
        'Ce modèle ne peut pas produire ce tracé ($issue).',
      );
    }
    final completed = applyBorderFeaturePreview(
      proposed,
      expectedMapId: map.id,
      layerId: layerId,
      featureId: id,
      expectedBaseFeatureFingerprint: computeBorderFeatureEditFingerprint(
        feature,
      ),
      proposedRequest: request,
      proposedResult: result,
    );
    if (completed == proposed) {
      throw const ValidationException(
        'La bordure a changé pendant sa préparation. Réessayez.',
      );
    }
    return completed;
  }

  void finish(MapBorderDrawingDraft draft) => document.commit(preview(draft));

  MapData previewErase(MapBorderEraseDraft draft) {
    if (!draft.validFor(document.current, project)) {
      throw const ValidationException('La carte ou le projet a changé pendant la gomme. Recommencez.');
    }
    draft.geometry;
    return const BorderActions().eraseStroke(manifest: project,
        map: document.current, layerId: draft.layerId,
        featureId: draft.featureId, sampledPoints: draft.points);
  }

  void finishErase(MapBorderEraseDraft draft) => document.commit(previewErase(draft));

  void setSpatialOffset({
    required String layerId,
    required String featureId,
    required Model3dVector3? offset,
    required BorderFeature source,
  }) {
    final map = document.current;
    final layer = map.layers
        .whereType<BorderLayer>()
        .where((entry) => entry.id == layerId)
        .firstOrNull;
    final feature = layer?.content.features
        .where((entry) => entry.id == featureId)
        .firstOrNull;
    if (map.spatialScene == null ||
        project.settings.dimension != ProjectDimension.threeD ||
        feature == null ||
        !identical(feature, source)) {
      throw const ValidationException(
        'Le tracé a changé. Reprenez son décalage depuis la sélection actuelle.',
      );
    }
    final definition = project.borderCatalog
        .recordById(feature.blueprintId)
        ?.latestPublished
        ?.definition;
    if (definition?.isSpatial != true) {
      throw const ValidationException('Ce décalage concerne une bordure 3D.');
    }
    final updated = BorderFeature(
      id: feature.id,
      name: feature.name,
      blueprintId: feature.blueprintId,
      seed: feature.seed,
      geometry: feature.geometry,
      lineSide: feature.lineSide,
      spatialOffsetWorld: offset,
      paramsOverride: feature.paramsOverride,
      overrides: feature.overrides,
      keepOutRegions: feature.keepOutRegions,
      materialization: feature.materialization,
    );
    document.commit(
      upsertBorderFeature(
        map,
        layerId: layerId,
        feature: updated,
        template: definition!.template,
      ),
    );
  }

  MapData previewExisting({
    required String layerId,
    required String featureId,
  }) {
    final map = document.current;
    if (map.spatialScene == null) {
      throw const ValidationException(
        'Cette régénération s’applique aux bordures 3D.',
      );
    }
    final result = resolveSpatialBorderFeature(
      manifest: project,
      map: map,
      layerId: layerId,
      featureId: featureId,
    );
    if (!result.result.canApply) {
      throw ValidationException(
        'La bordure ne peut pas être régénérée (${result.result.diagnostics.first.code}).',
      );
    }
    return applySpatialBorderFeaturePreview(
      map,
      manifest: project,
      proposedResult: result,
    );
  }

  void applyExisting(
    MapData proposed, {
    required MapData source,
    required ProjectManifest sourceProject,
  }) {
    if (!identical(document.current, source) ||
        !identical(project, sourceProject) ||
        proposed.id != source.id) {
      throw const ValidationException(
        'La carte ou le projet a changé depuis l’aperçu. Reprenez la régénération.',
      );
    }
    document.commit(proposed);
  }

  void delete({required String layerId, required String featureId}) =>
      document.commit(
        removeBorderFeature(
          document.current,
          layerId: layerId,
          featureId: featureId,
        ),
      );
}
