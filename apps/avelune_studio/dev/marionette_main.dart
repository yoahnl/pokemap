import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:avelune_studio/app/studio_bootstrap.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:map_runtime/map_runtime.dart';

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
    if (params['reset'] == 'true') movement.reset();
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
        'x': movement.x,
        'z': movement.z,
        'y': movement.y,
        'facing': movement.facing.name,
        'moving': movement.moving,
        'paused': movement.paused,
        'diagonals': movement.allowDiagonalMovement,
        'focus': FocusManager.instance.primaryFocus?.toString(),
      }),
    );
  });
  runApp(StudioBootstrap(debugSession: session));
}
