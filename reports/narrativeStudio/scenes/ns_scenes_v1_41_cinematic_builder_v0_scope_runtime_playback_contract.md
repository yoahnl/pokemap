# NS-SCENES-V1-41 — Cinematic Builder V0 Scope / Runtime Playback Contract

## 1. Resume executif

V1-41 est un lot documentaire de cadrage. Il ne code pas le Cinematic Builder, ne cree pas de timeline editor, ne modifie pas le runtime visuel et ne change aucun package produit.

Decision canonique :

```text
Cinematic Builder V0 = assembleur no-code de sequences moteur simples, lineaires, sandboxees.
Runtime Playback V0 = lecture bornee de ces sequences, sans gameplay effect et sans branching.
```

Le Builder V0 cible doit ouvrir une cinematic depuis la Cinematics Library, afficher une palette de blocs simples, une preview sandbox centrale, un deroule/timeline simplifie et un inspecteur de bloc. Il reste un outil d'assemblage, pas un Scene Builder bis, pas un Dialogue Studio, pas un Cutscene Studio legacy et pas un outil video professionnel.

Le Runtime Playback cible doit lire un `CinematicAsset` canonique, resoudre les dependances visuelles via un host borne, retourner uniquement `completed` a la Scene en cas de succes et signaler les failures internes sans exposer de ports authorables `failed`, `skipped` ou `cancelled`. Cinematic ne lance pas de Battle, n'ecrit pas de Fact, n'applique pas de World Rule, ne teleporte pas, ne complete pas de StorylineStep et ne modifie pas durablement le `GameState`.

Prochain lot recommande : `NS-SCENES-V1-42 — Cinematic Builder V0 Shell`.

## 2. Gate 0

Commande : `pwd`

```text
/Users/karim/Project/pokemonProject
```

Commande : `git branch --show-current`

```text
main
```

Commande : `git status --short --untracked-files=all`

```text
<vide>
```

Commande : `git diff --stat`

```text
<vide>
```

Commande : `git diff --name-only`

```text
<vide>
```

Commande : `git log --oneline -n 15`

```text
9e1d45d9 feat(narrative): add cinematic runtime adapter v0 bis evidence closure (NS-SCENES-V1-40)
b39d596f feat(narrative): add cinematic runtime adapter v0 (NS-SCENES-V1-40)
eadb0052 chore(reports): add missing screenshot for V1-15 wire anchor color code
0fe8fa1f feat(narrative): add cinematic scene builder picker v0 (NS-SCENES-V1-39)
6644def0 feat(narrative): add cinematics library v0 (NS-SCENES-V1-38)
05d631f8 feat(narrative): add cinematic asset core model v0 (NS-SCENES-V1-37)
ba7a91f3 update package_config.json
7c4667a4 feat(runtime): finalize cinematic v1 bridge decision and battle auto-switch
27ae87af chore(repo): ignore and untrack .idea workspace
1bc426a9 feat(runtime): sync gamepads plugin packages and host tests
2db4a2b4 Merge branch 'runtime-battle-bridge-psdk-restart'
5f6a17b7 feat(scenes): add facts and world rules manager ui v0
dcbf33b3 feat: complete PSDK runtime bridge diagnostics
8b78df97 feat(scenes): add v1-33 v1-34 runtime persistence projection gates
29c78ea8 chore(scenes): add v1-32 readiness checkpoint report
```

Conclusion Gate 0 : working tree propre avant V1-41. Les changements introduits par V1-41 sont donc uniquement les changements visibles apres ce rapport.

## 3. Fichiers lus

Fichiers de consignes et workflow :

```text
AGENTS.md
agent_rules.md
skills/README.md
skills/brainstorming/SKILL.md
skills/writing-plans/SKILL.md
skills/verification-before-completion/SKILL.md
/Users/karim/.codex/attachments/c745ace4-f97b-4aa6-a285-309896bbb34a/pasted-text.txt
```

Roadmaps et rapports Narrative Studio lus :

```text
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_36_cinematic_v1_contract_bridge_decision.md
reports/narrativeStudio/scenes/ns_scenes_v1_37_cinematic_asset_core_model_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_38_cinematics_library_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_39_cinematic_scene_builder_picker_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_40_cinematic_runtime_adapter_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_40_bis_cinematic_runtime_adapter_evidence_closure.md
```

Fichiers de code lus en audit seulement :

```text
packages/map_core/lib/src/models/cinematic_asset.dart
packages/map_core/lib/src/models/scene_asset.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/runtime/scene_runtime_plan.dart
packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart
packages/map_core/lib/src/runtime/scene_runtime_executor.dart
packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_adapter.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_result.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
```

Tous les chemins obligatoires existent dans le repo local.

## 4. Pourquoi ce lot existe

V1-36 a tranche que Cinematic doit devenir un asset canonique dedie, lineaire et visuel, distinct de `ScenarioAsset`. V1-37 a ajoute le modele core `CinematicAsset`. V1-38 a expose la Cinematics Library. V1-39 a permis a Scene Builder de referencer un `CinematicAsset` canonique. V1-40 a remplace l'ack bridge par un adapter awaitable no-visual qui attend la completion.

Le trou restant n'est pas un trou de code, mais un trou de contrat produit. Sans V1-41, le prochain chantier peut deriver dans plusieurs directions dangereuses : refaire `ScenarioAsset`, ouvrir un mini Scene Builder dans Cinematic, coder un After Effects artisanal, laisser Cinematic ecrire dans le monde, ou construire une jolie UI impossible a brancher proprement.

V1-41 existe donc pour figer les frontieres avant V1-42 : ce que Builder V0 assemble, ce que Runtime Playback lit, ce qui reste preview sandbox, ce qui reste Scene, ce qui reste Dialogue Yarn, ce qui reste Battle, et ce que le legacy ne doit pas redevenir.

## 5. Etat actuel apres V1-40

Etat canonique acquis :

- `CinematicAsset` existe dans `map_core` avec `id`, `title`, metadata, `requiredActors`, `timeline` et `legacyBridge` optionnel.
- `CinematicTimeline` contient une liste ordonnee de `CinematicTimelineStep`.
- `CinematicTimelineStepKind` existe deja avec `wait`, `camera`, `actorMove`, `actorFace`, `actorEmote`, `dialogueLine`, `sound`, `music`, `fade`, `shake`, `fx` et `marker`.
- `ProjectManifest.cinematics` stocke les cinematics canoniques.
- `CinematicPublicContract` expose les cinematics canoniques avec `completed`, `linear: true`, acteurs requis et diagnostics, tout en gardant `scenarioBridge` comme legacy `bridgeOnly`.
- `SceneCinematicPayload` porte seulement un `cinematicId`.
- `SceneRuntimePlanIntent.playCinematic` compile ce payload en intent runtime.
- `SceneRuntimeExecutor` accepte seulement le port `completed` pour `playCinematic`.
- `SceneCinematicRuntimeAwaitableAdapter` resout l'asset canonique, reconnait un bridge legacy, echoue les ids inconnus et appelle un player.
- `SceneCinematicRuntimeNoVisualPlayer` somme les `durationMs` positives et attend cette duree, sans rendu visuel.
- `PlayableMapGame` injecte ce player no-visual dans le callback `playCinematic`.

