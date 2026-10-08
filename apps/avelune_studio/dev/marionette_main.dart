import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:avelune_studio/app/studio_bootstrap.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_map_editor.dart';
import 'package:avelune_studio/platform/playtest/studio_spatial_playtest_view.dart';
import 'package:avelune_studio/platform/playtest/studio_playtest_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:map_core/map_core.dart';

import 'spatial_frame_recorder.dart';

bool dispatchStudioTestKey(KeyEvent event) {
  HardwareKeyboard.instance.handleKeyEvent(event);
  return ServicesBinding.instance.keyEventManager.keyMessageHandler?.call(
        KeyMessage([event], null),
      ) ??
      false;
}

void applyStudioCaptureLifecycle(AppLifecycleState target) {
  final binding = WidgetsBinding.instance;
  final current = binding.lifecycleState;
  if (current == null || current == target) return;
  const nextStates = {
    AppLifecycleState.detached: [AppLifecycleState.resumed],
    AppLifecycleState.resumed: [AppLifecycleState.inactive],
    AppLifecycleState.inactive: [
      AppLifecycleState.resumed,
      AppLifecycleState.hidden,
    ],
    AppLifecycleState.hidden: [
      AppLifecycleState.inactive,
      AppLifecycleState.paused,
    ],
    AppLifecycleState.paused: [
      AppLifecycleState.hidden,
      AppLifecycleState.detached,
    ],
  };
  final routes = <List<AppLifecycleState>>[
    [current],
  ];
  final visited = <AppLifecycleState>{current};
  for (var index = 0; index < routes.length; index++) {
    final route = routes[index];
    for (final next in nextStates[route.last]!) {
      if (!visited.add(next)) continue;
      final extended = [...route, next];
      if (next == target) {
        for (final state in extended.skip(1)) {
          binding.handleAppLifecycleStateChanged(state);
        }
        return;
      }
      routes.add(extended);
    }
  }
  throw StateError('Unsupported Studio capture lifecycle transition.');
}

