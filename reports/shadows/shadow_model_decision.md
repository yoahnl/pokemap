# Shadow Model Decision V0

## 1. Résumé exécutif

Shadow-1 fige un modèle V0 volontairement petit. Le prochain lot de code, Shadow-2, doit créer uniquement des value objects purs dans `map_core` :

- `ShadowCasterMode`
- `ShadowRenderPass`
- `ShadowSoftnessMode`
- `ProjectShadowProfile`
- `ProjectShadowCatalog`

La décision retenue est donc l'Option B : `ProjectShadowProfile` + `ProjectShadowCatalog` purs dès Shadow-2, sans branchement à `ProjectManifest`, sans JSON, sans éditeur et sans runtime. Cette option correspond au pattern déjà observé sur Surface : créer les contrats purs et leurs invariants avant de brancher la persistance ou les usages.

Le V0 ne doit pas essayer de résoudre tout le sujet des ombres. Il doit seulement permettre de décrire des ombres simples, stables et testables :

- `ShadowCasterMode` contient exactement `none`, `contactBlob`, `ellipse`.
- `ShadowRenderPass` contient exactement `groundStatic`, `actorContact`.
- `ShadowSoftnessMode` contient exactement `hardEdge`.
- `runtimeBlur` n'existe pas en V0.
- La couleur persistable future est un RGB hexadécimal canonique sans alpha, séparé de `opacity`.
- `zOrder`, `zIndex`, `skew`, `rotation`, sprite masks, atlas frames, time-of-day et ShadowLayer manuel sont repoussés.

La suite recommandée est progressive : value objects purs, codecs manuels externes, config par élément, intégration manifest du catalogue, override par instance, resolver de merge, puis lecture éditeur. Le système Shadow reste un contrat visuel : il ne modifie jamais collision, occlusion, gameplay zones, cells ou pathfinding.

## 2. Fichiers inspectés

Rapports :

- `reports/shadows/shadow_system_architecture_audit.md`

Modèles et patterns `map_core` :

- `packages/map_core/lib/map_core.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_core/lib/src/models/element_collision_profile.dart`
- `packages/map_core/lib/src/models/surface.dart`
- `packages/map_core/lib/src/models/surface_catalog.dart`
- `packages/map_core/lib/src/models/tileset.dart`
- `packages/map_core/lib/src/models/tileset_transparent_color.dart`
- `packages/map_core/lib/src/models/project_path_pattern_preset.dart`

Codecs manuels existants :

- `packages/map_core/lib/src/operations/project_surface_catalog_json_codec.dart`
- `packages/map_core/lib/src/operations/project_surface_preset_json_codec.dart`
- `packages/map_core/lib/src/operations/project_surface_animation_json_codec.dart`
- `packages/map_core/lib/src/operations/surface_animation_timeline_json_codec.dart`
- `packages/map_core/lib/src/operations/surface_animation_frame_json_codec.dart`
- `packages/map_core/lib/src/operations/surface_atlas_json_codec.dart`
- `packages/map_core/lib/src/operations/surface_variant_animation_ref_json_codec.dart`
- `packages/map_core/lib/src/operations/surface_variant_animation_ref_set_json_codec.dart`
- `packages/map_core/lib/src/operations/project_path_pattern_preset_json_codec.dart`
- `packages/map_core/lib/src/operations/environment_preset_json_codec.dart`

Surface et runtime comme références :

- `packages/map_core/lib/src/operations/project_manifest_surface_catalog_operations.dart`
- `packages/map_core/lib/src/operations/surface_studio_read_model.dart`
- `packages/map_core/lib/src/operations/surface_layer_placements.dart`
- `packages/map_runtime/lib/src/surface/surface_runtime_render_instruction.dart`
- `packages/map_runtime/lib/src/surface/surface_runtime_resolver.dart`

Collision, occlusion et visual masks :

- `packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart`
- `packages/map_editor/lib/src/application/collision_generation/placed_element_auto_collision_generator.dart`
- `packages/map_editor/lib/src/application/collision_generation/placed_element_mask_heuristics_v1.dart`
- `packages/map_editor/lib/src/application/collision_generation/element_visual_occupancy_analyzer.dart`

Edition d'élément et Tileset Library :

- `packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart`
- `packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart`
- `packages/map_editor/lib/src/application/use_cases/project_element_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/project_tileset_library_use_cases.dart`

Runtime Flame à connaître, non modifié :

- `packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/player_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/overworld_actor_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart`
- `packages/map_runtime/lib/src/infrastructure/runtime_tileset_image.dart`

Constats principaux :

- `ProjectManifest` et `MapData` sont aujourd'hui des modèles Freezed avec JSON généré.
- Les travaux récents Surface / Environment / PathPattern introduisent aussi des modèles purs et des codecs JSON manuels externes dans `operations`.
- `ProjectSurfaceCatalog` est déjà intégré au manifest via un converter qui transforme `null` ou absence en catalogue vide.
- `ElementCollisionProfile` sépare déjà `visualMask`, `collisionMask` et `occlusionMask`.
- `MapPlacedElement` contient aujourd'hui `applyCollision`, `opacity`, `animation`, `behaviors` et `properties`, mais aucune donnée Shadow.
- L'édition d'un élément vit dans `tileset_palette_panel.dart`, autour de la modale `Edit Element`; l'éditeur de masques de collision vit ailleurs et ne doit pas recevoir la configuration Shadow.
- Le runtime a déjà une séparation background / foreground dans `MapLayersComponent`, et `RuntimeTilesetImage` expose déjà un rendu par `drawImageRect`.

## 3. Décisions finales

### Décision 1 : Shadow-2 crée profil et catalogue purs

Shadow-2 doit créer `ProjectShadowProfile` et `ProjectShadowCatalog` ensemble, mais ne doit pas brancher le catalogue au manifest.

Option retenue : Option B.

Raison :

- Le catalogue est un invariant métier en soi : ids uniques, liste immuable, lookup par id, ordre stable.
- Tester le catalogue avant le manifest réduit le risque de migration JSON prématurée.
- Le pattern Surface a déjà montré l'intérêt de caractériser les value objects et codecs avant de généraliser l'usage éditeur/runtime.

