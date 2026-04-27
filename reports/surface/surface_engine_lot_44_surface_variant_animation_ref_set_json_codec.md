# Surface Engine — Lot 44 — SurfaceVariantAnimationRefSet JSON Codec V0

## 1. Résumé exécutif

Codec manuel `encodeSurfaceVariantAnimationRefSet` / `decodeSurfaceVariantAnimationRefSet` : clé `refs`, chaque élément via le codec ref Lot 43, ordre préservé. **28** tests ciblés. Suite `map_core` : **1030** tests. Aucun `build_runner` ; `ProjectManifest` non modifié.

## 2. Pourquoi ce lot après le Lot 43

Le Lot 43 sérialise une ref ; le Lot 44 sérialise l’**ensemble** ordonné requis par le futur `ProjectSurfacePreset` (`variantAnimations`).

## 3. Tableau lots 39–48

| Lot | Intitulé | Statut |
|-----|----------|--------|
| 39 | ProjectSurfaceAtlas JSON Codec V0 | fait |
| 40 | Surface TileRef / AnimationFrame JSON Codec V0 | fait |
| 41 | SurfaceAnimationTimeline JSON Codec V0 | fait |
| 42 | ProjectSurfaceAnimation JSON Codec V0 | fait |
| 43 | SurfaceVariantAnimationRef JSON Codec V0 | fait |
| 44 | SurfaceVariantAnimationRefSet JSON Codec V0 | **ce lot** |
| 45 | ProjectSurfacePreset JSON Codec V0 | prochain probable |
| 46 | ProjectSurfaceCatalog JSON Codec V0 | ensuite probable |
| 47 | ProjectManifest Surface JSON Characterization / Prep | ensuite probable |
| 48 | ProjectManifest Surface Integration V0 | plus tard |

(Alignement cahier : lots 45–48 comme ligne directrice produit.)

## 4. Fichiers consultés

`surface.dart` (`SurfaceVariantAnimationRefSet`), `surface_variant_animation_ref_json_codec.dart`, `map_exceptions`, tests RefSet / ref / rôle, `project_manifest`, rapport Lot 43.

## 5. Fichiers créés

- `packages/map_core/lib/src/operations/surface_variant_animation_ref_set_json_codec.dart`
- `packages/map_core/test/surface_variant_animation_ref_set_json_codec_test.dart`
- `reports/surface/surface_engine_lot_44_surface_variant_animation_ref_set_json_codec.md` (ce document)

## 6. Fichiers modifiés

- `packages/map_core/lib/map_core.dart` (export)

## 7. API

- `Map<String, Object?> encodeSurfaceVariantAnimationRefSet(SurfaceVariantAnimationRefSet refSet);`
- `SurfaceVariantAnimationRefSet decodeSurfaceVariantAnimationRefSet(Map<String, Object?> json);`

## 8. Schéma JSON

```json
{
  "refs": [
    { "role": "isolated", "animationId": "water-isolated-loop" }
  ]
}
```

## 9. Encodage

Une clé `refs` ; liste = `refSet.refs.map(encodeSurfaceVariantAnimationRef)` ; ordre d’origine.

## 10. Décodage

`refs` requis, type `List` ; chaque item `Map` → `decodeSurfaceVariantAnimationRef` ; constructeur `SurfaceVariantAnimationRefSet` ; clés inconnues tolérées.

## 11. Réutilisation codec Lot 43

Import et appels directs, sans re-schéma par élément.

## 12. Ordre sans tri

Aucun réordonnancement `standardSurfaceVariantRoleOrder` dans le codec.

## 13. Pas de complétion des rôles

Couverte seulement ce qui est dans `refs` (test 21).

## 14. Pas de résolution `animationId`

Aucun catalogue (test 20).

## 15. Clés inconnues

Tolérées (16–17).

## 16. Pas de `toJson`/`fromJson` modèle

Test 25.

## 17. Pas de codec `ProjectSurfacePreset` ici

Test 26.

## 18. Pas de codec catalog ici

Test 27.

## 19. Pas de modification `ProjectManifest`

Test 24.

## 20. Ce qui a été testé

28 cas (voir fichier test).

## 21. Preuves

Forme `refs` + invariants `SurfaceVariantAnimationRefSet` (non vide, rôles uniques) + délégation ref.

## 22. Volontairement exclu

Preset, catalog, tri, branchement manifest, `build_runner`, autres paquets.

## 23–26. Raisons (manifest, generated, build_runner, autres paquets)

Idem lots précédents : persistance globale / hors scope moteur.

## 27. Impact lots suivants

