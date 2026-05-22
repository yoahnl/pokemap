# ShadowV2-62 — Projected Building Shadow Adaptive Depth Preset Model V0

## 1. Résumé exécutif

ShadowV2-62 ajoute `footprintStrategy` optionnel à `ProjectBuildingShadowPreset` en conservant le chemin fixed legacy existant.

Résultat :

- `geometryMode.directional` rejette maintenant `footprint` et `footprintStrategy`.
- `geometryMode.footprint` avec `footprintStrategy == null` continue d’exiger `footprint`.
- `geometryMode.footprint` accepte `ProjectedShadowFootprintAdaptiveDepthTuning` seulement si `footprint == null`.
- `ProjectedShadowFootprintFixedTuning` est rejeté dans le preset V0 pour éviter une double source de vérité fixed.
- `footprintStrategy` est inclus dans `operator ==` et `hashCode`.
- Aucun resolver, JSON, runtime, editor, diagnostics, screenshot, baseline ou generated file n’a été modifié.

## 2. Objectif du lot

Objectif exact exécuté :

```text
Ajouter un champ optionnel footprintStrategy à ProjectBuildingShadowPreset,
avec compatibilité fixed legacy,
sans supprimer le champ footprint,
sans modifier JSON/persistence,
sans modifier le resolver géométrique,
sans modifier runtime/editor,
sans modifier renderer/painter,
sans Selbrume,
sans screenshot,
sans baseline.
```

## 3. Rappel ShadowV2-61

ShadowV2-61 a retenu l’intégration progressive :

- `geometryMode` reste `footprint`.
- Aucun `adaptiveFootprint` n’est ajouté.
- `footprint` reste la source fixed legacy en V0.
- `footprintStrategy` devient la source adaptive.
- `fixed legacy = footprint != null + footprintStrategy == null`.
- `adaptive = footprint == null + footprintStrategy is ProjectedShadowFootprintAdaptiveDepthTuning`.
- `appearance.colorHexRgb` reste commun.
- `appearance.opacity` reste fixed/fallback pour fixed legacy.
- L’opacité adaptive reste portée par `baseOpacity` / `targetOpacity`.
- JSON/persistence, resolver géométrique et guard building/largeVolume restent hors scope.

## 4. État initial du worktree

Commande initiale :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Sortie :

```text
```

Interprétation :

- Fichiers préexistants non liés au lot : Aucun.
- Fichiers ShadowV2 précédents non suivis avant ShadowV2-62 : Aucun.
- Changements hors scope présents avant ShadowV2-62 : Aucun.

## 5. Lecture AGENTS.md et méthode suivie

Commandes exécutées :

```bash
cd /Users/karim/Project/pokemonProject
find .. -name AGENTS.md -print
sed -n '1,320p' AGENTS.md
```

Sortie `find` :

```text
../pokemonProject-worktree/AGENTS.md
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Instructions retenues depuis `AGENTS.md` :

- `map_core` est un package Dart pur.
- Les changements doivent rester minimaux et strictement liés au lot.
- Les opérations Git d’écriture sont interdites.
- Les rapports de lot doivent inclure inventaire, commandes, résultats exacts, limites et auto-critique.
- Les fichiers créés/modifiés doivent être réconciliés avec `git status --short --untracked-files=all`.
- Les tests ciblés puis les tests élargis sont attendus.

Méthode réellement suivie :

- Pass 1 — Audit modèle / tests existants.
- Pass 2 — Tests RED sur le nouveau comportement `footprintStrategy`.
- Pass 3 — Implémentation modèle V0 limitée à `ProjectBuildingShadowPreset`.
- Pass 4 — Tests, analyze, audit anti-dérive, Git final, rapport.

Skills utilisés conformément à `AGENTS.md` :

- `superpowers:using-superpowers`.
- `karpathy-guidelines`.
- `superpowers:test-driven-development`.
- `dart-add-unit-test`.
- `dart-run-static-analysis`.
- `superpowers:systematic-debugging` pour le chemin de test inexistant demandé.
- `superpowers:verification-before-completion`.

## 6. Fichiers créés / modifiés / supprimés

Fichiers modifiés par ShadowV2-62 :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart
```

