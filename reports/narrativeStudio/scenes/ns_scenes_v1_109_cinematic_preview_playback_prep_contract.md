# NS-SCENES-V1-109 — Cinematic Preview Playback Prep Contract

## 1. Résumé Exécutif

`NS-SCENES-V1-109` est un lot **doc-only / architecture-review / interaction-contract / design-first**. Il cadre le futur playback preview editor-only du Cinematic Builder sans l'implémenter.

Décision retenue : **Option C — Plan de playback pur dans `map_core` + état local/ticker/rendu dans `map_editor`**.

Le futur playback preview devra être déterministe, calculé depuis un read model pur, sans `Flutter`, sans `Flame`, sans `GameState`, sans mutation de `ProjectManifest`, sans mutation de `MapData`, et sans confusion avec l'exécution réelle en jeu.

Verdict :

```text
NS-SCENES-V1-109 : DONE documentaire.
Preview Playback : contrat cadré.
Playback Plan : recommandé pour V1-110.
Transport UI : reporté à un lot ultérieur.
ActorMove direct/manual path : cadrés pour playback preview futur.
Runtime / Flame / GameState : non touchés.
Aucun code produit modifié.
Aucun screenshot.
V1-110 recommandé, non démarré.
```

## 2. Gate 0

### Mission

Définir le contrat du futur playback preview editor-only du Cinematic Builder avant toute implémentation de lecture temporelle.

### Scope Autorisé

Fichiers autorisés :

- `reports/narrativeStudio/scenes/ns_scenes_v1_109_cinematic_preview_playback_prep_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_109_evidence_pack.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

### Anti-Scope Confirmé

Ce lot n'ajoute pas :

- playback fonctionnel ;
- boutons Play / Stop / Reset actifs ;
- timer ;
- ticker Flutter ;
- `AnimationController` ;
- runtime ;
- Flame ;
- `PlayableMapGame` ;
- `SceneRuntimeExecutor` ;
- `CinematicRuntimeAdapter` ;
- `GameState` ;
- `currentTimeMs` ou `isPlaying` persistants ;
- screenshot / Visual Gate ;
- V1-110.

### État Git Initial

Commandes demandées :

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

`git status --short --untracked-files=all` :

```text
Sortie : <vide>
```

`git diff --stat` :

```text
Sortie : <vide>
```

`git diff --name-only` :

```text
Sortie : <vide>
```

`git log --oneline -n 10` :

```text
3ed90377 fix: corrections tests et rapports v1.108
4670f42c update selbrume
caaa7f65 feat: cinematic manual path drawing UI et rapports v1.108
b54e1cd3 docs: ajout rapports v1.107 bis (nettoyage JSON et hardening)
ecb0d64b feat: cinematic manual path core model et tests
550e6364 docs: mise à jour roadmaps et ajout rapports v1.106
73be9440 feat: cinematic builder UX simplification et rapports
d93136a5 refactor: UI cinematic builder workspace et tests
1444a60f update selbrume
50c1bba6 update selbrume
```

## 3. Fichiers Lus

### Règles

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `codex_rules.md` : absent, sortie observée `codex_rules.md MISSING`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/verification-before-completion/SKILL.md`

### Rapports Récents

- `reports/narrativeStudio/scenes/ns_scenes_v1_108_cinematic_manual_path_drawing_ui_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_108_evidence_pack.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

### Rapports Conceptuels / Techniques

- `reports/narrativeStudio/scenes/ns_scenes_v1_40_cinematic_runtime_adapter_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_41_cinematic_builder_v0_scope_runtime_playback_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_52_cinematic_timeline_selection_cursor_playhead_placeholder_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_53_cinematic_timeline_transport_controls_placeholder_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_61_cinematic_timeline_mouse_playhead_scrub_prep_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_62_cinematic_timeline_mouse_time_probe_playhead_drag_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_67_cinematic_timeline_duration_editing_resize_prep_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_68_cinematic_timeline_duration_inspector_editing_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_69_cinematic_timeline_duration_resize_handles_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_107_cinematic_manual_path_core_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_107_bis_cinematic_manual_path_evidence_json_cleanup_hardening.md`

Tous les rapports demandés existent.

### Code Lu En Lecture Seule

- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
- `packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_manual_path_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_point_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_adapter.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `examples/playable_runtime_host` via recherches `rg "Cinematic"` / runtime keywords.

