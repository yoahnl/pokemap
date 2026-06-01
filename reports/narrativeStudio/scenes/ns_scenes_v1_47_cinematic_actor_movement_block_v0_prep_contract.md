# NS-SCENES-V1-47 — Cinematic Actor Movement Block V0 Prep / Contract

## 1. Résumé exécutif

`NS-SCENES-V1-47` est un lot documentaire. Aucun code produit n'a ete modifie.

Le verdict principal : `CinematicTimelineStepKind.actorMove` existe deja dans le modele core, mais il ne doit pas etre rendu authorable avant d'avoir une representation de timeline par lanes. Le futur `actorMove` V0 doit rester strict : acteur requis, lane derivee de l'acteur, duree par presets, cible authoring stable et diagnostiquable, `pathMode=direct`, sans pathfinding, sans preview runtime et sans entite runtime brute.

Prochain lot recommande : `NS-SCENES-V1-48 — Cinematic Timeline Lane Grouping V0`.

## 2. Gate 0

Commandes executees depuis `/Users/karim/Project/pokemonProject` avant modification :

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all

git diff --stat

git diff --name-only

git log --oneline -n 15
7a4404f6 feat(narrative): add cinematic actor references actor facing v0 (NS-SCENES-V1-46)
c68990a7 feat(narrative): add cinematic wait fade camera basic blocks evidence closure (NS-SCENES-V1-45-BIS)
88cb3a54 feat(narrative): add cinematic wait fade camera basic blocks v0 (NS-SCENES-V1-45)
6e66a66d feat(narrative): add cinematic timeline authoring drafts evidence closure (NS-SCENES-V1-44-BIS)
eb0ea9b6 feat(narrative): add cinematic timeline authoring drafts v0 (NS-SCENES-V1-44)
2805560d feat(narrative): add cinematic timeline read-only step inspector evidence closure (NS-SCENES-V1-43-BIS)
6c3b1074 feat(narrative): add cinematic timeline read-only step inspector v0 (NS-SCENES-V1-43)
e95290ce feat(narrative): add cinematic builder v0 shell evidence closure (NS-SCENES-V1-42-BIS)
c9d44fc8 feat(narrative): add cinematic builder v0 shell (NS-SCENES-V1-42)
38f09efa feat(narrative): add cinematic builder v0 scope and runtime playback contract (NS-SCENES-V1-41)
9e1d45d9 feat(narrative): add cinematic runtime adapter v0 bis evidence closure (NS-SCENES-V1-40)
b39d596f feat(narrative): add cinematic runtime adapter v0 (NS-SCENES-V1-40)
eadb0052 chore(reports): add missing screenshot for V1-15 wire anchor color code
0fe8fa1f feat(narrative): add cinematic scene builder picker v0 (NS-SCENES-V1-39)
6644def0 feat(narrative): add cinematics library v0 (NS-SCENES-V1-38)
```

`git status`, `git diff --stat` et `git diff --name-only` etaient vides. Le working tree etait propre, et V1-46 etait deja en `HEAD`.

## 3. Fichiers lus

Instructions et roadmaps :

```text
AGENTS.md
agent_rules.md
skills/README.md
skills/using-superpowers/SKILL.md
skills/brainstorming/SKILL.md
skills/writing-plans/SKILL.md
skills/verification-before-completion/SKILL.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_41_cinematic_builder_v0_scope_runtime_playback_contract.md
reports/narrativeStudio/scenes/ns_scenes_v1_42_cinematic_builder_v0_shell.md
reports/narrativeStudio/scenes/ns_scenes_v1_43_cinematic_timeline_read_only_step_inspector_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_44_cinematic_timeline_authoring_drafts_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_45_bis_cinematic_wait_fade_camera_basic_blocks_evidence_closure.md
reports/narrativeStudio/scenes/ns_scenes_v1_46_cinematic_actor_references_actor_facing_v0.md
```

Audit core, lecture seule :

```text
packages/map_core/lib/src/models/cinematic_asset.dart
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
packages/map_core/lib/src/read_models/cinematics_library_read_model.dart
packages/map_core/lib/map_core.dart
packages/map_core/test/cinematic_authoring_operations_test.dart
packages/map_core/test/cinematic_diagnostics_test.dart
packages/map_core/test/cinematic_asset_test.dart
```

Audit editor, lecture seule :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
```

Audit complementaire positions / ids, lecture seule :

```text
packages/map_core/lib/src/models/map_data.dart
packages/map_core/lib/src/models/map_event_definition.dart
packages/map_core/lib/src/models/geometry.dart
packages/map_core/lib/src/models/map_layer.dart
```

## 4. Pourquoi ce lot existe

