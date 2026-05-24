# P1-06 — No-code Workflow Specification

## 1. Résumé exécutif

P1-06 transforme la grammaire Phase 1 en workflows auteur no-code minimaux. Le lot décrit comment un créateur non développeur peut préparer une chaîne narrative de type Selbrume sans écrire d'IDs bruts, de flags techniques, de predicates, de payload battle ou de DSL conditionnel.

La frontière proposée est la suivante :

- le créateur nomme des objets produit lisibles : Histoire, Chapitre, Étape, Déclencheur, Scène, Dialogue, Combat, Fait du monde, Règle du monde ;
- les références sont choisies via pickers, pas saisies comme chaînes techniques ;
- les conditions sont présentées comme phrases humaines ;
- les conséquences durables deviennent des Facts ou des Story Steps, pas des flags exposés ;
- les World Rules expliquent ce qu'elles rendent visible ou disponible et pourquoi ;
- le Validator diagnostique les références cassées, outcomes non gérés et chaînes inatteignables avant runtime.

Les workflows spécifiés couvrent : Storyline principale, Chapter, Story Step, Event d'interaction, Scene, Dialogue Yarn et outcomes, Cinematic reference, Battle reference et outcomes, Fact, World Rule, Side Quest / Storyline secondaire, Validator.

P1-06 ne crée aucune UI finale, aucun widget Flutter, aucun builder visuel complet, aucun modèle `map_core`, aucun schéma JSON, aucun contenu Selbrume et aucun `project.json`.

Le prochain lot exact attendu est :

```text
P1-07 — Phase 2 Domain Contract Proposal
```

## 2. Scope du lot

Inclus :

- spécification documentaire des workflows auteur no-code minimaux ;
- identification des pickers nécessaires pour remplacer les IDs bruts ;
- identification des validations auteur immédiates ;
- identification des diagnostics Validator attendus ;
- mapping workflow conceptuel sur le Golden Slice Selbrume ;
- séparation entre Phase 1, Phase 2, Phase 4 et Phase 7 ;
- mise à jour de la roadmap vivante de Phase 1.

Exclus :

- aucun code modifié ;
- aucun test lancé ;
- aucun package modifié ;
- aucun widget Flutter créé ;
- aucune UI finale créée ;
- aucun design system créé ;
- aucun Scene Builder complet créé ;
- aucun Cinematic Builder complet créé ;
- aucun modèle `map_core` créé ;
- aucun schéma JSON créé ;
- aucun contenu Selbrume final créé ;
- aucune fixture Selbrume créée ;
- aucun `project.json` Selbrume créé ;
- aucun lancement de P1-07.

Fichiers créés :

```text
reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md
```

Fichiers modifiés :

```text
MVP Selbrume/road_map_phase_1.md
```

Fichiers explicitement non modifiés :

```text
MVP Selbrume/road_map_global.md
packages/map_core
packages/map_gameplay
packages/map_battle
packages/map_runtime
packages/map_editor
examples/playable_runtime_host
```

`road_map_global.md` a été lu pour contexte mais n'est pas modifié. Selbrume est utilisé comme référence conceptuelle uniquement.

## 3. Sources lues

Sources de gouvernance et cadrage :

- `AGENTS.md` — règles du dépôt, Git safety, limites package et evidence.
- `MVP Selbrume/road_map_global.md` — contexte global, lu mais non modifié.
- `MVP Selbrume/road_map_phase_1.md` — roadmap vivante à mettre à jour pour P1-06.
- `MVP Selbrume/road_map.md` — roadmap historique et contexte NS-GS.
- `MVP Selbrume/narrative_studio.md` — vision Narrative Studio et attentes no-code.
- `MVP Selbrume/selbrume.md` — scénario de référence, utilisé conceptuellement.
- `reports/roadmap/pokemap_full_product_phased_roadmap_v1.md` — roadmap produit phasée.
- `reports/roadmap/roadmap_global_00_master_phase_roadmap_bootstrap.md` — bootstrap de gouvernance globale.
- `reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md` — cadrage Phase 1.

Rapports Phase 1 :

- `reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md` — dictionnaire canonique.
- `reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md` — frontières Event / Scene / Cinematic.
- `reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md` — grammaire Fact / World Rule.
- `reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md` — structure Storyline / Chapter / Story Step.
- `reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md` — mapping conceptuel Selbrume.

Rapports gameplay / NS-GS :

- `reports/gameplay/audit/narrative_studio_product_model_v0.md` — état produit Narrative Studio V0.
- `reports/gameplay/audit/sel_a2_event_scene_outcome_fact_contract.md` — contrat event / scene / outcome / fact.
- `reports/gameplay/audit/sel_b2_battle_from_scene.md` — battle handoff depuis Scene.
- `reports/gameplay/ns_gs/ns_gs_08_npc_interaction_scene_authoring_readiness.md` — interaction PNJ vers Scene.
- `reports/gameplay/ns_gs/ns_gs_09_yarn_outcome_scene_branch_readiness.md` — outcomes Yarn et branchement Scene.
- `reports/gameplay/ns_gs/ns_gs_10_world_rules_conditional_presence_readiness.md` — world rules présence/dialogue.
- `reports/gameplay/ns_gs/ns_gs_11_trainer_battle_authoring_readiness.md` — Scene vers trainer battle.
- `reports/gameplay/ns_gs/ns_gs_12_bis_evidence_pack_and_level_label_fix.md` — limites Level 2 Application.
- `reports/gameplay/ns_gs/ns_gs_13_narrative_validator_minimal_v0.md` — Validator V0 minimal.
- `reports/gameplay/ns_gs/ns_gs_14_item_pickup_give_item_authoring_readiness.md` — pickup / give item.
- `reports/gameplay/ns_gs/ns_gs_15_key_item_door_gate_readiness.md` — key item / door gate pattern.
- `reports/gameplay/ns_gs/ns_gs_16_side_quest_optional_storyline_readiness.md` — side quest comme optional storyline.
- `reports/gameplay/ns_gs/ns_gs_17_static_encounter_boss_battle_readiness.md` — boss trainer-like et limites static/wild.
- `reports/gameplay/ns_gs/ns_gs_18_reward_money_xp_bridge_audit.md` — rewards item, money/XP gaps.
- `reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md` — synthèse mechanics-first et limites Level 2/3/4.

Fichiers de méthode agent lus :

- `/Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/using-superpowers/SKILL.md` — rappel d'usage des skills.
- `/Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md` — vérification avant déclaration de complétion.

Aucun fichier obligatoire P1-06 n'a été signalé comme absent.

## 4. Rappel de la grammaire Phase 1

