# Avelune Studio — Charte graphique et parcours M1/M2/M3

## UI-01 — Accueil, en attente de validation visuelle

Lot réalisé le 19 septembre 2026, uniquement sur l’accueil et ses raccordements.
Le ZIP annoncé n’était pas disponible : le brief complet
`avelune_studio_codex_UI01_accueil.md` et l’image originale
`Downloads/Avelune Studio/01 - page d'accueil.png` ont été lus/ouverts.
Aucun `PROMPT_CODEX.md` extrait ni fichier de référence inexistant n’est revendiqué.

L’audit initial a identifié un accueil limité à l’ouverture de dossier, un atelier
déjà fonctionnel et des gardes de brouillons à conserver. L’accueil reprend le
bandeau illustré, la navigation gauche, les six outils, les cartes et la colonne
de droite. Les outils ouvrent le sélecteur si aucun projet n’est chargé, puis
rejoignent leur contexte existant. Le test nécessite une carte disponible.
La recherche filtre seulement les noms/chemins des projets connus et les cartes
du manifeste chargé. Aucun scan ni rendu massif de miniatures n’est ajouté.

L’atelier reste monté lors du retour à l’accueil : document modifié, historique,
zoom et brouillons restent en mémoire. Un remplacement ouvre le candidat avant
de libérer l’ancien projet ; échec ou annulation conservent celui-ci. La garde
de sortie possède désormais l’identifiant de sa session, pour que la destruction
tardive de l’ancien atelier ne désinscrive pas celle du nouveau.
Les cinq projets récents sont enregistrés hors des projets de jeu, dans
`~/Library/Application Support/Avelune Studio/recent-projects.json` sur macOS
(dans le conteneur applicatif lorsque macOS utilise un HOME isolé).
Retirer un récent ne supprime jamais son dossier.

### Assets et comparaison visuelle

`assets/home/hero_landscape.png` (2172 × 724) est une reconstruction générative
du paysage de la référence via `image_gen`, pas un recadrage pixel-identique.
`assets/home/avelune_logo.png` et `avelune_symbol.png` reprennent sans modification
les exports `logo.png` et `icon.png` du nouveau `Downloads/Avelune_Studio_Kit`,
avec leurs variantes Flutter 1×/2×/3×. Le logo complet occupe l’en-tête ;
l’icône seule est utilisée sous 650 px. L’installateur du kit cible l’ancien
éditeur et n’a pas été exécuté ; les icônes natives restent hors de ce changement.
Les captures du vrai arbre Flutter ont été comparées à la référence : titre bleu
éclairci, en-tête compacté à 150 %, composition hero/outils/colonne conservée.
Les données de démonstration sont explicitement nommées comme telles.

Captures hors dépôt, sous
`/Users/karim/.codex/visualizations/2026/09/19/01a0b96a-7828-73d0-a984-42e3e3a5753c/ui01/` :

- `ui01-demo-1536.png` : données de démonstration, 1536 × 1024.
- `ui01-empty.png` : aucun projet ouvert.
- `ui01-active-project.png` : projet temporaire réel ouvert depuis le disque,
  carte modifiée non enregistrée conservée pendant l’aller-retour.
- `ui01-small-150.png` : 1024 × 640, texte à 150 %.

Ce sont des captures de rendu Flutter hors écran avec polices desktop, pas des
captures d’une fenêtre macOS pilotée. Le pilote natif Marionette n’a pas été
ajouté : aucune dépendance ou configuration native n’a été changée.
Les cartes sans miniature affichent un substitut explicite ; aucune miniature
fictive n’est présentée comme réelle. La création de projet reste désactivée et
annoncée comme prochain écran. Le second bandeau illustré n’est pas reproduit.
La validation artistique appartient à l’utilisateur, pas aux tests.

### Vérifications UI-01

Depuis `apps/avelune_studio` :

```bash
flutter run -d macos -t lib/main.dart
flutter test --no-pub --reporter expanded
flutter analyze --no-pub
dart format --output=none --set-exit-if-changed lib test tool
flutter build macos --debug --no-pub
```

