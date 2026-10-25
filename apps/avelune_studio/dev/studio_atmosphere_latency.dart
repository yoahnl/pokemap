import 'dart:convert';
import 'dart:developer' as developer;

import 'package:avelune_studio/features/map_workspace/application/map_atmosphere_controller.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_atmosphere_settings_panel.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_map_editor.dart';
import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:map_runtime/map_runtime.dart';

import 'marionette_main.dart' as studio;
import 'save_disk_trace.dart';
import '../test/support/studio_shadow_probe.dart';

({
  MapAtmosphereController? settings,
  SpatialSceneController? renderer,
  Map<String, Object?> state,
})
readState() {
  MapAtmosphereController? settings;
  SpatialMapEditor? editor;
  SpatialSceneController? renderer;
  SpatialExplorationView? runtime;
  Game? renderGame;
  final renderGames = <Map<String, Object?>>[];
  void visit(Element element) {
    switch (element.widget) {
      case MapAtmosphereSettingsPanel(:final controller):
        settings = controller;
      case SpatialMapEditor():
        editor = element.widget as SpatialMapEditor;
      case SpatialSceneView(:final controller):
        renderer = controller;
      case GameWidget(:final game):
        renderGame = game;
        if (game != null) {
          renderGames.add({
            'identity': identityHashCode(game),
            'type': game.runtimeType.toString(),
            'paused': game.isPaused,
          });
        }
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
    renderer: renderer,
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
      'presentationProfileIdentity': renderer == null
          ? null
          : identityHashCode(renderer!.presentationProfile),
      'renderer': renderer == null
          ? null
          : {
              'water': renderer!.waterAnimated,
              'windows': renderer!.windowsLit,
              'fireflies': renderer!.fireflies,
              'halos': renderer!.halosEnabled,
              'fog': renderer!.depthFogEnabled,
              'haloStrength': renderer!.presentationProfile.haloStrength,
              'haloSpread': renderer!.presentationProfile.haloSpread,
              'fogOpacity': renderer!.presentationProfile.fogOpacity,
              'fogStart': renderer!.presentationProfile.fogStart,
              'fogEnd': renderer!.presentationProfile.fogEnd,
              'haloCount': renderer!.haloCount,
              'haloAllocations': renderer!.haloAllocations,
              'minute': renderer!.previewMinuteOfDay,
            },
      'renderGames': renderGames,
      'rendererGameIdentity': renderGame == null
          ? null
          : identityHashCode(renderGame!),
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
  final playtestWatch = Stopwatch();
  developer.registerExtension('ext.flutter.avelune.atmospherePreviewTime', (
    method,
    parameters,
  ) async {
    final view = readState();
    final minute = double.tryParse(parameters['minute'] ?? '');
    final runtime = view.state['runtime'] as Map<String, Object?>?;
    if ((view.state['projectPath'] != root &&
            runtime?['projectPath'] != root) ||
        view.renderer == null ||
        minute == null ||
        !minute.isFinite ||
        minute < 0 ||
        minute >= 1440) {
      throw StateError(
        'A bounded preview in the configured test project is required.',
      );
    }
    view.renderer!.previewMinuteOfDay = minute;
    return developer.ServiceExtensionResponse.result(
      jsonEncode(readState().state),
    );
  });
  registerStudioShadowProbe(
    isCopyActive: () {
      final state = readState().state;
      final runtime = state['runtime'] as Map<String, Object?>?;
      return state['projectPath'] == root || runtime?['projectPath'] == root;
    },
  );
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
    if (parameters['action'] == 'playtestStart') {
      trace.arm();
      playtestWatch
        ..reset()
        ..start();
    }
    if (parameters['action'] == 'playtestFinish') {
      playtestWatch.stop();
      trace.armed = false;
      return developer.ServiceExtensionResponse.result(
        jsonEncode({
          'elapsedUs': playtestWatch.elapsedMicroseconds,
          'disk': trace.snapshot(),
          'state': readState().state,
        }),
      );
    }
    if (parameters['action'] == 'feedback') {
      final controller = readState().settings!;
      final before = controller.current;
      final pointerWatch = Stopwatch();
      void pointerRoute(PointerEvent event) {
        if (event is PointerDownEvent) pointerWatch.start();
      }

      GestureBinding.instance.pointerRouter.addGlobalRoute(pointerRoute);
      trace.arm();
      feedback = {'status': 'armed'};
      late VoidCallback onChange;
      onChange = () {
        if (controller.current == before) return;
        controller.removeListener(onChange);
        final timer = Stopwatch()..start();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          trace.armed = false;
          GestureBinding.instance.pointerRouter.removeGlobalRoute(pointerRoute);
          feedback = {
            'status': 'complete',
            'stateChangeToFrameUs': timer.elapsedMicroseconds,
            'pointerDownToFrameUs': pointerWatch.isRunning
                ? pointerWatch.elapsedMicroseconds
                : null,
            'disk': trace.snapshot(),
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
