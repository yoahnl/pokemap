# Dynamic Shop State Builder — Design Specification

**Date:** 2026-07-23
**Status:** direction approuvée ; contrat `FG-074` implémenté, lots `FG-075` à `FG-079` à réaliser
**Roadmap proposée:** `FG-074` à `FG-079`
**Surface:** PokeMap desktop editor, Narrative Studio, runtime Selbrume

## 1. Résumé

PokeMap sait déjà :

- stocker des boutiques statiques dans `ProjectManifest.shops` ;
- créer une boutique sans saisir d’identifiant technique ;
- choisir des objets depuis le catalogue ;
- authorer un prix et un stock facultatif ;
- ouvrir une boutique depuis une commande Scene `openShop(shopId)` ;
- acheter une quantité, débiter l’argent, créditer le sac et persister le stock.

La limitation actuelle est structurelle : `ShopDefinition` ne porte qu’un
catalogue statique. Une boutique ne peut pas changer automatiquement selon
l’état du jeu.

La cible approuvée transforme une boutique en service stable possédant :

1. un état par défaut rétrocompatible ;
2. zéro ou plusieurs états conditionnels complets ;
3. un résolveur déterministe choisissant un seul état actif ;
4. un éditeur no-code inspiré de l’Event Builder ;
5. une prévisualisation expliquant l’état retenu ;
6. des diagnostics empêchant les configurations ambiguës ou cassées.

## 2. Décisions utilisateur

Les décisions suivantes sont acquises :

- un bâtiment physique de boutique n’est pas requis pour le MVP ;
- une interaction ouvrant un menu d’achat fonctionnel est suffisante ;
- le créateur doit pouvoir configurer les objets vendus et leurs prix sans
  modifier de JSON ;
- toute la configuration actuellement utile d’une boutique doit pouvoir varier
  selon l’état du jeu ;
- l’interface doit reprendre le langage visuel et la densité de l’Event Builder ;
- le mockup produit le 2026-07-23 constitue la direction visuelle approuvée ;
- un profil complet est sélectionné à la fois, selon ses conditions et sa
  priorité.

## 3. Objectifs

### 3.1 Objectifs fonctionnels

Un créateur doit pouvoir :

- créer et renommer une boutique ;
- conserver un catalogue par défaut ;
- créer un état en dupliquant un état existant ou en partant vide ;
- modifier dans chaque état :
  - le nom affiché ;
  - l’ouverture ou la fermeture ;
  - le message d’accueil ;
  - le message de fermeture ;
  - le catalogue complet ;
  - le prix de chaque objet ;
  - le stock de chaque objet ;
- définir une expression d’activation sans identifiant libre ;
- ordonner les états par priorité ;
- simuler un contexte de jeu ;
- voir quel état gagne et pourquoi ;
- être averti avant le runtime lorsqu’une configuration est invalide.

Le joueur doit :

- ouvrir la même boutique physique avant et après une progression narrative ;
- voir le catalogue correspondant à son état courant ;
- ne jamais acheter un objet absent de l’état résolu ;
- payer le prix de l’état résolu ;
- conserver l’état du stock après sauvegarde et chargement ;
- recevoir un message lisible lorsqu’une boutique est fermée.

### 3.2 Objectifs techniques

- préserver les anciens JSON de boutiques ;
- préserver les anciennes sauvegardes de stock ;
- conserver les règles métier dans les packages Dart purs ;
- ne pas faire dépendre `map_core` ou `map_gameplay` de Flutter ;
- réutiliser le langage canonique `ScriptCondition` au lieu de créer un second
  moteur d’expressions propre aux boutiques ;
- garder `openShop(shopId)` stable ;
- utiliser exclusivement le design system PokeMap dans `map_editor`.

## 4. Non-objectifs V1

Cette tranche ne livre pas :

- un bâtiment ou un intérieur de boutique ;
- un système de revente au marchand ;
- plusieurs monnaies ;
- une variation horaire en temps réel ;
- un réapprovisionnement journalier fondé sur une horloge ;
- une tarification aléatoire ;
- un langage de script libre ;
- une modification des boutiques depuis le runtime.

L’architecture ne doit pas empêcher ces extensions, mais aucun contrôle inactif
ne doit les simuler dans l’UI V1.

## 5. Modèle de données

### 5.1 Compatibilité de `ShopDefinition`

Le contrat existant reste valide :

