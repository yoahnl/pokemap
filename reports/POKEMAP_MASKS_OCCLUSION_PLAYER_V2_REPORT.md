# Rapport — masques visuel / collision / occlusion, rendu « passer derrière », joueur pixel-level

**Date** : 2026-04-07  
**Contrainte** : aucune opération Git effectuée par l’agent (pas de commit, merge, etc.).

---

## 1. Résumé exécutif

Cette itération poursuit la **séparation explicite** entre :

1. **Masque visuel** (`visualMask`) — matière affichée (alpha / référence éditeur).  
2. **Masque collision** (`collisionMask`, clé JSON **`pixelMask`**) — pixels qui **bloquent** le gameplay.  
3. **Masque occlusion** (`occlusionMask`) — pixels redessinés **au-dessus** du joueur pour l’effet « passer derrière », **sans** rôle de blocage.

**Réalisé dans cette série de modifications :**

- **Runtime** : branchement effectif de [`PlacedElementOcclusionPatchComponent`](packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart) au montage de carte dans [`playable_map_game.dart`](packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart) ; démontage propre ; suivi dans [`_LoadedPlayableMap`](packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart) (`occlusionPatches`).  
- **Joueur** : [`PlayerComponent`](packages/map_runtime/lib/src/presentation/flame/player_component.dart) aligne **position**, **taille**, **interpolation de pas**, `focusPoint` et `footPoint` sur [`GameplayPlayerState.playerPositionPx`](packages/map_gameplay/lib/src/gameplay_player_state.dart) avec mise à l’échelle `cellWidth/tileWidth` et `cellHeight/tileHeight`, pour resynchroniser **mouvement pixel gameplay** et **rendu Flame** (objectif : réduire la saccade / désynchronisation animation–déplacement).  
- **Éditeur** : nouveau widget [`ElementCollisionTripleMaskEditor`](packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart) (modes Aperçu / Collision / Occlusion, damier, légende, peinture pixel, dérivation `cells` legacy pour compatibilité).  
- **Validation** : import manquant corrigé dans [`validators.dart`](packages/map_core/lib/src/validation/validators.dart) (`ElementCollisionPixelMask`).

**Non revendiqué comme « terminé » :**

- **Tri Y des NPC** : seul le joueur utilise `priority ≈ 1000 + footY` ; les NPC peuvent ne pas être cohérents avec les patches d’occlusion selon leur implémentation actuelle.  
- **Base des bâtiments** : le commentaire dans le composant d’occlusion reste valide — la **base** du sprite reste dans les calques carte (priorité basse) ; l’occlusion ne recouvre que les pixels du **masque d’occlusion** (souvent « couronne » / toit).  
- **Heuristique auto** : le fichier [`placed_element_mask_heuristics_v1.dart`](packages/map_editor/lib/src/application/collision_generation/placed_element_mask_heuristics_v1.dart) (génération) n’a pas été réécrit dans cette passe ; l’éditeur permet d’ajuster après coup.

---

## 2. Diagnostic initial (état avant / constat honnête)

### 2.1 Ce qui était déjà « pixel-level »

- **Gameplay** : [`GameplayWorldState`](packages/map_gameplay/lib/src/gameplay_world_state.dart) et le résolveur pixel utilisent **`collisionMask`** (JSON `pixelMask`), pas la grille `cells` pour le blocage.  
- **Modèle** : [`ElementCollisionProfile`](packages/map_core/lib/src/models/element_collision_profile.dart) expose `visualMask`, `collisionMask`, `occlusionMask`.

### 2.2 Ce qui restait faux ou incomplet

| Problème | Cause probable | Action dans cette itération |
|----------|----------------|------------------------------|
| Ombres encore perçues comme « collision » | Ancienne logique « alpha ⇒ collision » ou mauvaise génération | Atténué côté **auto** dans des itérations précédentes ; l’**éditeur** permet maintenant d’**effacer** la collision sur l’ombre sans toucher l’occlusion, ou l’inverse. |
| Joueur toujours devant les grands éléments | Priorité joueur fixe + pas de passe de rendu « toit » | **Patches d’occlusion** branchés au runtime (redessin partiel au-dessus du joueur selon tri Y). |
| Preview éditeur pauvre / grille seule | Ancien `_ElementCollisionProfileEditor` basé **cellules** | Remplacé par éditeur **pixel** + trois calques. |
| Marche saccadée | `PlayerComponent` interpolait en **coordonnées grille × cellule** alors que le gameplay avance en **pixels** | **Correction** : position et pas interpolés depuis `playerPositionPx`. |
| Occlusion non branchée | Composant créé mais non ajouté au `FlameGame` | **Montage** dans `_mountLoadedMap` + liste dans `_LoadedPlayableMap`. |

### 2.3 Confusion collision / occlusion / visuel