Ce qui n'existe pas encore :

- aucun Cinematic Builder V0 ;
- aucune edition de steps ;
- aucune UI de timeline ;
- aucune preview sandbox in-engine ;
- aucun player visuel camera/acteurs/FX/audio/fondu ;
- aucun contrat de host playback visuel ;
- aucun diagnostic de dependances fines par bloc cinematic.

## 6. Pass A — Audit produit Cinematic V1

Cinematic V1 doit rester une sequence visuelle lineaire. Son role produit est de montrer quelque chose : cadrage camera, entree d'un acteur, mouvement, emotion, dialogue visuel borne, transition, son, FX ou attente. Son role n'est pas de decider la logique de la scene.

Frontiere produit stable :

- Scene orchestre le graph logique et decide quand lancer une Cinematic.
- Cinematic decrit ce qui se passe visuellement pendant cette attente.
- Dialogue Yarn reste responsable des textes riches, choix et outcomes.
- Battle reste responsable du combat runtime.
- Facts et World Rules restent responsables de l'etat persistant et de sa projection.
- ScenarioAsset reste legacy/bridge, pas modele final.

La Cinematics Library doit donc presenter des sequences moteur authorables, pas des videos. Les metadonnees utiles sont les blocs internes resumes, acteurs requis, map/context, duree estimee, diagnostics et usages Scene. Les signaux dangereux sont les jaquettes media, les imports MP4, les termes de montage video professionnel et les controles frame-perfect.

## 7. Pass B — Audit modele CinematicAsset actuel

Le modele actuel est volontairement minimal et deja compatible avec un Builder V0 borne :

- `CinematicAsset` est canonique, identifiable et serialisable.
- `requiredActors` fournit une surface d'audit pour les dependances acteur.
- `timeline.steps` est un ordre lineaire, pas un graph.
- `CinematicTimelineStepKind` couvre les familles de blocs conceptuelles attendues.
- Chaque step a un payload generique minimal : `durationMs`, `actorId`, `targetId`, `dialogueText`, `assetRef`, `metadata`.
- `legacyBridge` documente une provenance et ne doit pas devenir une execution.

Limite volontaire : le payload de step est encore trop generique pour un Builder riche. V1-41 ne doit pas le changer. Les futurs lots devront decider si les blocs restent dans ce payload generique avec conventions validees, ou si des payloads types sont ajoutes. La decision doit venir apres le shell et les premiers blocs, pas dans ce lot documentaire.

Point de vigilance : `dialogueText` existe deja. Il ne doit pas devenir un Dialogue Studio cache. Il peut porter une ligne cinematic simple, sans choix, sans outcome et sans logique Yarn.

## 8. Pass C — Audit runtime V1-40 / playback no-visual

Le runtime actuel fait trois choses utiles :

1. Il resout un `CinematicAsset` canonique depuis `ProjectManifest.cinematics`.
2. Il appelle un `SceneCinematicRuntimePlayer`.
3. Il retourne un port Scene `completed` si le player reussit.

Le player V0 no-visual ne joue pas les cameras, acteurs, sons, FX ou dialogues. Il attend seulement la somme des `durationMs` positives des steps, puis retourne `completed`. C'est suffisant pour prouver la temporalite awaitable et eviter que les consequences Scene soient commitees avant la fin.

La failure interne existe deja via `SceneCinematicRuntimeAwaitableResult.failed`. Elle ne devient pas un port authorable. Dans `PlayableMapGame`, une failure lève une erreur de callback, ce qui fait echouer l'execution Scene et evite les writes partiels.

Ce contrat doit rester vrai pour le futur player visuel : tout support visuel peut etre meilleur, mais ne doit jamais creer de nouveaux ports authorables ou ecrire dans `GameState`.

## 9. Pass D — Specification Cinematic Builder V0

Nature exacte de l'ecran : le Cinematic Builder V0 est un ecran Narrative Studio ouvert depuis une cinematic canonique de la Cinematics Library. Il assemble une sequence lineaire de blocs cinematic. Il ne gere pas une arborescence globale, ne cree pas de graph Scene, ne propose pas de branches et ne remplace pas la Library.

Structure cible :

- top bar : retour Library, titre cinematic, statut de validation, actions save/preview quand supportees ;
- palette gauche : blocs autorises par capacite V0 ;
- preview centrale : sandbox in-engine ou placeholder honnete tant que la preview n'est pas codee ;
- timeline/deroule simplifie : liste ordonnee de blocs, pas timeline frame-perfect ;
- inspecteur droit : payload no-code du bloc selectionne ;
- validation locale : erreurs/warnings/info par cinematic et par bloc ;
- sauvegarde authoring : mutation du `CinematicAsset` canonique seulement par operations bornees, dans un lot futur.

Le Builder V0 sert a composer :

```text
une sequence lineaire de steps cinematic
```

Il ne compose pas :

```text
un graph
un script generaliste
une Scene
un ScenarioAsset
un dialogue complet
un combat
une quete
une suite de consequences gameplay
```

Le shell V1-42 doit donc se limiter a ouvrir l'ecran, montrer les zones, afficher les etats vides/readonly, brancher la navigation depuis la Library et refuser l'edition des steps tant que les operations ne sont pas cadreuses.

## 10. Pass E — Specification Runtime Playback Contract

Le futur contrat runtime doit etre pense comme un host de capacites, pas comme un nouveau moteur narratif.

Concepts contractuels proposes, sans code dans V1-41 :

- `CinematicPlaybackHost` : facade runtime ou preview qui annonce ses capacites.
- `CinematicPlaybackRequest` : cinematic canonique, id de requete, contexte map optionnel, mode runtime/preview.
- `CinematicPlaybackResult` : `completed` ou failure interne, sans branch authorable.
- `CinematicActorResolver` : resolve actor refs vers entites runtime ou acteurs sandbox.
- `CinematicCameraController` : focus, pan, follow, reset.
- `CinematicDialoguePresenter` : ligne cinematic simple ou future reference bornee.
- `CinematicAudioCuePlayer` : SFX/ambience/BGM cue si le runtime audio le supporte.
- `CinematicFxPlayer` : FX predefinis, shake, flash, particules simples.

Repartition par horizon :

| Horizon | Contrat |
|---|---|
| V0 immediat | No-visual player existant : attend durees positives, retourne `completed`, failure interne si id/player invalides. |
| V0 Builder cible | Authoring de blocs simples et validation des dependances, sans supposer que chaque bloc est rendu par le runtime actuel. |
| V1 futur proche | Player visuel borne pour wait/fade/camera basique/actor movement simple/dialogue simple/FX simples selon capacites. |
| V2 plus tard | Preview plus riche, pause/skip interne, audio plus fin, easing/courbes simples si necessaire. |
| Hors-scope | Branching, keyframes avancees, scripts, combat, facts, world rules, teleport, inventory, save-game mutation. |

