# PokeMap — Collision d’éléments : modèle « sol / base » (ground blocking)

## 1. Résumé exécutif

L’implémentation **« alpha pur »** (toute cellule touchée par un pixel opaque = bloquant) était **correcte techniquement** pour la lecture du canal alpha, mais **fausse pour le produit** Pokémon-like : elle confondait **occupation visuelle** (où le sprite est dessiné) et **obstacle gameplay** (où le joueur doit s’arrêter). Résultat : grilles pleines sur les arbres, maisons, etc., et impossibilité crédible de **passer derrière** le haut d’un sprite.

Ce document décrit le **nouveau modèle** : seule la **matière basse / ancrée** du sprite contribue à la collision automatique, avec des paramètres **nommés, documentés et testés**.

---

## 2. Diagnostic de l’ancien comportement (mode alpha intégral)

| Problème | Effet observé |
|----------|----------------|
| Une seule notion « opaque = bloquant » | Toute la boîte du sprite devenait un mur, y compris le feuillage haut. |
| Pas de distinction haut / bas | Aucune sémantique « passer derrière » côté données de collision. |
| Agrégation par cellule sans verticalité | Une cellule avec un pixel de feuillage en haut pouvait bloquer comme le tronc. |

Le **runtime** (`map_gameplay`, `_buildCollisionCache`) applique fidèlement les cellules du profil : si le profil est un gros rectangle, le jeu bloque en conséquence. La correction doit être **côté génération** du profil, pas dans le moteur de déplacement.

---

## 3. Nouveau design : deux notions

### A. Occupation visuelle (référence)

- **Définition** : où l’image a de l’alpha au-dessus du seuil.
- **Usage** : lecture pixel dans [ElementVisualOccupancyRaster] (tests / extension future : profondeur, debug).
- **Non persisté** séparément dans cette version : seul le résultat **bloquant** alimente `ElementCollisionProfile.cells`.

### B. Zone bloquante gameplay (persistée)

- **Définition** : sous-ensemble des pixels **visibles** situés dans :
  1. la **bande basse du sprite** (fraction de la hauteur utile après padding) ;
  2. l’**empreinte basse** de chaque cellule (fraction basse des pixels de la case).
- **Décision** : une cellule est bloquante si la densité d’opacité dans cet **échantillon sol** dépasse `minimumOpaqueRatioInGroundSample`.

---

## 4. Algorithme (implémenté dans `ElementGroundBlockingAnalyzer`)

Pour chaque cellule `(cx, cy)` :

1. Clip horizontal/vertical du rectangle source par `WarpTriggerPadding` (rogne **utilisateur**).
2. **Bande gameplay** : ne garder que les pixels dont la coordonnée locale `Y` vérifie  
   `Y ≥ clipTop + ⌈(1 − F_sprite) × (clipBottom − clipTop)⌉`  
   avec `F_sprite = spriteGameplayBandBottomFraction` (défaut **0,52** → bas ~52 % du sprite).
3. **Empreinte cellule** : ne garder que les pixels avec `py ≥ ⌈(1 − F_cell) × cellPixelHeight⌉`  
   avec `F_cell = cellGroundFootprintFraction` (défaut **0,5** → moitié basse de la case).
4. Sur les pixels restants (**échantillon sol**), compter `opaque` avec `alpha > alphaThreshold` (défaut **24**).
5. Si `échantillon_sol = 0` → cellule non bloquante.  
   Sinon si `opaque / échantillon_sol ≥ minimumOpaqueRatioInGroundSample` (défaut **0,06**) → bloquant ; si le minimum est **0**, « au moins un pixel » suffit.

**Conséquence Pokémon-like** : le feuillage entièrement dans la moitié **haute** du sprite ne remplit pas l’échantillon sol des cellules du haut de la même manière qu’un tronc plein bas — les cellules supérieures tendent à rester **non bloquantes** ; le joueur peut passer « derrière » visuellement tant que la base ne barre pas le passage.

---

## 5. Paramètres (`PlacedElementCollisionGenerationParams`)

| Champ | Défaut | Rôle |
|-------|--------|------|
| `alphaThreshold` | 24 | Transparent si `alpha ≤ seuil`. |
| `spriteGameplayBandBottomFraction` | 0,52 | Part basse du **sprite** où la matière peut bloquer. |
| `cellGroundFootprintFraction` | 0,5 | Part basse de **chaque cellule** utilisée pour l’échantillon. |
| `minimumOpaqueRatioInGroundSample` | 0,06 | Filtre de densité sur l’échantillon sol (anti-alias / bruit). |

Aucun preset « arbre / maison » : tout est **explicite** dans ces nombres (réglage futur possible en UI).

---

## 6. Fichiers créés / modifiés / supprimés

### Créés

- `lib/src/application/collision_generation/placed_element_collision_params.dart`
- `lib/src/application/collision_generation/element_visual_occupancy_raster.dart`
- `lib/src/application/collision_generation/element_ground_blocking_analyzer.dart`
- `test/collision_generation/element_ground_blocking_analyzer_test.dart`
- `reports/pokemap_placed_element_collision_ground_model.md` (ce fichier)

### Modifiés

- `placed_element_auto_collision_generator.dart` — utilise `ElementGroundBlockingAnalyzer`
- `element_collision_profile_generator.dart` — nouveau type de params
- `editor_notifier.dart` — `generateElementCollisionProfile` + import
- `tileset_palette_panel.dart` — textes UX alignés sur le modèle « base / sol »

### Supprimés

- `alpha_collision_params.dart`
- `alpha_collision_grid_builder.dart`
- `test/collision_generation/alpha_collision_grid_builder_test.dart`

---

## 7. Runtime

- **Aucun changement requis** : `ElementCollisionProfile` et la fusion dans `_buildCollisionCache` restent identiques.
- Les critères d’acceptation « passer derrière », « bloquer au tronc », « PNJ devant maison » dépendent **du profil généré** ; le runtime ne distingue pas feuillage et tronc — c’est bien le **générateur** qui doit produire des cellules cohérentes.

---

## 8. Tests

Fichier : `test/collision_generation/element_ground_blocking_analyzer_test.dart`

- Sprite vide
- Opaque **uniquement haut** du sprite → pas de collision
- Opaque **base basse** → cellules du bas bloquantes
- Opaque seulement **haut de cellule** (avec bande pleine + empreinte) → pas de blocage
- **Lit / base** : au moins une cellule bloquante quand la base est remplie

---

## 9. Limites et travail ultérieur

| Limite | Piste |
|--------|--------|
| Pas d’exposition UI des 4 paramètres | Sliders dans le panneau collision. |
| Bâtiments très « plats » en bas | Ajuster `spriteGameplayBandBottomFraction` par projet ou preset **optionnel** documenté. |
| Profondeur / calque Z | Toujours hors de ce module ; collision = déplacement uniquement. |

---

## 10. Critères d’acceptation (produit)

1. Passer derrière le haut d’un arbre : **oui** si le générateur ne met pas de cellules bloquantes dans la zone haute (comportement attendu avec les défauts).
2. Bloquer au tronc / base : **oui** si la matière opaque est dans la bande basse.
3. Plus de **gros rectangle plein** automatique sur toute la hauteur : réduit par construction.
4. Approche PNJ : améliorée lorsque la collision décor ne remplit plus toute la façade.
5. Manuel / persistance : **inchangés**.

---

*Aucune opération Git (commit / merge / rebase / push / tag) dans le cadre de cette livraison.*
