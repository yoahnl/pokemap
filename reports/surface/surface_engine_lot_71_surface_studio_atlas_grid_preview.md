# Lot 71 — Surface Studio Atlas Grid Preview V0

## Résumé exécutif

Le lot ajoute une section **Aperçu de la grille atlas** dans `Préparation atlas` (après `Grille de l’image`, avant `Options avancées`).  
La preview est **symbolique** (V0) et affiche : source, tile, grille, total, disposition, ainsi qu’un rendu de cellules borné à **12 colonnes × 8 lignes** avec mention **Aperçu réduit** pour les grilles plus grandes.  
Les états vides/invalides sont gérés avec messages pédagogiques, sans toucher au runtime, au save flow ni à `map_core`.

## Périmètre

- **Modifiés**
  - `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart`
  - `packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart`
- **Créés**
  - `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_grid_preview.dart`
  - `packages/map_editor/test/surface_studio/surface_studio_atlas_grid_preview_test.dart`
  - `reports/surface/surface_engine_lot_71_surface_studio_atlas_grid_preview.md`

## Gate 0 — Status initial avant modification

Commandes exécutées avant modification :

```text
$ pwd
/Users/karim/Project/pokemonProject

$ git branch --show-current
codex/psdk-fight-next-move-wave

$ git status --short --untracked-files=all
(aucune sortie)

$ git diff --stat
(aucune sortie)

$ git log --oneline -n 10
1c763366 fix(map_editor): thème Material local pour Préparation atlas Surface Studio
0a802c72 feat(map_editor): Surface Studio Lot 70 — sélecteur source image atlas (no-code)
495004bb feat(map_editor): Surface Studio édition et suppression d'atlas (lots 67-69)
9ae28e89 chore(ios): ajuster LaunchAction Runner (launcher éphemère)
e9f46ce1 feat(map_editor): Lot 66 Surface Studio UX layout, rapports 65-bis et 66
5695bd87 feat(map_editor): Surface Studio sauvegarde projet via FileProjectRepository (Lot 65)
7d9d5347 docs(surface): rapport Lot 64-bis preuve d'analyze couvrant surface_studio, canvas, notifier
ec35c497 feat(map_editor): Surface Studio manifest save wiring in memory (Lot 64)
69faacc4 update tests
7ad7e847 feat(map_editor): Surface Studio save flow prep (Lot 63) + rapport 63-bis
```

## Audit initial

- `SurfaceStudioAtlasAuthoringPrep` possède déjà tous les champs nécessaires au calcul (`tileWidth`, `tileHeight`, `columns`, `rows`, `layout`, source via `_tilesetId`).
- Le lot 70 expose déjà la source via picker/fallback ; Lot 71 doit seulement rendre cette info visuelle.
- Le code existant n’a pas besoin d’une nouvelle couche de données : un widget UI local suffit.
- Contrainte de stabilité: ne pas toucher les flux create/edit/save/delete.

## Décision preview réelle vs preview symbolique

- **La vraie image est affichée ?** Non.
- **Pourquoi ?** Le lot 71 interdit explicitement de résoudre la chaîne asset complète (chargement image disque, dimensions PNG, découpage réel).
- **Choix retenu** : preview **symbolique** bornée (`Wrap` de cellules), calculée à partir des champs déjà saisis.
- **Valeur utilisateur apportée** :
  - compréhension immédiate de la grille,
  - feedback direct en création et édition,
  - états clairs si source absente ou dimensions invalides.
- **Reste à faire pour une vraie preview image** (hors lot) :
  - accès propre au pipeline asset,
  - récupération dimensions image,
  - mapping tuiles réelles dans la grille.

## Implémentation

- `surface_studio_atlas_grid_preview.dart`
  - widget `SurfaceStudioAtlasGridPreview`
  - affiche labels : Source, Tile, Grille, Total, Disposition
  - gère états :
    - source absente -> `Choisissez une image source...`
    - dimensions invalides -> `Corrigez les dimensions...`
  - rendu symbolique borné à `12×8`
  - indicateur `Aperçu réduit` si dépassement.
- `surface_studio_atlas_authoring_prep.dart`
  - import du widget preview
  - calcul `int.tryParse` des champs de grille
  - insertion de la section preview après `Grille de l’image`.
- `surface_studio_atlas_authoring_prep_test.dart`
  - nouveaux tests Lot 71 : visibilité, états vide/invalide, mise à jour en édition.
- `surface_studio_atlas_grid_preview_test.dart`
  - tests unitaires widget preview (métriques, bornage, jargon interdit).

## Fichiers créés

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_grid_preview.dart`
- `packages/map_editor/test/surface_studio/surface_studio_atlas_grid_preview_test.dart`
- `reports/surface/surface_engine_lot_71_surface_studio_atlas_grid_preview.md`

## Fichiers modifiés

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart`
- `packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart`

## Fichiers supprimés

- Aucun.

## Tests lancés

```text
cd packages/map_editor && flutter test test/surface_studio/surface_studio_atlas_grid_preview_test.dart
cd packages/map_editor && flutter test test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
cd packages/map_editor && flutter test test/surface_studio/surface_studio_atlas_source_picker_test.dart
cd packages/map_editor && flutter test test/surface_studio/surface_studio_panel_test.dart
cd packages/map_editor && flutter test test/surface_studio
cd packages/map_core && dart test test/surface_studio_read_model_test.dart
```

