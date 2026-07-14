import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_feature_authoring_controller.dart';
import 'package:map_editor/src/features/border_map_editing/state/border_map_editing_providers.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  test('notifier supports Border feature CRUD and reconciles selection', () {
    const collision = MapLayer.collision(
      id: 'collision',
      name: 'Collision',
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    notifier.state = EditorState(
      project: _project(<BorderBlueprintRecord>[
        _record('coast-a'),
        _record('coast-b'),
      ]),
      activeMap: const MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v2,
        size: GridSize(width: 4, height: 3),
        layers: <MapLayer>[
          collision,
          MapLayer.border(id: 'borders', name: 'Bordures'),
        ],
      ),
      activeLayerId: 'borders',
    );
    container.read(activeBorderFeatureControllerProvider);
    final collisionJson = collision.toJson();

    notifier.createBorderFeature(
      layerId: 'borders',
      blueprintId: 'coast-a',
      name: 'Basse',
    );
    notifier.createBorderFeature(
      layerId: 'borders',
      blueprintId: 'coast-a',
      name: 'Haute',
    );

    expect(
      container.read(activeBorderFeatureControllerProvider).activeFeatureId,
      'border_feature_2',
      reason: 'the last authored feature is uppermost',
    );
    notifier.selectBorderFeature(
      layerId: 'borders',
      featureId: 'border_feature',
    );
    notifier.renameBorderFeature(
      layerId: 'borders',
      featureId: 'border_feature',
      name: 'Rivage renommé',
    );
    notifier.reorderBorderFeature(
      layerId: 'borders',
      featureId: 'border_feature',
      newIndex: 1,
    );

    final mapBeforePreview = notifier.state.activeMap!;
    final preview =
        const BorderFeatureAuthoringController().previewBlueprintChange(
      map: mapBeforePreview,
      layerId: 'borders',
      featureId: 'border_feature',
      sourceBlueprint: _record('coast-a'),
      targetBlueprint: _record('coast-b'),
    );
    expect(notifier.state.activeMap, same(mapBeforePreview));
    notifier.changeBorderFeatureBlueprint(preview);
    notifier.deleteBorderFeature(
      layerId: 'borders',
      featureId: 'border_feature_2',
    );

    final border =
        notifier.state.activeMap!.layers.whereType<BorderLayer>().single;
    expect(border.content.features.single.id, 'border_feature');
    expect(border.content.features.single.name, 'Rivage renommé');
    expect(border.content.features.single.blueprintId, 'coast-b');
    expect(
      container.read(activeBorderFeatureControllerProvider).activeFeatureId,
      'border_feature',
    );
    expect(
      notifier.state.activeMap!.layers
          .whereType<CollisionLayer>()
          .single
          .toJson(),
      collisionJson,
    );
  });

  test('notifier refuses draft and deprecated blueprints for creation', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    notifier.state = EditorState(
      project: _project(<BorderBlueprintRecord>[
        _record('draft', published: false),
        _record('old', isDeprecated: true),
      ]),
      activeMap: const MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v2,
        size: GridSize(width: 2, height: 2),
        layers: <MapLayer>[
          MapLayer.border(id: 'borders', name: 'Bordures'),
        ],
      ),
      activeLayerId: 'borders',
    );
    final before = notifier.state.activeMap!.toJson();

    notifier.createBorderFeature(
      layerId: 'borders',
      blueprintId: 'draft',
      name: 'Draft',
    );
    expect(notifier.state.activeMap!.toJson(), before);
    expect(notifier.state.errorMessage, isNotNull);

    notifier.createBorderFeature(
      layerId: 'borders',
      blueprintId: 'old',
      name: 'Old',
    );
    expect(notifier.state.activeMap!.toJson(), before);
    expect(notifier.state.errorMessage, isNotNull);
  });

  test('notifier executes separate creation or confirmed reset proposals', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    final coast = _record('coast');
    final wall = _record(
      'wall',
      template: BorderBlueprintTemplate.masonryLine,
    );
    notifier.state = EditorState(
      project: _project(<BorderBlueprintRecord>[coast, wall]),
      activeMap: const MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v2,
        size: GridSize(width: 3, height: 3),
        layers: <MapLayer>[
          MapLayer.border(id: 'borders', name: 'Bordures'),
        ],
      ),
      activeLayerId: 'borders',
    );
    container.read(activeBorderFeatureControllerProvider);
    notifier.createBorderFeature(
      layerId: 'borders',
      blueprintId: 'coast',
      name: 'Côte',
    );
    final sourceMap = notifier.state.activeMap!;
    final preview =
        const BorderFeatureAuthoringController().previewBlueprintChange(
      map: sourceMap,
      layerId: 'borders',
      featureId: 'border_feature',
      sourceBlueprint: coast,
      targetBlueprint: wall,
    );

    notifier.createBorderFeatureFromBlueprintChange(
      preview: preview,
      name: 'Muret séparé',
    );
    var features = notifier.state.activeMap!.layers
        .whereType<BorderLayer>()
        .single
        .content
        .features;
    expect(features, hasLength(2));
    expect(features.first.blueprintId, 'coast');
    expect(features.last.blueprintId, 'wall');
    expect(
      container.read(activeBorderFeatureControllerProvider).activeFeatureId,
      features.last.id,
    );

    notifier.resetBorderFeatureBlueprint(preview);
    features = notifier.state.activeMap!.layers
        .whereType<BorderLayer>()
        .single
        .content
        .features;
    expect(features.first.blueprintId, 'wall');
    expect(features.first.geometry, isA<BorderStrokeGeometry>());
    expect(features.last.name, 'Muret séparé');
  });
}

ProjectManifest _project(List<BorderBlueprintRecord> records) =>
    ProjectManifest(
      name: 'Project',
      version: ProjectVersion.v2,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      borderCatalog: ProjectBorderCatalog(records: records),
    );

BorderBlueprintRecord _record(
  String id, {
  bool published = true,
  bool isDeprecated = false,
  BorderBlueprintTemplate template = BorderBlueprintTemplate.organicEdge,
}) {
  final definition = BorderBlueprintDraftDefinition(
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
      definition: definition,
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