```dart
ShopDefinition(
  id: 'shop_port_supplies',
  label: 'Comptoir des Brisants',
  entries: [
    ShopEntryDefinition(itemId: 'potion', price: 300, stock: 99),
  ],
)
```

`entries` reste le catalogue de l’état par défaut. Un nouveau champ
`states` porte uniquement les états conditionnels :

```dart
ShopDefinition(
  id: 'shop_port_supplies',
  label: 'Comptoir des Brisants',
  entries: defaultEntries,
  states: conditionalStates,
)
```

Conséquences :

- un projet sans `states` garde exactement son comportement actuel ;
- aucune migration destructive n’est nécessaire ;
- l’éditeur présente `label` et `entries` comme la carte « État par défaut » ;
- les états conditionnels peuvent remplacer la totalité de la présentation et
  du catalogue.

### 5.2 `ShopStateDefinition`

Le nouveau contrat proposé est :

```dart
@freezed
class ShopStateDefinition with _$ShopStateDefinition {
  const factory ShopStateDefinition({
    required String id,
    required String label,
    @Default(0) int priority,
    required ScriptCondition activation,
    @Default(true) bool isOpen,
    String? storefrontLabel,
    @Default('') String welcomeMessage,
    @Default('') String closedMessage,
    @Default([]) List<ShopEntryDefinition> entries,
  }) = _ShopStateDefinition;
}
```

Sémantique :

- `id` est généré depuis le libellé et n’est jamais saisi à la main ;
- `label` est le nom auteur de l’état ;
- `priority` choisit le gagnant parmi les états actifs ;
- `activation` est une expression `ScriptCondition` ;
- `isOpen == false` interdit l’achat et expose `closedMessage` ;
- `storefrontLabel` remplace le nom visible de la boutique ;
- `entries` remplace complètement le catalogue par défaut.

Une liste complète évite les règles de patch implicites. Pour faire évoluer un
catalogue cumulativement, l’auteur duplique l’état précédent puis ajoute ou
retire les produits voulus.

### 5.3 Résultat résolu

Le runtime ne doit pas transmettre un `ShopStateDefinition` brut à l’UI. Le
package `map_gameplay` expose une valeur résolue :

```dart
final class ResolvedShopState {
  const ResolvedShopState({
    required this.shopId,
    required this.stateId,
    required this.authoringLabel,
    required this.storefrontLabel,
    required this.priority,
    required this.isDefault,
    required this.isOpen,
    required this.message,
    required this.entries,
    required this.matchedStateIds,
  });
}
```

`ResolvedShopState` est immuable, normalisé et indépendant de Flutter.

### 5.4 Stock

Le stock d’un état conditionnel utilise la clé :

```text
shopId::stateId::itemId
```

L’état par défaut conserve la clé historique :

```text
shopId::itemId
```

Ainsi :

- les anciennes sauvegardes restent compatibles ;
- revenir vers un ancien état retrouve son stock déjà consommé ;
- débloquer un nouvel état ne détruit pas les compteurs précédents ;
- deux états peuvent déclarer des stocks différents pour le même objet.

## 6. Conditions d’activation

### 6.1 Langage canonique

Les états de boutique utilisent `ScriptCondition`, avec :

- `allOf` ;
- `anyOf` ;
- `not`.

Les conditions déjà supportées restent disponibles :

- story flag présent ou absent ;
- variable égale, supérieure ou inférieure ;
- capacité de terrain débloquée ;
- move présent ou utilisable dans l’équipe ;
- événement consommé ;
- carte courante.

La première tranche ajoute les sources guidées nécessaires à la progression :

- Fact typé égal à une valeur ;
- Story Step terminée ou non terminée ;
- badge possédé ou non possédé ;
- quantité minimale d’un objet ;
- argent minimum.

Ces extensions appartiennent au langage commun, pas au modèle Shop. Une future
surface no-code peut donc les réutiliser.

Une condition `factEquals` transporte explicitement `factId`, `valueType` et
`value`. `valueType` reprend les wire names canoniques de
`NarrativeValueKind` (`bool`, `int`, `string`) : aucune inférence ambiguë n’est
faite depuis une chaîne.

Toutes les résolutions — runtime, mutation d’achat et simulateur — reçoivent le
même `ScriptEvaluationContext`, construit depuis les Facts du
`ProjectManifest`. Le `NarrativeFactRuntimeResolver` associé fournit donc aussi
la valeur initiale d’un Fact lorsqu’aucun override n’existe. Une condition Fact
sans resolver valide échoue fermée et produit un diagnostic auteur.

