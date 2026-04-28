# Lot 88-quinquies — Surface Mapping Full Visual Atlas Picker V0

## 1. Résumé exécutif honnête

Lot 88-quinquies implémente le vrai saut demandé : l’édition du mapping Surface ne dépend plus d’une galerie symbolique comme expérience principale quand les données nominales sont disponibles. Depuis le panneau “Surfaces prêtes à peindre”, le bouton “Modifier le mapping visuel” ouvre maintenant une sheet large `Surface Mapping Editor`. Dans cette sheet, l’utilisateur choisit un slot visuel, puis clique directement dans l’image atlas réelle avec une grille superposée. Le clic de colonne assigne immédiatement l’animation correspondante au rôle actif, met à jour le catalogue de travail local, déclenche l’état dirty et conserve le save flow existant.

Le fallback symbolique existe encore, mais uniquement quand l’image réelle ne peut pas être chargée ou résolue. C’est volontaire : une surface reste éditable en mode dégradé, tout en affichant clairement “Image atlas réelle indisponible”. Le cas nominal affiche une vraie `ui.Image`, pas des carrés “Col 0”.

Le lot est validable fonctionnellement : tests Surface Studio, Surface Painter et sélection de map passent, et l’analyse ciblée est clean. La limite honnête : la sélection est V0 colonne entière pour atlas vertical, pas encore clic cellule avancé ni gestion multi-atlas complète ; si plusieurs atlas sont référencés, l’UI choisit le premier atlas utilisé et le signale.

## 2. Audit initial

### Gate 0 — Status initial avant modification

Commande exécutée avant toute modification depuis `/Users/karim/Project/pokemonProject` :

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_paintable_surfaces_panel.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_role_mapping_editor.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_preview.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_preview_test.dart
?? reports/surface/surface_engine_lot_88_quater_surface_mapping_editor_like_path_mapping.md
?? reports/surface/surface_engine_lot_88_ter_surface_studio_visual_role_mapping_layout_repair.md

git diff --stat
 .../surface_studio_paintable_surfaces_panel.dart   |    2 +-
 .../surface_studio_role_mapping_editor.dart        | 1465 ++++++++++++++++++--
 ...ce_studio_vertical_atlas_animation_preview.dart |   52 +-
 .../surface_studio/surface_studio_panel_test.dart  |   18 +-
 .../surface_studio_role_mapping_editor_test.dart   |  166 ++-
 ...udio_vertical_atlas_animation_preview_test.dart |   50 +-
 6 files changed, 1603 insertions(+), 150 deletions(-)

git log --oneline -n 10
d5561df7 feat(map_editor): edit surface role animation mapping
935a0036 feat(map_editor): animate surface editor previews
fe03b827 feat(map_editor): render surface atlas tile previews
5814f6e9 feat(map): add surface role resolver preview
f8859a06 feat(map_editor): improve surface painter and studio workflow ux
b20287da feat(map_editor): redesign surface studio workflow
f3a37532 feat(map_editor): add surface painter entry flow
d2a3ca2e feat(map): add surface layer model and placement ops
6cc7fafa docs: update agent workflow guidance
9645a04b docs(surface): decide surface placement model
```

### Commandes d’audit obligatoires

```bash
rg -n "Path Mapping|PathMapping|terrain_mapping_workspace|TerrainMappingWorkspace|tileset|tile picker|variant|slot|Mapping Editor" packages/map_editor/lib packages/map_editor/test
rg -n "SurfaceStudioRoleMapping|RoleMapping|surface_role_mapping|SurfaceStudioPaintableSurfacesPanel|SurfaceStudioPanel|projectRootPath|resolvedImagePath|Image.memory|decodeImage|ui.Image|atlas" packages/map_editor/lib/src/features/surface_studio packages/map_editor/test/surface_studio
rg -n "ProjectTilesetEntry|relativePath|projectRootPath|tilesetId|image cache|ImageCache|decodeImage|ui.Image" packages/map_editor/lib packages/map_core/lib
```

### Architecture constatée

- Le Path Mapping Editor est dans `packages/map_editor/lib/src/ui/panels/terrain_editor/dialogs/terrain_preset_dialogs.dart`, autour de `_showPathMappingWorkspaceDialog(...)`.
- Il ouvre une `MacosSheet` large d’environ `980 × 660`, charge une vraie `ui.Image` via `_TerrainTilesetImageCache.load(path)`, affiche le schéma des variantes à gauche et peint le tileset réel à droite avec `_PathTilesetMappingPainter`.
- Le clic dans le tileset est converti en cellule par `_gridFromPickerLocal(...)`, puis la variante active reçoit immédiatement la frame choisie.
- Surface Studio avait déjà accès à `projectRootPath` et `projectTilesets` dans `SurfaceStudioPanel` et `SurfaceStudioAtlasAuthoringPrep`.
- Le mapping Surface actuel, dans `surface_studio_role_mapping_editor.dart`, connaissait déjà la correspondance animation -> première frame -> atlasId/column/row, mais rendait surtout une galerie symbolique avec `C0`, `Frame 1`, etc.

### Problèmes observés

- Le 88-quater restait insuffisant parce que la galerie de colonnes ne dessinait pas l’atlas réel.
- Le mapping était encore compressible dans le panneau droit via `mappingEditor`, donc pas au niveau d’un vrai workspace Path Mapping.
- La sélection existait déjà par slot puis colonne, mais la colonne était abstraite, pas un clic dans l’image source.
- Le fallback était utile, mais il était devenu l’expérience principale dans le cas nominal.

## 3. Comparaison avec Path Mapping Editor

Path Mapping Editor :

- ouvre un espace large dédié ;
- affiche un schéma de slots à gauche ;
- affiche le tileset réel à droite ;
- peint une grille ;
- convertit un clic image en coordonnées de grille ;
- met à jour le mapping immédiatement.

Surface Mapping après ce lot :

- ouvre une sheet large `Surface Mapping Editor` ;
- garde le schéma Surface 3×3 + slots avancés ;
- résout l’atlas réel via preset -> animation -> frame -> atlas -> tileset -> chemin disque ;
- affiche l’image atlas réelle avec grille ;
- convertit un clic horizontal en colonne pour les atlas verticaux ;
- assigne la colonne au rôle actif immédiatement.

Écart assumé : Path Mapping mappe une cellule de tileset. Surface V0 mappe une colonne entière parce que le format vertical Surface encode les variantes/rôles par colonnes et les frames par lignes.

## 4. Pourquoi 88-quater était insuffisant

Le 88-quater améliorait les explications et la sélection par slots, mais gardait une preview symbolique comme zone principale. L’utilisateur voyait encore `Col 0`, `Frame 1` et des pastilles, pas l’image qu’il venait d’importer. Le mapping restait donc indirect : il fallait croire que “Col 1” correspondait à la bonne colonne visuelle.

Ce lot corrige précisément cela : l’image source réelle est maintenant visible et cliquable. La galerie symbolique n’apparaît plus dans le cas nominal avec image chargée.

## 5. Architecture retenue

- `SurfaceStudioRoleMappingEditor` reçoit maintenant `projectRootPath`, `projectTilesets` et un `SurfaceStudioAtlasUiImageLoader` optionnel.
- Le loader par défaut lit le fichier atlas depuis le disque et décode une `ui.Image`. Les tests injectent un fake loader déterministe.
- `_SurfaceAtlasPickerSource` résout l’atlas nominal du preset sans toucher `map_core`.
- `_MappingWorkspace` devient stateful pour charger l’image une fois par chemin et partager l’image chargée entre les slots et la zone atlas.
- `_RealAtlasPicker` remplace la galerie symbolique quand l’image est disponible.
- `_AtlasImageHitArea` rend l’image + grille et transforme le clic en colonne.
- Le fallback `_ColumnGallery` reste disponible uniquement si la vraie image manque.

## 6. Résolution image atlas

Pipeline V0 :

```text
preset
→ variantAnimations.refs
→ animationId
→ ProjectSurfaceAnimation.timeline.frames.first
→ SurfaceAtlasTileRef.atlasId
→ ProjectSurfaceAtlas
→ atlas.tilesetId
→ ProjectTilesetEntry.relativePath
→ projectRootPath + relativePath
→ ui.Image
```

Si plusieurs atlas sont référencés, le V0 affiche le premier atlas utilisé et signale la limite. Si aucun atlas, tileset, root projet ou fichier image ne peut être résolu, l’UI affiche “Image atlas réelle indisponible” et explique le blocage.

## 7. Grille atlas cliquable

La zone `_AtlasImageHitArea` :

- conserve le ratio réel de l’image ;
- peint l’image avec `drawImageRect` et `FilterQuality.none` ;
- superpose une grille selon `atlas.geometry.gridSize` ;
- colore les colonnes assignées, manquantes, doublonnées ou actives ;
- calcule `column = localX / (renderWidth / columns)` ;
- assigne la première animation de catalogue qui correspond à cet atlas + colonne.

## 8. Schéma des slots

Le schéma Surface existant est conservé mais enrichi : quand l’image atlas est disponible et qu’un slot est assigné, le slot affiche un vrai crop de la tuile source via `_SurfaceColumnCropPreview`. Le détail du rôle affiche aussi un crop réel du rôle courant.

Le schéma reste organisé en :

- grille 3×3 : coins, bords, centre/croix ;
- continuités : isolé, horizontal, vertical ;
- jonctions et coins intérieurs.

## 9. Gestion centre multi-variante

Le modèle reste `SurfaceVariantRole -> animationId`. Le centre multi-variante complet n’est pas ajouté dans ce lot. L’UI expose les rôles “Centre / continuités” (`isolated`, `horizontal`, `vertical`, `cross`) comme slots distincts, ce qui est honnête avec le modèle actuel. Les variantes multiples aléatoires ou pondérées restent hors V0.

## 10. Mutation catalogue / dirty state

Le clic atlas appelle le callback existant `onRoleAnimationChanged(role, animationId)`. Dans `SurfaceStudioPanel`, ce callback réutilise `surfaceStudioReplacePresetRoleAnimation(...)`, reconstruit le `SurfaceStudioReadModel`, conserve la sélection du preset et remet `_saveFlowPrepNote` à `null`. Le bandeau dirty existant apparaît ensuite, et le bouton “Sauvegarder le catalogue” reste le même save flow.

Aucune écriture disque n’est effectuée par l’éditeur de mapping.

## 11. Tests lancés

### Tests ciblés nouveaux/ajustés

```bash
cd packages/map_editor && flutter test test/surface_studio/surface_studio_role_mapping_editor_test.dart
```

Résultat :

```text
00:02 +9: All tests passed!
```

```bash
cd packages/map_editor && flutter test test/surface_studio/surface_studio_panel_test.dart --plain-name "88-bis.1"
```

Résultat :

```text
00:02 +1: All tests passed!
```

### Non-régression obligatoire

```bash
cd packages/map_editor && flutter test test/surface_studio
```

Résultat :

```text
00:13 +407: All tests passed!
```

```bash
cd packages/map_editor && flutter test test/surface_painter
```

Résultat :

```text
00:02 +42: All tests passed!
```

```bash
cd packages/map_editor && flutter test test/map_selection_controller_test.dart
```

Résultat :

```text
00:01 +5: All tests passed!
```

### Analyse ciblée

```bash
cd packages/map_editor && flutter analyze lib/src/features/surface_studio/surface_studio_role_mapping_editor.dart lib/src/features/surface_studio/surface_studio_panel.dart lib/src/features/surface_studio/surface_studio_paintable_surfaces_panel.dart test/surface_studio/surface_studio_role_mapping_editor_test.dart test/surface_studio/surface_studio_panel_test.dart
```

Résultat :

```text
No issues found! (ran in 0.9s)
```

### Note sur une commande échouée

Une tentative initiale de lancer deux commandes `flutter test` en parallèle a échoué sur le verrou de démarrage Flutter :

```text
Waiting for another flutter command to release the startup lock...
Unable to delete file or directory at ".../macos/Flutter/ephemeral/Packages/.packages".
```

Ce n’était pas un échec produit ; les commandes ont ensuite été relancées séquentiellement et passent.

## 12. Résultats

- Vrai atlas visible : oui, quand `projectRootPath`, `ProjectTilesetEntry` et image sont disponibles.
- Grille visible : oui.
- Clic atlas : oui, clic colonne V0.
- Slot visuel : oui.
- Dropdown principal : non utilisé.
- Preview symbolique : fallback seulement.
- Dirty state : oui.
- Save flow existant : oui.
- Surface Painter : vert.
- map_core : inchangé.
- map_runtime : inchangé.

## 13. Fichiers créés

- `reports/surface/surface_engine_lot_88_quinquies_surface_mapping_real_atlas_picker.md` : rapport du lot. Exception récursive habituelle : ce rapport ne recopie pas son propre contenu complet dans lui-même.

## 14. Fichiers modifiés

Changements du Lot 88-quinquies :

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_role_mapping_editor.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_paintable_surfaces_panel.dart`
- `packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`

Changements préexistants encore présents au status final :

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_preview.dart`
- `packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_preview_test.dart`
- `reports/surface/surface_engine_lot_88_quater_surface_mapping_editor_like_path_mapping.md`
- `reports/surface/surface_engine_lot_88_ter_surface_studio_visual_role_mapping_layout_repair.md`

## 15. Fichiers supprimés

Aucun fichier supprimé.

## 16. Gate final

Status final attendu après création de ce rapport :

```text
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_paintable_surfaces_panel.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_role_mapping_editor.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_preview.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_preview_test.dart
?? reports/surface/surface_engine_lot_88_quater_surface_mapping_editor_like_path_mapping.md
?? reports/surface/surface_engine_lot_88_ter_surface_studio_visual_role_mapping_layout_repair.md
?? reports/surface/surface_engine_lot_88_quinquies_surface_mapping_real_atlas_picker.md
```

Diff stat final hors fichiers non suivis :

```text
 .../surface_studio_paintable_surfaces_panel.dart   |    8 +-
 .../surface_studio/surface_studio_panel.dart       |   85 +-
 .../surface_studio_role_mapping_editor.dart        | 2231 ++++++++++++++++++--
 ...ce_studio_vertical_atlas_animation_preview.dart |   52 +-
 .../surface_studio/surface_studio_panel_test.dart  |   63 +-
 .../surface_studio_role_mapping_editor_test.dart   |  297 ++-
 ...udio_vertical_atlas_animation_preview_test.dart |   50 +-
 7 files changed, 2604 insertions(+), 182 deletions(-)
```

Fichiers temporaires recherchés :

```bash
find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
```

Résultat : aucune sortie.

`git diff --check` : aucune sortie.

## 17. Périmètre explicitement non touché

- `map_core` inchangé.
- `ProjectManifest` inchangé.
- `surface.dart` inchangé.
- `surface_catalog.dart` inchangé.
- codecs Surface inchangés.
- `map_runtime` inchangé.
- `map_gameplay` inchangé.
- `map_battle` inchangé.
- aucun renderer runtime Surface créé.
- aucun resolver runtime créé.
- aucune animation clock runtime créée.
- aucune migration legacy codée.
- aucun changement JSON.
- Surface Painter non refondu.
- Runner.xcscheme non modifié.

## 18. Limites restantes

- Le V0 mappe une colonne entière, pas une cellule arbitraire. C’est cohérent avec l’atlas vertical Surface actuel, mais moins général qu’un picker de cellule.
- Le multi-atlas est signalé mais pas pleinement édité : l’UI prend le premier atlas utilisé par le preset.
- Les variantes multiples du centre ne sont pas modélisées ; l’UI expose les rôles existants sans prétendre à plus.
- La sheet large est un vrai progrès, mais elle reste à raffiner visuellement si l’on veut un niveau produit équivalent à un outil pro complet.

## 19. Auto-review obligatoire

- Est-ce que l’image atlas réelle est visible ? Oui, dans le cas nominal avec image résolue.
- Est-ce que l’utilisateur peut cliquer dans l’atlas ? Oui.
- Est-ce que l’utilisateur peut sélectionner un slot visuel ? Oui.
- Est-ce que le mapping fonctionne sans dropdown principal ? Oui.
- Est-ce que le résultat ressemble vraiment au Path Mapping Editor ? Oui sur l’architecture UX : sheet large, slot à gauche, atlas réel cliquable à droite. Visuellement ce n’est pas pixel-perfect.
- Est-ce que les previews sont de vrais crops atlas ? Oui pour les slots assignés et le détail du rôle quand l’image est disponible.
- Est-ce que le centre multi-variante est supporté ou seulement explicité ? Seulement explicité via rôles existants ; pas de modèle multi-variante nouveau.
- Est-ce que dirty/save flow fonctionne ? Oui.
- Est-ce que Surface Painter reste vert ? Oui.
- Est-ce que map_core est inchangé ? Oui.
- Est-ce que map_runtime est inchangé ? Oui.
- Est-ce qu’un 88-sexies est nécessaire ? Non pour débloquer le mapping visuel nominal. Un futur lot peut améliorer multi-atlas/cellule/multi-variante, mais ce n’est plus un blocage fondamental.

## 20. Auto-critique

Le lot corrige enfin la faute principale : le mapping ne se cache plus derrière une représentation symbolique. Le choix d’intégrer dans `surface_studio_role_mapping_editor.dart` plutôt que de créer un fichier entièrement nouveau garde le scope borné, mais le fichier devient très gros à cause des ajouts 88-ter/88-quater/88-quinquies cumulés. À moyen terme, il faudrait extraire le painter atlas, le loader et les widgets de slot dans des fichiers dédiés.

Le fallback symbolique reste présent ; c’est nécessaire pour la robustesse, mais il faudra surveiller qu’il ne redevienne pas l’expérience nominale si les projets réels ne passent pas correctement `projectRootPath` / `tilesets`.

## 21. Regard critique sur le prompt

Le prompt est volontairement brutal et utile : il nomme clairement l’échec UX des previews symboliques. Le point discutable est l’exigence “contenu complet de tous les fichiers modifiés” : sur un lot Flutter avec gros tests et fichier déjà très modifié par des lots précédents, cela produit un rapport massif et moins lisible. Pour l’ingénierie quotidienne, un diff complet ciblé ou des liens de fichiers serait plus exploitable.

Le prompt demande aussi de “ressembler vraiment au Path Mapping Editor” tout en interdisant une refonte globale. La solution retenue reprend le pattern structurel Path Mapping sans copier tout le code terrain, ce qui évite un couplage path/surface fragile.

## 22. Contenu complet des fichiers modifiés/créés/supprimés

Les contenus ci-dessous incluent aussi les fichiers modifiés préexistants encore présents au status, afin que l’état de worktree soit auditable. Le rapport lui-même est exclu de cette section pour éviter la récursion infinie.

### `packages/map_editor/lib/src/features/surface_studio/surface_studio_paintable_surfaces_panel.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';

const Color _accent = Color(0xFF2DD4BF);

/// Panneau final du workflow : les surfaces réellement peignables.
///
/// Les presets restent l’unité technique du catalogue, mais l’UI parle ici de
/// surfaces à peindre pour éviter que l’utilisateur confonde atlas, animations
/// et résultat final utilisable dans l’éditeur de map.
class SurfaceStudioPaintableSurfacesPanel extends StatelessWidget {
  const SurfaceStudioPaintableSurfacesPanel({
    super.key,
    required this.readModel,
    this.selectedPresetId,
    this.onCreateSurfacePressed,
    this.onSaveCatalogPressed,
    this.onPresetSelected,
    this.onEditMappingPressed,
  });

  final SurfaceStudioReadModel readModel;
  final String? selectedPresetId;
  final VoidCallback? onCreateSurfacePressed;
  final VoidCallback? onSaveCatalogPressed;
  final ValueChanged<String>? onPresetSelected;
  final ValueChanged<String>? onEditMappingPressed;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final presets = readModel.presets;
    final hasAnimations = readModel.summary.animationCount > 0;
    final hasSurfaces = presets.isNotEmpty;

