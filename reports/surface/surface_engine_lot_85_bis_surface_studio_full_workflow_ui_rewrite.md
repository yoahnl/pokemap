# Lot 85-bis — Surface Studio Full Workflow UI Rewrite V1.1

## Résumé exécutif

Le Lot 85-bis reprend le Surface Studio après le Lot 85 pour corriger le problème structurel restant : l'écran ressemblait encore trop à une pile verticale de formulaires. La refonte introduit un vrai layout principal multi-colonnes sur desktop large : assistant de création, workspace atlas/grille, animations détectées, surfaces prêtes à peindre.

Le lot reste strictement UI/UX `map_editor`. Aucun modèle `map_core`, aucun JSON, aucun runtime, aucun resolver et aucun save flow métier n'a été modifié.

## Périmètre

Inclus :

- refactor UI de `SurfaceStudioPanel`;
- extraction de `SurfaceStudioWorkflowLayout`;
- réorganisation visuelle de `SurfaceStudioAtlasAuthoringPrep`;
- test widget garantissant le layout desktop quatre zones côte à côte;
- rapport de lot.

Exclus :

- `map_core`;
- `map_runtime`;
- `map_gameplay`;
- `map_battle`;
- modèles Surface;
- codecs JSON;
- génération métier atlas / animations / preset;
- runtime renderer;
- resolver autotile;
- preview canvas.

## Gate 0 — Status initial avant modification

Commande `pwd` :

```text
/Users/karim/Project/pokemonProject
```

Commande `git branch --show-current` :

```text
main
```

Commande `git status --short --untracked-files=all` :

```text
 M packages/map_editor/lib/src/features/surface_painter/surface_palette_panel.dart
 M packages/map_editor/test/surface_painter/surface_palette_panel_test.dart
?? packages/map_editor/lib/src/features/surface_painter/surface_catalog_availability.dart
?? packages/map_editor/test/surface_painter/surface_catalog_availability_test.dart
?? reports/surface/surface_engine_lot_84_ter_surface_painter_preset_availability_ux.md
```

Commande `git diff --stat` :

```text
 .../surface_painter/surface_palette_panel.dart     | 130 ++++++++++++--
 .../surface_palette_panel_test.dart                | 199 ++++++++++++++++++++-
 2 files changed, 317 insertions(+), 12 deletions(-)
```

Commande `git log --oneline -n 10` :

```text
b20287da feat(map_editor): redesign surface studio workflow
f3a37532 feat(map_editor): add surface painter entry flow
d2a3ca2e feat(map): add surface layer model and placement ops
6cc7fafa docs: update agent workflow guidance
9645a04b docs(surface): decide surface placement model
19c75e77 feat(map_editor): ajouter preset vertical atlas et golden slice e2e
ccdf1094 fix(map_editor): lisibilité et ergonomie sélecteur colonne aperçu atlas
33d776aa feat(map_editor): Lot 78 — animations Surface depuis atlas vertical
1a92a64e feat(map_editor): Surface Studio Lot 77 — plan génération animations atlas vertical
021abf5f feat(map_editor): Surface Studio Lots 75–76 — mapping colonnes + preview animation
```

Le status initial n'était pas vide. Ces fichiers appartiennent au Lot 84-ter préexistant et ne sont pas revertés par ce lot.

## Analyse de l’image de référence

Structure générale :

- la sidebar globale reste à gauche;
- Surface Studio occupe un workspace clair avec header, stepper et grille;
- la lecture se fait de gauche à droite : assistant, atlas, animations, surfaces peignables;
- les actions finales sont visibles dans le panneau droit.

Colonnes principales :

- colonne assistant : checklist, aide et compteurs;
- colonne atlas : grande preview et validation de grille;
- colonne animations : liste des animations générées;
- colonne surfaces : presets peignables et CTA.

Rôle du stepper :

- il donne une progression immédiate en quatre étapes;
- il explique que la surface peignable est le résultat final, pas l'atlas ni l'animation.

Différence avec l'UI après Lot 85 :

- Lot 85 avait les bons libellés, mais encore une structure en trois zones puis une longue colonne;
- l'image cible exige une hiérarchie horizontale plus nette et moins de scroll avant les décisions importantes.

Choix repris :

