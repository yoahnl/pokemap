# AVELUNE-UI-01 — Mobile Console Home Experience V0

Date d’exécution : 4 août 2026
Application concernée : `apps/pokemap_hub`
Plateformes : iOS et Android
Verdict : **implémenté et validé sur le périmètre ciblé ; suite globale du Hub toujours rouge sur 26 fixtures v1/v2 préexistantes incompatibles avec le validateur v6**.

## 1. Résumé exécutif

Le lot remplace l’accueil mobile générique du Hub par une expérience Avelune de console virtuelle. L’interface conserve les données, contrôleurs et flows métier existants : bibliothèque installée, import de package, résolution des assets, sauvegarde reprenable, lancement du runtime et paramètres.

Le retour produit formulé pendant l’exécution a été intégré : le bouton principal `CONTINUER` a été supprimé. Un toucher sur la cartouche héro déclenche désormais une insertion animée dans la console, accompagnée d’un retour haptique et d’un clic système lorsque les préférences existantes l’autorisent, puis appelle le vrai flow `Continuer` ou `Jouer`. Un appui long anime uniquement l’illustration, ou son fallback, vers le haut d’un écran de détails. La sélection d’une cartouche de l’étagère produit un échange croisé : l’ancienne descend vers la gauche et la nouvelle remonte depuis la droite.

La contrainte centrale est respectée : `AveluneCartridge` est l’unique moule physique. Le héros, les jeux de l’étagère et `Ajouter un jeu` partagent `kAveluneCartridgeAspectRatio = 0.7`, la même coque, la même zone d’illustration, les mêmes détails moulés et les mêmes connecteurs. Seules l’échelle, la couleur, l’illustration, les textes et l’état varient.

La couleur de coque ne crée aucun nouveau schéma. Elle consomme le champ canonique existant `ProjectBrandingProfile.accentColor`, transporté dans `InstalledGameBranding.accentColor`. Le Hub de personnalisation PokeMap nomme maintenant explicitement cet effet. Le contrat `presentation.update` et le MCP existants restent la source d’autorité.

Sept captures golden documentent les états statiques, l’insertion, l’échange et la fiche de détails. Les builds Android et iOS Simulator réussissent. Les analyses Flutter du Hub et de l’éditeur ne remontent aucune anomalie. La suite ciblée finale passe 50 tests. La suite complète du Hub termine à `+199 -26` : les 26 échecs sont reproduits dans des fixtures hors diff, dont 24 `invalidProject` et 2 `smart_tile_v6_project_required` ; le `HEAD` exige déjà `v6` alors que sa fixture runtime déclare encore `v1`.

## 2. Gate 0 exact

Les commandes suivantes ont été exécutées depuis la racine avant toute modification.

### `pwd`

```text
/Users/karim/Project/pokemonProject
```

### `git branch --show-current`

```text
main
```

### `git status --short --untracked-files=all`

```text
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/models/map_layer.dart
 M packages/map_core/lib/src/models/map_layer.freezed.dart
 M packages/map_core/lib/src/models/map_layer.g.dart
 M packages/map_core/lib/src/operations/map_visual_composition.dart
 M packages/map_core/lib/src/operations/tiled_map_compilation.dart
 M packages/map_core/lib/src/validation/validators.dart
 M packages/map_core/test/fixtures/map_visual_stack/monochrome_parity_v1.json
 M packages/map_core/test/smart_tiles/tiled_map_compilation_test.dart
 M packages/map_core/test/smart_tiles/tiled_map_local_corpus_test.dart
 M packages/map_editor/lib/src/features/border_map_editing/presentation/editor_map_layer_paint_order.dart
 M packages/map_editor/lib/src/features/editor/application/map_canvas_object_hit_test.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/editor_canvas_animation_need_resolver.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
 M packages/map_editor/test/border_map_editing/editor_map_layer_paint_order_test.dart
 M packages/map_editor/test/map_grid_painter_test.dart
 M packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart
 M packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
 M packages/map_runtime/test/project_tileset_visual_resolution_test.dart
 M packages/map_runtime/test/runtime_manifest_tilesets_smart_tile_test.dart
?? documentation/reports/editor/smart_tiles_tiled_imports_and_performance_audit_2026-08-04.md
?? packages/map_core/lib/src/operations/map_placed_tile_visual_resolver.dart
?? packages/map_core/test/map_placed_tile_visual_resolver_test.dart
```

### `git diff --stat`

```text
 packages/map_core/lib/map_core.dart                |   1 +
 packages/map_core/lib/src/models/map_layer.dart    |  30 ++
 .../map_core/lib/src/models/map_layer.freezed.dart | 534 +++++++++++++++++++--
 packages/map_core/lib/src/models/map_layer.g.dart  |  39 ++
 .../lib/src/operations/map_visual_composition.dart |   6 +-
 .../lib/src/operations/tiled_map_compilation.dart  | 248 ++++++++--
 .../map_core/lib/src/validation/validators.dart    |  56 ++-
 .../map_visual_stack/monochrome_parity_v1.json     |   4 +-
 .../smart_tiles/tiled_map_compilation_test.dart    | 121 ++++-
 .../smart_tiles/tiled_map_local_corpus_test.dart   |  20 +-
 .../presentation/editor_map_layer_paint_order.dart |   6 +-
 .../application/map_canvas_object_hit_test.dart    |   2 +-
 .../map_editor/lib/src/ui/canvas/map_canvas.dart   |  58 +--
 .../editor_canvas_animation_need_resolver.dart     |  29 ++
 .../src/ui/canvas/map_canvas/map_grid_painter.dart |  68 ++-
 .../editor_map_layer_paint_order_test.dart         |   2 +-
 .../map_editor/test/map_grid_painter_test.dart     | 147 ++++++
 .../src/application/runtime_manifest_tilesets.dart |   5 +
 .../presentation/flame/map_layers_component.dart   |  70 ++-
 .../project_tileset_visual_resolution_test.dart    |  58 +++
 .../runtime_manifest_tilesets_smart_tile_test.dart |  30 ++
 21 files changed, 1407 insertions(+), 127 deletions(-)
```

### `git diff --name-only`

```text
packages/map_core/lib/map_core.dart
packages/map_core/lib/src/models/map_layer.dart
packages/map_core/lib/src/models/map_layer.freezed.dart
packages/map_core/lib/src/models/map_layer.g.dart
packages/map_core/lib/src/operations/map_visual_composition.dart
packages/map_core/lib/src/operations/tiled_map_compilation.dart
packages/map_core/lib/src/validation/validators.dart
packages/map_core/test/fixtures/map_visual_stack/monochrome_parity_v1.json
packages/map_core/test/smart_tiles/tiled_map_compilation_test.dart
packages/map_core/test/smart_tiles/tiled_map_local_corpus_test.dart
packages/map_editor/lib/src/features/border_map_editing/presentation/editor_map_layer_paint_order.dart
packages/map_editor/lib/src/features/editor/application/map_canvas_object_hit_test.dart
packages/map_editor/lib/src/ui/canvas/map_canvas.dart
packages/map_editor/lib/src/ui/canvas/map_canvas/editor_canvas_animation_need_resolver.dart
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
packages/map_editor/test/border_map_editing/editor_map_layer_paint_order_test.dart
packages/map_editor/test/map_grid_painter_test.dart
packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/test/project_tileset_visual_resolution_test.dart
packages/map_runtime/test/runtime_manifest_tilesets_smart_tile_test.dart
```

### `git log --oneline -n 10`

```text
4ebf11e05 feat(tiled): compile tmx layers to map data
21e51a028 feat(tiled): add bounded tmx parser
5ad0b430c feat(tile-layers): add canonical multi-tileset palette
98b615f39 feat(tilesets): import tiled image collections
1d5c5709c feat(tilesets): share visual resolution
d829f5646 fix(map-core): preserve tiled atlas geometry
8af0185b9 feat(authoring): pack tiled image collections
84b760bcb feat(map-core): parse tiled image collections
459a9ea92 feat(map-core): model image collection tilesets
27408ea3e feat(smart-tiles): unify tiled import transports
```

## 3. État initial du worktree

Le worktree était sale avant AVELUNE-UI-01. Les 21 modifications suivies et les trois fichiers non suivis du Gate 0 concernaient le chantier Smart Tiles / rendu de couches. Ils ont été traités comme préexistants et n’ont jamais été modifiés par ce lot.

Le worktree a évolué concurremment pendant l’exécution : plusieurs changements Smart Tiles initiaux ont disparu, puis d’autres fichiers d’auteur/runtime sont apparus. Aucun nettoyage Git, restauration, stash, checkout ou commit n’a été exécuté. Le rapport les qualifie de changements externes concurrents et les conserve tels quels.

Une conséquence générée par `npm test` dans `examples/playable_runtime_host/macos/Flutter/GeneratedPluginRegistrant.swift` a été identifiée immédiatement : deux lignes `package_info_plus` avaient été ajoutées automatiquement. Elles ont été retirées avec `apply_patch` afin de ne laisser aucune modification hors lot provoquée par la validation.

## 4. Audit de l’architecture Avelune

| Question obligatoire | Réponse auditée |
|---|---|
| 1. Package contenant Avelune | `apps/pokemap_hub`. La composition publique injecte déjà le nom Avelune sur iOS et Android. |
| 2. Accueil utilisé avant le lot | `HubShell`, puis `_HubHome` pour `HubSection.home`; `_HubLibrary` pour la bibliothèque. Le lot ne remplace ces surfaces que lorsque `mobileConsoleExperience` vaut `true`. |
| 3. Routeur/navigation | Aucun routeur déclaratif global. `PokeMapHubApp` choisit Hub ou player par état; `HubDashboardController.selectSection` pilote `HubShell`; `Navigator.push` est employé localement pour la fiche Avelune. |
| 4. Système d’état | `HubDashboardController extends ChangeNotifier`, consommé avec `ListenableBuilder`; états locaux Flutter pour sélection et animations. |
| 5. Liste des jeux installés | `GameLibraryStore`, relu par `HubDashboardController._reload`, projeté en `HubDashboardSnapshot.games`. |
| 6. Dernière sauvegarde | `InstalledHubGameActivityReader` vérifie l’installation, ouvre `HubSaveStore` et appelle `findContinue()`. Il renseigne `canContinue`, `lastSaveAt` et `playTimeSeconds`. |
| 7. Activité récente | Il n’existe pas d’historique événementiel multi-sauvegardes. La meilleure source réelle est le dernier `HubGameActivity.lastSaveAt` de chaque jeu, trié localement sans persistance nouvelle. |
| 8. Flow d’import | `HubPlatformAdapter.pickPackage` → `HubComposition._importExternalPackage` → `HubDashboardController.importPackage` → `GamePackageInstaller.install`. Les extensions existantes `.avelunegame` et `.pokemapgame` sont conservées. |
| 9. Flow de lancement/reprise | `PokeMapHubApp` → `HubInstalledGamePlayer` → `InstalledGameLaunchResolver` → `RuntimePlayerCoordinator`. La reprise envoie désormais l’intention explicite `continueGame` au coordinateur après initialisation. |
| 10. Assets Avelune existants | Vidéos d’introduction de certification et jeux d’icônes natifs iOS/macOS. Aucun décor ou artwork de console destiné à l’accueil. |
| 11. Logo final exploitable | Pas de logo autonome/vectoriel. L’icône iOS Avelune 180 px existante est réutilisée temporairement; la capture de référence n’est pas extraite. |
| 12. Thème/design system Avelune | Le projet possédait `PokeMapPlayerTheme`; aucune extension Avelune dédiée. Le lot ajoute une `ThemeExtension<AveluneColors>` isolée au runtime. |
| 13. Composants conservés | Contrôleur, snapshot, bibliothèque, activités, import, progression d’installation, erreurs, préférences, diagnostics, player, résolution des artworks et navigation desktop. |
| 14. Composants remplacés | Uniquement l’accueil et la barre de navigation en composition mobile Avelune. L’accueil desktop reste inchangé. |
| 15. Couleur de coque par jeu | Oui, via `ProjectBrandingProfile.accentColor` puis `InstalledGameBranding.accentColor`; aucun nouveau modèle persistant requis. |
| 16. Cover par jeu | Oui, optionnelle : `cover`, puis `hero`, puis `icon`, résolus vers `HubGameActivity.coverPath/heroPath/iconPath`. |
| 17. Sans jeu | Console vide, libellé explicite, vraie action d’import et emplacement Ajouter au ratio canonique. |
| 18. Sans sauvegarde | Cartouche du jeu sélectionné, geste `Insérer pour jouer`, aucune date inventée, activité récente vide. |
| 19. Branchement du moule canonique | Feature UI `lib/src/ui/avelune/avelune_cartridge.dart`, consommée par le héros, l’étagère et l’emplacement Ajouter. |
| 20. Risques empêchant une copie littérale | Logo autonome absent; covers optionnelles; pas d’historique de sauvegarde riche; pas d’avatar/profil local réel; fixtures package v1/v2 incompatibles avec le validateur v6 actuel. |