    return Container(
      key: const ValueKey('surface_studio_paintable_surfaces_panel'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withValues(alpha: 0.35)),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Surfaces prêtes à peindre',
            style: TextStyle(
              color: label,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ces surfaces seront disponibles dans l’éditeur de map pour peindre vos niveaux.',
            style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
          ),
          const SizedBox(height: 12),
          if (!hasSurfaces)
            _EmptyPaintableState(hasAnimations: hasAnimations)
          else
            for (var i = 0; i < presets.length; i++) ...[
              _PaintableSurfaceRow(
                row: presets[i],
                selected: presets[i].id == selectedPresetId,
                onSelect: onPresetSelected == null
                    ? null
                    : () => onPresetSelected!(presets[i].id),
                onEditMapping: onEditMappingPressed == null
                    ? null
                    : () => onEditMappingPressed!(presets[i].id),
              ),
              if (i != presets.length - 1) const SizedBox(height: 8),
            ],
          const SizedBox(height: 12),
          CupertinoButton(
            key: const ValueKey('surface_studio_guidance_create_surface'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            color: _accent.withValues(alpha: 0.72),
            disabledColor: EditorChrome.islandFillElevated(context)
                .withValues(alpha: 0.72),
            onPressed: onCreateSurfacePressed,
            child: const Text('Créer une surface'),
          ),
          if (onCreateSurfacePressed == null) ...[
            const SizedBox(height: 6),
            Text(
              hasAnimations
                  ? 'Utilisez le bloc “Créer une surface à peindre” après avoir généré les animations.'
                  : 'Générez d’abord les animations depuis l’atlas.',
              style: TextStyle(color: subtle, fontSize: 10.5, height: 1.35),
            ),
          ],
          if (onSaveCatalogPressed != null) ...[
            const SizedBox(height: 8),
            CupertinoButton(
              key: const ValueKey('surface_studio_guidance_save_catalog'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              onPressed: onSaveCatalogPressed,
              child: const Text('Sauvegarder le catalogue'),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyPaintableState extends StatelessWidget {
  const _EmptyPaintableState({required this.hasAnimations});

  final bool hasAnimations;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final label = EditorChrome.primaryLabel(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasAnimations
                ? 'Animations détectées, mais aucune surface peignable.'
                : 'Aucune surface prête à peindre',
            style: TextStyle(
              color: label,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasAnimations
                ? 'Créez une surface à partir des animations générées.'
                : 'Générez des animations depuis un atlas, puis créez une surface peignable.',
            style: TextStyle(
              color: subtle.withValues(alpha: 0.95),
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaintableSurfaceRow extends StatelessWidget {
  const _PaintableSurfaceRow({
    required this.row,
    required this.selected,
    this.onSelect,
    this.onEditMapping,
  });

  final SurfaceStudioPresetReadModel row;
  final bool selected;
  final VoidCallback? onSelect;
  final VoidCallback? onEditMapping;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final content = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: selected
            ? _accent.withValues(alpha: 0.12)
            : EditorChrome.islandFillElevated(context).withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected
              ? _accent.withValues(alpha: 0.68)
              : EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: label,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Peignable',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'ID : ${row.id}',
            style: TextStyle(
              color: subtle.withValues(alpha: 0.92),
              fontSize: 10.5,
              height: 1.3,
            ),
          ),
          Text(
            '${row.referencedAnimationIds.length} animation(s) liée(s)',
            style: TextStyle(
              color: subtle.withValues(alpha: 0.92),
              fontSize: 10.5,
              height: 1.3,
            ),
          ),
          if (onEditMapping != null) ...[
            const SizedBox(height: 8),
            CupertinoButton(
              key: ValueKey('surface_paintable_edit_mapping_${row.id}'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              onPressed: onEditMapping,
              child: const Text('Modifier le mapping visuel'),
            ),
          ],
        ],
      ),
    );
    if (onSelect == null) {
      return content;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onSelect,
      child: content,
    );
  }
}

```

### `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`

```dart
// Surface Studio — shell UI lecture seule (Lot 52).
//
// Consomme un [SurfaceStudioReadModel] déjà construit côté [map_core] : pas de
// re-diagnostic, pas de mutation manifest, pas d’I/O. Les actions futures sont
// désactivées ; seul le placeholder « Actions auteur » reste pour un lot ultérieur.
//
// Style : aligné sur [EditorChrome] / îlots de l’éditeur (pas de Card Material
// clair isolé) — cohérent avec World Explorer et le shell macOS.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'surface_studio_atlas_editing.dart';
import 'surface_studio_atlas_authoring_prep.dart';
import 'surface_studio_catalog_browser.dart';
import 'surface_studio_creation_assistant.dart';
import 'surface_studio_detected_animations_panel.dart';
import 'surface_studio_diagnostics_view.dart';
import 'surface_studio_paintable_surfaces_panel.dart';
import 'surface_studio_preset_editor_controller.dart';
import 'surface_studio_role_mapping_editor.dart';
import 'surface_studio_selection.dart';
import 'surface_studio_selection_inspector.dart';
import 'surface_studio_selection_summary.dart';
import 'surface_studio_workflow_layout.dart';
import 'surface_studio_workflow_stepper.dart';

SurfaceStudioSelection _selectionValidInReadModel(
  SurfaceStudioReadModel rm,
  SurfaceStudioSelection sel,
) {
  if (sel.isNone) return sel;
  if (sel.isAtlas) {
    for (final row in rm.atlases) {
      if (row.id == sel.id) return sel;
    }
  } else if (sel.isAnimation) {
    for (final row in rm.animations) {
      if (row.id == sel.id) return sel;
    }
  } else if (sel.isPreset) {
    for (final row in rm.presets) {
      if (row.id == sel.id) return sel;
    }
  }
  return const SurfaceStudioSelection.none();
}

/// Accent produit Surface Studio (même base que la tuile World Explorer).
const Color _surfaceStudioAccent = Color(0xFF2DD4BF);

/// Panneau présentationnel **lecture seule** pour Surface Studio.
class SurfaceStudioPanel extends StatefulWidget {
  const SurfaceStudioPanel({
    super.key,
    required this.readModel,
    this.onSurfaceCatalogSaveRequested,
    this.onRequestProjectSave,
    this.projectTilesets,
    this.projectRootPath,
    this.surfaceMappingImageLoader,
  });

  final SurfaceStudioReadModel readModel;
  final ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogSaveRequested;
  final Future<bool> Function()? onRequestProjectSave;
  final List<ProjectTilesetEntry>? projectTilesets;
  final SurfaceStudioAtlasUiImageLoader? surfaceMappingImageLoader;

  /// Racine projet sur disque pour résoudre les chemins d’images tileset (aperçu Lot 72).
  final String? projectRootPath;

  static const String titleText = 'Surface Studio';
  static const String readOnlyBadgeText = 'Lecture seule';
  static const String partialAuthoringBadgeText = 'Édition partielle';
  static const String workflowStepsHintText =
      'Étapes : atlas → grille → animations → surfaces prêtes à peindre';
  static const String productDescriptionText =
      'Créer des surfaces peintes à partir d’un atlas, étape par étape.';
  static const String placeholderActionsTitle = 'Actions auteur';
  static const String placeholderSoonText = 'Bientôt';
  static const String actionImportVerticalAtlasLabel =
      'Importer un atlas vertical';
  static const String workCatalogDirtyStateText =
      'Catalogue de travail modifié — sauvegarde projet non effectuée.';
  static const String savePrepActionLabel =
      'Préparer la sauvegarde du catalogue Surface';
  static const String savePrepTransmittedNote =
      'Catalogue de travail transmis au parent.';
  static const String savePrepNotConnectedNote =
      'Sauvegarde non connectée dans ce contexte.';
  static const String savePrepNoDiskNote =
      'Aucune écriture disque ne sera effectuée par Surface Studio.';
  static const String manifestMemoryUpdatedNote =
      'Manifest projet mis à jour en mémoire — écriture disque non effectuée.';
  static const String projectSaveViaExistingFlowButtonLabel =
      'Sauvegarder le projet via le flux existant';
  static const String projectDiskSaveResultSuccessNote =
      'Projet sauvegardé via le flux projet existant.';
  static const String projectDiskSaveRequestedNote =
      'Sauvegarde projet demandée.';
  static const String projectDiskSaveFailureNote =
      'Échec de sauvegarde projet — voir la barre d’état.';

  @override
  State<SurfaceStudioPanel> createState() => _SurfaceStudioPanelState();
}

class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
  /// Sélection d’inspection : locale au widget, jamais écrite dans le manifest.
  SurfaceStudioSelection _selection = const SurfaceStudioSelection.none();
  late SurfaceStudioReadModel _workReadModel;
  String? _saveFlowPrepNote;
  String? _projectSaveDiskNote;
  int _atlasEditSignal = 0;

  @override
  void initState() {
    super.initState();
    _workReadModel = widget.readModel;
  }

  @override
  void didUpdateWidget(covariant SurfaceStudioPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.readModel != oldWidget.readModel) {
      final hadDirty = _workReadModel != oldWidget.readModel;
      final absNow = widget.readModel ==
          buildSurfaceStudioReadModelFromCatalog(_workReadModel.catalog);
      final wasAbsorbed = hadDirty && absNow;
      setState(() {
        _workReadModel = widget.readModel;
        _selection = _selectionValidInReadModel(_workReadModel, _selection);
        _saveFlowPrepNote =
            wasAbsorbed ? SurfaceStudioPanel.manifestMemoryUpdatedNote : null;
      });
    }
  }

  bool get _hasWorkCatalogChanges => _workReadModel != widget.readModel;

  void _bumpAtlasEditSignal() {
    setState(() => _atlasEditSignal += 1);
  }

  void _onConfirmDeleteSelectedAtlas() {
    final id = _selection.id;
    if (id == null || !_selection.isAtlas) {
      return;
    }
    try {
      final next = removeAtlasIdFromWorkCatalog(_workReadModel.catalog, id);
      setState(() {
        _saveFlowPrepNote = null;
        _workReadModel = buildSurfaceStudioReadModelFromCatalog(next);
        _selection = const SurfaceStudioSelection.none();
      });
    } on StateError {
      return;
    }
  }

  SurfaceStudioSelection _selectionAfterCatalogChanged(
    ProjectSurfaceCatalog cat,
  ) {
    if (_selection.isAtlas) {
      final sid = _selection.id;
      if (sid != null) {
        for (final a in cat.atlases) {
          if (a.id == sid) {
            return SurfaceStudioSelection.atlas(sid);
          }
        }
        return const SurfaceStudioSelection.none();
      }
    }
    if (_selection.isAnimation) {
      final sid = _selection.id;
      if (sid != null) {
        for (final a in cat.animations) {
          if (a.id == sid) {
            return SurfaceStudioSelection.animation(sid);
          }
        }
        return const SurfaceStudioSelection.none();
      }
    }
    if (_selection.isPreset) {
      final sid = _selection.id;
      if (sid != null) {
        for (final p in cat.presets) {
          if (p.id == sid) {
            return SurfaceStudioSelection.preset(sid);
          }
        }
        return const SurfaceStudioSelection.none();
      }
    }
    if (cat.atlases.isNotEmpty) {
      return SurfaceStudioSelection.atlas(cat.atlases.last.id);
    }
    return const SurfaceStudioSelection.none();
  }

  void _onSurfaceCatalogSavePrep() {
    final cb = widget.onSurfaceCatalogSaveRequested;
    if (cb == null) {
      return;
    }
    cb(_workReadModel.catalog);
    setState(() {
      _saveFlowPrepNote = SurfaceStudioPanel.savePrepTransmittedNote;
    });
  }

  Future<void> _onRequestProjectSave() async {
    final fn = widget.onRequestProjectSave;
    if (fn == null) {
      return;
    }
    setState(() {
      _projectSaveDiskNote = SurfaceStudioPanel.projectDiskSaveRequestedNote;
    });
    final ok = await fn();
    if (!mounted) {
      return;
    }
    setState(() {
      _projectSaveDiskNote = ok
          ? SurfaceStudioPanel.projectDiskSaveResultSuccessNote
          : SurfaceStudioPanel.projectDiskSaveFailureNote;
    });
  }

  ProjectSurfacePreset? _selectedWorkPreset() {
    final id = _selection.id;
    if (id == null || !_selection.isPreset) {
      return null;
    }
    return _workReadModel.catalog.presetById(id);
  }

  void _selectPreset(String presetId) {
    setState(() {
      _selection = SurfaceStudioSelection.preset(presetId);
    });
  }

  void _onPresetRoleAnimationChanged(
    SurfaceVariantRole role,
    String animationId,
  ) {
    final presetId = _selection.id;
    if (presetId == null || !_selection.isPreset) {
      return;
    }
    final next = surfaceStudioReplacePresetRoleAnimation(
      catalog: _workReadModel.catalog,
      presetId: presetId,
      role: role,
      animationId: animationId,
    );
    setState(() {
      _saveFlowPrepNote = null;
      _workReadModel = buildSurfaceStudioReadModelFromCatalog(next);
      _selection = SurfaceStudioSelection.preset(presetId);
    });
  }

  Future<void> _openPresetMappingEditor(String presetId) async {
    final preset = _workReadModel.catalog.presetById(presetId);
    if (preset == null) {
      return;
    }
    setState(() {
      _selection = SurfaceStudioSelection.preset(presetId);
    });
    await showMacosSheet<void>(
      context: context,
      builder: (ctx) => Center(
        child: MacosSheet(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              key: const ValueKey('surface_mapping_editor_sheet'),
              width: 1120,
              height: 760,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Surface Mapping Editor',
                          style: editorMacosSheetTitleStyle(ctx),
                        ),
                      ),
                      PushButton(
                        key: const ValueKey('surface_mapping_editor_close'),
                        controlSize: ControlSize.large,
                        secondary: true,
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Fermer'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Étape 1 : choisissez un slot visuel. Étape 2 : cliquez directement une colonne dans l’atlas réel.',
                    style: TextStyle(
                      color: _surfaceStudioAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SurfaceStudioRoleMappingEditor(
                        catalog: _workReadModel.catalog,
                        preset: preset,
                        projectRootPath: widget.projectRootPath,
                        projectTilesets: widget.projectTilesets ??
                            const <ProjectTilesetEntry>[],
                        imageLoader: widget.surfaceMappingImageLoader,
                        onRoleAnimationChanged: _onPresetRoleAnimationChanged,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _workReadModel.summary;
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final isPartial = widget.onSurfaceCatalogSaveRequested != null;
    final canMutateCatalog = widget.onSurfaceCatalogSaveRequested != null;
    final authoring = SurfaceStudioAtlasAuthoringPrep(
      readModel: _workReadModel,
      selection: _selection,
      requestEditSignal: _atlasEditSignal,
      projectTilesets: widget.projectTilesets,
      projectRootPath: widget.projectRootPath,
      onSurfaceCatalogChanged: (cat) {
        setState(() {
          _saveFlowPrepNote = null;
          _workReadModel = buildSurfaceStudioReadModelFromCatalog(cat);
          _selection = _selectionAfterCatalogChanged(cat);
        });
      },
      onWorkCatalogAnimationsCreated: (createdIds) {
        if (createdIds.isEmpty) {
          return;
        }
        setState(() {
          _selection = SurfaceStudioSelection.animation(createdIds.first);
        });
      },
      onWorkCatalogPresetCreated: (presetId) {
        if (presetId.isEmpty) {
          return;
        }
        setState(() {
          _selection = SurfaceStudioSelection.preset(presetId);
        });
      },
    );
    final inspection = Column(
      key: const ValueKey('surface_studio_inspection_column'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SurfaceStudioSelectionSummary(selection: _selection),
        const SizedBox(height: 10),
        SurfaceStudioSelectionInspector(
          readModel: _workReadModel,
          selection: _selection,
          onRequestEditSelectedAtlas:
              canMutateCatalog ? _bumpAtlasEditSignal : null,
          onConfirmDeleteSelectedAtlas:
              canMutateCatalog ? _onConfirmDeleteSelectedAtlas : null,
        ),
      ],
    );
    final assistant = SurfaceStudioCreationAssistant(readModel: _workReadModel);
    final detectedAnimations =
        SurfaceStudioDetectedAnimationsPanel(readModel: _workReadModel);
    final selectedPreset = _selectedWorkPreset();
    final paintableSurfaces = SurfaceStudioPaintableSurfacesPanel(
      readModel: _workReadModel,
      selectedPresetId: selectedPreset?.id,
      onPresetSelected: _selectPreset,
      onEditMappingPressed: canMutateCatalog ? _openPresetMappingEditor : null,
      onSaveCatalogPressed: widget.onSurfaceCatalogSaveRequested != null
          ? _onSurfaceCatalogSavePrep
          : null,
    );

    return SingleChildScrollView(
      key: const ValueKey('surface_studio_root_scroll'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CompactStudioHeader(
            key: const ValueKey('surface_studio_workflow_header'),
            label: label,
            subtle: subtle,
            summary: s,
            readOnly: !isPartial,
          ),
          const SizedBox(height: 8),
          SurfaceStudioWorkflowStepper(readModel: _workReadModel),
          if (_hasWorkCatalogChanges) ...[
            const SizedBox(height: 10),
            _CatalogStateStrip(
              key: const ValueKey('surface_studio_catalog_status_strip'),
              subtle: subtle,
              workCatalogNote: SurfaceStudioPanel.workCatalogDirtyStateText,
              onSurfaceSavePrep: widget.onSurfaceCatalogSaveRequested != null
                  ? _onSurfaceCatalogSavePrep
                  : null,
              onResetWorkCatalog: () {
                setState(() {
                  _workReadModel = widget.readModel;
                  _selection =
                      _selectionValidInReadModel(_workReadModel, _selection);
                  _saveFlowPrepNote = null;
                });
              },
            ),
            if (widget.onSurfaceCatalogSaveRequested == null)
              Text(
                key: const ValueKey('surface_studio_save_prep_not_connected'),
                SurfaceStudioPanel.savePrepNotConnectedNote,
                style: TextStyle(
                  color: subtle.withValues(alpha: 0.95),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            if (widget.onRequestProjectSave != null) ...[
              const SizedBox(height: 6),
              CupertinoButton(
                key: const ValueKey(
                    'surface_studio_project_save_via_official_flow'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                onPressed: _onRequestProjectSave,
                child: const Text(
                  SurfaceStudioPanel.projectSaveViaExistingFlowButtonLabel,
                ),
              ),
              if (_projectSaveDiskNote != null)
                Text(
                  _projectSaveDiskNote!,
                  key: const ValueKey('surface_studio_project_save_disk_note'),
                  style: TextStyle(
                    color: _surfaceStudioAccent.withValues(alpha: 0.88),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ] else if (widget.onRequestProjectSave != null) ...[
            const SizedBox(height: 8),
            CupertinoButton(
              key: const ValueKey(
                  'surface_studio_project_save_via_official_flow'),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              onPressed: _onRequestProjectSave,
              child: const Text(
                SurfaceStudioPanel.projectSaveViaExistingFlowButtonLabel,
              ),
            ),
            if (_projectSaveDiskNote != null) ...[
              const SizedBox(height: 4),
              Text(
                _projectSaveDiskNote!,
                key: const ValueKey('surface_studio_project_save_disk_note'),
                style: TextStyle(
                  color: _surfaceStudioAccent.withValues(alpha: 0.88),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
          if (_saveFlowPrepNote != null) ...[
            const SizedBox(height: 6),
            Text(
              _saveFlowPrepNote!,
              key: const ValueKey('surface_studio_save_prep_transmitted'),
              style: TextStyle(
                color: _surfaceStudioAccent.withValues(alpha: 0.9),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SurfaceStudioWorkflowLayout(
            assistant: assistant,
            atlasWorkspace: authoring,
            detectedAnimations: detectedAnimations,
            paintableSurfaces: paintableSurfaces,
          ),
          const SizedBox(height: 12),
          _AdvancedDetailsSection(
            inspection: inspection,
            browser: SurfaceStudioCatalogBrowser(
              readModel: _workReadModel,
              selection: _selection,
              onSelectionChanged: (v) {
                setState(() => _selection = v);
              },
            ),
            diagnostics:
                SurfaceStudioDiagnosticsView(readModel: _workReadModel),
            futureActions: const _FutureActions(onImportVertical: null),
            placeholder: const _SectionPlaceholder(
              title: SurfaceStudioPanel.placeholderActionsTitle,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvancedDetailsSection extends StatelessWidget {
  const _AdvancedDetailsSection({
    required this.inspection,
    required this.browser,
    required this.diagnostics,
    required this.futureActions,
    required this.placeholder,
  });

  final Widget inspection;
  final Widget browser;
  final Widget diagnostics;
  final Widget futureActions;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return _StudioCard(
      key: const ValueKey('surface_studio_advanced_details'),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Détails avancés',
            style: TextStyle(
              color: label,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Catalogue, inspection et diagnostics restent disponibles sans remplacer le workflow principal.',
            style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth >= 960) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: inspection),
                    const SizedBox(width: 12),
                    Expanded(child: browser),
                    const SizedBox(width: 12),
                    Expanded(child: diagnostics),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  inspection,
                  const SizedBox(height: 12),
                  browser,
                  const SizedBox(height: 12),
                  diagnostics,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          futureActions,
          const SizedBox(height: 10),
          placeholder,
        ],
      ),
    );
  }
}

class _CompactStudioHeader extends StatelessWidget {
  const _CompactStudioHeader({
    super.key,
    required this.label,
    required this.subtle,
    required this.summary,
    required this.readOnly,
  });

  final Color label;
  final Color subtle;
  final SurfaceStudioCatalogSummaryReadModel summary;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final titleRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StudioHeaderIcon(accent: _surfaceStudioAccent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      SurfaceStudioPanel.titleText,
                      style: TextStyle(
                        color: label,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (readOnly)
                    const _ReadOnlyBadge(
                      label: SurfaceStudioPanel.readOnlyBadgeText,
                    )
                  else
                    const _ReadOnlyBadge(
                      label: SurfaceStudioPanel.partialAuthoringBadgeText,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                SurfaceStudioPanel.productDescriptionText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subtle,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    final counters = _CounterRow(
      atlas: summary.atlasCount,
      animations: summary.animationCount,
      presets: summary.presetCount,
      compact: true,
    );
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleRow,
              const SizedBox(height: 8),
              counters,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleRow),
            const SizedBox(width: 6),
            counters,
          ],
        );
      },
    );
  }
}

class _CatalogStateStrip extends StatelessWidget {
  const _CatalogStateStrip({
    super.key,
    required this.subtle,
    required this.workCatalogNote,
    required this.onResetWorkCatalog,
    this.onSurfaceSavePrep,
  });

  final Color subtle;
  final String workCatalogNote;
  final VoidCallback onResetWorkCatalog;
  final void Function()? onSurfaceSavePrep;

  @override
  Widget build(BuildContext context) {
    return _StudioCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            workCatalogNote,
            key: const ValueKey('surface_studio_work_catalog_dirty_state'),
            style: TextStyle(
              color: _surfaceStudioAccent.withValues(alpha: 0.95),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            SurfaceStudioPanel.savePrepNoDiskNote,
            style: TextStyle(
              color: subtle.withValues(alpha: 0.88),
              fontSize: 10.5,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (onSurfaceSavePrep != null)
                CupertinoButton(
                  key: const ValueKey('surface_studio_save_prep_catalog'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  onPressed: onSurfaceSavePrep,
                  child: const Text(SurfaceStudioPanel.savePrepActionLabel),
                ),
              CupertinoButton(
                key: const ValueKey('surface_studio_reset_work_catalog'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                onPressed: onResetWorkCatalog,
                child: const Text('Réinitialiser le catalogue de travail'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudioHeaderIcon extends StatelessWidget {
  const _StudioHeaderIcon({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    const hi = Color(0xFFFFFFFF);
    const lo = Color(0xFF120808);
    final onAccent =
        accent.computeLuminance() > 0.55 ? const Color(0xFF1A0A08) : hi;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(hi, accent, 0.72)!,
            Color.lerp(accent, lo, 0.38)!,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withValues(alpha: 0.88),
          width: 1.2,
        ),
        boxShadow: EditorChrome.toolbarCapsuleShadows(context),
      ),
      alignment: Alignment.center,
      child: MacosIcon(
        Icons.auto_awesome_motion,
        color: onAccent,
        size: 22,
      ),
    );
  }
}

class _ReadOnlyBadge extends StatelessWidget {
  const _ReadOnlyBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    const accent = _surfaceStudioAccent;
    final fill = Color.lerp(
      EditorChrome.islandFillElevated(context),
      accent,
      0.14,
    )!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.65)),
        boxShadow: EditorChrome.toolbarCapsuleShadows(context),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _surfaceStudioAccent,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  const _CounterRow({
    required this.atlas,
    required this.animations,
    required this.presets,
    this.compact = false,
  });

  final int atlas;
  final int animations;
  final int presets;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const ValueKey('surface_studio_header_counters'),
      spacing: compact ? 6 : 12,
      runSpacing: compact ? 6 : 10,
      children: [
        _CounterChip(label: 'Atlas', value: atlas, compact: compact),
        _CounterChip(label: 'Animations', value: animations, compact: compact),
        _CounterChip(label: 'Surfaces', value: presets, compact: compact),
      ],
    );
  }
}

class _CounterChip extends StatelessWidget {
  const _CounterChip({
    required this.label,
    required this.value,
    this.compact = false,
  });

  final String label;
  final int value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final labelColor = EditorChrome.primaryLabel(context);

    return _StudioCard(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 16,
        vertical: compact ? 7 : 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: subtle,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: compact ? 3 : 6),
          Text(
            '$value',
            style: TextStyle(
              color: labelColor,
              fontSize: compact ? 16 : 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte interne : même relief que les tuiles inspecteur / sections.
class _StudioCard extends StatelessWidget {
  const _StudioCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context),
          width: 1,
        ),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: child,
    );
  }
}

class _FutureActions extends StatelessWidget {
  const _FutureActions({
    required this.onImportVertical,
  });

  final VoidCallback? onImportVertical;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions futures (non disponibles)',
          style: TextStyle(
            color: subtle,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _GhostAction(
              label: SurfaceStudioPanel.actionImportVerticalAtlasLabel,
              onPressed: onImportVertical,
            ),
          ],
        ),
      ],
    );
  }
}

class _GhostAction extends StatelessWidget {
  const _GhostAction({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final enabled = onPressed != null;

    return Opacity(
      opacity: enabled ? 1.0 : 0.48,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(
            color: enabled ? EditorChrome.inspectorJoyCyan : subtle,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

class _SectionPlaceholder extends StatelessWidget {
  const _SectionPlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return _StudioCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: label,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  SurfaceStudioPanel.placeholderSoonText,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          MacosIcon(
            CupertinoIcons.chevron_right,
            size: 16,
            color: subtle,
          ),
        ],
      ),
    );
  }
}

/// Adaptateur : construit le read model **sans** I/O à partir d’un [ProjectManifest].
class SurfaceStudioPanelFromManifest extends StatefulWidget {
  const SurfaceStudioPanelFromManifest({
    super.key,
    required this.manifest,
    this.onProjectManifestChanged,
    this.onRequestProjectSave,
    this.projectRootPath,
  });

  final ProjectManifest manifest;
  final ValueChanged<ProjectManifest>? onProjectManifestChanged;
  final Future<bool> Function()? onRequestProjectSave;

  /// Dossier projet ouvert (même source que l’éditeur) pour résoudre les fichiers image.
  final String? projectRootPath;

  @override
  State<SurfaceStudioPanelFromManifest> createState() =>
      _SurfaceStudioPanelFromManifestState();
}

class _SurfaceStudioPanelFromManifestState
    extends State<SurfaceStudioPanelFromManifest> {
  late ProjectManifest _manifest;

  @override
  void initState() {
    super.initState();
    _manifest = widget.manifest;
  }

  @override
  void didUpdateWidget(covariant SurfaceStudioPanelFromManifest oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.manifest != oldWidget.manifest) {
      setState(() {
        _manifest = widget.manifest;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SurfaceStudioPanel(
      readModel: buildSurfaceStudioReadModel(_manifest),
      projectTilesets: _manifest.tilesets,
      projectRootPath: widget.projectRootPath,
      onSurfaceCatalogSaveRequested: (c) {
        final n = replaceProjectManifestSurfaceCatalog(_manifest, c);
        setState(() {
          _manifest = n;
        });
        widget.onProjectManifestChanged?.call(n);
      },
      onRequestProjectSave: widget.onRequestProjectSave,
    );
  }
}

```

### `packages/map_editor/lib/src/features/surface_studio/surface_studio_role_mapping_editor.dart`

```dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'surface_studio_role_mapping_preview.dart';

const Color _accent = Color(0xFF2DD4BF);
const Color _warning = Color(0xFFF59E0B);
const Color _danger = Color(0xFFEF4444);

typedef SurfaceStudioAtlasUiImageLoader = Future<ui.Image?> Function(
  String absolutePath,
);

/// Charge une image atlas Surface pour le mapping visuel.
///
/// Ce helper reste volontairement local au Surface Studio : le Lot 88-quinquies
/// a besoin d'un aperçu editor depuis le disque, pas d'un nouveau service
/// d'assets partagé ni d'un contrat runtime.
Future<ui.Image?> loadSurfaceStudioRoleMappingAtlasImage(
  String absolutePath,
) async {
  try {
    final bytes = await File(absolutePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  } catch (_) {
    return null;
  }
}

/// Une animation Surface présentée comme une colonne d'atlas modifiable.
///
/// Dans les catalogues générés depuis un atlas vertical, chaque animation
/// correspond en pratique à une colonne. Le modèle persistant reste
/// rôle -> animationId ; cette vue reconstruit juste une lecture visuelle
/// colonne -> rôles pour que l'utilisateur n'édite plus une liste abstraite.
class SurfaceStudioRoleMappingColumnOption {
  const SurfaceStudioRoleMappingColumnOption({
    required this.animation,
    required this.atlasId,
    required this.columnIndex,
    required this.rowIndex,
    required this.assignedRoles,
  });

  final ProjectSurfaceAnimation animation;
  final String atlasId;
  final int columnIndex;
  final int rowIndex;
  final List<SurfaceVariantRole> assignedRoles;

  String get animationId => animation.id;

  int get frameCount => animation.frameCount;

  bool get isAssigned => assignedRoles.isNotEmpty;

  bool get hasDuplicateAssignment => assignedRoles.length > 1;
}

/// Analyse locale du preset courant pour alimenter la UI visuelle.
///
/// Elle ne valide pas le catalogue au sens métier global : elle résume seulement
/// ce que l'utilisateur doit voir pour corriger un mapping dans le catalogue de
/// travail Surface Studio.
class SurfaceStudioRoleMappingAnalysis {
  SurfaceStudioRoleMappingAnalysis._({
    required this.columns,
    required this.assignedColumnCount,
    required this.unassignedColumnCount,
    required this.duplicateAnimationCount,
    required this.missingRoleCount,
  });

  final List<SurfaceStudioRoleMappingColumnOption> columns;
  final int assignedColumnCount;
  final int unassignedColumnCount;
  final int duplicateAnimationCount;
  final int missingRoleCount;

  factory SurfaceStudioRoleMappingAnalysis.fromCatalog({
    required ProjectSurfaceCatalog catalog,
    required ProjectSurfacePreset preset,
  }) {
    final rolesByAnimation = <String, List<SurfaceVariantRole>>{};
    for (final ref in preset.variantAnimations.refs) {
      rolesByAnimation
          .putIfAbsent(ref.animationId, () => <SurfaceVariantRole>[])
          .add(ref.role);
    }

    final columns = <SurfaceStudioRoleMappingColumnOption>[];
    for (final animation in catalog.animations) {
      final firstFrame = animation.timeline.frames.first;
      columns.add(
        SurfaceStudioRoleMappingColumnOption(
          animation: animation,
          atlasId: firstFrame.tileRef.atlasId,
          columnIndex: firstFrame.tileRef.column,
          rowIndex: firstFrame.tileRef.row,
          assignedRoles: List<SurfaceVariantRole>.unmodifiable(
            rolesByAnimation[animation.id] ?? const <SurfaceVariantRole>[],
          ),
        ),
      );
    }

    columns.sort((a, b) {
      final atlas = a.atlasId.compareTo(b.atlasId);
      if (atlas != 0) {
        return atlas;
      }
      final col = a.columnIndex.compareTo(b.columnIndex);
      if (col != 0) {
        return col;
      }
      return a.animation.id.compareTo(b.animation.id);
    });

    final assigned = columns.where((column) => column.isAssigned).length;
    final duplicates =
        columns.where((column) => column.hasDuplicateAssignment).length;
    final missingRoles = standardSurfaceVariantRoleOrder
        .where((role) => !preset.containsRole(role))
        .length;

    return SurfaceStudioRoleMappingAnalysis._(
      columns: List<SurfaceStudioRoleMappingColumnOption>.unmodifiable(columns),
      assignedColumnCount: assigned,
      unassignedColumnCount: columns.length - assigned,
      duplicateAnimationCount: duplicates,
      missingRoleCount: missingRoles,
    );
  }

  SurfaceStudioRoleMappingColumnOption? columnByAnimationId(String? id) {
    if (id == null) {
      return null;
    }
    for (final column in columns) {
      if (column.animation.id == id) {
        return column;
      }
    }
    return null;
  }
}

class SurfaceStudioRoleMappingEditor extends StatefulWidget {
  const SurfaceStudioRoleMappingEditor({
    super.key,
    required this.catalog,
    required this.preset,
    this.projectRootPath,
    this.projectTilesets = const <ProjectTilesetEntry>[],
    this.imageLoader,
    this.onRoleAnimationChanged,
  });

  final ProjectSurfaceCatalog catalog;
  final ProjectSurfacePreset preset;
  final String? projectRootPath;
  final List<ProjectTilesetEntry> projectTilesets;
  final SurfaceStudioAtlasUiImageLoader? imageLoader;
  final void Function(SurfaceVariantRole role, String animationId)?
      onRoleAnimationChanged;

  @override
  State<SurfaceStudioRoleMappingEditor> createState() =>
      _SurfaceStudioRoleMappingEditorState();
}

class _SurfaceStudioRoleMappingEditorState
    extends State<SurfaceStudioRoleMappingEditor> {
  SurfaceVariantRole _selectedRole = SurfaceVariantRole.cross;
  String? _selectedAnimationId;
  final Map<SurfaceVariantRole, String> _optimisticRoleAnimationIds =
      <SurfaceVariantRole, String>{};

  @override
  void didUpdateWidget(covariant SurfaceStudioRoleMappingEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.catalog != oldWidget.catalog ||
        widget.preset != oldWidget.preset) {
      _optimisticRoleAnimationIds.clear();
      final analysis = SurfaceStudioRoleMappingAnalysis.fromCatalog(
        catalog: widget.catalog,
        preset: widget.preset,
      );
      if (analysis.columnByAnimationId(_selectedAnimationId) == null) {
        _selectedAnimationId = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final analysis = SurfaceStudioRoleMappingAnalysis.fromCatalog(
      catalog: widget.catalog,
      preset: widget.preset,
    );
    final selectedColumn = _resolveSelectedColumn(analysis);

    return Container(
      key: const ValueKey('surface_role_mapping_editor'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withValues(alpha: 0.38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Édition du mapping de surface',
            style: TextStyle(
              color: label,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Surface sélectionnée : ${widget.preset.name}',
            style: TextStyle(
              color: label,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Un atlas fournit des colonnes, une animation lit les frames d’une colonne, et un rôle indique où cette animation sera utilisée dans la surface.',
            style: TextStyle(color: subtle, fontSize: 10.5, height: 1.35),
          ),
          const SizedBox(height: 10),
          if (analysis.columns.isEmpty)
            _NoAnimationsState(subtle: subtle, label: label)
          else ...[
            _MappingSummary(analysis: analysis),
            const SizedBox(height: 10),
            _MappingWorkspace(
              analysis: analysis,
              catalog: widget.catalog,
              preset: widget.preset,
              projectRootPath: widget.projectRootPath,
              projectTilesets: widget.projectTilesets,
              imageLoader:
                  widget.imageLoader ?? loadSurfaceStudioRoleMappingAtlasImage,
              selectedRole: _selectedRole,
              selectedColumn: selectedColumn,
              selectedRoleAnimationId:
                  _effectiveAnimationIdForRole(_selectedRole),
              onRoleSelected: _selectRole,
              onColumnSelected: _selectColumn,
              onColumnAssigned: widget.onRoleAnimationChanged == null
                  ? null
                  : _assignColumnToSelectedRole,
            ),
          ],
        ],
      ),
    );
  }

  SurfaceStudioRoleMappingColumnOption? _resolveSelectedColumn(
    SurfaceStudioRoleMappingAnalysis analysis,
  ) {
    final explicit = analysis.columnByAnimationId(_selectedAnimationId);
    if (explicit != null) {
      return explicit;
    }
    final roleAnimationId = widget.preset.animationIdForRole(_selectedRole);
    final currentForRole = analysis.columnByAnimationId(roleAnimationId);
    if (currentForRole != null) {
      return currentForRole;
    }
    if (analysis.columns.isNotEmpty) {
      return analysis.columns.first;
    }
    return null;
  }

  String? _effectiveAnimationIdForRole(SurfaceVariantRole role) {
    return _optimisticRoleAnimationIds[role] ??
        widget.preset.animationIdForRole(role);
  }

  void _selectRole(SurfaceVariantRole role) {
    setState(() {
      _selectedRole = role;
      _selectedAnimationId =
          _effectiveAnimationIdForRole(role) ?? _selectedAnimationId;
    });
  }

  void _selectColumn(SurfaceStudioRoleMappingColumnOption column) {
    setState(() {
      _selectedAnimationId = column.animationId;
    });
  }

  void _assignColumnToSelectedRole(
    SurfaceStudioRoleMappingColumnOption column,
  ) {
    setState(() {
      _selectedAnimationId = column.animationId;
      // Le parent reconstruit normalement le catalogue de travail après le
      // callback. Cette écriture optimiste rend le retour visuel immédiat dans
      // les tests isolés et dans le cas d'un frame avant propagation Riverpod.
      _optimisticRoleAnimationIds[_selectedRole] = column.animationId;
    });
    widget.onRoleAnimationChanged?.call(_selectedRole, column.animationId);
  }
}

class _MappingWorkspace extends StatefulWidget {
  const _MappingWorkspace({
    required this.analysis,
    required this.catalog,
    required this.preset,
    required this.projectRootPath,
    required this.projectTilesets,
    required this.imageLoader,
    required this.selectedRole,
    required this.selectedColumn,
    required this.selectedRoleAnimationId,
    required this.onRoleSelected,
    required this.onColumnSelected,
    required this.onColumnAssigned,
  });

  final SurfaceStudioRoleMappingAnalysis analysis;
  final ProjectSurfaceCatalog catalog;
  final ProjectSurfacePreset preset;
  final String? projectRootPath;
  final List<ProjectTilesetEntry> projectTilesets;
  final SurfaceStudioAtlasUiImageLoader imageLoader;
  final SurfaceVariantRole selectedRole;
  final SurfaceStudioRoleMappingColumnOption? selectedColumn;
  final String? selectedRoleAnimationId;
  final ValueChanged<SurfaceVariantRole> onRoleSelected;
  final ValueChanged<SurfaceStudioRoleMappingColumnOption> onColumnSelected;
  final ValueChanged<SurfaceStudioRoleMappingColumnOption>? onColumnAssigned;

  @override
  State<_MappingWorkspace> createState() => _MappingWorkspaceState();
}

class _MappingWorkspaceState extends State<_MappingWorkspace> {
  _SurfaceAtlasPickerSource? _source;
  String? _imagePath;
  Future<ui.Image?>? _imageFuture;

  @override
  void initState() {
    super.initState();
    _refreshImageSource();
  }

  @override
  void didUpdateWidget(covariant _MappingWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.catalog != widget.catalog ||
        oldWidget.preset != widget.preset ||
        oldWidget.projectRootPath != widget.projectRootPath ||
        oldWidget.projectTilesets != widget.projectTilesets ||
        oldWidget.imageLoader != widget.imageLoader) {
      _refreshImageSource();
    }
  }

  void _refreshImageSource() {
    final source = _resolveSurfaceAtlasPickerSource(
      catalog: widget.catalog,
      preset: widget.preset,
      projectRootPath: widget.projectRootPath,
      projectTilesets: widget.projectTilesets,
    );
    _source = source;
    final path = source.absolutePath;
    if (path == null || path.isEmpty) {
      _imagePath = null;
      _imageFuture = null;
      return;
    }
    if (_imagePath == path && _imageFuture != null) {
      return;
    }
    _imagePath = path;
    _imageFuture = widget.imageLoader(path);
  }

  @override
  Widget build(BuildContext context) {
    final source = _source ??
        _resolveSurfaceAtlasPickerSource(
          catalog: widget.catalog,
          preset: widget.preset,
          projectRootPath: widget.projectRootPath,
          projectTilesets: widget.projectTilesets,
        );
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageFuture = _imageFuture;
        if (imageFuture == null) {
          return _buildLayout(
            constraints: constraints,
            source: source,
            atlasImage: null,
            imageLoading: false,
          );
        }
        return FutureBuilder<ui.Image?>(
          future: imageFuture,
          builder: (context, snapshot) => _buildLayout(
            constraints: constraints,
            source: source,
            atlasImage: snapshot.data,
            imageLoading: snapshot.connectionState != ConnectionState.done,
          ),
        );
      },
    );
  }

  Widget _buildLayout({
    required BoxConstraints constraints,
    required _SurfaceAtlasPickerSource source,
    required ui.Image? atlasImage,
    required bool imageLoading,
  }) {
    final slotPane = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SurfaceSlotSchema(
          analysis: widget.analysis,
          preset: widget.preset,
          selectedRole: widget.selectedRole,
          selectedRoleAnimationId: widget.selectedRoleAnimationId,
          atlasImage: atlasImage,
          atlas: source.atlas,
          onRoleSelected: widget.onRoleSelected,
        ),
        const SizedBox(height: 10),
        _RoleDetail(
          preset: widget.preset,
          selectedRole: widget.selectedRole,
          selectedColumn: widget.selectedColumn,
          currentColumn: widget.analysis
              .columnByAnimationId(widget.selectedRoleAnimationId),
          atlasImage: atlasImage,
          atlas: source.atlas,
          canAssign:
              widget.onColumnAssigned != null && widget.selectedColumn != null,
          onAssign:
              widget.selectedColumn == null || widget.onColumnAssigned == null
                  ? null
                  : () => widget.onColumnAssigned!(widget.selectedColumn!),
        ),
      ],
    );

    final atlasPane = _RealAtlasPicker(
      analysis: widget.analysis,
      source: source,
      atlasImage: atlasImage,
      imageLoading: imageLoading,
      selectedRole: widget.selectedRole,
      selectedAnimationId: widget.selectedColumn?.animationId,
      selectedRoleAnimationId: widget.selectedRoleAnimationId,
      onColumnSelected: widget.onColumnSelected,
      onColumnAssigned: widget.onColumnAssigned,
    );

    if (constraints.maxWidth >= 900) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 350, child: slotPane),
          const SizedBox(width: 12),
          Expanded(child: atlasPane),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        slotPane,
        const SizedBox(height: 10),
        atlasPane,
      ],
    );
  }
}

class _SurfaceAtlasPickerSource {
  const _SurfaceAtlasPickerSource({
    required this.atlasIds,
    this.atlas,
    this.tileset,
    this.absolutePath,
    this.message,
  });

  final Set<String> atlasIds;
  final ProjectSurfaceAtlas? atlas;
  final ProjectTilesetEntry? tileset;
  final String? absolutePath;
  final String? message;

  bool get hasMultipleAtlases => atlasIds.length > 1;
}

_SurfaceAtlasPickerSource _resolveSurfaceAtlasPickerSource({
  required ProjectSurfaceCatalog catalog,
  required ProjectSurfacePreset preset,
  required String? projectRootPath,
  required List<ProjectTilesetEntry> projectTilesets,
}) {
  final animationIds = preset.variantAnimations.refs
      .map((ref) => ref.animationId)
      .where((id) => id.trim().isNotEmpty)
      .toSet();
  final atlasIds = <String>{};
  for (final animation in catalog.animations) {
    if (!animationIds.contains(animation.id)) {
      continue;
    }
    final firstFrame = animation.timeline.frames.first;
    atlasIds.add(firstFrame.tileRef.atlasId);
  }
  if (atlasIds.isEmpty) {
    return const _SurfaceAtlasPickerSource(
      atlasIds: <String>{},
      message:
          'Aucune animation liée ne permet de retrouver un atlas réel pour cette surface.',
    );
  }

  final atlasId = atlasIds.first;
  ProjectSurfaceAtlas? atlas;
  for (final candidate in catalog.atlases) {
    if (candidate.id == atlasId) {
      atlas = candidate;
      break;
    }
  }
  if (atlas == null) {
    return _SurfaceAtlasPickerSource(
      atlasIds: atlasIds,
      message: 'Atlas Surface introuvable : $atlasId.',
    );
  }

  ProjectTilesetEntry? tileset;
  for (final entry in projectTilesets) {
    if (entry.id == atlas.tilesetId) {
      tileset = entry;
      break;
    }
  }
  if (tileset == null) {
    return _SurfaceAtlasPickerSource(
      atlasIds: atlasIds,
      atlas: atlas,
      message:
          'Jeu d’images introuvable pour l’atlas ${atlas.name} (${atlas.tilesetId}).',
    );
  }

  final root = projectRootPath?.trim();
  final rel = tileset.relativePath.trim();
  if (root == null || root.isEmpty) {
    return _SurfaceAtlasPickerSource(
      atlasIds: atlasIds,
      atlas: atlas,
      tileset: tileset,
      message:
          'Projet sans dossier ouvert sur disque. Chemin attendu dans le manifeste : $rel.',
    );
  }
  if (rel.isEmpty) {
    return _SurfaceAtlasPickerSource(
      atlasIds: atlasIds,
      atlas: atlas,
      tileset: tileset,
      message:
          'Le jeu d’images ${tileset.name} n’a pas de chemin relatif dans le manifeste.',
    );
  }

  return _SurfaceAtlasPickerSource(
    atlasIds: atlasIds,
    atlas: atlas,
    tileset: tileset,
    absolutePath: p.normalize(p.join(root, rel)),
  );
}

class _NoAnimationsState extends StatelessWidget {
  const _NoAnimationsState({
    required this.subtle,
    required this.label,
  });

  final Color subtle;
  final Color label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context)
            .withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aucune animation disponible.',
            style: TextStyle(
              color: label,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Générez d’abord les animations depuis l’atlas.',
            style: TextStyle(color: subtle, fontSize: 10.5, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _MappingSummary extends StatelessWidget {
  const _MappingSummary({required this.analysis});

  final SurfaceStudioRoleMappingAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return _Panellet(
      key: const ValueKey('surface_role_mapping_summary'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Résumé du mapping',
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _MetricChip('Colonnes : ${analysis.columns.length}'),
              _MetricChip('Assignées : ${analysis.assignedColumnCount}'),
              _MetricChip('Non assignées : ${analysis.unassignedColumnCount}'),
              _MetricChip(
                'Doublons : ${analysis.duplicateAnimationCount}',
                color: analysis.duplicateAnimationCount > 0 ? _danger : _accent,
              ),
              _MetricChip(
                'Rôles manquants : ${analysis.missingRoleCount}',
                color: analysis.missingRoleCount > 0 ? _warning : _accent,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            analysis.duplicateAnimationCount > 0
                ? 'Un même extrait de colonne est utilisé par plusieurs rôles. Vérifiez que c’est volontaire.'
                : 'Chaque colonne assignée pointe vers un rôle unique.',
            style: TextStyle(color: subtle, fontSize: 10.5, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _SurfaceSlotSchema extends StatelessWidget {
  const _SurfaceSlotSchema({
    required this.analysis,
    required this.preset,
    required this.selectedRole,
    required this.selectedRoleAnimationId,
    required this.atlasImage,
    required this.atlas,
    required this.onRoleSelected,
  });

  final SurfaceStudioRoleMappingAnalysis analysis;
  final ProjectSurfacePreset preset;
  final SurfaceVariantRole selectedRole;
  final String? selectedRoleAnimationId;
  final ui.Image? atlasImage;
  final ProjectSurfaceAtlas? atlas;
  final ValueChanged<SurfaceVariantRole> onRoleSelected;

  static const List<SurfaceVariantRole> _mainSurfaceShape =
      <SurfaceVariantRole>[
    SurfaceVariantRole.cornerNW,
    SurfaceVariantRole.endNorth,
    SurfaceVariantRole.cornerNE,
    SurfaceVariantRole.endWest,
    SurfaceVariantRole.cross,
    SurfaceVariantRole.endEast,
    SurfaceVariantRole.cornerSW,
    SurfaceVariantRole.endSouth,
    SurfaceVariantRole.cornerSE,
  ];

  static const List<SurfaceVariantRole> _centerVariants = <SurfaceVariantRole>[
    SurfaceVariantRole.isolated,
    SurfaceVariantRole.horizontal,
    SurfaceVariantRole.vertical,
  ];

  static const List<SurfaceVariantRole> _junctionVariants =
      <SurfaceVariantRole>[
    SurfaceVariantRole.teeNorth,
    SurfaceVariantRole.teeEast,
    SurfaceVariantRole.teeSouth,
    SurfaceVariantRole.teeWest,
  ];

  static const List<SurfaceVariantRole> _innerCornerVariants =
      <SurfaceVariantRole>[
    SurfaceVariantRole.innerCornerNE,
    SurfaceVariantRole.innerCornerSE,
    SurfaceVariantRole.innerCornerSW,
    SurfaceVariantRole.innerCornerNW,
  ];

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return _Panellet(
      key: const ValueKey('surface_role_slot_schema'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Schéma des slots Surface',
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Cliquez un slot, puis une colonne',
            style: TextStyle(
              color: _accent,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Le slot représente la position logique de la tile dans une surface continue.',
            style: TextStyle(color: subtle, fontSize: 10.5, height: 1.35),
          ),
          const SizedBox(height: 8),
          Text(
            'Slot actif : ${surfaceStudioRoleMappingLabel(selectedRole)}',
            key: const ValueKey('surface_role_active_slot_label'),
            style: const TextStyle(
              color: _accent,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _SurfaceSlotGrid(
            roles: _mainSurfaceShape,
            columns: 3,
            analysis: analysis,
            preset: preset,
            selectedRole: selectedRole,
            selectedRoleAnimationId: selectedRoleAnimationId,
            atlasImage: atlasImage,
            atlas: atlas,
            onRoleSelected: onRoleSelected,
          ),
          const SizedBox(height: 10),
          Text(
            'Centre et continuités',
            style: TextStyle(
              color: label,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          _SurfaceSlotWrap(
            roles: _centerVariants,
            analysis: analysis,
            preset: preset,
            selectedRole: selectedRole,
            selectedRoleAnimationId: selectedRoleAnimationId,
            atlasImage: atlasImage,
            atlas: atlas,
            onRoleSelected: onRoleSelected,
          ),
          const SizedBox(height: 10),
          Text(
            'Jonctions et coins intérieurs',
            style: TextStyle(
              color: label,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          _SurfaceSlotWrap(
            roles: const <SurfaceVariantRole>[
              ..._junctionVariants,
              ..._innerCornerVariants,
            ],
            analysis: analysis,
            preset: preset,
            selectedRole: selectedRole,
            selectedRoleAnimationId: selectedRoleAnimationId,
            atlasImage: atlasImage,
            atlas: atlas,
            onRoleSelected: onRoleSelected,
          ),
        ],
      ),
    );
  }
}

class _SurfaceSlotGrid extends StatelessWidget {
  const _SurfaceSlotGrid({
    required this.roles,
    required this.columns,
    required this.analysis,
    required this.preset,
    required this.selectedRole,
    required this.selectedRoleAnimationId,
    required this.atlasImage,
    required this.atlas,
    required this.onRoleSelected,
  });

  final List<SurfaceVariantRole> roles;
  final int columns;
  final SurfaceStudioRoleMappingAnalysis analysis;
  final ProjectSurfacePreset preset;
  final SurfaceVariantRole selectedRole;
  final String? selectedRoleAnimationId;
  final ui.Image? atlasImage;
  final ProjectSurfaceAtlas? atlas;
  final ValueChanged<SurfaceVariantRole> onRoleSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 6.0;
        final available = constraints.maxWidth - (gap * (columns - 1));
        final cellWidth = available / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final role in roles)
              SizedBox(
                width: cellWidth,
                child: _SurfaceRoleSlot(
                  role: role,
                  column: _columnForRole(role),
                  atlasImage: atlasImage,
                  atlas: atlas,
                  selected: role == selectedRole,
                  isSelectedRoleAssignment:
                      selectedRole == role && selectedRoleAnimationId != null,
                  onTap: () => onRoleSelected(role),
                ),
              ),
          ],
        );
      },
    );
  }

  SurfaceStudioRoleMappingColumnOption? _columnForRole(
    SurfaceVariantRole role,
  ) {
    final animationId = role == selectedRole
        ? selectedRoleAnimationId
        : preset.animationIdForRole(role);
    return analysis.columnByAnimationId(animationId);
  }
}

class _SurfaceSlotWrap extends StatelessWidget {
  const _SurfaceSlotWrap({
    required this.roles,
    required this.analysis,
    required this.preset,
    required this.selectedRole,
    required this.selectedRoleAnimationId,
    required this.atlasImage,
    required this.atlas,
    required this.onRoleSelected,
  });

  final List<SurfaceVariantRole> roles;
  final SurfaceStudioRoleMappingAnalysis analysis;
  final ProjectSurfacePreset preset;
  final SurfaceVariantRole selectedRole;
  final String? selectedRoleAnimationId;
  final ui.Image? atlasImage;
  final ProjectSurfaceAtlas? atlas;
  final ValueChanged<SurfaceVariantRole> onRoleSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final role in roles)
          SizedBox(
            width: 112,
            child: _SurfaceRoleSlot(
              role: role,
              column: _columnForRole(role),
              atlasImage: atlasImage,
              atlas: atlas,
              selected: role == selectedRole,
              isSelectedRoleAssignment:
                  selectedRole == role && selectedRoleAnimationId != null,
              onTap: () => onRoleSelected(role),
            ),
          ),
      ],
    );
  }

  SurfaceStudioRoleMappingColumnOption? _columnForRole(
    SurfaceVariantRole role,
  ) {
    final animationId = role == selectedRole
        ? selectedRoleAnimationId
        : preset.animationIdForRole(role);
    return analysis.columnByAnimationId(animationId);
  }
}

class _SurfaceRoleSlot extends StatelessWidget {
  const _SurfaceRoleSlot({
    required this.role,
    required this.column,
    required this.atlasImage,
    required this.atlas,
    required this.selected,
    required this.isSelectedRoleAssignment,
    required this.onTap,
  });

  final SurfaceVariantRole role;
  final SurfaceStudioRoleMappingColumnOption? column;
  final ui.Image? atlasImage;
  final ProjectSurfaceAtlas? atlas;
  final bool selected;
  final bool isSelectedRoleAssignment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final linked = column != null || isSelectedRoleAssignment;
    final color = linked ? _accent : _warning;
    return GestureDetector(
      key: ValueKey('surface_role_slot_${role.name}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 74),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.20)
              : EditorChrome.elevatedPanelBackground(context)
                  .withValues(alpha: 0.56),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.90)
                : color.withValues(alpha: 0.34),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (column != null && atlasImage != null && atlas != null)
              _SurfaceColumnCropPreview(
                key: ValueKey('surface_role_real_crop_${role.name}'),
                image: atlasImage!,
                atlas: atlas!,
                column: column!,
                size: 34,
              )
            else
              _SurfaceRoleGlyph(role: role, selected: selected, linked: linked),
            const SizedBox(height: 5),
            Text(
              surfaceStudioRoleMappingLabel(role),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: label,
                fontSize: 9.6,
                fontWeight: FontWeight.w800,
                height: 1.12,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              column == null ? 'À lier' : 'Col ${column!.columnIndex}',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: column == null ? subtle : _accent,
                fontSize: 8.7,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurfaceRoleGlyph extends StatelessWidget {
  const _SurfaceRoleGlyph({
    required this.role,
    required this.selected,
    required this.linked,
  });

  final SurfaceVariantRole role;
  final bool selected;
  final bool linked;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 26,
      child: CustomPaint(
        painter: _SurfaceRoleGlyphPainter(
          role: role,
          selected: selected,
          linked: linked,
        ),
      ),
    );
  }
}

class _SurfaceRoleGlyphPainter extends CustomPainter {
  const _SurfaceRoleGlyphPainter({
    required this.role,
    required this.selected,
    required this.linked,
  });

  final SurfaceVariantRole role;
  final bool selected;
  final bool linked;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.24;
    final active = selected ? _accent : _accent.withValues(alpha: 0.82);
    final inactive = linked
        ? _accent.withValues(alpha: 0.24)
        : _warning.withValues(alpha: 0.22);
    final activePaint = Paint()
      ..color = active
      ..strokeWidth = selected ? 3 : 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final inactivePaint = Paint()
      ..color = inactive
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..color = (linked ? _accent : _warning).withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, fillPaint);
    canvas.drawCircle(center, radius, inactivePaint);

    final connections = _surfaceRoleConnections(role);
    final north = Offset(center.dx, 1.5);
    final east = Offset(size.width - 1.5, center.dy);
    final south = Offset(center.dx, size.height - 1.5);
    final west = Offset(1.5, center.dy);

    void drawArm(bool enabled, Offset target) {
      canvas.drawLine(center, target, enabled ? activePaint : inactivePaint);
    }

    drawArm(connections.north, north);
    drawArm(connections.east, east);
    drawArm(connections.south, south);
    drawArm(connections.west, west);

    final notch = _surfaceInnerCornerAlignment(role);
    if (notch != null) {
      final notchCenter = Offset(
        center.dx + notch.dx * radius * 1.35,
        center.dy + notch.dy * radius * 1.35,
      );
      canvas.drawCircle(
        notchCenter,
        4,
        Paint()
          ..color = _danger.withValues(alpha: 0.60)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SurfaceRoleGlyphPainter oldDelegate) {
    return oldDelegate.role != role ||
        oldDelegate.selected != selected ||
        oldDelegate.linked != linked;
  }
}

class _ColumnGallery extends StatelessWidget {
  const _ColumnGallery({
    required this.analysis,
    required this.selectedRole,
    required this.selectedAnimationId,
    required this.selectedRoleAnimationId,
    required this.onColumnSelected,
    required this.onColumnAssigned,
  });

  final SurfaceStudioRoleMappingAnalysis analysis;
  final SurfaceVariantRole selectedRole;
  final String? selectedAnimationId;
  final String? selectedRoleAnimationId;
  final ValueChanged<SurfaceStudioRoleMappingColumnOption> onColumnSelected;
  final ValueChanged<SurfaceStudioRoleMappingColumnOption>? onColumnAssigned;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return _Panellet(
      key: const ValueKey('surface_role_column_gallery'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Galerie des colonnes',
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cliquez une colonne pour l’assigner au slot actif : ${surfaceStudioRoleMappingLabel(selectedRole)}.',
            style: TextStyle(color: subtle, fontSize: 10.5, height: 1.35),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final cardWidth = width >= 248 ? (width - 8) / 2 : width;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final column in analysis.columns)
                    SizedBox(
                      width: cardWidth,
                      child: _ColumnCard(
                        column: column,
                        selected: column.animationId == selectedAnimationId,
                        assignedToSelectedRole:
                            column.animationId == selectedRoleAnimationId,
                        onTap: () {
                          onColumnSelected(column);
                          onColumnAssigned?.call(column);
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RealAtlasPicker extends StatefulWidget {
  const _RealAtlasPicker({
    required this.analysis,
    required this.source,
    required this.atlasImage,
    required this.imageLoading,
    required this.selectedRole,
    required this.selectedAnimationId,
    required this.selectedRoleAnimationId,
    required this.onColumnSelected,
    required this.onColumnAssigned,
  });

  final SurfaceStudioRoleMappingAnalysis analysis;
  final _SurfaceAtlasPickerSource source;
  final ui.Image? atlasImage;
  final bool imageLoading;
  final SurfaceVariantRole selectedRole;
  final String? selectedAnimationId;
  final String? selectedRoleAnimationId;
  final ValueChanged<SurfaceStudioRoleMappingColumnOption> onColumnSelected;
  final ValueChanged<SurfaceStudioRoleMappingColumnOption>? onColumnAssigned;

  @override
  State<_RealAtlasPicker> createState() => _RealAtlasPickerState();
}

class _RealAtlasPickerState extends State<_RealAtlasPicker> {
  int? _selectedColumnIndex;
  String? _lastClickMessage;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final image = widget.atlasImage;
    final atlas = widget.source.atlas;

    return _Panellet(
      key: const ValueKey('surface_real_atlas_picker'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Atlas réel cliquable',
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Étape 2 : cliquez une colonne dans l’image atlas réelle pour l’assigner au slot actif : ${surfaceStudioRoleMappingLabel(widget.selectedRole)}.',
            style: TextStyle(color: subtle, fontSize: 10.5, height: 1.35),
          ),
          if (widget.source.hasMultipleAtlases) ...[
            const SizedBox(height: 6),
            Text(
              'Plusieurs atlas sont référencés par cette surface. V0 affiche l’atlas ${atlas?.name ?? widget.source.atlasIds.first}.',
              style: const TextStyle(
                color: _warning,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (widget.imageLoading)
            _RealAtlasMessage(
              title: 'Chargement de l’image atlas…',
              body: widget.source.absolutePath ?? '',
            )
          else if (image != null && atlas != null)
            _AtlasImageHitArea(
              image: image,
              atlas: atlas,
              analysis: widget.analysis,
              selectedColumnIndex: _selectedColumnIndex,
              selectedAnimationId: widget.selectedAnimationId,
              selectedRoleAnimationId: widget.selectedRoleAnimationId,
              onColumnTapped: _assignColumn,
            )
          else ...[
            _RealAtlasMessage(
              title: 'Image atlas réelle indisponible',
              body: widget.source.message ??
                  'Le fichier image n’a pas pu être chargé : ${widget.source.absolutePath ?? 'chemin indisponible'}.',
            ),
            const SizedBox(height: 10),
            _ColumnGallery(
              analysis: widget.analysis,
              selectedRole: widget.selectedRole,
              selectedAnimationId: widget.selectedAnimationId,
              selectedRoleAnimationId: widget.selectedRoleAnimationId,
              onColumnSelected: widget.onColumnSelected,
              onColumnAssigned: widget.onColumnAssigned,
            ),
          ],
          if (_lastClickMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _lastClickMessage!,
              key: const ValueKey('surface_real_atlas_click_message'),
              style: TextStyle(
                color: _lastClickMessage!.startsWith('Colonne assignée')
                    ? _accent
                    : _warning,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _assignColumn(int columnIndex) {
    final atlas = widget.source.atlas;
    if (atlas == null) {
      return;
    }
    SurfaceStudioRoleMappingColumnOption? match;
    for (final column in widget.analysis.columns) {
      if (column.atlasId == atlas.id && column.columnIndex == columnIndex) {
        match = column;
        break;
      }
    }
    setState(() {
      _selectedColumnIndex = columnIndex;
      _lastClickMessage = match == null
          ? 'Col $columnIndex ne correspond à aucune animation générée.'
          : 'Colonne assignée : Col $columnIndex → ${surfaceStudioRoleMappingLabel(widget.selectedRole)}.';
    });
    if (match == null) {
      return;
    }
    widget.onColumnSelected(match);
    widget.onColumnAssigned?.call(match);
  }
}

class _RealAtlasMessage extends StatelessWidget {
  const _RealAtlasMessage({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return Container(
      key: const ValueKey('surface_real_atlas_fallback'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _warning.withValues(alpha: 0.34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: label,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: TextStyle(color: subtle, fontSize: 10.5, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _AtlasImageHitArea extends StatelessWidget {
  const _AtlasImageHitArea({
    required this.image,
    required this.atlas,
    required this.analysis,
    required this.selectedColumnIndex,
    required this.selectedAnimationId,
    required this.selectedRoleAnimationId,
    required this.onColumnTapped,
  });

  final ui.Image image;
  final ProjectSurfaceAtlas atlas;
  final SurfaceStudioRoleMappingAnalysis analysis;
  final int? selectedColumnIndex;
  final String? selectedAnimationId;
  final String? selectedRoleAnimationId;
  final ValueChanged<int> onColumnTapped;

  @override
  Widget build(BuildContext context) {
    final columns = atlas.geometry.gridSize.columns;
    final aspect = image.width / image.height;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth <= 0 ? 1.0 : constraints.maxWidth;
        const maxHeight = 440.0;
        var renderWidth = maxWidth;
        var renderHeight = renderWidth / aspect;
        if (renderHeight > maxHeight) {
          renderHeight = maxHeight;
          renderWidth = renderHeight * aspect;
        }
        renderWidth = renderWidth.clamp(1.0, maxWidth).toDouble();
        renderHeight = renderHeight.clamp(1.0, maxHeight).toDouble();

        void tapAt(Offset localPosition) {
          final dx = localPosition.dx.clamp(0.0, renderWidth - 0.0001);
          final column =
              (dx / (renderWidth / columns)).floor().clamp(0, columns - 1);
          onColumnTapped(column);
        }

        return Center(
          child: SizedBox(
            key: const ValueKey('surface_real_atlas_hit_area'),
            width: renderWidth,
            height: renderHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) => tapAt(details.localPosition),
              child: CustomPaint(
                key: const ValueKey('surface_real_atlas_grid'),
                painter: _SurfaceAtlasMappingPainter(
                  image: image,
                  atlas: atlas,
                  analysis: analysis,
                  selectedColumnIndex: selectedColumnIndex,
                  selectedAnimationId: selectedAnimationId,
                  selectedRoleAnimationId: selectedRoleAnimationId,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SurfaceAtlasMappingPainter extends CustomPainter {
  const _SurfaceAtlasMappingPainter({
    required this.image,
    required this.atlas,
    required this.analysis,
    required this.selectedColumnIndex,
    required this.selectedAnimationId,
    required this.selectedRoleAnimationId,
  });

  final ui.Image image;
  final ProjectSurfaceAtlas atlas;
  final SurfaceStudioRoleMappingAnalysis analysis;
  final int? selectedColumnIndex;
  final String? selectedAnimationId;
  final String? selectedRoleAnimationId;

  @override
  void paint(Canvas canvas, Size size) {
    final source = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dest = Offset.zero & size;
    canvas.drawImageRect(
      image,
      source,
      dest,
      Paint()..filterQuality = FilterQuality.none,
    );

    final columns = atlas.geometry.gridSize.columns;
    final rows = atlas.geometry.gridSize.rows;
    final cellWidth = size.width / columns;
    final cellHeight = size.height / rows;

    for (final column in analysis.columns) {
      if (column.atlasId != atlas.id) {
        continue;
      }
      final left = column.columnIndex * cellWidth;
      final rect = Rect.fromLTWH(left, 0, cellWidth, size.height);
      final assignedToSelectedRole =
          column.animationId == selectedRoleAnimationId;
      final selected = column.animationId == selectedAnimationId ||
          column.columnIndex == selectedColumnIndex;
      final fillColor = assignedToSelectedRole
          ? _accent.withValues(alpha: 0.26)
          : column.hasDuplicateAssignment
              ? _danger.withValues(alpha: 0.18)
              : column.isAssigned
                  ? _accent.withValues(alpha: 0.13)
                  : _warning.withValues(alpha: 0.09);
      canvas.drawRect(rect, Paint()..color = fillColor);
      if (selected) {
        canvas.drawRect(
          rect.deflate(1),
          Paint()
            ..color = _accent
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke,
        );
      }

      final tp = TextPainter(
        text: TextSpan(
          text: 'Col ${column.columnIndex}',
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(color: Color(0xCC000000), blurRadius: 4),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: math.max(24, cellWidth - 4));
      tp.paint(canvas, Offset(left + 4, 4));
    }

    final gridPaint = Paint()
      ..color = const Color(0xCCFFFFFF)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (var i = 0; i <= columns; i++) {
      final x = i * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var j = 0; j <= rows; j++) {
      final y = j * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SurfaceAtlasMappingPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.atlas != atlas ||
        oldDelegate.analysis != analysis ||
        oldDelegate.selectedColumnIndex != selectedColumnIndex ||
        oldDelegate.selectedAnimationId != selectedAnimationId ||
        oldDelegate.selectedRoleAnimationId != selectedRoleAnimationId;
  }
}

class _ColumnCard extends StatelessWidget {
  const _ColumnCard({
    required this.column,
    required this.selected,
    required this.assignedToSelectedRole,
    required this.onTap,
  });

  final SurfaceStudioRoleMappingColumnOption column;
  final bool selected;
  final bool assignedToSelectedRole;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final statusColor = assignedToSelectedRole
        ? _accent
        : column.hasDuplicateAssignment
            ? _danger
            : column.isAssigned
                ? _accent
                : _warning;
    return GestureDetector(
      key: ValueKey('surface_role_column_card_${column.animationId}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected
              ? _accent.withValues(alpha: 0.15)
              : EditorChrome.elevatedPanelBackground(context)
                  .withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? _accent.withValues(alpha: 0.82)
                : statusColor.withValues(alpha: 0.35),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Col ${column.columnIndex}',
                  style: TextStyle(
                    color: label,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                _StatusPill(
                  label: column.hasDuplicateAssignment
                      ? 'Doublon'
                      : assignedToSelectedRole
                          ? 'Assigné au slot actif'
                          : column.isAssigned
                              ? 'Assignée'
                              : 'Non assignée',
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 7),
            _ColumnMiniPreview(column: column),
            const SizedBox(height: 7),
            Text(
              column.animation.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: label,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${column.frameCount} frame(s) · ${column.atlasId}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: subtle, fontSize: 9.5, height: 1.2),
            ),
            if (column.assignedRoles.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                column.assignedRoles
                    .map(surfaceStudioRoleMappingLabel)
                    .join(', '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ColumnMiniPreview extends StatelessWidget {
  const _ColumnMiniPreview({required this.column});

  final SurfaceStudioRoleMappingColumnOption column;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    return Center(
      child: Container(
        key: ValueKey('surface_role_column_preview_${column.animationId}'),
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: _accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _accent.withValues(alpha: 0.42)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'C${column.columnIndex}',
              style: const TextStyle(
                color: _accent,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 2,
              runSpacing: 2,
              children: [
                for (var i = 0; i < column.frameCount.clamp(1, 6); i++)
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.30 + i * 0.07),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              'Frame 1',
              style: TextStyle(color: subtle, fontSize: 8.5, height: 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurfaceColumnCropPreview extends StatelessWidget {
  const _SurfaceColumnCropPreview({
    required this.image,
    required this.atlas,
    required this.column,
    required this.size,
    super.key,
  });

  final ui.Image image;
  final ProjectSurfaceAtlas atlas;
  final SurfaceStudioRoleMappingColumnOption column;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CustomPaint(
          painter: _SurfaceColumnCropPainter(
            image: image,
            atlas: atlas,
            column: column,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _SurfaceColumnCropPainter extends CustomPainter {
  const _SurfaceColumnCropPainter({
    required this.image,
    required this.atlas,
    required this.column,
  });

  final ui.Image image;
  final ProjectSurfaceAtlas atlas;
  final SurfaceStudioRoleMappingColumnOption column;

  @override
  void paint(Canvas canvas, Size size) {
    final tileWidth = atlas.geometry.tileSize.width.toDouble();
    final tileHeight = atlas.geometry.tileSize.height.toDouble();
    final source = Rect.fromLTWH(
      column.columnIndex * tileWidth,
      column.rowIndex * tileHeight,
      tileWidth,
      tileHeight,
    );
    canvas.drawImageRect(
      image,
      source,
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.none,
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = _accent.withValues(alpha: 0.85)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _SurfaceColumnCropPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.atlas != atlas ||
        oldDelegate.column != column;
  }
}

class _RoleDetail extends StatelessWidget {
  const _RoleDetail({
    required this.preset,
    required this.selectedRole,
    required this.selectedColumn,
    required this.currentColumn,
    required this.atlasImage,
    required this.atlas,
    required this.canAssign,
    this.onAssign,
  });

  final ProjectSurfacePreset preset;
  final SurfaceVariantRole selectedRole;
  final SurfaceStudioRoleMappingColumnOption? selectedColumn;
  final SurfaceStudioRoleMappingColumnOption? currentColumn;
  final ui.Image? atlasImage;
  final ProjectSurfaceAtlas? atlas;
  final bool canAssign;
  final VoidCallback? onAssign;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final selected = selectedColumn;
    final current = currentColumn;
    return _Panellet(
      key: const ValueKey('surface_role_detail_panel'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Détail du rôle',
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Slot actif : ${surfaceStudioRoleMappingLabel(selectedRole)}',
            style: TextStyle(
              color: label,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _roleExplanation(selectedRole),
            style: TextStyle(color: subtle, fontSize: 10.5, height: 1.35),
          ),
          const SizedBox(height: 10),
          SurfaceStudioRoleMappingPreview(
            preset: preset,
            selectedRole: selectedRole,
            onRoleSelected: (_) {},
          ),
          if (current != null && atlasImage != null && atlas != null) ...[
            const SizedBox(height: 10),
            Center(
              child: _SurfaceColumnCropPreview(
                key: const ValueKey('surface_selected_role_real_crop'),
                image: atlasImage!,
                atlas: atlas!,
                column: current,
                size: 72,
              ),
            ),
          ],
          const SizedBox(height: 10),
          _DetailLine(
            label: 'Animation actuelle du rôle',
            value: current == null
                ? 'Aucune colonne liée'
                : 'Col ${current.columnIndex} — ${current.animation.name}',
          ),
          _DetailLine(
            label: 'Colonne sélectionnée',
            value: selected == null
                ? 'Aucune'
                : 'Col ${selected.columnIndex} — ${selected.animation.name}',
          ),
          const SizedBox(height: 10),
          CupertinoButton(
            key: const ValueKey('surface_role_assign_column'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: _accent.withValues(alpha: 0.72),
            disabledColor:
                EditorChrome.islandFillElevated(context).withValues(alpha: 0.6),
            onPressed: canAssign ? onAssign : null,
            child: const Text('Assigner cette colonne au rôle'),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final labelColor = EditorChrome.primaryLabel(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label : $value',
        style: TextStyle(
          color: labelColor,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip(this.label, {this.color = _accent});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: EditorChrome.primaryLabel(context),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Panellet extends StatelessWidget {
  const _Panellet({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context)
            .withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: EditorChrome.editorIslandRim(context)),
      ),
      child: child,
    );
  }
}

({bool north, bool east, bool south, bool west}) _surfaceRoleConnections(
  SurfaceVariantRole role,
) {
  return switch (role) {
    SurfaceVariantRole.isolated => (
        north: false,
        east: false,
        south: false,
        west: false,
      ),
    SurfaceVariantRole.endNorth => (
        north: true,
        east: false,
        south: false,
        west: false,
      ),
    SurfaceVariantRole.endEast => (
        north: false,
        east: true,
        south: false,
        west: false,
      ),
    SurfaceVariantRole.endSouth => (
        north: false,
        east: false,
        south: true,
        west: false,
      ),
    SurfaceVariantRole.endWest => (
        north: false,
        east: false,
        south: false,
        west: true,
      ),
    SurfaceVariantRole.horizontal => (
        north: false,
        east: true,
        south: false,
        west: true,
      ),
    SurfaceVariantRole.vertical => (
        north: true,
        east: false,
        south: true,
        west: false,
      ),
    SurfaceVariantRole.cornerNE => (
        north: true,
        east: true,
        south: false,
        west: false,
      ),
    SurfaceVariantRole.cornerSE => (
        north: false,
        east: true,
        south: true,
        west: false,
      ),
    SurfaceVariantRole.cornerSW => (
        north: false,
        east: false,
        south: true,
        west: true,
      ),
    SurfaceVariantRole.cornerNW => (
        north: true,
        east: false,
        south: false,
        west: true,
      ),
    SurfaceVariantRole.innerCornerNE => (
        north: true,
        east: true,
        south: true,
        west: true,
      ),
    SurfaceVariantRole.innerCornerSE => (
        north: true,
        east: true,
        south: true,
        west: true,
      ),
    SurfaceVariantRole.innerCornerSW => (
        north: true,
        east: true,
        south: true,
        west: true,
      ),
    SurfaceVariantRole.innerCornerNW => (
        north: true,
        east: true,
        south: true,
        west: true,
      ),
    SurfaceVariantRole.teeNorth => (
        north: true,
        east: true,
        south: false,
        west: true,
      ),
    SurfaceVariantRole.teeEast => (
        north: true,
        east: true,
        south: true,
        west: false,
      ),
    SurfaceVariantRole.teeSouth => (
        north: false,
        east: true,
        south: true,
        west: true,
      ),
    SurfaceVariantRole.teeWest => (
        north: true,
        east: false,
        south: true,
        west: true,
      ),
    SurfaceVariantRole.cross => (
        north: true,
        east: true,
        south: true,
        west: true,
      ),
  };
}

Offset? _surfaceInnerCornerAlignment(SurfaceVariantRole role) {
  return switch (role) {
    SurfaceVariantRole.innerCornerNE => const Offset(1, -1),
    SurfaceVariantRole.innerCornerSE => const Offset(1, 1),
    SurfaceVariantRole.innerCornerSW => const Offset(-1, 1),
    SurfaceVariantRole.innerCornerNW => const Offset(-1, -1),
    _ => null,
  };
}

String _roleExplanation(SurfaceVariantRole role) {
  switch (role) {
    case SurfaceVariantRole.isolated:
      return 'Plein : tuile utilisée pour une cellule seule ou un centre simple sans voisin compatible.';
    case SurfaceVariantRole.endNorth:
      return 'Bord haut : limite supérieure d’une zone de surface.';
    case SurfaceVariantRole.endEast:
      return 'Bord droit : limite droite d’une zone de surface.';
    case SurfaceVariantRole.endSouth:
      return 'Bord bas : limite inférieure d’une zone de surface.';
    case SurfaceVariantRole.endWest:
      return 'Bord gauche : limite gauche d’une zone de surface.';
    case SurfaceVariantRole.horizontal:
      return 'Horizontal : segment qui continue vers la gauche et la droite.';
    case SurfaceVariantRole.vertical:
      return 'Vertical : segment qui continue vers le haut et le bas.';
    case SurfaceVariantRole.cornerNE:
      return 'Coin haut droit : angle extérieur supérieur droit.';
    case SurfaceVariantRole.cornerSE:
      return 'Coin bas droit : angle extérieur inférieur droit.';
    case SurfaceVariantRole.cornerSW:
      return 'Coin bas gauche : angle extérieur inférieur gauche.';
    case SurfaceVariantRole.cornerNW:
      return 'Coin haut gauche : angle extérieur supérieur gauche.';
    case SurfaceVariantRole.innerCornerNE:
      return 'Coin intérieur haut droit : creux interne orienté vers le haut droit.';
    case SurfaceVariantRole.innerCornerSE:
      return 'Coin intérieur bas droit : creux interne orienté vers le bas droit.';
    case SurfaceVariantRole.innerCornerSW:
      return 'Coin intérieur bas gauche : creux interne orienté vers le bas gauche.';
    case SurfaceVariantRole.innerCornerNW:
      return 'Coin intérieur haut gauche : creux interne orienté vers le haut gauche.';
    case SurfaceVariantRole.teeNorth:
      return 'Jonction T haut : branche qui rejoint gauche, droite et haut.';
    case SurfaceVariantRole.teeEast:
      return 'Jonction T droite : branche qui rejoint haut, bas et droite.';
    case SurfaceVariantRole.teeSouth:
      return 'Jonction T bas : branche qui rejoint gauche, droite et bas.';
    case SurfaceVariantRole.teeWest:
      return 'Jonction T gauche : branche qui rejoint haut, bas et gauche.';
    case SurfaceVariantRole.cross:
      return 'Croix : jonction centrale multi-branches ou centre d’une grande zone continue.';
  }
}

```

### `packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_preview.dart`

```dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'surface_studio_atlas_grid_overlay.dart';
import 'surface_studio_vertical_atlas_role_mapping.dart';

/// Rectangle source (pixels atlas) pour une frame d’une colonne — preview locale uniquement.
@immutable
class SurfaceStudioVerticalAtlasAnimationSourceRect {
  const SurfaceStudioVerticalAtlasAnimationSourceRect({
    required this.sourceX,
    required this.sourceY,
    required this.sourceWidth,
    required this.sourceHeight,
  });

  final int sourceX;
  final int sourceY;
  final int sourceWidth;
  final int sourceHeight;
}

/// Résumé affichable pour la preview locale (aucune persistance catalogue).
@immutable
class SurfaceStudioVerticalAtlasAnimationPreviewSummary {
  const SurfaceStudioVerticalAtlasAnimationPreviewSummary({
    required this.columnIndex,
    required this.role,
    required this.frameCount,
    required this.currentFrameIndex,
    required this.tileWidth,
    required this.tileHeight,
    required this.sourceRect,
  });

  final int columnIndex;
  final SurfaceVariantRole role;
  final int frameCount;
  final int currentFrameIndex;
  final int tileWidth;
  final int tileHeight;
  final SurfaceStudioVerticalAtlasAnimationSourceRect sourceRect;
}

/// Calcule le rectangle source ; [frameIndex] est borné puis cyclé sur [0, frameCount-1].
SurfaceStudioVerticalAtlasAnimationPreviewSummary?
    surfaceStudioVerticalAtlasAnimationPreviewSummary({
  required int columnIndex,
  required SurfaceVariantRole role,
  required int frameIndex,
  required int tileWidth,
  required int tileHeight,
  required int rows,
}) {
  if (tileWidth <= 0 || tileHeight <= 0 || rows <= 0) {
    return null;
  }
  final frameCount = rows;
  final idx = frameIndex % frameCount;
  final sx = columnIndex * tileWidth;
  final sy = idx * tileHeight;
  return SurfaceStudioVerticalAtlasAnimationPreviewSummary(
    columnIndex: columnIndex,
    role: role,
    frameCount: frameCount,
    currentFrameIndex: idx,
    tileWidth: tileWidth,
    tileHeight: tileHeight,
    sourceRect: SurfaceStudioVerticalAtlasAnimationSourceRect(
      sourceX: sx,
      sourceY: sy,
      sourceWidth: tileWidth,
      sourceHeight: tileHeight,
    ),
  );
}

/// Dessine un crop de [image] vers la taille du canvas (preview locale).
class SurfaceStudioAtlasFrameCropPainter extends CustomPainter {
  SurfaceStudioAtlasFrameCropPainter({
    required this.image,
    required this.srcRect,
  });

  final ui.Image image;
  final Rect srcRect;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(
      image,
      srcRect,
      dst,
      // Surface Studio affiche des extraits d'atlas pixel-art : le filtre
      // nearest-neighbor garde la tuile nette au lieu de la lisser/étirer.
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(covariant SurfaceStudioAtlasFrameCropPainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.srcRect != srcRect;
  }
}

/// Preview locale des frames d’une colonne mappée — ne crée aucune animation catalogue.
class SurfaceStudioVerticalAtlasAnimationPreview extends StatefulWidget {
  const SurfaceStudioVerticalAtlasAnimationPreview({
    super.key,
    required this.label,
    required this.subtle,
    required this.mappingDraft,
    required this.tileWidth,
    required this.tileHeight,
    required this.columns,
    required this.rows,
    this.resolvedImagePath,
  });

  static const ValueKey<String> sectionKey =
      ValueKey<String>('surface_studio_vertical_atlas_animation_preview');

  final Color label;
  final Color subtle;
  final SurfaceStudioColumnRoleMappingDraft mappingDraft;
  final int? tileWidth;
  final int? tileHeight;
  final int? columns;
  final int? rows;
  final String? resolvedImagePath;

  @override
  State<SurfaceStudioVerticalAtlasAnimationPreview> createState() =>
      _SurfaceStudioVerticalAtlasAnimationPreviewState();
}

class _SurfaceStudioVerticalAtlasAnimationPreviewState
    extends State<SurfaceStudioVerticalAtlasAnimationPreview> {
  static const int _msPerFrame = 120;

  int? _selectedColumn;
  int _frameIndex = 0;
  bool _playing = false;
  Timer? _playTimer;
  ui.Image? _decoded;
  Uint8List? _bytes;
  String? _cachedPath;

  @override
  void dispose() {
    _playTimer?.cancel();
    _decoded?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(
      covariant SurfaceStudioVerticalAtlasAnimationPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    final pathChanged = widget.resolvedImagePath != oldWidget.resolvedImagePath;
    final draftChanged = widget.mappingDraft != oldWidget.mappingDraft;
    final layoutChanged = widget.tileWidth != oldWidget.tileWidth ||
        widget.tileHeight != oldWidget.tileHeight ||
        widget.rows != oldWidget.rows ||
        widget.columns != oldWidget.columns;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (pathChanged) {
        _reloadImageBytes();
      }
      if (pathChanged || draftChanged || layoutChanged) {
        _syncSelectedColumn();
        if (layoutChanged) {
          final r = widget.rows;
          if (r != null && r > 0) {
            setState(() {
              _frameIndex = _frameIndex % r;
            });
          }
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _reloadImageBytes();
      _syncSelectedColumn();
    });
  }

  void _syncSelectedColumn() {
    final assigned = widget.mappingDraft.assignments
        .where((a) => a.role != null)
        .map((a) => a.columnIndex)
        .toList()
      ..sort();
    if (assigned.isEmpty) {
      if (_selectedColumn != null) {
        setState(() {
          _selectedColumn = null;
          _frameIndex = 0;
        });
      }
      return;
    }
    if (_selectedColumn == null || !assigned.contains(_selectedColumn)) {
      setState(() {
        _selectedColumn = assigned.first;
        _frameIndex = 0;
      });
    }
  }

  void _reloadImageBytes() {
    final p = widget.resolvedImagePath?.trim();
    if (p == null || p.isEmpty) {
      if (_cachedPath != null || _bytes != null) {
        setState(() {
          _cachedPath = null;
          _bytes = null;
          _decoded?.dispose();
          _decoded = null;
        });
      }
      return;
    }
    if (_cachedPath == p && _bytes != null) {
      return;
    }
    _cachedPath = p;
    try {
      final b = File(p).readAsBytesSync();
      setState(() {
        _bytes = b;
        _decoded?.dispose();
        _decoded = null;
      });
      ui.decodeImageFromList(b, (ui.Image img) {
        if (!mounted) {
          img.dispose();
          return;
        }
        setState(() {
          _decoded?.dispose();
          _decoded = img;
        });
      });
    } catch (_) {
      setState(() {
        _bytes = null;
        _decoded?.dispose();
        _decoded = null;
      });
    }
  }

  /// Fond du menu : assez sombre pour garder [widget.label] lisible (évite chips M3 clairs).
  Color _columnPickerMenuBackground(BuildContext context) => Color.alphaBlend(
        Colors.black.withValues(alpha: 0.42),
        EditorChrome.islandFillElevated(context),
      );

  Color _columnPickerFieldFill(BuildContext context) => Color.alphaBlend(
        Colors.black.withValues(alpha: 0.28),
        EditorChrome.islandFillElevated(context),
      );

  void _togglePlay() {
    if (_playing) {
      _playTimer?.cancel();
      setState(() => _playing = false);
      return;
    }
    final tw = widget.tileWidth;
    final th = widget.tileHeight;
    final r = widget.rows;
    if (tw == null || th == null || r == null || r <= 0) {
      return;
    }
    setState(() => _playing = true);
    _playTimer?.cancel();
    _playTimer = Timer.periodic(const Duration(milliseconds: _msPerFrame), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _frameIndex = (_frameIndex + 1) % r;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final gridOk = surfaceStudioAtlasGridOverlayDraftValid(
      widget.tileWidth,
      widget.tileHeight,
      widget.columns,
      widget.rows,
    );
    final tw = widget.tileWidth;
    final th = widget.tileHeight;
    final rws = widget.rows;

    return Container(
      key: SurfaceStudioVerticalAtlasAnimationPreview.sectionKey,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Aperçu animation par colonne',
            style: TextStyle(
              color: widget.label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          if (!gridOk) ...[
            Text(
              'Corrigez la grille avant de prévisualiser une animation.',
              style:
                  TextStyle(color: widget.subtle, fontSize: 11, height: 1.35),
            ),
          ] else if (widget.mappingDraft.assignments
              .where((a) => a.role != null)
              .isEmpty) ...[
            Text(
              'Assignez un rôle à une colonne pour prévisualiser son animation.',
              style:
                  TextStyle(color: widget.subtle, fontSize: 11, height: 1.35),
            ),
          ] else ...[
            _buildControls(context, tw!, th!, rws!),
          ],
        ],
      ),
    );
  }

  Widget _buildControls(
    BuildContext context,
    int tw,
    int th,
    int rws,
  ) {
    final sel = _selectedColumn;
    if (sel == null) {
      return const SizedBox.shrink();
    }
    final role = widget.mappingDraft.roleForColumn(sel);
    if (role == null) {
      return const SizedBox.shrink();
    }
    final summary = surfaceStudioVerticalAtlasAnimationPreviewSummary(
      columnIndex: sel,
      role: role,
      frameIndex: _frameIndex,
      tileWidth: tw,
      tileHeight: th,
      rows: rws,
    );
    if (summary == null) {
      return const SizedBox.shrink();
    }
    final sr = summary.sourceRect;
    final assigned = widget.mappingDraft.assignments
        .where((a) => a.role != null)
        .toList()
      ..sort((a, b) => a.columnIndex.compareTo(b.columnIndex));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Rôle : ${SurfaceStudioRoleLabels.labelForRole(role)}',
          style: TextStyle(color: widget.label, fontSize: 11.5, height: 1.35),
        ),
        Text(
          'Frames : ${summary.frameCount}',
          style: TextStyle(color: widget.label, fontSize: 11.5, height: 1.35),
        ),
        Text(
          'Frame courante : ${summary.currentFrameIndex + 1} / ${summary.frameCount}',
          style: TextStyle(color: widget.label, fontSize: 11.5, height: 1.35),
        ),
        Text(
          'Durée par frame : $_msPerFrame ms',
          style: TextStyle(color: widget.subtle, fontSize: 11, height: 1.35),
        ),
        const SizedBox(height: 6),
        Text(
          'Colonne à prévisualiser',
          style: TextStyle(
              color: widget.label, fontSize: 11, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          'Choisissez une colonne déjà reliée à un rôle (liste déroulante).',
          style: TextStyle(color: widget.subtle, fontSize: 10, height: 1.3),
        ),
        const SizedBox(height: 6),
        InputDecorator(
          decoration: InputDecoration(
            filled: true,
            fillColor: _columnPickerFieldFill(context),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: widget.label.withValues(alpha: 0.35),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: widget.label.withValues(alpha: 0.28),
              ),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: sel,
              isExpanded: true,
              isDense: true,
              dropdownColor: _columnPickerMenuBackground(context),
              iconEnabledColor: widget.label,
              iconDisabledColor: widget.subtle,
              style: TextStyle(color: widget.label, fontSize: 12, height: 1.25),
              items: [
                for (final a in assigned)
                  DropdownMenuItem<int>(
                    value: a.columnIndex,
                    child: Text(
                      'Colonne ${a.columnIndex} — ${SurfaceStudioRoleLabels.labelForRole(a.role!)}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: widget.label, fontSize: 12),
                    ),
                  ),
              ],
              onChanged: (v) {
                if (v == null) {
                  return;
                }
                setState(() {
                  _selectedColumn = v;
                  _frameIndex = 0;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          key: const ValueKey('surface_animation_preview_actions'),
          spacing: 8,
          runSpacing: 6,
          children: [
            OutlinedButton(
              onPressed: rws <= 0
                  ? null
                  : () {
                      setState(() {
                        _frameIndex = (_frameIndex - 1 + rws) % rws;
                      });
                    },
              child: const Text('Frame précédente'),
            ),
            OutlinedButton(
              onPressed: rws <= 0
                  ? null
                  : () {
                      setState(() {
                        _frameIndex = (_frameIndex + 1) % rws;
                      });
                    },
              child: const Text('Frame suivante'),
            ),
            OutlinedButton(
              onPressed: rws <= 0 ? null : _togglePlay,
              child: Text(_playing ? 'Pause' : 'Lecture'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Source rect : x=${sr.sourceX}, y=${sr.sourceY}, ${sr.sourceWidth}×${sr.sourceHeight}',
          style: TextStyle(color: widget.subtle, fontSize: 10.5, height: 1.35),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            key: const ValueKey('surface_animation_preview_tile_box'),
            height: 96,
            width: 96,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: widget.label.withValues(alpha: 0.35)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: _buildPreviewVisual(sr, tw, th),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewVisual(
    SurfaceStudioVerticalAtlasAnimationSourceRect sr,
    int tw,
    int th,
  ) {
    final img = _decoded;
    if (img == null || _bytes == null) {
      return ColoredBox(
        color: Colors.black12,
        child: Center(
          child: Text(
            'Colonne $_selectedColumn\nFrame ${_frameIndex + 1}',
            textAlign: TextAlign.center,
            style: TextStyle(color: widget.subtle, fontSize: 10),
          ),
        ),
      );
    }
    final src = Rect.fromLTWH(
      sr.sourceX.toDouble(),
      sr.sourceY.toDouble(),
      sr.sourceWidth.toDouble(),
      sr.sourceHeight.toDouble(),
    );
    return CustomPaint(
      painter: SurfaceStudioAtlasFrameCropPainter(image: img, srcRect: src),
    );
  }
}

```

### `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`

```dart
// Tests widget — Surface Studio panel (Lot 52).
// Imports `map_core` en API publique uniquement (pas de `map_core/src/...`).

import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_selection_inspector.dart';

void main() {
  group('SurfaceStudioPanel (Lot 52)', () {
    testWidgets('1. title Surface Studio is visible', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.text('Surface Studio'), findsOneWidget);
    });

    testWidgets('2. read-only badge is visible', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      // Bandeau panneau + inspecteur (Lot 59).
      expect(find.text('Lecture seule'), findsNWidgets(2));
    });

    testWidgets('3. three counters are zero for empty catalog', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      final counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('0')),
        findsNWidgets(3),
      );
    });

    testWidgets('4. empty catalog shows empty state copy', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(
        find.text('Le catalogue Surface est vide'),
        findsOneWidget,
      );
    });

    testWidgets('5. minimal catalog shows 1/1/1', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      final counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('1')),
        findsNWidgets(3),
      );
    });

    testWidgets('6. non-empty shows catalog browser content', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Catalogue Surface'), findsOneWidget);
      expect(find.text('Water Atlas'), findsOneWidget);
    });

    testWidgets('7. clean diagnostics for minimal coherent catalog',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Aucun diagnostic Surface'), findsOneWidget);
    });

    testWidgets('8. warning state when unused atlas', (tester) async {
      final rm = _warningReadModel();
      expect(rm.hasWarnings, isTrue);
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: rm)),
      );
      expect(find.text('Diagnostics Surface'), findsOneWidget);
      // Atlas orphelin + animation non référencée par un preset (presets vides)
      expect(find.textContaining('Avertissements : 2'), findsOneWidget);
      expect(find.text('Atlas inutilisé'), findsOneWidget);
      expect(find.text('Animation inutilisée'), findsOneWidget);
    });

    testWidgets('9. error state when preset animation missing', (tester) async {
      final rm = _errorReadModel();
      expect(rm.hasErrors, isTrue);
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: rm)),
      );
      expect(find.text('Diagnostics Surface'), findsOneWidget);
      expect(find.textContaining('Erreurs : 1'), findsOneWidget);
      expect(
        find.text('Animation manquante dans un preset'),
        findsOneWidget,
      );
    });

    testWidgets('10. future action label import visible (pas Créer un atlas)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.text('Créer un atlas'), findsNothing);
      expect(
        find.text(SurfaceStudioPanel.actionImportVerticalAtlasLabel),
        findsOneWidget,
      );
    });

    testWidgets('11. future import action disabled (onPressed null)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      final b = tester.widget<CupertinoButton>(
        find.ancestor(
          of: find.text(SurfaceStudioPanel.actionImportVerticalAtlasLabel),
          matching: find.byType(CupertinoButton),
        ),
      );
      expect(b.onPressed, isNull);
    });

    testWidgets('12. section placeholder titles are visible', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.text('Diagnostics Surface'), findsOneWidget);
      expect(find.text('Actions auteur'), findsOneWidget);
    });

    testWidgets('13. SurfaceStudioPanelFromManifest uses manifest catalog',
        (tester) async {
      final cat = _minimalWaterCatalog();
      final manifest = _manifest(cat);
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
      );
      final counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('1')),
        findsNWidgets(3),
      );
    });

    testWidgets('14. manifest is not mutated after pump', (tester) async {
      final cat = _minimalWaterCatalog();
      final before = cat.atlases.length;
      final manifest = _manifest(cat);
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
      );
      expect(manifest.surfaceCatalog.atlases.length, before);
    });

    testWidgets(
      '15. does not require provider setup — panel builds without ProviderScope',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SurfaceStudioPanel(readModel: _emptyReadModel()),
            ),
          ),
        );
        expect(find.text('Surface Studio'), findsOneWidget);
      },
    );

    testWidgets('16. content is in a scrollable', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));
    });

    testWidgets('17. no internal domain type names in user-visible strings',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.textContaining('ProjectSurfaceCatalog'), findsNothing);
      expect(find.textContaining('SurfaceStudioReadModel'), findsNothing);
      expect(
          find.textContaining('SurfaceVariantAnimationRefSet'), findsNothing);
    });

    testWidgets('18. error read model does not throw on build', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _errorReadModel())),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('19. warning read model does not throw on build',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _warningReadModel())),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('20. displayed counts match read model summary',
        (tester) async {
      final rm = _minimalWaterReadModel();
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: rm)),
      );
      expect(rm.summary.atlasCount, 1);
      expect(rm.summary.animationCount, 1);
      expect(rm.summary.presetCount, 1);
    });

    testWidgets(
        '22. TextField seulement zone brouillon (Lot 60), pas dans inspecteur',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(
        find.descendant(
          of: find.byKey(kSurfaceStudioSelectionInspectorKey),
          matching: find.byType(TextField),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(kSurfaceStudioAtlasAuthoringPrepKey),
          matching: find.byType(TextField),
        ),
        findsWidgets,
      );
    });

    testWidgets('23. no save affordances', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.textContaining('Sauvegarder'), findsNothing);
      expect(find.textContaining('Enregistrer'), findsNothing);
      expect(find.textContaining('Save'), findsNothing);
    });

    testWidgets('22. panel shows catalog browser for minimal catalog', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Catalogue Surface'), findsOneWidget);
      expect(find.text('Atlas Surface'), findsOneWidget);
      expect(find.text('Animations Surface'), findsOneWidget);
      expect(find.text('Presets Surface'), findsOneWidget);
      expect(find.text('Water Atlas'), findsOneWidget);
      expect(find.text('Water Isolated Loop'), findsOneWidget);
      expect(find.text('Water Surface'), findsWidgets);
    });

    testWidgets('24. test file uses public map_core only (smoke)',
        (tester) async {
      // Vérification statique : seul `package:map_core/map_core.dart` est importé.
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.text('Surface Studio'), findsOneWidget);
    });

    testWidgets('25. Lot 55 — clean diagnostics view in panel', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Diagnostics Surface'), findsOneWidget);
      expect(find.text('Aucun diagnostic Surface'), findsOneWidget);
    });

    testWidgets('26. Lot 55 — error diagnostics visible in panel',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _errorReadModel())),
      );
      expect(find.text('Diagnostics Surface'), findsOneWidget);
      expect(find.text('Erreurs'), findsOneWidget);
    });

    testWidgets('27. Lot 55 — browser and diagnostics cohabit (minimal cat)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Catalogue Surface'), findsOneWidget);
      expect(find.text('Atlas Surface'), findsOneWidget);
      expect(find.text('Animations Surface'), findsOneWidget);
      expect(find.text('Presets Surface'), findsOneWidget);
      expect(find.text('Diagnostics Surface'), findsOneWidget);
      expect(find.text('Water Atlas'), findsOneWidget);
    });

    testWidgets(
        '48. Lot 57 — panel shows Atlas / Animations / Presets / Diagnostics',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Atlas Surface'), findsOneWidget);
      expect(find.text('Animations Surface'), findsOneWidget);
      expect(find.text('Presets Surface'), findsOneWidget);
      expect(find.text('Diagnostics Surface'), findsOneWidget);
    });

    testWidgets('58.21 — Aucune sélection au départ (catalogue minimal)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Aucune sélection'), findsOneWidget);
    });

    testWidgets('58.22 — sélection atlas après tap', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      expect(find.text('Atlas sélectionné'), findsWidgets);
      expect(find.text('water-atlas'), findsWidgets);
    });

    testWidgets('58.23 — sélection animation après tap', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Isolated Loop'));
      await tester.tap(find.text('Water Isolated Loop'));
      await tester.pump();
      expect(find.text('Animation sélectionnée'), findsWidgets);
      expect(find.text('water-isolated-loop'), findsWidgets);
    });

    testWidgets('58.24 — sélection preset après tap', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Surface').last);
      await tester.tap(find.text('Water Surface').last);
      await tester.pump();
      expect(find.text('Preset sélectionné'), findsWidgets);
      expect(find.text('water-surface'), findsWidgets);
    });

    testWidgets('58.25 — changement de sélection remplace la précédente',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      await tester.ensureVisible(find.text('Water Isolated Loop'));
      await tester.tap(find.text('Water Isolated Loop'));
      await tester.pump();
      expect(find.text('Animation sélectionnée'), findsWidgets);
      final t = tester
          .widgetList<Text>(find.byType(Text))
          .map((e) => e.data ?? '')
          .join('\n');
      expect(t.contains('Atlas sélectionné'), isFalse);
    });

    testWidgets('58.26 — sélection ne mute pas surfaceCatalog', (tester) async {
      final cat = _minimalWaterCatalog();
      final manifest = _manifest(cat);
      final before = manifest.surfaceCatalog;
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      await tester.ensureVisible(find.text('Water Surface').last);
      await tester.tap(find.text('Water Surface').last);
      await tester.pump();
      expect(identical(manifest.surfaceCatalog, before), isTrue);
    });

    testWidgets('58.27 — pas de TextField dans inspecteur après sélections', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(kSurfaceStudioSelectionInspectorKey),
          matching: find.byType(TextField),
        ),
        findsNothing,
      );
    });

    testWidgets('58.28 — pas de libellés édition/save actifs', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      for (final s in <String>[
        'Sauvegarder',
        'Enregistrer',
        'Modifier',
        'Supprimer',
        'Save',
        'Edit',
        'Delete',
      ]) {
        expect(find.text(s), findsNothing);
      }
    });

    testWidgets('59.20 — inspecteur none au départ', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Inspecteur Surface'), findsOneWidget);
      expect(find.text('Aucune sélection à inspecter'), findsOneWidget);
    });

    testWidgets('59.21 — inspecteur atlas après tap', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      final insp = find.byKey(kSurfaceStudioSelectionInspectorKey);
      expect(
          find.descendant(of: insp, matching: find.text('Inspecteur Surface')),
          findsOneWidget);
      expect(
        find.descendant(of: insp, matching: find.text('Atlas sélectionné')),
        findsWidgets,
      );
      expect(
        find.descendant(
          of: insp,
          matching: find.textContaining('Identifiant : water-atlas'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('59.22 — inspecteur animation après tap', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Isolated Loop'));
      await tester.tap(find.text('Water Isolated Loop'));
      await tester.pump();
      final insp = find.byKey(kSurfaceStudioSelectionInspectorKey);
      expect(
        find.descendant(
          of: insp,
          matching: find.textContaining('Identifiant : water-isolated-loop'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('59.23 — inspecteur preset après tap', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Surface').last);
      await tester.tap(find.text('Water Surface').last);
      await tester.pump();
      final insp = find.byKey(kSurfaceStudioSelectionInspectorKey);
      expect(
        find.descendant(
          of: insp,
          matching: find.textContaining('Identifiant : water-surface'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('59.24 — changement de sélection met l’inspecteur à jour',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      await tester.ensureVisible(find.text('Water Isolated Loop'));
      await tester.tap(find.text('Water Isolated Loop'));
      await tester.pump();
      final insp = find.byKey(kSurfaceStudioSelectionInspectorKey);
      expect(
        find.descendant(
          of: insp,
          matching: find.textContaining('Identifiant : water-isolated-loop'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: insp,
          matching: find.text('Atlas sélectionné'),
        ),
        findsNothing,
      );
    });

    testWidgets('59.25 — inspecteur ne mute pas le manifest', (tester) async {
      final cat = _minimalWaterCatalog();
      final manifest = _manifest(cat);
      final before = manifest.surfaceCatalog;
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      await tester.ensureVisible(find.text('Water Surface').last);
      await tester.tap(find.text('Water Surface').last);
      await tester.pump();
      expect(identical(manifest.surfaceCatalog, before), isTrue);
    });

    testWidgets(
        '59.26 — inspecteur read-only : aucun TextField (Lot 60 brouillon ok)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(kSurfaceStudioSelectionInspectorKey),
          matching: find.byType(TextField),
        ),
        findsNothing,
      );
    });

    testWidgets('59.27 — pas de libellés édition/save (Lot 59)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Surface').last);
      await tester.tap(find.text('Water Surface').last);
      await tester.pump();
      for (final s in <String>[
        'Sauvegarder',
        'Enregistrer',
        'Modifier',
        'Supprimer',
        'Save',
        'Edit',
        'Delete',
      ]) {
        expect(find.text(s), findsNothing);
      }
    });

    testWidgets('30. Lot 55 — surfaceCatalog unchanged after panel pump',
        (tester) async {
      final cat = _minimalWaterCatalog();
      final manifest = _manifest(cat);
      final before = manifest.surfaceCatalog;
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
      );
      expect(identical(manifest.surfaceCatalog, before), isTrue);
    });

    testWidgets('60.1 — Préparation atlas (brouillon) visible', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      await tester.ensureVisible(find.text('Atlas source').first);
      expect(find.text('Atlas source'), findsWidgets);
      expect(
        find.textContaining('Brouillon : rien n’est écrit sur le disque'),
        findsOneWidget,
      );
    });

    testWidgets('61.1 — action création atlas dans le catalogue de travail',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      await tester.ensureVisible(
        find.text('Créer l’atlas dans le catalogue de travail'),
      );
      expect(
        find.text('Créer l’atlas dans le catalogue de travail'),
        findsOneWidget,
      );
    });

    testWidgets(
        '61.2 — créer atlas (catalogue vide) : compteur atlas 1, browser, '
        'inspecteur', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'lot61-a');
      await tester.enterText(nameF, 'Lot61 A');
      await tester.enterText(tsF, 'tileset-x');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      final counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('1')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: counters, matching: find.text('0')),
        findsNWidgets(2),
      );
      expect(find.text('Lot61 A'), findsWidgets);
      expect(find.text('Diagnostics Surface'), findsOneWidget);
    });

    testWidgets(
        '61.3 — créer second atlas : compteur 2, animations/presets inchangés',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'grass-a');
      await tester.enterText(nameF, 'Grass');
      await tester.enterText(tsF, 'ts-g');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      final counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('2')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: counters, matching: find.text('1')),
        findsNWidgets(2),
      );
      expect(find.text('Water Atlas'), findsOneWidget);
      expect(find.text('Water Isolated Loop'), findsOneWidget);
      expect(find.text('Water Surface'), findsWidgets);
      expect(find.text('grass-a'), findsWidgets);
    });

