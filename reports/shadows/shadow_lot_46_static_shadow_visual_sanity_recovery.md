# Shadow-46 — Static Shadow Visual Sanity Recovery V0

## 1. Résumé du lot

Shadow-46 réduit les cas les plus visuellement absurdes du système d’ombres projetées :

- les micro-décors `1x1` et `1x2` ne reçoivent plus automatiquement une ombre projetée ;
- le runtime transmet et applique désormais `StaticShadowFamily` au calcul de projection statique ;
- la preview éditeur transmet et applique désormais `StaticShadowFamily` au calcul de projection statique ;
- `MapPlacedElementShadowOverride.family` gagne sur `ProjectElementShadowConfig.family` ;
- aucune API Flame, aucun nouveau component, aucun modèle persistant et aucun codec JSON ne sont modifiés.

Ce lot est un lot de récupération visuelle : il corrige le fait que les familles d’ombres créées dans les lots précédents n’étaient pas réellement prises en compte partout, et il évite que de tout petits éléments polluent la carte avec des losanges d’ombre.

## 2. Design retenu

Le lot garde les briques existantes :

- `resolveStaticShadowFamily(...)` ;
- `resolveStaticShadowFamilyProjectionSpec(...)` ;
- `resolveProjectedStaticShadowGeometry(...)` ;
- `StaticShadowFamily` sur l’ombre d’élément et l’override d’instance.

Le runtime reste dans son pipeline existant :

1. résolution de l’ombre source ;
2. résolution de la géométrie footprint ;
3. résolution de la projection polygonale ;
4. instruction runtime finale.

L’éditeur garde son builder de preview existant et ne dépend pas de `map_runtime`.

## 3. Fichiers créés par Shadow-46

- `reports/shadows/shadow_lot_46_static_shadow_visual_sanity_recovery_plan.md`
- `reports/shadows/shadow_lot_46_static_shadow_visual_sanity_recovery.md`

## 4. Fichiers modifiés par Shadow-46

- `packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart`
- `packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart`
- `packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart`
- `packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart`
- `packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart`
- `packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart`
- `packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart`
- `packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart`

Note honnête : `editor_static_shadow_preview.dart` et `editor_static_shadow_preview_test.dart` étaient déjà modifiés avant ce lot. Shadow-46 y ajoute seulement le branchement `StaticShadowFamily` dans la projection éditeur et les tests associés.

## 5. Fichiers hors lot présents dans le worktree

Fichiers `map_editor` déjà sales avant Shadow-46 et non modifiés par ce lot :

- `packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart`
- `packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart`

Fichiers hors lot observés au status final et non modifiés par Shadow-46 :

- Aucun fichier `map_battle`, `map_gameplay` ou host au dernier scan.

## 6. Correction auto-suggestion micro-décors

`buildElementAutoShadowSuggestion(...)` retourne maintenant `null` pour les éléments `1x1` et `1x2`.

Objectif : éviter que fleurs, petits détails, mini touffes ou fragments décoratifs reçoivent automatiquement des ombres projetées visibles sur la map.

Extrait modifié :

```dart
if (_isMicroDecor(
  width: source.width.toDouble(),
  height: source.height.toDouble(),
)) {
  return null;
}
```

Helper ajouté :

```dart
bool _isMicroDecor({
  required double width,
  required double height,
}) {
  return width <= 1 && height <= 2;
}
```

## 7. Runtime : transmission et application de `StaticShadowFamily`

`StaticPlacedElementShadowRuntimeInput` porte maintenant :

```dart
final StaticShadowFamily? elementFamily;
final StaticShadowFamily? overrideFamily;
```

Le resolver statique runtime appelle :

```dart
resolveStaticShadowFamilyProjectionSpec(
  family: resolveStaticShadowFamily(
    elementFamily: input.elementFamily,
    overrideFamily: input.overrideFamily,
  ),
)
```

Le collection builder transmet :

```dart
elementFamily: source.elementShadow?.family,
overrideFamily: source.placedOverride?.family,
```

Effet attendu : les familles `tallProp`, `compactProp`, `building`, etc. cessent d’être de simples métadonnées et changent réellement la silhouette projetée.

