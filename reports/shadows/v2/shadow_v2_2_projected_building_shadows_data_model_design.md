# ShadowV2-2 — Projected Building Shadows Data Model Design

## 1. Résumé exécutif

ShadowV2-2 conçoit le modèle de données futur des ombres projetées de bâtiments V2.

Ce lot ne modifie aucun code, aucune donnée, aucun codec et aucun fichier Selbrume.

Décision recommandée:

- Ne pas étendre directement `ProjectElementShadowConfig` avec toute la V2.
- Créer un modèle dédié `ProjectElementProjectedBuildingShadowConfig`.
- Ajouter un catalogue dédié de presets artistiques: `ProjectBuildingShadowPresetCatalog`.
- Garder les overrides V2 séparés de `MapPlacedElementShadowOverride` pour éviter de complexifier V1.
- Préparer time-of-day conceptuellement via un champ mode extensible, mais ne pas implémenter les courbes maintenant.

Design recommandé: Design C comme base, avec extension contrôlée vers Design D plus tard.

Raison:

- séparation claire V1/V2;
- authoring explicite;
- presets no-code;
- compatibilité future time-of-day;
- pas de retour de `genericProjection` automatique;
- migration additive et optionnelle.

## 2. Objectif du lot

Question centrale:

```text
Quel modèle de données permet d'authorer des ombres projetées de bâtiments propres,
sans polluer ProjectElementShadowConfig,
sans casser V1,
et sans réintroduire une automaticité dangereuse ?
```

Réponse courte:

```text
Un modèle V2 dédié, optional et authoré:
ProjectBuildingShadowPresetCatalog + ProjectElementProjectedBuildingShadowConfig.
```

## 3. Rappel ShadowV2-1

ShadowV2-1 a fixé:

- North Star Pokémon-like;
- bâtiments comme cible principale;
- authoring explicite;
- preview éditeur obligatoire;
- runtime consommateur;
- no `genericProjection` automatique;
- direction recommandée: hybrid authoring.

ShadowV2-2 précise la partie données.

## 4. État actuel V1 à préserver

V1 stable:

- runtime auto-apply absent;
- policy auto-shadow durcie;
- `buildingLarge` seul kind auto-safe;
- `genericProjection = 0` dans Selbrume baseline;
- `contactLedge = 10`;
- baseline visuelle Selbrume V1 présente;
- contact ledges V1 retunées.

V1 ne doit pas être réécrit pour faire entrer V2.

## 5. Fichiers audités

Tous les fichiers demandés existent:

```text
present	reports/shadows/v2/shadow_v2_1_projected_building_shadows_product_spec_art_direction.md
present	reports/shadows/shadow_lot_68_shadow_recovery_closure_projected_building_shadows_v2_roadmap.md
present	reports/shadows/shadow_lot_67_selbrume_shadow_golden_baseline_implementation.md
present	reports/shadows/shadow_lot_66_selbrume_shadow_golden_baseline_design.md
present	packages/map_core/lib/src/models/shadow.dart
present	packages/map_core/lib/src/models/shadow_catalog.dart
present	packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart
present	packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart
present	packages/map_core/lib/src/operations/static_shadow_footprint_config_json_codec.dart
present	packages/map_core/lib/src/operations/project_shadow_catalog_json_codec.dart
present	packages/map_core/lib/src/operations/project_shadow_profile_json_codec.dart
present	packages/map_core/lib/src/operations/shadow_config_resolver.dart
present	packages/map_core/lib/src/operations/static_shadow_geometry.dart
present	packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
present	packages/map_core/lib/src/operations/static_shadow_family_projection.dart
present	packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart
present	packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
present	packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
present	packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
present	packages/map_core/lib/src/models/project_manifest.dart
present	packages/map_core/lib/src/operations/project_json_migrations.dart
present	packages/map_core/lib/src/operations/project_manifest_shadow_catalog_operations.dart
```

Symboles V1 repérés:

```text
packages/map_core/lib/src/models/shadow_catalog.dart:27:final class ProjectShadowCatalog {
packages/map_core/lib/src/models/shadow.dart:18:enum ShadowRenderPass {
packages/map_core/lib/src/models/shadow.dart:27:enum ShadowSoftnessMode {
packages/map_core/lib/src/models/shadow.dart:44:enum StaticShadowFamily {
packages/map_core/lib/src/models/shadow.dart:45:  genericProjection,
packages/map_core/lib/src/models/shadow.dart:53:final class StaticShadowFootprintConfig {
packages/map_core/lib/src/models/shadow.dart:107:final class ProjectShadowProfile {
packages/map_core/lib/src/models/shadow.dart:179:final class ProjectElementShadowConfig {
packages/map_core/lib/src/models/shadow.dart:257:final class MapPlacedElementShadowOverride {
```

