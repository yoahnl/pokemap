# P1-03 — Fact & World Rule Product Grammar

## 1. Résumé exécutif

P1-03 définit la grammaire produit no-code de deux concepts qui risquent sinon
de redevenir du jargon technique :

```text
Fact = ce qui est vrai.
World Rule = ce que le monde montre parce que c’est vrai.
```

Le lot propose une séparation stricte :

- un Fact est une vérité persistante, lisible et nommable par un humain ;
- un Fact peut être stocké techniquement par un flag, une step terminée, une
  possession d’objet, un trainer state, un outcome mémorisé ou un état dérivé ;
- une World Rule lit des Facts, des Story Steps ou du GameState ;
- une World Rule projette passivement un changement visible : présence,
  dialogue, interactabilité, porte, objet, disponibilité de quête ou état visuel ;
- une World Rule n’écrit pas de Fact, ne complète pas de Step et ne déclenche
  pas de Scene.

La frontière proposée est volontairement stricte :

```text
Scene écrit les conséquences durables.
Fact nomme les vérités durables.
World Rule projette ces vérités dans le monde visible.
Event déclenche.
Validator diagnostique.
```

Ce qui reste hors scope :

- aucun code ;
- aucun modèle `map_core` ;
- aucun `FactRegistry` ;
- aucun `WorldRuleRegistry` ;
- aucune modification du Narrative Validator ;
- aucune UI ;
- aucun contenu Selbrume final.

Prochain lot exact après P1-03 :

```text
P1-04 — Storyline / Chapter / Story Step Structure
```

## 2. Scope du lot

Inclus :

- définition produit de Fact ;
- grammaire de nommage no-code des Facts ;
- cycle de vie produit des Facts ;
- distinction entre Fact utilisateur, flag technique, état dérivé et storage ;
- définition produit de World Rule ;
- types de projections visibles supportées conceptuellement ;
- cycle de vie produit des World Rules ;
- relation avec Event, Scene, Story Step, Storyline, Chapter, Yarn, Battle,
  GameState et Validator ;
- mapping prudent vers les acquis NS-GS ;
- mapping Selbrume uniquement illustratif ;
- mise à jour de `MVP Selbrume/road_map_phase_1.md`.

Exclus :

- aucun code modifié ;
- aucun test lancé ;
- aucun package modifié ;
- aucun `FactRegistry` créé ;
- aucun `WorldRuleRegistry` créé ;
- Narrative Validator lu pour contexte, mais non modifié ;
- `MVP Selbrume/road_map_global.md` lu, mais non modifié ;
- Selbrume utilisé comme référence conceptuelle uniquement.

Fichiers créés :

- `reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md`

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

| Fichier | Rôle dans P1-03 |
|---|---|
| `AGENTS.md` | Règles de repo, limites de package, sécurité Git et evidence. |
| `MVP Selbrume/road_map_global.md` | Gouvernance globale par phases ; lu pour contexte, non modifié. |
| `MVP Selbrume/road_map_phase_1.md` | Roadmap vivante Phase 1 ; source à mettre à jour. |
| `reports/roadmap/pokemap_full_product_phased_roadmap_v1.md` | Proposition stratégique qui place Phase 1 avant modèles et UI. |
| `reports/roadmap/roadmap_global_00_master_phase_roadmap_bootstrap.md` | Rapport de création de la roadmap globale vivante. |
| `reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md` | Cadre de maintenance de Phase 1. |
| `reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md` | Définitions canoniques initiales Fact / World Rule / Validator. |
| `reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md` | Contrat Event / Scene / Cinematic et place de Fact / World Rule. |
| `MVP Selbrume/road_map.md` | Roadmap historique NS-GS, conservée comme contexte. |
| `MVP Selbrume/narrative_studio.md` | Vision Narrative Studio et besoin de remplacer les flags bruts par des faits lisibles. |
| `MVP Selbrume/selbrume.md` | Référence conceptuelle Selbrume, sans création de contenu. |

Sources NS-GS et audits :

| Fichier | Rôle dans P1-03 |
|---|---|
| `reports/gameplay/audit/narrative_studio_product_model_v0.md` | Confirme que le Narrative Studio doit éviter l’édition de flags bruts. |
| `reports/gameplay/audit/sel_a2_event_scene_outcome_fact_contract.md` | Contrat Event → Scene → Outcome → Fact → Step → World Rule. |
| `reports/gameplay/ns_gs/ns_gs_09_yarn_outcome_scene_branch_readiness.md` | Outcomes Yarn persistés techniquement comme `scenario.outcome.*`. |
| `reports/gameplay/ns_gs/ns_gs_10_world_rules_conditional_presence_readiness.md` | Présence et dialogues conditionnels prouvés par predicates GameState. |
| `reports/gameplay/ns_gs/ns_gs_12_bis_evidence_pack_and_level_label_fix.md` | Rappel strict Level 2 Application, pas Level 3/4 complet. |
| `reports/gameplay/ns_gs/ns_gs_13_narrative_validator_minimal_v0.md` | Validator V0 diagnostique, sans exécuter ni corriger. |
| `reports/gameplay/ns_gs/ns_gs_14_item_pickup_give_item_authoring_readiness.md` | Pickup / giveItem → Bag + fact/step + save/load. |
| `reports/gameplay/ns_gs/ns_gs_15_key_item_door_gate_readiness.md` | Key item → fact dérivé → gate ; `hasItem` direct absent. |
| `reports/gameplay/ns_gs/ns_gs_16_side_quest_optional_storyline_readiness.md` | Side quest V0 via facts/steps/scenes/world rules, sans Quest Engine. |
| `reports/gameplay/ns_gs/ns_gs_17_static_encounter_boss_battle_readiness.md` | Boss trainer-like → outcome → facts/steps/world rules. |
| `reports/gameplay/ns_gs/ns_gs_18_reward_money_xp_bridge_audit.md` | Reward item post-battle via scène ; money/XP non prouvés. |
| `reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md` | Synthèse : NS-GS principalement Level 2 Application. |

## 4. Rappel P1-01 / P1-02

P1-01 a défini :

```text
Fact = vérité lisible du monde.
World Rule = projection passive du GameState.
Validator = diagnostique.
```

P1-02 a durci :

```text
Event déclenche.
Scene orchestre.
Cinematic met en scène.
```

P1-02 a aussi posé la règle utile pour P1-03 :

```text
Event peut lire Facts/Steps en conditions.
Scene écrit les Facts.
Scene complète les Steps.
Cinematic ne doit pas écrire la progression.
World Rule lit Facts/Steps et projette passivement.
```

P1-03 ne redéfinit pas tout P1-01/P1-02. Il durcit uniquement le langage produit
de Fact et World Rule pour préparer P1-04 puis Phase 2.

## 5. Problème à résoudre

