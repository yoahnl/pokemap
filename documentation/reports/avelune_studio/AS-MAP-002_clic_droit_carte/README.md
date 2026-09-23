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
un autre élément se trouve sous le pointeur. Un décor armé reprend le chemin
ordinaire du canvas : `MapEditingCommands.move`, son contrôle de bornes et son
aperçu, avec le décalage entre le point saisi et l'origine du décor. Une zone
de jeu ou une zone d'histoire voyage par son rectangle entier —
`MapArmedAreaMove` translate l'aire, la borne à la carte, conserve sa taille et
sa charge utile. Chaque déplacement n'écrit qu'une entrée d'historique.

La consigne est portée par la cible armée elle-même (`MapWorkspaceViewState.
armMove`) : elle disparaît avec elle après validation, Échap pendant l'aperçu,
changement d'outil, changement de carte ou disparition de la cible. Un
déplacement armé ne se réactive jamais au retour sur une carte.

« Ouvrir son interaction » sur une zone d'histoire ouvre le travail existant et
ne fabrique jamais d'identité narrative : le lien est cherché parmi les sessions
en cours, les brouillons d'Événements et les enregistrements sauvegardés, puis
ouvert par son vrai propriétaire — la session simplifiée, Événements, ou le
document enregistré. Depuis Carte comme depuis Histoire, l'ouverture porte son
origine et une seule requête de navigation. Sans lien, la commande le dit ; avec
plusieurs, un choix limité aux interactions réellement liées s'affiche.

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
- Maj+F10 et la touche Menu ouvrent le menu sur la cible sélectionnée, même
  si elle n'est pas la première de sa pile, à sa position actuelle, ancré près
  d'elle dans le viewport courant ; sans cible valide, un message l'explique et
  rien n'est modifié ;
- tant qu'un menu est ouvert, aucune commande clavier destructive n'agit
  derrière lui ;
- le menu prend le focus à l'ouverture et le **rend** à son propriétaire
  précédent à la fermeture ;
- chaque entrée est un contrôle activable au clavier : Tab la parcourt, Entrée
  l'exécute, une entrée bloquée reste inerte pour le clavier comme pour le
  pointeur ;
- une dépendance ajoutée pendant que le menu est ouvert bloque quand même ;
- changer d'espace ou de carte ferme réellement la requête : un ancien menu ne
  réapparaît pas au retour.

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
| déplacement réel d'une zone et d'une zone d'histoire | `test/map_workspace/context_move_test.dart` (3) |
| focus, activation clavier, reciblage | `test/map_workspace/context_keyboard_test.dart` (4) |
| **véritable `MapWorkspaceScreen`**, avec ses propriétaires et ports | `test/map_workspace/context_menu_host_test.dart` (4) |
| hôte réel : Supprimer et Retour arrière protégés, chaque famille | `test/map_workspace/keyboard_delete_host_test.dart` (6) |
| hôte réel : Déplacer un décor, Échap, outil, carte, disque | `test/map_workspace/decor_move_host_test.dart` (8) |
| hôte réel : rouvrir une interaction existante depuis Carte | `test/map_workspace/story_zone_reopen_host_test.dart` (5) |
| hôte réel : lignes qualifiées, Maj+F10, changement de carte | `test/map_workspace/context_identity_host_test.dart` (4) |

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

## Intervention — finaliser les parcours sans nouvelles régressions

Base de revue `498c06e0a` ; travail sur `main`, arbre propre au départ (`HEAD`
`d1d24bf00`, puis `1e10c83fb` après deux commits iOS d'une autre session, sans
recouvrement). Livré en `70519322e`, puis complété par les corrections issues de
la critique finale.

### Audit initial

Les quatre défauts signalés ont été confirmés à la lecture, puis reproduits par
un test rouge sur le véritable écran :

| Défaut | Cause trouvée |
| --- | --- |
| Supprimer contourne les protections | `map_workspace_shortcuts.dart` construisait `CharacterEditingCommands` sans `draftGuard` ; `historyGuard` ne voit que les sessions narratives |
| Déplacer n'agit pas sur un décor | la branche armée de `MapCharacterGesture.start()` capturait le décor sans savoir le déplacer ; `_movingHint` n'était jamais remis à `null` |
| Interaction non enregistrée introuvable depuis Carte | `_openStoryInteraction` exigeait l'espace Histoire, et l'appelant invalidait sa propre requête par un second incrément |
| Menu et Maj+F10 perdent la cible | lignes indexées par `target.id` ; ouverture clavier depuis `stackPosition` et premier élément de la pile |

Trouvé en chemin : chaque carte ayant sa propre `MapWorkspaceViewState`, un
déplacement armé survivait à l'aller-retour ; et une requête de menu était
seulement masquée sur une autre carte, pas fermée.

