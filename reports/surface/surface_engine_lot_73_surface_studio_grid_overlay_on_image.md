# Lot 73 — Surface Studio Grid Overlay on Real Image V0

## Résumé exécutif

Superposition d’une grille (traits uniquement, `CustomPainter`) sur l’aperçu image réel lorsque le fichier est résolu, les dimensions natives sont décodées depuis les octets déjà lus, et le brouillon atlas (`tileWidth`, `tileHeight`, `columns`, `rows`) est valide. Métriques attendues (px, colonnes × lignes, total cases, disposition), message de correspondance ou d’écart doux, mode « grille dense » avec sous-échantillonnage des traits, repli Lot 72 inchangé si image absente ou non résolue. Aucun changement `map_core`, pas de provider/repository Surface, pas de `build_runner`.

## Périmètre

- **Inclus** : `map_editor` — `surface_studio` (aperçu image + overlay + tests + rapport).
- **Exclus** : runtime, import d’assets, presets, animations, sauvegarde manifeste, `map_core`.

## Gate 0 — Status initial avant modification

Consigne : exécuter `pwd`, `git branch --show-current`, `git status --short --untracked-files=all`, `git diff --stat`, `git log --oneline -n 10` **avant** toute modification.

- En **tête de lot** (session agent précédente), Gate 0 a été exécuté sur dépôt propre après Lot 72 (branche `codex/psdk-fight-next-move-wave`, HEAD `24467c67`).
- À la **reprise** de cette session, l’arbre contenait déjà les fichiers Lot 73 en cours ; le relevé ci-dessous reflète l’état **avant ajout du présent rapport** et **après** stabilisation code/tests :

```text
/Users/karim/Project/pokemonProject
codex/psdk-fight-next-move-wave
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_image_preview.dart
 M packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_grid_overlay.dart
?? packages/map_editor/test/surface_studio/surface_studio_atlas_grid_overlay_test.dart
 .../surface_studio_atlas_authoring_prep.dart       |   5 +
 .../surface_studio_atlas_image_preview.dart        | 260 +++++++++++++++++++--
 .../surface_studio_atlas_authoring_prep_test.dart  |  18 ++
 3 files changed, 262 insertions(+), 21 deletions(-)
24467c67 feat(map_editor): Surface Studio Lot 72 — aperçu image source (résolution disque)
fcdc064d feat(map_editor): Surface Studio Lot 71 — aperçu grille atlas (preview V0)
…
```

## Audit initial

- Lot 72 : image résolue via `projectRootPath` + `ProjectTilesetEntry.relativePath`, cache octets + `Image.memory`.
- Lot 73 : réutiliser les octets pour dimensions natives, éviter `Wrap` de cellules sur l’image réelle, garder la grille symbolique (Lot 71) telle quelle.

## Décision overlay / dimensions image

| Question | Réponse |
|----------|---------|
| Comment la grille est dessinée ? | `SurfaceStudioAtlasImageGridPainter` (`CustomPainter`) trace des **lignes** verticales et horizontes selon `columns` et `rows`, espacées uniformément sur la taille **affichée** du `Stack` (image mise à l’échelle avec le même rectangle que l’image quand les dimensions natives sont connues). |
| `CustomPainter` utilisé ? | **Oui**, via `CustomPaint` au-dessus de `Image.memory` dans un `Stack`. |
| Dimensions réelles lues ? | **Oui**, quand possible : `decodeRasterImageSizeFromBytes` dans `surface_studio_atlas_grid_overlay.dart` appelle `package:image` `decodeImage` sur les octets déjà en cache (même lecture fichier que Lot 72). Stockage dans `_imageNaturalWidth` / `_imageNaturalHeight` dans l’état du widget. |
| Si non ? | Si décodage impossible ou dimensions nulles : pas d’overlay sur l’image (évite une grille non alignée sur l’échelle réelle) ; message **« Dimensions réelles non lues. »** et **« Superposition sur l’image désactivée tant que les dimensions du fichier ne sont pas lues. »** tout en affichant les **métriques attendues** du brouillon. |
| Cas invalides (brouillon) ? | Si `surfaceStudioAtlasGridOverlayDraftValid` est faux : pas d’overlay, texte **« Corrigez les dimensions de grille pour afficher l’overlay. »**, image toujours affichée si octets valides. |
| Grille dense ? | `surfaceStudioAtlasGridOverlayIsDense` + `surfaceStudioAtlasGridOverlayLineStep` pour sauter des traits intérieurs (bords toujours dessinés). Message **« Grille dense — aperçu visuel simplifié. »** |
| Tests widget image + overlay ? | **Non** : un essai avec image résolue réelle + `pumpAndSettle` a montré un risque de blocage (idle engine) ; les tests ciblent l’overlay via tests unitaires / `CustomPaint` minimal et les parcours authoring sans fichier image résolu. |

