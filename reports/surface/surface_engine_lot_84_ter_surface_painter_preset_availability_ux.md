# Lot 84-ter — Surface Painter Preset Availability UX / Catalog Completion Guard V0

## Résumé exécutif

Le Lot 84-ter corrige le blocage UX restant du Surface Painter : un utilisateur pouvait créer un `SurfaceLayer`, voir un catalogue avec des atlas et des animations, mais rester bloqué sur `Presets : 0` avec un simple message trop vague.

La palette Surface affiche maintenant un état de disponibilité du catalogue :

- compteurs `Atlas`, `Animations`, `Presets` ;
- message différent pour catalogue vide, atlas seul, atlas + animations sans preset, et presets disponibles ;
- explication explicite qu’un preset Surface est l’unité peignable ;
- CTA léger `Ouvrir Surface Studio` ;
- message dédié quand un calque Surface existe déjà mais qu’aucun preset n’est peignable.

Aucun preset n’est créé automatiquement. Aucun rendu Surface, resolver autotile, runtime renderer, migration ou changement `map_core` n’a été ajouté.

## Périmètre

Inclus :

- UX locale du panneau `SurfacePainterPanel` / `SurfacePalettePanel`.
- Petit modèle editor-only `SurfaceCatalogAvailability`.
- Tests widget et tests purs ciblés.
- Rapport d’audit du lot.

Exclus :

- `map_core`.
- `map_runtime`.
- `map_gameplay`.
- `map_battle`.
- `ProjectManifest`, `surface.dart`, `surface_catalog.dart`.
- Création automatique de `ProjectSurfacePreset`.
- Rendu canvas des surfaces.
- Resolver autotile.
- Surface preview static/animated.
- Migration legacy.

## Gate 0 — Status initial avant modification

Commande lancée avant toute modification :

```text
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git log --oneline -n 10
```

Sortie capturée :

```text
/Users/karim/Project/pokemonProject
main
f3a37532 feat(map_editor): add surface painter entry flow
d2a3ca2e feat(map): add surface layer model and placement ops
6cc7fafa docs: update agent workflow guidance
9645a04b docs(surface): decide surface placement model
19c75e77 feat(map_editor): ajouter preset vertical atlas et golden slice e2e
ccdf1094 fix(map_editor): lisibilité et ergonomie sélecteur colonne aperçu atlas
33d776aa feat(map_editor): Lot 78 — animations Surface depuis atlas vertical
1a92a64e feat(map_editor): Surface Studio Lot 77 — plan génération animations atlas vertical
021abf5f feat(map_editor): Surface Studio Lots 75–76 — mapping colonnes + preview animation
cd9bf788 feat(map_editor): Surface Studio Lot 74 — assistant atlas vertical + preview grand format
```

`git status --short --untracked-files=all` était vide et `git diff --stat` était vide dans cette sortie groupée. Le worktree était donc propre au début du Lot 84-ter.

## Audit Surface Painter empty state

Commandes d’audit lancées :

```text
rg -n "Aucune surface disponible|Créez des surfaces|Surface sélectionnée|surfaceCatalog|presets|atlases|animations" packages/map_editor/lib packages/map_editor/test
rg -n "SurfacePainterPanel|SurfacePalettePanel|selectedSurfacePresetId|surfacePaint|SurfaceLayer" packages/map_editor/lib packages/map_editor/test
rg -n "Surface Studio|surfaceStudio|Workspace|Catalogues|SurfaceStudioPanel" packages/map_editor/lib packages/map_editor/test
```

Constats :

- Le message trop vague venait de `packages/map_editor/lib/src/features/surface_painter/surface_palette_panel.dart`.
- `SurfacePalettePanel` affichait seulement `Aucune surface disponible` quand `presets.isEmpty`.
- `SurfacePainterPanel` lisait déjà `state.project?.surfaceCatalog.presets`, mais pas les compteurs `atlases` / `animations`.
- Les tests existants ne couvraient pas le cas `Atlas : 1`, `Animations : 20`, `Presets : 0`.
- Le flux paint restait bien bloqué sans preset sélectionné via les tests existants du contrôleur.

## Audit catalogue Surface disponible côté editor

Fichiers consultés :

