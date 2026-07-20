import 'package:map_core/map_core.dart';

/// Runtime-facing alias for the neutral map_core boundary. Keeping the alias in
/// the application package prevents the Flame sink from inventing a second
/// media command vocabulary.
typedef CinematicRuntimeMediaPlaybackPort = CinematicMediaPlaybackPort;

CinematicMediaPlaybackCommand? cinematicMediaCommandForStep(
  CinematicTimelineStep step, {
  required Iterable<CinematicMediaAsset> mediaAssets,
}) {
  if (step.kind != CinematicTimelineStepKind.sound &&
      step.kind != CinematicTimelineStepKind.music &&
      step.kind != CinematicTimelineStepKind.fx) {
    return null;
  }
  final assetId = step.assetRef;
  if (assetId == null) {
    throw StateError('Cinematic step "${step.id}" has no media reference.');
  }
  CinematicMediaAsset? asset;
  for (final candidate in mediaAssets) {
    if (candidate.id == assetId) {
      asset = candidate;
      break;
    }
  }
  if (asset == null) {
    throw StateError('Unknown cinematic media "$assetId".');
  }
  final expectedKind = cinematicExpectedMediaKind(step.kind);
  if (asset.kind != expectedKind) {
    throw StateError('Cinematic media "$assetId" has incompatible kind.');
  }
  final channel = asset.channel ??
      switch (step.kind) {
        CinematicTimelineStepKind.sound => 'sound',
        CinematicTimelineStepKind.music => 'music',
        CinematicTimelineStepKind.fx => 'fx',
        _ => throw StateError('Unreachable media kind.'),
      };
  if (step.kind == CinematicTimelineStepKind.fx) {
    return CinematicMediaPlaybackCommand.spawnFx(
      commandId: 'runtime:${step.id}',
      assetId: assetId,
      channel: channel,
      durationMs: step.durationMs ?? asset.durationMs ?? 0,
      intensity: _doubleMetadata(
        step,
        cinematicTimelineCommandIntensityMetadataKey,
        0.5,
      ),
    );
  }
  return CinematicMediaPlaybackCommand.play(
    commandId: 'runtime:${step.id}',
    assetId: assetId,
    channel: channel,
    volume: _doubleMetadata(
      step,
      cinematicTimelineCommandVolumeMetadataKey,
      1,
    ),
    fadeMs: _intMetadata(
      step,
      cinematicTimelineCommandFadeMsMetadataKey,
      0,
    ),
    loop: step.metadata.containsKey(cinematicTimelineCommandLoopMetadataKey)
        ? step.metadata[cinematicTimelineCommandLoopMetadataKey] == 'true'
        : asset.loopByDefault,
  );
}

CinematicMediaPlaybackCommand? cinematicMediaEndCommandForStep(
  CinematicTimelineStep step,
) {
  final assetId = step.assetRef;
  if (step.kind != CinematicTimelineStepKind.fx || assetId == null) {
    return null;
  }
  return CinematicMediaPlaybackCommand.cancelFx(
    commandId: 'runtime:${step.id}:end',
    assetId: assetId,
  );
}

double _doubleMetadata(
  CinematicTimelineStep step,
  String key,
  double fallback,
) =>
    double.tryParse(step.metadata[key] ?? '') ?? fallback;

int _intMetadata(CinematicTimelineStep step, String key, int fallback) =>
    int.tryParse(step.metadata[key] ?? '') ?? fallback;
