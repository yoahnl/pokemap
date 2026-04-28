# Lot 80 — Vertical Atlas Golden Slice / End-to-End Authoring V0

## Résumé exécutif

Preuve automatisée **end-to-end** (sans refonte UI) : atlas brouillon **4×32×3** dans Surface Studio → mapping standard → boutons Lot **78** / **79** → préparation sauvegarde catalogue → **`saveProjectManifest()`** → relecture **`project.json`** avec **`ProjectManifest.fromJson`**, catalogue Surface cohérent (atlas, 4 animations, 1 preset, refs valides, frames colonne/ligne/durée). Complément **test pur 23×32** pour la volumétrie réelle (20 animations + preset 20 refs) sans PNG 736×1024.

## Périmètre

- **Lot 80 uniquement** : `packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart` + ce rapport.  
- **Aucun** fichier production modifié pour le Lot 80.

## Passes Composer 2

1. Gate 0 + worktree  
2. Audit chaîne Lots 70–79 (callbacks shell / `EditorCanvasHost` / générateurs)  
3. Scénario : UI légère 4×3 + logique 23×32  
4. Helpers : réutilisation `pumpEditorShellPage`, `ValueKey` existants  
5. Tests `golden_slice_test.dart`  
6. Vérification `project.json` via `File.readAsStringSync` + `fromJson`  
7. Suites ciblées + `test/surface_studio` + `map_core` read model  
8. `flutter analyze`  
9. Auto-review  

## Gate 0 — Status initial avant modification

*(Début Lot 80 — worktree **non vide** : fichiers Lot 79 non commités.)*

```text
pwd: /Users/karim/Project/pokemonProject
branche: codex/psdk-fight-next-move-wave
status: M atlas_authoring_prep, panel, atlas_authoring_prep_test
        ?? preset_creation_section, preset_generator, preset_generator_test, rapport Lot 79
diff --stat (tracked): 3 fichiers, +44 lignes (héritage Lot 79)
```

**Changements préexistants (Lot 79)** : preset Surface + wiring + tests preset + rapport `surface_engine_lot_79_…`.  
**Changements du Lot 80** : `surface_studio_vertical_atlas_golden_slice_test.md` (ce rapport) + `surface_studio_vertical_atlas_golden_slice_test.dart`.

## Analyze baseline

```bash
cd packages/map_editor && flutter analyze lib/src/features/surface_studio test/surface_studio
```

**Final** : `No issues found!`

## Audit initial

- Shell : `SurfaceStudioPanelFromManifest` + `saveProjectManifest` / `applyInMemoryProjectManifest` (Lot 53–65).  
- Génération : `buildSurfaceStudioVerticalAtlasAnimationGenerationPlan`, `surfaceStudioCollectNewAnimationsFromReadyPlan`, `surfaceStudioBuildVerticalAtlasPreset`, ids `eau-*-loop`, preset `eau-surface-preset`.

## Scénario golden slice retenu

| Question | Réponse |
|----------|---------|
| Full UI unique ou split ? | **Split** : (A) **UI** 4×3 + disque ; (B) **pur Dart** 23×32 sans image. |
| Pourquoi ? | Le 23×32 complet en widget test imposerait scroll/async image lourd ; la combinaison couvre **volumétrie** + **flux réel UI + save**. |
| Taille atlas UI | **4 colonnes × 3 lignes**, tuiles **32×32**, id `eau`, tileset non vide `t` (même pattern Lot 65). |
| Rôles mappés | **Suggestion standard** sur 4 colonnes → `isolated`, `endNorth`, `endEast`, `endSouth`. |
| Animations créées | `eau-plein-loop`, `eau-bord-haut-loop`, `eau-bord-droit-loop`, `eau-bord-bas-loop` (4). |
| Preset | `eau-surface-preset` avec 4 refs alignées sur ces ids. |
| Vérification `project.json` | `File` → `jsonDecode` → `ProjectManifest.fromJson` puis assertions sur listes + frames + refs. |

## Implémentation

- Fichier unique `surface_studio_vertical_atlas_golden_slice_test.dart` : deux tests dans un `group`.

## Fichiers créés

- `packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart`  
- `reports/surface/surface_engine_lot_80_vertical_atlas_golden_slice.md`  

## Fichiers modifiés

- Aucun (Lot 80 test-only).

## Fichiers supprimés

- Aucun.

## Tests lancés

```bash
cd packages/map_editor && flutter test test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart
```

```text
00:04 +2: All tests passed!
```

```bash
cd packages/map_editor && flutter test test/surface_studio
```

Ligne finale :

```text
00:17 +387: All tests passed!
```

```bash
cd packages/map_core && dart test test/surface_studio_read_model_test.dart
```

→ `All tests passed!`

## Analyse lancée

Idem baseline → **`No issues found!`**

## Résultats

Critères Lot 80 : **satisfaits** (golden slice + disque + test 23×32 logique, pas de `map_core`, pas d’écriture `project.json` ad hoc hors `saveProjectManifest`).

## Evidence Pack

### Status final (après Lot 80)

Inclut toujours les fichiers **Lot 79** non suivis + nouveau test + ce rapport :

```text
?? .../surface_studio_vertical_atlas_golden_slice_test.dart
?? reports/surface/surface_engine_lot_80_vertical_atlas_golden_slice.md
(+ état Lot 79 inchangé côté liste de fichiers)
```

### Fichiers temporaires

```bash
find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
```

→ aucune sortie significative sur l’échantillon.

## Changements préexistants

- Lot 79 (preset + UI + tests + rapport 79) — **non** introduits par le Lot 80.

## Changements du Lot 80

- Test golden slice + rapport 80 uniquement.

## Périmètre explicitement non touché

- `map_core`, runtime, gameplay, battle, `ProjectManifest` sources, save flow **code**, `Runner.xcscheme`, `build_runner`.

## Vérification mojibake

- Chaînes de test / commentaires UTF-8 corrects.

## Auto-review

| Question | Réponse |
|----------|---------|
| Golden slice prouve atlas + animations + preset ? | **Oui** (UI 4×3) |
| `project.json` relu et vérifié ? | **Oui** |
| Save flow officiel ? | **Oui** (`editorNotifier.saveProjectManifest`) |
| Écriture ad hoc `project.json` ? | **Non** (seul le repo fichier minimal initial + save) |
| Animations référencées existent ? | **Oui** |
| Frames column/row correctes ? | **Oui** |
| `durationMs` conservé ? | **Oui** (120) |
| `map_core` modifié ? | **Non** |
| Analyze clean ? | **Oui** |
| Régressions create/edit/… ? | **Non** (suite +387) |
| Fichier initial disparu ? | **Non** |
| Hors périmètre modifié ? | **Non** |
| 80-bis nécessaire ? | **Non** |

## Critique du prompt

Le prompt demandait idéalement une image ; le **split** UI léger + test logique **23×32** respecte l’intention sans fixture PNG lourde ni UI instable sur 23 colonnes.
