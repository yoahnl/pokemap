# Shadow-68 — Shadow Recovery Closure / Projected Building Shadows V2 Roadmap

## 1. Résumé exécutif

Shadow-68 clôt la récupération Shadow-55 -> Shadow-67.

État actuel: stabilisé pour Selbrume.

État futur: pas encore le système final d'ombres projetées de bâtiments.

Conclusion canonique:

- La récupération a supprimé les projections automatiques dangereuses.
- Elle n'a pas supprimé l'ambition d'ombres projetées Pokémon-like.
- Le futur chantier doit être `Projected Building Shadows V2`.
- V2 doit être asset-driven, authoré, previewé et validé visuellement.
- `genericProjection` automatique ne doit pas revenir comme mécanisme par défaut.

## 2. Objectif du lot

Ce lot est documentation-only / closure-only / roadmap-only.

Questions traitées:

1. Où en est le système Shadow après Shadow-55 -> Shadow-67 ?
2. Quelle roadmap propre prépare les futures ombres projetées de bâtiments, y compris compatibilité cycle jour/nuit ?

## 3. État initial du worktree

Commande:

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Sortie exacte:

```text
(no output)
```

## 4. Rapports audités

Tous les rapports demandés sont présents:

```text
present	reports/shadows/shadow_lot_55_full_shadow_system_audit_recovery_roadmap.md
present	reports/shadows/shadow_lot_56_disable_runtime_auto_apply.md
present	reports/shadows/shadow_lot_57_selbrume_shadow_inventory_runtime_instruction_debug_report.md
present	reports/shadows/shadow_lot_58_disable_unsafe_static_shadow_defaults_selbrume_recovery_plan.md
present	reports/shadows/shadow_lot_58_implementation_disable_unsafe_static_shadow_defaults.md
present	reports/shadows/shadow_lot_59_selbrume_authored_shadow_cleanup_patch.md
present	reports/shadows/shadow_lot_60_selbrume_post_cleanup_verification_remaining_static_shadows.md
present	reports/shadows/shadow_lot_61_selbrume_building_contact_ledge_visual_review_retune_decision.md
present	reports/shadows/shadow_lot_62_selbrume_contact_ledge_screenshot_review_visual_gate.md
present	reports/shadows/shadow_lot_63_building_contact_ledge_minimal_retune_design.md
present	reports/shadows/shadow_lot_64_building_contact_ledge_minimal_depth_retune.md
present	reports/shadows/shadow_lot_65_selbrume_shadow_screenshot_harness.md
present	reports/shadows/shadow_lot_66_selbrume_shadow_golden_baseline_design.md
present	reports/shadows/shadow_lot_67_selbrume_shadow_golden_baseline_implementation.md
```

Fichiers outil / baseline audités:

- `packages/map_runtime/tool/shadow/README.md`
- `packages/map_runtime/tool/shadow/selbrume_shadow_capture_test.dart`
- `reports/shadows/baselines/selbrume_shadow_v1/baseline_manifest.json`
- `reports/shadows/shadow_lot_67_baseline_compare.json`
- `reports/shadows/shadow_lot_67_baseline_compare.tsv`

## 5. Synthèse Shadow-55 -> Shadow-67

Avant récupération:

- runtime auto-apply silencieux;
- auto-policy trop agressive;
- 111 instructions statiques en `projectedPolygon`;
- 97 `genericProjection`;
- 95 instructions issues des deux arbres PixelLab;
- `panneau` et `lampadaire` produisaient aussi des projections dangereuses;
- screenshots non formalisés;
- pas de baseline visuelle versionnée.

Après récupération:

- runtime lit le manifest authoré;
- runtime auto-apply absent;
- policy auto-shadow durcie;
- `buildingLarge` reste le seul chemin auto V0;
- `tallThin`, `wideLow`, `smallSquare`, `defaultProp` ne produisent plus d'ombre auto;
- Selbrume nettoyée des grosses projections;
- `genericProjection = 0`;
- `contactLedge = 10`;
- `staticInstructions = 10`;
- contact ledge building retuné avec profondeur max `14.0`;
- screenshots reproductibles;
- baseline visuelle V1 créée;
- comparaison baseline informative disponible;
- invariants structurels bloquants.

