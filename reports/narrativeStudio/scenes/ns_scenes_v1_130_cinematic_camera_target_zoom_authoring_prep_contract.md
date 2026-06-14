# NS-SCENES-V1-130 — Cinematic Camera Target / Zoom Authoring Prep Contract

Date : 2026-06-14  
Statut : DONE documentaire  
Prochain lot recommande : `NS-SCENES-V1-131 — Cinematic Camera Target / Zoom Core Model V0`

## Verdict

V1-130 cadre le futur authoring Camera Target / Zoom sans modifier le produit. La decision retenue est :

- cible camera no-code : `Centre de la scene`, `Acteur`, `Repere` ;
- mode camera no-code : `Reinitialiser le cadrage`, `Maintenir le cadrage`, `Cadrer une cible` ;
- zoom no-code : `Plan large`, `Plan moyen`, `Gros plan` ;
- stockage futur borne : pas de coordonnees libres, pas de waypoints libres, pas de `manualPathId` cote Camera ;
- prochain lot : V1-131 pour le core model, sans UI preview reelle ni runtime.

## Regles et audit initial

Fichiers de regles lus :

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/writing-plans/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`

Note : `codex_rules.md` n'existe pas dans le repo. Le lot est doc-only et interdit les modifications de packages ; la regle TDD est donc bornee a un audit de tests futurs et non appliquee par creation de tests.

Etat git initial :

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
 M selbrume/project.json

git diff --stat
 selbrume/project.json | 40 +++++++++++++++++++++++++++++++++-------
 1 file changed, 33 insertions(+), 7 deletions(-)

git diff --name-only
selbrume/project.json

git log --oneline -n 10
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

Le fichier `selbrume/project.json` etait deja modifie avant V1-130. Il n'a pas ete touche par ce lot.

## Passes d'audit

### Passe A — Camera existante

Le bloc Camera V0 existe deja comme basic block. Son modele est volontairement minimal :

```dart
enum CinematicTimelineCameraMode {
  reset,
  hold,
}

const cinematicTimelineCameraModeMetadataKey = 'camera.mode';
const cinematicTimelineDefaultCameraDurationMs = 500;
```

Le Builder expose aujourd'hui seulement les modes `Reset` et `Hold` :

```dart
String _cameraModeLabel(CinematicTimelineCameraMode mode) {
  return switch (mode) {
    CinematicTimelineCameraMode.reset => 'Reset',
    CinematicTimelineCameraMode.hold => 'Hold',
  };
}
```

Conclusion : aucun centre, cible, zoom, framing, follow actor ou geometrie camera n'est persiste.

### Passe B — Targets possibles

Les sources fiables deja disponibles sont :

- `CinematicStagePoint` pour les reperes spatiaux no-code ;
- `CinematicActorRef` et les actor tracks pour les acteurs requis ;
- le centre de scene derive du contexte map/stage ;
- les `movementTargets` existantes pour actorMove, mais elles ne doivent pas devenir la source camera principale.

Decision : Camera doit cibler `sceneCenter`, `actor` ou `stagePoint`. On ne reutilise pas `actorMove.targetId` comme workflow principal camera, car il melange destination de mouvement et cadrage.

### Passe C — Zoom / framing / viewport

Le viewport editor possede deja un zoom/pan local via `CinematicBackdropPreviewFramingState` :

```dart
enum CinematicBackdropPreviewFramingMode {
  fitMap,
  scene,
}