Résultats finaux : **261 tests réussis, 2 ignorés** (copie de projet personnel
non fournie), **No issues found!**, **224 fichiers, 0 changement de format**,
**Built build/macos/Build/Products/Debug/Avelune Studio.app**.
Les tests couvrent notamment chemins exacts, annulation, récents/persistance,
recherche, actions des six outils, identité du document/zoom/historique,
remplacement annulé et garde de sortie après remplacement. Les tailles 1536,
1440, 1280, 1024 à 150 % et 480 px sont vérifiées sans débordement.
Le lanceur de tests suit les descendants et leurs identités : 67 enfants
observés sur la dernière suite, aucun processus résiduel à terminer.
Le journal et le reçu sont `final-suite.txt` et `final-suite.json` près des captures.
À la racine : `bash tools/scripts/check_markdown_hygiene.sh` et
`git diff --check` réussissent.

### Périmètre des fichiers et verdicts

Tous les chemins ci-dessous sont relatifs à cette application :

| Fichiers | Zone et rôle |
| --- | --- |
| `lib/app/studio_app.dart`, `lib/app/studio_bootstrap.dart`, `lib/app/di/home_providers.dart` | Injection des récents et propriété de la garde de sortie. |
| `lib/features/home/domain/recent_studio_project.dart`, `lib/features/home/application/recent_projects_controller.dart` | Contrat pur, cinq récents et opérations sérialisées. |
| `lib/features/home/data/local_recent_projects_adapter.dart`, `lib/features/home/data/memory_recent_projects_adapter.dart`, `lib/platform/files/studio_preferences.dart` | Persistance locale atomique et isolation des tests. |
| `lib/features/project_session/application/project_session_controller.dart` | Remplacement transactionnel et annulation du candidat. |
| `lib/presentation/features/home/studio_home_screen.dart`, `studio_home_hero.dart`, `studio_home_navigation.dart`, `studio_home_projects.dart`, `studio_home_tools.dart` dans le même dossier | Composition et interactions de l’accueil. |
| `lib/presentation/features/project_session/project_session_screen.dart`, `project_open_controls.dart` dans le même dossier | Atelier conservé monté, sélecteur, erreurs et chemin exact. |
| `lib/presentation/shell/studio_home_navigation.dart`, `lib/presentation/shell/studio_workspace_host.dart` | Navigation de présentation et raccordement à l’atelier existant. |
| `lib/presentation/features/map_workspace/map_workspace_screen.dart`, `map_workspace_layout.dart`, `workspace_home_binding.dart` dans le même dossier | Destination Accueil, projection des cartes connues et callbacks existants. |
| `lib/presentation/theme/studio_home_tokens.dart`, `assets/home/hero_landscape.png`, `assets/home/avelune_symbol.png`, `pubspec.yaml` | Accent du titre et déclaration des assets, sans changement de dépendance. |
| `test/home/home_visual_test.dart`, `home_navigation_test.dart`, `home_real_project_test.dart`, `home_exit_guard_test.dart`, `recent_projects_test.dart` dans le même dossier | Rendu, parcours, session et stockage. |
| `test/application/project_session_races_test.dart`, `test/presentation/studio_app_test.dart`, `test/presentation/project_path_submission_test.dart`, `test/support/open_project_path.dart`, `test/support/test_studio_app.dart` | Régressions et adaptation des finders sans affaiblir les garanties de chemins. |
| `README.md` | Provenance, commandes, preuves et limites de ce lot. |

Passes : audit/architecture validé ; agent illustration/interface livré et
analysé ; agent récents/tests livré et analysé ; tests/build validés par la passe
principale ; critique finale : défaut de désinscription de garde trouvé, corrigé
et couvert par `home_exit_guard_test.dart`, aucun autre défaut concret relevé.
Parité MCP : aucune nouvelle sémantique d’édition ; les raccourcis réutilisent les
commandes existantes, les préférences locales restent propres à l’interface.
Pas de modification du serveur MCP ou des moteurs, ni de nouvelle action à publier.

