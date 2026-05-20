# ShadowV2-15 — Projected Building Shadow Semantic Diagnostics Design Gate

## 1. Résumé exécutif

ShadowV2-15 est un design gate uniquement. Aucun code, modèle, codec, test, runtime, éditeur, migration, fichier Selbrume, baseline screenshot ou fichier généré n'a été modifié.

Décision canonique :

- créer au prochain lot une opération dédiée `diagnoseProjectedBuildingShadows(ProjectManifest manifest)` ;
- retourner une liste immuable de diagnostics structurés ;
- utiliser des enums dédiées de severity et de kind ;
- considérer un preset manquant référencé par une config active comme `error` ;
- considérer un preset manquant référencé par une config désactivée comme `warning` ;
- considérer un preset inutilisé comme `warning` ;
- considérer une coexistence V1 active + V2 active comme `warning` ;
- considérer `followsSun` utilisé activement sans système jour/nuit comme `info` ;
- ne pas intégrer ces diagnostics à `ProjectValidator` / `MapValidator` en V0 ;
- ne pas auto-corriger, ne pas rendre, ne pas créer de preset, ne pas toucher au JSON.

## 2. Objectif du lot

Concevoir précisément les diagnostics sémantiques nécessaires maintenant que ShadowV2 est persistée dans :

- `ProjectManifest.projectedBuildingShadowCatalog` ;
- `ProjectElementEntry.projectedBuildingShadow`.

La question traitée :

```text
Comment détecter les données ShadowV2 incohérentes sans rendre, sans modifier, et sans auto-corriger ?
```

## 3. Rappel ShadowV2-14

ShadowV2-14 a intégré ShadowV2 dans `project.json` en persistance dormante.

Comportement validé :

```text
root absent -> catalogue vide
root null -> catalogue vide
root vide -> omis au toJson
root non vide -> émis au toJson

element field absent -> null
element field null -> null
element object -> round-trip
element null -> champ omis au toJson

ancien JSON V1 -> ne gagne aucun champ V2
V1 shadow + V2 projectedBuildingShadow -> coexistent
aucune migration injective
aucun runtime/editor
aucun Selbrume
```

ShadowV2-15 ne modifie pas cette intégration. Il prépare seulement le contrôle sémantique futur.

## 4. État initial du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Sortie initiale :

```text

```

Interprétation :

- aucun changement local n'était présent au démarrage de ShadowV2-15 ;
- le présent rapport est le seul fichier permanent attendu pour ce lot.

## 5. Décision AGENTS / design gate

Commandes :

```bash
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Sorties :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

```text
765:Before structural changes, read the nearest:
848:1. Brainstorming (`superpowers:brainstorming`) before creative work.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
1096:For creative work such as features, components, behavior changes, or UI:
```

Décision :

- le lot est explicitement design-only ;
- le design gate est satisfait par un rapport sans implémentation ;
- aucune action d'implémentation n'est nécessaire pour ShadowV2-15.

## 6. Fichiers audités

Modèles ShadowV2 / persistance :

- `packages/map_core/lib/src/models/projected_building_shadow.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/shadow.dart`
- `packages/map_core/lib/src/models/shadow_catalog.dart`

Codecs ShadowV2 :

- `packages/map_core/lib/src/operations/projected_shadow_value_object_json_codecs.dart`
- `packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart`
- `packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart`
- `packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart`

Diagnostics / validators existants :

- `packages/map_core/lib/src/operations/shadow_authoring_diagnostics.dart`
- `packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart`
- `packages/map_core/lib/src/operations/environment_authoring_diagnostics.dart`
- `packages/map_core/lib/src/validation/validators.dart`
- `packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart`
- `packages/map_core/test/surface_catalog_diagnostics_test.dart`
- `packages/map_core/test/environment_authoring_diagnostics_test.dart`

Rapports récents :

- `reports/shadows/v2/shadow_v2_12_project_element_projected_building_shadow_config_json_codec.md`
- `reports/shadows/v2/shadow_v2_13_projected_building_shadow_manifest_element_integration_design.md`
- `reports/shadows/v2/shadow_v2_14_projected_building_shadow_manifest_element_persistence_integration.md`

Note :

- le chemin `packages/map_core/lib/src/models/project_element.dart` n'existe pas ;
- `ProjectElementEntry` est défini dans `packages/map_core/lib/src/models/project_manifest.dart`.

## 7. Diagnostics à créer

### 7.1 `missingPreset`

Cas :

```text
element.projectedBuildingShadow != null
element.projectedBuildingShadow.enabled == true
catalog.presetById(config.presetId) == null
```

Décision :

- severity : `error`
- raison : une ombre projetée V2 active ne peut pas être résolue.

### 7.2 `missingPresetForDisabledConfig`

Cas :

```text
element.projectedBuildingShadow != null
element.projectedBuildingShadow.enabled == false
catalog.presetById(config.presetId) == null
```

Décision :

- severity : `warning`
- raison : la config est dormante et ne casse pas un rendu immédiat, mais elle deviendra invalide si l'utilisateur la réactive.

### 7.3 Empty catalog avec références élément

Cas :

```text
projectedBuildingShadowCatalog.isEmpty
au moins un élément porte projectedBuildingShadow.presetId
```

Décision :

- pas de diagnostic agrégé V0 ;
- les diagnostics `missingPreset` / `missingPresetForDisabledConfig` couvrent chaque élément concerné ;
- un résumé agrégé pourra être ajouté plus tard dans un read model editor si nécessaire.

### 7.4 `unusedPreset`

Cas :

```text
un ProjectBuildingShadowPreset existe dans le catalogue
aucune config élément V2 ne référence son id
```

Décision :

- severity : `warning`
- raison : donnée authoring potentiellement inutile, mais non bloquante.

Précision :

- une config V2 désactivée compte comme référence pour `unusedPreset` ;
- cela évite de marquer comme inutilisé un preset conservé volontairement dans une intention dormante.

### 7.5 `v1AndV2Coexistence`

Cas V0 retenu :

```text
element.shadow?.castsShadow == true
element.projectedBuildingShadow?.enabled == true
```

Décision :

- severity : `warning`
- raison : V1 + V2 actifs sont autorisés mais risquent de créer une double ombre visuelle quand le runtime V2 arrivera.

Précision :

- une config V1 présente mais `castsShadow == false` ne déclenche pas ce diagnostic ;
- une config V2 présente mais `enabled == false` ne déclenche pas ce diagnostic.

### 7.6 Config V2 désactivée présente

Cas :

```text
element.projectedBuildingShadow != null
element.projectedBuildingShadow.enabled == false
catalog.presetById(config.presetId) != null
```

Décision :

- aucun diagnostic V0 ;
- raison : c'est une intention utilisateur valide, pas une incohérence.

### 7.7 `followsSunWithoutTimeOfDay`

Cas V0 retenu :

```text
preset.timeOfDayMode == ProjectedShadowTimeOfDayMode.followsSun
au moins une config élément enabled true référence ce preset
aucun système jour/nuit V2 n'est encore actif
```

Décision :

- severity : `info`
- raison : c'est utile pour l'auteur, mais ce n'est pas une erreur de données.

Précision :

- ne pas émettre cette info pour un preset `followsSun` inutilisé ;
- dans ce cas, `unusedPreset` suffit et évite le bruit.

### 7.8 Catalogue non vide sans éléments V2

Cas :

```text
catalogue non vide
aucun element.projectedBuildingShadow non-null
```

Décision :

- émettre `unusedPreset` par preset ;
- pas de diagnostic agrégé V0.

### 7.9 Duplicate preset ids

Décision :

- pas de diagnostic V0 ;
- raison : `ProjectBuildingShadowPresetCatalog` et son codec rejettent déjà les ids dupliqués ;
- un état mémoire valide ne peut pas contenir de doublons.

### 7.10 Valeurs invalides

Cas :

```text
direction nulle, ratios invalides, opacity invalide, presetId vide, etc.
```

Décision :

- pas de diagnostic sémantique V0 ;
- raison : les value objects, modèles et codecs rejettent déjà ces formes avant l'état mémoire valide.

## 8. Severities recommandées

| Kind | Severity | Décision |
| --- | --- | --- |
| `missingPreset` | `error` | Config V2 active non résoluble. |
| `missingPresetForDisabledConfig` | `warning` | Dormant mais deviendra bloquant si réactivé. |
| `unusedPreset` | `warning` | Dette authoring, non bloquante. |
| `v1AndV2Coexistence` | `warning` | Double ombre possible, coexistence autorisée. |
| `followsSunWithoutTimeOfDay` | `info` | Préparation future jour/nuit, pas d'erreur de données. |
| Empty catalog aggregate | Aucun | Couvert par les diagnostics élémentaires. |
| Disabled config avec preset existant | Aucun | Intention utilisateur valide. |
| Duplicate ids | Aucun | Impossible après décodage/modèle valide. |
| Valeurs invalides | Aucun | Déjà rejetées par modèles/codecs. |

## 9. Diagnostic model proposé

Types proposés pour ShadowV2-16 :

```dart
enum ProjectedBuildingShadowDiagnosticSeverity {
  info,
  warning,
  error,
}