    testWidgets('62.0 — pas de dirty au départ (vide + minimal)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
    });

    testWidgets('62.1 — dirty après création locale', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'dirty-a');
      await tester.enterText(nameF, 'D');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsOneWidget,
      );
      expect(
        find.textContaining('sauvegarde projet non effectuée'),
        findsWidgets,
      );
    });

    testWidgets(
        '62.2 — reset depuis catalogue vide : compteur 0, atlas absent, dirty off',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'rs-a');
      await tester.enterText(nameF, 'R');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      var counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('1')),
        findsOneWidget,
      );
      expect(find.text('rs-a'), findsWidgets);
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
      );
      await tester.pump();
      counters = find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('0')),
        findsNWidgets(3),
      );
      expect(
        find.text('Le catalogue Surface est vide'),
        findsOneWidget,
      );
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
      expect(find.text('Aucune sélection'), findsOneWidget);
    });

    testWidgets(
        '62.3 — reset depuis minimal : revient à Water, Grass absent, 1/1/1',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'grass-x');
      await tester.enterText(nameF, 'Grass');
      await tester.enterText(tsF, 'ts');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      var counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('2')),
        findsOneWidget,
      );
      expect(find.text('Water Atlas'), findsOneWidget);
      expect(find.text('grass-x'), findsWidgets);
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
      );
      await tester.pump();
      counters = find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('1')),
        findsNWidgets(3),
      );
      expect(find.text('Water Atlas'), findsOneWidget);
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
      expect(find.text('Water Isolated Loop'), findsOneWidget);
      expect(find.text('Water Surface'), findsWidgets);
    });

    testWidgets('62.4 — A puis B puis reset (source vide)', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      for (final row in <String>['lot62-a', 'lot62-b']) {
        final idF = find.byKey(const ValueKey('atlas_draft_id'));
        final nameF = find.byKey(const ValueKey('atlas_draft_name'));
        final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
        await tester.ensureVisible(idF);
        await tester.enterText(idF, row);
        await tester.enterText(nameF, row);
        await tester.enterText(tsF, 't');
        await tester.pump();
        await tester.ensureVisible(
          find.byKey(
              const ValueKey('surface_studio_create_atlas_work_catalog')),
        );
        await tester.tap(
          find.byKey(
              const ValueKey('surface_studio_create_atlas_work_catalog')),
        );
        await tester.pump();
      }
      var counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('2')),
        findsOneWidget,
      );
      expect(find.text('lot62-a'), findsWidgets);
      expect(find.text('lot62-b'), findsWidgets);
      expect(find.text('Aucune sélection'), findsNothing);
      expect(find.text('Atlas sélectionné'), findsWidgets);
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
      );
      await tester.pump();
      counters = find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('0')),
        findsNWidgets(3),
      );
      expect(
        find.text('Le catalogue Surface est vide'),
        findsOneWidget,
      );
    });

    testWidgets('62.5 — readModel parent change : resync, dirty off, X absent',
        (tester) async {
      final w = _wrap(
        SurfaceStudioPanel(readModel: _emptyReadModel()),
      );
      await tester.pumpWidget(w);
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'ext-x');
      await tester.enterText(nameF, 'X');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsOneWidget,
      );
      expect(find.text('ext-x'), findsWidgets);
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(readModel: _minimalWaterReadModel()),
        ),
      );
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
      expect(find.text('Water Atlas'), findsOneWidget);
      expect(find.text('Aucune sélection'), findsOneWidget);
    });

    testWidgets(
        '62.6 — pas d’action fantôme Créer un atlas, vraie action présente',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.text('Créer un atlas'), findsNothing);
      expect(
        find.text('Créer l’atlas dans le catalogue de travail'),
        findsOneWidget,
      );
    });

    testWidgets('62.7 — no save flow libellés interdits', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('atlas_draft_id')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('atlas_draft_id')),
        'z',
      );
      await tester.enterText(
          find.byKey(const ValueKey('atlas_draft_name')), 'N');
      await tester.enterText(
          find.byKey(const ValueKey('atlas_draft_tileset_advanced')), 'T');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      for (final s in <String>[
        'Sauvegarder le projet',
        'Enregistrer le projet',
        'Sauvegarder maintenant',
        'Save project',
        'Write to disk',
        'Écrire sur disque',
      ]) {
        expect(find.text(s), findsNothing);
      }
    });
  });

  group('SurfaceStudioPanel (Lot 63)', () {
    testWidgets(
        '63.1 — sans modification : pas d’action préparation, callback jamais',
        (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _minimalWaterReadModel(),
            onSurfaceCatalogSaveRequested: (_) => calls++,
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
        findsNothing,
      );
      expect(
        find.text(SurfaceStudioPanel.savePrepActionLabel),
        findsNothing,
      );
      expect(calls, 0);
    });

    testWidgets(
        '63.2 — dirty + callback : action, un appel, catalogue complet, dirty et accusé',
        (tester) async {
      ProjectSurfaceCatalog? received;
      var calls = 0;
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _emptyReadModel(),
            onSurfaceCatalogSaveRequested: (c) {
              calls++;
              received = c;
            },
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'prep-one');
      await tester.enterText(nameF, 'P');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      final prep =
          find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
      expect(prep, findsOneWidget);
      await tester.ensureVisible(prep);
      await tester.tap(prep);
      await tester.pump();
      expect(calls, 1);
      expect(received, isNotNull);
      expect(received!.atlases.length, 1);
      expect(received!.atlases.first.id, 'prep-one');
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsOneWidget,
      );
      expect(
        find.text(SurfaceStudioPanel.savePrepTransmittedNote),
        findsOneWidget,
      );
    });

    testWidgets(
        '63.3 — sans callback : stable, message not connected, pas de bouton',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'nccb');
      await tester.enterText(nameF, 'N');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        find.text(SurfaceStudioPanel.savePrepNotConnectedNote),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
        findsNothing,
      );
    });

    testWidgets('63.4 — resync parent : dirty off, atlas source, pas d’accusé',
        (tester) async {
      ProjectSurfaceCatalog? out;
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _emptyReadModel(),
            onSurfaceCatalogSaveRequested: (c) => out = c,
          ),
        ),
      );
      var idF = find.byKey(const ValueKey('atlas_draft_id'));
      var nameF = find.byKey(const ValueKey('atlas_draft_name'));
      var tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'sync-x');
      await tester.enterText(nameF, 'S');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      final prep =
          find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
      await tester.ensureVisible(prep);
      await tester.tap(prep);
      await tester.pump();
      expect(out, isNotNull);
      final synced = buildSurfaceStudioReadModelFromCatalog(out!);
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: synced,
            onSurfaceCatalogSaveRequested: (c) => out = c,
          ),
        ),
      );
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
      expect(
        find.text(SurfaceStudioPanel.savePrepTransmittedNote),
        findsNothing,
      );
      expect(find.text('sync-x'), findsWidgets);
    });

    testWidgets('63.5 — reset après préparation : clean, accusé nettoyé, vide',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _emptyReadModel(),
            onSurfaceCatalogSaveRequested: (_) {},
          ),
        ),
      );
      var idF = find.byKey(const ValueKey('atlas_draft_id'));
      var nameF = find.byKey(const ValueKey('atlas_draft_name'));
      var tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'reset-p');
      await tester.enterText(nameF, 'R');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      final prep =
          find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
      await tester.ensureVisible(prep);
      await tester.tap(prep);
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.savePrepTransmittedNote),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
      );
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
      expect(
        find.text(SurfaceStudioPanel.savePrepTransmittedNote),
        findsNothing,
      );
      final counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('0')),
        findsNWidgets(3),
      );
      expect(
        find.text('Le catalogue Surface est vide'),
        findsOneWidget,
      );
    });

    testWidgets('63.6 — A puis B puis préparation : ordre des atlas',
        (tester) async {
      ProjectSurfaceCatalog? got;
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _emptyReadModel(),
            onSurfaceCatalogSaveRequested: (c) => got = c,
          ),
        ),
      );
      for (final row in <(String, String, String)>[
        ('lot63-a', 'A', 'ta'),
        ('lot63-b', 'B', 'tb'),
      ]) {
        final idF = find.byKey(const ValueKey('atlas_draft_id'));
        final nameF = find.byKey(const ValueKey('atlas_draft_name'));
        final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
        await tester.ensureVisible(idF);
        await tester.enterText(idF, row.$1);
        await tester.enterText(nameF, row.$2);
        await tester.enterText(tsF, row.$3);
        await tester.pump();
        await tester.ensureVisible(
          find.byKey(
              const ValueKey('surface_studio_create_atlas_work_catalog')),
        );
        await tester.tap(
          find.byKey(
              const ValueKey('surface_studio_create_atlas_work_catalog')),
        );
        await tester.pump();
      }
      final prep =
          find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
      await tester.ensureVisible(prep);
      await tester.tap(prep);
      await tester.pump();
      expect(got, isNotNull);
      expect(got!.atlases.length, 2);
      expect(got!.atlases[0].id, 'lot63-a');
      expect(got!.atlases[1].id, 'lot63-b');
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsOneWidget,
      );
    });

    testWidgets('66.1 — header compact et repères workflow visibles',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(
        find.byKey(const ValueKey('surface_studio_workflow_header')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('surface_studio_workflow_steps')),
        findsOneWidget,
      );
    });

    testWidgets(
        '66.2 — préparation atlas au-dessus du catalogue (ordre vertical)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      final yPrep = tester
          .getTopLeft(
            find.byKey(const ValueKey('surface_studio_authoring_main_title')),
          )
          .dy;
      final yCat = tester.getTopLeft(find.text('Catalogue Surface')).dy;
      expect(yPrep, lessThan(yCat));
    });

    testWidgets('66.3 — bandeau dirty visible si catalogue de travail modifié',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _emptyReadModel(),
            onSurfaceCatalogSaveRequested: (_) {},
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'x');
      await tester.enterText(nameF, 'N');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('surface_studio_catalog_status_strip')),
        findsOneWidget,
      );
    });

    testWidgets('66.4 — inspecteur, catalogue, diagnostics toujours présents',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Inspecteur Surface'), findsOneWidget);
      expect(find.text('Catalogue Surface'), findsOneWidget);
      expect(find.text('Diagnostics Surface'), findsOneWidget);
    });

    testWidgets('66.5 — pas de libellés techniques dans l’UI principale',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.textContaining('ProjectSurfaceAtlas'), findsNothing);
      expect(find.textContaining('ProjectSurfaceCatalog'), findsNothing);
      expect(find.textContaining('SurfaceStudioReadModel'), findsNothing);
      expect(find.textContaining('copyWith'), findsNothing);
    });

    testWidgets('85.1 — workflow guidé Surface Studio visible', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );

      expect(
        find.text(
            'Créer des surfaces peintes à partir d’un atlas, étape par étape.'),
        findsOneWidget,
      );
      expect(find.text('1. Atlas'), findsOneWidget);
      expect(find.text('2. Grille'), findsOneWidget);
      expect(find.text('3. Animations'), findsOneWidget);
      expect(find.text('4. Surfaces prêtes à peindre'), findsOneWidget);
      expect(find.text('Assistant de création'), findsOneWidget);
      expect(find.text('Ce que vous faites ici'), findsOneWidget);
      expect(find.text('Atlas source'), findsWidgets);
      expect(find.text('Découpage et validation'), findsOneWidget);
      expect(find.text('Animations détectées'), findsOneWidget);
      expect(find.text('Surfaces prêtes à peindre'), findsWidgets);
    });

    testWidgets(
        '85.2 — animations présentes sans surfaces peignables : état explicite',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _animationsOnlyReadModel())),
      );

      expect(
        find.text('Animations détectées, mais aucune surface peignable.'),
        findsOneWidget,
      );
      expect(
        find.text('Créez une surface à partir des animations générées.'),
        findsOneWidget,
      );
    });

    testWidgets('85.3 — surfaces peignables listées dans le panneau dédié',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );

      final panel = find.byKey(
        const ValueKey('surface_studio_paintable_surfaces_panel'),
      );
      expect(panel, findsOneWidget);
      expect(
        find.descendant(of: panel, matching: find.text('Water Surface')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: panel, matching: find.text('Peignable')),
        findsOneWidget,
      );
    });

    testWidgets('85.4 — CTA création surface et sauvegarde visibles',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _minimalWaterReadModel(),
            onSurfaceCatalogSaveRequested: (_) {},
          ),
        ),
      );

      expect(find.text('Créer une surface'), findsOneWidget);
      expect(find.text('Sauvegarder le catalogue'), findsOneWidget);
    });

    testWidgets('85-bis.1 — workflow desktop en quatre zones côte à côte',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );

      final grid =
          find.byKey(const ValueKey('surface_studio_workflow_desktop_grid'));
      final assistant =
          find.byKey(const ValueKey('surface_studio_workflow_assistant_lane'));
      final atlas =
          find.byKey(const ValueKey('surface_studio_workflow_atlas_lane'));
      final animations =
          find.byKey(const ValueKey('surface_studio_workflow_animations_lane'));
      final surfaces =
          find.byKey(const ValueKey('surface_studio_workflow_surfaces_lane'));
      final advanced =
          find.byKey(const ValueKey('surface_studio_advanced_details'));

      expect(grid, findsOneWidget);
      expect(assistant, findsOneWidget);
      expect(atlas, findsOneWidget);
      expect(animations, findsOneWidget);
      expect(surfaces, findsOneWidget);
      expect(advanced, findsOneWidget);

      final assistantLeft = tester.getTopLeft(assistant).dx;
      final atlasLeft = tester.getTopLeft(atlas).dx;
      final animationsLeft = tester.getTopLeft(animations).dx;
      final surfacesLeft = tester.getTopLeft(surfaces).dx;
      expect(assistantLeft, lessThan(atlasLeft));
      expect(atlasLeft, lessThan(animationsLeft));
      expect(animationsLeft, lessThan(surfacesLeft));

      final workflowTop = tester.getTopLeft(grid).dy;
      expect(
        (tester.getTopLeft(assistant).dy - workflowTop).abs(),
        lessThan(1),
      );
      expect(
        (tester.getTopLeft(atlas).dy - workflowTop).abs(),
        lessThan(1),
      );
      expect(
        (tester.getTopLeft(animations).dy - workflowTop).abs(),
        lessThan(1),
      );
      expect(
        (tester.getTopLeft(surfaces).dy - workflowTop).abs(),
        lessThan(1),
      );
      expect(tester.getTopLeft(advanced).dy, greaterThan(workflowTop));
    });

    testWidgets(
        '88-bis.1 — modifier le mapping met le catalogue de travail dirty et sauvegardable',
        (tester) async {
      ProjectSurfaceCatalog? saved;
      final atlasImage = await _fakeAtlasImage();
      addTearDown(atlasImage.dispose);
      await tester.binding.setSurfaceSize(const Size(1600, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: buildSurfaceStudioReadModelFromCatalog(
              _roleMappingCatalog(),
            ),
            projectRootPath: '/project',
            projectTilesets: _surfaceTilesets(),
            surfaceMappingImageLoader: (_) async => atlasImage,
            onSurfaceCatalogSaveRequested: (catalog) => saved = catalog,
          ),
        ),
      );

      final editButton =
          find.byKey(const ValueKey('surface_paintable_edit_mapping_water'));
      await tester.ensureVisible(editButton);
      expect(find.text('Modifier le mapping visuel'), findsOneWidget);
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      expect(find.text('Surface Mapping Editor'), findsOneWidget);
      expect(find.text('Atlas réel cliquable'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('surface_role_slot_endNorth')),
      );
      await tester.pump();

      final hitArea = find.byKey(const ValueKey('surface_real_atlas_hit_area'));
      final topLeft = tester.getTopLeft(hitArea);
      final size = tester.getSize(hitArea);
      await tester.tapAt(topLeft + Offset(size.width * 0.75, size.height / 2));
      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey('surface_mapping_editor_close')),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsOneWidget,
      );

      final prep =
          find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
      await tester.ensureVisible(prep);
      await tester.tap(prep);
      await tester.pump();

      expect(saved, isNotNull);
      expect(
        saved!
            .presetById('water')!
            .animationIdForRole(SurfaceVariantRole.endNorth),
        'water-horizontal',
      );
      expect(
        saved!
            .presetById('water')!
            .animationIdForRole(SurfaceVariantRole.horizontal),
        'water-horizontal',
      );
    });
  });

  group('SurfaceStudioPanel (Lot 67–69)', () {
    testWidgets('67–68.1 — édition nom atlas, dirty, compteurs stables',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _minimalWaterReadModel(),
            onSurfaceCatalogSaveRequested: (_) {},
          ),
        ),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_start_edit_atlas')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_start_edit_atlas')),
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('atlas_draft_name')),
        'Renamed Water',
      );
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_apply_atlas_edit')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_apply_atlas_edit')),
      );
      await tester.pump();
      expect(find.text('Renamed Water'), findsWidgets);
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsOneWidget,
      );
      final counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('1')),
        findsNWidgets(3),
      );
    });

    testWidgets(
        '67–68.2 — création atlas avec sélection animation : sélection inchangée',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _minimalWaterReadModel(),
            onSurfaceCatalogSaveRequested: (_) {},
          ),
        ),
      );
      await tester.ensureVisible(find.text('Water Isolated Loop'));
      await tester.tap(find.text('Water Isolated Loop'));
      await tester.pump();
      expect(find.text('Animation sélectionnée'), findsWidgets);
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'z2');
      await tester.enterText(nameF, 'Z2');
      await tester.enterText(tsF, 't2');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      expect(find.text('Animation sélectionnée'), findsWidgets);
    });

    testWidgets('69.1 — atlas utilisé : pas de préparation suppression',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _warningReadModel(),
            onSurfaceCatalogSaveRequested: (_) {},
          ),
        ),
      );
      final usedLine = find.textContaining('used-atlas');
      await tester.ensureVisible(usedLine.first);
      await tester.tap(usedLine.first);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('surface_studio_inspector_prepare_delete')),
        findsNothing,
      );
    });

    testWidgets('69.2 — atlas inutilisé : supprimer et sélection nettoyée',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _warningReadModel(),
            onSurfaceCatalogSaveRequested: (_) {},
          ),
        ),
      );
      final orphanLine = find.textContaining('orphan-atlas');
      await tester.ensureVisible(orphanLine.first);
      await tester.tap(orphanLine.first);
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_inspector_prepare_delete')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_inspector_prepare_delete')),
      );
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_inspector_confirm_delete')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_inspector_confirm_delete')),
      );
      await tester.pump();
      expect(find.textContaining('orphan-atlas'), findsNothing);
      expect(find.text('Aucune sélection'), findsOneWidget);
    });
  });

  group('SurfaceStudioPanel (Lot 64)', () {
    testWidgets(
        '64.1 — FromManifest : préparer sauvegarde, manifest mémoire, dirty off',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanelFromManifest(
            manifest: _manifest(ProjectSurfaceCatalog()),
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'lot64-a');
      await tester.enterText(nameF, 'L');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsOneWidget,
      );
      final prep =
          find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
      await tester.ensureVisible(prep);
      await tester.tap(prep);
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
      expect(
        find.text(SurfaceStudioPanel.manifestMemoryUpdatedNote),
        findsOneWidget,
      );
      expect(find.text('lot64-a'), findsWidgets);
      final counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('1')),
        findsWidgets,
      );
    });

    testWidgets('64.2 — onProjectManifestChanged une fois, atlas dans manifest',
        (tester) async {
      var calls = 0;
      late ProjectManifest out;
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanelFromManifest(
            manifest: _manifest(
              ProjectSurfaceCatalog(),
            ),
            onProjectManifestChanged: (m) {
              calls++;
              out = m;
            },
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'cb-one');
      await tester.enterText(nameF, 'C');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
      );
      await tester.pump();
      expect(calls, 1);
      expect(out.surfaceCatalog.atlases.length, 1);
      expect(out.surfaceCatalog.atlases.first.id, 'cb-one');
      expect(out.name, 'Test');
    });

    testWidgets('64.3 — onProjectManifestChanged absent : pas d’exception',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanelFromManifest(
            manifest: _manifest(ProjectSurfaceCatalog()),
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'nccb64');
      await tester.enterText(nameF, 'N');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        '64.4 — changement de manifest parent externe (FromManifest) : resync',
        (tester) async {
      const extKey = ValueKey<String>('lot64_from_manifest');
      final a = _manifest(ProjectSurfaceCatalog());
      final b = _manifest(
        _minimalWaterCatalog(),
      );
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanelFromManifest(
            key: extKey,
            manifest: a,
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'orph');
      await tester.enterText(nameF, 'O');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsOneWidget,
      );
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanelFromManifest(
            key: extKey,
            manifest: b,
          ),
        ),
      );
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
      expect(find.text('Water Atlas'), findsOneWidget);
    });
  });
}

