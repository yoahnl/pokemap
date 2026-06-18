# NS-EVENT-17 — Event Builder Target Layout Alignment Plan

## 1. Résumé exécutif

### Verdict

L’Event Builder actuel est adapté à un **MVP fonctionnel** : il permet déjà de créer un brouillon, sélectionner une map active, choisir une position explicite, renommer l’événement, éditer le type de déclencheur, choisir une scène principale, choisir le comportement, ajouter/retirer des conditions Fact et Event consumed, préserver les conditions legacy avancées, afficher des diagnostics et garder une navigation Narrative Studio lisible.

Il n’est pas encore adapté à une **V1 proche de l’image cible**. L’écran actuel reste construit comme une interface de chantier fonctionnelle : liste à gauche, création/position encore très présente, puis un grand panneau de détail qui contient à la fois le builder, l’inspecteur et les contrôles d’édition. La cible Yoahn demande une séparation plus nette :

- liste d’événements ;
- bibliothèque d’éléments ;
- builder central en blocs ;
- inspecteur droit ;
- validation / aperçu.

Le principal problème à corriger est donc la **séparation des responsabilités UI**. La grille de position est utile, mais elle attire trop l’attention par rapport au futur builder. Elle doit devenir un outil secondaire de création, pas l’axe principal de l’écran.

### Estimation synthétique

| Périmètre | Lots UI restants estimés | Décision |
|---|---:|---|
| MVP fonctionnel actuel | 0 | Déjà atteint par NS-EVENT-09 à NS-EVENT-16. |
| MVP agréable | 3 à 4 | Compacter la création, installer les blocs centraux, clarifier les détails avancés, refaire une Visual Gate. |
| V1 proche image cible | 7 à 9 | Ajouter bibliothèque, builder central, inspecteur droit, blocs Monde/Résultats/Réactions placeholder ou partiels, validation plus visible. |
| V1 avec drag/drop | 11 à 15 | À repousser après stabilisation du layout et des opérations add-by-click. |

### Prochain lot recommandé

Je recommande de démarrer par :

```text
NS-EVENT-18 — Creation Panel Compact / Collapsible V0
```

Raison : la grille de position est utile pour créer un brouillon, mais elle occupe encore une place de premier plan. Avant d’ajouter une bibliothèque ou un inspecteur droit, il faut la rendre secondaire et repliable pour libérer le centre de gravité du futur builder.

## 2. État actuel de l’Event Builder

### Sources utilisées

- Référence cible fournie par Yoahn : `/Users/karim/Desktop/assets/pokeMap/définitive/4 - événements/1 - événements.png`.
- Visual Gate NS-EVENT-16 bloc layout : `reports/narrativeStudio/events/screenshots/ns_event_16_block_layout_consolidation_v0.png`.
- Visual Gate NS-EVENT-16 map activation : `reports/narrativeStudio/events/screenshots/ns_event_16_map_activation_creation_availability_v0.png`.
- Code : `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`.
- Code : `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`.
- Code : `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`.
- Tests : `packages/map_editor/test/event_builder_workspace_test.dart`.
- Rapports NS-EVENT-13 à NS-EVENT-16.

### Structure visible actuelle

D’après la Visual Gate `ns_event_16_block_layout_consolidation_v0.png`, l’écran actuel contient :

- sidebar Narrative Studio ;
- header `Événements` ;
- métriques : total, actifs, brouillons, diagnostics, portée map ;
- badge de position requise quand aucune position n’est sélectionnée ;
- colonne gauche `Liste d’événements` ;
- carte d’événement sélectionnable ;
- panneau `Créer un événement` sous la liste ;
- grille de position V0 dans la colonne gauche ;
- grand panneau `Builder d’événement` à droite ;
- sections : `Identité`, `Déclencheur`, `Conditions`, `Action principale`, `Comportement`, `Changements du monde`, `Diagnostics`, `Informations techniques`.

D’après la Visual Gate `ns_event_16_map_activation_creation_availability_v0.png`, l’état sans map active affiche :

- navigation Narrative Studio ;
- métriques skeleton ;
- panneau d’activation de map ;
- zone centrale vide en attente ;
- aucune fausse map active ;
- création indisponible tant que l’activation n’est pas résolue.