## 4. Rappel V1-108 / État Actuel

V1-108 est DONE seulement parce que V1-108-ter a régénéré et validé une Visual Gate conforme.

État actuel :

- un `actorMove` peut être `Direct` ou `Manuel` ;
- un `CinematicManualPath` contient uniquement les points de passage intermédiaires ;
- la Destination finale reste séparée dans `actorMove.targetId` et son `movementTargetBinding` ;
- la preview affiche une ligne authoring-only et des badges numérotés ;
- la timeline affiche une projection temporelle dérivée ;
- les transports restent placeholders ;
- aucun playback visuel réel n'existe.

## 5. Problème Produit

Le Cinematic Builder sait authorer et visualiser statiquement :

- décor de map ;
- acteurs statiques ;
- Repères ;
- Destinations ;
- Trajets manuels authoring-only ;
- timeline temporelle non jouée.

Il ne sait pas encore répondre à la question produit suivante :

```text
À quoi ressemble la cinématique au temps t ?
```

Le futur playback preview doit permettre à l'auteur de valider le timing, le déplacement visuel et l'ordre des blocs, sans prétendre être l'exécution runtime finale du jeu.

## 6. Définitions

### Cinematic Preview Playback

Lecture visuelle locale d'une `CinematicAsset` dans le Cinematic Builder, destinée à aider l'auteur à vérifier timing, poses et transitions. Elle n'écrit rien dans le projet et ne déclenche pas de gameplay.

### Editor-only Playback

Playback qui vit uniquement dans l'éditeur. Il peut utiliser un ticker local côté `map_editor`, mais l'état de lecture reste volatile et non persisté.

### Runtime Cinematic Playback

Exécution en jeu, dans `map_runtime`, potentiellement couplée à `PlayableMapGame`, `GameState`, caméra runtime, acteurs runtime et audio runtime. Hors scope V1-109/V1-110.

### Timeline Selection Cursor

Repère dérivé du bloc sélectionné par l'auteur. Il sert à inspecter et éditer un bloc. Il n'est pas un temps courant de lecture.

### Mouse Time Probe

Repère local d'inspection temporelle placé par la souris. Il sert à lire une position temporelle ou un snap d'analyse. Il ne doit pas devenir implicitement le playhead de playback.

### Playback Playhead

Temps courant d'une lecture preview. Il est local, editor-only, clampé entre 0 et `totalDurationMs`, et calculé en millisecondes.

### Scrubbing

Action de déplacer explicitement le `Playback Playhead` à un temps donné. À reporter après V1-111 si nécessaire ; ne pas fusionner avec le Mouse Time Probe en V0.

### Playback Plan

Read model pur, déterministe, produit depuis une `CinematicAsset`, qui décrit les items temporels, tracks d'acteurs, états caméra/fade, capabilities et diagnostics.

### Playback Frame

État évalué au temps `t` depuis un `Playback Plan` : steps actifs, poses d'acteurs, état caméra, état fade, diagnostics visibles.

### Actor Playback Pose

Position/facing/source d'un acteur au temps `t`, avec indication si la pose est interpolée ou héritée.

### Camera Playback Pose

Intention de cadrage cinématique au temps `t`. À distinguer du viewport d'édition actuel.

### Fade Playback State

État d'opacité local au temps `t`, calculé depuis un bloc `fade` et sa durée, sans mutation UI globale ni runtime.

### Preview Capability

Capacité déclarée par le plan pour dire ce que le preview sait rendre : actors, actorMove direct, manual path, actorFace, wait, fade, camera placeholder, unsupported steps.

### Unsupported Step

Bloc présent dans la timeline mais non rendu par le preview V0. Il doit produire un diagnostic no-code et ne doit pas être silencieusement ignoré si cela peut tromper l'auteur.

## 7. Options Comparées

### Option A — Brancher PlayableMapGame / Flame Dans Le Builder

Avantages :

- fidélité runtime potentielle ;
- réutilisation de certains systèmes visuels existants.

Inconvénients :

- dépendance Flame dans une surface d'authoring ;
- risque d'effets de bord `GameState` ;
- couplage fort à `PlayableMapGame` ;
- difficulté à préserver la séparation preview editor-only / runtime ;
- trop tôt pour V0.

Verdict : refusée en V0.

### Option B — Simulateur Local Dans `map_editor` Seulement

