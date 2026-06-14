# NS-SCENES-V1-130 — Evidence Pack

Date : 2026-06-14  
Statut : DONE documentaire  
Lot : `NS-SCENES-V1-130 — Cinematic Camera Target / Zoom Authoring Prep Contract`

## Synthese

V1-130 est une cloture documentaire. Aucun code produit, aucun test, aucun screenshot et aucun asset n'ont ete modifies. Le lot cadre le futur modele Camera Target / Zoom et aligne les roadmaps vers :

```text
NS-SCENES-V1-131 — Cinematic Camera Target / Zoom Core Model V0
```

Decision : Option D + Option G, soit cibles `Centre de la scene / Acteur / Repere` et zooms `Plan large / Plan moyen / Gros plan`.

## Audit initial

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
 M selbrume/project.json
 selbrume/project.json | 40 +++++++++++++++++++++++++++++++++-------
 1 file changed, 33 insertions(+), 7 deletions(-)
selbrume/project.json
3edcfe36 Allow deeper cinematic timeline zoom out
6bb457a4 Polish cinematic emote dropdowns
f16314fe NS-SCENES-V1-129 — Cinematic Emote Preview Playback UI V0
6da6410f NS-SCENES-V1-128 — Cinematic Emote Block Editor UI V0
af8be4ac update selbrume
d864d502 NS-SCENES-V1-128 — Cinematic Timeline Zoom Controller V0
9e6d5c6e NS-SCENES-V1-127 — Cinematic Emote Playback State Read Model V0
bf27192e NS-SCENES-V1-126 — Cinematic Emote Core Model Asset Catalog V0
7806431f NS-SCENES-V1-125 — Cinematic Emote Assets Reaction Bubble Prep Contract V0
c5329014 NS-SCENES-V1-124 — Cinematic Camera Preview Playback UI V0
```

Interpretation : `selbrume/project.json` etait dirty avant le lot. V1-130 ne le modifie pas.

## Regles lues

```text
AGENTS.md
agent_rules.md
codex_rule.md
skills/README.md
skills/using-superpowers/SKILL.md
skills/writing-plans/SKILL.md
skills/test-driven-development/SKILL.md
skills/verification-before-completion/SKILL.md
```

`codex_rules.md` est absent du repo.

## Passes / sub-agents documentaires

- Passe A — Audit Camera existant : PASS, Camera V0 = `reset/hold`, metadata `camera.mode`, pas de geometrie.
- Passe B — Audit targets possibles : PASS, sources fiables = scene center, actor, stage point.
- Passe C — Audit zoom/framing/viewport : PASS, viewport editor local separe de camera cinematographique.
- Passe D — Comparaison options : PASS, Option D + G retenue.
- Passe E — Decision architecture : PASS, core model V1-131 recommande.
- Passe F — Contrat modele/UX/diagnostics : PASS, labels et diagnostics futurs listes.
- Passe G — Roadmaps/Evidence Pack : PASS, artefacts documentaires crees et roadmaps alignees.
- Passe H — Auto-critique : PASS avec limites documentees.

## Extraits de code audites

Camera authoring actuel :

```dart
enum CinematicTimelineCameraMode {
  reset,
  hold,
}

