# P1-01 — Canonical Narrative Product Model V1

## 1. Résumé exécutif

P1-01 définit le dictionnaire produit canonique du futur Narrative Studio. Le
lot ne crée aucun modèle technique, aucun code, aucune UI et aucun contenu
Selbrume. Il stabilise les mots avant les contrats.

Le modèle produit proposé repose sur dix concepts :

- Storyline
- Chapter
- Story Step
- Event
- Scene
- Cinematic
- Dialogue Yarn
- Fact
- World Rule
- Validator

Frontières stabilisées :

- Event = déclenche.
- Scene = orchestre.
- Cinematic = met en scène linéairement.
- Yarn = dialogue + outcomes.
- Fact = vérité lisible du monde.
- World Rule = projection passive du GameState.
- Battle = résout le combat.
- Validator = diagnostique.

Hors scope volontaire :

- aucun modèle `map_core` ;
- aucun contrat JSON ;
- aucune migration ;
- aucune UI ;
- aucun test ;
- aucune fixture Selbrume ;
- aucun `project.json`.

Prochain lot exact :

```text
P1-02 — Event / Scene / Cinematic Boundary Contract
```

## 2. Scope du lot

Inclus :

- définir les dix concepts canoniques du Narrative Studio ;
- proposer un vocabulaire no-code lisible par une personne non développeuse ;
- distinguer les concepts qui se recouvrent aujourd’hui dans l’existant ;
- mapper prudemment les concepts vers les preuves NS-GS ;
- utiliser Selbrume comme référence conceptuelle uniquement ;
- mettre à jour `MVP Selbrume/road_map_phase_1.md`.

Exclus :

- code de production ;
- tests ;
- analyse Dart/Flutter ;
- modification de `packages/` ;
- modification de `examples/playable_runtime_host/` ;
- modification de `MVP Selbrume/road_map_global.md` ;
- P1-02 ou autre lot suivant ;
- contenu Selbrume final.

Fichiers créés :

- `reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md`

Fichiers modifiés :

- `MVP Selbrume/road_map_phase_1.md`

Fichiers explicitement non modifiés :

- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map.md`
- `packages/map_core`
- `packages/map_gameplay`
- `packages/map_battle`
- `packages/map_runtime`
- `packages/map_editor`
- `examples/playable_runtime_host`

Confirmation :

```text
Aucun code modifié.
Aucun test lancé.
Aucun package modifié.
road_map_global.md lu mais non modifié.
Selbrume utilisé comme référence conceptuelle uniquement.
```

## 3. Sources lues

Roadmaps et cadrages de phase :

- `MVP Selbrume/road_map_global.md` — gouvernance globale par phases et règle
  de non-modification hors checkpoint.
- `MVP Selbrume/road_map_phase_1.md` — source vivante détaillée de la Phase 1.
- `reports/roadmap/pokemap_full_product_phased_roadmap_v1.md` — proposition
  stratégique longue et matrice des gaps.
- `reports/roadmap/roadmap_global_00_master_phase_roadmap_bootstrap.md` —
  rapport de création de la roadmap globale.
- `reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md` — rapport de
  création de la roadmap Phase 1.
- `MVP Selbrume/road_map.md` — roadmap historique NS-GS clôturée.

Documents produit :

- `MVP Selbrume/narrative_studio.md` — vision Narrative Studio et concepts
  Storyline / Chapter / Story Step / Event / Scene / Cinematic / Yarn / Fact /
  World Rule / Validator.
- `MVP Selbrume/selbrume.md` — scénario de référence Selbrume, utilisé comme
  banc d’essai conceptuel seulement.
- `AGENTS.md` — contraintes repo, package boundaries, Git safety et evidence.

Rapports NS-GS / audits utiles :

- `reports/gameplay/audit/narrative_studio_product_model_v0.md` — modèle
  mental “Quand / Si / Alors / Puis” et critique des flags bruts.
- `reports/gameplay/audit/sel_a2_event_scene_outcome_fact_contract.md` —
  contrat Event → Scene → Outcome → Fact.
- `reports/gameplay/audit/sel_b2_battle_from_scene.md` — pont Scene → battle.
- `reports/gameplay/ns_gs/ns_gs_08_npc_interaction_scene_authoring_readiness.md`
  — entity interaction → scene.
- `reports/gameplay/ns_gs/ns_gs_09_yarn_outcome_scene_branch_readiness.md` —
  Yarn outcome → branch.
- `reports/gameplay/ns_gs/ns_gs_10_world_rules_conditional_presence_readiness.md`
  — World Rules / présence / dialogue conditionnel.
- `reports/gameplay/ns_gs/ns_gs_11_trainer_battle_authoring_readiness.md` —
  Scene → trainer battle → continuation.
- `reports/gameplay/ns_gs/ns_gs_12_bis_evidence_pack_and_level_label_fix.md`
  — rappel Level 2 Application, Level 3/4 non prouvés.
- `reports/gameplay/ns_gs/ns_gs_13_narrative_validator_minimal_v0.md` —
  Narrative Validator V0.
- `reports/gameplay/ns_gs/ns_gs_14_item_pickup_give_item_authoring_readiness.md`
  — giveItem / item pickup.
- `reports/gameplay/ns_gs/ns_gs_15_key_item_door_gate_readiness.md` —
  gate via fact dérivé, pas `hasItem` direct.
- `reports/gameplay/ns_gs/ns_gs_16_side_quest_optional_storyline_readiness.md`
  — side quest pattern via facts/steps/scenes.
- `reports/gameplay/ns_gs/ns_gs_17_static_encounter_boss_battle_readiness.md`
  — boss trainer-like, static wild réel non prouvé.
- `reports/gameplay/ns_gs/ns_gs_18_reward_money_xp_bridge_audit.md` —
  rewards item post-battle prouvés via scène ; money/XP partiels ou absents.
- `reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md`
  — synthèse des niveaux de preuve.

## 4. Objectif produit du Narrative Studio

Le Narrative Studio est l’espace de composition narrative où l’utilisateur
organise :

- histoire principale ;
- chapitres ;
- étapes ;
- événements déclencheurs ;
- scènes ;
- dialogues ;
- cinématiques ;
- combats déclenchés par scènes ;
- faits persistants ;
- règles visibles du monde ;
- validation de cohérence.

Son rôle n’est pas de faire taper des IDs ou des flags. Son rôle est de rendre
lisible la logique d’un fangame court :

```text
Quand [déclencheur]
Si [conditions]
Alors [actions / scène / dialogue / combat / cinématique]
Puis [conséquences / faits / changements du monde]
```

Le créateur ne pense pas en flags techniques. Il pense en situations,
décisions, conséquences et progression. Les flags peuvent exister derrière,
mais ils doivent être une couche technique, jamais le langage principal du
produit.

## 5. Glossaire canonique

| Concept | Définition courte | Rôle produit | Ne doit pas être confondu avec | Exemple conceptuel |
|---|---|---|---|---|
| Storyline | Ligne narrative cohérente et suivable | Regrouper une histoire principale, quête ou arc optionnel | Quest Engine séparé obligatoire | “La brume du phare” |
| Chapter | Grande section d’une Storyline | Organiser la lecture, le filtrage et la validation | Map, acte runtime obligatoire | “Le port” |
| Story Step | Jalon clair de progression | Dire où en est le joueur | Scene, Cinematic, flag brut | “Parler à Lysa au port” |
| Event | Déclencheur contextualisé | Observer quand quelque chose doit démarrer | Scene complète | “Le joueur interagit avec un PNJ” |
| Scene | Orchestrateur narratif | Assembler dialogue, cinematic, battle, actions, facts | Cinematic linéaire | “Rencontre rival” |
| Cinematic | Séquence linéaire de mise en scène | Décrire caméra, déplacements, pauses, effets | Progression narrative | “Lysa avance vers le joueur” |
| Dialogue Yarn | Dialogue interactif avec choix/outcomes | Porter le texte et les choix | Moteur principal de progression | “Réponse confiante / hésitante” |
| Fact | Vérité persistante et lisible du monde | Mémoriser une conséquence compréhensible | Flag technique exposé | “Le rival a été battu au port” |
| World Rule | Projection passive de l’état vers le monde | Changer visibilité, dialogue ou disponibilité | Event actif | “Lysa change de dialogue si le rival est battu” |
| Validator | Diagnostic statique | Expliquer incohérences et références cassées | Executor ou auto-correcteur | “Cette scène référence un dialogue inconnu” |

## 6. Storyline

### Définition canonique

Une Storyline est une ligne narrative cohérente et suivable. Elle peut
représenter l’histoire principale, une quête annexe, un tutoriel, un épilogue ou
un arc optionnel.

### Rôle dans le produit

Elle donne au créateur un conteneur humain pour organiser ce qui arrive dans le
jeu. Elle répond à : “De quelle histoire parle-t-on ?”

### Ce que voit l’utilisateur

Une liste ou un graphe d’histoires : “Histoire principale”, “Quête du port”,
“Tutoriel combat”, “Épilogue”. Chaque Storyline peut afficher ses chapitres,
steps, scènes liées, facts produits et règles du monde concernées.

### Ce que le moteur pourra représenter plus tard

Phase 2 pourra décider si une Storyline devient un modèle `map_core`, un
registre de métadonnées autour des `ScenarioAsset`, ou un contrat intermédiaire.
P1-01 ne tranche pas la représentation technique.

### Entrées / sorties conceptuelles

Entrées :

- conditions de disponibilité ;
- Chapters ;
- Story Steps ;
- scènes et Events liés.

Sorties :

- progression visible ;
- facts de démarrage / résolution ;
- diagnostics de cohérence.

### Relations avec les autres concepts

Une Storyline contient des Chapters. Les Chapters contiennent des Story Steps.
Les Steps sont activés, complétés ou rendus visibles par des Events, Scenes,
Facts et World Rules.

### Ce que ce concept ne doit pas faire

- imposer un Quest Engine séparé dès P1 ;
- remplacer les Scenes ;
- stocker toute la logique d’exécution ;
- forcer toutes les histoires à être linéaires.

### Exemples conceptuels

- Histoire principale : “La brume du phare”.
- Quête annexe : “Aider un habitant du port”.
- Tutoriel : “Premier combat”.

### Impacts Phase 2

Phase 2 devra décider :

- si Storyline est un vrai modèle ;
- si une side quest est une Storyline typée `optional` ;
- comment Storyline référence Chapters, Steps, Scenes et Validator.

## 7. Chapter

### Définition canonique

Un Chapter est une grande section de progression dans une Storyline. Il sert à
organiser la lisibilité et la validation.

### Rôle dans le produit

Il aide le créateur à structurer une histoire sans transformer cette structure
en contrainte runtime rigide. Un Chapter est un outil de lecture, pas forcément
un état technique.

### Ce que voit l’utilisateur

Des sections comme “Départ”, “Port”, “Marais”, “Phare”. Le créateur peut
filtrer les Steps, Events, Scenes et World Rules par Chapter.

### Ce que le moteur pourra représenter plus tard

Phase 2 pourra décider si Chapter est obligatoire, optionnel, ou seulement une
métadonnée de classification.

### Entrées / sorties conceptuelles

Entrées :

- Storyline parent ;
- ordre ou regroupement de Story Steps ;
- état de complétion dérivé.

Sorties :

- vue organisée ;
- diagnostics “chapitre incomplet” ;
- filtres de navigation.

### Relations avec les autres concepts

Une Storyline peut contenir plusieurs Chapters. Un Chapter contient ou référence
des Story Steps. Les Scenes et Events peuvent être affichés dans un Chapter sans
être possédés exclusivement par lui.

### Ce que ce concept ne doit pas faire

- être nécessairement un changement de map ;
- être un cutscene ;
- décider seul de la progression ;
- devenir une obligation lourde pour les petites Storylines.

### Exemples conceptuels

- “Chapitre 1 — Le port”.
- “Chapitre 2 — Les marais”.
- “Épilogue”.

### Impacts Phase 2

Décision à prendre : Chapter obligatoire pour toute Storyline, ou optionnel avec
un Chapter implicite pour les petites quêtes.

## 8. Story Step

### Définition canonique

Un Story Step est une unité de progression claire et validable. Il décrit un
jalon attendu : ce que le joueur a fait, doit faire, ou a débloqué.

### Rôle dans le produit

Le Step donne au créateur une lecture de l’avancement sans exposer un flag brut.
Il répond à : “Où en est le joueur dans cette Storyline ?”

### Ce que voit l’utilisateur

Un libellé humain : “Parler à Lysa au port”, “Recevoir un starter”, “Battre le
rival”, “Ouvrir l’accès au phare”. Le statut peut être “non disponible”,
“actif”, “terminé”, “échoué” si le modèle futur le supporte.

### Ce que le moteur pourra représenter plus tard

Phase 2 pourra relier Story Step à `completedStepIds`, facts dérivés,
conditions d’activation, et diagnostics. Le Step ne doit pas être réduit à un
ID technique.

### Entrées / sorties conceptuelles

Entrées :

- prérequis ;
- Events attendus ;
- Scenes qui peuvent le compléter ;
- Facts lus.

Sorties :

- complétion ;
- Facts produits ;
- World Rules activées ;
- diagnostics.

### Relations avec les autres concepts

Les Story Steps vivent dans un Chapter. Des Events et Scenes peuvent les
compléter. Des World Rules peuvent lire leur état. Le Validator doit détecter
les Steps jamais complétés ou jamais lus quand cette information est fiable.

### Ce que ce concept ne doit pas faire

- jouer une Scene ;
- contenir une Cinematic ;
- remplacer un Fact ;
- devenir un simple flag opaque.

### Exemples conceptuels

- “Parler à Lysa au port”.
- “Recevoir la mission principale”.
- “Battre le rival”.

### Impacts Phase 2

Phase 2 devra décider :

- si les steps sont déclarés dans un registre ;
- comment ils se relient à `completedStepIds` ;
- comment ils sont validés statiquement.

## 9. Event

### Définition canonique

Un Event est un déclencheur. Il observe une situation : interaction PNJ,
entrée de zone, pression bouton, pickup, collision trigger, fin de combat,
retour de scène, entrée sur une map, ou autre source explicite.

### Rôle dans le produit

L’Event répond à :

```text
Quand ?
Où ?
Par qui ?
Sous quelles conditions ?
Quelle Scene ou action démarre ?
```

### Ce que voit l’utilisateur

Un déclencheur formulé en langage clair :

- “Quand le joueur parle à ce PNJ”.
- “Quand le joueur entre dans cette zone”.
- “Quand ce combat se termine”.
- “Quand cet objet est ramassé”.

### Ce que le moteur pourra représenter plus tard

Les preuves NS-GS montrent déjà `entityInteract`, `mapEnter`,
`triggerEnter`, `outcomeReceived` et autres sources scenario. Phase 2 devra
décider s’il faut un modèle Event canonique qui englobe ces sources sans
dupliquer `ScenarioAsset`.

### Entrées / sorties conceptuelles

Entrées :

- source de déclenchement ;
- conditions ;
- portée map / entité / zone ;
- priorité ou fallback si plusieurs Events matchent.

Sorties :

- Scene lancée ;
- action simple ;
- diagnostic si cible absente.

### Relations avec les autres concepts

Un Event déclenche une Scene. Il peut dépendre de Facts ou Story Steps. Il ne
projette pas l’état visible : c’est le rôle des World Rules.

### Ce que ce concept ne doit PAS faire

- contenir toute l’orchestration narrative ;
- décider des branches internes ;
- jouer une Cinematic directement comme moteur global ;
- remplacer les World Rules.

### Exemples conceptuels

- “Interaction avec un PNJ”.
- “Entrée dans une zone”.
- “Fin du combat trainer-like”.
- “Pickup d’un objet”.

### Impacts Phase 2

P1-02 devra approfondir la frontière Event / Scene / Cinematic. Phase 2 devra
ensuite proposer un contrat Event ou une convention d’adaptation depuis les
sources runtime existantes.

## 10. Scene

### Définition canonique

Une Scene est un orchestrateur narratif. Elle assemble actions, dialogues,
cinématiques, combats, outcomes et conséquences.

### Rôle dans le produit

Elle répond à : “Dans quel ordre les choses se passent-elles ?” Une Scene peut
brancher, attendre un dialogue, lancer une Cinematic, lancer un Battle, poser
des Facts et compléter des Story Steps.

### Ce que voit l’utilisateur

Un graphe ou une liste ordonnée de blocs :

- ouvrir un dialogue ;
- jouer une mise en scène ;
- lancer un combat ;
- selon victory/defeat, continuer vers une branche ;
- poser un fait du monde ;
- terminer une étape.

### Ce que le moteur pourra représenter plus tard

L’existant utilise `ScenarioAsset`, nodes, edges, conditions et actions. Phase 2
devra décider si “Scene” est un renommage produit de `ScenarioAsset`, un wrapper
autour de lui, ou un modèle séparé.

### Entrées / sorties conceptuelles

Entrées :

- Event source ;
- conditions ;
- parameters de dialogue / cinematic / battle ;
- Facts lus.

Sorties :

- Dialogue outcomes ;
- Battle outcomes ;
- Fact writes ;
- Step completion ;
- continuation ou fin.

### Relations avec les autres concepts

Une Scene est déclenchée par un Event. Elle orchestre Dialogue Yarn, Cinematic,
Battle et actions gameplay. Elle produit des Facts et peut compléter des Story
Steps. Elle ne doit pas décider de la projection passive du monde : les World
Rules lisent ensuite l’état.

### Ce que ce concept ne doit PAS faire

- être une simple Cinematic ;
- contenir des déclencheurs globaux implicites ;
- devenir un moteur de quêtes complet ;
- masquer les Facts dans des labels opaques.

### Exemples conceptuels

- “Rencontre rival”.
- “Don du starter”.
- “Résolution d’une quête optionnelle”.

### Impacts Phase 2

Phase 2 devra clarifier le contrat entre Scene, `ScenarioAsset`, actions
existantes (`giveItem`, `completeStep`, `startTrainerBattle`) et Validator.

## 11. Cinematic

### Définition canonique

Une Cinematic est une séquence linéaire de mise en scène. Elle décrit caméra,
déplacements, pauses, animations, regards, effets et transitions.

### Rôle dans le produit

Elle rend un moment narratif lisible et vivant. Elle ne décide pas de la
progression globale. Elle met en scène une décision déjà orchestrée par une
Scene.

### Ce que voit l’utilisateur

Un enchaînement de beats :

- déplacer caméra ;
- faire avancer un personnage ;
- pause ;
- regard vers un objet ;
- effet visuel ;
- retour au contrôle.

### Ce que le moteur pourra représenter plus tard

L’existant a déjà des cutscenes et un runtime de scripts/cutscenes. Phase 2 ne
doit pas transformer Cinematic en moteur principal de progression.

### Entrées / sorties conceptuelles

Entrées :

- paramètres de mise en scène ;
- personnages/entités ciblés ;
- durée / ordre / transitions.

Sorties :

- signal de fin ;
- éventuellement un outcome technique si nécessaire, mais pas la progression
  globale par défaut.

### Relations avec les autres concepts

Une Scene peut appeler une Cinematic. Une Cinematic peut être différente selon
un outcome Yarn, mais la décision de branche appartient à la Scene.

### Ce que ce concept ne doit PAS faire

- compléter toute la progression seule ;
- écrire directement tous les Facts ;
- contenir des conditions globales complexes ;
- remplacer une Scene.

### Exemples conceptuels

- “Lysa avance vers le joueur”.
- “La caméra montre le phare”.
- “Le rival quitte le port”.

### Impacts Phase 2

P1-02 devra verrouiller Scene ≠ Cinematic. Phase 2 devra décider si Cinematic
reste un asset existant, une metadata de Scene, ou un contrat plus explicite.

## 12. Dialogue Yarn

### Définition canonique

Dialogue Yarn est un dialogue interactif, avec texte, choix et outcomes. Il
porte la conversation, pas toute la progression du jeu.

### Rôle dans le produit

Il permet de dire, demander et choisir. Il peut produire un outcome que la Scene
interprète ensuite.

### Ce que voit l’utilisateur

Une conversation avec choix :

- “Répondre avec confiance”.
- “Hésiter”.
- “Provoquer”.

L’utilisateur doit voir ce que chaque choix produit comme outcome lisible.

### Ce que le moteur pourra représenter plus tard

L’existant sait déjà émettre un outcome et brancher via un flag
`scenario.outcome.*`. Phase 2 devra stabiliser la relation entre Yarn outcomes,
Facts et Scene branching.

### Entrées / sorties conceptuelles

Entrées :

- dialogue asset ;
- nœud de départ ;
- contexte de Scene.

Sorties :

- outcome ;
- choix mémorisé ;
- signal de fin de dialogue.

### Relations avec les autres concepts

Une Scene ouvre un Dialogue Yarn. Le Dialogue Yarn produit un outcome. La Scene
lit cet outcome et décide de la suite : Cinematic, Battle, Fact, Step, branche.

### Ce que ce concept ne doit PAS faire

- devenir le moteur principal de progression ;
- écrire directement toute la logique du monde ;
- remplacer les Story Steps ;
- exposer des flags techniques au créateur.

### Exemples conceptuels

- Dialogue de rival avec trois tons de réponse.
- Dialogue d’un mentor qui propose une mission.

### Impacts Phase 2

Phase 2 devra décider comment déclarer, nommer et valider les outcomes Yarn :
registry, convention, ou lien typé vers les Scenes.

## 13. Fact

### Définition canonique

Un Fact est une vérité persistante et lisible du monde. Il peut être stocké
techniquement comme flag, step, état trainer, état item ou autre donnée, mais
l’utilisateur ne doit pas le manipuler comme une chaîne technique brute.

### Rôle dans le produit

Le Fact mémorise une conséquence compréhensible :

- “Le rival a été battu au port.”
- “Le joueur a reçu la clé du phare.”
- “Maël a expliqué l’origine de la brume.”

### Ce que voit l’utilisateur

Une phrase ou un libellé métier, groupé par histoire, personnage, map ou
système. Le mode avancé pourra afficher l’ID technique, mais ce n’est pas le
langage principal.

### Ce que le moteur pourra représenter plus tard

Aujourd’hui, beaucoup de preuves passent par `storyFlags.activeFlags`. Phase 2
devra décider si un FactRegistry humain existe au-dessus des flags, et comment
il mappe vers les données persistantes.

### Entrées / sorties conceptuelles

Entrées :

- écriture depuis Scene ;
- résultat battle ;
- outcome dialogue ;
- pickup / item ;
- progression Step.

Sorties :

- conditions de Scene ;
- World Rules ;
- diagnostics ;
- disponibilité de Storyline / Step.

### Relations avec les autres concepts

Les Scenes écrivent des Facts. Les Events, Scenes et World Rules peuvent lire
des Facts. Les Story Steps peuvent produire ou dépendre de Facts.

### Ce que ce concept ne doit PAS faire

- être exposé comme un simple flag brut ;
- rester une chaîne libre sans registre ;
- remplacer la notion de Step ;
- devenir une variable fourre-tout.

### Exemples conceptuels

- “Le rival a été battu au port.”
- “La porte du phare est débloquée.”
- “L’objet optionnel a été ramassé.”

### Impacts Phase 2

Phase 2 devra probablement proposer un FactRegistry, ou au minimum une grammaire
de facts nommés et validables.

## 14. World Rule

### Définition canonique

Une World Rule est une projection passive du GameState / Facts vers le monde
visible. Elle ne déclenche pas une scène par elle-même.

### Rôle dans le produit

Elle répond à : “Comment le monde reflète-t-il ce qui s’est passé ?”

### Ce que voit l’utilisateur

Des règles en langage simple :

- “Si le rival est battu, Lysa change de dialogue.”
- “Si la clé est obtenue, la porte peut apparaître ouverte.”
- “Si une étape est terminée, ce PNJ disparaît.”

### Ce que le moteur pourra représenter plus tard

L’existant sait déjà évaluer des predicates de présence et dialogue
conditionnel. Phase 2 devra décider comment centraliser ou référencer ces règles
dans un registre produit.

### Entrées / sorties conceptuelles

Entrées :

- Facts ;
- Story Steps ;
- cutscenes completed ;
- chapitre completed si pertinent.

Sorties :

- visibilité ;
- dialogue ;
- interactabilité future ;
- état visuel ou proxy.

### Relations avec les autres concepts

Les World Rules lisent les Facts et Steps produits par les Scenes. Elles
modifient passivement ce que le joueur voit. Elles ne lancent pas Events et ne
jouent pas Scenes.

### Ce que ce concept ne doit PAS faire

- déclencher une Scene ;
- contenir des actions gameplay ;
- remplacer Event ;
- corriger automatiquement l’état.

### Exemples conceptuels

- “Objet ramassable caché après pickup.”
- “PNJ de quête visible après disponibilité.”
- “Dialogue post-combat changé après victory.”

### Impacts Phase 2

Phase 2 devra décider si WorldRuleRegistry existe, comment il référence maps /
entities / dialogues, et comment le Validator détecte les références cassées.

## 15. Validator

### Définition canonique

Le Validator est un système de diagnostic. Il explique les incohérences,
trous, références manquantes, branches impossibles, facts orphelins et steps
inatteignables quand ces diagnostics sont suffisamment fiables.

### Rôle dans le produit

Il protège le créateur no-code avant runtime. Il dit “ce projet risque de ne pas
fonctionner” avec un message actionnable.

### Ce que voit l’utilisateur

Des diagnostics classés :

- erreur bloquante ;
- avertissement ;
- chemin concerné ;
- référence manquante ;
- suggestion humaine non automatique.

### Ce que le moteur pourra représenter plus tard

NS-GS-13 a ajouté un validator narratif V0 pure Dart. Phase 2 pourra étendre ce
validator si les concepts deviennent des contrats ou registries.

### Entrées / sorties conceptuelles

Entrées :

- Storylines ;
- Chapters ;
- Steps ;
- Events ;
- Scenes ;
- Dialogues ;
- Trainers ;
- Facts ;
- World Rules.

Sorties :

- diagnostics ;
- sévérité ;
- localisation logique ;
- référence concernée.

### Relations avec les autres concepts

Le Validator ne déclenche rien. Il vérifie toute la chaîne. Il ne mute pas le
projet et ne corrige pas automatiquement.

### Ce que ce concept ne doit PAS faire

- exécuter un projet ;
- remplacer le runtime ;
- auto-corriger sans décision utilisateur ;
- masquer les limites Level 2 / Level 3 / Level 4.

### Exemples conceptuels

- “Cette Scene référence un dialogue inconnu.”
- “Ce Step est lu mais jamais complété.”
- “Cette World Rule cible une entité absente.”

### Impacts Phase 2

Phase 2 devra décider quels diagnostics deviennent fiables grâce aux nouveaux
contrats : Storyline refs, Event refs, Fact refs, WorldRule refs, Cinematic refs.

## 16. Relations entre concepts

Relations canoniques :

- Storyline contient Chapters.
- Chapter contient Story Steps.
- Story Step décrit une progression attendue.
- Event déclenche une Scene ou une action.
- Scene orchestre Dialogue / Cinematic / Battle / Facts / Step completion.
- Dialogue Yarn produit des outcomes.
- Cinematic met en scène sans décider seule de la progression.
- Battle résout le combat et retourne un outcome.
- Fact persiste une vérité.
- World Rule projette passivement les facts vers le monde.
- Validator diagnostique tout l’ensemble.

Diagramme texte :

```text
Storyline
  → Chapter
    → Story Step
      → Event
        → Scene
          → Dialogue Yarn
          → Cinematic
          → Battle
          → Fact writes
          → Step completion
            → World Rules
              → visible world changes

