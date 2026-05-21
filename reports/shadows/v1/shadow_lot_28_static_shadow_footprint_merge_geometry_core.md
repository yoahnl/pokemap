# Shadow-28 — Static Shadow Footprint Merge / Geometry Core V0

## 1. Résumé du lot

Shadow-28 ajoute une opération pure `map_core` pour résoudre le footprint statique et calculer une géométrie commune.

Le lot crée :

- `StaticShadowVisualMetrics`
- `ResolvedStaticShadowFootprint`
- `ResolvedStaticShadowGeometry`
- `resolveStaticShadowFootprint(...)`
- `resolveStaticShadowGeometry(...)`

Le comportement sans footprint reproduit la formule V0 existante :

```text
anchorXRatio = 0.5
anchorYRatio = 1.0
footprintWidthRatio = 0.75
footprintHeightRatio = 0.25
```

Aucun runtime, aucun editor, aucun modèle persistant, aucun codec JSON et aucun fichier généré ne sont modifiés.

## 2. Design retenu

La géométrie est isolée dans `packages/map_core/lib/src/operations/static_shadow_geometry.dart`.

Le helper est volontairement pur :

- dépend de `map_core` uniquement ;
- ne connaît ni Flutter, ni Flame, ni Canvas ;
- ne décide pas si une ombre doit être rendue ;
- ne filtre pas `ShadowCasterMode.none` ou `ShadowRenderPass.actorContact` ;
- applique seulement les métriques visuelles, le footprint résolu et `ResolvedShadowConfig`.

Le public barrel `packages/map_core/lib/map_core.dart` exporte l’opération pour les futurs lots runtime/editor.

## 3. Fichiers créés

```text
packages/map_core/lib/src/operations/static_shadow_geometry.dart
packages/map_core/test/shadow/static_shadow_geometry_test.dart
reports/shadows/shadow_lot_28_static_shadow_footprint_merge_geometry_core.md
```

## 4. Fichiers modifiés

```text
packages/map_core/lib/map_core.dart
```

Modification : ajout d’un export public.

## 5. Fichiers non modifiés explicitement

```text
packages/map_editor/**
packages/map_runtime/**
packages/map_gameplay/**
packages/map_battle/**
packages/map_core/lib/src/models/**
packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart
packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart
packages/map_core/lib/src/operations/static_shadow_footprint_config_json_codec.dart
```

Fichiers déjà présents/modifiés avant Shadow-28 : aucun relevé au `git status` initial.

Fichiers non suivis préexistants hors lot : aucun relevé au `git status` initial.

Dettes préexistantes hors lot : aucune découverte dans ce lot.

Problèmes introduits par Shadow-28 : aucun problème détecté par les tests, l’analyse et les scans anti-dérive lancés.

## 6. API geometry ajoutée

```dart
final class StaticShadowVisualMetrics
final class ResolvedStaticShadowFootprint
final class ResolvedStaticShadowGeometry

ResolvedStaticShadowFootprint resolveStaticShadowFootprint({
  StaticShadowFootprintConfig? elementFootprint,
  StaticShadowFootprintConfig? overrideFootprint,
});

ResolvedStaticShadowGeometry resolveStaticShadowGeometry({
  required StaticShadowVisualMetrics metrics,
  required ResolvedShadowConfig shadowConfig,
  StaticShadowFootprintConfig? elementFootprint,
  StaticShadowFootprintConfig? overrideFootprint,
});
```

Validation ajoutée :

- `StaticShadowVisualMetrics.left/top` doivent être finite ;
- `StaticShadowVisualMetrics.visualWidth/visualHeight` doivent être finite et `> 0` ;
- `ResolvedStaticShadowFootprint.anchorXRatio/anchorYRatio` doivent être finite et dans `[0, 1]` ;
- `ResolvedStaticShadowFootprint.footprintWidthRatio/footprintHeightRatio` doivent être finite et `> 0` ;
- `ResolvedStaticShadowGeometry` exige des positions finite et des tailles `> 0`.

## 7. Defaults V0

```text
anchorXRatio = 0.5
anchorYRatio = 1.0
footprintWidthRatio = 0.75
footprintHeightRatio = 0.25
```

Ces valeurs sont testées explicitement dans `static_shadow_geometry_test.dart`.

## 8. Règles de merge footprint

Le merge est champ par champ :

```text
defaults
→ champs non-null de ProjectElementShadowConfig.footprint
→ champs non-null de MapPlacedElementShadowOverride.footprint
```

Un `overrideFootprint` non-null ne remplace pas tout le footprint élément. Il remplace seulement ses champs non-null.

Exemple testé :

```text
element:
  anchorXRatio = 0.25
  anchorYRatio = 0.5
  footprintWidthRatio = 0.5
  footprintHeightRatio = 0.125

override:
  anchorYRatio = 0.75
  footprintWidthRatio = 0.25

resolved:
  anchorXRatio = 0.25
  anchorYRatio = 0.75
  footprintWidthRatio = 0.25
  footprintHeightRatio = 0.125
```

## 9. Formule géométrique commune

