# ShadowV2-67 — Projected Building Shadow Adaptive Guard Diagnostics Design Gate

## 1. Résumé exécutif

Ce lot est design-only.

Recommandation unique :

```text
Étendre diagnoseProjectedBuildingShadows(...) avec un diagnostic V0 :
adaptivePresetRequiresCasterKind
```

Ce diagnostic doit être émis uniquement quand :

```text
config.enabled == true
preset référencé existe
preset est adaptiveHeightDepth
config.casterKind == null
```

Sévérité recommandée :

```text
error
```

Raison : le preset adaptive est non résolvable sans `casterKind`, comme l'opération effective le signale déjà avec `blocked(adaptiveDepthRequiresCasterKind)`.

Ce lot n'a modifié aucun fichier Dart, aucun test, aucun JSON, aucun modèle, aucun diagnostic, aucun resolver, aucun runtime/editor. Un seul rapport Markdown est créé.

## 2. Objectif du lot

Objectif exact :

```text
Définir les diagnostics nécessaires pour signaler les incohérences entre :
- ProjectBuildingShadowPreset adaptiveHeightDepth ;
- ProjectElementProjectedBuildingShadowConfig.casterKind ;
- ProjectElementProjectedBuildingShadowConfig.enabled ;
- ProjectedBuildingShadowCatalog / presets existants ;

sans implémenter encore,
sans modifier les diagnostics,
sans modifier le modèle,
sans modifier JSON,
sans modifier resolver/runtime/editor,
sans screenshot/baseline.
```

## 3. Rappel ShadowV2-62 à ShadowV2-66

ShadowV2-62 :

- `ProjectBuildingShadowPreset` peut exprimer un preset adaptive avec `geometryMode: footprint`, `footprint: null`, `footprintStrategy: ProjectedShadowFootprintAdaptiveDepthTuning(...)`.
- Le fixed legacy reste porté par `footprint != null` et `footprintStrategy == null`.
- `ProjectedShadowFootprintFixedTuning` reste rejeté dans `ProjectBuildingShadowPreset` V0.

ShadowV2-64 :

- `ProjectElementProjectedBuildingShadowConfig` porte `casterKind: ProjectedBuildingShadowCasterKind?`.
- `casterKind` est optionnel, `null` par défaut, conservé même si `enabled == false`, inclus dans equality/hashCode.
- Valeurs existantes : `building`, `largeVolume`.

ShadowV2-66 :

- `casterKind` est persisté dans le JSON de config élément.
- `null` est omis à l'encodage.
- absence et `null` explicite décodent `null`.
- `"building"` et `"largeVolume"` décodent les deux valeurs existantes.
- valeurs inconnues et types non string non null sont rejetés.
- Diagnostics, resolver, runtime/editor, `ProjectBuildingShadowPreset JSON` et `footprintStrategy JSON` sont restés hors scope.

## 4. État initial du worktree

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Sortie initiale :

```text
```

Fichiers préexistants avant ShadowV2-67 :

```text
Aucun fichier modifié ou non suivi visible dans git status initial.
```

Fichiers hors scope déjà présents :

```text
Aucun visible dans git status initial.
```

## 5. Lecture AGENTS.md et méthode suivie

Commandes :

```bash
cd /Users/karim/Project/pokemonProject
find .. -name AGENTS.md -print
sed -n '1,320p' AGENTS.md
```

Sortie `find` :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Preuve de lecture AGENTS.md :

```text
PokeMap is a Dart/Flutter monorepo for a Pokemon-like no-code fangame editor/runtime/battle stack.
No workspace orchestrator is present: melos.yaml is absent. Run commands package by package.
Never run Git write operations unless the user explicitly asks.
Reports under reports/ are tracked engineering artifacts. Modify them only when the task asks for a report, audit, review, lot closure, or roadmap/status evidence.
Pure Dart: cd packages/map_core && dart test && dart analyze
```

Méthode réellement suivie :

- Pass 1 — audit diagnostics actuels.
- Pass 2 — audit adaptive preset / `casterKind` / JSON.
- Pass 3 — comparaison des options de diagnostic.
- Pass 4 — evidence/report et vérification Git finale.

Skills lus / utilisés :