V1-46 a donne une identite et une orientation aux acteurs cinematics. Le prochain bloc naturel est le deplacement acteur, mais il porte plus de risques que `actorFace` : cible spatiale, duree, rapport a la carte, lane acteur, future preview et possible confusion avec runtime/pathfinding.

Ce lot existe pour eviter de coder trop tot une API qui deviendrait ensuite une dette : un `actorMove` authorable sans contrat de cible clair risque de devenir soit une teleportation deguisee, soit un mini pathfinding, soit un champ technique difficile a migrer vers une vraie timeline.

## 5. État actuel après V1-46

Etat confirme :

```text
CinematicAsset canonique existe.
ProjectManifest.cinematics existe.
CinematicTimelineStepKind.actorMove existe deja.
CinematicTimelineStepKind.actorFace est authorable depuis V1-46.
CinematicTimelineStep expose actorId, targetId, durationMs et metadata.
CinematicActorRef / requiredActors existent.
Le Builder affiche des lane hints simples via actorId.
Le Builder ne propose pas de vrai multi-lane editor.
Déplacement acteur reste verrouille.
La preview reste un sandbox visuel non-runtime.
```

Hypothese corrigee par l'audit : `actorMove` n'est pas a ajouter comme enum, il est deja present dans `CinematicTimelineStepKind`. Le futur lot d'implementation devra donc ajouter des operations, diagnostics et UI autour d'une enum existante, pas changer le schema juste pour le kind.

## 6. Pass A — Audit modèle CinematicTimelineStep / actorMove existant

`packages/map_core/lib/src/models/cinematic_asset.dart` contient deja :

```text
enum CinematicTimelineStepKind {
  wait,
  camera,
  actorMove,
  actorFace,
  actorEmote,
  dialogueLine,
  sound,
  music,
  fade,
  shake,
  fx,
  marker,
}
```

`CinematicTimelineStep` expose les champs generiques utiles :

```text
id
kind
label
durationMs
actorId
targetId
dialogueText
assetRef
metadata
```

Conclusion : le modele peut representer un futur `actorMove` sans nouveau `kind`. En revanche, il ne possede pas de type cible dedie, pas de `movementMode`, pas de `pathMode` type et pas de lane persistante.

## 7. Pass B — Audit positions / coordonnées / map references disponibles

Le projet possede deja des concepts de positions dans d'autres domaines :

```text
EventPosition pour MapEventDefinition.
GridPos dans geometry.
SurfaceCellPlacement x/y.
MapEntity avec id dans MapData.
MapEventDefinition avec id et position.
MapData avec id.
```

Ces elements prouvent que les maps ont des ids, des events ont des ids et certaines donnees map portent des coordonnees. Ils ne prouvent pas qu'un `CinematicAsset` peut pointer directement vers une position runtime de facon stable et no-code.

Decision : V1-47 ne recommande pas de position libre x/y comme cible V0. Il faut un target authoring stable, validable et lisible, qui pourra ensuite etre resolu par une preview ou un runtime cinematic.

## 8. Pass C — Audit timeline actuelle et lane hints existants

Le Builder V1-46 affiche deja un hint :

```text
Acteur: <label acteur>
```

Ce hint est derive de `step.actorId` et de `CinematicAsset.requiredActors`. Il n'est pas une lane persistante, ne cree pas de piste editable, ne gere pas d'overlap et ne change pas l'ordre lineaire des steps.

Conclusion : la prochaine evolution doit consolider cette derivation en lanes visuelles avant de rendre un bloc `actorMove` authorable. Sinon, le mouvement sera code comme un step lineaire supplementaire, puis devra etre remanie pour entrer dans une timeline par acteurs.

## 9. Design Gate — Cinematic Actor Movement Block V0 Prep / Contract

