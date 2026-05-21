# Shadow-53 — Auto Shadow Policy Reconciliation / Selbrume Audit

## Résumé du lot

Shadow-53 a réconcilié les tests éditeur d’auto-shadow avec la politique `map_core` actuellement en vigueur, puis a audité le projet Selbrume externe en lecture seule.

Le lot ne modifie pas le rendu, le runtime, le canvas, Flame, les modèles persistants, les codecs JSON, ni `/Users/karim/Desktop/selbrume`.

Conclusion importante : les captures peuvent encore sembler mauvaises, mais le blocage immédiat côté code était une divergence de tests éditeur. Le fichier Selbrume contient déjà beaucoup de configs automatiques récentes, mais aussi quelques configs manuelles/family null et toutes les instances auditées ont `shadowOverride: null`. La suite logique doit être un lot de calibration visuelle ciblé sur le rendu/profils/familles, pas un nouveau réglage manuel d’instance.

## Design retenu

- Garder `map_core` comme source de vérité de la politique auto-shadow.
- Ne pas dupliquer une seconde politique dans `map_editor`.
- Aligner les attentes stale des tests wrappers éditeur sur les valeurs core actuelles.
- Ajouter une garde de parité entre `applyElementAutoShadowSuggestionsToProject(...)` côté éditeur et `applyElementAutoShadowPolicyToProject(...)` côté core.
- Auditer Selbrume en lecture seule avec `jq`.

## Fichiers créés par Shadow-53

- `reports/shadows/shadow_lot_53_auto_shadow_policy_reconciliation_selbrume_audit_plan.md`
- `reports/shadows/shadow_lot_53_auto_shadow_policy_reconciliation_selbrume_audit.md`

## Fichiers modifiés par Shadow-53

- `packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart`
- `packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart`

## Fichiers non modifiés explicitement

- `packages/map_core/lib/src/operations/element_auto_shadow_policy.dart`
- `packages/map_runtime/**`
- `packages/map_editor/lib/src/application/shadow/**`
- `packages/map_editor/lib/src/ui/canvas/**`
- `packages/map_core/lib/src/models/**`
- `packages/map_core/lib/src/operations/*json_codec*.dart`
- `/Users/karim/Desktop/selbrume/project.json`
- `/Users/karim/Desktop/selbrume/maps/Selbrume.json`

## Fichiers préexistants hors Shadow-53

Présents dans le worktree avant ou pendant Shadow-53, non modifiés par ce lot :

- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart`
- `packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart`
- `packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart`
- `packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart`
- `packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart`
- `packages/map_core/test/shadow/static_shadow_contact_ledge_geometry_test.dart`
- `reports/shadows/shadow_lot_52_building_contact_ledge_core_editor_parity.md`
- `reports/shadows/shadow_lot_52_building_contact_ledge_core_editor_parity_plan.md`

Changements battle/PSDK visibles pendant certaines lectures intermédiaires du worktree, mais absents du `git status` final :

- Aucun fichier battle/PSDK présent dans le dernier `git status --short --untracked-files=all`.

## Root cause

Les tests éditeur attendaient encore l’ancienne politique large :

- `tallThin`: `footprintWidthRatio 0.18`, `footprintHeightRatio 0.07`, `opacity 0.28`.
- `buildingLarge`: `anchorYRatio 0.92`, `footprintWidthRatio 0.82`, `footprintHeightRatio 0.12`, `scaleY 0.85`, `opacity 0.30`.
- `wideLow`: `anchorYRatio 0.95`, `footprintWidthRatio 0.72`, `footprintHeightRatio 0.10`, `scaleX 0.92`, `scaleY 0.75`, `opacity 0.27`.

`map_core` porte déjà la politique plus sobre :

- `tallThin`: `footprintWidthRatio 0.28`, `footprintHeightRatio 0.05`, `scaleX 0.80`, `scaleY 0.55`, `opacity 0.20`.
- `buildingLarge`: `anchorYRatio 0.98`, `footprintWidthRatio 0.60`, `footprintHeightRatio 0.06`, `scaleX 0.72`, `scaleY 0.48`, `opacity 0.20`.
- `wideLow`: `anchorYRatio 0.98`, `footprintWidthRatio 0.58`, `footprintHeightRatio 0.06`, `scaleX 0.74`, `scaleY 0.50`, `opacity 0.20`.

## Audit Selbrume

Commandes de lecture seule :

```bash
jq -r '.elements as $elements | ($elements | map(select(.shadow != null)) | length) as $withShadow | [$elements|length, $withShadow, (($elements|length) - $withShadow)] | @tsv' /Users/karim/Desktop/selbrume/project.json
```

Résultat :

```text
63	25	38
```

Interprétation : le projet contient 63 éléments, 25 ont une config shadow, 38 n’en ont pas.

```bash
jq -r '.elements[] | select(.shadow != null and (.shadow.family == null)) | [.id, .name, (.frames[0].source.width // "?"), (.frames[0].source.height // "?"), (.shadow.shadowProfileId // "null"), (.shadow.scaleX // "null"), (.shadow.scaleY // "null"), (.shadow.opacity // "null"), (.shadow.footprint.footprintWidthRatio // "null"), (.shadow.footprint.footprintHeightRatio // "null")] | @tsv' /Users/karim/Desktop/selbrume/project.json
```

Résultat :

```text
selbrume_maison_5	selbrume maison 5	7	6	default-ground-soft-ellipse	null	null	0.22	0.68	0.08
arbre_pixellab_1	arbre  pixelLab 1	7	7	default-ground-soft-ellipse	null	null	0.25	0.58	0.1
arbre_pixellab_2	arbre  pixelLab 2	5	8	default-ground-soft-ellipse	null	null	0.25	0.5	0.1
panneau	panneau	3	3	default-ground-wide-ellipse	0.92	0.75	0.27	0.72	0.1
```

Interprétation : quatre éléments utilisent encore des configs sans `family`, donc ils ne passent pas par les règles de projection family-aware récentes.

```bash
jq -r '[.. | objects | select(has("shadowOverride"))] as $placed | [$placed|length, ($placed|map(select(.shadowOverride != null))|length), ($placed|map(select(.shadowOverride == null))|length)] | @tsv' /Users/karim/Desktop/selbrume/maps/Selbrume.json
```

Résultat :

```text
2105	0	2105
```

Interprétation : 2105 instances placées portent un champ `shadowOverride`, mais aucune n’a d’override non-null. Les captures reflètent donc surtout les configs d’éléments source et la politique/projection globale.

## Tests rouges reproduits avant correction

```bash
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_suggestion_test.dart
```

Résultat utile :

```text
Expected: <0.18>
  Actual: <0.28>
test/application/shadow/element_auto_shadow_suggestion_test.dart 76:7

Expected: <0.92>
  Actual: <0.98>
test/application/shadow/element_auto_shadow_suggestion_test.dart 90:7

Expected: <0.95>
  Actual: <0.98>
test/application/shadow/element_auto_shadow_suggestion_test.dart 111:7

00:00 +13 -3: Some tests failed.
```

```bash
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_backfill_test.dart
```

Résultat utile :

```text
Expected: <0.18>
  Actual: <0.28>
test/application/shadow/element_auto_shadow_backfill_test.dart 39:7

Expected: <0.72>
  Actual: <0.58>
test/application/shadow/element_auto_shadow_backfill_test.dart 82:7

