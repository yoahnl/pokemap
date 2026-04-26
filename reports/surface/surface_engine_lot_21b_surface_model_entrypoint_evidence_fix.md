# Lot 21-bis — Evidence fix (Surface Model Entrypoint V0)

**Date (rédaction)** : 2026-04-26  
**Type** : lot **uniquement documentaire** (aucun changement de code, aucun manifest, pas de générés, pas de `build_runner`).

---

## 1. Résumé exécutif

Le rapport `surface_engine_lot_21_surface_model_entrypoint.md` (Lot 21) n’y collait **pas** les **textes intégraux** des sources ni les **diffs unifiés** (notamment `diff -u /dev/null` pour les ajouts de fichiers). Le Lot **21-bis** fournit ici les **contenus complets**, les **diffs** reproductibles, et les **sorties** de `dart test` / `dart analyze` relancés.

---

## 2. Pourquoi le Lot 21-bis existe

Compléter la discipline de preuve demandée : copier les fichiers, les diff, et re-coller les résultats de commandes, **sans** avancer le Lot 22.

---

## 3. Fichiers inspectés

- `packages/map_core/lib/src/models/surface.dart`
- `packages/map_core/test/surface_model_entrypoint_test.dart`
- `packages/map_core/lib/map_core.dart`
- `reports/surface/surface_engine_lot_21_surface_model_entrypoint.md`

Vérifications :

1. `surface.dart` : **un seul** type public, `enum SurfaceAtlasLayout` (3 variantes, ordre documenté en §6/§10/§11 n’est pas requis ici, voir contenu).
2. Valeurs d’`enum` : `grid`, `columnsAreVariantsRowsAreFrames`, `rowsAreVariantsColumnsAreFrames`.
3. `map_core.dart` : ligne `export 'src/models/surface.dart';` (voir §8, §9).
4. **Imports du test** : `import 'package:map_core/map_core.dart';` pour l’API publique ; `import 'package:test/test.dart';` pour le moteur de test (indispensable). Le Lot 21 avait qualifié d’ « import unique » côté spec — **nuance** : unique **package** applicatif, pas le seul `import` du fichier.
5. Vérification des clés interdites sur le **niveau racine** de `toJson()`.
6. Aucun `project_manifest` modifié en Lot 21 ; idem 21-bis. Aucun `.g` / `freezed` généré pour le Lot 21.

---

## 4. Fichiers modifiés par le Lot 21-bis (ce document)

- **Créé** : `reports/surface/surface_engine_lot_21b_surface_model_entrypoint_evidence_fix.md`  
- **Aucun** fichier `packages/**` modifié par 21-bis (preuve = ce fichier + statut `git`).

---

## 5. Confirmation : code du Lot 21 **non** modifié en 21-bis

Le Lot 21-bis n’édite **aucun** `.dart` de `map_core` : seules les relectures et les commandes d’**observation** sont effectuées.

---

## 6. Contenu intégral — `packages/map_core/lib/src/models/surface.dart`

```dart
// Fichier d’entrée minimal Surface : pas de modèle persistant ici, uniquement
// du vocabulaire d’atlas partagé pour le futur moteur.

/// Convention de **disposition** d’un tileset d’atlas (comment interpréter la
/// grille 2D par rapport aux variantes de surface et aux frames d’animation).
///
/// Ce type est volontairement indépendant de `ProjectPathPreset` : il pourra
/// servir plus tard à décrire des atlasses Surface sans dupliquer le legacy
/// path-only.
enum SurfaceAtlasLayout {
  /// Grille d’atlas classique, **sans** convention imposée « variante = axe X »
  /// / « frame = axe Y ». Utile quand l’adresse d’une tuile est arbitraire
  /// (sélection manuelle, pack artistique) ou quand l’outillage n’impose pas
  /// encore la séparation variante/animation.
  grid,

  /// Chaque **colonne** du tileset = une **variante** d’apparence (bord, coin,
  /// pièce centrale, etc.) ; chaque **ligne** = une **frame** d’animation
  /// (temps) pour ce même slot de variante.
  ///
  /// C’est la convention des lots **11–19** (bridge vertical-atlas) : l’axe
  /// `x` indexe le `TerrainPathVariant` / la colonne, l’axe `y` indexe
  /// l’empilement des `TilesetVisualFrame`.
  columnsAreVariantsRowsAreFrames,

  /// Convention **miroir** de [columnsAreVariantsRowsAreFrames] : chaque
  /// **ligne** = une variante, chaque **colonne** = une frame. Prévue pour
  /// ne pas enfermer le moteur Surface dans une seule orientation d’atlas
  /// (art packs, outils, ou imports où les axes sont inversés).
  rowsAreVariantsColumnsAreFrames,
}
```

