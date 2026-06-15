# NS-SCENES-V1-136 — Evidence Pack

## Gate 0

Commandes :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
```

Sorties :

```text
/Users/karim/Project/pokemonProject
main
```

`git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` n'ont imprimé aucune ligne au Gate 0.

```text
2bd11dda NS-SCENES-V1-135 — Cinematic Builder V1 Camera Closure Polish Gate
179cd6aa NS-SCENES-V1-134 — Cinematic Camera Geometry Preview UI V0
28d0e46e NS-SCENES-V1-133 — Cinematic Camera Geometry Playback State V0
d4e0b28b NS-SCENES-V1-132 — Cinematic Camera Target Zoom Editor UI V0
882c2c23 NS-SCENES-V1-131 — Cinematic Camera Target Zoom Core Model V0
a7bb9b42 update selbrume
4c3040a3 update selbrume
47660d78 NS-SCENES-V1-130 — Cinematic Camera Target Zoom Authoring Prep Contract
2344303e update selbrume
3edcfe36 Allow deeper cinematic timeline zoom out
```

## Règles lues

Fichiers lus :

```text
AGENTS.md
agent_rules.md
codex_rule.md
skills/README.md
skills/using-superpowers/SKILL.md
skills/test-driven-development/SKILL.md
skills/verification-before-completion/SKILL.md
skills/writing-plans/SKILL.md
```

Vérification `codex_rules.md` :

```bash
ls -1 codex_rule.md codex_rules.md 2>&1
```

Sortie :

```text
ls: codex_rules.md: No such file or directory
codex_rule.md
```

## Préconditions V1-135

Commandes :

```bash
ls -lh reports/narrativeStudio/scenes/ns_scenes_v1_135_cinematic_builder_v1_camera_closure_polish_gate.md reports/narrativeStudio/scenes/ns_scenes_v1_135_evidence_pack.md reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_135_cinematic_builder_v1_camera_closure_polish_gate.png
rg -n "NS-SCENES-V1-135|Cinematic Builder V1 Camera Closure|Cadrage visible dans la preview\\. La vue reste non pilotée\\.|Cadrage affiché, vue non pilotée\\.|NS-SCENES-V1-136 — Cinematic Builder V1 Closure / Readiness Audit" reports/narrativeStudio/scenes packages/map_editor/lib/src/ui/canvas/cinematics packages/map_editor/test/cinematic_builder_workspace_test.dart
```

Résultat utile :

```text
- rapport V1-135 présent ;
- Evidence Pack V1-135 présent ;
- Visual Gate V1-135 présente ;
- wording caméra final présent ;
- roadmaps recommandant V1-136 présentes.
```

## Fichiers lus

Fichiers de règles, rapports, roadmaps et zones audit :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_135_cinematic_builder_v1_camera_closure_polish_gate.md
reports/narrativeStudio/scenes/ns_scenes_v1_135_evidence_pack.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
```

## Commandes d'audit

### Inventaire tests cinématiques

Commande :

```bash
rg --files packages/map_core/test packages/map_editor/test | rg "cinematic|cinematics|scene_cinematic"
```

Sortie utile :

```text
packages/map_core/test/cinematic_actor_display_preview_model_test.dart
packages/map_core/test/cinematic_asset_test.dart
packages/map_core/test/cinematic_authoring_operations_test.dart
packages/map_core/test/cinematic_diagnostics_test.dart
packages/map_core/test/cinematic_emote_catalog_test.dart
packages/map_core/test/cinematic_map_backdrop_preview_model_test.dart
packages/map_core/test/cinematic_preview_playback_plan_test.dart
packages/map_core/test/cinematic_stage_map_source_catalog_test.dart
packages/map_core/test/cinematic_timeline_lane_read_model_test.dart
packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart
packages/map_core/test/cinematics_library_read_model_test.dart
packages/map_core/test/project_manifest_cinematics_test.dart
packages/map_core/test/scene_cinematic_authoring_test.dart
packages/map_editor/test/cinematic_actor_sprite_preview_renderer_test.dart
packages/map_editor/test/cinematic_actor_sprite_preview_resolver_test.dart
packages/map_editor/test/cinematic_actor_walking_animation_preview_resolver_test.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematic_playback_preview_fallback_summary_test.dart
packages/map_editor/test/cinematic_stage_point_preview_overlay_test.dart
packages/map_editor/test/cinematic_timeline_zoom_controller_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
packages/map_editor/test/scene_cinematic_picker_test.dart
```

### Visual Gates

Commande :

```bash
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -type f -name '*v1_*' -print | sort
```

