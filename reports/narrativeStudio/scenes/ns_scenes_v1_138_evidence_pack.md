# NS-SCENES-V1-138 — Evidence Pack

## Gate 0 complet

Commande :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 12
```

Sortie utile exacte :

```text
/Users/karim/Project/pokemonProject
main
80dd997a NS-SCENES-V1-137 — Narrative Studio Golden Slice Authoring Readiness Selbrume Demo Content Plan
703c5702 NS-SCENES-V1-136-BIS — Cinematic Builder Legacy Widget Expectations Cleanup
0f9c5cfe NS-SCENES-V1-136 — Cinematic Builder V1 Closure Readiness Audit
2bd11dda NS-SCENES-V1-135 — Cinematic Builder V1 Camera Closure Polish Gate
179cd6aa NS-SCENES-V1-134 — Cinematic Camera Geometry Preview UI V0
28d0e46e NS-SCENES-V1-133 — Cinematic Camera Geometry Playback State V0
d4e0b28b NS-SCENES-V1-132 — Cinematic Camera Target Zoom Editor UI V0
882c2c23 NS-SCENES-V1-131 — Cinematic Camera Target Zoom Core Model V0
a7bb9b42 update selbrume
4c3040a3 update selbrume
47660d78 NS-SCENES-V1-130 — Cinematic Camera Target Zoom Authoring Prep Contract
2344303e update selbrume
```

Interpretation : `git status`, `git diff --stat` et `git diff --name-only` n'ont rien imprime au Gate 0. Le worktree etait propre avant V1-138.

## Regles lues

Fichiers lus avant modification :

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `skills/writing-plans/SKILL.md`

Commande :

```bash
ls -1 codex_rule.md codex_rules.md 2>&1 || true
```

Sortie :

```text
ls: codex_rules.md: No such file or directory
codex_rule.md
```

Decision : `codex_rules.md` au pluriel est absent ; `codex_rule.md` est present et lu.

## Preconditions V1-137

Commande :

```bash
rg -n "NS-SCENES-V1-137|Narrative Studio Golden Slice Authoring Readiness / Selbrume Demo Content Plan|Golden slice narrative Selbrume : NOT_READY_FOR_DIRECT_AUTHORING|NS-SCENES-V1-138 — Selbrume Golden Slice Content Inventory / Asset Gap Audit" reports/narrativeStudio/scenes/ns_scenes_v1_137_narrative_studio_golden_slice_authoring_readiness_selbrume_demo_content_plan.md reports/narrativeStudio/scenes/ns_scenes_v1_137_evidence_pack.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