Les flags techniques sont nécessaires au moteur, mais ils sont un mauvais langage
principal pour une personne non développeuse. Ils décrivent un stockage, pas une
intention.

Mauvais modèle mental :

```text
flag_lighthouse_key = true
scenario.outcome.rival_intro.confident = true
npc_lysa_state_2
```

Bon modèle mental :

```text
Le joueur possède la clé du phare.
Le joueur a choisi une réponse confiante.
Lysa parle maintenant après le combat du port.
```

Les problèmes à résoudre sont précis :

- les flags bruts sont illisibles dans une UX no-code ;
- des Facts mal nommés peuvent devenir une soupe de chaînes non validables ;
- une World Rule trop active peut devenir un Event déguisé ;
- les conditions peuvent se disperser entre Event, Scene, Yarn, Cinematic et
  World Rule ;
- un changement visible devient magique si on ne sait pas quel Fact le provoque ;
- le Validator ne pourra pas expliquer les erreurs si les vérités du monde n’ont
  pas de nom humain.

Le créateur ne doit pas penser :

```text
storyFlags.activeFlags contient "test_key_fact".
```

Il doit penser :

```text
Le joueur possède la clé du phare.
```

## 6. Principe de séparation Fact / World Rule

Règle produit :

```text
Fact = ce qui est vrai.
World Rule = ce que le monde montre parce que c’est vrai.
```

Conséquences de cette règle :

- Fact est un état lisible ;
- Fact peut être persistant ou dérivé ;
- Fact peut être lu par Event, Scene, World Rule et Validator ;
- Scene est le lieu recommandé pour écrire les Facts narratifs ;
- Event peut lire des Facts dans ses conditions d’entrée ;
- Scene peut lire des Facts pour brancher son orchestration ;
- World Rule lit des Facts, mais ne les écrit pas ;
- World Rule ne déclenche pas de Scene ;
- World Rule ne consomme pas un Event ;
- World Rule ne complète pas un Story Step.

Formulation canonique :

```text
Quand un Event se déclenche,
la Scene orchestre,
la Scene marque ce qui devient vrai,
les Facts nomment ces vérités,
les World Rules montrent leurs effets visibles.
```

## 7. Fact — définition canonique

### Définition

Un Fact est une vérité persistante, lisible et référençable du monde du jeu.

Un Fact doit être compréhensible par :

- le créateur dans l’éditeur ;
- le Validator dans ses diagnostics ;
- le futur runtime dans ses conditions ;
- la future UI dans ses pickers ;
- éventuellement le joueur si le jeu expose un journal ou un résumé.

### Rôle utilisateur

Le Fact permet au créateur de dire :

```text
Cette chose est maintenant vraie dans mon aventure.
```

Exemples :

- Le rival a été battu au port.
- Le joueur a reçu la clé du phare.
- Maël a expliqué l’origine de la brume.
- La récompense de la quête a été donnée.
- Le vieux passage est maintenant connu.

### Données conceptuelles minimales

P1-03 ne crée aucun modèle, mais le produit aura probablement besoin de ces
notions en Phase 2 :

| Notion conceptuelle | Rôle |
|---|---|
| Identifiant technique futur éventuel | Référence stable pour runtime, save, migration et validator. |
| Label utilisateur | Phrase lisible affichée dans l’éditeur. |
| Description | Explication courte du sens du Fact. |
| Catégorie | Story, character, world, item, battle, dialogue, system, derived. |
| Scope | Global, storyline, chapter, map, character, item, battle, quest. |
| Source d’écriture attendue | Scene, action, battle outcome interprété, item pickup, step completion. |
| Consumers attendus | Event, Scene, World Rule, Validator, future UI. |
| Notes auteur | Justification ou intention, non nécessaire au runtime. |

Ces notions restent documentaires. Elles ne constituent pas un schéma JSON.

### Origines possibles

Un Fact peut venir de :

- une Scene qui pose une conséquence ;
- une Scene qui transforme un outcome Yarn durable ;
- une Scene qui interprète un outcome Battle ;
- une action `giveItem` accompagnée d’un fact produit ;
- une Story Step terminée ;
- une possession d’objet clé lue comme état dérivé ;
- un trainer state ;
- une capture future ;
- une variable technique présentée avec un label humain.

### Durabilité

Un Fact est durable si le monde doit s’en souvenir après la Scene courante.

Un outcome temporaire n’a pas besoin de devenir Fact s’il ne sert qu’à choisir la
branche immédiate d’une Scene.

### Scope

Le scope évite de tout transformer en vérité globale.

Exemples :

- Global : le joueur possède la clé du phare.
- Storyline : la quête de Soline est terminée.
- Chapter : le chapitre du port est clos.
- Map : le vieux passage est connu sur cette carte.
- Character : Lysa a accepté d’aider.
- Battle : le rival a été battu au port.
- Dialogue : le joueur a choisi une réponse confiante.

### Ce qu’un Fact peut représenter

Un Fact peut représenter :

- une progression narrative ;
- un choix mémorisé ;
- un résultat de combat qui change le monde ;
- un objet obtenu, s’il doit être exprimé comme vérité lisible ;
- un état de personnage ;
- une porte ou zone désormais accessible ;
- une récompense déjà donnée ;
- un état dérivé d’une Step, d’un objet ou d’un trainer state.

### Ce qu’un Fact ne doit pas représenter

Un Fact ne doit pas être :

- un simple nom de flag brut exposé au créateur ;
- un ID moteur sans label ;
- un duplicat inutile d’un état déjà fiable ;
- un raccourci pour cacher une logique non validable ;
- un compteur technique présenté comme une vérité ;
- une action à exécuter ;
- une World Rule ;
- une Scene ;
- un Event.

### Diagnostics Validator possibles

Diagnostics futurs possibles :

- Fact référencé mais jamais écrit ;
- Fact écrit mais jamais lu ;
- Fact inconnu ;
- Fact dupliqué avec labels différents ;
- Fact technique exposé sans label humain ;
- Event lit un Fact non déclaré ;
- Scene écrit un Fact non déclaré.

### Impacts Phase 2

Phase 2 devra décider si PokeMap a besoin :

- d’un `FactRegistry` ;
- d’une couche de présentation des facts au-dessus des flags existants ;
- d’un mapping Fact → GameState / flags / steps / bag / trainer state ;
- de diagnostics validator spécifiques aux Facts ;
- de migrations ou règles d’ID stables.

P1-03 recommande de ne créer un registre que si ses consumers sont clairs :
éditeur, runtime, validator, persistence, migrations et tests.

## 8. Fact — grammaire de nommage no-code

Un Fact visible dans l’éditeur doit être formulé comme une phrase claire.

Bons exemples :

- Le rival a été battu au port.
- Le joueur a reçu la clé du phare.
- Lysa a accepté d’aider le joueur.
- La récompense de Soline a été donnée.
- Le vieux phare est accessible.
- Le joueur a choisi une réponse confiante.