Widget _wrap(Widget child) {
  // MacosApp + thème sombre : même [EditorChrome] que l’éditeur réel.
  return MacosApp(
    theme: MacosThemeData.dark(),
    home: ColoredBox(
      color: const Color(0xFF0F1218),
      child: child,
    ),
  );
}

SurfaceStudioReadModel _emptyReadModel() {
  return buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog());
}

SurfaceStudioReadModel _minimalWaterReadModel() {
  return buildSurfaceStudioReadModelFromCatalog(_minimalWaterCatalog());
}

SurfaceStudioReadModel _warningReadModel() {
  return buildSurfaceStudioReadModelFromCatalog(_catalogWithUnusedAtlas());
}

SurfaceStudioReadModel _animationsOnlyReadModel() {
  return buildSurfaceStudioReadModelFromCatalog(_catalogWithUnusedAtlas());
}

SurfaceStudioReadModel _errorReadModel() {
  return buildSurfaceStudioReadModelFromCatalog(_catalogWithMissingAnimation());
}

SurfaceAtlasGeometry _geom() {
  return SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
}

ProjectSurfaceCatalog _minimalWaterCatalog() {
  final g = _geom();
  final atlas = ProjectSurfaceAtlas(
    id: 'water-atlas',
    name: 'Water Atlas',
    tilesetId: 'nature-tileset',
    geometry: g,
  );
  final frame = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'water-atlas', column: 0, row: 0),
    durationMs: 120,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'water-isolated-loop',
    name: 'Water Isolated Loop',
    timeline: SurfaceAnimationTimeline(frames: [frame]),
  );
  final refs = SurfaceVariantAnimationRefSet(
    refs: [
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'water-isolated-loop',
      ),
    ],
  );
  final preset = ProjectSurfacePreset(
    id: 'water-surface',
    name: 'Water Surface',
    variantAnimations: refs,
  );
  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [anim],
    presets: [preset],
  );
}

