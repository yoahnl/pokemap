import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:avelune_rendering/avelune_rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_exterior_decoration_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_map_editor.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';

import 'save_disk_trace.dart';
import 'exterior_decoration_scene_probe.dart';

import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';

const qaRoot = '/Users/karim/Library/Caches/AveluneQA/exterior-decoration';
const projectRoot = '$qaRoot/jeu';
final boundaryKey = GlobalKey();
final sceneProbe = ExteriorDecorationSceneProbe();
final presentation = sceneProbe.presentation;
late MapWorkspaceController workspace;
late SaveDiskTrace disk;
String? handled;
bool busy = false;
final errors = <String>[];
final workerRows = <Object?>[];
final traceEnabled = Platform.environment['AVELUNE_QA_TRACE'] != 'off';
late ReceivePort workerDiagnostics;
int initializationMicroseconds = 0;

({SpatialMapEditor? editor, SpatialSceneView? scene}) activeView() =>
    sceneProbe.sourceView();

Future<void> main() async {
  AveluneWidgetsFlutterBinding.ensureInitialized();
  if (await Directory(projectRoot).resolveSymbolicLinks() != projectRoot) {
    throw StateError('Canonical owned QA project required');
  }
  final port = LocalMapWorkspaceAdapter();
  workerDiagnostics = ReceivePort()..listen(workerRows.add);
  MapAuthoringWorkerDiagnostics.port = traceEnabled
      ? workerDiagnostics.sendPort
      : null;
  const session = ProjectSession(
    sessionId: 'exterior_native',
    name: 'Exterior QA',
    directoryPath: projectRoot,
    storage: ProjectSessionStorage.workingCatalog,
  );
  workspace = MapWorkspaceController(session, port);
  disk = SaveDiskTrace(projectRoot);
  final initializeTimer = Stopwatch()..start();
  await disk.run(workspace.initialize);
  initializationMicroseconds = initializeTimer.elapsedMicroseconds;
  if (workspace.active?.current.id != 'route-30' || workspace.error != null) {
    throw StateError('QA map failed: ${workspace.error}');
  }
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    errors.add(details.exceptionAsString());
    previous?.call(details);
  };
  runApp(
    MaterialApp(
      theme: studioTheme(),
      home: RepaintBoundary(
        key: boundaryKey,
        child: ValueListenableBuilder<Widget?>(
          valueListenable: presentation,
          child: KeyedSubtree(
            key: sceneProbe.sourceKey,
            child: MapWorkspaceScreen(
              controller: workspace,
              loadVisuals: StudioMapResources.load,
              runtimeBuilder: (_, _, _) => const SizedBox(),
              onClose: () async {},
              registerExitGuard: (_) {},
            ),
          ),
          builder: (_, overlay, child) => Stack(
            children: [
              Offstage(
                offstage: overlay != null,
                child: TickerMode(enabled: overlay == null, child: child!),
              ),
              if (overlay != null) Positioned.fill(child: overlay),
            ],
          ),
        ),
      ),
    ),
  );
  Timer.periodic(const Duration(milliseconds: 150), (_) async {
    if (busy) {
      return;
    }
    final file = File('$qaRoot/control.json');
    if (!await file.exists()) {
      return;
    }
    busy = true;
    String? id;
    try {
      final command =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      id = command['id'] as String;
      if (handled == id) {
        return;
      }
      handled = id;
      final result = await execute(command);
      await File('$qaRoot/result.json')
          .writeAsString(jsonEncode({'id': id, 'ok': true, ...result}));
    } catch (error, stack) {
      await File('$qaRoot/result.json').writeAsString(
        jsonEncode({
          'id': id,
          'ok': false,
          'error': '$error',
          'stack': '$stack',
        }),
      );
    } finally {
      disk.armed = false;
      busy = false;
    }
  });
}

