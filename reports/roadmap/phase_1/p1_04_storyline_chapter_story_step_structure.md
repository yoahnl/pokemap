# P1-04 — Storyline / Chapter / Story Step Structure

## 1. Résumé exécutif

P1-04 définit la structure narrative produit du futur Narrative Studio :

```text
Storyline = une ligne narrative.
Chapter = une section de cette ligne.
Story Step = un jalon de progression.
```

La structure proposée est volontairement simple :

- une Storyline représente une ligne narrative cohérente : histoire principale,
  quête annexe, tutoriel, arc optionnel ou épilogue ;
- un Chapter organise une Storyline en sections lisibles, sans devenir un état
  runtime obligatoire ;
- un Story Step décrit un jalon concret, validable et compréhensible, sans
  devenir une Scene ni un flag technique brut ;
- une side quest est une Storyline secondaire en V0, pas un Quest Engine séparé
  obligatoire ;
- Event déclenche les Scenes qui font avancer des Steps ;
- Scene orchestre, écrit des Facts et complète des Steps ;
- Facts peuvent refléter ou expliquer la progression ;
- World Rules projettent la progression dans le monde visible ;
- Validator diagnostique les trous, références cassées et steps inatteignables.

Le lot ne crée aucun code, aucun modèle `map_core`, aucun `QuestEngine`, aucun
`QuestJournal`, aucune save data et aucun contenu Selbrume final.

Prochain lot exact après P1-04 :

```text
P1-05 — Selbrume Reference Grammar Mapping
```

## 2. Scope du lot

Inclus :

- définition produit de Storyline ;
- définition produit de Chapter ;
- définition produit de Story Step ;
- positionnement des side quests ;
- clarification des relations avec Event, Scene, Fact, World Rule, Dialogue
  Yarn, Battle et Validator ;
- mapping prudent vers l’existant NS-GS et les documents Narrative Studio ;
- mapping Selbrume illustratif sans création de contenu ;
- mise à jour de `MVP Selbrume/road_map_phase_1.md`.

Exclus :

- aucun code modifié ;
- aucun test lancé ;
- aucun package modifié ;
- aucun modèle Storyline / Chapter / Story Step créé ;
- aucun `QuestEngine` créé ;
- aucun `QuestJournal` créé ;
- aucune save data modifiée ;
- aucun contrat JSON ;
- aucun `build_runner` ;
- aucune UI ;
- `MVP Selbrume/road_map_global.md` lu, mais non modifié ;
- Selbrume utilisé comme référence conceptuelle uniquement.

Fichiers créés :

- `reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md`

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

## 3. Sources lues

Sources de gouvernance :

| Fichier | Rôle dans P1-04 |
|---|---|
| `AGENTS.md` | Règles repo, no-code first, Git safety, evidence et limites de package. |
| `MVP Selbrume/road_map_global.md` | Gouvernance globale par phases ; lu pour contexte, non modifié. |
| `MVP Selbrume/road_map_phase_1.md` | Roadmap vivante Phase 1 ; P1-04 prochain lot exact au départ. |
| `reports/roadmap/pokemap_full_product_phased_roadmap_v1.md` | Roadmap stratégique : Phase 1 avant modèles et UI. |
| `reports/roadmap/roadmap_global_00_master_phase_roadmap_bootstrap.md` | Règle de non-modification de la roadmap globale hors checkpoint. |
| `reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md` | Cadre de maintenance de Phase 1. |
| `reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md` | Définitions initiales Storyline / Chapter / Story Step. |
| `reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md` | Contrat Event / Scene / Cinematic et place des Steps dans Scene. |
| `reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md` | Frontière Step / Fact et World Rule passive. |
| `MVP Selbrume/road_map.md` | Roadmap NS-GS historique, conservée comme contexte. |
| `MVP Selbrume/narrative_studio.md` | Vision Narrative Studio : Storylines multiples, Chapters, Steps, side quests. |
| `MVP Selbrume/selbrume.md` | Scénario de référence, utilisé uniquement comme exemple conceptuel. |

Sources NS-GS et audits :

| Fichier | Rôle dans P1-04 |
|---|---|
| `reports/gameplay/audit/narrative_studio_product_model_v0.md` | Critique du Global Story linéaire et des flags, modèle Story Step. |
| `reports/gameplay/audit/sel_a2_event_scene_outcome_fact_contract.md` | Pipeline Event → Scene → Outcome → Fact → Step → World Rule. |
| `reports/gameplay/ns_gs/ns_gs_08_npc_interaction_scene_authoring_readiness.md` | Event entityInteract → Scene au niveau application. |
| `reports/gameplay/ns_gs/ns_gs_09_yarn_outcome_scene_branch_readiness.md` | Outcome Yarn technique → branch Scene → action/step/fact. |
| `reports/gameplay/ns_gs/ns_gs_10_world_rules_conditional_presence_readiness.md` | World Rules lisent storyFlags, steps, chapters, cutscenes. |
| `reports/gameplay/ns_gs/ns_gs_12_bis_evidence_pack_and_level_label_fix.md` | Rappel : Golden Slice prouvé Level 2 Application, pas Flame/disk complet. |
| `reports/gameplay/ns_gs/ns_gs_13_narrative_validator_minimal_v0.md` | Diagnostics actuels flags/steps/scenarios, sans modèle Storyline complet. |
| `reports/gameplay/ns_gs/ns_gs_16_side_quest_optional_storyline_readiness.md` | Side quest prouvée via facts/steps/scenes sans Quest Engine. |
| `reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md` | Synthèse des preuves NS-GS et gaps Level 3/4. |

## 4. Rappel P1-01 / P1-02 / P1-03

P1-01 :

```text
Storyline = ligne narrative.
Chapter = section de progression.
Story Step = jalon validable.
Fact = vérité lisible du monde.
World Rule = projection passive du GameState.
Validator = diagnostique.
```

P1-02 :

```text
Event déclenche.
Scene orchestre.
Cinematic met en scène.
```

P1-03 :

```text
Fact nomme une vérité.
World Rule projette passivement.
Scene écrit les conséquences durables.
World Rule ne déclenche pas de Scene.
Fact ne doit pas être exposé comme flag technique.
```