## 6. État stable actuel

Le système Shadow actuel est stabilisé pour Selbrume.

Il n'est pas le système final d'ombres projetées de bâtiments.

Il est actuellement composé de:

- actor contact shadows;
- contact ledges building minimaux;
- authoring manuel / overrides;
- suggestions editor explicites;
- backfill editor explicite;
- harness screenshot manuel;
- baseline Selbrume V1 informative.

## 7. Invariants actuels

### Runtime auto-apply absent

Commande:

```bash
rg -n "applyElementAutoShadowPolicyToProject" packages/map_runtime packages/map_editor packages/map_core
```

Sortie exacte:

```text
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:142:ElementAutoShadowBackfillResult applyElementAutoShadowPolicyToProject(
packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart:8:        applyElementAutoShadowPolicyToProject;
packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart:13:  return applyElementAutoShadowPolicyToProject(project);
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:127:  group('applyElementAutoShadowPolicyToProject', () {
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:129:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:154:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:179:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:207:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:232:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:270:      final result = applyElementAutoShadowPolicyToProject(
packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart:431:      final coreResult = applyElementAutoShadowPolicyToProject(project);
```

Conclusion: aucun appel dans `packages/map_runtime`.

### Policy Shadow-58 active

Commande:

```bash
rg -n "_autoShadowKindIsArtisticallySafe|case ElementAutoShadowSuggestionKind.buildingLarge|case ElementAutoShadowSuggestionKind.tallThin|case ElementAutoShadowSuggestionKind.wideLow|case ElementAutoShadowSuggestionKind.smallSquare|case ElementAutoShadowSuggestionKind.defaultProp" packages/map_core/lib/src/operations/element_auto_shadow_policy.dart
```

Sortie exacte:

```text
124:  if (!_autoShadowKindIsArtisticallySafe(
261:bool _autoShadowKindIsArtisticallySafe(
267:    case ElementAutoShadowSuggestionKind.buildingLarge:
269:    case ElementAutoShadowSuggestionKind.tallThin:
270:    case ElementAutoShadowSuggestionKind.wideLow:
271:    case ElementAutoShadowSuggestionKind.smallSquare:
272:    case ElementAutoShadowSuggestionKind.defaultProp:
282:    case ElementAutoShadowSuggestionKind.tallThin:
283:    case ElementAutoShadowSuggestionKind.smallSquare:
285:    case ElementAutoShadowSuggestionKind.buildingLarge:
286:    case ElementAutoShadowSuggestionKind.wideLow:
288:    case ElementAutoShadowSuggestionKind.defaultProp:
348:    case ElementAutoShadowSuggestionKind.tallThin:
365:    case ElementAutoShadowSuggestionKind.buildingLarge:
382:    case ElementAutoShadowSuggestionKind.wideLow:
399:    case ElementAutoShadowSuggestionKind.smallSquare:
416:    case ElementAutoShadowSuggestionKind.defaultProp:
438:    case ElementAutoShadowSuggestionKind.tallThin:
440:    case ElementAutoShadowSuggestionKind.buildingLarge:
442:    case ElementAutoShadowSuggestionKind.wideLow:
444:    case ElementAutoShadowSuggestionKind.smallSquare:
446:    case ElementAutoShadowSuggestionKind.defaultProp:
```

Conclusion: `buildingLarge` reste le seul kind safe; `tallThin`, `wideLow`, `smallSquare`, `defaultProp` ne sont pas safe.

### Contact ledge retune actif

Commande:

```bash
rg -n "buildingStaticShadowContactLedgeMaxDepth|buildingStaticShadowContactLedgeMinDepth" packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart packages/map_core/test/shadow
```

Sortie exacte:

```text
packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart:8:const buildingStaticShadowContactLedgeMinDepth = 6.0;
packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart:9:const buildingStaticShadowContactLedgeMaxDepth = 14.0;
packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart:55:    buildingStaticShadowContactLedgeMinDepth,
packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart:56:    buildingStaticShadowContactLedgeMaxDepth,
packages/map_core/test/shadow/static_shadow_contact_ledge_geometry_test.dart:11:      expect(buildingStaticShadowContactLedgeMinDepth, 6);
packages/map_core/test/shadow/static_shadow_contact_ledge_geometry_test.dart:12:      expect(buildingStaticShadowContactLedgeMaxDepth, 14);
```

Conclusion: `buildingStaticShadowContactLedgeMaxDepth = 14.0`.

### Selbrume Shadow-59 toujours appliqué

Commande corrigée read-only:

```text
python read project.json targets/counts
```

Sortie exacte:

```text
Selbrume targets:
selbrume_maison_5	selbrume maison 5	True
lampadaire	lampadaire	True
arbre_pixellab_1	arbre  pixelLab 1	True
arbre_pixellab_2	arbre  pixelLab 2	True
panneau	panneau	True
withShadow 20
withoutShadow 43
elements 63
```

Note: une première commande jq de comptage était mal formée et a été remplacée par cette lecture Python read-only.

## 8. Ce qui a été corrigé

- Le runtime ne fabrique plus d'ombres auto silencieuses.
- La policy auto-shadow ne propose plus de defaults dangereux pour props étroits, bas, petits ou génériques.
- Selbrume ne contient plus les configs authorées dangereuses des 5 cibles Shadow-59.
- Les grosses plaques diagonales d'arbres ont disparu.
- `genericProjection` tombe à `0`.
- Les 10 ombres restantes sont des contact ledges building.
- La profondeur max des ledges est passée à `14.0`.
- Les screenshots sont reproductibles.
- Une baseline V1 existe.
- Les invariants structurels sont vérifiables.

## 9. Ce qui reste volontairement non résolu

- Pas de système final d'ombres projetées directionnelles.
- Pas de `Projected Building Shadows V2`.
- Pas de cycle jour/nuit.
- Pas de shadow asset-driven authoring model.
- Pas de pixel diff bloquant.
- Pas de golden CI fragile.
- Pas d'auto-update de baseline.
- Pas de retour de projections automatiques pour petits props / arbres.

## 10. Interdictions permanentes

- Ne pas réintroduire runtime auto-apply.
- Ne pas appliquer `genericProjection` par défaut.
- Ne pas générer des ombres sur petits props par heuristique.
- Ne pas traiter les arbres comme `projectedPolygon` générique.
- Ne pas rendre les projections polygonales automatiques.
- Ne pas modifier le rendu sans screenshots.
- Ne pas accepter un lot visuel sans visual gate.
- Ne pas mettre à jour une baseline sans validation explicite.
- Ne pas confondre `Projected Building Shadows V2` avec retour du genericProjection automatique.

## 11. Ce qui reste autorisé

- Actor contact shadows.
- Contact ledges building minimaux.
- Authoring manuel de shadows.
- Overrides d'instance.
- Previews éditeur.
- Backfill editor explicite.
- Projected shadows futures si asset-driven / authorées / validées.
- Screenshots visual gate.
- Baseline informative.

## 12. État des composants Shadow

