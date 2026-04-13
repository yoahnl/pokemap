# PokeMap — Refonte collision éléments (pixel-level)

## 1. Résumé

La collision des éléments placés est maintenant construite autour d’un **masque pixel gameplay** (`pixelMask`) et exploitée côté runtime via une **grille monde en pixels**, au lieu d’une exécution fondée sur `cells`.

Point clé produit : un sprite peut rester visuellement haut/large sans bloquer partout. Le blocage est déterminé par la matière gameplay utile (base/sol) puis testé en pixels en runtime.

---

## 2. Diagnostic produit initial

- L’ancien flux mélangeait visuel et collision gameplay.
- Un feuillage haut pouvait bloquer comme un tronc.
- Le runtime se comportait essentiellement en logique cellule (`isBlocked(x, y)`), ce qui amplifiait les collisions “rectangles”.

---

## 3. Modèle cible appliqué

### A. Données persistées (`map_core`)

- `ElementCollisionProfile.pixelMask` devient la donnée principale de collision élément.
- Encodage compact : `ElementCollisionMaskEncoding.packedBitsV1` + `dataBase64`.
- `cells` reste un fallback legacy pour compatibilité projets anciens / tooling existant.

### B. Génération (`map_editor`)

Pipeline explicite:
1. `ElementVisualOccupancyAnalyzer` lit l’occupation visuelle alpha.
2. `ElementGroundBlockingMaskAnalyzer` filtre la zone gameplay (bande basse sprite + empreinte basse cellule + densité).
3. `PlacedElementAutoCollisionGenerator` encode le masque pixel en `pixelMask`.

Important: le masque gameplay généré n’est plus “cellule pleine”. Il conserve des pixels solides réels issus de l’occupation filtrée.

### C. Runtime (`map_gameplay`)

- Nouveau cache `_pixelCollisionCache` en espace monde pixel (`mapWidth * tileWidth` par `mapHeight * tileHeight`).
- Fusion runtime:
  - layers collision carte -> tuiles pleines en pixels;
  - éléments placés -> `pixelMask` décodé et stampé en pixels;
  - fallback legacy -> `cells` uniquement si `pixelMask` absent ou invalide.
- `isBlocked(x, y)` s’appuie sur la hitbox de déplacement au bas de la case et teste l’intersection pixel-level.
- `movementBlockReasonAt(...)` consomme cette même logique.

---

## 4. Détails algorithmiques

### Génération gameplay mask (`ElementGroundBlockingMaskAnalyzer`)

- Échantillon par cellule dans une zone “sol”:
  - bas du sprite (`spriteGameplayBandBottomFraction`);
  - bas de cellule (`cellGroundFootprintFraction`);
  - alpha > `alphaThreshold`.
- Une cellule est candidate bloquante selon `minimumOpaqueRatioInGroundSample`.
- Le masque final active **uniquement** les pixels visibles dans la zone gameplay des cellules retenues.

### Résolution runtime

- Hitbox déplacement cellule -> rect bas (centrée X, ancrée bas Y).
- Test collision = au moins un pixel du rect qui intersecte `_pixelCollisionCache`.
- Les entités bloquantes restent gérées en cache entité (inchangé).

---

## 5. Fichiers impactés

### map_core

- `lib/src/models/enums.dart`
- `lib/src/models/element_collision_profile.dart`
- `lib/src/models/element_collision_profile.freezed.dart`
- `lib/src/models/element_collision_profile.g.dart`
- `lib/src/operations/element_collision_mask_codec.dart` (nouveau)
- `lib/src/validation/validators.dart`
- `lib/map_core.dart`

### map_editor

- `lib/src/application/collision_generation/placed_element_collision_params.dart` (nouveau)
- `lib/src/application/collision_generation/element_visual_occupancy_analyzer.dart` (nouveau)
- `lib/src/application/collision_generation/element_visual_occupancy_raster.dart` (nouveau)
- `lib/src/application/collision_generation/element_ground_blocking_mask_analyzer.dart` (nouveau)
- `lib/src/application/collision_generation/placed_element_auto_collision_generator.dart`
- `lib/src/ui/panels/tileset_palette_panel.dart`
- `test/collision_generation/element_ground_blocking_analyzer_test.dart`
- `test/collision_generation/element_ground_blocking_mask_analyzer_test.dart` (nouveau)

### map_gameplay

- `lib/src/gameplay_world_state.dart`
- `test/placed_elements_collision_test.dart`

### map_runtime

- `lib/src/presentation/flame/map_layers_component.dart`

---

## 6. Validation exécutée

- `packages/map_core`: tests codec + JSON `pixelMask` passés.
- `packages/map_editor`: tests analyzeurs collision passés.
- `packages/map_gameplay`: tests collision éléments passés, incluant:
  - source-of-truth `pixelMask`;
  - cas “haut décoratif” non bloquant en déplacement;
  - vérification `isPixelBlocked`.

---

## 7. Hors périmètre / sécurité

- `packages/map_core/lib/src/models/scenario_asset.freezed.dart` a été explicitement restauré à l’état initial.
- Aucun changement hors périmètre collision n’est conservé dans le résultat final.
- Règle appliquée: si une régénération modifie du hors périmètre, ces changements sont signalés puis écartés.

---

## 8. Limites connues

- La séparation collision / profondeur visuelle / interaction est maintenant préparée, mais la profondeur “passer derrière” reste encore un système distinct à implémenter côté rendu/Z-order.
- Les paramètres de génération ne sont pas encore exposés en sliders complets dans l’UI.

---

## 9. Conclusion produit

Le système n’est plus une simple persistance `pixelMask` avec exécution en cellules.  
La résolution runtime des collisions d’éléments placés passe désormais par un cache pixel monde et des tests pixel-level sur la hitbox de déplacement.

---

*Aucun commit, amend, merge, rebase, push ou tag n’a été effectué.*
