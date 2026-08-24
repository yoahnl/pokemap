import 'package:flame_audio/flame_audio.dart';
import 'package:map_core/map_core.dart';

import 'runtime_audio_mixer.dart';
import 'runtime_presentation_media_playback_controller.dart'
    show RuntimePresentationMediaUriResolver;

/// Executes the deterministic Presentation audio plan under the single
/// authority of the runtime mixer — BETA-CIN-076.
///
/// Every playing channel is registered on the mixer with its cinematic
/// route, so master, bus, mute and ducking always apply; the controller
/// itself never sets a volume outside the mixer. Holds and lifecycle pauses
/// suspend the sources position-preserving — resuming never restarts a loop
/// audibly — and leaving the presentation (stop, skip, error, disposal)
/// releases every handle and clears the ducking, after which stale async
/// completions are ignored by epoch.
abstract interface class RuntimePresentationAudioDriver {
  /// Starts [source].
  ///
  /// [mimeType] carries the catalog's declared media type. The media store is
  /// content-addressed, so every file lands at `<digest>.blob` with no
  /// extension: AVFoundation cannot infer a container from that name and
  /// refuses the item outright. The declared type is what lets it open the
  /// file anyway, and a media without one is played on the platform's own
  /// sniffing as before.
  Future<Object> play(
    Uri source, {
    required double volume,
    required bool loop,
    required Duration position,
    String? mimeType,
  });

  Future<void> pause(Object handle);

  Future<void> resume(Object handle);

  Future<void> setVolume(Object handle, double volume);

  Future<void> stop(Object handle);
}

final class FlameRuntimePresentationAudioDriver
    implements RuntimePresentationAudioDriver {
  @override
  Future<Object> play(
    Uri source, {
    required double volume,
    required bool loop,
    required Duration position,
    String? mimeType,
  }) async {
    final player = AudioPlayer();
    await player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.release);
    await player.play(
      DeviceFileSource(source.toFilePath(), mimeType: mimeType),
      volume: volume,
      position: position <= Duration.zero ? null : position,
    );
    return player;
  }

  @override
  Future<void> pause(Object handle) => (handle as AudioPlayer).pause();

  @override
  Future<void> resume(Object handle) => (handle as AudioPlayer).resume();

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

final class RuntimePresentationAudioFailure implements Exception {
  const RuntimePresentationAudioFailure({required this.diagnosticCode});

  final String diagnosticCode;

  @override
  String toString() =>
      'RuntimePresentationAudioFailure($diagnosticCode)';
}

final class _ActiveAudioChannel {
  _ActiveAudioChannel({
    required this.handle,
    required this.snapshot,
    required this.bus,
    required this.holdPolicy,
  });

  final Object handle;
  PresentationAudioChannelSnapshot snapshot;
  final PresentationAudioBus bus;
  final PresentationHoldTrackPolicy holdPolicy;
  bool suspendedByHold = false;
  bool suspendedByLifecycle = false;

  bool get suspended => suspendedByHold || suspendedByLifecycle;
}

final class RuntimePresentationAudioController {
  RuntimePresentationAudioController({
    required this.catalog,
    required this.resolveUri,
    required this.driver,
    required this.mixer,
    this.voiceDuckingGain = 0.35,
  });

  final ProjectMediaCatalog catalog;
  final RuntimePresentationMediaUriResolver resolveUri;
  final RuntimePresentationAudioDriver driver;
  final RuntimeAudioMixer mixer;
  final double voiceDuckingGain;

  final Map<String, _ActiveAudioChannel> _channels =
      <String, _ActiveAudioChannel>{};
  var _epoch = 0;
  var _duckingActive = false;
  var _holdDepth = 0;
  var _lifecycleSuspended = false;

  int get activeChannelCount => _channels.length;

  bool get isDucking => _duckingActive;

  /// Applies the pure plan for [frame] (null on terminal: everything stops).
  ///
  /// Throws [RuntimePresentationAudioFailure] fail-closed: an unknown clip in
  /// the frame, a media id missing from the catalog or a non-audio media all
  /// carry [PresentationDiagnosticCodes.mediaMissing]-family codes instead of
  /// playing something undefined.
  Future<void> synchronize(
    PresentationCinematicAsset asset,
    PresentationFrame? frame, {
    PresentationAudioOrientation orientation =
        PresentationAudioOrientation.landscape,
  }) async {
    final epoch = _epoch;
    final plan = planPresentationAudioCommands(
      asset: asset,
      frame: frame,
      activeChannels: [
        for (final channel in _channels.values) channel.snapshot,
      ],
      orientation: orientation,
    );
    if (plan.issues.isNotEmpty) {
      throw const RuntimePresentationAudioFailure(
        diagnosticCode: PresentationDiagnosticCodes.referenceMissing,
      );
    }
    for (final command in plan.commands) {
      if (_epoch != epoch) return;
      switch (command) {
        case PresentationAudioStopCommand(:final clipId):
          await _stopChannel(clipId);
        case PresentationAudioStartCommand():
          await _startChannel(command, epoch);
        case PresentationAudioSetVolumeCommand(:final clipId, :final volume):
          final channel = _channels[clipId];
          if (channel == null) continue;
          channel.snapshot = PresentationAudioChannelSnapshot(
            clipId: channel.snapshot.clipId,
            resourceId: channel.snapshot.resourceId,
            loop: channel.snapshot.loop,
            volume: volume,
          );
          await mixer.updateSourceVolume(channel.handle, volume);
      }
    }
    await _reconcileDucking();
  }