Validator
  → vérifie la cohérence de toute la chaîne
```

Relation critique :

```text
Event déclenche.
Scene orchestre.
Cinematic illustre.
Fact mémorise.
World Rule projette.
Validator diagnostique.
```

## 17. Cycle de vie narratif canonique

1. Le joueur agit dans le monde.
2. Un Event est déclenché.
3. Les conditions sont évaluées.
4. Une Scene est lancée.
5. La Scene orchestre dialogue / cinematic / battle / actions.
6. Les outcomes sont collectés.
7. Des Facts sont écrits.
8. Des Story Steps progressent.
9. Des World Rules changent l’état visible du monde.
10. Le Validator peut diagnostiquer la cohérence.

Ce cycle doit rester intelligible dans l’éditeur. Le créateur doit pouvoir
répondre aux questions suivantes :

- Qu’est-ce qui déclenche ?
- Quelles conditions sont requises ?
- Quelle Scene est jouée ?
- Quelles conséquences sont persistées ?
- Qu’est-ce qui change dans le monde ?
- Qu’est-ce qui est invalide ou incomplet ?

## 18. Mapping vers l’existant

| Domaine | Statut | Niveau de preuve | Mapping P1-01 | Limite |
|---|---:|---|---|---|
| New Game | ✅ prouvé | Level 1/2 | point de départ GameState | Pas modèle Storyline |
| GivePokemon | ✅ prouvé | Level 2 | action de Scene | Pas modèle cadeau complet |
| GiveItem | ✅ prouvé | Level 2 | action de Scene / reward simple | Pas Item Catalogue |
| Step completion | ✅ prouvé | Level 1/2 | Story Step completion | Pas registre Step canonique |
| NPC interaction → Scene | ✅ prouvé | Level 2 | Event entityInteract → Scene | Golden Slice Flame complet non prouvé |
| Yarn/outcome → branch | ✅ prouvé | Level 2 | Dialogue Yarn outcome lu par Scene | Outcome registry absent |
| World Rules | ✅ prouvé | Level 1/2 | World Rule présence/dialogue | Registry central absent |
| Trainer Battle | ✅ prouvé | Level 2 | Battle appelé par Scene | Level 3 complet non prouvé |
| Boss trainer-like battle | ✅ prouvé | Level 2 | Battle authorable trainer-like | Static wild réel non prouvé |
| Item pickup | ✅ prouvé | Level 2 | Event pickup → Scene → Fact | Bag UI / Item Studio absents |
| Key item / door gate | ⚠️ partiel | Level 2 | item → Fact dérivé → Gate Scene/World Rule | `hasItem` direct absent |
| Side quest / optional storyline | ✅ prouvé | Level 2 | Storyline optionnelle par facts/steps/scenes | Pas Quest Engine |
| Post-battle item reward via scène | ✅ prouvé | Level 2 | Scene continuation → giveItem | Pas Reward Model |
| Narrative Validator V0 | ✅ prouvé | Level 1 | Validator diagnostique | Pas intégré editor |
| Save/load | ✅ prouvé sur de nombreux flux | Level 1/2 | persistance Facts/Steps/Bag | Disk project narratif complet non prouvé |
| Golden Slice complet Flame | ⚠️ partiel | Level 3 non complet | future Phase 3 | Ne pas vendre comme prouvé |
| Projet disque créé dans l’éditeur | ❌ non prouvé | Level 4 absent | future Phase 3/6 | Aucun vrai projet auteur validé |
| Static wild encounter authorable | ⚠️ partiel | non prouvé par scène | future Phase 5 | startStatic/startWild absent côté scénario |
| Money reward | ⚠️ partiel | state only | future Phase 5 | pas de bridge reward |
| XP / level-up / learn move | ❌ absent | non prouvé | future Phase 5 | pas de XP persistent |
| UI no-code moderne | ❌ absent / futur | hors P1 | future Phase 7 | UI tardive |
| Validator intégré map_editor | ❌ absent | hors P1 | Phase 4/7 | pas de surface auteur |

Lecture stricte :

```text
Le bloc NS-GS prouve surtout des patterns Level 2 Application.
Il ne prouve pas le produit final no-code.
Il ne prouve pas un Golden Slice complet Flame.
Il ne prouve pas un vrai projet disque créé dans l’éditeur.
```

## 19. Mapping Selbrume Golden Slice

Ce mapping est illustratif. Aucun contenu Selbrume final n’est créé par P1-01.
Le Golden Slice réel est prévu plus tard, probablement en Phase 6.

Golden Slice recommandé :

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

Mapping conceptuel :

| Étape Selbrume illustrative | Concept P1-01 | Commentaire |
|---|---|---|
| “La brume du phare” | Storyline | Histoire principale conceptuelle. |
| “Le port” | Chapter | Section de progression. |
| “Parler à Lysa au port” | Story Step | Jalon lisible, pas une Scene. |
| Interaction avec Lysa | Event | Déclencheur externe. |
| “Rencontre rival” | Scene | Orchestration de dialogue, cinematic, battle, consequences. |
| Dialogue `rival_intro` | Dialogue Yarn | Texte + choix + outcomes. |
| Outcome confident / hesitant / aggressive | Dialogue Yarn outcome | La Scene lit l’outcome. |
| Mise en scène différente | Cinematic | Séquence linéaire choisie par la Scene. |
| Combat Rival | Battle | Résolution gameplay, pas progression narrative autonome. |
| Victory / defeat | Battle outcome | La Scene décide des conséquences. |
| “Le rival a été battu au port” | Fact | Vérité persistante lisible. |
| Step terminé | Story Step completion | Progression claire. |
| Lysa change de dialogue | World Rule | Projection passive. |
| Quête annexe disponible | Storyline optionnelle / Fact / World Rule | À préciser en P1-04. |
| Validation atteignable | Validator | Diagnostic statique. |

Rappel :

```text
Aucun `map_port_brisants`, aucun `npc_lysa`, aucun dialogue final,
aucun trainer final, aucun battle final et aucun `project.json` Selbrume
n’est créé par P1-01.
```

## 20. Vocabulaire utilisateur recommandé

| Concept canonique | Libellé UI recommandé | Remarque |
|---|---|---|
| Storyline | Histoire / Quête | “Histoire” pour main story, “Quête” pour optionnel. |
| Chapter | Chapitre | Terme simple, connu. |
| Story Step | Étape | Éviter “step id”. |
| Event | Déclencheur | Plus clair qu’Event pour non-développeur. |
| Scene | Scène | Terme central à garder. |
| Cinematic | Mise en scène | Plus humain que “cutscene” si besoin. |
| Dialogue Yarn | Dialogue | Yarn peut rester en mode technique. |
| Fact | Fait du monde | Remplace “flag” en UX simple. |
| World Rule | Règle du monde | Projection visible du monde. |
| Validator | Vérificateur / Diagnostic | “Diagnostic” pour la surface de résultats. |

Termes à éviter dans l’UX simple :

- flag ;
- node id ;
- script binding ;
- runtime resolver ;
- predicate ;
- mutation ;
- `ScenarioAsset.metadata`.

Ces termes peuvent exister en mode avancé, debug ou documentation technique,
mais pas dans le flux normal no-code.

## 21. Anti-patterns interdits

- Event qui contient toute une scène.
- Scene utilisée comme simple cinematic.
- Cinematic qui écrit directement toute la progression.
- Yarn qui devient le moteur principal de progression.
- Facts exposés comme flags techniques.
- World Rule utilisée comme déclencheur actif.
- Battle qui décide seule de la progression narrative.
- Side quest implémentée comme système totalement séparé dès le départ.
- Validator qui corrige automatiquement sans décision utilisateur.
- UI premium commencée avant stabilisation modèle/runtime.
- Selbrume final généré trop tôt.
- Chapter utilisé comme état runtime obligatoire.
- Story Step utilisé comme script.
- Reward Model lancé dans Phase 1.

## 22. Impacts attendus pour Phase 2

P1-01 prépare Phase 2, mais ne l’exécute pas.

Phase 2 devra probablement transformer ces concepts en :

- contrats domaine ;
- modèles `map_core` ;
- contrats JSON ;
- diagnostics ;
- règles de validation ;
- migrations éventuelles ;
- frontières runtime/application ;
- relations avec GameState ;
- relations avec scènes/dialogues/battles.

Sujets à traiter en Phase 2 ou à reporter explicitement :

- Storyline model ;
- Chapter model ;
- Story Step registry ;
- Event contract ;
- Scene / `ScenarioAsset` relation ;
- Cinematic metadata ;
- FactRegistry ;
- WorldRuleRegistry ;
- Dialogue outcome registry ;
- Validator diagnostics supplémentaires.

Garde-fou :

```text
Phase 2 ne doit pas créer un modèle lourd simplement parce que le vocabulaire
existe. Chaque modèle devra justifier son utilité, ses consumers et ses tests.
```

## 23. Mise à jour de road_map_phase_1.md

Mise à jour prévue dans `MVP Selbrume/road_map_phase_1.md` :

```text
P1-01 : ✅ terminé
P1-02 : 🔜 prochain lot exact
```

La roadmap Phase 1 doit aussi indiquer :

- résumé court du résultat P1-01 ;
- fichiers créés / modifiés ;
- commandes exécutées ;
- décisions utilisateur nouvelles : aucune ;
- changements de périmètre : aucun ;
- prochain lot exact : P1-02 — Event / Scene / Cinematic Boundary Contract.

`MVP Selbrume/road_map_global.md` reste lu mais non modifié.

## 24. Décisions à valider par l’utilisateur

Décisions non bloquantes à valider :

- Faut-il traduire “Storyline” par “Histoire”, “Quête” ou garder “Storyline” dans
  l’UI ?
- Une quête annexe est-elle une Storyline avec type optionnel, ou faut-il un
  modèle séparé plus tard ?
- Un Chapter est-il obligatoire, optionnel, ou implicite pour les petites
  Storylines ?
- Le terme “Fact” doit-il être exposé comme “Fait du monde” partout dans l’UI ?
- Le Validator doit-il s’appeler “Vérificateur”, “Diagnostic” ou “Contrôle du
  projet” côté utilisateur ?
- Les outcomes Yarn doivent-ils être visibles comme “résultats de dialogue” ou
  comme faits produits ?

Aucune de ces décisions ne bloque P1-02. Elles orientent surtout les termes UI
et les contrats Phase 2.

## 25. Evidence Pack

### 25.1 git status initial

```text