```text
footprint = resolveStaticShadowFootprint(...)

anchorX = metrics.left + metrics.visualWidth * footprint.anchorXRatio
anchorY = metrics.top + metrics.visualHeight * footprint.anchorYRatio

baseWidth = metrics.visualWidth * footprint.footprintWidthRatio
baseHeight = metrics.visualHeight * footprint.footprintHeightRatio

width = baseWidth * shadowConfig.scaleX
height = baseHeight * shadowConfig.scaleY

centerX = anchorX + shadowConfig.offsetX
centerY = anchorY + shadowConfig.offsetY

left = centerX - width / 2
top = centerY - height / 2
```

`offsetX/offsetY` s’appliquent après l’ancre. `scaleX/scaleY` s’appliquent après le footprint de base.

## 10. Compatibilité comportementale avec la formule actuelle

Cas testé :

```text
metrics.left = 16
metrics.top = 24
metrics.visualWidth = 32
metrics.visualHeight = 64
offsetX = 0
offsetY = 0
scaleX = 1
scaleY = 1
```

Résultat attendu et testé :

```text
anchorX = 32
anchorY = 88
baseWidth = 24
baseHeight = 16
centerX = 32
centerY = 88
width = 24
height = 16
left = 20
top = 80
```

## 11. Pourquoi ce lot ne touche pas runtime/editor

Shadow-28 est la brique `map_core` commune. L’intégration runtime/editor est volontairement réservée aux lots suivants afin de garder le changement petit et vérifiable :

- runtime : futur lot d’intégration de la géométrie commune ;
- editor : futur lot d’intégration de la preview canvas à la géométrie commune.

## 12. Pourquoi ce lot ne filtre pas mode/renderPass

La fonction `resolveStaticShadowGeometry(...)` calcule uniquement une géométrie à partir d’un `ResolvedShadowConfig` déjà résolu.

Le filtrage de rendu reste dans les builders consommateurs :

- `mode == none` ;
- `renderPass == actorContact` ;
- profil manquant ;
- ombre désactivée ;
- métriques de sprite invalides.

Cette séparation évite de mélanger décision de rendu et calcul géométrique.

## 13. Tests ajoutés

```text
packages/map_core/test/shadow/static_shadow_geometry_test.dart
```

Couverture :

- métriques valides/invalides ;
- defaults exacts ;
- merge partiel ;
- override gagnant champ par champ ;
- formule V0 reproduite sans footprint ;
- offset après ancre ;
- scale après footprint ;
- style sans effet sur la géométrie (`mode`, `renderPass`, `opacity`, `colorHexRgb`, `softnessMode`) ;
- passage direct de `ProjectElementShadowConfig.footprint` ;
- passage direct de `MapPlacedElementShadowOverride.footprint` ;
- égalité/hashCode sur les trois classes.

## 14. Commandes lancées

