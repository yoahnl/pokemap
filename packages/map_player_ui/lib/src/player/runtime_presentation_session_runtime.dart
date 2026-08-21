import 'dart:async';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'presentation_video_playback_driver.dart';
import 'runtime_presentation_surface_controller.dart';

/// The interactive Presentation stack every host composes — BETA-CIN-082.
///
/// This is the single composition root of the player side: the surface
/// controller, the awaitable adapter and the pre-session runner, wired the
/// one way that has been certified. Hosts differ only in how they find their
/// media (an installed package, a project directory), never in how the
/// player is assembled — otherwise two roots drift and only one of them is
/// the one that was tested.
final class RuntimePresentationSessionRuntime {
  RuntimePresentationSessionRuntime({
    required this.runtimeSourceId,
    required ProjectMediaCatalog catalog,
    required Map<String, Uri> mediaUris,
    required PresentationMediaTargetPlatform targetPlatform,
    required RuntimeAudioMixer audioMixer,
    required bool reducedMotion,
    RuntimePresentationVideoPlaybackDriver? videoDriver,
    RuntimePresentationFrameDeltas? frameDeltas,
    RuntimePresentationBeforeTerminal? beforeTerminal,
  }) : controller = RuntimePresentationSurfaceController(
          catalog: catalog,
          mediaUris: mediaUris,
          targetPlatform: targetPlatform,
          videoDriver:
              videoDriver ?? VideoPlayerPresentationPlaybackDriver(),
          audioMixer: audioMixer,
          reduceMotion: reducedMotion,
          frameDeltas: frameDeltas,
          beforeTerminal: beforeTerminal,
        );

  final String runtimeSourceId;
  final RuntimePresentationSurfaceController controller;

  /// Builds the pre-session runner the New Game flow drives: the Scene runner
  /// bound to this cinematic player, so a cue suspends the timeline and the
  /// authored branches route it (BETA-CIN-072, BETA-CIN-073).
  RuntimeNewGamePreSessionRunner buildPreSessionRunner({
    required ProjectManifest project,
    required String projectRootDirectory,
    required String projectRevision,
    required String sceneId,
  }) =>
      RuntimeTextPreSessionSceneRunner(
        project: project,
        projectRootDirectory: projectRootDirectory,
        sceneId: sceneId,
        presentationCinematic:
            ScenePresentationCinematicRuntimeAwaitableAdapter(
          runtimeSourceId: runtimeSourceId,
          projectRevision: projectRevision,
          assets: project.presentationCinematics,
          player: controller,
        ),
      );

  void cancelActive() => unawaited(controller.cancelActive());

  Future<void> close() => controller.close();
}

/// The platform the media pipeline must resolve variants for.
PresentationMediaTargetPlatform currentPresentationMediaTargetPlatform() {
  if (Platform.isAndroid) return PresentationMediaTargetPlatform.android;
  if (Platform.isIOS) return PresentationMediaTargetPlatform.ios;
  if (Platform.isMacOS) return PresentationMediaTargetPlatform.macos;
  if (Platform.isWindows) return PresentationMediaTargetPlatform.windows;
  if (Platform.isLinux) return PresentationMediaTargetPlatform.linux;
  return PresentationMediaTargetPlatform.web;
}