- `packages/map_editor/lib/src/features/surface_painter/surface_palette_panel.dart`
- `packages/map_editor/test/surface_painter/surface_palette_panel_test.dart`
- `packages/map_editor/test/surface_painter/surface_painting_controller_test.dart`
- `packages/map_editor/test/surface_painter/editor_notifier_surface_paint_test.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart`
- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`
- `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
- `packages/map_core/test/project_surface_catalog_test.dart`

Constats :

- `ProjectSurfaceCatalog` expose déjà `atlasCount`, `animationCount`, `presetCount`, `atlases`, `animations`, `presets`.
- `ProjectSurfaceCatalog()` représente un catalogue vide.
- `EditorNotifier` expose déjà `selectSurfaceStudioWorkspace()`.
- `Surface Studio` est déjà accessible depuis la toolbar et le Project Explorer.
- Le CTA peut donc appeler une navigation existante sans créer de route, provider, repository ou service.

## Décision UX

Décision :

- Ajouter un état local `SurfaceCatalogAvailability` dans `map_editor`.
- Calculer cet état depuis `ProjectManifest.surfaceCatalog`.
- Afficher les compteurs dans le Surface Painter.
- Remplacer le message générique par des messages actionnables :
  - catalogue vide : créer atlas, animations, preset ;
  - atlas sans animations : générer animations puis créer preset ;
  - animations sans preset : créer un preset Surface puis appliquer/sauvegarder ;
  - presets présents : sélectionner une surface à peindre.
- Si un `SurfaceLayer` existe déjà mais `presetCount == 0`, afficher que le calque existe mais qu’aucune surface n’est peignable.

Cette décision garde le modèle mental du Lot 84 : le painter place des `surfacePresetId`, pas des atlas ni des animations.

## Décision CTA Surface Studio

CTA ajouté : oui.

Justification :

- `EditorNotifier.selectSurfaceStudioWorkspace()` existe déjà.
- `SurfacePainterPanel` est déjà un `ConsumerWidget` qui lit le notifier.
- Ajouter `Ouvrir Surface Studio` ne nécessite pas de refactor de navigation.
- Le CTA reste un lien d’aide ; il ne crée pas de preset et ne modifie pas le catalogue.

## Implémentation

Ajout :

- `SurfaceCatalogAvailability`
  - `atlasCount`
  - `animationCount`
  - `presetCount`
  - `hasAnyAtlas`
  - `hasAnyAnimation`
  - `hasAnyPreset`
  - `canPaint`
  - `primaryMessage`
  - `secondaryMessage`
  - `recommendedActionLabel`

Modification :

- `SurfacePalettePanel`
  - accepte `availability`;
  - affiche `Catalogue Surface : Atlas / Animations / Presets`;
  - affiche les messages détaillés ;
  - affiche `Ouvrir Surface Studio` quand aucun preset n’est disponible ;
  - continue de lister les presets quand ils existent.
- `SurfacePainterPanel`
  - calcule `SurfaceCatalogAvailability.fromCatalog(...)`;
  - garde `Peindre Surface` désactivé si `presetCount == 0`;
  - affiche `Un calque Surface existe, mais aucune surface n’est encore peignable.` quand le layer existe sans preset.

Ce qui n’a pas été fait :

- aucune création automatique de preset ;
- aucun rendu Surface ;
- aucun resolver autotile ;
- aucune modification `map_core` ;
- aucune modification `map_runtime`.

## Fichiers créés

- `packages/map_editor/lib/src/features/surface_painter/surface_catalog_availability.dart`
- `packages/map_editor/test/surface_painter/surface_catalog_availability_test.dart`
- `reports/surface/surface_engine_lot_84_ter_surface_painter_preset_availability_ux.md`

## Fichiers modifiés

- `packages/map_editor/lib/src/features/surface_painter/surface_palette_panel.dart`
- `packages/map_editor/test/surface_painter/surface_palette_panel_test.dart`

## Fichiers supprimés

Aucun.

## Tests lancés

### Test rouge initial

Commande :

```text
cd packages/map_editor && flutter test test/surface_painter
```

Résultat attendu avant implémentation :

```text
Error: Error when reading 'lib/src/features/surface_painter/surface_catalog_availability.dart': No such file or directory
Error: No named parameter with the name 'availability'.
Some tests failed.
```