P1-01 a fixé le dictionnaire canonique :

- Storyline = ligne narrative.
- Chapter = section.
- Story Step = jalon.
- Event = déclenche.
- Scene = orchestre.
- Cinematic = met en scène.
- Dialogue Yarn = dialogue + outcomes.
- Fact = vérité lisible.
- World Rule = projection passive.
- Validator = diagnostique.

P1-02 a durci la frontière :

```text
Event déclenche.
Scene orchestre.
Cinematic met en scène.
```

P1-03 a durci :

```text
Fact = ce qui est vrai.
World Rule = ce que le monde montre parce que c'est vrai.
```

P1-04 a durci :

```text
Storyline = une ligne narrative.
Chapter = une section de cette ligne.
Story Step = un jalon de progression.
Side quest V0 = Storyline secondaire.
```

P1-05 a vérifié que le Golden Slice Selbrume "Lysa au port" est couvert conceptuellement par cette grammaire. P1-06 ne redéfinit pas ces concepts ; il les transforme en parcours auteur no-code.

## 5. Objectif des workflows no-code

Le but de P1-06 est de décrire comment un créateur non développeur peut créer une chaîne narrative sans écrire :

- IDs techniques ;
- flags ;
- predicates ;
- scenario node IDs ;
- battle request payloads ;
- condition DSL brut ;
- noms internes `scenario.outcome.*` ;
- références PNJ ou map à la main.

Le workflow doit permettre au créateur de :

- choisir des objets via pickers ;
- nommer les concepts avec des labels humains ;
- relier les blocs sans manipuler d'IDs ;
- valider les erreurs locales au moment de la saisie ;
- diagnostiquer la chaîne complète avant runtime ;
- préparer les contrats de domaine Phase 2 sans imposer une UI finale Phase 7.

La phrase produit de P1-06 est :

```text
Le workflow no-code doit remplacer les chaînes techniques par des choix guidés,
des pickers, des validations et des diagnostics compréhensibles.
```

## 6. Principes UX no-code non négociables

1. Aucun ID brut ne doit être le langage principal du flux auteur.
2. Tout objet référencé doit être choisi via picker ou assistant de sélection.
3. Toute condition doit être lisible en phrase humaine.
4. Toute conséquence durable doit être formulée comme Fact ou Story Step.
5. Toute World Rule doit expliquer ce qu'elle montre et pourquoi.
6. Tout outcome Yarn ou Battle doit être soit géré, soit explicitement ignoré.
7. Toute side quest doit avoir une disponibilité et une entrée explicites.
8. Le Validator doit être accessible avant runtime.
9. Le système doit afficher les références cassées avant que l'utilisateur teste en jeu.
10. Les options avancées peuvent montrer l'ID technique, mais jamais comme langage principal.
11. Les workflows doivent rester utilisables sans Scene Builder visuel complet.
12. Les diagnostics doivent parler le vocabulaire auteur : Histoire, Étape, Scène, Fait du monde, Règle du monde.

## 7. Workflow global auteur — vue d'ensemble

Vue d'ensemble conceptuelle :

```text
Créer Storyline
→ créer Chapter
→ créer Story Step
→ créer Event
→ créer Scene
→ connecter Yarn / Cinematic / Battle
→ définir outcomes
→ écrire Facts / compléter Steps
→ créer World Rules
→ créer Side Quest disponible
→ lancer Validator
→ lire diagnostics
→ corriger manuellement
→ relancer Validator
```

Diagramme texte :

```text
Histoire principale
  Chapitre
    Étape
      Déclencheur
        Conditions lisibles
        Scène cible
          Dialogue Yarn
            outcomes gérés
          Mise en scène
          Combat
            outcomes gérés
          Faits du monde
          Étapes complétées
      Règles du monde
      Quête annexe disponible
Validator
  diagnostics lisibles
```

Ce workflow n'est pas une maquette UI finale. Il décrit les intentions auteur, les objets manipulés, les pickers attendus et les validations nécessaires.

## 8. Workflow Storyline principale

Objectif utilisateur :

Créer une histoire principale lisible, par exemple "Les Brumes de Selbrume", sans créer de modèle technique ni de contenu final dans le repo.

Étapes auteur :

1. Choisir "Créer une histoire principale".
2. Saisir un nom utilisateur.
3. Ajouter une description courte.
4. Choisir un type : histoire principale.
5. Préparer les chapitres ou laisser l'assistant proposer le premier chapitre.
6. Définir une disponibilité conceptuelle si l'histoire n'est pas active dès le début.
7. Relier des Facts, Steps ou World Rules plus tard.

Pickers nécessaires :

- Storyline type picker : main story, side quest, tutorial, optional arc.
- Fact picker pour disponibilité éventuelle.
- Chapter picker pour rattacher des chapitres existants.

Validations immédiates :

- nom vide ;
- nom dupliqué ;
- type manquant ;
- Storyline principale sans aucun Step prévu ;
- disponibilité qui référence un Fact absent.

Diagnostics Validator possibles :

- Storyline sans début ;
- Storyline sans Step ;
- Storyline impossible à rendre disponible ;
- Storyline terminable mais sans Fact ou Step de résolution.

Données conceptuelles produites :

- nom utilisateur ;
- type ;
- description ;
- liste de Chapters ;
- résumé de disponibilité ;
- liens vers Steps / Facts / World Rules.

Gaps Phase 2 :

- contrat Storyline ;
- règles de disponibilité ;
- statut de Storyline ;
- référence validable vers Chapters et Steps.

## 9. Workflow Chapter

Objectif utilisateur :

Organiser une section de l'histoire, par exemple "Le port", sans imposer qu'un Chapter soit une map ou un état runtime obligatoire.

Étapes auteur :

1. Choisir une Storyline via picker.
2. Créer un Chapter dans cette Storyline.
3. Nommer le Chapter.
4. Ajouter une description courte.
5. Choisir un ordre de lecture.
6. Voir ou rattacher les Story Steps associés.

Pickers nécessaires :

- Storyline picker ;
- Chapter order picker ou liste ordonnée ;
- Story Step picker.

Validations immédiates :

- Chapter sans Storyline ;
- Chapter sans nom ;
- doublon de nom dans la même Storyline ;
- ordre ambigu si plusieurs Chapters partagent la même position ;
- Chapter vide signalé comme warning, pas forcément erreur bloquante.

Diagnostics Validator possibles :

- Chapter vide ;
- Chapter sans ordre clair ;
- Step rattaché à un Chapter d'une autre Storyline ;
- Chapter présenté comme map obligatoire alors qu'aucune map n'est requise par le modèle produit.