## 5. Audit des données et flows existants

### Bibliothèque et sélection

`AveluneMobileHome` reçoit exclusivement `HubDashboardSnapshot`. La sélection initiale privilégie la sauvegarde la plus récente, puis la date d’installation. Les listes de jeux ne sont ni bornées ni codées en dur. L’étagère est une `ListView.separated` horizontale lazy.

### Covers et branding

`InstalledHubGameActivityReader` résout les références du manifeste uniquement après validation de l’installation. `aveluneArtworkFor` utilise `coverPath ?? heroPath ?? iconPath`. En l’absence d’image ou en cas d’erreur de lecture, un fallback local est montré sans faire tomber l’accueil.

`aveluneShellColorFor` décode `InstalledGameBranding.accentColor`, la mélange légèrement avec la teinte de coque neutre pour préserver la lisibilité du plastique, puis fournit exactement la même couleur au héros et à l’étagère.

### Sauvegarde et reprise

La section récente projette une entrée par jeu ayant un `lastSaveAt`. Elle ne prétend pas connaître le type automatique/manuelle, car le read model existant ne le fournit pas. Le libellé honnête est `Dernière sauvegarde`.

Le toucher de la cartouche appelle `HubUiActions.onContinue` seulement si `canContinue`; sinon `onNewGame`. `HubPlayerLaunchIntent.continueGame` saute l’introduction, initialise le vrai coordinateur et lui transmet `RuntimePlayerAction.continueGame` avec la révision du snapshot. Un refus devient une erreur réelle du player; aucune réussite n’est simulée.

### Import et paramètres

Les deux accès Ajouter déclenchent le sélecteur et l’installeur existants. `Paramètres` ouvre la surface de préférences existante. Aucun profil fictif n’existant, aucun avatar ou état en ligne n’est inventé.

### Parité d’auteur PokeMap

La demande de couleur ne justifie pas un champ `cartridgeColor` concurrent. `accentColor` est déjà éditable, sérialisé, empaqueté et exposé par `presentation.update`. Les libellés de `ProjectBrandingEditor` et `PersonalizationStudioWorkspace` explicitent maintenant la consommation par la coque Avelune. Le test direct `map_authoring`, le check TypeScript, le build et les 32 tests MCP sont verts.

## 6. Analyse de l’image de référence

La référence impose une lecture verticale nette : marque, cartouche, console, action, étagère, activité, navigation. Elle utilise un fond noir sans pièce, un halo violet localisé, une console frontale symétrique, du plastique moulé, des connecteurs dorés et un bois brun sombre.

La première comparaison jointe référence/implémentation a montré une composition juste mais des matériaux trop plats. Une seconde passe a ajouté, sans image de fond ni moteur 3D :

- reliefs et doubles bords moulés des cartouches;
- rails latéraux, vis et reflets de l’étiquette;
- connecteurs dorés en dégradé;
- chanfreins, joints verticaux, plaque frontale, ports et fente lumineuse de la console;
- tablette avec highlight chaud et profondeur;
- espace réel entre connecteurs et console à l’état de repos.

La comparaison finale a été effectuée dans une image côte à côte unique à la même hauteur : référence jointe à gauche, golden `home_390x844.png` à droite. La capture de référence n’est jamais devenue un asset du produit.

## 7. Décisions UI/UX

- Mobile seulement : le desktop conserve le Hub actuel.
- Aucun gros bouton Continuer en état normal.
- Le geste primaire est l’objet lui-même : toucher la cartouche l’insère.
- Un hint compact sous la tablette explique `Insérer pour continuer` ou `Insérer pour jouer`.
- Appui long : route de détails avec Hero limité à l’artwork/fallback, pas à toute la cartouche.
- Échange : ancienne cartouche vers bas-gauche, nouvelle depuis bas-droite, sans rotation ni physique fragile.
- Console frontale purement décorative; aucun D-pad, A/B ou joystick.
- Deux destinations seulement : Accueil et Paramètres.
- Import accessible par l’étagère et par l’icône compacte du header; aucun accès Paramètres dupliqué.
- Aucun état social, succès, boutique, découverte ou présence en ligne.

## 8. Contrat du format canonique de cartouche

Source de vérité :

```dart
const double kAveluneCartridgeAspectRatio = 0.7;
```

Invariants :

1. Une seule classe publique : `AveluneCartridge`.
2. Deux tailles d’affichage seulement : `hero` et `shelf`; aucune variante horizontale.
3. `AspectRatio` interne toujours alimenté par `kAveluneCartridgeAspectRatio`.
4. L’étagère calcule aussi sa hauteur avec cette constante.
5. `AveluneCartridge.addGame` passe dans la même méthode `build`, donc possède coque, bandeau, cover, détails moulés et connecteurs identiques.
6. Tous les jeux de l’étagère reçoivent la même largeur calculée et donc la même hauteur.
7. Les titres sont bornés à deux lignes et ellipsés; le contenu ne redimensionne jamais la coque.
8. Aucune rotation n’apparaît dans la feature Avelune.

## 9. Architecture des composants

| Composant | Responsabilité |
|---|---|
| `AveluneMobileHome` | Composition scrollable, sélection locale, vraies actions et états. |
| `AveluneHeader` | Logo existant, nom produit, import compact. |
| `AveluneHeroConsoleSection` | Flottement, échange, insertion, haptique/clic et sémantique du geste. |
| `AveluneCartridge` | Moule physique canonique unique. |
| `AveluneConsole` / `AveluneConsoleDock` | Console frontale, slot réactif et tablette bois. |
| `AveluneGameShelf` | Liste lazy et uniforme, y compris Ajouter. |
| `AveluneRecentActivitySection` | Projection des dernières sauvegardes réelles. |
| `AveluneGameDetailsScreen` | Destination Hero et métadonnées réelles. |
| `AveluneBottomNavigation` | Accueil / Paramètres uniquement. |
| `AveluneColors` | Tokens de couleur et matériaux centralisés. |
| `HubPlayerLaunchIntent` | Distingue titre et reprise réelle sans contourner le runtime. |

## 10. Fichiers créés

| Chemin | Zones principales | Raison / impact |
|---|---|---|
| `apps/pokemap_hub/lib/src/ui/avelune/avelune_cartridge.dart` | ratio, enum de taille, coque, label, connecteurs | Moule physique unique. |
| `apps/pokemap_hub/lib/src/ui/avelune/avelune_console.dart` | console, dock, ports | Objet console frontal et slot réactif. |
| `apps/pokemap_hub/lib/src/ui/avelune/avelune_game_details.dart` | SliverAppBar Hero, détails | Fiche sur appui long. |
| `apps/pokemap_hub/lib/src/ui/avelune/avelune_game_presentation.dart` | artwork, couleur, temps relatif | Read helpers partagés sans persistance. |
| `apps/pokemap_hub/lib/src/ui/avelune/avelune_mobile_home.dart` | accueil, animations, étagère, activité | Expérience console mobile complète. |
| `apps/pokemap_hub/lib/src/ui/avelune/avelune_navigation.dart` | destinations mobile | Navigation minimale. |
| `apps/pokemap_hub/lib/src/ui/avelune/avelune_theme.dart` | `AveluneColors` | Centralisation palette/matériaux. |
| `apps/pokemap_hub/lib/src/ui/player/hub_player_launch_intent.dart` | enum, dispatch | Reprise explicite dans le vrai runtime. |
| `apps/pokemap_hub/test/ui/avelune_cartridge_test.dart` | ratio, structure, tailles, sémantique | Preuve du moule unique. |
| `apps/pokemap_hub/test/ui/avelune_mobile_home_test.dart` | états, gestes, responsive | Preuve fonctionnelle et accessibilité. |
| `apps/pokemap_hub/test/ui/avelune_mobile_home_golden_test.dart` | 7 scénarios golden | Visual Gate reproductible. |
| `apps/pokemap_hub/test/ui/player/hub_initial_launch_intent_test.dart` | dispatch reprise/titre | Garde-fou runtime. |
| `apps/pokemap_hub/test/ui/goldens/avelune/*.png` | 7 PNG | Captures du Visual Gate. |
| `documentation/reports/avelune/avelune_ui_01_mobile_console_home_experience.md` | présent document | Rapport consolidé et Evidence Pack. |

## 11. Fichiers modifiés

| Chemin | Zones modifiées | Raison / impact |
|---|---|---|
| `apps/pokemap_hub/lib/pokemap_hub_ui.dart` | exports Avelune et launch intent | API UI interne accessible aux tests/composition. |
| `apps/pokemap_hub/lib/src/platform/hub_composition.dart` | `buildApp`, player builder | Active l’expérience sur iOS/Android et transmet l’intention. |
| `apps/pokemap_hub/lib/src/ui/hub_app.dart` | builder, actions, thème | Sépare Jouer et Continuer; applique les tokens Avelune. |
| `apps/pokemap_hub/lib/src/ui/hub_game_views.dart` | `decodeHubAccentColor` public | Réutilise le décodage existant sans duplication. |
| `apps/pokemap_hub/lib/src/ui/hub_shell.dart` | composition responsive mobile | Route mobile vers accueil/nav Avelune, desktop intact. |
| `apps/pokemap_hub/lib/src/ui/player/hub_installed_game_player.dart` | initialisation du player | Saute l’intro et dispatche la reprise réelle. |
| `apps/pokemap_hub/pubspec.yaml` | assets | Déclare l’icône Avelune existante utilisée au header. |
| `apps/pokemap_hub/test/ui/hub_app_player_navigation_test.dart` | signature builder, reprise mobile | Prouve l’intention `continueGame`. |
| `apps/pokemap_hub/integration_test/runtime_owned_player_flow_test.dart` | signature builder | Maintient la compilation du test d’intégration. |
| `packages/map_editor/lib/src/features/personalization/presentation/project_branding_editor.dart` | textes accent | Rend l’effet sur la coque explicite. |
| `packages/map_editor/lib/src/features/personalization/presentation/personalization_studio_workspace.dart` | dialogue et undo | Nomme la couleur cartouche + accent sans changer le modèle. |
| `packages/map_editor/test/personalization/project_branding_editor_test.dart` | attentes de libellés | Garde-fou de découvrabilité. |

## 12. Interactions implémentées

### Toucher la cartouche héro

1. Verrouillage anti-double lancement.
2. Arrêt du flottement.
3. Descente `easeInCubic` vers 72 % de l’insertion.
4. Haptique `mediumImpact` si activée et clic système si volumes master/effets non nuls.
5. Petit enclenchement final `easeOutCubic`.
6. Appel du vrai `onContinue` ou `onNewGame`.
7. Retour visuel seulement si l’appelant ne change pas de surface.

### Appui long

La zone d’artwork/fallback porte un tag Hero stable par `gameId`. Elle monte vers un `SliverAppBar` de détails. Le titre, l’auteur, la description, la version, la dernière activité, le temps de jeu et l’état proviennent des modèles réels.

### Sélection sur l’étagère

`AnimatedSwitcher` conserve brièvement les deux cartouches. Le test vérifie explicitement un `dx > 0` pour l’entrante et un `dx < 0` pour la sortante. Aucune rotation ou variante physique n’est créée.

### Activité récente

