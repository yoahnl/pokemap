# P1-05 — Selbrume Reference Grammar Mapping

## 1. Résumé exécutif

P1-05 a mappé conceptuellement le Golden Slice Selbrume “Lysa au port” sur la
grammaire produit définie par les lots P1-01 à P1-04.

Le flow de référence testé est :

```text
Parler à Lysa au port
→ Event vérifie Step actif + rival non battu
→ Scene “Rencontre rival”
→ Dialogue Yarn “rival_intro”
→ outcome confident / hesitant / aggressive
→ Cinematic choisie par la Scene
→ Battle Rival
→ outcome victory / defeat
→ Fact persistant
→ Story Step completed
→ World Rule change Lysa
→ Storyline secondaire disponible
→ Validator diagnostique la chaîne
```

Conclusion produit : la grammaire Phase 1 couvre le Golden Slice Selbrume au
niveau conceptuel. Les frontières tiennent :

- Storyline / Chapter / Story Step organisent la progression.
- Event déclenche.
- Scene orchestre.
- Cinematic met en scène.
- Yarn produit des outcomes.
- Battle résout le combat.
- Fact nomme ce qui devient vrai.
- World Rule montre dans le monde ce qui découle de ces vérités.
- Validator diagnostique la cohérence.

Les gaps restants sont surtout des décisions de grammaire à préciser avant les
contrats Phase 2 : vocabulaire d’availability, statut de defeat/retry, choix
Yarn temporaire ou durable, entry point de Storyline secondaire, statut des
Rewards et statut du passage marais/phare. Les gaps techniques restent hors
P1-05 : runtime Flame complet, projet disque créé par l’éditeur, reward model,
Quest Journal, Validator intégré dans l’éditeur, UI no-code moderne.

P1-05 n’a créé aucun contenu Selbrume final, aucune fixture, aucun project.json
et aucun code.

Prochain lot exact :

```text
P1-06 — No-code Workflow Specification
```

## 2. Scope du lot

Inclus :

- lecture des roadmaps et rapports Phase 1 ;
- lecture des documents Selbrume et Narrative Studio ;
- lecture des rapports NS-GS utiles au Golden Slice ;
- création du rapport P1-05 ;
- mapping conceptuel du Golden Slice “Lysa au port” ;
- identification des gaps de grammaire ;
- séparation des gaps techniques hors P1-05 ;
- mise à jour de `MVP Selbrume/road_map_phase_1.md`.

Exclus :

- aucun code modifié ;
- aucun test lancé ;
- aucun package modifié ;
- aucun modèle `map_core` créé ;
- aucun contrat JSON créé ;
- aucune fixture Selbrume créée ;
- aucun contenu Selbrume final créé ;
- aucune map Selbrume créée ;
- aucun PNJ Selbrume créé ;
- aucun dialogue Yarn Selbrume final créé ;
- aucun trainer Selbrume final créé ;
- aucun battle Selbrume final créé ;
- aucun `project.json` Selbrume créé ;
- aucune modification de `MVP Selbrume/road_map_global.md` ;
- aucun démarrage de P1-06.

Fichiers créés :

- `reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md`

Fichiers modifiés :

- `MVP Selbrume/road_map_phase_1.md`

Fichiers explicitement non modifiés :

- `MVP Selbrume/road_map_global.md`
- `packages/map_core`
- `packages/map_gameplay`
- `packages/map_battle`
- `packages/map_runtime`
- `packages/map_editor`
- `examples/playable_runtime_host`

Selbrume est utilisé comme référence conceptuelle uniquement.

## 3. Sources lues

Roadmaps et gouvernance :

- `AGENTS.md` — règles repo, frontières package, sécurité Git et evidence.
- `MVP Selbrume/road_map_global.md` — gouvernance globale lue pour contexte,
  non modifiée.
- `MVP Selbrume/road_map_phase_1.md` — roadmap vivante Phase 1 à mettre à jour.
- `reports/roadmap/pokemap_full_product_phased_roadmap_v1.md` — proposition
  stratégique globale par phases.
- `reports/roadmap/roadmap_global_00_master_phase_roadmap_bootstrap.md` —
  bootstrap de la roadmap globale vivante.
- `reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md` — cadrage Phase 1.
- `reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md` —
  glossaire canonique.
- `reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md` —
  frontières Event / Scene / Cinematic.
- `reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md` —
  grammaire Fact / World Rule.
- `reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md` —
  structure Storyline / Chapter / Story Step.

Documents Selbrume et Narrative Studio :

- `MVP Selbrume/road_map.md` — roadmap NS-GS historique.
- `MVP Selbrume/narrative_studio.md` — vision Narrative Studio et grammaire
  auteur.
- `MVP Selbrume/selbrume.md` — scénario de référence Selbrume, utilisé
  conceptuellement.

Rapports NS-GS et audits lus :

- `reports/gameplay/audit/narrative_studio_product_model_v0.md` — modèle
  produit initial et limites.
- `reports/gameplay/audit/sel_a2_event_scene_outcome_fact_contract.md` —
  contrat Event / Scene / Outcome / Fact et historique du blocker battle.
- `reports/gameplay/audit/sel_b2_battle_from_scene.md` — preuve d’un battle
  lancé depuis une Scene au niveau application.
