import 'package:map_core/map_core.dart';

import '../player/runtime_audio_mixer.dart';
import '../player/runtime_project_audio_controller.dart';
import '../presentation/flame/flame_cinematic_media_playback_adapter.dart';
import 'scene_runtime/world_presentation_image_loader.dart';

Future<RuntimeProjectAudioController> loadRuntimeProjectAudio({
  required String projectRootDirectory,
  required RuntimeAudioMixer mixer,
  ProjectAudioSettings? settings,
  FlameCinematicAudioDriver? driver,
}) async {
  final ids =
      settings?.cues.values
          .where((binding) => binding.source == ProjectSoundSource.custom)
          .map((binding) => binding.mediaId!) ??
      const <String>[];
  final files = await WorldPresentationImageLoader(projectRootDirectory)
      .loadAudioFiles(ids);
  return RuntimeProjectAudioController(
    mixer: mixer,
    settings: settings,
    driver: driver,
    resolveMedia: (id) {
      final file = files[id];
      return file == null
          ? null
          : RuntimeProjectAudioFile(path: file.$1, mimeType: file.$2);
    },
  );
}