### Corrections et zones modifiées

| Fichier | Zone | Raison |
| --- | --- | --- |
| `application/map_context_menu_model.dart` | `mapContextAnchorOf`, `locateMapContextTarget` | retrouver une cible par sa famille et sa position actuelle, jamais par une ancienne case |
| `application/map_context_menu_actions.dart` | `MapContextActionContext`, `_characterActions` | retrait du garde narratif non qualifié par carte |
| `map_selection_context.dart` (créé) | correspondances de familles, `selectedContextTarget` | pont unique entre la sélection et le menu, partagé par Supprimer et Maj+F10 |
| `map_workspace_shortcuts.dart` | `delete()` | Supprimer passe par `MapContextCommandRunner` avec le contexte de l'écran |
| `workspace_keyboard_binding.dart` | `_keyboard` | aucune commande destructive derrière un menu ouvert |
| `workspace_world_binding.dart` | `_draftReferenceSources` | une session d'interaction modifiée protège aussi sa zone d'histoire |
| `map_workspace_view_state.dart` | `pendingMove`, `armMove`, `moveHint`, `armedDecorIn`, `attachViewport`, `globalOfCell` | consigne portée par la cible armée ; liaison du viewport sortie du canvas |
| `map_workspace_canvas.dart` | `_down`, `_up` | un décor armé reprend le chemin ordinaire et libère le déplacement |
| `map_character_gesture.dart` | `start()` | la branche armée ne capture plus un décor |
| `workspace_context_menu_binding.dart` | `_releaseStaleMapState`, `_openContextMenuFromKeyboard`, `_openExistingStoryZone`, `_chooseInteraction` | libérations au changement de carte, d'outil ou de cible ; ouverture clavier ciblée ; choix limité aux interactions liées |
| `workspace_story_binding.dart` | `_openStoryInteraction` | origine explicite, une seule requête |
| `map_context_menu.dart` | lignes de cibles | clé et sélection qualifiées |
| `map_workspace_screen.dart`, `workspace_screen_body.dart` | `_changed`, raccourcis, consigne | raccordements |

### Passes

- **Audit / architecture** : défauts confirmés, aucune règle de protection
  recopiée dans les raccourcis, aucune couche `application` ne voit Flutter.
- **Implémentation** : réutilisation des commandes, de l'index des brouillons et
  du runner existants ; aucun cadre général de commandes.
- **Tests** : un test d'acceptation par défaut sur le véritable
  `MapWorkspaceScreen`, avec les ports narratif, Événements et Monde montés
  comme par `StudioWorkspaceHost`, rouge avant la correction. Les parcours déjà
  verts avant correction sont des gardes explicites (cible libre supprimable,
  interaction enregistrée, lecture tardive).
- **Build / validation** : voir « Résultats ».
- **Critique finale**, par un relecteur indépendant en lecture seule. Corrigé
  suite à ses constats : zone d'histoire en cours d'écriture supprimable,
  garde narratif non qualifié par carte, déplacement armé qui survivait à un
  changement d'outil, coût de la vérification de cible disparue, dialogue de
  choix sans défilement ni nom de repli, formulation du message de Maj+F10.
  Non corrigé : le setter `pendingMove` efface la consigne quand il reçoit une
  valeur (piège d'API interne, sans chemin utilisateur) ; `blocksDeletion` n'a
  plus d'appelant, laissé pour ne pas toucher au contrôleur narratif.

### Décisions à valider

- Supprimer et Retour arrière agissent désormais sur toutes les familles que le
  menu supprime, avec ses protections. Avant, la touche ne supprimait que les
  décors et les personnages. Un test prouve suppression et annulation pour le
  panneau, le passage et la zone de jeu.
- `codex_rule.md` demande un maximum de commentaires ; le mandat en interdit
  dans le code manuel. Le mandat a été suivi.
- Aucune écriture Notion : le mandat l'interdit sans autorisation, et le
  connecteur demande une authentification.
- Parité MCP PokeMap : non applicable, aucune nouvelle sémantique de données ni
  commande ; seules les routes d'interface vers des commandes existantes
  changent.

## Correctif AS-EXP-001 — priorité au travail non enregistré

Un cinquième test de l'hôte réel reproduit la première sauvegarde d'une
interaction simplifiée, une seconde modification laissée en brouillon, puis
« Ouvrir son interaction » depuis Carte. La réouverture reprend la même session
et son contenu courant, sans publication implicite. Une session simplifiée
propre laisse toujours la priorité au propriétaire Événements. La correction
est dans `_openStoryInteraction()` ; les protections de coexistence restent
actives.

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