static const minZoom = 1.0;
static const maxZoom = 4.0;
static const zoomStep = 0.25;
```

Ce zoom est un outil d'edition local. Il ne doit pas etre confondu avec le futur zoom camera cinematographique. Le lot V1-130 confirme deux espaces separes :

- viewport editor : aide locale pour inspecter la map ;
- camera cinematographique : intention stockee dans la timeline et lue par preview playback.

### Passe D — Options comparees

| Option | Decision | Raison |
|---|---|---|
| A — coordonnees libres | Rejetee | Trop technique, fragile, contraire au no-code et aux interdictions du lot. |
| B — cible = movement target | Rejetee comme source principale | Confond destination actorMove et cadrage camera. |
| C — cible = stage point uniquement | Partielle | Solide mais insuffisant pour cadrer directement un acteur. |
| D — cible = scene center / actor / stage point | Retenue | Couvre les besoins auteur sans coordonnees libres. |
| E — zoom numerique libre | Rejetee | Trop technique, validation plus dure, UX moins claire. |
| F — zoom lie au viewport editor | Rejetee | Confond outil d'edition et intention cinematographique. |
| G — zoom par presets no-code | Retenue | Simple, stable, testable, compatible preview-only. |
| H — renderer/preview camera immediate | Rejetee pour V1-130 | Demarrerait le code produit et risquerait de mentir sur la geometrie. |

Decision finale : Option D + Option G.

### Passe E — Architecture recommandee

V1-131 doit introduire un core model borne, pur et backward-compatible. Types recommandes :

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

Stockage futur recommande : metadata de step Camera, afin d'eviter une migration large de `CinematicTimelineStep` dans V1-131.

```text
camera.mode = reset | hold | focus
camera.targetKind = sceneCenter | actor | stagePoint
camera.targetActorId = <actor id>        // seulement si actor
camera.targetStagePointId = <point id>   // seulement si stagePoint
camera.zoomPreset = wide | medium | close
```

Regles :

- `reset` ne requiert pas de target ;
- `hold` ne requiert pas de target ;
- `focus` requiert une target valide et un zoom preset valide ;
- `sceneCenter` ne porte aucun ID ;
- `actor` exige un acteur existant dans `requiredActors` ;
- `stagePoint` exige un repere existant dans le `stageContext` ;
- aucun target libre, aucune coordonnee libre, aucun `manualPathId`.

### Passe F — UX et diagnostics futurs

Labels utilisateur :

- `Reinitialiser le cadrage`
- `Maintenir le cadrage`
- `Cadrer une cible`
- `Centre de la scene`
- `Acteur`
- `Repere`
- `Plan large`
- `Plan moyen`
- `Gros plan`

Diagnostics futurs recommandes :

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

Wording no-code :

- `Choisissez une cible pour cadrer la camera.`
- `Cet acteur n'est plus disponible.`
- `Ce repere n'existe plus dans la scene.`
- `Ce repere est en dehors de la carte.`
- `Choisissez un type de plan.`
- `Le cadrage camera sera visible dans la preview quand la geometrie sera disponible.`

### Passe G — Tests futurs V1-131

Tests core model :

- decode ancien bloc Camera `reset` / `hold` sans target ;
- encode/decode `focus + sceneCenter + medium` ;
- encode/decode `focus + actor + close` ;
- encode/decode `focus + stagePoint + wide` ;
- rejet ou diagnostic d'un mode inconnu ;
- rejet ou diagnostic d'un zoom inconnu ;
- pas de mutation des steps non camera.

Tests authoring operations :

- ajouter Camera focus scene center ;
- ajouter Camera focus acteur ;
- ajouter Camera focus repere ;
- modifier mode sans perdre duree ;
- modifier target sans affecter actorMove ;
- reset/hold nettoient les bindings inutiles ;
- aucun `manualPathId`, aucune coordonnee libre.

Tests diagnostics :

- actor cible absent ;
- actor sans position preview exploitable ;
- repere absent ;
- repere hors map ;
- stage map manquante ;
- zoom preset manquant/inconnu ;
- mode camera inconnu.

Tests read model futurs :

- `frameAt(timeMs).cameraPose` expose le binding focus ;
- seek/scrub restent deterministes ;
- fade/emote/actorMove coexistent avec cameraPose ;
- le zoom preset ne change pas les durees timeline.

## Non-objectifs respectes

Non demarre :

- V1-131 ;
- code Dart/Flutter ;
- runtime ;
- Flame ;
- GameState ;
- playback camera reel ;
- interpolation ;
- pathfinding ;
- collision ;
- UI d'authoring ;
- Visual Gate ;
- screenshot ;
- emotes ;
- modifications Selbrume.

## Fichiers modifies

Crees :

- `reports/narrativeStudio/scenes/ns_scenes_v1_130_cinematic_camera_target_zoom_authoring_prep_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_130_evidence_pack.md`

Modifies :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Aucun fichier sous `packages/`, `examples/`, `assets/`, `selbrume/` ou `pubspec.yaml` n'a ete modifie par V1-130.

## Code / contenu genere par V1-130

Erratum ajoute apres relecture : V1-130 est un lot documentaire strict. Il n'a donc genere aucun code produit Dart/Flutter. Le "code" cree par ce lot correspond aux contrats et blocs Markdown ci-dessous, qui doivent etre consommes par V1-131 sans demarrer V1-131 ici.

### Contrat type futur

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

### Contrat metadata futur

