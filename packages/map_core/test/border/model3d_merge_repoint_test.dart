import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'spatial_border_resolution_test.dart' show spatialBorderFixture;

const _model = 'unit';
const _replacement = 'unit-copy';

SpatialBorderResolutionResult _resolve(ProjectManifest project, MapData map) =>
    resolveSpatialBorderFeature(
      manifest: project,
      map: map,
      layerId: 'border',
      featureId: 'fence',
    );

ProjectManifest _merged(
  ProjectManifest project, {
  Map<String, Object?> replacementChanges = const {},
}) {
  final model = project.models3d.single;
  final catalog = project.borderCatalog;
  return project.copyWith(
    models3d: [
      ProjectModel3dEntry.fromJson({
        ...model.toJson(),
        'id': _replacement,
        'sourceAssetId': model.sourceAssetId.replaceAll(_model, _replacement),
        'relativePath': model.relativePath.replaceAll(_model, _replacement),
        ...replacementChanges,
      }),
    ],
    borderCatalog: ProjectBorderCatalog(
      formatVersion: catalog.formatVersion,
      records: [
        for (final record in catalog.records)
          repointModelInBorderRecord(
            record,
            modelId: _model,
            replacementId: _replacement,
            formatVersion: catalog.formatVersion,
          ),
      ],
      visualSnapshots: catalog.visualSnapshots,
    ),
  );
}

MapData _materialized(ProjectManifest project, MapData map) {
  final applied = applySpatialBorderFeaturePreview(
    map,
    manifest: project,
    proposedResult: _resolve(project, map),
  );
  final scene = applied.spatialScene!;
  return applied.copyWith(
    spatialScene: scene.copyWith(
      instances: [
        ...scene.instances,
        SpatialModelInstance(
          id: 'direct',
          modelId: _model,
          position: Model3dVector3(x: 1, y: 0, z: 1),
          animationIndex: 0,
        ),
      ],
    ),
  );
}

BorderFeature _feature(MapData map) =>
    map.layers.whereType<BorderLayer>().single.content.featureById('fence')!;

void main() {
  test(
    'a duplicate model is repointed everywhere and the border stays fresh',
    () {
      final fixture = spatialBorderFixture();
      final map = _materialized(fixture.project, fixture.map);
      final after = _merged(fixture.project);

      final result = repointModelInMap(
        map,
        before: fixture.project,
        after: after,
        modelId: _model,
        replacementId: _replacement,
        blueprintIds: {'fence'},
      );

      final before = map.spatialScene!.instances;
      final instances = result.spatialScene!.instances;
      expect(
        instances.where((instance) => instance.modelId == _model),
        isEmpty,
      );
      expect(
        {for (final instance in instances) instance.id: instance},
        {
          for (final instance in before)
            instance.id: instance.copyWith(modelId: _replacement),
        },
      );
      expect(
        instances
            .singleWhere((instance) => instance.id == 'direct')
            .animationIndex,
        0,
      );
      final feature = _feature(result);
      expect(feature.materialization!.receipt.blueprintRevision, 2);
      expect(
        spatialBorderMaterializationIsFresh(
          _resolve(after, result),
          feature.materialization!,
          result,
        ),
        isTrue,
      );
      final record = after.borderCatalog.records.single;
      expect(record.latestPublished!.revision, 2);
      expect(
        borderRecordUsesModel(
          record,
          _model,
          formatVersion: after.borderCatalog.formatVersion,
        ),
        isFalse,
      );
      expect(
        borderRecordUsesModel(
          fixture.project.borderCatalog.records.single,
          _model,
          formatVersion: after.borderCatalog.formatVersion,
        ),
        isTrue,
      );
    },
  );

  test('a stale border is refused before anything is repointed', () {
    final fixture = spatialBorderFixture();
    final map = _materialized(fixture.project, fixture.map);
    final generated = _feature(map).generatedPlacementIds.first;
    final scene = map.spatialScene!;
    final stale = map.copyWith(
      spatialScene: scene.copyWith(
        instances: [
          for (final instance in scene.instances)
            instance.id == generated
                ? instance.copyWith(
                    position: Model3dVector3(
                      x: instance.position.x + 1,
                      y: instance.position.y,
                      z: instance.position.z,
                    ),
                  )
                : instance,
        ],
      ),
    );

    expect(
      () => repointModelInMap(
        stale,
        before: fixture.project,
        after: _merged(fixture.project),
        modelId: _model,
        replacementId: _replacement,
        blueprintIds: {'fence'},
      ),
      throwsA(
        isA<Model3dMergeException>().having(
          (error) => error.reason,
          'reason',
          Model3dMergeRefusal.borderStale,
        ),
      ),
    );
  });

  test('an already stale border is kept as is when asked', () {
    final fixture = spatialBorderFixture();
    final map = _materialized(fixture.project, fixture.map);
    final generated = _feature(map).generatedPlacementIds.first;
    final scene = map.spatialScene!;
    final stale = map.copyWith(
      spatialScene: scene.copyWith(
        instances: [
          for (final instance in scene.instances)
            instance.id == generated
                ? instance.copyWith(
                    position: Model3dVector3(
                      x: instance.position.x + 1,
                      y: instance.position.y,
                      z: instance.position.z,
                    ),
                  )
                : instance,
        ],
      ),
    );

    final result = repointModelInMap(
      stale,
      before: fixture.project,
      after: _merged(fixture.project),
      modelId: _model,
      replacementId: _replacement,
      blueprintIds: {'fence'},
      keepStaleBorders: true,
    );

    expect(_feature(result).materialization, _feature(stale).materialization);
    expect(result.spatialScene!.instances, [
      for (final instance in stale.spatialScene!.instances)
        instance.copyWith(modelId: _replacement),
    ]);
  });

  test('environment-owned instances are refused', () {
    final fixture = spatialBorderFixture();
    final map = _materialized(fixture.project, fixture.map);
    final scene = map.spatialScene!;
    final owned = map.copyWith(
      spatialScene: scene.copyWith(
        instances: [
          ...scene.instances,
          SpatialModelInstance(
            id: 'env3d_area_0',
            modelId: _model,
            position: Model3dVector3(x: 2, y: 0, z: 2),
          ),
        ],
      ),
    );

    expect(
      () => repointModelInMap(
        owned,
        before: fixture.project,
        after: _merged(fixture.project),
        modelId: _model,
        replacementId: _replacement,
        blueprintIds: {'fence'},
      ),
      throwsA(
        isA<Model3dMergeException>().having(
          (error) => error.reason,
          'reason',
          Model3dMergeRefusal.environmentOwned,
        ),
      ),
    );
  });

  test(
    'a missing replacement leaves the border unresolvable and is refused',
    () {
      final fixture = spatialBorderFixture();
      final map = _materialized(fixture.project, fixture.map);
      final after = _merged(fixture.project);

      expect(
        () => repointModelInMap(
          map,
          before: fixture.project,
          after: after.copyWith(models3d: const []),
          modelId: _model,
          replacementId: _replacement,
          blueprintIds: {'fence'},
        ),
        throwsA(
          isA<Model3dMergeException>().having(
            (error) => error.reason,
            'reason',
            Model3dMergeRefusal.borderNotApplicable,
          ),
        ),
      );
    },
  );
}