P1-04 ne redéfinit pas ces contrats. Il durcit uniquement Storyline / Chapter /
Story Step et positionne les side quests sans créer de Quest Engine.

## 5. Problème à résoudre

Sans structure narrative claire, les mécaniques prouvées par NS-GS peuvent
redevenir une collection de flags, de scenes et de conventions implicites.

Problèmes à couvrir :

- sans Storyline, les Steps deviennent une liste plate ;
- sans Chapter, les longues histoires deviennent illisibles ;
- sans Story Step clair, la progression redevient un tas de flags ;
- sans positionnement des side quests, on risque de créer un Quest Engine
  prématuré ;
- si Chapter devient un état runtime obligatoire, la structure devient trop
  rigide ;
- si Step devient une Scene, progression et orchestration se mélangent ;
- si Step devient un simple flag, le créateur ne comprend plus la progression ;
- si Storyline devient un script géant, le Narrative Studio perd sa lisibilité.

Formulation produit :

```text
Le créateur ne doit pas penser :
completedStepIds contains "rival_port_done".

Il doit penser :
Dans l’histoire “La brume du phare”,
l’étape “Battre le rival au port” est terminée.
```

## 6. Principe de structure narrative

Règle simple :

```text
Storyline = de quelle histoire parle-t-on ?
Chapter = dans quelle section de cette histoire sommes-nous ?
Story Step = quel jalon concret fait avancer cette histoire ?
```

Conséquences :

- Storyline organise une ligne narrative ;
- Chapter groupe des Steps pour lecture, filtrage et validation ;
- Story Step décrit une progression attendue ;
- Event déclenche une Scene qui peut faire progresser un Step ;
- Scene écrit des Facts et complète des Steps ;
- Facts peuvent refléter ou expliquer la progression ;
- World Rules projettent cette progression dans le monde ;
- Validator diagnostique les trous, références et chemins impossibles.

Diagramme conceptuel :

```text
Storyline
  → Chapter
    → Story Step
      ← Event déclenche une Scene liée
      ← Scene orchestre et complète le Step
      → Fact produit ou dérivé
      → World Rule projette le changement visible

Validator
  → vérifie que la chaîne est cohérente et atteignable
```

## 7. Storyline — définition canonique

### Définition

Une Storyline est une ligne narrative cohérente et suivable. Elle regroupe un
ensemble de Chapters, Steps, Events, Scenes, Facts et World Rules autour d’un
même fil d’histoire.

### Rôle utilisateur

Elle répond à :

```text
De quelle histoire parle-t-on ?
```

Exemples :

- histoire principale ;
- quête annexe ;
- tutoriel ;
- épilogue ;
- arc optionnel ;
- mini-objectif narratif.

### Données conceptuelles minimales

P1-04 ne crée pas de modèle, mais le produit aura probablement besoin de ces
notions en Phase 2 :

| Notion conceptuelle | Rôle |
|---|---|
| Identifiant futur éventuel | Référence stable pour runtime, validator et migrations. |
| Nom utilisateur | Label lisible : “La brume du phare”. |
| Description | Résumé de l’histoire. |
| Type | `main`, `sideQuest`, `tutorial`, `optionalArc`, `epilogue`. |
| Chapters | Sections de progression, optionnelles selon le type. |
| Entry conditions | Conditions de disponibilité. |
| Completion conditions | Conditions de clôture. |
| Related facts | Facts de disponibilité, démarrage, résolution. |
| Related world rules | Projections visibles liées à cette Storyline. |
| Related scenes | Scenes qui font progresser ou résoudre la Storyline. |
| Notes auteur | Intention, pacing, commentaire de design. |

Ces notions restent documentaires. Elles ne constituent pas un schéma JSON.

### Entrées / sorties

Entrées possibles :

- Facts prérequis ;
- Steps d’autres Storylines ;
- Events de map ;
- choix Yarn durable ;
- outcomes Battle ;
- disponibilité future d’une zone, item ou NPC.

Sorties possibles :

- Steps disponibles ou terminés ;
- Facts de progression ;
- World Rules ;
- disponibilité d’une autre Storyline ;
- diagnostics Validator ;
- récompense future si un modèle reward existe plus tard.

### Relations

Une Storyline :

- contient ou référence des Chapters ;
- contient ou référence des Story Steps ;
- s’appuie sur des Events et Scenes ;
- produit ou lit des Facts ;
- est visible ou reflétée par des World Rules ;
- doit pouvoir être diagnostiquée par Validator.

### Ce qu’une Storyline peut représenter

Elle peut représenter :

- une histoire principale ;
- une side quest ;
- un tutoriel ;
- un arc optionnel ;
- un épilogue ;
- un événement caché ;
- une mini-chaîne narrative sans imposer un système de quête séparé.

### Ce qu’une Storyline ne doit pas représenter

Elle ne doit pas être :

- un Quest Engine complet ;
- un Quest Journal ;
- un gros script runtime ;
- une Scene ;
- un Chapter ;
- une liste plate de flags ;
- une structure qui force toutes les histoires à être linéaires.

### Diagnostics Validator possibles

Diagnostics futurs :

- Storyline sans début ;
- Storyline sans fin ;
- Storyline sans Step ;
- Storyline sideQuest sans condition de disponibilité si elle est censée être
  débloquée ;
- Storyline terminable uniquement par une Scene absente ;
- Storyline dont tous les Steps sont inatteignables ;
- Storyline qui dépend d’un Fact jamais écrit.

### Impacts Phase 2

Phase 2 devra décider :

- si Storyline devient un modèle `map_core` ;
- si Storyline est un wrapper autour de `ScenarioAsset(scope: globalStory)` ;
- si le type `sideQuest` est un champ ou un registre séparé ;
- comment relier Storyline aux Scenes existantes sans casser les projets.

## 8. Storyline — types et statuts conceptuels

### Types conceptuels possibles

| Type | Sens | Notes |
|---|---|---|
| `mainStory` | Histoire principale du jeu. | Généralement une seule, mais ne pas coder cette règle trop tôt. |
| `sideQuest` | Storyline secondaire optionnelle. | Recommandé en V0 plutôt qu’un Quest Engine séparé. |
| `tutorial` | Ligne d’apprentissage : combat, bag, capture future. | Peut être courte et sans Chapter explicite. |
| `optionalArc` | Arc narratif optionnel plus large. | Peut contenir plusieurs Chapters. |
| `epilogue` | Suite post-résolution. | Peut dépendre de la mainStory terminée. |
| `systemGuide` | Guide de système si pertinent. | À valider plus tard, pas central en P1-04. |

