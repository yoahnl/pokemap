# ShadowV2-59 — Projected Building Shadow Adaptive Depth Effective Tuning Resolver Design Gate

## 1. Résumé exécutif

ShadowV2-59 est un design gate strictement lecture seule, hors création de ce rapport. Le Lot 58 a bien posé les value objects purs de stratégie, mais il n'a pas encore défini l'opération qui transforme une stratégie fixed/adaptive en tuning réellement utilisable par la géométrie footprint.

Option recommandée : créer au Lot 60 une opération pure dédiée :

```text
resolveProjectedShadowFootprintEffectiveTuning(...)
```

Cette opération doit rester séparée de `resolveProjectedBuildingShadowGeometry(...)`. Elle doit recevoir une stratégie de tuning, les métriques visuelles, une opacité fixed explicite issue du futur appelant, et un `ProjectedBuildingShadowCasterKind?`. Elle doit retourner un result object explicite capable de représenter soit un tuning résolu, soit un blocage guard.

Décision centrale :

```text
Fixed -> resolved tuning + fixedOpacity + adaptiveT = 0
Adaptive + casterKind building/largeVolume -> resolved tuning + interpolated opacity + adaptiveT
Adaptive + casterKind null/incompatible -> blocked result
```

Le Lot 60 recommandé est un V0 pur map_core, sans branchement du resolver existant, sans JSON, sans runtime/editor, sans screenshot/baseline.

## 2. Objectif du lot

Objectif exécuté :

```text
Définir comment calculer proprement un tuning effectif à partir des nouveaux value objects ShadowV2 Adaptive Depth,
sans implémenter encore,
sans brancher le resolver de géométrie existant,
sans JSON,
sans runtime,
sans editor,
sans renderer/painter,
sans Selbrume,
sans screenshot,
sans baseline.
```

Ce rapport répond aux questions demandées :

1. Opération pure recommandée : `resolveProjectedShadowFootprintEffectiveTuning(...)`.
2. Inputs : stratégie, metrics, fixed opacity, caster kind optionnel.
3. Output : result object union-like resolved/blocked.
4. Fixed vs Adaptive : fixed résout directement, adaptive interpole sous guard.
5. `ProjectedBuildingShadowCasterKind` intervient uniquement comme garde d'autorisation adaptive.
6. Adaptive sans caster compatible produit un résultat `blocked`.
7. Pas de null, pas de fallback silencieux, pas d'exception pour le flux normal.
8. L'opacité effective est retournée avec le tuning.
9. L'opération reste pure map_core et ne lit ni editor ni runtime.
10. Le futur branchement resolver pourra consommer le result object sans changer la formule footprint.
11. Lot 60 doit être un Pure Resolver V0.

## 3. Rappel ShadowV2-58

Le Lot 58 a ajouté dans `packages/map_core/lib/src/models/projected_building_shadow.dart` :

```text
ProjectedShadowFootprintTuningStrategy
ProjectedShadowFootprintFixedTuning
ProjectedShadowFootprintAdaptiveDepthTuning
ProjectedShadowAdaptiveDepthGate
ProjectedBuildingShadowCasterKind
```

Le Lot 58 a volontairement laissé hors scope :

```text
resolver
effective tuning calculation
adaptiveT calculation
ProjectBuildingShadowPreset integration
ProjectElementProjectedBuildingShadowConfig integration
JSON/persistence
runtime/editor integration
renderer/painter integration
diagnostics
Selbrume
screenshots/baselines
```

Le Lot 59 s'appuie sur ces types, mais ne les modifie pas.

## 4. État initial du worktree

Commande exécutée avant création du rapport :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
```

Fichiers préexistants non liés au Lot 59 : Aucun.

## 5. Lecture AGENTS.md et méthode suivie

Commandes exécutées :

```bash
find .. -name AGENTS.md -print
sed -n '1,320p' AGENTS.md
```

Sortie `find` :

```text
../pokemonProject-worktree/AGENTS.md
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Règles AGENTS.md appliquées :

- lot scoped, modifications minimales ;
- aucun git write ;
- `reports/` modifié seulement parce que le lot demande un rapport ;
- `map_core` reste pure Dart ;
- pas de tests pour ce lot design-only ;
- preuves et inventaire dans le rapport ;
- statut git final documenté.

Skills réellement lus / appliqués :

- `superpowers:using-superpowers` : vérification de discipline de skills.
- `karpathy-guidelines` : scope minimal, pas d'élargissement.
- `superpowers:verification-before-completion` : preuves avant final.
- `superpowers:writing-plans` : lu car le lot prépare un prochain plan, mais non appliqué à la lettre car il demanderait un fichier de plan sous `docs/`, interdit par le contrat Lot 59.

