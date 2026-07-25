# Runtime-Owned Player Shell — Design Specification

**Date :** 2026-07-25
**Statut :** direction approuvée et implémentée ; certification P7 exécutée
**Roadmap concernée :** `FG-015`, `FG-160`, `FG-163`, `FG-165`, avec
clarification de `FG-070`, `FG-071`, `FG-091` et `FG-094`
**Surface :** `map_runtime`, `map_player_ui`, `pokemap_hub`
**Périmètre de livraison :** player lancé par le Hub

## 1. Résumé

Le Hub ne doit pas posséder l’interface d’une partie en cours.

Sa responsabilité produit s’arrête à :

- installer et vérifier un package ;
- gérer la bibliothèque ;
- sélectionner une version installée ;
- fournir l’identité et le stockage de sauvegarde du jeu ;
- lancer un player ;
- récupérer le contrôle après un retour explicite au Hub.

Toute la session joueur appartient au runtime :

```text
titre
→ chargement
→ monde
→ pause
→ écrans joueur
→ monde
→ résultat
→ crédits
→ titre ou Hub
```

`map_runtime` est l’autorité sur les états, les commandes, les inputs, le
lifecycle et les services contextuels. `map_player_ui` rend ces états sous forme
de widgets Flutter accessibles et responsives. `pokemap_hub` ne compose aucun
menu ou overlay en jeu.

Le design retient un menu A1 :

- panneau latéral et détail côte à côte sur grande largeur ;
- panneau compact à deux colonnes en mobile paysage ;
- feuille de pause puis page dédiée en mobile portrait ;
- clavier, souris et manette sur PC ;
- tactile et manette sur mobile ;
- focus et sous-écran conservés lors d’un changement d’orientation.

Boutique, Centre Pokémon et PC restent exclusivement liés à des interactions
dans le monde. Ils ne figurent jamais dans le menu pause.

## 2. Décisions utilisateur acquises

Les décisions suivantes sont validées :

1. toute la session joueur est runtime-owned, y compris le titre, la pause, les
   sous-écrans, le résultat et les crédits ;
2. le Hub ne doit pas posséder de widgets, contrôleurs ou états de présentation
   en jeu ;
3. `map_runtime` reste l’autorité et ne dépend jamais de `map_player_ui` ;
4. `map_player_ui` dépend de `map_runtime` et rend ses snapshots ;
5. le menu suit la variante responsive A1 ;
6. PC : clavier, souris et manette ;
7. mobile portrait et paysage : tactile et manette ;
8. le bouton tactile Menu reste disponible avec une manette connectée, mais
   devient plus discret après une entrée manette ;
9. le Centre Pokémon V0 utilise un dialogue court, une confirmation, un soin
   transactionnel et un message de résultat ;
10. Boutique, soin et PC ne sont jamais des entrées globales du menu ;
11. un jeu standalone doit rester architecturalement possible sans dépendre du
    Hub ;
12. la création, l’export et le packaging standalone sont hors périmètre du
    chantier actuel.

## 3. Objectifs

### 3.1 Objectifs fonctionnels

Le joueur doit pouvoir :

- accéder à un écran titre géré par le player ;
- lancer ou continuer une partie ;
- ouvrir le menu via une action Menu/Start ;
- reprendre la partie ;
- consulter Équipe, Sac, Pokédex et Carte lorsque ces écrans sont disponibles ;
- sauvegarder ;
- ouvrir les Options ;
- revenir proprement au titre ;
- revenir du titre au Hub ;
- utiliser une boutique uniquement après une interaction de monde ;
- recevoir un soin uniquement après une interaction de monde ;
- utiliser un PC uniquement après une interaction de monde ;
- conserver une navigation utilisable au clavier, à la souris, au tactile ou à
  la manette selon la plateforme ;
- changer d’orientation mobile sans perdre son écran courant ni sa sélection.

### 3.2 Objectifs techniques

- déplacer l’autorité du player hors de `pokemap_hub` ;
- conserver le sens de dépendance `map_player_ui → map_runtime` ;
- fournir des contrats génériques ne mentionnant ni le Hub ni
  `map_distribution` ;
