# PokeMap Full Product Phased Roadmap V1

## 1. Résumé exécutif

ROADMAP-01 ferme une proposition stratégique, pas une implémentation.

Verdict principal :

- Le bloc NS-GS-01 -> NS-GS-18 est terminé comme bloc mechanics-first, principalement au niveau **Level 2 Application**.
- PokeMap possède déjà des briques runtime/application solides : New Game, GivePokemon, GiveItem, steps, scenes, outcomes, world rules, trainer battle, boss trainer-like, side quest pattern, item reward post-battle et Narrative Validator V0.
- PokeMap ne possède pas encore un produit no-code complet : Event model canonique, Storyline/Chapter/StoryStep product model stabilisé, vrai Cinematic model, registries Facts/World Rules, UI validator, Flame Golden Slice complet et validation disk/editor restent partiels ou non prouvés.
- La décision utilisateur nouvelle est intégrée : **la refonte UI moderne / premium devient une phase tardive**, après stabilisation produit, domaine, runtime, validation et workflows no-code.
- NS-GS-19 n'est pas le prochain chantier automatique. Il devient un sous-chantier futur de la phase Gameplay Gaps.

Recommandation :

```text
Phase recommandée ensuite : Phase 1 — Canonical Product Model / Narrative Studio foundations
```

Prochain lot exact recommandé :

```text
P1-01 — Canonical Narrative Product Model V1
```

Ce prochain lot doit figer les frontières produit : Storyline, Chapter, Story Step, Event, Scene, Cinematic, Dialogue Yarn, Fact, World Rule et Validator. Il doit rester documentaire/design-first, sans UI premium ni modèle JSON lourd tant que les contrats ne sont pas validés.

## 2. Objectif final du projet

Objectif final :

```text
Créer un outil moderne de création de fangame Pokémon-like,
no-code autant que possible,
proche d'un RPG Maker Pokémon-like,
permettant à une personne non développeuse de créer un jeu court, jouable, cohérent,
avec exploration, histoire, événements, dialogues, cinématiques, combats, progression,
quêtes annexes, sauvegarde, validation et runtime.
```

Le créateur doit penser en :

```text
situations
événements
scènes
décisions
conséquences
progression
faits du monde
règles visibles du monde
```

La grammaire cible reste :

```text
Quand [déclencheur]
Si [conditions]
Alors [actions / scène / dialogue / combat / cinématique]
Puis [conséquences / faits / changements du monde]
```

Le produit final ne doit pas être un éditeur de flags techniques ni seulement un éditeur de maps. Il doit permettre d'authorer une boucle RPG courte : maps, exploration, events, dialogues, scenes, battles, items, rewards, progression, save/load, validation et runtime jouable.

## 3. Documents et sources lus

Documents canoniques lus :

- `AGENTS.md`
- `pokemap_roadmap_mecaniques_fangame.md`
- `MVP Selbrume/narrative_studio.md`
- `MVP Selbrume/selbrume.md`
- `MVP Selbrume/road_map.md`
- `reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md`

Rapports NS-GS lus ou inspectés :

- `reports/gameplay/ns_gs/ns_gs_18_reward_money_xp_bridge_audit.md`
- `reports/gameplay/ns_gs/ns_gs_17_static_encounter_boss_battle_readiness.md`
- `reports/gameplay/ns_gs/ns_gs_16_side_quest_optional_storyline_readiness.md`
- `reports/gameplay/ns_gs/ns_gs_15_key_item_door_gate_readiness.md`
- `reports/gameplay/ns_gs/ns_gs_14_item_pickup_give_item_authoring_readiness.md`
- `reports/gameplay/ns_gs/ns_gs_13_bis_evidence_pack_closure.md`
- `reports/gameplay/ns_gs/ns_gs_13_narrative_validator_minimal_v0.md`
- `reports/gameplay/ns_gs/ns_gs_12_bis_evidence_pack_and_level_label_fix.md`
- `reports/gameplay/ns_gs/ns_gs_12_editor_authored_golden_slice_validation.md`
- `reports/gameplay/ns_gs/ns_gs_11_bis_evidence_pack_fix.md`
- `reports/gameplay/ns_gs/ns_gs_11_trainer_battle_authoring_readiness.md`
- `reports/gameplay/ns_gs/ns_gs_10_world_rules_conditional_presence_readiness.md`
- `reports/gameplay/ns_gs/ns_gs_09_yarn_outcome_scene_branch_readiness.md`
- `reports/gameplay/ns_gs/ns_gs_08_npc_interaction_scene_authoring_readiness.md`
- `reports/gameplay/ns_gs/ns_gs_07_step_completion_progression_hooks.md`
- `reports/gameplay/ns_gs/ns_gs_06_bis_give_pokemon_runtime_payload_hardening.md`
- `reports/gameplay/ns_gs/ns_gs_06_give_pokemon_minimal.md`
- `reports/gameplay/ns_gs/ns_gs_05_new_game_minimal_runtime.md`

Fichiers projet inspectés :

