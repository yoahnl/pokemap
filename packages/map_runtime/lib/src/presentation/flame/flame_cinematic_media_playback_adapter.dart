import 'package:flame_audio/flame_audio.dart';
import 'package:map_core/map_core.dart';

import '../../player/runtime_audio_mixer.dart';
import 'flame_cinematic_fx_playback_adapter.dart';

typedef FlameCinematicMediaPathResolver = String Function(
  CinematicMediaAsset asset,
);

abstract interface class FlameCinematicAudioDriver {
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  });
  Future<void> setVolume(Object handle, double volume);
  Future<void> stop(Object handle);
}

/// Capacités de boucle à point de reprise — BETA-BAT-026.
///
/// Interface SÉPARÉE et optionnelle : un driver qui ne la porte pas garde la
/// boucle du fichier entier, et aucune implémentation existante (les faux
/// drivers des tests) n'a à changer. Le service musique la détecte par `is`.
abstract interface class FlameCinematicAudioLoopDriver {
  /// Déplace la lecture, puis reprend là où on vient d'atterrir.
  Future<void> seekAndResume(Object handle, Duration position);

  /// Notifie la fin de la piste (le moment de revenir au point de boucle).
  Stream<void> onComplete(Object handle);
}

final class FlameAudioCinematicRuntimeDriver
    implements FlameCinematicAudioDriver, FlameCinematicAudioLoopDriver {
  @override
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  }) async {
    final player = AudioPlayer();
    // `stop` plutôt que `release` quand on gère la boucle nous-mêmes : le
    // player doit rester vivant à la fin de la piste pour pouvoir revenir au
    // point de reprise.
    await player.setReleaseMode(
      loop ? ReleaseMode.loop : ReleaseMode.stop,
    );
    await player.play(DeviceFileSource(path), volume: volume);
    return player;
  }

  @override
  Future<void> seekAndResume(Object handle, Duration position) async {
    final player = handle as AudioPlayer;
    await player.seek(position);
    await player.resume();
  }

  @override
  Stream<void> onComplete(Object handle) =>
      (handle as AudioPlayer).onPlayerComplete;

  @override
  Future<void> setVolume(Object handle, double volume) =>
      (handle as AudioPlayer).setVolume(volume);

  @override
  Future<void> stop(Object handle) async {
    final player = handle as AudioPlayer;
    await player.stop();
    await player.dispose();
  }
}