Regles runtime :

- `completed` est le seul port scene normal.
- Une failure interne bloque la Scene, ne devient pas un choix auteur.
- Le player ne commit aucune mutation persistante.
- Les effets visuels temporaires doivent etre nettoyes a la fin ou a l'echec.
- Les actor refs absents sont des diagnostics authoring et des failures runtime si le bloc ne peut pas etre degrade proprement.
- Les contexts map absents bloquent les blocs visuels qui en dependent ; `wait` peut rester supporte.
- Save/load pendant une cinematic doit etre interdit, reporte, ou checkpointé avant/apres la cinematic ; jamais sauvegarde au milieu d'une mutation visuelle temporaire.
- Skip/pause futur reste un controle runtime interne qui retourne `completed` ou failure interne, pas une branche auteur.

## 11. Pass F — Frontieres anti-scope et legacy bridge

Confusions interdites :

| Confusion | Decision V1-41 |
|---|---|
| Cinematic = Scene | Rejete. Scene orchestre ; Cinematic montre. |
| Cinematic = ScenarioAsset | Rejete. ScenarioAsset est legacy/bridge. |
| Cinematic = Dialogue Yarn | Rejete. Ligne simple possible, choix/outcomes interdits. |
| Cinematic = Battle | Rejete. Battle reste un node Scene/runtime battle. |
| Cinematic = Fact writer | Rejete. Les writes passent par Scene Action/Consequence. |
| Cinematic = World Rule | Rejete. World Rules projettent l'etat ; Cinematic ne les applique pas. |
| Cinematic = StorylineStep | Rejete. StorylineStep peut referencer Scene, pas etre complete par Cinematic. |
| Cinematic = Event | Rejete. Event declenche Scene ; Scene peut lancer Cinematic. |

Le legacy peut inspirer certains concepts visuels, mais ne fournit pas le runtime canonique. `ScenarioRuntimeExecutor` ne doit pas devenir le player cinematic : il execute des flows generiques avec commandes et effets gameplay, exactement ce que Cinematic doit refuser.

## 12. Contrat canonique Builder V0

Le Builder V0 est autorise a :

- editer l'ordre d'une sequence lineaire de blocs cinematic ;
- exposer uniquement des blocs dont les payloads sont validables ;
- utiliser des pickers lisibles pour acteurs, cibles, sons, dialogues et FX ;
- afficher un resume de duree estimee ;
- afficher diagnostics et usages ;
- lancer une preview sandbox quand un host preview existe ;
- sauvegarder un `CinematicAsset` canonique dans un lot futur.

Le Builder V0 est interdit de :

- creer des branches ;
- exposer des outcomes authorables ;
- lancer un combat ;
- ecrire un Fact ;
- appliquer une World Rule ;
- completer une StorylineStep ;
- donner un objet ;
- teleporter le joueur ;
- muter le `GameState` ;
- consommer un event ;
- accepter des ids libres comme workflow normal ;
- devenir un outil de montage video frame-perfect.

Contrat d'UX no-code :

- les acteurs se choisissent dans `requiredActors` ou via un picker de contexte ;
- les cibles camera/position doivent etre choisies par picker ou preview, pas par id brut ;
- les sons/FX doivent etre des cues/predefs validables ;
- les erreurs bloquantes doivent etre visibles avant preview/runtime ;
- les limitations runtime doivent etre affichees comme capacites, pas cachees.

## 13. Contrat canonique Runtime Playback V0/V1

Le runtime V0 actuel :

- accepte un intent `playCinematic(cinematicId)`;
- resout un asset canonique ;
- reconnait un bridge Scenario legacy sans le promouvoir ;
- refuse un id inconnu ;
- appelle un player no-visual ;
- attend les durees positives ;
- retourne `completed`.

Le runtime visuel futur devra :

- prendre un `CinematicAsset`, jamais un `ScenarioAsset` comme source de verite ;
- valider les steps supportes par le host courant ;
- resoudre les acteurs requis avant de jouer ;
- appliquer seulement des effets visuels/audio temporaires ;
- verrouiller les inputs gameplay si necessaire ;
- nettoyer les effets temporaires a la fin ;
- signaler `completed` ou failure interne ;
- ne jamais ecrire de consequence persistante ;
- laisser Scene continuer vers Dialogue/Battle/Action/End.

Failure interne sans branche authorable :

- id manquant : failure ;
- id inconnu : failure ;
- bridge legacy non canonique : acknowledgement legacy ou failure selon mode futur, mais pas canonical playback ;
- acteur requis absent : failure ou preview degraded explicite ;
- step unsupported : diagnostic authoring, et runtime failure si la cinematic est jouee quand meme ;
- player exception : failure `playerFailed`.

Partial writes :

- Cinematic ne stage ni ne commit de writes ;
- Scene consequences restent apres les ports Scene ;
- un echec cinematic empeche les ActionNode suivants de s'executer ;
- aucun effet visuel temporaire ne devient source de verite.

## 14. Taxonomie des blocs cinematic

### Attente

Objectif utilisateur : creer une pause narrative courte ou temporiser la sequence.

Payload authoring minimal : duree en millisecondes, label optionnel.

Dependances : aucune.

Validation minimale : duree positive ou nulle ; avertissement si duree tres longue ; id step unique.

Runtime support attendu : supporte par le player no-visual actuel via `durationMs`; support visuel equivalent a un timer.

Limites V0 : pas de condition, pas de interruption authorable.

Report : pause/skip fine, accelerations, time scaling.

### Fondu

Objectif utilisateur : masquer ou reveler la scene par transition courte.

Payload authoring minimal : type `fadeIn`, `fadeOut` ou `fadeToBlack`, duree, couleur token/predefinie si exposee plus tard.

Dependances : overlay/transition host runtime ou preview.

Validation minimale : type connu, duree positive, couleur/predef autorisee.

Runtime support attendu : no-op ou unsupported dans le player no-visual ; support V1 visuel via host de transition.

Limites V0 : pas de courbe complexe, pas de masque video, pas de transition custom.

Report : transitions composees, wipes, easing avance.

### Camera

Objectif utilisateur : cadrer l'attention sans ecrire de gameplay.

Payload authoring minimal : action `focus`, `pan`, `follow`, `frameZone`, `reset`; cible acteur/point/zone ; duree optionnelle.

Dependances : contexte map, camera controller, actor/target resolver.

Validation minimale : cible connue, action supportee par le host, duree non negative, fallback reset disponible.

Runtime support attendu : no-visual actuel ne rend rien ; V1 visuel supporte d'abord focus/reset/pan simple.

