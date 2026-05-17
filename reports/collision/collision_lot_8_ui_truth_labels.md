# Collision Lot 8 — UI Truth Labels / PixelMask vs Cells V0

## 1. Résumé exécutif

Collision-8 ajoute une couche UX légère dans `map_editor` pour rendre visible la donnée réellement utilisée par le gameplay :

- `collisionMask` devient visible comme "Collision fine active" côté UI.
- `cells` est présenté comme "Collision par grille" seulement quand aucun masque fin n’existe.
- `visualMask` est décrit comme aperçu/analyse, jamais comme collision.
- `occlusionMask` est décrit comme rendu devant/derrière, non bloquant.
- Le terme JSON historique `pixelMask` n’est pas exposé comme libellé principal utilisateur.

Le lot ne modifie pas le moteur de collision, le normalizer, le gameplay, le runtime, la génération automatique, le JSON schema ou `FileProjectRepository`.

## 2. Git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
```

Interprétation : le worktree Collision-8 était propre au début du lot.

## 3. Rapports précédents relus

Rapports relus dans ce worktree :

- `reports/collision/collision_lot_4_element_collision_profile_normalizer.md`
- `reports/collision/collision_lot_5_collision_mask_cells_projection_contract.md`
- `reports/collision/collision_lot_6_editor_persistence_uses_normalizer.md`
- `reports/collision/collision_lot_7_gameplay_legacy_fallback_hardening.md`

Décisions reprises :

- `collisionMask` est la vérité gameplay fine.
- `pixelMask` reste le nom JSON historique.
- `cells` est projection / fallback / compatibilité.
- `visualMask` reste une aide d’analyse / aperçu.
- `occlusionMask` reste hors collision et ne bloque pas le joueur.
- `map_gameplay` consomme les profils déjà normalisés et ne fait pas de migration cachée.

## 4. Audit ciblé UI collision

Commande de recherche principale :

```bash
rg -n "collisionMask|pixelMask|cells|shapeCells|manualAddedCells|manualRemovedCells|visualMask|occlusionMask|collisionProfile|Collision|collision|Masque|mask|grille|legacy|runtime|gameplay|pinceau|polygone|padding" packages/map_editor/lib packages/map_editor/test
```

Fichiers inspectés :

- `packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart`
- `packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/collision/element_collision_editor.dart`
- `packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/collision/element_collision_profile_painter.dart`
- `packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart`
- `packages/map_editor/lib/src/application/services/element_collision_authoring_service.dart`
- `packages/map_editor/lib/src/application/services/element_collision_profile_generator.dart`
- `packages/map_editor/lib/src/application/services/element_collision_cells_overlay_service.dart`

Constats :

- `element_collision_editor_sheet.dart` affichait un texte obsolète indiquant que le runtime lisait uniquement `collisionProfile.cells`.
- `element_collision_editor.dart` présentait la forme finale en cellules comme la lecture runtime, sans distinguer le masque fin.
- `element_collision_triple_mask_editor.dart` séparait déjà collision et occlusion, mais ne présentait pas clairement la source active sous la forme partagée avec les autres vues.
- `element_collision_profile_painter.dart` ne contient pas de texte utilisateur ; aucune modification utile dans ce lot.
- Les services authoring restent cohérents avec le flux coarse ; aucune modification de logique nécessaire.

## 5. Design UX retenu

Design retenu : un read-model UI/application pur, plus deux surfaces d’affichage.

Fichier créé :

- `packages/map_editor/lib/src/application/models/element_collision_truth_summary.dart`

API :

```dart
ElementCollisionTruthSummary summarizeElementCollisionTruth(
  ElementCollisionProfile? profile,
)
```

Modes :

- `fineMask` : `collisionMask` présent, collision fine active.
- `legacyCells` : `collisionMask` absent et `cells` non vide, collision par grille.
- `empty` : aucune collision active.

Raisons :

- Les libellés restent hors `map_core`, donc les modèles domaine ne portent pas du texte produit.
- Les widgets ne dupliquent pas la logique de décision.
- Les tests unitaires peuvent couvrir la vérité UI sans tests widget lourds.

## 6. Contrat affiché à l’utilisateur

Libellés principaux :

- `Collision fine active`
- `Collision par grille`
- `Aucune collision active`

Textes affichés :

- Masque fin : `Le gameplay utilise le masque de collision fin.`
- Grille : `Aucun masque fin n’est défini. Le gameplay utilise les cellules de la grille comme fallback.`
- Vide : `Cet élément ne bloque pas le joueur.`
- Masque visuel : `Masque visuel disponible pour l’aperçu/analyse : il ne bloque pas le joueur.`
- Masque d’occlusion : `Masque d’occlusion disponible : il sert au rendu devant/derrière et ne bloque pas le joueur.`

Dans l’éditeur coarse, l’ancien message `runtime lit uniquement cells` est remplacé par une explication conditionnelle :

- si masque fin présent : la grille affichée est une projection de compatibilité ;
- sinon : la grille est le fallback de gameplay.

## 7. Fichiers créés

- `packages/map_editor/lib/src/application/models/element_collision_truth_summary.dart`
- `packages/map_editor/test/element_collision_truth_summary_test.dart`
- `reports/collision/collision_lot_8_ui_truth_labels.md`

## 8. Fichiers modifiés

- `packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart`
- `packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/collision/element_collision_editor.dart`
- `packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart`
- `packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart`

Note de format : `dart format` a reformatté deux lignes préexistantes dans `tileset_palette_panel.dart` et quelques lignes longues dans `element_collision_triple_mask_editor.dart`. Ces changements sont mécaniques et visibles dans le diff.

## 9. Fichiers explicitement non modifiés

- `packages/map_core/**`
- `packages/map_gameplay/**`
- `packages/map_runtime/**`
- `packages/map_battle/**`
- `examples/**`
- `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`
- `packages/map_editor/lib/src/application/collision_generation/**`
- fichiers generated

## 10. Tests ajoutés / modifiés

Fichier créé :

- `packages/map_editor/test/element_collision_truth_summary_test.dart`

Tests ajoutés :

- `returns fineMask when collisionMask exists`
- `returns legacyCells when only cells exist`
- `visualMask alone does not make collision active`
- `occlusionMask alone does not make collision active`
- `returns empty when profile is null`

Aucun test existant n’a été modifié.

## 11. Commandes lancées

Inventaire / audit :

```bash
git status --short --untracked-files=all
rg -n "collisionMask|pixelMask|cells|shapeCells|manualAddedCells|manualRemovedCells|visualMask|occlusionMask|collisionProfile|Collision|collision|Masque|mask|grille|legacy|runtime|gameplay|pinceau|polygone|padding" packages/map_editor/lib packages/map_editor/test
git diff --name-only
git diff --stat
```

Tests :

```bash
cd packages/map_editor
flutter test --no-pub --reporter compact test/element_collision_authoring_service_test.dart test/element_collision_shape_rasterizer_service_test.dart
flutter test --no-pub --reporter expanded test/element_collision_truth_summary_test.dart
flutter test --no-pub --reporter compact test/element_collision_truth_summary_test.dart test/element_collision_authoring_service_test.dart test/element_collision_shape_rasterizer_service_test.dart test/project_element_collision_persistence_test.dart test/project_element_collision_file_repository_roundtrip_test.dart
flutter test --no-pub --reporter compact
```

Analyse / format :

```bash
cd packages/map_editor
flutter analyze lib/src/application/models/element_collision_truth_summary.dart lib/src/ui/panels/tileset_palette_panel.dart lib/src/ui/panels/element_collision_editor_sheet.dart lib/src/ui/widgets/element_collision_triple_mask_editor.dart test/element_collision_truth_summary_test.dart
cd ../..
dart format packages/map_editor/lib/src/application/models/element_collision_truth_summary.dart packages/map_editor/test/element_collision_truth_summary_test.dart packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/collision/element_collision_editor.dart packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart
dart format --output=none --set-exit-if-changed packages/map_editor/lib/src/application/models/element_collision_truth_summary.dart packages/map_editor/test/element_collision_truth_summary_test.dart packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/collision/element_collision_editor.dart packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart
```

## 12. Résultats des tests ciblés

Baseline avant modification :

```bash
cd packages/map_editor
flutter test --no-pub --reporter compact test/element_collision_authoring_service_test.dart test/element_collision_shape_rasterizer_service_test.dart
```

Sortie utile :

```text
00:01 +29: All tests passed!
```

RED TDD du nouveau test avant implémentation :

```bash
cd packages/map_editor
flutter test --no-pub --reporter expanded test/element_collision_truth_summary_test.dart
```

Sortie utile :

```text
Error when reading 'lib/src/application/models/element_collision_truth_summary.dart'
Method not found: 'summarizeElementCollisionTruth'
Undefined name 'ElementCollisionTruthMode'
00:00 +0 -1: Some tests failed.
```

Test du read-model après implémentation :

```bash
cd packages/map_editor
flutter test --no-pub --reporter expanded test/element_collision_truth_summary_test.dart
```

Sortie utile :

```text
00:00 +5: All tests passed!
```

Tests ciblés finaux :

```bash
cd packages/map_editor
flutter test --no-pub --reporter compact test/element_collision_truth_summary_test.dart test/element_collision_authoring_service_test.dart test/element_collision_shape_rasterizer_service_test.dart test/project_element_collision_persistence_test.dart test/project_element_collision_file_repository_roundtrip_test.dart
```

Sortie utile :

```text
00:01 +41: All tests passed!
```

Suite complète `map_editor` :

```bash
cd packages/map_editor
flutter test --no-pub --reporter compact
```

Sortie utile :

```text
01:37 +1428 -42: Some tests failed.
```

Échecs visibles dans la sortie capturée :

- Plusieurs tests hors Collision-8 ne compilent pas à cause de `const ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog(), ...)` avec constructeur non-const dans des fichiers UI/catalogues.
- `test/environment_studio/tile_layer_environment_erase_mode_test.dart` attend `null` et reçoit `EnvironmentMaskEditMode.erase`.
- `test/update_pokedex_species_learnset_use_case_test.dart` échoue car `protect` est absent du catalogue local de moves.

Décision : ces échecs sont hors périmètre Collision-8 et ne sont pas modifiés dans ce lot.

## 13. Analyse statique / format

Première analyse après implémentation :

```text
3 issues found:
- prefer_const_constructors dans element_collision_editor_sheet.dart
- prefer_const_declarations dans element_collision_triple_mask_editor.dart
- prefer_const_declarations dans element_collision_triple_mask_editor.dart
```

Correction appliquée : ajout de `const` sur le `TextStyle` concerné et sur les couleurs du checkerboard.

Analyse ciblée finale :

```bash
cd packages/map_editor
flutter analyze lib/src/application/models/element_collision_truth_summary.dart lib/src/ui/panels/tileset_palette_panel.dart lib/src/ui/panels/element_collision_editor_sheet.dart lib/src/ui/widgets/element_collision_triple_mask_editor.dart test/element_collision_truth_summary_test.dart
```

Sortie utile :

```text
Analyzing 5 items...
No issues found! (ran in 2.5s)
```

Format appliqué :

```text
Formatted packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart
Formatted packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart
Formatted 6 files (2 changed) in 0.05 seconds.
```

Contrôle format final :

```text
Formatted 6 files (0 changed) in 0.05 seconds.
```

## 14. Vérification du périmètre

Commande :

```bash
git diff --name-only
```

Sortie :

```text
packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart
packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/collision/element_collision_editor.dart
packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart
packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart
```

Untracked créés par Collision-8 :

```text
packages/map_editor/lib/src/application/models/element_collision_truth_summary.dart
packages/map_editor/test/element_collision_truth_summary_test.dart
reports/collision/collision_lot_8_ui_truth_labels.md
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
 M packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/collision/element_collision_editor.dart
 M packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart
 M packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart
?? packages/map_editor/lib/src/application/models/element_collision_truth_summary.dart
?? packages/map_editor/test/element_collision_truth_summary_test.dart
?? reports/collision/collision_lot_8_ui_truth_labels.md
```

## 16. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text
 .../ui/panels/element_collision_editor_sheet.dart  | 79 +++++++++++++++++++++-
 .../collision/element_collision_editor.dart        | 66 ++++++++++++++++--
 .../lib/src/ui/panels/tileset_palette_panel.dart   |  9 +--
 .../element_collision_triple_mask_editor.dart      | 36 +++++++---
 4 files changed, 165 insertions(+), 25 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers untracked ; ils sont listés dans le `git status` final.

## 17. Risques / réserves

Risque : les libellés UI restent en texte direct dans les widgets, sans infrastructure d’i18n.

Impact : si une internationalisation arrive, ces textes devront être déplacés dans la couche prévue.

Décision Collision-8 : conserver le style actuel du package, qui utilise déjà des libellés directs.

Non vérifié.

**Sujet :**
Tests widget visuels complets de l’éditeur collision.

**Raison :**
Le lot ajoute des tests unitaires du read-model et valide les tests services/persistence ciblés. Aucun test widget collision existant n’a été identifié comme point d’extension léger.

**Impact :**
Les textes sont couverts par le read-model, mais l’affichage exact dans tous les layouts n’a pas de test widget dédié.

**Comment vérifier dans Collision-9 ou Collision-10 :**
Ajouter un test widget ciblé sur `ElementCollisionEditor` ou sur la sheet quand l’infrastructure de montage du panneau collision est stabilisée.

## 18. Préparation de Collision-9 / Collision-10

Collision-9 peut ajouter une preview de hitbox joueur en s’appuyant sur les mêmes libellés :

- la source active est déjà résumée ;
- l’UI distingue déjà masque fin, grille et absence de collision ;
- l’occlusion est clairement non bloquante.

Collision-10 peut ajouter une golden slice bâtiment :

- le read-model peut servir de contrôle textuel ;
- les tests gameplay existants peuvent être reliés à une vue editor plus concrète ;
- aucun nouveau modèle domaine n’est requis pour cette étape.

## 19. Auto-review finale

- Ai-je limité le lot à `map_editor` ? Oui.
- Ai-je évité `map_core` ? Oui.
- Ai-je évité `map_gameplay` ? Oui.
- Ai-je évité `map_runtime` ? Oui.
- Ai-je évité `FileProjectRepository` ? Oui.
- Ai-je évité `build_runner` et les fichiers generated ? Oui.
- Ai-je rendu visible `collisionMask` comme vérité fine ? Oui, via `Collision fine active`.
- Ai-je évité d’exposer `pixelMask` comme jargon principal ? Oui.
- Ai-je clarifié `cells` comme projection/fallback ? Oui.
- Ai-je clarifié `visualMask` comme preview/analyse ? Oui.
- Ai-je clarifié `occlusionMask` comme non bloquant ? Oui.
- Ai-je évité de changer la logique de collision ? Oui.
- Ai-je ajouté des tests ciblés ? Oui, cinq tests du read-model.
- Ai-je gardé une UX compréhensible pour non-développeur ? Oui, les libellés principaux utilisent "collision fine", "collision par grille" et "aucune collision active".

## 20. Contenu complet des fichiers créés/modifiés

### `packages/map_editor/lib/src/application/models/element_collision_truth_summary.dart`

```dart
import 'package:map_core/map_core.dart';

enum ElementCollisionTruthMode {
  fineMask,
  legacyCells,
  empty,
}

final class ElementCollisionTruthSummary {
  const ElementCollisionTruthSummary({
    required this.mode,
    required this.title,
    required this.description,
    required this.detail,
    required this.hasCollisionMask,
    required this.hasLegacyCells,
    required this.hasVisualMask,
    required this.hasOcclusionMask,
    this.notes = const <String>[],
  });

  final ElementCollisionTruthMode mode;
  final String title;
  final String description;
  final String detail;
  final bool hasCollisionMask;
  final bool hasLegacyCells;
  final bool hasVisualMask;
  final bool hasOcclusionMask;
  final List<String> notes;

  bool get hasActiveCollision => mode != ElementCollisionTruthMode.empty;
}

ElementCollisionTruthSummary summarizeElementCollisionTruth(
  ElementCollisionProfile? profile,
) {
  final hasCollisionMask = profile?.collisionMask != null;
  final hasLegacyCells = profile?.cells.isNotEmpty ?? false;
  final hasVisualMask = profile?.visualMask != null;
  final hasOcclusionMask = profile?.occlusionMask != null;
  final notes = <String>[
    if (hasVisualMask)
      'Masque visuel disponible pour l’aperçu/analyse : il ne bloque pas le joueur.',
    if (hasOcclusionMask)
      'Masque d’occlusion disponible : il sert au rendu devant/derrière et ne bloque pas le joueur.',
  ];

  if (hasCollisionMask) {
    return ElementCollisionTruthSummary(
      mode: ElementCollisionTruthMode.fineMask,
      title: 'Collision fine active',
      description: 'Le gameplay utilise le masque de collision fin.',
      detail:
          'La grille sert de projection de compatibilité et d’aperçu grossier.',
      hasCollisionMask: hasCollisionMask,
      hasLegacyCells: hasLegacyCells,
      hasVisualMask: hasVisualMask,
      hasOcclusionMask: hasOcclusionMask,
      notes: notes,
    );
  }

  if (hasLegacyCells) {
    return ElementCollisionTruthSummary(
      mode: ElementCollisionTruthMode.legacyCells,
      title: 'Collision par grille',
      description:
          'Aucun masque fin n’est défini. Le gameplay utilise les cellules de la grille comme fallback.',
      detail: 'La précision est limitée à la grille de l’élément.',
      hasCollisionMask: hasCollisionMask,
      hasLegacyCells: hasLegacyCells,
      hasVisualMask: hasVisualMask,
      hasOcclusionMask: hasOcclusionMask,
      notes: notes,
    );
  }

  return ElementCollisionTruthSummary(
    mode: ElementCollisionTruthMode.empty,
    title: 'Aucune collision active',
    description: 'Cet élément ne bloque pas le joueur.',
    detail: 'Aucun masque fin ni cellule de collision n’est défini.',
    hasCollisionMask: hasCollisionMask,
    hasLegacyCells: hasLegacyCells,
    hasVisualMask: hasVisualMask,
    hasOcclusionMask: hasOcclusionMask,
    notes: notes,
  );
}
```

### `packages/map_editor/test/element_collision_truth_summary_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/element_collision_truth_summary.dart';

void main() {
  group('summarizeElementCollisionTruth', () {
    test('returns fineMask when collisionMask exists', () {
      final summary = summarizeElementCollisionTruth(
        ElementCollisionProfile(
          collisionMask: _mask(),
          cells: const [GridPos(x: 4, y: 4)],
        ),
      );

      expect(summary.mode, ElementCollisionTruthMode.fineMask);
      expect(summary.title, contains('Collision fine'));
      expect(summary.description, contains('gameplay'));
      expect(summary.description, contains('masque de collision fin'));
      expect(summary.detail, contains('grille'));
      expect(summary.detail, contains('projection'));
      expect(summary.hasCollisionMask, isTrue);
      expect(summary.hasLegacyCells, isTrue);
    });

    test('returns legacyCells when only cells exist', () {
      final summary = summarizeElementCollisionTruth(
        const ElementCollisionProfile(
          cells: [GridPos(x: 0, y: 0)],
        ),
      );

      expect(summary.mode, ElementCollisionTruthMode.legacyCells);
      expect(summary.title, contains('Collision par grille'));
      expect(summary.description, contains('fallback'));
      expect(summary.description, contains('cellules'));
      expect(summary.hasCollisionMask, isFalse);
      expect(summary.hasLegacyCells, isTrue);
    });

    test('visualMask alone does not make collision active', () {
      final summary = summarizeElementCollisionTruth(
        ElementCollisionProfile(visualMask: _mask()),
      );

      expect(summary.mode, ElementCollisionTruthMode.empty);
      expect(summary.title, contains('Aucune collision active'));
      expect(summary.description, contains('ne bloque pas'));
      expect(summary.hasVisualMask, isTrue);
      expect(summary.notes.join(' '), contains('aperçu/analyse'));
      expect(summary.notes.join(' '), contains('ne bloque pas'));
    });

    test('occlusionMask alone does not make collision active', () {
      final summary = summarizeElementCollisionTruth(
        ElementCollisionProfile(occlusionMask: _mask()),
      );

      expect(summary.mode, ElementCollisionTruthMode.empty);
      expect(summary.title, contains('Aucune collision active'));
      expect(summary.hasOcclusionMask, isTrue);
      expect(summary.notes.join(' '), contains('occlusion'));
      expect(summary.notes.join(' '), contains('ne bloque pas'));
    });

    test('returns empty when profile is null', () {
      final summary = summarizeElementCollisionTruth(null);

      expect(summary.mode, ElementCollisionTruthMode.empty);
      expect(summary.title, 'Aucune collision active');
      expect(summary.hasCollisionMask, isFalse);
      expect(summary.hasLegacyCells, isFalse);
      expect(summary.hasVisualMask, isFalse);
      expect(summary.hasOcclusionMask, isFalse);
    });
  });
}

ElementCollisionPixelMask _mask() {
  return ElementCollisionPixelMask(
    widthPx: 1,
    heightPx: 1,
    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
      widthPx: 1,
      heightPx: 1,
      solidPixels: const [true],
    ),
  );
}
```

### Diff complet des fichiers modifiés

```diff
diff --git a/packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart b/packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart
index 9b7d84ec..79e3bd29 100644
--- a/packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart
+++ b/packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart
@@ -8,6 +8,7 @@ import 'package:macos_ui/macos_ui.dart';
 import 'package:map_core/map_core.dart';
 
 import '../../application/services/element_collision_authoring_service.dart';
+import '../../application/models/element_collision_truth_summary.dart';
 import '../../ui/shared/cupertino_editor_widgets.dart';
 
 const ElementCollisionAuthoringService _authoringService =
@@ -86,6 +87,7 @@ class _ElementCollisionEditorSheetState
   @override
   Widget build(BuildContext context) {
     final snapshot = _describe();
+    final truthSummary = summarizeElementCollisionTruth(_draftProfile);
     final pendingPolygonPreviewCells = _buildPendingPolygonPreviewCells();
     final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
     final label = CupertinoColors.label.resolveFrom(context);
@@ -186,6 +188,8 @@ class _ElementCollisionEditorSheetState
                   },
                 ),
                 const SizedBox(height: 14),
+                _CollisionTruthBanner(summary: truthSummary),
+                const SizedBox(height: 14),
                 Expanded(
                   child: Row(
                     crossAxisAlignment: CrossAxisAlignment.stretch,
@@ -324,6 +328,7 @@ class _ElementCollisionEditorSheetState
                         child: _EditorSidebar(
                           source: widget.source,
                           snapshot: snapshot,
+                          truthSummary: truthSummary,
                           showGrid: _showGrid,
                           showBase: _showBase,
                           showFinal: _showFinal,
@@ -705,6 +710,7 @@ class _EditorSidebar extends StatelessWidget {
   const _EditorSidebar({
     required this.source,
     required this.snapshot,
+    required this.truthSummary,
     required this.showGrid,
     required this.showBase,
     required this.showFinal,
@@ -719,6 +725,7 @@ class _EditorSidebar extends StatelessWidget {
 
   final TilesetSourceRect source;
   final ElementCollisionAuthoringSnapshot snapshot;
+  final ElementCollisionTruthSummary truthSummary;
   final bool showGrid;
   final bool showBase;
   final bool showFinal;
@@ -767,7 +774,9 @@ class _EditorSidebar extends StatelessWidget {
               ),
               const SizedBox(height: 10),
               Text(
-                'Le runtime lira uniquement ${snapshot.finalCells.length} cellule${snapshot.finalCells.length > 1 ? 's' : ''} dans `collisionProfile.cells`.',
+                truthSummary.mode == ElementCollisionTruthMode.fineMask
+                    ? 'Le gameplay utilise le masque fin. Les ${snapshot.finalCells.length} cellule${snapshot.finalCells.length > 1 ? 's' : ''} affichées ici servent de projection de compatibilité.'
+                    : 'Le gameplay utilise ${snapshot.finalCells.length} cellule${snapshot.finalCells.length > 1 ? 's' : ''} de grille quand aucun masque fin n’est défini.',
                 style: TextStyle(
                   color: secondary,
                   fontSize: 11,
@@ -795,7 +804,7 @@ class _EditorSidebar extends StatelessWidget {
                 const SizedBox(height: 8),
                 Text(
                   'Preview backend polygone: $pendingPolygonPreviewCount cellule${pendingPolygonPreviewCount > 1 ? 's' : ''}',
-                  style: TextStyle(
+                  style: const TextStyle(
                     color: Colors.yellowAccent,
                     fontSize: 11,
                     fontWeight: FontWeight.w600,
@@ -844,7 +853,7 @@ class _EditorSidebar extends StatelessWidget {
         _SidebarSection(
           title: 'Aide',
           child: Text(
-            'Polygone forme: définit la forme principale d’un bâtiment. Pinceau + / -: applique des retouches locales. Le padding auto reste un outil secondaire pour les cas simples. Le runtime continue à lire uniquement `collisionProfile.cells`.',
+            'Polygone forme: définit une base coarse de bâtiment. Pinceau + / -: applique des retouches locales. Le padding auto reste un outil secondaire pour les cas simples. Le gameplay suit la source active affichée en haut.',
             style: TextStyle(
               color: secondary,
               fontSize: 11,
@@ -856,6 +865,70 @@ class _EditorSidebar extends StatelessWidget {
   }
 }
 
+class _CollisionTruthBanner extends StatelessWidget {
+  const _CollisionTruthBanner({required this.summary});
+
+  final ElementCollisionTruthSummary summary;
+
+  @override
+  Widget build(BuildContext context) {
+    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
+    final label = CupertinoColors.label.resolveFrom(context);
+    final accent = switch (summary.mode) {
+      ElementCollisionTruthMode.fineMask => Colors.redAccent,
+      ElementCollisionTruthMode.legacyCells => Colors.orangeAccent,
+      ElementCollisionTruthMode.empty => Colors.greenAccent,
+    };
+    return Container(
+      padding: const EdgeInsets.all(12),
+      decoration: BoxDecoration(
+        color: accent.withValues(alpha: 0.10),
+        borderRadius: BorderRadius.circular(12),
+        border: Border.all(color: accent.withValues(alpha: 0.38)),
+      ),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          Text(
+            'Source utilisée par le gameplay',
+            style: TextStyle(
+              color: secondary,
+              fontSize: 11,
+              fontWeight: FontWeight.w600,
+            ),
+          ),
+          const SizedBox(height: 4),
+          Text(
+            summary.title,
+            style: TextStyle(
+              color: label,
+              fontSize: 13,
+              fontWeight: FontWeight.w700,
+            ),
+          ),
+          const SizedBox(height: 2),
+          Text(
+            summary.description,
+            style: TextStyle(color: secondary, fontSize: 11),
+          ),
+          const SizedBox(height: 2),
+          Text(
+            summary.detail,
+            style: TextStyle(color: secondary, fontSize: 11),
+          ),
+          for (final note in summary.notes) ...[
+            const SizedBox(height: 2),
+            Text(
+              note,
+              style: TextStyle(color: secondary, fontSize: 11),
+            ),
+          ],
+        ],
+      ),
+    );
+  }
+}
+
 class ElementCollisionPaddingEditor extends StatelessWidget {
   const ElementCollisionPaddingEditor({
     super.key,
diff --git a/packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/collision/element_collision_editor.dart b/packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/collision/element_collision_editor.dart
index d3044078..765de080 100644
--- a/packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/collision/element_collision_editor.dart
+++ b/packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/collision/element_collision_editor.dart
@@ -32,6 +32,7 @@ class _ElementCollisionProfileSummaryCard extends StatelessWidget {
       profile: profile,
       fallbackPadding: draftPadding,
     );
+    final truthSummary = summarizeElementCollisionTruth(profile);
     final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
     final label = CupertinoColors.label.resolveFrom(context);
     return Container(
@@ -71,14 +72,13 @@ class _ElementCollisionProfileSummaryCard extends StatelessWidget {
             ],
           ),
           const SizedBox(height: 4),
+          _CollisionTruthInline(summary: truthSummary),
+          const SizedBox(height: 6),
           Text(
             snapshot.usesManualPrimaryShape
-                ? 'Forme principale auteur active. Le polygone définit la base métier, les retouches la corrigent, et le runtime lit uniquement la forme finale en cellules.'
-                : 'Base padding automatique active. Le polygone peut remplacer cette base pour définir une vraie forme principale de bâtiment.',
-            style: TextStyle(
-              color: secondary,
-              fontSize: 10,
-            ),
+                ? 'Forme principale auteur active. Le polygone définit la base coarse ; les retouches la corrigent.'
+                : 'Base padding automatique active. Le polygone peut remplacer cette base coarse pour définir une silhouette de bâtiment.',
+            style: TextStyle(color: secondary, fontSize: 10),
           ),
           const SizedBox(height: 8),
           Wrap(
@@ -170,6 +170,7 @@ class _ElementCollisionProfileEditorState
       profile: widget.profile,
       fallbackPadding: widget.draftPadding,
     );
+    final truthSummary = summarizeElementCollisionTruth(widget.profile);
     final padding = snapshot.padding;
     return Container(
       padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
@@ -217,12 +218,14 @@ class _ElementCollisionProfileEditorState
           ),
           const SizedBox(height: 2),
           Text(
-            'Base = padding. Final = base + ajouts - suppressions.',
+            'Édition grille / forme coarse. Si un masque fin existe, le gameplay l’utilise d’abord.',
             style: TextStyle(
               color: secondary,
               fontSize: 10,
             ),
           ),
+          const SizedBox(height: 4),
+          _CollisionTruthInline(summary: truthSummary),
           const SizedBox(height: 6),
           Wrap(
             spacing: 8,
@@ -473,6 +476,55 @@ class _CollisionLegendChip extends StatelessWidget {
   }
 }
 
+class _CollisionTruthInline extends StatelessWidget {
+  const _CollisionTruthInline({required this.summary});
+
+  final ElementCollisionTruthSummary summary;
+
+  @override
+  Widget build(BuildContext context) {
+    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
+    final accent = switch (summary.mode) {
+      ElementCollisionTruthMode.fineMask => Colors.redAccent,
+      ElementCollisionTruthMode.legacyCells => Colors.orangeAccent,
+      ElementCollisionTruthMode.empty => Colors.greenAccent,
+    };
+    return Container(
+      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
+      decoration: BoxDecoration(
+        color: accent.withValues(alpha: 0.10),
+        borderRadius: BorderRadius.circular(7),
+        border: Border.all(color: accent.withValues(alpha: 0.36)),
+      ),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          Text(
+            summary.title,
+            style: TextStyle(
+              color: CupertinoColors.label.resolveFrom(context),
+              fontSize: 10,
+              fontWeight: FontWeight.w700,
+            ),
+          ),
+          const SizedBox(height: 2),
+          Text(
+            '${summary.description} ${summary.detail}',
+            style: TextStyle(color: secondary, fontSize: 10),
+          ),
+          for (final note in summary.notes) ...[
+            const SizedBox(height: 2),
+            Text(
+              note,
+              style: TextStyle(color: secondary, fontSize: 10),
+            ),
+          ],
+        ],
+      ),
+    );
+  }
+}
+
 class _CollisionModeButton extends StatelessWidget {
   const _CollisionModeButton({
     required this.label,
diff --git a/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart b/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart
index d69d5ec5..2a7c79f2 100644
--- a/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart
+++ b/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart
@@ -22,6 +22,7 @@ import 'package:map_editor/src/ui/panels/tileset_palette/widgets/shadow/element_
 import 'package:map_editor/src/ui/shared/cupertino_editor_widgets.dart';
 import 'package:map_editor/src/ui/shared/editor_paint_palette.dart';
 
+import '../../application/models/element_collision_truth_summary.dart';
 import '../../application/services/element_collision_authoring_service.dart';
 import '../../features/editor/state/editor_notifier.dart';
 import '../../features/editor/state/editor_selectors.dart';
@@ -785,7 +786,8 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
                                       tileId: selectedTileId,
                                       columns: columns,
                                       category: picked,
-                                      recommendedLayerId: snapshot.activeLayerId,
+                                      recommendedLayerId:
+                                          snapshot.activeLayerId,
                                     );
                                   }
                                 },
@@ -1274,7 +1276,8 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
                       tileHeight: tileHeight,
                       selectionAccent: tilesAccent,
                       selected: snapshot.activeBrush.maybeMap(
-                        projectElement: (brush) => brush.elementId == element.id,
+                        projectElement: (brush) =>
+                            brush.elementId == element.id,
                         orElse: () => false,
                       ),
                       categoryPath: categoryPath,
@@ -2953,7 +2956,6 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
   }
 }
 
-
 class _PlacedElementBehaviorsSection extends StatefulWidget {
   const _PlacedElementBehaviorsSection({
     required this.value,
@@ -4301,7 +4303,6 @@ class _PlacedElementBehaviorsSectionState
   }
 }
 
-
 String _resolveElementPrimaryTilesetId(ProjectElementEntry entry) {
   final frameTilesetId = entry.frames.primaryFrame.tilesetId.trim();
   if (frameTilesetId.isNotEmpty) {
diff --git a/packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart b/packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart
index 726b84f7..eec34782 100644
--- a/packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart
+++ b/packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart
@@ -8,6 +8,7 @@ import 'package:flutter/cupertino.dart';
 import 'package:flutter/material.dart' show Colors;
 import 'package:map_core/map_core.dart';
 
+import '../../application/models/element_collision_truth_summary.dart';
 import '../shared/cupertino_editor_widgets.dart';
 
 /// Mode de la surface d’édition : **aperçu** (lecture seule) ou peinture sur
@@ -119,7 +120,8 @@ class _ElementCollisionTripleMaskEditorState
     setState(() {
       _loadingVisual = true;
     });
-    final bd = await widget.image.toByteData(format: ui.ImageByteFormat.rawRgba);
+    final bd =
+        await widget.image.toByteData(format: ui.ImageByteFormat.rawRgba);
     if (!mounted || bd == null) {
       setState(() {
         _loadingVisual = false;
@@ -246,7 +248,8 @@ class _ElementCollisionTripleMaskEditorState
     );
   }
 
-  void _applyStroke(Offset local, Size boxSize, double boxHeight, {required bool erase}) {
+  void _applyStroke(Offset local, Size boxSize, double boxHeight,
+      {required bool erase}) {
     if (_mode == MaskSurfaceMode.preview) {
       return;
     }
@@ -264,7 +267,9 @@ class _ElementCollisionTripleMaskEditorState
     final px = (lx / targetRect.width * _wPx).floor().clamp(0, _wPx - 1);
     final py = (ly / targetRect.height * _hPx).floor().clamp(0, _hPx - 1);
     final idx = py * _wPx + px;
-    final next = _mode == MaskSurfaceMode.collisionPaint ? _collisionBits : _occlusionBits;
+    final next = _mode == MaskSurfaceMode.collisionPaint
+        ? _collisionBits
+        : _occlusionBits;
     next[idx] = !erase;
     setState(() {});
     _emitProfile();
@@ -275,6 +280,7 @@ class _ElementCollisionTripleMaskEditorState
     final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
     final label = CupertinoColors.label.resolveFrom(context);
     final padding = widget.profile?.padding ?? widget.draftPadding;
+    final truthSummary = summarizeElementCollisionTruth(widget.profile);
 
     return Container(
       padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
@@ -301,9 +307,14 @@ class _ElementCollisionTripleMaskEditorState
           ),
           const SizedBox(height: 6),
           Text(
-            'La collision ne doit pas recopier bêtement l’ombre : éditez la zone '
-            'qui bloque vraiment. L’occlusion définit ce qui peut vous couvrir '
-            'quand vous passez derrière (rendu), sans bloquer le déplacement.',
+            '${truthSummary.title}. ${truthSummary.description} ${truthSummary.detail}',
+            style: TextStyle(color: secondary, fontSize: 10),
+          ),
+          const SizedBox(height: 4),
+          Text(
+            'Masque collision : bloque le déplacement du joueur. '
+            'Masque occlusion : rendu devant/derrière, ne bloque pas. '
+            'Masque visuel : aide d’analyse / aperçu, ne bloque pas.',
             style: TextStyle(color: secondary, fontSize: 10),
           ),
           const SizedBox(height: 8),
@@ -587,7 +598,8 @@ class _TripleMaskPixelPainter extends CustomPainter {
       math.max(activeLeft, activeRight),
       math.max(activeTop, activeBottom),
     );
-    _paintPaddingBands(canvas, targetRect, leftPad, rightPad, topPad, bottomPad);
+    _paintPaddingBands(
+        canvas, targetRect, leftPad, rightPad, topPad, bottomPad);
 
     if (activeRect.width > 0 && activeRect.height > 0) {
       canvas.drawRect(
@@ -680,19 +692,21 @@ class _TripleMaskPixelPainter extends CustomPainter {
         ..strokeWidth = 0.5;
       for (var x = 0; x <= wPx; x += 4) {
         final dx = targetRect.left + x * scaleX;
-        canvas.drawLine(Offset(dx, targetRect.top), Offset(dx, targetRect.bottom), grid);
+        canvas.drawLine(
+            Offset(dx, targetRect.top), Offset(dx, targetRect.bottom), grid);
       }
       for (var y = 0; y <= hPx; y += 4) {
         final dy = targetRect.top + y * scaleY;
-        canvas.drawLine(Offset(targetRect.left, dy), Offset(targetRect.right, dy), grid);
+        canvas.drawLine(
+            Offset(targetRect.left, dy), Offset(targetRect.right, dy), grid);
       }
     }
   }
 
   void _paintCheckerboard(Canvas canvas, Rect r) {
     const sq = 10.0;
-    final light = const Color(0xFFECEFF1);
-    final dark = const Color(0xFFD0D5D8);
+    const light = Color(0xFFECEFF1);
+    const dark = Color(0xFFD0D5D8);
     var row = 0;
     for (var y = r.top; y < r.bottom; y += sq) {
       var col = 0;
```


## 21. Appendice — contenu complet des fichiers modifiés

### `packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart`

```dart
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../application/services/element_collision_authoring_service.dart';
import '../../application/models/element_collision_truth_summary.dart';
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

### `packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/collision/element_collision_editor.dart`

```dart
part of 'package:map_editor/src/ui/panels/tileset_palette_panel.dart';

// The collision editor owns a dense cluster of local widgets, modes, and
// affordances. Keeping them together in a dedicated part file makes the main
// palette panel easier to scan while preserving the existing private API.

class _ElementCollisionProfileSummaryCard extends StatelessWidget {
  const _ElementCollisionProfileSummaryCard({
    required this.source,
    required this.tileWidth,
    required this.tileHeight,
    required this.profile,
    required this.draftPadding,
    required this.onOpenEditor,
    required this.onClearProfile,
  });

  final TilesetSourceRect source;
  final int tileWidth;
  final int tileHeight;
  final ElementCollisionProfile? profile;
  final WarpTriggerPadding draftPadding;
  final VoidCallback onOpenEditor;
  final VoidCallback onClearProfile;

  @override
  Widget build(BuildContext context) {
    final snapshot = _elementCollisionAuthoringService.describe(
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      profile: profile,
      fallbackPadding: draftPadding,
    );
    final truthSummary = summarizeElementCollisionTruth(profile);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: Colors.white.withValues(alpha: 0.015),
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Collision de l’élément',
                  style: TextStyle(
                    color: label,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${snapshot.finalCells.length} cellule${snapshot.finalCells.length > 1 ? 's' : ''}',
                style: TextStyle(
                  color: secondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _CollisionTruthInline(summary: truthSummary),
          const SizedBox(height: 6),
          Text(
            snapshot.usesManualPrimaryShape
                ? 'Forme principale auteur active. Le polygone définit la base coarse ; les retouches la corrigent.'
                : 'Base padding automatique active. Le polygone peut remplacer cette base coarse pour définir une silhouette de bâtiment.',
            style: TextStyle(color: secondary, fontSize: 10),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CollisionLegendChip(
                label: snapshot.usesManualPrimaryShape
                    ? 'Forme ${snapshot.baseCells.length}'
                    : 'Base ${snapshot.baseCells.length}',
                color: Colors.cyanAccent,
              ),
              _CollisionLegendChip(
                label: '+ ${snapshot.manualAddedCells.length}',
                color: Colors.greenAccent,
              ),
              _CollisionLegendChip(
                label: '- ${snapshot.manualRemovedCells.length}',
                color: Colors.redAccent,
              ),
              _CollisionLegendChip(
                label: 'Final ${snapshot.finalCells.length}',
                color: EditorChrome.inspectorJoyCoral,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: PushButton(
                  controlSize: ControlSize.regular,
                  secondary: true,
                  onPressed: onOpenEditor,
                  child: const Text('Ouvrir l’éditeur de collision'),
                ),
              ),
              const SizedBox(width: 8),
              PushButton(
                controlSize: ControlSize.regular,
                secondary: true,
                onPressed: onClearProfile,
                child: const Text('Effacer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ElementCollisionProfileEditor extends StatefulWidget {
  const _ElementCollisionProfileEditor({
    required this.image,
    required this.source,
    required this.tileWidth,
    required this.tileHeight,
    required this.profile,
    required this.draftPadding,
    required this.onProfileChanged,
  });

  final ui.Image image;
  final TilesetSourceRect source;
  final int tileWidth;
  final int tileHeight;
  final ElementCollisionProfile? profile;
  final WarpTriggerPadding draftPadding;
  final ValueChanged<ElementCollisionProfile?> onProfileChanged;

  @override
  State<_ElementCollisionProfileEditor> createState() =>
      _ElementCollisionProfileEditorState();
}

class _ElementCollisionProfileEditorState
    extends State<_ElementCollisionProfileEditor> {
  _ElementCollisionPaintMode _paintMode = _ElementCollisionPaintMode.preview;

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);
    final snapshot = _elementCollisionAuthoringService.describe(
      source: widget.source,
      tileWidth: widget.tileWidth,
      tileHeight: widget.tileHeight,
      profile: widget.profile,
      fallbackPadding: widget.draftPadding,
    );
    final truthSummary = summarizeElementCollisionTruth(widget.profile);
    final padding = snapshot.padding;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: Colors.white.withValues(alpha: 0.015),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Collision par cases',
                  style: TextStyle(
                    color: label,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${snapshot.finalCells.length} cellule${snapshot.finalCells.length > 1 ? 's' : ''}',
                style: TextStyle(
                  color: secondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Padding px: T${padding.top} R${padding.right} B${padding.bottom} L${padding.left}',
            style: TextStyle(
              color: secondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Édition grille / forme coarse. Si un masque fin existe, le gameplay l’utilise d’abord.',
            style: TextStyle(
              color: secondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          _CollisionTruthInline(summary: truthSummary),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CollisionLegendChip(
                label: 'Base ${snapshot.baseCells.length}',
                color: Colors.cyanAccent,
              ),
              _CollisionLegendChip(
                label: '+ Ajouts ${snapshot.manualAddedCells.length}',
                color: Colors.greenAccent,
              ),
              _CollisionLegendChip(
                label: '- Retraits ${snapshot.manualRemovedCells.length}',
                color: Colors.redAccent,
              ),
              _CollisionLegendChip(
                label: 'Final ${snapshot.finalCells.length}',
                color: EditorChrome.inspectorJoyCoral,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _CollisionModeButton(
                  label: 'Apercu',
                  selected: _paintMode == _ElementCollisionPaintMode.preview,
                  onPressed: () => setState(
                    () => _paintMode = _ElementCollisionPaintMode.preview,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _CollisionModeButton(
                  label: 'Ajouter',
                  selected: _paintMode == _ElementCollisionPaintMode.add,
                  onPressed: () => setState(
                    () => _paintMode = _ElementCollisionPaintMode.add,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _CollisionModeButton(
                  label: 'Retirer',
                  selected: _paintMode == _ElementCollisionPaintMode.remove,
                  onPressed: () => setState(
                    () => _paintMode = _ElementCollisionPaintMode.remove,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CollisionActionButton(
                label: 'Reinitialiser retouches',
                onPressed: () {
                  widget.onProfileChanged(
                    _elementCollisionAuthoringService.resetOverrides(
                      source: widget.source,
                      tileWidth: widget.tileWidth,
                      tileHeight: widget.tileHeight,
                      current: widget.profile,
                      fallbackPadding: widget.draftPadding,
                    ),
                  );
                },
              ),
              _CollisionActionButton(
                label: 'Restaurer base seule',
                onPressed: () {
                  widget.onProfileChanged(
                    _elementCollisionAuthoringService.resetOverrides(
                      source: widget.source,
                      tileWidth: widget.tileWidth,
                      tileHeight: widget.tileHeight,
                      current: widget.profile,
                      fallbackPadding: widget.draftPadding,
                    ),
                  );
                },
              ),
              _CollisionActionButton(
                label: 'Vider toute la collision',
                onPressed: () {
                  widget.onProfileChanged(
                    _elementCollisionAuthoringService.clearAllCollision(
                      source: widget.source,
                      tileWidth: widget.tileWidth,
                      tileHeight: widget.tileHeight,
                      current: widget.profile,
                      fallbackPadding: widget.draftPadding,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final boxHeight = math
                  .min(210, constraints.maxWidth * 0.72)
                  .toDouble()
                  .clamp(120.0, 210.0);
              return SizedBox(
                height: boxHeight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) {
                    if (_paintMode == _ElementCollisionPaintMode.preview) {
                      return;
                    }
                    final local = details.localPosition;
                    final size = Size(constraints.maxWidth, boxHeight);
                    final targetRect = _fitCollisionPreviewRect(
                      size: size,
                      source: widget.source,
                      tileWidth: widget.tileWidth,
                      tileHeight: widget.tileHeight,
                    );
                    if (!targetRect.contains(local)) {
                      return;
                    }
                    final localX = local.dx - targetRect.left;
                    final localY = local.dy - targetRect.top;
                    final cellWidth = targetRect.width / widget.source.width;
                    final cellHeight = targetRect.height / widget.source.height;
                    final cellX = (localX / cellWidth)
                        .floor()
                        .clamp(0, widget.source.width - 1);
                    final cellY = (localY / cellHeight)
                        .floor()
                        .clamp(0, widget.source.height - 1);
                    final tappedCell = GridPos(x: cellX, y: cellY);
                    final next = switch (_paintMode) {
                      _ElementCollisionPaintMode.add =>
                        _elementCollisionAuthoringService.applyAddModeTap(
                          source: widget.source,
                          tileWidth: widget.tileWidth,
                          tileHeight: widget.tileHeight,
                          cell: tappedCell,
                          current: widget.profile,
                          fallbackPadding: widget.draftPadding,
                        ),
                      _ElementCollisionPaintMode.remove =>
                        _elementCollisionAuthoringService.applyRemoveModeTap(
                          source: widget.source,
                          tileWidth: widget.tileWidth,
                          tileHeight: widget.tileHeight,
                          cell: tappedCell,
                          current: widget.profile,
                          fallbackPadding: widget.draftPadding,
                        ),
                      _ElementCollisionPaintMode.preview =>
                        _elementCollisionAuthoringService
                            .recalculateFromPadding(
                          source: widget.source,
                          tileWidth: widget.tileWidth,
                          tileHeight: widget.tileHeight,
                          padding: padding,
                          current: widget.profile,
                        ),
                    };
                    widget.onProfileChanged(next);
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: CupertinoColors.separator.resolveFrom(context),
                      ),
                    ),
                    child: CustomPaint(
                      painter: _ElementCollisionProfilePainter(
                        image: widget.image,
                        source: widget.source,
                        tileWidth: widget.tileWidth,
                        tileHeight: widget.tileHeight,
                        padding: padding,
                        baseCells: snapshot.baseCells,
                        manualAddedCells: snapshot.manualAddedCells,
                        manualRemovedCells: snapshot.manualRemovedCells,
                        finalCells: snapshot.finalCells,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            switch (_paintMode) {
              _ElementCollisionPaintMode.preview =>
                'Apercu uniquement. Passe en mode Ajouter ou Retirer pour peindre les cellules.',
              _ElementCollisionPaintMode.add =>
                'Mode ajout: clique une case pour l’ajouter explicitement a la collision.',
              _ElementCollisionPaintMode.remove =>
                'Mode retrait: clique une case pour la retirer explicitement de la collision.',
            },
            style: TextStyle(
              color: secondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _CollisionLegendChip extends StatelessWidget {
  const _CollisionLegendChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: CupertinoColors.label.resolveFrom(context),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CollisionTruthInline extends StatelessWidget {
  const _CollisionTruthInline({required this.summary});

  final ElementCollisionTruthSummary summary;

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final accent = switch (summary.mode) {
      ElementCollisionTruthMode.fineMask => Colors.redAccent,
      ElementCollisionTruthMode.legacyCells => Colors.orangeAccent,
      ElementCollisionTruthMode.empty => Colors.greenAccent,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: accent.withValues(alpha: 0.36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            summary.title,
            style: TextStyle(
              color: CupertinoColors.label.resolveFrom(context),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${summary.description} ${summary.detail}',
            style: TextStyle(color: secondary, fontSize: 10),
          ),
          for (final note in summary.notes) ...[
            const SizedBox(height: 2),
            Text(
              note,
              style: TextStyle(color: secondary, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}

class _CollisionModeButton extends StatelessWidget {
  const _CollisionModeButton({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      minimumSize: Size.zero,
      onPressed: onPressed,
      color: selected ? accent.withValues(alpha: 0.18) : Colors.black26,
      borderRadius: BorderRadius.circular(8),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? accent : labelColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CollisionActionButton extends StatelessWidget {
  const _CollisionActionButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

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

// ignore: unused_element
class _ElementCollisionPaddingEditor extends StatelessWidget {
  const _ElementCollisionPaddingEditor({
    required this.padding,
    required this.maxHorizontal,
    required this.maxVertical,
    required this.onChanged,
  });

  final WarpTriggerPadding padding;
  final int maxHorizontal;
  final int maxVertical;
  final ValueChanged<WarpTriggerPadding> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: Colors.white.withValues(alpha: 0.01),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Padding collision (px)',
            style: TextStyle(
              color: label,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Ajuste l’auto-génération puis affine manuellement si besoin.',
            style: TextStyle(
              color: secondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CollisionPaddingStepper(
                label: 'Top',
                value: padding.top,
                maxValue: maxVertical,
                onChanged: (v) => onChanged(padding.copyWith(top: v)),
              ),
              _CollisionPaddingStepper(
                label: 'Right',
                value: padding.right,
                maxValue: maxHorizontal,
                onChanged: (v) => onChanged(padding.copyWith(right: v)),
              ),
              _CollisionPaddingStepper(
                label: 'Bottom',
                value: padding.bottom,
                maxValue: maxVertical,
                onChanged: (v) => onChanged(padding.copyWith(bottom: v)),
              ),
              _CollisionPaddingStepper(
                label: 'Left',
                value: padding.left,
                maxValue: maxHorizontal,
                onChanged: (v) => onChanged(padding.copyWith(left: v)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollisionPaddingStepper extends StatelessWidget {
  const _CollisionPaddingStepper({
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
      width: 92,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
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
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              GestureDetector(
                onTap: canDecrease ? () => onChanged(value - 1) : null,
                child: Icon(
                  CupertinoIcons.minus_circle_fill,
                  size: 16,
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
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: canIncrease ? () => onChanged(value + 1) : null,
                child: Icon(
                  CupertinoIcons.plus_circle_fill,
                  size: 16,
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

```

### `packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart`

```dart
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart'
    show
        BorderSide,
        BoxShadow,
        Colors,
        Material,
        PopupMenuButton,
        PopupMenuItem,
        RoundedRectangleBorder;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart';
import 'package:map_editor/src/ui/shared/cupertino_editor_widgets.dart';
import 'package:map_editor/src/ui/shared/editor_paint_palette.dart';

import '../../application/models/element_collision_truth_summary.dart';
import '../../application/services/element_collision_authoring_service.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_selectors.dart';
import '../../features/editor/state/models/editor_ui_modes.dart';
import '../../features/editor/tools/editor_tool.dart';
import 'element_collision_editor_sheet.dart';

part 'tileset_palette/dialogs/element_frame_picker_dialog.dart';
part 'tileset_palette/widgets/animation/placed_element_animation_widgets.dart';
part 'tileset_palette/widgets/collision/element_collision_editor.dart';
part 'tileset_palette/widgets/collision/element_collision_profile_painter.dart';
part 'tileset_palette/widgets/library/tileset_palette_library_widgets.dart';
part 'tileset_palette/widgets/palette/tileset_palette_preview.dart';
part 'tileset_palette/widgets/placed_instances/placed_instances_section.dart';

const ElementCollisionAuthoringService _elementCollisionAuthoringService =
    ElementCollisionAuthoringService();

class _InspectorPulldownAction {
  const _InspectorPulldownAction({
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;
}

class TilesetPalettePanel extends ConsumerStatefulWidget {
  const TilesetPalettePanel({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  ConsumerState<TilesetPalettePanel> createState() =>
      _TilesetPalettePanelState();
}

class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
  bool _creationMode = false;
  GridPos? _selectionStart;
  GridPos? _selectionEnd;
  String? _selectedCategoryId;
  final Set<String> _expandedCategories = <String>{};
  final Set<String> _expandedTilesetGroups = <String>{};
  final ScrollController _selectionHorizontalScrollController =
      ScrollController();
  final ScrollController _selectionVerticalScrollController =
      ScrollController();
  String? _lastPlacedInstancesSignature;

  @override
  void dispose() {
    _selectionHorizontalScrollController.dispose();
    _selectionVerticalScrollController.dispose();
    super.dispose();
  }

  /// Sélecteur type « menu déroulant » (ancré sous le contrôle), même look que les pilules inspecteur.
  Widget _inspectorPickerDropdown({
    required BuildContext context,
    required Color accent,
    required String fieldLabel,
    required String valueLabel,
    required List<String> orderedIds,
    required String selectedId,
    required String Function(String id) idToLabel,
    required ValueChanged<String> onSelected,
    String? tooltip,
  }) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final labelColor = EditorChrome.primaryLabel(context);
    return Material(
      color: Colors.transparent,
      child: PopupMenuButton<String>(
        tooltip: tooltip ?? fieldLabel,
        padding: EdgeInsets.zero,
        splashRadius: 20,
        offset: const Offset(0, 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: accent.withValues(alpha: 0.35)),
        ),
        color: EditorChrome.islandFillElevated(context),
        elevation: 3,
        initialValue: selectedId,
        onSelected: onSelected,
        itemBuilder: (menuCtx) => [
          for (final id in orderedIds)
            PopupMenuItem<String>(
              value: id,
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: id == selectedId
                        ? Icon(
                            CupertinoIcons.checkmark,
                            size: 14,
                            color: accent,
                          )
                        : null,
                  ),
                  Expanded(
                    child: Text(
                      idToLabel(id),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: id == selectedId
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: labelColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: EditorChrome.largeIslandSurfaceColor(
              context,
              tint: accent.withValues(alpha: 0.09),
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.14),
                blurRadius: 0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fieldLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: secondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      valueLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(CupertinoIcons.chevron_down, size: 14, color: accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inspectorAccentPopupMenu({
    required BuildContext context,
    required Color accent,
    required String buttonLabel,
    required List<_InspectorPulldownAction> actions,
  }) {
    final labelColor = EditorChrome.primaryLabel(context);
    return Material(
      color: Colors.transparent,
      child: PopupMenuButton<int>(
        tooltip: buttonLabel,
        padding: EdgeInsets.zero,
        splashRadius: 16,
        offset: const Offset(0, 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: accent.withValues(alpha: 0.35)),
        ),
        color: EditorChrome.islandFillElevated(context),
        elevation: 3,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: EditorChrome.largeIslandSurfaceColor(
              context,
              tint: accent.withValues(alpha: 0.1),
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                buttonLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
              const SizedBox(width: 5),
              Icon(CupertinoIcons.chevron_down, size: 11, color: accent),
            ],
          ),
        ),
        itemBuilder: (ctx) => [
          for (var i = 0; i < actions.length; i++)
            PopupMenuItem<int>(
              value: i,
              enabled: actions[i].enabled,
              child: Text(
                actions[i].label,
                style: TextStyle(
                  color: actions[i].enabled
                      ? labelColor
                      : CupertinoColors.placeholderText.resolveFrom(ctx),
                ),
              ),
            ),
        ],
        onSelected: (i) {
          final a = actions[i];
          if (a.enabled) a.onTap();
        },
      ),
    );
  }

  TilesetSourceRect? get _selectionRect {
    final start = _selectionStart;
    final end = _selectionEnd;
    if (start == null || end == null) return null;
    return _rectFromPoints(start, end);
  }

  TilesetSourceRect _rectFromPoints(GridPos start, GridPos end) {
    final left = math.min(start.x, end.x);
    final top = math.min(start.y, end.y);
    final right = math.max(start.x, end.x);
    final bottom = math.max(start.y, end.y);
    return TilesetSourceRect(
      x: left,
      y: top,
      width: right - left + 1,
      height: bottom - top + 1,
    );
  }

  void _setCreationMode(bool enabled) {
    setState(() {
      _creationMode = enabled;
      _selectionStart = null;
      _selectionEnd = null;
    });
  }

  GridPos _gridFromLocal(
    Offset localPosition,
    double cellSize,
    int columns,
    int rows,
  ) {
    final maxX = math.max(0.0, columns * cellSize - 0.000001);
    final maxY = math.max(0.0, rows * cellSize - 0.000001);
    final dx = localPosition.dx.clamp(0.0, maxX).toDouble();
    final dy = localPosition.dy.clamp(0.0, maxY).toDouble();
    final x = (dx / cellSize).floor().clamp(0, columns - 1);
    final y = (dy / cellSize).floor().clamp(0, rows - 1);
    return GridPos(x: x, y: y);
  }

  @override
  Widget build(BuildContext context) {
    final paletteSnapshot = ref.watch(editorTilesetPaletteSnapshotProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final map = paletteSnapshot.activeMap;
    final project = paletteSnapshot.project;
    final settings = paletteSnapshot.settings;

    if (project == null) {
      return Center(
        child: Text(
          'No project loaded',
          style: TextStyle(
            color: CupertinoColors.placeholderText.resolveFrom(context),
          ),
        ),
      );
    }

    final selectedTileset = paletteSnapshot.selectedTilesetEntry;
    final selectedTilesetPath = notifier.getSelectedTilesetAbsolutePath();
    if (selectedTileset == null || selectedTilesetPath == null) {
      return Center(
        child: Text(
          'No tileset selected',
          style: TextStyle(
            color: CupertinoColors.placeholderText.resolveFrom(context),
          ),
        ),
      );
    }
    final sortedTilesets = List<ProjectTilesetEntry>.from(project.tilesets)
      ..sort((a, b) {
        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) return sortCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    final tileLayers =
        map?.layers.whereType<TileLayer>().toList(growable: false) ?? const [];
    final categories = notifier.getElementCategories();
    if (_selectedCategoryId != null &&
        !categories.any((c) => c.id == _selectedCategoryId)) {
      _selectedCategoryId = null;
    }

    return FutureBuilder<ui.Image?>(
      future: _PaletteImageCache.load(selectedTilesetPath),
      builder: (context, imageSnapshot) {
        final image = imageSnapshot.data;
        if (image == null) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedTileset.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tileset image unavailable',
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          );
        }

        final columns =
            settings.tileWidth > 0 ? image.width ~/ settings.tileWidth : 0;
        final rows =
            settings.tileHeight > 0 ? image.height ~/ settings.tileHeight : 0;
        if (columns <= 0 || rows <= 0) {
          return Center(
            child: Text(
              'Invalid tile size for active tileset',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          );
        }

        final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
        final pickerAccent = widget.embedded
            ? EditorChrome.inspectorJoyLilac
            : CupertinoTheme.of(context).primaryColor;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(12, widget.embedded ? 8 : 12, 12, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.embedded)
                    Text(
                      'ELEMENTS',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.bold,
                        color: secondary,
                      ),
                    ),
                  if (!widget.embedded) const SizedBox(height: 6),
                  _inspectorPickerDropdown(
                    context: context,
                    accent: pickerAccent,
                    fieldLabel: 'Tileset',
                    valueLabel: selectedTileset.name,
                    tooltip: 'Choisir un tileset',
                    orderedIds:
                        sortedTilesets.map((tileset) => tileset.id).toList(),
                    selectedId: selectedTileset.id,
                    idToLabel: (id) =>
                        sortedTilesets.firstWhere((t) => t.id == id).name,
                    onSelected: notifier.selectTilesetEditorContext,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${columns * rows} tuiles',
                    style: TextStyle(color: secondary, fontSize: 11),
                  ),
                  if (map == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'No active map: edition mode only',
                        style: TextStyle(color: secondary, fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: _buildElementsTab(
                snapshot: paletteSnapshot,
                notifier: notifier,
                image: image,
                project: project,
                categories: categories,
                columns: columns,
                tileWidth: settings.tileWidth,
                tileHeight: settings.tileHeight,
                activeTileset: selectedTileset,
                tileLayers: tileLayers,
              ),
            ),
          ],
        );
      },
    );
  }

  // ignore: unused_element
  Widget _buildTilesTab({
    required EditorTilesetPaletteSnapshot snapshot,
    required EditorNotifier notifier,
    required ui.Image image,
    required ProjectManifest project,
    required List<TileLayer> tileLayers,
    required int columns,
    required int rows,
    required ProjectSettings settings,
    required ProjectTilesetEntry activeTileset,
  }) {
    final unitEntryByTileId = <int, TilesetPaletteEntry>{};
    for (final entry in activeTileset.paletteEntries) {
      final ps = entry.frames.primarySource;
      if (ps.width != 1 || ps.height != 1) continue;
      final tileId = ps.y * columns + ps.x + 1;
      if (tileId > 0 && tileId <= columns * rows) {
        unitEntryByTileId[tileId] = entry;
      }
    }

    final filter = snapshot.paletteCategoryFilter;
    final filteredTileIds = <int>[];
    for (var tileId = 1; tileId <= columns * rows; tileId++) {
      if (filter == null) {
        filteredTileIds.add(tileId);
        continue;
      }
      final entry = unitEntryByTileId[tileId];
      if (entry == null) {
        if (filter == PaletteCategory.uncategorized) {
          filteredTileIds.add(tileId);
        }
      } else if (entry.category == filter) {
        filteredTileIds.add(tileId);
      }
    }

    final selectedTileId = snapshot.activeBrush.maybeMap(
      tile: (brush) =>
          brush.tilesetId == activeTileset.id ? brush.tileId : null,
      orElse: () => null,
    );
    final selectedEntry =
        selectedTileId == null ? null : unitEntryByTileId[selectedTileId];
    final selectedCategory =
        selectedEntry?.category ?? PaletteCategory.uncategorized;
    final previewSize = settings.tileWidth * settings.displayScale * 2.0;
    final selectionRect = _selectionRect;

    final tileTabSecondary =
        CupertinoColors.secondaryLabel.resolveFrom(context);
    final tileTabLabel = CupertinoColors.label.resolveFrom(context);
    final filterItems = <int>[
      -1,
      ...List.generate(PaletteCategory.values.length, (i) => i),
    ];
    String filterLabel(int i) =>
        i < 0 ? 'All' : _legacyCategoryLabel(PaletteCategory.values[i]);
    final currentFilterIndex =
        filter == null ? -1 : PaletteCategory.values.indexOf(filter);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            onPressed: () async {
              final picked = await showCupertinoListPicker<int>(
                context: context,
                title: 'Tile Category Filter',
                items: filterItems,
                labelOf: filterLabel,
              );
              if (picked != null) {
                notifier.setPaletteCategoryFilter(
                  picked < 0 ? null : PaletteCategory.values[picked],
                );
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tile Category Filter',
                  style: TextStyle(fontSize: 12, color: tileTabSecondary),
                ),
                Text(
                  filterLabel(currentFilterIndex),
                  style: TextStyle(color: tileTabLabel),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  onPressed: () => _setCreationMode(!_creationMode),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _creationMode
                            ? CupertinoIcons.xmark
                            : CupertinoIcons.square,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _creationMode
                              ? 'Exit Element Creation'
                              : 'Create Element',
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CupertinoButton.filled(
                onPressed: !_creationMode || selectionRect == null
                    ? null
                    : () => _showCreateElementDialog(
                          context,
                          notifier: notifier,
                          project: project,
                          image: image,
                          tilesetId: activeTileset.id,
                          tilesetGroups: activeTileset.elementGroups,
                          source: selectionRect,
                          tileWidth: settings.tileWidth,
                          tileHeight: settings.tileHeight,
                          activeLayerId: snapshot.activeLayerId,
                          tileLayers: tileLayers,
                        ),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _creationMode
              ? _buildSelectionCanvas(
                  image: image,
                  columns: columns,
                  rows: rows,
                  tileWidth: settings.tileWidth,
                  tileHeight: settings.tileHeight,
                  displayScale: settings.displayScale,
                  selectionRect: selectionRect,
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: 8),
                  children: [
                    SizedBox(
                      height: 220,
                      child: _buildSelectionCanvas(
                        image: image,
                        columns: columns,
                        rows: rows,
                        tileWidth: settings.tileWidth,
                        tileHeight: settings.tileHeight,
                        displayScale: settings.displayScale,
                        selectionRect: selectionRect,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final paletteTileSize =
                              settings.tileWidth * settings.displayScale;
                          final crossAxisCount =
                              (constraints.maxWidth / (paletteTileSize + 8))
                                  .floor()
                                  .clamp(1, 20);
                          return GridView.builder(
                            itemCount: filteredTileIds.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                            ),
                            itemBuilder: (context, index) {
                              final tileId = filteredTileIds[index];
                              return _PaletteTileCell(
                                image: image,
                                tileId: tileId,
                                tileWidth: settings.tileWidth,
                                tileHeight: settings.tileHeight,
                                columns: columns,
                                selected: tileId == selectedTileId,
                                onTap: () {
                                  notifier.selectPaletteTile(tileId);
                                  notifier.selectTool(EditorToolType.tilePaint);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                  color: CupertinoColors.separator.resolveFrom(context)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selected Tile',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: tileTabLabel,
                ),
              ),
              if (_creationMode && selectionRect != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Selection: ${selectionRect.width}x${selectionRect.height} at (${selectionRect.x}, ${selectionRect.y})',
                  style: TextStyle(
                    color: tileTabSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: previewSize,
                    height: previewSize,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: CupertinoColors.separator.resolveFrom(context),
                      ),
                    ),
                    child: selectedTileId == null
                        ? Center(
                            child: Text(
                              '-',
                              style: TextStyle(
                                color: CupertinoColors.placeholderText
                                    .resolveFrom(context),
                              ),
                            ),
                          )
                        : _PaletteTilePreview(
                            image: image,
                            tileId: selectedTileId,
                            tileWidth: settings.tileWidth,
                            tileHeight: settings.tileHeight,
                            columns: columns,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedTileId == null
                              ? 'No tile selected'
                              : 'Tile #$selectedTileId',
                          style: TextStyle(fontSize: 12, color: tileTabLabel),
                        ),
                        const SizedBox(height: 8),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                          onPressed: selectedTileId == null
                              ? null
                              : () async {
                                  final picked = await showCupertinoListPicker<
                                      PaletteCategory>(
                                    context: context,
                                    title: 'Tile Category',
                                    items: PaletteCategory.values.toList(),
                                    labelOf: _legacyCategoryLabel,
                                  );
                                  if (picked != null) {
                                    notifier.upsertPaletteEntryForTile(
                                      tileId: selectedTileId,
                                      columns: columns,
                                      category: picked,
                                      recommendedLayerId:
                                          snapshot.activeLayerId,
                                    );
                                  }
                                },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tile Category',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: tileTabSecondary,
                                ),
                              ),
                              Text(
                                _legacyCategoryLabel(selectedCategory),
                                style: TextStyle(color: tileTabLabel),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildElementsTab({
    required EditorTilesetPaletteSnapshot snapshot,
    required EditorNotifier notifier,
    required ui.Image image,
    required ProjectManifest project,
    required List<ProjectElementCategory> categories,
    required int columns,
    required int tileWidth,
    required int tileHeight,
    required ProjectTilesetEntry activeTileset,
    required List<TileLayer> tileLayers,
  }) {
    final categoriesById = <String, ProjectElementCategory>{
      for (final category in categories) category.id: category,
    };
    final categoriesByParent = <String?, List<ProjectElementCategory>>{};
    for (final category in categories) {
      final key = category.parentCategoryId;
      categoriesByParent.putIfAbsent(key, () => []).add(category);
    }
    for (final list in categoriesByParent.values) {
      list.sort((a, b) {
        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) return sortCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    }

    final tilesetGroups = notifier.getSelectedTilesetElementGroups();
    final tilesetGroupById = <String, TilesetElementGroup>{
      for (final group in tilesetGroups) group.id: group,
    };
    final tilesetGroupsByParent = <String?, List<TilesetElementGroup>>{};
    for (final group in tilesetGroups) {
      tilesetGroupsByParent
          .putIfAbsent(group.parentGroupId, () => [])
          .add(group);
    }
    for (final list in tilesetGroupsByParent.values) {
      list.sort((a, b) {
        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) return sortCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    }
    final selectedTilesetGroupId = snapshot.selectedTilesetElementGroupId;
    final validSelectedTilesetGroupId = selectedTilesetGroupId != null &&
            tilesetGroupById.containsKey(selectedTilesetGroupId)
        ? selectedTilesetGroupId
        : null;

    final tilesetElements = notifier.getSelectedTilesetElements(
      tilesetGroupId: validSelectedTilesetGroupId,
      includeDescendants: true,
    );

    final selectedCategoryId = _selectedCategoryId;
    Set<String>? categoryScope;
    if (selectedCategoryId != null) {
      categoryScope =
          _collectCategoryScope(categoriesByParent, selectedCategoryId);
    }

    final filteredElements = tilesetElements.where((element) {
      if (categoryScope != null &&
          !categoryScope.contains(element.categoryId)) {
        return false;
      }
      return true;
    }).toList(growable: false);

    final groupById = <String, ProjectMapGroup>{
      for (final group in project.groups) group.id: group,
    };

    const tilesAccent = EditorChrome.inspectorJoyLilac;
    final secondaryLabel = CupertinoColors.secondaryLabel.resolveFrom(context);
    final rim = EditorChrome.editorIslandRim(context);
    final listSurface = EditorChrome.largeIslandSurfaceColor(
      context,
      tint: tilesAccent.withValues(alpha: 0.07),
    );
    const categoryStripe = EditorChrome.inspectorJoyCyan;

    final tilesetGroupActions = <_InspectorPulldownAction>[
      _InspectorPulldownAction(
        label: 'Nouveau groupe racine',
        onTap: () => _showCreateTilesetGroupDialog(
          context,
          notifier: notifier,
          tilesetId: activeTileset.id,
        ),
      ),
      _InspectorPulldownAction(
        label: 'Nouveau sous-groupe',
        enabled: validSelectedTilesetGroupId != null,
        onTap: () {
          final id = validSelectedTilesetGroupId;
          if (id == null) return;
          _showCreateTilesetSubgroupDialog(
            context,
            notifier: notifier,
            tilesetId: activeTileset.id,
            parentGroupId: id,
          );
        },
      ),
      _InspectorPulldownAction(
        label: 'Renommer la sélection',
        enabled: validSelectedTilesetGroupId != null,
        onTap: () {
          final id = validSelectedTilesetGroupId;
          if (id == null) return;
          _showRenameTilesetGroupDialog(
            context,
            notifier: notifier,
            tilesetId: activeTileset.id,
            groupId: id,
            currentName: tilesetGroupById[id]?.name ?? '',
          );
        },
      ),
    ];

    final categoryActions = <_InspectorPulldownAction>[
      _InspectorPulldownAction(
        label: 'Nouvelle catégorie racine',
        onTap: () => _showCreateCategoryDialog(
          context,
          notifier: notifier,
          parentCategoryId: null,
        ),
      ),
      _InspectorPulldownAction(
        label: 'Nouvelle sous-catégorie',
        enabled: selectedCategoryId != null,
        onTap: () {
          final id = selectedCategoryId;
          if (id == null) return;
          _showCreateCategoryDialog(
            context,
            notifier: notifier,
            parentCategoryId: id,
          );
        },
      ),
      _InspectorPulldownAction(
        label: 'Renommer la catégorie',
        enabled: selectedCategoryId != null,
        onTap: () {
          final id = selectedCategoryId;
          if (id == null) return;
          _showRenameCategoryDialog(
            context,
            notifier: notifier,
            categoryId: id,
            currentName: categoriesById[id]?.name ?? '',
          );
        },
      ),
    ];

    final tilesetGroupRows = <Widget>[
      _CategoryTreeRow(
        depth: 0,
        selected: validSelectedTilesetGroupId == null,
        label: 'Tous les groupes',
        hasChildren: false,
        expanded: false,
        accentOverride: tilesAccent,
        onTap: () => notifier.selectTilesetElementGroupFilter(null),
      ),
      const EditorHorizontalDivider(),
      ..._buildTilesetGroupRows(
        groupsByParent: tilesetGroupsByParent,
        parentGroupId: null,
        selectedGroupId: validSelectedTilesetGroupId,
        rowAccent: tilesAccent,
        onSelect: (groupId) =>
            notifier.selectTilesetElementGroupFilter(groupId),
      ),
    ];

    final categoryRows = <Widget>[
      _CategoryTreeRow(
        depth: 0,
        selected: selectedCategoryId == null,
        label: 'Toutes les catégories',
        hasChildren: false,
        expanded: false,
        accentOverride: categoryStripe,
        onTap: () {
          setState(() {
            _selectedCategoryId = null;
          });
        },
      ),
      const EditorHorizontalDivider(),
      ..._buildCategoryRows(
        categoriesByParent: categoriesByParent,
        parentCategoryId: null,
        depth: 0,
        rowAccent: categoryStripe,
      ),
    ];

    final panelMode = snapshot.tilesElementsPanelMode;
    final placedInstancesScope = _resolvePlacedElementInstances(
      snapshot: snapshot,
      activeTileset: activeTileset,
      project: project,
      tilesetColumns: columns,
    );
    final selectedPlacedInstance = _findPlacedElementInstanceById(
      instances: placedInstancesScope.instances,
      instanceId: snapshot.selectedPlacedElementInstanceId,
    );

    if (panelMode == TilesElementsPanelMode.placedInstances) {
      _logPlacedInstancesSnapshot(placedInstancesScope);
      if (snapshot.selectedPlacedElementInstanceId != null &&
          selectedPlacedInstance == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          ref.read(editorNotifierProvider.notifier).selectPlacedElementInstance(
                instanceId: null,
              );
        });
      }
    }

    final paletteSections = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.square_stack_3d_up_fill,
                  size: 14,
                  color: tilesAccent,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Groupes internes (tileset)',
                    style: TextStyle(
                      color: secondaryLabel,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _inspectorAccentPopupMenu(
                  context: context,
                  accent: tilesAccent,
                  buttonLabel: 'Actions',
                  actions: tilesetGroupActions,
                ),
              ],
            ),
            Text(
              'Filtre les éléments selon le groupe dans ce tileset.',
              style: TextStyle(
                color: secondaryLabel,
                fontSize: 10,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
      Container(
        height: 72,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: listSurface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: rim),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ColoredBox(
              color: tilesAccent,
              child: SizedBox(width: 3),
            ),
            Expanded(
              child: ListView(
                children: tilesetGroupRows,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 5),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 2, 12, 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.tag_fill,
                  size: 14,
                  color: categoryStripe,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Catégories d'éléments",
                    style: TextStyle(
                      color: secondaryLabel,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _inspectorAccentPopupMenu(
                  context: context,
                  accent: categoryStripe,
                  buttonLabel: 'Actions',
                  actions: categoryActions,
                ),
              ],
            ),
            Text(
              'Filtre la liste par catégorie projet (pas le tileset).',
              style: TextStyle(
                color: secondaryLabel,
                fontSize: 10,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
      Container(
        height: 72,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: listSurface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: rim),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ColoredBox(
              color: categoryStripe,
              child: SizedBox(width: 3),
            ),
            Expanded(
              child: ListView(
                children: categoryRows,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 6),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: EditorChrome.largeIslandSurfaceColor(
            context,
            tint: tilesAccent.withValues(alpha: 0.08),
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tilesAccent.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: tilesAccent.withValues(alpha: 0.1),
              blurRadius: 0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  CupertinoIcons.cube_box_fill,
                  size: 15,
                  color: tilesAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Éléments à placer',
                    style: TextStyle(
                      color: EditorChrome.primaryLabel(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${filteredElements.length}',
                  style: TextStyle(
                    color: secondaryLabel,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (filteredElements.isEmpty)
              Text(
                'Aucun élément pour ces filtres',
                style: TextStyle(
                  color: CupertinoColors.placeholderText.resolveFrom(context),
                  fontSize: 12,
                ),
              )
            else
              ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: filteredElements.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final element = filteredElements[index];
                  final categoryPath = _buildCategoryPathLabel(
                    categoriesById: categoriesById,
                    categoryId: element.categoryId,
                  );
                  final tilesetName = activeTileset.name;
                  final groupLabel = element.groupId == null
                      ? 'Global'
                      : 'Groupe : ${_buildGroupPathLabel(groupById, element.groupId!)}';
                  final tilesetGroupLabel = element.tilesetGroupId == null
                      ? 'Interne : aucun'
                      : 'Interne : ${_buildTilesetGroupPathLabel(tilesetGroupById, element.tilesetGroupId!)}';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _ProjectElementCard(
                      image: image,
                      element: element,
                      tileWidth: tileWidth,
                      tileHeight: tileHeight,
                      selectionAccent: tilesAccent,
                      selected: snapshot.activeBrush.maybeMap(
                        projectElement: (brush) =>
                            brush.elementId == element.id,
                        orElse: () => false,
                      ),
                      categoryPath: categoryPath,
                      tilesetName: tilesetName,
                      groupLabel: groupLabel,
                      tilesetGroupLabel: tilesetGroupLabel,
                      onTap: () {
                        notifier.selectProjectElement(element.id);
                        if (element.recommendedLayerId != null &&
                            (snapshot.activeMap?.layers.any(
                                  (layer) =>
                                      layer is TileLayer &&
                                      layer.id == element.recommendedLayerId,
                                ) ??
                                false)) {
                          notifier.setActiveLayer(
                            element.recommendedLayerId!,
                          );
                        }
                        notifier.selectTool(EditorToolType.tilePaint);
                      },
                      onEdit: () => _showEditElementDialog(
                        context,
                        notifier: notifier,
                        project: project,
                        image: image,
                        element: element,
                        categories: categories,
                        tileWidth: tileWidth,
                        tileHeight: tileHeight,
                        tileLayers: tileLayers,
                        tilesetGroups: tilesetGroups,
                      ),
                      onDelete: () => _showDeleteElementDialog(
                        context,
                        notifier: notifier,
                        element: element,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 2),
          child: _buildTilesElementsModeSelector(
            mode: panelMode,
            onChanged: notifier.setTilesElementsPanelMode,
            placedCount: placedInstancesScope.instances.length,
          ),
        ),
        const SizedBox(height: 4),
        if (panelMode == TilesElementsPanelMode.palette) ...paletteSections,
        if (panelMode == TilesElementsPanelMode.placedInstances)
          _PlacedInstancesSection(
            image: image,
            tileWidth: tileWidth,
            tileHeight: tileHeight,
            scope: placedInstancesScope,
            selectedInstanceId: snapshot.selectedPlacedElementInstanceId,
            selectedInstance: selectedPlacedInstance,
            dialogues: project.dialogues,
            projectRootPath: snapshot.projectRootPath,
            onSelectInstance: (instance) {
              notifier.selectPlacedElementInstance(
                instanceId: instance?.instanceId,
                elementId:
                    instance?.element?.id ?? instance?.instance.elementId,
                layerId: instance?.layerId,
              );
            },
            onCollisionAppliedChanged: (instance, applyCollision) {
              notifier.setPlacedElementInstanceCollisionApplied(
                instanceId: instance.instanceId,
                applyCollision: applyCollision,
              );
            },
            onOpacityChanged: (instance, opacity) {
              notifier.setPlacedElementInstanceOpacity(
                instanceId: instance.instanceId,
                opacity: opacity,
              );
            },
            onAnimationConfigChanged: (instance, animation) {
              notifier.setPlacedElementInstanceAnimationConfig(
                instanceId: instance.instanceId,
                animation: animation,
              );
            },
            onBehaviorsChanged: (instance, behaviors) {
              notifier.setPlacedElementInstanceBehaviors(
                instanceId: instance.instanceId,
                behaviors: behaviors,
              );
            },
            onDeleteInstance: (instance) async {
              await _showDeletePlacedInstanceDialog(
                context,
                notifier: notifier,
                instance: instance,
              );
            },
          ),
      ],
    );
  }

  Widget _buildTilesElementsModeSelector({
    required TilesElementsPanelMode mode,
    required ValueChanged<TilesElementsPanelMode> onChanged,
    required int placedCount,
  }) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyLilac.withValues(alpha: 0.08),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.inspectorJoyLilac.withValues(alpha: 0.38),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mode',
            style: TextStyle(
              color: secondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          CupertinoSlidingSegmentedControl<TilesElementsPanelMode>(
            groupValue: mode,
            children: const {
              TilesElementsPanelMode.palette: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text('Palette'),
              ),
              TilesElementsPanelMode.placedInstances: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text('Instances posées'),
              ),
            },
            onValueChanged: (value) {
              if (value == null) {
                return;
              }
              onChanged(value);
            },
          ),
          if (mode == TilesElementsPanelMode.placedInstances) ...[
            const SizedBox(height: 6),
            Text(
              '$placedCount instance${placedCount > 1 ? 's' : ''} détectée${placedCount > 1 ? 's' : ''} sur le calque actif',
              style: TextStyle(
                color: secondary,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  _PlacedElementInstancesScope _resolvePlacedElementInstances({
    required EditorTilesetPaletteSnapshot snapshot,
    required ProjectManifest project,
    required ProjectTilesetEntry activeTileset,
    required int tilesetColumns,
  }) {
    final map = snapshot.activeMap;
    if (map == null) {
      return const _PlacedElementInstancesScope(
        layerId: null,
        layerName: null,
        instances: [],
        emptyTitle: 'Aucune map active',
        emptyMessage: 'Charge une map pour parcourir les éléments posés.',
      );
    }
    final layerId = snapshot.activeLayerId;
    if (layerId == null || layerId.isEmpty) {
      return const _PlacedElementInstancesScope(
        layerId: null,
        layerName: null,
        instances: [],
        emptyTitle: 'Aucun calque actif',
        emptyMessage: 'Sélectionne un calque pour afficher les instances.',
      );
    }
    MapLayer? layer;
    for (final entry in map.layers) {
      if (entry.id == layerId) {
        layer = entry;
        break;
      }
    }
    if (layer == null) {
      return _PlacedElementInstancesScope(
        layerId: layerId,
        layerName: null,
        instances: const [],
        emptyTitle: 'Calque introuvable',
        emptyMessage: 'Le calque actif "$layerId" est introuvable.',
      );
    }
    if (layer is! TileLayer) {
      return _PlacedElementInstancesScope(
        layerId: layer.id,
        layerName: layer.name,
        instances: const [],
        emptyTitle: 'Calque non compatible',
        emptyMessage:
            'Les instances posées sont disponibles sur les calques de tuiles.',
      );
    }
    final tileLayer = layer;
    final layerTilesetId = (tileLayer.tilesetId ?? map.tilesetId).trim();
    if (layerTilesetId.isEmpty) {
      return _PlacedElementInstancesScope(
        layerId: tileLayer.id,
        layerName: tileLayer.name,
        instances: const [],
        emptyTitle: 'Tileset manquant',
        emptyMessage:
            'Le calque actif n’a pas de tileset associé pour détecter les éléments.',
      );
    }
    final elementById = <String, ProjectElementEntry>{
      for (final entry in project.elements) entry.id: entry,
    };
    final rawLayerInstances = map.placedElements
        .where((instance) => instance.layerId == tileLayer.id)
        .toList(growable: true)
      ..sort((a, b) {
        final yCompare = a.pos.y.compareTo(b.pos.y);
        if (yCompare != 0) return yCompare;
        final xCompare = a.pos.x.compareTo(b.pos.x);
        if (xCompare != 0) return xCompare;
        return a.id.compareTo(b.id);
      });

    if (rawLayerInstances.isEmpty) {
      return _PlacedElementInstancesScope(
        layerId: tileLayer.id,
        layerName: tileLayer.name,
        instances: const [],
        emptyTitle: 'Aucun élément placé sur ce layer',
        emptyMessage: 'Place un élément depuis la palette pour le voir ici.',
      );
    }

    final occurrencesByElementId = <String, int>{};
    final instances = <_PlacedElementInstanceVm>[];
    for (final instance in rawLayerInstances) {
      final element = elementById[instance.elementId];
      final previewAvailable = element != null &&
          _resolveElementPrimaryTilesetId(element) == activeTileset.id &&
          tilesetColumns > 0;
      final key = element?.id ?? instance.elementId;
      final occurrence = (occurrencesByElementId[key] ?? 0) + 1;
      occurrencesByElementId[key] = occurrence;
      instances.add(
        _PlacedElementInstanceVm(
          instance: instance,
          element: element,
          layerName: tileLayer.name,
          occurrence: occurrence,
          previewAvailable: previewAvailable,
        ),
      );
    }

    if (instances.isEmpty) {
      return _PlacedElementInstancesScope(
        layerId: layer.id,
        layerName: layer.name,
        instances: const [],
        emptyTitle: 'Aucun élément placé sur ce layer',
        emptyMessage: 'Place un élément depuis la palette pour le voir ici.',
      );
    }

    return _PlacedElementInstancesScope(
      layerId: layer.id,
      layerName: layer.name,
      instances: instances,
      emptyTitle: '',
      emptyMessage: '',
    );
  }

  _PlacedElementInstanceVm? _findPlacedElementInstanceById({
    required List<_PlacedElementInstanceVm> instances,
    required String? instanceId,
  }) {
    if (instanceId == null || instanceId.isEmpty) {
      return null;
    }
    for (final instance in instances) {
      if (instance.instanceId == instanceId) {
        return instance;
      }
    }
    return null;
  }

  void _logPlacedInstancesSnapshot(_PlacedElementInstancesScope scope) {
    if (!kDebugMode) {
      return;
    }
    final layerId = scope.layerId ?? '';
    final signature =
        '$layerId|${scope.instances.length}|${scope.emptyTitle}|${scope.emptyMessage}';
    if (signature == _lastPlacedInstancesSignature) {
      return;
    }
    _lastPlacedInstancesSignature = signature;
    if (scope.instances.isEmpty) {
      debugPrint('[editor][elements] no placed instances for layer=$layerId');
      return;
    }
    debugPrint(
      '[editor][elements] loaded placed instances count=${scope.instances.length} layer=$layerId',
    );
  }

  List<Widget> _buildCategoryRows({
    required Map<String?, List<ProjectElementCategory>> categoriesByParent,
    required String? parentCategoryId,
    required int depth,
    Color? rowAccent,
  }) {
    final rows = <Widget>[];
    final children = categoriesByParent[parentCategoryId] ?? const [];
    for (final category in children) {
      final grandChildren = categoriesByParent[category.id] ?? const [];
      final hasChildren = grandChildren.isNotEmpty;
      final expanded = _expandedCategories.contains(category.id);

      rows.add(
        _CategoryTreeRow(
          depth: depth,
          selected: _selectedCategoryId == category.id,
          label: category.name,
          hasChildren: hasChildren,
          expanded: expanded,
          accentOverride: rowAccent,
          onTap: () {
            setState(() {
              _selectedCategoryId = category.id;
            });
          },
          onToggleExpanded: hasChildren
              ? () {
                  setState(() {
                    if (expanded) {
                      _expandedCategories.remove(category.id);
                    } else {
                      _expandedCategories.add(category.id);
                    }
                  });
                }
              : null,
        ),
      );
      if (hasChildren && expanded) {
        rows.addAll(
          _buildCategoryRows(
            categoriesByParent: categoriesByParent,
            parentCategoryId: category.id,
            depth: depth + 1,
            rowAccent: rowAccent,
          ),
        );
      }
    }
    return rows;
  }

  List<Widget> _buildTilesetGroupRows({
    required Map<String?, List<TilesetElementGroup>> groupsByParent,
    required String? parentGroupId,
    required String? selectedGroupId,
    required ValueChanged<String> onSelect,
    int depth = 0,
    Color? rowAccent,
  }) {
    final rows = <Widget>[];
    final children = groupsByParent[parentGroupId] ?? const [];
    for (final group in children) {
      final grandChildren = groupsByParent[group.id] ?? const [];
      final hasChildren = grandChildren.isNotEmpty;
      final expanded = _expandedTilesetGroups.contains(group.id);

      rows.add(
        _CategoryTreeRow(
          depth: depth,
          selected: selectedGroupId == group.id,
          label: group.name,
          hasChildren: hasChildren,
          expanded: expanded,
          accentOverride: rowAccent,
          onTap: () => onSelect(group.id),
          onToggleExpanded: hasChildren
              ? () {
                  setState(() {
                    if (expanded) {
                      _expandedTilesetGroups.remove(group.id);
                    } else {
                      _expandedTilesetGroups.add(group.id);
                    }
                  });
                }
              : null,
        ),
      );
      if (hasChildren && expanded) {
        rows.addAll(
          _buildTilesetGroupRows(
            groupsByParent: groupsByParent,
            parentGroupId: group.id,
            selectedGroupId: selectedGroupId,
            onSelect: onSelect,
            depth: depth + 1,
            rowAccent: rowAccent,
          ),
        );
      }
    }
    return rows;
  }

  Set<String> _collectCategoryScope(
    Map<String?, List<ProjectElementCategory>> byParent,
    String rootId,
  ) {
    final scope = <String>{rootId};
    final queue = <String>[rootId];
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      final children = byParent[current] ?? const [];
      for (final child in children) {
        if (scope.add(child.id)) {
          queue.add(child.id);
        }
      }
    }
    return scope;
  }

  String _buildCategoryPathLabel({
    required Map<String, ProjectElementCategory> categoriesById,
    required String categoryId,
  }) {
    final labels = <String>[];
    String? cursor = categoryId;
    final visited = <String>{};
    while (cursor != null && visited.add(cursor)) {
      final category = categoriesById[cursor];
      if (category == null) break;
      labels.add(category.name);
      cursor = category.parentCategoryId;
    }
    return labels.reversed.join(' / ');
  }

  String _buildGroupPathLabel(
    Map<String, ProjectMapGroup> groupById,
    String groupId,
  ) {
    final labels = <String>[];
    String? cursor = groupId;
    final visited = <String>{};
    while (cursor != null && visited.add(cursor)) {
      final group = groupById[cursor];
      if (group == null) break;
      labels.add(group.name);
      cursor = group.parentGroupId;
    }
    return labels.reversed.join(' / ');
  }

  String _buildTilesetGroupPathLabel(
    Map<String, TilesetElementGroup> groupById,
    String groupId,
  ) {
    final labels = <String>[];
    String? cursor = groupId;
    final visited = <String>{};
    while (cursor != null && visited.add(cursor)) {
      final group = groupById[cursor];
      if (group == null) break;
      labels.add(group.name);
      cursor = group.parentGroupId;
    }
    return labels.reversed.join(' / ');
  }

  Widget _buildSelectionCanvas({
    required ui.Image image,
    required int columns,
    required int rows,
    required int tileWidth,
    required int tileHeight,
    required double displayScale,
    required TilesetSourceRect? selectionRect,
  }) {
    final cellSize = math.max(8.0, tileWidth * displayScale);
    final canvasWidth = columns * cellSize;
    final canvasHeight = rows * cellSize;

    return SingleChildScrollView(
      controller: _selectionHorizontalScrollController,
      primary: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        controller: _selectionVerticalScrollController,
        primary: false,
        scrollDirection: Axis.vertical,
        child: SizedBox(
          width: canvasWidth,
          height: canvasHeight,
          child: GestureDetector(
            onPanStart: (details) {
              final pos = _gridFromLocal(
                  details.localPosition, cellSize, columns, rows);
              setState(() {
                _selectionStart = pos;
                _selectionEnd = pos;
              });
            },
            onPanUpdate: (details) {
              if (_selectionStart == null) return;
              final pos = _gridFromLocal(
                  details.localPosition, cellSize, columns, rows);
              setState(() {
                _selectionEnd = pos;
              });
            },
            onTapUp: (details) {
              final pos = _gridFromLocal(
                  details.localPosition, cellSize, columns, rows);
              setState(() {
                _selectionStart = pos;
                _selectionEnd = pos;
              });
            },
            child: CustomPaint(
              painter: _TilesetSelectionPainter(
                image: image,
                columns: columns,
                rows: rows,
                tileWidth: tileWidth,
                tileHeight: tileHeight,
                selection: selectionRect,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateCategoryDialog(
    BuildContext context, {
    required EditorNotifier notifier,
    required String? parentCategoryId,
  }) async {
    final controller = TextEditingController();
    var shouldSave = false;
    await showMacosEditorModalSheet<void>(
      context: context,
      maxWidth: 400,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            parentCategoryId == null ? 'New Category' : 'New Subcategory',
            style: editorMacosSheetTitleStyle(ctx),
          ),
          const SizedBox(height: 12),
          MacosTextField(
            controller: controller,
            autofocus: true,
            placeholder: 'Name',
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PushButton(
                controlSize: ControlSize.large,
                secondary: true,
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 10),
              PushButton(
                controlSize: ControlSize.large,
                onPressed: () {
                  if (controller.text.trim().isEmpty) return;
                  shouldSave = true;
                  Navigator.pop(ctx);
                },
                child: const Text('Create'),
              ),
            ],
          ),
        ],
      ),
    );
    if (!shouldSave) return;
    if (parentCategoryId == null) {
      await notifier.createElementCategory(controller.text.trim());
    } else {
      await notifier.createElementSubcategory(
        parentCategoryId,
        controller.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _expandedCategories.add(parentCategoryId);
      });
    }
  }

  Future<void> _showRenameCategoryDialog(
    BuildContext context, {
    required EditorNotifier notifier,
    required String categoryId,
    required String currentName,
  }) async {
    final controller = TextEditingController(text: currentName);
    var shouldSave = false;
    await showMacosEditorModalSheet<void>(
      context: context,
      maxWidth: 400,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Rename Category',
            style: editorMacosSheetTitleStyle(ctx),
          ),
          const SizedBox(height: 12),
          MacosTextField(
            controller: controller,
            autofocus: true,
            placeholder: 'Name',
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PushButton(
                controlSize: ControlSize.large,
                secondary: true,
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 10),
              PushButton(
                controlSize: ControlSize.large,
                onPressed: () {
                  if (controller.text.trim().isEmpty) return;
                  shouldSave = true;
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
    if (!shouldSave) return;
    await notifier.renameElementCategory(categoryId, controller.text.trim());
  }

  Future<void> _showCreateTilesetGroupDialog(
    BuildContext context, {
    required EditorNotifier notifier,
    required String tilesetId,
  }) async {
    final controller = TextEditingController();
    var shouldSave = false;
    await showMacosEditorModalSheet<void>(
      context: context,
      maxWidth: 400,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'New Tileset Group',
            style: editorMacosSheetTitleStyle(ctx),
          ),
          const SizedBox(height: 12),
          MacosTextField(
            controller: controller,
            autofocus: true,
            placeholder: 'Name',
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PushButton(
                controlSize: ControlSize.large,
                secondary: true,
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 10),
              PushButton(
                controlSize: ControlSize.large,
                onPressed: () {
                  if (controller.text.trim().isEmpty) return;
                  shouldSave = true;
                  Navigator.pop(ctx);
                },
                child: const Text('Create'),
              ),
            ],
          ),
        ],
      ),
    );
    if (!shouldSave) return;
    await notifier.createTilesetElementGroup(
      tilesetId,
      controller.text.trim(),
    );
  }

  Future<void> _showCreateTilesetSubgroupDialog(
    BuildContext context, {
    required EditorNotifier notifier,
    required String tilesetId,
    required String parentGroupId,
  }) async {
    final controller = TextEditingController();
    var shouldSave = false;
    await showMacosEditorModalSheet<void>(
      context: context,
      maxWidth: 400,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'New Tileset Subgroup',
            style: editorMacosSheetTitleStyle(ctx),
          ),
          const SizedBox(height: 12),
          MacosTextField(
            controller: controller,
            autofocus: true,
            placeholder: 'Name',
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PushButton(
                controlSize: ControlSize.large,
                secondary: true,
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 10),
              PushButton(
                controlSize: ControlSize.large,
                onPressed: () {
                  if (controller.text.trim().isEmpty) return;
                  shouldSave = true;
                  Navigator.pop(ctx);
                },
                child: const Text('Create'),
              ),
            ],
          ),
        ],
      ),
    );
    if (!shouldSave) return;
    await notifier.createTilesetElementSubgroup(
      tilesetId,
      parentGroupId,
      controller.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _expandedTilesetGroups.add(parentGroupId);
    });
  }

  Future<void> _showRenameTilesetGroupDialog(
    BuildContext context, {
    required EditorNotifier notifier,
    required String tilesetId,
    required String groupId,
    required String currentName,
  }) async {
    final controller = TextEditingController(text: currentName);
    var shouldSave = false;
    await showMacosEditorModalSheet<void>(
      context: context,
      maxWidth: 400,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Rename Tileset Group',
            style: editorMacosSheetTitleStyle(ctx),
          ),
          const SizedBox(height: 12),
          MacosTextField(
            controller: controller,
            autofocus: true,
            placeholder: 'Name',
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PushButton(
                controlSize: ControlSize.large,
                secondary: true,
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 10),
              PushButton(
                controlSize: ControlSize.large,
                onPressed: () {
                  if (controller.text.trim().isEmpty) return;
                  shouldSave = true;
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
    if (!shouldSave) return;
    await notifier.renameTilesetElementGroup(
      tilesetId,
      groupId,
      controller.text.trim(),
    );
  }

  Future<void> _showCreateElementDialog(
    BuildContext context, {
    required EditorNotifier notifier,
    required ProjectManifest project,
    required ui.Image image,
    required String tilesetId,
    required List<TilesetElementGroup> tilesetGroups,
    required TilesetSourceRect source,
    required int tileWidth,
    required int tileHeight,
    required String? activeLayerId,
    required List<TileLayer> tileLayers,
  }) async {
    final categories = notifier.getElementCategories();
    if (categories.isEmpty) {
      await showCupertinoEditorAlert(
        context,
        title: 'Missing Element Category',
        message:
            'Create at least one element category before creating an element.',
      );
      return;
    }
    final categoriesById = <String, ProjectElementCategory>{
      for (final category in categories) category.id: category,
    };
    final nameController = TextEditingController(
      text: 'element_${source.x}_${source.y}',
    );
    final tagsController = TextEditingController();
    var selectedCategoryId = _selectedCategoryId;
    if (selectedCategoryId == null ||
        !categories.any((category) => category.id == selectedCategoryId)) {
      selectedCategoryId = categories.first.id;
    }
    final sortedTilesetGroups = List<TilesetElementGroup>.from(tilesetGroups)
      ..sort((a, b) {
        if (a.parentGroupId == b.parentGroupId) {
          final sortCompare = a.sortOrder.compareTo(b.sortOrder);
          if (sortCompare != 0) return sortCompare;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        }
        final parentA = a.parentGroupId ?? '';
        final parentB = b.parentGroupId ?? '';
        final parentCompare = parentA.compareTo(parentB);
        if (parentCompare != 0) return parentCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    final tilesetGroupById = <String, TilesetElementGroup>{
      for (final group in sortedTilesetGroups) group.id: group,
    };
    String? selectedTilesetGroupId =
        ref.read(editorNotifierProvider).selectedTilesetElementGroupId;
    if (selectedTilesetGroupId != null &&
        !tilesetGroupById.containsKey(selectedTilesetGroupId)) {
      selectedTilesetGroupId = null;
    }
    String? selectedGroupId = _activeMapGroupId();
    String? selectedLayerId = activeLayerId;
    if (selectedLayerId != null &&
        !tileLayers.any((layer) => layer.id == selectedLayerId)) {
      selectedLayerId = null;
    }
    var selectedPresetKind = ElementPresetKind.generic;
    ElementCollisionProfile? collisionProfile;
    var collisionPadding = const WarpTriggerPadding();

    final groups = List<ProjectMapGroup>.from(project.groups)
      ..sort((a, b) {
        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) return sortCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    final groupById = <String, ProjectMapGroup>{
      for (final group in groups) group.id: group,
    };

    var shouldSave = false;
    String tilesetGroupRowLabel(String id) {
      if (id.isEmpty) return 'None';
      return _buildTilesetGroupPathLabel(tilesetGroupById, id);
    }

    String scopeRowLabel(String id) {
      if (id.isEmpty) return 'Global';
      return _buildGroupPathLabel(groupById, id);
    }

    String layerRowLabel(String id) {
      if (id.isEmpty) return 'None';
      return tileLayers.firstWhere((l) => l.id == id).name;
    }

    await showMacosEditorTallSheet<void>(
      context: context,
      maxWidth: 440,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => ListView(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create Element',
                    style: editorMacosSheetTitleStyle(ctx),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Source: ${source.width}x${source.height} at (${source.x}, ${source.y})',
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel.resolveFrom(ctx),
                    ),
                  ),
                  const SizedBox(height: 12),
                  MacosTextField(
                    controller: nameController,
                    autofocus: true,
                    placeholder: 'Name',
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PushButton(
                      controlSize: ControlSize.regular,
                      secondary: true,
                      onPressed: () async {
                        final picked = await showCupertinoListPicker<String>(
                          context: ctx,
                          title: 'Category',
                          items: categories.map((c) => c.id).toList(),
                          labelOf: (id) => _buildCategoryPathLabel(
                            categoriesById: categoriesById,
                            categoryId: id,
                          ),
                        );
                        if (picked != null) {
                          setStateDialog(() => selectedCategoryId = picked);
                        }
                      },
                      child: Text(
                        'Category: ${_buildCategoryPathLabel(categoriesById: categoriesById, categoryId: selectedCategoryId!)}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PushButton(
                      controlSize: ControlSize.regular,
                      secondary: true,
                      onPressed: () async {
                        final items = <String>[
                          '',
                          ...sortedTilesetGroups.map((g) => g.id),
                        ];
                        final picked = await showCupertinoListPicker<String>(
                          context: ctx,
                          title: 'Tileset Group',
                          items: items,
                          labelOf: tilesetGroupRowLabel,
                        );
                        if (picked != null) {
                          setStateDialog(
                            () => selectedTilesetGroupId =
                                picked.isEmpty ? null : picked,
                          );
                        }
                      },
                      child: Text(
                        'Tileset Group: ${tilesetGroupRowLabel(selectedTilesetGroupId ?? '')}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PushButton(
                      controlSize: ControlSize.regular,
                      secondary: true,
                      onPressed: () async {
                        final items = <String>[
                          '',
                          ...groups.map((g) => g.id),
                        ];
                        final picked = await showCupertinoListPicker<String>(
                          context: ctx,
                          title: 'Scope Group',
                          items: items,
                          labelOf: scopeRowLabel,
                        );
                        if (picked != null) {
                          setStateDialog(
                            () => selectedGroupId =
                                picked.isEmpty ? null : picked,
                          );
                        }
                      },
                      child: Text(
                        'Scope Group: ${scopeRowLabel(selectedGroupId ?? '')}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PushButton(
                      controlSize: ControlSize.regular,
                      secondary: true,
                      onPressed: () async {
                        final items = <String>[
                          '',
                          ...tileLayers.map((l) => l.id),
                        ];
                        final picked = await showCupertinoListPicker<String>(
                          context: ctx,
                          title: 'Recommended Layer',
                          items: items,
                          labelOf: layerRowLabel,
                        );
                        if (picked != null) {
                          setStateDialog(
                            () => selectedLayerId =
                                picked.isEmpty ? null : picked,
                          );
                        }
                      },
                      child: Text(
                        'Recommended Layer: ${layerRowLabel(selectedLayerId ?? '')}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  MacosTextField(
                    controller: tagsController,
                    placeholder: 'Tags (tree,outdoor,oak)',
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PushButton(
                      controlSize: ControlSize.regular,
                      secondary: true,
                      onPressed: () async {
                        final picked =
                            await showCupertinoListPicker<ElementPresetKind>(
                          context: ctx,
                          title: 'Type prédéfini',
                          items: ElementPresetKind.values,
                          labelOf: _elementPresetLabel,
                        );
                        if (picked != null) {
                          setStateDialog(() => selectedPresetKind = picked);
                        }
                      },
                      child: Text(
                        'Type: ${_elementPresetLabel(selectedPresetKind)}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ElementCollisionProfileSummaryCard(
                    source: source,
                    tileWidth: tileWidth,
                    tileHeight: tileHeight,
                    profile: collisionProfile,
                    draftPadding: collisionPadding,
                    onOpenEditor: () async {
                      final edited = await showElementCollisionEditorSheet(
                        context: ctx,
                        elementName: nameController.text.trim().isEmpty
                            ? 'Nouvel élément'
                            : nameController.text.trim(),
                        image: image,
                        source: source,
                        tileWidth: tileWidth,
                        tileHeight: tileHeight,
                        initialProfile: collisionProfile,
                        fallbackPadding: collisionPadding,
                      );
                      if (edited == null) {
                        return;
                      }
                      setStateDialog(() {
                        collisionProfile = edited;
                        collisionPadding = edited.padding;
                      });
                    },
                    onClearProfile: () {
                      setStateDialog(() {
                        collisionProfile = null;
                        collisionPadding = const WarpTriggerPadding();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      PushButton(
                        controlSize: ControlSize.large,
                        secondary: true,
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      PushButton(
                        controlSize: ControlSize.large,
                        onPressed: () async {
                          if (nameController.text.trim().isEmpty) {
                            await showCupertinoEditorAlert(
                              ctx,
                              message: 'Name is required.',
                            );
                            return;
                          }
                          shouldSave = true;
                          Navigator.pop(ctx);
                        },
                        child: const Text('Create'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (!shouldSave || selectedCategoryId == null) return;
    await notifier.createProjectElement(
      name: nameController.text.trim(),
      tilesetId: tilesetId,
      categoryId: selectedCategoryId!,
      tilesetGroupId: selectedTilesetGroupId,
      source: source,
      presetKind: selectedPresetKind,
      collisionProfile: collisionProfile,
      groupId: selectedGroupId,
      recommendedLayerId: selectedLayerId,
      tags: _parseTags(tagsController.text),
    );
    notifier.selectTool(EditorToolType.tilePaint);
    if (!mounted) return;
    setState(() {
      _creationMode = false;
      _selectionStart = null;
      _selectionEnd = null;
    });
  }

  Future<void> _showEditElementDialog(
    BuildContext context, {
    required EditorNotifier notifier,
    required ProjectManifest project,
    required ui.Image image,
    required ProjectElementEntry element,
    required List<ProjectElementCategory> categories,
    required int tileWidth,
    required int tileHeight,
    required List<TileLayer> tileLayers,
    required List<TilesetElementGroup> tilesetGroups,
  }) async {
    final categoriesById = <String, ProjectElementCategory>{
      for (final category in categories) category.id: category,
    };
    final sortedTilesetGroups = List<TilesetElementGroup>.from(tilesetGroups)
      ..sort((a, b) {
        if (a.parentGroupId == b.parentGroupId) {
          final sortCompare = a.sortOrder.compareTo(b.sortOrder);
          if (sortCompare != 0) return sortCompare;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        }
        final parentA = a.parentGroupId ?? '';
        final parentB = b.parentGroupId ?? '';
        final parentCompare = parentA.compareTo(parentB);
        if (parentCompare != 0) return parentCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    final tilesetGroupById = <String, TilesetElementGroup>{
      for (final group in sortedTilesetGroups) group.id: group,
    };
    final groups = List<ProjectMapGroup>.from(project.groups)
      ..sort((a, b) {
        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) return sortCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    final groupById = <String, ProjectMapGroup>{
      for (final group in groups) group.id: group,
    };

    final nameController = TextEditingController(text: element.name);
    final tagsController = TextEditingController(text: element.tags.join(','));
    String selectedCategoryId = element.categoryId;
    String? selectedTilesetGroupId = element.tilesetGroupId;
    if (selectedTilesetGroupId != null &&
        !tilesetGroupById.containsKey(selectedTilesetGroupId)) {
      selectedTilesetGroupId = null;
    }
    String? selectedGroupId = element.groupId;
    String? selectedLayerId = element.recommendedLayerId;
    if (selectedLayerId != null &&
        !tileLayers.any((layer) => layer.id == selectedLayerId)) {
      selectedLayerId = null;
    }
    var selectedPresetKind = element.presetKind;
    ElementCollisionProfile? collisionProfile = element.collisionProfile;
    ProjectElementShadowConfig? shadowConfig = element.shadow;
    var collisionPadding =
        collisionProfile?.padding ?? const WarpTriggerPadding();
    var frames = List<TilesetVisualFrame>.from(element.frames);
    var shouldSave = false;

    String editTilesetGroupRowLabel(String id) {
      if (id.isEmpty) return 'None';
      return _buildTilesetGroupPathLabel(tilesetGroupById, id);
    }

    String editScopeRowLabel(String id) {
      if (id.isEmpty) return 'Global';
      return _buildGroupPathLabel(groupById, id);
    }

    String editLayerRowLabel(String id) {
      if (id.isEmpty) return 'None';
      return tileLayers.firstWhere((l) => l.id == id).name;
    }

    await showMacosEditorTallSheet<void>(
      context: context,
      maxWidth: 440,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => ListView(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Edit Element',
                    style: editorMacosSheetTitleStyle(ctx),
                  ),
                  const SizedBox(height: 12),
                  _ElementFramesEditor(
                    image: image,
                    tileWidth: tileWidth,
                    tileHeight: tileHeight,
                    ownerTilesetId: element.tilesetId,
                    frames: frames,
                    onChanged: (next) {
                      setStateDialog(() {
                        frames = next;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  MacosTextField(
                    controller: nameController,
                    placeholder: 'Name',
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PushButton(
                      controlSize: ControlSize.regular,
                      secondary: true,
                      onPressed: () async {
                        final picked = await showCupertinoListPicker<String>(
                          context: ctx,
                          title: 'Category',
                          items: categories.map((c) => c.id).toList(),
                          labelOf: (id) => _buildCategoryPathLabel(
                            categoriesById: categoriesById,
                            categoryId: id,
                          ),
                        );
                        if (picked != null) {
                          setStateDialog(() => selectedCategoryId = picked);
                        }
                      },
                      child: Text(
                        'Category: ${_buildCategoryPathLabel(categoriesById: categoriesById, categoryId: selectedCategoryId)}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PushButton(
                      controlSize: ControlSize.regular,
                      secondary: true,
                      onPressed: () async {
                        final items = <String>[
                          '',
                          ...sortedTilesetGroups.map((g) => g.id),
                        ];
                        final picked = await showCupertinoListPicker<String>(
                          context: ctx,
                          title: 'Tileset Group',
                          items: items,
                          labelOf: editTilesetGroupRowLabel,
                        );
                        if (picked != null) {
                          setStateDialog(
                            () => selectedTilesetGroupId =
                                picked.isEmpty ? null : picked,
                          );
                        }
                      },
                      child: Text(
                        'Tileset Group: ${editTilesetGroupRowLabel(selectedTilesetGroupId ?? '')}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PushButton(
                      controlSize: ControlSize.regular,
                      secondary: true,
                      onPressed: () async {
                        final items = <String>[
                          '',
                          ...groups.map((g) => g.id),
                        ];
                        final picked = await showCupertinoListPicker<String>(
                          context: ctx,
                          title: 'Scope Group',
                          items: items,
                          labelOf: editScopeRowLabel,
                        );
                        if (picked != null) {
                          setStateDialog(
                            () => selectedGroupId =
                                picked.isEmpty ? null : picked,
                          );
                        }
                      },
                      child: Text(
                        'Scope Group: ${editScopeRowLabel(selectedGroupId ?? '')}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PushButton(
                      controlSize: ControlSize.regular,
                      secondary: true,
                      onPressed: () async {
                        final items = <String>[
                          '',
                          ...tileLayers.map((l) => l.id),
                        ];
                        final picked = await showCupertinoListPicker<String>(
                          context: ctx,
                          title: 'Recommended Layer',
                          items: items,
                          labelOf: editLayerRowLabel,
                        );
                        if (picked != null) {
                          setStateDialog(
                            () => selectedLayerId =
                                picked.isEmpty ? null : picked,
                          );
                        }
                      },
                      child: Text(
                        'Recommended Layer: ${editLayerRowLabel(selectedLayerId ?? '')}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  MacosTextField(
                    controller: tagsController,
                    placeholder: 'Tags (tree,outdoor,oak)',
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PushButton(
                      controlSize: ControlSize.regular,
                      secondary: true,
                      onPressed: () async {
                        final picked =
                            await showCupertinoListPicker<ElementPresetKind>(
                          context: ctx,
                          title: 'Type prédéfini',
                          items: ElementPresetKind.values,
                          labelOf: _elementPresetLabel,
                        );
                        if (picked != null) {
                          setStateDialog(() => selectedPresetKind = picked);
                        }
                      },
                      child: Text(
                        'Type: ${_elementPresetLabel(selectedPresetKind)}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElementShadowSection(
                    manifest: project,
                    element: element,
                    shadow: shadowConfig,
                    onChanged: (next) {
                      setStateDialog(() {
                        shadowConfig = next;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  _ElementCollisionProfileSummaryCard(
                    source: frames.primarySource,
                    tileWidth: tileWidth,
                    tileHeight: tileHeight,
                    profile: collisionProfile,
                    draftPadding: collisionPadding,
                    onOpenEditor: () async {
                      final edited = await showElementCollisionEditorSheet(
                        context: ctx,
                        elementName: nameController.text.trim().isEmpty
                            ? element.name
                            : nameController.text.trim(),
                        image: image,
                        source: frames.primarySource,
                        tileWidth: tileWidth,
                        tileHeight: tileHeight,
                        initialProfile: collisionProfile,
                        fallbackPadding: collisionPadding,
                      );
                      if (edited == null) {
                        return;
                      }
                      setStateDialog(() {
                        collisionProfile = edited;
                        collisionPadding = edited.padding;
                      });
                    },
                    onClearProfile: () {
                      setStateDialog(() {
                        collisionProfile = null;
                        collisionPadding = const WarpTriggerPadding();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      PushButton(
                        controlSize: ControlSize.large,
                        secondary: true,
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      PushButton(
                        controlSize: ControlSize.large,
                        onPressed: () async {
                          if (nameController.text.trim().isEmpty) {
                            await showCupertinoEditorAlert(
                              ctx,
                              message: 'Name is required.',
                            );
                            return;
                          }
                          shouldSave = true;
                          Navigator.pop(ctx);
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (!shouldSave) return;
    await notifier.updateProjectElement(
      elementId: element.id,
      name: nameController.text.trim(),
      presetKind: selectedPresetKind,
      collisionProfile: collisionProfile,
      clearCollisionProfile: collisionProfile == null,
      categoryId: selectedCategoryId,
      tilesetGroupId: selectedTilesetGroupId,
      clearTilesetGroupId: selectedTilesetGroupId == null,
      groupId: selectedGroupId,
      clearGroupId: selectedGroupId == null,
      recommendedLayerId: selectedLayerId,
      clearRecommendedLayerId: selectedLayerId == null,
      shadow: shadowConfig,
      clearShadow: shadowConfig == null,
      frames: frames,
      tags: _parseTags(tagsController.text),
    );
  }

  Future<void> _showDeleteElementDialog(
    BuildContext context, {
    required EditorNotifier notifier,
    required ProjectElementEntry element,
  }) async {
    final shouldDelete = await showMacosEditorTwoChoiceAlert(
      context,
      title: 'Delete Element',
      message: 'Delete "${element.name}"?',
      primaryLabel: 'Delete',
      primaryIsDestructive: true,
    );
    if (!shouldDelete) return;
    await notifier.deleteProjectElement(element.id);
  }

  Future<void> _showDeletePlacedInstanceDialog(
    BuildContext context, {
    required EditorNotifier notifier,
    required _PlacedElementInstanceVm instance,
  }) async {
    final elementName = instance.element?.name ?? instance.instance.elementId;
    final shouldDelete = await showMacosEditorTwoChoiceAlert(
      context,
      title: 'Supprimer l’instance',
      message:
          'Supprimer "$elementName" en (${instance.pos.x}, ${instance.pos.y}) sur "${instance.layerName}" ?',
      primaryLabel: 'Supprimer',
      primaryIsDestructive: true,
    );
    if (!shouldDelete) {
      return;
    }
    notifier.deletePlacedElementInstance(instanceId: instance.instanceId);
  }

  List<String> _parseTags(String value) {
    return value
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  String? _activeMapGroupId() {
    final project = ref.read(editorNotifierProvider).project;
    final map = ref.read(editorNotifierProvider).activeMap;
    if (project == null || map == null) return null;
    for (final entry in project.maps) {
      if (entry.id == map.id) {
        return entry.groupId;
      }
    }
    return null;
  }

  String _legacyCategoryLabel(PaletteCategory category) {
    switch (category) {
      case PaletteCategory.floors:
        return 'Sols';
      case PaletteCategory.paths:
        return 'Chemins';
      case PaletteCategory.water:
        return 'Eau';
      case PaletteCategory.buildings:
        return 'Batiments';
      case PaletteCategory.roofs:
        return 'Toits';
      case PaletteCategory.plants:
        return 'Plantes';
      case PaletteCategory.trees:
        return 'Arbres';
      case PaletteCategory.cliffs:
        return 'Falaises';
      case PaletteCategory.decorations:
        return 'Decorations';
      case PaletteCategory.interiors:
        return 'Interieurs';
      case PaletteCategory.objects:
        return 'Objets';
      case PaletteCategory.uncategorized:
        return 'Non classes';
    }
  }
}

class _PlacedElementBehaviorsSection extends StatefulWidget {
  const _PlacedElementBehaviorsSection({
    required this.value,
    required this.dialogues,
    required this.projectRootPath,
    required this.onChanged,
  });

  final List<MapPlacedElementBehavior> value;
  final List<ProjectDialogueEntry> dialogues;
  final String? projectRootPath;
  final ValueChanged<List<MapPlacedElementBehavior>> onChanged;

  @override
  State<_PlacedElementBehaviorsSection> createState() =>
      _PlacedElementBehaviorsSectionState();
}

class _PlacedElementBehaviorsSectionState
    extends State<_PlacedElementBehaviorsSection> {
  static const String _dialogueNoneMenuId = '__placed_behavior_dialogue_none__';
  static const String _nodeNoneMenuId = '__placed_behavior_node_none__';
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  int _selectedIndex = 0;
  String _messageDraft = '';
  Timer? _messageCommitDebounce;
  List<String> _dialogueNodes = const <String>[];
  bool _dialogueNodesLoading = false;
  int _dialogueNodesRequestId = 0;

  @override
  void initState() {
    super.initState();
    _messageFocusNode.addListener(_onMessageFocusChanged);
    _syncFromWidget(force: true);
    Future.microtask(_reloadDialogueNodesForSelected);
  }

  @override
  void didUpdateWidget(covariant _PlacedElementBehaviorsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncFromWidget();
    final dialoguesChanged = !listEquals(oldWidget.dialogues, widget.dialogues);
    final rootChanged = oldWidget.projectRootPath != widget.projectRootPath;
    final valueChanged = !listEquals(oldWidget.value, widget.value);
    if (dialoguesChanged || rootChanged || valueChanged) {
      Future.microtask(_reloadDialogueNodesForSelected);
    }
  }

  @override
  void dispose() {
    _messageCommitDebounce?.cancel();
    _messageFocusNode.removeListener(_onMessageFocusChanged);
    _messageFocusNode.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onMessageFocusChanged() {
    if (_messageFocusNode.hasFocus) {
      return;
    }
    _commitMessageDraft();
  }

  void _syncFromWidget({bool force = false}) {
    if (widget.value.isEmpty) {
      _selectedIndex = 0;
      _setMessageDraft('', force: force);
      return;
    }
    if (_selectedIndex >= widget.value.length) {
      _selectedIndex = widget.value.length - 1;
    }
    _applyDraftsFromBehavior(widget.value[_selectedIndex], force: force);
  }

  void _applyDraftsFromBehavior(
    MapPlacedElementBehavior behavior, {
    bool force = false,
  }) {
    _setMessageDraft(behavior.effect.message ?? '', force: force);
  }

  void _setMessageDraft(String value, {bool force = false}) {
    final canApply = force || !_messageFocusNode.hasFocus;
    if (!canApply) {
      return;
    }
    if (_messageDraft == value && _messageController.text == value) {
      return;
    }
    _messageDraft = value;
    _messageController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _scheduleMessageCommit() {
    _messageCommitDebounce?.cancel();
    _messageCommitDebounce = Timer(const Duration(milliseconds: 220), () {
      _commitMessageDraft();
    });
  }

  void _commitDrafts() {
    _commitMessageDraft();
  }

  void _commitMessageDraft() {
    _messageCommitDebounce?.cancel();
    final selected = _selectedBehavior;
    if (selected == null ||
        selected.effect.type != MapPlacedElementEffectType.showMessage) {
      return;
    }
    final normalized = _messageDraft.trim().isEmpty ? null : _messageDraft;
    if (selected.effect.message == normalized) {
      return;
    }
    _replaceSelectedBehavior(
      selected.copyWith(
        effect: selected.effect.copyWith(message: normalized),
      ),
    );
  }

  MapPlacedElementBehavior _defaultBehavior() {
    return const MapPlacedElementBehavior(
      enabled: true,
      trigger: MapPlacedElementTriggerType.onAction,
      effect: MapPlacedElementEffect(
        type: MapPlacedElementEffectType.showMessage,
        message: '...',
      ),
    );
  }

  void _emit(List<MapPlacedElementBehavior> next) {
    widget.onChanged(next);
  }

  void _addBehavior() {
    _commitDrafts();
    final next = List<MapPlacedElementBehavior>.from(
      widget.value,
      growable: true,
    )..add(_defaultBehavior());
    _selectedIndex = next.length - 1;
    _emit(next);
  }

  void _removeSelectedBehavior() {
    if (widget.value.isEmpty) {
      return;
    }
    _commitDrafts();
    final next = List<MapPlacedElementBehavior>.from(
      widget.value,
      growable: true,
    );
    next.removeAt(_selectedIndex);
    if (_selectedIndex >= next.length) {
      _selectedIndex = next.isEmpty ? 0 : next.length - 1;
    }
    _emit(next);
  }

  void _replaceSelectedBehavior(MapPlacedElementBehavior behavior) {
    if (widget.value.isEmpty) {
      return;
    }
    final next = List<MapPlacedElementBehavior>.from(
      widget.value,
      growable: true,
    );
    next[_selectedIndex] = behavior;
    _emit(next);
  }

  void _updateSelected(MapPlacedElementBehavior behavior) {
    _replaceSelectedBehavior(behavior);
  }

  int _defaultExplicitCooldownMs(MapPlacedElementEffectType effectType) {
    switch (effectType) {
      case MapPlacedElementEffectType.showMessage:
        return 650;
      case MapPlacedElementEffectType.openDialogue:
        return 900;
      case MapPlacedElementEffectType.setAnimationEnabled:
        return 0;
      case MapPlacedElementEffectType.playAnimationOnce:
        return 180;
    }
  }

  List<MapPlacedElementTriggerScope> _allowedScopesForTrigger(
    MapPlacedElementTriggerType trigger,
  ) {
    switch (trigger) {
      case MapPlacedElementTriggerType.onAction:
        return const <MapPlacedElementTriggerScope>[
          MapPlacedElementTriggerScope.defaultScope,
          MapPlacedElementTriggerScope.facingOnly,
        ];
      case MapPlacedElementTriggerType.onEnter:
        return const <MapPlacedElementTriggerScope>[
          MapPlacedElementTriggerScope.defaultScope,
          MapPlacedElementTriggerScope.oncePerEnter,
          MapPlacedElementTriggerScope.whileInsideSingleShot,
        ];
      case MapPlacedElementTriggerType.onNear:
        return const <MapPlacedElementTriggerScope>[
          MapPlacedElementTriggerScope.defaultScope,
          MapPlacedElementTriggerScope.whileInsideSingleShot,
          MapPlacedElementTriggerScope.facingOnly,
          MapPlacedElementTriggerScope.nearCardinalOnly,
        ];
      case MapPlacedElementTriggerType.onBump:
      case MapPlacedElementTriggerType.onExit:
        return const <MapPlacedElementTriggerScope>[
          MapPlacedElementTriggerScope.defaultScope,
        ];
    }
  }

  String _scopeLabel(MapPlacedElementTriggerScope scope) {
    switch (scope) {
      case MapPlacedElementTriggerScope.defaultScope:
        return 'Par défaut';
      case MapPlacedElementTriggerScope.oncePerEnter:
        return 'Une fois/entrée';
      case MapPlacedElementTriggerScope.whileInsideSingleShot:
        return 'Zone unique';
      case MapPlacedElementTriggerScope.facingOnly:
        return 'Regard uniquement';
      case MapPlacedElementTriggerScope.nearCardinalOnly:
        return 'Proche N/S/E/O';
    }
  }

  MapPlacedElementBehavior? get _selectedBehavior {
    if (widget.value.isEmpty) {
      return null;
    }
    if (_selectedIndex < 0 || _selectedIndex >= widget.value.length) {
      return null;
    }
    return widget.value[_selectedIndex];
  }

  List<ProjectDialogueEntry> _sortedDialogues() {
    final sorted = List<ProjectDialogueEntry>.of(widget.dialogues);
    sorted.sort((a, b) {
      final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      if (byName != 0) {
        return byName;
      }
      return a.id.compareTo(b.id);
    });
    return sorted;
  }

  String _normalizeDialogueRelativePath(String raw) {
    return raw.trim().replaceAll(r'\', '/');
  }

  String? _resolveDialogueFilePath(String dialogueId) {
    final root = widget.projectRootPath;
    if (root == null || root.trim().isEmpty) {
      return null;
    }
    final normalizedId = dialogueId.trim();
    if (normalizedId.isEmpty) {
      return null;
    }
    final matches = widget.dialogues.where((e) => e.id == normalizedId);
    if (matches.isEmpty) {
      return null;
    }
    final rel = _normalizeDialogueRelativePath(matches.first.relativePath);
    if (rel.isEmpty) {
      return null;
    }
    return '$root/$rel';
  }

  Future<List<String>> _extractYarnNodeTitles(String absolutePath) async {
    try {
      final file = File(absolutePath);
      if (!await file.exists()) {
        return const <String>[];
      }
      final lines = await file.readAsLines();
      return [
        for (final line in lines)
          if (line.trim().startsWith('title:'))
            line.trim().substring('title:'.length).trim(),
      ].where((title) => title.isNotEmpty).toList(growable: false);
    } catch (_) {
      return const <String>[];
    }
  }

  Future<void> _reloadDialogueNodesForSelected() async {
    final selected = _selectedBehavior;
    if (selected == null ||
        selected.effect.type != MapPlacedElementEffectType.openDialogue) {
      if (mounted) {
        setState(() {
          _dialogueNodesLoading = false;
          _dialogueNodes = const <String>[];
        });
      }
      return;
    }
    final dialogueId = selected.effect.dialogue?.dialogueId.trim() ?? '';
    final path = _resolveDialogueFilePath(dialogueId);
    if (path == null) {
      if (mounted) {
        setState(() {
          _dialogueNodesLoading = false;
          _dialogueNodes = const <String>[];
        });
      }
      return;
    }
    final requestId = ++_dialogueNodesRequestId;
    if (mounted) {
      setState(() {
        _dialogueNodesLoading = true;
      });
    }
    final nodes = await _extractYarnNodeTitles(path);
    if (!mounted || requestId != _dialogueNodesRequestId) {
      return;
    }
    setState(() {
      _dialogueNodesLoading = false;
      _dialogueNodes = nodes;
    });
  }

  Future<String?> _showDialoguePicker({
    required BuildContext context,
    required List<ProjectDialogueEntry> sorted,
    required String selectedDialogueId,
  }) async {
    final searchController = TextEditingController();
    var query = '';
    try {
      return await showMacosSheet<String>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setModalState) {
              final q = query.trim().toLowerCase();
              final filtered = sorted.where((entry) {
                if (q.isEmpty) {
                  return true;
                }
                final haystack =
                    '${entry.name} ${entry.id} ${entry.relativePath}'
                        .toLowerCase();
                return haystack.contains(q);
              }).toList(growable: false);
              final selectedMissing = selectedDialogueId.isNotEmpty &&
                  !sorted.any((entry) => entry.id == selectedDialogueId);
              return Center(
                child: MacosSheet(
                  insetPadding: const EdgeInsets.symmetric(
                    horizontal: 72,
                    vertical: 44,
                  ),
                  child: SizedBox(
                    width: 520,
                    height: MediaQuery.sizeOf(ctx).height * 0.62,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Choisir un script Yarn',
                            textAlign: TextAlign.center,
                            style: editorMacosSheetTitleStyle(ctx),
                          ),
                          const SizedBox(height: 10),
                          CupertinoTextField(
                            controller: searchController,
                            placeholder: 'Rechercher (nom, id, chemin)…',
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            onChanged: (value) {
                              setModalState(() {
                                query = value;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: ListView.separated(
                              itemCount: 1 +
                                  (selectedMissing ? 1 : 0) +
                                  filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 6),
                              itemBuilder: (c, i) {
                                if (i == 0) {
                                  return PushButton(
                                    controlSize: ControlSize.large,
                                    secondary: true,
                                    onPressed: () => Navigator.of(c).pop(
                                      _dialogueNoneMenuId,
                                    ),
                                    child: const Text('Aucun dialogue'),
                                  );
                                }
                                final offset = i - 1;
                                if (selectedMissing && offset == 0) {
                                  return PushButton(
                                    controlSize: ControlSize.large,
                                    secondary: true,
                                    onPressed: () => Navigator.of(c).pop(
                                      selectedDialogueId,
                                    ),
                                    child: Text(
                                      '$selectedDialogueId (absent du projet)',
                                    ),
                                  );
                                }
                                final index =
                                    offset - (selectedMissing ? 1 : 0);
                                final entry = filtered[index];
                                return PushButton(
                                  controlSize: ControlSize.large,
                                  secondary: true,
                                  onPressed: () =>
                                      Navigator.of(c).pop(entry.id),
                                  child: Text(
                                    '${entry.name} · ${entry.relativePath}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          PushButton(
                            controlSize: ControlSize.large,
                            secondary: true,
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      searchController.dispose();
    }
  }

  void _updateSelectedDialogue(String dialogueId) {
    final selected = _selectedBehavior;
    if (selected == null ||
        selected.effect.type != MapPlacedElementEffectType.openDialogue) {
      return;
    }
    final normalizedId = dialogueId.trim();
    final currentDialogue = selected.effect.dialogue;
    if (currentDialogue?.dialogueId == normalizedId) {
      return;
    }
    final nextDialogue = DialogueRef(
      dialogueId: normalizedId,
      scriptPathRelative: currentDialogue?.scriptPathRelative ?? '',
      startNode: null,
    );
    _updateSelected(
      selected.copyWith(
        effect: selected.effect.copyWith(dialogue: nextDialogue),
      ),
    );
  }

  void _updateSelectedDialogueNode(String? nodeId) {
    final selected = _selectedBehavior;
    if (selected == null ||
        selected.effect.type != MapPlacedElementEffectType.openDialogue) {
      return;
    }
    final currentDialogue = selected.effect.dialogue;
    if (currentDialogue == null) {
      return;
    }
    final normalizedNode =
        (nodeId == null || nodeId.trim().isEmpty) ? null : nodeId.trim();
    if (currentDialogue.startNode == normalizedNode) {
      return;
    }
    _updateSelected(
      selected.copyWith(
        effect: selected.effect.copyWith(
          dialogue: currentDialogue.copyWith(startNode: normalizedNode),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);
    final selected = _selectedBehavior;
    const maxBehaviorCooldownMs = 600000;
    final allowedScopes = selected == null
        ? const <MapPlacedElementTriggerScope>[]
        : _allowedScopesForTrigger(selected.trigger);
    final selectedScope = selected == null
        ? MapPlacedElementTriggerScope.defaultScope
        : allowedScopes.contains(selected.triggerScope)
            ? selected.triggerScope
            : MapPlacedElementTriggerScope.defaultScope;

    String triggerHelp(MapPlacedElementTriggerType trigger) {
      switch (trigger) {
        case MapPlacedElementTriggerType.onAction:
          return 'Action: déclenché avec la touche d’action face à l’élément.';
        case MapPlacedElementTriggerType.onEnter:
          return 'Entrée: déclenché quand le joueur marche sur l’élément.';
        case MapPlacedElementTriggerType.onBump:
          return 'Contact: déclenché quand le joueur se cogne contre l’élément.';
        case MapPlacedElementTriggerType.onExit:
          return 'Sortie: déclenché quand le joueur quitte la zone couverte.';
        case MapPlacedElementTriggerType.onNear:
          return 'Proximité: déclenché quand le joueur devient adjacent (4 directions).';
      }
    }

    String scopeHelp(MapPlacedElementTriggerScope scope) {
      switch (scope) {
        case MapPlacedElementTriggerScope.defaultScope:
          return 'Default: comportement actuel sans filtre supplémentaire.';
        case MapPlacedElementTriggerScope.oncePerEnter:
          return 'Once per enter: déclenche une fois à l’entrée, puis réarme après sortie.';
        case MapPlacedElementTriggerScope.whileInsideSingleShot:
          return 'Single-shot: un déclenchement tant que le joueur reste dans la zone, puis réarmement après sortie.';
        case MapPlacedElementTriggerScope.facingOnly:
          return 'Facing only: déclenche seulement si le joueur regarde l’élément.';
        case MapPlacedElementTriggerScope.nearCardinalOnly:
          return 'Near cardinal: proximité limitée à N/S/E/W (pas de diagonales).';
      }
    }

    String effectHelp(MapPlacedElementEffectType effectType) {
      switch (effectType) {
        case MapPlacedElementEffectType.showMessage:
          return 'Message: affiche un texte court dans le HUD runtime.';
        case MapPlacedElementEffectType.openDialogue:
          return 'Dialogue: choisis un script Yarn, puis un nœud de départ.';
        case MapPlacedElementEffectType.setAnimationEnabled:
          return 'Animation on/off: active ou coupe l’animation locale de cette instance.';
        case MapPlacedElementEffectType.playAnimationOnce:
          return 'Animation 1x: joue une séquence une fois puis revient à l’état normal.';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: Colors.white.withValues(alpha: 0.015),
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Comportements',
                  style: TextStyle(
                    color: label,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                minimumSize: Size.zero,
                onPressed: _addBehavior,
                child: const Text(
                  'Ajouter',
                  style: TextStyle(fontSize: 10),
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                minimumSize: Size.zero,
                onPressed:
                    widget.value.isEmpty ? null : _removeSelectedBehavior,
                child: const Text(
                  'Supprimer',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Décor enrichi local: utilise cette section pour des réactions simples. Pour un vrai acteur gameplay (PNJ, panneau, item), utilise une MapEntity.',
            style: TextStyle(
              color: secondary,
              fontSize: 10,
            ),
          ),
          if (widget.value.isEmpty) ...[
            Text(
              'Aucun comportement configuré.',
              style: TextStyle(
                color: secondary,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ajoute un comportement pour définir déclencheur + effet.',
              style: TextStyle(
                color: secondary,
                fontSize: 10,
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 28,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.value.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final behavior = widget.value[index];
                  final selectedChip = index == _selectedIndex;
                  return CupertinoButton(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    color: selectedChip
                        ? EditorChrome.inspectorJoyCyan.withValues(alpha: 0.3)
                        : EditorPaintColors.white12,
                    onPressed: () {
                      _commitDrafts();
                      setState(() {
                        _selectedIndex = index;
                        _applyDraftsFromBehavior(behavior, force: true);
                      });
                      Future.microtask(_reloadDialogueNodesForSelected);
                    },
                    child: Text(
                      '${index + 1}. ${behavior.trigger.name} → ${behavior.effect.type.name}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            if (selected != null) ...[
              const SizedBox(height: 8),
              _CompactSwitchRow(
                title: 'Activé',
                value: selected.enabled,
                onChanged: (next) =>
                    _updateSelected(selected.copyWith(enabled: next)),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'Déclencheur',
                    style: TextStyle(color: secondary, fontSize: 10),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CupertinoSlidingSegmentedControl<
                        MapPlacedElementTriggerType>(
                      groupValue: selected.trigger,
                      children: const {
                        MapPlacedElementTriggerType.onAction: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text('Action', style: TextStyle(fontSize: 10)),
                        ),
                        MapPlacedElementTriggerType.onEnter: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text('Entrée', style: TextStyle(fontSize: 10)),
                        ),
                        MapPlacedElementTriggerType.onBump: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child:
                              Text('Contact', style: TextStyle(fontSize: 10)),
                        ),
                        MapPlacedElementTriggerType.onExit: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text('Sortie', style: TextStyle(fontSize: 10)),
                        ),
                        MapPlacedElementTriggerType.onNear: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text('Proche', style: TextStyle(fontSize: 10)),
                        ),
                      },
                      onValueChanged: (next) {
                        if (next == null) {
                          return;
                        }
                        _commitDrafts();
                        final allowedScopesForNext =
                            _allowedScopesForTrigger(next);
                        final nextScope =
                            allowedScopesForNext.contains(selected.triggerScope)
                                ? selected.triggerScope
                                : MapPlacedElementTriggerScope.defaultScope;
                        _updateSelected(
                          selected.copyWith(
                            trigger: next,
                            triggerScope: nextScope,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                triggerHelp(selected.trigger),
                style: TextStyle(
                  color: secondary,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Scope',
                    style: TextStyle(color: secondary, fontSize: 10),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: PopupMenuButton<MapPlacedElementTriggerScope>(
                        padding: EdgeInsets.zero,
                        splashRadius: 20,
                        offset: const Offset(0, 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: EditorChrome.inspectorJoyBlue
                                .withValues(alpha: 0.35),
                          ),
                        ),
                        color: EditorChrome.islandFillElevated(context),
                        elevation: 3,
                        initialValue: selectedScope,
                        onSelected: (nextScope) {
                          _commitDrafts();
                          _updateSelected(
                            selected.copyWith(triggerScope: nextScope),
                          );
                        },
                        itemBuilder: (menuCtx) => [
                          for (final scope in allowedScopes)
                            PopupMenuItem<MapPlacedElementTriggerScope>(
                              value: scope,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 22,
                                    child: scope == selectedScope
                                        ? const Icon(
                                            CupertinoIcons.checkmark,
                                            size: 14,
                                            color:
                                                EditorChrome.inspectorJoyBlue,
                                          )
                                        : null,
                                  ),
                                  Expanded(
                                    child: Text(
                                      _scopeLabel(scope),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: scope == selectedScope
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: label,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: EditorChrome.largeIslandSurfaceColor(
                              context,
                              tint: EditorChrome.inspectorJoyBlue
                                  .withValues(alpha: 0.08),
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: EditorChrome.inspectorJoyBlue
                                  .withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _scopeLabel(selectedScope),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: label,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              Icon(
                                CupertinoIcons.chevron_down,
                                size: 12,
                                color: secondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                scopeHelp(selectedScope),
                style: TextStyle(
                  color: secondary,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Effet',
                    style: TextStyle(color: secondary, fontSize: 10),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CupertinoSlidingSegmentedControl<
                        MapPlacedElementEffectType>(
                      groupValue: selected.effect.type,
                      children: const {
                        MapPlacedElementEffectType.showMessage: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child:
                              Text('Message', style: TextStyle(fontSize: 10)),
                        ),
                        MapPlacedElementEffectType.openDialogue: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child:
                              Text('Dialogue', style: TextStyle(fontSize: 10)),
                        ),
                        MapPlacedElementEffectType.setAnimationEnabled: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text('Anim ON/OFF',
                              style: TextStyle(fontSize: 10)),
                        ),
                        MapPlacedElementEffectType.playAnimationOnce: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child:
                              Text('Anim 1x', style: TextStyle(fontSize: 10)),
                        ),
                      },
                      onValueChanged: (next) {
                        if (next == null) {
                          return;
                        }
                        _commitDrafts();
                        final effect = switch (next) {
                          MapPlacedElementEffectType.showMessage =>
                            const MapPlacedElementEffect(
                              type: MapPlacedElementEffectType.showMessage,
                              message: '...',
                            ),
                          MapPlacedElementEffectType.openDialogue =>
                            const MapPlacedElementEffect(
                              type: MapPlacedElementEffectType.openDialogue,
                              dialogue: DialogueRef(dialogueId: ''),
                            ),
                          MapPlacedElementEffectType.setAnimationEnabled =>
                            const MapPlacedElementEffect(
                              type: MapPlacedElementEffectType
                                  .setAnimationEnabled,
                              animationEnabled: true,
                            ),
                          MapPlacedElementEffectType.playAnimationOnce =>
                            const MapPlacedElementEffect(
                              type:
                                  MapPlacedElementEffectType.playAnimationOnce,
                            ),
                        };
                        _updateSelected(selected.copyWith(effect: effect));
                        Future.microtask(_reloadDialogueNodesForSelected);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                effectHelp(selected.effect.type),
                style: TextStyle(
                  color: secondary,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 8),
              _CompactSwitchRow(
                title: 'Cooldown explicite',
                value: selected.cooldownMs != null,
                onChanged: (next) {
                  if (!next) {
                    _updateSelected(selected.copyWith(cooldownMs: null));
                    return;
                  }
                  _updateSelected(
                    selected.copyWith(
                      cooldownMs:
                          _defaultExplicitCooldownMs(selected.effect.type),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              Text(
                selected.cooldownMs == null
                    ? 'Utilise la valeur par défaut du runtime pour cet effet.'
                    : 'Valeur forcée pour ce behavior. Le runtime ignore sa valeur par défaut.',
                style: TextStyle(
                  color: secondary,
                  fontSize: 10,
                ),
              ),
              if (selected.cooldownMs != null) ...[
                const SizedBox(height: 6),
                _CompactStepperRow(
                  label: 'Cooldown',
                  value: '${selected.cooldownMs} ms',
                  onMinus: () {
                    final current = selected.cooldownMs ?? 0;
                    final next = math.max(0, current - 50);
                    _updateSelected(selected.copyWith(cooldownMs: next));
                  },
                  onPlus: () {
                    final current = selected.cooldownMs ?? 0;
                    final next = math.min(maxBehaviorCooldownMs, current + 50);
                    _updateSelected(selected.copyWith(cooldownMs: next));
                  },
                  onReset: () =>
                      _updateSelected(selected.copyWith(cooldownMs: null)),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final preset in const [250, 500, 1000])
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        color: selected.cooldownMs == preset
                            ? EditorChrome.inspectorJoyBlue
                                .withValues(alpha: 0.25)
                            : EditorPaintColors.white12,
                        onPressed: () => _updateSelected(
                            selected.copyWith(cooldownMs: preset)),
                        child: Text(
                          '${preset}ms',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                  ],
                ),
              ],
              if (selected.effect.type ==
                  MapPlacedElementEffectType.showMessage)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: CupertinoTextField(
                    controller: _messageController,
                    focusNode: _messageFocusNode,
                    placeholder: 'Message…',
                    style: TextStyle(color: label, fontSize: 11),
                    placeholderStyle: TextStyle(color: secondary, fontSize: 11),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    onChanged: (text) {
                      _messageDraft = text;
                      _scheduleMessageCommit();
                    },
                    onSubmitted: (_) => _commitMessageDraft(),
                    onEditingComplete: _commitMessageDraft,
                  ),
                ),
              if (selected.effect.type ==
                  MapPlacedElementEffectType.openDialogue)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Builder(
                    builder: (context) {
                      final sortedDialogues = _sortedDialogues();
                      final selectedDialogueId =
                          selected.effect.dialogue?.dialogueId.trim() ?? '';
                      ProjectDialogueEntry? selectedDialogue;
                      for (final entry in sortedDialogues) {
                        if (entry.id == selectedDialogueId) {
                          selectedDialogue = entry;
                          break;
                        }
                      }
                      final selectedDialogueLabel = selectedDialogueId.isEmpty
                          ? 'Aucun dialogue'
                          : selectedDialogue != null
                              ? '${selectedDialogue.name} · ${selectedDialogue.relativePath}'
                              : '$selectedDialogueId (absent du projet)';
                      final currentNode =
                          selected.effect.dialogue?.startNode?.trim() ?? '';
                      final nodeMenuIds = <String>[
                        _nodeNoneMenuId,
                        ..._dialogueNodes,
                      ];
                      if (currentNode.isNotEmpty &&
                          !nodeMenuIds.contains(currentNode)) {
                        nodeMenuIds.add(currentNode);
                      }
                      final selectedNodeMenu =
                          currentNode.isEmpty ? _nodeNoneMenuId : currentNode;
                      String nodeLabel(String id) {
                        if (id == _nodeNoneMenuId) {
                          return 'Nœud par défaut';
                        }
                        return id;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () async {
                              final picked = await _showDialoguePicker(
                                context: context,
                                sorted: sortedDialogues,
                                selectedDialogueId: selectedDialogueId,
                              );
                              if (picked == null) {
                                return;
                              }
                              if (picked == _dialogueNoneMenuId) {
                                _updateSelectedDialogue('');
                              } else {
                                _updateSelectedDialogue(picked);
                              }
                              await _reloadDialogueNodesForSelected();
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: EditorChrome.largeIslandSurfaceColor(
                                  context,
                                  tint: EditorChrome.inspectorJoyLilac
                                      .withValues(alpha: 0.08),
                                ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: EditorChrome.inspectorJoyLilac
                                      .withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Script Yarn',
                                          style: TextStyle(
                                            color: secondary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          selectedDialogueLabel,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: label,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.chevron_down,
                                    size: 12,
                                    color: secondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Material(
                            color: Colors.transparent,
                            child: PopupMenuButton<String>(
                              enabled: selectedDialogueId.isNotEmpty,
                              tooltip: 'Choisir un nœud Yarn',
                              padding: EdgeInsets.zero,
                              splashRadius: 20,
                              offset: const Offset(0, 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: EditorChrome.inspectorJoyBlue
                                      .withValues(alpha: 0.35),
                                ),
                              ),
                              color: EditorChrome.islandFillElevated(context),
                              elevation: 3,
                              initialValue: selectedNodeMenu,
                              onSelected: (picked) {
                                if (picked == _nodeNoneMenuId) {
                                  _updateSelectedDialogueNode(null);
                                } else {
                                  _updateSelectedDialogueNode(picked);
                                }
                              },
                              itemBuilder: (menuCtx) => [
                                for (final id in nodeMenuIds)
                                  PopupMenuItem<String>(
                                    value: id,
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 22,
                                          child: id == selectedNodeMenu
                                              ? const Icon(
                                                  CupertinoIcons.checkmark,
                                                  size: 14,
                                                  color: EditorChrome
                                                      .inspectorJoyBlue,
                                                )
                                              : null,
                                        ),
                                        Expanded(
                                          child: Text(
                                            nodeLabel(id),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: id == selectedNodeMenu
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                              color: label,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: EditorChrome.largeIslandSurfaceColor(
                                    context,
                                    tint: EditorChrome.inspectorJoyBlue
                                        .withValues(alpha: 0.08),
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: EditorChrome.inspectorJoyBlue
                                        .withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Nœud Yarn',
                                            style: TextStyle(
                                              color: secondary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            nodeLabel(selectedNodeMenu),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: selectedDialogueId.isEmpty
                                                  ? secondary
                                                  : label,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      CupertinoIcons.chevron_down,
                                      size: 12,
                                      color: secondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (selectedDialogueId.isEmpty)
                            Text(
                              'Choisis un script pour activer la sélection du nœud.',
                              style: TextStyle(
                                color: secondary,
                                fontSize: 10,
                              ),
                            )
                          else if (_dialogueNodesLoading)
                            Text(
                              'Chargement des nœuds Yarn…',
                              style: TextStyle(
                                color: secondary,
                                fontSize: 10,
                              ),
                            )
                          else if (_dialogueNodes.isEmpty)
                            Text(
                              'Aucun nœud détecté dans ce script (ou fichier introuvable).',
                              style: TextStyle(
                                color: secondary,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              if (selected.effect.type ==
                  MapPlacedElementEffectType.setAnimationEnabled)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _CompactSwitchRow(
                    title: 'Animation activée',
                    value: selected.effect.animationEnabled ?? true,
                    onChanged: (next) {
                      _updateSelected(
                        selected.copyWith(
                          effect:
                              selected.effect.copyWith(animationEnabled: next),
                        ),
                      );
                    },
                  ),
                ),
              if (selected.effect.type ==
                  MapPlacedElementEffectType.playAnimationOnce)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Animation 1x: déclenche une lecture unique puis restaure l’animation locale normale.',
                    style: TextStyle(
                      color: secondary,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

String _resolveElementPrimaryTilesetId(ProjectElementEntry entry) {
  final frameTilesetId = entry.frames.primaryFrame.tilesetId.trim();
  if (frameTilesetId.isNotEmpty) {
    return frameTilesetId;
  }
  return entry.tilesetId.trim();
}

```

### `packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart`

```dart
// Éditeur de masques triple couche pour les éléments projet (PokeMap).
// Voir le rapport : reports/POKEMAP_MASKS_OCCLUSION_PLAYER_V2_REPORT.md

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:map_core/map_core.dart';

import '../../application/models/element_collision_truth_summary.dart';
import '../shared/cupertino_editor_widgets.dart';

/// Mode de la surface d’édition : **aperçu** (lecture seule) ou peinture sur
/// un des deux masques métiers (collision vs occlusion).
///
/// Rappel produit :
/// - **Collision** = bloque le déplacement (gameplay).
/// - **Occlusion** = peut recouvrir le joueur au rendu quand il passe « derrière » ;
///   ne bloque pas par lui-même.
enum MaskSurfaceMode {
  /// Sprite + overlays + légende ; pas d’édition.
  preview,

  /// Pinceau / gomme sur [ElementCollisionProfile.collisionMask] (JSON `pixelMask`).
  collisionPaint,

  /// Pinceau / gomme sur [ElementCollisionProfile.occlusionMask].
  occlusionPaint,
}

/// Éditeur **pixel-level** pour les masques d’un [ProjectElementEntry] :
/// visual (alpha), collision, occlusion — avec fond damier, zoom centré, légende.
///
/// ## Compatibilité
/// - Si seul l’ancien champ [ElementCollisionProfile.cells] est rempli, on
///   **dérive** un bitmap collision en remplissant chaque tuile « bloquante ».
/// - À chaque modification, on **ré-écrit** aussi `cells` via
///   [ElementCollisionMaskCodec.cellsFromPixelMask] pour les outils legacy.
///
/// ## Non-objectifs
/// - La grille affichée est un **repère** ; la vérité reste le masque pixel.
class ElementCollisionTripleMaskEditor extends StatefulWidget {
  const ElementCollisionTripleMaskEditor({
    super.key,
    required this.image,
    required this.source,
    required this.tileWidth,
    required this.tileHeight,
    required this.profile,
    required this.draftPadding,
    required this.onProfileChanged,
  });

  final ui.Image image;
  final TilesetSourceRect source;
  final int tileWidth;
  final int tileHeight;
  final ElementCollisionProfile? profile;
  final WarpTriggerPadding draftPadding;
  final ValueChanged<ElementCollisionProfile?> onProfileChanged;

  @override
  State<ElementCollisionTripleMaskEditor> createState() =>
      _ElementCollisionTripleMaskEditorState();
}

class _ElementCollisionTripleMaskEditorState
    extends State<ElementCollisionTripleMaskEditor> {
  MaskSurfaceMode _mode = MaskSurfaceMode.preview;
  bool _showPixelGrid = false;

  late List<bool> _collisionBits;
  late List<bool> _occlusionBits;
  List<bool>? _visualBits;
  bool _loadingVisual = false;

  int get _wPx => math.max(1, widget.source.width * widget.tileWidth);
  int get _hPx => math.max(1, widget.source.height * widget.tileHeight);

  @override
  void initState() {
    super.initState();
    _collisionBits = _initialCollisionBits();
    _occlusionBits = _initialOcclusionBits();
    _scheduleVisualLoad();
  }

  @override
  void didUpdateWidget(covariant ElementCollisionTripleMaskEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile ||
        oldWidget.source != widget.source ||
        oldWidget.tileWidth != widget.tileWidth ||
        oldWidget.tileHeight != widget.tileHeight) {
      setState(() {
        _collisionBits = _initialCollisionBits();
        _occlusionBits = _initialOcclusionBits();
        _visualBits = null;
        _loadingVisual = false;
      });
      _scheduleVisualLoad();
    }
  }

  void _scheduleVisualLoad() {
    final decoded = _decodeMask(widget.profile?.visualMask, _wPx, _hPx);
    if (decoded != null) {
      setState(() {
        _visualBits = decoded;
      });
      return;
    }
    _loadVisualFromImageAlpha();
  }

  /// Construit le masque « visible » depuis l’alpha du PNG si aucun [visualMask]
  /// n’est persisté — cohérent avec l’auto-génération (seuil alpha).
  Future<void> _loadVisualFromImageAlpha() async {
    setState(() {
      _loadingVisual = true;
    });
    final bd =
        await widget.image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (!mounted || bd == null) {
      setState(() {
        _loadingVisual = false;
        _visualBits = List<bool>.filled(_wPx * _hPx, false);
      });
      return;
    }
    final bytes = bd.buffer.asUint8List();
    final srcLeft = widget.source.x * widget.tileWidth;
    final srcTop = widget.source.y * widget.tileHeight;
    final w = _wPx;
    final h = _hPx;
    final imgW = widget.image.width;
    final out = List<bool>.filled(w * h, false);
    const alphaThreshold = 12;
    for (var py = 0; py < h; py++) {
      for (var px = 0; px < w; px++) {
        final ix = srcLeft + px;
        final iy = srcTop + py;
        if (ix < 0 || iy < 0 || ix >= imgW || iy >= widget.image.height) {
          continue;
        }
        final o = (iy * imgW + ix) * 4;
        final a = bytes[o + 3];
        out[py * w + px] = a > alphaThreshold;
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _visualBits = out;
      _loadingVisual = false;
    });
  }

  List<bool>? _decodeMask(ElementCollisionPixelMask? m, int w, int h) {
    if (m == null || m.widthPx != w || m.heightPx != h) {
      return null;
    }
    try {
      return ElementCollisionMaskCodec.decodePackedBits(
        widthPx: w,
        heightPx: h,
        dataBase64: m.dataBase64,
      );
    } catch (_) {
      return null;
    }
  }

  List<bool> _initialCollisionBits() {
    final decoded = _decodeMask(widget.profile?.collisionMask, _wPx, _hPx);
    if (decoded != null) {
      return decoded;
    }
    // Legacy : cellules → remplissage tuile par tuile.
    final out = List<bool>.filled(_wPx * _hPx, false);
    final cells = widget.profile?.cells ?? const <GridPos>[];
    for (final c in cells) {
      if (c.x < 0 ||
          c.y < 0 ||
          c.x >= widget.source.width ||
          c.y >= widget.source.height) {
        continue;
      }
      for (var ly = 0; ly < widget.tileHeight; ly++) {
        for (var lx = 0; lx < widget.tileWidth; lx++) {
          final px = c.x * widget.tileWidth + lx;
          final py = c.y * widget.tileHeight + ly;
          if (px < _wPx && py < _hPx) {
            out[py * _wPx + px] = true;
          }
        }
      }
    }
    return out;
  }

  List<bool> _initialOcclusionBits() {
    final decoded = _decodeMask(widget.profile?.occlusionMask, _wPx, _hPx);
    if (decoded != null) {
      return decoded;
    }
    return List<bool>.filled(_wPx * _hPx, false);
  }

  ElementCollisionPixelMask _maskFromBits(List<bool> bits) {
    return ElementCollisionPixelMask(
      widthPx: _wPx,
      heightPx: _hPx,
      encoding: ElementCollisionMaskEncoding.packedBitsV1,
      dataBase64: ElementCollisionMaskCodec.encodePackedBits(
        widthPx: _wPx,
        heightPx: _hPx,
        solidPixels: bits,
      ),
    );
  }

  void _emitProfile() {
    final collisionMask = _maskFromBits(_collisionBits);
    final occlusionMask = _maskFromBits(_occlusionBits);
    ElementCollisionPixelMask? visualMask;
    if (_visualBits != null && _visualBits!.length == _wPx * _hPx) {
      visualMask = _maskFromBits(_visualBits!);
    }
    final derivedCells = ElementCollisionMaskCodec.cellsFromPixelMask(
      mask: collisionMask,
      tileWidth: widget.tileWidth,
      tileHeight: widget.tileHeight,
      sourceWidthInTiles: widget.source.width,
      sourceHeightInTiles: widget.source.height,
    );
    widget.onProfileChanged(
      ElementCollisionProfile(
        source: ElementCollisionProfileSource.manual,
        padding: widget.profile?.padding ?? widget.draftPadding,
        visualMask: visualMask ?? widget.profile?.visualMask,
        collisionMask: collisionMask,
        occlusionMask: occlusionMask,
        cells: derivedCells,
      ),
    );
  }

  void _applyStroke(Offset local, Size boxSize, double boxHeight,
      {required bool erase}) {
    if (_mode == MaskSurfaceMode.preview) {
      return;
    }
    final targetRect = fitCollisionPreviewRect(
      size: Size(boxSize.width, boxHeight),
      source: widget.source,
      tileWidth: widget.tileWidth,
      tileHeight: widget.tileHeight,
    );
    if (!targetRect.contains(local)) {
      return;
    }
    final lx = local.dx - targetRect.left;
    final ly = local.dy - targetRect.top;
    final px = (lx / targetRect.width * _wPx).floor().clamp(0, _wPx - 1);
    final py = (ly / targetRect.height * _hPx).floor().clamp(0, _hPx - 1);
    final idx = py * _wPx + px;
    final next = _mode == MaskSurfaceMode.collisionPaint
        ? _collisionBits
        : _occlusionBits;
    next[idx] = !erase;
    setState(() {});
    _emitProfile();
  }

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);
    final padding = widget.profile?.padding ?? widget.draftPadding;
    final truthSummary = summarizeElementCollisionTruth(widget.profile);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: Colors.white.withValues(alpha: 0.015),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Masques pixel (visuel / collision / occlusion)',
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${truthSummary.title}. ${truthSummary.description} ${truthSummary.detail}',
            style: TextStyle(color: secondary, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            'Masque collision : bloque le déplacement du joueur. '
            'Masque occlusion : rendu devant/derrière, ne bloque pas. '
            'Masque visuel : aide d’analyse / aperçu, ne bloque pas.',
            style: TextStyle(color: secondary, fontSize: 10),
          ),
          const SizedBox(height: 8),
          CupertinoSlidingSegmentedControl<int>(
            groupValue: _mode.index,
            children: const {
              0: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: Text('Aperçu', style: TextStyle(fontSize: 11)),
              ),
              1: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: Text('Collision', style: TextStyle(fontSize: 11)),
              ),
              2: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: Text('Occlusion', style: TextStyle(fontSize: 11)),
              ),
            },
            onValueChanged: (int? v) {
              if (v != null) {
                setState(() => _mode = MaskSurfaceMode.values[v]);
              }
            },
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              CupertinoSwitch(
                value: _showPixelGrid,
                onChanged: (v) => setState(() => _showPixelGrid = v),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Grille pixel (aide visuelle seulement)',
                  style: TextStyle(color: secondary, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Padding px: T${padding.top} R${padding.right} B${padding.bottom} L${padding.left} · '
            'cadre cyan = zone analysée par l’auto-génération',
            style: TextStyle(color: secondary, fontSize: 10),
          ),
          if (_loadingVisual)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Lecture du masque visuel depuis l’image…',
                style: TextStyle(color: secondary, fontSize: 10),
              ),
            ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              final boxHeight = math
                  .min(240, constraints.maxWidth * 0.72)
                  .toDouble()
                  .clamp(140.0, 260.0);
              return Listener(
                onPointerDown: (e) {
                  _applyStroke(
                    e.localPosition,
                    constraints.biggest,
                    boxHeight,
                    erase: false,
                  );
                },
                onPointerMove: (e) {
                  if (_mode == MaskSurfaceMode.preview) {
                    return;
                  }
                  // Bouton principal = peindre, secondaire = effacer (style tablette).
                  final erase = e.buttons == 2;
                  _applyStroke(
                    e.localPosition,
                    constraints.biggest,
                    boxHeight,
                    erase: erase,
                  );
                },
                child: SizedBox(
                  height: boxHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: CupertinoColors.separator.resolveFrom(context),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: CustomPaint(
                        painter: _TripleMaskPixelPainter(
                          image: widget.image,
                          source: widget.source,
                          tileWidth: widget.tileWidth,
                          tileHeight: widget.tileHeight,
                          padding: padding,
                          visualBits: _visualBits,
                          collisionBits: _collisionBits,
                          occlusionBits: _occlusionBits,
                          mode: _mode,
                          showPixelGrid: _showPixelGrid,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _legendRow(
            color: const Color(0xFFB71C1C).withValues(alpha: 0.55),
            border: const Color(0xFFB71C1C),
            text: 'Rouge : collision (bloque)',
            secondary: secondary,
          ),
          const SizedBox(height: 4),
          _legendRow(
            color: const Color(0xFF5E35B1).withValues(alpha: 0.45),
            border: const Color(0xFF4527A0),
            text: 'Violet : occlusion (couverture rendu, ne bloque pas)',
            secondary: secondary,
          ),
          const SizedBox(height: 4),
          _legendRow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
            border: const Color(0xFF1B5E20),
            text: 'Vert : passable (hors collision)',
            secondary: secondary,
          ),
          const SizedBox(height: 4),
          _legendRow(
            color: const Color(0xFF0277BD).withValues(alpha: 0.18),
            border: const Color(0xFF01579B),
            text: 'Bleu léger : matière visuelle (alpha) — repère seulement',
            secondary: secondary,
          ),
          const SizedBox(height: 6),
          Text(
            _mode == MaskSurfaceMode.preview
                ? 'Mode aperçu : édition désactivée.'
                : 'Mode ${_mode == MaskSurfaceMode.collisionPaint ? 'collision' : 'occlusion'} : '
                    'cliquez / tracez pour peindre. Clic droit ou périphérique secondaire = gomme.',
            style: TextStyle(color: secondary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _legendRow({
    required Color color,
    required Color border,
    required String text,
    required Color secondary,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: border, width: 1),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: secondary, fontSize: 10),
          ),
        ),
      ],
    );
  }
}

/// Même géométrie que l’ancien `_fitCollisionPreviewRect` : garde le sprite **centré**
/// et le plus grand possible dans la boîte, **sans** déformer les pixels.
Rect fitCollisionPreviewRect({
  required Size size,
  required TilesetSourceRect source,
  required int tileWidth,
  required int tileHeight,
}) {
  final sourcePixelWidth = source.width * tileWidth.toDouble();
  final sourcePixelHeight = source.height * tileHeight.toDouble();
  if (sourcePixelWidth <= 0 || sourcePixelHeight <= 0) {
    return Rect.fromLTWH(0, 0, size.width, size.height);
  }
  final sourceAspect = sourcePixelWidth / sourcePixelHeight;
  final targetAspect = size.width <= 0 || size.height <= 0
      ? sourceAspect
      : size.width / size.height;
  if (sourceAspect > targetAspect) {
    final height = size.width / sourceAspect;
    final top = (size.height - height) / 2;
    return Rect.fromLTWH(0, top, size.width, height);
  }
  final width = size.height * sourceAspect;
  final left = (size.width - width) / 2;
  return Rect.fromLTWH(left, 0, width, size.height);
}

class _TripleMaskPixelPainter extends CustomPainter {
  _TripleMaskPixelPainter({
    required this.image,
    required this.source,
    required this.tileWidth,
    required this.tileHeight,
    required this.padding,
    required this.visualBits,
    required this.collisionBits,
    required this.occlusionBits,
    required this.mode,
    required this.showPixelGrid,
  });

  final ui.Image image;
  final TilesetSourceRect source;
  final int tileWidth;
  final int tileHeight;
  final WarpTriggerPadding padding;
  final List<bool>? visualBits;
  final List<bool> collisionBits;
  final List<bool> occlusionBits;
  final MaskSurfaceMode mode;
  final bool showPixelGrid;

  @override
  void paint(Canvas canvas, Size size) {
    final wPx = math.max(1, source.width * tileWidth);
    final hPx = math.max(1, source.height * tileHeight);

    final targetRect = fitCollisionPreviewRect(
      size: size,
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
    );

    // --- Fond damier (transparence lisible) ---
    _paintCheckerboard(canvas, targetRect);

    final sourceRect = Rect.fromLTWH(
      source.x * tileWidth.toDouble(),
      source.y * tileHeight.toDouble(),
      source.width * tileWidth.toDouble(),
      source.height * tileHeight.toDouble(),
    );
    if (sourceRect.right <= image.width && sourceRect.bottom <= image.height) {
      final imagePaint = Paint()
        ..isAntiAlias = false
        ..filterQuality = FilterQuality.none;
      canvas.drawImageRect(image, sourceRect, targetRect, imagePaint);
    }

    final scaleX = targetRect.width / wPx;
    final scaleY = targetRect.height / hPx;

    // --- Padding : zone exclue de l’analyse auto (assombrissement) ---
    final leftPad = padding.left * scaleX;
    final rightPad = padding.right * scaleX;
    final topPad = padding.top * scaleY;
    final bottomPad = padding.bottom * scaleY;
    final activeLeft = targetRect.left + leftPad;
    final activeTop = targetRect.top + topPad;
    final activeRight = targetRect.right - rightPad;
    final activeBottom = targetRect.bottom - bottomPad;
    final activeRect = Rect.fromLTRB(
      math.min(activeLeft, activeRight),
      math.min(activeTop, activeBottom),
      math.max(activeLeft, activeRight),
      math.max(activeTop, activeBottom),
    );
    _paintPaddingBands(
        canvas, targetRect, leftPad, rightPad, topPad, bottomPad);

    if (activeRect.width > 0 && activeRect.height > 0) {
      canvas.drawRect(
        activeRect,
        Paint()
          ..color = const Color(0xFF00BCD4).withValues(alpha: 0.72)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    // --- Calque « matière visuelle » (optionnel) ---
    if (visualBits != null && visualBits!.length == wPx * hPx) {
      final vp = Paint()..style = PaintingStyle.fill;
      for (var py = 0; py < hPx; py++) {
        for (var px = 0; px < wPx; px++) {
          if (!visualBits![py * wPx + px]) {
            continue;
          }
          final cell = Rect.fromLTWH(
            targetRect.left + px * scaleX,
            targetRect.top + py * scaleY,
            scaleX,
            scaleY,
          );
          vp.color = const Color(0xFF0277BD).withValues(alpha: 0.12);
          canvas.drawRect(cell, vp);
        }
      }
    }

    // --- Collision : rouge ---
    for (var py = 0; py < hPx; py++) {
      for (var px = 0; px < wPx; px++) {
        final idx = py * wPx + px;
        if (idx >= collisionBits.length || !collisionBits[idx]) {
          continue;
        }
        final cell = Rect.fromLTWH(
          targetRect.left + px * scaleX,
          targetRect.top + py * scaleY,
          scaleX,
          scaleY,
        );
        canvas.drawRect(
          cell,
          Paint()..color = const Color(0xFFC62828).withValues(alpha: 0.38),
        );
        canvas.drawRect(
          cell,
          Paint()
            ..color = const Color(0xFFB71C1C)
            ..style = PaintingStyle.stroke
            ..strokeWidth = mode == MaskSurfaceMode.collisionPaint ? 1.0 : 0.6,
        );
      }
    }

    // --- Occlusion : violet (au-dessus du rouge en alpha combiné) ---
    for (var py = 0; py < hPx; py++) {
      for (var px = 0; px < wPx; px++) {
        final idx = py * wPx + px;
        if (idx >= occlusionBits.length || !occlusionBits[idx]) {
          continue;
        }
        final cell = Rect.fromLTWH(
          targetRect.left + px * scaleX,
          targetRect.top + py * scaleY,
          scaleX,
          scaleY,
        );
        canvas.drawRect(
          cell,
          Paint()..color = const Color(0xFF5E35B1).withValues(alpha: 0.42),
        );
        canvas.drawRect(
          cell,
          Paint()
            ..color = const Color(0xFF4527A0)
            ..style = PaintingStyle.stroke
            ..strokeWidth = mode == MaskSurfaceMode.occlusionPaint ? 1.0 : 0.55,
        );
      }
    }

    // --- Grille optionnelle (1 px logique) ---
    if (showPixelGrid) {
      final grid = Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..strokeWidth = 0.5;
      for (var x = 0; x <= wPx; x += 4) {
        final dx = targetRect.left + x * scaleX;
        canvas.drawLine(
            Offset(dx, targetRect.top), Offset(dx, targetRect.bottom), grid);
      }
      for (var y = 0; y <= hPx; y += 4) {
        final dy = targetRect.top + y * scaleY;
        canvas.drawLine(
            Offset(targetRect.left, dy), Offset(targetRect.right, dy), grid);
      }
    }
  }

  void _paintCheckerboard(Canvas canvas, Rect r) {
    const sq = 10.0;
    const light = Color(0xFFECEFF1);
    const dark = Color(0xFFD0D5D8);
    var row = 0;
    for (var y = r.top; y < r.bottom; y += sq) {
      var col = 0;
      for (var x = r.left; x < r.right; x += sq) {
        final cell = Rect.fromLTWH(
          x,
          y,
          math.min(sq, r.right - x),
          math.min(sq, r.bottom - y),
        );
        final paint = Paint()
          ..color = ((row + col) % 2 == 0) ? light : dark
          ..style = PaintingStyle.fill;
        canvas.drawRect(cell, paint);
        col++;
      }
      row++;
    }
  }

  void _paintPaddingBands(
    Canvas canvas,
    Rect targetRect,
    double leftPad,
    double rightPad,
    double topPad,
    double bottomPad,
  ) {
    final p = Paint()..color = Colors.black.withValues(alpha: 0.22);
    if (leftPad > 0) {
      canvas.drawRect(
        Rect.fromLTWH(
          targetRect.left,
          targetRect.top,
          leftPad,
          targetRect.height,
        ),
        p,
      );
    }
    if (rightPad > 0) {
      canvas.drawRect(
        Rect.fromLTWH(
          targetRect.right - rightPad,
          targetRect.top,
          rightPad,
          targetRect.height,
        ),
        p,
      );
    }
    if (topPad > 0) {
      canvas.drawRect(
        Rect.fromLTWH(
          targetRect.left,
          targetRect.top,
          targetRect.width,
          topPad,
        ),
        p,
      );
    }
    if (bottomPad > 0) {
      canvas.drawRect(
        Rect.fromLTWH(
          targetRect.left,
          targetRect.bottom - bottomPad,
          targetRect.width,
          bottomPad,
        ),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TripleMaskPixelPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.source != source ||
        !_boolListEq(oldDelegate.collisionBits, collisionBits) ||
        !_boolListEq(oldDelegate.occlusionBits, occlusionBits) ||
        !_nullableBoolListEq(oldDelegate.visualBits, visualBits) ||
        oldDelegate.mode != mode ||
        oldDelegate.showPixelGrid != showPixelGrid ||
        oldDelegate.padding != padding;
  }

  static bool _boolListEq(List<bool> a, List<bool> b) {
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

  static bool _nullableBoolListEq(List<bool>? a, List<bool>? b) {
    if (identical(a, b)) {
      return true;
    }
    if (a == null || b == null) {
      return false;
    }
    return _boolListEq(a, b);
  }
}

```

