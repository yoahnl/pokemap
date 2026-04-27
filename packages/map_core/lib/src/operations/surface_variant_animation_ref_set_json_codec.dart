// JSON codec manuel (Lot 44) — [SurfaceVariantAnimationRefSet].
//
// * Prépare la **future** persistance de [ProjectSurfacePreset] (champ
//   `variantAnimations`) **sans** branchement [ProjectManifest] et sans
//   [toJson] / [fromJson] sur le modèle.
// * Chaque élément de `refs` est encodé / décodé **uniquement** via
//   [encodeSurfaceVariantAnimationRef] / [decodeSurfaceVariantAnimationRef]
//   (Lot 43) — pas de second schéma de ref, pas de contournement.
// * L’**ordre** de [SurfaceVariantAnimationRefSet.refs] est **préservé** :
//   **pas** de tri sur [standardSurfaceVariantRoleOrder], **pas** de complétion
//   des rôles manquants, **pas** de fusion ni déduplication côté codec
//   (l’**unicité** de rôle est celle de [SurfaceVariantAnimationRefSet]).
// * [animationId] : **aucune** résolution vers [ProjectSurfaceAnimation] ni
//   catalogue — seulement forme JSON + règles des refs.
// * Décodage : clés inconnues **tolérées** ; [Map] sources **jamais** mutées
//   (copies [Map] pour chaque item avant [decodeSurfaceVariantAnimationRef]).

import '../exceptions/map_exceptions.dart';
import '../models/surface.dart';
import 'surface_variant_animation_ref_json_codec.dart';

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

/// Une seule clé de premier niveau : [refs] ; ordre des entrées = ordre de
/// [refSet.refs] (aucun retri).
Map<String, Object?> encodeSurfaceVariantAnimationRefSet(
  SurfaceVariantAnimationRefSet refSet,
) {
  return <String, Object?>{
    'refs': refSet.refs
        .map(encodeSurfaceVariantAnimationRef)
        .toList(growable: false),
  };
}

/// [refs] requis, [List] d’[Map] (objets JSON) ; chaque item via le codec ref
/// Lot 43 ; [SurfaceVariantAnimationRefSet] valide non-vide + rôles uniques.
SurfaceVariantAnimationRefSet decodeSurfaceVariantAnimationRefSet(
  Map<String, Object?> json,
) {
  final v = _valueForRequiredKey(
    json,
    'refs',
    'SurfaceVariantAnimationRefSet.refs',
  );
  if (v is! List) {
    throw const ValidationException(
      'SurfaceVariantAnimationRefSet.refs must be a List',
    );
  }
  final decoded = <SurfaceVariantAnimationRef>[];
  for (var i = 0; i < v.length; i++) {
    final e = v[i];
    if (e is! Map) {
      throw ValidationException(
        'SurfaceVariantAnimationRefSet.refs[$i] must be an Object',
      );
    }
    decoded.add(
      decodeSurfaceVariantAnimationRef(
        _stringKeyMapFrom(e),
      ),
    );
  }
  return SurfaceVariantAnimationRefSet(refs: decoded);
}