1. `actorMove` existe-t-il deja dans `CinematicTimelineStepKind` ? Oui.
2. Champs actuels pouvant porter `actorMove` : `actorId`, `targetId`, `durationMs`, `metadata`, `label`.
3. `actorId` est-il suffisant pour identifier l'acteur ? Oui pour l'authoring, s'il reference `CinematicAsset.requiredActors`.
4. `targetId` existe-t-il et que signifie-t-il aujourd'hui ? Oui, mais il est generique et non specialise pour une cible spatiale cinematic.
5. Le modele cinematic possede-t-il une notion de position ? Non.
6. Le modele cinematic possede-t-il une notion de map coordinate ? Non.
7. Le modele cinematic possede-t-il une notion de zone ou waypoint ? Non.
8. Les maps/entities/events exposent-ils deja des ids utilisables comme cibles ? Oui, maps/entities/events ont des ids, mais pas encore un contrat target cinematic.
9. Cible V0 recommandee : waypoint/target authoring explicite et stable, pas position libre, pas entite runtime brute.
10. Sans preview runtime, on peut authorer intention, acteur, cible referencee, duree preset et pathMode borne.
11. Eviter le pathfinding implicite : `pathMode=direct` en V0, pas de chemins manuels, pas d'auto route.
12. Eviter la teleportation deguisee : duree obligatoire, diagnostic si duree absente/invalide, wording "deplacement" seulement si cible resolvable.
13. Duree actorMove : `durationMs` par presets bornes.
14. Marche/course sans gameplay : `movementMode` metadata authoring-only, intention visuelle, pas vitesse runtime.
15. Lane acteur : derivee de `actorId`.
16. Lanes persistées ou dérivées ? Derivees en V0.
17. Faut-il coder Lane Grouping avant Actor Movement ? Oui.
18. Diagnostics bloquants : actorId absent/inconnu, target absent/inconnu, duree invalide, pathMode unsupported, movementMode unsupported.
19. Diagnostics warnings : non previewable, runtime unsupported, target hors map si map connue mais non resolue par preview.
20. Prochain lot exact recommande : `NS-SCENES-V1-48 — Cinematic Timeline Lane Grouping V0`.

## 10. Contrat actorMove V0 recommandé

Contrat futur propose :

```text
kind = actorMove
actorId = requiredActors.actorId existant
targetId = id d'un target authoring cinematic stable
durationMs = preset positif
metadata authoring.source = cinematic-builder-v0
metadata authoring.kind = basicBlock
metadata authoring.block = actorMove
metadata actor.movementMode = walk | run
metadata actor.pathMode = direct
lane = derivee depuis actorId, non persistée
```

Champs interdits en V0 :

```text
position libre x/y dans metadata
path manuel
curve smooth
vitesse runtime
spawn/despawn
followActor
map entity runtime brute comme cible normale
teleport implicite
```

## 11. Options target actorMove comparées

| Option | Verdict | Lisibilite no-code | Diagnostics | Risque runtime | Migration future |
|---|---|---|---|---|---|
| A — position libre x/y | Rejetee V0 | Faible sans preview | Bornes map possibles mais contexte fragile | Eleve, ressemble a runtime coord | Migration probable vers target typed |
| B — targetId vers waypoint authoring | Retenue | Bonne si label/picker | Ref inconnue, map mismatch, target type | Faible | Compatible lane/preview |
| C — targetId vers map entity | Reportee | Lisible si entite nommee | Entity inconnue possible | Moyen, binding runtime implicite | Peut devenir un target type plus tard |
| D — targetId vers zone predefinie | Reportee | Bonne pour zones | Zone inconnue, ambiguite point d'arrivee | Moyen | Utile apres contrat zone |
| E — metadata target temporaire | Rejetee | Faible | Difficile a valider | Eleve | Dette assuree |
| F — pas de target V0 | Rejetee pour implementation future, utile comme garde | Tres sur | Aucun actorMove complet | Tres faible | Bloque trop de valeur |

Option V0 recommandee : `targetId` vers un waypoint/target authoring cinematic stable, introduit dans le lot d'implementation correspondant. Le target devra etre cree via picker/outil no-code et non par texte libre.

## 12. Durée, mouvement et path mode

Duree :

```text
V0 : durationMs obligatoire via presets bornes.
Interdit V0 : champ texte libre, derive runtime, vitesse comme source de duree.
```

Movement mode :

```text
V0 : walk | run comme intention authoring visuelle.
Interdit V0 : vitesse physique, acceleration, collision, stamina ou gameplay.
```

Path mode :

```text
V0 : direct.
Reportes : auto simple, curve smooth, manual path.
Interdits V0 : pathfinding et chemins multi-points authorables.
```

## 13. Contrat timeline / lane pour actorMove

La lane `actorMove` doit etre derivee :

```text
laneId = actor:<actorId>
laneLabel = label de CinematicActorRef ou actorId fallback
laneOrder = ordre de requiredActors, avec Camera/Dialogue/FX/Audio plus tard
```

Ne pas persister la lane dans le step V0. Une lane persistée dans metadata ou layout deviendrait une deuxieme source de verite alors que `actorId` suffit.

Le futur UI lane grouping devra grouper :

```text
actorFace
actorMove
actorEmote
```

sur la lane acteur, sans autoriser encore overlaps, drag/drop ou reordonnancement temporel.

## 14. Diagnostics actorMove requis

Diagnostics V0 bloquants :

```text
actorMove sans actorId
actorMove actorId inconnu
actorMove sans targetId
actorMove targetId inconnu
actorMove target type non supporte
actorMove duree absente ou invalide
actorMove pathMode non supporte
actorMove movementMode non supporte
```

