# Shadow-26 — Shadow Footprint / Anchor Model Decision V0

## 1. Résumé exécutif

Shadow-26 est un lot de décision d'architecture. Aucun code de production n'a été modifié.

Décision retenue :

- ne pas placer le footprint comme responsabilité principale de `ProjectShadowProfile` ;
- ajouter un footprint par défaut au niveau `ProjectElementShadowConfig` ;
- ajouter un override de footprint au niveau `MapPlacedElementShadowOverride` ;
- représenter le footprint avec un value object dédié ;
- utiliser des ratios en V0 : `anchorXRatio`, `anchorYRatio`, `footprintWidthRatio`, `footprintHeightRatio` ;
- conserver `offsetX`, `offsetY`, `scaleX`, `scaleY`, `opacity` comme ajustements fins déjà existants ;
- extraire ensuite une opération pure `map_core` de géométrie statique pour garder runtime et éditeur alignés.

Synthèse courte :

```text
ProjectShadowProfile = style partagé
ProjectElementShadowConfig = footprint par défaut de l'objet
MapPlacedElementShadowOverride = exception par instance
map_core operation = géométrie commune runtime/editor
```

## 2. Problème actuel

Les ombres statiques sont visibles, configurables et ajustables, mais leur géométrie de base reste dérivée de la bounding box visuelle de la première frame.

Formule actuelle côté runtime :

```text
worldLeft = placed.pos.x * cellWidth
worldTop = placed.pos.y * cellHeight
visualWidth = firstFrame.source.width * cellWidth
visualHeight = firstFrame.source.height * cellHeight
anchorXRatio = 0.5
anchorYRatio = 1.0
baseWidthMultiplier = 0.75
baseHeightMultiplier = 0.25
```

Formule actuelle côté éditeur :

```text
anchorX = baseLeft + visualWidth * 0.5
anchorY = baseTop + visualHeight
shadowWidth = visualWidth * 0.75 * resolved.scaleX
shadowHeight = visualHeight * 0.25 * resolved.scaleY
```

Conséquence : un objet haut et fin, un objet bas et large ou un sprite avec beaucoup d'espace visuel autour de sa base obtient une ombre plausible seulement après correction manuelle. Shadow-25 aide l'utilisateur à corriger, mais ne règle pas la cause.

## 3. Audit des modèles existants

### `ProjectShadowProfile`

Extrait audité : `packages/map_core/lib/src/models/shadow.dart:44-81`

```text
ProjectShadowProfile:
- id
- name
- mode
- renderPass
- offsetX / offsetY
- scaleX / scaleY
- opacity
- colorHexRgb
- softnessMode
```

Constat : le profil porte déjà des valeurs de style et des ajustements numériques globaux. Il n'a pas de connaissance d'un sprite, d'un élément, d'une frame, d'un pied, d'une emprise au sol ou d'une instance placée.

### `ProjectElementShadowConfig`

Extrait audité : `packages/map_core/lib/src/models/shadow.dart:115-159`

```text
ProjectElementShadowConfig:
- castsShadow
- shadowProfileId
- offsetX / offsetY
- scaleX / scaleY
- opacity
```

Constat : c'est aujourd'hui le meilleur endroit pour définir le comportement par défaut d'un type d'objet. Un lampadaire, un stand ou un arbre connaissent mieux leur emprise au sol que le profil partagé.

### `MapPlacedElementShadowOverride`

Extrait audité : `packages/map_core/lib/src/models/shadow.dart:185-239`

```text
MapPlacedElementShadowOverride:
- mode inherit / disabled / custom
- shadowProfileId
- offsetX / offsetY
- scaleX / scaleY
- opacity
```

Constat : c'est le bon niveau pour les exceptions d'instance. Le modèle interdit déjà les champs custom lorsque `mode != custom`, ce qui doit rester vrai pour le futur footprint override.

### Intégration JSON actuelle

Extraits audités :

- `packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart:64-78`
- `packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart:81-133`
- `packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart:74-88`
- `packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart:91-141`

Constats :

- les codecs sont manuels ;
- les champs inconnus sont ignorés en lecture ;
- les champs optionnels absents gardent le comportement existant ;
- les champs `shadow` et `shadowOverride` sont branchés dans des modèles Freezed via converters, sans nécessiter de changer `ProjectElementEntry` ou `MapPlacedElement` pour ajouter des sous-champs au contenu Shadow.