- `superpowers:using-superpowers` : chemin annoncé absent, chemin réel trouvé sous `df858c72`.
- `karpathy-guidelines` : garder le scope design-only et éviter toute dérive.
- `superpowers:writing-plans` : lu, adapté au contrat utilisateur qui demande un rapport design gate et non un plan sous `docs/`.
- `superpowers:verification-before-completion` : utilisé pour la vérification finale avant clôture.

## 6. Fichiers créés / modifiés / supprimés

Créé par ShadowV2-67 :

```text
reports/shadows/v2/shadow_v2_67_projected_building_shadow_adaptive_guard_diagnostics_design.md
```

Modifiés par ShadowV2-67 :

```text
Aucun
```

Supprimés par ShadowV2-67 :

```text
Aucun
```

Fichiers Dart créés/modifiés :

```text
Aucun
```

Tests créés/modifiés :

```text
Aucun
```

Confirmation :

```text
Un seul rapport Markdown a été créé.
```

## 7. Audit diagnostics actuels

Commande :

```bash
rg -n "diagnoseProjectedBuildingShadows|ProjectedBuildingShadowDiagnostic|ProjectedBuildingShadowDiagnosticKind|missingPreset|missingPresetForDisabledConfig|unusedPreset|v1AndV2Coexistence|followsSunWithoutTimeOfDay|severity|error|warning|info|element|preset" packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart packages/map_core/test/shadow_v2/projected_building_shadow_diagnostics_test.dart
```

Résumé :

Kinds actuels :

```text
missingPreset
missingPresetForDisabledConfig
unusedPreset
v1AndV2Coexistence
followsSunWithoutTimeOfDay
```

Sévérités actuelles :

```text
missingPreset => error
missingPresetForDisabledConfig => warning
unusedPreset => warning
v1AndV2Coexistence => warning
followsSunWithoutTimeOfDay => info
```

Structure actuelle :

```text
ProjectedBuildingShadowDiagnostic
  severity
  kind
  message
  elementId?
  elementName?
  presetId?
  presetName?
```

Ordre actuel :

- boucle éléments dans l'ordre du manifest;
- pour chaque élément : config absente ignorée;
- preset manquant actif => `missingPreset`;
- preset manquant disabled => `missingPresetForDisabledConfig`;
- V1 + V2 enabled => `v1AndV2Coexistence`;
- ensuite boucle catalogue dans l'ordre des presets;
- preset jamais référencé => `unusedPreset`;
- preset activement référencé + `followsSun` => `followsSunWithoutTimeOfDay`.

Comportement actuel avec preset manquant :

- actif : error `missingPreset`;
- disabled : warning `missingPresetForDisabledConfig`;
- le preset absent ne fournit aucune stratégie, donc aucun diagnostic adaptive ne doit être ajouté dans ce cas.

Comportement actuel avec config disabled :

- compte comme référence pour éviter `unusedPreset`;
- ne compte pas comme référence active pour `followsSunWithoutTimeOfDay`;
- peut produire seulement le warning missing disabled si le preset est absent.

Comment ajouter un diagnostic sans casser l'existant :

- ajouter le nouveau kind à l'enum;
- ajouter un helper dédié;
- l'émettre dans la boucle éléments après résolution réussie du preset;
- ne pas changer la boucle catalogue;
- préserver les tests existants d'ordre stable.

## 8. Audit modèles ShadowV2

Commande :

```bash
rg -n "ProjectBuildingShadowPreset|ProjectElementProjectedBuildingShadowConfig|footprintStrategy|ProjectedShadowFootprintAdaptiveDepthTuning|ProjectedShadowFootprintFixedTuning|ProjectedBuildingShadowCasterKind|casterKind|enabled|presetId|geometryMode|footprint|building|largeVolume" packages/map_core/lib/src/models/projected_building_shadow.dart packages/map_core/test/shadow_v2
```

Résumé modèles :

Détection d'un preset adaptive :

```text
preset.geometryMode == ProjectedBuildingShadowGeometryMode.footprint
preset.footprint == null
preset.footprintStrategy is ProjectedShadowFootprintAdaptiveDepthTuning
```

Détection d'un preset fixed legacy :