```

### 25.2 Fichiers lus

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
```

### 25.3 Fichiers créés

```text
reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
```

### 25.4 Fichiers modifiés

```text
MVP Selbrume/road_map_phase_1.md
```

### 25.5 Commandes exécutées

```bash
git status --short --untracked-files=all
find reports -maxdepth 4 -type f | sort
find "MVP Selbrume" -maxdepth 2 -type f | sort
sed -n '1,260p' "MVP Selbrume/road_map_global.md"
sed -n '261,700p' "MVP Selbrume/road_map_global.md"
sed -n '1,520p' "MVP Selbrume/road_map_phase_1.md"
sed -n '1,260p' reports/roadmap/pokemap_full_product_phased_roadmap_v1.md
sed -n '261,760p' reports/roadmap/pokemap_full_product_phased_roadmap_v1.md
sed -n '1,260p' reports/roadmap/roadmap_global_00_master_phase_roadmap_bootstrap.md
sed -n '1,220p' reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md
sed -n '1,260p' "MVP Selbrume/road_map.md"
sed -n '1,220p' "MVP Selbrume/narrative_studio.md"
sed -n '1,180p' "MVP Selbrume/selbrume.md"
sed -n '1,220p' AGENTS.md
sed -n '1,260p' reports/gameplay/audit/narrative_studio_product_model_v0.md
sed -n '1,260p' reports/gameplay/audit/sel_a2_event_scene_outcome_fact_contract.md
sed -n '1,220p' reports/gameplay/audit/sel_b2_battle_from_scene.md
sed -n '1,220p' reports/gameplay/ns_gs/ns_gs_08_npc_interaction_scene_authoring_readiness.md
sed -n '1,220p' reports/gameplay/ns_gs/ns_gs_09_yarn_outcome_scene_branch_readiness.md
sed -n '1,220p' reports/gameplay/ns_gs/ns_gs_10_world_rules_conditional_presence_readiness.md
sed -n '1,220p' reports/gameplay/ns_gs/ns_gs_11_trainer_battle_authoring_readiness.md
sed -n '1,220p' reports/gameplay/ns_gs/ns_gs_12_bis_evidence_pack_and_level_label_fix.md
sed -n '1,220p' reports/gameplay/ns_gs/ns_gs_13_narrative_validator_minimal_v0.md
sed -n '1,220p' reports/gameplay/ns_gs/ns_gs_14_item_pickup_give_item_authoring_readiness.md
sed -n '1,220p' reports/gameplay/ns_gs/ns_gs_15_key_item_door_gate_readiness.md
sed -n '1,220p' reports/gameplay/ns_gs/ns_gs_16_side_quest_optional_storyline_readiness.md
sed -n '1,220p' reports/gameplay/ns_gs/ns_gs_17_static_encounter_boss_battle_readiness.md
sed -n '1,260p' reports/gameplay/ns_gs/ns_gs_18_reward_money_xp_bridge_audit.md
sed -n '1,260p' reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md
perl -pi -e 's/[ \t]+$//' reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

### 25.6 git diff --check

```text