## 4. Audit runtime geometry

### Metrics statiques runtime

Extrait audité : `packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:11-39`

```text
StaticPlacedElementShadowRuntimeMetrics:
- worldLeft
- worldTop
- visualWidth
- visualHeight
- anchorXRatio = 0.5
- anchorYRatio = 1.0
- baseWidthMultiplier = 0.75
- baseHeightMultiplier = 0.25
```

Extrait géométrique : `packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:91-99`

```text
worldX = worldLeft + visualWidth * anchorXRatio
worldY = worldTop + visualHeight * anchorYRatio
baseWidth = visualWidth * baseWidthMultiplier
baseHeight = visualHeight * baseHeightMultiplier
```

Constat important : le runtime a déjà le concept technique de ratios d'ancre et de footprint, mais seulement comme métriques runtime transitoires. Ces valeurs ne sont pas stockées dans le modèle authoring et ne sont pas alimentées depuis l'éditeur.

### Sources runtime statiques

Extrait audité : `packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:47-58`

```text
metrics: StaticPlacedElementShadowRuntimeMetrics(
  worldLeft: placed.pos.x * cellWidth,
  worldTop: placed.pos.y * cellHeight,
  visualWidth: source.width * cellWidth,
  visualHeight: source.height * cellHeight,
)
```

Constat : Shadow-21 prépare les sources avec la première frame, sans footprint authorable.

### Resolver runtime générique

Extrait audité : `packages/map_runtime/lib/src/shadow/shadow_runtime_resolver.dart:77-93`

```text
resolvedWidth = anchor.baseWidth * resolved.scaleX
resolvedHeight = anchor.baseHeight * resolved.scaleY
centerX = anchor.worldX + resolved.offsetX
centerY = anchor.worldY + resolved.offsetY
```

Constat : `scaleX/scaleY` agissent après la base width/height. C'est précisément la différence entre footprint et scale : le footprint définit la base sémantique, le scale ajuste le rendu résolu.

## 5. Audit editor preview geometry

Extrait audité : `packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart:106-130`

```text
visualWidth = source.width * tileWidth
visualHeight = source.height * tileHeight
baseLeft = placed.pos.x * tileWidth
baseTop = placed.pos.y * tileHeight
anchorX = baseLeft + visualWidth * 0.5
anchorY = baseTop + visualHeight
shadowWidth = visualWidth * 0.75 * resolved.scaleX
shadowHeight = visualHeight * 0.25 * resolved.scaleY
centerX = anchorX + resolved.offsetX
centerY = anchorY + resolved.offsetY
```

Constat : l'éditeur reproduit l'esprit de la formule runtime, mais sans réutiliser une opération commune. Toute évolution de géométrie devra donc être factorisée pour éviter une divergence entre preview et runtime.

## 6. Analyse footprint vs scale

Le footprint est l'emprise de base au sol d'un objet. Il répond à la question :

```text
Quelle surface au sol cet objet occupe-t-il naturellement pour son ombre ?
```

Le scale répond à une autre question :

```text
Comment ajuster l'ombre résolue après avoir choisi sa base ?
```

Exemples :

- lampadaire : footprint étroit par défaut, puis scale pour un petit ajustement ;
- stand : footprint plutôt large mais peu haut, puis scale si une instance particulière doit être réduite ;
- arbre : footprint large et ancré au tronc, puis scale selon profil ou instance ;
- maison : footprint potentiellement désactivé ou très spécifique, pas seulement `scaleY = 0.1` sur une bounding box de maison.

Pourquoi Shadow-25 ne suffit pas :

- les presets modifient `scaleX/scaleY/offset/opacity` instance par instance ;
- ils ne changent pas la base par défaut de l'élément ;
- ils forcent l'utilisateur à corriger répétitivement chaque instance d'un même objet ;
- ils ne donnent pas au runtime ou à la preview une meilleure compréhension de l'emprise réelle.

## 7. Analyse anchor

L'anchor est le point de contact/référence autour duquel l'ombre est placée.

Aujourd'hui :