Option A rejetée pour Shadow-2 :

- `ShadowProfile` seul ne permet pas de figer les règles de duplication d'id.
- Les lots suivants auraient à inventer le catalogue au moment de la persistance, exactement quand le risque de casser le manifest est plus grand.
- Cela retarde les tests de lookup, alors que `shadowProfileId` sera la référence centrale du modèle.

### Décision 2 : ProjectManifest reste intact jusqu'à Shadow-5

Shadow-2 ne modifie pas `ProjectManifest`.

Shadow-3 ajoute seulement des codecs manuels externes.

Shadow-4 ajoute la configuration future par élément.

Shadow-5 branche `ProjectShadowCatalog` au manifest, avec une stratégie backward-compatible proche de `ProjectSurfaceCatalog`.

### Décision 3 : aucun JSON généré pour Shadow V0 initial

Les modèles Shadow V0 ne doivent pas avoir `toJson` / `fromJson` directement. Les codecs arrivent en Shadow-3, dans `operations`, sous forme de fonctions manuelles externes.

### Décision 4 : Shadow reste visuel

Shadow ne doit jamais écrire dans :

- `ElementCollisionProfile.collisionMask`
- `ElementCollisionProfile.occlusionMask`
- `visualMask`
- `MapPlacedElement.applyCollision`
- `MapLayer.cells`
- `GameplayZone`
- pathfinding ou collision gameplay

Les ombres peuvent utiliser des dimensions visuelles pour se placer, mais elles ne créent ni collision ni occlusion.

## 4. Décision codecs JSON

Décision : codecs JSON manuels externes.

Shadow-3 doit créer des codecs similaires à :

- `project_surface_catalog_json_codec.dart`
- `project_surface_preset_json_codec.dart`
- `project_path_pattern_preset_json_codec.dart`
- `environment_preset_json_codec.dart`

Forme probable :

```dart
Map<String, Object?> encodeProjectShadowProfile(ProjectShadowProfile profile)
ProjectShadowProfile decodeProjectShadowProfile(Object? json)

Map<String, Object?> encodeProjectShadowCatalog(ProjectShadowCatalog catalog)
ProjectShadowCatalog decodeProjectShadowCatalog(Object? json)
```

Les modèles ne doivent pas exposer :

```dart
toJson()
fromJson()
```

Justification :

- Les codecs Surface récents sont déjà externes et manuels.
- `environment_preset_json_codec.dart` suit explicitement l'idée de ne pas mettre `toJson/fromJson` sur les modèles.
- Les codecs externes permettent d'accepter temporairement des formes JSON anciennes ou tolérantes sans polluer le modèle pur.
- Eviter `build_runner` est important sur les premiers lots Shadow, car le prompt interdit la génération et parce que les changements Freezed dans les modèles existants doivent être isolés à des lots dédiés.

Freezed / generated / build_runner est donc rejeté pour Shadow-2 et Shadow-3.

Un mix temporaire est rejeté aussi : il ajouterait deux sources de vérité pour une surface modèle encore petite.

## 5. Décision couleur

Décision V0 : couleur RGB hexadécimale + opacité séparée.

Champ recommandé :

```dart
final String colorHexRgb;
final double opacity;
```

Convention exacte :

- `colorHexRgb` est une chaîne canonique de 6 caractères hexadécimaux RGB, sans alpha.
- Le modèle pur exige la forme normalisée `RRGGBB`, sans `#`.
- La valeur par défaut est `000000`.
- `opacity` est séparée, bornée de `0.0` à `1.0`.
- La valeur par défaut recommandée est `0.35`.
- L'UI pourra afficher `#RRGGBB`, mais le stockage canonique reste sans `#`.
- Le codec Shadow-3 pourra accepter `#RRGGBB` en entrée pour tolérance, puis réencoder sans `#`, comme `TilesetTransparentColor.fromHexRgb` accepte déjà un préfixe optionnel.

Options rejetées :

| Option | Décision | Raison |
|---|---|---|
| `int colorArgb` | Rejet V0 | Peu lisible en JSON, mélange couleur et alpha, encourage à importer mentalement `Color(0x...)` dans `map_core`. |
| `String colorHex "#AARRGGBB"` | Rejet V0 | Double la notion d'opacité si `opacity` existe aussi; risque de désaccord alpha/opacité. |
| `String colorHex "#RRGGBB" + opacity` | Accepté en UI, pas comme canon interne | Lisible, mais le `#` n'est pas cohérent avec le modèle `TilesetTransparentColor` qui encode sans préfixe. |

Nom de champ retenu : `colorHexRgb`, pas `colorArgb`, afin de rendre explicite l'absence d'alpha.

Validation Shadow-2 :

- chaîne non nulle ;
- longueur exacte 6 ;
- caractères `[0-9a-fA-F]` uniquement ;
- normalisation recommandée en uppercase ou lowercase stable, avec une préférence pour uppercase si le code existant `TilesetTransparentColor` le confirme au moment de l'implémentation ;
- pas de préfixe `#` dans le value object pur.

## 6. Décision render pass / ordre de rendu

Décision V0 : pas de `zOrder` libre, pas de `zIndex`, pas de `double` de tri exposé.

Enum exact Shadow-2 :

```dart
enum ShadowRenderPass {
  groundStatic,
  actorContact,
}
```

Rôle :

- `groundStatic` : ombres simples d'éléments statiques, rendues au niveau sol, avant les sprites principaux et avant l'occlusion foreground.
- `actorContact` : ombres de contact sous les acteurs, liées au tri des acteurs mais jamais devant l'acteur.

Pourquoi un enum contraint :

- Evite qu'une ombre soit placée au-dessus du joueur par une valeur arbitraire.
- Evite les ordres divergents entre éditeur et runtime.
- Force les futurs cas complexes à devenir des décisions explicites plutôt que des nombres magiques.
- Reste compatible avec l'ordre actuel Flame, qui distingue déjà background layers, actors depth-sorted et foreground / occlusion.

Valeurs rejetées ou repoussées :

