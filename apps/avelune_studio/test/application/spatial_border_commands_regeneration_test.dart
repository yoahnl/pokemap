import 'package:avelune_studio/features/map_workspace/application/map_border_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_model_editing_commands.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_border_fixture.dart';
import 'spatial_border_commands_fixtures.dart';

void main() {
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