- garantir une seule autorité d’input ;
- ne jamais laisser un overlay Flutter et une UI Flame concurrente présenter
  la même interaction ;
- garantir que chaque modalité d’input produit les mêmes commandes logiques ;
- rendre les services contextuels transactionnels et input-safe ;
- préserver la possibilité future d’un host standalone.

## 4. Non-objectifs

Cette tranche ne livre pas :

- un générateur d’application standalone ;
- l’export d’un projet vers un bundle macOS, Windows, Linux, Android ou iOS
  standalone ;
- la signature ou la distribution d’un standalone ;
- un nouveau moteur de combat ;
- un nouveau moteur narratif ;
- un moteur de scripts exécutables ;
- une boutique accessible depuis le menu pause ;
- un Centre Pokémon accessible depuis le menu pause ;
- un PC accessible depuis le menu pause ;
- une détection de layout fondée sur le nom de plateforme ;
- un remapping complet des contrôles ;
- une refonte visuelle de l’éditeur.

Les contrats créés ne doivent toutefois pas empêcher le standalone futur.

## 5. Architecture retenue

### 5.1 Graphe de dépendances

```text
apps/pokemap_hub
├── map_distribution
├── map_player_ui
└── adaptateurs Hub vers les ports runtime

map_player_ui
└── map_runtime

map_runtime
├── map_core
├── map_gameplay
└── map_battle
```

Interdictions :

```text
map_runtime ─X→ map_player_ui
map_runtime ─X→ pokemap_hub
map_player_ui ─X→ pokemap_hub
```

Le fait que le widget Flutter vive dans `map_player_ui` ne retire aucune
autorité au runtime. Le widget :

- lit des snapshots runtime ;
- envoie des commandes runtime ;
- ne décide pas lui-même des transitions de session ;
- ne lit pas directement le projet JSON ;
- ne lit pas directement les sauvegardes ;
- ne possède pas une seconde machine à états.

### 5.2 Responsabilités de `map_runtime`

`map_runtime` possède :

- le chargement et l’interprétation du projet joueur ;
- le graphe jetable de session ;
- la machine à états player ;
- le runtime Flame ;
- les snapshots titre, pause, sous-écrans, services, résultat et crédits ;
- les commandes player ;
- l’autorité d’input ;
- les verrous d’input ;
- le lifecycle ;
- les commandes de sauvegarde ;
- les commandes contextuelles Boutique, soin et PC ;
- la validation des commandes révisionnées ;
- le teardown complet avant un retour externe.

### 5.3 Responsabilités de `map_player_ui`

`map_player_ui` possède :

- `PokeMapPlayerSessionView` ;
- le menu responsive A1 ;
- les écrans titre, pause, Équipe, Sac, Pokédex, Carte et Options ;
- les surfaces de chargement, erreur, résultat et crédits ;
- les surfaces Flutter des services contextuels ;
- le focus Flutter ;
- les semantics ;
- le text scaling ;
- le reduced motion ;
- les glyphes d’input ;
- les cibles tactiles ;
- le design system joueur.

### 5.4 Responsabilités de `pokemap_hub`

Le Hub possède :

- la bibliothèque ;
- l’installation et la réparation ;
- la résolution d’une version installée ;
- l’identité `gameId` ;
- les profils et slots Hub ;
- l’adaptateur de sauvegarde scopé ;
- les préférences globales ;
- le montage d’un `PokeMapPlayerSessionView` ;
- un callback externe après teardown : `onReturnToHub`.

Le Hub ne possède plus :

- `HubPlayerShellSurface` ;
- un contrôleur de titre ou pause ;
- un menu Équipe/Sac/Pokédex ;
- un overlay Boutique/soin/PC ;
- un contrôleur de présentation combat/dialogue/post-combat ;
- une machine à états concurrente de la session runtime.

## 6. Contrats runtime génériques

Les noms ci-dessous expriment le design. Le plan d’implémentation pourra les
adapter aux conventions existantes sans modifier leur responsabilité.

### 6.1 `RuntimeGameSource`

Le player reçoit une source générique :

