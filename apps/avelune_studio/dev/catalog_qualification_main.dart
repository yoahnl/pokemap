import 'dart:developer' as developer;
import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/app/studio_bootstrap.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

Future<ProjectSessionController> openCatalogQualificationProject(
  String configuredPath,
) async {
  if (configuredPath.isEmpty || !Directory(configuredPath).isAbsolute) {
    throw ArgumentError.value(configuredPath, 'MARIONETTE_PROJECT_PATH');
  }
  final root = Directory(configuredPath);
  if (!await root.exists() ||
      await root.resolveSymbolicLinks() != configuredPath) {
    throw StateError('The qualification project must have a canonical root.');
  }
  final session = ProjectSessionController(LocalProjectSessionAdapter());
  await session.open(configuredPath);
  if (session.state.project?.directoryPath != configuredPath) {
    final problem = session.state.problem;
    await session.dispose();
    throw StateError('The qualification project could not be opened: $problem');
  }
  return session;
}

Future<void> main() async {
  if (!kDebugMode || !Platform.isMacOS) {
    throw StateError('Catalog qualification requires a macOS debug build.');
  }
  final logs = PrintLogCollector();
  MarionetteBinding.ensureInitialized(
    MarionetteConfiguration(logCollector: logs),
  );
  final previousErrorHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    logs.addLog('FlutterError: ${details.exceptionAsString()}');
    previousErrorHandler?.call(details);
  };
  const root = String.fromEnvironment('MARIONETTE_PROJECT_PATH');
  final session = await openCatalogQualificationProject(root);
  developer.registerExtension('ext.flutter.avelune.catalogQualification', (
    method,
    parameters,
  ) async {
    final project = session.state.project;
    return developer.ServiceExtensionResponse.result(
      jsonEncode({
        'pid': pid,
        'expectedProjectPath': root,
        'activeProjectPath': project?.directoryPath,
        'matches': project?.directoryPath == root,
        'projectName': project?.name,
        'storage': project?.storage.name,
        'status': session.state.status.name,
        'problem': session.state.problem?.name,
      }),
    );
  });
  runApp(StudioBootstrap(debugSession: session));
}
