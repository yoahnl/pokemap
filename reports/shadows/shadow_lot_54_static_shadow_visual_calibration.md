# Shadow-54 — Static Shadow Visual Calibration

## Résumé

Shadow-54 calibre les ombres statiques sans créer de nouveau renderer, sans modèle persistant et sans nouvelle UI.

Le problème confirmé était double :

- les projections statiques étaient devenues trop timides après la réduction des galettes ;
- les projets déjà backfillés en Shadow-53 conservaient des configs auto à `opacity: 0.20`, que la politique traitait comme manuelles.

Le lot augmente donc la lisibilité des projections et rend les configs auto Shadow-53 remplaçables par le tuning Shadow-54.

## Fichiers modifiés par Shadow-54

- `packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart`
- `packages/map_core/lib/src/operations/static_shadow_family_projection.dart`
- `packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart`
- `packages/map_core/lib/src/operations/element_auto_shadow_policy.dart`
- `packages/map_core/test/shadow/static_shadow_projection_geometry_test.dart`
- `packages/map_core/test/shadow/static_shadow_family_projection_test.dart`
- `packages/map_core/test/shadow/static_shadow_contact_ledge_geometry_test.dart`
- `packages/map_core/test/shadow/element_auto_shadow_policy_test.dart`
- `packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart`
- `packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart`
- `packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart`
- `reports/shadows/shadow_lot_54_static_shadow_visual_calibration.md`

## Fichiers déjà modifiés avant Shadow-54

Présents dans le `git status` initial et non créés par ce lot :

- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart`
- `packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart`
- `packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart`
- `packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart`
- `packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart`
- `packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart`
- `packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart`
- `packages/map_core/test/shadow/static_shadow_contact_ledge_geometry_test.dart`
- `reports/shadows/shadow_lot_52_building_contact_ledge_core_editor_parity.md`
- `reports/shadows/shadow_lot_52_building_contact_ledge_core_editor_parity_plan.md`
- `reports/shadows/shadow_lot_53_auto_shadow_policy_reconciliation_selbrume_audit.md`
- `reports/shadows/shadow_lot_53_auto_shadow_policy_reconciliation_selbrume_audit_plan.md`

`static_shadow_contact_ledge_geometry.dart` et son test étaient non suivis avant Shadow-54, mais Shadow-54 a modifié leurs constantes et attentes.

## Changements fonctionnels

Projection polygonale :

- `defaultProjectedStaticShadowFarOpacityScale` passe de `0.34` à `0.52`.
- La dernière bande d’opacité par défaut passe de `0.3871428571` à `0.5542857143`.

Familles statiques :

- `compactProp`: `lengthRatio 0.1120`, `nearWidthMultiplier 0.5200`, `farWidthMultiplier 0.4300`.
- `tallProp`: `lengthRatio 0.1280`, `nearWidthMultiplier 0.5400`, `farWidthMultiplier 0.4000`.
- `building`: `lengthRatio 0.1120`, `nearWidthMultiplier 0.6400`, `farWidthMultiplier 0.5400`.
- `foliage`: `lengthRatio 0.1300`, `nearWidthMultiplier 0.7000`, `farWidthMultiplier 0.6400`.

Contact ledge bâtiment :

- largeur near/far augmentée ;
- profondeur augmentée et clampée entre `6` et `20` ;
- skew légèrement réduit et clampé à `7`.

Politique auto :

- `tallThin` passe à `opacity: 0.30`.
- `buildingLarge` passe à `opacity: 0.32`.
- `wideLow` passe à `opacity: 0.28`.
- Les anciennes configs auto Shadow-53 à `opacity: 0.20` sont reconnues comme auto et remplacées au backfill.

## Ce qui n’a pas changé

- Aucun modèle persistant modifié.
- Aucun codec JSON modifié.
- Aucun build_runner lancé.
- Aucun renderer avancé ajouté.
- Aucun blur, `saveLayer`, `ImageFilter`, atlas ou sprite shadow ajouté.
- Aucun `map_editor` production touché par Shadow-54.
- Aucun `map_runtime` production touché par Shadow-54.
- Aucun commit effectué.

## Flame

Le lot ne modifie pas les APIs Flame ni les composants runtime. Les recherches Flame effectuées précédemment sur l’ordre de rendu et `Canvas` n’ont pas retourné de documentation exploitable via `flame_docs`; l’implémentation reste donc dans les opérations pures `map_core` et respecte les patterns runtime existants.

## Tests RED

Commande :

```bash
cd packages/map_core && dart test test/shadow/static_shadow_projection_geometry_test.dart test/shadow/static_shadow_family_projection_test.dart test/shadow/static_shadow_contact_ledge_geometry_test.dart test/shadow/element_auto_shadow_policy_test.dart
```

Résultat attendu avant production : échec sur les nouvelles attentes Shadow-54.

Sortie utile :

```text
Expected: a numeric value within <0.000001> of <0.5542857143>
Actual: <0.38714285714285723>

Expected: a numeric value within <1e-7> of <0.112>
Actual: <0.0704>

Expected: <0.72>
Actual: <0.55>

Expected: a numeric value within <1e-7> of <0.3>
Actual: <0.2>