- `packages/map_core/lib/map_core.dart`
- `packages/map_gameplay/lib/map_gameplay.dart`
- `packages/map_runtime/lib/map_runtime.dart`
- `packages/map_battle/lib/map_battle.dart`
- inventaire `packages/map_core/lib`
- inventaire `packages/map_runtime/lib`
- inventaire `packages/map_editor/lib`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart`
- inventaire `examples/playable_runtime_host`
- `examples/playable_runtime_host/README.md`

Note de chemin : les rapports NS-GS récents sont présents sous `reports/gameplay/ns_gs/`. Les anciens chemins plats mentionnés dans plusieurs briefs ne correspondent plus à l'emplacement réel courant.

Note skills : `skills/README.md` est absent dans le repo.

## 4. État actuel après NS-GS-01 → NS-GS-18

Synthèse :

| Bloc | Statut | Résultat réel |
|---|---:|---|
| NS-GS-01 -> 04-bis | ✅ prouvé | Alignement mechanics-first, Selbrume comme référence, pas comme contenu à générer. |
| NS-GS-05 | ✅ prouvé | `createNewGameState`, état initial générique, party/bag/flags/progression vides. |
| NS-GS-06 / 06-bis | ✅ prouvé | `givePokemon`, action scénario, payload durci. |
| NS-GS-07 / 07-bis | ✅ prouvé | `completeStep`, predicates step, persistance progression. |
| NS-GS-08 | ✅ prouvé | `entityInteract` peut déclencher une scène au niveau executor. |
| NS-GS-09 | ✅ prouvé | `emitOutcome` -> flag -> branch de scène. |
| NS-GS-10 | ✅ prouvé | World rules de présence/dialogue selon facts/steps au niveau evaluator. |
| NS-GS-11 / 11-bis | ✅ prouvé | `startTrainerBattle` -> effect battle -> outcome -> continuation. |
| NS-GS-12 / 12-bis | ✅ prouvé | Golden Slice générique au **Level 2 Application**, label corrigé. |
| NS-GS-13 / 13-bis | ✅ prouvé | Narrative Validator V0 pure Dart dans `map_core`, 16 tests, evidence fermé. |
| NS-GS-14 | ✅ prouvé | Item pickup / giveItem authorable, save/load, anti double pickup par condition/fact/world rule pattern. |
| NS-GS-15 | ⚠️ partiel | Door gate prouvé via fact dérivé ; `hasItem` direct absent. |
| NS-GS-16 | ✅ prouvé | Side quest V0 par facts/steps/scenes/giveItem/world rule, sans Quest Engine. |
| NS-GS-17 | ⚠️ partiel | Boss trainer-like prouvé ; static wild authorable réel non prouvé. |
| NS-GS-18 | ⚠️ partiel | Item reward post-battle prouvé via scène ; money/XP/reward model absents ou partiels. |

Conclusion : le bloc NS-GS a bien transformé un ensemble de pièces en boucle narrative/gameplay générique au niveau application. Il ne prouve pas encore le produit final no-code, ni le Golden Slice complet dans Flame, ni un vrai projet disque créé dans l'éditeur.

## 5. Matrice complète des acquis

Niveaux de preuve :

```text
Level 1 — unit / pure model
Level 2 — application layer / ScenarioRuntimeExecutor
Level 3 — Flame / PlayableMapGame
Level 4 — disk project / vrai projet créé dans l'éditeur
```

| Domaine | Statut | Niveau | Fichiers / preuves | Limites | Prochain besoin | Priorité |
|---|---:|---|---|---|---|---:|
| New Game | ✅ prouvé | Level 1/2 | `createNewGameState`, `new_game_state_builder_test.dart`, NS-GS-05 | Pas de spawn/manifest policy complète | Contract start project / spawn | Haute |
| GivePokemon | ✅ prouvé | Level 1/2 | `GameStateMutations.givePokemon`, `kScenarioActionGivePokemon`, NS-GS-06 | Pas de stats/learnset/party cap 6 | Gift Pokémon authoring contract | Moyenne |
| GiveItem | ✅ prouvé | Level 1/2 | `GameStateMutations.giveItem`, `kScenarioActionGiveItem`, NS-GS-14 | Pas d'item catalogue / effects / Bag UI | Item model futur | Moyenne |
| Step completion | ✅ prouvé | Level 1/2 | `completeStep`, `completedStepIds`, NS-GS-07 | Pas de Step registry canonique | Story Step model | Haute |
| NPC interaction -> Scene | ✅ prouvé | Level 2 | `kScenarioSourceEntityInteract`, NS-GS-08 | Executor-level dominant | Event model + Flame harness | Haute |
| Yarn/outcome -> branch | ✅ prouvé | Level 2 | `emitOutcome`, `sourceOutcome`, NS-GS-09 | Yarn réel/Dialogue Studio bridge incomplet | Yarn outcome contract | Haute |
| World Rules | ✅ prouvé | Level 1/2 | `MapEntityRuntimePredicateEvaluator`, NS-GS-10 | Projection surtout NPC/dialogue, Flame refresh complet non prouvé | WorldRule registry | Haute |
| Trainer Battle | ✅ prouvé | Level 2 | `startTrainerBattle`, `ScenarioRuntimeEffectType.battle`, NS-GS-11 | Level 3 complet non prouvé | Flame battle handoff harness | Haute |
| Boss trainer-like battle | ✅ prouvé | Level 2 | NS-GS-17 tests | Ce n'est pas un wild/static réel | Boss/static taxonomy | Moyenne |
| Static wild encounter | ⚠️ partiel | Level 1/2 hors scénario | Wild encounter runtime existe, `WildBattleStartRequest` existe | Pas `startStaticEncounter` / scénario authorable | Static Encounter design | Moyenne |
| Item pickup | ✅ prouvé | Level 2 avec un test PlayableMapGame ciblé | NS-GS-14 | Pas Item Studio / Bag UI | Authoring workflow minimal | Moyenne |
| Key item / door gate pattern | ⚠️ partiel | Level 2 | NS-GS-15 | `hasItem` direct absent, pas Door Engine, pas warp conditionnel | hasItem / gate contract decision | Moyenne |
| Side quest / optional storyline | ✅ prouvé | Level 2 | NS-GS-16 | Pas Quest Engine / Quest UI | Storyline/Step product model | Haute |
| Post-battle item reward | ✅ prouvé | Level 2 | `reward_bridge_readiness_test.dart`, NS-GS-18 | Via scène, pas Reward model | Reward Model Minimal Design | Moyenne |
| Money | ⚠️ partiel | Level 1 state only | `TrainerProfile.money` dans `save_data.dart` | Pas mutation/action/reward bridge | Money reward design | Moyenne |
| XP / level-up / learn move | ❌ absent | Non prouvé | `PlayerPokemon.level` existe, learnset seed battle existe | Pas XP field, pas addExperience, pas level-up post-battle | XP design phase | Moyenne |
| Save/load | ✅ prouvé | Level 1/2 | `game_state_persistence.dart`, multiples NS-GS | Level 4 projet disque narratif non prouvé | Disk validation harness | Haute |
| Narrative Validator | ✅ prouvé | Level 1 | `narrative_validator.dart`, `narrative_validator_test.dart`, NS-GS-13 | Pas intégré editor/runtime UI | Validator integration design | Haute |
| PlayableMapGame / Flame runtime | ⚠️ partiel | Level 3 partiel | `PlayableMapGame`, host, quelques tests ciblés | Golden Slice NS-GS complet non prouvé | Flame harness plan | Haute |
| Disk project / vrai projet éditeur | ❌ non prouvé pour NS-GS | Level 4 absent | `playable_runtime_host/golden_battle_slice/project.json` existe pour battle/surface runtime | Pas projet narratif créé dans editor puis exécuté | Disk project validation | Haute |
| Map Editor authoring | ⚠️ partiel | Level 4 partiel hors NS-GS | `map_editor` use cases, studios existants | Workflows narratifs pas alignés canonically | Authoring Workflows phase | Haute |
| Narrative Studio existing UI | ⚠️ partiel | UI existante | `NarrativeWorkspaceCanvas`, Global/Step/Cutscene/Dialogue workspaces | Concepts hérités ambigus, pas modèle canonique final | Phase 1 puis 4/7 | Haute |
| Cinematic Builder | ⚠️ partiel | Editor/runtime existing cutscene | `CutsceneStudioWorkspace`, `cutscene_runtime_runner.dart` | Scene vs Cinematic encore à clarifier produit | Cinematic contract | Haute |
| Event Builder | ⚠️ partiel | Map events/triggers existent | `map_event_definition.dart`, trigger/event services | Pas Event product model canonique | Event model | Haute |
| Facts / World Rules UI | ⚠️ partiel | Step Studio world changes, predicate UI partielle | `StepStudioWorkspace`, world presence runtime | Pas Fact registry humain central | Fact/WorldRule registry | Haute |
| Validator UI | ❌ absent | Aucun UI central prouvé | `narrative_validator.dart` non branché UI | Pas diagnostic UX no-code | Validator UI later | Haute |

## 6. Matrice complète des gaps

| Gap | Statut | Impact produit | Phase proposée | Priorité |
|---|---:|---|---|---:|
| Storyline model canonique | ❌ absent | Impossible de parler clairement d'histoire principale/side quests/chapters | Phase 1 puis Phase 2 | Critique |
| Chapter model canonique | ❌ absent | Organisation narrative fragile | Phase 1 puis Phase 2 | Haute |
| Story Step registry | ⚠️ partiel | Steps sont prouvés runtime mais pas product model complet | Phase 1/2 | Critique |
| Event model canonique | ⚠️ partiel | Event est confondu avec source scenario / trigger / map event | Phase 1/2 | Critique |
| Scene vs Cinematic boundary | ⚠️ partiel | Risque de transformer cutscene en moteur de progression | Phase 1 | Critique |
| Fact registry humain | ❌ absent | Les flags restent techniques | Phase 1/2 | Critique |
| WorldRule registry | ⚠️ partiel | Projection existe mais authoring global manque | Phase 2/4 | Haute |
| Yarn outcome contract | ⚠️ partiel | Outcome technique existe, workflow no-code pas stabilisé | Phase 1/4 | Haute |
| Narrative Validator editor integration | ❌ absent | Les diagnostics ne protègent pas encore l'utilisateur no-code | Phase 4 puis Phase 7 | Haute |
| Flame Golden Slice complet | ⚠️ partiel | Risque de bug d'intégration runtime réel | Phase 3 | Critique |
| Disk/editor-created project validation | ❌ absent | On ne prouve pas encore le chemin auteur réel | Phase 3/4 | Critique |
| Reward model | ❌ absent | Money/XP/rewards non unifiés | Phase 5 | Moyenne |
| Money bridge | ⚠️ partiel | `money` persiste mais ne se gagne pas | Phase 5 | Moyenne |
| XP / level-up / learn move | ❌ absent | Boucle RPG incomplète | Phase 5 | Moyenne |
| `hasItem` direct | ❌ absent | Gate possible via fact, pas via bag directement | Phase 5 | Moyenne |
| Static wild authorable | ⚠️ partiel | Boss trainer-like possible, static wild réel absent | Phase 5 | Moyenne |
| Door / warp conditionnel | ⚠️ partiel | Gate V0 par scene/fact, pas engine navigation | Phase 5 | Moyenne |
| PC/Boxes | ❌ absent / hors NS-GS | Fangame complet limité si capture dépasse party | Phase 5 ou phase gameplay dédiée | Moyenne |
| Shop / heal center / runtime menus | ❌ absent / hors NS-GS | Boucle RPG courte limitée | Phase 5 ou phase gameplay dédiée | Moyenne |
| UI premium finale | 🧭 futur | Valeur UX forte mais prématurée | Phase 7 | Tardive |

## 7. Lecture de Selbrume comme scénario de référence

Selbrume reste un scénario de référence, pas un contenu à générer par agent.

Utilisation correcte :

- vérifier que la grammaire narrative couvre un jeu court complet ;
- prioriser les contrats manquants ;
- tester mentalement les frontières Event / Scene / Cinematic / Fact / World Rule ;
- définir le Golden Slice final à valider plus tard depuis l'éditeur.

Utilisation interdite dans cette roadmap :

- générer `map_bourg_selbrume` ;
- générer `npc_lysa`, `npc_mael`, `npc_soline` ;
- générer dialogues finaux ;
- générer trainer/battle final ;
- générer un `project.json` Selbrume.

Golden Slice Selbrume cible :

```text
Parler à Lysa au port
→ Event vérifie Step active + Rival pas battu
→ Scene “Rencontre rival”
→ Dialogue Yarn “rival_intro”
→ Outcome confident / hesitant / aggressive
→ Cinematic différente selon outcome
→ Combat Rival
→ Outcome victory / defeat
→ Fact persistant
→ Step completed
→ World Rule change Lysa
→ Quête annexe devient disponible
→ Validator confirme que tout est atteignable
```

Phase de validation réelle proposée :

```text
Phase 6 — Selbrume Golden Slice réel
```

Raison : ce Golden Slice nécessite d'abord le modèle produit canonique, les contrats de domaine, la validation Flame/disk et les workflows authoring minimaux. Le faire maintenant recréerait le risque déjà corrigé : produire du contenu Selbrume dans le repo au lieu de stabiliser l'outil.

## 8. Concepts canoniques du futur Narrative Studio

Concepts cibles :

| Concept | Définition stricte | Frontière |
|---|---|---|
| Storyline | Ligne narrative complète : main story, side quest, tutorial, epilogue | Pas forcément linéaire ; pas un simple global story unique. |
| Chapter | Organisation macro d'une Storyline | Sert à classer, filtrer, visualiser ; ne remplace pas les steps. |
| Story Step | Jalon logique de progression | Ne joue pas la scène ; mémorise l'avancement. |
| Event | Déclencheur externe/local : quand, où, par qui, sous quelles conditions | Ne devient pas l'orchestrateur complet. |
| Scene | Orchestration narrative graphée | Peut brancher, lancer dialogue, cinematic, battle, actions, emit outcome. |
| Cinematic | Séquence linéaire de mise en scène | Ne branche pas et ne possède pas la progression. |
| Dialogue Yarn | Dialogue, choix, outcomes | Ne devient pas moteur principal de progression. |
| Fact | Vérité lisible du monde | UX humaine au-dessus des flags techniques. |
| World Rule | Projection passive de GameState sur le monde | Ne lance pas de scène. |
| Validator | Diagnostic statique | Ne corrige pas, n'exécute pas, ne mute pas. |

Règles de frontière :

```text
Event = déclenche.
Scene = orchestre.
Cinematic = met en scène linéairement.
Yarn = dialogue + outcomes.
Fact = vérité lisible du monde.
World Rule = projection passive du GameState.
Battle = résout le combat.
Validator = diagnostique.
```

Confusions à éviter :

- Scene ≠ Cinematic.
- Event ≠ Scene.
- Yarn ≠ moteur principal de progression.
- Fact ≠ flag technique exposé.
- Side Quest ≠ système séparé obligatoire au départ.
- UI finale ≠ priorité immédiate.

## 9. Principes de gouvernance roadmap

Gouvernance recommandée :

```text
Objectif final
→ Phases majeures
→ Roadmap précise pour la phase courante
→ Exécution de cette roadmap en lots stricts
→ Checkpoint de fin de phase
→ État des lieux par rapport à l'objectif final
→ Roadmap de la phase suivante
→ Répéter
```

Règles :

- Ne plus maintenir une roadmap infinie de 80 lots actifs.
- Conserver une master roadmap par phases.
- Détailler seulement la phase active et, au besoin, la phase suivante immédiate.
- Chaque phase a un checkpoint final obligatoire.
- Un checkpoint peut réordonner les phases si une preuve nouvelle le justifie.
- Une phase terminée doit dire ce qui est prouvé, partiel, non prouvé et reporté.
- Les anciens lots NS-GS restent un bloc historique clos et une base de preuves.
- `MVP Selbrume/road_map.md` doit être archivé/reclassé après validation utilisateur, pas remplacé automatiquement par ce rapport.

Décision utilisateur intégrée :

```text
La partie UI moderne / belle / refonte visuelle doit être l'une des dernières grandes phases.
```

Conséquence :

- pas de Modern App Shell maintenant ;
- pas de design system final maintenant ;
- pas de Scene Builder visuel complet maintenant ;
- pas de refonte premium avant modèle produit/runtime/validation/workflows ;
- l'éditeur peut recevoir plus tard des workflows minimaux, mais pas une refonte visuelle finale.

## 10. Proposition de phases globales

Master roadmap proposée :

| Phase | Nom | Objectif court | Statut |
|---|---|---|---:|
| Phase 0 | Audit global & roadmap reset | Figer l'état et la méthode de gouvernance | Ce rapport |
| Phase 1 | Canonical Product Model / Narrative Studio foundations | Figer la grammaire produit et les frontières | Recommandée ensuite |
| Phase 2 | Domain Model & Contracts | Stabiliser les contrats `map_core` nécessaires | Future |
| Phase 3 | Runtime / Application / Flame / Disk Validation | Prouver Event -> Scene -> Battle -> save/load au vrai runtime | Future |
| Phase 4 | Authoring Workflows Minimal | Rendre les mécaniques authorables sans UI premium | Future |
| Phase 5 | Gameplay Gaps Prioritaires | Rewards, money, XP, static wild, hasItem, gates, RPG gaps | Future |
| Phase 6 | Selbrume Golden Slice réel | Valider le Golden Slice Selbrume créé par l'utilisateur dans l'éditeur | Future |
| Phase 7 | UI / UX moderne finale | Refonte premium App Shell / Narrative Studio / Builders | Tardive |

## 11. Phase 0 — Audit global & roadmap reset

Objectif :

```text
Figer l'objectif final, l'état actuel, les gaps, les phases et la méthode de gouvernance.
```

Pourquoi :

- Le bloc NS-GS a accumulé beaucoup de preuves.
- La roadmap précédente était utile, mais devenait un fil continu.
- La décision utilisateur replace l'UI premium en fin de cycle.

Préconditions :

- NS-GS-01 -> NS-GS-18 lus.
- Documents Narrative Studio / Selbrume lus.

Périmètre :

- audit stratégique ;
- proposition de master roadmap ;
- choix de la prochaine phase.

Non-objectifs :

- aucun code ;
- aucun test ;
- aucun NS-GS-19 ;
- aucune UI ;
- aucun contenu Selbrume.

Livrables :

- `reports/roadmap/pokemap_full_product_phased_roadmap_v1.md`

Critères de sortie :

- phases définies ;
- prochaine phase choisie ;
- prochaine phase détaillée ;
- Evidence Pack complet.

Risques :

- Sur-détailler trop loin.
- Refaire une roadmap infinie sous un autre nom.

Checkpoint final :

```text
ROADMAP-01 — PokeMap Full Product Audit & Phased Master Roadmap Proposal
```

## 12. Phase 1 — Canonical Product Model / Narrative Studio foundations

Objectif :

```text
Stabiliser les concepts produit et les frontières :
Storyline, Chapter, Step, Event, Scene, Cinematic, Yarn, Fact, World Rule, Validator.
```

Pourquoi :

- Les mécaniques runtime existent souvent, mais les concepts produit restent hérités de Global Story / Step / Cutscene.
- Avant de coder de nouveaux modèles ou une UI, il faut figer le langage que l'utilisateur non développeur va manipuler.
- Selbrume demande une grammaire narrative complète, pas seulement des flags et des ScenarioAssets.

Préconditions :

- ROADMAP-01 validé.
- Décision utilisateur acceptée : UI premium tardive.

Périmètre :

- glossaire canonique ;
- frontières conceptuelles ;
- mapping de l'existant vers le futur modèle ;
- définition des objets produit V1 ;
- définition des workflows no-code sans UI finale.

Non-objectifs :

- pas de modèle Freezed/JSON ;
- pas de build_runner ;
- pas de refonte UI ;
- pas de Selbrume généré ;
- pas de NS-GS-19 rewards implémenté.

Livrables :

- Product Model V1 ;
- event/scene/cinematic/fact/world rule contract product-level ;
- Selbrume reference mapping ;
- décision claire pour Phase 2.

Critères de sortie :

- chaque concept a une définition stricte ;
- les confusions Scene/Cinematic/Event/Yarn/Fact sont fermées ;
- la grammaire "Quand / Si / Alors / Puis" est mappée à des objets produit ;
- les besoins domain model Phase 2 sont listés et bornés.

Risques :

- Rester trop abstrait.
- Concevoir un Quest Engine ou Reward Engine prématuré.
- Commencer l'UI sous prétexte de clarifier le produit.

Checkpoint final :

```text
P1-CHECKPOINT-01 — Canonical Product Model Closure & Phase 2 Decision
```

## 13. Phase 2 — Domain Model & Contracts

Objectif :

```text
Définir ou stabiliser dans map_core les modèles nécessaires :
Storyline, Chapter, StoryStep, Event, SceneGraph, FactRegistry,
WorldRuleRegistry, Cinematic metadata, diagnostics.
```

Pourquoi :

- Les tests NS-GS prouvent des patterns, mais pas un modèle produit durable.
- `ScenarioAsset` existe, mais le futur produit a besoin de contrats plus lisibles et validables.
- Le validator V0 pourra devenir plus utile si les registries existent.

Préconditions :

- Phase 1 validée.
- Liste de modèles acceptée par l'utilisateur.

Périmètre :

- pure Dart en `map_core` autant que possible ;
- petites migrations / adapters si nécessaires ;
- tests unitaires et golden JSON ciblés.

Non-objectifs :

- UI ;
- Flame ;
- reward engine complet ;
- création de contenu Selbrume.

Livrables :

- modèles ou adapters strictement nécessaires ;
- diagnostics nouveaux si le modèle les rend sûrs ;
- tests de round-trip JSON ;
- note migration/compatibilité.

Critères de sortie :

- les concepts Phase 1 ont un support contractuel ou une décision explicite de report ;
- aucun concept produit central ne reste seulement implicite dans un test runtime.

Risques :

- Modifier `ProjectManifest` trop tôt.
- Déclencher du generated-file churn.
- Sur-modéliser des objets qui peuvent rester annotations V1.

Checkpoint final :

```text
P2-CHECKPOINT-01 — Domain Contracts Readiness Review
```

## 14. Phase 3 — Runtime / Application / Flame / Disk Validation

Objectif :

```text
Prouver le vrai chemin d'exécution :
Event → Scene → Dialogue/Yarn outcome → Cinematic placeholder → Battle
→ Fact/Step → World Rule → Save/Load.
```

Pourquoi :

- NS-GS a surtout prouvé Level 2 Application.
- Le produit final doit fonctionner dans `PlayableMapGame` et depuis un projet disque.
- Les gaps Level 3/4 ne doivent pas être cachés par une future UI.

Préconditions :

- Contrats Phase 2 ou adapters suffisants.

Périmètre :

- harness `PlayableMapGame` ciblé ;
- harness disk project ciblé ;
- preuve save/load depuis projet disque ;
- pas de contenu Selbrume final.

Non-objectifs :

- UI premium ;
- quest/reward engine complet ;
- éditeur complet.

Livrables :

- Runtime-Validation-01 ;
- Disk-Validation-01 ;
- rapport Level 2/3/4 ;
- liste des gaps d'intégration.

Critères de sortie :

- Golden path générique prouvé en Flame ou gap documenté ;
- projet disque générique chargé et joué ou gap documenté ;
- l'ancienne formulation "Editor-authored" ne peut plus être mal lue.

Risques :

- Tests Flame fragiles.
- Mélanger validation runtime et contenu final Selbrume.

Checkpoint final :

```text
P3-CHECKPOINT-01 — Runtime / Disk Golden Path Review
```

## 15. Phase 4 — Authoring Workflows Minimal

Objectif :

```text
Rendre les mécaniques authorables de manière fonctionnelle, même sans UI premium :
events, scenes, conditions, facts, steps, world rules, battle refs, item refs.
```

Pourquoi :

- Le futur produit doit permettre à un créateur non développeur d'utiliser les briques.
- Il ne faut pas attendre la grande refonte UI finale pour sécuriser les workflows.

Préconditions :

- Phase 1 terminée.
- Phase 2/3 au moins partiellement validées.

Périmètre :

- workflows minimaux ;
- pickers / validations simples ;
- intégration du validator en mode fonctionnel si possible ;
- pas de design system final.

Non-objectifs :

- premium UI ;
- Scene Builder complet ;
- Cinematic Builder complet ;
- contenu Selbrume final.

Livrables :

- Event authoring minimal ;
- Scene authoring minimal ;
- Facts/World Rules workflow minimal ;
- validator workflow minimal ;
- test ou checklist de projet créé par l'utilisateur.

Critères de sortie :

- un utilisateur peut authorer un mini-flow générique sans éditer du JSON brut ;
- les références cassées sont diagnostiquées avant runtime.

Risques :

- Glisser vers une refonte visuelle.
- Exposer encore des IDs techniques partout.

Checkpoint final :

```text
P4-CHECKPOINT-01 — Minimal Authoring Workflow Review
```

## 16. Phase 5 — Gameplay Gaps Prioritaires

Objectif :

```text
Traiter les gaps nécessaires pour une boucle fangame jouable :
rewards, money, XP, static wild encounter, hasItem direct, door/warp conditionnel, etc.
```

Pourquoi :

- Un RPG Pokémon-like court a besoin de récompenses, progression combat, gates et quelques mécaniques de boucle RPG.
- NS-GS-18 a montré que money/XP demandent un design avant implémentation.

Préconditions :

- Le modèle produit ne doit plus être ambigu.
- Les workflows authoring minimaux doivent savoir où placer ces gaps.

Périmètre :

- `NS-GS-19 — Reward Model Minimal Design` reclassé ici ;
- money bridge ;
- XP/level-up design puis implémentation bornée ;
- `hasItem` / bag condition si validé ;
- static wild encounter authorable ;
- door/warp conditionnel minimal ;
- PC/Boxes, shop, heal center si priorisés par roadmap gameplay.

Non-objectifs :

- reward engine énorme ;
- parité Pokémon complète ;
- UI premium.

Livrables :

- sous-roadmaps courtes ;
- tests mechanics-first ;
- reports avec evidence.

Critères de sortie :

- boucle RPG courte raisonnable : combat -> reward/progression -> world update -> save/load ;
- les gaps restants sont classés hors MVP ou phase ultérieure.

Risques :

- Ouvrir trop de fronts RPG à la fois.
- Coupler `map_battle` à la narration.

Checkpoint final :

```text
P5-CHECKPOINT-01 — Gameplay Gaps Readiness Review
```

## 17. Phase 6 — Selbrume Golden Slice réel

Objectif :

```text
Créer ou valider, par l'utilisateur dans l'éditeur,
le premier vrai Golden Slice Selbrume,
sans que l'agent génère tout le jeu à sa place.
```

Pourquoi :

- Selbrume est le test concret de la grammaire complète.
- Le vrai produit doit prouver qu'un créateur peut fabriquer ce slice dans l'éditeur.

Préconditions :

- Phase 1 modèle produit validée.
- Phase 3 runtime/disk au moins assez solide.
- Phase 4 authoring minimal disponible.
- Les gaps gameplay bloquants sont tranchés.

Périmètre :

- checklist auteur ;
- validator sur projet réel ;
- smoke runtime ;
- corrections génériques si le projet réel révèle des gaps.

Non-objectifs :

- générer Selbrume automatiquement ;
- finaliser tout le mini-jeu ;
- produire toutes les maps/PNJ/dialogues.

Livrables :

- Golden Slice créé/validé par l'utilisateur ;
- rapport Level 3/4 ;
- liste des corrections produit restantes.

Critères de sortie :

- le scénario de référence "Lysa au port" est réellement authoré et jouable ;
- Validator confirme les refs principales ;
- runtime charge et exécute le projet disque.

Risques :

- Retomber dans la génération de contenu.
- Confondre slice de validation et jeu complet final.

Checkpoint final :

```text
P6-CHECKPOINT-01 — Selbrume Golden Slice Validation Review
```

## 18. Phase 7 — UI / UX moderne finale

Objectif :

```text
Refondre ou construire l'UI moderne et premium :
App Shell, Narrative Studio, Scene Builder, Storyline Graph,
Cinematic Builder, Validator UI.
```

Pourquoi :

- Une fois le modèle, le runtime, la validation et les workflows stabilisés, l'UI peut devenir belle sans figer de mauvais concepts.
- L'UI finale doit servir un modèle prouvé, pas compenser un domaine flou.

Préconditions :

- Phase 1 terminée.
- Phase 2/3/4 suffisamment solides.
- Phase 6 ou au moins un Golden Slice réel donne un retour produit.

Périmètre :

- Modern App Shell ;
- Narrative Studio premium ;
- Storyline Board/Graph ;
- Event Builder ;
- Scene Builder ;
- Cinematic Builder ;
- Facts & World Rules UI ;
- Validator UI ;
- UX no-code guidée.

Non-objectifs :

- inventer des mécaniques au fil de la UI ;
- cacher les gaps runtime ;
- rendre les flags techniques visibles comme expérience principale.

Livrables :

- design system final ou stabilisé ;
- composants UI ;
- previews / validations ;
- tests widget/interaction ;
- QA responsive.

Critères de sortie :

- un créateur non développeur peut authorer, diagnostiquer et comprendre son fangame court dans une UI moderne.

Risques :

- Sur-polir avant que les derniers gaps gameplay ne soient fermés.
- Créer une UI splendide qui expose encore de mauvais concepts.

Checkpoint final :

```text
P7-CHECKPOINT-01 — Modern UI Product Readiness Review
```

## 19. Phase recommandée ensuite

Phase recommandée :

```text
Phase 1 — Canonical Product Model / Narrative Studio foundations
```

Pourquoi ce choix :

- L'UI premium est explicitement repoussée par décision utilisateur.
- NS-GS-19 rewards est utile, mais ne résout pas le problème central de langage produit.
- Le repo possède déjà des mécaniques prouvées, mais les concepts auteur restent trop implicites ou hérités.
- Avant de modifier `map_core` pour Storyline/Event/Cinematic/FactRegistry, il faut valider le modèle produit.
- Selbrume exige une grammaire narrative claire avant d'être créé ou validé.

Options écartées :

| Option | Décision | Raison |
|---|---:|---|
| Phase 2 tout de suite | Écartée | Trop tôt sans Product Model V1 validé. |
| Phase 3 tout de suite | Écartée | Utile, mais les objets à valider doivent d'abord être nommés proprement. |
| Phase 5 / NS-GS-19 | Reportée | Rewards utile mais non prioritaire pour la gouvernance produit. |
| Phase 7 UI | Reportée | Décision utilisateur : UI moderne tardive. |

## 20. Roadmap détaillée de la prochaine phase

Roadmap détaillée Phase 1 :

### P1-01 — Canonical Narrative Product Model V1

Scope :

- définir Storyline, Chapter, Story Step, Event, Scene, Cinematic, Dialogue Yarn, Fact, World Rule, Validator ;
- écrire les responsabilités et non-responsabilités ;
- mapper chaque concept à l'existant actuel.

Non-objectifs :

- pas de code ;
- pas de `ProjectManifest` ;
- pas d'UI ;
- pas de Selbrume généré.

Validation attendue :

- revue documentaire ;
- matrice concept -> fichiers existants -> gaps.

Livrable :

- `reports/roadmap/p1_01_canonical_narrative_product_model_v1.md`

### P1-02 — Event / Scene / Cinematic Boundary Contract

Scope :

- figer la frontière Event déclenche / Scene orchestre / Cinematic linéaire ;
- définir comment Yarn outcome et battle outcome reviennent dans la scène ou l'event ;
- définir ce qui devient Fact persistant.

Non-objectifs :

- pas de Scene Builder UI ;
- pas de Cinematic Builder UI.

Validation attendue :

- exemples génériques ;
- contre-exemples interdits.

Livrable :

- contrat produit Event/Scene/Cinematic.

### P1-03 — Fact & World Rule Product Grammar

Scope :

- définir Fact comme vérité lisible ;
- définir World Rule comme projection passive ;
- lister les types de facts et les noms humains ;
- décider si un FactRegistry est obligatoire en Phase 2.

Non-objectifs :

- pas de registry implémentée ;
- pas de migration flags.

Validation attendue :

- mapping flags NS-GS -> facts humains ;
- diagnostics souhaités validator.

Livrable :

- grammaire Fact / World Rule V1.

### P1-04 — Storyline / Chapter / Story Step Structure

Scope :

- définir Storyline principale et secondaires ;
- définir Chapter comme organisation ;
- définir Story Step comme jalon ;
- décider si side quest V0 reste une Storyline secondaire.

Non-objectifs :

- pas de Quest Engine ;
- pas de Quest Journal.

Validation attendue :

- Selbrume mappé en référence, sans contenu généré.

Livrable :

- modèle produit Storyline/Chapter/Step.

### P1-05 — Selbrume Reference Grammar Mapping

Scope :

- prendre le Golden Slice Lysa au port ;
- mapper chaque élément à la grammaire canonique ;
- identifier les manques pour Phase 2/3/4.

Non-objectifs :

- pas de création de maps, NPC, dialogues, trainers ou project.json.

Validation attendue :

- tableau "élément Selbrume -> concept canonique -> support actuel -> gap".

Livrable :

- mapping Selbrume de référence.

### P1-06 — No-code Workflow Specification

Scope :

- décrire les workflows auteur minimaux sans UI finale :
  - créer event ;
  - créer scène ;
  - brancher Yarn ;
  - poser fact ;
  - brancher battle ;
  - projeter world rule ;
  - lancer validator.

Non-objectifs :

- pas de Modern App Shell ;
- pas de design system final.

Validation attendue :

- parcours utilisateur textuel ;
- champs requis / pickers / validations attendus.

Livrable :

- workflow no-code V1.

### P1-07 — Phase 2 Domain Contract Proposal

Scope :

- transformer les décisions Phase 1 en lots Phase 2 ;
- lister les modèles `map_core` à créer, adapter ou ne pas créer ;
- définir les risques build_runner / migrations.

Non-objectifs :

- pas d'implémentation.

Validation attendue :

- proposition de Phase 2 détaillée et bornée.

Livrable :

- `P1-CHECKPOINT-01`.

### P1-CHECKPOINT-01 — Canonical Product Model Closure & Phase 2 Decision

Scope :

- vérifier que Phase 1 a fermé les ambiguïtés ;
- choisir la Phase 2 ou une correction P1-bis ;
- produire la roadmap détaillée Phase 2.

Critères de sortie :

- concepts figés ;
- Selbrume mappé ;
- phase suivante choisie ;
- aucun code produit prématuré.

## 21. Critères de changement de phase

Une phase peut être fermée seulement si :

- les livrables de phase existent ;
- les non-objectifs ont été respectés ;
- les preuves sont citées ;
- les gaps restants sont classés ;
- un checkpoint final tranche la suite ;
- la phase suivante a une roadmap détaillée.

Critères spécifiques :

| Passage | Conditions |
|---|---|
| Phase 0 -> Phase 1 | ROADMAP-01 validé par l'utilisateur. |
| Phase 1 -> Phase 2 | Concepts canoniques validés, Selbrume mappé, contrats domaine proposés. |
| Phase 2 -> Phase 3 | Modèles/adapters nécessaires testés ou explicitement reportés. |
| Phase 3 -> Phase 4 | Golden path générique Level 3/4 prouvé ou gap borné. |
| Phase 4 -> Phase 5 | Workflows authoring minimaux utilisables sans JSON brut. |
| Phase 5 -> Phase 6 | Gaps gameplay bloquants pour le Golden Slice traités ou reportés explicitement. |
| Phase 6 -> Phase 7 | Golden Slice Selbrume réel donne un retour concret pour finaliser l'UI. |

## 22. Risques majeurs et garde-fous

Risques majeurs :

- Commencer la UI finale trop tôt.
- Continuer une roadmap infinie au lieu de piloter par phases.
- Confondre Selbrume référence et Selbrume contenu généré.
- Sur-modéliser avant d'avoir validé le product model.
- Créer un Reward/Quest/Door/Boss Engine trop tôt.
- Vendre Level 2 Application comme Level 3/4 complet.
- Exposer des flags techniques comme expérience no-code principale.

Garde-fous :

- Phase 1 documentaire/design-first obligatoire.
- Chaque phase a son checkpoint.
- UI premium placée Phase 7.
- Selbrume reste un banc d'essai.
- Level 2 / Level 3 / Level 4 toujours distingués.
- Toute implémentation future doit citer la phase et le lot actif.
- Chaque lot futur conserve Evidence Pack et statut honnête.

## 23. Décisions à faire valider par l’utilisateur

Décisions proposées :

1. Valider cette master roadmap par phases comme nouvelle gouvernance.
2. Reclasser `MVP Selbrume/road_map.md` comme roadmap historique NS-GS terminée, pas comme roadmap infinie active.
3. Choisir Phase 1 comme prochaine phase.
4. Valider le prochain lot exact : `P1-01 — Canonical Narrative Product Model V1`.
5. Reporter UI premium en Phase 7.
6. Reporter NS-GS-19 dans Phase 5, sauf priorité explicite rewards.
7. Confirmer que Selbrume reste scénario de référence, pas contenu à générer.
8. Décider si les prochains rapports Phase 1 vivent dans `reports/roadmap/` ou `reports/gameplay/product_model/`.

Décision déjà intégrée depuis le brief utilisateur :

```text
La partie UI moderne / belle / refonte visuelle doit être l'une des dernières grandes phases.
```

## 24. Evidence Pack

### Git status initial exact

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
```

