import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  late SpatialModelAnimationController controller;
  var canClose = true;
  late List<SpatialWorldState> commits;

  setUp(() {
    canClose = true;
    commits = [];
    controller = SpatialModelAnimationController(
      mapId: () => 'village',
      instances: () => [
        SpatialModelInstance(
          id: 'door',
          modelId: 'door-model',
          position: Model3dVector3(x: 3, y: 0, z: 4),
          blocksMovement: true,
        )
      ],
      models: () => [
        ProjectModel3dEntry(
          id: 'door-model',
          name: 'Porte',
          sourceAssetId: 'nb2-door',
          relativePath: 'assets/models3d/door-model.glb',
          inspection: Model3dInspection(
            bounds: Model3dBounds(
                min: Model3dVector3.zero,
                max: Model3dVector3(x: 1, y: 2, z: 1)),
            meshCount: 1,
            triangleCount: 2,
            animations: [
              Model3dAnimation(index: 0, name: 'Ouvrir', durationSeconds: 2)
            ],
          ),
        )
      ],
      state: const SpatialWorldState.empty(),
      canClose: (_) => canClose,
      commit: commits.add,
    );
  });

  tearDown(() => controller.dispose());

  final open = ScenePlayModelAnimationInteractiveCommand(
    mapId: 'village',
    instanceId: 'door',
    animationIndex: 0,
    blocksMovementAfter: false,
  );

  test('one-shot progresses by frames and commits collision only at completion',
      () async {
    final result = controller.play(open);
    controller.update(.5);
    expect(controller.worldState.modelState('village', 'door')!.normalizedTime,
        .25);
    expect(controller.worldState.modelState('village', 'door')!.blocksMovement,
        isTrue);
    expect(commits, isEmpty);
    controller.update(1.5);
    expect(await result, 'completed');
    expect(commits.single.modelState('village', 'door')!.normalizedTime, 1);
    expect(
        commits.single.modelState('village', 'door')!.blocksMovement, isFalse);
    controller.update(100);
    expect(commits, hasLength(1));
  });

  test(
      'pause freezes the clock and cancellation restores prior pose and collision',
      () async {
    final result = controller.play(open);
    controller.update(.5);
    controller.update(20, paused: true);
    expect(controller.worldState.modelState('village', 'door')!.normalizedTime,
        .25);
    controller.cancel();
    expect(await result, 'cancelled');
    expect(controller.worldState, const SpatialWorldState.empty());
    expect(commits, isEmpty);
  });

  test('unknown clip, wrong map and overlapping operation are blocked',
      () async {
    expect(
        await controller.play(ScenePlayModelAnimationInteractiveCommand(
            mapId: 'elsewhere', instanceId: 'door', animationIndex: 0)),
        'blocked');
    expect(
        await controller.play(ScenePlayModelAnimationInteractiveCommand(
            mapId: 'village', instanceId: 'door', animationIndex: 9)),
        'blocked');
    final pending = controller.play(open);
    expect(await controller.play(open), 'blocked');
    controller.cancel();
    expect(await pending, 'cancelled');
  });

  test('closure refuses actor overlap both before and after playback',
      () async {
    final close = ScenePlayModelAnimationInteractiveCommand(
      mapId: 'village',
      instanceId: 'door',
      animationIndex: 0,
      blocksMovementAfter: true,
    );
    canClose = false;
    expect(await controller.play(close), 'blocked');
    canClose = true;
    final pending = controller.play(close);
    controller.update(.5);
    canClose = false;
    controller.update(2);
    expect(await pending, 'blocked');
    expect(controller.worldState, const SpatialWorldState.empty());
    expect(commits, isEmpty);
  });
}
