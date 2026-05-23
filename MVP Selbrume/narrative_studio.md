# Reprise projet PokeMap — Vision complète du futur Narrative Studio

Je reprends le projet **PokeMap** avec un focus prioritaire sur le **Narrative Studio**.

Le projet local est :

```text
/Users/karim/Project/pokemonProject
```

PokeMap est un éditeur/runtime Flutter/Flame de jeu Pokémon-like. L’objectif global n’est pas seulement de faire un éditeur de maps, mais un outil beaucoup plus ambitieux : une sorte de **RPG Maker Pokémon-like moderne**, no-code autant que possible, permettant à une personne non développeuse de créer un fangame court, jouable, cohérent, avec exploration, histoire, événements, combats, progression, quêtes, cinématiques, dialogues, sauvegarde et validation.

Le chantier actuel doit se concentrer sur le **Narrative Studio** : son modèle produit, sa représentation graphique, sa relation avec les maps, les events, les scènes, les cinématiques, Yarn Spinner, les faits du monde, les règles de monde, les quêtes annexes, les branches narratives et le validateur.

L’idée centrale est simple :

```text
Le créateur ne doit pas penser en flags techniques.
Il doit penser en situations, événements, décisions, conséquences, progression et changements visibles du monde.
```

Les flags existent probablement techniquement derrière. Mais ils ne doivent pas être l’expérience utilisateur principale.

---

# 1. Vision produit générale

Le Narrative Studio doit devenir l’endroit où l’on organise et orchestre tout ce qui fait qu’un jeu Pokémon-like a une vraie histoire jouable.

Il doit répondre à ces questions :

```text
Quelles histoires existent dans le jeu ?
Quelles étapes composent ces histoires ?
Quelles quêtes annexes existent ?
Quand une quête devient-elle disponible ?
Quels événements peuvent se déclencher sur les maps ?
Quelle scène est lancée quand le joueur parle à ce PNJ ?
Quelle cinématique est jouée quand le joueur choisit telle réponse ?
Quel dialogue Yarn est utilisé ?
Quelles décisions du joueur produisent quels résultats ?
Quels faits du monde sont mémorisés ?
Quels éléments de la map changent après un événement ?
Comment savoir si tout est atteignable et jouable ?
```

La phrase canonique du système est :

```text
Quand [déclencheur]
Si [conditions]
Alors [actions / scène / dialogue / combat / cinématique]
Puis [conséquences / faits / changements du monde]
```

Mais cette phrase ne doit pas être forcément affichée partout de manière brute. Elle sert surtout de grammaire interne.

---

# 2. Le problème de l’ancien Narrative Studio

L’ancien système avait des concepts séduisants :

```text
Global Story
Step Studio
Cutscene Studio
Dialogue Studio
```

Mais il était trop ambigu.

Les problèmes principaux :

```text
Global Story était trop linéaire.
Story Step et Cutscene se marchaient dessus.
Cutscene pouvait être confondu avec progression narrative.
Le système de flags était trop technique.
Les quêtes annexes ne rentraient pas proprement dans le modèle.
La map n’était pas assez reliée aux événements narratifs.
Les scènes n’étaient pas clairement séparées des cinématiques.
Yarn pouvait devenir un deuxième moteur narratif caché.
La représentation graphique était belle mais pas assez structurée.
```

Il ne faut pas forcément tout jeter. Mais il faut **redéfinir les frontières**.

---

# 3. Modèle canonique retenu

Les concepts principaux du futur Narrative Studio doivent être :

```text
Storyline
Chapter
Story Step
Event
Scene
Cinematic
Dialogue Yarn
Fact
World Rule
Validator
```

Ces concepts doivent avoir des rôles strictement séparés.

---

# 4. Storyline

Une **Storyline** représente une ligne narrative complète.

Elle peut être :

```text
Histoire principale
Quête annexe
Tutoriel
Épilogue
Post-game
Événement caché
```

Une Storyline n’est pas forcément linéaire. Elle peut avoir des branches, des conditions d’accès, des étapes optionnelles, des fins alternatives ou des convergences.

Exemples pour le jeu test “Les Brumes de Selbrume” :

```text
Histoire principale : La brume du phare
Quête annexe : Les cristaux de sel
Quête annexe : Le Goélise du port
Quête annexe : La cabane du phare
Tutoriel : Premier combat
Épilogue : Le phare rallumé
```

On ne doit plus penser uniquement “Global Story”. On doit penser :

```text
Storylines = ensemble des lignes narratives du projet.
```

L’ancienne “Global Story” peut devenir :

```text
Storyline principale
```

ou

```text
Histoire principale
```

