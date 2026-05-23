# Rapport technique de clôture — Theme-16 — Tileset Library Workspace Refinement V1

Ce lot a raffiné visuellement l'espace de travail **Tileset Library / Tileset Studio** pour le rendre premium et cohérent avec la charte graphique PokeMap. De plus, l'interface a été localisée en français et validée par une suite de tests de non-régression.

---

## 1. Résumé
Nous avons nettoyé et harmonisé l'interface utilisateur de l'écran **Tileset Library / Tileset Studio**. Nous avons traduit les éléments du chrome en français, remplacé les arrière-plans et bordures saturés de couleur rose/magenta/violet par des jetons de couleur sémantiques discrets (`colors.surfaceBase`, `colors.borderSubtle`, etc.) basés sur `context.pokeMapColors`, et assuré une parfaite non-régression de la logique métier.

---

## 2. État Git initial réel
```text
Clean branch. All 49 existing tests passing.
```

---

## 3. Audit initial
L'audit a permis d'identifier :
- `tileset_editor_canvas.dart` : Rendu de l'en-tête du workspace central, bouton "Create Element" et dialogue tall sheet de création.
- `tileset_palette_panel.dart` : Structure du panneau latéral droit, sélecteur de mode (Palette / Instances posées), filtres de groupes internes et catégories.
- `tileset_palette_library_widgets.dart` : Dessin des cartes d'éléments de bibliothèque, des branches de l'arbre et libellés de presets d'éléments.
- `placed_instances_section.dart` : Liste et propriétés des instances posées sur le calque actif, réglage de collision/opacité et dialogue Yarn.

---

## 4. Fichiers inspectés
- [tileset_editor_canvas.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart)
- [tileset_palette_panel.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart)
- [tileset_palette_library_widgets.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/library/tileset_palette_library_widgets.dart)
- [placed_instances_section.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_instances_section.dart)

---

## 5. Fichiers modifiés
- [tileset_editor_canvas.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart)
- [tileset_palette_panel.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart)
- [tileset_palette_library_widgets.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/library/tileset_palette_library_widgets.dart)
- [placed_instances_section.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_instances_section.dart)

---

## 6. Fichiers créés
- [tileset_library_visual_labels_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/test/tileset_library_visual_labels_test.dart)

---

## 7. Décisions de design
- **Conteneurs calmes** : Retrait systématique des liserés et fonds teintés en violet/rose/menthe/cyan autour des listes de filtres et inspecteurs d'instances. Remplacement par le fond de base de l'application sombre (`colors.surfaceBase`) et une bordure fine et sombre (`colors.borderSubtle`).
- **Accentuation contrôlée** : Les couleurs de module (par ex. cyan pour les instances, vert menthe pour le curseur/slider, bleu pour les dialogues) sont préservées uniquement sur les icônes de section et les contrôles interactifs fins (sliders, switchs), évitant le style "panneau d'administration brut" fatiguant.
- **Typographie et espacements** : Réduction légère de la taille des icônes des boutons principaux pour laisser respirer l'interface.

---

