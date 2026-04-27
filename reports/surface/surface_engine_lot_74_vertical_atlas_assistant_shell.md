# Lot 74 — Vertical Atlas Assistant Shell + Usable Atlas Preview V0

## Résumé exécutif

Ajout d’un bloc **Assistant atlas vertical** (convention colonnes / lignes, détection V0, métriques) et d’une **aperçu grand format** pour l’image source : hauteur de zone portée à **360–560 px** (ou **480 px** si contrainte de hauteur non bornée), **trois modes d’ajustement** (largeur, 100 % pixels, hauteur), **défilement** horizontal et vertical, grille overlay Lot 73 conservée. Réorganisation de la **Préparation atlas** : source image → assistant → grand format → champs grille → aperçu grille symbolique → nom / id → options avancées. **SingleChildScrollView** autour du contenu de la préparation pour éviter les débordements verticaux. Aucun changement `map_core`, pas de provider / repository Surface, pas de `build_runner`.

## Périmètre

- **Inclus** : `map_editor` — `surface_studio` (assistant, image preview, authoring prep, tests, rapport).
- **Exclus** : génération d’animations, presets, import atlas vertical réel, runtime, `map_core`.

## Gate 0 — Status initial avant modification

Exécuté avant modifications :

```text
/Users/karim/Project/pokemonProject
codex/psdk-fight-next-move-wave
(working tree vide — aucune ligne git status)
13569f30 feat(map_editor): Surface Studio Lot 73 — grille sur aperçu image source
24467c67 feat(map_editor): Surface Studio Lot 72 — aperçu image source (résolution disque)
…
```

## Audit initial

- Lot 73 : overlay grille sur image mais **hauteur max 160 px** → grille illisible sur atlas type 736×1024.
- Préparation atlas : `Column` sans scroll interne → risque d’overflow avec contenu plus haut.

## Décision UX preview grand format

| Point | Décision |
|-------|-----------|
| Pourquoi la preview était trop petite | `\_maxImageHeight = 160` dans `SurfaceStudioAtlasImagePreview` forçait une mise à l’échelle minuscule pour les grandes textures. |
| Taille / contrainte maintenant | `largeFormat: true` : hauteur de la zone d’image `viewH = maxHeight.clamp(360, 560)` si le parent borne la hauteur ; sinon **480 px** ; image dimensionnée selon le mode. |
| Overlay lisible | Même `CustomPainter` ; traits sur la **taille affichée** agrandie ; modes **Ajuster à la largeur / hauteur** augmentent la surface utile ; **100 %** montre les pixels 1:1 avec scroll. |
| Zoom « libre » type loupe | **Non** (hors périmètre V0) ; remplacé par **3 modes** + **scroll** à double axe. |

## Implémentation

- `surface_studio_vertical_atlas_assistant.dart` : section dédiée, clé `SurfaceStudioVerticalAtlasAssistant.sectionKey`, textes « Colonnes = variantes visuelles », « Lignes = frames d’animation », messages V0 (`rows > columns`, `columns > rows`, `1×1`), métriques si brouillon valide ; libellé **« Taille de tuile : … »** dans l’assistant pour éviter le doublon exact avec l’aperçu grille symbolique (« Tile : … »).
- `surface_studio_atlas_image_preview.dart` : paramètre optionnel `largeFormat` (défaut `false`), titre **« Aperçu grand format de l’image source »** si activé, enum `SurfaceStudioAtlasImagePreviewFitMode`, fonction `_surfaceStudioAtlasImageFitDisplaySize`, rangée de boutons clé `surface_studio_atlas_image_fit_controls`, `Scrollbar` + double `SingleChildScrollView`.
- `surface_studio_atlas_authoring_prep.dart` : ordre des sections ; `SurfaceStudioAtlasImagePreview(..., largeFormat: true)` ; `SingleChildScrollView` enveloppant la `Column` de contenu.

## Fichiers créés

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_assistant.dart`
- `packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_assistant_test.dart`
- `reports/surface/surface_engine_lot_74_vertical_atlas_assistant_shell.md`

## Fichiers modifiés

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_image_preview.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart`
- `packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`

## Fichiers supprimés

- Aucun.

## Signature publique modifiée

- `SurfaceStudioAtlasImagePreview` : ajout du paramètre nommé optionnel **`largeFormat`** (`bool`, défaut `false`). Ajout de l’enum **`SurfaceStudioAtlasImagePreviewFitMode`** dans le même fichier (utilisé par l’état interne du preview grand format).

## Tests lancés