```text
anchorXRatio = 0.5
anchorYRatio = 1.0
```

Cette règle marche pour beaucoup de sprites dont le pied est au bas-centre de la frame, mais échoue pour des objets dont la base visuelle n'est pas centrée :

- panneau décalé dans la frame ;
- arbre dont le tronc n'est pas au centre de la couronne ;
- lampadaire fin dans une frame large ;
- asset composé avec beaucoup de vide transparent.

Décision V0 :

- autoriser `anchorXRatio` dans `0..1` ;
- autoriser `anchorYRatio` dans `0..1` ;
- garder les offsets existants pour les décalages hors-frame ou effets de portée ;
- ne pas ajouter d'ancre pixel absolue en V0.

## 8. Ratios vs pixels

### Ratios

Champs :

```text
anchorXRatio
anchorYRatio
footprintWidthRatio
footprintHeightRatio
```

Avantages :

- indépendants du tile size ;
- alignés avec les métriques runtime déjà existantes ;
- portables entre runtime et éditeur ;
- faciles à appliquer sur la largeur/hauteur visuelle actuelle ;
- compatibles avec les sprites multi-tailles tant que la frame source est la référence.

Limites :

- moins précis qu'un réglage pixel pour certains assets pixel-art ;
- dépend encore de la bounding box visuelle ;
- nécessitera peut-être plus tard des handles visuels pour être agréable.

### Pixels

Champs possibles :

```text
footprintWidthPx
footprintHeightPx
anchorOffsetXpx
anchorOffsetYpx
```

Avantages :

- précision pixel-art ;
- bon contrôle pour lampadaires/panneaux.

Limites :

- dépendance au tile size et au scale d'import ;
- moins portable ;
- plus difficile à garder cohérent dans un projet no-code ;
- risque d'introduire trop tôt des notions d'unité/résolution dans l'UI.

Décision V0 : ratios.

Garde-fou futur : ajouter des pixels absolus seulement si des cas réels démontrent que les ratios ne suffisent pas.

## 9. Profil vs élément vs instance

### Option A — footprint dans `ProjectShadowProfile`

Avantages :

- centralisé ;
- partageable entre plusieurs éléments ;
- facile à seed avec des profils par défaut.

Inconvénients :

- mélange style visuel et géométrie propre à l'objet ;
- un même profil `Ombre compacte` peut convenir à un panneau mais pas à un lampadaire ;
- pousse à multiplier les profils pour compenser les formes d'objets ;
- ne corrige pas le fait que l'élément connaît mieux son pied que le catalogue.

Décision : rejeté comme niveau principal. Le profil peut conserver `mode/renderPass/color/opacity/scale/offset` comme style par défaut, mais ne doit pas porter seul le footprint.

### Option B — footprint dans `ProjectElementShadowConfig`

Avantages :

- l'élément source connaît sa base ;
- corrige toutes les instances du même asset ;
- évite de régler chaque instance ;
- cohérent avec l'UI d'édition d'ombre d'élément.

Inconvénients :

- nécessite une extension du modèle Shadow ;
- nécessite une UI d'édition élément ;
- nécessite une compatibilité JSON explicite.

Décision : recommandé pour le footprint par défaut.

### Option C — footprint dans `MapPlacedElementShadowOverride`

Avantages :

- parfait pour exceptions locales ;
- cohérent avec Shadow-23 ;
- permet de corriger une instance sans changer toutes les autres.

Inconvénients :

- mauvais niveau si utilisé seul ;
- peut créer beaucoup de réglages répétitifs.

Décision : recommandé comme override d'instance, pas comme source principale.

### Option D — modèle multi-niveaux

Décision retenue.

```text
ProjectShadowProfile
  -> style partagé

ProjectElementShadowConfig.footprint
  -> footprint par défaut

MapPlacedElementShadowOverride.footprint
  -> exception par instance

offset/scale/opacity existants
  -> ajustements fins après footprint
```

## 10. Décision retenue

Décision principale :

```text
Adopter un modèle multi-niveaux :
- profil = style ;
- élément = footprint par défaut ;
- instance = footprint override ;
- géométrie résolue = opération pure map_core partagée runtime/editor.
```

Champs V0 :

```text
anchorXRatio
anchorYRatio
footprintWidthRatio
footprintHeightRatio
```

