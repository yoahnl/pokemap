import 'package:meta/meta.dart' show immutable;

enum CinematicMediaPlaybackCommandKind {
  play,
  stopChannel,
  fadeChannel,
  spawnFx,
  cancelFx,
  restore,
}

@immutable
final class CinematicMediaPlaybackCommand {
  const CinematicMediaPlaybackCommand._({
    required this.commandId,
    required this.kind,
    this.assetId,
    this.channel,
    this.volume,
    this.durationMs,
    this.loop = false,
    this.intensity,
  });

  factory CinematicMediaPlaybackCommand.play({
    required String commandId,
    required String assetId,
    required String channel,
    double volume = 1,
    bool loop = false,
    int fadeMs = 0,
  }) =>
      CinematicMediaPlaybackCommand._(
        commandId: commandId,
        kind: CinematicMediaPlaybackCommandKind.play,
        assetId: assetId,
        channel: channel,
        volume: volume,
        loop: loop,
        durationMs: fadeMs,
      );

  factory CinematicMediaPlaybackCommand.stopChannel({
    required String commandId,
    required String channel,
  }) =>
      CinematicMediaPlaybackCommand._(
        commandId: commandId,
        kind: CinematicMediaPlaybackCommandKind.stopChannel,
        channel: channel,
      );

  factory CinematicMediaPlaybackCommand.fadeChannel({
    required String commandId,
    required String channel,
    required double volume,
    required int durationMs,
  }) =>
      CinematicMediaPlaybackCommand._(
        commandId: commandId,
        kind: CinematicMediaPlaybackCommandKind.fadeChannel,
        channel: channel,
        volume: volume,
        durationMs: durationMs,
      );

  factory CinematicMediaPlaybackCommand.spawnFx({
    required String commandId,
    required String assetId,
    required String channel,
    required int durationMs,
    double intensity = 0.5,
  }) =>
      CinematicMediaPlaybackCommand._(
        commandId: commandId,
        kind: CinematicMediaPlaybackCommandKind.spawnFx,
        assetId: assetId,
        channel: channel,
        durationMs: durationMs,
        intensity: intensity,
      );

  factory CinematicMediaPlaybackCommand.cancelFx({
    required String commandId,
    required String assetId,
  }) =>
      CinematicMediaPlaybackCommand._(
        commandId: commandId,
        kind: CinematicMediaPlaybackCommandKind.cancelFx,
        assetId: assetId,
      );

  factory CinematicMediaPlaybackCommand.restore({required String commandId}) =>
      CinematicMediaPlaybackCommand._(
        commandId: commandId,
        kind: CinematicMediaPlaybackCommandKind.restore,
      );

  factory CinematicMediaPlaybackCommand.fromJson(Map<String, dynamic> json) =>
      CinematicMediaPlaybackCommand._(
        commandId: json['commandId'] as String,
        kind: CinematicMediaPlaybackCommandKind.values
            .byName(json['kind'] as String),
        assetId: json['assetId'] as String?,
        channel: json['channel'] as String?,
        volume: (json['volume'] as num?)?.toDouble(),
        durationMs: json['durationMs'] as int?,
        loop: json['loop'] as bool? ?? false,
        intensity: (json['intensity'] as num?)?.toDouble(),
      );

  final String commandId;
  final CinematicMediaPlaybackCommandKind kind;
  final String? assetId;
  final String? channel;
  final double? volume;
  final int? durationMs;
  final bool loop;
  final double? intensity;

  Map<String, dynamic> toJson() => {
        'commandId': commandId,
        'kind': kind.name,
        if (assetId != null) 'assetId': assetId,
        if (channel != null) 'channel': channel,
        if (volume != null) 'volume': volume,
        if (durationMs != null) 'durationMs': durationMs,
        if (loop) 'loop': true,
        if (intensity != null) 'intensity': intensity,
      };

  @override
  bool operator ==(Object other) =>
      other is CinematicMediaPlaybackCommand &&
      other.commandId == commandId &&
      other.kind == kind &&
      other.assetId == assetId &&
      other.channel == channel &&
      other.volume == volume &&
      other.durationMs == durationMs &&
      other.loop == loop &&
      other.intensity == intensity;

  @override
  int get hashCode => Object.hash(
        commandId,
        kind,
        assetId,
        channel,
        volume,
        durationMs,
        loop,
        intensity,
      );
}

@immutable
final class CinematicMediaPlaybackCheckpoint {
  CinematicMediaPlaybackCheckpoint({
    Map<String, String> activeChannels = const {},
    Set<String> activeFxIds = const {},
    Map<String, double> channelVolumes = const {},
    Set<String> loopingChannels = const {},
  })  : activeChannels = Map.unmodifiable(activeChannels),
        activeFxIds = Set.unmodifiable(activeFxIds),
        channelVolumes = Map.unmodifiable(channelVolumes),
        loopingChannels = Set.unmodifiable(loopingChannels);

  factory CinematicMediaPlaybackCheckpoint.fromJson(
    Map<String, dynamic> json,
  ) =>
      CinematicMediaPlaybackCheckpoint(
        activeChannels: (json['activeChannels'] as Map?)?.map(
              (key, value) => MapEntry('$key', '$value'),
            ) ??
            const {},
        activeFxIds:
            (json['activeFxIds'] as List?)?.map((value) => '$value').toSet() ??
                const {},
        channelVolumes: (json['channelVolumes'] as Map?)?.map(
              (key, value) => MapEntry('$key', (value as num).toDouble()),
            ) ??
            const {},
        loopingChannels: (json['loopingChannels'] as List?)
                ?.map((value) => '$value')
                .toSet() ??
            const {},
      );

  final Map<String, String> activeChannels;
  final Set<String> activeFxIds;
  final Map<String, double> channelVolumes;
  final Set<String> loopingChannels;

  Map<String, dynamic> toJson() => {
        'activeChannels': activeChannels,
        'activeFxIds': activeFxIds.toList()..sort(),
        'channelVolumes': channelVolumes,
        'loopingChannels': loopingChannels.toList()..sort(),
      };

  @override
  bool operator ==(Object other) =>
      other is CinematicMediaPlaybackCheckpoint &&
      _mapsEqual(other.activeChannels, activeChannels) &&
      other.activeFxIds.length == activeFxIds.length &&
      other.activeFxIds.containsAll(activeFxIds) &&
      _doubleMapsEqual(other.channelVolumes, channelVolumes) &&
      other.loopingChannels.length == loopingChannels.length &&
      other.loopingChannels.containsAll(loopingChannels);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(activeChannels.entries),
        Object.hashAll(activeFxIds),
        Object.hashAll(channelVolumes.entries),
        Object.hashAll(loopingChannels),
      );
}

abstract interface class CinematicMediaPlaybackPort {
  Future<CinematicMediaPlaybackCheckpoint> captureCheckpoint();
  Future<void> execute(CinematicMediaPlaybackCommand command);
  Future<void> restore(CinematicMediaPlaybackCheckpoint checkpoint);
}

bool _mapsEqual(Map<String, String> a, Map<String, String> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

bool _doubleMapsEqual(Map<String, double> a, Map<String, double> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}
