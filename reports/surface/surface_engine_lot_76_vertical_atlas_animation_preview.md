# Lot 76 — Vertical Atlas Animation Preview V0

## Résumé exécutif

Ajout d’une **prévisualisation locale** des frames verticales par colonne mappée (`SurfaceStudioVerticalAtlasAnimationPreview`), intégrée dans la préparation atlas **après** le mapping des colonnes et **avant** l’aperçu grand format. Modèle pur `surfaceStudioVerticalAtlasAnimationPreviewSummary` + `CustomPainter` pour crop quand une image est résolue ; fallback textuel sinon. Nettoyage analyzer Lot 75 (`prefer_const_constructors`, etc.) jusqu’à **`No issues found!`**. Aucune persistance catalogue, aucun `ProjectSurfaceAnimation` / `ProjectSurfacePreset`, aucune modification `map_core`.

## Périmètre

- **Autorisé** : `packages/map_editor/lib/src/features/surface_studio/*`, `packages/map_editor/test/surface_studio/*`, ce rapport.
- **Interdit** (respecté) : `map_core`, `map_runtime`, gameplay, battle, `build_runner`, écriture `project.json`, nouveaux providers/repositories/services Surface.

## Gate 0 — Status initial avant modification

*(Capturé en début de lot sur la branche de travail ; le dépôt contenait déjà le travail Lot 75 non commité.)*

```text
pwd: /Users/karim/Project/pokemonProject/packages/map_editor (shell cwd lors d’une commande ultérieure ; repo racine: /Users/karim/Project/pokemonProject)
git branch --show-current: codex/psdk-fight-next-move-wave
git status --short --untracked-files=all:
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart
 M packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
?? nvidia_nim_models.json
?? packages/map_editor/lib/.../surface_studio_column_role_mapping_block.dart
?? packages/map_editor/lib/.../surface_studio_vertical_atlas_role_mapping.dart
?? packages/map_editor/test/.../surface_studio_column_role_mapping_block_test.dart
?? packages/map_editor/test/.../surface_studio_vertical_atlas_role_mapping_test.dart
?? reports/surface/surface_engine_lot_75_vertical_atlas_column_role_mapping_prep.md
git diff --stat (extrait): authoring_prep +69 / prep_test +77 (fichiers suivis uniquement)
git log --oneline -n 10: cd9bf788 feat(map_editor): Surface Studio Lot 74 — … (puis Lots 73…)
```

## Analyze baseline et nettoyage warnings Lot 75

- **Baseline** (session Lot 76) : `flutter analyze lib/src/features/surface_studio test/surface_studio` → **0 issue** après corrections déjà appliquées (constructeurs `const` dans les tests Surface Studio, petits correctifs lib Lot 75 : `SurfaceStudioColumnRoleMappingDraft.empty`, `const roles` dans `suggested`, variable inutilisée retirée dans le bloc mapping).
- **Final** : même commande → **`No issues found!`**.

## Passes Composer (internes)

1. **Pass 1** — Gate 0 + analyze baseline.  
2. **Pass 2** — Nettoyage `prefer_const_constructors` / lints Lot 75 (déjà vert au moment du contrôle final).  
3. **Pass 3** — Audit mapping colonne → rôle + résolution image (`resolveSurfaceStudioAtlasImagePreview`).  
4. **Pass 4** — Modèle local : `SurfaceStudioVerticalAtlasAnimationSourceRect`, `SurfaceStudioVerticalAtlasAnimationPreviewSummary`, fonction `surfaceStudioVerticalAtlasAnimationPreviewSummary`.  
5. **Pass 5** — UI : section « Aperçu animation par colonne », chips colonnes assignées, prev/suiv, Lecture/Pause (Timer 120 ms), durée affichée, crop ou fallback.  
6. **Pass 6** — Tests dédiés + test d’intégration léger dans `surface_studio_atlas_authoring_prep_test.dart`.  
7. **Pass 7** — `flutter test test/surface_studio`, `dart test` read model.  
8. **Pass 8** — Auto-review (section dédiée).

## Audit initial