Règles V0 :

- `anchorXRatio` et `anchorYRatio` : finis, `0..1` ;
- `footprintWidthRatio` et `footprintHeightRatio` : finis, strictement `> 0` ;
- absence de footprint : comportement actuel ;
- champs partiels : chaque champ absent hérite du niveau précédent ;
- instance override possible seulement en mode `custom`, comme les champs numériques actuels.

## 11. Modèle conceptuel recommandé

Nom recommandé pour le value object :

```dart
final class StaticShadowFootprintConfig {
  const StaticShadowFootprintConfig({
    this.anchorXRatio,
    this.anchorYRatio,
    this.footprintWidthRatio,
    this.footprintHeightRatio,
  });

  final double? anchorXRatio;
  final double? anchorYRatio;
  final double? footprintWidthRatio;
  final double? footprintHeightRatio;
}
```

Pourquoi des champs nullable dans le value object authoring :

- permet les overrides partiels ;
- garde les JSON propres ;
- permet à l'élément de définir seulement ce qui est nécessaire ;
- permet à l'instance de modifier uniquement un ratio sans recopier toute la géométrie.

Résolution conceptuelle :

```text
defaults V0:
  anchorXRatio = 0.5
  anchorYRatio = 1.0
  footprintWidthRatio = 0.75
  footprintHeightRatio = 0.25

merge:
  defaults
  -> ProjectElementShadowConfig.footprint
  -> MapPlacedElementShadowOverride.footprint si mode custom
```

Alternative plus stricte :

```dart
final class StaticShadowFootprint {
  const StaticShadowFootprint({
    this.anchorXRatio = 0.5,
    this.anchorYRatio = 1.0,
    this.footprintWidthRatio = 0.75,
    this.footprintHeightRatio = 0.25,
  });
}
```

Cette alternative est plus simple pour une valeur résolue, mais moins bonne pour l'authoring partiel. Recommandation : utiliser un config nullable pour les niveaux persistés, puis produire une valeur résolue non-null dans l'opération de géométrie.

## 12. Compatibilité JSON / migrations

Contraintes respectées par la trajectoire recommandée :

- nouveaux champs optionnels ;
- absence de `footprint` = comportement actuel ;
- anciens JSON continuent à décoder ;
- codecs manuels peuvent ignorer les clés absentes ;
- encoder `footprint` seulement s'il existe et contient au moins un champ non-null ;
- aucune migration obligatoire au moment de l'ajout.

Point technique important : `ProjectElementShadowConfig` et `MapPlacedElementShadowOverride` sont des classes manuelles dans `shadow.dart`, avec codecs manuels. Les modèles Freezed `ProjectElementEntry` et `MapPlacedElement` contiennent déjà les objets Shadow via converters :

- `ProjectElementEntry.shadow` : `packages/map_core/lib/src/models/project_manifest.dart:381-382`
- `MapPlacedElement.shadowOverride` : `packages/map_core/lib/src/models/map_data.dart:109-110`

Donc un futur lot peut ajouter des sous-champs Shadow sans changer la signature Freezed de `ProjectElementEntry` ou `MapPlacedElement`.

Si un futur lot déplace le footprint dans un nouveau champ Freezed au lieu d'un sous-champ Shadow, alors `build_runner` deviendrait nécessaire. Cette option n'est pas recommandée en V0.

## 13. Runtime/editor alignment

Problème actuel :

- runtime a `StaticPlacedElementShadowRuntimeMetrics` avec ratios ;
- éditeur recode la formule directement dans `editor_static_shadow_preview.dart` ;
- les deux sont alignés par convention, pas par code partagé.

Décision de trajectoire :

Créer plus tard une opération pure dans `map_core`, par exemple :

```dart
final class StaticShadowVisualMetrics {
  const StaticShadowVisualMetrics({
    required this.left,
    required this.top,
    required this.visualWidth,
    required this.visualHeight,
  });
}

final class ResolvedStaticShadowFootprint {
  const ResolvedStaticShadowFootprint({
    required this.anchorXRatio,
    required this.anchorYRatio,
    required this.footprintWidthRatio,
    required this.footprintHeightRatio,
  });
}

final class ResolvedStaticShadowGeometry {
  const ResolvedStaticShadowGeometry({
    required this.centerX,
    required this.centerY,
    required this.width,
    required this.height,
    required this.left,
    required this.top,
  });
}
```

