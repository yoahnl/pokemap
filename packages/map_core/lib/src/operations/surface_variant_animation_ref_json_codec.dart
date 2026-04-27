// JSON codec manuel (Lot 43) — [SurfaceVariantRole] + [SurfaceVariantAnimationRef].
//
// * Prépare la **future** persistance des **presets** Surface (variant animations)
//   **sans** branchement [ProjectManifest] et sans [toJson] / [fromJson] sur les
//   modèles (voir [SurfaceVariantAnimationRef] dans [surface.dart]).
// * [SurfaceVariantRole] : encodage = [EnumName.name] ; décodage **strict** sur
//   [SurfaceVariantRole.values] — **pas** de trim, pas de lowercasing, pas de
//   normalisation. Une seule faute de casse / espace / caractère → refus
//   ([ValidationException]).
// * [SurfaceVariantAnimationRef] : deux clés `role` (string) et `animationId` (string) ;
//   [animationId] n’est **pas** résolu contre [ProjectSurfaceAnimation] ni catalogue :
//   seulement la **forme** JSON + règles du constructeur (trim vide, etc.).
// * [SurfaceVariantAnimationRefSet] : **hors** de ce lot (Lot 44).
// * Décodage : clés inconnues **tolérées** ; [Map] source **jamais** mutée.

import '../exceptions/map_exceptions.dart';
import '../models/surface.dart';

/// Encodage V0 : nom exact d’énum ([SurfaceVariantRole.name]).
String encodeSurfaceVariantRole(SurfaceVariantRole role) => role.name;

String _validSurfaceVariantRoleListForMessage() =>
    SurfaceVariantRole.values.map((e) => e.name).join(', ');

/// Décodage **exact** : la chaîne doit être **identique** à [e.name] pour un
/// [e] de [SurfaceVariantRole.values] — ni trim, ni casse, ni alias.
SurfaceVariantRole decodeSurfaceVariantRole(String value) {
  for (final r in SurfaceVariantRole.values) {
    if (r.name == value) {
      return r;
    }
  }
  throw ValidationException(
    'SurfaceVariantRole: unknown or invalid value "$value"; '
    'valid: ${_validSurfaceVariantRoleListForMessage()}',
  );
}

Object? _required(
  Map<String, Object?> json,
  String key,
  String labelForError,
) {
  if (!json.containsKey(key)) {
    throw ValidationException('$labelForError is required');
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

/// Deux clés, ordre d’encodage : `role` puis `animationId`.
Map<String, Object?> encodeSurfaceVariantAnimationRef(
  SurfaceVariantAnimationRef ref,
) {
  return <String, Object?>{
    'role': encodeSurfaceVariantRole(ref.role),
    'animationId': ref.animationId,
  };
}

/// Clés inconnues ignorées. [role] / [animationId] validés en forme puis
/// [SurfaceVariantAnimationRef] pour la politique de chaîne d’[animationId].
SurfaceVariantAnimationRef decodeSurfaceVariantAnimationRef(
  Map<String, Object?> json,
) {
  final roleRaw = _reqNonNullString(
    'SurfaceVariantAnimationRef.role',
    _required(
      json,
      'role',
      'SurfaceVariantAnimationRef.role',
    ),
  );
  final role = decodeSurfaceVariantRole(roleRaw);

  final animId = _reqNonNullString(
    'SurfaceVariantAnimationRef.animationId',
    _required(
      json,
      'animationId',
      'SurfaceVariantAnimationRef.animationId',
    ),
  );

  return SurfaceVariantAnimationRef(
    role: role,
    animationId: animId,
  );
}
