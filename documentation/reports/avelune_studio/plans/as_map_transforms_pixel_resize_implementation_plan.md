# Décalage au pixel et redimensionnement des décors — plan d’implémentation

> Exécution autorisée par Yoahn après remise du plan. Application de `skills/subagent-driven-development/SKILL.md`, revues et preuves lot par lot. Les cases non cochées restent à réaliser ; ce document ne décrit pas une fonctionnalité déjà livrée.

**Objectif :** déplacer les occurrences de décors au pixel du projet près, puis les étirer ou les rétrécir indépendamment en largeur et en hauteur, avec un résultat cohérent dans Avelune Studio, le Player, les collisions, les interactions et les exports.

**Architecture :** enrichir `MapPlacedElement`, réutiliser les transformations existantes de `map_core`, puis faire consommer cette géométrie par les systèmes actuels. Conserver le document éditable, l’historique et les ports d’authoring existants. Aucun nouveau moteur de scène ni framework de transformations.

**Stack :** Dart pur pour `map_core`, `map_gameplay`, `map_authoring` et `map_distribution` ; Flutter/Flame pour `map_runtime` et les éditeurs ; TypeScript pour `tools/pokemap_mcp`. Flame résolu actuellement : 1.38.0.

**État :** implémentation en cours après autorisation de Yoahn. Analyse initiale du 29 septembre 2026 sur `main`, SHA `df9d134ae5326b05488d5b6e3668adca59566899`. Au début de l'implémentation, seul ce plan était non suivi ; aucun fichier de production n'était modifié. Les preuves de préparation de §10 restent historiques ; le suivi d'exécution figure en §11.

## 1. Décision proposée et périmètre

Le système concerne les **occurrences de décors placées manuellement** (`MapPlacedElement`). Deux occurrences d’un même asset peuvent avoir des positions et des tailles différentes. Le PNG, l’atlas et la définition partagée de l’asset restent les sources.

| Action auteur | Comportement proposé |
| --- | --- |
| Glisser un décor | Déplacement par pas de tuile, en conservant son éventuel résidu pixel. |
| Shift + glisser | Déplacement par pas de 1 pixel du projet, quel que soit le zoom. |
| Shift + flèches, canvas focalisé | Déplacement de 1 pixel ; les champs de texte gardent leurs propres touches. |
| Poignée sur un côté | Modifier uniquement largeur ou hauteur ; le bord opposé reste fixe. |
| Poignée sur un coin | Modifier les deux dimensions ; proportions libres par défaut. |
| Redimensionnement avec Shift | Pas de 1 pixel ; sans Shift, pas de tuile sur les axes concernés. |
| Inspecteur | Position X/Y et largeur/hauteur en pixels ; saisie précise et validation avant commit. |
| Verrou de proportions | Option explicite, désactivée par défaut, pour les coins et la saisie de taille ; Shift reste réservé à la précision. Les poignées de côté restent des actions sur un seul axe. |
| « Aligner sur la grille » | Aligner explicitement l’origine sur l’intersection la plus proche, avec règle d’égalité déterministe. |
| « Taille d’origine » | Supprimer la taille personnalisée en conservant position, rotation et autres propriétés. |

Une unité est un **pixel du projet**, pas un pixel physique d’écran. Le zoom et le facteur d’affichage n’altèrent jamais la valeur sauvegardée. À un zoom fractionnaire, la netteté physique de tous les pixels n’est pas garantie ; l’échantillonnage reste sans lissage.

La « forme » couverte ici est la déformation rectangulaire, y compris très étroite ou très large, acceptée par Yoahn. Polygones, perspective, cisaillement, angles libres, édition de vertices et nine-slice sont hors périmètre. Les rotations par quarts de tour des occurrences continuent de fonctionner. `MapPlacedElement` n'a pas de propriété de flip : ce lot n'en ajoute pas. Les flips du renderer Smart Tiles sont seulement une surface de non-régression hors périmètre.

Les personnages, les tuiles peintes, les Smart Tiles, les bordures procédurales, les zones et les warps indépendants ne deviennent pas des objets librement redimensionnables. V1 : les placements générés ne sont pas transformables tant qu’ils restent gérés par leur générateur. L’UI explique cette restriction ; l’API la valide. Un éventuel détachement s’appuiera sur un flux déjà présent et prouvé, sinon sera un lot ultérieur explicite.

## 2. Audit initial : ce qui existe réellement

Les chemins ci-dessous sont relatifs à la racine `/Users/karim/Project/pokemonProject`. Les lignes sont celles du SHA audité ; les symboles sont les repères durables.

| Constat vérifié | Source et conséquence |
| --- | --- |
| Géométrie d’instance limitée à `pos` en cases et `quarterTurns` | `packages/map_core/lib/src/models/map_data.dart:224`. Ajouter les valeurs par occurrence, sans les détourner dans `properties` ou dans l’asset partagé. |
| Transformations de rotation déjà centralisées | `packages/map_core/lib/src/operations/map_placed_element_footprint.dart:18` et `:123` : `QuarterTurnGridTransform` et `QuarterTurnPixelTransform`. Ce dernier sait déjà inverse-échantillonner des tailles source/destination distinctes. |
| Un ordre visuel existe déjà | `map_placed_element_visual_order.dart:35,77,204`. Adapter hit-test et overlaps aux pixels ; conserver `visualOrder` et les tie-breaks. L’ordre de `map.placedElements` choisit aussi les interactions gagnantes. |
| Déplacement Studio déjà transactionnel | `apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_canvas_gestures.dart:49` et `:100` ; `features/map_workspace/application/editable_map_document.dart:28`. Étendre ce geste, sans sauvegarde à chaque mouvement. |
| Le déplacement ne prévisualise actuellement que le contour | `map_workspace_canvas.dart:237` et `map_canvas_overlay.dart:268`. Le sprite devra suivre la prévisualisation. |
| Studio utilise le renderer de la runtime | `apps/avelune_studio/lib/platform/rendering/studio_map_visual_widgets.dart:10`. Son `didUpdateWidget` recrée le renderer lorsque la map change : éviter une reconstruction complète à chaque événement souris. |
| Rendu et index spatial calculent chacun leurs bounds | `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:1242,1689`. Déplacer aussi les limites de culling et de recherche. |
| Collisions pixels et cases sont deux chemins | `packages/map_gameplay/lib/src/gameplay_world_state.dart:818,904` ; `collision/world_collision_storage.dart:130`. Le stockage pixel est déjà en chunks clairsemés de 32 × 32. |
| Un masque réduit peut perdre un obstacle fin | `WorldCollisionStorageBuilder.stampPackedMask` échantillonne au centre du pixel destination. Une collision conservative est nécessaire pour la réduction. |
| Les comportements sont indexés par cases | `gameplay_world_state.dart:1115,1165,1231`. Mettre à jour ensemble action, entrée/sortie, proximité et priorité. |
| Les lecteurs ne sont pas tous permissifs | `map_data.g.dart:159` extrait les champs connus ; `apps/avelune_studio/test/infrastructure/map_workspace_io_test.dart:148,162` vérifie des refus stricts. Le modèle généré seul ne suffit pas. |
| Plusieurs versions coexistent volontairement ou historiquement | `models/enums.dart:5`, `map_data.dart:60`, `validation/validators.dart:100`, `apps/pokemap_hub/lib/core/config/avelune_host_compatibility.dart:15`. Les versions projet, map et package doivent être distinguées. |
| L’ancien éditeur reste consommateur | `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`, indexeurs, déplacement, cinématiques et export. Une simple conservation JSON serait insuffisante. |
| La régénération recrée certaines occurrences | `packages/map_authoring/lib/src/domains/maps/environment_actions.dart:329` et l’ancien générateur de `map_editor`. D’où la restriction aux occurrences manuelles en V1. |

La documentation Flame configurée a été consultée via `flame_docs.search_documentation` et la version installée vérifiée. Le plan repose surtout sur le renderer local déjà fonctionnel ; il ne suppose pas une nouvelle API Flame ni une collision Flame remplaçant `map_gameplay`.

## 3. Contrat géométrique commun

### 3.1 Données persistées

Étendre `MapPlacedElement` avec deux valeurs seulement :

- `pixelOffset` : `PixelOffset`, entier, défaut `(0, 0)` ;
- `pixelSize` : `PixelSize?`, largeur/hauteur entières en pixels, `null` pour la taille naturelle.

Ajouter ces deux petits types valeur Freezed sérialisables dans `models/geometry.dart` : `PixelOffset(x, y)` et `PixelSize(width, height)`, avec égalité par valeur. Les types existants `PixelPosition`/`PixelRect` restent utilisables pour les calculs dérivés ; `PixelPosition` porte `leftPx/topPx` et n'a actuellement ni codec JSON ni égalité par valeur, ce n'est donc pas le champ persistant proposé. Les types `GridPos/GridSize` conservent leur sens de grille.

Convention sérialisée proposée :

```json
{
  "pos": {"x": 4, "y": 3},
  "pixelOffset": {"x": 5, "y": 2},
  "pixelSize": {"width": 75, "height": 48},
  "quarterTurns": 0
}
```

Avec des tuiles 32 × 32, l’origine est `(133, 98)` et la taille `(75, 48)`. Les champs existants de l’occurrence restent présents dans le JSON complet.

La position canonique est normalisée : `0 ≤ pixelOffset.x < tileWidth` et `0 ≤ pixelOffset.y < tileHeight`. Un déplacement de 33 pixels modifie la case et le résidu. Utiliser une division par plancher mathématique, y compris pour un déplacement négatif avant le contrôle des limites ; ne pas confondre division entière tronquée et plancher.

La taille personnalisée décrit le rectangle final **après rotation, dans les axes de la map**. `null` résout exactement l’empreinte naturelle actuelle, y compris pour des tuiles non carrées. Ajouter un quart de tour à une occurrence dimensionnée permute largeur et hauteur ; l’ancre haute gauche reste fixe comme aujourd’hui. Quatre rotations rendent strictement la géométrie initiale.

### 3.2 Une résolution, plusieurs rectangles explicitement nommés

Étendre `map_placed_element_footprint.dart` et ses opérations publiques, sans dépendance Flutter. La résolution produit :

1. le rectangle logique en pixels du projet ;
2. la transformation source → rectangle destination et son inverse ;
3. l’emprise en cellules couvrantes, pour les consommateurs qui restent sur grille ;
4. les bounds visuels de chaque frame et leur union pour le culling.

Formules du rectangle logique, à bords demi-ouverts :

```text
left   = pos.x * tileWidth  + pixelOffset.x
top    = pos.y * tileHeight + pixelOffset.y
right  = left + resolvedWidth
bottom = top  + resolvedHeight
rect   = [left, right) × [top, bottom)
```

Attention aux offsets atlas : le renderer ajoute déjà `ProjectRegularAtlasTilesetSource.pixelOffsetX/Y` à l’image, sans appliquer cette translation aux collisions. **Conserver cette convention** : offsets atlas visuels ajoutés après résolution, en pixels du projet dans les axes de la map, sans rotation ou multiplication implicite par le resize. L’offset de l’occurrence déplace, lui, tous ses systèmes. Séparer `logicalRect` et `visualRect(frame)` empêche de changer le comportement des assets existants à transformation identité.

Le hit-test du décor suit ses bounds visuels transformés et le même ordre de superposition qu’aujourd’hui. La boîte de transformation exprime le rectangle logique ; un indicateur visuel distingue les éventuels offsets atlas. Ne pas ajouter un hit-test alpha ou changer les règles de sélection en même temps.

### 3.3 Validation et bornes

- Largeur et hauteur entières strictement positives, minimum 1 pixel ; pas de taille négative servant de flip implicite.
- Validation du rectangle logique entier dans la carte ; les débords visuels dus aux offsets atlas gardent la politique existante. L’UI montre l’éventuel débord visuel sans le confondre avec l’emprise gameplay.
- Même diagnostic dans `MapValidator`, `MapDeltaValidator`, API, inspecteur et gestes ; refus atomique sans modification d’historique.
- Limites de dimension, d’aire et de travail avant toute allocation. Réutiliser les limites existantes de représentabilité ; le lot P0 fixe les plafonds supplémentaires mesurés pour les transformations, communs aux transports, sans valeurs magiques dispersées.
- Clipping spatial avant rasterisation ; jamais de bitmap de la taille totale de la map.
- Une ressource manquante ou un masque mal dimensionné produit un diagnostic explicite ; ne pas choisir arbitrairement des dimensions pour masquer l’erreur.

## 4. Conséquences gameplay et rendu

### 4.1 Collisions

Transformation identité : conserver le chemin actuel et prouver le résultat identique. **Translation seule, sans changement effectif de taille : déplacer exactement la collision actuelle, bit pour bit, sans rééchantillonner ni épaissir**, y compris après rotation et lorsque le masque diffère du frame. La couverture conservative ci-dessous s'applique au redimensionnement effectif :

- Masque pixel : projeter les pixels/runs bloquants vers les chunks existants. Un pixel destination est bloqué dès que son aire inverse recouvre une aire source bloquante strictement positive. Cette règle conservative évite la disparition d’un mur de 1 pixel lors d’une réduction.
- Profil en cases : transformer les rectangles des cases bloquantes directement vers le stockage pixel, sans fabriquer un énorme masque source intermédiaire.
- Exclure alors cette occurrence de l’ancien cache de collision par cases ; sinon ancienne et nouvelle empreintes se cumulent.
- `applyCollision=false` continue de désactiver la collision de cette occurrence.
- Respecter les dimensions propres aux masques et leur repère source. À 0°, le code actuel conserve `mask.widthPx/heightPx` ; une translation ne doit pas les remplacer par la taille du sprite. Résoudre d'abord l'empreinte collision naturelle selon les conventions actuelles pour la rotation choisie, puis lui appliquer les rapports `tailleLogiqueCible / tailleLogiqueNaturelle` axe par axe. Les frontières rationnelles sont couvertes de manière conservative, sans arrondi intermédiaire qui perdrait une ligne. Cette règle réutilise les runs/rectangles et n'impose pas un bitmap naturel intermédiaire.
- Construire les données dérivées au chargement ou au commit effectif. La translation de prévisualisation dans Studio ne reconstruit pas le monde gameplay à chaque frame.

Le visuel utilise le nearest-neighbor, la collision utilise la couverture conservative. Une ligne devenue sous-pixel peut donc garder un pixel bloquant alors qu’elle est peu visible : c’est un compromis explicite de la réduction, à montrer dans l’overlay collisions.

Player et PNJ n’utilisent pas toutes les mêmes requêtes. Les PNJ/pathfinding et certaines décisions terrain restent basés sur le centre des cellules. Cette fonctionnalité ne promet pas un nouveau pathfinding au pixel. Tester les quatre bords, les petits obstacles, les chemins scriptés, les modes de déplacement et le diagnostic d’authoring contre cette sémantique réelle.

### 4.2 Comportements attachés et éléments indépendants

V1 conserve les interactions sur grille. L’emprise attachée à l’occurrence devient :

```text
firstX = floor(left / tileWidth)
lastXExclusive = ceil(right / tileWidth)
firstY = floor(top / tileHeight)
lastYExclusive = ceil(bottom / tileHeight)
```

Toucher exactement un bord n’ajoute pas de cellule ; déborder de 1 pixel en ajoute une. L’overlay « zone d’interaction » montre ces cellules dans Studio. Cette règle couvre les petits objets, sans introduire un nouveau système d’interaction au pixel.

Recalculer les index action/enter/exit/bump, la couverture et le périmètre `onNear` depuis la même emprise. `onBump` existe via `bumpBehaviorByPos` et `gameplay_step.dart` : vérifier aussi le déclenchement lors d'un mouvement bloqué après transformation. Conserver les IDs, les cooldowns, les scopes et l’ordre gagnant : ordre des occurrences dans la liste, puis ordre des comportements. `visualOrder` ne doit pas devenir une priorité gameplay.