Warnings authoring :

```text
actorMove target hors map si mapId connu mais target map mismatch
actorMove non previewable tant que preview absente
actorMove runtime unsupported tant que player absent
```

Diagnostics futurs :

```text
collision possible
path bloque
overlap temporel avec un autre bloc de meme lane
target occupe
arrivee impossible selon path mode
```

## 15. Relation avec preview et runtime

Actor Movement authoring ne doit pas impliquer :

```text
PlayableMapGame
SceneRuntimeExecutor
SceneEventRuntimeHook
SceneCinematicRuntimeAwaitableAdapter
GameState
pathfinding
actor resolver runtime
preview runtime
```

Abstractions futures possibles, non codees dans V1-47 :

```text
CinematicPlaybackHost
CinematicActorResolver
CinematicPositionResolver
CinematicMovementRunner
```

Le lot d'authoring devra rester capable de produire une cinematic validable sans promettre qu'elle est jouable.

## 16. Non-objectifs confirmés

Confirmé absent de V1-47 :

```text
code Dart produit
widget Flutter
modification map_core/lib
modification map_editor/lib
modification packages
ProjectManifest change
CinematicAsset change
CinematicTimelineStep change
nouvelle enum
build_runner
generated files
actorMove authorable
position cible codee
pathfinding
chemin
vitesse authorable
timeline lane widget
timeline multi-track
drag/drop
reordonnancement
scrubber
keyframes
preview runtime
runtime cinematic
dialogue cinematic
FX authorable
Son authorable
migration ScenarioAsset
donnees produit
```

## 17. Roadmap post V1-47 recommandée

Roadmap courte recommandee :

```text
NS-SCENES-V1-48 — Cinematic Timeline Lane Grouping V0
NS-SCENES-V1-49 — Cinematic Actor Movement Block V0
NS-SCENES-V1-50 — Cinematic Actor Movement Inspector V0
NS-SCENES-V1-51 — Cinematic Dialogue Line Block V0
NS-SCENES-V1-52 — Cinematic FX / Sound Cue Blocks V0
NS-SCENES-V1-53 — Cinematic Timeline Polish / Density Pass
NS-SCENES-V1-54 — Cinematic Preview Sandbox Contract V0
```

Prochain lot exact retenu : `NS-SCENES-V1-48 — Cinematic Timeline Lane Grouping V0`.

Raison : actorMove existe deja comme kind, mais la timeline n'a pas encore de structure visuelle par lanes. Regrouper les steps par lanes derivees donnera une base plus saine pour `actorMove`, sans creer de drag/drop ni de multi-track complet.

## 18. Roadmaps mises à jour

Fichiers modifies :

```text
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

Changements :

```text
V1-47 ajoute comme DONE.
Prochain lot exact mis a jour vers V1-48.
Decision V1-47 ajoutee dans les deux roadmaps.
Limites doc-only et anti-code confirmees.
```

## 19. Commandes exécutées

Lecture et audit :

```text
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 15
sed / cat / rg en lecture seule sur les fichiers listes en section 3
```

Validation documentaire :

```text
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

Tests Dart/Flutter :

```text
Aucun test Dart/Flutter lance pour V1-47 : le lot interdit les modifications de packages et ne change que des rapports Markdown.
```

## 20. Checks anti-scope

Les checks anti-scope sont documentaires. Les termes runtime ou Selbrume peuvent apparaitre dans ce rapport et les roadmaps uniquement comme non-objectifs ou analyse conceptuelle.

Commandes a conserver comme preuve finale :

```text
git diff --name-only -- packages/map_core packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples
git diff --name-only -- packages
rg -n "selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" reports/narrativeStudio/scenes/ns_scenes_v1_47_cinematic_actor_movement_block_v0_prep_contract.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md || true
rg -n "PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|SceneCinematicRuntimeAwaitableAdapter|SceneCinematicRuntimeNoVisualPlayer|GameState|setFact|WorldRule|BattleRuntime|DialogueRuntime" reports/narrativeStudio/scenes/ns_scenes_v1_47_cinematic_actor_movement_block_v0_prep_contract.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md || true
```

## 21. Evidence Pack

Hunks complets des roadmaps modifiees :

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index 72127821..d3ed9a99 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -9,7 +9,7 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
 ## Prochain lot exact recommande

 ```text
-NS-SCENES-V1-47 — Cinematic Actor Movement Block V0 Prep / Contract
+NS-SCENES-V1-48 — Cinematic Timeline Lane Grouping V0
 ```

 ## Principes