| Valeur possible | Décision | Raison |
|---|---|---|
| `manualOverlay` | V2 | Trop proche d'un ShadowLayer manuel; demande des règles d'authoring. |
| `foregroundShadow` | V2 ou rejet | Risque direct d'ombres devant façades/joueur; doit être justifié par un cas produit précis. |
| `underOcclusion` | V1/V2 | Probablement utile pour maisons/arbres, mais doit être validé avec les occlusion patches. |
| `aboveActors` | Rejet V0 | Contredit le principe d'ombre au sol, sauf effet spécial non V0. |
| `int zOrder` | Rejet V0 | Trop puissant, impossible à valider proprement. |
| `double zIndex` | Rejet V0 | Même problème, avec plus de combinaisons invalides. |

Ordre cible à préserver plus tard :

```text
terrain / tile background
surfaces
shadows groundStatic
base sprites / placed elements background
shadows actorContact
actors
foreground tiles / occlusion patches
UI / overlays
```

Cet ordre sera corrigé au besoin dans Shadow-10 après caractérisation. Il ne faut pas refactorer `MapLayersComponent` avant d'avoir des tests d'ordre de rendu.

## 7. Décision softness / blur

Décision V0 : aucun blur runtime, aucun champ `blurRadius`.

Enum exact Shadow-2 :

```dart
enum ShadowSoftnessMode {
  hardEdge,
}
```

`hardEdge` et `noBlur` sont redondants. Le V0 garde `hardEdge`, car il décrit le rendu de bord et laisse une place claire à des modes futurs.

Valeurs repoussées :

| Valeur | Décision | Raison |
|---|---|---|
| `noBlur` | Rejet V0 | Synonyme opérationnel de `hardEdge`. |
| `feathered` | V1/V2 | Besoin d'une stratégie de texture ou de cache avant exposition. |
| `prebakedBlur` | V1 | Utile pour sprites d'ombre, mais seulement après support de sprite/atlas shadow. |
| `runtimeBlur` | V2 ou non-objectif long terme | Trop coûteux si appliqué par objet/frame; doit être prouvé par mesure avant d'exister. |

Règle stricte : `runtimeBlur` ne doit pas exister dans l'enum V0. Cela évite une fausse promesse dans l'éditeur et empêche un renderer de choisir `saveLayer + ImageFilter.blur` objet par objet.

## 8. Modèles V0 retenus

### ShadowCasterMode

Lot : Shadow-2.

Package : `map_core`.

Fichier probable : `packages/map_core/lib/src/models/shadow.dart`.

Enum exact :

```dart
enum ShadowCasterMode {
  none,
  contactBlob,
  ellipse,
}
```

Sens :

- `none` : profil valide mais ne produit pas d'ombre.
- `contactBlob` : petite ombre simple sous un acteur ou petit objet.
- `ellipse` : ombre elliptique au sol pour objets statiques simples.

Repoussé : `projectedQuad`, `projectedSpriteMask`, `customShadowSprite`, `customShadowAtlasFrame`, `handPaintedMask`.

### ShadowRenderPass

Lot : Shadow-2.

Package : `map_core`.

Fichier probable : `packages/map_core/lib/src/models/shadow.dart`.

Enum exact :

```dart
enum ShadowRenderPass {
  groundStatic,
  actorContact,
}
```

### ShadowSoftnessMode

Lot : Shadow-2.

Package : `map_core`.

Fichier probable : `packages/map_core/lib/src/models/shadow.dart`.

Enum exact :

```dart
enum ShadowSoftnessMode {
  hardEdge,
}
```

### ProjectShadowProfile

Lot : Shadow-2.

Package : `map_core`.

Fichier probable : `packages/map_core/lib/src/models/shadow.dart`.

Persisté : pas en Shadow-2; persistable via codec manuel en Shadow-3.

JSON : non en Shadow-2.

Dépendances autorisées : Dart pur uniquement.

Forme recommandée :

```dart
final class ProjectShadowProfile {
  ProjectShadowProfile({
    required this.id,
    required this.name,
    required this.mode,
    required this.renderPass,
    this.offsetX = 0,
    this.offsetY = 0,
    this.scaleX = 1,
    this.scaleY = 1,
    this.opacity = 0.35,
    this.colorHexRgb = '000000',
    this.softnessMode = ShadowSoftnessMode.hardEdge,
  }) {
    // validation V0
  }

  final String id;
  final String name;
  final ShadowCasterMode mode;
  final ShadowRenderPass renderPass;
  final double offsetX;
  final double offsetY;
  final double scaleX;
  final double scaleY;
  final double opacity;
  final String colorHexRgb;
  final ShadowSoftnessMode softnessMode;
}
```

Champs gardés depuis le squelette :

- `id`
- `name`
- `mode`
- `renderPass`
- `offsetX`
- `offsetY`
- `scaleX`
- `scaleY`
- `opacity`
- `softnessMode`

Champ renommé :

- `colorArgb` devient `colorHexRgb`.

Champs supprimés :

- aucun autre champ du squelette.

Champs à ne pas ajouter en V0 :

- `skewX`
- `skewY`
- `rotationDegrees`
- `blurRadius`
- `falloff`
- `timeMode`
- `minOpacity`
- `maxOpacity`
- `shadowTilesetId`
- `shadowSource`

Validations Shadow-2 :

- `id.trim().isNotEmpty`
- `name.trim().isNotEmpty`
- `scaleX > 0`
- `scaleY > 0`
- `opacity >= 0 && opacity <= 1`
- `colorHexRgb` est exactement 6 hex chars sans `#`
- tous les doubles doivent être finis, donc pas `NaN` ni `Infinity`

Egalité :

- Le modèle doit avoir une égalité de valeur.
- Sans Freezed, implémenter `operator ==` et `hashCode`, ou suivre un petit helper local si un pattern pur existe déjà.

### ProjectShadowCatalog

Lot : Shadow-2.

Package : `map_core`.

Fichier probable : `packages/map_core/lib/src/models/shadow_catalog.dart`, ou dans `shadow.dart` si l'équipe préfère un seul fichier V0. La séparation `shadow.dart` / `shadow_catalog.dart` est plus cohérente avec `surface.dart` / `surface_catalog.dart`.

Persisté : pas en Shadow-2; persistable via codec manuel en Shadow-3; branché au manifest seulement en Shadow-5.

Forme recommandée :

