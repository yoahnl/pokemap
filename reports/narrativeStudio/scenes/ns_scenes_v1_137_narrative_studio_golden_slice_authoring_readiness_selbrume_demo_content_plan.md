# NS-SCENES-V1-137 — Narrative Studio Golden Slice Authoring Readiness / Selbrume Demo Content Plan

## 1. Résumé exécutif

V1-137 sort volontairement du Cinematic Builder V1. Le Builder est considéré fermé après V1-136 et V1-136-bis ; ce lot ne le rouvre pas et ne modifie aucun code produit.

Le résultat de l'audit est clair : PokeMap dispose maintenant d'un socle Narrative Studio exploitable pour cadrer une golden slice Selbrume, mais les données Selbrume actuelles ne sont pas encore prêtes pour une écriture directe de démo narrative jouable.

Les systèmes sont présents ou documentés : maps, Scene V1, Storylines, CinematicAsset, dialogue Yarn, facts, world rules, battle handoff, save/reload et diagnostics. En revanche, le projet Selbrume courant contient surtout des éléments prototypes : 10 maps, 1 scène de test, 1 cinématique `UwU`, 2 dialogues Yarn dont un placeholder, 1 fact de test, 0 world rule et aucun battle canonique dans `project.json`.

Décision : V1-137 est DONE comme plan de readiness. Le prochain lot recommandé doit être un audit d'inventaire et de gaps de contenu, pas une écriture de contenu immédiate.

## 2. Verdict de readiness

Verdict V1-137 :

```text
Golden slice narrative Selbrume : NOT_READY_FOR_DIRECT_AUTHORING
Narrative Studio systems : PARTIAL_READY
Content inventory : REQUIRES_AUDIT
Next lot : NS-SCENES-V1-138 — Selbrume Golden Slice Content Inventory / Asset Gap Audit
```

Le chemin joueur peut être cadré, mais il ne doit pas encore être authoré en dur. Les IDs de la bible Selbrume, les maps réelles, les PNJ, les dialogues, les scenes et les règles de monde doivent être réconciliés dans un inventaire V1-138.

## 3. Rappel : Cinematic Builder V1 fermé

V1-136 a conclu que le Cinematic Builder V1 était closable avec réserves non bloquantes. V1-136-bis a ensuite corrigé les attentes widget legacy sans modifier le produit.

La séquence caméra/cinematic reste fermée :

- CinematicAsset authoring V1 disponible.
- Cinematic Builder V1 fermé.
- Preview editor-only disponible.
- Camera V1 fermée comme cadrage editor-only, sans runtime camera.
- Emotes, fade, actorMove, manual path, walking preview et timeline sont stabilisés côté Builder.

V1-137 ne crée donc ni bloc cinematic, ni UI Builder, ni Visual Gate cinematic.

## 4. Objectif golden slice Selbrume

Objectif produit : démontrer une boucle narrative courte et jouable dans Selbrume, avec un vrai enchaînement no-code :

```text
Map -> Event/PNJ -> Scene -> Dialogue -> Cinematic -> Battle -> Consequence -> Fact -> World Rule -> Storyline -> Save/reload
```

La démo visée doit durer environ 10 à 20 minutes et prouver que PokeMap peut faire autre chose que montrer des outils isolés. Elle doit raconter un bout cohérent de "Les Brumes de Selbrume" :

- Maël donne la mission.
- Le joueur rejoint le port.
- Lysa confronte le joueur.
- Une scène ou cinématique pose la brume du phare.
- Un combat rival démarre.
- Le résultat écrit des facts.
- Les dialogues et la présence des PNJ changent.
- Save/reload conserve l'état.

## 5. Chemin joueur proposé

Chemin joueur proposé pour la première golden slice :