## 8. Editor preview : transmission et application de `StaticShadowFamily`

La preview éditeur conserve le preset de lumière local, puis le compose avec la famille :

```dart
projectionSpec: resolveStaticShadowFamilyProjectionSpec(
  family: resolveStaticShadowFamily(
    elementFamily: element.shadow?.family,
    overrideFamily: placed.shadowOverride?.family,
  ),
  baseProjectionSpec: _projectionSpecForEditorLightPreview(
    resolvedLightPreviewPreset,
  ),
),
```

Effet attendu : runtime et éditeur utilisent la même logique de famille, sans importer `map_runtime` dans `map_editor`.

## 9. Protection contre les régressions visuelles les plus évidentes

Tests ajoutés ou enrichis :

- micro-décors `1x1` / `1x2` sans suggestion automatique ;
- une famille élément change la silhouette projetée runtime ;
- une famille override gagne sur la famille élément runtime ;
- la collection runtime transmet bien les familles ;
- une famille élément change la silhouette projetée editor ;
- une famille override gagne sur la famille élément editor ;
- égalité/hashCode runtime incluent les familles.

## 10. Pourquoi ce lot ne rend pas encore les ombres “final Pokémon”

Ce lot corrige une incohérence importante, mais il ne suffit pas à lui seul pour atteindre le rendu de référence :

- il ne découpe pas les ombres à la silhouette exacte du sprite ;
- il ne fait pas de masque par bâtiment ;
- il ne gère pas encore les zones où une ombre devrait passer derrière ou devant certaines parties du décor ;
- il ne fait pas de hand-authored shadow mesh par élément ;
- il ne remplace pas les assets par de vraies ombres dessinées.

Il rend cependant le système beaucoup moins incohérent et prépare le lot suivant : sélectionner automatiquement de bonnes familles et désactiver les ombres projetées pour davantage de cas décoratifs.

## 11. Flame docs

Conformément à `AGENTS.md`, une recherche `flame_docs` a été effectuée avant de toucher au runtime :

- recherche : `Flame rendering custom Canvas drawPath component render order priority`
- résultat : aucune entrée retournée ;
- recherche : `Flame Component render priority Canvas`
- résultat : aucune entrée retournée.

Décision : Shadow-46 ne modifie aucun component Flame, aucun ordre de rendu et aucune API Flame. Le lot reste dans les resolvers et builders existants.

## 12. Commandes lancées

### Tests ciblés RED

```bash
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_suggestion_test.dart
```

Échec attendu avant implémentation :

```text
Expected: null
  Actual: <Instance of 'ElementAutoShadowSuggestion'>
00:00 +15 -1: Some tests failed.
```

```bash
cd packages/map_runtime && flutter test test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
```

Échec attendu avant implémentation :

```text
Error: No named parameter with the name 'elementFamily'.
The getter 'elementFamily' isn't defined for the type 'StaticPlacedElementShadowRuntimeInput'.
The getter 'overrideFamily' isn't defined for the type 'StaticPlacedElementShadowRuntimeInput'.
00:00 +0 -1: Some tests failed.
```

```bash
cd packages/map_editor && flutter test test/application/shadow/editor_static_shadow_preview_test.dart
```

Échec attendu avant implémentation :

```text
Expected: a value less than <22.123215715548074>
  Actual: <22.123215715548074>
00:00 +17 -1: Some tests failed.
```

### Format

```bash
cd packages/map_editor && dart format lib/src/application/shadow/element_auto_shadow_suggestion.dart test/application/shadow/element_auto_shadow_suggestion_test.dart lib/src/application/shadow/editor_static_shadow_preview.dart test/application/shadow/editor_static_shadow_preview_test.dart
```

Résultat :

```text
Formatted 4 files (0 changed) in 0.02 seconds.
```

```bash
cd packages/map_runtime && dart format lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart lib/src/shadow/runtime_static_placed_element_shadow_collection.dart test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
```

Résultat :

```text
Formatted 3 files (0 changed) in 0.01 seconds.
```

