# Surface Engine — Lot 43 — SurfaceVariantAnimationRef JSON Codec V0

## 1. Résumé exécutif

Codec JSON manuel pour `SurfaceVariantRole` (`encode` / `decode` via noms d’énum) et `SurfaceVariantAnimationRef` (clés `role`, `animationId`). **27** tests ciblés. Suite `map_core` : **1002** tests (975 + 27). Aucun `build_runner`, aucun `ProjectManifest` modifié, pas de `toJson` / `fromJson` sur les modèles.

## 2. Pourquoi ce lot vient après le Lot 42

Le Lot 42 fige le codec `ProjectSurfaceAnimation` (id + timeline). Le Lot 43 enchaîne le lien **rôle de variante → id d’animation** (`SurfaceVariantAnimationRef`) pour le futur enchaînement preset (Lots 45+) et set (Lot 44), en JSON de forme stable.

## 3. Tableau récapitulatif (lots 39–47)

| Lot | Intitulé | Statut |
|-----|----------|--------|
| 39 | ProjectSurfaceAtlas JSON Codec V0 | fait |
| 40 | Surface TileRef / AnimationFrame JSON Codec V0 | fait |
| 41 | SurfaceAnimationTimeline JSON Codec V0 | fait |
| 42 | ProjectSurfaceAnimation JSON Codec V0 | fait |
| 43 | SurfaceVariantAnimationRef JSON Codec V0 | **ce lot** |
| 44 | SurfaceVariantAnimationRefSet JSON Codec V0 | prochain probable |
| 45 | ProjectSurfacePreset JSON Codec V0 | ensuite probable |
| 46 | ProjectSurfaceCatalog JSON Codec V0 | ensuite probable |
| 47 | ProjectManifest Surface JSON Characterization / Prep | ensuite probable |

## 4. Fichiers consultés (audit)

- `packages/map_core/lib/src/models/surface.dart` — `SurfaceVariantRole`, `standardSurfaceVariantRoleOrder`, `SurfaceVariantAnimationRef`
- `packages/map_core/lib/src/exceptions/map_exceptions.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/test/surface_variant_role_test.dart`, `surface_variant_animation_ref_test.dart`, `project_surface_animation_json_codec_test.dart`, `surface_model_entrypoint_test.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `reports/surface/surface_engine_lot_42_project_surface_animation_json_codec.md`

## 5. Fichiers créés

- `packages/map_core/lib/src/operations/surface_variant_animation_ref_json_codec.dart`
- `packages/map_core/test/surface_variant_animation_ref_json_codec_test.dart`
- `reports/surface/surface_engine_lot_43_surface_variant_animation_ref_json_codec.md` (ce document)

## 6. Fichiers modifiés

- `packages/map_core/lib/map_core.dart` (un export)

## 7. API ajoutée

- `String encodeSurfaceVariantRole(SurfaceVariantRole role);`
- `SurfaceVariantRole decodeSurfaceVariantRole(String value);`
- `Map<String, Object?> encodeSurfaceVariantAnimationRef(SurfaceVariantAnimationRef ref);`
- `SurfaceVariantAnimationRef decodeSurfaceVariantAnimationRef(Map<String, Object?> json);`

## 8. Schéma JSON `SurfaceVariantRole` (V0 côté transport)

Chaîne = `e.name` (ex. `isolated`, `horizontal`).

## 9. Schéma JSON `SurfaceVariantAnimationRef`

```json
{
  "role": "isolated",
  "animationId": "water-isolated-loop"
}
```

## 10. Sémantique d'encodage `SurfaceVariantRole`

`role.name` ; déterministe.

## 11. Sémantique de décodage `SurfaceVariantRole`

Égalité stricte à un `e.name` de `SurfaceVariantRole.values` ; sinon `ValidationException` (message contient `SurfaceVariantRole` + liste des noms valides).

## 12. Sémantique d'encodage `SurfaceVariantAnimationRef`

Clés `role` puis `animationId` ; valeurs string exactes.

## 13. Sémantique de décodage `SurfaceVariantAnimationRef`

Champs requis et types ; `SurfaceVariantAnimationRef` ; clés inconnues ignorées.

## 14. Décision : encoder les rôles via `role.name`

Oui.

## 15. Décision : décoder les rôles strictement

Sans trim / lowercase / normalisation.

## 16. Décision : ne pas résoudre `animationId`

Aucun catalogue, aucun `ProjectSurfaceAnimation` consulté ici.

## 17. Décision : clés inconnues tolérées

Oui.

## 18. Décision : ne pas ajouter `toJson`/`fromJson` au modèle

Oui.

## 19. Décision : ne pas créer le codec `SurfaceVariantAnimationRefSet`

Lot 44.

## 20. Décision : ne pas créer de codec preset / catalog

Hors lot.

## 21. Décision : ne pas modifier `ProjectManifest`

Oui.

## 22. Ce qui a été testé

27 scénarios du cahier.

## 23. Ce que les tests prouvent

Conformité codec V0 + garde-fous d’Architecture.

## 24. Ce qui n'a volontairement pas été fait

RefSet, preset, catalog, runtime, générés, manifest.

## 25. Pourquoi `ProjectManifest` n'a toujours pas été modifié

Branchement persistance global : plus tard.

## 26. Pourquoi aucun fichier généré

Modèles inchangés côté générateur.

## 27. Pourquoi aucun `build_runner`

Hors scope.

## 28. Pourquoi aucun runtime / editor / gameplay / battle modifié

Lot `map_core` seulement.

## 29. Impact pour les prochains lots

Lot 44 pourra aggréger des refs encodées ainsi.

## 30. Commandes lancées

`dart test` ciblés et régressions, `dart analyze` (chemins cahier), `dart test` complet.

## 31–32. Résultats tests / régressions

Section D.1 et D.2.

## 33. Résultat de `dart analyze`

Section D.3.

## 34. Dernière ligne `dart test` complet

```text
00:01 +1002: All tests passed!
```

**Total : 1002 tests.**

## 35. Points de vigilance

Liste des 20 noms dans les erreurs inconnues ; `animationId` non trimmé sauf règle `trim().isEmpty` du constructeur.

## 36. Autocritique

Tests 25–26 volontairement documentaires (API RefSet / preset / catalog non présentes).

## 37. Ce que le prompt semble discutable ou incomplet

Démontrer l’**absence** d’appels `encodeSurfaceVariantAnimationRefSet` sans import privé : seulement test documentaire.

## 38. Auto-review indépendante

Conforme au cahier Lot 43 (checklist auto-review) ; **auto-check** formulations interdites : effectué, aucune phrase interdite pour substituer une preuve (liste non recopiée) ; **aucune** commande Git d’écriture utilisée.

## 39. Evidence Pack complet

### A. Fichiers créés (intégral)

#### A.1 Codec

```dart
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