- `reports/gameplay/ns_gs/ns_gs_08_npc_interaction_scene_authoring_readiness.md`
  — interaction PNJ vers Scene.
- `reports/gameplay/ns_gs/ns_gs_09_yarn_outcome_scene_branch_readiness.md` —
  outcomes Yarn et branching de Scene.
- `reports/gameplay/ns_gs/ns_gs_10_world_rules_conditional_presence_readiness.md`
  — World Rules de présence et dialogue conditionnel.
- `reports/gameplay/ns_gs/ns_gs_11_trainer_battle_authoring_readiness.md` —
  battle trainer authorable au niveau application.
- `reports/gameplay/ns_gs/ns_gs_12_bis_evidence_pack_and_level_label_fix.md`
  — correction de labels de preuve.
- `reports/gameplay/ns_gs/ns_gs_13_narrative_validator_minimal_v0.md` —
  Validator V0.
- `reports/gameplay/ns_gs/ns_gs_14_item_pickup_give_item_authoring_readiness.md`
  — item pickup / give item.
- `reports/gameplay/ns_gs/ns_gs_15_key_item_door_gate_readiness.md` — key item
  et door gate pattern.
- `reports/gameplay/ns_gs/ns_gs_16_side_quest_optional_storyline_readiness.md`
  — side quest comme optional storyline.
- `reports/gameplay/ns_gs/ns_gs_17_static_encounter_boss_battle_readiness.md`
  — boss trainer-like et limites static encounter.
- `reports/gameplay/ns_gs/ns_gs_18_reward_money_xp_bridge_audit.md` — reward,
  money et XP gaps.
- `reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md`
  — clôture mechanics-first et limites Level 3/4.

## 4. Rappel de la grammaire Phase 1

P1-01 a fixé le vocabulaire canonique :

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

- Event choisit le point d’entrée.
- Scene décide l’enchaînement et les conséquences.
- Cinematic exécute une séquence linéaire de présentation.

P1-03 a durci :

- Fact = ce qui est vrai.
- World Rule = ce que le monde montre parce que c’est vrai.
- Scene écrit les conséquences durables.
- World Rule ne déclenche pas de Scene.

P1-04 a durci :

- Storyline = une ligne narrative.
- Chapter = une section de cette ligne.
- Story Step = un jalon de progression.
- Side quest V0 = Storyline secondaire.

P1-05 teste cette grammaire sur Selbrume sans créer Selbrume.

## 5. Objectif du mapping Selbrume

P1-05 vérifie que la grammaire Phase 1 peut décrire un flow Pokémon-like
concret sans se réfugier dans des flags techniques ou dans une implémentation
prématurée.

Questions testées :

- La grammaire couvre-t-elle une progression principale ?
- Les concepts sont-ils suffisants pour un flow interaction → dialogue →
  cinématique → combat → conséquences ?
- Les frontières Event / Scene / Cinematic restent-elles lisibles ?
- Les Facts et World Rules restent-ils distincts ?
- Une side quest peut-elle rester une Storyline secondaire sans Quest Engine ?
- Le Validator peut-il théoriquement diagnostiquer la chaîne ?

P1-05 n’est pas un lot d’implémentation. Il ne crée ni modèles, ni runtime, ni
UI, ni projet Selbrume. Il prépare P1-06 et Phase 2 en rendant les workflows et
contrats attendus plus concrets.

## 6. Selbrume — périmètre conceptuel utilisé

Périmètre conceptuel utilisé :

- Storyline principale : Les Brumes de Selbrume.
- Chapter conceptuel : Le port.
- Golden Slice : interaction avec Lysa au port → rencontre rival → battle →
  conséquences.
- Side Quest conceptuelle : Aider Soline, rendue disponible après le rival.

Noms utilisés comme références conceptuelles :

- Lysa ;
- Maël ;
- Soline ;
- rival ;
- port ;
- marais ;
- phare.

Ces noms ne correspondent à aucun contenu créé par P1-05.

Le document `MVP Selbrume/selbrume.md` contient déjà des éléments narratifs
conceptuels utiles, notamment une rivalité au port, des outcomes de dialogue, des
facts de victoire/défaite et des projections de monde. P1-05 les utilise comme
matière de test de grammaire, pas comme ordre de génération de contenu.

## 7. Golden Slice principal “Lysa au port”

Flow cible complet :

1. Le joueur arrive au port.
2. Le joueur parle à Lysa.
3. L’Event vérifie que le Step attendu est actif et que le rival n’est pas
   battu.
4. La Scene “Rencontre rival” démarre.
5. Le Dialogue Yarn “rival_intro” propose plusieurs tons de réponse.
6. Un outcome `confident`, `hesitant` ou `aggressive` est produit.
7. La Scene lit cet outcome.
8. La Scene choisit une Cinematic courte selon l’outcome.
9. La Scene lance un combat Rival.
10. Battle retourne `victory` ou `defeat`.
11. La Scene lit l’outcome battle.
12. En `victory`, la Scene écrit un Fact et complète un Story Step.
13. En `defeat`, la Scene applique la politique narrative décidée : retry,
    progression malgré défaite, ou branche de revanche.
14. World Rule change le dialogue ou la présence de Lysa.
15. Une side quest devient disponible.
16. Validator peut vérifier que chaque référence est atteignable.