Interprétation : worktree clean au début de ROADMAP-01.

### Fichiers lus

Liste synthétique :

```text
AGENTS.md
pokemap_roadmap_mecaniques_fangame.md
MVP Selbrume/narrative_studio.md
MVP Selbrume/selbrume.md
MVP Selbrume/road_map.md
reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md
reports/gameplay/ns_gs/ns_gs_18_reward_money_xp_bridge_audit.md
reports/gameplay/ns_gs/ns_gs_17_static_encounter_boss_battle_readiness.md
reports/gameplay/ns_gs/ns_gs_16_side_quest_optional_storyline_readiness.md
reports/gameplay/ns_gs/ns_gs_15_key_item_door_gate_readiness.md
reports/gameplay/ns_gs/ns_gs_14_item_pickup_give_item_authoring_readiness.md
reports/gameplay/ns_gs/ns_gs_13_bis_evidence_pack_closure.md
reports/gameplay/ns_gs/ns_gs_13_narrative_validator_minimal_v0.md
reports/gameplay/ns_gs/ns_gs_12_bis_evidence_pack_and_level_label_fix.md
reports/gameplay/ns_gs/ns_gs_12_editor_authored_golden_slice_validation.md
reports/gameplay/ns_gs/ns_gs_11_bis_evidence_pack_fix.md
reports/gameplay/ns_gs/ns_gs_11_trainer_battle_authoring_readiness.md
reports/gameplay/ns_gs/ns_gs_10_world_rules_conditional_presence_readiness.md
reports/gameplay/ns_gs/ns_gs_09_yarn_outcome_scene_branch_readiness.md
reports/gameplay/ns_gs/ns_gs_08_npc_interaction_scene_authoring_readiness.md
reports/gameplay/ns_gs/ns_gs_07_step_completion_progression_hooks.md
reports/gameplay/ns_gs/ns_gs_06_bis_give_pokemon_runtime_payload_hardening.md
reports/gameplay/ns_gs/ns_gs_06_give_pokemon_minimal.md
reports/gameplay/ns_gs/ns_gs_05_new_game_minimal_runtime.md
packages/map_core/lib/map_core.dart
packages/map_gameplay/lib/map_gameplay.dart
packages/map_runtime/lib/map_runtime.dart
packages/map_battle/lib/map_battle.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart
packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart
packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart
packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart
examples/playable_runtime_host/README.md
```