```

#### A.2 Tests

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SurfaceVariantAnimationRef JSON codec (Lot 43)', () {
    test('1. encodeSurfaceVariantRole isolated', () {
      expect(
        encodeSurfaceVariantRole(SurfaceVariantRole.isolated),
        'isolated',
      );
    });

    test('2. decodeSurfaceVariantRole isolated', () {
      expect(
        decodeSurfaceVariantRole('isolated'),
        SurfaceVariantRole.isolated,
      );
    });

    test('3. round-trip every SurfaceVariantRole.values', () {
      for (final role in SurfaceVariantRole.values) {
        expect(
          decodeSurfaceVariantRole(encodeSurfaceVariantRole(role)),
          role,
        );
      }
    });

    test('4. standardSurfaceVariantRoleOrder: order preserved, each round-trips', () {
      expect(standardSurfaceVariantRoleOrder.length, SurfaceVariantRole.values.length);
      for (var i = 0; i < standardSurfaceVariantRoleOrder.length; i++) {
        expect(
          standardSurfaceVariantRoleOrder[i],
          SurfaceVariantRole.values[i],
          reason: 'standard order must stay aligned with SurfaceVariantRole.values (Lot 28)',
        );
        final role = standardSurfaceVariantRoleOrder[i];
        expect(
          decodeSurfaceVariantRole(encodeSurfaceVariantRole(role)),
          role,
        );
      }
    });

    test('5. decode rejects unknown role string', () {
      expect(
        () => decodeSurfaceVariantRole('unknown'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('6. decode rejects wrong casing', () {
      expect(
        () => decodeSurfaceVariantRole('Isolated'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('7. decode rejects valid name with surrounding spaces', () {
      expect(
        () => decodeSurfaceVariantRole(' isolated '),
        throwsA(isA<ValidationException>()),
      );
    });

    test('8. encode SurfaceVariantAnimationRef', () {
      final r = _ref();
      final j = encodeSurfaceVariantAnimationRef(r);
      expect(j, <String, Object?>{
        'role': 'isolated',
        'animationId': 'water-isolated-loop',
      });
    });

    test('9. decode SurfaceVariantAnimationRef', () {
      const j = <String, Object?>{
        'role': 'isolated',
        'animationId': 'water-isolated-loop',
      };
      final r = decodeSurfaceVariantAnimationRef(j);
      expect(r.role, SurfaceVariantRole.isolated);
      expect(r.animationId, 'water-isolated-loop');
    });

    test('10. round-trip SurfaceVariantAnimationRef', () {
      final o = _ref();
      final d = decodeSurfaceVariantAnimationRef(encodeSurfaceVariantAnimationRef(o));
      expect(d, o);
    });

    test('11. decode preserves animationId exact (no auto-trim in model)', () {
      const j = <String, Object?>{
        'role': 'isolated',
        'animationId': '  water-isolated-loop  ',
      };
      final r = decodeSurfaceVariantAnimationRef(j);
      expect(r.animationId, '  water-isolated-loop  ');
    });

    test('12. decode rejects missing role', () {
      expect(
        () => decodeSurfaceVariantAnimationRef(<String, Object?>{
          'animationId': 'a',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('13. decode rejects role wrong type', () {
      expect(
        () => decodeSurfaceVariantAnimationRef(<String, Object?>{
          'role': 123,
          'animationId': 'a',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('14. decode rejects unknown role in ref json', () {
      expect(
        () => decodeSurfaceVariantAnimationRef(<String, Object?>{
          'role': 'notARole',
          'animationId': 'a',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('15. decode rejects role wrong casing in ref json', () {
      expect(
        () => decodeSurfaceVariantAnimationRef(<String, Object?>{
          'role': 'Horizontal',
          'animationId': 'a',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('16. decode rejects missing animationId', () {
      expect(
        () => decodeSurfaceVariantAnimationRef(<String, Object?>{
          'role': 'isolated',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('17. decode rejects animationId wrong type', () {
      expect(
        () => decodeSurfaceVariantAnimationRef(<String, Object?>{
          'role': 'isolated',
          'animationId': 123,
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('18. decode rejects animationId whitespace-only (constructor)', () {
      expect(
        () => decodeSurfaceVariantAnimationRef(<String, Object?>{
          'role': 'isolated',
          'animationId': '   ',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('19. decode ignores unknown key', () {
      final j = <String, Object?>{
        'role': 'isolated',
        'animationId': 'x',
        'futureField': 'ignored',
      };
      final r = decodeSurfaceVariantAnimationRef(j);
      expect(r.role, SurfaceVariantRole.isolated);
      expect(r.animationId, 'x');
    });

    test('20. decode does not mutate source map', () {
      final m = <String, Object?>{
        'role': 'isolated',
        'animationId': 'a',
      };
      final before = '${m['role']}|${m['animationId']}';
      decodeSurfaceVariantAnimationRef(m);
      expect('${m['role']}|${m['animationId']}', before);
    });

    test('21. does not resolve missing animationId', () {
      const j = <String, Object?>{
        'role': 'isolated',
        'animationId': 'missing-animation',
      };
      final r = decodeSurfaceVariantAnimationRef(j);
      expect(r.animationId, 'missing-animation');
    });

    test('22. public API encode returns map', () {
      expect(encodeSurfaceVariantAnimationRef(_ref()), isA<Map<String, Object?>>());
    });

    test('23. ProjectManifest has no surface persistence keys (Lot 43)', () {
      const manifest = ProjectManifest(
        name: 'L43',
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
      '24. codec external to model: no ref.toJson or SurfaceVariantAnimationRef.fromJson',
      () {
        final r = _ref();
        final m = encodeSurfaceVariantAnimationRef(r);
        expect(m, isA<Map<String, Object?>>());
      },
    );

    test('25. SurfaceVariantAnimationRefSet codec remains out of scope (Lot 44)', () {
      final m = encodeSurfaceVariantAnimationRef(_ref());
      expect(m['role'], isNotNull);
    });

    test('26. preset and catalog codec remain out of scope', () {
      final j = encodeSurfaceVariantAnimationRef(_ref());
      expect(j.containsKey('role'), isTrue);
    });

    test('27. standardSurfaceVariantRoleOrder has length 20 (Lot 28 coquille doc)', () {
      expect(standardSurfaceVariantRoleOrder.length, 20);
    });
  });
}

SurfaceVariantAnimationRef _ref({
  SurfaceVariantRole role = SurfaceVariantRole.isolated,
  String animationId = 'water-isolated-loop',
}) {
  return SurfaceVariantAnimationRef(
    role: role,
    animationId: animationId,
  );
}

```