Limite :

Chapter sert à organiser, filtrer et rendre lisible. Il ne devient pas un sous-jeu, une sauvegarde séparée ou un runtime state imposé.

## 10. Workflow Story Step

Objectif utilisateur :

Créer un jalon de progression clair, par exemple "Parler à Lysa au port" ou "Battre le rival au port".

Étapes auteur :

1. Choisir la Storyline parent.
2. Choisir un Chapter parent si pertinent.
3. Saisir le nom de l'étape comme action lisible.
4. Définir une disponibilité conceptuelle : disponible dès le début, après un Fact, après un Step, ou via World Rule visible.
5. Définir la Scene qui peut compléter ce Step.
6. Voir les Facts liés.
7. Voir les World Rules affectées.

Pickers nécessaires :

- Storyline picker ;
- Chapter picker ;
- Fact picker ;
- Step picker pour dépendances ;
- Scene picker pour completion ;
- Event picker pour entrée.

Validations immédiates :

- Step sans Storyline ;
- Step sans nom lisible ;
- Step dupliqué ;
- Step jamais activable ;
- Step sans completion possible ;
- Step complété par une Scene absente ;
- Step qui ressemble à un ID technique au lieu d'un jalon humain.

Diagnostics Validator possibles :

- Story Step jamais activable ;
- Story Step actif mais jamais complété ;
- Story Step complété par plusieurs Scenes sans règle claire ;
- Event référence un Step inconnu ;
- World Rule lit un Step inconnu.

Données conceptuelles produites :

- label humain ;
- parent Storyline ;
- parent Chapter éventuel ;
- disponibilité ;
- completion attendue ;
- liens Facts / Events / Scenes / World Rules.

## 11. Workflow Event d'interaction

Objectif utilisateur :

Créer un déclencheur comme "Quand le joueur parle à Lysa" sans saisir `npc_lysa_003` comme langage principal.

Étapes auteur :

1. Choisir le type de source : PNJ, objet, zone, map entry, pickup, outcome.
2. Choisir la map via picker.
3. Choisir l'entité ou le trigger via picker.
4. Définir les conditions d'entrée en phrases humaines.
5. Choisir la Scene cible.
6. Choisir la repeat policy : rejouable, one-shot, consommé après résolution.
7. Lire le résumé : "Quand le joueur parle à Lysa, si l'étape X est active et le rival n'est pas battu, lancer la scène Y."

Pickers nécessaires :

- Map picker ;
- Entity / NPC picker ;
- Trigger / zone picker ;
- Story Step picker ;
- Fact picker ;
- Scene picker.

Validations immédiates :

- Event sans source ;
- source absente sur la map choisie ;
- Event sans Scene target ;
- condition qui référence un Fact ou Step inconnu ;
- Event qui tente d'orchestrer dialogue, battle et reward directement ;
- repeat policy absente pour un Event one-shot probable.

Diagnostics Validator possibles :

- Event jamais déclenchable ;
- Event cible Scene absente ;
- Event avec conditions impossibles ;
- Event qui devient mini-Scene ;
- conflit entre plusieurs Events sur la même source et la même priorité.

Interdit comme langage principal :

```text
npc_lysa_003
event_lysa_003
scenario_source_entity_interact_12
predicate_step_active_flag_true
```

## 12. Workflow Scene

Objectif utilisateur :

Créer une Scene, par exemple "Rencontre rival", qui orchestre dialogue, cinematic, battle, facts, steps et continuations.

Étapes auteur :

1. Créer la Scene avec un nom lisible.
2. Ajouter des blocs conceptuels : Yarn, Cinematic, Battle, Fact write, Step completion, continuation.
3. Ordonner les blocs.
4. Définir les outcomes attendus pour Yarn et Battle.
5. Mapper chaque outcome vers une branche, une Cinematic, un Fact, une Step completion ou une fin explicite.
6. Définir la fin de Scene ou la continuation.
7. Lancer les validations locales.

Pickers nécessaires :

- Dialogue Yarn picker ;
- Yarn outcome picker ;
- Cinematic picker ;
- Battle / Trainer picker ;
- Battle outcome mapper ;
- Fact picker ;
- Story Step picker ;
- Scene continuation picker.

Validations immédiates :

- Scene sans nom ;
- Scene sans entrée connue ;
- Scene sans fin ;
- bloc référencé absent ;
- outcome Yarn non géré ;
- outcome Battle non géré ;
- Fact écrit sans label humain ;
- Step completion inconnue ;
- boucle de continuation non intentionnelle.

Diagnostics Validator possibles :

- Scene unreachable ;
- Scene référence Yarn absent ;
- Scene référence Cinematic absente ;
- Scene référence Battle absent ;
- Scene écrit Fact inconnu ;
- Scene complète Step inconnu ;
- branche outcome sans sortie.

Important :

P1-06 ne crée pas de Scene Builder complet. Le rapport spécifie seulement le workflow minimal attendu pour relier et valider les blocs.

## 13. Workflow Dialogue Yarn et outcomes

Objectif utilisateur :

Associer un dialogue à une Scene et gérer ses outcomes sans exposer `scenario.outcome.rival_intro.confident` comme langage principal.

Étapes auteur :

1. Choisir un Dialogue Yarn existant ou futur.
2. Choisir un start node si nécessaire.
3. Déclarer les outcomes attendus : confident, hesitant, aggressive, ou labels utilisateur équivalents.
4. Mapper chaque outcome vers une branche de Scene.
5. Marquer explicitement un outcome comme ignoré si le design le veut.
6. Indiquer si un outcome reste temporaire ou devient un Fact durable.

Pickers nécessaires :

- Dialogue Yarn picker ;
- Yarn node picker si plusieurs entrées existent ;
- Yarn outcome picker ;
- Fact picker pour outcome durable ;
- Scene branch picker.

Validations immédiates :

- Yarn absent ;
- start node absent ;
- outcome déclaré par Yarn mais non géré ;
- outcome durable sans Fact ;
- Fact créé à partir d'un outcome mais sans label humain.

Diagnostics Validator possibles :

- Yarn outcome orphelin ;
- Yarn outcome jamais transformé alors qu'il est marqué durable ;
- Scene qui dépend d'un outcome inexistant ;
- Yarn utilisé comme moteur caché de progression.

Règle produit :

Yarn produit un résultat. Scene interprète ce résultat et décide s'il reste temporaire ou s'il devient Fact.

## 14. Workflow Cinematic

Objectif utilisateur :

Référencer une mise en scène linéaire dans une Scene, par exemple une entrée du rival, une réaction courte ou une sortie après combat.