Mais elle ne doit plus être le seul conteneur de tout.

---

# 5. Chapter

Un **Chapter** sert à organiser une Storyline.

Il permet de ranger les steps, les scènes et les cinématiques par gros moment narratif.

Exemple :

```text
Histoire principale : La brume du phare

Chapitre 1 — Le port
- Départ à Selbrume
- Aller au port
- Combat rival

Chapitre 2 — Les marais
- Enquête dans les marais
- Signal étrange
- Sauvetage du pêcheur

Chapitre 3 — Le phare
- Accès au phare
- Ascension du phare
- Affrontement final
- Épilogue
```

Les chapitres ne doivent pas être une contrainte trop rigide. Ils servent surtout à organiser, filtrer, retrouver, afficher et comprendre.

Ils doivent pouvoir être utilisés dans :

```text
Storyline Graph
Scenes Library
Cinematics Library
Cinematic Builder
Validator
```

---

# 6. Story Step

Une **Story Step** est un jalon logique de progression.

Elle ne doit pas être une scène.

Elle ne doit pas être une cinématique.

Elle ne doit pas contenir toute la logique jouée à l’écran.

Elle dit plutôt :

```text
Où en est le joueur dans cette Storyline ?
Quel objectif ou jalon a été atteint ?
Qu’est-ce qui doit être actif, terminé ou disponible ?
```

Exemples :

```text
Recevoir son starter
Aller au port
Affronter le rival
Trouver les indices
Débloquer le Passage des Dames
Explorer le phare
Apaiser le Pokémon du phare
```

Une Step peut avoir des états :

```text
Inactive
Disponible
Active
Completed
Failed
Skipped
Locked
Optional
```

En V0, on peut rester simple :

```text
Inactive
Active
Completed
```

Mais il faut penser à l’évolution.

Une Step doit pouvoir avoir :

```text
conditions d’activation
conditions de complétion
events liés
scènes liées
facts produits
world rules associées
quêtes débloquées
```

Exemple :

```text
Step : Combat rival

Active si :
- Step “Aller au port” completed

Completed si :
- Fact “Rival battu au port” vrai

Events liés :
- PNJ Rival → parler → Event “Rencontre rival au port”

Scènes liées :
- Scene “Rencontre rival”
- Scene “Après victoire rival”
- Scene “Après défaite rival”

Conséquences :
- Si victoire : le rival bat en retraite
- Si défaite : le rival triomphe mais l’histoire peut continuer
```

---

# 7. Event

Un **Event** est une règle de déclenchement locale.

C’est la grosse pièce manquante du modèle actuel.

Un Event répond à :

```text
Quand quelque chose arrive ?
Dans quelles conditions ?
Qu’est-ce qu’on lance ?
Quelles réactions sont exécutées ?
Qu’est-ce qui change dans le monde ?
```

Un Event est généralement attaché à :

```text
un PNJ
une zone de map
un objet interactif
une porte
un coffre
un panneau
un dresseur
un changement de map
un résultat de combat
une fin de scène
```

Exemples :

```text
Parler au rival au port
Entrer dans la zone du quai
Ramasser une Poké Ball
Ouvrir la porte de la cabane du phare
Parler à Mado
Battre le rival
Trouver un cristal de sel
```

L’Event ne doit pas être confondu avec une Scene.

La différence canonique est :

```text
Event = pourquoi / quand quelque chose démarre.
Scene = ce qui se déroule une fois que c’est démarré.
```

Exemple :

```text
Event : Parler au rival au port

Quand :
- Le joueur interagit avec le PNJ Rival

Si :
- Step “Aller au port” active
- Fact “Rival battu” faux

Alors :
- Lancer Scene “Rencontre rival”
- Puis éventuellement lancer combat

Après :
- Si victoire : set Fact “Rival battu”
- Si défaite : set Fact “Rival défaite joueur”
```

Graphiquement, l’Event Builder peut être plus structuré, moins “graph libre” que le Scene Builder :

```text
Déclencheur
→ Conditions
→ Actions
→ Récompenses
→ Changements de monde
→ Fin de l’événement
```

C’est très lisible pour un créateur no-code.

---

# 8. Scene

Une **Scene** est une orchestration narrative.

Elle orchestre :

```text
dialogues Yarn
outcomes Yarn
cinématiques linéaires
combats
actions
branches locales
merge
résultats finaux
```

Une Scene est **graphique**. On aime beaucoup la représentation sous forme de graph, parce qu’elle est très parlante.

La Scene répond à :