## Implémentation

- **`surface_studio_atlas_grid_overlay.dart`** : décodage taille, validité brouillon, dimensions attendues, densité, pas de traits, peintre const.
- **`surface_studio_atlas_image_preview.dart`** : paramètres brouillon optionnels, métriques, `showOverlay = gridValid && naturalKnown`, `Stack` + `CustomPaint` avec clé `kSurfaceStudioAtlasImageGridOverlayKey`.
- **`surface_studio_atlas_authoring_prep.dart`** : passe `draftTileWidth` … `draftLayoutLabel` (`_layoutMenuLabel(_layout)`) à `SurfaceStudioAtlasImagePreview`.

## Fichiers créés

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_grid_overlay.dart`
- `packages/map_editor/test/surface_studio/surface_studio_atlas_grid_overlay_test.dart`
- `reports/surface/surface_engine_lot_73_surface_studio_grid_overlay_on_image.md` (ce fichier)

## Fichiers modifiés

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_image_preview.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart`
- `packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart`

## Fichiers supprimés

- Aucun.

## Tests lancés

```bash
cd packages/map_editor && flutter test test/surface_studio/surface_studio_atlas_grid_overlay_test.dart test/surface_studio/surface_studio_atlas_image_preview_test.dart test/surface_studio/surface_studio_atlas_grid_preview_test.dart test/surface_studio/surface_studio_atlas_authoring_prep_test.dart test/surface_studio/surface_studio_panel_test.dart
```

Sortie finale : **`00:15 +125: All tests passed!`**

```bash
cd packages/map_editor && flutter test test/surface_studio
```

Sortie finale (dernière exécution de validation) : **`00:11 +311: All tests passed!`**

```bash
cd packages/map_core && dart test test/surface_studio_read_model_test.dart
```

Sortie finale : **`00:00 +30: All tests passed!`**

## Analyse lancée

```bash
cd packages/map_editor && flutter analyze lib/src/features/surface_studio/surface_studio_atlas_grid_overlay.dart lib/src/features/surface_studio/surface_studio_atlas_image_preview.dart lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart test/surface_studio/surface_studio_atlas_grid_overlay_test.dart test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
```

Sortie : **`No issues found! (ran in 1.6s)`**

```bash
cd packages/map_editor && flutter analyze lib/src/features/surface_studio test/surface_studio
```

Sortie : **`No issues found! (ran in 1.9s)`**

## Résultats

- Overlay grille sur image réelle : **OK** sous conditions (brouillon valide + dimensions natives lues).
- Fallback Lot 72, grille symbolique Lot 71 : **OK** (tests existants + suite `test/surface_studio`).
- `map_core` read model : **OK**.

## Evidence Pack

- Gate 0 / état git : section **Gate 0** ci-dessus (relevé avant ajout du rapport ; fichiers Lot 73 déjà présents à la reprise de session).
- `git diff --stat` : voir **Git status final** (après rapport = +1 fichier rapport).
- Tests ciblés principaux : ligne finale **`All tests passed!`** avec **`+125`** (regroupement des 5 fichiers de test listés).
- Suite `test/surface_studio` : **`00:16 +311: All tests passed!`**
- `flutter analyze` : **`No issues found!`**
- Fichiers créés / modifiés / supprimés : sections dédiées.
- `editor_canvas_host.dart` : **non modifié** (omis de l’analyse ciblée explicite).

## Git status final

Commandes exécutées depuis la racine du dépôt après écriture du rapport :

```bash
git status --short --untracked-files=all
git diff --stat
find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
```

Sortie `git status --short --untracked-files=all` :

