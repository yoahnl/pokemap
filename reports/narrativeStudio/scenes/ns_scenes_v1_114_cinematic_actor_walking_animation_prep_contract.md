# NS-SCENES-V1-114 — Cinematic Actor Walking Animation Prep Contract

## 1. Résumé exécutif

V1-114 est un lot documentaire. Il cadre le futur système d'animation de marche preview-only pour les acteurs du Cinematic Builder, sans modifier de code produit, sans screenshot et sans Visual Gate.

Verdict architectural : recommander une trajectoire prudente en deux lots :

```text
V1-115 — Cinematic Actor Walking Animation Frame Resolver V0
V1-116 — Cinematic Actor Walking Animation Renderer Integration V0
```

Décision V0 : `Option B + F`, c'est-à-dire un resolver editor-only séparé, time-based, consommant `CinematicPreviewPlaybackFrame.actorPoses`, `playbackTimeMs`, le plan sprite/Character Library existant et les métadonnées actorMove. Ce resolver doit choisir une frame symbolique `idle | walk | run | fallback`, sans recalculer la route, sans importer Flame/runtime/GameState et sans charger d'image.

V1-115 est recommandé comme lot suivant exact, non démarré.

## 2. Gate 0

Commande :

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
<vide>
<vide>
<vide>
2dff3a1e feat: cinematic actor playback smooth motion v1.113
d41f7f22 feat: cinematic actor move preview playback v1.112
e41f5874 update selbrume
e9972298 Add cinematic preview transport UI
3411ae0b feat: cinematic preview playback plan read model v1.110
8cf3b6f6 docs: préparation contrat preview/playback cinematic v1.109
3ed90377 fix: corrections tests et rapports v1.108
4670f42c update selbrume
caaa7f65 feat: cinematic manual path drawing UI et rapports v1.108
b54e1cd3 docs: ajout rapports v1.107 bis (nettoyage JSON et hardening)
```

## 3. Fichiers lus

Règles :

```text
AGENTS.md : présent
agent_rules.md : présent
codex_rule.md : présent
codex_rules.md : absent
```

Rapports récents :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_110_cinematic_preview_playback_plan_read_model_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_110_evidence_pack.md
reports/narrativeStudio/scenes/ns_scenes_v1_111_cinematic_preview_playback_transport_ui_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_111_evidence_pack.md
reports/narrativeStudio/scenes/ns_scenes_v1_112_cinematic_actormove_preview_playback_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_112_evidence_pack.md
reports/narrativeStudio/scenes/ns_scenes_v1_113_cinematic_actor_playback_smooth_motion_subtile_overlay_polish_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_113_evidence_pack.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

Rapports sprites / acteurs :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_90_cinematic_actor_display_preview_prep_contract.md
reports/narrativeStudio/scenes/ns_scenes_v1_91_cinematic_actor_display_preview_read_model_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_92_cinematic_actor_display_preview_renderer_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_97_cinematic_actor_display_preview_sprite_resolver_prep_contract.md
reports/narrativeStudio/scenes/ns_scenes_v1_98_cinematic_actor_display_preview_sprite_resolver_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_99_cinematic_actor_display_preview_sprite_renderer_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_99_bis_cinematic_actor_sprite_real_asset_fidelity_visual_gate_polish_v0.md
```

Code et tests lus en lecture seule :

```text
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart
packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart
packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart
packages/map_core/lib/src/models/cinematic_asset.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/enums.dart
packages/map_core/lib/map_core.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_plan.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_resolver.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_renderer.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/lib/src/ui/panels/character_library_panel.dart
packages/map_core/test/cinematic_preview_playback_plan_test.dart
packages/map_core/test/cinematic_actor_display_preview_model_test.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematic_actor_sprite_preview_renderer_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
```

## 4. Rappel V1-110 à V1-113

V1-110 : `map_core` fournit `CinematicPreviewPlaybackPlan` et `CinematicPreviewPlaybackFrame.actorPoses`.

V1-111 : `map_editor` ajoute Play/Pause/Stop/Reset editor-only, sans runtime.

V1-112 : la preview consomme `actorPoses` pour déplacer les acteurs, mais encore par projection entière.

