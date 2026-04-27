# Lot 78 — Generate Surface Animations from Vertical Atlas V0

## Résumé exécutif

Le Surface Studio peut désormais **matérialiser** les entrées du plan de génération (Lot 77) en **`ProjectSurfaceAnimation`** réelles, **uniquement** via append au **catalogue de travail** (`onSurfaceCatalogChanged` / équivalent), sans preset, sans modification des atlas, sans `map_core`, sans `build_runner`, sans déclencher la sauvegarde projet. Une action UI explicite ajoute les items **prêts** ; les **invalides** et **doublons** (plan) ne sont pas générés ; dédup interne si deux colonnes prêtes collisionnent sur le même `proposedAnimationId`. Après création, la sélection passe à la **première** animation créée.

## Périmètre

- **Inclus** : `map_editor` — `surface_studio_vertical_atlas_animation_generator.dart` (nouveau), filière plan → catalogue, UI section plan, tests, ce rapport.
- **Exclus** : `map_core`, `map_runtime`, gameplay, battle, presets persistés, manifest disque, providers/repositories Surface dédiés.

## Passes Composer 2 (obligatoires)

| Pass | Contenu |
|------|---------|
| 1 | Gate 0 + analyse worktree |
| 2 | Audit plan Lot 77 (`ready` / `duplicate` / `invalid`, `proposedAnimationId`, rects preview) |
| 3 | Modèle local : outcome append + collecte depuis items `ready` |
| 4 | Transformation item → `ProjectSurfaceAnimation` (`SurfaceAtlasTileRef` grille, timeline, noms lisibles) |
| 5 | `surfaceStudioAppendAnimationsToWorkCatalog` — append fin de liste, atlases/presets inchangés |
| 6 | UI : bouton, messages « aucun preset », résumé N créées / M ignorées, bouton désactivé si 0 ready |
| 7 | Tests générateur + plan widget + suite `test/surface_studio` + `map_core` read model |
| 8 | `flutter analyze` ciblé Surface Studio |
| 9 | Auto-review + critique prompt (ci-dessous) |

## Gate 0 — Status initial avant modification

*(Session Lot 78 : worktree propre sur `HEAD` avant toute édition ; branche `codex/psdk-fight-next-move-wave`.)*

- **Changements préexistants** : aucun fichier modifié ou non suivi lié au Lot 78 avant le début des changements.
- **Changements du Lot 78** : tous les fichiers listés en section « Fichiers modifiés / créés » et le présent rapport.

## Analyze baseline

Commande : `cd packages/map_editor && flutter analyze lib/src/features/surface_studio test/surface_studio`

Résultat final (après correction `const` / `unnecessary_const` dans le test générateur) :

```text
No issues found! (ran in 1.9s)
```

## Audit initial

Fichiers relus (constructeurs `map_core` via imports, sans modification du package) :

- `surface_studio_vertical_atlas_animation_generation_plan.dart` — statuts items, `isReady`, `proposedAnimationId`, `frameCount`, `durationMsPerFrame`, `columnIndex`, `role`.
- `surface_studio_vertical_atlas_animation_preview.dart`, `surface_studio_vertical_atlas_role_mapping.dart`, `surface_studio_atlas_authoring_prep.dart` — câblage brouillon / atlas.
- `packages/map_core/lib/src/models/surface.dart` — `SurfaceAtlasTileRef`, `SurfaceAnimationFrame`, `SurfaceAnimationTimeline`, `ProjectSurfaceAnimation`, `ProjectSurfaceCatalog`.

**Règles retenues** : frames = une ligne atlas par frame (`row` 0..`frameCount-1`, `column` = `columnIndex`) ; `durationMs` = `durationMsPerFrame` ; `syncGroupId` = `atlasIdForTileRefs` (trim) ; `categoryId` = catégorie atlas persistée si dispo, sinon catégorie brouillon atlas ; `sortOrder` = `animations.length + index` au moment de l’append (base = longueur liste existante).

## Transformation plan vers animations

1. Filtrer `plan.items` où `isReady` et `status == ready`.
2. Dédup par `proposedAnimationId` dans le même clic (compteur `ignoredReadyCount`).
3. Pour chaque item retenu : `SurfaceAnimationFrame(tileRef: SurfaceAtlasTileRef(atlasId, column, row), durationMs)` pour `r in 0..frameCount-1`.
4. `SurfaceAnimationTimeline(frames: …)` puis `ProjectSurfaceAnimation(id: proposedAnimationId, name: « préfixe — rôle lisible », …)`.
5. `ProjectSurfaceCatalog(animations: [...existants, ...nouveaux], atlases: copie, presets: copie)`.

## Implémentation

- **`surface_studio_vertical_atlas_animation_generator.dart`** : fonctions pures d’assemblage + append catalogue.
- **`surface_studio_vertical_atlas_animation_generation_plan.dart`** : section plan — bouton conditionné à `readyCount > 0` et `onWorkCatalogChanged != null` ; appelle append puis `onWorkCatalogChanged` puis `onWorkCatalogAnimationsCreated(ids)` ; SnackBar / textes utilisateur sans jargon interdit.
- **`surface_studio_atlas_authoring_prep.dart`** : passage `atlasDisplayName`, `atlasCategoryDraft`, callbacks catalogue / ids créés.
- **`surface_studio_panel.dart`** : câble callbacks ; sélection `SurfaceStudioSelection.animation(createdIds.first)` si non vide.

## Fichiers créés

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generator.dart`
- `packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generator_test.dart`
- `reports/surface/surface_engine_lot_78_generate_surface_animations_from_vertical_atlas.md` (ce fichier)

## Fichiers modifiés

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generation_plan.dart`
- `packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart`

