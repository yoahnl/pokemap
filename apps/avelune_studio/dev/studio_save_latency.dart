import 'dart:convert';
import 'dart:developer' as developer;

import 'package:avelune_studio/presentation/features/characters/character_studio_page.dart';
import 'package:avelune_studio/presentation/features/resources/working_catalog_workspace.dart';
import 'package:flutter/widgets.dart';

import 'marionette_main.dart' as studio;
import 'save_disk_trace.dart';

final class _SaveView {
  _SaveView(this.changes, this.saving, this.state);
  final Listenable changes;
  final bool Function() saving;
  final Map<String, Object?> Function() state;

  static _SaveView find() {
    _SaveView? result;
    void visit(Element element) {
      switch (element.widget) {
        case CharacterStudioPage(:final controller):
          result = _SaveView(
            controller,
            () => controller.saving,
            () => {
              'storage': 'manifest',
              'selectedId': controller.selectedId,
              'saving': controller.saving,
              'error': controller.error,
              'dirty': controller.selectedDraft?.dirty,
              'draftValue': controller.selectedDraft?.contactShadow,
              'savedValue': controller.selectedDraft?.saved.contactShadow,
              'projectDefault': controller
                  .project()
                  .settings
                  .actorContactShadowsByDefault,
            },
          );
        case WorkingCatalogWorkspace(:final controller):
          result = _SaveView(
            controller,
            () => controller.saving,
            () => {
              'storage': 'workingCatalog',
              'selectedId': controller.selected?.id,
              'saving': controller.saving,
              'opening': controller.opening,
              'error': controller.error,
              'dirty': controller.dirty,
              'draftValue': controller.draft?.contactShadow,
              'savedValue': controller.detail?.entry.contactShadow,
              'projectDefault': controller
                  .detail
                  ?.definitions
                  .settings
                  .actorContactShadowsByDefault,
            },
          );
        default:
          break;
      }
      element.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
    return result ?? (throw StateError('A resource editor is required.'));
  }
}

Future<void> main() async {
  const root = String.fromEnvironment('MARIONETTE_PROJECT_PATH');
  final disk = SaveDiskTrace(root);
  final opening = Stopwatch()..start();
  await disk.run(studio.main);
  developer.registerExtension('ext.flutter.avelune.saveUiState', (
    method,
    parameters,
  ) async {
    final binding = WidgetsBinding.instance;
    binding.scheduleFrame();
    await binding.endOfFrame;
    return developer.ServiceExtensionResponse.result(
      jsonEncode({
        ..._SaveView.find().state(),
        'elapsedSinceLaunchMicroseconds': opening.elapsedMicroseconds,
      }),
    );
  });
  Listenable? observed;
  VoidCallback? listener;
  Map<String, Object?> measurement = {};
  Map<String, Object?> feedback = {};
  developer.registerExtension('ext.flutter.avelune.feedbackLatency', (
    method,
    parameters,
  ) async {
    if (parameters['command'] == 'arm') {
      final view = _SaveView.find();
      final before = view.state()['draftValue'];
      feedback = {'status': 'armed', 'before': before};
      late final VoidCallback onChange;
      onChange = () {
        final after = view.state()['draftValue'];
        if (before == after) return;
        view.changes.removeListener(onChange);
        final timer = Stopwatch()..start();
        WidgetsBinding.instance.endOfFrame.then((_) {
          feedback = {
            'status': 'complete',
            'before': before,
            'after': after,
            'stateChangeToFrameMicroseconds': timer.elapsedMicroseconds,
          };
        });
      };
      view.changes.addListener(onChange);
    }
    return developer.ServiceExtensionResponse.result(jsonEncode(feedback));
  });
  developer.registerExtension('ext.flutter.avelune.diskTrace', (
    method,
    parameters,
  ) async {
    if (parameters['command'] == 'arm') disk.arm();
    if (parameters['command'] == 'stop') disk.armed = false;
    return developer.ServiceExtensionResponse.result(
      jsonEncode(disk.snapshot()),
    );
  });
  developer.registerExtension('ext.flutter.avelune.saveLatency', (
    method,
    parameters,
  ) async {
    if (parameters['command'] == 'arm') {
      if (observed != null && listener != null) {
        observed!.removeListener(listener!);
      }
      final view = _SaveView.find();
      if (view.saving()) throw StateError('An idle editor is required.');
      final timer = Stopwatch();
      measurement = {
        'label': parameters['label'],
        'status': 'armed',
        ...view.state(),
      };
      observed = view.changes;
      disk.arm();
      listener = () {
        if (view.saving() && !timer.isRunning) {
          timer.start();
          measurement['status'] = 'saving';
        } else if (!view.saving() && timer.isRunning) {
          timer.stop();
          measurement.addAll({
            'status': 'controller-complete',
            'controllerMicroseconds': timer.elapsedMicroseconds,
            ...view.state(),
          });
          view.changes.removeListener(listener!);
          final frameTimer = Stopwatch()..start();
          WidgetsBinding.instance.endOfFrame.then((_) {
            measurement['frameMicroseconds'] = frameTimer.elapsedMicroseconds;
            measurement['usableMicroseconds'] =
                timer.elapsedMicroseconds + frameTimer.elapsedMicroseconds;
            disk.armed = false;
            measurement['disk'] = disk.snapshot();
            measurement['status'] = 'complete';
          });
          WidgetsBinding.instance.scheduleFrame();
        }
      };
      view.changes.addListener(listener!);
    }
    return developer.ServiceExtensionResponse.result(jsonEncode(measurement));
  });
}
