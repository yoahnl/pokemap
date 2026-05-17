# Collision Lot 14-bis — Occlusion Patch Reposition Lifecycle Hardening V0

## 1. Résumé exécutif

Collision-14-bis verrouille le repositionnement successif des patches d'occlusion statiques.

Le risque identifié dans Collision-14 était réel :

```text
applyMapOriginDelta(delta) recalculait position/priority depuis l'instruction initiale + delta courant.
Après plusieurs repositionnements successifs, les deltas ne s'accumulaient pas.
```

Correction retenue :

```text
Renommer la sémantique en translateByMapOriginDelta(delta).
Appliquer le delta à la position courante.
Maintenir un _currentDepthSortY double pour recalculer priority sans accumuler les arrondis.
```

Le rendu, le montage et le gameplay restent inchangés hors nécessité minimale.

## 2. Pourquoi ce bis est nécessaire

Collision-14 a ajouté :

```text
PlacedElementOcclusionPatchComponent
PlayableMapGame mounting des patches
_LoadedPlayableMap.occlusionPatches
unmount des patches
```

Mais la méthode suivante était fragile :

```dart
void applyMapOriginDelta(Vector2 delta) {
  position = Vector2(
    instruction.worldLeft + delta.x,
    instruction.worldTop + delta.y,
  );
  priority = (1000 + instruction.depthSortY + delta.y).round();
}
```

Cette logique fonctionne pour un seul delta, mais pas pour plusieurs deltas relatifs successifs.

Reproduction minimale :

```text
position initiale = 100
delta A = +32 → position attendue 132, obtenue 132
delta B = +32 → position attendue 164, ancienne logique obtenait 132
```

## 3. Git status initial

Commande lancée au début du bis :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
?? packages/map_runtime/test/placed_element_occlusion_patch_component_test.dart
?? packages/map_runtime/test/playable_map_game_placed_element_occlusion_test.dart
?? reports/collision/collision_lot_14_static_occlusion_patch_renderer.md
```

Interprétation :

```text
Ces fichiers correspondent à Collision-14 non committé.
Collision-14-bis a été appliqué par-dessus cet état, sans git add/commit.
```

Worktree actif :

```text
/Users/karim/.config/superpowers/worktrees/pokemonProject/collision-source-of-truth-worktree
```

## 4. Audit ciblé

Rapports relus :

```text
reports/collision/collision_lot_13_occlusion_runtime_patch_resolution.md
reports/collision/collision_lot_14_static_occlusion_patch_renderer.md
```

Fichiers inspectés :

```text
packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/lib/src/presentation/flame/static_placed_element_occlusion_patch_resolution.dart
packages/map_runtime/test/placed_element_occlusion_patch_component_test.dart
packages/map_runtime/test/playable_map_game_placed_element_occlusion_test.dart
packages/map_runtime/test/static_placed_element_occlusion_patch_resolution_test.dart
```

Recherche lancée :

```bash
rg -n "applyMapOriginDelta|occlusionPatches|_repositionLoadedMap|_LoadedPlayableMap|originDelta|originCellX|originCellY|debugUnmountLoadedMapForTest|PlacedElementOcclusionPatchComponent|flamePriority|depthSortY" packages/map_runtime/lib packages/map_runtime/test
```

Constats :

```text
Les tests Collision-14 couvraient le montage, l'absence de mask, applyCollision=false, le tileset manquant et l'unmount.
Ils ne couvraient pas plusieurs repositionnements successifs.
_repositionLoadedMap(...) calcule bien un delta relatif entre l'ancienne et la nouvelle origine.
Le composant interprétait ce delta comme s'il était absolu depuis l'instruction initiale.
```

## 5. Bug ou risque identifié

Bug confirmé par test rouge.

Commande rouge :

```bash
cd packages/map_runtime
flutter test --no-pub --reporter expanded test/placed_element_occlusion_patch_component_test.dart
```

Sortie utile :

```text
00:00 +4 -1: PlacedElementOcclusionPatchComponent applies successive map origin deltas cumulatively [E]
  Expected: <164>
    Actual: <132.0>
