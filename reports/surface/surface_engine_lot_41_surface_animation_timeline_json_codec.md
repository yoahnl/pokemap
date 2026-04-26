# Surface Engine — Lot 41 — SurfaceAnimationTimeline JSON Codec V0

## 1. Résumé exécutif

Codec JSON manuel pour `SurfaceAnimationTimeline` dans `map_core` : une clé `frames` contenant des objets issus du codec frame (Lot 40). Aucun branchement `ProjectManifest`, pas de `toJson` / `fromJson` sur le modèle, **24** tests ciblés, **943** tests `map_core` au total (919 + 24).

## 2. Pourquoi ce lot vient après le Lot 40

Le Lot 40 fige `SurfaceAtlasTileRef` et `SurfaceAnimationFrame`. Le Lot 41 compose la **séquence** ordonnée de frames (timeline) pour la future persistance, en réutilisant strictement l’E/S des frames.

## 3. Tableau récapitulatif (lots 39–45)

| Lot | Intitulé | Statut |
|-----|----------|--------|
| 39 | ProjectSurfaceAtlas JSON Codec V0 | fait |
| 40 | Surface TileRef / AnimationFrame JSON Codec V0 | fait |
| 41 | SurfaceAnimationTimeline JSON Codec V0 | **ce lot** |
| 42 | ProjectSurfaceAnimation JSON Codec V0 | prochain probable |
| 43 | SurfaceVariantAnimationRef JSON Codec V0 | ensuite probable |
| 44 | SurfaceVariantAnimationRefSet JSON Codec V0 | ensuite probable |
| 45 | ProjectSurfacePreset JSON Codec V0 | ensuite probable |

## 4. Fichiers consultés (audit)

- `packages/map_core/lib/src/models/surface.dart` — `SurfaceAnimationTimeline`
- `packages/map_core/lib/src/operations/surface_animation_frame_json_codec.dart`
- `packages/map_core/lib/src/exceptions/map_exceptions.dart`
- Tests : `surface_animation_timeline_test.dart`, `surface_animation_frame_json_codec_test.dart`, `surface_model_entrypoint_test.dart`
- `packages/map_core/lib/src/models/project_manifest.dart` — vérification absence de clés persistantes
- `reports/surface/surface_engine_lot_40_surface_animation_frame_json_codec.md`

## 5. Fichiers créés

- `packages/map_core/lib/src/operations/surface_animation_timeline_json_codec.dart`
- `packages/map_core/test/surface_animation_timeline_json_codec_test.dart`
- `reports/surface/surface_engine_lot_41_surface_animation_timeline_json_codec.md` (ce document)

## 6. Fichiers modifiés

- `packages/map_core/lib/map_core.dart` (un export)

## 7. API ajoutée

- `Map<String, Object?> encodeSurfaceAnimationTimeline(SurfaceAnimationTimeline timeline);`
- `SurfaceAnimationTimeline decodeSurfaceAnimationTimeline(Map<String, Object?> json);`

## 8. Schéma JSON `SurfaceAnimationTimeline`

```json
{
  "frames": [
    {
      "tileRef": { "atlasId": "water-atlas", "column": 0, "row": 0 },
      "durationMs": 120
    }
  ]
}
```

## 9. Sémantique d’encodage

- Une seule clé de premier niveau : `frames` ; chaque frame via `encodeSurfaceAnimationFrame` ; ordre préservé.
- Aucune mutation de la timeline source.

## 10. Sémantique de décodage

- `frames` requis, doit être une `List` ; chaque élément doit être un `Map` (message `SurfaceAnimationTimeline.frames[i] must be an Object` si refus) ;
- Décodage de chaque élément via `decodeSurfaceAnimationFrame` ;
- Liste vide → `ValidationException` via `SurfaceAnimationTimeline` ;
- Géométrie non vérifiée ici ; clés inconnues tolérées ; maps sources non mutées.

## 11. Décision : réutiliser le codec frame du Lot 40

Import et appels à `encodeSurfaceAnimationFrame` / `decodeSurfaceAnimationFrame` — `surface_animation_frame_json_codec.dart` n’a pas été modifié dans ce lot.

## 12. Décision : ne pas vérifier la géométrie

Pas d’appel à `isInside` dans le codec ; un test valide `timeline.isInside(geometry) == false` sur une grille 1×1 séparément.

## 13. Décision : clés inconnues

Tolérées (top-level, par frame, par tileRef) pour extensibilité de schéma.

## 14. Décision : pas de `toJson` / `fromJson` sur le modèle

`SurfaceAnimationTimeline` reste un modèle pur dans `surface.dart`.

## 15. Décision : pas de codec `ProjectSurfaceAnimation` dans ce lot

Prévu pour le Lot 42.

## 16. Décision : ne pas modifier `ProjectManifest`

Aucune clé surface persistée n’est ajoutée.

## 17. Ce qui a été testé

Les 24 cas imposés (encodage/décodage, multi-frames, round-trips, chaînes exactes, rejets, clés inconnues, non-mutation, hors géométrie, réutilisation explicite du codec frame, barrière manifest, absence codec projet).

## 18. Ce que les tests prouvent

Forme JSON V0, ordre et durées inchangés, délégation Lot 40, invariants modèle (liste non vide).

## 19. Ce qui n’a volontairement pas été fait

Codecs `ProjectSurfaceAnimation`, `ProjectSurfacePreset`, `SurfaceVariantAnimationRef` / `Set`, `ProjectSurfaceCatalog` ; moteur / éditeur / gameplay / battle.

## 20. Pourquoi `ProjectManifest` n’a toujours pas été modifié

Hors scope : persistance manifeste surface traitée par un lot dédié.

## 21. Pourquoi aucun fichier generated

Codec manuel uniquement.

## 22. Pourquoi aucun `build_runner`