Depuis `/Users/karim/Project/pokemonProject` :

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
```

Depuis `/Users/karim/Project/pokemonProject/packages/map_core` :

```bash
dart test test/shadow/static_shadow_geometry_test.dart --reporter expanded
dart format lib/src/operations/static_shadow_geometry.dart lib/map_core.dart test/shadow/static_shadow_geometry_test.dart
dart test test/shadow/static_shadow_geometry_test.dart --reporter expanded
dart test test/shadow --reporter expanded
dart analyze lib test/shadow
dart test --reporter expanded
dart analyze
```

Depuis `/Users/karim/Project/pokemonProject` :

```bash
git diff --name-only | rg -n "packages/map_editor|packages/map_runtime|packages/map_gameplay|packages/map_battle"
git diff --name-only | rg -n "packages/map_core/lib/src/models"
git diff --name-only | rg -n "project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec"
git diff --name-only | rg -n "\.g\.dart|\.freezed\.dart"
git diff -U0 -- packages/map_core | rg -n "Canvas|Flame|drawOval|drawImageRect|saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex"
git diff --check
git diff --stat
git diff --name-status
git status --short --untracked-files=all
```

## 15. Résultats complets des tests ciblés

### RED attendu avant implémentation

Commande :

```bash
cd packages/map_core && dart test test/shadow/static_shadow_geometry_test.dart --reporter expanded
```

Résultat utile :

```text
Error: Type 'StaticShadowVisualMetrics' not found.
Error: Method not found: 'resolveStaticShadowFootprint'.
Error: Method not found: 'ResolvedStaticShadowFootprint'.
Error: Method not found: 'resolveStaticShadowGeometry'.
Error: Method not found: 'ResolvedStaticShadowGeometry'.
00:00 +0 -1: Some tests failed.
```

### Format

Commande :

```bash
cd packages/map_core && dart format lib/src/operations/static_shadow_geometry.dart lib/map_core.dart test/shadow/static_shadow_geometry_test.dart
```

Résultat :

```text
Formatted test/shadow/static_shadow_geometry_test.dart
Formatted 3 files (1 changed) in 0.01 seconds.
```

### GREEN ciblé

Commande :

```bash
cd packages/map_core && dart test test/shadow/static_shadow_geometry_test.dart --reporter expanded
```

Résultat :

```text
00:00 +0: loading test/shadow/static_shadow_geometry_test.dart
00:00 +0: StaticShadowVisualMetrics accepts valid metrics
00:00 +1: StaticShadowVisualMetrics rejects non-finite left and top
00:00 +2: StaticShadowVisualMetrics rejects invalid visual sizes
00:00 +3: StaticShadowVisualMetrics equality and hashCode include all fields
00:00 +4: ResolvedStaticShadowFootprint defaults match current V0 ratios
00:00 +5: ResolvedStaticShadowFootprint element footprint overrides defaults field by field
00:00 +6: ResolvedStaticShadowFootprint override footprint wins over element footprint field by field
00:00 +7: ResolvedStaticShadowFootprint rejects invalid direct resolved ratios
00:00 +8: ResolvedStaticShadowFootprint equality and hashCode include all fields
00:00 +9: resolveStaticShadowGeometry without footprint reproduces current V0 formula
00:00 +10: resolveStaticShadowGeometry element footprint changes anchor and footprint size
00:00 +11: resolveStaticShadowGeometry override footprint wins while partial override keeps element fields
00:00 +12: resolveStaticShadowGeometry offset and scale apply after footprint
00:00 +13: resolveStaticShadowGeometry mode renderPass opacity color and softness do not affect geometry
00:00 +14: resolveStaticShadowGeometry rejects invalid direct geometry values
00:00 +15: resolveStaticShadowGeometry equality and hashCode include all fields
00:00 +16: static shadow geometry integration with existing configs ProjectElementShadowConfig footprint can be passed directly
00:00 +17: static shadow geometry integration with existing configs MapPlacedElementShadowOverride footprint can be passed directly
00:00 +18: static shadow geometry integration with existing configs custom override with null footprint uses element or default footprint
00:00 +19: All tests passed!
```

## 16. Ligne finale exacte des tests globaux

Commande :

```bash
cd packages/map_core && dart test test/shadow --reporter expanded
```

Résultat final exact :

```text
00:00 +204: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart analyze lib test/shadow
```

Résultat exact :

```text
Analyzing lib, shadow...
No issues found!
```

Commande :

```bash
cd packages/map_core && dart test --reporter expanded
```

Résultat final exact :

```text
00:02 +1560: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart analyze
```

Résultat exact :

```text
Analyzing map_core...
No issues found!
```

## 17. Résultats des scans anti-dérive

Commande :

```bash
find .. -name AGENTS.md -print
```

Résultat :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Commande :

```bash
git diff --name-only | rg -n "packages/map_editor|packages/map_runtime|packages/map_gameplay|packages/map_battle"
```

Résultat :

```text
aucune sortie
```

Commande :

```bash
git diff --name-only | rg -n "packages/map_core/lib/src/models"
```

Résultat :

```text
aucune sortie
```

Commande :

```bash
git diff --name-only | rg -n "project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec"
```

Résultat :

```text
aucune sortie
```

Commande :

```bash
git diff --name-only | rg -n "\.g\.dart|\.freezed\.dart"
```

Résultat :

```text
aucune sortie
```

Commande :

```bash
git diff -U0 -- packages/map_core | rg -n "Canvas|Flame|drawOval|drawImageRect|saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex"
```

Résultat :

```text
aucune sortie
```

Commande :

```bash
git diff --check
```

Résultat :

```text
aucune sortie
```

## 18. git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Résultat initial :

```text
aucune sortie
```

## 19. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Résultat final :

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/static_shadow_geometry.dart
?? packages/map_core/test/shadow/static_shadow_geometry_test.dart
?? reports/shadows/shadow_lot_28_static_shadow_footprint_merge_geometry_core.md
```

## 20. git diff --stat

Commande :

```bash
git diff --stat
```

Résultat :

```text
 packages/map_core/lib/map_core.dart | 1 +
 1 file changed, 1 insertion(+)
```

Note : les fichiers non suivis du lot sont listés dans `git status final`.

Commande :

```bash
git diff --name-status
```

Résultat :

```text
M	packages/map_core/lib/map_core.dart
```

## 21. Non-objectifs respectés

- Aucun `map_runtime`.
- Aucun `map_editor`.
- Aucun `map_gameplay`.
- Aucun `map_battle`.
- Aucun modèle persistant modifié.
- Aucun codec JSON modifié.
- Aucun fichier généré modifié.
- Aucun `build_runner`.
- Aucun rendu visible.
- Aucun Canvas / Flame.
- Aucun blur / atlas / sprite.
- Aucun `zOrder` / `zIndex`.
- Aucune direction globale de lumière.

## 22. Risques / réserves

- Le runtime et l’éditeur n’utilisent pas encore cette opération. Les lots suivants devront remplacer leurs formules locales par `resolveStaticShadowGeometry(...)`.
- La fonction ne filtre volontairement pas `mode` ou `renderPass`. Les consommateurs doivent continuer à filtrer avant d’appeler ou d’utiliser la géométrie.
- Les ratios absolus de V0 restent proportionnels à la bounding box visuelle. Les futurs lots UI footprint devront aider à authorer des ratios adaptés aux objets hauts/fins.

## 23. Auto-review finale