Project structure:

```text
packages/map_core/lib/src/models/project_manifest.dart:133:    @Default(ProjectShadowCatalog.empty())
packages/map_core/lib/src/models/project_manifest.dart:134:    @ProjectShadowCatalogJsonConverter()
packages/map_core/lib/src/models/project_manifest.dart:135:    ProjectShadowCatalog shadowCatalog,
```

Runtime projection support exists, but must not become automatic:

```text
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart:8:  projectedPolygon,
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:20:      case ShadowRuntimeShapeKind.projectedPolygon:
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:175:    shape: ShadowRuntimeShapeKind.projectedPolygon,
```

## 6. Questions de design obligatoires

### 6.1 Faut-il étendre `ProjectElementShadowConfig` ?

Décision: non pour le coeur V2.

Évaluation:

- Simplicité: bonne au départ, mauvaise à moyen terme.
- Compatibilité JSON: additive possible, mais mélange de concepts.
- Risque modèle: élevé; V1 contient déjà casts/profile/family/footprint/numeric overrides.
- Confusion V1/V2: élevée, surtout contact ledge vs projected building.
- Impact resolver: risquerait de pousser V2 dans `resolveShadowConfig`, alors que V2 mérite un resolver dédié.
- Impact editor: UI pourrait mélanger "ombre statique V1" et "ombre projetée bâtiment V2".

Conclusion:

`ProjectElementShadowConfig` doit rester V1/static shadow. V2 doit vivre ailleurs.

### 6.2 Faut-il créer un nouveau modèle dédié ?

Décision: oui.

Nom recommandé:

```text
ProjectElementProjectedBuildingShadowConfig
```

Rôle:

- activation explicite;
- référence preset;
- anchor;
- offset local;
- overrides locaux limités;
- future time-of-day mode par référence ou override.

Avantages:

- clarté métier;
- séparation V1/V2;
- diagnostics dédiés;
- possibilité de ne pas charger V2 côté runtime V1;
- compat time-of-day plus propre.

Coût:

- nouveau champ optionnel dans les éléments;
- nouveaux tests JSON;
- futur codec.

### 6.3 Faut-il créer un catalogue de presets ?

Décision: oui, catalogue dédié recommandé.

Nom recommandé:

```text
ProjectBuildingShadowPresetCatalog
```

Pourquoi pas `ProjectShadowCatalog` ?

- `ProjectShadowCatalog` contient des profiles techniques V1.
- Les presets V2 sont des objets artistiques no-code.
- Mélanger profiles et presets rendrait l'UI confuse.

Structure future:

```text
ProjectManifest.projectedBuildingShadowCatalog
```

ou nom plus court:

```text
ProjectManifest.buildingShadowCatalog
```

Recommandation de nom:

```text
ProjectBuildingShadowPresetCatalog
```

Plus explicite, moins risqué.

### 6.4 Où vivent les overrides instance ?

Décision: ne pas réutiliser `MapPlacedElementShadowOverride` pour V2.

Nom futur possible:

```text
MapPlacedElementProjectedBuildingShadowOverride
```

Mais ne pas l'implémenter dans le premier modèle si pas nécessaire.

Approche recommandée:

- V2 initial: authoring par élément uniquement.
- V2 optional/future: override d'instance dédié.

Pourquoi:

- V1 override est déjà complexe.
- Les overrides d'instance V2 peuvent rendre l'UI lourde.
- Le POC doit d'abord prouver l'asset-level authoring.

### 6.5 Comment préparer le cycle jour/nuit ?

Décision: prévoir conceptuellement, pas de courbes dans V2 initial.

Approche:

- champ `timeOfDay.mode` dans preset;
- valeur initiale: `fixed`;
- futures valeurs possibles: `globalLight`, `presetCurve`;
- pas de courbe détaillée dans les premiers objets V0.

Raison:

- éviter premature complexity;
- réserver une extension JSON;
- ne pas bloquer V2 sur cycle jour/nuit.

## 7. Candidate model designs A/B/C/D

### Design A — Extension minimale de `ProjectElementShadowConfig`

Concept:

```dart
ProjectElementShadowConfig(
  castsShadow: true,
  family: StaticShadowFamily.building,
  projectedBuildingShadow: ProjectedBuildingShadowConfig(...),
)
```

Avantages:

- peu de nouveaux champs racine;
- réutilise le modèle d'ombre existant;
- intégration rapide.

Inconvénients:

- mélange V1 et V2;
- surcharge `ProjectElementShadowConfig`;
- risque de confondre contact ledge et projection;
- pousse le resolver V1 vers V2;
- danger de `genericProjection` déguisé.

Impact JSON:

- additive mais ambigu.

Impact tests:

- beaucoup de tests existants à élargir.

Risque:

- élevé.

Décision:

- non recommandé.

### Design B — Modèle dédié par élément

Concept:

```dart
ProjectElementProjectedBuildingShadowConfig(
  enabled: true,
  presetId: 'short-afternoon-building-shadow',
  anchor: ...,
  localOverrides: ...
)
```

Puis dans l'élément:

```dart
projectedBuildingShadow: ProjectElementProjectedBuildingShadowConfig?
```

Avantages:

- séparation claire;
- activation explicite;
- pas de pollution V1;
- facile à masquer en UI si absent.

Inconvénients:

- sans preset catalog, risque de dupliquer params par élément;
- pas idéal pour cohérence artistique globale.

Impact JSON:

- champ optionnel par élément.

Impact tests:

- tests model/codec element.

Risque:

- duplication si utilisé seul.

Décision:

- bon composant, mais insuffisant seul.

### Design C — Preset catalog + element ref

Concept:

```dart
ProjectBuildingShadowPreset(
  id,
  name,
  direction,
  length,
  width,
  opacity,
  color,
  anchorPolicy,
  timeOfDayMode
)
```

Et:

```dart
ProjectElementProjectedShadowRef(
  presetId,
  anchor,
  enabled
)
```

Avantages:

- no-code;
- cohérence artistique;
- presets réutilisables;
- séparation V1/V2;
- diagnostics catalog simples;
- compat time-of-day.

Inconvénients:

- nouveau catalogue;
- nouveaux codecs;
- intégration manifest future.

Impact JSON:

- nouveau champ manifest optional + champ élément optional.

Impact tests:

- catalog decode/encode;
- presetId validation;
- legacy absent.

Risque:

- modéré.

Décision:

- recommandé comme base.

### Design D — Hybrid preset + optional shadow asset

Concept:

```dart
ProjectBuildingShadowPreset(
  kind: parametric | assetDriven,
  parametric: ...,
  assetRef: ...
)
```

Avantages:

- contrôle artistique maximal à terme;
- compatible North Star;
- permet assets pour cas spéciaux;
- garde parametric pour POC rapide.

Inconvénients:

- plus de surface modèle;
- asset management;
- diagnostics asset;
- time-of-day plus difficile pour asset-driven.

Impact JSON:

- union/discriminated object plus complexe.

Impact tests:

- kind validation;
- parametric required when kind parametric;
- assetRef required when kind assetDriven.

Risque:

- élevé si livré trop tôt.

Décision:

- direction future, pas V0 complet.

## 8. Décision recommandée

Choix:

```text
Design C maintenant, avec extensibilité contrôlée vers Design D.
```

Modèles futurs recommandés:

```text
ProjectBuildingShadowPresetCatalog
ProjectBuildingShadowPreset
ProjectBuildingShadowParametricShape
ProjectElementProjectedBuildingShadowConfig
ProjectBuildingShadowAnchorConfig
ProjectBuildingShadowLocalOverrides
```

À différer:

```text
ProjectBuildingShadowAssetSpec
MapPlacedElementProjectedBuildingShadowOverride
ProjectBuildingShadowTimeCurve
```

Position dans les données:

```text
ProjectManifest.projectedBuildingShadowCatalog // optional/additive
ProjectElementEntry.projectedBuildingShadow // optional/additive
```

Règle runtime:

```text
Pas de projected shadow si ProjectElementEntry.projectedBuildingShadow est null ou disabled.
```

## 9. Paramètres V2 required / optional / future

### V2 required

Preset:

- `id`
- `name`
- `kind = parametric`
- `directionX`
- `directionY`
- `lengthRatio`
- `nearWidthRatio`
- `farWidthRatio`
- `opacity`
- `colorHexRgb`
- `timeOfDay.mode = fixed`

Element config:

- `enabled`
- `presetId`
- `anchorXRatio`
- `anchorYRatio`
- `originOffsetX`
- `originOffsetY`

### V2 optional

- `renderPass`
- `softnessMode` if limited to existing hard edge first
- `edgeStyle`
- `layerOrderHint`
- `localOpacityMultiplier`
- `localLengthMultiplier`
- `localWidthMultiplier`

Recommendation:

Do not include all optional fields in first implementation. Add only if a POC proves need.

### Out of V2 initial

- `clampToGround`
- `cropPolicy`
- advanced `layerOrderHint`
- asset-driven kind
- per-instance override

### Future time-of-day

- `timeOfDayEnabled`
- `morningDirection`
- `noonDirection`
- `eveningDirection`
- `lengthMultiplierCurve`
- `opacityMultiplierCurve`
- `colorTintCurve`
- `nightBehavior`

Initial model should reserve `timeOfDay.mode`, but not implement curves.

## 10. Draft JSON non implémenté

Ce JSON est un draft de design, pas un contrat implémenté.

```json
{
  "projectedBuildingShadowCatalog": {
    "presets": [
      {
        "id": "short-west-building-shadow",
        "name": "Short west building shadow",
        "kind": "parametric",
        "direction": {
          "x": -0.55,
          "y": 0.35
        },
        "lengthRatio": 0.28,
        "nearWidthRatio": 0.85,
        "farWidthRatio": 0.75,
        "opacity": 0.18,
        "colorHexRgb": "000000",
        "timeOfDay": {
          "mode": "fixed"
        }
      },
      {
        "id": "medium-east-building-shadow",
        "name": "Medium east building shadow",
        "kind": "parametric",
        "direction": {
          "x": 0.45,
          "y": 0.30
        },
        "lengthRatio": 0.40,
        "nearWidthRatio": 0.90,
        "farWidthRatio": 0.70,
        "opacity": 0.16,
        "colorHexRgb": "000000",
        "timeOfDay": {
          "mode": "fixed"
        }
      }
    ]
  },
  "elements": [
    {
      "id": "house_01",
      "projectedBuildingShadow": {
        "enabled": true,
        "presetId": "short-west-building-shadow",
        "anchor": {
          "xRatio": 0.5,
          "yRatio": 0.98
        },
        "localOffset": {
          "x": 0,
          "y": 0
        }
      }
    }
  ]
}
```

Future asset-driven extension, not V2 initial:

```json
{
  "id": "painted-pokemon-center-shadow",
  "name": "Painted Pokémon Center shadow",
  "kind": "assetDriven",
  "assetRef": {
    "path": "assets/shadows/pokemon_center_shadow.png",
    "anchor": {
      "xRatio": 0.5,
      "yRatio": 0.98
    }
  },
  "timeOfDay": {
    "mode": "fixed"
  }
}
```

## 11. Relation avec V1 contact ledge

Règles:

- contact ledge V1 reste stable;
- projected shadow V2 est séparé;
- V2 projected shadow désactivée par défaut;
- V1 contact ledge reste inchangée;
- coexistence uniquement explicitement authorée;
- éviter double shadow trop visible;
- renderer order à définir plus tard;
- V2 ne doit pas réactiver `genericProjection`.

Recommandation:

```text
Un élément peut avoir contact ledge V1 et projected shadow V2 seulement si l'éditeur l'autorise explicitement.
```

Un futur POC doit décider:

- contact ledge conservée;
- contact ledge réduite;
- contact ledge masquée quand V2 active.

## 12. Validation / invariants futurs

### Validation model

- `id` non vide;
- `name` non vide;
- `opacity` entre 0 et 1;
- `colorHexRgb` RGB 6 chars;
- direction non zéro;
- direction finite;
- `lengthRatio >= 0`;
- width ratios `> 0`;
- anchor ratios entre 0 et 1;
- offsets finite;
- `kind` connu;
- `timeOfDay.mode` connu.

### Validation catalog

- preset ids uniques;
- no duplicate names warning possible;
- `presetId` element existe dans catalog;
- parametric fields présents quand `kind=parametric`;
- asset fields absents ou ignorés en V2 initial.

### Diagnostics editor

- preset manquant;
- direction invalide;
- anchor hors bornes;
- opacity trop forte;
- V2 active sur élément non-bâtiment;
- coexistence V1/V2 potentiellement trop visible;
- asset shadow missing future.

### Runtime fallback

