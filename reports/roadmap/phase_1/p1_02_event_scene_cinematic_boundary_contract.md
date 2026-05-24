# P1-02 — Event / Scene / Cinematic Boundary Contract

## 1. Résumé exécutif

P1-02 transforme la règle courte de P1-01 en contrat produit strict :

```text
Event déclenche.
Scene orchestre.
Cinematic met en scène.
```

Le lot ne crée aucun code, aucun modèle `map_core`, aucun schéma JSON, aucune UI
et aucun contenu Selbrume. Il définit uniquement les frontières à respecter pour
la suite de la Phase 1 et pour les futurs contrats de Phase 2.

Frontière proposée :

- Event = `Quand / Si` : il observe une source de déclenchement, lit des
  conditions d’entrée simples et choisit quoi lancer.
- Scene = `Alors / Puis` : elle orchestre l’ordre des blocs, les dialogues, les
  cinématiques, les combats, les outcomes et les conséquences persistantes.
- Cinematic = `Montrer / Attendre / Mettre en scène` : elle joue une séquence
  linéaire de présentation, puis rend la main à la Scene.

Ce qu’un Event peut faire :

- matcher une interaction, une zone, une entrée de map, un pickup, une fin de
  combat, un outcome ou une autre source déclarée ;
- lire des conditions d’entrée simples ;
- lancer une Scene, un message simple ou une action très bornée ;
- porter une politique de répétition ou de consommation.

Ce qu’une Scene peut faire :

- ordonner plusieurs blocs ;
- lancer Dialogue Yarn, Cinematic et Battle ;
- lire les outcomes produits par Yarn ou Battle ;
- brancher selon ces outcomes ;
- écrire les Facts et compléter les Story Steps ;
- décider des continuations et de la fin du flow.

Ce qu’une Cinematic peut faire :

- déplacer caméra ou personnages ;
- jouer animations, pauses, regards, sons, transitions et effets ;
- verrouiller ou rendre les contrôles si nécessaire ;
- retourner “terminée” à la Scene.

Ce qu’elle ne doit pas faire :

- décider seule de la progression narrative ;
- écrire librement des Facts ;
- compléter directement des Story Steps ;
- contenir un branching complexe ;
- remplacer une Scene.

Hors scope :

- aucun modèle technique ;
- aucun diagnostic implémenté ;
- aucun test ;
- aucune validation Dart/Flutter ;
- aucun contenu final Selbrume ;
- P1-03 non démarré.

Prochain lot exact :

```text
P1-03 — Fact & World Rule Product Grammar
```

## 2. Scope du lot

Inclus :

- lire les roadmaps et rapports demandés ;
- durcir les frontières Event / Scene / Cinematic ;
- définir les responsabilités, entrées, sorties et limites de chaque concept ;
- établir une matrice de responsabilité ;
- clarifier les relations avec Dialogue Yarn, Battle, Fact, Story Step,
  World Rule et Validator ;
- mapper prudemment vers l’existant NS-GS sans sur-vendre le niveau de preuve ;
- utiliser Selbrume uniquement comme exemple conceptuel ;
- mettre à jour `MVP Selbrume/road_map_phase_1.md` ;
- fournir un Evidence Pack.

Exclus :

- code de production ;
- fichiers Dart ;
- tests ;
- analyze Dart/Flutter ;
- package `map_core`, `map_gameplay`, `map_battle`, `map_runtime`,
  `map_editor` ou `examples/playable_runtime_host` ;
- création de modèle Event / Scene / Cinematic ;
- schéma JSON ;
- build_runner ;
- UI ;
- Selbrume final ;
- `project.json` Selbrume ;
- modification de `MVP Selbrume/road_map_global.md` ;
- P1-03 ou tout lot suivant.

Fichiers créés :

- `reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md`

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

Roadmaps et cadrages Phase 1 :

- `MVP Selbrume/road_map_global.md` — gouvernance globale par phases et règle
  de non-modification hors checkpoint.
- `MVP Selbrume/road_map_phase_1.md` — roadmap vivante de la Phase 1, statut
  P1-02 et prochain lot.
- `reports/roadmap/pokemap_full_product_phased_roadmap_v1.md` — proposition
  stratégique, niveau de preuve réel et phases 0 à 7.
- `reports/roadmap/roadmap_global_00_master_phase_roadmap_bootstrap.md` —
  création de la roadmap globale vivante.
- `reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md` — création de
  la roadmap Phase 1.
- `reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md` —
  dictionnaire canonique P1-01 et définitions de départ.
- `MVP Selbrume/road_map.md` — roadmap historique NS-GS et rappel
  mechanics-first.

Documents produit :

- `MVP Selbrume/narrative_studio.md` — vision Narrative Studio et anciens
  points de confusion Global Story / Step / Cutscene / Scene / Fact.
- `MVP Selbrume/selbrume.md` — scénario de référence, lu uniquement pour le
  mapping conceptuel.
- `AGENTS.md` — boundaries repo, Git safety, no-code first et evidence.

Rapports NS-GS / audits utiles :

- `reports/gameplay/audit/narrative_studio_product_model_v0.md` — grammaire
  “Quand / Si / Alors / Puis” et critique des flags bruts.
- `reports/gameplay/audit/sel_a2_event_scene_outcome_fact_contract.md` —
  pipeline Event → Scene → Dialogue / Cinematic / Battle → Fact / Step.
- `reports/gameplay/audit/sel_b2_battle_from_scene.md` — pont Scene → Battle
  et continuation post-combat.
- `reports/gameplay/ns_gs/ns_gs_08_npc_interaction_scene_authoring_readiness.md`
  — entity/NPC interaction → scene.
- `reports/gameplay/ns_gs/ns_gs_09_yarn_outcome_scene_branch_readiness.md` —
  Yarn outcome → Scene branch.
- `reports/gameplay/ns_gs/ns_gs_10_world_rules_conditional_presence_readiness.md`
  — World Rule passive, présence et dialogue conditionnel.
- `reports/gameplay/ns_gs/ns_gs_11_trainer_battle_authoring_readiness.md` —
  Scene → Trainer Battle → Outcome → continuation.
- `reports/gameplay/ns_gs/ns_gs_12_bis_evidence_pack_and_level_label_fix.md`
  — rappel que le Golden Slice NS-GS est Level 2 Application, pas Level 3/4.
- `reports/gameplay/ns_gs/ns_gs_13_narrative_validator_minimal_v0.md` —
  Validator V0 comme diagnostic statique.
- `reports/gameplay/ns_gs/ns_gs_17_static_encounter_boss_battle_readiness.md`
  — boss trainer-like authorable, static wild réel non prouvé.
- `reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md`
  — synthèse des niveaux de preuve et gaps restants.