### Statuts conceptuels possibles

| Statut | Sens | Décision P1-04 |
|---|---|---|
| `locked` / non disponible | Le joueur ne peut pas encore la démarrer. | Concept utile, non implémenté. |
| `available` / disponible | Le joueur peut la découvrir ou la démarrer. | Concept utile, peut être projeté par World Rule. |
| `active` / en cours | La Storyline a démarré. | Concept utile, à formaliser plus tard. |
| `completed` / terminée | La Storyline est résolue. | Concept central, non implémenté ici. |
| `failed` / échouée | Fin d’échec possible. | À valider avant modèle. |
| `hidden` / masquée | Invisible tant qu’un prérequis manque. | Peut être un choix UI, pas forcément runtime. |

Ces statuts sont conceptuels. P1-04 ne crée ni modèle ni save data.

Décision produit recommandée :

```text
Une side quest peut être une Storyline typée sideQuest.
Elle ne nécessite pas un moteur séparé par défaut.
```

## 9. Chapter — définition canonique

### Définition

Un Chapter est une grande section de progression dans une Storyline. Il organise
des Story Steps autour d’un moment narratif cohérent.

### Rôle utilisateur

Il répond à :

```text
Dans quelle section de cette histoire sommes-nous ?
```

Exemples :

- “Le port” ;
- “Les marais” ;
- “Le phare” ;
- “Épilogue”.

### Données conceptuelles minimales

P1-04 ne crée pas de modèle, mais Phase 2 pourra discuter :

| Notion conceptuelle | Rôle |
|---|---|
| Identifiant futur éventuel | Référence stable si Chapter devient validable. |
| Nom utilisateur | Label lisible : “Chapitre 1 — Le port”. |
| Description | Résumé de la section. |
| Ordre dans la Storyline | Aide au tri, pas forcément contrainte runtime. |
| Steps | Jalon(s) regroupés dans ce Chapter. |
| Availability summary | Résumé humain des conditions d’entrée. |
| Completion summary | Résumé humain de clôture. |
| Notes auteur | Intention, pacing, ambiance. |

Ces notions ne sont pas un schéma JSON.

### Entrées / sorties

Entrées :

- Storyline parent ;
- ordre auteur ;
- Steps associés ;
- Facts ou Steps prérequis conceptuels.

Sorties :

- vue organisée ;
- filtrage UI ;
- diagnostics de Chapter vide ou incomplet ;
- Chapter status dérivé éventuel.

### Relations

Un Chapter :

- appartient à une Storyline ;
- regroupe des Story Steps ;
- peut aider à filtrer Scenes, Events, Facts et World Rules ;
- peut être évalué comme completed si tous ses Steps requis sont terminés, mais
  cette règle reste à formaliser en Phase 2.

### Ce qu’un Chapter peut représenter

Il peut représenter :

- un arc local ;
- une section de map ou de région ;
- un moment narratif ;
- une étape macro du pacing ;
- un conteneur de lecture dans l’éditeur.

### Ce qu’un Chapter ne doit pas représenter

Il ne doit pas être :

- nécessairement une map ;
- un état runtime obligatoire ;
- une sauvegarde séparée ;
- un niveau ;
- un sous-jeu ;
- une Scene ;
- une contrainte rigide imposée aux petites Storylines.

### Diagnostics Validator possibles

Diagnostics futurs :

- Chapter vide ;
- Chapter sans ordre clair si la Storyline exige un ordre ;
- Chapter référencé par un Step inconnu ;
- Chapter marqué obligatoire sans Step terminable ;
- Chapter dont le statut dérivé dépend d’un Step jamais complété.

### Impacts Phase 2

Phase 2 devra décider :

- Chapter obligatoire ou optionnel ;
- Chapter implicite pour petites Storylines ;
- statut de Chapter calculé ou stocké ;
- relation avec les predicates `chapterCompleted` existants.

## 10. Chapter — rôle d’organisation et limites

Chapter sert à :

- organiser la lecture ;
- grouper les Story Steps ;
- aider le Validator ;
- aider le futur filtrage UI ;
- faciliter les vues Storyline Graph ;
- donner un contexte humain aux Scenes et Events.

Chapter ne sert pas à :

- déclencher une Scene ;
- écrire un Fact ;
- remplacer un Event ;
- imposer une map ;
- imposer un état runtime ;
- transformer une quête courte en structure lourde.

Recommandation :

```text
Pour l’histoire principale, Chapter est recommandé.
Pour une petite side quest, Chapter peut être implicite ou optionnel.
```

## 11. Story Step — définition canonique

### Définition

Un Story Step est une unité de progression claire, validable et compréhensible.
Il représente un jalon concret dans une Storyline.

### Rôle utilisateur

Il répond à :

```text
Quel jalon concret fait avancer cette histoire ?
```

Exemples :

- Parler à Lysa au port.
- Battre le rival.
- Recevoir la clé du phare.
- Ouvrir le passage vers les marais.
- Rendre la récompense à Soline.

### Données conceptuelles minimales

P1-04 ne crée pas de modèle, mais Phase 2 devra probablement discuter :

| Notion conceptuelle | Rôle |
|---|---|
| Identifiant futur éventuel | Mapping vers `completedStepIds` ou futur registry. |
| Nom utilisateur | Label no-code : “Battre le rival au port”. |
| Description | Ce que le joueur doit faire ou a accompli. |
| Parent Storyline | Ligne narrative concernée. |
| Parent Chapter éventuel | Section d’organisation. |
| Statut conceptuel | Non disponible, disponible, actif, terminé, etc. |
| Entry conditions | Conditions de disponibilité ou activation. |
| Completion conditions | Conditions de complétion. |
| Completed by Scene | Scene(s) qui peuvent compléter le Step. |
| Facts written | Facts produits à la complétion. |
| Facts read | Facts requis ou lus. |
| Events expected | Events qui déclenchent les Scenes liées. |
| World rules affected | Projections visibles après progression. |
| Notes auteur | Intention ou aide narrative. |

Ces notions ne sont pas un schéma JSON.