Synthèse avec tailles et SHA-256 :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_42_cinematic_builder_v0_shell.png | PRESENT | 145K | f5af0a1f7bf91feb3bd9b541f76beacd833f7fe2bdd28820df210710904801fe
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_48_cinematic_timeline_lane_grouping_v0.png | PRESENT | 183K | 18a1ae7b81ba0192de0fc074c6275d8a585d2815d469b5dce9f64dcda85981dd
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_56_cinematic_timeline_bar_geometry_duration_scale_correction_v0.png | PRESENT | 228K | 21c3f6cc18b1008286ad15d0be7afa857f9ff5a0bdcae49ff5fa2bf69f79776f
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_84_cinematic_map_backdrop_preview_renderer_v0.png | PRESENT | 253K | c005528da38d6af1766c949749528154323ef4e5cc896919bb141631915d1e81
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_89_cinematic_map_backdrop_real_tile_renderer_integration_fidelity_polish_v0.png | PRESENT | 244K | ef160c2febfd96a9fbc8cdcfe8d2e140238bf7f12020e6c4892df5226ef1844f
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_92_cinematic_actor_display_preview_renderer_v0.png | PRESENT | 287K | 431d9555fcf0ea36c5929af660adcf7720fb1b76c0802c6ebe0feabcc14df8c3
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_94_cinematic_extended_map_backdrop_visual_gate_v0.png | PRESENT | 243K | 3cc17a0b4a9d986df0bf9b262014489185693b473501f52436c8ebde4dfa649c
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_95_cinematic_backdrop_preview_framing_zoom_controls_v0.png | PRESENT | 250K | 3a2ee1eef54a8c7a4342d137733484cd734625a71f4b90d441c0140ad1d3cff9
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_99_cinematic_actor_display_sprite_renderer_v0.png | PRESENT | 225K | 02469a67c3e8b57e63752e14a8a501135afb53ccc82a221eddfc9c0924120317
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_102_cinematic_preview_point_placement_ui_v0.png | PRESENT | 241K | 193add356cd297d384980a3d3695a229012cf43536007ad1ebb52542bde835c8
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_108_cinematic_manual_path_drawing_ui_v0.png | PRESENT | 259K | f016199226ef426bdb8a28554d0221f130b06471af7f3246113b0853230dd1fe
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_121_cinematic_fade_preview_playback_v0.png | PRESENT | 207K | e728869979d5cfdca17c5e456051b5449ded1c7045759f667097d69330fa0c8e
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_124_cinematic_camera_preview_playback_ui_v0.png | PRESENT | 212K | f32320c3bccd6047dbc88f094ca6baf336b1a903559dc85f36b3764f2937f67f
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_129_cinematic_emote_preview_playback_ui_v0.png | PRESENT | 233K | ac71b1d68b1021acdc0225a05844bf43e66985473258ebc647f3ac817acd1ac4
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_134_cinematic_camera_geometry_preview_ui_v0.png | PRESENT | 224K | 01ce3b5de7fd78aeaa549f47866523c5505c14813ccbe03a7e25acf5e3f22ee4
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_135_cinematic_builder_v1_camera_closure_polish_gate.png | PRESENT | 225K | 788b64ab4fbe297c3d461fa97b4fb1c793a6201e3b7038ae82c6af4c7dbef123
```

## Tests exécutés

### Builder complet

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

Résultat :

```text
00:54 +285 -6: Some tests failed.
```

Échecs isolés :

```text
sets a local timeline time probe from mouse interaction without changing selection
Expected: at least one matching candidate
Actual: Found 0 widgets with text "step_face"

snaps local timeline time probe to block boundaries without changing selection
Expected: at least one matching candidate
Actual: Found 0 widgets with text "step_face"

navigates selected timeline blocks vertically with local keyboard focus
Expected: at least one matching candidate
Actual: Found 0 widgets with text "step_camera"

uses step index as vertical navigation tie break
Expected: at least one matching candidate
Actual: Found 0 widgets with text "step_camera_a"

adds a safe draft after selected step and inspects it
Expected: at least one matching candidate
Actual: Found 0 widgets with text "Statut"

polishes movement target labels and actor movement inspector
Expected: exactly one matching candidate
Actual: Found 0 widgets with text "Professor marche vers Centre scène en 1000 ms."
```

Classification : MAJOR non bloquant. Les échecs ciblent des attentes de libellés/IDs legacy après les nettoyages no-code.

### Builder ciblé récent

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-135|V1-134|V1-132|V1-129|V1-128|V1-124|V1-121|V1-120|V1-118|V1-117-bis|V1-116|V1-112|V1-108|V1-105|V1-102"
```

Sortie finale :

```text
00:16 +73: All tests passed!
```

