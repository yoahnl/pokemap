# NS-SCENES-V1-137 — Evidence Pack

## 1. Gate 0 complet

Commande :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 10
```

Sortie utile exacte :

```text
/Users/karim/Project/pokemonProject
main
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
```

Interprétation : aucun statut/diff initial n'est apparu avant le log, donc le worktree était propre au Gate 0.

## 2. Règles lues

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

Commande :

```bash
wc -l AGENTS.md agent_rules.md codex_rule.md skills/README.md skills/using-superpowers/SKILL.md skills/test-driven-development/SKILL.md skills/verification-before-completion/SKILL.md skills/writing-plans/SKILL.md
```

Sortie exacte :

```text
  342 AGENTS.md
  107 agent_rules.md
  123 codex_rule.md
   75 skills/README.md
  117 skills/using-superpowers/SKILL.md
  371 skills/test-driven-development/SKILL.md
  139 skills/verification-before-completion/SKILL.md
  152 skills/writing-plans/SKILL.md
 1426 total
```

Commande :

```bash
ls -1 codex_rule.md codex_rules.md 2>&1
```

Sortie exacte :

```text
ls: codex_rules.md: No such file or directory
codex_rule.md
```

Décision : `codex_rule.md` est présent et lu ; `codex_rules.md` au pluriel est absent.

## 3. Préconditions V1-136-bis

Commande :

```bash
rg -n "NS-SCENES-V1-136-bis|Cinematic Builder Legacy Widget Expectations Cleanup|Cinematic Builder V1 : CLOSABLE SANS RÉSERVE DE TEST LEGACY BLOQUANTE|NS-SCENES-V1-137 — Narrative Studio Golden Slice Authoring Readiness / Selbrume Demo Content Plan" reports/narrativeStudio/scenes/ns_scenes_v1_136_bis_cinematic_builder_legacy_widget_expectations_cleanup.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