### Commandes exécutées

```bash
git status --short --untracked-files=all
find reports -maxdepth 3 -type f | sort
find packages/map_core/lib -maxdepth 4 -type f | sort
find packages/map_runtime/lib -maxdepth 4 -type f | sort
find packages/map_editor/lib -maxdepth 4 -type f | sort
find examples/playable_runtime_host -maxdepth 3 -type f | sort
find . -iname "*narrative*studio*.md" -o -iname "*selbrume*.md" -o -iname "*road*map*.md" -o -iname "*checkpoint*.md"
sed -n '1,260p' 'MVP Selbrume/narrative_studio.md'
sed -n '261,620p' 'MVP Selbrume/narrative_studio.md'
sed -n '1,260p' 'MVP Selbrume/selbrume.md'
sed -n '261,620p' 'MVP Selbrume/selbrume.md'
sed -n '1,320p' 'MVP Selbrume/road_map.md'
sed -n '321,760p' 'MVP Selbrume/road_map.md'
sed -n '1,280p' reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md
sed -n '281,620p' reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md
sed -n '1,220p' pokemap_roadmap_mecaniques_fangame.md
rg "Storyline|Chapter|StoryStep|Scene|Cinematic|WorldRule|Fact|Event|Narrative|Validator|Reward|XP|money|hasItem|startStaticEncounter|PlayableMapGame|project.json" packages reports "MVP Selbrume" --type dart --glob "*.md"
rg -n "^#|^## [0-9]+\\.|Résumé|Verdict|Décision|Niveau|Level|Limites|Prochain|Matrice|money|XP|static wild|trainer-like|hasItem|Flame|disk|éditeur|Evidence" reports/gameplay/ns_gs/ns_gs_18_reward_money_xp_bridge_audit.md reports/gameplay/ns_gs/ns_gs_17_static_encounter_boss_battle_readiness.md reports/gameplay/ns_gs/ns_gs_16_side_quest_optional_storyline_readiness.md reports/gameplay/ns_gs/ns_gs_15_key_item_door_gate_readiness.md reports/gameplay/ns_gs/ns_gs_14_item_pickup_give_item_authoring_readiness.md reports/gameplay/ns_gs/ns_gs_13_bis_evidence_pack_closure.md reports/gameplay/ns_gs/ns_gs_13_narrative_validator_minimal_v0.md reports/gameplay/ns_gs/ns_gs_12_bis_evidence_pack_and_level_label_fix.md reports/gameplay/ns_gs/ns_gs_12_editor_authored_golden_slice_validation.md reports/gameplay/ns_gs/ns_gs_11_bis_evidence_pack_fix.md reports/gameplay/ns_gs/ns_gs_11_trainer_battle_authoring_readiness.md reports/gameplay/ns_gs/ns_gs_10_world_rules_conditional_presence_readiness.md reports/gameplay/ns_gs/ns_gs_09_yarn_outcome_scene_branch_readiness.md reports/gameplay/ns_gs/ns_gs_08_npc_interaction_scene_authoring_readiness.md reports/gameplay/ns_gs/ns_gs_07_step_completion_progression_hooks.md reports/gameplay/ns_gs/ns_gs_06_bis_give_pokemon_runtime_payload_hardening.md reports/gameplay/ns_gs/ns_gs_06_give_pokemon_minimal.md reports/gameplay/ns_gs/ns_gs_05_new_game_minimal_runtime.md
sed -n '1,220p' packages/map_core/lib/map_core.dart
sed -n '1,220p' packages/map_gameplay/lib/map_gameplay.dart
sed -n '1,220p' packages/map_runtime/lib/map_runtime.dart
sed -n '1,220p' packages/map_battle/lib/map_battle.dart
sed -n '1,260p' reports/gameplay/ns_gs/ns_gs_18_reward_money_xp_bridge_audit.md
sed -n '260,620p' reports/gameplay/ns_gs/ns_gs_18_reward_money_xp_bridge_audit.md
sed -n '1,260p' reports/gameplay/ns_gs/ns_gs_14_item_pickup_give_item_authoring_readiness.md
sed -n '1,220p' reports/gameplay/ns_gs/ns_gs_15_key_item_door_gate_readiness.md
sed -n '1,240p' reports/gameplay/ns_gs/ns_gs_16_side_quest_optional_storyline_readiness.md
sed -n '1,220p' packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
sed -n '1,220p' packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart
sed -n '1,220p' packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart
sed -n '1,220p' packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart
sed -n '1,220p' packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart
sed -n '1,180p' examples/playable_runtime_host/README.md
test -f skills/README.md && sed -n '1,220p' skills/README.md || printf 'skills/README.md missing\n'
rg -n "class NarrativeValidation|enum NarrativeValidation|diagnoseNarrativeProject|scenarioNodeReferencesUnknownNode|scenarioGraphHasUnreachableNode|openDialogueReferencesUnknownDialogue|startTrainerBattleReferencesUnknownTrainer|outcomeEmittedNeverConsumed|outcomeConsumedNeverEmitted" packages/map_core/lib/src/operations/narrative_validator.dart packages/map_core/test/narrative_validator_test.dart
rg -n "kScenarioActionGivePokemon|kScenarioActionGiveItem|kScenarioActionCompleteStep|kScenarioActionStartTrainerBattle|kScenarioActionEmitOutcome|dispatchContinuation|ScenarioRuntimeEffectType.battle|kScenarioSourceEntityInteract|kScenarioSourceOutcome" packages/map_runtime/lib/src/application/scenario_runtime packages/map_runtime/test
rg -n "class GameStateMutations|givePokemon|giveItem|completeStep|createNewGameState|BagEntry|TrainerProfile|money|PlayerPokemon|knownMoveIds|level" packages/map_core/lib/src/models packages/map_core/lib/src/operations packages/map_gameplay/lib/src packages/map_gameplay/test
mkdir -p reports/roadmap
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff --no-index --check /dev/null reports/roadmap/pokemap_full_product_phased_roadmap_v1.md || true
wc -l reports/roadmap/pokemap_full_product_phased_roadmap_v1.md
```