Branches conceptuelles :

- `confident`, `hesitant`, `aggressive` sont des outcomes Yarn conceptuels.
- `victory` et `defeat` sont des outcomes battle conceptuels.
- Les Facts, World Rules et Steps nommés ici sont des exemples de grammaire, pas
  des données créées dans le repo.

## 8. Mapping Storyline / Chapter / Story Step

| Élément Selbrume conceptuel | Concept Phase 1 | Rôle | Pourquoi c’est le bon concept | Gaps / questions |
|---|---|---|---|---|
| Les Brumes de Selbrume | Storyline principale | Ligne narrative suivable de l’île, du port au phare. | Elle répond à “de quelle histoire parle-t-on ?”. | Statuts exacts `available` / `active` / `completed` à valider en Phase 2. |
| Le port | Chapter | Section lisible de progression. | Il groupe des Steps et des scènes autour d’un lieu narratif, sans devenir forcément une map runtime. | Chapter obligatoire ou recommandé seulement pour l’histoire principale ? |
| Parler à Lysa au port | Story Step | Jalon d’entrée du Golden Slice. | Il décrit une progression attendue compréhensible par un créateur. | Peut être fusionné avec “rencontrer le rival” ou rester Step distinct. |
| Battre le rival au port | Story Step | Jalon de résolution du conflit portuaire. | Il peut être complété par la Scene après outcome battle. | Si defeat fait aussi progresser, le nom du Step doit devenir plus neutre. |
| Accéder à la suite vers marais/phare | Story Step futur | Jalon qui ouvre la suite de l’histoire. | Il décrit une progression narrative, pas une porte technique seule. | Besoin futur Door/Warp ou World Rule d’interactabilité. |
| Aider Soline | Storyline secondaire / sideQuest | Quête annexe disponible après le rival. | P1-04 a positionné side quest V0 comme Storyline secondaire. | Entry point, reward et journal restent hors P1-05. |

Frontières :

- Story Step ≠ Fact : “Battre le rival au port” est un jalon ; “Le rival a été
  battu au port” est une vérité.
- Story Step ≠ Scene : le Step décrit ce qui progresse ; la Scene orchestre ce
  qui se passe.
- Storyline secondaire ≠ Quest Engine obligatoire : “Aider Soline” peut être une
  Storyline typée sideQuest sans moteur séparé en V0.

## 9. Mapping Event / Scene / Cinematic

| Élément du flow | Concept | Responsabilité | Limite |
|---|---|---|---|
| Interaction avec Lysa | Event | Déclencher depuis une interaction PNJ, vérifier Step actif + rival non battu, cibler une Scene. | Ne contient pas le dialogue, le battle ou les conséquences durables. |
| Rencontre rival | Scene | Orchestrer Yarn, Cinematic, Battle, outcomes, Fact writes et Step completion. | Ne doit pas être réduite à une simple cutscene. |
| Entrée de Lysa ou du rival | Cinematic | Déplacer personnage, caméra, pauses, regards, effets courts. | Ne complète pas le Step et n’écrit pas de Fact. |
| Variation selon outcome Yarn | Scene choisit Cinematic | La Scene lit l’outcome et choisit la mise en scène. | Le Yarn ne devient pas moteur global de progression. |
| Départ après combat | Cinematic éventuelle | Montrer départ, repositionnement, pause ou réaction. | La progression reste décidée par la Scene. |

Contrat réaffirmé :

- Event ne contient pas le battle.
- Scene orchestre le battle.
- Cinematic ne complète pas le Step.

## 10. Mapping Dialogue Yarn / Outcomes

Le Dialogue Yarn porte le texte, les choix et les outcomes de dialogue.

Dans le Golden Slice :

- `rival_intro` est le dialogue conceptuel de rencontre.
- `confident`, `hesitant`, `aggressive` sont des outcomes de ton.
- La Scene lit l’outcome.
- La Scene décide si l’outcome reste temporaire ou devient Fact durable.

Distinctions :

| Élément | Nature | Durabilité | Décision recommandée |
|---|---|---|---|
| `confident` utilisé pour une réplique immédiate | Outcome temporaire | Non persisté | Pas de Fact nécessaire. |
| `confident` utilisé plus tard par Lysa | Outcome durable | Persisté via Fact ou état dérivé | La Scene peut écrire “Le joueur a répondu avec assurance”. |
| `hesitant` utilisé seulement pour une Cinematic courte | Outcome temporaire | Non persisté | La Scene choisit une Cinematic et n’écrit rien. |
| `aggressive` qui change une relation future | Outcome durable | Persisté si design voulu | La Scene peut écrire un Fact relationnel. |

Anti-confusion :

- Yarn produit un résultat.
- Scene interprète ce résultat.
- Yarn ne doit pas écrire directement une collection de flags invisibles.

## 11. Mapping Battle / Battle Outcome

La Scene lance le combat Rival. Battle résout le combat et retourne un outcome.
La Scene interprète ensuite ce résultat.