Mauvais exemples exposés à l’utilisateur :

- `flag_rival_beaten = true`
- `scene_12_done`
- `scenario.outcome.rival_intro.confident`
- `var_034 > 1`
- `npc_lysa_state_2`

Règles de nommage :

| Règle | Pourquoi |
|---|---|
| Un Fact doit être formulé comme une phrase claire. | Le créateur doit comprendre sans contexte moteur. |
| Un Fact doit éviter les IDs internes dans son label. | Les IDs servent au stockage, pas au sens produit. |
| Un Fact doit pouvoir être lu dans un diagnostic. | Le Validator doit expliquer avec des mots humains. |
| Un Fact doit être relié à une source d’écriture. | Sinon il devient une vérité fantôme. |
| Un Fact doit avoir au moins un usage prévu ou être signalé comme orphelin. | Cela évite l’accumulation de faits morts. |
| Un Fact doit distinguer vérité durable et outcome temporaire. | Tous les résultats immédiats ne méritent pas une persistence. |
| Un Fact doit pouvoir être dérivé au lieu d’être stocké. | Cela évite de dupliquer le GameState. |

Préférer :

```text
Le joueur possède la clé du phare.
```

à :

```text
bagContains(lighthouse_key) == true
```

La deuxième formulation peut exister dans un panneau avancé ou dans la couche
technique, mais elle ne doit pas être le langage principal.

## 9. Fact — cycle de vie produit

Cycle canonique :

1. Une Scene ou action autorisée produit une conséquence.
2. Cette conséquence est formulée comme Fact.
3. Le Fact est persisté techniquement ou dérivé d’un état existant.
4. Events, Scenes et World Rules peuvent lire ce Fact.
5. Le Validator peut diagnostiquer Facts absents, inconnus, jamais écrits ou
   jamais lus.

Lecture et écriture recommandées :

| Moment | Responsable recommandé | Exemple |
|---|---|---|
| Écriture durable | Scene | Après victory, marquer “Le rival a été battu au port”. |
| Lecture en entrée | Event | Ne déclencher une Scene que si le rival n’est pas encore battu. |
| Lecture interne | Scene | Choisir une branche selon un choix mémorisé. |
| Projection visible | World Rule | Changer le dialogue de Lysa après le combat. |
| Diagnostic | Validator | Signaler une World Rule qui lit un Fact jamais écrit. |

Un Fact ne doit pas avoir de mémoire active propre. Il décrit un état ; il ne
fait rien par lui-même.

## 10. Fact — conditions, outcomes et technical storage

Il faut distinguer plusieurs notions proches :

| Notion | Définition | Exemple | Persistance |
|---|---|---|---|
| Outcome temporaire | Résultat immédiat d’un dialogue, combat ou action. | `confident` dans une Scene. | Non obligatoire. |
| Fact persistant | Vérité durable lisible. | Le joueur a choisi une réponse confiante. | Oui ou dérivé. |
| Story Step completed | Jalon de progression terminé. | “Battre le rival au port” terminé. | Oui. |
| Variable technique | Valeur moteur typée. | compteur, booléen, texte. | Selon besoin. |
| Item ownership | État du Bag. | La clé du phare est dans le Bag. | Oui via Bag. |
| Trainer state | État gameplay du trainer. | trainer_defeated:rival_port. | Oui via flags/trainer state. |
| Dialogue choice | Résultat Yarn. | Choix “confident”. | Temporaire ou durable selon usage. |

Catégories utiles :

### Fact source-of-truth

Le Fact est l’état principal à lire.

Exemple :

```text
Le rival a été battu au port.
```

### Fact dérivé

Le Fact est présenté à l’utilisateur, mais sa vérité vient d’un autre état.

Exemples :

- “Le joueur possède la clé du phare” dérivé du Bag.
- “L’étape Battre le rival est terminée” dérivé de `completedStepIds`.
- “Le rival est déjà battu” dérivé d’un trainer state.

### Fact de présentation

Le Fact sert surtout à afficher une phrase lisible dans l’éditeur ou un
diagnostic.

Exemple :

```text
Ce dialogue n’est disponible que si “Lysa a accepté d’aider”.
```

### Flag technique de stockage

Le flag technique est une clé de persistence.

Exemple :

```text
storyFlags.activeFlags contient test_key_fact.
```

Recommandation :

- ne pas dupliquer inutilement l’état ;
- ne pas créer un Fact stocké si l’état existe déjà proprement ;
- fournir quand même un label produit lisible pour l’utiliser dans l’UX et le
  Validator ;
- laisser Phase 2 décider le mapping technique.

Exemples :

| Situation | Recommandation |
|---|---|
| Outcome Yarn “confident” ne sert que dans la Scene courante. | Outcome temporaire, pas Fact. |
| Outcome Yarn “confident” influence Lysa plus tard. | Scene transforme l’outcome en Fact durable. |
| Battle victory change le monde. | Scene transforme victory en Fact durable. |
| Item clé déjà dans le Bag. | Présenter un Fact dérivé plutôt que dupliquer. |
| Step terminée déjà persistée. | Présenter un Fact dérivé si des World Rules doivent l’expliquer. |

## 11. World Rule — définition canonique

### Définition

Une World Rule est une projection passive de l’état vers le monde visible.

Elle répond à :

```text
Que montre le monde quand certains Facts, Steps ou états GameState sont vrais ?
```

### Rôle utilisateur

La World Rule permet au créateur de dire :

```text
Si cette vérité est vraie, alors le monde doit apparaître autrement.
```

Exemple :

```text
Si “Le rival a été battu au port”, alors Lysa utilise son dialogue post-combat.
```

### Données conceptuelles minimales

P1-03 ne crée aucun modèle, mais Phase 2 devra probablement discuter :

| Notion conceptuelle | Rôle |
|---|---|
| Identifiant futur éventuel | Référence stable pour diagnostics et migrations. |
| Nom utilisateur | Résumé humain de la règle. |
| Condition lisible | Fact, Step ou état GameState lu. |
| Target | Entité, dialogue, porte, pickup, zone, marker ou hint. |
| Type de projection | Présence, dialogue, interactabilité, porte, objet, quête, visuel. |
| État de fallback | Ce que le monde montre si la condition ne matche pas. |
| Scope | Map ou global. |
| Priorité | Résolution de conflits si plusieurs règles touchent la même target. |
| Notes auteur | Intention ou justification. |

Ces notions ne constituent pas un schéma JSON.

### Entrées

Une World Rule peut lire :

- Fact source-of-truth ;
- Fact dérivé ;
- Story Step completed ;
- Chapter status futur ;
- item ownership futur via Fact dérivé ou condition spécialisée ;
- trainer state ;
- cutscene completed ;
- variable technique, si elle est présentée par un label humain.

### Sorties

Une World Rule peut projeter :