Limites V0 : pas de keyframes, pas de Bezier complexe, pas de camera collision, pas de multi-camera.

Report : easing avance, splines, shakes parametrables complexes, composition camera avec gameplay.

### Deplacement acteur

Objectif utilisateur : faire entrer, sortir ou repositionner visuellement un acteur pendant la cinematic.

Payload authoring minimal : acteur requis, cible position/zone, mode marche/course simple, duree estimee ou vitesse simple.

Dependances : actor resolver, contexte map, coordonnees validables, mouvement visuel temporaire.

Validation minimale : acteur declare, cible connue, map compatible, bloc non utilise pour teleport/gameplay, pas de collision gameplay obligatoire en V0.

Runtime support attendu : no-visual actuel no-op/unsupported ; V1 visuel peut supporter un chemin simple si le runtime dispose d'un acteur visible.

Limites V0 : pas de pathfinding complexe garanti, pas de commit position durable, pas de collision gameplay, pas de follow system.

Report : choregraphies multi-acteurs, avoidance, chemins edites point par point, blending animation avance.

### Orientation / emote acteur

Objectif utilisateur : montrer une reaction lisible.

Payload authoring minimal : acteur, direction ou emote predefinie, duree optionnelle.

Dependances : actor resolver, catalogue d'emotes/animations si disponible.

Validation minimale : acteur connu, emote/predef connue, fallback si animation absente.

Runtime support attendu : no-visual no-op ; V1 visuel si actor component expose orientation/emote.

Limites V0 : pas d'animation timeline fine, pas de blend tree.

Report : expressions avancees, poses custom, animation importee.

### Dialogue

Objectif utilisateur : afficher une ligne cinematic courte pendant la sequence.

Payload authoring minimal : speaker/acteur optionnel, texte court ou future reference dialogue bornee, duree/auto-advance optionnelle.

Dependances : presenter dialogue cinematic, localisation future si necessaire, actor/speaker resolver.

Validation minimale : texte non vide si inline, longueur raisonnable, aucune choice, aucun outcome, aucune variable gameplay non supportee.

Runtime support attendu : no-visual actuel no-op/unsupported ; V1 peut afficher une ligne simple. Reference Yarn complete reportee tant qu'elle ne produit pas d'outcome dans Cinematic.

Limites V0 : aucun choix, aucun outcome Yarn, pas de Dialogue Studio cache, pas de branche.

Report : reference Yarn bornee, localisation, speaker portraits, voice cue, mais toujours sans outcome cinematic.

### Son

Objectif utilisateur : jouer un SFX, une ambiance courte ou un cue BGM borne.

Payload authoring minimal : asset/cue ref, type `sfx`, `ambience` ou `bgmCue`, volume/predef optionnel, duree optionnelle pour ambiance.

Dependances : audio cue registry ou assets audio validables, runtime audio host.

Validation minimale : ref connue, type supporte, pas de chemin libre comme workflow normal.

Runtime support attendu : no-visual actuel no-op/unsupported ; V1 seulement si audio runtime expose un host.

Limites V0 : pas de mixage pro, pas d'automation, pas de timeline audio frame-perfect.

Report : crossfade BGM avance, ducking, spatial audio.

### FX

Objectif utilisateur : ajouter un effet visuel simple et previsible.

Payload authoring minimal : FX predefini (`flash`, `mist`, `particle`, `shake`), cible optionnelle, duree/intensite bornee.

Dependances : catalogue FX, preview/runtime host, cible optionnelle.

Validation minimale : FX connu, intensite bornee, cible connue si requise.

Runtime support attendu : no-visual no-op/unsupported ; V1 peut supporter flash/shake/fade avant particules.

Limites V0 : pas de shader authoring, pas de particules custom libres, pas de scripts.

Report : librairie FX enrichie, parametres avances, layering.

### Marker interne

Objectif utilisateur : annoter la sequence pour auteurs ou futurs outils.

Payload authoring minimal : label/note.

Dependances : aucune runtime.

Validation minimale : label lisible.

Runtime support attendu : ignore par runtime.

Limites V0 : ne produit aucun effet.

Report : bookmarks preview, chapitres internes.

## 15. Capability Matrix

| Capacite | Builder V0 | Runtime V0 | Preview sandbox V0 | Validation V0 | Statut | Commentaires |
|---|---|---|---|---|---|---|
| Wait duration | Oui | Oui no-visual | Oui simple | Error si duree negative | V0 immediat | Deja compatible avec `durationMs`. |
| Camera focus | Oui cible | No-op/unsupported | Futur proche | Target connu requis | V1 runtime | Authorable apres shell/blocs camera. |
| Camera pan | Oui simple | No-op/unsupported | Futur proche | Duree/cible requises | V1 runtime | Pas de keyframes. |
| Actor move | Oui borne | No-op/unsupported | Futur proche | Acteur/cible requis | V1 runtime | Pas de commit position durable. |
| Actor facing | Oui borne | No-op/unsupported | Futur proche | Acteur/direction requis | V1 runtime | Peut partager actor resolver. |
| Dialogue simple | Oui borne | No-op/unsupported | Futur proche | Texte/speaker valides | V1 runtime | Pas de choix/outcome. |
| Dialogue Yarn ref | Reporte | Unsupported | Reporte | Ref connue future | V1/V2 | Possible seulement sans outcome cinematic. |
| Fade in/out | Oui borne | No-op/unsupported | Futur proche | Type/duree requis | V1 runtime | Bloc prioritaire apres wait. |
| SFX cue | Oui si registry | Unsupported | Futur proche | Cue connu | V1/V2 | No-op valide si audio host absent et signale. |
| BGM cue | Reporte | Unsupported | Reporte | Cue connu | V2 | Risque de scope audio. |
| FX simple | Oui predef | Unsupported | Futur proche | FX connu/intensite bornee | V1/V2 | Flash/shake avant particules. |
| Shake | Oui borne | Unsupported | Futur proche | Intensite/duree bornees | V1 | Sous-famille camera/FX. |
| Actor spawn temporary | Reporte | Unsupported | Reporte | Acteur/asset requis | V2 | Temporaire seulement, pas spawn gameplay. |
| Actor hide/show temporary | Reporte | Unsupported | Reporte | Acteur requis | V2 | Visuel temporaire, pas World Rule. |
| Branch | Non | Non | Non | Error si legacy | Interdit | La branche reste Scene. |
| Battle | Non | Non | Non | Error si legacy | Interdit | Battle reste Scene/Battle runtime. |
| Fact write | Non | Non | Non | Error si legacy | Interdit | Les writes passent par Action/Consequence. |
| World Rule apply | Non | Non | Non | Error si legacy | Interdit | World Rules projettent le monde. |
| Teleport | Non | Non | Non | Error si legacy | Interdit | Teleport est gameplay/runtime map, pas cinematic. |
| StoryStep complete | Non | Non | Non | Error si legacy | Interdit | Progression reste Scene/Storyline systems. |