### Actions actuellement disponibles

Les lots NS-EVENT-09 à NS-EVENT-16 ont livré :

- création de brouillon avec position explicite ;
- reset de la position après création ;
- sélection automatique du brouillon créé ;
- activation de map depuis le workspace ;
- renommage du titre humain sans modifier l’ID technique ;
- édition du type de déclencheur : PNJ, objet, zone ;
- édition de l’action principale Scene ;
- édition du comportement : une seule fois / réutilisable ;
- conditions Fact vrai / Fact faux ;
- conditions événement déjà consommé / pas encore consommé ;
- préservation des conditions legacy avancées ;
- feedback utilisateur ;
- diagnostics et statuts.

### Ce qui est bon

- Les capacités MVP sont réelles et testées.
- L’utilisateur reste dans une logique no-code : labels humains, boutons guidés, messages explicites.
- Le modèle d’édition est borné : pas de JSON libre, pas de script libre.
- La séparation entre map active, création et sélection est saine.
- Les conditions legacy avancées ne sont pas écrasées silencieusement.

### Ce qui est acceptable temporairement

- La grille V0 comme outil de création.
- Le grand panneau `Builder d’événement` qui combine builder et détails.
- L’absence de bibliothèque d’éléments tant que les opérations sont encore peu nombreuses.
- L’absence d’inspecteur droit séparé tant que le nombre de champs éditables reste borné.

### Ce qui doit être déplacé

- La grille de position doit quitter le rôle de bloc visuel dominant.
- La création d’événement doit devenir un panneau compact, repliable ou contextuel.
- Les informations techniques doivent rester secondaires.
- Les contrôles d’édition fins doivent migrer vers un inspecteur droit quand le builder central devient plus visuel.

### Ce qui doit disparaître ou être masqué par défaut

- La grille visible en permanence quand un événement est sélectionné.
- Les contrôles de création qui prennent plus de place que les blocs d’un event existant.
- Les détails techniques trop proches du flux principal.

### Ce qui doit être repensé

- La distinction entre builder central et inspecteur.
- La place de la future bibliothèque d’éléments.
- La représentation des blocs `Résultats`, `Réactions` et `Changements du monde`.
- La validation globale visible dans l’écran Event Builder.

## 3. Analyse de l’écart avec l’image cible

| Zone cible | Présent aujourd’hui ? | Écart | Décision recommandée |
|---|---:|---|---|
| Sidebar globale PokeMap | Partiel | La sidebar Narrative Studio existe dans l’app, mais l’image cible montre une sidebar produit plus large avec projet, project health et navigation globale. | Hors scope immédiat Event Builder. Ne pas bloquer NS-EVENT-18. |
| Navigation Narrative Studio | Oui | L’entrée Événements est active. | Conserver. |
| Liste événements | Oui | Elle n’est pas encore groupée par map/zone comme la cible. | Améliorer après compactage création. |
| Recherche événements | Non visible dans V16 | L’image cible prévoit une recherche dans la liste. | V1 souhaitable, pas MVP immédiat. |
| Statuts Actif/Brouillon/Inactif | Partiel | Actif/Brouillon existent, mais pas encore une liste riche groupée comme la cible. | À polir dans un lot liste, après layout central. |
| Bibliothèque d’éléments | Non | Aucune colonne dédiée `Déclencheurs`, `Conditions`, `Actions`, `Résultats`, `Réactions`, `Monde`. | Créer en read-only avant add-by-click. |
| Builder central | Partiel | Le panneau `Builder d’événement` existe, mais il est une fiche détaillée, pas un canvas vertical de blocs. | Installer un layout central en blocs avant l’inspecteur droit. |
| Bloc Déclencheur | Oui | Présent et éditable, mais dans une section détail. | Migrer vers bloc central + édition fine dans inspecteur. |
| Bloc Conditions | Oui | Présent et éditable pour Fact/Event consumed. | Migrer vers bloc central ; ajouter bibliothèque plus tard. |
| Bloc Actions | Partiel | `Action principale` Scene existe ; pas encore action list multi-actions. | Garder une action principale MVP, ne pas ouvrir multi-actions trop tôt. |
| Bloc Résultats | Non | Pas de victory/defeat/failure dans Event Builder. | Repousser tant que battle/outcome contract n’est pas cadré. |
| Bloc Réactions | Non | Aucune réaction par outcome. | V1/V1.5, après outcomes. |
| Bloc Monde | Partiel | `Changements du monde` existe comme section, mais reste surtout un état/placeholder de conséquences. | Garder comme placeholder visuel, brancher plus tard avec facts/world rules/story steps. |
| Fin de l’événement | Non | Pas de bloc terminal visuel. | Ajouter comme bloc symbolique dans le builder central, sans runtime nouveau. |
| Inspecteur droit | Non | Le panneau actuel mélange builder et inspecteur. | Créer un split droit seulement après stabilisation du builder central. |
| Boutons Aperçu / Valider | Partiel | Diagnostics existent ; pas encore boutons visuels équivalents à la cible. | Ajouter dans le polish MVP UX, sans runtime preview lourd. |
| Création nouvel événement | Oui | Fonctionnelle, mais trop visible. | Rendre compacte/repliable en NS-EVENT-18. |
| Position picker | Oui | Grille V0 visible ; elle structure encore trop la page. | Secondariser dans un panneau création. |
| Validation | Partiel | Diagnostics par event ; pas encore Validator global branché. | Garder diagnostic local, prévoir Validator plus tard. |
| Preview | Non | Pas d’aperçu Event runtime. | Hors prochaine séquence UI ; ne pas mélanger avec layout. |