- layout desktop multi-colonnes;
- assistant à gauche;
- atlas et validation au centre;
- animations et surfaces séparées;
- détails avancés relégués sous le workflow principal.

Choix non repris :

- pas de miniature de frame générée dans chaque animation, car le lot ne devait pas ajouter de preview animée réelle;
- pas de nouveau système de navigation ou d'action globale;
- pas de rendu atlas supplémentaire hors widgets existants.

## Audit de l’UI actuelle après Lot 85

Fichiers audités :

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_creation_assistant.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_detected_animations_panel.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_paintable_surfaces_panel.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_workflow_stepper.dart`
- `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart`

Constat :

- `SurfaceStudioPanel` utilisait un layout responsive, mais le desktop large restait en trois blocs : assistant, authoring, outcome panels;
- animations et surfaces étaient empilées dans une même colonne;
- inspection, catalogue, diagnostics et actions futures restaient des sections directes du scroll principal;
- `SurfaceStudioAtlasAuthoringPrep` affichait encore beaucoup de sous-étapes dans un long ordre vertical, avec la grande preview placée trop tard.

## Problèmes identifiés

- Pas de vraie grille quatre zones sur desktop large.
- Les surfaces prêtes à peindre n'étaient pas un panneau droit dédié.
- Le bloc atlas central mélangeait action, mapping, génération, preview et validation dans un ordre trop formulaire.
- Les détails avancés dominaient encore la fin directe du flux au lieu d'être regroupés.
- Les tests Lot 85 validaient surtout des textes, pas l'architecture visuelle.

## Décision UX globale

Décision : créer un layout workflow dédié qui impose un desktop large en quatre lanes :

1. Assistant de création.
2. Workspace atlas / grille.
3. Animations détectées.
4. Surfaces prêtes à peindre.

Les écrans plus étroits conservent un responsive en deux colonnes puis en pile, mais le cas principal desktop exploite explicitement la largeur.

## Nouveau layout

Nouveau widget :

```text
SurfaceStudioWorkflowLayout
```

Comportement :

- `maxWidth >= 1280` : Row quatre zones;
- `900 <= maxWidth < 1280` : deux colonnes;
- `< 900` : pile verticale responsive.

Clés testables :

- `surface_studio_workflow_desktop_grid`
- `surface_studio_workflow_assistant_lane`
- `surface_studio_workflow_atlas_lane`
- `surface_studio_workflow_animations_lane`
- `surface_studio_workflow_surfaces_lane`
- `surface_studio_workflow_tablet_grid`
- `surface_studio_workflow_stacked`

## Header

Le header existant est conservé :

- titre `Surface Studio`;
- description no-code;
- compteurs `Atlas`, `Animations`, `Surfaces`;
- badge lecture seule / édition partielle.

Il reste compact et n'a pas été transformé en section décorative.

## Stepper

Le stepper Lot 85 est conservé :

- `1. Atlas`;
- `2. Grille`;
- `3. Animations`;
- `4. Surfaces prêtes à peindre`.

Il reste sous le header, avant le workspace principal.

## Assistant de création

Le panneau assistant est conservé et devient la première lane du layout desktop.

Il contient :

- checklist;
- compteurs;
- carte `Ce que vous faites ici`;
- explication atlas / animations / surfaces.

## Atlas source

La préparation atlas est réorganisée en cartes internes. La première carte est maintenant `Atlas source`.

Elle contient :

- état brouillon;
- sélection image source;
- actions historiques nécessaires au flux (`Charger la sélection`, `Modifier cet atlas`, `Créer l'atlas`, etc.);
- grande preview atlas.

Point important : les actions ont été remontées dans cette carte pour éviter de recréer un deadlock UX et pour préserver les tests historiques qui interagissent avec elles sans scroll profond.

## Découpage et validation

La carte `Découpage et validation` est placée immédiatement après `Atlas source`.

Elle regroupe :

- largeur / hauteur tuile;
- colonnes / lignes;
- disposition;
- aperçu grille;
- état `Structure détectée automatiquement` ou correction nécessaire;
- erreurs de validation.

## Animations détectées

Les animations ne sont plus empilées avec les surfaces dans une même colonne. Elles ont leur lane dédiée sur desktop large via `SurfaceStudioDetectedAnimationsPanel`.

Ce panneau conserve :