- présence ou absence ;
- dialogue conditionnel ;
- interactabilité ;
- porte ouverte ou fermée ;
- objet visible ou caché ;
- disponibilité d’une quête ;
- indice ou marker futur ;
- état visuel d’un élément ;
- passage autorisé ou bloqué.

### Ce qu’une World Rule peut faire

Elle peut :

- choisir entre plusieurs dialogues ;
- masquer ou afficher un PNJ ;
- masquer ou afficher un pickup ;
- indiquer qu’une porte est ouverte ou fermée ;
- modifier l’interactabilité d’un objet ;
- rendre l’entrée d’une quête disponible ;
- appliquer une projection différente après save/load.

### Ce qu’une World Rule ne doit pas faire

Elle ne doit pas :

- déclencher une Scene ;
- écrire un Fact ;
- compléter un Story Step ;
- lancer Battle ;
- donner un item ;
- devenir un Event ;
- contenir un branching narratif ;
- corriger automatiquement l’état ;
- muter le GameState.

### Diagnostics Validator possibles

Diagnostics futurs :

- World Rule sans condition ;
- World Rule condition impossible ;
- World Rule cible entité absente ;
- World Rule cible dialogue absent ;
- World Rule cible map absente ;
- World Rule conflit avec une autre règle ;
- World Rule utilisée comme Event ;
- Fact référencé mais jamais écrit.

### Impacts Phase 2

Phase 2 devra choisir si les World Rules restent attachées aux payloads existants
ou deviennent un contrat produit plus explicite. P1-03 recommande de garder une
frontière passive stricte quelle que soit la représentation.

## 12. World Rule — types de projections visibles

| Type de projection | Ce que la règle lit | Ce qu’elle change visuellement | Ce qu’elle ne doit pas faire | Exemple conceptuel |
|---|---|---|---|---|
| Présence / absence PNJ | Fact ou Step | PNJ visible ou caché | Lancer une Scene quand le PNJ apparaît | Si le rival est battu, cacher le proxy de combat. |
| Dialogue conditionnel | Fact, Step ou choix mémorisé | Dialogue sélectionné | Écrire le choix ou lancer Yarn | Si Lysa a accepté d’aider, utiliser son dialogue de soutien. |
| Interactabilité | Fact ou état dérivé | Objet activable ou non | Donner directement l’objet | Si le vieux passage est connu, rendre le levier utilisable. |
| Porte ouverte / fermée | Fact dérivé d’objet clé ou Step | État ouvert/fermé, blocage visuel | Téléporter ou terminer une étape | Si le joueur possède la clé, la porte du phare est ouverte. |
| Objet visible / caché | Fact pickup déjà ramassé | Pickup affiché ou supprimé | Ajouter l’item au Bag | Si la potion est déjà ramassée, ne plus l’afficher. |
| Quête disponible | Fact prérequis | PNJ ou marker de quête visible | Démarrer la quête | Si le rival est battu, rendre visible l’entrée de quête annexe. |
| Indice affiché | Fact ou Step active | Hint, marker ou label futur | Forcer la progression | Si l’étape active est “Aller au port”, montrer un hint portuaire. |
| État visuel | Fact, Step ou variable lisible | Sprite, animation idle, couleur, décor | Écrire l’état technique | Si le phare est rallumé, afficher la lumière. |
| Passage autorisé ou bloqué | Fact ou état dérivé | Blocage, message, porte, collision future | Devenir un Door Engine complet | Si la clé manque, la porte reste bloquée. |

Exemple correct :

```text
Si “Le rival a été battu au port”, alors Lysa utilise un dialogue post-combat.
```

Exemple incorrect :

```text
Si “Le rival a été battu au port”, alors lancer directement la Scene de quête annexe.
```

Dans l’exemple incorrect, la World Rule agit comme Event. La version correcte
rend disponible l’entrée de la quête ; un Event séparé déclenche la Scene quand
le joueur interagit.

## 13. World Rule — cycle de vie produit

Cycle canonique :

1. Un Fact ou état GameState existe.
2. Une World Rule lit cet état.
3. Elle choisit une projection visible.
4. Le runtime ou l’éditeur applique cette projection.
5. Si l’état change, la projection change.
6. Le Validator peut diagnostiquer les règles cassées ou ambiguës.

Règles de cycle de vie :

- World Rule n’a pas de mémoire propre par défaut ;
- World Rule ne consomme pas un Event ;
- World Rule ne produit pas de Fact ;
- World Rule ne complète pas une Step ;
- World Rule ne déclenche pas une Scene ;
- World Rule doit être recalculable après mutation et save/load ;
- World Rule doit pouvoir être expliquée : “cet élément est visible parce que…”.

## 14. Matrice Fact / World Rule / Event / Scene

| Responsabilité | Fact | World Rule | Event | Scene | Commentaire |
|---|---|---|---|---|---|
| Représenter une vérité persistante | Oui | Non | Non | Non | Le Fact nomme l’état, il ne l’exécute pas. |
| Lire une vérité | Non actif | Oui | Oui | Oui | Fact n’est pas un lecteur, c’est la vérité lue. |
| Écrire une vérité | Non | Non | Non par défaut | Oui | La Scene est le lieu recommandé pour les conséquences. |
| Déclencher une Scene | Non | Non | Oui | Peut continuer | World Rule ne déclenche jamais. |
| Projeter une visibilité | Non | Oui | Non | Non directement | Scene écrit l’état ; World Rule le montre. |
| Changer un dialogue | Non | Oui | Non | Peut orchestrer | Dialogue conditionnel est une projection. |
| Compléter un Story Step | Non | Non | Non par défaut | Oui | Step completion est conséquence orchestrée. |
| Brancher selon outcome | Non | Non | Non | Oui | Yarn/Battle produisent, Scene interprète. |
| Lancer Battle | Non | Non | Non | Oui | Battle reste gameplay, Scene orchestre. |
| Déplacer caméra | Non | Non | Non | Via Cinematic | Hors responsabilité Fact/World Rule. |
| Diagnostiquer cohérence | Non | Non | Non | Non | Validator diagnostique l’ensemble. |
| Corriger automatiquement | Non | Non | Non | Non | Aucun de ces concepts ne fait d’auto-fix. |

## 15. Relation avec Story Step, Storyline et Chapter

Story Step et Fact peuvent se ressembler, mais ils n’ont pas le même rôle.

```text
Story Step = jalon de progression.
Fact = vérité lisible que d’autres systèmes peuvent lire.
```

Exemple :

```text
Story Step : Battre le rival au port.
Fact : Le rival a été battu au port.
```

Différence :

| Concept | Rôle |
|---|---|
| Storyline | Organise une ligne narrative cohérente. |
| Chapter | Organise une section de progression. |
| Story Step | Décrit un jalon à accomplir. |
| Fact | Mémorise ou expose une vérité lisible. |
| World Rule | Projette cette vérité dans le monde visible. |

