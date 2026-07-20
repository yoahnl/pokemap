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
  });

  factory CinematicMediaPlaybackCommand.play({
    required String commandId,
    required String assetId,
    required String channel,
    double volume = 1,
    bool loop = false,
  }) =>
      CinematicMediaPlaybackCommand._(
        commandId: commandId,
        kind: CinematicMediaPlaybackCommandKind.play,
        assetId: assetId,
        channel: channel,
        volume: volume,
        loop: loop,
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
      );

  final String commandId;
  final CinematicMediaPlaybackCommandKind kind;
  final String? assetId;
  final String? channel;
  final double? volume;
  final int? durationMs;
  final bool loop;

  Map<String, dynamic> toJson() => {
        'commandId': commandId,
        'kind': kind.name,
        if (assetId != null) 'assetId': assetId,
        if (channel != null) 'channel': channel,
        if (volume != null) 'volume': volume,
        if (durationMs != null) 'durationMs': durationMs,
        if (loop) 'loop': true,
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
      other.loop == loop;

  @override
  int get hashCode => Object.hash(
        commandId,
        kind,
        assetId,
        channel,
        volume,
        durationMs,
        loop,
      );
}

@immutable
final class CinematicMediaPlaybackCheckpoint {
  CinematicMediaPlaybackCheckpoint({
    Map<String, String> activeChannels = const {},
    Set<String> activeFxIds = const {},
  })  : activeChannels = Map.unmodifiable(activeChannels),
        activeFxIds = Set.unmodifiable(activeFxIds);

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
      );

  final Map<String, String> activeChannels;
  final Set<String> activeFxIds;

  Map<String, dynamic> toJson() => {
        'activeChannels': activeChannels,
        'activeFxIds': activeFxIds.toList()..sort(),
      };

  @override
  bool operator ==(Object other) =>
      other is CinematicMediaPlaybackCheckpoint &&
      _mapsEqual(other.activeChannels, activeChannels) &&
      other.activeFxIds.length == activeFxIds.length &&
      other.activeFxIds.containsAll(activeFxIds);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(activeChannels.entries),
        Object.hashAll(activeFxIds),
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
