# TSX Recovery — Stabilize Surface Studio TSX Workspace / Remove Broken Visual Shell

Date: 2026-04-30

## 1. Verdict

Recovery appliqué.

Le workspace TSX a été stabilisé autour du problème runtime constaté :

```text
No Material widget found.
_InkResponseStateWidget widgets require a Material widget ancestor.
```

Le chemin TSX principal ne dépend plus de `InkWell` ni de `ElevatedButton`.

Le picker d'animation TSX s'ouvre maintenant dans un arbre `CupertinoApp` / `CupertinoPageScaffold` sans exception Flutter.

## 2. Audit Initial

Commandes initiales exécutées :

```bash
pwd
git status --short --untracked-files=all
git diff --stat
rg -n "DropdownButton|DropdownMenuItem|ElevatedButton|Material\(|MaterialType|InkWell|InkResponse|ListTile|Scaffold|showDialog|AlertDialog|TextButton|OutlinedButton|FilledButton" packages/map_editor/lib/src/features/surface_studio packages/map_editor/test/surface_studio
rg -n "TiledTsxWorkspace|TiledTsxRoleMappingBuilder|TiledTsxAnimationBrowser|_ReferenceTsxSurfaceBuilder|_PreviewAndSaveColumn|_TsxReferenceActionBar|_saveReferenceSurface|_applyPreparedSuggestions|_runLocalDetection" packages/map_editor/lib/src/features/surface_studio packages/map_editor/test/surface_studio
```

Résultat `pwd` :

```text
/Users/karim/Project/pokemonProject
```

`ctx` :

```text
commande ctx absente dans cet environnement
```

État de départ observé avant le rapport :

```text
 M packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_workspace.dart
 M packages/map_editor/test/surface_studio/tiled_tsx_surface_builder_suggestions_test.dart
```

Ces deux modifications venaient du correctif précédent sur `Appliquer les suggestions`. Le recovery a ensuite réduit ce chemin et supprimé le morceau high-confidence non demandé pour la stabilisation.

## 3. Cause Exacte Du `No Material widget found`

Cause directe :

```text
packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_role_mapping_builder.dart
```

Le picker d'animation utilisait :

```dart
InkWell(...)
```

`InkWell` crée un `_InkResponseStateWidget`, qui exige un ancêtre `Material`.

Dans le shell macOS / Cupertino de Surface Studio, le workspace peut être rendu sous `CupertinoPageScaffold`, sans `Scaffold` / `Material` global autour du picker. Dans ce contexte, ouvrir le picker déclenche le red screen.

Cause secondaire :

```text
packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_workspace.dart
```

Le chemin TSX utilisait plusieurs `ElevatedButton`, qui sont aussi des widgets Material. Ils n'ont pas tous déclenché le red screen montré, mais ils étaient incohérents avec le shell Cupertino/macOS et augmentaient le risque.

## 4. Correction Appliquée

### Picker

Dans `tiled_tsx_role_mapping_builder.dart` :

```diff
- import 'package:flutter/material.dart' show BoxDecoration, CustomPaint, InkWell;
+ import 'package:flutter/cupertino.dart';
```

Et :

```diff
- child: InkWell(
-   onTap: onSelected,
-   borderRadius: BorderRadius.circular(10),
+ child: CupertinoButton(
+   padding: EdgeInsets.zero,
+   minimumSize: Size.zero,
+   borderRadius: BorderRadius.circular(10),
+   onPressed: onSelected,
```

### Boutons TSX

Dans `tiled_tsx_workspace.dart`, suppression de `ElevatedButton` du chemin TSX et ajout d'un bouton local Cupertino :

```dart
class _TsxPrimaryButton extends StatelessWidget {
  const _TsxPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      color: enabled
          ? const Color(0xFF2DD4BF).withValues(alpha: 0.28)
          : EditorChrome.islandFillElevated(context),
      disabledColor: EditorChrome.islandFillElevated(context),
      borderRadius: BorderRadius.circular(10),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: enabled
              ? const Color(0xFFEFFCF9)
              : EditorChrome.subtleLabel(context),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
```

Remplacements réalisés :

```text
Importer un fichier TSX
Confirmer l'import TSX
Empty state Importer un fichier TSX
Action bar Importer un TSX
Enregistrer la surface
```

## 5. Widgets Material Remplacés Ou Encapsulés

Remplacés :

```text
InkWell -> CupertinoButton
ElevatedButton -> _TsxPrimaryButton -> CupertinoButton
```

Conservé et encapsulé localement :

```text
DropdownButton<ProjectTilesetEntry>
DropdownMenuItem<ProjectTilesetEntry>
```

Localisation :

```text
packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_workspace.dart
```

Protection existante :

```dart
Material(
  type: MaterialType.transparency,
  child: DropdownButton<ProjectTilesetEntry>(...),
)
```

Cette encapsulation est locale au choix du tileset image et ne modifie pas l'application globale.

Scan après correction sur le chemin TSX direct :

