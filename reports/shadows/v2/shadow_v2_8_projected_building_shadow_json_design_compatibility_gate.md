# ShadowV2-8 — Projected Building Shadow JSON Design / Compatibility Gate

## 1. Résumé exécutif

ShadowV2-8 est un gate de design JSON. Aucun code n'a été modifié.

Décisions canoniques recommandées :

- champ root futur : `projectedBuildingShadowCatalog` ;
- forme root : objet catalogue dédié `{ "presets": [...] }` ;
- champ élément futur : `projectedBuildingShadow` ;
- absence du champ root : décoder en catalogue vide ;
- champ root vide : ne pas l'émettre dans `toJson` tant que le catalogue est vide ;
- absence du champ élément : décoder en `null`, aucune ombre projetée V2 ;
- champ élément explicite `null` : accepter au decode comme `null`, mais ne jamais l'émettre au `toJson` ;
- config élément disabled : valide seulement avec `presetId`, `anchor` et `localOffset`, pour préserver l'intention authorée ;
- stratégie codec : codecs manuels externes dans `operations`, sans `build_runner`, sans `toJson/fromJson` sur les modèles purs ;
- stratégie migration : additive, aucune injection de catalogue vide, aucun preset par défaut, aucune ombre V2 créée automatiquement.

## 2. Objectif du lot

Décider comment les modèles ShadowV2 doivent être sérialisés en JSON avant toute implémentation :

- `ProjectedShadowDirection`
- `ProjectedShadowAnchor`
- `ProjectedShadowOffset`
- `ProjectedShadowShapeTuning`
- `ProjectedShadowAppearance`
- `ProjectedShadowTimeOfDayMode`
- `ProjectBuildingShadowPreset`
- `ProjectBuildingShadowPresetCatalog`
- `ProjectElementProjectedBuildingShadowConfig`

## 3. Rappel ShadowV2-7

ShadowV2-7 a introduit `ProjectElementProjectedBuildingShadowConfig`, modèle pur et non branché.

Champs actuels :

```text
enabled
presetId
anchor
localOffset
```

Ce modèle n'est pas encore présent dans `ProjectElementEntry`, n'a aucun codec JSON et ne dépend pas du catalogue.

## 4. État initial du worktree

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Sortie initiale :

```text
```

Interprétation : worktree propre au début de ShadowV2-8.

## 5. Décision AGENTS / design gate

Commandes :

```bash
cd /Users/karim/Project/pokemonProject
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Sortie :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
765:Before structural changes, read the nearest:
848:1. Brainstorming (`superpowers:brainstorming`) before creative work.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
1096:For creative work such as features, components, behavior changes, or UI:
```

Décision :

- ce lot est design-only ;
- le design gate est respecté par la production du présent rapport ;
- aucune implémentation n'est prévue ni effectuée.

## 6. Fichiers audités

Modèles V2 audités :

- `packages/map_core/lib/src/models/projected_building_shadow.dart`
- `packages/map_core/test/shadow_v2/projected_building_shadow_value_objects_test.dart`
- `packages/map_core/test/shadow_v2/projected_building_shadow_preset_test.dart`
- `packages/map_core/test/shadow_v2/projected_building_shadow_preset_catalog_test.dart`
- `packages/map_core/test/shadow_v2/projected_building_shadow_element_config_test.dart`

Conventions JSON auditées :

- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/shadow.dart`
- `packages/map_core/lib/src/models/shadow_catalog.dart`
- `packages/map_core/lib/src/operations/project_shadow_catalog_json_codec.dart`
- `packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart`
- `packages/map_core/lib/src/operations/project_shadow_profile_json_codec.dart`
- `packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart`
- `packages/map_core/lib/src/operations/static_shadow_footprint_config_json_codec.dart`
- `packages/map_core/lib/src/operations/project_json_migrations.dart`
- `packages/map_core/test/shadow/project_manifest_shadow_catalog_json_test.dart`
- `packages/map_core/test/shadow/project_element_entry_shadow_json_test.dart`
- `packages/map_core/test/shadow/project_shadow_catalog_json_codec_test.dart`
- `packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart`

Rapports V2 audités :

- `reports/shadows/v2/shadow_v2_1_projected_building_shadows_product_spec_art_direction.md`
- `reports/shadows/v2/shadow_v2_2_projected_building_shadows_data_model_design.md`
- `reports/shadows/v2/shadow_v2_3_projected_building_shadow_json_characterization.md`
- `reports/shadows/v2/shadow_v2_4_projected_building_shadow_value_objects.md`
- `reports/shadows/v2/shadow_v2_5_projected_building_shadow_preset_model.md`
- `reports/shadows/v2/shadow_v2_6_projected_building_shadow_preset_catalog_model.md`
- `reports/shadows/v2/shadow_v2_7_projected_building_shadow_element_config_model.md`

Fichier demandé mais absent :

```text
MISSING packages/map_core/lib/src/models/project_element.dart
```

`ProjectElementEntry` vit dans `packages/map_core/lib/src/models/project_manifest.dart`.

## 7. Décisions JSON obligatoires

| Décision | Choix recommandé |
| --- | --- |
| Nom du champ root catalogue | `projectedBuildingShadowCatalog` |
| Forme du champ root | objet catalogue dédié avec `presets` |
| Nom du champ élément | `projectedBuildingShadow` |
| Root absent | catalogue vide en mémoire |
| Root vide au toJson | omis |
| Élément absent | `null` en mémoire, aucune V2 |
| Élément null explicite | accepté au decode, omis au toJson |
| Disabled config | valide si elle porte encore `presetId`, `anchor`, `localOffset` |
| Codecs | manuels externes dans `operations` |
| Migration | additive, pas d'injection V2 |

## 8. Nom du champ root recommandé

Recommandation :

```text
projectedBuildingShadowCatalog
```

Options comparées :

- `projectedBuildingShadowCatalog`
- `buildingShadowCatalog`
- `buildingShadowPresets`
- `projectedShadowCatalog`

Pourquoi `projectedBuildingShadowCatalog` :

- explicite sur `projected` ;
- explicite sur `building` ;
- évite la confusion avec `shadowCatalog` V1 ;
- laisse de la place à de futurs shadow catalogs non building ;
- cohérent avec `ProjectElementProjectedBuildingShadowConfig` ;
- déjà anticipé dans ShadowV2-2 et caractérisé dans ShadowV2-3.

Pourquoi pas les autres :

- `buildingShadowCatalog` ne dit pas assez clairement que ce sont des ombres projetées ;
- `buildingShadowPresets` est trop plat et ne permet pas d'ajouter metadata/versions dans le catalogue ;
- `projectedShadowCatalog` est trop large et pourrait mélanger bâtiments, arbres, props ou effets futurs.

## 9. Forme du champ root recommandée

Recommandation :

```json
{
  "projectedBuildingShadowCatalog": {
    "presets": []
  }
}
```

Options comparées :

### Option A — Liste directe

```json
{
  "buildingShadowPresets": []
}
```

Avantage : compacte.

Risque : champ root trop spécifique aux presets, pas extensible si le catalogue gagne une version, des catégories ou des métadonnées.

### Option B — Objet catalogue dédié

```json
{
  "projectedBuildingShadowCatalog": {
    "presets": []
  }
}
```

Avantages :

- proche de `shadowCatalog: { profiles: [...] }` ;
- extensible ;
- clair ;
- sépare V1 et V2 ;
- compatible avec un futur asset-driven override.

### Option C — Dans `shadowCatalog` V1

```json
{
  "shadowCatalog": {
    "profiles": [],
    "buildingShadowPresets": []
  }
}
```

Risque : mélange V1 profiles techniques et V2 presets artistiques. Cela recrée une confusion que ShadowV2 cherche justement à éviter.

Décision : Option B.

## 10. Nom du champ élément recommandé

Recommandation :

```text
projectedBuildingShadow
```

Options comparées :

- `projectedBuildingShadow`
- `buildingProjectedShadow`
- `buildingShadow`
- `projectedShadow`

Pourquoi `projectedBuildingShadow` :

- cohérent avec le root `projectedBuildingShadowCatalog` ;
- explicite ;
- ne se confond pas avec `shadow` V1 ;
- lisible dans un JSON élément ;
- déjà caractérisé comme unknown key dans ShadowV2-3.

Pourquoi pas les autres :

- `buildingProjectedShadow` sonne moins naturel ;
- `buildingShadow` est trop vague ;
- `projectedShadow` est trop large et pourrait s'appliquer à autre chose que les bâtiments.

## 11. Stratégie absence / null / empty

### Root absent

Décision :

```text
absence de projectedBuildingShadowCatalog -> ProjectBuildingShadowPresetCatalog vide
```

Raison : les anciens projets restent valides et ne gagnent pas de V2 authorée.

### Root vide

Décision :

```text
toJson omet projectedBuildingShadowCatalog si le catalogue est vide
```

Raison : éviter de muter tous les anciens `project.json` en ajoutant un champ V2 vide. V1 émet déjà `shadowCatalog: { profiles: [] }`, mais V2 doit être plus prudente pour ne pas faire apparaître une fonctionnalité non authorée.

### Root null

Décision recommandée :

```text
decode null comme catalogue vide pour tolérance ;
toJson ne l'émet jamais comme null.
```

### Élément absent

Décision :

```text
absence de projectedBuildingShadow -> null en mémoire
```

Cela signifie : aucune ombre projetée V2.

### Élément null

Décision :

```text
decode "projectedBuildingShadow": null comme null ;
toJson omet le champ si null.
```

Différence avec V1 :

- V1 `shadow` émet actuellement `shadow: null`.
- V2 ne doit pas copier ce bruit JSON par défaut, parce que l'objectif est de rester invisible tant qu'aucune V2 n'est authorée.

### Config disabled

JSON valide :

```json
{
  "projectedBuildingShadow": {
    "enabled": false,
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
```

Décision : valide.

Raison : `enabled: false` conserve l'intention utilisateur et le preset choisi. Une config absente ou null signifie "pas de V2". Une config présente disabled signifie "V2 authorée mais désactivée".

## 12. JSON canonique proposé

### 12.1 Catalogue avec preset

```json
{
  "projectedBuildingShadowCatalog": {
    "presets": [
      {
        "id": "short-west-building-shadow",
        "name": "Short west building shadow",
        "direction": {
          "x": -0.55,
          "y": 0.35
        },
        "shape": {
          "lengthRatio": 0.28,
          "nearWidthRatio": 0.85,
          "farWidthRatio": 0.75
        },
        "appearance": {
          "opacity": 0.18,
          "colorHexRgb": "000000"
        },
        "timeOfDayMode": "fixed",
        "sortOrder": 0
      }
    ]
  }
}
```

Notes :

- `categoryId` est omis quand il est null ;
- `categoryId: null` peut être accepté au decode pour tolérance ;
- `colorHexRgb` doit sortir en uppercase ;
- `timeOfDayMode` encode `fixed` ou `followsSun`.

### 12.2 Preset avec categoryId

```json
{
  "id": "long-east-building-shadow",
  "name": "Long east building shadow",
  "direction": {
    "x": 0.6,
    "y": 0.32
  },
  "shape": {
    "lengthRatio": 0.42,
    "nearWidthRatio": 0.9,
    "farWidthRatio": 0.78
  },
  "appearance": {
    "opacity": 0.2,
    "colorHexRgb": "000000"
  },
  "timeOfDayMode": "fixed",
  "categoryId": "building-basic",
  "sortOrder": 10
}
```

### 12.3 Config élément

```json
{
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
```

### 12.4 Projet sans V2

Forme recommandée :

```json
{
  "elements": [
    {
      "id": "house",
      "name": "House"
    }
  ]
}
```

Pas de `projectedBuildingShadowCatalog` vide et pas de `projectedBuildingShadow: null`.

### 12.5 Projet avec V1 + V2 explicitement authorés

```json
{
  "projectedBuildingShadowCatalog": {
    "presets": [
      {
        "id": "short-west-building-shadow",
        "name": "Short west building shadow",
        "direction": {
          "x": -0.55,
          "y": 0.35
        },
        "shape": {
          "lengthRatio": 0.28,
          "nearWidthRatio": 0.85,
          "farWidthRatio": 0.75
        },
        "appearance": {
          "opacity": 0.18,
          "colorHexRgb": "000000"
        },
        "timeOfDayMode": "fixed",
        "sortOrder": 0
      }
    ]
  },
  "elements": [
    {
      "id": "house_01",
      "name": "House 01",
      "shadow": {
        "castsShadow": true,
        "shadowProfileId": "building_contact_ledge"
      },
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

Cette coexistence doit être authorée explicitement. Elle ne doit jamais être produite par genericProjection automatique.

## 13. Stratégie codec

Recommandation :

```text
codecs manuels externes dans packages/map_core/lib/src/operations
```

Pourquoi :

- les modèles ShadowV2 restent purs ;
- pas de `toJson/fromJson` sur les value objects ;
- pas de `build_runner` pour cette phase ;
- le style existe déjà pour Shadow V1 :
  - `project_shadow_catalog_json_codec.dart`
  - `project_element_shadow_config_json_codec.dart`
  - `map_placed_element_shadow_override_json_codec.dart`
  - `static_shadow_footprint_config_json_codec.dart`

Fichiers futurs recommandés :

```text
packages/map_core/lib/src/operations/projected_shadow_direction_json_codec.dart
packages/map_core/lib/src/operations/projected_shadow_anchor_json_codec.dart
packages/map_core/lib/src/operations/projected_shadow_offset_json_codec.dart
packages/map_core/lib/src/operations/projected_shadow_shape_tuning_json_codec.dart
packages/map_core/lib/src/operations/projected_shadow_appearance_json_codec.dart
packages/map_core/lib/src/operations/projected_shadow_time_of_day_mode_json_codec.dart
packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart
packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart
packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart
```

Alternative acceptable si la multiplication de fichiers devient trop lourde :

```text
packages/map_core/lib/src/operations/projected_building_shadow_json_codec.dart
```

Mais la recommandation V0 reste le découpage explicite, plus testable.

## 14. Stratégie migration

Décision :

```text
Ne pas créer de migration qui injecte projectedBuildingShadowCatalog.
Ne pas créer de migration qui ajoute projectedBuildingShadow aux éléments.
Ne pas créer de preset par défaut.
```

Règles futures :

- V2 est additive ;
- projets sans V2 restent sans V2 ;
- absence root -> catalogue vide en mémoire ;
- absence élément -> config null ;
- `project_json_migrations` ne doit pas créer d'ombres V2 ;
- si une future migration copie/filtre le JSON, elle devra préserver explicitement les champs V2 connus.

## 15. Stratégie tests futurs

### 15.1 Value object codecs

Tests à créer :

- direction encode/decode ;
- anchor encode/decode ;
- offset encode/decode ;
- shape encode/decode ;
- appearance encode/decode avec uppercase color ;
- `timeOfDayMode` encode/decode `fixed` et `followsSun` ;
- enum invalide rejeté ;
- nombres invalides rejetés.

### 15.2 Preset codec

Tests à créer :

- full preset round-trip ;
- required fields missing ;
- invalid `id` / `name` / `categoryId` ;
- unknown extra keys ignorées ;
- `sortOrder` absent -> `0` si cette stratégie est retenue ;
- `categoryId` absent ou null -> null ;
- `categoryId` non-null conservé.

### 15.3 Catalog codec

Tests à créer :

- empty catalog ;
- multiple presets order stable ;
- duplicate IDs rejected ;
- unknown keys ignored ;
- invalid `presets` type rejected ;
- missing `presets` -> empty catalog ou rejet selon décision future. Recommandation : missing `presets` dans l'objet root -> empty catalog pour alignement V1.

### 15.4 Element config codec

Tests à créer :

- enabled true ;
- enabled false ;
- presetId required ;
- anchor required ;
- localOffset required ou default. Recommandation : required dans la config JSON ;
- null config behavior ;
- unknown keys ignored ;
- invalid anchor/offset rejected.

### 15.5 Manifest integration future

Tests à créer :

- projet sans root V2 field -> empty catalog ;
- projet avec root V2 field -> catalog preserved ;
- projet avec root V2 field vide -> empty catalog ;
- `toJson` no root V2 field when empty ;
- élément sans V2 field -> null ;
- élément avec V2 field -> preserved ;
- `toJson` no element V2 field when null ;
- `toJson` preserves disabled element config ;
- round-trip V1 + V2 stable ;
- old V1-only fixtures unchanged.

## 16. Golden JSON fixtures proposées

Recommandation :

- inline fixtures pour codecs atomiques ;
- fichiers JSON pour manifest golden.

Fixtures fichiers futures :

```text
packages/map_core/test/fixtures/shadow_v2/projected_building_shadow_preset_full.json
packages/map_core/test/fixtures/shadow_v2/projected_building_shadow_catalog_full.json
packages/map_core/test/fixtures/shadow_v2/project_manifest_with_projected_building_shadow_v2.json
packages/map_core/test/fixtures/shadow_v2/project_manifest_without_projected_building_shadow_v2.json
packages/map_core/test/fixtures/shadow_v2/project_manifest_with_v1_and_v2_shadow.json
```

## 17. Backward compatibility implications

Implications :

- anciens projets sans V2 restent valides ;
- anciens projets ne gagnent pas de V2 ;
- nouveaux projets avec V2 doivent round-trip sans perte ;
- vieux code sans V2 supprimera les unknown keys au round-trip, comme caractérisé par ShadowV2-3 ;
- une fois les champs V2 implémentés, ils ne seront plus unknown et devront être conservés ;
- l'absence de migration d'injection évite toute apparition automatique d'ombres V2.

Point critique :

```text
Tant que ProjectManifest / ProjectElementEntry ne connaissent pas les champs V2,
ProjectManifest.fromJson(...).toJson() peut supprimer les données V2.
```

C'est précisément ce que les prochains lots JSON doivent corriger.

## 18. Interaction avec baseline screenshots

Les lots JSON purs ne changent pas le rendu. Ils n'ont pas besoin de relancer le harness screenshot.

Règle pour plus tard :

- dès qu'un lot runtime/editor preview V2 arrive, relancer le harness ;
- dès qu'un lot modifie Selbrume ou authoring visuel V2, produire before/after ;
- ne pas remplacer la baseline Selbrume V1 sans validation explicite.

## 19. Roadmap prochains lots

Ordre strict recommandé :

### ShadowV2-9 — Projected Shadow Atomic JSON Codecs V0

Objectif : codecs pour direction, anchor, offset, shape, appearance, timeOfDayMode.

Pourquoi maintenant : les types atomiques doivent être testés avant les presets.

### ShadowV2-10 — Project Building Shadow Preset JSON Codec V0

Objectif : codec `ProjectBuildingShadowPreset`.

Pourquoi maintenant : compose les atomic codecs.

### ShadowV2-11 — Project Building Shadow Preset Catalog JSON Codec V0

Objectif : codec `ProjectBuildingShadowPresetCatalog`.

Pourquoi maintenant : vérifie ordre stable, catalogue vide, IDs dupliqués.

### ShadowV2-12 — Project Element Projected Building Shadow Config JSON Codec V0

Objectif : codec `ProjectElementProjectedBuildingShadowConfig`.

Pourquoi maintenant : configure l'élément sans encore modifier `ProjectElementEntry`.

### ShadowV2-13 — ProjectManifest / ProjectElement Integration Design Gate

Objectif : décider exactement comment intégrer les champs à `ProjectManifest` et `ProjectElementEntry`, avec conventions `includeIfNull` / omission empty.

Pourquoi maintenant : éviter une modification generated/freezed mal cadrée.

### ShadowV2-14 — ProjectManifest V2 Integration Implementation

Objectif : ajouter les champs persistants et tests golden manifest.

Pourquoi après codecs : l'intégration manifest doit assembler des codecs déjà prouvés.

## 20. Tests / commandes lancées

Commandes lancées :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
rg -n "ProjectedShadow|ProjectBuildingShadowPreset|ProjectBuildingShadowPresetCatalog|ProjectElementProjectedBuildingShadowConfig|TimeOfDay" packages/map_core/lib/src/models/projected_building_shadow.dart packages/map_core/test/shadow_v2
find packages/map_core/lib/src/operations -maxdepth 1 -type f | rg "json_codec|migration|manifest|shadow"
rg -n "encodeProjectShadowCatalog|decodeProjectShadowCatalog|encodeProjectElementShadowConfig|decodeProjectElementShadowConfig|ProjectShadowCatalogJsonConverter|ProjectElementShadowConfigJsonConverter|migrateProjectManifestJson|ProjectManifest\\.fromJson|ProjectElementEntry|shadowCatalog|encodes null shadow|empty shadow catalog canonically|Unknown keys are ignored|unknown keys are ignored" packages/map_core/lib/src/models/project_manifest.dart packages/map_core/lib/src/operations/project_shadow_catalog_json_codec.dart packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart packages/map_core/lib/src/operations/project_json_migrations.dart packages/map_core/test/shadow/project_manifest_shadow_catalog_json_test.dart packages/map_core/test/shadow/project_element_entry_shadow_json_test.dart packages/map_core/test/shadow/project_shadow_catalog_json_codec_test.dart
rg -n "unknown root|unknown element|buildingShadowPresets|projectedBuildingShadowCatalog|projectedBuildingShadow|round-trip|migrateProjectManifestJson|V1 round-trip|suppression|supprim" packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart reports/shadows/v2/shadow_v2_3_projected_building_shadow_json_characterization.md reports/shadows/v2/shadow_v2_2_projected_building_shadows_data_model_design.md
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

## 21. Résultats

### Résultat rg modèles V2

Commande ciblée incluse :

```bash
rg -n "^(enum|final class)|factory Project|final (bool|String|ProjectedShadow|ProjectBuildingShadowPreset|List)|timeOfDayMode|presetId|anchor|localOffset|presets" packages/map_core/lib/src/models/projected_building_shadow.dart packages/map_core/test/shadow_v2/projected_building_shadow_*_test.dart
```

Sortie pertinente complète :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart:11:enum ProjectedShadowTimeOfDayMode {
packages/map_core/lib/src/models/projected_building_shadow.dart:21:final class ProjectedShadowDirection {
packages/map_core/lib/src/models/projected_building_shadow.dart:62:final class ProjectedShadowAnchor {
packages/map_core/lib/src/models/projected_building_shadow.dart:93:final class ProjectedShadowOffset {
packages/map_core/lib/src/models/projected_building_shadow.dart:122:final class ProjectedShadowShapeTuning {
packages/map_core/lib/src/models/projected_building_shadow.dart:175:final class ProjectedShadowAppearance {
packages/map_core/lib/src/models/projected_building_shadow.dart:193:  final String colorHexRgb;
packages/map_core/lib/src/models/projected_building_shadow.dart:211:final class ProjectBuildingShadowPreset {
packages/map_core/lib/src/models/projected_building_shadow.dart:212:  factory ProjectBuildingShadowPreset({
packages/map_core/lib/src/models/projected_building_shadow.dart:218:    required ProjectedShadowTimeOfDayMode timeOfDayMode,
packages/map_core/lib/src/models/projected_building_shadow.dart:251:  final String id;
packages/map_core/lib/src/models/projected_building_shadow.dart:252:  final String name;
packages/map_core/lib/src/models/projected_building_shadow.dart:253:  final ProjectedShadowDirection direction;
packages/map_core/lib/src/models/projected_building_shadow.dart:254:  final ProjectedShadowShapeTuning shape;
packages/map_core/lib/src/models/projected_building_shadow.dart:255:  final ProjectedShadowAppearance appearance;
packages/map_core/lib/src/models/projected_building_shadow.dart:256:  final ProjectedShadowTimeOfDayMode timeOfDayMode;
packages/map_core/lib/src/models/projected_building_shadow.dart:257:  final String? categoryId;
packages/map_core/lib/src/models/projected_building_shadow.dart:291:final class ProjectBuildingShadowPresetCatalog {
packages/map_core/lib/src/models/projected_building_shadow.dart:293:    List<ProjectBuildingShadowPreset> presets = const [],
packages/map_core/lib/src/models/projected_building_shadow.dart:296:  final List<ProjectBuildingShadowPreset> _presets;
packages/map_core/lib/src/models/projected_building_shadow.dart:299:  List<ProjectBuildingShadowPreset> get presets => _presets;
packages/map_core/lib/src/models/projected_building_shadow.dart:372:final class ProjectElementProjectedBuildingShadowConfig {
packages/map_core/lib/src/models/projected_building_shadow.dart:373:  factory ProjectElementProjectedBuildingShadowConfig({
packages/map_core/lib/src/models/projected_building_shadow.dart:375:    required String presetId,
packages/map_core/lib/src/models/projected_building_shadow.dart:376:    required ProjectedShadowAnchor anchor,
packages/map_core/lib/src/models/projected_building_shadow.dart:377:    required ProjectedShadowOffset localOffset,
packages/map_core/lib/src/models/projected_building_shadow.dart:398:  final bool enabled;
packages/map_core/lib/src/models/projected_building_shadow.dart:399:  final String presetId;
packages/map_core/lib/src/models/projected_building_shadow.dart:400:  final ProjectedShadowAnchor anchor;
packages/map_core/lib/src/models/projected_building_shadow.dart:401:  final ProjectedShadowOffset localOffset;
```

### Résultat codecs/migrations actuels

Commande ciblée incluse :

```bash
rg -n "encodeProjectShadowCatalog|decodeProjectShadowCatalog|encodeProjectElementShadowConfig|decodeProjectElementShadowConfig|ProjectShadowCatalogJsonConverter|ProjectElementShadowConfigJsonConverter|migrateProjectManifestJson|ProjectManifest\\.fromJson|ProjectElementEntry|shadowCatalog|encodes null shadow|empty shadow catalog canonically|Unknown keys are ignored|unknown keys are ignored" packages/map_core/lib/src/models/project_manifest.dart packages/map_core/lib/src/operations/project_shadow_catalog_json_codec.dart packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart packages/map_core/lib/src/operations/project_json_migrations.dart packages/map_core/test/shadow/project_manifest_shadow_catalog_json_test.dart packages/map_core/test/shadow/project_element_entry_shadow_json_test.dart packages/map_core/test/shadow/project_shadow_catalog_json_codec_test.dart
```

Sortie pertinente complète :

```text
packages/map_core/lib/src/models/project_manifest.dart:98:    @Default([]) List<ProjectElementEntry> elements,
packages/map_core/lib/src/models/project_manifest.dart:134:    @ProjectShadowCatalogJsonConverter()
packages/map_core/lib/src/models/project_manifest.dart:135:    ProjectShadowCatalog shadowCatalog,
packages/map_core/lib/src/models/project_manifest.dart:138:  factory ProjectManifest.fromJson(Map<String, dynamic> json) =>
packages/map_core/lib/src/models/project_manifest.dart:368:class ProjectElementEntry with _$ProjectElementEntry {
packages/map_core/lib/src/models/project_manifest.dart:370:  const factory ProjectElementEntry({
packages/map_core/lib/src/models/project_manifest.dart:381:    @ProjectElementShadowConfigJsonConverter()
packages/map_core/lib/src/models/project_manifest.dart:387:  }) = _ProjectElementEntry;
packages/map_core/lib/src/models/project_manifest.dart:389:  factory ProjectElementEntry.fromJson(Map<String, dynamic> json) =>
packages/map_core/lib/src/models/project_manifest.dart:390:      _$ProjectElementEntryFromJson(jsonCoerceLegacySourceToFrames(json));
packages/map_core/lib/src/operations/project_shadow_catalog_json_codec.dart:21:Map<String, Object?> encodeProjectShadowCatalog(ProjectShadowCatalog catalog) {
packages/map_core/lib/src/operations/project_shadow_catalog_json_codec.dart:34:ProjectShadowCatalog decodeProjectShadowCatalog(Object? json) {
packages/map_core/lib/src/operations/project_shadow_catalog_json_codec.dart:70:class ProjectShadowCatalogJsonConverter
packages/map_core/lib/src/operations/project_shadow_catalog_json_codec.dart:72:  const ProjectShadowCatalogJsonConverter();
packages/map_core/lib/src/operations/project_shadow_catalog_json_codec.dart:76:    return decodeProjectShadowCatalog(json);
packages/map_core/lib/src/operations/project_shadow_catalog_json_codec.dart:81:    return encodeProjectShadowCatalog(catalog);
packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart:68:Map<String, Object?> encodeProjectElementShadowConfig(
packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart:90:/// `null` means no shadow config on the element. Unknown keys are ignored.
packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart:91:ProjectElementShadowConfig? decodeProjectElementShadowConfig(Object? json) {
packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart:144:class ProjectElementShadowConfigJsonConverter
packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart:146:  const ProjectElementShadowConfigJsonConverter();
packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart:150:    return decodeProjectElementShadowConfig(json);
packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart:155:    return config == null ? null : encodeProjectElementShadowConfig(config);
packages/map_core/lib/src/operations/project_json_migrations.dart:1:Map<String, dynamic> migrateProjectManifestJson(Map<String, dynamic> raw) {
packages/map_core/test/shadow/project_element_entry_shadow_json_test.dart:7:  group('ProjectElementEntry shadow JSON', () {
packages/map_core/test/shadow/project_element_entry_shadow_json_test.dart:71:    test('encodes null shadow using the existing nullable field style', () {
packages/map_core/test/shadow/project_manifest_shadow_catalog_json_test.dart:7:  group('ProjectManifest.shadowCatalog JSON', () {
packages/map_core/test/shadow/project_manifest_shadow_catalog_json_test.dart:8:    test('decodes legacy manifest JSON without shadowCatalog as empty', () {
packages/map_core/test/shadow/project_manifest_shadow_catalog_json_test.dart:54:    test('toJson encodes an empty shadow catalog canonically', () {
packages/map_core/test/shadow/project_manifest_shadow_catalog_json_test.dart:57:      expect(json['shadowCatalog'], <String, Object?>{
packages/map_core/test/shadow/project_shadow_catalog_json_codec_test.dart:63:        encodeProjectShadowCatalog(ProjectShadowCatalog()),
packages/map_core/test/shadow/project_shadow_catalog_json_codec_test.dart:69:      expect(decodeProjectShadowCatalog(null).isEmpty, isTrue);
packages/map_core/test/shadow/project_shadow_catalog_json_codec_test.dart:70:      expect(decodeProjectShadowCatalog(<String, Object?>{}).isEmpty, isTrue);
```

### Résultat V2-3 / compatibility characterization

Commande ciblée incluse :

```bash
rg -n "unknown root|unknown element|buildingShadowPresets|projectedBuildingShadowCatalog|projectedBuildingShadow|round-trip|migrateProjectManifestJson|V1 round-trip|suppression|supprim" packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart reports/shadows/v2/shadow_v2_3_projected_building_shadow_json_characterization.md reports/shadows/v2/shadow_v2_2_projected_building_shadows_data_model_design.md
```

Sortie pertinente complète :

```text
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:69:      'unknown root future catalog keys are accepted by ProjectManifest.fromJson '
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:75:            'buildingShadowPresets': <Object?>[],
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:76:            'projectedBuildingShadowCatalog': <String, Object?>{
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:87:        expect(json, isNot(contains('buildingShadowPresets')));
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:88:        expect(json, isNot(contains('projectedBuildingShadowCatalog')));
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:94:      'unknown element future projected shadow key is accepted and dropped by '
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:100:            'projectedBuildingShadow': <String, Object?>{
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:110:        expect(raw, contains('projectedBuildingShadow'));
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:111:        expect(json, isNot(contains('projectedBuildingShadow')));
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:117:      'migrateProjectManifestJson currently preserves V2-like unknown keys by '
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:132:            'buildingShadowPresets': <Object?>[],
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:133:            'projectedBuildingShadowCatalog': <String, Object?>{
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:139:        final migrated = migrateProjectManifestJson(raw);
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:144:        expect(migrated, contains('buildingShadowPresets'));
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:145:        expect(migrated, contains('projectedBuildingShadowCatalog'));
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:146:        expect(element, contains('projectedBuildingShadow'));
reports/shadows/v2/shadow_v2_2_projected_building_shadows_data_model_design.md:487:ProjectManifest.projectedBuildingShadowCatalog // optional/additive
reports/shadows/v2/shadow_v2_2_projected_building_shadows_data_model_design.md:488:ProjectElementEntry.projectedBuildingShadow // optional/additive
reports/shadows/v2/shadow_v2_2_projected_building_shadows_data_model_design.md:721:- old projects without `projectedBuildingShadowCatalog` decode as empty/default;
reports/shadows/v2/shadow_v2_2_projected_building_shadows_data_model_design.md:722:- old elements without `projectedBuildingShadow` decode as null;
reports/shadows/v2/shadow_v2_3_projected_building_shadow_json_characterization.md:21:- unknown root keys V2-like: acceptées par `ProjectManifest.fromJson`, supprimées par `toJson`;
reports/shadows/v2/shadow_v2_3_projected_building_shadow_json_characterization.md:22:- unknown element keys V2-like: acceptées par `ProjectElementEntry.fromJson`, supprimées par `toJson`;
reports/shadows/v2/shadow_v2_3_projected_building_shadow_json_characterization.md:23:- `migrateProjectManifestJson`: préserve actuellement l'objet par identité, donc conserve les unknown keys;
reports/shadows/v2/shadow_v2_3_projected_building_shadow_json_characterization.md:24:- Shadow V1 round-trip: stable, aucun champ V2 émis.
reports/shadows/v2/shadow_v2_3_projected_building_shadow_json_characterization.md:278:ProjectManifest.fromJson accepte buildingShadowPresets et projectedBuildingShadowCatalog.
reports/shadows/v2/shadow_v2_3_projected_building_shadow_json_characterization.md:279:ProjectManifest.toJson les supprime.
reports/shadows/v2/shadow_v2_3_projected_building_shadow_json_characterization.md:293:ProjectElementEntry.fromJson accepte projectedBuildingShadow.
reports/shadows/v2/shadow_v2_3_projected_building_shadow_json_characterization.md:294:ProjectElementEntry.toJson le supprime.
reports/shadows/v2/shadow_v2_3_projected_building_shadow_json_characterization.md:308:migrateProjectManifestJson(raw) retourne actuellement raw par identité.
reports/shadows/v2/shadow_v2_3_projected_building_shadow_json_characterization.md:347:3. Unknown keys conservées au round-trip ? Non, supprimées par `toJson`.
reports/shadows/v2/shadow_v2_3_projected_building_shadow_json_characterization.md:348:4. `migrateProjectManifestJson` conserve ou supprime ? Conserve par identité.
```

## 22. git diff --stat

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git diff --stat
```

Sortie :

```text
```

## 23. git diff --name-status

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git diff --name-status
```

Sortie :

```text
```

## 24. git diff --check

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git diff --check
```

Sortie :

```text
```

## 25. git status final

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Sortie finale réelle après ce rapport :

```text
?? reports/shadows/v2/shadow_v2_8_projected_building_shadow_json_design_compatibility_gate.md
```

## 26. Risques / réserves

- Omettre le root vide diverge de `shadowCatalog` V1, qui émet un catalogue vide canonique. Ce choix est volontaire pour éviter de modifier les projets anciens avec un champ V2 vide.
- L'omission de `projectedBuildingShadow: null` exigera probablement une configuration `includeIfNull: false` ou une stratégie de toJson dédiée lors de l'intégration `ProjectElementEntry`.
- Si les prochains lots intègrent directement au manifest avant les codecs, le risque de perte silencieuse au round-trip reste élevé.

## 27. Auto-critique

La recommandation est conservatrice : elle protège les anciens projets et garde V2 invisible tant qu'elle n'est pas authorée. Elle introduit toutefois une petite différence avec V1 (`shadow: null` et `shadowCatalog: { profiles: [] }`), qu'il faudra tester explicitement pour éviter une surprise de generated JSON.

Le rapport ne crée pas de fixture optionnelle ; c'est volontaire, car les fixtures doivent arriver avec les codecs et tests correspondants.

## 28. Regard critique sur le prompt

Le prompt force la bonne pause : décider le contrat JSON avant de toucher aux codecs ou au manifest. C'est exactement le point où une V2 peut devenir propre ou recréer une "feature moderne" qui perd des données au round-trip.

La contrainte "Aucun projet existant ne doit gagner une ombre projetée V2 automatiquement" justifie la décision la plus importante du lot : ne pas émettre de root vide par défaut.

## 29. Prochain lot recommandé

Prochain lot recommandé :

```text
ShadowV2-9 — Projected Shadow Atomic JSON Codecs V0
```

Objectif : implémenter et tester les codecs manuels des value objects atomiques ShadowV2, sans intégration manifest, sans runtime/editor et sans generated files.

## Inventaire des fichiers

Créés :

- `reports/shadows/v2/shadow_v2_8_projected_building_shadow_json_design_compatibility_gate.md`

Modifiés :

- Aucun

Supprimés :

- Aucun

Fichiers code modifiés :

- Aucun

Generated files :

- Aucun

Fichiers Selbrume :

- Aucun
