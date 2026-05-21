# Shadow-58 Implementation — Disable Unsafe Static Shadow Defaults

## 1. Résumé exécutif

Shadow-58 Implementation durcit la policy auto-shadow pour ne plus générer de defaults dangereux par défaut.

Changement produit livré :

```text
buildingLarge reste autorisé.
tallThin est désactivé.
wideLow est désactivé.
smallSquare reste désactivé.
defaultProp reste désactivé.
```

La modification de production est volontairement chirurgicale : seul `_autoShadowKindIsArtisticallySafe(...)` change de comportement. Les modèles, codecs, profils, renderer, runtime, géométrie de projection/contact ledge et fichiers Selbrume ne sont pas modifiés.

## 2. Rappel du design Shadow-58 validé

Design validé :

```text
reports/shadows/shadow_lot_58_disable_unsafe_static_shadow_defaults_selbrume_recovery_plan.md
```

Contrat appliqué :

```text
La policy auto-shadow ne doit plus produire d’ombre automatique pour tallThin, wideLow, smallSquare, defaultProp ou unknown/family null/genericProjection implicite.
Le seul chemin automatique encore accepté en V0 est buildingLarge -> StaticShadowFamily.building.
Mieux vaut aucune ombre qu’une mauvaise ombre.
```

## 3. État initial du worktree

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Sortie exacte :

```text

```

Commande :

```bash
find .. -name AGENTS.md -print
```

Sortie exacte :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

## 4. Fichiers modifiés

Production :

```text
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart
```

Tests :

```text
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart
packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart
```

Rapport créé :

```text
reports/shadows/shadow_lot_58_implementation_disable_unsafe_static_shadow_defaults.md
```

Fichiers Selbrume modifiés :

```text
Aucun.
```

Fichiers runtime modifiés :

```text
Aucun.
```

## 5. Changement exact de policy

Avant :

```text
tallThin était considéré safe.
buildingLarge était considéré safe.
wideLow était considéré safe si width >= 4 ou area >= 10.
smallSquare/defaultProp étaient non safe.
```

Après :

```text
buildingLarge uniquement est safe.
tallThin, wideLow, smallSquare et defaultProp retournent false.
```

Diff de production :

```diff
diff --git a/packages/map_core/lib/src/operations/element_auto_shadow_policy.dart b/packages/map_core/lib/src/operations/element_auto_shadow_policy.dart
index de68aca5..c483bb27 100644
--- a/packages/map_core/lib/src/operations/element_auto_shadow_policy.dart
+++ b/packages/map_core/lib/src/operations/element_auto_shadow_policy.dart
@@ -264,11 +264,10 @@ bool _autoShadowKindIsArtisticallySafe(
   required double height,
 ) {
   switch (kind) {
-    case ElementAutoShadowSuggestionKind.tallThin:
     case ElementAutoShadowSuggestionKind.buildingLarge:
       return true;
+    case ElementAutoShadowSuggestionKind.tallThin:
     case ElementAutoShadowSuggestionKind.wideLow:
-      return width >= 4 || width * height >= 10;
     case ElementAutoShadowSuggestionKind.smallSquare:
     case ElementAutoShadowSuggestionKind.defaultProp:
       return false;
```

## 6. Tests core adaptés

`packages/map_core/test/shadow/element_auto_shadow_policy_test.dart` couvre maintenant :

```text
wideLow 3x2 et 4x2 -> null.
tallThin 1x4 -> null.
lampadaire 3x5 -> null.
barriere_pierre 13x6 -> null.
panneau 3x3 -> null.
maison/building -> buildingLarge conservé.
legacy broad sans suggestion safe -> clearedAutoNoSuggestion + shadow null.
Shadow-53 tallThin/wideLow -> clearedAutoNoSuggestion.
Shadow-53 building -> appliedGeneric conservé.
manual/disabled -> préservés.
```

## 7. Tests editor adaptés

`packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart` couvre maintenant :

```text
tall thin -> null.
wide low -> null.
buildingLarge -> suggestion conservée.
fallback profile custom -> building uniquement.
_allSuggestionKinds ne contient plus que buildingLarge.
```

`packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart` couvre maintenant :

```text
lamp/tall prop sans shadow -> skippedNoSuggestion.
house/building sans shadow -> appliedMissing.
stand/wide unsafe pre-footprint -> clearedAutoNoSuggestion.
missing profile unsafe tall -> clearedAutoNoSuggestion.
default profile backfill utilise un bâtiment, plus une lampe.
ordre et champs non-shadow préservés.
```

## 8. Confirmation que runtime auto-apply reste absent

Commande :

```bash
rg -n "applyElementAutoShadowPolicyToProject" packages/map_runtime packages/map_editor packages/map_core
```

Sortie exacte :

```text
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:142:ElementAutoShadowBackfillResult applyElementAutoShadowPolicyToProject(
packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart:431:      final coreResult = applyElementAutoShadowPolicyToProject(project);
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:127:  group('applyElementAutoShadowPolicyToProject', () {
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:129:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:154:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:179:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:207:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:232:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:270:      final result = applyElementAutoShadowPolicyToProject(
packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart:8:        applyElementAutoShadowPolicyToProject;
packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart:13:  return applyElementAutoShadowPolicyToProject(project);
```

Conclusion :

```text
map_runtime : aucun appel.
map_core : définition + tests.
map_editor : backfill explicite côté authoring.
```

## 9. Résultat exact de l’audit rg policy

Commande :

```bash
rg -n "genericProjection|tallThin|wideLow|buildingLarge|smallSquare|defaultProp|_autoShadowKindIsArtisticallySafe|buildElementAutoShadowSuggestion|applyElementAutoShadowPolicyToProject" packages/map_core/lib/src/operations/element_auto_shadow_policy.dart packages/map_core/test/shadow/element_auto_shadow_policy_test.dart packages/map_editor/test/application/shadow
```

Sortie exacte :

```text
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:7:  tallThin,
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:8:  buildingLarge,
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:9:  wideLow,
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:10:  smallSquare,
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:11:  defaultProp,
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:101:ElementAutoShadowSuggestion? buildElementAutoShadowSuggestion({
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:124:  if (!_autoShadowKindIsArtisticallySafe(
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:142:ElementAutoShadowBackfillResult applyElementAutoShadowPolicyToProject(
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:161:    final suggestion = buildElementAutoShadowSuggestion(
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:241:    return ElementAutoShadowSuggestionKind.tallThin;
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:244:    return ElementAutoShadowSuggestionKind.wideLow;
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:247:    return ElementAutoShadowSuggestionKind.wideLow;
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:250:    return ElementAutoShadowSuggestionKind.buildingLarge;
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:253:    return ElementAutoShadowSuggestionKind.wideLow;
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:256:    return ElementAutoShadowSuggestionKind.smallSquare;
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:258:  return ElementAutoShadowSuggestionKind.defaultProp;
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:261:bool _autoShadowKindIsArtisticallySafe(
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:267:    case ElementAutoShadowSuggestionKind.buildingLarge:
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:269:    case ElementAutoShadowSuggestionKind.tallThin:
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:270:    case ElementAutoShadowSuggestionKind.wideLow:
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:271:    case ElementAutoShadowSuggestionKind.smallSquare:
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:272:    case ElementAutoShadowSuggestionKind.defaultProp:
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:282:    case ElementAutoShadowSuggestionKind.tallThin:
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:283:    case ElementAutoShadowSuggestionKind.smallSquare:
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:285:    case ElementAutoShadowSuggestionKind.buildingLarge:
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:286:    case ElementAutoShadowSuggestionKind.wideLow:
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:288:    case ElementAutoShadowSuggestionKind.defaultProp:
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:348:    case ElementAutoShadowSuggestionKind.tallThin:
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:365:    case ElementAutoShadowSuggestionKind.buildingLarge:
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:382:    case ElementAutoShadowSuggestionKind.wideLow:
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:399:    case ElementAutoShadowSuggestionKind.smallSquare:
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:416:    case ElementAutoShadowSuggestionKind.defaultProp:
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:425:        family: StaticShadowFamily.genericProjection,
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:438:    case ElementAutoShadowSuggestionKind.tallThin:
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:440:    case ElementAutoShadowSuggestionKind.buildingLarge:
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:442:    case ElementAutoShadowSuggestionKind.wideLow:
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:444:    case ElementAutoShadowSuggestionKind.smallSquare:
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:446:    case ElementAutoShadowSuggestionKind.defaultProp:
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:540:    family: StaticShadowFamily.genericProjection,
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:5:  group('buildElementAutoShadowSuggestion', () {
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:8:        buildElementAutoShadowSuggestion(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:15:        buildElementAutoShadowSuggestion(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:25:        buildElementAutoShadowSuggestion(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:33:        buildElementAutoShadowSuggestion(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:42:      final tall = buildElementAutoShadowSuggestion(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:46:      final building = buildElementAutoShadowSuggestion(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:52:      expect(building!.kind, ElementAutoShadowSuggestionKind.buildingLarge);
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:57:      final suggestion = buildElementAutoShadowSuggestion(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:66:      final suggestion = buildElementAutoShadowSuggestion(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:75:      final suggestion = buildElementAutoShadowSuggestion(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:84:      final suggestion = buildElementAutoShadowSuggestion(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:89:      expect(suggestion!.kind, ElementAutoShadowSuggestionKind.buildingLarge);
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:113:      final suggestion = buildElementAutoShadowSuggestion(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:127:  group('applyElementAutoShadowPolicyToProject', () {
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:129:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:154:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:179:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:207:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:232:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:270:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:525:          family: shadow.family ?? StaticShadowFamily.genericProjection,
packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart:29:        ElementAutoShadowSuggestionKind.buildingLarge,
packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart:173:    test('clears genericProjection auto shadow when policy has no suggestion',
packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart:431:      final coreResult = applyElementAutoShadowPolicyToProject(project);
packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart:498:    family: StaticShadowFamily.genericProjection,
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart:6:        buildElementAutoShadowSuggestion;
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart:10:  group('buildElementAutoShadowSuggestion', () {
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart:12:      final suggestion = buildElementAutoShadowSuggestion(
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart:30:      final suggestion = buildElementAutoShadowSuggestion(
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart:39:      final invalidWidth = buildElementAutoShadowSuggestion(
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart:43:      final invalidHeight = buildElementAutoShadowSuggestion(
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart:54:      final oneByOne = buildElementAutoShadowSuggestion(
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart:58:      final oneByTwo = buildElementAutoShadowSuggestion(
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart:68:      final suggestion = buildElementAutoShadowSuggestion(
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart:76:    test('classifies large buildings as buildingLarge', () {
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart:77:      final suggestion = buildElementAutoShadowSuggestion(
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart:82:      expect(suggestion.kind, ElementAutoShadowSuggestionKind.buildingLarge);
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart:94:      final smallWide = buildElementAutoShadowSuggestion(
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart:98:      final suggestion = buildElementAutoShadowSuggestion(
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart:108:      final suggestion = buildElementAutoShadowSuggestion(
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart:117:      final suggestion = buildElementAutoShadowSuggestion(
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart:125:    test('prefers default wide profile for buildingLarge', () {
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart:126:      final suggestion = buildElementAutoShadowSuggestion(
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart:140:      final building = buildElementAutoShadowSuggestion(
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart:189:  yield buildElementAutoShadowSuggestion(
```