```dart
abstract interface class RuntimeGameSource {
  GameIdentity get identity;

  Future<RuntimeGameLaunch> resolve();
}
```

`RuntimeGameLaunch` fournit au minimum :

- identité stable ;
- version du jeu ;
- version du projet ;
- chemin ou resolver du projet joueur ;
- resolver d’assets borné à la racine installée ;
- branding déclaratif ;
- locales ;
- capacités déclarées ;
- compatibilité de sauvegarde.

L’implémentation Hub utilise le package installé. Une future implémentation
standalone pourra utiliser des assets embarqués, sans changement du player.

### 6.2 `PlayerSaveGateway`

Le player dépend d’un port de sauvegarde :

```dart
abstract interface class PlayerSaveGateway {
  Future<PlayerSaveCatalogSnapshot> inspect();
  Future<PlayerSaveReadResult> read(PlayerSaveAddress address);
  Future<PlayerSaveWriteResult> write(PlayerSaveWriteRequest request);
}
```

Ce port :

- est scopé par `gameId` ;
- ne transporte aucun type Hub ;
- préserve profils et slots ;
- conserve les garanties d’écriture atomique ;
- retourne des erreurs typées et présentables ;
- ne permet pas au player de parcourir les sauvegardes d’un autre jeu.

### 6.3 `RuntimePlayerCoordinator`

Le coordinateur runtime est l’unique machine à états player :

```dart
abstract interface class RuntimePlayerCoordinator {
  ValueListenable<RuntimePlayerSnapshot> get snapshot;

  Future<RuntimePlayerCommandResult> dispatch(
    RuntimePlayerCommand command,
  );

  Future<void> dispose();
}
```

Il remplace les décisions actuellement réparties entre :

- le `PlayerShellController` du Hub ;
- le `GameSessionController` ;
- le `GameWidget` ;
- les overlays Flutter host-owned.

Le contrôleur de session existant peut rester un composant interne. Il ne doit
plus être doublé par une machine à états produit dans le Hub.

### 6.4 Snapshots et commandes

`RuntimePlayerSnapshot` expose :

- phase player ;
- identité et branding ;
- disponibilité des actions ;
- progression de chargement ;
- écran pause courant ;
- données du sous-écran ;
- service contextuel courant ;
- erreur récupérable ;
- résultat et crédits ;
- révision monotone ;
- source d’input active pour les glyphes.

Les commandes sont typées :

```text
openMenu
resume
openParty
openBag
openPokedex
openMap
openOptions
save
returnToPauseRoot
returnToTitle
returnToHub
select
confirm
back
```

Une commande de présentation inclut la révision du snapshot observé. Une
commande obsolète est refusée sans mutation.

## 7. Machine à états player

La machine cible est :

```text
boot
→ title
→ preparingSession
→ loadingSession
→ playing
↔ paused.root
↔ paused.party
↔ paused.bag
↔ paused.pokedex
↔ paused.map
↔ paused.options
→ saving
→ playing ou paused.*
→ completing
→ result
→ credits
→ title ou externalExit
```

États transverses :

```text
lifecyclePaused(previousState)
recoverableError(previousState)
disposingSession
```

Règles :

- une seule phase est propriétaire des inputs ;
- un sous-écran pause ne crée pas une seconde session ;
- une ouverture de service contextuel suspend la navigation pause et
  l’overworld ;
- `returnToTitle` détruit la partie Flame avant de publier `title` ;
- `returnToHub` n’est valide que depuis `title` ;
- le callback Hub n’est appelé qu’après teardown réussi ;
- une erreur de teardown est affichée et ne produit pas un faux retour réussi.

## 8. Menu responsive A1

Le layout utilise les contraintes Flutter, pas `Platform.isX`.

### 8.1 Classe `expanded`

Conditions indicatives :

- largeur suffisante pour deux zones lisibles ;
- hauteur suffisante pour les actions sans compression.

Présentation :

- monde visible derrière un scrim ;
- panneau aligné à droite ;
- navigation à gauche du panneau ;
- contenu détaillé à droite ;
- souris, clavier et manette utilisables simultanément.

### 8.2 Classe `compactLandscape`

Conditions indicatives :