Étapes auteur :

1. Choisir une Cinematic existante ou future.
2. La rattacher à une Scene.
3. Indiquer son rôle : entrée, réaction, variation, sortie.
4. Indiquer quelles branches l'appellent.
5. Vérifier qu'elle ne porte pas la progression narrative.

Pickers nécessaires :

- Cinematic picker ;
- Scene picker ;
- Branch picker ;
- Character / entity picker futur pour les commandes internes.

Validations immédiates :

- Cinematic absente ;
- Cinematic appelée par aucune Scene ;
- Cinematic sans rôle compréhensible ;
- Cinematic qui prétend écrire un Fact ;
- Cinematic qui prétend compléter un Step ;
- Cinematic avec branching narratif complexe.

Diagnostics Validator possibles :

- Cinematic référence personnage absent ;
- Cinematic contient une logique interdite ;
- Cinematic appelée après une branche impossible ;
- Cinematic orpheline.

Important :

P1-06 ne crée pas de Cinematic Builder. Il spécifie seulement comment une Scene référence une Cinematic et comment l'auteur comprend son rôle.

## 15. Workflow Battle reference et battle outcomes

Objectif utilisateur :

Associer un combat à une Scene, déclarer les outcomes et décider les conséquences post-combat.

Étapes auteur :

1. Choisir une référence trainer ou battle template.
2. Vérifier les préconditions futures : équipe, niveau, trainer, availability.
3. Déclarer les outcomes attendus : victory, defeat, flee/capture si le type de combat le justifie plus tard.
4. Mapper chaque outcome vers une branche de Scene.
5. Définir les Facts et Step completions post-battle.
6. Définir les World Rules qui liront ces conséquences.

Pickers nécessaires :

- Trainer picker ;
- Battle template picker ;
- Party validation future ;
- Battle outcome mapper ;
- Fact picker ;
- Step picker ;
- World Rule picker.

Validations immédiates :

- battle/trainer reference absente ;
- outcome victory non géré ;
- outcome defeat non géré ou explicitement ignoré sans justification ;
- outcome capture utilisé sur un combat qui ne le supporte pas ;
- Fact post-battle sans label humain ;
- Step completed sans Scene propriétaire.

Diagnostics Validator possibles :

- Battle outcome orphelin ;
- Scene référence Battle absent ;
- battle defeat non géré ;
- victory écrit un Fact inconnu ;
- reward conceptuel sans modèle supporté.

Règle produit :

Battle résout. Scene interprète.

## 16. Workflow Fact

Objectif utilisateur :

Créer ou choisir une vérité lisible du monde, par exemple "Le rival a été battu au port", sans exposer `flag_rival_port_done`.

Étapes auteur :

1. Choisir "Créer un Fait du monde" ou sélectionner un Fact existant.
2. Donner un label humain.
3. Ajouter une description si nécessaire.
4. Indiquer la source d'écriture attendue : Scene, Step completion dérivée, item state, battle outcome interprété par Scene.
5. Indiquer les consumers attendus : Event, Scene, World Rule, Validator.
6. Choisir si le Fact est stocké, dérivé ou seulement présenté conceptuellement.

Pickers nécessaires :

- Fact category picker ;
- Scene picker pour source ;
- Story Step picker pour dérivé ;
- Event picker pour lecture ;
- World Rule picker pour projection.

Validations immédiates :

- Fact sans label humain ;
- Fact exposé comme flag technique brut ;
- Fact référencé mais jamais écrit ;
- Fact écrit mais jamais lu ;
- Fact dupliqué avec label proche ;
- Fact stocké en double alors qu'un Step ou item state suffit.

Diagnostics Validator possibles :

- Fact inconnu ;
- Fact référencé mais jamais écrit ;
- Fact écrit mais jamais lu ;
- Fact technique exposé sans label humain ;
- Fact dupliqué avec labels différents.

Règle produit :

Le Fact visible dans l'éditeur doit être compréhensible sans connaître le moteur. Le stockage technique peut exister, mais il n'est pas le langage principal.

## 17. Workflow World Rule

Objectif utilisateur :

Créer une règle qui projette l'état dans le monde visible, par exemple "Si le rival a été battu au port, Lysa utilise son dialogue post-combat".

Étapes auteur :

1. Choisir une condition lisible : Fact, Step, état GameState dérivé.
2. Choisir une cible : PNJ, dialogue, objet, porte, marker, side quest availability.
3. Choisir un type de projection : visible, caché, dialogue alternatif, interactable, bloqué, disponible.
4. Définir un fallback si la condition est fausse.
5. Lire le résumé : "Parce que X est vrai, le monde montre Y."

Pickers nécessaires :

- Fact picker ;
- Story Step picker ;
- GameState derived state picker futur ;
- Map picker ;
- Entity / NPC picker ;
- Dialogue picker ;
- Door / trigger picker futur ;
- Side Quest picker.

Validations immédiates :

- World Rule sans condition ;
- target absente ;
- projection absente ;
- fallback ambigu ;
- conflit avec une autre World Rule ;
- World Rule utilisée comme Event ;
- World Rule qui écrit un Fact ;
- World Rule qui complète un Step.

Diagnostics Validator possibles :

- World Rule sans condition ;
- World Rule condition impossible ;
- World Rule cible absente ;
- World Rule conflit ;
- World Rule utilisée comme Event ;
- World Rule lit un Fact ou Step inconnu.

Règle produit :

World Rule ne lance pas de Scene. Elle rend visible ou disponible. Un Event séparé déclenche la Scene quand le joueur interagit.

## 18. Workflow Side Quest / Storyline secondaire

Objectif utilisateur :

Créer une quête annexe comme Storyline secondaire, par exemple "Aider Soline", sans créer un Quest Engine obligatoire.

Étapes auteur :

1. Créer une Storyline type sideQuest.
2. Définir son availability : après un Fact, après un Step, ou via condition future.
3. Définir l'entry Event : parler à Soline, interagir avec un objet, entrer dans une zone.
4. Définir la first Scene.
5. Créer les Steps de la side quest.
6. Définir les Facts produits.
7. Définir les World Rules : dialogue, présence, récompense visible ou masquée.
8. Définir un reward conceptuel si nécessaire, sans créer de reward model dans P1-06.

Pickers nécessaires :

- Storyline type picker ;
- Fact picker ;
- Step picker ;
- Event source picker ;
- Scene picker ;
- World Rule picker ;
- Reward picker futur.

Validations immédiates :

