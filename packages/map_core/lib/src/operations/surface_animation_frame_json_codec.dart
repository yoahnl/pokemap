// JSON codec manuel (Lot 40) — [SurfaceAtlasTileRef] et [SurfaceAnimationFrame].
//
// * Prépare une **future** persistance Surface **sans** brancher [ProjectManifest]
//   ni ajouter de champs manifest dans ce lot.
// * Aucun [toJson] / [fromJson] sur les modèles : [SurfaceAtlasTileRef] et
//   [SurfaceAnimationFrame] restent des value objects purs dans [surface.dart].
// * La **géométrie d’atlas** ([SurfaceAtlasGeometry], bornes de grille) n’est
//   **pas** vérifiée ici : le codec n’a pas de [ProjectSurfaceAtlas] et ne doit
//   pas appeler [SurfaceAtlasTileRef.isInside] / [SurfaceAnimationFrame.isInside]
//   — des indices (column, row) arbitrairement grands se décodent donc
//   correctement, comme demandé.
// * Décodage : les clés inconnues sont **tolérées** (ignorées) et les [Map]
//   source ne doivent **jamais** être mutées (lecture seule, copies défensives
//   quand on normalise [Map<dynamic, dynamic>]).
//
// * [SurfaceAnimationTimeline], [ProjectSurfaceAnimation], etc. : **hors lot**
//   (codecs distincts, lots ultérieurs).

import '../exceptions/map_exceptions.dart';
import '../models/surface.dart';

/// Copie défensive, clés en [String] (décodage : Map dynamique, clés parfois non-string).
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

String _reqNonNullStringForTileRef(
  String fieldKey,
  Object? value,
) {
  if (value is! String) {
    throw ValidationException('$fieldKey must be a non-null String');
  }
  return value;
}

int _reqInt(
  String fieldKey,
  Object? value,
) {
  if (value is! int) {
    throw ValidationException('$fieldKey must be an int');
  }
  return value;
}

/// Encodage : `atlasId`, `column`, `row` (ordre d’insertion stable).
Map<String, Object?> encodeSurfaceAtlasTileRef(SurfaceAtlasTileRef tileRef) {
  return <String, Object?>{
    'atlasId': tileRef.atlasId,
    'column': tileRef.column,
    'row': tileRef.row,
  };
}

SurfaceAtlasTileRef decodeSurfaceAtlasTileRef(Map<String, Object?> json) {
  final atlasId = _reqNonNullStringForTileRef(
    'SurfaceAtlasTileRef.atlasId',
    _valueForRequiredKey(json, 'atlasId', 'SurfaceAtlasTileRef.atlasId'),
  );
  final column = _reqInt(
    'SurfaceAtlasTileRef.column',
    _valueForRequiredKey(json, 'column', 'SurfaceAtlasTileRef.column'),
  );
  final row = _reqInt(
    'SurfaceAtlasTileRef.row',
    _valueForRequiredKey(json, 'row', 'SurfaceAtlasTileRef.row'),
  );

  return SurfaceAtlasTileRef(
    atlasId: atlasId,
    column: column,
    row: row,
  );
}

/// Encodage : `tileRef` puis `durationMs` (ordre d’insertion stable).
Map<String, Object?> encodeSurfaceAnimationFrame(
  SurfaceAnimationFrame frame,
) {
  return <String, Object?>{
    'tileRef': encodeSurfaceAtlasTileRef(frame.tileRef),
    'durationMs': frame.durationMs,
  };
}

SurfaceAnimationFrame decodeSurfaceAnimationFrame(Map<String, Object?> json) {
  final tr = _valueForRequiredKey(
    json,
    'tileRef',
    'SurfaceAnimationFrame.tileRef',
  );
  if (tr is! Map) {
    throw const ValidationException(
      'SurfaceAnimationFrame.tileRef must be an Object',
    );
  }
  final tileRef = decodeSurfaceAtlasTileRef(_stringKeyMapFrom(tr));

  final durationVal = _valueForRequiredKey(
    json,
    'durationMs',
    'SurfaceAnimationFrame.durationMs',
  );
  if (durationVal is! int) {
    throw const ValidationException(
      'SurfaceAnimationFrame.durationMs must be an int',
    );
  }

  return SurfaceAnimationFrame(
    tileRef: tileRef,
    durationMs: durationVal,
  );
}
