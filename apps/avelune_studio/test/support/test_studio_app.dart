import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avelune_studio/app/di/providers.dart';
import 'package:avelune_studio/app/studio_app.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';

class TestStudioApp extends StatelessWidget {
  const TestStudioApp({
    super.key,
    required this.createSession,
    required this.chooseDirectory,
  });

  final ProjectSessionController Function() createSession;
  final Future<String?> Function() chooseDirectory;

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      projectSessionControllerProvider.overrideWith((ref) {
        final controller = createSession();
        ref.onDispose(() => unawaited(controller.dispose()));
        return controller;
      }),
      projectDirectoryPickerProvider.overrideWithValue(chooseDirectory),
    ],
    child: const StudioApp(),
  );
}