## 4. Rappel P1-01

P1-01 a défini le modèle produit canonique :

- Storyline = ligne narrative cohérente.
- Chapter = grande section de progression.
- Story Step = jalon clair et validable.
- Event = déclenche.
- Scene = orchestre.
- Cinematic = met en scène linéairement.
- Dialogue Yarn = dialogue + choix + outcomes.
- Fact = vérité lisible du monde.
- World Rule = projection passive du GameState.
- Validator = diagnostique.

P1-02 ne redéfinit pas tout P1-01. Il durcit seulement la frontière entre
Event, Scene et Cinematic, parce que c’est l’endroit où le produit risque le
plus de mélanger déclenchement, orchestration et présentation.

Rappel strict :

```text
Event déclenche.
Scene orchestre.
Cinematic met en scène linéairement.
Yarn produit des outcomes.
Fact persiste une vérité lisible.
World Rule projette passivement.
Validator diagnostique.
```

## 5. Problème à résoudre

La confusion Event / Scene / Cinematic crée trois risques.

Premier risque : l’Event devient une mini-Scene.

Si l’Event contient dialogue, combat, branches, rewards et écritures de Facts,
il devient un script caché attaché à une entité ou une zone. Le créateur ne sait
plus si la logique narrative vit dans le déclencheur ou dans la Scene. Le
Validator doit alors inspecter des logiques dispersées.

Deuxième risque : la Scene devient seulement une cutscene.

Si une Scene est comprise comme “ce qu’on voit à l’écran”, elle perd son rôle
d’orchestrateur. Les dialogues, combats, outcomes et conséquences durables
risquent d’être déplacés ailleurs, souvent dans Yarn ou dans des flags
techniques.

Troisième risque : la Cinematic écrit la progression.

Si une Cinematic pose directement les Facts, complète les Steps et décide des
branches, la progression devient invisible. Un auteur no-code peut regarder une
Scene et ne pas voir pourquoi une étape se termine. Un Validator peut voir une
cinématique jouée, mais pas comprendre la logique produit.

Le risque no-code est très concret : une personne non développeuse doit pouvoir
distinguer quatre questions.

```text
Qu’est-ce qui déclenche ?
Qu’est-ce qui se joue ?
Qu’est-ce qui est mis en scène ?
Qu’est-ce qui persiste ?
```

Si ces questions sont mélangées, le Narrative Studio redevient un éditeur de
scripts et de flags.

## 6. Principe de séparation

Règle simple :

```text
Event = Quand / Si.
Scene = Alors / Puis.
Cinematic = Montrer / Attendre / Mettre en scène.
```

Décomposition :

- Event choisit le point d’entrée.
- Event peut filtrer avec des conditions d’entrée simples.
- Event décide quelle Scene, quel message ou quelle action bornée lancer.
- Scene décide l’enchaînement.
- Scene interprète les outcomes.
- Scene écrit les conséquences durables.
- Cinematic exécute une séquence linéaire de présentation.
- Cinematic rend la main à la Scene.

Règle de bascule :

```text
Dès qu’il y a orchestration, branching, dialogue, combat ou conséquence durable,
l’Event doit lancer une Scene.
```

Règle de conséquence :

```text
Les conséquences persistantes appartiennent à la Scene, pas à la Cinematic.
```

Règle de visibilité :

```text
Les changements visibles durables sont projetés par les World Rules, pas
déclenchés activement par elles.
```

## 7. Event — contrat produit

### Définition

Un Event est un déclencheur contextualisé. Il observe une situation dans le
monde ou dans le runtime et décide si quelque chose doit commencer.

### Rôle utilisateur

L’utilisateur comprend un Event comme :

```text
Quand le joueur fait X, si les conditions Y sont vraies, lancer Z.
```

Exemples :

- Quand le joueur parle à ce PNJ.
- Quand le joueur entre dans cette zone.
- Quand le joueur ramasse cet objet.
- Quand ce combat se termine.
- Quand ce dialogue produit ce résultat.

### Données conceptuelles minimales

P1-02 ne crée pas de modèle, mais fixe la grammaire minimale :

- id lisible ;
- nom auteur ;
- source de déclenchement ;
- scope : map / entity / zone / global ;
- conditions d’entrée ;
- target : Scene, message simple ou action simple bornée ;
- repeat policy : repeatable, one-shot, consumed ;
- priorité ou ordre si plusieurs Events matchent ;
- notes auteur.

Ces données ne sont pas un schéma JSON. Elles sont un contrat produit à
transformer plus tard seulement si Phase 2 le valide.

### Entrées

- source runtime ou auteur ;
- GameState ;
- Facts ;
- Story Steps ;
- map / entity / zone concernée ;
- politique de répétition.

### Sorties

- lancement d’une Scene ;
- affichage d’un message simple ;
- action simple très bornée ;
- résultat “non matché” si conditions ou source ne passent pas ;
- diagnostic si la cible est absente.

### Lifecycle : repeatable / one-shot / consumed

Un Event peut être :

- repeatable : rejouable tant que ses conditions passent ;
- one-shot : conçu pour être joué une seule fois ;
- consumed : marqué comme consommé par un Fact ou un état persistant ;
- gated : disponible seulement si un Fact ou Step est dans l’état attendu.

Important : l’Event ne doit pas masquer l’idempotence dans une action gameplay.
Pour un pickup, par exemple, la Scene peut donner l’objet et poser le Fact
“pickup effectué”. L’Event relit ensuite ce Fact ou une World Rule masque
l’objet.

### Conditions

Event peut lire des conditions d’entrée simples :

- Fact présent / absent ;
- Step terminé / non terminé ;
- map ou entity source ;
- objet ou état gameplay si le modèle futur le supporte ;
- priorité si plusieurs Events sont candidats.

Event ne doit pas contenir une logique conditionnelle profonde avec plusieurs
branches internes. Ce branching appartient à la Scene.

### Priorité / conflits potentiels

Si plusieurs Events matchent la même source, le produit doit prévoir une règle
future :

- ordre explicite ;
- priorité ;
- fallback ;
- diagnostic de conflit.

P1-02 ne tranche pas le modèle technique. Il impose seulement que le conflit
soit visible et validable, pas caché dans l’ordre des fichiers.

### Relation avec map/entity/trigger

Un Event peut être attaché :

- à un PNJ ;
- à un objet interactif ;
- à une zone ;
- à une entrée de map ;
- à un résultat runtime comme fin de combat ou outcome de dialogue.

La map fournit la source. L’Event ne doit pas devenir le lieu où l’auteur écrit
toute la scène.

### Ce qu’un Event peut lancer

Un Event peut lancer :

- une Scene ;
- un message simple ;
- une action simple très bornée.

Recommandation stricte :

