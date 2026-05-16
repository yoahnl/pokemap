# Shadow-36 - Runtime Projected Shadow Instruction / Renderer V0 - Plan

## 1. Resume

Shadow-36 doit permettre au runtime de dessiner une ombre polygonale projetee.

Le lot ne doit pas encore brancher les static placed elements sur cette forme. Il doit seulement etendre le contrat runtime non persistant et le renderer runtime existant :

- `ShadowRuntimeRenderInstruction` peut porter un polygone ;
- `ShadowRuntimeRenderer` peut dessiner ce polygone avec `Canvas.drawPath(...)` ;
- `ellipse` et `contactBlob` restent rendus avec `Canvas.drawOval(...)`.

Pourquoi ce lot existe :

- les ombres actuelles de maisons, lampadaires, panneaux et stands restent des galettes ;
- Shadow-35 sait calculer une projection polygonale pure dans `map_core` ;
- avant de brancher les objets statiques sur cette projection, le runtime doit savoir recevoir et dessiner une instruction polygonale.

## 2. Decision

Decision retenue :

- ajouter `ShadowRuntimeShapeKind.projectedPolygon` ;
- ajouter un value object runtime pur `ShadowRuntimePoint` ;
- ajouter `polygonPoints` a `ShadowRuntimeRenderInstruction` ;
- valider strictement les points polygonaux ;
- dessiner `projectedPolygon` via `ui.Path` + `canvas.drawPath(...)` ;
- ne pas creer de nouveau Flame Component ;
- ne pas modifier `MapLayersComponent` ;
- ne pas modifier `map_core`, `map_editor`, `map_gameplay`, `map_battle`.

Shadow-36 ne doit pas rendre les ombres statiques plus belles tout seul. Il donne seulement au runtime la capacite de dessiner la bonne forme.

## 3. Audit AGENTS / workflow

Fichiers de consignes trouves :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Seul `../pokemonProject/AGENTS.md` s'applique au repo courant.

Consignes importantes pour Shadow-36 :

- package runtime = Flutter + Flame ;
- garder `map_editor` decouple du runtime ;
- ne pas toucher aux modeles persistants hors demande explicite ;
- ne pas faire de commit sans demande explicite ;
- verifier par tests et analyse ;
- produire un rapport complet si le lot est implemente.

## 4. Audit Flame / Canvas

Version locale observee :

```text
packages/map_runtime/pubspec.yaml: flame: ^1.35.0
packages/map_runtime/pubspec.lock: flame 1.37.0
examples/playable_runtime_host/pubspec.lock: flame 1.37.0
```

API pertinente :

- Flame `Component.render(Canvas canvas)` recoit un `Canvas` Flutter ;
- `MapLayersComponent` etend `PositionComponent` ;
- `MapLayersComponent._paintShadows(Canvas canvas)` appelle deja `ShadowRuntimeRenderer` ;
- `ShadowRuntimeRenderer` recoit deja un `dart:ui Canvas`.

Conclusion :

- `Canvas.drawPath(Path, Paint)` est directement utilisable dans `ShadowRuntimeRenderer` ;
- aucune API Flame additionnelle n'est necessaire ;
- aucun `saveLayer`, `ImageFilter`, atlas, sprite ou z-order n'est necessaire ;
- `Paint.isAntiAlias = false` doit rester le comportement V0 pixel-art friendly.

## 5. Audit fichiers runtime actuels

### 5.1 `packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart`

Etat actuel :

```dart
enum ShadowRuntimeShapeKind {
  contactBlob,
  ellipse,
}
```

`ShadowRuntimeRenderInstruction` porte aujourd'hui :

```text
shape
renderPass
worldLeft
worldTop
width
height
opacity
colorHexRgb
softnessMode
```

Le rectangle reste utile pour :

- les ovales existants ;
- les bounds d'une instruction polygonale ;
- la compatibilite avec `ShadowRuntimeInstructionCollection` et le culling existant.

### 5.2 `packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart`

Etat actuel :