- Ai-je ajouté une opération pure de merge footprint ? oui.
- Ai-je ajouté une opération pure de géométrie statique ? oui.
- Ai-je gardé la formule actuelle quand footprint absent ? oui.
- Ai-je évité de toucher au runtime ? oui.
- Ai-je évité de toucher à l’éditeur ? oui.
- Ai-je évité de modifier les modèles persistants ? oui.
- Ai-je évité de modifier les codecs JSON ? oui.
- Ai-je évité build_runner ? oui.
- Ai-je évité toute lumière globale ? oui.
- Ai-je laissé le filtrage mode/renderPass aux builders runtime/editor ? oui.

## 24. Regard critique sur le prompt

Le prompt est cohérent avec la décision Shadow-26 et le modèle Shadow-27. Le point le plus important est la séparation stricte entre calcul géométrique et décision de rendu : elle évite de faire remonter dans `map_core` des règles runtime/editor prématurées. Le risque principal des prochains lots sera de garder runtime et preview editor alignés sans dupliquer à nouveau la formule.

## 25. Contenu complet des fichiers créés/modifiés

Le fichier source créé et le fichier test créé sont reproduits intégralement dans la section 26 sous forme de diffs `/dev/null`, ce qui inclut chaque ligne ajoutée.

Modification complète de `packages/map_core/lib/map_core.dart` :

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index c9471247..6a087fa0 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -64,6 +64,7 @@ export 'src/operations/surface_catalog_diagnostics.dart';
 export 'src/operations/surface_catalog_authoring_diagnostics.dart';
 export 'src/operations/surface_catalog_diagnostics_summary.dart';
 export 'src/operations/surface_catalog_diagnostics_presentation.dart';
+export 'src/operations/static_shadow_geometry.dart';
 export 'src/operations/surface_atlas_json_codec.dart';
 export 'src/operations/surface_animation_frame_json_codec.dart';
 export 'src/operations/surface_animation_timeline_json_codec.dart';