@@ -80,6 +80,7 @@ NS-SCENES-V1-47 — Cinematic Actor Movement Block V0 Prep / Contract
 | NS-SCENES-V1-44 | Cinematic Timeline Authoring Drafts V0 | core / editor | Ajouter un brouillon neutre dans le deroule Cinematic, l'inspecter et le retirer de facon bornee via operations pures. | Pas de vrais blocs metier, pas d'edition de champs, pas de player visuel, pas de runtime, pas de changement schema. | `cinematic_authoring_operations.dart`, Builder/Library cinematics, tests core/widget, rapport, screenshot. | DONE : add/remove draft purs, insertion apres selection ou fin, suppression refusee hors brouillon, mutation memoire, visual gate, analyses. | Laisser un brouillon produire un effet ; supprimer un vrai step ; confondre marker neutre et bloc moteur. | DONE : marker draft identifie par metadata, UI no-code bornee, non-regression core/editor prouvee. | V1-43. |
 | NS-SCENES-V1-45 | Cinematic Wait/Fade/Camera Basic Blocks V0 | core / editor | Activer les premiers blocs metier simples du Cinematic Builder : Attente, Fondu et Camera basique. | Pas de deplacement acteur, pas de dialogue, pas de FX/Son, pas de preview runtime, pas de reordonnancement, pas de changement schema. | operations cinematic authoring, Builder/Library cinematics, tests core/widget, rapport, screenshot. | DONE : add/update/remove authoring-owned, presets duree, modes fade/camera, protections non-owned, visual gate, analyses. | Transformer les metadata authoring en API runtime ; ouvrir trop tot des cibles acteur/map. | DONE : blocs V0 bornes, canonical-only preserve, aucun runtime modifie. | V1-44. |
 | NS-SCENES-V1-46 | Cinematic Actor References / Actor Facing V0 | core / editor | Ajouter les references acteur requises et un bloc Orientation acteur V0 dans le Cinematic Builder. | Pas de deplacement acteur, pas de chemin/pathfinding, pas de timeline multi-track, pas de drag/drop, pas de preview runtime, pas de dialogue/FX/Son. | operations cinematic authoring, diagnostics cinematic, Builder/Library cinematics, tests core/widget, rapport, screenshot. | DONE : acteurs requis, bloc `actorFace`, picker acteur, direction up/down/left/right, diagnostics acteur inconnu, visual gate, analyses. | Confondre orientation et mouvement ; exposer des ids acteur comme workflow principal ; ouvrir trop tot runtime/player. | DONE : actor refs et facing bornes, canonical-only preserve, aucun runtime modifie. | V1-45. |
+| NS-SCENES-V1-47 | Cinematic Actor Movement Block V0 Prep / Contract | doc-only / architecture-review | Definir le contrat du futur bloc `actorMove` avant authoring : acteur, cible, duree, movementMode, pathMode, lane, diagnostics et frontieres runtime. | Pas de code Dart, pas de widget, pas de package modifie, pas de schema JSON, pas de actorMove authorable, pas de preview runtime. | rapport V1-47, roadmaps. | DONE : contrat V0, options target comparees, diagnostics cadres, roadmap post V1-47, checks anti-scope. | Coder actorMove trop tot ; creer une position libre non diagnostiquable ; lier le mouvement a un runtime implicite. | DONE : actorMove cadre sans implementation, prochain verrou lane grouping retenu. | V1-46. |

 ## Options comparees

@@ -740,6 +741,20 @@ Preuve : tests core authoring/diagnostics, tests widget Builder/Library, analyse

 Prochain lot exact : `NS-SCENES-V1-47 — Cinematic Actor Movement Block V0 Prep / Contract`.

