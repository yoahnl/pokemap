# Lot PathPattern-41 — Asset & Bounds Validation V0

## 1. Résumé exécutif

Diagnostics Path Studio enrichis : pour chaque PathPattern sauvegardé (centerPattern + frames des variants du base preset), validation **fichier tileset** (présence, décodage PNG) et **bounds** des `TilesetSourceRect` en pixels (`settings.tileWidth` / `tileHeight`), avec avertissement si la source n’est pas **1×1 tuile**. Les infos image sont chargées via un **adaptateur synchrone local** (`loadPathPatternTilesetImageInfoMap`) lorsque `projectRootPath` est fourni au panel. Aucun changement `map_core`, runtime, format JSON ni politique de rendu.

## 2. Audit initial (réponses ciblées)

| # | Réponse |
|---|---------|
| 1 | `projectRootPath` : paramètre `PathStudioPanel.projectRootPath`, injecté par `PathStudioWorkspace` depuis `editorProjectRootPathProvider`. |
| 2 | `tileWidth` / `tileHeight` : `ProjectManifest.settings` (`ProjectSettings`, défaut 16×16). |
| 3 | Picker : `loadPathStudioTilesetImage` (async) dans `path_studio_tileset_image_picker.dart` — décodage `package:image`. |
| 4 | Réutilisation : même bibliothèque `decodeImage` dans le loader synchrone Lot 41. |
| 5 | Lot 38 : diagnostics manifest-only ; pas de fichier ni bounds. |
| 6 | Frame effective : commentaire `map_core` — `tilesetId` vide → contexte parent ; Path Studio résout avec `effectivePathPatternFrameTilesetId`. |
| 7 | `tilesetId == ""` → tileset du **ProjectPathPreset** de base. |
| 8 | Sans fichier : manifest-only (`missingBaseTileset`, `missingFrameTileset` pour override non vide). |
| 9 | Avec fichier : existence, décodage, dimensions px pour bounds. |
| 10 | UI : cartes et `_DiagnosticsCard` existantes ; pas de refonte. |

## 3. Décision diagnostics asset/bounds V0

| Code stable | Sévérité | Déclencheur |
|-------------|----------|---------------|
| `missingTilesetImageFile` | blocking | Entrée tileset dans le manifest + fichier absent sous `projectRootPath`. |
| `unreadableTilesetImageFile` | blocking | Fichier présent, `decodeImage` null ou exception. |
| `frameSourceOutOfBounds` | blocking | Rectangle source en px dépasse `widthPx×heightPx`. |
| `unsupportedPathPatternFrameSize` | warning | `source.width` ou `source.height` ≠ 1 (aligné preview statique V0). |
| `assetValidationUnavailable` | info | Pas de carte image injectée ou dimensions tuile invalides — **une seule fois sur la première carte** pour éviter le spam. |

## 4. Règle tilesetId vide vs override

- `frame.tilesetId.trim().isEmpty` → résolution **base** (`effectivePathPatternFrameTilesetId`). Jamais `missingFrameTileset`.
- `missingFrameTileset` uniquement si override **non vide** et absent du manifest (inchangé dans `path_pattern_editor_read_model.dart`).

## 5. Image info / filesystem adapter

- Fichier : `path_pattern_tileset_image_info_loader.dart` — `loadPathPatternTilesetImageInfoMap(projectRootPath, manifest)` : une passe par `ProjectTilesetEntry`, chemin `normalize(join(root, relativePath))`, `File.existsSync`, `decodeImage`.

## 6. Bounds validation

Formule (tuiles → px) :

```text
leftPx = source.x * tileWidth
topPx = source.y * tileHeight
rightPx = (source.x + source.width) * tileWidth
bottomPx = (source.y + source.height) * tileHeight
```

Valide si tout ≥ 0 et `rightPx ≤ imageWidthPx`, `bottomPx ≤ imageHeightPx`.

## 7. Read model enrichi

`createPathPatternEditorReadModel` accepte en option :

```dart
Map<String, PathPatternTilesetImageInfo>? tilesetImageInfoById,
```

Sans carte → diagnostics manifest-only + éventuellement `assetValidationUnavailable` sur **index 0** uniquement.

## 8. UI diagnostics

- Panel : `_pathPatternReadModel()` charge la carte d’infos si `projectRootPath` non vide.
- Cartes : compteur `blocage(s)` inclut les nouveaux blocking.
- Détail read-only : titres « Image de tileset introuvable », « Frame hors image », etc.
- **Brouillon** création/édition : hors scope V0 (priorité aux patterns sauvegardés).

## 9. Cas non implémentés / reportés

- Diagnostics asset sur **draft** Path Studio UI : non branchés dans ce lot (priorité prompt).
- Cache disque des métadonnées image entre builds : non (recalcul synchrone à chaque `build`).

## 10. Fichiers créés

- `packages/map_editor/lib/src/features/path_studio/path_pattern_asset_diagnostics.dart`
- `packages/map_editor/lib/src/features/path_studio/path_pattern_tileset_image_info_loader.dart`
- `packages/map_editor/test/path_pattern/path_pattern_asset_diagnostics_test.dart`
- `reports/pathPattern/pathpattern_41_asset_bounds_validation_v0.md`
- `reports/pathPattern/pathpattern_41_git_diff.patch`

## 11. Fichiers modifiés

- `packages/map_editor/lib/src/features/path_studio/path_pattern_diagnostics.dart`
- `packages/map_editor/lib/src/features/path_studio/path_pattern_editor_read_model.dart`
- `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart`
- `packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart`
- `packages/map_editor/test/path_pattern/path_studio_panel_test.dart`