## 16. Donnees / modele : ce qui existe, ce qui manque, ce qui est reporte

Existe :

- asset canonique `CinematicAsset` ;
- timeline lineaire ;
- step kind enum large ;
- payload generique de step ;
- acteurs requis ;
- metadata et legacy bridge ;
- diagnostics de forme, timeline vide, duplicate ids, duree negative et legacy gameplay step ;
- public contract canonical + scenarioBridge ;
- runtime adapter no-visual.

Manque :

- payloads types par bloc ;
- operations authoring de timeline ;
- diagnostics actor target/dialogue/sound/fx/camera ;
- capability report par host runtime/preview ;
- preview sandbox ;
- host playback visuel ;
- UI Builder.

Reporte :

- migration ScenarioAsset ;
- conversion Cutscene Studio ;
- keyframes avancees ;
- branching ;
- outcomes dialogue ;
- audio avance ;
- pathfinding complexe ;
- save/load mid-cinematic.

## 17. UI cible : principes, structure et limites

Principes UI :

- no-code first ;
- blocs simples, labels humains, pickers guides ;
- validation visible avant preview ;
- aucune saisie d'id technique comme workflow normal ;
- pas de surfaces decoratives qui masquent l'etat ;
- Library pour trouver/organiser, Builder pour assembler une cinematic precise.

Structure cible :

```text
Top bar
Palette blocs gauche
Preview sandbox centrale
Timeline / deroule simplifie
Inspecteur droit
Validation locale
```

Limites UI :

- pas de timeline frame-perfect ;
- pas de courbes Bezier avancees ;
- pas de keyframe editor ;
- pas de media/video import comme concept central ;
- pas de graph ;
- pas de branches ;
- pas de side effects gameplay.

V1-42 doit rester un shell. Les lots de blocs doivent venir ensuite, un petit groupe a la fois.

## 18. Runtime cible : principes, etapes et limites

Principes :

- Scene est proprietaire de l'orchestration ;
- Cinematic est une attente visuelle ;
- le runtime lit des capacites declarees ;
- unsupported doit etre visible en validation ;
- failure interne ne devient pas gameplay ;
- les effets sont temporaires et nettoyables.

Etapes runtime cible :

1. Recevoir `playCinematic(cinematicId)` depuis Scene.
2. Resoudre le `CinematicAsset` canonique.
3. Valider les dependances runtime du host courant.
4. Verrouiller inputs si necessaire.
5. Executer les blocs supportes dans l'ordre.
6. Degrader explicitement ou echouer les blocs unsupported selon severite.
7. Nettoyer les effets temporaires.
8. Retourner `completed`.

Limites :

- aucun write persistant ;
- aucun outcome authorable ;
- aucun lancement de battle ;
- aucun teleport ;
- aucune application World Rule ;
- aucune reprise mid-cinematic tant qu'un contrat save/load n'existe pas.

## 19. Diagnostics et validation cinematic

Diagnostics existants a conserver :

- id manquant ;
- titre manquant ;
- titre technique ;
- duplicate id ;
- timeline vide ;
- duplicate step id ;
- duree negative ;
- legacy gameplay step interdite ;
- refs storyline/chapter/map inconnues ;
- legacy bridge warning/info.

Diagnostics futurs recommandes :

| Diagnostic | Severite | Blocage | Commentaire |
|---|---|---|---|
| step sans type | error | authoring/runtime | Impossible a jouer. |
| acteur requis inconnu | error | runtime | Bloque actor blocks. |
| acteur utilise mais non declare | warning/error | authoring | Error si policy stricte V0. |
| cible camera inconnue | error | preview/runtime | Bloque camera block. |
| dialogue inline vide | error | authoring | Dialogue block invalide. |
| dialogue ref inconnue | error | authoring/runtime | Quand ref supportee. |
| sound ref inconnue | warning/error | preview/runtime | Error si sound block actif. |
| fx ref inconnue | warning/error | preview/runtime | Error si FX obligatoire. |
| step unsupported runtime | warning/error | runtime | Warning en authoring, error au lancement si non degrade. |
| step unsupported preview | warning | preview | Preview degradee mais asset sauve possible. |
| legacy bridge reference | warning/info | authoring | Provenance, pas runtime canonical. |
| gameplay effect detected | error | authoring/runtime | Branch/Battle/Fact/WorldRule/Teleport/StoryStep. |

Classification :

- `error` : bloque authoring final ou runtime ;
- `warning` : autorise draft mais signale une limite ;
- `info` : provenance, capacite ou conseil ;
- `legacy warning` : visible mais non promu.

## 20. Relation avec Scene Builder

Scene Builder decide quand lancer une Cinematic. Cinematic Builder decide ce qui se passe visuellement pendant cette Cinematic. Scene Builder recoit `completed` et continue vers les nodes suivants.

Exemple :

```text
Scene :
Start
-> Dialogue "Le rival arrive"
-> Cinematic "Entree de Lysa"
-> Battle "Lysa"
-> Action setFact rival_battu
-> End
```

La Cinematic "Entree de Lysa" ne lance pas le Battle. Elle montre l'entree, la camera, l'emotion et eventuellement une ligne visuelle. Le Battle reste dans la Scene. Le Fact est ecrit par Action/Consequence apres le Battle, pas par Cinematic.

## 21. Relation avec Dialogue Yarn

Position V0 :

- une cinematic peut afficher une ligne simple cinematic, bornee et sans choix ;
- une reference Dialogue Yarn peut etre etudiee plus tard, mais uniquement comme presentation bornee ;
- une cinematic ne produit aucun outcome Yarn ;
- une cinematic ne contient aucun choix ;
- les choix restent dans Dialogue Yarn et l'orchestration des outcomes reste dans Scene.

`dialogueText` dans `CinematicTimelineStep` est donc acceptable pour une ligne courte, mais ne doit pas ouvrir variables, conditions, branches, localisation avancee ou graph de dialogue dans Builder V0.

## 22. Relation avec Battle

Cinematic peut preparer visuellement un combat : camera sur adversaire, entree d'acteur, fondu, son, expression. Cinematic ne lance pas le combat et ne decide pas victoire/defaite.

Le node Battle de Scene reste responsable de `victory` / `defeat`. Le runtime Battle reste responsable du combat. Les consequences post-combat restent dans Scene.

Toute trace legacy de step `battle` dans une cinematic doit rester error.

## 23. Relation avec Facts / World Rules / Story Steps

Cinematic ne lit pas et n'ecrit pas directement les Facts comme logique gameplay. Elle peut utiliser des refs pour presentation si un futur contrat de preview le permet, mais ne modifie pas l'etat.

World Rules restent une projection visible/active du monde selon l'etat. Cinematic ne les applique pas et ne les remplace pas. Si une apparition durable depend d'une World Rule, la Rule est owner ; la cinematic peut seulement montrer une animation temporaire coherente.