- état vide clair;
- liste des animations;
- frame count;
- atlas lié.

## Surfaces prêtes à peindre

Le panneau `SurfaceStudioPaintableSurfacesPanel` devient la lane droite du layout desktop.

Il conserve :

- explication no-code;
- état `Animations détectées, mais aucune surface peignable.`;
- cartes de surfaces peignables;
- CTA `Créer une surface`;
- CTA `Sauvegarder le catalogue` quand callback disponible.

## Zones avancées / diagnostics / inspector

L'inspection, le browser catalogue, les diagnostics, les actions futures et le placeholder `Actions auteur` restent accessibles, mais sont regroupés sous une carte :

```text
Détails avancés
```

Clé :

```text
surface_studio_advanced_details
```

But :

- préserver l'inspection et les tests existants;
- ne plus laisser ces blocs dominer la première expérience utilisateur.

## Implémentation

Changements principaux :

- ajout de `SurfaceStudioWorkflowLayout`;
- `SurfaceStudioPanel` utilise ce layout au lieu d'un Row ad hoc à trois colonnes;
- les détails secondaires sont regroupés dans `_AdvancedDetailsSection`;
- `SurfaceStudioAtlasAuthoringPrep` est réordonné en cartes : atlas source, découpage, animations, surface finale, options avancées;
- les actions d'atlas restent dans la carte `Atlas source` pour être visibles tôt;
- ajout d'un test `85-bis.1` qui vérifie l'existence du grid desktop et l'ordre horizontal des lanes.

## Fichiers créés

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_workflow_layout.dart`
- `reports/surface/surface_engine_lot_85_bis_surface_studio_full_workflow_ui_rewrite.md`

## Fichiers modifiés

Changements du Lot 85-bis :

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart`
- `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`

Changements préexistants Lot 84-ter, non modifiés volontairement par ce lot :

- `packages/map_editor/lib/src/features/surface_painter/surface_palette_panel.dart`
- `packages/map_editor/test/surface_painter/surface_palette_panel_test.dart`
- `packages/map_editor/lib/src/features/surface_painter/surface_catalog_availability.dart`
- `packages/map_editor/test/surface_painter/surface_catalog_availability_test.dart`
- `reports/surface/surface_engine_lot_84_ter_surface_painter_preset_availability_ux.md`

## Fichiers supprimés

Aucun.

## Tests lancés

RED initial :

```bash
cd packages/map_editor && flutter test test/surface_studio/surface_studio_panel_test.dart --plain-name "85-bis.1"
```

Résultat attendu du RED :

```text
Expected: exactly one matching candidate
  Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'surface_studio_workflow_desktop_grid'>]: []>
```

GREEN ciblé :

```bash
cd packages/map_editor && flutter test test/surface_studio/surface_studio_panel_test.dart --plain-name "85-bis.1"
```

Résultat :

```text
00:02 +1: All tests passed!
```

Debug régression authoring :

```bash
cd packages/map_editor && flutter test test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
```

Premier résultat intermédiaire : échec dû aux actions déplacées trop bas. Correction appliquée en remontant les actions dans `Atlas source`.

Résultat après correction :

```text
00:07 +37: All tests passed!
```

Suite Surface Studio :

```bash
cd packages/map_editor && flutter test test/surface_studio
```

Résultat :

```text
00:15 +392: All tests passed!
```

Surface Painter non-régression :

```bash
cd packages/map_editor && flutter test test/surface_painter
```

Résultat :

```text
00:03 +20: All tests passed!
```

Map selection non-régression :

```bash
cd packages/map_editor && flutter test test/map_selection_controller_test.dart
```

Résultat :

```text
00:01 +5: All tests passed!
```

## Analyse lancée

Analyse ciblée :

```bash
cd packages/map_editor && flutter analyze lib/src/features/surface_studio/surface_studio_panel.dart lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart lib/src/features/surface_studio/surface_studio_workflow_layout.dart test/surface_studio/surface_studio_panel_test.dart lib/src/features/surface_painter/surface_palette_panel.dart lib/src/features/surface_painter/surface_catalog_availability.dart test/surface_painter/surface_palette_panel_test.dart test/surface_painter/surface_catalog_availability_test.dart
```

Résultat :

```text
Analyzing 8 items...
No issues found! (ran in 1.6s)
```

Format :