Avantages :

- rapide à prototyper ;
- proche du rendu existant du Builder ;
- pas de runtime.

Inconvénients :

- logique métier cachée dans des widgets ;
- tests plus fragiles ;
- divergence probable avec un futur runtime visuel ;
- risque de confondre sélection, probe et playhead.

Verdict : refusée comme architecture principale.

### Option C — Plan Pur Dans `map_core` + État/Ticker/Rendu Dans `map_editor`

Avantages :

- read model pur et testable ;
- `map_core` reste sans Flutter/Flame ;
- `map_editor` ne porte que l'état local de lecture et le rendu ;
- prépare un runtime futur sans le brancher ;
- cohérent avec `CinematicTimelineTimeLayoutReadModel`.

Inconvénients :

- nécessite un lot core dédié avant l'UI active ;
- impose de formaliser diagnostics/capabilities dès le début.

Verdict : retenue.

### Option D — Réutiliser SceneRuntimeExecutor / CinematicRuntimeAdapter

Avantages :

- réutilisation tentante du chemin Scene -> Cinematic ;
- cohérence possible avec certains IDs runtime.

Inconvénients :

- `SceneRuntimeExecutor` est un flux de runtime narratif, pas un simulateur visuel editor-only ;
- `SceneCinematicRuntimeNoVisualPlayer` attend une durée puis retourne `completed`, sans frame visuelle ;
- risque de side effects et de confusion Scene/Cinematic ;
- inadapté au Builder.

Verdict : refusée pour preview editor-only.

### Option E — Ne Rien Faire

Avantages :

- simplicité maximale ;
- aucun risque technique immédiat.

Inconvénients :

- Cinematic Builder incomplet ;
- l'auteur ne peut pas valider timing et movement ;
- ne répond pas au besoin produit.

Verdict : refusée comme trajectoire.

### Option F — Activer Directement Play/ActorMove Dans Le Widget

Avantages :

- gratification rapide ;
- démo possible rapidement.

Inconvénients :

- dette immédiate ;
- tests fragiles ;
- logique temporelle dispersée ;
- confusion probe/playhead/selection probable.

Verdict : refusée.

## 8. Décision Retenue

La trajectoire recommandée est :

```text
V1-110 — Cinematic Preview Playback Plan Read Model V0
V1-111 — Cinematic Preview Playback Transport UI V0
V1-112 — Cinematic ActorMove Preview Playback V0
```

V1-110 doit créer le plan pur et les diagnostics. V1-111 doit rendre les contrôles actifs côté éditeur, mais uniquement avec l'état local et un rendu minimal. V1-112 doit brancher les poses interpolées d'acteurs dans la preview.

## 9. Contrat Playback Plan

Modèle conceptuel recommandé pour V1-110 :

```text
CinematicPreviewPlaybackPlan
- cinematicId
- totalDurationMs
- timelineItems
- actorTracks
- cameraTrack
- fadeTrack
- diagnostics
- capabilities

CinematicPreviewPlaybackTimelineItem
- stepId
- stepIndex
- kind
- label
- startMs
- endMs
- durationMs
- visualDurationMs
- durationSource
- supported
- diagnostics

CinematicPreviewPlaybackFrame
- timeMs
- activeStepIds
- actorPoses
- cameraPose?
- fadeState?
- visibleDiagnostics

CinematicActorPlaybackPose
- actorId
- actorLabel
- x
- y
- facing
- source
- isInterpolated
- activeStepId?
```

Règles :

- `map_core` produit le plan et les frames.
- `map_core` n'importe ni Flutter, ni `dart:ui`, ni Flame.
- `map_editor` contrôle seulement `playbackTimeMs`, `isPlaying` local, ticker local futur et rendu.
- Aucun champ de temps de playback n'est persisté dans `CinematicAsset`.
- Aucun `startMs` / `endMs` n'est persisté.

## 10. Source De Vérité Temporelle

Source de vérité : la timeline dérivée depuis `CinematicTimelineStep.durationMs`.

Règles :

- `durationMs > 0` est la durée explicite.
- absence ou valeur invalide utilise le fallback visuel existant `cinematicTimelineFallbackVisualDurationMs = 300`.
- `startMs` et `endMs` restent dérivés.
- `totalDurationMs` est la somme des durées visuelles dérivées.
- le temps courant preview est local, editor-only, en millisecondes, clampé entre `0` et `totalDurationMs`.