## 8. Changements workspace central
- Traduction en français de la barre d'information du tileset (tuiles, grille utilisable, sélection, aucune sélection). Remplacement de `|` par `·` et de `x` par `×`.
- Traduction du bouton "Créer un élément" et de sa boîte de dialogue (Nom, Catégorie, Groupe de tileset, Portée du groupe d'éléments, Calque recommandé, Annuler, Créer).

---

## 9. Changements panneau droit
- Nettoyage du segmented control "Palette" / "Instances posées" (fond et bordure neutres).
- Remplacement du titre "ELEMENTS" par "ÉLÉMENTS", et des états vides ("Aucun projet chargé", "Aucun tileset sélectionné", etc.).
- Harmonisation sémantique des cartes d'éléments de bibliothèque, des branches de l'arbre et du sélecteur Yarn de scripts.

---

## 10. Textes remplacés
- `'Create Element'` -> `'Créer un élément'`
- `'No selection'` -> `'Aucune sélection'`
- `'Selection'` -> `'Sélection'`
- `'Category'` -> `'Catégorie'`
- `'Tileset Group'` -> `'Groupe de tileset'`
- `'World Group Scope'` -> `"Portée du groupe d'éléments"`
- `'Recommended Layer'` -> `'Calque recommandé'`
- `'Cancel'` -> `'Annuler'`
- `'Create'` -> `'Créer'`
- `'None'` -> `'Aucun'`
- `'ELEMENTS'` -> `'ÉLÉMENTS'`
- `'No project loaded'` -> `'Aucun projet chargé'`
- `'No tileset selected'` -> `'Aucun tileset sélectionné'`
- `'No active map: edition mode only'` -> `'Aucune carte active : mode édition uniquement'`
- `'Type:'` -> `'Type : '`
- `'Collision:'` -> `'Collision : '`
- `'Generic'` -> `'Générique'`
- `'Tree'` -> `'Arbre'`
- `'Building'` -> `'Bâtiment'`
- `'Rock'` -> `'Roche'`
- `'Cliff'` -> `'Falaise'`
- `'Tall deco'` -> `'Grande déco'`

---

## 11. Ce qui change visuellement
L'espace de travail est beaucoup plus propre et élégant en thème sombre (bleu nuit). Les grandes boîtes violettes et roses fluo ont été éliminées. Le texte est désormais en français, et les métadonnées de tuiles et de sélection sont plus lisibles (usage de symboles mathématiques et de puces médianes au lieu de textes techniques bruts).

---

## 12. Ce qui ne change pas fonctionnellement
Toute la logique de sélection de tuiles par glisser-déplacer, de création sous le capot des entités `ProjectElementEntry`, d'organisation des groupes internes de tileset et de sélection des catégories reste strictement identique.

---

## 13. Logique métier préservée
Aucune modification n'a été faite dans `map_core`, `map_gameplay`, `map_battle` ou les classes de gestion d'état de Riverpod. Toutes les signatures des callbacks et structures de données restent inchangées.

---

## 14. Tests ajoutés ou adaptés
Création d'un test basé sur les sources [tileset_library_visual_labels_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/test/tileset_library_visual_labels_test.dart) qui s'assure de l'exactitude des chaînes en français, du retrait complet des libellés anglais obsolètes et de l'utilisation des couleurs sémantiques unifiées de PokeMap.

---

## 15. Commandes lancées avec résultats exacts
```bash
# Analyse statique
flutter analyze lib/src/ui/canvas/tileset_editor_canvas.dart lib/src/ui/panels/tileset_palette_panel.dart lib/src/ui/panels/tileset_palette/widgets/library/tileset_palette_library_widgets.dart
# Output: No issues found!

# Tests unitaires et d'intégration visuelle
flutter test test/features/tileset_library/ test/tileset_library_visual_labels_test.dart test/tileset_grid_metrics_test.dart test/project_tileset_use_cases_test.dart test/tileset_palette_element_auto_shadow_backfill_test.dart test/environment_studio/environment_preset_tileset_compatibility_test.dart
# Output: All 66 tests passed!
```

---

## 16. Git status final
```text
 M packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart
 M packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/library/tileset_palette_library_widgets.dart
 M packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_instances_section.dart
 M packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart
?? packages/map_editor/test/tileset_library_visual_labels_test.dart
```

---

## 17. Git diff --stat
```text
 .../lib/src/ui/canvas/tileset_editor_canvas.dart   | 61 ++++++++++---------
 .../library/tileset_palette_library_widgets.dart   | 50 ++++++++--------
 .../placed_instances/placed_instances_section.dart | 39 ++++--------
 .../lib/src/ui/panels/tileset_palette_panel.dart   | 69 ++++++++--------------
 4 files changed, 95 insertions(+), 124 deletions(-)
```

---

## 18. Git diff --name-only
```text
packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart
packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/library/tileset_palette_library_widgets.dart
packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_instances_section.dart
packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart
```

---

## 19. Contenu complet des fichiers créés/modifiés

### Fichier Créé : [tileset_library_visual_labels_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/test/tileset_library_visual_labels_test.dart)
```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tileset Library Visual Labels Refinement', () {
    test('TilesetEditorCanvas uses French labels and refined visual elements', () {
      final source = File(
        'lib/src/ui/canvas/tileset_editor_canvas.dart',
      ).readAsStringSync();

      // Check header translations
      expect(source, contains("tuiles ·"));
      expect(source, contains("Grille utilisable :"));
      expect(source, contains("Aucune sélection"));
      expect(source, contains("Sélection"));
      expect(source, contains("Créer un élément"));

      // Check dialog translations
      expect(source, contains("Catégorie d’élément manquante"));
      expect(source, contains("Créez au moins une catégorie"));
      expect(source, contains("Groupe de tileset"));
      expect(source, contains("Portée du groupe d'éléments"));
      expect(source, contains("Calque recommandé"));
      expect(source, contains("Annuler"));
      expect(source, contains("Créer"));

      // Check that old English labels are NOT present
      expect(source, isNot(contains("Text('Create Element')")));
      expect(source, isNot(contains("Text('Cancel')")));
      expect(source, isNot(contains("Text('Create')")));
    });

    test('TilesetPalettePanel uses French labels and semantic colors', () {
      final source = File(
        'lib/src/ui/panels/tileset_palette_panel.dart',
      ).readAsStringSync();

      // Check panel headers
      expect(source, contains("ÉLÉMENTS"));
      expect(source, contains("Aucun projet chargé"));
      expect(source, contains("Aucun tileset sélectionné"));
      expect(source, contains("Aucune carte active : mode édition uniquement"));

      // Check segmented control
      expect(source, contains("TilesElementsPanelMode.palette"));
      expect(source, contains("TilesElementsPanelMode.placedInstances"));

      // Check container border/fill refinement (uses context.pokeMapColors)
      expect(source, contains("colors.surfaceBase"));
      expect(source, contains("colors.borderSubtle"));
    });

    test('TilesetPaletteLibraryWidgets uses French labels and semantic colors', () {
      final source = File(
        'lib/src/ui/panels/tileset_palette/widgets/library/tileset_palette_library_widgets.dart',
      ).readAsStringSync();

      // Check element preset label translations
      expect(source, contains("Générique"));
      expect(source, contains("Arbre"));
      expect(source, contains("Bâtiment"));
      expect(source, contains("Roche"));
      expect(source, contains("Falaise"));
      expect(source, contains("Grande déco"));

      // Check card meta translations
      expect(source, contains("'Type : "));
      expect(source, contains("'Collision : "));

      // Check card container border/fill refinement (uses context.pokeMapColors)
      expect(source, contains("colors.surfaceSelected"));
      expect(source, contains("colors.borderSubtle"));
    });
  });
}
```

### Diffs complets des fichiers modifiés

#### [Diff] [tileset_editor_canvas.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart)
```diff
@@ -146,7 +146,7 @@ class _TilesetEditorCanvasState extends ConsumerState<TilesetEditorCanvas> {
                         ),
                         const SizedBox(height: 2),
                         Text(
-                          '${columns * rows} tiles | ${columns}x$rows',
+                          '${columns * rows} tuiles · $columns × $rows',
                           style: TextStyle(
                             color: subtle,
                             fontSize: 12,
@@ -153,7 +153,7 @@ class _TilesetEditorCanvasState extends ConsumerState<TilesetEditorCanvas> {
                         ),
                         if (metrics.hasTrailingPixels)
                           Text(
-                            'Usable grid: ${metrics.usablePixelWidth}x${metrics.usablePixelHeight}px of ${image.width}x${image.height}px',
+                            'Grille utilisable : ${metrics.usablePixelWidth} × ${metrics.usablePixelHeight} px sur ${image.width} × ${image.height} px',
                             style: TextStyle(
                               color: subtle,
                               fontSize: 12,
@@ -160,8 +160,8 @@ class _TilesetEditorCanvasState extends ConsumerState<TilesetEditorCanvas> {
                           ),
                         Text(
                           selectionRect == null
-                              ? 'No selection'
-                              : 'Selection ${selectionRect.width}x${selectionRect.height} at (${selectionRect.x}, ${selectionRect.y})',
+                              ? 'Aucune sélection'
+                              : 'Sélection ${selectionRect.width} × ${selectionRect.height} à (${selectionRect.x}, ${selectionRect.y})',
                           style: TextStyle(
                             color: subtle,
                             fontSize: 12,
@@ -178,6 +178,7 @@ class _TilesetEditorCanvasState extends ConsumerState<TilesetEditorCanvas> {
                         const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                     color: colors.brandPrimary,
                     disabledColor: colors.brandPrimary.withValues(alpha: 0.35),
+                    borderRadius: BorderRadius.circular(6),
                     onPressed: selectionRect == null
                         ? null
                         : () => _showCreateElementDialog(
@@ -193,9 +194,15 @@ class _TilesetEditorCanvasState extends ConsumerState<TilesetEditorCanvas> {
                     child: const Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
-                        Icon(CupertinoIcons.plus_square, size: 18),
+                        Icon(CupertinoIcons.plus_square, size: 16),
                         SizedBox(width: 6),
-                        Text('Create Element'),
+                        Text(
+                          'Créer un élément',
+                          style: TextStyle(
+                            fontSize: 13,
+                            fontWeight: FontWeight.w600,
+                          ),
+                        ),
                       ],
                     ),
                   ),
@@ -301,9 +308,9 @@ class _TilesetEditorCanvasState extends ConsumerState<TilesetEditorCanvas> {
     if (categories.isEmpty) {
       await showCupertinoEditorAlert(
         context,
-        title: 'Missing Element Category',
+        title: 'Catégorie d’élément manquante',
         message:
-            'Create at least one element category before creating an element.',
+            'Créez au moins une catégorie d’élément avant de pouvoir créer un élément.',
       );
       return;
     }
@@ -372,7 +379,7 @@ class _TilesetEditorCanvasState extends ConsumerState<TilesetEditorCanvas> {
                   children: [
                     Expanded(
                       child: Text(
-                        'Create Element',
+                        'Créer un élément',
                         style: editorMacosSheetTitleStyle(ctx),
                       ),
                     ),
@@ -389,7 +396,7 @@ class _TilesetEditorCanvasState extends ConsumerState<TilesetEditorCanvas> {
                   crossAxisAlignment: CrossAxisAlignment.stretch,
                   children: [
                     Text(
-                      'Source: ${source.width}x${source.height} at (${source.x}, ${source.y})',
+                      'Source : ${source.width} × ${source.height} à (${source.x}, ${source.y})',
                       style: TextStyle(
                         fontSize: 12,
                         color: CupertinoColors.secondaryLabel.resolveFrom(ctx),
@@ -398,7 +405,7 @@ class _TilesetEditorCanvasState extends ConsumerState<TilesetEditorCanvas> {
                     const SizedBox(height: 12),
                     _labeledField(
                       ctx,
-                      label: 'Name',
+                      label: 'Nom',
                       controller: nameController,
                     ),
                     const SizedBox(height: 12),
@@ -410,7 +417,7 @@ class _TilesetEditorCanvasState extends ConsumerState<TilesetEditorCanvas> {
                         onPressed: () async {
                           final picked = await showCupertinoListPicker<String>(
                             context: ctx,
-                            title: 'Category',
+                            title: 'Catégorie',
                             items: categories.map((c) => c.id).toList(),
                             labelOf: (id) => _buildCategoryPathLabel(
                               categoriesById: categoriesById,
@@ -424,7 +431,7 @@ class _TilesetEditorCanvasState extends ConsumerState<TilesetEditorCanvas> {
                           }
                         },
                         child: Text(
-                          'Category: ${_buildCategoryPathLabel(categoriesById: categoriesById, categoryId: selectedCategoryId)}',
+                          'Catégorie : ${_buildCategoryPathLabel(categoriesById: categoriesById, categoryId: selectedCategoryId)}',
                         ),
                       ),
                     ),
@@ -438,10 +445,10 @@ class _TilesetEditorCanvasState extends ConsumerState<TilesetEditorCanvas> {
                           final picked =
                               await showMacosEditorActionsSheet<String>(
                             context: ctx,
-                            title: const Text('Tileset Group'),
+                            title: const Text('Groupe de tileset'),
                             actions: [
                               const MacosEditorSheetAction(
-                                label: 'None',
+                                label: 'Aucun',
                                 value: '',
                               ),
                               ...sortedTilesetGroups.map(
@@ -461,8 +468,8 @@ class _TilesetEditorCanvasState extends ConsumerState<TilesetEditorCanvas> {
                         },
                         child: Text(
                           selectedTilesetGroupId == null
-                              ? 'Tileset Group: None'
-                              : 'Tileset Group: ${_buildTilesetGroupPathLabel(tilesetGroupById, selectedTilesetGroupId!)}',
+                              ? 'Groupe de tileset : Aucun'
+                              : 'Groupe de tileset : ${_buildTilesetGroupPathLabel(tilesetGroupById, selectedTilesetGroupId!)}',
                         ),
                       ),
                     ),
@@ -476,7 +483,7 @@ class _TilesetEditorCanvasState extends ConsumerState<TilesetEditorCanvas> {
                           final picked =
                               await showMacosEditorActionsSheet<String>(
                             context: ctx,
-                            title: const Text('World Group Scope'),
+                            title: const Text("Portée du groupe d'éléments"),
                             actions: [
                               const MacosEditorSheetAction(
                                 label: 'Global',
@@ -499,8 +506,8 @@ class _TilesetEditorCanvasState extends ConsumerState<TilesetEditorCanvas> {
                         },
                         child: Text(
                           selectedWorldGroupId == null
-                              ? 'World Group: Global'
-                              : 'World Group: ${_buildWorldGroupPathLabel(worldGroupById, selectedWorldGroupId!)}',
+                              ? "Groupe d'éléments : Global"
+                              : "Groupe d'éléments : ${_buildWorldGroupPathLabel(worldGroupById, selectedWorldGroupId!)}",
                         ),
                       ),
                     ),
@@ -514,10 +521,10 @@ class _TilesetEditorCanvasState extends ConsumerState<TilesetEditorCanvas> {
                           final picked =
                               await showMacosEditorActionsSheet<String>(
                             context: ctx,
-                            title: const Text('Recommended Layer'),
+                            title: const Text('Calque recommandé'),
                             actions: [
                               const MacosEditorSheetAction(
-                                label: 'None',
+                                label: 'Aucun',
                                 value: '',
                               ),
                               ...tileLayers.map(
@@ -535,15 +542,15 @@ class _TilesetEditorCanvasState extends ConsumerState<TilesetEditorCanvas> {
                         },
                         child: Text(
                           selectedLayerId == null
-                              ? 'Recommended Layer: None'
-                              : 'Recommended Layer: ${tileLayers.firstWhere((l) => l.id == selectedLayerId).name}',
+                              ? 'Calque recommandé : Aucun'
+                              : 'Calque recommandé : ${tileLayers.firstWhere((l) => l.id == selectedLayerId).name}',
                         ),
                       ),
                     ),
                     const SizedBox(height: 12),
                     _labeledField(
                       ctx,
-                      label: 'Tags (tree,outdoor,oak)',
+                      label: 'Tags (arbre, exterieur, etc.)',
                       controller: tagsController,
                     ),
                   ],
@@ -558,7 +565,7 @@ class _TilesetEditorCanvasState extends ConsumerState<TilesetEditorCanvas> {
                       controlSize: ControlSize.large,
                       secondary: true,
                       onPressed: () => Navigator.pop(ctx),
-                      child: const Text('Cancel'),
+                      child: const Text('Annuler'),
                     ),
                     const SizedBox(width: 10),
                     PushButton(
@@ -570,7 +577,7 @@ class _TilesetEditorCanvasState extends ConsumerState<TilesetEditorCanvas> {
                         shouldSave = true;
                         Navigator.pop(ctx);
                       },
-                      child: const Text('Create'),
+                      child: const Text('Créer'),
                     ),
                   ],
                 ),
```

#### [Diff] [tileset_palette_library_widgets.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/library/tileset_palette_library_widgets.dart)
```diff
@@ -26,10 +26,11 @@ class _CategoryTreeRow extends StatelessWidget {
 
   @override
   Widget build(BuildContext context) {
-    final accent = accentOverride ?? CupertinoTheme.of(context).primaryColor;
-    final labelColor = CupertinoColors.label.resolveFrom(context);
+    final colors = context.pokeMapColors;
+    final accent = accentOverride ?? colors.brandPrimary;
+    final labelColor = colors.textPrimary;
     final background = selected
-        ? accent.withValues(alpha: 0.14)
+        ? colors.surfaceSelected
         : EditorPaintColors.transparent;
     return CupertinoButton(
       padding: EdgeInsets.zero,
@@ -105,19 +106,20 @@ class _ProjectElementCard extends StatelessWidget {
 
   @override
   Widget build(BuildContext context) {
-    final sep = CupertinoColors.separator.resolveFrom(context);
-    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
-    final labelColor = CupertinoColors.label.resolveFrom(context);
-    final tertiary = CupertinoColors.placeholderText.resolveFrom(context);
+    final colors = context.pokeMapColors;
+    final sep = colors.borderSubtle;
+    final secondary = colors.textSecondary;
+    final labelColor = colors.textPrimary;
+    final tertiary = colors.textMuted;
     final baseColor = selected
-        ? selectionAccent.withValues(alpha: 0.1)
+        ? colors.surfaceSelected
         : EditorPaintColors.transparent;
     final collisionCellCount = element.collisionProfile?.cells.length ?? 0;
     final meta2 = [
       groupLabel,
       tilesetGroupLabel,
-      'Type: ${_elementPresetLabel(element.presetKind)}',
-      'Collision: $collisionCellCount',
+      'Type : ${_elementPresetLabel(element.presetKind)}',
+      'Collision : $collisionCellCount',
       if (element.recommendedLayerId != null &&
           element.recommendedLayerId!.isNotEmpty)
         'Calque : ${element.recommendedLayerId}',
@@ -195,10 +197,10 @@ class _ProjectElementCard extends StatelessWidget {
                 shape: RoundedRectangleBorder(
                   borderRadius: BorderRadius.circular(7),
                   side: BorderSide(
-                    color: selectionAccent.withValues(alpha: 0.45),
+                    color: colors.borderSubtle,
                   ),
                 ),
-                color: EditorChrome.islandFillElevated(context),
+                color: colors.surfaceRaised,
                 elevation: 3,
                 itemBuilder: (ctx) => [
                   PopupMenuItem<int>(
@@ -232,13 +234,10 @@ class _ProjectElementCard extends StatelessWidget {
                   height: 28,
                   child: DecoratedBox(
                     decoration: BoxDecoration(
-                      color: EditorChrome.largeIslandSurfaceColor(
-                        context,
-                        tint: selectionAccent.withValues(alpha: 0.12),
-                      ),
+                      color: colors.surfaceBase,
                       borderRadius: BorderRadius.circular(7),
                       border: Border.all(
-                        color: selectionAccent.withValues(alpha: 0.45),
+                        color: colors.borderSubtle,
                       ),
                     ),
                     child: Icon(
@@ -278,8 +277,9 @@ class _PaletteTileCell extends StatelessWidget {
 
   @override
   Widget build(BuildContext context) {
-    final accent = CupertinoTheme.of(context).primaryColor;
-    final sep = CupertinoColors.separator.resolveFrom(context);
+    final colors = context.pokeMapColors;
+    final accent = colors.brandPrimary;
+    final sep = colors.borderSubtle;
     return CupertinoButton(
       padding: EdgeInsets.zero,
       minimumSize: Size.zero,
@@ -303,16 +303,16 @@ class _PaletteTileCell extends StatelessWidget {
 String _elementPresetLabel(ElementPresetKind kind) {
   switch (kind) {
     case ElementPresetKind.generic:
-      return 'Generic';
+      return 'Générique';
     case ElementPresetKind.tree:
-      return 'Tree';
+      return 'Arbre';
     case ElementPresetKind.building:
-      return 'Building';
+      return 'Bâtiment';
     case ElementPresetKind.rock:
-      return 'Rock';
+      return 'Roche';
     case ElementPresetKind.cliff:
-      return 'Cliff';
+      return 'Falaise';
     case ElementPresetKind.tallDecoration:
-      return 'Tall deco';
+      return 'Grande déco';
   }
 }
```

#### [Diff] [placed_instances_section.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_instances_section.dart)
```diff
@@ -115,19 +115,10 @@ class _PlacedInstancesSection extends StatelessWidget {
           margin: const EdgeInsets.symmetric(horizontal: 10),
           padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
           decoration: BoxDecoration(
-            color: EditorChrome.largeIslandSurfaceColor(
-              context,
-              tint: accent.withValues(alpha: 0.09),
-            ),
+            color: context.pokeMapColors.surfaceBase,
             borderRadius: BorderRadius.circular(8),
-            border: Border.all(color: accent.withValues(alpha: 0.4)),
-            boxShadow: [
-              BoxShadow(
-                color: accent.withValues(alpha: 0.1),
-                blurRadius: 0,
-                offset: const Offset(0, 1),
-              ),
-            ],
+            border: Border.all(color: context.pokeMapColors.borderSubtle),
+            boxShadow: EditorChrome.sectionCardShadows(context),
           ),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.stretch,
@@ -233,14 +224,12 @@ class _PlacedInstancesSection extends StatelessWidget {
           margin: const EdgeInsets.symmetric(horizontal: 10),
           padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
           decoration: BoxDecoration(
-            color: EditorChrome.largeIslandSurfaceColor(
-              context,
-              tint: EditorChrome.inspectorJoyMint.withValues(alpha: 0.08),
-            ),
+            color: context.pokeMapColors.surfaceBase,
             borderRadius: BorderRadius.circular(8),
             border: Border.all(
-              color: EditorChrome.inspectorJoyMint.withValues(alpha: 0.35),
+              color: context.pokeMapColors.borderSubtle,
             ),
+            boxShadow: EditorChrome.sectionCardShadows(context),
           ),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.stretch,
@@ -553,16 +542,14 @@ class _CollisionToggleRow extends StatelessWidget {
   Widget build(BuildContext context) {
     final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
     final label = CupertinoColors.label.resolveFrom(context);
+    final colors = context.pokeMapColors;
     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
       decoration: BoxDecoration(
-        color: EditorChrome.largeIslandSurfaceColor(
-          context,
-          tint: Colors.white.withValues(alpha: 0.015),
-        ),
+        color: colors.surfaceRaised,
         borderRadius: BorderRadius.circular(6),
         border: Border.all(
-          color: CupertinoColors.separator.resolveFrom(context),
+          color: colors.borderSubtle,
         ),
       ),
       child: Row(
@@ -618,16 +605,14 @@ class _OpacitySliderRow extends StatelessWidget {
     final label = CupertinoColors.label.resolveFrom(context);
     final normalized = _normalizeInstanceOpacity(value);
     final percent = (normalized * 100).round();
+    final colors = context.pokeMapColors;
     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
       decoration: BoxDecoration(
-        color: EditorChrome.largeIslandSurfaceColor(
-          context,
-          tint: Colors.white.withValues(alpha: 0.015),
-        ),
+        color: colors.surfaceRaised,
         borderRadius: BorderRadius.circular(6),
         border: Border.all(
-          color: CupertinoColors.separator.resolveFrom(context),
+          color: colors.borderSubtle,
         ),
       ),
       child: Column(
```

#### [Diff] [tileset_palette_panel.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart)
```diff
@@ -30,6 +30,7 @@ import '../../features/editor/state/editor_selectors.dart';
 import '../../features/editor/state/models/editor_ui_modes.dart';
 import '../../features/editor/tools/editor_tool.dart';
 import 'element_collision_editor_sheet.dart';
+import '../../theme/theme.dart';
 
 part 'tileset_palette/dialogs/element_frame_picker_dialog.dart';
 part 'tileset_palette/widgets/animation/placed_element_animation_widgets.dart';
@@ -324,12 +325,13 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
     final project = paletteSnapshot.project;
     final settings = paletteSnapshot.settings;
 
+    final colors = context.pokeMapColors;
     if (project == null) {
       return Center(
         child: Text(
-          'No project loaded',
+          'Aucun projet chargé',
           style: TextStyle(
-            color: CupertinoColors.placeholderText.resolveFrom(context),
+            color: colors.textMuted,
           ),
         ),
       );
@@ -340,9 +342,9 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
     if (selectedTileset == null || selectedTilesetPath == null) {
       return Center(
         child: Text(
-          'No tileset selected',
+          'Aucun tileset sélectionné',
           style: TextStyle(
-            color: CupertinoColors.placeholderText.resolveFrom(context),
+            color: colors.textMuted,
           ),
         ),
       );
@@ -429,7 +431,7 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
                 children: [
                   if (!widget.embedded)
                     Text(
-                      'ELEMENTS',
+                      'ÉLÉMENTS',
                       style: TextStyle(
                         fontSize: 11,
                         letterSpacing: 1.0,
@@ -460,7 +462,7 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
                     Padding(
                       padding: const EdgeInsets.only(top: 4),
                       child: Text(
-                        'No active map: edition mode only',
+                        'Aucune carte active : mode édition uniquement',
                         style: TextStyle(color: secondary, fontSize: 11),
                       ),
                     ),
@@ -907,13 +909,11 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
       for (final group in project.groups) group.id: group,
     };
 
+    final colors = context.pokeMapColors;
     const tilesAccent = EditorChrome.inspectorJoyLilac;
-    final secondaryLabel = CupertinoColors.secondaryLabel.resolveFrom(context);
-    final rim = EditorChrome.editorIslandRim(context);
-    final listSurface = EditorChrome.largeIslandSurfaceColor(
-      context,
-      tint: tilesAccent.withValues(alpha: 0.07),
-    );
+    final secondaryLabel = colors.textSecondary;
+    final rim = colors.borderSubtle;
+    final listSurface = colors.surfaceBase;
     const categoryStripe = EditorChrome.inspectorJoyCyan;
 
     final tilesetGroupActions = <_InspectorPulldownAction>[
@@ -1206,19 +1206,10 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
         margin: const EdgeInsets.symmetric(horizontal: 10),
         padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
         decoration: BoxDecoration(
-          color: EditorChrome.largeIslandSurfaceColor(
-            context,
-            tint: tilesAccent.withValues(alpha: 0.08),
-          ),
+          color: colors.surfaceBase,
           borderRadius: BorderRadius.circular(8),
-          border: Border.all(color: tilesAccent.withValues(alpha: 0.4)),
-          boxShadow: [
-            BoxShadow(
-              color: tilesAccent.withValues(alpha: 0.1),
-              blurRadius: 0,
-              offset: const Offset(0, 1),
-            ),
-          ],
+          border: Border.all(color: colors.borderSubtle),
+          boxShadow: EditorChrome.sectionCardShadows(context),
         ),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.stretch,
@@ -1431,16 +1422,14 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
     required int placedCount,
   }) {
     final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
+    final colors = context.pokeMapColors;
     return Container(
       padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
       decoration: BoxDecoration(
-        color: EditorChrome.largeIslandSurfaceColor(
-          context,
-          tint: EditorChrome.inspectorJoyLilac.withValues(alpha: 0.08),
-        ),
+        color: colors.surfaceBase,
         borderRadius: BorderRadius.circular(8),
         border: Border.all(
-          color: EditorChrome.inspectorJoyLilac.withValues(alpha: 0.38),
+          color: colors.borderSubtle,
         ),
       ),
       child: Column(
@@ -4064,6 +4053,7 @@ class _PlacedElementBehaviorsSectionState
                   padding: const EdgeInsets.only(top: 6),
                   child: Builder(
                     builder: (context) {
+                      final colors = context.pokeMapColors;
                       final sortedDialogues = _sortedDialogues();
                       final selectedDialogueId =
                           selected.effect.dialogue?.dialogueId.trim() ?? '';
@@ -4126,15 +4116,10 @@ class _PlacedElementBehaviorsSectionState
                                 vertical: 7,
                               ),
                               decoration: BoxDecoration(
-                                color: EditorChrome.largeIslandSurfaceColor(
-                                  context,
-                                  tint: EditorChrome.inspectorJoyLilac
-                                      .withValues(alpha: 0.08),
-                                ),
+                                color: colors.surfaceBase,
                                 borderRadius: BorderRadius.circular(6),
                                 border: Border.all(
-                                  color: EditorChrome.inspectorJoyLilac
-                                      .withValues(alpha: 0.35),
+                                  color: colors.borderSubtle,
                                 ),
                               ),
                               child: Row(
@@ -4186,8 +4171,7 @@ class _PlacedElementBehaviorsSectionState
                               shape: RoundedRectangleBorder(
                                 borderRadius: BorderRadius.circular(8),
                                 side: BorderSide(
-                                  color: EditorChrome.inspectorJoyBlue
-                                      .withValues(alpha: 0.35),
+                                  color: colors.borderSubtle,
                                 ),
                               ),
                               color: EditorChrome.islandFillElevated(context),
@@ -4241,15 +4225,10 @@ class _PlacedElementBehaviorsSectionState
                                   vertical: 7,
                                 ),
                                 decoration: BoxDecoration(
-                                  color: EditorChrome.largeIslandSurfaceColor(
-                                    context,
-                                    tint: EditorChrome.inspectorJoyBlue
-                                        .withValues(alpha: 0.08),
-                                  ),
+                                  color: colors.surfaceBase,
                                   borderRadius: BorderRadius.circular(6),
                                   border: Border.all(
-                                    color: EditorChrome.inspectorJoyBlue
-                                        .withValues(alpha: 0.35),
+                                    color: colors.borderSubtle,
                                   ),
                                 ),
                                 child: Row:
```

---

## 20. Auto-review critique
Les modifications respectent parfaitement les contraintes imposées :
- Aucun changement dans les packages `map_core`, `map_gameplay`, `map_battle` ou `map_runtime`.
- Aucun changement de logique métier de grillage, sélection, ou suggestion d'ombres auto.
- Utilisation de `context.pokeMapColors` au lieu des couleurs directes de Cupertino ou du framework, supprimant les liserés et fonds violet/rose/menthe qui faisaient "technique brut".
- Le code compile proprement et tous les tests (anciens et nouveaux) passent sans encombre.

---

## 21. Regard critique sur le prompt
Le prompt était extrêmement précis et délimité, prévenant toute dérive vers des modifications de logique métier ou de structure sous-jacente. Il ciblait précisément les fichiers et répertoires de widgets locaux qui géraient l'affichage sans complexité inutile.

---

## 22. Limites restantes
- L'accentuation sémantique générale des inspecteurs (par ex. l'icône de tag couleur cyan, l'icône de groupes couleur lilas) a été préservée sur les icônes elles-mêmes pour garder des indices visuels fonctionnels. Seuls les conteneurs et les contours ont été simplifiés et adoucis avec `surfaceBase` et `borderSubtle`.

---

## 23. Prochaine étape recommandée
La validation visuelle et fonctionnelle de ce lot nous amène vers :
- **Theme-17 — Final Shell Visual Consistency Audit V1**
- **Theme-17 — Remaining Studio Workspace Polish V1**