1. Le joueur commence dans le bourg de Selbrume.
2. Il parle à Maël, qui introduit la brume, donne la mission et oriente vers le port.
3. La Scene `scene_intro_mael_mission` démarre depuis l'interaction PNJ.
4. Le dialogue `dlg_mael_intro_mission` présente le conflit et se termine en écrivant `fact_mael_mission_received`.
5. Le Story Step `step_receive_mission` est complété.
6. Une World Rule rend Lysa disponible au port ou active son interaction.
7. Le joueur va vers la zone portuaire candidate.
8. L'interaction avec Lysa lance `scene_port_lysa_rival`.
9. Un dialogue court `dlg_lysa_port_prebattle` installe le conflit.
10. Une cinématique courte `cin_port_mist_signal` montre la brume, Lysa et le port.
11. Le combat `battle_lysa_port_01` démarre.
12. Victoire ou défaite écrit `battle:battle_lysa_port_01:victory` ou `battle:battle_lysa_port_01:defeat`.
13. La scène reprend et écrit `fact_lysa_battle_resolved`.
14. Le Story Step `step_rival_battle` est complété.
15. Une World Rule change le dialogue de Lysa et de Maël.
16. Le joueur sauvegarde, recharge, puis retrouve le bon dialogue post-combat.

Ce chemin est démontrable en théorie avec les systèmes documentés, mais pas directement authorable avec les données Selbrume actuelles sans inventaire et réconciliation.

## 6. Maps nécessaires

| Map | Statut | Rôle narratif | Events attendus | PNJ attendus | Dépendances | Risques |
|---|---|---|---|---|---|---|
| `Selbrume` | EXISTS / NEEDS_REVIEW | Hub actuel probable pour le bourg. | Interaction Maël, départ joueur, accès port/route. | Maël ou substitut. | Vérifier si la map correspond à `map_bourg_selbrume`. | ID non canonique par rapport à la bible. |
| `route 1` | EXISTS / NEEDS_REVIEW | Liaison ou première route vers le port/marais. | Passage, éventuelle rencontre, signe ou checkpoint. | Grant existe comme entité. | Vérifier usage narratif réel. | Route 1 n'est pas explicitement Port des Brisants. |
| `lab` | EXISTS / OPTIONAL | Lieu possible de Maël/starter. | Interaction mission/starter si choisi. | Maël. | Décider si Maël est dans le lab ou dehors. | Map vide côté events. |
| `pokémon center` | EXISTS / OPTIONAL | Heal minimal de démo. | Interaction soin. | Soigneur. | Hors strict narrative si la démo reste courte. | Pas de scène/fact nécessaire. |
| `pub` | EXISTS / OPTIONAL | Lieu social/lore. | Dialogue secondaire. | PNJ local. | Peut attendre V2. | Risque de distraire du chemin critique. |
| `map_port_brisants` | MISSING / REQUIRED_BY_STORY | Port canonique de Lysa. | Interaction Lysa, signal brume. | Lysa, pêcheur. | À mapper sur une map existante ou créer plus tard. | Bloquant pour contenu fidèle si aucun substitut n'est validé. |
| `map_marais_salants` | MISSING / V2 | Chapitre 2. | Enquête, indices. | Mado. | Hors golden slice 10-20 min. | Ne pas inclure dans V1. |
| `map_phare_*` | MISSING / V2 | Final du récit complet. | Dungeon/phare. | Yvon, boss. | Hors première golden slice. | Ne doit pas gonfler V1-138. |

Décision : V1-138 doit d'abord choisir si `Selbrume` couvre le bourg + port ou si un Port des Brisants dédié manque réellement.

## 7. Events nécessaires

Events minimaux :

| Event | Source | Résultat attendu | Statut actuel | Gap |
|---|---|---|---|---|
| `event_mael_intro` | Interaction PNJ Maël. | Lance `scene_intro_mael_mission`. | MISSING. | Maël n'est pas encore réconcilié avec les entités de map. |
| `event_port_lysa` | Interaction PNJ Lysa. | Lance `scene_port_lysa_rival`. | MISSING. | Lysa n'est pas présente comme entité canonique dans les maps auditées. |
| `event_port_signal` | Entrée zone ou interaction Lysa. | Lance cinématique brume/port. | MISSING. | Nécessite map port ou substitut. |
| `event_post_battle_dialogue` | Interaction Lysa après combat. | Dialogue conditionnel victory/defeat. | MISSING. | Dépend facts/world rules. |
| `event_return_mael` | Retour vers Maël. | Maël réagit au combat résolu. | MISSING. | Dépend save/reload et world rules. |

Les maps JSON auditées contiennent `events: 0` partout. L'eventing golden slice doit donc être planifié comme contenu à authorer, pas comme contenu déjà disponible.

## 8. Scenes nécessaires