Un toucher sélectionne le jeu et appelle la reprise uniquement si l’installation est saine et la sauvegarde reprenable.

## 13. États vides et erreurs

- **0 jeu** : console prête sans cartouche fictive, grande action Ajouter, étagère avec emplacement canonique, activité vide.
- **Jeu sans sauvegarde** : `Insérer pour jouer`, aucun faux timestamp.
- **Jeu avec sauvegarde** : `Insérer pour continuer`, date relative réelle.
- **Jeu invalide** : sélection possible, label `JEU INDISPONIBLE`, explication fichiers manquants, lancement impossible.
- **Import en cours** : `HubInstallProgressScreen` existant reste superposé à la composition.
- **Assets manquants** : fallback visuel local; aucune exception de rendu ne détruit l’accueil.
- **Beaucoup de jeux** : liste horizontale lazy, largeur stable.
- **Activité vide** : texte explicite sans repository fictif.

## 14. Responsive design

Le corps est un `CustomScrollView` sous `SliverSafeArea`. Les largeurs héro/console/étagère viennent de `LayoutBuilder`, avec bornes min/max. L’étagère défile horizontalement au lieu d’écraser les cartouches. La navigation conserve la safe area gestuelle.

Les tests couvrent `320×568`, `375×667`, `390×844` et `430×932` avec `TextScaler.linear(1.3)`. Aucun overflow ou texte hors limite n’est remonté. Sur le petit écran, l’étagère reste volontairement partielle et scrollable.

## 15. Accessibilité

- `Semantics` nomme chaque jeu et annonce sélection/indisponibilité.
- La cartouche héro annonce le geste d’insertion et l’appui long.
- Les cibles reposent sur `InkWell` et dépassent 44–48 dp.
- L’état invalide combine icône, texte et couleur.
- Les ports et détails décoratifs de console sont exclus de l’arbre sémantique.
- `MediaQuery.disableAnimations` et la préférence `reducedMotion` désactivent flottement/échange et raccourcissent l’insertion.
- La préférence `highContrast` sélectionne des tokens Avelune renforcés pour les textes secondaires, les contours, le violet actif et les erreurs.
- Une `AnnotatedRegion<SystemUiOverlayStyle>` maintient des icônes système claires et une zone de navigation noire, même si la préférence générale utilise le thème clair.
- Un test vérifie l’absence de frame programmée après quatre secondes en réduction des animations.

## 16. Animations

| Animation | Durée | Courbe / garde-fou |
|---|---:|---|
| Flottement héro | 2800 ms aller-retour | 2–6 px, aucune rotation, désactivé en reduced motion. |
| Insertion principale | 360 ms + 160 ms | `easeInCubic`, puis `easeOutCubic`; feedback au point de contact. |
| Retour local | 260 ms | Ne survient que si la surface reste montée. |
| Échange de jeux | 440 ms | translation croisée, fondu et scale 0.90→1; zéro en reduced motion. |
| Route de détails | 420 ms | Hero artwork + fade/slide léger. |

## 17. Performances

- `RepaintBoundary` autour des cartouches, de la console et des captures.
- Aucun blur plein écran, shader complexe ou particule.
- Animation localisée à la section héro.
- `ListView.separated` lazy pour l’étagère.
- Covers résolues en chemins puis chargées par `FileImage`, avec le cache Flutter standard.
- Logo précaché dans les goldens; asset 180 px plutôt que 1024 px.
- Aucun accès disque dans `build`; la résolution est faite par le reader existant.
- Tous les objets coûteux restent décoratifs statiques, sans `CustomPainter` continuellement repeint.

## 18. Tests exécutés

### Suite ciblée finale Avelune / plateforme / shell

Commande :

```text
cd apps/pokemap_hub
flutter test --no-pub -r expanded test/platform/ios_distribution_contract_test.dart test/platform/public_product_identity_test.dart test/release/mobile_platform_release_gate_test.dart test/ui/avelune_cartridge_test.dart test/ui/avelune_mobile_home_golden_test.dart test/ui/avelune_mobile_home_test.dart test/ui/hub_app_player_navigation_test.dart test/ui/hub_display_preferences_ui_test.dart test/ui/hub_shell_test.dart test/ui/player/hub_initial_launch_intent_test.dart
```

Résultat exact final :

```text
00:04 +50: All tests passed!
```

### Gestes et états Avelune isolés

```text
00:00 +0: empty Avelune home exposes the real import action
00:00 +1: selecting a shelf cartridge exchanges the hero before launch
00:01 +2: Continue and recent activity use existing latest-save data
00:01 +3: invalid games stay selectable but cannot claim a launch
00:01 +4: mobile navigation contains only Home and Settings
00:01 +5: personalization accent colors the canonical cartridge shell
00:01 +6: hero insertion remains accessible with reduced motion
00:01 +7: long press opens real game details through artwork Hero
00:01 +8: console home stays scrollable at 320.0x568.0
00:01 +9: console home stays scrollable at 375.0x667.0
00:02 +10: console home stays scrollable at 390.0x844.0
00:02 +11: console home stays scrollable at 430.0x932.0
00:02 +12: All tests passed!
```

### Éditeur de personnalisation

Commande :

```text
cd packages/map_editor
flutter test --no-pub test/personalization/project_branding_editor_test.dart -r expanded
```

Résultat exact :

```text
00:00 +0: offers guided image controls for icon, cover, and hero
00:00 +1: edits accent and title layout through guided controls
00:00 +2: imports, previews, and removes title music
00:00 +3: All tests passed!
```

### API d’auteur directe

Commande :

```text
cd packages/map_authoring
dart test test/domains/assets/presentation_authoring_test.dart -r expanded
```

Résultat exact :

```text
00:00 +0: presentation authoring validates every media reference against the canonical asset catalog
00:00 +1: presentation authoring editor adapter and mutation gate share the same projected state
00:00 +2: presentation authoring preview handles are revision-bound and reject stale consumption
00:00 +3: presentation authoring media processing jobs are asynchronous and idempotent
00:00 +4: presentation authoring dispatcher exposes canonical presentation mutations
00:00 +5: All tests passed!
```

### MCP

`npm run check` :

```text
> @pokemap/mcp-server@0.1.0 check
> tsc -p tsconfig.json --noEmit
```

`npm test` :

```text
ℹ tests 32
ℹ suites 0
ℹ pass 32
ℹ fail 0
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 59246.61625
```

Le catalogue MCP live avait également été interrogé : `pokemap_describe` répond `ok: true`, expose 12 `resourceKinds` et inclut les mutations `presentation.update` / `presentation.delete`.

### Suite complète du Hub

Commande :

```text
cd apps/pokemap_hub
flutter test --no-pub -r expanded
```

Résultat exact synthétique :

```text
TEST_EXIT=1
INVALID_PROJECT_OCCURRENCES=24
SMART_TILE_V6_OCCURRENCES=2
00:45 +199 -26: Some tests failed.
```

Répartition exacte des 26 tests :

```text
1 ui/player/phase_6_personalization_packaging_e2e_test.dart
3 install/game_install_recovery_test.dart
5 install/game_maintenance_service_test.dart
10 install/game_package_installer_test.dart
2 install/installed_game_verifier_concurrency_test.dart
1 library/game_library_store_test.dart
2 support/runtime_owned_player_package_fixture_test.dart
2 session/installed_game_launch_resolver_test.dart
```

Preuve de préexistence au `HEAD` :

```text
packages/map_core/lib/src/models/project_manifest.dart:492:  if (version != 'v6') {
packages/map_core/lib/src/models/project_manifest.dart:494:      r'$.version: smart_tile_v6_project_required '
apps/pokemap_hub/test/support/runtime_owned_player_package_fixture.dart:15:  "version": "v1",
apps/pokemap_hub/test/support/runtime_owned_player_package_fixture.dart:406:  "version": "v1",
```

`git diff --name-only` ne retourne aucun des fichiers de ces huit groupes de tests ni `project_manifest.dart`.

### Test d’intégration macOS

Commande :

```text
flutter test --no-pub integration_test/runtime_owned_player_flow_test.dart -d macos -r expanded
```

Résultat exact utile :

```text
✓ Built build/macos/Build/Products/Debug/PokeMap Hub.app
GamePackageFormatException(invalidProject at project/project.json): Project manifest failed its pure validation preflight.
00:01 +0 -1: Some tests failed.
```

Le test compile donc la nouvelle signature du player, puis échoue avant le parcours UI lors de la construction de sa fixture v1/v2.

## 19. Résultats exacts d’analyse et de build

### Hub

```text
Analyzing pokemap_hub...
No issues found! (ran in 3.8s)
```

### Éditeur

```text
Analyzing map_editor...
No issues found! (ran in 8.8s)
```

### Android

```text
Running Gradle task 'assembleDebug'...                             13.3s
✓ Built build/app/outputs/flutter-apk/app-debug.apk
```

### iOS Simulator

```text
Building com.yoahnl.avelune.player for simulator (ios)...
Running Xcode build...
Xcode build done.                                           13.5s
✓ Built build/ios/iphonesimulator/Runner.app
```

## 20. Visual Gate

Le Visual Gate contrôle explicitement :

- cartouche principale droite, verticale et frontale;
- ratio unique visible pour héros, étagère et Ajouter;
- tailles strictement uniformes sur l’étagère;
- console frontale sans contrôles Game Boy;
- fond supérieur noir sans décor de pièce;
- bois visible sous console et bibliothèque;
- hiérarchie geste d’insertion → Mes jeux → Activité récente;
- navigation Accueil / Paramètres seulement;
- contraste ivoire, violet et or;
- insertion avec connecteurs masqués dans la console;
- échange montrant les deux cartouches et le changement de coque;
- Hero de l’artwork/fallback vers le haut de la fiche.

Comparaison finale avec la référence : la composition, les proportions relatives et le langage console/étagère sont reconnaissables. La version implémentée est volontairement plus lisible et moins photographique; elle emploie de vrais widgets, des données réelles et des matériaux stylisés. Les artworks riches de la référence ne sont pas reproduits dans les fixtures golden, afin de tester également le fallback demandé. En production, les covers installées sont affichées.

## 21. Screenshots produits

| Chemin | Dimensions | État |
|---|---:|---|
| `apps/pokemap_hub/test/ui/goldens/avelune/home_390x844.png` | 390×844 | Plusieurs jeux, sauvegardes, accueil standard. |
| `apps/pokemap_hub/test/ui/goldens/avelune/home_320x568.png` | 320×568 | Petit mobile scrollable. |
| `apps/pokemap_hub/test/ui/goldens/avelune/empty_390x844.png` | 390×844 | Aucun jeu. |
| `apps/pokemap_hub/test/ui/goldens/avelune/no_save_430x932.png` | 430×932 | Jeux sans sauvegarde. |
| `apps/pokemap_hub/test/ui/goldens/avelune/inserting_390x844.png` | 390×844 | Cartouche engagée dans la console. |
| `apps/pokemap_hub/test/ui/goldens/avelune/exchange_390x844.png` | 390×844 | Échange croisé violet → bleu pétrole. |
| `apps/pokemap_hub/test/ui/goldens/avelune/details_390x844.png` | 390×844 | Destination Hero et détails. |

Comparaisons temporaires de QA, hors dépôt et hors production :

```text
/tmp/avelune_reference_comparison_before.png
/tmp/avelune_reference_comparison_after_materials.png
```

## 22. Diff stat

Le diff stat final exact sera reproduit dans l’Evidence Pack final ci-dessous.