- side quest sans availability ;
- side quest disponible mais sans entry Event ;
- first Scene absente ;
- Step de side quest sans completion ;
- reward conceptuel non supporté présenté comme disponible ;
- World Rule qui tente de lancer directement la side quest.

Diagnostics Validator possibles :

- Side quest disponible mais sans entrée ;
- Side quest jamais atteignable ;
- Entry Event cible Scene absente ;
- Side quest terminable sans Step terminal ;
- reward référencé mais non supporté par les contrats actuels.

Limites :

Pas de Quest Engine obligatoire. Pas de Quest Journal maintenant. Pas de UI tracking finale dans P1-06.

## 19. Workflow Validator

Objectif utilisateur :

Diagnostiquer la chaîne narrative avant runtime avec des messages compréhensibles.

Étapes auteur :

1. Lancer le diagnostic depuis le workflow Narrative Studio.
2. Voir les erreurs bloquantes.
3. Voir les warnings.
4. Cliquer ou naviguer vers une référence conceptuelle : Storyline, Step, Event, Scene, Fact, World Rule.
5. Lire une explication humaine.
6. Corriger manuellement via les workflows auteur.
7. Relancer le diagnostic.

Types de messages attendus :

- erreur bloquante : la chaîne ne peut pas fonctionner ;
- warning : le design est possible mais suspect ;
- information : amélioration de lisibilité ou complétude.

Exemples de diagnostic humain :

- "La scène Rencontre rival référence le dialogue rival_intro, mais ce dialogue est absent."
- "L'outcome defeat du combat Rival n'est pas géré."
- "La règle du monde Lysa dialogue post-combat lit un Fact jamais écrit."
- "La quête annexe Aider Soline est disponible, mais aucun déclencheur ne permet de l'ouvrir."

Important :

Validator diagnostique. Validator ne corrige pas automatiquement.

## 20. Pickers nécessaires pour éviter les IDs bruts

| Picker | Remplace | Doit afficher | Validation permise |
|---|---|---|---|
| Storyline picker | `storylineId` | nom, type, statut conceptuel | Storyline absente ou mauvaise portée |
| Chapter picker | `chapterId` | nom, ordre, Storyline parent | Chapter hors Storyline |
| Story Step picker | `stepId`, `completedStepIds` | label humain, statut, parent | Step inconnu, jamais activable |
| Map picker | `mapId` | nom de map, aperçu ou description | map absente |
| Entity / NPC picker | `entityId`, `npcId` | nom PNJ/objet, map, rôle | entité absente sur map |
| Trigger / zone picker | `triggerId`, zone technique | nom de zone, position, type | trigger absent |
| Scene picker | `scenarioId`, `nodeId` brut | nom de Scene, entrée, statut | Scene absente ou unreachable |
| Dialogue Yarn picker | chemin ou ID Yarn | titre dialogue, start nodes | Yarn absent |
| Yarn outcome picker | `scenario.outcome.*` | label outcome, source Yarn | outcome non géré |
| Cinematic picker | cinematic ID | nom, rôle, branches appelantes | Cinematic absente/orpheline |
| Battle / Trainer picker | `trainerId`, `battleId` | trainer, niveau conceptuel, type | battle absent |
| Battle outcome mapper | suffixes flags battle | victory, defeat, flee/capture si pertinent | outcome orphelin |
| Fact picker | `storyFlags.activeFlags` | label humain, source, consumers | Fact inconnu ou brut |
| World Rule target picker | entity/dialogue/door IDs | cible visible, projection | target absente |
| Item picker futur | `itemId` | nom item, catégorie, disponibilité | item absent |
| Reward picker futur | reward payload | type reward, support actuel | reward non supporté |

Les pickers ne sont pas une UI finale. Ils définissent les capacités minimales qu'une UI Phase 4 ou Phase 7 devra offrir.

## 21. Validations auteur immédiates

Validations inline minimales :

- nom vide ;
- référence absente ;
- doublon de nom dans le même scope ;
- Storyline sans Step ;
- Chapter sans Storyline ;
- Chapter vide si le contexte le rend suspect ;
- Step sans Storyline ;
- Step sans completion possible ;
- Step jamais activable ;
- Event sans source ;
- Event sans Scene target ;
- Event avec condition inconnue ;
- Scene sans entrée connue ;
- Scene sans fin ;
- Scene référence Yarn absent ;
- Scene référence Cinematic absente ;
- Scene référence Battle absent ;
- Yarn outcome non géré ;
- Battle victory non géré ;
- Battle defeat non géré ou non explicitement ignoré ;
- Fact technique sans label humain ;
- Fact référencé mais jamais écrit ;
- World Rule sans condition ;
- World Rule sans target ;
- World Rule utilisée comme Event ;
- Side quest sans availability ;
- Side quest sans entry Event.

Ces validations ne remplacent pas le Validator global. Elles empêchent les erreurs simples dès la saisie.

## 22. Diagnostics Validator attendus

Diagnostics globaux attendus plus tard :

- Storyline inatteignable ;
- Storyline sans début ;
- Storyline sans Step ;
- Chapter vide ;
- Chapter sans ordre clair ;
- Step jamais activable ;
- Step actif mais jamais complété ;
- Event jamais déclenchable ;
- Event cible Scene absente ;
- Scene unreachable ;
- Scene sans fin ;
- Scene référence Yarn absent ;
- Scene référence Cinematic absente ;
- Scene référence Battle absent ;
- Yarn outcome orphelin ;
- Battle outcome orphelin ;
- Battle outcome defeat non géré ;
- Fact jamais écrit ;
- Fact jamais lu ;
- Fact technique exposé sans label humain ;
- World Rule cassée ;
- World Rule cible absente ;
- World Rule conflit avec une autre règle ;
- World Rule utilisée comme Event ;
- Side quest disponible mais sans entrée ;
- reward conceptuel référencé mais non supporté.

Le Validator doit rester explicatif et non destructif : il diagnostique, il ne répare pas automatiquement.

## 23. Mapping workflow sur Golden Slice Selbrume

Mapping conceptuel, sans création de contenu :