| Scene | Objectif | Déclencheur | Nodes attendus | Liens | Statut actuel | Gap |
|---|---|---|---|---|---|---|
| `scene_intro_mael_mission` | Introduire Selbrume et la mission. | `event_mael_intro`. | Start, Dialogue, Set Fact, Complete Step, End. | `dlg_mael_intro_mission`, `fact_mael_mission_received`, `step_receive_mission`. | MISSING. | À authorer après inventaire. |
| `scene_port_lysa_rival` | Introduire Lysa et le conflit du port. | `event_port_lysa`. | Start, Dialogue, Cinematic, Battle, Branch, Consequence, End. | `dlg_lysa_port_prebattle`, `cin_port_mist_signal`, `battle_lysa_port_01`. | MISSING. | À authorer après battle/dialogue inventory. |
| `scene_lysa_post_battle` | Poser les conséquences. | Continuation post-battle ou interaction. | Condition victory/defeat, Set Fact, Complete Step, Dialogue. | `fact_lysa_battle_resolved`, `step_rival_battle`. | MISSING. | Nécessite outcome flags et rule projection. |
| `scene_demo_exit` | Fin propre de slice. | Step rival terminé. | Dialogue, outcome, optional message. | Storyline main. | MISSING. | Peut rester simple. |
| `scene_test` | Prototype existant. | Non canonique. | Start, End, Battle grant, Yarn `g`, Cinematic `UwU`. | `grant`, `g`, `cinematic_uwu`. | EXISTS / PROTOTYPE. | Ne doit pas être utilisé comme contenu final sans renommage/revue. |

## 9. Cinematics nécessaires

| CinematicAsset | Rôle narratif | Actors | Stage context | Blocs nécessaires | Durée cible | Statut actuel | Gap |
|---|---|---|---|---|---|---|---|
| `cin_port_mist_signal` | Montrer la brume au port et cadrer Lysa. | Joueur, Lysa, foule/pêcheur. | Port ou zone portuaire validée. | Caméra focus, actorMove, emote, fade, wait. | 5-10 s. | MISSING. | À authorer après choix de map/repères. |
| `cin_mael_points_to_port` | Optionnel : Maël oriente vers le port. | Joueur, Maël. | Bourg/lab. | actorFace, camera focus, wait. | 3-5 s. | MISSING / OPTIONAL. | Peut être remplacé par dialogue. |
| `cinematic_uwu` | Prototype de capacité Builder. | Acteur, Jean. | Stage Context existant. | actorMove, actorFace, actorEmote, camera. | 11 steps. | EXISTS / PROTOTYPE. | Pas canonique Selbrume. |

Le Cinematic Builder V1 permet de produire ces assets, mais V1-137 ne les crée pas.

## 10. Dialogues nécessaires

| Dialogue | PNJ | Intention narrative | Entrée | Sortie | Statut actuel | Gap |
|---|---|---|---|---|---|---|
| `dlg_mael_intro_mission` | Maël. | Présenter brume, mission, direction port. | Interaction Maël initiale. | `fact_mael_mission_received`. | MISSING. | À écrire. |
| `dlg_mael_after_lysa` | Maël. | Réagir au combat résolu. | Retour après `fact_lysa_battle_resolved`. | Fin de démo ou prochain objectif. | MISSING. | À écrire. |
| `dlg_lysa_port_prebattle` | Lysa. | Confronter le joueur et lancer combat. | Interaction Lysa avant combat. | Battle handoff. | MISSING. | À écrire. |
| `dlg_lysa_post_victory` | Lysa. | Respect après victoire. | Flag victory. | Dialogue post-combat. | MISSING. | À écrire. |
| `dlg_lysa_post_defeat` | Lysa. | Défaite acceptée sans bloquer la démo. | Flag defeat. | Dialogue post-combat. | MISSING. | À écrire. |
| `g.yarn` | Prototype. | Placeholder. | Scene test. | Aucun contenu final. | EXISTS / PLACEHOLDER. | À ignorer ou remplacer. |
| `test.yarn` | Marc/Léa. | Dialogue météo hors Selbrume canonique. | Prototype. | Branches Yarn. | EXISTS / NEEDS_REVIEW. | Peut servir d'exemple technique, pas de contenu Maël/Lysa. |

## 11. Battles nécessaires