<!-- FINAL_DIFF_STAT_START -->
```text
 .../runtime_owned_player_flow_test.dart            |   4 +-
 apps/pokemap_hub/lib/pokemap_hub_ui.dart           |   8 ++
 .../lib/src/platform/hub_composition.dart          |   4 +-
 apps/pokemap_hub/lib/src/ui/hub_app.dart           |  65 ++++++++---
 apps/pokemap_hub/lib/src/ui/hub_game_views.dart    |   8 +-
 apps/pokemap_hub/lib/src/ui/hub_shell.dart         | 129 +++++++++++++--------
 .../src/ui/player/hub_installed_game_player.dart   |  18 ++-
 apps/pokemap_hub/pubspec.yaml                      |   1 +
 .../test/ui/hub_app_player_navigation_test.dart    |  79 ++++++++++++-
 .../macos/Flutter/GeneratedPluginRegistrant.swift  |   2 +
 .../lib/src/domains/assets/tileset_actions.dart    |  10 +-
 .../assets/visual_library_contract_test.dart       |  52 +++++++++
 .../project_tileset_visual_resolver.dart           |   6 +-
 .../map_core/lib/src/validation/validators.dart    |   6 +-
 .../map_core/test/project_tileset_source_test.dart |   6 +-
 .../test/project_tileset_visual_resolver_test.dart |   2 +-
 .../application/tiled_map_import_service.dart      |  85 +++++++++++++-
 .../personalization_studio_workspace.dart          |   6 +-
 .../presentation/project_branding_editor.dart      |  10 +-
 .../application/tiled_map_import_service_test.dart |  54 +++++++++
 .../project_branding_editor_test.dart              |   5 +
 .../src/application/load_runtime_map_bundle.dart   |  50 +++++++-
 22 files changed, 516 insertions(+), 94 deletions(-)
```
<!-- FINAL_DIFF_STAT_END -->

`git diff --stat` ne compte pas les nouveaux fichiers non suivis; leur inventaire exhaustif figure dans le status ci-dessous. Les lignes auteur/Smart Tiles du stat sont des changements externes concurrents, pas AVELUNE-UI-01.

## 23. Git status final exact

Le status inclut le présent rapport, tous les nouveaux fichiers du lot et les changements externes concurrents conservés.

<!-- FINAL_STATUS_START -->
```text
 M apps/pokemap_hub/integration_test/runtime_owned_player_flow_test.dart
 M apps/pokemap_hub/lib/pokemap_hub_ui.dart
 M apps/pokemap_hub/lib/src/platform/hub_composition.dart
 M apps/pokemap_hub/lib/src/ui/hub_app.dart
 M apps/pokemap_hub/lib/src/ui/hub_game_views.dart
 M apps/pokemap_hub/lib/src/ui/hub_shell.dart
 M apps/pokemap_hub/lib/src/ui/player/hub_installed_game_player.dart
 M apps/pokemap_hub/pubspec.yaml
 M apps/pokemap_hub/test/ui/hub_app_player_navigation_test.dart
 M examples/playable_runtime_host/macos/Flutter/GeneratedPluginRegistrant.swift
 M packages/map_authoring/lib/src/domains/assets/tileset_actions.dart
 M packages/map_authoring/test/domains/assets/visual_library_contract_test.dart
 M packages/map_core/lib/src/operations/project_tileset_visual_resolver.dart
 M packages/map_core/lib/src/validation/validators.dart
 M packages/map_core/test/project_tileset_source_test.dart
 M packages/map_core/test/project_tileset_visual_resolver_test.dart
 M packages/map_editor/lib/src/features/editor/application/tiled_map_import_service.dart
 M packages/map_editor/lib/src/features/personalization/presentation/personalization_studio_workspace.dart
 M packages/map_editor/lib/src/features/personalization/presentation/project_branding_editor.dart
 M packages/map_editor/test/features/editor/application/tiled_map_import_service_test.dart
 M packages/map_editor/test/personalization/project_branding_editor_test.dart
 M packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
?? apps/pokemap_hub/lib/src/ui/avelune/avelune_cartridge.dart
?? apps/pokemap_hub/lib/src/ui/avelune/avelune_console.dart
?? apps/pokemap_hub/lib/src/ui/avelune/avelune_game_details.dart
?? apps/pokemap_hub/lib/src/ui/avelune/avelune_game_presentation.dart
?? apps/pokemap_hub/lib/src/ui/avelune/avelune_mobile_home.dart
?? apps/pokemap_hub/lib/src/ui/avelune/avelune_navigation.dart
?? apps/pokemap_hub/lib/src/ui/avelune/avelune_theme.dart
?? apps/pokemap_hub/lib/src/ui/player/hub_player_launch_intent.dart
?? apps/pokemap_hub/test/ui/avelune_cartridge_test.dart
?? apps/pokemap_hub/test/ui/avelune_mobile_home_golden_test.dart
?? apps/pokemap_hub/test/ui/avelune_mobile_home_test.dart
?? apps/pokemap_hub/test/ui/goldens/avelune/details_390x844.png
?? apps/pokemap_hub/test/ui/goldens/avelune/empty_390x844.png
?? apps/pokemap_hub/test/ui/goldens/avelune/exchange_390x844.png
?? apps/pokemap_hub/test/ui/goldens/avelune/home_320x568.png
?? apps/pokemap_hub/test/ui/goldens/avelune/home_390x844.png
?? apps/pokemap_hub/test/ui/goldens/avelune/inserting_390x844.png
?? apps/pokemap_hub/test/ui/goldens/avelune/no_save_430x932.png
?? apps/pokemap_hub/test/ui/player/hub_initial_launch_intent_test.dart
?? documentation/reports/avelune/avelune_ui_01_mobile_console_home_experience.md
?? documentation/reports/editor/smart_tiles_tiled_imports_and_performance_audit_2026-08-04.md
?? examples/playable_runtime_host/test/stn10_tiled_golden_workflow_test.dart
?? packages/map_runtime/test/tiled_asset_store_bundle_loading_test.dart
```
<!-- FINAL_STATUS_END -->

## 24. Périmètre non touché

Le lot ne modifie pas : Flame, mécaniques de jeu, format des packages, format de sauvegarde, combat, Narrative Studio, Map Editor, comptes, réseau social, boutique, succès, monétisation, analytics, routeur global ou modèles persistants.

La mécanique la plus proche du roadmap est `FG-014` déjà marquée DONE. Les lots runtime UX de phase 9 ne sont pas requalifiés : AVELUNE-UI-01 est un shell de distribution mobile et n’ajoute aucune mécanique. Aucun statut de roadmap n’est modifié.

## 25. Limites connues

1. Le dépôt ne contient pas le logo autonome croissant/A/étoile; l’icône iOS existante sert de ressource temporaire.
2. Aucun profil local n’existe, donc aucun avatar fictif n’est affiché.
3. L’activité récente expose une dernière sauvegarde par jeu, pas un historique complet ni le type automatique/manuelle.
4. La couleur de coque partage volontairement `accentColor` avec le titre; un contrôle indépendant demanderait un futur lot de modèle, packaging et migration.
5. Le clic emploie `SystemSoundType.click`; aucun asset sonore de cartouche n’existe dans le produit.
6. Les goldens utilisent le fallback d’artwork. Les covers réelles dépendent des packages installés.
7. La suite globale et l’intégration sont bloquées par la divergence v6/fixtures v1, hors scope.
8. La reproduction reste stylisée : pas de rendu 3D, de texture photographique ou d’animation physique complexe.

## 26. Auto-review critique

| Question | Verdict |
|---|---|
| Même composant héros/étagère/Ajouter ? | Oui, `AveluneCartridge` dans les trois cas. |
| Ratio réellement unique ? | Oui, constante 0.7 et test structurel. |
| Étagère strictement uniforme ? | Oui, largeur unique, hauteur dérivée, test de tailles. |
| Ajouter au même format ? | Oui, constructeur nommé du même widget. |
| Héros droit ? | Oui, aucune API de rotation dans la feature. |
| Console frontale ? | Oui, symétrique, sans perspective ni manette. |
| Variante horizontale introduite ? | Non. |
| Fausses données en production ? | Non; noms de référence uniquement dans tests/goldens. |
| Flow métier contourné ? | Non; import, resolveur, player et coordinateur sont réutilisés. |
| Sans jeu / sans sauvegarde ? | Oui, tests et goldens. |
| Petit téléphone ? | Oui, 320×568 et scrolling. |
| Festival de cartes ? | Non; les surfaces structurantes sont console, étagère, activité. |
| Effets surchargés ? | Non; gradients statiques et animations localisées. |
| Boutique, succès, Découvrir ? | Absents. |
| Paramètres dupliqués ? | Non; uniquement la navigation basse. |
| Modèle persistant modifié ? | Non. |
| Fichier temporaire dans le dépôt ? | Le Gate `find` doit retourner vide. |
| Commentaires ajoutés ? | Aucun dans les nouveaux fichiers Avelune. Le prompt demandait de vérifier ce point; cette consigne directe a prévalu sur la préférence générique de commentaires de `codex_rule.md`. |

### Verdict des passes nommées

L’instruction développeur active interdisait de créer des sous-agents sans demande explicite. Conformément au fallback de `codex_rule.md`, le travail a donc été conduit en passes distinctes, sans sous-agent.

| Passe | Verdict |
|---|---|
| Audit / Architecture | Conforme : package, navigation, données, assets et frontières identifiés. |
| Implémentation | Conforme : mobile isolé, desktop préservé, source unique cartouche. |
| Tests | Conforme ciblé : 50/50; global honnêtement rouge sur 26 fixtures hors diff. |
| Build / Validation | Conforme : Android et iOS Simulator construits; macOS compile avant blocage fixture. |
| Critique finale | Conforme avec limites documentées : logo, historique, audio et fixtures. |

## 27. Critique du prompt

Le prompt initial est particulièrement utile sur la règle d’un moule unique et sur l’interdiction des données fictives. Trois tensions ont nécessité une interprétation explicite :

1. **Bouton Continuer obligatoire vs retour utilisateur ultérieur.** Le retour ultérieur demandait de supprimer le gros bouton. Il est prioritaire et améliore la cohérence console; la fonction Continuer reste réelle mais devient le geste d’insertion.
2. **Skeuomorphisme léger vs réalisme demandé ensuite.** La seconde demande assume davantage de matière. La solution ajoute reliefs et animation sans moteur 3D ni image statique.
3. **Couleur de coque dédiée.** Créer silencieusement un champ persistant aurait violé le scope. L’existant `accentColor` couvre déjà le besoin avec parité API/MCP; le libellé a été clarifié.

Le prompt demande aussi un Evidence Pack exhaustif pouvant devenir disproportionné. Le présent document conserve toutes les sorties utiles et les petits contrats complets, tandis que les sources et le diff Git restent les preuves canoniques conformément aux règles du dépôt.

## 28. Recommandations pour le lot suivant

1. Produire un asset de marque autonome officiel, idéalement vectoriel ou PNG transparent multi-densité.
2. Décider produit : conserver `accentColor` partagé ou introduire explicitement `cartridgeShellColor` avec migration, packaging, auteur et MCP.
3. Enrichir le read model d’activité seulement si un vrai historique de sauvegarde devient nécessaire.
4. Ajouter un son de cartouche Avelune licencié et routé par le mixer d’effets.
5. Corriger le lot séparé de migration des fixtures v1/v2 vers le manifeste v6, puis relancer la suite complète et l’intégration réelle.
6. Faire tester l’insertion et l’appui long sur appareils physiques iOS/Android pour calibrer haptique et durée.

## 29. Evidence Pack

### 29.1 Petits fichiers créés — contenu complet

#### `apps/pokemap_hub/lib/src/ui/player/hub_player_launch_intent.dart`

```dart
import 'package:map_runtime/map_runtime.dart';

enum HubPlayerLaunchIntent { title, continueGame }

extension HubPlayerLaunchIntentBehavior on HubPlayerLaunchIntent {
  bool get skipsIntro => this == HubPlayerLaunchIntent.continueGame;
}

typedef HubRuntimeCommandDispatcher = Future<RuntimePlayerCommandResult>
    Function(RuntimePlayerCommand command);

Future<RuntimePlayerCommandResult?> dispatchHubInitialLaunchIntent({
  required HubPlayerLaunchIntent intent,
  required RuntimePlayerSnapshot snapshot,
  required HubRuntimeCommandDispatcher dispatch,
}) {
  if (intent == HubPlayerLaunchIntent.title) {
    return Future<RuntimePlayerCommandResult?>.value();
  }
  return dispatch(
    RuntimePlayerCommand(
      action: RuntimePlayerAction.continueGame,
      snapshotRevision: snapshot.revision,
    ),
  );
}
```