```dart
final rect = ui.Rect.fromLTWH(
  instruction.worldLeft,
  instruction.worldTop,
  instruction.width,
  instruction.height,
);
canvas.drawOval(rect, shadowRuntimePaintForInstruction(instruction));
```

Conclusion :

- le bon point de changement est un `switch` sur `instruction.shape` ;
- `ellipse` et `contactBlob` doivent conserver exactement le chemin `drawOval` ;
- `projectedPolygon` doit construire un `ui.Path`.

### 5.3 `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`

Etat actuel :

```dart
shadowRenderer.renderCollectionPass(
  canvas,
  collection,
  ShadowRenderPass.groundStatic,
);
shadowRenderer.renderCollectionPass(
  canvas,
  collection,
  ShadowRenderPass.actorContact,
);
```

Conclusion :

- aucun changement d'ordre de rendu n'est requis ;
- aucun nouveau composant Flame n'est requis ;
- Shadow-36 doit rester dans `map_runtime/lib/src/shadow`.

## 6. Fichiers a modifier

```text
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/test/shadow/shadow_runtime_render_instruction_test.dart
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart
```

Fichier optionnel a modifier seulement si le test d'integration est utile et stable :

```text
packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart
```

Rapport du lot a creer lors de l'implementation :

```text
reports/shadows/shadow_lot_36_runtime_projected_shadow_renderer.md
```

Ce plan ne modifie aucun fichier de production.

## 7. Fichiers a ne pas modifier

```text
packages/map_core/**
packages/map_editor/**
packages/map_gameplay/**
packages/map_battle/**
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart
```

Pourquoi :

- Shadow-36 est le renderer primitive lot ;
- Shadow-37 branchera les static placed elements ;
- Shadow-38 branchera l'editor preview ;
- aucun modele persistant n'est necessaire pour une forme runtime non persistante.

## 8. API a ajouter

### 8.1 `ShadowRuntimeShapeKind.projectedPolygon`

Ajouter :

```dart
enum ShadowRuntimeShapeKind {
  contactBlob,
  ellipse,
  projectedPolygon,
}
```

Regle :

- `projectedPolygon` est une forme runtime seulement ;
- ne pas ajouter `ShadowCasterMode.projectedPolygon` dans `map_core` dans ce lot ;
- `shadowRuntimeShapeFromCasterMode(...)` continue a mapper seulement `contactBlob` et `ellipse`, et continue a rejeter `none`.

Pourquoi :

- les profils persistants actuels restent stables ;
- Shadow-37 peut produire directement une instruction `projectedPolygon` pour les static placed shadows sans changer le modele JSON.

### 8.2 `ShadowRuntimePoint`

Ajouter dans `shadow_runtime_render_instruction.dart` :

```dart
final class ShadowRuntimePoint {
  ShadowRuntimePoint({
    required this.worldX,
    required this.worldY,
  });

  final double worldX;
  final double worldY;
}
```

Validation :

- `worldX` fini ;
- `worldY` fini.

Egalite :

- `operator ==` sur `worldX`, `worldY` ;
- `hashCode` sur `worldX`, `worldY`.

Pourquoi ne pas reutiliser `ProjectedStaticShadowPoint` directement :

- `ShadowRuntimePoint` decrit une instruction de rendu runtime en coordonnees monde ;
- `ProjectedStaticShadowPoint` est un resultat d'operation core ;
- garder les deux noms evite de coupler le renderer runtime a une operation de projection particuliere ;
- Shadow-37 fera le mapping explicite depuis `ProjectedStaticShadowGeometry.points` vers `ShadowRuntimePoint`.

### 8.3 `ShadowRuntimeRenderInstruction.polygonPoints`

Ajouter au constructeur :

```dart
List<ShadowRuntimePoint> polygonPoints = const [],
```

Stockage recommande :

```dart
polygonPoints = List<ShadowRuntimePoint>.unmodifiable(polygonPoints)
```

Validation :

- pour `projectedPolygon` :
  - au moins 3 points ;
  - tous les points finis via `ShadowRuntimePoint` ;
  - aire polygonale > 0 ;