| Component | Current status | Keep / Redesign / Frozen / Future | Notes |
|---|---|---|---|
| `ProjectShadowProfile` | Stable contract | Keep | Garder comme contrat de profil. |
| `ProjectShadowCatalog` | Stable contract | Keep | Catalogue existant utile pour profiles authorés. |
| `ProjectElementShadowConfig` | Stable authored config | Keep | Ne pas transformer en auto default implicite. |
| `MapPlacedElementShadowOverride` | Stable override | Keep | Préserve authoring instance. |
| `StaticShadowFootprintConfig` | Stable footprint | Keep | Utile pour manual/contact ledge. |
| `resolveShadowConfig` | Stable resolver | Keep | Runtime consomme données authorées. |
| `static_shadow_geometry` | Shared geometry | Keep | Pas de changement dans closure. |
| `static_shadow_projection_geometry` | Legacy/projection support | Frozen | Ne pas utiliser pour auto generic defaults. |
| `static_shadow_family_projection` | Family dispatch | Redesign later | V2 doit clarifier projected building path. |
| `static_shadow_contact_ledge_geometry` | Retuned | Keep | Max depth `14.0`, ledge minimal. |
| `element_auto_shadow_policy` | Hardened | Keep | Only `buildingLarge` auto-safe en V0. |
| runtime static shadow resolver | Authored-only boundary | Keep | Pas d'auto apply. |
| runtime renderer | Consumes instructions | Keep | Ne pas retoucher sans visual gate. |
| actor contact shadows | Existing feature | Keep | Hors crise genericProjection. |
| building contact ledge | Current stable visual fallback | Keep | Minimal, not final projected shadow. |
| `genericProjection` | Dangerous default removed | Frozen / forbidden by default | Peut exister comme legacy/manual only, jamais auto. |
| editor suggestion workflow | Explicit authoring helper | Keep | Propose, utilisateur valide. |
| editor backfill | Explicit operation | Keep | Pas runtime. |
| shadow screenshot harness | Manual visual gate | Keep | Shadow-65/67. |
| Selbrume baseline V1 | Versioned reference | Keep | Informative pixel/hash, structure blocking. |

## 13. Baseline visuelle Selbrume V1

Baseline présente:

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

Manifest summary:

```text
baselineId selbrume_shadow_v1
sourceLot Shadow-65
mapId Selbrume
counts {'staticInstructions': 10, 'contactLedge': 10, 'genericProjection': 0, 'captures': 11}
captures 11
```

Shadow-67 compare summary:

```text
baselineId selbrume_shadow_v1
mode informative-hash-v0
total 11
exactMatches 11
informativeDiffs 0
blockingFailures 0
hasBlockingFailure False
counts {'staticInstructions': 10, 'contactLedge': 10, 'genericProjection': 0, ...}
```

## 14. Règles pour tout futur changement visuel

- Toute modification de rendu Shadow doit produire des screenshots.
- Toute modification visuelle Selbrume doit comparer contre la baseline V1 ou une baseline explicitement remplacée.
- Les invariants structurels restent bloquants.
- Hash/pixel diff V0 reste informatif jusqu'à décision de pixel diff avec seuil.
- Une baseline ne s'auto-update jamais.
- Une baseline change seulement après review visuelle et rapport dédié.

## 15. North Star artistique long terme

Objectif futur:

- ombres projetées Pokémon-like;
- grandes mais propres;
- directionnelles;
- simples;
- attachées visuellement au bâtiment;
- contrôlées artistiquement;
- pas appliquées aux petits props;
- pas appliquées aux arbres par défaut;
- pas de plaques génériques;
- pas de décision automatique silencieuse au runtime.

La phase Shadow-55 -> Shadow-67 a supprimé les projections dangereuses, pas l'idée d'ombres projetées.

## 16. Roadmap Projected Building Shadows V2

Roadmap proposée, à lancer seulement si priorité produit validée:

1. `ShadowV2-1 — Projected Building Shadows Product Spec / Art Direction`
   - Définir direction artistique, exemples Pokémon-like, limites.
   - Sortie: spec produit + critères visuels.

2. `ShadowV2-2 — Building Shadow Authoring Model Design`
   - Concevoir données authorées, non automatiques.
   - Sortie: design model, sans migration.

3. `ShadowV2-3 — Asset-driven Shadow Footprint / Anchor Model`
   - Définir anchors, footprint, asset relation.
   - Sortie: modèle V2 compatible asset.

4. `ShadowV2-4 — Projected Shadow Preview in Editor`
   - Preview éditeur avant runtime.
   - Sortie: visual gate editor, no runtime surprise.