```text
Dès qu’il y a orchestration, branching, dialogue, combat ou conséquence durable,
l’Event doit lancer une Scene.
```

### Ce qu’un Event ne doit pas faire

Un Event ne doit pas :

- contenir une chaîne dialogue → cinematic → battle → reward ;
- écrire tous les Facts d’une progression ;
- compléter directement des Story Steps complexes ;
- devenir un SceneGraph ;
- contenir un branching narratif libre ;
- remplacer World Rule ;
- corriger un projet ;
- décider des conséquences post-battle.

### Diagnostics Validator possibles

Diagnostics futurs possibles, non implémentés dans P1-02 :

- Event sans source ;
- Event sans cible ;
- Event cible Scene absente ;
- Event avec conditions impossibles ;
- Event conflictuel avec un autre Event de même source ;
- Event one-shot sans Fact ou règle de consommation ;
- Event contenant une orchestration trop complexe ;
- Event lançant une action durable sans Scene.

### Impacts Phase 2

Phase 2 devra décider si Event devient :

- un modèle `map_core` ;
- une metadata autour de `ScenarioAsset` ;
- une convention de source scenario ;
- un contrat de validation seulement.

Le point important est de ne pas dupliquer inutilement les sources runtime
existantes, mais de leur donner un langage produit clair.

## 8. Scene — contrat produit

### Définition

Une Scene est un orchestrateur narratif. Elle organise ce qui arrive une fois
qu’un Event ou une continuation l’a lancée.

### Rôle utilisateur

L’utilisateur comprend une Scene comme :

```text
Voici le déroulé : dialogue, mise en scène, combat, résultats, conséquences.
```

Elle répond à :

- dans quel ordre les blocs se passent ;
- quels outcomes sont possibles ;
- quelles branches sont jouées ;
- quelles conséquences persistent ;
- quelle étape progresse.

### Données conceptuelles minimales

P1-02 ne crée pas de modèle, mais fixe la grammaire minimale :

- id lisible ;
- nom auteur ;
- points d’entrée ;
- blocs ordonnés ou graphe ;
- conditions internes ;
- références Dialogue Yarn ;
- références Cinematic ;
- références Battle ;
- actions gameplay ;
- Fact writes ;
- Story Step completion ;
- branches et continuations ;
- end states ;
- notes auteur.

### Entrées

- Event source ;
- continuation de dialogue ;
- continuation de cinematic ;
- continuation de battle ;
- outcome Yarn ;
- outcome battle ;
- GameState ;
- Facts / Steps lus.

### Sorties

- Dialogue Yarn lancé ;
- Cinematic lancée ;
- Battle lancé ;
- action gameplay exécutée ;
- Fact écrit ;
- Story Step complété ;
- continuation vers une autre Scene ;
- fin de flow.

### Orchestration

La Scene est le lieu principal de :

- ordre des actions ;
- attente de dialogue ;
- attente de cinematic ;
- attente de battle ;
- lecture des outcomes ;
- écriture des Facts ;
- complétion des Story Steps ;
- continuations ;
- convergence des branches.

La Scene peut être un graphe, une liste de blocs ou une représentation future
plus guidée. P1-02 ne choisit pas l’UI. Il fixe seulement la responsabilité.

### Branching

La Scene peut brancher selon :

- outcome Yarn ;
- outcome battle ;
- Fact lu ;
- Step lu ;
- résultat d’une action ;
- fallback si condition non satisfaite.

Le branching est Scene-level. Il ne doit pas être enfoui dans Event ou
Cinematic.

### Relation avec Yarn

La Scene lance Yarn, puis lit son outcome.

Yarn ne décide pas seul de la progression globale. Il produit un résultat que la
Scene interprète.

### Relation avec Cinematic

La Scene peut appeler une Cinematic avant, pendant ou après un dialogue ou un
combat. La Cinematic joue une séquence linéaire, puis la Scene reprend la main.

La Scene peut choisir quelle Cinematic jouer selon un outcome, mais la
Cinematic ne choisit pas les conséquences durables.

### Relation avec Battle

La Scene lance un Battle. Battle résout le combat. La Scene lit victory,
defeat, flee/runaway ou captured si ces outcomes sont supportés par le flow
réel.

La Scene décide ensuite les Facts, Steps, rewards simples ou branches.

### Fact writes

La Scene est le lieu recommandé pour écrire les Facts persistants.

Exemples :

- “Le rival a été battu au port.”
- “La récompense de quête a été donnée.”
- “L’objet ramassable a été consommé.”

### Step completion

La Scene est le lieu recommandé pour compléter les Story Steps.

Exemples :

- terminer “Parler à Lysa au port” ;
- terminer “Battre le rival” ;
- terminer une étape optionnelle après une résolution.

### Ce qu’une Scene ne doit pas faire

Une Scene ne doit pas :

- être un Event ;
- être une simple Cinematic ;
- mélanger plusieurs responsabilités sans structure ;
- devenir un Quest Engine complet ;
- être un script opaque impossible à valider ;
- cacher les Facts dans des labels techniques ;
- transformer Yarn en moteur de progression principal ;
- écrire des effets dont le Validator ne peut jamais comprendre la portée.

### Diagnostics Validator possibles

Diagnostics futurs possibles, non implémentés dans P1-02 :

- Scene sans entrée ;
- Scene sans fin ;
- Scene référence Yarn absent ;
- Scene référence Cinematic absente ;
- Scene référence Battle absent ;
- Scene écrit Fact inconnu ;
- Scene complète Step inconnu ;
- Scene outcome Yarn non géré ;
- Scene outcome battle non géré ;
- Scene branch impossible ;
- Scene unreachable ;
- Scene qui contient une action durable non validable.

### Impacts Phase 2

Phase 2 devra décider si Scene est :

- le nom produit de `ScenarioAsset` ;
- un wrapper autour de `ScenarioAsset` ;
- un contrat supérieur qui référence plusieurs scenario graphs ;
- ou un modèle nouveau.

P1-02 recommande de ne pas créer un modèle séparé tant que la relation à
`ScenarioAsset` n’est pas explicitement choisie.

## 9. Cinematic — contrat produit

### Définition

Une Cinematic est une séquence linéaire de mise en scène. Elle décrit ce que le
joueur voit et entend pendant un moment contrôlé.

### Rôle utilisateur

L’utilisateur comprend une Cinematic comme :

```text
Montrer une action, faire bouger des personnages, cadrer la caméra, attendre,
puis rendre la main à la Scene.
```

### Données conceptuelles minimales

P1-02 ne crée pas de modèle, mais fixe la grammaire minimale :