Fichiers créés par ShadowV2-62 :

```text
packages/map_core/test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart
reports/shadows/v2/shadow_v2_62_projected_building_shadow_adaptive_depth_preset_model_v0.md
```

Fichiers supprimés par ShadowV2-62 :

```text
Aucun
```

Fichiers hors scope modifiés par ShadowV2-62 :

```text
Aucun
```

## 7. Audit initial

Commandes d’audit exécutées avant modification :

```bash
rg -n "class ProjectBuildingShadowPreset|ProjectBuildingShadowPreset|ProjectedBuildingShadowGeometryMode|geometryMode|footprint|footprintStrategy|ProjectedShadowFootprintTuning|ProjectedShadowFootprintTuningStrategy|ProjectedShadowFootprintFixedTuning|ProjectedShadowFootprintAdaptiveDepthTuning|appearance|timeOfDayMode|categoryId|sortOrder|operator ==|hashCode|_validateProjectedBuildingShadowGeometryMode" packages/map_core/lib/src/models/projected_building_shadow.dart packages/map_core/test/shadow_v2

rg -n "resolveProjectedShadowFootprintEffectiveTuning|ProjectedShadowFootprintEffectiveTuningResult|ProjectedShadowEffectiveFootprintTuning|ProjectedShadowFootprintEffectiveTuningResolved|ProjectedShadowFootprintEffectiveTuningBlocked|fixedOpacity|adaptiveT|strategyKind|ProjectedBuildingShadowCasterKind|ProjectedShadowFootprintTuningStrategy" packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart packages/map_core/test/shadow_v2/projected_shadow_footprint_effective_tuning_test.dart reports/shadows/v2/shadow_v2_60_projected_building_shadow_adaptive_depth_effective_tuning_resolver_v0.md

rg -n "ProjectBuildingShadowPreset JSON|encodeProjectBuildingShadowPreset|decodeProjectBuildingShadowPreset|geometryMode|footprint|footprintStrategy|appearance|opacity|colorHexRgb|categoryId|sortOrder|projectedBuildingShadowCatalog|round-trips|unknown|omits|toJson|fromJson" packages/map_core/lib/src/operations packages/map_core/test/shadow_v2

rg -n "ProjectElementEntry|ProjectElementProjectedBuildingShadowConfig|projectedBuildingShadow|ProjectBuildingShadowPresetCatalog|projectedBuildingShadowCatalog|diagnoseProjectedBuildingShadows|missing preset|unused preset|V1|V2|categoryId|presetKind|casterKind|building|largeVolume" packages/map_core/lib/src/models packages/map_core/lib/src/operations packages/map_core/test/shadow_v2
```

Résumé audit :

- `ProjectBuildingShadowPreset` contenait déjà `geometryMode` et `footprint`, mais pas `footprintStrategy`.
- `_validateProjectedBuildingShadowGeometryMode` faisait uniquement la validation `directional => footprint null` et `footprint => footprint required`.
- Les stratégies `ProjectedShadowFootprintTuningStrategy`, `ProjectedShadowFootprintFixedTuning` et `ProjectedShadowFootprintAdaptiveDepthTuning` existaient déjà.
- L’opération pure Lot 60 existait déjà et reste hors scope du Lot 62.
- Les codecs JSON actuels ne persistent pas `footprintStrategy`.
- `ProjectElementProjectedBuildingShadowConfig` ne porte pas encore `casterKind`.
- Les diagnostics actuels ne traitent pas encore le guard adaptive.

## 8. Champ footprintStrategy ajouté

Champ ajouté dans `ProjectBuildingShadowPreset` :

```dart
ProjectedShadowFootprintTuningStrategy? footprintStrategy
```

Caractéristiques :

- optionnel ;
- `final` ;
- transmis au constructeur privé ;
- exposé comme propriété publique immutable ;
- inclus dans la validation du preset ;
- inclus dans `operator ==` ;
- inclus dans `hashCode`.

## 9. Compatibilité fixed legacy

Le chemin fixed legacy reste :

```text
geometryMode == ProjectedBuildingShadowGeometryMode.footprint
footprint != null
footprintStrategy == null
```

Le test ciblé vérifie :