+## Mise a jour V1-47
+
+Statut : `NS-SCENES-V1-47 — Cinematic Actor Movement Block V0 Prep / Contract` est DONE.
+
+Decision : V1-47 ne code pas le deplacement acteur. L'audit constate que `CinematicTimelineStepKind.actorMove` existe deja et que les champs generiques `actorId`, `targetId`, `durationMs` et `metadata` pourraient porter un futur bloc, mais que le contrat de cible, de lane et de diagnostics doit rester explicite avant toute UI authorable.
+
+Contrat retenu : `actorId` reference obligatoirement `requiredActors`, lane derivee de `actorId`, duree par presets bornes, `movementMode` authoring-only, `pathMode=direct` en V0, cible recommandee sous forme de waypoint/target authoring stable et diagnostiquable. Les positions libres, entites runtime brutes, courbes et chemins manuels sont reportes.
+
+Limites : pas de fichiers `packages/` modifies, pas de build_runner, pas de widget lane, pas de drag/drop, pas de reordonnancement, pas de preview runtime, pas de pathfinding, pas de donnees produit.
+
+Preuve : rapport V1-47, roadmaps seules, checks anti-scope et `git diff --check`.
+
+Prochain lot exact : `NS-SCENES-V1-48 — Cinematic Timeline Lane Grouping V0`.
+
 ## Selbrume golden slice

 Avant le golden slice, il faut au minimum :
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index ece2cfdb..aab59c4b 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -101,16 +101,17 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-44 — Cinematic Timeline Authoring Drafts V0 | DONE | Le Builder peut ajouter un bloc brouillon marker borne, l'inspecter en lecture seule et supprimer uniquement ce brouillon via operations pures `ProjectManifest.cinematics`, sans effet runtime ni vrai bloc metier. |
 | NS-SCENES-V1-45 — Cinematic Wait/Fade/Camera Basic Blocks V0 | DONE | Premiers vrais blocs Cinematic Builder V0 : Attente, Fondu et Camera basique authoring-owned, edition par presets/modes bornes, suppression protegee, sans runtime ni editeur de montage complet. |
 | NS-SCENES-V1-46 — Cinematic Actor References / Actor Facing V0 | DONE | References acteur requises et bloc Orientation acteur V0 : ajout d'acteurs requis, bloc `actorFace` authoring-owned, picker acteur/direction, diagnostics acteur inconnu, sans mouvement ni runtime. |
+| NS-SCENES-V1-47 — Cinematic Actor Movement Block V0 Prep / Contract | DONE | Lot documentaire : contrat spatial/temporel/timeline du futur `actorMove` V0, options de cible comparees, diagnostics cadres, sans code produit ni package modifie. |

 ## Prochain lot recommande

-`NS-SCENES-V1-47 — Cinematic Actor Movement Block V0 Prep / Contract`
+`NS-SCENES-V1-48 — Cinematic Timeline Lane Grouping V0`

-Raison : V1-46 a pose les references acteur et une orientation minimale sans ouvrir deplacement/pathfinding. Le prochain verrou logique est de cadrer le contrat de mouvement acteur avant tout bloc `actorMove` authorable, drag/drop, timeline multi-track ou runtime preview.
+Raison : V1-47 a montre que `actorMove` existe deja dans le modele mais qu'une vraie representation par lanes manque encore. Le prochain verrou logique est de grouper visuellement la timeline par lanes derivees, avant d'authorer un deplacement acteur.

-Ordre apres V1-46 : `NS-SCENES-V1-47 — Cinematic Actor Movement Block V0 Prep / Contract`.
+Ordre apres V1-47 : `NS-SCENES-V1-48 — Cinematic Timeline Lane Grouping V0`.

-Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion, puis Dialogue/Battle Ports Authoring V0, puis Runtime Executor MVP, puis Evidence & Review Hardening, puis World Rules Map Editor Integration V0, puis Golden Slice Scene/Event Prep, puis Event to Scene Runtime Hook V0, puis Scene Consequence Contract Prep, puis Scene Consequence Model V0, puis Scene Consequence Runtime Write V0, puis Battle Runtime Outcome Adapter V0, puis Dialogue Runtime Awaitable Adapter V0, puis Golden Slice Runtime Smoke V0, puis StorylineStep to Scene Link, puis Scene Node Payload Editing V0, puis Scene Node Deletion UX V0, puis Scene Consequence Authoring UI V0, puis Scene V1 Beta Readiness Checkpoint, puis Runtime State Persistence Gate V0, puis World Rules Runtime Projection Hook V0, puis Facts & World Rules Manager UI V0, puis Cinematic V1 Contract / Bridge Decision, puis CinematicAsset Core Model V0, puis Cinematics Library V0, puis Cinematic Scene Builder Picker V0, puis Cinematic Runtime Adapter V0, puis Cinematic Builder V0 Scope / Runtime Playback Contract, puis Cinematic Builder V0 Shell, puis Cinematic Timeline Read-only / Step Inspector V0, puis Cinematic Timeline Authoring Drafts V0, puis Cinematic Wait/Fade/Camera Basic Blocks V0, puis Cinematic Actor References / Actor Facing V0, puis Cinematic Actor Movement Block V0 Prep / Contract.
+Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion, puis Dialogue/Battle Ports Authoring V0, puis Runtime Executor MVP, puis Evidence & Review Hardening, puis World Rules Map Editor Integration V0, puis Golden Slice Scene/Event Prep, puis Event to Scene Runtime Hook V0, puis Scene Consequence Contract Prep, puis Scene Consequence Model V0, puis Scene Consequence Runtime Write V0, puis Battle Runtime Outcome Adapter V0, puis Dialogue Runtime Awaitable Adapter V0, puis Golden Slice Runtime Smoke V0, puis StorylineStep to Scene Link, puis Scene Node Payload Editing V0, puis Scene Node Deletion UX V0, puis Scene Consequence Authoring UI V0, puis Scene V1 Beta Readiness Checkpoint, puis Runtime State Persistence Gate V0, puis World Rules Runtime Projection Hook V0, puis Facts & World Rules Manager UI V0, puis Cinematic V1 Contract / Bridge Decision, puis CinematicAsset Core Model V0, puis Cinematics Library V0, puis Cinematic Scene Builder Picker V0, puis Cinematic Runtime Adapter V0, puis Cinematic Builder V0 Scope / Runtime Playback Contract, puis Cinematic Builder V0 Shell, puis Cinematic Timeline Read-only / Step Inspector V0, puis Cinematic Timeline Authoring Drafts V0, puis Cinematic Wait/Fade/Camera Basic Blocks V0, puis Cinematic Actor References / Actor Facing V0, puis Cinematic Actor Movement Block V0 Prep / Contract, puis Cinematic Timeline Lane Grouping V0.

 Note : l'overview n'affiche plus `Facts — necessite un modele`; Facts et Regles du monde pointent maintenant vers des workspaces actifs.

