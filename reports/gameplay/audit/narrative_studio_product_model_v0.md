# Narrative Studio Product Model V0

## 1. Résumé exécutif

Le Narrative Studio cible ne doit pas être un éditeur de flags, un canvas décoratif, ni une collection de scènes isolées. Il doit devenir l'interface d'orchestration du monde de PokeMap : l'endroit où une personne non développeuse décrit ce qui se passe, quand cela se déclenche, sous quelles conditions, avec quelles actions gameplay, et quelles conséquences persistent dans le monde.

La forme produit recommandée est :

```text
Quand [déclencheur]
Si [conditions]
Alors [actions]
Puis [conséquences / changements du monde]
```

Le constat de départ est critique. L'audit de readiness montre que Global Story, Step Studio, Dialogue Studio et Cutscene Studio existent visuellement, mais que la logique macro est encore trop souvent stockée en metadata JSON, avec un lien runtime fragile. Le runtime sait déjà évaluer des conditions et muter certains états, mais les actions gameplay essentielles d'un fangame Pokémon-like restent incomplètes : starter, combat trainer, récompenses, badges, soin, PC, shop, post-combat, progression et world rules généralisées.

La direction V0 proposée est donc de séparer clairement :

- la vision auteur : situations, étapes, événements, scènes, conséquences visibles ;
- le modèle métier : déclencheurs, conditions, actions, faits du monde, règles du monde ;
- l'exécution : runtime typé, validé, testable ;
- la persistance technique : flags et variables générés ou référencés via un registre lisible.

Le Narrative Studio voulu est un studio de règles de monde jouables, pas un studio de décoration narrative.

## 2. Problème produit à résoudre

Exposer directement des flags est une mauvaise UX no-code, car un flag est un détail d'implémentation, pas une intention de design. Un créateur ne pense pas en clés booléennes. Il pense en événements de son aventure.

Mauvais modèle mental :

```text
flag_professor_intro_done = true
```

Bon modèle mental :

```text
L'étape "Introduction du professeur" est terminée.
```

Le flag brut pose plusieurs problèmes :

- il n'exprime pas le sens produit : `rival_1_done` ne dit pas si le rival a été battu, rencontré, ignoré ou rendu invisible ;
- il accepte les fautes de frappe : `badge_1_obtenu` et `badge1_obtenu` peuvent devenir deux vérités concurrentes ;
- il ne porte aucune validation métier : le jeu ne sait pas si un flag est lié à une step, un trainer, un objet, une porte ou un dialogue ;
- il pousse le créateur à raisonner comme un développeur ;
- il casse la preview : impossible d'expliquer visuellement pourquoi un PNJ est visible si la condition est une chaîne technique obscure ;
- il encourage la dette narrative : plus le jeu grandit, plus les flags deviennent un langage secret fragile.

Les flags doivent continuer à exister techniquement, mais comme une couche compilée, générée ou avancée. L'UX doit parler de faits lisibles :

- "Starter reçu" ;
- "Rival battu sur la Route 1" ;
- "Badge Roche obtenu" ;
- "Route 2 débloquée" ;
- "Potion de la forêt ramassée" ;
- "PNJ bloqueur parti".

Le problème produit central n'est donc pas seulement technique. Il est cognitif : le Narrative Studio doit faire penser en situations, décisions, conséquences, étapes et changements du monde.

## 3. Ce que le Narrative Studio ne doit pas être

Le Narrative Studio ne doit pas devenir :

- un éditeur de texte avec quelques boutons ;
- un éditeur de flags et variables bruts ;
- un éditeur Yarn déguisé ;
- un outil de cutscenes qui prétend gérer la progression ;
- un canvas joli mais non exécutable ;
- une timeline linéaire qui force tous les fangames à suivre la même structure ;
- un battle editor ;
- un map editor bis ;
- un système où l'utilisateur doit comprendre `ScenarioAsset.metadata` ;
- un moteur de scripts générique façon automation avancée ;
- un endroit où les actions gameplay existent en labels mais pas au runtime.

Il ne doit pas non plus obliger tous les jeux à commencer par un starter, ni confondre "histoire principale" avec "toutes les quêtes". PokeMap doit permettre des structures Pokémon-like classiques, mais ne doit pas enfermer les créateurs dans une seule recette.

## 4. Vision cible

Le Narrative Studio cible est un orchestrateur lisible du monde. Il permet de créer des règles jouables :

```text
Quand le joueur parle au Professeur
Si l'étape "Recevoir son starter" n'est pas terminée
Alors ouvrir le choix du starter
Puis donner le Pokémon choisi
Puis marquer l'étape "Recevoir son starter" comme terminée
Puis faire partir le Professeur du laboratoire
```

La vision repose sur cinq promesses produit :

- écrire la logique du jeu sans écrire de code ;
- comprendre immédiatement pourquoi quelque chose arrive ou n'arrive pas ;
- lier naturellement la narration à la map ;
- utiliser les systèmes gameplay réels : combat, party, bag, badges, shops, PC, field moves, save ;
- tester une règle ou une étape avant de lancer tout le jeu.

