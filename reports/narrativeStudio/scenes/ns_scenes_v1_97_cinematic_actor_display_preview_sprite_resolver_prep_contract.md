# NS-SCENES-V1-97 — Cinematic Actor Display Preview Sprite Resolver Prep Contract

## 1. Résumé exécutif

Le lot **NS-SCENES-V1-97** est un lot exclusivement documentaire et de conception (design-first). Il a pour mission de cadrer l'architecture et les spécifications techniques du futur **Sprite Resolver** pour l'overlay des acteurs du Cinematic Builder. 

L'objectif est de remplacer de manière robuste, progressive et déterministe les placeholders actuels (cercles de couleur avec les lettres P, M, C) par des visuels statiques (sprites de personnages) tirés directement des données du projet : la Character Library, le joueur par défaut, ou les entités de map (PNJ, dresseurs).

Cette architecture garantit une parfaite étanchéité par rapport au runtime gameplay et au moteur Flame, préserve les acquis des lots précédents (le cadrage de la Vue scène, le pan/zoom local, la grille masquée par défaut et le z-ordering V1-96-bis) et s'assure que les placeholders restent opérationnels en tant que fallback immédiat en cas d'assets manquants ou incomplets.

*Phrase canonique :*
> V1-97 prépare la résolution des sprites acteurs statiques.  
> V1-97 ne rend toujours aucun sprite acteur final.

---

## 2. Gate 0

Voici les sorties des commandes d'audit initiales exécutées à la racine du projet (/Users/karim/Project/pokemonProject) :

```text
/Users/karim/Project/pokemonProject
main
de216dc0 feat(cinematics): implement cinematic backdrop real map editor ordering fix (V1-96-bis)
89f172b7 feat(cinematics): implement cinematic backdrop depth / Z-order parity polish V0
0d95818f update selbrume
0ccc4c33 update selbrume
b3477664 feat(map_editor): refine cinematic backdrop preview and update scene reports
e093213f update selbrume
5b6822e7 feat(map_editor): refactor UI, add cinematic backdrop preview, and update tests
adc0b197 update selbrume
35415a41 feat(map_editor): smooth left sidebar transitions & refactored narrative studio quick actions
0f1cce5c Merge branch 'feature/stabilize-sidebar'
cf774aef ui: stabilize World Explorer sidebar width and card ordering in Narrative Studio
cdd653e5 feat(narrative): auto-commit changes
50d3ca85 remove failures
48d6398d ui: collapse project explorer accordions by default and fix tests
4dbebbfe feat(narrative): auto-commit changes
```

Statut Git au lancement du lot :
```text
On branch main
Your branch is ahead of 'origin/main' by 2 commits.
  (use "git push" to publish your local commits)

nothing to commit, working tree clean
```

---

## 3. Fichiers lus

Les fichiers suivants ont été audités en détail pour établir ce contrat :