```bash
cd packages/map_runtime && dart format test/shadow/runtime_static_placed_element_shadow_collection_test.dart
```

Résultat :

```text
Formatted 1 file (0 changed) in 0.01 seconds.
```

### Tests ciblés GREEN

```bash
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_suggestion_test.dart
```

Résultat :

```text
00:00 +16: All tests passed!
```

```bash
cd packages/map_editor && flutter test test/application/shadow/editor_static_shadow_preview_test.dart
```

Résultat :

```text
00:00 +18: All tests passed!
```

```bash
cd packages/map_runtime && flutter test test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
```

Résultat :

```text
00:00 +33: All tests passed!
```

```bash
cd packages/map_runtime && flutter test test/shadow/runtime_static_placed_element_shadow_collection_test.dart
```

Résultat :

```text
00:00 +24: All tests passed!
```

```bash
cd packages/map_core && dart test test/shadow/static_shadow_family_projection_test.dart
```

Résultat :

```text
00:00 +16: All tests passed!
```

### Suites de dossier

```bash
cd packages/map_editor && flutter test test/application/shadow
```

Résultat :

```text
00:01 +90: All tests passed!
```

```bash
cd packages/map_runtime && flutter test test/shadow
```

Résultat :

```text
00:03 +225: All tests passed!
```

```bash
cd packages/map_core && dart test test/shadow
```

Résultat :

```text
00:01 +255: All tests passed!
```

### Analyse

```bash
cd packages/map_editor && flutter analyze lib/src/application/shadow test/application/shadow
```

Résultat :

```text
No issues found! (ran in 1.7s)
```

```bash
cd packages/map_runtime && flutter analyze lib/src/shadow test/shadow
```

Résultat :

```text
No issues found! (ran in 2.6s)
```

```bash
cd packages/map_core && dart analyze lib test/shadow
```

Résultat :

```text
Analyzing lib, shadow...
No issues found!
```

## 13. Scans anti-dérive

```bash
git diff --check
```

Résultat :

```text
aucune sortie
```

```bash
git diff --name-only | rg -n "packages/map_gameplay|packages/map_battle|examples/playable_runtime_host"
```

Résultat :

```text
aucune sortie
```

Interprétation : aucun diff `map_battle`, `map_gameplay` ou host au dernier scan.

```bash
git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_family_json_codec|\.g\.dart|\.freezed\.dart"
```

Résultat :

```text
aucune sortie
```

```bash
git diff -U0 -- packages/map_editor packages/map_runtime packages/map_core | rg -n "saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
```

Résultat :

```text
aucune sortie
```

```bash
git diff -U0 -- packages/map_editor | rg -n "package:map_runtime|map_runtime/src"
```

Résultat :

```text
aucune sortie
```

## 14. git status initial

Snapshot disponible au début de la reprise Shadow-46 :

```text
 M packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
 M packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
 M packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
 M packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
```

## 15. git status final

```text
 M packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
 M packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart
 M packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
 M packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
 M packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart
 M packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
 M packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
 M packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
 M packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
 M packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
?? reports/shadows/shadow_lot_46_static_shadow_visual_sanity_recovery.md
?? reports/shadows/shadow_lot_46_static_shadow_visual_sanity_recovery_plan.md
```

## 16. git diff --stat final

```text
 .../shadow/editor_static_shadow_preview.dart       | 291 +++++++++++--
 .../shadow/element_auto_shadow_suggestion.dart     |  13 +
 .../editor_static_shadow_preview_painter.dart      |  54 ++-
 .../shadow/editor_static_shadow_preview_test.dart  | 467 ++++++++++++++++++---
 .../element_auto_shadow_suggestion_test.dart       |  15 +
 .../editor_static_shadow_preview_painter_test.dart |  69 ++-
 ...me_static_placed_element_shadow_collection.dart |   2 +
 ...tic_placed_element_shadow_runtime_resolver.dart |  16 +-
 ...atic_placed_element_shadow_collection_test.dart |  70 +++
 ...laced_element_shadow_runtime_resolver_test.dart |  79 ++++
 10 files changed, 957 insertions(+), 119 deletions(-)
```