Some tests failed.
```

Commande :

```bash
cd packages/map_core && dart test test/shadow/element_auto_shadow_policy_test.dart --plain-name 'backfill upgrades Shadow-53 auto shadows to Shadow-54 tuning'
```

Résultat attendu avant production : échec, car les configs Shadow-53 étaient encore préservées comme manuelles.

Sortie utile :

```text
Expected: <3>
Actual: <0>
Some tests failed.
```

## Vérifications GREEN

Commande :

```bash
cd packages/map_core && dart test test/shadow/static_shadow_projection_geometry_test.dart test/shadow/static_shadow_family_projection_test.dart test/shadow/static_shadow_contact_ledge_geometry_test.dart test/shadow/element_auto_shadow_policy_test.dart
```

Résultat :

```text
00:00 +65: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/shadow
```

Résultat :

```text
00:00 +283: All tests passed!
```

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow
```

Résultat :

```text
00:02 +233: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test test/application/shadow
```

Résultat :

```text
00:00 +96: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart analyze lib test/shadow
```

Résultat :

```text
Analyzing lib, shadow...
No issues found!
```

Commande :

```bash
cd packages/map_runtime && flutter analyze lib/src/shadow test/shadow
```

Résultat :

```text
No issues found! (ran in 2.8s)
```

Commande :

```bash
cd packages/map_editor && flutter analyze lib/src/application/shadow test/application/shadow
```

Résultat :

```text
No issues found! (ran in 1.9s)
```

Commande :

```bash
git diff --check
```

Résultat : aucune sortie, exit code `0`.

## Limites et risques

- Ce lot améliore la lisibilité mathématique des ombres existantes, mais ne crée toujours pas d’ombres pixel-art dessinées à la main.
- Les projets déjà ouverts doivent déclencher le backfill auto pour remplacer les anciennes configs Shadow-53 persistées.
- Le rendu reste hard-edge polygonal ; une vraie qualité Pokémon demandera encore une passe de composition visuelle ou d’assets dédiés.

## Changements hors Shadow-54 présents au statut final

Ces fichiers sont présents dans le `git status` final mais ne font pas partie de Shadow-54 et n'ont pas été modifiés par ce lot :

- `packages/map_battle/lib/src/domain/effect/battle_effect.dart`
- `packages/map_battle/lib/src/domain/effect/battle_effect_hooks.dart`
- `packages/map_battle/lib/src/domain/effect/battle_effect_stack.dart`
- `packages/map_battle/lib/src/domain/effect/item/item_effect_registry.dart`
- `packages/map_battle/lib/src/domain/effect/item/shed_shell_effect.dart`
- `packages/map_battle/lib/src/domain/effect/move/cant_switch_effect.dart`
- `packages/map_battle/lib/src/domain/handler/battle_switch_handler.dart`
- `packages/map_battle/lib/src/psdk/domain/psdk_battle_combatant.dart`
- `packages/map_battle/test/psdk_switch_effect_test.dart`
- `reports/analysis/psdk_fight_100_percent_lot_plan_2026-05-16.md`

Ils sont documentés comme changements concurrents ou préexistants hors lot, sans tentative de correction ou de revert.

## Statut final du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale :

```text
 M packages/map_battle/lib/src/domain/effect/battle_effect.dart
 M packages/map_battle/lib/src/domain/effect/battle_effect_hooks.dart
 M packages/map_battle/lib/src/domain/effect/battle_effect_stack.dart
 M packages/map_battle/lib/src/domain/effect/item/item_effect_registry.dart
 M packages/map_battle/lib/src/domain/effect/move/cant_switch_effect.dart
 M packages/map_battle/lib/src/domain/handler/battle_switch_handler.dart
 M packages/map_battle/lib/src/psdk/domain/psdk_battle_combatant.dart
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/operations/element_auto_shadow_policy.dart
 M packages/map_core/lib/src/operations/static_shadow_family_projection.dart
 M packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
 M packages/map_core/test/shadow/element_auto_shadow_policy_test.dart
 M packages/map_core/test/shadow/static_shadow_family_projection_test.dart
 M packages/map_core/test/shadow/static_shadow_projection_geometry_test.dart
 M packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
 M packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
 M packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart
 M packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart
 M packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
 M packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
 M packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
 M reports/analysis/psdk_fight_100_percent_lot_plan_2026-05-16.md
?? packages/map_battle/lib/src/domain/effect/item/shed_shell_effect.dart
?? packages/map_battle/test/psdk_switch_effect_test.dart
?? packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart
?? packages/map_core/test/shadow/static_shadow_contact_ledge_geometry_test.dart
?? reports/shadows/shadow_lot_52_building_contact_ledge_core_editor_parity.md
?? reports/shadows/shadow_lot_52_building_contact_ledge_core_editor_parity_plan.md
?? reports/shadows/shadow_lot_53_auto_shadow_policy_reconciliation_selbrume_audit.md
?? reports/shadows/shadow_lot_53_auto_shadow_policy_reconciliation_selbrume_audit_plan.md
?? reports/shadows/shadow_lot_54_static_shadow_visual_calibration.md
```

Les fichiers `packages/map_battle/**`, `shed_shell_effect.dart`, `psdk_switch_effect_test.dart` et `reports/analysis/psdk_fight_100_percent_lot_plan_2026-05-16.md` sont hors Shadow-54 et n’ont pas été modifiés par ce lot.

## Auto-review

- Ai-je évité de créer un nouveau renderer ? oui.
- Ai-je évité les modèles persistants et codecs JSON ? oui.
- Ai-je amélioré la visibilité sans revenir aux galettes géantes ? oui.
- Ai-je ajouté un test pour les configs auto Shadow-53 déjà persistées ? oui.
- Ai-je évité de toucher au runtime production ? oui.
- Ai-je évité de toucher à l’editor production ? oui.
- Ai-je exécuté les tests ciblés et élargis ? oui.
- Ai-je fait un commit ? non.
