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

Cette identité qualifiée va jusqu'à l'exécution. `MapContextCommandRunner`
relit la cible dans **sa** famille sur **sa** carte (`MapContextTarget.sameAs`,
clé `carte · famille · identifiant`) : deux familles peuvent porter le même
identifiant local sans que l'une agisse pour l'autre, et une cible venue d'une
autre carte est refusée, jamais substituée par l'homonyme local.

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

« Passer devant » et « Passer derrière » se calculent sur la cible du menu et
la cellule du clic, pas sur ce qu'un clic gauche antérieur avait sélectionné.
Choisir un autre élément de la pile recalcule les deux disponibilités, et le
décor qui bouge est celui que l'auteur a choisi.

« Déplacer » arme la cible choisie. Le geste suivant déplace celle-là, même si
un personnage ou un décor se trouve sous le pointeur : le geste court-circuite
sa résolution habituelle quand une cible est armée. Une zone de jeu ou une zone
d'histoire voyage par son rectangle entier — `MapArmedAreaMove` translate
l'aire, la borne à la carte, conserve sa taille et sa charge utile, et n'écrit
qu'une seule entrée d'historique. Échap désarme sans rien toucher.

« Ouvrir son interaction » sur une zone d'histoire ouvre le travail existant et
ne fabrique jamais d'identité narrative : le lien est cherché parmi les sessions
en cours, les brouillons d'Événements et les enregistrements sauvegardés. Sans
lien, la commande le dit et propose de tracer la zone depuis Histoire ; avec
plusieurs, elle ouvre Événements filtré plutôt que d'en choisir un au hasard.

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
- Maj+F10 et la touche Menu ouvrent le menu sur la sélection courante, à sa
  cellule, sans pointeur ;
- le menu prend le focus à l'ouverture et le **rend** à son propriétaire
  précédent à la fermeture ;
- chaque entrée est un contrôle activable au clavier : Tab la parcourt, Entrée
  l'exécute, une entrée bloquée reste inerte pour le clavier comme pour le
  pointeur ;
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
| identité qualifiée jusqu'à l'exécution, devant/derrière | `test/map_workspace/context_identity_test.dart` (4) |
| déplacement réel d'une zone et d'une zone d'histoire | `test/map_workspace/context_move_test.dart` (4) |
| focus, activation clavier, reciblage | `test/map_workspace/context_keyboard_test.dart` (4) |
| **véritable `MapWorkspaceScreen`**, avec ses propriétaires et ports | `test/map_workspace/context_menu_host_test.dart` (4) |

Les clics sont de véritables `startGesture(buttons: kSecondaryButton)`, pas des
appels directs au constructeur du menu.

Le fichier d'hôte monte l'écran réel sur un projet temporaire écrit sur disque :
suppression par le menu puis relecture du fichier, ouverture et fermeture sans
aucune écriture ni entrée d'historique, ouverture d'une interaction absente, et
« Propriétés » atteignant l'inspecteur compact dans une fenêtre étroite. La
position d'une cellule y est lue sur le rectangle rendu : la carte est ajustée à
l'espace disponible, donc la taille de tuile du projet ne suffit pas.

Ces tests ont été éprouvés par mutation : en neutralisant l'exécution des
commandes du menu, le parcours de suppression et celui de l'interaction absente
tombent, tandis que le parcours « n'écrit rien » reste vert, comme il se doit.

## Résultats

Mesurés sur l'état final, avec AS-MAP-001 :

| Vérification | Résultat |
| --- | --- |
| analyse Studio | aucune remarque |
| frontières d'architecture | 12 verts |
| placements, protections et menu | 124 verts |
| suite Studio complète | 845 verts, 2 ignorés, **aucun échec** |

Le garde des 300 lignes a d'abord échoué sur trois fichiers ; il passe après les
découpes décrites plus bas. La suite complète est intégralement verte en
3 min 25 : `desktop_workspace_layout_test`, seul échec de charge des passages
antérieurs, ne s'est pas reproduit.

Journaux : `logs/analyse.txt`, `logs/architecture.txt`, `logs/menu-cible.txt`,
`logs/suite-studio-finale.txt`.

## Découpes imposées par le plafond de 300 lignes

Trois fichiers dépassaient la limite d'architecture après cette intervention.
Aucune des découpes n'introduit d'abstraction gratuite :

- `MapArmedAreaMove` (`map_armed_area_move.dart`) sort du geste de la carte la
  seule responsabilité « déplacer une cible rectangulaire » : résoudre l'aire,
  la translater bornée, l'écrire. Le geste garde la résolution du pointeur ;
- `WorkspaceMapFooter` (`workspace_map_footer.dart`) sort de la mise en page le
  pied de carte (avis de bordures et diagnostics de ressources), qui n'avait
  aucun lien avec l'agencement ;
- les tests de garde se répartissent entre `draft_reference_guard_test.dart`
  (l'index) et `draft_deletion_guard_test.dart` (les refus de suppression), leur
  montage commun passant dans `test/support/draft_reference_fixture.dart`.

Dans le geste, six constructions identiques ont été repliées sur un seul
point de sortie local ; ce n'est pas une abstraction nouvelle, c'est une
duplication en moins.

## Limites

- **aucune manipulation native macOS n'a été exécutée** : tout est mesuré par
  tests de widgets et écritures disque réelles. Les captures sont produites par
  le harnais de test, elles ne prouvent pas un clic droit natif ;
- « Déplacer » arme la cible et affiche sa consigne, puis réutilise le geste de
  glisser existant du canvas ; pour une zone il affiche le rectangle déplacé,
  mais il n'ajoute pas d'aperçu fantôme pour les autres familles ;
- la navigation entre les entrées est celle de Flutter (Tab et Maj+Tab), pas une
  navigation fléchée dédiée ;
- les rotations de décor de l'ancien éditeur ne sont pas reprises : le modèle
  utilisé par Studio ne les porte pas.
