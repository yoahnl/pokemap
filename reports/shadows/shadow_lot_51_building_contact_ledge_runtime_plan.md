# Shadow-51 — Building Contact Ledge Runtime Shadow V0 Plan

## 1. Résumé

Shadow-51 doit corriger le probleme visuel le plus visible dans le runtime : les batiments projettent encore de grandes plaques diagonales qui traversent le sol comme des morceaux de carton semi-transparents.

Le lot propose de traiter les elements de famille `building` autrement que les props hauts, les arbres ou les lampadaires :

- les batiments ne doivent plus utiliser la projection longue V0 ;
- ils doivent produire une ombre courte de contact, attachee au bas du sprite ;
- le resultat doit rester dans le pipeline runtime Shadow existant ;
- aucun modele persistant ne doit etre modifie ;
- aucun codec JSON ne doit etre modifie ;
- aucun editor/canvas ne doit etre modifie dans ce lot ;
- aucun nouveau composant Flame ne doit etre cree.

Objectif utilisateur :

```text
Les maisons ne doivent plus produire de longues ombres polygonales absurdes.
Elles doivent avoir une ombre de base discrete, proche d'un contact au sol facon Pokemon.
```

## 2. Constat actuel

Les lots precedents ont fait avancer le systeme :

- Shadow-27 a ajoute le footprint persistable.
- Shadow-28 a ajoute la geometrie commune.
- Shadow-29 et Shadow-30 ont aligne runtime/editor sur cette geometrie.
- Shadow-35+ ont ajoute des familles, des projections polygonales et des calibrations Selbrume.
- Shadow-50 a baisse l'intensite et raccourci certains parametres.

Mais le probleme restant n'est plus seulement numerique.

Pour les batiments, le modele "projection longue" est le mauvais outil. Meme avec des ratios plus courts, une maison reste un grand sprite frontal ; projeter cette surface cree une plaque visible qui ne ressemble pas a une ombre Pokemon.

Le bon comportement V0 pour un batiment est plus proche de :

```text
une ombre de contact au pied du batiment,
courte,
large mais basse,
legerement skewed,
jamais une longue projection diagonale.
```

## 3. Audit local

### 3.1 Runtime shape contract

Fichier inspecte :

```text
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
```

Etat utile :

```dart
enum ShadowRuntimeShapeKind {
  contactBlob,
  ellipse,
  projectedPolygon,
}
```

`ShadowRuntimeRenderInstruction` sait deja transporter un `projectedPolygon` avec des points.

Conclusion :

```text
Shadow-51 n'a pas besoin d'ajouter un nouveau shape kind.
Une ombre de contact de batiment peut etre representee comme un projectedPolygon court a 4 points.
```

### 3.2 Runtime renderer

Fichier inspecte :

```text
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
```

Etat utile :

```dart
case ShadowRuntimeShapeKind.projectedPolygon:
  _renderProjectedPolygon(canvas, instruction);
```

Le renderer sait deja dessiner des polygons et utilise une logique de bandes d'opacite pour les quadrilateres.

Conclusion :

```text
Shadow-51 ne doit pas modifier le renderer.
Le probleme vient du choix de geometrie emis pour les batiments, pas du dessin Canvas lui-meme.
```

### 3.3 Runtime resolver

Fichier inspecte :

```text
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
```

Etat utile :

```dart
final family = resolveStaticShadowFamily(
  elementFamily: input.elementFamily,
  overrideFamily: input.overrideFamily,
);
final familySpec = resolveStaticShadowFamilyProjectionSpec(family);
final projectedGeometry = resolveProjectedStaticShadowGeometry(
  base: baseGeometry,
  light: defaultProjectedStaticShadowLight,
  projection: familySpec.projection,
);
```

Le resolver resout deja la famille, puis utilise une projection polygonale.

Conclusion :

```text
Le bon point d'intervention est le resolver runtime statique.
Quand family == building, il doit emettre une geometrie speciale courte.
Les autres familles doivent rester dans la projection existante.
```

### 3.4 Runtime collection

Fichier inspecte :

```text
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
```

Etat utile :

```dart
elementFamily: source.elementShadow?.family,
overrideFamily: source.placedOverride?.family,
```

Conclusion :

```text
La collection transmet deja les familles.
Shadow-51 ne devrait pas avoir besoin de changer ce fichier, sauf test de non-regression.
```

### 3.5 Flame / rendu

Fichier inspecte :

```text
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
```

Etat utile :