00:00 +11 -2: Some tests failed.
```

## Résultats après correction

```bash
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_suggestion_test.dart
```

Sortie complète utile :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart
00:00 +0: buildElementAutoShadowSuggestion returns null without compatible ground static profile
00:00 +1: buildElementAutoShadowSuggestion returns null for missing frames
00:00 +2: buildElementAutoShadowSuggestion returns null for invalid first frame source
00:00 +3: buildElementAutoShadowSuggestion returns null for micro decor that should not cast projected shadows
00:00 +4: buildElementAutoShadowSuggestion classifies tall thin elements as tallThin
00:00 +5: buildElementAutoShadowSuggestion classifies large buildings as buildingLarge
00:00 +6: buildElementAutoShadowSuggestion wide low needs enough surface to receive an automatic shadow
00:00 +7: buildElementAutoShadowSuggestion small square returns null under artistic V0 policy
00:00 +8: buildElementAutoShadowSuggestion default prop returns null under artistic V0 policy
00:00 +9: buildElementAutoShadowSuggestion prefers default compact profile for tallThin
00:00 +10: buildElementAutoShadowSuggestion falls back to custom compatible profile ids
00:00 +11: buildElementAutoShadowSuggestion all suggestions have castsShadow true
00:00 +12: buildElementAutoShadowSuggestion all suggestion footprints are non-null and valid
00:00 +13: buildElementAutoShadowSuggestion all suggestions carry a static shadow family
00:00 +14: buildElementAutoShadowSuggestion all suggestion opacities are within 0..1
00:00 +15: buildElementAutoShadowSuggestion all suggestion scaleX and scaleY are greater than zero
00:00 +16: All tests passed!
```

```bash
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_backfill_test.dart
```

Sortie complète utile :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart
00:00 +0: applyElementAutoShadowSuggestionsToProject applies suggestions to elements without shadow configs
00:00 +1: applyElementAutoShadowSuggestionsToProject replaces generic pre-footprint active shadows
00:00 +2: applyElementAutoShadowSuggestionsToProject preserves disabled shadows
00:00 +3: applyElementAutoShadowSuggestionsToProject preserves manual footprints and numeric overrides
00:00 +4: applyElementAutoShadowSuggestionsToProject clears recognized auto small square shadow when policy has no suggestion
00:00 +5: applyElementAutoShadowSuggestionsToProject clears genericProjection auto shadow when policy has no suggestion
00:00 +6: applyElementAutoShadowSuggestionsToProject clears recognized auto wide low shadow below safe threshold
00:00 +7: applyElementAutoShadowSuggestionsToProject preserves manual footprint even if no suggestion exists
00:00 +8: applyElementAutoShadowSuggestionsToProject preserves non-default existing profile ids present in catalog
00:00 +9: applyElementAutoShadowSuggestionsToProject replaces generic shadows with missing profile ids
00:00 +10: applyElementAutoShadowSuggestionsToProject adds default profiles when the catalog has no compatible profile
00:00 +11: applyElementAutoShadowSuggestionsToProject records skippedNoSuggestion for invalid element frames
00:00 +12: applyElementAutoShadowSuggestionsToProject preserves element order and non-shadow fields
00:00 +13: applyElementAutoShadowSuggestionsToProject editor wrapper stays in parity with core backfill operation
00:00 +14: All tests passed!
```

```bash
cd packages/map_editor && flutter test test/application/shadow
```

Ligne finale exacte :

```text
00:00 +96: All tests passed!
```

```bash
cd packages/map_core && dart test test/shadow/element_auto_shadow_policy_test.dart
```

Ligne finale exacte :

```text
00:00 +12: All tests passed!
```

```bash
cd packages/map_core && dart test test/shadow
```

Ligne finale exacte :

```text
00:00 +281: All tests passed!
```

```bash
cd packages/map_editor && flutter analyze lib/src/application/shadow test/application/shadow
```

Résultat exact :

```text
No issues found! (ran in 1.6s)
```

```bash
git diff --check
```

Résultat exact :

```text

