import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:avelune_studio/app/studio_bootstrap.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_map_editor.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_render_3d/map_render_3d.dart';

Future<void> main() async {
  MarionetteBinding.ensureInitialized();
  const configured = String.fromEnvironment('MARIONETTE_PROJECT_PATH');
  if (configured.isEmpty) {
    throw StateError('MARIONETTE_PROJECT_PATH is required');
  }
  final root = await Directory(configured).resolveSymbolicLinks();
  if (root != configured) {
    throw StateError('The project path must be canonical: $root');
  }
  final session = ProjectSessionController(LocalProjectSessionAdapter());
  await session.open(root);
  final active = session.state.project;
  if (active == null || active.directoryPath != root) {
    throw StateError('The requested project could not be opened: $root');
  }
  developer.registerExtension('ext.flutter.avelune.activeProject', (
    method,
    params,
  ) async {
    return developer.ServiceExtensionResponse.result(
      jsonEncode({'path': session.state.project?.directoryPath}),
    );
  });
  developer.registerExtension('ext.flutter.avelune.spatialEditorState', (
    method,
    params,
  ) async {
    SpatialMapEditor? editor;
    SpatialSceneView? canvas;
    Element? canvasElement;
    void visit(Element element) {
      final widget = element.widget;
      if (widget is SpatialMapEditor) editor = widget;
      if (widget is SpatialSceneView) {
        canvas = widget;
        canvasElement = element;
      }
      element.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
    final current = editor;
    final scene = canvas;
    if (current == null || scene == null) {
      return developer.ServiceExtensionResponse.result('{"available":false}');
    }
    final box = canvasElement?.findRenderObject();
    final bounds = box is RenderBox
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    return developer.ServiceExtensionResponse.result(
      jsonEncode({
        'available': true,
        'mapId': current.document.current.id,
        'tool': current.view.tool.name,
        'undoCount': current.document.undoCount,
        'dirty': current.document.dirty,
        'placement': scene.placementPreview == null
            ? null
            : {
                'modelId': scene.placementPreview!.modelId,
                'position': scene.placementPreview!.position.toJson(),
              },
        'instances': current.document.current.spatialScene!.instances
            .map((instance) => instance.toJson())
            .toList(),
        'gameCamera': current.document.current.spatialScene!.camera.toJson(),
        'editorCamera': {
          'view': scene.controller.view.name,
          'yaw': scene.controller.yaw,
          'pitch': scene.controller.pitch,
        },
        'overlays': scene.cellOverlays
            .map(
              (overlay) => {
                'cell': [overlay.cell.$1, overlay.cell.$2],
                'kind': overlay.kind.name,
                'targetHeight': overlay.targetHeight,
              },
            )
            .toList(),
        'ramps': scene.scene.navigation.ramps
            .map((ramp) => ramp.toJson())
            .toList(),
        'error': current.document.error,
        'bounds': bounds == null
            ? null
            : {
                'x': bounds.left,
                'y': bounds.top,
                'width': bounds.width,
                'height': bounds.height,
              },
      }),
    );
  });
  developer.registerExtension('ext.flutter.avelune.spatialExploration', (
    method,
    params,
  ) async {
    SpatialExplorationSession? exploration;
    void visit(Element element) {
      final widget = element.widget;
      if (widget is SpatialExplorationView) exploration = widget.session;
      element.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
    final current = exploration;
    if (current == null) {
      return developer.ServiceExtensionResponse.error(
        developer.ServiceExtensionResponse.extensionError,
        'Aucune exploration 3D active.',
      );
    }
    final movement = current.movement;
    if (params['reset'] == 'true') current.resetPosition();
    if (params['key'] case final name?) {
      final (logical, physical) = switch (name) {
        'north' => (LogicalKeyboardKey.arrowUp, PhysicalKeyboardKey.arrowUp),
        'south' => (
          LogicalKeyboardKey.arrowDown,
          PhysicalKeyboardKey.arrowDown,
        ),
        'west' => (LogicalKeyboardKey.arrowLeft, PhysicalKeyboardKey.arrowLeft),
        'east' => (
          LogicalKeyboardKey.arrowRight,
          PhysicalKeyboardKey.arrowRight,
        ),
        _ => throw ArgumentError.value(name, 'key'),
      };
      final milliseconds = int.parse(params['milliseconds'] ?? '300');
      if (milliseconds < 1 || milliseconds > 2000) {
        throw ArgumentError.value(milliseconds, 'milliseconds');
      }
      final dispatch = ui.PlatformDispatcher.instance.onKeyData;
      if (dispatch == null) throw StateError('Clavier non initialisé.');
      final binding = WidgetsBinding.instance;
      final lifecycle = binding.lifecycleState;
      final captureInput = params['captureInput'] == 'true';
      if (captureInput) {
        binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      }
      try {
        dispatch(
          ui.KeyData(
            type: ui.KeyEventType.down,
            physical: physical.usbHidUsage,
            logical: logical.keyId,
            character: null,
            timeStamp: Duration.zero,
            synthesized: true,
          ),
        );
        try {
          await Future<void>.delayed(Duration(milliseconds: milliseconds));
        } finally {
          dispatch(
            ui.KeyData(
              type: ui.KeyEventType.up,
              physical: physical.usbHidUsage,
              logical: logical.keyId,
              character: null,
              timeStamp: Duration(milliseconds: milliseconds),
              synthesized: true,
            ),
          );
        }
      } finally {
        if (captureInput && lifecycle != null) {
          binding.handleAppLifecycleStateChanged(lifecycle);
        }
      }
    }
    if (params['steps'] case final steps?) {
      final count = int.parse(steps);
      final x = int.parse(params['x'] ?? '0');
      final z = int.parse(params['z'] ?? '0');
      if (count < 0 || count > 400 || x.abs() > 1 || z.abs() > 1) {
        return developer.ServiceExtensionResponse.error(
          developer.ServiceExtensionResponse.invalidParams,
          'Déplacement borné requis.',
        );
      }
      movement.setInput(x: x, z: z, run: params['run'] == 'true');
      for (var index = 0; index < count; index++) {
        movement.update(.05);
      }
      movement.releaseInput();
    }
    return developer.ServiceExtensionResponse.result(
      jsonEncode({
        'path': session.state.project?.directoryPath,
        'mapId': current.bundle.map.id,
        'x': current.movement.x,
        'z': current.movement.z,
        'y': current.movement.y,
        'facing': current.movement.facing.name,
        'moving': current.movement.moving,
        'paused': current.movement.paused,
        'mapRevision': current.mapRevision.value,
        'transitioning': current.transitioning.value,
        'error': current.interactionError.value?.toString(),
        'diagonals': movement.allowDiagonalMovement,
        'focus': FocusManager.instance.primaryFocus?.toString(),
      }),
    );
  });
  runApp(StudioBootstrap(debugSession: session));
}