### Entrées / sorties

Entrées :

- availability facts ;
- Step précédent ;
- Event déclencheur ;
- Scene orchestratrice ;
- outcome Yarn ou Battle interprété par Scene.

Sorties :

- Step completed ;
- Facts de résolution ;
- World Rules recalculées ;
- disponibilité de Step suivant ou Storyline secondaire ;
- diagnostics.

### Relations

Un Story Step :

- appartient à une Storyline ;
- peut appartenir à un Chapter ;
- est rendu disponible par Facts, Steps ou Storyline state ;
- est complété par une Scene ou action autorisée ;
- peut produire des Facts ;
- peut être lu par des Events et World Rules.

### Ce qu’un Story Step peut représenter

Il peut représenter :

- un objectif narratif ;
- une étape d’enquête ;
- un combat à résoudre ;
- un item à obtenir ;
- un lieu à atteindre ;
- une interaction importante ;
- une résolution de side quest.

### Ce qu’un Story Step ne doit pas représenter

Il ne doit pas être :

- une Scene ;
- une Cinematic ;
- un dialogue ;
- un combat ;
- un flag brut ;
- un script ;
- une action gameplay ;
- un conteneur de toute une quête.

### Diagnostics Validator possibles

Diagnostics futurs :

- Story Step jamais activable ;
- Story Step actif mais jamais complété ;
- Story Step complété par une Scene absente ;
- Story Step dépend d’un Fact jamais écrit ;
- Event référence un Step inconnu ;
- Scene complète un Step inconnu ;
- World Rule lit un Step inconnu ;
- Step terminal sans Fact de résolution si nécessaire.

### Impacts Phase 2

Phase 2 devra décider :

- si `completedStepIds` suffit comme storage initial ;
- si un Story Step registry est nécessaire ;
- quels statuts V0 sont réellement persistés ;
- comment Step completion se valide dans `NarrativeValidator`.

## 12. Story Step — statuts conceptuels et cycle de vie

Cycle simple recommandé :

```text
non disponible
→ disponible
→ actif
→ terminé
```

Statuts optionnels à valider plus tard :

- échoué ;
- abandonné ;
- masqué ;
- ignoré ;
- optionnel ;
- bloqué.

Ces statuts sont conceptuels. P1-04 ne crée ni enum, ni save data, ni migration.

Cycle canonique :

1. Une Storyline devient disponible.
2. Un Chapter organise la zone de progression.
3. Un Story Step devient disponible ou actif.
4. Un Event lié déclenche une Scene.
5. La Scene orchestre dialogue, cinematic, battle ou action.
6. La Scene écrit des Facts.
7. La Scene complète le Story Step.
8. Des World Rules reflètent la progression.
9. Le Validator vérifie la cohérence.

Décision de prudence :

```text
V0 peut commencer avec “terminé / non terminé” côté storage,
mais l’UX doit préparer “disponible / actif / terminé” comme langage auteur.
```

## 13. Side Quest — position produit

Règle produit :

```text
Une Side Quest est une Storyline secondaire.
```

Elle peut avoir :

- conditions de disponibilité ;
- Steps optionnels ;
- Events liés ;
- Scenes liées ;
- Facts produits ;
- World Rules ;
- récompenses ;
- dialogues de résolution.

Elle ne nécessite pas au départ :

- Quest Engine ;
- Quest Journal ;
- modèle séparé obligatoire ;
- save data dédiée ;
- UI de journal ;
- reward model ;
- routing spécial hors Scenes/Facts/Steps.

Lecture de NS-GS-16 :

```text
availability fact
→ scene start
→ started fact + step
→ objective step
→ final scene conditionnée
→ giveItem reward simple
→ completed fact + step
→ save/load
→ world rule dialogue/visibility
```

Ce flux prouve que le pattern “side quest V0” fonctionne déjà au niveau Level 2
Application avec les briques génériques. Il ne prouve pas un Quest Engine et ne
demande pas d’en créer un pendant P1-04.

Position recommandée :

```text
Side quest V0 = Storyline type sideQuest.
Quest Engine futur possible ≠ obligatoire maintenant.
Quest Journal futur possible ≠ structure produit de base.
```

Limites assumées :

- pas de journal de quête maintenant ;
- pas de tracking UI maintenant ;
- pas de reward model maintenant ;
- pas de save data maintenant ;
- pas de décision sur failed/abandoned tant que le produit ne l’exige pas.

## 14. Relation avec Event

Event déclenche une Scene. Il peut vérifier si une Storyline ou un Story Step
est disponible ou actif, mais il ne doit pas devenir la progression.

Règles :

- Event peut lire un Step ou Fact en condition ;
- Event peut cibler une Scene ;
- Event peut être one-shot ou repeatable selon les Facts/Steps ;
- Event ne complète pas directement toute une Storyline ;
- Event ne contient pas toute la logique de side quest.

Exemple conceptuel :

```text
Event : le joueur parle à Lysa.
Condition : Step “Battre le rival au port” actif.
Target : Scene “Rencontre rival”.
```

L’Event répond à “quand et si ?”. La Scene répond à “alors et puis ?”.

## 15. Relation avec Scene

Scene orchestre. Elle est le lieu recommandé pour faire progresser les Steps.

Une Scene peut :

- lancer Dialogue Yarn ;
- lancer Cinematic ;
- lancer Battle ;
- lire outcomes ;
- écrire Facts ;
- compléter un Story Step ;
- rendre disponible un autre Step via Fact ;
- terminer une Storyline si toutes les conditions sont remplies.

Mais :

- Scene ≠ Story Step ;
- Scene ≠ Storyline ;
- Scene n’est pas une quête complète par elle-même ;
- Scene ne doit pas cacher la progression sous forme de script opaque.

Exemple :

```text
Scene “Rencontre rival”
→ dialogue
→ battle
→ outcome victory
→ Fact “Le rival a été battu au port”
→ Step “Battre le rival au port” terminé
```

## 16. Relation avec Fact

Fact nomme une vérité. Story Step nomme un jalon.

Exemple :

```text
Story Step : Battre le rival au port.
Fact : Le rival a été battu au port.
```

Ils peuvent se recouvrir, mais ne sont pas identiques :

