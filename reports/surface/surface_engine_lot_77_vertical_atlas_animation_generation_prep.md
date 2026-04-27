# Lot 77 — Vertical Atlas Animation Generation Prep V0

## Résumé exécutif

Introduction d’un **plan local de génération** des animations Surface à partir du mapping colonnes → rôles et de la grille brouillon : ids proposés (`<atlas-slug>-<rôle-slug>-loop`), frames, durées, rectangles source par frame, statuts **prête / invalide / doublon** (lecture seule des ids existants via `SurfaceStudioReadModel.animations`). **Aucune** écriture catalogue, **aucun** `ProjectSurfaceAnimation` ajouté, **aucune** modification `map_core`. UI : section **Plan de génération des animations** sous l’aperçu animation, champ durée ms éditable (défaut 120), boutons **Prévisualiser le plan** et **Réinitialiser la durée par frame**.

## Périmètre

- **Touché** : `map_editor` Surface Studio (`surface_studio_atlas_authoring_prep`, nouveau module + tests, test préparation).
- **Non touché** : `map_core` (hors lecture types publics), runtime, gameplay, battle, `build_runner`, flux save, `project.json`.

## Gate 0 — Status initial avant modification

Branche : `codex/psdk-fight-next-move-wave`, HEAD après Lots 75–76 : `021abf5f`.  
État git **sans modifications locales** au démarrage du Lot 77 (worktree propre avant édition).  
**Préexistences hors lot** : aucun fichier hors périmètre listé dans le status au moment du Gate 0 de cette session ; le rapport Lot 76 mentionnait parfois `nvidia_nim_models.json` sur d’autres machines — **non modifié, non inclus au Lot 77**.

## Analyze baseline

```bash
cd packages/map_editor && flutter analyze lib/src/features/surface_studio test/surface_studio
```

Résultat final après implémentation : **`No issues found!`**

## Passes Composer (internes)

1. **Pass 1** — Gate 0 + worktree propre.  
2. **Pass 2** — Audit preview Lot 76 + mapping + `readModel.animations`.  
3. **Pass 3** — Modèles `SurfaceStudioVerticalAtlasAnimationGenerationSourceRect`, `…Item`, `…Summary`, `…Plan`, builder pur + slugs.  
4. **Pass 4** — `SurfaceStudioVerticalAtlasAnimationGenerationPlanSection` + scroll pour listes longues.  
5. **Pass 5** — Priorité statut invalide > doublon ; durée ≤ 0 → plan invalide.  
6. **Pass 6** — Tests dédiés + test titre dans `authoring_prep`.  
7. **Pass 7** — Suite `test/surface_studio` + `dart test` read model.  
8. **Pass 8** — Auto-review.

## Audit initial

- Colonnes assignées : `mappingDraft.assignments` avec `role != null`, tri par `columnIndex`.  
- `frameCount` = `rows` si grille valide.  
- Rects source : `x = columnIndex * tw`, `y = f * th`.  
- Doublons : ensemble des `readModel.animations[].id` (pas de mutation du catalogue).

## Modèle local de plan de génération

- **`SurfaceStudioVerticalAtlasAnimationGenerationSourceRect`** : `frameIndex`, `sourceX`, `sourceY`, `sourceWidth`, `sourceHeight`.  
- **`SurfaceStudioVerticalAtlasAnimationPlanItemStatus`** : `ready` | `invalid` | `duplicate`.  
- **`SurfaceStudioVerticalAtlasAnimationGenerationItem`** : champs demandés + `isReady` + `problems`.  
- **`SurfaceStudioVerticalAtlasAnimationGenerationSummary`** : compteurs + `durationFieldValid`.  
- **`buildSurfaceStudioVerticalAtlasAnimationGenerationPlan(...)`** : construction pure.

## Implémentation

- Fichier **`surface_studio_vertical_atlas_animation_generation_plan.dart`** : slugs atlas (ASCII, accents latins courants repliés), slugs rôle alignés sur les exemples type `eau-plein-loop` / `bord-haut`, détail scrollable après « Prévisualiser le plan », conteneur scrollable pour éviter overflow en tests / écrans courts.  
- **`surface_studio_atlas_authoring_prep.dart`** : insertion du panneau après `SurfaceStudioVerticalAtlasAnimationPreview`.