```text
Qu’est-ce qui se déroule ?
Dans quel ordre ?
Quels dialogues sont joués ?
Quel outcome produit Yarn ?
Quelle cinématique est lancée selon l’outcome ?
Est-ce qu’on rejoint une fin commune ?
Quel résultat la Scene émet-elle ?
```

Exemple :

```text
Scene : Annonce au port

Start
→ Dialogue Yarn : alerte_port
→ Branch by outcome
    panic → Play Cinematic : cinematic_panic
    reassure → Play Cinematic : cinematic_reassure
→ Merge
→ Action : lancer combat rival optionnel
→ Emit Scene Outcome : crowd_panicked ou crowd_reassured
→ End
```

Très important :

```text
Une Scene peut brancher.
Une Cinematic ne branche pas.
```

La Scene est l’orchestrateur. Elle peut choisir quelle cinématique linéaire lancer.

---

# 9. Cinematic

Une **Cinematic** est une séquence linéaire jouée à l’écran.

Elle ne doit pas contenir de branches.

Elle ne doit pas gérer la progression.

Elle ne doit pas modifier directement la Storyline.

Elle doit être un outil de mise en scène :

```text
caméra
mouvements PNJ
emotes
sons
musique
FX
dialogue simple si besoin
fondu
shake caméra
attente
placement d’acteurs
timeline
```

Le futur **Cinematic Builder** doit être un vrai outil de montage / chorégraphie visuelle.

Il doit combiner :

```text
Storyboard
Blocking
Timeline
Validation
```

## 9.1 Storyboard

Vue par plans :

```text
Plan 1 : la caméra montre le port
Plan 2 : Lysa arrive
Plan 3 : la foule panique
Plan 4 : fondu vers le phare
```

## 9.2 Blocking

Vue sur la map :

```text
où sont les acteurs ?
où commence le joueur ?
où va Lysa ?
où est le cadre caméra ?
où commence et finit la trajectoire ?
```

## 9.3 Timeline

Vue précise :

```text
Caméra : pan → zoom → shake → pan final
Joueur : déplacement joueur
Lysa : course → arrêt → réaction
Gardien : regarde joueur → avance vers Lysa
Foule : réaction foule → dispersion
Dialogue : dlg_intro → dlg_panique
Audio : cloche → ambiance port → alertes
FX : brouillard → fondu noir
```

Le Cinematic Builder doit être en **mode sombre**. C’est là qu’il est le plus beau et le plus lisible. On a validé que le mode sombre donne un côté outil de montage / création visuelle beaucoup plus fort.

Le mantra :

```text
Scene Builder = cerveau d’orchestration.
Cinematic Builder = chorégraphe visuel.
Event Builder = règles de déclenchement.
Storyline Graph = carte de progression.
```

---

# 10. Dialogue Yarn / Yarn Spinner

Yarn Spinner est utilisé pour les dialogues.

Yarn peut contenir des choix et des variables. C’est puissant, mais dangereux si on le laisse devenir le moteur caché du scénario.

Règle canonique :

```text
Yarn raconte et produit des outcomes.
Scene lit les outcomes et orchestre la suite.
Event applique les conséquences persistantes.
Storyline progresse via Facts / Steps.
```

Yarn ne doit pas devenir propriétaire de toute la progression.

À éviter :

```text
Yarn termine directement une Story Step.
Yarn donne directement des objets.
Yarn débloque directement des routes.
Yarn modifie 12 flags techniques en douce.
```

À préférer :

```text
Yarn retourne outcome = panic
Scene joue cinematic_panic
Scene émet sceneOutcome = crowd_panicked
Event décide si ce résultat doit devenir un Fact persistant
World Rules changent le monde si besoin
```

Exemple :

```text
Dialogue Yarn : alerte_port

Choix :
- “Oh mon Dieu, on va tous mourir !”
- “Non, restez calmes.”

Outcomes :
- panic
- reassure
```

Puis :

```text
Scene :
panic → Play Cinematic cinematic_panic
reassure → Play Cinematic cinematic_reassure
```

Puis si nécessaire :

```text
Event :
si sceneOutcome = crowd_panicked
  → SetFact(port_crowd_panicked)

si sceneOutcome = crowd_reassured
  → SetFact(port_crowd_reassured)
```

La persistance doit être une décision explicite. Tout ce qui ne sert que pendant la scène reste local.

---

# 11. Fact

Un **Fact** est un fait lisible du monde.

C’est l’équivalent UX d’un flag, mais formulé humainement.

Exemples :

```text
Starter reçu
Rival battu au port
Clé du phare obtenue
Accès au phare débloqué
Cristal 1 ramassé
Port rassuré
Port paniqué
Mado a demandé de l’aide
Quête Goélise acceptée
```

Le créateur ne doit pas manipuler :