Git initial : HEAD `774d99ac1`, modifications hors lot dans les icônes du Hub.
Git final : uniquement ce lot ajouté dans cette application ; modifications
concurrentes/préexistantes du Hub (icônes et plist) laissées intactes.
Aucun commit/push, aucune modification Notion ni écriture dans un projet original.
Le lot reste **à valider visuellement**. Aucun autre écran n’est commencé.

## Charte graphique intégrée

La présentation utilise un atelier bleu nuit, des panneaux à bordure fine, une
action principale bleue et des aperçus prioritaires. Les neuf références fournies
guident la structure de l’éditeur V2, les bibliothèques avec détail, les atlas et
les écrans narratifs. Leurs bandeaux explicatifs ne font pas partie du produit.
La gestion manuelle des calques reste exclue.

Les valeurs canoniques sont dans `lib/presentation/theme/studio_theme.dart` et
`studio_tokens.dart`. Les écrans consomment ces tokens sémantiques.

| Rôle | Valeur |
| --- | --- |
| Fond / panneau / surface surélevée | `#071522` / `#0D1D2C` / `#14283B` |
| Bordure | `#29445F` |
| Texte principal / secondaire | `#EDF4FF` / `#A4B7CD` |
| Action principale / sélection sur carte | `#2163DF` / `#3BCEF5` |
| Succès / attention / erreur | `#25C49A` / `#F1BE58` / `#E45C69` |
| Accent de fonctionnalité | `#8256E8` |

Le bleu proposé `#2474FF` a été assombri : le contraste texte/bouton atteint
4,85:1. Corps à 14, texte secondaire à 12, titres de section à 16 et de page à 22.
Contrôles de 36, outils compacts de 32 ; rayons de 6 et 8 ; espacement principal
de 12 et marge intérieure de panneau de 16. Les atlas conservent leur ratio,
leur transparence et leur rendu sans lissage. Le focus clavier reste distinct
de la sélection persistante.

### Catalogue intégré

Les noms existants sont conservés lorsqu’ils remplissent déjà la responsabilité
du catalogue. Les composants métier composent le socle partagé ; ils ne sont pas
recopiés dans une bibliothèque parallèle.

| Famille | Composants | Utilisation |
| --- | --- | --- |
| Cadre | `StudioAppShell`, `StudioTopBar`, `StudioNavigationRail`, `StudioSidebar` | Accueil, carte, ressources, histoire, galerie ; navigation compacte avec libellés. |
| Surfaces | `StudioPageHeader`, `StudioPanel`, `StudioSection` | Titres/actions adaptatifs, surfaces Material, sections repliables. |
| Actions | `StudioButton`, `StudioTool`, `StudioDepthControl` | Principale, secondaire, discrète, destructive, chargement ; outils et profondeur locale. |
| Saisie | `StudioDraftField`, `StudioPathField`, `StudioChoice`, `StudioSearchField`, `StudioTabs`, `StudioToggleRow` | Brouillons, recherche effaçable, choix, onglets et options. |
| Retour utilisateur | `StudioNotice`, `StudioBadge`, `StudioEmptyState` | Erreurs, information, catégories, absence de résultat. |
| Ressources | `StudioResourceCard`, `StudioResourceGrid`, `StudioAssetPreview`, `ResourceDetailPanel` | Aperçus dominants, grille virtualisée, damier, métadonnées et utilisation sur la carte. |
| Préparation | `confirmImageImport`, `DecorEditorScreen`, `TerrainEditorScreen`, `AtlasSelectionView`, `TerrainScratchView` | Import, décor, raccords automatiques et essai ; contrôles existants et surfaces communes. |
| Carte | `MapWorkspaceLayout`, `MapWorkspaceToolbar`, `MapWorkspaceCanvas`, `MapSelectionInspector`, `MapWorkspaceInspector` | Répartition responsive, sélection cyan, aperçu et empilement local. |
| Personnages | `CharacterPalette`, `CharacterInspector`, `DialoguePortraitChoice` | Palette et propriétés dédiées avec thème et primitives partagés. |
| Histoire | `NarrativeStoryPane`, `DialogueLinesEditor`, `NarrativeConditionsEditor`, `NarrativeSequenceEditor` | Conversations, choix, conditions et étapes ; panneaux et onglets communs. |
| Test | `StudioPlaytestView` et session existante | Lancement du vrai runtime depuis la carte ou l’interaction. |