### Surface Painter

Commande finale :

```text
cd packages/map_editor && flutter test test/surface_painter
```

Résultat :

```text
00:02 +20: All tests passed!
```

### Map selection controller

Commande :

```text
cd packages/map_editor && flutter test test/map_selection_controller_test.dart
```

Résultat :

```text
00:01 +5: All tests passed!
```

### Surface Studio

Première tentative :

```text
cd packages/map_editor && flutter test test/surface_studio
```

Cette commande avait été lancée en parallèle avec une autre commande Flutter et a d’abord attendu le startup lock. La sortie compacte a fini avec `Some tests failed`, sans diagnostic stable exploitable dans la portion capturée. J’ai donc relancé isolément en mode expansé.

Relance isolée :

```text
cd packages/map_editor && flutter test test/surface_studio --reporter expanded
```

Résultat :

```text
00:11 +387: All tests passed!
```

Conclusion : la suite Surface Studio est verte lorsqu’elle n’est pas lancée en concurrence avec une autre commande Flutter.

## Analyse lancée

Commande :

```text
cd packages/map_editor && flutter analyze lib/src/features/surface_painter/surface_catalog_availability.dart lib/src/features/surface_painter/surface_palette_panel.dart test/surface_painter/surface_catalog_availability_test.dart test/surface_painter/surface_palette_panel_test.dart
```

Résultat :

```text
No issues found! (ran in 1.1s)
```

Analyse globale `map_editor` non lancée : le lot ne modifie que deux fichiers de production ciblés et deux tests ciblés ; le prompt rend l’analyse globale optionnelle si l’analyse ciblée est clean.

## Résultats

- Blocage `Presets : 0` expliqué.
- Cas `Atlas : 1`, `Animations : 20`, `Presets : 0` testé.
- Presets existants toujours listés et sélectionnables.
- `Peindre Surface` reste désactivé sans preset sélectionné.
- `SurfaceLayer` existant + aucun preset affiche un message explicite.
- CTA vers Surface Studio ajouté sans nouveau système de navigation.
- Aucun changement hors `map_editor` et rapport.

## Evidence Pack

### Fichiers audités

- `packages/map_editor/lib/src/features/surface_painter/surface_palette_panel.dart`
- `packages/map_editor/test/surface_painter/surface_palette_panel_test.dart`
- `packages/map_editor/test/surface_painter/surface_painting_controller_test.dart`
- `packages/map_editor/test/surface_painter/editor_notifier_surface_paint_test.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart`
- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`
- `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
- `packages/map_core/test/project_surface_catalog_test.dart`

### Diff stat avant rapport

```text
.../surface_painter/surface_palette_panel.dart     | 128 +++++++++++--
.../surface_palette_panel_test.dart                | 199 ++++++++++++++++++++-
2 files changed, 315 insertions(+), 12 deletions(-)
```

Les deux nouveaux fichiers Dart étaient encore non suivis et ne figurent donc pas dans ce `git diff --stat`.

### Tests / analyse

```text
flutter test test/surface_painter
=> 00:02 +20: All tests passed!

flutter test test/map_selection_controller_test.dart
=> 00:01 +5: All tests passed!

flutter test test/surface_studio --reporter expanded
=> 00:11 +387: All tests passed!

flutter analyze lib/src/features/surface_painter/surface_catalog_availability.dart lib/src/features/surface_painter/surface_palette_panel.dart test/surface_painter/surface_catalog_availability_test.dart test/surface_painter/surface_palette_panel_test.dart
=> No issues found! (ran in 1.1s)

git diff --check
=> aucune sortie, code 0
```

## Git status final

Commande :

```text
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_editor/lib/src/features/surface_painter/surface_palette_panel.dart
 M packages/map_editor/test/surface_painter/surface_palette_panel_test.dart
?? packages/map_editor/lib/src/features/surface_painter/surface_catalog_availability.dart
?? packages/map_editor/test/surface_painter/surface_catalog_availability_test.dart
?? reports/surface/surface_engine_lot_84_ter_surface_painter_preset_availability_ux.md
```

Commande :

```text
git diff --stat
```

Sortie :

