import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:avelune_studio/app/studio_bootstrap.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/platform/playtest/studio_playtest_player_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

Future<void> main() async {
  if (!kDebugMode || !Platform.isMacOS) {
    throw StateError('Converter playtest QA requires macOS debug mode.');
  }
  final logs = PrintLogCollector();
  final originalDebugPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) logs.addLog(message);
    originalDebugPrint(message, wrapWidth: wrapWidth);
  };
  MarionetteBinding.ensureInitialized(
    MarionetteConfiguration(logCollector: logs),
  );
  const projectPath = String.fromEnvironment('AVELUNE_CONVERTER_QA_PROJECT');
  if (projectPath.isEmpty ||
      !Directory(projectPath).isAbsolute ||
      await Directory(projectPath).resolveSymbolicLinks() != projectPath) {
    throw StateError(
      'AVELUNE_CONVERTER_QA_PROJECT must be a canonical absolute project directory.',
    );
  }
  final session = ProjectSessionController(LocalProjectSessionAdapter());
  await session.open(projectPath);
  if (session.state.project?.directoryPath != projectPath ||
      session.state.problem != null) {
    throw StateError('The requested converter QA project could not be opened.');
  }
  final service = await developer.Service.getInfo();
  final sessionInfo = {
    'vmService': service.serverUri?.toString(),
    'pid': pid,
    'projectPath': projectPath,
  };
  await File('${Directory.systemTemp.path}/avelune-converter-qa-session.json')
      .writeAsString(jsonEncode(sessionInfo), flush: true);
  stdout.writeln(jsonEncode(sessionInfo));
  developer.registerExtension('ext.flutter.avelune.converterPlaytestQa', (
    method,
    parameters,
  ) async {
    StudioPlaytestPlayerView? player;
    void visit(Element element) {
      if (element.widget case final StudioPlaytestPlayerView value) {
        if (player != null) throw StateError('Multiple playtests are mounted.');
        player = value;
      }
      element.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
    final game = player?.game;
    if (parameters['operation'] == 'holdMovement') {
      final control = switch (parameters['direction']) {
        'north' => RuntimeInputControl.up,
        'east' => RuntimeInputControl.right,
        'south' => RuntimeInputControl.down,
        'west' => RuntimeInputControl.left,
        _ => throw ArgumentError('A cardinal direction is required.'),
      };
      final durationMs = int.tryParse(parameters['durationMs'] ?? '');
      if (game == null || !game.inputAuthoritySnapshot.acceptsOverworldInput ||
          durationMs == null || durationMs < 1 || durationMs > 1000) {
        throw StateError('An active overworld and a duration of 1 to 1000 ms are required.');
      }
      game.handleRuntimeInputEvent(RuntimeInputEvent.press(control));
      try {
        await Future<void>.delayed(Duration(milliseconds: durationMs));
      } finally {
        game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
      }
    }
    return developer.ServiceExtensionResponse.result(
      jsonEncode({
        'pid': pid,
        'projectPath': session.state.project?.directoryPath,
        'testSpeed': game?.testSpeed.value.multiplier,
        'inputContext': game?.inputAuthoritySnapshot.context.name,
        'gameState': player == null
            ? null
            : strictGameStateSaveJson(player!.game.gameStateSnapshot),
        'dialogueVisible':
            player?.game.dialoguePresentationListenable.value != null,
      }),
    );
  });
  runApp(StudioBootstrap(debugSession: session));
}