### 6.2 Algorithme de résolution

Pour une boutique et un `GameState` :

1. évaluer chaque état conditionnel ;
2. conserver les états dont l’expression est vraie ;
3. trier par priorité décroissante ;
4. à priorité égale, conserver l’ordre de déclaration pour garantir un résultat
   stable ;
5. choisir le premier état ;
6. utiliser l’état par défaut si aucun état conditionnel ne correspond.

Une égalité de priorité entre deux états simultanément satisfaisables reste
exécutable, mais constitue une erreur de validation auteur.

## 7. Runtime

La commande Scene reste :

```dart
SceneInteractiveCommand.openShop(shopId: 'shop_port_supplies')
```

Lors de l’ouverture :

1. retrouver `ShopDefinition` ;
2. construire le contexte d’évaluation depuis les Facts du projet ;
3. résoudre son état depuis le `GameState` courant avec ce contexte ;
4. si l’état est fermé, afficher son message et ne pas ouvrir le catalogue ;
5. sinon transmettre `ResolvedShopState` à l’overlay ;
6. lors de l’achat, revérifier l’état résolu avec le même contexte avant la
   mutation ;
7. refuser une requête devenue obsolète entre l’affichage et la validation ;
8. sauvegarder argent, sac et compteur de stock dans une seule transaction.

La réévaluation à l’achat empêche un écran ancien d’acheter un objet ou un prix
qui n’est plus valide après une mutation de progression.

## 8. UI no-code

### 8.1 Route

Une destination `Boutiques` est ajoutée au Narrative Studio. Elle ouvre un
workspace de premier plan, pas une boîte de dialogue.

Le fil d’Ariane est :

```text
Narrative Studio / Boutique Builder
```

### 8.2 Géométrie approuvée

Le workspace desktop comporte quatre zones :

| Zone | Responsabilité |
|---|---|
| Boutiques | recherche, sélection, création, suppression réparée |
| États | état par défaut, états conditionnels, duplication, priorité |
| Catalogue | résumé de résolution et édition des produits |
| Inspecteur | général, conditions, comportement et messages |

Le shell, les surfaces, boutons, badges, champs et empty states utilisent les
primitives PokeMap existantes. Aucune couleur n’est codée dans le feature.

### 8.3 Colonne Boutiques

- recherche par libellé ;
- compteur d’états et de produits ;
- statut valide ou diagnostic ;
- bouton `Nouvelle boutique` ;
- suppression avec réparation des commandes `openShop`.

### 8.4 Colonne États

- carte non supprimable `État par défaut` ;
- cartes des états conditionnels ;
- badge de priorité ;
- résumé humain de l’expression ;
- badge actif dans le contexte simulé ;
- menu Dupliquer / Renommer / Supprimer ;
- bouton `Nouvel état`.

La création propose :

- dupliquer l’état sélectionné ;
- partir du catalogue par défaut ;
- créer un état vide.

### 8.5 Catalogue central

Chaque ligne affiche :

- icône et libellé du catalogue d’objets ;
- prix ;
- stock ;
- statut comparatif `Nouveau`, `Modifié`, `Inchangé` ou `Retiré` ;
- actions Éditer et Retirer.

Les produits sont choisis par picker. Les champs prix et stock sont numériques,
avec validation immédiate.

### 8.6 Inspecteur

Sections :

- Général : nom auteur, priorité, boutique ouverte, nom visible ;
- Conditions d’activation : expression visuelle AND/OR/NOT ;
- Messages : accueil ou fermeture ;
- Diagnostics : références manquantes, ambiguïtés et état simulé.

Les Facts, Steps, badges et objets sont choisis depuis le projet. Aucun champ
d’identifiant libre n’est offert dans le parcours normal.

### 8.7 Prévisualisation

Le bandeau inférieur montre :

- le contexte simulé ;
- l’état retenu ;
- sa priorité ;
- les conditions vraies et fausses ;
- les états concurrents ignorés.

Le bouton `Modifier le contexte` réutilise les données du simulateur d’état du
monde lorsque possible. Le simulateur ne modifie jamais le projet ni une save.

### 8.8 Responsive

- à partir de 1440 px : quatre zones visibles ;
- entre 1100 et 1439 px : inspecteur dans un side sheet ;
- sous 1100 px : listes Boutiques/États dans un panneau repliable ;
- aucune largeur ne doit produire d’overflow Flutter.