```

### 25.7 git diff --stat

```text
 MVP Selbrume/road_map_phase_1.md | 33 ++++++++++++++++++++++-----------
 1 file changed, 22 insertions(+), 11 deletions(-)
```

### 25.8 git diff --name-only

```text
MVP Selbrume/road_map_phase_1.md
```

### 25.9 git status final

```text
 M "MVP Selbrume/road_map_phase_1.md"
?? reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
```

### 25.10 Tests / analyze

```text
Non exécutés — P1-01 est documentaire et ne modifie aucun code.
```

### 25.11 Preuve Markdown créée / modifiée

Le présent fichier est le rapport P1-01 complet créé à :

```text
reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
```

Contrôle whitespace du rapport untracked créé :

```bash
git diff --no-index --check /dev/null reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md || true
```

Sortie exacte :

```text

```

Line counts après création :

```text
    1479 reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
     478 MVP Selbrume/road_map_phase_1.md
     638 MVP Selbrume/road_map_global.md
    2595 total
```

Preuve que `MVP Selbrume/road_map_global.md` n’est pas modifiée :

```bash
git diff -- "MVP Selbrume/road_map_global.md"
```

Sortie exacte :

```text

```

Hunks complets de `MVP Selbrume/road_map_phase_1.md` :

```diff
diff --git a/MVP Selbrume/road_map_phase_1.md b/MVP Selbrume/road_map_phase_1.md
index 14f66eef..49bb2d00 100644
--- a/MVP Selbrume/road_map_phase_1.md
+++ b/MVP Selbrume/road_map_phase_1.md
@@ -6,15 +6,15 @@ Phase 1 — Canonical Product Model / Narrative Studio Foundations

 Statut : 🔜 En préparation