StorylineStep reste progression narrative. Cinematic ne complete pas de step. La progression doit passer par Scene, Storyline systems ou consequences explicites futures.

## 24. Relation avec ScenarioAsset / Cutscene Studio legacy

`ScenarioAsset` est legacy / bridge. Cutscene Studio reste ancien outil ou source transitoire. `CinematicAsset` est canonique.

Reutilisable conceptuellement :

- vocabulaire de sequence ;
- intentions visuelles simples ;
- provenance legacy ;
- certains labels ou resumes ;
- idees de validation anti-gameplay.

Non reutilisable comme canonique :

- graph/scopes Scenario ;
- executor Scenario ;
- commandes gameplay ;
- battle/action/fact/world rule steps ;
- migration implicite ;
- selection normale d'un bridge comme cinematic finale.

Pourquoi `ScenarioRuntimeExecutor` ne doit pas devenir player cinematic : il execute un langage plus large, avec commandes runtime et gameplay. Le player cinematic doit etre un host visuel borne, pas un runtime de scenario recycle.

Futures UI legacy :

- afficher les bridges comme provenance ou sources a revoir ;
- badge legacy explicite ;
- action future de conversion seulement apres contrat dedie ;
- aucun bridge selectionnable comme workflow normal.

## 25. Roadmap post V1-41 recommandee

Pass G — Roadmap post V1-41.

Ordre recommande :

1. `NS-SCENES-V1-42 — Cinematic Builder V0 Shell`
2. `NS-SCENES-V1-43 — Cinematic Timeline Read-only / Step Inspector V0`
3. `NS-SCENES-V1-44 — Cinematic Timeline Authoring Drafts V0`
4. `NS-SCENES-V1-45 — Cinematic Wait/Fade/Camera Basic Blocks V0`
5. `NS-SCENES-V1-46 — Cinematic Actor Movement Block V0`
6. `NS-SCENES-V1-47 — Cinematic Preview Sandbox V0`
7. `NS-SCENES-V1-48 — Cinematic Runtime Visual Playback V0`

Raison de l'ordre : le shell doit d'abord installer la navigation et l'espace de travail sans mutation risquee. Le read-only step inspector permet de verifier le modele existant. L'authoring drafts doit ensuite fournir les operations minimales. Les blocs wait/fade/camera sont moins dangereux que le mouvement acteur. La preview sandbox doit venir avant le runtime visuel complet pour tester les dependencies sans impacter gameplay. Le runtime visuel vient en dernier.

Prochain lot exact recommande : `NS-SCENES-V1-42 — Cinematic Builder V0 Shell`.

## 26. Mise a jour des roadmaps

Roadmaps modifiees :

```text
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

Mise a jour realisee :

- V1-41 ajoute comme DONE ;
- resume Builder/Runtime ajoute ;
- limites explicites ajoutees ;
- prochain lot exact mis a jour vers V1-42 ;
- rappel que V1-41 n'a pas code le Builder.

## 27. Commandes executees

Commandes Gate 0 :

```text
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 15
```

Commandes d'audit :

```text
rg --files -g 'AGENTS.md' -g 'pokemap_roadmap_mecaniques_fangame.md' -g 'pubspec.yaml'
wc -l AGENTS.md agent_rules.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md reports/narrativeStudio/scenes/ns_scenes_v1_36_cinematic_v1_contract_bridge_decision.md reports/narrativeStudio/scenes/ns_scenes_v1_37_cinematic_asset_core_model_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_38_cinematics_library_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_39_cinematic_scene_builder_picker_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_40_cinematic_runtime_adapter_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_40_bis_cinematic_runtime_adapter_evidence_closure.md
rg -n "^(class|enum|typedef)|Cinematic|Scenario|Timeline|Step|fromJson|toJson|copyWith|diagnos|legacy|bridge|duration|requiredActors|completed" packages/map_core/lib/src/models/cinematic_asset.dart packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart
rg -n "SceneCinematicRuntimeAwaitableAdapter|SceneRuntimeExecutionCallbacks|playCinematic|_executeScene|_runScene|applyConsequence|SceneRuntimeExecutor" packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
git diff -- reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

Commandes de validation documentaire :

```text
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff --name-only -- packages/map_core packages/map_runtime packages/map_editor packages/map_gameplay packages/map_battle examples
rg -n "ma""el|ma""ël|ly""sa|port_""brisants|bourg_""selbrume|pha""re|ma""rais" reports/narrativeStudio/scenes/ns_scenes_v1_41_cinematic_builder_v0_scope_runtime_playback_contract.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

Pas de `dart test`, `flutter test`, `dart analyze` ou `flutter analyze` lance : V1-41 est documentaire et ne modifie aucun package.

## 28. Evidence Pack

### 28.1 Gate 0 complet

Gate 0 reproduit en section 2.

### 28.2 Liste des fichiers lus

Liste reproduite en section 3.

### 28.3 Rapport courant

Ce fichier est le rapport courant :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_41_cinematic_builder_v0_scope_runtime_playback_contract.md
```

### 28.4 Hunks complets des roadmaps modifiees

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index 62651d9e..7faec7f8 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -9,7 +9,7 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
 ## Prochain lot exact recommande
 
 ```text
-NS-SCENES-V1-41 — Cinematic Builder V0 Scope / Runtime Playback Contract
+NS-SCENES-V1-42 — Cinematic Builder V0 Shell
 ```
 
 ## Principes
@@ -74,6 +74,7 @@ NS-SCENES-V1-41 — Cinematic Builder V0 Scope / Runtime Playback Contract
 | NS-SCENES-V1-38 | Cinematics Library V0 | editor / read-model | Rendre les CinematicAsset visibles, navigables et diagnostiques dans Narrative Studio. | Pas de Builder V2, pas de timeline editor, pas de runtime cinematic, pas de migration legacy. | workspace/library Cinematics, liste, selection, metadata authoring, diagnostics/usages, overview/sidebar. | DONE : read model pur, Library editor, bridges legacy explicites, tests widget/read model, analyze editor/core cible, visual gate. | Confondre library avec Builder ; reactiver Cutscene Studio comme canonique. | DONE : cinematic assets visibles avant authoring avance, sans runtime ni migration. | V1-37. |
 | NS-SCENES-V1-39 | Cinematic Scene Builder Picker V0 | core / editor | Ajouter/editer un `CinematicNode` depuis un picker `CinematicAsset` canonique et rendre `cinematic.completed` authorable. | Pas de Builder V2, pas de timeline editor, pas de runtime cinematic, pas de migration legacy, pas de bridge selectionnable en workflow normal. | operations Scene cinematic, picker/inspector Scene Builder, diagnostics, tests core/editor, visual gate. | DONE : canonical-only, bridge legacy warning, completed port, tests/analyze, screenshot. | Promouvoir les bridges Scenario comme choix normal ; laisser entrer des cinematicId libres. | DONE : CinematicNode honnete, editable et connectable sans fake ref. | V1-38. |
 | NS-SCENES-V1-40 | Cinematic Runtime Adapter V0 | runtime / integration | Remplacer l'ack cinematic bridge par un adapter awaitable qui resout un `CinematicAsset` canonique, attend une completion reelle et retourne `completed`. | Pas de Builder V2, pas de timeline editor UI, pas de migration ScenarioAsset, pas de playback visuel complet, pas d'effets gameplay depuis cinematic. | adapter cinematic runtime, result/request/player V0, wiring PlayableMapGame, tests hook no partial writes, rapport. | DONE : canonical awaitable, bridge legacy explicite, unknown failed, consequences post-cinematic commit apres completion, tests/analyze. | Continuer a ack immediatement ; traiter scenarioBridge comme canonical ; laisser une cinematic ecrire le monde. | DONE : pont runtime propre Scene -> CinematicAsset -> completed. | V1-39. |