```dart
final class ProjectShadowCatalog {
  ProjectShadowCatalog({
    List<ProjectShadowProfile> profiles = const [],
  }) : profiles = List.unmodifiable(profiles) {
    // duplicate id validation V0
  }

  final List<ProjectShadowProfile> profiles;

  ProjectShadowProfile? profileById(String id) {
    // exact id lookup
  }
}
```

Validations Shadow-2 :

- liste copiée en immutable ;
- aucun id dupliqué ;
- lookup exact par id ;
- le catalogue vide est valide.

Exports :

- Shadow-2 doit exporter les nouveaux modèles depuis `packages/map_core/lib/map_core.dart`, mais ne doit pas exposer de codec dans le barrel principal sans vérifier le style existant des operations.

## 9. Modèles repoussés

| Modèle | Lot recommandé | Package | Rôle | Persisté | JSON | Champs V0 si introduit | Champs repoussés |
|---|---:|---|---|---|---|---|---|
| `ProjectElementShadowConfig` | Shadow-4 | `map_core` | Config par défaut d'un `ProjectElementEntry` | Oui après branchement | Via JSON généré ou converter selon choix du lot | `castsShadow`, `shadowProfileId`, `offsetX?`, `offsetY?`, `scaleX?`, `scaleY?`, `opacity?` | mode/color/renderPass/softness/skew/rotation/blur/time |
| `MapPlacedElementShadowOverride` | Shadow-6 | `map_core` | Override par instance placée | Oui | Via JSON `MapData` au lot dédié | `overrideMode`, `shadowProfileId?`, `offsetX?`, `offsetY?`, `scaleX?`, `scaleY?`, `opacity?` | mode/color/renderPass/softness/source/time |
| `ShadowResolvedConfig` | Shadow-7 | `map_core` operations | Résultat pur du merge profil + élément + instance | Non | Non | mode, renderPass, transform, opacity, color, softness | cache/runtime image/light interpolation |
| `ShadowRuntimeRenderInstruction` | Shadow-10 ou plus tard runtime | `map_runtime` | Instruction de dessin Flame | Non | Non | world rect, shape, color, opacity, pass | source sprite, atlas batch, blur |
| `WorldLightState` | V1/V2 | `map_runtime` d'abord | Etat courant de lumière globale | Non | Non | phase/direction/multipliers si nécessaire | authoring persistant |
| `ShadowLightProfile` | V2 | `map_core` ou editor config | Profil authorable de lumière | Plus tard | Plus tard | aucun en V0 | tout le modèle |

`WorldLightState` ne doit pas être créé en Shadow-2. `ShadowLightProfile` ne doit pas être persisté en V0.

## 10. Config élément future

La configuration par défaut d'un élément doit arriver en Shadow-4, pas en Shadow-2.

Nom recommandé :

```dart
final class ProjectElementShadowConfig
```

Champ futur dans `ProjectElementEntry` :

```dart
final ProjectElementShadowConfig? shadow;
```

Forme V0 recommandée :

```dart
final class ProjectElementShadowConfig {
  const ProjectElementShadowConfig({
    this.castsShadow = false,
    this.shadowProfileId,
    this.offsetX,
    this.offsetY,
    this.scaleX,
    this.scaleY,
    this.opacity,
  });

  final bool castsShadow;
  final String? shadowProfileId;
  final double? offsetX;
  final double? offsetY;
  final double? scaleX;
  final double? scaleY;
  final double? opacity;
}
```

Décisions :

- La config élément référence un profil.
- Elle peut porter seulement quelques overrides numériques : offset, scale, opacity.
- Elle ne doit pas porter `modeOverride` en V0.
- Elle ne doit pas porter `colorHexRgb` en V0.
- Elle ne doit pas porter `renderPass` en V0.
- Elle ne doit pas porter `softnessMode` en V0.
- `castsShadow: false` gagne toujours.
- `shadow == null` signifie aucun système Shadow configuré.

Pourquoi ne pas rendre tous les champs overrideables :

- L'éditeur deviendrait ingérable dès la première UI.
- Les instances et éléments pourraient diverger du preset sans traçabilité.
- `renderPass` libre par élément recrée le problème de z-order.
- `color` et `softness` peuvent attendre l'existence de presets solides.

Validation future :

- Si `castsShadow == true`, `shadowProfileId` devrait être non nul après intégration du catalogue.
- Si le profil est introuvable, validation authoring signale un diagnostic.
- Runtime ne lance pas d'exception : il rend no shadow + diagnostic.

## 11. Override instance futur

L'override par instance doit arriver en Shadow-6, pas avant.

Nom recommandé :

```dart
enum ShadowOverrideMode {
  inherit,
  disabled,
  custom,
}

final class MapPlacedElementShadowOverride {
  const MapPlacedElementShadowOverride({
    this.mode = ShadowOverrideMode.inherit,
    this.shadowProfileId,
    this.offsetX,
    this.offsetY,
    this.scaleX,
    this.scaleY,
    this.opacity,
  });

  final ShadowOverrideMode mode;
  final String? shadowProfileId;
  final double? offsetX;
  final double? offsetY;
  final double? scaleX;
  final double? scaleY;
  final double? opacity;
}
```

Champ futur dans `MapPlacedElement` :

```dart
final MapPlacedElementShadowOverride? shadowOverride;
```

Décisions :

- Absence d'override = inherit.
- `ShadowOverrideMode.inherit` = utiliser la config élément.
- `ShadowOverrideMode.disabled` = aucune ombre, même si l'élément en projette une.
- `ShadowOverrideMode.custom` = autoriser un profil alternatif et/ou des overrides limités.
- Pas de `modeOverride` en V0.
- Pas de `colorOverride` en V0.
- Pas de `renderPassOverride` en V0.
- Pas de `softnessOverride` en V0.

`custom` doit rester limité. Le but est de permettre "cet arbre a une ombre un peu plus courte" ou "cette instance n'a pas d'ombre", pas de transformer chaque instance en mini Shadow Studio.

## 12. Règles de merge futures

Lot recommandé : Shadow-7.

Le resolver doit être pur et ne doit pas importer Flutter, Flame ou éditeur.

Pseudo-code recommandé :