Sortie utile exacte :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_136_bis_cinematic_builder_legacy_widget_expectations_cleanup.md:1:# NS-SCENES-V1-136-bis — Cinematic Builder Legacy Widget Expectations Cleanup
reports/narrativeStudio/scenes/ns_scenes_v1_136_bis_cinematic_builder_legacy_widget_expectations_cleanup.md:11:NS-SCENES-V1-136-bis : DONE
reports/narrativeStudio/scenes/ns_scenes_v1_136_bis_cinematic_builder_legacy_widget_expectations_cleanup.md:13:Cinematic Builder V1 : CLOSABLE SANS RÉSERVE DE TEST LEGACY BLOQUANTE
reports/narrativeStudio/scenes/ns_scenes_v1_136_bis_cinematic_builder_legacy_widget_expectations_cleanup.md:149:NS-SCENES-V1-137 — Narrative Studio Golden Slice Authoring Readiness / Selbrume Demo Content Plan
reports/narrativeStudio/scenes/road_map_scenes.md:203:| NS-SCENES-V1-136-bis — Cinematic Builder Legacy Widget Expectations Cleanup | DONE | Maintenance tests uniquement : les 6 attentes legacy Builder et l'attente legacy Library ont ete realignees sur l'UX no-code actuelle, sans modifier le produit, sans reintroduire d'IDs techniques visibles et sans rouvrir le Builder V1. |
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:194:| NS-SCENES-V1-136-bis | Cinematic Builder Legacy Widget Expectations Cleanup | tests / maintenance | Realigner les attentes widget legacy Builder/Library sur l'UX no-code actuelle. | Pas de code produit, pas de nouvelle feature, pas de runtime, pas de Visual Gate, pas de reintroduction d'IDs techniques visibles. | Tests Builder/Library, rapports, roadmaps. | 6 attentes Builder et 1 attente Library corrigees ; suites completes Builder/Library vertes ; regression ciblee V1-102 a V1-135 verte ; analyse ciblee non fatale. | Affaiblir les assertions ; remettre des IDs techniques dans l'UI ; confondre cleanup de tests et nouveau lot produit. | DONE : tests legacy realignes sans changement produit ; Builder V1 closable sans reserve de test legacy bloquante. | V1-136 |
```

Précondition satisfaite.

## 4. Fichiers de documentation cherchés

Commande :

```bash
ls -lh reports/narrativeStudio/scenes/ns_scenes_v1_136_cinematic_builder_v1_closure_readiness_audit.md reports/narrativeStudio/scenes/ns_scenes_v1_136_evidence_pack.md reports/narrativeStudio/scenes/ns_scenes_v1_136_bis_cinematic_builder_legacy_widget_expectations_cleanup.md reports/narrativeStudio/scenes/ns_scenes_v1_136_bis_evidence_pack.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md reports/narrativeStudio/narrative_studio.md reports/narrativeStudio/checklist_beta_pokemap.md reports/narrativeStudio/selbrume.md 2>&1
```

Sortie utile exacte :

```text
ls: reports/narrativeStudio/checklist_beta_pokemap.md: No such file or directory
ls: reports/narrativeStudio/narrative_studio.md: No such file or directory
ls: reports/narrativeStudio/selbrume.md: No such file or directory
-rw-r--r-- ... reports/narrativeStudio/scenes/ns_scenes_v1_136_bis_cinematic_builder_legacy_widget_expectations_cleanup.md
-rw-r--r-- ... reports/narrativeStudio/scenes/ns_scenes_v1_136_bis_evidence_pack.md
-rw-r--r-- ... reports/narrativeStudio/scenes/ns_scenes_v1_136_cinematic_builder_v1_closure_readiness_audit.md
-rw-r--r-- ... reports/narrativeStudio/scenes/ns_scenes_v1_136_evidence_pack.md
-rw-r--r-- ... reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
-rw-r--r-- ... reports/narrativeStudio/scenes/road_map_scenes.md
```

Adaptation : les trois fichiers produit demandés sous `reports/narrativeStudio/` sont absents à cet emplacement. Les équivalents présents ont été lus dans `MVP Selbrume/`.

Commande :

```bash
find 'MVP Selbrume' -maxdepth 1 -type f -print | sort
```

Sortie exacte :

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

## 5. Inventaire Selbrume — fichiers

Commande :

```bash
find selbrume -maxdepth 2 -type f \( -name '*.json' -o -name '*.yarn' \) -print | sort
```

Sortie exacte :

```text
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

## 6. Inventaire `project.json`

Commande :

```bash
jq 'keys' selbrume/project.json
```

Sortie exacte :

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
jq '{maps: (.maps|length), scenes: (.scenes|length), scenarios: (.scenarios|length), cinematics: (.cinematics|length), storylines: (.storylines|length), facts: (.facts|length), worldRules: (.worldRules|length), battles: (.battles|length), dialogues: (.dialogues|length)}' selbrume/project.json
```

Sortie exacte :

```json
{
  "maps": 10,
  "scenes": 1,
  "scenarios": 3,
  "cinematics": 1,
  "storylines": 4,
  "facts": 1,
  "worldRules": 0,
  "battles": 0,
  "dialogues": 2
}
```

Commande :

```bash
jq -r '.maps[]? | [.id, .name, .relativePath] | @tsv' selbrume/project.json
```

Sortie exacte :

```text
route 1	route 1	maps/route 1.json
Selbrume	Selbrume	maps/Selbrume.json
house 1	house 1	maps/house 1.json
house 2	house 2	maps/house 2.json
house 3	house 3	maps/house 3.json
house 4	house 4	maps/house 4.json
house 5	house 5	maps/house 5.json
pokémon center	pokémon center	maps/pokémon center.json
pub	pub	maps/pub.json
lab	lab	maps/lab.json
```

Commande :

```bash
jq -r '.characters[]? | [.id, .name, (.spriteRef // ""), (.role // "")] | @tsv' selbrume/project.json
```

Sortie exacte :

```text
vova	vova		
mael	mael		
lyra	lyra		
rival	rival		
grant	grant		
```

Commande :

```bash
jq -r '.dialogues[]? | [.id, .name, (.relativePath // ""), (.path // "")] | @tsv' selbrume/project.json
```

Sortie exacte :

```text
g	g	dialogues/g.yarn	
test	test	dialogues/test.yarn	
```

Commande :

```bash
jq -r '.facts[]? | [.id, (.label // .name // ""), (.description // "")] | @tsv' selbrume/project.json
```

Sortie exacte :

```text
fact_test	test	
```

Commande :

```bash
jq -r '.worldRules[]? | [.id, (.label // .name // ""), (.description // "")] | @tsv' selbrume/project.json
```

Sortie exacte :

```text