- `footprint` reste la source de vérité fixed legacy ;
- `footprintStrategy` reste `null` pour un preset fixed legacy ;
- les tests existants de footprint tuning et geometry restent verts.

## 10. Adaptive footprintStrategy behavior

Le nouveau chemin adaptive V0 est :

```text
geometryMode == ProjectedBuildingShadowGeometryMode.footprint
footprint == null
footprintStrategy is ProjectedShadowFootprintAdaptiveDepthTuning
```

Le modèle ne calcule aucun tuning effectif.

Le modèle ne branche pas :

- `resolveProjectedBuildingShadowGeometry(...)` ;
- `resolveProjectedShadowFootprintEffectiveTuning(...)` ;
- `ProjectElementProjectedBuildingShadowConfig` ;
- JSON ;
- runtime/editor.

## 11. Validations ProjectBuildingShadowPreset

Validations finales :

```text
directional + footprint != null -> rejet
directional + footprintStrategy != null -> rejet
footprint + footprint == null + footprintStrategy == null -> rejet
footprint + footprint != null + footprintStrategy == null -> accepté
footprint + footprint == null + adaptive strategy -> accepté
footprint + footprint != null + adaptive strategy -> rejet
footprint + fixed strategy -> rejet
```

La stratégie fixed est volontairement rejetée dans `ProjectBuildingShadowPreset` V0, car le fixed legacy reste porté par `footprint`.

## 12. Equality / hashCode

`operator ==` compare désormais :

```text
id
name
direction
shape
appearance
timeOfDayMode
geometryMode
footprint
footprintStrategy
categoryId
sortOrder
```

`hashCode` inclut désormais `footprintStrategy`.

Les tests ciblés vérifient deux presets adaptive identiques et un preset adaptive variant.

## 13. Appearance / opacity policy

`ProjectedShadowAppearance` n’a pas été modifié.

Politique V0 documentée :

- `appearance.colorHexRgb` reste commun fixed/adaptive.
- `appearance.opacity` reste obligatoire car le modèle appearance l’exige.
- Pour fixed legacy, `appearance.opacity` reste le `fixedOpacity`.
- Pour adaptive, `appearance.opacity` est un fallback/compat non source effective.
- Pour adaptive, les sources effectives futures sont `baseOpacity` et `targetOpacity` dans `ProjectedShadowFootprintAdaptiveDepthTuning`.

## 14. Ce qui n’a volontairement pas été branché

Non branché :

- resolver géométrique ;
- opération effective Lot 60 ;
- `ProjectBuildingShadowPreset` JSON ;
- catalog JSON ;
- diagnostics ;
- `ProjectElementProjectedBuildingShadowConfig`;
- `ProjectElementEntry`;
- `MapPlacedElement`;
- runtime ;
- editor ;
- renderer/painter ;
- guard `ProjectedBuildingShadowCasterKind`;
- screenshot/baseline ;
- Selbrume.