#### `apps/pokemap_hub/lib/src/ui/avelune/avelune_game_presentation.dart`

```dart
import 'dart:io';

import 'package:flutter/material.dart';

import '../hub_dashboard_controller.dart';
import '../hub_game_views.dart';
import 'avelune_theme.dart';

String aveluneArtworkHeroTag(String gameId) => 'avelune-artwork-$gameId';

ImageProvider<Object>? aveluneArtworkFor(HubGameView game) {
  final path = game.activity.coverPath ??
      game.activity.heroPath ??
      game.activity.iconPath;
  return path == null ? null : FileImage(File(path));
}

Color aveluneShellColorFor(BuildContext context, HubGameView game) {
  final colors = context.aveluneColors;
  final accent = decodeHubAccentColor(game.game.branding?.accentColor);
  return accent == null
      ? colors.shell
      : Color.lerp(accent, colors.shell, 0.24)!;
}

String formatAveluneRelativeTime(
  DateTime value,
  DateTime reference, {
  required bool french,
  bool compact = false,
}) {
  final difference = reference.toUtc().difference(value.toUtc());
  if (difference.isNegative || difference.inMinutes < 1) {
    return french ? 'À l’instant' : 'Now';
  }
  if (difference.inMinutes < 60) {
    return compact
        ? '${difference.inMinutes} min'
        : french
            ? 'Il y a ${difference.inMinutes} min'
            : '${difference.inMinutes} min ago';
  }
  if (difference.inHours < 24) {
    return compact
        ? '${difference.inHours} h'
        : french
            ? 'Il y a ${difference.inHours} h'
            : '${difference.inHours} h ago';
  }
  if (difference.inDays == 1) return french ? 'Hier' : 'Yesterday';
  return compact
      ? '${difference.inDays} j'
      : french
          ? 'Il y a ${difference.inDays} j'
          : '${difference.inDays} d ago';
}
```

### 29.2 Hunk pertinent — activation mobile et reprise

```diff
@@ HubComposition.buildApp
+        mobileConsoleExperience: Platform.isAndroid || Platform.isIOS,
-        playerBuilder: (context, game, onHubRequested) =>
+        playerBuilder: (context, game, intent, onHubRequested) =>
             HubInstalledGamePlayer(
+          initialLaunchIntent: intent,
```

```diff
@@ PokeMapHubApp._effectiveActions
-      onContinue: _openPlayer,
-      onNewGame: _openPlayer,
+      onContinue: (game) => _openPlayer(
+        game,
+        intent: HubPlayerLaunchIntent.continueGame,
+      ),
+      onNewGame: (game) => _openPlayer(
+        game,
+        intent: HubPlayerLaunchIntent.title,
+      ),
```

```diff
@@ HubInstalledGamePlayer._initialize
+      _introComplete = widget.initialLaunchIntent.skipsIntro ||
+          intro == null ||
+          (_reducedMotion &&
+              (intro.reducedMotionBehavior == 'skip' || intro.poster == null));
       await coordinator.initialize();
+      final initialLaunch = await dispatchHubInitialLaunchIntent(
+        intent: widget.initialLaunchIntent,
+        snapshot: coordinator.snapshot,
+        dispatch: coordinator.dispatch,
+      );
+      if (initialLaunch != null &&
+          initialLaunch.status != RuntimePlayerCommandStatus.accepted) {
+        throw StateError(
+          initialLaunch.safeMessage ??
+              'The selected save could not be resumed from Avelune.',
+        );
+      }
```

### 29.3 Hunk pertinent — couleur dans le Hub de personnalisation

```diff
-              'Couleur d’accent',
+              'Couleur de cartouche Avelune et accent',
...
+              const Text(
+                'Cette couleur teinte la coque de la cartouche dans Avelune '
+                'et les accents de l’écran titre.',
+              ),
```

### 29.4 Git diff --name-only final

<!-- FINAL_DIFF_NAMES_START -->
```text
apps/pokemap_hub/integration_test/runtime_owned_player_flow_test.dart
apps/pokemap_hub/lib/pokemap_hub_ui.dart
apps/pokemap_hub/lib/src/platform/hub_composition.dart
apps/pokemap_hub/lib/src/ui/hub_app.dart
apps/pokemap_hub/lib/src/ui/hub_game_views.dart
apps/pokemap_hub/lib/src/ui/hub_shell.dart
apps/pokemap_hub/lib/src/ui/player/hub_installed_game_player.dart
apps/pokemap_hub/pubspec.yaml
apps/pokemap_hub/test/ui/hub_app_player_navigation_test.dart
examples/playable_runtime_host/macos/Flutter/GeneratedPluginRegistrant.swift
packages/map_authoring/lib/src/domains/assets/tileset_actions.dart
packages/map_authoring/test/domains/assets/visual_library_contract_test.dart
packages/map_core/lib/src/operations/project_tileset_visual_resolver.dart
packages/map_core/lib/src/validation/validators.dart
packages/map_core/test/project_tileset_source_test.dart
packages/map_core/test/project_tileset_visual_resolver_test.dart
packages/map_editor/lib/src/features/editor/application/tiled_map_import_service.dart
packages/map_editor/lib/src/features/personalization/presentation/personalization_studio_workspace.dart
packages/map_editor/lib/src/features/personalization/presentation/project_branding_editor.dart
packages/map_editor/test/features/editor/application/tiled_map_import_service_test.dart
packages/map_editor/test/personalization/project_branding_editor_test.dart
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
```
<!-- FINAL_DIFF_NAMES_END -->

### 29.5 Git diff --check final

<!-- FINAL_DIFF_CHECK_START -->
```text
Sortie : <vide>
```
<!-- FINAL_DIFF_CHECK_END -->

### 29.6 Absence de fichiers temporaires dans le dépôt

Commande :

```text
find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
```

<!-- FINAL_TEMP_FIND_START -->
```text
Sortie : <vide>
```
<!-- FINAL_TEMP_FIND_END -->

### 29.7 Hygiène Markdown

<!-- FINAL_MARKDOWN_HYGIENE_START -->
```text
Markdown hygiene: 2 new Markdown files exceed the default limit of 0.
Use POKEMAP_MARKDOWN_MAX_NEW only when the user explicitly approved a bounded bulk documentation task.
```
<!-- FINAL_MARKDOWN_HYGIENE_END -->

Résultat : échec non masqué. Le prompt autorise exactement le présent rapport, mais le worktree contenait déjà l’autre fichier non suivi `documentation/reports/editor/smart_tiles_tiled_imports_and_performance_audit_2026-08-04.md`. Le garde-fou compte donc deux nouveaux Markdown. Aucun override n’a été utilisé et le fichier externe n’a pas été modifié.

### 29.8 Règles Git

Aucune commande Git d’écriture n’a été exécutée. Aucun commit n’a été créé. Toutes les opérations Git du lot sont des lectures autorisées.

## 30. Addendum V0.2 — passe skeuomorphique Picsart

### 30.1 Résumé exécutif de la reprise

Cette reprise répond au retour explicite demandant davantage de skeuomorphisme,
des matériaux réalistes, puis une nouvelle composition de la console et de
l’étagère. Elle conserve intégralement les contrats métier et le moule unique de
cartouche de la V0.1.

Résultat livré :

- quatre matières/illustrations originales Picsart sont intégrées comme petites
  ressources de surface, jamais comme capture d’écran ou objet complet ;
- les jaquettes de démonstration Picsart restent exclusivement dans les fixtures
  de tests golden ;
- la cartouche canonique reçoit grain ABS, biseau, reflet d’étiquette et
  connecteurs en laiton ;
- la console est désormais frontale, symétrique, biseautée et composée d’une
  coque supérieure, d’une façade en retrait, d’un puits d’insertion profond et
  d’une lèvre d’occlusion ;
- l’étagère est une niche continue en noyer avec rail, montants, fond sombre et
  plinthe épaisse ;
- l’activité récente repose dans un cadre de noyer cohérent ;
- les animations d’insertion, d’échange et de Hero sont conservées, testées et
  compatibles avec la réduction des animations ;
- le flottement de la cartouche ne reconstruit plus la console texturée à chaque
  frame ;
- sept goldens ont été régénérés, inspectés et comparés dans une même image avec
  la référence.

### 30.2 Gate de reprise et concurrence

État exact observé avant la première modification de cette reprise :

```text
?? documentation/reports/editor/smart_tiles_tiled_imports_and_performance_audit_2026-08-04.md
?? packages/map_core/test/benchmark/smart_tiles_rich_map_fixture_test.dart
?? packages/map_core/test/benchmark/smart_tiles_rich_map_scaling_cli_test.dart
?? tools/performance/smart_tiles_rich_map_fixture.dart
```

Ces fichiers appartenaient à un travail Smart Tiles/performance concurrent. Ils
n’ont jamais été modifiés par AVELUNE-UI-01 V0.2. Pendant la reprise, ce travail
concurrent a ajouté/modifié d’autres fichiers sous `map_core`, `map_editor` et
`map_runtime`. Une compilation Avelune a momentanément observé le fichier
`map_layers_component.dart` pendant son écriture concurrente ; aucun fichier de
ce lot externe n’a été corrigé, restauré ou nettoyé par la passe Avelune.

### 30.3 Provenance Picsart

Le MCP Picsart a été utilisé avec `flux-2-pro`. Les ressources acceptées sont :

| Usage | Generation ID Picsart | Fichier final | Dimensions |
|---|---|---|---|
| grain ABS mat neutre et teintable | `62f117ba-016b-48e6-812d-f986bb26c61a` | `assets/avelune/materials/matte_abs_grain.webp` | 512 × 512 |
| noyer sombre satiné horizontal | `1a0e0043-0422-44fc-8837-ae960f337e6b` | `assets/avelune/materials/dark_walnut_satin.webp` | 1024 × 614 |
| laiton brossé | `2d963abf-4cb8-4745-a01d-526daa4959d3` | `assets/avelune/materials/brushed_brass.webp` | 640 × 384 |
| fallback générique Avelune, sentier lunaire | `6798f863-cd11-493f-ae23-9b65b30b52fa` | `assets/avelune/artwork/fallback_moonlit_path.webp` | 512 × 853 |
| fixture Selbrume, phare côtier | `e6d3f268-a7eb-49d0-8d11-3283335c0c8c` | `test/fixtures/avelune/covers/selbrume.webp` | 512 × 853 |
| fixture Train, crépuscule | `118c61f0-b410-4dbc-8247-5c8aa890d6b0` | `test/fixtures/avelune/covers/train.webp` | 512 × 853 |
| fixture Démo, manette filaire violette | `1c1ff56d-5ba9-4965-a235-dcd96435013b` | `test/fixtures/avelune/covers/demo.webp` | 512 × 853 |

Une première proposition de bois trop rustique a été rejetée et n’a pas été
ajoutée au dépôt. Aucun logo, écran complet, cartouche complète ni console
complète n’a été généré. Les couleurs de coque restent calculées depuis
`branding.accentColor`.

Poids total des quatre ressources de production : 235 504 octets. Les trois
jaquettes de tests totalisent 158 434 octets et ne sont pas déclarées comme
assets de production.

### 30.4 Contrat visuel et composants repris

Le contrat canonique reste inchangé :

```dart
const double kAveluneCartridgeAspectRatio = 0.7;
```

`AveluneCartridge` reste l’unique widget utilisé pour :

- la cartouche héro ;
- chaque cartouche de bibliothèque ;
- la cartouche « Ajouter un jeu ».

La nouvelle console utilise une silhouette propriétaire
`_AveluneConsoleSilhouetteClipper`, parfaitement frontale et symétrique. Elle ne
contient ni rotation de cartouche, ni perspective latérale, ni contrôle de
Game Boy. Les clés structurelles testées sont :

```text
avelune-console-silhouette
avelune-console-material-texture
avelune-console-faceplate
avelune-console-insertion-well
avelune-console-slot-lip
```

La niche de bibliothèque est contrôlée par :

```text
avelune-game-cabinet
avelune-shelf-cavity
avelune-shelf-top-rail
avelune-shelf-wood-texture
avelune-shelf-plinth
```