```

Un test PlayableMapGame a aussi été ajouté avant le hook de test, ce qui a produit le rouge attendu :

```text
Error: The method 'debugRepositionLoadedMapForTest' isn't defined for the type 'PlayableMapGame'.
```

Conclusion :

```text
La méthode avait une sémantique de delta relatif côté appelant, mais une implémentation quasi-absolue côté composant.
```

## 6. Design retenu

Design final :

```dart
void translateByMapOriginDelta(Vector2 delta) {
  position = position + delta;
  _currentDepthSortY += delta.y;
  priority = (1000 + _currentDepthSortY).round();
}
```

Raison :

```text
_repositionLoadedMap(...) calcule originDelta = newOriginPx - oldOriginPx.
Ce delta est relatif.
Le composant doit donc translater sa position courante.
La priority doit suivre le depthSortY courant, pas repartir de instruction.depthSortY à chaque appel.
```

Pourquoi ne pas recalculer les instructions :

```text
C'était plus large que nécessaire pour un bis.
Le delta relatif est déjà la donnée disponible dans PlayableMapGame.
La correction locale couvre le bug sans recréer de composants.
```

## 7. Fichiers créés

```text
reports/collision/collision_lot_14bis_occlusion_patch_reposition_lifecycle.md
```

## 8. Fichiers modifiés

```text
packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/test/placed_element_occlusion_patch_component_test.dart
packages/map_runtime/test/playable_map_game_placed_element_occlusion_test.dart
```

Note :

```text
Les deux fichiers de test existaient déjà comme fichiers non suivis issus de Collision-14.
Collision-14-bis les complète.
```

## 9. Fichiers explicitement non modifiés

```text
packages/map_core/**
packages/map_editor/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart
packages/map_runtime/lib/src/presentation/flame/player_component.dart
packages/map_runtime/lib/src/presentation/flame/overworld_actor_component.dart
packages/map_runtime/lib/src/presentation/flame/static_placed_element_occlusion_patch_resolution.dart
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
packages/map_runtime/lib/src/application/runtime_map_bundle.dart
```

Generated :

```text
Aucun
```

## 10. Tests ajoutés / modifiés

Ajouts dans `placed_element_occlusion_patch_component_test.dart` :

```text
applies successive map origin deltas cumulatively
zero map origin delta keeps position and priority unchanged
```

Ajout dans `playable_map_game_placed_element_occlusion_test.dart` :

```text
repositions occlusion patches with loaded map origin changes
```

Hook test ajouté dans `PlayableMapGame` :

```dart
@visibleForTesting
void debugRepositionLoadedMapForTest(...)
```

Le hook appelle `_repositionLoadedMap(...)` sans dupliquer la logique.

## 11. Commandes lancées

```bash
git status --short --untracked-files=all
pwd
sed -n '1,220p' reports/collision/collision_lot_13_occlusion_runtime_patch_resolution.md
sed -n '1,260p' reports/collision/collision_lot_14_static_occlusion_patch_renderer.md
rg -n "applyMapOriginDelta|occlusionPatches|_repositionLoadedMap|_LoadedPlayableMap|originDelta|originCellX|originCellY|debugUnmountLoadedMapForTest|PlacedElementOcclusionPatchComponent|flamePriority|depthSortY" packages/map_runtime/lib packages/map_runtime/test
cd packages/map_runtime && flutter test --no-pub --reporter compact test/placed_element_occlusion_patch_component_test.dart test/playable_map_game_placed_element_occlusion_test.dart
cd packages/map_runtime && flutter test --no-pub --reporter expanded test/placed_element_occlusion_patch_component_test.dart
cd packages/map_runtime && flutter test --no-pub --reporter expanded test/playable_map_game_placed_element_occlusion_test.dart
dart format packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart packages/map_runtime/test/placed_element_occlusion_patch_component_test.dart packages/map_runtime/test/playable_map_game_placed_element_occlusion_test.dart
cd packages/map_runtime && flutter analyze lib/src/presentation/flame/placed_element_occlusion_patch_component.dart lib/src/presentation/flame/playable_map_game.dart test/placed_element_occlusion_patch_component_test.dart test/playable_map_game_placed_element_occlusion_test.dart
cd packages/map_runtime && flutter test --no-pub --reporter compact test/placed_element_occlusion_patch_component_test.dart test/playable_map_game_placed_element_occlusion_test.dart test/static_placed_element_occlusion_patch_resolution_test.dart
cd packages/map_runtime && flutter test --no-pub --reporter compact test/map_layers_component_placed_element_render_test.dart test/map_layers_component_render_pass_test.dart test/load_runtime_map_bundle_collision_normalization_test.dart
cd packages/map_runtime && flutter test --no-pub --reporter compact
git diff --name-only
git diff --stat
git status --short --untracked-files=all
```

## 12. Résultats des tests ciblés

Baseline avant modification du bis :

```bash
cd packages/map_runtime
flutter test --no-pub --reporter compact test/placed_element_occlusion_patch_component_test.dart test/playable_map_game_placed_element_occlusion_test.dart
```

Sortie utile :

```text
00:02 +9: All tests passed!
```

Test composant après correction :

```bash
cd packages/map_runtime
flutter test --no-pub --reporter expanded test/placed_element_occlusion_patch_component_test.dart
```

Sortie utile :

```text
00:00 +6: All tests passed!
```

Test PlayableMapGame après correction :

```bash
cd packages/map_runtime
flutter test --no-pub --reporter expanded test/playable_map_game_placed_element_occlusion_test.dart
```

Sortie utile :

```text
00:00 +6: All tests passed!
```

## 13. Résultats des tests de non-régression

Groupé runtime occlusion :

```bash
cd packages/map_runtime
flutter test --no-pub --reporter compact test/placed_element_occlusion_patch_component_test.dart test/playable_map_game_placed_element_occlusion_test.dart test/static_placed_element_occlusion_patch_resolution_test.dart
```

Sortie utile :

```text
00:01 +24: All tests passed!
```

Régression runtime ciblée :

```bash
cd packages/map_runtime
flutter test --no-pub --reporter compact test/map_layers_component_placed_element_render_test.dart test/map_layers_component_render_pass_test.dart test/load_runtime_map_bundle_collision_normalization_test.dart
```

Sortie utile :

```text
00:01 +4: All tests passed!
```

Suite complète runtime :

```bash
cd packages/map_runtime
flutter test --no-pub --reporter compact
```

Sortie utile :

```text
00:23 +1130: All tests passed!
```

## 14. Analyse statique / format

Format :

```bash
dart format packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart packages/map_runtime/test/placed_element_occlusion_patch_component_test.dart packages/map_runtime/test/playable_map_game_placed_element_occlusion_test.dart
```

Sortie exacte :

```text
Formatted 4 files (0 changed) in 0.06 seconds.
```

Analyse ciblée :

```bash
cd packages/map_runtime
flutter analyze lib/src/presentation/flame/placed_element_occlusion_patch_component.dart lib/src/presentation/flame/playable_map_game.dart test/placed_element_occlusion_patch_component_test.dart test/playable_map_game_placed_element_occlusion_test.dart
```

Sortie exacte :

```text
No issues found! (ran in 4.7s)
```

## 15. Vérification du périmètre

Commande :

```bash
git diff --name-only
```

Sortie exacte :

```text
packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
```

Fichiers non suivis concernés par Collision-14 / Collision-14-bis :

```text
packages/map_runtime/test/placed_element_occlusion_patch_component_test.dart
packages/map_runtime/test/playable_map_game_placed_element_occlusion_test.dart
reports/collision/collision_lot_14_static_occlusion_patch_renderer.md
reports/collision/collision_lot_14bis_occlusion_patch_reposition_lifecycle.md
```

Inventaire complet :

```text
Créés par Collision-14-bis :
- reports/collision/collision_lot_14bis_occlusion_patch_reposition_lifecycle.md

Modifiés par Collision-14-bis :
- packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart
- packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
- packages/map_runtime/test/placed_element_occlusion_patch_component_test.dart
- packages/map_runtime/test/playable_map_game_placed_element_occlusion_test.dart

Préexistants non suivis avant Collision-14-bis :
- packages/map_runtime/test/placed_element_occlusion_patch_component_test.dart
- packages/map_runtime/test/playable_map_game_placed_element_occlusion_test.dart
- reports/collision/collision_lot_14_static_occlusion_patch_renderer.md

Supprimés :
- Aucun

Generated :
- Aucun

Hors périmètre touché :
- Aucun
```

## 16. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte après création du rapport :

```text
 M packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
?? packages/map_runtime/test/placed_element_occlusion_patch_component_test.dart
?? packages/map_runtime/test/playable_map_game_placed_element_occlusion_test.dart
?? reports/collision/collision_lot_14_static_occlusion_patch_renderer.md
?? reports/collision/collision_lot_14bis_occlusion_patch_reposition_lifecycle.md
```

## 17. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie exacte :

```text
 .../placed_element_occlusion_patch_component.dart  | 226 ++++++++++-----------
 .../src/presentation/flame/playable_map_game.dart  |  60 ++++++
 2 files changed, 162 insertions(+), 124 deletions(-)
```

Note :

```text
git diff --stat ne liste pas les fichiers non suivis.
L'inventaire complet ci-dessus les liste explicitement.
```

## 18. Risques / réserves

```text
Le test lifecycle passe par un hook @visibleForTesting.
La logique reste delta-relative ; elle ne recrée pas les instructions depuis une origine absolue.
Collision-15 devra encore prouver le cas bâtiment runtime complet avec joueur devant/derrière.
```

## 19. Préparation de Collision-15

Collision-15 peut maintenant s'appuyer sur :

```text
Un resolver testé.
Un renderer statique testé.
Un montage PlayableMapGame testé.
Un unmount testé.
Un repositionnement successif testé.
```

Point à prouver ensuite :

```text
bâtiment réel + joueur + toit occlusif rendu devant/derrière + collision gameplay inchangée.
```

## 20. Auto-review finale

```text
Ai-je corrigé ou prouvé la sémantique de reposition ? Oui.
Ai-je testé plusieurs repositionnements successifs ? Oui.
Ai-je gardé le rendu occlusion inchangé ? Oui.
Ai-je évité map_core ? Oui.
Ai-je évité map_editor ? Oui.
Ai-je évité map_gameplay ? Oui.
Ai-je évité MapLayersComponent ? Oui.
Ai-je évité RuntimeMapGame ? Oui.
Ai-je évité les animations ? Oui.
Ai-je préparé Collision-15 ? Oui.
```

## 21. Contenu complet des fichiers créés/modifiés

### Diff complet des fichiers suivis modifiés

```diff
diff --git a/packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart b/packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart
index 0edffd3f..9a92c667 100644
--- a/packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart
@@ -1,151 +1,129 @@
-import 'dart:ui' as ui;
-
 import 'package:flame/components.dart';
 import 'package:flutter/material.dart';
 import 'package:map_core/map_core.dart';
 
-import '../../application/runtime_map_bundle.dart';
+import '../../infrastructure/runtime_tileset_image.dart';
+import 'static_placed_element_occlusion_patch_resolution.dart';
 
-/// Une **zone d’occlusion** (toit / couronne) pour **un** [MapPlacedElement] :
-/// redessine uniquement les pixels marqués dans [ElementCollisionProfile.occlusionMask]
-/// **par-dessus** le joueur lorsque la priorité Flame le permet.
-///
-/// ## Rôle produit
-/// - **Ne** gère **pas** la collision (voir masque collision / gameplay).
-/// - Sert uniquement à l’effet « passer derrière » la partie haute d’un bâtiment.
-///
-/// ## Priorité de dessin
-/// `priority ≈ 1000 + bas_du_sprite_en_pixels_monde` pour rester aligné avec
-/// [OverworldActorComponent.depthSortY] / le joueur (`1000 + footY`).
-///
-/// ## Limites (honnêtes)
-/// - La **base** du bâtiment reste peinte dans [MapLayersComponent] (priorité 0) :
-///   tant qu’on ne duplique pas le rendu « base » en couche Y-sortée, le joueur
-///   peut recouvrir la base quand il est au sud — comportement classique acceptable
-///   pour une première itération ; la suite est documentée dans le rapport produit.
 class PlacedElementOcclusionPatchComponent extends PositionComponent {
   PlacedElementOcclusionPatchComponent({
-    required this.bundle,
-    required this.instance,
-    required this.element,
-    required this.tileImage,
-    required Vector2 mapOriginPx,
-  }) : super(
+    required this.instruction,
+    required this.tilesetImage,
+  })  : _drawRuns = _buildDrawRuns(instruction),
+        _currentDepthSortY = instruction.depthSortY,
+        super(
           anchor: Anchor.topLeft,
-          position: _computeTopLeft(
-            bundle: bundle,
-            instance: instance,
-            element: element,
-            mapOriginPx: mapOriginPx,
-          ),
-          size: _computeSize(
-            bundle: bundle,
-            element: element,
-          ),
+          position: Vector2(instruction.worldLeft, instruction.worldTop),
+          size: Vector2(instruction.visualWidth, instruction.visualHeight),
         ) {
-    final mask = element.collisionProfile?.occlusionMask;
-    final tw = bundle.manifest.settings.tileWidth;
-    final th = bundle.manifest.settings.tileHeight;
-    final ch = bundle.cellHeight;
-    if (mask != null && tw > 0 && th > 0) {
-      final sy = ch / th;
-      final bottomWorld =
-          mapOriginPx.y + instance.pos.y * ch + mask.heightPx * sy;
-      priority = (1000 + bottomWorld).round().clamp(0, 2000000);
-    } else {
-      priority = -1;
-    }
+    priority = instruction.flamePriority;
   }
 
-  final RuntimeMapBundle bundle;
-  final MapPlacedElement instance;
-  final ProjectElementEntry element;
-  final ui.Image tileImage;
+  final StaticPlacedElementOcclusionPatchInstruction instruction;
+  final RuntimeTilesetImage tilesetImage;
+  final List<_OcclusionPixelRun> _drawRuns;
+  double _currentDepthSortY;
 
-  static Vector2 _computeTopLeft({
-    required RuntimeMapBundle bundle,
-    required MapPlacedElement instance,
-    required ProjectElementEntry element,
-    required Vector2 mapOriginPx,
-  }) {
-    final cw = bundle.cellWidth;
-    final ch = bundle.cellHeight;
-    return Vector2(
-      mapOriginPx.x + instance.pos.x * cw,
-      mapOriginPx.y + instance.pos.y * ch,
-    );
-  }
+  @visibleForTesting
+  int get debugDrawRunCount => _drawRuns.length;
 
-  static Vector2 _computeSize({
-    required RuntimeMapBundle bundle,
-    required ProjectElementEntry element,
-  }) {
-    final mask = element.collisionProfile?.occlusionMask;
-    final tw = bundle.manifest.settings.tileWidth;
-    final th = bundle.manifest.settings.tileHeight;
-    final cw = bundle.cellWidth;
-    final ch = bundle.cellHeight;
-    if (mask == null || tw <= 0 || th <= 0) {
-      return Vector2.zero();
-    }
-    final sx = cw / tw;
-    final sy = ch / th;
-    return Vector2(mask.widthPx * sx, mask.heightPx * sy);
+  void translateByMapOriginDelta(Vector2 delta) {
+    position = position + delta;
+    _currentDepthSortY += delta.y;
+    priority = (1000 + _currentDepthSortY).round();
   }
 
   @override
   void render(Canvas canvas) {
-    final profile = element.collisionProfile;
-    final mask = profile?.occlusionMask;
-    if (mask == null) {
+    if (instruction.opacity <= 0 || _drawRuns.isEmpty) {
       return;
     }
-    List<bool> pixels;
-    try {
-      pixels = ElementCollisionMaskCodec.decodePackedBits(
-        widthPx: mask.widthPx,
-        heightPx: mask.heightPx,
-        dataBase64: mask.dataBase64,
+    final paint = Paint()
+      ..isAntiAlias = false
+      ..filterQuality = FilterQuality.none;
+    if (instruction.opacity < 1) {
+      paint.color = Color.fromRGBO(255, 255, 255, instruction.opacity);
+    }
+
+    final scaleX = instruction.visualWidth / instruction.sourceWidthPx;
+    final scaleY = instruction.visualHeight / instruction.sourceHeightPx;
+    for (final run in _drawRuns) {
+      final src = Rect.fromLTWH(
+        (instruction.sourceLeftPx + run.x).toDouble(),
+        (instruction.sourceTopPx + run.y).toDouble(),
+        run.width.toDouble(),
+        1,
       );
-    } catch (_) {
-      return;
+      final dst = Rect.fromLTWH(
+        run.x * scaleX,
+        run.y * scaleY,
+        run.width * scaleX,
+        scaleY,
+      );
+      tilesetImage.drawImageRect(canvas, src, dst, paint);
     }
-    final frame = element.frames.primaryFrame;
-    final tw = bundle.manifest.settings.tileWidth;
-    final th = bundle.manifest.settings.tileHeight;
-    final cw = bundle.cellWidth;
-    final ch = bundle.cellHeight;
-    if (tw <= 0 || th <= 0) {
-      return;
+  }
+
+  static List<_OcclusionPixelRun> _buildDrawRuns(
+    StaticPlacedElementOcclusionPatchInstruction instruction,
+  ) {
+    final mask = instruction.occlusionMask;
+    if (mask.widthPx <= 0 ||
+        mask.heightPx <= 0 ||
+        instruction.sourceWidthPx <= 0 ||
+        instruction.sourceHeightPx <= 0 ||
+        instruction.visualWidth <= 0 ||
+        instruction.visualHeight <= 0 ||
+        mask.widthPx != instruction.sourceWidthPx ||
+        mask.heightPx != instruction.sourceHeightPx) {
+      return const [];
     }
-    final scaleX = cw / tw;
-    final scaleY = ch / th;
-    final srcLeft = frame.source.x * tw;
-    final srcTop = frame.source.y * th;
-    final paint = Paint()..filterQuality = FilterQuality.none;
-    for (var py = 0; py < mask.heightPx; py++) {
-      for (var px = 0; px < mask.widthPx; px++) {
-        final idx = py * mask.widthPx + px;
-        if (idx < 0 || idx >= pixels.length || !pixels[idx]) {
-          continue;
-        }
-        final ix = srcLeft + px;
-        final iy = srcTop + py;
-        if (ix < 0 ||
-            iy < 0 ||
-            ix >= tileImage.width ||
-            iy >= tileImage.height) {
-          continue;
+
+    final pixels = _decodeMask(mask);
+    if (pixels.isEmpty) {
+      return const [];
+    }
+
+    final runs = <_OcclusionPixelRun>[];
+    for (var y = 0; y < mask.heightPx; y++) {
+      int? runStart;
+      for (var x = 0; x <= mask.widthPx; x++) {
+        final isSolid = x < mask.widthPx && pixels[y * mask.widthPx + x];
+        if (isSolid && runStart == null) {
+          runStart = x;
+        } else if (!isSolid && runStart != null) {
+          runs.add(_OcclusionPixelRun(x: runStart, y: y, width: x - runStart));
+          runStart = null;
         }
-        final src = Rect.fromLTWH(ix.toDouble(), iy.toDouble(), 1, 1);
-        final dst = Rect.fromLTWH(
-          px * scaleX,
-          py * scaleY,
-          scaleX,
-          scaleY,
-        );
-        canvas.drawImageRect(tileImage, src, dst, paint);
       }
     }
+    return List<_OcclusionPixelRun>.unmodifiable(runs);
   }
+
+  static List<bool> _decodeMask(ElementCollisionPixelMask mask) {
+    try {
+      return ElementCollisionMaskCodec.decodePackedBits(
+        widthPx: mask.widthPx,
+        heightPx: mask.heightPx,
+        dataBase64: mask.dataBase64,
+      );
+    } on FormatException {
+      return const [];
+    } on ArgumentError {
+      return const [];
+    }
+  }
+}
+
+@immutable
+final class _OcclusionPixelRun {
+  const _OcclusionPixelRun({
+    required this.x,
+    required this.y,
+    required this.width,
+  });
+
+  final int x;
+  final int y;
+  final int width;
 }
diff --git a/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart b/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
index 86e65ec0..cfac9ceb 100644
--- a/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
@@ -77,8 +77,10 @@ import 'dialogue_overlay_component.dart';
 import 'map_layers_component.dart';
 import 'overworld_actor_component.dart';
 import 'player_component.dart';
+import 'placed_element_occlusion_patch_component.dart';
 import 'runtime_battle_gender_overrides.dart';
 import 'runtime_trainer_battle_overrides.dart';
+import 'static_placed_element_occlusion_patch_resolution.dart';
 import 'warp_transition_overlay_component.dart';
 
 const double _kViewportTilesX = 15.0;
@@ -600,6 +602,28 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
   @visibleForTesting
   bool debugIsMapLoaded(String mapId) => _loadedMapsById.containsKey(mapId);
 
+  @visibleForTesting
+  void debugUnmountLoadedMapForTest(String mapId) {
+    _unmountLoadedMap(mapId);
+  }
+
+  @visibleForTesting
+  void debugRepositionLoadedMapForTest({
+    required String mapId,
+    required int originCellX,
+    required int originCellY,
+  }) {
+    final loaded = _loadedMapsById[mapId];
+    if (loaded == null) {
+      return;
+    }
+    _repositionLoadedMap(
+      loaded,
+      originCellX: originCellX,
+      originCellY: originCellY,
+    );
+  }
+
   @visibleForTesting
   Vector2 debugWorldTopLeftForSpawnCell(GridPos cell) {
     return _worldTopLeftForPlayerSpawnCell(
@@ -5022,6 +5046,7 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
           originCellY: activeLoaded.originCellY,
           backgroundLayers: activeLoaded.backgroundLayers,
           foregroundLayers: activeLoaded.foregroundLayers,
+          occlusionPatches: activeLoaded.occlusionPatches,
           npcActors: activeLoaded.npcActors,
           npcActorByEntityId: activeLoaded.npcActorByEntityId,
         );
@@ -6460,6 +6485,9 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
     }
     loaded.backgroundLayers.removeFromParent();
     loaded.foregroundLayers.removeFromParent();
+    for (final patch in loaded.occlusionPatches) {
+      patch.removeFromParent();
+    }
     for (final actor in loaded.npcActors) {
       actor.removeFromParent();
       _npcActors.remove(actor);
@@ -6501,6 +6529,26 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
     foregroundLayers.priority = 100000;
     await world.add(foregroundLayers);
 
+    final occlusionPatches = <PlacedElementOcclusionPatchComponent>[];
+    final occlusionInstructions =
+        resolveStaticPlacedElementOcclusionPatchInstructions(
+      bundle: bundle,
+      originCellX: originCellX,
+      originCellY: originCellY,
+    );
+    for (final instruction in occlusionInstructions) {
+      final tilesetImage = tileImagesById[instruction.tilesetId];
+      if (tilesetImage == null) {
+        continue;
+      }
+      final patch = PlacedElementOcclusionPatchComponent(
+        instruction: instruction,
+        tilesetImage: tilesetImage,
+      );
+      occlusionPatches.add(patch);
+      await world.add(patch);
+    }
+
     final npcActors = <OverworldActorComponent>[];
     final npcActorByEntityId = <String, OverworldActorComponent>{};
     final charById = {for (final c in bundle.manifest.characters) c.id: c};
@@ -6551,6 +6599,7 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
       originCellY: originCellY,
       backgroundLayers: backgroundLayers,
       foregroundLayers: foregroundLayers,
+      occlusionPatches: occlusionPatches,
       npcActors: npcActors,
       npcActorByEntityId: npcActorByEntityId,
     );
@@ -6660,12 +6709,20 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
     required int originCellX,
     required int originCellY,
   }) {
+    final oldOriginPx = _originPixels(
+      originCellX: loaded.originCellX,
+      originCellY: loaded.originCellY,
+    );
     final originPx = _originPixels(
       originCellX: originCellX,
       originCellY: originCellY,
     );
+    final originDelta = originPx - oldOriginPx;
     loaded.backgroundLayers.position = originPx.clone();
     loaded.foregroundLayers.position = originPx.clone();
+    for (final patch in loaded.occlusionPatches) {
+      patch.translateByMapOriginDelta(originDelta);
+    }
     for (final entity in loaded.bundle.map.entities) {
       if (entity.kind != MapEntityKind.npc) {
         continue;
@@ -6687,6 +6744,7 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
       originCellY: originCellY,
       backgroundLayers: loaded.backgroundLayers,
       foregroundLayers: loaded.foregroundLayers,
+      occlusionPatches: loaded.occlusionPatches,
       npcActors: loaded.npcActors,
       npcActorByEntityId: loaded.npcActorByEntityId,
     );
@@ -7639,6 +7697,7 @@ class _LoadedPlayableMap {
     required this.originCellY,
     required this.backgroundLayers,
     required this.foregroundLayers,
+    required this.occlusionPatches,
     required this.npcActors,
     required this.npcActorByEntityId,
   });
@@ -7648,6 +7707,7 @@ class _LoadedPlayableMap {
   final int originCellY;
   final MapLayersComponent backgroundLayers;
   final MapLayersComponent foregroundLayers;
+  final List<PlacedElementOcclusionPatchComponent> occlusionPatches;
   final List<OverworldActorComponent> npcActors;
   final Map<String, OverworldActorComponent> npcActorByEntityId;
 }
```

### Contenu complet — `packages/map_runtime/test/placed_element_occlusion_patch_component_test.dart`

```dart
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/placed_element_occlusion_patch_component.dart';
import 'package:map_runtime/src/presentation/flame/static_placed_element_occlusion_patch_resolution.dart';

import 'surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlacedElementOcclusionPatchComponent', () {
    test('configures position size and priority from instruction', () async {
      final component = PlacedElementOcclusionPatchComponent(
        instruction: _instruction(
          worldLeft: 12,
          worldTop: 24,
          visualWidth: 32,
          visualHeight: 16,
          flamePriority: 1040,
        ),
        tilesetImage: await _runtimeTilesetImage2x2(),
      );

      expect(component.position.x, 12);
      expect(component.position.y, 24);
      expect(component.size.x, 32);
      expect(component.size.y, 16);
      expect(component.priority, 1040);
    });

    test('renders only masked occlusion pixels', () async {
      final component = PlacedElementOcclusionPatchComponent(
        instruction: _instruction(
          mask: _mask(widthPx: 2, heightPx: 2, solidPixels: const {3}),
        ),
        tilesetImage: await _runtimeTilesetImage2x2(),
      );

      final image = await _render(component, width: 2, height: 2);

      expect(await pixelAt(image, 0, 0), rgba(0, 0, 0, 0));
      expect(await pixelAt(image, 1, 0), rgba(0, 0, 0, 0));
      expect(await pixelAt(image, 0, 1), rgba(0, 0, 0, 0));
      expect(await pixelAt(image, 1, 1), rgba(255, 255, 0, 255));
    });

    test('does not render when opacity is zero', () async {
      final component = PlacedElementOcclusionPatchComponent(
        instruction: _instruction(
          opacity: 0,
          mask: _mask(widthPx: 2, heightPx: 2, solidPixels: const {0, 3}),
        ),
        tilesetImage: await _runtimeTilesetImage2x2(),
      );

      final image = await _render(component, width: 2, height: 2);

      expect(await pixelAt(image, 0, 0), rgba(0, 0, 0, 0));
      expect(await pixelAt(image, 1, 1), rgba(0, 0, 0, 0));
    });

    test('empty decoded mask produces no draw runs', () async {
      final component = PlacedElementOcclusionPatchComponent(
        instruction: _instruction(
          mask: _mask(widthPx: 2, heightPx: 2, solidPixels: const {}),
        ),
        tilesetImage: await _runtimeTilesetImage2x2(),
      );

      expect(component.debugDrawRunCount, 0);
    });

    test('applies successive map origin deltas cumulatively', () async {
      final component = PlacedElementOcclusionPatchComponent(
        instruction: _instruction(
          worldLeft: 100,
          worldTop: 200,
          depthSortY: 216,
          flamePriority: 1216,
        ),
        tilesetImage: await _runtimeTilesetImage2x2(),
      );

      component.translateByMapOriginDelta(Vector2(32, 16));
      component.translateByMapOriginDelta(Vector2(32, -8));

      expect(component.position.x, 164);
      expect(component.position.y, 208);
      expect(component.priority, 1224);
    });

    test('zero map origin delta keeps position and priority unchanged',
        () async {
      final component = PlacedElementOcclusionPatchComponent(
        instruction: _instruction(
          worldLeft: 100,
          worldTop: 200,
          depthSortY: 216,
          flamePriority: 1216,
        ),
        tilesetImage: await _runtimeTilesetImage2x2(),
      );

      component.translateByMapOriginDelta(Vector2.zero());

      expect(component.position.x, 100);
      expect(component.position.y, 200);
      expect(component.priority, 1216);
    });
  });
}

StaticPlacedElementOcclusionPatchInstruction _instruction({
  double worldLeft = 0,
  double worldTop = 0,
  double visualWidth = 2,
  double visualHeight = 2,
  double depthSortY = 2,
  int flamePriority = 1002,
  double opacity = 1,
  ElementCollisionPixelMask? mask,
}) {
  return StaticPlacedElementOcclusionPatchInstruction(
    mapId: 'map',
    placedElementId: 'placed',
    elementId: 'element',
    layerId: 'objects',
    tilesetId: 'entity',
    sourceLeftPx: 0,
    sourceTopPx: 0,
    sourceWidthPx: 2,
    sourceHeightPx: 2,
    worldLeft: worldLeft,
    worldTop: worldTop,
    visualWidth: visualWidth,
    visualHeight: visualHeight,
    depthSortY: depthSortY,
    flamePriority: flamePriority,
    opacity: opacity,
    occlusionMask: mask ?? _mask(widthPx: 2, heightPx: 2),
  );
}

ElementCollisionPixelMask _mask({
  required int widthPx,
  required int heightPx,
  Set<int> solidPixels = const {0},
}) {
  final bits = List<bool>.filled(widthPx * heightPx, false);
  for (final index in solidPixels) {
    if (index >= 0 && index < bits.length) {
      bits[index] = true;
    }
  }
  return ElementCollisionPixelMask(
    widthPx: widthPx,
    heightPx: heightPx,
    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
      widthPx: widthPx,
      heightPx: heightPx,
      solidPixels: bits,
    ),
  );
}

Future<RuntimeTilesetImage> _runtimeTilesetImage2x2() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 1, 1),
    Paint()..color = const Color(0xFFFF0000),
  );
  canvas.drawRect(
    const Rect.fromLTWH(1, 0, 1, 1),
    Paint()..color = const Color(0xFF00FF00),
  );
  canvas.drawRect(
    const Rect.fromLTWH(0, 1, 1, 1),
    Paint()..color = const Color(0xFF0000FF),
  );
  canvas.drawRect(
    const Rect.fromLTWH(1, 1, 1, 1),
    Paint()..color = const Color(0xFFFFFF00),
  );
  final image = await recorder.endRecording().toImage(2, 2);
  return RuntimeTilesetImage(
    images: [image],
    chunks: const [
      RuntimeTilesetChunk(top: 0, height: 2, width: 2),
    ],
    width: 2,
    height: 2,
  );
}

Future<ui.Image> _render(
  PlacedElementOcclusionPatchComponent component, {
  required int width,
  required int height,
}) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  component.render(canvas);
  return recorder.endRecording().toImage(width, height);
}
```

### Contenu complet — `packages/map_runtime/test/playable_map_game_placed_element_occlusion_test.dart`

```dart
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/placed_element_occlusion_patch_component.dart';
import 'package:map_runtime/src/presentation/flame/playable_map_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayableMapGame placed element occlusion patches', () {
    test(
        'mounts static occlusion patches for placed elements with occlusionMask',
        () async {
      final game = _game(bundle: _bundle());

      await _load(game);

      final patches = _occlusionPatches(game);
      expect(patches, hasLength(1));
      expect(patches.single.priority, 1064);
      expect(patches.single.position.x, 32);
      expect(patches.single.position.y, 32);
    });

    test('does not mount occlusion patch when occlusionMask is absent',
        () async {
      final game = _game(
        bundle: _bundle(includeOcclusionMask: false),
      );

      await _load(game);

      expect(_occlusionPatches(game), isEmpty);
    });

    test('mounts occlusion patch even when applyCollision is false', () async {
      final game = _game(
        bundle: _bundle(applyCollision: false),
      );

      await _load(game);

      expect(_occlusionPatches(game), hasLength(1));
    });

    test('skips occlusion patch when RuntimeTilesetImage is missing', () async {
      final game = _game(
        bundle: _bundle(),
        includeElementTilesetImage: false,
      );

      await _load(game);

      expect(_occlusionPatches(game), isEmpty);
    });

    test('removes occlusion patches when loaded map is unmounted', () async {
      final game = _game(bundle: _bundle());
      await _load(game);

      expect(_occlusionPatches(game), hasLength(1));

      game.debugUnmountLoadedMapForTest('occlusion-map');
      game.update(0);

      expect(_occlusionPatches(game), isEmpty);
    });

    test('repositions occlusion patches with loaded map origin changes',
        () async {
      final game = _game(bundle: _bundle());
      await _load(game);

      game.debugRepositionLoadedMapForTest(
        mapId: 'occlusion-map',
        originCellX: 1,
        originCellY: 0,
      );
      game.update(0);

      var patch = _occlusionPatches(game).single;
      expect(patch.position.x, 64);
      expect(patch.position.y, 32);
      expect(patch.priority, 1064);

      game.debugRepositionLoadedMapForTest(
        mapId: 'occlusion-map',
        originCellX: 2,
        originCellY: 1,
      );
      game.update(0);

      patch = _occlusionPatches(game).single;
      expect(patch.position.x, 96);
      expect(patch.position.y, 64);
      expect(patch.priority, 1096);
    });
  });
}

PlayableMapGame _game({
  required RuntimeMapBundle bundle,
  bool includeElementTilesetImage = true,
}) {
  return PlayableMapGame(
    bundle: bundle,
    projectFilePath: '/tmp/occlusion-project.json',
    runtimeTilesetImageLoader: (
      absolutePathByTilesetId, {
      transparentColorByTilesetId = const <String, TilesetTransparentColor>{},
    }) async {
      final out = <String, RuntimeTilesetImage>{};
      if (absolutePathByTilesetId.containsKey('player')) {
        out['player'] = await _runtimeTilesetImage(
          width: 16,
          height: 32,
          color: const Color(0xFF4070FF),
        );
      }
      if (includeElementTilesetImage &&
          absolutePathByTilesetId.containsKey('entity')) {
        out['entity'] = await _runtimeTilesetImage(
          width: 16,
          height: 16,
          color: const Color(0xFFFF0000),
        );
      }
      return out;
    },
  );
}

Future<void> _load(PlayableMapGame game) async {
  game.onGameResize(Vector2(128, 128));
  await game.onLoad();
  game.update(0);
}

List<PlacedElementOcclusionPatchComponent> _occlusionPatches(
  PlayableMapGame game,
) {
  return game.world.children
      .whereType<PlacedElementOcclusionPatchComponent>()
      .toList(growable: false);
}

RuntimeMapBundle _bundle({
  bool includeOcclusionMask = true,
  bool applyCollision = true,
}) {
  final occlusionMask = includeOcclusionMask ? _mask() : null;
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Playable Occlusion Test',
      maps: const <ProjectMapEntry>[],
      tilesets: const [
        ProjectTilesetEntry(
          id: 'player',
          name: 'Player',
          relativePath: 'tilesets/player.png',
        ),
        ProjectTilesetEntry(
          id: 'entity',
          name: 'Entity',
          relativePath: 'tilesets/entity.png',
        ),
      ],
      settings: const ProjectSettings(
        tileWidth: 16,
        tileHeight: 16,
        displayScale: 2,
        defaultPlayerCharacterId: 'player',
      ),
      characters: const [
        ProjectCharacterEntry(
          id: 'player',
          name: 'Player',
          tilesetId: 'player',
          frameWidth: 1,
          frameHeight: 2,
        ),
      ],
      elements: [
        ProjectElementEntry(
          id: 'house',
          name: 'House',
          tilesetId: 'entity',
          categoryId: 'buildings',
          frames: const [
            TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
          ],
          collisionProfile: occlusionMask == null
              ? null
              : ElementCollisionProfile(
                  source: ElementCollisionProfileSource.manual,
                  occlusionMask: occlusionMask,
                ),
        ),
      ],
      surfaceCatalog: ProjectSurfaceCatalog(),
    ),
    map: MapData(
      id: 'occlusion-map',
      name: 'Occlusion Map',
      size: const GridSize(width: 4, height: 4),
      layers: const [
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: const [
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      placedElements: [
        MapPlacedElement(
          id: 'house-1',
          layerId: 'objects',
          elementId: 'house',
          pos: const GridPos(x: 1, y: 1),
          applyCollision: applyCollision,
        ),
      ],
      mapMetadata: const MapMetadata(defaultSpawnId: 'spawn'),
    ),
    projectRootDirectory: '/tmp/occlusion-runtime-test',
    tilesetAbsolutePathsById: const {
      'player': '/tmp/player.png',
      'entity': '/tmp/entity.png',
    },
  );
}

ElementCollisionPixelMask _mask() {
  final bits = List<bool>.filled(16 * 16, false);
  bits[0] = true;
  return ElementCollisionPixelMask(
    widthPx: 16,
    heightPx: 16,
    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
      widthPx: 16,
      heightPx: 16,
      solidPixels: bits,
    ),
  );
}

Future<RuntimeTilesetImage> _runtimeTilesetImage({
  required int width,
  required int height,
  required Color color,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = color,
  );
  final image = await recorder.endRecording().toImage(width, height);
  return RuntimeTilesetImage(
    images: [image],
    chunks: [
      RuntimeTilesetChunk(top: 0, height: height, width: width),
    ],
    width: width,
    height: height,
  );
}
```

### Note sur le rapport courant

Le rapport courant ne s'inclut pas récursivement dans sa propre section de contenu.
