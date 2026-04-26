// JSON codec manuel (Lot 39) — [ProjectSurfaceAtlas] et value objects de géométrie.
//
// * Prépare une **futures** persistance Surface **sans** brancher
//   [ProjectManifest] ni ajouter de champs de manifest dans ce lot.
// * Toute résolution de référence (existence d’un [tilesetId] dans le projet,
//   chemins d’image, cohérence texture) reste **hors scope** — seule la
//   forme des maps JSON compte ici.
// * Encodage : si [ProjectSurfaceAtlas.categoryId] est `null`, la clé
//   `categoryId` est **omise** (V0) ; [sortOrder] est **toujours** présent.
// * Décodage : les clés inconnues au premier niveau (atlas) et dans les
//   objets imbriqués reconnus sont **ignorées** sans [ValidationException] —
//   cela laisse de la marge à des évolutions de schéma.
// * Les modèles [surface.dart] restent **sans** `toJson` / `fromJson` : le
//   contrat d’E/S reste ici, dans [map_core], et délègue la validation métier
//   (tailles > 0, ids non vides) aux **constructeurs** existants quand c’est
//   possible.
//
// * Ne **mutate** jamais les [Map] passées en entrée en décodage (lecture
//   seulement).

import '../exceptions/map_exceptions.dart';
import '../models/surface.dart';

/// Copie défensive, clés en [String] (décodage JSON : clés string ou rarement non-string).
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

String _validLayoutNamesForMessage() =>
    SurfaceAtlasLayout.values.map((e) => e.name).join(', ');

/// Encodage pour persistance : identiques aux champs, ordre d’insertion
/// stable ([id], [name], [tilesetId], [geometry], [`categoryId` si non null],
/// [sortOrder]).
Map<String, Object?> encodeProjectSurfaceAtlas(ProjectSurfaceAtlas atlas) {
  final out = <String, Object?>{
    'id': atlas.id,
    'name': atlas.name,
    'tilesetId': atlas.tilesetId,
    'geometry': encodeSurfaceAtlasGeometry(atlas.geometry),
    'sortOrder': atlas.sortOrder,
  };
  if (atlas.categoryId != null) {
    out['categoryId'] = atlas.categoryId;
  }
  return out;
}

ProjectSurfaceAtlas decodeProjectSurfaceAtlas(Map<String, Object?> json) {
  final id = _reqString(
    fieldKey: 'ProjectSurfaceAtlas.id',
    value: _valueForRequiredKey(json, 'id', 'ProjectSurfaceAtlas.id'),
  );
  final name = _reqString(
    fieldKey: 'ProjectSurfaceAtlas.name',
    value: _valueForRequiredKey(json, 'name', 'ProjectSurfaceAtlas.name'),
  );
  final tilesetId = _reqString(
    fieldKey: 'ProjectSurfaceAtlas.tilesetId',
    value: _valueForRequiredKey(
      json,
      'tilesetId',
      'ProjectSurfaceAtlas.tilesetId',
    ),
  );

  final g = json['geometry'];
  if (g == null) {
    throw const ValidationException(
      'ProjectSurfaceAtlas.geometry is required',
    );
  }
  if (g is! Map) {
    throw const ValidationException(
      'ProjectSurfaceAtlas.geometry must be a Map',
    );
  }
  final geometry = decodeSurfaceAtlasGeometry(
    _stringKeyMapFrom(g),
  );

  final categoryId = _optionalCategoryId(json);
  final sortOrder = _sortOrder(json, 'ProjectSurfaceAtlas.sortOrder');

  return ProjectSurfaceAtlas(
    id: id,
    name: name,
    tilesetId: tilesetId,
    geometry: geometry,
    categoryId: categoryId,
    sortOrder: sortOrder,
  );
}

Map<String, Object?> encodeSurfaceAtlasGeometry(
  SurfaceAtlasGeometry geometry,
) {
  return {
    'tileSize': encodeSurfaceAtlasTileSize(geometry.tileSize),
    'gridSize': encodeSurfaceAtlasGridSize(geometry.gridSize),
    'layout': encodeSurfaceAtlasLayout(geometry.layout),
  };
}