V1-113 : la preview conserve les positions sub-tile `double` dans un override editor-only, sans `round()/toInt()` sur le rendu playback.

État produit actuel : le mouvement est fluide, mais le sprite/placeholder glisse sans cycle de marche.

## 5. Problème produit

Le Cinematic Builder commence à ressembler à une vraie prévisualisation temporelle, mais un acteur qui se déplace avec une frame idle statique donne une impression d'autocollant glissé sur la carte.

Le futur système doit donc choisir une frame visuelle de marche quand l'acteur est en mouvement, tout en gardant la distinction stricte :

```text
Movement interpolation = position calculée par V1-110/V1-113.
Walking animation = choix visuel d'une frame sprite pendant le mouvement.
Runtime animation = exécution en jeu, hors scope.
```

## 6. Définitions

Walking Animation Preview : sélection editor-only d'une frame visuelle de marche pendant le playback preview.

Idle Frame : frame statique issue d'une animation `CharacterAnimationState.idle`.

Walk Cycle : suite ordonnée de frames `CharacterAnimationState.walk` répétée pendant le mouvement.

Directional Animation : animation attachée à une direction `EntityFacing.north/south/east/west`.

Animation Frame : `CharacterAnimationFrame`, composée d'un `TilesetSourceRect source` et d'un `durationMs`.

Frame Cadence : règle qui choisit l'index de frame à un instant de playback.

Distance-based Step Cadence : cadence dérivée de la distance parcourue. Plus naturelle mais non recommandée pour V0 car le plan actuel n'expose pas encore une progression de route prête à consommer.

Time-based Frame Cadence : cadence dérivée de `playbackTimeMs` ou d'un temps local de step. Recommandée pour V0.

Playback Actor Pose : `CinematicActorPlaybackPose` avec `actorId`, `x/y`, `facing`, `source`, `isInterpolated` et `activeStepId`.

Actor Motion State : état dérivé `moving | stationary | fallback`, jamais persisté.

Moving / Stationary : moving si l'acteur a une pose interpolée exploitable pendant un `actorMove`; stationary sinon.

Sprite Animation Source : `ProjectCharacterEntry.animations`, avec `state`, `direction` et `frames`.

Fallback Placeholder : rendu existant utilisé quand le sprite ou la frame d'animation n'est pas exploitable.

Preview-only Animation : logique du Cinematic Builder, limitée à `map_editor`, sans gameplay ni runtime.

Runtime Animation : animation du jeu réel. Hors scope et non réutilisée directement ici.

## 7. Audit sprite / Character Library / renderer actuel

Contrat Character Library :

```text
ProjectCharacterEntry(id, name, tilesetId, frameWidth, frameHeight, animations)
CharacterAnimation(state, direction, frames)
CharacterAnimationFrame(source, durationMs = 150)
CharacterAnimationState = idle | walk | run
EntityFacing = north | south | east | west
```

Audit :

```text
- les personnages peuvent déjà porter des animations walk/run ;
- les animations sont directionnelles via EntityFacing ;
- les frames sont ordonnées par leur liste ;
- la cadence existe par frame via durationMs ;
- la Character Library UI affiche Idle / Walk / Run par direction ;
- le resolver actor sprite actuel filtre seulement CharacterAnimationState.idle ;
- le renderer actuel dessine une seule CinematicActorSpriteRef ;
- l'overlay vérifie les source rects hors atlas et retombe sur placeholder ;
- le renderer n'a pas de notion de frameIndex animé.
```

Preuve notable :

```text
cinematic_actor_sprite_preview_resolver.dart filtre actuellement :
resolvedCharacter.animations.where((anim) => anim.state == CharacterAnimationState.idle)
```

Conclusion : le modèle de données est prêt pour walk/run, mais le plan de rendu actuel est volontairement statique.

## 8. Options comparées

Option A — Animation directement dans l'overlay UI.

```text
Avantages : rapide, localisé, peu de nouveaux fichiers.
Risques : met la logique moving/facing/cadence dans un widget, rend les tests fragiles, duplique les règles du resolver sprite.
Verdict : refusée comme architecture principale. Acceptable seulement comme glue d'affichage très mince après resolver.
```