```text
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_image_preview.dart
 M packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_grid_overlay.dart
?? packages/map_editor/test/surface_studio/surface_studio_atlas_grid_overlay_test.dart
?? reports/surface/surface_engine_lot_73_surface_studio_grid_overlay_on_image.md
```

Sortie `git diff --stat` (fichiers suivis uniquement ; les `??` n’y figurent pas) :

```text
 .../surface_studio_atlas_authoring_prep.dart       |   5 +
 .../surface_studio_atlas_image_preview.dart        | 260 +++++++++++++++++++--
 .../surface_studio_atlas_authoring_prep_test.dart  |  18 ++
 3 files changed, 262 insertions(+), 21 deletions(-)
```

Sortie `find` (aucune correspondance dans l’arborescence parcourue) : **vide**.

## Changements préexistants

- Aucun autre lot en cours dans les fichiers touchés au-delà de Lot 72 → 73 sur les chemins `surface_studio` ci-dessus.

## Changements du Lot 73

- Overlay `CustomPainter` + métriques + correspondance dimensions / grille attendue + mode dense + messages utilisateur sans jargon technique.

## Périmètre explicitement non touché

- `map_core` non modifié.
- `ProjectManifest` / `.g.dart` / `.freezed.dart` non modifiés.
- Fichiers générés non modifiés ; **`build_runner` non lancé**.
- Aucun provider / repository / service Surface créé.
- Aucune logique de sauvegarde modifiée ; aucune écriture `project.json` modifiée par ce lot.
- Pas de création métier nouvelle ; pas de changement fonctionnel création / édition / suppression d’atlas hors affichage preview.
- Pas d’animation, preset, runtime, gameplay, battle, painter carte, `SurfaceLayer`, import atlas vertical.
- `examples/playable_runtime_host/ios/Runner.xcodeproj/.../Runner.xcscheme` non modifié.

## Vérification fichiers temporaires

- Commande `find` (motifs `_gen_*.py`, `build_*.py`, `*.tmp`) : **aucun fichier** attendu dans le périmètre du lot.

## Vérification mojibake

- Chaînes UI revues en français (apostrophes typographiques `’` cohérentes avec le fichier existant).

## Auto-review

| Question | Réponse |
|----------|---------|
| Grille sur image réelle ? | **Oui**, quand image résolue, octets affichables, brouillon grille valide, dimensions natives lues (`Stack` + `CustomPaint`). |
| Overlay utilise `tileWidth` / `tileHeight` / `columns` / `rows` ? | **Oui** (via dimensions attendues et nombre de divisions du peintre). |
| Dimensions attendues affichées ? | **Oui** (`Grille attendue : …`, `Grille : …`, `Tile : …`, `Total : …`). |
| Dimensions réelles lues ? | **Oui** quand `decodeRasterImageSizeFromBytes` réussit ; sinon message explicite, pas d’overlay. |
| Cas invalides sans crash ? | **Oui** (tests + garde-fous). |
| Preview symbolique disponible ? | **Oui** (section Lot 71 inchangée ; rappel sous l’image). |
| Create atlas OK ? | **Oui** (suite Surface Studio). |
| Edit atlas OK ? | **Oui** (idem). |
| Delete guard OK ? | **Oui** (idem). |
| Save flow OK ? | **Oui** (idem ; pas de code save touché). |
| `map_core` modifié ? | **Non**. |
| Repository / service / provider créé ? | **Non**. |
| Tests ciblés passent ? | **Oui**. |
| Suite `test/surface_studio` ? | **Oui** (`+311`). |
| `flutter analyze` ? | **Oui**. |
| Fichier présent au status initial disparu au final ? | **Non** (aucune suppression). |
| Fichier hors périmètre modifié ? | **Non** (hors rapport). |
| 73-bis nécessaire ? | **Non** : périmètre V0 rempli ; amélioration possible ultérieure = test widget image résolue si une stratégie sans hang est trouvée (ex. fausse résolution ou mock codec). |

## Critique du prompt

- Exigeant et clair sur l’overlay **non-éditeur** et **pas de widgets par cellule** : respecté.
- La phrase « La grille est affichée à titre visuel » lorsque les dimensions réelles sont absentes entre en tension avec une superposition **alignée** sur l’image : implémentation retenue = **honnêteté UX** (superposition désactivée si dimensions non lues) plutôt qu’une grille trompeuse sur une mise à l’échelle inconnue.