```text
packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_workspace.dart:7:    show DropdownButton, DropdownMenuItem, Material, MaterialType;
packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_workspace.dart:980:        Material(
packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_workspace.dart:981:          type: MaterialType.transparency,
packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_workspace.dart:982:          child: DropdownButton<ProjectTilesetEntry>(
packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_workspace.dart:988:                DropdownMenuItem<ProjectTilesetEntry>(
```

## 6. Ce Qui Était Visuel / Non Fonctionnel Dans TSX-8

Observations :

```text
- le shell TSX affichait une UI de référence plus avancée que la robustesse réelle ;
- l'ancien browser restait accessible et pouvait donner l'impression d'un double workflow ;
- Appliquer les suggestions avait été élargi temporairement vers les suggestions high-confidence sans acceptation manuelle ;
- le picker contenait encore InkWell, donc il était cassable en runtime Cupertino/macOS.
```

Le recovery ne poursuit pas la refonte. Il stabilise le chemin minimal.

## 7. Ce Qui Est Maintenant Fonctionnel

Chemin stable vérifié :

```text
1. Ouvrir le workspace TSX.
2. Ouvrir le picker d'animation.
3. Assigner Plein(center).
4. Voir la preview/checklist passer en état actif.
5. Enregistrer la surface après clic explicite.
6. Recevoir un ProjectSurfacePreset dans le catalogue de travail.
```

Actions :

```text
Importer TSX : bouton Cupertino branché.
Détection auto : sélectionne un groupe réel et filtre le picker.
Appliquer les suggestions : disabled sans suggestion acceptée ; applique les suggestions acceptées au draft.
Enregistrer la surface : disabled sans isolated ; crée un preset après clic.
```

## 8. Ce Qui A Été Masqué / Désactivé

Pas de nouvelle feature ajoutée.

Le comportement high-confidence non accepté n'a pas été conservé dans ce recovery. L'action principale `Appliquer les suggestions` reste volontairement stricte :

```text
suggestions acceptées uniquement
```

Raison :

```text
la règle recovery impose qu'un bouton principal ne promette pas une action ambigüe ou semi-automatique.
```

## 9. Suppression Du Double Workflow

Le builder principal reste le chemin par défaut.

Le browser complet TSX n'est pas rendu sous le builder au chargement.

Accès secondaire :

```text
Voir toutes les animations
```

Retour :

```text
Retour au builder
```

Test ajouté :

```text
packages/map_editor/test/surface_studio/tiled_tsx_no_double_workflow_test.dart
```

## 10. Tests Ciblés

Commande :

```bash
cd packages/map_editor && flutter test test/surface_studio/tiled_tsx_recovery_material_error_test.dart test/surface_studio/tiled_tsx_workspace_stable_flow_test.dart test/surface_studio/tiled_tsx_no_double_workflow_test.dart test/surface_studio/tiled_tsx_functional_actions_test.dart --no-pub --reporter expanded
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_recovery_material_error_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_recovery_material_error_test.dart: opening the TSX animation picker has no Material ancestor error
00:01 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_workspace_stable_flow_test.dart: TSX workspace opens, assigns center, previews, and enables save
00:01 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_no_double_workflow_test.dart: TSX browser is secondary and not stacked under the builder
00:01 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_functional_actions_test.dart: recovery TSX actions are disabled or functional
00:01 +4: All tests passed!
```

## 11. Régressions

Commande :

```bash
cd packages/map_editor && flutter test test/surface_studio/tiled_tsx_import_ui_test.dart test/surface_studio/tiled_tsx_animation_browser_test.dart test/surface_studio/tiled_tsx_role_mapping_builder_test.dart test/surface_studio/tiled_tsx_surface_preset_builder_test.dart --no-pub --reporter expanded
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_import_ui_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_import_ui_test.dart: TiledTsxWorkspace import UI loads a TSX, shows summary, imports atlas and animations
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_import_ui_test.dart: TiledTsxWorkspace import UI loads a TSX, shows summary, imports atlas and animations
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_import_ui_test.dart: TiledTsxWorkspace import UI loads a TSX, shows summary, imports atlas and animations
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_import_ui_test.dart: TiledTsxWorkspace import UI loads a TSX, shows summary, imports atlas and animations
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_import_ui_test.dart: TiledTsxWorkspace import UI loads a TSX, shows summary, imports atlas and animations
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_import_ui_test.dart: TiledTsxWorkspace import UI loads a TSX, shows summary, imports atlas and animations
00:00 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_import_ui_test.dart: TiledTsxWorkspace import UI loads a TSX, shows summary, imports atlas and animations
00:00 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_import_ui_test.dart: TiledTsxWorkspace import UI loads a TSX, shows summary, imports atlas and animations
00:01 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_import_ui_test.dart: TiledTsxWorkspace import UI loads a TSX, shows summary, imports atlas and animations
00:01 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_role_mapping_builder_test.dart: shows visual role slots and maps roles through a picker
00:01 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_role_mapping_builder_test.dart: shows visual role slots and maps roles through a picker
00:01 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_animation_browser_test.dart: TiledTsxAnimationBrowser widget searches by tile id in the browser UI
00:01 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_animation_browser_test.dart: TiledTsxAnimationBrowser widget searches by tile id in the browser UI
00:01 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_import_ui_test.dart: TiledTsxWorkspace import UI blocks TSX without animations
00:01 +14: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_animation_browser_test.dart: TiledTsxAnimationBrowser widget shows imported TSX frame details for tile 99
00:01 +15: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_import_ui_test.dart: TiledTsxWorkspace import UI reports duplicate atlas id without mutating the catalog
00:01 +16: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_animation_browser_test.dart: TiledTsxSurfaceAnimationPreview steps through explicit ProjectSurfaceAnimation frames
00:01 +17: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_animation_browser_test.dart: TiledTsxSurfaceAnimationPreview lists frames when atlas image bytes are unavailable
00:01 +18: All tests passed!
```

