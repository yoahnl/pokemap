import 'dart:async';

import 'package:flutter/foundation.dart';

import '../presentation/flame/flame_cinematic_media_playback_adapter.dart';
import 'runtime_audio_mixer.dart';
import 'runtime_music_loop_points.dart';

/// Joue LA musique courante du runtime — BETA-BAT-015.
///
/// Le contrat suit la référence : une seule BGM à la fois, quel que soit son
/// propriétaire (carte, rencontre, combat, victoire). La route ne change pas
/// ce qui joue, seulement l'identité mixeur du canal — carte et combat vivent
/// tous deux sur le bus musique.
///
/// Comportements repris de la référence :
/// - rejouer le même fichier ne le redémarre pas (parité `Game_Map#autoplay`
///   entre deux cartes qui partagent leur BGM) ;
/// - un changement de piste fond d'abord l'ancienne sur 250 ms (parité du
///   fondu FMOD de `bgm_play`), puis démarre la nouvelle ;
/// - un chemin absent joue le silence sans jamais casser le flux appelant.
///
/// Les opérations sont sérialisées dans une file unique, comme
/// [RuntimeTitleMusicController] : le dernier état demandé gagne toujours, et
/// aucun fondu périmé ne peut écraser une piste plus récente.
final class RuntimeMusicService {
  RuntimeMusicService({
    FlameCinematicAudioDriver? driver,
    RuntimeAudioMixer? mixer,
    RuntimeAudioFadeDelay? fadeDelay,
    int fadeSteps = 8,
  })  : _driver = driver ?? FlameAudioCinematicRuntimeDriver(),
        _mixer = mixer ?? RuntimeAudioMixer(),
        _fadeDelay = fadeDelay ?? Future<void>.delayed,
        _fadeSteps = fadeSteps < 1 ? 1 : fadeSteps;

  static const Duration fadeOutDuration = Duration(milliseconds: 250);

  final FlameCinematicAudioDriver _driver;
  final RuntimeAudioMixer _mixer;
  final RuntimeAudioFadeDelay _fadeDelay;
  final int _fadeSteps;

  Future<void> _pending = Future<void>.value();
  Object? _handle;
  StreamSubscription<void>? _loopSubscription;
  String? _playingPath;
  double _playingSourceVolume = 0.8;
  String? _desiredPath;
  RuntimeAudioRoute _desiredRoute = RuntimeAudioRoute.overworld;
  double _desiredVolume = 0.8;
  bool _disposed = false;

  Object? lastFailure;

  bool get isPlaying => _handle != null;

  @visibleForTesting
  String? get playingPath => _playingPath;

  /// Déclare l'état musical voulu. Idempotent : même chemin, même piste.
  Future<void> update({
    required RuntimeAudioRoute route,
    required String? path,
    double volume = 0.8,
  }) {
    if (_disposed) return Future<void>.value();
    _desiredPath = path;
    _desiredRoute = route;
    _desiredVolume = volume.clamp(0.0, 1.0);
    return _enqueue(_applyDesiredState);
  }

  Future<void> dispose() {
    if (_disposed) return _pending;
    _disposed = true;
    _desiredPath = null;
    return _enqueue(() => _stop(fade: false));
  }

  Future<void> _applyDesiredState() async {
    final path = _desiredPath;
    if (_disposed || path == null) {
      await _stop(fade: true);
      return;
    }
    if (_handle != null && _playingPath == path) {
      try {
        await _mixer.updateSourceVolume(_handle!, _desiredVolume);
        _playingSourceVolume = _desiredVolume;
        lastFailure = null;
      } on Object catch (error) {
        lastFailure = error;
        await _stop(fade: false);
      }
      return;
    }
    await _stop(fade: true);
    try {
      // BETA-BAT-026 (recette du 2026-08-24) : « la musique est en boucle
      // c'est bien, mais on a aussi le jingle de début de combat ». Le
      // lecteur bouclait le FICHIER ENTIER, donc l'intro du morceau (14 s sur
      // la piste de combat sauvage du Train) revenait à chaque tour. Quand la
      // piste porte les points de boucle de la convention RPG Maker, on joue
      // l'intro UNE fois puis on ne reboucle que sur la région marquée.
      final loopPoints = readRuntimeMusicLoopPoints(path);
      final loopDriver = _driver;
      final usesIntroLoop = loopPoints != null &&
          loopDriver is FlameCinematicAudioLoopDriver &&
          loopPoints.start > Duration.zero;
      final handle = await _driver.play(
        path,
        volume: _mixer.mix.volumeFor(
          _desiredRoute,
          sourceVolume: _desiredVolume,
        ),
        loop: !usesIntroLoop,
      );
      if (usesIntroLoop) {
        final looping = loopDriver as FlameCinematicAudioLoopDriver;
        _loopSubscription = looping.onComplete(handle).listen((_) {
          // La piste s'est terminée : reprendre au point de boucle, jamais au
          // début — l'intro ne se rejoue plus.
          unawaited(looping.seekAndResume(handle, loopPoints.start));
        });
      }
      _handle = handle;
      _playingPath = path;
      _playingSourceVolume = _desiredVolume;
      await _mixer.register(
        channel: handle,
        route: _desiredRoute,
        sourceVolume: _desiredVolume,
        setVolume: (volume) => _driver.setVolume(handle, volume),
        applyImmediately: false,
      );
      lastFailure = null;
    } on Object catch (error) {
      _handle = null;
      _playingPath = null;
      lastFailure = error;
    }
  }

  Future<void> _stop({required bool fade}) async {
    final handle = _handle;
    final fromVolume = _playingSourceVolume;
    // La boucle à point de reprise meurt avec sa piste : laisser vivre cette
    // souscription ferait revenir un morceau arrêté.
    unawaited(_loopSubscription?.cancel());
    _loopSubscription = null;
    _handle = null;
    _playingPath = null;
    if (handle == null) return;
    if (fade) {
      final step = Duration(
        microseconds: (fadeOutDuration.inMicroseconds / _fadeSteps).ceil(),
      );
      for (var index = 1; index <= _fadeSteps; index += 1) {
        await _fadeDelay(step);
        try {
          await _mixer.updateSourceVolume(
            handle,
            fromVolume * (1 - index / _fadeSteps),
          );
        } on Object catch (error) {
          lastFailure = error;
          break;
        }
      }
    }
    _mixer.unregister(handle);
    try {
      await _driver.stop(handle);
    } on Object catch (error) {
      lastFailure = error;
    }
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.onError((_, __) {});
    return result;
  }
}