ProjectSurfaceCatalog _roleMappingCatalog() {
  final g = _geom();
  final atlas = ProjectSurfaceAtlas(
    id: 'water-atlas',
    name: 'Water Atlas',
    tilesetId: 'nature-tileset',
    geometry: g,
  );

  ProjectSurfaceAnimation animation(String id, String name, int column) {
    return ProjectSurfaceAnimation(
      id: id,
      name: name,
      timeline: SurfaceAnimationTimeline(
        frames: [
          SurfaceAnimationFrame(
            tileRef: SurfaceAtlasTileRef(
              atlasId: 'water-atlas',
              column: column,
              row: 0,
            ),
            durationMs: 120,
          ),
        ],
      ),
    );
  }

  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [
      animation('water-cross', 'Water Cross', 0),
      animation('water-horizontal', 'Water Horizontal', 1),
    ],
    presets: [
      ProjectSurfacePreset(
        id: 'water',
        name: 'Water Surface',
        categoryId: 'water',
        sortOrder: 3,
        variantAnimations: SurfaceVariantAnimationRefSet(
          refs: [
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.cross,
              animationId: 'water-cross',
            ),
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.horizontal,
              animationId: 'water-horizontal',
            ),
          ],
        ),
      ),
    ],
  );
}

List<ProjectTilesetEntry> _surfaceTilesets() => const [
      ProjectTilesetEntry(
        id: 'nature-tileset',
        name: 'Nature Tileset',
        relativePath: 'assets/tilesets/nature.png',
      ),
    ];