Suite Surface Studio complète :

```bash
cd packages/map_editor && flutter test test/surface_studio --no-pub --reporter expanded
```

Ligne finale exacte :

```text
00:28 +433: All tests passed!
```

## 12. Analyze

Commande :

```bash
cd packages/map_editor && flutter analyze lib/src/features/surface_studio lib/src/features/editor/application/editor_ai_settings.dart
```

Sortie complète :

```text
Analyzing 2 items...
No issues found! (ran in 1.4s)
```

## 13. QA Runtime

Commande :

```bash
cd packages/map_editor && flutter run -d macos
```

Sortie observée :

```text
Launching lib/main.dart on macOS in debug mode...
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
Running with merged UI and platform thread. Experimental.
Syncing files to device macOS...
A Dart VM Service on macOS is available at: http://127.0.0.1:57930/XFuRWRqEpkc=/
The Flutter DevTools debugger and profiler on macOS is available at:
http://127.0.0.1:57930/XFuRWRqEpkc=/devtools/?uri=ws://127.0.0.1:57930/XFuRWRqEpkc=/ws
flutter: FileProjectRepository: Loading project from /Users/karim/Desktop/my_new_project/project.json
Application finished.
```

QA interactive complète non validée dans cette session.

Ce qui est validé :

```text
build macOS OK
lancement macOS OK
chargement projet OK
arrêt contrôlé OK
```

## 14. Non-Objectifs Confirmés

Non réalisés :

```text
pas de nouvelle refonte complète
pas de nouvelle feature produit
pas de PixelLab
pas de MCP
pas de génération d'image
pas de gameplay
pas de MapGameplayZone
pas de modification map_runtime
pas de modification map_gameplay
pas de modification map_battle
pas de sauvegarde disque automatique
pas de mutation directe ProjectManifest
pas de nouveau secret API
pas de commit
```

## 15. Limites Restantes

Limites honnêtes :

```text
- le choix de ProjectTilesetEntry utilise encore DropdownButton, mais encapsulé dans Material transparent local ;
- la QA interactive macOS écran par écran n'a pas été conduite ;
- la preview globale reste une preview de récupération, pas une composition Surface finale parfaite ;
- la détection de groupes reste basique ;
- le fichier non suivi packages/map_editor/generate_project_overview.sh existe déjà dans le worktree et n'a pas été touché.
```

## 16. Git Status Final

État final après ajout du rapport :

```text
 M packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_role_mapping_builder.dart
 M packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_workspace.dart
 M packages/map_editor/test/surface_studio/tiled_tsx_import_ui_test.dart
 M packages/map_editor/test/surface_studio/tiled_tsx_surface_builder_functional_test.dart
 M packages/map_editor/test/surface_studio/tiled_tsx_surface_builder_suggestions_test.dart
 M packages/map_editor/test/surface_studio/tiled_tsx_surface_preview_ui_test.dart
?? packages/map_editor/generate_project_overview.sh
?? packages/map_editor/test/surface_studio/tiled_tsx_functional_actions_test.dart
?? packages/map_editor/test/surface_studio/tiled_tsx_no_double_workflow_test.dart
?? packages/map_editor/test/surface_studio/tiled_tsx_recovery_material_error_test.dart
?? packages/map_editor/test/surface_studio/tiled_tsx_workspace_stable_flow_test.dart
?? reports/surface/surface_studio_tiled_tsx_recovery_stabilization.md
```

Diff stat final attendu :

```text
 .../importers/tiled_tsx_role_mapping_builder.dart  |  7 +--
 .../importers/tiled_tsx_workspace.dart             | 63 ++++++++++++++++------
 .../surface_studio/tiled_tsx_import_ui_test.dart   | 15 +++++-
 .../tiled_tsx_surface_builder_functional_test.dart | 10 +++-
 ...tiled_tsx_surface_builder_suggestions_test.dart | 10 +++-
 .../tiled_tsx_surface_preview_ui_test.dart         | 16 ++++--
 reports/surface/surface_studio_tiled_tsx_recovery_stabilization.md | nouveau rapport
 4 nouveaux tests recovery sous packages/map_editor/test/surface_studio/
```

