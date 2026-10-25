import 'dart:convert';
import 'dart:developer' as developer;

import 'package:avelune_studio/presentation/features/characters/character_studio_controller.dart';
import 'package:avelune_studio/presentation/features/characters/character_studio_page.dart';
import 'package:flutter/widgets.dart';

import 'marionette_main.dart' as studio;

Future<void> main() async {
  await studio.main();
  developer.registerExtension('ext.flutter.avelune.saveUiState', (
    method,
    parameters,
  ) async {
    final binding = WidgetsBinding.instance;
    binding.scheduleFrame();
    await binding.endOfFrame;
    CharacterStudioPage? page;
    void visit(Element element) {
      if (element.widget case final CharacterStudioPage candidate) {
        page = candidate;
      }
      element.visitChildren(visit);
    }

    binding.rootElement?.visitChildren(visit);
    final controller = page?.controller;
    if (controller == null) {
      return developer.ServiceExtensionResponse.error(
        developer.ServiceExtensionResponse.extensionError,
        'A character editor is required.',
      );
    }
    return developer.ServiceExtensionResponse.result(jsonEncode({
      'selectedId': controller.selectedId,
      'saving': controller.saving,
      'error': controller.error,
      'dirty': controller.selectedDraft?.dirty,
      'draftValue': controller.selectedDraft?.contactShadow,
      'savedValue': controller.selectedDraft?.saved.contactShadow,
      'projectDefault':
          controller.project().settings.actorContactShadowsByDefault,
    }));
  });
  CharacterStudioController? observed;
  VoidCallback? listener;
  Map<String, Object?> measurement = {};
  developer.registerExtension('ext.flutter.avelune.saveLatency', (
    method,
    parameters,
  ) async {
    if (parameters['command'] == 'arm') {
      if (observed != null && listener != null) {
        observed!.removeListener(listener!);
      }
      CharacterStudioPage? page;
      void visit(Element element) {
        if (element.widget case final CharacterStudioPage candidate) {
          page = candidate;
        }
        element.visitChildren(visit);
      }
      WidgetsBinding.instance.rootElement?.visitChildren(visit);
      final controller = page?.controller;
      if (controller == null || controller.saving) {
        return developer.ServiceExtensionResponse.error(
          developer.ServiceExtensionResponse.extensionError,
          'An idle character editor is required.',
        );
      }
      final timer = Stopwatch();
      measurement = {
        'label': parameters['label'],
        'status': 'armed',
        'characterId': controller.selectedId,
        'draftValue': controller.selectedDraft?.contactShadow,
        'dirty': controller.selectedDraft?.dirty,
      };
      observed = controller;
      listener = () {
        if (controller.saving && !timer.isRunning) {
          timer.start();
          measurement['status'] = 'saving';
        } else if (!controller.saving && timer.isRunning) {
          timer.stop();
          measurement.addAll({
            'status': 'controller-complete',
            'controllerMicroseconds': timer.elapsedMicroseconds,
            'error': controller.error,
            'dirty': controller.selectedDraft?.dirty,
            'savedValue': controller.selectedDraft?.saved.contactShadow,
          });
          controller.removeListener(listener!);
          final frameTimer = Stopwatch()..start();
          WidgetsBinding.instance.endOfFrame.then((_) {
            measurement['frameMicroseconds'] = frameTimer.elapsedMicroseconds;
            measurement['usableMicroseconds'] =
                timer.elapsedMicroseconds + frameTimer.elapsedMicroseconds;
            measurement['status'] = 'complete';
          });
          WidgetsBinding.instance.scheduleFrame();
        }
      };
      controller.addListener(listener!);
    }
    return developer.ServiceExtensionResponse.result(jsonEncode(measurement));
  });
}