Les effets attachés, dont une porte animée, suivent cette zone. Les destinations `targetMap/targetPos`, les `map.warps`, les triggers, les rencontres, les zones et les entités indépendantes restent à leurs coordonnées explicites. Aucun déplacement automatique d’un warp « proche ». Vérifier qu’une réduction de porte ne rend pas son parcours injouable ; le plan n’automatise pas la réécriture des destinations.

### 4.3 Rendu, animations, ombres et occlusion

- Utiliser les rectangles communs pour image, sélection, index spatial, culling, collisions debug, foreground et recherche des objets qui se recouvrent.
- Réutiliser `quarter_turn_pixel_renderer.dart`. Son chemin rapide `drawImageRect` à 0° peut différer du sampling rationnel à 90° pour des ratios non entiers. Les raccourcis sont conservés seulement pour les cas dont l’équivalence est prouvée ; les autres emploient un résultat transformé réutilisable.
- Échantillonnage visuel et masque d’occlusion partagent la même convention et les mêmes tie-breaks. La collision conservative reste volontairement distincte.
- Conserver les rectangles de découpe source dans l’atlas. L’étirement agit sur la destination ; il ne déborde pas dans la tuile voisine du PNG.
- Les frames d’un élément ont déjà des dimensions uniformes imposées par le validator. Taille cible stable pendant animation normale et one-shot ; offsets atlas par frame inclus dans les bounds et invalidations.
- Transformer les empreintes, masques et points d’ancrage des ombres simples et des bâtiments. La direction et la distance lumineuses gardent leurs unités monde ; ne pas les multiplier arbitrairement par l’étirement X/Y de l’asset.
- Conserver transparence, opacité, ordre des couches et passages derrière/devant le joueur. Le chemin de flip des Smart Tiles reste inchangé et couvert en non-régression.

Clés de caches locaux des occurrences : ressource/révision, frame, taille, rotation et mode de masque requis. Une simple translation n’invalide pas les pixels locaux transformés ; elle met à jour les bounds monde. Invalidation à la modification d’image, de masque, de tileset ou de ressource. Mémoire bornée et libération des images dérivées lors d’éviction/dispose ; pas de cache illimité par combinaison de tailles rencontrées pendant un drag.

## 5. Studio : interaction et prévisualisation

Le geste garde un snapshot source, une géométrie proposée et une validation locale. Les deltas sont calculés depuis le point de saisie initial, sans arrondis cumulés. `event.localPosition` arrive déjà dans le repère du contenu de l’`InteractiveViewer` actuel : convertir via `displayScale`, sans diviser deux fois par le zoom.

Lorsqu’on presse ou relâche Shift pendant un geste, recalibrer le point de référence sur la géométrie affichée pour éviter un saut. Une poignée garde son bord opposé ; à 1 pixel, elle s’arrête avant inversion. Les poignées gardent une taille confortable à l’écran, avec un hit-test tenant compte du zoom. Avec proportions verrouillées aux coins, conserver le ratio du début du geste, arrondir une seule fois la dimension dérivée au pixel et garder le coin opposé ; le label du verrou précise son champ d’application. La saisie proportionnelle garde l’ancre haute gauche.

Le sprite, son occlusion et ses ombres suivent l’aperçu. Ajouter une mise à jour transitoire ciblée dans `RuntimeAuthoringMapRenderer`/`MapLayersComponent`, limitée à l’occurrence concernée et à ses dépendances visuelles. Garder la map persistée inchangée jusqu’au relâchement. Ne pas superposer simplement une image au-dessus de toutes les couches : cela donnerait un faux aperçu des profondeurs.

Les événements sont regroupés au plus une fois par frame. Un résultat asynchrone devenu obsolète ne remplace pas le dernier aperçu. Les caches de tailles intermédiaires sont bornés ; la translation simple réutilise les données locales. Si l’aperçu lourd ne peut pas suivre le budget mesuré, réduire la fréquence de recalcul de ses données dérivées, sans changer le résultat final ni reconstruire tout le renderer.

Au relâchement : valider encore le snapshot/document courant, puis une opération atomique et **une entrée undo**. Escape, perte de focus, changement d’outil ou de map annulent le geste. Un geste invalide ne commit rien et explique le motif. Les répétitions clavier se regroupent jusqu’au key-up ou changement de sélection ; les champs numériques commitent une seule valeur validée.

L’inspecteur réutilise `StudioCommitField` et les primitives/tokens du design system. Position, taille, verrou de proportions et réinitialisations appartiennent à « Cette instance ». Ne pas modifier involontairement la définition commune. Les raccourcis Cmd/Ctrl + Haut/Bas déjà consacrés à l’ordre visuel restent disponibles.

## 6. API, persistance et distribution

### 6.1 Commande atomique canonique

Ajouter une action `placed_element.set_geometry` dans le domaine maps de `map_authoring`. Paramètres métier proposés, après le ciblage de map déjà prévu par le transport :

```json
{
  "instanceId": "decor-17",
  "pixelX": 133,
  "pixelY": 98,
  "pixelSize": {"width": 75, "height": 48}
}
```

`pixelX`, `pixelY` et `pixelSize` sont requis pour cette opération complète ; `pixelSize: null` demande la taille naturelle. Un champ omis est une erreur, pas une remise à zéro implicite. Position et taille se valident et se publient ensemble. La géométrie normalisée apparaît dans le read model et les diagnostics.

`placed_element.move` conserve ses `x/y` en cases et le résidu pixel courant ; aucune réinterprétation silencieuse de ses unités. Les opérations de rotation utilisent le helper commun et permutent la taille explicite. Alignement et reset se traduisent en `set_geometry`, sans multiplier les actions équivalentes.

Studio utilise l’opération pure commune et les façades publiques `map_authoring_api.dart`/`map_authoring_local.dart` aux frontières appropriées : prévisualisation locale immédiate, publication canonique existante au commit/save. Aucun accès UI à `map_authoring/src`, aucun `EditorNotifier` supplémentaire, aucun appel MCP dans une boucle de drag.

Mettre à jour schémas d’entrée/sortie, describe, catalogue, diagnostics, historique et matrice de parité. `placed_element.update` générique et un whole-map save ne constituent pas la preuve sémantique. Le MCP relaie déjà les actions canoniques : pas besoin d’un nouveau serveur ou d’un outil top-level dédié.

### 6.2 Cycle de vie à préserver

| Opération | Règle |
| --- | --- |
| Nouveau placement | Offset nul, taille naturelle. |
| Clone/copie/collage | Conserver taille/rotation/résidu ; appliquer la translation demandée ; nouvel ID selon contrat actuel. |
| Remplacement de ressource | Conserver taille personnalisée en pixels ; si naturelle, résoudre la nouvelle taille et revalider. |
| Modification de la ressource source | Recalculer naturel, masques et caches ; taille personnalisée reste fixe ; diagnostic si nouvelle source incompatible. |
| Déplacement de sélection multiple existant | Même delta pixel pour les objets pris en charge, positions relatives préservées ; pas de resize de groupe introduit. |
| Resize/crop de carte | Détecter le dépassement pixel même si l’ancre reste dans la carte ; respecter les politiques de traitement existantes, sans déformation automatique du décor. |
| Changement de taille de tuile, s’il est exposé | `pos` reste l’ancrage en cases ; taille personnalisée reste en pixels. L’objectif initial de renormalisation automatique est borné lors de P6 : revalider toutes les cartes avant sauvegarde et refuser clairement un changement invalidant, sans écriture partielle. La réécriture transactionnelle de toutes les cartes n’est pas ajoutée dans ce lot. |
| Réindexation tuile/instance | Préserver les occurrences manuelles et leurs champs, éviter les doublons. Les objets générés demeurent sous autorité du générateur. |
| Sauvegarde de partie | Pas de transform du décor dans la sauvegarde joueur si la map source reste l’autorité ; tester reprise, positions du joueur et scopes des comportements. |

### 6.3 Formats et hôtes

Avant tout changement de version, tracer séparément le format de map, le manifeste projet, le manifeste de jeu distribué, le contrat exporté et les capacités acceptées par le Hub/Player. Le `v7` existant ne désigne pas automatiquement le prochain format de map.

La fonctionnalité doit être annoncée par une version/capacité effectivement contrôlée **avant** la lecture par un hôte ancien. Un ancien consommateur ne doit pas accepter le package puis ignorer les champs. Pour l’ouverture directe de projets, une gate de format de map/projet doit empêcher la même perte silencieuse. Le lot P0 fixe le mécanisme et les valeurs après traçage des lecteurs réels ; l’activation UI dépend de cette gate.

La politique pré-1.0 s’applique : pas de migration, double lecteur ou pont de compatibilité ajoutés par réflexe. Un ancien format non supporté est refusé explicitement ; aucune conversion silencieuse d’un projet utilisateur. Préserver l’identité géométrique des données actuelles sous le format cible ne prouve pas leur compatibilité avec un ancien binaire.

Vérifier export, validation package, installation, réouverture, miniatures, aperçus de cartes/cinématiques et rendu Player. Les exports mobiles utilisent le même modèle/runtime ; les hosts aux versions incompatibles doivent être refusés selon leurs gates. Pas d’upgrade de dépendance ou de release ajouté implicitement à ce chantier.

## 7. Plan par lots et fichiers concernés

Ordre : `P0 → P1 → P2/P3/P4 → P5 → P6 → P7`. P2/P3/P4 peuvent être développés indépendamment après stabilisation du contrat, mais ne se livrent pas séparément aux utilisateurs avec des comportements divergents. Les cases restent ouvertes jusqu’à exécution et preuve.

### P0 — Verrouiller les conventions et caractériser les chemins actuels

- [x] Recontrôler le SHA, l’état Git et les AGENTS locaux ; préserver toute modification concurrente.
- [x] Figer noms/types des deux champs et payload d’action ; tester la rotation de tailles personnalisées avec tuiles 16 × 32.
- [x] Tracer les gates de formats jusqu’au Hub et aux lecteurs stricts. Consigner ici la décision de version/capacité avant P1 ; aucun numéro choisi par intuition.
- [x] Caractériser le travail des grands décors, ombres, masques et aperçus ; mesurer les plans graphiques et vérifier les bornes de dimensions/aire/cache. Les sondes et compteurs ne constituent pas un profil RSS/GPU ni une garantie de temps de frame.
- [x] Ajouter les caractérisations identité/rotation/atlas offset/ordre des comportements et masques de dimensions différentes du frame qui manquent ; ne pas remplacer des goldens pour rendre le nouveau comportement vert. Preuves réparties entre P1, P2 et P3 ci-dessous.

Fichiers : `packages/map_core/lib/src/models/enums.dart`, `map_data.dart`, `project_manifest.dart`, `validation/validators.dart` ; `packages/map_distribution/lib/src/game_package_compatibility.dart`, `game_package_project_validator.dart` ; `apps/pokemap_hub/lib/core/config/avelune_host_compatibility.dart`. Tests : `map_placed_element_rotation_test.dart`, `placed_element_rotation_gameplay_test.dart`, `map_layers_component_performance_profile_test.dart` dans leurs packages respectifs.

**Sortie :** conventions sans ambiguïté, limites justifiées, consommateurs/gates identifiés, baseline ciblée enregistrée. Si la gate requiert une décision produit de conversion des projets, présenter un impact concret avant cette action ; ne pas l’inventer.

### P1 — Modèle et géométrie Dart pure

- [x] Ajouter offset/taille, sérialisation, égalité et `copyWith` ; regénérer uniquement `map_core`.
- [x] Étendre les helpers de `map_placed_element_footprint.dart` : rectangles, normalisation, rotation, coverage, projection des repères source.
- [x] Adapter validation complète/delta, hit-test pixel, overlaps pour ordre visuel et impact du resize/crop de map.
- [x] Exporter les API nécessaires par les barrels publics existants, sans Flutter/Flame dans le core.
- [x] Ajouter `packages/map_core/test/map_placed_element_geometry_test.dart` : identité, offset négatif normalisé, limites exactes, tailles 1/impaires, rectangles demi-ouverts, rotation ×4, crop avec ancre valide mais débord, valeurs invalides/énormes, JSON aller-retour et rejet de format.

Fichiers sous `packages/map_core/lib/src/` : `models/map_data.dart` et ses générés Freezed/JSON, `models/geometry.dart` et ses générés Freezed/JSON, `operations/map_placed_element_footprint.dart`, `operations/map_placed_element_visual_order.dart`, `operations/map_resize.dart`, `validation/validators.dart`, `validation/map_delta_validator.dart`. Exports : `packages/map_core/lib/map_core.dart` et le barrel domaine concerné.

**Sortie :** géométrie unique testée et garde de format opérationnelle ; les objets à transformation identité gardent leur résultat.

### P2 — Collisions, comportements et overlays de diagnostic

- [x] Adapter les constructions caches dans `gameplay_world_state.dart` et `collision/world_collision_storage.dart` selon §4.1 ; éliminer le double comptage cases/pixels.
- [x] Transformer les cases bloquantes et les masques avec couverture conservative et clipping préalable.
- [x] Utiliser la nouvelle emprise pour behaviors, near, bump et coverage, sans réordonner les occurrences.
- [x] Faire suivre l’overlay/provenance de `packages/map_authoring/lib/src/domains/maps/collision_actions.dart` et les diagnostics de playabilité.
- [x] Ajouter `packages/map_gameplay/test/placed_element_transform_gameplay_test.dart` : mur 1 px réduit, translation bit-à-bit après rotations 0–3 avec masque de dimensions différentes du frame, ancien obstacle libéré, quatre faces, masque asymétrique, profil cases, collision désactivée, PNJ/Player, action/enter/exit/near/bump, cooldown et porte avec destination indépendante.

**Sortie :** rendu de collision de diagnostic et collision réelle concordants selon la politique déclarée ; pas de recalcul par frame.

### P3 — Runtime et aperçu partageant le rendu

- [x] Adapter image, index spatial, culling, foreground et debug dans `map_layers_component.dart`.
- [x] Définir un échantillonnage visuel cohérent dans `quarter_turn_pixel_renderer.dart` ; tester les chemins rapides contre la référence rationnelle.
- [x] Adapter, sous `packages/map_runtime/lib/src/`, `shadow/runtime_static_placed_element_shadow_sources.dart`, `shadow/runtime_projected_building_shadow_collection.dart`, `presentation/flame/static_placed_element_occlusion_patch_resolution.dart` et `presentation/flame/placed_element_occlusion_patch_component.dart`.
- [x] Ajouter le canal d’aperçu ciblé dans `application/authoring_preview/runtime_authoring_map_renderer.dart`, avec invalidations locales, dispose et annulation.
- [x] Ajouter `packages/map_runtime/test/placed_element_transform_render_test.dart` ; étendre tests animation, occlusion, ombres et profil performance. Vérifier les ratios non entiers, réduction forte, rotations, zoom, atlas offset et bords de viewport ; conserver les tests existants des flips Smart Tiles séparément.

**Sortie :** Studio et Player rendent le même résultat final ; un drag de translation ne recrée ni renderer complet ni pixels locaux ; pas de cache non borné pendant un resize.

### P4 — Authoring canonique, formats, export et MCP

- [x] Implémenter `placed_element.set_geometry` et la sémantique de `move`, clone, rotation et reset dans `packages/map_authoring/lib/src/domains/maps/placed_element_actions.dart`.
- [x] Préserver transaction/undo dans `packages/map_authoring/lib/src/editing/map_history_delta.dart` et les chemins de batch existants ; un échec ne produit aucune écriture partielle.
- [x] Actualiser lecteurs stricts, contrats describe et catalogue `pokemap_authoring_api_mcp_action_catalog.md` ; ajouter la conformance de la nouvelle action.
- [x] Propager sans perte via `packages/map_authoring/lib/src/domains/distribution/runtime_project_projection_builder.dart`, `game_package_export_service.dart` et les validators de `map_distribution` ; appliquer les gates définies en P0. Projection transformée relue ; archive transformée et Player à certifier en P7.
- [x] Étendre les preuves transport/historique/projection et `tools/pokemap_mcp/test/mutation_server.test.ts`, avec non-régression spatial/order.
- [x] Prouver API directe, JSONL/CLI et MCP : describe → query → plan → apply → validate → requery → undo. Inclure reset `null`, omission invalide, taille hors limites, occurrence générée et conflit.