- Si preset manquant: ne pas rendre l'ombre V2, diagnostic/log testable.
- Si valeur invalide: ne pas rendre l'ombre V2.
- Ne jamais fallback vers `genericProjection`.
- Ne jamais créer un preset implicite.

## 13. Migration / compatibilité

Décision:

```text
V2 additive et optional.
Aucun projet existant ne gagne une ombre V2 automatiquement.
```

Compat:

- old projects without `projectedBuildingShadowCatalog` decode as empty/default;
- old elements without `projectedBuildingShadow` decode as null;
- no migration required for V2 absent;
- project size increases only when V2 used;
- fixtures unchanged until V2 tests;
- no build_runner until actual model implementation lot;
- project_json_migrations only if schema version requires explicit addition later.

Recommandation:

Commencer avec decode-defaults sans migration si possible. N'ajouter migration que si le repo exige versioning explicite.

## 14. Editor UX implications

V2 initial:

- section séparée "Ombre projetée bâtiment";
- visible pour éléments compatibles ou activable manuellement;
- presets lisibles;
- preview obligatoire;
- sliders limités;
- bouton reset;
- badge "V2" ou "experimental" possible;
- aucun JSON manuel.

V2 future:

- override par instance;
- preview matin/midi/soir;
- asset-driven shadow picker;
- diagnostics de double shadow;
- batch apply après visual review.

Ne pas exposer:

- `genericProjection`;
- `projectedPolygon`;
- `StaticShadowFamily`;
- IDs techniques sans label.

## 15. Runtime implications

V2 future implique:

- resolver dédié, pas extension opaque du resolver V1;
- instruction runtime V2 ou factory claire vers instruction existante;
- render pass explicite;
- ordering avec terrain/path/surface/elements/actors;
- culling éventuel;
- no manifest mutation;
- fallback no-shadow si preset manquant;
- diagnostics si asset shadow manquant future;
- aucun runtime auto-apply.

Point sensible:

Le renderer supporte déjà `projectedPolygon`. V2 peut éventuellement l'utiliser comme primitive de rendu, mais seulement depuis données authorées V2, jamais depuis default generic.

## 16. Screenshot / baseline implications

Règles:

- Chaque POC V2 relance le harness.
- Baseline V1 Selbrume n'est pas remplacée sans validation.
- Créer une baseline V2 séparée si POC validé.
- Comparer before/after pour un bâtiment puis trois bâtiments.
- Time-of-day aura ses propres captures matin/midi/soir plus tard.

Captures futures:

- baseline V1 current;
- V2 POC one building;
- V2 POC three buildings;
- time-of-day morning/noon/evening later.

## 17. Roadmap micro-lots

### ShadowV2-3 — Projected Building Shadow Data Model JSON Characterization

Objectif: caractériser JSON V1 avant extension.

Fichiers probablement touchés:

- `packages/map_core/test/shadow/**`
- rapport.

Ce qui est interdit:

- ajouter modèle;
- migration;
- runtime;
- editor.

Tests attendus:

- `cd packages/map_core && dart test test/shadow`

Visual gate attendu:

- Aucun.

Critère de validation:

- legacy shadow JSON stable et documenté avant V2.

Risque:

- sous-estimer compat existante.

Pourquoi ce lot vient maintenant:

- avant toute modification de modèle.

### ShadowV2-4 — Projected Building Shadow Value Objects V0

Objectif: ajouter objets purs V2.

Fichiers probablement touchés:

- `packages/map_core/lib/src/models/**`
- tests shadow.

Ce qui est interdit:

- codecs JSON externes si non inclus;
- runtime;
- editor;
- Selbrume.

Tests attendus:

- validation/equality/copy.

Visual gate attendu:

- Aucun.

Critère de validation:

- objets purs, aucun comportement runtime.

Risque:

- trop de champs dès V0.

Pourquoi ce lot vient maintenant:

- base type-safe.

### ShadowV2-5 — Projected Building Shadow Preset Model V0

Objectif: catalogue/preset V2.

Fichiers probablement touchés:

- `map_core` models/tests.

Ce qui est interdit:

- integration manifest si non prête;
- runtime.

Tests attendus:

- ids uniques;
- validation ranges;
- empty catalog.

Visual gate attendu:

- Aucun.

Critère de validation:

- catalog V2 clair et optionnel.

Risque:

- mélange avec `ProjectShadowCatalog`.

Pourquoi ce lot vient maintenant:

- presets nécessaires au no-code.

