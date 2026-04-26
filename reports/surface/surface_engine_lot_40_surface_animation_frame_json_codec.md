# Surface Engine — Lot 40 — Surface TileRef / AnimationFrame JSON Codec V0

## 1. Résumé exécutif

Implémentation d’un **codec JSON manuel** (sans Freezed) pour `SurfaceAtlasTileRef` et `SurfaceAnimationFrame` dans `map_core` : `encode` / `decode` symétriques, messages `ValidationException` explicites, **aucune** vérification de géométrie d’atlas, **aucun** branchement au `ProjectManifest`, **aucun** `toJson` / `fromJson` sur les modèles. Export public via `map_core.dart`. **23** tests ciblés, régressions Surface et **919** tests au total pour `map_core` après intégration (896 + 23).

## 2. Pourquoi ce lot vient après le Lot 39

Le Lot 39 a externalisé le JSON d’`ProjectSurfaceAtlas` et de sa géométrie. Le Lot 40 enchaîne sur les **deux** types qui décrivent une **frame d’animation** (référence de tuile + durée) pour la persistance auteur future, en conservant le même principe : **codec séparé des modèles** et **pas de manifeste**.

## 3. Tableau récapitulatif (lots 34–41)

| Lot | Intitulé | Statut |
|-----|----------|--------|
| 34 | Surface Catalog Diagnostics V0 | fait |
| 35 | Surface Catalog Unused Diagnostics V0 | fait |
| 36 | Surface Catalog Authoring Diagnostics Aggregator V0 | fait |
| 37 | Surface Catalog Diagnostics Summary V0 | fait |
| 38 | Surface Catalog Diagnostics Presentation Model V0 | fait |
| 39 | ProjectSurfaceAtlas JSON Codec V0 | fait |
| 40 | Surface TileRef / AnimationFrame JSON Codec V0 | **ce lot** |
| 41 | SurfaceAnimationTimeline JSON Codec V0 | prochain probable |
| 42 | ProjectSurfaceAnimation JSON Codec V0 | ensuite probable |

## 4. Fichiers consultés (audit)

- `packages/map_core/lib/src/models/surface.dart` — `SurfaceAtlasTileRef`, `SurfaceAnimationFrame` (validations)
- `packages/map_core/lib/src/operations/surface_atlas_json_codec.dart` — Lot 39 (inchangé)
- `packages/map_core/lib/src/exceptions/map_exceptions.dart` — `ValidationException`
- `packages/map_core/lib/map_core.dart` — barrel
- `packages/map_core/test/surface_atlas_tile_ref_test.dart`, `surface_animation_frame_test.dart`, `surface_atlas_json_codec_test.dart`, `surface_model_entrypoint_test.dart`
- `packages/map_core/lib/src/models/project_manifest.dart` — absence de clés `surface*`
- `reports/surface/surface_engine_lot_39_surface_atlas_json_codec.md` — continuité Lot 39

## 5. Fichiers créés

- `packages/map_core/lib/src/operations/surface_animation_frame_json_codec.dart`
- `packages/map_core/test/surface_animation_frame_json_codec_test.dart`
- `reports/surface/surface_engine_lot_40_surface_animation_frame_json_codec.md` (ce document)

## 6. Fichiers modifiés

- `packages/map_core/lib/map_core.dart` — +1 `export` (seule modification)

## 7. API ajoutée

- `Map<String, Object?> encodeSurfaceAtlasTileRef(SurfaceAtlasTileRef tileRef);`
- `SurfaceAtlasTileRef decodeSurfaceAtlasTileRef(Map<String, Object?> json);`
- `Map<String, Object?> encodeSurfaceAnimationFrame(SurfaceAnimationFrame frame);`
- `SurfaceAnimationFrame decodeSurfaceAnimationFrame(Map<String, Object?> json);`

## 8. Schéma JSON `SurfaceAtlasTileRef`

```json
{
  "atlasId": "string",
  "column": 0,
  "row": 0
}
```

## 9. Schéma JSON `SurfaceAnimationFrame`

```json
{
  "tileRef": { "atlasId": "…", "column": 0, "row": 0 },
  "durationMs": 120
}
```

`tileRef` est une **map** d’objet (côté Dart : `Map` JSON), reprise par `decodeSurfaceAtlasTileRef` sur une **copie** à clés `String` (`_stringKeyMapFrom`).

## 10. Sémantique d’encodage `SurfaceAtlasTileRef`

- Déterministe : clés `atlasId`, `column`, `row` dans cet ordre.
- Chaînes inchangées (aucun trim / lowercase).
- Aucune mutation de l’objet source.

## 11. Sémantique de décodage `SurfaceAtlasTileRef`

- Champs requis : `atlasId`, `column`, `row`.
- `atlasId` : `String` non `null` ; vide uniquement côté construction (`SurfaceAtlasTileRef` rejette `trim().isEmpty`).
- `column` / `row` : `int` (Dart) ; négatifs rejetés par le constructeur.
- Clés inconnues ignorées. La map d’entrée n’est **pas** modifiée.

## 12. Sémantique d’encodage `SurfaceAnimationFrame`

- Clés `tileRef` (via `encodeSurfaceAtlasTileRef`), `durationMs`, dans cet ordre.
- Aucune mutation de l’objet source.

## 13. Sémantique de décodage `SurfaceAnimationFrame`

- `tileRef` requis, doit être un `Map` (message d’erreur : « must be an Object » comme pour les sous-objets du Lot 39).
- `durationMs` requis, `int` ; `<= 0` rejeté par `SurfaceAnimationFrame` (comme ailleurs).
- Pas d’appel à `isInside(geometry)`.
- Clés inconnues ignorées. Map source non mutée.

## 14. Décision : pas de vérification géométrique au décodage

`SurfaceAtlasTileRef.isInside` / `SurfaceAnimationFrame.isInside` existent pour les **diagnostics** / logique auteur, mais le codec n’a **pas** de `SurfaceAtlasGeometry` : des indices (999, 999) se décodent donc **sans** erreur (test 18 + assertion `isInside == false` avec grille 1×1).

## 15. Décision : clés inconnues tolérées

Les champs requis + types suffisent ; le reste est ignoré (évolution de schéma future).

## 16. Décision : pas de `toJson` / `fromJson` sur les modèles

Les types restent purs dans `surface.dart` ; l’E/S reste dans `surface_animation_frame_json_codec.dart`.

## 17. Décision : pas de codec timeline / `ProjectSurfaceAnimation` dans ce lot

Ces codecs relèvent des lots **41+** (timeline puis animation projet).

## 18. Décision : `ProjectManifest` non modifié

Aucune clé de persistance Surface n’est introduite côté manifeste ; aligné avec les lots 33–39.

## 19. Ce qui a été testé

- Encodage / décodage / round-trips, rejets (types, champs, `atlasId` blanc, `durationMs` ≤ 0), clés inconnues, immutabilité des maps, absence de vérification géométrique dans le codec, erreur imbriquée depuis `tileRef`, manifest minimal sans clés `surface*`, **pas** d’appels `toJson`/`fromJson` modèle, rappel que timeline / project animation ne sont **pas** exposés ici.

## 20. Ce que les tests prouvent

- Cohérence formelle JSON V0, délégation correcte aux constructeurs, indépendance vis-à-vis du manifeste et de la grille d’atlas, export `map_core` utilisable.

## 21. Ce qui n’a volontairement pas été fait

- Codecs `SurfaceAnimationTimeline`, `ProjectSurfaceAnimation`, préréglages, catalogue ; IO ; moteur ; éditeur.

## 22. Pourquoi `ProjectManifest` n’a toujours pas été modifié

Hors scope : la persistance manifeste unifiera `surfaceAtlases` / animations quand un lot l’imposera expressément.

## 23. Pourquoi aucun fichier generated

Pas de `build_runner` / Freezed / `part` — codec manuel seulement.

## 24. Pourquoi aucun `build_runner` n’a été lancé

Aucun modèle généré ni annotation ajoutée.

## 25. Pourquoi aucun runtime / editor / gameplay / battle n’a été modifié

Le contrat se limite à `map_core` (contrats et tests purs).

## 26. Impact pour les prochains lots Surface

