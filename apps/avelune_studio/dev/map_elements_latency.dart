import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editor_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/platform/rendering/studio_map_visual_widgets.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_elements_panel.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_map_editor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flame/game.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:map_authoring/map_authoring_local.dart'
    show MapAuthoringWorkerDiagnostics;

import 'marionette_main.dart' as studio;
import 'save_disk_trace.dart';

({
  EditableMapDocument? document,
  MapEditorController? editor,
  MapWorkspaceController? workspace,
  StudioMapVisual? visual2d,
  Map<String, Object?> state,
})
readMapElementsState() {
  MapWorkspaceScreen? workspace;
  MapElementsPanel? panel;
  SpatialMapEditor? spatial;
  SpatialSceneController? renderer;
  StudioMapVisual? visual2d;
  Object? renderer2d;
  String? renderer2dDiagnosticError;
  dynamic sceneGame;
  void visit(Element element) {
    if (element.widget case Offstage(offstage: true)) return;
    switch (element.widget) {
      case MapWorkspaceScreen():
        workspace = element.widget as MapWorkspaceScreen;
      case MapElementsPanel():
        panel = element.widget as MapElementsPanel;
      case SpatialMapEditor():
        spatial = element.widget as SpatialMapEditor;
      case SpatialSceneView(:final controller):
        renderer = controller;
      case StudioMapVisual(preview: false):
        if (element is StatefulElement && element.state.mounted) {
          try {
            renderer2d = (element.state as dynamic).renderer as Object?;
            visual2d = element.widget as StudioMapVisual;
          } on Object catch (error) {
            renderer2dDiagnosticError = error.runtimeType.toString();
          }
        }
      case GameWidget(:final game):
        if (game.runtimeType.toString() == 'SpatialSceneGame') sceneGame = game;
      default:
        break;
    }
    element.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
  final document =
      panel?.document ?? workspace?.controller.active ?? spatial?.document;
  final editor = document?.editor;
  final visibility3d = sceneGame == null
      ? null
      : sceneGame!.configuration.visibility as SpatialSceneVisibility;
  return (
    document: document,
    editor: editor,
    workspace: workspace?.controller,
    visual2d: visual2d,
    state: {
      'pid': pid,
      'profile': kProfileMode,
      'debug': kDebugMode,
      'projectPath': editor?.session.directoryPath,
      'mapId': editor?.mapId,
      'mapName': document?.current.name,
      'panelMounted': panel != null,
      'spatial': document?.current.spatialScene != null,
      'mapDirty': document?.dirty,
      'mapSaving': document?.saving,
      'mapRevision': document?.base.revision,
      'selectedId': spatial?.view.target?.id ?? panel?.view.target?.id,
      'mapIdentity': document == null
          ? null
          : identityHashCode(document.current),
      'sceneIdentity': document?.current.spatialScene == null
          ? null
          : identityHashCode(document!.current.spatialScene!),
      'rendererIdentity': renderer == null ? null : identityHashCode(renderer!),
      'renderer2dIdentity': renderer2d == null
          ? null
          : identityHashCode(renderer2d!),
      'renderer2dResourcesIdentity': visual2d == null
          ? null
          : identityHashCode(visual2d!.resources),
      'renderer2dImagesIdentity': visual2d == null
          ? null
          : identityHashCode(visual2d!.resources.images),
      'renderer2dImageIdentities': visual2d == null
          ? null
          : {
              for (final entry in visual2d!.resources.images.entries)
                entry.key: identityHashCode(entry.value),
            },
      'renderer2dDecodedBytes': visual2d?.resources.decodedBytes,
      'renderer2dDiagnosticError': renderer2dDiagnosticError,
      'saving': editor?.saving,
      'dirty': editor?.dirty,
      'error': editor?.error,
      'state': editor?.current.toJson(),
      'modelCount': document?.current.spatialScene?.instances.length,
      'decorCount': document?.current.placedElements.length,
      'layerIds': document?.current.layers.map((layer) => layer.id).toList(),
      'rendererGeneration': sceneGame?.generation,
      'visualOrderUpdates': sceneGame?.visualOrderUpdates,
      'visualGroundRebuilds': sceneGame?.visualGroundRebuilds,
      'visibilityUpdates': sceneGame?.visibilityUpdates,
      'visibilityGroundRebuilds': sceneGame?.visibilityGroundRebuilds,
      'visibility3d': visibility3d == null
          ? null
          : {
              'hiddenContent': [
                for (final (kind, id) in visibility3d.hiddenContent)
                  '${kind.name}:$id',
              ]..sort(),
              'hiddenKinds': [
                for (final kind in visibility3d.hiddenKinds) kind.name,
              ]..sort(),
              'hiddenLayers': visibility3d.hiddenLayers.toList()..sort(),
            },
      'modelPresentationVisible': sceneGame == null
          ? null
          : {
              for (final entry in sceneGame!.modelComponents.entries)
                entry.key: entry.value.component.presentationVisible,
            },
      'modelComponentIdentities': sceneGame == null
          ? null
          : {
              for (final entry in sceneGame!.modelComponents.entries)
                entry.key: identityHashCode(entry.value.component),
            },
      'animationModelIdentities': sceneGame == null
          ? null
          : {
              for (final entry in sceneGame!.animationModels.entries)
                '${entry.key}': identityHashCode(entry.value),
            },
      'actorMeshIdentities': sceneGame == null
          ? null
          : {
              for (final entry in sceneGame!.actors.entries)
                entry.key: identityHashCode(entry.value.mesh),
            },
      'actorPresentationVisible': sceneGame == null
          ? null
          : {
              for (final entry in sceneGame!.actors.entries)
                entry.key: entry.value.mesh.isVisible(sceneGame!.camera),
            },
      'pointLightBindingsIdentity': sceneGame == null
          ? null
          : identityHashCode(sceneGame!.pointLightBindings),
      'authoredLightingIdentity': sceneGame == null
          ? null
          : identityHashCode(sceneGame!.authoredLighting),
    },
  );
}

Future<void> main() async {
  const root = String.fromEnvironment('MARIONETTE_PROJECT_PATH');
  final workerTraces = <Object?>[];
  final workerPort = ReceivePort();
  workerPort.listen(workerTraces.add);
  MapAuthoringWorkerDiagnostics.port = workerPort.sendPort;
  final trace = SaveDiskTrace(root);
  await trace.run(studio.main);
  Map<String, Object?> measurement = {};
  MapEditorController? observed;
  VoidCallback? observedListener;
  PointerRoute? observedPointer;
  MapWorkspaceController? observedWorkspace;
  void clearObserver() {
    if (observed != null && observedListener != null) {
      observed!.removeListener(observedListener!);
    }
    if (observedWorkspace != null && observedListener != null) {
      observedWorkspace!.removeListener(observedListener!);
    }
    observedWorkspace = null;
    if (observedPointer != null) {
      GestureBinding.instance.pointerRouter.removeGlobalRoute(observedPointer!);
    }
    observed = null;
    observedListener = null;
    observedPointer = null;
  }

  developer.registerExtension(
    'ext.flutter.avelune.mapElementsState',
    (method, parameters) async => developer.ServiceExtensionResponse.result(
      jsonEncode(readMapElementsState().state),
    ),
  );
  developer.registerExtension('ext.flutter.avelune.mapElementsAwaitResources', (
    method,
    parameters,
  ) async {
    final view = readMapElementsState();
    await view.visual2d?.resources.settled;
    return developer.ServiceExtensionResponse.result(
      jsonEncode({
        'waitedFor2dResources': view.visual2d != null,
        'state': readMapElementsState().state,
      }),
    );
  });
  developer.registerExtension('ext.flutter.avelune.mapElementsUi', (
    method,
    parameters,
  ) async {
    final found = <String, List<({Element element, Rect bounds})>>{};
    void visit(Element element) {
      if (element.widget case Offstage(offstage: true)) return;
      final key = element.widget.key;
      if (key is ValueKey<String>) {
        final render = element.findRenderObject();
        if (render is RenderBox && render.hasSize && render.attached) {
          final bounds = render.localToGlobal(Offset.zero) & render.size;
          if (bounds.width > 0 && bounds.height > 0) {
            found.putIfAbsent(key.value, () => []).add((
              element: element,
              bounds: bounds,
            ));
          }
        }
      }
      element.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
    if (parameters['command'] == 'tap' || parameters['command'] == 'drag') {
      final project = readMapElementsState().editor?.session.directoryPath;
      if (project != root) {
        throw StateError('The requested disposable project must be active.');
      }
      final matches = found[parameters['key']] ?? [];
      if (matches.length != 1) {
        throw StateError('A unique mounted key is required.');
      }
      final drag = parameters['command'] == 'drag';
      final targetMatches = found[parameters['targetKey']] ?? [];
      if (drag && targetMatches.length != 1) {
        throw StateError('Unique mounted drag target required.');
      }
      final bounds = matches.single.bounds;
      final position = drag
          ? Offset(bounds.left + 20, bounds.center.dy)
          : bounds.center;
      final target = drag ? targetMatches.single.bounds.center : position;
      final pointer = drag ? 81026 : 81025;
      final downEpochUs = DateTime.now().microsecondsSinceEpoch;
      final down = PointerDownEvent(
        pointer: pointer,
        position: position,
        kind: PointerDeviceKind.mouse,
      );
      observedPointer?.call(down);
      GestureBinding.instance.handlePointerEvent(down);
      if (drag) {
        for (var step = 1; step <= 16; step++) {
          await Future<void>.delayed(const Duration(milliseconds: 12));
          GestureBinding.instance.handlePointerEvent(
            PointerMoveEvent(
              pointer: pointer,
              position: Offset.lerp(position, target, step / 16)!,
              delta: (target - position) / 16,
              kind: PointerDeviceKind.mouse,
            ),
          );
        }
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }
      final upEpochUs = DateTime.now().microsecondsSinceEpoch;
      final up = PointerUpEvent(
        pointer: pointer,
        position: target,
        kind: PointerDeviceKind.mouse,
      );
      observedPointer?.call(up);
      GestureBinding.instance.handlePointerEvent(up);
      return developer.ServiceExtensionResponse.result(
        jsonEncode({
          'tappedKey': parameters['key'],
          'targetKey': parameters['targetKey'],
          'pointer': pointer,
          'downEpochUs': downEpochUs,
          'upEpochUs': upEpochUs,
          'x': position.dx,
          'y': position.dy,
          'state': readMapElementsState().state,
        }),
      );
    }
    return developer.ServiceExtensionResponse.result(
      jsonEncode({
        'state': readMapElementsState().state,
        'keys': [
          for (final entry in found.entries)
            if (entry.key.startsWith('map-') || entry.key.startsWith('layer:'))
              {
                'key': entry.key,
                'matches': entry.value.length,
                'bounds': [
                  for (final item in entry.value)
                    [
                      item.bounds.left,
                      item.bounds.top,
                      item.bounds.width,
                      item.bounds.height,
                    ],
                ],
              },
        ],
      }),
    );
  });
  developer.registerExtension('ext.flutter.avelune.mapElementsMeasure', (
    method,
    parameters,
  ) async {
    if (parameters['command'] == 'arm') {
      clearObserver();
      final view = readMapElementsState();
      final editor = view.editor;
      if (editor == null ||
          editor.session.directoryPath != root ||
          editor.saving ||
          editor.dirty) {
        throw StateError(
          'An idle clean map editor in the configured disposable project is required.',
        );
      }
      final before = editor.current;
      final pointerWatch = Stopwatch();
      final stateWatch = Stopwatch();
      var changed = false;
      var frameReady = false;
      var durable = false;
      measurement = {
        'label': parameters['label'],
        'status': 'armed',
        'before': view.state,
      };
      void finish() {
        if (!durable || !frameReady) return;
        measurement['status'] = 'complete';
        clearObserver();
      }

      observedPointer = (event) {
        if (event is PointerDownEvent && event.pointer != 81025) {
          measurement['externalPointer'] = event.pointer;
        }
        if (event is PointerDownEvent &&
            event.pointer == 81025 &&
            !pointerWatch.isRunning) {
          measurement['pointer'] = event.pointer;
          measurement.putIfAbsent(
            'downEpochUs',
            () => DateTime.now().microsecondsSinceEpoch,
          );
          pointerWatch.start();
        }
        if (event is PointerUpEvent && event.pointer == 81025) {
          measurement.putIfAbsent(
            'upEpochUs',
            () => DateTime.now().microsecondsSinceEpoch,
          );
        }
      };
      GestureBinding.instance.pointerRouter.addGlobalRoute(observedPointer!);
      observed = editor;
      observedListener = () {
        if (!changed && editor.current != before) {
          changed = true;
          stateWatch.start();
          measurement['changed'] = readMapElementsState().state;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            frameReady = true;
            measurement['stateChangeToFrameUs'] =
                stateWatch.elapsedMicroseconds;
            measurement['pointerDownToFrameUs'] = pointerWatch.isRunning
                ? pointerWatch.elapsedMicroseconds
                : null;
            measurement['frameState'] = readMapElementsState().state;
            finish();
          });
          WidgetsBinding.instance.scheduleFrame();
        }
        if (changed && !editor.saving && !editor.dirty) {
          durable = true;
          measurement['stateChangeToDurableUs'] =
              stateWatch.elapsedMicroseconds;
          measurement['pointerDownToDurableUs'] = pointerWatch.isRunning
              ? pointerWatch.elapsedMicroseconds
              : null;
          measurement['state'] = readMapElementsState().state;
          measurement['disk'] = trace.snapshot();
          measurement['workerDisk'] = workerTraces.toList();
          trace.armed = false;
          finish();
        }
        if (editor.error != null) {
          measurement['status'] = 'failed';
          measurement['state'] = readMapElementsState().state;
          trace.armed = false;
          clearObserver();
        }
      };
      editor.addListener(observedListener!);
      workerTraces.clear();
      trace.arm();
    }
    return developer.ServiceExtensionResponse.result(jsonEncode(measurement));
  });
  developer.registerExtension('ext.flutter.avelune.mapElementsOrderMeasure', (
    method,
    parameters,
  ) async {
    if (parameters['command'] == 'arm') {
      clearObserver();
      final view = readMapElementsState();
      final document = view.document;
      final workspace = view.workspace;
      if (document == null ||
          workspace == null ||
          document.dirty ||
          document.saving ||
          workspace.session.directoryPath != root) {
        throw StateError('Clean disposable workspace required.');
      }
      final before = document.current;
      final revision = document.base.revision;
      final upWatch = Stopwatch();
      final stateWatch = Stopwatch();
      var changed = false;
      var durable = false;
      var frameReady = false;
      measurement = {
        'status': 'armed',
        'label': parameters['label'],
        'before': view.state,
      };
      void finish() {
        if (durable && frameReady) {
          measurement['status'] = 'complete';
          clearObserver();
        }
      }

      observedPointer = (event) {
        if (event is PointerDownEvent) {
          if (event.pointer != 81026) {
            measurement['externalPointer'] = event.pointer;
          }
          measurement['pointer'] = event.pointer;
          measurement.putIfAbsent(
            'downEpochUs',
            () => DateTime.now().microsecondsSinceEpoch,
          );
        }
        if (event is PointerUpEvent &&
            event.pointer == 81026 &&
            !upWatch.isRunning) {
          upWatch.start();
          measurement.putIfAbsent(
            'upEpochUs',
            () => DateTime.now().microsecondsSinceEpoch,
          );
        }
      };
      GestureBinding.instance.pointerRouter.addGlobalRoute(observedPointer!);
      observedWorkspace = workspace;
      observedListener = () {
        if (!changed && !identical(document.current, before)) {
          changed = true;
          stateWatch.start();
          measurement['changed'] = readMapElementsState().state;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            frameReady = true;
            measurement['pointerUpToFrameUs'] = upWatch.isRunning
                ? upWatch.elapsedMicroseconds
                : null;
            measurement['stateChangeToFrameUs'] =
                stateWatch.elapsedMicroseconds;
            measurement['frameState'] = readMapElementsState().state;
            finish();
          });
          WidgetsBinding.instance.scheduleFrame();
        }
        if (changed &&
            !document.saving &&
            !document.dirty &&
            document.base.revision != revision) {
          durable = true;
          measurement['pointerUpToDurableUs'] = upWatch.isRunning
              ? upWatch.elapsedMicroseconds
              : null;
          measurement['stateChangeToDurableUs'] =
              stateWatch.elapsedMicroseconds;
          measurement['state'] = readMapElementsState().state;
          measurement['disk'] = trace.snapshot();
          measurement['workerDisk'] = workerTraces.toList();
          trace.armed = false;
          finish();
        }
        if (document.error != null) {
          measurement['status'] = 'failed';
          measurement['error'] = document.error;
          trace.armed = false;
          clearObserver();
        }
      };
      workspace.addListener(observedListener!);
      workerTraces.clear();
      trace.arm();
    }
    measurement['workerDisk'] = workerTraces.toList();
    return developer.ServiceExtensionResponse.result(jsonEncode(measurement));
  });
  developer.registerExtension(
    'ext.flutter.avelune.mapElementsOrderVerifyDisk',
    (method, parameters) async {
      final view = readMapElementsState();
      final document = view.document;
      if (document == null ||
          document.dirty ||
          document.saving ||
          view.workspace?.session.directoryPath != root) {
        throw StateError('Durable disposable workspace required.');
      }
      trace.armed = false;
      final bytes = await File('$root/maps/${document.current.id}.json')
          .readAsBytes();
      final disk = MapData.fromJson(
        jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
      );
      return developer.ServiceExtensionResponse.result(
        jsonEncode({
          'matchesDisk': disk == document.current,
          'matchesRevision':
              narrativeEventBytesFingerprint(bytes) == document.base.revision,
          'diskLayers': disk.layers.map((layer) => layer.id).toList(),
          'bytes': bytes.length,
          'state': view.state,
        }),
      );
    },
  );
  developer.registerExtension('ext.flutter.avelune.mapElementsVerifyDisk', (
    method,
    parameters,
  ) async {
    final view = readMapElementsState();
    final editor = view.editor;
    if (editor == null ||
        editor.session.directoryPath != root ||
        editor.saving ||
        editor.dirty) {
      throw StateError(
        'A durable map editor in the configured disposable project is required.',
      );
    }
    trace.armed = false;
    final path = '$root/${MapEditorDocument.relativePathForMap(editor.mapId)}';
    final bytes = await File(path).readAsBytes();
    final disk = MapEditorDocument.fromJson(
      jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
    );
    final reopened = await editor.port.loadEditorState(
      editor.session,
      editor.mapId,
    );
    return developer.ServiceExtensionResponse.result(
      jsonEncode({
        'path': path,
        'bytes': bytes.length,
        'diskState': disk.state.toJson(),
        'reopenedState': reopened.state.toJson(),
        'matchesDisk': disk.state == editor.current,
        'matchesReopened': reopened.state == editor.current,
        'state': view.state,
      }),
    );
  });
}