final class FlameCinematicMediaPlaybackAdapter
    implements CinematicMediaPlaybackPort {
  FlameCinematicMediaPlaybackAdapter({
    required Iterable<CinematicMediaAsset> mediaAssets,
    required this.resolvePath,
    required this.fx,
    FlameCinematicAudioDriver? audioDriver,
    RuntimeAudioMixer? audioMixer,
  })  : _mediaById = {for (final asset in mediaAssets) asset.id: asset},
        _audioDriver = audioDriver ?? FlameAudioCinematicRuntimeDriver(),
        _audioMixer = audioMixer ?? RuntimeAudioMixer();

  final Map<String, CinematicMediaAsset> _mediaById;
  final FlameCinematicMediaPathResolver resolvePath;
  final FlameCinematicFxPlaybackAdapter fx;
  final FlameCinematicAudioDriver _audioDriver;
  final RuntimeAudioMixer _audioMixer;
  final Map<String, _RuntimeAudioChannel> _channels = {};

  @override
  Future<CinematicMediaPlaybackCheckpoint> captureCheckpoint() async =>
      CinematicMediaPlaybackCheckpoint(
        activeChannels: {
          for (final entry in _channels.entries)
            entry.key: entry.value.asset.id,
        },
        activeFxIds: fx.activeFxIds,
        channelVolumes: {
          for (final entry in _channels.entries) entry.key: entry.value.volume,
        },
        loopingChannels: {
          for (final entry in _channels.entries)
            if (entry.value.loop) entry.key,
        },
      );

  @override
  Future<void> execute(CinematicMediaPlaybackCommand command) async {
    switch (command.kind) {
      case CinematicMediaPlaybackCommandKind.play:
        await _play(command);
      case CinematicMediaPlaybackCommandKind.stopChannel:
        await _stopChannel(command.channel);
      case CinematicMediaPlaybackCommandKind.fadeChannel:
        await _fade(command);
      case CinematicMediaPlaybackCommandKind.spawnFx:
      case CinematicMediaPlaybackCommandKind.cancelFx:
        await fx.execute(command);
      case CinematicMediaPlaybackCommandKind.restore:
        await restore(CinematicMediaPlaybackCheckpoint());
    }
  }

  @override
  Future<void> restore(CinematicMediaPlaybackCheckpoint checkpoint) async {
    final errors = <Object>[];
    for (final channel in _channels.values.toList(growable: false)) {
      try {
        _audioMixer.unregister(channel.handle);
        await _audioDriver.stop(channel.handle);
      } catch (error) {
        errors.add(error);
      }
    }
    _channels.clear();
    fx.restore(checkpoint.activeFxIds);
    for (final entry in checkpoint.activeChannels.entries) {
      final asset = _requireAsset(entry.value);
      try {
        final volume = checkpoint.channelVolumes[entry.key] ?? 1;
        final loop = checkpoint.loopingChannels.contains(entry.key);
        final route = _routeFor(asset);
        final handle = await _audioDriver.play(
          resolvePath(asset),
          volume: _audioMixer.mix.volumeFor(
            route,
            sourceVolume: volume,
          ),
          loop: loop,
        );
        await _audioMixer.register(
          channel: handle,
          route: route,
          sourceVolume: volume,
          setVolume: (nextVolume) => _audioDriver.setVolume(handle, nextVolume),
          applyImmediately: false,
        );
        _channels[entry.key] = _RuntimeAudioChannel(
          asset: asset,
          handle: handle,
          volume: volume,
          loop: loop,
        );
      } catch (error) {
        errors.add(error);
      }
    }
    if (errors.isNotEmpty) {
      throw StateError('Cinematic media restore failed: ${errors.first}');
    }
  }

  Future<void> _play(CinematicMediaPlaybackCommand command) async {
    final assetId = command.assetId;
    final channel = command.channel;
    if (assetId == null || channel == null) {
      throw StateError('Audio command is incomplete.');
    }
    final asset = _requireAsset(assetId);
    if (asset.kind == CinematicMediaAssetKind.cinematicFx) {
      throw StateError('FX asset "$assetId" cannot be played as audio.');
    }
    await _stopChannel(channel);
    final volume = command.volume ?? 1;
    final fadeMs = command.durationMs ?? 0;
    final route = _routeFor(asset);
    final initialVolume = fadeMs > 0 ? 0.0 : volume;
    final handle = await _audioDriver.play(
      resolvePath(asset),
      volume: _audioMixer.mix.volumeFor(
        route,
        sourceVolume: initialVolume,
      ),
      loop: command.loop,
    );
    await _audioMixer.register(
      channel: handle,
      route: route,
      sourceVolume: initialVolume,
      setVolume: (nextVolume) => _audioDriver.setVolume(handle, nextVolume),
      applyImmediately: false,
    );
    _channels[channel] = _RuntimeAudioChannel(
      asset: asset,
      handle: handle,
      volume: volume,
      loop: command.loop,
    );
    if (fadeMs > 0) {
      await _audioMixer.updateSourceVolume(handle, volume);
    }
  }

  Future<void> _fade(CinematicMediaPlaybackCommand command) async {
    final channel = command.channel;
    if (channel == null) return;
    final active = _channels[channel];
    if (active == null) return;
    final volume = command.volume ?? active.volume;
    await _audioMixer.updateSourceVolume(active.handle, volume);
    _channels[channel] = active.copyWith(volume: volume);
  }

  Future<void> _stopChannel(String? channel) async {
    if (channel == null) return;
    final active = _channels.remove(channel);
    if (active != null) {
      _audioMixer.unregister(active.handle);
      await _audioDriver.stop(active.handle);
    }
  }

  RuntimeAudioRoute _routeFor(CinematicMediaAsset asset) =>
      asset.kind == CinematicMediaAssetKind.sound
          ? RuntimeAudioRoute.cinematicEffects
          : RuntimeAudioRoute.cinematicMusic;

  CinematicMediaAsset _requireAsset(String id) {
    final asset = _mediaById[id];
    if (asset == null) throw StateError('Unknown cinematic media "$id".');
    return asset;
  }
}

final class _RuntimeAudioChannel {
  const _RuntimeAudioChannel({
    required this.asset,
    required this.handle,
    required this.volume,
    required this.loop,
  });

  final CinematicMediaAsset asset;
  final Object handle;
  final double volume;
  final bool loop;

  _RuntimeAudioChannel copyWith({required double volume}) =>
      _RuntimeAudioChannel(
        asset: asset,
        handle: handle,
        volume: volume,
        loop: loop,
      );
}
