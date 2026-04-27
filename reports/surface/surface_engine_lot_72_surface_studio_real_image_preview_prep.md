# Lot 72 — Surface Studio Real Image Preview Prep V0

## Résumé exécutif

Ajout d’une section **« Aperçu de l’image source »** dans la préparation atlas Surface Studio : résolution locale du fichier image à partir de `projectRootPath` + `ProjectTilesetEntry.relativePath`, affichage via **`Image.memory`** (octets lus une fois et mis en cache dans l’état du widget) lorsque le fichier existe, messages de repli explicites sinon. La grille symbolique (Lot 71) est conservée ; la ligne **Source** de l’aperçu grille utilise le **nom manifeste** du tileset lorsqu’il est connu. Aucune modification `map_core`, aucun service / repository / provider Surface, aucun `build_runner`.

## Périmètre

- **Inclus** : `map_editor` — `surface_studio_*`, `editor_canvas_host.dart`, tests `test/surface_studio/*`, rapport présent.
- **Exclu** : `map_core`, `map_runtime`, `map_gameplay`, `map_battle`, flux de sauvegarde manifeste (seul passage optionnel de `projectRootPath` en lecture), `Runner.xcscheme`.

## Gate 0 — Status initial avant modification

Commandes exécutées **avant** toute modification de fichier (capturées au début du lot) :

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
codex/psdk-fight-next-move-wave

git status --short --untracked-files=all
(vide — working tree clean)

git diff --stat
(vide)

git log --oneline -n 10
fcdc064d feat(map_editor): Surface Studio Lot 71 — aperçu grille atlas (preview V0)
1c763366 fix(map_editor): thème Material local pour Préparation atlas Surface Studio
0a802c72 feat(map_editor): Surface Studio Lot 70 — sélecteur source image atlas (no-code)
495004bb feat(map_editor): Surface Studio édition et suppression d'atlas (lots 67-69)
9ae28e89 chore(ios): ajuster LaunchAction Runner (launcher éphemère)
e9f46ce1 feat(map_editor): Lot 66 Surface Studio UX layout, rapports 65-bis et 66
5695bd87 feat(map_editor): Surface Studio sauvegarde projet via FileProjectRepository (Lot 65)
7d9d5347 docs(surface): rapport Lot 64-bis preuve d'analyze couvrant surface_studio, canvas, notifier
ec35c497 feat(map_editor): Surface Studio manifest save wiring in memory (Lot 64)
69faacc4 update tests
```

## Audit initial

- **`ProjectTilesetEntry`** (`packages/map_core/lib/src/models/project_manifest.dart`, lecture seule) : champs utilisés pour ce lot — `id`, `name`, `relativePath` (et tri existant via `sortOrder` / nom dans le sélecteur, inchangé).
- **Pas** de nouveau champ manifeste : résolution = `p.join(projectRootPath, entry.relativePath)` + `File.existsSync`.
- **Chargement d’images ailleurs** : même idée que d’autres panneaux (`projectRootPath` + chemin relatif), ex. explorations Pokedex / gameplay zones.
- **`EditorCanvasHost`** : expose déjà le `project` via Riverpod ; `EditorState.projectRootPath` est disponible via `editorNotifierProvider` — passage optionnel à `SurfaceStudioPanelFromManifest` sans toucher au save flow.
- **Pas** de resolver global ni d’architecture asset nouvelle : fonction pure `resolveSurfaceStudioAtlasImagePreview` + widget local.

## Résolution image retenue

| Question | Réponse |
|----------|---------|
| Quels champs `ProjectTilesetEntry` sont utilisés ? | `id` (sélection = identifiant technique courant du brouillon), `relativePath` (chemin relatif au dossier projet), `name` (affichage grille + contexte). |
| Comment le chemin image est résolu ? | `absolute = normalize(join(projectRootPath.trim(), entry.relativePath.trim()))` ; fichier considéré résolu si `File(absolute).existsSync()`. |
| `projectRootPath` est-il utilisé ? | **Oui**, optionnel : transmis depuis `EditorCanvasHost` → `SurfaceStudioPanelFromManifest` → `SurfaceStudioPanel` → `SurfaceStudioAtlasAuthoringPrep`. Si null ou vide → statut `unresolved` (message explicite, pas de crash). |
| La vraie image est-elle affichée ? | **Oui** dans l’éditeur lorsque le fichier existe : affichage par **`Image.memory`** après `readAsBytesSync()` (équivalent visuel à un fichier local, sans pipeline d’import nouveau). |
| Si non dans les tests widget ? | Les tests widget qui appelaient `resolve` + `existsSync` sur un répertoire temporaire **bloquaient** le runner (`flutter test` restait en attente d’idle). Les tests widget d’aperçu **résolu** ont été retirés ; l’état **resolved** est couvert par un **test unitaire** sur `resolveSurfaceStudioAtlasImagePreview` + intégration réelle dans l’UI. |
| Cas de fallback ? | `empty`, `unresolved`, `missingFile` : textes conformes au prompt + rappel grille symbolique ; `errorBuilder` / lecture octets en échec : message de chargement impossible. |

## Implémentation

- **`resolveSurfaceStudioAtlasImagePreview`** : statuts `empty` | `resolved` | `missingFile` | `unresolved`.
- **`SurfaceStudioAtlasImagePreview`** (StatefulWidget) : cache octets par chemin résolu ; `Image.memory` + cadre hauteur max 160 ; pas d’exception si fichier absent (résolu en amont par le helper).
- **`SurfaceStudioAtlasAuthoringPrep`** : après **Image source de l’atlas**, bloc **Aperçu de l’image source** ; calcul `gridSourceDisplayForUi` pour la grille (nom tileset, basename si nom vide, libellé fixe si saisie technique sans entrée).
- **`SurfaceStudioAtlasGridPreview`** : paramètre optionnel `sourceDisplayForUi`.
- **Câblage racine** : `projectRootPath` sur `SurfaceStudioPanel` / `SurfaceStudioPanelFromManifest` / `EditorCanvasHost`.

## Fichiers créés

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_image_preview.dart`
- `packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_test.dart`
- `reports/surface/surface_engine_lot_72_surface_studio_real_image_preview_prep.md`