Interprétation : ce stat contient les fichiers painter editor déjà sales, en plus des fichiers modifiés par Shadow-46.

## 17. Diffs Shadow-46 utiles

### Micro-décors sans auto-shadow

```diff
+  if (_isMicroDecor(
+    width: source.width.toDouble(),
+    height: source.height.toDouble(),
+  )) {
+    return null;
+  }
```

```diff
+bool _isMicroDecor({
+  required double width,
+  required double height,
+}) {
+  return width <= 1 && height <= 2;
+}
```

### Runtime families

```diff
+    this.elementFamily,
+    this.overrideFamily,
```

```diff
+  final StaticShadowFamily? elementFamily;
+  final StaticShadowFamily? overrideFamily;
```

```diff
+    projectionSpec: resolveStaticShadowFamilyProjectionSpec(
+      family: resolveStaticShadowFamily(
+        elementFamily: input.elementFamily,
+        overrideFamily: input.overrideFamily,
+      ),
+    ),
```

```diff
+        elementFamily: source.elementShadow?.family,
+        overrideFamily: source.placedOverride?.family,
```

### Editor families

```diff
+      projectionSpec: resolveStaticShadowFamilyProjectionSpec(
+        family: resolveStaticShadowFamily(
+          elementFamily: element.shadow?.family,
+          overrideFamily: placed.shadowOverride?.family,
+        ),
+        baseProjectionSpec: _projectionSpecForEditorLightPreview(
+          resolvedLightPreviewPreset,
+        ),
+      ),
```

## 18. Non-objectifs respectés

- Aucun modèle persistant modifié.
- Aucun codec JSON modifié.
- Aucun fichier generated modifié par Shadow-46.
- Aucun nouveau build_runner.
- Aucun `map_gameplay`.
- Aucun `map_battle` touché par Shadow-46.
- Aucun import `map_runtime` dans `map_editor`.
- Aucun nouveau `Flame Component`.
- Aucun `saveLayer`, `ImageFilter`, `drawAtlas`, `zOrder`, `zIndex`.
- Aucune vraie lumière globale.
- Aucun Shadow Studio.

## 19. Risques / réserves

- Le rendu peut encore être insuffisant sur certains gros bâtiments : ce lot ne remplace pas une vraie silhouette dessinée ou masquée à la main.
- Le seuil micro-décor `width <= 1 && height <= 2` est volontairement conservateur. Certains éléments `2x1` ou `2x2` peuvent encore nécessiter une famille plus douce ou aucune ombre selon le tileset.
- Les fichiers painter editor étaient déjà modifiés avant ce lot ; ils doivent être stabilisés dans leur propre lot si nécessaire.
- Aucun diff `map_battle` n’est présent au dernier scan final.

## 20. Auto-review finale

- Ai-je supprimé les auto-ombres absurdes des micro-décors `1x1` et `1x2` ? oui.
- Ai-je appliqué `StaticShadowFamily` côté runtime ? oui.
- Ai-je transmis `elementFamily` et `overrideFamily` côté runtime collection ? oui.
- Ai-je appliqué `StaticShadowFamily` côté editor preview ? oui.
- Ai-je gardé `overrideFamily` prioritaire sur `elementFamily` ? oui.
- Ai-je évité de modifier les modèles persistants ? oui.
- Ai-je évité de modifier les codecs JSON ? oui.
- Ai-je évité de modifier `map_gameplay` / `map_battle` pour Shadow-46 ? oui.
- Ai-je évité un nouveau renderer ou un nouveau Flame component ? oui.
- Ai-je évité une lumière globale ? oui.
- Ai-je vérifié avec tests et analyze ? oui.

## 21. Regard critique

Le prompt implicite “faire les vraies ombres” est émotionnellement juste, mais techniquement trop large pour un seul lot sûr. La bonne trajectoire reste incrémentale : d’abord empêcher les absurdités automatiques, puis faire consommer les familles, puis traiter les silhouettes/masques/buildings avec des règles ou assets dédiés. Shadow-46 est donc utile, mais pas suffisant pour le rendu final de référence.