---

## 7. Contenu intégral — `packages/map_core/test/surface_model_entrypoint_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Lot 21 — surface model entrypoint (SurfaceAtlasLayout)', () {
    test('SurfaceAtlasLayout.values exposes exactly the expected cases in order',
        () {
      expect(SurfaceAtlasLayout.values, [
        SurfaceAtlasLayout.grid,
        SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
        SurfaceAtlasLayout.rowsAreVariantsColumnsAreFrames,
      ]);
    });

    test('ProjectManifest JSON has no surface engine manifest keys yet', () {
      const manifest = ProjectManifest(
        name: 'L21 smoke',
        maps: [
          ProjectMapEntry(
            id: 'm1',
            name: 'Map',
            relativePath: 'maps/m1.json',
          ),
        ],
        tilesets: [],
      );
      final map = manifest.toJson();
      const forbidden = <String>[
        'surfaceDefinitions',
        'surfaceAtlases',
        'surfaceAnimations',
        'surfacePresets',
        'surfaceCategories',
      ];
      for (final key in forbidden) {
        expect(map.containsKey(key), isFalse, reason: 'unexpected key: $key');
      }
    });

    test('ProjectPathPreset construction remains available unchanged', () {
      const preset = ProjectPathPreset(
        id: 'l21-preset',
        name: 'L21',
        surfaceKind: PathSurfaceKind.water,
      );
      expect(preset.id, 'l21-preset');
      expect(preset.name, 'L21');
      expect(preset.surfaceKind, PathSurfaceKind.water);
      expect(preset.variants, isEmpty);
    });
  });
}
```

---

## 8. Extrait pertinent — `packages/map_core/lib/map_core.dart` (30 premières lignes)

```dart
library map_core;

export 'src/models/enums.dart';
export 'src/models/geometry.dart';
export 'src/models/tileset.dart';
export 'src/models/map_data.dart';
export 'src/models/element_collision_profile.dart';
export 'src/models/map_entity_payloads.dart';
export 'src/models/map_entity_editor_visual.dart';
export 'src/models/map_gameplay_zone_payloads.dart';
export 'src/models/map_layer.dart';
export 'src/models/map_metadata.dart';
export 'src/models/project_manifest.dart';
export 'src/models/save_data.dart';
export 'src/models/game_state.dart';
export 'src/models/pokemon_move.dart';
export 'src/models/pokemon_move_accuracy.dart';
export 'src/models/pokemon_move_effect.dart';
export 'src/models/script_asset.dart';
export 'src/models/script_conditions.dart';
export 'src/models/map_event_definition.dart';
export 'src/models/project_trainer.dart';
export 'src/models/scenario_asset.dart';
export 'src/models/visual_frame_json.dart';
export 'src/models/surface.dart';
export 'src/operations/map_resize.dart';
export 'src/operations/map_paint.dart';
export 'src/operations/map_collision.dart';
export 'src/operations/map_path.dart';
export 'src/operations/map_terrain.dart';
```

… (fichier complet : 74 lignes ; l’`export` Surface est visibles ci-dessus) …

---

## 9. Diff complet — `map_core.dart` (commit Lot 21 `9431782f`, `git diff` parent → commit)

> Si ce commit n’est **pas** dans votre historique local, générer l’équivalent avec le même seul hunk `+export 'src/models/surface.dart';`.

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 46e6067b..52f4115c 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -22,6 +22,7 @@ export 'src/models/map_event_definition.dart';
 export 'src/models/project_trainer.dart';
 export 'src/models/scenario_asset.dart';
 export 'src/models/visual_frame_json.dart';
+export 'src/models/surface.dart';
 export 'src/operations/map_resize.dart';
 export 'src/operations/map_paint.dart';
 export 'src/operations/map_collision.dart';
```

---

## 10. Diff unifié `diff -u /dev/null` — `surface.dart`

