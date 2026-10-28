import 'package:flutter/foundation.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_runtime/map_runtime.dart';

import '../../features/project_audio/domain/project_audio_port.dart';
import '../../features/project_session/domain/project_session.dart';

final class StudioProjectAudioPreview implements ProjectAudioPreviewPort {
  StudioProjectAudioPreview({required this.session, required this.port}) {
    _audio = RuntimeProjectAudioController(
      mixer: RuntimeAudioMixer(),
      resolveMedia: (id) => _files[id],
      onPlaybackChanged: () {
        if (!_closed) {
          playing.value = _audio.isPlaying(ProjectSoundCue.uiConfirm)
              ? _selected
              : null;
        }
      },
    );
  }
  final ProjectSession session;
  final ProjectAudioPort port;
  late final RuntimeProjectAudioController _audio;
  final _files = <String, RuntimeProjectAudioFile>{};
  @override
  final ValueNotifier<String?> playing = ValueNotifier<String?>(null);
  String? _selected;
  int _generation = 0;
  bool _closed = false;
  @override
  Future<void> play(String mediaId) async {
    if (_closed) return;
    final generation = ++_generation;
    await _audio.stopAll();
    final file = await port.resolveAudio(session, mediaId);
    if (_closed || generation != _generation) return;
    _files[mediaId] = RuntimeProjectAudioFile(
      path: file.path,
      mimeType: file.mimeType,
    );
    _selected = mediaId;
    final started = await _audio.play(
      ProjectSoundCue.uiConfirm,
      binding: ProjectSoundBinding(
        source: ProjectSoundSource.custom,
        mediaId: mediaId,
      ),
    );
    if (!_closed && generation == _generation && !started) {
      throw StateError(
        'Le son ne peut pas être lu : ${_audio.lastFailure ?? 'format indisponible'}',
      );
    }
  }

  @override
  Future<void> stop() async {
    if (_closed) return;
    _generation++;
    _selected = null;
    await _audio.stopAll();
    playing.value = null;
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _generation++;
    await _audio.dispose();
    playing.dispose();
  }
}