La bonne métaphore n'est pas "script". C'est "règle de monde". Le créateur dit : dans cette situation, le monde réagit ainsi.

## 5. Modèle mental utilisateur

Le modèle mental recommandé est :

```text
Dans cette situation,
quand quelque chose arrive,
si certaines conditions sont vraies,
alors le jeu fait des actions,
puis le monde change.
```

Exemple simple :

```text
Situation : Laboratoire du Professeur
Quand : le joueur parle au Professeur
Si : le joueur n'a pas encore reçu son starter
Alors : afficher le choix du starter
Puis : donner le Pokémon choisi
Puis : terminer l'étape "Recevoir le starter"
Puis : débloquer la sortie vers la Route 1
```

Ce modèle a trois avantages :

- il part de la carte et de l'aventure, pas d'une variable ;
- il sépare le déclenchement, les prérequis et les effets ;
- il permet d'expliquer les erreurs : "Cette règle ne peut jamais se déclencher, car la step requise n'est jamais terminée."

## 6. Vocabulaire produit recommandé

| Terme | Décision recommandée | Sens produit conseillé | Notes |
|---|---|---|---|
| Global Story | Garder | Vue macro de l'aventure principale | Ne doit pas contenir la logique détaillée de chaque PNJ. |
| Chapter | Garder | Groupe lisible de Story Steps | Optionnel. Sert à organiser, pas à exécuter. |
| Story Step | Garder, traduire en "Étape d'histoire" | Jalon logique de progression | Concept central. Ne doit pas être une cutscene. |
| Event | Renommer en "Événement de map" si ambigu | Règle locale attachée à un PNJ, objet, zone ou porte | Doit avoir un trigger, des conditions et des actions. |
| Trigger | Garder, traduire en "Déclencheur" | Ce qui démarre une règle | Doit venir d'une source claire : PNJ, zone, combat, badge, choix. |
| Scene | Garder | Séquence jouée au runtime | Peut contenir dialogues, mouvements, caméra, pauses. |
| Cutscene | Fusionner comme sous-type de Scene | Scène non interactive ou semi-interactive | Éviter que Cutscene porte la progression. |
| Dialogue | Garder | Contenu textuel ou conversation | Ne doit pas devenir le moteur principal de branchement global. |
| Condition | Garder | Ce qui autorise ou bloque | Présentée en langage humain, compilée vers prédicats typés. |
| Action | Garder | Effet immédiat exécuté par le jeu | Donner objet, lancer combat, téléporter, soigner, etc. |
| Reaction | Renommer en "Conséquence visible" | Changement observable du monde après une action | À distinguer des actions immédiates. |
| World Rule | Garder, traduire en "Règle du monde" | Condition persistante de visibilité, activation ou accessibilité | Le coeur du lien map + narration. |
| Flag | Éviter en UI simple | Détail technique booléen | Visible seulement en mode avancé ou diagnostic. |
| Variable | Éviter en UI simple | Valeur de jeu numérique, texte ou booléenne | Présenter comme "compteur", "choix mémorisé", "valeur". |
| Outcome | Réduire | Résultat logique d'une action ou d'une step | Ne doit pas devenir un troisième langage parallèle aux facts. |
| Quest | Reporter ou définir séparément | Ensemble optionnel d'objectifs suivis | Peut exister plus tard hors Global Story. |
| Milestone | Fusionner avec Story Step | Jalon | Éviter deux mots pour le même concept. |

Recommandation forte : introduire le mot produit "Fait du monde". Il remplace le réflexe "flag" dans l'UX.

Exemples :

- fait du monde : "Badge 1 obtenu" ;
- fait du monde : "Potion de la forêt ramassée" ;
- fait du monde : "Rival battu sur la Route 1" ;
- fait technique possible : `story.rival.route1.defeated`.

## 7. Les concepts fondamentaux

Trigger = ce qui démarre quelque chose.

Exemple : parler à un PNJ, entrer dans une zone, finir un combat, choisir une réponse.

Condition = ce qui autorise ou bloque.

Exemple : "Badge 1 obtenu", "Starter pas encore reçu", "Party non pleine".

Action = ce que le jeu fait maintenant.

Exemple : afficher un dialogue, donner une Potion, lancer un combat, téléporter le joueur.

Reaction = ce que le joueur voit changer.

Exemple : le PNJ disparaît, la porte s'ouvre, le dialogue change, la Poké Ball n'est plus sur la map.

World Rule = règle persistante d'activation du monde.

Exemple : "Le PNJ bloqueur est visible tant que Route 2 n'est pas débloquée."

Story Step = jalon logique de progression.

Exemple : "Recevoir le starter", "Battre le rival", "Obtenir le badge 1".

Scene = séquence jouée.

Exemple : caméra qui se déplace, PNJ qui marche, dialogue, pause, son, transition.

Cutscene = type de Scene où le joueur contrôle peu ou pas l'action.

Elle peut terminer une step, mais elle n'est pas la step.

Dialogue = contenu conversationnel.