- id lisible ;
- nom auteur ;
- contexte de Scene ;
- personnages ou entités ciblés ;
- séquence de beats ;
- timing ;
- caméra ;
- mouvements ;
- animations ;
- sons / effets ;
- verrouillage ou retour contrôle ;
- signal de fin.

### Entrées

- Scene appelante ;
- acteurs disponibles ;
- map courante ;
- paramètres de mise en scène ;
- contexte de branche choisi par la Scene.

### Sorties

- signal “terminée” ;
- signal d’échec technique si une référence est absente ;
- éventuellement un outcome technique très borné si Phase 2 le valide.

Recommandation P1-02 :

```text
Une Cinematic peut retourner “terminée”, mais la Scene décide ensuite de la
progression.
```

### Séquence linéaire

Une Cinematic doit être lisible comme une timeline ou une séquence de beats :

1. focus caméra ;
2. déplacement personnage ;
3. pause ;
4. animation ;
5. transition ;
6. retour contrôle.

Elle peut être choisie par une Scene selon une branche, mais elle ne porte pas
elle-même le branching narratif principal.

### Commandes possibles

Commandes conceptuelles possibles :

- move character ;
- turn character ;
- camera pan ;
- camera focus ;
- wait ;
- play animation ;
- show emotion ;
- fade in/out ;
- play sound ;
- lock controls ;
- unlock controls.

Ces commandes restent documentaires dans P1-02.

### Limites

Une Cinematic ne doit pas :

- écrire librement les Facts ;
- compléter librement les Story Steps ;
- lancer des combats ;
- ouvrir Yarn comme moteur de progression ;
- contenir un graph complexe ;
- être utilisée comme Event ;
- décider la suite narrative globale.

Si une cinématique doit produire une conséquence durable, la recommandation est
de faire revenir le contrôle à la Scene et de laisser la Scene écrire cette
conséquence.

### Relation avec Scene

La Cinematic est appelée par une Scene. Elle est un bloc de présentation dans
l’orchestration, pas l’orchestrateur.

### Relation avec outcomes

Une Cinematic peut être sélectionnée selon un outcome produit ailleurs :

- outcome Yarn lu par Scene ;
- outcome battle lu par Scene ;
- Fact lu par Scene.

Mais la Cinematic ne doit pas décider elle-même du branchement durable. Au
mieux, elle signale sa fin.

### Ce qu’une Cinematic ne doit pas faire

Une Cinematic ne doit pas :

- écrire directement toute la progression ;
- contenir du branching complexe ;
- remplacer une Scene ;
- remplacer un Event ;
- devenir un script runtime opaque ;
- masquer des actions gameplay ;
- changer durablement le monde sans Fact écrit par Scene.

### Diagnostics Validator possibles

Diagnostics futurs possibles, non implémentés dans P1-02 :

- Cinematic référence personnage absent ;
- Cinematic référence map/entity absente ;
- Cinematic sans fin ;
- Cinematic contient logique interdite ;
- Cinematic tente d’écrire Fact/Step hors politique validée ;
- Cinematic appelée par aucune Scene ;
- Cinematic appelée avec acteurs indisponibles.

### Impacts Phase 2

Phase 2 devra décider :

- si Cinematic correspond aux cutscene assets existants ;
- si elle devient un modèle explicite ;
- comment elle est référencée par Scene ;
- quels diagnostics sont fiables ;
- si un outcome technique borné est autorisé ou interdit.

Position P1-02 :

```text
Conséquences persistantes dans Scene par défaut.
Cinematic seulement linéaire par défaut.
```

## 10. Matrice de responsabilité

| Responsabilité | Event | Scene | Cinematic | Commentaire |
|---|---:|---:|---:|---|
| Déclencher depuis interaction | Oui | Non | Non | Event matche la source. |
| Déclencher depuis zone | Oui | Non | Non | Event observe map / zone. |
| Évaluer conditions d’entrée | Oui | Possible | Non | Event filtre l’entrée ; Scene peut brancher en interne. |
| Choisir quoi lancer | Oui | Possible | Non | Event choisit la Scene ; Scene choisit les blocs. |
| Orchestrer plusieurs blocs | Non | Oui | Non | Responsabilité centrale de Scene. |
| Brancher selon outcome Yarn | Non | Oui | Non | Yarn produit, Scene interprète. |
| Brancher selon outcome battle | Non | Oui | Non | Battle résout, Scene interprète. |
| Lancer Dialogue Yarn | Non | Oui | Non | Event lance une Scene qui ouvre Yarn. |
| Lancer Battle | Non | Oui | Non | Event ne lance pas directement un combat narratif complexe. |
| Déplacer caméra | Non | Appelle | Oui | Scene orchestre, Cinematic exécute. |
| Déplacer personnage | Non | Appelle | Oui | Même logique que caméra. |
| Jouer animation | Non | Appelle | Oui | Animation comme beat de mise en scène. |
| Verrouiller / rendre contrôles | Non | Appelle | Oui | Beat de Cinematic. |
| Écrire Fact | Non par défaut | Oui | Non | Conséquence durable dans Scene. |
| Compléter Story Step | Non par défaut | Oui | Non | Progression durable dans Scene. |
| Changer visibilité monde | Non | Écrit Fact | Non | World Rule projette ensuite. |
| Être repeatable / one-shot | Oui | Peut être relancée | Non | One-shot via Event condition / Fact / World Rule. |
| Diagnostiquer cohérence | Non | Non | Non | Validator diagnostique. |
| Corriger automatiquement | Non | Non | Non | Aucun de ces concepts ne corrige. |

Règles clés :

```text
Écrire Fact : Event non / Scene oui / Cinematic non.
Déplacer caméra : Event non / Scene appelle / Cinematic oui.
Brancher selon battle outcome : Event non / Scene oui / Cinematic non.
Changer visibilité monde : World Rule, pas Event/Scene/Cinematic directement.
```

## 11. Cycle canonique Event → Scene → Cinematic

Cycle cible :

1. Le joueur interagit avec un objet ou PNJ.
2. L’Event correspondant matche la source.
3. L’Event vérifie ses conditions d’entrée.
4. L’Event demande le lancement d’une Scene.
5. La Scene orchestre éventuellement une Cinematic.
6. La Cinematic joue une séquence linéaire.
7. La Scene reprend la main.
8. La Scene peut lancer Yarn, Battle ou actions.
9. La Scene écrit les Facts et complète les Steps.
10. Les World Rules projettent les changements visibles.
11. Le Validator peut diagnostiquer la chaîne.

Forme produit :

```text
Quand le joueur parle à un PNJ
Si l’étape attendue est active
Alors lancer la Scene de rencontre
Puis jouer une Cinematic d’entrée
Puis ouvrir un Dialogue Yarn
Puis lire l’outcome
Puis lancer un Battle
Puis écrire le Fact de résultat
Puis terminer le Step
Puis les World Rules changent le dialogue ou la visibilité
```

