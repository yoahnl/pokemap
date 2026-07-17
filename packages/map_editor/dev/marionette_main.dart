import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_editor/main.dart' show MapEditorApp;
import 'package:map_editor/src/debug/marionette_project_bootstrap.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

/// Debug-only entrypoint for deterministic, observable macOS QA.
void main() {
  // Marionette must be the sole binding initializer in this process.
  MarionetteBinding.ensureInitialized();

  const configuredProjectPath = String.fromEnvironment(
    MarionetteProjectBootstrap.projectPathDefine,
  );
  final bootstrap = MarionetteProjectBootstrap.load(configuredProjectPath);
  final initialState = bootstrap.createInitialState();
  final container = ProviderContainer(
    overrides: <Override>[
      editorNotifierProvider.overrideWith(
        () => _MarionetteSeededEditorNotifier(initialState),
      ),
    ],
  );

  // Force provider creation before runApp, then expose the live provider state
  // so the driver can prove that the rendered shell owns the expected copy.
  container.read(editorNotifierProvider);
  registerMarionetteExtension(
    name: 'pokemap.activeProjectPath',
    description: 'Returns the active and expected PokeMap project roots.',
    callback: (_) async {
      final activePath = container.read(editorNotifierProvider).projectRootPath;
      return MarionetteExtensionResult.success(<String, dynamic>{
        'activeProjectPath': activePath,
        'expectedProjectPath': bootstrap.projectRootPath,
        'matches': activePath == bootstrap.projectRootPath,
      });
    },
  );
  developer.registerExtension(
    'ext.flutter.pokemap.marionette.projectContext',
    (_, __) async {
      final editor = container.read(editorNotifierProvider);
      return developer.ServiceExtensionResponse.result(
        jsonEncode(<String, Object?>{
          'ready': editor.project != null,
          'projectRootPath': editor.projectRootPath,
          'projectName': editor.project?.name,
        }),
      );
    },
  );
  developer.registerExtension(
    'ext.flutter.pokemap.marionette.drawPolyline',
    (_, parameters) => _drawPolyline(parameters),
  );
  developer.registerExtension(
    'ext.flutter.pokemap.marionette.applyBorderPreviewAndSave',
    (_, parameters) async {
      final notifier = container.read(editorNotifierProvider.notifier);
      final layerId = parameters['layerId'];
      final featureId = parameters['featureId'];
      final hasTarget = layerId != null && featureId != null;
      if (hasTarget) {
        notifier.selectBorderFeature(
          layerId: layerId,
          featureId: featureId,
        );
      }
      final prepared = hasTarget
          ? notifier.previewBorderFeatureUpdate(
              layerId: layerId,
              featureId: featureId,
            )
          : false;
      final applied = prepared && notifier.applyPendingBorderPreview();
      final saveOutcome = applied ? await notifier.saveActiveMap() : null;
      final editor = container.read(editorNotifierProvider);
      return developer.ServiceExtensionResponse.result(
        jsonEncode(<String, Object?>{
          'prepared': prepared,
          'applied': applied,
          'saveOutcome': saveOutcome?.toString(),
          'activeMapId': editor.activeMap?.id,
          'errorMessage': editor.errorMessage,
          'statusMessage': editor.statusMessage,
        }),
      );
    },
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MapEditorApp(),
    ),
  );
}

/// Seeds only the debug container; production continues to use EditorNotifier.
final class _MarionetteSeededEditorNotifier extends EditorNotifier {
  _MarionetteSeededEditorNotifier(this.initialState);

  final EditorState initialState;

  @override
  EditorState build() => initialState;
}

Future<developer.ServiceExtensionResponse> _drawPolyline(
  Map<String, String> parameters,
) async {
  try {
    final rawPoints = parameters['points'];
    if (rawPoints == null) {
      throw const FormatException('Missing points JSON.');
    }
    final decoded = jsonDecode(rawPoints);
    if (decoded is! List || decoded.length < 2) {
      throw const FormatException('points must contain at least two entries.');
    }
    final points = decoded.map((entry) {
      if (entry is! Map) {
        throw const FormatException('Each point must be an object.');
      }
      final x = entry['x'];
      final y = entry['y'];
      if (x is! num || y is! num) {
        throw const FormatException('Each point needs numeric x and y.');
      }
      return Offset(x.toDouble(), y.toDouble());
    }).toList(growable: false);
    final spacing = math.max(
      1.0,
      double.tryParse(parameters['spacing'] ?? '') ?? 8.0,
    );
    final moveDelayMs = math.max(
      0,
      int.tryParse(parameters['moveDelayMs'] ?? '') ?? 8,
    );
    final buttons = switch (parameters['buttons']) {
      'secondary' => kSecondaryMouseButton,
      'tertiary' => kMiddleMouseButton,
      _ => kPrimaryMouseButton,
    };
    const pointer = 424242;
    const device = 424242;
    var previous = points.first;
    GestureBinding.instance.handlePointerEvent(
      PointerDownEvent(
        pointer: pointer,
        device: device,
        position: previous,
        kind: PointerDeviceKind.mouse,
        buttons: buttons,
      ),
    );
    await Future<void>.delayed(Duration(milliseconds: moveDelayMs));
    var emittedMoves = 0;
    for (var index = 1; index < points.length; index += 1) {
      final start = points[index - 1];
      final end = points[index];
      final distance = (end - start).distance;
      final steps = math.max(1, (distance / spacing).ceil());
      for (var step = 1; step <= steps; step += 1) {
        final next = Offset.lerp(start, end, step / steps)!;
        GestureBinding.instance.handlePointerEvent(
          PointerMoveEvent(
            pointer: pointer,
            device: device,
            position: next,
            delta: next - previous,
            kind: PointerDeviceKind.mouse,
            buttons: buttons,
          ),
        );
        previous = next;
        emittedMoves += 1;
        await Future<void>.delayed(Duration(milliseconds: moveDelayMs));
      }
    }
    GestureBinding.instance.handlePointerEvent(
      PointerUpEvent(
        pointer: pointer,
        device: device,
        position: previous,
        kind: PointerDeviceKind.mouse,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return developer.ServiceExtensionResponse.result(
      jsonEncode(<String, Object?>{
        'ok': true,
        'pointCount': points.length,
        'emittedMoves': emittedMoves,
      }),
    );
  } on Object catch (error, stackTrace) {
    return developer.ServiceExtensionResponse.result(
      jsonEncode(<String, Object?>{
        'ok': false,
        'error': error.toString(),
        'stackTrace': stackTrace.toString(),
      }),
    );
  }
}