const cinematicTimelineCameraModeMetadataKey = 'camera.mode';
```

Camera playback state actuel :

```dart
final class CinematicCameraPlaybackPose {
  CinematicCameraPlaybackPose({
    required this.isActive,
    required this.isSupported,
    required this.progress,
    this.activeStepId,
    this.mode,
    List<CinematicPreviewPlaybackDiagnostic> diagnostics = const [],
  });
}
```

Separation viewport/camera deja explicite :

```dart
// This is preview/read-model state only: V1-123 intentionally describes the
// cinematic camera timeline without mutating editor viewport pan or zoom.
```

Viewport editor local :

```dart
enum CinematicBackdropPreviewFramingMode {
  fitMap,
  scene,
}
```

## Commandes d'audit

```bash
rg -n "enum CinematicTimelineCameraMode|cinematicTimelineCameraModeMetadataKey|CinematicCameraPlaybackPose|_cameraPoseFor|CinematicTimelineStepKind\\.camera|cameraPose|cameraMode" packages/map_core/lib/src packages/map_core/test packages/map_editor/lib/src/ui/canvas/cinematics packages/map_editor/test
```

Resultat utile : Camera V0 est limitee a `reset/hold`, `camera.mode`, `CinematicCameraPlaybackPose`, `_cameraPoseFor`, overlay symbolique et tests de modes inconnus/manquants.

```bash
rg -n "stagePoint|StagePoint|movementTargetBinding|actorInitialPlacement|targetId|stagePointId|CinematicStagePoint" packages/map_core/lib/src packages/map_core/test packages/map_editor/lib/src/ui/canvas/cinematics packages/map_editor/test
```

Resultat utile : `CinematicStagePoint`, stage context, actor initial placement, actorMove stage point targets et overlays existent deja.

```bash
rg -n "CinematicBackdropPreviewFraming|framing|zoom|Vue scene|Carte entiere|viewport|pan" packages/map_editor/lib/src/ui/canvas/cinematics reports/narrativeStudio/scenes/ns_scenes_v1_95* reports/narrativeStudio/scenes/ns_scenes_v1_122* reports/narrativeStudio/scenes/ns_scenes_v1_123* reports/narrativeStudio/scenes/ns_scenes_v1_124*
```

Resultat utile : le zoom/pan existant est un framing local editor-only et ne doit pas devenir le zoom camera cinematographique.

## Tests et analyse

Aucun test Dart/Flutter lance pour V1-130, volontairement :

- le lot interdit les modifications de packages ;
- aucun code produit n'a ete modifie ;
- aucun test n'a ete cree ou modifie ;
- la validation pertinente est documentaire + `git diff --check` + anti-scope.

## Fichiers crees/modifies

Crees :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_130_cinematic_camera_target_zoom_authoring_prep_contract.md
reports/narrativeStudio/scenes/ns_scenes_v1_130_evidence_pack.md
```

Modifies :

```text
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

## Code / contenu genere par le lot

Correction ajoutee apres relecture : V1-130 ne cree pas de code produit Dart/Flutter. Les blocs generes sont des contrats documentaires et des zones de roadmap. Ils sont listés ci-dessous pour que le rapport contienne bien le "code/contenu" produit par le lot.

### Contrat futur cree dans le rapport principal

```text
CinematicCameraTargetKind
- sceneCenter
- actor
- stagePoint

CinematicCameraZoomPreset
- wide
- medium
- close

CinematicTimelineCameraMode
- reset
- hold
- focus

CinematicCameraTargetBinding
- kind
- actorId?
- stagePointId?
- label?

CinematicTimelineCameraFocusBinding
- target
- zoomPreset
```

```text
camera.mode = reset | hold | focus
camera.targetKind = sceneCenter | actor | stagePoint
camera.targetActorId = <actor id>        // seulement si actor
camera.targetStagePointId = <point id>   // seulement si stagePoint
camera.zoomPreset = wide | medium | close
```

```text
cameraTargetMissing
cameraTargetActorMissing
cameraTargetActorWithoutPosition
cameraTargetStagePointMissing
cameraTargetStagePointOutOfMap
cameraTargetStageMapMissing
cameraZoomPresetMissing
cameraZoomPresetUnsupported
cameraModeUnsupported
cameraGeometryUnavailable
```

### Zones roadmap generees

```md
| NS-SCENES-V1-130 — Cinematic Camera Target / Zoom Authoring Prep Contract | DONE | Cadrer le futur authoring Camera Target / Zoom : cibles no-code `Centre de la scene / Acteur / Repere`, presets `Plan large / Plan moyen / Gros plan`, diagnostics futurs et separation stricte viewport editor / camera cinematographique, sans code produit. |
| NS-SCENES-V1-131 — Cinematic Camera Target / Zoom Core Model V0 | RECOMMANDÉ | Implementer le core model camera cible/zoom issu du contrat precedent avec enums, helpers metadata, operations pures et diagnostics, sans UI preview reelle, runtime, Flame, GameState, coordonnees libres ni waypoints libres. |

## Prochain lot exact recommande

