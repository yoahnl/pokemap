import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/updates/studio_update_controller.dart';
import '../../platform/updates/studio_update_service.dart';
import '../studio_lifecycle_controller.dart';
import 'project_session_providers.dart';
import 'rendering_providers.dart';
import 'studio_mcp_providers.dart';

final studioLifecycleControllerProvider = Provider<StudioLifecycleController>((
  ref,
) {
  final controller = StudioLifecycleController(
    session: ref.watch(projectSessionControllerProvider),
    mcp: ref.watch(studioMcpServiceProvider),
    renderingPreferences: ref.watch(studioRenderingPreferencesProvider),
    exitGuard: ref.watch(studioExitGuardProvider),
  );
  ref.onDispose(() => unawaited(controller.close()));
  return controller;
});

final studioUpdateControllerProvider = Provider<StudioUpdateController>((ref) {
  final lifecycle = ref.watch(studioLifecycleControllerProvider);
  final service = StudioUpdateService(
    prepareForRestart: lifecycle.prepareForUpdate,
    resumeAfterFailure: lifecycle.resumeAfterUpdateFailure,
  );
  ref.onDispose(service.dispose);
  return service.controller;
});