- pour `ellipse` et `contactBlob` :
  - `polygonPoints` doit etre vide.

Les champs `worldLeft`, `worldTop`, `width`, `height` restent obligatoires pour toutes les formes.

Pour `projectedPolygon`, ils representent les bounds de l'instruction. Shadow-37 devra les remplir depuis le bounding rect des points projetes.

Pourquoi garder rectangle + points :

- les collections et le culling runtime savent deja raisonner sur un rectangle ;
- les tests existants n'ont pas besoin d'un second contrat ;
- le polygone porte la forme reelle, le rectangle porte l'enveloppe.

## 9. Validation du polygone

Ajouter une fonction privee dans `shadow_runtime_render_instruction.dart` :

```dart
double _polygonArea(List<ShadowRuntimePoint> points) {
  var area = 0.0;
  for (var i = 0; i < points.length; i += 1) {
    final current = points[i];
    final next = points[(i + 1) % points.length];
    area += current.worldX * next.worldY - next.worldX * current.worldY;
  }
  return area.abs() / 2;
}
```

Regle :

- `area <= 0` => `ValidationException`.

Pourquoi :

- eviter une instruction polygonale invisible ou impossible ;
- proteger `drawPath` contre des points degeneres ;
- rester coherent avec `ProjectedStaticShadowGeometry`, qui rejette deja les polygones degeneres dans `map_core`.

## 10. Renderer attendu

Dans `shadow_runtime_renderer.dart`, remplacer le rendu unique `drawOval` par :

```dart
switch (instruction.shape) {
  case ShadowRuntimeShapeKind.contactBlob:
  case ShadowRuntimeShapeKind.ellipse:
    _renderOval(canvas, instruction);
  case ShadowRuntimeShapeKind.projectedPolygon:
    _renderProjectedPolygon(canvas, instruction);
}
```

Implementation conceptuelle :

```dart
void _renderProjectedPolygon(
  ui.Canvas canvas,
  ShadowRuntimeRenderInstruction instruction,
) {
  final points = instruction.polygonPoints;
  final path = ui.Path()
    ..moveTo(points.first.worldX, points.first.worldY);
  for (final point in points.skip(1)) {
    path.lineTo(point.worldX, point.worldY);
  }
  path.close();
  canvas.drawPath(path, shadowRuntimePaintForInstruction(instruction));
}
```

Regles :

- ne pas utiliser `saveLayer` ;
- ne pas utiliser `ImageFilter` ;
- ne pas ajouter de blur ;
- ne pas changer `shadowRuntimePaintForInstruction(...)` sauf si necessaire ;
- conserver `isAntiAlias = false`.

## 11. Tests a ajouter ou modifier

### 11.1 `shadow_runtime_render_instruction_test.dart`

Ajouter :

```text
1. cree une instruction projectedPolygon valide ;
2. ShadowRuntimePoint rejette NaN / Infinity ;
3. projectedPolygon rejette moins de 3 points ;
4. projectedPolygon rejette un polygone degenere ;
5. ellipse rejette polygonPoints non vide ;
6. contactBlob rejette polygonPoints non vide ;
7. equality/hashCode incluent polygonPoints ;
8. polygonPoints est immuable apres construction ;
9. shadowRuntimeShapeFromCasterMode ne mappe pas projectedPolygon depuis un mode persistant.
```

Le dernier point est important : `projectedPolygon` n'est pas un nouveau `ShadowCasterMode` dans Shadow-36.

### 11.2 `shadow_runtime_renderer_test.dart`

Ajouter :

```text
1. projectedPolygon dessine un pixel interieur visible ;
2. projectedPolygon laisse un pixel exterieur transparent ;
3. projectedPolygon respecte opacity 0 ;
4. renderInstructions conserve l'ordre entre ellipse et projectedPolygon ;
5. renderCollectionPass filtre encore groundStatic / actorContact avec polygons ;
6. ellipse et contactBlob restent verts avec les tests existants.
```

Exemple de polygone stable pour test pixels :

```text
(4, 4)
(16, 4)
(20, 12)
(2, 12)
```

Pixels attendus :

