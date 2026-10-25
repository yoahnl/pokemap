import 'dart:convert';
import 'dart:developer' as developer;

import 'package:avelune_studio/features/map_workspace/application/map_atmosphere_controller.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_atmosphere_settings_panel.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_map_editor.dart';
import 'package:flutter/widgets.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:map_runtime/map_runtime.dart';

import 'marionette_main.dart' as studio;
import 'save_disk_trace.dart';

({MapAtmosphereController? settings, Map<String, Object?> state}) readState() {
  MapAtmosphereController? settings;
  SpatialMapEditor? editor;
  SpatialSceneController? renderer;
  SpatialExplorationView? runtime;
  void visit(Element element) {
    switch (element.widget) {
      case MapAtmosphereSettingsPanel(:final controller):
        settings = controller;
      case SpatialMapEditor():
        editor = element.widget as SpatialMapEditor;
      case SpatialSceneView(:final controller):
        renderer = controller;
      case SpatialExplorationView():
        runtime = element.widget as SpatialExplorationView;
      default:
        break;
    }
    element.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
  return (
    settings: settings,
    state: {
      'available': settings != null,
      'projectPath': settings?.session.directoryPath,
      'mapId': settings?.mapId,
      'dirty': settings?.dirty,
      'saving': settings?.saving,
      'error': settings?.error,
      'draft': settings?.current.toJson(),
      'saved': settings?.saved.toJson(),
      'revision': settings?.revision,
      'mapDocumentDirty': editor?.document.dirty,
      'mapDocumentIdentity': editor == null
          ? null
          : identityHashCode(editor!.document.current),
      'rendererProfileIdentity': renderer == null
          ? null
          : identityHashCode(renderer!.atmosphereProfile),
      'renderer': renderer == null
          ? null
          : {
              'water': renderer!.waterAnimated,
              'windows': renderer!.windowsLit,
              'fireflies': renderer!.fireflies,
              'minute': renderer!.previewMinuteOfDay,
            },
      'runtime': runtime == null
          ? null
          : {
              'projectPath': runtime!.session.bundle.projectRootDirectory,
              'mapId': runtime!.session.bundle.map.id,
              'settings': runtime!.session.bundle.spatialAtmosphereSettings
                  .toJson(),
            },
    },
  );
}

Future<void> main() async {
  const root = String.fromEnvironment('MARIONETTE_PROJECT_PATH');
  final trace = SaveDiskTrace(root);
  await trace.run(studio.main);
  Map<String, Object?> measurement = {};
  Map<String, Object?> feedback = {};
  MapAtmosphereController? observed;
  VoidCallback? listener;
  developer.registerExtension('ext.flutter.avelune.atmosphereState', (
    method,
    parameters,
  ) async {
    return developer.ServiceExtensionResponse.result(
      jsonEncode(readState().state),
    );
  });
  developer.registerExtension('ext.flutter.avelune.atmosphereMeasure', (
    method,
    parameters,
  ) async {
    if (parameters['action'] == 'feedback') {
      final controller = readState().settings!;
      final before = controller.current;
      feedback = {'status': 'armed'};
      late VoidCallback onChange;
      onChange = () {
        if (controller.current == before) return;
        controller.removeListener(onChange);
        final timer = Stopwatch()..start();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          feedback = {
            'status': 'complete',
            'stateChangeToFrameUs': timer.elapsedMicroseconds,
          };
        });
        WidgetsBinding.instance.scheduleFrame();
      };
      controller.addListener(onChange);
    }
    if (parameters['action'] == 'save') {
      if (observed != null && listener != null) {
        observed!.removeListener(listener!);
      }
      final view = readState();
      final controller = view.settings!;
      if (controller.saving) throw StateError('An idle editor is required.');
      final watch = Stopwatch();
      measurement = {
        'label': parameters['label'],
        'status': 'armed',
        'before': view.state,
      };
      observed = controller;
      trace.arm();
      listener = () {
        if (controller.saving && !watch.isRunning) {
          watch.start();
        } else if (!controller.saving && watch.isRunning) {
          watch.stop();
          observed!.removeListener(listener!);
          measurement['confirmedUs'] = watch.elapsedMicroseconds;
          measurement['state'] = readState().state;
          final frameWatch = Stopwatch()..start();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            trace.armed = false;
            measurement['usableFrameUs'] =
                watch.elapsedMicroseconds + frameWatch.elapsedMicroseconds;
            measurement['disk'] = trace.snapshot();
            measurement['status'] = 'complete';
          });
          WidgetsBinding.instance.scheduleFrame();
        }
      };
      controller.addListener(listener!);
    }
    return developer.ServiceExtensionResponse.result(
      jsonEncode({'save': measurement, 'feedback': feedback}),
    );
  });
}