Interdits :

- persister `playbackTimeMs` ;
- persister `isPlaying` ;
- persister `startMs` / `endMs` ;
- muter la timeline pour jouer.

## 11. Contrat `actorMove` Direct

V0 recommandé :

- départ = pose courante de l'acteur à l'entrée du step ;
- si aucune pose courante n'existe, utiliser la position initiale résolue depuis `CinematicStageContext.initialPlacements` ;
- destination = `movementTargetBinding` résolu, avec priorité aux Repères existants ;
- interpolation = linéaire editor-only entre départ et destination ;
- durée = durée dérivée du step ;
- facing = direction du segment pendant le mouvement, puis dernière direction à la fin ;
- si départ/destination manquant : pas d'interpolation, pose héritée si possible, diagnostic no-code.

Limites :

- pas de pathfinding ;
- pas de collision ;
- pas de correction automatique d'obstacles ;
- pas de garantie de vérité runtime.

## 12. Contrat `actorMove` Manual Path

Le chemin de preview se construit ainsi :

```text
départ -> waypoint 1 -> waypoint 2 -> destination finale
```

Règles :

- les waypoints viennent de `CinematicManualPath.waypointStagePointIds` ;
- la destination finale reste hors manual path ;
- les waypoints manquants produisent un diagnostic ;
- la destination manquante produit un diagnostic bloquant pour ce move ;
- les doublons sont autorisés au modèle mais signalables si cela crée des segments nuls répétés.

Répartition V0 recommandée :

- durée proportionnelle à la longueur de chaque segment résolu ;
- segments de longueur zéro ignorés pour la répartition si au moins un segment a une longueur positive ;
- si toutes les longueurs sont nulles, fallback à répartition égale et diagnostic warning ;
- facing recalculé par segment.

## 13. Contrat `actorFace`

V0 recommandé :

- `actorFace` est appliqué dès le début du step ;
- il met à jour la facing pose de l'acteur jusqu'au prochain `actorFace` ou `actorMove` ;
- aucune animation de rotation en V0 ;
- durée du bloc sert au temps passé dans la timeline, pas à une interpolation de rotation.

## 14. Contrat Wait / Fade / Camera

### Wait

- aucune pose acteur ne change ;
- le temps passe ;
- les diagnostics restent visibles si déjà actifs.

### Fade

V0 recommandé :

- `fadeIn` / `fadeOut` génère un `FadePlaybackState` local ;
- l'opacité est dérivée du temps dans le step ;
- l'overlay est editor-only ;
- aucun impact sur runtime ou map data.

### Camera

V0 recommandé :

- la caméra cinématique est une intention distincte du viewport d'édition ;
- ne pas muter le pan/zoom de l'éditeur pour simuler la caméra ;
- V1-110 peut déclarer `cameraUnsupported` ou un `CameraPlaybackPose` placeholder ;
- le rendu caméra réel doit attendre un lot dédié.

## 15. Contrat Transport UI

Boutons existants : Reset, Play, Stop.

V0 futur recommandé :

- Play devient Play/Pause toggle ;
- Stop = pause + retour à 0 ms ;
- Reset = retour à 0 ms sans lancer ;
- Playhead suit la timeline via l'état local `playbackTimeMs` ;
- sélectionner un bloc pendant playback doit suspendre la lecture en V0 pour éviter la confusion avec l'inspection ;
- clic/scrub timeline actif à reporter, sauf si V1-111 le cadre explicitement en mode minimal.

## 16. Selection Cursor / Mouse Probe / Playback Playhead

Séparation obligatoire :

- Selection Cursor : bloc inspecté.
- Mouse Time Probe : repère local d'analyse temporelle.
- Playback Playhead : temps courant de lecture preview.

Décision :

- ne pas convertir le Mouse Time Probe en scrubber en V0 ;
- créer un `Playback Playhead` visuel distinct ;
- si un futur scrub existe, il doit manipuler explicitement le `Playback Playhead` ;
- le clear probe reste utile et indépendant.

## 17. Diagnostics Futurs