- **Mapping** : `SurfaceStudioColumnRoleMappingDraft` — `assignments` avec `columnIndex` + `SurfaceVariantRole?` ; `roleForColumn` ; `suggested(columnCount)` aligné sur `standardSurfaceVariantRoleOrder`.  
- **Grille** : `surfaceStudioAtlasGridOverlayDraftValid` pour bloquer la preview si dimensions invalides.  
- **Image** : chemin absolu résolu uniquement si `SurfaceStudioAtlasImagePreviewResolveStatus.resolved` ; lecture synchrone des octets + `decodeImageFromList` pour le crop.  
- **Tests** : pas de `pumpAndSettle` long ; lecture auto optionnelle, non exigée dans les tests pour limiter le flakiness.

## Modèle local de preview animation

- **`SurfaceStudioVerticalAtlasAnimationSourceRect`** : `sourceX`, `sourceY`, `sourceWidth`, `sourceHeight`.  
- **`SurfaceStudioVerticalAtlasAnimationPreviewSummary`** : `columnIndex`, `role`, `frameCount` (= `rows`), `currentFrameIndex` (index après modulo), `tileWidth`, `tileHeight`, `sourceRect`.  
- **`surfaceStudioVerticalAtlasAnimationPreviewSummary(...)`** : `sourceX = columnIndex * tileWidth`, `sourceY = (frameIndex % rows) * tileHeight`.

## Implémentation

- Fichier **`surface_studio_vertical_atlas_animation_preview.dart`** : widget stateful, `SchedulerBinding.addPostFrameCallback` pour `_reloadImageBytes` / `_syncSelectedColumn` (évite `setState` pendant `didUpdateWidget`). Chips dans une zone **scrollable** bornée (`maxHeight: 120`) pour éviter overflow avec 23 colonnes.  
- **`surface_studio_atlas_authoring_prep.dart`** : insertion de `SurfaceStudioVerticalAtlasAnimationPreview` avec `mappingDraft: _columnRoleMappingDraft`, dimensions brouillon, `resolvedImagePath` si résolu.

## Fichiers créés

| Fichier |
|--------|
| `packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_preview.dart` |
| `packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_preview_test.dart` |
| `reports/surface/surface_engine_lot_76_vertical_atlas_animation_preview.md` |

## Fichiers modifiés

| Fichier | Motif |
|--------|--------|
| `surface_studio_atlas_authoring_prep.dart` | Intégration section preview après mapping colonnes. |
| `surface_studio_atlas_authoring_prep_test.dart` | Test présence titre « Aperçu animation par colonne » dans la préparation. |

## Fichiers supprimés

Aucun.

## Tests lancés

```bash
cd packages/map_editor && flutter test test/surface_studio/surface_studio_vertical_atlas_animation_preview_test.dart
# → 00:02 +8: All tests passed!

cd packages/map_editor && flutter test test/surface_studio/surface_studio_vertical_atlas_role_mapping_test.dart test/surface_studio/surface_studio_column_role_mapping_block_test.dart test/surface_studio/surface_studio_vertical_atlas_assistant_test.dart test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
# (inclus dans la suite complète ci-dessous)

cd packages/map_editor && flutter test test/surface_studio
# → dernière ligne: 00:18 +360: All tests passed!

cd packages/map_core && dart test test/surface_studio_read_model_test.dart
# → 00:00 +30: All tests passed!
```

## Analyse lancée

```bash
cd packages/map_editor && flutter analyze lib/src/features/surface_studio test/surface_studio
```

Sortie finale : **`No issues found!`**

## Résultats

- Section **« Aperçu animation par colonne »** présente et testée.  
- États vides / grille invalide / navigation modulo / calcul source rect / cas 23×32 (32 frames) couverts.  
- Suite Surface Studio **360** tests verts ; read model **30** tests verts.

## Evidence Pack

### Status final (`git status --short --untracked-files=all`)