```bash
cd packages/map_editor && dart format lib/src/features/surface_studio/surface_studio_panel.dart lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart lib/src/features/surface_studio/surface_studio_workflow_layout.dart test/surface_studio/surface_studio_panel_test.dart
```

Résultat final :

```text
Formatted 4 files (0 changed) in 0.03 seconds.
```

## Résultats

- Surface Studio passe avec `+392`.
- Surface Painter passe avec `+20`.
- Map selection passe avec `+5`.
- Analyse ciblée clean.
- Aucun changement `map_core`.
- Aucun changement `map_runtime`.

## Evidence Pack

Fichiers audités :

- `packages/map_editor/pubspec.yaml`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_creation_assistant.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_detected_animations_panel.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_paintable_surfaces_panel.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_workflow_stepper.dart`
- `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart`

Fichiers créés par le lot :

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_workflow_layout.dart`
- `reports/surface/surface_engine_lot_85_bis_surface_studio_full_workflow_ui_rewrite.md`

Fichiers modifiés par le lot :

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart`
- `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`

Fichiers préexistants au status initial :

- `packages/map_editor/lib/src/features/surface_painter/surface_palette_panel.dart`
- `packages/map_editor/test/surface_painter/surface_palette_panel_test.dart`
- `packages/map_editor/lib/src/features/surface_painter/surface_catalog_availability.dart`
- `packages/map_editor/test/surface_painter/surface_catalog_availability_test.dart`
- `reports/surface/surface_engine_lot_84_ter_surface_painter_preset_availability_ux.md`

Diff stat observé avant rapport :

```text
 .../surface_painter/surface_palette_panel.dart     |  130 ++-
 .../surface_studio_atlas_authoring_prep.dart       | 1016 +++++++++++---------
 .../surface_studio/surface_studio_panel.dart       |  163 ++--
 .../surface_palette_panel_test.dart                |  199 +++-
 .../surface_studio/surface_studio_panel_test.dart  |   56 ++
 5 files changed, 1021 insertions(+), 543 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers non suivis, donc le nouveau layout et les rapports apparaissent dans `git status` mais pas dans cette stat.

## Git status final

Commande `git status --short --untracked-files=all` :

```text
 M packages/map_editor/lib/src/features/surface_painter/surface_palette_panel.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/test/surface_painter/surface_palette_panel_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
?? packages/map_editor/lib/src/features/surface_painter/surface_catalog_availability.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_workflow_layout.dart
?? packages/map_editor/test/surface_painter/surface_catalog_availability_test.dart
?? reports/surface/surface_engine_lot_84_ter_surface_painter_preset_availability_ux.md
?? reports/surface/surface_engine_lot_85_bis_surface_studio_full_workflow_ui_rewrite.md
```

Commande `git diff --stat` :

```text
 .../surface_painter/surface_palette_panel.dart     |  130 ++-
 .../surface_studio_atlas_authoring_prep.dart       | 1016 +++++++++++---------
 .../surface_studio/surface_studio_panel.dart       |  163 ++--
 .../surface_palette_panel_test.dart                |  199 +++-
 .../surface_studio/surface_studio_panel_test.dart  |   56 ++
 5 files changed, 1021 insertions(+), 543 deletions(-)
```

Commande `git diff --check` :

```text

```

Sortie vide, exit code 0.

## Changements préexistants

Préexistants au Gate 0 :

- modifications Lot 84-ter dans `surface_palette_panel.dart`;
- modifications Lot 84-ter dans `surface_palette_panel_test.dart`;
- nouveau helper Lot 84-ter `surface_catalog_availability.dart`;
- nouveau test Lot 84-ter `surface_catalog_availability_test.dart`;
- rapport Lot 84-ter.

Ces changements n'ont pas été revertés. L'analyse ciblée inclut aussi ces fichiers pour vérifier qu'ils restent propres.

## Changements du Lot 85-bis

- Nouveau layout desktop quatre lanes.
- Réorganisation de `SurfaceStudioPanel` autour de ce layout.
- Regroupement des détails secondaires.
- Réorganisation de la carte d'authoring atlas.
- Test de layout horizontal.
- Rapport Lot 85-bis.

## Périmètre explicitement non touché