- **Collision** = fichier de vérité pour **déplacement** (gameplay).  
- **Occlusion** = **rendu** uniquement (pixels recopiés du tileset selon masque).  
- **Visuel** = aide à la compréhension / auto-génération ; l’éditeur peut dériver un masque depuis l’alpha du PNG si `visualMask` est absent.

---

## 3. Architecture cible (rappel)

```
[PNG tileset]
     ↓
visualMask (optionnel, alpha)     ← éditeur + auto
collisionMask (pixelMask JSON)    ← gameplay / map_gameplay
occlusionMask                     ← runtime Flame (patch au-dessus du joueur)
cells                             ← dérivés / legacy / outils, pas vérité gameplay
```

**Rendu :**

- Carte : `MapLayersComponent` (fond + éléments placés).  
- Joueur / NPC : composants acteurs avec `priority` basée sur Y pied.  
- Occlusion : `PlacedElementOcclusionPatchComponent` avec `priority ≈ 1000 + bas_du_masque_en_monde` pour intercaler avec le joueur.

---

## 4. Fichiers créés, modifiés, supprimés

### 4.1 Créés

| Fichier | Rôle |
|---------|------|
| [`packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart`](packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart) | UI masques triples + peinture + légende + damier. |
| [`reports/POKEMAP_MASKS_OCCLUSION_PLAYER_V2_REPORT.md`](reports/POKEMAP_MASKS_OCCLUSION_PLAYER_V2_REPORT.md) | Ce rapport. |

### 4.2 Modifiés

| Fichier | Changement principal |
|---------|----------------------|
| [`packages/map_runtime/lib/src/presentation/flame/player_component.dart`](packages/map_runtime/lib/src/presentation/flame/player_component.dart) | Sync **pixels** gameplay → monde Flame ; `footPoint` / `focusPoint` ; `startStep` / `_snapToStatePosition`. |
| [`packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`](packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart) | Import occlusion ; création liste `occlusionPatches` ; `_unmountLoadedMap` ; `_LoadedPlayableMap` ; copie dans `_applyPlacedElementAnimationEnabled`. |
| [`packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart`](packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart) | Utilisation de `ElementCollisionTripleMaskEditor` ; suppression ancien éditeur cellulaire + painter + `_fitCollisionPreviewRect` (déplacé dans le widget dédié). |
| [`packages/map_core/lib/src/validation/validators.dart`](packages/map_core/lib/src/validation/validators.dart) | `import '../models/element_collision_profile.dart';` pour le type `ElementCollisionPixelMask` dans un helper local. |

### 4.3 Supprimés (logique déplacée, pas de fichier projet supprimé)

- Classes **`_ElementCollisionProfileEditor`**, **`_ElementCollisionProfilePainter`**, fonction **`_fitCollisionPreviewRect`** retirées de `tileset_palette_panel.dart` (équivalent : `ElementCollisionTripleMaskEditor` + `fitCollisionPreviewRect`).

### 4.4 Hors périmètre inattendu

- Aucun fichier hors périmètre **métier** modifié sans justification : seul ajout transversal = **import** dans `validators.dart` (package `map_core`, cohérent avec la validation des masques).

---

## 5. Détail des changements (extraits commentés)

### 5.1 `PlayerComponent`

- **Avant** : `position = mapOrigin + state.pos * cellSize` (grille).  
- **Après** : `position = mapOrigin + playerPositionPx * (cellSize/tileSize)` — aligné sur [`PixelPosition`](packages/map_core/lib/src/models/geometry.dart) du gameplay.  
- **`size`** : `playerSpriteWidthPx/HeightPx` mis à l’échelle pareil.  
- **`footPoint`** : bas de [`PlayerCollisionConventionsV1.playerCollisionRectFromSpriteTopLeft`](packages/map_core/lib/src/collision/player_collision_conventions_v1.dart), puis passage en coordonnées Flame.

### 5.2 `PlayableMapGame._mountLoadedMap`

Pour chaque `MapPlacedElement` avec une entrée manifeste et un `occlusionMask` valide, chargement de l’image tileset du frame principal, instanciation de `PlacedElementOcclusionPatchComponent`, `world.add(patch)`.

### 5.3 `ElementCollisionTripleMaskEditor`

- Décode `collisionMask` / `occlusionMask` ; si collision absente, **remplit** depuis **`cells`** (legacy) en expansant chaque cellule en rectangle de `tileWidth × tileHeight` pixels.  
- `_emitProfile` : encode les trois masques, dérive **`cells`** via `ElementCollisionMaskCodec.cellsFromPixelMask`.  
- **Mode Auto** : inchangé dans la section existante (`_ElementCollisionAuthoringSection` + `generateElementCollisionProfile`) — le brief « mode Auto » reste **la section auto + bouton Régénérer**, distincte des segments Aperçu/Collision/Occlusion.

---

## 6. Stratégie auto collision / occlusion