@@ -328,6 +329,20 @@ Preuve : tests core authoring et diagnostics, tests widget Builder et Library, a

 Prochain lot exact : `NS-SCENES-V1-47 — Cinematic Actor Movement Block V0 Prep / Contract`.

+## Mise a jour V1-47
+
+Statut : `NS-SCENES-V1-47 — Cinematic Actor Movement Block V0 Prep / Contract` est DONE.
+
+Decision : le lot reste documentaire. `CinematicTimelineStepKind.actorMove` existe deja, tout comme `actorId`, `targetId`, `durationMs` et `metadata`, mais aucun contrat spatial cinematic n'est encore authorable. Le futur `actorMove` V0 devra referencer uniquement `CinematicAsset.requiredActors`, utiliser une cible authoring stable et diagnostiquable, garder `pathMode` borne, ne pas impliquer de pathfinding et rester separe de toute preview/runtime.
+
+Contrat recommande : lane derivee depuis `actorId`, duree par presets bornes, `movementMode` authoring-only (`walk`/`run` comme intention visuelle), `pathMode=direct` en V0, cible V0 sous forme de waypoint/target authoring explicite plutot qu'une position libre ou une entite map runtime brute.
+
+Limites : aucun code Dart, aucun widget Flutter, aucun fichier `packages/`, aucun schema JSON, aucun build_runner, aucun actorMove authorable, aucune position cible codee, aucune lane persistante, aucune preview runtime, aucune donnee Selbrume.
+
+Preuve : rapport `reports/narrativeStudio/scenes/ns_scenes_v1_47_cinematic_actor_movement_block_v0_prep_contract.md`, roadmaps seules modifiees, `git diff --check` propre et checks anti-scope confirmant que `packages/`, runtime/gameplay/battle/examples restent intacts.
+
+Prochain lot exact : `NS-SCENES-V1-48 — Cinematic Timeline Lane Grouping V0`.
+
 ## Mise a jour V1-30-bis

 Statut : `NS-SCENES-V1-30-bis — Scene Node Deletion UX V0` est DONE.
```

Sorties finales a jour :

```text
git diff --name-only -- packages/map_core packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples

git diff --name-only -- packages

git diff --unified=0 -- reports/narrativeStudio/scenes/ns_scenes_v1_47_cinematic_actor_movement_block_v0_prep_contract.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md | rg -ni "^\+.*(selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais)" || true
52:+Limites : aucun code Dart, aucun widget Flutter, aucun fichier `packages/`, aucun schema JSON, aucun build_runner, aucun actorMove authorable, aucune position cible codee, aucune lane persistante, aucune preview runtime, aucune donnee Selbrume.

git diff --unified=0 -- reports/narrativeStudio/scenes/ns_scenes_v1_47_cinematic_actor_movement_block_v0_prep_contract.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md | rg -n "^\+.*(PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|SceneCinematicRuntimeAwaitableAdapter|SceneCinematicRuntimeNoVisualPlayer|GameState|setFact|WorldRule|BattleRuntime|DialogueRuntime)" || true