Option B — Resolver editor-only séparé pour les frames de marche.

```text
Avantages : séparation claire, pas de map_core obligatoire, testable, compatible avec CinematicActorSpritePreviewPlan, sans runtime.
Risques : nécessite un petit modèle symbolique de frame et une étape d'intégration renderer.
Verdict : retenue.
```

Option C — Étendre map_core avec un plan d'animation.

```text
Avantages : pur et testable.
Risques : map_core devrait connaître les détails sprite/Character Library de rendu preview ; prématuré pour V0.
Verdict : éviter en V0. À reconsidérer seulement si la cadence distance-based exige une donnée pure exposée par le playback plan.
```

Option D — Reprendre le système runtime/Flame d'animation.

```text
Avantages : fidélité potentielle au jeu final.
Risques : fuite runtime, GameState, Flame, lifecycle, assets et collisions ; anti-scope massif.
Verdict : refusée.
```

Option E — Pas d'animation, garder le glissement.

```text
Avantages : zéro risque technique.
Risques : insuffisant pour un Cinematic Builder crédible.
Verdict : refusée comme trajectoire produit, gardée seulement comme fallback.
```

Option F — Animation time-based simple.

```text
Avantages : simple, robuste, compatible pause/stop, ne demande pas de recalcul de route.
Risques : cadence moins naturelle pour mouvements très lents/rapides.
Verdict : retenue pour V0 avec cadence par frame metadata si disponible.
```

Option G — Animation distance-based.

```text
Avantages : plus naturelle.
Risques : exige distance/progression propre ou previous/current pose ; peut encourager à recalculer le chemin dans l'UI.
Verdict : reporter. Possible futur si le playback plan expose une progression de mouvement explicite.
```

## 9. Décision retenue

Décision : `Option B + F`, split prudent.

V1-115 doit créer un resolver editor-only de frame de marche, sans widget, sans `ui.Image`, sans `BuildContext` et sans runtime.

V1-116 doit intégrer ce plan dans le renderer/overlay existant.

Raison du split : le resolver actuel est idle-only et le renderer actuel consomme une seule `CinematicActorSpriteRef`. Mélanger choix de frame, cadence, fallback, diagnostics et intégration visuelle dans un seul lot augmenterait le risque de casser les fallbacks sprites V1-99.

## 10. Détection moving/stationary

Recommandation V0 :

```text
moving si actorPose.isInterpolated == true
et actorPose.hasPosition == true
et actorPose.activeStepId != null
```

Fallback de robustesse :

```text
si previousPose/currentPose sont fournis plus tard, moving si delta position > epsilon.
epsilon recommandé : 0.001 tuile.
```

Comportements :

```text
Pause : la frame reste figée, pas d'avancement de cadence.
Stop/Reset : retour idle frame.
Segment zéro : stationary, même si actorMove est actif.
actorMove destination manquante : stationary + fallback diagnostic.
actorFace : stationary, direction mise à jour.
wait : stationary.
```

`actorPose.isInterpolated` est suffisant pour V0, mais il ne distingue pas encore walk/run. Le resolver V1-115 devra lire `actor.movementMode` depuis le step actif ou une table dérivée depuis le plan/timeline editor.

## 11. Direction/facing

Règles :

```text
- utiliser actorPose.facing si différent de unknown ;
- sinon conserver actor.direction du display model ;
- mapper CinematicActorPreviewDirection vers EntityFacing ;
- chercher l'animation directionnelle correspondante ;
- si la direction manque, fallback sur une animation même state disponible ;
- si tout manque, fallback idle ou placeholder.
```

Vocabulaire utilisateur : garder les labels no-code existants, ne pas exposer `EntityFacing`, `sourceRect` ou `animationKey`.

## 12. Source des sprites/animations

Sources autorisées :

```text
ProjectCharacterEntry
Character Library
frameWidth / frameHeight
tileset / atlas
animations idle/walk/run
directional frames
CinematicActorSpritePreviewPlan
CinematicActorDisplayPreview renderer
```

Questions tranchées :