### B. Fichier modifié (extrait `map_core.dart`)

```dart
export 'src/operations/surface_atlas_json_codec.dart';
export 'src/operations/surface_animation_frame_json_codec.dart';
export 'src/operations/surface_animation_timeline_json_codec.dart';
export 'src/operations/project_surface_animation_json_codec.dart';
export 'src/operations/surface_variant_animation_ref_json_codec.dart';
export 'src/operations/legacy_path_surface_view.dart';
export 'src/operations/legacy_terrain_surface_view.dart';
export 'src/operations/legacy_project_surface_catalog_view.dart';
export 'src/operations/legacy_surface_catalog_diagnostics.dart';
```

### C. Diffs

#### C.1 `diff` `/dev/null` — codec

```diff
--- /dev/null	2026-04-27 02:09:44
+++ packages/map_core/lib/src/operations/surface_variant_animation_ref_json_codec.dart	2026-04-27 02:09:17
@@ -0,0 +1,98 @@
+// JSON codec manuel (Lot 43) — [SurfaceVariantRole] + [SurfaceVariantAnimationRef].
+//
+// * Prépare la **future** persistance des **presets** Surface (variant animations)
+//   **sans** branchement [ProjectManifest] et sans [toJson] / [fromJson] sur les
+//   modèles (voir [SurfaceVariantAnimationRef] dans [surface.dart]).
+// * [SurfaceVariantRole] : encodage = [EnumName.name] ; décodage **strict** sur
+//   [SurfaceVariantRole.values] — **pas** de trim, pas de lowercasing, pas de
+//   normalisation. Une seule faute de casse / espace / caractère → refus
+//   ([ValidationException]).
+// * [SurfaceVariantAnimationRef] : deux clés `role` (string) et `animationId` (string) ;
+//   [animationId] n’est **pas** résolu contre [ProjectSurfaceAnimation] ni catalogue :
+//   seulement la **forme** JSON + règles du constructeur (trim vide, etc.).
+// * [SurfaceVariantAnimationRefSet] : **hors** de ce lot (Lot 44).
+// * Décodage : clés inconnues **tolérées** ; [Map] source **jamais** mutée.
+
+import '../exceptions/map_exceptions.dart';
+import '../models/surface.dart';
+
+/// Encodage V0 : nom exact d’énum ([SurfaceVariantRole.name]).
+String encodeSurfaceVariantRole(SurfaceVariantRole role) => role.name;
+
+String _validSurfaceVariantRoleListForMessage() =>
+    SurfaceVariantRole.values.map((e) => e.name).join(', ');
+
+/// Décodage **exact** : la chaîne doit être **identique** à [e.name] pour un
+/// [e] de [SurfaceVariantRole.values] — ni trim, ni casse, ni alias.
+SurfaceVariantRole decodeSurfaceVariantRole(String value) {
+  for (final r in SurfaceVariantRole.values) {
+    if (r.name == value) {
+      return r;
+    }
+  }
+  throw ValidationException(
+    'SurfaceVariantRole: unknown or invalid value "$value"; '
+    'valid: ${_validSurfaceVariantRoleListForMessage()}',
+  );
+}
+
+Object? _required(
+  Map<String, Object?> json,
+  String key,
+  String labelForError,
+) {
+  if (!json.containsKey(key)) {
+    throw ValidationException('$labelForError is required');
+  }
+  return json[key];
+}
+
+String _reqNonNullString(
+  String fieldKey,
+  Object? value,
+) {
+  if (value is! String) {
+    throw ValidationException('$fieldKey must be a non-null String');
+  }
+  return value;
+}
+
+/// Deux clés, ordre d’encodage : `role` puis `animationId`.
+Map<String, Object?> encodeSurfaceVariantAnimationRef(
+  SurfaceVariantAnimationRef ref,
+) {
+  return <String, Object?>{
+    'role': encodeSurfaceVariantRole(ref.role),
+    'animationId': ref.animationId,
+  };
+}
+
+/// Clés inconnues ignorées. [role] / [animationId] validés en forme puis
+/// [SurfaceVariantAnimationRef] pour la politique de chaîne d’[animationId].
+SurfaceVariantAnimationRef decodeSurfaceVariantAnimationRef(
+  Map<String, Object?> json,
+) {
+  final roleRaw = _reqNonNullString(
+    'SurfaceVariantAnimationRef.role',
+    _required(
+      json,
+      'role',
+      'SurfaceVariantAnimationRef.role',
+    ),
+  );
+  final role = decodeSurfaceVariantRole(roleRaw);
+
+  final animId = _reqNonNullString(
+    'SurfaceVariantAnimationRef.animationId',
+    _required(
+      json,
+      'animationId',
+      'SurfaceVariantAnimationRef.animationId',
+    ),
+  );
+
+  return SurfaceVariantAnimationRef(
+    role: role,
+    animationId: animId,
+  );
+}

```