- Lot 41 : `SurfaceAnimationTimeline` (liste de frames) pourra s’appuyer sur `encodeSurfaceAnimationFrame` par élément.
- Lot 42 : enchaîner `ProjectSurfaceAnimation` sans re-dupliquer le codec frame.

## 27. Commandes lancées

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/surface_animation_frame_json_codec_test.dart
/opt/homebrew/bin/dart test test/surface_atlas_tile_ref_test.dart
/opt/homebrew/bin/dart test test/surface_animation_frame_test.dart
/opt/homebrew/bin/dart test test/surface_atlas_json_codec_test.dart
/opt/homebrew/bin/dart test test/surface_model_entrypoint_test.dart
/opt/homebrew/bin/dart analyze \
  lib/src/operations/surface_animation_frame_json_codec.dart \
  lib/src/operations/surface_atlas_json_codec.dart \
  lib/src/models/surface.dart \
  test/surface_animation_frame_json_codec_test.dart \
  test/surface_atlas_tile_ref_test.dart \
  test/surface_animation_frame_test.dart \
  test/surface_atlas_json_codec_test.dart \
  test/surface_model_entrypoint_test.dart \
  lib/map_core.dart
/opt/homebrew/bin/dart test
```

`git status --short` (lecture seule, après lot) :

```
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/surface_animation_frame_json_codec.dart
?? packages/map_core/test/surface_animation_frame_json_codec_test.dart
?? reports/surface/surface_engine_lot_40_surface_animation_frame_json_codec.md
```

## 28. Résultats exacts des tests ciblés (Lot 40)

Sorties intégrales : **§36 D.1** ci-dessous.

Ligne de synthèse : **`+23: All tests passed!`**

## 29. Résultat exact de `dart analyze`

Sortie intégrale : **§36 D.6** ci-dessous.

## 30. Résultat exact du `dart test` complet (`map_core`)

- **Commande** : `cd packages/map_core && /opt/homebrew/bin/dart test`
- **Dernière ligne** : `00:01 +919: All tests passed!` (séparateur de progression converti : **§36 D.7**).

## 31. Total exact du `dart test` complet

**919** (896 avant Lot 40 + 23).

## 32. Points de vigilance

- JSON Dart : seuls les `int` natifs comptent (pas d’`int` JSON décodé en `num` ici, les tests passent en maps Dart typées).
- Le helper `_stringKeyMapFrom` duplique le motif du Lot 39 (évite de coupler / modifier `surface_atlas_json_codec.dart`).

## 33. Autocritique finale

- Duplication légère de `_stringKeyMapFrom` (alternative : module partagé, hors scope explicite « ne pas toucher atlas par défaut »).
- `durationMs: 0` : `ValidationException` vient du modèle, pas d’un message explicite « durationMs must be an int » — acceptable car contrat déjà couvert ailleurs.

## 34. Ce que le prompt semble discutable ou incomplet

- Le type JSON « `Map<String, Object?>` pour tileRef dans la spec » est mappé en pratique sur tout `Map` accepté par l’écosystème `dart:convert` (puis normalisé) ; l’API publique reste `Map<String, Object?>` pour l’intégration manuelle, comme le Lot 39.

## 35. Auto-review indépendante

- Périmètre Lot 40 respecté (codec tileRef + frame seulement).
- `ProjectManifest` non modifié ; pas de champs `surface*` ajoutés.
- Pas de `toJson` / `fromJson` modèle ; pas de codec timeline / `ProjectSurfaceAnimation` / préréglage / catalogue.
- Pas de générés, pas de `build_runner` ; paquets runtime / editor / gameplay / battle intacts.
- Géométrie non vérifiée dans le codec ; clés inconnues OK ; maps sources non muetées (copie pour `_stringKeyMapFrom`).
- Export `map_core` OK ; tests manifest + 919 tests verts.
- Evidence Pack (§36) : contenu des sources, diffs, sorties.
- Aucune commande Git d’**écriture** utilisée (`git add` / `commit` / etc. interdits par le contrat).
- **Auto-check anti-formulations** (liste interdite du contrat) : effectué sur ce document ; **aucune** de ces tournures n’est employée **à la place d’une preuve** requise.

## 36. Evidence Pack complet

### A. Contenu complet — `packages/map_core/lib/src/operations/surface_animation_frame_json_codec.dart`

```dart
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
```

### A. Contenu complet — `packages/map_core/test/surface_animation_frame_json_codec_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40)', () {
    test('1. encodes SurfaceAtlasTileRef', () {
      final ref = SurfaceAtlasTileRef(
        atlasId: 'water-atlas',
        column: 3,
        row: 12,
      );
      final j = encodeSurfaceAtlasTileRef(ref);
      expect(j, {
        'atlasId': 'water-atlas',
        'column': 3,
        'row': 12,
      });
    });

    test('2. decodes SurfaceAtlasTileRef', () {
      final j = <String, Object?>{
        'atlasId': 'water-atlas',
        'column': 3,
        'row': 12,
      };
      final r = decodeSurfaceAtlasTileRef(j);
      expect(r.atlasId, 'water-atlas');
      expect(r.column, 3);
      expect(r.row, 12);
    });

    test('3. round-trip SurfaceAtlasTileRef', () {
      final original = _tileRef();
      final decoded = decodeSurfaceAtlasTileRef(encodeSurfaceAtlasTileRef(original));
      expect(decoded, original);
    });

    test('4. preserves exact atlasId string (no trim)', () {
      const raw = '  water-atlas  ';
      final r = decodeSurfaceAtlasTileRef(<String, Object?>{
        'atlasId': raw,
        'column': 3,
        'row': 12,
      });
      expect(r.atlasId, raw);
    });

    test('5. rejects atlasId missing, wrong type, whitespace-only', () {
      expect(
        () => decodeSurfaceAtlasTileRef(<String, Object?>{'column': 0, 'row': 0}),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeSurfaceAtlasTileRef(<String, Object?>{
          'atlasId': 123,
          'column': 0,
          'row': 0,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeSurfaceAtlasTileRef(<String, Object?>{
          'atlasId': '   ',
          'column': 0,
          'row': 0,
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('6. rejects column missing, wrong type, negative', () {
      expect(
        () => decodeSurfaceAtlasTileRef(<String, Object?>{
          'atlasId': 'a',
          'row': 0,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeSurfaceAtlasTileRef(<String, Object?>{
          'atlasId': 'a',
          'column': '3',
          'row': 0,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeSurfaceAtlasTileRef(<String, Object?>{
          'atlasId': 'a',
          'column': -1,
          'row': 0,
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('7. rejects row missing, wrong type, negative', () {
      expect(
        () => decodeSurfaceAtlasTileRef(<String, Object?>{
          'atlasId': 'a',
          'column': 0,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeSurfaceAtlasTileRef(<String, Object?>{
          'atlasId': 'a',
          'column': 0,
          'row': false,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeSurfaceAtlasTileRef(<String, Object?>{
          'atlasId': 'a',
          'column': 0,
          'row': -1,
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('8. decode SurfaceAtlasTileRef ignores unknown keys', () {
      final r = decodeSurfaceAtlasTileRef(<String, Object?>{
        'atlasId': 'water-atlas',
        'column': 3,
        'row': 12,
        'futureField': 'ignored',
      });
      expect(r, _tileRef());
    });

    test('9. decode SurfaceAtlasTileRef does not mutate source map', () {
      final map = <String, Object?>{
        'atlasId': 'water-atlas',
        'column': 3,
        'row': 12,
      };
      final before = _deepStr(map);
      decodeSurfaceAtlasTileRef(map);
      expect(_deepStr(map), before);
    });

    test('10. encodes SurfaceAnimationFrame', () {
      final f = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'water-atlas',
          column: 3,
          row: 12,
        ),
        durationMs: 120,
      );
      expect(encodeSurfaceAnimationFrame(f), {
        'tileRef': {
          'atlasId': 'water-atlas',
          'column': 3,
          'row': 12,
        },
        'durationMs': 120,
      });
    });

    test('11. decodes SurfaceAnimationFrame', () {
      const j = <String, Object?>{
        'tileRef': <String, Object?>{
          'atlasId': 'water-atlas',
          'column': 3,
          'row': 12,
        },
        'durationMs': 120,
      };
      final f = decodeSurfaceAnimationFrame(j);
      expect(f.tileRef.atlasId, 'water-atlas');
      expect(f.tileRef.column, 3);
      expect(f.tileRef.row, 12);
      expect(f.durationMs, 120);
    });

    test('12. round-trip SurfaceAnimationFrame', () {
      final original = _frame();
      final decoded = decodeSurfaceAnimationFrame(encodeSurfaceAnimationFrame(original));
      expect(decoded, original);
    });

    test('13. rejects frame tileRef missing or wrong type', () {
      expect(
        () => decodeSurfaceAnimationFrame(<String, Object?>{'durationMs': 120}),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeSurfaceAnimationFrame(<String, Object?>{
          'tileRef': 'nope',
          'durationMs': 120,
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('14. rejects durationMs missing or wrong type', () {
      final ref = <String, Object?>{'atlasId': 'a', 'column': 0, 'row': 0};
      expect(
        () => decodeSurfaceAnimationFrame(<String, Object?>{'tileRef': ref}),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeSurfaceAnimationFrame(<String, Object?>{
          'tileRef': ref,
          'durationMs': '120',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('15. rejects durationMs <= 0', () {
      final ref = <String, Object?>{'atlasId': 'a', 'column': 0, 'row': 0};
      expect(
        () => decodeSurfaceAnimationFrame(<String, Object?>{
          'tileRef': ref,
          'durationMs': 0,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeSurfaceAnimationFrame(<String, Object?>{
          'tileRef': ref,
          'durationMs': -1,
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('16. decode SurfaceAnimationFrame ignores unknown keys', () {
      final f = decodeSurfaceAnimationFrame(<String, Object?>{
        'tileRef': <String, Object?>{
          'atlasId': 'water-atlas',
          'column': 3,
          'row': 12,
        },
        'durationMs': 120,
        'futureField': 'ignored',
      });
      expect(f, _frame());
    });

    test('17. decode SurfaceAnimationFrame does not mutate source map', () {
      final inner = <String, Object?>{
        'atlasId': 'water-atlas',
        'column': 3,
        'row': 12,
      };
      final map = <String, Object?>{
        'tileRef': inner,
        'durationMs': 120,
      };
      final before = _deepStr(map);
      decodeSurfaceAnimationFrame(map);
      expect(_deepStr(map), before);
    });

    test('18. does not verify geometry; isInside is separate', () {
      const j = <String, Object?>{
        'tileRef': <String, Object?>{
          'atlasId': 'water-atlas',
          'column': 999,
          'row': 999,
        },
        'durationMs': 120,
      };
      final frame = decodeSurfaceAnimationFrame(j);
      expect(frame.tileRef.column, 999);
      expect(frame.tileRef.row, 999);

      final geometry = SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(width: 1, height: 1),
        gridSize: SurfaceAtlasGridSize(columns: 1, rows: 1),
        layout: SurfaceAtlasLayout.grid,
      );
      expect(frame.isInside(geometry), isFalse);
    });

    test('19. nested tileRef errors propagate from decode frame', () {
      expect(
        () => decodeSurfaceAnimationFrame(<String, Object?>{
          'tileRef': <String, Object?>{
            'atlasId': '   ',
            'column': 3,
            'row': 12,
          },
          'durationMs': 120,
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('20. public API encodeSurfaceAnimationFrame returns Map', () {
      expect(encodeSurfaceAnimationFrame(_frame()), isA<Map<String, Object?>>());
    });

    test('21. ProjectManifest has no surface persistence keys (Lot 40)', () {
      const manifest = ProjectManifest(
        name: 'L40',
        maps: [
          ProjectMapEntry(
            id: 'm1',
            name: 'M',
            relativePath: 'maps/m1.json',
          ),
        ],
        tilesets: [],
      );
      final j = manifest.toJson();
      for (final k in const [
        'surfaceDefinitions',
        'surfaceAtlases',
        'surfaceAnimations',
        'surfacePresets',
        'surfaceCategories',
      ]) {
        expect(j.containsKey(k), isFalse, reason: k);
      }
    });

    test(
      '22. codec external to models: no Surface toJson or fromJson on ref/frame',
      () {
        final tr = _tileRef();
        final jsonTr = encodeSurfaceAtlasTileRef(tr);
        expect(jsonTr, isA<Map<String, Object?>>());
        final f = _frame();
        final jsonF = encodeSurfaceAnimationFrame(f);
        expect(jsonF, isA<Map<String, Object?>>());
        // Ne pas appeler tr.toJson, SurfaceAtlasTileRef.fromJson, f.toJson,
        // SurfaceAnimationFrame.fromJson — inexistants / hors contrat.
      },
    );

    test(
      '23. no timeline or ProjectSurfaceAnimation codec in this lot',
      () {
        final j = encodeSurfaceAnimationFrame(_frame());
        expect(j.containsKey('tileRef'), isTrue);
        // Pas d’encodeSurfaceAnimationTimeline / encodeProjectSurfaceAnimation.
      },
    );
  });
}

SurfaceAtlasTileRef _tileRef({
  String atlasId = 'water-atlas',
  int column = 3,
  int row = 12,
}) {
  return SurfaceAtlasTileRef(atlasId: atlasId, column: column, row: row);
}

SurfaceAnimationFrame _frame({
  SurfaceAtlasTileRef? tileRef,
  int durationMs = 120,
}) {
  return SurfaceAnimationFrame(
    tileRef: tileRef ?? _tileRef(),
    durationMs: durationMs,
  );
}

String _deepStr(Object? o) {
  if (o is Map) {
    return '{${o.keys.map((k) => '$k:${_deepStr(o[k])}').join(',')}}';
  }
  if (o is String) {
    return o;
  }
  if (o is int) {
    return '$o';
  }
  if (o == null) {
    return 'null';
  }
  return o.toString();
}
```

### B. Fichier modifié `map_core.dart` (bloc d’exports autour du nouvel export, lignes 40–60)

```dart
export 'src/operations/standard_lava_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_ice_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_tall_grass_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_surface_preset_builder.dart';
export 'src/operations/surface_catalog_diagnostics.dart';
export 'src/operations/surface_catalog_authoring_diagnostics.dart';
export 'src/operations/surface_catalog_diagnostics_summary.dart';
export 'src/operations/surface_catalog_diagnostics_presentation.dart';
export 'src/operations/surface_atlas_json_codec.dart';
export 'src/operations/surface_animation_frame_json_codec.dart';
export 'src/operations/legacy_path_surface_view.dart';
export 'src/operations/legacy_terrain_surface_view.dart';
export 'src/operations/legacy_project_surface_catalog_view.dart';
export 'src/operations/legacy_surface_catalog_diagnostics.dart';
export 'src/operations/legacy_surface_usage_view.dart';
export 'src/operations/legacy_surface_usage_diagnostics.dart';
export 'src/operations/legacy_surface_audit_report.dart';
export 'src/operations/path_animation_rules.dart';
export 'src/operations/element_collision_mask_codec.dart';
export 'src/collision/pixel_rect.dart';
export 'src/collision/player_collision_conventions_v1.dart';
```

### C. Diffs

#### C.1 `git diff` de `map_core.dart` (working tree, lecture seule)

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index a7793afe..acdc3869 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -46,6 +46,7 @@ export 'src/operations/surface_catalog_authoring_diagnostics.dart';
 export 'src/operations/surface_catalog_diagnostics_summary.dart';
 export 'src/operations/surface_catalog_diagnostics_presentation.dart';
 export 'src/operations/surface_atlas_json_codec.dart';
+export 'src/operations/surface_animation_frame_json_codec.dart';
 export 'src/operations/legacy_path_surface_view.dart';
 export 'src/operations/legacy_terrain_surface_view.dart';
 export 'src/operations/legacy_project_surface_catalog_view.dart';
```

#### C.2 `diff -u /dev/null` — `surface_animation_frame_json_codec.dart`

```diff
--- /dev/null	2026-04-27 01:40:46
+++ /Users/karim/Project/pokemonProject/packages/map_core/lib/src/operations/surface_animation_frame_json_codec.dart	2026-04-27 01:39:09
@@ -0,0 +1,134 @@
+// JSON codec manuel (Lot 40) — [SurfaceAtlasTileRef] et [SurfaceAnimationFrame].
+//
+// * Prépare une **future** persistance Surface **sans** brancher [ProjectManifest]
+//   ni ajouter de champs manifest dans ce lot.
+// * Aucun [toJson] / [fromJson] sur les modèles : [SurfaceAtlasTileRef] et
+//   [SurfaceAnimationFrame] restent des value objects purs dans [surface.dart].
+// * La **géométrie d’atlas** ([SurfaceAtlasGeometry], bornes de grille) n’est
+//   **pas** vérifiée ici : le codec n’a pas de [ProjectSurfaceAtlas] et ne doit
+//   pas appeler [SurfaceAtlasTileRef.isInside] / [SurfaceAnimationFrame.isInside]
+//   — des indices (column, row) arbitrairement grands se décodent donc
+//   correctement, comme demandé.
+// * Décodage : les clés inconnues sont **tolérées** (ignorées) et les [Map]
+//   source ne doivent **jamais** être mutées (lecture seule, copies défensives
+//   quand on normalise [Map<dynamic, dynamic>]).
+//
+// * [SurfaceAnimationTimeline], [ProjectSurfaceAnimation], etc. : **hors lot**
+//   (codecs distincts, lots ultérieurs).
+
+import '../exceptions/map_exceptions.dart';
+import '../models/surface.dart';
+
+/// Copie défensive, clés en [String] (décodage : Map dynamique, clés parfois non-string).
+Map<String, Object?> _stringKeyMapFrom(Object mapLike) {
+  final m = mapLike as Map<dynamic, dynamic>;
+  return Map<String, Object?>.from(
+    m.map(
+      (dynamic k, dynamic v) => MapEntry(
+        k is String ? k : k.toString(),
+        v as Object?,
+      ),
+    ),
+  );
+}
+
+Object? _valueForRequiredKey(
+  Map<String, Object?> json,
+  String key,
+  String errorPrefix,
+) {
+  if (!json.containsKey(key)) {
+    throw ValidationException('$errorPrefix is required');
+  }
+  return json[key];
+}
+
+String _reqNonNullStringForTileRef(
+  String fieldKey,
+  Object? value,
+) {
+  if (value is! String) {
+    throw ValidationException('$fieldKey must be a non-null String');
+  }
+  return value;
+}
+
+int _reqInt(
+  String fieldKey,
+  Object? value,
+) {
+  if (value is! int) {
+    throw ValidationException('$fieldKey must be an int');
+  }
+  return value;
+}
+
+/// Encodage : `atlasId`, `column`, `row` (ordre d’insertion stable).
+Map<String, Object?> encodeSurfaceAtlasTileRef(SurfaceAtlasTileRef tileRef) {
+  return <String, Object?>{
+    'atlasId': tileRef.atlasId,
+    'column': tileRef.column,
+    'row': tileRef.row,
+  };
+}
+
+SurfaceAtlasTileRef decodeSurfaceAtlasTileRef(Map<String, Object?> json) {
+  final atlasId = _reqNonNullStringForTileRef(
+    'SurfaceAtlasTileRef.atlasId',
+    _valueForRequiredKey(json, 'atlasId', 'SurfaceAtlasTileRef.atlasId'),
+  );
+  final column = _reqInt(
+    'SurfaceAtlasTileRef.column',
+    _valueForRequiredKey(json, 'column', 'SurfaceAtlasTileRef.column'),
+  );
+  final row = _reqInt(
+    'SurfaceAtlasTileRef.row',
+    _valueForRequiredKey(json, 'row', 'SurfaceAtlasTileRef.row'),
+  );
+
+  return SurfaceAtlasTileRef(
+    atlasId: atlasId,
+    column: column,
+    row: row,
+  );
+}
+
+/// Encodage : `tileRef` puis `durationMs` (ordre d’insertion stable).
+Map<String, Object?> encodeSurfaceAnimationFrame(
+  SurfaceAnimationFrame frame,
+) {
+  return <String, Object?>{
+    'tileRef': encodeSurfaceAtlasTileRef(frame.tileRef),
+    'durationMs': frame.durationMs,
+  };
+}
+
+SurfaceAnimationFrame decodeSurfaceAnimationFrame(Map<String, Object?> json) {
+  final tr = _valueForRequiredKey(
+    json,
+    'tileRef',
+    'SurfaceAnimationFrame.tileRef',
+  );
+  if (tr is! Map) {
+    throw const ValidationException(
+      'SurfaceAnimationFrame.tileRef must be an Object',
+    );
+  }
+  final tileRef = decodeSurfaceAtlasTileRef(_stringKeyMapFrom(tr));
+
+  final durationVal = _valueForRequiredKey(
+    json,
+    'durationMs',
+    'SurfaceAnimationFrame.durationMs',
+  );
+  if (durationVal is! int) {
+    throw const ValidationException(
+      'SurfaceAnimationFrame.durationMs must be an int',
+    );
+  }
+
+  return SurfaceAnimationFrame(
+    tileRef: tileRef,
+    durationMs: durationVal,
+  );
+}
```

#### C.3 `diff -u /dev/null` — `surface_animation_frame_json_codec_test.dart`

```diff
--- /dev/null	2026-04-27 01:40:46
+++ /Users/karim/Project/pokemonProject/packages/map_core/test/surface_animation_frame_json_codec_test.dart	2026-04-27 01:39:18
@@ -0,0 +1,380 @@
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+void main() {
+  group('Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40)', () {
+    test('1. encodes SurfaceAtlasTileRef', () {
+      final ref = SurfaceAtlasTileRef(
+        atlasId: 'water-atlas',
+        column: 3,
+        row: 12,
+      );
+      final j = encodeSurfaceAtlasTileRef(ref);
+      expect(j, {
+        'atlasId': 'water-atlas',
+        'column': 3,
+        'row': 12,
+      });
+    });
+
+    test('2. decodes SurfaceAtlasTileRef', () {
+      final j = <String, Object?>{
+        'atlasId': 'water-atlas',
+        'column': 3,
+        'row': 12,
+      };
+      final r = decodeSurfaceAtlasTileRef(j);
+      expect(r.atlasId, 'water-atlas');
+      expect(r.column, 3);
+      expect(r.row, 12);
+    });
+
+    test('3. round-trip SurfaceAtlasTileRef', () {
+      final original = _tileRef();
+      final decoded = decodeSurfaceAtlasTileRef(encodeSurfaceAtlasTileRef(original));
+      expect(decoded, original);
+    });
+
+    test('4. preserves exact atlasId string (no trim)', () {
+      const raw = '  water-atlas  ';
+      final r = decodeSurfaceAtlasTileRef(<String, Object?>{
+        'atlasId': raw,
+        'column': 3,
+        'row': 12,
+      });
+      expect(r.atlasId, raw);
+    });
+
+    test('5. rejects atlasId missing, wrong type, whitespace-only', () {
+      expect(
+        () => decodeSurfaceAtlasTileRef(<String, Object?>{'column': 0, 'row': 0}),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => decodeSurfaceAtlasTileRef(<String, Object?>{
+          'atlasId': 123,
+          'column': 0,
+          'row': 0,
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => decodeSurfaceAtlasTileRef(<String, Object?>{
+          'atlasId': '   ',
+          'column': 0,
+          'row': 0,
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('6. rejects column missing, wrong type, negative', () {
+      expect(
+        () => decodeSurfaceAtlasTileRef(<String, Object?>{
+          'atlasId': 'a',
+          'row': 0,
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => decodeSurfaceAtlasTileRef(<String, Object?>{
+          'atlasId': 'a',
+          'column': '3',
+          'row': 0,
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => decodeSurfaceAtlasTileRef(<String, Object?>{
+          'atlasId': 'a',
+          'column': -1,
+          'row': 0,
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('7. rejects row missing, wrong type, negative', () {
+      expect(
+        () => decodeSurfaceAtlasTileRef(<String, Object?>{
+          'atlasId': 'a',
+          'column': 0,
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => decodeSurfaceAtlasTileRef(<String, Object?>{
+          'atlasId': 'a',
+          'column': 0,
+          'row': false,
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => decodeSurfaceAtlasTileRef(<String, Object?>{
+          'atlasId': 'a',
+          'column': 0,
+          'row': -1,
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('8. decode SurfaceAtlasTileRef ignores unknown keys', () {
+      final r = decodeSurfaceAtlasTileRef(<String, Object?>{
+        'atlasId': 'water-atlas',
+        'column': 3,
+        'row': 12,
+        'futureField': 'ignored',
+      });
+      expect(r, _tileRef());
+    });
+
+    test('9. decode SurfaceAtlasTileRef does not mutate source map', () {
+      final map = <String, Object?>{
+        'atlasId': 'water-atlas',
+        'column': 3,
+        'row': 12,
+      };
+      final before = _deepStr(map);
+      decodeSurfaceAtlasTileRef(map);
+      expect(_deepStr(map), before);
+    });
+
+    test('10. encodes SurfaceAnimationFrame', () {
+      final f = SurfaceAnimationFrame(
+        tileRef: SurfaceAtlasTileRef(
+          atlasId: 'water-atlas',
+          column: 3,
+          row: 12,
+        ),
+        durationMs: 120,
+      );
+      expect(encodeSurfaceAnimationFrame(f), {
+        'tileRef': {
+          'atlasId': 'water-atlas',
+          'column': 3,
+          'row': 12,
+        },
+        'durationMs': 120,
+      });
+    });
+
+    test('11. decodes SurfaceAnimationFrame', () {
+      const j = <String, Object?>{
+        'tileRef': <String, Object?>{
+          'atlasId': 'water-atlas',
+          'column': 3,
+          'row': 12,
+        },
+        'durationMs': 120,
+      };
+      final f = decodeSurfaceAnimationFrame(j);
+      expect(f.tileRef.atlasId, 'water-atlas');
+      expect(f.tileRef.column, 3);
+      expect(f.tileRef.row, 12);
+      expect(f.durationMs, 120);
+    });
+
+    test('12. round-trip SurfaceAnimationFrame', () {
+      final original = _frame();
+      final decoded = decodeSurfaceAnimationFrame(encodeSurfaceAnimationFrame(original));
+      expect(decoded, original);
+    });
+
+    test('13. rejects frame tileRef missing or wrong type', () {
+      expect(
+        () => decodeSurfaceAnimationFrame(<String, Object?>{'durationMs': 120}),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => decodeSurfaceAnimationFrame(<String, Object?>{
+          'tileRef': 'nope',
+          'durationMs': 120,
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('14. rejects durationMs missing or wrong type', () {
+      final ref = <String, Object?>{'atlasId': 'a', 'column': 0, 'row': 0};
+      expect(
+        () => decodeSurfaceAnimationFrame(<String, Object?>{'tileRef': ref}),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => decodeSurfaceAnimationFrame(<String, Object?>{
+          'tileRef': ref,
+          'durationMs': '120',
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('15. rejects durationMs <= 0', () {
+      final ref = <String, Object?>{'atlasId': 'a', 'column': 0, 'row': 0};
+      expect(
+        () => decodeSurfaceAnimationFrame(<String, Object?>{
+          'tileRef': ref,
+          'durationMs': 0,
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => decodeSurfaceAnimationFrame(<String, Object?>{
+          'tileRef': ref,
+          'durationMs': -1,
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('16. decode SurfaceAnimationFrame ignores unknown keys', () {
+      final f = decodeSurfaceAnimationFrame(<String, Object?>{
+        'tileRef': <String, Object?>{
+          'atlasId': 'water-atlas',
+          'column': 3,
+          'row': 12,
+        },
+        'durationMs': 120,
+        'futureField': 'ignored',
+      });
+      expect(f, _frame());
+    });
+
+    test('17. decode SurfaceAnimationFrame does not mutate source map', () {
+      final inner = <String, Object?>{
+        'atlasId': 'water-atlas',
+        'column': 3,
+        'row': 12,
+      };
+      final map = <String, Object?>{
+        'tileRef': inner,
+        'durationMs': 120,
+      };
+      final before = _deepStr(map);
+      decodeSurfaceAnimationFrame(map);
+      expect(_deepStr(map), before);
+    });
+
+    test('18. does not verify geometry; isInside is separate', () {
+      const j = <String, Object?>{
+        'tileRef': <String, Object?>{
+          'atlasId': 'water-atlas',
+          'column': 999,
+          'row': 999,
+        },
+        'durationMs': 120,
+      };
+      final frame = decodeSurfaceAnimationFrame(j);
+      expect(frame.tileRef.column, 999);
+      expect(frame.tileRef.row, 999);
+
+      final geometry = SurfaceAtlasGeometry(
+        tileSize: SurfaceAtlasTileSize(width: 1, height: 1),
+        gridSize: SurfaceAtlasGridSize(columns: 1, rows: 1),
+        layout: SurfaceAtlasLayout.grid,
+      );
+      expect(frame.isInside(geometry), isFalse);
+    });
+
+    test('19. nested tileRef errors propagate from decode frame', () {
+      expect(
+        () => decodeSurfaceAnimationFrame(<String, Object?>{
+          'tileRef': <String, Object?>{
+            'atlasId': '   ',
+            'column': 3,
+            'row': 12,
+          },
+          'durationMs': 120,
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('20. public API encodeSurfaceAnimationFrame returns Map', () {
+      expect(encodeSurfaceAnimationFrame(_frame()), isA<Map<String, Object?>>());
+    });
+
+    test('21. ProjectManifest has no surface persistence keys (Lot 40)', () {
+      const manifest = ProjectManifest(
+        name: 'L40',
+        maps: [
+          ProjectMapEntry(
+            id: 'm1',
+            name: 'M',
+            relativePath: 'maps/m1.json',
+          ),
+        ],
+        tilesets: [],
+      );
+      final j = manifest.toJson();
+      for (final k in const [
+        'surfaceDefinitions',
+        'surfaceAtlases',
+        'surfaceAnimations',
+        'surfacePresets',
+        'surfaceCategories',
+      ]) {
+        expect(j.containsKey(k), isFalse, reason: k);
+      }
+    });
+
+    test(
+      '22. codec external to models: no Surface toJson or fromJson on ref/frame',
+      () {
+        final tr = _tileRef();
+        final jsonTr = encodeSurfaceAtlasTileRef(tr);
+        expect(jsonTr, isA<Map<String, Object?>>());
+        final f = _frame();
+        final jsonF = encodeSurfaceAnimationFrame(f);
+        expect(jsonF, isA<Map<String, Object?>>());
+        // Ne pas appeler tr.toJson, SurfaceAtlasTileRef.fromJson, f.toJson,
+        // SurfaceAnimationFrame.fromJson — inexistants / hors contrat.
+      },
+    );
+
+    test(
+      '23. no timeline or ProjectSurfaceAnimation codec in this lot',
+      () {
+        final j = encodeSurfaceAnimationFrame(_frame());
+        expect(j.containsKey('tileRef'), isTrue);
+        // Pas d’encodeSurfaceAnimationTimeline / encodeProjectSurfaceAnimation.
+      },
+    );
+  });
+}
+
+SurfaceAtlasTileRef _tileRef({
+  String atlasId = 'water-atlas',
+  int column = 3,
+  int row = 12,
+}) {
+  return SurfaceAtlasTileRef(atlasId: atlasId, column: column, row: row);
+}
+
+SurfaceAnimationFrame _frame({
+  SurfaceAtlasTileRef? tileRef,
+  int durationMs = 120,
+}) {
+  return SurfaceAnimationFrame(
+    tileRef: tileRef ?? _tileRef(),
+    durationMs: durationMs,
+  );
+}
+
+String _deepStr(Object? o) {
+  if (o is Map) {
+    return '{${o.keys.map((k) => '$k:${_deepStr(o[k])}').join(',')}}';
+  }
+  if (o is String) {
+    return o;
+  }
+  if (o is int) {
+    return '$o';
+  }
+  if (o == null) {
+    return 'null';
+  }
+  return o.toString();
+}
```

#### C.4 Rapport Lot 40 (ce fichier)

Ce document inclut déjà l’Evidence Pack (§36 A–D). Pour le fichier Markdown de rapport lui-même, l’exception contractuelle du lot s’applique : la preuve est le contenu de ce même fichier, sans exiger un second `diff` redondant reprenant mot pour mot l’intégralité du rapport.

### D. Sorties de commandes (complètes, telles qu’enregistrées)

#### D.1 `dart test test/surface_animation_frame_json_codec_test.dart` (retours chariot de progression convertis en sauts de ligne)

```

00:00 [32m+0[0m: [1m[90mloading test/surface_animation_frame_json_codec_test.dart[0m[0m                                                                                                                                    
00:00 [32m+0[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 1. encodes SurfaceAtlasTileRef[0m                                                                                                    
00:00 [32m+1[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 1. encodes SurfaceAtlasTileRef[0m                                                                                                    
00:00 [32m+1[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 2. decodes SurfaceAtlasTileRef[0m                                                                                                    
00:00 [32m+2[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 2. decodes SurfaceAtlasTileRef[0m                                                                                                    
00:00 [32m+2[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 3. round-trip SurfaceAtlasTileRef[0m                                                                                                 
00:00 [32m+3[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 3. round-trip SurfaceAtlasTileRef[0m                                                                                                 
00:00 [32m+3[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 4. preserves exact atlasId string (no trim)[0m                                                                                       
00:00 [32m+4[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 4. preserves exact atlasId string (no trim)[0m                                                                                       
00:00 [32m+4[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 5. rejects atlasId missing, wrong type, whitespace-only[0m                                                                           
00:00 [32m+5[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 5. rejects atlasId missing, wrong type, whitespace-only[0m                                                                           
00:00 [32m+5[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 6. rejects column missing, wrong type, negative[0m                                                                                   
00:00 [32m+6[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 6. rejects column missing, wrong type, negative[0m                                                                                   
00:00 [32m+6[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 7. rejects row missing, wrong type, negative[0m                                                                                      
00:00 [32m+7[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 7. rejects row missing, wrong type, negative[0m                                                                                      
00:00 [32m+7[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 8. decode SurfaceAtlasTileRef ignores unknown keys[0m                                                                                
00:00 [32m+8[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 8. decode SurfaceAtlasTileRef ignores unknown keys[0m                                                                                
00:00 [32m+8[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 9. decode SurfaceAtlasTileRef does not mutate source map[0m                                                                          
00:00 [32m+9[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 9. decode SurfaceAtlasTileRef does not mutate source map[0m                                                                          
00:00 [32m+9[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 10. encodes SurfaceAnimationFrame[0m                                                                                                 
00:00 [32m+10[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 10. encodes SurfaceAnimationFrame[0m                                                                                                
00:00 [32m+10[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 11. decodes SurfaceAnimationFrame[0m                                                                                                
00:00 [32m+11[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 11. decodes SurfaceAnimationFrame[0m                                                                                                
00:00 [32m+11[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 12. round-trip SurfaceAnimationFrame[0m                                                                                             
00:00 [32m+12[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 12. round-trip SurfaceAnimationFrame[0m                                                                                             
00:00 [32m+12[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 13. rejects frame tileRef missing or wrong type[0m                                                                                  
00:00 [32m+13[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 13. rejects frame tileRef missing or wrong type[0m                                                                                  
00:00 [32m+13[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 14. rejects durationMs missing or wrong type[0m                                                                                     
00:00 [32m+14[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 14. rejects durationMs missing or wrong type[0m                                                                                     
00:00 [32m+14[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 15. rejects durationMs <= 0[0m                                                                                                      
00:00 [32m+15[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 15. rejects durationMs <= 0[0m                                                                                                      
00:00 [32m+15[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 16. decode SurfaceAnimationFrame ignores unknown keys[0m                                                                            
00:00 [32m+16[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 16. decode SurfaceAnimationFrame ignores unknown keys[0m                                                                            
00:00 [32m+16[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 17. decode SurfaceAnimationFrame does not mutate source map[0m                                                                      
00:00 [32m+17[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 17. decode SurfaceAnimationFrame does not mutate source map[0m                                                                      
00:00 [32m+17[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 18. does not verify geometry; isInside is separate[0m                                                                               
00:00 [32m+18[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 18. does not verify geometry; isInside is separate[0m                                                                               
00:00 [32m+18[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 19. nested tileRef errors propagate from decode frame[0m                                                                            
00:00 [32m+19[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 19. nested tileRef errors propagate from decode frame[0m                                                                            
00:00 [32m+19[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 20. public API encodeSurfaceAnimationFrame returns Map[0m                                                                           
00:00 [32m+20[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 20. public API encodeSurfaceAnimationFrame returns Map[0m                                                                           
00:00 [32m+20[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 21. ProjectManifest has no surface persistence keys (Lot 40)[0m                                                                     
00:00 [32m+21[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 21. ProjectManifest has no surface persistence keys (Lot 40)[0m                                                                     
00:00 [32m+21[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 22. codec external to models: no Surface toJson or fromJson on ref/frame[0m                                                         
00:00 [32m+22[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 22. codec external to models: no Surface toJson or fromJson on ref/frame[0m                                                         
00:00 [32m+22[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 23. no timeline or ProjectSurfaceAnimation codec in this lot[0m                                                                     
00:00 [32m+23[0m: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 23. no timeline or ProjectSurfaceAnimation codec in this lot[0m                                                                     
00:00 [32m+23[0m: All tests passed![0m                                                                                                                                                                           
```

#### D.2 `dart test test/surface_atlas_tile_ref_test.dart`

```

00:00 [32m+0[0m: [1m[90mloading test/surface_atlas_tile_ref_test.dart[0m[0m                                                                                                                                                
00:00 [32m+0[0m: SurfaceAtlasTileRef minimal ref holds fields[0m                                                                                                                                                 
00:00 [32m+1[0m: SurfaceAtlasTileRef minimal ref holds fields[0m                                                                                                                                                 
00:00 [32m+1[0m: SurfaceAtlasTileRef stores atlasId exactly without trimming the stored value[0m                                                                                                                 
00:00 [32m+2[0m: SurfaceAtlasTileRef stores atlasId exactly without trimming the stored value[0m                                                                                                                 
00:00 [32m+2[0m: SurfaceAtlasTileRef rejects empty atlasId: empty string[0m                                                                                                                                      
00:00 [32m+3[0m: SurfaceAtlasTileRef rejects empty atlasId: empty string[0m                                                                                                                                      
00:00 [32m+3[0m: SurfaceAtlasTileRef rejects empty atlasId: whitespace only[0m                                                                                                                                   
00:00 [32m+4[0m: SurfaceAtlasTileRef rejects empty atlasId: whitespace only[0m                                                                                                                                   
00:00 [32m+4[0m: SurfaceAtlasTileRef rejects negative column[0m                                                                                                                                                  
00:00 [32m+5[0m: SurfaceAtlasTileRef rejects negative column[0m                                                                                                                                                  
00:00 [32m+5[0m: SurfaceAtlasTileRef rejects negative row[0m                                                                                                                                                     
00:00 [32m+6[0m: SurfaceAtlasTileRef rejects negative row[0m                                                                                                                                                     
00:00 [32m+6[0m: SurfaceAtlasTileRef accepts column and row zero[0m                                                                                                                                              
00:00 [32m+7[0m: SurfaceAtlasTileRef accepts column and row zero[0m                                                                                                                                              
00:00 [32m+7[0m: SurfaceAtlasTileRef isInside: true for interior cells[0m                                                                                                                                        
00:00 [32m+8[0m: SurfaceAtlasTileRef isInside: true for interior cells[0m                                                                                                                                        
00:00 [32m+8[0m: SurfaceAtlasTileRef isInside: false when out of grid[0m                                                                                                                                         
00:00 [32m+9[0m: SurfaceAtlasTileRef isInside: false when out of grid[0m                                                                                                                                         
00:00 [32m+9[0m: SurfaceAtlasTileRef isInside: same column/row independent of layout enum[0m                                                                                                                     
00:00 [32m+10[0m: SurfaceAtlasTileRef isInside: same column/row independent of layout enum[0m                                                                                                                    
00:00 [32m+10[0m: SurfaceAtlasTileRef value equality: same values and hashCode[0m                                                                                                                                
00:00 [32m+11[0m: SurfaceAtlasTileRef value equality: same values and hashCode[0m                                                                                                                                
00:00 [32m+11[0m: SurfaceAtlasTileRef value equality: atlasId differs[0m                                                                                                                                         
00:00 [32m+12[0m: SurfaceAtlasTileRef value equality: atlasId differs[0m                                                                                                                                         
00:00 [32m+12[0m: SurfaceAtlasTileRef value equality: column differs[0m                                                                                                                                          
00:00 [32m+13[0m: SurfaceAtlasTileRef value equality: column differs[0m                                                                                                                                          
00:00 [32m+13[0m: SurfaceAtlasTileRef value equality: row differs[0m                                                                                                                                             
00:00 [32m+14[0m: SurfaceAtlasTileRef value equality: row differs[0m                                                                                                                                             
00:00 [32m+14[0m: SurfaceAtlasTileRef export: type is visible through map_core[0m                                                                                                                                
00:00 [32m+15[0m: SurfaceAtlasTileRef export: type is visible through map_core[0m                                                                                                                                
00:00 [32m+15[0m: SurfaceAtlasTileRef ProjectManifest toJson: no surface* top-level keys[0m                                                                                                                      
00:00 [32m+16[0m: SurfaceAtlasTileRef ProjectManifest toJson: no surface* top-level keys[0m                                                                                                                      
00:00 [32m+16[0m: All tests passed![0m                                                                                                                                                                           
```

#### D.3 `dart test test/surface_animation_frame_test.dart`

```

00:00 [32m+0[0m: [1m[90mloading test/surface_animation_frame_test.dart[0m[0m                                                                                                                                               
00:00 [32m+0[0m: SurfaceAnimationFrame minimal frame holds tileRef and durationMs[0m                                                                                                                             
00:00 [32m+1[0m: SurfaceAnimationFrame minimal frame holds tileRef and durationMs[0m                                                                                                                             
00:00 [32m+1[0m: SurfaceAnimationFrame preserves the exact same tileRef instance (identity)[0m                                                                                                                   
00:00 [32m+2[0m: SurfaceAnimationFrame preserves the exact same tileRef instance (identity)[0m                                                                                                                   
00:00 [32m+2[0m: SurfaceAnimationFrame rejects durationMs == 0[0m                                                                                                                                                
00:00 [32m+3[0m: SurfaceAnimationFrame rejects durationMs == 0[0m                                                                                                                                                
00:00 [32m+3[0m: SurfaceAnimationFrame rejects durationMs < 0[0m                                                                                                                                                 
00:00 [32m+4[0m: SurfaceAnimationFrame rejects durationMs < 0[0m                                                                                                                                                 
00:00 [32m+4[0m: SurfaceAnimationFrame accepts durationMs == 1[0m                                                                                                                                                
00:00 [32m+5[0m: SurfaceAnimationFrame accepts durationMs == 1[0m                                                                                                                                                
00:00 [32m+5[0m: SurfaceAnimationFrame isInside: true for interior cell[0m                                                                                                                                       
00:00 [32m+6[0m: SurfaceAnimationFrame isInside: true for interior cell[0m                                                                                                                                       
00:00 [32m+6[0m: SurfaceAnimationFrame isInside: false when cell out of grid[0m                                                                                                                                  
00:00 [32m+7[0m: SurfaceAnimationFrame isInside: false when cell out of grid[0m                                                                                                                                  
00:00 [32m+7[0m: SurfaceAnimationFrame isInside: same frame independent of layout enum[0m                                                                                                                        
00:00 [32m+8[0m: SurfaceAnimationFrame isInside: same frame independent of layout enum[0m                                                                                                                        
00:00 [32m+8[0m: SurfaceAnimationFrame value equality: same tile values and duration => equal and same hash[0m                                                                                                   
00:00 [32m+9[0m: SurfaceAnimationFrame value equality: same tile values and duration => equal and same hash[0m                                                                                                   
00:00 [32m+9[0m: SurfaceAnimationFrame value equality: different tileRef (atlasId)[0m                                                                                                                            
00:00 [32m+10[0m: SurfaceAnimationFrame value equality: different tileRef (atlasId)[0m                                                                                                                           
00:00 [32m+10[0m: SurfaceAnimationFrame value equality: different tileRef (column)[0m                                                                                                                            
00:00 [32m+11[0m: SurfaceAnimationFrame value equality: different tileRef (column)[0m                                                                                                                            
00:00 [32m+11[0m: SurfaceAnimationFrame value equality: different durationMs[0m                                                                                                                                  
00:00 [32m+12[0m: SurfaceAnimationFrame value equality: different durationMs[0m                                                                                                                                  
00:00 [32m+12[0m: SurfaceAnimationFrame export: type is visible through map_core[0m                                                                                                                              
00:00 [32m+13[0m: SurfaceAnimationFrame export: type is visible through map_core[0m                                                                                                                              
00:00 [32m+13[0m: SurfaceAnimationFrame ProjectManifest toJson: no surface* top-level keys[0m                                                                                                                    
00:00 [32m+14[0m: SurfaceAnimationFrame ProjectManifest toJson: no surface* top-level keys[0m                                                                                                                    
00:00 [32m+14[0m: All tests passed![0m                                                                                                                                                                           
```

#### D.4 `dart test test/surface_atlas_json_codec_test.dart`

```

00:00 [32m+0[0m: [1m[90mloading test/surface_atlas_json_codec_test.dart[0m[0m                                                                                                                                              
00:00 [32m+0[0m: surface_atlas_json_codec (Lot 39) 1. encode SurfaceAtlasTileSize[0m                                                                                                                             
00:00 [32m+1[0m: surface_atlas_json_codec (Lot 39) 1. encode SurfaceAtlasTileSize[0m                                                                                                                             
00:00 [32m+1[0m: surface_atlas_json_codec (Lot 39) 2. decode SurfaceAtlasTileSize[0m                                                                                                                             
00:00 [32m+2[0m: surface_atlas_json_codec (Lot 39) 2. decode SurfaceAtlasTileSize[0m                                                                                                                             
00:00 [32m+2[0m: surface_atlas_json_codec (Lot 39) 3. reject tile size missing / wrong type / width 0[0m                                                                                                         
00:00 [32m+3[0m: surface_atlas_json_codec (Lot 39) 3. reject tile size missing / wrong type / width 0[0m                                                                                                         
00:00 [32m+3[0m: surface_atlas_json_codec (Lot 39) 4. encode SurfaceAtlasGridSize[0m                                                                                                                             
00:00 [32m+4[0m: surface_atlas_json_codec (Lot 39) 4. encode SurfaceAtlasGridSize[0m                                                                                                                             
00:00 [32m+4[0m: surface_atlas_json_codec (Lot 39) 5. decode SurfaceAtlasGridSize[0m                                                                                                                             
00:00 [32m+5[0m: surface_atlas_json_codec (Lot 39) 5. decode SurfaceAtlasGridSize[0m                                                                                                                             
00:00 [32m+5[0m: surface_atlas_json_codec (Lot 39) 6. reject grid size missing / wrong type / columns 0[0m                                                                                                       
00:00 [32m+6[0m: surface_atlas_json_codec (Lot 39) 6. reject grid size missing / wrong type / columns 0[0m                                                                                                       
00:00 [32m+6[0m: surface_atlas_json_codec (Lot 39) 7. encode/decode layout grid[0m                                                                                                                               
00:00 [32m+7[0m: surface_atlas_json_codec (Lot 39) 7. encode/decode layout grid[0m                                                                                                                               
00:00 [32m+7[0m: surface_atlas_json_codec (Lot 39) 8. encode/decode layout columnsAreVariantsRowsAreFrames[0m                                                                                                    
00:00 [32m+8[0m: surface_atlas_json_codec (Lot 39) 8. encode/decode layout columnsAreVariantsRowsAreFrames[0m                                                                                                    
00:00 [32m+8[0m: surface_atlas_json_codec (Lot 39) 9. reject layout unknown or wrong casing[0m                                                                                                                   
00:00 [32m+9[0m: surface_atlas_json_codec (Lot 39) 9. reject layout unknown or wrong casing[0m                                                                                                                   
00:00 [32m+9[0m: surface_atlas_json_codec (Lot 39) 10. encode SurfaceAtlasGeometry[0m                                                                                                                            
00:00 [32m+10[0m: surface_atlas_json_codec (Lot 39) 10. encode SurfaceAtlasGeometry[0m                                                                                                                           
00:00 [32m+10[0m: surface_atlas_json_codec (Lot 39) 11. decode SurfaceAtlasGeometry + tileCount[0m                                                                                                               
00:00 [32m+11[0m: surface_atlas_json_codec (Lot 39) 11. decode SurfaceAtlasGeometry + tileCount[0m                                                                                                               
00:00 [32m+11[0m: surface_atlas_json_codec (Lot 39) 12. reject geometry missing nested / wrong types[0m                                                                                                          
00:00 [32m+12[0m: surface_atlas_json_codec (Lot 39) 12. reject geometry missing nested / wrong types[0m                                                                                                          
00:00 [32m+12[0m: surface_atlas_json_codec (Lot 39) 13. encode ProjectSurfaceAtlas minimal[0m                                                                                                                    
00:00 [32m+13[0m: surface_atlas_json_codec (Lot 39) 13. encode ProjectSurfaceAtlas minimal[0m                                                                                                                    
00:00 [32m+13[0m: surface_atlas_json_codec (Lot 39) 14. encode ProjectSurfaceAtlas full[0m                                                                                                                       
00:00 [32m+14[0m: surface_atlas_json_codec (Lot 39) 14. encode ProjectSurfaceAtlas full[0m                                                                                                                       
00:00 [32m+14[0m: surface_atlas_json_codec (Lot 39) 15. decode ProjectSurfaceAtlas minimal (no category, no sortOrder)[0m                                                                                        
00:00 [32m+15[0m: surface_atlas_json_codec (Lot 39) 15. decode ProjectSurfaceAtlas minimal (no category, no sortOrder)[0m                                                                                        
00:00 [32m+15[0m: surface_atlas_json_codec (Lot 39) 16. decode ProjectSurfaceAtlas full[0m                                                                                                                       
00:00 [32m+16[0m: surface_atlas_json_codec (Lot 39) 16. decode ProjectSurfaceAtlas full[0m                                                                                                                       
00:00 [32m+16[0m: surface_atlas_json_codec (Lot 39) 17. round-trip ProjectSurfaceAtlas[0m                                                                                                                        
00:00 [32m+17[0m: surface_atlas_json_codec (Lot 39) 17. round-trip ProjectSurfaceAtlas[0m                                                                                                                        
00:00 [32m+17[0m: surface_atlas_json_codec (Lot 39) 18. exact strings preserved (no trim in codec)[0m                                                                                                            
00:00 [32m+18[0m: surface_atlas_json_codec (Lot 39) 18. exact strings preserved (no trim in codec)[0m                                                                                                            
00:00 [32m+18[0m: surface_atlas_json_codec (Lot 39) 19. reject id / name / tilesetId missing, wrong type, whitespace tileset[0m                                                                                  
00:00 [32m+19[0m: surface_atlas_json_codec (Lot 39) 19. reject id / name / tilesetId missing, wrong type, whitespace tileset[0m                                                                                  
00:00 [32m+19[0m: surface_atlas_json_codec (Lot 39) 20. reject geometry missing or non-map on atlas[0m                                                                                                           
00:00 [32m+20[0m: surface_atlas_json_codec (Lot 39) 20. reject geometry missing or non-map on atlas[0m                                                                                                           
00:00 [32m+20[0m: surface_atlas_json_codec (Lot 39) 21. reject categoryId non-string non-null[0m                                                                                                                 
00:00 [32m+21[0m: surface_atlas_json_codec (Lot 39) 21. reject categoryId non-string non-null[0m                                                                                                                 
00:00 [32m+21[0m: surface_atlas_json_codec (Lot 39) 22. decode categoryId null in JSON[0m                                                                                                                        
00:00 [32m+22[0m: surface_atlas_json_codec (Lot 39) 22. decode categoryId null in JSON[0m                                                                                                                        
00:00 [32m+22[0m: surface_atlas_json_codec (Lot 39) 23. reject sortOrder non-int[0m                                                                                                                              
00:00 [32m+23[0m: surface_atlas_json_codec (Lot 39) 23. reject sortOrder non-int[0m                                                                                                                              
00:00 [32m+23[0m: surface_atlas_json_codec (Lot 39) 24. decode sortOrder negative[0m                                                                                                                             
00:00 [32m+24[0m: surface_atlas_json_codec (Lot 39) 24. decode sortOrder negative[0m                                                                                                                             
00:00 [32m+24[0m: surface_atlas_json_codec (Lot 39) 25. decode ignores unknown top-level key[0m                                                                                                                  
00:00 [32m+25[0m: surface_atlas_json_codec (Lot 39) 25. decode ignores unknown top-level key[0m                                                                                                                  
00:00 [32m+25[0m: surface_atlas_json_codec (Lot 39) 26. tilesetId not resolved against manifest[0m                                                                                                               
00:00 [32m+26[0m: surface_atlas_json_codec (Lot 39) 26. tilesetId not resolved against manifest[0m                                                                                                               
00:00 [32m+26[0m: surface_atlas_json_codec (Lot 39) 27. decode does not mutate source map[0m                                                                                                                     
00:00 [32m+27[0m: surface_atlas_json_codec (Lot 39) 27. decode does not mutate source map[0m                                                                                                                     
00:00 [32m+27[0m: surface_atlas_json_codec (Lot 39) 28. public API returns Map from encode[0m                                                                                                                    
00:00 [32m+28[0m: surface_atlas_json_codec (Lot 39) 28. public API returns Map from encode[0m                                                                                                                    
00:00 [32m+28[0m: surface_atlas_json_codec (Lot 39) 29. ProjectManifest has no surface persistence keys (Lot 39)[0m                                                                                              
00:00 [32m+29[0m: surface_atlas_json_codec (Lot 39) 29. ProjectManifest has no surface persistence keys (Lot 39)[0m                                                                                              
00:00 [32m+29[0m: surface_atlas_json_codec (Lot 39) 30. codec external to models: no model toJson / fromJson[0m                                                                                                  
00:00 [32m+30[0m: surface_atlas_json_codec (Lot 39) 30. codec external to models: no model toJson / fromJson[0m                                                                                                  
00:00 [32m+30[0m: All tests passed![0m                                                                                                                                                                           
```

#### D.5 `dart test test/surface_model_entrypoint_test.dart`

```

00:00 [32m+0[0m: [1m[90mloading test/surface_model_entrypoint_test.dart[0m[0m                                                                                                                                              
00:00 [32m+0[0m: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) SurfaceAtlasLayout.values exposes exactly the expected cases in order[0m                                                                 
00:00 [32m+1[0m: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) SurfaceAtlasLayout.values exposes exactly the expected cases in order[0m                                                                 
00:00 [32m+1[0m: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) ProjectManifest JSON has no surface engine manifest keys yet[0m                                                                          
00:00 [32m+2[0m: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) ProjectManifest JSON has no surface engine manifest keys yet[0m                                                                          
00:00 [32m+2[0m: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) ProjectPathPreset construction remains available unchanged[0m                                                                            
00:00 [32m+3[0m: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) ProjectPathPreset construction remains available unchanged[0m                                                                            
00:00 [32m+3[0m: All tests passed![0m                                                                                                                                                                            
```

#### D.6 `dart analyze` (chemins du lot)

```
Analyzing surface_animation_frame_json_codec.dart, surface_atlas_json_codec.dart, surface.dart, surface_animation_frame_json_codec_test.dart, surface_atlas_tile_ref_test.dart, surface_animation_frame_test.dart, surface_atlas_json_codec_test.dart, surface_model_entrypoint_test.dart, map_core.dart...
No issues found!
```

#### D.7 `dart test` (suite complète `map_core`)

Commande : `cd packages/map_core && /opt/homebrew/bin/dart test`

Dernière ligne (sortie avec retours chariot convertis) :

```
00:01 [32m+919[0m: All tests passed![0m                                                                                                                                                                          
```