## 9. Validation

La validation est volontairement séparée :

- `map_core` vérifie la structure, les références projet et les expressions
  identiques sans connaître le moteur de résolution ;
- `map_gameplay` évalue les contextes simulés avec `ShopStateResolver` et
  signale les conflits de priorité réellement actifs.

Le simulateur Editor agrège les deux sources. Aucune logique d’évaluation de
`GameState` n’est dupliquée dans `map_core`. Les IDs d’objets connus sont
fournis explicitement au validateur après chargement du catalogue référencé par
`ProjectManifest.pokemon`; le validateur Core ne lit jamais le système de
fichiers.

Diagnostics bloquants :

- identifiant d’état vide ou dupliqué ;
- libellé vide ;
- expression mal formée ;
- référence vers Fact, Step, badge, événement ou objet inconnue ;
- prix nul ou négatif ;
- stock négatif ;
- produit dupliqué dans un même état ;
- deux états de même priorité pouvant être vrais dans le même scénario simulé.

Avertissements :

- état fermé sans message ;
- état conditionnel identique à l’état par défaut ;
- état jamais sélectionné dans les contextes simulés connus ;
- catalogue ouvert mais vide ;
- nom visible vide après normalisation.

Le Validator doit indiquer la boutique, l’état et le champ concernés, puis
proposer une navigation directe vers le Shop Builder.

## 10. Migration

### 10.1 Projet

- `states` absent est interprété comme liste vide ;
- `entries` reste le catalogue par défaut ;
- les JSON existants round-trippent sans perte ;
- aucune réécriture globale n’est déclenchée à l’ouverture ;
- l’ajout du premier état écrit uniquement le nouveau champ `states`.

### 10.2 Sauvegarde

- les clés `shopId::itemId` restent celles de l’état par défaut ;
- les nouveaux états utilisent `shopId::stateId::itemId` ;
- aucun compteur historique n’est supprimé ;
- une sauvegarde chargée puis sauvegardée conserve les clés inconnues.

## 11. Intégration Selbrume

`shop_port_supplies` devient la preuve produit :

| État | Condition | Catalogue attendu |
|---|---|---|
| État par défaut | aucune | Potion et Poké Ball aux prix initiaux |
| Après Lysa | victoire/Step correspondante | Antidote ajouté, Potion moins chère |
| Phare en danger | progression du phare | boutique fermée avec message |
| Histoire terminée | épilogue atteint | catalogue final enrichi |

Le point physique `service_port_shop` et la commande
`openShop(shop_port_supplies)` ne changent pas.

## 12. Tests d’acceptation

La fonctionnalité est acceptée lorsque :

1. une boutique statique existante charge et achète comme avant ;
2. le default state gagne sans progression ;
3. un Fact ou Step sélectionne le profil Après Lysa ;
4. l’état fermé bloque l’achat avec un message ;
5. l’épilogue sélectionne le profil final ;
6. une variation de prix débite le montant exact ;
7. un objet non disponible est refusé côté mutation ;
8. le stock est indépendant et persistant par état ;
9. save/load conserve argent, sac et compteurs ;
10. l’éditeur permet de reconstruire les quatre états sans JSON ;
11. le simulateur et le runtime choisissent le même état ;
12. le Validator détecte une ambiguïté de priorité ;
13. le workspace respecte le mockup et le design system ;
14. le scénario Selbrume achète avant et après un changement d’état.

## 13. Lots proposés

| Lot | Intitulé | Résultat autonome |
|---|---|---|
| FG-074 | Shop State Model & Compatibility V0 | JSON et migrations rétrocompatibles |
| FG-075 | Shop State Resolver & Stock V0 | résolution pure et achats sûrs |
| FG-076 | Dynamic Shop Runtime V0 | overlay et commande Scene dynamiques |
| FG-077 | Dynamic Shop No-Code Builder V0 | workspace quatre zones authorable |
| FG-078 | Shop State Validator & Simulator V0 | diagnostics et preview explicable |
| FG-079 | Selbrume Dynamic Shop Golden Slice V0 | contenu réel, E2E et clôture |

Chaque lot doit posséder son propre commit et ses preuves ciblées. La roadmap
canonique ne passe aucun de ces lots à `DONE` avant exécution fraîche des tests,
analyses et vérifications prévues.
