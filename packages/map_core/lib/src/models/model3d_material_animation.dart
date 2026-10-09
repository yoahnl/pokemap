import 'dart:math' as math;

final class Model3dMaterialAnimations {
  const Model3dMaterialAnimations._(this.clips);

  final List<Model3dMaterialAnimationClip> clips;

  factory Model3dMaterialAnimations.fromGlbJson(Map<String, dynamic> json) {
    final extras = json['extras'];
    if (extras is! Map || !extras.containsKey('aveluneMaterialAnimations')) {
      return const Model3dMaterialAnimations._([]);
    }
    final document = _object(extras['aveluneMaterialAnimations']);
    _keys(document, {'schemaVersion', 'clips'});
    if (document['schemaVersion'] != 1) {
      throw const FormatException('Unsupported material animation version.');
    }
    final rawClips = _list(document['clips'], 256);
    final materialCount = _list(json['materials'], 1024).length;
    final textureCount = _list(json['textures'], 1024).length;
    final nodeClipCount = _list(json['animations'], 256).length;
    var trackBudget = 0;
    var keyBudget = 0;
    final clips = <Model3dMaterialAnimationClip>[];
    for (final raw in rawClips) {
      final clip = _object(raw);
      _keys(clip, {'name', 'durationSeconds', 'nodeAnimationIndex', 'tracks'});
      final name = clip['name'];
      if (name is! String || name.trim().isEmpty || name.length > 256) {
        throw const FormatException('Invalid material animation name.');
      }
      final duration = _duration(clip['durationSeconds']);
      final nodeIndex = clip['nodeAnimationIndex'];
      if (nodeIndex != null) _index(nodeIndex, nodeClipCount);
      final rawTracks = _list(clip['tracks'], 4096);
      trackBudget += rawTracks.length;
      if (rawTracks.isEmpty || trackBudget > 4096) {
        throw const FormatException('Invalid material animation track budget.');
      }
      final targets = <int>{};
      final tracks = <Model3dMaterialAnimationTrack>[];
      for (final rawTrack in rawTracks) {
        final track = _object(rawTrack);
        _keys(track, {
          'materialIndex',
          'durationSeconds',
          'times',
          'transforms',
          'interpolation',
          'textureIndices',
        });
        final target = _index(track['materialIndex'], materialCount);
        if (!targets.add(target)) {
          throw const FormatException('Duplicate material animation target.');
        }
        final trackDuration = _duration(track['durationSeconds'] ?? duration);
        if (trackDuration > duration) {
          throw const FormatException('Material track exceeds clip duration.');
        }
        final interpolation = track['interpolation'];
        if (interpolation != 'LINEAR' && interpolation != 'STEP') {
          throw const FormatException('Unsupported material interpolation.');
        }
        final times = _list(track['times'], 65536).map(_number).toList();
        keyBudget += times.length;
        if (times.isEmpty || keyBudget > 131072 || times.first != 0) {
          throw const FormatException('Invalid material animation key budget.');
        }
        for (var i = 0; i < times.length; i++) {
          if (times[i] < 0 ||
              times[i] > trackDuration ||
              (i > 0 && times[i] <= times[i - 1])) {
            throw const FormatException(
              'Material key times must strictly increase.',
            );
          }
        }
        final rows = _list(track['transforms'], 65536);
        if (rows.length != times.length) {
          throw const FormatException('Material transform key count mismatch.');
        }
        final transforms = <List<double>>[];
        for (final rawRow in rows) {
          final row = _list(rawRow, 6);
          if (row.length != 6) {
            throw const FormatException(
              'UV transforms require six components.',
            );
          }
          transforms.add(List.unmodifiable(row.map(_number)));
        }
        List<int>? textures;
        if (track['textureIndices'] != null) {
          textures = _list(
            track['textureIndices'],
            65536,
          ).map((value) => _index(value, textureCount)).toList();
          if (textures.length != times.length) {
            throw const FormatException('Material texture key count mismatch.');
          }
        }
        tracks.add(
          Model3dMaterialAnimationTrack._(
            materialIndex: target,
            durationSeconds: trackDuration,
            times: List.unmodifiable(times),
            transforms: List.unmodifiable(transforms),
            interpolation: interpolation as String,
            textureIndices: textures == null
                ? null
                : List.unmodifiable(textures),
          ),
        );
      }
      clips.add(
        Model3dMaterialAnimationClip._(
          name: name.trim(),
          durationSeconds: duration,
          nodeAnimationIndex: nodeIndex as int?,
          tracks: List.unmodifiable(tracks),
        ),
      );
    }
    return Model3dMaterialAnimations._(List.unmodifiable(clips));
  }
}