```text
resolveShadowConfig(element, catalog, instanceOverride):
  diagnostics = []

  if instanceOverride?.mode == disabled:
    return none(diagnostics)

  elementShadow = element.shadow
  if elementShadow == null:
    return none(diagnostics)

  if elementShadow.castsShadow == false:
    return none(diagnostics)

  profileId = elementShadow.shadowProfileId
  if profileId is null or blank:
    diagnostics += missingProfileId(element.id)
    return none(diagnostics)

  profile = catalog.profileById(profileId)
  if profile == null:
    diagnostics += missingProfile(profileId)
    return none(diagnostics)

  resolved = copy(profile)

  resolved.offsetX = elementShadow.offsetX ?? resolved.offsetX
  resolved.offsetY = elementShadow.offsetY ?? resolved.offsetY
  resolved.scaleX = elementShadow.scaleX ?? resolved.scaleX
  resolved.scaleY = elementShadow.scaleY ?? resolved.scaleY
  resolved.opacity = elementShadow.opacity ?? resolved.opacity

  if instanceOverride?.mode == custom:
    if instanceOverride.shadowProfileId is not null:
      customProfile = catalog.profileById(instanceOverride.shadowProfileId)
      if customProfile == null:
        diagnostics += missingProfile(instanceOverride.shadowProfileId)
        return none(diagnostics)
      resolved = copy(customProfile)
      resolved = applyElementOverridesAgainIfPolicyRequiresIt(resolved, elementShadow)

    resolved.offsetX = instanceOverride.offsetX ?? resolved.offsetX
    resolved.offsetY = instanceOverride.offsetY ?? resolved.offsetY
    resolved.scaleX = instanceOverride.scaleX ?? resolved.scaleX
    resolved.scaleY = instanceOverride.scaleY ?? resolved.scaleY
    resolved.opacity = instanceOverride.opacity ?? resolved.opacity

  if resolved.mode == none:
    return none(diagnostics)

  if resolved.scaleX <= 0 or resolved.scaleY <= 0:
    diagnostics += invalidScale(...)
    return none(diagnostics)

  resolved.opacity = clamp(resolved.opacity, 0, 1)
  if resolved.opacity <= 0:
    return none(diagnostics)

  // WorldLightState intentionally ignored in V0.
  return resolved(resolved, diagnostics)
```

Point à trancher précisément en Shadow-7 : si une instance `custom` choisit un autre profil, faut-il réappliquer les overrides élément après ce profil ? Recommandation : oui pour offset/scale/opacity, car la config élément décrit le comportement par défaut de cet asset; l'instance custom ne change que la base ou quelques paramètres. Le test doit figer ce choix.

Référence manquante :

- Validation authoring : diagnostic, idéalement erreur bloquante quand le manifest contient le catalogue.
- Runtime : no shadow + diagnostic non fatal.
- Modèle pur : ne connaît pas le catalogue, donc ne peut pas valider la référence.

Pas d'exception runtime pour un profil introuvable. Une ombre manquante ne doit pas empêcher la map de se lancer.

## 13. UI future dans Edit Element

La future UI Shadow élément doit vivre dans la modale `Edit Element` de la Tileset Library, pas dans l'éditeur de masques.

Emplacement recommandé :

- fichier probable : `packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart`
- zone : modale `Edit Element`
- position produit : entre `Type` et `Collision`

Section compacte recommandée :

```text
Ombre de l'élément
[ ] Projette une ombre
Preset: ...
Offset X / Y
Scale X / Y
Opacity
```

Champs à ne pas afficher en V0 :

- Mode si le preset le porte déjà.
- Render pass.
- Softness, sauf affichage lecture seule `Hard edge`.
- Couleur, sauf si la décision produit veut absolument un champ V0; recommandation : garder la couleur dans le preset.
- Blur.
- Time-of-day.
- Sprite source / mask.

Règles UX :

- Cette modale configure l'ombre par défaut de l'élément.
- L'instance placée sur la map aura plus tard `inherit` / `disabled` / `custom`.
- La section ne doit jamais modifier `collisionMask`, `occlusionMask`, `visualMask` ou `cells`.
- `ElementCollisionTripleMaskEditor` reste réservé aux masques visual/collision/occlusion.
- Le bouton ou sheet Collision existant ne doit pas devenir un éditeur Shadow.

Le premier lot éditeur Shadow doit être lecture/affichage read model avant d'ajouter des inputs persistants.

## 14. Runtime futur

Le runtime Shadow doit suivre le pattern Surface :

```text
MapData + ProjectManifest + light state optionnel
-> ShadowRuntimeResolver pur
-> ShadowRuntimeRenderInstruction[]
-> Flame Shadow Renderer
```

Règles :

- `ShadowRuntimeRenderInstruction` ne doit jamais être persisté.
- Les caches d'images, pictures, chunks ou atlas ne doivent jamais être persistés.
- L'état courant du soleil ne doit jamais être persisté dans la map.
- Le renderer Flame ne doit pas résoudre les références projet.
- Le resolver ne doit pas charger d'images.

Champs de `ProjectShadowProfile` convertibles plus tard en instruction :

- `mode`
- `renderPass`
- `offsetX`
- `offsetY`
- `scaleX`
- `scaleY`
- `opacity`
- `colorHexRgb`
- `softnessMode`

V0 runtime suffisant :

- `contactBlob` peut être rendu par ellipse simple.
- `ellipse` peut être rendu par `drawOval` ou `drawPath` simple.
- Pas de `saveLayer`.
- Pas de `ImageFilter.blur`.
- Pas de shader obligatoire.
- Pas de loader Shadow parallèle.

Evolution sprite plus tard :

- `customShadowSprite` et `customShadowAtlasFrame` devront réutiliser `RuntimeTilesetImage` et son chemin `drawImageRect`, afin de rester cohérents avec les tilesets runtime.
- Le resolver produira alors `tilesetId` + source rect, mais seulement quand le modèle source existera.

Culling V0 futur :

- Les ombres statiques offscreen ne doivent pas être dessinées.
- Les ombres dynamiques acteurs peuvent être recalculées légèrement chaque frame.
- Les ombres statiques ne doivent pas être recalculées pour toute la map à chaque frame.