Future<Map<String, Object?>> execute(Map<String, dynamic> command) async {
  if (command['action'] == 'state') {
    return state();
  }
  final view = activeView();
  final editor = view.editor;
  final scene = view.scene;
  if (editor == null ||
      scene == null ||
      workspace.session.directoryPath != projectRoot) {
    throw StateError('Owned Studio canvas required');
  }
  switch (command['action']) {
    case 'editor':
      await sceneProbe.restoreEditor();
    case 'presentation':
      final camera = SpatialSceneController()..setView(SpatialEditorView.game);
      camera.visualProfile = scene.controller.visualProfile;
      camera.atmosphereProfile = scene.controller.atmosphereProfile;
      if (command['sharp'] == true) camera.depthOfFieldEnabled = false;
      camera.previewMinuteOfDay =
          (command['minute'] as num?)?.toDouble() ?? 720;
      camera.panBy(
        (command['x'] as num).toDouble(),
        (command['z'] as num).toDouble(),
      );
      final native = SpatialSceneView(
        key: UniqueKey(),
        scene: scene.scene,
        models: scene.models,
        onCell: (x, z) {},
        actorFrames: scene.actorFrames,
        background: scene.background,
        ground: scene.ground,
        edge: scene.edge,
        errorBuilder: scene.errorBuilder,
        loadModel: scene.loadModel,
        controller: camera,
        groundMap: scene.groundMap,
        groundProject: scene.groundProject,
        loadGroundImage: scene.loadGroundImage,
        neighbors: scene.neighbors,
        decorations: command['decorated'] == true
            ? scene.decorations
            : const [],
        sceneOffset: scene.sceneOffset,
        cameraMagnification: () =>
            (command['magnification'] as num?)?.toDouble() ?? 1,
        selectContent: false,
      );
      await sceneProbe.show(native, (command['aspect'] as num).toDouble());

    case 'measureFrames':
      return {...await sceneProbe.measureFrames(), ...state()};

    case 'camera':
      final displayed = sceneProbe.displayedScene!;
      displayed.controller.setView(SpatialEditorView.game);
      final x = (command['x'] as num).toDouble(),
          z = (command['z'] as num).toDouble();
      if (x.abs() > 100 || z.abs() > 100) {
        throw StateError('Bounded camera required');
      }
      displayed.controller.panBy(
        x - displayed.controller.pan.dx,
        z - displayed.controller.pan.dy,
      );
      displayed.controller.previewMinuteOfDay =
          (command['minute'] as num?)?.toDouble() ?? 720;
      editor.onChanged();
    case 'hide':
      workspace.active!.exteriorDecoration?.dispose();
      workspace.active!.exteriorDecoration = null;
      workspace.notify();
    case 'reload':
      final decoration = await MapExteriorDecorationController.open(
        workspace.session,
        workspace.active!.current,
        workspace.port as LocalMapWorkspaceAdapter,
      );
      final previous = workspace.active!.exteriorDecoration;
      workspace.active!.exteriorDecoration = decoration;
      previous?.dispose();
      workspace.notify();
    case 'capture':
      WidgetsBinding.instance.scheduleFrame();
      await WidgetsBinding.instance.endOfFrame;
      final render =
          boundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final name = command['name'] as String;
      if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(name)) {
        throw StateError('Safe capture name required');
      }
      await File('$qaRoot/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    case 'stroke':
      if (sceneProbe.presentedScene != null) await sceneProbe.restoreEditor();
      final prepareTimer = Stopwatch()..start();
      while (activeView().editor?.exteriorContextReady != true) {
        if (prepareTimer.elapsed > const Duration(seconds: 10)) {
          throw StateError('Native neighbor context not ready');
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      final exterior = workspace.active!.exteriorDecoration!;
      exterior.setEditingExterior(true);
      final preset = editor.project.smartTileCatalog.presets.singleWhere(
        (preset) => preset.id == command['presetId'],
      );
      editor.view.prepareTerrainPainting(preset);
      if (command['erase'] == true) editor.view.tool = StudioMapTool.erase;
      if (command['materialId'] case final String material) {
        if (!preset.allowedMaterialIds.contains(material)) {
          throw StateError('Unknown material');
        }
        editor.view.terrainMaterialId = material;
      }
      editor.onChanged();
      WidgetsBinding.instance.scheduleFrame();
      await WidgetsBinding.instance.endOfFrame;
      if (editor.visuals case final StudioMapResources visuals) {
        await visuals.settled;
        await WidgetsBinding.instance.endOfFrame;
      }
      final canvas = activeView().scene!;
      final x = (command['x'] as num).toInt(),
          z = (command['z'] as num).toInt();
      final beforeStats = canvas.controller.decorationStats;
      final preparation = prepareTimer.elapsedMicroseconds;
      final workerStart = workerRows.length;
      if (traceEnabled) disk.arm();
      final timer = Stopwatch()..start();
      final target = canvas.resolveAuthoringTarget!(x, z);
      if (target == null) {
        throw StateError('Exterior point rejected');
      }
      final started = activeView().scene!.onDragStart!(
        x - target.offset.dx.toInt(),
        z - target.offset.dy.toInt(),
        null,
      );
      if (!started) {
        throw StateError('Native stroke rejected');
      }
      activeView().scene!.onDragEnd!();
      editor.onChanged();
      WidgetsBinding.instance.scheduleFrame();
      await WidgetsBinding.instance.endOfFrame;
      while (true) {
        final stats = activeView().scene!.controller.decorationStats;
        if (stats.ready &&
            stats.committedRevision > beforeStats.committedRevision &&
            stats.sectorBuilds > beforeStats.sectorBuilds) {
          break;
        }
        if (timer.elapsed > const Duration(seconds: 10)) {
          throw StateError('Changed native decoration did not commit: $stats');
        }
        await Future<void>.delayed(const Duration(milliseconds: 5));
        WidgetsBinding.instance.scheduleFrame();
      }
      await WidgetsBinding.instance.endOfFrame;
      final feedback = timer.elapsedMicroseconds;
      timer.reset();
      await exterior.save();
      final saved = timer.elapsedMicroseconds;
      disk.armed = false;
      if (exterior.dirty || exterior.error != null) {
        throw StateError('Native save failed ${exterior.error}');
      }
      return {
        'traceEnabled': traceEnabled,
        'feedbackMicroseconds': feedback,
        'durableMicroseconds': saved,
        'gestureToDurableMicroseconds': feedback + saved,
        'toolPreparationMicroseconds': preparation,
        'workerDiagnostics': workerRows.skip(workerStart).toList(),
        'disk': disk.snapshot(),
        ...state(),
      };
    case 'state':
      break;
    default:
      throw StateError('Unknown QA action');
  }
  return state();
}

Map<String, Object?> state() {
  final source = activeView();
  final scene = sceneProbe.displayedScene;
  final exterior = workspace.active?.exteriorDecoration;
  final texts = <String>[];
  void visit(Element element) {
    if (element.widget case Text(:final data?) when texts.length < 100) {
      texts.add(data);
    }
    element.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
  return {
    'texts': texts,
    'workspaceError': workspace.error,
    'initializationMicroseconds': initializationMicroseconds,
    'pid': pid,
    'project': workspace.session.directoryPath,
    'mapId': workspace.active?.current.id,
    'sourceSceneAvailable': source.scene != null,
    'sourceDecorationDefinitions': source.scene?.decorations.length,
    'sceneAvailable': scene != null,
    'cameraPan': scene == null
        ? null
        : [scene.controller.pan.dx, scene.controller.pan.dy],
    ...sceneProbe.snapshot(),
    'decorationSectors': exterior?.current?.sectors.length,
    'revision': exterior?.revision,
    'receiptId': exterior?.lastReceiptId,
    'dirty': exterior?.dirty,
    'error': exterior?.error,
    'errors': errors,
  };
}
