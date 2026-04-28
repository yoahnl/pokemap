# Lot 85 — Surface Studio Workflow Redesign V1

## Résumé exécutif

Surface Studio a été réorganisé comme un workflow guidé `atlas -> grille -> animations -> surfaces prêtes à peindre`.

Le lot reste strictement UI/UX `map_editor` :

- aucun changement `map_core`;
- aucun changement JSON;
- aucun changement `ProjectManifest`;
- aucun runtime renderer;
- aucun resolver autotile;
- aucune modification de la logique profonde de génération atlas / animations / surface peignable.

Le nouvel écran met désormais en premier :

- un header clair avec compteurs `Atlas / Animations / Surfaces`;
- un stepper 4 étapes;
- un assistant de création;
- une carte d’aide expliquant atlas / animations / surfaces;
- un panneau `Animations détectées`;
- un panneau `Surfaces prêtes à peindre`;
- des messages explicites quand des animations existent mais qu’aucune surface peignable n’existe encore.

Les blocs historiques de catalogue, diagnostics et inspecteur restent disponibles comme zones secondaires.

## Périmètre

Périmètre touché :

- `packages/map_editor/lib/src/features/surface_studio/**`
- `packages/map_editor/test/surface_studio/**`
- ce rapport.

Périmètre non touché :

- `packages/map_core/**`
- `packages/map_runtime/**`
- `packages/map_gameplay/**`
- `packages/map_battle/**`
- modèles Surface persistants;
- codecs JSON;
- save flow projet;
- runtime Flame.

## Gate 0 — Status initial avant modification

Commande exécutée avant toute modification Lot 85 :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git log --oneline -n 10
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
 M packages/map_editor/lib/src/features/surface_painter/surface_palette_panel.dart
 M packages/map_editor/test/surface_painter/surface_palette_panel_test.dart
?? packages/map_editor/lib/src/features/surface_painter/surface_catalog_availability.dart
?? packages/map_editor/test/surface_painter/surface_catalog_availability_test.dart
?? reports/surface/surface_engine_lot_84_ter_surface_painter_preset_availability_ux.md
 .../surface_painter/surface_palette_panel.dart     | 130 ++++++++++++--
 .../surface_palette_panel_test.dart                | 199 ++++++++++++++++++++-
 2 files changed, 317 insertions(+), 12 deletions(-)
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

Conclusion Gate 0 : le worktree n’était pas vide. Les changements Lot 84-ter ci-dessus sont préexistants et n’ont pas été revert.

## Analyse de l’image de référence

L’image jointe montre une structure produit claire :

- navigation globale à gauche, non modifiée par ce lot;
- workspace Surface Studio avec header, stepper, grande preview atlas et panneaux de progression;
- assistant à gauche;
- atlas / découpage au centre;
- animations et surfaces peignables à droite;
- actions principales visibles.

Le lot a repris la hiérarchie UX, pas le pixel-perfect.

## Audit Surface Studio actuel

Fichiers audités :

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_preset_creation_section.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_catalog_browser.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_selection_inspector.dart`
- `packages/map_core/lib/src/operations/surface_studio_read_model.dart`
- `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart`

Constat :

- `SurfaceStudioPanel` affichait surtout header, texte de workflow, bloc d’authoring, inspecteur, catalogue, diagnostics.
- `SurfaceStudioAtlasAuthoringPrep` concentrait la logique atlas, grille, mapping, génération animations et création du preset.
- La dernière étape parlait encore fortement de `preset Surface`, peu compréhensible pour un utilisateur no-code.
- Le browser catalogue restait utile mais ne devait plus être la première expérience.

## Décision UX globale

Décision : ajouter une enveloppe workflow autour des widgets existants.

La logique métier existante reste dans :

- `SurfaceStudioAtlasAuthoringPrep`;
- `SurfaceStudioVerticalAtlasAnimationGenerationPlanSection`;
- `SurfaceStudioVerticalAtlasPresetCreationSection`;
- les générateurs existants.

Le nouveau shell ajoute seulement des panneaux de compréhension :

- progression;
- assistant;
- explication;
- animations détectées;
- surfaces prêtes à peindre.

## Nouveau layout

Desktop large :

- gauche : `SurfaceStudioCreationAssistant`;
- centre : `SurfaceStudioAtlasAuthoringPrep`;
- droite : `SurfaceStudioDetectedAnimationsPanel` + `SurfaceStudioPaintableSurfacesPanel`;
- bas : inspecteur, catalogue, diagnostics et actions secondaires.

Largeur moyenne :

- centre : authoring;
- droite : assistant + panneaux de résultat.

Largeur faible :

- layout empilé : assistant, authoring, animations, surfaces.

## Stepper workflow

Fichier créé :

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_workflow_stepper.dart`