-Lot courant : P1-00 — Phase 1 Roadmap Bootstrap
+Lot courant : P1-01 — Canonical Narrative Product Model V1

-Prochain lot exact après P1-00 : P1-01 — Canonical Narrative Product Model V1
+Prochain lot exact après P1-01 : P1-02 — Event / Scene / Cinematic Boundary Contract

 Suivi des lots :

 - ✅ P1-00 — Phase 1 Roadmap Bootstrap
-- 🔜 P1-01 — Canonical Narrative Product Model V1
-- P1-02 — Event / Scene / Cinematic Boundary Contract
+- ✅ P1-01 — Canonical Narrative Product Model V1
+- 🔜 P1-02 — Event / Scene / Cinematic Boundary Contract
 - P1-03 — Fact & World Rule Product Grammar
 - P1-04 — Storyline / Chapter / Story Step Structure
 - P1-05 — Selbrume Reference Grammar Mapping
@@ -24,7 +24,9 @@ Suivi des lots :

 P1-00 : ✅ terminé

-P1-01 : 🔜 prochain lot exact
+P1-01 : ✅ terminé
+
+P1-02 : 🔜 prochain lot exact

 ## 2. Objectif de la Phase 1

@@ -160,7 +162,7 @@ Critères de validation :
 - la règle permanente de maintenance est inscrite ;
 - l’Evidence Pack P1-00 est complet.