Les cartouches ont toujours les mêmes contraintes. Leur bas rejoint la face
supérieure de la plinthe ; la couverture et les titres ne changent jamais la
géométrie de la coque.

### 30.5 Interactions, animation et performances

- toucher la cartouche héro déclenche la descente amortie, l’occlusion par la
  lèvre, le clic système, le retour haptique, le bloom de LED puis le flow réel ;
- appuyer longtemps déclenche le Hero de la seule illustration/fallback vers la
  page de détails ;
- sélectionner une cartouche de la niche anime une cartouche sortante vers le
  bas/gauche et la nouvelle vers le haut/centre, sans rotation ;
- les durées de route, l’insertion et l’échange deviennent nulles si
  `MediaQuery.disableAnimationsOf(context)` le demande ;
- le `AnimatedBuilder` du flottement ne reconstruit plus la console : la
  console n’écoute que la progression d’insertion ;
- les images sont packagées, compressées et mises en cache ;
- le harness golden consulte le cache avant décodage, clone l’image conservée
  puis libère le codec et l’image de frame intermédiaire.

### 30.6 Fichiers de la reprise

Fichiers de production modifiés :

```text
apps/pokemap_hub/lib/src/ui/avelune/avelune_cartridge.dart
apps/pokemap_hub/lib/src/ui/avelune/avelune_console.dart
apps/pokemap_hub/lib/src/ui/avelune/avelune_game_details.dart
apps/pokemap_hub/lib/src/ui/avelune/avelune_game_presentation.dart
apps/pokemap_hub/lib/src/ui/avelune/avelune_mobile_home.dart
apps/pokemap_hub/lib/src/ui/avelune/avelune_theme.dart
apps/pokemap_hub/pubspec.yaml
```

Ressources de production créées :

```text
apps/pokemap_hub/assets/avelune/artwork/fallback_moonlit_path.webp
apps/pokemap_hub/assets/avelune/materials/brushed_brass.webp
apps/pokemap_hub/assets/avelune/materials/dark_walnut_satin.webp
apps/pokemap_hub/assets/avelune/materials/matte_abs_grain.webp
```

Tests et preuves modifiés/créés :

```text
apps/pokemap_hub/test/fixtures/avelune/covers/demo.webp
apps/pokemap_hub/test/fixtures/avelune/covers/selbrume.webp
apps/pokemap_hub/test/fixtures/avelune/covers/train.webp
apps/pokemap_hub/test/ui/avelune_cartridge_test.dart
apps/pokemap_hub/test/ui/avelune_mobile_home_golden_test.dart
apps/pokemap_hub/test/ui/avelune_mobile_home_test.dart
apps/pokemap_hub/test/ui/goldens/avelune/details_390x844.png
apps/pokemap_hub/test/ui/goldens/avelune/empty_390x844.png
apps/pokemap_hub/test/ui/goldens/avelune/exchange_390x844.png
apps/pokemap_hub/test/ui/goldens/avelune/home_320x568.png
apps/pokemap_hub/test/ui/goldens/avelune/home_390x844.png
apps/pokemap_hub/test/ui/goldens/avelune/inserting_390x844.png
apps/pokemap_hub/test/ui/goldens/avelune/no_save_430x932.png
documentation/reports/avelune/avelune_ui_01_mobile_console_home_experience.md
```

### 30.7 TDD et validation exacte

RED initial ciblé :

```text
flutter test --no-pub -r expanded \
  test/ui/avelune_cartridge_test.dart \
  test/ui/avelune_mobile_home_test.dart
```

Résultat : trois échecs attendus, portant sur l’absence de texture de cartouche,
des couches structurelles de console/niche et du fallback illustré.

GREEN intermédiaire :

```text
+17: All tests passed!
```

Validation finale après la reprise demandée de la console et de l’étagère :

```text
flutter test --no-pub -r expanded \
  test/ui/avelune_cartridge_test.dart \
  test/ui/avelune_mobile_home_test.dart \
  test/ui/avelune_mobile_home_golden_test.dart
```

Résultat exact :

```text
00:02 +24: All tests passed!
```

Analyse ciblée :

```text
flutter analyze --no-pub \
  lib/src/ui/avelune \
  test/ui/avelune_cartridge_test.dart \
  test/ui/avelune_mobile_home_test.dart \
  test/ui/avelune_mobile_home_golden_test.dart
```

Résultat exact :

```text
Analyzing 4 items...
No issues found! (ran in 3.0s)
```

Build Android :

```text
flutter build apk --debug --no-pub
Running Gradle task 'assembleDebug'... 11.6s
✓ Built build/app/outputs/flutter-apk/app-debug.apk
```

Build iOS Simulator :

```text
flutter build ios --simulator --no-codesign --no-pub
Building com.yoahnl.avelune.player for simulator (ios)...
Xcode build done. 13.3s
✓ Built build/ios/iphonesimulator/Runner.app
```

### 30.8 Visual Gate V0.2

Captures versionnées :

| État | Dimensions | SHA-256 |
|---|---:|---|
| accueil standard | 390 × 844 | `6f3021b0d1b9c32f130baf65c04c8cd70511e7b574144b94a9e2aae3db2b223d` |
| petit écran | 320 × 568 | `800ea3be87e084119ef469378d31a594cd324a603024c3f8f7a06d67d1cfcb24` |
| aucun jeu | 390 × 844 | `201f5607587d032dcac20d064ca4fbe2ffb7e559df84ed070f26cfd4ed20de61` |
| jeu sans sauvegarde | 430 × 932 | `0e6fd81dcee0f708439b0a88a804396247703a557f857ca37b65cc4cc84fe860` |
| insertion | 390 × 844 | `5f0eed068f618f049920d953d88f389294ba04cb2a45d321248da1b831007f66` |
| échange | 390 × 844 | `ced63b9c77fbaf795576622a55b14d59b81ece98e24f9017c9f8a2f69bb023fe` |
| détails Hero | 390 × 844 | `eb8c96bac9bf34e159876620bb2185618991861d8d62a42217f75f2827969741` |

Comparaisons hors dépôt :

```text
/Users/karim/.codex/visualizations/2026/08/04/019fce80-6edd-7ae1-8cb2-5243868c7a82/avelune_v02_reference_comparison.png
865 × 844
SHA-256 b0234c6a5ce67a5a55bb85e27bf538459028a628dce1af936de7c355c216151b

/Users/karim/.codex/visualizations/2026/08/04/019fce80-6edd-7ae1-8cb2-5243868c7a82/avelune_v02_capture_sheet.png
780 × 1126
SHA-256 6ee5e3b04dce92e98ae18b2bc40434b8bceeee8f3601f049518b4c0522c012a5
```

Contrôles visuels passés :

- cartouche héro droite, verticale et issue du même composant ;
- ratio unique et cartouches de niche strictement uniformes ;
- console frontale, symétrique et non assimilable à une manette ;
- puits et lèvre masquant correctement la cartouche pendant l’insertion ;
- meuble continu en noyer, fond de niche sombre et plinthe visible ;
- scène entière stable pendant insertion et échange ;
- fond supérieur sans décor ;
- navigation Accueil/Paramètres seulement ;
- aucun bouton Game Boy, aucun onglet boutique/découverte/succès ;
- pas d’overflow à 320 × 568, 390 × 844 ou 430 × 932.

Différences assumées avec la référence :

- l’ancien gros bouton Continuer est volontairement remplacé par le geste
  physique d’insertion demandé par l’utilisateur ;
- le header conserve l’action d’import réelle à la place d’un faux profil ;
- la console reste une géométrie propriétaire stylisée, non une copie de
  console existante ;
- à mi-échange, les connecteurs des deux cartouches restent visibles ;
- l’état vide conserve provisoirement un CTA d’import explicite en plus de la
  cartouche d’ajout, afin de ne pas rendre le premier usage ambigu.

### 30.9 Verdict des passes V0.2

- **Audit / Architecture** : faisable uniquement dans `apps/pokemap_hub`, sans
  modèle persistant ni runtime à modifier ; verdict favorable.
- **Tests** : baseline verte, tests RED minimaux définis puis validation finale
  `+24` ; verdict GREEN.
- **Implémentation Review** : aucun P1 ; ratio, flows, personnalisation, Hero et
  réduction des animations préservés. Le P2 de reconstruction permanente de la
  console a été corrigé avant clôture.
- **Critique visuelle contradictoire** : une première lecture d’un golden
  périmé signalait à tort une scène d’insertion manquante. La relecture des
  fichiers courants a retiré ce P1. Après la nouvelle console et la nouvelle
  niche demandées par l’utilisateur, verdict final : passe acceptée, écarts
  résiduels non bloquants.

### 30.10 Auto-review V0.2

- même composant cartouche partout : **oui** ;
- ratio central unique : **oui, 0.7** ;
- cartouches de niche uniformes : **oui** ;
- ajout au même format : **oui** ;
- cartouche héro droite et frontale : **oui** ;
- console frontale et symétrique : **oui** ;
- aucune variante horizontale : **oui** ;
- fausses données en production : **non** ;
- flows import/lancement contournés : **non** ;
- état vide et sans sauvegarde : **oui** ;
- petit téléphone : **oui, test et golden 320 × 568** ;
- festival de cartes : **non** ;
- effets permanents coûteux : **non** ;
- boutique, succès ou Découvrir : **non** ;
- modèle persistant modifié : **non** ;
- fichiers temporaires golden conservés : **non** ;
- commentaires de code ajoutés : **non**.

Limites restantes non bloquantes : superposition des connecteurs à mi-échange,
CTA d’import vide encore Material, `+` du header redondant et console encore un
peu plus graphique que la référence photographique.

### 30.11 Evidence Pack final V0.2

#### Diff stat final

<!-- V02_FINAL_DIFF_STAT_START -->
```text
 .../lib/src/ui/avelune/avelune_cartridge.dart      |  60 +-
 .../lib/src/ui/avelune/avelune_console.dart        | 606 ++++++++++++++-------
 .../lib/src/ui/avelune/avelune_game_details.dart   |  71 ++-
 .../src/ui/avelune/avelune_game_presentation.dart  |  25 +
 .../lib/src/ui/avelune/avelune_mobile_home.dart    | 458 +++++++++++-----
 .../lib/src/ui/avelune/avelune_theme.dart          |  12 +
 apps/pokemap_hub/pubspec.yaml                      |   2 +
 .../test/ui/avelune_cartridge_test.dart            |  17 +
 .../test/ui/avelune_mobile_home_golden_test.dart   |  60 +-
 .../test/ui/avelune_mobile_home_test.dart          | 145 ++++-
 .../test/ui/goldens/avelune/details_390x844.png    | Bin 79387 -> 214937 bytes
 .../test/ui/goldens/avelune/empty_390x844.png      | Bin 80562 -> 167578 bytes
 .../test/ui/goldens/avelune/exchange_390x844.png   | Bin 121611 -> 232604 bytes
 .../test/ui/goldens/avelune/home_320x568.png       | Bin 61622 -> 114331 bytes
 .../test/ui/goldens/avelune/home_390x844.png       | Bin 113331 -> 229568 bytes
 .../test/ui/goldens/avelune/inserting_390x844.png  | Bin 109872 -> 224998 bytes
 .../test/ui/goldens/avelune/no_save_430x932.png    | Bin 132210 -> 271277 bytes
 ...avelune_ui_01_mobile_console_home_experience.md | 461 ++++++++++++++++
 .../world_map_large_map_performance_test.dart      |  17 +
 ..._layers_component_performance_profile_test.dart |  19 +
 20 files changed, 1598 insertions(+), 355 deletions(-)
```
<!-- V02_FINAL_DIFF_STAT_END -->

#### Diff name-only final