- orientation large ;
- largeur insuffisante pour le panneau desktop complet.

Présentation :

- panneau occupant une part plus importante de la largeur ;
- navigation compacte ;
- détail à côté ;
- cibles tactiles d’au moins 48 points logiques ;
- bouton tactile Menu visible ;
- navigation manette identique au desktop.

### 8.3 Classe `compactPortrait`

Présentation :

- feuille modale de pause au niveau racine ;
- passage à une page Flutter dédiée pour un sous-écran ;
- retour explicite au menu ;
- listes pleine largeur ;
- cibles tactiles d’au moins 48 points logiques ;
- bouton tactile Menu visible.

### 8.4 Changement de contraintes

Lors d’une rotation ou d’un redimensionnement :

- l’état runtime ne change pas ;
- le sous-écran courant ne change pas ;
- l’identifiant logique sélectionné est conservé ;
- le focus Flutter est restauré sur le contrôle correspondant ;
- aucun événement de validation n’est synthétisé ;
- aucune direction overworld n’est réactivée.

## 9. Contrat d’input

### 9.1 Sources

PC :

- clavier ;
- souris ;
- manette.

Mobile :

- tactile ;
- manette ;
- portrait et paysage.

### 9.2 Commandes logiques

Toutes les sources convergent vers un routeur unique :

```text
up
down
left
right
confirm
back
menu
```

Exemples de mappings V0 :

```text
clavier :
  flèches ou WASD → directions
  Entrée, E ou Espace → confirm
  Échap → back ; ouvre le menu depuis l’overworld
  Tab → menu

manette :
  D-pad ou stick numérique → directions
  A / bouton principal → confirm
  B / bouton secondaire → back
  Start → menu

souris :
  hover → focus visuel facultatif
  clic → confirm

tactile :
  tap → confirm
  bouton Menu → menu
```

Le remapping complet est hors périmètre, mais les widgets ne doivent pas
hardcoder les touches. Ils affichent les glyphes transmis par le snapshot
d’input.

### 9.3 Verrouillage

À l’ouverture d’un écran Flutter runtime :

1. relâcher toutes les directions overworld ;
2. acquérir le verrou correspondant ;
3. publier le snapshot de présentation ;
4. déplacer le focus vers la première action valide.

À la fermeture :

1. retirer le snapshot ;
2. libérer le verrou dans un `finally` ;
3. restaurer l’état runtime propriétaire ;
4. exiger une nouvelle pression pour reprendre un déplacement.

Le bouton tactile Menu reste visible avec une manette connectée. Il peut réduire
son opacité après une entrée manette, mais reste activable et accessible.

## 10. Menu global

Le menu pause expose :

- Reprendre ;
- Équipe ;
- Sac ;
- Pokédex ;
- Carte ;
- Sauvegarder ;
- Options ;
- Retour au titre.

La disponibilité provient du runtime :

- une action prête est activée ;
- une action indisponible est désactivée avec une raison lisible ;
- une capacité projet peut masquer une action qui n’a aucun sens pour ce jeu ;
- aucun écran ne simule une mécanique inexistante.

Entrées interdites :

- Boutique ;
- Centre Pokémon ;
- Soin gratuit ;
- PC.

## 11. Services contextuels du monde

### 11.1 Sources d’interaction

Un service peut être déclenché par :

- un PNJ ;
- un objet inspectable ;
- une zone ;
- un événement narratif ;
- une Scene ;
- une interaction conditionnée par des Facts ou l’avancement.

### 11.2 Boutique

Flux :

```text
interaction monde
→ Scene
→ openShop(shopId)
→ validation runtime
→ verrou input
→ snapshot Boutique
→ UI Flutter
→ achat ou annulation
→ commit transactionnel
→ reprise Scene ou overworld
```

Le runtime :

- résout la boutique et son état dynamique ;
- refuse un `shopId` inconnu ;
- revérifie prix, argent, stock et état avant mutation ;
- ne publie aucun état intermédiaire ;
- restitue les inputs sur succès, annulation ou erreur.

### 11.3 Centre Pokémon V0

Flux simple :