```text
preset.geometryMode == ProjectedBuildingShadowGeometryMode.footprint
preset.footprint != null
preset.footprintStrategy == null
```

Détection directional :

```text
preset.geometryMode == ProjectedBuildingShadowGeometryMode.directional
preset.footprint == null
preset.footprintStrategy == null
```

Lecture `casterKind` :

```text
config.casterKind
```

Gestion `enabled == false` :

- le modèle conserve `casterKind`;
- les diagnostics V0 doivent éviter le bruit adaptive guard sur config disabled.

Pourquoi `ProjectedShadowFootprintFixedTuning` reste hors diagnostic V0 :

- `ProjectBuildingShadowPreset` rejette déjà `footprintStrategy fixed tuning is not supported in preset V0`;
- le fixed legacy a une source de vérité unique : `footprint`;
- diagnostiquer un `footprintStrategy fixed` dans un preset n'est pas utile tant que le modèle l'interdit.

## 9. Audit JSON / persistence casterKind

Commande :

```bash
rg -n "casterKind|ProjectedBuildingShadowCasterKind|encodeProjectedBuildingShadowCasterKind|decodeProjectedBuildingShadowCasterKind|building|largeVolume|round-trips legacy|without re-emitting|ValidationException" packages/map_core/lib/src/operations packages/map_core/test/shadow_v2 reports/shadows/v2/shadow_v2_66_projected_building_shadow_caster_kind_config_json_v0.md
```

Résumé :

- `casterKind` est durable dans `ProjectElementProjectedBuildingShadowConfig` JSON.
- Le codec dédié existe pour `ProjectedBuildingShadowCasterKind`.
- Les anciens JSON sans `casterKind` décodent `null`.
- Les JSON avec `casterKind: null` décodent `null`.
- L'encodage ne réémet pas `casterKind` quand il est `null`.
- Les valeurs inconnues et types invalides sont rejetés.

Pourquoi les diagnostics sont maintenant utiles :

- le modèle porte le guard;
- le JSON persiste le guard;
- un diagnostic map_core peut maintenant signaler une config active adaptive incomplète avant runtime/resolver.

Pourquoi ne pas rouvrir JSON au Lot 67 :

- le contrat JSON `casterKind` est déjà fermé au Lot 66;
- `footprintStrategy JSON` est explicitement hors scope;
- le Lot 67 doit décider les diagnostics, pas modifier persistence.

## 10. Audit opération effective

Commande :

```bash
rg -n "resolveProjectedShadowFootprintEffectiveTuning|adaptiveDepthRequiresCasterKind|adaptiveDepthUnsupportedCasterKind|ProjectedShadowFootprintEffectiveTuningBlocked|ProjectedBuildingShadowCasterKind|building|largeVolume|casterKind" packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart packages/map_core/test/shadow_v2/projected_shadow_footprint_effective_tuning_test.dart
```

Résumé :

Comportement actuel :

```text
fixed:
  casterKind ignoré

adaptive:
  casterKind null -> blocked(adaptiveDepthRequiresCasterKind)
  casterKind building -> resolved
  casterKind largeVolume -> resolved
```

Relation avec le diagnostic futur :

- le diagnostic `adaptivePresetRequiresCasterKind` doit être l'équivalent authoring/domain de `blocked(adaptiveDepthRequiresCasterKind)`;
- il doit signaler la donnée incomplète avant l'intégration resolver/runtime;
- il ne doit pas appeler `resolveProjectedShadowFootprintEffectiveTuning(...)`, car les diagnostics n'ont pas les `StaticShadowVisualMetrics` nécessaires et ne doivent pas résoudre de tuning effectif.

Pourquoi l'opération effective ne doit pas être modifiée au Lot 67 :

- Lot 67 est design-only;
- l'opération est déjà alignée avec le guard `casterKind`;
- le prochain pas logique est un diagnostic, pas un resolver.

## 11. Audit manifest / elements

Commande :

```bash
rg -n "ProjectElementEntry|projectedBuildingShadow|projectedBuildingShadowCatalog|ProjectBuildingShadowPresetCatalog|ProjectElementProjectedBuildingShadowConfig|toJson|fromJson|copyWith" packages/map_core/lib/src/models/project_manifest.dart packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart
```