Il peut contenir des choix, mais les conséquences durables doivent être modélisées par Actions, Facts et World Rules.

Event = règle locale attachée au monde.

Exemple : "PNJ Professeur, quand on lui parle, si starter non reçu, lance la scène de starter."

Fact = vérité lisible du jeu.

Exemple : "Rival battu sur la Route 1". Un fact peut être stocké techniquement en flag, progression, trainer state, consumed event ou variable.

## 8. Déclencheurs

| Déclencheur | Usage typique | Source dans le monde | Lien map/editor/runtime | Complexité | Priorité MVP |
|---|---|---|---|---|---|
| Parler à un PNJ | Dialogue, don, combat, quête | Entity PNJ sur une map | Map Editor choisit l'événement du PNJ ; runtime déclenche à l'interaction | Moyenne | Oui |
| Entrer dans une zone | Scène, rencontre, tutoriel, blocage | Zone de trigger dessinée sur la map | Map Editor définit la zone ; Narrative Studio définit la règle ; runtime détecte l'entrée | Moyenne | Oui |
| Interagir avec un objet | Ramasser, activer, inspecter | Objet interactif sur la map | Objet lié à un Event ; runtime exécute actions et consommation | Basse | Oui |
| Inspecter un panneau | Texte court ou conseil | Tile/objet panneau | Map Editor lie panneau à dialogue ; runtime affiche | Basse | Oui |
| Finir un combat | Récompense, progression, dialogue post-combat | Résultat du système battle | Runtime battle émet victoire/défaite ; Narrative Studio branche les suites | Élevée | Oui |
| Gagner un badge | Débloquer route, capacité, dialogue | Système badges/progression | Gameplay écrit le badge ; règles narratives réagissent | Moyenne | Oui |
| Capturer un Pokémon | Tutoriel, quête Pokédex, réaction PNJ | Système capture | Battle/runtime écrit capture ; Narrative Studio écoute le fact | Élevée | Après MVP court |
| Recevoir un objet | Déclencher tutoriel ou nouvelle option | Bag/economy | Action GiveItem écrit le sac ; rules peuvent écouter | Moyenne | Oui |
| Entrer sur une map | Intro de lieu, météo, scène d'arrivée | Changement de map | Runtime émet OnMapEnter ; Narrative Studio filtre | Moyenne | Oui |
| Utiliser une capacité terrain | Ouvrir passage, couper arbre, surf | Field move runtime | Map Editor marque obstacle ; gameplay valide ability ; runtime déclenche | Élevée | Après socle MVP |
| Faire un choix de dialogue | Brancher conséquence, mémoriser décision | Dialogue/Scene | Dialogue retourne un choix ; Narrative Studio applique outcome/fact | Moyenne | Oui |
| Terminer une étape d'histoire | Débloquer prochaine étape ou world rule | Story Step | Step completion émet fact ; Global Story et map réagissent | Moyenne | Oui |

Le MVP doit prioriser les déclencheurs qui permettent une boucle jouable : PNJ, objet, zone, panneau, entrée de map, fin de combat, choix de dialogue, étape terminée.

## 9. Conditions

Les conditions doivent être présentées comme des phrases, jamais comme des flags à taper.

| Condition | Présentation UI recommandée | Source métier probable | Notes |
|---|---|---|---|
| Étape terminée / non terminée | "L'étape X est terminée" / "n'est pas terminée" | Story Step / facts | Condition centrale, doit être autocomplete. |
| Possède un objet | "Le joueur possède au moins 1 Potion" | Bag | Nécessite vrai inventaire, pas metadata ad-hoc. |
| Possède un Pokémon | "Le joueur possède Pikachu" | Party / PC | Doit pouvoir chercher party et boxes. |
| A battu un trainer | "Le dresseur Rival Route 1 est battu" | Trainer state / facts | Empêche les combats répétés non voulus. |
| A un badge | "Badge Roche obtenu" | PlayerProgression | Sert aux gates map, shops, field moves. |
| A débloqué une capacité terrain | "Surf est débloqué" | PlayerProgression | Existe déjà conceptuellement via field abilities. |
| Variable numérique ou textuelle | "Le compteur X est au moins 3" | ScriptVariables typées | Mode simple : compteur/choix. Mode avancé : variable. |
| Choix précédent effectué | "Le joueur a choisi Salamèche" | Dialogue choice fact / variable | Devrait être un fait nommé, pas une chaîne libre. |
| Map actuelle | "Le joueur est sur Route 1" | GameState.currentMapId | Utile pour événements globaux. |
| Party pleine / non pleine | "L'équipe est pleine" / "a une place libre" | Party | Critique pour cadeaux Pokémon et capture. |
| Event déjà consommé | "Cet objet a déjà été ramassé" | consumedEventIds / facts | À masquer derrière "objet déjà ramassé". |

La condition visible doit être construite par pickers :

- choisir un type : Étape, Objet, Badge, Trainer, Map, Party, Variable ;
- choisir une cible dans un registre ;
- choisir un opérateur humain : est terminé, possède, ne possède pas, au moins, exactement, avant, après ;
- afficher une phrase de résumé ;
- afficher l'id technique seulement dans un panneau avancé.