### ShadowV2-6 — Projected Building Shadow JSON Codecs V0

Objectif: encode/decode V2.

Fichiers probablement touchés:

- `packages/map_core/lib/src/operations/*json_codec.dart`
- tests.

Ce qui est interdit:

- migration globale;
- auto defaults;
- runtime.

Tests attendus:

- decode absent as null/empty;
- encode stable;
- invalid JSON errors.

Visual gate attendu:

- Aucun.

Critère de validation:

- JSON additive et stable.

Risque:

- compat project fixtures.

Pourquoi ce lot vient maintenant:

- après objets.

### ShadowV2-7 — Manifest Integration Design Gate

Objectif: décider champ manifest exact avant intégration.

Fichiers probablement touchés:

- rapport design.

Ce qui est interdit:

- code.

Tests attendus:

- Aucun.

Visual gate attendu:

- Aucun.

Critère de validation:

- nom champ manifest validé.

Risque:

- intégrer trop tôt.

Pourquoi ce lot vient maintenant:

- éviter churn manifest.

### ShadowV2-8 — Manifest Integration V0

Objectif: ajouter catalog V2 optional au manifest.

Fichiers probablement touchés:

- `ProjectManifest`;
- generated files si requis;
- codecs/tests.

Ce qui est interdit:

- Selbrume mutation;
- runtime render;
- editor UI.

Tests attendus:

- `dart test test/shadow`;
- build_runner seulement si nécessaire et explicitement dans le lot.

Visual gate attendu:

- Aucun.

Critère de validation:

- old projects decode unchanged.

Risque:

- generated-file churn.

Pourquoi ce lot vient maintenant:

- après design gate.

### ShadowV2-9 — Editor Preview Design Gate

Objectif: design no-code preview.

Fichiers probablement touchés:

- rapport design.

Ce qui est interdit:

- code UI.

Tests attendus:

- Aucun.

Visual gate attendu:

- wireframe/description.

Critère de validation:

- UX validée.

Risque:

- jargon technique.

Pourquoi ce lot vient maintenant:

- avant editor.

### ShadowV2-10 — Editor Preview POC One Building

Objectif: preview une ombre V2 authorée.

Fichiers probablement touchés:

- `packages/map_editor/**`
- tests application shadow.

Ce qui est interdit:

- runtime renderer;
- auto apply;
- Selbrume global.

Tests attendus:

- `flutter test test/application/shadow`

Visual gate attendu:

- screenshot editor preview si possible.

Critère de validation:

- preview correspond aux params.

Risque:

- couplage runtime/editor.

Pourquoi ce lot vient maintenant:

- authoring avant runtime.

### ShadowV2-11 — Runtime Instruction Design Gate

Objectif: définir instruction runtime V2.

Fichiers probablement touchés:

- rapport design.

Ce qui est interdit:

- code runtime.

Tests attendus:

- Aucun.

Visual gate attendu:

- critères screenshot.

Critère de validation:

- pas de confusion avec genericProjection.

Risque:

- réutiliser primitive existante sans garde-fou.

Pourquoi ce lot vient maintenant:

- avant runtime POC.

### ShadowV2-12 — Runtime POC One Building

Objectif: rendre une ombre V2 authorée sur un bâtiment.

Fichiers probablement touchés:

- `packages/map_runtime/**`
- tests shadow.

Ce qui est interdit:

- runtime auto apply;
- data mutation;
- generic default.

Tests attendus:

- runtime shadow tests;
- harness.

Visual gate attendu:

- before/after one building.

Critère de validation:

- seulement données authorées rendent l'ombre.

Risque:

- render order.

Pourquoi ce lot vient maintenant:

- après modèles + preview.

### ShadowV2-13 — Selbrume 3 Buildings Authoring POC

Objectif: POC sur trois bâtiments Selbrume.

Fichiers probablement touchés:

- données Selbrume seulement avec autorisation explicite;
- rapports/screenshots.

Ce qui est interdit:

- global backfill;
- petits props;
- arbres.

Tests attendus:

- harness baseline;
- runtime bundle.

Visual gate attendu:

- overview + 3 captures.

Critère de validation:

- rendu accepté visuellement.

Risque:

- trop spécifique.

Pourquoi ce lot vient maintenant:

- validation terrain.

### ShadowV2-14 — Screenshot Baseline V2

Objectif: baseline V2.

Fichiers probablement touchés:

- `reports/shadows/baselines/**`
- harness tool si besoin.