- le Step appartient à la structure narrative ;
- le Fact décrit une vérité que d’autres systèmes peuvent lire ;
- Step completed peut être lu comme Fact dérivé ;
- Fact peut rendre un Step disponible ;
- Fact peut être écrit par la Scene qui complète un Step.

Règle :

```text
Ne pas fusionner Fact et Story Step sans frontière.
```

## 17. Relation avec World Rule

World Rule lit Facts et Steps. Elle montre la progression dans le monde.

Une World Rule peut :

- changer le dialogue d’un PNJ après un Step ;
- rendre visible une side quest ;
- cacher un objectif optionnel après complétion ;
- afficher ou masquer un élément lié au Chapter courant ;
- modifier un état visible lié à une Storyline.

Elle ne doit pas :

- démarrer une Storyline ;
- compléter un Step ;
- écrire un Fact ;
- remplacer un Event.

Exemple :

```text
Si le Step “Battre le rival au port” est terminé,
alors Lysa utilise son dialogue post-combat.
```

## 18. Relation avec Dialogue Yarn et Battle

Dialogue Yarn produit des outcomes. Scene lit ces outcomes. Scene décide si un
outcome devient Fact ou complète un Step.

Exemples :

- Outcome “confident” influence une branche immédiate ;
- Outcome “confident” devient un Fact si Lysa doit s’en souvenir ;
- Outcome “accept_help” peut rendre une side quest disponible si la Scene le
  transforme en Fact.

Battle produit des outcomes gameplay. Scene lit le résultat et décide la
progression narrative.

Exemples :

- victory → Scene complète “Battre le rival” ;
- defeat → Scene peut afficher une revanche sans compléter le Step ;
- captured future → Scene peut compléter un Step si le combat statique est
  résolu.

Limites :

- Yarn ne complète pas toute une Storyline seul ;
- Battle ne décide pas seul de la progression narrative ;
- les preuves NS-GS restent surtout Level 2 Application.

## 19. Relation avec Validator

Le Validator diagnostique. Il n’exécute pas, ne mute pas et ne corrige pas
automatiquement.

Diagnostics futurs utiles :

- Storyline sans début ;
- Storyline sans fin ;
- Storyline sans Step ;
- Storyline sideQuest sans condition de disponibilité si elle est censée être
  débloquée ;
- Chapter vide ;
- Chapter sans ordre clair ;
- Story Step jamais activable ;
- Story Step actif mais jamais complété ;
- Story Step complété par une Scene absente ;
- Story Step dépend d’un Fact jamais écrit ;
- Event référence un Step inconnu ;
- Scene complète un Step inconnu ;
- World Rule lit un Step inconnu ;
- Side quest disponible mais jamais atteignable ;
- Step terminal sans Fact de résolution si nécessaire.

Ne pas implémenter ces diagnostics dans P1-04.

Règle :

```text
Validator diagnostique.
Validator ne corrige pas automatiquement.
```

## 20. Matrice Storyline / Chapter / Story Step / Fact

| Responsabilité | Storyline | Chapter | Story Step | Fact | Commentaire |
|---|---|---|---|---|---|
| Regrouper une histoire | Oui | Non | Non | Non | Storyline porte le fil narratif. |
| Organiser une section | Non | Oui | Non | Non | Chapter structure la lecture. |
| Décrire un jalon concret | Non | Non | Oui | Non | Step décrit la progression attendue. |
| Mémoriser une vérité | Non | Non | Partiellement / dérivé | Oui | Fact est la vérité lisible. |
| Être complété par une Scene | Non directement | Non | Oui | Non | Scene complète un Step. |
| Être lu par Event | Peut être résumé | Peut être dérivé | Oui | Oui | Event lit surtout Step/Fact. |
| Être lu par World Rule | Peut être dérivé | Peut être dérivé | Oui | Oui | World Rule projette Step/Fact. |
| Être affiché au créateur | Oui | Oui | Oui | Oui | Tous doivent être lisibles. |
| Être dérivé d’un état technique | Possible | Possible | Oui | Oui | À formaliser en Phase 2. |
| Diagnostiquer cohérence | Non | Non | Non | Non | Validator porte le diagnostic. |

Exemples attendus :

```text
Mémoriser une vérité :
Storyline non / Chapter non / Story Step partiellement / Fact oui.

Organiser une section :
Storyline non / Chapter oui / Story Step non / Fact non.

Décrire un jalon concret :
Storyline non / Chapter non / Story Step oui / Fact non.
```

## 21. Mapping vers l’existant

| Existant | Lecture produit P1-04 | Statut | Limite |
|---|---|---:|---|
| `completedStepIds` | Stockage technique de Step completion | ✅ Prouvé Level 1/2 | Pas de Story Step registry canonique. |
| `storyFlags.activeFlags` | Peut soutenir availability, facts et side quest state | ⚠️ Partiel | Pas de labels humains ni de type Storyline. |
| `scenario.outcome.*` | Outcome technique qui peut influer un Step via Scene | ⚠️ Partiel | Pas un modèle de progression. |
| `ScenarioAsset` | Support de Scene et de graphe existant | ✅ Prouvé Level 2 | Pas modèle Storyline produit clair. |
| `ScenarioAsset(scope: globalStory)` | Ancien support possible de Global Story | ⚠️ Partiel | Ambigu, pas Storylines Board ni type sideQuest. |
| `GlobalStoryChapterStepIndex` | Évaluation Chapter completed depuis Steps | ⚠️ Partiel | Chapter non typé dans `map_core`, metadata historique. |
| NS-GS-16 side quest | Optional storyline pattern via facts/steps/scenes | ✅ Prouvé Level 2 | Pas Quest Engine / Quest Journal. |
| World Rules conditional presence/dialogue | Projection de Step/Fact vers monde visible | ✅ Prouvé Level 1/2 | Pas registry World Rule central. |
| Narrative Validator V0 | Diagnostics flags/steps/scenarios | ⚠️ Partiel | Pas Storyline/Chapter/Step registry complet. |
| PlayableMapGame Golden Slice complet | Runtime Flame complet | ❌ Non prouvé | NS-GS reste surtout Level 2. |
| Disk project editor-created | Projet disque réel créé dans éditeur | ❌ Non prouvé | Phase future. |

Lecture critique :

