# Audit — Source de vérité réelle des collisions d’éléments dans ce checkout

## 1. Résumé exécutif

J’ai audité la chaîne complète demandée dans **le code réellement présent** dans ce checkout de `/Users/karim/Project/pokemonProject`.

Conclusion factuelle :

- dans **ce checkout**, la collision active des éléments placés est toujours pilotée par `ElementCollisionProfile.cells`
- je n’ai trouvé **aucun** champ `collisionMask`, `visualMask`, `occlusionMask` ou `pixelMask` dans le modèle actuel de `ElementCollisionProfile`
- le fichier mentionné `packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart` **n’existe pas** dans ce checkout
- `map_gameplay` et `map_runtime` lisent explicitement `profile.cells`

Autrement dit :

> la piste “le runtime lit déjà collisionMask, donc la correction sur cells est hors contrat” n’est pas vérifiée dans cette copie du dépôt

Dans ce checkout, elle est même contredite par le code.

## 2. Méthode d’audit

J’ai inspecté :

1. le modèle `ElementCollisionProfile`
2. les recherches globales sur :
   - `collisionMask`
   - `pixelMask`
   - `visualMask`
   - `occlusionMask`
   - `cells`
3. la consommation runtime dans :
   - `map_gameplay`
   - `map_runtime`
4. la couche editor liée à l’édition de collision

## 3. Résultat de l’audit modèle

Fichier :

- [/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/element_collision_profile.dart](/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/element_collision_profile.dart)

Le modèle actuel contient :

- `source`
- `padding`
- `shapeCells`
- `cells`
- `manualAddedCells`
- `manualRemovedCells`

Il **ne contient pas** :

- `collisionMask`
- `visualMask`
- `occlusionMask`
- `pixelMask`

Extrait réel :

```dart
const factory ElementCollisionProfile({
  @Default(ElementCollisionProfileSource.generated)
  ElementCollisionProfileSource source,
  @Default(WarpTriggerPadding()) WarpTriggerPadding padding,
  @Default([]) List<GridPos> shapeCells,
  @Default([]) List<GridPos> cells,
  @Default([]) List<GridPos> manualAddedCells,
  @Default([]) List<GridPos> manualRemovedCells,
}) = _ElementCollisionProfile;
```

## 4. Résultat de l’audit editor

Le fichier que tu cites :

- `packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart`

est **absent** dans ce checkout.

Tentative d’ouverture :

```text
sed: packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart: No such file or directory
```

Donc je ne peux pas confirmer le contrat “triple mask editor” à partir de ce dépôt local, parce que ce fichier n’est tout simplement pas là.

## 5. Résultat de l’audit global par recherche symbolique

Recherche exécutée :

```bash
rg -n "collisionMask|pixelMask|visualMask|occlusionMask|cells" \
  packages/map_gameplay/lib \
  packages/map_runtime/lib \
  packages/map_editor/lib \
  packages/map_core/lib
```

Résultat factuel :

- occurrences nombreuses de `cells`
- **aucune** occurrence utile de :
  - `collisionMask`
  - `pixelMask`
  - `visualMask`
  - `occlusionMask`

## 6. Chaîne réelle de consommation runtime

### 6.1 Chargement / désérialisation

Le profil est désérialisé via :

- [/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/element_collision_profile.g.dart](/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/element_collision_profile.g.dart)

Les champs JSON réellement lus sont :

- `source`
- `padding`
- `shapeCells`
- `cells`
- `manualAddedCells`
- `manualRemovedCells`

Pas de masque pixel.

### 6.2 Gameplay — blocage du joueur

Fichier :

- [/Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/gameplay_world_state.dart](/Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/gameplay_world_state.dart)

Chaîne exacte :

```dart
final profile = elementById[instance.elementId]?.collisionProfile;
if (profile == null || profile.cells.isEmpty) {
  continue;
}
for (final localCell in profile.cells) {
  final x = instance.pos.x + localCell.x;
  final y = instance.pos.y + localCell.y;
  ...
  cache[y * map.size.width + x] = true;
}
```

Conclusion :

- le blocage du joueur est construit à partir de `profile.cells`
- pas à partir d’un `collisionMask`

### 6.3 Runtime / overlay debug

Fichier :

- [/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart)

Chaîne exacte :