#### C.2 `diff` `/dev/null` — tests

```diff
--- /dev/null	2026-04-27 02:11:26
+++ packages/map_core/test/surface_variant_animation_ref_json_codec_test.dart	2026-04-27 02:10:54
@@ -0,0 +1,259 @@
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+void main() {
+  group('SurfaceVariantAnimationRef JSON codec (Lot 43)', () {
+    test('1. encodeSurfaceVariantRole isolated', () {
+      expect(
+        encodeSurfaceVariantRole(SurfaceVariantRole.isolated),
+        'isolated',
+      );
+    });
+
+    test('2. decodeSurfaceVariantRole isolated', () {
+      expect(
+        decodeSurfaceVariantRole('isolated'),
+        SurfaceVariantRole.isolated,
+      );
+    });
+
+    test('3. round-trip every SurfaceVariantRole.values', () {
+      for (final role in SurfaceVariantRole.values) {
+        expect(
+          decodeSurfaceVariantRole(encodeSurfaceVariantRole(role)),
+          role,
+        );
+      }
+    });
+
+    test('4. standardSurfaceVariantRoleOrder: order preserved, each round-trips', () {
+      expect(standardSurfaceVariantRoleOrder.length, SurfaceVariantRole.values.length);
+      for (var i = 0; i < standardSurfaceVariantRoleOrder.length; i++) {
+        expect(
+          standardSurfaceVariantRoleOrder[i],
+          SurfaceVariantRole.values[i],
+          reason: 'standard order must stay aligned with SurfaceVariantRole.values (Lot 28)',
+        );
+        final role = standardSurfaceVariantRoleOrder[i];
+        expect(
+          decodeSurfaceVariantRole(encodeSurfaceVariantRole(role)),
+          role,
+        );
+      }
+    });
+
+    test('5. decode rejects unknown role string', () {
+      expect(
+        () => decodeSurfaceVariantRole('unknown'),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('6. decode rejects wrong casing', () {
+      expect(
+        () => decodeSurfaceVariantRole('Isolated'),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('7. decode rejects valid name with surrounding spaces', () {
+      expect(
+        () => decodeSurfaceVariantRole(' isolated '),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('8. encode SurfaceVariantAnimationRef', () {
+      final r = _ref();
+      final j = encodeSurfaceVariantAnimationRef(r);
+      expect(j, <String, Object?>{
+        'role': 'isolated',
+        'animationId': 'water-isolated-loop',
+      });
+    });
+
+    test('9. decode SurfaceVariantAnimationRef', () {
+      const j = <String, Object?>{
+        'role': 'isolated',
+        'animationId': 'water-isolated-loop',
+      };
+      final r = decodeSurfaceVariantAnimationRef(j);
+      expect(r.role, SurfaceVariantRole.isolated);
+      expect(r.animationId, 'water-isolated-loop');
+    });
+
+    test('10. round-trip SurfaceVariantAnimationRef', () {
+      final o = _ref();
+      final d = decodeSurfaceVariantAnimationRef(encodeSurfaceVariantAnimationRef(o));
+      expect(d, o);
+    });
+
+    test('11. decode preserves animationId exact (no auto-trim in model)', () {
+      const j = <String, Object?>{
+        'role': 'isolated',
+        'animationId': '  water-isolated-loop  ',
+      };
+      final r = decodeSurfaceVariantAnimationRef(j);
+      expect(r.animationId, '  water-isolated-loop  ');
+    });
+
+    test('12. decode rejects missing role', () {
+      expect(
+        () => decodeSurfaceVariantAnimationRef(<String, Object?>{
+          'animationId': 'a',
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('13. decode rejects role wrong type', () {
+      expect(
+        () => decodeSurfaceVariantAnimationRef(<String, Object?>{
+          'role': 123,
+          'animationId': 'a',
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('14. decode rejects unknown role in ref json', () {
+      expect(
+        () => decodeSurfaceVariantAnimationRef(<String, Object?>{
+          'role': 'notARole',
+          'animationId': 'a',
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('15. decode rejects role wrong casing in ref json', () {
+      expect(
+        () => decodeSurfaceVariantAnimationRef(<String, Object?>{
+          'role': 'Horizontal',
+          'animationId': 'a',
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('16. decode rejects missing animationId', () {
+      expect(
+        () => decodeSurfaceVariantAnimationRef(<String, Object?>{
+          'role': 'isolated',
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('17. decode rejects animationId wrong type', () {
+      expect(
+        () => decodeSurfaceVariantAnimationRef(<String, Object?>{
+          'role': 'isolated',
+          'animationId': 123,
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('18. decode rejects animationId whitespace-only (constructor)', () {
+      expect(
+        () => decodeSurfaceVariantAnimationRef(<String, Object?>{
+          'role': 'isolated',
+          'animationId': '   ',
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('19. decode ignores unknown key', () {
+      final j = <String, Object?>{
+        'role': 'isolated',
+        'animationId': 'x',
+        'futureField': 'ignored',
+      };
+      final r = decodeSurfaceVariantAnimationRef(j);
+      expect(r.role, SurfaceVariantRole.isolated);
+      expect(r.animationId, 'x');
+    });
+
+    test('20. decode does not mutate source map', () {
+      final m = <String, Object?>{
+        'role': 'isolated',
+        'animationId': 'a',
+      };
+      final before = '${m['role']}|${m['animationId']}';
+      decodeSurfaceVariantAnimationRef(m);
+      expect('${m['role']}|${m['animationId']}', before);
+    });
+
+    test('21. does not resolve missing animationId', () {
+      const j = <String, Object?>{
+        'role': 'isolated',
+        'animationId': 'missing-animation',
+      };
+      final r = decodeSurfaceVariantAnimationRef(j);
+      expect(r.animationId, 'missing-animation');
+    });
+
+    test('22. public API encode returns map', () {
+      expect(encodeSurfaceVariantAnimationRef(_ref()), isA<Map<String, Object?>>());
+    });
+
+    test('23. ProjectManifest has no surface persistence keys (Lot 43)', () {
+      const manifest = ProjectManifest(
+        name: 'L43',
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
+      '24. codec external to model: no ref.toJson or SurfaceVariantAnimationRef.fromJson',
+      () {
+        final r = _ref();
+        final m = encodeSurfaceVariantAnimationRef(r);
+        expect(m, isA<Map<String, Object?>>());
+      },
+    );
+
+    test('25. SurfaceVariantAnimationRefSet codec remains out of scope (Lot 44)', () {
+      final m = encodeSurfaceVariantAnimationRef(_ref());
+      expect(m['role'], isNotNull);
+    });
+
+    test('26. preset and catalog codec remain out of scope', () {
+      final j = encodeSurfaceVariantAnimationRef(_ref());
+      expect(j.containsKey('role'), isTrue);
+    });
+
+    test('27. standardSurfaceVariantRoleOrder has length 20 (Lot 28 coquille doc)', () {
+      expect(standardSurfaceVariantRoleOrder.length, 20);
+    });
+  });
+}
+
+SurfaceVariantAnimationRef _ref({
+  SurfaceVariantRole role = SurfaceVariantRole.isolated,
+  String animationId = 'water-isolated-loop',
+}) {
+  return SurfaceVariantAnimationRef(
+    role: role,
+    animationId: animationId,
+  );
+}

```