## 10. Actions

| Action | Description utilisateur | Dépendances gameplay | Package métier probable | MVP ? |
|---|---|---|---|---|
| Afficher un dialogue | Ouvre une conversation ou un message | Dialogue asset, overlay runtime | `map_runtime`, contrat dans `map_core` | Oui |
| Jouer une scène | Joue une séquence de mouvements, caméra, dialogues | Scene/Cutscene runtime, contrôle joueur | `map_runtime`, modèle dans `map_core` | Oui |
| Donner un Pokémon | Ajoute un Pokémon à l'équipe ou au PC | Party, PC, species catalog, règles party pleine | `map_gameplay`, contrats `map_core` | Oui |
| Retirer un Pokémon si pertinent | Retire un Pokémon ciblé ou échangé | Party/PC, sélection sécurisée | `map_gameplay` | Après MVP |
| Donner un objet | Ajoute un item au sac | Bag, item catalog, quantité | `map_gameplay`, contrats `map_core` | Oui |
| Retirer un objet | Retire une quantité d'item | Bag, validation quantité | `map_gameplay` | Oui |
| Lancer un combat trainer | Démarre un combat contre un trainer | Trainer roster, battle setup, handoff runtime | `map_runtime` + `map_battle` + `map_gameplay` | Oui |
| Lancer un combat wild/static | Démarre rencontre sauvage ou statique | Encounter setup, species, level, capture | `map_runtime` + `map_battle` | Oui |
| Donner argent | Ajoute de l'argent | Economy dans trainer profile/progression | `map_gameplay` | Oui |
| Retirer argent | Retire de l'argent si disponible | Economy, validation fonds | `map_gameplay` | Oui |
| Donner badge | Marque un badge obtenu | PlayerProgression, badge registry | `map_gameplay`, contrats `map_core` | Oui |
| Débloquer capacité terrain | Autorise une field ability | PlayerProgression, field move checks | `map_gameplay` | Oui |
| Soigner l'équipe | Restaure PV/status/PP selon règles | Party, Pokémon state, move PP/status | `map_gameplay` | Oui |
| Ouvrir shop | Affiche une boutique | Shop catalog, bag, money, runtime menu | `map_runtime` + `map_gameplay` | Oui |
| Ouvrir PC | Ouvre l'interface PC/boxes | PC storage, party rules | `map_runtime` + `map_gameplay` | Oui |
| Téléporter le joueur | Change map, position et orientation | Map registry, warp validation | `map_runtime`, mutation `map_gameplay` | Oui |
| Déplacer un PNJ | Fait marcher ou repositionne un PNJ | Entity runtime, path, collision | `map_runtime` | Oui |
| Afficher/masquer un PNJ ou objet | Change la présence visible | World rules, entity refs, runtime visibility | `map_runtime`, règles `map_core` | Oui |
| Marquer une étape comme terminée | Termine une Story Step | Story graph, facts/progression | `map_gameplay`, contrats `map_core` | Oui |
| Définir une variable | Enregistre un choix, compteur ou texte | ScriptVariables typées, registry | `map_gameplay` | Oui, mode avancé |

Le catalogue d'actions doit être typé. Une action ne doit pas être un label libre avec un dictionnaire de paramètres arbitraires. Chaque action doit connaître ses champs, ses validations, ses dépendances et son comportement runtime attendu.

## 11. Réactions et conséquences visibles

Il faut distinguer trois niveaux :

Action immédiate :

```text
Donner une Potion.
```

Conséquence persistante :

```text
La Poké Ball disparaît de la map après avoir été ramassée.
```

Règle du monde :

```text
Ce PNJ n'est visible que tant que l'étape "Recevoir le starter" n'est pas terminée.
```

Modèle recommandé :

| Cas | Modèle produit | Stockage conceptuel | Exemple UI |
|---|---|---|---|
| PNJ visible/invisible | World Rule de présence | Target entity + condition + état visible | "Afficher le Professeur après l'intro" |
| Objet ramassé/non ramassé | Event consommé + world rule | consumed event ou fact "objet ramassé" | "Disparaît après ramassage" |
| Porte ouverte/fermée | World Rule d'interaction | Target porte + condition d'ouverture | "Ouvrir si Badge 1 obtenu" |
| Route bloquée/débloquée | Gate map ou PNJ bloqueur | Rule sur zone, obstacle ou PNJ | "Route 2 accessible après starter" |
| Dialogue alternatif | Event avec branches conditionnelles | Conditions ordonnées sur dialogue/action | "Si Rival battu, dire autre chose" |
| Combat déjà fait | Trainer defeated fact | Trainer state + world/dialogue rule | "Après victoire, ne relance pas le combat" |
| Shop disponible | Rule d'activation service | Shop ref + condition | "Boutique ouverte après badge 1" |
| Zone accessible | Rule de traversal | Map zone + condition | "Entrée autorisée si Cut débloqué" |