```text
interaction monde
→ dialogue
→ « Soigner l’équipe ? »
→ confirmation
→ healParty
→ commit HP / PP / statuts
→ message de résultat
→ reprise
```

Une interaction spéciale peut appeler `healParty` sans confirmation : lit,
fontaine, récompense ou événement narratif.

### 11.4 PC

Le PC suit la même règle contextuelle :

```text
interaction monde
→ commande PC typée
→ verrou input
→ snapshot PC
→ UI Flutter
→ transaction ou annulation
→ reprise
```

Le PC n’est pas requis pour fermer le premier lot de menu, mais son absence du
menu global est un contrat immédiat.

### 11.5 Erreurs

Une référence ou transaction invalide :

- affiche un message joueur sûr ;
- fournit un code diagnostic ;
- ne modifie pas le `GameState` ;
- ne consomme pas l’événement narratif si le service n’a pas abouti ;
- ferme ou permet de réessayer ;
- libère toujours le verrou d’input.

## 12. Lifecycle et récupération

### 12.1 Sauvegarde

- l’écriture passe par `PlayerSaveGateway` ;
- l’écran courant reste visible pendant la requête ;
- une confirmation est publiée après validation ;
- une erreur conserve la dernière sauvegarde valide ;
- une nouvelle tentative est possible ;
- aucun succès n’est affiché avant le commit.

### 12.2 Arrière-plan

Quand l’application passe en arrière-plan :

- capturer l’état player précédent ;
- relâcher les directions ;
- suspendre la session ;
- conserver le sous-écran logique ;
- afficher une surface runtime de suspension si l’application reste visible.

À la reprise :

- restaurer l’état player précédent ;
- restaurer le focus logique ;
- ne pas réinjecter les directions précédemment maintenues.

### 12.3 Retour au titre

Ordre obligatoire :

1. refuser de nouvelles commandes ;
2. relâcher les inputs ;
3. fermer les services et overlays ;
4. produire le checkpoint requis ;
5. démonter `GameWidget` ;
6. disposer le graphe Flame ;
7. vider les caches de session non partagés ;
8. publier l’état titre.

### 12.4 Retour au Hub

Le retour au Hub :

- n’est exposé que depuis le titre ;
- exige l’absence de session montée ;
- déclenche un callback externe unique ;
- ne transporte aucun widget Hub dans le player.

## 13. Intégration Hub

La composition Hub cible est conceptuellement :

```dart
PokeMapPlayerSessionView(
  source: HubInstalledRuntimeGameSource(...),
  saves: HubScopedPlayerSaveGateway(...),
  preferences: HubPlayerPreferencesGateway(...),
  onExternalExit: onReturnToHub,
)
```

Le Hub peut construire les adaptateurs. Il ne :

- transforme pas les snapshots en écrans ;
- route pas les actions pause ;
- choisit pas l’état player ;
- active pas les overlays combat/dialogue ;
- présente pas Boutique, soin ou PC.

## 14. Compatibilité standalone future

Les interfaces runtime ne mentionnent pas le Hub. Une future application
standalone pourra fournir :

```text
BundledRuntimeGameSource
LocalStandaloneSaveGateway
StandalonePreferencesGateway
onExternalExit → fermeture ou écran propriétaire
```

Cette tranche ne crée aucune de ces implémentations. La compatibilité est
assurée uniquement par :

- des ports génériques ;
- l’absence de dépendance au Hub ;
- l’absence de chemin d’installation Hub dans les contrats publics ;
- un callback de sortie générique.

## 15. Migration depuis l’état actuel

La migration devra :

1. caractériser les comportements actuels ;
2. introduire les snapshots et commandes génériques dans `map_runtime` ;
3. déplacer la machine player générique hors du Hub ;
4. construire `PokeMapPlayerSessionView` dans `map_player_ui` ;
5. déplacer le menu A1 et ses sous-écrans hors du Hub ;
6. brancher le routeur d’input unique ;
7. remplacer la composition Hub par les adaptateurs génériques ;
8. supprimer les anciens widgets et contrôleurs player du Hub ;
9. brancher les services contextuels Flutter sans les rendre globaux ;
10. conserver le host développeur et ses outils debug séparés.