## Fichiers créés

| Fichier |
|--------|
| `packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generation_plan.dart` |
| `packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart` |
| `reports/surface/surface_engine_lot_77_vertical_atlas_animation_generation_prep.md` |

## Fichiers modifiés

| Fichier |
|--------|
| `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart` |
| `packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart` |

## Fichiers supprimés

Aucun.

## Tests lancés

```bash
cd packages/map_editor && flutter test test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart
# → 00:02 +11: All tests passed!

cd packages/map_editor && flutter test test/surface_studio
# → 00:12 +372: All tests passed!

cd packages/map_core && dart test test/surface_studio_read_model_test.dart
# → +30: All tests passed!
```

## Analyse lancée

```bash
cd packages/map_editor && flutter analyze lib/src/features/surface_studio test/surface_studio
```

→ **`No issues found!`**

## Résultats

- Section **Plan de génération des animations** + résumé + détail par item après prévisualisation.  
- Suite Surface Studio : **372** tests (+12 vs Lot 76 : 11 tests fichier plan + 1 test authoring).

## Evidence Pack

### Status final (extrait)

```text
 M packages/map_editor/.../surface_studio_atlas_authoring_prep.dart
 M packages/map_editor/.../surface_studio_atlas_authoring_prep_test.dart
?? packages/map_editor/.../surface_studio_vertical_atlas_animation_generation_plan.dart
?? packages/map_editor/.../surface_studio_vertical_atlas_animation_generation_plan_test.dart
?? reports/surface/surface_engine_lot_77_vertical_atlas_animation_generation_prep.md
```

### `git diff --stat` (fichiers suivis)

```text
 .../surface_studio_atlas_authoring_prep.dart        | 13 +++++
 .../surface_studio_atlas_authoring_prep_test.dart  | 14 +++++
 2 files changed, 27 insertions(+)
```

### Fichiers temporaires

`find` sur motifs `_gen_*.py`, `build_*.py`, `*.tmp` : **aucune occurrence** (échantillon racine).

## Git status final

Voir Evidence Pack ; fichiers **??** = apports Lot 77 uniquement dans le périmètre Surface Studio + rapport.

## Changements préexistants

Aucun dans le worktree au début du lot (HEAD propre).

## Changements du Lot 77

Plan de génération + tests + intégration UI + rapport.

## Périmètre explicitement non touché

Confirmé : `map_core` non modifié, `ProjectManifest` / générés non modifiés, `build_runner` non lancé, aucun provider/repository/service Surface, save flow / `project.json` inchangés, aucune animation ni preset créés dans le catalogue, pas de runtime / gameplay / battle, `Runner.xcscheme` non modifié.

## Vérification fichiers temporaires

Aucun fichier temporaire ajouté par le lot.

## Vérification mojibake

Chaînes UTF-8 cohérentes (apostrophes typographiques conservées).

## Auto-review

| Question | Réponse |
|----------|---------|
| Plan local uniquement ? | **Oui** |
| `ProjectSurfaceAnimation` créés ? | **Non** |
| `ProjectSurfacePreset` créé ? | **Non** |
| `map_core` modifié ? | **Non** |
| `flutter analyze` final clean ? | **Oui** |
| Plan affiche animations proposées ? | **Oui** (après prévisualisation) |
| Ids, rôles, colonnes, frames, durée ? | **Oui** |
| `sourceX` / `sourceY` testés ? | **Oui** |
| 23×32 → 32 frames ? | **Oui** |
| Doublons détectés ? | **Oui** |
| Dimensions invalides gérées ? | **Oui** |
| Aucune animation ajoutée au catalogue ? | **Oui** |
| create / edit / delete / save OK ? | **Oui** (non-régression suite) |
| Tests ciblés + suite OK ? | **Oui** |
| Fichier initial disparu ? | **Non** |
| Fichier hors périmètre modifié ? | **Non** |
| 77-bis nécessaire ? | **Non** — génération réelle et persistance restent lots suivants |

## Critique du prompt

Le prompt est clair sur la non-persistance. La détection de doublon suppose des ids catalogue **exactement** égaux au proposé (comportement voulu V0). Les slugs rôle sont une convention locale jusqu’à alignement éventuel avec un générateur futur.

---

*Fin du rapport Lot 77.*