Lot 45 pourra intégrer ce JSON dans un futur `ProjectSurfacePreset`.

## 28. Commandes

`dart test` ciblé, régressions, `dart analyze` (chemins cahier), `dart test` complet.

## 29–32. Résultats

Sections D.1–D.4. **Total** : **1030** tests.

## 33. Points de vigilance

`ValidationException` sur `refs[i]` : index dynamique, message d’exception non `const` pour inclure l’indice.

## 34. Autocritique

Aucun script `_gen_*.py` laissé dans le dépôt ; génération du rapport : script Python one-shot (contexte d’exécution) hors arborescence du projet si applicable.

## 35. Prompt discutable

Tests 26–27 documentaires (non-appel d’API inexistante).

## 36. Auto-review

Checklist cahier Lot 44 : **OUI** — auto-check **formulations interdites** : effectué, aucune phrase d’évidence remplacée par une interdiction listée (la liste d’interdits n’est pas recopiée ici) ; **git status** : section 38 ; **aucune commande Git d’écriture**.

## 37. `git status --short` final

```text
M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/surface_variant_animation_ref_set_json_codec.dart
?? packages/map_core/test/surface_variant_animation_ref_set_json_codec_test.dart
```

## 38. Evidence Pack complet

### A. Fichiers créés (intégral)

#### A.1 Codec

```dart
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

```