La migration ne doit jamais réintroduire une double UI Flutter/Flame.

## 16. Stratégie de tests

### 16.1 Architecture

- `map_runtime` ne dépend pas de `map_player_ui`, `pokemap_hub` ou
  `map_distribution` ;
- `map_player_ui` ne dépend pas de `pokemap_hub` ;
- aucun widget ou contrôleur player en jeu ne reste dans le Hub ;
- le host développeur conserve ses outils sans devenir le produit player.

### 16.2 Widgets

Tester :

- layout grande largeur ;
- layout mobile paysage ;
- layout mobile portrait ;
- cibles tactiles ;
- focus clavier ;
- focus manette logique ;
- clic souris ;
- text scaling ;
- reduced motion ;
- rotation avec conservation du sous-écran et de la sélection ;
- raisons des actions désactivées ;
- absence de Boutique, soin et PC.

### 16.3 Runtime

Tester :

- ouverture Menu pendant une direction maintenue ;
- libération des directions ;
- overworld immobile sous menu ;
- reprise avec une nouvelle pression ;
- absence de double input pendant transition ;
- commandes obsolètes refusées ;
- teardown titre complet ;
- retour externe après teardown seulement ;
- arrière-plan et reprise ;
- erreur de sauvegarde récupérable.

### 16.4 Services contextuels

Tester :

- Boutique ouverte par Scene ;
- Boutique absente du menu ;
- achat transactionnel ;
- annulation sans mutation ;
- boutique invalide sans softlock ;
- confirmation de soin ;
- soin HP, PP et statuts ;
- refus ou erreur sans mutation partielle ;
- reprise de la Scene ;
- PC absent du menu.

### 16.5 Intégration Hub

Tester :

- lancement depuis un jeu installé ;
- titre runtime visible ;
- nouvelle partie et continuation ;
- pause runtime visible ;
- retour au titre ;
- retour au Hub ;
- aucune deuxième interface au-dessus du runtime ;
- isolation des sauvegardes inchangée.

### 16.6 Smoke desktop

Sur macOS :

- clavier ;
- souris ;
- commandes manette logiques ;
- redimensionnement ;
- combat puis reprise overworld ;
- Boutique contextuelle ;
- soin contextuel ;
- retour propre au Hub.

## 17. Critères d’acceptation

Le design est correctement implémenté lorsque :

1. le Hub ne contient plus de player shell en jeu ;
2. le titre, la pause et les sous-écrans sont pilotés par un coordinateur
   runtime unique ;
3. `PokeMapPlayerSessionView` rend les snapshots runtime ;
4. les trois dispositions A1 sont testées ;
5. les cinq modalités requises sont supportées :
   clavier, souris, tactile, manette PC, manette mobile ;
6. l’overworld ne reçoit aucun input sous un écran Flutter runtime ;
7. un déplacement fonctionne après fermeture du menu ;
8. une rotation conserve l’écran et la sélection ;
9. Boutique, soin et PC sont absents du menu ;
10. une Boutique s’ouvre depuis une interaction Scene ;
11. un soin simple s’exécute depuis une interaction Scene ;
12. le retour au titre dispose entièrement la session ;
13. le retour au Hub n’arrive qu’après teardown ;
14. les contrats publics ne dépendent d’aucun type Hub ;
15. tests ciblés, analyses et build macOS sont verts, hors échecs préexistants
    explicitement documentés.

## 18. Risques et parades

### 18.1 Deux machines à états pendant la migration

**Risque :** le Hub et le runtime publient simultanément une phase player.

**Parade :** introduire d’abord le coordinateur runtime, puis faire du Hub un
adaptateur passif avant de supprimer l’ancien shell.

### 18.2 Double input

**Risque :** `GameWidget` et le focus Flutter consomment le même événement.

**Parade :** un routeur unique décide du propriétaire avant toute distribution.

### 18.3 Dépendance inversée

**Risque :** `map_runtime` importe `map_player_ui` pour ouvrir un widget.

**Parade :** le runtime publie un snapshot ; `map_player_ui` l’écoute.