Sortie utile exacte :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_137_narrative_studio_golden_slice_authoring_readiness_selbrume_demo_content_plan.md:1:# NS-SCENES-V1-137 — Narrative Studio Golden Slice Authoring Readiness / Selbrume Demo Content Plan
reports/narrativeStudio/scenes/ns_scenes_v1_137_narrative_studio_golden_slice_authoring_readiness_selbrume_demo_content_plan.md:18:Golden slice narrative Selbrume : NOT_READY_FOR_DIRECT_AUTHORING
reports/narrativeStudio/scenes/ns_scenes_v1_137_narrative_studio_golden_slice_authoring_readiness_selbrume_demo_content_plan.md:21:Next lot : NS-SCENES-V1-138 — Selbrume Golden Slice Content Inventory / Asset Gap Audit
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:12:NS-SCENES-V1-138 — Selbrume Golden Slice Content Inventory / Asset Gap Audit
reports/narrativeStudio/scenes/road_map_scenes.md:205:| NS-SCENES-V1-138 — Selbrume Golden Slice Content Inventory / Asset Gap Audit | RECOMMANDÉ | Reconciler la bible Selbrume, `project.json`, les maps, PNJ, trainers, dialogues, facts, world rules, assets et IDs canoniques avant toute ecriture de contenu golden slice. |
```

Verdict : precondition OK.

## Fichiers lus

Sources Selbrume et docs :

```text
MVP Selbrume/checklist_beta_pokemap.md
MVP Selbrume/narrative_studio.md
MVP Selbrume/road_map.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_1.md
MVP Selbrume/road_map_phase_2.md
MVP Selbrume/road_map_phase_3.md
MVP Selbrume/road_map_phase_4.md
MVP Selbrume/road_map_phase_5.md
MVP Selbrume/road_map_phase_6.md
MVP Selbrume/road_map_phase_7.md
MVP Selbrume/selbrume.md
selbrume/project.json
selbrume/project.shadow59.before.json
selbrume/maps/Selbrume.json
selbrume/maps/route 1.json
selbrume/maps/house 1.json
selbrume/maps/house 2.json
selbrume/maps/house 3.json
selbrume/maps/house 4.json
selbrume/maps/house 5.json
selbrume/maps/lab.json
selbrume/maps/pokémon center.json
selbrume/maps/pub.json
selbrume/dialogues/g.yarn
selbrume/dialogues/test.yarn
```

Rapports utiles lus ou interroges :

```text
reports/gameplay/ns_gs/ns_gs_01_golden_slice_exact_specification.md
reports/gameplay/ns_gs/ns_gs_03_content_inventory_fixture_plan.md
reports/gameplay/ns_gs/ns_gs_08_npc_interaction_scene_authoring_readiness.md
reports/gameplay/ns_gs/ns_gs_09_yarn_outcome_scene_branch_readiness.md
reports/gameplay/ns_gs/ns_gs_10_world_rules_conditional_presence_readiness.md
reports/gameplay/ns_gs/ns_gs_11_trainer_battle_authoring_readiness.md
reports/gameplay/ns_gs/ns_gs_12_editor_authored_golden_slice_validation.md
reports/gameplay/ns_gs/ns_gs_13_narrative_validator_minimal_v0.md
reports/gameplay/audit/selbrume_readiness_audit_and_plan.md
reports/gameplay/audit/selbrume_readiness_audit_and_plan_bis.md
reports/roadmap/phase_6/*.md
```

## Commandes d'inventaire

### Fichiers Selbrume

Commande :

```bash
find selbrume -maxdepth 3 -type f | sort
```

Sortie :

```text
selbrume/assets/pokemon/.DS_Store
selbrume/assets/tilesets/arbre_pixellab.png
selbrume/assets/tilesets/bateau_selbrume.png
selbrume/assets/tilesets/beach_tile.png
selbrume/assets/tilesets/beach_wave.jpg
selbrume/assets/tilesets/big_water_rock.png
selbrume/assets/tilesets/bosquet_fleurs.png
selbrume/assets/tilesets/cliff.png
selbrume/assets/tilesets/deep_water.png
selbrume/assets/tilesets/dirt_path.png
selbrume/assets/tilesets/fleurs_elements.png
selbrume/assets/tilesets/fleurs_selbrume_de_toure_es.png
selbrume/assets/tilesets/grant.png
selbrume/assets/tilesets/grass_elements.png
selbrume/assets/tilesets/grass_soft_flowers.png
selbrume/assets/tilesets/grass_sprite.png
selbrume/assets/tilesets/gros_sol_herbre.png
selbrume/assets/tilesets/haute_herbe.png
selbrume/assets/tilesets/lyra.png
selbrume/assets/tilesets/mael.png
selbrume/assets/tilesets/mountain_elements_paths.png
selbrume/assets/tilesets/new_pavement_new.png
selbrume/assets/tilesets/objectif.png
selbrume/assets/tilesets/objectif_1.png
selbrume/assets/tilesets/pavement_path.png
selbrume/assets/tilesets/ponton_selbrume.png
selbrume/assets/tilesets/rocks.png
selbrume/assets/tilesets/route_1.png
selbrume/assets/tilesets/route_1_1.png
selbrume/assets/tilesets/selbrume_all_sprite.png
selbrume/assets/tilesets/selbrume_open_sea_true_loop.png
selbrume/assets/tilesets/small_water_rock.png
selbrume/assets/tilesets/timi.png
selbrume/assets/tilesets/vova.png
selbrume/assets/tilesets/water_edge.png
selbrume/assets/tilesets/water_edge_only.png
selbrume/dialogues/g.yarn
selbrume/dialogues/test.yarn
selbrume/maps/Selbrume.json
selbrume/maps/house 1.json
selbrume/maps/house 2.json
selbrume/maps/house 3.json
selbrume/maps/house 4.json
selbrume/maps/house 5.json
selbrume/maps/lab.json
selbrume/maps/pokémon center.json
selbrume/maps/pub.json
selbrume/maps/route 1.json
selbrume/project.json
selbrume/project.shadow59.before.json
```

### Docs et rapports disponibles

Commande :

```bash
find 'MVP Selbrume' -maxdepth 1 -type f -print | sort
```

Sortie :

```text
MVP Selbrume/.gitignore
MVP Selbrume/checklist_beta_pokemap.md
MVP Selbrume/narrative_studio.md
MVP Selbrume/road_map.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_1.md
MVP Selbrume/road_map_phase_2.md
MVP Selbrume/road_map_phase_3.md
MVP Selbrume/road_map_phase_4.md
MVP Selbrume/road_map_phase_5.md
MVP Selbrume/road_map_phase_6.md
MVP Selbrume/road_map_phase_7.md
MVP Selbrume/selbrume.md
```

Commande :

```bash
find reports/gameplay/ns_gs reports/gameplay/audit reports/roadmap/phase_6 -maxdepth 1 -type f | sort
```

Sortie utile exacte :

```text
reports/gameplay/audit/selbrume_readiness_audit_and_plan.md
reports/gameplay/audit/selbrume_readiness_audit_and_plan_bis.md
reports/gameplay/ns_gs/ns_gs_01_golden_slice_exact_specification.md
reports/gameplay/ns_gs/ns_gs_03_content_inventory_fixture_plan.md
reports/gameplay/ns_gs/ns_gs_08_npc_interaction_scene_authoring_readiness.md
reports/gameplay/ns_gs/ns_gs_09_yarn_outcome_scene_branch_readiness.md
reports/gameplay/ns_gs/ns_gs_10_world_rules_conditional_presence_readiness.md
reports/gameplay/ns_gs/ns_gs_11_trainer_battle_authoring_readiness.md
reports/gameplay/ns_gs/ns_gs_12_editor_authored_golden_slice_validation.md
reports/gameplay/ns_gs/ns_gs_13_narrative_validator_minimal_v0.md
reports/roadmap/phase_6/p6_03_selbrume_first_narrative_interaction.md
reports/roadmap/phase_6/p6_05_selbrume_first_trainer_battle_golden_slice.md
```

La commande a aussi liste d'autres rapports gameplay et phase_6 historiques ; les lignes ci-dessus sont celles utilisees directement pour les decisions V1-138.

## Inventaire brut `project.json`

Commande :

```bash
jq 'keys' selbrume/project.json
```

Sortie :

```text
[
  "characters",
  "cinematics",
  "dialogueFolders",
  "dialogues",
  "elementCategories",
  "elements",
  "encounterTables",
  "environmentPresets",
  "facts",
  "globalProperties",
  "groups",
  "maps",
  "name",
  "pathCategories",
  "pathPatternPresets",
  "pathPresets",
  "pokemon",
  "scenarios",
  "scenes",
  "scripts",
  "settings",
  "shadowCatalog",
  "storylines",
  "surfaceCatalog",
  "terrainCategories",
  "terrainPresets",
  "tilesetFolders",
  "tilesets",
  "trainers",
  "version",
  "worldRules"
]
```

Commande :

```bash
jq '{maps: (.maps|length), characters: (.characters|length), dialogues: (.dialogues|length), scenes: (.scenes|length), scenarios: (.scenarios|length), cinematics: (.cinematics|length), storylines: (.storylines|length), facts: (.facts|length), worldRules: (.worldRules|length), trainers: (.trainers|length), encounterTables: (.encounterTables|length)}' selbrume/project.json
```

Sortie :

```text
{
  "maps": 10,
  "characters": 5,
  "dialogues": 2,
  "scenes": 1,
  "scenarios": 3,
  "cinematics": 1,
  "storylines": 4,
  "facts": 1,
  "worldRules": 0,
  "trainers": 1,
  "encounterTables": 1
}
```

## Inventaire maps

Commande :

```bash
for f in selbrume/maps/*.json; do jq -r --arg f "$f" '[$f, (.id // ""), (.name // ""), (.width // .size.width // ""), (.height // .size.height // ""), (.layers|length // 0), (.events|length // 0), (.entities|length // 0), (.placedElements|length // 0), (.warps|length // 0), (.triggers|length // 0)] | @tsv' "$f"; done
```

Sortie :

```text
selbrume/maps/Selbrume.json	Selbrume	Selbrume	55	55	17	0	3	307	3	0
selbrume/maps/house 1.json	house 1	house 1	45	45	3	0	0	0	1	0
selbrume/maps/house 2.json	house 2	house 2	45	45	3	0	0	0	1	0
selbrume/maps/house 3.json	house 3	house 3	45	45	3	0	0	0	0	0
selbrume/maps/house 4.json	house 4	house 4	45	45	3	0	0	0	0	0
selbrume/maps/house 5.json	house 5	house 5	45	45	3	0	0	0	0	0
selbrume/maps/lab.json	lab	lab	45	45	3	0	0	0	0	0
selbrume/maps/pokémon center.json	pokémon center	pokémon center	45	45	3	0	0	0	0	0
selbrume/maps/pub.json	pub	pub	45	45	3	0	0	0	0	0
selbrume/maps/route 1.json	route 1	route 1	45	45	6	0	1	68	0	0
```

Entites :

```text
### selbrume/maps/Selbrume.json
spawn	spawn			
p6_03_intro_sign	P6-03 intro sign			
npc	npc			
### selbrume/maps/route 1.json
grant	grant			
```

Events :

```text
Tous les fichiers `selbrume/maps/*.json` audites ont `events: 0`.
```

Warps utiles :

```text
### selbrume/maps/Selbrume.json
to lab		Selbrume		
to house 1		house 1		
to house 2		house 2		
### selbrume/maps/house 1.json
warp		Selbrume		
### selbrume/maps/house 2.json
warp		Selbrume		
```

Indices port dans `Selbrume` :

```text
l_tile_ponton	ponton		3025
l_path_oc_an	océan		0
```

Premier placed element :

```json
{
  "id": "l_tile_ponton::6::33",
  "layerId": "l_tile_ponton",
  "elementId": "ponton_selbrume",
  "pos": {
    "x": 6,
    "y": 33
  },
  "applyCollision": true,
  "opacity": 1.0,
  "animation": null,
  "shadowOverride": null,
  "behaviors": [],
  "properties": {}
}
```

Decision : `Selbrume` peut avoir une zone portuaire, mais `map_port_brisants` n'existe pas comme map dediee.

## Inventaire dialogues Yarn

Commande :

```bash
for f in selbrume/dialogues/*.yarn; do printf '### %s\n' "$f"; wc -l "$f"; sed -n '1,120p' "$f"; done
```

Sortie :

```text
### selbrume/dialogues/g.yarn
       4 selbrume/dialogues/g.yarn
title: g
---
(Begin editing your dialogue here.)
===
### selbrume/dialogues/test.yarn
      35 selbrume/dialogues/test.yarn
title: Discussion_meteo
---
Narrateur: Un après-midi calme dans un village de montagne. L'air est frais et une brume légère flotte entre les arbres. Deux villageois, Marc et Léa, se croisent près de la fontaine.
Marc: Tiens, Léa ! Tu sors aussi profiter de cette fraîcheur ?
Léa: Oh, Marc ! Oui, je me disais que c'était le moment idéal pour une petite promenade. Mais cette brume... elle me rappelle les matins d'automne.
Marc: Exactement. Et avec ce vent léger, on dirait que l'hiver n'est pas loin. Tu as remarqué les feuilles qui commencent à tomber ?
Léa: Oui, c'est vrai. Les arbres perdent leurs couleurs déjà. Tu penses qu'on va avoir un hiver précoce cette année ?
```

Decision : `g.yarn` est placeholder ; `test.yarn` est un prototype meteo Marc/Lea, pas un dialogue Mael/Lysa.

## Inventaire scenes / cinematics / storylines

Commande :

```bash
jq -r '.scenes[]? | .id as $sid | (.name // "") as $name | .graph.nodes[]? | [$sid, $name, .id, (.kind // ""), (.title // ""), (.payload.kind // ""), (.payload.dialogueId // ""), (.payload.cinematicId // ""), (.payload.battleId // "")] | @tsv' selbrume/project.json
```

Sortie :

```text
scene_test	test	node_start	start	Début	start			
scene_test	test	node_end	end	Fin	end			
scene_test	test	node_end_2	end	Fin	end			
scene_test	test	node_battle	battle	grant	battle			
scene_test	test	node_yarn_dialogue_2	yarnDialogue	g	yarnDialogue	g		
scene_test	test	node_cinematic	cinematic	UwU	cinematic		cinematic_uwu	
```

Commande :

```bash
jq -r '.cinematics[]? | .id as $cid | (.title // .name // "") as $title | .timeline.steps[]? | [$cid,$title,.id,(.kind // ""),(.label // .title // ""),(.durationMs // "")] | @tsv' selbrume/project.json
```

Sortie :

```text
cinematic_uwu	UwU	step_wait	wait	Attente	300
cinematic_uwu	UwU	step_actor_move	actorMove	Déplacement Acteur	1700
cinematic_uwu	UwU	step_actor_move_2	actorMove	Déplacement Jean	3000
cinematic_uwu	UwU	step_actor_face	actorFace	Orientation Acteur	
cinematic_uwu	UwU	step_actor_emote	actorEmote	Acteur affiche Gêne	800
cinematic_uwu	UwU	step_actor_move_3	actorMove	Déplacement Acteur	400
cinematic_uwu	UwU	step_actor_emote_3	actorEmote	Acteur affiche Coeur	800
cinematic_uwu	UwU	step_actor_emote_2	actorEmote	Jean affiche Coeur	400
cinematic_uwu	UwU	step_actor_emote_4	actorEmote	Acteur affiche Coeur	400
cinematic_uwu	UwU	step_actor_emote_5	actorEmote	Jean affiche Coeur	200
cinematic_uwu	UwU	step_camera	camera	Caméra	500
```

Storyline chapter 1 utile :

```text
story_main_brume_phare	La brume du phare	chapter_1_port	Le port	step_intro_selbrume	Introduction à Selbrume		
story_main_brume_phare	La brume du phare	chapter_1_port	Le port	step_receive_mission	Recevoir la mission de Maël		
story_main_brume_phare	La brume du phare	chapter_1_port	Le port	step_go_to_port	Aller au Port des Brisants		
story_main_brume_phare	La brume du phare	chapter_1_port	Le port	step_rival_battle	Affronter Lysa		
```

## Inventaire characters / trainers / facts

Commande :

```bash
jq -r '.characters[]? | [.id, .name, (.tilesetId // ""), (.animations|length // 0), (.tags|length // 0)] | @tsv' selbrume/project.json
```

Sortie :

```text
vova	vova	vova	8	0
mael	mael	mael	8	0
lyra	lyra	lyra	8	0
rival	rival	timi	8	0
grant	grant	grant	8	0
```

Trainer `grant` :

```text
grant	grant	bulbasaur	1
grant	grant	dratini	25
grant	grant	ivysaur	25
```

Fact actuel :

```json
{
  "id": "fact_test",
  "label": "test",
  "description": "",
  "category": "test",
  "defaultValue": false,
  "tags": []
}
```

## Inventaire assets utiles

Commande :

```bash
find assets -maxdepth 4 -type f | rg -i "mael|maël|lysa|lyra|rival|grant|vova|selbrume|port|brume|phare|sprite|character|trainer|npc|battle|dialogue|cinematic" || true
```

Sortie :

```text
find: assets: No such file or directory
```

Commande :

```bash
jq -r '.tilesets[]? | [.id, (.name // ""), (.relativePath // .path // "")] | @tsv' selbrume/project.json | rg -i "mael|lyra|rival|grant|vova|ponton|bateau|water|sea|beach|selbrume|timi" || true
```

Sortie :

```text
vova	vova	assets/tilesets/vova.png
deep_water	deep_water	assets/tilesets/deep_water.png
selbrume_all_sprite	selbrume all sprite	assets/tilesets/selbrume_all_sprite.png
water_edge_only	water_edge_only	assets/tilesets/water_edge_only.png
beach_tile	beach tile	assets/tilesets/beach_tile.png
big_water_rock	big water rock	assets/tilesets/big_water_rock.png
small_water_rock	small water rock	assets/tilesets/small_water_rock.png
fleurs_selbrume_de_toure_es	fleurs selbrume détourées	assets/tilesets/fleurs_selbrume_de_toure_es.png
mael	mael	assets/tilesets/mael.png
lyra	lyra	assets/tilesets/lyra.png
timi	timi	assets/tilesets/timi.png
water_edge	water_edge	assets/tilesets/water_edge.png
grant	grant	assets/tilesets/grant.png
ponton_selbrume	ponton selbrume	assets/tilesets/ponton_selbrume.png
beach_wave	beach_wave	assets/tilesets/beach_wave.jpg
```

## Preuves bible / NS-GS utiles

Lignes utiles retenues :

```text
MVP Selbrume/selbrume.md:106:| `map_bourg_selbrume`    | Bourg de Selbrume               | Village de départ                    |
MVP Selbrume/selbrume.md:107:| `map_port_brisants`     | Port des Brisants               | Premier conflit, pêcheurs, rival     |
MVP Selbrume/selbrume.md:147:**Nom :** Maël
MVP Selbrume/selbrume.md:149:**Localisation :** Bourg de Selbrume
MVP Selbrume/selbrume.md:168:**Nom :** Lysa
MVP Selbrume/selbrume.md:169:**Rôle :** rival local / fille de pêcheur / protectrice du port
MVP Selbrume/selbrume.md:170:**Localisation :** Port des Brisants
MVP Selbrume/selbrume.md:543:ID : step_rival_battle
MVP Selbrume/selbrume.md:556:event_rival_port_meet
MVP Selbrume/selbrume.md:1995:ID : battle_rival_port
MVP Selbrume/selbrume.md:1997:Trainer : trainer_lysa_port
```

NS-GS lignes utiles :

```text
reports/gameplay/ns_gs/ns_gs_01_golden_slice_exact_specification.md:62:2 maps (map_bourg_selbrume, map_port_brisants)
reports/gameplay/ns_gs/ns_gs_01_golden_slice_exact_specification.md:66:2 dialogues Yarn (yarn_mael_intro, yarn_rival_intro)
reports/gameplay/ns_gs/ns_gs_01_golden_slice_exact_specification.md:68:1 combat trainer (battle_rival_port / trainer_lysa_port)
reports/gameplay/ns_gs/ns_gs_01_golden_slice_exact_specification.md:71:4+ world rules (NPC visibility changes)
reports/gameplay/ns_gs/ns_gs_03_content_inventory_fixture_plan.md:274:| `npc_mael` | Maël | Mentor / garde-nature, donne le starter | `map_bourg_selbrume` | `entity_mael_bourg` | NS-GS-08 | À créer | Interaction → scene_mael_intro |
reports/gameplay/ns_gs/ns_gs_03_content_inventory_fixture_plan.md:275:| `npc_lysa` | Lysa | Rivale, combat trainer | `map_port_brisants` | `entity_lysa_port` | NS-GS-09 | À créer | Interaction → scene_rival_meet |
reports/gameplay/ns_gs/ns_gs_03_content_inventory_fixture_plan.md:344:| `fact_starter_received` | Fact auteur (storyFlag) | Starter reçu | scene_mael_intro (setFlag) | event_mael_intro (condition anti-redon), world rules | NS-GS-08 | Posé après givePokemon |
reports/gameplay/ns_gs/ns_gs_03_content_inventory_fixture_plan.md:345:| `fact_mission_started` | Fact auteur (storyFlag) | Mission lancée | scene_mael_intro (setFlag) | event_rival_meet (condition), world rules | NS-GS-08 | Posé après dialogue mission |
reports/gameplay/ns_gs/ns_gs_03_content_inventory_fixture_plan.md:347:| `fact_rival_battle_done` | Fact auteur (storyFlag) | Combat rival terminé | scene_rival_meet (setFlag) | world rules, dialogue conditionnel Lysa | NS-GS-09 | Posé après battle outcome branch |
reports/gameplay/ns_gs/ns_gs_03_content_inventory_fixture_plan.md:498:| Trainer id | `trainer_lysa_port` | — | À créer | NS-GS-11 | Doit être dans le ProjectManifest |
reports/gameplay/ns_gs/ns_gs_03_content_inventory_fixture_plan.md:499:| Battle id | `battle_rival_port` | — | À créer | NS-GS-11 | Utilisé par `scenarioBattleOutcomeFlagName` |
```

## Decisions d'IDs

| Domaine | ID propose | Decision |
|---|---|---|
| Bourg | `map_bourg_selbrume` | MAP_TO_EXISTING or RENAME_LATER from `Selbrume`; confirmation required. |
| Port | `map_port_brisants` | NEEDS_USER_CONFIRMATION. |
| Mael character | `mael` | KEEP. |
| Mael entity | `entity_mael_bourg` | CREATE_LATER. |
| Lysa character | `lysa` or `lyra` | NEEDS_USER_CONFIRMATION. |
| Rival character | `rival` | NEEDS_USER_CONFIRMATION / possible prototype. |
| Lysa entity | `entity_lysa_port` | CREATE_LATER after decision. |
| Lysa trainer | `trainer_lysa_port` | CREATE_LATER. |
| Rival battle | `battle_rival_port` | CREATE_LATER. |
| Mael intro | `scene_mael_intro`, `yarn_mael_intro` | CREATE_LATER. |
| Rival meet | `scene_rival_meet`, `yarn_rival_intro` | CREATE_LATER. |
| Mission facts | `fact_mission_started`, `fact_starter_received` | CREATE_LATER. |
| Rival facts | `fact_rival_battle_done`, victory/defeat facts | NEEDS_USER_CONFIRMATION for exact names. |

## Matrices de gaps

| Gap | Domaine | Impact | Gravite | Bloque V1-139 ? | Decision |
|---|---|---|---|---|---|
| Lysa/Lyra/rival ambigu | Character | Mauvais ID possible. | P0_BLOCKER | Oui | NEEDS_USER_CONFIRMATION |
| Port des Brisants absent comme map | Map | Mauvais lieu d'authoring possible. | P0_BLOCKER | Oui | NEEDS_USER_CONFIRMATION |
| Mael sans entite/event/dialogue | Scene | Premiere interaction manquante. | P1_REQUIRED | Oui | CREATE_LATER |
| Dialogues Mael/Lysa absents | Dialogue | Narrative slice injouable. | P1_REQUIRED | Oui | CREATE_LATER |
| Battle Lysa absent | Battle | Rival battle absent. | P1_REQUIRED | Oui | CREATE_LATER |
| Facts/world rules absents | Progression | Conditions et dialogues non pilotables. | P1_REQUIRED | Oui | CREATE_LATER |
| Prototypes existants | Data hygiene | Risque de contenu faux. | P1_REQUIRED | Oui | IGNORE_PROTOTYPE |

## Matrice de readiness V1-139

| Condition | Etat | Preuve | Decision |
|---|---|---|---|
| IDs Mael | READY_WITH_RISK | `mael` existe, entity manquante. | Garder `mael`, creer `entity_mael_bourg`. |
| IDs Lysa | NOT_READY | `lysa` absent ; `lyra` et `rival` existent. | Confirmation Karim requise. |
| Map bourg | READY_WITH_USER_CONFIRMATION | `Selbrume` existe. | Confirmer mapping vers bourg. |
| Map port | NOT_READY | `map_port_brisants` absent ; port possible dans `Selbrume`. | Confirmation + review visuelle. |
| Dialogues | NOT_READY | `g.yarn` placeholder, `test.yarn` prototype. | Creer plus tard. |
| Scene graph canonique | NOT_READY | `scene_test` prototype. | Creer plus tard. |
| Battle Lysa | NOT_READY | Seul trainer `grant`. | Creer plus tard. |
| Facts/world rules | NOT_READY | 1 fact test, 0 world rules. | Creer plus tard. |
| Assets port | READY_WITH_RISK | bateau/ponton/eau presents. | Verifier visuellement. |

## Roadmaps modifiees

Fichiers modifies :

```text
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

Sections modifiees :

- V1-138 passe de RECOMMANDÉ a DONE.
- V1-138-bis est ajoute comme RECOMMANDÉ.
- Le prochain lot exact recommande devient `NS-SCENES-V1-138-bis — Selbrume Golden Slice Canonical ID Decision Closure`.
- Les mentions de prochain lot global actuel sont alignees sur V1-138-bis.

## Fichiers crees

```text
reports/narrativeStudio/scenes/ns_scenes_v1_138_selbrume_golden_slice_content_inventory_asset_gap_audit.md
reports/narrativeStudio/scenes/ns_scenes_v1_138_evidence_pack.md
```

Le contenu complet du rapport principal est structure dans les sections 1 a 25 du fichier `ns_scenes_v1_138_selbrume_golden_slice_content_inventory_asset_gap_audit.md`. Ce fichier Evidence Pack est le second fichier cree et contient ses propres preuves, commandes, decisions et validations finales.

## Fichiers supprimes

```text
<aucun>
```

## Tests / analyses

Aucun test Dart/Flutter n'a ete lance pour V1-138, car le lot est explicitement doc-only et ne modifie aucun fichier `packages/**`, `examples/**`, `assets/**`, `selbrume/**` ou `pubspec.yaml`.

Validation obligatoire doc-only :

```text
git diff --check
```

## Anti-scope

Respecte :

- aucun code produit modifie ;
- aucun fichier `selbrume/**` modifie ;
- aucun asset modifie ;
- aucune screenshot / Visual Gate creee ;
- aucun V1-139 demarre ;
- aucun runtime, Flame, GameState.

## Auto-review independante

| Point | Verdict |
|---|---|
| Lot vraiment doc-only | OK |
| Aucun `selbrume/**` modifie | A verifier par anti-scope final, attendu OK |
| Aucun `packages/**` modifie | A verifier par anti-scope final, attendu OK |
| Matrices exploitables | OK |
| IDs proposes non presentes comme deja ecrits | OK |
| Prototypes non promus | OK |
| Ambiguites Karim explicites | OK |
| V1-139 non demarre | OK |

## Critique du prompt

Le prompt est pertinent mais large. Il force une reconciliation utile entre plusieurs sources, mais certains points ne peuvent pas etre decides automatiquement :

- `lyra` peut etre Lysa ou non ;
- `rival` peut etre un role, un personnage separe ou un prototype ;
- la zone portuaire peut deja exister dans `Selbrume`, mais une revue visuelle est necessaire ;
- les noms de facts divergent entre bible et rapports NS-GS ;
- V1-139 serait premature sans confirmation utilisateur.

Conclusion critique : V1-138-bis est plus honnete que V1-139 immediat.

## Validations finales

Commande :

```bash
git diff --check
```

Sortie :

```text
<vide>
```

Commande :

```bash
rg -n "NS-SCENES-V1-138|NS-SCENES-V1-139|NS-SCENES-V1-138-bis" reports/narrativeStudio/scenes
```

Sortie utile exacte :

```text
reports/narrativeStudio/scenes/road_map_scenes.md:205:| NS-SCENES-V1-138 — Selbrume Golden Slice Content Inventory / Asset Gap Audit | DONE | Inventaire documentaire Selbrume : project.json, maps, characters, entities, trainers, dialogues, facts, world rules, assets et IDs canoniques reconciles ; verdict V1-139_SHOULD_WAIT car Lysa/Lyra/rival et Port des Brisants demandent confirmation Karim. |
reports/narrativeStudio/scenes/road_map_scenes.md:206:| NS-SCENES-V1-138-bis — Selbrume Golden Slice Canonical ID Decision Closure | RECOMMANDÉ | Fermer les decisions utilisateur avant authoring : Lysa/Lyra/rival, mapping Port des Brisants, IDs Mael/Lysa/battle/facts/world rules et strict perimetre V1-139. |
reports/narrativeStudio/scenes/road_map_scenes.md:210:`NS-SCENES-V1-138-bis — Selbrume Golden Slice Canonical ID Decision Closure`
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:12:NS-SCENES-V1-138-bis — Selbrume Golden Slice Canonical ID Decision Closure
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:196:| NS-SCENES-V1-138 | Selbrume Golden Slice Content Inventory / Asset Gap Audit | doc / content-inventory | Reconciler la bible Selbrume, `project.json`, maps, PNJ, trainers, dialogues, facts, world rules, assets et IDs canoniques avant toute ecriture de contenu golden slice. | Pas de contenu final, pas de runtime, pas de nouvelle feature, pas de modification Selbrume irreversible sans validation. | Rapport d'inventaire, matrice assets/gaps, IDs canoniques proposes, decisions de scope. | Audit data Selbrume, gaps d'assets, anti-scope produit. | Ecrire du contenu avant d'avoir stabilise les IDs ; confondre audit et seed. | DONE : inventaire brut et reconciliation realises ; V1-139 attend confirmation Karim sur Lysa/Lyra/rival et Port des Brisants. | V1-137 |
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:197:| NS-SCENES-V1-138-bis | Selbrume Golden Slice Canonical ID Decision Closure | doc / product-decision | Fermer les choix Karim avant authoring : Lysa/Lyra/rival, Port des Brisants, IDs Mael/Lysa/battle/facts/world rules et perimetre V1-139. | Pas de contenu final, pas de code produit, pas de modification Selbrume, pas de V1-139. | Rapport de decision court, table IDs definitive, roadmap V1-139 clarifiee. | Questions utilisateur, validation ID, anti-scope doc-only. | Lancer V1-139 avec de mauvais IDs ; transformer un bis de decision en authoring. | Recommande, non demarre. | V1-138 |
reports/narrativeStudio/scenes/ns_scenes_v1_138_selbrume_golden_slice_content_inventory_asset_gap_audit.md:10:NS-SCENES-V1-138 : DONE
reports/narrativeStudio/scenes/ns_scenes_v1_138_selbrume_golden_slice_content_inventory_asset_gap_audit.md:13:Prochain lot recommande : NS-SCENES-V1-138-bis — Selbrume Golden Slice Canonical ID Decision Closure
```

La commande retourne aussi les references historiques V1-137 et les mentions de progression existantes dans les roadmaps. Les lignes ci-dessus sont les lignes utiles exactes qui prouvent l'alignement V1-138 DONE et V1-138-bis recommande.

Commande :

```bash
git diff --name-only -- packages examples assets selbrume pubspec.yaml
```

Sortie :

```text
<vide>
```

Commande :

```bash
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_138*' -print
```

Sortie :

```text
<vide>
```

Commande :

```bash
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_139*' -print
```

Sortie :

```text
<vide>
```

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_138_evidence_pack.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_138_selbrume_golden_slice_content_inventory_asset_gap_audit.md
```

Commande :

```bash
git diff --stat
```

Sortie :

```text
 .../scenes/road_map_scene_builder_authoring.md     | 77 ++++++++++++---------
 reports/narrativeStudio/scenes/road_map_scenes.md  | 78 +++++++++++++---------
 2 files changed, 91 insertions(+), 64 deletions(-)
```

Commande :

```bash
git diff --name-only
```

Sortie :

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Note : les deux rapports V1-138 sont non suivis a ce stade, donc ils apparaissent dans `git status --short --untracked-files=all` mais pas dans `git diff --stat`.