Un Story Step terminé peut produire un Fact dérivé, mais il ne faut pas les
confondre automatiquement. P1-04 devra décider comment les Steps, Chapters et
Storylines s’exposent comme truths lisibles dans l’éditeur.

## 16. Relation avec Dialogue Yarn

Yarn produit des dialogues et des outcomes.

Règle P1-03 :

```text
Yarn produit un résultat.
Scene décide si ce résultat devient un Fact.
```

Exemple temporaire :

```text
Le joueur choisit “confident”.
La Scene joue immédiatement une variation de cinematic.
Le choix n’a plus d’effet ensuite.
```

Dans ce cas, l’outcome peut rester temporaire.

Exemple durable :

```text
Le joueur choisit “confident”.
Plus tard, Lysa réagit à cette attitude.
```

Dans ce cas, la Scene peut écrire :

```text
Le joueur a choisi une réponse confiante.
```

Anti-pattern :

```text
Yarn écrit directement une soupe de flags invisibles.
```

Le dialogue ne doit pas devenir le moteur caché de progression. Il peut produire
un outcome ; la Scene l’interprète.

## 17. Relation avec Battle

Battle produit un outcome gameplay. Scene interprète cet outcome dans la
narration.

Règle P1-03 :

```text
Battle résout.
Scene décide ce que le monde doit retenir.
```

Exemples :

- Victory contre rival → Fact : Le rival a été battu au port.
- Defeat contre rival → Fact possible : Le joueur a perdu contre le rival.
- Capture static future → Fact possible : Le Pokémon du phare a été apaisé.

Limites :

- Battle ne décide pas seul de la progression narrative ;
- Battle ne doit pas écrire directement les Facts narratifs principaux ;
- NS-GS-17 prouve un boss trainer-like Level 2, pas un static wild authorable
  complet ;
- NS-GS-18 prouve un item reward post-battle via Scene, pas un reward engine.

## 18. Relation avec GameState et flags techniques

Fact est un langage produit. GameState, flags et variables sont des stockages
techniques possibles.

Distinctions :

| Terme | Sens |
|---|---|
| Fact utilisateur | Phrase lisible : “Le joueur possède la clé du phare.” |
| Fact technique canonique futur | Représentation stable éventuelle dans un registre. |
| Flag technique existant | Clé dans `storyFlags.activeFlags`. |
| Variable technique | Valeur typée, souvent non narrative. |
| État dérivé | Vérité calculée depuis Bag, Step, trainer state ou autre GameState. |

Stratégie conceptuelle :

- un Fact visible dans l’éditeur doit avoir un label humain ;
- il peut mapper vers un flag technique existant ;
- il peut mapper vers un état déjà présent ;
- il peut être dérivé plutôt que stocké ;
- le Validator doit pouvoir expliquer la relation ;
- P1-03 ne crée pas ce mapping.

Exemple :

```text
Label : Le joueur possède la clé du phare.
Storage possible : Bag contient lighthouse_key.
Fact type : dérivé.
Usage : World Rule porte du phare ouverte.
```

Cette représentation évite de créer à la fois un item, un flag et un Fact stocké
qui pourraient se désynchroniser.

## 19. Relation avec Validator

Le Validator diagnostique. Il n’exécute pas, ne mute pas et ne corrige pas
automatiquement.

Diagnostics futurs utiles :

- Fact référencé mais jamais écrit ;
- Fact écrit mais jamais lu ;
- Fact inconnu ;
- Fact dupliqué avec labels différents ;
- Fact technique exposé sans label humain ;
- World Rule sans condition ;
- World Rule condition impossible ;
- World Rule cible entité absente ;
- World Rule cible dialogue absent ;
- World Rule cible map absente ;
- World Rule conflit avec une autre règle ;
- World Rule utilisée comme Event ;
- Event lit un Fact non déclaré ;
- Scene écrit un Fact non déclaré ;
- Yarn outcome jamais transformé alors qu’il est marqué durable ;
- Battle outcome non traité par Scene.

Le Validator doit expliquer :

```text
Cette règle du monde ne peut pas fonctionner parce qu’elle lit un fait qui n’est jamais produit.
```

Il ne doit pas décider :

```text
Je crée automatiquement le Fact manquant.
```

## 20. Mapping vers l’existant

Le mapping ci-dessous est prudent. Il ne transforme pas le Level 2 Application en
validation produit complète.

| Existant | Lecture produit P1-03 | Statut | Limite |
|---|---|---:|---|
| `storyFlags.activeFlags` | Stockage technique actuel possible pour Facts | ⚠️ Partiel / prouvé Level 1-2 | Pas de label humain ni registre de facts. |
| `completedStepIds` | Step completion lisible comme Fact dérivé | ✅ Prouvé Level 1-2 | Step ≠ Fact ; P1-04 doit clarifier. |
| `scenario.outcome.*` | Outcome technique qui peut devenir Fact durable | ⚠️ Partiel | Ce sont des flags techniques, pas un langage no-code. |
| `MapEntityRuntimePredicateEvaluator` | Évaluation passive pour World Rules presence/dialogue | ✅ Prouvé Level 1-2 | Projection surtout NPC/dialogue, pas registre global. |
| Conditional presence/dialogue | World Rule V0 concrète | ✅ Prouvé Level 1-2 | Pas encore UI no-code complète. |
| `giveItem` / pickup | Action Scene + Bag + fact/step possible | ✅ Prouvé Level 2 | Anti double pickup par fact/condition, pas item engine. |
| Key item door gate | Item clé → fact dérivé → gate | ⚠️ Partiel | `hasItem` direct absent ; Door Engine absent. |
| Side quest optional pattern | Facts/steps/scenes/world rules suffisent pour V0 | ✅ Prouvé Level 2 | Pas de Quest Engine / Quest Journal. |
| Post-battle reward via Scene | Outcome → continuation → giveItem/fact/step | ✅ Prouvé Level 2 | Pas de reward model money/XP. |
| Narrative Validator V0 | Diagnostics structurels flags/steps/scenarios | ⚠️ Partiel | Pas de FactRegistry / WorldRuleRegistry diagnostics. |
| PlayableMapGame Golden Slice complet | Runtime Flame complet | ❌ Non prouvé | NS-GS reste surtout Level 2. |
| Disk project editor-created | Projet disque réel | ❌ Non prouvé | Phase future. |

Lecture critique :

- l’existant prouve que le GameState peut porter des vérités techniques ;
- l’existant prouve que des règles passives peuvent lire ces vérités ;
- l’existant ne prouve pas encore une grammaire auteur complète de Facts ;
- l’existant ne prouve pas encore un système centralisé de World Rules ;
- P1-03 prépare les mots avant de demander à Phase 2 de créer les contrats.

## 21. Mapping Selbrume illustratif

