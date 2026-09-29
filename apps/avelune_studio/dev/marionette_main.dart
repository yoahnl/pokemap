import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:avelune_studio/app/studio_bootstrap.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:flutter/widgets.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

Future<void> main() async {
  MarionetteBinding.ensureInitialized();
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
  developer.registerExtension('ext.flutter.avelune.activeProject', (
    method,
    params,
  ) async {
    return developer.ServiceExtensionResponse.result(
      jsonEncode({'path': session.state.project?.directoryPath}),
    );
  });
  runApp(StudioBootstrap(debugSession: session));
}