```bash
cd packages/map_editor && flutter test test/surface_studio/surface_studio_vertical_atlas_assistant_test.dart test/surface_studio/surface_studio_atlas_image_preview_test.dart test/surface_studio/surface_studio_atlas_grid_overlay_test.dart test/surface_studio/surface_studio_atlas_authoring_prep_test.dart test/surface_studio/surface_studio_panel_test.dart
```

Résultat : **`00:10 +126: All tests passed!`**

```bash
cd packages/map_editor && flutter test test/surface_studio
```

Résultat : **`00:12 +317: All tests passed!`**

```bash
cd packages/map_core && dart test test/surface_studio_read_model_test.dart
```

Résultat : **`+30: All tests passed!`**

## Analyse lancée

```bash
cd packages/map_editor && flutter analyze lib/src/features/surface_studio test/surface_studio
```

Résultat : **`No issues found!`**

## Résultats

- Preview utilisable : **oui** (zone 360–560 px, modes + scroll).
- Assistant vertical : **oui**, avec textes et détection V0 demandés.
- Non-régression Surface Studio : **oui** (+317 tests).

## Evidence Pack

- Gate 0 : section dédiée ci-dessus.
- Gate final : voir section **Git status final**.
- Tests ciblés : ligne finale **`All tests passed!`** avec **`+126`** pour le regroupement des cinq fichiers de test listés.
- Suite `test/surface_studio` : **`00:12 +317: All tests passed!`**
- `flutter analyze` : **`No issues found!`**

## Git status final

```bash
git status --short --untracked-files=all
git diff --stat
find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
```

`git status --short --untracked-files=all` :

```text
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_image_preview.dart
 M packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_assistant.dart
?? packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_assistant_test.dart
?? reports/surface/surface_engine_lot_74_vertical_atlas_assistant_shell.md
```

`git diff --stat` (fichiers suivis) :

```text
 .../surface_studio_atlas_authoring_prep.dart       | 103 ++++----
 .../surface_studio_atlas_image_preview.dart        | 293 +++++++++++++++++----
 .../surface_studio_atlas_authoring_prep_test.dart  |  25 +-
 .../surface_studio/surface_studio_panel_test.dart  |   2 +-
 4 files changed, 315 insertions(+), 108 deletions(-)
```

`find` : **aucune** correspondance.

## Changements préexistants

- Aucun autre chantier en cours sur les chemins modifiés.

## Changements du Lot 74

- Assistant + grand format + scroll préparation + ajustements de tests (scroll multiple, `ensureVisible` sur « Appliquer »).

## Périmètre explicitement non touché

- `map_core` non modifié ; `ProjectManifest` / générés non modifiés ; `build_runner` non lancé ; aucun provider / repository / service Surface ; pas de modification du flux de sauvegarde ; pas d’animation ni preset ; pas de `SurfaceLayer` / painter carte / runtime ; `Runner.xcscheme` non modifié ; **`surface_studio_panel.dart`** non modifié (seul le test panel 16 a été ajusté).

## Vérification fichiers temporaires

- `find` : vide.

## Vérification mojibake

- Chaînes françaises vérifiées à la relecture (apostrophes typographiques).

## Auto-review

| Question | Réponse |
|----------|---------|
| Preview image utilisable ? | **Oui** — zone jusqu’à ~560 px de haut, modes largeur / 100 % / hauteur, scroll. |
| Zone grand format ? | **Oui** — `largeFormat: true` dans la préparation. |
| Grille overlay visible ? | **Oui** — inchangée quand dimensions natives + brouillon valides. |
| Colonnes = variantes expliqué ? | **Oui** |
| Lignes = frames expliqué ? | **Oui** |
| 23×32 → 23 / 32 / total ? | **Oui** (tests assistant). |
| 1×1 géré ? | **Oui** |
| create / edit / delete guard / save | **Oui** (suite + tests ciblés). |
| `map_core` modifié ? | **Non** |
| Repository / service / provider ? | **Non** |
| Tests ciblés / suite / analyze | **Oui** |
| Fichier initial disparu ? | **Non** |
| Fichier hors périmètre modifié ? | **Non** (hors rapport) |
| 74-bis nécessaire ? | **Non** — zoom libre ou rôles de colonnes pourront être un lot ultérieur. |

## Critique du prompt

- Exigeant sur l’**utilisabilité** : la contrainte 360–560 px est respectée via `clamp` sur la hauteur disponible.
- L’ordre exact « Nom après grille » a été appliqué pour remonter la preview ; les tests qui tapent des boutons en bas de carte utilisent désormais **`ensureVisible`** là où nécessaire.