```text
flag_rival_port_defeated = true
```

Il doit manipuler :

```text
Rival battu au port
```

L’ID technique peut exister, mais dans une section avancée :

```text
Détails avancés
- id: story.rival.port.defeated
```

Le Fact peut être :

```text
booléen
numérique
texte
enum
compteur
collection simple
```

Mais en V0, on peut commencer par des booléens et quelques compteurs simples.

---

# 12. World Rule

Une **World Rule** change l’apparence ou le comportement du monde selon des Facts / Steps / Conditions.

Elle répond à :

```text
Ce PNJ est-il visible ?
Cette porte est-elle ouverte ?
Cet objet est-il encore ramassable ?
Ce dialogue doit-il changer ?
Cette zone est-elle active ?
Cette route est-elle débloquée ?
```

Exemples :

```text
PNJ Rival visible si “Rival battu au port” est faux.
Porte du phare utilisable si “Clé du phare obtenue” est vrai.
Cristal de sel disparaît si “Cristal 1 ramassé” est vrai.
Pêcheur propose la quête si “Combat rival terminé” est vrai.
Zone d’alerte active si “Aller au port” est active.
```

Le Map Editor doit devenir un point d’entrée naturel des World Rules.

Quand on sélectionne un élément de map, on doit pouvoir configurer :

```text
Visible si…
Actif si…
Déclenche quand…
Change après…
Disparaît après…
Dialogue alternatif si…
```

Mais sans exposer des flags bruts.

---

# 13. Relation avec la map

Le Narrative Studio ne doit pas être isolé. Il doit être relié à la World Map / Map Editor.

Quand l’utilisateur pose un PNJ, une zone, une porte, un objet ou un dresseur, il doit pouvoir dire :

```text
Ce PNJ lance quel Event quand on lui parle ?
Cette zone déclenche quelle Scene quand on y entre ?
Cette porte s’ouvre sous quelle condition ?
Cet objet disparaît après quel Fact ?
Ce dresseur est considéré battu quand quel combat est gagné ?
Ce PNJ change de dialogue quand quelle Step est completed ?
```

La map doit donc supporter deux grandes familles narratives :

```text
Events
World Rules
```

Chaque élément important de map peut avoir :

```text
World Rules :
- Visible si…
- Actif si…
- Dialogue variant si…
- État visuel si…

Events :
- On interact
- On enter zone
- On inspect
- On battle won
- On battle lost
- On collect
```

---

# 14. Relation avec les combats

Le Narrative Studio doit être capable de lancer des combats, mais il ne doit pas contenir la logique interne du moteur de combat.

Il doit pouvoir dire :

```text
Lancer combat trainer Rival_Port
Si victoire :
  - SetFact Rival battu
  - Terminer Step Combat rival
  - Donner argent / XP / objet
  - Jouer Scene après victoire

Si défaite :
  - SetFact Joueur a perdu contre Rival
  - Jouer Scene après défaite
  - Revenir au centre Pokémon ou continuer selon configuration
```

Le combat produit des outcomes :

```text
victory
defeat
flee
capture
draw / interrupted éventuellement plus tard
```

Le Narrative/Event System doit pouvoir réagir à ces outcomes.

---

# 15. Relation avec les quêtes annexes

Une quête annexe est une **Storyline secondaire**, pas un système complètement séparé au départ.

Elle peut avoir :

```text
conditions de disponibilité
conditions d’activation
steps
events liés
récompenses
état dans le journal
expiration optionnelle
visibilité dans l’UI joueur
```

Exemple :

```text
Side Storyline : Les cristaux de sel

Disponible si :
- Step “Aller au port” completed
- Zone “Marais Salants” accessible

Step 1 : Parler à Mado
Step 2 : Trouver 3 cristaux
Step 3 : Retourner voir Mado
Step 4 : Recevoir la récompense

Events :
- Interagir avec cristal 1
- Interagir avec cristal 2
- Interagir avec cristal 3
- Parler à Mado après collecte

Facts :
- Cristal 1 ramassé
- Cristal 2 ramassé
- Cristal 3 ramassé
- Quête cristaux terminée
```

Pour une quête type Mewtwo, elle peut exister dans le projet mais être cachée :

```text
Disponible si :
- Ligue terminée
- Accès grotte finale débloqué
```

Donc elle ne pollue pas le début du jeu.

---

# 16. Relation avec les scènes et les cinématiques

Il faut une séparation nette :

```text
Scene = graph d’orchestration.
Cinematic = séquence linéaire.
Dialogue Yarn = contenu dialogue / choix.
Event = déclencheur local.
```

Exemple complet :