```text
Les personnages possèdent-ils déjà des animations walk ? Oui, le modèle le permet.
Les animations sont-elles directionnelles ? Oui, via EntityFacing.
Les frames sont-elles ordonnées ? Oui, l'ordre de List<CharacterAnimationFrame>.
La cadence est-elle stockée ? Oui, durationMs sur chaque frame, défaut 150 ms.
Comment gérer l'absence de walk ? fallback idle puis placeholder.
Comment gérer l'absence d'une direction ? fallback direction disponible + diagnostic warning.
Comment gérer un sourceRect hors atlas ? réutiliser le fallback placeholder existant et ajouter diagnostic.
```

## 13. Cadence d'animation

Recommandation V0 :

```text
1. Utiliser CharacterAnimationFrame.durationMs quand disponible et > 0.
2. Fallback walk : 140 ms / frame.
3. Fallback run : 90 ms / frame si movementMode == run.
4. Fallback générique : 140 ms / frame.
5. Pause : frameIndex figé.
6. Stop/Reset : frameIndex 0 de l'idle.
7. Début d'un actorMove : frameIndex calculé depuis le temps local du step si disponible, sinon depuis playbackTimeMs.
```

Note : `CharacterAnimationFrame.durationMs` a déjà un défaut de 150 ms. La recommandation 140/90 ne doit s'appliquer que si la metadata frame n'est pas exploitable ou si le futur resolver a besoin d'une cadence V0 uniforme.

Cadence distance-based : à reporter. Elle demanderait une donnée propre de progression/distance dans le playback plan, pas un recalcul de chemin dans l'UI.

## 14. Contrat futur du resolver

Pseudo-contrat V1-115 :

```text
CinematicActorWalkingAnimationPreviewFrame
- actorId
- animationKind: idle | walk | run | fallback
- direction
- frameIndex
- sourceRect / spriteFrameRef
- durationMs
- reason
- fallbackReason
- diagnostics
```

Fonction possible :

```text
buildCinematicActorWalkingAnimationPreviewFrame({
  required CinematicActorDisplayPreviewActor actor,
  required CinematicActorSpritePreviewActor? spriteActor,
  required CinematicPreviewPlaybackFrame? playbackFrame,
  required int playbackTimeMs,
  required bool isPlaying,
  required ProjectManifest project,
  CinematicPreviewPlaybackFrame? previousFrame,
})
```

Entrées autorisées :

```text
actor display model / render actor
sprite preview plan
playbackFrame.actorPoses
playbackTimeMs
isPlaying
CharacterAnimation metadata
actor.movementMode metadata si accessible sans runtime
```

Sortie : frame sprite symbolique ou fallback.

Interdits :

```text
Image
ui.Image
BuildContext
Widget
Flame
GameState
chargement fichier
runtime
```

## 15. Fallbacks

| Cas | Fallback recommandé | Diagnostic utilisateur |
|---|---|---|
| acteur sans sprite | placeholder existant | `Animation de marche indisponible pour cet acteur.` |
| personnage sans walk | idle directionnelle puis idle par défaut | `Animation de marche indisponible, affichage de la pose fixe.` |
| direction walk manquante | walk autre direction puis idle directionnelle | `Direction de marche indisponible, affichage de la pose par défaut.` |
| sourceRect hors atlas | placeholder existant | `Sprite de marche introuvable, affichage du placeholder.` |
| actorPose sans position | idle | Aucun message principal si non bloquant. |
| actorPose non interpolée | idle | Aucun message principal. |
| facing unknown | direction statique existante | Warning discret si fallback visible. |
| playback paused | frame courante figée | Aucun message. |
| playback stopped | idle frame 0 | Aucun message. |
| preview map indisponible | overlay acteur absent/fallback existant | diagnostic readiness existant. |

Ne jamais exposer `sourceRect`, `tilesetId`, `animationKey`, payload ou JSON comme message principal.

## 16. Diagnostics futurs

