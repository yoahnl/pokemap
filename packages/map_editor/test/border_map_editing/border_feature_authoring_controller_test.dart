import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_feature_authoring_controller.dart';

void main() {
  group('BorderFeatureAuthoringController', () {
    const controller = BorderFeatureAuthoringController();

    test('creates unique region features from a published blueprint', () {
      final map = _map();
      final blueprint = _record(
        id: 'coast',
        template: BorderBlueprintTemplate.organicEdge,
      );

      final first = controller.createFeature(
        map: map,
        layerId: 'borders',
        blueprint: blueprint,
        name: 'Côte principale',
      );
      final second = controller.createFeature(
        map: first.map,
        layerId: 'borders',
        blueprint: blueprint,
        name: 'Îlot',
      );

      expect(first.feature.id, 'border_feature');
      expect(second.feature.id, 'border_feature_2');
      expect(first.feature.geometry, isA<BorderRegionGeometry>());
      final geometry = first.feature.geometry as BorderRegionGeometry;
      expect(geometry.width, map.size.width);
      expect(geometry.height, map.size.height);
      expect(geometry.cells, everyElement(isFalse));
      expect(first.feature.blueprintId, 'coast');
      expect(
        (second.map.layers.last as BorderLayer)
            .content
            .features
            .map((feature) => feature.id),
        <String>['border_feature', 'border_feature_2'],
      );
    });

    test('rejects unpublished or deprecated blueprints for new features', () {
      expect(
        () => controller.createFeature(
          map: _map(),
          layerId: 'borders',
          blueprint: _record(
            id: 'draft',
            template: BorderBlueprintTemplate.organicEdge,
            published: false,
          ),
          name: 'Draft',
        ),
        throwsStateError,
      );
      expect(
        () => controller.createFeature(
          map: _map(),
          layerId: 'borders',
          blueprint: _record(
            id: 'deprecated',
            template: BorderBlueprintTemplate.organicEdge,
            isDeprecated: true,
          ),
          name: 'Deprecated',
        ),
        throwsStateError,
      );
    });

    test('renames, reorders and deletes without touching collision layers', () {
      const collision = MapLayer.collision(
        id: 'collision',
        name: 'Collision',
      );
      final blueprint = _record(
        id: 'coast',
        template: BorderBlueprintTemplate.organicEdge,
      );
      var map = _map(collision: collision);
      map = controller
          .createFeature(
            map: map,
            layerId: 'borders',
            blueprint: blueprint,
            name: 'First',
          )
          .map;
      map = controller
          .createFeature(
            map: map,
            layerId: 'borders',
            blueprint: blueprint,
            name: 'Second',
          )
          .map;
      final collisionJson = collision.toJson();

      map = controller.renameFeature(
        map: map,
        layerId: 'borders',
        featureId: 'border_feature',
        name: 'Renamed',
      );
      map = controller.reorderFeature(
        map: map,
        layerId: 'borders',
        featureId: 'border_feature',
        newIndex: 1,
      );
      map = controller.deleteFeature(
        map: map,
        layerId: 'borders',
        featureId: 'border_feature_2',
      );

      final border = map.layers.whereType<BorderLayer>().single;
      expect(border.content.features.single.id, 'border_feature');
      expect(border.content.features.single.name, 'Renamed');
      final afterCollision = map.layers.whereType<CollisionLayer>().single;
      expect(afterCollision, same(collision));
      expect(afterCollision.toJson(), collisionJson);
    });
  });
}

MapData _map({MapLayer? collision}) => MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v2,
      size: const GridSize(width: 5, height: 4),
      layers: <MapLayer>[
        if (collision != null) collision,
        const MapLayer.border(id: 'borders', name: 'Bordures'),
      ],
    );

BorderBlueprintRecord _record({
  required String id,
  required BorderBlueprintTemplate template,
  bool published = true,
  bool isDeprecated = false,
}) {
  final draftDefinition = BorderBlueprintDraftDefinition(
    name: id,
    previewSeed: BorderSignedInt64.zero,
    template: template,
    primitives: const <BorderPrimitiveDraft>[],
    defaults: _params(),
    sortOrder: 0,
  );
  return BorderBlueprintRecord(
    id: id,
    draft: BorderBlueprintDraft(
      baseRevision: published ? 1 : 0,
      definition: draftDefinition,
    ),
    latestPublished: published
        ? BorderBlueprintRevision(
            revision: 1,
            definition: BorderBlueprintPublishedDefinition(
              name: id,
              previewSeed: BorderSignedInt64.zero,
              template: template,
              primitives: const <BorderPublishedPrimitive>[],
              defaults: _params(),
              sortOrder: 0,
            ),
          )
        : null,
    isDeprecated: isDeprecated,
  );
}

BorderGenerationParams _params() => BorderGenerationParams(
      irregularityPermille: 0,
      detailDensityPermille: 0,
      variationPermille: 0,
      maxOverlapPx: 0,
      gapTolerancePx: 0,
      depthRows: 1,
    );