SurfaceAtlasGeometry decodeSurfaceAtlasGeometry(Map<String, Object?> json) {
  final ts = json['tileSize'];
  if (ts == null) {
    throw const ValidationException(
      'SurfaceAtlasGeometry.tileSize is required',
    );
  }
  if (ts is! Map) {
    throw const ValidationException(
      'SurfaceAtlasGeometry.tileSize must be an Object',
    );
  }
  final tileSize = decodeSurfaceAtlasTileSize(
    _stringKeyMapFrom(ts),
  );

  final gs = json['gridSize'];
  if (gs == null) {
    throw const ValidationException(
      'SurfaceAtlasGeometry.gridSize is required',
    );
  }
  if (gs is! Map) {
    throw const ValidationException(
      'SurfaceAtlasGeometry.gridSize must be an Object',
    );
  }
  final gridSize = decodeSurfaceAtlasGridSize(
    _stringKeyMapFrom(gs),
  );

  final layoutRaw = json['layout'];
  if (layoutRaw == null) {
    throw const ValidationException('SurfaceAtlasGeometry.layout is required');
  }
  if (layoutRaw is! String) {
    throw const ValidationException(
      'SurfaceAtlasGeometry.layout must be a String',
    );
  }

  return SurfaceAtlasGeometry(
    tileSize: tileSize,
    gridSize: gridSize,
    layout: decodeSurfaceAtlasLayout(layoutRaw),
  );
}

Map<String, Object?> encodeSurfaceAtlasTileSize(
  SurfaceAtlasTileSize tileSize,
) {
  return {
    'width': tileSize.width,
    'height': tileSize.height,
  };
}

SurfaceAtlasTileSize decodeSurfaceAtlasTileSize(Map<String, Object?> json) {
  final w = _valueForRequiredKey(json, 'width', 'SurfaceAtlasTileSize.width');
  if (w is! int) {
    throw const ValidationException(
      'SurfaceAtlasTileSize.width must be an int',
    );
  }
  final h = _valueForRequiredKey(
    json,
    'height',
    'SurfaceAtlasTileSize.height',
  );
  if (h is! int) {
    throw const ValidationException(
      'SurfaceAtlasTileSize.height must be an int',
    );
  }
  return SurfaceAtlasTileSize(width: w, height: h);
}

Map<String, Object?> encodeSurfaceAtlasGridSize(
  SurfaceAtlasGridSize gridSize,
) {
  return {
    'columns': gridSize.columns,
    'rows': gridSize.rows,
  };
}

SurfaceAtlasGridSize decodeSurfaceAtlasGridSize(Map<String, Object?> json) {
  final c = _valueForRequiredKey(
    json,
    'columns',
    'SurfaceAtlasGridSize.columns',
  );
  if (c is! int) {
    throw const ValidationException(
      'SurfaceAtlasGridSize.columns must be an int',
    );
  }
  final r = _valueForRequiredKey(json, 'rows', 'SurfaceAtlasGridSize.rows');
  if (r is! int) {
    throw const ValidationException('SurfaceAtlasGridSize.rows must be an int');
  }
  return SurfaceAtlasGridSize(columns: c, rows: r);
}

String encodeSurfaceAtlasLayout(SurfaceAtlasLayout layout) => layout.name;

SurfaceAtlasLayout decodeSurfaceAtlasLayout(String value) {
  for (final l in SurfaceAtlasLayout.values) {
    if (l.name == value) {
      return l;
    }
  }
  throw ValidationException(
    'SurfaceAtlasLayout must be one of: ${_validLayoutNamesForMessage()}',
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

String _reqString({required String fieldKey, required Object? value}) {
  if (value is! String) {
    throw ValidationException('$fieldKey must be a non-null String');
  }
  return value;
}

int _sortOrder(Map<String, Object?> json, String fieldKey) {
  if (!json.containsKey('sortOrder')) {
    return 0;
  }
  final v = json['sortOrder'];
  if (v is! int) {
    throw ValidationException('$fieldKey must be an int');
  }
  return v;
}

String? _optionalCategoryId(Map<String, Object?> json) {
  if (!json.containsKey('categoryId')) {
    return null;
  }
  final v = json['categoryId'];
  if (v == null) {
    return null;
  }
  if (v is! String) {
    throw const ValidationException(
      'ProjectSurfaceAtlas.categoryId must be a String or null',
    );
  }
  return v;
}