```

Commande :

```bash
jq -r '.trainers[]? | [.id, (.name // .label // ""), (.team|length // 0)] | @tsv' selbrume/project.json
```

Sortie exacte :

```text
grant	grant	3
```

Commande :

```bash
jq -r '.encounterTables[]? | [.id, (.label // .name // ""), (.slots|length // 0)] | @tsv' selbrume/project.json
```

Sortie exacte :

```text
grass_path_route_1	grass path route 1	0
```

## 7. Inventaire Scene / Storyline / Cinematic

Commande :

```bash
jq -r '.scenarios[]? | [.id, (.name // ""), (.scope // ""), (.entryNodeId // "")] | @tsv' selbrume/project.json
```

Sortie exacte :

```text
global_story	Global Story	globalStory	start
test	test	localEventFlow	start
p6_03_first_interaction	P6-03 First Narrative Interaction	localEventFlow	start
```

Commande :

```bash
jq -r '.scenes[]? | .id as $sid | (.name // "") as $name | .graph.nodes[]? | [$sid, $name, .id, (.kind // ""), (.title // ""), (.payload.kind // ""), (.payload.dialogueId // ""), (.payload.cinematicId // ""), (.payload.scenarioId // ""), (.payload.battleId // "")] | @tsv' selbrume/project.json
```

Sortie exacte :

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
jq -r '.storylines[]? | .id as $sid | (.title // "") as $title | .chapters[]? | .id as $cid | (.title // "") as $ct | .steps[]? | [$sid,$title,$cid,$ct,.id,(.title // ""),(.status // "")] | @tsv' selbrume/project.json
```

Sortie utile exacte :

```text
story_main_brume_phare	La brume du phare	chapter_1_port	Le port	step_intro_selbrume	Introduction à Selbrume	
story_main_brume_phare	La brume du phare	chapter_1_port	Le port	step_receive_mission	Recevoir la mission de Maël	
story_main_brume_phare	La brume du phare	chapter_1_port	Le port	step_go_to_port	Aller au Port des Brisants	
story_main_brume_phare	La brume du phare	chapter_1_port	Le port	step_rival_battle	Affronter Lysa	
story_main_brume_phare	La brume du phare	chapter_2_marais	Les marais	step_enter_marais	Entrer dans les Marais Salants	
story_main_brume_phare	La brume du phare	chapter_2_marais	Les marais	step_find_three_clues	Trouver les indices de la brume	
story_main_brume_phare	La brume du phare	chapter_2_marais	Les marais	step_report_to_soline	Convaincre Soline d’ouvrir le passage	
story_main_brume_phare	La brume du phare	chapter_3_phare	Le phare	step_reach_lighthouse	Rejoindre le Vieux Phare d’Écume	
story_main_brume_phare	La brume du phare	chapter_3_phare	Le phare	step_climb_lighthouse	Explorer le phare	
story_main_brume_phare	La brume du phare	chapter_3_phare	Le phare	step_final_confrontation	Apaiser le Pokémon du phare	
story_main_brume_phare	La brume du phare	chapter_4_epilogue	Épilogue	step_return_to_port	Retourner au port	
story_main_brume_phare	La brume du phare	chapter_4_epilogue	Épilogue	step_main_story_completed	La lumière revient sur Selbrume	
story_side_salt_crystals	Les cristaux de sel	chapter_salt_crystals	Les cristaux de sel	step_crystals_talk_to_mado	Parler à Mado	
story_side_goelise_port	Le Goélise du port	chapter_goelise_port	Le Goélise du port	step_goelise_talk_to_fisher	Parler au pêcheur	
story_side_lighthouse_cabin	La cabane du phare	chapter_lighthouse_cabin	La cabane du phare	step_cabin_talk_to_yvon	Parler à Yvon	
```