## 4. Décision sur la grille de position

### Décision

La grille reste un **outil V0 temporaire de création**, mais elle doit devenir secondaire.

Elle doit vivre dans :

```text
Colonne gauche
→ Liste d’événements
→ Créer un événement
→ panneau compact / accordéon
→ grille seulement si création ouverte
```

Elle ne doit pas vivre dans le builder central, car le builder central doit représenter la logique de l’événement sélectionné. Elle ne doit pas vivre dans l’inspecteur droit, car l’inspecteur droit doit éditer l’événement sélectionné, pas créer un nouvel event.

### Visibilité recommandée

| Situation | Visibilité de la grille |
|---|---|
| Aucun event sélectionné | Panneau création ouvert par défaut acceptable. |
| Event sélectionné | Panneau création replié par défaut. |
| Utilisateur clique `Nouvel événement` | Panneau création ouvert, grille visible. |
| Position choisie | Résumé compact `Position sélectionnée : x/y, couche`. |
| Draft créé | Panneau replié ou reset compact, event sélectionné. |
| Pas de map active | Pas de grille ; afficher activation de map. |

### Remplacement futur

À terme, la grille peut être remplacée par un clic direct sur la map ou un overlay de placement. Ce remplacement ne doit pas être fait maintenant. Il dépend d’une vraie décision UX sur l’espace map dans l’Event Builder.

### Règle à conserver

```text
Créer un événement → choisir une position → créer un brouillon
```

La grille ne doit pas devenir :

```text
le builder principal
le flux de composition des conditions/actions
le centre visuel permanent de l’écran
```

## 5. Architecture UI cible intermédiaire

### V0.5 recommandé

Objectif : conserver les fonctionnalités existantes, mais rapprocher la structure de la cible sans créer de nouvelle capacité métier.

```text
Écran Événements
├─ Colonne gauche
│  ├─ Liste d’événements
│  ├─ Recherche simple plus tard
│  └─ Créer un événement compact / repliable
│     └─ Grille de position V0 si ouvert
├─ Colonne centrale
│  ├─ Builder en blocs
│  ├─ Déclencheur
│  ├─ Conditions
│  ├─ Action principale
│  ├─ Comportement
│  ├─ Changements du monde
│  ├─ Diagnostics
│  └─ Informations techniques repliées
└─ Colonne droite
   └─ Différée
```

Dans cette étape, la troisième colonne n’est pas nécessaire. Il vaut mieux d’abord stabiliser la colonne centrale pour ne pas déplacer deux fois les mêmes contrôles.

### V0.75 recommandé

Objectif : introduire la structure cible sans drag/drop.