## 10. Résultats des tests ciblés

### 10.1 RED — test core avant production

Commande :

```bash
cd packages/map_core && dart test test/shadow/element_auto_shadow_policy_test.dart
```

Sortie utile complète des échecs attendus :

```text
00:00 +0: loading test/shadow/element_auto_shadow_policy_test.dart
00:00 +0: buildElementAutoShadowSuggestion small square and default prop return null
00:00 +1: buildElementAutoShadowSuggestion small square and default prop return null
00:00 +1: buildElementAutoShadowSuggestion wide low returns null under safe default policy
00:00 +1 -1: buildElementAutoShadowSuggestion wide low returns null under safe default policy [E]
  Expected: null
    Actual: <Instance of 'ElementAutoShadowSuggestion'>

  package:matcher                                        expect
  test/shadow/element_auto_shadow_policy_test.dart 32:7  main.<fn>.<fn>

00:00 +1 -1: buildElementAutoShadowSuggestion tall thin returns null while building receives suggestion
00:00 +1 -2: buildElementAutoShadowSuggestion tall thin returns null while building receives suggestion [E]
  Expected: null
    Actual: <Instance of 'ElementAutoShadowSuggestion'>

  package:matcher                                        expect
  test/shadow/element_auto_shadow_policy_test.dart 51:7  main.<fn>.<fn>

00:00 +1 -2: buildElementAutoShadowSuggestion Selbrume lamp proportions receive no automatic shadow
00:00 +1 -3: buildElementAutoShadowSuggestion Selbrume lamp proportions receive no automatic shadow [E]
  Expected: null
    Actual: <Instance of 'ElementAutoShadowSuggestion'>

  package:matcher                                        expect
  test/shadow/element_auto_shadow_policy_test.dart 62:7  main.<fn>.<fn>

00:00 +1 -3: buildElementAutoShadowSuggestion Selbrume wide barriers receive no automatic shadow
00:00 +1 -4: buildElementAutoShadowSuggestion Selbrume wide barriers receive no automatic shadow [E]
  Expected: null
    Actual: <Instance of 'ElementAutoShadowSuggestion'>

  package:matcher                                        expect
  test/shadow/element_auto_shadow_policy_test.dart 71:7  main.<fn>.<fn>

00:00 +7 -5: applyElementAutoShadowPolicyToProject backfill clears broad legacy Selbrume shadow without safe suggestion [E]
  Expected: <0>
    Actual: <1>

  package:matcher                                         expect
  test/shadow/element_auto_shadow_policy_test.dart 221:7  main.<fn>.<fn>

00:00 +8 -6: applyElementAutoShadowPolicyToProject backfill clears unsafe Shadow-53 auto shadows but keeps building [E]
  Expected: <1>
    Actual: <3>

  package:matcher                                         expect
  test/shadow/element_auto_shadow_policy_test.dart 296:7  main.<fn>.<fn>

00:00 +8 -6: Some tests failed.
```

### 10.2 GREEN — core ciblé

Commande :

```bash
cd packages/map_core && dart test test/shadow/element_auto_shadow_policy_test.dart
```

Sortie complète :

```text
00:00 +0: loading test/shadow/element_auto_shadow_policy_test.dart
00:00 +0: buildElementAutoShadowSuggestion small square and default prop return null
00:00 +1: buildElementAutoShadowSuggestion small square and default prop return null
00:00 +1: buildElementAutoShadowSuggestion wide low returns null under safe default policy
00:00 +2: buildElementAutoShadowSuggestion wide low returns null under safe default policy
00:00 +2: buildElementAutoShadowSuggestion tall thin returns null while building receives suggestion
00:00 +3: buildElementAutoShadowSuggestion tall thin returns null while building receives suggestion
00:00 +3: buildElementAutoShadowSuggestion Selbrume lamp proportions receive no automatic shadow
00:00 +4: buildElementAutoShadowSuggestion Selbrume lamp proportions receive no automatic shadow
00:00 +4: buildElementAutoShadowSuggestion Selbrume wide barriers receive no automatic shadow
00:00 +5: buildElementAutoShadowSuggestion Selbrume wide barriers receive no automatic shadow
00:00 +5: buildElementAutoShadowSuggestion panneau-like small wide props receive no automatic shadow
00:00 +6: buildElementAutoShadowSuggestion panneau-like small wide props receive no automatic shadow
00:00 +6: buildElementAutoShadowSuggestion Selbrume houses receive calibrated building config
00:00 +7: buildElementAutoShadowSuggestion Selbrume houses receive calibrated building config
00:00 +7: buildElementAutoShadowSuggestion Shadow-54 building auto config projects far less area than legacy broad
00:00 +8: buildElementAutoShadowSuggestion Shadow-54 building auto config projects far less area than legacy broad
00:00 +8: applyElementAutoShadowPolicyToProject backfill clears recognized old auto shadows without suggestion
00:00 +9: applyElementAutoShadowPolicyToProject backfill clears recognized old auto shadows without suggestion
00:00 +9: applyElementAutoShadowPolicyToProject backfill applies eligible missing building shadows
00:00 +10: applyElementAutoShadowPolicyToProject backfill applies eligible missing building shadows
00:00 +10: applyElementAutoShadowPolicyToProject manual and disabled shadows are preserved
00:00 +11: applyElementAutoShadowPolicyToProject manual and disabled shadows are preserved
00:00 +11: applyElementAutoShadowPolicyToProject backfill clears broad legacy Selbrume shadow without safe suggestion
00:00 +12: applyElementAutoShadowPolicyToProject backfill clears broad legacy Selbrume shadow without safe suggestion
00:00 +12: applyElementAutoShadowPolicyToProject backfill replaces broad legacy Selbrume building shadow
00:00 +13: applyElementAutoShadowPolicyToProject backfill replaces broad legacy Selbrume building shadow
00:00 +13: applyElementAutoShadowPolicyToProject backfill clears unsafe Shadow-53 auto shadows but keeps building
00:00 +14: applyElementAutoShadowPolicyToProject backfill clears unsafe Shadow-53 auto shadows but keeps building
00:00 +14: All tests passed!
```

### 10.3 GREEN — editor suggestion ciblé

Commande :

```bash
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_suggestion_test.dart
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart
00:00 +0: buildElementAutoShadowSuggestion returns null without compatible ground static profile
00:00 +1: buildElementAutoShadowSuggestion returns null for missing frames
00:00 +2: buildElementAutoShadowSuggestion returns null for invalid first frame source
00:00 +3: buildElementAutoShadowSuggestion returns null for micro decor that should not cast projected shadows
00:00 +4: buildElementAutoShadowSuggestion returns null for tall thin elements under safe default policy
00:00 +5: buildElementAutoShadowSuggestion classifies large buildings as buildingLarge
00:00 +6: buildElementAutoShadowSuggestion wide low elements receive no automatic shadow
00:00 +7: buildElementAutoShadowSuggestion small square returns null under artistic V0 policy
00:00 +8: buildElementAutoShadowSuggestion default prop returns null under artistic V0 policy
00:00 +9: buildElementAutoShadowSuggestion prefers default wide profile for buildingLarge
00:00 +10: buildElementAutoShadowSuggestion falls back to custom compatible profile id for building
00:00 +11: buildElementAutoShadowSuggestion all suggestions have castsShadow true
00:00 +12: buildElementAutoShadowSuggestion all suggestion footprints are non-null and valid
00:00 +13: buildElementAutoShadowSuggestion all suggestions carry a static shadow family
00:00 +14: buildElementAutoShadowSuggestion all suggestion opacities are within 0..1
00:00 +15: buildElementAutoShadowSuggestion all suggestion scaleX and scaleY are greater than zero
00:00 +16: All tests passed!
```

### 10.4 GREEN — editor backfill ciblé

Commande :

```bash
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_backfill_test.dart
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart
00:00 +0: applyElementAutoShadowSuggestionsToProject applies suggestions only to safe building elements
00:00 +1: applyElementAutoShadowSuggestionsToProject clears unsafe generic pre-footprint active shadows
00:00 +2: applyElementAutoShadowSuggestionsToProject preserves disabled shadows
00:00 +3: applyElementAutoShadowSuggestionsToProject preserves manual footprints and numeric overrides
00:00 +4: applyElementAutoShadowSuggestionsToProject clears recognized auto small square shadow when policy has no suggestion
00:00 +5: applyElementAutoShadowSuggestionsToProject clears genericProjection auto shadow when policy has no suggestion
00:00 +6: applyElementAutoShadowSuggestionsToProject clears recognized auto wide low shadow below safe threshold
00:00 +7: applyElementAutoShadowSuggestionsToProject preserves manual footprint even if no suggestion exists
00:00 +8: applyElementAutoShadowSuggestionsToProject preserves non-default existing profile ids present in catalog
00:00 +9: applyElementAutoShadowSuggestionsToProject clears unsafe generic shadows with missing profile ids
00:00 +10: applyElementAutoShadowSuggestionsToProject adds default profiles when the catalog has no compatible profile
00:00 +11: applyElementAutoShadowSuggestionsToProject records skippedNoSuggestion for invalid element frames
00:00 +12: applyElementAutoShadowSuggestionsToProject preserves element order and non-shadow fields
00:00 +13: applyElementAutoShadowSuggestionsToProject editor wrapper stays in parity with core backfill operation
00:00 +14: All tests passed!
```