```text
1. Créer Storyline principale
   Nom : Les Brumes de Selbrume
   Type : histoire principale

2. Créer Chapter
   Nom : Le port
   Parent : Les Brumes de Selbrume

3. Créer Story Step
   Nom : Parler à Lysa au port
   Parent : Le port
   Availability : chapitre port actif

4. Créer Event
   Label : Quand le joueur parle à Lysa
   Source : PNJ Lysa choisi via picker
   Conditions : Step "Parler à Lysa au port" actif + Fact "Le rival a été battu au port" absent
   Target : Scene "Rencontre rival"

5. Créer Scene
   Nom : Rencontre rival
   Blocs : Dialogue Yarn, Cinematic, Battle, Fact write, Step completion

6. Associer Dialogue Yarn
   Dialogue : rival_intro
   Outcomes : confident / hesitant / aggressive
   Gestion : chaque outcome mène à une variation de Scene

7. Associer Cinematic
   Entrée du rival
   Variation courte selon outcome Yarn
   Sortie éventuelle après combat

8. Associer Battle
   Combat : Rival au port
   Outcomes : victory / defeat
   Scene interprète chaque outcome

9. Créer Fact
   Label : Le rival a été battu au port
   Source : victory battle interprétée par Scene
   Consumers : Event Lysa, World Rule dialogue post-combat, disponibilité side quest

10. Compléter Story Step
    Step : Battre le rival au port
    Completed by : Scene "Rencontre rival" sur victory

11. Créer World Rule
    Si : Le rival a été battu au port
    Alors : Lysa utilise son dialogue post-combat

12. Créer Storyline secondaire
    Nom : Aider Soline
    Type : sideQuest
    Availability : après le rival battu
    Entry Event : parler à Soline ou interagir avec une entrée dédiée

13. Lancer Validator
    Vérifier : refs, outcomes, Facts, Steps, World Rules, side quest entry
```

Ces noms servent uniquement de références conceptuelles. P1-06 ne crée aucune map, aucun PNJ, aucun dialogue Yarn, aucun combat, aucune fixture et aucun projet Selbrume dans le repo.

## 24. Ce que P1-06 prouve

P1-06 prouve seulement :

- la grammaire Phase 1 peut se traduire en workflows auteur ;
- les workflows nécessaires sont identifiés ;
- les pickers nécessaires sont identifiés ;
- les validations auteur immédiates sont identifiées ;
- les diagnostics Validator attendus sont identifiés ;
- le Golden Slice Selbrume peut être parcouru conceptuellement comme workflow no-code ;
- les dépendances Phase 2 / Phase 4 / Phase 7 sont plus claires.

## 25. Ce que P1-06 ne prouve pas

P1-06 ne prouve pas :

- que l'UI existe ;
- que les widgets Flutter existent ;
- que les modèles `map_core` existent ;
- que le runtime exécute ces workflows ;
- que l'éditeur peut sauvegarder ces workflows ;
- que le Validator les analyse réellement ;
- que Selbrume est créé ;
- que le Scene Builder existe ;
- que le Cinematic Builder existe ;
- que le Golden Slice complet est prouvé en Flame ;
- qu'un projet disque Selbrume existe ;
- que les rewards money/XP sont supportés.

## 26. Impacts attendus pour P1-07 et Phase 2

P1-07 devra traiter :

```text
P1-07 — Phase 2 Domain Contract Proposal
```

Contrats probablement nécessaires pour Phase 2 :

- Storyline contract ;
- Chapter contract ;
- Story Step contract ;
- Event contract ;
- Scene contract ou relation explicite à `ScenarioAsset` ;
- Cinematic reference contract ;
- Yarn outcome contract ;
- Battle reference contract ;
- Fact contract ;
- World Rule contract ;
- Validator diagnostic contract ;
- Reference registry ;
- règles de statut availability / active / completed ;
- mapping entre labels humains et stockage technique.

Séparation par phase :

- Phase 1 : langage produit et workflows documentaires.
- Phase 2 : modèles, contrats, registries, diagnostics domaine.
- Phase 3 : runtime, disk validation et preuves d'exécution.
- Phase 4 : authoring minimal dans `map_editor`.
- Phase 7 : UI moderne / premium finale, ergonomie complète et visual builders plus riches.

P1-06 ne doit pas écrire ces modèles. Il prépare la question que P1-07 devra poser : quels contrats Phase 2 sont vraiment nécessaires, dans quel ordre, et avec quels consumers.

## 27. Mise à jour de road_map_phase_1.md

Mise à jour attendue de la roadmap vivante :

```text
P1-06 : ✅ terminé
P1-07 : 🔜 prochain lot exact
```

Résumé ajouté :

```text
P1-06 spécifie les workflows auteur no-code minimaux, les pickers, les validations immédiates, les diagnostics Validator attendus et la séparation Phase 2 / Phase 4 / Phase 7.
```

Fichiers déclarés :

```text
Créé : reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md
Modifié : MVP Selbrume/road_map_phase_1.md
Non modifié : MVP Selbrume/road_map_global.md
```

Prochain lot exact :

```text
P1-07 — Phase 2 Domain Contract Proposal
```

## 28. Décisions à valider par l'utilisateur

Décisions non bloquantes à valider avant Phase 2 ou Phase 4 :

- Les workflows P1-06 doivent-ils être séparés en studios distincts ou regroupés dans un Narrative Studio unifié ?
- Faut-il commencer l'authoring minimal par Storyline/Step ou par Event/Scene ?
- Faut-il un Scene Builder graph minimal ou un assistant pas-à-pas en V0 ?
- Faut-il exposer les IDs techniques en mode avancé, et avec quel niveau de garde-fou ?
- Quels pickers sont obligatoires en V0 ?
- Quels diagnostics sont bloquants et lesquels sont seulement des warnings ?
- Les rewards doivent-ils entrer dans le workflow V0 ou rester un gameplay gap après Phase 1 ?
- La branche defeat du battle doit-elle être obligatoire dans l'UI auteur ?
- Faut-il une notion explicite d'availability pour Storyline et Story Step en Phase 2 ?

Aucune de ces décisions ne justifie d'élargir P1-06 vers du code ou de l'UI finale.

## 29. Evidence Pack

### 29.1 git status initial

```text
Sortie vide — aucun changement détecté au début du lot.
```

### 29.2 Fichiers lus