```diff
--- /dev/null	2026-04-26 23:08:54
+++ /Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/surface.dart	2026-04-26 23:03:57
@@ -0,0 +1,31 @@
+// Fichier d’entrée minimal Surface : pas de modèle persistant ici, uniquement
+// du vocabulaire d’atlas partagé pour le futur moteur.
+
+/// Convention de **disposition** d’un tileset d’atlas (comment interpréter la
+/// grille 2D par rapport aux variantes de surface et aux frames d’animation).
+///
+/// Ce type est volontairement indépendant de `ProjectPathPreset` : il pourra
+/// servir plus tard à décrire des atlasses Surface sans dupliquer le legacy
+/// path-only.
+enum SurfaceAtlasLayout {
+  /// Grille d’atlas classique, **sans** convention imposée « variante = axe X »
+  /// / « frame = axe Y ». Utile quand l’adresse d’une tuile est arbitraire
+  /// (sélection manuelle, pack artistique) ou quand l’outillage n’impose pas
+  /// encore la séparation variante/animation.
+  grid,
+
+  /// Chaque **colonne** du tileset = une **variante** d’apparence (bord, coin,
+  /// pièce centrale, etc.) ; chaque **ligne** = une **frame** d’animation
+  /// (temps) pour ce même slot de variante.
+  ///
+  /// C’est la convention des lots **11–19** (bridge vertical-atlas) : l’axe
+  /// `x` indexe le `TerrainPathVariant` / la colonne, l’axe `y` indexe
+  /// l’empilement des `TilesetVisualFrame`.
+  columnsAreVariantsRowsAreFrames,
+
+  /// Convention **miroir** de [columnsAreVariantsRowsAreFrames] : chaque
+  /// **ligne** = une variante, chaque **colonne** = une frame. Prévue pour
+  /// ne pas enfermer le moteur Surface dans une seule orientation d’atlas
+  /// (art packs, outils, ou imports où les axes sont inversés).
+  rowsAreVariantsColumnsAreFrames,
+}
```

---

## 11. Diff unifié `diff -u /dev/null` — `surface_model_entrypoint_test.dart`

```diff
--- /dev/null	2026-04-26 23:08:54
+++ /Users/karim/Project/pokemonProject/packages/map_core/test/surface_model_entrypoint_test.dart	2026-04-26 23:04:28
@@ -0,0 +1,52 @@
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+void main() {
+  group('Lot 21 — surface model entrypoint (SurfaceAtlasLayout)', () {
+    test('SurfaceAtlasLayout.values exposes exactly the expected cases in order',
+        () {
+      expect(SurfaceAtlasLayout.values, [
+        SurfaceAtlasLayout.grid,
+        SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+        SurfaceAtlasLayout.rowsAreVariantsColumnsAreFrames,
+      ]);
+    });
+
+    test('ProjectManifest JSON has no surface engine manifest keys yet', () {
+      const manifest = ProjectManifest(
+        name: 'L21 smoke',
+        maps: [
+          ProjectMapEntry(
+            id: 'm1',
+            name: 'Map',
+            relativePath: 'maps/m1.json',
+          ),
+        ],
+        tilesets: [],
+      );
+      final map = manifest.toJson();
+      const forbidden = <String>[
+        'surfaceDefinitions',
+        'surfaceAtlases',
+        'surfaceAnimations',
+        'surfacePresets',
+        'surfaceCategories',
+      ];
+      for (final key in forbidden) {
+        expect(map.containsKey(key), isFalse, reason: 'unexpected key: $key');
+      }
+    });
+
+    test('ProjectPathPreset construction remains available unchanged', () {
+      const preset = ProjectPathPreset(
+        id: 'l21-preset',
+        name: 'L21',
+        surfaceKind: PathSurfaceKind.water,
+      );
+      expect(preset.id, 'l21-preset');
+      expect(preset.name, 'L21');
+      expect(preset.surfaceKind, PathSurfaceKind.water);
+      expect(preset.variants, isEmpty);
+    });
+  });
+}
```

---

## 12. Diff unifié `diff -u /dev/null` — `surface_engine_lot_21_surface_model_entrypoint.md`

