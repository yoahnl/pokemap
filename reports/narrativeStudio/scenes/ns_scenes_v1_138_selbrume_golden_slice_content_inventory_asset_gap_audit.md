# NS-SCENES-V1-138 — Selbrume Golden Slice Content Inventory / Asset Gap Audit

## 1. Resume executif

V1-138 est un audit documentaire d'inventaire. Aucun code produit, aucune donnee `selbrume/**`, aucun asset, aucun test Dart/Flutter et aucune capture n'ont ete modifies.

Verdict principal :

```text
NS-SCENES-V1-138 : DONE
Selbrume golden slice content inventory : DONE
V1-139 : SHOULD_WAIT
Prochain lot recommande : NS-SCENES-V1-138-bis — Selbrume Golden Slice Canonical ID Decision Closure
```

La raison est simple : les systemes Narrative Studio sont disponibles, mais les donnees Selbrume actuelles restent melangees entre prototypes, preuves techniques et bible narrative. L'audit confirme :

- `selbrume/project.json` contient 10 maps, 5 characters, 2 dialogues, 1 scene, 3 scenarios, 1 cinematic, 4 storylines, 1 fact, 0 world rule, 1 trainer et 1 encounter table vide.
- Les personnages `mael`, `lyra`, `rival` et `grant` existent comme Character Library entries avec tilesets et animations.
- Mael existe comme personnage et asset sprite, mais pas comme entite de map canonique, dialogue, scene ou event jouable.
- Lysa n'existe pas sous l'ID `lysa`; le projet contient `lyra` et `rival`, ce qui demande confirmation utilisateur.
- Le Port des Brisants n'existe pas comme map `map_port_brisants`; la map `Selbrume` contient toutefois une couche `ponton`, une couche `océan`, un element `ponton_selbrume` et des assets port/eau, donc une zone portuaire peut exister visuellement dans la map actuelle.
- `scene_test`, `cinematic_uwu`, `g.yarn`, `test.yarn`, `fact_test` et `grant` ne doivent pas etre promus comme contenu canonique sans decision.

V1-139 ne doit donc pas demarrer directement. Le bon prochain verrou est un V1-138-bis tres court pour valider les IDs et choix canoniques avec Karim.

## 2. Verdict V1-138

```text
V1-138 inventory : DONE
V1-139 decision : V1-139_SHOULD_WAIT
Reason : canonical ID ambiguities and port mapping need user confirmation before authoring.
```

Le prochain lot recommande est :

```text
NS-SCENES-V1-138-bis — Selbrume Golden Slice Canonical ID Decision Closure
```

Questions a faire confirmer avant V1-139 :

1. `lyra` doit-elle devenir Lysa, ou faut-il creer un nouveau character `lysa` ?
2. `rival` est-il un role generique pour Lysa, un autre personnage, ou un prototype a ignorer ?
3. La map `Selbrume` peut-elle contenir la zone Port des Brisants, ou faut-il creer une map dediee `map_port_brisants` ?
4. `grant` reste-t-il un prototype technique hors golden slice narrative ?
5. Garde-t-on `mael` comme character ID canonique, avec une nouvelle entite `entity_mael_bourg` ?
6. Les facts rival doivent-ils suivre la bible (`fact_rival_port_defeated`, `fact_rival_port_lost_once`) ou l'inventaire NS-GS (`fact_rival_defeated`, `fact_rival_lost`, `fact_rival_battle_done`) ?

## 3. Rappel V1-137

V1-137 a conclu :

```text
Golden slice narrative Selbrume : NOT_READY_FOR_DIRECT_AUTHORING
Narrative Studio systems : PARTIAL_READY
Content inventory : REQUIRES_AUDIT
```

V1-137 a propose le chemin joueur :

1. Le joueur commence a Selbrume.
2. Il parle a Mael.
3. Mael introduit la brume et la mission.
4. Le joueur est oriente vers le port.
5. Lysa confronte le joueur.
6. Une scene/cinematic courte prepare le combat.
7. Le combat rival produit victory ou defeat.
8. Des facts/world rules changent les dialogues et la progression.

V1-138 verifie maintenant si les donnees actuelles permettent de l'ecrire sans deviner. Reponse : pas encore.

## 4. Methode d'audit

Passes effectuees :