| Battle | Adversaire | Contexte | Victory | Defeat | Statut battle existant | Gap |
|---|---|---|---|---|---|---|
| `battle_lysa_port_01` | Lysa. | Premier combat rival au port. | Set `battle:battle_lysa_port_01:victory`, puis `fact_lysa_battle_resolved`. | Set `battle:battle_lysa_port_01:defeat`, continuer la démo sans softlock. | MISSING. | Aucun battle canonique Selbrume dans `project.json`. |
| `grant` / scene test | Grant. | Prototype battle node dans `scene_test`. | Non défini pour Selbrume. | Non défini pour Selbrume. | EXISTS AS TRAINER / PROTOTYPE. | Ne remplace pas Lysa. |

Le système battle/readiness est documenté dans les rapports NS-GS, mais les données de démo Lysa ne sont pas présentes dans le projet courant.

## 12. Facts / World Rules nécessaires

Facts minimaux :

| Fact | Label no-code | Source | Target | Effet attendu | Statut actuel | Gap |
|---|---|---|---|---|---|---|
| `fact_mael_mission_received` | Mission de Maël reçue. | Scene Maël. | Storyline + Lysa availability. | Débloque objectif port. | MISSING. | À authorer. |
| `fact_port_reached` | Port atteint. | Event entrée port. | Storyline. | Active Lysa ou cinématique. | MISSING. | À authorer si port dédié. |
| `fact_lysa_battle_started` | Combat Lysa lancé. | Scene Lysa. | Diagnostics/progression. | Trace le début du combat. | MISSING / OPTIONAL. | À décider. |
| `fact_lysa_battle_resolved` | Combat Lysa résolu. | Outcome battle. | World rules/dialogues. | Change Lysa/Maël. | MISSING. | À authorer. |
| `fact_lysa_victory` | Lysa battue. | Outcome victory. | Dialogue Lysa. | Variante victoire. | MISSING. | À authorer. |
| `fact_lysa_defeat` | Défaite contre Lysa. | Outcome defeat. | Dialogue Lysa. | Variante défaite. | MISSING. | À authorer. |
| `fact_test` | test. | Prototype. | Aucun effet final. | Présence de test. | EXISTS / PROTOTYPE. | Ne couvre pas la démo. |

World Rules minimales :

| World Rule | Effet | Dépendance | Statut actuel | Gap |
|---|---|---|---|---|
| `wr_show_lysa_before_battle` | Lysa interactive avant combat. | `fact_mael_mission_received`. | MISSING. | `worldRules` est vide. |
| `wr_lysa_post_battle_dialogue` | Dialogue Lysa change après combat. | `fact_lysa_battle_resolved` + victory/defeat. | MISSING. | À authorer. |
| `wr_mael_after_lysa` | Maël réagit au retour. | `fact_lysa_battle_resolved`. | MISSING. | À authorer. |
| `wr_port_access` | Accès ou guidance vers port. | `fact_mael_mission_received`. | MISSING / OPTIONAL. | À décider selon map. |

## 13. Storyline / progression

Le projet contient déjà la Storyline `story_main_brume_phare` avec le chapitre `Le port` et les steps clés :

- `step_intro_selbrume`
- `step_receive_mission`
- `step_go_to_port`
- `step_rival_battle`

Ces steps correspondent bien au chemin golden slice. Le gap n'est donc pas la structure de progression, mais son raccord concret avec les scenes/events/facts :

- aucun event Maël canonique n'est lié ;
- aucune scene Maël/Lysa canonique n'existe ;
- aucun dialogue Maël/Lysa canonique n'existe ;
- aucun battle Lysa canonique n'existe ;
- aucune world rule ne projette encore ces facts dans le monde.

Décision : conserver cette storyline comme squelette V1, mais la réconcilier avec les assets réels en V1-138.

## 14. Runtime / save-reload attendu

Comportement runtime attendu pour la future démo :

1. Interaction PNJ lance Scene V1.
2. Scene lance Dialogue Yarn.
3. Scene peut lancer CinematicAsset.
4. Scene peut lancer Battle.
5. Battle outcome écrit un flag déterministe.
6. Scene reprend et écrit facts/steps.
7. World Rules changent dialogue/présence/interactivité.
8. Save/reload conserve facts, battle flags, completed steps et état d'event consommé.

Les rapports NS-GS existants indiquent que plusieurs briques sont déjà caractérisées, notamment NPC interaction -> scene, scene -> battle, outcome flags et save/load de progression. V1-137 ne relance pas ces tests car le lot est documentaire et ne modifie pas le code.

