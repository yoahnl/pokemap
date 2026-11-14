part of 'map_border_editing_commands.dart';

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

final class MapBorderRegenerationStatus {
  const MapBorderRegenerationStatus({required this.stale, this.diagnostic});
  final bool stale;
  final String? diagnostic;
}

extension MapBorderRegenerationCommands on MapBorderEditingCommands {
  MapBorderRegenerationStatus regenerationStatus({
    required String layerId,
    required String featureId,
  }) {
    final map = document.current;
    try {
      if (map.spatialScene != null) {
        final report = diagnoseSpatialBorderFeature(
          manifest: project,
          map: map,
          layerId: layerId,
          featureId: featureId,
        );
        return MapBorderRegenerationStatus(
          stale: report.diagnostics.any(
            (issue) => issue.code == 'border.spatial.materialization_stale',
          ),
          diagnostic: report.hasErrors
              ? 'Cette bordure doit être corrigée avant régénération.'
              : null,
        );
      }
      return MapBorderRegenerationStatus(
        stale: previewExisting(layerId: layerId, featureId: featureId) != map,
      );
    } on Object {
      return const MapBorderRegenerationStatus(
        stale: false,
        diagnostic: 'La bordure ne peut pas être préparée. Vérifiez ses pièces sources.',
      );
    }
  }

  MapBorderRegenerationPreview prepareExisting({
    required String layerId,
    required String featureId,
  }) => MapBorderRegenerationPreview(
    source: document.current,
    project: project,
    result: previewExisting(layerId: layerId, featureId: featureId),
    layerId: layerId,
    featureId: featureId,
  );

  void applyRegeneration(MapBorderRegenerationPreview preview) => applyExisting(
    preview.result,
    source: preview.source,
    sourceProject: preview.project,
  );

  MapData previewExisting({
    required String layerId,
    required String featureId,
  }) {
    final map = document.current;
    if (map.spatialScene == null) {
      final layer = map.layers
          .whereType<BorderLayer>()
          .where((layer) => layer.id == layerId)
          .firstOrNull;
      final feature = layer?.content.features
          .where((feature) => feature.id == featureId)
          .firstOrNull;
      if (feature == null) {
        throw const ValidationException('Ce tracé de bordure est introuvable.');
      }
      final record = project.borderCatalog.recordById(feature.blueprintId);
      final revision = record?.latestPublished;
      if (revision == null ||
          revision.definition.isSpatial ||
          project.settings.dimension != ProjectDimension.twoD ||
          !borderTemplateUsesStrokeGeometry(revision.definition.template) ||
          !project.resourceLibraryCatalog.availableForMap(
            'borderBlueprint',
            feature.blueprintId,
            map.id,
          )) {
        throw const ValidationException(
          'Cette bordure publiée n’est plus disponible.',
        );
      }
      final request = BorderResolutionRequest(
        mapSize: map.size,
        tileSizePx: GridSize(
          width: project.settings.tileWidth,
          height: project.settings.tileHeight,
        ),
        blueprintId: feature.blueprintId,
        blueprintRevision: revision,
        feature: feature,
        visualSnapshots: project.borderCatalog.visualSnapshots,
        resolverVersion: borderResolverVersion,
      );
      final result = resolveBorderFeature(request);
      if (!result.canApply) {
        throw ValidationException(
          'La bordure ne peut pas être régénérée (${result.diagnostics.first.code}).',
        );
      }
      return applyBorderFeaturePreview(
        map,
        expectedMapId: map.id,
        layerId: layerId,
        featureId: featureId,
        expectedBaseFeatureFingerprint: computeBorderFeatureEditFingerprint(
          feature,
        ),
        proposedRequest: request,
        proposedResult: result,
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
}