Résumé :

- `ProjectManifest` porte `projectedBuildingShadowCatalog`.
- `ProjectElementEntry` porte `projectedBuildingShadow`.
- `projectedBuildingShadow` est un `ProjectElementProjectedBuildingShadowConfig?`.
- Le diagnostic peut joindre :
  - `manifest.elements`;
  - `element.projectedBuildingShadow`;
  - `config.presetId`;
  - `manifest.projectedBuildingShadowCatalog.presetById(config.presetId)`.
- Les éléments sans config ShadowV2 doivent rester ignorés.
- Les diagnostics `missingPreset` existants doivent rester prioritaires quand le preset référencé n'existe pas.

## 12. Problème à résoudre

Le système peut maintenant représenter :

```text
preset adaptiveHeightDepth
config élément avec casterKind nullable
casterKind persisté en JSON
```

Mais aucun diagnostic ne signale encore :

```text
config active + preset adaptiveHeightDepth + casterKind null
```

Ce cas est non résolvable par l'opération effective. Le diagnostic futur doit rendre l'erreur visible côté authoring/domain validation.

## 13. Options emplacement diagnostics

Option A — ajouter dans `diagnoseProjectedBuildingShadows(...)`.

Avantages :

- centralise les diagnostics ShadowV2;
- accès direct au manifest, éléments, config et catalogue;
- cohérent avec `missingPreset`, `unusedPreset`, `v1AndV2Coexistence`;
- pas de nouvelle API à mémoriser.

Inconvénient :

- la fonction grossit un peu;
- il faut préserver l'ordre stable.

Verdict :

```text
Recommandé.
```

Option B — nouvelle fonction `diagnoseProjectedBuildingShadowAdaptiveGuards(...)`.

Avantages :

- isolation stricte du sujet adaptive guard.

Inconvénients :

- fragmentation;
- l'appelant devrait lancer deux fonctions diagnostics;
- l'éditeur pourrait oublier un diagnostic map_core.

Verdict :

```text
Rejeté pour V0.
```

Option C — diagnostics seulement dans editor.

Avantage :

- visible dans l'UI.

Inconvénients :

- pas de garantie domaine;
- pas testable purement en map_core;
- données incohérentes possibles hors editor.

Verdict :

```text
Rejeté.
```

## 14. Diagnostic adaptive sans casterKind

Cas :

```text
config.enabled == true
preset existe
preset.footprintStrategy is ProjectedShadowFootprintAdaptiveDepthTuning
config.casterKind == null
```

Diagnostic recommandé :

```text
kind: adaptivePresetRequiresCasterKind
severity: error
```

Message recommandé :

```text
Element "<elementId>" references adaptive projected building shadow preset "<presetId>" but does not declare casterKind.
```

Pourquoi `error` :

- l'adaptive ne peut pas être résolu sans caster kind;
- `warning` ou `info` serait trop faible;
- le resolver ne doit pas être le premier endroit où l'auteur découvre le problème.

## 15. Preset missing

Cas :

```text
config.enabled == true
presetId absent du catalog
casterKind null ou non null
```

Décision :

```text
Émettre seulement missingPreset existant.
Ne pas émettre adaptivePresetRequiresCasterKind.
```

Justification :

- un preset absent n'a pas de `footprintStrategy`;
- on ne sait pas s'il est adaptive;
- ajouter un guard diagnostic serait un faux positif;
- le diagnostic principal clair est déjà `missingPreset`.

Cas disabled + preset missing :

```text
Émettre seulement missingPresetForDisabledConfig existant.
```

## 16. Config disabled

Cas :

```text
config.enabled == false
preset adaptive
casterKind null
```

Décision :

```text
Aucun adaptive guard diagnostic en V0.
```

Justification :

- une config disabled peut conserver une intention authoring;
- elle ne bloque pas le rendu courant;
- le comportement existant évite déjà `followsSunWithoutTimeOfDay` pour les références non actives;
- le diagnostic doit rester non bruyant.

## 17. casterKind sur fixed legacy

Cas :

```text
config.enabled == true
preset fixed legacy
config.casterKind != null
```

Décision V0 :

```text
Aucun diagnostic.
```

Justification :