### 18.4 UI de service encore host-owned

**Risque :** Boutique ou PC reste implémenté uniquement dans le host développeur.

**Parade :** définir des snapshots/commandes player-service dans le runtime et
les rendre dans `map_player_ui`.

### 18.5 Layout fondé sur la plateforme

**Risque :** desktop étroit ou tablette paysage mal classé.

**Parade :** utiliser uniquement `LayoutBuilder`, dimensions, orientation et
contraintes.

### 18.6 Standalone prématuré

**Risque :** élargir le lot vers plusieurs applications de distribution.

**Parade :** ne livrer que les ports génériques et les adaptateurs Hub.

## 19. Mapping roadmap

### `FG-015 — Runtime Pause Menu Shell V0`

Le lot pourra être proposé `DONE` lorsque le menu minimal appartient réellement
au runtime, reçoit les inputs requis et bloque proprement l’overworld.

### `FG-160 — Pause Menu Complete V0`

Le lot restera `PARTIAL` tant que les écrans reliés ne couvrent pas leurs vrais
flows. Le déplacement architectural et le menu A1 constituent sa base.

### `FG-163 — Runtime Save Menu V0`

Le lot reste séparé : la surface runtime doit appeler le port de sauvegarde et
afficher confirmation/erreur.

### `FG-165 — Runtime Input Lock Conventions V0`

Le routeur unique et les tests de non-fuite d’input sont requis pour proposer le
lot `DONE`.

### `FG-070`, `FG-071`, `FG-091`, `FG-094`

La roadmap devra être clarifiée lors d’une mise à jour explicitement demandée :

- la Boutique ne doit plus être décrite comme accessible depuis le menu pause ;
- le soin doit être déclenché par une interaction ou une Scene ;
- les templates `shop clerk` et `heal center nurse` restent la cible no-code ;
- le PC suit le même contrat contextuel.

## 20. Décision finale

La direction retenue est :

```text
Runtime autoritaire
+ renderer Flutter map_player_ui
+ Hub adaptateur passif
+ menu responsive A1
+ inputs unifiés
+ services de monde contextuels
+ contrats compatibles standalone
- implémentation standalone dans ce lot
```

Cette direction a été approuvée, implémentée et certifiée par le plan
`2026-07-25-runtime-owned-player-shell.md`.

## 21. État livré et limites de certification

Le résultat implémenté respecte les frontières retenues :

- `map_runtime` possède la machine d’état joueur, le lifecycle, les commandes,
  les services contextuels et le teardown ;
- `map_player_ui` rend les snapshots runtime avec le menu A1 responsive ;
- `pokemap_hub` fournit les adaptateurs, monte la vue canonique et récupère le
  contrôle après le callback de sortie ;
- Boutique, soin et PC sont absents du menu pause et ne s’ouvrent que depuis
  une interaction du monde ;
- aucun code standalone n’a été ajouté et aucun contrat public ne dépend du
  Hub.

Le parcours natif macOS certifie l’installation d’une fixture data-only,
l’ouverture depuis la bibliothèque, le titre, la nouvelle partie, le
déplacement, la pause et un détail, la reprise, les services contextuels, la
sauvegarde, le retour au titre, `Continuer`, la restauration de position et le
retour final au Hub sans session active.

La certification matérielle reste limitée :

- aucune manette physique n’était disponible ; les intentions et le focus
  manette sont prouvés par tests automatisés ;
- aucun appareil mobile physique n’était disponible ; portrait, paysage,
  resize, text scaling et conservation d’état sont prouvés par widget tests ;
- le parcours E2E neutre ne déclenche pas un combat, couvert séparément par les
  suites runtime ;
- le dépôt complet reste non vert à cause de trois régressions Selbrume et de
  deux divergences `map_core` consignées dans la section P7 du plan.

Les statuts roadmap sont seulement proposés : `FG-015`, `FG-163`, `FG-165`,
`FG-071` et `FG-091` sont candidats `DONE`, `FG-160` reste `PARTIAL`,
`FG-070` demande la clarification « contextuel uniquement » et `FG-094` reste
inchangé. Le fichier roadmap n’a pas été modifié.