```text
AGENTS.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_1.md
MVP Selbrume/road_map.md
MVP Selbrume/narrative_studio.md
MVP Selbrume/selbrume.md
reports/roadmap/pokemap_full_product_phased_roadmap_v1.md
reports/roadmap/roadmap_global_00_master_phase_roadmap_bootstrap.md
reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md
reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md
reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md
reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md
reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md
reports/gameplay/audit/narrative_studio_product_model_v0.md
reports/gameplay/audit/sel_a2_event_scene_outcome_fact_contract.md
reports/gameplay/audit/sel_b2_battle_from_scene.md
reports/gameplay/ns_gs/ns_gs_08_npc_interaction_scene_authoring_readiness.md
reports/gameplay/ns_gs/ns_gs_09_yarn_outcome_scene_branch_readiness.md
reports/gameplay/ns_gs/ns_gs_10_world_rules_conditional_presence_readiness.md
reports/gameplay/ns_gs/ns_gs_11_trainer_battle_authoring_readiness.md
reports/gameplay/ns_gs/ns_gs_12_bis_evidence_pack_and_level_label_fix.md
reports/gameplay/ns_gs/ns_gs_13_narrative_validator_minimal_v0.md
reports/gameplay/ns_gs/ns_gs_14_item_pickup_give_item_authoring_readiness.md
reports/gameplay/ns_gs/ns_gs_15_key_item_door_gate_readiness.md
reports/gameplay/ns_gs/ns_gs_16_side_quest_optional_storyline_readiness.md
reports/gameplay/ns_gs/ns_gs_17_static_encounter_boss_battle_readiness.md
reports/gameplay/ns_gs/ns_gs_18_reward_money_xp_bridge_audit.md
reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md
/Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/using-superpowers/SKILL.md
/Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md
```

### 29.3 Fichiers créés

```text
reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md
```

### 29.4 Fichiers modifiés

```text
MVP Selbrume/road_map_phase_1.md
```

### 29.5 Commandes exécutées

```text
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/using-superpowers/SKILL.md
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md
git status --short --untracked-files=all
find reports -maxdepth 4 -type f | sort
find "MVP Selbrume" -maxdepth 2 -type f | sort
sed -n '1,260p' "MVP Selbrume/road_map_global.md"
sed -n '1,620p' "MVP Selbrume/road_map_phase_1.md"
sed -n '1,260p' reports/roadmap/pokemap_full_product_phased_roadmap_v1.md
sed -n '1,260p' reports/roadmap/roadmap_global_00_master_phase_roadmap_bootstrap.md
sed -n '1,260p' reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md
sed -n '1,220p' AGENTS.md
sed -n '1,420p' reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
sed -n '420,980p' reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
sed -n '1,420p' reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md
sed -n '420,980p' reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md
sed -n '1,460p' reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md
sed -n '460,980p' reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md
sed -n '1,460p' reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md
sed -n '460,980p' reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md
sed -n '1,460p' reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md
sed -n '460,920p' reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md
sed -n '920,1200p' reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md
sed -n '1,320p' "MVP Selbrume/narrative_studio.md"
sed -n '320,720p' "MVP Selbrume/narrative_studio.md"
sed -n '1,320p' "MVP Selbrume/selbrume.md"
sed -n '320,760p' "MVP Selbrume/selbrume.md"
sed -n '1,320p' "MVP Selbrume/road_map.md"
sed -n '1,320p' reports/gameplay/audit/narrative_studio_product_model_v0.md
sed -n '1,320p' reports/gameplay/audit/sel_a2_event_scene_outcome_fact_contract.md
sed -n '1,300p' reports/gameplay/audit/sel_b2_battle_from_scene.md
sed -n '1,280p' reports/gameplay/ns_gs/ns_gs_08_npc_interaction_scene_authoring_readiness.md
sed -n '1,300p' reports/gameplay/ns_gs/ns_gs_09_yarn_outcome_scene_branch_readiness.md
sed -n '1,320p' reports/gameplay/ns_gs/ns_gs_10_world_rules_conditional_presence_readiness.md
sed -n '1,320p' reports/gameplay/ns_gs/ns_gs_11_trainer_battle_authoring_readiness.md
sed -n '1,280p' reports/gameplay/ns_gs/ns_gs_12_bis_evidence_pack_and_level_label_fix.md
sed -n '1,320p' reports/gameplay/ns_gs/ns_gs_13_narrative_validator_minimal_v0.md
sed -n '1,300p' reports/gameplay/ns_gs/ns_gs_14_item_pickup_give_item_authoring_readiness.md
sed -n '1,320p' reports/gameplay/ns_gs/ns_gs_15_key_item_door_gate_readiness.md
sed -n '1,360p' reports/gameplay/ns_gs/ns_gs_16_side_quest_optional_storyline_readiness.md
sed -n '1,360p' reports/gameplay/ns_gs/ns_gs_17_static_encounter_boss_battle_readiness.md
sed -n '1,360p' reports/gameplay/ns_gs/ns_gs_18_reward_money_xp_bridge_audit.md
sed -n '1,420p' reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md
rg -n "Lot courant|Prochain lot|P1-05|P1-06|P1-07|Historique" "MVP Selbrume/road_map_phase_1.md"
sed -n '1,220p' "MVP Selbrume/road_map_phase_1.md"
sed -n '220,520p' "MVP Selbrume/road_map_phase_1.md"
sed -n '520,620p' "MVP Selbrume/road_map_phase_1.md"
apply_patch (création du rapport P1-06)
apply_patch (mise à jour de road_map_phase_1.md)
apply_patch (remplissage de l'Evidence Pack P1-06)
apply_patch (correction du comptage final de l'Evidence Pack)
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff --no-index --check /dev/null reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md || true
git diff -- "MVP Selbrume/road_map_phase_1.md"
git diff -- "MVP Selbrume/road_map_global.md"
git diff --name-only -- packages examples/playable_runtime_host
wc -l reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md "MVP Selbrume/road_map_phase_1.md" "MVP Selbrume/road_map_global.md"
sed -n '1135,1195p' reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md
```

### 29.6 git diff --check

```text
```

### 29.7 git diff --stat

```text
 MVP Selbrume/road_map_phase_1.md | 38 ++++++++++++++++++++++++++------------
 1 file changed, 26 insertions(+), 12 deletions(-)
```

### 29.8 git diff --name-only

```text
MVP Selbrume/road_map_phase_1.md
```

### 29.9 git status final

```text
 M "MVP Selbrume/road_map_phase_1.md"
?? reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md
```

### 29.10 Tests / analyze

```text
Non exécutés — P1-06 est documentaire et ne modifie aucun code.
```

### 29.11 git diff --no-index --check du rapport P1-06

Commande :

```bash
git diff --no-index --check /dev/null reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md || true
```

Sortie exacte :

```text
```

### 29.12 Diff complet de road_map_phase_1.md