Dans cette forme, chaque responsabilité reste visible.

## 12. Conditions, outcomes et conséquences

### Conditions d’entrée

Les conditions d’entrée appartiennent principalement à Event.

Exemples :

- ce PNJ est-il le bon ?
- cette zone est-elle la bonne ?
- ce Step est-il actif ?
- ce Fact est-il absent ?
- cet Event est-il déjà consommé ?

### Conditions internes

Les conditions internes appartiennent à Scene.

Exemples :

- si outcome Yarn = confident, jouer telle branche ;
- si battle outcome = victory, poser tel Fact ;
- si objective Step terminé, ouvrir la fin de quête ;
- sinon jouer un message bloqué.

### Outcomes

Les outcomes sont produits par :

- Dialogue Yarn ;
- Battle ;
- action runtime bornée ;
- éventuellement un flow futur validé.

Ils sont lus par Scene.

### Conséquences durables

Les conséquences durables sont écrites par Scene :

- Fact écrit ;
- Story Step complété ;
- item donné via action de Scene ;
- progression post-battle ;
- état de résolution.

### Projection visible

La projection visible appartient à World Rule :

- PNJ visible / caché ;
- dialogue changé ;
- proxy ouvert / fermé ;
- objet masqué après pickup.

Règle P1-02 :

```text
Event peut avoir des conditions d’entrée simples pour décider s’il déclenche.
Scene peut avoir des conditions internes pour brancher.
Cinematic ne doit pas porter la logique conditionnelle principale.
```

## 13. Relation avec Dialogue Yarn

La relation canonique :

```text
Scene lance Yarn.
Yarn produit un outcome.
Scene interprète l’outcome.
```

Yarn porte :

- le texte ;
- les choix ;
- les nœuds de dialogue ;
- les outcomes de conversation.

Yarn ne doit pas porter :

- toute la progression globale ;
- tous les Facts ;
- les Story Step completions principales ;
- le dispatch de combats ;
- les World Rules.

Anti-pattern :

```text
Un dialogue Yarn qui pose directement tous les flags de progression devient un
moteur caché et difficile à valider.
```

Position P1-02 :

- Yarn peut produire un résultat lisible.
- Scene lit ce résultat.
- Scene décide la suite.
- Le Validator doit pouvoir repérer les outcomes Yarn non gérés par Scene.

## 14. Relation avec Battle

La relation canonique :

```text
Scene lance Battle.
Battle résout le combat.
Battle retourne victory / defeat / escape / capture si pertinent plus tard.
Scene interprète le résultat.
```

Battle porte :

- règles de combat ;
- résolution gameplay ;
- outcome de combat ;
- éventuel write-back gameplay strictement supporté par le runtime.

Battle ne doit pas porter :

- la progression narrative globale ;
- la décision de terminer une Story Step ;
- la disponibilité d’une side quest ;
- les World Rules.

Les preuves NS-GS montrent surtout le Level 2 Application :

- `startTrainerBattle` authorable par Scene ;
- outcome flags déterministes ;
- `dispatchContinuation` ;
- branches victory / defeat ;
- facts / steps post-battle.

Limite à conserver :

```text
Ces preuves ne valident pas encore le Golden Slice complet Level 3 Flame ni un
vrai projet disque Level 4 créé dans l’éditeur.
```

Position P1-02 :

- Battle résout.
- Scene interprète.
- World Rule projette ensuite.

## 15. Relation avec Fact et Story Step

La relation canonique :

```text
Event lit éventuellement Facts / Steps en conditions d’entrée.
Scene écrit les Facts et complète les Story Steps.
Cinematic ne doit pas écrire les Facts / Steps.
World Rule lit ensuite Facts / Steps.
```

Fact :

- vérité persistante et lisible du monde ;
- écrit par Scene ;
- lu par Event, Scene ou World Rule ;
- diagnostiqué par Validator.

Story Step :

- jalon de progression ;
- complété par Scene ;
- lu par Event ou World Rule ;
- organisé plus tard par Storyline / Chapter.

Recommandation :

```text
La Scene est le lieu recommandé pour écrire les Facts.
La Scene est le lieu recommandé pour compléter les Story Steps.
Event peut lire des Facts/Steps en conditions.
Cinematic ne doit pas écrire des Facts/Steps.
```

Ambiguïté à valider plus tard :

- une Cinematic peut-elle émettre un outcome technique très borné ?
- si oui, la Scene doit rester responsable de transformer cet outcome en Fact
  ou Step.

## 16. Relation avec World Rule

World Rule lit les Facts / Steps et projette passivement l’état vers le monde
visible.

Elle peut :

- masquer une entité ;
- afficher une entité ;
- changer un dialogue ;
- changer l’interactabilité si supportée ;
- afficher un proxy ouvert / fermé ;
- refléter une progression.

Elle ne doit pas :

- déclencher une Scene ;
- remplacer Event ;
- écrire Fact ;
- compléter Step ;
- lancer Battle ;
- corriger l’état ;
- devenir un script de réaction actif.

Règle stricte :

```text
World Rule ne déclenche pas une Scene.
World Rule ne remplace pas Event.
World Rule projette ce que Scene a persisté.
```

P1-03 devra approfondir cette relation, notamment :

- où les Facts sont déclarés ;
- comment éviter les flags bruts ;
- comment World Rule reste passive ;
- quels diagnostics le Validator doit produire.

## 17. Relation avec Validator

Validator diagnostique la cohérence de la chaîne. Il ne déclenche, n’orchestre
et ne corrige rien.

Diagnostics futurs possibles, non implémentés dans P1-02 :

- Event sans source ;
- Event sans cible ;
- Event cible Scene absente ;
- Event avec conditions impossibles ;
- Scene sans entrée ;
- Scene référence Yarn absent ;
- Scene référence Cinematic absente ;
- Scene référence Battle absent ;
- Scene écrit Fact inconnu ;
- Scene complète Step inconnu ;
- Cinematic référence personnage absent ;
- Cinematic contient logique interdite ;
- World Rule utilisée comme déclencheur ;
- Yarn outcome non géré par Scene ;
- Battle outcome non géré par Scene ;
- Event one-shot sans Fact ou condition anti-replay ;
- Scene unreachable ;
- Cinematic appelée mais jamais terminée.

Position produit :

```text
Le Validator explique.
Il ne répare pas automatiquement.
Il doit rendre les frontières visibles.
```

## 18. Mapping vers l’existant

Mapping prudent :