```text
Event : Entrer dans la zone du port

Quand :
- Le joueur entre dans Zone_Port_Alert

Si :
- Step “Aller au port” active
- Fact “Alerte port déjà jouée” faux

Alors :
- Jouer Scene “Annonce au port”

Scene “Annonce au port” :
- Dialogue Yarn “alerte_port”
- Branch by outcome :
    panic → Play Cinematic “panic_port”
    reassure → Play Cinematic “reassure_port”
- Merge
- Emit Scene Outcome “port_alert_resolved”

Event, après Scene :
- SetFact “Alerte port déjà jouée”
- Selon outcome :
    panic → SetFact “Port paniqué”
    reassure → SetFact “Port rassuré”
```

---

# 17. UI globale souhaitée

On a validé une direction visuelle très forte : **mode sombre premium** pour le Narrative Studio, ou au minimum pour les écrans les plus visuels.

L’identité validée :

```text
dark navy / charcoal
accents bleu, vert, teal, violet, jaune
panneaux arrondis
typographie nette
beaucoup de lisibilité
graphs très visuels
interface pro mais pas froide
ambiance outil de création
```

On a particulièrement aimé :

```text
Storyline Graph en dark mode
Scene Builder en graph
Cinematic Builder V2 sombre avec timeline
Validator sombre
Cinematics Library sombre
Event Builder sombre
```

Règle UX possible :

```text
Écrans de gestion : clair ou sombre selon préférence.
Écrans de création visuelle : sombre recommandé.
```

Mais vu les mockups, le dark mode pourrait devenir le thème principal du Narrative Studio.

---

# 18. Écrans principaux du futur Narrative Studio

## 18.1 Narrative Overview / Aperçu

C’est le dashboard du Narrative Studio.

Il montre :

```text
nombre de chapitres
nombre de scènes
nombre de cinématiques
nombre de quêtes
histoire principale
progression
quêtes annexes
dialogues
facts
world rules
activité récente
structure narrative sélectionnée
```

Il sert à comprendre le projet d’un coup d’œil.

---

## 18.2 Storylines Board

Écran pour gérer les Storylines.

Il doit montrer :

```text
Histoire principale
Quêtes annexes
Tutoriels
Épilogue
Post-game
```

Chaque Storyline affiche :

```text
type
chapitres
steps
events liés
maps liées
état de validation utile
```

Les statuts doivent être orientés jouabilité, pas gestion de projet.

À éviter :

```text
On Track
Ready
High priority
Updated by
```

À préférer :

```text
Jouable
Incomplet
Non atteignable
À tester
Erreur
Sans début
Sans fin
```

---

## 18.3 Storyline Graph

Écran majeur.

Il affiche une Storyline comme un graph macro.

Il doit montrer :

```text
chapters / swimlanes
steps
branches
convergences
quêtes annexes liées
steps optionnelles
conditions d’accès
issues / outcomes majeurs
```

Exemple :

```text
Chapitre 1 — Le port
Départ à Selbrume → Aller au port → Combat rival
                                      ├─ Le rival bat en retraite
                                      └─ Le rival triomphe
                                               ↓
Chapitre 2 — Les marais
Enquête dans les marais
  ↙ Signal étrange
  ↘ Sauvetage du pêcheur

Chapitre 3 — Le phare
Accès au phare → Ascension du phare → Affrontement final → Épilogue
```

C’est une vue de progression, pas une vue de détails de chaque dialogue.

---

## 18.4 Scenes Library

Bibliothèque des scènes uniquement.

Important :

```text
Une Scene n’est pas une Cinematic.
```

Elle doit être organisée par :

```text
Storyline
Chapter
Dossier / contexte
```

Elle affiche :

```text
nom
storyline
chapitre
events liés
dialogues Yarn utilisés
cinématiques appelées
outcomes émis
facts émis
état de validation
```

---

## 18.5 Scene Builder

Écran graph.

Il doit permettre de construire une Scene avec des nodes :

```text
Start
Dialogue Yarn
Branch by outcome
Condition
Play Cinematic
Play Combat
Action
Reward
Merge
Emit Scene Outcome
End
```

Cet écran est très important visuellement. Les scènes sous forme de graph sont une excellente idée : c’est beau, parlant et adapté aux branches.

Il doit aussi permettre de voir les liens :

```text
Déclencheur de map
Dialogue Yarn
Cinématiques appelées
Combats lancés
Outcomes produits
Facts produits
```

---

## 18.6 Cinematics Library

Bibliothèque des cinématiques uniquement.

Titre clair :

```text
Bibliothèque des cinématiques
```

Pas :

```text
Scenes & Cinematics Library
```

