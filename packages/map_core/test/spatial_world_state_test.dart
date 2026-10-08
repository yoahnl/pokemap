import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  SpatialModelRuntimeState opened({String modelId = 'door'}) =>
      SpatialModelRuntimeState(
        modelId: modelId,
        animationIndex: 0,
        normalizedTime: 1,
        blocksMovement: false,
      );

  test('model states are isolated by map and instance and round trip', () {
    final state = const SpatialWorldState.empty()
        .setModelState('village', 'entrance', opened())
        .setModelState(
          'forest',
          'entrance',
          SpatialModelRuntimeState(
            modelId: 'gate',
            animationIndex: 1,
            normalizedTime: .25,
            blocksMovement: true,
          ),
        );

    final restored = SpatialWorldState.fromJson(state.toJson());

    expect(restored, state);
    expect(restored.modelState('village', 'entrance'), opened());
    expect(restored.modelState('forest', 'entrance')!.blocksMovement, isTrue);
    expect(restored.modelState('other', 'entrance'), isNull);
    expect(restored.toJson()['schemaVersion'], 1);
  });

  test('state owns immutable copies and leaves previous snapshots intact', () {
    final source = <String, Map<String, SpatialModelRuntimeState>>{
      'village': {'entrance': opened()},
    };
    final state = SpatialWorldState(modelsByMap: source);
    source['village']!.clear();
    source.clear();

    expect(state.modelState('village', 'entrance'), opened());
    expect(state.removeModelState('absent', 'entrance'), same(state));
    expect(() => state.modelsByMap.clear(), throwsUnsupportedError);
    expect(() => state.modelsByMap['village']!.clear(), throwsUnsupportedError);
    final removed = state.removeModelState('village', 'entrance');
    expect(removed, const SpatialWorldState.empty());
    expect(state.modelState('village', 'entrance'), opened());
  });

  test(
    'strict saves and SaveData preserve decor poses and reject absent state',
    () {
      final original = GameState(
        saveId: 'save',
        currentMapId: 'village',
        spatialWorldState: const SpatialWorldState.empty().setModelState(
          'village',
          'entrance',
          opened(),
        ),
      );
      final json = strictGameStateSaveJson(original);
      expect(
        gameStateFromStrictSaveJson(json).spatialWorldState,
        original.spatialWorldState,
      );
      expect(
        gameStateFromSaveData(
          saveDataFromGameState(original),
        ).spatialWorldState,
        original.spatialWorldState,
      );
      final missing = Map<String, dynamic>.from(json)
        ..remove('spatialWorldState');
      expect(() => gameStateFromStrictSaveJson(missing), throwsFormatException);
      expect(
        () => gameStateFromStrictSaveJson({
          ...json,
          'spatialWorldState': {
            ...original.spatialWorldState.toJson(),
            'schemaVersion': 2,
          },
        }),
        throwsFormatException,
      );
    },
  );

  test(
    'pose rejects nonfinite or out of range clocks and animation indexes',
    () {
      for (final time in [double.nan, double.infinity, -.001, 1.001]) {
        expect(
          () => SpatialModelRuntimeState(
            modelId: 'door',
            animationIndex: 0,
            normalizedTime: time,
            blocksMovement: false,
          ),
          throwsFormatException,
        );
      }
      expect(
        () => SpatialModelRuntimeState(
          modelId: 'door',
          animationIndex: -1,
          normalizedTime: 1,
          blocksMovement: false,
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'actor destinations are typed, isolated and persisted with decor poses',
    () {
      final pose = SpatialActorRuntimeState(
        x: 2.25,
        z: 3.5,
        facing: EntityFacing.east,
      );
      final state = const SpatialWorldState.empty()
          .setActorState('village', 'guide', pose)
          .setModelState('village', 'door', opened());
      expect(SpatialWorldState.fromJson(state.toJson()), state);
      expect(state.actorState('village', 'guide'), pose);
      expect(state.actorState('forest', 'guide'), isNull);
      expect(
        () => SpatialActorRuntimeState(x: -1, z: 3, facing: EntityFacing.south),
        throwsFormatException,
      );
    },
  );

  test('documents reject missing, unknown and unsupported fields', () {
    final valid = const SpatialWorldState.empty().toJson();
    for (final json in [
      <String, dynamic>{},
      {...valid, 'schemaVersion': 2},
      {...valid, 'extra': true},
      {
        ...valid,
        'modelsByMap': <String, dynamic>{'village': []},
      },
      {
        ...valid,
        'modelsByMap': {
          'village': {
            'entrance': {...opened().toJson(), 'blocksMovement': 'false'},
          },
        },
      },
    ]) {
      expect(() => SpatialWorldState.fromJson(json), throwsFormatException);
    }
    expect(
      () =>
          const SpatialWorldState.empty().setModelState('', 'entry', opened()),
      throwsFormatException,
    );
  });

  test('one-shot decor command carries its terminal collision decision', () {
    final command = SceneInteractiveCommand.playModelAnimation(
      mapId: 'village',
      instanceId: 'entrance',
      animationIndex: 0,
      speed: 2,
      blocksMovementAfter: false,
    );

    expect(SceneInteractiveCommand.fromJson(command.toJson()), command);
    expect(command.outputPortIds, ['completed', 'blocked', 'cancelled']);
    expect(command.toJson()['blocksMovementAfter'], false);
    expect(
      () => SceneInteractiveCommand.playModelAnimation(
        mapId: 'village',
        instanceId: 'entrance',
        animationIndex: 0,
        speed: 0,
      ),
      throwsFormatException,
    );
  });
}
