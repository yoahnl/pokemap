# Avelune Studio — Ressources et terrains M2

Studio ouvre un projet PokeMap, affiche ses cartes et leurs ressources, permet
d’éditer les décors préparés et des tuiles simples, puis d’enregistrer et de tester
la carte dans le runtime existant. M2 ajoute l’import PNG, la préparation de décors
et de terrains automatiques. L’ancien éditeur reste disponible séparément.

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

## Des ressources à la carte

- **Ressources** ou **Gérer les ressources** ouvre la bibliothèque : décors,
  terrains, images et tuiles, recherche, catégories existantes, grille ou liste.
  **Utiliser sur la carte** retrouve la carte active ou propose une carte.
  Les documents, historiques, vues et brouillons restent en mémoire pendant
  cette navigation. Le compteur d’usages porte explicitement sur les cartes ouvertes.
- **Importer une image** choisit un PNG, montre sa prévisualisation, son nom et
  sa grille. L’import copie réellement la source dans le projet via staging et
  transaction authoring avec journal de reprise. Annuler ne publie aucune ressource.
  La préparation accepte jusqu’à 64 Mio encodés et 64 Mio décodés ; les atlas déjà
  présents disposent du budget de lecture plus large décrit ci-dessous.
- **Créer un décor** sélectionne exactement un rectangle de cellules, propose
  une miniature, un nom et un masque de collision modifiable. **Enregistrer et
  utiliser** publie la définition puis sélectionne le pinceau. Modifier une
  définition partagée affecte ses instances ; **Créer une variante** conserve
  l’original. L’occlusion demeure indépendante du masque de collision.
- **Créer un terrain automatique** prépare le modèle natif à quatre voisins et
  seize raccords : choisir une règle puis une case source. Le terrain d’essai
  utilise le résolveur existant ; cliquer un résultat retrouve la règle concernée.
  Le brouillon peut être enregistré et repris, puis **Publier et peindre** permet
  le trait, la gomme et l’annulation sur la carte, sans gérer de calques à la main.
- **Enregistrer et tester** utilise les mêmes données publiées dans le runtime.
  Les mutations propres au Studio avancent la révision après validation du reçu ;
  une modification extérieure reste un conflit et ne détruit pas le travail local.

## Limites explicites

Le Studio prévisualise les animations à leur première frame. Les bordures sont
conservées mais leur aperçu Studio affiche un avertissement ; le runtime les
charge normalement. La sélection des décors suit leur empreinte en cellules,
pas l’alpha exact de l’image. L’ordre fixe est limité aux contextes compatibles :
il ne remplace pas la profondeur dynamique du personnage.

La création de terrains couvre le modèle cardinal à seize morceaux. Les presets
avancés compatibles restent utilisables, mais leur édition spécialisée n’est pas
encore disponible. Les catégories se filtrent sans éditeur de catégories dédié.
La conversion en décor exige une grille régulière identique à celle du projet,
sans marge, espacement ou décalage ; les autres sources gardent leur parcours de
tuiles, avec un motif explicite quand la conversion n’est pas disponible.
Les sources anciennes sans métadonnées de découpe conservent leurs tuiles déjà
référencées, mais le nouveau sélecteur ne peut pas en exposer toute la planche.
Les autres studios spécialisés, la sélection multiple et la 3D restent hors lot.
Les métadonnées sont indexées à l'ouverture. Les images sont demandées pour la
carte active, le pinceau puis les miniatures visibles ; aucun plafond de 128 atlas.
Le cache conserve au plus 256 Mio décodés, avec éviction des images non utilisées.
Un seul décodage à la fois ; l’admission estime quatre fois les octets RGBA et
deux fois les octets encodés, plus les images résidentes ou encore retenues,
dans un budget de 512 Mio. Ce budget estimé n’est pas une mesure du RSS système.
Le grand atlas HGSS de 4096 × 5280 pixels a été décodé et rendu sur une copie isolée.
Les images ne sont pas décodées partiellement : le découpage runtime vient après
le décodage. Les consommateurs retiennent leur génération jusqu’à leur retrait ;
les reçus de mutation invalident uniquement les chemins concernés, y compris
un remplacement au même chemin. Une limite déterministe désactive le réessai.

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
    resources/                Port pur et transactions authoring locales
    decors/application/       Brouillons, variantes et masques
    terrains/                 Règles natives, brouillons et gestes de peinture
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
[rapport M2](../../documentation/reports/avelune_studio/M2_ressources_terrains/README.md).
Les captures M2 proviennent de widgets Flutter exécutés hors écran avec les vrais
adaptateurs et fichiers. Le pilote natif s’est rattaché à une ancienne fenêtre :
le dialogue système d’import n’est donc pas certifié par ce parcours automatisé.
Le runner existant `tool/run_check.py` conserve sorties, codes et descendants de
tests ; son répertoire historique par défaut reste AS-ARC-002. La mission M2
redirige ce chemin en mémoire vers son propre dossier de preuves.