## 11. Lignes finales exactes des suites de régression

Commande :

```bash
cd packages/map_core && dart test test/shadow
```

Ligne finale exacte :

```text
00:00 +284: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test test/application/shadow
```

Ligne finale exacte :

```text
00:00 +96: All tests passed!
```

Commande :

```bash
cd packages/map_runtime && flutter test test/application/load_runtime_map_bundle_shadow_policy_test.dart
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/application/load_runtime_map_bundle_shadow_policy_test.dart
00:00 +0: loadProjectManifestFromFile authored shadow manifest keeps missing shadow configs absent at runtime load
00:00 +1: loadProjectManifestFromFile authored shadow manifest preserves recognized old auto shadows as authored data
00:00 +2: loadProjectManifestFromFile authored shadow manifest preserves manual and disabled shadows
00:00 +3: All tests passed!
```

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow
```

Ligne finale exacte :

```text
00:05 +233: All tests passed!
```

Note runtime :

```text
La suite runtime shadow a émis des logs runtime existants, notamment un fallback spawn dans un test de wiring. Aucun échec.
```

## 12. Résultat des analyses

Commande :

```bash
cd packages/map_core && dart analyze lib/src/operations/element_auto_shadow_policy.dart
```

Sortie exacte :

```text
Analyzing element_auto_shadow_policy.dart...
No issues found!
```

Commande :

```bash
cd packages/map_editor && flutter analyze lib/src/application/shadow
```

Sortie exacte :

```text
Analyzing shadow...
No issues found! (ran in 0.6s)
```

## 13. Impact produit

Impact attendu :

```text
Les futures suggestions/backfills automatiques ne créeront plus d’ombres pour lampadaires, wide props, small props, default props, ni genericProjection implicite.
Les anciennes auto-shadows unsafe reconnues sont nettoyées par le backfill explicite.
Les bâtiments larges gardent une suggestion building, compatible avec le chemin contact ledge minimal existant.
```

Limite importante :

```text
Ce lot ne nettoie pas Selbrume. Les configs déjà authorées dans /Users/karim/Desktop/selbrume restent inchangées jusqu’au lot de nettoyage explicite.
```

## 14. Ce qui n’a volontairement pas été modifié

```text
packages/map_runtime/lib/src/**
packages/map_runtime/test/**
packages/map_core/lib/src/models/shadow.dart
packages/map_core/lib/src/models/shadow_catalog.dart
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
packages/map_core/lib/src/operations/static_shadow_family_projection.dart
packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart
packages/map_core/lib/src/operations/shadow_config_resolver.dart
/Users/karim/Desktop/selbrume/project.json
/Users/karim/Desktop/selbrume/maps/Selbrume.json
```

Non-objectifs respectés :

```text
Aucun renderer modifié.
Aucun profil global modifié.
Aucun modèle Shadow modifié.
Aucun codec modifié.
Aucune géométrie projection/contact ledge modifiée.
Aucune UI ajoutée.
Aucune migration JSON.
Aucun build_runner.
Aucun generated file.
Aucun commit.
```

Vérification anti-dérive runtime/modèles/géométrie interdits :

Commande :

```bash
git diff --name-only | rg -n "packages/map_runtime|packages/map_core/lib/src/models/shadow.dart|packages/map_core/lib/src/models/shadow_catalog.dart|packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart|packages/map_core/lib/src/operations/static_shadow_family_projection.dart|packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart|packages/map_core/lib/src/operations/shadow_config_resolver.dart"
```

Sortie exacte :

```text

```

Vérification Selbrume/runtime supplémentaire :

Commande :

```bash
git diff --name-only | rg -n "map_runtime|/Users/karim/Desktop/selbrume|selbrume/project.json|selbrume/maps/Selbrume.json"
```

Sortie exacte :

```text

```

## 15. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie exacte avant création du rapport :

```text
 .../src/operations/element_auto_shadow_policy.dart |   3 +-
 .../shadow/element_auto_shadow_policy_test.dart    | 102 +++++++++------------
 .../shadow/element_auto_shadow_backfill_test.dart  |  58 ++++--------
 .../element_auto_shadow_suggestion_test.dart       |  68 +++-----------
 4 files changed, 77 insertions(+), 154 deletions(-)
```

## 16. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie exacte avant création du rapport :

```text
M	packages/map_core/lib/src/operations/element_auto_shadow_policy.dart
M	packages/map_core/test/shadow/element_auto_shadow_policy_test.dart
M	packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart
M	packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart
```

## 17. git diff --check

Commande :

```bash
git diff --check
```

Sortie exacte avant création du rapport :

```text

```

## 18. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M packages/map_core/lib/src/operations/element_auto_shadow_policy.dart
 M packages/map_core/test/shadow/element_auto_shadow_policy_test.dart
 M packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart
 M packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart
?? reports/shadows/shadow_lot_58_implementation_disable_unsafe_static_shadow_defaults.md
```

Interprétation :

```text
Les seuls fichiers modifiés sont les fichiers autorisés et le rapport du lot.
```

## 19. Risques / réserves

1. Les suggestions auto deviennent très conservatrices. C’est volontaire.
2. `buildingLarge` reste dimensionnel, donc pas encore asset-driven. C’est le dernier chemin auto V0 conservé.
3. Les configs Selbrume existantes restent authorées et donc visibles tant qu’un lot de nettoyage ne les modifie pas explicitement.
4. Les anciennes fonctions `_configForKind` gardent les configs des kinds désactivés pour compatibilité interne et reconnaissance legacy ; elles ne sont plus atteintes via la policy safe.
5. `genericProjection` reste présent dans le modèle et le renderer pour compatibilité, mais il n’est plus généré par défaut par la policy safe.

## 20. Auto-critique

Le changement est minimal et respecte le design validé. Il ne tente pas de corriger visuellement les ombres existantes, ce qui est important pour ne pas mélanger policy future et nettoyage de données authorées.

Le point le plus fragile reste le maintien de `buildingLarge` comme suggestion automatique. Si Selbrume montre encore des bâtiments moches après nettoyage des arbres/panneaux/lampadaires, le prochain durcissement devra rendre building opt-in ou asset-driven.

Le lancement Flutter parallèle initial a produit un verrou de démarrage Flutter. La cause a été identifiée : deux `flutter test` lancés en même temps dans `packages/map_editor`. Les vérifications finales ont été relancées séquentiellement et passent.

## 21. Regard critique sur le prompt

Le prompt est précis et utile : il sépare clairement stabilisation de policy, nettoyage Selbrume et non-objectifs runtime/renderer. La contrainte “ne pas modifier Selbrume” est importante, car elle empêche de mélanger un changement de comportement futur avec un patch de données existantes.

Le seul point à surveiller est l’exigence de tests runtime : ce lot ne modifie pas runtime, mais lancer les tests runtime était pertinent pour prouver que Shadow-56 reste en place et que l’absence d’auto-apply n’a pas régressé.

## 22. Prochain lot recommandé

```text
Shadow-59 — Selbrume Authored Shadow Cleanup Patch / Explicit Data Review
```

Objectif recommandé :

```text
Appliquer explicitement et seulement après validation le plan de nettoyage Selbrume : panneau, lampadaire, arbre_pixellab_1, arbre_pixellab_2, selbrume_maison_5.
Mesurer before/after runtime instructions.
Vérifier visuellement que les grandes plaques dangereuses disparaissent.
```

## 23. Code complet des fichiers modifiés

### packages/map_core/lib/src/operations/element_auto_shadow_policy.dart

```dart
import '../models/project_manifest.dart';
import '../models/shadow.dart';
import '../models/shadow_catalog.dart';
import 'default_shadow_profiles.dart';

enum ElementAutoShadowSuggestionKind {
  tallThin,
  buildingLarge,
  wideLow,
  smallSquare,
  defaultProp,
}

final class ElementAutoShadowSuggestion {
  const ElementAutoShadowSuggestion({
    required this.kind,
    required this.config,
    required this.summary,
  });

  final ElementAutoShadowSuggestionKind kind;
  final ProjectElementShadowConfig config;
  final String summary;
}

enum ElementAutoShadowBackfillStatus {
  appliedMissing,
  appliedGeneric,
  skippedDisabled,
  skippedManual,
  skippedNoSuggestion,
  clearedAutoNoSuggestion,
}

final class ElementAutoShadowBackfillEntry {
  const ElementAutoShadowBackfillEntry({
    required this.elementId,
    required this.elementName,
    required this.status,
    this.suggestionKind,
  });

  final String elementId;
  final String elementName;
  final ElementAutoShadowBackfillStatus status;
  final ElementAutoShadowSuggestionKind? suggestionKind;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ElementAutoShadowBackfillEntry &&
            elementId == other.elementId &&
            elementName == other.elementName &&
            status == other.status &&
            suggestionKind == other.suggestionKind;
  }

  @override
  int get hashCode => Object.hash(
        elementId,
        elementName,
        status,
        suggestionKind,
      );
}

final class ElementAutoShadowBackfillResult {
  const ElementAutoShadowBackfillResult({
    required this.project,
    required this.entries,
    required this.addedDefaultProfiles,
  });

  final ProjectManifest project;
  final List<ElementAutoShadowBackfillEntry> entries;
  final bool addedDefaultProfiles;

  int get appliedCount => entries
      .where(
        (entry) =>
            entry.status == ElementAutoShadowBackfillStatus.appliedMissing ||
            entry.status == ElementAutoShadowBackfillStatus.appliedGeneric,
      )
      .length;

  int get clearedCount => entries
      .where(
        (entry) =>
            entry.status ==
            ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
      )
      .length;

  int get changedCount => entries.where(_entryChangesProject).length;

  int get skippedCount => entries.length - changedCount;

  bool get hasChanges => addedDefaultProfiles || changedCount > 0;
}

ElementAutoShadowSuggestion? buildElementAutoShadowSuggestion({
  required ProjectElementEntry element,
  required ProjectShadowCatalog shadowCatalog,
}) {
  if (element.frames.isEmpty) {
    return null;
  }
  final source = element.frames.first.source;
  if (source.width <= 0 || source.height <= 0) {
    return null;
  }
  final width = source.width.toDouble();
  final height = source.height.toDouble();
  if (_isMicroDecor(
    width: width,
    height: height,
  )) {
    return null;
  }
  final kind = _classifyElement(
    width: width,
    height: height,
  );
  if (!_autoShadowKindIsArtisticallySafe(
    kind,
    width: width,
    height: height,
  )) {
    return null;
  }
  final profile = _profileForKind(shadowCatalog, kind);
  if (profile == null) {
    return null;
  }
  return ElementAutoShadowSuggestion(
    kind: kind,
    config: _configForKind(kind, profile.id),
    summary: _summaryForKind(kind),
  );
}

ElementAutoShadowBackfillResult applyElementAutoShadowPolicyToProject(
  ProjectManifest project,
) {
  final projectWithDefaults =
      ensureDefaultGroundStaticShadowProfilesForProject(project);
  final addedDefaultProfiles = projectWithDefaults != project;
  final entries = <ElementAutoShadowBackfillEntry>[];
  final elements = <ProjectElementEntry>[];

  for (final element in projectWithDefaults.elements) {
    final currentShadow = element.shadow;
    if (currentShadow != null && !currentShadow.castsShadow) {
      entries.add(
        _entry(element, ElementAutoShadowBackfillStatus.skippedDisabled),
      );
      elements.add(element);
      continue;
    }

    final suggestion = buildElementAutoShadowSuggestion(
      element: element,
      shadowCatalog: projectWithDefaults.shadowCatalog,
    );
    if (suggestion == null) {
      if (currentShadow != null &&
          _isRecognizedAutoShadow(
            currentShadow,
            projectWithDefaults.shadowCatalog,
          )) {
        entries.add(
          _entry(
            element,
            ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
          ),
        );
        elements.add(element.copyWith(shadow: null));
        continue;
      }
      entries.add(
        _entry(
          element,
          currentShadow == null
              ? ElementAutoShadowBackfillStatus.skippedNoSuggestion
              : ElementAutoShadowBackfillStatus.skippedManual,
        ),
      );
      elements.add(element);
      continue;
    }
    if (currentShadow != null &&
        !_isRecognizedAutoShadow(
          currentShadow,
          projectWithDefaults.shadowCatalog,
        )) {
      entries.add(
        _entry(element, ElementAutoShadowBackfillStatus.skippedManual),
      );
      elements.add(element);
      continue;
    }

    final status = currentShadow == null
        ? ElementAutoShadowBackfillStatus.appliedMissing
        : ElementAutoShadowBackfillStatus.appliedGeneric;
    entries.add(
      _entry(
        element,
        status,
        suggestionKind: suggestion.kind,
      ),
    );
    elements.add(element.copyWith(shadow: suggestion.config));
  }

  return ElementAutoShadowBackfillResult(
    project: addedDefaultProfiles || entries.any(_entryChangesProject)
        ? projectWithDefaults.copyWith(elements: elements)
        : project,
    entries: entries,
    addedDefaultProfiles: addedDefaultProfiles,
  );
}

bool _isMicroDecor({
  required double width,
  required double height,
}) {
  return width <= 1 && height <= 2;
}

ElementAutoShadowSuggestionKind _classifyElement({
  required double width,
  required double height,
}) {
  final area = width * height;
  final aspect = height / width;
  final wideAspect = width / height;
  if ((aspect >= 2.2 && width <= 2) ||
      (width <= 3 && height >= 5 && aspect >= 1.4)) {
    return ElementAutoShadowSuggestionKind.tallThin;
  }
  if (width >= 3 && height <= 2) {
    return ElementAutoShadowSuggestionKind.wideLow;
  }
  if (width >= 4 && height <= 6 && wideAspect >= 2.0) {
    return ElementAutoShadowSuggestionKind.wideLow;
  }
  if (width >= 4 || area >= 12) {
    return ElementAutoShadowSuggestionKind.buildingLarge;
  }
  if (width >= 3 && height <= 3) {
    return ElementAutoShadowSuggestionKind.wideLow;
  }
  if (area <= 4) {
    return ElementAutoShadowSuggestionKind.smallSquare;
  }
  return ElementAutoShadowSuggestionKind.defaultProp;
}

bool _autoShadowKindIsArtisticallySafe(
  ElementAutoShadowSuggestionKind kind, {
  required double width,
  required double height,
}) {
  switch (kind) {
    case ElementAutoShadowSuggestionKind.buildingLarge:
      return true;
    case ElementAutoShadowSuggestionKind.tallThin:
    case ElementAutoShadowSuggestionKind.wideLow:
    case ElementAutoShadowSuggestionKind.smallSquare:
    case ElementAutoShadowSuggestionKind.defaultProp:
      return false;
  }
}

ProjectShadowProfile? _profileForKind(
  ProjectShadowCatalog catalog,
  ElementAutoShadowSuggestionKind kind,
) {
  switch (kind) {
    case ElementAutoShadowSuggestionKind.tallThin:
    case ElementAutoShadowSuggestionKind.smallSquare:
      return _preferredCompactProfile(catalog);
    case ElementAutoShadowSuggestionKind.buildingLarge:
    case ElementAutoShadowSuggestionKind.wideLow:
      return _preferredWideProfile(catalog);
    case ElementAutoShadowSuggestionKind.defaultProp:
      return _preferredSoftProfile(catalog);
  }
}

ProjectShadowProfile? _preferredCompactProfile(ProjectShadowCatalog catalog) {
  return _compatibleProfileById(catalog, 'default-ground-contact-blob') ??
      _firstCompatibleProfileWithMode(catalog, ShadowCasterMode.contactBlob) ??
      _firstCompatibleProfile(catalog);
}

ProjectShadowProfile? _preferredWideProfile(ProjectShadowCatalog catalog) {
  return _compatibleProfileById(catalog, 'default-ground-wide-ellipse') ??
      _firstCompatibleProfileWithMode(catalog, ShadowCasterMode.ellipse) ??
      _firstCompatibleProfile(catalog);
}

ProjectShadowProfile? _preferredSoftProfile(ProjectShadowCatalog catalog) {
  return _compatibleProfileById(catalog, 'default-ground-soft-ellipse') ??
      _firstCompatibleProfileWithMode(catalog, ShadowCasterMode.ellipse) ??
      _firstCompatibleProfile(catalog);
}

ProjectShadowProfile? _compatibleProfileById(
  ProjectShadowCatalog catalog,
  String id,
) {
  final profile = catalog.profileById(id);
  if (profile == null || !isGroundStaticElementShadowProfile(profile)) {
    return null;
  }
  return profile;
}

ProjectShadowProfile? _firstCompatibleProfileWithMode(
  ProjectShadowCatalog catalog,
  ShadowCasterMode mode,
) {
  for (final profile in catalog.profiles) {
    if (profile.mode == mode && isGroundStaticElementShadowProfile(profile)) {
      return profile;
    }
  }
  return null;
}

ProjectShadowProfile? _firstCompatibleProfile(ProjectShadowCatalog catalog) {
  for (final profile in catalog.profiles) {
    if (isGroundStaticElementShadowProfile(profile)) {
      return profile;
    }
  }
  return null;
}

ProjectElementShadowConfig _configForKind(
  ElementAutoShadowSuggestionKind kind,
  String profileId,
) {
  switch (kind) {
    case ElementAutoShadowSuggestionKind.tallThin:
      return ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: profileId,
        offsetX: 0,
        offsetY: 0,
        scaleX: 0.80,
        scaleY: 0.55,
        opacity: 0.30,
        family: StaticShadowFamily.tallProp,
        footprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 1.0,
          footprintWidthRatio: 0.28,
          footprintHeightRatio: 0.05,
        ),
      );
    case ElementAutoShadowSuggestionKind.buildingLarge:
      return ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: profileId,
        offsetX: 0,
        offsetY: 0,
        scaleX: 0.72,
        scaleY: 0.48,
        opacity: 0.32,
        family: StaticShadowFamily.building,
        footprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 0.98,
          footprintWidthRatio: 0.60,
          footprintHeightRatio: 0.06,
        ),
      );
    case ElementAutoShadowSuggestionKind.wideLow:
      return ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: profileId,
        offsetX: 0,
        offsetY: 0,
        scaleX: 0.74,
        scaleY: 0.50,
        opacity: 0.28,
        family: StaticShadowFamily.compactProp,
        footprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 0.98,
          footprintWidthRatio: 0.58,
          footprintHeightRatio: 0.06,
        ),
      );
    case ElementAutoShadowSuggestionKind.smallSquare:
      return ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: profileId,
        offsetX: 0,
        offsetY: 0,
        scaleX: 0.78,
        scaleY: 0.70,
        opacity: 0.26,
        family: StaticShadowFamily.compactProp,
        footprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 0.96,
          footprintWidthRatio: 0.46,
          footprintHeightRatio: 0.10,
        ),
      );
    case ElementAutoShadowSuggestionKind.defaultProp:
      return ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: profileId,
        offsetX: 0,
        offsetY: 0,
        scaleX: 0.90,
        scaleY: 0.80,
        opacity: 0.28,
        family: StaticShadowFamily.genericProjection,
        footprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 0.95,
          footprintWidthRatio: 0.62,
          footprintHeightRatio: 0.12,
        ),
      );
  }
}

String _summaryForKind(ElementAutoShadowSuggestionKind kind) {
  switch (kind) {
    case ElementAutoShadowSuggestionKind.tallThin:
      return 'lampadaire fin';
    case ElementAutoShadowSuggestionKind.buildingLarge:
      return 'grand bâtiment';
    case ElementAutoShadowSuggestionKind.wideLow:
      return 'élément large et bas';
    case ElementAutoShadowSuggestionKind.smallSquare:
      return 'petit élément compact';
    case ElementAutoShadowSuggestionKind.defaultProp:
      return 'élément standard';
  }
}

bool _entryChangesProject(ElementAutoShadowBackfillEntry entry) {
  return entry.status == ElementAutoShadowBackfillStatus.appliedMissing ||
      entry.status == ElementAutoShadowBackfillStatus.appliedGeneric ||
      entry.status == ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion;
}

ElementAutoShadowBackfillEntry _entry(
  ProjectElementEntry element,
  ElementAutoShadowBackfillStatus status, {
  ElementAutoShadowSuggestionKind? suggestionKind,
}) {
  return ElementAutoShadowBackfillEntry(
    elementId: element.id,
    elementName: element.name,
    status: status,
    suggestionKind: suggestionKind,
  );
}

bool _isRecognizedAutoShadow(
  ProjectElementShadowConfig shadow,
  ProjectShadowCatalog catalog,
) {
  return _canReplaceExistingShadow(shadow, catalog) ||
      shadow == _oldAutoSmallSquareShadow() ||
      shadow == _oldAutoDefaultPropShadow() ||
      shadow == _oldAutoWideLowShadow() ||
      shadow == _shadow53TallThinShadow() ||
      shadow == _shadow53BuildingLargeShadow() ||
      shadow == _shadow53WideLowShadow() ||
      _isLegacyBroadSelbrumeAutoShadow(shadow);
}

bool _canReplaceExistingShadow(
  ProjectElementShadowConfig shadow,
  ProjectShadowCatalog catalog,
) {
  if (!shadow.castsShadow) {
    return false;
  }
  if (shadow.footprint != null) {
    return false;
  }
  if (shadow.offsetX != null ||
      shadow.offsetY != null ||
      shadow.scaleX != null ||
      shadow.scaleY != null ||
      shadow.opacity != null) {
    return false;
  }

  final profileId = shadow.shadowProfileId;
  if (profileId == null) {
    return true;
  }
  if (_defaultGroundStaticProfileIds.contains(profileId)) {
    return true;
  }
  return catalog.profileById(profileId) == null;
}

ProjectElementShadowConfig _oldAutoSmallSquareShadow() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-contact-blob',
    offsetX: 0,
    offsetY: 0,
    scaleX: 0.78,
    scaleY: 0.70,
    opacity: 0.26,
    family: StaticShadowFamily.compactProp,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.96,
      footprintWidthRatio: 0.46,
      footprintHeightRatio: 0.10,
    ),
  );
}

ProjectElementShadowConfig _oldAutoDefaultPropShadow() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-soft-ellipse',
    offsetX: 0,
    offsetY: 0,
    scaleX: 0.90,
    scaleY: 0.80,
    opacity: 0.28,
    family: StaticShadowFamily.genericProjection,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.95,
      footprintWidthRatio: 0.62,
      footprintHeightRatio: 0.12,
    ),
  );
}

ProjectElementShadowConfig _oldAutoWideLowShadow() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-wide-ellipse',
    offsetX: 0,
    offsetY: 0,
    scaleX: 0.92,
    scaleY: 0.75,
    opacity: 0.27,
    family: StaticShadowFamily.compactProp,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.95,
      footprintWidthRatio: 0.72,
      footprintHeightRatio: 0.10,
    ),
  );
}

ProjectElementShadowConfig _shadow53TallThinShadow() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-contact-blob',
    offsetX: 0,
    offsetY: 0,
    scaleX: 0.80,
    scaleY: 0.55,
    opacity: 0.20,
    family: StaticShadowFamily.tallProp,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 1.0,
      footprintWidthRatio: 0.28,
      footprintHeightRatio: 0.05,
    ),
  );
}

ProjectElementShadowConfig _shadow53BuildingLargeShadow() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-wide-ellipse',
    offsetX: 0,
    offsetY: 0,
    scaleX: 0.72,
    scaleY: 0.48,
    opacity: 0.20,
    family: StaticShadowFamily.building,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.98,
      footprintWidthRatio: 0.60,
      footprintHeightRatio: 0.06,
    ),
  );
}

ProjectElementShadowConfig _shadow53WideLowShadow() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-wide-ellipse',
    offsetX: 0,
    offsetY: 0,
    scaleX: 0.74,
    scaleY: 0.50,
    opacity: 0.20,
    family: StaticShadowFamily.compactProp,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.98,
      footprintWidthRatio: 0.58,
      footprintHeightRatio: 0.06,
    ),
  );
}

bool _isLegacyBroadSelbrumeAutoShadow(ProjectElementShadowConfig shadow) {
  if (!shadow.castsShadow ||
      shadow.shadowProfileId != 'default-ground-wide-ellipse' ||
      shadow.offsetX != 0 ||
      shadow.offsetY != 0 ||
      shadow.scaleX != 1 ||
      shadow.scaleY != 0.85 ||
      shadow.opacity != 0.30) {
    return false;
  }
  final family = shadow.family;
  if (family != null &&
      family != StaticShadowFamily.building &&
      family != StaticShadowFamily.compactProp) {
    return false;
  }
  return shadow.footprint ==
      StaticShadowFootprintConfig(
        anchorXRatio: 0.5,
        anchorYRatio: 0.92,
        footprintWidthRatio: 0.82,
        footprintHeightRatio: 0.12,
      );
}

const _defaultGroundStaticProfileIds = <String>{
  'default-ground-soft-ellipse',
  'default-ground-wide-ellipse',
  'default-ground-contact-blob',
};

```

### packages/map_core/test/shadow/element_auto_shadow_policy_test.dart

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('buildElementAutoShadowSuggestion', () {
    test('small square and default prop return null', () {
      expect(
        buildElementAutoShadowSuggestion(
          element: _element(id: 'small', width: 2, height: 2),
          shadowCatalog: _defaultCatalog(),
        ),
        isNull,
      );
      expect(
        buildElementAutoShadowSuggestion(
          element: _element(id: 'prop', width: 2, height: 3),
          shadowCatalog: _defaultCatalog(),
        ),
        isNull,
      );
    });

    test('wide low returns null under safe default policy', () {
      expect(
        buildElementAutoShadowSuggestion(
          element: _element(id: 'small-wide', width: 3, height: 2),
          shadowCatalog: _defaultCatalog(),
        ),
        isNull,
      );

      expect(
        buildElementAutoShadowSuggestion(
          element: _element(id: 'wide', width: 4, height: 2),
          shadowCatalog: _defaultCatalog(),
        ),
        isNull,
      );
    });

    test('tall thin returns null while building receives suggestion', () {
      final tall = buildElementAutoShadowSuggestion(
        element: _element(id: 'lamp', width: 1, height: 4),
        shadowCatalog: _defaultCatalog(),
      );
      final building = buildElementAutoShadowSuggestion(
        element: _element(id: 'house', width: 4, height: 3),
        shadowCatalog: _defaultCatalog(),
      );

      expect(tall, isNull);
      expect(building!.kind, ElementAutoShadowSuggestionKind.buildingLarge);
      expect(building.config.family, StaticShadowFamily.building);
    });

    test('Selbrume lamp proportions receive no automatic shadow', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(id: 'lampadaire', width: 3, height: 5),
        shadowCatalog: _defaultCatalog(),
      );

      expect(suggestion, isNull);
    });

    test('Selbrume wide barriers receive no automatic shadow', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(id: 'barriere_pierre', width: 13, height: 6),
        shadowCatalog: _defaultCatalog(),
      );

      expect(suggestion, isNull);
    });

    test('panneau-like small wide props receive no automatic shadow', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(id: 'panneau', width: 3, height: 3),
        shadowCatalog: _defaultCatalog(),
      );

      expect(suggestion, isNull);
    });

    test('Selbrume houses receive calibrated building config', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(id: 'maison', width: 6, height: 7),
        shadowCatalog: _defaultCatalog(),
      );

      expect(suggestion!.kind, ElementAutoShadowSuggestionKind.buildingLarge);
      _expectConfig(
        suggestion.config,
        profileId: 'default-ground-wide-ellipse',
        scaleX: 0.72,
        scaleY: 0.48,
        opacity: 0.32,
        family: StaticShadowFamily.building,
        anchorXRatio: 0.5,
        anchorYRatio: 0.98,
        footprintWidthRatio: 0.60,
        footprintHeightRatio: 0.06,
      );
    });

    test(
        'Shadow-54 building auto config projects far less area than legacy broad',
        () {
      final legacy = _projectedAreaForShadow(
        _legacyBroadSelbrumeShadow(family: StaticShadowFamily.building),
        visualWidth: 192,
        visualHeight: 224,
        projectionSpec: _legacyBuildingProjectionSpec(),
      );
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(id: 'maison', width: 6, height: 7),
        shadowCatalog: _defaultCatalog(),
      )!;
      final v1 = _projectedAreaForShadow(
        suggestion.config,
        visualWidth: 192,
        visualHeight: 224,
      );

      expect(v1, lessThan(legacy * 0.30));
    });
  });

  group('applyElementAutoShadowPolicyToProject', () {
    test('backfill clears recognized old auto shadows without suggestion', () {
      final result = applyElementAutoShadowPolicyToProject(
        _project(
          elements: [
            _element(
              id: 'small',
              width: 2,
              height: 2,
              shadow: _oldAutoSmallSquareShadow(),
            ),
          ],
          shadowCatalog: _defaultCatalog(),
        ),
      );

      expect(result.appliedCount, 0);
      expect(result.clearedCount, 1);
      expect(result.changedCount, 1);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
      );
      expect(result.project.elements.single.shadow, isNull);
    });

    test('backfill applies eligible missing building shadows', () {
      final result = applyElementAutoShadowPolicyToProject(
        _project(
          elements: [
            _element(id: 'house', width: 4, height: 3),
          ],
          shadowCatalog: const ProjectShadowCatalog.empty(),
        ),
      );

      expect(result.addedDefaultProfiles, isTrue);
      expect(result.appliedCount, 1);
      expect(result.clearedCount, 0);
      expect(result.changedCount, 1);
      expect(
        result.project.elements.single.shadow!.shadowProfileId,
        'default-ground-wide-ellipse',
      );
    });

    test('manual and disabled shadows are preserved', () {
      final manual = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'custom-ground-shadow',
      );
      final disabled = ProjectElementShadowConfig(castsShadow: false);
      final result = applyElementAutoShadowPolicyToProject(
        _project(
          elements: [
            _element(id: 'manual', width: 2, height: 2, shadow: manual),
            _element(id: 'disabled', width: 4, height: 3, shadow: disabled),
          ],
          shadowCatalog: ProjectShadowCatalog(
            profiles: [
              ...createDefaultGroundStaticShadowProfiles(),
              ProjectShadowProfile(
                id: 'custom-ground-shadow',
                name: 'Custom ground shadow',
                mode: ShadowCasterMode.ellipse,
                renderPass: ShadowRenderPass.groundStatic,
              ),
            ],
          ),
        ),
      );

      expect(result.changedCount, 0);
      expect(result.hasChanges, isFalse);
      expect(result.project.elements[0].shadow, manual);
      expect(result.project.elements[1].shadow, disabled);
    });

    test('backfill clears broad legacy Selbrume shadow without safe suggestion',
        () {
      final result = applyElementAutoShadowPolicyToProject(
        _project(
          elements: [
            _element(
              id: 'lampadaire',
              width: 3,
              height: 5,
              shadow: _legacyBroadSelbrumeShadow(),
            ),
          ],
          shadowCatalog: _defaultCatalog(),
        ),
      );

      expect(result.appliedCount, 0);
      expect(result.clearedCount, 1);
      expect(result.changedCount, 1);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
      );
      expect(result.project.elements.single.shadow, isNull);
    });

    test('backfill replaces broad legacy Selbrume building shadow', () {
      final result = applyElementAutoShadowPolicyToProject(
        _project(
          elements: [
            _element(
              id: 'maison',
              width: 6,
              height: 7,
              shadow: _legacyBroadSelbrumeShadow(
                family: StaticShadowFamily.building,
              ),
            ),
          ],
          shadowCatalog: _defaultCatalog(),
        ),
      );

      expect(result.appliedCount, 1);
      expect(result.changedCount, 1);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.appliedGeneric,
      );
      _expectConfig(
        result.project.elements.single.shadow!,
        profileId: 'default-ground-wide-ellipse',
        scaleX: 0.72,
        scaleY: 0.48,
        opacity: 0.32,
        family: StaticShadowFamily.building,
        anchorXRatio: 0.5,
        anchorYRatio: 0.98,
        footprintWidthRatio: 0.60,
        footprintHeightRatio: 0.06,
      );
    });

    test('backfill clears unsafe Shadow-53 auto shadows but keeps building',
        () {
      final result = applyElementAutoShadowPolicyToProject(
        _project(
          elements: [
            _element(
              id: 'lampadaire',
              width: 3,
              height: 5,
              shadow: _shadow53TallThinShadow(),
            ),
            _element(
              id: 'maison',
              width: 6,
              height: 7,
              shadow: _shadow53BuildingLargeShadow(),
            ),
            _element(
              id: 'barriere_pierre',
              width: 13,
              height: 6,
              shadow: _shadow53WideLowShadow(),
            ),
          ],
          shadowCatalog: _defaultCatalog(),
        ),
      );

      expect(result.appliedCount, 1);
      expect(result.clearedCount, 2);
      expect(result.changedCount, 3);
      expect(
        result.entries.map((entry) => entry.status),
        [
          ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
          ElementAutoShadowBackfillStatus.appliedGeneric,
          ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
        ],
      );
      expect(result.project.elements[0].shadow, isNull);
      expect(result.project.elements[1].shadow!.opacity, 0.32);
      expect(result.project.elements[2].shadow, isNull);
    });
  });
}

ProjectManifest _project({
  required List<ProjectElementEntry> elements,
  required ProjectShadowCatalog shadowCatalog,
}) {
  return ProjectManifest(
    name: 'Auto shadow policy test',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'tileset_main',
        name: 'Main tileset',
        relativePath: 'tilesets/main.png',
      ),
    ],
    elementCategories: const <ProjectElementCategory>[
      ProjectElementCategory(id: 'decor', name: 'Decor'),
    ],
    elements: elements,
    shadowCatalog: shadowCatalog,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

ProjectShadowCatalog _defaultCatalog() {
  return ProjectShadowCatalog(
    profiles: createDefaultGroundStaticShadowProfiles(),
  );
}

ProjectElementEntry _element({
  required String id,
  required int width,
  required int height,
  ProjectElementShadowConfig? shadow,
}) {
  return ProjectElementEntry(
    id: id,
    name: id,
    tilesetId: 'tileset_main',
    categoryId: 'decor',
    frames: [
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0, width: width, height: height),
      ),
    ],
    shadow: shadow,
  );
}

ProjectElementShadowConfig _oldAutoSmallSquareShadow() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-contact-blob',
    offsetX: 0,
    offsetY: 0,
    scaleX: 0.78,
    scaleY: 0.70,
    opacity: 0.26,
    family: StaticShadowFamily.compactProp,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.96,
      footprintWidthRatio: 0.46,
      footprintHeightRatio: 0.10,
    ),
  );
}

ProjectElementShadowConfig _legacyBroadSelbrumeShadow({
  StaticShadowFamily? family,
}) {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-wide-ellipse',
    offsetX: 0,
    offsetY: 0,
    scaleX: 1,
    scaleY: 0.85,
    opacity: 0.30,
    family: family,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.92,
      footprintWidthRatio: 0.82,
      footprintHeightRatio: 0.12,
    ),
  );
}

ProjectElementShadowConfig _shadow53TallThinShadow() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-contact-blob',
    offsetX: 0,
    offsetY: 0,
    scaleX: 0.80,
    scaleY: 0.55,
    opacity: 0.20,
    family: StaticShadowFamily.tallProp,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 1.0,
      footprintWidthRatio: 0.28,
      footprintHeightRatio: 0.05,
    ),
  );
}

ProjectElementShadowConfig _shadow53BuildingLargeShadow() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-wide-ellipse',
    offsetX: 0,
    offsetY: 0,
    scaleX: 0.72,
    scaleY: 0.48,
    opacity: 0.20,
    family: StaticShadowFamily.building,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.98,
      footprintWidthRatio: 0.60,
      footprintHeightRatio: 0.06,
    ),
  );
}

ProjectElementShadowConfig _shadow53WideLowShadow() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-wide-ellipse',
    offsetX: 0,
    offsetY: 0,
    scaleX: 0.74,
    scaleY: 0.50,
    opacity: 0.20,
    family: StaticShadowFamily.compactProp,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.98,
      footprintWidthRatio: 0.58,
      footprintHeightRatio: 0.06,
    ),
  );
}

void _expectConfig(
  ProjectElementShadowConfig config, {
  required String profileId,
  required double scaleX,
  required double scaleY,
  required double opacity,
  required StaticShadowFamily family,
  required double anchorXRatio,
  required double anchorYRatio,
  required double footprintWidthRatio,
  required double footprintHeightRatio,
}) {
  expect(config.castsShadow, isTrue);
  expect(config.shadowProfileId, profileId);
  expect(config.offsetX, 0);
  expect(config.offsetY, 0);
  expect(config.scaleX, closeTo(scaleX, 0.0000001));
  expect(config.scaleY, closeTo(scaleY, 0.0000001));
  expect(config.opacity, closeTo(opacity, 0.0000001));
  expect(config.family, family);
  expect(config.footprint!.anchorXRatio, closeTo(anchorXRatio, 0.0000001));
  expect(config.footprint!.anchorYRatio, closeTo(anchorYRatio, 0.0000001));
  expect(
    config.footprint!.footprintWidthRatio,
    closeTo(footprintWidthRatio, 0.0000001),
  );
  expect(
    config.footprint!.footprintHeightRatio,
    closeTo(footprintHeightRatio, 0.0000001),
  );
}

double _projectedAreaForShadow(
  ProjectElementShadowConfig shadow, {
  required double visualWidth,
  required double visualHeight,
  StaticShadowProjectionSpec? projectionSpec,
}) {
  final metrics = StaticShadowVisualMetrics(
    left: 0,
    top: 0,
    visualWidth: visualWidth,
    visualHeight: visualHeight,
  );
  final geometry = resolveStaticShadowGeometry(
    metrics: metrics,
    shadowConfig: ResolvedShadowConfig(
      shadowProfileId: shadow.shadowProfileId!,
      mode: ShadowCasterMode.ellipse,
      renderPass: ShadowRenderPass.groundStatic,
      offsetX: shadow.offsetX ?? 0,
      offsetY: shadow.offsetY ?? 0,
      scaleX: shadow.scaleX ?? 1,
      scaleY: shadow.scaleY ?? 1,
      opacity: shadow.opacity ?? 0.35,
      colorHexRgb: '000000',
      softnessMode: ShadowSoftnessMode.hardEdge,
    ),
    elementFootprint: shadow.footprint,
  );
  final projected = resolveProjectedStaticShadowGeometry(
    baseGeometry: geometry,
    metrics: metrics,
    projectionSpec: projectionSpec ??
        resolveStaticShadowFamilyProjectionSpec(
          family: shadow.family ?? StaticShadowFamily.genericProjection,
        ),
  );
  return _projectedPolygonArea(projected.points);
}

StaticShadowProjectionSpec _legacyBuildingProjectionSpec() {
  return StaticShadowProjectionSpec(
    directionX: defaultStaticShadowProjectionDirectionX,
    directionY: defaultStaticShadowProjectionDirectionY,
    lengthRatio: 0.1984,
    nearWidthMultiplier: 0.7176,
    farWidthMultiplier: 0.7316,
  );
}

double _projectedPolygonArea(List<ProjectedStaticShadowPoint> points) {
  var area = 0.0;
  for (var index = 0; index < points.length; index += 1) {
    final current = points[index];
    final next = points[(index + 1) % points.length];
    area += current.x * next.y - next.x * current.y;
  }
  return area.abs() / 2;
}

```

### packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart'
    hide
        ElementAutoShadowSuggestion,
        ElementAutoShadowSuggestionKind,
        buildElementAutoShadowSuggestion;
import 'package:map_editor/src/application/shadow/element_auto_shadow_suggestion.dart';

void main() {
  group('buildElementAutoShadowSuggestion', () {
    test('returns null without compatible ground static profile', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 1, height: 4),
        shadowCatalog: ProjectShadowCatalog(
          profiles: [
            _profile(
              'actor_contact',
              mode: ShadowCasterMode.contactBlob,
              renderPass: ShadowRenderPass.actorContact,
            ),
            _profile('none', mode: ShadowCasterMode.none),
          ],
        ),
      );

      expect(suggestion, isNull);
    });

    test('returns null for missing frames', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _elementWithFrames(const []),
        shadowCatalog: _defaultCatalog(),
      );

      expect(suggestion, isNull);
    });

    test('returns null for invalid first frame source', () {
      final invalidWidth = buildElementAutoShadowSuggestion(
        element: _element(width: 0, height: 4),
        shadowCatalog: _defaultCatalog(),
      );
      final invalidHeight = buildElementAutoShadowSuggestion(
        element: _element(width: 1, height: 0),
        shadowCatalog: _defaultCatalog(),
      );

      expect(invalidWidth, isNull);
      expect(invalidHeight, isNull);
    });

    test('returns null for micro decor that should not cast projected shadows',
        () {
      final oneByOne = buildElementAutoShadowSuggestion(
        element: _element(width: 1, height: 1),
        shadowCatalog: _defaultCatalog(),
      );
      final oneByTwo = buildElementAutoShadowSuggestion(
        element: _element(width: 1, height: 2),
        shadowCatalog: _defaultCatalog(),
      );

      expect(oneByOne, isNull);
      expect(oneByTwo, isNull);
    });

    test('returns null for tall thin elements under safe default policy', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 1, height: 4),
        shadowCatalog: _defaultCatalog(),
      );

      expect(suggestion, isNull);
    });

    test('classifies large buildings as buildingLarge', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 4, height: 3),
        shadowCatalog: _defaultCatalog(),
      )!;

      expect(suggestion.kind, ElementAutoShadowSuggestionKind.buildingLarge);
      expect(suggestion.config.shadowProfileId, 'default-ground-wide-ellipse');
      expect(suggestion.config.family, StaticShadowFamily.building);
      expect(suggestion.config.footprint!.anchorYRatio, 0.98);
      expect(suggestion.config.footprint!.footprintWidthRatio, 0.60);
      expect(suggestion.config.footprint!.footprintHeightRatio, 0.06);
      expect(suggestion.config.scaleX, 0.72);
      expect(suggestion.config.scaleY, 0.48);
      expect(suggestion.config.opacity, 0.32);
    });

    test('wide low elements receive no automatic shadow', () {
      final smallWide = buildElementAutoShadowSuggestion(
        element: _element(width: 3, height: 2),
        shadowCatalog: _defaultCatalog(),
      );
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 4, height: 2),
        shadowCatalog: _defaultCatalog(),
      );

      expect(smallWide, isNull);
      expect(suggestion, isNull);
    });

    test('small square returns null under artistic V0 policy', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 2, height: 2),
        shadowCatalog: _defaultCatalog(),
      );

      expect(suggestion, isNull);
    });

    test('default prop returns null under artistic V0 policy', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 2, height: 3),
        shadowCatalog: _defaultCatalog(),
      );

      expect(suggestion, isNull);
    });

    test('prefers default wide profile for buildingLarge', () {
      final suggestion = buildElementAutoShadowSuggestion(
        element: _element(width: 4, height: 3),
        shadowCatalog: ProjectShadowCatalog(
          profiles: [
            _profile('custom-soft'),
            _profile('default-ground-wide-ellipse'),
          ],
        ),
      )!;

      expect(suggestion.config.shadowProfileId, 'default-ground-wide-ellipse');
    });

    test('falls back to custom compatible profile id for building', () {
      final building = buildElementAutoShadowSuggestion(
        element: _element(width: 4, height: 3),
        shadowCatalog: ProjectShadowCatalog(
          profiles: [_profile('custom-ellipse')],
        ),
      )!;

      expect(building.config.shadowProfileId, 'custom-ellipse');
    });

    test('all suggestions have castsShadow true', () {
      for (final suggestion in _allSuggestionKinds()) {
        expect(suggestion.config.castsShadow, isTrue);
      }
    });

    test('all suggestion footprints are non-null and valid', () {
      for (final suggestion in _allSuggestionKinds()) {
        final footprint = suggestion.config.footprint;
        expect(footprint, isNotNull);
        expect(footprint!.anchorXRatio, inInclusiveRange(0, 1));
        expect(footprint.anchorYRatio, inInclusiveRange(0, 1));
        expect(footprint.footprintWidthRatio, greaterThan(0));
        expect(footprint.footprintHeightRatio, greaterThan(0));
      }
    });

    test('all suggestions carry a static shadow family', () {
      for (final suggestion in _allSuggestionKinds()) {
        expect(suggestion.config.family, isNotNull);
      }
    });

    test('all suggestion opacities are within 0..1', () {
      for (final suggestion in _allSuggestionKinds()) {
        expect(suggestion.config.opacity, inInclusiveRange(0, 1));
      }
    });

    test('all suggestion scaleX and scaleY are greater than zero', () {
      for (final suggestion in _allSuggestionKinds()) {
        expect(suggestion.config.scaleX, greaterThan(0));
        expect(suggestion.config.scaleY, greaterThan(0));
      }
    });
  });
}

Iterable<ElementAutoShadowSuggestion> _allSuggestionKinds() sync* {
  yield buildElementAutoShadowSuggestion(
    element: _element(width: 4, height: 3),
    shadowCatalog: _defaultCatalog(),
  )!;
}

ProjectShadowCatalog _defaultCatalog() {
  return ProjectShadowCatalog(
    profiles: createDefaultGroundStaticShadowProfiles(),
  );
}

ProjectElementEntry _element({
  required int width,
  required int height,
}) {
  return _elementWithFrames([
    TilesetVisualFrame(
      source: TilesetSourceRect(x: 0, y: 0, width: width, height: height),
    ),
  ]);
}

ProjectElementEntry _elementWithFrames(List<TilesetVisualFrame> frames) {
  return ProjectElementEntry(
    id: 'element',
    name: 'Element',
    tilesetId: 'tileset',
    categoryId: 'decor',
    frames: frames,
  );
}

ProjectShadowProfile _profile(
  String id, {
  ShadowCasterMode mode = ShadowCasterMode.ellipse,
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
}) {
  return ProjectShadowProfile(
    id: id,
    name: '$id shadow',
    mode: mode,
    renderPass: renderPass,
  );
}

```

### packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart' hide ElementAutoShadowSuggestionKind;
import 'package:map_editor/src/application/shadow/element_auto_shadow_backfill.dart';
import 'package:map_editor/src/application/shadow/element_auto_shadow_suggestion.dart';

void main() {
  group('applyElementAutoShadowSuggestionsToProject', () {
    test('applies suggestions only to safe building elements', () {
      final project = _project(
        elements: [
          _element(id: 'lamp', name: 'Lamp', width: 1, height: 4),
          _element(id: 'house', name: 'House', width: 4, height: 3),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 1);
      expect(result.skippedCount, 1);
      expect(result.hasChanges, isTrue);
      expect(result.addedDefaultProfiles, isFalse);
      expect(result.entries.map((entry) => entry.status), [
        ElementAutoShadowBackfillStatus.skippedNoSuggestion,
        ElementAutoShadowBackfillStatus.appliedMissing,
      ]);
      expect(result.entries.map((entry) => entry.suggestionKind), [
        null,
        ElementAutoShadowSuggestionKind.buildingLarge,
      ]);
      expect(result.project.elements[0].shadow, isNull);
      expect(
        result.project.elements[1].shadow!.shadowProfileId,
        'default-ground-wide-ellipse',
      );
      expect(
        result.project.elements[1].shadow!.family,
        StaticShadowFamily.building,
      );
      expect(
        result.project.elements[1].shadow!.footprint!.footprintWidthRatio,
        0.60,
      );
    });

    test('clears unsafe generic pre-footprint active shadows', () {
      final project = _project(
        elements: [
          _element(
            id: 'stand',
            name: 'Stand',
            width: 4,
            height: 2,
            shadow: ProjectElementShadowConfig(
              castsShadow: true,
              shadowProfileId: 'default-ground-soft-ellipse',
            ),
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 0);
      expect(result.clearedCount, 1);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
      );
      expect(result.project.elements.single.shadow, isNull);
    });

    test('preserves disabled shadows', () {
      final disabled = ProjectElementShadowConfig(castsShadow: false);
      final project = _project(
        elements: [
          _element(
            id: 'disabled',
            name: 'Disabled',
            width: 1,
            height: 4,
            shadow: disabled,
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 0);
      expect(result.hasChanges, isFalse);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.skippedDisabled,
      );
      expect(result.project.elements.single.shadow, disabled);
    });

    test('preserves manual footprints and numeric overrides', () {
      final manualFootprint = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'default-ground-contact-blob',
        footprint: StaticShadowFootprintConfig(footprintWidthRatio: 0.31),
      );
      final manualNumbers = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'default-ground-wide-ellipse',
        offsetX: 4,
        scaleY: 0.6,
        opacity: 0.18,
      );
      final project = _project(
        elements: [
          _element(
            id: 'manual-footprint',
            name: 'Manual footprint',
            width: 1,
            height: 4,
            shadow: manualFootprint,
          ),
          _element(
            id: 'manual-numbers',
            name: 'Manual numbers',
            width: 4,
            height: 3,
            shadow: manualNumbers,
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 0);
      expect(result.skippedCount, 2);
      expect(
        result.entries.map((entry) => entry.status),
        everyElement(ElementAutoShadowBackfillStatus.skippedManual),
      );
      expect(result.project.elements[0].shadow, manualFootprint);
      expect(result.project.elements[1].shadow, manualNumbers);
    });

    test(
        'clears recognized auto small square shadow when policy has no suggestion',
        () {
      final project = _project(
        elements: [
          _element(
            id: 'small-square',
            name: 'Small square',
            width: 2,
            height: 2,
            shadow: _oldAutoSmallSquareShadow(),
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 0);
      expect(result.changedCount, 1);
      expect(result.hasChanges, isTrue);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
      );
      expect(result.project.elements.single.shadow, isNull);
    });

    test('clears genericProjection auto shadow when policy has no suggestion',
        () {
      final project = _project(
        elements: [
          _element(
            id: 'default-prop',
            name: 'Default prop',
            width: 2,
            height: 3,
            shadow: _oldAutoDefaultPropShadow(),
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 0);
      expect(result.changedCount, 1);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
      );
      expect(result.project.elements.single.shadow, isNull);
    });

    test('clears recognized auto wide low shadow below safe threshold', () {
      final project = _project(
        elements: [
          _element(
            id: 'small-stand',
            name: 'Small stand',
            width: 3,
            height: 2,
            shadow: _oldAutoWideLowShadow(),
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 0);
      expect(result.changedCount, 1);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
      );
      expect(result.project.elements.single.shadow, isNull);
    });

    test('preserves manual footprint even if no suggestion exists', () {
      final manual = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'default-ground-soft-ellipse',
        footprint: StaticShadowFootprintConfig(footprintWidthRatio: 0.33),
      );
      final project = _project(
        elements: [
          _element(
            id: 'manual-small',
            name: 'Manual small',
            width: 2,
            height: 2,
            shadow: manual,
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 0);
      expect(result.changedCount, 0);
      expect(result.hasChanges, isFalse);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.skippedManual,
      );
      expect(result.project.elements.single.shadow, manual);
    });

    test('preserves non-default existing profile ids present in catalog', () {
      final customShadow = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'custom-ground-shadow',
      );
      final project = _project(
        elements: [
          _element(
            id: 'custom-profile',
            name: 'Custom profile',
            width: 4,
            height: 3,
            shadow: customShadow,
          ),
        ],
        shadowCatalog: ProjectShadowCatalog(
          profiles: [
            ...createDefaultGroundStaticShadowProfiles(),
            ProjectShadowProfile(
              id: 'custom-ground-shadow',
              name: 'Custom ground shadow',
              mode: ShadowCasterMode.ellipse,
              renderPass: ShadowRenderPass.groundStatic,
            ),
          ],
        ),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 0);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.skippedManual,
      );
      expect(result.project.elements.single.shadow, customShadow);
    });

    test('clears unsafe generic shadows with missing profile ids', () {
      final project = _project(
        elements: [
          _element(
            id: 'missing-profile',
            name: 'Missing profile',
            width: 1,
            height: 4,
            shadow: ProjectElementShadowConfig(
              castsShadow: true,
              shadowProfileId: 'missing-profile-id',
            ),
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 0);
      expect(result.clearedCount, 1);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
      );
      expect(result.project.elements.single.shadow, isNull);
    });

    test('adds default profiles when the catalog has no compatible profile',
        () {
      final project = _project(
        elements: [
          _element(id: 'house', name: 'House', width: 4, height: 3),
        ],
        shadowCatalog: const ProjectShadowCatalog.empty(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.addedDefaultProfiles, isTrue);
      expect(result.appliedCount, 1);
      expect(result.hasChanges, isTrue);
      expect(
          result.project.shadowCatalog.profiles.map((profile) => profile.id), [
        'default-ground-soft-ellipse',
        'default-ground-wide-ellipse',
        'default-ground-contact-blob',
      ]);
      expect(
        result.project.elements.single.shadow!.shadowProfileId,
        'default-ground-wide-ellipse',
      );
    });

    test('records skippedNoSuggestion for invalid element frames', () {
      final project = _project(
        elements: [
          _elementWithFrames(
            id: 'invalid',
            name: 'Invalid',
            frames: const [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 0, height: 2),
              ),
            ],
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.appliedCount, 0);
      expect(result.skippedCount, 1);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.skippedNoSuggestion,
      );
      expect(result.project.elements.single.shadow, isNull);
    });

    test('preserves element order and non-shadow fields', () {
      final project = _project(
        elements: [
          _element(
            id: 'first',
            name: 'First',
            width: 1,
            height: 4,
            presetKind: ElementPresetKind.tree,
            tags: const ['nature', 'tall'],
            sortOrder: 7,
          ),
          _element(
            id: 'second',
            name: 'Second',
            width: 4,
            height: 3,
            recommendedLayerId: 'decor_layer',
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = applyElementAutoShadowSuggestionsToProject(project);

      expect(result.project.elements.map((element) => element.id), [
        'first',
        'second',
      ]);
      expect(result.project.elements[0].presetKind, ElementPresetKind.tree);
      expect(result.project.elements[0].tags, ['nature', 'tall']);
      expect(result.project.elements[0].sortOrder, 7);
      expect(result.project.elements[1].recommendedLayerId, 'decor_layer');
      expect(result.project.elements[0].shadow, isNull);
      expect(result.project.elements[1].shadow, isNotNull);
    });

    test('editor wrapper stays in parity with core backfill operation', () {
      final project = _project(
        elements: [
          _element(id: 'lamp', name: 'Lamp', width: 1, height: 4),
          _element(
            id: 'house',
            name: 'House',
            width: 4,
            height: 3,
            shadow: ProjectElementShadowConfig(
              castsShadow: true,
              shadowProfileId: 'default-ground-wide-ellipse',
            ),
          ),
          _element(id: 'small', name: 'Small', width: 2, height: 2),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final editorResult = applyElementAutoShadowSuggestionsToProject(project);
      final coreResult = applyElementAutoShadowPolicyToProject(project);

      expect(editorResult.project, coreResult.project);
      expect(editorResult.entries, coreResult.entries);
      expect(
          editorResult.addedDefaultProfiles, coreResult.addedDefaultProfiles);
    });
  });
}

ProjectManifest _project({
  required List<ProjectElementEntry> elements,
  required ProjectShadowCatalog shadowCatalog,
}) {
  return ProjectManifest(
    name: 'Backfill test',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'tileset_main',
        name: 'Main tileset',
        relativePath: 'tilesets/main.png',
      ),
    ],
    elementCategories: const <ProjectElementCategory>[
      ProjectElementCategory(id: 'decor', name: 'Decor'),
    ],
    elements: elements,
    shadowCatalog: shadowCatalog,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

ProjectShadowCatalog _defaultCatalog() {
  return ProjectShadowCatalog(
    profiles: createDefaultGroundStaticShadowProfiles(),
  );
}

ProjectElementShadowConfig _oldAutoSmallSquareShadow() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-contact-blob',
    offsetX: 0,
    offsetY: 0,
    scaleX: 0.78,
    scaleY: 0.70,
    opacity: 0.26,
    family: StaticShadowFamily.compactProp,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.96,
      footprintWidthRatio: 0.46,
      footprintHeightRatio: 0.10,
    ),
  );
}

ProjectElementShadowConfig _oldAutoDefaultPropShadow() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-soft-ellipse',
    offsetX: 0,
    offsetY: 0,
    scaleX: 0.90,
    scaleY: 0.80,
    opacity: 0.28,
    family: StaticShadowFamily.genericProjection,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.95,
      footprintWidthRatio: 0.62,
      footprintHeightRatio: 0.12,
    ),
  );
}

ProjectElementShadowConfig _oldAutoWideLowShadow() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-wide-ellipse',
    offsetX: 0,
    offsetY: 0,
    scaleX: 0.92,
    scaleY: 0.75,
    opacity: 0.27,
    family: StaticShadowFamily.compactProp,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.95,
      footprintWidthRatio: 0.72,
      footprintHeightRatio: 0.10,
    ),
  );
}

ProjectElementEntry _element({
  required String id,
  required String name,
  required int width,
  required int height,
  ProjectElementShadowConfig? shadow,
  ElementPresetKind presetKind = ElementPresetKind.generic,
  List<String> tags = const [],
  int sortOrder = 0,
  String? recommendedLayerId,
}) {
  return _elementWithFrames(
    id: id,
    name: name,
    frames: [
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0, width: width, height: height),
      ),
    ],
    shadow: shadow,
    presetKind: presetKind,
    tags: tags,
    sortOrder: sortOrder,
    recommendedLayerId: recommendedLayerId,
  );
}

ProjectElementEntry _elementWithFrames({
  required String id,
  required String name,
  required List<TilesetVisualFrame> frames,
  ProjectElementShadowConfig? shadow,
  ElementPresetKind presetKind = ElementPresetKind.generic,
  List<String> tags = const [],
  int sortOrder = 0,
  String? recommendedLayerId,
}) {
  return ProjectElementEntry(
    id: id,
    name: name,
    tilesetId: 'tileset_main',
    categoryId: 'decor',
    frames: frames,
    presetKind: presetKind,
    shadow: shadow,
    tags: tags,
    sortOrder: sortOrder,
    recommendedLayerId: recommendedLayerId,
  );
}

```

## 24. Contenu complet du rapport créé

```text
Le rapport créé est ce fichier. Pour éviter une auto-copie récursive infinie, son contenu complet est le présent contenu du fichier.
```
