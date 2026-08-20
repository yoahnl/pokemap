import 'package:meta/meta.dart' show immutable;

import '../models/presentation_cinematic_asset.dart';
import '../models/presentation_dialogue_contract.dart';
import 'presentation_frame.dart';

/// Deterministic audio scheduling of an evaluated Presentation frame —
/// BETA-CIN-076.
///
/// The planner is pure: it confronts the audio entries of one evaluated
/// frame with the channels currently playing and produces typed mixer
/// commands — start at the exact evaluated position, volume updates driven
/// by the authored fades, stops for everything that left the frame, and a
/// full stop on terminal. The same asset, frame and channel state always
/// produce the same command list in the same order, so preview and runtime
/// can never drift. A frame entry whose clip cannot be found in the asset is
/// a fail-closed issue, never a silent skip.
///
/// Music carries one shared source across orientations (enforced by the
/// asset schema); other audio kinds may carry two variants and fall back to
/// the single available version. Sound effects never loop unless explicitly
/// authored to.
enum PresentationAudioOrientation { landscape, portrait }

enum PresentationAudioPlanIssueCode { unknownAudioClip }

@immutable
final class PresentationAudioPlanIssue {
  const PresentationAudioPlanIssue({
    required this.clipId,
    required this.code,
  });

  final String clipId;
  final PresentationAudioPlanIssueCode code;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationAudioPlanIssue &&
          other.clipId == clipId &&
          other.code == code;

  @override
  int get hashCode => Object.hash(clipId, code);
}

/// What the runtime currently plays on one channel, keyed by clip id.
@immutable
final class PresentationAudioChannelSnapshot {
  const PresentationAudioChannelSnapshot({
    required this.clipId,
    required this.resourceId,
    required this.loop,
    required this.volume,
  });

  final String clipId;
  final String resourceId;
  final bool loop;
  final double volume;
}

sealed class PresentationAudioCommand {
  const PresentationAudioCommand();

  String get clipId;
}

@immutable
final class PresentationAudioStartCommand extends PresentationAudioCommand {
  const PresentationAudioStartCommand({
    required this.clipId,
    required this.resourceId,
    required this.positionUs,
    required this.loop,
    required this.volume,
    required this.audioKind,
    required this.bus,
    this.holdPolicy = PresentationHoldTrackPolicy.frozen,
  });

  @override
  final String clipId;
  final String resourceId;
  final int positionUs;
  final bool loop;
  final double volume;
  final PresentationAudioKind audioKind;
  final PresentationAudioBus bus;

  /// Derived from the owning track: whether this channel keeps playing
  /// while an interaction cue holds the timeline (BETA-CIN-077).
  final PresentationHoldTrackPolicy holdPolicy;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationAudioStartCommand &&
          other.clipId == clipId &&
          other.resourceId == resourceId &&
          other.positionUs == positionUs &&
          other.loop == loop &&
          other.volume == volume &&
          other.audioKind == audioKind &&
          other.bus == bus &&
          other.holdPolicy == holdPolicy;

  @override
  int get hashCode => Object.hash(
        clipId,
        resourceId,
        positionUs,
        loop,
        volume,
        audioKind,
        bus,
        holdPolicy,
      );
}

@immutable
final class PresentationAudioSetVolumeCommand
    extends PresentationAudioCommand {
  const PresentationAudioSetVolumeCommand({
    required this.clipId,
    required this.volume,
  });

  @override
  final String clipId;
  final double volume;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationAudioSetVolumeCommand &&
          other.clipId == clipId &&
          other.volume == volume;

  @override
  int get hashCode => Object.hash(clipId, volume);
}

@immutable
final class PresentationAudioStopCommand extends PresentationAudioCommand {
  const PresentationAudioStopCommand({required this.clipId});

  @override
  final String clipId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationAudioStopCommand && other.clipId == clipId;

  @override
  int get hashCode => clipId.hashCode;
}

@immutable
final class PresentationAudioPlan {
  PresentationAudioPlan({
    List<PresentationAudioCommand> commands =
        const <PresentationAudioCommand>[],
    List<PresentationAudioPlanIssue> issues =
        const <PresentationAudioPlanIssue>[],
  })  : commands = List<PresentationAudioCommand>.unmodifiable(commands),
        issues = List<PresentationAudioPlanIssue>.unmodifiable(issues);

  final List<PresentationAudioCommand> commands;
  final List<PresentationAudioPlanIssue> issues;
}