```dart
final profile = elementById[instance.elementId]?.collisionProfile;
if (profile == null || profile.cells.isEmpty) {
  continue;
}
for (final local in profile.cells) {
  ...
  canvas.drawRect(...);
}
```

Conclusion :

- l’overlay runtime lit aussi `profile.cells`

## 7. Diagnostic du bug réel dans CE checkout

Dans ce checkout, le bug de `petite_maison_toit_bleu` est bien celui-ci :

- `padding = 0`
- `baseCellsFromPaddingService.derive(...)` retourne toute la grille
- `manualAddedCells` contient la forme du lasso
- `manualRemovedCells` est vide
- `rebuild()` recompose :

```text
finalCells = basePaddingFull + manualAdded - manualRemoved
```

Comme `basePaddingFull` contient déjà toute la grille :

- `finalCells == toute la grille`
- le runtime lit `finalCells` via `cells`
- la maison entière bloque

Donc, dans **ce checkout**, la correction métier devait bien porter sur la reconstruction de `cells`.

## 8. Pourquoi la piste “collisionMask runtime” ne peut pas être suivie ici

La piste proposée par ton message reposerait sur des éléments absents ici :

- modèle à masques pixel
- éditeur triple mask
- runtime qui lit `collisionMask`

Je n’ai trouvé aucune de ces trois briques dans ce dépôt local.

Donc :

- soit tu fais référence à une autre branche / un autre checkout / un état plus récent ou plus ancien du repo
- soit ce contrat existait ailleurs mais n’est pas présent dans l’espace de travail actuel

Dans les deux cas, je ne peux pas raisonnablement corriger `collisionMask` dans **ce checkout** sans inventer une architecture qui n’y existe pas.

## 9. Conséquence sur la correction en cours

La correction que j’ai appliquée autour de :

- `shapeCells`
- `source == manual`
- la base auteur vs la base padding

reste cohérente avec le code réellement présent ici, parce que :

- le runtime lit `cells`
- il fallait donc empêcher `cells` de retomber sur la base pleine

Je n’affirme pas que c’est le contrat idéal global du produit.
J’affirme que c’est le contrat **réel** de ce checkout.

## 10. Réponse directe à la question “est-ce que le runtime lit collisionMask ou cells ?”

Réponse prouvée par le code local :

- `map_gameplay` lit `cells`
- `map_runtime` lit `cells`
- je n’ai trouvé aucune lecture de `collisionMask`
- je n’ai trouvé aucun champ `collisionMask` dans `ElementCollisionProfile`

## 11. Ce que je recommande maintenant

Deux chemins possibles, selon ta réalité projet :

### Option A — on reste sur CE checkout

Alors la bonne direction est :

- conserver la correction actuelle centrée sur `cells`
- parce que c’est réellement la source de vérité runtime ici

### Option B — tu vises une autre branche / un autre état du dépôt

Alors il faut me donner le checkout exact où existent :

- `collisionMask`
- `visualMask`
- `occlusionMask`
- `element_collision_triple_mask_editor.dart`

et je reprendrai l’audit / correction sur cette base-là.

Sans ce checkout, je serais obligé d’inventer une architecture absente du code local, ce que je ne veux pas faire.

## 12. Commandes réellement exécutées pour cet audit

```bash
sed -n '1,260p' packages/map_core/lib/src/models/element_collision_profile.dart
sed -n '1,320p' packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart
rg -n "collisionMask|pixelMask|visualMask|occlusionMask|cells" packages/map_gameplay/lib packages/map_runtime/lib packages/map_editor/lib packages/map_core/lib
sed -n '680,740p' packages/map_gameplay/lib/src/gameplay_world_state.dart
sed -n '850,910p' packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
sed -n '1988,2255p' /Users/karim/Desktop/my_new_project/project.json
```

## 13. Conclusion

Le dépôt local et ton message ne décrivent pas le même contrat métier.

Dans le dépôt local :

- la collision active est encore fondée sur `cells`
- pas sur `collisionMask`

Donc la correction “shape base -> rebuild -> cells runtime” n’était pas une correction de surface dans **ce checkout**.
Elle corrigeait bien la source de vérité consommée ici.

Si tu veux qu’on bascule sur le contrat “triple masks pixel + collisionMask runtime”, il faudra qu’on travaille sur le checkout qui contient réellement ce contrat.