Mapping conceptuel, non créé dans le dépôt :

```text
Scene “Rencontre rival”
→ battle victory
→ Fact : “Le rival a été battu au port”
→ Story Step : “Battre le rival au port” terminé
→ World Rule : Lysa utilise son dialogue post-combat
→ World Rule : une quête annexe devient visible
→ Event futur : interaction avec Lysa peut maintenant lancer une autre Scene
```

Clarification importante :

```text
La World Rule ne lance pas la quête annexe.
Elle rend visible ou disponible l’entrée vers cette quête.
Un Event séparé déclenchera la Scene quand le joueur interagit.
```

Autre exemple conceptuel :

```text
Scene “Obtention clé du phare”
→ giveItem clé du phare
→ Fact dérivé : “Le joueur possède la clé du phare”
→ World Rule : la porte du phare apparaît ouverte ou interactable
→ Event porte : interaction lance la Scene ou action de passage
```

Aucun contenu Selbrume final n’est créé par P1-03. Ces noms servent uniquement
à tester la grammaire produit.

## 22. Vocabulaire utilisateur recommandé

| Concept produit | Libellé utilisateur recommandé | Libellés possibles en mode avancé |
|---|---|---|
| Fact | Fait du monde | Fact |
| Fact write | Marquer un fait | setFlag / mutation |
| Fact read | Vérifier un fait | condition |
| Derived Fact | Fait déduit | derived fact |
| Technical flag | Stockage technique | flag / storyFlags |
| World Rule | Règle du monde | projection rule |
| Projection | Changement visible | runtime projection |
| Condition | Condition | predicate |
| Visibility Rule | Règle de visibilité | visibility predicate |
| Dialogue Rule | Règle de dialogue | conditional dialogue |
| Interaction Rule | Règle d’interaction | interaction predicate |

Termes à éviter dans le flux auteur normal :

- `flag`
- `storyFlags`
- `activeFlags`
- `predicate`
- `runtime predicate`
- `mutation`
- `variable`
- `scenario.outcome.*`
- `boolean`

Ces termes peuvent rester utiles dans :

- documentation technique ;
- mode debug ;
- panneau avancé ;
- diagnostics détaillés ;
- migration ou support.

Mais le flux auteur principal doit parler de :

```text
faits du monde, conditions, conséquences et changements visibles.
```

## 23. Anti-patterns interdits

Anti-patterns Facts :

- Fact exposé comme flag technique brut ;
- Fact nommé avec un ID moteur au lieu d’une phrase humaine ;
- Fact stocké en double alors qu’il existe déjà comme Step ou item state ;
- Fact jamais écrit mais utilisé partout ;
- Fact écrit mais jamais lu ;
- Fact créé pour masquer un outcome temporaire qui ne sert plus ;
- Scene qui écrit des flags techniques sans label produit ;
- Yarn qui écrit directement tous les Facts ;
- Battle qui décide seul des Facts narratifs ;
- `FactRegistry` codé trop tôt pendant Phase 1.

Anti-patterns World Rules :

- World Rule qui déclenche une Scene ;
- World Rule qui écrit un Fact ;
- World Rule qui complète un Story Step ;
- World Rule qui devient Event ;
- World Rule qui contient un branching narratif ;
- World Rule qui donne un item ;
- World Rule qui lance Battle ;
- World Rule qui corrige automatiquement l’état ;
- `WorldRuleRegistry` codé trop tôt pendant Phase 1.

Anti-patterns de validation :

- Validator qui corrige automatiquement ;
- Validator qui masque l’ID technique sans offrir de diagnostic utile ;
- Validator qui accepte une World Rule sans source lisible ;
- Validator qui ne sait pas expliquer pourquoi un élément est visible.

## 24. Impacts attendus pour P1-04 et Phase 2

P1-04 devra traiter :

```text
Storyline / Chapter / Story Step Structure
```

P1-03 prépare P1-04 en clarifiant :

- différence entre Story Step et Fact ;
- différence entre progression narrative et vérité du monde ;
- comment une Storyline peut produire ou lire des Facts ;
- comment une side quest devient disponible sans World Rule active ;
- comment le Validator peut vérifier steps/facts.

Phase 2 devra potentiellement transformer P1-03 en :

- contrat Fact ;
- registry Fact ou couche de présentation Fact ;
- contrat World Rule ;
- diagnostics World Rule ;
- mapping GameState / flags / variables ;
- références validables dans Event / Scene / World Rule ;
- relations avec `ScenarioAsset` ;
- relations avec `MapEntityRuntimePredicateEvaluator`.

Recommandation Phase 2 :

```text
Ne créer un FactRegistry ou WorldRuleRegistry que si les consumers sont clairs :
editor, runtime, validator, persistence, migration et tests.
```

## 25. Mise à jour de road_map_phase_1.md

`MVP Selbrume/road_map_phase_1.md` est mis à jour pour :

- marquer `P1-03 — Fact & World Rule Product Grammar` comme terminé ;
- marquer `P1-04 — Storyline / Chapter / Story Step Structure` comme prochain
  lot exact ;
- ajouter un résumé court du résultat ;
- lister les fichiers créés et modifiés ;
- lister les commandes exécutées ;
- confirmer qu’aucune décision utilisateur nouvelle ni changement de périmètre
  n’a été introduit.

`MVP Selbrume/road_map_global.md` n’est pas modifié.

## 26. Décisions à valider par l’utilisateur

Décisions produit à valider plus tard :

1. Faut-il exposer “Fact” comme “Fait du monde” dans toute l’UI ?
2. Faut-il autoriser des Facts dérivés ou seulement des Facts stockés ?
3. Un Story Step terminé doit-il apparaître automatiquement comme Fact dérivé ?
4. Une possession d’objet clé doit-elle être présentée comme Fact dérivé ?
5. World Rule doit-elle s’appeler “Règle du monde”, “Règle visible” ou
   “Règle d’état” ?
6. Une World Rule peut-elle modifier l’interactabilité ou seulement la
   présence/dialogue ?
7. Faut-il un mode auteur qui montre l’ID technique derrière un Fact ?
8. Phase 2 doit-elle créer un registre central dès le début ou d’abord une
   couche de présentation au-dessus des états existants ?

Aucune de ces décisions ne bloque P1-04. Elles devront surtout guider Phase 2 et
les workflows no-code futurs.

## 27. Evidence Pack