`NS-SCENES-V1-131 — Cinematic Camera Target / Zoom Core Model V0`
```

````md
## Prochain lot exact recommande

```text
NS-SCENES-V1-131 — Cinematic Camera Target / Zoom Core Model V0
```

| NS-SCENES-V1-130 | Cinematic Camera Target / Zoom Authoring Prep Contract | doc-only / architecture-review | Cadrer le futur authoring Camera Target / Zoom avec cibles no-code `Centre de la scene / Acteur / Repere`, presets `Plan large / Plan moyen / Gros plan`, diagnostics futurs et separation viewport editor / camera cinematographique. | Pas de code produit, pas de package, pas de screenshot, pas de runtime, Flame, GameState, coordonnees libres ou waypoints libres. | Rapport V1-130, Evidence Pack V1-130, roadmaps. | Validation documentaire : audit read-only camera/stage/viewport/playback, `git diff --check`, anti-scope packages/screenshots. | Confondre zoom editor et zoom camera ; lancer la preview reelle trop tot ; reutiliser actorMove target comme workflow principal. | DONE : Option D + G retenue, V1-131 core model recommande, aucun code produit modifie. | V1-129 |
| NS-SCENES-V1-131 | Cinematic Camera Target / Zoom Core Model V0 | core / authoring-model | Implementer le core model camera cible/zoom retenu par V1-130 avec enums, helpers metadata, operations pures et diagnostics. | Pas d'UI preview reelle, pas de runtime, Flame, GameState, coordonnees libres, waypoints libres, `manualPathId` camera ou mutation du viewport editor. | `map_core` cinematic asset/authoring/diagnostics/tests, rapports. | Tests JSON backward-compatible, focus scene center/actor/stage point, zoom presets, diagnostics target/zoom/mode, anti-scope runtime/editor viewport. | Sur-modeliser le step Camera ; casser les blocs reset/hold historiques ; exposer des IDs techniques comme workflow principal. | Recommande, non demarre. | V1-130 |
````

## Commandes finales

### Roadmap headers

```bash
sed -n '198,204p' reports/narrativeStudio/scenes/road_map_scenes.md
sed -n '9,16p' reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

Sortie :

````text

## Prochain lot exact recommande

`NS-SCENES-V1-131 — Cinematic Camera Target / Zoom Core Model V0`

Raison : V1-130 a cadré l’enrichissement caméra cible/zoom sans code produit. Le prochain verrou produit est maintenant le core model V1-131 : types, metadata helpers, operations pures et diagnostics, avant toute UI preview reelle ou runtime.

## Prochain lot exact recommande

```text
NS-SCENES-V1-131 — Cinematic Camera Target / Zoom Core Model V0
```

Suite V1-130 : le contrat Camera Target / Zoom est cadré sans code produit. Le prochain verrou produit est le core model V1-131 : types, metadata helpers, operations pures et diagnostics pour les cibles `Centre de la scene / Acteur / Repere` et les presets `Plan large / Plan moyen / Gros plan`.
````

```bash
rg -n "V1-130 est recommandé|V1-130 est recommande|recommandé mais non démarré|recommande mais non demarre|V1-130.*recommande, non demarre|V1-130.*Recommandé, non démarré|RECOMMANDÉ.*V1-130" reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

Sortie :

```text
<vide, exit 1 rg car aucune contradiction trouvee>
```

### Git diff

```bash
git diff --check
```

Sortie :

```text
<vide>
```

```bash
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

Sortie :

```text
 .../scenes/road_map_scene_builder_authoring.md     | 59 ++++++++++++---------
 reports/narrativeStudio/scenes/road_map_scenes.md  | 60 +++++++++++++---------
 selbrume/project.json                              | 40 ++++++++++++---
 3 files changed, 106 insertions(+), 53 deletions(-)
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
selbrume/project.json
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
 M selbrume/project.json
?? reports/narrativeStudio/scenes/ns_scenes_v1_130_cinematic_camera_target_zoom_authoring_prep_contract.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_130_evidence_pack.md
```

Note : `git diff --stat` ne liste pas les deux rapports V1-130 car ils sont non suivis/non stages. Ils sont visibles dans `git status --short --untracked-files=all`.

### Anti-scope

```bash
git diff --name-only -- packages/map_core packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets pubspec.yaml
```

Sortie :

```text
<vide>
```

```bash
git diff --name-only -- packages/map_core packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume pubspec.yaml
```

Sortie :

```text
selbrume/project.json
```

Interpretation : `selbrume/project.json` etait dirty dans l'audit initial avant V1-130. Le lot V1-130 ne l'a pas modifie.

### Screenshots

```bash
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_130*' -print
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_131*' -print
```

Sortie :

```text
<vide>
<vide>
```

## Verdict final

`NS-SCENES-V1-130 — Cinematic Camera Target / Zoom Authoring Prep Contract` : DONE documentaire.

Roadmaps : alignees sur `NS-SCENES-V1-131 — Cinematic Camera Target / Zoom Core Model V0`.

Anti-scope : aucun package, example, asset ou pubspec modifie par V1-130. `selbrume/project.json` reste une modification preexistante hors lot.

V1-131 : recommande, non demarre.