Future<ui.Image> _fakeAtlasImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 32, 64),
    ui.Paint()..color = const ui.Color(0xFF0EA5E9),
  );
  canvas.drawRect(
    const ui.Rect.fromLTWH(32, 0, 32, 64),
    ui.Paint()..color = const ui.Color(0xFF22C55E),
  );
  canvas.drawLine(
    const ui.Offset(32, 0),
    const ui.Offset(32, 64),
    ui.Paint()
      ..color = const ui.Color(0xFFFFFFFF)
      ..strokeWidth = 2,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(64, 64);
  picture.dispose();
  return image;
}

ProjectSurfaceCatalog _catalogWithUnusedAtlas() {
  final g = _geom();
  final used = ProjectSurfaceAtlas(
    id: 'used-atlas',
    name: 'U',
    tilesetId: 't',
    geometry: g,
  );
  final unused = ProjectSurfaceAtlas(
    id: 'orphan-atlas',
    name: 'O',
    tilesetId: 't',
    geometry: g,
  );
  final f = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'used-atlas', column: 0, row: 0),
    durationMs: 10,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'a',
    name: 'a',
    timeline: SurfaceAnimationTimeline(frames: [f]),
  );
  return ProjectSurfaceCatalog(
    atlases: [used, unused],
    animations: [anim],
    presets: const [],
  );
}