| Battle outcome | Conséquence Scene | Fact éventuel | Step éventuel | World Rule éventuelle |
|---|---|---|---|---|
| `victory` | Rival battu, respect gagné, suite ouverte. | “Le rival a été battu au port.” | “Battre le rival au port” terminé. | Lysa utilise un dialogue post-combat ; la side quest devient disponible. |
| `defeat` avec retry | Pas de Step terminé, dialogue de revanche ou relance possible. | Fact optionnel “Le joueur a perdu contre Lysa au port.” | Step reste actif. | Lysa propose une revanche. |
| `defeat` avec progression | Lysa avance malgré la défaite, histoire continue. | “Le joueur a perdu contre Lysa au port.” | Step peut être terminé si le design veut avancer. | Lysa change vers un dialogue de moquerie douce. |

Le choix exact de politique de défaite reste une décision utilisateur. Dans tous
les cas, Battle ne décide pas seul de la progression narrative.

## 12. Mapping Fact / Story Step Completion

Facts conceptuels possibles :

- “Le rival a été battu au port.”
- “Le joueur a choisi une réponse confiante.”
- “Lysa a reconnu la force du joueur.”
- “La quête annexe de Soline est disponible.”

| Élément | Catégorie | Source recommandée | Usage | Commentaire |
|---|---|---|---|---|
| Le rival a été battu au port. | Fact source-of-truth | Scene après `battle.victory` | Conditions, World Rules, diagnostics. | Fact durable central du Golden Slice. |
| Le joueur a choisi une réponse confiante. | Fact durable optionnel | Scene après outcome Yarn | Dialogue futur ou relation. | À écrire seulement si utilisé plus tard. |
| Lysa a reconnu la force du joueur. | Fact relationnel | Scene après victory ou branche spécifique | Dialogue / side quest availability. | Peut être dérivé du rival battu si aucune nuance distincte. |
| La quête annexe de Soline est disponible. | Fact de disponibilité ou état dérivé | Scene ou dérivation depuis Step terminé | Availability de Storyline secondaire. | Peut être dérivé au lieu d’être stocké. |
| Step “Battre le rival au port” terminé. | Story Step completion | Scene après battle outcome retenu | Progression narrative. | Peut être lu comme Fact dérivé. |
| `confident` / `hesitant` / `aggressive` | Outcome temporaire | Yarn | Branche immédiate de Scene. | Devient Fact seulement si une conséquence future existe. |

Règle produit :

- Step completion décrit la progression.
- Fact décrit une vérité lisible.
- Outcome décrit un résultat immédiat.
- Le stockage technique futur ne doit pas être exposé au créateur comme langage
  principal.

## 13. Mapping World Rules

World Rules conceptuelles :

| Condition lue | Projection visible | Ce que la World Rule ne fait pas |
|---|---|---|
| “Le rival a été battu au port.” | Lysa utilise son dialogue post-combat. | Elle ne lance pas la Scene post-combat. |
| “Le joueur a perdu contre Lysa au port.” | Lysa utilise un dialogue de revanche ou de moquerie douce. | Elle ne décide pas que le Step est terminé. |
| Rival non battu + Step port actif | Lysa reste disponible comme entrée de rencontre. | Elle ne remplace pas l’Event d’interaction. |
| Step port terminé | L’entrée vers une side quest devient visible ou disponible. | Elle ne lance pas la side quest. |
| Passage futur vers marais/phare débloqué | Une porte, un passage ou une interaction peut apparaître comme accessible. | Elle ne fait pas un warp narratif actif. |

Clarification centrale :

```text
World Rule ne lance pas la side quest.
World Rule rend l’entrée visible ou disponible.
Un Event séparé déclenche la Scene de side quest quand le joueur interagit.
```

## 14. Mapping Side Quest Availability

Storyline secondaire conceptuelle :

```text
Aider Soline
```

Mapping :

- Type : Storyline secondaire / sideQuest.
- Availability : après “Le rival a été battu au port” ou après Step port
  terminé.
- Entry Event : parler à Soline ou interagir avec un élément disponible.
- Scene start : introduction de la quête.
- Facts possibles : quête acceptée, objectif rempli, récompense donnée.
- World Rules : Soline change de dialogue, récompense visible ou masquée,
  entrée de quête affichée.

Conclusion P1-05 :

```text
Le modèle Phase 1 suffit à représenter cette side quest comme Storyline
secondaire.
Pas besoin de Quest Engine obligatoire en V0.
```

Limites :

- Quest Journal futur non couvert.
- Tracking UI futur non couvert.
- Reward model unifié non couvert.
- Save data et contrats persistants non couverts.

## 15. Mapping Validator

Diagnostics théoriques que le Validator pourrait produire sur ce Golden Slice :

- Storyline principale sans Step initial.
- Chapter “Le port” sans Step.
- Story Step “Parler à Lysa au port” jamais activable.
- Event Lysa sans source d’interaction.
- Event Lysa cible une Scene absente.
- Event Lysa lit un Step inconnu.
- Event Lysa lit un Fact non déclaré.
- Scene rival référence Yarn absent.
- Scene rival référence Cinematic absente.
- Scene rival référence Battle absent.
- Yarn outcome `confident` non géré.
- Yarn outcome `hesitant` non géré.
- Yarn outcome `aggressive` non géré.
- Battle outcome `defeat` non géré.
- Fact “Le rival a été battu au port” lu mais jamais écrit.
- Story Step terminé par une Scene absente.
- World Rule cible PNJ absent.
- World Rule cible dialogue absent.
- Side quest disponible mais sans Event d’entrée.
- Step terminé mais aucune suite narrative ou World Rule attendue.