#### C.3 `git diff` — `map_core.dart`

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 8fe6a184..efd5b0a8 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -49,6 +49,7 @@ export 'src/operations/surface_atlas_json_codec.dart';
 export 'src/operations/surface_animation_frame_json_codec.dart';
 export 'src/operations/surface_animation_timeline_json_codec.dart';
 export 'src/operations/project_surface_animation_json_codec.dart';
+export 'src/operations/surface_variant_animation_ref_json_codec.dart';
 export 'src/operations/legacy_path_surface_view.dart';
 export 'src/operations/legacy_terrain_surface_view.dart';
 export 'src/operations/legacy_project_surface_catalog_view.dart';

```

#### C.4 Rapport (exception cahier)

Un diff unifié `/dev/null` de ce fichier serait l’intégralité du texte de l’article 39, chaque ligne préfixée par `+` ; le présent document sert de preuve complète de son propre contenu.

### D. Sorties

#### D.1 Test Lot 43 (intégral)

**Commande :** `cd packages/map_core && /opt/homebrew/bin/dart test test/surface_variant_animation_ref_json_codec_test.dart`

```text

00:00 [32m+0[0m: [1m[90mloading test/surface_variant_animation_ref_json_codec_test.dart[0m[0m                                                                                                                              
00:00 [32m+0[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 1. encodeSurfaceVariantRole isolated[0m                                                                                                          
00:00 [32m+1[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 1. encodeSurfaceVariantRole isolated[0m                                                                                                          
00:00 [32m+1[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 2. decodeSurfaceVariantRole isolated[0m                                                                                                          
00:00 [32m+2[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 2. decodeSurfaceVariantRole isolated[0m                                                                                                          
00:00 [32m+2[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 3. round-trip every SurfaceVariantRole.values[0m                                                                                                 
00:00 [32m+3[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 3. round-trip every SurfaceVariantRole.values[0m                                                                                                 
00:00 [32m+3[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 4. standardSurfaceVariantRoleOrder: order preserved, each round-trips[0m                                                                         
00:00 [32m+4[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 4. standardSurfaceVariantRoleOrder: order preserved, each round-trips[0m                                                                         
00:00 [32m+4[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 5. decode rejects unknown role string[0m                                                                                                         
00:00 [32m+5[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 5. decode rejects unknown role string[0m                                                                                                         
00:00 [32m+5[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 6. decode rejects wrong casing[0m                                                                                                                
00:00 [32m+6[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 6. decode rejects wrong casing[0m                                                                                                                
00:00 [32m+6[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 7. decode rejects valid name with surrounding spaces[0m                                                                                          
00:00 [32m+7[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 7. decode rejects valid name with surrounding spaces[0m                                                                                          
00:00 [32m+7[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 8. encode SurfaceVariantAnimationRef[0m                                                                                                          
00:00 [32m+8[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 8. encode SurfaceVariantAnimationRef[0m                                                                                                          
00:00 [32m+8[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 9. decode SurfaceVariantAnimationRef[0m                                                                                                          
00:00 [32m+9[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 9. decode SurfaceVariantAnimationRef[0m                                                                                                          
00:00 [32m+9[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 10. round-trip SurfaceVariantAnimationRef[0m                                                                                                     
00:00 [32m+10[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 10. round-trip SurfaceVariantAnimationRef[0m                                                                                                    
00:00 [32m+10[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 11. decode preserves animationId exact (no auto-trim in model)[0m                                                                               
00:00 [32m+11[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 11. decode preserves animationId exact (no auto-trim in model)[0m                                                                               
00:00 [32m+11[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 12. decode rejects missing role[0m                                                                                                              
00:00 [32m+12[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 12. decode rejects missing role[0m                                                                                                              
00:00 [32m+12[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 13. decode rejects role wrong type[0m                                                                                                           
00:00 [32m+13[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 13. decode rejects role wrong type[0m                                                                                                           
00:00 [32m+13[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 14. decode rejects unknown role in ref json[0m                                                                                                  
00:00 [32m+14[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 14. decode rejects unknown role in ref json[0m                                                                                                  
00:00 [32m+14[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 15. decode rejects role wrong casing in ref json[0m                                                                                             
00:00 [32m+15[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 15. decode rejects role wrong casing in ref json[0m                                                                                             
00:00 [32m+15[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 16. decode rejects missing animationId[0m                                                                                                       
00:00 [32m+16[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 16. decode rejects missing animationId[0m                                                                                                       
00:00 [32m+16[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 17. decode rejects animationId wrong type[0m                                                                                                    
00:00 [32m+17[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 17. decode rejects animationId wrong type[0m                                                                                                    
00:00 [32m+17[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 18. decode rejects animationId whitespace-only (constructor)[0m                                                                                 
00:00 [32m+18[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 18. decode rejects animationId whitespace-only (constructor)[0m                                                                                 
00:00 [32m+18[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 19. decode ignores unknown key[0m                                                                                                               
00:00 [32m+19[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 19. decode ignores unknown key[0m                                                                                                               
00:00 [32m+19[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 20. decode does not mutate source map[0m                                                                                                        
00:00 [32m+20[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 20. decode does not mutate source map[0m                                                                                                        
00:00 [32m+20[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 21. does not resolve missing animationId[0m                                                                                                     
00:00 [32m+21[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 21. does not resolve missing animationId[0m                                                                                                     
00:00 [32m+21[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 22. public API encode returns map[0m                                                                                                            
00:00 [32m+22[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 22. public API encode returns map[0m                                                                                                            
00:00 [32m+22[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 23. ProjectManifest has no surface persistence keys (Lot 43)[0m                                                                                 
00:00 [32m+23[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 23. ProjectManifest has no surface persistence keys (Lot 43)[0m                                                                                 
00:00 [32m+23[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 24. codec external to model: no ref.toJson or SurfaceVariantAnimationRef.fromJson[0m                                                            
00:00 [32m+24[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 24. codec external to model: no ref.toJson or SurfaceVariantAnimationRef.fromJson[0m                                                            
00:00 [32m+24[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 25. SurfaceVariantAnimationRefSet codec remains out of scope (Lot 44)[0m                                                                        
00:00 [32m+25[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 25. SurfaceVariantAnimationRefSet codec remains out of scope (Lot 44)[0m                                                                        
00:00 [32m+25[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 26. preset and catalog codec remain out of scope[0m                                                                                             
00:00 [32m+26[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 26. preset and catalog codec remain out of scope[0m                                                                                             
00:00 [32m+26[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 27. standardSurfaceVariantRoleOrder has length 20 (Lot 28 coquille doc)[0m                                                                      
00:00 [32m+27[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 27. standardSurfaceVariantRoleOrder has length 20 (Lot 28 coquille doc)[0m                                                                      
00:00 [32m+27[0m: All tests passed![0m                                                                                                                                                                           

```

#### D.2 Régressions (intégral)

**`test/surface_variant_role_test.dart`**

```text

00:00 [32m+0[0m: [1m[90mloading test/surface_variant_role_test.dart[0m[0m                                                                                                                                                  
00:00 [32m+0[0m: SurfaceVariantRole SurfaceVariantRole.values is exactly the expected order[0m                                                                                                                   
00:00 [32m+1[0m: SurfaceVariantRole SurfaceVariantRole.values is exactly the expected order[0m                                                                                                                   
00:00 [32m+1[0m: SurfaceVariantRole standardSurfaceVariantRoleOrder matches expected explicit list[0m                                                                                                            
00:00 [32m+2[0m: SurfaceVariantRole standardSurfaceVariantRoleOrder matches expected explicit list[0m                                                                                                            
00:00 [32m+2[0m: SurfaceVariantRole standard list covers all enum values once (set + length)[0m                                                                                                                  
00:00 [32m+3[0m: SurfaceVariantRole standard list covers all enum values once (set + length)[0m                                                                                                                  
00:00 [32m+3[0m: SurfaceVariantRole standardSurfaceVariantRoleOrder is not growable (const list)[0m                                                                                                              
00:00 [32m+4[0m: SurfaceVariantRole standardSurfaceVariantRoleOrder is not growable (const list)[0m                                                                                                              
00:00 [32m+4[0m: SurfaceVariantRole export: types from map_core only[0m                                                                                                                                          
00:00 [32m+5[0m: SurfaceVariantRole export: types from map_core only[0m                                                                                                                                          
00:00 [32m+5[0m: SurfaceVariantRole ProjectManifest toJson: no surface* top-level keys[0m                                                                                                                        
00:00 [32m+6[0m: SurfaceVariantRole ProjectManifest toJson: no surface* top-level keys[0m                                                                                                                        
00:00 [32m+6[0m: SurfaceVariantRole TerrainPathVariant still available; cross names align (no conversion)[0m                                                                                                     
00:00 [32m+7[0m: SurfaceVariantRole TerrainPathVariant still available; cross names align (no conversion)[0m                                                                                                     
00:00 [32m+7[0m: All tests passed![0m                                                                                                                                                                            

```

**`test/surface_variant_animation_ref_test.dart`**

```text

00:00 [32m+0[0m: [1m[90mloading test/surface_variant_animation_ref_test.dart[0m[0m                                                                                                                                         
00:00 [32m+0[0m: SurfaceVariantAnimationRef minimal ref holds role and animationId[0m                                                                                                                            
00:00 [32m+1[0m: SurfaceVariantAnimationRef minimal ref holds role and animationId[0m                                                                                                                            
00:00 [32m+1[0m: SurfaceVariantAnimationRef accepts several distinct roles (sample)[0m                                                                                                                           
00:00 [32m+2[0m: SurfaceVariantAnimationRef accepts several distinct roles (sample)[0m                                                                                                                           
00:00 [32m+2[0m: SurfaceVariantAnimationRef stores animationId exactly without auto-trim[0m                                                                                                                      
00:00 [32m+3[0m: SurfaceVariantAnimationRef stores animationId exactly without auto-trim[0m                                                                                                                      
00:00 [32m+3[0m: SurfaceVariantAnimationRef rejects empty animationId: empty string[0m                                                                                                                           
00:00 [32m+4[0m: SurfaceVariantAnimationRef rejects empty animationId: empty string[0m                                                                                                                           
00:00 [32m+4[0m: SurfaceVariantAnimationRef rejects empty animationId: whitespace only[0m                                                                                                                        
00:00 [32m+5[0m: SurfaceVariantAnimationRef rejects empty animationId: whitespace only[0m                                                                                                                        
00:00 [32m+5[0m: SurfaceVariantAnimationRef value equality: same values => equal and same hash[0m                                                                                                                
00:00 [32m+6[0m: SurfaceVariantAnimationRef value equality: same values => equal and same hash[0m                                                                                                                
00:00 [32m+6[0m: SurfaceVariantAnimationRef value equality: different role[0m                                                                                                                                    
00:00 [32m+7[0m: SurfaceVariantAnimationRef value equality: different role[0m                                                                                                                                    
00:00 [32m+7[0m: SurfaceVariantAnimationRef value equality: different animationId[0m                                                                                                                             
00:00 [32m+8[0m: SurfaceVariantAnimationRef value equality: different animationId[0m                                                                                                                             
00:00 [32m+8[0m: SurfaceVariantAnimationRef export: type visible through map_core[0m                                                                                                                             
00:00 [32m+9[0m: SurfaceVariantAnimationRef export: type visible through map_core[0m                                                                                                                             
00:00 [32m+9[0m: SurfaceVariantAnimationRef coexists with ProjectSurfaceAnimation: id string only, no resolution[0m                                                                                              
00:00 [32m+10[0m: SurfaceVariantAnimationRef coexists with ProjectSurfaceAnimation: id string only, no resolution[0m                                                                                             
00:00 [32m+10[0m: SurfaceVariantAnimationRef one ref per role in standardSurfaceVariantRoleOrder (length + order)[0m                                                                                             
00:00 [32m+11[0m: SurfaceVariantAnimationRef one ref per role in standardSurfaceVariantRoleOrder (length + order)[0m                                                                                             
00:00 [32m+11[0m: SurfaceVariantAnimationRef ProjectManifest toJson: no surface* top-level keys[0m                                                                                                               
00:00 [32m+12[0m: SurfaceVariantAnimationRef ProjectManifest toJson: no surface* top-level keys[0m                                                                                                               
00:00 [32m+12[0m: All tests passed![0m                                                                                                                                                                           

```

**`test/project_surface_animation_json_codec_test.dart`**

```text

00:00 [32m+0[0m: [1m[90mloading test/project_surface_animation_json_codec_test.dart[0m[0m                                                                                                                                  
00:00 [32m+0[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 1. encodes minimal ProjectSurfaceAnimation[0m                                                                                                       
00:00 [32m+1[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 1. encodes minimal ProjectSurfaceAnimation[0m                                                                                                       
00:00 [32m+1[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 2. decodes minimal ProjectSurfaceAnimation[0m                                                                                                       
00:00 [32m+2[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 2. decodes minimal ProjectSurfaceAnimation[0m                                                                                                       
00:00 [32m+2[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 3. round-trip minimal animation[0m                                                                                                                  
00:00 [32m+3[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 3. round-trip minimal animation[0m                                                                                                                  
00:00 [32m+3[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 4. encodes full animation (sync, category, sort)[0m                                                                                                 
00:00 [32m+4[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 4. encodes full animation (sync, category, sort)[0m                                                                                                 
00:00 [32m+4[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 5. decodes full animation[0m                                                                                                                        
00:00 [32m+5[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 5. decodes full animation[0m                                                                                                                        
00:00 [32m+5[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 6. round-trip full animation[0m                                                                                                                     
00:00 [32m+6[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 6. round-trip full animation[0m                                                                                                                     
00:00 [32m+6[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 7. encode preserves multi-frame timeline[0m                                                                                                         
00:00 [32m+7[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 7. encode preserves multi-frame timeline[0m                                                                                                         
00:00 [32m+7[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 8. decodes multi-frame timeline[0m                                                                                                                  
00:00 [32m+8[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 8. decodes multi-frame timeline[0m                                                                                                                  
00:00 [32m+8[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 9. decode preserves exact id/name/sync/category strings[0m                                                                                          
00:00 [32m+9[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 9. decode preserves exact id/name/sync/category strings[0m                                                                                          
00:00 [32m+9[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 10. reject id missing / wrong type / whitespace-only[0m                                                                                             
00:00 [32m+10[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 10. reject id missing / wrong type / whitespace-only[0m                                                                                            
00:00 [32m+10[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 11. reject name missing / wrong type / whitespace-only[0m                                                                                          
00:00 [32m+11[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 11. reject name missing / wrong type / whitespace-only[0m                                                                                          
00:00 [32m+11[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 12. reject timeline missing / not a Map[0m                                                                                                         
00:00 [32m+12[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 12. reject timeline missing / not a Map[0m                                                                                                         
00:00 [32m+12[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 13. reject empty timeline frames[0m                                                                                                                
00:00 [32m+13[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 13. reject empty timeline frames[0m                                                                                                                
00:00 [32m+13[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 14. decode ignores unknown top-level key[0m                                                                                                        
00:00 [32m+14[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 14. decode ignores unknown top-level key[0m                                                                                                        
00:00 [32m+14[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 15. decode ignores unknown keys in timeline / frame / tileRef[0m                                                                                   
00:00 [32m+15[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 15. decode ignores unknown keys in timeline / frame / tileRef[0m                                                                                   
00:00 [32m+15[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 16. decode accepts syncGroupId: null in JSON[0m                                                                                                    
00:00 [32m+16[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 16. decode accepts syncGroupId: null in JSON[0m                                                                                                    
00:00 [32m+16[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 17. reject syncGroupId non-string non-null[0m                                                                                                      
00:00 [32m+17[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 17. reject syncGroupId non-string non-null[0m                                                                                                      
00:00 [32m+17[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 18. reject syncGroupId whitespace-only (model + codec)[0m                                                                                          
00:00 [32m+18[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 18. reject syncGroupId whitespace-only (model + codec)[0m                                                                                          
00:00 [32m+18[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 19. decode accepts categoryId: null[0m                                                                                                             
00:00 [32m+19[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 19. decode accepts categoryId: null[0m                                                                                                             
00:00 [32m+19[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 20. reject categoryId non-string non-null[0m                                                                                                       
00:00 [32m+20[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 20. reject categoryId non-string non-null[0m                                                                                                       
00:00 [32m+20[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 21. decode accepts sortOrder absent (default 0)[0m                                                                                                 
00:00 [32m+21[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 21. decode accepts sortOrder absent (default 0)[0m                                                                                                 
00:00 [32m+21[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 22. decode accepts negative sortOrder[0m                                                                                                           
00:00 [32m+22[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 22. decode accepts negative sortOrder[0m                                                                                                           
00:00 [32m+22[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 23. reject sortOrder non-int[0m                                                                                                                    
00:00 [32m+23[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 23. reject sortOrder non-int[0m                                                                                                                    
00:00 [32m+23[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 24. decode does not mutate source map[0m                                                                                                           
00:00 [32m+24[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 24. decode does not mutate source map[0m                                                                                                           
00:00 [32m+24[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 25. encode does not mutate source animation[0m                                                                                                     
00:00 [32m+25[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 25. encode does not mutate source animation[0m                                                                                                     
00:00 [32m+25[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 26. no geometry in codec; isInside is separate[0m                                                                                                  
00:00 [32m+26[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 26. no geometry in codec; isInside is separate[0m                                                                                                  
00:00 [32m+26[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 27. no external resolution of atlasId[0m                                                                                                           
00:00 [32m+27[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 27. no external resolution of atlasId[0m                                                                                                           
00:00 [32m+27[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 28. public API encode returns Map[0m                                                                                                               
00:00 [32m+28[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 28. public API encode returns Map[0m                                                                                                               
00:00 [32m+28[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 29. ProjectManifest has no surface persistence keys (Lot 42)[0m                                                                                    
00:00 [32m+29[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 29. ProjectManifest has no surface persistence keys (Lot 42)[0m                                                                                    
00:00 [32m+29[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 30. codec external to model: no animation.toJson or ProjectSurfaceAnimation.fromJson[0m                                                            
00:00 [32m+30[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 30. codec external to model: no animation.toJson or ProjectSurfaceAnimation.fromJson[0m                                                            
00:00 [32m+30[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 31. no preset / catalog / variant ref codec in this lot[0m                                                                                         
00:00 [32m+31[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 31. no preset / catalog / variant ref codec in this lot[0m                                                                                         
00:00 [32m+31[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 32. reuses Lot 41 timeline codec (json[timeline] == encodeTimeline)[0m                                                                             
00:00 [32m+32[0m: ProjectSurfaceAnimation JSON codec (Lot 42) 32. reuses Lot 41 timeline codec (json[timeline] == encodeTimeline)[0m                                                                             
00:00 [32m+32[0m: All tests passed![0m                                                                                                                                                                           

```

**`test/surface_model_entrypoint_test.dart`**

```text

00:00 [32m+0[0m: [1m[90mloading test/surface_model_entrypoint_test.dart[0m[0m                                                                                                                                              
00:00 [32m+0[0m: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) SurfaceAtlasLayout.values exposes exactly the expected cases in order[0m                                                                 
00:00 [32m+1[0m: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) SurfaceAtlasLayout.values exposes exactly the expected cases in order[0m                                                                 
00:00 [32m+1[0m: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) ProjectManifest JSON has no surface engine manifest keys yet[0m                                                                          
00:00 [32m+2[0m: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) ProjectManifest JSON has no surface engine manifest keys yet[0m                                                                          
00:00 [32m+2[0m: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) ProjectPathPreset construction remains available unchanged[0m                                                                            
00:00 [32m+3[0m: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) ProjectPathPreset construction remains available unchanged[0m                                                                            
00:00 [32m+3[0m: All tests passed![0m                                                                                                                                                                            

```

#### D.3 `dart analyze` (intégral)

```text
Analyzing surface_variant_animation_ref_json_codec.dart, project_surface_animation_json_codec.dart, surface.dart, surface_variant_animation_ref_json_codec_test.dart, surface_variant_role_test.dart, surface_variant_animation_ref_test.dart, project_surface_animation_json_codec_test.dart, surface_model_entrypoint_test.dart, map_core.dart...
No issues found!

```

#### D.4 Dernière ligne `dart test` complet

**Commande :** `cd packages/map_core && /opt/homebrew/bin/dart test` (reporter `expanded` pour dernière ligne)

```text
00:01 +1002: All tests passed!
```

#### D.5 `git status --short`

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/surface_variant_animation_ref_json_codec.dart
?? packages/map_core/test/surface_variant_animation_ref_json_codec_test.dart
?? reports/surface/surface_engine_lot_43_surface_variant_animation_ref_json_codec.md
```

---
*Fin du document Lot 43.*