```text
Écran Événements
├─ Colonne gauche
│  ├─ Liste événements groupée
│  └─ Création compacte
├─ Colonne bibliothèque
│  ├─ Déclencheurs
│  ├─ Conditions
│  ├─ Actions
│  ├─ Résultats
│  ├─ Réactions
│  └─ Monde
├─ Colonne centrale
│  └─ Builder vertical en blocs
└─ Colonne droite
   └─ Inspecteur de l’élément ou de l’événement sélectionné
```

La bibliothèque doit d’abord être read-only. L’ajout par clic doit arriver avant tout drag/drop.

### V1 proche cible

Objectif : ressembler à l’image tout en restant réaliste.

```text
Liste événements groupée
Bibliothèque d’éléments utilisable par clic
Builder central vertical
Inspecteur droit structuré
Validation locale visible
Création compacte
Grille secondaire
Pas de drag/drop obligatoire
```

## 6. Plan de migration lot par lot

### NS-EVENT-18 — Creation Panel Compact / Collapsible V0

Type : UI layout / polish borné.

Objectif : rendre la création d’événement secondaire et libérer l’espace du builder.

Scope :

- transformer `Créer un événement` en panneau compact ;
- replier la grille quand un événement est sélectionné ;
- afficher un résumé de position sélectionnée ;
- conserver le flux NS-EVENT-09 ;
- conserver l’activation map NS-EVENT-16.

Non-objectifs :

- pas de nouveau modèle ;
- pas de clic direct sur map ;
- pas de refonte builder central ;
- pas de bibliothèque d’éléments ;
- pas de drag/drop.

Fichiers probables :

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`
- rapport et screenshot NS-EVENT-18.

Tests :

- création reste possible ;
- grille visible seulement quand le panneau création est ouvert ;
- event sélectionné replie la création par défaut ;
- position reset après draft ;
- activation map inchangée.

Visual Gate :

- montrer event sélectionné, création repliée, builder plus lisible ;
- montrer création ouverte dans un test/capture complémentaire si possible.

Critères d’acceptation :

- aucune fonctionnalité NS-EVENT-09 à NS-EVENT-16 ne régresse ;
- la grille n’est plus le bloc le plus dominant quand un event est sélectionné.

Risques :

- états widget autour du repli ;
- tests existants qui supposent la grille visible.

Complexité : M.

### NS-EVENT-19 — Event Builder Central Blocks Layout V0

Type : UI layout.

Objectif : transformer le panneau `Builder d’événement` en vraie colonne centrale de blocs.

Scope :

- créer une hiérarchie visuelle de blocs : Déclencheur, Conditions, Action principale, Comportement, Changements du monde, Diagnostics ;
- garder les contrôles existants ;
- clarifier le flux `Quand / Si / Alors / Puis` ;
- conserver le read model existant.

Non-objectifs :

- pas d’inspecteur droit ;
- pas de bibliothèque ;
- pas de nouveaux types de conditions/actions ;
- pas de outcomes/réactions.

Fichiers probables :

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`

Tests :

- blocs visibles dans l’ordre ;
- édition déclencheur, conditions, scène, behavior toujours verte ;
- legacy condition lock toujours visible ;
- aucun contrôle hors scope.

Visual Gate :

- event sélectionné avec blocs centraux lisibles.

Critères d’acceptation :

- l’écran commence à ressembler à un builder plutôt qu’à une fiche détail.

Risques :

- gonfler `event_builder_workspace.dart` si aucun sous-widget dédié n’est créé.

Complexité : M.

### NS-EVENT-20 — Event Inspector Split V0

Type : UI layout / séparation des responsabilités.

Objectif : introduire un inspecteur droit minimal sans changer les opérations métier.

Scope :

- créer une zone droite `Inspecteur d’événement` ;
- déplacer les informations fines et techniques vers cette zone ;
- garder les blocs centraux comme résumé/action rapide ;
- préserver les éditions existantes.

Non-objectifs :

- pas de multi-sélection ;
- pas d’inspecteur par sous-bloc ;
- pas de nouveau champ métier.

Fichiers probables :

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- éventuellement nouveau widget local si le fichier devient trop dense.
- `packages/map_editor/test/event_builder_workspace_test.dart`

Tests :

- inspecteur affiche titre, ID secondaire, statut, comportement ;
- les blocs centraux restent visibles ;
- aucune perte d’édition.

Visual Gate :

- trois zones lisibles : liste, builder, inspecteur.

