# Collision Lot 9 — Player Foot Hitbox Preview in Editor V0

## 1. Résumé exécutif

Collision-9 ajoute une prévisualisation pédagogique de la hitbox de déplacement du joueur dans l’éditeur de collision.

Résultat :

- l’éditeur affiche une section `Hitbox joueur` près de la source de collision active ajoutée en Collision-8 ;
- la section explique que le déplacement utilise une petite zone aux pieds du personnage ;
- la section affiche les dimensions réelles issues de `PlayerCollisionConventionsV1` : `12 × 8 px` ;
- une mini-preview dessine le sprite joueur conceptuel et le rectangle de contact en bas ;
- aucune logique gameplay, runtime, normalizer, sérialisation ou génération automatique n’est modifiée.

## 2. Git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
```

Interprétation : le worktree Collision-9 était propre au début du lot.

## 3. Rapports précédents relus

Rapports relus :

- `reports/collision/collision_lot_7_gameplay_legacy_fallback_hardening.md`
- `reports/collision/collision_lot_8_ui_truth_labels.md`

Décisions reprises :

- Collision-7 confirme que `GameplayWorldState` consomme `collisionMask` en priorité, utilise `cells` comme fallback, et ne migre pas les profils.
- Collision-8 affiche déjà la source de collision active : collision fine, collision par grille, absence de collision, occlusion non bloquante.
- Collision-9 ne change pas ce contrat ; il ajoute uniquement l’explication de la zone joueur qui touche cette collision.

## 4. Audit ciblé hitbox joueur

Commandes :

```bash
sed -n '1,220p' packages/map_core/lib/src/collision/player_collision_conventions_v1.dart
sed -n '1,220p' packages/map_core/lib/src/collision/pixel_rect.dart
rg -n "PlayerCollisionConventionsV1|playerCollision|foot|hitbox|PixelRect|collisionPreview|collisionProfile|truthSummary|Collision fine|Collision par grille" packages/map_core/lib packages/map_editor/lib packages/map_editor/test
rg -n "collision/player_collision_conventions_v1|collision/pixel_rect|PlayerCollisionConventionsV1|PixelRect" packages/map_core/lib/map_core.dart packages/map_core/lib/src
```

Constats vérifiés :

- `PlayerCollisionConventionsV1.defaultSpriteWidthPx = 32`.
- `PlayerCollisionConventionsV1.defaultSpriteHeightPx = 32`.
- `PlayerCollisionConventionsV1.playerHitboxWidthPx = 12`.
- `PlayerCollisionConventionsV1.playerHitboxHeightPx = 8`.
- `PlayerCollisionConventionsV1.playerCollisionRectFromSpriteTopLeft(...)` calcule le rectangle de collision depuis le coin haut-gauche du sprite.
- Pour le sprite V1 `32×32`, le rectangle obtenu est `left=10`, `top=24`, `width=12`, `height=8`.
- `packages/map_core/lib/map_core.dart` exporte déjà `pixel_rect.dart` et `player_collision_conventions_v1.dart`; aucun export `map_core` n’est nécessaire.
- Le point d’insertion le moins risqué est `element_collision_editor_sheet.dart`, juste sous la bannière `Source utilisée par le gameplay` ajoutée en Collision-8.

## 5. Design UX retenu

Design retenu :

- créer un read-model editor-only `PlayerCollisionHitboxPreview` dans `packages/map_editor/lib/src/application/models/player_collision_hitbox_preview.dart` ;
- construire ce read-model via `buildPlayerCollisionHitboxPreview(...)` en appelant `PlayerCollisionConventionsV1.playerCollisionRectFromSpriteTopLeft(...)` ;
- afficher une carte `_PlayerFootHitboxPreviewCard` dans la sheet ;
- dessiner une mini-preview par `CustomPainter`, sans asset et sans Flame ;
- ne pas ajouter de simulation de déplacement.

Le read-model accepte aussi une taille de sprite custom pour prouver le centrage, mais l’UI de Collision-9 utilise les valeurs V1 par défaut.

## 6. Contrat affiché à l’utilisateur

Libellés ajoutés :

- `Hitbox joueur`
- `Le déplacement utilise une petite zone aux pieds du personnage. Ce rectangle touche réellement les collisions.`
- `12 × 8 px`
- `Zone de contact centrée en bas du sprite`

Contrat affiché :

- ce n’est pas tout le sprite joueur qui sert aux collisions de déplacement ;
- la zone utile est un rectangle aux pieds ;
- cette zone mesure `12 × 8 px` dans les conventions V1 ;
- la preview est pédagogique et ne lance aucune simulation.

## 7. Fichiers créés

- `packages/map_editor/lib/src/application/models/player_collision_hitbox_preview.dart`
- `packages/map_editor/test/player_collision_hitbox_preview_test.dart`
- `reports/collision/collision_lot_9_player_foot_hitbox_preview.md`

## 8. Fichiers modifiés

- `packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart`

## 9. Fichiers explicitement non modifiés

- `packages/map_core/lib/src/collision/player_collision_conventions_v1.dart`
- `packages/map_core/lib/src/collision/pixel_rect.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_gameplay/**`
- `packages/map_runtime/**`
- `packages/map_battle/**`
- `examples/**`
- `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`
- `packages/map_editor/lib/src/application/collision_generation/**`
- fichiers generated

## 10. Tests ajoutés / modifiés

Fichier créé :

- `packages/map_editor/test/player_collision_hitbox_preview_test.dart`

Tests ajoutés :

- `uses PlayerCollisionConventionsV1 defaults`
- `explains the foot hitbox without saying the full sprite blocks`
- `centers hitbox for custom sprite size`

Aucun test existant n’a été modifié.

## 11. Commandes lancées

Inventaire / audit :

```bash
git status --short --untracked-files=all
find . -path './.git' -prune -o -name AGENTS.md -print
sed -n '1,220p' reports/collision/collision_lot_8_ui_truth_labels.md
sed -n '1,220p' reports/collision/collision_lot_7_gameplay_legacy_fallback_hardening.md
sed -n '1,220p' packages/map_core/lib/src/collision/player_collision_conventions_v1.dart
sed -n '1,220p' packages/map_core/lib/src/collision/pixel_rect.dart
sed -n '1,150p' packages/map_core/lib/map_core.dart
rg -n "PlayerCollisionConventionsV1|playerCollision|foot|hitbox|PixelRect|collisionPreview|collisionProfile|truthSummary|Collision fine|Collision par grille" packages/map_core/lib packages/map_editor/lib packages/map_editor/test
rg -n "collision/player_collision_conventions_v1|collision/pixel_rect|PlayerCollisionConventionsV1|PixelRect" packages/map_core/lib/map_core.dart packages/map_core/lib/src
git diff --name-only
git diff --stat
```

Tests / TDD :

```bash
cd packages/map_editor
flutter test --no-pub --reporter compact test/element_collision_truth_summary_test.dart
flutter test --no-pub --reporter expanded test/player_collision_hitbox_preview_test.dart
flutter test --no-pub --reporter compact test/player_collision_hitbox_preview_test.dart test/element_collision_truth_summary_test.dart
flutter test --no-pub --reporter compact test/element_collision_authoring_service_test.dart test/element_collision_shape_rasterizer_service_test.dart test/project_element_collision_persistence_test.dart test/project_element_collision_file_repository_roundtrip_test.dart
flutter test --no-pub --reporter compact test/player_collision_hitbox_preview_test.dart test/element_collision_truth_summary_test.dart test/element_collision_authoring_service_test.dart test/element_collision_shape_rasterizer_service_test.dart test/project_element_collision_persistence_test.dart test/project_element_collision_file_repository_roundtrip_test.dart
flutter test --no-pub --reporter compact
```

Analyse / format :

```bash
dart format packages/map_editor/lib/src/application/models/player_collision_hitbox_preview.dart packages/map_editor/test/player_collision_hitbox_preview_test.dart packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart
cd packages/map_editor
flutter analyze lib/src/application/models/player_collision_hitbox_preview.dart lib/src/ui/panels/element_collision_editor_sheet.dart test/player_collision_hitbox_preview_test.dart
```

## 12. Résultats des tests ciblés

Baseline avant modification :

```bash
cd packages/map_editor
flutter test --no-pub --reporter compact test/element_collision_truth_summary_test.dart
```

Sortie utile :

```text
00:01 +5: All tests passed!
```

RED TDD avant implémentation :

```bash
cd packages/map_editor
flutter test --no-pub --reporter expanded test/player_collision_hitbox_preview_test.dart
```

Sortie utile :

```text
test/player_collision_hitbox_preview_test.dart:3:8: Error: Error when reading 'lib/src/application/models/player_collision_hitbox_preview.dart': No such file or directory
Method not found: 'buildPlayerCollisionHitboxPreview'.
00:00 +0 -1: Some tests failed.
```

Test du read-model après implémentation :

```bash
cd packages/map_editor
flutter test --no-pub --reporter expanded test/player_collision_hitbox_preview_test.dart
```

Sortie utile :

```text
00:00 +3: All tests passed!
```

Tests read-model Collision-9 + résumé Collision-8 :

```bash
cd packages/map_editor
flutter test --no-pub --reporter compact test/player_collision_hitbox_preview_test.dart test/element_collision_truth_summary_test.dart
```

Sortie utile :

```text
00:01 +8: All tests passed!
```

Tests ciblés collision editor :

```bash
cd packages/map_editor
flutter test --no-pub --reporter compact test/element_collision_authoring_service_test.dart test/element_collision_shape_rasterizer_service_test.dart test/project_element_collision_persistence_test.dart test/project_element_collision_file_repository_roundtrip_test.dart
```

Sortie utile :

```text
00:02 +36: All tests passed!
```

Vérification ciblée finale groupée :

```bash
cd packages/map_editor
flutter test --no-pub --reporter compact test/player_collision_hitbox_preview_test.dart test/element_collision_truth_summary_test.dart test/element_collision_authoring_service_test.dart test/element_collision_shape_rasterizer_service_test.dart test/project_element_collision_persistence_test.dart test/project_element_collision_file_repository_roundtrip_test.dart
```

Sortie utile :

```text
00:02 +44: All tests passed!
```

Suite complète `map_editor` :

```bash
cd packages/map_editor
flutter test --no-pub --reporter compact
```

Sortie utile :

```text
01:45 +1431 -42: Some tests failed.
```

Échecs visibles dans la sortie capturée :

- plusieurs tests UI/catalogues hors Collision-9 ne compilent pas à cause de `ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog())` utilisé dans une expression `const` alors que `ProjectSurfaceCatalog()` n’est pas const ;
- `test/environment_studio/tile_layer_environment_erase_mode_test.dart` échoue avec `EnvironmentMaskEditMode.erase` alors que le test attend `null` ;
- `test/update_pokedex_species_learnset_use_case_test.dart` échoue avec une entrée `protect` absente du catalogue local de moves.

Décision : ces échecs sont hors périmètre Collision-9 et ne sont pas modifiés dans ce lot.

## 13. Analyse statique / format

Format :

```bash
dart format packages/map_editor/lib/src/application/models/player_collision_hitbox_preview.dart packages/map_editor/test/player_collision_hitbox_preview_test.dart packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart
```

Sortie utile :

```text
Formatted packages/map_editor/lib/src/application/models/player_collision_hitbox_preview.dart
Formatted 3 files (1 changed) in 0.02 seconds.
```

Analyse ciblée :

```bash
cd packages/map_editor
flutter analyze lib/src/application/models/player_collision_hitbox_preview.dart lib/src/ui/panels/element_collision_editor_sheet.dart test/player_collision_hitbox_preview_test.dart
```

Sortie utile :

```text
Analyzing 3 items...
No issues found! (ran in 2.1s)
```

## 14. Vérification du périmètre

Commande :

```bash
git diff --name-only
```

Sortie avant création du rapport :

```text
packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart
```

Fichiers untracked créés par Collision-9 avant rapport :

```text
packages/map_editor/lib/src/application/models/player_collision_hitbox_preview.dart
packages/map_editor/test/player_collision_hitbox_preview_test.dart
```

Contrôle :

- Aucun fichier `packages/map_core/**` modifié.
- Aucun fichier `packages/map_gameplay/**` modifié.
- Aucun fichier `packages/map_runtime/**` modifié.
- Aucun fichier `packages/map_battle/**` modifié.
- Aucun fichier generated modifié.
- Aucun fichier `FileProjectRepository` modifié.

## 15. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart
?? packages/map_editor/lib/src/application/models/player_collision_hitbox_preview.dart
?? packages/map_editor/test/player_collision_hitbox_preview_test.dart
?? reports/collision/collision_lot_9_player_foot_hitbox_preview.md
```

## 16. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie avant création du rapport :

```text
 .../ui/panels/element_collision_editor_sheet.dart  | 142 ++++++++++++++++++++-
 1 file changed, 141 insertions(+), 1 deletion(-)
```

Note : `git diff --stat` ne liste pas les fichiers untracked ; ils sont listés dans le `git status` final.

## 17. Risques / réserves

Risque : la preview est pédagogique et non interactive.

Impact : elle explique la hitbox joueur réelle, mais elle ne teste pas un déplacement contre la collision de l’élément dans l’éditeur.

Décision Collision-9 : rester hors simulation, conformément au lot.

Non vérifié.

**Sujet :**
Test widget de la carte `_PlayerFootHitboxPreviewCard`.

**Raison :**
La carte est un widget privé de la sheet ; le lot couvre le contrat par read-model testé et analyse statique, sans monter toute la sheet.

**Impact :**
Les textes et dimensions sont couverts par tests unitaires, mais la présence visuelle exacte dans l’arbre widget n’a pas de test dédié.

**Comment vérifier dans Collision-10 :**
Ajouter un test widget ciblé sur l’ouverture de la sheet collision ou extraire la carte si l’éditeur gagne une couche de tests UI dédiée aux previews pédagogiques.

## 18. Préparation de Collision-10

Collision-10 peut maintenant combiner :

- source active de collision affichée par Collision-8 ;
- hitbox joueur affichée par Collision-9 ;
- bâtiment test / golden slice pour vérifier que l’auteur comprend à la fois la silhouette collisionnelle et la zone de contact du joueur.

## 19. Auto-review finale

- Ai-je limité le lot à `map_editor` ? Oui.
- Ai-je évité `map_gameplay` ? Oui.
- Ai-je évité `map_runtime` ? Oui.
- Ai-je évité `FileProjectRepository` ? Oui.
- Ai-je évité le normalizer ? Oui.
- Ai-je évité `build_runner` et generated ? Oui.
- Ai-je utilisé les conventions joueur existantes ? Oui, via `PlayerCollisionConventionsV1`.
- Ai-je évité de hardcoder des valeurs fausses ? Oui, les dimensions viennent de `map_core`.
- Ai-je expliqué que seule la zone aux pieds sert au déplacement ? Oui.
- Ai-je évité de modifier la hitbox réelle ? Oui.
- Ai-je ajouté des tests ciblés ? Oui, trois tests du read-model.
- Ai-je gardé une UX compréhensible pour non-développeur ? Oui, la carte parle de `Hitbox joueur`, `zone aux pieds`, `déplacement` et `zone de contact`.

## 20. Contenu complet des fichiers créés/modifiés

### `packages/map_editor/lib/src/application/models/player_collision_hitbox_preview.dart`

```dart
import 'package:map_core/map_core.dart';

final class PlayerCollisionHitboxPreview {
  const PlayerCollisionHitboxPreview({
    required this.spriteWidthPx,
    required this.spriteHeightPx,
    required this.hitboxLeftPx,
    required this.hitboxTopPx,
    required this.hitboxWidthPx,
    required this.hitboxHeightPx,
    required this.title,
    required this.description,
    required this.dimensionsLabel,
    required this.positionLabel,
  });

  final int spriteWidthPx;
  final int spriteHeightPx;
  final int hitboxLeftPx;
  final int hitboxTopPx;
  final int hitboxWidthPx;
  final int hitboxHeightPx;
  final String title;
  final String description;
  final String dimensionsLabel;
  final String positionLabel;
}

PlayerCollisionHitboxPreview buildPlayerCollisionHitboxPreview({
  int spriteWidthPx = PlayerCollisionConventionsV1.defaultSpriteWidthPx,
  int spriteHeightPx = PlayerCollisionConventionsV1.defaultSpriteHeightPx,
}) {
  final hitbox =
      PlayerCollisionConventionsV1.playerCollisionRectFromSpriteTopLeft(
    spriteTopLeftPx: const PixelPosition(leftPx: 0, topPx: 0),
    spriteWidthPx: spriteWidthPx,
    spriteHeightPx: spriteHeightPx,
  );

  return PlayerCollisionHitboxPreview(
    spriteWidthPx: spriteWidthPx,
    spriteHeightPx: spriteHeightPx,
    hitboxLeftPx: hitbox.leftPx,
    hitboxTopPx: hitbox.topPx,
    hitboxWidthPx: hitbox.widthPx,
    hitboxHeightPx: hitbox.heightPx,
    title: 'Hitbox joueur',
    description:
        'Le déplacement utilise une petite zone aux pieds du personnage. '
        'Ce rectangle touche réellement les collisions.',
    dimensionsLabel: '${hitbox.widthPx} × ${hitbox.heightPx} px',
    positionLabel: 'Zone de contact centrée en bas du sprite',
  );
}

```

### `packages/map_editor/test/player_collision_hitbox_preview_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/player_collision_hitbox_preview.dart';

void main() {
  group('buildPlayerCollisionHitboxPreview', () {
    test('uses PlayerCollisionConventionsV1 defaults', () {
      final preview = buildPlayerCollisionHitboxPreview();

      expect(
        preview.spriteWidthPx,
        PlayerCollisionConventionsV1.defaultSpriteWidthPx,
      );
      expect(
        preview.spriteHeightPx,
        PlayerCollisionConventionsV1.defaultSpriteHeightPx,
      );
      expect(
        preview.hitboxWidthPx,
        PlayerCollisionConventionsV1.playerHitboxWidthPx,
      );
      expect(
        preview.hitboxHeightPx,
        PlayerCollisionConventionsV1.playerHitboxHeightPx,
      );
      expect(preview.hitboxLeftPx, 10);
      expect(preview.hitboxTopPx, 24);
    });

    test('explains the foot hitbox without saying the full sprite blocks', () {
      final preview = buildPlayerCollisionHitboxPreview();

      expect(preview.title, 'Hitbox joueur');
      expect(preview.description, contains('zone aux pieds'));
      expect(preview.description, contains('déplacement'));
      expect(preview.description, isNot(contains('tout le sprite bloque')));
      expect(preview.dimensionsLabel, '12 × 8 px');
      expect(preview.positionLabel, contains('centrée en bas'));
    });

    test('centers hitbox for custom sprite size', () {
      final preview = buildPlayerCollisionHitboxPreview(
        spriteWidthPx: 48,
        spriteHeightPx: 40,
      );

      expect(preview.spriteWidthPx, 48);
      expect(preview.spriteHeightPx, 40);
      expect(preview.hitboxLeftPx, 18);
      expect(preview.hitboxTopPx, 32);
      expect(preview.hitboxWidthPx, 12);
      expect(preview.hitboxHeightPx, 8);
    });
  });
}

```

### Diff complet du fichier modifié `packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart`

```diff
diff --git a/packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart b/packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart
index 79e3bd29..25607385 100644
--- a/packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart
+++ b/packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart
@@ -7,8 +7,9 @@ import 'package:flutter/material.dart' show Colors;
 import 'package:macos_ui/macos_ui.dart';
 import 'package:map_core/map_core.dart';
 
-import '../../application/services/element_collision_authoring_service.dart';
 import '../../application/models/element_collision_truth_summary.dart';
+import '../../application/models/player_collision_hitbox_preview.dart';
+import '../../application/services/element_collision_authoring_service.dart';
 import '../../ui/shared/cupertino_editor_widgets.dart';
 
 const ElementCollisionAuthoringService _authoringService =
@@ -88,6 +89,7 @@ class _ElementCollisionEditorSheetState
   Widget build(BuildContext context) {
     final snapshot = _describe();
     final truthSummary = summarizeElementCollisionTruth(_draftProfile);
+    final playerHitboxPreview = buildPlayerCollisionHitboxPreview();
     final pendingPolygonPreviewCells = _buildPendingPolygonPreviewCells();
     final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
     final label = CupertinoColors.label.resolveFrom(context);
@@ -189,6 +191,8 @@ class _ElementCollisionEditorSheetState
                 ),
                 const SizedBox(height: 14),
                 _CollisionTruthBanner(summary: truthSummary),
+                const SizedBox(height: 10),
+                _PlayerFootHitboxPreviewCard(preview: playerHitboxPreview),
                 const SizedBox(height: 14),
                 Expanded(
                   child: Row(
@@ -929,6 +933,142 @@ class _CollisionTruthBanner extends StatelessWidget {
   }
 }
 
+class _PlayerFootHitboxPreviewCard extends StatelessWidget {
+  const _PlayerFootHitboxPreviewCard({required this.preview});
+
+  final PlayerCollisionHitboxPreview preview;
+
+  @override
+  Widget build(BuildContext context) {
+    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
+    final label = CupertinoColors.label.resolveFrom(context);
+    return Container(
+      padding: const EdgeInsets.all(12),
+      decoration: BoxDecoration(
+        color: Colors.blueAccent.withValues(alpha: 0.08),
+        borderRadius: BorderRadius.circular(12),
+        border: Border.all(
+          color: Colors.blueAccent.withValues(alpha: 0.30),
+        ),
+      ),
+      child: Row(
+        crossAxisAlignment: CrossAxisAlignment.center,
+        children: [
+          SizedBox(
+            width: 70,
+            height: 70,
+            child: CustomPaint(
+              painter: _PlayerFootHitboxPreviewPainter(preview),
+            ),
+          ),
+          const SizedBox(width: 12),
+          Expanded(
+            child: Column(
+              crossAxisAlignment: CrossAxisAlignment.start,
+              mainAxisSize: MainAxisSize.min,
+              children: [
+                Text(
+                  preview.title,
+                  style: TextStyle(
+                    color: label,
+                    fontSize: 13,
+                    fontWeight: FontWeight.w700,
+                  ),
+                ),
+                const SizedBox(height: 3),
+                Text(
+                  preview.description,
+                  style: TextStyle(color: secondary, fontSize: 11),
+                ),
+                const SizedBox(height: 5),
+                Wrap(
+                  spacing: 8,
+                  runSpacing: 6,
+                  children: [
+                    _LegendChip(
+                      label: preview.dimensionsLabel,
+                      color: Colors.blueAccent,
+                    ),
+                    _LegendChip(
+                      label: preview.positionLabel,
+                      color: Colors.lightBlueAccent,
+                    ),
+                  ],
+                ),
+              ],
+            ),
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _PlayerFootHitboxPreviewPainter extends CustomPainter {
+  const _PlayerFootHitboxPreviewPainter(this.preview);
+
+  final PlayerCollisionHitboxPreview preview;
+
+  @override
+  void paint(Canvas canvas, Size size) {
+    final scale = math.min(
+      size.width / preview.spriteWidthPx,
+      size.height / preview.spriteHeightPx,
+    );
+    final spriteWidth = preview.spriteWidthPx * scale;
+    final spriteHeight = preview.spriteHeightPx * scale;
+    final spriteRect = Rect.fromLTWH(
+      (size.width - spriteWidth) / 2,
+      (size.height - spriteHeight) / 2,
+      spriteWidth,
+      spriteHeight,
+    );
+    final hitboxRect = Rect.fromLTWH(
+      spriteRect.left + preview.hitboxLeftPx * scale,
+      spriteRect.top + preview.hitboxTopPx * scale,
+      preview.hitboxWidthPx * scale,
+      preview.hitboxHeightPx * scale,
+    );
+
+    final spritePaint = Paint()
+      ..color = Colors.white.withValues(alpha: 0.08)
+      ..style = PaintingStyle.fill;
+    final spriteStroke = Paint()
+      ..color = Colors.white.withValues(alpha: 0.32)
+      ..style = PaintingStyle.stroke
+      ..strokeWidth = 1;
+    final hitboxPaint = Paint()
+      ..color = Colors.blueAccent.withValues(alpha: 0.38)
+      ..style = PaintingStyle.fill;
+    final hitboxStroke = Paint()
+      ..color = Colors.lightBlueAccent
+      ..style = PaintingStyle.stroke
+      ..strokeWidth = 1.5;
+
+    canvas.drawRRect(
+      RRect.fromRectAndRadius(spriteRect, const Radius.circular(8)),
+      spritePaint,
+    );
+    canvas.drawRRect(
+      RRect.fromRectAndRadius(spriteRect, const Radius.circular(8)),
+      spriteStroke,
+    );
+    canvas.drawRRect(
+      RRect.fromRectAndRadius(hitboxRect, const Radius.circular(3)),
+      hitboxPaint,
+    );
+    canvas.drawRRect(
+      RRect.fromRectAndRadius(hitboxRect, const Radius.circular(3)),
+      hitboxStroke,
+    );
+  }
+
+  @override
+  bool shouldRepaint(covariant _PlayerFootHitboxPreviewPainter oldDelegate) {
+    return oldDelegate.preview != preview;
+  }
+}
+
 class ElementCollisionPaddingEditor extends StatelessWidget {
   const ElementCollisionPaddingEditor({
     super.key,

```

### Contenu complet du fichier modifié `packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart`

```dart
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../application/models/element_collision_truth_summary.dart';
import '../../application/models/player_collision_hitbox_preview.dart';
import '../../application/services/element_collision_authoring_service.dart';
import '../../ui/shared/cupertino_editor_widgets.dart';

const ElementCollisionAuthoringService _authoringService =
    ElementCollisionAuthoringService();

Future<ElementCollisionProfile?> showElementCollisionEditorSheet({
  required BuildContext context,
  required String elementName,
  required ui.Image image,
  required TilesetSourceRect source,
  required int tileWidth,
  required int tileHeight,
  ElementCollisionProfile? initialProfile,
  WarpTriggerPadding fallbackPadding = const WarpTriggerPadding(),
}) {
  return showMacosEditorTallSheet<ElementCollisionProfile>(
    context: context,
    heightFraction: 0.92,
    maxWidth: 1180,
    builder: (ctx) => _ElementCollisionEditorSheet(
      elementName: elementName,
      image: image,
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      initialProfile: initialProfile,
      fallbackPadding: fallbackPadding,
    ),
  );
}

class _ElementCollisionEditorSheet extends StatefulWidget {
  const _ElementCollisionEditorSheet({
    required this.elementName,
    required this.image,
    required this.source,
    required this.tileWidth,
    required this.tileHeight,
    required this.initialProfile,
    required this.fallbackPadding,
  });

  final String elementName;
  final ui.Image image;
  final TilesetSourceRect source;
  final int tileWidth;
  final int tileHeight;
  final ElementCollisionProfile? initialProfile;
  final WarpTriggerPadding fallbackPadding;

  @override
  State<_ElementCollisionEditorSheet> createState() =>
      _ElementCollisionEditorSheetState();
}

class _ElementCollisionEditorSheetState
    extends State<_ElementCollisionEditorSheet> {
  _ElementCollisionEditorTool _tool = _ElementCollisionEditorTool.preview;
  ElementCollisionProfile? _draftProfile;
  late WarpTriggerPadding _draftPadding;
  bool _showGrid = true;
  bool _showBase = true;
  bool _showFinal = true;
  bool _showOverrides = true;
  final List<Offset> _pendingPolygon = <Offset>[];
  Offset? _lastBrushPoint;
  Offset? _hoverGridPoint;

  @override
  void initState() {
    super.initState();
    _draftProfile = widget.initialProfile;
    _draftPadding = widget.initialProfile?.padding ?? widget.fallbackPadding;
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _describe();
    final truthSummary = summarizeElementCollisionTruth(_draftProfile);
    final playerHitboxPreview = buildPlayerCollisionHitboxPreview();
    final pendingPolygonPreviewCells = _buildPendingPolygonPreviewCells();
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);
    return LayoutBuilder(
      builder: (context, constraints) => Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) {
            return KeyEventResult.ignored;
          }
          if (_isPolygonTool(_tool) &&
              event.logicalKey == LogicalKeyboardKey.enter &&
              _pendingPolygon.length >= 3) {
            _closeAndApplyPendingPolygon();
            return KeyEventResult.handled;
          }
          if (_isPolygonTool(_tool) &&
              event.logicalKey == LogicalKeyboardKey.escape &&
              _pendingPolygon.isNotEmpty) {
            setState(() {
              _pendingPolygon.clear();
              _hoverGridPoint = null;
            });
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EditorHeader(
                  elementName: widget.elementName,
                  source: widget.source,
                  finalCellCount: snapshot.finalCells.length,
                  onCancel: () => Navigator.of(context).pop(),
                  onSave: () => Navigator.of(context).pop(_buildSavedProfile()),
                ),
                const SizedBox(height: 14),
                _EditorToolbar(
                  tool: _tool,
                  pendingPolygonCount: _pendingPolygon.length,
                  onToolChanged: (tool) {
                    setState(() {
                      _tool = tool;
                      _lastBrushPoint = null;
                      _hoverGridPoint = null;
                      if (!_isPolygonTool(tool)) {
                        _pendingPolygon.clear();
                      }
                    });
                  },
                  onClosePolygon: _pendingPolygon.length >= 3
                      ? _closeAndApplyPendingPolygon
                      : null,
                  onClearPolygon: _pendingPolygon.isNotEmpty
                      ? () => setState(() {
                            _pendingPolygon.clear();
                            _hoverGridPoint = null;
                          })
                      : null,
                  onResetOverrides: () {
                    setState(() {
                      _draftProfile = _authoringService.resetOverrides(
                        source: widget.source,
                        tileWidth: widget.tileWidth,
                        tileHeight: widget.tileHeight,
                        current: _draftProfile,
                        fallbackPadding: _draftPadding,
                      );
                      _draftPadding = _draftProfile?.padding ?? _draftPadding;
                    });
                  },
                  onRestoreBase: () {
                    setState(() {
                      _draftProfile = _authoringService.usePaddingAsPrimaryBase(
                        source: widget.source,
                        tileWidth: widget.tileWidth,
                        tileHeight: widget.tileHeight,
                        padding: _draftPadding,
                      );
                    });
                  },
                  onClearAll: () {
                    setState(() {
                      _draftProfile = _authoringService.clearAllCollision(
                        source: widget.source,
                        tileWidth: widget.tileWidth,
                        tileHeight: widget.tileHeight,
                        current: _draftProfile,
                        fallbackPadding: _draftPadding,
                      );
                    });
                  },
                ),
                const SizedBox(height: 14),
                _CollisionTruthBanner(summary: truthSummary),
                const SizedBox(height: 10),
                _PlayerFootHitboxPreviewCard(preview: playerHitboxPreview),
                const SizedBox(height: 14),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: EditorChrome.largeIslandSurfaceColor(
                              context,
                              tint: Colors.white.withValues(alpha: 0.02),
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: CupertinoColors.separator
                                  .resolveFrom(context),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Forme de collision',
                                    style: TextStyle(
                                      color: label,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _tool.helpLabel,
                                    style: TextStyle(
                                      color: secondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, canvasConstraints) {
                                    final canvasSize = Size(
                                      canvasConstraints.maxWidth,
                                      canvasConstraints.maxHeight,
                                    );
                                    return MouseRegion(
                                      cursor: _tool ==
                                              _ElementCollisionEditorTool
                                                  .preview
                                          ? SystemMouseCursors.basic
                                          : SystemMouseCursors.precise,
                                      onHover: (event) {
                                        final next = _localToGridPoint(
                                          event.localPosition,
                                          canvasSize,
                                        );
                                        if (next == _hoverGridPoint) {
                                          return;
                                        }
                                        setState(() => _hoverGridPoint = next);
                                      },
                                      onExit: (_) {
                                        if (_hoverGridPoint != null) {
                                          setState(
                                              () => _hoverGridPoint = null);
                                        }
                                      },
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTapUp: (details) => _handleCanvasTap(
                                            details.localPosition, canvasSize),
                                        onDoubleTapDown: (details) =>
                                            _handleCanvasDoubleTap(
                                          details.localPosition,
                                          canvasSize,
                                        ),
                                        onPanStart: (details) =>
                                            _handleCanvasPanStart(
                                          details.localPosition,
                                          canvasSize,
                                        ),
                                        onPanUpdate: (details) =>
                                            _handleCanvasPanUpdate(
                                          details.localPosition,
                                          canvasSize,
                                        ),
                                        onPanEnd: (_) => _lastBrushPoint = null,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            color: Colors.black
                                                .withValues(alpha: 0.14),
                                            border: Border.all(
                                              color: CupertinoColors.separator
                                                  .resolveFrom(context),
                                            ),
                                          ),
                                          child: CustomPaint(
                                            painter:
                                                _ElementCollisionCanvasPainter(
                                              image: widget.image,
                                              source: widget.source,
                                              tileWidth: widget.tileWidth,
                                              tileHeight: widget.tileHeight,
                                              snapshot: snapshot,
                                              showGrid: _showGrid,
                                              showBase: _showBase,
                                              showFinal: _showFinal,
                                              showOverrides: _showOverrides,
                                              pendingPolygon: _pendingPolygon,
                                              pendingPolygonPreviewCells:
                                                  pendingPolygonPreviewCells,
                                              hoverGridPoint: _hoverGridPoint,
                                              highlightPolygonClosure:
                                                  _shouldHighlightPolygonClosure,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      SizedBox(
                        width: 320,
                        child: _EditorSidebar(
                          source: widget.source,
                          snapshot: snapshot,
                          truthSummary: truthSummary,
                          showGrid: _showGrid,
                          showBase: _showBase,
                          showFinal: _showFinal,
                          showOverrides: _showOverrides,
                          pendingPolygonPreviewCount:
                              pendingPolygonPreviewCells.length,
                          onShowGridChanged: (value) =>
                              setState(() => _showGrid = value),
                          onShowBaseChanged: (value) =>
                              setState(() => _showBase = value),
                          onShowFinalChanged: (value) =>
                              setState(() => _showFinal = value),
                          onShowOverridesChanged: (value) =>
                              setState(() => _showOverrides = value),
                          paddingEditor: ElementCollisionPaddingEditor(
                            padding: _draftPadding,
                            usesManualPrimaryShape:
                                snapshot.usesManualPrimaryShape,
                            maxHorizontal: math.max(
                                0, widget.source.width * widget.tileWidth - 1),
                            maxVertical: math.max(0,
                                widget.source.height * widget.tileHeight - 1),
                            onChanged: (next) {
                              setState(() {
                                _draftPadding = next;
                                _draftProfile =
                                    _authoringService.recalculateFromPadding(
                                  source: widget.source,
                                  tileWidth: widget.tileWidth,
                                  tileHeight: widget.tileHeight,
                                  padding: next,
                                  current: _draftProfile,
                                );
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ElementCollisionAuthoringSnapshot _describe() {
    return _authoringService.describe(
      source: widget.source,
      tileWidth: widget.tileWidth,
      tileHeight: widget.tileHeight,
      profile: _draftProfile,
      fallbackPadding: _draftPadding,
    );
  }

  List<GridPos> _buildPendingPolygonPreviewCells() {
    if (!_isPolygonTool(_tool) || _pendingPolygon.length < 3) {
      return const <GridPos>[];
    }
    // The polygon itself is the authoring truth while editing. These preview
    // cells are the backend projection that will actually reach runtime after
    // closing/saving, so the author can judge the conversion before commit.
    return _authoringService.shapeRasterizerService.rasterizePolygon(
      vertices: _pendingPolygon,
      gridWidth: widget.source.width,
      gridHeight: widget.source.height,
    );
  }

  ElementCollisionProfile _buildSavedProfile() {
    final snapshot = _describe();
    return _authoringService.rebuild(
      source: widget.source,
      tileWidth: widget.tileWidth,
      tileHeight: widget.tileHeight,
      sourceMode: snapshot.source,
      padding: snapshot.padding,
      shapeCells: snapshot.shapeCells,
      manualAddedCells: snapshot.manualAddedCells,
      manualRemovedCells: snapshot.manualRemovedCells,
    );
  }

  void _closeAndApplyPendingPolygon() {
    if (_pendingPolygon.length < 3) {
      return;
    }
    final operation = _tool.operation;
    if (operation == null) {
      return;
    }
    setState(() {
      _draftProfile = _authoringService.applyPolygon(
        source: widget.source,
        tileWidth: widget.tileWidth,
        tileHeight: widget.tileHeight,
        vertices: List<Offset>.from(_pendingPolygon),
        operation: operation,
        current: _draftProfile,
        fallbackPadding: _draftPadding,
      );
      _pendingPolygon.clear();
      _hoverGridPoint = null;
    });
  }

  void _handleCanvasTap(Offset localPosition, Size canvasSize) {
    if (_tool == _ElementCollisionEditorTool.preview) {
      return;
    }
    final gridPoint = _localToGridPoint(localPosition, canvasSize);
    if (gridPoint == null) {
      return;
    }
    if (_isPolygonTool(_tool)) {
      if (_pendingPolygon.length >= 3 &&
          _isNearPolygonStart(gridPoint, _pendingPolygon.first)) {
        _closeAndApplyPendingPolygon();
        return;
      }
      setState(() {
        _pendingPolygon.add(gridPoint);
      });
      return;
    }

    final operation = _tool.operation;
    if (operation == null) {
      return;
    }
    setState(() {
      _draftProfile = _authoringService.applyBrushStroke(
        source: widget.source,
        tileWidth: widget.tileWidth,
        tileHeight: widget.tileHeight,
        points: <Offset>[gridPoint],
        operation: operation,
        current: _draftProfile,
        fallbackPadding: _draftPadding,
      );
    });
  }

  void _handleCanvasDoubleTap(Offset localPosition, Size canvasSize) {
    if (!_isPolygonTool(_tool) || _pendingPolygon.length < 3) {
      return;
    }
    final gridPoint = _localToGridPoint(localPosition, canvasSize);
    if (gridPoint == null) {
      return;
    }
    setState(() => _hoverGridPoint = gridPoint);
    _closeAndApplyPendingPolygon();
  }

  void _handleCanvasPanStart(Offset localPosition, Size canvasSize) {
    if (!_isBrushTool(_tool)) {
      return;
    }
    final gridPoint = _localToGridPoint(localPosition, canvasSize);
    if (gridPoint == null) {
      return;
    }
    _lastBrushPoint = gridPoint;
    final operation = _tool.operation;
    if (operation == null) {
      return;
    }
    setState(() {
      _draftProfile = _authoringService.applyBrushStroke(
        source: widget.source,
        tileWidth: widget.tileWidth,
        tileHeight: widget.tileHeight,
        points: <Offset>[gridPoint],
        operation: operation,
        current: _draftProfile,
        fallbackPadding: _draftPadding,
      );
    });
  }

  void _handleCanvasPanUpdate(Offset localPosition, Size canvasSize) {
    if (!_isBrushTool(_tool)) {
      return;
    }
    final gridPoint = _localToGridPoint(localPosition, canvasSize);
    if (gridPoint == null) {
      return;
    }
    final previous = _lastBrushPoint;
    final operation = _tool.operation;
    if (previous == null || operation == null) {
      _lastBrushPoint = gridPoint;
      return;
    }
    if ((previous - gridPoint).distance < 0.001) {
      return;
    }
    setState(() {
      _draftProfile = _authoringService.applyBrushStroke(
        source: widget.source,
        tileWidth: widget.tileWidth,
        tileHeight: widget.tileHeight,
        points: <Offset>[previous, gridPoint],
        operation: operation,
        current: _draftProfile,
        fallbackPadding: _draftPadding,
      );
      _lastBrushPoint = gridPoint;
    });
  }

  Offset? _localToGridPoint(Offset localPosition, Size canvasSize) {
    final targetRect = _fitCollisionPreviewRect(
      size: canvasSize,
      source: widget.source,
      tileWidth: widget.tileWidth,
      tileHeight: widget.tileHeight,
      padding: 24,
    );
    if (!targetRect.contains(localPosition)) {
      return null;
    }
    final localX = localPosition.dx - targetRect.left;
    final localY = localPosition.dy - targetRect.top;
    final gridX = (localX / targetRect.width) * widget.source.width;
    final gridY = (localY / targetRect.height) * widget.source.height;
    return Offset(gridX, gridY);
  }

  bool _isBrushTool(_ElementCollisionEditorTool tool) {
    return tool == _ElementCollisionEditorTool.brushAdd ||
        tool == _ElementCollisionEditorTool.brushRemove;
  }

  bool _isPolygonTool(_ElementCollisionEditorTool tool) {
    return tool == _ElementCollisionEditorTool.polygonAdd ||
        tool == _ElementCollisionEditorTool.polygonRemove;
  }

  bool get _shouldHighlightPolygonClosure {
    if (!_isPolygonTool(_tool) ||
        _pendingPolygon.length < 3 ||
        _hoverGridPoint == null) {
      return false;
    }
    return _isNearPolygonStart(_hoverGridPoint!, _pendingPolygon.first);
  }

  bool _isNearPolygonStart(Offset point, Offset start) {
    return (point - start).distance <= 0.45;
  }
}

class _EditorHeader extends StatelessWidget {
  const _EditorHeader({
    required this.elementName,
    required this.source,
    required this.finalCellCount,
    required this.onCancel,
    required this.onSave,
  });

  final String elementName;
  final TilesetSourceRect source;
  final int finalCellCount;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Collision Editor',
                style: editorMacosSheetTitleStyle(context),
              ),
              const SizedBox(height: 4),
              Text(
                '$elementName • source ${source.width}x${source.height} • $finalCellCount cellule${finalCellCount > 1 ? 's' : ''} finales',
                style: TextStyle(
                  color: secondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        PushButton(
          controlSize: ControlSize.large,
          secondary: true,
          onPressed: onCancel,
          child: const Text('Annuler'),
        ),
        const SizedBox(width: 10),
        PushButton(
          controlSize: ControlSize.large,
          onPressed: onSave,
          child: const Text('Sauvegarder'),
        ),
      ],
    );
  }
}

class _EditorToolbar extends StatelessWidget {
  const _EditorToolbar({
    required this.tool,
    required this.pendingPolygonCount,
    required this.onToolChanged,
    required this.onClosePolygon,
    required this.onClearPolygon,
    required this.onResetOverrides,
    required this.onRestoreBase,
    required this.onClearAll,
  });

  final _ElementCollisionEditorTool tool;
  final int pendingPolygonCount;
  final ValueChanged<_ElementCollisionEditorTool> onToolChanged;
  final VoidCallback? onClosePolygon;
  final VoidCallback? onClearPolygon;
  final VoidCallback onResetOverrides;
  final VoidCallback onRestoreBase;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final value in _ElementCollisionEditorTool.values)
          _ToolButton(
            label: value.label,
            selected: tool == value,
            onPressed: () => onToolChanged(value),
          ),
        if (tool == _ElementCollisionEditorTool.polygonAdd ||
            tool == _ElementCollisionEditorTool.polygonRemove)
          _ToolbarAction(
            label: 'Fermer le polygone ($pendingPolygonCount)',
            onPressed: onClosePolygon,
          ),
        if (tool == _ElementCollisionEditorTool.polygonAdd ||
            tool == _ElementCollisionEditorTool.polygonRemove)
          _ToolbarAction(
            label: 'Effacer le polygone',
            onPressed: onClearPolygon,
          ),
        _ToolbarAction(
          label: 'Réinitialiser retouches',
          onPressed: onResetOverrides,
        ),
        _ToolbarAction(
          label: 'Utiliser le padding comme base',
          onPressed: onRestoreBase,
        ),
        _ToolbarAction(
          label: 'Vider toute collision',
          onPressed: onClearAll,
        ),
      ],
    );
  }
}

class _EditorSidebar extends StatelessWidget {
  const _EditorSidebar({
    required this.source,
    required this.snapshot,
    required this.truthSummary,
    required this.showGrid,
    required this.showBase,
    required this.showFinal,
    required this.showOverrides,
    required this.onShowGridChanged,
    required this.onShowBaseChanged,
    required this.onShowFinalChanged,
    required this.onShowOverridesChanged,
    this.pendingPolygonPreviewCount = 0,
    required this.paddingEditor,
  });

  final TilesetSourceRect source;
  final ElementCollisionAuthoringSnapshot snapshot;
  final ElementCollisionTruthSummary truthSummary;
  final bool showGrid;
  final bool showBase;
  final bool showFinal;
  final bool showOverrides;
  final ValueChanged<bool> onShowGridChanged;
  final ValueChanged<bool> onShowBaseChanged;
  final ValueChanged<bool> onShowFinalChanged;
  final ValueChanged<bool> onShowOverridesChanged;
  final int pendingPolygonPreviewCount;
  final Widget paddingEditor;

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SidebarSection(
          title: 'Résumé',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _LegendChip(
                    label: snapshot.usesManualPrimaryShape
                        ? 'Forme principale ${snapshot.baseCells.length}'
                        : 'Base padding ${snapshot.baseCells.length}',
                    color: Colors.cyanAccent,
                  ),
                  _LegendChip(
                    label: '+ ${snapshot.manualAddedCells.length}',
                    color: Colors.greenAccent,
                  ),
                  _LegendChip(
                    label: '- ${snapshot.manualRemovedCells.length}',
                    color: Colors.redAccent,
                  ),
                  _LegendChip(
                    label: 'Final ${snapshot.finalCells.length}',
                    color: EditorChrome.inspectorJoyCoral,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                truthSummary.mode == ElementCollisionTruthMode.fineMask
                    ? 'Le gameplay utilise le masque fin. Les ${snapshot.finalCells.length} cellule${snapshot.finalCells.length > 1 ? 's' : ''} affichées ici servent de projection de compatibilité.'
                    : 'Le gameplay utilise ${snapshot.finalCells.length} cellule${snapshot.finalCells.length > 1 ? 's' : ''} de grille quand aucun masque fin n’est défini.',
                style: TextStyle(
                  color: secondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Source sprite: ${source.width} colonnes × ${source.height} lignes',
                style: TextStyle(
                  color: secondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                snapshot.source == ElementCollisionProfileSource.manual
                    ? 'Base métier actuelle: forme principale auteur. Le padding reste disponible comme aide secondaire, mais il ne reprend pas la main au rebuild.'
                    : 'Base métier actuelle: padding automatique. Utilisez un polygone forme si vous voulez remplacer cette base par une vraie silhouette de bâtiment.',
                style: TextStyle(
                  color: secondary,
                  fontSize: 11,
                ),
              ),
              if (pendingPolygonPreviewCount > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Preview backend polygone: $pendingPolygonPreviewCount cellule${pendingPolygonPreviewCount > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.yellowAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SidebarSection(
          title: 'Padding auto',
          child: paddingEditor,
        ),
        const SizedBox(height: 12),
        _SidebarSection(
          title: 'Affichage',
          child: Column(
            children: [
              _DisplayToggle(
                label: 'Grille',
                value: showGrid,
                onChanged: onShowGridChanged,
              ),
              _DisplayToggle(
                label: snapshot.usesManualPrimaryShape
                    ? 'Forme principale'
                    : 'Base padding',
                value: showBase,
                onChanged: onShowBaseChanged,
              ),
              _DisplayToggle(
                label: 'Retouches manuelles',
                value: showOverrides,
                onChanged: onShowOverridesChanged,
              ),
              _DisplayToggle(
                label: 'Forme finale',
                value: showFinal,
                onChanged: onShowFinalChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SidebarSection(
          title: 'Aide',
          child: Text(
            'Polygone forme: définit une base coarse de bâtiment. Pinceau + / -: applique des retouches locales. Le padding auto reste un outil secondaire pour les cas simples. Le gameplay suit la source active affichée en haut.',
            style: TextStyle(
              color: secondary,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class _CollisionTruthBanner extends StatelessWidget {
  const _CollisionTruthBanner({required this.summary});

  final ElementCollisionTruthSummary summary;

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);
    final accent = switch (summary.mode) {
      ElementCollisionTruthMode.fineMask => Colors.redAccent,
      ElementCollisionTruthMode.legacyCells => Colors.orangeAccent,
      ElementCollisionTruthMode.empty => Colors.greenAccent,
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Source utilisée par le gameplay',
            style: TextStyle(
              color: secondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            summary.title,
            style: TextStyle(
              color: label,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            summary.description,
            style: TextStyle(color: secondary, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            summary.detail,
            style: TextStyle(color: secondary, fontSize: 11),
          ),
          for (final note in summary.notes) ...[
            const SizedBox(height: 2),
            Text(
              note,
              style: TextStyle(color: secondary, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlayerFootHitboxPreviewCard extends StatelessWidget {
  const _PlayerFootHitboxPreviewCard({required this.preview});

  final PlayerCollisionHitboxPreview preview;

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blueAccent.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: CustomPaint(
              painter: _PlayerFootHitboxPreviewPainter(preview),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  preview.title,
                  style: TextStyle(
                    color: label,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  preview.description,
                  style: TextStyle(color: secondary, fontSize: 11),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _LegendChip(
                      label: preview.dimensionsLabel,
                      color: Colors.blueAccent,
                    ),
                    _LegendChip(
                      label: preview.positionLabel,
                      color: Colors.lightBlueAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerFootHitboxPreviewPainter extends CustomPainter {
  const _PlayerFootHitboxPreviewPainter(this.preview);

  final PlayerCollisionHitboxPreview preview;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(
      size.width / preview.spriteWidthPx,
      size.height / preview.spriteHeightPx,
    );
    final spriteWidth = preview.spriteWidthPx * scale;
    final spriteHeight = preview.spriteHeightPx * scale;
    final spriteRect = Rect.fromLTWH(
      (size.width - spriteWidth) / 2,
      (size.height - spriteHeight) / 2,
      spriteWidth,
      spriteHeight,
    );
    final hitboxRect = Rect.fromLTWH(
      spriteRect.left + preview.hitboxLeftPx * scale,
      spriteRect.top + preview.hitboxTopPx * scale,
      preview.hitboxWidthPx * scale,
      preview.hitboxHeightPx * scale,
    );

    final spritePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    final spriteStroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final hitboxPaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.38)
      ..style = PaintingStyle.fill;
    final hitboxStroke = Paint()
      ..color = Colors.lightBlueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(spriteRect, const Radius.circular(8)),
      spritePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(spriteRect, const Radius.circular(8)),
      spriteStroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(hitboxRect, const Radius.circular(3)),
      hitboxPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(hitboxRect, const Radius.circular(3)),
      hitboxStroke,
    );
  }

  @override
  bool shouldRepaint(covariant _PlayerFootHitboxPreviewPainter oldDelegate) {
    return oldDelegate.preview != preview;
  }
}

class ElementCollisionPaddingEditor extends StatelessWidget {
  const ElementCollisionPaddingEditor({
    super.key,
    required this.padding,
    required this.usesManualPrimaryShape,
    required this.maxHorizontal,
    required this.maxVertical,
    required this.onChanged,
  });

  final WarpTriggerPadding padding;
  final bool usesManualPrimaryShape;
  final int maxHorizontal;
  final int maxVertical;
  final ValueChanged<WarpTriggerPadding> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          usesManualPrimaryShape
              ? 'Le padding reste stocké comme réglage secondaire. Tant qu’une forme principale auteur existe, il ne redéfinit pas la base métier.'
              : 'Le padding génère la base automatique actuelle. Vous pouvez ensuite ajouter ou retirer quelques cellules localement.',
          style: TextStyle(
            color: secondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PaddingStepper(
              label: 'Top',
              value: padding.top,
              maxValue: maxVertical,
              onChanged: (v) => onChanged(padding.copyWith(top: v)),
            ),
            _PaddingStepper(
              label: 'Right',
              value: padding.right,
              maxValue: maxHorizontal,
              onChanged: (v) => onChanged(padding.copyWith(right: v)),
            ),
            _PaddingStepper(
              label: 'Bottom',
              value: padding.bottom,
              maxValue: maxVertical,
              onChanged: (v) => onChanged(padding.copyWith(bottom: v)),
            ),
            _PaddingStepper(
              label: 'Left',
              value: padding.left,
              maxValue: maxHorizontal,
              onChanged: (v) => onChanged(padding.copyWith(left: v)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Valeurs actuelles: T${padding.top} R${padding.right} B${padding.bottom} L${padding.left}',
          style: TextStyle(
            color: label,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PaddingStepper extends StatelessWidget {
  const _PaddingStepper({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int maxValue;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final canDecrease = value > 0;
    final canIncrease = value < maxValue;
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: TextStyle(
              color: secondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              GestureDetector(
                onTap: canDecrease ? () => onChanged(value - 1) : null,
                child: Icon(
                  CupertinoIcons.minus_circle_fill,
                  size: 18,
                  color: canDecrease
                      ? labelColor
                      : labelColor.withValues(alpha: 0.25),
                ),
              ),
              Expanded(
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: canIncrease ? () => onChanged(value + 1) : null,
                child: Icon(
                  CupertinoIcons.plus_circle_fill,
                  size: 18,
                  color: canIncrease
                      ? labelColor
                      : labelColor.withValues(alpha: 0.25),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SidebarSection extends StatelessWidget {
  const _SidebarSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final label = CupertinoColors.label.resolveFrom(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: Colors.white.withValues(alpha: 0.018),
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: label,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DisplayToggle extends StatelessWidget {
  const _DisplayToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          MacosSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: CupertinoColors.label.resolveFrom(context),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const accent = EditorChrome.inspectorJoyCoral;
    final labelColor = CupertinoColors.label.resolveFrom(context);
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      minimumSize: Size.zero,
      borderRadius: BorderRadius.circular(10),
      color: selected ? accent.withValues(alpha: 0.16) : Colors.black26,
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: selected ? accent : labelColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ToolbarAction extends StatelessWidget {
  const _ToolbarAction({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return PushButton(
      controlSize: ControlSize.small,
      secondary: true,
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class _ElementCollisionCanvasPainter extends CustomPainter {
  _ElementCollisionCanvasPainter({
    required this.image,
    required this.source,
    required this.tileWidth,
    required this.tileHeight,
    required this.snapshot,
    required this.showGrid,
    required this.showBase,
    required this.showFinal,
    required this.showOverrides,
    required this.pendingPolygon,
    required this.pendingPolygonPreviewCells,
    required this.hoverGridPoint,
    required this.highlightPolygonClosure,
  });

  final ui.Image image;
  final TilesetSourceRect source;
  final int tileWidth;
  final int tileHeight;
  final ElementCollisionAuthoringSnapshot snapshot;
  final bool showGrid;
  final bool showBase;
  final bool showFinal;
  final bool showOverrides;
  final List<Offset> pendingPolygon;
  final List<GridPos> pendingPolygonPreviewCells;
  final Offset? hoverGridPoint;
  final bool highlightPolygonClosure;

  @override
  void paint(Canvas canvas, Size size) {
    final targetRect = _fitCollisionPreviewRect(
      size: size,
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      padding: 24,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          targetRect.inflate(10), const Radius.circular(18)),
      Paint()..color = Colors.black.withValues(alpha: 0.1),
    );

    final sourceRect = Rect.fromLTWH(
      source.x * tileWidth.toDouble(),
      source.y * tileHeight.toDouble(),
      source.width * tileWidth.toDouble(),
      source.height * tileHeight.toDouble(),
    );
    if (sourceRect.right <= image.width && sourceRect.bottom <= image.height) {
      canvas.drawImageRect(
        image,
        sourceRect,
        targetRect,
        Paint()
          ..isAntiAlias = false
          ..filterQuality = FilterQuality.none,
      );
    }

    final cellWidth = targetRect.width / source.width;
    final cellHeight = targetRect.height / source.height;

    if (showBase) {
      for (final cell in snapshot.baseCells) {
        _fillCell(
          canvas,
          cell: cell,
          targetRect: targetRect,
          cellWidth: cellWidth,
          cellHeight: cellHeight,
          color: Colors.cyanAccent.withValues(alpha: 0.16),
        );
      }
    }

    if (showFinal) {
      for (final cell in snapshot.finalCells) {
        _fillCell(
          canvas,
          cell: cell,
          targetRect: targetRect,
          cellWidth: cellWidth,
          cellHeight: cellHeight,
          color: EditorChrome.inspectorJoyCoral.withValues(alpha: 0.18),
          strokeColor: EditorChrome.inspectorJoyCoral,
        );
      }
    }

    if (pendingPolygonPreviewCells.isNotEmpty) {
      for (final cell in pendingPolygonPreviewCells) {
        _fillCell(
          canvas,
          cell: cell,
          targetRect: targetRect,
          cellWidth: cellWidth,
          cellHeight: cellHeight,
          color: Colors.yellowAccent.withValues(alpha: 0.14),
          strokeColor: Colors.yellowAccent.withValues(alpha: 0.85),
        );
      }
    }

    if (showOverrides) {
      for (final cell in snapshot.manualAddedCells) {
        final cellRect = _cellRect(
          cell,
          targetRect: targetRect,
          cellWidth: cellWidth,
          cellHeight: cellHeight,
        );
        canvas.drawRect(
          cellRect.deflate(2),
          Paint()
            ..color = Colors.greenAccent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );
      }

      for (final cell in snapshot.manualRemovedCells) {
        final cellRect = _cellRect(
          cell,
          targetRect: targetRect,
          cellWidth: cellWidth,
          cellHeight: cellHeight,
        );
        canvas.drawRect(
          cellRect,
          Paint()
            ..color = Colors.redAccent.withValues(alpha: 0.16)
            ..style = PaintingStyle.fill,
        );
        final strikePaint = Paint()
          ..color = Colors.redAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4;
        canvas.drawLine(cellRect.topLeft, cellRect.bottomRight, strikePaint);
        canvas.drawLine(cellRect.topRight, cellRect.bottomLeft, strikePaint);
      }
    }

    if (showGrid) {
      final gridPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..strokeWidth = 1;
      for (var x = 0; x <= source.width; x++) {
        final dx = targetRect.left + x * cellWidth;
        canvas.drawLine(
          Offset(dx, targetRect.top),
          Offset(dx, targetRect.bottom),
          gridPaint,
        );
      }
      for (var y = 0; y <= source.height; y++) {
        final dy = targetRect.top + y * cellHeight;
        canvas.drawLine(
          Offset(targetRect.left, dy),
          Offset(targetRect.right, dy),
          gridPaint,
        );
      }
    }

    if (pendingPolygon.isNotEmpty) {
      final path = Path();
      final points = pendingPolygon
          .map((point) => Offset(
                targetRect.left + (point.dx / source.width) * targetRect.width,
                targetRect.top + (point.dy / source.height) * targetRect.height,
              ))
          .toList(growable: false);
      path.moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.yellowAccent.withValues(alpha: 0.95)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      for (final point in points) {
        canvas.drawCircle(
          point,
          4,
          Paint()..color = Colors.yellowAccent,
        );
      }
      canvas.drawCircle(
        points.first,
        highlightPolygonClosure ? 9 : 6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = highlightPolygonClosure ? 3 : 1.5
          ..color = highlightPolygonClosure
              ? Colors.greenAccent
              : Colors.yellowAccent.withValues(alpha: 0.8),
      );
      if (hoverGridPoint != null && highlightPolygonClosure) {
        final hoverPoint = Offset(
          targetRect.left +
              (hoverGridPoint!.dx / source.width) * targetRect.width,
          targetRect.top +
              (hoverGridPoint!.dy / source.height) * targetRect.height,
        );
        canvas.drawLine(
          hoverPoint,
          points.first,
          Paint()
            ..color = Colors.greenAccent.withValues(alpha: 0.85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
      if (points.length >= 3) {
        final preview = Path.from(path)..close();
        canvas.drawPath(
          preview,
          Paint()
            ..color = Colors.yellowAccent.withValues(alpha: 0.12)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  void _fillCell(
    Canvas canvas, {
    required GridPos cell,
    required Rect targetRect,
    required double cellWidth,
    required double cellHeight,
    required Color color,
    Color? strokeColor,
  }) {
    final rect = _cellRect(
      cell,
      targetRect: targetRect,
      cellWidth: cellWidth,
      cellHeight: cellHeight,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    if (strokeColor != null) {
      canvas.drawRect(
        rect,
        Paint()
          ..color = strokeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  Rect _cellRect(
    GridPos cell, {
    required Rect targetRect,
    required double cellWidth,
    required double cellHeight,
  }) {
    return Rect.fromLTWH(
      targetRect.left + cell.x * cellWidth,
      targetRect.top + cell.y * cellHeight,
      cellWidth,
      cellHeight,
    );
  }

  @override
  bool shouldRepaint(covariant _ElementCollisionCanvasPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.source != source ||
        oldDelegate.tileWidth != tileWidth ||
        oldDelegate.tileHeight != tileHeight ||
        oldDelegate.snapshot != snapshot ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.showBase != showBase ||
        oldDelegate.showFinal != showFinal ||
        oldDelegate.showOverrides != showOverrides ||
        !_sameCells(oldDelegate.pendingPolygonPreviewCells,
            pendingPolygonPreviewCells) ||
        oldDelegate.hoverGridPoint != hoverGridPoint ||
        oldDelegate.highlightPolygonClosure != highlightPolygonClosure ||
        !_sameOffsets(oldDelegate.pendingPolygon, pendingPolygon);
  }

  bool _sameOffsets(List<Offset> a, List<Offset> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  bool _sameCells(List<GridPos> a, List<GridPos> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}

Rect _fitCollisionPreviewRect({
  required Size size,
  required TilesetSourceRect source,
  required int tileWidth,
  required int tileHeight,
  double padding = 0,
}) {
  final sourcePixelWidth = source.width * tileWidth.toDouble();
  final sourcePixelHeight = source.height * tileHeight.toDouble();
  final safeRect = Rect.fromLTWH(
    padding,
    padding,
    math.max(0, size.width - padding * 2),
    math.max(0, size.height - padding * 2),
  );
  if (sourcePixelWidth <= 0 ||
      sourcePixelHeight <= 0 ||
      safeRect.width <= 0 ||
      safeRect.height <= 0) {
    return safeRect;
  }
  final sourceAspect = sourcePixelWidth / sourcePixelHeight;
  final targetAspect = safeRect.width / safeRect.height;
  if (sourceAspect > targetAspect) {
    final height = safeRect.width / sourceAspect;
    final top = safeRect.top + (safeRect.height - height) / 2;
    return Rect.fromLTWH(safeRect.left, top, safeRect.width, height);
  }
  final width = safeRect.height * sourceAspect;
  final left = safeRect.left + (safeRect.width - width) / 2;
  return Rect.fromLTWH(left, safeRect.top, width, safeRect.height);
}

enum _ElementCollisionEditorTool {
  preview(
    label: 'Aperçu',
    helpLabel: 'Visualiser la forme finale exacte qui sera sauvegardée.',
  ),
  brushAdd(
    label: 'Pinceau +',
    helpLabel: 'Cliquez-glissez pour ajouter des retouches locales.',
    operation: ElementCollisionAuthoringOperation.add,
  ),
  brushRemove(
    label: 'Pinceau -',
    helpLabel: 'Cliquez-glissez pour retirer des retouches locales.',
    operation: ElementCollisionAuthoringOperation.remove,
  ),
  polygonAdd(
    label: 'Polygone forme',
    helpLabel:
        'Placez des points, puis fermez le polygone pour remplacer la forme principale.',
    operation: ElementCollisionAuthoringOperation.add,
  ),
  polygonRemove(
    label: 'Polygone -',
    helpLabel: 'Placez des points, puis retirez cette zone.',
    operation: ElementCollisionAuthoringOperation.remove,
  );

  const _ElementCollisionEditorTool({
    required this.label,
    required this.helpLabel,
    this.operation,
  });

  final String label;
  final String helpLabel;
  final ElementCollisionAuthoringOperation? operation;
}

```