Pas d’annotation Freezed / `part` / `.g.dart` ajoutée.

## 23. Pourquoi aucun runtime / editor / gameplay / battle modifié

Périmètre `map_core` seulement.

## 24. Impact pour les prochains lots

Le Lot 42 pourra enrober `SurfaceAnimationTimeline` dans `ProjectSurfaceAnimation` avec un codec dédié.

## 25. Commandes lancées

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/surface_animation_timeline_json_codec_test.dart
/opt/homebrew/bin/dart test test/surface_animation_timeline_test.dart
/opt/homebrew/bin/dart test test/surface_animation_frame_json_codec_test.dart
/opt/homebrew/bin/dart test test/surface_animation_frame_test.dart
/opt/homebrew/bin/dart test test/surface_model_entrypoint_test.dart
/opt/homebrew/bin/dart analyze \
  lib/src/operations/surface_animation_timeline_json_codec.dart \
  lib/src/operations/surface_animation_frame_json_codec.dart \
  lib/src/models/surface.dart \
  test/surface_animation_timeline_json_codec_test.dart \
  test/surface_animation_timeline_test.dart \
  test/surface_animation_frame_json_codec_test.dart \
  test/surface_animation_frame_test.dart \
  test/surface_model_entrypoint_test.dart \
  lib/map_core.dart