Une conséquence visible doit toujours être testable depuis l'éditeur : "Simuler avec l'étape X terminée" doit montrer les PNJ, objets, portes et dialogues dans l'état attendu.

## 12. Étapes d’histoire et progression

Une Story Step est un jalon logique, pas une cutscene.

Exemples de bonnes steps :

- Recevoir le starter ;
- Battre le rival ;
- Obtenir le badge 1 ;
- Débloquer la Route 2 ;
- Atteindre la ville suivante.

Une step doit avoir un état clair :

| État | Sens | Exemple |
|---|---|---|
| Inactive | Le joueur n'a pas encore accès à cet objectif | "Battre le rival" avant d'avoir reçu le starter |
| Active | L'objectif est en cours ou disponible | "Va parler au rival sur la Route 1" |
| Completed | Le jalon est terminé | "Rival battu sur la Route 1" |

Chaque Story Step devrait pouvoir définir :

- conditions d'activation : quand elle devient disponible ;
- actions au début : lancer une scène, afficher un objectif, débloquer un PNJ ;
- conditions de complétion : combat gagné, objet obtenu, zone atteinte, dialogue choisi ;
- actions à la fin : donner récompense, marquer un fact, débloquer une step ;
- conséquences monde : masquer un PNJ, ouvrir une route, changer un dialogue.

Une step ne doit pas stocker toute la logique détaillée. Elle coordonne. Les événements locaux et les scènes exécutent.

## 13. Relation entre Global Story, Step, Event, Scene, Dialogue et Cutscene

Cette frontière doit être stricte.

| Concept | Responsabilité | Ne doit pas faire |
|---|---|---|
| Global Story | Montrer la structure macro de l'aventure | Exécuter directement des actions runtime détaillées |
| Chapter | Grouper des steps pour lecture et navigation | Bloquer le gameplay par lui-même |
| Story Step | Décrire un jalon logique et ses règles de progression | Devenir une scène ou un dialogue |
| Event | Relier une source du monde à une règle jouable | Remplacer Global Story |
| Scene | Jouer une séquence runtime | Porter seule la vérité de progression |
| Dialogue | Afficher texte, choix et conversations | Devenir le registre caché des flags |
| Cutscene | Scène non interactive ou semi-interactive | Être confondue avec "étape terminée" |
| Action | Modifier l'état ou lancer un service runtime | Être un placeholder non exécuté |
| Condition | Gater une branche ou une action | Être une chaîne technique libre |

Proposition de relation :

```text
Global Story
  -> contient des Chapters
  -> ordonne des Story Steps

Story Step
  -> définit un objectif logique
  -> peut référencer des Events, Scenes, World Rules
  -> se complète par conditions ou actions

Event
  -> vit sur la map ou sur un système gameplay
  -> possède Trigger + Conditions + Actions + Consequences

Scene
  -> est une séquence jouée
  -> peut inclure un Dialogue
  -> peut appeler des Actions à des moments précis

Cutscene
  -> est un type de Scene

Dialogue
  -> fournit le texte et les choix
  -> retourne un choix ou un outcome lisible
```

Comment éviter que Step et Cutscene se marchent dessus :

- une Step dit "Recevoir le starter est terminé quand le joueur a choisi et reçu un Pokémon" ;
- une Cutscene montre le Professeur qui parle, se déplace et présente les Poké Balls ;
- l'action "Donner le Pokémon choisi" modifie réellement le GameState ;
- la conséquence "Route 1 débloquée" est une World Rule ;
- la Step ne dépend pas du fait qu'une animation soit jouée jusqu'au bout, sauf si le produit le décide explicitement.

Une Cutscene peut être le chemin normal de complétion d'une Step, mais elle ne doit jamais être la seule source de vérité.

## 14. Relation entre Narrative Studio et la map

Le Narrative Studio doit être relié à la map de façon bidirectionnelle.

Quand l'auteur place un élément sur la map, il devrait pouvoir répondre à des questions concrètes :

- Ce PNJ lance quel event quand on lui parle ?
- Ce PNJ est visible quand quelle step est active ?
- Cette porte fonctionne si quelle condition est vraie ?
- Cette Poké Ball donne quel item et disparaît quand ramassée ?
- Cette zone déclenche quelle scène ?
- Ce panneau affiche quel dialogue ?
- Ce trainer lance quel combat, puis quel dialogue après victoire ?

Liens recommandés entre Map Editor et Narrative Studio :

- panneau "Events" dans l'inspecteur de PNJ, objet, porte, zone ;
- picker "Créer un event depuis cet élément" ;
- picker "Lier à une Story Step" ;
- aperçu des World Rules qui affectent l'élément sélectionné ;
- badge d'état : toujours visible, conditionnel, masqué après consommation, bloqué ;
- navigation inverse : depuis Narrative Studio, bouton "Voir sur la map" ;
- validation : détecter une règle qui référence une entity supprimée ou une map absente.

Le Map Editor reste l'endroit où l'on place les choses. Le Narrative Studio devient l'endroit où l'on explique comment elles réagissent.

## 15. Relation entre Narrative Studio et les systèmes gameplay