Étapes affichées :

1. `Atlas`
2. `Grille`
3. `Animations`
4. `Surfaces prêtes à peindre`

Le stepper dérive son état de `SurfaceStudioReadModel.summary`.

## Assistant de création

Fichier créé :

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_creation_assistant.dart`

Le panneau affiche :

- checklist de création;
- compteurs `Atlas / Animations / Surfaces`;
- carte visible `Ce que vous faites ici`.

La carte explique :

- un atlas contient les images;
- les animations regroupent les frames;
- les surfaces sont les éléments finaux peignables dans la map.

## Atlas source

`SurfaceStudioAtlasAuthoringPrep` affiche maintenant `Atlas source` au lieu de `Préparation atlas`.

Le texte d’introduction indique :

```text
Choisissez l’image atlas, vérifiez la grille, puis générez les animations et la surface peignable.
```

Les contrôleurs, champs, source picker, mapping colonnes, preview animation et génération restent inchangés fonctionnellement.

## Découpage et validation

La zone de grille est renommée visuellement :

```text
Découpage et validation
```

Le but est de rendre explicite que cette étape vérifie la structure de l’atlas avant de générer animations et surface peignable.

## Animations détectées

Fichier créé :

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_detected_animations_panel.dart`

Le panneau affiche :

- `Animations détectées`;
- un état vide `Aucune animation générée`;
- la liste des animations existantes avec nom, nombre de frames et atlas lié.

## Surfaces prêtes à peindre

Fichier créé :

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_paintable_surfaces_panel.dart`

Le panneau affiche :

- `Surfaces prêtes à peindre`;
- explication que ces surfaces seront disponibles dans l’éditeur de map;
- liste des surfaces peignables existantes;
- badge `Peignable`;
- CTA guide `Créer une surface`;
- CTA `Sauvegarder le catalogue` quand le callback existe.

Si `animations > 0` et `surfaces == 0`, l’état vide indique :

```text
Animations détectées, mais aucune surface peignable.
Créez une surface à partir des animations générées.
```

## États vides et messages utilisateur

Les nouveaux messages évitent les types internes et expliquent le flux :

- atlas = images source;
- animations = frames groupées;
- surfaces = éléments peignables en map.

Le mot `preset` reste dans les tests et API internes, mais la surface primaire parle de `surface peignable`.

## Implémentation

Changements principaux :

- `SurfaceStudioPanel` intègre le stepper et les nouveaux panneaux.
- `SurfaceStudioPanel.productDescriptionText` devient le texte no-code du header.
- le compteur header affiche `Surfaces` au lieu de `Presets`.
- `SurfaceStudioAtlasAuthoringPrep` renomme les zones principales.
- `SurfaceStudioVerticalAtlasPresetCreationSection` garde la logique de génération mais remplace les textes visibles par `surface à peindre / surface peignable`.
- les tests existants ont été ajustés lorsque les noms de surface apparaissent deux fois : dans le nouveau panneau peignable et dans le browser historique.

## Fichiers créés

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_workflow_stepper.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_creation_assistant.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_detected_animations_panel.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_paintable_surfaces_panel.dart`
- `reports/surface/surface_engine_lot_85_surface_studio_workflow_redesign.md`