Ces diagnostics ne sont pas implémentés par P1-05. Le Validator diagnostique ; il
ne corrige pas automatiquement.

## 16. Cycle complet du Golden Slice

```text
Storyline principale: Les Brumes de Selbrume
  Chapter: Le port
    Step: Parler à Lysa au port
      Event: interaction Lysa
        Conditions:
          - Step port actif
          - Le rival n'a pas été battu au port
        Scene: Rencontre rival
          Yarn: rival_intro
            outcomes:
              - confident
              - hesitant
              - aggressive
          Scene branch:
            confident → Cinematic variante assurance
            hesitant → Cinematic variante hésitation
            aggressive → Cinematic variante tension
          Battle: rival au port
            outcomes:
              - victory
              - defeat
          victory:
            Fact: Le rival a été battu au port
            Step completed: Battre le rival au port
            World Rule: Lysa dialogue post-combat
            World Rule: side quest Soline available
          defeat:
            Policy à valider:
              - retry
              - progression malgré défaite
              - branche de revanche
            Fact optionnel: Le joueur a perdu contre Lysa au port

Storyline secondaire: Aider Soline
  Availability:
    - Fact rival battu
    - ou Step port terminé
  Entry:
    Event séparé: interaction Soline
  Scene:
    Introduction de quête annexe

Validator:
  Vérifie références, outcomes gérés, facts écrits/lus,
  steps atteignables et world rules ciblées.
```

Ce cycle est conceptuel et ne crée aucun contenu final dans le repo.

## 17. Gaps de grammaire identifiés

Gaps de grammaire produit :

| Gap | Pourquoi il apparaît dans Selbrume | Décision attendue |
|---|---|---|
| Availability Storyline / Step | La side quest devient disponible après le rival. | Nommer explicitement availability et ses conditions en Phase 2. |
| Fact de disponibilité vs Fact de résolution | “Quête Soline disponible” peut être dérivé de “rival battu”. | Décider quand stocker un Fact ou le dériver. |
| Defeat policy | Le flow Selbrume peut avancer ou proposer retry après défaite. | Choisir si defeat est fallback, retry, ou branche narrative explicite. |
| Outcome temporaire vs durable | `confident` peut rester local ou influencer plus tard. | Exposer une décision auteur : mémoriser ou non l’outcome. |
| Entry point de Storyline secondaire | Side quest disponible ne signifie pas lancée. | Définir l’entrée explicite : Event séparé + Scene start. |
| Reward | Side quest et battle peuvent donner reward. | Décider si Reward entre dans la grammaire Phase 1 ou reste gameplay gap. |
| Passage marais/phare | La suite peut être Step, World Rule, Door/Warp ou combinaison. | Clarifier la composition produit avant contrats Door/Warp. |

Ces gaps ne bloquent pas le mapping conceptuel. Ils doivent être portés dans P1-06
et Phase 2 comme décisions ou contrats à stabiliser.

## 18. Gaps techniques déjà connus mais hors P1-05

| Gap | Catégorie | Statut prudent |
|---|---|---|
| Golden Slice complet dans PlayableMapGame / Flame | Technique Phase 2+ / runtime | Non prouvé complet. |
| Projet disque créé dans l’éditeur | Technique Phase 2+ / disk | Non prouvé. |
| Static wild encounter authorable par scénario | Gameplay futur | Non prouvé complet. |
| Money reward | Gameplay futur | Non prouvé. |
| XP / level-up / learn move post-battle | Gameplay futur | Non prouvé. |
| Reward Model unifié | Gameplay / domaine futur | Absent. |
| `hasItem` direct / `bagContains` direct | Domaine / gameplay | Absent ou partiel selon le pattern. |
| Door Engine réel / warp conditionnel | Runtime / gameplay | Partiel. |
| Quest Journal | UI / gameplay futur | Absent. |
| Validator intégré dans `map_editor` | UI / validation future | Absent. |
| UI no-code moderne | UI future | Absente. |

Ces gaps ne doivent pas être résolus par P1-05.

## 19. Ce que P1-05 prouve

P1-05 prouve uniquement :

- la grammaire Phase 1 peut décrire conceptuellement le Golden Slice Selbrume ;
- les frontières restent cohérentes sur un flow concret ;
- Event / Scene / Cinematic peuvent rester séparés même avec dialogue, battle et
  conséquences ;
- Fact / Story Step / World Rule peuvent rester distincts ;
- les side quests peuvent être modélisées comme Storylines secondaires ;
- les gaps restants sont identifiables avant Phase 2.

## 20. Ce que P1-05 ne prouve pas

P1-05 ne prouve pas :

- que le runtime Flame exécute Selbrume ;
- que l’éditeur peut créer Selbrume ;
- que le projet disque Selbrume existe ;
- que les modèles `map_core` existent ;
- que le Validator analyse réellement ce Golden Slice ;
- que le battle complet fonctionne dans ce flow ;
- que les rewards money/XP existent ;
- que l’UI no-code est prête ;
- que des maps, PNJ, dialogues, battles ou fixtures Selbrume finales existent.

