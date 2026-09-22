# AS-MAP-002 — Clic droit et actions contextuelles de la page Carte

Livraison du menu contextuel de la carte du jeu dans Avelune Studio. Il ne
remplace aucun accès existant : l'inspecteur et les raccourcis gardent leurs
commandes, et le menu emprunte exactement les mêmes.

## Ouverture et cible

Le clic secondaire est intercepté avant toute autre branche du canvas
(`map_workspace_canvas.dart`) : il ne peut ni peindre, ni placer, ni effacer.
La cible est résolue depuis la cellule sous le pointeur, donc après panoramique,
zoom et redimensionnement, puisque la conversion passe par les coordonnées
locales du canvas transformé.

`mapContextTargetsAt` liste **toutes** les familles présentes à cet endroit, du
plus spécifique au moins : personnage, panneau ou point d'apparition, passage,
décor, zone de jeu, zone d'histoire. Une zone ne masque donc jamais le décor ou
le personnage qui s'y trouve. Quand il y en a plusieurs, le menu affiche la
liste « Éléments à cet endroit » et le choix synchronise la surbrillance, la
sélection qualifiée et l'inspecteur.

La cible est identifiée par carte, famille et identifiant — la même sélection
unifiée qu'AS-MAP-001. Aucun identifiant concurrent n'a été réintroduit.

## Actions par famille

| Cible | Actions |
| --- | --- |
| Décor | Propriétés, ouvrir et modifier sa ressource, déplacer, passer devant/derrière, supprimer |
| Personnage | Propriétés, écrire son interaction, déplacer, supprimer (protégé) |
| Panneau, point d'apparition | Propriétés, déplacer, supprimer (protégé) |
| Passage | Propriétés, déplacer, ouvrir la carte d'arrivée, supprimer |
| Zone de jeu | Propriétés, déplacer, supprimer |
| Zone d'histoire | Propriétés, déplacer, ouvrir son interaction, supprimer (protégé) |
| Case vide | Copier les coordonnées, effacer la tuile de cette case |

Une capacité que la famille ne supporte pas est absente ; une capacité
temporairement bloquée est présente, inerte, avec sa raison en infobulle. Aucune
rotation n'est proposée : le modèle de décor de Studio n'en porte pas, et
l'orientation d'un PNJ reste une propriété de son inspecteur, pas une rotation
géométrique.

L'effacement annonce son périmètre et le respecte : seul le calque visuel le
plus haut est touché, jamais une entité, une zone ou une pile de décors.

## Une seule implémentation des mutations

`MapContextCommandRunner` est le seul endroit où une commande devient une
mutation. Il relit la cible et sa disponibilité **au moment d'agir**, puis
délègue aux commandes déjà utilisées par l'inspecteur et le clavier
(`MapEditingCommands`, `CharacterEditingCommands`, `MapEntityEditingCommands`,
`WarpEditingCommands`, `GameplayZoneEditingCommands`,
`TriggerEditingCommands`). Le menu ne contient aucune mutation propre, et
l'historique est celui du document.

La navigation (ouvrir une ressource, une interaction, une carte d'arrivée) passe
par des rappels que l'écran fournit, en réutilisant ses retours contextualisés
existants.

## Cycle de vie

- ouvrir, fermer, Échap ou cliquer à l'extérieur ne crée aucune mutation ni
  entrée d'historique ;
- le voile de fermeture absorbe le clic : il ne traverse pas vers le canvas ;
- la requête est **figée à l'ouverture** : ce que l'auteur lit est ce que la
  commande revérifie ensuite ;
- une cible disparue depuis l'ouverture est refusée avec une explication ;
- une dépendance ajoutée pendant que le menu est ouvert bloque quand même ;
- changer d'espace ferme le menu, et un menu ouvert sur une autre carte n'est
  plus affiché.

## Rendu

Menu compact aligné sur les tokens Avelune (`surfaceContainerHigh`, bordure
`outlineVariant`, élévation discrète), libellés français, groupes courts, la
cible nommée en tête. Il reste dans la fenêtre près des bords, défile si la
fenêtre est petite, et se ferme au clavier avec Échap.

- `captures/asmap002-menu-contextuel.png` — cellule chargée : personnage, décor
  et zone de jeu superposés, l'inspecteur montrant la même cible.
- `captures/asmap002-menu-bord.png` — ouverture au coin bas-droit de la carte.

## Tests

| Nature | Fichier |
| --- | --- |
| widgets, vrais clics secondaires | `test/map_workspace/context_menu_test.dart` (9) |
| widgets, équivalence menu/inspecteur et garde tardive | `test/map_workspace/context_menu_parity_test.dart` (2) |
| commandes + sauvegarde disque | `test/map_workspace/context_menu_parity_test.dart` (1) |
| rendu et bords, captures | `test/map_workspace/context_menu_visual_test.dart` (2) |

Les clics sont de véritables `startGesture(buttons: kSecondaryButton)`, pas des
appels directs au constructeur du menu.

## Résultats

Mesurés sur l'état final, avec AS-MAP-001 : analyse sans remarque, 12 tests
d'architecture verts, 98 tests de placements, protections et menu verts, et
825 verts sur la suite Studio complète (2 ignorés, 1 échec de charge connu de
`desktop_workspace_layout_test`, vert isolément). Les journaux sont ceux du
rapport AS-MAP-001.

## Limites

- **aucune manipulation native macOS n'a été exécutée** : tout est mesuré par
  tests de widgets et écritures disque réelles. Les captures sont produites par
  le harnais de test, elles ne prouvent pas un clic droit natif ;
- « Déplacer » arme la cible et affiche sa consigne, puis réutilise le geste de
  glisser existant du canvas ; il n'ajoute pas d'aperçu fantôme dédié ;
- le menu ne propose pas encore de navigation fléchée entre les entrées : il est
  atteignable au clavier et se ferme par Échap, mais l'activation se fait au
  pointeur ;
- aucun accès clavier dédié n'ouvre le menu sur la sélection courante ;
- les rotations de décor de l'ancien éditeur ne sont pas reprises : le modèle
  utilisé par Studio ne les porte pas.