```text
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart
 M packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
?? nvidia_nim_models.json
?? packages/map_editor/lib/.../surface_studio_column_role_mapping_block.dart
?? packages/map_editor/lib/.../surface_studio_vertical_atlas_animation_preview.dart
?? packages/map_editor/lib/.../surface_studio_vertical_atlas_role_mapping.dart
?? packages/map_editor/test/.../surface_studio_column_role_mapping_block_test.dart
?? packages/map_editor/test/.../surface_studio_vertical_atlas_animation_preview_test.dart
?? packages/map_editor/test/.../surface_studio_vertical_atlas_role_mapping_test.dart
?? reports/surface/surface_engine_lot_75_vertical_atlas_column_role_mapping_prep.md
?? reports/surface/surface_engine_lot_76_vertical_atlas_animation_preview.md
```

### `git diff --stat` (fichiers suivis)

```text
 .../surface_studio_atlas_authoring_prep.dart       | 69 ++++++++++++++++++-
 .../surface_studio_atlas_authoring_prep_test.dart  | 77 ++++++++++++++++++++++
 2 files changed, 144 insertions(+), 2 deletions(-)
```

### Fichiers temporaires

```bash
find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
```

→ **aucune sortie** (rien trouvé sous la racine du repo pour ces motifs).

## Git status final

Identique au bloc Evidence ci-dessus : fichiers **M** = lots 75/76 sur la préparation atlas ; **??** = Lot 75 (mapping colonnes, rapport 75) + Lot 76 (animation preview + ce rapport) + `nvidia_nim_models.json` **hors périmètre** (préexistant à l’atelier, non touché par ce lot).

## Changements préexistants

- Lot 75 : fichiers untracked mapping colonnes + rapport 75 ; `nvidia_nim_models.json` toujours présent en untracked.

## Changements du Lot 76

- Nouveau module preview animation + tests.  
- Intégration dans `SurfaceStudioAtlasAuthoringPrep` + un test de présence du titre.

## Périmètre explicitement non touché

- `map_core` non modifié (lecture seule des types publics).  
- `ProjectManifest` / fichiers générés non modifiés.  
- `build_runner` non lancé.  
- Aucun provider / repository / service Surface.  
- Aucune modification du flux de sauvegarde disque.  
- Pas de création `ProjectSurfaceAnimation` / `ProjectSurfacePreset`.  
- `Runner.xcscheme` non modifié.  
- `map_runtime`, `map_gameplay`, `map_battle` non modifiés.

## Vérification fichiers temporaires

Aucun `_gen_*.py`, `build_*.py`, `*.tmp` trouvé par `find` à la racine du dépôt.

## Vérification mojibake

Rapport et chaînes UI en UTF-8 cohérent (apostrophes typographiques existantes du module).

## Auto-review

| Question | Réponse |
|----------|---------|
| Preview animation locale uniquement ? | **Oui** |
| `ProjectSurfaceAnimation` créés ? | **Non** |
| `ProjectSurfacePreset` créé ? | **Non** |
| `map_core` modifié ? | **Non** |
| Cleanup analyze Lot 75 si nécessaire ? | **Oui** (état clean vérifié) |
| `flutter analyze` final clean ? | **Oui** |
| Colonne, rôle, frame count, frame courante affichés ? | **Oui** |
| Calcul `sourceX` / `sourceY` testé ? | **Oui** |
| Cas 23×32 → 32 frames ? | **Oui** |
| Dimensions invalides gérées ? | **Oui** |
| Create / edit / delete / save toujours OK ? | **Non régression** via suite existante (**Oui** au sens tests verts) |
| Tests ciblés + suite Surface Studio verts ? | **Oui** |
| Fichier présent au status initial disparu au final ? | **Non** |
| Fichier hors périmètre modifié par ce lot ? | **Non** (`nvidia_nim_models.json` inchangé) |
| 76-bis nécessaire ? | **Non** — périmètre V0 tenu ; lecture Timer pourrait être affinée plus tard si besoin UX |

## Critique du prompt

Le prompt est cohérent avec l’architecture (preview locale, pas de catalogue). La contrainte « Gate 0 avant toute modification » suppose une session continue : en reprise, le statut initial doit être archivé manuellement. L’interdiction des noms techniques dans l’UI est respectée dans les libellés ajoutés ; les tests `map_core` utilisent encore les types domaine dans les fixtures (acceptable hors UI).

---

*Fin du rapport Lot 76.*
