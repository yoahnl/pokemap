// JSON codec manuel (Lot 45) — [ProjectSurfacePreset].
//
// * Prépare la **future** persistance de **catalogues** Surface (Lot 46+) **sans**
//   branchement [ProjectManifest] et sans [toJson] / [fromJson] sur le modèle.
// * [variantAnimations] : délégation stricte à [encodeSurfaceVariantAnimationRefSet] /
//   [decodeSurfaceVariantAnimationRefSet] (Lot 44) — ordre des refs = celui du
//   [SurfaceVariantAnimationRefSet], **aucun** retri, **aucune** complétion de
//   rôles manquants ici.
// * **Pas** de résolution d’[animationId] → [ProjectSurfaceAnimation] : seulement
//   forme JSON + invariants [SurfaceVariantAnimationRef] / [RefSet].
// * Pas de [SurfacePresetKind], pas de clé [surfaceKind] : V0 auteur, visuel.
// * Aucun codec [ProjectSurfaceCatalog] ici.
// * Décodage : clés inconnues **tolérées** ; [Map] sources **jamais** mutées.
//
// * V0 encodage : [categoryId] **absent** si `null` ; [sortOrder] **toujours** présent.

import '../exceptions/map_exceptions.dart';
import '../models/surface.dart';
import 'surface_variant_animation_ref_set_json_codec.dart';

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
      'ProjectSurfacePreset.sortOrder must be an int',
    );
  }
  return v;
}

/// Encodage : [id], [name], [variantAnimations] ; [categoryId] seulement si non
/// `null` ; [sortOrder] **toujours** (V0).
Map<String, Object?> encodeProjectSurfacePreset(
  ProjectSurfacePreset preset,
) {
  final out = <String, Object?>{
    'id': preset.id,
    'name': preset.name,
    'variantAnimations': encodeSurfaceVariantAnimationRefSet(
      preset.variantAnimations,
    ),
  };
  if (preset.categoryId != null) {
    out['categoryId'] = preset.categoryId;
  }
  out['sortOrder'] = preset.sortOrder;
  return out;
}

ProjectSurfacePreset decodeProjectSurfacePreset(
  Map<String, Object?> json,
) {
  final id = _reqNonNullString(
    'ProjectSurfacePreset.id',
    _valueForRequiredKey(
      json,
      'id',
      'ProjectSurfacePreset.id',
    ),
  );
  final name = _reqNonNullString(
    'ProjectSurfacePreset.name',
    _valueForRequiredKey(
      json,
      'name',
      'ProjectSurfacePreset.name',
    ),
  );

  final va = _valueForRequiredKey(
    json,
    'variantAnimations',
    'ProjectSurfacePreset.variantAnimations',
  );
  if (va is! Map) {
    throw const ValidationException(
      'ProjectSurfacePreset.variantAnimations must be an Object',
    );
  }
  final refSet = decodeSurfaceVariantAnimationRefSet(
    _stringKeyMapFrom(va),
  );

  final categoryId = _optionalStringOrNull(
    json,
    'categoryId',
    'ProjectSurfacePreset.categoryId must be a String or null',
  );
  final sortOrder = _sortOrder(json);

  return ProjectSurfacePreset(
    id: id,
    name: name,
    variantAnimations: refSet,
    categoryId: categoryId,
    sortOrder: sortOrder,
  );
}