Critères d’acceptation :

- les détails techniques ne polluent plus le flux central.

Risques :

- largeur desktop ;
- responsive à définir.

Complexité : L.

### NS-EVENT-21 — Element Library Read-only V0

Type : UI read-only.

Objectif : afficher une bibliothèque d’éléments proche de la cible, sans ajout réel depuis la bibliothèque.

Scope :

- ajouter une colonne ou panneau `Bibliothèque d’éléments` ;
- groupes : Déclencheurs, Conditions, Actions, Résultats, Réactions, Monde ;
- indiquer ce qui est disponible maintenant et ce qui est à venir ;
- labels no-code.

Non-objectifs :

- pas d’ajout par clic ;
- pas de drag/drop ;
- pas de nouveaux contrats métier.

Fichiers probables :

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`

Tests :

- bibliothèque visible ;
- groupes visibles ;
- éléments non supportés indiqués comme indisponibles ;
- aucun clic ne modifie l’event.

Visual Gate :

- liste + bibliothèque + builder central visibles.

Critères d’acceptation :

- l’utilisateur comprend quels blocs existent et lesquels restent à venir.

Risques :

- trop de promesses UI si les éléments indisponibles ne sont pas clairement marqués.

Complexité : M.

### NS-EVENT-22 — Add-by-click From Library V0

Type : UI authoring borné.

Objectif : permettre d’utiliser la bibliothèque par clic pour les capacités déjà livrées.

Scope :

- clic `Fact vrai/faux` ouvre/active l’ajout existant ;
- clic `Événement consommé/pas consommé` ouvre/active l’ajout existant ;
- clic `Jouer une scène` focalise la section action principale ;
- clic `Réutilisation` focalise comportement ou affiche le choix ;
- pas de nouvelles capacités métier.

Non-objectifs :

- pas de drag/drop ;
- pas d’outcomes ;
- pas de réactions riches ;
- pas de battle authoring.

Fichiers probables :

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`

Tests :

- clic bibliothèque ajoute ou prépare une condition supportée ;
- éléments indisponibles ne modifient rien ;
- feedback clair.

Visual Gate :

- bibliothèque avec éléments disponibles et indisponibles.

Critères d’acceptation :

- la bibliothèque devient utile sans ouvrir un moteur de blocs complet.

Risques :

- ambiguïté entre clic direct et sélection d’un bloc.

Complexité : M/L.

### NS-EVENT-23 — Actions / Conditions Block Polish V0

Type : UI polish / consolidation.

Objectif : rendre les blocs Conditions et Actions lisibles comme dans la cible.

Scope :

- présentation plus compacte des conditions supportées ;
- séparations visuelles Fact vs Event consumed ;
- action principale Scene affichée comme bloc action ;
- messages empty plus courts ;
- suppression des doublons de wording.

Non-objectifs :

- pas de nouvelle action ;
- pas de multi-actions ;
- pas de outcome ;
- pas de drag/drop.

