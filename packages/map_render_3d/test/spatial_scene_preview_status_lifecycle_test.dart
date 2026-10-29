import 'dart:typed_data';

import 'package:flame_3d/graphics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';

void main() {
  testWidgets('gameplay-zone edits retain the materialized scene and only update overlays', (tester) async {
    final key = GlobalKey();
    final controller = SpatialSceneController();
    addTearDown(controller.dispose);
    final before = MapData(id: 'map', name: 'Map', version: ProjectVersion.v9,
      size: const GridSize(width: 4, height: 4), spatialScene: MapSpatialScene(width: 4, depth: 4));
    Future<Uint8List> loadModel(String _) async => Uint8List(0);
    Widget view(MapData map) => Directionality(textDirection: TextDirection.ltr,
      child: SpatialSceneView(key: key, scene: map.spatialScene!, groundMap: map,
        models: const [], loadModel: loadModel, controller: controller, onCell: (_, _) {},
        errorBuilder: (_, error) => Text('$error'),
        background: const Color(0xff000000), ground: const Color(0xff000000), edge: const Color(0xff000000)));
    await tester.pumpWidget(view(before));
    _UnusedBackend();
    final dynamic state = key.currentState;
    final game = _RecordingSceneGame(tester.widget<SpatialSceneView>(find.byType(SpatialSceneView)));
    state.game = game;
    state.failure = StateError('No GPU needed to observe invalidation');
    final after = before.copyWith(gameplayZones: const [MapGameplayZone(id: 'water', kind: GameplayZoneKind.movement,
      area: MapRect(pos: GridPos(x: 0, y: 0), size: GridSize(width: 2, height: 2)),
      movement: MovementZonePayload(requiredMode: MovementMode.surf))]);
    await tester.pumpWidget(view(after));
    expect(game.refreshCalls, 0);
    expect(game.configuration.groundMap, same(after));
    final raised = after.copyWith(spatialScene: after.spatialScene!.copyWith(heightLevels: List.filled(16, 1)));
    await tester.pumpWidget(view(raised));
    expect(game.refreshCalls, 1);
  });
  testWidgets('placement preview recovery can clear its error from layout', (
    tester,
  ) async {
    final fixture = _Fixture();
    addTearDown(fixture.controller.dispose);
    await tester.pumpWidget(fixture.widget());
    final dynamic state = fixture.key.currentState;
    _UnusedBackend();
    final game = SpatialSceneGame(
      tester.widget<SpatialSceneView>(find.byType(SpatialSceneView)),
      onPreviewStatus: (status) => state.handlePreviewStatus(status),
      onSurfaceChanged: () {},
    )..sceneReady = true;
    addTearDown(game.onRemove);
    Future<void>? clearing;
    fixture.onLayout = () => clearing = game.syncPlacementPreview();
    state.failure = StateError('Renderer unavailable in the widget harness');
    state.handlePreviewStatus(StateError('Previous placement failed'));
    await tester.pump();
    await clearing;
    expect(tester.takeException(), isNull);
    expect(state.previewFailure, isNull);
    expect(game.placementRenderer.component, isNull);
  });

  testWidgets(
    'renderer status from a descendant LayoutBuilder is published safely',
    (tester) async {
      final fixture = _Fixture();
      addTearDown(fixture.controller.dispose);
      await tester.pumpWidget(fixture.widget());
      final dynamic state = fixture.key.currentState;
      final status = StateError('Texture preparation failed');
      fixture.onLayout = () => state.handlePreviewStatus(status);
      state.failure = StateError('Renderer unavailable in the widget harness');
      state.handlePreviewStatus(StateError('Earlier preview status'));

      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(state.previewFailure, same(status));
      expect(fixture.layoutCalls, 1);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(state.previewFailure, same(status));
    },
  );

  testWidgets('latest renderer error or recovery wins within a build frame', (
    tester,
  ) async {
    final fixture = _Fixture();
    addTearDown(fixture.controller.dispose);
    await tester.pumpWidget(fixture.widget());
    final dynamic state = fixture.key.currentState;
    final first = StateError('First failure');
    final latest = StateError('Latest failure');
    fixture.onLayout = () {
      state.handlePreviewStatus(first);
      state.handlePreviewStatus(null);
      state.handlePreviewStatus(latest);
    };
    state.failure = StateError('Renderer unavailable in the widget harness');
    state.handlePreviewStatus(first);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(state.previewFailure, same(latest));

    fixture.onLayout = () {
      state.handlePreviewStatus(first);
      state.handlePreviewStatus(null);
    };
    state.handlePreviewStatus(first);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(state.previewFailure, isNull);
  });

  testWidgets('a late renderer status cannot rebuild a disposed viewport', (
    tester,
  ) async {
    final fixture = _Fixture();
    addTearDown(fixture.controller.dispose);
    await tester.pumpWidget(fixture.widget());
    final dynamic state = fixture.key.currentState;
    state.handlePreviewStatus(StateError('Visible failure'));
    await tester.pumpWidget(const SizedBox());
    state.handlePreviewStatus(StateError('Late failure'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

final class _RecordingSceneGame extends SpatialSceneGame {
  _RecordingSceneGame(SpatialSceneView configuration) : super(configuration,
    onPreviewStatus: (_) {}, onSurfaceChanged: () {});
  int refreshCalls = 0;
  @override
  Future<bool> refresh() async { refreshCalls++; return false; }
}

final class _UnusedBackend extends GpuBackend {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

final class _Fixture {
  final key = GlobalKey();
  final controller = SpatialSceneController();
  VoidCallback? onLayout;
  int layoutCalls = 0;

  Widget widget() => Directionality(
    textDirection: TextDirection.ltr,
    child: SpatialSceneView(
      key: key,
      scene: MapSpatialScene(width: 2, depth: 2),
      models: const [],
      loadModel: (_) async => Uint8List(0),
      controller: controller,
      onCell: (_, _) {},
      background: const Color(0xff000000),
      ground: const Color(0xff000000),
      edge: const Color(0xff000000),
      errorBuilder: (context, error) => LayoutBuilder(
        builder: (context, constraints) {
          final callback = onLayout;
          onLayout = null;
          if (callback != null) {
            layoutCalls++;
            callback();
          }
          return Text('$error');
        },
      ),
    ),
  );
}
