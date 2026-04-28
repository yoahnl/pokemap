# Lot 79 — Generate Surface Preset from Vertical Atlas V0

## Résumé exécutif

Surface Studio peut créer un **`ProjectSurfacePreset`** dans le **catalogue de travail** à partir du mapping colonne → rôle et des **animations déjà présentes** (ids proposés identiques au Lot 77 / 78). Aucune animation ni atlas n’est créé ou modifié par ce lot ; pas de `map_core` modifié ; pas de sauvegarde automatique ; sélection passe sur le **preset créé**.

## Périmètre

- **Inclus** : `map_editor` — `surface_studio_vertical_atlas_preset_generator.dart`, `surface_studio_vertical_atlas_preset_creation_section.dart`, câblage `SurfaceStudioAtlasAuthoringPrep` + `SurfaceStudioPanel`, tests, ce rapport.
- **Exclus** : `map_core`, runtime, gameplay, battle, save flow, `project.json` direct.

## Passes Composer 2

1. Gate 0 + worktree  
2. Audit générateur animations Lot 78 (`surfaceStudioProposedAnimationId`, append catalogue)  
3. Audit modèles `map_core` `surface.dart` : `SurfaceVariantAnimationRef`, `SurfaceVariantAnimationRefSet`, `ProjectSurfacePreset`  
4. Plan local `SurfaceStudioVerticalAtlasPresetAppendPlan` + statuts  
5. Transformation mapping + catalogue → `ProjectSurfacePreset` + `surfaceStudioAppendPresetToWorkCatalog`  
6. Append immutable presets uniquement  
7. UI section « Création du preset Surface » + bouton + messages (sans jargon interdit)  
8. Tests + suite `test/surface_studio` + read model `map_core`  
9. `flutter analyze` ciblé  
10. Auto-review + critique prompt  

## Gate 0 — Status initial avant modification

*(Exécuté au début du Lot 79.)*

```text
pwd: /Users/karim/Project/pokemonProject
branche: codex/psdk-fight-next-move-wave
git status: vide (worktree propre sur HEAD ccdf1094)
git diff --stat: vide
git log -n 10: ccdf1094 … (fix sélecteur colonne), 33d776aa (Lot 78), …
```

**Changements préexistants** : aucun.  
**Changements du Lot 79** : fichiers listés ci-dessous.

## Analyze baseline

```bash
cd packages/map_editor && flutter analyze lib/src/features/surface_studio test/surface_studio
```

**Résultat final** : `No issues found!`

## Audit initial

- **Lot 78** : `surfaceStudioProposedAnimationId` / append animations via `onSurfaceCatalogChanged` ; ids stables `atlasSeg-roleSeg-loop`.  
- **`surface.dart`** : `SurfaceVariantAnimationRef(role, animationId)` ; `SurfaceVariantAnimationRefSet(refs:)` non vide, rôles uniques ; `ProjectSurfacePreset(id, name, variantAnimations, categoryId?, sortOrder)`.  
- **Preset** : refs ordonnées par indice d’énumération `SurfaceVariantRole` pour stabilité.

## Transformation mapping vers preset

1. Colonnes avec `role != null` → rôles uniques (première colonne par rôle si doublon).  
2. Pour chaque rôle : `animationId = surfaceStudioProposedAnimationId(atlasIdRaw, role)`.  
3. Si une animation manque dans `catalog.animations` → **bloqué** (aucune création).  
4. Sinon : `SurfaceVariantAnimationRefSet` puis `ProjectSurfacePreset` ; `id = <slug>-surface-preset` ; `name = « <nom atlas> — Surface »` ; `sortOrder = catalog.presets.length` ; `categoryId` = catégorie atlas catalogue sinon brouillon.  
5. **Rôles non couverts** : rôles de `standardSurfaceVariantRoleOrder` absents du mapping → compteur **M** ; message doux si **M > 0** (preset **incomplet** mais créable).

## Implémentation

- **`surface_studio_vertical_atlas_preset_generator.dart`** : plan, build, append.  
- **`surface_studio_vertical_atlas_preset_creation_section.dart`** : UI autonome (évite import circulaire avec `generation_plan`).  
- **`surface_studio_atlas_authoring_prep.dart`** : section sous le plan d’animations ; `onWorkCatalogPresetCreated` optionnel.  
- **`surface_studio_panel.dart`** : sélection `SurfaceStudioSelection.preset(id)` après création.

## Fichiers créés

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_preset_generator.dart`  
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_preset_creation_section.dart`  
- `packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_preset_generator_test.dart`  
- `reports/surface/surface_engine_lot_79_generate_surface_preset_from_vertical_atlas.md`  