Les personnages restent dans la palette et le test dans les commandes existantes.
Le sélecteur de projets récents, l’assistant générique multiétape et le bandeau
générique de variantes du catalogue cible ne sont pas ajoutés comme composants
inutilisés : les parcours actuels conservent leurs contrôles dédiés. L’accueil
illustré et une reproduction artistique complète des planches ne sont pas livrés.

### Lancer l’application et la galerie

Depuis `apps/avelune_studio` :

```sh
flutter run -d macos -t lib/main.dart
flutter run -d macos -t lib/design_gallery.dart
```

La galerie permet de manipuler les boutons, le chargement, la recherche, les
filtres, la sélection, les sections et les couleurs, aux largeurs 480, 840 et
disponible. Elle est explicitement démonstrative, n’ouvre aucun projet et n’écrit
aucun contenu utilisateur.

### Vérification de la charte

Tests dédiés : `test/presentation/studio_design_system_test.dart`,
`studio_gallery_test.dart` et `studio_atlas_preview_test.dart`. Ils vérifient
chargement, clavier, recherche, sélection, contrastes, fenêtre étroite avec texte
agrandi et ratio réel d’un atlas rectangulaire. Le test de conditions M3 recherche
sa section par défilement après redimensionnement, sans supposer qu’elle est déjà
montée hors écran.

```sh
flutter test --no-pub --reporter expanded
flutter analyze --no-pub
flutter build macos --debug --no-pub
AVELUNE_CAPTURE_DIR=/tmp/avelune-studio-captures flutter test --no-pub test/presentation/studio_gallery_test.dart test/presentation/desktop_workspace_layout_test.dart test/presentation/m2_end_to_end_test.dart test/presentation/m3_authoring_journey_test.dart
```

Les captures sont produites par de vrais widgets Flutter hors écran, avec les
adaptateurs et projets temporaires générés. Elles ne constituent pas une recette
manuelle de la fenêtre native ou une validation artistique des cartes.

L’audit initial a identifié le thème existant, des cartes sans hiérarchie
d’information et des panneaux/navigation recomposés par écran. L’intégration
conserve les contrôleurs, schémas, moteurs et dépendances. La parité sémantique
API/JSONL/MCP ne nécessite aucune nouvelle action pour cet habillage. Les passages
import → décor/terrain → carte → sauvegarde → runtime et les dialogues/histoires
sont vérifiés par les parcours existants.

Validation du 19 septembre 2026 :

- `flutter test --no-pub --reporter expanded` : **243 réussis, 2 ignorés**.
  Les deux tests ignorés attendent une copie externe explicitement fournie
  (`AVELUNE_PROJECT_COPY` et la capture Train) ; les parcours temporaires M1/M2/M3
  et le stress à 132 atlas sont exécutés.
- `flutter analyze --no-pub` : **No issues found!**
- `flutter build macos --debug --no-pub` : **Built
  build/macos/Build/Products/Debug/Avelune Studio.app**.
- Format ciblé : **79 fichiers, 0 changement**. `git diff --check` est propre.
  Hygiène Markdown : **no new Markdown files**.
- `cd tools/pokemap_mcp && npm test` : reconstruction TypeScript puis
  **82 tests réussis, 0 échec**, incluant les échanges MCP isolés. Le connecteur
  configuré dans la session échoue toujours sur `pokemap_describe` avec
  `worker.exited`, code 78 ; sa disponibilité n’est pas revendiquée.
- Les runners Flutter ont suivi leurs descendants et revérifié leur identité :
  aucun processus résiduel de ces exécutions à terminer. Aucun arrêt global.