Sub-agents : AGENTS.md ne rend pas de sub-agent obligatoire. Passes équivalentes réalisées :

- Pass 1 — Audit modèle V0.
- Pass 2 — Analyse resolver effectif.
- Pass 3 — Design options.
- Pass 4 — Evidence/report.

## 6. Fichiers créés / modifiés / supprimés

Créés par ShadowV2-59 :

- `reports/shadows/v2/shadow_v2_59_projected_building_shadow_adaptive_depth_effective_tuning_resolver_design.md`

Modifiés par ShadowV2-59 : Aucun fichier préexistant.

Supprimés par ShadowV2-59 : Aucun.

Fichiers Dart créés/modifiés : Aucun.

Screenshots / baselines créés : Aucun.

Generated créés : Aucun.

## 7. Audit modèle V0

Commande obligatoire :

```bash
rg -n "ProjectedShadowFootprintTuningStrategy|ProjectedShadowFootprintFixedTuning|ProjectedShadowFootprintAdaptiveDepthTuning|ProjectedShadowAdaptiveDepthGate|ProjectedBuildingShadowCasterKind|referenceHeight|targetHeight|referenceRatio|targetRatio|baseOpacity|targetOpacity" packages/map_core/lib/src/models/projected_building_shadow.dart packages/map_core/test/shadow_v2/projected_shadow_footprint_strategy_test.dart reports/shadows/v2/shadow_v2_58_projected_building_shadow_adaptive_depth_core_model_v0.md
```