<!-- V02_FINAL_DIFF_NAMES_START -->
```text
apps/pokemap_hub/lib/src/ui/avelune/avelune_cartridge.dart
apps/pokemap_hub/lib/src/ui/avelune/avelune_console.dart
apps/pokemap_hub/lib/src/ui/avelune/avelune_game_details.dart
apps/pokemap_hub/lib/src/ui/avelune/avelune_game_presentation.dart
apps/pokemap_hub/lib/src/ui/avelune/avelune_mobile_home.dart
apps/pokemap_hub/lib/src/ui/avelune/avelune_theme.dart
apps/pokemap_hub/pubspec.yaml
apps/pokemap_hub/test/ui/avelune_cartridge_test.dart
apps/pokemap_hub/test/ui/avelune_mobile_home_golden_test.dart
apps/pokemap_hub/test/ui/avelune_mobile_home_test.dart
apps/pokemap_hub/test/ui/goldens/avelune/details_390x844.png
apps/pokemap_hub/test/ui/goldens/avelune/empty_390x844.png
apps/pokemap_hub/test/ui/goldens/avelune/exchange_390x844.png
apps/pokemap_hub/test/ui/goldens/avelune/home_320x568.png
apps/pokemap_hub/test/ui/goldens/avelune/home_390x844.png
apps/pokemap_hub/test/ui/goldens/avelune/inserting_390x844.png
apps/pokemap_hub/test/ui/goldens/avelune/no_save_430x932.png
documentation/reports/avelune/avelune_ui_01_mobile_console_home_experience.md
packages/map_editor/test/ui/world_map/world_map_large_map_performance_test.dart
packages/map_runtime/test/map_layers_component_performance_profile_test.dart
```
<!-- V02_FINAL_DIFF_NAMES_END -->

#### Git status final exact

<!-- V02_FINAL_STATUS_START -->
```text
 M apps/pokemap_hub/lib/src/ui/avelune/avelune_cartridge.dart
 M apps/pokemap_hub/lib/src/ui/avelune/avelune_console.dart
 M apps/pokemap_hub/lib/src/ui/avelune/avelune_game_details.dart
 M apps/pokemap_hub/lib/src/ui/avelune/avelune_game_presentation.dart
 M apps/pokemap_hub/lib/src/ui/avelune/avelune_mobile_home.dart
 M apps/pokemap_hub/lib/src/ui/avelune/avelune_theme.dart
 M apps/pokemap_hub/pubspec.yaml
 M apps/pokemap_hub/test/ui/avelune_cartridge_test.dart
 M apps/pokemap_hub/test/ui/avelune_mobile_home_golden_test.dart
 M apps/pokemap_hub/test/ui/avelune_mobile_home_test.dart
 M apps/pokemap_hub/test/ui/goldens/avelune/details_390x844.png
 M apps/pokemap_hub/test/ui/goldens/avelune/empty_390x844.png
 M apps/pokemap_hub/test/ui/goldens/avelune/exchange_390x844.png
 M apps/pokemap_hub/test/ui/goldens/avelune/home_320x568.png
 M apps/pokemap_hub/test/ui/goldens/avelune/home_390x844.png
 M apps/pokemap_hub/test/ui/goldens/avelune/inserting_390x844.png
 M apps/pokemap_hub/test/ui/goldens/avelune/no_save_430x932.png
 M documentation/reports/avelune/avelune_ui_01_mobile_console_home_experience.md
 M packages/map_editor/test/ui/world_map/world_map_large_map_performance_test.dart
 M packages/map_runtime/test/map_layers_component_performance_profile_test.dart
?? apps/pokemap_hub/assets/avelune/artwork/fallback_moonlit_path.webp
?? apps/pokemap_hub/assets/avelune/materials/brushed_brass.webp
?? apps/pokemap_hub/assets/avelune/materials/dark_walnut_satin.webp
?? apps/pokemap_hub/assets/avelune/materials/matte_abs_grain.webp
?? apps/pokemap_hub/test/fixtures/avelune/covers/demo.webp
?? apps/pokemap_hub/test/fixtures/avelune/covers/selbrume.webp
?? apps/pokemap_hub/test/fixtures/avelune/covers/train.webp
?? documentation/reports/editor/smart_tiles_tiled_imports_and_performance_audit_2026-08-04.md
?? packages/map_core/test/benchmark/smart_tiles_performance_baseline_test.dart
?? packages/map_core/test/benchmark/smart_tiles_performance_policy_test.dart
?? packages/map_core/test/benchmark/verify_smart_tiles_performance_cli_test.dart
?? packages/map_editor/tool/performance/smart_tiles_rich_editor_scaling_test.dart
?? packages/map_runtime/tool/performance/smart_tiles_rich_runtime_scaling_test.dart
?? tools/performance/smart_tiles_performance_baseline.dart
?? tools/performance/smart_tiles_performance_policy.dart
?? tools/performance/verify_smart_tiles_performance.dart
```
<!-- V02_FINAL_STATUS_END -->

#### Git diff --check final

<!-- V02_FINAL_DIFF_CHECK_START -->
```text
Sortie : <vide>
```
<!-- V02_FINAL_DIFF_CHECK_END -->

#### Fichiers temporaires

<!-- V02_FINAL_TEMP_START -->
```text
Sortie : <vide>
```
<!-- V02_FINAL_TEMP_END -->

#### Hygiène Markdown

<!-- V02_FINAL_MARKDOWN_START -->
```text
Markdown hygiene: 1 new Markdown files exceed the default limit of 0.
Use POKEMAP_MARKDOWN_MAX_NEW only when the user explicitly approved a bounded bulk documentation task.
```
<!-- V02_FINAL_MARKDOWN_END -->

Résultat d’hygiène : échec préexistant/concurrent non masqué. La reprise met à
jour le rapport Avelune déjà suivi et ne crée aucun nouveau Markdown. L’unique
nouveau Markdown compté est le rapport Smart Tiles non suivi, hors périmètre.

### 30.12 Git

Aucune commande Git d’écriture n’a été exécutée pendant V0.2. Aucun commit et
aucun push n’ont été réalisés par cette reprise.

## 31. Addendum V0.3 — usure réaliste et commode continue

### 31.1 Résumé exécutif

Cette dernière passe répond au retour demandant une console et des cartouches
plus réalistes, avec de petites marques d’usage, ainsi qu’un véritable meuble
sur lequel la console et les jeux paraissent physiquement rangés.

Le résultat conserve les widgets et les données réelles de la V0.2, mais ajoute :

- un masque d’usure ABS transparent issu d’une matière Picsart, sans voile gris
  ni grain « pierre » sur les composants ;
- des micro-rayures et abrasions rares sur la coque canonique et la façade de
  la console ;
- un noyer vieilli plus riche, avec veinage horizontal, patine et fines rayures ;
- une commode continue composée de la tablette de console, de deux montants,
  d’une niche, d’une plinthe et de deux façades de tiroirs avec petites poignées ;
- deux vis de moulage discrètes sur le dessus de la console ;
- une stabilisation du golden d’insertion : état animé exécuté en premier,
  reconstruction propre du décor et repaint complet avant capture.

Ni modèle persistant, ni moteur, ni format de package, ni flow d’import ou de
lancement n’a été modifié.

### 31.2 Provenance Picsart complémentaire

Deux nouvelles générations Picsart `flux-2-pro` ont été retenues :

| Usage | Generation ID | Fichier final |
|---|---|---|
| ABS vieilli et micro-rayé | `eb4d4a93-ff01-4817-9978-2e37d37e7593` | `assets/avelune/materials/aged_abs_wear.webp` |
| noyer ancien satiné | `6e06007f-ce84-406b-86b8-943a3864b39e` | `assets/avelune/materials/dark_walnut_satin.webp` |

Prompt ABS exact :

```text
Seamless tileable grayscale material texture, realistic matte black ABS plastic micro-grain with subtle handling polish, sparse hairline scuffs, tiny abrasion flecks and faint rubbed marks from years of careful use, evenly lit orthographic material scan, premium vintage consumer electronics, near-black background with light gray wear details, no object, no text, no logo, no borders, no dramatic shadow.
```

Prompt noyer exact :

```text
Seamless tileable horizontal dark walnut veneer material scan for premium 1970s hi-fi console furniture, rich deep brown grain, satin hand-rubbed varnish, subtle age patina, rare fine scratches and gently rubbed finish, warm understated realism, evenly lit orthographic surface, no furniture object, no handles, no text, no borders, no dramatic shadow.
```

La matière ABS brute n’est pas affichée directement. Sa luminance a été
seuillée pour isoler seulement les marques claires, puis convertie en canal
alpha blanc et compressée en WebP lossless 512 × 512. Cette dérivation évite le
défaut observé lors de la première tentative : un relief uniforme trop rugueux
qui faisait ressembler la console à de la pierre ou du feutre.

Le noyer V0.2 a été remplacé au même chemin par la génération plus patinée. Le
composant de console, la cartouche et la commode restent de vrais widgets ;
aucun objet complet généré n’est utilisé pour simuler l’interface.

### 31.3 Contrat du moule canonique inchangé

Le contrat reste :

```dart
const double kAveluneCartridgeAspectRatio = 0.7;
```

`AveluneCartridge` reste la seule implémentation physique pour le héros, les
jeux de la niche et « Ajouter un jeu ». L’usure est une couche de surface
commune, dont l’alignement varie de manière déterministe selon `gameId` ; elle
ne modifie ni silhouette, ni ratio, ni contraintes.

Constantes de matière ajoutées ou ajustées :

```dart
const String kAveluneAgedAbsWearAssetPath =
    'assets/avelune/materials/aged_abs_wear.webp';
const double kAveluneCartridgeWearOpacity = 0.86;
const double kAveluneConsoleWearOpacity = 0.72;
```

### 31.4 Architecture de la commode

La composition reste responsive. Elle ne dépend d’aucune hauteur d’iPhone
figée :

- `AveluneConsoleDock` dessine la tablette supérieure en noyer ;
- `_AveluneFurnitureBridge` prolonge cette tablette par deux montants de 18 dp ;
- `AveluneGameShelf` forme la niche sombre et garde sa liste horizontale lazy ;
- la plinthe de 36 dp reçoit `_AveluneFurnitureDrawers` ;
- les deux tiroirs sont décoratifs et exclus de l’arbre sémantique ;
- la cartouche et l’instruction d’insertion restent interactives et lisibles
  dans l’espace central du meuble.

Clés structurelles contrôlées :

```text
avelune-console-shelf
avelune-furniture-bridge
avelune-game-cabinet
avelune-shelf-cavity
avelune-shelf-plinth
avelune-furniture-drawers
```

### 31.5 Réalisme et performances

- le grain ABS de base reste modulé par la couleur de coque ;
- le masque d’usure transparent ne conserve que de rares rayures ;
- le masque de cartouche est placé au-dessus du label et des moulures, afin que
  l’objet complet porte des traces d’usage cohérentes ;
- le masque de console couvre le dessus et la façade, mais reste sous le slot,
  la marque, les ports et la LED ;
- les textures sont des assets packagés et mis en cache par Flutter ;
- chaque objet coûteux reste sous `RepaintBoundary` ;
- le flottement ne reconstruit toujours pas la console ;
- aucun blur plein écran, shader ou painter animé permanent n’a été ajouté.

Poids des cinq ressources de production : 265 356 octets.

```text
 33866 assets/avelune/materials/aged_abs_wear.webp
 27934 assets/avelune/materials/brushed_brass.webp
 70800 assets/avelune/materials/dark_walnut_satin.webp
 77702 assets/avelune/materials/matte_abs_grain.webp
 55054 assets/avelune/artwork/fallback_moonlit_path.webp
```

### 31.6 Tests et validation finale

Tests ciblés, goldens inclus :

```text
flutter test --no-pub -r expanded \
  test/ui/avelune_cartridge_test.dart \
  test/ui/avelune_mobile_home_test.dart \
  test/ui/avelune_mobile_home_golden_test.dart
```

Résultat exact :

```text
00:02 +24: All tests passed!
```

Analyse ciblée :

```text
flutter analyze --no-pub \
  lib/src/ui/avelune \
  test/ui/avelune_cartridge_test.dart \
  test/ui/avelune_mobile_home_test.dart \
  test/ui/avelune_mobile_home_golden_test.dart
```

Résultat exact après retrait d’un import redondant détecté pendant la passe :

```text
Analyzing 4 items...
No issues found! (ran in 2.0s)
```

Build Android :