### Library complète

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematics_library_workspace_test.dart
```

Résultat :

```text
00:07 +20 -1: Some tests failed.
```

Échec isolé :

```text
adds a basic block from builder and refreshes library summary
Expected: exactly one matching candidate
Actual: Found 0 widgets with text "Bloc authoring V0"
```

Classification : MAJOR non bloquant. Attente de label ancien.

### Core cinematic élargi

Commande :

```bash
cd packages/map_core
dart test --reporter=compact test/cinematic_asset_test.dart test/cinematic_authoring_operations_test.dart test/cinematic_diagnostics_test.dart test/cinematic_preview_playback_plan_test.dart test/cinematic_timeline_lane_read_model_test.dart test/cinematic_timeline_time_layout_read_model_test.dart test/cinematic_emote_catalog_test.dart test/cinematic_actor_display_preview_model_test.dart test/cinematic_map_backdrop_preview_model_test.dart test/cinematic_stage_map_source_catalog_test.dart test/cinematics_library_read_model_test.dart test/project_manifest_cinematics_test.dart
```

Sortie finale :

```text
00:00 +262: All tests passed!
```

## Analyses

### map_editor

Commande :

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics test/cinematic_builder_workspace_test.dart
```

Résultat :

```text
Analyzing 2 items...
38 issues found. (ran in 3.7s)
```

Nature des issues : infos non fatales `prefer_const_constructors`, `prefer_const_literals_to_create_immutables`, `deprecated_member_use` sur `withOpacity`.

### map_core

Commande :

```bash
cd packages/map_core
dart analyze lib test
```

Sortie :

```text
Analyzing lib, test...
No issues found!
```

## Build

Commande :

```bash
cd packages/map_editor
flutter build macos --debug
```

Sortie finale :

```text
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## Fichiers créés

```text
reports/narrativeStudio/scenes/ns_scenes_v1_136_cinematic_builder_v1_closure_readiness_audit.md
reports/narrativeStudio/scenes/ns_scenes_v1_136_evidence_pack.md
```

Nature des fichiers créés : rapports Markdown uniquement. Aucun code produit n'a été généré par V1-136.

Contenu du rapport principal créé :

```text
# NS-SCENES-V1-136 — Cinematic Builder V1 Closure / Readiness Audit

Verdict : Cinematic Builder V1 : CLOSABLE AVEC RÉSERVES NON BLOQUANTES.

Sections :
- Résumé exécutif ;
- Verdict final ;
- Rappel du périmètre V1 ;
- Méthode d'audit ;
- Matrice de readiness ;
- Analyse par domaine ;
- Tests et validations ;
- Visual Gates ;
- Blockers / majors / minors ;
- Limites V1 assumées ;
- Backlog V2 ;
- Décision de fermeture ;
- Prochain lot recommandé ;
- Auto-critique finale ;
- Critique du prompt.
```

La matière probante du rapport principal est reproduite dans le présent Evidence Pack : verdict, matrice synthétique, tests, analyses, build, Visual Gates, risques, backlog V2 et roadmaps.

## Fichiers modifiés

```text
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

Sections modifiées attendues :

```text
NS-SCENES-V1-136 — DONE
NS-SCENES-V1-137 — RECOMMANDÉ
Prochain lot exact recommande : NS-SCENES-V1-137 — Narrative Studio Golden Slice Authoring Readiness / Selbrume Demo Content Plan
```

## Fichiers supprimés

```text
<aucun>
```

## Roadmaps modifiées

Modification prévue :

- V1-136 passe de `RECOMMANDÉ` à `DONE`.
- V1-137 devient le prochain lot recommandé.
- V1-137 est explicitement non démarré.
- Aucun V1-137 n'est implémenté.

## Anti-scope final

Commandes exécutées après écriture :

```bash
git diff --check
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume pubspec.yaml
git diff --name-only -- packages/map_core packages/map_editor/lib packages/map_editor/test
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_136*' -print
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_137*' -print
git status --short --untracked-files=all
```

Sorties :

```text
git diff --check
<vide>

git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume pubspec.yaml
<vide>

git diff --name-only -- packages/map_core packages/map_editor/lib packages/map_editor/test
<vide>

find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_136*' -print
<vide>

find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_137*' -print
<vide>

git status --short --untracked-files=all
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_136_cinematic_builder_v1_closure_readiness_audit.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_136_evidence_pack.md
```

## Auto-review indépendante

- Le lot n'ajoute aucune feature produit.
- Le verdict est argumenté par tests, build, Visual Gates et réserves.
- Les réserves ne sont pas camouflées : 6 échecs Builder complet et 1 échec Library complet sont documentés.
- Les limites V1 sont classées comme backlog V2, pas comme bugs V1.
- L'anti-scope runtime reste central.
- Les roadmaps ne démarrent pas V1-137.

## Critique du prompt

Le prompt est très large pour un lot documentaire. Il demande un audit global produit, des validations lourdes, un build, une synthèse Visual Gates et un backlog V2. Le résultat reste exploitable, mais une QA manuelle exhaustive demanderait un lot dédié.

La demande de Visual Gate V1-136 est raisonnable seulement si un mécanisme existant le permet sans code. Ici, aucune capture V1-136 n'a été créée pour respecter le caractère audit-only ; V1-135 reste la Visual Gate finale.

Le prompt a raison d'autoriser la remise en cause : fermer en `CLOSABLE` sans réserve aurait masqué les tests complets rouges. Le verdict retenu est donc volontairement plus honnête.