Limite importante : la preuve d'une démo Selbrume réelle reste à produire plus tard avec des données Selbrume authorées et un smoke runtime dédié.

## 15. Matrice de readiness

| Domaine | État actuel | Besoin golden slice | Gap | Gravité | Lot recommandé | Décision |
|---|---|---|---|---|---|---|
| Maps Selbrume | PARTIAL | Bourg + port/substitut validés. | IDs bible/projet à réconcilier. | MAJOR | V1-138 | REQUIRES_AUDIT |
| Map events | MISSING | Maël, Lysa, port, post-battle. | `events: 0` dans les maps auditées. | BLOCKER | V1-139 | AUTHOR_CONTENT |
| Scene V1 graph | PARTIAL | Scenes Maël/Lysa/battle/consequence. | Une seule `scene_test`. | BLOCKER | V1-139 | AUTHOR_CONTENT |
| Dialogue | PARTIAL | Dialogues Maël/Lysa finalisés. | Deux Yarn prototypes, pas Maël/Lysa. | BLOCKER | V1-140 | AUTHOR_CONTENT |
| CinematicAsset | PARTIAL | Cinématique port/brume. | `cinematic_uwu` prototype uniquement. | MAJOR | V1-140 | AUTHOR_CONTENT |
| Battle | PARTIAL | Battle Lysa canonique. | Trainer `grant`, pas Lysa battle. | BLOCKER | V1-140 | AUTHOR_CONTENT |
| Facts | PARTIAL | Facts mission/combat/outcome. | `fact_test` uniquement. | BLOCKER | V1-139 | AUTHOR_CONTENT |
| World Rules | MISSING | Dialogues/présence conditionnels. | `worldRules` vide. | BLOCKER | V1-139 | AUTHOR_CONTENT |
| Storyline links | PARTIAL | Steps liés aux scenes/facts. | Squelette OK, liens manquants. | MAJOR | V1-139 | AUTHOR_CONTENT |
| Runtime Event -> Scene | READY | Déclenchement interaction PNJ. | Besoin d'un cas Selbrume. | MAJOR | V1-141 | USE_AS_IS |
| Consequences runtime | READY / PARTIAL | setFact, battle outcome, completed step. | Preuve Selbrume future. | MAJOR | V1-141 | USE_AS_IS |
| Save / reload | READY / PARTIAL | Persistance after battle. | Smoke Selbrume futur. | MAJOR | V1-141 | USE_AS_IS |
| Preview authoring | READY | Builder/Scene/Cinematic authoring. | Pas de blocage produit identifié. | NONE | V1-138 | USE_AS_IS |
| Diagnostics | PARTIAL | Validator golden slice. | Validation contenu Selbrume absente. | MAJOR | V1-142 | REQUIRES_AUDIT |
| Visual Gates | READY for tools | Visual final démo future. | Pas de Visual Gate Selbrume golden slice. | MINOR | V1-142 | AUTHOR_CONTENT |
| Manual demo checklist | PARTIAL | Checklist de test jouable. | Checklist beta existe mais pas check final. | MAJOR | V1-142 | AUTHOR_CONTENT |
| Content writing | MISSING | Dialogues, scenes, cinematic, battle. | Contenu final absent. | BLOCKER | V1-139/V1-140 | AUTHOR_CONTENT |

## 16. Gaps et risques

Gaps bloquants :

- Les maps réelles ne sont pas alignées avec les IDs narratifs de `selbrume.md`.
- Aucun event map canonique Maël/Lysa n'existe dans les maps auditées.
- Les scenes disponibles sont des prototypes.
- Les dialogues disponibles ne couvrent pas Maël/Lysa.
- Le battle rival Lysa est absent.
- Les world rules sont absentes.
- Aucun smoke Selbrume ne prouve le chemin complet.

Risques majeurs :

- Écrire du contenu avant l'inventaire créerait des IDs incohérents.
- Réutiliser `scene_test`, `g.yarn` ou `cinematic_uwu` comme contenu final masquerait la dette réelle.
- Lancer un lot runtime avant le contenu produirait un smoke artificiel.
- Ajouter trop de maps du récit complet gonflerait inutilement la première slice.

## 17. Proposition de découpage post V1-137

