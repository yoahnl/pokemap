// JSON codec manuel (Lot 46) — [ProjectSurfaceCatalog].
//
// * Prépare la **future** persistance / intégration [ProjectManifest] **sans**
//   branchement manifeste dans ce lot — **aucun** champ `surfaceCatalog` ici.
// * Compose strictement [encodeProjectSurfaceAtlas] / [decodeProjectSurfaceAtlas]
//   (Lot 39), [encodeProjectSurfaceAnimation] / [decodeProjectSurfaceAnimation]
//   (Lot 42), [encodeProjectSurfacePreset] / [decodeProjectSurfacePreset] (Lot 45).
// * Préserve l’**ordre** des trois collections ; **aucun** retri, **aucun** filtrage
//   par id / `sortOrder`, **aucune** déduplication côté codec.
// * **Pas** de résolution d’[atlasId] / [animationId] / tileset : seulement la
//   forme JSON + validations des codecs enfants + règles [ProjectSurfaceCatalog]
//   (ex. unicité des id par collection).
// * **Pas** d’appel aux diagnostics ([diagnoseProjectSurfaceCatalog], etc.) :
//   le codec ne fait pas le travail d’analyse de cohérence métier.
// * Décodage : clés inconnues **top-level** **tolérées** ; [Map] sources
//   **jamais** mutées. Les clés imbriquées inconnues restent gérées par les
//   codecs atlas / animation / preset.
// * Aucun [toJson] / [fromJson] sur [ProjectSurfaceCatalog] : modèle domaine pur.
// * V0 : les clés `atlases`, `animations`, `presets` sont **requises** et
//   doivent être des listes (éventuellement vides).

import '../exceptions/map_exceptions.dart';
import '../models/surface.dart';
import '../models/surface_catalog.dart';
import 'project_surface_animation_json_codec.dart';
import 'project_surface_preset_json_codec.dart';
import 'surface_atlas_json_codec.dart';

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

List<Object?> _requiredList(
  Map<String, Object?> json,
  String key,
  String fieldErrorPrefix,
) {
  if (!json.containsKey(key)) {
    throw ValidationException('$fieldErrorPrefix is required');
  }
  final v = json[key];
  if (v is! List) {
    throw ValidationException('$fieldErrorPrefix must be a List');
  }
  return v;
}

/// Encodage : exactement [atlases], [animations], [presets] — ordre des listes
/// préservé, déterministe, sans mutation du [catalog] source.
Map<String, Object?> encodeProjectSurfaceCatalog(
  ProjectSurfaceCatalog catalog,
) {
  return <String, Object?>{
    'atlases': <Object?>[
      for (final a in catalog.atlases) encodeProjectSurfaceAtlas(a),
    ],
    'animations': <Object?>[
      for (final a in catalog.animations) encodeProjectSurfaceAnimation(a),
    ],
    'presets': <Object?>[
      for (final p in catalog.presets) encodeProjectSurfacePreset(p),
    ],
  };
}

/// Décodage : [atlases] / [animations] / [presets] requis, listes d’objets
/// mappables ; chaque élément décodé par le codec correspondant. Délègue
/// l’unicité des id au constructeur [ProjectSurfaceCatalog].
ProjectSurfaceCatalog decodeProjectSurfaceCatalog(
  Map<String, Object?> json,
) {
  final atlasesRaw = _requiredList(
    json,
    'atlases',
    'ProjectSurfaceCatalog.atlases',
  );
  final animationsRaw = _requiredList(
    json,
    'animations',
    'ProjectSurfaceCatalog.animations',
  );
  final presetsRaw = _requiredList(
    json,
    'presets',
    'ProjectSurfaceCatalog.presets',
  );

  final atlases = <ProjectSurfaceAtlas>[];
  for (var i = 0; i < atlasesRaw.length; i++) {
    final item = atlasesRaw[i];
    if (item is! Map) {
      throw ValidationException(
        'ProjectSurfaceCatalog.atlases[$i] must be an Object',
      );
    }
    atlases.add(decodeProjectSurfaceAtlas(_stringKeyMapFrom(item)));
  }

  final animations = <ProjectSurfaceAnimation>[];
  for (var i = 0; i < animationsRaw.length; i++) {
    final item = animationsRaw[i];
    if (item is! Map) {
      throw ValidationException(
        'ProjectSurfaceCatalog.animations[$i] must be an Object',
      );
    }
    animations.add(decodeProjectSurfaceAnimation(_stringKeyMapFrom(item)));
  }

  final presets = <ProjectSurfacePreset>[];
  for (var i = 0; i < presetsRaw.length; i++) {
    final item = presetsRaw[i];
    if (item is! Map) {
      throw ValidationException(
        'ProjectSurfaceCatalog.presets[$i] must be an Object',
      );
    }
    presets.add(decodeProjectSurfacePreset(_stringKeyMapFrom(item)));
  }

  return ProjectSurfaceCatalog(
    atlases: atlases,
    animations: animations,
    presets: presets,
  );
}