Cette opération resterait pure Dart, sans Flutter, Flame, Canvas ou runtime dependency.

Flux futur :

```text
map_core:
  resolve static footprint config
  resolve static shadow geometry

map_runtime:
  prépare visual metrics
  appelle map_core
  produit ShadowRuntimeRenderInstruction

map_editor:
  prépare visual metrics
  appelle map_core
  produit EditorStaticShadowPreviewInstruction
```

## 14. Roadmap proposée

Roadmap micro-lots recommandée :

```text
Shadow-27 — Static Shadow Footprint Value Object / JSON V0
```

Ajouter `StaticShadowFootprintConfig` dans `map_core`, brancher en sous-champ optionnel dans `ProjectElementShadowConfig` et `MapPlacedElementShadowOverride`, mettre à jour codecs et tests. Aucun runtime/editor.

```text
Shadow-28 — Static Shadow Footprint Merge / Geometry Core V0
```

Créer une opération pure `map_core` qui fusionne defaults + élément + override, et calcule la géométrie statique à partir des visual metrics. Tester que l'absence de footprint reproduit exactement la formule actuelle.

```text
Shadow-29 — Runtime Static Shadow Geometry Integration V0
```

Remplacer la formule runtime statique par l'opération core. Aucun changement UI.

```text
Shadow-30 — Editor Static Shadow Preview Geometry Integration V0
```

Remplacer la formule éditeur par l'opération core. Vérifier preview et runtime alignés.

```text
Shadow-31 — Element Shadow Footprint UI V0
```

Ajouter l'édition du footprint par défaut au niveau élément source.

```text
Shadow-32 — Instance Shadow Footprint Override UI V0
```

Ajouter l'édition du footprint override dans la section instance. Garder Shadow-25 comme presets rapides offset/scale/opacité ou l'adapter pour écrire footprint seulement si le design UX le justifie.

```text
Shadow-33 — Shadow Footprint Fixtures / Visual Polish V0
```

Créer des fixtures lampadaire/stand/arbre/panneau et vérifier sauvegarde, preview et runtime.

Roadmap optionnelle plus tard :

```text
Shadow-34 — Direct Manipulation Handles V0
Shadow-35 — Pixel Absolute Footprint Evaluation
```

## 15. Alternatives rejetées

### Tout mettre dans `ProjectShadowProfile`

Rejeté parce que le profil est partagé et ne connaît pas la forme de l'objet. Cela pousserait à créer des profils trop spécifiques : `lampadaire-fin`, `stand-bas`, `arbre-large`, etc.

### Tout mettre dans `MapPlacedElementShadowOverride`

Rejeté parce que cela force la correction instance par instance. C'est précisément ce que Shadow-26 veut éviter.

### Remplacer `scaleX/scaleY` par footprint

Rejeté. Les deux concepts sont utiles :

- footprint = base sémantique ;
- scale = ajustement final.

### Ajouter des pixels absolus maintenant

Rejeté en V0. Trop dépendant du tile size et de l'échelle d'import. Les ratios collent mieux au modèle actuel et aux métriques runtime existantes.

### Garder deux formules séparées runtime/editor

Rejeté à moyen terme. C'était acceptable pour Shadow-21/24, mais le footprint authorable rendra la divergence plus risquée.

## 16. Risques / réserves

- Les ratios restent dépendants de la bounding box visuelle ; des sprites avec beaucoup de vide transparent peuvent encore nécessiter des ajustements.
- Les champs nullable dans un value object demandent des règles de merge très testées.
- L'UI devra éviter de présenter trop de curseurs d'un coup.
- Le modèle ne doit pas promettre une vraie lumière globale.
- Les defaults V0 devront être testés pour reproduire exactement l'ancien comportement quand `footprint == null`.

## 17. Réponses aux 10 questions obligatoires

### 1. Pourquoi les presets Shadow-25 ne suffisent-ils pas ?

Parce qu'ils corrigent l'instance après coup via offset/scale/opacité. Ils ne définissent pas l'emprise par défaut d'un objet et obligent à répéter les corrections.