## Fichiers modifiés

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_preset_creation_section.dart`
- `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart`

## Fichiers supprimés

Aucun.

## Tests lancés

Tests TDD / ciblés :

```bash
cd packages/map_editor && flutter test test/surface_studio/surface_studio_panel_test.dart
```

Premier passage attendu rouge :

```text
85.1 / 85.2 / 85.3 / 85.4 échouaient car le workflow guidé n’était pas encore implémenté.
```

Passage final :

```text
00:10 +80: All tests passed!
```

```bash
cd packages/map_editor && flutter test test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
```

Résultat final :

```text
00:06 +37: All tests passed!
```

```bash
cd packages/map_editor && flutter test test/surface_studio/surface_studio_workspace_entry_test.dart
```

Résultat final :

```text
00:09 +16: All tests passed!
```

Suite Surface Studio complète :

```bash
cd packages/map_editor && flutter test test/surface_studio
```

Résultat final :

```text
00:17 +391: All tests passed!
```

Non-régression Surface Painter :

```bash
cd packages/map_editor && flutter test test/surface_painter
```

Résultat final :

```text
00:04 +20: All tests passed!
```

Non-régression sélection :

```bash
cd packages/map_editor && flutter test test/map_selection_controller_test.dart
```

Résultat final :

```text
00:02 +5: All tests passed!
```

## Analyse lancée

Analyse ciblée :

```bash
cd packages/map_editor && flutter analyze \
  lib/src/features/surface_studio/surface_studio_panel.dart \
  lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart \
  lib/src/features/surface_studio/surface_studio_vertical_atlas_preset_creation_section.dart \
  lib/src/features/surface_studio/surface_studio_workflow_stepper.dart \
  lib/src/features/surface_studio/surface_studio_creation_assistant.dart \
  lib/src/features/surface_studio/surface_studio_detected_animations_panel.dart \
  lib/src/features/surface_studio/surface_studio_paintable_surfaces_panel.dart \
  test/surface_studio/surface_studio_panel_test.dart \
  test/surface_studio/surface_studio_atlas_authoring_prep_test.dart \
  test/surface_studio/surface_studio_workspace_entry_test.dart
```

Résultat :

```text
Analyzing 10 items...
No issues found! (ran in 3.2s)
```

Whitespace :

```bash
git diff --check
```

Résultat : aucune sortie, exit code 0.

## Résultats

- Surface Studio complet : vert.
- Surface Painter : vert.
- Sélection map : vert.
- Analyse ciblée : verte.
- Aucun changement hors `map_editor` et rapport.

## Evidence Pack

Fichiers audités :

- `packages/map_core/lib/src/operations/surface_studio_read_model.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_preset_creation_section.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_catalog_browser.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_selection_inspector.dart`
- `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart`

## Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_editor/lib/src/features/surface_painter/surface_palette_panel.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_preset_creation_section.dart
 M packages/map_editor/test/surface_painter/surface_palette_panel_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
?? packages/map_editor/lib/src/features/surface_painter/surface_catalog_availability.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_creation_assistant.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_detected_animations_panel.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_paintable_surfaces_panel.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_workflow_stepper.dart
?? packages/map_editor/test/surface_painter/surface_catalog_availability_test.dart
?? reports/surface/surface_engine_lot_84_ter_surface_painter_preset_availability_ux.md
?? reports/surface/surface_engine_lot_85_surface_studio_workflow_redesign.md
```

Diff stat final :

```text
 .../surface_painter/surface_palette_panel.dart     | 130 ++-
 .../surface_studio_atlas_authoring_prep.dart       | 903 +++++++++++----------
 .../surface_studio/surface_studio_panel.dart       |  87 +-
 ...dio_vertical_atlas_preset_creation_section.dart |  91 ++-
 .../surface_palette_panel_test.dart                | 199 ++++-
 .../surface_studio_atlas_authoring_prep_test.dart  |  51 +-
 .../surface_studio/surface_studio_panel_test.dart  | 206 +++--
 .../surface_studio_workspace_entry_test.dart       |  27 +-
 8 files changed, 1107 insertions(+), 587 deletions(-)
```