Fichiers probables :

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`

Tests :

- conditions fact/event affichées humainement ;
- retrait toujours possible ;
- action scene préservée ;
- empty states lisibles.

Visual Gate :

- event avec conditions et scène, proche du flow cible.

Critères d’acceptation :

- le flux `Si / Alors` est compréhensible sans lire les détails techniques.

Risques :

- sur-polish avant inspecteur droit.

Complexité : M.

### NS-EVENT-24 — MVP UX Closure Visual Gate

Type : gate UI / audit / regressions.

Objectif : fermer la V0.75 Event Builder avant d’ouvrir outcomes/réactions/drag-drop.

Scope :

- audit visuel ;
- tests régressions Event Builder ;
- Visual Gate finale MVP agréable ;
- rapport de fermeture UI MVP.

Non-objectifs :

- pas de feature ;
- pas de nouveaux modèles ;
- pas de runtime.

Fichiers probables :

- rapport NS-EVENT-24 ;
- screenshot NS-EVENT-24 ;
- tests si ajustements minimes nécessaires.

Tests :

- suite `event_builder_workspace_test.dart` ;
- suite notifier Event Builder si touchée par lots précédents ;
- analyse ciblée.

Visual Gate :

- écran complet avec liste, création compacte, bibliothèque si déjà livrée, builder central lisible.

Critères d’acceptation :

- MVP agréable validé ;
- prochains lots outcomes/réactions séparés ;
- pas de drag/drop démarré.

Risques :

- découvrir une dette responsive.

Complexité : S/M.

## 7. Fonctionnalités à ne pas ouvrir maintenant

| Fonctionnalité | Décision | Raison |
|---|---|---|
| Drag/drop | Repousser | Trop risqué avant stabilité layout + add-by-click. |
| Outcomes complets | Repousser | Dépend de battle/dialogue/scene outcome contract. |
| Réactions riches | Repousser | Dépend des outcomes et conséquences persistantes. |
| Battle actions | Repousser | Frontière battle/runtime à cadrer. |
| Récompenses objet/argent | Repousser | Requiert contrats gameplay/inventaire/récompenses. |
| World rules inline | Repousser | Risque de mélanger Event Builder et World Rules workspace. |
| Preview runtime complète | Repousser | Ce serait un autre chantier runtime/simulation. |
| Édition géométrie zone | Repousser | Le lot actuel n’édite que type de déclencheur, pas forme/zone. |
| Multi-map event graph | Repousser | Trop large pour MVP UI. |
| Conditions avancées | Repousser | Les conditions legacy avancées sont volontairement verrouillées. |
| Story Step conditions | Différer | Utile, mais moins prioritaire que layout et lisibilité. |

## 8. Recommandation du prochain lot

### Choix

Je recommande l’option A :

```text
NS-EVENT-18 — Creation Panel Compact / Collapsible V0
```

### Pourquoi maintenant

Le prochain problème n’est pas l’absence d’un autre bouton. Le problème est que l’écran donne encore trop de poids à la création/position alors que l’utilisateur doit surtout lire et composer un événement.

Compacter la création en premier permet :

- de libérer la lecture du builder ;
- de préserver la grille V0 sans la promouvoir ;
- de réduire le bruit avant d’ajouter bibliothèque et inspecteur ;
- de limiter le risque fonctionnel, car le flux de création est déjà bien cadré.

### Ce que NS-EVENT-18 ne doit surtout pas faire

- ne pas créer de bibliothèque ;
- ne pas créer de drag/drop ;
- ne pas changer les contrats map_core ;
- ne pas ajouter outcomes/réactions ;
- ne pas modifier la logique de création ;
- ne pas supprimer la grille.

## 9. Estimation mise à jour

| Objectif | Lots restants estimés | Commentaire |
|---|---:|---|
| MVP agréable | 3 à 4 | NS-EVENT-18 à NS-EVENT-20 ou NS-EVENT-21 selon appétit UI. |
| V1 proche image cible sans drag/drop | 7 à 9 | Liste, création compacte, builder central, inspecteur, bibliothèque read-only, add-by-click, polish/gate. |
| V1 proche image cible avec drag/drop | 11 à 15 | Ajouter 4 à 6 lots après add-by-click : drag model, hover/drop states, tests widget, accessibility, visual gates. |
| V1.5 avec outcomes/réactions riches | 15 à 22 | Dépend des contrats battle/dialogue/consequence, donc non recommandé comme suite immédiate. |

Répartition probable :

| Catégorie | Lots estimés |
|---|---:|
| Layout / UX structure | 3 à 4 |
| Bibliothèque / add-by-click | 2 |
| Inspector split | 1 à 2 |
| Tests / Visual Gates / closure | 1 à 2 |
| Drag/drop si demandé | 4 à 6 |

## 10. Evidence Pack

### Gate 0

Commande :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 20
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
```

`git status --short --untracked-files=all` :

```text
<vide>
```

`git diff --stat` :

```text
<vide>
```

`git diff --name-only` :

```text
<vide>
```

`git log --oneline -n 20` :