## Analyse lancée

```text
cd packages/map_editor && flutter analyze lib/src/features/surface_studio test/surface_studio
```

## Résultats

- `surface_studio_atlas_grid_preview_test.dart` : **All tests passed!**
- `surface_studio_atlas_authoring_prep_test.dart` : **All tests passed!**
- `surface_studio_atlas_source_picker_test.dart` : **All tests passed!**
- `surface_studio_panel_test.dart` : **All tests passed!**
- `flutter test test/surface_studio` : **All tests passed!**  
  Ligne finale exacte: `00:11 +295: All tests passed!`
- `dart test test/surface_studio_read_model_test.dart` : **All tests passed!** (30 tests)
- `flutter analyze lib/src/features/surface_studio test/surface_studio` :  
  `Analyzing 2 items...` puis `No issues found! (ran in 2.9s)`

## Evidence Pack

### Status final complet

```text
$ git status --short --untracked-files=all
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart
 M packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_grid_preview.dart
?? packages/map_editor/test/surface_studio/surface_studio_atlas_grid_preview_test.dart
?? reports/surface/surface_engine_lot_71_surface_studio_atlas_grid_preview.md
```

### Diff stat final

```text
$ git diff --stat
 .../surface_studio_atlas_authoring_prep.dart       | 15 ++++
 .../surface_studio_atlas_authoring_prep_test.dart  | 93 ++++++++++++++++++++++
 2 files changed, 108 insertions(+)
```

### Fichiers temporaires

```text
$ find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
(aucune sortie)
```

### Sorties exactes ciblées (extraits)

- `surface_studio_atlas_grid_preview_test.dart` : `00:02 +5: All tests passed!`
- `surface_studio_atlas_authoring_prep_test.dart` : `00:04 +28: All tests passed!`
- `surface_studio_atlas_source_picker_test.dart` : `00:01 +3: All tests passed!`
- `surface_studio_panel_test.dart` : `00:09 +76: All tests passed!`
- `flutter test test/surface_studio` : `00:11 +295: All tests passed!`

## Git status final

Voir `Evidence Pack`.

## Changements préexistants

Aucun changement préexistant local au moment du Gate 0 (repo propre).

## Changements du Lot 71

- Ajout d’une preview de grille symbolique V0, pédagogique et bornée.
- Intégration non intrusive dans le formulaire existant.
- Renforcement des tests authoring avec scénarios Lot 71.

## Périmètre explicitement non touché

- map_core non modifié
- ProjectManifest non modifié
- generated files non modifiés
- build_runner non lancé
- aucun provider Surface créé
- aucun repository/service Surface créé
- aucune logique de sauvegarde modifiée
- aucune écriture project.json modifiée
- aucune création métier nouvelle
- aucune édition atlas existant modifiée fonctionnellement
- aucune suppression atlas modifiée fonctionnellement
- aucune animation créée/modifiée
- aucun preset créé/modifié
- aucun runtime/gameplay/battle modifié
- aucun painter map
- aucun SurfaceLayer
- aucun import atlas vertical
- Runner.xcscheme non modifié par ce lot

## Vérification fichiers temporaires

Aucun fichier `_gen_*.py`, `build_*.py`, `*.tmp` détecté.

## Vérification mojibake

Aucun artefact mojibake observé dans les textes ajoutés (accents et multiplication `×` rendus correctement dans tests).

## Auto-review

- Est-ce que la vraie image est affichée ? **Non**, preview symbolique volontaire.
- Est-ce qu’une preview symbolique existe ? **Oui**.
- Est-ce que la preview affiche source, tile, grille, total, disposition ? **Oui**.
- Est-ce que la preview gère les dimensions invalides ? **Oui**.
- Est-ce que la preview fonctionne en création ? **Oui**.
- Est-ce que la preview fonctionne en édition ? **Oui**.
- Est-ce que create atlas fonctionne toujours ? **Oui**.
- Est-ce que edit atlas fonctionne toujours ? **Oui**.
- Est-ce que delete guard fonctionne toujours ? **Oui**.
- Est-ce que save flow fonctionne toujours ? **Oui**.
- Est-ce que map_core est modifié ? **Non**.
- Est-ce que les tests ciblés passent ? **Oui**.
- Est-ce que la suite Surface Studio passe ? **Oui**.
- Est-ce que flutter analyze passe ? **Oui**.
- Est-ce qu’un fichier présent au status initial a disparu du status final ? **Non**.
- Est-ce qu’un fichier hors périmètre a été modifié ? **Non**.
- Est-ce qu’un 71-bis est nécessaire ? **Non** pour l’objectif V0 ; **Oui** seulement si on veut une vraie preview image (pipeline asset).

## Critique du prompt

Le prompt est cohérent et borné. Les contraintes “preview V0 symbolique” + “pas de map_core / pas de save flow” sont alignées avec un lot UX incrémental, ce qui réduit le risque de régression et évite une implémentation disproportionnée.