## 12. Fichiers supprimés

Aucun.

## 13. Tests exécutés

```bash
cd packages/map_editor && flutter test test/path_pattern/path_pattern_asset_diagnostics_test.dart --reporter expanded
```
→ **12 tests, All tests passed.**

```bash
cd packages/map_editor && flutter test test/path_pattern/path_pattern_editor_read_model_test.dart --reporter expanded
```
→ **22 tests, All tests passed.**

```bash
cd packages/map_editor && flutter test test/path_pattern/path_studio_panel_test.dart --name PathPattern-41 --reporter expanded
```
→ **3 tests, All tests passed.**

```bash
cd packages/map_editor && flutter test test/path_pattern/ --reporter compact
```
→ **All tests passed** (suite complète `test/path_pattern/`).

```bash
cd packages/map_core && dart test test/project_manifest_path_pattern_save_reload_test.dart test/path_pattern_water_animated_golden_slice_test.dart test/path_pattern_visual_resolution_test.dart --reporter compact --no-color
```
→ **All tests passed.**

```bash
cd packages/map_runtime && flutter test test/path_pattern_water_animated_runtime_golden_slice_test.dart test/path_pattern_runtime_render_resolution_test.dart --reporter compact
```
→ **All tests passed.**

## 14. Résultats des validations

```bash
cd packages/map_editor && flutter analyze \
  lib/src/features/path_studio/path_pattern_diagnostics.dart \
  lib/src/features/path_studio/path_pattern_asset_diagnostics.dart \
  lib/src/features/path_studio/path_pattern_tileset_image_info_loader.dart \
  lib/src/features/path_studio/path_pattern_editor_read_model.dart \
  lib/src/features/path_studio/path_studio_panel.dart \
  test/path_pattern/path_pattern_asset_diagnostics_test.dart \
  test/path_pattern/path_pattern_editor_read_model_test.dart \
  test/path_pattern/path_studio_panel_test.dart
```

- **path_pattern_asset_diagnostics.dart** : `No issues found!`
- Autres fichiers : uniquement **info** `prefer_const_constructors` sur quelques tests (dette mineure, pas d’erreur).

## 15. git status final

À produire localement : `git status --short --untracked-files=all` (inclut les nouveaux fichiers et ce rapport).

## 16. git diff --stat

```text
 .../path_studio/path_pattern_diagnostics.dart      |  10 ++
 .../path_pattern_editor_read_model.dart            |  33 +++++-
 .../features/path_studio/path_studio_panel.dart    |  22 ++++-
 .../path_pattern_editor_read_model_test.dart       | 105 ++++++++++++++++++++
 .../test/path_pattern/path_studio_panel_test.dart  | 106 +++++++++++++++++++++
 5 files changed, 270 insertions(+), 6 deletions(-)
```

*(Les fichiers nouvellement ajoutés apparaissent en non suivis jusqu’à `git add`.)*

## 17. git diff --name-status

```text
M	packages/map_editor/lib/src/features/path_studio/path_pattern_diagnostics.dart
M	packages/map_editor/lib/src/features/path_studio/path_pattern_editor_read_model.dart
M	packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
M	packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart
M	packages/map_editor/test/path_pattern/path_studio_panel_test.dart
```

## 18. Evidence Pack

- Diff complet : `reports/pathPattern/pathpattern_41_git_diff.patch`
- Preuve **tilesetId vide** : tests `effectivePathPatternFrameTilesetId` + test read model existant « missing frame tileset override » (override non vide).
- Preuve **image manquante / illisible / OOB / multi-tile** : `path_pattern_asset_diagnostics_test.dart`
- Preuve **UI** : groupe `PathPattern-41 asset / bounds diagnostics` dans `path_studio_panel_test.dart`

## 19. Auto-review

- **Couvert** : centre + variants du base preset lié ; pas d’élargissement à tout le projet.
- **Limite** : pas d’asset diagnostics dans l’éditeur de brouillon ; chargement synchrone peut coûter sur de gros projets (acceptable V0).
- **Non-régression** : suites `map_editor` `path_pattern/`, `map_core`, `map_runtime` ciblées vertes.

## 20. Critique du prompt

Exhaustif ; le scope « pas de draft » est respecté en documentant l’optionalité. Le rapport Evidence Pack complet inclut le `.patch` pour éviter les citations tronquées du diff.

## 21. Conclusion

Lot PathPattern-41 livré : diagnostics asset/bounds visibles dans Path Studio pour les PathPatterns sauvegardés, règle `tilesetId` vide vs override respectée et testée, boundaries alignées sur `ProjectSettings` et preview V0 (1×1 source).

---

## Checklist finale

- [x] Audit initial réalisé.
- [x] AGENTS.md et agent_rules.md pris en compte (périmètre `map_editor`, pas de git write).
- [x] Aucun faux test.
- [x] Aucun provider inventé.
- [x] Aucun repository/service global ajouté.
- [x] Aucun map_core modifié.
- [x] Aucun runtime modifié.
- [x] Aucun format JSON modifié.
- [x] Aucun build_runner.
- [x] Diagnostics asset/bounds ajoutés côté map_editor.
- [x] tilesetId vide → base tileset.
- [x] Override absent → missingFrameTileset (lot existant).
- [x] Image manquante / illisible / OOB / multi-tile.
- [x] Center + variants base validés.
- [x] Read model enrichi.
- [x] UI détail + carte (compteur blocages).
- [x] Tests + analyze bornée (0 erreur sur fichier asset pur).
- [x] Rapport présent.