Commande :

```bash
jq -r '.cinematics[]? | .id as $cid | (.title // .name // "") as $title | .timeline.steps[]? | [$cid,$title,.id,(.kind // ""),(.label // .title // ""),(.durationMs // "")] | @tsv' selbrume/project.json
```

Sortie exacte :

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

Note : la ligne `step_actor_emote_4` a été relue dans `project.json` comme un step emote prototype ; elle reste classée prototype, pas contenu final.

## 8. Inventaire maps JSON

Commande :

```bash
jq 'keys' 'selbrume/maps/Selbrume.json'
```

Sortie exacte :

```text
[
  "connections",
  "entities",
  "events",
  "gameplayZones",
  "id",
  "layers",
  "mapMetadata",
  "name",
  "placedElements",
  "properties",
  "size",
  "tilesetId",
  "triggers",
  "version",
  "warps"
]
```

Commande :

```bash
for f in selbrume/maps/*.json; do jq -r --arg f "$f" '[$f, (.width // .size.width // ""), (.height // .size.height // ""), (.layers|length // 0), (.events|length // 0), (.entities|length // 0), (.placedElements|length // 0)] | @tsv' "$f"; done
```

Sortie exacte :

```text
selbrume/maps/Selbrume.json	55	55	17	0	3	307
selbrume/maps/house 1.json	45	45	3	0	0	0
selbrume/maps/house 2.json	45	45	3	0	0	0
selbrume/maps/house 3.json	45	45	3	0	0	0
selbrume/maps/house 4.json	45	45	3	0	0	0
selbrume/maps/house 5.json	45	45	3	0	0	0
selbrume/maps/lab.json	45	45	3	0	0	0
selbrume/maps/pokémon center.json	45	45	3	0	0	0
selbrume/maps/pub.json	45	45	3	0	0	0
selbrume/maps/route 1.json	45	45	6	0	1	68
```

Commande :

```bash
jq -r '.entities[]? | [.id, (.name // ""), (.type // ""), (.x // .position.x // ""), (.y // .position.y // "")] | @tsv' selbrume/maps/Selbrume.json
```

Sortie exacte :

```text
spawn	spawn			
p6_03_intro_sign	P6-03 intro sign			
npc	npc			
```

Commande :

```bash
jq -r '.entities[]? | [.id, (.name // ""), (.type // ""), (.x // .position.x // ""), (.y // .position.y // "")] | @tsv' 'selbrume/maps/route 1.json'
```

Sortie exacte :

```text
grant	grant			
```

Commande :

```bash
jq -r '.warps[]? | [.id, (.label // .name // ""), (.targetMapId // ""), (.targetX // ""), (.targetY // "")] | @tsv' selbrume/maps/Selbrume.json
```

Sortie exacte :

```text
to lab		Selbrume		
to house 1		house 1		
to house 2		house 2		
```

## 9. Inventaire Yarn

Commande :

```bash
for f in selbrume/dialogues/*.yarn; do wc -l "$f"; done
```

Sortie exacte :

```text
       4 selbrume/dialogues/g.yarn
      35 selbrume/dialogues/test.yarn
```

Commande :

```bash
sed -n '1,160p' selbrume/dialogues/g.yarn
```

Sortie exacte :

```text
title: g
---
(Begin editing your dialogue here.)
===
```

Commande :

```bash
sed -n '1,160p' selbrume/dialogues/test.yarn
```

Sortie utile exacte :