git diff --unified=0 -- reports/narrativeStudio/scenes/ns_scenes_v1_47_cinematic_actor_movement_block_v0_prep_contract.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md | rg -n '^\+.*(actorMove authorable|pathfinding|drag/drop|preview runtime|code Dart|widget Flutter|fichier `packages/`)' || true
9:+| NS-SCENES-V1-47 | Cinematic Actor Movement Block V0 Prep / Contract | doc-only / architecture-review | Definir le contrat du futur bloc `actorMove` avant authoring : acteur, cible, duree, movementMode, pathMode, lane, diagnostics et frontieres runtime. | Pas de code Dart, pas de widget, pas de package modifie, pas de schema JSON, pas de actorMove authorable, pas de preview runtime. | rapport V1-47, roadmaps. | DONE : contrat V0, options target comparees, diagnostics cadres, roadmap post V1-47, checks anti-scope. | Coder actorMove trop tot ; creer une position libre non diagnostiquable ; lier le mouvement a un runtime implicite. | DONE : actorMove cadre sans implementation, prochain verrou lane grouping retenu. | V1-46. |
19:+Limites : pas de fichiers `packages/` modifies, pas de build_runner, pas de widget lane, pas de drag/drop, pas de reordonnancement, pas de preview runtime, pas de pathfinding, pas de donnees produit.
48:+Decision : le lot reste documentaire. `CinematicTimelineStepKind.actorMove` existe deja, tout comme `actorId`, `targetId`, `durationMs` et `metadata`, mais aucun contrat spatial cinematic n'est encore authorable. Le futur `actorMove` V0 devra referencer uniquement `CinematicAsset.requiredActors`, utiliser une cible authoring stable et diagnostiquable, garder `pathMode` borne, ne pas impliquer de pathfinding et rester separe de toute preview/runtime.
52:+Limites : aucun code Dart, aucun widget Flutter, aucun fichier `packages/`, aucun schema JSON, aucun build_runner, aucun actorMove authorable, aucune position cible codee, aucune lane persistante, aucune preview runtime, aucune donnee Selbrume.

rg -n "[ \t]+$" reports/narrativeStudio/scenes/ns_scenes_v1_47_cinematic_actor_movement_block_v0_prep_contract.md || true

git diff --check

git diff --stat
 .../scenes/road_map_scene_builder_authoring.md     | 17 +++++++++++++++-
 reports/narrativeStudio/scenes/road_map_scenes.md  | 23 ++++++++++++++++++----
 2 files changed, 35 insertions(+), 5 deletions(-)

git diff --name-only
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md

git status --short --untracked-files=all
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_47_cinematic_actor_movement_block_v0_prep_contract.md
```

Interpretation : les deux checks `packages` sont vides ; les seuls matches Selbrume ou anti-scope sur lignes ajoutees sont des limites explicites ; aucun terme runtime interdit n'apparait dans les lignes ajoutees. `git diff --stat` ne liste que les fichiers deja suivis par Git, tandis que `git status --short --untracked-files=all` expose le rapport V1-47 non suivi.

## 22. Auto-review critique

1. V1-47 a-t-il modifie `packages/` ? Non.
2. V1-47 a-t-il modifie `map_core/lib` ? Non.
3. V1-47 a-t-il modifie `map_editor/lib` ? Non.
4. V1-47 a-t-il ajoute du code Dart ? Non.
5. V1-47 a-t-il ajoute un widget Flutter ? Non.
6. V1-47 a-t-il change le schema JSON ? Non.
7. V1-47 a-t-il lance build_runner ? Non.
8. V1-47 a-t-il rendu `actorMove` authorable ? Non.
9. V1-47 a-t-il ajoute une position cible codee ? Non.
10. V1-47 a-t-il ajoute du pathfinding ? Non.
11. V1-47 a-t-il ajoute un drag/drop ou un reorder ? Non.
12. V1-47 a-t-il ajoute une preview runtime ? Non.
13. Le contrat `actorMove` V0 est-il defini ? Oui.
14. Les options de target sont-elles comparees ? Oui.
15. Une option target V0 est-elle recommandee ? Oui, waypoint/target authoring stable.
16. Les lanes sont-elles tranchees ? Oui, derivees de `actorId`; Lane Grouping avant Actor Movement.
17. Les diagnostics actorMove sont-ils cadres ? Oui.
18. Les roadmaps sont-elles mises a jour ? Oui.
19. L'Evidence Pack contient-il Gate 0, hunks, checks et statut final ? Oui.
20. Prochain lot exact recommande ? `NS-SCENES-V1-48 — Cinematic Timeline Lane Grouping V0`.

## 23. Verdict final

`NS-SCENES-V1-47 — Cinematic Actor Movement Block V0 Prep / Contract` peut etre marque DONE.

Le lot a rempli son objectif : cadrer `actorMove` avant implementation, confirmer que le kind existe deja, refuser le pathfinding et la preview runtime, recommander des lanes derivees et choisir `NS-SCENES-V1-48 — Cinematic Timeline Lane Grouping V0` comme prochain verrou.