Le status final inclut :

- les changements préexistants Lot 84-ter;
- les changements Lot 85;
- le rapport Lot 85.

## Changements préexistants

Présents avant Lot 85 et non revert :

- `packages/map_editor/lib/src/features/surface_painter/surface_palette_panel.dart`
- `packages/map_editor/test/surface_painter/surface_palette_panel_test.dart`
- `packages/map_editor/lib/src/features/surface_painter/surface_catalog_availability.dart`
- `packages/map_editor/test/surface_painter/surface_catalog_availability_test.dart`
- `reports/surface/surface_engine_lot_84_ter_surface_painter_preset_availability_ux.md`

## Changements du Lot 85

Créés :

- `surface_studio_workflow_stepper.dart`
- `surface_studio_creation_assistant.dart`
- `surface_studio_detected_animations_panel.dart`
- `surface_studio_paintable_surfaces_panel.dart`
- ce rapport.

Modifiés :

- `surface_studio_panel.dart`
- `surface_studio_atlas_authoring_prep.dart`
- `surface_studio_vertical_atlas_preset_creation_section.dart`
- tests Surface Studio associés.

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
- `Runner.xcscheme` non modifié.

## Vérification fichiers temporaires

Commande :

```bash
find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
```

Sortie : aucune.

Commande :

```bash
git diff --check
```

Sortie : aucune, exit code 0.

## Vérification mojibake

Les textes ajoutés sont en français UTF-8 cohérent avec les fichiers existants. Aucun mojibake observé pendant les tests/analyse.

## Auto-review

- Est-ce que l’écran Surface Studio suit maintenant un workflow compréhensible ? Oui.
- Est-ce que les 4 étapes sont visibles ? Oui.
- Est-ce que l’utilisateur comprend la différence atlas / animation / surface peignable ? Oui, via l’assistant et la carte d’aide.
- Est-ce que les surfaces prêtes à peindre sont visibles dans un panneau dédié ? Oui.
- Est-ce que le cas animations présentes mais presets absents est clair ? Oui.
- Est-ce que l’UI évite les termes techniques internes ? Oui pour la surface principale; les zones historiques secondaires gardent certains termes établis comme `Presets Surface`.
- Est-ce que la preview atlas reste lisible ? Oui, le bloc d’authoring et sa preview restent en zone centrale.
- Est-ce que le flux création animations/preset est conservé ? Oui.
- Est-ce que le save flow catalogue est conservé ? Oui.
- Est-ce que Surface Painter n’est pas régressé ? Oui, `test/surface_painter` passe.
- Est-ce que map_core est modifié ? Non.
- Est-ce que map_runtime est modifié ? Non.
- Est-ce que les tests ciblés passent ? Oui.
- Est-ce que l’analyse ciblée passe ? Oui.
- Est-ce qu’un 85-bis est nécessaire ? Non. Les limites restantes sont la preview réelle et le resolver, explicitement hors scope.

## Critique du prompt

- Le prompt demande un redesign UX important mais interdit de toucher à la logique métier : la meilleure stratégie était donc un shell de guidage autour des blocs existants, pas une réécriture visuelle complète.
- Le terme `preset` reste présent dans quelques panneaux historiques secondaires; le supprimer partout aurait dépassé le périmètre et cassé des tests de caractérisation du catalogue.
- Le CTA `Créer une surface` du panneau droit est volontairement guidant et désactivé : l’action réelle reste dans le bloc central existant pour éviter de dupliquer la logique.
- Les tests widget vérifient la hiérarchie et les messages, pas le pixel-perfect de l’image de référence.