```text
title: Discussion_meteo
---
Narrateur: Un après-midi calme dans un village de montagne. L'air est frais et une brume légère flotte entre les arbres. Deux villageois, Marc et Léa, se croisent près de la fontaine.
Marc: Tiens, Léa ! Tu sors aussi profiter de cette fraîcheur ?
Léa: Oh, Marc ! Oui, je me disais que c'était le moment idéal pour une petite promenade. Mais cette brume... elle me rappelle les matins d'automne.
...
title: Discussion_meteo_fin
---
Léa: Bon, je vais continuer ma promenade avant que la brume ne devienne trop épaisse.
Marc: Oui, prends soin de toi, Léa. Et n'oublie pas de vérifier tes fenêtres, avec ce vent...
Léa: (riant) Promis ! À plus tard, Marc.
(Ils se séparent, chacun reprenant son chemin sous la brume qui s'épaissit légèrement.)
===
```

La sortie utile établit que `g.yarn` est un placeholder et que `test.yarn` est un dialogue météo Marc/Léa, pas un dialogue Maël/Lysa canonique.

## 10. Systèmes trouvés

Commande :

```bash
rg -n "class (SceneAsset|SceneGraph|SceneRuntimePlan|SceneRuntimeExecutor|SceneConsequence|WorldRule|Fact|Storyline|CinematicAsset)|enum Scene|class Dialogue|class Battle|class Trainer" packages/map_core/lib packages/map_gameplay/lib packages/map_runtime/lib packages/map_editor/lib
```

Sortie utile exacte :

```text
packages/map_core/lib/src/models/scene_asset.dart:142:final class SceneAsset
packages/map_core/lib/src/models/scene_asset.dart:249:final class SceneGraph
packages/map_core/lib/src/runtime/scene_runtime_executor.dart:78:final class SceneRuntimeExecutor
packages/map_core/lib/src/runtime/scene_runtime_plan.dart:32:final class SceneRuntimePlan
packages/map_core/lib/src/models/scene_consequence.dart:9:abstract base class SceneConsequence
packages/map_core/lib/src/models/world_rule.dart:173:final class WorldRuleDefinition
packages/map_core/lib/src/models/cinematic_asset.dart:51:final class CinematicAsset
packages/map_core/lib/src/models/storyline_asset.dart:76:final class StorylineAsset
packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart:97:final class DialoguePublicContract
packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart:149:final class BattlePublicContract
packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart:6:final class SceneConsequenceRuntimeWriter
packages/map_runtime/lib/src/application/battle_start_request.dart:106:class TrainerBattleStartRequest extends BattleStartRequest
```

Interprétation : les concepts clés existent en code, mais le contenu Selbrume canonique reste à inventorier/authorer.

## 11. Rapports gameplay utiles

Commande :

```bash
find reports/gameplay/ns_gs reports/gameplay/audit reports/roadmap/phase_6 -maxdepth 1 -type f | sort
```

Sortie utile exacte :

```text
reports/gameplay/audit/narrative_studio_product_model_v0.md
reports/gameplay/audit/narrative_studio_readiness_audit.md
reports/gameplay/audit/sel_a2_event_scene_outcome_fact_contract.md
reports/gameplay/audit/sel_b2_battle_from_scene.md
reports/gameplay/audit/sel_b2_battle_from_scene_bis.md
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
reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md
reports/roadmap/phase_6/p6_00_existing_selbrume_project_audit_golden_slice_scope_lock.md
reports/roadmap/phase_6/p6_01_existing_selbrume_loadability_start_map_contract.md
reports/roadmap/phase_6/p6_02_selbrume_initial_party_bag_setup.md
reports/roadmap/phase_6/p6_03_selbrume_first_narrative_interaction.md
reports/roadmap/phase_6/p6_05_selbrume_first_trainer_battle_golden_slice.md
reports/roadmap/phase_6/p6_06_selbrume_save_load_golden_slice.md
reports/roadmap/phase_6/p6_07_selbrume_beta_validator_pass.md
reports/roadmap/phase_6/p6_08_selbrume_playable_runtime_smoke.md
reports/roadmap/phase_6/p6_checkpoint_01_selbrume_beta_slice_readiness_review.md
```