```text
.../surface_painter/surface_palette_panel.dart     | 130 ++++++++++++--
.../surface_palette_panel_test.dart                | 199 ++++++++++++++++++++-
2 files changed, 317 insertions(+), 12 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers non suivis, donc le nouveau helper, le nouveau test et ce rapport apparaissent uniquement dans `git status`.

## Changements préexistants

Aucun changement préexistant au Gate 0.

## Changements du Lot 84-ter

- Création de l’état local de disponibilité du catalogue Surface.
- Enrichissement de l’état vide du Surface Painter.
- Ajout du CTA vers Surface Studio.
- Ajout de tests ciblant les cas `0/0/0`, `1/0/0`, `1/20/0`, `presetCount > 0`, et `SurfaceLayer existant + 0 preset`.

## Périmètre explicitement non touché

- `ProjectManifest` non modifié.
- `surface.dart` non modifié.
- `surface_catalog.dart` non modifié.
- Codecs Surface non modifiés.
- `map_core` non modifié.
- `map_runtime` non modifié.
- `map_gameplay` non modifié.
- `map_battle` non modifié.
- Aucun renderer runtime Surface créé.
- Aucun resolver autotile Surface créé.
- Aucune animation clock runtime créée.
- Aucune migration legacy codée.
- Aucun provider/repository/service Surface créé.
- Aucune refonte Surface Studio.
- Aucun rendu des surfaces sur le canvas.
- `Runner.xcscheme` non modifié par ce lot.

## Vérification fichiers temporaires

Commande :

```text
find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
```

Sortie :

```text
```

Aucun fichier temporaire détecté.

Commande :

```text
git diff --check
```

Sortie :

```text
```

Aucun whitespace error détecté.

## Vérification mojibake

Les textes ajoutés sont volontairement en français avec accents, comme les textes voisins du Surface Painter et des rapports Surface. Aucun mojibake détecté visuellement dans les fichiers modifiés.

## Auto-review

- Est-ce que le message “Aucune surface disponible” est remplacé ou enrichi ? Oui.
- Est-ce que le cas Atlas > 0 / Animations > 0 / Presets = 0 est expliqué ? Oui, avec le message `Animations Surface trouvées, mais aucun preset peignable.`
- Est-ce que l’utilisateur comprend qu’il doit créer un preset Surface ? Oui.
- Est-ce que les counts Atlas / Animations / Presets sont affichés ? Oui.
- Est-ce qu’un SurfaceLayer existant sans preset est expliqué ? Oui.
- Est-ce que les presets présents restent listés normalement ? Oui.
- Est-ce qu’un CTA Surface Studio est ajouté ? Oui, via `selectSurfaceStudioWorkspace()`.
- Est-ce que paint reste bloqué sans preset sélectionné ? Oui.
- Est-ce qu’un preset est créé automatiquement ? Non.
- Est-ce qu’un rendu Surface est ajouté ? Non.
- Est-ce qu’un resolver autotile est ajouté ? Non.
- Est-ce que `map_core` est modifié ? Non.
- Est-ce que `map_runtime` est modifié ? Non.
- Est-ce que les tests ciblés passent ? Oui.
- Est-ce que l’analyse ciblée passe ? Oui.
- Est-ce qu’un fichier présent au status initial a disparu du status final ? Non.
- Est-ce qu’un fichier hors périmètre a été modifié ? Non.
- Est-ce qu’un 84-quater est nécessaire ? Non pour ce blocage précis. La suite logique est une preview Surface, mais c’est un autre lot.

## Critique du prompt

- Le terme “preset” reste un peu technique pour un utilisateur no-code, mais il est déjà installé dans l’UI Surface Studio ; le lot l’explique donc plutôt que le masquer.
- Le CTA vers Surface Studio est utile ici parce que la navigation existait déjà. Sans cette méthode du notifier, il aurait fallu se limiter à un message pour éviter une refonte.
- Ce lot améliore la compréhension du blocage, mais ne rend pas encore le résultat visible sur la map. L’UX restera donc partielle tant que la preview Surface n’existe pas.
- La demande de relancer tout `test/surface_studio` est pertinente mais longue ; il faut éviter de la lancer en parallèle avec d’autres commandes Flutter à cause du startup lock.
