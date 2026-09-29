import 'package:map_core/map_core_domain.dart';

import 'editable_map_document.dart';
import 'map_border_drawing_draft.dart';

final class MapBorderEditingCommands {
  MapBorderEditingCommands(this.document, this.project);

  final EditableMapDocument document;
  final ProjectManifest project;
  static int _nextId = 0;

  static List<BorderBlueprintRecord> publishedLines(ProjectManifest project) =>
      project.borderCatalog.records
          .where(
            (record) =>
                !record.isDeprecated &&
                record.latestPublished != null &&
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

  void finish(MapBorderDrawingDraft draft) {
    final map = document.current;
    if (draft.mapId != map.id || draft.mapSize != map.size) {
      throw const ValidationException('La carte a changé pendant le tracé.');
    }
    final record = publishedLines(
      project,
    ).where((entry) => entry.id == draft.blueprintId).firstOrNull;
    if (record == null) {
      throw const ValidationException(
        'Cette bordure publiée n’est plus disponible.',
      );
    }
    final id =
        'studio-border-${DateTime.now().microsecondsSinceEpoch}-${_nextId++}';
    final feature = BorderFeature(
      id: id,
      name: record.latestPublished!.definition.name,
      blueprintId: record.id,
      seed: BorderSignedInt64.fromInt(DateTime.now().microsecondsSinceEpoch),
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
    document.commit(completed);
  }
}