| Code | Condition | Severity | Message utilisateur | Bloquant | Test futur |
|---|---|---|---|---|---|
| `cinematicPreviewPlaybackUnsupportedStep` | Step non rendu par le preview V0 | warning | `Ce bloc n'est pas encore prévisualisé.` | Non | step unsupported visible |
| `cinematicPreviewPlaybackActorMissing` | Step référence un acteur absent | error | `Impossible de prévisualiser ce bloc : l'acteur est introuvable.` | Oui pour le step | actor missing |
| `cinematicPreviewPlaybackActorInitialPoseMissing` | acteur sans position de départ | error | `Cet acteur n'a pas de position de départ.` | Oui pour actor pose | initial pose missing |
| `cinematicPreviewPlaybackMoveDestinationMissing` | destination non résolue | error | `Impossible de prévisualiser ce déplacement : la destination est introuvable.` | Oui pour move | missing destination |
| `cinematicPreviewPlaybackManualPathMissing` | mode manuel sans path owned | error | `Ce déplacement manuel n'a pas de trajet à lire.` | Oui pour move | missing path |
| `cinematicPreviewPlaybackManualPathPointMissing` | waypoint introuvable | error | `Ce trajet manuel utilise un repère manquant.` | Oui pour segment | missing waypoint |
| `cinematicPreviewPlaybackZeroDurationStep` | durée visuelle nulle impossible | warning | `Ce bloc a une durée trop courte pour être prévisualisé précisément.` | Non si fallback | zero duration |
| `cinematicPreviewPlaybackTimelineEmpty` | aucun step | info | `La cinématique ne contient aucun bloc à lire.` | Oui pour playback | empty timeline |
| `cinematicPreviewPlaybackStageContextMissing` | stage context absent pour actors/map | error | `La scène n'est pas assez préparée pour prévisualiser les acteurs.` | Oui pour actor playback | missing stage |
| `cinematicPreviewPlaybackMapUnavailable` | map/backdrop indisponible | warning | `Le décor de carte n'est pas disponible pour cette prévisualisation.` | Non pour timeline | map unavailable |
| `cinematicPreviewPlaybackCameraUnsupported` | camera non rendue en V0 | warning | `La caméra de ce bloc sera cadrée dans un lot suivant.` | Non | camera unsupported |
| `cinematicPreviewPlaybackFadeUnsupported` | fade non rendu en V0 | warning | `Le fondu de ce bloc sera rendu dans un lot suivant.` | Non | fade unsupported |

Les messages UX principaux ne doivent pas exposer `targetId`, `sourceId`, `binding`, `manualPathId`, `stagePointId`, `payload` ou JSON.

## 18. Tests Futurs

### V1-110 Core

- plan vide ;
- durée totale ;
- active step at time ;
- frame clampée à 0 et total ;
- `actorFace` met à jour la facing ;
- `actorMove` direct interpolation ;
- `actorMove` manual path interpolation ;
- missing destination diagnostic ;
- missing waypoint diagnostic ;
- no persisted time ;
- deterministic frame output.

### V1-111 Editor

- Play active transport ;
- Pause stops time ;
- Stop returns to 0 ;
- Reset returns to 0 ;
- playhead moves ;
- actor overlay consumes playback frame ;
- selection/probe behavior preserved ;
- no `ProjectManifest` mutation ;
- no runtime/Flame imports.

### Visual Gate Future

- timeline avec playback playhead ;
- acteur en position interpolée ;
- transport visible actif ;
- statut playback no-code ;
- aucun label runtime.

## 19. Anti-Scope Runtime / Flame / Playback Réel

V1-109 ne modifie aucun package et ne crée aucune Visual Gate.

Le runtime existant contient `SceneCinematicRuntimeNoVisualPlayer`, qui attend une durée estimée puis retourne `completed`. Il ne doit pas servir de preview visuelle dans le Builder.

`PlayableMapGame` branche déjà un adapter runtime pour les Scene intents cinematic, mais cela reste l'exécution runtime no-visual actuelle, pas un simulateur editor-only.

## 20. Roadmap Proposée

Prochain lot recommandé :

```text
NS-SCENES-V1-110 — Cinematic Preview Playback Plan Read Model V0
```

Puis :

```text
NS-SCENES-V1-111 — Cinematic Preview Playback Transport UI V0
NS-SCENES-V1-112 — Cinematic ActorMove Preview Playback V0
```

## 21. Commandes Exécutées