| Passe | Role | Verdict |
|---|---|---|
| Gate 0 / regles | Lire regles repo, skills et etat Git initial. | OK |
| Preconditions V1-137 | Verifier rapports V1-137 et roadmaps. | OK |
| Inventaire donnees | Lire `project.json`, maps, Yarn, assets Selbrume. | OK |
| Reconciliation bible | Comparer avec `MVP Selbrume` et rapports NS-GS. | OK |
| ID decision pass | Classer KEEP / CREATE_LATER / NEEDS_USER_CONFIRMATION. | OK |
| Anti-scope pass | Verifier aucune modification produit/Selbrume. | OK |
| Critique finale | Identifier limites et prochain verrou. | OK |

Les skills demandes ont ete lus. `test-driven-development` n'a pas ete applique en pratique car le lot est doc-only et ne change aucun comportement.

## 5. Sources lues

Sources regles :

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `skills/writing-plans/SKILL.md`

Note : `codex_rules.md` au pluriel est absent. Le fichier present est `codex_rule.md`.

Sources Selbrume :

- `MVP Selbrume/selbrume.md`
- `MVP Selbrume/narrative_studio.md`
- `MVP Selbrume/checklist_beta_pokemap.md`
- `MVP Selbrume/road_map.md`
- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_1.md` a `road_map_phase_7.md`
- `selbrume/project.json`
- `selbrume/project.shadow59.before.json`
- `selbrume/maps/*.json`
- `selbrume/dialogues/*.yarn`

Sources rapports :

- `reports/narrativeStudio/scenes/ns_scenes_v1_137_narrative_studio_golden_slice_authoring_readiness_selbrume_demo_content_plan.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_137_evidence_pack.md`
- `reports/gameplay/ns_gs/ns_gs_01_golden_slice_exact_specification.md`
- `reports/gameplay/ns_gs/ns_gs_03_content_inventory_fixture_plan.md`
- `reports/gameplay/ns_gs/ns_gs_08_npc_interaction_scene_authoring_readiness.md`
- `reports/gameplay/ns_gs/ns_gs_09_yarn_outcome_scene_branch_readiness.md`
- `reports/gameplay/ns_gs/ns_gs_10_world_rules_conditional_presence_readiness.md`
- `reports/gameplay/ns_gs/ns_gs_11_trainer_battle_authoring_readiness.md`
- `reports/gameplay/ns_gs/ns_gs_12_editor_authored_golden_slice_validation.md`
- `reports/gameplay/ns_gs/ns_gs_13_narrative_validator_minimal_v0.md`
- `reports/gameplay/audit/selbrume_readiness_audit_and_plan.md`
- `reports/gameplay/audit/selbrume_readiness_audit_and_plan_bis.md`
- `reports/roadmap/phase_6/*.md`

## 6. Inventaire brut Selbrume

### 6.1 `project.json`

| Domaine | Nombre | Commentaire |
|---|---:|---|
| maps | 10 | Maps existantes mais IDs non alignes bible. |
| characters | 5 | `vova`, `mael`, `lyra`, `rival`, `grant`. |
| dialogues | 2 | `g`, `test`. Aucun dialogue Mael/Lysa canonique. |
| scenes | 1 | `scene_test`. Prototype. |
| scenarios | 3 | `global_story`, `test`, `p6_03_first_interaction`. |
| cinematics | 1 | `cinematic_uwu`. Prototype Builder. |
| storylines | 4 | Storyline principale + 3 side quests deja presentes. |
| facts | 1 | `fact_test`. Prototype. |
| worldRules | 0 | Aucun world rule canonique. |
| trainers | 1 | `grant`. Prototype / trainer technique. |
| encounterTables | 1 | `grass_path_route_1`, 0 slot. |

### 6.2 Maps

| ID actuel | Label | Fichier | Taille | Layers | Events | Entities | Placed elements | Warps | Statut |
|---|---|---|---:|---:|---:|---:|---:|---:|---|
| `Selbrume` | Selbrume | `maps/Selbrume.json` | 55x55 | 17 | 0 | 3 | 307 | 3 | PARTIAL |
| `route 1` | route 1 | `maps/route 1.json` | 45x45 | 6 | 0 | 1 | 68 | 0 | PARTIAL |
| `house 1` | house 1 | `maps/house 1.json` | 45x45 | 3 | 0 | 0 | 0 | 1 | PROTOTYPE |
| `house 2` | house 2 | `maps/house 2.json` | 45x45 | 3 | 0 | 0 | 0 | 1 | PROTOTYPE |
| `house 3` | house 3 | `maps/house 3.json` | 45x45 | 3 | 0 | 0 | 0 | 0 | PROTOTYPE |
| `house 4` | house 4 | `maps/house 4.json` | 45x45 | 3 | 0 | 0 | 0 | 0 | PROTOTYPE |
| `house 5` | house 5 | `maps/house 5.json` | 45x45 | 3 | 0 | 0 | 0 | 0 | PROTOTYPE |
| `pokémon center` | pokémon center | `maps/pokémon center.json` | 45x45 | 3 | 0 | 0 | 0 | 0 | OPTIONAL |
| `pub` | pub | `maps/pub.json` | 45x45 | 3 | 0 | 0 | 0 | 0 | OPTIONAL |
| `lab` | lab | `maps/lab.json` | 45x45 | 3 | 0 | 0 | 0 | 0 | OPTIONAL |

Entites map :

| Map | Entite | Commentaire |
|---|---|---|
| `Selbrume` | `spawn` | Spawn existant. |
| `Selbrume` | `p6_03_intro_sign` | Interaction technique P6-03. |
| `Selbrume` | `npc` | Entite generique non canonique. |
| `route 1` | `grant` | Trainer/PNJ Grant prototype. |

Warps :

| Source | Warp | Destination | Statut |
|---|---|---|---|
| `Selbrume` | `to lab` | `Selbrume` | Prototype / cible suspecte. |
| `Selbrume` | `to house 1` | `house 1` | Usable. |
| `Selbrume` | `to house 2` | `house 2` | Usable. |
| `house 1` | `warp` | `Selbrume` | Usable. |
| `house 2` | `warp` | `Selbrume` | Usable. |

### 6.3 Characters

| ID | Nom | Tileset | Animations | Statut |
|---|---|---|---:|---|
| `vova` | vova | `vova` | 8 | CANONICAL_READY visuel, narratif non lie |
| `mael` | mael | `mael` | 8 | PARTIAL |
| `lyra` | lyra | `lyra` | 8 | NEEDS_USER_CONFIRMATION |
| `rival` | rival | `timi` | 8 | NEEDS_USER_CONFIRMATION |
| `grant` | grant | `grant` | 8 | PROTOTYPE |

### 6.4 Dialogues

| ID | Fichier | Lignes | Statut | Commentaire |
|---|---|---:|---|---|
| `g` | `dialogues/g.yarn` | 4 | PLACEHOLDER | Contient `(Begin editing your dialogue here.)`. |
| `test` | `dialogues/test.yarn` | 35 | PROTOTYPE | Dialogue meteo Marc/Lea, pas Mael/Lysa. |

### 6.5 Scenes, scenarios, cinematics

| Domaine | ID | Statut | Commentaire |
|---|---|---|---|
| Scene | `scene_test` | PROTOTYPE | Contient start/end, battle `grant`, Yarn `g`, cinematic `cinematic_uwu`. |
| Scenario | `global_story` | PROTOTYPE | Squelette global story minimal. |
| Scenario | `test` | PROTOTYPE | Template dialogue simple. |
| Scenario | `p6_03_first_interaction` | TECHNICAL_READY | Interaction narrative courte via `p6_03_intro_sign`, pas golden slice finale. |
| Cinematic | `cinematic_uwu` | PROTOTYPE | 11 steps, utile comme preuve Builder, pas contenu Selbrume final. |

### 6.6 Trainers / battles

| ID | Character | Team | Statut | Commentaire |
|---|---|---|---|---|
| `grant` | `grant` | bulbasaur L1, dratini L25, ivysaur L25 | PROTOTYPE | Trainer existant mais pas Lysa, niveaux non coherents demo depart. |

Il n'y a pas de `trainer_lysa_port` ni de `battle_rival_port` dans `project.json`.

## 7. Inventaire bible / cible narrative

La bible Selbrume attend notamment :

| Domaine | ID cible / label | Preuve doc | Statut donnees |
|---|---|---|---|
| Map | `map_bourg_selbrume` / Bourg de Selbrume | `MVP Selbrume/selbrume.md` | Non present, peut mapper vers `Selbrume`. |
| Map | `map_port_brisants` / Port des Brisants | `MVP Selbrume/selbrume.md` | Non present, peut-etre zone de `Selbrume`. |
| PNJ | `npc_mael` / Mael | Bible | Character `mael` existe, entite/event/dialogue manquants. |
| PNJ | `npc_lysa` / Lysa | Bible | `lysa` absent, `lyra` et `rival` ambigus. |
| Event | `event_enter_port_alert` | Bible | Manquant. |
| Event | `event_rival_port_meet` | Bible | Manquant. |
| Scene | `scene_rival_meet` | Bible / NS-GS | Manquant. |
| Dialogue | `yarn_rival_intro` | Bible / NS-GS | Manquant. |
| Battle | `battle_rival_port` / `trainer_lysa_port` | Bible / NS-GS | Manquant. |
| Facts | rival/mission/port flags | Bible / NS-GS | Manquants hors `fact_test`. |
| World Rules | Lysa/Mael visibility/dialogue | Bible / NS-GS | Aucune world rule actuelle. |

## 8. Reconciliation maps

| Cible narrative | ID canonique propose | Existe actuellement | ID actuel lie | Decision | Raison | Besoin utilisateur |
|---|---|---|---|---|---|---|
| Bourg de Selbrume | `map_bourg_selbrume` | Non | `Selbrume` | MAP_TO_EXISTING puis RENAME_LATER possible | `Selbrume` est le hub 55x55 avec spawn, maisons, ponton/ocean. | Confirmer si `Selbrume` = bourg canonique. |
| Port des Brisants | `map_port_brisants` | Non | `Selbrume` zone potentielle | NEEDS_USER_CONFIRMATION | `Selbrume` contient ponton/ocean/assets port, mais aucun port map ID ni event Lysa. | Confirmer map dediee ou zone dans `Selbrume`. |
| Route vers port | `map_route_port` ou conserver `route 1` | `route 1` existe | `route 1` | DEFER | Route 1 a Grant et 68 elements, mais la bible demande plutot le Port. | Decider plus tard. |
| Lab / mentor | `map_lab_selbrume` optionnel | `lab` existe | `lab` | DEFER | Peut heberger Mael mais la bible place Mael au bourg. | Confirmer si Mael est dehors ou au lab. |
| Centre Pokemon | `map_pokemon_center_selbrume` | `pokémon center` existe | `pokémon center` | DEFER | Utile pour demo playable, pas bloquant pour V1-138. | Aucun pour V1-138. |

Conclusion Port :

```text
Decision : USE_EXISTING_ZONE_WITH_REVIEW ou CREATE_MISSING_MAP_LATER.
Statut V1-138 : NEEDS_VISUAL_REVIEW + NEEDS_USER_CONFIRMATION.
```

## 9. Reconciliation personnages / PNJ

### Mael

| Verification | Resultat |
|---|---|
| Character existe ? | Oui, `mael`. |
| Tileset exploitable ? | Oui, `mael` -> `assets/tilesets/mael.png`, 8 animations. |
| Entite de map ? | Non. |
| Event ? | Non. |
| Dialogue ? | Non. |
| Scene ? | Non. |
| Storyline ? | Step `step_receive_mission` mentionne Mael, sans lien scene. |

Conclusion :

```text
Mael : PARTIAL
Decision proposee : KEEP character `mael`, CREATE_LATER `entity_mael_bourg`, `event_mael_intro`, `scene_mael_intro`, Yarn Mael.
```

### Lysa / Lyra / rival

| Element actuel | Preuve | Interpretation possible | Decision |
|---|---|---|---|
| `lyra` | Character + tileset `lyra`, 8 animations | Peut etre Lysa mal nommee ou personnage separe. | NEEDS_USER_CONFIRMATION |
| `rival` | Character `rival`, tileset `timi`, 8 animations | Role generique rival ou prototype visuel. | NEEDS_USER_CONFIRMATION |
| `lysa` | Aucun ID actuel | Personnage canonique bible absent. | CREATE_LATER ou RENAME_LATER |

Conclusion :

```text
Lysa : MISSING as canonical ID
Lyra/rival : ambiguous
Decision V1-138 : DO_NOT_AUTHOR_YET
```

### Grant

Grant existe comme character, entity `route 1` et trainer. Il est reutilisable comme preuve technique d'un trainer battle, mais pas comme rival battle Lysa.

## 10. Reconciliation dialogues

| Cible narrative | ID propose | Existe actuellement | Decision |
|---|---|---|---|
| Intro Mael | `yarn_mael_intro` ou `yarn_mael_intro_before_gift` | Non | CREATE_LATER |
| Mission Mael | `yarn_mael_mission` | Non | CREATE_LATER |
| Encouragement Mael | `yarn_mael_encouragement` | Non | CREATE_LATER |
| Mael apres rival | `yarn_mael_post_rival` | Non | CREATE_LATER |
| Intro rival/Lysa | `yarn_rival_intro` | Non | CREATE_LATER |
| Lysa post-victoire | `yarn_rival_after_win` ou `yarn_lysa_post_win` | Non | CREATE_LATER |
| Lysa post-defaite | `yarn_rival_after_loss` ou `yarn_lysa_post_loss` | Non | CREATE_LATER |
| Placeholder | `g` | Oui | IGNORE_PROTOTYPE |
| Dialogue test | `test` | Oui | IGNORE_PROTOTYPE |

Decision :

```text
Les dialogues existants ne sont pas utilisables pour le contenu final.
```

## 11. Reconciliation scenes

| Cible narrative | ID propose | Existe actuellement | Decision |
|---|---|---|---|
| Scene Mael intro/mission | `scene_mael_intro` | Non | CREATE_LATER |
| Scene arrivee port | `scene_port_alert` | Non | CREATE_LATER ou DEFER |
| Scene rival | `scene_rival_meet` | Non | CREATE_LATER |
| Scene apres victoire | `scene_rival_after_win` | Non | CREATE_LATER |
| Scene apres defaite | `scene_rival_after_loss` | Non | CREATE_LATER |
| Scene demo exit | `scene_demo_exit` | Non | DEFER |
| Prototype | `scene_test` | Oui | IGNORE_PROTOTYPE / CAN_REUSE_AS_TEMPLATE |

`scene_test` prouve que le systeme sait lier battle/dialogue/cinematic, mais il lie `grant`, `g` et `cinematic_uwu`, donc il ne doit pas devenir golden slice canonique.

## 12. Reconciliation cinematics

| Cible narrative | ID propose | Existe actuellement | Decision |
|---|---|---|---|
| Signal brume port | `cin_port_mist_signal` | Non | CREATE_LATER |
| Lysa sourit | `cinematic_rival_smiles` | Non | CREATE_LATER / SIMPLE_V0 |
| Lysa taquine | `cinematic_rival_teases` | Non | CREATE_LATER / SIMPLE_V0 |
| Depart rival victoire | `cinematic_rival_depart_win` | Non | DEFER |
| Depart rival defaite | `cinematic_rival_depart_loss` | Non | DEFER |
| Prototype | `cinematic_uwu` | Oui | IGNORE_PROTOTYPE / CAN_REUSE_AS_TEMPLATE |

`cinematic_uwu` reste utile comme template de capacite Cinematic Builder, mais pas comme scene Selbrume.

## 13. Reconciliation trainers / battles

| Cible narrative | ID propose | Existe actuellement | Decision |
|---|---|---|---|
| Trainer Lysa | `trainer_lysa_port` | Non | CREATE_LATER |
| Battle rival port | `battle_rival_port` | Non | CREATE_LATER |
| Outcomes battle | `battle:battle_rival_port:victory`, `battle:battle_rival_port:defeat` | Runtime supporte le pattern, pas de contenu ecrit | CREATE_LATER |
| Trainer prototype | `grant` | Oui | IGNORE_PROTOTYPE for golden slice |

Grant a une team de trois Pokemon avec Dratini/Ivysaur niveau 25, trop eloignee d'un premier rival battle de demo. Il peut rester reference technique.

## 14. Reconciliation facts / world rules

Facts actuels :

| ID actuel | Label | Statut |
|---|---|---|
| `fact_test` | test | PROTOTYPE |

World rules actuelles :

```text
0
```

Facts proposes avant authoring :

| ID propose | Source | Decision |
|---|---|---|
| `fact_starter_received` | NS-GS | CREATE_LATER si starter dans slice. |
| `fact_mission_started` | NS-GS | CREATE_LATER. |
| `fact_port_alert_seen` | Bible | CREATE_LATER ou DEFER si V0 coupe l'alerte port. |
| `fact_rival_battle_done` | NS-GS | CREATE_LATER. |
| `fact_rival_defeated` | NS-GS | CREATE_LATER, a reconciler avec bible. |
| `fact_rival_lost` | NS-GS | CREATE_LATER, a reconciler avec bible. |
| `fact_rival_port_defeated` | Bible | NEEDS_USER_CONFIRMATION vs `fact_rival_defeated`. |
| `fact_rival_port_lost_once` | Bible | NEEDS_USER_CONFIRMATION vs `fact_rival_lost`. |

World rules proposees :

| ID propose | Effet | Decision |
|---|---|---|
| `wr_lysa_invisible_before_starter_or_mission` | Lysa non disponible avant starter/mission. | CREATE_LATER |
| `wr_lysa_visible_before_battle` | Lysa visible/interactable avant combat. | CREATE_LATER |
| `wr_lysa_dialogue_post_victory` | Dialogue apres victoire. | CREATE_LATER |
| `wr_lysa_dialogue_post_defeat` | Dialogue apres defaite. | CREATE_LATER |
| `wr_mael_dialogue_before_starter` | Mael lance intro. | CREATE_LATER |
| `wr_mael_dialogue_after_starter` | Mael encourage avant rival. | CREATE_LATER |
| `wr_mael_dialogue_post_rival` | Mael reagit apres combat. | CREATE_LATER |

## 15. Reconciliation storylines / steps

Storyline principale actuelle :

| Storyline | Chapter | Step | Label | Statut |
|---|---|---|---|---|
| `story_main_brume_phare` | `chapter_1_port` | `step_intro_selbrume` | Introduction a Selbrume | PARTIAL |
| `story_main_brume_phare` | `chapter_1_port` | `step_receive_mission` | Recevoir la mission de Mael | PARTIAL |
| `story_main_brume_phare` | `chapter_1_port` | `step_go_to_port` | Aller au Port des Brisants | PARTIAL |
| `story_main_brume_phare` | `chapter_1_port` | `step_rival_battle` | Affronter Lysa | PARTIAL |

Les steps existent, mais sans liens scenes/facts/world rules. V1-139 ne doit pas changer leur sens sans confirmer la granularite avec Karim.

## 16. Assets utiles / manquants

Assets utiles trouves dans `selbrume/assets/tilesets` :

| Asset | Usage potentiel |
|---|---|
| `mael.png` | Mael character. |
| `lyra.png` | Candidat Lysa si confirme. |
| `timi.png` | Candidat rival/prototype. |
| `grant.png` | Grant prototype/trainer. |
| `vova.png` | Character existant. |
| `bateau_selbrume.png` | Port / decor. |
| `ponton_selbrume.png` | Port / ponton. |
| `deep_water.png`, `water_edge.png`, `water_edge_only.png`, `selbrume_open_sea_true_loop.png`, `beach_tile.png`, `beach_wave.jpg` | Eau / plage / port. |

Assets absents ou non confirmes :

- sprite/portrait canonique Lysa si `lyra` n'est pas Lysa ;
- portrait Mael/Lysa si le dialogue en a besoin ;
- assets battle Lysa dedies ;
- map port dediee si la zone de `Selbrume` ne suffit pas.

Note : le dossier racine `assets` est absent dans ce repo au moment de l'audit. Les assets utiles sont sous `selbrume/assets/tilesets`.

## 17. Classement prototypes vs contenu canonique

| Element | Classement | Decision |
|---|---|---|
| `scene_test` | PROTOTYPE_ONLY | Ne pas utiliser en golden slice finale ; peut inspirer un graphe. |
| `cinematic_uwu` | CAN_REUSE_AS_TEMPLATE | Ne pas utiliser comme contenu final. |
| `g.yarn` | PLACEHOLDER | Ne pas utiliser. |
| `test.yarn` | PROTOTYPE_ONLY | Ne pas utiliser pour Mael/Lysa. |
| `fact_test` | PROTOTYPE_ONLY | Ne pas utiliser. |
| `grant` trainer | PROTOTYPE / TECHNICAL_READY | Ne pas mapper a Lysa. |
| `p6_03_first_interaction` | TECHNICAL_READY | Garder comme preuve P6, ne pas confondre avec scene Mael finale. |

## 18. IDs canoniques proposes

| Domaine | Cible narrative | ID canonique propose | Existe actuellement | ID actuel lie | Decision | Raison | Besoin utilisateur |
|---|---|---|---|---|---|---|---|
| map | Bourg | `map_bourg_selbrume` | Non | `Selbrume` | MAP_TO_EXISTING / RENAME_LATER | Hub actuel probable. | Confirmer le mapping. |
| map | Port | `map_port_brisants` | Non | zone possible dans `Selbrume` | NEEDS_USER_CONFIRMATION | Assets port/eau presents, map dediee absente. | Confirmer zone ou map dediee. |
| character | Mael | `mael` | Oui | `mael` | KEEP | Character + tileset existants. | Confirmer nom affiche Mael. |
| entity | Mael bourg | `entity_mael_bourg` | Non | aucun | CREATE_LATER | Entite jouable manquante. | Confirmer emplacement. |
| character | Lysa | `lysa` ou `lyra` | `lyra` existe, `lysa` non | `lyra`, `rival` | NEEDS_USER_CONFIRMATION | Ambiguite ID/personnage. | Choisir. |
| entity | Lysa port | `entity_lysa_port` | Non | aucun | CREATE_LATER | Necessaire au trigger rival. | Depend du choix character. |
| trainer | Lysa | `trainer_lysa_port` | Non | `grant` prototype | CREATE_LATER | Grant n'est pas Lysa. | Confirmer team. |
| battle | Rival port | `battle_rival_port` | Non | aucun | CREATE_LATER | Contrat NS-GS. | Confirmer outcome flee. |
| dialogue | Mael intro | `yarn_mael_intro` | Non | aucun | CREATE_LATER | Dialogue canonique manquant. | Aucun si IDs valides. |
| dialogue | Rival intro | `yarn_rival_intro` | Non | aucun | CREATE_LATER | Dialogue Lysa avec choices. | Confirmer ton. |
| scene | Mael intro | `scene_mael_intro` | Non | aucun | CREATE_LATER | Premier trigger. | Depend map/entity. |
| scene | Rival meet | `scene_rival_meet` | Non | aucun | CREATE_LATER | Combat Lysa. | Depend map/entity/trainer. |
| fact | Mission | `fact_mission_started` | Non | aucun | CREATE_LATER | Condition Lysa. | Confirmer nom. |
| fact | Battle done | `fact_rival_battle_done` | Non | aucun | CREATE_LATER | World rules post battle. | Confirmer nom. |
| world rule | Lysa visible | `wr_lysa_visible_before_battle` | Non | aucun | CREATE_LATER | Evite combat avant mission. | Aucun si IDs valides. |
| storyline step | Intro | `step_intro_selbrume` | Oui | actuel | KEEP | Existe deja. | Aucun. |
| storyline step | Mission | `step_receive_mission` | Oui | actuel | KEEP / MAP_TO_NS_GS | Existe deja, nom differe de `step_mission_received`. | Confirmer granularite. |
| storyline step | Port | `step_go_to_port` | Oui | actuel | KEEP | Existe deja. | Aucun. |
| storyline step | Rival | `step_rival_battle` | Oui | actuel | KEEP | Existe deja. | Aucun. |

## 19. Blockers avant authoring

| Gap | Domaine | Impact | Gravite | Bloque V1-139 ? | Lot recommande | Decision |
|---|---|---|---|---|---|---|
| Lysa/Lyra/rival non tranche | Characters | Risque de creer le mauvais personnage. | P0_BLOCKER | Oui | V1-138-bis | NEEDS_USER_CONFIRMATION |
| Port des Brisants non tranche | Maps | Risque d'ecrire events au mauvais endroit. | P0_BLOCKER | Oui | V1-138-bis | NEEDS_USER_CONFIRMATION |
| Mael sans entite/event | Maps/Scene | Pas de premiere interaction canonique. | P1_REQUIRED | Oui | V1-139 apres confirmation | CREATE_LATER |
| Aucun dialogue Mael/Lysa | Dialogue | Slice narrative injouable. | P1_REQUIRED | Oui | V1-139/V1-140 | CREATE_LATER |
| Aucun battle Lysa | Battle | Rival battle absent. | P1_REQUIRED | Oui | V1-139/V1-140 | CREATE_LATER |
| Facts/world rules manquants | Progression | Pas de progression conditionnelle. | P1_REQUIRED | Oui | V1-139 | CREATE_LATER |
| Scene/cinematic prototypes | Scene/Cinematic | Risque de promouvoir du faux contenu. | P1_REQUIRED | Oui | V1-139 | IGNORE_PROTOTYPE |
| Assets Lysa ambigus | Assets | Sprite final incertain. | P1_REQUIRED | Oui | V1-138-bis | NEEDS_USER_CONFIRMATION |
| Visual review port | Map visual | Donnees JSON indiquent ponton/ocean mais pas le layout produit. | P1_REQUIRED | Oui | V1-138-bis | NEEDS_VISUAL_REVIEW |

## 20. Matrice de gaps

| Gap | Domaine | Impact | Gravite | Bloque V1-139 ? | Lot recommande | Decision |
|---|---|---|---|---|---|---|
| `map_bourg_selbrume` absent | maps | ID canonique non aligne. | P1_REQUIRED | Oui | V1-138-bis | MAP_TO_EXISTING or RENAME_LATER |
| `map_port_brisants` absent | maps | Port canonique non authorable. | P0_BLOCKER | Oui | V1-138-bis | NEEDS_USER_CONFIRMATION |
| `entity_mael_bourg` absent | entities | Mael non interactif. | P1_REQUIRED | Oui | V1-139 | CREATE_LATER |
| `entity_lysa_port` absent | entities | Rival non interactif. | P1_REQUIRED | Oui | V1-139 | CREATE_LATER |
| `trainer_lysa_port` absent | trainer | Battle Lysa absent. | P1_REQUIRED | Oui | V1-139/V1-140 | CREATE_LATER |
| `battle_rival_port` absent | battle | Outcome rival absent. | P1_REQUIRED | Oui | V1-139/V1-140 | CREATE_LATER |
| `yarn_rival_intro` absent | dialogue | Choix pre-battle absent. | P1_REQUIRED | Oui | V1-139/V1-140 | CREATE_LATER |
| `worldRules` vide | world rules | Dialogues/presence non conditionnels. | P1_REQUIRED | Oui | V1-139 | CREATE_LATER |
| `fact_test` seul fact | facts | Progression reelle absente. | P1_REQUIRED | Oui | V1-139 | CREATE_LATER |
| `g.yarn` placeholder | dialogue | Risque UX si reutilise. | P1_REQUIRED | Oui | V1-139 | IGNORE_PROTOTYPE |
| `cinematic_uwu` non canonique | cinematic | Mauvaise scene si reutilisee. | P2_NICE_TO_HAVE | Non si ignore | V1-139 | IGNORE_PROTOTYPE |

## 21. Decision : peut-on demarrer V1-139 ?

```text
V1-139_SHOULD_WAIT
```

V1-139 ne doit pas demarrer tant que les decisions suivantes ne sont pas fermees :

- Lysa = `lyra`, `rival`, ou nouveau `lysa`.
- Port = zone existante dans `Selbrume` ou nouvelle map `map_port_brisants`.
- Noms de facts rival : bible vs NS-GS.
- Mael garde `mael` comme character ID avec entite `entity_mael_bourg`.

## 22. Proposition V1-139

La proposition V1-139 est reportee derriere un bis :

```text
NS-SCENES-V1-138-bis — Selbrume Golden Slice Canonical ID Decision Closure
```

Objectif V1-138-bis :

- demander et figer les decisions Karim ;
- produire une table definitive des IDs canoniques a ecrire ;
- confirmer si `Selbrume` contient le port ou si `map_port_brisants` doit etre cree ;
- confirmer `lyra` / `rival` / `lysa` ;
- definir le strict perimetre V1-139.

V1-139 probable apres confirmation :

```text
NS-SCENES-V1-139 — Selbrume Golden Slice Canonical Content Scaffolding V0
```

Objectif futur :

- creer seulement les drafts authoring minimaux valides ;
- ne pas ecrire les dialogues finaux longs ;
- ne pas finaliser battle balance ;
- ne pas lancer runtime smoke complet ;
- ne pas modifier sans validation les IDs incertains.

## 23. Non-objectifs confirmes

V1-138 n'a pas fait :

- modification de code Dart/Flutter ;
- modification de `selbrume/project.json` ;
- modification de maps ;
- modification de Yarn ;
- creation de SceneAsset/CinematicAsset/Fact/World Rule ;
- creation d'assets ;
- screenshot / Visual Gate ;
- V1-139 ;
- runtime ;
- Flame ;
- GameState ;
- migration ;
- seed final.

## 24. Auto-critique finale

L'audit est volontairement conservateur. Les fichiers prouvent que certains assets portuaires et sprites existent, mais pas que la golden slice est authorable sans decision produit. Le risque principal serait de promouvoir `lyra`, `rival`, `grant`, `scene_test` ou `cinematic_uwu` par commodite alors que la bible demande Lysa, Mael, Port des Brisants et des scenes/facts/rules canoniques.

La meilleure suite n'est pas un gros V1-139 de creation de contenu, mais un V1-138-bis tres court pour fermer les decisions humaines. C'est moins spectaculaire, mais plus sain pour eviter de construire sur de mauvais IDs.

## 25. Critique du prompt

Le prompt est large pour un lot doc-only : il demande de reconciler bible, project data, maps, PNJ, battles, facts, world rules, assets et IDs. C'est faisable en audit, mais il serait dangereux de transformer ces conclusions en ecriture de contenu sans validation visuelle et produit.

Points limites :

- Certaines decisions d'ID ne peuvent pas etre tranchees par le repo seul, notamment `lyra` vs `lysa` vs `rival`.
- Le statut du Port des Brisants demande une revue visuelle de la map `Selbrume`; les donnees JSON indiquent ponton/ocean, mais pas l'intention auteur.
- Les rapports NS-GS et la bible n'utilisent pas toujours exactement les memes noms de facts. Un bis de decision est donc utile.
- Le prochain lot devrait etre V1-138-bis plutot que V1-139 si l'on veut eviter une ecriture bancale.