  /// Suspends every source position-preserving while a cue holds the
  /// timeline. Loops must survive the hold without an audible restart, so
  /// this pauses and [resumeFromHold] resumes — nothing is stopped.
  Future<void> pauseForHold() async {
    _holdDepth += 1;
    if (_holdDepth > 1) return;
    await _suspendAll(hold: true);
  }

  Future<void> resumeFromHold() async {
    if (_holdDepth == 0) return;
    _holdDepth -= 1;
    if (_holdDepth > 0) return;
    await _resumeSuspended(hold: true);
  }

  Future<void> pauseForLifecycle() async {
    if (_lifecycleSuspended) return;
    _lifecycleSuspended = true;
    await _suspendAll(hold: false);
  }

  Future<void> resumeAfterLifecycle() async {
    if (!_lifecycleSuspended) return;
    _lifecycleSuspended = false;
    await _resumeSuspended(hold: false);
  }

  /// Stops and unregisters every channel and clears the ducking. After this
  /// returns there is no active handle, and async completions from the
  /// previous epoch are ignored.
  Future<void> releaseAll() async {
    _epoch += 1;
    _holdDepth = 0;
    _lifecycleSuspended = false;
    final channels = _channels.values.toList(growable: false);
    _channels.clear();
    for (final channel in channels) {
      mixer.unregister(channel.handle);
      try {
        await driver.stop(channel.handle);
      } on Object {
        // Releasing must never fail the terminal path: the handle is gone
        // from every registry either way.
      }
    }
    if (_duckingActive) {
      _duckingActive = false;
      await mixer.clearDucking(this);
    }
  }

  Future<void> dispose() => releaseAll();

  Future<void> _startChannel(
    PresentationAudioStartCommand command,
    int epoch,
  ) async {
    final media = catalog.find(command.resourceId);
    if (media == null || media.kind != ProjectMediaKind.audio) {
      throw const RuntimePresentationAudioFailure(
        diagnosticCode: PresentationDiagnosticCodes.mediaMissing,
      );
    }
    final uri = resolveUri(media);
    final handle = await driver.play(
      uri,
      volume: 0,
      loop: command.loop,
      position: Duration(microseconds: command.positionUs),
      mimeType: media.technicalMetadata?.mediaType,
    );
    if (_epoch != epoch) {
      await driver.stop(handle);
      return;
    }
    final channel = _ActiveAudioChannel(
      handle: handle,
      snapshot: PresentationAudioChannelSnapshot(
        clipId: command.clipId,
        resourceId: command.resourceId,
        loop: command.loop,
        volume: command.volume,
      ),
      bus: command.bus,
      holdPolicy: command.holdPolicy,
    );
    _channels[command.clipId] = channel;
    await mixer.register(
      channel: handle,
      route: switch (command.bus) {
        PresentationAudioBus.music => RuntimeAudioRoute.cinematicMusic,
        PresentationAudioBus.voice ||
        PresentationAudioBus.effects =>
          RuntimeAudioRoute.cinematicEffects,
      },
      sourceVolume: command.volume,
      setVolume: (volume) => driver.setVolume(handle, volume),
    );
    if (_holdDepth > 0 &&
        command.holdPolicy == PresentationHoldTrackPolicy.frozen) {
      channel.suspendedByHold = true;
      await driver.pause(handle);
    }
    if (_lifecycleSuspended) {
      channel.suspendedByLifecycle = true;
      if (!channel.suspendedByHold) await driver.pause(handle);
    }
  }

  Future<void> _stopChannel(String clipId) async {
    final channel = _channels.remove(clipId);
    if (channel == null) return;
    mixer.unregister(channel.handle);
    await driver.stop(channel.handle);
  }

  Future<void> _suspendAll({required bool hold}) async {
    for (final channel in _channels.values) {
      if (hold &&
          channel.holdPolicy == PresentationHoldTrackPolicy.ambientContinues) {
        // Authored ambience keeps playing through the hold — only a real
        // pause or a lifecycle suspension may silence it.
        continue;
      }
      final wasSuspended = channel.suspended;
      if (hold) {
        channel.suspendedByHold = true;
      } else {
        channel.suspendedByLifecycle = true;
      }
      if (!wasSuspended) await driver.pause(channel.handle);
    }
  }

  Future<void> _resumeSuspended({required bool hold}) async {
    for (final channel in _channels.values) {
      if (hold) {
        channel.suspendedByHold = false;
      } else {
        channel.suspendedByLifecycle = false;
      }
      if (!channel.suspended) await driver.resume(channel.handle);
    }
  }

  Future<void> _reconcileDucking() async {
    final voiceActive = _channels.values.any(
      (channel) => channel.bus == PresentationAudioBus.voice,
    );
    if (voiceActive && !_duckingActive) {
      _duckingActive = true;
      await mixer.setDucking(
        owner: this,
        bus: RuntimeAudioBus.music,
        gain: voiceDuckingGain,
      );
    } else if (!voiceActive && _duckingActive) {
      _duckingActive = false;
      await mixer.clearDucking(this);
    }
  }
}