```diff
diff --git a/MVP Selbrume/road_map_phase_1.md b/MVP Selbrume/road_map_phase_1.md
index 396c5206..2dbbbee4 100644
--- a/MVP Selbrume/road_map_phase_1.md
+++ b/MVP Selbrume/road_map_phase_1.md
@@ -6,9 +6,9 @@ Phase 1 — Canonical Product Model / Narrative Studio Foundations

 Statut : 🔜 En préparation

-Lot courant : P1-05 — Selbrume Reference Grammar Mapping
+Lot courant : P1-06 — No-code Workflow Specification

-Prochain lot exact après P1-05 : P1-06 — No-code Workflow Specification
+Prochain lot exact après P1-06 : P1-07 — Phase 2 Domain Contract Proposal

 Suivi des lots :

@@ -18,8 +18,8 @@ Suivi des lots :
 - ✅ P1-03 — Fact & World Rule Product Grammar
 - ✅ P1-04 — Storyline / Chapter / Story Step Structure
 - ✅ P1-05 — Selbrume Reference Grammar Mapping
-- 🔜 P1-06 — No-code Workflow Specification
-- P1-07 — Phase 2 Domain Contract Proposal
+- ✅ P1-06 — No-code Workflow Specification
+- 🔜 P1-07 — Phase 2 Domain Contract Proposal
 - P1-CHECKPOINT-01 — Canonical Product Model Closure & Phase 2 Decision

 P1-00 : ✅ terminé
@@ -34,7 +34,9 @@ P1-04 : ✅ terminé

 P1-05 : ✅ terminé

-P1-06 : 🔜 prochain lot exact
+P1-06 : ✅ terminé
+
+P1-07 : 🔜 prochain lot exact

 ## 2. Objectif de la Phase 1

@@ -310,7 +312,7 @@ Critères de validation :
 - les gaps de grammaire sont listés ;
 - les décisions à reporter en Phase 2 sont explicites.

-### 🔜 P1-06 — No-code Workflow Specification
+### ✅ P1-06 — No-code Workflow Specification

 Objectif :
 Décrire les workflows auteur minimaux sans UI finale :
@@ -339,7 +341,7 @@ Critères de validation :
 - le validator est placé dans le flux auteur ;
 - les dépendances Phase 2 / Phase 4 sont séparées.

-### P1-07 — Phase 2 Domain Contract Proposal
+### 🔜 P1-07 — Phase 2 Domain Contract Proposal

 Objectif :
 Transformer les décisions Phase 1 en proposition de lots Phase 2.
@@ -398,14 +400,14 @@ Critères de validation :

 ## 10. Prochain lot exact

-P1-06 — No-code Workflow Specification
+P1-07 — Phase 2 Domain Contract Proposal

 Objectif du prochain lot :
-Décrire les workflows auteur minimaux sans UI finale : créer Event, Scene,
-Fact, World Rule, battle ref, Yarn outcome et validator flow.
+Transformer les décisions Phase 1 en proposition de lots Phase 2 et lister les
+contrats domaine à créer, adapter ou reporter.

-P1-06 ne doit pas créer de code, de modèles `map_core`, d’UI, de fixtures
-Selbrume finales ou de `project.json`.
+P1-07 ne doit pas créer de code, de modèles `map_core`, de schemas JSON, de
+fixtures Selbrume finales ou de `project.json`.

 ## 11. Critères de sortie de Phase 1

@@ -536,3 +538,15 @@ P1-CHECKPOINT-01 devra aussi mettre à jour
   Décisions utilisateur nouvelles : aucune.
   Changements de périmètre : aucun.
   Prochain lot exact fixé à P1-06 — No-code Workflow Specification.
+- 2026-05-24 — P1-06 — No-code Workflow Specification terminé.
+  Résultat : workflows auteur no-code minimaux décrits de bout en bout, avec
+  pickers, validations immédiates, diagnostics Validator attendus et séparation
+  Phase 2 / Phase 4 / Phase 7.
+  Fichiers créés : `reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md`.
+  Fichiers modifiés : `MVP Selbrume/road_map_phase_1.md`.
+  Commandes exécutées : lectures Markdown ciblées, `find`, `rg`, `wc -l`,
+  `git status --short --untracked-files=all`, `git diff --check`,
+  `git diff --stat`, `git diff --name-only`, `git diff --no-index --check`.
+  Décisions utilisateur nouvelles : aucune.
+  Changements de périmètre : aucun.
+  Prochain lot exact fixé à P1-07 — Phase 2 Domain Contract Proposal.
```

### 29.13 Preuve road_map_global.md non modifiée

Commande :

```bash
git diff -- "MVP Selbrume/road_map_global.md"
```

Sortie exacte :

```text
```

### 29.14 Preuve qu'aucun package code n'est modifié

Commande :

```bash
git diff --name-only -- packages examples/playable_runtime_host
```

Sortie exacte :

```text
```

### 29.15 Comptage final des fichiers Markdown concernés

Commande :

```bash
wc -l reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md "MVP Selbrume/road_map_phase_1.md" "MVP Selbrume/road_map_global.md"
```

Sortie exacte finale :

```text
    1409 reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md
     552 MVP Selbrume/road_map_phase_1.md
     638 MVP Selbrume/road_map_global.md
    2599 total
```

## 30. Auto-review critique

Auto-review du lot :

- Le lot a modifié uniquement ce qui était autorisé : le rapport P1-06 et la roadmap vivante de Phase 1.
- Le rapport P1-06 existe au bon chemin : `reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md`.
- `road_map_phase_1.md` a été mise à jour pour marquer P1-06 terminé et P1-07 comme prochain lot exact.
- `road_map_global.md` est restée intacte.
- Aucun code n'a été modifié.
- Aucun test/analyze Dart/Flutter n'a été lancé.
- P1-07 n'a pas été commencé ; il est seulement annoncé comme prochain lot exact.
- Selbrume reste une référence conceptuelle.
- Aucun contenu Selbrume final n'a été créé.
- Le rapport reste workflow produit et non UI finale.
- Le rapport évite de créer un Scene Builder complet ou un Cinematic Builder complet.
- Les pickers, validations et diagnostics sont listés concrètement.
- Les dépendances Phase 2 / Phase 4 / Phase 7 sont séparées.

Ambiguïtés restantes :

- le niveau exact d'obligation de la branche defeat dans l'authoring V0 ;
- le choix entre assistant pas-à-pas et graph minimal pour la Scene en Phase 4 ;
- la frontière exacte entre reward conceptuel, reward gameplay et future UI reward ;
- la forme du mode avancé qui peut afficher les IDs techniques sans redevenir le langage principal.

### Regard critique sur le prompt

Le prompt est strict et bien cadré. Sa principale ambiguïté tient au mot "workflow" : il autorise de parler de panneaux, pickers et assistants, mais interdit l'UI finale. La résolution retenue ici est de documenter les capacités auteur attendues sans imposer de layout, de design system ou de widget. Le prompt demande aussi de séparer Phase 2, Phase 4 et Phase 7 ; cette séparation est utile mais devra être validée dans P1-07 pour éviter de transformer prématurément des workflows en contrats techniques.