- `map_core` non modifié.
- `ProjectManifest` non modifié.
- `surface.dart` non modifié.
- `surface_catalog.dart` non modifié.
- codecs Surface non modifiés.
- `map_runtime` non modifié.
- `map_gameplay` non modifié.
- `map_battle` non modifié.
- aucun renderer runtime Surface créé.
- aucun resolver autotile Surface créé.
- aucune animation clock runtime créée.
- aucune migration legacy codée.
- aucun provider/repository/service Surface créé.
- aucun changement JSON.
- `Runner.xcscheme` non modifié par ce lot.

## Vérification fichiers temporaires

Commande :

```bash
find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
```

Résultat :

```text

```

Sortie vide, aucun fichier temporaire détecté.

## Vérification mojibake

Commande large :

```bash
rg -n "Ã|Â|â€™|â€œ|â€|�" packages/map_editor/lib/src/features/surface_studio packages/map_editor/test/surface_studio reports/surface/surface_engine_lot_85_bis_surface_studio_full_workflow_ui_rewrite.md
```

Résultat :

```text
packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generation_plan.dart:129:      'àáâãäåèéêëìíîïòóôõöùúûüýÿçñÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÝŸÇÑ';
```

Ce résultat est un faux positif préexistant : la ligne contient volontairement un alphabet accentué accepté par le normalizer, et le fichier n'est pas modifié par le Lot 85-bis.

Commande ciblée sur les fichiers modifiés/créés par le Lot 85-bis :

```bash
rg -n "Ã|Â|â€™|â€œ|â€|�" packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart packages/map_editor/lib/src/features/surface_studio/surface_studio_workflow_layout.dart packages/map_editor/test/surface_studio/surface_studio_panel_test.dart reports/surface/surface_engine_lot_85_bis_surface_studio_full_workflow_ui_rewrite.md
```

Résultat :

```text

```

Sortie vide, aucun mojibake détecté dans les fichiers du lot.

## Auto-review

- Est-ce que Surface Studio ressemble beaucoup plus à l’image de référence ? Oui, par l'organisation quatre lanes desktop.
- Est-ce que l’écran utilise un vrai layout multi-colonnes ? Oui.
- Est-ce que les 4 étapes sont visibles ? Oui.
- Est-ce que l’assistant de création est visible ? Oui.
- Est-ce que l’utilisateur comprend atlas / animations / surfaces peignables ? Oui, via l'assistant, le stepper et les panneaux séparés.
- Est-ce que la preview atlas reste grande ? Oui, elle est dans `Atlas source` en `largeFormat`.
- Est-ce que les animations sont dans un panneau dédié ? Oui.
- Est-ce que les surfaces prêtes à peindre sont dans un panneau droit dédié ? Oui sur desktop large.
- Est-ce que le cas animations présentes / surfaces absentes est clair ? Oui, le panneau surfaces garde le message explicite.
- Est-ce que les CTA sont visibles ? Oui, `Créer une surface` et `Sauvegarder le catalogue` restent dans le panneau surfaces.
- Est-ce que les actions existantes sont conservées ? Oui, les actions atlas historiques ont même été remontées pour éviter le deadlock.
- Est-ce que map_core est modifié ? Non.
- Est-ce que map_runtime est modifié ? Non.
- Est-ce que le save flow est conservé ? Oui.
- Est-ce que les tests Surface Studio passent ? Oui, `+392`.
- Est-ce que les tests Surface Painter passent ? Oui, `+20`.
- Est-ce que l’analyse ciblée passe ? Oui.
- Est-ce qu’un 85-ter est nécessaire ? Non pour le layout demandé. Un futur lot pourra traiter la vraie preview animée, mais c'est hors périmètre.

## Critique du prompt

- Le prompt demande une proximité visuelle forte avec l'image, mais sans screenshot automatique dans ce lot; la conformité reste évaluée par structure, clés et tests de layout.
- Réorganiser fortement `SurfaceStudioAtlasAuthoringPrep` sans toucher la logique métier est délicat, car ce widget concentre encore beaucoup d'actions historiques.
- Les tests existants interagissent avec des widgets sans toujours scroller; il fallait donc remonter les actions principales au lieu de simplement les déplacer en section avancée.
- Le résultat est nettement plus structuré, mais l'absence de vraie preview de surface peignable reste une limite volontaire du périmètre.