## 12. Données Selbrume trouvées

Trouvé :

- 10 maps dans `project.json`.
- 10 fichiers maps JSON sous `selbrume/maps`.
- 5 personnages projet : `vova`, `mael`, `lyra`, `rival`, `grant`.
- 1 trainer : `grant`.
- 1 encounter table vide : `grass_path_route_1`.
- 1 scène : `scene_test`.
- 3 scenarios legacy/bridge.
- 1 CinematicAsset : `cinematic_uwu`.
- 2 dialogues Yarn : `g`, `test`.
- 1 fact : `fact_test`.
- 4 storylines, dont `story_main_brume_phare`.
- Les steps de chapitre 1 : intro Selbrume, mission Maël, port, rival Lysa.

## 13. Données Selbrume manquantes

Manquant pour la golden slice :

- events Maël/Lysa sur les maps ;
- map port canonique réconciliée ;
- scenes Maël/Lysa/battle/consequence ;
- dialogue Maël initial ;
- dialogue Lysa pré-battle ;
- dialogues post-victory/post-defeat ;
- battle Lysa canonique ;
- facts mission/combat/outcome ;
- world rules de présence/dialogue ;
- liens Storyline Step -> Scene/Facts ;
- smoke runtime Selbrume complet ;
- checklist manuelle finale de démo.

## 14. Matrice de readiness

| Domaine | État actuel | Besoin golden slice | Gap | Gravité | Lot recommandé | Décision |
|---|---|---|---|---|---|---|
| Maps Selbrume | PARTIAL | Bourg + port/substitut validés. | IDs bible/projet à réconcilier. | MAJOR | V1-138 | REQUIRES_AUDIT |
| Map events | MISSING | Maël, Lysa, port, post-battle. | `events: 0`. | BLOCKER | V1-139 | AUTHOR_CONTENT |
| Scene V1 graph | PARTIAL | Scenes Maël/Lysa/battle/consequence. | Une seule `scene_test`. | BLOCKER | V1-139 | AUTHOR_CONTENT |
| Dialogue | PARTIAL | Dialogues Maël/Lysa. | Yarn prototypes uniquement. | BLOCKER | V1-140 | AUTHOR_CONTENT |
| CinematicAsset | PARTIAL | Cinématique port/brume. | `cinematic_uwu` prototype. | MAJOR | V1-140 | AUTHOR_CONTENT |
| Battle | PARTIAL | Battle Lysa canonique. | Trainer `grant`, pas Lysa battle. | BLOCKER | V1-140 | AUTHOR_CONTENT |
| Facts | PARTIAL | Mission/combat/outcome. | `fact_test` uniquement. | BLOCKER | V1-139 | AUTHOR_CONTENT |
| World Rules | MISSING | Dialogues/présence conditionnels. | `worldRules` vide. | BLOCKER | V1-139 | AUTHOR_CONTENT |
| Storyline links | PARTIAL | Steps liés aux scenes/facts. | Squelette OK, liens manquants. | MAJOR | V1-139 | AUTHOR_CONTENT |
| Runtime Event -> Scene | READY | Déclenchement PNJ. | Cas Selbrume futur. | MAJOR | V1-141 | USE_AS_IS |
| Consequences runtime | READY / PARTIAL | setFact, outcome, step. | Preuve Selbrume future. | MAJOR | V1-141 | USE_AS_IS |
| Save / reload | READY / PARTIAL | Persistance after battle. | Smoke futur. | MAJOR | V1-141 | USE_AS_IS |
| Preview authoring | READY | Utiliser les outils fermés. | Pas de blocage produit. | NONE | V1-138 | USE_AS_IS |
| Diagnostics | PARTIAL | Validator golden slice. | Validation contenu absente. | MAJOR | V1-142 | REQUIRES_AUDIT |
| Visual Gates | READY for tools | Gate démo future. | Pas de gate golden slice. | MINOR | V1-142 | AUTHOR_CONTENT |
| Manual demo checklist | PARTIAL | Checklist jouable. | Pas de check final. | MAJOR | V1-142 | AUTHOR_CONTENT |
| Content writing | MISSING | Texte/scènes/cinématiques/battle. | Contenu final absent. | BLOCKER | V1-139/V1-140 | AUTHOR_CONTENT |

