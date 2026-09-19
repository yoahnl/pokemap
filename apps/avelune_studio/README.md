# Avelune Studio — Intégration M1

Studio ouvre un projet PokeMap, affiche ses cartes et leurs ressources, permet
d’éditer les décors préparés et des tuiles simples, puis d’enregistrer et de tester
la carte dans le runtime existant. L’ancien éditeur reste disponible séparément.

## Lancer l’exemple

Depuis la racine du dépôt, avec le Dart livré par votre SDK Flutter :

```sh
cd apps/avelune_studio
flutter pub get
dart run tool/create_example_project.dart
flutter run -d macos --no-pub
```

Le générateur imprime un nouveau dossier temporaire : deux cartes, un atlas
original de test, trois décors et un personnage. Il refuse une cible déjà existante.
Un argument permet de choisir un autre nouveau dossier. Aucun asset personnel ni
de jeu tiers n’est nécessaire.

Dans Studio, **Ouvrir un projet** permet de choisir ce dossier. Le sandbox macOS conserve
ses protections et accorde la lecture/écriture uniquement au dossier choisi.
Une saisie manuelle peut nécessiter cette sélection préalable. Les plugins Apple
utilisent Swift Package Manager. SDK vérifié : Flutter 3.48.0-0.4.pre,
Dart embarqué 3.14.0-95.2.beta, macOS arm64.

## Utiliser une carte

- Choisir une carte par son nom. Les cartes déjà ouvertes conservent document,
  historique, sélection et zoom ; changer de carte ne perd pas les modifications.
- Rechercher un décor dans la palette, puis cliquer plusieurs fois sur la carte.
  Échap revient à la sélection. Cliquer/glisser déplace un décor avec aperçu ;
  la modification est validée à la fin du geste.
- **Empilement ici** sélectionne un décor masqué. **Passer devant / derrière**
  change son ordre d’un cran parmi les décors compatibles qui se recouvrent.
  Cet ordre est enregistré sans changer les collisions ni la priorité d’interaction.
- Choisir une tuile déjà référencée dans la palette pour peindre. La gomme cible
  le support contenant une tuile visible au départ du trait. Un trait interpolé
  compte comme une seule opération d’historique.
- La main déplace la vue ; molette/pincement et boutons règlent le zoom.
  Recentrage et grille sont disponibles.
- **Enregistrer** écrit la carte avec contrôle de révision et persistance atomique.
  Un conflit ou une erreur conserve le travail en mémoire. Aucun écrasement forcé.
  À la fermeture, choisir Enregistrer, Abandonner ou Annuler.
- **Enregistrer et tester** démarre le vrai runtime après sauvegarde confirmée et
  contrôle de révision. Les sauvegardes de jeu restent en mémoire dans cette
  session de test. Revenir au Studio restaure le document et sa vue.

Raccourcis affichés dans les infobulles : ⌘/Ctrl+Z, ⌘/Ctrl+Maj+Z,
⌘/Ctrl+S, ⌘/Ctrl+↑/↓ et Suppr/Retour arrière. Ils ne modifient pas la carte
pendant une saisie de texte.

## Limites explicites

Le Studio prévisualise les animations à leur première frame. Les bordures sont
conservées mais leur aperçu Studio affiche un avertissement ; le runtime les
charge normalement. La sélection des décors suit leur empreinte en cellules,
pas l’alpha exact de l’image. L’ordre fixe est limité aux contextes compatibles :
il ne remplace pas la profondeur dynamique du personnage.

La peinture ne remplace pas Smart Tile Studio ou la bibliothèque de ressources.
Les autres familles de données restent conservées ; leurs studios spécialisés,
la sélection multiple, l’import et la 3D ne font pas partie de M1.
Les métadonnées sont indexées à l'ouverture. Les images sont demandées pour la
carte active, le pinceau puis les miniatures visibles ; aucun plafond de 128 atlas.
Le cache conserve au plus 256 Mio décodés, avec éviction des images non utilisées.
Un décodage à la fois, limité à 64 Mio encodés et 64 Mio décodés par image,
borne les allocations temporaires. Les consommateurs retiennent leurs images
jusqu'à leur retrait ; changer de carte recharge une image évincée à la demande.