## 15. Résultats tests ciblés

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart
```

Sortie :

```text
00:00 +0: loading test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart
00:00 +0: ProjectBuildingShadowPreset footprintStrategy legacy footprint fixed keeps footprint as source of truth
00:00 +1: ProjectBuildingShadowPreset footprintStrategy legacy footprint fixed keeps footprint as source of truth
00:00 +1: ProjectBuildingShadowPreset footprintStrategy legacy footprint fixed keeps footprintStrategy null
00:00 +2: ProjectBuildingShadowPreset footprintStrategy legacy footprint fixed keeps footprintStrategy null
00:00 +2: ProjectBuildingShadowPreset footprintStrategy directional rejects footprintStrategy
00:00 +3: ProjectBuildingShadowPreset footprintStrategy directional rejects footprintStrategy
00:00 +3: ProjectBuildingShadowPreset footprintStrategy directional still rejects footprint
00:00 +4: ProjectBuildingShadowPreset footprintStrategy directional still rejects footprint
00:00 +4: ProjectBuildingShadowPreset footprintStrategy directional accepts no footprint and no footprintStrategy
00:00 +5: ProjectBuildingShadowPreset footprintStrategy directional accepts no footprint and no footprintStrategy
00:00 +5: ProjectBuildingShadowPreset footprintStrategy footprint rejects missing footprint and missing footprintStrategy
00:00 +6: ProjectBuildingShadowPreset footprintStrategy footprint rejects missing footprint and missing footprintStrategy
00:00 +6: ProjectBuildingShadowPreset footprintStrategy footprint accepts adaptive footprintStrategy with null footprint
00:00 +7: ProjectBuildingShadowPreset footprintStrategy footprint accepts adaptive footprintStrategy with null footprint
00:00 +7: ProjectBuildingShadowPreset footprintStrategy footprint adaptive rejects non-null footprint
00:00 +8: ProjectBuildingShadowPreset footprintStrategy footprint adaptive rejects non-null footprint
00:00 +8: ProjectBuildingShadowPreset footprintStrategy footprint rejects fixed footprintStrategy in V0
00:00 +9: ProjectBuildingShadowPreset footprintStrategy footprint rejects fixed footprintStrategy in V0
00:00 +9: ProjectBuildingShadowPreset footprintStrategy equality includes footprintStrategy
00:00 +10: ProjectBuildingShadowPreset footprintStrategy equality includes footprintStrategy
00:00 +10: ProjectBuildingShadowPreset footprintStrategy hashCode includes footprintStrategy
00:00 +11: ProjectBuildingShadowPreset footprintStrategy hashCode includes footprintStrategy
00:00 +11: All tests passed!
```

TDD RED observé avant l’implémentation :

```text
Getter not found: 'footprintStrategy'
No named parameter with the name 'footprintStrategy'
```

## 16. Résultats régressions utiles

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart
```

Sortie :

```text
00:00 +13: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2/projected_building_shadow_geometry_test.dart
```

Sortie :

```text
00:00 +17: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2/projected_shadow_footprint_strategy_test.dart
```

Sortie :

```text
00:00 +24: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2/projected_shadow_footprint_effective_tuning_test.dart
```

Sortie :

```text
00:00 +18: All tests passed!
```

Commande demandée :

```bash
cd packages/map_core && dart test test/shadow_v2/project_building_shadow_preset_test.dart
```

Sortie :

```text
Failed to load "test/shadow_v2/project_building_shadow_preset_test.dart": Does not exist.
```

Investigation :

- Le fichier demandé n’existe pas dans le repo.
- Le fichier réel est `test/shadow_v2/projected_building_shadow_preset_test.dart`.
- Aucun fichier n’a été créé ou renommé pour contourner ce point.

Commande réelle exécutée pour la régression correspondante :

```bash
cd packages/map_core && dart test test/shadow_v2/projected_building_shadow_preset_test.dart
```

Sortie :

```text
00:00 +15: All tests passed!
```

## 17. Résultat dart test test/shadow_v2

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2
```

Sortie finale :

```text
00:00 +221: All tests passed!
```

Le groupe a été relancé après la dernière retouche de helper de test.

## 18. Résultat analyze

Commande :

```bash
cd packages/map_core && dart analyze lib/src/models/projected_building_shadow.dart test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart
```

Sortie :

```text
Analyzing projected_building_shadow.dart, project_building_shadow_preset_footprint_strategy_test.dart...
No issues found!
```

## 19. Audit anti-dérive

Commande :

```bash
rg -n "adaptiveFootprint|genericProjection|matchesGoldenFile|reports/shadows/baselines|SHADOW_SCREENSHOT|selbrume|build_runner|toJson|fromJson|Json|json|runtime|editor|resolveProjectedBuildingShadowGeometry\(|resolveProjectedShadowFootprintEffectiveTuning\(" packages/map_core/lib/src/models/projected_building_shadow.dart packages/map_core/test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart
```

Sortie :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart:10:/// inspect the clock, or affect runtime rendering.
packages/map_core/lib/src/models/projected_building_shadow.dart:28:/// The raw values are intentionally preserved so the editor can keep the
packages/map_core/lib/src/models/projected_building_shadow.dart:452:/// This model is intentionally not connected to JSON, manifests, runtime
packages/map_core/lib/src/models/projected_building_shadow.dart:453:/// resolution, or editor UI in ShadowV2-5.
packages/map_core/lib/src/models/projected_building_shadow.dart:557:/// manifest integration, default presets, editor behavior, or runtime behavior.
packages/map_core/lib/src/models/projected_building_shadow.dart:640:/// ProjectElementEntry, JSON, manifests, runtime resolution, or editor UI.
```