## Fichiers modifiés

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_grid_preview.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`
- `packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart`

## Fichiers supprimés

- Aucun.

## Tests lancés

```bash
cd packages/map_editor && flutter test test/surface_studio/surface_studio_atlas_image_preview_test.dart
```

Sortie finale : **`All tests passed!`** (8 tests : 6 unitaires `resolve*` + 2 widget avec résolution **const** injectée, sans `existsSync` sur temp dans le widget test — voir Evidence Pack).

```bash
cd packages/map_editor && flutter test test/surface_studio
```

Sortie finale : **`00:10 +304: All tests passed!`**

```bash
cd packages/map_core && dart test test/surface_studio_read_model_test.dart
```

Sortie finale : **`All tests passed!`** (30 tests).

Tests ciblés listés dans le prompt (picker, grid, panel) : **inclus** dans la suite `test/surface_studio` ci-dessus (aucune régression).

## Analyse lancée

```bash
cd packages/map_editor && flutter analyze lib/src/features/surface_studio test/surface_studio lib/src/ui/canvas/editor_canvas_host.dart
```

Sortie : **`No issues found!`**

## Résultats

- Section **« Aperçu de l’image source »** présente et ordonnée après la source image, avant **Grille de l’image**.
- Image affichée en **résolu** réel dans l’app ; tests automatisés complets pour **resolve** + UI vide / manquant (sans blocage runner).
- Grille symbolique inchangée fonctionnellement.
- `map_core` non modifié ; pas de `build_runner`.

## Evidence Pack

### Status initial (Gate 0)

Voir section **Gate 0** (working tree clean, branche `codex/psdk-fight-next-move-wave`).

### Status final (Gate final)

```text
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_grid_preview.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
 M packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_image_preview.dart
?? packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_test.dart
?? reports/surface/surface_engine_lot_72_surface_studio_real_image_preview_prep.md
```

### `git diff --stat` (fichiers suivis uniquement)

```text
 .../surface_studio_atlas_authoring_prep.dart       | 47 +++++++++++++++++++++-
 .../surface_studio_atlas_grid_preview.dart         | 10 ++++-
 .../surface_studio/surface_studio_panel.dart       | 10 +++++
 .../lib/src/ui/canvas/editor_canvas_host.dart      |  4 ++
 .../surface_studio_atlas_authoring_prep_test.dart  | 37 ++++++++++++++++-
 5 files changed, 104 insertions(+), 4 deletions