L’écran doit contenir uniquement des cinématiques linéaires.

Organisation :

```text
Storyline
Chapter
Lieu
Scène parente
Dossier
```

Chaque cinematic affiche :

```text
thumbnail
durée
lieu / chapitre
scène liée
storyline liée
tags éditoriaux
outcomes possibles si utilisés par une scène
notes
```

Pas de statuts “On Track”.

---

## 18.7 Cinematic Builder V2

Le plus visuel.

Il doit contenir :

```text
Project/cinematic tree par chapitre
Palette d’actions
Presets rapides
Storyboard strip
Preview viewport
Blocking actors
Camera frame
Trajectoires
Timeline multi-pistes
Inspector
Acteurs requis
Validation locale
```

Actions disponibles :

```text
Caméra
Déplacement acteur
Dialogue
Émote
Son
FX
Attente
Fondu
Shake caméra
Trigger script
```

Presets rapides :

```text
Entrée PNJ
Panique foule
Arrivée dramatique
Caméra pan
Fondu noir
```

Timeline :

```text
Caméra
Joueur
PNJ
Foule
Dialogue
Audio
FX
```

La cinématique reste linéaire.

---

## 18.8 Map Events View

Écran reliant la map au narratif.

Il doit permettre de sélectionner une map et voir :

```text
PNJ
Zones
Objets
Portes
Dresseurs
Coffres
Panneaux
```

Pour chaque élément :

```text
Events attachés
World Rules
Conditions de visibilité
Dialogues alternatifs
Scènes déclenchées
Étapes liées
Facts produits
```

Exemple :

```text
Map : Port Selbrume

PNJ Rival
- Event : Rencontre rival au port
- Visible si Rival battu = faux
- Dialogue alternatif si Rival battu = vrai
- Scene liée : Rencontre rival

Zone Quai central
- Event : Annonce au port
- Active si Step Aller au port active
- One-shot si Alerte port déjà jouée = faux
```

---

## 18.9 Event Builder

Écran de règles locales.

Structure recommandée :

```text
Déclencheur
Conditions
Actions
Récompenses
Changements de monde
Comportement
```

Il doit être plus formulaire / blocs que graph libre, pour rester très clair.

Exemple :

```text
Event : Rencontre rival au port

Déclencheur :
- Interaction avec PNJ
- Cible : Rival
- Portée : Port Selbrume

Conditions :
- Step “Aller au port” active
- Fact “Rival battu” faux

Actions :
- Jouer Scene “Rencontre rival”
- Lancer Combat “Rival”

Récompenses :
- XP joueur : 250
- Argent : ₽1200
- Objet : Potion x2

Changements de monde :
- Fact “Rival battu” = vrai
- PNJ Rival désactivé / déplacé / dialogue changé

Comportement :
- Réutilisation : une seule fois
- Réinitialisation : jamais
```

---

## 18.10 Facts & World Rules

Écran de gestion des faits et règles du monde.

Il doit montrer des noms lisibles :

```text
Starter reçu
Rival battu au port
Clé du phare obtenue
Accès au phare débloqué
Cristaux purifiés
Port rassuré
Port paniqué
```

Et des règles :

```text
Porte du phare utilisable si Clé du phare obtenue.
Cristal disparaît si Cristal 1 ramassé.
Rival change de dialogue si Rival battu au port.
Quête Goélise disponible si Combat rival completed.
```

Les IDs techniques doivent être cachés dans une section avancée.

---

## 18.11 Validator

Écran indispensable.

Il remplace les statuts vagues.

Il doit détecter :

```text
Storyline sans début
Storyline sans fin
Step non atteignable
Step sans event
Event sans trigger
Event sans action
Scene appelée mais inexistante
Cinematic référencée mais inexistante
Dialogue Yarn non référencé
Outcome Yarn non géré
Branch impossible
World Rule qui pointe vers élément de map absent
Fact jamais produit
Fact utilisé mais jamais déclaré
Quest sans condition d’activation
Quest impossible à terminer
Conflit de facts
Cinematic avec acteur manquant
Cinematic avec clip hors timeline
```

Il doit proposer des corrections :

```text
Ouvrir l’éditeur
Voir les events
Ajouter une condition
Lier une scène
Créer le fact manquant
Corriger le lien cassé
```

C’est vital pour un outil no-code.

---

# 19. Scénario test : Les Brumes de Selbrume

On utilise ce mini-jeu comme scénario de test du modèle.

Pitch :

```text
Sur l’île de Selbrume, une brume étrange se lève chaque soir.
Le phare semble dysfonctionner.
Les pêcheurs n’osent plus sortir.
Les Pokémon sauvages deviennent nerveux.
Le joueur doit aider les habitants à comprendre ce qui perturbe l’île.
```