```dart
void render(Canvas canvas) {
  if (renderPass == MapLayerRenderPass.background) {
    _paintTerrainLayer(canvas);
    _paintPathLayer(canvas);
    _paintSurfaceLayer(canvas);
    _paintShadows(canvas);
  }
  _paintTileLayer(canvas);
  _paintPlacedElements(canvas);
  _paintEntities(canvas);
}
```

La position de rendu des ombres est deja correcte pour ce lot : sous les elements places.

Conclusion :

```text
Shadow-51 ne doit pas changer MapLayersComponent.
```

## 4. Recherche Flame

Le serveur documentaire `flame_docs` a ete consulte avant de proposer ce plan runtime.

Requetes effectuees :

```text
Flame render method Canvas drawPath Component priority render order PositionComponent
Flame Component render Canvas priority
components render canvas priority
```

Resultat :

```text
Le serveur n'a retourne aucun resultat pour ces requetes.
```

Interpretation :

```text
Le lot ne depend pas d'une API Flame nouvelle.
Il reste sur les patterns locaux deja en place :
- MapLayersComponent.render(Canvas)
- ShadowRuntimeRenderer.renderInstruction(Canvas, instruction)
- drawPath/drawOval deja utilises dans le repo
```

Cette absence de resultat Flame ne bloque pas Shadow-51, car le lot ne modifie pas la hierarchie Flame, le cycle de vie des components, les priorities, ni les overlays.

## 5. Design retenu

### 5.1 Principe

Ajouter une branche runtime :

```text
si family == StaticShadowFamily.building
alors produire une ombre de contact courte
sinon conserver la projection polygonale existante
```

Cette branche doit vivre dans :

```text
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
```

### 5.2 Pourquoi le runtime d'abord

Le probleme signale par les captures vient du runtime jouable.

L'editor preview devra suivre plus tard, mais modifier l'editor dans le meme lot augmenterait le risque et melangerait deux surfaces de validation.

Shadow-51 doit donc etre runtime-only.

## 6. Geometrie de ledge batiment

### 6.1 Source de base

La ledge doit partir de la geometrie deja resolue par Shadow-28/29 :

```dart
final baseGeometry = _resolveStaticPlacedElementBaseGeometry(input);
```

Pourquoi :

- elle respecte deja le footprint element ;
- elle respecte deja le footprint override ;
- elle applique deja offset/scale une seule fois dans la base logique ;
- elle conserve les corrections utilisateur existantes ;
- elle evite de recalculer les dimensions a la main depuis le sprite.

### 6.2 Forme proposee

Pour une maison, on veut un trapeze court au pied :

```text
nearLeft -------- nearRight
   \              \
    \              \
     farLeft ------ farRight
```

Coordonnees proposees :

```dart
final centerX = baseGeometry.centerX;
final nearY = baseGeometry.centerY - baseGeometry.height * 0.30;
final farY = baseGeometry.centerY + _buildingContactLedgeDepth(input.metrics);
final nearHalfWidth = baseGeometry.width * 0.55;
final farHalfWidth = baseGeometry.width * 0.48;
final skewX = _buildingContactLedgeSkew(input.metrics);

final points = <StaticShadowPoint>[
  StaticShadowPoint(
    x: centerX - nearHalfWidth,
    y: nearY,
  ),
  StaticShadowPoint(
    x: centerX + nearHalfWidth,
    y: nearY,
  ),
  StaticShadowPoint(
    x: centerX + skewX + farHalfWidth,
    y: farY,
  ),
  StaticShadowPoint(
    x: centerX + skewX - farHalfWidth,
    y: farY,
  ),
];
```

Helper propose :

```dart
double _buildingContactLedgeDepth(
  StaticPlacedElementShadowRuntimeMetrics metrics,
) {
  return (metrics.visualHeight * 0.035).clamp(4.0, 14.0);
}

double _buildingContactLedgeSkew(
  StaticPlacedElementShadowRuntimeMetrics metrics,
) {
  return (metrics.visualWidth * 0.025).clamp(0.0, 8.0);
}
```

Ces valeurs sont volontairement conservatrices :

- profondeur limitee ;
- largeur derivee du footprint ;
- leger skew pour eviter un rectangle plat ;
- pas de grande diagonale ;
- pas de projection selon une lumiere globale.

### 6.3 Opacite

Shadow-51 doit conserver :

```dart
opacity: input.resolvedConfig.opacity
```

Pourquoi :