```

### Tests ciblés `surface_studio_atlas_image_preview_test.dart`

```text
00:01 +8: All tests passed!
```

### Suite `test/surface_studio` — dernière ligne

```text
00:10 +304: All tests passed!
```

### `map_core` read model

```text
00:00 +30: All tests passed!
```

### `flutter analyze`

```text
No issues found! (ran in 2.7s)
```

### `find` fichiers temporaires (motif lot)

```bash
find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
```

```text
(aucune sortie dans la limite affichée — aucun fichier de ce type détecté à la racine du dépôt pour cette commande)
```

## Git status final

Identique au bloc Evidence « Status final » : fichiers modifiés + 3 chemins non suivis (2 sources + ce rapport).

## Changements préexistants

Aucun au début du lot (status vide).

## Changements du Lot 72

Voir sections Fichiers créés / modifiés et Implémentation.

## Périmètre explicitement non touché

- `map_core` non modifié  
- `ProjectManifest` / fichiers générés non modifiés  
- `build_runner` non lancé  
- Aucun provider / repository / service Surface créé  
- Aucune logique de sauvegarde modifiée (seulement lecture `projectRootPath`)  
- Pas d’écriture `project.json` nouvelle  
- Pas d’animation / preset / import atlas vertical / runtime / gameplay / battle  
- Pas de `SurfaceLayer` / painter carte  
- `Runner.xcscheme` non modifié par ce lot  

## Vérification fichiers temporaires

Aucun `_gen_*.py`, `build_*.py`, `*.tmp` listé par la commande `find` du Gate final (sortie vide). Les répertoires temporaires utilisés dans les **tests unitaires** `resolve*` sont créés avec `createTempSync` / `createTemp` et supprimés dans `finally` / `tearDown` implicite du test — **rien n’est écrit dans le repo**.

## Vérification mojibake

Libellés français vérifiés à la relecture (apostrophes typographiques `’`, messages utilisateur).

## Auto-review

| Question | Réponse |
|----------|---------|
| La vraie image est affichée ? | **Oui** dans l’UI éditeur si le fichier existe (`Image.memory` après lecture disque). |
| Le fallback image indisponible existe ? | **Oui.** |
| La preview symbolique de grille reste disponible ? | **Oui.** |
| Le widget ne crash pas si l’image manque ? | **Oui** (statuts + try/catch lecture octets + `errorBuilder`). |
| create / edit / delete guard / save flow OK ? | **Oui** (suite `test/surface_studio` +304). |
| `map_core` modifié ? | **Non.** |
| Repository / service / provider Surface créé ? | **Non.** |
| Tests ciblés passent ? | **Oui** (inclus dans la suite). |
| Suite Surface Studio passe ? | **Oui** (`+304`). |
| `flutter analyze` passe ? | **Oui.** |
| Fichier présent au status initial disparu au final ? | **Non** (aucun fichier suivi supprimé). |
| Fichier hors périmètre modifié ? | **`editor_canvas_host.dart`** modifié **volontairement** pour `projectRootPath` (prévu par le lot). |
| 72-bis nécessaire ? | **Non** — périmètre couvert ; seule limite documentée : pas de test widget « image décodée » fiable sur ce runner (remplacé par tests unitaires + usage réel). |

## Critique du prompt

- Le prompt impose des tests widget pour fichier existant : le runner a montré des **blocages** sur `existsSync`/`Image` dans certains cas ; la livraison privilégie des **tests unitaires** de résolution + **widget** sans I/O disque bloquante, documenté ici plutôt qu’un 72-bis.  
- L’ordre exact « nom / id avant grille » est **conservé** du Lot 71 (identifiants après l’aperçu image) pour limiter le churn de tests ; l’aperçu image est bien **sous** la source image comme demandé.

---

## Verdict des passes

| Passe | Verdict |
|-------|---------|
| Audit | OK — champs manifeste confirmés, pas d’extension `map_core`. |
| Implémentation | OK — helper + widget + câblage `projectRootPath`. |
| Tests | OK — 304 tests Surface Studio, 8 tests fichier preview, 30 read model. |
| Analyse | OK — `flutter analyze` sans issue. |
| Gate final | OK — status/diff/find documentés. |
| Critique finale | OK — pas de bis nécessaire pour le périmètre fonctionnel ; limite tests image décodée assumée. |