| Système | Ce que Narrative Studio doit pouvoir faire | Dépendances | À faire avant refonte ? |
|---|---|---|---|
| Combat | Lancer trainer battle, wild/static battle, brancher victoire/défaite | Battle setup, trainer roster, runtime handoff | Contrat minimum avant UX finale |
| Post-combat | Donner argent, XP, items, badge, dialogue après victoire, marquer trainer battu | Battle write-back, rewards, progression | Oui pour slice Pokémon-like |
| Progression Pokémon | Réagir à level-up, évolution, move learning si exposé | XP/level-up/evolution systems | Pas bloquant V0, nécessaire MVP complet |
| Party / PC / Capture | Donner Pokémon, gérer party pleine, envoyer au PC, réagir capture | Party, boxes, capture destination | Oui pour starter et cadeaux |
| Bag / Items / Economy | Donner/retirer items, vérifier possession, ouvrir shop, gérer argent | Bag réel, item catalog, money | Oui pour boucle RPG |
| Trainers / Badges / Gyms | Marquer dresseur battu, donner badge, débloquer gates | Trainer state, badge registry, gym templates | Oui |
| Field Moves | Gater obstacles, routes, portes, zones | Field ability checks, map obstacles | Après socle actions, mais important |
| Encounters | Déclencher static/wild, modifier zones selon progression | Encounter tables, battle handoff | Après starter/combat minimal |
| Menus runtime | Ouvrir PC, shop, bag, pause, party si action narrative | Runtime overlays, save state | Oui pour PC/shop/center |
| Save / Load | Persister facts, variables, consumed events, world state | GameState stable, migration | Oui avant refonte profonde |

Le Narrative Studio ne doit pas implémenter ces systèmes. Il doit les orchestrer via des contrats d'action stables.

## 16. Comment cacher les flags sans perdre leur puissance

Stratégie recommandée :

- créer un registry de faits narratifs lisibles ;
- générer les ids techniques automatiquement depuis des objets métier ;
- afficher les labels humains partout en UI ;
- utiliser autocomplete et pickers au lieu de champs texte libres ;
- typer les faits : step completed, trainer defeated, item picked up, badge obtained, route unlocked, choice made ;
- distinguer facts persistants et facts dérivés du GameState ;
- conserver un mode avancé "voir l'id technique" pour debug, migration et support ;
- empêcher les doublons et fautes de frappe ;
- valider les références cassées ;
- compiler vers `StoryFlags`, `ScriptVariables`, `consumedEventIds` ou structures dédiées selon le besoin.

Exemple :

| UI | Id technique possible | Stockage |
|---|---|---|
| "Étape Recevoir le starter terminée" | `story.step.receive_starter.completed` | Story fact / flag |
| "Rival Route 1 battu" | `trainer.rival_route_1.defeated` | Trainer state ou fact |
| "Potion forêt ramassée" | `event.forest_potion.consumed` | consumedEventIds |
| "Choix starter = Bulbizarre" | `choice.starter.selected` | variable typée |
| "Badge Roche obtenu" | `badge.rock.obtained` | PlayerProgression |

Le créateur doit manipuler la colonne UI. Le runtime peut utiliser les ids.

## 17. Exemples de workflows utilisateur

1. Créer une intro avec choix starter.

L'utilisateur crée une Story Step "Recevoir son starter". Dans la map Laboratoire, il sélectionne le Professeur, ajoute un Event "Quand le joueur parle au Professeur", choisit la condition "Étape Recevoir son starter non terminée", puis ajoute les actions "Afficher dialogue d'intro", "Ouvrir choix starter", "Donner le Pokémon choisi", "Marquer l'étape comme terminée". Il ajoute ensuite une World Rule : "La sortie vers Route 1 est bloquée tant que cette étape n'est pas terminée."

2. Créer un PNJ qui donne une potion une seule fois.

L'utilisateur sélectionne le PNJ, crée un Event "Parler". Il ajoute la condition "Potion du PNJ pas encore donnée", l'action "Afficher dialogue", l'action "Donner Potion x1", puis la conséquence "Marquer cet event comme consommé". Il ajoute une branche alternative : si consommé, afficher "Je t'ai déjà donné quelque chose."

3. Créer un rival battle avec dialogue avant/après.

L'utilisateur crée une Story Step "Battre le rival sur la Route 1". Sur le PNJ Rival, il ajoute un Event "Parler ou contact". Actions : "Afficher dialogue avant combat", "Lancer combat trainer Rival Route 1". Branches post-combat : si gagné, "Donner 500", "Marquer Rival Route 1 battu", "Terminer l'étape", "Afficher dialogue de défaite du rival". Si perdu, "Afficher dialogue de revanche" et ne pas terminer la step.

4. Créer une porte bloquée jusqu'au badge 1.

L'utilisateur sélectionne la porte. Il définit une condition d'utilisation : "Badge 1 obtenu". Si vrai, action "Téléporter vers Gym arrière" ou "Ouvrir porte". Si faux, action "Afficher dialogue : La porte est verrouillée." Le Studio affiche aussi la règle dans Global Story : cette porte dépend du jalon "Obtenir le badge 1".

