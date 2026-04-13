# PokeMap — Refonte « mode Alpha » pour les collisions d’éléments

## Résumé exécutif

La refonte précédente conservait encore **trop d’heuristiques** (bande basse du sprite, empreinte par cellule, presets `ElementPresetKind`, raffinements « arbre / bâtiment », padding auto dérivé du preset). En pratique, le résultat **ne suivait pas** la règle produit attendue :

> transparence → pas de collision ; matière visible → collision possible.

Cette livraison **remplace** ce pipeline par un **mode Alpha unique**, documenté, à deux paramètres explicites, et aligne l’UI sur l’intention du wireframe (auto/manuel, méthode, aperçu rouge/vert).

---

## 1. Pourquoi la refonte précédente « ne changeait rien » pour le produit

| Cause | Effet |
|--------|--------|
| `focusBottomFraction` / `cellFootprintFraction` | Ignoraient une grande partie des pixels du sprite **avant** même le seuil alpha. |
| `CollisionShapeRefinement` (bandes, colonnes, connectivité) | Retrait ou modifiait les cellules après le seuil, **éloignant** le résultat de la silhouette visible. |
| `CollisionPresetPolicy.forPreset` | Même action « Générer » produisait des comportements **difficiles à prévoir** selon le type d’élément. |
| Padding auto depuis preset | Rogait les bords **sans** que l’utilisateur le demande explicitement. |

L’UI affichait encore « Type prédéfini » et le générateur **consommait** ce preset : l’utilisateur percevait un **comportement magique**, pas une lecture directe de l’alpha.

---

## 2. Ce qui a été supprimé

- **Fichiers supprimés** (logique non alpha-first) :
  - `collision_preset_policy.dart`
  - `collision_raster_analyzer.dart` (version avec bandes / empreinte)
  - `collision_shape_refinement.dart`
  - `collision_padding_resolver.dart`
- **Tests** associés à ces modules supprimés.

---

## 3. Ce qui remplace

### 3.1 Paramètres nommés (`alpha_collision_params.dart`)

- **`alphaThreshold`** (`kAlphaCollisionOpaqueThreshold = 24`) :  
  pixels avec `alpha <= seuil` → **transparent** (pas de matière).
- **`minimumOpaquePixelRatioPerCell`** (`0.0` par défaut) :  
  si `0`, **au moins un pixel** opaque dans la cellule suffit pour bloquer la case.  
  Si > 0, proportion minimale de pixels opaques dans la cellule (filtre anti-bruit optionnel).

### 3.2 `AlphaCollisionGridBuilder` (`alpha_collision_grid_builder.dart`)

Pour chaque cellule de la grille de l’élément :

1. Parcourir **tous** les pixels de la cellule (après clip du rectangle source par `WarpTriggerPadding` utilisateur).
2. Compter les pixels avec `alpha > alphaThreshold`.
3. Décision : blocage si la condition de ratio est remplie (voir ci-dessus).

Aucune bande haute/basse, aucun preset, aucune composante connexe.

### 3.3 `PlacedElementAutoCollisionGenerator`

- Charge l’image, décode RGBA, appelle `AlphaCollisionGridBuilder`.
- Retourne `ElementCollisionProfile` avec `padding` **identique** à celui fourni (plus de padding auto dérivé d’un preset).

### 3.4 `EditorNotifier.generateElementCollisionProfile`

- **Suppression** du paramètre `presetKind` pour la génération.
- Ajout optionnel de `AlphaCollisionGenerationParams` (par défaut `defaults`).

### 3.5 UI (`tileset_palette_panel.dart`)

- **Section** `_ElementCollisionAuthoringSection` :
  - titre + sous-texte ;
  - `CupertinoSlidingSegmentedControl` **Auto / Manuel** ;
  - bloc vert « Analyse automatique » avec méthode **Pixel Alpha** et mention « Preset avancé — bientôt » ;
  - éditeur de padding (rogne la zone analysée) ;
  - ligne **Régénérer la collision** / **Effacer** ;
  - aperçu **Aperçu visuel** avec légende rouge/vert.
- **Aperçu** : `_ElementCollisionProfilePainter` dessine **chaque** cellule : rouge = bloquante, vert = passable (clic pour basculer).

---

## 4. Persistance et édition manuelle

- **Inchangé** : `ElementCollisionProfile` (JSON), cellules + padding.
- **Inchangé** : clic sur la grille pour forcer `source: manual` et modifier les cellules.

---

## 5. Tests

Fichier : `test/collision_generation/alpha_collision_grid_builder_test.dart`

- cellule vide → pas de collision ;
- au moins un pixel opaque → collision ;
- alpha sous seuil → transparent ;
- moitié de sprite opaque → une seule cellule touchée.

---

## 6. Limites et prochaines étapes

| Étape | Description |
|--------|-------------|
| UI | Exposer `alphaThreshold` et `minimumOpaquePixelRatioPerCell` (sliders) sans toucher au code. |
| Presets avancés | Réintroduire **uniquement** comme couche optionnelle au-dessus du mode Alpha, jamais comme défaut. |
| Profondeur / interaction | Toujours hors de ce module (voir rapport précédent). |

---

## 7. Fichiers touchés (principaux)

| Fichier | Rôle |
|---------|------|
| `lib/src/application/collision_generation/alpha_collision_params.dart` | Nouveau |
| `lib/src/application/collision_generation/alpha_collision_grid_builder.dart` | Nouveau |
| `lib/src/application/collision_generation/placed_element_auto_collision_generator.dart` | Réécrit |
| `lib/src/application/services/element_collision_profile_generator.dart` | API sans preset |
| `lib/src/features/editor/state/editor_notifier.dart` | `generateElementCollisionProfile` |
| `lib/src/ui/panels/tileset_palette_panel.dart` | Section UI + peintre |
| `test/collision_generation/alpha_collision_grid_builder_test.dart` | Nouveau |

---

*Aucune opération Git (commit / merge / rebase / push / tag) n’a été effectuée dans le cadre de cette tâche.*
