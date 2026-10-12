import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_drawing_draft.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_model_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_border_fixture.dart';

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

  test('stale sources dimensions and private source models fail closed', () {
    final project = spatialBorderProject();
    final map = spatialBorderMap();
    final document = borderDocument(map);
    final draft = borderDraft(map, project);
    document.commit(map.copyWith(name: 'Carte modifiée'));
    expect(
      () => MapBorderEditingCommands(document, project).finish(draft),
      throwsA(isA<ValidationException>()),
    );
    expect(document.current.layers.whereType<BorderLayer>(), isEmpty);
    final other = project.copyWith(name: 'Projet modifié');
    expect(
      () => MapBorderEditingCommands(borderDocument(map), other).preview(draft),
      throwsA(isA<ValidationException>()),
    );
    final scoped = project.copyWith(
      resourceLibraryCatalog: ResourceLibraryCatalog(
        entries: [
          ResourceLibraryEntry(
            resourceKind: 'model3d',
            resourceId: 'oak',
            mapId: 'b',
          ),
        ],
      ),
    );
    expect(
      () => MapBorderEditingCommands(
        borderDocument(map),
        scoped,
      ).preview(borderDraft(map, scoped)),
      throwsA(isA<ValidationException>()),
    );
    final planar = project.copyWith(
      settings: const ProjectSettings(dimension: ProjectDimension.twoD),
    );
    expect(MapBorderEditingCommands.publishedLines(planar), isEmpty);
    final anchorOutside = spatialBorderProject(
      anchor: Model3dVector3(x: 40, y: 0, z: 0),
    );
    expect(
      () => MapBorderEditingCommands(
        borderDocument(map),
        anchorOutside,
      ).preview(borderDraft(map, anchorOutside)),
      throwsA(isA<ValidationException>()),
    );
  });

  test('generated border models stay owned and feature deletion preserves foreign content', () {
    final project = spatialBorderProject();
    final map = spatialBorderMap();
    final foreign = SpatialModelInstance(
      id: 'foreign',
      modelId: 'oak',
      position: Model3dVector3(x: .5, y: 0, z: .5),
    );
    final source = map.copyWith(
      spatialScene: map.spatialScene!.copyWith(instances: [foreign]),
    );
    final document = borderDocument(source);
    final borders = MapBorderEditingCommands(document, project);
    borders.finish(borderDraft(source, project));
    final generated = document.current.spatialScene!.instances.firstWhere(
      (instance) => instance.id != foreign.id,
    );
    final models = SpatialModelEditingCommands(document, project);
    final before = document.current;
    expect(() => models.update(generated.id, x: 8), throwsStateError);
    expect(() => models.delete(generated.id), throwsStateError);
    expect(() => models.duplicate(generated.id), throwsStateError);
    expect(document.current, same(before));
    final layer = before.layers.whereType<BorderLayer>().single;
    borders.delete(
      layerId: layer.id,
      featureId: layer.content.features.single.id,
    );
    expect(document.current.spatialScene!.instances, [foreign]);
    expect(document.undoCount, 2);
    document.restore(redo: false);
    expect(document.current, before);
  });

  test(
    'changed live models require an explicit preview before regeneration',
    () {
      final project = spatialBorderProject(
        anchor: Model3dVector3(x: .1, y: 0, z: 0),
      );
      final source = spatialBorderMap();
      final document = borderDocument(source);
      MapBorderEditingCommands(
        document,
        project,
      ).finish(borderDraft(source, project));
      final map = document.current;
      final changed = project.copyWith(
        models3d: [project.models3d.single.copyWith(scale: 2)],
      );
      final layer = map.layers.whereType<BorderLayer>().single;
      final feature = layer.content.features.single;
      expect(
        diagnoseSpatialBorderFeature(
          manifest: changed,
          map: map,
          layerId: layer.id,
          featureId: feature.id,
        ).diagnostics.map((issue) => issue.code),
        contains('border.spatial.materialization_stale'),
      );
      final commands = MapBorderEditingCommands(document, changed);
      final preview = commands.previewExisting(
        layerId: layer.id,
        featureId: feature.id,
      );
      expect(document.current, same(map));
      expect(
        preview.spatialScene!.instances.first.position.x,
        isNot(map.spatialScene!.instances.first.position.x),
      );
      commands.applyExisting(preview, source: map, sourceProject: changed);
      expect(document.undoCount, 2);
      expect(
        diagnoseSpatialBorderFeature(
          manifest: changed,
          map: document.current,
          layerId: layer.id,
          featureId: feature.id,
        ).diagnostics,
        isEmpty,
      );
      expect(
        () => commands.applyExisting(
          preview,
          source: map,
          sourceProject: changed,
        ),
        throwsA(isA<ValidationException>()),
      );
    },
  );
}

EditableMapDocument borderDocument(MapData map) => EditableMapDocument(
  MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r0'),
);

MapBorderDrawingDraft borderDraft(MapData map, ProjectManifest project) =>
    MapBorderDrawingDraft.start(
      mapId: map.id,
      mapSize: map.size,
      blueprintId: 'fence',
      origin: const GridPos(x: 2, y: 5),
      sourceMap: map,
      sourceProject: project,
      featureId: 'test-border',
      seed: BorderSignedInt64.fromInt(17),
    ).addAngle(const GridPos(x: 5, y: 5)).addAngle(const GridPos(x: 5, y: 7));