5. `ShadowV2-5 — Manual Building Shadow Presets`
   - Presets artistiques pour bâtiments.
   - Sortie: presets manuels, pas auto generic.

6. `ShadowV2-6 — Runtime Projected Building Shadow Renderer V2`
   - Consommer données V2 authorées.
   - Sortie: renderer path contrôlé.

7. `ShadowV2-7 — Selbrume 3 Buildings POC`
   - POC limité à 3 bâtiments.
   - Sortie: screenshots before/after + décision.

8. `ShadowV2-8 — Time-of-Day Shadow Parameters Design`
   - Préparer direction/longueur/opacité selon temps.
   - Sortie: design, sans intégration runtime globale.

9. `ShadowV2-9 — Day/Night Integration POC`
   - POC interpolation runtime.
   - Sortie: slice contrôlée.

10. `ShadowV2-10 — Visual Golden Baseline V2`
    - Baseline pour projected building V2.
    - Sortie: visual gate dédié.

Chaque lot doit rester petit, testable et non automatique par défaut.

## 17. Préparation time-of-day

Ne pas intégrer time-of-day maintenant.

Besoins futurs:

- light direction;
- shadow length multiplier;
- opacity multiplier;
- color/tint;
- time ranges;
- setting global ou par map;
- preview à différentes heures;
- interpolation runtime;
- désactivation ou remplacement par lumières artificielles la nuit;
- compatibilité avec shadows statiques authorées.

Décision recommandée:

Concevoir Projected Building Shadows V2 avec paramètres compatibles time-of-day, mais ne pas brancher le cycle jour/nuit avant que V2 soit validé visuellement.

## 18. Séparation des horizons A/B/C

### Horizon A — Stable current Shadow system

- contact ledges;
- actor contact shadows;
- manual authoring;
- editor suggestions/backfill explicites;
- baseline Selbrume V1.

### Horizon B — Projected Building Shadows V2

- ombres projetées authorées;
- direction contrôlée;
- preview éditeur;
- modèle asset-driven;
- POC bâtiments limité.

### Horizon C — Time-of-Day Shadows

- variation direction / longueur / opacité;
- cycle jour/nuit;
- interpolation runtime;
- compatibilité V2.

Ces horizons ne doivent pas être mélangés dans un même lot.

## 19. Recommandation de priorité

Recommandation: faire une pause sur Shadow avant V2, sauf besoin produit immédiat de grandes ombres projetées.

Justification:

- Selbrume est stabilisée.
- Les régressions principales sont couvertes.
- La baseline visuelle existe.
- Le système final V2 demande un vrai spec art/product.
- Lancer V2 trop vite risquerait de recréer une calibration large sans direction artistique validée.

Prochain lot recommandé si on continue Shadow: `ShadowV2-1 — Projected Building Shadows Product Spec / Art Direction`.

Sinon: revenir aux priorités PokeMap hors Shadow, en gardant la baseline pour toute future modification de rendu.

## 20. Tests / commandes lancées

Commande harness baseline compare, sorties sous `/tmp` pour ne pas modifier le repo:

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
SHADOW_SCREENSHOT_PREFIX=shadow68verify \
SHADOW_SCREENSHOT_OUTPUT_DIR=/tmp/shadow68_screenshots \
SELBRUME_PROJECT_PATH=/Users/karim/Desktop/selbrume/project.json \
SHADOW_COMPARE_BASELINE=true \
SHADOW_BASELINE_DIR=/Users/karim/Project/pokemonProject/reports/shadows/baselines/selbrume_shadow_v1 \
SHADOW_BASELINE_COMPARE_OUTPUT_JSON=/tmp/shadow68_baseline_compare.json \
SHADOW_BASELINE_COMPARE_OUTPUT_TSV=/tmp/shadow68_baseline_compare.tsv \
flutter test tool/shadow/selbrume_shadow_capture_test.dart --plain-name "selbrume shadow screenshot harness"
```

Commande runtime bundle:

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
flutter test test/application/load_runtime_map_bundle_shadow_policy_test.dart
```