## Fichiers modifiés

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart`  
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`  
- `packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart`  

## Fichiers supprimés

- Aucun.

## Tests lancés

```bash
cd packages/map_editor && flutter test test/surface_studio/surface_studio_vertical_atlas_preset_generator_test.dart
```

→ `00:01 +8: All tests passed!`

```bash
cd packages/map_editor && flutter test test/surface_studio
```

→ ligne finale : `00:12 +385: All tests passed!`

```bash
cd packages/map_core && dart test test/surface_studio_read_model_test.dart
```

→ `All tests passed!`

## Analyse lancée

Même commande que baseline → **`No issues found!`**

## Résultats

Critères d’acceptation du lot : **satisfaits** (preset depuis mapping + animations existantes, blocages manquant / doublon, partiel avec avertissement, analyze clean, suite verte).

## Evidence Pack

### Status final

```text
 M packages/map_editor/.../surface_studio_atlas_authoring_prep.dart
 M packages/map_editor/.../surface_studio_panel.dart
 M packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
?? .../surface_studio_vertical_atlas_preset_creation_section.dart
?? .../surface_studio_vertical_atlas_preset_generator.dart
?? .../surface_studio_vertical_atlas_preset_generator_test.dart
?? reports/surface/surface_engine_lot_79_generate_surface_preset_from_vertical_atlas.md
```

### `git diff --stat` (fichiers suivis)

```text
 .../surface_studio_atlas_authoring_prep.dart        | 21 +++++++++++++++++++++
 .../surface_studio/surface_studio_panel.dart        |  8 ++++++++
 .../surface_studio_atlas_authoring_prep_test.dart   | 15 +++++++++++++++
 3 files changed, 44 insertions(+)
```

### Fichiers temporaires

```bash
find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
```

→ aucune entrée pertinente (échantillon vide).

### Environnement local

Un échec transitoire `PathExistsException` sur lien SPM macOS a été contourné en supprimant le dossier `packages/map_editor/macos/Flutter/ephemeral/Packages/.packages` avant un second `flutter test` (hors périmètre git du lot).

## Git status final

Voir Evidence Pack ; aucun fichier suivi au Gate 0 n’a disparu sans explication.

## Changements préexistants

- Aucun au périmètre Lot 79.

## Changements du Lot 79

- Voir sections Fichiers créés / modifiés.

## Périmètre explicitement non touché

- `map_core` non modifié ; `ProjectManifest` / codecs non modifiés ; `build_runner` non lancé.  
- Aucun provider / repository / service Surface dédié.  
- Aucune animation créée par ce lot ; aucun atlas modifié.  
- Pas de modification du save flow ; pas d’écriture `project.json` depuis cette UI.  
- `Runner.xcscheme` non modifié.

## Vérification mojibake

- Chaînes UI en UTF-8 (`n’est`, `incomplet`, etc.).

## Auto-review

| Question | Réponse |
|----------|---------|
| Un `ProjectSurfacePreset` est créé ? | **Oui** (si conditions remplies) |
| Ajouté uniquement au catalogue de travail ? | **Oui** |
| Des `ProjectSurfaceAnimation` créées par ce lot ? | **Non** |
| `map_core` modifié ? | **Non** |
| `flutter analyze` final clean ? | **Oui** |
| Preset ne référence que des animations existantes ? | **Oui** |
| Animations manquantes bloquent ? | **Oui** |
| Doublon d’id preset bloqué ? | **Oui** |
| Rôles non assignés ignorés ? | **Oui** (hors preset) |
| Partiel avec warning ? | **Oui** |
| Animations / presets / atlas existants conservés ? | **Oui** (append + copies de listes) |
| Dirty après création ? | **Oui** (même mécanisme que mutations catalogue) |
| Browser presets mis à jour ? | **Oui** (read model reconstruit) |
| Save non auto ? | **Oui** |
| Create / edit / delete / Lot 78 non régressés ? | **Oui** (suite `test/surface_studio`) |
| Tests ciblés OK ? | **Oui** |
| Suite Surface Studio OK ? | **Oui** (`+385`) |
| Fichier initial disparu ? | **Non** |
| Fichier hors périmètre modifié ? | **Non** |
| 79-bis nécessaire ? | **Non** (V0 honnête ; persistance mapping hors scope) |

## Critique du prompt

Le prompt est cohérent. Seule nuance : la phrase « **Rôles couverts** » en UI compte les rôles mappés **dont l’animation existe** (aligné sur le contenu réel du preset), pas le nombre de colonnes assignées quand des animations manquent.
