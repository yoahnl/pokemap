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