Zones :

```text
Bourg de Selbrume
Port des Brisants
Bois de la Chaise-Brume
Marais Salants
Passage des Dames
Vieux Phare d’Écume
```

Histoire principale :

```text
Acte 1 : mission du garde-nature, arrivée au port, rival
Acte 2 : enquête forêt / marais / indices
Acte 3 : passage vers le phare, confrontation finale, brume dissipée
```

Quêtes annexes :

```text
Les cristaux de sel
Le Goélise du port
La cabane du phare
```

Ce scénario teste :

```text
Storylines principales et secondaires
Chapters
Story Steps
Events map
Scenes graph
Yarn outcomes
Cinematics linéaires
Battle outcomes
World Rules
Facts
Quest availability
Validator
```

---

# 20. Architecture conceptuelle par package

## map_core

Doit contenir :

```text
modèles purs
contrats JSON
facts
storyline models
steps
events contracts
scene graph models
cinematic metadata models
world rules
validators purs
diagnostics
```

Pas Flutter.

Pas Flame.

Pas runtime direct.

Pas UI.

## map_gameplay

Doit contenir :

```text
mutations pures GameState
évaluation de conditions
application de facts
résolution de disponibilité de quêtes
progression steps/storylines
résolution world rules
```

## map_battle

Doit rester le moteur de combat.

Il produit des outcomes :

```text
victory
defeat
capture
flee
etc.
```

Le Narrative System consomme ces outcomes, mais le moteur battle ne doit pas connaître tout le Narrative Studio.

## map_runtime

Doit exécuter :

```text
events déclenchés en jeu
scene engine
cinematic playback
dialogue Yarn runtime
battle handoff
world rules appliquées à la map
save/load GameState
menus joueur
```

## map_editor

Doit contenir :

```text
Narrative Studio UI
Storyline Graph
Scene Builder
Cinematic Builder
Event Builder
Map Events View
Facts & World Rules UI
Validator UI
```

---

# 21. Règles non négociables

```text
Ne pas exposer les flags techniques comme UX principale.
Ne pas mélanger Scene et Cinematic.
Ne pas mettre de branches dans les Cinematics.
Ne pas laisser Yarn piloter toute la progression du jeu en douce.
Ne pas faire de Global Story un conteneur unique de tout.
Ne pas coder avant d’avoir stabilisé le modèle produit.
Ne pas mélanger ce chantier avec Surface, Shadow, Environment, Path.
Ne pas faire de refactor massif.
Ne pas faire de système de quête séparé trop tôt si Storyline secondaire suffit.
Ne pas oublier le Validator.
Ne pas oublier la relation avec la map.
```

---

# 22. Décisions validées

## Décision 1 — Le Narrative Studio doit être centré sur des concepts humains

L’utilisateur manipule :

```text
étapes
histoires
événements
scènes
cinématiques
faits du monde
règles de monde
```

Pas des flags bruts.

## Décision 2 — Les quêtes annexes sont des Storylines secondaires

Pas besoin d’un Quest Studio totalement séparé au départ.

## Décision 3 — Les scènes sont des graphs

C’est beau, lisible et adapté aux branches.

## Décision 4 — Les cinématiques restent linéaires

Pas de branches dans le moteur de cinématique.

Si une réponse Yarn doit provoquer une réaction différente, la Scene choisit quelle Cinematic linéaire jouer.

## Décision 5 — Yarn produit des outcomes, pas toute la progression

Yarn influence la Scene. La Scene émet un outcome. L’Event ou le Narrative System décide de persister.

## Décision 6 — La map doit porter Events + World Rules

Chaque élément narratif de map doit pouvoir déclencher ou changer selon la progression.

## Décision 7 — Le Validator est central

Il garantit que le contenu est jouable, atteignable et cohérent.

## Décision 8 — Le mode sombre est excellent pour le Narrative Studio

Surtout pour :

```text
Storyline Graph
Scene Builder
Cinematic Builder
Event Builder
Validator
```

---

# 23. Roadmap proposée pour la suite

Avant d’implémenter, il faut faire un chantier produit/design très propre.

## N0 — Narrative Studio Canonical Product Model V1

Objectif :

```text
Écrire le document canonique qui fixe les concepts, frontières, responsabilités, vocabulaire, relations et non-goals.
```

Livrable :

```text
reports/gameplay/narrative_studio_canonical_product_model_v1.md
```

Aucun code.

## N1 — Existing Narrative Studio Audit vs Canonical Model

Objectif :

```text
Auditer l’existant et le comparer au modèle canonique.
```