## 21. Vocabulaire utilisateur recommandé pour Selbrume

Libellés no-code recommandés :

| Concept | Libellé utilisateur Selbrume |
|---|---|
| Storyline principale | Histoire principale : Les Brumes de Selbrume |
| Chapter | Chapitre : Le port |
| Story Step | Étape : Parler à Lysa au port |
| Event | Déclencheur : Quand le joueur parle à Lysa |
| Scene | Scène : Rencontre rival |
| Dialogue Yarn | Dialogue : Introduction du rival |
| Cinematic | Mise en scène : Entrée du rival |
| Battle | Combat : Rival au port |
| Fact | Fait du monde : Le rival a été battu au port |
| World Rule | Règle du monde : Lysa parle après le combat |
| Side quest | Quête annexe : Aider Soline |
| Validator | Diagnostic : La scène Rival ne gère pas la défaite |

Termes à éviter dans le flux auteur normal :

- `flag_rival_port_done`
- `scenario.outcome.rival_intro.confident`
- `event_lysa_003`
- `node_12_trueBranch`
- `completedStepIds`
- `storyFlags.activeFlags`

Ces termes peuvent rester dans des panneaux techniques ou diagnostics avancés,
mais ils ne doivent pas devenir le langage principal du créateur.

## 22. Anti-patterns Selbrume interdits

- Créer les vraies fixtures Selbrume pendant P1-05.
- Créer un `project.json` Selbrume.
- Coder une map ou un PNJ.
- Créer un Yarn final Selbrume.
- Créer un battle final Selbrume.
- Utiliser World Rule pour lancer la quête Soline.
- Laisser Yarn écrire directement tous les flags.
- Faire du battle outcome le moteur narratif principal.
- Faire de Chapter “Le port” une map obligatoire.
- Faire de la side quest un Quest Engine complet.
- Ignorer la branche `defeat`.
- Ignorer les diagnostics Validator théoriques.
- Vendre ce mapping comme une preuve runtime.

## 23. Impacts attendus pour P1-06 et Phase 2

P1-06 devra traiter :

```text
P1-06 — No-code Workflow Specification
```

Workflows auteur à décrire en P1-06 :

- créer une Storyline principale ;
- créer un Chapter ;
- créer un Story Step ;
- créer un Event d’interaction ;
- créer une Scene ;
- associer un Dialogue Yarn ;
- associer une Cinematic ;
- associer un Battle ;
- définir les outcomes ;
- définir les Facts ;
- définir les World Rules ;
- définir une Storyline secondaire ;
- lancer le Validator.

Phase 2 devra potentiellement transformer les conclusions P1-05 en contrats :

- Storyline contract ;
- Step contract ;
- Event contract ;
- Scene contract ;
- Fact contract ;
- World Rule contract ;
- Validator diagnostics ;
- reference registry.

P1-05 ne doit pas écrire ces modèles.

## 24. Mise à jour de road_map_phase_1.md

`MVP Selbrume/road_map_phase_1.md` a été mise à jour pour refléter :

- `P1-05 : ✅ terminé`
- `P1-06 : 🔜 prochain lot exact`
- le résumé court du résultat P1-05 ;
- les fichiers créés / modifiés ;
- les commandes exécutées ;
- l’absence de décision utilisateur nouvelle ;
- l’absence de changement de périmètre ;
- le prochain lot exact :

```text
P1-06 — No-code Workflow Specification
```

`MVP Selbrume/road_map_global.md` a été lu mais non modifié.

## 25. Décisions à valider par l’utilisateur

Décisions non bloquantes à valider avant les contrats Phase 2 :

- La branche `defeat` du rival doit-elle être explicitement modélisée ou rester
  fallback ?
- Le choix `confident` / `hesitant` / `aggressive` doit-il être temporaire ou
  devenir Fact durable ?
- La quête Soline doit-elle être disponible immédiatement après `victory` ou
  après un Step séparé ?
- Faut-il une notion `availability` explicite pour Storyline / Step en Phase 2 ?
- Faut-il introduire un concept Reward dans la grammaire produit ou le garder
  hors Phase 1 ?
- Faut-il représenter “passage vers phare/marais” comme Story Step, World Rule
  ou future mécanique Door/Warp ?
- Si defeat fait avancer Selbrume, le Step doit-il être nommé “Affronter le
  rival” plutôt que “Battre le rival” ?

Aucune de ces décisions ne bloque P1-05. Elles orientent P1-06 et Phase 2.

## 26. Evidence Pack

### 26.1 git status initial

```text
Sortie vide — aucun changement détecté au début du lot.
```

### 26.2 Fichiers lus

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

### 26.3 Fichiers créés

```text
reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md
```

### 26.4 Fichiers modifiés

```text
MVP Selbrume/road_map_phase_1.md
```