Justification des hits :

- Tous les hits proviennent de commentaires préexistants dans `projected_building_shadow.dart`.
- Aucun hit dans le nouveau test.
- Aucun hit sur `adaptiveFootprint`, `matchesGoldenFile`, baseline, screenshot, Selbrume, build_runner, JSON codec ajouté, runtime/editor ajouté, resolver géométrique, ou opération effective.

## 20. Ce qui n’a volontairement pas été modifié

Non modifié :

```text
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart
packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart
packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart
packages/map_core/lib/src/operations/projected_shadow_value_object_json_codecs.dart
packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/map_data.dart
packages/map_runtime/**
packages/map_editor/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
reports/shadows/screenshots/**
reports/shadows/baselines/**
/Users/karim/Desktop/selbrume/**
project.json
```

## 21. Ce qui n’a volontairement pas été créé

Non créé :

```text
*.g.dart
*.freezed.dart
*.golden
baseline_manifest.json
renderer
painter
codec JSON
migration
fixture Selbrume
screenshot
image
```

## 22. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text
 .../lib/src/models/projected_building_shadow.dart  | 32 ++++++++++++++++++++--
 1 file changed, 29 insertions(+), 3 deletions(-)
```

Note : les fichiers non suivis apparaissent dans `git status`.

## 23. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie :

```text
M	packages/map_core/lib/src/models/projected_building_shadow.dart
```

## 24. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text
```

## 25. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale :

```text
 M packages/map_core/lib/src/models/projected_building_shadow.dart
?? packages/map_core/test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart
?? reports/shadows/v2/shadow_v2_62_projected_building_shadow_adaptive_depth_preset_model_v0.md
```

## 26. Risques / réserves

- `footprintStrategy` n’est pas encore sérialisé : tout preset adaptive en mémoire reste non persistant.
- Le guard building/largeVolume n’est pas encore branché au modèle élément : un lot ultérieur doit décider et implémenter cette protection.
- Le resolver géométrique ne consomme pas encore `footprintStrategy`.
- `appearance.opacity` reste obligatoire pour le preset adaptive, mais n’est pas source effective adaptive.

## 27. Auto-critique

- Le lot est limité au modèle `ProjectBuildingShadowPreset` : oui.
- Le resolver géométrique est intact : oui.
- L’opération effective est intacte : oui.
- JSON/persistence est hors scope : oui.
- Runtime/editor sont hors scope : oui.
- Le fixed legacy reste compatible : oui, `footprint` reste requis quand `footprintStrategy == null`.
- L’adaptive évite la double source `footprint + footprintStrategy` : oui, cette combinaison est rejetée.
- Le fixed strategy est rejeté en V0 : oui.
- Les tests existants restent verts : oui, `dart test test/shadow_v2` passe avec `+221`.
- Le rapport contient l’inventaire, les commandes, les résultats, le diff et le code créé/modifié.

## 28. Regard critique sur le prompt

Le prompt est très strict et protège bien le scope. Le seul point incohérent observé est le chemin de régression demandé `test/shadow_v2/project_building_shadow_preset_test.dart`, qui n’existe pas. La régression équivalente correcte est `test/shadow_v2/projected_building_shadow_preset_test.dart`, exécutée et verte.

## 29. Prochain lot recommandé

Prochain lot recommandé :

```text
ShadowV2-63 — Projected Building Shadow Caster Kind Element Guard Design Gate
```

Objectif probable :

```text
Définir où intégrer ProjectedBuildingShadowCasterKind pour protéger les presets adaptive :
- ProjectElementProjectedBuildingShadowConfig ;
- ProjectElementEntry ;
- autre modèle voisin ;
- diagnostics ;
sans implémenter encore ou avec un V0 très limité selon la décision.
```

Ne pas faire au Lot 63 sans nouveau contrat explicite :

- brancher le resolver géométrique ;
- modifier JSON ;
- modifier runtime/editor ;
- créer screenshot/baseline ;
- traiter les props fins comme support officiel.