- fixed legacy ignore `casterKind`;
- ce n'est pas dangereux;
- émettre `info` ou `warning` pourrait créer du bruit d'authoring;
- priorité Lot 68 : signaler uniquement le cas adaptive non résolvable.

Nom conceptuel possible pour plus tard, non V0 :

```text
casterKindIgnoredForFixedPreset
```

## 18. casterKind sur config disabled

Cas :

```text
config.enabled == false
casterKind != null
```

Décision :

```text
Aucun diagnostic.
```

Justification :

- le modèle conserve déjà `casterKind` sur config disabled;
- cela peut représenter une intention authoring mise en pause;
- un diagnostic serait du bruit.

## 19. casterKind incompatible futur

État actuel :

```text
ProjectedBuildingShadowCasterKind.building
ProjectedBuildingShadowCasterKind.largeVolume
```

Les deux valeurs sont compatibles adaptive.

L'opération effective prévoit déjà :

```text
adaptiveDepthUnsupportedCasterKind
```

Décision :

```text
Prévoir conceptuellement adaptivePresetUnsupportedCasterKind,
mais ne pas l'implémenter au Lot 68 V0.
```

Justification :

- impossible à déclencher aujourd'hui sans nouvelle valeur enum;
- l'ajouter maintenant créerait du code mort;
- le nom reste utile pour le jour où un caster kind incompatible existera.

## 20. Ordre des diagnostics

Ordre recommandé pour Lot 68 :

1. Boucle éléments dans l'ordre du manifest.
2. Ignorer les éléments sans `projectedBuildingShadow`.
3. Ajouter `referencedPresetIds` comme aujourd'hui.
4. Ajouter `activelyReferencedPresetIds` seulement si `config.enabled`.
5. Résoudre `preset = catalog.presetById(config.presetId)`.
6. Si `preset == null`, émettre seulement le missing diagnostic existant et ne pas émettre de guard adaptive.
7. Si `preset != null` et `config.enabled == true` et preset adaptive et `config.casterKind == null`, émettre `adaptivePresetRequiresCasterKind`.
8. Si `config.enabled == true` et `element.shadow != null`, émettre `v1AndV2Coexistence`.
9. Boucle catalogue inchangée : `unusedPreset`, puis `followsSunWithoutTimeOfDay`.

Ordre des diagnostics pour un même élément actif avec preset adaptive sans caster et Shadow V1 présent :

```text
adaptivePresetRequiresCasterKind
v1AndV2Coexistence
```

Raison : l'erreur de non-résolution adaptive est plus spécifique au preset/config, et le warning V1/V2 reste ensuite.

## 21. Structure du diagnostic futur

Nouveau kind recommandé :

```text
ProjectedBuildingShadowDiagnosticKind.adaptivePresetRequiresCasterKind
```

Diagnostic recommandé :

```text
ProjectedBuildingShadowDiagnostic(
  severity: ProjectedBuildingShadowDiagnosticSeverity.error,
  kind: ProjectedBuildingShadowDiagnosticKind.adaptivePresetRequiresCasterKind,
  message:
      'Element "<elementId>" references adaptive projected building shadow preset "<presetId>" but does not declare casterKind.',
  elementId: element.id,
  elementName: element.name,
  presetId: config.presetId,
  presetName: preset.name,
)
```

Détection adaptive recommandée :

```text
preset.geometryMode == ProjectedBuildingShadowGeometryMode.footprint
preset.footprintStrategy is ProjectedShadowFootprintAdaptiveDepthTuning
```

Le check `geometryMode == footprint` est redondant avec les validations modèle, mais le garder dans l'intention de test/documentation rend le diagnostic plus lisible.

## 22. Tests futurs Lot 68

Tests indispensables V0 :

```text
diagnoseProjectedBuildingShadows reports adaptivePresetRequiresCasterKind for active adaptive preset without casterKind
diagnoseProjectedBuildingShadows does not report adaptive guard for active adaptive preset with building casterKind
diagnoseProjectedBuildingShadows does not report adaptive guard for active adaptive preset with largeVolume casterKind
diagnoseProjectedBuildingShadows does not report adaptive guard when preset is missing
diagnoseProjectedBuildingShadows does not report adaptive guard when config is disabled
diagnoseProjectedBuildingShadows preserves existing missingPreset diagnostics
diagnoseProjectedBuildingShadows preserves existing unusedPreset diagnostics
diagnoseProjectedBuildingShadows keeps adaptive guard before V1/V2 coexistence for the same active element
diagnoseProjectedBuildingShadows keeps stable element diagnostics then catalog diagnostics order with adaptive guard included
```