### 26.5 Commandes exécutées

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
sed -n '1,220p' AGENTS.md
sed -n '1,260p' reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md
sed -n '1,420p' reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
sed -n '420,980p' reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
sed -n '1,420p' reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md
sed -n '420,980p' reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md
sed -n '1,460p' reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md
sed -n '460,980p' reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md
sed -n '1,460p' reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md
sed -n '460,980p' reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md
sed -n '980,1500p' reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md
sed -n '1,320p' "MVP Selbrume/narrative_studio.md"
sed -n '320,720p' "MVP Selbrume/narrative_studio.md"
sed -n '1,300p' "MVP Selbrume/selbrume.md"
sed -n '300,760p' "MVP Selbrume/selbrume.md"
sed -n '1,320p' "MVP Selbrume/road_map.md"
rg -n "Lysa|rival|Soline|quête annexe|Quête annexe|Chapitre 1|Le port|Combat rival|confident|hesitant|aggressive|défaite|victoire|World Rule|Fact|Validator|Passage|phare|marais" "MVP Selbrume/selbrume.md"
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
sed -n '1,340p' reports/gameplay/ns_gs/ns_gs_17_static_encounter_boss_battle_readiness.md
sed -n '1,360p' reports/gameplay/ns_gs/ns_gs_18_reward_money_xp_bridge_audit.md
sed -n '1,360p' reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md
rg -n "Lot courant|Prochain lot|P1-04|P1-05|P1-06|Historique" "MVP Selbrume/road_map_phase_1.md"
sed -n '1,220p' "MVP Selbrume/road_map_phase_1.md"
sed -n '250,430p' "MVP Selbrume/road_map_phase_1.md"
sed -n '430,560p' "MVP Selbrume/road_map_phase_1.md"
apply_patch
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff --no-index --check /dev/null reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md || true
git diff -- "MVP Selbrume/road_map_phase_1.md"
git diff -- "MVP Selbrume/road_map_global.md"
git diff --name-only -- packages examples/playable_runtime_host
wc -l reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md "MVP Selbrume/road_map_phase_1.md" "MVP Selbrume/road_map_global.md"
```

### 26.6 git diff --check

Sortie exacte vide.

```text
```

### 26.7 git diff --stat

```text
 MVP Selbrume/road_map_phase_1.md | 36 ++++++++++++++++++++++++++----------
 1 file changed, 26 insertions(+), 10 deletions(-)
```

### 26.8 git diff --name-only

```text
MVP Selbrume/road_map_phase_1.md
```

### 26.9 git status final

```text
 M "MVP Selbrume/road_map_phase_1.md"
?? reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md
```

### 26.10 Tests / analyze

```text
Non exécutés — P1-05 est documentaire et ne modifie aucun code.
```

### 26.11 git diff --no-index --check du rapport P1-05

Sortie exacte vide.

```text
```

### 26.12 Diff complet de road_map_phase_1.md

```diff
diff --git a/MVP Selbrume/road_map_phase_1.md b/MVP Selbrume/road_map_phase_1.md
index 5a73d693..396c5206 100644
--- a/MVP Selbrume/road_map_phase_1.md
+++ b/MVP Selbrume/road_map_phase_1.md
@@ -6,9 +6,9 @@ Phase 1 — Canonical Product Model / Narrative Studio Foundations

 Statut : 🔜 En préparation

-Lot courant : P1-04 — Storyline / Chapter / Story Step Structure
+Lot courant : P1-05 — Selbrume Reference Grammar Mapping

-Prochain lot exact après P1-04 : P1-05 — Selbrume Reference Grammar Mapping
+Prochain lot exact après P1-05 : P1-06 — No-code Workflow Specification

 Suivi des lots :

@@ -17,8 +17,8 @@ Suivi des lots :
 - ✅ P1-02 — Event / Scene / Cinematic Boundary Contract
 - ✅ P1-03 — Fact & World Rule Product Grammar
 - ✅ P1-04 — Storyline / Chapter / Story Step Structure
-- 🔜 P1-05 — Selbrume Reference Grammar Mapping
-- P1-06 — No-code Workflow Specification
+- ✅ P1-05 — Selbrume Reference Grammar Mapping
+- 🔜 P1-06 — No-code Workflow Specification
 - P1-07 — Phase 2 Domain Contract Proposal
 - P1-CHECKPOINT-01 — Canonical Product Model Closure & Phase 2 Decision

@@ -32,7 +32,9 @@ P1-03 : ✅ terminé

 P1-04 : ✅ terminé

-P1-05 : 🔜 prochain lot exact
+P1-05 : ✅ terminé
+
+P1-06 : 🔜 prochain lot exact

 ## 2. Objectif de la Phase 1

@@ -280,7 +282,7 @@ Critères de validation :
 - la progression principale et optionnelle sont séparables ;
 - les besoins Phase 2 sont prêts à être transformés en contrats.

-### 🔜 P1-05 — Selbrume Reference Grammar Mapping
+### ✅ P1-05 — Selbrume Reference Grammar Mapping

 Objectif :
 Mapper le Golden Slice Selbrume “Lysa au port” sur la grammaire canonique.
@@ -308,7 +310,7 @@ Critères de validation :
 - les gaps de grammaire sont listés ;
 - les décisions à reporter en Phase 2 sont explicites.

-### P1-06 — No-code Workflow Specification
+### 🔜 P1-06 — No-code Workflow Specification

 Objectif :
 Décrire les workflows auteur minimaux sans UI finale :
@@ -396,12 +398,13 @@ Critères de validation :

 ## 10. Prochain lot exact

-P1-05 — Selbrume Reference Grammar Mapping
+P1-06 — No-code Workflow Specification

 Objectif du prochain lot :