```text
interieur : (10, 8)
exterieur : (1, 1)
```

### 11.3 `shadow_runtime_renderer_integration_test.dart`

Modification optionnelle :

```text
Ajouter un test MapLayersComponent avec une instruction projectedPolygon si le test reste simple.
```

Critere :

- si le test d'integration devient bruyant ou fragile, ne pas le modifier ;
- `shadow_runtime_renderer_test.dart` suffit a prouver le renderer ;
- `MapLayersComponent` n'a pas besoin de connaitre la forme.

## 12. TDD propose

Ordre recommande :

1. Ajouter les tests model dans `shadow_runtime_render_instruction_test.dart`.
2. Verifier qu'ils echouent sur `projectedPolygon` / `ShadowRuntimePoint` absents.
3. Implementer `ShadowRuntimePoint`, `projectedPolygon`, `polygonPoints` et validations.
4. Faire passer le test model cible.
5. Ajouter les tests renderer polygon dans `shadow_runtime_renderer_test.dart`.
6. Verifier qu'ils echouent parce que le renderer dessine encore seulement des ovales ou ne sait pas switcher.
7. Implementer le switch renderer et `drawPath`.
8. Relancer les tests cibles, puis la suite shadow runtime.

## 13. Commandes de verification Shadow-36

Commandes minimales :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter test test/shadow/shadow_runtime_render_instruction_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter test test/shadow/shadow_runtime_renderer_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter test test/shadow
cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter analyze lib/src/shadow test/shadow
```

Commande globale runtime si les tests cibles sont verts :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter test
```

Regression core utile parce que Shadow-36 prepare Shadow-37 :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_core && dart test test/shadow/static_shadow_projection_geometry_test.dart
```

## 14. Scans anti-derive

A lancer depuis le repo :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
find .. -name AGENTS.md -print
git diff --name-only | rg -n "packages/map_editor|packages/map_gameplay|packages/map_battle"
git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec"
git diff --name-only | rg -n "\\.g\\.dart|\\.freezed\\.dart"
git diff -U0 -- packages/map_runtime packages/map_core | rg -n "saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
git diff --check
git diff --stat
git diff --name-status
git status --short --untracked-files=all
```

Sorties attendues :

- aucun diff `map_editor` ;
- aucun diff `map_gameplay` ;
- aucun diff `map_battle` ;
- aucun diff model/codec core ;
- aucun fichier generated ;
- aucune nouvelle occurrence interdite de blur, layer, light globale, z-order ou atlas.

`drawPath` est autorise uniquement dans :

```text
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart
```

## 15. Non-objectifs stricts

Shadow-36 ne doit pas :

- brancher `resolveProjectedStaticShadowGeometry(...)` dans les static placed shadows ;
- modifier `static_placed_element_shadow_runtime_resolver.dart` ;
- modifier `runtime_static_placed_element_shadow_collection.dart` ;
- modifier `MapLayersComponent` ;
- modifier l'editor ;
- modifier les modeles persistants ;
- modifier les codecs JSON ;
- ajouter `ShadowCasterMode.projectedPolygon` ;
- ajouter une lumiere globale persistante ;
- ajouter time-of-day ;
- ajouter blur ;
- ajouter `saveLayer` ;
- ajouter `ImageFilter` ;
- ajouter sprite/atlas d'ombre ;
- ajouter `zOrder` ou `zIndex` ;
- lancer `build_runner`.

## 16. Rapport attendu si implementation

Creer :

```text
reports/shadows/shadow_lot_36_runtime_projected_shadow_renderer.md
```

Sections recommandees :

```text
1. Resume du lot
2. Design retenu
3. Fichiers crees
4. Fichiers modifies
5. Fichiers non modifies explicitement
6. API runtime ajoutee
7. Validation projectedPolygon
8. Renderer drawPath
9. Pourquoi ce lot ne branche pas encore les static placed shadows
10. Pourquoi ce lot ne touche pas editor/map_core models/codecs
11. Tests ajoutes/modifies
12. Commandes lancees
13. Resultats complets des tests cibles
14. Ligne finale exacte des tests globaux
15. Resultats des scans anti-derive
16. git status initial
17. git status final
18. git diff --stat
19. Non-objectifs respectes
20. Risques / reserves
21. Auto-review finale
22. Regard critique sur le prompt
23. Contenu complet des fichiers crees/modifies
24. Diffs complets ou equivalents /dev/null pour fichiers crees
```