Questions :

```text
Quels modèles existent ?
Quels écrans existent ?
Qu’est-ce qui est réutilisable ?
Qu’est-ce qui est à jeter ?
Qu’est-ce qui est dangereux ?
```

Aucun code.

## N2 — Narrative Domain Model Design

Objectif :

```text
Définir les modèles map_core futurs :
Storyline, Chapter, Step, Event, SceneGraph, SceneNode, CinematicAsset, Fact, WorldRule.
```

Aucun code au départ.

## N3 — UX Blueprint / Screen-by-Screen Specification

Objectif :

```text
Transformer les mockups en spécification UI détaillée écran par écran.
```

Écrans :

```text
Overview
Storylines Board
Storyline Graph
Scenes Library
Scene Builder
Cinematics Library
Cinematic Builder
Map Events View
Event Builder
Facts & World Rules
Validator
```

## N4 — Prototype Read-only Narrative Studio Shell

Objectif :

```text
Refaire le shell UI du Narrative Studio en lecture seule, avec navigation propre et données mockées.
```

Pas de mutation.

## N5 — Storyline Graph Read-only V0

Objectif :

```text
Afficher une storyline sous forme de graph avec chapters, steps, branches et inspector.
```

## N6 — Scene Builder Graph Read-only V0

Objectif :

```text
Afficher une Scene sous forme de graph avec nodes, outcomes, cinematic calls, merge et inspector.
```

## N7 — Cinematics Library V0

Objectif :

```text
Séparer clairement Cinematics Library des Scenes.
```

## N8 — Cinematic Builder V2 Shell

Objectif :

```text
Créer l’écran sombre Storyboard / Blocking / Timeline / Validation en shell UI.
```

Pas encore runtime complet.

## N9 — Event Builder V0

Objectif :

```text
Créer l’écran trigger → conditions → actions → changes.
```

## N10 — Facts & World Rules Registry V0

Objectif :

```text
Créer un registry lisible des facts et règles du monde.
```

## N11 — Map Events Integration Design

Objectif :

```text
Définir comment les éléments de map portent des events et world rules.
```

## N12 — Validator Design V0

Objectif :

```text
Définir les diagnostics narratifs prioritaires.
```

## N13 — Golden Narrative Slice Selbrume

Objectif :

```text
Implémenter une mini-chaîne complète :
Parler au rival → Yarn outcome → Scene branch → Cinematic → Combat → Fact → Step completed → World Rule.
```

C’est le premier vrai test de bout en bout.

---

# 24. Ce que le premier golden slice devrait tester

Golden slice recommandé :

```text
Storyline : La brume du phare
Chapter : Chapitre 1 — Le port
Step : Combat rival
Map : Port Selbrume
PNJ : Rival
Event : Rencontre rival au port
Scene : Rencontre rival
Dialogue Yarn : rival_intro
Combat : Rival_Port
Facts :
- rival_port_defeated
- rival_port_lost_once
World Rules :
- Rival change de dialogue après victoire
- Une quête annexe devient disponible
```

Flux :

```text
Le joueur parle au Rival.
L’Event vérifie les conditions.
Il lance la Scene.
La Scene joue Yarn.
Yarn retourne un outcome de ton.
La Scene lance une cinématique adaptée.
Puis elle lance le combat.
Le combat retourne victoire ou défaite.
L’Event applique les conséquences.
La Step avance.
Le Validator confirme que tout est atteignable.
```

Si ce golden slice fonctionne, le modèle tient debout.

---

# 25. Résumé ultra court de la vision

Le futur Narrative Studio doit être :

```text
Un outil visuel pour organiser des Storylines,
découper l’histoire en Chapters et Steps,
déclencher des Events depuis les maps,
orchestrer des Scenes en graph,
jouer des Cinematics linéaires,
utiliser Yarn pour les dialogues et outcomes,
cacher les flags derrière des Facts lisibles,
changer le monde via des World Rules,
et valider que tout est jouable.
```

La structure mentale finale :

```text
Storyline
  → Chapter
    → Story Step

Map Element
  → Event
    → Scene
      → Dialogue Yarn
      → Branch by outcome
      → Play Cinematic
      → Play Combat
      → Emit Scene Outcome

Event / Gameplay
  → Set Fact
  → Complete Step
  → Unlock Quest
  → Apply World Rule

Validator
  → vérifie que tout est atteignable, cohérent et jouable.
```

La phrase finale à garder :

```text
Le Narrative Studio ne doit pas être un éditeur de flags.
Il doit être un éditeur de situations, de décisions, de scènes et de conséquences.
```

C’est ça, le cœur du chantier.