Commande core shadow:

```bash
cd /Users/karim/Project/pokemonProject/packages/map_core
dart test test/shadow
```

## 21. Résultats des tests

Harness compare:

```text
baseline comparison wrote /tmp/shadow68_baseline_compare.json and /tmp/shadow68_baseline_compare.tsv
"counts": {
  "staticInstructions": 10,
  "contactLedge": 10,
  "genericProjection": 0
}
"baselineComparison": {
  "baselineId": "selbrume_shadow_v1",
  "mode": "informative-hash-v0",
  "total": 11,
  "exactMatches": 11,
  "informativeDiffs": 0,
  "blockingFailures": 0,
  "hasBlockingFailure": false
}
00:01 +1: All tests passed!
```

Runtime bundle:

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/application/load_runtime_map_bundle_shadow_policy_test.dart
00:00 +0: loadProjectManifestFromFile authored shadow manifest keeps missing shadow configs absent at runtime load
00:00 +1: loadProjectManifestFromFile authored shadow manifest preserves recognized old auto shadows as authored data
00:00 +2: loadProjectManifestFromFile authored shadow manifest preserves manual and disabled shadows
00:00 +3: All tests passed!
```

Core shadow:

```text
00:00 +284: All tests passed!
```

## 22. git diff --stat

État attendu après création de ce rapport: aucun fichier suivi modifié, seulement le rapport Shadow-68 non suivi.

```text
(no output)
```

## 23. git diff --name-status

État attendu après création de ce rapport:

```text
(no output)
```

## 24. git diff --check

État attendu après création de ce rapport:

```text
(no output)
```

## 25. git status final

État attendu après création de ce rapport:

```text
?? reports/shadows/shadow_lot_68_shadow_recovery_closure_projected_building_shadows_v2_roadmap.md
```

## 26. Risques / réserves

- La baseline V1 est informative sur pixels/hash, pas encore un pixel diff robuste.
- V2 demande direction artistique; sans cela, les coefficients risquent de redevenir arbitraires.
- Time-of-day peut complexifier les shadows; il faut le concevoir après V2, pas avant.
- Les anciennes APIs projection existent encore; la règle importante est de ne pas les réactiver comme auto default.

## 27. Auto-critique

Ce rapport ferme le cycle de récupération sans prétendre que Shadow est fini. Il est volontairement strict sur les interdictions, parce que la crise venait d'un mécanisme auto trop confiant. La roadmap V2 garde l'ambition visuelle, mais impose authoring, preview et validation.

## 28. Regard critique sur le prompt

Le prompt est bien cadré: il empêche une rechute en implémentation tout en reconnaissant que l'objectif final n'est pas "zéro ombre". Le point le plus important est la séparation des horizons A/B/C; sans elle, time-of-day et projected shadows V2 pourraient se mélanger trop tôt.

## 29. Prochain lot recommandé

Option recommandée court terme: pause Shadow, reprendre une priorité PokeMap plus utile si aucune demande produit immédiate n'exige de grandes ombres de bâtiments.

Si le chantier Shadow continue:

```text
ShadowV2-1 — Projected Building Shadows Product Spec / Art Direction
```

Objectif: définir la référence artistique, les cas acceptés/interdits, les contraintes authoring, les critères de screenshots, et les non-objectifs avant toute ligne de code.

## 30. Inventaire des fichiers

Créé:

- `reports/shadows/shadow_lot_68_shadow_recovery_closure_projected_building_shadows_v2_roadmap.md`

Modifié:

- Aucun.

Supprimé:

- Aucun.

Généré dans le repo:

- Aucun autre fichier.

Fichiers temporaires hors repo:

- `/tmp/shadow68_screenshots/*`
- `/tmp/shadow68_baseline_compare.json`
- `/tmp/shadow68_baseline_compare.tsv`

Code modifié:

- Aucun.

Selbrume modifié:

- Non.

Commit:

- Aucun.