## 17. Auto-review attendue du lot

Questions a repondre dans le rapport Shadow-36 :

```text
- Ai-je ajoute ShadowRuntimeShapeKind.projectedPolygon ? oui.
- Ai-je ajoute ShadowRuntimePoint ? oui.
- Ai-je ajoute polygonPoints a ShadowRuntimeRenderInstruction ? oui.
- Ai-je valide au moins 3 points et une aire non degeneree ? oui.
- Ai-je conserve drawOval pour ellipse/contactBlob ? oui.
- Ai-je rendu projectedPolygon via drawPath ? oui.
- Ai-je garde Paint.isAntiAlias false ? oui.
- Ai-je evite saveLayer / ImageFilter / blur ? oui.
- Ai-je evite de modifier map_editor ? oui.
- Ai-je evite de modifier map_core models/codecs ? oui.
- Ai-je evite de modifier static placed runtime integration ? oui.
- Ai-je evite toute lumiere globale persistante ? oui.
```

## 18. Risques

Risque 1 : culling.

`ShadowRuntimeInstructionCollection` utilise probablement `worldLeft/worldTop/width/height` pour grouper ou culler. Pour eviter de casser ce contrat, `projectedPolygon` garde ces champs obligatoires. Shadow-37 devra calculer les bounds depuis les points.

Risque 2 : anti-aliasing.

`drawPath` peut produire une forme trop dure sans anti-aliasing. C'est volontaire en V0 pour rester coherent avec le pixel art et le renderer actuel. Un futur lot pourra decider d'une legere attenuation, mais pas avec `ImageFilter` ou `saveLayer` dans Shadow-36.

Risque 3 : confusion modele persistant / forme runtime.

`projectedPolygon` ne doit pas devenir un `ShadowCasterMode` dans ce lot. C'est une instruction runtime, pas une option JSON authoring.

Risque 4 : visible seulement apres Shadow-37.

Apres Shadow-36, aucun objet statique ne produira automatiquement cette forme. C'est normal : Shadow-36 prepare le renderer, Shadow-37 changera la production d'instructions statiques.

## 19. Definition of Done

Shadow-36 est termine si :

- `ShadowRuntimeShapeKind.projectedPolygon` existe ;
- `ShadowRuntimePoint` existe ;
- `ShadowRuntimeRenderInstruction.polygonPoints` existe ;
- les polygones invalides sont rejetes ;
- les points sont immuables apres construction ;
- `ShadowRuntimeRenderer` dessine les polygons via `drawPath` ;
- les ovales existants restent inchanges ;
- les tests pixels prouvent interieur/exterieur/opacity ;
- les tests `test/shadow` runtime sont verts ;
- `flutter analyze lib/src/shadow test/shadow` est vert ;
- aucun editor n'est modifie ;
- aucun modele/codec core n'est modifie ;
- aucun static placed runtime resolver n'est modifie ;
- le rapport evidence pack est cree ;
- aucun commit n'est fait sans demande explicite.

## 20. Suite prevue

Shadow-37 doit ensuite :

- utiliser `resolveStaticShadowGeometry(...)` ;
- utiliser `resolveProjectedStaticShadowGeometry(...)` ;
- mapper `ProjectedStaticShadowPoint` vers `ShadowRuntimePoint` ;
- calculer les bounds du polygone ;
- produire `ShadowRuntimeRenderInstruction(shape: projectedPolygon, ...)` pour les static placed shadows ;
- garder les acteurs en `contactBlob`.

Shadow-38 doit ensuite :

- donner le meme rendu polygonal a la preview canvas editor ;
- garder l'ordre de rendu canvas ;
- ne pas importer `map_runtime` dans `map_editor`.