Suite recommandée :

1. `NS-SCENES-V1-138 — Selbrume Golden Slice Content Inventory / Asset Gap Audit`
   - Réconcilier bible Selbrume, `project.json`, maps, PNJ, trainers, dialogues, facts, world rules et assets disponibles.
   - Verrouiller les IDs canoniques de la slice.

2. `NS-SCENES-V1-139 — Selbrume Golden Slice Scene Graph Drafts V0`
   - Créer les drafts scenes/events/facts/world rules une fois l'inventaire validé.

3. `NS-SCENES-V1-140 — Selbrume Golden Slice Dialogue / Battle / Cinematic Linking V0`
   - Brancher dialogues Maël/Lysa, battle Lysa et cinématique port/brume.

4. `NS-SCENES-V1-141 — Selbrume Golden Slice Runtime Smoke V0`
   - Prouver le chemin joueur en runtime avec save/reload.

5. `NS-SCENES-V1-142 — Selbrume Golden Slice Visual / Manual Demo Gate V0`
   - Produire captures, checklist manuelle et verdict démo.

## 18. Critères de succès de la démo

La démo est réussie si :

- le joueur démarre dans une zone Selbrume claire ;
- Maël lance une scène no-code ;
- le dialogue Maël donne un objectif compréhensible ;
- le joueur rejoint Lysa ;
- Lysa lance dialogue + cinématique courte + battle ;
- victory et defeat ne cassent pas la progression ;
- facts et completed steps sont visibles et persistés ;
- Lysa et Maël changent de dialogue après le combat ;
- save/reload conserve l'état ;
- aucun ID technique n'est nécessaire pour jouer ou comprendre ;
- un rapport + smoke + checklist prouvent le chemin complet.

## 19. Non-objectifs confirmés

V1-137 n'a pas pour objectif :

- de créer ou modifier une map ;
- de créer ou modifier une scene ;
- de créer ou modifier une CinematicAsset ;
- de créer ou modifier un dialogue Yarn ;
- de créer ou modifier un battle ;
- de créer ou modifier un Fact ou une World Rule ;
- de modifier `packages/**` ;
- de modifier `selbrume/**` ;
- de créer une Visual Gate ;
- de rouvrir le Cinematic Builder V1 ;
- de toucher au runtime, Flame ou GameState.

## 20. Prochain lot recommandé

Prochain lot recommandé :

```text
NS-SCENES-V1-138 — Selbrume Golden Slice Content Inventory / Asset Gap Audit
```

Raison : l'audit montre que le plus gros risque n'est pas un manque de Builder, mais une divergence entre bible narrative, données de projet et contenu réellement authorable. V1-138 doit verrouiller l'inventaire avant toute écriture de contenu.

V1-138 est recommandé, non démarré.

## 21. Auto-critique finale

Cette clôture est volontairement prudente. Elle ne prétend pas que la golden slice est prête parce que les systèmes existent. Elle sépare le socle technique, qui est largement présent, du contenu Selbrume, qui reste incomplet.

Le point le plus fragile de V1-137 est l'absence d'ouverture de l'application : l'audit s'appuie sur les fichiers, rapports et données JSON/Yarn, pas sur une manipulation UI. Pour ce lot doc-only, c'est acceptable ; pour V1-138/V1-142, une vérification visuelle et runtime deviendra nécessaire.

Le rapport pourrait être trop conservateur sur `Selbrume` comme hub : la map 55x55 contient déjà des entités et beaucoup de placed elements. Mais tant que les PNJ/events/dialogues canoniques ne sont pas alignés, il serait risqué de l'utiliser comme preuve de contenu final.

## 22. Critique du prompt

Le prompt est large, mais sa frontière doc-only est saine. Il demande beaucoup de domaines à auditer ; certains, comme runtime save/reload et battle, ne peuvent pas être revérifiés exhaustivement sans relancer des tests hors scope. Pour V1-137, les rapports NS-GS existants suffisent à cadrer les dépendances, pas à certifier une démo jouable.

La demande de plan de contenu avant création est pertinente. Elle évite de produire des données Selbrume incohérentes avec les IDs existants.

Le prochain lot doit rester audit/data. Passer directement à l'authoring de scènes serait prématuré, car les maps et personnages canoniques ne sont pas encore réconciliés avec `project.json`.