| Concept P1-02 | Existant observé | Statut | Limite |
|---|---|---:|---|
| Event source entity interaction | `ScenarioRuntimeSourceEvent.entityInteract` | ✅ prouvé Level 2 | Produit Event canonique absent. |
| Event source trigger enter | `ScenarioRuntimeSourceEvent.triggerEnter` | ✅ existant / partiel | Pas modèle auteur canonique Phase 1. |
| Event source map enter | `ScenarioRuntimeSourceEvent.mapEnter` | ✅ existant / partiel | Pas workflow no-code stabilisé. |
| Event source outcome | `ScenarioRuntimeSourceEvent.outcomeReceived` | ✅ prouvé Level 2 | Pont technique, vocabulaire produit à clarifier. |
| Scene runtime | `ScenarioAsset` + `ScenarioRuntimeExecutor` | ✅ prouvé Level 2 | Relation Scene = ScenarioAsset ou wrapper non tranchée. |
| Scene branching | condition node + `trueBranch` / `falseBranch` | ✅ prouvé Level 2 | Registry outcomes/facts absent. |
| Dialogue Yarn outcome | `emitOutcome` + flag `scenario.outcome.*` | ✅ prouvé Level 2 | Yarn ne doit pas devenir moteur global. |
| Scene → Battle | `kScenarioActionStartTrainerBattle` | ✅ prouvé Level 2 | Boss trainer-like seulement pour NS-GS-17. |
| Static wild par Scene | startStatic/startWild absent | ⚠️ non prouvé | Futur gameplay gap, hors P1-02. |
| Cinematic depuis Scene | script / cutscene runtime mentionné dans SEL-A2 | ⚠️ partiel | Contrat produit Cinematic non stabilisé. |
| World Rule | `MapEntityRuntimePredicateEvaluator` | ✅ prouvé Level 1/2 | Registry produit absent. |
| Validator V0 | `narrative_validator.dart` | ✅ prouvé Level 1 | Diagnostics Event/Scene/Cinematic futurs non ajoutés. |
| Golden Slice Flame | `PlayableMapGame` ponts inspectés | ⚠️ partiel | Golden Slice complet Level 3 non prouvé. |
| Projet disque éditeur | aucun vrai projet auteur validé | ❌ non prouvé | Level 4 futur. |

Lecture stricte :

```text
Le bloc NS-GS prouve surtout des patterns Level 2 Application.
Il ne prouve pas le produit final no-code.
Il ne prouve pas un Golden Slice complet Flame.
Il ne prouve pas un vrai projet disque créé dans l’éditeur.
```

Confusion probable dans l’existant :

- `ScenarioAsset` porte aujourd’hui beaucoup de responsabilités de Scene, mais
  le produit n’a pas encore décidé si Scene est exactement ce modèle.
- `script` / cutscene peut servir de Cinematic, mais la frontière produit
  Cinematic reste à stabiliser avant contrat technique.
- `storyFlags` supporte les Facts techniquement, mais “Fact” doit devenir un
  langage lisible, pas une chaîne brute.

## 19. Mapping Selbrume illustratif

Ce mapping est illustratif. Aucun contenu Selbrume final n’est créé par P1-02.

Exemple conceptuel :

```text
Interaction avec Lysa au port
→ Event : player interacts with Lysa, Step active, Rival not beaten
→ Scene : Rencontre rival
→ Cinematic : Lysa avance, rival entre, caméra se déplace
→ Yarn : dialogue rival_intro
→ Scene : lit outcome
→ Cinematic : variation courte selon outcome
→ Scene : lance combat Rival
→ Scene : lit victory/defeat
→ Scene : écrit Fact + complète Step
→ World Rule : Lysa change de dialogue
```

Mapping par frontière :

| Étape illustrative | Concept | Responsabilité |
|---|---|---|
| Le joueur appuie sur interaction devant Lysa | Event source | Déclenchement externe. |
| Step active + Rival pas battu | Event conditions | Filtre d’entrée. |
| Lancer “Rencontre rival” | Event target | Event choisit la Scene. |
| Ordre dialogue / mise en scène / combat | Scene | Orchestration. |
| Lysa avance, caméra cadre le port | Cinematic | Mise en scène linéaire. |
| Choix confident / hesitant / aggressive | Yarn | Dialogue et outcome. |
| Variation de mise en scène selon choix | Scene choisit Cinematic | Branching Scene-level. |
| Combat Rival | Battle lancé par Scene | Battle résout. |
| Victory / defeat | Battle outcome | Scene interprète. |
| Rival battu au port | Fact écrit par Scene | Vérité persistante. |
| Étape terminée | Story Step completion par Scene | Progression. |
| Lysa change de dialogue | World Rule | Projection passive. |

Rappel :

```text
Aucun `map_port_brisants`, aucun `npc_lysa`, aucun dialogue final,
aucun trainer final, aucun battle final et aucun `project.json` Selbrume
n’est créé par P1-02.
```

Le Golden Slice réel reste prévu plus tard, après les phases produit, domaine,
runtime/disk validation et authoring minimal.

## 20. Vocabulaire utilisateur recommandé

| Concept technique | Libellé UI recommandé | Remarque |
|---|---|---|
| Event | Déclencheur | Terme principal recommandé. |
| Scene | Scène | Terme central, compréhensible. |
| Cinematic | Mise en scène | Plus large et moins technique que “cinématique”. |
| Cinematic alternatif | Cinématique | Acceptable pour une séquence très visible. |
| Condition | Condition | Terme simple. |
| Outcome | Résultat | “Résultat de dialogue” ou “résultat de combat”. |
| Fact write | Marquer un fait du monde | Évite “setFlag”. |
| Step completion | Terminer une étape | Évite “completeStep id”. |
| Branch | Chemin / suite | Plus lisible que “edge”. |
| World Rule | Règle du monde | Projection visible. |
| Validator | Diagnostic / Vérificateur | À valider en UI future. |

Termes à éviter dans l’UX simple :

- source event ;
- runtime event ;
- node id ;
- predicate ;
- mutation ;
- scenario edge ;
- flag write ;
- actionKind ;
- binding ;
- payload ;
- resolver.

Ces termes peuvent rester dans une documentation technique, un mode debug ou un
panneau avancé, mais pas dans le flux auteur normal.

## 21. Anti-patterns interdits

Anti-patterns Event :

- Event qui contient une chaîne complète dialogue → battle → reward.
- Event qui écrit directement tous les Facts.
- Event qui devient un SceneGraph.
- Event qui contient plusieurs branches narratives internes.
- Event qui remplace World Rule pour gérer visibilité ou dialogue durable.

Anti-patterns Scene :

- Scene réduite à une simple animation caméra.
- Scene qui mélange déclencheur et orchestration.
- Scene qui cache les conséquences dans des labels techniques.
- Scene qui devient un Quest Engine complet.
- Scene impossible à diagnostiquer car tout est opaque.