## 30. Code complet des fichiers créés/modifiés

### Diff complet — `packages/map_core/lib/src/models/projected_building_shadow.dart`

```diff
diff --git a/packages/map_core/lib/src/models/projected_building_shadow.dart b/packages/map_core/lib/src/models/projected_building_shadow.dart
index a985b2ac..e0bd7ec9 100644
--- a/packages/map_core/lib/src/models/projected_building_shadow.dart
+++ b/packages/map_core/lib/src/models/projected_building_shadow.dart
@@ -463,6 +463,7 @@ final class ProjectBuildingShadowPreset {
     ProjectedBuildingShadowGeometryMode geometryMode =
         ProjectedBuildingShadowGeometryMode.directional,
     ProjectedShadowFootprintTuning? footprint,
+    ProjectedShadowFootprintTuningStrategy? footprintStrategy,
     String? categoryId,
     int sortOrder = 0,
   }) {
@@ -475,6 +476,7 @@ final class ProjectBuildingShadowPreset {
     _validateProjectedBuildingShadowGeometryMode(
       geometryMode: geometryMode,
       footprint: footprint,
+      footprintStrategy: footprintStrategy,
     );
     return ProjectBuildingShadowPreset._(
       id: id,
@@ -485,6 +487,7 @@ final class ProjectBuildingShadowPreset {
       timeOfDayMode: timeOfDayMode,
       geometryMode: geometryMode,
       footprint: footprint,
+      footprintStrategy: footprintStrategy,
       categoryId: categoryId,
       sortOrder: sortOrder,
     );
@@ -499,6 +502,7 @@ final class ProjectBuildingShadowPreset {
     required this.timeOfDayMode,
     required this.geometryMode,
     required this.footprint,
+    required this.footprintStrategy,
     required this.categoryId,
     required this.sortOrder,
   });
@@ -511,6 +515,7 @@ final class ProjectBuildingShadowPreset {
   final ProjectedShadowTimeOfDayMode timeOfDayMode;
   final ProjectedBuildingShadowGeometryMode geometryMode;
   final ProjectedShadowFootprintTuning? footprint;
+  final ProjectedShadowFootprintTuningStrategy? footprintStrategy;
   final String? categoryId;
   final int sortOrder;
 
@@ -526,6 +531,7 @@ final class ProjectBuildingShadowPreset {
           other.timeOfDayMode == timeOfDayMode &&
           other.geometryMode == geometryMode &&
           other.footprint == footprint &&
+          other.footprintStrategy == footprintStrategy &&
           other.categoryId == categoryId &&
           other.sortOrder == sortOrder;
 
@@ -539,6 +545,7 @@ final class ProjectBuildingShadowPreset {
         timeOfDayMode,
         geometryMode,
         footprint,
+        footprintStrategy,
         categoryId,
         sortOrder,
       );
@@ -724,6 +731,7 @@ void _validatePositiveRatioMax(double value, String name, double max) {
 void _validateProjectedBuildingShadowGeometryMode({
   required ProjectedBuildingShadowGeometryMode geometryMode,
   required ProjectedShadowFootprintTuning? footprint,
+  required ProjectedShadowFootprintTuningStrategy? footprintStrategy,
 }) {
   switch (geometryMode) {
     case ProjectedBuildingShadowGeometryMode.directional:
@@ -732,12 +740,30 @@ void _validateProjectedBuildingShadowGeometryMode({
           'ProjectBuildingShadowPreset.footprint must be null for directional geometry',
         );
       }
-    case ProjectedBuildingShadowGeometryMode.footprint:
-      if (footprint == null) {
+      if (footprintStrategy != null) {
         throw const ValidationException(
-          'ProjectBuildingShadowPreset.footprint is required for footprint geometry',
+          'ProjectBuildingShadowPreset.footprintStrategy must be null for directional geometry',
         );
       }
+    case ProjectedBuildingShadowGeometryMode.footprint:
+      switch (footprintStrategy) {
+        case null:
+          if (footprint == null) {
+            throw const ValidationException(
+              'ProjectBuildingShadowPreset.footprint is required for footprint geometry',
+            );
+          }
+        case ProjectedShadowFootprintFixedTuning():
+          throw const ValidationException(
+            'ProjectBuildingShadowPreset.footprintStrategy fixed tuning is not supported in preset V0',
+          );
+        case ProjectedShadowFootprintAdaptiveDepthTuning():
+          if (footprint != null) {
+            throw const ValidationException(
+              'ProjectBuildingShadowPreset.footprint must be null when adaptive footprintStrategy is used',
+            );
+          }
+      }
   }
 }
```