- Step completion technique est bien prouvé ;
- side quest pattern est prouvé sans moteur dédié ;
- Chapter existe déjà partiellement dans certains predicates/runtime historiques ;
- Storyline comme produit canonique n’est pas encore stabilisée ;
- Phase 2 devra choisir entre formaliser ces concepts ou créer une couche
  produit au-dessus des structures existantes.

## 22. Mapping Selbrume illustratif

Mapping conceptuel, non créé dans le dépôt :

```text
Storyline : La brume du phare
Chapter : Le port
Story Step : Parler à Lysa au port
Event : Interaction avec Lysa
Scene : Rencontre rival
Dialogue Yarn : rival_intro
Battle : Combat rival
Fact : Le rival a été battu au port
Story Step completed : Battre le rival au port
World Rule : Lysa change de dialogue
Side Quest Storyline : Aider Soline devient disponible
```

Clarification :

```text
La side quest ne nécessite pas un Quest Engine séparé.
Elle peut être une Storyline secondaire rendue disponible par Fact/World Rule.
```

Exemple de side quest conceptuelle :

```text
Storyline secondaire : Aider Soline
Chapter implicite : Port
Step 1 : Accepter d’aider Soline
Step 2 : Récupérer l’objet demandé
Step 3 : Rendre l’objet à Soline
Fact : Soline a reçu l’objet demandé
World Rule : Soline utilise son dialogue de remerciement
```

Aucun contenu Selbrume final n’est créé. Ce mapping est illustratif et prépare
P1-05.

## 23. Vocabulaire utilisateur recommandé

| Concept | Libellé utilisateur recommandé | À éviter en UX simple |
|---|---|---|
| Storyline | Histoire / Quête | `scenarioId`, `globalStory` |
| Main Storyline | Histoire principale | `mainStoryFlag` |
| Side Quest Storyline | Quête annexe | Quest Engine |
| Chapter | Chapitre | runtime chapter state |
| Story Step | Étape | `completedStepIds` |
| Step active | Étape en cours | active bool |
| Step completed | Étape terminée | flag done |
| Availability | Disponible | predicate |
| Locked | Non disponible | boolean flag |
| Completed | Terminé | raw save state |

Termes à éviter dans le flux auteur normal :

- `completedStepIds`
- `storyFlags`
- `scenarioId`
- `quest engine`
- `node id`
- `predicate`
- `state machine`
- `boolean flag`

Ces termes peuvent rester en documentation technique, mode debug ou panneau
avancé. Ils ne doivent pas être le langage principal de l’auteur.

## 24. Anti-patterns interdits

- Storyline utilisée comme simple dossier sans logique ;
- Storyline utilisée comme Quest Engine complet trop tôt ;
- Chapter utilisé comme map obligatoire ;
- Chapter utilisé comme état runtime obligatoire ;
- Story Step utilisé comme flag technique brut ;
- Story Step utilisé comme Scene ;
- Story Step qui contient dialogue/combat/cinematic ;
- Side quest implémentée comme système séparé obligatoire ;
- Quest Journal lancé pendant Phase 1 ;
- Step completed écrit sans Scene ou sans conséquence lisible ;
- Fact et Story Step fusionnés sans frontière ;
- World Rule qui complète un Step ;
- Yarn qui complète toute une Storyline seul ;
- Battle qui termine une Storyline sans Scene ;
- Validator qui corrige automatiquement ;
- modèles `map_core` créés pendant Phase 1.

## 25. Impacts attendus pour P1-05 et Phase 2

P1-05 devra traiter :

```text
Selbrume Reference Grammar Mapping
```

P1-04 prépare P1-05 en clarifiant :

- comment mapper l’histoire principale Selbrume ;
- comment mapper les chapitres ;
- comment mapper les étapes ;
- comment mapper les side quests ;
- comment relier Steps, Facts, Events, Scenes et World Rules.

Phase 2 devra potentiellement transformer P1-04 en :

- contrat Storyline ;
- contrat Chapter ;
- contrat Story Step ;
- grammaire de statut Step ;
- type `sideQuest` ;
- diagnostics Validator ;
- relations avec `completedStepIds` ;
- relations avec `ScenarioAsset` ;
- relations avec Facts et World Rules.

Recommandation Phase 2 :

```text
Ne créer Storyline / Chapter / Story Step models que si les consumers sont clairs :
editor, runtime, validator, persistence, migration et tests.
```

## 26. Mise à jour de road_map_phase_1.md

`MVP Selbrume/road_map_phase_1.md` est mis à jour pour :

- marquer `P1-04 — Storyline / Chapter / Story Step Structure` comme terminé ;
- marquer `P1-05 — Selbrume Reference Grammar Mapping` comme prochain lot
  exact ;
- ajouter un résumé court du résultat ;
- lister les fichiers créés et modifiés ;
- lister les commandes exécutées ;
- confirmer qu’aucune décision utilisateur nouvelle ni changement de périmètre
  n’a été introduit.

`MVP Selbrume/road_map_global.md` n’est pas modifié.

## 27. Décisions à valider par l’utilisateur

Décisions produit à valider plus tard :

1. Faut-il exposer “Storyline” comme “Histoire”, “Quête” ou garder
   “Storyline” ?
2. Une side quest doit-elle être une Storyline typée `sideQuest` ou un modèle
   séparé plus tard ?
3. Un Chapter est-il obligatoire pour l’histoire principale ?
4. Un Chapter est-il optionnel pour les side quests ?
5. Quels statuts de Story Step sont nécessaires en V0 ?
6. Un Story Step terminé doit-il produire automatiquement un Fact dérivé ?
7. Faut-il afficher les Steps dans un futur journal de quête, ou seulement dans
   le Narrative Studio ?
8. Le statut `active` doit-il être stocké ou seulement dérivé depuis les
   conditions ?

Aucune de ces décisions ne bloque P1-05. Elles devront guider Phase 2 et les
workflows no-code futurs.

## 28. Evidence Pack