## 15. Préparation heure de journée

Shadow V0 ne doit pas créer `WorldLightState` en Shadow-2.

Shadow V0 ne doit pas persister `ShadowLightProfile`.

Le modèle V0 doit seulement éviter de bloquer cette évolution :

- offset et scale restent numériques simples, donc multipliables plus tard ;
- opacity est séparée de la couleur, donc modulable par lumière ;
- render pass est contraint, donc les variations temporelles ne changent pas l'ordre de rendu ;
- pas de baked alpha dans `colorHexRgb`.

Stratégie V1/V2 :

| Concept | Lot futur | Persisté | Rôle |
|---|---:|---|---|
| `DayPhase` | V1/V2 | Peut-être | Nommer matin/midi/soir/nuit/intérieur. |
| `WorldLightState` | V1 | Non au départ | Etat runtime courant : direction, opacité, longueur. |
| `ShadowLengthMultiplier` | V1 | Non au départ | Modifier offset/scale en fonction de la phase. |
| `ShadowOpacityMultiplier` | V1 | Non au départ | Modifier opacity sans toucher au profil. |
| `IndoorShadowPolicy` | V2 | Oui si authoring map | Désactiver ou réduire les ombres indoor/grotte. |
| `ShadowLightProfile` | V2 | Oui | Preset authorable par map/zone. |
| Lumières locales | V2+ | Peut-être | Sujet séparé, plus proche lighting que shadow V0. |

Interdit V0 :

- `affectedByTimeOfDay`
- `timeMode`
- `minOpacity`
- `maxOpacity`
- direction solaire persistée
- interpolation frame-by-frame persistée

## 16. Tests des prochains lots

### Shadow-2 tests map_core

Fichiers recommandés :

- `packages/map_core/test/shadow/project_shadow_profile_test.dart`
- `packages/map_core/test/shadow/project_shadow_catalog_test.dart`

Cas exacts `ProjectShadowProfile` :

- crée un profil valide avec valeurs explicites ;
- applique les defaults V0 attendus ;
- rejette `id` vide ou whitespace ;
- rejette `name` vide ou whitespace ;
- rejette `scaleX <= 0` ;
- rejette `scaleY <= 0` ;
- rejette `opacity < 0` ;
- rejette `opacity > 1` ;
- rejette `NaN` et `Infinity` sur tous les doubles ;
- rejette `colorHexRgb` avec `#` ;
- rejette couleur trop courte, trop longue ou non hex ;
- vérifie égalité de valeur et `hashCode`.

Cas exacts `ProjectShadowCatalog` :

- catalogue vide valide ;
- conserve l'ordre des profils ;
- copie la liste en immuable ;
- lookup par id retourne le profil attendu ;
- lookup id inconnu retourne `null` ;
- rejette les ids dupliqués ;
- vérifie égalité de valeur si implémentée ;
- ne touche pas `ProjectManifest` ;
- ne crée pas de JSON généré ;
- ne crée pas de `toJson/fromJson`.

Commande cible Shadow-2 :

```bash
cd packages/map_core && dart test test/shadow/project_shadow_profile_test.dart test/shadow/project_shadow_catalog_test.dart
```

### Shadow-3 tests codecs

Fichiers recommandés :

- `packages/map_core/test/shadow/project_shadow_profile_json_codec_test.dart`
- `packages/map_core/test/shadow/project_shadow_catalog_json_codec_test.dart`

Cas exacts :

- encode/decode `ProjectShadowProfile` complet ;
- encode/decode `ProjectShadowCatalog` complet ;
- decode des champs optionnels manquants avec defaults ;
- enum inconnu produit une `ValidationException` ou fallback documenté ;
- couleur `#RRGGBB` acceptée par decode si cette tolérance est retenue ;
- couleur invalide rejetée ;
- opacity invalide rejetée ;
- scale invalide rejetée ;
- ordre des profils préservé ;
- duplicate id rejeté au decode catalogue ;
- aucun `toJson/fromJson` ajouté au modèle ;
- aucun `build_runner` requis.

Commande cible Shadow-3 :

```bash
cd packages/map_core && dart test test/shadow
```

### Shadow-4 tests config élément

Cas exacts :

- ancien JSON projet sans `shadow` decode avec `shadow == null` ;
- `ProjectElementEntry.shadow` absent implique no shadow ;
- `castsShadow: false` implique no shadow ;
- `castsShadow: true` avec `shadowProfileId` valide est accepté ;
- overrides offset/scale/opacity valides acceptés ;
- overrides invalides rejetés ;
- aucune mutation de `collisionProfile`, `visualMask`, `collisionMask`, `occlusionMask`.

### Shadow-5 tests manifest catalog

Cas exacts :

- manifest sans `shadowCatalog` decode en catalogue vide ;
- manifest avec `shadowCatalog: null` decode en catalogue vide si le pattern Surface est repris ;
- encode manifest préserve catalogue ;
- duplicate profile ids rejetés ;
- référence element -> profile introuvable produit diagnostic de validation authoring ;
- ancien projet JSON reste backward-compatible.

### Shadow-6 tests override instance

Cas exacts :

- ancien `MapPlacedElement` sans `shadowOverride` decode en inherit ;
- override absent = inherit ;
- `disabled` gagne sur config élément ;
- `custom` peut changer profil ;
- `custom` peut override offset/scale/opacity ;
- valeurs invalides rejetées ;
- aucune modification de `applyCollision`, `behaviors`, `properties` ou layer cells.

### Shadow-7 tests resolver / merge

Cas exacts :

- aucun shadow config -> no shadow ;
- `castsShadow false` -> no shadow ;
- instance disabled -> no shadow ;
- profil introuvable -> no shadow + diagnostic ;
- profile `mode none` -> no shadow ;
- element overrides appliqués ;
- instance overrides appliqués après élément ;
- opacity clamp ou validation defensive selon décision finale ;
- scale positive obligatoire ;
- renderPass vient du profil et reste contraint ;
- light state ignoré en V0.

## 17. Roadmap corrigée Shadow-2 à Shadow-10