La barre d'état compte uniquement les incidents des ressources demandées.
**Détails** ouvre une liste filtrable par carte active ; le réessai cible les échecs.
Une image froide ou évincée n'est pas déclarée absente. La pression mémoire
reste distincte d'un fichier absent, d'un accès refusé ou d'un échec de décodage.

Les formats dont une réécriture perdrait des champs sont refusés pour l’édition.
AS-ARC-002-bis reste actif : un chemin d’entrée ou une racine résolue altérable
par le nettoyage partagé est refusé avant lecture de manifeste. Ce refus ne
constitue pas un support complet des noms terminés par un espace ; sa réserve
native historique reste distincte de M1.

## Organisation du code

L'organisation reprend la séparation de Grimaldi entre métier, présentation,
intégrations natives et composition. Le thème desktop sombre et les contrôles
compacts sont centralisés dans presentation/theme et presentation/shared/widgets.

```text
lib/
  app/
    di/                       Providers Riverpod et barrel providers.dart
    studio_app.dart           Application et fermeture native
    studio_bootstrap.dart     Assemblage des adaptateurs concrets
  features/
    project_session/
      domain/                 Session, port et erreurs typées
      application/            Contrôleur et état de session
      data/                   Lecture locale du projet
    map_workspace/
      domain/                 Contrat et document de carte
      application/            Documents éditables, commandes et contrôleur
      data/                   Chargement et sauvegarde des cartes
  platform/
    files/                    Sélecteur de dossier natif
    rendering/                Adaptateurs de ressources et de rendu
    playtest/                 Intégration du runtime existant
  presentation/
    features/                 Écrans et widgets propres à chaque fonctionnalité
    shell/                    Structure des écrans et hôte du workspace
    theme/                    Thème et styles Flutter
    shared/widgets/
      buttons/                StudioButton et StudioTool
      inputs/                 StudioPathField et StudioChoice
      layout/                 StudioPanel et StudioSidebar
      feedback/               StudioNotice
      dialogs/                Confirmation de fermeture
  main.dart
```

`app/di/providers.dart` contient uniquement des exports. Les définitions de
providers y sont réparties par responsabilité et exposent des contrats abstraits ;
seul `studio_bootstrap.dart` les branche sur les adaptateurs. La présentation
consomme ce barrel sans dépendre des implémentations disque ou natives.

Riverpod gère l'injection et la portée des contrôleurs. La session globale vit
jusqu'à la destruction du scope racine ; chaque workspace possède un contrôleur
lié à son instance de projet, libéré lorsqu'il quitte l'écran. Les contrôleurs
métier restent en Dart pur avec leurs notifications existantes. Les documents en mémoire,
les gestes et les opérations d'édition conservent leurs garanties existantes.
Les adaptateurs de rendu restent sous `platform` car ils accèdent aux ressources
locales ; ce ne sont pas des widgets génériques de présentation.

## Projet volumineux reproductible

`dart run tool/create_example_project.dart --stress /nouveau/dossier` produit
132 atlas valides, trois cartes et 200 incidents représentatifs, sans utiliser
d'assets personnels. La première carte référence l'atlas 131. Le générateur
refuse toute destination déjà existante.

## Vérifier

```sh
flutter test --no-pub
flutter analyze --no-pub
flutter build macos --debug --no-pub
```

Les preuves et les réserves de recette sont détaillées dans le
[rapport UX et ressources](../../documentation/reports/avelune_studio/M1_ux_ressources/README.md).
Le runner existant `tool/run_check.py` conserve sorties, codes et descendants de
tests ; son répertoire historique par défaut reste AS-ARC-002. La mission M1
redirige ce chemin en mémoire vers son propre dossier de preuves.
