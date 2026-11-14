import 'package:avelune_studio/features/map_workspace/application/map_border_editing_commands.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_border_fixture.dart';
import 'spatial_border_commands_fixtures.dart';
export 'spatial_border_commands_fixtures.dart';

void main() {
  test('spatial offsets keep feature intent and ownership until explicit regeneration', () {
    final project = spatialBorderProject();
    final map = spatialBorderMap();
    final document = borderDocument(map);
    final commands = MapBorderEditingCommands(document, project);
    commands.finish(borderDraft(map, project));
    final before = document.current;
    final layer = before.layers.whereType<BorderLayer>().single;
    final feature = layer.content.features.single;
    final offset = Model3dVector3(x: .25, y: 1.5, z: -.25);
    commands.setSpatialOffset(
      layerId: layer.id,
      featureId: feature.id,
      offset: offset,
      source: feature,
    );
    final edited = document.current;
    final updated = edited.layers
        .whereType<BorderLayer>()
        .single
        .content
        .features
        .single;
    expect(updated.spatialOffsetWorld, offset);
    expect(updated.geometry, feature.geometry);
    expect(updated.lineSide, feature.lineSide);
    expect(updated.seed, feature.seed);
    expect(updated.overrides, feature.overrides);
    expect(updated.keepOutRegions, feature.keepOutRegions);
    expect(updated.materialization, feature.materialization);
    expect(edited.spatialScene, before.spatialScene);
    expect(MapData.fromJson(edited.toJson()), edited);
    expect(
      diagnoseSpatialBorderFeature(
        manifest: project,
        map: edited,
        layerId: layer.id,
        featureId: feature.id,
      ).diagnostics.map((issue) => issue.code),
      contains('border.spatial.materialization_stale'),
    );
    expect(
      () => commands.setSpatialOffset(
        layerId: layer.id,
        featureId: feature.id,
        offset: null,
        source: feature,
      ),
      throwsA(isA<ValidationException>()),
    );
    expect(document.current, same(edited));
    final preview = commands.previewExisting(
      layerId: layer.id,
      featureId: feature.id,
    );
    for (final instance in preview.spatialScene!.instances) {
      final original = before.spatialScene!.instances.singleWhere(
        (item) => item.id == instance.id,
      );
      expect(instance.position.x, closeTo(original.position.x + .25, 1e-9));
      expect(instance.position.y, closeTo(original.position.y + 1.5, 1e-9));
      expect(instance.position.z, closeTo(original.position.z - .25, 1e-9));
    }
    commands.applyExisting(preview, source: edited, sourceProject: project);
    expect(document.undoCount, 3);
    document.restore(redo: false);
    expect(document.current, edited);
    document.restore(redo: false);
    expect(document.current, before);
    document.restore(redo: true);
    final restored = document.current.layers
        .whereType<BorderLayer>()
        .single
        .content
        .features
        .single;
    commands.setSpatialOffset(
      layerId: layer.id,
      featureId: feature.id,
      offset: null,
      source: restored,
    );
    expect(
      document.current.layers
          .whereType<BorderLayer>()
          .single
          .content
          .features
          .single
          .spatialOffsetWorld,
      isNull,
    );
    final planar = project.copyWith(
      settings: const ProjectSettings(dimension: ProjectDimension.twoD),
    );
    expect(
      () => MapBorderEditingCommands(document, planar).setSpatialOffset(
        layerId: layer.id,
        featureId: feature.id,
        offset: offset,
        source: restored,
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('native preview shares exact units and identity with one undoable application', () {
    final project = spatialBorderProject();
    final map = spatialBorderMap();
    final document = borderDocument(map);
    final commands = MapBorderEditingCommands(document, project);
    final draft = borderDraft(map, project);
    final preview = commands.preview(draft);
    final feature = preview.layers
        .whereType<BorderLayer>()
        .single
        .content
        .features
        .single;
    expect(document.current, same(map));
    expect(document.undoCount, 0);
    expect(preview.placedElements, isEmpty);
    expect(
      feature.generatedPlacementIds.toSet(),
      preview.spatialScene!.instances.map((instance) => instance.id).toSet(),
    );
    expect(preview.spatialScene!.instances, hasLength(6));
    for (final instance in preview.spatialScene!.instances) {
      expect(
        instance.position.y,
        map.spatialScene!.worldHeightAt(
          instance.position.x,
          instance.position.z,
        ),
      );
    }
    expect(commands.preview(draft), preview);
    commands.finish(draft);
    expect(document.current, preview);
    expect(document.undoCount, 1);
    document.restore(redo: false);
    expect(document.current, map);
    document.restore(redo: true);
    expect(document.current, preview);
    expect(MapData.fromJson(preview.toJson()), preview);
  });
}