Ce qui est interdit:

- CI fragile;
- overwrite V1 sans validation.

Tests attendus:

- harness compare.

Visual gate attendu:

- V2 baseline review.

Critère de validation:

- captures V2 reproductibles.

Risque:

- figer trop tôt.

Pourquoi ce lot vient maintenant:

- après POC accepté.

### ShadowV2-15 — Time-of-Day Parameter Design

Objectif: design time-of-day.

Fichiers probablement touchés:

- rapport design.

Ce qui est interdit:

- runtime cycle integration.

Tests attendus:

- Aucun.

Visual gate attendu:

- scenarios matin/midi/soir.

Critère de validation:

- modèle compatible sans rewrite.

Risque:

- sur-concevoir.

Pourquoi ce lot vient maintenant:

- après V2 visuelle validée.

## 18. Recommandation finale

Design recommandé:

```text
Design C maintenant:
ProjectBuildingShadowPresetCatalog + ProjectElementProjectedBuildingShadowConfig.
Extensible vers Design D plus tard.
```

Pourquoi:

- séparation V1/V2;
- authoring explicite;
- presets no-code;
- validation catalog claire;
- time-of-day préparé;
- pas de `genericProjection` automatique.

Prochain lot recommandé:

```text
ShadowV2-3 — Projected Building Shadow Data Model JSON Characterization / Compatibility Prep
```

Justification:

Avant d'ajouter des objets, il faut verrouiller le comportement JSON V1 existant et les attentes compat. Cela réduit le risque de casser `ProjectElementShadowConfig`, `ProjectShadowCatalog`, overrides et fixtures.

## 19. Tests / commandes lancées

Commandes:

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
rg -n "applyElementAutoShadowPolicyToProject" packages/map_runtime packages/map_editor packages/map_core
rg -n "_autoShadowKindIsArtisticallySafe|ElementAutoShadowSuggestionKind" packages/map_core/lib/src/operations/element_auto_shadow_policy.dart
test -d reports/shadows/baselines/selbrume_shadow_v1
test -f reports/shadows/baselines/selbrume_shadow_v1/baseline_manifest.json
find reports/shadows/baselines/selbrume_shadow_v1 -maxdepth 1 -type f -name "*.png" | sort
rg -n "ProjectElementShadowConfig|MapPlacedElementShadowOverride|ProjectShadowCatalog|ProjectShadowProfile" packages/map_core/lib/src
```

No full test suite: design-only lot.

## 20. Résultats

### git status initial

```text
(no output)
```

### AGENTS / design gate

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
765:Before structural changes, read the nearest:
848:1. Brainstorming (`superpowers:brainstorming`) before creative work.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
1096:For creative work such as features, components, behavior changes, or UI:
```

Interprétation: ce lot est design-only et respecte le design gate.

### Runtime auto-apply

```text
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:142:ElementAutoShadowBackfillResult applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:127:  group('applyElementAutoShadowPolicyToProject', () {
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:129:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:154:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:179:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:207:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:232:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:270:      final result = applyElementAutoShadowPolicyToProject(
packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart:431:      final coreResult = applyElementAutoShadowPolicyToProject(project);
packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart:8:        applyElementAutoShadowPolicyToProject;
packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart:13:  return applyElementAutoShadowPolicyToProject(project);
```

Conclusion: aucun appel dans `packages/map_runtime`.

### Policy Shadow V1