### 2. Pourquoi le footprint est-il différent du scaleX/scaleY ?

Le footprint définit la base naturelle de l'ombre. Le scale ajuste cette base après résolution. Le runtime actuel applique déjà `scaleX/scaleY` après `anchor.baseWidth/baseHeight`.

### 3. Pourquoi le profil Shadow ne doit-il probablement pas porter seul le footprint ?

Parce que le profil décrit un style partagé. Le footprint dépend de l'objet : lampadaire, stand, arbre, panneau. Mélanger ces responsabilités rendrait le catalogue trop spécifique.

### 4. Pourquoi l'élément source doit-il avoir un footprint par défaut ?

Parce qu'il connaît sa forme et son point de contact. Une correction au niveau élément s'applique automatiquement à toutes les instances.

### 5. Pourquoi l'instance doit-elle pouvoir override ?

Parce qu'une instance peut être placée dans un contexte spécial ou utiliser un asset/profil où l'ombre par défaut doit être ajustée localement.

### 6. Ratios ou pixels : que choisir en V0 ?

Ratios. Ils sont portables, déjà proches des métriques runtime existantes et indépendants du tile size.

### 7. Value object ou champs plats ?

Value object dédié. Cela évite de gonfler `ProjectElementShadowConfig` et `MapPlacedElementShadowOverride` avec quatre champs supplémentaires non groupés.

### 8. Comment éviter de casser les anciens projets ?

Ajouter des champs optionnels, garder `footprint == null` comme comportement actuel, encoder seulement les valeurs présentes, ne pas exiger de migration immédiate.

### 9. Où mettre la géométrie commune runtime/editor ?

Dans une opération pure `map_core`, sans Flutter ni Flame. Runtime et éditeur fourniront seulement les visual metrics.

### 10. Quels lots faire ensuite ?

Shadow-27 à Shadow-33 selon la roadmap ci-dessus : value object, merge/geometry core, intégration runtime, intégration editor, UI élément, UI instance, fixtures/polish.