```

## 26. Diffs complets ou équivalents /dev/null pour fichiers créés

### packages/map_core/lib/src/operations/static_shadow_geometry.dart

```diff
diff --git a/packages/map_core/lib/src/operations/static_shadow_geometry.dart b/packages/map_core/lib/src/operations/static_shadow_geometry.dart
new file mode 100644
index 00000000..228cbc01
--- /dev/null
+++ b/packages/map_core/lib/src/operations/static_shadow_geometry.dart
@@ -0,0 +1,258 @@
+import '../exceptions/map_exceptions.dart';
+import '../models/shadow.dart';
+import 'shadow_config_resolver.dart';
+
+const _defaultStaticShadowAnchorXRatio = 0.5;
+const _defaultStaticShadowAnchorYRatio = 1.0;
+const _defaultStaticShadowFootprintWidthRatio = 0.75;
+const _defaultStaticShadowFootprintHeightRatio = 0.25;
+
+final class StaticShadowVisualMetrics {
+  StaticShadowVisualMetrics({
+    required this.left,
+    required this.top,
+    required this.visualWidth,
+    required this.visualHeight,
+  }) {
+    _validateFinite(left, 'StaticShadowVisualMetrics.left');
+    _validateFinite(top, 'StaticShadowVisualMetrics.top');
+    _validatePositiveFinite(
+      visualWidth,
+      'StaticShadowVisualMetrics.visualWidth',
+    );
+    _validatePositiveFinite(
+      visualHeight,
+      'StaticShadowVisualMetrics.visualHeight',
+    );
+  }
+
+  final double left;
+  final double top;
+  final double visualWidth;
+  final double visualHeight;
+
+  @override
+  bool operator ==(Object other) =>
+      identical(this, other) ||
+      other is StaticShadowVisualMetrics &&
+          other.left == left &&
+          other.top == top &&
+          other.visualWidth == visualWidth &&
+          other.visualHeight == visualHeight;
+
+  @override
+  int get hashCode => Object.hash(
+        left,
+        top,
+        visualWidth,
+        visualHeight,
+      );
+}
+
+final class ResolvedStaticShadowFootprint {
+  ResolvedStaticShadowFootprint({
+    required this.anchorXRatio,
+    required this.anchorYRatio,
+    required this.footprintWidthRatio,
+    required this.footprintHeightRatio,
+  }) {
+    _validateRatio(
+      anchorXRatio,
+      'ResolvedStaticShadowFootprint.anchorXRatio',
+    );
+    _validateRatio(
+      anchorYRatio,
+      'ResolvedStaticShadowFootprint.anchorYRatio',
+    );
+    _validatePositiveFinite(
+      footprintWidthRatio,
+      'ResolvedStaticShadowFootprint.footprintWidthRatio',
+    );
+    _validatePositiveFinite(
+      footprintHeightRatio,
+      'ResolvedStaticShadowFootprint.footprintHeightRatio',
+    );
+  }
+
+  final double anchorXRatio;
+  final double anchorYRatio;
+  final double footprintWidthRatio;
+  final double footprintHeightRatio;
+
+  @override
+  bool operator ==(Object other) =>
+      identical(this, other) ||
+      other is ResolvedStaticShadowFootprint &&
+          other.anchorXRatio == anchorXRatio &&
+          other.anchorYRatio == anchorYRatio &&
+          other.footprintWidthRatio == footprintWidthRatio &&
+          other.footprintHeightRatio == footprintHeightRatio;
+
+  @override
+  int get hashCode => Object.hash(
+        anchorXRatio,
+        anchorYRatio,
+        footprintWidthRatio,
+        footprintHeightRatio,
+      );
+}
+
+final class ResolvedStaticShadowGeometry {
+  ResolvedStaticShadowGeometry({
+    required this.anchorX,
+    required this.anchorY,
+    required this.baseWidth,
+    required this.baseHeight,
+    required this.centerX,
+    required this.centerY,
+    required this.width,
+    required this.height,
+    required this.left,
+    required this.top,
+  }) {
+    _validateFinite(anchorX, 'ResolvedStaticShadowGeometry.anchorX');
+    _validateFinite(anchorY, 'ResolvedStaticShadowGeometry.anchorY');
+    _validatePositiveFinite(
+      baseWidth,
+      'ResolvedStaticShadowGeometry.baseWidth',
+    );
+    _validatePositiveFinite(
+      baseHeight,
+      'ResolvedStaticShadowGeometry.baseHeight',
+    );
+    _validateFinite(centerX, 'ResolvedStaticShadowGeometry.centerX');
+    _validateFinite(centerY, 'ResolvedStaticShadowGeometry.centerY');
+    _validatePositiveFinite(width, 'ResolvedStaticShadowGeometry.width');
+    _validatePositiveFinite(height, 'ResolvedStaticShadowGeometry.height');
+    _validateFinite(left, 'ResolvedStaticShadowGeometry.left');
+    _validateFinite(top, 'ResolvedStaticShadowGeometry.top');
+  }
+
+  final double anchorX;
+  final double anchorY;
+  final double baseWidth;
+  final double baseHeight;
+  final double centerX;
+  final double centerY;
+  final double width;
+  final double height;
+  final double left;
+  final double top;
+
+  @override
+  bool operator ==(Object other) =>
+      identical(this, other) ||
+      other is ResolvedStaticShadowGeometry &&
+          other.anchorX == anchorX &&
+          other.anchorY == anchorY &&
+          other.baseWidth == baseWidth &&
+          other.baseHeight == baseHeight &&
+          other.centerX == centerX &&
+          other.centerY == centerY &&
+          other.width == width &&
+          other.height == height &&
+          other.left == left &&
+          other.top == top;
+
+  @override
+  int get hashCode => Object.hash(
+        anchorX,
+        anchorY,
+        baseWidth,
+        baseHeight,
+        centerX,
+        centerY,
+        width,
+        height,
+        left,
+        top,
+      );
+}
+
+ResolvedStaticShadowFootprint resolveStaticShadowFootprint({
+  StaticShadowFootprintConfig? elementFootprint,
+  StaticShadowFootprintConfig? overrideFootprint,
+}) {
+  var anchorXRatio = _defaultStaticShadowAnchorXRatio;
+  var anchorYRatio = _defaultStaticShadowAnchorYRatio;
+  var footprintWidthRatio = _defaultStaticShadowFootprintWidthRatio;
+  var footprintHeightRatio = _defaultStaticShadowFootprintHeightRatio;
+
+  if (elementFootprint != null) {
+    anchorXRatio = elementFootprint.anchorXRatio ?? anchorXRatio;
+    anchorYRatio = elementFootprint.anchorYRatio ?? anchorYRatio;
+    footprintWidthRatio =
+        elementFootprint.footprintWidthRatio ?? footprintWidthRatio;
+    footprintHeightRatio =
+        elementFootprint.footprintHeightRatio ?? footprintHeightRatio;
+  }
+
+  if (overrideFootprint != null) {
+    anchorXRatio = overrideFootprint.anchorXRatio ?? anchorXRatio;
+    anchorYRatio = overrideFootprint.anchorYRatio ?? anchorYRatio;
+    footprintWidthRatio =
+        overrideFootprint.footprintWidthRatio ?? footprintWidthRatio;
+    footprintHeightRatio =
+        overrideFootprint.footprintHeightRatio ?? footprintHeightRatio;
+  }
+
+  return ResolvedStaticShadowFootprint(
+    anchorXRatio: anchorXRatio,
+    anchorYRatio: anchorYRatio,
+    footprintWidthRatio: footprintWidthRatio,
+    footprintHeightRatio: footprintHeightRatio,
+  );
+}
+
+ResolvedStaticShadowGeometry resolveStaticShadowGeometry({
+  required StaticShadowVisualMetrics metrics,
+  required ResolvedShadowConfig shadowConfig,
+  StaticShadowFootprintConfig? elementFootprint,
+  StaticShadowFootprintConfig? overrideFootprint,
+}) {
+  final footprint = resolveStaticShadowFootprint(
+    elementFootprint: elementFootprint,
+    overrideFootprint: overrideFootprint,
+  );
+  final anchorX = metrics.left + metrics.visualWidth * footprint.anchorXRatio;
+  final anchorY = metrics.top + metrics.visualHeight * footprint.anchorYRatio;
+  final baseWidth = metrics.visualWidth * footprint.footprintWidthRatio;
+  final baseHeight = metrics.visualHeight * footprint.footprintHeightRatio;
+  final width = baseWidth * shadowConfig.scaleX;
+  final height = baseHeight * shadowConfig.scaleY;
+  final centerX = anchorX + shadowConfig.offsetX;
+  final centerY = anchorY + shadowConfig.offsetY;
+
+  return ResolvedStaticShadowGeometry(
+    anchorX: anchorX,
+    anchorY: anchorY,
+    baseWidth: baseWidth,
+    baseHeight: baseHeight,
+    centerX: centerX,
+    centerY: centerY,
+    width: width,
+    height: height,
+    left: centerX - width / 2,
+    top: centerY - height / 2,
+  );
+}
+
+void _validateFinite(double value, String name) {
+  if (!value.isFinite) {
+    throw ValidationException('$name must be finite');
+  }
+}
+
+void _validatePositiveFinite(double value, String name) {
+  _validateFinite(value, name);
+  if (value <= 0) {
+    throw ValidationException('$name must be > 0');
+  }
+}
+
+void _validateRatio(double value, String name) {
+  _validateFinite(value, name);
+  if (value < 0 || value > 1) {
+    throw ValidationException('$name must be between 0 and 1');
+  }
+}
```

### packages/map_core/test/shadow/static_shadow_geometry_test.dart

```diff
diff --git a/packages/map_core/test/shadow/static_shadow_geometry_test.dart b/packages/map_core/test/shadow/static_shadow_geometry_test.dart
new file mode 100644
index 00000000..d86def71
--- /dev/null
+++ b/packages/map_core/test/shadow/static_shadow_geometry_test.dart
@@ -0,0 +1,471 @@
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+void main() {
+  group('StaticShadowVisualMetrics', () {
+    test('accepts valid metrics', () {
+      final metrics = StaticShadowVisualMetrics(
+        left: 16,
+        top: 24,
+        visualWidth: 32,
+        visualHeight: 64,
+      );
+
+      expect(metrics.left, 16);
+      expect(metrics.top, 24);
+      expect(metrics.visualWidth, 32);
+      expect(metrics.visualHeight, 64);
+    });
+
+    test('rejects non-finite left and top', () {
+      for (final value in <double>[
+        double.nan,
+        double.infinity,
+        double.negativeInfinity,
+      ]) {
+        expect(
+          () => StaticShadowVisualMetrics(
+            left: value,
+            top: 0,
+            visualWidth: 32,
+            visualHeight: 64,
+          ),
+          throwsA(isA<ValidationException>()),
+        );
+        expect(
+          () => StaticShadowVisualMetrics(
+            left: 0,
+            top: value,
+            visualWidth: 32,
+            visualHeight: 64,
+          ),
+          throwsA(isA<ValidationException>()),
+        );
+      }
+    });
+
+    test('rejects invalid visual sizes', () {
+      for (final value in <double>[
+        0,
+        -1,
+        double.nan,
+        double.infinity,
+        double.negativeInfinity,
+      ]) {
+        expect(
+          () => StaticShadowVisualMetrics(
+            left: 0,
+            top: 0,
+            visualWidth: value,
+            visualHeight: 64,
+          ),
+          throwsA(isA<ValidationException>()),
+        );
+        expect(
+          () => StaticShadowVisualMetrics(
+            left: 0,
+            top: 0,
+            visualWidth: 32,
+            visualHeight: value,
+          ),
+          throwsA(isA<ValidationException>()),
+        );
+      }
+    });
+
+    test('equality and hashCode include all fields', () {
+      final first = StaticShadowVisualMetrics(
+        left: 16,
+        top: 24,
+        visualWidth: 32,
+        visualHeight: 64,
+      );
+      final same = StaticShadowVisualMetrics(
+        left: 16,
+        top: 24,
+        visualWidth: 32,
+        visualHeight: 64,
+      );
+      final different = StaticShadowVisualMetrics(
+        left: 17,
+        top: 24,
+        visualWidth: 32,
+        visualHeight: 64,
+      );
+
+      expect(first, same);
+      expect(first.hashCode, same.hashCode);
+      expect(first, isNot(different));
+    });
+  });
+
+  group('ResolvedStaticShadowFootprint', () {
+    test('defaults match current V0 ratios', () {
+      expect(
+        resolveStaticShadowFootprint(),
+        ResolvedStaticShadowFootprint(
+          anchorXRatio: 0.5,
+          anchorYRatio: 1,
+          footprintWidthRatio: 0.75,
+          footprintHeightRatio: 0.25,
+        ),
+      );
+    });
+
+    test('element footprint overrides defaults field by field', () {
+      final footprint = resolveStaticShadowFootprint(
+        elementFootprint: StaticShadowFootprintConfig(
+          anchorXRatio: 0.4,
+          footprintHeightRatio: 0.2,
+        ),
+      );
+
+      expect(footprint.anchorXRatio, 0.4);
+      expect(footprint.anchorYRatio, 1);
+      expect(footprint.footprintWidthRatio, 0.75);
+      expect(footprint.footprintHeightRatio, 0.2);
+    });
+
+    test('override footprint wins over element footprint field by field', () {
+      final footprint = resolveStaticShadowFootprint(
+        elementFootprint: StaticShadowFootprintConfig(
+          anchorXRatio: 0.4,
+          anchorYRatio: 0.9,
+          footprintWidthRatio: 0.5,
+          footprintHeightRatio: 0.2,
+        ),
+        overrideFootprint: StaticShadowFootprintConfig(
+          anchorYRatio: 0.8,
+          footprintWidthRatio: 0.25,
+        ),
+      );
+
+      expect(
+        footprint,
+        ResolvedStaticShadowFootprint(
+          anchorXRatio: 0.4,
+          anchorYRatio: 0.8,
+          footprintWidthRatio: 0.25,
+          footprintHeightRatio: 0.2,
+        ),
+      );
+    });
+
+    test('rejects invalid direct resolved ratios', () {
+      expect(
+        () => ResolvedStaticShadowFootprint(
+          anchorXRatio: -0.01,
+          anchorYRatio: 1,
+          footprintWidthRatio: 0.75,
+          footprintHeightRatio: 0.25,
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => ResolvedStaticShadowFootprint(
+          anchorXRatio: 0.5,
+          anchorYRatio: 1,
+          footprintWidthRatio: 0,
+          footprintHeightRatio: 0.25,
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('equality and hashCode include all fields', () {
+      final first = ResolvedStaticShadowFootprint(
+        anchorXRatio: 0.5,
+        anchorYRatio: 1,
+        footprintWidthRatio: 0.75,
+        footprintHeightRatio: 0.25,
+      );
+      final same = ResolvedStaticShadowFootprint(
+        anchorXRatio: 0.5,
+        anchorYRatio: 1,
+        footprintWidthRatio: 0.75,
+        footprintHeightRatio: 0.25,
+      );
+      final different = ResolvedStaticShadowFootprint(
+        anchorXRatio: 0.4,
+        anchorYRatio: 1,
+        footprintWidthRatio: 0.75,
+        footprintHeightRatio: 0.25,
+      );
+
+      expect(first, same);
+      expect(first.hashCode, same.hashCode);
+      expect(first, isNot(different));
+    });
+  });
+
+  group('resolveStaticShadowGeometry', () {
+    test('without footprint reproduces current V0 formula', () {
+      final geometry = resolveStaticShadowGeometry(
+        metrics: _defaultMetrics(),
+        shadowConfig: _shadowConfig(),
+      );
+
+      expect(
+        geometry,
+        ResolvedStaticShadowGeometry(
+          anchorX: 32,
+          anchorY: 88,
+          baseWidth: 24,
+          baseHeight: 16,
+          centerX: 32,
+          centerY: 88,
+          width: 24,
+          height: 16,
+          left: 20,
+          top: 80,
+        ),
+      );
+    });
+
+    test('element footprint changes anchor and footprint size', () {
+      final geometry = resolveStaticShadowGeometry(
+        metrics: _defaultMetrics(),
+        shadowConfig: _shadowConfig(),
+        elementFootprint: StaticShadowFootprintConfig(
+          anchorXRatio: 0.25,
+          anchorYRatio: 0.5,
+          footprintWidthRatio: 0.5,
+          footprintHeightRatio: 0.125,
+        ),
+      );
+
+      expect(geometry.anchorX, 24);
+      expect(geometry.anchorY, 56);
+      expect(geometry.baseWidth, 16);
+      expect(geometry.baseHeight, 8);
+      expect(geometry.left, 16);
+      expect(geometry.top, 52);
+    });
+
+    test('override footprint wins while partial override keeps element fields',
+        () {
+      final geometry = resolveStaticShadowGeometry(
+        metrics: _defaultMetrics(),
+        shadowConfig: _shadowConfig(),
+        elementFootprint: StaticShadowFootprintConfig(
+          anchorXRatio: 0.25,
+          anchorYRatio: 0.5,
+          footprintWidthRatio: 0.5,
+          footprintHeightRatio: 0.125,
+        ),
+        overrideFootprint: StaticShadowFootprintConfig(
+          anchorYRatio: 0.75,
+          footprintWidthRatio: 0.25,
+        ),
+      );
+
+      expect(geometry.anchorX, 24);
+      expect(geometry.anchorY, 72);
+      expect(geometry.baseWidth, 8);
+      expect(geometry.baseHeight, 8);
+      expect(geometry.left, 20);
+      expect(geometry.top, 68);
+    });
+
+    test('offset and scale apply after footprint', () {
+      final geometry = resolveStaticShadowGeometry(
+        metrics: _defaultMetrics(),
+        shadowConfig: _shadowConfig(
+          offsetX: 3,
+          offsetY: -4,
+          scaleX: 2,
+          scaleY: 0.5,
+        ),
+      );
+
+      expect(geometry.anchorX, 32);
+      expect(geometry.anchorY, 88);
+      expect(geometry.baseWidth, 24);
+      expect(geometry.baseHeight, 16);
+      expect(geometry.centerX, 35);
+      expect(geometry.centerY, 84);
+      expect(geometry.width, 48);
+      expect(geometry.height, 8);
+      expect(geometry.left, 11);
+      expect(geometry.top, 80);
+    });
+
+    test('mode renderPass opacity color and softness do not affect geometry',
+        () {
+      final base = resolveStaticShadowGeometry(
+        metrics: _defaultMetrics(),
+        shadowConfig: _shadowConfig(),
+      );
+      final changedStyle = resolveStaticShadowGeometry(
+        metrics: _defaultMetrics(),
+        shadowConfig: _shadowConfig(
+          mode: ShadowCasterMode.none,
+          renderPass: ShadowRenderPass.actorContact,
+          opacity: 0,
+          colorHexRgb: 'FFFFFF',
+        ),
+      );
+
+      expect(changedStyle, base);
+    });
+
+    test('rejects invalid direct geometry values', () {
+      expect(
+        () => ResolvedStaticShadowGeometry(
+          anchorX: double.nan,
+          anchorY: 88,
+          baseWidth: 24,
+          baseHeight: 16,
+          centerX: 32,
+          centerY: 88,
+          width: 24,
+          height: 16,
+          left: 20,
+          top: 80,
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => ResolvedStaticShadowGeometry(
+          anchorX: 32,
+          anchorY: 88,
+          baseWidth: 0,
+          baseHeight: 16,
+          centerX: 32,
+          centerY: 88,
+          width: 24,
+          height: 16,
+          left: 20,
+          top: 80,
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => ResolvedStaticShadowGeometry(
+          anchorX: 32,
+          anchorY: 88,
+          baseWidth: 24,
+          baseHeight: 16,
+          centerX: 32,
+          centerY: 88,
+          width: 0,
+          height: 16,
+          left: 20,
+          top: 80,
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('equality and hashCode include all fields', () {
+      final first = resolveStaticShadowGeometry(
+        metrics: _defaultMetrics(),
+        shadowConfig: _shadowConfig(),
+      );
+      final same = resolveStaticShadowGeometry(
+        metrics: _defaultMetrics(),
+        shadowConfig: _shadowConfig(),
+      );
+      final different = resolveStaticShadowGeometry(
+        metrics: _defaultMetrics(),
+        shadowConfig: _shadowConfig(offsetX: 1),
+      );
+
+      expect(first, same);
+      expect(first.hashCode, same.hashCode);
+      expect(first, isNot(different));
+    });
+  });
+
+  group('static shadow geometry integration with existing configs', () {
+    test('ProjectElementShadowConfig footprint can be passed directly', () {
+      final elementShadow = ProjectElementShadowConfig(
+        castsShadow: true,
+        shadowProfileId: 'ground',
+        footprint: StaticShadowFootprintConfig(anchorXRatio: 0.25),
+      );
+
+      final geometry = resolveStaticShadowGeometry(
+        metrics: _defaultMetrics(),
+        shadowConfig: _shadowConfig(),
+        elementFootprint: elementShadow.footprint,
+      );
+
+      expect(geometry.anchorX, 24);
+      expect(geometry.anchorY, 88);
+    });
+
+    test('MapPlacedElementShadowOverride footprint can be passed directly', () {
+      final placedOverride = MapPlacedElementShadowOverride(
+        mode: ShadowOverrideMode.custom,
+        footprint: StaticShadowFootprintConfig(anchorYRatio: 0.75),
+      );
+
+      final geometry = resolveStaticShadowGeometry(
+        metrics: _defaultMetrics(),
+        shadowConfig: _shadowConfig(),
+        overrideFootprint: placedOverride.footprint,
+      );
+
+      expect(geometry.anchorX, 32);
+      expect(geometry.anchorY, 72);
+    });
+
+    test(
+        'custom override with null footprint uses element or default footprint',
+        () {
+      final placedOverride = MapPlacedElementShadowOverride(
+        mode: ShadowOverrideMode.custom,
+        offsetX: 1,
+      );
+
+      final withElement = resolveStaticShadowGeometry(
+        metrics: _defaultMetrics(),
+        shadowConfig: _shadowConfig(),
+        elementFootprint: StaticShadowFootprintConfig(anchorXRatio: 0.25),
+        overrideFootprint: placedOverride.footprint,
+      );
+      final withoutElement = resolveStaticShadowGeometry(
+        metrics: _defaultMetrics(),
+        shadowConfig: _shadowConfig(),
+        overrideFootprint: placedOverride.footprint,
+      );
+
+      expect(withElement.anchorX, 24);
+      expect(withoutElement.anchorX, 32);
+    });
+  });
+}
+
+StaticShadowVisualMetrics _defaultMetrics() {
+  return StaticShadowVisualMetrics(
+    left: 16,
+    top: 24,
+    visualWidth: 32,
+    visualHeight: 64,
+  );
+}
+
+ResolvedShadowConfig _shadowConfig({
+  ShadowCasterMode mode = ShadowCasterMode.ellipse,
+  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
+  double offsetX = 0,
+  double offsetY = 0,
+  double scaleX = 1,
+  double scaleY = 1,
+  double opacity = 0.35,
+  String colorHexRgb = '000000',
+}) {
+  return ResolvedShadowConfig(
+    shadowProfileId: 'ground',
+    mode: mode,
+    renderPass: renderPass,
+    offsetX: offsetX,
+    offsetY: offsetY,
+    scaleX: scaleX,
+    scaleY: scaleY,
+    opacity: opacity,
+    colorHexRgb: colorHexRgb,
+    softnessMode: ShadowSoftnessMode.hardEdge,
+  );
+}
```