La revue indépendante `design_audit` a relevé puis vérifié le contraste, le
calcul de largeur après navigation, le ratio d’atlas et la surface Material.
Verdict final : aucun blocage statique restant. `design_widgets_tests` a ajouté
les tests d’interaction, de contraste et de galerie ; `design_gallery` a livré
le catalogue interactif. La passe principale a intégré les écrans, exécuté les
tests/build et inspecté les captures. La condition de navigation compacte reste
dupliquée entre shell et workspace : réserve de maintenance, sans refactor métier.

État Git observé : 179 entrées modifiées/non suivies au départ, sur `2abaea0a7`.
Pendant le travail, une opération extérieure a avancé HEAD vers `505458f03` et
enregistré une partie des fichiers en cours. Aucune écriture Git n’a été lancée
par cette tâche ou ses sous-agents. L’état final comporte 35 fichiers modifiés/non
suivis, tous dans `apps/avelune_studio`. Aucune modification Notion, dépendance,
configuration native ou projet personnel n’a été effectuée par cette intégration.

## Fonctionnalités M1/M2/M3

Studio ouvre un projet PokeMap, affiche ses cartes et leurs ressources, permet
d’éditer les décors préparés et des tuiles simples, puis d’enregistrer et de tester
la carte dans le runtime existant. M2 ajoute l’import PNG, la préparation de décors
et de terrains automatiques. M3 ajoute les personnages, conversations à choix,
conditions, petites scènes et étapes d’histoire. L’ancien éditeur reste disponible séparément.

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

### Personnages, conversations et histoire

- Dans **Palette → Personnages**, rechercher un personnage préparé, le choisir
  puis cliquer sur la carte. Son sprite réel est affiché. La sélection permet
  déplacement, duplication, nom, orientation et collision de cette instance ;
  ses paramètres avancés restent conservés. Un geste se défait en une fois.
- Dans l’inspecteur, **Interaction → Quand le joueur lui parle → Écrire son
  interaction** ouvre les répliques et leurs locuteurs. Ajouter des suites nommées
  puis des choix permet de construire deux destinations différentes sans saisir
  de code. Les sources avancées non représentables restent en lecture seule.
- **Conditions et répétition** utilise les états booléens du projet. Une variante
  conditionnelle peut remplacer la conversation initiale quand son état convient.
  **Après la conversation** et **Après le choix** proposent dialogue, orientation,
  attente, changement d’état et accomplissement d’une étape, dans l’ordre choisi.
- **Histoire** permet de créer une progression avec ses étapes, rechercher les
  interactions et retrouver leur contexte. L’outil **Dessiner une zone d’histoire**
  crée un rectangle directement sur la carte et ouvre sa conversation d’entrée.
- **Enregistrer l’interaction et la carte** publie un ensemble cohérent par la
  transaction canonique, en conservant les autres changements de la carte.
  Naviguer ou sélectionner ne publie rien. Les brouillons narratifs participent
  à la confirmation de fermeture ; un échec conserve le travail.
- **Enregistrer et tester** utilise le vrai runtime. **Enregistrer le test**,
  **Reprendre le test** et **Nouvelle partie** manipulent une sauvegarde isolée en
  mémoire, conservée jusqu’à la fermeture du projet. Elle ne remplace jamais une
  sauvegarde personnelle ni la progression éditoriale du projet.

Le sous-ensemble narratif visuel couvre les états booléens et ces actions simples.
Les conditions typées complexes, graphes avancés et Character Studio complet ne
sont pas édités ici. L’aperçu auteur utilise la frame immobile réelle ; les
animations et portraits de dialogue restent ceux du runtime. Les captures M3 sont
des widgets Flutter réellement exécutés hors écran. Le pilote natif s’est attaché
à une ancienne fenêtre personnelle : aucun clic n’y a été tenté, et cette couche
de validation reste ouverte. Détails et preuves dans le
[rapport M3](../../documentation/reports/avelune_studio/M3_personnages_histoire/README.md).

### Limites conservées de la carte et des ressources

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