Anti-patterns Cinematic :

- Cinematic qui écrit directement la progression.
- Cinematic qui complète librement des Story Steps.
- Cinematic avec branching complexe.
- Cinematic qui lance directement un Battle.
- Cinematic qui remplace Scene.

Anti-patterns transverses :

- Yarn qui devient le moteur principal de progression.
- Battle qui décide seul des Facts de progression.
- World Rule utilisée comme Event.
- Validator qui corrige automatiquement.
- UI premium démarrée avant stabilisation des contrats.
- Selbrume final généré trop tôt.

## 22. Impacts attendus pour P1-03 et Phase 2

P1-03 devra traiter :

```text
Fact & World Rule Product Grammar
```

P1-02 prépare P1-03 en fixant :

- la Scene comme lieu recommandé d’écriture des Facts ;
- l’Event comme lecteur de conditions d’entrée ;
- la World Rule comme lecteur passif de Facts / Steps ;
- la Cinematic comme séquence qui ne porte pas la progression durable ;
- le besoin d’éviter les flags bruts dans l’UX.

Phase 2 devra potentiellement transformer P1-02 en :

- Event contract ;
- Scene contract ;
- Cinematic contract ;
- diagnostics Validator ;
- registry de références ;
- relations avec `ScenarioAsset` ;
- relations avec runtime source events ;
- relations avec GameState ;
- relation entre cutscene runtime existant et Cinematic produit.

Mais P1-02 ne doit pas écrire ces modèles.

Recommandation Phase 2 :

```text
Ne créer un modèle Event / Scene / Cinematic que si les consumers sont clairs :
editor, runtime, validator, persistence et tests.
```

## 23. Mise à jour de road_map_phase_1.md

Mise à jour prévue dans `MVP Selbrume/road_map_phase_1.md` :

```text
P1-02 : ✅ terminé
P1-03 : 🔜 prochain lot exact
```

La roadmap Phase 1 doit aussi indiquer :

- résumé court du résultat P1-02 ;
- fichiers créés / modifiés ;
- commandes exécutées ;
- décisions utilisateur nouvelles : aucune ;
- changements de périmètre : aucun ;
- prochain lot exact : P1-03 — Fact & World Rule Product Grammar.

`MVP Selbrume/road_map_global.md` reste lu mais non modifié.

## 24. Décisions à valider par l’utilisateur

Décisions non bloquantes à valider :

- Un Event peut-il lancer une action simple sans Scene, ou doit-il toujours
  lancer une Scene même pour les micro-actions ?
- Faut-il exposer “Déclencheur” plutôt que “Event” dans toute l’UI ?
- Faut-il utiliser “Mise en scène” ou “Cinématique” comme terme principal ?
- Une Cinematic peut-elle émettre un outcome technique très borné, ou doit-elle
  seulement retourner “terminée” ?
- Une Cinematic peut-elle écrire un Fact technique très borné, ou est-ce
  strictement interdit ?
- Une Scene est-elle simplement `ScenarioAsset` côté produit, ou un wrapper
  futur ?
- Les actions simples bornées lancées directement par Event doivent-elles être
  limitées à “message simple” et “notification”, ou inclure des actions gameplay
  sans conséquence durable ?

Aucune de ces décisions ne bloque P1-03. Elles doivent guider P1-03 et surtout
la Phase 2.

## 25. Evidence Pack

### 25.1 git status initial

```text
Sortie vide — aucun changement détecté au début du lot.
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
reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
reports/gameplay/audit/narrative_studio_product_model_v0.md
reports/gameplay/audit/sel_a2_event_scene_outcome_fact_contract.md
reports/gameplay/audit/sel_b2_battle_from_scene.md
reports/gameplay/ns_gs/ns_gs_08_npc_interaction_scene_authoring_readiness.md
reports/gameplay/ns_gs/ns_gs_09_yarn_outcome_scene_branch_readiness.md
reports/gameplay/ns_gs/ns_gs_10_world_rules_conditional_presence_readiness.md
reports/gameplay/ns_gs/ns_gs_11_trainer_battle_authoring_readiness.md
reports/gameplay/ns_gs/ns_gs_12_bis_evidence_pack_and_level_label_fix.md
reports/gameplay/ns_gs/ns_gs_13_narrative_validator_minimal_v0.md
reports/gameplay/ns_gs/ns_gs_17_static_encounter_boss_battle_readiness.md
reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md
```

### 25.3 Fichiers créés

```text
reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md
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
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/using-superpowers/SKILL.md
sed -n '1,260p' "MVP Selbrume/road_map_global.md"
sed -n '1,560p' "MVP Selbrume/road_map_phase_1.md"
sed -n '1,260p' reports/roadmap/pokemap_full_product_phased_roadmap_v1.md
sed -n '1,260p' reports/roadmap/roadmap_global_00_master_phase_roadmap_bootstrap.md
sed -n '1,220p' reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md
sed -n '1,260p' reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
sed -n '261,620p' reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
sed -n '621,1040p' reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
sed -n '1041,1520p' reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
sed -n '1,260p' "MVP Selbrume/road_map.md"
sed -n '1,260p' "MVP Selbrume/narrative_studio.md"
sed -n '1,220p' "MVP Selbrume/selbrume.md"
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
sed -n '1,220p' reports/gameplay/ns_gs/ns_gs_17_static_encounter_boss_battle_readiness.md
sed -n '1,260p' reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff --no-index --check /dev/null reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md || true
git diff -- "MVP Selbrume/road_map_phase_1.md"
git diff -- "MVP Selbrume/road_map_global.md"
wc -l reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md "MVP Selbrume/road_map_phase_1.md" "MVP Selbrume/road_map_global.md"
```

### 25.6 git diff --check

```text

```

### 25.7 git diff --stat

```text
 MVP Selbrume/road_map_phase_1.md | 35 +++++++++++++++++++++++++----------
 1 file changed, 25 insertions(+), 10 deletions(-)
```

### 25.8 git diff --name-only

```text
MVP Selbrume/road_map_phase_1.md
```

### 25.9 git status final

```text
 M "MVP Selbrume/road_map_phase_1.md"
?? reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md
```

### 25.10 Tests / analyze

```text
Non exécutés — P1-02 est documentaire et ne modifie aucun code.
```

### 25.11 Preuve Markdown créée / modifiée

Le présent fichier est le rapport P1-02 complet créé à :

```text
reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md
```

Contrôle whitespace du rapport untracked créé :

```bash
git diff --no-index --check /dev/null reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md || true
```

Sortie exacte :

```text

```

Line counts après création :

