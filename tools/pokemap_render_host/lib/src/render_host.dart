import 'dart:async';
import 'dart:convert';
import 'dart:io';
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

final class RenderHost {
  RenderHost(this._render);

  final RenderFunction _render;

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

  Future<Map<String, Object?>> render(RenderRequest request) async {
    errors.clear();
    final clock = Stopwatch()..start();
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(allowedRootPaths: [request.projectRoot], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final read = AuthoringReadApi(
      openService: ProjectOpenService(policy: policy, fileReader: reader, handles: handles),
      snapshotLoader: ProjectSnapshotLoader(handles: handles),
    );
    final opened = await read.openProject(request.projectRoot);
    try {
      final view = await read.readMapView(opened.projectHandle, request.mapId);
      final loadedAt = clock.elapsedMilliseconds;
      final scene = view.map.spatialScene;
      if (scene == null) {
        throw RenderFailure('render.map_not_spatial', 'Map ${request.mapId} has no 3D scene.');
      }
      final image = await _capture(request, view, scene);
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
    } finally {
      content.value = const SizedBox.shrink();
      await read.closeWorkspace(opened.workspaceHandle);
    }
  }

  Future<ui.Image> _capture(RenderRequest request, AuthoringMapView view, MapSpatialScene scene) async {
    final map = view.map;
    final project = view.manifest;
    final controller = SpatialSceneController()
      ..setView(switch (request.view) {
        MapRenderView.game => SpatialEditorView.game,
        MapRenderView.top => SpatialEditorView.top,
        MapRenderView.orbit => SpatialEditorView.orbit,
      })
      ..depthOfFieldEnabled = false
      ..previewMinuteOfDay = request.minuteOfDay;
    if (request.view != MapRenderView.game) {
      controller.zoom = (1 / request.magnification).clamp(.125, 1 / .15);
    }
    controller.panBy(
      (request.centerX ?? map.size.width / 2) - map.size.width / 2,
      (request.centerZ ?? map.size.height / 2) - map.size.height / 2,
    );
    final elapsed = Stopwatch()..start();
    final ready = Completer<void>();
    content.value = SpatialSceneView(
      key: UniqueKey(),
      scene: scene,
      models: project.models3d,
      loadModel: (id) => File(request.projectFile(
              project.models3d.singleWhere((model) => model.id == id).relativePath))
          .readAsBytes(),
      controller: controller,
      onCell: (_, _) {},
      background: const Color(0xff242b31),
      ground: const Color(0xff0c1013),
      edge: const Color(0xff0c1013),
      groundMap: map,
      groundProject: project,
      loadGroundImage: (id) => File(request.projectFile(
              project.tilesets.singleWhere((tileset) => tileset.id == id).relativePath))
          .readAsBytes(),
      presentationElapsedSeconds: () => elapsed.elapsedMicroseconds / 1000000,
      cameraMagnification: () => request.magnification,
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
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    await WidgetsBinding.instance.endOfFrame;
    final boundary = boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    return boundary.toImage(pixelRatio: renderPixelRatio);
  }
}