final class Model3dMaterialAnimationClip {
  const Model3dMaterialAnimationClip._({
    required this.name,
    required this.durationSeconds,
    required this.nodeAnimationIndex,
    required this.tracks,
  });

  final String name;
  final double durationSeconds;
  final int? nodeAnimationIndex;
  final List<Model3dMaterialAnimationTrack> tracks;
}

final class Model3dMaterialAnimationTrack {
  const Model3dMaterialAnimationTrack._({
    required this.materialIndex,
    required this.durationSeconds,
    required this.times,
    required this.transforms,
    required this.interpolation,
    required this.textureIndices,
  });

  final int materialIndex;
  final double durationSeconds;
  final List<double> times;
  final List<List<double>> transforms;
  final String interpolation;
  final List<int>? textureIndices;

  Model3dMaterialAnimationSample sample(double seconds, {bool loop = true}) {
    if (!seconds.isFinite || seconds < 0) {
      throw ArgumentError.value(
        seconds,
        'seconds',
        'Expected finite positive time.',
      );
    }
    final time = loop
        ? seconds % durationSeconds
        : math.min(seconds, durationSeconds);
    var low = 0;
    var high = times.length;
    while (low < high) {
      final middle = (low + high) ~/ 2;
      if (times[middle] <= time) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    final index = math.max(0, low - 1);
    final left = transforms[index];
    final factor = interpolation == 'STEP' || index == times.length - 1
        ? 0.0
        : (time - times[index]) / (times[index + 1] - times[index]);
    final transform = factor == 0
        ? left
        : List<double>.unmodifiable(
            List.generate(
              6,
              (component) =>
                  left[component] +
                  (transforms[index + 1][component] - left[component]) * factor,
            ),
          );
    return Model3dMaterialAnimationSample(
      transform: transform,
      textureIndex: textureIndices?[index],
    );
  }
}

final class Model3dMaterialAnimationSample {
  const Model3dMaterialAnimationSample({
    required this.transform,
    this.textureIndex,
  });
  final List<double> transform;
  final int? textureIndex;
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map) {
    throw const FormatException('Expected material animation object.');
  }
  return Map<String, dynamic>.from(value);
}

List<dynamic> _list(Object? value, int limit) {
  if (value == null) return const [];
  if (value is! List || value.length > limit) {
    throw const FormatException('Invalid material animation list.');
  }
  return value;
}

double _number(Object? value) {
  if (value is! num || !value.isFinite || value.abs() > 1e9) {
    throw const FormatException('Invalid material animation numeric value.');
  }
  return value.toDouble();
}

double _duration(Object? value) {
  final duration = _number(value);
  if (duration <= 0 || duration > 86400) {
    throw const FormatException('Invalid material animation duration.');
  }
  return duration;
}

int _index(Object? value, int count) {
  if (value is! int || value < 0 || value >= count) {
    throw const FormatException('Invalid material animation target index.');
  }
  return value;
}

void _keys(Map<String, dynamic> json, Set<String> keys) {
  if (json.keys.any((key) => !keys.contains(key))) {
    throw const FormatException('Unknown material animation fields.');
  }
}