-### 🔜 P1-01 — Canonical Narrative Product Model V1
+### ✅ P1-01 — Canonical Narrative Product Model V1

 Objectif :
 Définir Storyline, Chapter, Story Step, Event, Scene, Cinematic,
@@ -189,7 +191,7 @@ Critères de validation :
 - le vocabulaire reste no-code et créateur-friendly ;
 - les impacts Phase 2 sont listés sans implémentation.

-### P1-02 — Event / Scene / Cinematic Boundary Contract
+### 🔜 P1-02 — Event / Scene / Cinematic Boundary Contract

 Objectif :
 Figer les frontières Event déclenche / Scene orchestre / Cinematic linéaire.
@@ -388,13 +390,12 @@ Critères de validation :

 ## 10. Prochain lot exact

-P1-01 — Canonical Narrative Product Model V1
+P1-02 — Event / Scene / Cinematic Boundary Contract

 Objectif du prochain lot :
-Définir Storyline, Chapter, Story Step, Event, Scene, Cinematic,
-Dialogue Yarn, Fact, World Rule et Validator.
+Figer les frontières Event déclenche / Scene orchestre / Cinematic linéaire.

-P1-01 ne doit pas créer de code, de modèles `map_core`, d’UI, de fixtures
+P1-02 ne doit pas créer de code, de modèles `map_core`, d’UI, de fixtures
 Selbrume finales ou de `project.json`.

 ## 11. Critères de sortie de Phase 1
