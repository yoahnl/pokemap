import 'dart:async';

import 'package:flutter/foundation.dart' show ValueChanged;
import 'package:flame_audio/flame_audio.dart';
import 'package:map_core/map_core.dart';

typedef CinematicPreviewMediaPathResolver = String Function(
  CinematicMediaAsset asset,
);

abstract interface class FlutterCinematicAudioDriver {
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  });

  Future<void> setVolume(Object handle, double volume);
  Future<void> stop(Object handle);
}

final class FlameAudioCinematicPreviewDriver
    implements FlutterCinematicAudioDriver {
  @override
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  }) async {
    final player = AudioPlayer();
    await player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.release);
    await player.play(DeviceFileSource(path), volume: volume);
    return player;
  }

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

/// Flutter preview adapter backed by flame_audio/audioplayers. Tests inject a
/// fake driver, so no platform audio is required for contract verification.
final class FlutterCinematicMediaPreviewAdapter
    implements CinematicMediaPlaybackPort {
  FlutterCinematicMediaPreviewAdapter({
    required Iterable<CinematicMediaAsset> mediaAssets,
    required this.resolvePath,
    FlutterCinematicAudioDriver? driver,
    this.onFxChanged,
  })  : _mediaById = {for (final asset in mediaAssets) asset.id: asset},
        _driver = driver ?? FlameAudioCinematicPreviewDriver();

  final Map<String, CinematicMediaAsset> _mediaById;
  final CinematicPreviewMediaPathResolver resolvePath;
  final FlutterCinematicAudioDriver _driver;
  final ValueChanged<Set<String>>? onFxChanged;
  final Map<String, _PreviewChannel> _channels = {};
  final Set<String> _activeFxIds = {};

  @override
  Future<CinematicMediaPlaybackCheckpoint> captureCheckpoint() async =>
      CinematicMediaPlaybackCheckpoint(
        activeChannels: {
          for (final entry in _channels.entries)
            entry.key: entry.value.asset.id,
        },
        activeFxIds: _activeFxIds,
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
        final assetId = _required(command.assetId, 'assetId');
        _requireAsset(assetId, CinematicMediaAssetKind.cinematicFx);
        _activeFxIds.add(assetId);
        onFxChanged?.call(Set.unmodifiable(_activeFxIds));
      case CinematicMediaPlaybackCommandKind.cancelFx:
        _activeFxIds.remove(command.assetId);
        onFxChanged?.call(Set.unmodifiable(_activeFxIds));
      case CinematicMediaPlaybackCommandKind.restore:
        await restore(CinematicMediaPlaybackCheckpoint());
    }
  }

  @override
  Future<void> restore(CinematicMediaPlaybackCheckpoint checkpoint) async {
    final errors = <Object>[];
    for (final channel in _channels.values.toList(growable: false)) {
      try {
        await _driver.stop(channel.handle);
      } catch (error) {
        errors.add(error);
      }
    }
    _channels.clear();
    _activeFxIds
      ..clear()
      ..addAll(checkpoint.activeFxIds);
    onFxChanged?.call(Set.unmodifiable(_activeFxIds));
    for (final entry in checkpoint.activeChannels.entries) {
      final asset = _requireAsset(entry.value, null);
      try {
        final volume = checkpoint.channelVolumes[entry.key] ?? 1;
        final loop = checkpoint.loopingChannels.contains(entry.key);
        final handle = await _driver.play(
          resolvePath(asset),
          volume: volume,
          loop: loop,
        );
        _channels[entry.key] = _PreviewChannel(
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
      throw StateError('Media restore failed: ${errors.first}');
    }
  }

  Future<void> _play(CinematicMediaPlaybackCommand command) async {
    final assetId = _required(command.assetId, 'assetId');
    final channel = _required(command.channel, 'channel');
    final asset = _requireAsset(assetId, null);
    await _stopChannel(channel);
    final volume = command.volume ?? 1;
    final handle = await _driver.play(
      resolvePath(asset),
      volume:
          command.durationMs == null || command.durationMs == 0 ? volume : 0,
      loop: command.loop,
    );
    _channels[channel] = _PreviewChannel(
      asset: asset,
      handle: handle,
      volume: volume,
      loop: command.loop,
    );
    if ((command.durationMs ?? 0) > 0) {
      await _driver.setVolume(handle, volume);
    }
  }

  Future<void> _fade(CinematicMediaPlaybackCommand command) async {
    final channel = _required(command.channel, 'channel');
    final active = _channels[channel];
    if (active == null) return;
    final volume = command.volume ?? active.volume;
    await _driver.setVolume(active.handle, volume);
    _channels[channel] = active.copyWith(volume: volume);
  }

  Future<void> _stopChannel(String? channel) async {
    if (channel == null) return;
    final active = _channels.remove(channel);
    if (active != null) await _driver.stop(active.handle);
  }

  CinematicMediaAsset _requireAsset(
    String id,
    CinematicMediaAssetKind? expectedKind,
  ) {
    final asset = _mediaById[id];
    if (asset == null) throw StateError('Unknown cinematic media "$id".');
    if (expectedKind != null && asset.kind != expectedKind) {
      throw StateError('Cinematic media "$id" has incompatible kind.');
    }
    return asset;
  }
}

final class _PreviewChannel {
  const _PreviewChannel({
    required this.asset,
    required this.handle,
    required this.volume,
    required this.loop,
  });

  final CinematicMediaAsset asset;
  final Object handle;
  final double volume;
  final bool loop;

  _PreviewChannel copyWith({double? volume}) => _PreviewChannel(
        asset: asset,
        handle: handle,
        volume: volume ?? this.volume,
        loop: loop,
      );
}

String _required(String? value, String name) {
  if (value == null || value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'Required.');
  }
  return value;
}
