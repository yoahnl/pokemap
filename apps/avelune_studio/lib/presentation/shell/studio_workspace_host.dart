import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'studio_home_navigation.dart';

import 'package:avelune_studio/app/di/providers.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';

class StudioWorkspaceHost extends ConsumerWidget {
  const StudioWorkspaceHost({
    super.key,
    required this.session,
    required this.onClose,
    required this.registerExitGuard,
  });

  final ProjectSession session;
  final Future<void> Function() onClose;
  final void Function(Future<bool> Function()?) registerExitGuard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(mapWorkspaceControllerProvider(session));
    return MapWorkspaceScreen(
      home: StudioHomeScope.of(context),
      controller: controller,
      resourcePort: ref.watch(resourcePortProvider(session)),
      narrativePort: ref.watch(narrativePortProvider(session)),
      scenePort: ref.watch(scenePortProvider(session)),
      storyPort: ref.watch(storyPortProvider(session)),
      eventPort: ref.watch(eventPortProvider(session)),
      dialoguePort: ref.watch(dialoguePortProvider(session)),
      cinematicPort: ref.watch(cinematicPortProvider(session)),
      presentationPort: ref.watch(presentationPortProvider(session)),
      presentationMediaPicker: ref.watch(presentationMediaPickerProvider),
      imagePicker: ref.watch(resourceImagePickerProvider),
      loadVisuals: ref.watch(workspaceVisualsLoaderProvider),
      runtimeBuilder: ref.watch(sessionRuntimeBuilderProvider(session)),
      onClose: onClose,
      registerExitGuard: registerExitGuard,
    );
  }
}