**Sortie :** contrat découvrable et transportable, format réellement contrôlé par les consommateurs, export réimporté sans perte. Catalogue live à certifier en P7.

### P5 — Avelune Studio : manipulation, inspecteur et historique

- [x] Étendre `map_editing_commands.dart` et `editable_map_document.dart` en réutilisant la géométrie/validation publique ; garder la publication canonique existante.
- [x] Implémenter l’état du geste dans `map_workspace_canvas_gestures.dart` et la conversion des coordonnées dans `map_workspace_canvas.dart`.
- [x] Ajouter poignées/boîte/zone d’interaction aux fichiers overlay concernés. Traiter les poignées avant le corps de l’objet dans le Listener existant ; conserver une autorité d’input.
- [x] Brancher l’aperçu ciblé dans `platform/rendering/studio_map_visual_widgets.dart`, sans nouvelle map persistée à chaque mouvement.
- [x] Ajouter champs, verrou et resets dans l’inspecteur, via design system ; gérer focus/raccourcis dans le canvas sans modifier les raccourcis d’ordre existants.
- [x] Vérifier les suites mouvement, inspecteur, placement, ordre et I/O ; ajouter `test/map_workspace/decor_transform_host_test.dart` pour poignées et déformations, et la comparaison RGBA dans `studio_map_resources_test.dart`.

**Sortie :** Shift précis à plusieurs zooms, aucun saut à la bascule, bord opposé fixe, preview réel, undo unique, Escape sans mutation, reload exact, restriction claire des éléments générés.

### P6 — Consommateurs secondaires et effets de bord

- [x] Dans `packages/map_editor`, adapter bounds/rendu/sélection/rotation/déplacement de l’instance en réutilisant le core. Aucun nouvel outil de resize requis dans cet ancien éditeur ; ses outils existants préservent la géométrie.
- [x] Vérifier l’indexer, les planners de déplacement/rotation et le painter, avec les validations et sauvegardes contextuelles de leurs consommateurs.
- [x] Vérifier les aperçus de cinématiques, cartes voisines, miniatures et caches ; utiliser les géométries d’occurrence sans modifier les calculs des tuiles ordinaires.
- [x] Vérifier exports, sauvegarde/relecture, copie/clone, remplacement de ressource et installation réelle du paquet dans le Player.
- [x] Prouver qu’environnement/réindexation préservent les occurrences manuelles ; protéger les instances réellement possédées par Environment.
- [x] Étendre les tests de rendu, sélection, mouvement, rotation, ombres, indexer, I/O, lifecycle, distribution et Hub. Protéger les changements de grille invalidants avant écriture, y compris pour la carte active non sauvegardée ; limite de conversion automatique documentée.

**Sortie :** aucun consommateur encore actif ne perd silencieusement les champs ou n’affiche l’ancienne empreinte. Tout consommateur volontairement non supporté doit refuser explicitement le format, avant ouverture/écriture.

### P7 — Certification ciblée et revue

- [x] Exécuter les commandes pertinentes de §8, préserver les résultats exacts et distinguer les échecs antérieurs.
- [x] Rebuild/reload du MCP, vérifier le `pokemap_describe` réellement chargé, puis la transaction complète sur fixture temporaire sous un root autorisé. Client stdio neuf sur le build courant ; preuve détaillée ci-dessous.
- [ ] Parcours natif Studio → sauvegarde → fermeture/réouverture → export → Player installé, selon la matrice ci-dessous.
- [x] Revue finale indépendante : exactitude géométrique, absence de logique dupliquée, effets de bord, bornes/performance, parité et limites de la preuve manuelle. Conformité et qualité favorables ; validation visuelle réservée à Yoahn.
- [x] Ticket `POST-WLD-TRANSFORM-PLAN-001` mis à `TO REVIEW`, preuves et limites synchronisées puis relues dans Notion. `DONE` reste réservé à la décision de Yoahn. Aucun commit/push/rebase sans autorisation explicite.

## 8. Validation prévue, distincte des vérifications du plan

### 8.1 Matrice d’acceptation

| Scénario | Preuve attendue |
| --- | --- |
| Identité sur objets actuels | Même rendu, collisions, ordre, comportements et source d’asset. |
| Déplacement de 1 px à zoom 50 %, 100 %, 200 % | Même valeur projet et même save/reload ; aucune double correction de zoom. |
| Taille 1 px, impaire, étirement X seul/Y seul | Dimensions exactes, pas de ratio forcé, minimum valide, reset naturel. |
| Tuiles 16 × 32 et rotations 0–3 | Convention finale cohérente ; quatre rotations = identité. |
| Atlas offset, animation/one-shot | Image, occlusion et culling cohérents ; frame source non recadrée incorrectement ; flips Smart Tiles inchangés en non-régression séparée. |
| Translation seule avec masque différent du frame | Collision bit-à-bit translatée après rotations 0–3, sans changement de dimensions ni épaississement. |
| Masque asymétrique et bloqueur 1 px réduit | Ancienne empreinte libre ; nouvelle collision conservative ; pas de mur disparu. |
| Grand décor au bord du viewport/carte | Sélection sur portion visible, culling exact, validation/crop fiables. |
| Deux décors chevauchants | Ordre visuel correct ; priorité gameplay inchangée. |
| Porte décalée de 1 px | Zone en cases visible, action/near/enter/exit/bump conformes ; destination indépendante. |
| Escape, conflit, changement map/outil/focus | Zéro commit parasite ; aperçu détruit ; aucun résultat asynchrone tardif appliqué. |
| Undo/redo, clone, replace, save/reload | Tous les champs et IDs pertinents conservés ; une transaction par geste. |
| Ancien lecteur/Player incompatible | Refus explicite avant perte des transformations. |
| Resize répété, grand asset, nombreuses occurrences | Travail borné, aucun bitmap global, aucun cache croissant sans limite, coût lié aux instances pertinentes. |

Fixture synthétique minimale : décor asymétrique, profil cases, masque pixel fin, décor animé avec atlas offset, ombre/occlusion, interaction et warp indépendant. Pas de mutation du projet Train pour fabriquer les preuves.

### 8.2 Commandes à lancer pendant l’implémentation

Exécuter depuis le package indiqué. Les chemins des nouveaux tests correspondent aux fichiers planifiés ci-dessus ; ces commandes ne sont **pas** des preuves déjà obtenues. Ajouter les suites d’ombre concernées au lot P3 et les tests des gates effectivement changées au lot P4.

```text
packages/map_core
  dart run build_runner build --delete-conflicting-outputs
  dart test test/map_placed_element_geometry_test.dart test/placed_elements_test.dart test/map_placed_element_rotation_test.dart test/placed_element_visual_order_test.dart
  dart analyze

packages/map_gameplay
  dart test test/placed_element_transform_gameplay_test.dart test/placed_elements_collision_test.dart test/placed_element_rotation_gameplay_test.dart test/placed_element_behaviors_test.dart test/runtime_movement_collision_regression_test.dart test/gameplay_world_state_collision_storage_characterization_test.dart
  dart analyze

packages/map_runtime
  flutter test test/placed_element_transform_render_test.dart test/placed_element_quarter_turn_render_test.dart test/map_layers_component_placed_element_render_test.dart test/placed_element_large_scale_render_test.dart test/placed_element_animation_runtime_test.dart test/placed_element_collision_clip_test.dart test/playable_map_game_placed_element_occlusion_test.dart test/static_placed_element_occlusion_patch_resolution_test.dart test/map_layers_component_performance_profile_test.dart
  flutter test test/phase_a_golden_battle_slice_smoke_test.dart test/playable_map_game_save_load_transaction_test.dart
  flutter analyze

apps/avelune_studio
  flutter test test/map_workspace/decor_transform_host_test.dart test/map_workspace/decor_move_host_test.dart test/map_workspace/inspector_fields_undo_test.dart test/map_workspace/decor_placement_preview_host_test.dart test/map_workspace/decor_order_e2e_test.dart test/infrastructure/map_workspace_io_test.dart
  flutter analyze
  flutter build macos --debug --no-pub

packages/map_authoring
  dart test test/domains/maps/spatial_object_contract_test.dart test/domains/maps/placed_element_visual_order_actions_test.dart test/domains/maps/map_operations_batch_test.dart test/history/undo_redo_contract_test.dart test/domains/distribution/game_package_export_api_test.dart
  dart test test/parity/full_authoring_parity_test.dart
  dart run tool/pmcp085_conformance.dart
  dart analyze

packages/map_distribution
  dart test test/game_package_compatibility_test.dart test/game_package_inspector_test.dart test/phase0_contract_fixtures_test.dart
  dart analyze

apps/pokemap_hub
  flutter test test/platform/avelune_host_compatibility_test.dart
  flutter analyze

packages/map_editor
  flutter test test/cinematic_map_backdrop_placed_element_rotation_test.dart test/placed_element_instance_indexer_test.dart test/map_canvas_object_selection_test.dart test/game_export/runtime_project_projection_builder_test.dart
  flutter test test/authoring_api/editor_mutation_parity_test.dart test/authoring_api/editor_write_boundary_test.dart test/authoring_api/no_bypass_guardrail_test.dart
  flutter analyze

examples/playable_runtime_host
  flutter test test/phase_a_golden_slice_launch_test.dart
  flutter analyze
  flutter build macos --debug --no-pub

tools/pokemap_mcp
  npm run check
  npm run build
  npm test

racine
  bash tools/scripts/check_markdown_hygiene.sh
  git diff --check
  git status --short --untracked-files=all
```

Résultat attendu : tests ciblés réussis, analyses sans nouveau diagnostic, builds disponibles, puis preuves native et MCP séparées. Ne pas annoncer « tout vert » à partir d’un sous-ensemble.

Après chaque suite Flutter, capturer runner PID et descendants pendant son exécution ; vérifier UID, date de démarrage et commande avant de terminer un reliquat appartenant à cette suite, TERM puis KILL seulement si nécessaire. Aucun kill global par nom. `apps/avelune_studio/tool/run_check.py` montre cette discipline, mais son cwd et son répertoire de preuves sont fixés à un ancien lot AS-ARC-002 : ne pas le réutiliser tel quel. Préférer un wrapper temporaire paramétré hors dépôt si nécessaire.

PMCP-085 global comprend une certification items et une dette PMCP-081 indépendante. Enregistrer son vrai résultat ; ne pas réparer cette dette dans ce chantier pour obtenir du vert. `npm run verify:checkout-catalog` peut compléter le contrôle mais son garde Git exige un arbre propre ; il ne remplace pas le catalogue du serveur réellement chargé et n’autorise pas un commit.

Les builds natifs et parcours longs restent locaux. Aucune nouvelle dépendance de release, aucun soak CI ni runner macOS payant n’est ajouté. Pas de `flutter build web` promis sur les hosts sans cible web. Un parcours macOS ne vaut pas certification iOS/Android : réutiliser les gates de chaque livraison réellement visée.

## 9. Risques résiduels, arbitrages et conditions de livraison

| Risque | Réponse et condition |
| --- | --- |
| Collision invisible après réduction | Couverture conservative et overlay ; cas de mur fin obligatoire. |
| Activation sur une case supplémentaire | Sémantique floor/ceil assumée et affichée ; interactions au pixel restent hors scope. |
| Saut au changement Shift/zoom | Référence du geste recalée, deltas projet, tests à plusieurs zooms. |
| Image/masque/ombre différents | Géométrie commune, politiques d’échantillonnage nommées, preuves indépendantes. |
| Performances lors du resize | Limites avant allocation, clipping, aperçu ciblé, caches bornés, mesure locale en P0/P3. |
| Ancien hôte ignorant les champs | Gates format/capacité vérifiées sur un export réel avant exposition utilisateur. |
| Modifications perdues par générateur | V1 limitée aux occurrences manuelles ; même refus UI/API. |
| Ancien éditeur/aperçu export oublié | P6 obligatoire, inventaire des consommateurs et test de round-trip. |
| Changement de source ou de grille | Règles explicites de taille naturelle/personnalisée et revalidation ; aucun silent clamp. |
| Scope qui enfle en refonte | Réutiliser opérations, transactions, renderer et stockage existants ; nouvelle abstraction seulement si deux consommateurs en ont réellement besoin. |

La majorité de la difficulté est dans la cohérence des consommateurs, pas dans les poignées. Les seuls points à mesurer/décider techniquement au début de l’exécution sont les plafonds de travail/cache et les gates de formats exactes. Les règles produit principales sont proposées explicitement dans ce plan, sans bloquer sa lecture sur des questions ouvertes.

Livraison complète : tous les lots P0–P7 satisfaits, contrats et transports cohérents, parcours natif observé, revue effectuée. Une UI de resize fonctionnelle avec collisions/export encore anciens reste `PARTIAL` et n’est pas exposée comme une fonctionnalité terminée.

## 10. Traçabilité, passes de revue et preuves de cette préparation

### Périmètre produit

Rattachement : grand domaine existant **14. Monde, exploration et narration — Post-bêta**, `Domaine = Monde & narration`, `Gate bêta = non`, `Rang d’exécution = Hors gate`. Aucune dépendance ajoutée à la bêta figée.

