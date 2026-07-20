import 'package:meta/meta.dart' show immutable;

enum CinematicMediaAssetKind { sound, music, cinematicFx }

@immutable
final class CinematicMediaAsset {
  CinematicMediaAsset({
    required String id,
    required String label,
    required this.kind,
    required String relativePath,
    this.durationMs,
    this.loopByDefault = false,
    String? channel,
    Map<String, String> metadata = const {},
  })  : id = _required(id, 'id'),
        label = _required(label, 'label'),
        relativePath = _required(relativePath, 'relativePath'),
        channel = _optional(channel),
        metadata = Map.unmodifiable(metadata) {
    if (durationMs != null && durationMs! <= 0) {
      throw ArgumentError.value(durationMs, 'durationMs', 'Must be positive.');
    }
  }

  factory CinematicMediaAsset.fromJson(Map<String, dynamic> json) =>
      CinematicMediaAsset(
        id: json['id'] as String,
        label: json['label'] as String,
        kind: CinematicMediaAssetKind.values.byName(json['kind'] as String),
        relativePath: json['relativePath'] as String,
        durationMs: json['durationMs'] as int?,
        loopByDefault: json['loopByDefault'] as bool? ?? false,
        channel: json['channel'] as String?,
        metadata: (json['metadata'] as Map?)?.map(
              (key, value) => MapEntry('$key', '$value'),
            ) ??
            const {},
      );

  final String id;
  final String label;
  final CinematicMediaAssetKind kind;
  final String relativePath;
  final int? durationMs;
  final bool loopByDefault;
  final String? channel;
  final Map<String, String> metadata;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'kind': kind.name,
        'relativePath': relativePath,
        if (durationMs != null) 'durationMs': durationMs,
        if (loopByDefault) 'loopByDefault': true,
        if (channel != null) 'channel': channel,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  @override
  bool operator ==(Object other) =>
      other is CinematicMediaAsset &&
      other.id == id &&
      other.label == label &&
      other.kind == kind &&
      other.relativePath == relativePath &&
      other.durationMs == durationMs &&
      other.loopByDefault == loopByDefault &&
      other.channel == channel &&
      _mapsEqual(other.metadata, metadata);

  @override
  int get hashCode => Object.hash(
        id,
        label,
        kind,
        relativePath,
        durationMs,
        loopByDefault,
        channel,
        Object.hashAll(metadata.entries),
      );
}

String _required(String value, String name) {
  final clean = value.trim();
  if (clean.isEmpty) throw ArgumentError.value(value, name, 'Required.');
  return clean;
}

String? _optional(String? value) {
  final clean = value?.trim();
  return clean == null || clean.isEmpty ? null : clean;
}

bool _mapsEqual(Map<String, String> a, Map<String, String> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}