@@ -465,3 +466,13 @@ P1-CHECKPOINT-01 devra aussi mettre à jour

 - 2026-05-24 — P1-00 — Roadmap Phase 1 créée. P1-00 marqué terminé. Prochain
   lot exact fixé à P1-01 — Canonical Narrative Product Model V1.
+- 2026-05-24 — P1-01 — Canonical Narrative Product Model V1 terminé.
+  Résultat : définition canonique produit de Storyline, Chapter, Story Step,
+  Event, Scene, Cinematic, Dialogue Yarn, Fact, World Rule et Validator.
+  Fichiers créés : `reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md`.
+  Fichiers modifiés : `MVP Selbrume/road_map_phase_1.md`.
+  Commandes exécutées : lectures Markdown ciblées, `find`, `git status --short --untracked-files=all`,
+  `git diff --check`, `git diff --stat`, `git diff --name-only`.
+  Décisions utilisateur nouvelles : aucune.
+  Changements de périmètre : aucun.
+  Prochain lot exact fixé à P1-02 — Event / Scene / Cinematic Boundary Contract.
```

## 26. Auto-review critique

Le lot a-t-il modifié uniquement ce qui était autorisé ?

```text
Oui : un rapport P1-01 créé et road_map_phase_1.md mise à jour.
```

Le rapport P1-01 existe-t-il au bon chemin ?

```text
Oui : reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md.
```

road_map_phase_1.md a-t-elle été mise à jour ?

```text
Oui, P1-01 doit y être marqué terminé et P1-02 prochain lot exact.
```

road_map_global.md est-elle restée intacte ?

```text
Oui : `git diff -- "MVP Selbrume/road_map_global.md"` retourne une sortie vide.
```

Aucun code n’a-t-il été modifié ?

```text
Oui : `git diff --name-only` ne liste que `MVP Selbrume/road_map_phase_1.md`.
Le rapport P1-01 apparaît en untracked, hors packages/examples.
```

Aucun test/analyze Dart/Flutter n’a-t-il été lancé inutilement ?

```text
Oui : aucun test/analyze Dart/Flutter lancé.
```

P1-02 n’a-t-il pas été commencé ?

```text
Oui : P1-02 est seulement désigné comme prochain lot.
```

Selbrume est-il resté une référence conceptuelle seulement ?

```text
Oui : aucun contenu Selbrume final ni project.json créé.
```

Les concepts sont-ils assez strictement distingués ?

```text
Oui pour P1-01. P1-02 devra approfondir Event / Scene / Cinematic.
```

Ambiguïtés restantes à valider :

- traduction finale de Storyline ;
- statut optionnel ou obligatoire des Chapters ;
- side quest comme Storyline typée ou modèle séparé ;
- exposition UI du terme Fact ;
- nom UI du Validator.

### Regard critique sur le prompt

Le prompt est cohérent et très utile pour empêcher la dérive vers le code. La
seule tension est documentaire : il demande un rapport long et un Evidence Pack
complet avec preuves exploitables. Pour éviter un rapport illisible, P1-01
fournit le contenu complet du rapport comme artefact principal et les hunks
complets de la roadmap modifiée dans l’Evidence Pack final.