| Diagnostic | Condition | Severity | Message utilisateur | Fallback | Test futur |
|---|---|---|---|---|---|
| `cinematicWalkingAnimationMissing` | moving + aucune animation walk/run exploitable | warning | Animation de marche indisponible pour cet acteur. | idle puis placeholder | missing walk falls back |
| `cinematicWalkingAnimationDirectionMissing` | state trouvé mais direction absente | warning | Direction de marche indisponible, pose par défaut affichée. | autre direction puis idle | missing direction falls back |
| `cinematicWalkingAnimationFrameMissing` | animation trouvée mais frames vides | warning | Animation de marche vide, pose fixe affichée. | idle/placeholder | empty walk frames |
| `cinematicWalkingAnimationSourceRectInvalid` | frame hors atlas ou source négative | warning | Sprite de marche introuvable, placeholder affiché. | placeholder | invalid source rect |
| `cinematicWalkingAnimationNoSprite` | acteur sans spriteRef exploitable | info/warning | Acteur affiché en repère visuel. | placeholder | placeholder actor visible |
| `cinematicWalkingAnimationFallbackToIdle` | walk absent mais idle disponible | info | Pose fixe utilisée pour cet acteur. | idle | fallback to idle |
| `cinematicWalkingAnimationUnsupportedActorKind` | acteur caché/unsupported/non renderable | info | Acteur non affichable dans la preview. | hidden/placeholder | unsupported actor kind |

## 17. Tests futurs

Tests resolver V1-115 :

```text
- moving actor selects walk frame ;
- stationary actor selects idle frame ;
- facing right selects right walk ;
- missing direction falls back ;
- missing walk falls back to idle ;
- sourceRect invalid falls back ;
- pause keeps same frame ;
- movementMode run uses faster cadence if supported ;
- no runtime/Flame imports.
```

Tests widget V1-116 :

```text
- actorMove direct shows changing walk frames while moving ;
- actorMove manual path shows changing walk frames ;
- stop/reset returns to idle ;
- pause freezes frame ;
- actor without walk animation still visible ;
- placeholder actor still visible ;
- no ProjectManifest mutation ;
- no GameState/runtime imports.
```

Visual Gate future :

```text
- acteur moving visible ;
- frame walk différente de idle ;
- aucun label runtime ;
- aucun scrubber ;
- statut preview-only.
```

## 18. Anti-scope runtime/Flame/GameState

L'animation de marche du Cinematic Builder est une preview editor-only.

Elle ne doit pas :

```text
importer Flame
importer GameState
utiliser PlayableMapGame
modifier CinematicRuntimeAdapter
modifier SceneRuntimeExecutor
charger des images
démarrer une game loop
réutiliser les composants runtime
recalculer pathfinding/collision
```

## 19. Roadmap proposée

Trajectoire retenue :

```text
NS-SCENES-V1-115 — Cinematic Actor Walking Animation Frame Resolver V0
NS-SCENES-V1-116 — Cinematic Actor Walking Animation Renderer Integration V0
```

Justification : le resolver actuel est statique/idle-only et le renderer actuel consomme une frame unique. Séparer le choix de frame de l'intégration visuelle protège les fallbacks et rend le premier lot testable sans screenshot.

## 20. Commandes exécutées