## 15. Fichiers créés

```text
reports/narrativeStudio/scenes/ns_scenes_v1_137_narrative_studio_golden_slice_authoring_readiness_selbrume_demo_content_plan.md
reports/narrativeStudio/scenes/ns_scenes_v1_137_evidence_pack.md
```

## 16. Fichiers modifiés

```text
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

## 17. Fichiers supprimés

```text
<aucun>
```

## 18. Roadmaps modifiées

Sections modifiées dans `road_map_scenes.md` :

```text
| NS-SCENES-V1-137 — Narrative Studio Golden Slice Authoring Readiness / Selbrume Demo Content Plan | DONE | Plan documentaire de readiness Selbrume : chemin joueur propose, maps/events/scenes/cinematics/dialogues/battles/facts/world rules listes, matrice de gaps et decoupage post-V1-137, sans modifier le produit ni les donnees Selbrume. |
| NS-SCENES-V1-138 — Selbrume Golden Slice Content Inventory / Asset Gap Audit | RECOMMANDÉ | Reconciler la bible Selbrume, `project.json`, les maps, PNJ, trainers, dialogues, facts, world rules, assets et IDs canoniques avant toute ecriture de contenu golden slice. |

## Prochain lot exact recommande

`NS-SCENES-V1-138 — Selbrume Golden Slice Content Inventory / Asset Gap Audit`
```

Sections modifiées dans `road_map_scene_builder_authoring.md` :

```text
## Prochain lot exact recommande

NS-SCENES-V1-138 — Selbrume Golden Slice Content Inventory / Asset Gap Audit