```text
Le lot corrige la forme.
Il ne doit pas cacher la correction derriere une baisse implicite d'opacite.
```

Les profils et politiques Selbrume deja calibres continuent de controler l'opacite.

## 7. Implementation cible

### 7.1 Fichier a modifier

```text
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
```

Changement principal :

```dart
if (family == StaticShadowFamily.building) {
  return _resolveBuildingContactLedgeRuntimeInstruction(input);
}
```

Cette branche doit intervenir apres :

- validation `groundStatic` ;
- rejet de `none` ;
- rejet de `actorContact` ;
- resolution de la famille.

Elle doit intervenir avant la projection polygonale longue.

### 7.2 Helper prive a ajouter

Proposition :

```dart
ShadowRuntimeRenderInstruction _resolveBuildingContactLedgeRuntimeInstruction(
  StaticPlacedElementShadowRuntimeInput input,
) {
  final baseGeometry = _resolveStaticPlacedElementBaseGeometry(input);
  final points = _buildingContactLedgePoints(
    geometry: baseGeometry,
    metrics: input.metrics,
  );
  final bounds = _boundsFromRuntimePoints(points);
  return ShadowRuntimeRenderInstruction(
    shape: ShadowRuntimeShapeKind.projectedPolygon,
    renderPass: input.resolvedConfig.renderPass,
    worldLeft: bounds.left,
    worldTop: bounds.top,
    width: bounds.width,
    height: bounds.height,
    opacity: input.resolvedConfig.opacity,
    colorHexRgb: input.resolvedConfig.colorHexRgb,
    softnessMode: input.resolvedConfig.softnessMode,
    polygonPoints: points,
  );
}
```

Autres helpers possibles :

```dart
List<StaticShadowPoint> _buildingContactLedgePoints({
  required ResolvedStaticShadowGeometry geometry,
  required StaticPlacedElementShadowRuntimeMetrics metrics,
})
```

Si `StaticShadowPoint` n'est pas le type expose dans le fichier runtime, utiliser le type local deja employe par `_runtimePointsFromProjection(...)`.

### 7.3 Fichiers a ne pas modifier

```text
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_core/lib/src/models/**
packages/map_core/lib/src/operations/*json_codec.dart
packages/map_editor/**
packages/map_gameplay/**
packages/map_battle/**
```

## 8. Tests a ajouter/modifier

### 8.1 Resolver runtime statique

Fichier :

```text
packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
```

Tests a ajouter :

1. `building family emits a short contact ledge polygon`

Verifier :

```text
- instruction != null ;
- shape == projectedPolygon ;
- polygonPoints.length == 4 ;
- height reste faible pour une maison ;
- width reste bornee par le footprint ;
```

Seuils proposes pour une maison Selbrume :

```text
instruction.height < 18
instruction.width < 100
```

2. `building contact ledge uses resolved footprint`

Verifier qu'un `elementFootprint` plus etroit donne une ledge plus etroite.

3. `building contact ledge applies offset and scale once`

Verifier que :

```text
offsetX deplace les points de +offsetX une fois ;
offsetY deplace les points de +offsetY une fois ;
scaleX agrandit la largeur une fois ;
scaleY agrandit la hauteur logique une fois ;
```

4. `override family building wins over element family`

Cas :

```text
elementFamily: compactProp
overrideFamily: building
```

Verifier :

```text
forme courte de building
```

5. `non-building family keeps projected shadow`

Cas :

```text
family: tallProp ou foliage
```

Verifier que le chemin de projection actuel reste utilise.

6. Regressions existantes a conserver :

```text
mode none retourne null
actorContact reste rejete
opacity/color/softness restent transmis
batch conserve l'ordre
```

### 8.2 Collection runtime

Fichier :

```text
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
```

Tests a ajouter ou adapter :

1. `elementShadow family building reaches resolver and emits short contact ledge`

Verifier qu'une famille stockee sur `ProjectElementShadowConfig.family` produit bien une ledge courte.

2. `placed override family building reaches resolver and emits short contact ledge`

Verifier qu'un override d'instance custom peut forcer le comportement building.

3. `custom override without family keeps element family`

Verifier que le comportement de merge de famille reste intact.

### 8.3 Renderer

Fichier :

```text
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart
```

Pas de nouveau test obligatoire si le renderer n'est pas modifie.

Relancer le fichier pour garantir que les polygons a 4 points sont encore dessines.

## 9. Verification cible