ProjectSurfaceCatalog _catalogWithMissingAnimation() {
  final refs = SurfaceVariantAnimationRefSet(
    refs: [
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'missing-anim',
      ),
    ],
  );
  return ProjectSurfaceCatalog(
    atlases: const [],
    animations: const [],
    presets: [
      ProjectSurfacePreset(
        id: 'p',
        name: 'p',
        variantAnimations: refs,
      ),
    ],
  );
}

ProjectManifest _manifest(ProjectSurfaceCatalog catalog) {
  return ProjectManifest(
    name: 'Test',
    maps: const [],
    tilesets: const [],
    surfaceCatalog: catalog,
  );
}

```

### `packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart`

```dart
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_role_mapping_editor.dart';

void main() {
  testWidgets('editor lists roles, current animation and missing roles',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        SurfaceStudioRoleMappingEditor(
          catalog: _catalog(),
          preset: _catalog().presetById('water-surface')!,
          onRoleAnimationChanged: (_, __) {},
        ),
      ),
    );

    expect(find.text('Édition du mapping de surface'), findsOneWidget);
    expect(find.text('Surface sélectionnée : Water Surface'), findsOneWidget);
    expect(find.text('Centre / plein'), findsWidgets);
    expect(find.text('Bord haut'), findsWidgets);
    expect(find.textContaining('Water Cross'), findsWidgets);
    expect(find.text('Animation manquante'), findsWidgets);
    expect(find.textContaining('ProjectSurfacePreset'), findsNothing);
    expect(find.textContaining('SurfaceVariantAnimationRef'), findsNothing);
    expect(find.textContaining('copyWith'), findsNothing);
  });

  testWidgets('changing a role animation invokes the callback', (tester) async {
    SurfaceVariantRole? changedRole;
    String? changedAnimationId;
    await tester.pumpWidget(
      _wrap(
        SurfaceStudioRoleMappingEditor(
          catalog: _catalog(),
          preset: _catalog().presetById('water-surface')!,
          onRoleAnimationChanged: (role, animationId) {
            changedRole = role;
            changedAnimationId = animationId;
          },
        ),
      ),
    );

    final horizontalCard =
        find.byKey(const ValueKey('surface_role_column_card_anim-horizontal'));
    await tester.ensureVisible(horizontalCard);
    await tester.pump();
    await tester.tap(horizontalCard);
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('surface_role_assign_column')),
      220,
    );
    await tester.tap(find.byKey(const ValueKey('surface_role_assign_column')));
    await tester.pump();

    expect(changedRole, SurfaceVariantRole.cross);
    expect(changedAnimationId, 'anim-horizontal');
  });

  testWidgets('visual slot then column click assigns the selected role',
      (tester) async {
    SurfaceVariantRole? changedRole;
    String? changedAnimationId;
    await tester.pumpWidget(
      _wrap(
        SurfaceStudioRoleMappingEditor(
          catalog: _catalog(),
          preset: _catalog().presetById('water-surface')!,
          onRoleAnimationChanged: (role, animationId) {
            changedRole = role;
            changedAnimationId = animationId;
          },
        ),
      ),
    );

    expect(find.text('Schéma des slots Surface'), findsOneWidget);
    expect(find.text('Cliquez un slot, puis une colonne'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('surface_role_slot_endNorth')),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('surface_role_active_slot_label')),
      findsOneWidget,
    );
    expect(find.text('Slot actif : Bord haut'), findsWidgets);
    expect(find.textContaining('limite supérieure'), findsOneWidget);

    final horizontalCard =
        find.byKey(const ValueKey('surface_role_column_card_anim-horizontal'));
    await tester.ensureVisible(horizontalCard);
    await tester.pump();
    await tester.tap(horizontalCard);
    await tester.pump();

    expect(changedRole, SurfaceVariantRole.endNorth);
    expect(changedAnimationId, 'anim-horizontal');
    expect(find.text('Assigné au slot actif'), findsOneWidget);
  });

  testWidgets('visual gallery exposes columns, selection and mapping summary',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        SurfaceStudioRoleMappingEditor(
          catalog: _catalog(),
          preset: _catalog().presetById('water-surface')!,
          onRoleAnimationChanged: (_, __) {},
        ),
      ),
    );

    expect(find.text('Galerie des colonnes'), findsOneWidget);
    expect(find.text('Col 0'), findsWidgets);
    expect(find.text('Col 1'), findsOneWidget);
    expect(find.text('Assigné au slot actif'), findsOneWidget);
    expect(find.text('Non assignée'), findsOneWidget);
    expect(find.text('Résumé du mapping'), findsOneWidget);
    expect(find.text('Schéma des slots Surface'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('surface_role_slot_cross')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('surface_role_slot_cornerNE')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('surface_role_slot_teeNorth')),
      findsOneWidget,
    );
    expect(find.text('Colonnes : 2'), findsOneWidget);
    expect(find.text('Assignées : 1'), findsOneWidget);
    expect(find.text('Non assignées : 1'), findsOneWidget);
    expect(find.textContaining('Rôles manquants'), findsOneWidget);

    final horizontalCard =
        find.byKey(const ValueKey('surface_role_column_card_anim-horizontal'));
    await tester.ensureVisible(horizontalCard);
    await tester.pump();
    await tester.tap(horizontalCard);
    await tester.pump();

    expect(find.textContaining('Colonne sélectionnée : Col 1'), findsOneWidget);
    expect(find.textContaining('Water Horizontal'), findsWidgets);
  });

  testWidgets('duplicate animation assignments are visible', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SurfaceStudioRoleMappingEditor(
          catalog: _duplicateCatalog(),
          preset: _duplicateCatalog().presetById('water-surface')!,
          onRoleAnimationChanged: (_, __) {},
        ),
      ),
    );

    expect(find.textContaining('Doublons : 1'), findsOneWidget);
    expect(find.text('Doublon'), findsWidgets);
  });

  testWidgets('role detail explains the selected role without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      _wrap(
        SizedBox(
          width: 330,
          child: SurfaceStudioRoleMappingEditor(
            catalog: _catalog(),
            preset: _catalog().presetById('water-surface')!,
            onRoleAnimationChanged: (_, __) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Détail du rôle'), findsOneWidget);
    expect(find.textContaining('jonction centrale'), findsOneWidget);
  });

  testWidgets('shows clear copy when no animation is available',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        SurfaceStudioRoleMappingEditor(
          catalog: ProjectSurfaceCatalog(presets: [_catalog().presets.first]),
          preset: _catalog().presetById('water-surface')!,
          onRoleAnimationChanged: (_, __) {},
        ),
      ),
    );

    expect(find.text('Aucune animation disponible.'), findsOneWidget);
    expect(
      find.text('Générez d’abord les animations depuis l’atlas.'),
      findsOneWidget,
    );
  });

  testWidgets('real atlas picker shows image grid and assigns a clicked column',
      (tester) async {
    final image = await _fakeAtlasImage();
    addTearDown(image.dispose);
    SurfaceVariantRole? changedRole;
    String? changedAnimationId;

    await tester.pumpWidget(
      _wrap(
        SizedBox(
          width: 1040,
          child: SurfaceStudioRoleMappingEditor(
            catalog: _catalog(),
            preset: _catalog().presetById('water-surface')!,
            projectRootPath: '/project',
            projectTilesets: _tilesets(),
            imageLoader: (_) async => image,
            onRoleAnimationChanged: (role, animationId) {
              changedRole = role;
              changedAnimationId = animationId;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Atlas réel cliquable'), findsOneWidget);
    expect(find.byKey(const ValueKey('surface_real_atlas_picker')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('surface_real_atlas_grid')), findsOneWidget);
    expect(find.text('Galerie des colonnes'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('surface_role_slot_endNorth')));
    await tester.pump();

    final hitArea = find.byKey(const ValueKey('surface_real_atlas_hit_area'));
    await tester.ensureVisible(hitArea);
    await tester.pump();
    final topLeft = tester.getTopLeft(hitArea);
    final size = tester.getSize(hitArea);
    await tester.tapAt(topLeft + Offset(size.width * 0.75, size.height * 0.5));
    await tester.pump();

    expect(changedRole, SurfaceVariantRole.endNorth);
    expect(changedAnimationId, 'anim-horizontal');
    expect(find.byKey(const ValueKey('surface_role_real_crop_endNorth')),
        findsOneWidget);
    expect(
      find.textContaining('Colonne assignée : Col 1'),
      findsOneWidget,
    );
  });

  testWidgets('real atlas picker explains fallback when image cannot load',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        SizedBox(
          width: 1040,
          child: SurfaceStudioRoleMappingEditor(
            catalog: _catalog(),
            preset: _catalog().presetById('water-surface')!,
            projectRootPath: '/project',
            projectTilesets: _tilesets(),
            imageLoader: (_) async => null,
            onRoleAnimationChanged: (_, __) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Image atlas réelle indisponible'), findsOneWidget);
    expect(find.byKey(const ValueKey('surface_real_atlas_fallback')),
        findsOneWidget);
    expect(find.text('Galerie des colonnes'), findsOneWidget);
  });
}

Widget _wrap(Widget child) {
  return MacosApp(
    theme: MacosThemeData.dark(),
    home: ColoredBox(
      color: const Color(0xFF0F1218),
      child: Material(
        child: SingleChildScrollView(
          child: Center(child: child),
        ),
      ),
    ),
  );
}

ProjectSurfaceCatalog _catalog() {
  final atlas = ProjectSurfaceAtlas(
    id: 'atlas',
    name: 'Water Atlas',
    tilesetId: 'surface-water-tileset',
    geometry: SurfaceAtlasGeometry(
      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
      gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
      layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
    ),
  );
  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [
      _animation('anim-cross', 'Water Cross', column: 0),
      _animation('anim-horizontal', 'Water Horizontal', column: 1),
    ],
    presets: [
      ProjectSurfacePreset(
        id: 'water-surface',
        name: 'Water Surface',
        variantAnimations: SurfaceVariantAnimationRefSet(
          refs: [
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.cross,
              animationId: 'anim-cross',
            ),
          ],
        ),
      ),
    ],
  );
}

List<ProjectTilesetEntry> _tilesets() => const [
      ProjectTilesetEntry(
        id: 'surface-water-tileset',
        name: 'Surface Water Tileset',
        relativePath: 'assets/tilesets/water.png',
      ),
    ];

ProjectSurfaceCatalog _duplicateCatalog() {
  final catalog = _catalog();
  return ProjectSurfaceCatalog(
    animations: catalog.animations,
    presets: [
      ProjectSurfacePreset(
        id: 'water-surface',
        name: 'Water Surface',
        variantAnimations: SurfaceVariantAnimationRefSet(
          refs: [
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.cross,
              animationId: 'anim-cross',
            ),
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.horizontal,
              animationId: 'anim-cross',
            ),
          ],
        ),
      ),
    ],
  );
}

ProjectSurfaceAnimation _animation(
  String id,
  String name, {
  required int column,
}) =>
    ProjectSurfaceAnimation(
      id: id,
      name: name,
      timeline: SurfaceAnimationTimeline(
        frames: [
          SurfaceAnimationFrame(
            tileRef: SurfaceAtlasTileRef(
              atlasId: 'atlas',
              column: column,
              row: 0,
            ),
            durationMs: 100,
          ),
        ],
      ),
    );

Future<ui.Image> _fakeAtlasImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 32, 64),
    ui.Paint()..color = const ui.Color(0xFF0EA5E9),
  );
  canvas.drawRect(
    const ui.Rect.fromLTWH(32, 0, 32, 64),
    ui.Paint()..color = const ui.Color(0xFF22C55E),
  );
  canvas.drawLine(
    const ui.Offset(32, 0),
    const ui.Offset(32, 64),
    ui.Paint()
      ..color = const ui.Color(0xFFFFFFFF)
      ..strokeWidth = 2,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(64, 64);
  picture.dispose();
  return image;
}