Ticket : [POST-WLD-TRANSFORM-PLAN-001 — Plan du décalage pixel et du redimensionnement des décors](https://app.notion.com/p/3ea197a7bfa581e38e07f35046dc5eb1), `TO REVIEW`, type Documentation. Le statut concerne ce plan ; l'implémentation reste entièrement à faire. Aucun ticket bêta existant n'a été élargi.

Roadmap consultée, non modifiée : FG-014 save/load, FG-090 warp et FG-180/182/183/185 validation/régression sont des surfaces de non-régression, pas de nouveaux objectifs signés. La table actuelle indique FG-014/180/182/183 `DONE`, FG-090/185 `PARTIAL` ; ces statuts documentaires ne sont pas une preuve fraîche et ce travail ne propose aucune promotion de lot.

### Passes réalisées en lecture seule

- **Audit/Architecture — `plan_architecture` :** faisable sans refonte ; géométrie partagée, distinction des versions et couverture des consommateurs requises. Constats intégrés : crop, ordre, validation delta, générateurs, ancien éditeur et export.
- **Implémentation — `plan_implementation` :** extension ciblée faisable ; conventions de rectangle final, offsets atlas, collision conservative et sampling explicite nécessaires. Ces arbitrages sont inscrits aux §3–6.
- **Tests — `plan_tests_build`, passe Tests :** existant réutilisable, mais les tests de rotation seuls ne prouvent pas décalage/resize. Matrice et nouveaux tests dédiés inscrits au §8.
- **Build/Validation — `plan_tests_build`, passe distincte :** gates identifiées ; compilation, parité du catalogue et parcours réel restent des preuves différentes. Dettes PMCP et discipline des harnesses consignées.
- **Critique finale — `plan_critique` :** favorable après trois corrections ciblées, intégrées et relues : translation collision bit-à-bit distincte du resize conservatif avec masques de dimensions propres ; couverture de `onBump` ; absence de flips par occurrence clarifiée. L'incohérence initiale du type persistant a aussi été corrigée par les types valeur `PixelOffset`/`PixelSize`. Verdict final : favorable pour remise, aucun point bloquant restant sur les passages revus. Aucun code ni test exécuté par cette passe.

### Commandes et limites de cette préparation

- `git log -1 --format='%H %s'` : SHA `df9d134ae5326b05488d5b6e3668adca59566899`, « Rename PokeMap editor to Avelune Studio and add multi-platform release ».
- `git status --short --untracked-files=all` avant rédaction : sortie vide, arbre propre.
- Lectures ciblées via `rg`, `sed`, outils de contexte ; lecture de `AGENTS.md`, `codex_rule.md`, skills applicables et roadmap. Recherche/fetch du cockpit et du schéma Notion ; aucun changement de famille bêta.
- `bash tools/scripts/check_markdown_hygiene.sh` avant rédaction : exit 0, `Markdown hygiene: no new Markdown files.`
- Tests Dart/Flutter, analyse et build : **non exécutés**, car la demande porte sur un plan et aucune source de production n’a été changée. Les commandes de §8 sont futures.
- `POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh` après rédaction : exit 0, `Markdown hygiene: 1 new Markdown file(s), all in canonical locations.` L'override borné à un fichier correspond au plan persistant explicitement demandé.
- `git diff --check` : exit 0, aucune sortie. Ce contrôle ne couvre pas à lui seul le nouveau fichier non suivi : contrôle direct du document effectué en complément.
- Contrôle documentaire par script JavaScript en lecture seule : deux exemples JSON parsés, 45 références de tests dont 41 chemins existants et quatre nouveaux fichiers explicitement planifiés ; fences équilibrées, aucune ligne avec whitespace terminal, aucun marqueur de conflit.
- État Git final : seul ajout non suivi `?? documentation/reports/avelune_studio/plans/as_map_transforms_pixel_resize_implementation_plan.md` ; aucun fichier suivi modifié. Aucun commit ni changement de branche.

Auto-critique : la revue documentaire couvre les dépendances connues et corrige plusieurs hypothèses initiales, mais ne prouve ni performances ni résultat graphique. Les valeurs de plafonds et les gates de formats restent des livrables techniques obligatoires de P0. Leur choix doit précéder l'exposition utilisateur ; une estimation de lignes de code ou de durée à ce stade serait peu fiable. Le nombre de consommateurs justifie les lots de vérification, sans justifier une refonte de leur architecture.

Fichier créé par cette préparation : uniquement ce plan. Zones : §1–6 contrat et audit ; §7 lots/fichiers ; §8 validation future ; §9 risques ; §10 preuves et traçabilité. Pas de diff de production, de modification de projet utilisateur, de migration, de génération de code ni d’opération Git d’écriture.

## 11. Suivi d'exécution après autorisation

Le ticket existant est passé à `DOING`, type Fonctionnalité, toujours hors gate bêta. Aucune opération Git d'écriture autorisée. La demande directe de l'utilisateur de ne pas ajouter de commentaires de code prime la consigne contradictoire de `codex_rule.md`.

### P0 — Constats et décisions

- Audit formats : les anciennes gates rejettent déjà les versions projet/map inconnues. `ProjectVersion.v8` et le second enum `ProjectFormat.v8` sont nécessaires ; le format ZIP 1 n'a pas à changer. **Décision explicite de Yoahn : v8 strict, anciens projets refusés.** Les codecs, validateurs, factories et hôtes passent au format cible v8 ; les fonctions cinématiques existantes doivent rester disponibles. Aucun double lecteur, migration ou conversion de projet utilisateur sur disque.
- Baseline : `flutter test test/map_layers_component_performance_profile_test.dart --reporter expanded --concurrency=1`, depuis `packages/map_runtime`, exit 0, **4 tests réussis**. Wrapper temporaire suivant PID/descendants et identités : `/tmp/pokemap-transform.031d1V/run_check.py`. Preuve : `baseline-runtime-profile.json`, `remainingOwnedProcesses={}`.
- Mesure courte, hors dépôt, avec image synthétique 256², rotation 1 et masque alterné : display lists destinations 128×127 / 256×255 / 512×511 / 1024×1023. Enregistrement observé 19 / 25 / 45 / 116 ms ; stockage picture 607 080 / 2 437 272 / 4 883 912 / 9 777 192 octets ; replay 1–4 ms. Ce sont des mesures locales en test Flutter, pas des percentiles ni une certification release. Test temporaire corrigé après un premier échec de compilation dû aux arguments width/height oubliés ; seconde exécution : 1 test réussi, exit 0, aucun processus possédé restant.
- Limite choisie pour une taille personnalisée : **1 048 576 pixels d'aire**, minimum 1 par axe et bounds de map. Cette limite borne un travail ponctuel mesuré ; elle ne garantit pas un resize à 60 FPS. Translation seule/taille naturelle des éléments actuels ne subissent pas ce nouveau plafond. P3 doit réutiliser et borner les données dérivées au lieu d'enregistrer un million de samples à chaque mouvement.
- Préflight MCP pendant l'implémentation : `pokemap_describe` retourne `worker.exited`, code 254. Aucune parité live revendiquée ; recontrôle après stabilisation, build et chargement du worker.
- Après stabilisation des sources de format : nouvel appel `pokemap_describe` réussi (`ok=true`, protocole `pokemap.authoring.v1`, 360 actions). La future action de géométrie n'existe pas encore : cette reprise ne valide pas P4.

### P1 — Socle géométrique vérifié

- Types `PixelOffset`/`PixelSize`, champs d'occurrence, normalisation, rectangles logique/visuel, sélection pixel/couverture cellule, validation complète/delta, rotation des dimensions et crop implémentés. Les offsets atlas restent visuels et constants dans les axes de la map.
- Tests RED de désérialisation des champs ignorés et taille fractionnaire prouvés avant correction. Commande finale depuis `packages/map_core` : `dart test test/map_placed_element_geometry_test.dart test/placed_elements_test.dart test/map_placed_element_rotation_test.dart test/placed_element_visual_order_test.dart test/map_resize_plan_test.dart` ; **75 tests réussis**, exit 0, `remainingOwnedProcesses={}`. Reçu : `/tmp/pokemap-transform.031d1V/core-p1-order-index.json`.
- `dart analyze` : exit 0, 122 diagnostics informatifs, zéro warning/erreur ; aucun sur les nouvelles lignes. Analyse ciblée après correction d'index : `No issues found!`. `git diff --check` : exit 0.
- Revue conformité favorable après correction de la sélection cellule des occurrences de 1 pixel ; revue qualité favorable après mutualisation de l'index tilesets et du calcul des bounds source lors du classement visuel.
- Génération limitée aux modèles concernés ; churn généré hors lot retiré sans opération Git d'écriture. Les consommateurs collision, runtime, authoring et UI restent à implémenter : P1 ne constitue pas une livraison de la fonctionnalité.

### Format v8 strict — vérifications ciblées

Codecs, validateurs, factories, fonctions cinématiques et présentations, exports et compatibilité Hub utilisent v8. Les formats projet/map antérieurs, absents ou futurs sont refusés ; le format ZIP reste 1 et les algorithmes Smart Tiles V6 gardent leurs identifiants. Les fixtures positives suivent le format courant. L'ancien outil de migration est inchangé ; ses tests attestent désormais le refus strict sans écriture.

Reçus sous `/tmp/pokemap-transform.031d1V`, tous avec `remainingOwnedProcesses={}` et exit 0 : `format-v8-core-contracts-green` (74), `format-v8-legacy-refusal` (6), `format-v8-distribution-green` (144), `format-v8-authoring-green` (37), `format-v8-hub` (3), `format-v8-studio-green` (27), `format-v8-editor-export` (27). Le test de compatibilité atteste qu'un host v7 refuse un paquet v8 et qu'un host v8 l'accepte. Studio couvre ouverture, sauvegarde, réouverture et refus v6 sans modification des octets.

La première suite complète core a donné 4 711 succès, 1 skip et 7 échecs ; les trois échecs de fixtures liés au format ont ensuite été corrigés et revérifiés. Quatre échecs restent hors périmètre supposé, sans baseline HEAD attestée : `project_item_reference_index_test`, `scene_runtime_dry_run_preview_test`, `beta_playability_composition_test`, `cinematic_media_contract_fixture_test`. Aucune suite complète verte revendiquée.

`dart analyze` core : exit 0, 122 informations. `git diff --check` : exit 0. Hygiène Markdown avec l'override autorisé pour ce seul plan : exit 0. Conformité finale et revue qualité favorables ; aucune anomalie bloquante restante dans ce lot. P2 collisions/comportements en cours.

Préflight natif : dépendances Marionette et entrypoint déterministe déjà présents, appareil macOS disponible. Fixture synthétique v8 créée par l'outil existant, exit 0, sous `/Users/karim/Library/Containers/com.yoahnl.pokemap.editor/Data/Documents/pixel-transform-qa-20260929-031d1V`. Aucun projet utilisateur source n'a été modifié ; aucun parcours de la nouvelle fonctionnalité n'est encore revendiqué.

### P2 — Collisions et comportements vérifiés

Helper core `resolveMapPlacedElementCollisionRects`, méthode inverse exacte `QuarterTurnPixelTransform.sourcePixelRectToDestinationPixelRect`, stamping de rectangles dans les chunks existants, couverture des comportements et overlay authoring branchés. Aucun bitmap destination intermédiaire ; les masques source restent prioritaires sur les cellules. Les dimensions explicites de `GameplayWorldState` sont respectées ; le Player lui transmet les dimensions projet sans displayScale.

Fichiers du lot : `packages/map_core/lib/map_core_domain.dart`, `src/operations/map_placed_element_footprint.dart`, nouveau `src/operations/map_placed_element_collision_geometry.dart` et son test ; `packages/map_gameplay/lib/src/gameplay_world_state.dart`, `src/collision/world_collision_storage.dart`, nouveau `test/placed_element_transform_gameplay_test.dart` ; `packages/map_authoring/lib/src/domains/maps/collision_actions.dart` et `test/domains/maps/effective_collision_test.dart`.

RED comportemental attesté avant correction : 7 échecs gameplay et 2 échecs overlay. Résultats finaux : **53 tests core, 79 gameplay, 6 authoring et 7 cooldown runtime réussis**, exit 0. Analyses : core 122 informations, gameplay 1 information existante, authoring aucune anomalie, tous exit 0. `git diff --check` exit 0. Revues conformité et qualité favorables. Commandes et reçus exacts : `/tmp/pokemap-transform.031d1V/p2-{core-green,gameplay-final,authoring-final,runtime-cooldown,core-analyze,gameplay-analyze,authoring-analyze}.{json,log}` ; aucun processus possédé restant.

P4 est exécuté avant P3, conformément à l'indépendance de ces lots après le socle.

### P4 — Action canonique et transports vérifiés

Action `placed_element.set_geometry` v1 : position absolue et taille entière, `pixelSize` obligatoire et nullable pour le retour naturel, paramètres stricts, validation atomique, refus des occurrences générées. Update conserve l'ordre de la liste et sa normalisation existante. Une régression de nettoyage des propriétés/effets a été démontrée par deux échecs comportementaux puis corrigée ; les IDs manquants étaient déjà traités au décodage. Revues conformité et qualité finales favorables.

Fichiers : `packages/map_authoring/lib/src/domains/maps/placed_element_actions.dart`, `lib/src/parity/full_authoring_parity.dart`, nouveau `test/domains/maps/placed_element_geometry_transport_test.dart` ; nouveau `packages/map_editor/test/authoring_api/placed_element_geometry_transport_test.dart` ; `tools/pokemap_mcp/test/mutation_server.test.ts` et catalogue racine existant. Les tests utilisent les vrais transports API, worker JSONL, adapter editor et client MCP relié au serveur.

Preuves finales : **30 tests authoring/parité/spatial/order, 1 test adapter editor et 1 test MCP ciblé réussis**, exit 0. Analyses ciblées authoring/editor sans anomalie. `npm run check` et `npm run build` exit 0 ; suite npm complète réservée à P7. Reçus `/tmp/pokemap-transform.031d1V/p4-{final-contracts,final-analyze,editor-query,editor-analyze,mcp-targeted2,npm-check,npm-build,final-live}.{json,log}`, aucun processus possédé restant.

Client MCP stdio neuf, build courant : catalogue **361 actions**, nouvelle action v1 présente. Sur fixture jetable sous root autorisé : détachement, géométrie `(83,69)` et `23×37`, relecture `(5,4)` + offset `(3,5)`, ordre stable, puis deux undo et restauration exacte. Validation structure/références : aucun diagnostic avant/après. Validation globale négative avec les mêmes neuf erreurs Pokémon de cette fixture de démonstration ; aucune certification globale revendiquée. Projection runtime transformée réimportée via `MapData.fromJson` sans perte ; archive ZIP transformée et parcours Player restent des preuves P7 distinctes.

P3 est en cours. P5 inclura le marqueur authored pour les nouveaux placements Studio et une action guidée de détachement pour les occurrences hors autorité Environment ; changer seulement la propriété d'un objet encore géré par un environnement serait insuffisant. Le rendu, les gestes Studio, les consommateurs secondaires et la certification native restent ouverts. Aucun commit ni opération Git d'écriture.

### P7 — Premières vérifications indépendantes

Après le build P4, phase complète de `npm test` exécutée sans son rebuild : `node --import tsx --test --test-concurrency=1 test/**/*.test.ts`, depuis `tools/pokemap_mcp`. **84 tests réussis, aucun échec ni skip**, exit 0, 479 632 ms, aucun processus possédé restant. Preuves `/tmp/pokemap-transform.031d1V/p7-mcp-full.{json,log}`.

`dart run tool/pmcp085_conformance.dart`, depuis `packages/map_authoring` : **exit 1**. Catalogue complet, aucune cellule manquante/bloquée, 86 ressources et 361 actions ; `placed_element.set_geometry` dispose des quatre preuves de transport. Certification globale et Items non acquise lors de cette invocation sans bundle `--transport-receipts`. Ce résultat ne vaut ni certification globale ni comparaison avec une baseline HEAD. Reçus `p7-pmcp085-global.{json,log}`, aucun processus possédé restant.

Préparation native : Marionette fournit les gestes usuels et Shift + flèche, mais pas de maintien de Shift pendant un drag ; les API CUA natives consultées n'exposent pas non plus de key-down/up séparés. Ne pas présenter un simple envoi de touche comme une marche Player observée. Deux applications Studio partagent actuellement le bundle ID : le futur test doit utiliser son propre lancement, son URI VM et la preuve `avelune.activeProject` du fixture jetable. Aucun lancement ni parcours de la nouvelle fonctionnalité attesté à ce stade.

Audit ciblé de propriété Environment : le détachement existant ne retire pas l'ID des `generatedPlacementIds`, tandis que la régénération supprime/recrée ces IDs indépendamment du marqueur. Le garde-fou doit donc considérer cette propriété réelle dans le setter, les validations complète/delta, l'action de détachement et l'UI. Correction ciblée prévue avant P5 ; aucune nouvelle extraction complète d'environnement.

### P3 — Rendu partagé et aperçu : vérifications finales

Géométrie commune branchée dans le rendu, le culling, les masques et les ombres. L'aperçu remplace une occurrence dans les candidats de l'index immuable ; les plans de dessin sont locaux, bornés et indépendants de la translation. Le renderer expose `setPlacedElementPreview`, `clearPlacedElementPreview`, `setCollisionOverlay` et `dispose`. Le widget Studio libère le renderer remplacé ou démonté. Le rendu par quarts de tour est exporté par `map_runtime_authoring.dart` pour les consommateurs P6.

La revue a fait corriger l'index de recouvrement des animations (union de leurs frames), les couches masquées/translucides et la séparation effective des patches. Les régions masquées sont composées une seule fois dans l'ordre visuel, avec attribution disjointe lorsque plusieurs patches se recouvrent. La réservation dépend des patches réellement créés et des images disponibles. Les régressions ont été reproduites avant correction ; une référence indépendante calcule l'image projet puis la zoome en nearest-neighbor à 50 %, 150 %, 200 % et 300 %.

Commande finale depuis `packages/map_runtime` : `flutter test test/placed_element_transform_render_test.dart test/playable_map_game_placed_element_occlusion_test.dart test/static_placed_element_occlusion_patch_resolution_test.dart test/quarter_turn_pixel_renderer_test.dart test/placed_element_occlusion_patch_component_test.dart test/runtime_authoring_map_renderer_order_test.dart test/map_layers_component_performance_profile_test.dart --reporter expanded` : **79 tests réussis**, exit 0. Analyse ciblée : `No issues found!`, exit 0. Reçus `/tmp/pokemap-transform.031d1V/p3-reserved-{final,analyze}.{json,log}`, aucun processus possédé restant. `git diff --check` exit 0. Revues finales conformité et qualité favorables, aucun finding restant sur les corrections relues. P3 terminé, P5 en cours.

Inventaire production P3 : `packages/map_runtime/lib/map_runtime_authoring.dart`, `src/application/authoring_preview/runtime_authoring_map_renderer.dart`, `src/infrastructure/runtime_tileset_image.dart`, `src/presentation/flame/{map_layers_component,placed_element_occlusion_patch_component,playable_map_game,playable_map_game_interactions,quarter_turn_pixel_renderer,static_placed_element_occlusion_patch_resolution}.dart`, `src/shadow/{runtime_projected_building_shadow_collection,runtime_static_placed_element_shadow_sources,static_placed_element_shadow_runtime_resolver}.dart` ; widget de durée de vie Studio précité. Tests ajoutés/modifiés : `placed_element_transform_render_test.dart`, `playable_map_game_placed_element_occlusion_test.dart`, `quarter_turn_pixel_renderer_test.dart`, `static_placed_element_occlusion_patch_resolution_test.dart`, `shadow/runtime_projected_building_shadow_collection_test.dart` dans `packages/map_runtime/test`.

Mesure locale du sampler/cache uniquement, avant la dernière correction de composition dont le draw plan est inchangé : `/tmp/pokemap-transform.031d1V/p3-final-merged-probe.log`. Source 1024² → 1023², rotation 1, masque plein : préparation cache 66 992 µs, 2 046 runs, picture 212 984 octets ; masque alterné : 216 972 µs, 523 265 runs, 29 303 040 octets. Source 256² → 1024² alternée : 27 168 µs, 32 768 runs, 1 835 208 octets. Cache résident dérivé borné à 32 MiB ; ces observations ne bornent ni le pic RSS/GPU ni le coût d'une frame complète et ne certifient pas 60 FPS.

Préparation native complémentaire : seul le manifeste du fixture jetable a reçu un profil d'ombre typé pour l'arbre ; relecture et égalité du modèle vérifiées, exit 0. Sauvegarde locale `project.before-shadow.json` dans ce fixture. Nouveau SHA-256 du manifeste : `a9b06fdf1083844dcadcded129c042b23e8d8d0a3f72aea6a71a1daab83cc4cf`. Les cartes et l'atlas sont inchangés ; aucune donnée utilisateur n'a été modifiée.

### P7 — Smokes et build du host

Après stabilisation du socle P5, commandes indépendantes de l'interface en cours :

- Depuis `packages/map_runtime`, `flutter test test/phase_a_golden_battle_slice_smoke_test.dart test/playable_map_game_save_load_transaction_test.dart --reporter expanded --concurrency=1` : **8 succès**, exit 0, aucun processus possédé restant ; reçu `p7-runtime-smoke`.
- Depuis `examples/playable_runtime_host`, `flutter test test/phase_a_golden_slice_launch_test.dart --reporter expanded --concurrency=1` : **14 succès**, exit 0, aucun processus possédé restant ; reçu `p7-host-smoke`.
- Depuis ce même host, `flutter build macos --debug --no-pub` : **exit 0**, application `build/macos/Build/Products/Debug/PokeMap Selbrume.app`, avertissements de dépréciation Apple dans les dépendances ; reçu `p7-host-build`. Trois enfants `ibtoold` restaient au reçu : PID 16409, 16410 et 17010. UID, date de démarrage et commande revérifiés identiques au suivi de ce run, TERM ciblé puis `ps` confirmant leur sortie. Aucun kill global.
- `flutter analyze` runtime : **exit 1**, une information `avoid_relative_lib_imports` dans `tool/import_battle_se_assets.dart:3:8`, fichier non modifié ; reçu `p7-runtime-analyze`. L'analyse ciblée P3 reste sans diagnostic.
- `flutter analyze` host : **exit 1**, 22 informations et trois erreurs dans `lib/src/golden_item_system_journey.dart:636/645` : paramètres `encounterSourceId`/`encounterSourceKind` manquants et ancien `zoneId`. Appelant et contrat `packages/map_runtime/lib/src/application/battle_start_request.dart` non modifiés ; `git show HEAD` confirme déjà la même signature incompatible. Constat indépendant de ce chantier par comparaison des sources, sans exécution d'une baseline complète. Reçu `p7-host-analyze`, aucun processus possédé restant.

Tous ces reçus sont sous `/tmp/pokemap-transform.031d1V`. Aucune analyse globale entièrement verte ni certification native des gestes n'est revendiquée.

Preuve d'archive transformée réalisée : le test `apps/pokemap_hub/test/features/installation/avelune_studio_export_player_e2e_test.dart` exporte réellement depuis Studio, rend le projet auteur inaccessible, installe via `GamePackageInstaller`, résout le projet installé et exécute le Player. Le fixture désactive Pokémon par configuration canonique, sans stub de son validateur. Le reçu `p6-export-final` confirme un succès ; détails finaux ci-dessous.

### Audit des quatre échecs core restants

Comparaison en lecture seule avec `git show HEAD`, sans exécution d'une baseline HEAD :

- `project_item_reference_index_test.dart:194`, attendu 17/obtenu 18 : test et collecteurs identiques. La même condition d'inventaire est recensée comme `sceneInventoryCondition` puis `condition`, catégories distinctes dans l'égalité ; aucun élément placé ni contrôle de version dans ce calcul.
- `scene_runtime_dry_run_preview_test.dart:191` : test, moteur et enum identiques ; 14 conséquences construites face aux 16 valeurs de l'enum, `grantRailCurrency` et `grantRailStamp` déjà présentes dans HEAD mais absentes du test.
- `beta_playability_composition_test.dart:51` : test et catalogue identiques ; le fichier `project_regional_map_validator.dart` existe dans HEAD et manque déjà au catalogue.
- `cinematic_media_contract_fixture_test.dart:37`, attendu 3200/obtenu 2900 : test/calculateur inchangés ; le marker est déjà instantané dans HEAD, total `1000 + 500 + 300 + 300 + 800 + 0 = 2900`. Le seul changement de fixture est v6 → v8, sans incidence sur les durées.

Verdict de cette passe indépendante : causes présentes dans les sources HEAD, aucune causalité v8/transformation identifiée. Aucune réparation hors périmètre ni suite complète verte revendiquée.

### P5 — Vérification finale Studio

Les revues de conformité et de qualité sont favorables, sans finding restant. `p5-final-studio` : **82 tests réussis**, 15 suites, exit 0 ; `p5-core-final` : **26 succès** ; `p5-authoring-geometry` : **2 succès** API/CLI. Les trois reçus ne conservent aucun processus possédé. Analyse ciblée Studio sur 25 fichiers : aucun problème ; action authoring : aucun problème ; core : trois informations préexistantes dans `validators.dart:118–120`, exit 0. `git diff --check` : exit 0.

Les tests couvrent le geste aux zooms 0,5/1/1,5/2/3 avec displayScale 2, le changement de Shift sans saut, le bord opposé fixe, l’annulation, l’historique groupé, les champs et la sauvegarde/réouverture. Trois poignées sont exercées explicitement (droite, gauche, bas-droite) ; les huit mappings utilisent l’algorithme commun et sont revus, sans prétendre à huit tests natifs distincts. La comparaison RGBA montre que `resources.canvas(candidate)` produit le même rendu que la transformation enregistrée ; l’effacement du preview retrouve le rendu initial. Le test de réouverture a reproduit puis corrigé l’absence du contexte manifest dans `LocalMapWorkspaceAdapter.loadMap`.

Les éléments possédés par Environment sont protégés par un index partagé, y compris dans les zones masquées. Le détachement, la géométrie et les validations complète/delta consultent cette propriété réelle ; modifier seulement le marqueur ne contourne plus la protection. Les placements Studio nouveaux sont indépendants. L’overlay des collisions runtime est activé en sélection ; les outils de peinture/effacement gardent leur aperçu existant.

Commandes finales des groupes P3/P5, depuis leur package respectif :

```text
packages/map_runtime
flutter test test/placed_element_transform_render_test.dart test/playable_map_game_placed_element_occlusion_test.dart test/static_placed_element_occlusion_patch_resolution_test.dart test/quarter_turn_pixel_renderer_test.dart test/placed_element_occlusion_patch_component_test.dart test/runtime_authoring_map_renderer_order_test.dart test/map_layers_component_performance_profile_test.dart --reporter expanded

apps/avelune_studio
flutter test test/map_workspace/decor_transform_host_test.dart test/map_workspace/decor_move_host_test.dart test/map_workspace/decor_placement_preview_host_test.dart test/map_workspace/decor_order_e2e_test.dart test/map_workspace/inspector_fields_undo_test.dart test/map_workspace/tile_paint_preview_test.dart test/map_workspace/map_collision_stroke_test.dart test/map_workspace/context_menu_test.dart test/map_workspace/context_menu_host_test.dart test/map_workspace/context_menu_parity_test.dart test/infrastructure/studio_map_resources_test.dart test/infrastructure/map_workspace_io_test.dart test/terrain_canvas_test.dart test/cinematics/cinematic_library_thumbnail_ui10_test.dart test/presentation/workspace_resource_diagnostics_test.dart --reporter expanded
```

### P6/P7 — Findings de la revue transversale en cours

La revue inter-paquets confirme les conventions de géométrie P0–P5, mais identifie une borne manquante dans le cache d’overlay des collisions : 64 entrées de listes complètes, indexées par taille, peuvent conserver 64 variantes d’un masque damier volumineux. Le plafond du cache graphique ne couvre pas ces listes. Correction exigée avant gel : réutiliser la préparation source entre tailles et vérifier la conservation bornée ; aucune mesure RSS/GPU/FPS n’est déduite de ce constat statique.

La revue partielle P6 identifie aussi deux masques de projection hérités, dans le painter de carte et le fond cinématique, qui traitent encore les occurrences indépendantes comme une projection de tuiles. Cela peut effacer ou promouvoir au premier plan une tuile de fond après réduction/décalage. La sélection doit également résoudre la frame avec les mêmes options d’animation de l’occurrence que le painter lorsque les offsets atlas varient. Corrections et régressions ciblées demandées ; aucun verdict P6 global avant leur vérification.

La recherche initiale d’un réglage de grille était incomplète : l’ancienne toolbar expose `Tile Width/Height`. Passer de 16 à 8 avec un résidu de 15 peut rendre une carte illisible si seul le manifeste est sauvegardé. Le coordinateur lifecycle existant ne permet ni plusieurs maps ni la modification de `manifest.settings` ; sa garantie est récupérable, pas une atomicité multi-fichiers. Le journal authoring pourrait porter un futur cas d’usage global, mais ajouter cette sémantique est écarté pour garder ce lot ciblé. Décision explicitement annoncée : charger et valider toutes les cartes avec le manifeste cible avant toute écriture, refuser le changement invalidant avec un diagnostic, permettre les changements qui restent valides. **Limite assumée par rapport au plan initial : pas de renormalisation automatique multi-map.**

Les validations sans manifeste dans les use cases anciens d’entités, triggers, warps, zones, calques, environnement, resize, tileset et lifecycle sont également alignées ; autrement ces outils peuvent refuser une carte qui conserve un décor transformé. Le contexte est propagé depuis les appelants, sans assouplir le codec ni le validateur.

### P7 — Analyse Studio et contrôle natif

`apps/avelune_studio`: `flutter analyze` : **aucun problème**, exit 0 (`p7-studio-analyze`). `packages/map_distribution`: `dart analyze` : une information `unnecessary_library_name` dans `lib/map_distribution.dart:1:9`, exit 0 (`p7-distribution-analyze`). Aucun processus possédé restant.

Le lancement natif de `dev/marionette_main.dart` a compilé le Studio macOS et confirmé `avelune.activeProject` sur le seul fixture jetable. Les captures et l’arbre des widgets fonctionnent. Deux chemins de clic puis Tab/Enter n’ont pas produit de nouvelle frame : diagnostic VM en lecture seule, `lifecycleState=hidden`, `framesEnabled=false`, vue ID 0, aucun verrou de binding. Les actions Marionette demandent un frame que Flutter ignore dans cet état. `get_logs` échoue car le bootstrap n’a pas de collecteur ; la console Flutter possédée ne montre pas d’exception. CUA résout le chemin et le nom de l’exécutable vers l’autre application Studio ouverte sur Train : aucune action effectuée dans cette application. Affichage de la fenêtre de test demandé à l’utilisateur ; le parcours natif reste non validé tant que cette preuve manque.

Après affichage par l’utilisateur, la connexion confirme à nouveau le fixture exact et les contrôles natifs. Maj + flèche droite puis sauvegarde ont persisté `pos=(14,3), pixelOffset=(1,0)` sur l’occurrence indépendante `studio-1790716764657885-1`. Des tailles indépendantes `35×48` et `32×19` ont été relues après saisie/sauvegarde. Ces observations ne constituent pas un parcours visuel complet : la VM a de nouveau indiqué `hidden`, frames désactivées, à 21:26 UTC ; certains contrôles/captures étaient donc périmés. Une tentative `scrollTo` a échoué dans l’extension après 30 essais, sans exception applicative identifiée. L’utilisateur a ensuite explicitement demandé de poursuivre les tests automatisés et de lui laisser la vérification visuelle. Aucun autre geste natif n’est envoyé après cette décision ; fermeture/réouverture, drag natif avec Maj et approbation visuelle restent à sa revue.

### P7 — Rebuild et preuve MCP finale

Depuis `tools/pokemap_mcp`, `npm run check`, `npm run build`, puis `node --import tsx --test --test-name-pattern='MCP pixel geometry' test/mutation_server.test.ts` : **exit 0**, test ciblé **1 succès, 0 échec/skip**. Reçus `p7-mcp-{check,build,geometry}`. Client stdio neuf lancé sur `dist/src/index.js` avec root limité au fixture jetable : `pokemap_describe` retourne **361 actions**, `placed_element.set_geometry` v1 et ses garanties de révision/idempotence/undo. Détachement puis position `(83,69)`, taille `23×37`, relecture `(5,4)` + offset `(3,5)`, ordre stable ; deux undo restaurent le modèle exact. Reçu `p7-mcp-live`, exit 0. Structure et références sans diagnostic ; validation globale toujours négative pour les mêmes neuf catalogues/répertoires Pokémon manquants de ce fixture. Aucun processus possédé restant dans les quatre reçus. Cette preuve utilise son propre serveur actuel, sans arrêter un serveur partagé d'une autre session.

### P6 — Résultats vérifiés des consommateurs et de la distribution

Les consommateurs hérités utilisent la géométrie commune : painter et fond cinématique échantillonnent la frame complète ; sélection et culling prennent en compte les frames et offsets atlas ; déplacement/rotation préservent les champs. Les ombres adaptent ancrage et silhouette, sans multiplier la direction ni la longueur de la lumière monde. Réindexation, régénération, clone et remplacement d’asset préservent les occurrences indépendantes. Le manifeste est transmis aux lecteurs, validations, journaux, transactions lifecycle et sauvegardes, notamment duplication et renommage.

Le garde de changement de grille valide toutes les cartes persistées et la carte active non sauvegardée avant toute écriture. Un changement invalidant est refusé ; aucun convertisseur multi-map n’est ajouté.

Le cache de collisions conserve au plus 64 préparations source et 1 Mio de chaînes normalisées dérivées, avec éviction FIFO. Les données Base64 canoniques du modèle sont empruntées. Les rectangles sont projetés paresseusement ; la préparation n’est plus multipliée par taille/rotation/translation. Une normalisation trop volumineuse reste transitoire. Le scan source demeure proportionnel au masque, sans borne viewport ; ceci ne constitue pas une mesure RSS, GPU ou FPS.

| Reçu | Périmètre | Résultat |
| --- | --- | --- |
| `p6-render-final` | Painter, cinématique, rotation, hit-test, déplacement | 87 succès |
| `p6-journal-final` | Journal et session de sauvegarde | 35 succès |
| `p6-grid-draft-final` | Grille, carte active et absence d’écriture invalide | 11 succès |
| `p6-preservation-final` | Indexer, régénération et ombres | 53 succès |
| `p6-regeneration-green` | Régénération Environment | 16 succès |
| `p6-assets-clone` | Clone, remplacement et transports authoring | 12 succès |
| `p6-lifecycle-context` | Transactions et gateway de sauvegarde | 25 succès |
| `p6-collision-core` | Géométrie et cache collision | 2 succès |
| `p6-collision-gameplay` | Collisions, rotation et gameplay | 33 succès |
| `p6-collision-final` | Rendu et overlay collision runtime | 12 succès |
| `p6-export-final` | Export Studio → installation → Player | 1 succès |

Tous ces reçus terminent avec exit 0 et `remainingOwnedProcesses={}`. Certains groupes se recouvrent : ne pas sommer ces nombres comme un nombre de tests uniques. Analyses ciblées `p6-editor-analysis-green`, `p6-runtime-analysis-final`, `p6-core-analysis-final`, `p6-hub-analysis` et `p6-last-context-analysis` : aucun problème, exit 0.

Commandes P6 complémentaires, lancées depuis le package indiqué :

```text
packages/map_editor
flutter test test/cinematic_map_backdrop_placed_element_rotation_test.dart test/map_grid_painter_test.dart test/features/editor/application/map_placed_element_rotation_planner_test.dart test/features/editor/application/map_canvas_object_hit_test_test.dart test/features/editor/application/map_canvas_object_move_planner_test.dart --reporter expanded
flutter test test/narrative_event_spatial_link_journal_repository_test.dart test/narrative_event_authoring_session_test.dart --reporter expanded
flutter test test/placed_element_instance_indexer_test.dart test/environment_studio/environment_regenerate_shuffle_test.dart test/application/shadow/editor_static_shadow_preview_test.dart --reporter expanded
flutter test test/environment_studio/environment_regenerate_shuffle_test.dart test/environment_studio/tile_layer_environment_regenerate_shuffle_use_case_test.dart --reporter expanded
flutter test test/infrastructure/repositories/map_lifecycle_transaction_file_gateway_test.dart test/application/services/map_lifecycle_transaction_service_test.dart --reporter expanded

packages/map_authoring
dart test test/domains/assets/content_addressing_test.dart test/domains/maps/placed_element_geometry_transport_test.dart --reporter expanded

packages/map_core
dart test test/map_placed_element_collision_geometry_test.dart --reporter expanded

packages/map_gameplay
dart test test/placed_element_transform_gameplay_test.dart test/placed_elements_collision_test.dart test/placed_element_rotation_gameplay_test.dart --reporter expanded

packages/map_runtime
flutter test test/placed_element_transform_render_test.dart --reporter expanded

apps/pokemap_hub
flutter test --no-pub test/features/installation/avelune_studio_export_player_e2e_test.dart --reporter expanded
```

L’archive réellement exportée conserve v8, ordre des occurrences, offset (3,5), taille 29×17, rotation q=1, offset atlas (2,-1), catalogue et configuration d’ombres. Le dossier auteur est renommé `.offline` avant installation. Le Player installé recharge deux fois le bundle et exécute chargement, déplacement, dialogue et warp. Cette preuve automatisée ne remplace pas l’approbation visuelle demandée à Yoahn.

### P7 — Consolidation finale des contrôles automatisés

- `p7-studio-final` relance la commande Studio de §11 avec `--concurrency=1` : **82 succès**, exit 0, aucun processus possédé restant.
- `p7-mcp-geometry-final` relance le test MCP de géométrie après les corrections communes : **1 succès, 0 échec/skip**, exit 0, aucun processus possédé restant.
- `p7-editor-analyze-full`, `flutter analyze` dans `packages/map_editor` : exit 1, seulement deux informations `unnecessary_import` dans les tests inchangés `cinematic_media_preview_controller_test.dart:6:8` et `selbrume_npc_state_commands_test.dart:6:8`. Aucune erreur ni warning. Les analyses ciblées des fichiers modifiés sont vertes.
- `p7-hub-analyze-full`, `flutter analyze` dans `apps/pokemap_hub` : aucun problème, exit 0.
- `p7-studio-build-final`, `flutter build macos --debug --no-pub` : exit 0, `PokeMap.app` construite. L’enfant `ibtoold` 68657 encore présent au reçu a quitté naturellement avant la tentative de nettoyage ; identité contrôlée et absence confirmée, aucun signal envoyé.

La certification globale PMCP085 et les suites globales core/host ne sont pas vertes ; leurs limites antérieures sont décrites plus haut. Le parcours visuel natif reste à la revue de Yoahn, à sa demande explicite. Le format est strictement v8 ; les anciens projets sont refusés, sans migration automatique.

### Revue finale, autocritique et état Git

Le dernier finding qualité concernait l’index spatial de l’ancien éditeur : l’union de frames éloignées pouvait allouer les cellules d’un vaste espace vide. L’index est maintenant limité à 256 cellules par occurrence ; au-delà, une entrée globale est filtrée par intersection demi-ouverte au viewport, sans changer ordre ni déduplication. Le test couvre des offsets atlas de 160 millions de pixels, une frame naturelle d’un million de cellules par axe et un objet normal. `p6-index-bound` : **32 succès**, commande `flutter test test/application/shadow/editor_static_shadow_preview_test.dart --reporter expanded` depuis `packages/map_editor`. Les analyses des deux fichiers, y compris après formatage (`p6-index-formatted-analysis`), ne trouvent aucun problème. Reçus exit 0, aucun processus possédé restant.

Revues finales indépendantes de `plan_architecture` (conformité) et `transform_format_audit` (qualité) : **favorables, aucun finding ouvert**, après relecture de ce correctif et de ses preuves. Les index globaux coûtent encore un parcours des grandes occurrences à chaque requête ; la borne concerne l’allocation de buckets par occurrence, pas toute la durée de rendu.

`p7-studio-build-frozen` : `flutter build macos --debug --no-pub` depuis `apps/avelune_studio`, **exit 0**, ligne `✓ Built build/macos/Build/Products/Debug/PokeMap.app`. Deux enfants `ibtoold` 79245/79246 identifiés par UID, heure de démarrage et commande ont reçu TERM après le build ; leur sortie est confirmée. Seul un formatage sans changement logique des deux fichiers d’index a suivi le lancement du build ; l’analyse ciblée après formatage est verte.

Autocritique : l’extension v8 touche beaucoup de fixtures et consommateurs ; les preuves ciblées sont vertes, mais les suites globales conservent les dettes documentées. Aucune certification générale de performances ou validation artistique n’est revendiquée. Les projets pré-v8 sont refusés conformément au choix explicite de Yoahn ; le projet externe Train n’a pas été modifié. La modification de grille invalidante est bloquée, sans conversion automatique des cartes. La session native de test initiale a été conservée pour l’utilisateur ; elle n’est pas une preuve visuelle de chaque correction finale.

État initial : branche `main`, HEAD `df9d134ae5326b05488d5b6e3668adca59566899`, fichiers suivis propres, plan approuvé non suivi. État final : même branche et HEAD, **487 fichiers suivis modifiés + 13 non suivis = 500 chemins**, aucun fichier staged. Aucun commit, push, rebase ou autre écriture Git. Les fixtures de version constituent l’essentiel du volume. Inventaire complet ci-dessous, ensemble comparé au dernier `git status` sans chemin manquant ou supplémentaire ; les diffs Git restent la preuve précise des zones modifiées, sans copie du contenu source. `git diff --check` : exit 0. `POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh` : exit 0, un seul nouveau Markdown en emplacement canonique.

Les zones fonctionnelles principales sont le modèle/codec/validateur et la géométrie partagée de `map_core`, les collisions de `map_gameplay`, les renderers/index/ombres/occlusion de `map_runtime`, le contrat et l’action géométrique de `map_authoring`, les gestes/commandes/inspecteur et I/O de Studio, les consommateurs et sauvegardes de `map_editor`, ainsi que distribution, Hub, host et MCP. Les nouveaux fichiers de géométrie, preview et tests sont inclus dans l’inventaire.

<details>
<summary>Inventaire final des 500 chemins (M : modifié ; ?? : non suivi)</summary>

```text
 M apps/avelune_studio/lib/features/map_workspace/application/editable_map_document.dart
 M apps/avelune_studio/lib/features/map_workspace/application/map_context_menu_model.dart
 M apps/avelune_studio/lib/features/map_workspace/application/map_editing_commands.dart
 M apps/avelune_studio/lib/features/map_workspace/data/local_map_workspace_adapter.dart
 M apps/avelune_studio/lib/features/presentations/data/local_presentation_adapter.dart
 M apps/avelune_studio/lib/features/presentations/data/local_presentation_projection.dart
 M apps/avelune_studio/lib/platform/rendering/studio_map_resources.dart
 M apps/avelune_studio/lib/platform/rendering/studio_map_visual_widgets.dart
 M apps/avelune_studio/lib/presentation/features/map_workspace/map_canvas_overlay_editing.dart
?? apps/avelune_studio/lib/presentation/features/map_workspace/map_decor_geometry_panel.dart
 M apps/avelune_studio/lib/presentation/features/map_workspace/map_decor_order_panel.dart
 M apps/avelune_studio/lib/presentation/features/map_workspace/map_decor_selection_summary.dart
?? apps/avelune_studio/lib/presentation/features/map_workspace/map_decor_transform_draft.dart
?? apps/avelune_studio/lib/presentation/features/map_workspace/map_decor_transform_overlay.dart
 M apps/avelune_studio/lib/presentation/features/map_workspace/map_selection_inspector.dart
 M apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_canvas.dart
 M apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_canvas_gestures.dart
 M apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_inspector.dart
 M apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_view_state.dart
 M apps/avelune_studio/lib/presentation/features/map_workspace/map_workspace_visuals.dart
 M apps/avelune_studio/test/cinematics/cinematic_adapter_ui10_test.dart
 M apps/avelune_studio/test/cinematics/cinematic_library_thumbnail_ui10_test.dart
 M apps/avelune_studio/test/infrastructure/studio_map_resources_test.dart
?? apps/avelune_studio/test/map_workspace/decor_transform_host_test.dart
 M apps/avelune_studio/test/map_workspace/tile_paint_preview_test.dart
 M apps/avelune_studio/test/presentation/workspace_resource_diagnostics_test.dart
 M apps/avelune_studio/test/support/cinematic_adapter_fixture.dart
 M apps/avelune_studio/test/support/map_workspace_fixture.dart
 M apps/avelune_studio/test/support/ui10_fixture_visuals.dart
 M apps/avelune_studio/test/support/ui12_return_harness.dart
 M apps/avelune_studio/test/support/ui13_verification_fixture.dart
 M apps/avelune_studio/test/terrain_canvas_test.dart
 M apps/pokemap_hub/integration_test/runtime_owned_player_flow_test.dart
 M apps/pokemap_hub/lib/core/config/avelune_host_compatibility.dart
 M apps/pokemap_hub/test/features/installation/avelune_studio_combat_player_e2e_test.dart
 M apps/pokemap_hub/test/features/installation/avelune_studio_export_player_e2e_test.dart
 M apps/pokemap_hub/test/features/installation/game_package_branding_installation_test.dart
 M apps/pokemap_hub/test/features/saves/game_save_update_preparation_test.dart
 M apps/pokemap_hub/test/fixtures/runtime_owned_player_game/project/maps/runtime_harbor.json
 M apps/pokemap_hub/test/fixtures/runtime_owned_player_game/project/project.json
 M apps/pokemap_hub/test/platform/avelune_host_compatibility_test.dart
 M apps/pokemap_hub/test/presentation/features/player/phase_6_personalization_packaging_e2e_test.dart
 M apps/pokemap_hub/test/support/game_package_fixture.dart
 M apps/pokemap_hub/test/support/runtime_owned_player_package_fixture.dart
 M apps/pokemap_hub/test/support/runtime_owned_player_package_fixture_test.dart
?? documentation/reports/avelune_studio/plans/as_map_transforms_pixel_resize_implementation_plan.md
 M examples/playable_runtime_host/golden_battle_slice/maps/golden_field.json
 M examples/playable_runtime_host/golden_battle_slice/project.json
 M examples/playable_runtime_host/golden_fangame_slice/maps/golden_route.json
 M examples/playable_runtime_host/golden_fangame_slice/maps/golden_summit.json
 M examples/playable_runtime_host/golden_fangame_slice/maps/golden_town.json
 M examples/playable_runtime_host/golden_fangame_slice/project.json
 M examples/playable_runtime_host/golden_item_system/maps/golden_item_lab.json
 M examples/playable_runtime_host/golden_item_system/project.json
 M examples/playable_runtime_host/golden_personalization_v3/maps/vermeil_village.json
 M examples/playable_runtime_host/golden_personalization_v3/project.json
 M examples/playable_runtime_host/p3_narrative_smoke_slice/maps/p3_narrative_smoke_field.json
 M examples/playable_runtime_host/p3_narrative_smoke_slice/project.json
 M examples/playable_runtime_host/phase6_authoring_golden_slice/project.json
 M examples/playable_runtime_host/test/evaluation/evaluation_project_projection_test.dart
 M examples/playable_runtime_host/test/golden_fangame_slice_fixture_test.dart
 M examples/playable_runtime_host/test/golden_item_system_fixture_test.dart
 M examples/playable_runtime_host/test/selbrume_v6_fixture_test.dart
 M examples/playable_runtime_host/test/standalone_presentation_session_test.dart
 M examples/playable_runtime_host/test/stn10_tiled_golden_workflow_test.dart
 M packages/map_authoring/benchmark/authoring_snapshot_open.dart
 M packages/map_authoring/benchmark/smart_tiles_rich_authoring_scaling.dart
 M packages/map_authoring/lib/src/domains/maps/collision_actions.dart
 M packages/map_authoring/lib/src/domains/maps/map_lifecycle_adapter.dart
 M packages/map_authoring/lib/src/domains/maps/placed_element_actions.dart
 M packages/map_authoring/lib/src/domains/maps/region_operations.dart
 M packages/map_authoring/lib/src/domains/maps/smart_tile_native_transition_guard.dart
 M packages/map_authoring/lib/src/domains/narrative/cinematic_library_actions.dart
 M packages/map_authoring/lib/src/domains/narrative/cinematic_library_placement.dart
 M packages/map_authoring/lib/src/domains/narrative/presentation_cinematic_actions.dart
 M packages/map_authoring/lib/src/domains/narrative/presentation_cinematic_template_actions.dart
 M packages/map_authoring/lib/src/domains/narrative/presentation_publication_guards.dart
 M packages/map_authoring/lib/src/domains/narrative/scene_actions.dart
 M packages/map_authoring/lib/src/parity/full_authoring_parity.dart
 M packages/map_authoring/test/contracts/query_pagination_test.dart
 M packages/map_authoring/test/domains/assets/content_addressing_test.dart
 M packages/map_authoring/test/domains/assets/map_graphics_reset_test.dart
 M packages/map_authoring/test/domains/assets/presentation_media_configuration_test.dart
 M packages/map_authoring/test/domains/assets/presentation_media_import_transaction_test.dart
 M packages/map_authoring/test/domains/assets/tiled_tileset_import_projection_test.dart
 M packages/map_authoring/test/domains/assets/tiled_tileset_import_transaction_test.dart
 M packages/map_authoring/test/domains/distribution/game_package_export_api_test.dart
 M packages/map_authoring/test/domains/maps/border_catalog_actions_test.dart
 M packages/map_authoring/test/domains/maps/effective_collision_test.dart
 M packages/map_authoring/test/domains/maps/map_lifecycle_contract_test.dart
 M packages/map_authoring/test/domains/maps/map_lifecycle_transaction_test.dart
 M packages/map_authoring/test/domains/maps/map_operations_batch_test.dart
 M packages/map_authoring/test/domains/maps/map_region_query_test.dart
?? packages/map_authoring/test/domains/maps/placed_element_geometry_transport_test.dart
 M packages/map_authoring/test/domains/maps/region_operations_test.dart
 M packages/map_authoring/test/domains/maps/smart_tile_catalog_actions_test.dart
 M packages/map_authoring/test/domains/maps/smart_tile_cell_actions_test.dart
 M packages/map_authoring/test/domains/maps/smart_tile_draft_actions_test.dart
 M packages/map_authoring/test/domains/maps/smart_tile_encounter_behavior_transport_parity_test.dart
 M packages/map_authoring/test/domains/maps/smart_tile_layer_actions_test.dart
 M packages/map_authoring/test/domains/maps/smart_tile_layer_editing_actions_test.dart
 M packages/map_authoring/test/domains/maps/smart_tile_layer_preset_change_action_test.dart
 M packages/map_authoring/test/domains/maps/smart_tile_resource_query_test.dart
 M packages/map_authoring/test/domains/maps/spatial_object_contract_test.dart
 M packages/map_authoring/test/domains/maps/tiled_map_import_transaction_test.dart
 M packages/map_authoring/test/domains/narrative/cinematic_atomic_placement_test.dart
 M packages/map_authoring/test/domains/narrative/cinematic_library_authoring_test.dart
 M packages/map_authoring/test/domains/narrative/presentation_cinematic_authoring_test.dart
 M packages/map_authoring/test/domains/narrative/presentation_cinematic_draft_test.dart
 M packages/map_authoring/test/domains/narrative/presentation_cinematic_template_authoring_test.dart
 M packages/map_authoring/test/domains/narrative/scene_pre_session_actions_test.dart
 M packages/map_authoring/test/domains/narrative/scene_presentation_create_and_link_actions_test.dart
 M packages/map_authoring/test/domains/project/battle_transition_default_actions_test.dart
 M packages/map_authoring/test/domains/project/runtime_audio_actions_test.dart
 M packages/map_authoring/test/parity/character_studio_full_parity_test.dart
 M packages/map_authoring/test/parity/full_authoring_parity_test.dart
 M packages/map_authoring/test/references/presentation_reference_projection_test.dart
 M packages/map_authoring/test/tooling/jsonl_artifact_staging_test.dart
 M packages/map_authoring/test/tooling/jsonl_border_catalog_flow_test.dart
 M packages/map_authoring/test/tooling/jsonl_cinematic_library_flow_test.dart
 M packages/map_authoring/test/tooling/jsonl_mutation_worker_test.dart
 M packages/map_authoring/test/tooling/jsonl_presentation_cinematic_flow_test.dart
 M packages/map_authoring/test/tooling/jsonl_presentation_cinematic_template_flow_test.dart
 M packages/map_authoring/test/tooling/jsonl_presentation_clip_batch_flow_test.dart
 M packages/map_authoring/test/tooling/jsonl_presentation_publication_ui11_test.dart
 M packages/map_authoring/test/tooling/jsonl_regional_map_flow_test.dart
 M packages/map_authoring/test/tooling/jsonl_scene_pre_session_flow_test.dart
 M packages/map_authoring/test/tooling/jsonl_smart_tile_native_flow_test.dart
 M packages/map_authoring/test/tooling/jsonl_visual_organization_test.dart
 M packages/map_authoring/test/transactions/idempotency_contract_test.dart
 M packages/map_authoring/test/workspace/project_snapshot_concurrency_test.dart
 M packages/map_authoring/test/workspace/project_snapshot_fingerprint_cache_test.dart
 M packages/map_authoring/test/workspace/project_snapshot_map_projector_test.dart
 M packages/map_authoring/test/workspace/project_snapshot_test.dart
 M packages/map_core/benchmark/group_hierarchy_scaling.dart
 M packages/map_core/benchmark/json_roundtrip_scaling.dart
 M packages/map_core/lib/map_core_domain.dart
 M packages/map_core/lib/src/models/enums.dart
 M packages/map_core/lib/src/models/geometry.dart
 M packages/map_core/lib/src/models/geometry.freezed.dart
 M packages/map_core/lib/src/models/geometry.g.dart
 M packages/map_core/lib/src/models/map_data.dart
 M packages/map_core/lib/src/models/map_data.freezed.dart
 M packages/map_core/lib/src/models/map_data.g.dart
 M packages/map_core/lib/src/models/map_placed_element_origin.dart
 M packages/map_core/lib/src/models/project_manifest.dart
 M packages/map_core/lib/src/models/project_manifest.freezed.dart
 M packages/map_core/lib/src/models/project_manifest.g.dart
 M packages/map_core/lib/src/operations/border_layer_operations.dart
 M packages/map_core/lib/src/operations/map_layers.dart
?? packages/map_core/lib/src/operations/map_placed_element_collision_geometry.dart
 M packages/map_core/lib/src/operations/map_placed_element_footprint.dart
 M packages/map_core/lib/src/operations/map_placed_element_visual_order.dart
 M packages/map_core/lib/src/operations/map_placed_elements.dart
 M packages/map_core/lib/src/operations/map_resize.dart
 M packages/map_core/lib/src/operations/smart_tile_layer_creation.dart
 M packages/map_core/lib/src/operations/smart_tile_layer_operations.dart
 M packages/map_core/lib/src/operations/tiled_map_compilation.dart
 M packages/map_core/lib/src/save/game_identity.dart
 M packages/map_core/lib/src/validation/map_delta_validator.dart
 M packages/map_core/lib/src/validation/validators.dart
 M packages/map_core/test/authored_layer_insert_index_test.dart
 M packages/map_core/test/badge_definition_test.dart
 M packages/map_core/test/border/border_catalog_operations_test.dart
 M packages/map_core/test/border/border_feature_update_operations_test.dart
 M packages/map_core/test/border/border_layer_integration_test.dart
 M packages/map_core/test/border/border_layer_operations_test.dart
 M packages/map_core/test/border/border_manifest_integration_test.dart
 M packages/map_core/test/border/border_project_map_preparation_test.dart
 M packages/map_core/test/border/border_publication_readiness_test.dart
 M packages/map_core/test/border/border_relink_operations_test.dart
 M packages/map_core/test/border/border_resize_test.dart
 M packages/map_core/test/border/border_validation_test.dart
 M packages/map_core/test/border/project_manifest_border_catalog_operations_test.dart
 M packages/map_core/test/cinematic_library_catalog_test.dart
 M packages/map_core/test/encounter_contract_test.dart
 M packages/map_core/test/environment_single_area_migration_test.dart
 M packages/map_core/test/fixtures/cinematic_media_contract/project.json
?? packages/map_core/test/map_placed_element_collision_geometry_test.dart
?? packages/map_core/test/map_placed_element_geometry_test.dart
 M packages/map_core/test/map_placed_tile_visual_resolver_test.dart
 M packages/map_core/test/map_resize_plan_test.dart
 M packages/map_core/test/narrative_event_legacy_corpus_test.dart
 M packages/map_core/test/narrative_event_registry_codec_test.dart
 M packages/map_core/test/pre_session_draft_condition_test.dart
 M packages/map_core/test/project_character_studio_migration_test.dart
 M packages/map_core/test/project_character_studio_model_test.dart
 M packages/map_core/test/project_dialogue_declared_outcomes_test.dart
 M packages/map_core/test/project_manifest_character_compatibility_test.dart
 M packages/map_core/test/project_manifest_cinematics_test.dart
 M packages/map_core/test/project_manifest_environment_presets_test.dart
 M packages/map_core/test/project_manifest_facts_test.dart
 M packages/map_core/test/project_manifest_presentation_cinematics_test.dart
 M packages/map_core/test/project_manifest_scenes_test.dart
 M packages/map_core/test/project_manifest_storylines_test.dart
 M packages/map_core/test/project_manifest_world_rules_test.dart
 M packages/map_core/test/project_new_game_config_test.dart
 M packages/map_core/test/project_new_game_entrypoint_migration_test.dart
 M packages/map_core/test/project_presentation_profile_test.dart
 M packages/map_core/test/project_regional_map_test.dart
 M packages/map_core/test/project_tileset_source_test.dart
?? packages/map_core/test/project_transform_format_v8_test.dart
 M packages/map_core/test/rail_journey_project_manifest_test.dart
 M packages/map_core/test/shadow/map_placed_element_shadow_json_test.dart
 M packages/map_core/test/shadow/project_element_entry_shadow_json_test.dart
 M packages/map_core/test/shadow/project_manifest_shadow_catalog_json_test.dart
 M packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart
 M packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart
 M packages/map_core/test/shop_definition_test.dart
 M packages/map_core/test/smart_tiles/project_manifest_smart_tile_catalog_test.dart
 M packages/map_core/test/smart_tiles/smart_tile_authoring_draft_compiler_test.dart
 M packages/map_core/test/smart_tiles/smart_tile_authoring_draft_test.dart
 M packages/map_core/test/smart_tiles/smart_tile_cell_context_test.dart
 M packages/map_core/test/smart_tiles/smart_tile_field_v5_test.dart
 M packages/map_core/test/smart_tiles/smart_tile_layer_creation_test.dart
 M packages/map_core/test/smart_tiles/smart_tile_layer_operations_test.dart
 M packages/map_core/test/smart_tiles/smart_tile_layer_readiness_candidate_weights_test.dart
 M packages/map_core/test/smart_tiles/smart_tile_layer_readiness_test.dart
 M packages/map_core/test/smart_tiles/smart_tile_layer_roundtrip_test.dart
 M packages/map_core/test/smart_tiles/smart_tile_layer_visual_plan_animation_time_test.dart
 M packages/map_core/test/smart_tiles/smart_tile_layer_visual_resolver_candidate_weights_test.dart
 M packages/map_core/test/smart_tiles/smart_tile_layer_visual_resolver_test.dart
 M packages/map_core/test/smart_tiles/smart_tile_pattern_test.dart
 M packages/map_core/test/smart_tiles/smart_tile_project_version_test.dart
 M packages/map_core/test/smart_tiles/smart_tile_reconstruction_test.dart
 M packages/map_core/test/tile_layer_palette_legacy_tileset_source_test.dart
 M packages/map_core/test/tile_layer_palette_test.dart
 M packages/map_distribution/test/fixtures/game_package_contract/contracts/examples/complete-valid/game-manifest.json
 M packages/map_distribution/test/fixtures/game_package_contract/contracts/examples/complete-valid/payload/project/project.json
 M packages/map_distribution/test/fixtures/game_package_contract/contracts/examples/invalid/future-package-format.json
 M packages/map_distribution/test/fixtures/game_package_contract/contracts/examples/invalid/invalid-game-id.json
 M packages/map_distribution/test/fixtures/game_package_contract/contracts/examples/invalid/path-traversal.json
 M packages/map_distribution/test/fixtures/game_package_contract/contracts/examples/invalid/unknown-required-field.json
 M packages/map_distribution/test/fixtures/game_package_contract/contracts/examples/minimal-valid/game-manifest.json
 M packages/map_distribution/test/fixtures/game_package_contract/contracts/examples/minimal-valid/payload/project/project.json
 M packages/map_distribution/test/game_package_builder_test.dart
 M packages/map_distribution/test/game_package_compatibility_test.dart
 M packages/map_distribution/test/game_package_inspector_test.dart
 M packages/map_distribution/test/game_package_personalization_preflight_test.dart
 M packages/map_distribution/test/phase0_contract_fixtures_test.dart
 M packages/map_editor/benchmark/authoring_session_lifecycle.dart
 M packages/map_editor/integration_test/editor_canvas_projection_journey_test.dart
 M packages/map_editor/integration_test/editor_performance_soak_journey_test.dart
 M packages/map_editor/integration_test/editor_project_journey_test.dart
 M packages/map_editor/integration_test/presentation_studio_performance_journey_test.dart
 M packages/map_editor/integration_test/support/presentation_studio_performance_fixture.dart
 M packages/map_editor/lib/src/app/providers/editor/project_use_case_providers.dart
 M packages/map_editor/lib/src/application/models/narrative_event_authoring_session.dart
 M packages/map_editor/lib/src/application/services/entity_editing_service.dart
 M packages/map_editor/lib/src/application/services/gameplay_zone_editing_service.dart
 M packages/map_editor/lib/src/application/services/map_lifecycle_transaction_service.dart
 M packages/map_editor/lib/src/application/services/trigger_editing_service.dart
 M packages/map_editor/lib/src/application/services/warp_editing_service.dart
 M packages/map_editor/lib/src/application/shadow/editor_projected_building_shadow_preview.dart
 M packages/map_editor/lib/src/application/shadow/editor_shadow_preview_projection_index.dart
 M packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
 M packages/map_editor/lib/src/application/use_cases/entity_use_cases.dart
 M packages/map_editor/lib/src/application/use_cases/environment_generator_clear_use_cases.dart
 M packages/map_editor/lib/src/application/use_cases/environment_generator_regenerate_use_cases.dart
 M packages/map_editor/lib/src/application/use_cases/environment_mask_use_cases.dart
 M packages/map_editor/lib/src/application/use_cases/gameplay_zone_use_cases.dart
 M packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart
 M packages/map_editor/lib/src/application/use_cases/map_use_cases.dart
 M packages/map_editor/lib/src/application/use_cases/project_management_use_cases.dart
 M packages/map_editor/lib/src/application/use_cases/project_tileset_use_cases.dart
 M packages/map_editor/lib/src/application/use_cases/tile_layer_environment_area_settings_use_cases.dart
 M packages/map_editor/lib/src/application/use_cases/tile_layer_environment_attachment_use_cases.dart
 M packages/map_editor/lib/src/application/use_cases/tile_layer_environment_clear_use_cases.dart
 M packages/map_editor/lib/src/application/use_cases/tile_layer_environment_regenerate_use_cases.dart
 M packages/map_editor/lib/src/application/use_cases/trigger_use_cases.dart
 M packages/map_editor/lib/src/application/use_cases/warp_use_cases.dart
 M packages/map_editor/lib/src/debug/marionette_personalization_qa_seed.dart
 M packages/map_editor/lib/src/features/editor/application/map_canvas_object_hit_test.dart
 M packages/map_editor/lib/src/features/editor/application/map_canvas_object_move_planner.dart
 M packages/map_editor/lib/src/features/editor/application/map_placed_element_rotation_planner.dart
 M packages/map_editor/lib/src/features/editor/application/project_element_frame_resolver.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/features/smart_tiles_studio/application/smart_tile_test_layer_controller.dart
 M packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
 M packages/map_editor/lib/src/infrastructure/repositories/map_lifecycle_transaction_file_gateway.dart
 M packages/map_editor/lib/src/infrastructure/repositories/narrative_event_spatial_link_journal_repository.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_renderer.dart
 M packages/map_editor/lib/src/ui/canvas/entity_editor_element_visual.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
 M packages/map_editor/test/application/cinematic_library_authoring_gateway_test.dart
 M packages/map_editor/test/application/editor_snapshot_profile_recorder_test.dart
 M packages/map_editor/test/application/presentation_studio_document_controller_test.dart
 M packages/map_editor/test/application/scene_presentation_create_and_link_draft_session_test.dart
 M packages/map_editor/test/application/scene_presentation_create_and_link_gateway_test.dart
 M packages/map_editor/test/application/services/map_lifecycle_transaction_service_test.dart
 M packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
 M packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
 M packages/map_editor/test/application/use_cases/map_lifecycle_use_cases_test.dart
 M packages/map_editor/test/application/use_cases/map_revisioned_lifecycle_use_cases_test.dart
 M packages/map_editor/test/application/use_cases/map_transactional_lifecycle_use_cases_test.dart
 M packages/map_editor/test/authoring_api/editor_mutation_parity_test.dart
 M packages/map_editor/test/authoring_api/no_bypass_guardrail_test.dart
?? packages/map_editor/test/authoring_api/placed_element_geometry_transport_test.dart
 M packages/map_editor/test/authoring_api/presentation_studio_add_authoring_gateway_test.dart
 M packages/map_editor/test/authoring_api/presentation_studio_draft_authoring_gateway_test.dart
 M packages/map_editor/test/authoring_api/presentation_studio_layer_authoring_gateway_test.dart
 M packages/map_editor/test/authoring_api/presentation_studio_property_authoring_gateway_test.dart
 M packages/map_editor/test/authoring_api/presentation_studio_timeline_authoring_gateway_test.dart
 M packages/map_editor/test/border_cinematic_backdrop_noop_test.dart
 M packages/map_editor/test/border_layer_dispatch_integration_test.dart
 M packages/map_editor/test/border_layer_inspector_test.dart
 M packages/map_editor/test/border_map_editing/active_border_feature_controller_test.dart
 M packages/map_editor/test/border_map_editing/border_feature_authoring_controller_test.dart
 M packages/map_editor/test/border_map_editing/border_feature_editor_integration_test.dart
 M packages/map_editor/test/border_map_editing/border_feature_inspection_test.dart
 M packages/map_editor/test/border_map_editing/border_preview_controller_test.dart
 M packages/map_editor/test/border_map_editing/border_resize_editor_integration_test.dart
 M packages/map_editor/test/border_map_editing/border_tool_availability_test.dart
 M packages/map_editor/test/border_map_editing/border_visual_goldens_test.dart
 M packages/map_editor/test/border_map_editing/editor_border_paint_order_test.dart
 M packages/map_editor/test/border_map_editing/editor_border_painter_integration_test.dart
 M packages/map_editor/test/border_map_editing/editor_map_layer_paint_order_test.dart
 M packages/map_editor/test/border_map_editing/map_canvas_border_selection_test.dart
 M packages/map_editor/test/border_map_editing/pending_border_save_entry_points_test.dart
 M packages/map_editor/test/border_map_editing/pending_border_save_notifier_test.dart
 M packages/map_editor/test/border_studio/border_publication_candidate_builder_test.dart
 M packages/map_editor/test/border_studio/border_publication_filesystem_integration_test.dart
 M packages/map_editor/test/border_studio/border_publication_transaction_test.dart
 M packages/map_editor/test/border_studio/border_studio_asset_crud_rules_widget_test.dart
 M packages/map_editor/test/border_studio/border_studio_draft_controller_test.dart
 M packages/map_editor/test/border_studio/border_studio_navigation_test.dart
 M packages/map_editor/test/border_studio/border_studio_organic_publication_end_to_end_test.dart
 M packages/map_editor/test/border_studio/border_studio_publication_coordinator_test.dart
 M packages/map_editor/test/border_studio/border_studio_publication_provider_test.dart
 M packages/map_editor/test/border_studio/border_studio_workspace_test.dart
 M packages/map_editor/test/border_studio/erw_connected_line_local_certification_test.dart
 M packages/map_editor/test/border_studio/file_border_publication_manifest_port_test.dart
 M packages/map_editor/test/border_studio/first_border_draft_and_layer_file_round_trip_test.dart
 M packages/map_editor/test/border_studio/organic_border_draft_file_round_trip_test.dart
 M packages/map_editor/test/character_studio_export_asset_closure_test.dart
 M packages/map_editor/test/character_studio_golden_slice_e2e_test.dart
 M packages/map_editor/test/cinematic_map_backdrop_placed_element_rotation_test.dart
 M packages/map_editor/test/cinematic_map_backdrop_smart_tile_render_plan_test.dart
 M packages/map_editor/test/cinematics_library_workspace_test.dart
 M packages/map_editor/test/collision_building_golden_slice_test.dart
 M packages/map_editor/test/dev/marionette_main_test.dart
 M packages/map_editor/test/editor_notifier_eraser_footprint_test.dart
 M packages/map_editor/test/editor_notifier_placed_element_placement_test.dart
 M packages/map_editor/test/editor_notifier_placed_element_rotation_test.dart
 M packages/map_editor/test/encounter_authoring_runtime_e2e_test.dart
 M packages/map_editor/test/environment_studio/environment_regenerate_shuffle_test.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_regenerate_shuffle_use_case_test.dart
 M packages/map_editor/test/features/character_studio/character_studio_identity_test.dart
 M packages/map_editor/test/features/character_studio/character_studio_library_test.dart
 M packages/map_editor/test/features/editor/application/map_canvas_object_hit_test_test.dart
 M packages/map_editor/test/features/editor/application/map_canvas_object_move_planner_test.dart
 M packages/map_editor/test/features/editor/application/map_context_command_projector_test.dart
 M packages/map_editor/test/features/editor/application/map_context_target_resolver_test.dart
 M packages/map_editor/test/features/editor/application/map_layer_grouping_paint_order_test.dart
 M packages/map_editor/test/features/editor/application/map_placed_element_rotation_planner_test.dart
 M packages/map_editor/test/features/editor/application/tiled_map_import_service_test.dart
 M packages/map_editor/test/features/editor/application/world_map_inspector_projector_test.dart
 M packages/map_editor/test/features/editor/application/world_map_paint_layer_routing_test.dart
 M packages/map_editor/test/features/editor/application/world_map_subtool_body_projector_test.dart
 M packages/map_editor/test/features/editor/application/world_map_target_editor_intent_test.dart
 M packages/map_editor/test/features/editor/application/world_map_tool_activation_test.dart
 M packages/map_editor/test/features/editor/presentation/world_map/map_context_menu_host_test.dart
 M packages/map_editor/test/features/editor/presentation/world_map/map_placed_element_rotation_preview_controller_test.dart
 M packages/map_editor/test/features/editor/presentation/world_map/smart_tile_layer_preset_change_flow_test.dart
 M packages/map_editor/test/features/editor/presentation/world_map/world_map_cell_inspector_test.dart
 M packages/map_editor/test/features/editor/presentation/world_map/world_map_layers_inspector_test.dart
 M packages/map_editor/test/features/editor/presentation/world_map/world_map_paint_inspection_intent_test.dart
 M packages/map_editor/test/features/editor/presentation/world_map/world_map_paint_inspector_test.dart
 M packages/map_editor/test/features/editor/presentation/world_map/world_map_place_inspector_test.dart
 M packages/map_editor/test/features/editor/presentation/world_map/world_map_smart_tile_density_wiring_test.dart
 M packages/map_editor/test/features/editor/presentation/world_map/world_map_smart_tile_hidden_layer_test.dart
 M packages/map_editor/test/features/editor/presentation/world_map/world_map_toolbelt_test.dart
 M packages/map_editor/test/features/editor/presentation/world_map/world_map_workspace_test.dart
 M packages/map_editor/test/features/editor/state/editor_notifier_layer_insertion_test.dart
 M packages/map_editor/test/features/editor/state/editor_notifier_map_revision_test.dart
 M packages/map_editor/test/features/editor/state/editor_notifier_no_change_save_test.dart
 M packages/map_editor/test/features/editor/state/editor_notifier_startup_reconciliation_test.dart
 M packages/map_editor/test/fixtures/border/linear_border_visual_fixture.dart
 M packages/map_editor/test/fixtures/border/stone_chain_visual_fixture.dart
 M packages/map_editor/test/fixtures/border/two_tier_stone_chain_visual_fixture.dart
 M packages/map_editor/test/game_export/game_export_test_fixture.dart
 M packages/map_editor/test/game_export/game_package_export_service_test.dart
 M packages/map_editor/test/game_export/runtime_project_projection_builder_test.dart
 M packages/map_editor/test/infrastructure/repositories/atomic_map_document_persistence_test.dart
 M packages/map_editor/test/infrastructure/repositories/map_lifecycle_transaction_file_gateway_test.dart
 M packages/map_editor/test/map_canvas_interaction_arbitration_test.dart
 M packages/map_editor/test/map_canvas_object_selection_test.dart
 M packages/map_editor/test/map_grid_painter_layer_order_test.dart
 M packages/map_editor/test/map_grid_painter_test.dart
 M packages/map_editor/test/map_selection_controller_test.dart
 M packages/map_editor/test/marionette_qa_workspace_test.dart
 M packages/map_editor/test/narrative_document_session_workspace_adoption_test.dart
 M packages/map_editor/test/narrative_event_authoring_session_test.dart
 M packages/map_editor/test/narrative_event_spatial_link_journal_repository_test.dart
 M packages/map_editor/test/personalization/personalization_live_preview_test.dart
 M packages/map_editor/test/personalization/personalization_project_preview_projection_test.dart
 M packages/map_editor/test/personalization/personalization_studio_workspace_test.dart
 M packages/map_editor/test/personalization/phase_6_personalization_studio_export_e2e_test.dart
 M packages/map_editor/test/placed_element_instance_indexer_test.dart
 M packages/map_editor/test/project_element_collision_file_repository_roundtrip_test.dart
 M packages/map_editor/test/project_new_game_configuration_form_test.dart
 M packages/map_editor/test/project_pokemon_config_test.dart
 M packages/map_editor/test/scenes_workspace_shell_test.dart
 M packages/map_editor/test/shell_chrome_test_harness.dart
 M packages/map_editor/test/smart_tiles_studio/smart_tile_canonical_editor_flow_test.dart
 M packages/map_editor/test/smart_tiles_studio/smart_tile_draft_persistence_coordinator_test.dart
 M packages/map_editor/test/smart_tiles_studio/smart_tile_gesture_burst_test.dart
 M packages/map_editor/test/smart_tiles_studio/smart_tile_map_editing_test.dart
 M packages/map_editor/test/smart_tiles_studio/smart_tile_preset_deletion_service_test.dart
 M packages/map_editor/test/smart_tiles_studio/smart_tile_publication_service_test.dart
 M packages/map_editor/test/smart_tiles_studio/smart_tile_reconstruction_editor_test.dart
 M packages/map_editor/test/smart_tiles_studio/smart_tile_reconstruction_service_test.dart
 M packages/map_editor/test/smart_tiles_studio/smart_tile_source_asset_import_service_test.dart
 M packages/map_editor/test/smart_tiles_studio/smart_tile_stn04_golden_workflow_test.dart
 M packages/map_editor/test/smart_tiles_studio/smart_tile_stn07_organic_forest_golden_workflow_test.dart
 M packages/map_editor/test/smart_tiles_studio/smart_tile_studio_library_test.dart
 M packages/map_editor/test/smart_tiles_studio/smart_tile_studio_sprite_surfaces_test.dart
 M packages/map_editor/test/smart_tiles_studio/smart_tile_tiled_wang_import_service_test.dart
 M packages/map_editor/test/smart_tiles_studio/smart_tile_transform_preview_test.dart
 M packages/map_editor/test/smart_tiles_studio/smart_tiles_studio_navigation_test.dart
 M packages/map_editor/test/smart_tiles_studio/smart_tiles_studio_panel_test.dart
 M packages/map_editor/test/status_bar_test.dart
 M packages/map_editor/test/top_toolbar_test.dart
 M packages/map_editor/test/ui/canvas/cinematics/cinematic_library_browser_test.dart
 M packages/map_editor/test/ui/canvas/cinematics/presentation_studio_add_panel_test.dart
 M packages/map_editor/test/ui/canvas/cinematics/presentation_studio_journey_preview_test.dart
 M packages/map_editor/test/ui/canvas/editor_canvas_picture_cache_test.dart
 M packages/map_editor/test/ui/canvas/editor_canvas_smart_tile_animation_test.dart
 M packages/map_editor/test/ui/canvas/narrative_event_map_banner_test.dart
 M packages/map_editor/test/ui/canvas/narrative_studio_cinematics_route_test.dart
 M packages/map_editor/test/ui/world_map/world_map_gate_6_essential_journey_test.dart
 M packages/map_editor/test/ui/world_map/world_map_large_map_performance_test.dart
 M packages/map_editor/test/ui/world_map/world_map_rebuild_isolation_test.dart
 M packages/map_editor/test/ui/world_map/world_map_rotation_shortcuts_test.dart
 M packages/map_gameplay/benchmark/encounter_resolution_scaling.dart
 M packages/map_gameplay/lib/src/collision/world_collision_storage.dart
 M packages/map_gameplay/lib/src/gameplay_world_state.dart
 M packages/map_gameplay/test/collision_building_golden_slice_test.dart
 M packages/map_gameplay/test/encounter_resolution_contract_test.dart
 M packages/map_gameplay/test/new_game_seed_state_projection_test.dart
?? packages/map_gameplay/test/placed_element_transform_gameplay_test.dart
 M packages/map_gameplay/test/placed_elements_collision_test.dart
 M packages/map_gameplay/test/trainer_progression_reward_chain_test.dart
 M packages/map_player_ui/test/player/presentation_preview_session_test.dart
 M packages/map_runtime/lib/map_runtime_authoring.dart
 M packages/map_runtime/lib/src/application/authoring_preview/runtime_authoring_map_renderer.dart
 M packages/map_runtime/lib/src/infrastructure/runtime_tileset_image.dart
 M packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
 M packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game_interactions.dart
 M packages/map_runtime/lib/src/presentation/flame/quarter_turn_pixel_renderer.dart
 M packages/map_runtime/lib/src/presentation/flame/static_placed_element_occlusion_patch_resolution.dart
 M packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart
 M packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart
 M packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
 M packages/map_runtime/test/border/border_runtime_asset_collection_test.dart
 M packages/map_runtime/test/border/border_runtime_readiness_test.dart
 M packages/map_runtime/test/character_studio_golden_slice_runtime_test.dart
 M packages/map_runtime/test/fixtures/p3_event_source_bridge/maps/p3_event_source_field.json
 M packages/map_runtime/test/fixtures/p3_event_source_bridge/project.json
 M packages/map_runtime/test/fixtures/p3_fact_world_rule_projection/maps/p3_fact_world_rule_field.json
 M packages/map_runtime/test/fixtures/p3_fact_world_rule_projection/project.json
 M packages/map_runtime/test/fixtures/p3_outcome_battle_continuation/maps/p3_outcome_battle_field.json
 M packages/map_runtime/test/fixtures/p3_outcome_battle_continuation/project.json
 M packages/map_runtime/test/fixtures/p3_scenario_runtime_golden_path/maps/p3_scenario_field.json
 M packages/map_runtime/test/fixtures/p3_scenario_runtime_golden_path/project.json
 M packages/map_runtime/test/load_runtime_map_bundle_collision_normalization_test.dart
?? packages/map_runtime/test/placed_element_transform_render_test.dart
 M packages/map_runtime/test/playable_map_game_placed_element_occlusion_test.dart
 M packages/map_runtime/test/playable_map_game_smart_tile_animation_activation_test.dart
 M packages/map_runtime/test/playable_map_game_tile_seam_visual_test.dart
 M packages/map_runtime/test/player/runtime_text_pre_session_scene_runner_test.dart
 M packages/map_runtime/test/player/support/runtime_player_test_harness.dart
 M packages/map_runtime/test/project_tileset_visual_resolution_test.dart
 M packages/map_runtime/test/quarter_turn_pixel_renderer_test.dart
 M packages/map_runtime/test/runtime_manifest_tilesets_smart_tile_test.dart
 M packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart
 M packages/map_runtime/test/smart_tile_actor_occlusion_component_test.dart
 M packages/map_runtime/test/smart_tile_animation_activation_controller_test.dart
 M packages/map_runtime/test/smart_tile_layer_preset_change_render_test.dart
 M packages/map_runtime/test/smart_tile_runtime_culling_test.dart
 M packages/map_runtime/test/smart_tile_runtime_render_test.dart
 M packages/map_runtime/test/smart_tile_triggered_animation_render_test.dart
 M packages/map_runtime/test/static_placed_element_occlusion_patch_resolution_test.dart
 M packages/map_runtime/test/surface/surface_runtime_test_support.dart
 M packages/map_runtime/test/tiled_asset_store_bundle_loading_test.dart
 M pokemap_authoring_api_mcp_action_catalog.md
 M tools/performance/smart_tiles_rich_map_fixture.dart
 M tools/pokemap_mcp/test/border_catalog_server.test.ts
 M tools/pokemap_mcp/test/item_authoring.test.ts
 M tools/pokemap_mcp/test/mutation_server.test.ts
 M tools/pokemap_mcp/test/playtest_player_state.test.ts
 M tools/pokemap_mcp/test/playtest_projection.test.ts
 M tools/pokemap_mcp/test/pokemon_authoring.test.ts
 M tools/pokemap_mcp/test/rail_journey_server.test.ts
 M tools/pokemap_product_certification/lib/src/neutral_certification_game_fixture.dart
 M tools/pokemap_product_certification/tool/cinematic_v2/cinematic_v2_replacement_canary_test.dart
```

</details>
