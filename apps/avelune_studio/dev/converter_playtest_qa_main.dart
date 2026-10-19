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
import 'package:marionette_flutter/marionette_flutter.dart';

Future<void> main() async {
  if (!kDebugMode || !Platform.isMacOS) {
    throw StateError('Converter playtest QA requires macOS debug mode.');
  }
  MarionetteBinding.ensureInitialized();
  final session = ProjectSessionController(LocalProjectSessionAdapter());
  final service = await developer.Service.getInfo();
  stdout.writeln(
    jsonEncode({'vmService': service.serverUri?.toString(), 'pid': pid}),
  );
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
    return developer.ServiceExtensionResponse.result(
      jsonEncode({
        'pid': pid,
        'projectPath': session.state.project?.directoryPath,
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
