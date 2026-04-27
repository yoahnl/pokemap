// JSON codec manuel (Lot 42) — [ProjectSurfaceAnimation].
//
// * Prépare la **future** persistance Surface **sans** branchement [ProjectManifest].
// * [timeline] : délégation stricte à [encodeSurfaceAnimationTimeline] /
//   [decodeSurfaceAnimationTimeline] (Lot 41) — pas de contournement du codec
//   timeline, pas de second schéma de [frames] ici.
// * Aucun [toJson] / [fromJson] sur le modèle : [ProjectSurfaceAnimation] reste
//   dans [surface.dart] en pur domaine.
// * **Géométrie** : pas d’[isInside] ici (pas d’[SurfaceAtlasGeometry] en entrée) ;
//   le même JSON peut décrire des cellules (999, 999) qu’un atlas réel n’a pas.
// * **Résolution de références** : pas de vérification d’[atlasId], tileset, ou
//   d’enregistrement de catalogue / manifest — seulement la **forme** JSON.
// * Décodage : clés inconnues **tolérées** ; [Map] sources **jamais** mutées.
//
// * V0 encodage : [syncGroupId] et [categoryId] **absents** si `null` ;
//   [sortOrder] **toujours** présent.

import '../exceptions/map_exceptions.dart';
import '../models/surface.dart';
import 'surface_animation_timeline_json_codec.dart';

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

String _reqNonNullString(
  String fieldKey,
  Object? value,
) {
  if (value is! String) {
    throw ValidationException('$fieldKey must be a non-null String');
  }
  return value;
}

String? _optionalStringOrNull(
  Map<String, Object?> json,
  String key,
  String errorWhenWrongType,
) {
  if (!json.containsKey(key)) {
    return null;
  }
  final v = json[key];
  if (v == null) {
    return null;
  }
  if (v is! String) {
    throw ValidationException(errorWhenWrongType);
  }
  return v;
}

int _sortOrder(Map<String, Object?> json) {
  if (!json.containsKey('sortOrder')) {
    return 0;
  }
  final v = json['sortOrder'];
  if (v is! int) {
    throw const ValidationException(
      'ProjectSurfaceAnimation.sortOrder must be an int',
    );
  }
  return v;
}

/// Encodage : [id], [name], [timeline] ; [syncGroupId] / [categoryId] seulement
/// si non `null` ; [sortOrder] **toujours** (V0).
Map<String, Object?> encodeProjectSurfaceAnimation(
  ProjectSurfaceAnimation animation,
) {
  final out = <String, Object?>{
    'id': animation.id,
    'name': animation.name,
    'timeline': encodeSurfaceAnimationTimeline(animation.timeline),
  };
  if (animation.syncGroupId != null) {
    out['syncGroupId'] = animation.syncGroupId;
  }
  if (animation.categoryId != null) {
    out['categoryId'] = animation.categoryId;
  }
  out['sortOrder'] = animation.sortOrder;
  return out;
}

ProjectSurfaceAnimation decodeProjectSurfaceAnimation(
  Map<String, Object?> json,
) {
  final id = _reqNonNullString(
    'ProjectSurfaceAnimation.id',
    _valueForRequiredKey(
      json,
      'id',
      'ProjectSurfaceAnimation.id',
    ),
  );
  final name = _reqNonNullString(
    'ProjectSurfaceAnimation.name',
    _valueForRequiredKey(
      json,
      'name',
      'ProjectSurfaceAnimation.name',
    ),
  );

  final tl = _valueForRequiredKey(
    json,
    'timeline',
    'ProjectSurfaceAnimation.timeline',
  );
  if (tl is! Map) {
    throw const ValidationException(
      'ProjectSurfaceAnimation.timeline must be an Object',
    );
  }
  final timeline = decodeSurfaceAnimationTimeline(
    _stringKeyMapFrom(tl),
  );

  final syncGroupId = _optionalStringOrNull(
    json,
    'syncGroupId',
    'ProjectSurfaceAnimation.syncGroupId must be a String or null',
  );
  final categoryId = _optionalStringOrNull(
    json,
    'categoryId',
    'ProjectSurfaceAnimation.categoryId must be a String or null',
  );
  final sortOrder = _sortOrder(json);

  return ProjectSurfaceAnimation(
    id: id,
    name: name,
    timeline: timeline,
    syncGroupId: syncGroupId,
    categoryId: categoryId,
    sortOrder: sortOrder,
  );
}