-Mapper le Golden Slice Selbrume “Lysa au port” sur la grammaire canonique.
+Décrire les workflows auteur minimaux sans UI finale : créer Event, Scene,
+Fact, World Rule, battle ref, Yarn outcome et validator flow.

-P1-05 ne doit pas créer de code, de modèles `map_core`, d’UI, de fixtures
+P1-06 ne doit pas créer de code, de modèles `map_core`, d’UI, de fixtures
 Selbrume finales ou de `project.json`.

 ## 11. Critères de sortie de Phase 1
@@ -520,3 +523,16 @@ P1-CHECKPOINT-01 devra aussi mettre à jour
   Décisions utilisateur nouvelles : aucune.
   Changements de périmètre : aucun.
   Prochain lot exact fixé à P1-05 — Selbrume Reference Grammar Mapping.
+- 2026-05-24 — P1-05 — Selbrume Reference Grammar Mapping terminé.
+  Résultat : Golden Slice Selbrume “Lysa au port” mappé conceptuellement sur la
+  grammaire Phase 1, avec frontières Storyline / Chapter / Step,
+  Event / Scene / Cinematic, Yarn / Battle / Fact / World Rule / Validator
+  vérifiées, et gaps de grammaire séparés des gaps techniques.
+  Fichiers créés : `reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md`.
+  Fichiers modifiés : `MVP Selbrume/road_map_phase_1.md`.
+  Commandes exécutées : lectures Markdown ciblées, `find`, `rg`, `wc -l`,
+  `git status --short --untracked-files=all`, `git diff --check`,
+  `git diff --stat`, `git diff --name-only`, `git diff --no-index --check`.
+  Décisions utilisateur nouvelles : aucune.
+  Changements de périmètre : aucun.
+  Prochain lot exact fixé à P1-06 — No-code Workflow Specification.
```

### 26.13 Preuve road_map_global.md non modifiée

Commande : `git diff -- "MVP Selbrume/road_map_global.md"`

Sortie exacte vide.

```text
```

### 26.14 Preuve qu’aucun package code n’est modifié

Commande : `git diff --name-only -- packages examples/playable_runtime_host`

Sortie exacte vide.

```text
```

### 26.15 wc -l final

```text
    1051 reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md
     538 MVP Selbrume/road_map_phase_1.md
     638 MVP Selbrume/road_map_global.md
    2227 total
```

## 27. Auto-review critique

Le lot a-t-il modifié uniquement ce qui était autorisé ?

- Oui. Les seuls fichiers attendus sont le rapport P1-05 et la roadmap vivante
  de Phase 1.

Le rapport P1-05 existe-t-il au bon chemin ?

- Oui : `reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md`.

`road_map_phase_1.md` a-t-elle été mise à jour ?

- Oui. P1-05 est marqué terminé et P1-06 devient le prochain lot exact.

`road_map_global.md` est-elle restée intacte ?

- Oui. Elle a été lue pour contexte et n’a pas été modifiée.

Aucun code n’a-t-il été modifié ?

- Oui. Aucun fichier sous `packages/` ou `examples/playable_runtime_host/` n’a
  été modifié.

Aucun test/analyze Dart/Flutter n’a-t-il été lancé inutilement ?

- Oui. Aucun `dart test`, `flutter test`, `dart analyze` ou `flutter analyze`
  n’a été lancé.

P1-06 n’a-t-il pas été commencé ?

- Oui. P1-06 est seulement identifié comme prochain lot exact.

Selbrume est-il resté une référence conceptuelle seulement ?

- Oui. Aucun contenu final Selbrume n’a été créé.

Aucun contenu Selbrume final n’a-t-il été créé ?

- Oui. Aucune map, PNJ, Yarn, trainer, battle, fixture, asset ou project.json
  Selbrume n’a été créé.

La grammaire Phase 1 couvre-t-elle le Golden Slice ?

- Oui au niveau conceptuel. Le mapping montre que le flow Lysa au port peut être
  décrit avec Storyline, Chapter, Step, Event, Scene, Cinematic, Yarn, Battle,
  Fact, World Rule et Validator.

Les gaps sont-ils séparés entre grammaire, technique, gameplay et UI ?

- Oui. Les gaps de grammaire sont listés séparément des gaps techniques hors
  P1-05.

Quelles ambiguïtés restent à valider par l’utilisateur ?

- Politique de défaite, durabilité des outcomes Yarn, availability explicite,
  statut Reward, entry point de side quest et composition du passage marais /
  phare.

### Regard critique sur le prompt

Le prompt est très strict et utile pour éviter une dérive d’implémentation. Sa
principale ambiguïté tient au nom “Lysa au port” : certains documents Selbrume
présentent Lysa comme rival / figure de combat, tandis que d’autres formulations
de prompts parlent de “rival” plus génériquement. P1-05 résout cette ambiguïté
en gardant les noms comme références conceptuelles et en évitant toute création
de contenu final.

Autre point à valider plus tard : le prompt demande de mapper une side quest
“Aider Soline”, alors que les documents Selbrume existants peuvent employer
Soline surtout dans un rôle de passage / gate. Ce n’est pas bloquant pour P1-05,
car la side quest reste un exemple conceptuel de Storyline secondaire.