```

### `packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_preview_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_animation_preview.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_role_mapping.dart';

void main() {
  group('surfaceStudioVerticalAtlasAnimationPreviewSummary', () {
    test('colonne 0, frame 5, 32×32, 32 lignes → source x=0 y=160', () {
      final s = surfaceStudioVerticalAtlasAnimationPreviewSummary(
        columnIndex: 0,
        role: SurfaceVariantRole.isolated,
        frameIndex: 5,
        tileWidth: 32,
        tileHeight: 32,
        rows: 32,
      );
      expect(s, isNotNull);
      expect(s!.frameCount, 32);
      expect(s.currentFrameIndex, 5);
      expect(s.sourceRect.sourceX, 0);
      expect(s.sourceRect.sourceY, 160);
      expect(s.sourceRect.sourceWidth, 32);
      expect(s.sourceRect.sourceHeight, 32);
    });

    test('frameIndex est ramené modulo rows', () {
      final s = surfaceStudioVerticalAtlasAnimationPreviewSummary(
        columnIndex: 2,
        role: SurfaceVariantRole.isolated,
        frameIndex: 40,
        tileWidth: 32,
        tileHeight: 32,
        rows: 32,
      );
      expect(s, isNotNull);
      expect(s!.currentFrameIndex, 8);
      expect(s.sourceRect.sourceX, 64);
      expect(s.sourceRect.sourceY, 256);
    });

    test('dimensions invalides → null', () {
      expect(
        surfaceStudioVerticalAtlasAnimationPreviewSummary(
          columnIndex: 0,
          role: SurfaceVariantRole.isolated,
          frameIndex: 0,
          tileWidth: 0,
          tileHeight: 32,
          rows: 10,
        ),
        isNull,
      );
    });
  });

  group('SurfaceStudioVerticalAtlasAnimationPreview', () {
    testWidgets('titre de section visible', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SurfaceStudioVerticalAtlasAnimationPreview(
              label: Colors.white,
              subtle: Colors.grey,
              mappingDraft: SurfaceStudioColumnRoleMappingDraft.empty(1),
              tileWidth: 32,
              tileHeight: 32,
              columns: 1,
              rows: 1,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Aperçu animation par colonne'), findsOneWidget);
    });

    testWidgets('grille invalide : message sans jargon interdit',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SurfaceStudioVerticalAtlasAnimationPreview(
              label: Colors.white,
              subtle: Colors.grey,
              mappingDraft: SurfaceStudioColumnRoleMappingDraft.empty(3),
              tileWidth: null,
              tileHeight: 32,
              columns: 3,
              rows: 10,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.textContaining('Corrigez la grille avant de prévisualiser'),
        findsOneWidget,
      );
      expect(find.textContaining('ProjectSurfaceAnimation'), findsNothing);
      expect(find.textContaining('ProjectSurfacePreset'), findsNothing);
    });

    testWidgets('sans rôle assigné : invite à assigner', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SurfaceStudioVerticalAtlasAnimationPreview(
              label: Colors.white,
              subtle: Colors.grey,
              mappingDraft: SurfaceStudioColumnRoleMappingDraft.empty(5),
              tileWidth: 32,
              tileHeight: 32,
              columns: 5,
              rows: 10,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.textContaining(
          'Assignez un rôle à une colonne pour prévisualiser son animation.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'suggestion standard : frames, navigation modulo, source rect',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SurfaceStudioVerticalAtlasAnimationPreview(
                label: Colors.white,
                subtle: Colors.grey,
                mappingDraft: SurfaceStudioColumnRoleMappingDraft.suggested(2),
                tileWidth: 32,
                tileHeight: 32,
                columns: 2,
                rows: 4,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.text('Frames : 4'), findsOneWidget);
        expect(find.textContaining('Frame courante : 1 / 4'), findsOneWidget);
        expect(
          find.textContaining('Source rect : x=0, y=0, 32×32'),
          findsOneWidget,
        );

        await tester.tap(find.text('Frame suivante'));
        await tester.pump();
        expect(find.textContaining('Frame courante : 2 / 4'), findsOneWidget);
        expect(
          find.textContaining('Source rect : x=0, y=32, 32×32'),
          findsOneWidget,
        );

        await tester.tap(find.text('Frame précédente'));
        await tester.pump();
        expect(find.textContaining('Frame courante : 1 / 4'), findsOneWidget);

        await tester.tap(find.text('Frame précédente'));
        await tester.pump();
        expect(find.textContaining('Frame courante : 4 / 4'), findsOneWidget);

        await tester.tap(find.text('Frame suivante'));
        await tester.pump();
        expect(find.textContaining('Frame courante : 1 / 4'), findsOneWidget);
      },
    );

    testWidgets('23 colonnes × 32 lignes : 32 frames affichées',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurfaceStudioVerticalAtlasAnimationPreview(
              label: Colors.white,
              subtle: Colors.grey,
              mappingDraft: SurfaceStudioColumnRoleMappingDraft.suggested(23),
              tileWidth: 32,
              tileHeight: 32,
              columns: 23,
              rows: 32,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Frames : 32'), findsOneWidget);
    });

    testWidgets('preview controls stay constrained on narrow width',
        (tester) async {
      tester.view.physicalSize = const Size(420, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 260,
                child: SurfaceStudioVerticalAtlasAnimationPreview(
                  label: Colors.white,
                  subtle: Colors.grey,
                  mappingDraft:
                      SurfaceStudioColumnRoleMappingDraft.suggested(2),
                  tileWidth: 32,
                  tileHeight: 32,
                  columns: 2,
                  rows: 4,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('surface_animation_preview_actions')),
          findsOneWidget);
      final preview =
          find.byKey(const ValueKey('surface_animation_preview_tile_box'));
      expect(preview, findsOneWidget);
      final size = tester.getSize(preview);
      expect(size.width, lessThanOrEqualTo(96));
      expect(size.height, lessThanOrEqualTo(96));
    });
  });
}

```