enum ProjectedBuildingShadowDiagnosticKind {
  missingPreset,
  missingPresetForDisabledConfig,
  unusedPreset,
  v1AndV2Coexistence,
  followsSunWithoutTimeOfDay,
}

final class ProjectedBuildingShadowDiagnostic {
  const ProjectedBuildingShadowDiagnostic({
    required this.severity,
    required this.kind,
    required this.message,
    this.elementId,
    this.elementName,
    this.presetId,
    this.presetName,
  });

  final ProjectedBuildingShadowDiagnosticSeverity severity;
  final ProjectedBuildingShadowDiagnosticKind kind;
  final String message;
  final String? elementId;
  final String? elementName;
  final String? presetId;
  final String? presetName;
}
```

Décisions :

- severity dédiée plutôt que severity générique : les diagnostics existants utilisent des enums de domaine (`SurfaceCatalogDiagnosticSeverity`, `EnvironmentAuthoringDiagnosticSeverity`) ;
- kind dédié plutôt que strings : typage stable pour tests et UI ;
- message dans `map_core` : messages déterministes déjà présents dans `shadow_authoring_diagnostics.dart` et `surface_catalog_diagnostics.dart` ;
- inclure ids et noms optionnels : les ids restent la source canonique, les noms facilitent un futur panneau auteur ;
- égalité / `hashCode` : à implémenter manuellement comme les diagnostics existants ;
- pas de JSON ;
- pas de generated file.

## 10. API proposée

API recommandée V0 :

```dart
List<ProjectedBuildingShadowDiagnostic> diagnoseProjectedBuildingShadows(
  ProjectManifest manifest,
)
```

Décision :

- choisir une liste simple en V0 ;
- retourner une liste non modifiable ;
- ne pas créer de `ProjectedBuildingShadowDiagnosticsReport` en V0.

Justification :

- `shadow_authoring_diagnostics.dart` utilise déjà une API simple `List<ShadowAuthoringDiagnostic>` ;
- le besoin V0 est un contrôle sémantique ciblé, pas un dashboard ;
- les comptes par severity peuvent être dérivés par les consommateurs ;
- un report object pourra être ajouté plus tard si l'éditeur a besoin de summary, filtres ou groupements.

## 11. Ordre stable

Ordre recommandé pour rendre les tests stables :

1. Parcourir `manifest.elements` dans l'ordre du manifest.
2. Pour chaque élément portant une config V2 :
   - émettre `missingPreset` ou `missingPresetForDisabledConfig` si le preset est absent ;
   - émettre ensuite `v1AndV2Coexistence` si V1 actif et V2 actif.
3. Construire les ensembles :
   - `referencedPresetIds` : toutes les configs V2, y compris désactivées ;
   - `activelyReferencedPresetIds` : configs V2 avec `enabled == true`.
4. Parcourir `manifest.projectedBuildingShadowCatalog.presets` dans l'ordre du catalogue.
5. Pour chaque preset :
   - émettre `unusedPreset` si son id n'est pas dans `referencedPresetIds` ;
   - sinon émettre `followsSunWithoutTimeOfDay` si `timeOfDayMode == followsSun` et id dans `activelyReferencedPresetIds`.

Conséquences :

- les diagnostics élémentaires restent dans l'ordre des éléments authorés ;
- les diagnostics catalogue restent dans l'ordre stable des presets ;
- aucun tri alphabétique ne doit être appliqué ;
- les références désactivées empêchent `unusedPreset`, mais ne déclenchent pas `followsSunWithoutTimeOfDay`.

## 12. Tests à prévoir

Tests ShadowV2-16 recommandés dans :

```text
packages/map_core/test/shadow_v2/projected_building_shadow_diagnostics_test.dart
```

Cas :

1. Aucun diagnostic :
   - catalogue avec preset `a` ;
   - élément V2 `enabled: true` référence `a` ;
   - pas de shadow V1 actif ;
   - attendu : liste vide.

2. Missing preset actif :
   - élément V2 `enabled: true` référence `missing` ;
   - catalogue vide ;
   - attendu : `error`, kind `missingPreset`, `elementId`, `elementName`, `presetId`.

3. Missing preset désactivé :
   - élément V2 `enabled: false` référence `missing` ;
   - catalogue vide ;
   - attendu : `warning`, kind `missingPresetForDisabledConfig`.

4. Unused preset :
   - catalogue avec preset `a` ;
   - aucun élément ne référence `a` ;
   - attendu : `warning`, kind `unusedPreset`.

5. Disabled config avec preset existant :
   - catalogue avec preset `a` ;
   - élément V2 `enabled: false` référence `a` ;
   - attendu : aucun diagnostic.

6. Disabled config compte comme usage :
   - même configuration que le test 5 ;
   - vérifier explicitement qu'aucun `unusedPreset` n'est émis.

7. V1 + V2 coexistence :
   - élément avec `shadow` V1 `castsShadow: true` ;
   - même élément avec V2 `enabled: true` ;
   - attendu : `warning`, kind `v1AndV2Coexistence`.

8. V1 désactivé + V2 actif :
   - élément avec `shadow` V1 `castsShadow: false` ;
   - V2 `enabled: true` ;
   - attendu : pas de `v1AndV2Coexistence`.

9. V1 actif + V2 désactivé :
   - élément avec `shadow` V1 `castsShadow: true` ;
   - V2 `enabled: false` ;
   - attendu : pas de `v1AndV2Coexistence`.

10. followsSun actif :
    - preset `followsSun` référencé par une config `enabled: true` ;
    - attendu : `info`, kind `followsSunWithoutTimeOfDay`.

11. followsSun inutilisé :
    - preset `followsSun` non référencé ;
    - attendu : `unusedPreset` uniquement, pas d'info followsSun.

12. Ordre stable :
    - plusieurs éléments et presets ;
    - vérifier l'ordre exact : diagnostics par éléments, puis diagnostics catalogue.

13. Égalité / hashCode :
    - deux diagnostics identiques sont égaux ;
    - différence de severity, kind, elementId, presetId ou message casse l'égalité.

14. Liste non modifiable :
    - tenter de modifier la liste retournée ;
    - attendu : modification impossible.

## 13. Hors scope V0

ShadowV2-16 ne doit pas implémenter :

- runtime resolver ;
- renderer ;
- editor UI ;
- preview ;
- screenshots / baselines ;
- JSON changes ;
- manifest schema changes ;
- migrations ;
- auto-fix ;
- auto-cleanup ;
- preset creation ;
- default presets ;
- time-of-day implementation ;
- vérification du fait qu'un élément est réellement un bâtiment ;
- détection de recouvrement visuel ;
- calcul de double shadow visuelle ;
- intégration `MapPlacedElement` ou override instance.

## 14. Relation avec ProjectValidator / MapValidator

Audit :

```text
packages/map_core/lib/src/validation/validators.dart:14:class ProjectValidator {
packages/map_core/lib/src/validation/validators.dart:74:  static void validate(ProjectManifest manifest) {
packages/map_core/lib/src/validation/validators.dart:1276:class MapValidator {
packages/map_core/lib/src/validation/validators.dart:1278:  static void validate(
```

Décision :

- ne pas intégrer les diagnostics ShadowV2 à `ProjectValidator` ou `MapValidator` en V0 ;
- créer une opération authoring dédiée ;
- ne pas faire échouer la validation projet sur `unusedPreset`, `v1AndV2Coexistence` ou `followsSunWithoutTimeOfDay` ;
- ne pas faire échouer automatiquement `ProjectValidator` sur `missingPreset`, même si le diagnostic est `error`.

Justification :

- ShadowV2 est encore en persistance dormante ;
- `ProjectValidator` / `MapValidator` jettent des `ValidationException` pour des invariants structurels ;
- les diagnostics ShadowV2 doivent signaler une dette authoring sans muter ni bloquer les anciens flux ;
- un futur pipeline de publication pourra décider de traiter `ProjectedBuildingShadowDiagnosticSeverity.error` comme bloquant.

## 15. Fichiers proposés pour ShadowV2-16

À créer :

```text
packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart
packages/map_core/test/shadow_v2/projected_building_shadow_diagnostics_test.dart
reports/shadows/v2/shadow_v2_16_projected_building_shadow_semantic_diagnostics.md
```

À modifier si cohérent avec les conventions :

```text
packages/map_core/lib/map_core.dart
```

Raison export :

- `map_core.dart` exporte déjà des diagnostics authoring publics :
  - `surface_catalog_diagnostics.dart`
  - `environment_authoring_diagnostics.dart`
  - `shadow_authoring_diagnostics.dart`
- le diagnostic ShadowV2 doit probablement être exporté pour l'éditeur futur.

Interdits pour ShadowV2-16 :

```text
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/project_manifest.freezed.dart
packages/map_core/lib/src/models/project_manifest.g.dart
packages/map_core/lib/src/models/map_data.dart
packages/map_core/lib/src/operations/project_json_migrations.dart
packages/map_runtime/**
packages/map_editor/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
/Users/karim/Desktop/selbrume/project.json
/Users/karim/Desktop/selbrume/maps/Selbrume.json
```

## 16. Commandes lancées

Audit initial :

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Audits demandés / ciblés :

```bash
find packages/map_core/lib/src/operations -maxdepth 1 -type f | rg "diagnostic|diagnostics|validator|validation"
rg -n "projectedBuildingShadowCatalog|projectedBuildingShadow|ProjectBuildingShadowPresetCatalog|ProjectElementProjectedBuildingShadowConfig" packages/map_core/lib/src packages/map_core/test reports/shadows/v2/shadow_v2_12_project_element_projected_building_shadow_config_json_codec.md reports/shadows/v2/shadow_v2_13_projected_building_shadow_manifest_element_integration_design.md reports/shadows/v2/shadow_v2_14_projected_building_shadow_manifest_element_persistence_integration.md
rg -n "Diagnostic|Diagnostics|Severity|ProjectValidator|MapValidator|unused|missing|warning|error|catalog|preset|profile" packages/map_core/lib/src/operations packages/map_core/test --glob '*diagnostic*_test.dart' --glob '*diagnostics*_test.dart' --glob '*validator*_test.dart'
rg -n "ProjectElementShadowConfig|shadow:|MapPlacedElementShadowOverride|resolveShadowConfig|shadowCatalog" packages/map_core/lib/src packages/map_core/test/shadow packages/map_core/test/shadow_v2
```

Audits de convention reproduits ci-dessous :

```bash
sed -n '1,220p' packages/map_core/lib/src/operations/shadow_authoring_diagnostics.dart
sed -n '1,260p' packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart
sed -n '1,220p' packages/map_core/lib/src/operations/environment_authoring_diagnostics.dart
rg -n "ProjectValidator|MapValidator|validateProject|validateMap|Validation" packages/map_core/lib/src packages/map_core/test
rg -n "class ProjectValidator|class MapValidator|static (void|[A-Za-z<>?]+) validate|validate\(" packages/map_core/lib/src/models packages/map_core/lib/src/validation packages/map_core/lib/src/operations/map_events.dart packages/map_core/lib/src/operations/map_entities.dart
rg -n "diagnoseProjectShadowAuthoring|ShadowAuthoringDiagnostic|missingShadowProfile|castsShadow" packages/map_core/lib/src/operations/shadow_authoring_diagnostics.dart packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart
rg -n "diagnoseProjectSurfaceCatalog|SurfaceCatalogDiagnostic|SurfaceCatalogDiagnosticsReport|unused|missingPresetAnimation|hasErrors|byKind" packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart packages/map_core/test/surface_catalog_diagnostics_test.dart
rg -n "projectedBuildingShadowCatalog|projectedBuildingShadow|ProjectBuildingShadowPresetCatalog|ProjectElementProjectedBuildingShadowConfig" packages/map_core/lib/src/models/project_manifest.dart packages/map_core/lib/src/models/projected_building_shadow.dart packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart
sed -n '1,170p' packages/map_core/lib/src/validation/validators.dart
sed -n '1270,1345p' packages/map_core/lib/src/validation/validators.dart
rg -n "export 'src/operations/.*diagnostic|shadow_authoring_diagnostics|surface_catalog_diagnostics|environment_authoring_diagnostics" packages/map_core/lib/map_core.dart
```

Fin :

```bash
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

## 17. Résultats

### 17.1 Fichiers diagnostics / validators existants

Commande :

```bash
find packages/map_core/lib/src/operations -maxdepth 1 -type f | rg "diagnostic|diagnostics|validator|validation"
```

Sortie :

```text
packages/map_core/lib/src/operations/environment_authoring_diagnostics.dart
packages/map_core/lib/src/operations/environment_preset_diagnostics.dart
packages/map_core/lib/src/operations/surface_catalog_authoring_diagnostics.dart
packages/map_core/lib/src/operations/shadow_authoring_diagnostics.dart
packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart
packages/map_core/lib/src/operations/environment_layer_usage_diagnostics.dart
packages/map_core/lib/src/operations/surface_catalog_diagnostics_presentation.dart
packages/map_core/lib/src/operations/surface_catalog_diagnostics_summary.dart
```

### 17.2 Résultat rg ShadowV2 persistence

Commande :

```bash
rg -n "projectedBuildingShadowCatalog|projectedBuildingShadow|ProjectBuildingShadowPresetCatalog|ProjectElementProjectedBuildingShadowConfig" packages/map_core/lib/src/models/project_manifest.dart packages/map_core/lib/src/models/projected_building_shadow.dart packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart
```

Sortie :

```text
packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart:38:Map<String, dynamic> encodeProjectBuildingShadowPresetCatalog(
packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart:39:  ProjectBuildingShadowPresetCatalog catalog,
packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart:54:ProjectBuildingShadowPresetCatalog decodeProjectBuildingShadowPresetCatalog(
packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart:57:  final map = _requiredObject(json, 'ProjectBuildingShadowPresetCatalog');
packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart:61:    'ProjectBuildingShadowPresetCatalog.presets',
packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart:65:      'ProjectBuildingShadowPresetCatalog.presets must be a List',
packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart:74:        'ProjectBuildingShadowPresetCatalog.presets[$index] must be an Object',
packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart:80:  return ProjectBuildingShadowPresetCatalog(presets: presets);
packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart:62:Map<String, dynamic> encodeProjectElementProjectedBuildingShadowConfig(
packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart:63:  ProjectElementProjectedBuildingShadowConfig config,
packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart:78:ProjectElementProjectedBuildingShadowConfig
packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart:79:    decodeProjectElementProjectedBuildingShadowConfig(Object? json) {
packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart:82:    'ProjectElementProjectedBuildingShadowConfig',
packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart:84:  return ProjectElementProjectedBuildingShadowConfig(
packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart:88:      'ProjectElementProjectedBuildingShadowConfig.enabled',
packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart:93:      'ProjectElementProjectedBuildingShadowConfig.presetId',
packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart:99:        'ProjectElementProjectedBuildingShadowConfig.anchor',
packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart:106:        'ProjectElementProjectedBuildingShadowConfig.localOffset',
packages/map_core/lib/src/models/projected_building_shadow.dart:291:final class ProjectBuildingShadowPresetCatalog {
packages/map_core/lib/src/models/projected_building_shadow.dart:292:  ProjectBuildingShadowPresetCatalog({
packages/map_core/lib/src/models/projected_building_shadow.dart:296:  const ProjectBuildingShadowPresetCatalog.empty() : _presets = const [];
packages/map_core/lib/src/models/projected_building_shadow.dart:324:      other is ProjectBuildingShadowPresetCatalog &&
packages/map_core/lib/src/models/projected_building_shadow.dart:348:        'ProjectBuildingShadowPresetCatalog.presets must not contain duplicate ProjectBuildingShadowPreset.id',
packages/map_core/lib/src/models/projected_building_shadow.dart:374:final class ProjectElementProjectedBuildingShadowConfig {
packages/map_core/lib/src/models/projected_building_shadow.dart:375:  factory ProjectElementProjectedBuildingShadowConfig({
packages/map_core/lib/src/models/projected_building_shadow.dart:383:      'ProjectElementProjectedBuildingShadowConfig.presetId',
packages/map_core/lib/src/models/projected_building_shadow.dart:385:    return ProjectElementProjectedBuildingShadowConfig._(
packages/map_core/lib/src/models/projected_building_shadow.dart:393:  const ProjectElementProjectedBuildingShadowConfig._({
packages/map_core/lib/src/models/projected_building_shadow.dart:408:      other is ProjectElementProjectedBuildingShadowConfig &&
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:9:      'ProjectManifest without projectedBuildingShadowCatalog decodes an empty '
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:14:        expect(manifest.projectedBuildingShadowCatalog.isEmpty, isTrue);
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:17:        expect(json, isNot(contains('projectedBuildingShadowCatalog')));
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:19:            isNot(contains('projectedBuildingShadow')));
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:24:      'ProjectManifest with projectedBuildingShadowCatalog null decodes empty '
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:28:          _manifestJson(projectedBuildingShadowCatalog: null),
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:31:        expect(manifest.projectedBuildingShadowCatalog.isEmpty, isTrue);
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:34:        expect(json, isNot(contains('projectedBuildingShadowCatalog')));
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:39:      'ProjectManifest rejects an object projectedBuildingShadowCatalog without '
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:45:              projectedBuildingShadowCatalog: <String, Object?>{},
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:54:      'ProjectManifest with empty projectedBuildingShadowCatalog presets decodes '
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:59:            projectedBuildingShadowCatalog: <String, Object?>{
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:65:        expect(manifest.projectedBuildingShadowCatalog.isEmpty, isTrue);
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:68:        expect(json, isNot(contains('projectedBuildingShadowCatalog')));
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:73:      'ProjectManifest with non-empty projectedBuildingShadowCatalog round-trips '
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:77:          _manifestJson(projectedBuildingShadowCatalog: _catalogJson()),
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:80:        expect(manifest.projectedBuildingShadowCatalog.length, 2);
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:82:          manifest.projectedBuildingShadowCatalog
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:90:        expect(json['projectedBuildingShadowCatalog'], _catalogJson());
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:94:          roundTripped.projectedBuildingShadowCatalog,
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:95:          manifest.projectedBuildingShadowCatalog,
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:101:      'ProjectElementEntry without projectedBuildingShadow decodes null and '
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:106:        expect(element.projectedBuildingShadow, isNull);
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:107:        expect(element.toJson(), isNot(contains('projectedBuildingShadow')));
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:112:      'ProjectElementEntry with projectedBuildingShadow null decodes null and '
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:116:          _elementJson(projectedBuildingShadow: null),
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:119:        expect(element.projectedBuildingShadow, isNull);
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:120:        expect(element.toJson(), isNot(contains('projectedBuildingShadow')));
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:125:      'ProjectElementEntry with projectedBuildingShadow round-trips and emits '
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:129:          _elementJson(projectedBuildingShadow: _projectedShadowConfigJson()),
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:132:        expect(element.projectedBuildingShadow, _projectedShadowConfig());
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:135:        expect(json['projectedBuildingShadow'], _projectedShadowConfigJson());
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:138:        expect(roundTripped.projectedBuildingShadow,
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:139:            element.projectedBuildingShadow);
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:144:      'ProjectElementEntry preserves V1 shadow and V2 projectedBuildingShadow '
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:150:            projectedBuildingShadow: _projectedShadowConfigJson(enabled: false),
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:157:          element.projectedBuildingShadow,
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:164:          json['projectedBuildingShadow'],
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:189:        expect(json, isNot(contains('projectedBuildingShadowCatalog')));
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:190:        expect(elements[0], isNot(contains('projectedBuildingShadow')));
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:191:        expect(elements[1], isNot(contains('projectedBuildingShadow')));
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:197:      final catalog = ProjectBuildingShadowPresetCatalog(
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:202:        projectedBuildingShadowCatalog: catalog,
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:205:      expect(updatedManifest.projectedBuildingShadowCatalog, catalog);
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:206:      expect(manifest.projectedBuildingShadowCatalog.isEmpty, isTrue);
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:210:      final updatedElement = element.copyWith(projectedBuildingShadow: config);
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:212:      expect(updatedElement.projectedBuildingShadow, config);
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:213:      expect(element.projectedBuildingShadow, isNull);
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:219:  Object? projectedBuildingShadowCatalog = _absent,
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:228:    if (!identical(projectedBuildingShadowCatalog, _absent))
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:229:      'projectedBuildingShadowCatalog': projectedBuildingShadowCatalog,
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:237:  Object? projectedBuildingShadow = _absent,
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:250:    if (!identical(projectedBuildingShadow, _absent))
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:251:      'projectedBuildingShadow': projectedBuildingShadow,
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:338:ProjectElementProjectedBuildingShadowConfig _projectedShadowConfig({
packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart:341:  return ProjectElementProjectedBuildingShadowConfig(
packages/map_core/lib/src/models/project_manifest.dart:54:ProjectBuildingShadowPresetCatalog _projectedBuildingShadowCatalogFromJson(
packages/map_core/lib/src/models/project_manifest.dart:57:    return const ProjectBuildingShadowPresetCatalog.empty();
packages/map_core/lib/src/models/project_manifest.dart:61:      'projectedBuildingShadowCatalog must be a JSON object',
packages/map_core/lib/src/models/project_manifest.dart:64:  return decodeProjectBuildingShadowPresetCatalog(json);
packages/map_core/lib/src/models/project_manifest.dart:67:Map<String, Object?>? _projectedBuildingShadowCatalogToJson(
packages/map_core/lib/src/models/project_manifest.dart:68:  ProjectBuildingShadowPresetCatalog catalog,
packages/map_core/lib/src/models/project_manifest.dart:73:  return encodeProjectBuildingShadowPresetCatalog(catalog);
packages/map_core/lib/src/models/project_manifest.dart:76:ProjectElementProjectedBuildingShadowConfig?
packages/map_core/lib/src/models/project_manifest.dart:77:    _projectedBuildingShadowConfigFromJson(Object? json) {
packages/map_core/lib/src/models/project_manifest.dart:81:  return decodeProjectElementProjectedBuildingShadowConfig(json);
packages/map_core/lib/src/models/project_manifest.dart:84:Map<String, Object?>? _projectedBuildingShadowConfigToJson(
packages/map_core/lib/src/models/project_manifest.dart:85:  ProjectElementProjectedBuildingShadowConfig? config,
packages/map_core/lib/src/models/project_manifest.dart:90:  return encodeProjectElementProjectedBuildingShadowConfig(config);
packages/map_core/lib/src/models/project_manifest.dart:182:    @Default(ProjectBuildingShadowPresetCatalog.empty())
packages/map_core/lib/src/models/project_manifest.dart:184:      name: 'projectedBuildingShadowCatalog',
packages/map_core/lib/src/models/project_manifest.dart:185:      fromJson: _projectedBuildingShadowCatalogFromJson,
packages/map_core/lib/src/models/project_manifest.dart:186:      toJson: _projectedBuildingShadowCatalogToJson,
packages/map_core/lib/src/models/project_manifest.dart:189:    ProjectBuildingShadowPresetCatalog projectedBuildingShadowCatalog,
packages/map_core/lib/src/models/project_manifest.dart:438:      name: 'projectedBuildingShadow',
packages/map_core/lib/src/models/project_manifest.dart:439:      fromJson: _projectedBuildingShadowConfigFromJson,
packages/map_core/lib/src/models/project_manifest.dart:440:      toJson: _projectedBuildingShadowConfigToJson,
packages/map_core/lib/src/models/project_manifest.dart:443:    ProjectElementProjectedBuildingShadowConfig? projectedBuildingShadow,
```

### 17.3 Résultat rg diagnostics / validators existants

Commandes :

```bash
rg -n "diagnoseProjectShadowAuthoring|ShadowAuthoringDiagnostic|missingShadowProfile|castsShadow" packages/map_core/lib/src/operations/shadow_authoring_diagnostics.dart packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart
rg -n "diagnoseProjectSurfaceCatalog|SurfaceCatalogDiagnostic|SurfaceCatalogDiagnosticsReport|unused|missingPresetAnimation|hasErrors|byKind" packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart packages/map_core/test/surface_catalog_diagnostics_test.dart
rg -n "class ProjectValidator|class MapValidator|static (void|[A-Za-z<>?]+) validate|validate\(" packages/map_core/lib/src/models packages/map_core/lib/src/validation packages/map_core/lib/src/operations/map_events.dart packages/map_core/lib/src/operations/map_entities.dart
rg -n "export 'src/operations/.*diagnostic|shadow_authoring_diagnostics|surface_catalog_diagnostics|environment_authoring_diagnostics" packages/map_core/lib/map_core.dart
```

Sorties :

```text
packages/map_core/lib/src/operations/shadow_authoring_diagnostics.dart:3:enum ShadowAuthoringDiagnosticKind {
packages/map_core/lib/src/operations/shadow_authoring_diagnostics.dart:4:  missingShadowProfile,
packages/map_core/lib/src/operations/shadow_authoring_diagnostics.dart:7:final class ShadowAuthoringDiagnostic {
packages/map_core/lib/src/operations/shadow_authoring_diagnostics.dart:8:  const ShadowAuthoringDiagnostic({
packages/map_core/lib/src/operations/shadow_authoring_diagnostics.dart:15:  final ShadowAuthoringDiagnosticKind kind;
packages/map_core/lib/src/operations/shadow_authoring_diagnostics.dart:23:        other is ShadowAuthoringDiagnostic &&
packages/map_core/lib/src/operations/shadow_authoring_diagnostics.dart:43:List<ShadowAuthoringDiagnostic> diagnoseProjectShadowAuthoring(
packages/map_core/lib/src/operations/shadow_authoring_diagnostics.dart:46:  final diagnostics = <ShadowAuthoringDiagnostic>[];
packages/map_core/lib/src/operations/shadow_authoring_diagnostics.dart:51:    if (shadow == null || !shadow.castsShadow) {
packages/map_core/lib/src/operations/shadow_authoring_diagnostics.dart:65:      ShadowAuthoringDiagnostic(
packages/map_core/lib/src/operations/shadow_authoring_diagnostics.dart:66:        kind: ShadowAuthoringDiagnosticKind.missingShadowProfile,
packages/map_core/lib/src/operations/shadow_authoring_diagnostics.dart:75:  return List<ShadowAuthoringDiagnostic>.unmodifiable(diagnostics);
packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart:7:      final diagnostics = diagnoseProjectShadowAuthoring(
packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart:14:    test('ignores null shadow and castsShadow false', () {
packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart:15:      final diagnostics = diagnoseProjectShadowAuthoring(
packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart:22:                castsShadow: false,
packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart:33:    test('castsShadow true with existing profile has no diagnostics', () {
packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart:34:      final diagnostics = diagnoseProjectShadowAuthoring(
packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart:41:                castsShadow: true,
packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart:52:    test('castsShadow true with missing profile produces a diagnostic', () {
packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart:53:      final diagnostics = diagnoseProjectShadowAuthoring(
packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart:59:                castsShadow: true,
packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart:70:        ShadowAuthoringDiagnosticKind.missingShadowProfile,
packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart:79:      final diagnostics = diagnoseProjectShadowAuthoring(
packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart:85:                castsShadow: true,
packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart:92:                castsShadow: true,
packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart:108:      final diagnostics = diagnoseProjectShadowAuthoring(
packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart:114:                castsShadow: true,
packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart:121:                castsShadow: true,
packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart:141:      const a = ShadowAuthoringDiagnostic(
packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart:142:        kind: ShadowAuthoringDiagnosticKind.missingShadowProfile,
packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart:148:      const b = ShadowAuthoringDiagnostic(
packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart:149:        kind: ShadowAuthoringDiagnosticKind.missingShadowProfile,
packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart:172:          castsShadow: true,
packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart:178:      diagnoseProjectShadowAuthoring(manifest);
```

```text
packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart:23:/// Niveau de sévérité d’un [SurfaceCatalogDiagnostic] :
packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart:27:enum SurfaceCatalogDiagnosticSeverity {
packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart:34:enum SurfaceCatalogDiagnosticKind {
packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart:37:  missingPresetAnimation,
packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart:50:  unusedAtlas,
packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart:57:  unusedAnimation,
packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart:63:final class SurfaceCatalogDiagnostic {
packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart:117:final class SurfaceCatalogDiagnosticsReport {
packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart:134:  /// Vrai si au moins une entrée a [SurfaceCatalogDiagnosticSeverity.error].
packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart:135:  bool get hasErrors =>
packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart:140:  List<SurfaceCatalogDiagnostic> byKind(SurfaceCatalogDiagnosticKind kind) {
packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart:174:SurfaceCatalogDiagnosticsReport diagnoseProjectSurfaceCatalog(
packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart:184:            severity: SurfaceCatalogDiagnosticSeverity.error,
packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart:185:            kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart:257:SurfaceCatalogDiagnosticsReport diagnoseProjectSurfaceCatalogUnusedResources(
packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart:273:          severity: SurfaceCatalogDiagnosticSeverity.warning,
packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart:274:          kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart:297:          severity: SurfaceCatalogDiagnosticSeverity.warning,
packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart:298:          kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
```

```text
packages/map_core/lib/src/validation/validators.dart:14:class ProjectValidator {
packages/map_core/lib/src/validation/validators.dart:74:  static void validate(ProjectManifest manifest) {
packages/map_core/lib/src/validation/validators.dart:1276:class MapValidator {
packages/map_core/lib/src/validation/validators.dart:1278:  static void validate(
```

```text
69:export 'src/operations/surface_catalog_diagnostics.dart';
70:export 'src/operations/surface_catalog_authoring_diagnostics.dart';
71:export 'src/operations/surface_catalog_diagnostics_summary.dart';
72:export 'src/operations/surface_catalog_diagnostics_presentation.dart';
99:export 'src/operations/environment_preset_diagnostics.dart';
100:export 'src/operations/environment_layer_usage_diagnostics.dart';
101:export 'src/operations/environment_authoring_diagnostics.dart';
102:export 'src/operations/shadow_authoring_diagnostics.dart';
```

### 17.4 Conclusions d'audit

- Shadow V1 authoring utilise une API simple : `List<ShadowAuthoringDiagnostic> diagnoseProjectShadowAuthoring(ProjectManifest manifest)`.
- Les diagnostics Surface utilisent un report object quand les besoins incluent `hasErrors`, `byKind` et diagnostics multiples catalogue.
- Les diagnostics existants sont structurés, typés par enums, déterministes et sans JSON.
- `ProjectValidator` et `MapValidator` existent, mais ils servent aux invariants structurels avec exceptions, pas aux warnings authoring.
- `map_core.dart` exporte déjà les diagnostics publics existants ; le futur diagnostic ShadowV2 devrait suivre cette convention.

## 18. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie finale vérifiée après création du rapport :

```text

```

Interprétation :

- aucun fichier suivi n'est modifié ;
- le rapport ShadowV2-15 est un nouveau fichier non suivi, donc absent de `git diff --stat`.

## 19. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie finale vérifiée après création du rapport :

```text

```

Interprétation :

- aucun fichier suivi n'est modifié.

## 20. git diff --check

Commande :

```bash
git diff --check
```

Sortie finale vérifiée après création du rapport :

```text

```

Interprétation :

- aucune erreur whitespace détectée dans les fichiers suivis ;
- le rapport non suivi n'est pas évalué par `git diff --check`.

## 21. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale vérifiée :

```text
?? reports/shadows/v2/shadow_v2_15_projected_building_shadow_semantic_diagnostics_design.md
```

## 22. Risques / réserves

- Le choix d'une liste simple peut être trop léger pour un futur panneau editor riche ; il reste volontairement adapté à V0 et à `shadow_authoring_diagnostics.dart`.
- Le diagnostic `followsSunWithoutTimeOfDay` dépend d'un système jour/nuit absent. La décision V0 le garde en `info` et uniquement pour les presets activement référencés afin de limiter le bruit.
- La coexistence V1/V2 est diagnostiquée seulement quand V1 et V2 sont actifs. Une config V1 présente mais désactivée n'est pas signalée.
- `ProjectValidator` ne bloquera pas `missingPreset` en V0. C'est intentionnel pour garder ShadowV2 dormante, mais un futur publish gate devra probablement traiter cette severity `error` comme bloquante.

## 23. Auto-critique

La décision la plus discutable est de ne pas créer de report object. Les diagnostics Surface montrent qu'un report peut être utile. Pour ShadowV2-16, la liste simple est toutefois cohérente avec Shadow V1, réduit le diff et suffit pour tester les incohérences demandées. Si l'éditeur demande des compteurs ou filtres, un report object pourra être ajouté sans changer les diagnostics eux-mêmes.

Le deuxième point à surveiller est `followsSunWithoutTimeOfDay` : en l'absence de runtime V2, c'est plus une note de roadmap qu'un défaut. Le garder en `info` protège contre une fausse alarme tout en rendant la donnée visible.

## 24. Regard critique sur le prompt

Le prompt est bien borné : il sépare design, diagnostics, runtime, éditeur et auto-fix. Il impose aussi les bons cas sémantiques avant de rendre la V2 visible.

Point à améliorer pour les futurs lots design : les commandes `rg` très larges sur `packages/map_core/test` produisent beaucoup de correspondances. Pour les evidence packs, des commandes ciblées par fichiers diagnostics et tests donnent une preuve plus lisible tout en restant vérifiable.

## 25. Prompt proposé pour ShadowV2-16

````md
# ShadowV2-16 — Projected Building Shadow Semantic Diagnostics V0

Tu travailles dans le repo local :

```text
/Users/karim/Project/pokemonProject
```

## Contrat

Implémenter uniquement les diagnostics sémantiques ShadowV2 dans `map_core`.

Créer :

```text
packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart
packages/map_core/test/shadow_v2/projected_building_shadow_diagnostics_test.dart
reports/shadows/v2/shadow_v2_16_projected_building_shadow_semantic_diagnostics.md
```

Modifier `packages/map_core/lib/map_core.dart` seulement si l'export public suit les conventions existantes.

Ne pas modifier :

```text
ProjectManifest
ProjectElementEntry
MapPlacedElement
codecs JSON
migrations
runtime
editor
Selbrume
screenshots/baselines
generated files
```

Ne pas lancer `build_runner`. Ne pas faire de commit.

## API à créer

```dart
enum ProjectedBuildingShadowDiagnosticSeverity {
  info,
  warning,
  error,
}

enum ProjectedBuildingShadowDiagnosticKind {
  missingPreset,
  missingPresetForDisabledConfig,
  unusedPreset,
  v1AndV2Coexistence,
  followsSunWithoutTimeOfDay,
}

final class ProjectedBuildingShadowDiagnostic {
  const ProjectedBuildingShadowDiagnostic({
    required this.severity,
    required this.kind,
    required this.message,
    this.elementId,
    this.elementName,
    this.presetId,
    this.presetName,
  });
}

List<ProjectedBuildingShadowDiagnostic> diagnoseProjectedBuildingShadows(
  ProjectManifest manifest,
)
```

La liste retournée doit être non modifiable.

## Diagnostics

- `missingPreset` : `error`, config V2 active référence un preset absent.
- `missingPresetForDisabledConfig` : `warning`, config V2 désactivée référence un preset absent.
- `unusedPreset` : `warning`, preset jamais référencé par aucune config V2, y compris désactivée.
- `v1AndV2Coexistence` : `warning`, `element.shadow?.castsShadow == true` et V2 `enabled == true`.
- `followsSunWithoutTimeOfDay` : `info`, preset `followsSun` activement référencé par au moins une config enabled true.

Ne pas créer de diagnostic agrégé pour catalogue vide.
Ne pas diagnostiquer une config V2 disabled si son preset existe.
Ne pas diagnostiquer les duplicate ids ou values invalides déjà rejetés par modèles/codecs.

## Ordre stable

1. Diagnostics par élément dans l'ordre `manifest.elements` :
   - missing preset active/disabled ;
   - V1 + V2 coexistence.
2. Diagnostics par preset dans l'ordre `manifest.projectedBuildingShadowCatalog.presets` :
   - unused preset ;
   - followsSunWithoutTimeOfDay pour presets activement référencés.

## Tests

Ajouter les tests :

- aucun diagnostic ;
- missing preset actif ;
- missing preset désactivé ;
- unused preset ;
- config disabled avec preset existant ;
- config disabled compte comme usage ;
- V1 actif + V2 actif ;
- V1 désactivé + V2 actif ;
- V1 actif + V2 désactivé ;
- followsSun actif ;
- followsSun inutilisé ;
- ordre stable ;
- égalité / hashCode ;
- liste non modifiable.

## Commandes

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "diagnoseProjectShadowAuthoring|SurfaceCatalogDiagnostic|EnvironmentAuthoringDiagnostic|ProjectValidator|MapValidator" packages/map_core/lib/src packages/map_core/test
cd packages/map_core && dart test test/shadow_v2/projected_building_shadow_diagnostics_test.dart
cd packages/map_core && dart test test/shadow_v2
cd packages/map_core && dart test test/shadow
cd packages/map_core && dart analyze lib/src/operations/projected_building_shadow_diagnostics.dart test/shadow_v2/projected_building_shadow_diagnostics_test.dart
cd /Users/karim/Project/pokemonProject
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```
````

## Inventaire des fichiers

Créés :

- `reports/shadows/v2/shadow_v2_15_projected_building_shadow_semantic_diagnostics_design.md`

Modifiés :

- Aucun

Supprimés :

- Aucun

Générés :

- Aucun

Untracked attendus :

- `reports/shadows/v2/shadow_v2_15_projected_building_shadow_semantic_diagnostics_design.md`

Fichiers Selbrume :

- Aucun

Tests lancés :

- Aucun test lancé, car ShadowV2-15 est design-only et ne modifie pas le code.

Build runner :

- Non lancé, conformément au contrat du lot.

Commit :

- Aucun commit effectué.
