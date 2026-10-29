import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import 'render_request.dart';

const renderPixelRatio = 2.0;
const sceneReadyTimeout = Duration(minutes: 3);

final class RenderFailure implements Exception {
  const RenderFailure(this.code, this.message);

  final String code;
  final String message;
}

typedef RenderFunction = Future<Map<String, Object?>> Function(RenderRequest request);
typedef ScanFunction = Future<Map<String, Object?>> Function(ScanRequest request);

final class RenderHost {
  RenderHost(this._render, {this.scan});

  final RenderFunction _render;
  final ScanFunction? scan;

  Future<void> serve(Stream<List<int>> input, IOSink output) async {
    await for (final line in input.transform(utf8.decoder).transform(const LineSplitter())) {
      if (line.trim().isEmpty) continue;
      final response = await handle(line);
      output.writeln(jsonEncode(response));
      await output.flush();
      if (response['command'] == 'shutdown') return;
    }
  }

  Future<Map<String, Object?>> handle(String line) async {
    Object? id;
    String? command;
    try {
      final decoded = jsonDecode(line);
      if (decoded is! Map<String, Object?>) {
        throw const RenderRequestException('A request must be a JSON object.');
      }
      id = decoded['id'];
      command = decoded['command'] as String?;
      if (id is! String || id.isEmpty) {
        throw const RenderRequestException('id must be a non-empty string.');
      }
      final args = decoded['args'] ?? const <String, Object?>{};
      if (args is! Map<String, Object?>) {
        throw const RenderRequestException('args must be a JSON object.');
      }
      final data = switch (command) {
        'ping' => const <String, Object?>{'ready': true},
        'shutdown' => const <String, Object?>{'stopping': true},
        'render' => await _render(RenderRequest.fromJson(args)),
        'scan' when scan != null => await scan!(ScanRequest.fromJson(args)),
        _ => throw RenderRequestException('Unknown command: $command.'),
      };
      return {'id': id, 'command': command, 'status': 'success', 'data': data};
    } on RenderRequestException catch (error) {
      return _failure(id, command, 'render.request_invalid', error.message);
    } on FormatException catch (error) {
      return _failure(id, command, 'render.request_invalid', error.message);
    } on RenderFailure catch (error) {
      return _failure(id, command, error.code, error.message);
    } on AuthoringQueryException catch (error) {
      return _failure(id, command, error.code, error.message);
    } on CatalogStorageException catch (error) {
      return _failure(id, command, error.code, error.message);
    } on Object catch (error) {
      return _failure(id, command, 'render.failed', '$error');
    }
  }
}

Map<String, Object?> _failure(Object? id, String? command, String code, String message) => {
      'id': id is String ? id : null,
      'command': command,
      'status': 'failure',
      'error': {'code': code, 'message': message},
    };

final class SpatialMapRenderer {
  SpatialMapRenderer({required this.boundaryKey, required this.content, required this.errors});

  final GlobalKey boundaryKey;
  final ValueNotifier<Widget> content;
  final List<String> errors;

  Future<Map<String, Object?>> render(RenderRequest request) => _withMap(
        request.projectRoot,
        request.mapId,
        (view, scene, loadedAt, clock) => _renderView(request, view, scene, loadedAt, clock),
      );

  Future<Map<String, Object?>> scan(ScanRequest request) => _withMap(
        request.projectRoot,
        request.mapId,
        (view, scene, loadedAt, clock) => _scanView(request, view, scene, loadedAt, clock),
      );

  Future<Map<String, Object?>> _withMap(
    String projectRoot,
    String mapId,
    Future<Map<String, Object?>> Function(
            AuthoringMapView view, MapSpatialScene scene, int loadedAt, Stopwatch clock)
        body,
  ) async {
    errors.clear();
    final clock = Stopwatch()..start();
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(allowedRootPaths: [projectRoot], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final read = AuthoringReadApi(
      openService: ProjectOpenService(policy: policy, fileReader: reader, handles: handles),
      snapshotLoader: ProjectSnapshotLoader(handles: handles),
    );
    final opened = await read.openProject(projectRoot);
    try {
      final view = await read.readMapView(opened.projectHandle, mapId);
      final scene = view.map.spatialScene;
      if (scene == null) {
        throw RenderFailure('render.map_not_spatial', 'Map $mapId has no 3D scene.');
      }
      return await body(view, scene, clock.elapsedMilliseconds, clock);
    } finally {
      content.value = const SizedBox.shrink();
      await read.closeWorkspace(opened.workspaceHandle);
    }
  }

  Future<Map<String, Object?>> _renderView(RenderRequest request, AuthoringMapView view,
      MapSpatialScene scene, int loadedAt, Stopwatch clock) async {
      final controller = _controller(request.view, request.magnification, request.minuteOfDay);
      _panTo(controller, view.map, request.centerX, request.centerZ);
      await _mount(view, scene, controller, request.projectFile,
          background: const Color(0xff242b31), magnification: () => request.magnification);
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      final image = await _snapshot();
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(request.outputPath).writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
        return {
          'mapId': view.map.id,
          'revision': view.revision,
          'width': image.width,
          'height': image.height,
          'view': request.view.name,
          'center': {
            'x': request.centerX ?? view.map.size.width / 2,
            'z': request.centerZ ?? view.map.size.height / 2,
          },
          'magnification': request.magnification,
          'minuteOfDay': request.minuteOfDay,
          'instanceCount': scene.instances.length,
          'loadMilliseconds': loadedAt,
          'elapsedMilliseconds': clock.elapsedMilliseconds,
          'errors': List<String>.of(errors),
          'outputPath': request.outputPath,
        };
      } finally {
        image.dispose();
      }
  }