Tests explicitement non V0 :

```text
diagnoseProjectedBuildingShadows reports info/warning when casterKind is set on fixed legacy preset
diagnoseProjectedBuildingShadows reports adaptivePresetUnsupportedCasterKind
```

## 23. Option recommandée

Option recommandée :

```text
Ajouter adaptivePresetRequiresCasterKind dans diagnoseProjectedBuildingShadows(...)
```

Design recommandé :

- fonction : `diagnoseProjectedBuildingShadows(...)`;
- nouveau diagnostic kind V0 : `adaptivePresetRequiresCasterKind`;
- sévérité : `error`;
- cas adaptive active sans caster : émettre le nouveau diagnostic;
- cas preset missing : émettre seulement `missingPreset` ou `missingPresetForDisabledConfig`;
- cas config disabled : aucun adaptive guard diagnostic;
- cas `casterKind` sur fixed : aucun diagnostic V0;
- cas `casterKind` incompatible futur : nom conceptuel `adaptivePresetUnsupportedCasterKind`, non implémenté V0;
- ordre : dans la boucle éléments, après résolution du preset existant, avant `v1AndV2Coexistence`, puis catalogue inchangé;
- tests Lot 68 : ciblés sur diagnostics map_core existants.

Pourquoi :

- c'est le plus petit changement utile;
- cela aligne authoring/domain validation avec `blocked(adaptiveDepthRequiresCasterKind)`;
- cela évite les faux positifs sur preset missing;
- cela évite le bruit sur config disabled et fixed legacy;
- cela préserve l'API diagnostics unique.

Pourquoi les autres options sont rejetées :

- nouvelle fonction : fragmentation et risque d'oubli par les appelants;
- editor-only : pas de garantie pure domain;
- warning/info : trop faible pour un état non résolvable;
- diagnostic sur fixed : bruit V0;
- unsupported caster kind V0 : impossible à déclencher avec l'enum actuelle.

Lot 68 doit faire :

- modifier `projected_building_shadow_diagnostics.dart`;
- modifier `projected_building_shadow_diagnostics_test.dart`;
- ajouter `adaptivePresetRequiresCasterKind`;
- tester les cas active adaptive sans caster, building, largeVolume, missing preset, disabled config et ordre stable;
- créer le rapport Lot 68.

Lot 68 ne doit pas faire :

- modifier modèle;
- modifier JSON/codecs;
- modifier resolver;
- modifier opération effective;
- modifier runtime/editor;
- modifier `ProjectBuildingShadowPreset JSON`;
- ajouter `footprintStrategy JSON`;
- créer screenshot/baseline;
- toucher Selbrume.

## 24. Plan précis du Lot 68

Nom recommandé :

```text
ShadowV2-68 — Projected Building Shadow Adaptive Guard Diagnostics V0
```

Objectif :

```text
Implémenter le diagnostic adaptivePresetRequiresCasterKind dans diagnoseProjectedBuildingShadows(...),
avec tests map_core,
sans resolver,
sans runtime/editor,
sans JSON,
sans footprintStrategy JSON.
```

Périmètre probable :

Modifier :

```text
packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart
packages/map_core/test/shadow_v2/projected_building_shadow_diagnostics_test.dart
```

Créer :

```text
reports/shadows/v2/shadow_v2_68_projected_building_shadow_adaptive_guard_diagnostics_v0.md
```

Étapes recommandées :

1. Ajouter les tests RED dans `projected_building_shadow_diagnostics_test.dart`.
2. Ajouter `ProjectedBuildingShadowDiagnosticKind.adaptivePresetRequiresCasterKind`.
3. Ajouter un helper `_adaptivePresetRequiresCasterKindDiagnostic(...)`.
4. Ajouter une détection pure du preset adaptive dans `diagnoseProjectedBuildingShadows(...)`.
5. Émettre le diagnostic seulement si le preset existe, config active et `casterKind == null`.
6. Préserver les diagnostics existants et l'ordre stable.
7. Lancer les tests ciblés diagnostics, les régressions utiles ShadowV2, `dart test test/shadow_v2`, analyze ciblé et audit anti-dérive.
8. Créer le rapport Lot 68.