> Bloc en **4 backticks** (Markdown) afin d’y inclure les occurrences de ` ``` ` présentes *dans* le Rapport 21 (sinon, elles clôturent le bloc trop tôt).

````diff
--- /dev/null	2026-04-26 23:09:22
+++ reports/surface/surface_engine_lot_21_surface_model_entrypoint.md	2026-04-26 23:04:36
@@ -0,0 +1,229 @@
+# Lot 21 — Surface Model Entrypoint V0
+
+**Date (rédaction)** : 2026-04-26  
+**Objectif** : introduire le premier fichier modèle `surface.dart` dans `map_core` avec un enum minimal [`SurfaceAtlasLayout`], **sans** modifier `ProjectManifest` ni générer de JSON/Freezed.
+
+---
+
+## 1. Résumé exécutif
+
+- Ajout de `packages/map_core/lib/src/models/surface.dart` contenant **uniquement** l’enum `SurfaceAtlasLayout` (`grid`, `columnsAreVariantsRowsAreFrames`, `rowsAreVariantsColumnsAreFrames`) avec documentation.
+- Export public via `export 'src/models/surface.dart';` dans `map_core.dart`.
+- Trois tests de garde : ordre de l’enum, absence (dans le JSON manifest courant) des clés Surface futures, et non-régression `ProjectPathPreset` minimal.
+- Aucun `build_runner`, aucun `.g.dart` / `.freezed.dart` nouveau, `ProjectManifest` **non** modifié.
+- Analyse ciblée : **No issues found!**  
+- Tests : cible `+3`, suite complète `+527` **All tests passed!**
+
+---
+
+## 2. Pourquoi ce lot vient après le Lot 20
+
+Le Lot 20 a clos la phase **P0.5** (bridge vertical-atlas + wrappers) et a recommandé de ne plus multiplier les one-liners legacy. Le Lot 21 ouvre la **phase modèle** avec un point d’entrée **inoffensif** : un vocabulaire d’atlas partagé, sans accrochage persistant, pour ne pas bousculer le contrat `ProjectManifest` avant que les lots suivants ne le cadrer.
+
+---
+
+## 3. Fichiers consultés (audit)
+
+- `packages/map_core/lib/map_core.dart` — zone d’exports.
+- `packages/map_core/lib/src/models/project_manifest.dart` — vérification qu’aucun champ Surface n’existe encore (confirmé) ; rappel : Freezed/JSON ailleurs, **hors** périmètre de modification Lot 21.
+- `packages/map_core/lib/src/models/enums.dart`, `tileset.dart`, `map_layer.dart`, `visual_frame_json.dart` contexte.
+- `reports/surface/surface_engine_lot_20_legacy_vertical_atlas_bridge_consolidation.md`.
+- `surface project/pokemap_surface_engine_micro_lots.md` (présent) — alignement P1.01.
+- `surface project/pokemap_surface_engine_spec.md` (présent).
+
+---
+
+## 4. Fichiers créés
+
+| Fichier | Rôle |
+|---------|------|
+| `packages/map_core/lib/src/models/surface.dart` | Enum `SurfaceAtlasLayout` |
+| `packages/map_core/test/surface_model_entrypoint_test.dart` | Tests d’accès public + garde-fous |
+| `reports/surface/surface_engine_lot_21_surface_model_entrypoint.md` | Ce rapport |
+
+---
+
+## 5. Fichier modifié
+
+| Fichier | Modification |
+|---------|--------------|
+| `packages/map_core/lib/map_core.dart` | `+1` ligne d’`export` |
+
+---
+
+## 6. API ajoutée
+
+- **`enum SurfaceAtlasLayout`**
+
+---
+
+## 7. Explication des valeurs de `SurfaceAtlasLayout`
+
+| Valeur | Rôle documenté |
+|--------|-----------------|
+| `grid` | Atlas en grille classique, sans imposer l’alignement variante/animation sur un axe. |
+| `columnsAreVariantsRowsAreFrames` | **Colonnes = variantes**, **lignes = frames** — correspond au bridge lots **11–19** (vertical atlas : `x` = variante, `y` = frame). |
+| `rowsAreVariantsColumnsAreFrames` | **Miroir** : lignes = variantes, colonnes = frames, pour ne pas cristalliser une seule orientation. |
+
+**Choix** : **pas** de `@JsonValue` / `json_annotation` ici. Les valeurs stables en `snake_case` pour le JSON (si besoin) seront mieux gérées **avec** le lot qui introduit la sérialisation `Surface*`, pour éviter de suggérer une semantique JSON **sans** codegen autorisé ni contract tests manifest.
+
+---
+
+## 8. Ce qui a été testé
+
+- Ordre et contenu de `SurfaceAtlasLayout.values`.
+- `ProjectManifest.toJson()` : absence des clés **de premier niveau** `surfaceDefinitions`, `surfaceAtlases`, `surfaceAnimations`, `surfacePresets`, `surfaceCategories` (vérification sur la `Map` — import de test limité à `map_core` + `test`, sans `dart:convert`).
+- Construction d’un `ProjectPathPreset` minimal (API toujours accessible).
+
+---
+
+## 9. Ce que les tests prouvent
+
+- L’**export** `package:map_core/map_core.dart` réexporte `SurfaceAtlasLayout` correctement.
+- Le **lot n’a pas ajouté** de champs Surface sur le `ProjectManifest` (aucune de ces clés **au sommet** de `toJson()` aujourd’hui).
+- **Aucun break** sur le type legacy `ProjectPathPreset` pour un scénario minimal.
+
+---
+
+## 10. Ce qui n’a volontairement pas été fait
+
+- Pas de `SurfaceDefinition`, `ProjectSurface*`, `SurfaceLayer`.
+- Pas de changement de `MapData`, `MapLayer` structurelle.
+- Pas de `build_runner` / part files / générés.
+- Pas de modification des opérations vertical-atlas, ni des wrappers eau/lave/glace/herbes.
+- Pas de `map_runtime` / `map_editor` / `map_gameplay` / `map_battle`.
+
+---
+
+## 11. Pourquoi `ProjectManifest` n’a pas été modifié
+
+- Le prochain vrai **contrat** persistant (listes, IDs, liens) doit être **spécifié** en lot dédié ; l’injection d’un seul field mal nommé forcerait une migration / compat JSON prématurée.
+- Ici, seul un **énum côté Dart** sert d’**ancre** sémantique partagée.
+
+---
+
+## 12. Pourquoi aucun fichier generated n’a été créé
+
+- Contrainte explicite du lot ; l’**enum** n’a **pas** besoin de Freezed. Les champs `ProjectManifest` futurs s’adosseront à un **plan de sérialisation** unifié (probablement avec codegen **au moment voulu**).
+
+---
+
+## 13. Impact pour les prochains lots Surface
+
+- Les lots peuvent se référer à un **vocabulaire d’atlas** sans dépendre de `PathSurfaceKind` pour décrire la **géométrie** d’un pack de tuiles.
+- `columnsAreVariantsRowsAreFrames` relie explicitement l’héritage P0.5 au futur modèle.
+- Prochaine étape logique (hors petit 21) : champs de manifest, schéma JSON, ou DTOs Freezed **quand** le lot l’imposera.
+
+---
+
+## 14. Commandes lancées
+
+```bash
+cd packages/map_core
+/opt/homebrew/bin/dart test test/surface_model_entrypoint_test.dart
+```
+
+```bash
+cd packages/map_core
+/opt/homebrew/bin/dart analyze \
+  lib/src/models/surface.dart \
+  test/surface_model_entrypoint_test.dart \
+  lib/map_core.dart
+```
+
+```bash
+cd packages/map_core
+/opt/homebrew/bin/dart test
+```
+
+---
+
+## 15. Résultats exacts (tests ciblés)
+
+```text
+00:00 +0: ... loading ...
+00:00 +1: ... SurfaceAtlasLayout.values exposes exactly ...
+00:00 +2: ... ProjectManifest JSON has no surface engine manifest keys yet
+00:00 +3: ... ProjectPathPreset construction remains available unchanged
+00:00 +3: All tests passed!
+```
+
+**Exit code** : 0
+
+---
+
+## 16. Résultats exacts (analyse ciblée)
+
+```text
+Analyzing surface.dart, surface_model_entrypoint_test.dart, map_core.dart...
+No issues found!
+```
+
+**Exit code** : 0
+
+---
+
+## 17. Total exact — `dart test` complet (map_core)
+
+```text
+... +527: All tests passed!
+```
+
+**Exit code** : 0
+
+*(Avant ce lot, la dernière suite notée côté Lot 20 / consolidation était +524 : **+3** comptes ici = les 3 tests du Lot 21.)*
+
+---
+
+## 18. Points de vigilance
+
+- La **garantie d’absence** de champs dans le **JSON** repose sur `ProjectManifest` actuel : si un autre outil **injecte** des clés `surface*` ailleurs, ce test ne couvre **pas** ce flux.
+- L’**ordre** de déclaration de l’enum est contractuel pour le test (et pour tout `index` en sérialisation future) : le premier lot de sérialisation devra s’y référer explicitement.
+- `grid` n’établit **pas** de lien automatique vers autotile path — c’est voulu.
+
+---
+
+## 19. Autocritique finale
+
+- Le rapport s’appuie sur l’**état** du dépôt au moment de l’exécution.
+- Aucun **git write** n’a été utilisé (conformité prompt Lot 21).
+
+---
+
+## 20. Ce que le prompt semble discutable ou incomplet
+
+- **Emplacement** de l’`export` : le texte ne fixe pas d’**ordre strict** (alphabétique vs. clustering `project_manifest`) ; l’export a été placé **après** `visual_frame_json`, avant les `operations/`.
+- **@JsonValue** : utilisable sans générer *ce* fichier, mais conduirait visuellement vers une couche JSON **sans** règles d’enregistrement côté `ProjectManifest` — volontairement repoussé.
+- Compteur **+527** : dépend de l’**historique** de la suite ; toute branche parallèle peut diverger légèrement.
+
+---
+
+## 21. Auto-review indépendante (réponses explicites)
+
+| Question | Réponse |
+|----------|---------|
+| Lot strictement limité au modèle entrypoint + test + report + export ? | **Oui** |
+| Seuls `surface.dart`, test, rapport, `map_core` modifié ? | **Oui** (rapport sous `reports/surface/`) |
+| Aucun `ProjectManifest` modifié ? | **Oui** |
+| Aucun Freezed/JSON généré créé ? | **Oui** |
+| Aucun `.g.dart` / `.freezed.dart` ajouté ? | **Oui** |
+| Aucun runtime / editor / gameplay / battle modifié ? | **Oui** |
+| `SurfaceAtlasLayout` a exactement 3 cas dans l’ordre requis ? | **Oui** (test) |
+| Export public `map_core` OK ? | **Oui** (import unique du test) |
+| Tests prouvent absence (pour l’instant) de clés surface dans `toJson()` ? | **Oui** (clés explicites listées) |
+| Suite complète `map_core` verte avec total +527 ? | **Oui** |
+| Contenu/diff : voir remise de lot / workspace | **Fourni par l’agent** |
+| Commandes git interdites non utilisées ? | **Oui** |
+| Rapport honnête sur limites ? | **Oui** (§18) |
+
+---
+
+## 22. Contenu intégral des fichiers créés/modifiés (référence)
+
+Voir livrable dans l’arbre : `packages/map_core/lib/src/models/surface.dart`, `test/surface_model_entrypoint_test.dart`, `reports/surface/surface_engine_lot_21_surface_model_entrypoint.md`, et la ligne d’`export` dans `map_core.dart`.
+
+## 23. Diff complet (fichiers suivis + nouveaux)
+
+Les fichiers **non suivis** n’apparaissent **pas** dans `git diff` ; le diff des nouveaux fichiers = **ajout intégral** (équivalent `diff -u /dev/null <fichier>`).
+
+*Fin du rapport Lot 21.*
````


## 13. Commandes relancées

`cd packages/map_core` puis —

- `/opt/homebrew/bin/dart test test/surface_model_entrypoint_test.dart`
- `/opt/homebrew/bin/dart analyze lib/src/models/surface.dart test/surface_model_entrypoint_test.dart lib/map_core.dart`
- `/opt/homebrew/bin/dart test` (tout le package)

---

## 14. Résultats exacts (session 21-bis)

### 14.1 Test ciblé

```text
00:00 +0: ... loading test/surface_model_entrypoint_test.dart
00:00 +1: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) SurfaceAtlasLayout.values exposes exactly the expected cases in order
00:00 +2: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) ProjectManifest JSON has no surface engine manifest keys yet
00:00 +3: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) ProjectPathPreset construction remains available unchanged
00:00 +3: All tests passed!
```

**Exit code** : 0

### 14.2 Analyse ciblée

```text
Analyzing surface.dart, surface_model_entrypoint_test.dart, map_core.dart...
No issues found!
```

**Exit code** : 0

### 14.3 Suite complète (derniers octets de log)

```text
... +527: All tests passed!
```

**Exit code** : 0

---

## 15. Total exact — `dart test` complet (map_core)

**+527** — **All tests passed!**

---

## 16. Auto-review 21-bis

- Lot strictement limité à l’**evidence fix** (rapport) : **Oui**  
- Pas de modèle complexe, pas de manifest, pas de générés, pas d’autres paquets : **Oui**  
- Contenus + diffs : **Oui** (§6–12)  
- Relances et totaux : **Oui** (§14–15)  
- Aucun `git add` / `commit` : **Oui** (générer ce rapport reste en working tree / staging selon workflow utilisateur)  

**Note** : génération initiale assemblée localement (aucun outillage obligatoire pour rejouer les blocs de code : relecture de l’arbre + `diff -u /dev/null`).

---

## 17. `git status --short` (avant `git add` de ce seul rapport)

```text
?? reports/surface/surface_engine_lot_21b_surface_model_entrypoint_evidence_fix.md
```

---

*Fin — Lot 21-bis*