### Contenu complet — `packages/map_core/test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectBuildingShadowPreset footprintStrategy', () {
    test('legacy footprint fixed keeps footprint as source of truth', () {
      final footprint = _legacyFootprint();
      final preset = _legacyFootprintPreset(footprint: footprint);

      expect(
          preset.geometryMode, ProjectedBuildingShadowGeometryMode.footprint);
      expect(preset.footprint, footprint);
    });

    test('legacy footprint fixed keeps footprintStrategy null', () {
      final preset = _legacyFootprintPreset();

      expect(preset.footprintStrategy, isNull);
    });

    test('directional rejects footprintStrategy', () {
      expect(
        () => _directionalPreset(footprintStrategy: _adaptiveStrategy()),
        throwsA(isA<ValidationException>()),
      );
    });

    test('directional still rejects footprint', () {
      expect(
        () => _directionalPreset(footprint: _legacyFootprint()),
        throwsA(isA<ValidationException>()),
      );
    });

    test('directional accepts no footprint and no footprintStrategy', () {
      final preset = _directionalPreset();

      expect(
          preset.geometryMode, ProjectedBuildingShadowGeometryMode.directional);
      expect(preset.footprint, isNull);
      expect(preset.footprintStrategy, isNull);
    });

    test('footprint rejects missing footprint and missing footprintStrategy',
        () {
      expect(
        () => ProjectBuildingShadowPreset(
          id: 'shadow',
          name: 'Shadow',
          direction: _direction(),
          shape: _shape(),
          appearance: _appearance(),
          timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
          geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('footprint accepts adaptive footprintStrategy with null footprint',
        () {
      final strategy = _adaptiveStrategy();
      final preset = _adaptivePreset(footprintStrategy: strategy);

      expect(
          preset.geometryMode, ProjectedBuildingShadowGeometryMode.footprint);
      expect(preset.footprint, isNull);
      expect(preset.footprintStrategy, strategy);
    });

    test('footprint adaptive rejects non-null footprint', () {
      expect(
        () => _adaptivePreset(
          footprint: _legacyFootprint(),
          footprintStrategy: _adaptiveStrategy(),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('footprint rejects fixed footprintStrategy in V0', () {
      expect(
        () => _adaptivePreset(
          footprintStrategy: ProjectedShadowFootprintFixedTuning(
            tuning: _legacyFootprint(),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('equality includes footprintStrategy', () {
      final first = _adaptivePreset(
        footprintStrategy: _adaptiveStrategy(),
      );
      final same = _adaptivePreset(
        footprintStrategy: _adaptiveStrategy(),
      );
      final changed = _adaptivePreset(
        footprintStrategy: _adaptiveStrategyVariant(),
      );

      expect(first, same);
      expect(first, isNot(changed));
    });

    test('hashCode includes footprintStrategy', () {
      final first = _adaptivePreset(
        footprintStrategy: _adaptiveStrategy(),
      );
      final same = _adaptivePreset(
        footprintStrategy: _adaptiveStrategy(),
      );
      final changed = _adaptivePreset(
        footprintStrategy: _adaptiveStrategyVariant(),
      );

      expect(first.hashCode, same.hashCode);
      expect(first.hashCode, isNot(changed.hashCode));
    });
  });
}

ProjectedShadowDirection _direction() {
  return ProjectedShadowDirection(x: 1, y: 0);
}

ProjectedShadowShapeTuning _shape() {
  return ProjectedShadowShapeTuning(
    lengthRatio: 0.5,
    nearWidthRatio: 1,
    farWidthRatio: 0.5,
  );
}

ProjectedShadowAppearance _appearance() {
  return ProjectedShadowAppearance(opacity: 0.24, colorHexRgb: '606060');
}

ProjectedShadowFootprintTuning _legacyFootprint() {
  return ProjectedShadowFootprintTuning(
    attachYRatio: 0.82,
    frontWidthRatio: 1.30,
    rearWidthRatio: 1.42,
    depthRatio: 0.26,
    skewXRatio: 0.08,
  );
}

ProjectedShadowFootprintTuning _targetFootprint() {
  return ProjectedShadowFootprintTuning(
    attachYRatio: 0.80,
    frontWidthRatio: 1.30,
    rearWidthRatio: 1.47,
    depthRatio: 0.42,
    skewXRatio: 0.08,
  );
}

ProjectedShadowFootprintAdaptiveDepthTuning _adaptiveStrategy() {
  return ProjectedShadowFootprintAdaptiveDepthTuning(
    base: _legacyFootprint(),
    target: _targetFootprint(),
    gate: ProjectedShadowAdaptiveDepthGate(),
    baseOpacity: 0.24,
    targetOpacity: 0.22,
  );
}

ProjectedShadowFootprintAdaptiveDepthTuning _adaptiveStrategyVariant() {
  return ProjectedShadowFootprintAdaptiveDepthTuning(
    base: _legacyFootprint(),
    target: ProjectedShadowFootprintTuning(
      attachYRatio: 0.80,
      frontWidthRatio: 1.30,
      rearWidthRatio: 1.48,
      depthRatio: 0.42,
      skewXRatio: 0.08,
    ),
    gate: ProjectedShadowAdaptiveDepthGate(),
    baseOpacity: 0.24,
    targetOpacity: 0.22,
  );
}

ProjectBuildingShadowPreset _directionalPreset({
  ProjectedShadowFootprintTuning? footprint,
  ProjectedShadowFootprintTuningStrategy? footprintStrategy,
}) {
  return ProjectBuildingShadowPreset(
    id: 'shadow',
    name: 'Shadow',
    direction: _direction(),
    shape: _shape(),
    appearance: _appearance(),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
    footprint: footprint,
    footprintStrategy: footprintStrategy,
  );
}

ProjectBuildingShadowPreset _legacyFootprintPreset({
  ProjectedShadowFootprintTuning? footprint,
}) {
  return ProjectBuildingShadowPreset(
    id: 'shadow',
    name: 'Shadow',
    direction: _direction(),
    shape: _shape(),
    appearance: _appearance(),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
    geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
    footprint: footprint ?? _legacyFootprint(),
  );
}

ProjectBuildingShadowPreset _adaptivePreset({
  ProjectedShadowFootprintTuning? footprint,
  required ProjectedShadowFootprintTuningStrategy footprintStrategy,
}) {
  return ProjectBuildingShadowPreset(
    id: 'shadow',
    name: 'Shadow',
    direction: _direction(),
    shape: _shape(),
    appearance: _appearance(),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
    geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
    footprint: footprint,
    footprintStrategy: footprintStrategy,
  );
}
```

Checklist finale :

- [x] AGENTS.md lu
- [x] Aucun git write effectué
- [x] Aucun fichier runtime modifié
- [x] Aucun fichier editor modifié
- [x] Aucun resolver géométrique modifié
- [x] Aucune opération effective modifiée
- [x] Aucun JSON/codec modifié
- [x] Aucun generated créé
- [x] Aucun screenshot créé
- [x] Aucune baseline créée
- [x] footprintStrategy ajouté
- [x] footprintStrategy optionnel
- [x] Directional rejette footprintStrategy
- [x] Directional rejette toujours footprint
- [x] Fixed legacy footprint reste valide
- [x] Footprint missing footprint + missing strategy rejeté
- [x] Adaptive strategy accepte footprint null
- [x] Adaptive strategy rejette footprint non null
- [x] Fixed strategy rejetée dans preset V0
- [x] Equality inclut footprintStrategy
- [x] HashCode inclut footprintStrategy
- [x] Tests ciblés passés
- [x] Régressions utiles passées
- [x] dart test test/shadow_v2 passé
- [x] Analyze ciblé OK
- [x] Evidence Pack complet
- [x] git diff --check propre
- [x] git status final conforme au scope ou fichiers hors scope documentés