```

## git diff --stat final

```text
 packages/map_core/lib/map_core.dart                |  1 +
 .../shadow/editor_static_shadow_preview.dart       | 30 ++++---
 .../shadow/editor_static_shadow_preview_test.dart  | 93 ++++++++++++++++++++--
 .../shadow/element_auto_shadow_backfill_test.dart  | 34 +++++++-
 .../element_auto_shadow_suggestion_test.dart       | 31 ++++----
 ...tic_placed_element_shadow_runtime_resolver.dart | 81 +------------------
 ...laced_element_shadow_runtime_resolver_test.dart | 66 ++++-----------
 7 files changed, 176 insertions(+), 160 deletions(-)
```

Cette sortie inclut des changements Shadow-52 préexistants encore non commités. Les rapports Shadow-53 et les fichiers non suivis ne sont pas inclus dans cette sortie `git diff --stat`, ils sont listés dans le `git status` final ci-dessous.

## git status final

```text
 M packages/map_core/lib/map_core.dart
 M packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
 M packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
 M packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart
 M packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart
 M packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
 M packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
?? packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart
?? packages/map_core/test/shadow/static_shadow_contact_ledge_geometry_test.dart
?? reports/shadows/shadow_lot_52_building_contact_ledge_core_editor_parity.md
?? reports/shadows/shadow_lot_52_building_contact_ledge_core_editor_parity_plan.md
?? reports/shadows/shadow_lot_53_auto_shadow_policy_reconciliation_selbrume_audit.md
?? reports/shadows/shadow_lot_53_auto_shadow_policy_reconciliation_selbrume_audit_plan.md
```

## Note sur Flutter startup lock

Un premier lancement parallèle de deux commandes Flutter a produit un incident de tooling :

```text
Waiting for another flutter command to release the startup lock...
Unable to delete file or directory at "/Users/karim/Project/pokemonProject/packages/map_editor/macos/Flutter/ephemeral/Packages/.packages". This may be due to the project being in a read-only volume. Consider relocating the project and trying again.
```

Les mêmes tests ont ensuite été relancés séquentiellement et ont reproduit les vrais échecs d’attentes stale.

## Non-objectifs respectés

- Aucun runtime modifié par Shadow-53.
- Aucun canvas modifié par Shadow-53.
- Aucun modèle persistant modifié par Shadow-53.
- Aucun codec JSON modifié par Shadow-53.
- Aucun changement Flame.
- Aucun changement dans le projet externe Selbrume.
- Aucun commit effectué.

## Risques et suite recommandée

Shadow-53 ne rend pas les ombres visuellement meilleures à lui seul. Il enlève un obstacle de cohérence et clarifie l’état réel.

Pour obtenir un rendu acceptable, le prochain lot doit calibrer visuellement la sortie finale, probablement en visant :

1. une projection beaucoup plus lisible pour bâtiments, panneaux, puits et lampadaires ;
2. une opacité minimale moins fragile après modulation globale ;
3. une règle de `family` obligatoire ou backfillée pour les éléments Selbrume encore `family: null` ;
4. un smoke visuel Selbrume centré sur quelques éléments représentatifs.

## Auto-review

- Ai-je modifié le renderer ? non.
- Ai-je modifié le runtime ? non.
- Ai-je modifié le canvas ? non.
- Ai-je modifié les modèles/codecs ? non.
- Ai-je reproduit les tests rouges avant correction ? oui.
- Ai-je corrigé la divergence stale des tests éditeur ? oui.
- Ai-je ajouté une garde de parité wrapper éditeur vs core ? oui.
- Ai-je audité Selbrume en lecture seule ? oui.
- Ai-je modifié Selbrume ? non.
- Ai-je créé une lumière globale ? non.
- Ai-je fait un commit ? non.

## Diff Shadow-53

```diff
diff --git a/packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart b/packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart
index 5f666715..96ad442e 100644
--- a/packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart
+++ b/packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart
@@ -38,7 +38,7 @@ void main() {
       );
       expect(
         result.project.elements[0].shadow!.footprint!.footprintWidthRatio,
-        0.18,
+        0.28,
       );
       expect(
         result.project.elements[1].shadow!.shadowProfileId,
@@ -50,7 +50,7 @@ void main() {
       );
       expect(
         result.project.elements[1].shadow!.footprint!.footprintWidthRatio,
-        0.82,
+        0.60,
       );
     });
 