```text
54c59fba ns_event_16: Consolidation de la disposition des blocs et disponibilité de la création d'activation de carte
8b3866a8 ns_event_15: Ajout de l'auteur des types de déclencheurs pour les événements
8a5996be ns_event_14: Ajout des conditions de consommation d'événements
7f490b9e ns_event_13: Ajout de l'auteur des conditions de fait pour les événements
26bec474 ns_event_12: Ajout de l'auteur des comportements pour les événements
00698aea ns_event_11: Ajout de l'auteur des actions de scène pour les brouillons d'événements
fc0e0be0 ns_event_10: Ajout de la saisie du titre pour les brouillons d'événements
cdedbe6e ns_event_09: Fermeture du flux de création de brouillon
d3f1866f ns_event_08: Ajout du sélecteur de position explicite sur la carte pour la création de brouillon
30ae9429 ns_event_07: Ajout de l'entrée UI explicite pour la création de brouillon avec position
3bd06d2b ns_event_06: Ajout des opérations de création de brouillon pour l'éditeur d'événements
6fe430d9 ns_event_05: Polissage des détails en lecture seule et diagnostics
1a551f41 ns_event_04: Ajout de l'espace de travail pour l'éditeur d'événements en lecture seule
7eed36b2 FG-NS-EVENT-003: Ajout du read model et diagnostics pour le builder d'événements
93b655dd FG-NS-EVENT-002-BIS: Préservation des conditions legacy et corrections dans le builder d'événements
6279df74 Remove legacy Narrative Studio steps entry
f54a8243 FG-NS-EVENT-002: Ajout des contrats et opérations pour le builder d'événements (core + tests)
410be446 FG-NS-EVENT-001: Alignement des contrats existants pour le builder d'événements
7b3b2151 FG-NS-EVENT-001: Ajout du plan MVP v1 pour le builder d'événements Narrative Studio
05e70a57 NS-STUDIO-PRODUCT-BETA-READINESS — Audit de préparation pour la bêta de Narrative Studio
```

### Règles lues

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `product-design:image-to-code` consulté comme référence visuelle mentionnée par le prompt ; non appliqué comme workflow de build car NS-EVENT-17 interdit explicitement toute implémentation.
- `superpowers:writing-plans` consulté pour structurer le plan, avec adaptation au chemin demandé par le prompt au lieu de `docs/superpowers/plans`.
- `superpowers:verification-before-completion` consulté pour la vérification finale.

### Rapports lus

- `reports/narrativeStudio/events/ns_event_16_block_layout_consolidation_v0.md`
- `reports/narrativeStudio/events/ns_event_16_map_activation_creation_availability_v0.md`
- `reports/narrativeStudio/events/ns_event_15_trigger_type_authoring_v0.md`
- `reports/narrativeStudio/events/ns_event_14_event_consumed_conditions_authoring_v0.md`
- `reports/narrativeStudio/events/ns_event_13_fact_conditions_authoring_v0.md`