```text
flutter build apk --debug --no-pub
Running Gradle task 'assembleDebug'... 12.3s
✓ Built build/app/outputs/flutter-apk/app-debug.apk
```

Build iOS Simulator :

```text
flutter build ios --simulator --no-codesign --no-pub
Building com.yoahnl.avelune.player for simulator (ios)...
Xcode build done. 12.6s
✓ Built build/ios/iphonesimulator/Runner.app
```

Suite complète `apps/pokemap_hub` :

```text
flutter test --no-pub -r compact
00:44 +200 -26: Some tests failed.
```

Les 26 échecs sont signalés sans être masqués. Ils proviennent de la validation
Smart Tiles V6 introduite hors de ce lot alors que plusieurs fixtures Hub sont
encore en manifeste V1. Exemple exact :

```text
FormatException: $.version: smart_tile_v6_project_required (expected=v6, actual=v1)
```

Les trois suites Avelune isolées passent avant et après cette exécution globale.
Aucun fichier `map_core`, Smart Tiles ou fixture de package externe n’a été
modifié pour contourner cette régression concurrente.

### 31.7 Visual Gate V0.3

Captures versionnées :

| État | Dimensions | SHA-256 |
|---|---:|---|
| accueil standard | 390 × 844 | `ae04fe210df8a4175fb0b907c55590299b63a5471b151bf0296a54b73caebcfe` |
| petit écran | 320 × 568 | `05f2f7b56d31ccd8bc52562fad92100316886a2da2c469a18012a9ace21e3a69` |
| aucun jeu | 390 × 844 | `1704dd64742f85bd9eb126a12b9dc8dc7f925b62aee1275fee7ade836186ddef` |
| jeu sans sauvegarde | 430 × 932 | `caa7a1b9c45d4d94342a6cbf1623942afb804ebdad21f355d70cedc2d7226b74` |
| insertion à 300 ms | 390 × 844 | `21ac68cd88cc2efc95cf01db8687a4f28bda604295b1e56d23225ac297c71bee` |
| échange | 390 × 844 | `9eba753e667be7142cd9f96182324ab17db57e1f169d6acd5182e8338a8fa59d` |
| détails Hero | 390 × 844 | `eb8c96bac9bf34e159876620bb2185618991861d8d62a42217f75f2827969741` |

Comparaisons hors dépôt :

```text
/Users/karim/.codex/visualizations/2026/08/04/019fce80-6edd-7ae1-8cb2-5243868c7a82/avelune_v03_reference_comparison.png
865 × 844
SHA-256 618d02e80c64efe0233c47442379c7b08ee0e42bc6e2dadf09f35d1a7c15b968

/Users/karim/.codex/visualizations/2026/08/04/019fce80-6edd-7ae1-8cb2-5243868c7a82/avelune_v03_capture_sheet.png
780 × 1126
SHA-256 b7aab1b742aeb067c4745ff4220e42accfe1549ee0742fec06c96d4f7eb608db
```

Le comparatif met la référence et l’implémentation dans une même image, au même
état d’accueil et à la même hauteur. Il confirme : cartouche verticale,
console frontale, meuble en bois continu, hiérarchie héro → jeux → activité et
navigation minimale.

### 31.8 Verdict des passes finales

- **Visual Review** : accepté, non bloquant. Usure crédible et discrète,
  console plus réaliste, commode convaincante et moule canonique intact.
- **Architecture Review** : accepté sans P1 ni P2. Deux P3 documentés : le
  flottement reconstruit encore le sous-arbre de la cartouche héroïque, isolé
  par `RepaintBoundary`, et l’activité récente `shrinkWrap` reste linéaire pour
  une bibliothèque exceptionnellement grande.
- **Tests Review** : verdict ciblé GREEN, `+24`, analyze sans problème et diff
  check vide. La suite Hub globale reste explicitement rouge à `+200 -26` pour
  les fixtures Smart Tiles V1 devenues incompatibles avec la précondition V6.

Écarts visuels restants, non bloquants :

- à mi-échange, les connecteurs des cartouches entrante et sortante se
  chevauchent légèrement ;
- l’état vide conserve un CTA explicite et sépare donc davantage la tablette de
  la niche ;
- le golden d’insertion capture l’état intermédiaire à 300 ms, pas le point
  exact `1.0` juste avant lancement ;
- sur 320 × 568, il faut défiler pour voir la totalité des cartouches, ce qui
  est le comportement responsive prévu.

### 31.9 Auto-review finale

- cartouche principale et niche : **même `AveluneCartridge`** ;
- ratio : **une constante `0.7`** ;
- ajout : **même composant et même ratio** ;
- orientation : **verticale, frontale, sans rotation** ;
- console : **frontale, symétrique, matière et usure localisée** ;
- commode : **tablette, montants, niche, plinthe et tiroirs continus** ;
- données fictives de production : **aucune** ;
- flow import/lancement contourné : **non** ;
- modèle persistant : **inchangé** ;
- état vide, sans sauvegarde et invalide : **préservés** ;
- animations réduites : **respectées** ;
- boutique, succès, Découvrir : **absents** ;
- fichier temporaire dans le dépôt : **aucun** ;
- commentaire de code ajouté : **aucun**.

### 31.10 Evidence Pack final V0.3

#### Git diff --stat

<!-- V03_DIFF_STAT_START -->
```text
 .../lib/src/ui/avelune/avelune_cartridge.dart      |  85 ++-
 .../lib/src/ui/avelune/avelune_console.dart        | 697 ++++++++++++-----
 .../lib/src/ui/avelune/avelune_game_details.dart   |  71 +-
 .../src/ui/avelune/avelune_game_presentation.dart  |  25 +
 .../lib/src/ui/avelune/avelune_mobile_home.dart    | 650 ++++++++++++----
 .../lib/src/ui/avelune/avelune_theme.dart          |  16 +
 apps/pokemap_hub/pubspec.yaml                      |   2 +
 .../test/ui/avelune_cartridge_test.dart            |  32 +
 .../test/ui/avelune_mobile_home_golden_test.dart   | 124 ++-
 .../test/ui/avelune_mobile_home_test.dart          | 149 +++-
 .../test/ui/goldens/avelune/details_390x844.png    | Bin 79387 -> 214937 bytes
 .../test/ui/goldens/avelune/empty_390x844.png      | Bin 80562 -> 191707 bytes
 .../test/ui/goldens/avelune/exchange_390x844.png   | Bin 121611 -> 254458 bytes
 .../test/ui/goldens/avelune/home_320x568.png       | Bin 61622 -> 126046 bytes
 .../test/ui/goldens/avelune/home_390x844.png       | Bin 113331 -> 252098 bytes
 .../test/ui/goldens/avelune/inserting_390x844.png  | Bin 109872 -> 247238 bytes
 .../test/ui/goldens/avelune/no_save_430x932.png    | Bin 132210 -> 298501 bytes
 ...avelune_ui_01_mobile_console_home_experience.md | 845 +++++++++++++++++++++
 18 files changed, 2305 insertions(+), 391 deletions(-)
```
<!-- V03_DIFF_STAT_END -->

#### Git diff --name-only

<!-- V03_DIFF_NAMES_START -->
```text
apps/pokemap_hub/lib/src/ui/avelune/avelune_cartridge.dart
apps/pokemap_hub/lib/src/ui/avelune/avelune_console.dart
apps/pokemap_hub/lib/src/ui/avelune/avelune_game_details.dart
apps/pokemap_hub/lib/src/ui/avelune/avelune_game_presentation.dart
apps/pokemap_hub/lib/src/ui/avelune/avelune_mobile_home.dart
apps/pokemap_hub/lib/src/ui/avelune/avelune_theme.dart
apps/pokemap_hub/pubspec.yaml
apps/pokemap_hub/test/ui/avelune_cartridge_test.dart
apps/pokemap_hub/test/ui/avelune_mobile_home_golden_test.dart
apps/pokemap_hub/test/ui/avelune_mobile_home_test.dart
apps/pokemap_hub/test/ui/goldens/avelune/details_390x844.png
apps/pokemap_hub/test/ui/goldens/avelune/empty_390x844.png
apps/pokemap_hub/test/ui/goldens/avelune/exchange_390x844.png
apps/pokemap_hub/test/ui/goldens/avelune/home_320x568.png
apps/pokemap_hub/test/ui/goldens/avelune/home_390x844.png
apps/pokemap_hub/test/ui/goldens/avelune/inserting_390x844.png
apps/pokemap_hub/test/ui/goldens/avelune/no_save_430x932.png
documentation/reports/avelune/avelune_ui_01_mobile_console_home_experience.md
```
<!-- V03_DIFF_NAMES_END -->

#### Git status avant commit

<!-- V03_STATUS_START -->
```text
 M apps/pokemap_hub/lib/src/ui/avelune/avelune_cartridge.dart
 M apps/pokemap_hub/lib/src/ui/avelune/avelune_console.dart
 M apps/pokemap_hub/lib/src/ui/avelune/avelune_game_details.dart
 M apps/pokemap_hub/lib/src/ui/avelune/avelune_game_presentation.dart
 M apps/pokemap_hub/lib/src/ui/avelune/avelune_mobile_home.dart
 M apps/pokemap_hub/lib/src/ui/avelune/avelune_theme.dart
 M apps/pokemap_hub/pubspec.yaml
 M apps/pokemap_hub/test/ui/avelune_cartridge_test.dart
 M apps/pokemap_hub/test/ui/avelune_mobile_home_golden_test.dart
 M apps/pokemap_hub/test/ui/avelune_mobile_home_test.dart
 M apps/pokemap_hub/test/ui/goldens/avelune/details_390x844.png
 M apps/pokemap_hub/test/ui/goldens/avelune/empty_390x844.png
 M apps/pokemap_hub/test/ui/goldens/avelune/exchange_390x844.png
 M apps/pokemap_hub/test/ui/goldens/avelune/home_320x568.png
 M apps/pokemap_hub/test/ui/goldens/avelune/home_390x844.png
 M apps/pokemap_hub/test/ui/goldens/avelune/inserting_390x844.png
 M apps/pokemap_hub/test/ui/goldens/avelune/no_save_430x932.png
 M documentation/reports/avelune/avelune_ui_01_mobile_console_home_experience.md
?? apps/pokemap_hub/assets/avelune/artwork/fallback_moonlit_path.webp
?? apps/pokemap_hub/assets/avelune/materials/aged_abs_wear.webp
?? apps/pokemap_hub/assets/avelune/materials/brushed_brass.webp
?? apps/pokemap_hub/assets/avelune/materials/dark_walnut_satin.webp
?? apps/pokemap_hub/assets/avelune/materials/matte_abs_grain.webp
?? apps/pokemap_hub/test/fixtures/avelune/covers/demo.webp
?? apps/pokemap_hub/test/fixtures/avelune/covers/selbrume.webp
?? apps/pokemap_hub/test/fixtures/avelune/covers/train.webp
?? documentation/reports/editor/smart_tiles_tiled_imports_and_performance_audit_2026-08-04.md
```
<!-- V03_STATUS_END -->

#### Git diff --check

```text
Sortie : <vide>
```

#### Fichiers temporaires

```text
Sortie : <vide>
```

#### Hygiène Markdown

```text
Markdown hygiene: 1 new Markdown files exceed the default limit of 0.
Use POKEMAP_MARKDOWN_MAX_NEW only when the user explicitly approved a bounded bulk documentation task.
```

Cet échec est extérieur au lot : le seul nouveau Markdown est
`documentation/reports/editor/smart_tiles_tiled_imports_and_performance_audit_2026-08-04.md`, non suivi et jamais modifié par AVELUNE-UI-01. Le présent rapport
existait déjà et est seulement mis à jour.

### 31.11 Git et publication

Le Gate final ci-dessus est capturé avant commit. L’utilisateur a explicitement
autorisé le commit et le push après cette reprise. Le staging doit être limité
aux chemins Avelune et au présent rapport ; le rapport Smart Tiles non suivi ne
doit pas être ajouté. Le hash de commit et le résultat du push seront fournis
dans le compte rendu final de la conversation, car un commit ne peut pas
contenir son propre hash.