@@ -81,7 +81,7 @@ void main() {
       expect(result.project.elements.single.shadow!.footprint, isNotNull);
       expect(
         result.project.elements.single.shadow!.footprint!.footprintWidthRatio,
-        0.72,
+        0.58,
       );
       expect(
         result.project.elements.single.shadow!.shadowProfileId,
@@ -427,6 +427,34 @@ void main() {
       expect(result.project.elements[0].shadow, isNotNull);
       expect(result.project.elements[1].shadow, isNotNull);
     });
+
+    test('editor wrapper stays in parity with core backfill operation', () {
+      final project = _project(
+        elements: [
+          _element(id: 'lamp', name: 'Lamp', width: 1, height: 4),
+          _element(
+            id: 'house',
+            name: 'House',
+            width: 4,
+            height: 3,
+            shadow: ProjectElementShadowConfig(
+              castsShadow: true,
+              shadowProfileId: 'default-ground-wide-ellipse',
+            ),
+          ),
+          _element(id: 'small', name: 'Small', width: 2, height: 2),
+        ],
+        shadowCatalog: _defaultCatalog(),
+      );
+
+      final editorResult = applyElementAutoShadowSuggestionsToProject(project);
+      final coreResult = applyElementAutoShadowPolicyToProject(project);
+
+      expect(editorResult.project, coreResult.project);
+      expect(editorResult.entries, coreResult.entries);
+      expect(
+          editorResult.addedDefaultProfiles, coreResult.addedDefaultProfiles);
+    });
   });
 }
 