| Lot | Nom | Objectif | Fichiers probables | Tests | Critère de validation | Non-objectifs |
|---:|---|---|---|---|---|---|
| Shadow-2 | Shadow Value Objects V0 | Créer enums, `ProjectShadowProfile`, `ProjectShadowCatalog` purs. | `packages/map_core/lib/src/models/shadow.dart`, `packages/map_core/lib/src/models/shadow_catalog.dart`, `packages/map_core/lib/map_core.dart` | `project_shadow_profile_test.dart`, `project_shadow_catalog_test.dart` | Value objects validés, égalité, catalogue immuable, aucun JSON. | Pas de manifest, pas d'éditeur, pas de runtime, pas de build_runner. |
| Shadow-3 | Shadow JSON Codecs V0 | Ajouter codecs manuels externes profile/catalog. | `packages/map_core/lib/src/operations/project_shadow_profile_json_codec.dart`, `project_shadow_catalog_json_codec.dart` | codec profile/catalog, enum inconnu, defaults, invalides | Encode/decode stable sans `toJson/fromJson`. | Pas de `ProjectManifest`, pas de Freezed, pas de génération. |
| Shadow-4 | ProjectElement Shadow Config V0 | Ajouter config optionnelle par élément. | `project_manifest.dart` ou modèle dédié Shadow + converter si nécessaire | old JSON, absent -> null/no shadow, overrides limités | Ancien manifest compatible; collision/occlusion inchangées. | Pas de catalogue manifest obligatoire si lot séparé; pas d'UI. |
| Shadow-5 | ProjectShadowCatalog Manifest Integration V0 | Brancher catalogue au manifest avec default vide. | `project_manifest.dart`, codec/converter manifest, `validators.dart` | absent/null -> empty, duplicate ids, refs manquantes diagnostics | Catalog persistant backward-compatible. | Pas d'override instance, pas de runtime. |
| Shadow-6 | MapPlacedElement Shadow Override V0 | Ajouter override instance limité. | `map_data.dart`, modèle override, tests JSON `MapPlacedElement` | absent -> inherit, disabled wins, custom limité | Anciennes maps compatibles; aucune collision side-effect. | Pas de renderer, pas d'UI map complète. |
| Shadow-7 | Shadow Config Resolver / Merge Rules V0 | Résoudre profil + élément + instance en config pure. | `packages/map_core/lib/src/operations/shadow_config_resolver.dart` | merge matrix, diagnostics, missing profile, clamps | Resolver pur testé sans Flutter/Flame. | Pas de dessin, pas d'image, pas de time-of-day. |
| Shadow-8 | Editor Shadow Read Model V0 | Lire les données Shadow pour l'éditeur sans édition complète. | read model editor proche use cases Tileset Library | widget/use-case tests si existants | L'éditeur peut afficher état Shadow sans changer les masques. | Pas d'édition instance, pas de preview avancée. |
| Shadow-9 | Edit Element Shadow Section V0 | Ajouter section compacte dans `Edit Element`. | `tileset_palette_panel.dart`, use cases élément | tests UI/use-case ciblés | Activer preset + overrides limités; aucune mutation collision/occlusion. | Pas de Shadow Studio, pas de mask editor Shadow. |
| Shadow-10 | Shadow Render Order Regression V0 | Caractériser ordre runtime/editor avant dessin complet. | `map_layers_component.dart` tests, docs/report éventuel | tests d'ordre de rendu / characterization | Ordre cible documenté et protégé. | Pas de gros renderer, pas de cache chunk, pas de blur. |

Changement par rapport à la roadmap Shadow-0 : Shadow-10 devient une caractérisation d'ordre de rendu avant un renderer complet. Cela réduit le risque d'introduire une ombre qui passe devant le joueur ou derrière un mauvais layer.

Le renderer Flame réel peut commencer après Shadow-10, avec un lot Shadow-11 dédié aux actor blob shadows ou static contact shadows selon priorité produit.

## 18. Non-objectifs V0

| Feature / champ | Statut | Raison du report | Impact si ajouté trop tôt |
|---|---|---|---|
| `projectedQuad` | V1/V2 | Besoin de règles direction/longueur. | Math et UI prématurées. |
| `projectedSpriteMask` | V2 | Besoin de source sprite/mask et runtime image. | Couplage renderer trop tôt. |
| `customShadowSprite` | V1/V2 | Nécessite tileset/source rect. | Loader parallèle ou modèle incomplet. |
| `customShadowAtlasFrame` | V2 | Nécessite stratégie atlas. | Batching/cache avant besoins mesurés. |
| `handPaintedMask` | V2 | Nécessite UI mask dédiée. | Risque de mélanger avec collision masks. |
| `frameSpecific` | V2 | Nécessite animation sprite shadow. | Multiplie données et tests. |
| `coverageMode` | V1/V2 | Besoin produit non figé. | Enum fourre-tout. |
| `lowerBodyOnly` | V1/V2 | Concerne acteurs/occlusion spécifique. | Mauvais mélange actor render/element profile. |
| `customMask` | V2 | Besoin editor dédié. | Confusion avec `visualMask`. |
| `skewX / skewY` | V1/V2 | Utile pour soleil, pas V0. | UI trop complexe. |
| `rotationDegrees` | V1/V2 | Même famille que projection. | Casse rendu pixel simple. |
| `blurRadius` | V2 | Aucun blur runtime V0. | Invite `saveLayer` coûteux. |
| `falloff` | V2 | Pas de modèle softness avancé. | Faux réalisme non testé. |
| `runtimeBlur` | V2 ou non-objectif | Performance suspecte. | Flame peut devenir trop coûteux. |
| `timeMode` | V1/V2 | Pas de `WorldLightState` V0. | Bloque le modèle avant besoins réels. |
| `affectedByTimeOfDay` | V1/V2 | Même sujet que `timeMode`. | Champ boolean trop pauvre. |
| `minOpacity / maxOpacity` | V1/V2 | Seulement utile avec lumière. | Contraintes inutiles en V0. |
| `sourceMaskId` | V2 | Pas de mask shadow. | Couplage editor/asset prématuré. |
| `shadowTilesetId` | V1/V2 | Pas de custom sprite V0. | Introduit loader/source avant renderer simple. |
| `shadowSource` | V1/V2 | Même sujet. | Risque de dupliquer `TilesetVisualFrame`. |
| ShadowLayer manuel | V2 | Sujet surface/tile overlay distinct. | Mélange paint layer et element shadow. |
| Local lights | V2+ | Sujet lighting, pas shadow V0. | Explosion de complexité. |
| Day phase editor | V2 | Dépend de light model. | UI sans moteur. |
| Chunk cache | V1/V2 runtime | Nécessite métriques. | Optimisation prématurée. |
| `drawAtlas` batching | V2 runtime | Utile avec sprites nombreux. | Complexité sans sprite shadows V0. |