/// The authored volume shaped by the clip fades at the evaluated position.
///
/// Linear ramps: silence at the clip edge, authored volume once the fade
/// completes. The position is the single source of the value, so replaying
/// the same instant always renders the same volume.
double presentationAudioEffectiveVolume(
  PresentationAudioClip clip, {
  required int elapsedUs,
}) {
  final clamped = elapsedUs.clamp(0, clip.durationUs);
  var factor = 1.0;
  if (clip.fadeInUs > 0 && clamped < clip.fadeInUs) {
    factor = clamped / clip.fadeInUs;
  }
  final fadeOutStartUs = clip.durationUs - clip.fadeOutUs;
  if (clip.fadeOutUs > 0 && clamped > fadeOutStartUs) {
    final outFactor = (clip.durationUs - clamped) / clip.fadeOutUs;
    if (outFactor < factor) factor = outFactor;
  }
  return (clip.volume * factor).clamp(0.0, 1.0);
}

String presentationAudioResourceForOrientation(
  PresentationAudioClip clip,
  PresentationAudioOrientation orientation,
) {
  return switch (orientation) {
    PresentationAudioOrientation.landscape =>
      clip.landscapeResourceId ?? clip.resourceId,
    PresentationAudioOrientation.portrait =>
      clip.portraitResourceId ?? clip.resourceId,
  };
}

PresentationAudioPlan planPresentationAudioCommands({
  required PresentationCinematicAsset asset,
  required PresentationFrame? frame,
  required Iterable<PresentationAudioChannelSnapshot> activeChannels,
  PresentationAudioOrientation orientation =
      PresentationAudioOrientation.landscape,
}) {
  final channelsByClipId = <String, PresentationAudioChannelSnapshot>{
    for (final channel in activeChannels) channel.clipId: channel,
  };
  final commands = <PresentationAudioCommand>[];
  final issues = <PresentationAudioPlanIssue>[];

  final audioClipsById = <String, PresentationAudioClip>{
    for (final track in asset.tracks)
      for (final clip in track.clips)
        if (clip is PresentationAudioClip) clip.id: clip,
  };
  final holdPoliciesByClipId = <String, PresentationHoldTrackPolicy>{
    for (final track in asset.tracks)
      for (final clip in track.clips)
        if (clip is PresentationAudioClip) clip.id: track.holdPolicy,
  };

  final dueClipIds = <String>{};
  final frameAudio = (frame?.audio ?? const <PresentationAudioFrameClip>[])
      .toList(growable: false)
    ..sort((left, right) => left.clipId.compareTo(right.clipId));

  final starts = <PresentationAudioStartCommand>[];
  final volumeUpdates = <PresentationAudioSetVolumeCommand>[];
  final stops = <PresentationAudioStopCommand>[];

  for (final entry in frameAudio) {
    final clip = audioClipsById[entry.clipId];
    if (clip == null) {
      issues.add(
        PresentationAudioPlanIssue(
          clipId: entry.clipId,
          code: PresentationAudioPlanIssueCode.unknownAudioClip,
        ),
      );
      continue;
    }
    dueClipIds.add(entry.clipId);
    final resourceId = presentationAudioResourceForOrientation(
      clip,
      orientation,
    );
    final volume = presentationAudioEffectiveVolume(
      clip,
      elapsedUs: entry.elapsedUs,
    );
    final active = channelsByClipId[entry.clipId];
    if (active == null || active.resourceId != resourceId) {
      if (active != null) {
        stops.add(PresentationAudioStopCommand(clipId: entry.clipId));
      }
      starts.add(
        PresentationAudioStartCommand(
          clipId: entry.clipId,
          resourceId: resourceId,
          positionUs: entry.elapsedUs,
          loop: clip.loop,
          volume: volume,
          audioKind: clip.audioKind,
          bus: clip.bus,
          holdPolicy: holdPoliciesByClipId[entry.clipId] ??
              PresentationHoldTrackPolicy.frozen,
        ),
      );
      continue;
    }
    if ((active.volume - volume).abs() > 1e-9) {
      volumeUpdates.add(
        PresentationAudioSetVolumeCommand(
          clipId: entry.clipId,
          volume: volume,
        ),
      );
    }
  }

  for (final channel in channelsByClipId.values) {
    if (!dueClipIds.contains(channel.clipId)) {
      stops.add(PresentationAudioStopCommand(clipId: channel.clipId));
    }
  }

  stops.sort((left, right) => left.clipId.compareTo(right.clipId));
  commands
    ..addAll(stops)
    ..addAll(starts)
    ..addAll(volumeUpdates);
  return PresentationAudioPlan(commands: commands, issues: issues);
}