diff --git a/packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart b/packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart
index 9b25f0a4..d55d4fb0 100644
--- a/packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart
+++ b/packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart
@@ -73,9 +73,11 @@ void main() {
       expect(suggestion.kind, ElementAutoShadowSuggestionKind.tallThin);
       expect(suggestion.config.shadowProfileId, 'default-ground-contact-blob');
       expect(suggestion.config.family, StaticShadowFamily.tallProp);
-      expect(suggestion.config.footprint!.footprintWidthRatio, 0.18);
-      expect(suggestion.config.footprint!.footprintHeightRatio, 0.07);
-      expect(suggestion.config.opacity, 0.28);
+      expect(suggestion.config.footprint!.footprintWidthRatio, 0.28);
+      expect(suggestion.config.footprint!.footprintHeightRatio, 0.05);
+      expect(suggestion.config.scaleX, 0.80);
+      expect(suggestion.config.scaleY, 0.55);
+      expect(suggestion.config.opacity, 0.20);
     });
 
     test('classifies large buildings as buildingLarge', () {
@@ -87,11 +89,12 @@ void main() {
       expect(suggestion.kind, ElementAutoShadowSuggestionKind.buildingLarge);
       expect(suggestion.config.shadowProfileId, 'default-ground-wide-ellipse');
       expect(suggestion.config.family, StaticShadowFamily.building);
-      expect(suggestion.config.footprint!.anchorYRatio, 0.92);
-      expect(suggestion.config.footprint!.footprintWidthRatio, 0.82);
-      expect(suggestion.config.footprint!.footprintHeightRatio, 0.12);
-      expect(suggestion.config.scaleY, 0.85);
-      expect(suggestion.config.opacity, 0.30);
+      expect(suggestion.config.footprint!.anchorYRatio, 0.98);
+      expect(suggestion.config.footprint!.footprintWidthRatio, 0.60);
+      expect(suggestion.config.footprint!.footprintHeightRatio, 0.06);
+      expect(suggestion.config.scaleX, 0.72);
+      expect(suggestion.config.scaleY, 0.48);
+      expect(suggestion.config.opacity, 0.20);
     });
 
     test('wide low needs enough surface to receive an automatic shadow', () {
@@ -108,12 +111,12 @@ void main() {
       expect(suggestion.kind, ElementAutoShadowSuggestionKind.wideLow);
       expect(suggestion.config.shadowProfileId, 'default-ground-wide-ellipse');
       expect(suggestion.config.family, StaticShadowFamily.compactProp);
-      expect(suggestion.config.footprint!.anchorYRatio, 0.95);
-      expect(suggestion.config.footprint!.footprintWidthRatio, 0.72);
-      expect(suggestion.config.footprint!.footprintHeightRatio, 0.10);
-      expect(suggestion.config.scaleX, 0.92);
-      expect(suggestion.config.scaleY, 0.75);
-      expect(suggestion.config.opacity, 0.27);
+      expect(suggestion.config.footprint!.anchorYRatio, 0.98);
+      expect(suggestion.config.footprint!.footprintWidthRatio, 0.58);
+      expect(suggestion.config.footprint!.footprintHeightRatio, 0.06);
+      expect(suggestion.config.scaleX, 0.74);
+      expect(suggestion.config.scaleY, 0.50);
+      expect(suggestion.config.opacity, 0.20);
     });
 
     test('small square returns null under artistic V0 policy', () {
```

## Plan créé

```markdown
# Shadow-53 — Auto Shadow Policy Reconciliation / Selbrume Audit Plan

## Objectif

Réconcilier la politique d’ombre automatique entre `map_core` et les tests éditeur, puis auditer pourquoi le rendu Selbrume reste incohérent côté projet réel.

Le symptôme visible n’est plus principalement une absence de pipeline : le runtime et l’éditeur savent consommer les footprints, les projections et les réglages globaux. Le problème restant observé est que les règles automatiques, les tests wrappers éditeur et les données persistées de Selbrume peuvent encore diverger.

## Hypothèse vérifiée avant correction

`map_core` contient déjà une politique plus sobre pour les familles automatiques :

- `tallThin` : empreinte plus fine, opacité plus basse ;
- `buildingLarge` : footprint beaucoup moins haut et moins large ;
- `wideLow` : footprint réduit.

Les tests éditeur `element_auto_shadow_suggestion_test.dart` et `element_auto_shadow_backfill_test.dart` attendent encore d’anciennes valeurs larges. Cela masque la vraie prochaine étape : appliquer ou auditer ces configs sur les données Selbrume persistées.

## Périmètre Shadow-53

### Autorisé

- Mettre à jour les tests éditeur d’auto-shadow pour les aligner sur la source de vérité `map_core`.
- Ajouter une garde de parité entre le wrapper éditeur et l’opération core de backfill.
- Auditer le projet Selbrume externe en lecture seule.
- Créer un rapport Shadow-53.

### Interdit

- Modifier le renderer.
- Modifier Flame ou `map_runtime`.
- Modifier la preview canvas.
- Modifier les modèles persistants ou codecs JSON.
- Modifier `/Users/karim/Desktop/selbrume/project.json`.
- Commit/push sans demande explicite.

## Étapes

1. Reproduire les tests rouges éditeur ciblés.
2. Aligner les attentes obsolètes sur la politique core actuelle.
3. Ajouter un test de parité backfill wrapper éditeur vs core.
4. Auditer Selbrume en lecture seule pour compter les shadows persistées et les signatures legacy.
5. Lancer les tests ciblés éditeur et core.
6. Créer un rapport factuel distinguant Shadow-52 préexistant, Shadow-53 et données Selbrume non modifiées.

## Critère de sortie

- Les tests d’auto-shadow éditeur ciblés passent.
- Le test `test/application/shadow` éditeur ne bloque plus sur les attentes obsolètes.
- Le rapport explique clairement pourquoi les captures peuvent encore rester mauvaises tant que les données Selbrume persistées n’ont pas été réconciliées ou backfillées.
```