Commandes d'audit :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 10
for f in ...; do test -f "$f"; done
rg -n "class ProjectCharacterEntry|class CharacterAnimation|class CharacterAnimationFrame|enum CharacterAnimationState|enum EntityFacing|animations|frameWidth|frameHeight|durationMs|sourceRect|source:" packages/map_core/lib/src packages/map_core/lib/map_core.dart
rg -n "class CinematicActorSpritePreview|CinematicActorSpritePreviewActor|CinematicActorSpriteRef|sourceTileRect|frameWidthTiles|frameHeightTiles|direction|placeholderFallback|spriteReady|missing|out of bounds|source rect" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_plan.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_renderer.dart packages/map_editor/test/cinematic_actor_sprite_preview_renderer_test.dart
rg -n "class CinematicActorPlaybackPose|isInterpolated|activeStepId|actorPoseById|CinematicPreviewPlaybackFrame|actorPoses|movementMode|actorMove" packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart packages/map_editor/test/cinematic_builder_workspace_test.dart
rg -n "CharacterAnimationState\\.walk|CharacterAnimationState\\.run|state: CharacterAnimationState\\.walk|state: CharacterAnimationState\\.run|movementMode.*run|movementMode.*walk|actor\\.movementMode" packages/map_core packages/map_editor packages/map_editor/test
```

Tests : non lancés, car V1-114 est doc-only et ne modifie aucun package Dart/Flutter.

Analyse : non lancée, car V1-114 est doc-only et ne modifie aucun fichier Dart.

Build : non lancé, car V1-114 ne change ni runtime, ni editor app, ni package compilable.

Validation alternative pertinente : `git diff --check`, inventaire `git diff --name-only`, contrôle anti-scope des packages produit et absence de screenshot V1-114/V1-115.

## 21. git diff --check/stat/name-only/status final

Commande :

```bash
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff --name-only -- packages/map_core packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_114*' -print
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_115*' -print
```

Sortie :

```text
<git diff --check vide>
 .../scenes/road_map_scene_builder_authoring.md     | 15 +++++++++++++++
 reports/narrativeStudio/scenes/road_map_scenes.md  | 22 +++++++++++++++++++---
 2 files changed, 34 insertions(+), 3 deletions(-)
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_114_cinematic_actor_walking_animation_prep_contract.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_114_evidence_pack.md
<diff packages produit vide>
<screenshot v1_114 vide>
<screenshot v1_115 vide>
```

## 22. Risques restants

```text
- isInterpolated ne distingue pas walk/run ; V1-115 devra récupérer movementMode proprement.
- La cadence time-based peut paraître naïve sur un déplacement très lent/rapide.
- Le renderer actuel consomme une seule frame ; V1-116 devra éviter de casser l'ancrage bottom-center.
- Les diagnostics futurs devront rester no-code et ne pas exposer sourceRect/tilesetId.
```

## 23. Auto-critique

Bien tranché : séparation mouvement vs animation, refus runtime/Flame, Option B + F, split V1-115/V1-116.

Incertain : la meilleure source de temps local de step pour la cadence. `playbackTimeMs` suffit pour V0, mais un temps local par `activeStepId` serait plus propre.

Cadence V0 : 140/90 ms est acceptable comme fallback, mais la vraie priorité doit être `CharacterAnimationFrame.durationMs`.

V1-115 seul est raisonnable s'il reste resolver-only. Un lot unique resolver+renderer serait trop gros.

Frontière editor/runtime : claire. Le runtime ne doit pas être importé ni considéré comme source de vérité.

Bis documentaire recommandé : non. Le contrat est assez clair pour démarrer V1-115.

## 24. Verdict final

```text
NS-SCENES-V1-114 : DONE documentaire.
Walking Animation Preview : contrat cadré.
Mouvement vs animation : distingués.
Cadence / direction / fallbacks : cadrés.
Runtime / Flame / GameState : non touchés.
Aucun code produit modifié.
Aucun screenshot.
V1-115 recommandé, non démarré.
```

## 25. Prochain lot recommandé

```text
NS-SCENES-V1-115 — Cinematic Actor Walking Animation Frame Resolver V0
```

Objectif : implémenter un resolver editor-only testable qui choisit symboliquement une frame idle/walk/run/fallback à partir des poses playback et de la Character Library, sans intégration visuelle complète.

## Passes type sub-agents

```text
Sub-agent Audit / Architecture : PASS — les contrats V1-110/V1-113 et V1-97/V1-99 se complètent sans map_core.
Sub-agent Implémentation : PASS — implémentation volontairement limitée aux rapports et roadmaps autorisés.
Sub-agent Tests : PASS doc-only — aucun test Dart/Flutter requis sans code produit ; tests futurs V1-115/V1-116 cadrés.
Sub-agent Build / Validation : PASS — validation alternative `git diff --check` et anti-scope sans erreur.
Sub-agent Options : PASS — Option B + F retenue, D/E refusées, C reportée.
Sub-agent Anti-scope : PASS — aucun package code, runtime, Flame, GameState ni screenshot requis.
Sub-agent Critique finale : PASS avec limites — cadence V0 simple, movementMode à brancher proprement en V1-115.
```