### 28.1 git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
Sortie vide — aucun changement détecté au début du lot.
```

### 28.2 Fichiers lus

```text
AGENTS.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_1.md
reports/roadmap/pokemap_full_product_phased_roadmap_v1.md
reports/roadmap/roadmap_global_00_master_phase_roadmap_bootstrap.md
reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md
reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md
reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md
MVP Selbrume/road_map.md
MVP Selbrume/narrative_studio.md
MVP Selbrume/selbrume.md
reports/gameplay/audit/narrative_studio_product_model_v0.md
reports/gameplay/audit/sel_a2_event_scene_outcome_fact_contract.md
reports/gameplay/ns_gs/ns_gs_08_npc_interaction_scene_authoring_readiness.md
reports/gameplay/ns_gs/ns_gs_09_yarn_outcome_scene_branch_readiness.md
reports/gameplay/ns_gs/ns_gs_10_world_rules_conditional_presence_readiness.md
reports/gameplay/ns_gs/ns_gs_12_bis_evidence_pack_and_level_label_fix.md
reports/gameplay/ns_gs/ns_gs_13_narrative_validator_minimal_v0.md
reports/gameplay/ns_gs/ns_gs_16_side_quest_optional_storyline_readiness.md
reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md
```

### 28.3 Fichiers créés

```text
reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md
```

### 28.4 Fichiers modifiés

```text
MVP Selbrume/road_map_phase_1.md
```

### 28.5 Commandes exécutées

```text
git status --short --untracked-files=all
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/using-superpowers/SKILL.md
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md
sed -n '1,260p' "MVP Selbrume/road_map_global.md"
sed -n '1,620p' "MVP Selbrume/road_map_phase_1.md"
sed -n '1,260p' reports/roadmap/pokemap_full_product_phased_roadmap_v1.md
sed -n '1,260p' reports/roadmap/roadmap_global_00_master_phase_roadmap_bootstrap.md
sed -n '1,220p' reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md
sed -n '1,420p' reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
sed -n '1,420p' reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md
sed -n '1,460p' reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md
sed -n '460,980p' reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md
sed -n '1,260p' "MVP Selbrume/road_map.md"
sed -n '1,300p' "MVP Selbrume/narrative_studio.md"
sed -n '1,240p' "MVP Selbrume/selbrume.md"
sed -n '1,220p' AGENTS.md
sed -n '1,300p' reports/gameplay/audit/narrative_studio_product_model_v0.md
sed -n '1,300p' reports/gameplay/audit/sel_a2_event_scene_outcome_fact_contract.md
sed -n '1,260p' reports/gameplay/ns_gs/ns_gs_08_npc_interaction_scene_authoring_readiness.md
sed -n '1,280p' reports/gameplay/ns_gs/ns_gs_09_yarn_outcome_scene_branch_readiness.md
sed -n '1,320p' reports/gameplay/ns_gs/ns_gs_10_world_rules_conditional_presence_readiness.md
sed -n '1,260p' reports/gameplay/ns_gs/ns_gs_12_bis_evidence_pack_and_level_label_fix.md
sed -n '1,320p' reports/gameplay/ns_gs/ns_gs_13_narrative_validator_minimal_v0.md
sed -n '1,360p' reports/gameplay/ns_gs/ns_gs_16_side_quest_optional_storyline_readiness.md
sed -n '1,360p' reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md
rg -n "Storyline|Chapter|Story Step|Side Quest|side quest|optional|completedStepIds|Quest Engine|Quest Journal|Level 2|Level 3|Level 4" reports/roadmap reports/gameplay/audit reports/gameplay/ns_gs "MVP Selbrume" --glob "*.md"
wc -l AGENTS.md "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_1.md" reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md reports/gameplay/ns_gs/ns_gs_16_side_quest_optional_storyline_readiness.md reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md
test -f reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md && sed -n '1,80p' reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md || true
sed -n '80,260p' reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md
sed -n '260,560p' reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md
sed -n '560,920p' reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md
sed -n '920,1280p' reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md
sed -n '1280,1380p' reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md
sed -n '1190,1315p' reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md
sed -n '1315,1375p' reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md
wc -l reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md
apply_patch
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff --no-index --check /dev/null reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md || true
git diff -- "MVP Selbrume/road_map_phase_1.md"
git diff -- "MVP Selbrume/road_map_global.md"
wc -l reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md "MVP Selbrume/road_map_phase_1.md" "MVP Selbrume/road_map_global.md"
```

### 28.6 git diff --check

Sortie exacte : vide.

```text
```

### 28.7 git diff --stat

```text
 MVP Selbrume/road_map_phase_1.md | 35 ++++++++++++++++++++++++-----------
 1 file changed, 24 insertions(+), 11 deletions(-)
```

### 28.8 git diff --name-only

```text
MVP Selbrume/road_map_phase_1.md
```

### 28.9 git status final

```text
 M "MVP Selbrume/road_map_phase_1.md"
?? reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md
```

### 28.10 Tests / analyze

```text
Non exécutés — P1-04 est documentaire et ne modifie aucun code.
```

### 28.11 git diff --no-index --check du rapport P1-04

Sortie exacte : vide.

```text
```

### 28.12 Diff de road_map_phase_1.md

```diff
diff --git a/MVP Selbrume/road_map_phase_1.md b/MVP Selbrume/road_map_phase_1.md
index c5cb0e7b..5a73d693 100644
--- a/MVP Selbrume/road_map_phase_1.md
+++ b/MVP Selbrume/road_map_phase_1.md
@@ -6,9 +6,9 @@ Phase 1 — Canonical Product Model / Narrative Studio Foundations

 Statut : 🔜 En préparation

-Lot courant : P1-03 — Fact & World Rule Product Grammar
+Lot courant : P1-04 — Storyline / Chapter / Story Step Structure

-Prochain lot exact après P1-03 : P1-04 — Storyline / Chapter / Story Step Structure
+Prochain lot exact après P1-04 : P1-05 — Selbrume Reference Grammar Mapping

 Suivi des lots :

@@ -16,8 +16,8 @@ Suivi des lots :
 - ✅ P1-01 — Canonical Narrative Product Model V1
 - ✅ P1-02 — Event / Scene / Cinematic Boundary Contract
 - ✅ P1-03 — Fact & World Rule Product Grammar
-- 🔜 P1-04 — Storyline / Chapter / Story Step Structure
-- P1-05 — Selbrume Reference Grammar Mapping
+- ✅ P1-04 — Storyline / Chapter / Story Step Structure
+- 🔜 P1-05 — Selbrume Reference Grammar Mapping
 - P1-06 — No-code Workflow Specification
 - P1-07 — Phase 2 Domain Contract Proposal
 - P1-CHECKPOINT-01 — Canonical Product Model Closure & Phase 2 Decision