+| NS-SCENES-V1-41 | Cinematic Builder V0 Scope / Runtime Playback Contract | doc / architecture-review | Cadrer le futur Builder V0 et le futur contrat Runtime Playback avant de coder l'UI, la timeline, les blocs authorables ou le player visuel. | Pas de code Dart, pas de widget, pas de timeline editor, pas de playback visuel, pas de migration ScenarioAsset, pas d'effet gameplay cinematic. | rapport V1-41, roadmaps. | DONE : rapport contractuel, capability matrix, taxonomie blocs, frontieres anti-scope, `git diff --check`. | Coder le Builder trop tot ; refaire ScenarioAsset ; ouvrir branches/failures authorables ; laisser Cinematic ecrire le monde. | DONE : Builder V0 = assembleur lineaire sandboxe ; Runtime Playback V0/V1 = lecture bornee sans gameplay effect ; prochain lot shell seulement. | V1-40. |
 
 ## Options comparees
 
@@ -656,6 +657,18 @@ Limites : pas de Builder V2, pas de timeline editor UI, pas de playback visuel c
 
 Prochain lot exact : `NS-SCENES-V1-41 — Cinematic Builder V0 Scope / Runtime Playback Contract`.
 
+## Mise a jour V1-41
+
+Statut : `NS-SCENES-V1-41 — Cinematic Builder V0 Scope / Runtime Playback Contract` est DONE.
+
+Decision : le futur Cinematic Builder V0 reste un assembleur de blocs cinematic simples, ordonnes et no-code, ouvert depuis la Cinematics Library. Il n'est ni Scene Builder, ni Dialogue Studio, ni Cutscene Studio legacy, ni timeline frame-perfect. Le futur Runtime Playback reste un host borne qui lit la sequence, resolve acteurs/camera/dialogue/audio/FX selon capacites, retourne `completed` et ne produit aucun effet gameplay.
+
+Scope realise : rapport documentaire V1-41, specification Builder V0, specification Runtime Playback V0/V1, taxonomie des blocs, capability matrix, diagnostics futurs, frontieres Scene/Dialogue/Battle/Facts/World Rules/ScenarioAsset et roadmap stricte V1-42 a V1-48.
+
+Limites : aucun Builder code, aucune timeline editor, aucun widget, aucun modele, aucun runtime visuel et aucun package modifie. V1-41 n'a pas demarre V1-42.
+
+Prochain lot exact : `NS-SCENES-V1-42 — Cinematic Builder V0 Shell`.
+
 ## Selbrume golden slice
 
 Avant le golden slice, il faut au minimum :
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index 7c1b6152..6f807aa1 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -95,14 +95,15 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-38 — Cinematics Library V0 | DONE | Library Narrative Studio pour `CinematicAsset` canoniques : read model pur, liste/selection, metadata authoring, diagnostics/usages, bridge legacy explicite et overview aligne, sans Builder V2 ni runtime cinematic. |
 | NS-SCENES-V1-39 — Cinematic Scene Builder Picker V0 | DONE | Scene Builder peut ajouter/editer un `CinematicNode` via picker `CinematicAsset` canonique, exposer/connecter `cinematic.completed`, afficher details/diagnostics et signaler les bridges legacy sans les promouvoir. |
 | NS-SCENES-V1-40 — Cinematic Runtime Adapter V0 | DONE | Runtime Scene V1 : `playCinematic(cinematicId)` resout un `CinematicAsset` canonique, passe par un adapter awaitable/player V0, attend la completion reelle, retourne `completed`, preserve les bridges legacy explicites et bloque les refs inconnues sans commit partiel. |
+| NS-SCENES-V1-41 — Cinematic Builder V0 Scope / Runtime Playback Contract | DONE | Lot documentaire : contrat strict du futur Builder V0 comme assembleur no-code de sequences moteur simples, lineaires et sandboxees, plus contrat Runtime Playback V0/V1 borne, sans Builder code, sans timeline editor, sans playback visuel et sans effet gameplay depuis Cinematic. |
 
 ## Prochain lot recommande
 
-`NS-SCENES-V1-41 — Cinematic Builder V0 Scope / Runtime Playback Contract`
+`NS-SCENES-V1-42 — Cinematic Builder V0 Shell`
 
-Raison : V1-40 ferme le trou runtime awaitable. Le prochain verrou est de cadrer le vrai playback/builder cinematic sans transformer `CinematicAsset` en `ScenarioAsset`, sans timeline editor trop large et sans effets gameplay dans la cinematic.
+Raison : V1-41 a borne le Builder et le playback avant code. Le prochain verrou est de creer seulement le shell du Builder depuis la Library, avec navigation, structure d'ecran et etats vides/diagnostics, sans edition de steps, sans timeline authoring et sans playback visuel.
 
-Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion, puis Dialogue/Battle Ports Authoring V0, puis Runtime Executor MVP, puis Evidence & Review Hardening, puis World Rules Map Editor Integration V0, puis Golden Slice Selbrume Scene/Event Prep, puis Event to Scene Runtime Hook V0, puis Scene Consequence Contract Prep, puis Scene Consequence Model V0, puis Scene Consequence Runtime Write V0, puis Battle Runtime Outcome Adapter V0, puis Dialogue Runtime Awaitable Adapter V0, puis Golden Slice Runtime Smoke V0, puis StorylineStep to Scene Link, puis Scene Node Payload Editing V0, puis Scene Node Deletion UX V0, puis Scene Consequence Authoring UI V0, puis Scene V1 Beta Readiness Checkpoint, puis Runtime State Persistence Gate V0, puis World Rules Runtime Projection Hook V0, puis Facts & World Rules Manager UI V0, puis Cinematic V1 Contract / Bridge Decision, puis CinematicAsset Core Model V0, puis Cinematics Library V0, puis Cinematic Scene Builder Picker V0, puis Cinematic Runtime Adapter V0, puis Cinematic Builder V0 Scope / Runtime Playback Contract.
+Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion, puis Dialogue/Battle Ports Authoring V0, puis Runtime Executor MVP, puis Evidence & Review Hardening, puis World Rules Map Editor Integration V0, puis Golden Slice Selbrume Scene/Event Prep, puis Event to Scene Runtime Hook V0, puis Scene Consequence Contract Prep, puis Scene Consequence Model V0, puis Scene Consequence Runtime Write V0, puis Battle Runtime Outcome Adapter V0, puis Dialogue Runtime Awaitable Adapter V0, puis Golden Slice Runtime Smoke V0, puis StorylineStep to Scene Link, puis Scene Node Payload Editing V0, puis Scene Node Deletion UX V0, puis Scene Consequence Authoring UI V0, puis Scene V1 Beta Readiness Checkpoint, puis Runtime State Persistence Gate V0, puis World Rules Runtime Projection Hook V0, puis Facts & World Rules Manager UI V0, puis Cinematic V1 Contract / Bridge Decision, puis CinematicAsset Core Model V0, puis Cinematics Library V0, puis Cinematic Scene Builder Picker V0, puis Cinematic Runtime Adapter V0, puis Cinematic Builder V0 Scope / Runtime Playback Contract, puis Cinematic Builder V0 Shell.
 
 Note : l'overview n'affiche plus `Facts — necessite un modele`; Facts et Regles du monde pointent maintenant vers des workspaces actifs.
 
@@ -240,6 +241,18 @@ Limites : pas de Builder V2, pas de timeline editor, pas de playback visuel comp
 
 Prochain lot exact : `NS-SCENES-V1-41 — Cinematic Builder V0 Scope / Runtime Playback Contract`.
 
+## Mise a jour V1-41
+
+Statut : `NS-SCENES-V1-41 — Cinematic Builder V0 Scope / Runtime Playback Contract` est DONE.
+
+Decision : le futur Cinematic Builder V0 est borne comme assembleur no-code de sequences moteur simples, lineaires, ordonnees et sandboxees. Le futur Runtime Playback V0/V1 lit ces sequences via un host borne, retourne seulement `completed` a la Scene, signale les failures internes sans port authorable et ne peut pas ecrire de Fact, lancer de Battle, appliquer de World Rule, teleporter ou completer une StorylineStep.
+
+Scope realise : rapport contractuel V1-41, audit des lots V1-36 a V1-40, taxonomie des blocs camera/deplacement acteur/dialogue/FX/son/fondu/attente, capability matrix Builder/Runtime/Preview/Validation, frontieres Scene/Cinematic/Dialogue/Battle/Facts/World Rules/ScenarioAsset et roadmap post V1-41.
+
+Limites : aucun code produit, aucun modele Dart, aucun widget Flutter, aucun Builder UI, aucun timeline editor, aucun playback visuel, aucune migration legacy, aucune donnee produit et aucun package modifie. V1-41 n'a pas code le Builder.
+
+Prochain lot exact : `NS-SCENES-V1-42 — Cinematic Builder V0 Shell`.
+
 ## Mise a jour V1-30-bis
 
 Statut : `NS-SCENES-V1-30-bis — Scene Node Deletion UX V0` est DONE.
```

### 28.5 Sortie `git diff --check`

```text
<vide>
```

### 28.6 Sortie `git diff --stat`

```text
 .../scenes/road_map_scene_builder_authoring.md        | 15 ++++++++++++++-
 reports/narrativeStudio/scenes/road_map_scenes.md     | 19 ++++++++++++++++---
 2 files changed, 30 insertions(+), 4 deletions(-)
```

### 28.7 Sortie `git diff --name-only`

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

### 28.8 Sortie `git status --short --untracked-files=all` final

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_41_cinematic_builder_v0_scope_runtime_playback_contract.md
```

### 28.9 Checks anti-scope

Commande : `git diff --name-only -- packages/map_core packages/map_runtime packages/map_editor packages/map_gameplay packages/map_battle examples`

```text
<vide>
```

Commande : `rg -n "ma""el|ma""ël|ly""sa|port_""brisants|bourg_""selbrume|pha""re|ma""rais" reports/narrativeStudio/scenes/ns_scenes_v1_41_cinematic_builder_v0_scope_runtime_playback_contract.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

```text
<vide>
```

Interpretation anti-scope : aucun package n'apparait. La recherche anti-contenu produit ne remonte aucune donnee produit ajoutee par V1-41.

### 28.10 Auto-review critique

Auto-review complete en section 29.

## 29. Auto-review critique

Pass H — Review critique finale.

1. Est-ce que V1-41 a modifie du code produit ? Non. Aucun fichier sous `packages/` ou `examples/` n'est modifie.
2. Est-ce que V1-41 a demarre le Builder UI ? Non. Le Builder est seulement cadre.
3. Est-ce que V1-41 a cree un timeline editor ? Non.
4. Est-ce que V1-41 a change le runtime ? Non.
5. Est-ce que V1-41 a promu ScenarioAsset ? Non. `ScenarioAsset` reste legacy/bridge.
6. Est-ce que le contrat garde Cinematic lineaire ? Oui. La sequence reste ordonnee et sans graph.
7. Est-ce que le contrat interdit les effets gameplay dans Cinematic ? Oui. Branch, Battle, Fact write, World Rule apply, teleport et StoryStep complete sont interdits.
8. Est-ce que le document distingue Builder V0, Runtime Playback et Preview Sandbox ? Oui. Builder assemble, Runtime lit, Preview sandbox valide/visualise sans gameplay.
9. Est-ce que la roadmap post V1-41 est decoupee en lots raisonnables ? Oui. Shell, read-only, authoring drafts, blocs de base, mouvement acteur, preview, puis runtime visuel.
10. Quel est le prochain lot exact recommande ? `NS-SCENES-V1-42 — Cinematic Builder V0 Shell`.
11. Quelles incertitudes restent a trancher ? Le format final des payloads types par bloc, le niveau exact de degradation no-op vs failure pour audio/FX, le contrat save/load mid-cinematic, et la forme precise d'une reference Dialogue Yarn sans outcome.

Pass H — Review critique finale : le risque principal restant est de coder trop de capacites dans V1-42. Le shell doit rester un contenant navigable et diagnostique, pas le debut cache de l'authoring timeline. Le second risque est de traiter le player no-visual comme support runtime complet ; il est seulement une preuve awaitable. Le troisieme risque est le dialogue : une ligne cinematic simple est acceptable, mais tout choix ou outcome doit repartir vers Dialogue Yarn / Scene.

## 30. Verdict final

V1-41 peut etre propose comme DONE si les validations finales de la section 28 restent propres.

Statut propose : `DONE`.

Prochain lot exact : `NS-SCENES-V1-42 — Cinematic Builder V0 Shell`.

Limites finales : aucun test Dart/Flutter lance car le lot est documentaire ; aucun code produit modifie ; aucun package modifie ; V1-42 n'est pas demarre.