### 27.1 git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
Sortie vide — aucun changement détecté au début du lot.
```

### 27.2 Fichiers lus

```text
AGENTS.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_1.md
reports/roadmap/pokemap_full_product_phased_roadmap_v1.md
reports/roadmap/roadmap_global_00_master_phase_roadmap_bootstrap.md
reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md
reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md
MVP Selbrume/road_map.md
MVP Selbrume/narrative_studio.md
MVP Selbrume/selbrume.md
reports/gameplay/audit/narrative_studio_product_model_v0.md
reports/gameplay/audit/sel_a2_event_scene_outcome_fact_contract.md
reports/gameplay/ns_gs/ns_gs_09_yarn_outcome_scene_branch_readiness.md
reports/gameplay/ns_gs/ns_gs_10_world_rules_conditional_presence_readiness.md
reports/gameplay/ns_gs/ns_gs_12_bis_evidence_pack_and_level_label_fix.md
reports/gameplay/ns_gs/ns_gs_13_narrative_validator_minimal_v0.md
reports/gameplay/ns_gs/ns_gs_14_item_pickup_give_item_authoring_readiness.md
reports/gameplay/ns_gs/ns_gs_15_key_item_door_gate_readiness.md
reports/gameplay/ns_gs/ns_gs_16_side_quest_optional_storyline_readiness.md
reports/gameplay/ns_gs/ns_gs_17_static_encounter_boss_battle_readiness.md
reports/gameplay/ns_gs/ns_gs_18_reward_money_xp_bridge_audit.md
reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md
```

### 27.3 Fichiers créés

```text
reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md
```

### 27.4 Fichiers modifiés

```text
MVP Selbrume/road_map_phase_1.md
```

### 27.5 Commandes exécutées

```text
git status --short --untracked-files=all
sed -n '1,260p' "MVP Selbrume/road_map_global.md"
sed -n '1,560p' "MVP Selbrume/road_map_phase_1.md"
sed -n '1,260p' reports/roadmap/pokemap_full_product_phased_roadmap_v1.md
sed -n '1,260p' reports/roadmap/roadmap_global_00_master_phase_roadmap_bootstrap.md
sed -n '1,220p' reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md
sed -n '1,520p' reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
sed -n '521,1120p' reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
sed -n '1,520p' reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md
sed -n '521,1200p' reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md
sed -n '1,260p' "MVP Selbrume/road_map.md"
sed -n '1,260p' "MVP Selbrume/narrative_studio.md"
sed -n '1,220p' "MVP Selbrume/selbrume.md"
sed -n '1,260p' reports/gameplay/audit/narrative_studio_product_model_v0.md
sed -n '1,260p' reports/gameplay/audit/sel_a2_event_scene_outcome_fact_contract.md
sed -n '1,280p' reports/gameplay/ns_gs/ns_gs_09_yarn_outcome_scene_branch_readiness.md
sed -n '1,300p' reports/gameplay/ns_gs/ns_gs_10_world_rules_conditional_presence_readiness.md
sed -n '1,300p' reports/gameplay/ns_gs/ns_gs_12_bis_evidence_pack_and_level_label_fix.md
sed -n '1,320p' reports/gameplay/ns_gs/ns_gs_13_narrative_validator_minimal_v0.md
sed -n '1,300p' reports/gameplay/ns_gs/ns_gs_14_item_pickup_give_item_authoring_readiness.md
sed -n '1,300p' reports/gameplay/ns_gs/ns_gs_15_key_item_door_gate_readiness.md
sed -n '1,320p' reports/gameplay/ns_gs/ns_gs_16_side_quest_optional_storyline_readiness.md
sed -n '1,340p' reports/gameplay/ns_gs/ns_gs_17_static_encounter_boss_battle_readiness.md
sed -n '1,340p' reports/gameplay/ns_gs/ns_gs_18_reward_money_xp_bridge_audit.md
sed -n '1,340p' reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md
wc -l reports/gameplay/audit/narrative_studio_product_model_v0.md reports/gameplay/audit/sel_a2_event_scene_outcome_fact_contract.md reports/gameplay/ns_gs/ns_gs_09_yarn_outcome_scene_branch_readiness.md reports/gameplay/ns_gs/ns_gs_10_world_rules_conditional_presence_readiness.md reports/gameplay/ns_gs/ns_gs_12_bis_evidence_pack_and_level_label_fix.md reports/gameplay/ns_gs/ns_gs_13_narrative_validator_minimal_v0.md reports/gameplay/ns_gs/ns_gs_14_item_pickup_give_item_authoring_readiness.md reports/gameplay/ns_gs/ns_gs_15_key_item_door_gate_readiness.md reports/gameplay/ns_gs/ns_gs_16_side_quest_optional_storyline_readiness.md reports/gameplay/ns_gs/ns_gs_17_static_encounter_boss_battle_readiness.md reports/gameplay/ns_gs/ns_gs_18_reward_money_xp_bridge_audit.md reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md
rg -n "P1-03|P1-04|Prochain lot exact|Historique|Lot courant|Statut|Fichiers créés|Fichiers modifiés|Commandes exécutées|Décisions utilisateur|Changements de périmètre" "MVP Selbrume/road_map_phase_1.md"
sed -n '1,140p' "MVP Selbrume/road_map_phase_1.md"
sed -n '140,360p' "MVP Selbrume/road_map_phase_1.md"
sed -n '360,620p' "MVP Selbrume/road_map_phase_1.md"
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff --no-index --check /dev/null reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md || true
git diff -- "MVP Selbrume/road_map_phase_1.md"
git diff -- "MVP Selbrume/road_map_global.md"
wc -l reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md "MVP Selbrume/road_map_phase_1.md" "MVP Selbrume/road_map_global.md"
perl -pi -e 's/[ \t]+$//' reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md
rg -n "FactRegistry|WorldRuleRegistry|P1-04 — Storyline" reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md "MVP Selbrume/road_map_phase_1.md"
```

### 27.6 git diff --check

```text
Sortie vide — aucune erreur détectée.
```

### 27.7 git diff --stat

```text
 MVP Selbrume/road_map_phase_1.md | 36 ++++++++++++++++++++++++++----------
 1 file changed, 26 insertions(+), 10 deletions(-)
```

### 27.8 git diff --name-only

```text
MVP Selbrume/road_map_phase_1.md
```

### 27.9 git status final

```text
 M "MVP Selbrume/road_map_phase_1.md"
?? reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md
```

### 27.10 Tests / analyze

```text
Non exécutés — P1-03 est documentaire et ne modifie aucun code.
```

### 27.11 git diff --no-index --check du rapport P1-03

```text
Sortie vide — aucune erreur détectée.
```

### 27.12 Diff de road_map_phase_1.md

```diff
diff --git a/MVP Selbrume/road_map_phase_1.md b/MVP Selbrume/road_map_phase_1.md
index a5fb47e9..c5cb0e7b 100644
--- a/MVP Selbrume/road_map_phase_1.md
+++ b/MVP Selbrume/road_map_phase_1.md
@@ -6,17 +6,17 @@ Phase 1 — Canonical Product Model / Narrative Studio Foundations

 Statut : 🔜 En préparation

-Lot courant : P1-02 — Event / Scene / Cinematic Boundary Contract
+Lot courant : P1-03 — Fact & World Rule Product Grammar