  SpatialSceneController _controller(MapRenderView view, double magnification, double minuteOfDay) {
    final controller = SpatialSceneController()
      ..setView(switch (view) {
        MapRenderView.game => SpatialEditorView.game,
        MapRenderView.top => SpatialEditorView.top,
        MapRenderView.orbit => SpatialEditorView.orbit,
      })
      ..depthOfFieldEnabled = false
      ..previewMinuteOfDay = minuteOfDay;
    if (view != MapRenderView.game) {
      controller.zoom = (1 / magnification).clamp(.125, 1 / .15);
    }
    return controller;
  }

  void _panTo(SpatialSceneController controller, MapData map, double? x, double? z) {
    final targetX = (x ?? map.size.width / 2) - map.size.width / 2;
    final targetZ = (z ?? map.size.height / 2) - map.size.height / 2;
    controller.panBy(targetX - controller.pan.dx, targetZ - controller.pan.dy);
  }

  Future<void> _mount(
    AuthoringMapView view,
    MapSpatialScene scene,
    SpatialSceneController controller,
    String Function(String relativePath) projectFile, {
    required Color background,
    required double Function() magnification,
  }) async {
    final map = view.map;
    final project = view.manifest;
    final elapsed = Stopwatch()..start();
    final ready = Completer<void>();
    content.value = SpatialSceneView(
      key: UniqueKey(),
      scene: scene,
      models: project.models3d,
      loadModel: (id) => File(projectFile(
              project.models3d.singleWhere((model) => model.id == id).relativePath))
          .readAsBytes(),
      controller: controller,
      onCell: (_, _) {},
      background: background,
      ground: const Color(0xff0c1013),
      edge: const Color(0xff0c1013),
      groundMap: map,
      groundProject: project,
      loadGroundImage: (id) => File(projectFile(
              project.tilesets.singleWhere((tileset) => tileset.id == id).relativePath))
          .readAsBytes(),
      presentationElapsedSeconds: () => elapsed.elapsedMicroseconds / 1000000,
      cameraMagnification: magnification,
      errorBuilder: (_, error) {
        errors.add('$error');
        return Text('$error', textDirection: TextDirection.ltr);
      },
      onReady: () {
        if (!ready.isCompleted) ready.complete();
      },
      selectContent: false,
    );
    try {
      await ready.future.timeout(sceneReadyTimeout);
    } on TimeoutException {
      throw RenderFailure('render.scene_timeout',
          'The 3D scene was not ready within ${sceneReadyTimeout.inSeconds} seconds.');
    }
  }