## 25. Fichiers explicitement interdits au Lot 68

```text
packages/map_core/lib/src/models/projected_building_shadow.dart
packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart
packages/map_core/lib/src/operations/projected_shadow_value_object_json_codecs.dart
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart
packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart
packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/project_manifest.freezed.dart
packages/map_core/lib/src/models/project_manifest.g.dart
packages/map_core/lib/src/models/map_data.dart
packages/map_core/lib/src/models/map_data.freezed.dart
packages/map_core/lib/src/models/map_data.g.dart
packages/map_runtime/**
packages/map_editor/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
reports/shadows/screenshots/**
reports/shadows/baselines/**
/Users/karim/Desktop/selbrume/**
project.json
```

## 26. Risques / réserves

- Le diagnostic V0 ne signale pas `casterKind` présent sur fixed legacy; c'est un choix anti-bruit.
- Le diagnostic V0 ne signale pas les configs disabled; c'est cohérent avec les diagnostics existants, mais l'éditeur pourra plus tard choisir d'afficher une intention disabled.
- `adaptivePresetUnsupportedCasterKind` reste conceptuel tant que `building` et `largeVolume` sont les seules valeurs enum.
- `footprintStrategy JSON` reste non traité; les presets adaptive existent en modèle mémoire, pas encore en persistence preset.

## 27. Auto-critique

- Le lot est bien design-only : oui, seul ce rapport est créé.
- Le rapport évite de coder dans un design gate : oui.
- Le rapport garde JSON hors implémentation : oui.
- Le rapport garde resolver/runtime/editor hors scope : oui.
- Le rapport ne rouvre pas `footprintStrategy JSON` : oui.
- Le diagnostic recommandé évite les faux positifs sur preset missing : oui, missing reste le seul diagnostic dans ce cas.
- Le diagnostic recommandé évite le bruit sur config disabled : oui, aucun adaptive guard disabled.
- Le plan Lot 68 est assez petit : oui, deux fichiers map_core et un rapport.
- Le rapport contient les preuves demandées : oui, commandes, audits, git outputs et décisions sont documentés.

## 28. Regard critique sur le prompt

Le prompt protège bien le périmètre en séparant diagnostic design, modèle, JSON et resolver. Le point le plus important est la règle preset missing : sans elle, le futur diagnostic pourrait inventer un état adaptive pour un preset absent. Le prompt insiste aussi correctement sur config disabled, ce qui évite un diagnostic bruyant sur des intentions authoring mises en pause.

## 29. Commandes lancées