### Code lu

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`

### Indices code relevés

Commande :

```bash
rg -n "class EventBuilderWorkspace|class _EventCreationColumn|class _DraftPositionPickerPanel|class _EventListPanel|class _EventDetailsPanel|Builder d’événement|Liste d’événements|Créer un événement|Déclencheur|Conditions|Action principale|Comportement|Changements du monde" packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
```

Sortie utile :

```text
86:class EventBuilderWorkspace extends StatefulWidget {
696:class _EventCreationColumn extends StatelessWidget {
715:class _DraftPositionPickerPanel extends StatelessWidget {
753:                  'Créer un événement',
924:class _EventListPanel extends StatelessWidget {
945:            'Liste d’événements',
1085:class _EventDetailsPanel extends StatefulWidget {
1201:              'Builder d’événement',
1244:              title: 'Déclencheur',
1251:              title: 'Conditions',
1261:              title: 'Action principale',
1268:              title: 'Comportement',
1275:              title: 'Changements du monde',
2775:    'trigger' => 'Déclencheur',
2776:    'conditions' => 'Conditions',
2777:    'actions' => 'Action principale',
2778:    'behavior' => 'Comportement',
2779:    'world' => 'Changements du monde',
```

Commande :

```bash
rg -n "EventBuilderWorkspace|onRenameEvent|onUpdateEventTriggerType|onUpdateEventSceneAction|onUpdateEventReusePolicy|onAddEventFactCondition|onAddEventConsumedCondition|mapOptions|draftCreationGate" packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
```

Sortie utile :

```text
552:      EditorWorkspaceMode.events => EventBuilderWorkspace(
553:          readModel: _buildEventBuilderWorkspaceReadModel(editor),
554:          draftCreationGate: _buildEventBuilderDraftCreationGate(
562:          mapOptions: _buildEventBuilderMapOptions(editor.project),
571:          onRenameEventTitle: editorNotifier.renameEventBuilderEventTitle,
578:          onAddEventConsumedCondition:
656:EventBuilderReadModel _buildEventBuilderWorkspaceReadModel(
```

### Screenshots consultés

Commande :

```bash
file reports/narrativeStudio/events/screenshots/ns_event_16_block_layout_consolidation_v0.png reports/narrativeStudio/events/screenshots/ns_event_16_map_activation_creation_availability_v0.png /Users/karim/Desktop/assets/pokeMap/définitive/4\ -\ événements/1\ -\ événements.png
```

Sortie :

```text
reports/narrativeStudio/events/screenshots/ns_event_16_block_layout_consolidation_v0.png:           PNG image data, 1440 x 1100, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/events/screenshots/ns_event_16_map_activation_creation_availability_v0.png: PNG image data, 1440 x 1100, 8-bit/color RGBA, non-interlaced
/Users/karim/Desktop/assets/pokeMap/définitive/4 - événements/1 - événements.png:                   PNG image data, 1672 x 941, 8-bit/color RGB, non-interlaced
```

### Tests

Aucun test exécuté car aucun code applicatif n’a été modifié.

### Fichiers créés

- `reports/narrativeStudio/events/ns_event_17_target_layout_alignment_plan.md`

### Fichiers modifiés

- Aucun fichier applicatif.
- Aucun test.
- Aucune roadmap.
- Aucun screenshot.

### Limites de l’audit

- L’audit est basé sur les rapports, le code, les Visual Gates existantes et l’image cible.
- Aucune session interactive Flutter n’a été lancée.
- Le rapport ne vérifie pas les contraintes responsive en exécution réelle.
- Le rapport ne tranche pas encore les contrats outcomes/réactions/battle.

### Gate final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
?? reports/narrativeStudio/events/ns_event_17_target_layout_alignment_plan.md
```

Commande :

```bash
git diff --stat
```

Sortie :

```text
<vide>
```

Commande :

```bash
git diff --name-only
```

Sortie :

```text
<vide>
```

Commande :

```bash
git diff --check
```

Sortie :

```text
<vide>
```

## 11. Auto-review critique

### Vérification du périmètre

- Aucun code applicatif n’est prévu dans ce lot.
- Le rapport ne propose pas de drag/drop avant stabilisation du layout.
- La grille de position est conservée, mais déplacée dans un rôle secondaire.
- La prochaine étape est un lot UI borné, pas un lot de modèle ou runtime.

### Risques résiduels

- `EventBuilderWorkspace` peut devenir trop gros si les prochains lots n’extraient pas de sous-widgets.
- L’inspecteur droit risque de provoquer une refonte plus large si NS-EVENT-19 ne clarifie pas d’abord les blocs centraux.
- La bibliothèque read-only peut donner une impression de fonctionnalité indisponible si les états “à venir” ne sont pas clairement marqués.
- Le drag/drop doit rester repoussé ; le démarrer trop tôt ferait exploser les tests widget et les états de focus.

### Critique du prompt

Le prompt est bien ciblé : il interdit l’implémentation et force une trajectoire avant de continuer à ajouter des boutons. La seule ambiguïté est la présence du tag `product-design:image-to-code`, qui correspond normalement à un workflow de reproduction UI en code. Ici, il doit être traité comme signal de référence visuelle, pas comme permission d’implémenter, car le texte principal interdit explicitement toute modification de widget ou layout.

Le prompt pourrait demander explicitement si la V1 proche cible doit conserver le workspace Narrative Studio actuel ou migrer vers une page Event Builder plus indépendante. Pour l’instant, la recommandation garde l’intégration actuelle et fait évoluer l’écran progressivement.

## 12. Décision finale NS-EVENT-17

```text
NS-EVENT-17 — DONE comme plan de cadrage UI.
```

Décision clé :

```text
La grille de position reste un outil V0 temporaire, compact et repliable.
Elle ne doit pas structurer le builder.
Le prochain lot recommandé est NS-EVENT-18 — Creation Panel Compact / Collapsible V0.
```
