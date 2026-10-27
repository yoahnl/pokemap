import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  for (final entityCount in [10, 1000]) {
    for (final instanceCount in [1, 5]) {
      test(
          'bound model lookup reads no entity IDs after construction '
          'with $entityCount entities and $instanceCount instances', () {
        var idReads = 0;
        var presenceChecks = 0;
        var modelStateChecks = 0;
        final sources = [
          for (var i = 0; i < entityCount; i++)
            _CountingEntity(
              _entity('entity-$i'),
              () => idReads++,
            ),
        ];
        final input = _SingleUseEntities(sources);
        final movement = SpatialMovementController(
          scene: _scene([
            for (var i = 0; i < instanceCount; i++)
              _instance('instance-$i', entityId: 'entity-${entityCount - 1}'),
          ]),
          models: const [],
          entities: input,
          entityPresencePredicate: (_) {
            presenceChecks++;
            return true;
          },
          modelStateProvider: (_) {
            modelStateChecks++;
            return _modelState(false);
          },
        );
        idReads = 0;
        presenceChecks = 0;
        modelStateChecks = 0;

        expect(movement.canTraverseActor(3, 3, 3, 3), isTrue);
        expect(presenceChecks, 2 * instanceCount);
        expect(modelStateChecks, 2 * instanceCount);
        expect(idReads, 0);
        expect(input.iterations, 1);
      });
    }
  }

  test('duplicate source IDs retain the first owner and its live presence', () {
    final first = _entity('owner');
    final second = first.copyWith(name: 'second');
    var firstPresent = false;
    final owners = <MapEntity>[];
    final movement = SpatialMovementController(
      scene: _scene([_instance('bound', entityId: 'owner')]),
      models: [_model()],
      entities: [first, second],
      entityPresencePredicate: (entity) {
        owners.add(entity);
        return identical(entity, first) && firstPresent;
      },
    );
    owners.clear();

    expect(movement.canTraverseActor(3, 3, 3, 3), isTrue);
    expect(owners, hasLength(2));
    expect(owners.every((entity) => identical(entity, first)), isTrue);
    firstPresent = true;
    expect(movement.canTraverseActor(3, 3, 3, 3), isFalse);
    expect(owners.every((entity) => identical(entity, first)), isTrue);
  });

  for (final projected in [null, _entity('projected-owner')]) {
    test(
        'bound models use source presence when projection is '
        '${projected == null ? 'absent' : 'a different identity'}', () {
      final source = _entity('owner');
      var present = false;
      final owners = <MapEntity>[];
      final movement = SpatialMovementController(
        scene: _scene([_instance('bound', entityId: 'owner')]),
        models: [_model()],
        entities: [source],
        entityProjection: (_) => projected,
        entityPresencePredicate: (entity) {
          owners.add(entity);
          return present;
        },
      );
      owners.clear();

      expect(movement.canTraverseActor(3, 3, 3, 3), isTrue);
      expect(owners, hasLength(2));
      expect(owners.every((entity) => identical(entity, source)), isTrue);
      present = true;
      expect(movement.canTraverseActor(3, 3, 3, 3), isFalse);
      expect(owners.every((entity) => identical(entity, source)), isTrue);
    });
  }

  test('missing bound owners fail on collision use before model state lookup',
      () {
    var stateChecks = 0;
    final movement = SpatialMovementController.fromMap(
      map: MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 8, height: 8),
        spatialScene: _scene([_instance('bound', entityId: 'missing')]),
      ),
      models: const [],
      validateSpawn: false,
      modelStateProvider: (_) {
        stateChecks++;
        return _modelState(false);
      },
    );

    expect(stateChecks, 0);
    expect(
      () => movement.canTraverseActor(3, 3, 3, 3),
      throwsA(isA<StateError>().having(
        (error) => error.message,
        'message',
        'The bound 3D entity does not exist.',
      )),
    );
    expect(stateChecks, 0);
  });

  test('materialized source identities survive changes to the caller list', () {
    final source = _entity('owner');
    final input = [source];
    final movement = SpatialMovementController(
      scene: _scene([_instance('bound', entityId: 'owner')]),
      models: [_model()],
      entities: input,
    );
    input.clear();

    expect(movement.entities.single, same(source));
    expect(() => movement.entities.clear(), throwsUnsupportedError);
    expect(movement.canTraverseActor(3, 3, 3, 3), isFalse);
  });

  test('indexed instances keep live model state and model catalog values', () {
    var blocking = false;
    final movement = SpatialMovementController(
      scene: _scene([_instance('door', entityId: 'owner')]),
      models: [_model()],
      entities: [_entity('owner')],
      modelStateProvider: (_) => _modelState(blocking),
    );

    expect(movement.canTraverseActor(3, 3, 3, 3), isTrue);
    blocking = true;
    expect(movement.canTraverseActor(3, 3, 3, 3), isFalse);
    expect(movement.wouldModelBlockActor('door', 3, 3), isTrue);
    movement.models['model'] = _model(minY: 3, maxY: 5);
    expect(movement.wouldModelBlockActor('door', 3, 3), isFalse);
    expect(movement.canTraverseActor(3, 3, 3, 3), isTrue);
    movement.models.clear();
    expect(
      () => movement.wouldModelBlockActor('door', 3, 3),
      throwsA(isA<StateError>().having(
        (error) => error.message,
        'message',
        'Modèle de collision absent : model',
      )),
    );
  });
}

MapEntity _entity(String id) => MapEntity(
      id: id,
      kind: MapEntityKind.custom,
      pos: const GridPos(x: 6, y: 6),
      blocksMovement: false,
    );

MapSpatialScene _scene(List<SpatialModelInstance> instances) => MapSpatialScene(
      width: 8,
      depth: 8,
      instances: instances,
      navigation: SpatialNavigationProfile(
        spawn: SpatialSpawn(x: 1.5, z: 5.5),
      ),
    );

SpatialModelInstance _instance(String id, {String? entityId}) =>
    SpatialModelInstance(
      id: id,
      modelId: 'model',
      position: Model3dVector3(x: 3, y: 0, z: 3),
      entityId: entityId,
    );

ProjectModel3dEntry _model({double minY = 0, double maxY = 2}) =>
    ProjectModel3dEntry(
      id: 'model',
      name: 'Model',
      sourceAssetId: 'model-source',
      relativePath: 'assets/models3d/model.glb',
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3(x: -.5, y: minY, z: -.5),
          max: Model3dVector3(x: .5, y: maxY, z: .5),
        ),
        meshCount: 1,
        triangleCount: 1,
      ),
    );

SpatialModelRuntimeState _modelState(bool blocking) => SpatialModelRuntimeState(
      modelId: 'model',
      animationIndex: null,
      normalizedTime: 0,
      blocksMovement: blocking,
    );

final class _CountingEntity implements MapEntity {
  _CountingEntity(this.source, this.onIdRead);

  final MapEntity source;
  final void Function() onIdRead;

  @override
  String get id {
    onIdRead();
    return source.id;
  }

  @override
  bool get blocksMovement => source.blocksMovement;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _SingleUseEntities extends Iterable<MapEntity> {
  _SingleUseEntities(this.source);

  final List<MapEntity> source;
  int iterations = 0;

  @override
  Iterator<MapEntity> get iterator {
    if (++iterations > 1) {
      throw StateError('The caller iterable was consumed more than once.');
    }
    return source.iterator;
  }
}