5. Créer un objet visible seulement après une étape.

L'utilisateur place une Poké Ball sur la map. Dans l'inspecteur, il ajoute une World Rule : "Visible seulement quand l'étape Débloquer Route 2 est terminée." Event de l'objet : "Interagir", action "Donner Super Potion", conséquence "Disparaît après ramassage".

6. Créer un centre Pokémon simple.

L'utilisateur sélectionne l'infirmière, crée un Event "Parler". Actions : "Afficher dialogue de bienvenue", "Soigner l'équipe", "Afficher dialogue de fin". Condition optionnelle : si l'équipe est déjà soignée, afficher une variante. Le runtime applique la mutation de soin réelle sur party.

7. Créer un shop.

L'utilisateur sélectionne le vendeur, crée un Event "Parler". Condition : "Shop Bourg Palette disponible" ou aucune condition. Action : "Ouvrir shop", picker de stock "Boutique début de jeu". Le Studio valide que chaque item existe dans le catalogue et que l'économie est active.

## 18. Modèle d’orchestration recommandé

Modèle recommandé :

```text
Trigger
-> Condition Group
-> Action Sequence
-> Outcome / World Changes
```

Version auteur :

```text
Quand le joueur parle au Rival
Si "Starter reçu" est terminé
Alors afficher dialogue
Alors lancer combat Rival Route 1
Puis si victoire : donner argent, marquer Rival battu, terminer la step
Puis si défaite : afficher dialogue de revanche
```

Version conceptuelle stockable :

```text
EventRule
  trigger: EntityInteraction(professor_npc)
  conditions: allOf(StoryStepNotCompleted(receive_starter))
  actions:
    - OpenDialogue(professor_intro)
    - OpenStarterChoice(starter_set_1)
    - GivePokemon(fromChoice)
    - CompleteStoryStep(receive_starter)
  worldChanges:
    - SetWorldFact(route_1_unlocked)
```

Le stockage technique peut rester plus complexe que l'UX, mais il doit être typé :

- authoring model lisible dans `map_editor` ;
- contrats persistants dans `map_core` ;
- mutations pures dans `map_gameplay` ;
- exécution interactive dans `map_runtime` ;
- compilation vers graphe ou commandes runtime sans exposer les détails au créateur ;
- validation avant sauvegarde et avant runtime.

La règle d'or : aucune action affichée dans l'éditeur ne doit être un simple placeholder produit.

## 19. Architecture conceptuelle par package

| Élément | Package recommandé | Responsabilité |
|---|---|---|
| Trigger definitions | `map_core` | Contrats typés des déclencheurs et sources possibles |
| Condition definitions | `map_core` | Prédicats stables, sérialisables, validables |
| Gameplay Action contracts | `map_core` | Union/catalogue typé des actions narratives gameplay |
| Runtime command executor | `map_runtime` | Exécuter les actions interactives : dialogue, battle, overlays, warp, shop |
| Mutations GameState | `map_gameplay` | Appliquer les effets purs : flags, party, bag, money, badges, progression |
| Story graph | `map_core` | Structure persistante des steps, chapters, transitions et facts |
| World rules | `map_core` + `map_runtime` | Modèle dans core, application visibilité/interaction dans runtime |
| Validation | `map_core` + `map_editor` | Règles de cohérence, références, actions impossibles |
| Preview/test runner | `map_editor` + `map_runtime` | Simuler facts, steps, triggers et rendu de map |

Répartition par package :

- `map_core` : contrats, modèles, sérialisation, migrations, validations pures. Il doit posséder les mots officiels : Trigger, Condition, Action, Story Step, World Rule, Fact.
- `map_gameplay` : mutations pures du `GameState`, évaluation de conditions, calculs sans Flutter ni Flame. Donner objet, donner badge, terminer step, vérifier party pleine doivent vivre ici quand ils sont purs.
- `map_runtime` : exécution interactive et effets dépendants du jeu lancé. Dialogue overlay, cutscene, battle handoff, shop UI, PC UI, warp visuel, mouvements PNJ.
- `map_editor` : authoring no-code. Pickers, labels humains, preview, validation, liens map <-> narrative. Il ne doit pas inventer des contrats runtime privés en metadata.
- `examples/playable_runtime_host` : golden narrative slice et fumée d'intégration.

Le `ScenarioAsset` peut rester un graphe d'exécution bas niveau, mais il ne doit plus être le seul endroit où l'auteur cache des structures macro en metadata JSON. La cible saine est : modèle auteur lisible -> compilation typée -> runtime executor.

## 20. Risques UX et pièges à éviter