-Prochain lot exact après P1-02 : P1-03 — Fact & World Rule Product Grammar
+Prochain lot exact après P1-03 : P1-04 — Storyline / Chapter / Story Step Structure

 Suivi des lots :

 - ✅ P1-00 — Phase 1 Roadmap Bootstrap
 - ✅ P1-01 — Canonical Narrative Product Model V1
 - ✅ P1-02 — Event / Scene / Cinematic Boundary Contract
-- 🔜 P1-03 — Fact & World Rule Product Grammar
-- P1-04 — Storyline / Chapter / Story Step Structure
+- ✅ P1-03 — Fact & World Rule Product Grammar
+- 🔜 P1-04 — Storyline / Chapter / Story Step Structure
 - P1-05 — Selbrume Reference Grammar Mapping
 - P1-06 — No-code Workflow Specification
 - P1-07 — Phase 2 Domain Contract Proposal
@@ -28,7 +28,9 @@ P1-01 : ✅ terminé

 P1-02 : ✅ terminé

-P1-03 : 🔜 prochain lot exact
+P1-03 : ✅ terminé
+
+P1-04 : 🔜 prochain lot exact

 ## 2. Objectif de la Phase 1

@@ -221,7 +223,7 @@ Critères de validation :
 - la relation avec Yarn, Battle, Fact et World Rule est clarifiée ;
 - les besoins Phase 2 sont bornés.

-### 🔜 P1-03 — Fact & World Rule Product Grammar
+### ✅ P1-03 — Fact & World Rule Product Grammar

 Objectif :
 Définir Fact comme vérité lisible et World Rule comme projection passive.
@@ -248,7 +250,7 @@ Critères de validation :
 - les erreurs World Rule ≠ Event et Fact ≠ flag technique sont traitées ;
 - les besoins de validation future sont listés.

-### P1-04 — Storyline / Chapter / Story Step Structure
+### 🔜 P1-04 — Storyline / Chapter / Story Step Structure

 Objectif :
 Définir la structure Storyline / Chapter / Story Step et le statut des side quests.
@@ -392,12 +394,13 @@ Critères de validation :

 ## 10. Prochain lot exact

-P1-03 — Fact & World Rule Product Grammar
+P1-04 — Storyline / Chapter / Story Step Structure

 Objectif du prochain lot :
-Définir Fact comme vérité lisible et World Rule comme projection passive.
+Définir la structure Storyline / Chapter / Story Step et le statut des side
+quests.

-P1-03 ne doit pas créer de code, de modèles `map_core`, d’UI, de fixtures
+P1-04 ne doit pas créer de code, de modèles `map_core`, d’UI, de fixtures
 Selbrume finales ou de `project.json`.

 ## 11. Critères de sortie de Phase 1
@@ -491,3 +494,16 @@ P1-CHECKPOINT-01 devra aussi mettre à jour
   Décisions utilisateur nouvelles : aucune.
   Changements de périmètre : aucun.
   Prochain lot exact fixé à P1-03 — Fact & World Rule Product Grammar.
+- 2026-05-24 — P1-03 — Fact & World Rule Product Grammar terminé.
+  Résultat : grammaire produit stricte Fact = vérité lisible / World Rule =
+  projection passive, avec nommage no-code, cycle de vie des facts, types de
+  projections visibles et mapping prudent vers l’existant.
+  Fichiers créés : `reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md`.
+  Fichiers modifiés : `MVP Selbrume/road_map_phase_1.md`.
+  Commandes exécutées : lectures Markdown ciblées,
+  `git status --short --untracked-files=all`, `git diff --check`,
+  `git diff --stat`, `git diff --name-only`, `git diff --no-index --check`,
+  `wc -l`.
+  Décisions utilisateur nouvelles : aucune.
+  Changements de périmètre : aucun.
+  Prochain lot exact fixé à P1-04 — Storyline / Chapter / Story Step Structure.
```

### 27.13 Vérification road_map_global.md

Commande :

```bash
git diff -- "MVP Selbrume/road_map_global.md"
```

Sortie exacte :

```text
Sortie vide — aucun changement dans road_map_global.md.
```

### 27.14 Comptage de lignes final

```text
    1385 reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md
     509 MVP Selbrume/road_map_phase_1.md
     638 MVP Selbrume/road_map_global.md
    2532 total
```

### 27.15 Preuve des fichiers attendus uniquement

Les changements P1-03 attendus sont :

```text
MVP Selbrume/road_map_phase_1.md
reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md
```

La preuve finale est donnée par `git diff --name-only` et `git status final`
ci-dessus.

## 28. Auto-review critique

### Auto-review

| Question | Réponse |
|---|---|
| Le lot a-t-il modifié uniquement ce qui était autorisé ? | Oui, uniquement le rapport P1-03 et la roadmap Phase 1. |
| Le rapport P1-03 existe-t-il au bon chemin ? | Oui : `reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md`. |
| `road_map_phase_1.md` a-t-elle été mise à jour ? | Oui, P1-03 terminé et P1-04 prochain lot exact. |
| `road_map_global.md` est-elle restée intacte ? | Oui, elle est lue mais non modifiée. |
| Aucun code n’a-t-il été modifié ? | Oui, aucun fichier sous `packages/` ou `examples/` n’est modifié. |
| Aucun test/analyze Dart/Flutter n’a-t-il été lancé inutilement ? | Oui, non exécutés car P1-03 est documentaire. |
| P1-04 n’a-t-il pas été commencé ? | Oui, P1-04 est seulement mentionné comme prochain lot exact. |
| Selbrume est-il resté une référence conceptuelle seulement ? | Oui, aucun contenu Selbrume final n’est créé. |
| Les frontières Fact / World Rule sont-elles assez strictes ? | Oui : Fact nomme une vérité, World Rule projette passivement. |
| Le rapport évite-t-il d’exposer Fact comme flag technique ? | Oui, les flags sont décrits comme stockage technique possible. |
| Le rapport évite-t-il de transformer World Rule en Event ? | Oui, World Rule ne déclenche pas de Scene. |

Ambiguïtés restantes à valider :

- nom UI final de Fact : “Fait du monde” ou autre ;
- place des Facts dérivés dans la future UX ;
- niveau d’exposition des IDs techniques en mode avancé ;
- portée initiale des World Rules : présence/dialogue seulement ou
  interactabilité/porte/pickup dès Phase 2 ;
- nécessité ou non d’un registre central dès les premiers contrats Phase 2.

### Regard critique sur le prompt

Le prompt est volontairement strict et protège bien le périmètre documentaire. La
principale ambiguïté concerne la notion de “lire” de longs rapports NS-GS :
certains documents sont très volumineux, donc P1-03 s’appuie sur les sections
pertinentes aux facts, world rules, flags, steps, gates, side quests, rewards et
validator. Cette limite ne change pas le scope et ne justifie aucune
implémentation.