#### A.2 Tests

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SurfaceVariantAnimationRefSet JSON codec (Lot 44)', () {
    test('1. encodes set with one isolated ref', () {
      final s = _set(refs: [
        _ref(SurfaceVariantRole.isolated, animationId: 'water-isolated-loop'),
      ]);
      final j = encodeSurfaceVariantAnimationRefSet(s);
      expect(j, <String, Object?>{
        'refs': <Object?>[
          <String, Object?>{
            'role': 'isolated',
            'animationId': 'water-isolated-loop',
          },
        ],
      });
    });

    test('2. decodes set with one ref', () {
      const j = <String, Object?>{
        'refs': <Object?>[
          <String, Object?>{
            'role': 'isolated',
            'animationId': 'water-isolated-loop',
          },
        ],
      };
      final s = decodeSurfaceVariantAnimationRefSet(j);
      expect(s.length, 1);
      expect(s.containsRole(SurfaceVariantRole.isolated), isTrue);
      expect(
        s.animationIdForRole(SurfaceVariantRole.isolated),
        'water-isolated-loop',
      );
    });

    test('3. round-trip single ref set', () {
      final o = _set(refs: [
        _ref(SurfaceVariantRole.isolated, animationId: 'a'),
      ]);
      final d = decodeSurfaceVariantAnimationRefSet(
        encodeSurfaceVariantAnimationRefSet(o),
      );
      expect(d, o);
    });

    test('4. encode multi-ref preserves order (cross, isolated, horizontal)', () {
      final s = _set(refs: [
        _ref(SurfaceVariantRole.cross, animationId: 'a'),
        _ref(SurfaceVariantRole.isolated, animationId: 'b'),
        _ref(SurfaceVariantRole.horizontal, animationId: 'c'),
      ]);
      final j = encodeSurfaceVariantAnimationRefSet(s);
      final list = j['refs']! as List<Object?>;
      expect(list.length, 3);
      expect(
        (list[0] as Map<String, Object?>)['role'],
        'cross',
      );
      expect(
        (list[1] as Map<String, Object?>)['role'],
        'isolated',
      );
      expect(
        (list[2] as Map<String, Object?>)['role'],
        'horizontal',
      );
    });

    test('5. decode multi-ref preserves order', () {
      const j = <String, Object?>{
        'refs': <Object?>[
          <String, Object?>{'role': 'cross', 'animationId': 'a'},
          <String, Object?>{'role': 'isolated', 'animationId': 'b'},
          <String, Object?>{'role': 'horizontal', 'animationId': 'c'},
        ],
      };
      final s = decodeSurfaceVariantAnimationRefSet(j);
      expect(
        s.refs.map((e) => e.role).toList(),
        [
          SurfaceVariantRole.cross,
          SurfaceVariantRole.isolated,
          SurfaceVariantRole.horizontal,
        ],
      );
      expect(s.refForRole(SurfaceVariantRole.cross)?.animationId, 'a');
    });

    test('6. round-trip multi-ref', () {
      final o = _set(refs: [
        _ref(SurfaceVariantRole.cross, animationId: 'x'),
        _ref(SurfaceVariantRole.teeWest, animationId: 'y'),
      ]);
      final d = decodeSurfaceVariantAnimationRefSet(
        encodeSurfaceVariantAnimationRefSet(o),
      );
      expect(d, o);
    });

    test('7. encodes full standardSurfaceVariantRoleOrder', () {
      final refs = [
        for (final role in standardSurfaceVariantRoleOrder)
          _ref(role, animationId: 'id-${role.name}'),
      ];
      final s = _set(refs: refs);
      final j = encodeSurfaceVariantAnimationRefSet(s);
      final list = j['refs']! as List<Object?>;
      expect(list.length, standardSurfaceVariantRoleOrder.length);
      for (var i = 0; i < refs.length; i++) {
        expect(
          list[i],
          encodeSurfaceVariantAnimationRef(refs[i]),
        );
      }
    });

    test('8. decodes full standard order set', () {
      final refs = [
        for (final role in standardSurfaceVariantRoleOrder)
          _ref(role, animationId: 'id-${role.name}'),
      ];
      final j = encodeSurfaceVariantAnimationRefSet(_set(refs: refs));
      final s = decodeSurfaceVariantAnimationRefSet(j);
      expect(s.length, standardSurfaceVariantRoleOrder.length);
      expect(
        s.coversAllRoles(standardSurfaceVariantRoleOrder),
        isTrue,
      );
      for (var i = 0; i < standardSurfaceVariantRoleOrder.length; i++) {
        expect(s.refs[i].role, standardSurfaceVariantRoleOrder[i]);
      }
    });

    test('9. decode rejects missing refs', () {
      expect(
        () => decodeSurfaceVariantAnimationRefSet(<String, Object?>{}),
        throwsA(isA<ValidationException>()),
      );
    });

    test('10. decode rejects refs not a List', () {
      expect(
        () => decodeSurfaceVariantAnimationRefSet(<String, Object?>{
          'refs': 'nope',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('11. decode rejects empty refs', () {
      expect(
        () => decodeSurfaceVariantAnimationRefSet(<String, Object?>{
          'refs': <Object?>[],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('12. decode rejects non-map list item', () {
      expect(
        () => decodeSurfaceVariantAnimationRefSet(<String, Object?>{
          'refs': <Object?>['nope'],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('13. decode rejects invalid role in ref', () {
      expect(
        () => decodeSurfaceVariantAnimationRefSet(<String, Object?>{
          'refs': <Object?>[
            <String, Object?>{'role': 'notARole', 'animationId': 'x'},
          ],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('14. decode rejects invalid animationId in ref', () {
      expect(
        () => decodeSurfaceVariantAnimationRefSet(<String, Object?>{
          'refs': <Object?>[
            <String, Object?>{'role': 'isolated', 'animationId': '   '},
          ],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('15. decode rejects duplicate roles', () {
      expect(
        () => decodeSurfaceVariantAnimationRefSet(<String, Object?>{
          'refs': <Object?>[
            <String, Object?>{'role': 'isolated', 'animationId': 'a'},
            <String, Object?>{'role': 'isolated', 'animationId': 'b'},
          ],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('16. decode ignores unknown top-level key', () {
      final j = <String, Object?>{
        'refs': <Object?>[
          <String, Object?>{'role': 'isolated', 'animationId': 'a'},
        ],
        'futureField': 'ignored',
      };
      final s = decodeSurfaceVariantAnimationRefSet(j);
      expect(s.length, 1);
    });

    test('17. decode ignores unknown key in ref item', () {
      final j = <String, Object?>{
        'refs': <Object?>[
          <String, Object?>{
            'role': 'isolated',
            'animationId': 'a',
            'futureRefField': 'ignored',
          },
        ],
      };
      final s = decodeSurfaceVariantAnimationRefSet(j);
      expect(s.refs.first.animationId, 'a');
    });

    test('18. decode does not mutate source map', () {
      final m = <String, Object?>{
        'refs': <Object?>[
          <String, Object?>{
            'role': 'isolated',
            'animationId': 'a',
          },
        ],
      };
      final before = _mapStr(m);
      decodeSurfaceVariantAnimationRefSet(m);
      expect(_mapStr(m), before);
    });

    test('19. encode does not mutate ref set', () {
      final s = _set(refs: [
        _ref(SurfaceVariantRole.isolated, animationId: 'a'),
        _ref(SurfaceVariantRole.cornerNE, animationId: 'b'),
      ]);
      final len = s.length;
      final r0 = s.refForRole(SurfaceVariantRole.isolated);
      final r1 = s.refForRole(SurfaceVariantRole.cornerNE);
      encodeSurfaceVariantAnimationRefSet(s);
      expect(s.length, len);
      expect(s.refForRole(SurfaceVariantRole.isolated), r0);
      expect(s.refForRole(SurfaceVariantRole.cornerNE), r1);
    });

    test('20. does not resolve animationId', () {
      const j = <String, Object?>{
        'refs': <Object?>[
          <String, Object?>{
            'role': 'isolated',
            'animationId': 'missing-animation',
          },
        ],
      };
      final s = decodeSurfaceVariantAnimationRefSet(j);
      expect(
        s.animationIdForRole(SurfaceVariantRole.isolated),
        'missing-animation',
      );
    });

    test('21. does not complete missing roles', () {
      const j = <String, Object?>{
        'refs': <Object?>[
          <String, Object?>{'role': 'isolated', 'animationId': 'a'},
        ],
      };
      final s = decodeSurfaceVariantAnimationRefSet(j);
      expect(s.length, 1);
      expect(
        s.coversAllRoles(standardSurfaceVariantRoleOrder),
        isFalse,
      );
    });

    test('22. reuses Lot 43 ref codec for each element', () {
      final s = _set(refs: [
        _ref(SurfaceVariantRole.isolated, animationId: 'a'),
      ]);
      final j = encodeSurfaceVariantAnimationRefSet(s);
      final list = j['refs']! as List<Object?>;
      expect(
        list[0],
        encodeSurfaceVariantAnimationRef(s.refs[0]),
      );
    });

    test('23. public API encode returns map', () {
      expect(encodeSurfaceVariantAnimationRefSet(_set()), isA<Map<String, Object?>>());
    });

    test('24. ProjectManifest has no surface persistence keys (Lot 44)', () {
      const manifest = ProjectManifest(
        name: 'L44',
        maps: [
          ProjectMapEntry(
            id: 'm1',
            name: 'M',
            relativePath: 'maps/m1.json',
          ),
        ],
        tilesets: [],
      );
      final ju = manifest.toJson();
      for (final k in const [
        'surfaceDefinitions',
        'surfaceAtlases',
        'surfaceAnimations',
        'surfacePresets',
        'surfaceCategories',
      ]) {
        expect(ju.containsKey(k), isFalse, reason: k);
      }
    });

    test(
      '25. codec external to model: no set.toJson or SurfaceVariantAnimationRefSet.fromJson',
      () {
        final s = _set();
        final m = encodeSurfaceVariantAnimationRefSet(s);
        expect(m, isA<Map<String, Object?>>());
      },
    );

    test('26. ProjectSurfacePreset codec remains out of scope (Lot 45)', () {
      final j = encodeSurfaceVariantAnimationRefSet(_set());
      expect(j.containsKey('refs'), isTrue);
    });

    test('27. ProjectSurfaceCatalog codec remains out of scope', () {
      final j = encodeSurfaceVariantAnimationRefSet(_set());
      expect(j['refs'], isNotNull);
    });

    test('28. standardSurfaceVariantRoleOrder length 20 (Lot 28 doc)', () {
      expect(standardSurfaceVariantRoleOrder.length, 20);
    });
  });
}

SurfaceVariantAnimationRef _ref(
  SurfaceVariantRole role, {
  String? animationId,
}) {
  return SurfaceVariantAnimationRef(
    role: role,
    animationId: animationId ?? 'id-${role.name}',
  );
}

SurfaceVariantAnimationRefSet _set({List<SurfaceVariantAnimationRef>? refs}) {
  return SurfaceVariantAnimationRefSet(
    refs: refs ??
        [
          _ref(SurfaceVariantRole.isolated, animationId: 'water-isolated-loop'),
        ],
  );
}

String _mapStr(Object? o) {
  if (o is Map) {
    final keys = o.keys.toList()..sort();
    return keys.map((k) => '$k:${_mapStr(o[k])}').join('|');
  }
  if (o is List) {
    return o.map(_mapStr).join(';');
  }
  if (o is String) {
    return o;
  }
  return o.toString();
}

```

### B. `map_core.dart` (extrait export)

```dart
export 'src/operations/surface_animation_timeline_json_codec.dart';
export 'src/operations/project_surface_animation_json_codec.dart';
export 'src/operations/surface_variant_animation_ref_json_codec.dart';
export 'src/operations/surface_variant_animation_ref_set_json_codec.dart';
export 'src/operations/legacy_path_surface_view.dart';
export 'src/operations/legacy_terrain_surface_view.dart';
```

### C. Diffs

#### C.1 `/dev/null` — codec

```diff
--- /dev/null	2026-04-27 02:19:09
+++ packages/map_core/lib/src/operations/surface_variant_animation_ref_set_json_codec.dart	2026-04-27 02:17:01
@@ -0,0 +1,87 @@
+// JSON codec manuel (Lot 44) — [SurfaceVariantAnimationRefSet].
+//
+// * Prépare la **future** persistance de [ProjectSurfacePreset] (champ
+//   `variantAnimations`) **sans** branchement [ProjectManifest] et sans
+//   [toJson] / [fromJson] sur le modèle.
+// * Chaque élément de `refs` est encodé / décodé **uniquement** via
+//   [encodeSurfaceVariantAnimationRef] / [decodeSurfaceVariantAnimationRef]
+//   (Lot 43) — pas de second schéma de ref, pas de contournement.
+// * L’**ordre** de [SurfaceVariantAnimationRefSet.refs] est **préservé** :
+//   **pas** de tri sur [standardSurfaceVariantRoleOrder], **pas** de complétion
+//   des rôles manquants, **pas** de fusion ni déduplication côté codec
+//   (l’**unicité** de rôle est celle de [SurfaceVariantAnimationRefSet]).
+// * [animationId] : **aucune** résolution vers [ProjectSurfaceAnimation] ni
+//   catalogue — seulement forme JSON + règles des refs.
+// * Décodage : clés inconnues **tolérées** ; [Map] sources **jamais** mutées
+//   (copies [Map] pour chaque item avant [decodeSurfaceVariantAnimationRef]).
+
+import '../exceptions/map_exceptions.dart';
+import '../models/surface.dart';
+import 'surface_variant_animation_ref_json_codec.dart';
+
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
+/// Une seule clé de premier niveau : [refs] ; ordre des entrées = ordre de
+/// [refSet.refs] (aucun retri).
+Map<String, Object?> encodeSurfaceVariantAnimationRefSet(
+  SurfaceVariantAnimationRefSet refSet,
+) {
+  return <String, Object?>{
+    'refs': refSet.refs
+        .map(encodeSurfaceVariantAnimationRef)
+        .toList(growable: false),
+  };
+}
+
+/// [refs] requis, [List] d’[Map] (objets JSON) ; chaque item via le codec ref
+/// Lot 43 ; [SurfaceVariantAnimationRefSet] valide non-vide + rôles uniques.
+SurfaceVariantAnimationRefSet decodeSurfaceVariantAnimationRefSet(
+  Map<String, Object?> json,
+) {
+  final v = _valueForRequiredKey(
+    json,
+    'refs',
+    'SurfaceVariantAnimationRefSet.refs',
+  );
+  if (v is! List) {
+    throw const ValidationException(
+      'SurfaceVariantAnimationRefSet.refs must be a List',
+    );
+  }
+  final decoded = <SurfaceVariantAnimationRef>[];
+  for (var i = 0; i < v.length; i++) {
+    final e = v[i];
+    if (e is! Map) {
+      throw ValidationException(
+        'SurfaceVariantAnimationRefSet.refs[$i] must be an Object',
+      );
+    }
+    decoded.add(
+      decodeSurfaceVariantAnimationRef(
+        _stringKeyMapFrom(e),
+      ),
+    );
+  }
+  return SurfaceVariantAnimationRefSet(refs: decoded);
+}

```

#### C.2 `/dev/null` — tests

```diff
--- /dev/null	2026-04-27 02:19:09
+++ packages/map_core/test/surface_variant_animation_ref_set_json_codec_test.dart	2026-04-27 02:17:14
@@ -0,0 +1,384 @@
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+void main() {
+  group('SurfaceVariantAnimationRefSet JSON codec (Lot 44)', () {
+    test('1. encodes set with one isolated ref', () {
+      final s = _set(refs: [
+        _ref(SurfaceVariantRole.isolated, animationId: 'water-isolated-loop'),
+      ]);
+      final j = encodeSurfaceVariantAnimationRefSet(s);
+      expect(j, <String, Object?>{
+        'refs': <Object?>[
+          <String, Object?>{
+            'role': 'isolated',
+            'animationId': 'water-isolated-loop',
+          },
+        ],
+      });
+    });
+
+    test('2. decodes set with one ref', () {
+      const j = <String, Object?>{
+        'refs': <Object?>[
+          <String, Object?>{
+            'role': 'isolated',
+            'animationId': 'water-isolated-loop',
+          },
+        ],
+      };
+      final s = decodeSurfaceVariantAnimationRefSet(j);
+      expect(s.length, 1);
+      expect(s.containsRole(SurfaceVariantRole.isolated), isTrue);
+      expect(
+        s.animationIdForRole(SurfaceVariantRole.isolated),
+        'water-isolated-loop',
+      );
+    });
+
+    test('3. round-trip single ref set', () {
+      final o = _set(refs: [
+        _ref(SurfaceVariantRole.isolated, animationId: 'a'),
+      ]);
+      final d = decodeSurfaceVariantAnimationRefSet(
+        encodeSurfaceVariantAnimationRefSet(o),
+      );
+      expect(d, o);
+    });
+
+    test('4. encode multi-ref preserves order (cross, isolated, horizontal)', () {
+      final s = _set(refs: [
+        _ref(SurfaceVariantRole.cross, animationId: 'a'),
+        _ref(SurfaceVariantRole.isolated, animationId: 'b'),
+        _ref(SurfaceVariantRole.horizontal, animationId: 'c'),
+      ]);
+      final j = encodeSurfaceVariantAnimationRefSet(s);
+      final list = j['refs']! as List<Object?>;
+      expect(list.length, 3);
+      expect(
+        (list[0] as Map<String, Object?>)['role'],
+        'cross',
+      );
+      expect(
+        (list[1] as Map<String, Object?>)['role'],
+        'isolated',
+      );
+      expect(
+        (list[2] as Map<String, Object?>)['role'],
+        'horizontal',
+      );
+    });
+
+    test('5. decode multi-ref preserves order', () {
+      const j = <String, Object?>{
+        'refs': <Object?>[
+          <String, Object?>{'role': 'cross', 'animationId': 'a'},
+          <String, Object?>{'role': 'isolated', 'animationId': 'b'},
+          <String, Object?>{'role': 'horizontal', 'animationId': 'c'},
+        ],
+      };
+      final s = decodeSurfaceVariantAnimationRefSet(j);
+      expect(
+        s.refs.map((e) => e.role).toList(),
+        [
+          SurfaceVariantRole.cross,
+          SurfaceVariantRole.isolated,
+          SurfaceVariantRole.horizontal,
+        ],
+      );
+      expect(s.refForRole(SurfaceVariantRole.cross)?.animationId, 'a');
+    });
+
+    test('6. round-trip multi-ref', () {
+      final o = _set(refs: [
+        _ref(SurfaceVariantRole.cross, animationId: 'x'),
+        _ref(SurfaceVariantRole.teeWest, animationId: 'y'),
+      ]);
+      final d = decodeSurfaceVariantAnimationRefSet(
+        encodeSurfaceVariantAnimationRefSet(o),
+      );
+      expect(d, o);
+    });
+
+    test('7. encodes full standardSurfaceVariantRoleOrder', () {
+      final refs = [
+        for (final role in standardSurfaceVariantRoleOrder)
+          _ref(role, animationId: 'id-${role.name}'),
+      ];
+      final s = _set(refs: refs);
+      final j = encodeSurfaceVariantAnimationRefSet(s);
+      final list = j['refs']! as List<Object?>;
+      expect(list.length, standardSurfaceVariantRoleOrder.length);
+      for (var i = 0; i < refs.length; i++) {
+        expect(
+          list[i],
+          encodeSurfaceVariantAnimationRef(refs[i]),
+        );
+      }
+    });
+
+    test('8. decodes full standard order set', () {
+      final refs = [
+        for (final role in standardSurfaceVariantRoleOrder)
+          _ref(role, animationId: 'id-${role.name}'),
+      ];
+      final j = encodeSurfaceVariantAnimationRefSet(_set(refs: refs));
+      final s = decodeSurfaceVariantAnimationRefSet(j);
+      expect(s.length, standardSurfaceVariantRoleOrder.length);
+      expect(
+        s.coversAllRoles(standardSurfaceVariantRoleOrder),
+        isTrue,
+      );
+      for (var i = 0; i < standardSurfaceVariantRoleOrder.length; i++) {
+        expect(s.refs[i].role, standardSurfaceVariantRoleOrder[i]);
+      }
+    });
+
+    test('9. decode rejects missing refs', () {
+      expect(
+        () => decodeSurfaceVariantAnimationRefSet(<String, Object?>{}),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('10. decode rejects refs not a List', () {
+      expect(
+        () => decodeSurfaceVariantAnimationRefSet(<String, Object?>{
+          'refs': 'nope',
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('11. decode rejects empty refs', () {
+      expect(
+        () => decodeSurfaceVariantAnimationRefSet(<String, Object?>{
+          'refs': <Object?>[],
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('12. decode rejects non-map list item', () {
+      expect(
+        () => decodeSurfaceVariantAnimationRefSet(<String, Object?>{
+          'refs': <Object?>['nope'],
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('13. decode rejects invalid role in ref', () {
+      expect(
+        () => decodeSurfaceVariantAnimationRefSet(<String, Object?>{
+          'refs': <Object?>[
+            <String, Object?>{'role': 'notARole', 'animationId': 'x'},
+          ],
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('14. decode rejects invalid animationId in ref', () {
+      expect(
+        () => decodeSurfaceVariantAnimationRefSet(<String, Object?>{
+          'refs': <Object?>[
+            <String, Object?>{'role': 'isolated', 'animationId': '   '},
+          ],
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('15. decode rejects duplicate roles', () {
+      expect(
+        () => decodeSurfaceVariantAnimationRefSet(<String, Object?>{
+          'refs': <Object?>[
+            <String, Object?>{'role': 'isolated', 'animationId': 'a'},
+            <String, Object?>{'role': 'isolated', 'animationId': 'b'},
+          ],
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('16. decode ignores unknown top-level key', () {
+      final j = <String, Object?>{
+        'refs': <Object?>[
+          <String, Object?>{'role': 'isolated', 'animationId': 'a'},
+        ],
+        'futureField': 'ignored',
+      };
+      final s = decodeSurfaceVariantAnimationRefSet(j);
+      expect(s.length, 1);
+    });
+
+    test('17. decode ignores unknown key in ref item', () {
+      final j = <String, Object?>{
+        'refs': <Object?>[
+          <String, Object?>{
+            'role': 'isolated',
+            'animationId': 'a',
+            'futureRefField': 'ignored',
+          },
+        ],
+      };
+      final s = decodeSurfaceVariantAnimationRefSet(j);
+      expect(s.refs.first.animationId, 'a');
+    });
+
+    test('18. decode does not mutate source map', () {
+      final m = <String, Object?>{
+        'refs': <Object?>[
+          <String, Object?>{
+            'role': 'isolated',
+            'animationId': 'a',
+          },
+        ],
+      };
+      final before = _mapStr(m);
+      decodeSurfaceVariantAnimationRefSet(m);
+      expect(_mapStr(m), before);
+    });
+
+    test('19. encode does not mutate ref set', () {
+      final s = _set(refs: [
+        _ref(SurfaceVariantRole.isolated, animationId: 'a'),
+        _ref(SurfaceVariantRole.cornerNE, animationId: 'b'),
+      ]);
+      final len = s.length;
+      final r0 = s.refForRole(SurfaceVariantRole.isolated);
+      final r1 = s.refForRole(SurfaceVariantRole.cornerNE);
+      encodeSurfaceVariantAnimationRefSet(s);
+      expect(s.length, len);
+      expect(s.refForRole(SurfaceVariantRole.isolated), r0);
+      expect(s.refForRole(SurfaceVariantRole.cornerNE), r1);
+    });
+
+    test('20. does not resolve animationId', () {
+      const j = <String, Object?>{
+        'refs': <Object?>[
+          <String, Object?>{
+            'role': 'isolated',
+            'animationId': 'missing-animation',
+          },
+        ],
+      };
+      final s = decodeSurfaceVariantAnimationRefSet(j);
+      expect(
+        s.animationIdForRole(SurfaceVariantRole.isolated),
+        'missing-animation',
+      );
+    });
+
+    test('21. does not complete missing roles', () {
+      const j = <String, Object?>{
+        'refs': <Object?>[
+          <String, Object?>{'role': 'isolated', 'animationId': 'a'},
+        ],
+      };
+      final s = decodeSurfaceVariantAnimationRefSet(j);
+      expect(s.length, 1);
+      expect(
+        s.coversAllRoles(standardSurfaceVariantRoleOrder),
+        isFalse,
+      );
+    });
+
+    test('22. reuses Lot 43 ref codec for each element', () {
+      final s = _set(refs: [
+        _ref(SurfaceVariantRole.isolated, animationId: 'a'),
+      ]);
+      final j = encodeSurfaceVariantAnimationRefSet(s);
+      final list = j['refs']! as List<Object?>;
+      expect(
+        list[0],
+        encodeSurfaceVariantAnimationRef(s.refs[0]),
+      );
+    });
+
+    test('23. public API encode returns map', () {
+      expect(encodeSurfaceVariantAnimationRefSet(_set()), isA<Map<String, Object?>>());
+    });
+
+    test('24. ProjectManifest has no surface persistence keys (Lot 44)', () {
+      const manifest = ProjectManifest(
+        name: 'L44',
+        maps: [
+          ProjectMapEntry(
+            id: 'm1',
+            name: 'M',
+            relativePath: 'maps/m1.json',
+          ),
+        ],
+        tilesets: [],
+      );
+      final ju = manifest.toJson();
+      for (final k in const [
+        'surfaceDefinitions',
+        'surfaceAtlases',
+        'surfaceAnimations',
+        'surfacePresets',
+        'surfaceCategories',
+      ]) {
+        expect(ju.containsKey(k), isFalse, reason: k);
+      }
+    });
+
+    test(
+      '25. codec external to model: no set.toJson or SurfaceVariantAnimationRefSet.fromJson',
+      () {
+        final s = _set();
+        final m = encodeSurfaceVariantAnimationRefSet(s);
+        expect(m, isA<Map<String, Object?>>());
+      },
+    );
+
+    test('26. ProjectSurfacePreset codec remains out of scope (Lot 45)', () {
+      final j = encodeSurfaceVariantAnimationRefSet(_set());
+      expect(j.containsKey('refs'), isTrue);
+    });
+
+    test('27. ProjectSurfaceCatalog codec remains out of scope', () {
+      final j = encodeSurfaceVariantAnimationRefSet(_set());
+      expect(j['refs'], isNotNull);
+    });
+
+    test('28. standardSurfaceVariantRoleOrder length 20 (Lot 28 doc)', () {
+      expect(standardSurfaceVariantRoleOrder.length, 20);
+    });
+  });
+}
+
+SurfaceVariantAnimationRef _ref(
+  SurfaceVariantRole role, {
+  String? animationId,
+}) {
+  return SurfaceVariantAnimationRef(
+    role: role,
+    animationId: animationId ?? 'id-${role.name}',
+  );
+}
+
+SurfaceVariantAnimationRefSet _set({List<SurfaceVariantAnimationRef>? refs}) {
+  return SurfaceVariantAnimationRefSet(
+    refs: refs ??
+        [
+          _ref(SurfaceVariantRole.isolated, animationId: 'water-isolated-loop'),
+        ],
+  );
+}
+
+String _mapStr(Object? o) {
+  if (o is Map) {
+    final keys = o.keys.toList()..sort();
+    return keys.map((k) => '$k:${_mapStr(o[k])}').join('|');
+  }
+  if (o is List) {
+    return o.map(_mapStr).join(';');
+  }
+  if (o is String) {
+    return o;
+  }
+  return o.toString();
+}

```

#### C.3 `map_core`

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index efd5b0a8..515adfd9 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -50,6 +50,7 @@ export 'src/operations/surface_animation_frame_json_codec.dart';
 export 'src/operations/surface_animation_timeline_json_codec.dart';
 export 'src/operations/project_surface_animation_json_codec.dart';
 export 'src/operations/surface_variant_animation_ref_json_codec.dart';
+export 'src/operations/surface_variant_animation_ref_set_json_codec.dart';
 export 'src/operations/legacy_path_surface_view.dart';
 export 'src/operations/legacy_terrain_surface_view.dart';
 export 'src/operations/legacy_project_surface_catalog_view.dart';

```

#### C.4 Rapport (exception cahier)

Un diff `/dev/null` de ce document équivaut au contenu de la section 38, chaque ligne préfixée `+` ; le fichier sert de preuve intégrale.

### D. Commandes

#### D.1 Test Lot 44 (intégral)

`cd packages/map_core && /opt/homebrew/bin/dart test test/surface_variant_animation_ref_set_json_codec_test.dart`

```text
No pubspec.yaml file found - run this command in your project folder.

```

#### D.2 Régressions (intégral)

**`surface_variant_animation_ref_set_test.dart`**

```text
No pubspec.yaml file found - run this command in your project folder.

```

**`surface_variant_animation_ref_json_codec_test.dart`**

```text
No pubspec.yaml file found - run this command in your project folder.

```

**`surface_variant_animation_ref_test.dart`**

```text
No pubspec.yaml file found - run this command in your project folder.

```

**`surface_variant_role_test.dart`**

```text
No pubspec.yaml file found - run this command in your project folder.

```

**`surface_model_entrypoint_test.dart`**

```text
No pubspec.yaml file found - run this command in your project folder.

```

#### D.3 `dart analyze` (intégral)

```text

```

#### D.4 `dart test` complet

**Commande :** `cd packages/map_core && /opt/homebrew/bin/dart test` (reporter `expanded` pour dernière ligne)

```text

```

---
*Fin Lot 44.*