```text
6:enum ElementAutoShadowSuggestionKind {
21:  final ElementAutoShadowSuggestionKind kind;
46:  final ElementAutoShadowSuggestionKind? suggestionKind;
124:  if (!_autoShadowKindIsArtisticallySafe(
232:ElementAutoShadowSuggestionKind _classifyElement({
241:    return ElementAutoShadowSuggestionKind.tallThin;
244:    return ElementAutoShadowSuggestionKind.wideLow;
247:    return ElementAutoShadowSuggestionKind.wideLow;
250:    return ElementAutoShadowSuggestionKind.buildingLarge;
253:    return ElementAutoShadowSuggestionKind.wideLow;
256:    return ElementAutoShadowSuggestionKind.smallSquare;
258:  return ElementAutoShadowSuggestionKind.defaultProp;
261:bool _autoShadowKindIsArtisticallySafe(
262:  ElementAutoShadowSuggestionKind kind, {
267:    case ElementAutoShadowSuggestionKind.buildingLarge:
269:    case ElementAutoShadowSuggestionKind.tallThin:
270:    case ElementAutoShadowSuggestionKind.wideLow:
271:    case ElementAutoShadowSuggestionKind.smallSquare:
272:    case ElementAutoShadowSuggestionKind.defaultProp:
279:  ElementAutoShadowSuggestionKind kind,
282:    case ElementAutoShadowSuggestionKind.tallThin:
283:    case ElementAutoShadowSuggestionKind.smallSquare:
285:    case ElementAutoShadowSuggestionKind.buildingLarge:
286:    case ElementAutoShadowSuggestionKind.wideLow:
288:    case ElementAutoShadowSuggestionKind.defaultProp:
344:  ElementAutoShadowSuggestionKind kind,
348:    case ElementAutoShadowSuggestionKind.tallThin:
365:    case ElementAutoShadowSuggestionKind.buildingLarge:
382:    case ElementAutoShadowSuggestionKind.wideLow:
399:    case ElementAutoShadowSuggestionKind.smallSquare:
416:    case ElementAutoShadowSuggestionKind.defaultProp:
436:String _summaryForKind(ElementAutoShadowSuggestionKind kind) {
438:    case ElementAutoShadowSuggestionKind.tallThin:
440:    case ElementAutoShadowSuggestionKind.buildingLarge:
442:    case ElementAutoShadowSuggestionKind.wideLow:
444:    case ElementAutoShadowSuggestionKind.smallSquare:
446:    case ElementAutoShadowSuggestionKind.defaultProp:
460:  ElementAutoShadowSuggestionKind? suggestionKind,
```

Conclusion: `buildingLarge` seul auto-safe; autres kinds non-safe.

### Baseline Selbrume V1

```text
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_01_selbrum_maison_3.png
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_02_selbrum_maison_4.png
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_03_selbrum_maison_1.png
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_04_selbrume_centre_pok_mon.png
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_05_selbrum_maison_7.png
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_06_le_puits.png
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_07_selbrum_maison_4.png
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_08_selbrum_maison_2.png
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_09_selbrum_maison_8.png
reports/shadows/baselines/selbrume_shadow_v1/contact_ledge_10_kiosque_l_gumes.png
reports/shadows/baselines/selbrume_shadow_v1/selbrume_overview.png
```

## 21. git diff --stat

Après création de ce rapport, `git diff --stat` ne montre pas les fichiers non suivis.

```text
(no output)
```

## 22. git diff --name-status

Après création de ce rapport:

```text
(no output)
```

## 23. git diff --check

Après création de ce rapport:

```text
(no output)
```

## 24. git status final

Après création de ce rapport attendu:

```text
?? reports/shadows/v2/shadow_v2_2_projected_building_shadows_data_model_design.md
```

## 25. Risques / réserves

- Les noms de modèles proposés devront être validés avant implémentation.
- Ajouter un catalogue manifest peut nécessiter generated files dans un futur lot.
- Design D asset-driven reste futur; ne pas le livrer trop tôt.
- Time-of-day est préparé, pas spécifié en détail.
- Utiliser `projectedPolygon` comme primitive runtime reste possible, mais seulement via données V2 authorées.

## 26. Auto-critique

La recommandation sépare bien V1 et V2. Le coût est plus élevé qu'une extension directe de `ProjectElementShadowConfig`, mais c'est précisément ce qui évite de recréer une lasagne Shadow. Le prochain lot doit caractériser le JSON existant avant d'ajouter quoi que ce soit.

## 27. Regard critique sur le prompt

Le prompt verrouille correctement le risque principal: coder trop tôt. Il force aussi les questions difficiles: où vit le catalogue, où vivent les overrides, comment éviter un modèle trop large. La contrainte "no codecs" est utile, car les codecs seront le vrai point de compatibilité.

## 28. Prochain lot recommandé

```text
ShadowV2-3 — Projected Building Shadow Data Model JSON Characterization / Compatibility Prep
```

Objectif:

- verrouiller le comportement JSON V1;
- documenter absence V2;
- préparer tests de compat;
- éviter tout changement modèle prématuré.

## 29. Inventaire des fichiers

Créé:

- `reports/shadows/v2/shadow_v2_2_projected_building_shadows_data_model_design.md`

Modifié:

- Aucun.

Supprimé:

- Aucun.

Code modifié:

- Aucun.

Fichiers Selbrume modifiés:

- Aucun.

Generated files:

- Aucun.

Commit:

- Aucun.