Audits :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 10
sed -n '1,260p' AGENTS.md
sed -n '261,420p' AGENTS.md
sed -n '1,260p' agent_rules.md
sed -n '1,260p' codex_rule.md
if [ -f codex_rules.md ]; then sed -n '1,260p' codex_rules.md; else printf 'codex_rules.md MISSING\n'; fi
sed -n '1,220p' skills/README.md
sed -n '1,220p' skills/using-superpowers/SKILL.md
sed -n '1,240p' skills/verification-before-completion/SKILL.md
rg -n "class Cinematic|enum Cinematic|durationMs|manualPath|ManualPath|actorMove|actorFace|fade|camera|timeline|StagePoint|MovementTarget|toJson|fromJson" packages/map_core/lib/src/models/cinematic_asset.dart packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart packages/map_core/lib/map_core.dart
rg -n "Cinematic|playback|Playback|SceneRuntimeExecutor|CinematicRuntimeAdapter|Flame|GameState|PlayableMapGame|AnimationController|Ticker|Timer|Future.delayed" packages/map_runtime examples/playable_runtime_host
rg -n "Selection|selectedStepId|mouse|probe|playhead|Reset|Play|Stop|transport|duration|AnimationController|Ticker|Timer|Future.delayed|CinematicManualPathPreviewOverlay|ManualPath|actorMove|actorFace" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_manual_path_preview_overlay.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_point_preview_overlay.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
```

Validation finale à exécuter après rédaction :

```bash
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff --name-only -- packages/map_core packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host
git diff --name-only -- examples/playable_runtime_host/macos/Runner.xcodeproj/project.pbxproj packages/map_editor/macos/Runner.xcodeproj/project.pbxproj
```

## 22. Git Final

```bash
git diff --check
```

Sortie :

```text
Sortie : <vide>
```

```bash
git diff --stat
```

Sortie :

```text
 .../scenes/road_map_scene_builder_authoring.md       | 17 +++++++++++++++--
 reports/narrativeStudio/scenes/road_map_scenes.md    | 20 +++++++++++++++++---
 2 files changed, 32 insertions(+), 5 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers non suivis ; les deux rapports V1-109 créés apparaissent dans `git status --short --untracked-files=all`.

```bash
git diff --name-only
```

Sortie :

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_109_cinematic_preview_playback_prep_contract.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_109_evidence_pack.md
```

```bash
git diff --name-only -- packages/map_core packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host
```

Sortie :

```text
Sortie : <vide>
```

```bash
git diff --name-only -- examples/playable_runtime_host/macos/Runner.xcodeproj/project.pbxproj packages/map_editor/macos/Runner.xcodeproj/project.pbxproj
```

Sortie :

```text
Sortie : <vide>
```

```bash
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_109*' -print
```

Sortie :

```text
Sortie : <vide>
```

## 23. Risques Restants

- Le plan pur en `map_core` devra éviter de dupliquer trop de logique déjà présente dans `CinematicActorDisplayPreviewModel`.
- Les capabilities doivent rester honnêtes : preview partiel ne signifie pas runtime supporté.
- Le contrat caméra est volontairement prudent, car viewport d'édition et caméra cinématique sont deux concepts différents.
- Le découpage V1-110/V1-111/V1-112 est fin, mais adapté pour éviter un gros lot qui mélangerait modèle, ticker et rendu d'acteur.

## 24. Auto-Critique

Bien tranché :

- source de vérité temporelle ;
- séparation Selection Cursor / Mouse Probe / Playback Playhead ;
- refus de Flame/runtime dans le Builder ;
- choix du plan pur en `map_core`.

Reporté volontairement :

- ticker et transport actifs ;
- rendu caméra réel ;
- fade overlay réel ;
- scrubber actif ;
- actor animation runtime.

Le plan pur en `map_core` semble être le bon choix, car le repo a déjà des read models temporels purs et des résolveurs d'acteurs statiques purs. Un bis documentaire n'est pas recommandé sauf si V1-110 révèle une contradiction dans les diagnostics ou les capabilities.

## 25. Verdict Final

`NS-SCENES-V1-109 : DONE documentaire.`

Le playback preview est cadré sans implémentation. Le futur `Playback Plan` pur est recommandé pour V1-110. Aucun code produit, runtime, Flame, GameState, screenshot ou V1-110 n'a été ajouté.

## 26. Prochain Lot Recommandé

```text
NS-SCENES-V1-110 — Cinematic Preview Playback Plan Read Model V0
```