## Fichiers supprimés

- Aucun.

## Tests lancés

```bash
cd packages/map_editor && flutter test test/surface_studio/surface_studio_vertical_atlas_animation_generator_test.dart test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart
```

Sortie finale :

```text
00:02 +15: All tests passed!
```

```bash
cd packages/map_editor && flutter test test/surface_studio
```

Ligne finale de la suite :

```text
00:14 +376: All tests passed!
```

```bash
cd packages/map_core && dart test test/surface_studio_read_model_test.dart
```

```text
00:00 +30: All tests passed!
```

## Analyse lancée

```bash
cd packages/map_editor && flutter analyze lib/src/features/surface_studio test/surface_studio
```

→ `No issues found!`

## Résultats

- Critères d’acceptation du lot : **satisfaits** (action UI, append catalogue uniquement, frames grille, pas de preset, analyze clean, suite Surface Studio verte, read model `map_core` inchangé et tests verts).

## Evidence Pack

### Status final (après rapport + code)

```bash
git status --short --untracked-files=all
```

```text
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generation_plan.dart
 M packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generator.dart
?? packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generator_test.dart
?? reports/surface/surface_engine_lot_78_generate_surface_animations_from_vertical_atlas.md
```

```bash
git diff --stat
```

```text
 .../surface_studio_atlas_authoring_prep.dart       |   8 ++
 .../surface_studio/surface_studio_panel.dart       |   8 ++
 ...o_vertical_atlas_animation_generation_plan.dart | 127 ++++++++++++++++++++-
 ...tical_atlas_animation_generation_plan_test.dart |  37 ++++++
 4 files changed, 179 insertions(+), 1 deletion(-)
```

*(Les fichiers `??` générateur / test / rapport n’apparaissent pas dans `git diff --stat` tant qu’ils ne sont pas indexés.)*

### Diff stat (tracked uniquement, avant ajout du rapport au suivi)

```text
 .../surface_studio_atlas_authoring_prep.dart       |   8 ++
 .../surface_studio/surface_studio_panel.dart       |   8 ++
 ...o_vertical_atlas_animation_generation_plan.dart | 127 ++++++++++++++++++++-
 ...tical_atlas_animation_generation_plan_test.dart |  37 ++++++
 4 files changed, 179 insertions(+), 1 deletion(-)
```

### Fichiers temporaires

```bash
find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
```

→ **aucune** occurrence dans l’échantillon exécuté (sortie vide).

## Git status final

Voir Evidence Pack ; aucun fichier du status initial ne doit disparaître sans explication (aucun fichier préexistant supprimé par ce lot).

## Changements préexistants

- **Aucun** pour le périmètre Lot 78 : tout provient de l’implémentation Lot 78.

## Changements du Lot 78

- Générateur + tests + wiring UI/panel + rapport.

## Périmètre explicitement non touché

- `map_core` non modifié (y compris `ProjectManifest` / `.g.dart` / `.freezed.dart`).
- Fichiers générés non modifiés ; `build_runner` non lancé.
- Aucun provider / repository / service Surface dédié créé.
- Aucune logique de sauvegarde modifiée ; pas d’écriture `project.json` directe depuis cette feature.
- Pas de création `ProjectSurfacePreset` ni `SurfaceVariantAnimationRefSet`.
- `map_runtime`, `map_gameplay`, `map_battle` non modifiés.
- `Runner.xcscheme` non modifié.
- Pas d’import atlas vertical réel ni painter runtime.

## Vérification fichiers temporaires

- Recherche `_gen_*.py`, `build_*.py`, `*.tmp` : **rien** de pertinent ajouté par le lot.

## Vérification mojibake

- Chaînes UI en français UTF-8 (`n’est`, `catalogue`, etc.) ; pas de séquences corrompues détectées à la relecture.

## Auto-review

| Question | Réponse |
|----------|---------|
| Des `ProjectSurfaceAnimation` sont créés ? | **Oui** |
| Ajoutés uniquement au catalogue de travail ? | **Oui** (via callback existant, pas disque) |
| Un `ProjectSurfacePreset` est créé ? | **Non** |
| `map_core` modifié ? | **Non** |
| `flutter analyze` final clean ? | **Oui** |
| Seuls les items `ready` générés ? | **Oui** |
| Doublons ignorés ? | **Oui** (plan + dédup id dans le lot) |
| Invalides ignorés ? | **Oui** |
| Frames `column`/`row` correctes ? | **Oui** (tests 23×32) |
| `durationMs` conservé ? | **Oui** |
| Animations existantes conservées ? | **Oui** |
| Presets conservés ? | **Oui** |
| Dirty après génération ? | **Oui** (flux catalogue inchangé côté contrat ; régression panel 62.x) |
| Browser affiche les nouvelles ? | **Oui** (catalogue mis à jour + tests existants catalogue) |
| Save non auto-déclenché ? | **Oui** |
| Create / edit atlas / delete guard / save manuel OK ? | **Oui** (non-régression suite) |
| Tests ciblés OK ? | **Oui** |
| Suite `test/surface_studio` OK ? | **Oui** (`+376`) |
| Fichier initial disparu du status final ? | **Non** |
| Fichier hors périmètre modifié ? | **Non** |
| 78-bis nécessaire ? | **Non** — périmètre V0 couvert ; Lot 79 pourra brancher presets. |

## Critique du prompt

Le prompt est cohérent avec l’architecture existante (catalogue de travail + dirty + apply manifest séparé). Seule ambiguïté levée : **dédup intra-lot** quand deux colonnes `ready` produiraient le même `proposedAnimationId` (traité par `ignoredReadyCount`, aligné avec l’esprit « ne pas écraser »).