@@ -30,7 +30,9 @@ P1-02 : ✅ terminé

 P1-03 : ✅ terminé

-P1-04 : 🔜 prochain lot exact
+P1-04 : ✅ terminé
+
+P1-05 : 🔜 prochain lot exact

 ## 2. Objectif de la Phase 1

@@ -250,7 +252,7 @@ Critères de validation :
 - les erreurs World Rule ≠ Event et Fact ≠ flag technique sont traitées ;
 - les besoins de validation future sont listés.

-### 🔜 P1-04 — Storyline / Chapter / Story Step Structure
+### ✅ P1-04 — Storyline / Chapter / Story Step Structure

 Objectif :
 Définir la structure Storyline / Chapter / Story Step et le statut des side quests.
@@ -278,7 +280,7 @@ Critères de validation :
 - la progression principale et optionnelle sont séparables ;
 - les besoins Phase 2 sont prêts à être transformés en contrats.

-### P1-05 — Selbrume Reference Grammar Mapping
+### 🔜 P1-05 — Selbrume Reference Grammar Mapping

 Objectif :
 Mapper le Golden Slice Selbrume “Lysa au port” sur la grammaire canonique.
@@ -394,13 +396,12 @@ Critères de validation :

 ## 10. Prochain lot exact

-P1-04 — Storyline / Chapter / Story Step Structure
+P1-05 — Selbrume Reference Grammar Mapping

 Objectif du prochain lot :
-Définir la structure Storyline / Chapter / Story Step et le statut des side
-quests.
+Mapper le Golden Slice Selbrume “Lysa au port” sur la grammaire canonique.

-P1-04 ne doit pas créer de code, de modèles `map_core`, d’UI, de fixtures
+P1-05 ne doit pas créer de code, de modèles `map_core`, d’UI, de fixtures
 Selbrume finales ou de `project.json`.

 ## 11. Critères de sortie de Phase 1
@@ -507,3 +508,15 @@ P1-CHECKPOINT-01 devra aussi mettre à jour
   Décisions utilisateur nouvelles : aucune.
   Changements de périmètre : aucun.
   Prochain lot exact fixé à P1-04 — Storyline / Chapter / Story Step Structure.
+- 2026-05-24 — P1-04 — Storyline / Chapter / Story Step Structure terminé.
+  Résultat : structure narrative produit stricte Storyline = ligne narrative /
+  Chapter = section / Story Step = jalon, avec side quest positionnée comme
+  Storyline secondaire sans Quest Engine ni Quest Journal.
+  Fichiers créés : `reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md`.
+  Fichiers modifiés : `MVP Selbrume/road_map_phase_1.md`.
+  Commandes exécutées : lectures Markdown ciblées, `rg`, `wc -l`,
+  `git status --short --untracked-files=all`, `git diff --check`,
+  `git diff --stat`, `git diff --name-only`, `git diff --no-index --check`.
+  Décisions utilisateur nouvelles : aucune.
+  Changements de périmètre : aucun.
+  Prochain lot exact fixé à P1-05 — Selbrume Reference Grammar Mapping.
```

### 28.13 Vérification road_map_global.md

Commande :

```bash
git diff -- "MVP Selbrume/road_map_global.md"
```

Sortie exacte :

```text
```

Sortie vide : `road_map_global.md` n’a pas de diff dans P1-04.

### 28.14 Comptage de lignes final

```text
    1418 reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md
     522 MVP Selbrume/road_map_phase_1.md
     638 MVP Selbrume/road_map_global.md
    2578 total
```

### 28.15 Preuve des fichiers attendus uniquement

Les changements P1-04 attendus sont :

```text
MVP Selbrume/road_map_phase_1.md
reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md
```

La preuve finale est donnée par `git diff --name-only` et `git status final`
ci-dessus.

## 29. Auto-review critique

### Auto-review

| Question | Réponse |
|---|---|
| Le lot a-t-il modifié uniquement ce qui était autorisé ? | Oui, uniquement le rapport P1-04 et la roadmap Phase 1. |
| Le rapport P1-04 existe-t-il au bon chemin ? | Oui : `reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md`. |
| `road_map_phase_1.md` a-t-elle été mise à jour ? | Oui, P1-04 terminé et P1-05 prochain lot exact. |
| `road_map_global.md` est-elle restée intacte ? | Oui, elle est lue mais non modifiée. |
| Aucun code n’a-t-il été modifié ? | Oui, aucun fichier sous `packages/` ou `examples/` n’est modifié. |
| Aucun test/analyze Dart/Flutter n’a-t-il été lancé inutilement ? | Oui, non exécutés car P1-04 est documentaire. |
| P1-05 n’a-t-il pas été commencé ? | Oui, P1-05 est seulement mentionné comme prochain lot exact. |
| Selbrume est-il resté une référence conceptuelle seulement ? | Oui, aucun contenu Selbrume final n’est créé. |
| Les frontières Storyline / Chapter / Story Step sont-elles assez strictes ? | Oui : ligne narrative / section / jalon. |
| Le rapport évite-t-il de créer un Quest Engine prématuré ? | Oui, side quest V0 = Storyline typée `sideQuest`. |
| Le rapport évite-t-il de transformer Story Step en flag technique ? | Oui, `completedStepIds` est décrit comme storage, pas langage auteur. |

Ambiguïtés restantes à valider :

- nom UI final de Storyline : “Histoire”, “Quête” ou “Storyline” ;
- Chapter obligatoire ou optionnel selon type de Storyline ;
- statuts V0 réellement nécessaires pour Story Step ;
- mapping exact entre Step completed, Fact dérivé et Storyline completed ;
- futur Quest Journal : nécessaire plus tard ou non ;
- statut `active` stocké ou dérivé.

### Regard critique sur le prompt

Le prompt est cohérent avec Phase 1 et protège bien le périmètre documentaire.
La seule tension est que “Storyline / Chapter / Story Step Structure” appelle
naturellement des réflexes de modélisation persistante, mais le contrat interdit
justement de les implémenter maintenant. Cette tension est saine : P1-04 doit
préparer Phase 2 sans la commencer.