- exposer les flags bruts ;
- mélanger Step et Cutscene ;
- rendre Global Story trop linéaire ;
- créer une UI jolie mais non exécutable ;
- faire des actions trop techniques ;
- forcer tous les jeux à commencer par un starter ;
- cacher les erreurs de scénario ;
- ne pas avoir de preview/test runner ;
- multiplier les synonymes : outcome, milestone, step, quest, flag, fact sans frontière ;
- laisser Dialogue devenir le moteur caché de toute la logique ;
- permettre des références libres à des ids inexistants ;
- afficher des actions qui ne sont pas supportées par le runtime ;
- oublier les branches post-combat victoire/défaite ;
- rendre les world rules impossibles à inspecter depuis la map ;
- rendre le mode avancé obligatoire pour terminer un jeu simple ;
- confondre "organisation auteur" et "ordre d'exécution".

## 21. Questions produit à trancher

- Un jeu doit-il pouvoir commencer avec une équipe déjà donnée ?
- Le choix starter est-il une action narrative ou une configuration de New Game ?
- Les flags doivent-ils être déclarés dans un registry ?
- Les quêtes sont-elles séparées de Global Story ?
- Cutscene et Scene doivent-elles être fusionnées ?
- Une Step peut-elle être optionnelle ?
- Peut-on avoir plusieurs branches principales ?
- Comment représenter les choix du joueur ?
- Quel niveau de complexité afficher en UI simple vs avancée ?
- Les dialogues branchés doivent-ils vivre dans Yarn, dans Narrative Studio, ou dans un modèle hybride ?
- Un trainer battu est-il un fact narratif, un état trainer dédié, ou les deux ?
- Les world rules sont-elles attachées aux entities de map ou centralisées dans le Narrative Studio ?
- Une action peut-elle échouer au runtime, et comment l'auteur le voit-il ?
- Faut-il un mode "simulation de GameState" dans l'éditeur ?
- Quels templates Pokémon-like sont fournis sans devenir obligatoires ?

## 22. Proposition de roadmap de refonte

Cette roadmap ne remplace pas la roadmap fangame mechanics. Elle propose une séquence produit courte pour cadrer la refonte Narrative Studio. Elle dépend fortement des lots gameplay autour des event commands no-code, party, bag, combat, badges, PC, shops et save/load.

| Lot | Objectif | Type | Dépendances | Risque | Priorité |
|---|---|---|---|---|---|
| N0 - Product Model Decision | Valider vocabulaire, frontières et modèle mental | Produit | Ce document | Moyen | Très haute |
| N1 - Facts / Flags Registry Design | Définir facts lisibles, ids techniques, variables et mode avancé | Produit + architecture | N0 | Moyen | Très haute |
| N2 - Trigger / Condition / Action Catalog Design | Spécifier le catalogue typé minimal | Architecture | N0, N1 | Élevé | Très haute |
| N3 - World Rules Model | Modéliser présence, interaction, accessibilité, dialogues alternatifs | Architecture | N1, N2 | Élevé | Haute |
| N4 - Story Step Model Cleanup | Clarifier Step inactive/active/completed et completion rules | Architecture + migration | N1, N3 | Élevé | Haute |
| N5 - Event Authoring Model | Définir EventRule attaché à PNJ, objet, zone, map, système gameplay | Produit + editor architecture | N2, N3 | Élevé | Haute |
| N6 - Runtime Executor Contract | Relier actions typées aux mutations et effets runtime | Architecture runtime | N2, gameplay systems | Très élevé | Haute |
| N7 - Narrative Studio UX Redesign | Repenser les écrans autour de rules, facts, steps, preview | UX | N0 à N6 | Moyen | Moyenne |
| N8 - Preview / Test Runner | Simuler facts, triggers, steps et world state dans l'éditeur | Tooling + runtime | N3, N6 | Élevé | Haute |
| N9 - Golden Narrative Slice | Prouver intro + starter + rival + reward + badge gate + shop/center simple | Intégration | N1 à N8 + lots gameplay | Très élevé | Très haute |

Ordre recommandé :

1. Décider le langage produit avant l'UI.
2. Définir le registry de facts avant d'ajouter plus de flags.
3. Définir le catalogue d'actions avant la refonte visuelle.
4. Prouver une golden slice narrative avant d'élargir les templates.

## 23. Conclusion

Le Narrative Studio voulu est un outil pour composer un monde jouable, pas pour éditer des variables.

La cible est claire :

- Global Story organise l'aventure ;
- Story Step décrit les jalons ;
- Event relie le monde aux règles ;
- Trigger démarre ;
- Condition filtre ;
- Action agit ;
- Reaction montre la conséquence ;
- World Rule rend le monde cohérent dans le temps ;
- flags et variables restent des détails techniques cachés derrière des faits lisibles.

La refonte ne doit pas commencer par un nouvel écran. Elle doit commencer par un langage produit stable et un catalogue de contrats exécutables. Une UI élégante sans runtime fiable reproduirait le problème actuel. Une architecture typée sans vocabulaire no-code resterait inaccessible.

La bonne question n'est donc pas : "Comment réparer le Narrative Studio actuel ?"

La bonne question est : "Comment permettre à un créateur de décrire simplement une aventure Pokémon-like complète, et de voir le monde répondre correctement ?"

Réponse V0 : faire du Narrative Studio le studio des situations, décisions et conséquences visibles de PokeMap.