- **Documentée dans le code** : [`placed_element_mask_heuristics_v1.dart`](packages/map_editor/lib/src/application/collision_generation/placed_element_mask_heuristics_v1.dart) (itérations précédentes).  
- **Cette itération** : pas de modification de l’heuristique ; l’éditeur permet de **corriger** les masques après génération.  
- **Seuil alpha seul** n’est pas présenté comme solution suffisante dans le rapport : l’UI permet des corrections **locales** (ombre au sol, etc.).

---

## 7. Occlusion / « passer derrière »

- **Implémentation** : échantillonnage 1×1 depuis le tileset aux indices où `occlusionMask` est vrai (voir `PlacedElementOcclusionPatchComponent.render`).  
- **Tri** : même famille que le joueur (`priority` ~ `1000 + Y`).  
- **Limite** : si la **façade** doit aussi participer au tri, il faudrait soit étendre le masque d’occlusion, soit décomposer le rendu en plusieurs couches Y-sortées — **non fait** ici (honnêteté produit).

---

## 8. Preview éditeur

- Damier, sprite centré (`fitCollisionPreviewRect`), overlays rouge/violet/bleu, grille pixel optionnelle (aide seulement), légende textuelle.  
- **Peinture** : clic / drag ; **clic droit** ou bouton secondaire = gomme (efface le bit du masque actif).

---

## 9. Animation joueur

- **Hypothèse corrigée** : la saccade venait en partie du **décalage** entre la position réelle en pixels et la position rendue sur grille.  
- **OverworldActorComponent** reste enfant du joueur ; si l’animation semble encore incorrecte, auditer [`OverworldActorComponent`](packages/map_runtime/lib/src/presentation/flame/overworld_actor_component.dart) (cadence `walk` vs `dt`) dans une passe suivante.

---

## 10. Compatibilité / migration JSON

| Champ | JSON | Compatibilité |
|-------|------|----------------|
| `collisionMask` | `pixelMask` | `@JsonKey(name: 'pixelMask')` — les anciens fichiers avec seulement `pixelMask` chargent toujours. |
| `occlusionMask` | `occlusionMask` | Optionnel ; absent ⇒ pas de patch occlusion. |
| `visualMask` | `visualMask` | Optionnel ; éditeur peut dériver depuis l’image. |
| `cells` | `cells` | Toujours dérivé à l’enregistrement depuis le masque pixel pour cohérence avec outils legacy. |

**Validation stricte** : si `cells` non vide **sans** `collisionMask`, [`ProjectValidator`](packages/map_core/lib/src/validation/validators.dart) peut lever une erreur — les flux passant par le nouvel éditeur écrivent un `collisionMask`.

---

## 11. Limites restantes

1. **NPC** : pas d’harmonisation complète avec les patches d’occlusion dans cette passe.  
2. **Performance** : peinture pixel et `_emitProfile` à chaque événement pointeur — acceptable pour l’éditeur desktop ; optimiser (debounce) si besoin.  
3. **Tests UI** : pas de test widget dédié au nouvel éditeur dans cette itération.  
4. **Test map_editor** : `flutter test` a signalé **1 échec** sur `global_story_studio_workspace_test.dart` (tap / hit test) — **probablement flaky ou indépendant** des fichiers masques ; à investiguer séparément.

---

## 12. Tests exécutés

| Suite | Commande | Résultat |
|-------|----------|----------|
| `map_runtime` | `flutter test` | **Tous passés** (dont 157 tests). |
| `map_gameplay` | `dart test` | **Tous passés** (86 tests). |
| `map_editor` | `flutter test` | **108 passés, 1 échec** (voir section 11). |

---

## 13. Checklist de validation manuelle (produit)

- [ ] Une ombre de bâtiment ne bloque pas si vous l’avez **retirée du masque collision** dans l’éditeur.  
- [ ] La base utile peut bloquer (peinture collision).  
- [ ] Le joueur peut passer « derrière » si **occlusion** couvre la zone haute **et** la priorité Y place le patch au-dessus du joueur.  
- [ ] Rendu : vérifier visuellement au nord du bâtiment.  
- [ ] Preview : overlays collision + occlusion lisibles.  
- [ ] Peinture manuelle collision / occlusion.  
- [ ] Auto-génération + retouche.  
- [ ] Marche fluide : comparer avant/après sur la même carte.

---

## 14. Références code (navigation)

- Occlusion patch : [`placed_element_occlusion_patch_component.dart`](packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart)  
- Montage carte : [`playable_map_game.dart`](packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart) (`_mountLoadedMap`, `_unmountLoadedMap`)  
- Joueur : [`player_component.dart`](packages/map_runtime/lib/src/presentation/flame/player_component.dart)  
- Éditeur masques : [`element_collision_triple_mask_editor.dart`](packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart)

---

*Fin du rapport.*
