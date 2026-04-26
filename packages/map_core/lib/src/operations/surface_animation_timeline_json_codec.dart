// JSON codec manuel (Lot 41) — [SurfaceAnimationTimeline].
//
// * Prépare une **future** persistance Surface **sans** brancher [ProjectManifest].
// * Réutilise [encodeSurfaceAnimationFrame] / [decodeSurfaceAnimationFrame] du
//   Lot 40 : une timeline est une **liste ordonnée** de frames, sans
//   normalisation, tri, fusion, ni ajustement de [durationMs] (V0).
// * La **géométrie d’atlas** n’est **pas** vérifiée ici (pas d’[isInside] sur
//   chaque frame) — les indices (column, row) arbitraires se décodent comme en
//   Lot 40.
// * Décodage : clés inconnues (top-level, dans chaque map de frame, dans
//   chaque [tileRef]) **tolérées** ; [Map] sources **jamais** mutées (copies
//   défensives quand on normalise [Map<dynamic, dynamic>]).
// * [SurfaceAnimationTimeline] et les modèles [surface.dart] restent **sans**
//   `toJson` / `fromJson` : [ProjectSurfaceAnimation] (Lot 42+) reste un codec
//   **distinct**.

import '../exceptions/map_exceptions.dart';
import '../models/surface.dart';
import 'surface_animation_frame_json_codec.dart';

/// Copie défensive, clés en [String] (décodage : Map dynamique).
Map<String, Object?> _stringKeyMapFrom(Object mapLike) {
  final m = mapLike as Map<dynamic, dynamic>;
  return Map<String, Object?>.from(
    m.map(
      (dynamic k, dynamic v) => MapEntry(
        k is String ? k : k.toString(),
        v as Object?,
      ),
    ),
  );
}

Object? _valueForRequiredKey(
  Map<String, Object?> json,
  String key,
  String errorPrefix,
) {
  if (!json.containsKey(key)) {
    throw ValidationException('$errorPrefix is required');
  }
  return json[key];
}

/// Encodage : seule clé `frames` ; chaque [SurfaceAnimationFrame] via le
/// codec du Lot 40 ; ordre stable.
Map<String, Object?> encodeSurfaceAnimationTimeline(
  SurfaceAnimationTimeline timeline,
) {
  return <String, Object?>{
    'frames': <Object?>[
      for (final f in timeline.frames) encodeSurfaceAnimationFrame(f),
    ],
  };
}

/// Décodage : `frames` requis, liste d’objets mappables ; chaque élément via
/// [decodeSurfaceAnimationFrame] ; [SurfaceAnimationTimeline] valide la
/// non-vacuité.
SurfaceAnimationTimeline decodeSurfaceAnimationTimeline(
  Map<String, Object?> json,
) {
  final raw = _valueForRequiredKey(
    json,
    'frames',
    'SurfaceAnimationTimeline.frames',
  );
  if (raw is! List) {
    throw const ValidationException(
      'SurfaceAnimationTimeline.frames must be a List',
    );
  }

  final decoded = <SurfaceAnimationFrame>[];
  for (var i = 0; i < raw.length; i++) {
    final el = raw[i];
    if (el is! Map) {
      throw ValidationException(
        'SurfaceAnimationTimeline.frames[$i] must be an Object',
      );
    }
    decoded.add(
      decodeSurfaceAnimationFrame(
        _stringKeyMapFrom(el),
      ),
    );
  }

  return SurfaceAnimationTimeline(frames: decoded);
}