```bash
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/004da724/skills/using-superpowers/SKILL.md
sed -n '1,220p' /Users/karim/.codex/skills/karpathy-guidelines/SKILL.md
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/004da724/skills/writing-plans/SKILL.md
find /Users/karim/.codex -path '*using-superpowers*/SKILL.md' -print
find /Users/karim/.codex -path '*writing-plans*/SKILL.md' -print
find /Users/karim/.codex -path '*verification-before-completion*/SKILL.md' -print
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/df858c72/skills/using-superpowers/SKILL.md
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/df858c72/skills/writing-plans/SKILL.md
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/df858c72/skills/verification-before-completion/SKILL.md
git status --short --untracked-files=all
find .. -name AGENTS.md -print
sed -n '1,320p' AGENTS.md
rg -n "diagnoseProjectedBuildingShadows|ProjectedBuildingShadowDiagnostic|ProjectedBuildingShadowDiagnosticKind|missingPreset|missingPresetForDisabledConfig|unusedPreset|v1AndV2Coexistence|followsSunWithoutTimeOfDay|severity|error|warning|info|element|preset" packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart packages/map_core/test/shadow_v2/projected_building_shadow_diagnostics_test.dart
rg -n "ProjectBuildingShadowPreset|ProjectElementProjectedBuildingShadowConfig|footprintStrategy|ProjectedShadowFootprintAdaptiveDepthTuning|ProjectedShadowFootprintFixedTuning|ProjectedBuildingShadowCasterKind|casterKind|enabled|presetId|geometryMode|footprint|building|largeVolume" packages/map_core/lib/src/models/projected_building_shadow.dart packages/map_core/test/shadow_v2
rg -n "casterKind|ProjectedBuildingShadowCasterKind|encodeProjectedBuildingShadowCasterKind|decodeProjectedBuildingShadowCasterKind|building|largeVolume|round-trips legacy|without re-emitting|ValidationException" packages/map_core/lib/src/operations packages/map_core/test/shadow_v2 reports/shadows/v2/shadow_v2_66_projected_building_shadow_caster_kind_config_json_v0.md
rg -n "resolveProjectedShadowFootprintEffectiveTuning|adaptiveDepthRequiresCasterKind|adaptiveDepthUnsupportedCasterKind|ProjectedShadowFootprintEffectiveTuningBlocked|ProjectedBuildingShadowCasterKind|building|largeVolume|casterKind" packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart packages/map_core/test/shadow_v2/projected_shadow_footprint_effective_tuning_test.dart
rg -n "ProjectElementEntry|projectedBuildingShadow|projectedBuildingShadowCatalog|ProjectBuildingShadowPresetCatalog|ProjectElementProjectedBuildingShadowConfig|toJson|fromJson|copyWith" packages/map_core/lib/src/models/project_manifest.dart packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart
sed -n '1,210p' packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart
sed -n '295,365p' packages/map_core/test/shadow_v2/projected_building_shadow_diagnostics_test.dart
sed -n '450,775p' packages/map_core/lib/src/models/projected_building_shadow.dart
sed -n '100,230p' packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart
sed -n '54,90p' packages/map_core/lib/src/models/project_manifest.dart
sed -n '422,445p' packages/map_core/lib/src/models/project_manifest.dart
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

Tests :

```text
Aucun test lancé. Le lot est design-only et le prompt demande explicitement de ne pas lancer les tests.
```

## 30. git diff --stat

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git diff --stat
```

Sortie finale attendue pour les fichiers suivis :

```text
```

Explication :

```text
Le seul fichier du lot est un rapport Markdown non suivi; git diff --stat ne liste pas les fichiers non suivis.
```

## 31. git diff --name-status

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git diff --name-status
```

Sortie finale attendue pour les fichiers suivis :

```text
```

Explication :

```text
Aucun fichier suivi n'a été modifié.
```

## 32. git diff --check

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git diff --check
```

Sortie finale attendue :

```text
```

Résultat attendu : aucune erreur whitespace sur les fichiers suivis modifiés, car aucun fichier suivi n'a été modifié.

## 33. git status final

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Sortie finale attendue :

```text
?? reports/shadows/v2/shadow_v2_67_projected_building_shadow_adaptive_guard_diagnostics_design.md
```

Checklist finale :

- [x] Design-only respecté
- [x] Aucun fichier de production modifié
- [x] Aucun test créé/modifié
- [x] Aucun fichier map_core modifié
- [x] Aucun fichier map_runtime modifié
- [x] Aucun fichier map_editor modifié
- [x] Aucun fichier Selbrume modifié
- [x] Aucun generated modifié
- [x] Aucun screenshot créé
- [x] Aucune baseline créée
- [x] AGENTS.md lu
- [x] Diagnostics actuels audités
- [x] Modèles ShadowV2 audités
- [x] JSON casterKind audité
- [x] Opération effective auditée
- [x] Manifest/elements audités
- [x] Emplacement diagnostics tranché
- [x] Adaptive sans casterKind tranché
- [x] Preset missing tranché
- [x] Config disabled tranché
- [x] casterKind sur fixed tranché
- [x] casterKind incompatible futur tranché
- [x] Ordre diagnostics tranché
- [x] Tests futurs Lot 68 listés
- [x] Option recommandée unique
- [x] Plan ShadowV2-68 précis
- [x] Fichiers interdits au Lot 68 listés
- [x] Evidence Pack complet
- [x] git diff --check propre
- [x] git status final conforme au scope ou fichiers hors scope documentés