  Future<ui.Image> _snapshot() async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary = boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    return boundary.toImage(pixelRatio: renderPixelRatio);
  }

  Future<Map<String, Object?>> _scanView(ScanRequest request, AuthoringMapView view,
      MapSpatialScene scene, int loadedAt, Stopwatch clock) async {
    final report = inspectSpatialMapIntegrity(manifest: view.manifest, map: view.map);
    final targets = [
      for (final cluster in report.gapClusters)
        (kind: 'groundGap', x: cluster.centerX, z: cluster.centerZ, magnification: request.magnification, detail: cluster.toJson()),
      for (final overlap in report.borderObjectOverlaps)
        (
          kind: 'borderObjectOverlap',
          x: (overlap.firstCell.x + overlap.lastCell.x) / 2 + .5,
          z: (overlap.firstCell.y + overlap.lastCell.y) / 2 + .5,
          magnification: request.magnification,
          detail: overlap.toJson(),
        ),
    ].take(request.maxViews).toList();
    if (request.grid) {
      for (final (x, z) in gridViewCenters(view.map)) {
        targets.add((kind: 'grid', x: x, z: z, magnification: gridMagnification, detail: const {}));
      }
    }
    final views = <Map<String, Object?>>[];
    if (targets.isNotEmpty) {
      final controller = _controller(MapRenderView.game, request.magnification, 720);
      _panTo(controller, view.map, targets.first.x, targets.first.z);
      var magnification = targets.first.magnification;
      await _mount(view, scene, controller, request.projectFile,
          background: scanSentinel, magnification: () => magnification);
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      for (final (index, target) in targets.indexed) {
        _panTo(controller, view.map, target.x, target.z);
        magnification = target.magnification;
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await WidgetsBinding.instance.endOfFrame;
        final image = await _snapshot();
        try {
          final pixels = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
          final ratios = seeThroughRatios(pixels.buffer.asUint8List(), image.width, image.height);
          final kept = target.kind != 'grid' || ratios.holes > 0;
          final outputPath = '${request.outputDirectory}/${target.kind}-$index.png';
          if (kept) {
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            await File(outputPath).writeAsBytes(png!.buffer.asUint8List(), flush: true);
          }
          views.add({
            'kind': target.kind,
            'center': {'x': target.x, 'z': target.z},
            'magnification': target.magnification,
            'holeRatio': ratios.holes,
            'backgroundRatio': ratios.background,
            if (target.detail.isNotEmpty) 'target': target.detail,
            if (kept) 'outputPath': outputPath,
          });
        } finally {
          image.dispose();
        }
      }
    }
    return {
      'mapId': view.map.id,
      'revision': view.revision,
      'groundGapCount': report.groundGaps.length,
      'exposedCellCount': report.exposedCellCount,
      'unprovenCellCount': report.unprovenCellCount,
      'gapClusterCount': report.gapClusters.length,
      'borderObjectOverlapCount': report.borderObjectOverlaps.length,
      'viewCount': views.length,
      'gridViewCount': views.where((view) => view['kind'] == 'grid').length,
      'holeViewCount': views.where((view) => (view['holeRatio'] as double) > 0).length,
      'skippedTargetCount': report.gapClusters.length +
          report.borderObjectOverlaps.length -
          views.where((view) => view['kind'] != 'grid').length,
      'magnification': request.magnification,
      'views': views,
      'loadMilliseconds': loadedAt,
      'elapsedMilliseconds': clock.elapsedMilliseconds,
      'errors': List<String>.of(errors),
    };
  }
}

const scanSentinel = Color(0xffff00ff);
const gridMagnification = 2.0;
const _gridStepX = 20, _gridStepZ = 11;

/// Game-view centres tiling the cells any Smart Tile layer paints, so a
/// scan also looks where the integrity report finds nothing to frame.
List<(double, double)> gridViewCenters(MapData map) {
  final scene = map.spatialScene;
  if (scene == null) return const [];
  var minX = scene.width, maxX = -1, minZ = scene.depth, maxZ = -1;
  for (final layer in map.layers.whereType<SmartTileLayer>()) {
    final cells = layer.field.semanticCells;
    for (var index = 0; index < cells.length && index < scene.width * scene.depth; index++) {
      if (cells[index] == 0) continue;
      final x = index % scene.width, z = index ~/ scene.width;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (z < minZ) minZ = z;
      if (z > maxZ) maxZ = z;
    }
  }
  if (maxX < 0) return const [];
  List<double> axis(int min, int max, int step) {
    final span = max - min + 1;
    final count = (span / step).ceil();
    return [for (var i = 0; i < count; i++) min + span * (i + .5) / count];
  }
  return [
    for (final z in axis(minZ, maxZ, _gridStepZ))
      for (final x in axis(minX, maxX, _gridStepX)) (x, z),
  ];
}

/// Share of pixels showing the sentinel background: over the whole frame,
/// and only in patches the scene encloses. The map's outer void and the sky
/// reach the frame edge; a hole through the map does not.
({double background, double holes}) seeThroughRatios(Uint8List rgba, int width, int height) {
  if (width == 0 || height == 0) return (background: 0, holes: 0);
  final sentinel = Uint8List(width * height);
  var background = 0;
  for (var index = 0; index < width * height; index++) {
    final i = index * 4;
    if (rgba[i] > 240 && rgba[i + 1] < 16 && rgba[i + 2] > 240) {
      sentinel[index] = 1;
      background++;
    }
  }
  final pending = <int>[];
  void reach(int index) {
    if (sentinel[index] == 1) {
      sentinel[index] = 2;
      pending.add(index);
    }
  }
  for (var x = 0; x < width; x++) {
    reach(x);
    reach((height - 1) * width + x);
  }
  for (var y = 0; y < height; y++) {
    reach(y * width);
    reach(y * width + width - 1);
  }
  var reachable = 0;
  while (pending.isNotEmpty) {
    final index = pending.removeLast();
    reachable++;
    final x = index % width, y = index ~/ width;
    if (x > 0) reach(index - 1);
    if (x < width - 1) reach(index + 1);
    if (y > 0) reach(index - width);
    if (y < height - 1) reach(index + width);
  }
  final total = (width * height).toDouble();
  return (background: background / total, holes: (background - reachable) / total);
}