Future<void> main() async {
  if (!kDebugMode || !Platform.isMacOS) {
    throw StateError(
      'The spatial Studio harness requires a macOS debug build.',
    );
  }
  MarionetteBinding.ensureInitialized();
  const configuredCaptureRoot = String.fromEnvironment(
    'MARIONETTE_CAPTURE_ROOT',
  );
  final captureRoot = await requireStudioCaptureRoot(configuredCaptureRoot);
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
  final captureKey = GlobalKey();
  final recorder = StudioFrameRecorder(
    captureRoot: captureRoot,
    boundaryKey: captureKey,
    sourceMetadata: {
      'pid': pid,
      'platform': 'macOS',
      'host': 'Avelune Studio',
      'activeProject': root,
      'persistenceScope': 'studioTestCheckpoint',
      'durableSaveObserved': false,
      'sourcePaths': [
        'apps/avelune_studio/dev/marionette_main.dart',
        'apps/avelune_studio/dev/spatial_frame_recorder.dart',
        'apps/avelune_studio/lib/platform/playtest/studio_spatial_playtest_view.dart',
      ],
    },
  );
  AppLifecycleState? captureLifecycle;
  Timer? captureRefresh, captureLimit;
  void finishCaptureActivity() {
    captureRefresh?.cancel();
    captureLimit?.cancel();
    captureRefresh = captureLimit = null;
    if (captureLifecycle case final previous?) {
      applyStudioCaptureLifecycle(previous);
      captureLifecycle = null;
    }
  }

  developer.registerExtension('ext.flutter.avelune.captureActivity', (
    method,
    params,
  ) async {
    final enabled = params['enabled'] == 'true';
    if (enabled) {
      captureLifecycle ??= WidgetsBinding.instance.lifecycleState;
      captureRefresh?.cancel();
      captureLimit?.cancel();
      void refresh() {
        applyStudioCaptureLifecycle(AppLifecycleState.resumed);
        WidgetsBinding.instance.scheduleFrame();
      }

      refresh();
      captureRefresh = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => refresh(),
      );
      captureLimit = Timer(const Duration(minutes: 5), finishCaptureActivity);
    } else {
      finishCaptureActivity();
    }
    return developer.ServiceExtensionResponse.result(
      jsonEncode({
        'enabled': enabled,
        'host': 'Avelune Studio',
        'project': root,
        'scope': 'isolatedStudioCapture',
        'nativeLifecycleQualified': false,
        'lifecycle': WidgetsBinding.instance.lifecycleState?.name,
      }),
    );
  });
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
    SpatialExplorationGameSessionRuntime? runtime;
    StudioPlaytestView? playtest;
    FocusNode? playtestFocus;
    void visit(Element element) {
      final widget = element.widget;
      if (widget is SpatialExplorationView) exploration = widget.session;
      if (widget is StudioPlaytestView) playtest = widget;
      if (widget is StudioSpatialPlaytestView) {
        if (runtime != null && !identical(runtime, widget.runtime)) {
          throw StateError('More than one Studio spatial playtest is mounted.');
        }
        runtime = widget.runtime;
        void findFocus(Element child) {
          if (child.widget case Focus(focusNode: final node?)) {
            playtestFocus ??= node;
          }
          child.visitChildren(findFocus);
        }

        element.visitChildren(findFocus);
      }
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
    if (params.containsKey('reset') || params.containsKey('steps')) {
      return developer.ServiceExtensionResponse.error(
        developer.ServiceExtensionResponse.invalidParams,
        'Use bounded hardware keys through the real Studio playtest.',
      );
    }
    final currentRuntime = runtime;
    if (currentRuntime == null ||
        !identical(currentRuntime.session, current) ||
        session.state.project?.directoryPath != root ||
        current.bundle.projectRootDirectory != root) {
      return developer.ServiceExtensionResponse.error(
        developer.ServiceExtensionResponse.extensionError,
        'The exploration does not belong to the requested Studio project.',
      );
    }
    Map<String, Object?>? keyObservation;
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
        'primary' => (LogicalKeyboardKey.keyE, PhysicalKeyboardKey.keyE),
        'secondary' => (LogicalKeyboardKey.escape, PhysicalKeyboardKey.escape),
        'sprint' => (
          LogicalKeyboardKey.shiftLeft,
          PhysicalKeyboardKey.shiftLeft,
        ),
        _ => throw ArgumentError.value(name, 'key'),
      };
      final milliseconds = int.parse(params['milliseconds'] ?? '300');
      if (milliseconds < 1 || milliseconds > 2000) {
        throw ArgumentError.value(milliseconds, 'milliseconds');
      }
      final dispatch = dispatchStudioTestKey;
      final binding = WidgetsBinding.instance;
      final lifecycle = binding.lifecycleState;
      final captureInput = params['captureInput'] == 'true';
      if (captureInput) {
        if (playtestFocus == null) {
          throw StateError('Le focus du terrain de test est indisponible.');
        }
        applyStudioCaptureLifecycle(AppLifecycleState.resumed);
        playtestFocus!.requestFocus();
        await Future<void>.delayed(Duration.zero);
      }
      try {
        final downHandled = dispatch(
          KeyDownEvent(
            physicalKey: physical,
            logicalKey: logical,
            character: null,
            timeStamp: Duration.zero,
          ),
        );
        try {
          await Future<void>.delayed(Duration(milliseconds: milliseconds));
          keyObservation = {
            'mode': 'boundedTestKeyboard',
            'key': name,
            'milliseconds': milliseconds,
            'captureInput': captureInput,
            'downHandled': downHandled,
            'heldX': movement.x,
            'heldZ': movement.z,
            'heldPaused': movement.paused,
            'pressedKeys': HardwareKeyboard.instance.logicalKeysPressed
                .map((key) => key.debugName)
                .toList(),
          };
        } finally {
          dispatch(
            KeyUpEvent(
              physicalKey: physical,
              logicalKey: logical,
              timeStamp: Duration(milliseconds: milliseconds),
            ),
          );
        }
      } finally {
        if (captureInput && lifecycle != null) {
          applyStudioCaptureLifecycle(lifecycle);
        }
      }
    }
    final state = currentRuntime.gameStateSnapshot;
    final world = current.worldStateProvider?.call();
    final dialogue = current.dialoguePresentation.value;
    final interaction = currentRuntime.overworldInteractionSnapshot;
    final camera = current.storyCamera?.call();
    final hero = current.heroStoryPose?.call();
    final checkpoint = playtest?.testSession?.spatialSave;
    return developer.ServiceExtensionResponse.result(
      jsonEncode({
        'path': session.state.project?.directoryPath,
        'pid': pid,
        'host': 'Avelune Studio',
        'keyObservation': keyObservation,
        'persistenceScope': 'studioTestCheckpoint',
        'durableSaveObserved': false,
        'canonicalSave': checkpoint == null
            ? null
            : const SaveEnvelopeCodec().toJson(checkpoint),
        'canonicalSaveUnavailableReason': checkpoint == null
            ? 'No checkpoint has been saved in this Studio playtest.'
            : null,
        'recording': recorder.snapshot,
        'lifecycle': WidgetsBinding.instance.lifecycleState?.name,
        'sessionId': interaction?.sessionId,
        'mapActivationId': interaction?.mapActivationId,
        'inputContext': currentRuntime.inputAuthority.value.context.name,
        'inputLocks': currentRuntime.inputAuthority.value.externalLocks
            .map((lock) => lock.name)
            .toList(),
        'runtimeGameState': strictGameStateSaveJson(state),
        'worldPresentation': world?.toJson(),
        'actorPoses': {
          for (final entity in current.bundle.map.entities)
            if (current.actorRuntimeState(entity) case final pose?)
              entity.id: pose.toJson(),
        },
        'legacyNpcFacing': {
          for (final entry in current.npcFacing.entries)
            entry.key: entry.value.name,
        },
        'modelInstances': [
          for (final instance in current.bundle.map.spatialScene!.instances)
            {
              'instanceId': instance.id,
              'modelId': instance.modelId,
              'authoredBlocksMovement': instance.blocksMovement,
              'runtime': world
                  ?.modelState(current.bundle.map.id, instance.id)
                  ?.toJson(),
            },
        ],
        'cinematic': {
          'active': current.storyActive.value,
          'inputLocked': current.storyInputLocked,
          'camera': camera == null
              ? null
              : {
                  'x': camera.x,
                  'y': camera.y,
                  'z': camera.z,
                  'zoom': camera.zoom,
                },
          'heroPose': hero == null
              ? null
              : {
                  'x': hero.x,
                  'z': hero.z,
                  'facing': hero.facing.name,
                  'motion': hero.motion.name,
                  'animationSeconds': hero.animationSeconds,
                },
        },
        'interaction': interaction?.primaryAction?.toJson(),
        'dialogue': dialogue == null
            ? null
            : {
                'revision': dialogue.revision,
                'mode': dialogue.mode.name,
                'text': dialogue.text,
                'fullText': dialogue.fullText,
              },
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
  registerMarionetteExtension(
    name: 'avelune.recordingStart',
    description:
        'Records real Studio window PNG frames in its owned capture root.',
    callback: (parameters) async {
      final fps = int.tryParse(parameters['fps'] ?? '15');
      final duration = int.tryParse(parameters['maxDurationSeconds'] ?? '300');
      if (fps == null ||
          fps < 10 ||
          fps > 20 ||
          duration == null ||
          duration < 1 ||
          duration > 300) {
        return const MarionetteExtensionResult.invalidParams(
          'Use fps from 10 to 20 and maxDurationSeconds from 1 to 300.',
        );
      }
      if (session.state.project?.directoryPath != root) {
        return const MarionetteExtensionResult.error(
          0,
          'The active Studio project changed.',
        );
      }
      try {
        return MarionetteExtensionResult.success(
          await recorder.start(fps: fps, maxDurationSeconds: duration),
        );
      } on Object catch (error) {
        return MarionetteExtensionResult.error(0, error.toString());
      }
    },
  );
  registerMarionetteExtension(
    name: 'avelune.recordingStop',
    description: 'Stops Studio capture and flushes its timestamps and receipt.',
    callback: (_) async {
      try {
        return MarionetteExtensionResult.success(await recorder.stop());
      } on Object catch (error) {
        return MarionetteExtensionResult.error(0, error.toString());
      }
    },
  );
  runApp(
    RepaintBoundary(
      key: captureKey,
      child: StudioBootstrap(debugSession: session),
    ),
  );
}