## 18. Commandes lancées

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "class ProjectElementShadowConfig|class MapPlacedElementShadowOverride|ShadowOverrideMode|resolveShadowConfig" packages/map_core/lib/src
rg -n "StaticPlacedElementShadowRuntimeMetrics|staticPlacedElementShadowAnchorFromMetrics|resolveStaticPlacedElementShadow" packages/map_runtime/lib/src/shadow
rg -n "buildEditorStaticShadowPreviewInstructions|EditorStaticShadowPreviewInstruction" packages/map_editor/lib/src/application/shadow
rg -n "PlacedElementShadowOverrideSection|placed_element_shadow_tuning_presets" packages/map_editor/lib/src
rg -n "build_runner|freezed|JsonSerializable|part .*freezed|part .*g.dart" packages/map_core/lib/src/models --glob '!*.freezed.dart' --glob '!*.g.dart'
nl -ba packages/map_core/lib/src/models/shadow.dart | sed -n '1,280p'
nl -ba packages/map_core/lib/src/operations/shadow_config_resolver.dart | sed -n '1,260p'
nl -ba packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart | sed -n '1,220p'
nl -ba packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart | sed -n '1,230p'
nl -ba packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart | sed -n '1,230p'
nl -ba packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart | sed -n '1,180p'
nl -ba packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart | sed -n '1,150p'
nl -ba packages/map_runtime/lib/src/shadow/shadow_runtime_resolver.dart | sed -n '1,180p'
nl -ba packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart | sed -n '1,210p'
nl -ba packages/map_editor/lib/src/application/shadow/placed_element_shadow_tuning_presets.dart | sed -n '1,130p'
nl -ba packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart | sed -n '150,460p'
rg -n "ProjectElementShadowConfigJsonConverter|MapPlacedElementShadowOverrideJsonConverter|shadowOverride|shadow" packages/map_core/lib/src/models/project_manifest.dart packages/map_core/lib/src/models/map_data.dart
rg -n "footprint|anchor|visualWidth|baseShadowWidth|baseWidthMultiplier|anchorXRatio|shadowFootprint" reports/shadows packages/map_runtime/lib/src/shadow packages/map_editor/lib/src/application/shadow packages/map_core/lib/src
ls reports/shadows | tail -20
git diff --check
git diff --stat
git status --short --untracked-files=all
```

## 19. Résultats des audits

### `git status --short --untracked-files=all` initial

```text
aucune sortie
```

### `find .. -name AGENTS.md -print`

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Le fichier applicable au repo courant est `../pokemonProject/AGENTS.md`.

### Modèles Shadow

Commande :

```bash
rg -n "class ProjectElementShadowConfig|class MapPlacedElementShadowOverride|ShadowOverrideMode|resolveShadowConfig" packages/map_core/lib/src
```

Résultat :

```text
packages/map_core/lib/src/models/shadow.dart:33:enum ShadowOverrideMode {
packages/map_core/lib/src/models/shadow.dart:120:final class ProjectElementShadowConfig {
packages/map_core/lib/src/models/shadow.dart:190:final class MapPlacedElementShadowOverride {
packages/map_core/lib/src/models/shadow.dart:192:    this.mode = ShadowOverrideMode.inherit,
packages/map_core/lib/src/models/shadow.dart:210:    if (mode != ShadowOverrideMode.custom &&
packages/map_core/lib/src/models/shadow.dart:219:  final ShadowOverrideMode mode;
packages/map_core/lib/src/models/shadow.dart:221:  /// Optional profile replacement for [ShadowOverrideMode.custom].
packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart:51:ShadowOverrideMode _decodeShadowOverrideMode(Map<String, Object?> json) {
packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart:53:    return ShadowOverrideMode.inherit;
packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart:63:  for (final mode in ShadowOverrideMode.values) {
packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart:110:    mode: _decodeShadowOverrideMode(map),
packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart:144:class MapPlacedElementShadowOverrideJsonConverter
packages/map_core/lib/src/operations/shadow_config_resolver.dart:150:ShadowConfigResolution resolveShadowConfig({
packages/map_core/lib/src/operations/shadow_config_resolver.dart:155:  final overrideMode = placedOverride?.mode ?? ShadowOverrideMode.inherit;
packages/map_core/lib/src/operations/shadow_config_resolver.dart:156:  if (overrideMode == ShadowOverrideMode.disabled) {
packages/map_core/lib/src/operations/shadow_config_resolver.dart:165:  final isCustomOverride = overrideMode == ShadowOverrideMode.custom;
packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart:136:class ProjectElementShadowConfigJsonConverter
```

### Runtime static shadow

Commande :

```bash
rg -n "StaticPlacedElementShadowRuntimeMetrics|staticPlacedElementShadowAnchorFromMetrics|resolveStaticPlacedElementShadow" packages/map_runtime/lib/src/shadow
```

Résultat :

```text
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart:23:  final StaticPlacedElementShadowRuntimeMetrics metrics;
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart:75:    instructions: resolveStaticPlacedElementShadowRuntimeInstructions(inputs),
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:53:        metrics: StaticPlacedElementShadowRuntimeMetrics(
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:11:final class StaticPlacedElementShadowRuntimeMetrics {
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:12:  StaticPlacedElementShadowRuntimeMetrics({
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:44:      other is StaticPlacedElementShadowRuntimeMetrics &&
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:75:  final StaticPlacedElementShadowRuntimeMetrics metrics;
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:91:ShadowRuntimeAnchor staticPlacedElementShadowAnchorFromMetrics(
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:92:  StaticPlacedElementShadowRuntimeMetrics metrics,
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:103:    resolveStaticPlacedElementShadowRuntimeInstruction(
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:125:      anchor: staticPlacedElementShadowAnchorFromMetrics(input.metrics),
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:131:    resolveStaticPlacedElementShadowRuntimeInstructions(
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:137:        resolveStaticPlacedElementShadowRuntimeInstruction(input);
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:148:      'StaticPlacedElementShadowRuntimeMetrics.$name must be finite',
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:157:      'StaticPlacedElementShadowRuntimeMetrics.$name must be greater than 0',
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:166:      'StaticPlacedElementShadowRuntimeMetrics.$name must be between 0 and 1',
```

### Editor static preview

Commande :

```bash
rg -n "buildEditorStaticShadowPreviewInstructions|EditorStaticShadowPreviewInstruction" packages/map_editor/lib/src/application/shadow
```

Résultat :

```text
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart:3:final class EditorStaticShadowPreviewInstruction {
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart:4:  const EditorStaticShadowPreviewInstruction({
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart:29:      other is EditorStaticShadowPreviewInstruction &&
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart:54:List<EditorStaticShadowPreviewInstruction>
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart:55:    buildEditorStaticShadowPreviewInstructions({
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart:66:    return const <EditorStaticShadowPreviewInstruction>[];
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart:77:    return const <EditorStaticShadowPreviewInstruction>[];
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart:80:  final instructions = <EditorStaticShadowPreviewInstruction>[];
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart:121:      EditorStaticShadowPreviewInstruction(
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart:135:  return List<EditorStaticShadowPreviewInstruction>.unmodifiable(instructions);
```

### Instance override UI / presets

Commande :

```bash
rg -n "PlacedElementShadowOverrideSection|placed_element_shadow_tuning_presets" packages/map_editor/lib/src
```

Résultat :

```text
packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_instances_section.dart:320:                PlacedElementShadowOverrideSection(
packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart:8:import 'package:map_editor/src/application/shadow/placed_element_shadow_tuning_presets.dart';
packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart:11:class PlacedElementShadowOverrideSection extends StatefulWidget {
packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart:12:  const PlacedElementShadowOverrideSection({
packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart:30:  State<PlacedElementShadowOverrideSection> createState() =>
packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart:31:      _PlacedElementShadowOverrideSectionState();
packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart:34:class _PlacedElementShadowOverrideSectionState
packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart:35:    extends State<PlacedElementShadowOverrideSection> {
packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart:56:  void didUpdateWidget(covariant PlacedElementShadowOverrideSection oldWidget) {
```

### Freezed / JsonSerializable source-only audit

Commande :

```bash
rg -n "build_runner|freezed|JsonSerializable|part .*freezed|part .*g.dart" packages/map_core/lib/src/models --glob '!*.freezed.dart' --glob '!*.g.dart'
```

Résultat utile : plusieurs modèles `map_core` sont Freezed/JsonSerializable, notamment `project_manifest.dart` et `map_data.dart`. Cependant `ProjectElementShadowConfig` et `MapPlacedElementShadowOverride` sont des classes manuelles dans `shadow.dart`, avec converters manuels déjà attachés aux modèles Freezed.

## 20. git status initial

```text
aucune sortie
```

## 21. git status final

```text
?? reports/shadows/shadow_lot_26_footprint_anchor_model_decision.md
```

## 22. git diff --stat

```text
aucune sortie
```

Explication : le seul fichier du lot est un fichier non suivi nouvellement créé. `git diff --stat` ne l'affiche pas tant qu'il n'est pas indexé. Le `git status final` ci-dessus identifie le fichier créé par Shadow-26.

### `git diff --name-status`

```text
aucune sortie
```

Même raison : le rapport est non suivi.

### `git diff --check`

```text
aucune sortie
```

## 23. Auto-review

- Ai-je modifié du code de production ? non.
- Ai-je créé seulement le rapport de décision ? oui.
- Ai-je choisi où placer le footprint par défaut ? oui : `ProjectElementShadowConfig`.
- Ai-je choisi comment gérer l'override instance ? oui : `MapPlacedElementShadowOverride` en mode `custom`.
- Ai-je choisi ratios vs pixels ? oui : ratios en V0.
- Ai-je traité la compatibilité JSON ? oui.
- Ai-je proposé une roadmap de micro-lots ? oui.
- Ai-je évité de créer une fausse lumière globale ? oui.

## 24. Regard critique sur le prompt

Le prompt est très bien cadré pour un lot design-only. La recommandation attendue était globalement juste, avec une nuance importante issue de l'audit : les ratios existent déjà côté runtime sous forme de métriques transitoires. Le travail futur n'est donc pas d'inventer la géométrie, mais de la rendre authorable, persistable, testée et partagée.

Le seul point à surveiller pour Shadow-27 est le nommage du value object. Il doit être assez précis pour ne pas être confondu avec les footprints collision existants. `StaticShadowFootprintConfig` est plus explicite que `ShadowFootprint`.