## 19. Risques et validations humaines

Risques :

- Le nom `colorHexRgb` peut différer des conventions produit si l'équipe préfère toujours afficher/stocker `#RRGGBB`.
- `ProjectElementShadowConfig` avec overrides limités peut être jugé trop restrictif pour certains assets artistiques.
- `ShadowRenderPass.actorContact` dans `map_core` peut paraître runtime-ish, mais il reste un contrat visuel abstrait, pas une priorité Flame.
- `ShadowSoftnessMode.hardEdge` avec une seule valeur peut sembler superflu; il est gardé pour figer l'interdiction de blur et préparer un enum stable.
- Le choix "custom profile instance + réappliquer overrides élément" mérite validation humaine en Shadow-7.
- La future position exacte de `groundStatic` par rapport aux surfaces doit être confirmée par tests de rendu, pas seulement par lecture.

Validations humaines recommandées avant Shadow-2 :

- Accepter `ProjectShadowCatalog` pur dès Shadow-2.
- Accepter la couleur canonique sans `#`.
- Accepter que `runtimeBlur` soit absent de l'enum V0.
- Accepter que les overrides V0 ne couvrent pas color/renderPass/softness.
- Accepter que Shadow-10 soit une caractérisation d'ordre de rendu avant renderer.

## 20. Autocritique

Ce rapport peut sous-estimer le besoin d'un mode `projectedQuad` tôt si les maisons/arbres hauts sont prioritaires visuellement. La recommandation garde ces cas pour V1/V2 afin d'éviter un modèle mathématique trop large avant d'avoir un renderer simple.

Le choix `ShadowSoftnessMode.hardEdge` avec une seule valeur est discutable. Supprimer l'enum jusqu'à V1 serait encore plus minimaliste. Je le garde parce que le prompt demande explicitement une décision softness/blur et parce que l'enum permet d'interdire `runtimeBlur` sans ambiguïté.

Le choix `colorHexRgb` sans `#` est cohérent avec `TilesetTransparentColor`, mais l'UI produit préférera probablement montrer `#RRGGBB`. Il faudra être strict sur la frontière : UI lisible, modèle canonique.

Je n'ai pas exécuté de tests Dart, car ce lot ne modifie aucun code de production. Les tests deviennent obligatoires à partir de Shadow-2.

Je n'ai pas inspecté chaque ligne de tous les widgets editor autour de la Tileset Library; l'objectif ici était de localiser l'endroit produit et d'éviter le mélange avec l'éditeur de masques. Le lot Shadow-8 devra inspecter plus finement l'état Flutter avant toute UI.

Le rapport suppose que les codecs manuels Surface/Environment restent la direction préférée. Si l'équipe décide de revenir à Freezed pour tous les modèles persistés, Shadow devra réévaluer Shadow-3 à Shadow-5.

## 21. Preuves / commandes / git status

### Commandes lancées

```bash
git status --short --untracked-files=all
find reports/shadows -maxdepth 1 -type f -print
pwd && test -d reports/shadows && echo reports_shadows_exists
printf 'report_exists=' && test -f reports/shadows/shadow_model_decision.md && echo yes || echo no
printf 'section_count=' && rg -n '^## [0-9]+\.' reports/shadows/shadow_model_decision.md | wc -l | tr -d ' '
printf 'placeholders=' && rg -n 'T[O]DO|T[B]D|À confirme[r]|A confirme[r]' reports/shadows/shadow_model_decision.md | wc -l | tr -d ' '
git diff --stat
```

Des lectures ciblées ont aussi été effectuées avec recherche/indexation sur les fichiers listés en section 2, notamment pour vérifier :

- l'existence du rapport Shadow-0 ;
- le pattern `ProjectSurfaceCatalog` dans `ProjectManifest` ;
- les codecs manuels Surface / Environment / PathPattern ;
- la convention `TilesetTransparentColor` ;
- la séparation `visualMask` / `collisionMask` / `occlusionMask` ;
- l'emplacement de `Edit Element` dans `tileset_palette_panel.dart` ;
- les composants runtime Flame à ne pas modifier.

### Git status initial

```text
?? reports/shadows/shadow_system_architecture_audit.md
```

### Git status final

```text
?? reports/shadows/shadow_model_decision.md
?? reports/shadows/shadow_system_architecture_audit.md
```

### Git diff stat final

```text
(aucune sortie)
```

Note : `git diff --stat` ne liste pas les fichiers non suivis. Le fichier créé par ce lot apparaît donc dans `git status --short --untracked-files=all`, pas dans `git diff --stat`.

### Fichiers créés

- `reports/shadows/shadow_model_decision.md`

### Fichiers modifiés

- Aucun fichier de production.
- Aucun fichier existant modifié volontairement.

### Fichiers non modifiés volontairement

- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_core/lib/src/models/element_collision_profile.dart`
- `packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart`
- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/player_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/overworld_actor_component.dart`
- tous les modèles Surface / Path / Environment existants.

### Tests lancés

Aucun test Dart/Flutter lancé pour ce lot, car le changement est exclusivement documentaire et le prompt n'exige pas de test si seul le rapport Markdown est modifié.

### Tests non lancés et pourquoi

Les tests `dart test` / `flutter test` ne sont pas lancés ici pour éviter de transformer un lot de décision en validation de code inchangé. Les premiers tests obligatoires commencent avec Shadow-2 :

```bash
cd packages/map_core && dart test test/shadow/project_shadow_profile_test.dart test/shadow/project_shadow_catalog_test.dart
```

Puis Shadow-3 devra lancer :

```bash
cd packages/map_core && dart test test/shadow
```