```text
camera.mode = reset | hold | focus
camera.targetKind = sceneCenter | actor | stagePoint
camera.targetActorId = <actor id>        // seulement si actor
camera.targetStagePointId = <point id>   // seulement si stagePoint
camera.zoomPreset = wide | medium | close
```

### Contrat diagnostics futur

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

### Zones roadmap ajoutees/modifiees

`reports/narrativeStudio/scenes/road_map_scenes.md` :

```md
| NS-SCENES-V1-130 — Cinematic Camera Target / Zoom Authoring Prep Contract | DONE | Cadrer le futur authoring Camera Target / Zoom : cibles no-code `Centre de la scene / Acteur / Repere`, presets `Plan large / Plan moyen / Gros plan`, diagnostics futurs et separation stricte viewport editor / camera cinematographique, sans code produit. |
| NS-SCENES-V1-131 — Cinematic Camera Target / Zoom Core Model V0 | RECOMMANDÉ | Implementer le core model camera cible/zoom issu du contrat precedent avec enums, helpers metadata, operations pures et diagnostics, sans UI preview reelle, runtime, Flame, GameState, coordonnees libres ni waypoints libres. |

## Prochain lot exact recommande

`NS-SCENES-V1-131 — Cinematic Camera Target / Zoom Core Model V0`
```

`reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md` :

````md
## Prochain lot exact recommande

```text
NS-SCENES-V1-131 — Cinematic Camera Target / Zoom Core Model V0
```

| NS-SCENES-V1-130 | Cinematic Camera Target / Zoom Authoring Prep Contract | doc-only / architecture-review | Cadrer le futur authoring Camera Target / Zoom avec cibles no-code `Centre de la scene / Acteur / Repere`, presets `Plan large / Plan moyen / Gros plan`, diagnostics futurs et separation viewport editor / camera cinematographique. | Pas de code produit, pas de package, pas de screenshot, pas de runtime, Flame, GameState, coordonnees libres ou waypoints libres. | Rapport V1-130, Evidence Pack V1-130, roadmaps. | Validation documentaire : audit read-only camera/stage/viewport/playback, `git diff --check`, anti-scope packages/screenshots. | Confondre zoom editor et zoom camera ; lancer la preview reelle trop tot ; reutiliser actorMove target comme workflow principal. | DONE : Option D + G retenue, V1-131 core model recommande, aucun code produit modifie. | V1-129 |
| NS-SCENES-V1-131 | Cinematic Camera Target / Zoom Core Model V0 | core / authoring-model | Implementer le core model camera cible/zoom retenu par V1-130 avec enums, helpers metadata, operations pures et diagnostics. | Pas d'UI preview reelle, pas de runtime, Flame, GameState, coordonnees libres, waypoints libres, `manualPathId` camera ou mutation du viewport editor. | `map_core` cinematic asset/authoring/diagnostics/tests, rapports. | Tests JSON backward-compatible, focus scene center/actor/stage point, zoom presets, diagnostics target/zoom/mode, anti-scope runtime/editor viewport. | Sur-modeliser le step Camera ; casser les blocs reset/hold historiques ; exposer des IDs techniques comme workflow principal. | Recommande, non demarre. | V1-130 |
````

## Limites restantes

- Le contrat choisit un stockage metadata minimal pour V1-131 ; si le code existant montre une pression forte vers un champ typé dans `CinematicTimelineStep`, V1-131 devra le justifier explicitement.
- Les presets `wide/medium/close` ne definissent pas encore de valeur numerique de zoom. V1-131 doit rester core/authoring ; la traduction visuelle peut attendre le lot renderer/preview suivant.
- `actorTargetWithoutPosition` dependra de la disponibilite du read model actor display/playback au moment de la validation.
- L'ancien overlay camera reste symbolique jusqu'au futur lot de preview camera reelle.

## Auto-critique finale

Le contrat privilegie une solution simple et no-code. Le risque principal est de trop repousser la geometrie effective : V1-131 doit donc rester petit mais concret, avec enums, metadata helpers, diagnostics et operations pures. Le second risque est de laisser cohabiter trop longtemps des labels `Reset/Hold` anglophones dans l'UI ; le lot UI suivant devra basculer vers les labels francais proposes ici.

Verdict : `NS-SCENES-V1-130 — Cinematic Camera Target / Zoom Authoring Prep Contract` est DONE documentaire.

Suite : `NS-SCENES-V1-131 — Cinematic Camera Target / Zoom Core Model V0` est recommande, non demarre.