### Git diff --check

```text
```

### Git diff --stat

```text
```

### Git diff --name-only

```text
```

### Git status final exact

```text
?? reports/roadmap/pokemap_full_product_phased_roadmap_v1.md
```

### Preuve que seul le rapport roadmap a été créé

Le résultat attendu du status final pour ROADMAP-01 est :

```text
?? reports/roadmap/pokemap_full_product_phased_roadmap_v1.md
```

Aucun fichier `packages/`, `examples/`, `MVP Selbrume/road_map.md`, `map_core`, `map_runtime`, `map_editor`, `map_gameplay` ou `map_battle` n'est modifié par ROADMAP-01.

Preuve du fichier créé :

```text
Chemin : reports/roadmap/pokemap_full_product_phased_roadmap_v1.md
Nombre de lignes : 1242
```

Le présent document est le contenu complet du fichier créé.

## 25. Auto-review critique

- Aucun code modifié : oui.
- Aucun test ajouté : oui.
- Aucun fichier `packages/` modifié : oui.
- Aucun fichier `examples/` modifié : oui.
- Aucun contenu Selbrume final créé : oui.
- Aucun `project.json` créé : oui.
- NS-GS-19 non démarré : oui.
- UI-00 non démarré : oui.
- UI premium placée en phase tardive : oui.
- Roadmap globale par phases : oui.
- Prochaine phase recommandée clairement : oui, Phase 1.
- Roadmap détaillée uniquement pour la prochaine phase : oui.
- Level 2 / Level 3 / Level 4 distingués : oui.
- Selbrume utilisé comme référence, pas comme contenu : oui.
- Risque restant : Phase 1 devra rester stricte et ne pas glisser vers l'implémentation de modèles `map_core` avant validation utilisateur.