Hits structurants observés :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart:21:enum ProjectedBuildingShadowCasterKind {
packages/map_core/lib/src/models/projected_building_shadow.dart:262:sealed class ProjectedShadowFootprintTuningStrategy {
packages/map_core/lib/src/models/projected_building_shadow.dart:267:final class ProjectedShadowFootprintFixedTuning
packages/map_core/lib/src/models/projected_building_shadow.dart:285:final class ProjectedShadowAdaptiveDepthGate {
packages/map_core/lib/src/models/projected_building_shadow.dart:287:    double referenceHeight = 80,
packages/map_core/lib/src/models/projected_building_shadow.dart:288:    double targetHeight = 112,
packages/map_core/lib/src/models/projected_building_shadow.dart:289:    double referenceRatio = 1.25,
packages/map_core/lib/src/models/projected_building_shadow.dart:290:    double targetRatio = 1.75,
packages/map_core/lib/src/models/projected_building_shadow.dart:357:final class ProjectedShadowFootprintAdaptiveDepthTuning
packages/map_core/lib/src/models/projected_building_shadow.dart:363:    required double baseOpacity,
packages/map_core/lib/src/models/projected_building_shadow.dart:364:    required double targetOpacity,
```

Résumé du modèle V0 :

- `ProjectedShadowFootprintTuningStrategy` est une base sealed.
- `ProjectedShadowFootprintFixedTuning` stocke un tuning explicite.
- `ProjectedShadowFootprintAdaptiveDepthTuning` stocke base, target, gate, baseOpacity, targetOpacity.
- `ProjectedShadowAdaptiveDepthGate` valide les seuils hauteur/ratio.
- `ProjectedBuildingShadowCasterKind` expose `building` et `largeVolume`.

Validations déjà présentes :

- gate : hauteurs/ratios positifs et target > reference ;
- opacités adaptive : `[0, 1]` ;
- `ProjectedShadowFootprintTuning` : ratios bornés selon le modèle existant.

Ce que le Lot 58 ne branche pas :

- aucun champ `footprintStrategy` dans `ProjectBuildingShadowPreset` ;
- aucun `casterKind` dans `ProjectElementProjectedBuildingShadowConfig` ;
- aucun calcul `adaptiveT` ;
- aucune opération effective ;
- aucun resolver existant modifié ;
- aucun JSON.

Pourquoi Lot 59 reste design-only : le modèle V0 est posé, mais la bonne frontière entre stratégie, guard, result object et resolver doit être décidée avant d'écrire l'opération.

## 8. Audit resolver existant

Commande obligatoire :

```bash
rg -n "resolveProjectedBuildingShadowGeometry|_resolveDirectionalProjectedBuildingShadowGeometry|_resolveFootprintProjectedBuildingShadowGeometry|ProjectedShadowFootprintTuning|ProjectedShadowAppearance|StaticShadowVisualMetrics|ProjectElementProjectedBuildingShadowConfig|opacity|colorHexRgb|geometryMode|footprint" packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
```

Hits structurants observés :

```text
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:63:ProjectedBuildingShadowGeometry? resolveProjectedBuildingShadowGeometry({
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:64:  required ProjectElementProjectedBuildingShadowConfig config,
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:66:  required StaticShadowVisualMetrics metrics,
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:72:  return switch (preset.geometryMode) {
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:79:    ProjectedBuildingShadowGeometryMode.footprint =>
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:140:ProjectedBuildingShadowGeometry _resolveFootprintProjectedBuildingShadowGeometry({
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:145:  final footprint = preset.footprint!;
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:149:      metrics.visualHeight * footprint.attachYRatio +
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:152:  final frontWidth = metrics.visualWidth * footprint.frontWidthRatio;
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:153:  final rearWidth = metrics.visualWidth * footprint.rearWidthRatio;
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:154:  final depth = metrics.visualHeight * footprint.depthRatio;
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:156:  final rearCenterX = centerX + metrics.visualWidth * footprint.skewXRatio;
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:178:    opacity: preset.appearance.opacity,
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:179:    colorHexRgb: preset.appearance.colorHexRgb,
```

Résumé :

- Le resolver actuel choisit `directional` ou `footprint` selon `preset.geometryMode`.
- Le footprint actuel lit directement `preset.footprint!`.
- L'opacité actuelle vient de `preset.appearance.opacity`.
- La couleur actuelle vient de `preset.appearance.colorHexRgb`.
- Le resolver ne reçoit pas de `ProjectedShadowFootprintTuningStrategy`.
- Le resolver ne reçoit pas de `ProjectedBuildingShadowCasterKind`.

Inputs disponibles aujourd'hui :

- `ProjectElementProjectedBuildingShadowConfig config`
- `ProjectBuildingShadowPreset preset`
- `StaticShadowVisualMetrics metrics`

Inputs manquants pour adaptive :

- stratégie fixed/adaptive ;
- caster kind explicite ;
- opacité fixed passée comme input à une opération effective ;
- result object pour blocage guard.

Pourquoi ne pas brancher Adaptive C+ directement ici maintenant :

- cela mélangerait la dérivation du tuning avec la construction du polygone ;
- le guard building-only deviendrait difficile à tester isolément ;
- le resolver devrait gérer un état bloqué sans result object défini ;
- `ProjectBuildingShadowPreset` ne porte pas encore de stratégie ;
- JSON/editor/runtime ne sont pas prêts à authorer la stratégie.

Opération intermédiaire nécessaire : une fonction pure qui transforme une stratégie + metrics + guard en résultat effectif, avant toute géométrie.

## 9. Audit config élément / guard futur

Commande obligatoire :

```bash
rg -n "ProjectElementProjectedBuildingShadowConfig|ProjectElementEntry|MapPlacedElement|shadowOverride|StaticShadowFamily|building|largeVolume|casterKind|categoryId|presetKind|projectedBuildingShadow" packages/map_core/lib/src/models packages/map_core/test/shadow_v2
```

Hits structurants observés :

```text
packages/map_core/lib/src/models/project_manifest.dart:422:class ProjectElementEntry with _$ProjectElementEntry {
packages/map_core/lib/src/models/project_manifest.dart:428:    required String categoryId,
packages/map_core/lib/src/models/project_manifest.dart:433:    @Default(ElementPresetKind.generic) ElementPresetKind presetKind,
packages/map_core/lib/src/models/project_manifest.dart:443:    ProjectElementProjectedBuildingShadowConfig? projectedBuildingShadow,
packages/map_core/lib/src/models/map_data.dart:99:class MapPlacedElement with _$MapPlacedElement {
packages/map_core/lib/src/models/map_data.dart:110:    MapPlacedElementShadowOverride? shadowOverride,
packages/map_core/lib/src/models/shadow.dart:44:enum StaticShadowFamily {
packages/map_core/lib/src/models/shadow.dart:48:  building,
packages/map_core/lib/src/models/projected_building_shadow.dart:21:enum ProjectedBuildingShadowCasterKind {
```

Où le guard pourrait être branché plus tard :

- élément : `ProjectElementEntry` pourrait porter une sémantique durable ;
- config projetée : `ProjectElementProjectedBuildingShadowConfig` pourrait porter un opt-in spécifique ;
- instance placée : `MapPlacedElement` / override pourrait porter un opt-in très fin, mais lourd ;
- diagnostics/editor : peuvent empêcher les combinaisons incohérentes.

Pourquoi Lot 59 ne tranche pas le champ d'intégration :

- ce lot ne doit pas modifier modèle/JSON ;
- plusieurs emplacements restent plausibles ;
- choisir le champ maintenant sans authoring design risquerait de figer trop tôt la persistance.

Pourquoi le calcul effectif doit recevoir `casterKind` explicitement :

- l'opération pure ne doit pas inspecter `ProjectElementEntry`, `MapPlacedElement`, `categoryId`, editor ou runtime ;
- l'appelant futur décidera comment obtenir le caster kind ;
- l'opération reste testable avec un input simple.

Pourquoi `ProjectElementEntry.categoryId` n'est pas un guard suffisant :

- c'est une catégorie/catalogue authoring, pas une sémantique métier garantie ;
- les valeurs sont des chaînes libres ;
- elle peut servir au rangement UI sans garantir que l'objet est un grand volume ;
- elle ne protège pas contre un prop fin rangé dans une catégorie mal nommée.

Props fins :

- hors scope ;
- le canary `thin_prop_like_2x6` du Lot 56 montre qu'une silhouette fine peut déclencher partiellement la formule ;
- ce n'est pas un bug de la formule, c'est la preuve qu'un guard sémantique est obligatoire.

## 10. Problème à résoudre

Le système a maintenant deux représentations conceptuelles :

```text
fixed tuning -> utiliser tel quel
adaptiveHeightDepth tuning -> dériver un tuning effectif selon metrics
```

Mais le resolver actuel consomme seulement :

```text
ProjectedShadowFootprintTuning
ProjectedShadowAppearance.opacity
ProjectedShadowAppearance.colorHexRgb
```

Il faut donc définir une étape pure :

```text
strategy + metrics + casterKind + fixedOpacity -> effective tuning result
```

Cette étape doit :

- calculer `adaptiveT` uniquement pour adaptive ;
- interpoler tuning et opacity ;
- bloquer adaptive si le caster n'est pas compatible ;
- ne pas construire de points géométriques ;
- ne pas muter `ProjectedShadowAppearance` ;
- ne pas lire de données editor/runtime.

## 11. Options d’opération effective

### Option A — Calculer directement dans resolveProjectedBuildingShadowGeometry(...)

Avantages :

- branchement direct futur ;
- moins de fonctions.

Inconvénients :

- mélange tuning et géométrie ;
- complique le guard ;
- rend les tests moins ciblés ;
- force le resolver à porter des décisions de stratégie.

Verdict : rejeté pour le premier branchement.

### Option B — Opération pure dédiée resolveProjectedShadowFootprintEffectiveTuning(...)

Inputs conceptuels :

```text
ProjectedShadowFootprintTuningStrategy strategy
StaticShadowVisualMetrics metrics
double fixedOpacity
ProjectedBuildingShadowCasterKind? casterKind
```

Avantages :

- testable en isolation ;
- sépare stratégie et géométrie ;
- prépare le resolver sans le modifier au Lot 60 ;
- permet un result object blocked ;
- garde editor/runtime hors de la règle.

Inconvénient :

- ajoute une opération et quelques value objects de résultat.

Verdict : recommandé.

### Option C — Méthode sur ProjectedShadowFootprintTuningStrategy

Exemple conceptuel :

```text
strategy.resolveEffectiveTuning(metrics, casterKind)
```

Avantages :

- encapsulation directe avec la stratégie.

Inconvénients :

- met de la logique calculatoire dans les value objects ;
- moins cohérent avec les opérations déjà séparées (`projected_building_shadow_geometry.dart`, `static_shadow_geometry.dart`) ;
- rend le modèle moins passif.

Verdict : rejeté.

### Option D — Resolver editor-only / runtime-only

Avantages :

- pas de nouvelle opération map_core.

Inconvénients :

- divergence possible editor/runtime ;
- règle cachée hors domaine ;
- tests plus difficiles ;
- risque d'application incohérente.

Verdict : rejeté.

## 12. Options de result object

### Result A — Retourner directement ProjectedShadowFootprintTuning

Avantages :

- très simple.

Inconvénients :

- perd l'opacité effective ;
- ne représente pas le guard bloqué ;
- ne remonte pas `adaptiveT` pour tests/diagnostics.

Verdict : rejeté.

### Result B — Retourner record / tuple

Exemple :

```text
(ProjectedShadowFootprintTuning, double opacity, double adaptiveT)
```

Avantages :

- compact.

Inconvénients :

- peu explicite ;
- fragile en tests ;
- impossible de représenter proprement blocked.

Verdict : rejeté.

### Result C — Value object dédié uniquement success

Exemple :

```text
ProjectedShadowEffectiveFootprintTuning
```

Champs :

```text
tuning
opacity
adaptiveT
strategyKind
```

Avantages :

- clair pour le cas résolu ;
- inclut l'opacité et `adaptiveT`.

Inconvénients :

- ne représente pas le guard incompatible.

Verdict : insuffisant seul, mais à utiliser comme payload du success.

### Result D — Union result success / blocked

Concept :

```text
ProjectedShadowFootprintEffectiveTuningResult
  resolved(ProjectedShadowEffectiveFootprintTuning)
  blocked(ProjectedShadowFootprintEffectiveTuningBlockReason)
```

Avantages :

- explicite ;
- testable ;
- ne masque pas une incohérence ;
- prépare diagnostics/editor sans coupler l'opération.

Inconvénients :

- ajoute deux ou trois types.

Verdict : recommandé.

## 13. Décision guard incompatible

Cas critique :

```text
strategy = adaptiveHeightDepth
casterKind = null
ou casterKind non compatible
```

Options :

- `throw ValidationException` : strict, mais trop violent pour diagnostics/editor futurs.
- `return null` : ambigu, confond disabled/no geometry/block.
- fixed base fallback : dangereux, masque une donnée incohérente.
- diagnostic only elsewhere : risque que le resolver construise quand même une géométrie.
- blocked result : explicite et testable.

Décision : utiliser un blocked result.

Block reasons recommandées :

```text
adaptiveDepthRequiresCasterKind
adaptiveDepthUnsupportedCasterKind
```

Aujourd'hui l'enum `ProjectedBuildingShadowCasterKind` ne contient que `building` et `largeVolume`, donc `unsupported` est surtout une réserve de nommage si l'enum évolue. Pour V0, `casterKind == null` est le blocage principal.

## 14. Décision casterKind input

Options :

```text
ProjectedBuildingShadowCasterKind? casterKind
bool allowAdaptiveDepth
contexte riche
```

Décision : `ProjectedBuildingShadowCasterKind? casterKind`.

Pourquoi :

- sémantique claire ;
- cohérent avec le Lot 58 ;
- prépare les diagnostics ;
- permet de distinguer absence de guard et guard incompatible ;
- évite de coupler l'opération à `ProjectElementEntry`, `MapPlacedElement`, editor ou runtime.

`bool allowAdaptiveDepth` est rejeté : trop opaque et perd l'intention.

Un contexte riche est rejeté pour V0 : trop tôt, risque de couplage et de drift.

## 15. Décision opacité effective

Décision : l'opération effective doit retourner l'opacité effective.

Raison :

- Adaptive C+ modifie aussi l'opacité (`0.24 -> 0.22`) ;
- sans opacity dans le résultat, une partie de la stratégie serait cachée ailleurs ;
- le futur resolver de géométrie pourra produire `ProjectedBuildingShadowGeometry.opacity` depuis ce résultat.

Règle recommandée :

```text
fixed:
  opacity = fixedOpacity
  adaptiveT = 0

adaptive:
  opacity = lerp(baseOpacity, targetOpacity, adaptiveT)
```

L'opération ne doit pas modifier `ProjectedShadowAppearance`. Elle reçoit seulement l'opacité fixed existante sous forme de `double fixedOpacity`. `colorHexRgb` reste hors de l'opération effective et continue d'être porté par l'apparence / futur resolver géométrique.

## 16. Décision clamp / lerp / metrics

Formule conceptuelle recommandée :

```text
heightGate = clamp((metrics.visualHeight - gate.referenceHeight) / (gate.targetHeight - gate.referenceHeight), 0, 1)
ratioGate = clamp((metrics.visualHeight / metrics.visualWidth - gate.referenceRatio) / (gate.targetRatio - gate.referenceRatio), 0, 1)
adaptiveT = heightGate * ratioGate
```

Puis :

```text
effectiveAttachYRatio = lerp(base.attachYRatio, target.attachYRatio, adaptiveT)
effectiveFrontWidthRatio = lerp(base.frontWidthRatio, target.frontWidthRatio, adaptiveT)
effectiveRearWidthRatio = lerp(base.rearWidthRatio, target.rearWidthRatio, adaptiveT)
effectiveDepthRatio = lerp(base.depthRatio, target.depthRatio, adaptiveT)
effectiveSkewXRatio = lerp(base.skewXRatio, target.skewXRatio, adaptiveT)
effectiveOpacity = lerp(baseOpacity, targetOpacity, adaptiveT)
```

Audit `StaticShadowVisualMetrics` :

```text
packages/map_core/lib/src/operations/static_shadow_geometry.dart:10:final class StaticShadowVisualMetrics {
packages/map_core/lib/src/operations/static_shadow_geometry.dart:17:    _validateFinite(left, 'StaticShadowVisualMetrics.left');
packages/map_core/lib/src/operations/static_shadow_geometry.dart:18:    _validateFinite(top, 'StaticShadowVisualMetrics.top');
packages/map_core/lib/src/operations/static_shadow_geometry.dart:21:      visualWidth,
packages/map_core/lib/src/operations/static_shadow_geometry.dart:25:      visualHeight,
```

Le constructeur valide :

- `left` et `top` finis ;
- `visualWidth > 0` ;
- `visualHeight > 0`.

Décision :

- l'opération future peut faire confiance à `StaticShadowVisualMetrics` pour éviter division par zéro ;
- elle ne doit pas dupliquer inutilement les validations width/height ;
- elle doit valider `fixedOpacity` si ce double est accepté directement ;
- elle peut s'appuyer sur les constructors `ProjectedShadowFootprintTuning` et `ProjectedShadowFootprintAdaptiveDepthTuning` pour les bornes de tuning et opacité.

## 17. Nommage recommandé

Nom d'opération recommandé :

```text
resolveProjectedShadowFootprintEffectiveTuning(...)
```

Raison : précis, cohérent avec le vocabulaire `ProjectedShadowFootprintTuning`, et ne suggère pas une géométrie complète.

Nom du result object recommandé :

```text
ProjectedShadowFootprintEffectiveTuningResult
```

Payload success :

```text
ProjectedShadowEffectiveFootprintTuning
```

Block reason :

```text
ProjectedShadowFootprintEffectiveTuningBlockReason
```

Strategy kind :

```text
ProjectedShadowFootprintEffectiveTuningStrategyKind
```

Valeurs :

```text
fixed
adaptiveHeightDepth
```

Block reasons :

```text
adaptiveDepthRequiresCasterKind
adaptiveDepthUnsupportedCasterKind
```

Tests futurs :

```text
projected_shadow_footprint_effective_tuning_test.dart
```

Rapport Lot 60 :

```text
shadow_v2_60_projected_building_shadow_adaptive_depth_effective_tuning_resolver_v0.md
```

## 18. Option recommandée

Option recommandée :

```text
Option B — Opération pure dédiée resolveProjectedShadowFootprintEffectiveTuning(...)
+ Result D — union result success / blocked
```

Pourquoi :

- garde le resolver de géométrie propre ;
- rend le guard testable ;
- permet de retourner l'opacité effective ;
- évite null/fallback silencieux ;
- prépare diagnostics sans les implémenter ;
- reste pure map_core.

Options rejetées :

- calcul direct dans `resolveProjectedBuildingShadowGeometry(...)` : trop tôt et trop couplé ;
- méthode sur stratégie : met la logique dans le modèle ;
- editor/runtime-only : risque de divergence ;
- retour direct tuning : incomplet ;
- tuple/record : trop peu explicite ;
- exception pour guard : trop dure pour les flows de diagnostic.

## 19. Design conceptuel recommandé

Signature conceptuelle :

```dart
ProjectedShadowFootprintEffectiveTuningResult
    resolveProjectedShadowFootprintEffectiveTuning({
  required ProjectedShadowFootprintTuningStrategy strategy,
  required StaticShadowVisualMetrics metrics,
  required double fixedOpacity,
  ProjectedBuildingShadowCasterKind? casterKind,
})
```

Types conceptuels :

```dart
sealed class ProjectedShadowFootprintEffectiveTuningResult {}

final class ProjectedShadowFootprintEffectiveTuningResolved
    extends ProjectedShadowFootprintEffectiveTuningResult {
  final ProjectedShadowEffectiveFootprintTuning value;
}

final class ProjectedShadowFootprintEffectiveTuningBlocked
    extends ProjectedShadowFootprintEffectiveTuningResult {
  final ProjectedShadowFootprintEffectiveTuningBlockReason reason;
}

final class ProjectedShadowEffectiveFootprintTuning {
  final ProjectedShadowFootprintTuning tuning;
  final double opacity;
  final double adaptiveT;
  final ProjectedShadowFootprintEffectiveTuningStrategyKind strategyKind;
}
```

Fixed behavior :

```text
strategy: ProjectedShadowFootprintFixedTuning
result:
  resolved.tuning = strategy.tuning
  resolved.opacity = fixedOpacity
  resolved.adaptiveT = 0
  resolved.strategyKind = fixed
```

Adaptive behavior :

```text
strategy: ProjectedShadowFootprintAdaptiveDepthTuning
if casterKind == null:
  blocked(adaptiveDepthRequiresCasterKind)
else if casterKind not in building/largeVolume:
  blocked(adaptiveDepthUnsupportedCasterKind)
else:
  compute heightGate / ratioGate / adaptiveT
  interpolate base -> target tuning
  interpolate baseOpacity -> targetOpacity
  resolved.strategyKind = adaptiveHeightDepth
```

Relation future avec `resolveProjectedBuildingShadowGeometry(...)` :

- pas de changement au Lot 60 ;
- plus tard, le resolver pourra recevoir ou dériver une stratégie ;
- il appellera l'opération effective avant `_resolveFootprintProjectedBuildingShadowGeometry` ;
- la formule footprint existante restera inchangée ;
- la seule différence sera que le `footprint` et `opacity` utilisés seront effectifs.

## 20. Plan précis du Lot 60

Direction choisie :

```text
ShadowV2-60 — Projected Building Shadow Adaptive Depth Effective Tuning Resolver V0
```

Objectif :

```text
Créer une opération pure dans map_core qui résout un tuning footprint effectif depuis
ProjectedShadowFootprintFixedTuning ou ProjectedShadowFootprintAdaptiveDepthTuning,
avec support explicite du guard ProjectedBuildingShadowCasterKind?,
sans brancher le resolver géométrique existant.
```

Fichiers à créer / modifier probablement :

```text
Créer :
packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart
packages/map_core/test/shadow_v2/projected_shadow_footprint_effective_tuning_test.dart
reports/shadows/v2/shadow_v2_60_projected_building_shadow_adaptive_depth_effective_tuning_resolver_v0.md

Modifier :
packages/map_core/lib/map_core.dart
```

Pourquoi modifier `map_core.dart` au Lot 60 : les opérations map_core publiques sont exportées dans le barrel existant, et l'opération effective est destinée à être consommée plus tard par le resolver/runtime/editor via l'API publique. Si le prochain prompt veut garder l'opération purement interne pour V0, cette modification peut être repoussée.

Tests Lot 60 à créer :

- fixed retourne tuning, fixedOpacity, `adaptiveT = 0`, `strategyKind = fixed` ;
- adaptive sans caster kind retourne blocked `adaptiveDepthRequiresCasterKind` ;
- adaptive avec `building` atteint C+ sur `tall_shop_4x7` ;
- adaptive avec `largeVolume` suit la même règle ;
- adaptive sur `wide_house_6x5` retourne base/standard (`adaptiveT = 0`) ;
- adaptive sur `medium_shop_5x6` retourne base/standard (`adaptiveT = 0`) ;
- adaptive sur dimensions intermédiaires calcule gates et interpolation ;
- `fixedOpacity` hors `[0, 1]` est rejeté ;
- metrics width/height invalides déjà rejetées par `StaticShadowVisualMetrics`.

Commandes Lot 60 probables :

```bash
cd packages/map_core && dart test test/shadow_v2/projected_shadow_footprint_effective_tuning_test.dart
cd packages/map_core && dart test test/shadow_v2/projected_shadow_footprint_strategy_test.dart
cd packages/map_core && dart test test/shadow_v2/projected_building_shadow_geometry_test.dart
cd packages/map_core && dart analyze lib/src/operations/projected_shadow_footprint_effective_tuning.dart test/shadow_v2/projected_shadow_footprint_effective_tuning_test.dart
```

Lot 60 ne doit pas faire :

- modifier `resolveProjectedBuildingShadowGeometry(...)` ;
- brancher `ProjectBuildingShadowPreset` ;
- ajouter JSON/persistence ;
- modifier runtime/editor ;
- créer screenshot/baseline ;
- toucher Selbrume.

## 21. Fichiers explicitement interdits au Lot 60

Interdits au Lot 60 sauf instruction explicite contraire :

```text
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart
packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart
packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart
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

## 22. Risques / réserves

- Le result object ajoute un peu de modèle, mais il évite des ambiguïtés plus coûteuses.
- Le nom `fixedOpacity` devra être documenté soigneusement pour ne pas laisser croire que l'opération modifie `ProjectedShadowAppearance`.
- L'emplacement final du guard dans les données persistées n'est pas tranché par ce lot.
- Si l'enum `ProjectedBuildingShadowCasterKind` reste limité à `building` et `largeVolume`, `adaptiveDepthUnsupportedCasterKind` sera peu utilisé au début, mais il protège le design contre une extension future.
- Le futur branchement dans le resolver devra décider quoi faire d'un result blocked : probablement pas créer de géométrie et faire remonter diagnostic, mais ce n'est pas le Lot 60.

## 23. Auto-critique

- Le lot est-il bien design-only ? Oui : seul ce rapport est créé.
- Le rapport évite-t-il de coder dans un design gate ? Oui : aucun fichier Dart/test modifié.
- Le rapport sépare-t-il bien tuning effectif et géométrie ? Oui : opération pure avant resolver.
- Le rapport évite-t-il de brancher prématurément `resolveProjectedBuildingShadowGeometry(...)` ? Oui : le Lot 60 recommandé n'y touche pas.
- Le rapport protège-t-il vraiment les props fins ? Oui : adaptive est bloqué sans caster kind explicite.
- Le rapport traite-t-il correctement le cas guard incompatible ? Oui : blocked result recommandé.
- Le rapport inclut-il l'opacité effective ? Oui : output success inclut `opacity`.
- Le plan Lot 60 est-il assez petit ? Oui : une opération pure, un test, un rapport, export éventuel.
- Le rapport contient-il toutes les preuves ? Oui : commandes, audits, git final et inventaire inclus.

## 24. Regard critique sur le prompt

Le prompt est correctement prudent : il empêche de transformer un design de calcul en branchement resolver/JSON trop tôt. Le point le plus utile est l'obligation de trancher null/exception/diagnostic/blocked, car c'est exactement là que la future architecture pourrait devenir silencieuse ou fragile.

Le seul point à surveiller pour le Lot 60 : si l'opération est publique, le barrel `map_core.dart` devra probablement être modifié même s'il n'était pas listé dans les fichiers probables du prompt. C'est cohérent avec le style du repo, mais doit être explicitement autorisé dans le prochain lot.

## 25. Commandes lancées

Commandes exécutées :

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
sed -n '1,320p' AGENTS.md
rg -n "ProjectedShadowFootprintTuningStrategy|ProjectedShadowFootprintFixedTuning|ProjectedShadowFootprintAdaptiveDepthTuning|ProjectedShadowAdaptiveDepthGate|ProjectedBuildingShadowCasterKind|referenceHeight|targetHeight|referenceRatio|targetRatio|baseOpacity|targetOpacity" packages/map_core/lib/src/models/projected_building_shadow.dart packages/map_core/test/shadow_v2/projected_shadow_footprint_strategy_test.dart reports/shadows/v2/shadow_v2_58_projected_building_shadow_adaptive_depth_core_model_v0.md
rg -n "resolveProjectedBuildingShadowGeometry|_resolveDirectionalProjectedBuildingShadowGeometry|_resolveFootprintProjectedBuildingShadowGeometry|ProjectedShadowFootprintTuning|ProjectedShadowAppearance|StaticShadowVisualMetrics|ProjectElementProjectedBuildingShadowConfig|opacity|colorHexRgb|geometryMode|footprint" packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
rg -n "ProjectElementProjectedBuildingShadowConfig|ProjectElementEntry|MapPlacedElement|shadowOverride|StaticShadowFamily|building|largeVolume|casterKind|categoryId|presetKind|projectedBuildingShadow" packages/map_core/lib/src/models packages/map_core/test/shadow_v2
rg -n "effective tuning|effectiveTuning|adaptiveT|heightGate|ratioGate|blocked|BlockReason|Fixed C\\+|Adaptive C\\+|thin_prop_like|wide_house_6x5|medium_shop_5x6|tall_shop_4x7|JSON|runtime|editor|renderer|painter|Selbrume" reports/shadows/v2 packages/map_runtime/tool/shadow packages/map_core/lib packages/map_core/test
rg -n "class StaticShadowVisualMetrics|StaticShadowVisualMetrics" packages/map_core/lib/src/operations packages/map_core/lib/src/models packages/map_core/test/shadow_v2
sed -n '1,220p' packages/map_core/lib/src/operations/static_shadow_geometry.dart
sed -n '1,430p' packages/map_core/lib/src/models/projected_building_shadow.dart
sed -n '1,230p' packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
sed -n '1,180p' packages/map_core/lib/src/models/shadow.dart
sed -n '250,330p' packages/map_core/lib/src/models/shadow.dart
sed -n '410,455p' packages/map_core/lib/src/models/project_manifest.dart
sed -n '90,120p' packages/map_core/lib/src/models/map_data.dart
rg -n "projected_building_shadow_geometry|static_shadow_geometry|operations" packages/map_core/lib/map_core.dart
sed -n '1,220p' packages/map_core/lib/map_core.dart
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

Tests lancés : Aucun, conformément au contrat design-only.

## 26. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text
```

Interprétation : aucun fichier suivi n'est modifié dans le diff Git. Le rapport Lot 59 est un fichier nouveau non suivi, visible dans `git status`.

## 27. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie :

```text
```

Interprétation : aucun fichier suivi n'est modifié, renommé ou supprimé.

## 28. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text
```

Interprétation : propre, aucune erreur whitespace détectée dans les fichiers suivis modifiés.

## 29. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
?? reports/shadows/v2/shadow_v2_59_projected_building_shadow_adaptive_depth_effective_tuning_resolver_design.md
```

Conclusion : le seul fichier créé par ShadowV2-59 est le rapport Markdown demandé. Aucun fichier Dart, test, screenshot, baseline, JSON, runtime, editor ou Selbrume n'est créé/modifié/supprimé.

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
- [x] Modèle V0 audité
- [x] Resolver existant audité
- [x] Config élément / guard futur audité
- [x] Opération future recommandée
- [x] Result object futur recommandé
- [x] Guard incompatible tranché
- [x] casterKind input tranché
- [x] Opacité effective tranchée
- [x] Clamp / lerp / metrics tranchés
- [x] Option recommandée unique
- [x] Plan ShadowV2-60 précis
- [x] Fichiers interdits au Lot 60 listés
- [x] Evidence Pack complet
- [x] git diff --check propre
- [x] git status final conforme au scope ou fichiers hors scope documentés