Commandes minimales :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter test test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter test test/shadow/runtime_static_placed_element_shadow_collection_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter test test/shadow/shadow_runtime_renderer_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter test test/shadow
cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter analyze lib/src/shadow test/shadow
```

Comme le lot consomme des concepts core existants :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_core && dart test test/shadow/static_shadow_family_projection_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_core && dart test test/shadow/element_auto_shadow_policy_test.dart
```

Scans anti-derive :

```bash
cd /Users/karim/Project/pokemonProject && git diff --name-only | rg -n "packages/map_editor|packages/map_gameplay|packages/map_battle"
cd /Users/karim/Project/pokemonProject && git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec|\.g\.dart|\.freezed\.dart"
cd /Users/karim/Project/pokemonProject && git diff -U0 -- packages/map_runtime packages/map_core | rg -n "saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
cd /Users/karim/Project/pokemonProject && git diff --check
cd /Users/karim/Project/pokemonProject && git status --short --untracked-files=all
```

## 10. Non-objectifs

Shadow-51 ne doit pas :

- modifier `map_editor` ;
- modifier la preview canvas ;
- modifier `map_core` models ;
- modifier les codecs JSON ;
- modifier `map_gameplay` ;
- modifier `map_battle` ;
- creer une lumiere globale ;
- creer un systeme d'heure de jour ;
- creer `WorldLightState` ;
- creer `ShadowLightProfile` ;
- creer un nouveau renderer ;
- creer un nouveau Flame Component ;
- ajouter `saveLayer` ;
- ajouter `ImageFilter` ;
- ajouter du blur ;
- ajouter `zOrder` ou `zIndex` ;
- lancer `build_runner`.

## 11. Risques

### 11.1 Editor preview temporairement divergente

Le lot est runtime-only. Si l'editeur preview montre encore la projection longue pour les batiments, ce sera une divergence temporaire.

Mitigation :

```text
Shadow-52 doit aligner la preview editor si Shadow-51 valide le rendu runtime.
```

### 11.2 Contact ledge encore trop generique

Une ledge courte est beaucoup plus proche de Pokemon qu'une plaque diagonale, mais ce n'est pas encore une vraie ombre sprite peinte a la main.

Mitigation :

```text
Shadow-53 devra decider si certaines familles ont besoin de masques d'ombre authorables ou asset-driven.
```

### 11.3 Batiments tres larges

Un tres grand batiment peut encore produire une ledge large.

Mitigation :

```text
La largeur vient du footprint deja reglable.
Les tests doivent garantir surtout la profondeur faible.
```

## 12. Critere d'acceptation visuel

Apres Shadow-51, une maison ne doit plus afficher :

```text
une longue plaque diagonale traversant le chemin ou l'herbe.
```

Elle doit afficher :

```text
une ombre courte sous la facade,
attachee au bas du sprite,
moins intrusive,
compatible avec le style Pokemon-like.
```

Les lampadaires, arbres et props hauts peuvent conserver les projections existantes pour le moment.

## 13. Roadmap apres Shadow-51

### Shadow-52 — Editor Building Contact Ledge Preview Parity V0

Si le runtime de Shadow-51 est valide visuellement, aligner l'editor preview sur la meme regle building.

Scope probable :

```text
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
```

### Shadow-53 — Asset / Family Shadow Mask Decision V0

Decider si certaines familles doivent passer a des masques d'ombre authorables ou asset-driven.

But :

```text
se rapprocher des ombres Pokemon peintes,
notamment pour maisons, panneaux, puits, arbres complexes.
```

### Shadow-54 — Runtime Shadow Mask Prototype V0

Si Shadow-53 valide les masques, brancher un prototype runtime minimal pour une famille ou un element fixture.

### Shadow-55 — Selbrume Visual Slice Calibration V1

Valider une capture runtime Selbrume avec maisons, lampadaires, arbres, panneau, puits et joueur.

## 14. Definition of done

Shadow-51 sera termine si :

- les batiments runtime utilisent une ledge courte ;
- les batiments runtime ne passent plus par la projection longue ;
- les autres familles gardent leur comportement ;
- les footprints element/override restent respectes ;
- offset/scale ne sont pas appliques deux fois ;
- le renderer n'est pas modifie ;
- Flame component/render order n'est pas modifie ;
- aucun modele/codec/editor n'est modifie ;
- tests runtime shadow cibles verts ;
- analyse runtime shadow verte ;
- rapport d'implementation complet cree ;
- aucun commit sauf demande explicite de l'utilisateur.

