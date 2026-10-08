import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_3d/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/src/spatial_scene_components.dart';

final class _SceneProbe extends Component {
  _SceneProbe(this.id, this.rendered, {this.loading});

  final String id;
  final List<String> rendered;
  final Completer<void>? loading;

  @override
  FutureOr<void> onLoad() => loading?.future;

  @override
  void render(Canvas canvas) => rendered.add(id);
}

Future<FlameGame<World3D>> _mountedGame(WidgetTester tester) async {
  final game = FlameGame<World3D>(world: World3D());
  game.camera.world = null;
  await tester.pumpWidget(GameWidget(game: game));
  await tester.pump();
  await tester.runAsync(game.ready);
  return game;
}

List<String> _render(World3D world, List<String> rendered) {
  rendered.clear();
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  for (final child in world.children) {
    child.renderTree(canvas);
  }
  recorder.endRecording().dispose();
  return List.of(rendered);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('connected maps retain mounted components when promoted', (
    tester,
  ) async {
    final game = await _mountedGame(tester);
    final scene = SpatialSceneComponents(game.world);
    final rendered = <String>[];
    final village = _SceneProbe('village', rendered);
    final forest = _SceneProbe('forest', rendered);
    final first = scene.replaceGroups({
      'village': [village],
      'forest': [forest],
    });
    await tester.runAsync(game.ready);
    expect(await tester.runAsync(() => first), isTrue);
    final originalVillageParent = village.parent;
    final originalForestParent = forest.parent;
    final next = scene.replaceGroups({
      'forest': [forest],
      'village': [village],
    });
    await tester.runAsync(game.ready);
    expect(await tester.runAsync(() => next), isTrue);
    expect(village.parent, same(originalVillageParent));
    expect(forest.parent, same(originalForestParent));
    expect(_render(game.world, rendered), ['village', 'forest']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('pending neighbor keeps retained and previous maps visible', (
    tester,
  ) async {
    final game = await _mountedGame(tester);
    final scene = SpatialSceneComponents(game.world);
    final rendered = <String>[];
    final village = _SceneProbe('village', rendered);
    final forest = _SceneProbe('forest', rendered);
    final first = scene.replaceGroups({
      'village': [village],
      'forest': [forest],
    });
    await tester.runAsync(game.ready);
    await tester.runAsync(() => first);
    final gate = Completer<void>();
    final next = scene.replaceGroups({
      'forest': [forest],
      'clearing': [_SceneProbe('clearing', rendered, loading: gate)],
    });
    game.update(0);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    game.update(0);
    expect(_render(game.world, rendered), ['village', 'forest']);
    gate.complete();
    await tester.runAsync(game.ready);
    expect(await tester.runAsync(() => next), isTrue);
    expect(_render(game.world, rendered), ['forest', 'clearing']);
    await tester.runAsync(game.ready);
    expect(game.world.descendants(), isNot(contains(village)));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('cancelled neighbor never removes retained map components', (
    tester,
  ) async {
    final game = await _mountedGame(tester);
    final scene = SpatialSceneComponents(game.world);
    final rendered = <String>[];
    final forest = _SceneProbe('forest', rendered);
    final first = scene.replaceGroups({
      'forest': [forest],
    });
    await tester.runAsync(game.ready);
    await tester.runAsync(() => first);
    final originalParent = forest.parent;
    final gate = Completer<void>();
    final stale = scene.replaceGroups({
      'forest': [forest],
      'clearing': [_SceneProbe('clearing', rendered, loading: gate)],
    });
    game.update(0);
    final latest = scene.replaceGroups({
      'forest': [forest],
    });
    gate.complete();
    await tester.runAsync(game.ready);
    expect(await tester.runAsync(() => stale), isFalse);
    expect(await tester.runAsync(() => latest), isTrue);
    expect(forest.parent, same(originalParent));
    expect(_render(game.world, rendered), ['forest']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('promoted map retains its current animated ground', (
    tester,
  ) async {
    final game = await _mountedGame(tester);
    final scene = SpatialSceneComponents(game.world);
    final rendered = <String>[];
    final oldGround = _SceneProbe('old-ground', rendered);
    final tree = _SceneProbe('tree', rendered);
    final source = [oldGround, tree];
    final first = scene.replaceGroups({'forest': source});
    await tester.runAsync(game.ready);
    await tester.runAsync(() => first);
    final animatedGround = _SceneProbe('animated-ground', rendered);
    scene.replaceSubset([oldGround], [animatedGround]);
    await tester.runAsync(game.ready);
    final promoted = scene.replaceGroups({'forest': source});
    await tester.runAsync(game.ready);
    expect(await tester.runAsync(() => promoted), isTrue);
    expect(_render(game.world, rendered), ['tree', 'animated-ground']);
    await tester.pumpWidget(const SizedBox());
  });

  test('initial scene commits before its world is mounted', () async {
    final world = World3D();
    final scene = SpatialSceneComponents(world);
    final rendered = <String>[];
    var committed = false;
    expect(
      await scene.replace([
        _SceneProbe('initial', rendered),
      ], onCommit: () => committed = true),
      isTrue,
    );
    expect(committed, isTrue);
    expect(_render(world, rendered), ['initial']);
  });

  testWidgets('an invalidated generation preserves the visible old scene', (
    tester,
  ) async {
    final game = await _mountedGame(tester);
    final scene = SpatialSceneComponents(game.world);
    final rendered = <String>[];
    final initial = scene.replace([_SceneProbe('old', rendered)]);
    await tester.runAsync(game.ready);
    await tester.runAsync(() => initial);
    var current = true;
    var committed = false;
    final replacing = scene.replace(
      [_SceneProbe('invalidated', rendered)],
      isCurrent: () => current,
      onCommit: () => committed = true,
    );
    current = false;
    await tester.runAsync(game.ready);
    expect(await tester.runAsync(() => replacing), isFalse);
    expect(committed, isFalse);
    expect(_render(game.world, rendered), ['old']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('old scene stays visible until all new children mount', (
    tester,
  ) async {
    final game = await _mountedGame(tester);
    final scene = SpatialSceneComponents(game.world);
    final rendered = <String>[];
    final initial = scene.replace([_SceneProbe('old', rendered)]);
    await tester.runAsync(game.ready);
    await tester.runAsync(() => initial);
    expect(_render(game.world, rendered), ['old']);
    final gate = Completer<void>();
    var committed = false;
    final replacing = scene.replace([
      _SceneProbe('new-loaded', rendered),
      _SceneProbe('new-delayed', rendered, loading: gate),
    ], onCommit: () => committed = true);
    game.update(0);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    game.update(0);
    expect(committed, isFalse);
    expect(_render(game.world, rendered), ['old']);
    gate.complete();
    await tester.runAsync(game.ready);
    expect(await tester.runAsync(() => replacing), isTrue);
    expect(committed, isTrue);
    expect(_render(game.world, rendered), ['new-loaded', 'new-delayed']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a superseded staged batch never becomes visible', (
    tester,
  ) async {
    final game = await _mountedGame(tester);
    final scene = SpatialSceneComponents(game.world);
    final rendered = <String>[];
    final initial = scene.replace([_SceneProbe('old', rendered)]);
    await tester.runAsync(game.ready);
    await tester.runAsync(() => initial);
    final gate = Completer<void>();
    var staleCommitted = false;
    final stale = scene.replace([
      _SceneProbe('stale', rendered, loading: gate),
    ], onCommit: () => staleCommitted = true);
    game.update(0);
    final latest = scene.replace([_SceneProbe('latest', rendered)]);
    gate.complete();
    await tester.runAsync(game.ready);
    expect(await tester.runAsync(() => stale), isFalse);
    expect(await tester.runAsync(() => latest), isTrue);
    expect(staleCommitted, isFalse);
    expect(_render(game.world, rendered), ['latest']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'scene replacement preserves actors and removes animated ground',
    (tester) async {
      final game = await _mountedGame(tester);
      final rendered = <String>[];
      final actor = _SceneProbe('actor', rendered);
      await game.world.add(actor);
      await tester.runAsync(game.ready);
      final scene = SpatialSceneComponents(game.world);
      final terrain = _SceneProbe('terrain', rendered);
      final ground = _SceneProbe('ground', rendered);
      final initial = scene.replace([terrain, ground]);
      await tester.runAsync(game.ready);
      await tester.runAsync(() => initial);
      scene.replaceSubset([ground], [_SceneProbe('animated', rendered)]);
      final replacement = scene.replace([_SceneProbe('replacement', rendered)]);
      await tester.runAsync(game.ready);
      await tester.runAsync(() => replacement);
      expect(_render(game.world, rendered), ['actor', 'replacement']);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