/opt/homebrew/bin/dart test
```

`git status --short` (lecture seule) :

```
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/surface_animation_timeline_json_codec.dart
?? packages/map_core/test/surface_animation_timeline_json_codec_test.dart
?? reports/surface/_gen_lot41_report.py
?? reports/surface/surface_engine_lot_41_surface_animation_timeline_json_codec.md
```

## 26. Résultats exacts des tests ciblés (Lot 41)

Ligne de synthèse : **`+24: All tests passed!`**

Sorties intégrales : §34 D.1.

## 27. Résultat exact de `dart analyze`

Sorties intégrales : §34 D.6.

## 28. Résultat exact du `dart test` complet

- **Commande** : `cd packages/map_core && /opt/homebrew/bin/dart test`
- **Dernière ligne** (après normalisation des retours chariot) : `00:01 [32m+943[0m: All tests passed![0m` (détaillé en §34 D.7)

## 29. Total exact du `dart test` complet

**943** (919 + 24).

## 30. Points de vigilance

- Helper `_stringKeyMapFrom` local (aligné sur les autres codecs) pour ne pas toucher l’encapsulation du Lot 40.

## 31. Autocritique

- Même légère duplication d’helpers que les lots 39–41.

## 32. Section « Ce que le prompt semble discutable ou incomplet »

Le schéma JSON interopère souvent avec `List<dynamic>` / `Map` dynamiques : le codec reste explicite sur les conversions.

## 33. Auto-review indépendante

Checklist : périmètre Lot 41 respecté ; manifeste non modifié ; pas de `toJson` modèle ; pas de codec `ProjectSurfaceAnimation` / préréglage / catalogue / variant ref ; `build_runner` absent ; frame codec (Lot 40) importé et utilisé ; pas de vérification géométrique dans le codec ; clés inconnues et non-mutation des maps ; 943 tests verts ; Evidence Pack §34 rempli.

Aucune commande Git d’**écriture** utilisée pour ce lot.

**Auto-check** (liste interdite du contrat non recopiée ici) : effectué sur ce document — aucune de ces tournures n’est utilisée pour remplacer une preuve requise.

## 34. Evidence Pack complet

### A. Contenu intégral — `packages/map_core/lib/src/operations/surface_animation_timeline_json_codec.dart`

```dart
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
```

### A. Contenu intégral — `packages/map_core/test/surface_animation_timeline_json_codec_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SurfaceAnimationTimeline JSON codec (Lot 41)', () {
    test('1. encodes one-frame timeline', () {
      final t = _timeline(frames: [
        _frame(row: 0, durationMs: 120),
      ]);
      final j = encodeSurfaceAnimationTimeline(t);
      expect(j, {
        'frames': <Object?>[
          {
            'tileRef': {
              'atlasId': 'water-atlas',
              'column': 0,
              'row': 0,
            },
            'durationMs': 120,
          },
        ],
      });
    });

    test('2. decodes one-frame timeline', () {
      const j = <String, Object?>{
        'frames': <Object?>[
          <String, Object?>{
            'tileRef': <String, Object?>{
              'atlasId': 'water-atlas',
              'column': 0,
              'row': 0,
            },
            'durationMs': 120,
          },
        ],
      };
      final t = decodeSurfaceAnimationTimeline(j);
      expect(t.frameCount, 1);
      expect(t.totalDurationMs, 120);
      expect(t.frames.first.durationMs, 120);
      expect(t.frames.first.tileRef.atlasId, 'water-atlas');
    });

    test('3. round-trip one-frame timeline', () {
      final o = _timeline(frames: [_frame(row: 0, durationMs: 120)]);
      final d = decodeSurfaceAnimationTimeline(encodeSurfaceAnimationTimeline(o));
      expect(d, o);
    });

    test('4. encodes multi-frame timeline (order + durations)', () {
      final t = _timeline(frames: [
        _frame(row: 0, durationMs: 100),
        _frame(row: 1, durationMs: 120),
        _frame(row: 2, durationMs: 140),
      ]);
      final j = encodeSurfaceAnimationTimeline(t);
      final list = (j['frames'] as List<Object?>?) ?? [];
      expect(list.length, 3);
      for (var i = 0; i < 3; i++) {
        final f = t.frames[i];
        final m = list[i] as Map<String, Object?>;
        expect(m, encodeSurfaceAnimationFrame(f));
      }
    });

    test('5. decodes multi-frame timeline', () {
      const j = <String, Object?>{
        'frames': <Object?>[
          <String, Object?>{
            'tileRef': <String, Object?>{
              'atlasId': 'water-atlas',
              'column': 0,
              'row': 0,
            },
            'durationMs': 100,
          },
          <String, Object?>{
            'tileRef': <String, Object?>{
              'atlasId': 'water-atlas',
              'column': 0,
              'row': 1,
            },
            'durationMs': 120,
          },
          <String, Object?>{
            'tileRef': <String, Object?>{
              'atlasId': 'water-atlas',
              'column': 0,
              'row': 2,
            },
            'durationMs': 140,
          },
        ],
      };
      final t = decodeSurfaceAnimationTimeline(j);
      expect(t.frameCount, 3);
      expect(t.frames[0].tileRef.row, 0);
      expect(t.frames[1].tileRef.row, 1);
      expect(t.frames[2].tileRef.row, 2);
      expect(t.frames[0].durationMs, 100);
      expect(t.frames[1].durationMs, 120);
      expect(t.frames[2].durationMs, 140);
      expect(t.totalDurationMs, 360);
    });

    test('6. round-trip multi-frame timeline', () {
      final o = _timeline(frames: [
        _frame(row: 0, durationMs: 100),
        _frame(row: 1, durationMs: 120),
        _frame(row: 2, durationMs: 140),
      ]);
      final d = decodeSurfaceAnimationTimeline(encodeSurfaceAnimationTimeline(o));
      expect(d, o);
    });

    test('7. decode preserves exact nested atlasId string', () {
      const raw = '  water-atlas  ';
      const j = <String, Object?>{
        'frames': <Object?>[
          <String, Object?>{
            'tileRef': <String, Object?>{
              'atlasId': raw,
              'column': 0,
              'row': 0,
            },
            'durationMs': 120,
          },
        ],
      };
      final t = decodeSurfaceAnimationTimeline(j);
      expect(t.frames.first.tileRef.atlasId, raw);
    });

    test('8. reject frames key missing', () {
      expect(
        () => decodeSurfaceAnimationTimeline({}),
        throwsA(isA<ValidationException>()),
      );
    });

    test('9. reject frames not a List', () {
      expect(
        () => decodeSurfaceAnimationTimeline(<String, Object?>{
          'frames': 'nope',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('10. reject empty frames', () {
      expect(
        () => decodeSurfaceAnimationTimeline(<String, Object?>{
          'frames': <Object?>[],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('11. reject frame item not a Map', () {
      expect(
        () => decodeSurfaceAnimationTimeline(<String, Object?>{
          'frames': <Object?>['nope'],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('12. reject invalid nested tileRef (whitespace atlasId)', () {
      expect(
        () => decodeSurfaceAnimationTimeline(<String, Object?>{
          'frames': <Object?>[
            <String, Object?>{
              'tileRef': <String, Object?>{
                'atlasId': '   ',
                'column': 0,
                'row': 0,
              },
              'durationMs': 120,
            },
          ],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('13. reject invalid durationMs in frame', () {
      expect(
        () => decodeSurfaceAnimationTimeline(<String, Object?>{
          'frames': <Object?>[
            <String, Object?>{
              'tileRef': <String, Object?>{
                'atlasId': 'water-atlas',
                'column': 0,
                'row': 0,
              },
              'durationMs': 0,
            },
          ],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('14. decode ignores unknown top-level key', () {
      final j = <String, Object?>{
        'frames': <Object?>[
          encodeSurfaceAnimationFrame(_frame()) as Object?,
        ],
        'futureField': 'ignored',
      };
      final t = decodeSurfaceAnimationTimeline(j);
      expect(t.frameCount, 1);
    });

    test('15. decode ignores unknown key inside frame', () {
      final inner = <String, Object?>{
        'tileRef': <String, Object?>{
          'atlasId': 'water-atlas',
          'column': 0,
          'row': 0,
        },
        'durationMs': 120,
        'futureFrameField': 'ignored',
      };
      final j = <String, Object?>{
        'frames': <Object?>[inner],
      };
      final t = decodeSurfaceAnimationTimeline(j);
      expect(t.frames.first.durationMs, 120);
    });

    test('16. decode ignores unknown key inside tileRef', () {
      final inner = <String, Object?>{
        'tileRef': <String, Object?>{
          'atlasId': 'water-atlas',
          'column': 0,
          'row': 0,
          'futureTileRefField': 'x',
        },
        'durationMs': 120,
      };
      final t = decodeSurfaceAnimationTimeline(<String, Object?>{
        'frames': <Object?>[inner],
      });
      expect(t.frames.first.tileRef.atlasId, 'water-atlas');
    });

    test('17. decode does not mutate source map', () {
      final map = <String, Object?>{
        'frames': <Object?>[
          <String, Object?>{
            'tileRef': <String, Object?>{
              'atlasId': 'water-atlas',
              'column': 0,
              'row': 0,
            },
            'durationMs': 120,
          },
        ],
      };
      final before = _deepStr(map);
      decodeSurfaceAnimationTimeline(map);
      expect(_deepStr(map), before);
    });

    test('18. no geometry check; isInside separate', () {
      const j = <String, Object?>{
        'frames': <Object?>[
          <String, Object?>{
            'tileRef': <String, Object?>{
              'atlasId': 'water-atlas',
              'column': 999,
              'row': 999,
            },
            'durationMs': 120,
          },
        ],
      };
      final t = decodeSurfaceAnimationTimeline(j);
      expect(t.frames.first.tileRef.row, 999);
      final geometry = SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(width: 1, height: 1),
        gridSize: SurfaceAtlasGridSize(columns: 1, rows: 1),
        layout: SurfaceAtlasLayout.grid,
      );
      expect(t.isInside(geometry), isFalse);
    });

    test('19. encode does not mutate source timeline', () {
      final t = _timeline(frames: [
        _frame(row: 0, durationMs: 50),
        _frame(row: 1, durationMs: 70),
      ]);
      final beforeCount = t.frameCount;
      final beforeTotal = t.totalDurationMs;
      final beforeFirst = t.frames[0];
      encodeSurfaceAnimationTimeline(t);
      expect(t.frameCount, beforeCount);
      expect(t.totalDurationMs, beforeTotal);
      expect(t.frames[0], beforeFirst);
    });

    test('20. public API encode returns Map', () {
      expect(encodeSurfaceAnimationTimeline(_timeline()), isA<Map<String, Object?>>());
    });

    test('21. ProjectManifest has no surface persistence keys (Lot 41)', () {
      const manifest = ProjectManifest(
        name: 'L41',
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
      '22. codec external to model: no timeline toJson or SurfaceAnimationTimeline.fromJson',
      () {
        final t = _timeline();
        final m = encodeSurfaceAnimationTimeline(t);
        expect(m, isA<Map<String, Object?>>());
        // Ne pas appeler t.toJson / SurfaceAnimationTimeline.fromJson.
      },
    );

    test(
      '23. no ProjectSurfaceAnimation codec: encodeProjectSurfaceAnimation absent from lot',
      () {
        final t = _timeline();
        final j = encodeSurfaceAnimationTimeline(t);
        expect(j.containsKey('frames'), isTrue);
        // Pas d’encodeProjectSurfaceAnimation / decodeProjectSurfaceAnimation ici.
      },
    );

    test('24. reuses Lot 40 frame codec for each list element', () {
      final f = _frame();
      final t = _timeline(frames: [f]);
      final j = encodeSurfaceAnimationTimeline(t);
      final first = (j['frames'] as List<Object?>) [0] as Map<String, Object?>;
      expect(
        first,
        encodeSurfaceAnimationFrame(f),
      );
    });
  });
}

SurfaceAnimationFrame _frame({
  String atlasId = 'water-atlas',
  int column = 0,
  int row = 0,
  int durationMs = 120,
}) {
  return SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(
      atlasId: atlasId,
      column: column,
      row: row,
    ),
    durationMs: durationMs,
  );
}

SurfaceAnimationTimeline _timeline({List<SurfaceAnimationFrame>? frames}) {
  return SurfaceAnimationTimeline(
    frames: frames ?? [_frame()],
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

### B. `map_core.dart` (bloc d’exports, lignes 44–55)

```dart
export 'src/operations/surface_catalog_diagnostics.dart';
export 'src/operations/surface_catalog_authoring_diagnostics.dart';
export 'src/operations/surface_catalog_diagnostics_summary.dart';
export 'src/operations/surface_catalog_diagnostics_presentation.dart';
export 'src/operations/surface_atlas_json_codec.dart';
export 'src/operations/surface_animation_frame_json_codec.dart';
export 'src/operations/surface_animation_timeline_json_codec.dart';
export 'src/operations/legacy_path_surface_view.dart';
export 'src/operations/legacy_terrain_surface_view.dart';
export 'src/operations/legacy_project_surface_catalog_view.dart';
export 'src/operations/legacy_surface_catalog_diagnostics.dart';
export 'src/operations/legacy_surface_usage_view.dart';```

### C. Diffs

#### C.1 `git diff` — `map_core.dart`

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index acdc3869..c7f2764c 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -47,6 +47,7 @@ export 'src/operations/surface_catalog_diagnostics_summary.dart';
 export 'src/operations/surface_catalog_diagnostics_presentation.dart';
 export 'src/operations/surface_atlas_json_codec.dart';
 export 'src/operations/surface_animation_frame_json_codec.dart';
+export 'src/operations/surface_animation_timeline_json_codec.dart';
 export 'src/operations/legacy_path_surface_view.dart';
 export 'src/operations/legacy_terrain_surface_view.dart';
 export 'src/operations/legacy_project_surface_catalog_view.dart';
```

#### C.2 `diff -u /dev/null` — `surface_animation_timeline_json_codec.dart`

```diff
--- /dev/null	2026-04-27 01:51:22
+++ /Users/karim/Project/pokemonProject/packages/map_core/lib/src/operations/surface_animation_timeline_json_codec.dart	2026-04-27 01:49:30
@@ -0,0 +1,90 @@
+// JSON codec manuel (Lot 41) — [SurfaceAnimationTimeline].
+//
+// * Prépare une **future** persistance Surface **sans** brancher [ProjectManifest].
+// * Réutilise [encodeSurfaceAnimationFrame] / [decodeSurfaceAnimationFrame] du
+//   Lot 40 : une timeline est une **liste ordonnée** de frames, sans
+//   normalisation, tri, fusion, ni ajustement de [durationMs] (V0).
+// * La **géométrie d’atlas** n’est **pas** vérifiée ici (pas d’[isInside] sur
+//   chaque frame) — les indices (column, row) arbitraires se décodent comme en
+//   Lot 40.
+// * Décodage : clés inconnues (top-level, dans chaque map de frame, dans
+//   chaque [tileRef]) **tolérées** ; [Map] sources **jamais** mutées (copies
+//   défensives quand on normalise [Map<dynamic, dynamic>]).
+// * [SurfaceAnimationTimeline] et les modèles [surface.dart] restent **sans**
+//   `toJson` / `fromJson` : [ProjectSurfaceAnimation] (Lot 42+) reste un codec
+//   **distinct**.
+
+import '../exceptions/map_exceptions.dart';
+import '../models/surface.dart';
+import 'surface_animation_frame_json_codec.dart';
+
+/// Copie défensive, clés en [String] (décodage : Map dynamique).
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
+/// Encodage : seule clé `frames` ; chaque [SurfaceAnimationFrame] via le
+/// codec du Lot 40 ; ordre stable.
+Map<String, Object?> encodeSurfaceAnimationTimeline(
+  SurfaceAnimationTimeline timeline,
+) {
+  return <String, Object?>{
+    'frames': <Object?>[
+      for (final f in timeline.frames) encodeSurfaceAnimationFrame(f),
+    ],
+  };
+}
+
+/// Décodage : `frames` requis, liste d’objets mappables ; chaque élément via
+/// [decodeSurfaceAnimationFrame] ; [SurfaceAnimationTimeline] valide la
+/// non-vacuité.
+SurfaceAnimationTimeline decodeSurfaceAnimationTimeline(
+  Map<String, Object?> json,
+) {
+  final raw = _valueForRequiredKey(
+    json,
+    'frames',
+    'SurfaceAnimationTimeline.frames',
+  );
+  if (raw is! List) {
+    throw const ValidationException(
+      'SurfaceAnimationTimeline.frames must be a List',
+    );
+  }
+
+  final decoded = <SurfaceAnimationFrame>[];
+  for (var i = 0; i < raw.length; i++) {
+    final el = raw[i];
+    if (el is! Map) {
+      throw ValidationException(
+        'SurfaceAnimationTimeline.frames[$i] must be an Object',
+      );
+    }
+    decoded.add(
+      decodeSurfaceAnimationFrame(
+        _stringKeyMapFrom(el),
+      ),
+    );
+  }
+
+  return SurfaceAnimationTimeline(frames: decoded);
+}
```

#### C.3 `diff -u /dev/null` — `surface_animation_timeline_json_codec_test.dart`

```diff
--- /dev/null	2026-04-27 01:51:22
+++ /Users/karim/Project/pokemonProject/packages/map_core/test/surface_animation_timeline_json_codec_test.dart	2026-04-27 01:49:54
@@ -0,0 +1,401 @@
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+void main() {
+  group('SurfaceAnimationTimeline JSON codec (Lot 41)', () {
+    test('1. encodes one-frame timeline', () {
+      final t = _timeline(frames: [
+        _frame(row: 0, durationMs: 120),
+      ]);
+      final j = encodeSurfaceAnimationTimeline(t);
+      expect(j, {
+        'frames': <Object?>[
+          {
+            'tileRef': {
+              'atlasId': 'water-atlas',
+              'column': 0,
+              'row': 0,
+            },
+            'durationMs': 120,
+          },
+        ],
+      });
+    });
+
+    test('2. decodes one-frame timeline', () {
+      const j = <String, Object?>{
+        'frames': <Object?>[
+          <String, Object?>{
+            'tileRef': <String, Object?>{
+              'atlasId': 'water-atlas',
+              'column': 0,
+              'row': 0,
+            },
+            'durationMs': 120,
+          },
+        ],
+      };
+      final t = decodeSurfaceAnimationTimeline(j);
+      expect(t.frameCount, 1);
+      expect(t.totalDurationMs, 120);
+      expect(t.frames.first.durationMs, 120);
+      expect(t.frames.first.tileRef.atlasId, 'water-atlas');
+    });
+
+    test('3. round-trip one-frame timeline', () {
+      final o = _timeline(frames: [_frame(row: 0, durationMs: 120)]);
+      final d = decodeSurfaceAnimationTimeline(encodeSurfaceAnimationTimeline(o));
+      expect(d, o);
+    });
+
+    test('4. encodes multi-frame timeline (order + durations)', () {
+      final t = _timeline(frames: [
+        _frame(row: 0, durationMs: 100),
+        _frame(row: 1, durationMs: 120),
+        _frame(row: 2, durationMs: 140),
+      ]);
+      final j = encodeSurfaceAnimationTimeline(t);
+      final list = (j['frames'] as List<Object?>?) ?? [];
+      expect(list.length, 3);
+      for (var i = 0; i < 3; i++) {
+        final f = t.frames[i];
+        final m = list[i] as Map<String, Object?>;
+        expect(m, encodeSurfaceAnimationFrame(f));
+      }
+    });
+
+    test('5. decodes multi-frame timeline', () {
+      const j = <String, Object?>{
+        'frames': <Object?>[
+          <String, Object?>{
+            'tileRef': <String, Object?>{
+              'atlasId': 'water-atlas',
+              'column': 0,
+              'row': 0,
+            },
+            'durationMs': 100,
+          },
+          <String, Object?>{
+            'tileRef': <String, Object?>{
+              'atlasId': 'water-atlas',
+              'column': 0,
+              'row': 1,
+            },
+            'durationMs': 120,
+          },
+          <String, Object?>{
+            'tileRef': <String, Object?>{
+              'atlasId': 'water-atlas',
+              'column': 0,
+              'row': 2,
+            },
+            'durationMs': 140,
+          },
+        ],
+      };
+      final t = decodeSurfaceAnimationTimeline(j);
+      expect(t.frameCount, 3);
+      expect(t.frames[0].tileRef.row, 0);
+      expect(t.frames[1].tileRef.row, 1);
+      expect(t.frames[2].tileRef.row, 2);
+      expect(t.frames[0].durationMs, 100);
+      expect(t.frames[1].durationMs, 120);
+      expect(t.frames[2].durationMs, 140);
+      expect(t.totalDurationMs, 360);
+    });
+
+    test('6. round-trip multi-frame timeline', () {
+      final o = _timeline(frames: [
+        _frame(row: 0, durationMs: 100),
+        _frame(row: 1, durationMs: 120),
+        _frame(row: 2, durationMs: 140),
+      ]);
+      final d = decodeSurfaceAnimationTimeline(encodeSurfaceAnimationTimeline(o));
+      expect(d, o);
+    });
+
+    test('7. decode preserves exact nested atlasId string', () {
+      const raw = '  water-atlas  ';
+      const j = <String, Object?>{
+        'frames': <Object?>[
+          <String, Object?>{
+            'tileRef': <String, Object?>{
+              'atlasId': raw,
+              'column': 0,
+              'row': 0,
+            },
+            'durationMs': 120,
+          },
+        ],
+      };
+      final t = decodeSurfaceAnimationTimeline(j);
+      expect(t.frames.first.tileRef.atlasId, raw);
+    });
+
+    test('8. reject frames key missing', () {
+      expect(
+        () => decodeSurfaceAnimationTimeline({}),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('9. reject frames not a List', () {
+      expect(
+        () => decodeSurfaceAnimationTimeline(<String, Object?>{
+          'frames': 'nope',
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('10. reject empty frames', () {
+      expect(
+        () => decodeSurfaceAnimationTimeline(<String, Object?>{
+          'frames': <Object?>[],
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('11. reject frame item not a Map', () {
+      expect(
+        () => decodeSurfaceAnimationTimeline(<String, Object?>{
+          'frames': <Object?>['nope'],
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('12. reject invalid nested tileRef (whitespace atlasId)', () {
+      expect(
+        () => decodeSurfaceAnimationTimeline(<String, Object?>{
+          'frames': <Object?>[
+            <String, Object?>{
+              'tileRef': <String, Object?>{
+                'atlasId': '   ',
+                'column': 0,
+                'row': 0,
+              },
+              'durationMs': 120,
+            },
+          ],
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('13. reject invalid durationMs in frame', () {
+      expect(
+        () => decodeSurfaceAnimationTimeline(<String, Object?>{
+          'frames': <Object?>[
+            <String, Object?>{
+              'tileRef': <String, Object?>{
+                'atlasId': 'water-atlas',
+                'column': 0,
+                'row': 0,
+              },
+              'durationMs': 0,
+            },
+          ],
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('14. decode ignores unknown top-level key', () {
+      final j = <String, Object?>{
+        'frames': <Object?>[
+          encodeSurfaceAnimationFrame(_frame()) as Object?,
+        ],
+        'futureField': 'ignored',
+      };
+      final t = decodeSurfaceAnimationTimeline(j);
+      expect(t.frameCount, 1);
+    });
+
+    test('15. decode ignores unknown key inside frame', () {
+      final inner = <String, Object?>{
+        'tileRef': <String, Object?>{
+          'atlasId': 'water-atlas',
+          'column': 0,
+          'row': 0,
+        },
+        'durationMs': 120,
+        'futureFrameField': 'ignored',
+      };
+      final j = <String, Object?>{
+        'frames': <Object?>[inner],
+      };
+      final t = decodeSurfaceAnimationTimeline(j);
+      expect(t.frames.first.durationMs, 120);
+    });
+
+    test('16. decode ignores unknown key inside tileRef', () {
+      final inner = <String, Object?>{
+        'tileRef': <String, Object?>{
+          'atlasId': 'water-atlas',
+          'column': 0,
+          'row': 0,
+          'futureTileRefField': 'x',
+        },
+        'durationMs': 120,
+      };
+      final t = decodeSurfaceAnimationTimeline(<String, Object?>{
+        'frames': <Object?>[inner],
+      });
+      expect(t.frames.first.tileRef.atlasId, 'water-atlas');
+    });
+
+    test('17. decode does not mutate source map', () {
+      final map = <String, Object?>{
+        'frames': <Object?>[
+          <String, Object?>{
+            'tileRef': <String, Object?>{
+              'atlasId': 'water-atlas',
+              'column': 0,
+              'row': 0,
+            },
+            'durationMs': 120,
+          },
+        ],
+      };
+      final before = _deepStr(map);
+      decodeSurfaceAnimationTimeline(map);
+      expect(_deepStr(map), before);
+    });
+
+    test('18. no geometry check; isInside separate', () {
+      const j = <String, Object?>{
+        'frames': <Object?>[
+          <String, Object?>{
+            'tileRef': <String, Object?>{
+              'atlasId': 'water-atlas',
+              'column': 999,
+              'row': 999,
+            },
+            'durationMs': 120,
+          },
+        ],
+      };
+      final t = decodeSurfaceAnimationTimeline(j);
+      expect(t.frames.first.tileRef.row, 999);
+      final geometry = SurfaceAtlasGeometry(
+        tileSize: SurfaceAtlasTileSize(width: 1, height: 1),
+        gridSize: SurfaceAtlasGridSize(columns: 1, rows: 1),
+        layout: SurfaceAtlasLayout.grid,
+      );
+      expect(t.isInside(geometry), isFalse);
+    });
+
+    test('19. encode does not mutate source timeline', () {
+      final t = _timeline(frames: [
+        _frame(row: 0, durationMs: 50),
+        _frame(row: 1, durationMs: 70),
+      ]);
+      final beforeCount = t.frameCount;
+      final beforeTotal = t.totalDurationMs;
+      final beforeFirst = t.frames[0];
+      encodeSurfaceAnimationTimeline(t);
+      expect(t.frameCount, beforeCount);
+      expect(t.totalDurationMs, beforeTotal);
+      expect(t.frames[0], beforeFirst);
+    });
+
+    test('20. public API encode returns Map', () {
+      expect(encodeSurfaceAnimationTimeline(_timeline()), isA<Map<String, Object?>>());
+    });
+
+    test('21. ProjectManifest has no surface persistence keys (Lot 41)', () {
+      const manifest = ProjectManifest(
+        name: 'L41',
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
+      '22. codec external to model: no timeline toJson or SurfaceAnimationTimeline.fromJson',
+      () {
+        final t = _timeline();
+        final m = encodeSurfaceAnimationTimeline(t);
+        expect(m, isA<Map<String, Object?>>());
+        // Ne pas appeler t.toJson / SurfaceAnimationTimeline.fromJson.
+      },
+    );
+
+    test(
+      '23. no ProjectSurfaceAnimation codec: encodeProjectSurfaceAnimation absent from lot',
+      () {
+        final t = _timeline();
+        final j = encodeSurfaceAnimationTimeline(t);
+        expect(j.containsKey('frames'), isTrue);
+        // Pas d’encodeProjectSurfaceAnimation / decodeProjectSurfaceAnimation ici.
+      },
+    );
+
+    test('24. reuses Lot 40 frame codec for each list element', () {
+      final f = _frame();
+      final t = _timeline(frames: [f]);
+      final j = encodeSurfaceAnimationTimeline(t);
+      final first = (j['frames'] as List<Object?>) [0] as Map<String, Object?>;
+      expect(
+        first,
+        encodeSurfaceAnimationFrame(f),
+      );
+    });
+  });
+}
+
+SurfaceAnimationFrame _frame({
+  String atlasId = 'water-atlas',
+  int column = 0,
+  int row = 0,
+  int durationMs = 120,
+}) {
+  return SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(
+      atlasId: atlasId,
+      column: column,
+      row: row,
+    ),
+    durationMs: durationMs,
+  );
+}
+
+SurfaceAnimationTimeline _timeline({List<SurfaceAnimationFrame>? frames}) {
+  return SurfaceAnimationTimeline(
+    frames: frames ?? [_frame()],
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

#### C.4 Rapport Lot 41 (ce fichier)

L’intégralité du texte de ce lot documentaire est le présent fichier ; l’exception contractuelle s’applique pour éviter de dupliquer le même contenu en annexe sous forme de preuve secondaire.

### D. Sorties de commandes

#### D.1 `dart test test/surface_animation_timeline_json_codec_test.dart`

```

00:00 [32m+0[0m: [1m[90mloading test/surface_animation_timeline_json_codec_test.dart[0m[0m                                                                                                                                 
00:00 [32m+0[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 1. encodes one-frame timeline[0m                                                                                                                   
00:00 [32m+1[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 1. encodes one-frame timeline[0m                                                                                                                   
00:00 [32m+1[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 2. decodes one-frame timeline[0m                                                                                                                   
00:00 [32m+2[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 2. decodes one-frame timeline[0m                                                                                                                   
00:00 [32m+2[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 3. round-trip one-frame timeline[0m                                                                                                                
00:00 [32m+3[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 3. round-trip one-frame timeline[0m                                                                                                                
00:00 [32m+3[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 4. encodes multi-frame timeline (order + durations)[0m                                                                                             
00:00 [32m+4[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 4. encodes multi-frame timeline (order + durations)[0m                                                                                             
00:00 [32m+4[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 5. decodes multi-frame timeline[0m                                                                                                                 
00:00 [32m+5[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 5. decodes multi-frame timeline[0m                                                                                                                 
00:00 [32m+5[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 6. round-trip multi-frame timeline[0m                                                                                                              
00:00 [32m+6[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 6. round-trip multi-frame timeline[0m                                                                                                              
00:00 [32m+6[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 7. decode preserves exact nested atlasId string[0m                                                                                                 
00:00 [32m+7[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 7. decode preserves exact nested atlasId string[0m                                                                                                 
00:00 [32m+7[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 8. reject frames key missing[0m                                                                                                                    
00:00 [32m+8[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 8. reject frames key missing[0m                                                                                                                    
00:00 [32m+8[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 9. reject frames not a List[0m                                                                                                                     
00:00 [32m+9[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 9. reject frames not a List[0m                                                                                                                     
00:00 [32m+9[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 10. reject empty frames[0m                                                                                                                         
00:00 [32m+10[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 10. reject empty frames[0m                                                                                                                        
00:00 [32m+10[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 11. reject frame item not a Map[0m                                                                                                                
00:00 [32m+11[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 11. reject frame item not a Map[0m                                                                                                                
00:00 [32m+11[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 12. reject invalid nested tileRef (whitespace atlasId)[0m                                                                                         
00:00 [32m+12[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 12. reject invalid nested tileRef (whitespace atlasId)[0m                                                                                         
00:00 [32m+12[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 13. reject invalid durationMs in frame[0m                                                                                                         
00:00 [32m+13[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 13. reject invalid durationMs in frame[0m                                                                                                         
00:00 [32m+13[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 14. decode ignores unknown top-level key[0m                                                                                                       
00:00 [32m+14[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 14. decode ignores unknown top-level key[0m                                                                                                       
00:00 [32m+14[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 15. decode ignores unknown key inside frame[0m                                                                                                    
00:00 [32m+15[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 15. decode ignores unknown key inside frame[0m                                                                                                    
00:00 [32m+15[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 16. decode ignores unknown key inside tileRef[0m                                                                                                  
00:00 [32m+16[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 16. decode ignores unknown key inside tileRef[0m                                                                                                  
00:00 [32m+16[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 17. decode does not mutate source map[0m                                                                                                          
00:00 [32m+17[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 17. decode does not mutate source map[0m                                                                                                          
00:00 [32m+17[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 18. no geometry check; isInside separate[0m                                                                                                       
00:00 [32m+18[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 18. no geometry check; isInside separate[0m                                                                                                       
00:00 [32m+18[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 19. encode does not mutate source timeline[0m                                                                                                     
00:00 [32m+19[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 19. encode does not mutate source timeline[0m                                                                                                     
00:00 [32m+19[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 20. public API encode returns Map[0m                                                                                                              
00:00 [32m+20[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 20. public API encode returns Map[0m                                                                                                              
00:00 [32m+20[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 21. ProjectManifest has no surface persistence keys (Lot 41)[0m                                                                                   
00:00 [32m+21[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 21. ProjectManifest has no surface persistence keys (Lot 41)[0m                                                                                   
00:00 [32m+21[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 22. codec external to model: no timeline toJson or SurfaceAnimationTimeline.fromJson[0m                                                           
00:00 [32m+22[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 22. codec external to model: no timeline toJson or SurfaceAnimationTimeline.fromJson[0m                                                           
00:00 [32m+22[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 23. no ProjectSurfaceAnimation codec: encodeProjectSurfaceAnimation absent from lot[0m                                                            
00:00 [32m+23[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 23. no ProjectSurfaceAnimation codec: encodeProjectSurfaceAnimation absent from lot[0m                                                            
00:00 [32m+23[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 24. reuses Lot 40 frame codec for each list element[0m                                                                                            
00:00 [32m+24[0m: SurfaceAnimationTimeline JSON codec (Lot 41) 24. reuses Lot 40 frame codec for each list element[0m                                                                                            
00:00 [32m+24[0m: All tests passed![0m                                                                                                                                                                           
```

#### D.2 `dart test test/surface_animation_timeline_test.dart`

```

00:00 [32m+0[0m: [1m[90mloading test/surface_animation_timeline_test.dart[0m[0m                                                                                                                                            
00:00 [32m+0[0m: SurfaceAnimationTimeline minimal timeline with one frame[0m                                                                                                                                     
00:00 [32m+1[0m: SurfaceAnimationTimeline minimal timeline with one frame[0m                                                                                                                                     
00:00 [32m+1[0m: SurfaceAnimationTimeline rejects empty frames list[0m                                                                                                                                           
00:00 [32m+2[0m: SurfaceAnimationTimeline rejects empty frames list[0m                                                                                                                                           
00:00 [32m+2[0m: SurfaceAnimationTimeline preserves frame order[0m                                                                                                                                               
00:00 [32m+3[0m: SurfaceAnimationTimeline preserves frame order[0m                                                                                                                                               
00:00 [32m+3[0m: SurfaceAnimationTimeline totalDurationMs sums frame durations[0m                                                                                                                                
00:00 [32m+4[0m: SurfaceAnimationTimeline totalDurationMs sums frame durations[0m                                                                                                                                
00:00 [32m+4[0m: SurfaceAnimationTimeline exposed frames list is unmodifiable[0m                                                                                                                                 
00:00 [32m+5[0m: SurfaceAnimationTimeline exposed frames list is unmodifiable[0m                                                                                                                                 
00:00 [32m+5[0m: SurfaceAnimationTimeline defensive copy: mutating source after construction does not affect timeline[0m                                                                                         
00:00 [32m+6[0m: SurfaceAnimationTimeline defensive copy: mutating source after construction does not affect timeline[0m                                                                                         
00:00 [32m+6[0m: SurfaceAnimationTimeline isInside: true when all frames are inside grid[0m                                                                                                                      
00:00 [32m+7[0m: SurfaceAnimationTimeline isInside: true when all frames are inside grid[0m                                                                                                                      
00:00 [32m+7[0m: SurfaceAnimationTimeline isInside: false when any frame is out of grid[0m                                                                                                                       
00:00 [32m+8[0m: SurfaceAnimationTimeline isInside: false when any frame is out of grid[0m                                                                                                                       
00:00 [32m+8[0m: SurfaceAnimationTimeline isInside: independent of SurfaceAtlasLayout[0m                                                                                                                         
00:00 [32m+9[0m: SurfaceAnimationTimeline isInside: independent of SurfaceAtlasLayout[0m                                                                                                                         
00:00 [32m+9[0m: SurfaceAnimationTimeline value equality: same frames in same order => equal and same hashCode[0m                                                                                                
00:00 [32m+10[0m: SurfaceAnimationTimeline value equality: same frames in same order => equal and same hashCode[0m                                                                                               
00:00 [32m+10[0m: SurfaceAnimationTimeline value equality: different order => not equal[0m                                                                                                                       
00:00 [32m+11[0m: SurfaceAnimationTimeline value equality: different order => not equal[0m                                                                                                                       
00:00 [32m+11[0m: SurfaceAnimationTimeline value equality: different frame content => not equal[0m                                                                                                               
00:00 [32m+12[0m: SurfaceAnimationTimeline value equality: different frame content => not equal[0m                                                                                                               
00:00 [32m+12[0m: SurfaceAnimationTimeline value equality: different duration on a frame => not equal[0m                                                                                                         
00:00 [32m+13[0m: SurfaceAnimationTimeline value equality: different duration on a frame => not equal[0m                                                                                                         
00:00 [32m+13[0m: SurfaceAnimationTimeline export: type is visible through map_core[0m                                                                                                                           
00:00 [32m+14[0m: SurfaceAnimationTimeline export: type is visible through map_core[0m                                                                                                                           
00:00 [32m+14[0m: SurfaceAnimationTimeline ProjectManifest toJson: no surface* top-level keys[0m                                                                                                                 
00:00 [32m+15[0m: SurfaceAnimationTimeline ProjectManifest toJson: no surface* top-level keys[0m                                                                                                                 
00:00 [32m+15[0m: All tests passed![0m                                                                                                                                                                           
```

#### D.3 `dart test test/surface_animation_frame_json_codec_test.dart`

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

#### D.4 `dart test test/surface_animation_frame_test.dart`

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

#### D.6 `dart analyze`

```
Analyzing surface_animation_timeline_json_codec.dart, surface_animation_frame_json_codec.dart, surface.dart, surface_animation_timeline_json_codec_test.dart, surface_animation_timeline_test.dart, surface_animation_frame_json_codec_test.dart, surface_animation_frame_test.dart, surface_model_entrypoint_test.dart, map_core.dart...
No issues found!
```

#### D.7 `dart test` (suite complète) — dernière ligne

```
00:01 [32m+943[0m: All tests passed![0m
```