```text
    1683 reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md
     493 MVP Selbrume/road_map_phase_1.md
     638 MVP Selbrume/road_map_global.md
    2814 total
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
index 49bb2d00..a5fb47e9 100644
--- a/MVP Selbrume/road_map_phase_1.md
+++ b/MVP Selbrume/road_map_phase_1.md
@@ -6,16 +6,16 @@ Phase 1 — Canonical Product Model / Narrative Studio Foundations

 Statut : 🔜 En préparation

-Lot courant : P1-01 — Canonical Narrative Product Model V1
+Lot courant : P1-02 — Event / Scene / Cinematic Boundary Contract

-Prochain lot exact après P1-01 : P1-02 — Event / Scene / Cinematic Boundary Contract
+Prochain lot exact après P1-02 : P1-03 — Fact & World Rule Product Grammar

 Suivi des lots :

 - ✅ P1-00 — Phase 1 Roadmap Bootstrap
 - ✅ P1-01 — Canonical Narrative Product Model V1
-- 🔜 P1-02 — Event / Scene / Cinematic Boundary Contract
-- P1-03 — Fact & World Rule Product Grammar
+- ✅ P1-02 — Event / Scene / Cinematic Boundary Contract
+- 🔜 P1-03 — Fact & World Rule Product Grammar
 - P1-04 — Storyline / Chapter / Story Step Structure
 - P1-05 — Selbrume Reference Grammar Mapping
 - P1-06 — No-code Workflow Specification
@@ -26,7 +26,9 @@ P1-00 : ✅ terminé

 P1-01 : ✅ terminé

-P1-02 : 🔜 prochain lot exact
+P1-02 : ✅ terminé
+
+P1-03 : 🔜 prochain lot exact

 ## 2. Objectif de la Phase 1

@@ -191,7 +193,7 @@ Critères de validation :
 - le vocabulaire reste no-code et créateur-friendly ;
 - les impacts Phase 2 sont listés sans implémentation.

-### 🔜 P1-02 — Event / Scene / Cinematic Boundary Contract
+### ✅ P1-02 — Event / Scene / Cinematic Boundary Contract

 Objectif :
 Figer les frontières Event déclenche / Scene orchestre / Cinematic linéaire.
@@ -219,7 +221,7 @@ Critères de validation :
 - la relation avec Yarn, Battle, Fact et World Rule est clarifiée ;
 - les besoins Phase 2 sont bornés.

-### P1-03 — Fact & World Rule Product Grammar
+### 🔜 P1-03 — Fact & World Rule Product Grammar

 Objectif :
 Définir Fact comme vérité lisible et World Rule comme projection passive.
@@ -390,12 +392,12 @@ Critères de validation :

 ## 10. Prochain lot exact

-P1-02 — Event / Scene / Cinematic Boundary Contract
+P1-03 — Fact & World Rule Product Grammar

 Objectif du prochain lot :
-Figer les frontières Event déclenche / Scene orchestre / Cinematic linéaire.
+Définir Fact comme vérité lisible et World Rule comme projection passive.

-P1-02 ne doit pas créer de code, de modèles `map_core`, d’UI, de fixtures
+P1-03 ne doit pas créer de code, de modèles `map_core`, d’UI, de fixtures
 Selbrume finales ou de `project.json`.

 ## 11. Critères de sortie de Phase 1
@@ -476,3 +478,16 @@ P1-CHECKPOINT-01 devra aussi mettre à jour
   Décisions utilisateur nouvelles : aucune.
   Changements de périmètre : aucun.
   Prochain lot exact fixé à P1-02 — Event / Scene / Cinematic Boundary Contract.
+- 2026-05-24 — P1-02 — Event / Scene / Cinematic Boundary Contract terminé.
+  Résultat : contrat produit strict Event déclenche / Scene orchestre /
+  Cinematic met en scène linéairement, avec matrice de responsabilité et
+  relations clarifiées avec Yarn, Battle, Fact, Story Step, World Rule et
+  Validator.
+  Fichiers créés : `reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md`.
+  Fichiers modifiés : `MVP Selbrume/road_map_phase_1.md`.
+  Commandes exécutées : lectures Markdown ciblées, `find`, `git status --short --untracked-files=all`,
+  `git diff --check`, `git diff --stat`, `git diff --name-only`,
+  `git diff --no-index --check`, `wc -l`.
+  Décisions utilisateur nouvelles : aucune.
+  Changements de périmètre : aucun.
+  Prochain lot exact fixé à P1-03 — Fact & World Rule Product Grammar.
```

## 26. Auto-review critique

Le lot a-t-il modifié uniquement ce qui était autorisé ?

```text
Oui : création du rapport P1-02 et mise à jour de road_map_phase_1.md
uniquement.
```

Le rapport P1-02 existe-t-il au bon chemin ?

```text
Oui : reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md.
```

road_map_phase_1.md a-t-elle été mise à jour ?

```text
Oui : P1-02 est marqué terminé et P1-03 est défini comme prochain lot exact.
```

road_map_global.md est-elle restée intacte ?

```text
Oui : elle a été lue pour contexte seulement et `git diff -- "MVP Selbrume/road_map_global.md"`
retourne une sortie vide.
```

Aucun code n’a-t-il été modifié ?

```text
Oui : aucun fichier sous packages/ ou examples/ n’est modifié.
```

Aucun test/analyze Dart/Flutter n’a-t-il été lancé inutilement ?

```text
Oui : aucun test/analyze Dart ou Flutter n’est exécuté dans P1-02.
```

P1-03 n’a-t-il pas été commencé ?

```text
Oui : P1-03 est seulement désigné comme prochain lot exact.
```

Selbrume est-il resté une référence conceptuelle seulement ?

```text
Oui : aucun contenu final, aucun fixture, aucun project.json Selbrume créé.
```

Les frontières Event / Scene / Cinematic sont-elles assez strictes ?

```text
Oui : Event déclenche, Scene orchestre, Cinematic met en scène. Les Facts et
Steps appartiennent par défaut à la Scene, pas à la Cinematic.
```

Ambiguïtés restantes à valider par l’utilisateur :

- Event doit-il toujours lancer une Scene ou peut-il lancer une micro-action ?
- “Mise en scène” ou “Cinématique” comme libellé principal ?
- Cinematic peut-elle émettre un outcome technique borné ?
- Scene est-elle `ScenarioAsset` côté produit ou un wrapper futur ?

### Regard critique sur le prompt

Le prompt est cohérent et protège bien le lot contre la dérive vers code,
modèles et UI. La seule ambiguïté assumée est le droit d’un Event à lancer une
“action simple bornée” : cette porte est utile pour les messages très simples,
mais doit rester fortement limitée pour ne pas recréer une mini-Scene dans
Event. P1-02 recommande donc de faire passer toute orchestration, tout branching
et toute conséquence durable par Scene.
