import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';

final projectSessionPortProvider = Provider<ProjectSessionPort>(
  (ref) => throw StateError('Project session port must be configured'),
);

final projectSessionControllerProvider = Provider<ProjectSessionController>((
  ref,
) {
  final controller = ProjectSessionController(
    ref.watch(projectSessionPortProvider),
  );
  ref.onDispose(() => unawaited(controller.dispose()));
  return controller;
});

final projectDirectoryPickerProvider = Provider<Future<String?> Function()>(
  (ref) => throw StateError('Project directory picker must be configured'),
);