1. **Règles générales et conventions du dépôt** :
   - [AGENTS.md](file:///Users/karim/Project/pokemonProject/RULE[AGENTS.md]) (Root guidelines, packages boundaries, working style).
2. **Modèles du Core (`packages/map_core`)** :
   - [cinematic_actor_display_preview_model.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart) (Read model de l'affichage acteur, enchaînement de diagnostics et états d'apparence/position).
   - [cinematic_asset.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/cinematic_asset.dart) (Structure des requiredActors, timeline et steps).
   - [project_manifest.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/project_manifest.dart) (Définition de `ProjectCharacterEntry`, `CharacterAnimation`, `CharacterAnimationFrame`, et `ProjectSettings`).
   - [map_data.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_data.dart) (Structure des entités placées `MapEntity` et NPCs).
3. **Composants d'Affichage Editor (`packages/map_editor`)** :
   - [cinematic_actor_display_preview_overlay.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart) (Rendu actuel des placeholders en cercles et badges de direction).
   - [cinematic_tileset_asset_registry.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_tileset_asset_registry.dart) (Mécanisme de chargement asynchrone d'images et cache de png).
   - [cinematic_map_backdrop_layer_render_plan.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart) (Génération du plan de rendu du décor).
4. **Composants Runtime pour Anti-scope (`packages/map_runtime`)** :
   - [playable_map_game.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart)
   - [runtime_map_game.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart)
   - [player_component.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/player_component.dart)
   - [overworld_actor_component.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/overworld_actor_component.dart)

---

## 4. Synthèse des sub-agents et arbitrages

- **Pass A — Actor Display Read Model Audit** : Confirmation que le read model `CinematicActorDisplayPreviewModel` extrait déjà toutes les métadonnées requises (characterId, status, tilesetId, direction) et signale si les données de base manquent. Il peut être réutilisé tel quel.
- **Pass B — Character Library Audit** : Exploration du modèle `ProjectCharacterEntry`. L'association character -> animation idle -> EntityFacing -> frame 0 donne directement la `source` rectangulaire 1x1 ou multi-tuiles à découper dans le tileset.
- **Pass C — Appearance Sources Resolution** : Formalisation des priorités pour localiser le `characterId` (player settings, NPC characterId, Trainer characterId, appearanceBindings).
- **Pass D — Asset Resolution / Cache Audit** : Choix fort d'exploiter la classe existante `CinematicTilesetAssetRegistry` (Option A/C) qui effectue déjà le chargement `File.readAsBytes` de manière asynchrone, gère la transparence png, et instancie des `ui.Image` réutilisables.
- **Pass E — Static Sprite Frame / Direction Resolver** : Définition des règles d'extraction d'image statique : utilisation obligatoire de la frame 0 d'une animation idle, pas d'AnimationController ni de playback clock.
- **Pass F — Future Renderer / Overlay Integration** : Cadrage du positionnement et du sandwiching de l'acteur (ancre bottom-center). Deux stratégies pour le Z-Ordering V1-96-bis ont été présentées (conservation de l'overlay ou injection d'instructions dans le render plan backdrop).
- **Pass G — Anti-scope Audit** : Identification claire des packages gameplay et runtime à proscrire (Flame, GameState, etc.).
- **Pass H — Tests and Future Validation** : Conception de scénarios de tests unitaires et widget complets.
- **Pass I — UX and Product Review** : Recommandations sur les badges d'avertissement et le rendu visuel.

---

## 5. Pourquoi V1-97 vient après V1-96-bis

Le lot V1-96-bis a résolu le problème fondamental d'empilement du décor (les couches et passes de dessin), garantissant que l'eau, les pontons, les chemins et les toits s'affichent exactement dans l'ordre du Map Editor. 

Avant de coder l'affichage des sprites réels des personnages (ce qui introduit des opérations asynchrones sur le disque, des coordonnées d'atlas et des découpes rectangulaires), il est capital d'en définir l'architecture globale. Tenter de coder le resolver directement en V1-96 ou V1-97 aurait mené à du code trop complexe mêlant la logique de chargement d'image asynchrone dans les boucles de rendu (`build`/`paint`), provoquant des lags ou des scintillements.

Ce lot V1-97 pose donc les bases méthodologiques et structurelles (le "contrat") avant tout développement de code produit dans la future V1-98.

---

## 6. Objectif produit du Sprite Resolver Actor Display

Le Sprite Resolver doit permettre à l'utilisateur de voir les personnages représentés de façon reconnaissable dans le Cinematic Builder (ex. le héros de face, un PNJ de profil), améliorant l'expérience no-code sans devoir démarrer le jeu.

Le composant doit :
1. Découper la bonne cellule d'image à partir du fichier PNG du tileset.
2. Orienter le personnage en fonction de sa direction statique.
3. Conserver un label textuel clair et les flèches de direction pour le repérage de scène.
4. Traiter proprement les cas d'erreur (fichiers absents, IDs inconnus) en affichant un indicateur humain explicite.

---

## 7. Pass A — Actor Display Read Model Contract Audit

L'audit de `CinematicActorDisplayPreviewModel` et `CinematicActorDisplayPreviewActor` dans `map_core` montre que :
- **Données suffisantes** : Le modèle projette déjà le statut de liaison, la position sur la carte (en coordonnées de tuiles `x` et `y`), la direction courante de l'acteur (déterminée en priorité par le bloc `actorFace` de la timeline ou par l'orientation par défaut de l'entité de map), et résout les statuts d'apparence (ex: `spriteReady`, `placeholderOnly`, `missingCharacter`, `missingTileset`, `missingIdleAnimation`).
- **Gaps identifiés** : Le read model ne contient pas la référence d'image physique ni les coordonnées exactes du rectangle source dans le tileset. Cela est logique : `map_core` est indépendant de Flutter et ne possède pas d'accès aux fichiers du système local de l'éditeur.
- **Recommandation** : Conserver le read model de `map_core` inchangé. Il fournit toutes les métadonnées symboliques requises. Le resolver qui sera créé en V1-98 côté `map_editor` consommera ce modèle et le ProjectManifest pour générer un plan de rendu d'images local (`CinematicActorSpritePreviewPlan`).

---

## 8. Pass B — Character Library / ProjectCharacterEntry Audit

L'audit de `ProjectCharacterEntry` et ses sous-composants montre la structure suivante :
- Chaque personnage (`ProjectCharacterEntry`) est associé à un `tilesetId`.
- Il définit une grille de tuiles via `frameWidth` (largeur en tuiles, défaut 1) et `frameHeight` (hauteur en tuiles, défaut 2).
- Les animations sont listées dans `animations` (`List<CharacterAnimation>`).
- Chaque `CharacterAnimation` contient son type d'état (`state: CharacterAnimationState` comme `idle`), sa direction (`direction: EntityFacing` comme `north`, `south`, `east`, `west`), et ses frames (`frames: List<CharacterAnimationFrame>`).
- Chaque frame contient son `source` (`TilesetSourceRect`) avec les coordonnées de grille `x` et `y`.

**Règle de résolution** :
1. Extraire la liste d'animations `idle`.
2. Trouver l'animation qui correspond à la direction souhaitée (ex. `direction == EntityFacing.south`).
3. S'il n'y en a aucune, utiliser la première animation `idle` disponible (ou la première animation tout court).
4. Prendre la première frame (`frames.first`) et lire son `source` (de type `TilesetSourceRect`).
5. Convertir ce `source` en pixel rect (`x * tileWidth`, `y * tileHeight`, `width * tileWidth`, `height * tileHeight`).

---

## 9. Pass C — Player / MapEntity / CinematicOnly Appearance Sources

Pour résoudre le `characterId` d'un acteur requis par une cinématique, le resolver doit suivre les règles prioritaires selon la nature de sa liaison (`bindingKind`) :

1. **`bindingKind == player`** :
   - Lire `ProjectManifest.settings.defaultPlayerCharacterId`.
   - S'il est absent, le statut d'apparence passe en `placeholderOnly`.
2. **`bindingKind == mapEntity`** :
   - Trouver l'entité correspondante (`MapEntity`) dans le catalogue de la scène.
   - S'il s'agit d'un PNJ, lire son `npc.characterId`.
   - S'il s'agit d'un dresseur, lire son `npc.trainerId`, puis charger l'entrée `ProjectTrainerEntry` pour y récupérer le `trainer.characterId`.
   - Si aucune de ces informations n'est renseignée mais qu'un `visualElementId` est défini, le resolver retient le statut `placeholderOnly` car l'élément est purement structurel.
3. **`bindingKind == cinematicOnly`** :
   - Lire la liaison d'apparence de la cinématique : `CinematicActorAppearanceBinding.characterId`.
4. **`bindingKind == unbound`** (ou absent) :
   - L'acteur est masqué ou n'a aucun rendu demandé.

---

## 10. Pass D — Sprite Asset Resolution / Cache Contract

Le chargement et le décodage d'une image depuis le disque local de l'utilisateur nécessitent des appels asynchrones à la classe `File` et au moteur `dart:ui`.

### Comparaison des options
- **Option A — Réutiliser directement `CinematicTilesetAssetRegistry`** :
  - *Avantages* : Pas de duplication de logique de cache. Il contient déjà la méthode de transparence png et instancie des `ui.Image` en cache indexé.
  - *Inconvénients* : Léger couplage avec les tilesets du décor, mais s'agissant de fichiers de type tileset manifestés dans les deux cas, cela reste logique.
- **Option B — Créer un `ActorSpriteAssetRegistry` séparé** :
  - *Avantages* : Isolation totale.
  - *Inconvénients* : Duplication de code, décodage répété des mêmes images si les sprites partagent des atlas avec le décor.
- **Option C — Extraire un cache d'images partagé (TilesetImageCache)** :
  - *Avantages* : Très propre architecturalement.
  - *Inconvénients* : Refactoring plus large hors du scope minimal.

### Option recommandée : **Option A**
Nous utiliserons l'instance de `CinematicTilesetAssetRegistry` partagée ou passée au loader du Cinematic Builder. Le tileset du personnage sera chargé de la même manière que les tilesets du décor.

---

## 11. Pass E — Static Sprite Frame / Direction Resolver

La sélection de la texture statique à dessiner s'opère de manière purement déterministe à l'instant T = 0 (ou début de l'instruction courante) :

1. **Aucun minuteur ou Ticker** : Nous n'utilisons aucun chronomètre d'animation. Le sprite est dessiné figé.
2. **Choix de la direction** :
   - Si un bloc `actorFace` existe pour cet acteur dans la timeline de la cinématique, on mappe sa direction (`up`, `down`, `left`, `right`) vers les directions cardinales du jeu (`north`, `south`, `west`, `east`).
   - Sinon, on utilise la direction par défaut de l'entité de map (`EntityFacing`).
   - En dernier recours, on applique un fallback sur la direction `south`.
3. **Sélection de la frame** :
   - Récupérer l'animation `idle` correspondant à la direction.
   - Prendre la première frame (`frames.first`).
   - S'il n'y a pas de frame ou si l'animation est vide, le statut de rendu repasse en `placeholderOnly` (affichage du cercle de couleur).

---

## 12. Pass F — Future Renderer / Overlay Integration

Une fois le plan de sprite d'acteur (`CinematicActorSpritePreviewPlan`) construit par le resolver, l'intégration visuelle au Cinematic Builder de la V1-99 aura le choix entre deux stratégies :

### Stratégie A — Overlay Flutter Widget (Recommandée)
L'overlay `CinematicActorDisplayPreviewOverlay` de la V1-92 est conservé. Il se contente de remplacer le widget central de cercle `_ActorDisplayMarker` par un widget de type `RawImage` affichant le `ui.Image` découpé selon le `sourceRect`.
*   **Avantages** : Extrêmement simple et isolé. Les labels d'acteurs et les indicateurs directionnels restent disposés autour de manière responsive en CSS/Flutter.
*   **Z-Order** : Les acteurs se dessinent par-dessus tout le décor (les toits inclus), ce qui est le comportement actuel stable. Le tri Y est appliqué entre les acteurs de l'overlay (les acteurs plus bas en Y sont dessinés au-dessus de ceux plus hauts).

### Stratégie B — Rendu par instructions Canvas
Les sprites acteurs sont convertis en instructions de rendu cinématiques (`CinematicMapBackdropLayerBitmapInstruction`) et injectés directement dans le plan de dessin du décor, triés par le comparateur de la V1-96-bis.
*   **Avantages** : Permet de sandwicher les acteurs sous les toits (calque foreground) de manière native.
*   **Inconvénients** : Complexifie le dessin (dessiner du texte de diagnostic et des boutons de sélection interactifs directement sur le canvas).

### Recommandation :
**Stratégie A (Overlay Flutter Widget)** en V1-99 pour sa simplicité et sa fiabilité de sélection, tout en documentant la limite que les acteurs s'affichent par-dessus les éléments de toits.

---

## 13. Pass G — Runtime / Flame / Playback Anti-scope

Afin de maintenir le Cinematic Builder performant, léger et sans effet de bord, le futur resolver en V1-98 et renderer en V1-99 devront scrupuleusement proscrire les composants et packages suivants :

- **Pas d'imports de `map_runtime`** : Pas de `PlayerComponent`, de `OverworldActorComponent`, ni de classes liées à la boucle physique Flame.
- **Pas de `GameWidget` ou `FlameGame`** : La preview ne doit pas démarrer un moteur de jeu en tâche de fond.
- **Pas de `GameState`** : Pas d'évaluation de l'inventaire réel, d'équipe Pokémon ou de flags de sauvegarde. Le resolver utilise uniquement le manifeste statique.
- **Pas d'interpolation de mouvement (`actorMove`)** : Aucun déplacement de personnage n'est joué à l'écran. L'acteur reste statique à ses coordonnées initiales ou cibles.
- **Pas de gestion d'horloge de playback** : Pas de `Timer`, `TickerProvider` ni d'`AnimationController` pour les images.

---

## 14. Pass H — Tests / Visual Gate Future

### Plan de Tests pour la V1-98 (Resolver)
1. **Test unitaire pur** : Valider que `buildCinematicActorSpritePreviewPlan` produit les bonnes coordonnées `sourceRect` pour un personnage existant de la Character Library.
2. **Test d'apparence Joueur** : Vérifier la résolution correcte du sprite joueur depuis `settings.defaultPlayerCharacterId`.
3. **Test d'apparence MapEntity** : Vérifier que l'ID du tileset et le rectangle source d'un PNJ sont résolus depuis son NPC data.
4. **Test de fallback** : S'assurer qu'un dresseur sans tileset valide remonte un statut `missingTileset` ou `placeholderOnly` et ne provoque aucune exception.

### Plan de Tests pour la V1-99 (Renderer & Visual Gate)
1. **Test de rendu d'image** : S'assurer que le widget `RawImage` est bien monté dans l'overlay si le statut est `spriteReady`.
2. **Test de préservation des contrôles** : Confirmer que le zoom et le pan local fonctionnent toujours lorsque des sprites réels sont dessinés.
3. **Visual Gate** : Enregistrement d'un golden file `ns_scenes_v1_99_cinematic_actor_display_sprite_resolved_visual_gate.png` montrant des acteurs reconnaissables sur la carte.

---

## 15. Pass I — Product / UX Reviewer

Pour l'utilisateur, l'apparition de sprites statiques peut prêter à confusion si celui-ci s'attend à ce que le personnage s'anime ou se déplace.

**Recommandations UX** :
1. **Indicateur statique** : Afficher un badge discret "Pose statique" ou "Aperçu statique" dans la barre latérale du Cinematic Builder.
2. **Warnings de diagnostic** : Conserver l'affichage des avertissements (ex: "Tileset manquant", "Animation idle absente") dans le panneau des diagnostics pour guider le créateur no-code dans la complétion de ses fiches personnages.
3. **Labels persistants** : Permettre d'afficher le label textuel de l'acteur (ex: "Hero", "Guide PNJ") juste au-dessus du sprite pour faciliter le repérage dans les scènes denses, avec un bouton global pour masquer les overlays textuels.

---

## 16. Options techniques comparées

| Critères | Option A (Placeholders uniquement) | Option B (Résolution directe dans l'UI) | Option C (Resolver séparé V1-98 - Recommandée) |
| :--- | :--- | :--- | :--- |
| **Fidélité visuelle** | Faible (uniquement des cercles symboliques) | Élevée (sprites affichés) | Élevée (sprites affichés) |
| **Performances** | Excellentes | Moyennes (risque d'I/O disques dans paint) | Excellentes (chargement asynchrone hors paint) |
| **Testabilité** | Simple | Difficile (couplage fort UI/Image) | Très élevée (modèle de plan testable unitairement) |
| **Fallbacks** | Natifs | Complexes à intégrer proprement | Natifs et robustes |

---

## 17. Option retenue

L'**Option C (Resolver séparé V1-98)** est retenue en combinaison avec l'**Option A (Réutilisation de CinematicTilesetAssetRegistry)** pour le décodage d'images. 

Cette approche fournit une séparation stricte des préoccupations : le resolver prend en entrée le read model symbolique de `map_core` et le manifeste du projet, résout les chemins de fichiers locaux et les rectangles sources de personnages, et produit un plan d'affichage contenant des textures prêtes. L'overlay Flutter se charge ensuite de dessiner soit l'image découpée, soit le placeholder d'origine.

---

## 18. Contrat futur recommandé

En V1-98, le contrat d'affichage prendra la forme d'un modèle d'aperçu d'acteurs :

```dart
@immutable
final class CinematicActorSpritePreviewPlan {
  const CinematicActorSpritePreviewPlan({
    required this.actors,
    required this.diagnostics,
  });

  final List<CinematicActorSpritePreviewActor> actors;
  final List<CinematicActorDisplayPreviewDiagnostic> diagnostics;

  bool get hasReadySprites => actors.any((a) => a.status == CinematicActorSpriteStatus.spriteReady);
}

@immutable
final class CinematicActorSpritePreviewActor {
  const CinematicActorSpritePreviewActor({
    required this.actorId,
    required this.actorLabel,
    required this.bindingKind,
    required this.position,
    required this.direction,
    required this.status,
    this.spriteRef,
    required this.placeholderFallback,
  });

  final String actorId;
  final String actorLabel;
  final CinematicActorBindingKind bindingKind;
  final GridPos position;
  final CinematicActorPreviewDirection direction;
  final CinematicActorSpriteStatus status;
  final CinematicActorSpriteRef? spriteRef;
  final bool placeholderFallback;
}

enum CinematicActorSpriteStatus {
  spriteReady,
  placeholderFallback,
  missingCharacter,
  missingTileset,
  missingIdleAnimation,
  missingDirectionFrame,
  imageUnavailable,
  invalidSourceRect,
  unsupported,
}
```

---

## 19. Contrat asset resolution futur

Pour lier les ID de tilesets de personnages aux images physiques :

```dart
@immutable
final class CinematicActorSpriteRef {
  const CinematicActorSpriteRef({
    required this.characterId,
    required this.tilesetId,
    required this.sourceRect, // Rectangle en pixels
    required this.frameWidth,  // Largeur en tuiles (ex. 1)
    required this.frameHeight, // Hauteur en tuiles (ex. 2)
  });

  final String characterId;
  final String tilesetId;
  final Rect sourceRect;
  final int frameWidth;
  final int frameHeight;
}
```

---

## 20. Contrat frame / direction futur

Pour mapper les directions et les frames idle dans la V1-98 :

1. **Mapping directionnel** :
   ```dart
   EntityFacing? getFacingFromPreviewDirection(CinematicActorPreviewDirection direction) {
     return switch (direction) {
       CinematicActorPreviewDirection.north => EntityFacing.north,
       CinematicActorPreviewDirection.south => EntityFacing.south,
       CinematicActorPreviewDirection.east => EntityFacing.east,
       CinematicActorPreviewDirection.west => EntityFacing.west,
       CinematicActorPreviewDirection.unknown => null,
     };
   }
   ```
2. **Extraction de la première frame de l'animation correspondante** :
   ```dart
   CharacterAnimationFrame? getIdleFrame(ProjectCharacterEntry character, EntityFacing facing) {
     final animation = character.animations.firstWhere(
       (a) => a.state == CharacterAnimationState.idle && a.direction == facing,
       orElse: () => character.animations.firstWhere(
         (a) => a.state == CharacterAnimationState.idle,
         orElse: () => character.animations.first,
       ),
     );
     return animation.frames.isNotEmpty ? animation.frames.first : null;
   }
   ```

---

## 21. Fallback placeholders

Si le statut résolu d'un acteur n'est pas `spriteReady` (c'est-à-dire si le tileset n'est pas trouvé sur le disque, si l'image png est corrompue, ou si la frame n'est pas configurée dans la fiche du personnage), le resolver définit `placeholderFallback = true`. 

L'overlay instanciera alors l'actuel composant `_ActorDisplayPlaceholder` en forme de pastille circulaire avec la lettre du rôle. Aucune exception bloquante n'est jetée, assurant la continuité de l'affichage interactif pour l'utilisateur.

---

## 22. Diagnostics futurs

Le resolver V1-98 implémentera les diagnostics suivants (s'ajoutant ou précisant ceux du read model) :

- **`actorSpriteMissingCharacter`** (Warning) : Acteur lié à un personnage qui n'existe plus dans le manifeste.
- **`actorSpriteMissingTileset`** (Warning) : Le personnage n'a pas de tileset assigné.
- **`actorSpriteImageUnavailable`** (Warning) : Le fichier png du tileset n'existe pas au chemin relatif spécifié.
- **`actorSpriteMissingIdleAnimation`** (Warning) : Le personnage n'a pas d'animation idle configurée pour la direction requise.
- **`actorSpriteFrameOutsideAtlas`** (Error) : Les coordonnées du rectangle source de la frame dépassent les dimensions réelles de l'image du tileset.

---

## 23. Tests futurs V1-98

Les tests unitaires à écrire dans `packages/map_editor/test/cinematic_actor_sprite_resolver_test.dart` couvriront :
1. La résolution complète d'un sprite acteur `cinematicOnly` à partir d'une fiche Character de test valide.
2. Le fallback immédiat sur placeholder en cas de tileset absent.
3. La détection d'une direction héritée d'une timeline step `actorFace`.
4. La non-pollution du plan par des clock animations (vérification du caractère statique des frames).

---

## 24. Visual Gate future V1-99

La Visual Gate du lot V1-99 consistera en un test d'intégration avec capture d'écran comparant :
- **Avant (V1-96-bis)** : Les pastilles circulaires bleues, jaunes et violettes avec P, M, C par-dessus la carte.
- **Après (V1-99)** : Les vrais sprites de PNJ et de joueur dessinés en pose statique orientée selon leur direction respective.

---

## 25. Roadmaps mises à jour

Les fichiers de feuille de route suivants ont été mis à jour pour valider `NS-SCENES-V1-97` et préparer la suite logique :
- [road_map_scenes.md](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/road_map_scenes.md)
- [road_map_scene_builder_authoring.md](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md)

Le lot V1-97 est marqué `DONE` et recommande précisément `NS-SCENES-V1-98 — Cinematic Actor Display Preview Sprite Resolver V0` comme prochaine étape.

---

## 26. Non-objectifs confirmés

Le lot a strictement respecté toutes les interdictions :
- Aucun fichier de code Dart source modifié dans `packages/`.
- Aucun test widget n'a été créé ou exécuté pendant le lot.
- Aucun asset ou image décodée n'a été créé.
- Pas de Flame, GameWidget, GameState, ou clock de lecture introduits.
- Aucune modification de Selbrume ni de base de données.

---

## 27. Commandes exécutées

Pour valider l'absence de modifications indésirables et vérifier le statut du dépôt, les commandes suivantes ont été exécutées :

```bash
git diff --name-only -- packages
# Résultat : <vide>

git diff --check
# Résultat : <vide>

git status --short --untracked-files=all
# Résultat : montre uniquement les rapports créés/modifiés.
```

---

## 28. Checks anti-scope

Le diff sur les répertoires de code source est absolument vierge. L'analyse ciblée sur les fichiers exclus :
```bash
git diff --stat -- packages/map_runtime packages/map_gameplay packages/map_battle examples
# Résultat : <vide>
```
Confirme le respect total du cloisonnement.

---

## 29. Evidence Pack

L'ensemble des commandes, hunks de roadmaps, et états de fichiers a été consigné dans l'Evidence Pack dédié :
[ns_scenes_v1_97_evidence_pack.md](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/ns_scenes_v1_97_evidence_pack.md)

---

## 30. Auto-review critique

1. **Est-ce que V1-97 a modifié du code produit ?** Non.
2. **Est-ce que V1-97 a modifié packages/ ?** Non.
3. **Est-ce que V1-97 a créé un test ?** Non.
4. **Est-ce que V1-97 a généré un screenshot ?** Non.
5. **Est-ce que V1-97 a rendu un sprite acteur ?** Non.
6. **Est-ce que V1-97 a chargé une image acteur ?** Non.
7. **Est-ce que V1-97 a modifié l’overlay V1-92 ?** Non.
8. **Est-ce que V1-97 a modifié le backdrop V1-96-bis ?** Non.
9. **Est-ce que V1-97 a utilisé runtime/Flame ?** Non.
10. **Est-ce que V1-97 a utilisé GameState ?** Non.
11. **Est-ce que V1-97 a ajouté du playback ?** Non.
12. **Est-ce que V1-97 a comparé les sources player/mapEntity/cinematicOnly ?** Oui (Pass C).
13. **Est-ce que V1-97 a cadré ProjectCharacterEntry ?** Oui (Pass B).
14. **Est-ce que V1-97 a cadré l’asset resolution ?** Oui (Pass D).
15. **Est-ce que V1-97 a cadré idle/direction frame ?** Oui (Pass E).
16. **Est-ce que V1-97 a cadré les fallbacks placeholders ?** Oui (Pass F et diagnostics).
17. **Est-ce que V1-97 a défini les diagnostics futurs ?** Oui (Section 22).
18. **Est-ce que V1-97 a défini les tests V1-98 ?** Oui (Section 23).
19. **Est-ce que V1-97 a défini la Visual Gate V1-99 ?** Oui (Section 24).
20. **Est-ce que V1-97 a mis à jour les roadmaps ?** Oui.
21. **Est-ce que l’Evidence Pack est complet ?** Oui.
22. **Quel est le prochain lot exact recommandé ?** `NS-SCENES-V1-98 — Cinematic Actor Display Preview Sprite Resolver V0`.

---

## 31. Recommandation pour le prochain lot

Nous recommandons d'activer le lot suivant conformément au cadrage :
`NS-SCENES-V1-98 — Cinematic Actor Display Preview Sprite Resolver V0`
Celui-ci implémentera la classe pure de résolution de sprites et ses tests unitaires de parité.