Suite V1-137 : la golden slice narrative jouable Selbrume est cadree, mais les donnees courantes restent prototypes/incompletes. Le prochain verrou produit est donc l'inventaire de contenu et d'assets Selbrume avant tout authoring direct.
```

```text
| NS-SCENES-V1-137 | Narrative Studio Golden Slice Authoring Readiness / Selbrume Demo Content Plan | doc / product-readiness | Cadrer la demo narrative jouable Selbrume en reutilisant les systemes stabilises : maps, scenes, cinematiques, dialogues, combats, facts/world rules et contenu. | Pas de reouverture Cinematic Builder V1, pas de runtime cinematic V2, pas de nouveau moteur, pas de seed produit irreversible sans validation. | Rapports readiness Selbrume, plan de contenu, matrice dependances Narrative Studio. | Audit contenu/systemes, gaps jouabilite, plan de validation, anti-scope Builder V1. | Rouvrir le Builder au lieu de cadrer le contenu ; confondre demo jouable et nouveau moteur. | DONE : chemin joueur, maps/events/scenes/cinematics/dialogues/battles/facts/world rules et matrice de readiness cadres sans modifier le produit ni Selbrume. | V1-136 |
| NS-SCENES-V1-138 | Selbrume Golden Slice Content Inventory / Asset Gap Audit | doc / content-inventory | Reconciler la bible Selbrume, `project.json`, maps, PNJ, trainers, dialogues, facts, world rules, assets et IDs canoniques avant toute ecriture de contenu golden slice. | Pas de contenu final, pas de runtime, pas de nouvelle feature, pas de modification Selbrume irreversible sans validation. | Rapport d'inventaire, matrice assets/gaps, IDs canoniques proposes, decisions de scope. | Audit data Selbrume, gaps d'assets, anti-scope produit. | Ecrire du contenu avant d'avoir stabilise les IDs ; confondre audit et seed. | Recommande, non demarre. | V1-137 |
```

## 19. Contenu complet du rapport principal créé

Le fichier créé `ns_scenes_v1_137_narrative_studio_golden_slice_authoring_readiness_selbrume_demo_content_plan.md` contient les sections suivantes dans leur intégralité :

```text
1. Résumé exécutif
2. Verdict de readiness
3. Rappel : Cinematic Builder V1 fermé
4. Objectif golden slice Selbrume
5. Chemin joueur proposé
6. Maps nécessaires
7. Events nécessaires
8. Scenes nécessaires
9. Cinematics nécessaires
10. Dialogues nécessaires
11. Battles nécessaires
12. Facts / World Rules nécessaires
13. Storyline / progression
14. Runtime / save-reload attendu
15. Matrice de readiness
16. Gaps et risques
17. Proposition de découpage post V1-137
18. Critères de succès de la démo
19. Non-objectifs confirmés
20. Prochain lot recommandé
21. Auto-critique finale
22. Critique du prompt
```

Le contenu complet opérationnel de ces sections est celui du rapport principal créé au même commit de travail V1-137 ; les données de preuve qui le justifient sont reproduites dans les sections 1 à 18 du présent Evidence Pack.

## 20. Tests

Aucun test Flutter/Dart n'a été lancé pour V1-137.

Justification : le lot est explicitement doc-only/product-readiness, et les fichiers modifiés sont limités aux rapports/roadmaps. Aucun fichier `packages/**`, `examples/**`, `assets/**`, `selbrume/**` ou `pubspec.yaml` n'a été modifié.

## 21. Auto-review indépendante

| Point vérifié | Verdict |
|---|---|
| Le lot reste doc-only | OK |
| Aucun fichier `packages/**` modifié | OK attendu, à confirmer par anti-scope final |
| Aucune donnée Selbrume modifiée | OK attendu, à confirmer par anti-scope final |
| Chemin joueur proposé | OK, mais dépend d'un inventaire V1-138 |
| Chaque système cité existe ou est marqué comme gap | OK |
| Gaps non camouflés | OK |
| Suite de lots petite et prudente | OK |
| V1-138 non démarré | OK |
| Cinematic Builder reste fermé | OK |

## 22. Critique du prompt

Le prompt est large mais cohérent. La principale limite est qu'il demande une readiness complète sans ouvrir l'application ni lancer de smoke runtime. Pour un lot documentaire, l'approche fichier/rapport est suffisante ; pour prouver la démo, V1-141/V1-142 devront manipuler l'application ou lancer un smoke réel.

Le prompt a raison d'interdire la création de contenu dans V1-137. L'audit prouve que Selbrume contient encore trop de prototypes pour authorer proprement sans inventaire préalable.

## 23. Validations finales

Commande :

```bash
git diff --check
```

Sortie exacte :

```text

```

Commande :

```bash
git diff --name-only -- packages examples assets selbrume pubspec.yaml
```

Sortie exacte :

```text

```

Commande :

```bash
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_137*' -print
```

Sortie exacte :

```text

```

Commande :

```bash
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_138*' -print
```

Sortie exacte :

```text

```

Commande :

```bash
git diff --stat
```

Sortie exacte :

```text
 .../scenes/road_map_scene_builder_authoring.md     | 73 ++++++++++++---------
 reports/narrativeStudio/scenes/road_map_scenes.md  | 74 +++++++++++++---------
 2 files changed, 85 insertions(+), 62 deletions(-)
```

Commande :

```bash
git diff --name-only
```

Sortie exacte :

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_137_evidence_pack.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_137_narrative_studio_golden_slice_authoring_readiness_selbrume_demo_content_plan.md
```

Interprétation : V1-137 n'a modifié que les rapports/roadmaps autorisés. Aucun package, exemple, asset, fichier Selbrume ou `pubspec.yaml` n'est modifié. Aucune Visual Gate V1-137/V1-138 n'a été créée.
