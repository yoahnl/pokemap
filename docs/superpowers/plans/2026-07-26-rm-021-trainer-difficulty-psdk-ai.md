# RM-021 Trainer Difficulty to PSDK AI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Faire produire à `battleDifficulty` des différences déterministes de niveau IA, de switch et d'usage d'objets dans le chemin PSDK réellement utilisé par le runtime.

**Architecture:** `map_battle` possède une policy pure qui transforme la difficulté produit en configuration `PsdkBattleAi`. `map_runtime` relit le trainer du manifeste, construit cette IA et l'injecte dans la session PSDK. L'Editor décrit les trois profils au niveau du curseur sans dépendre du moteur battle.

**Tech Stack:** Dart 3, Flutter/Flame runtime existant, `package:test`, `flutter_test`.

---

### Task 1: Policy IA PSDK pure

**Files:**
- Create: `packages/map_battle/lib/src/domain/ai/psdk_battle_ai_policy.dart`
- Modify: `packages/map_battle/lib/map_battle.dart`
- Test: `packages/map_battle/test/psdk_ai_difficulty_policy_test.dart`

- [ ] **Step 1: Write the failing policy tests**

Vérifier :

```dart
final basic = psdkBattleAiPolicyForDifficulty(2);
expect(basic.aiLevel, 1);
expect(basic.switchPolicy, PsdkBattleAiSwitchPolicy.never);
expect(basic.itemPolicy, PsdkBattleAiItemPolicy.disabled);

final advanced = psdkBattleAiPolicyForDifficulty(9);
expect(advanced.aiLevel, 3);
expect(advanced.switchPolicy, PsdkBattleAiSwitchPolicy.tactical);
expect(advanced.itemPolicy, PsdkBattleAiItemPolicy.authoredOptionsOnly);
```

Cas négatif :

```dart
expect(
  psdkBattleAiPolicyForDifficulty(-1).productDifficulty,
  1,
);
expect(
  psdkBattleAiPolicyForDifficulty(99).productDifficulty,
  10,
);
```

Policy objet :

```dart
expect(advanced.createAi().canUseItem, isFalse);
expect(
  advanced.createAi(
    itemOptions: const <PsdkBattleAiItemOption>[
      PsdkBattleAiItemOption.hpHeal(itemId: 'potion', amount: 20),
    ],
  ).canUseItem,
  isTrue,
);
```

- [ ] **Step 2: Run RED**

```bash
cd packages/map_battle
dart test test/psdk_ai_difficulty_policy_test.dart
```

Expected: types and resolver undefined.

- [ ] **Step 3: Implement minimal policy**

Créer :

```dart
enum PsdkBattleAiSwitchPolicy { never, tactical }
enum PsdkBattleAiItemPolicy { disabled, authoredOptionsOnly }

final class PsdkBattleAiPolicy {
  const PsdkBattleAiPolicy({
    required this.profileId,
    required this.productDifficulty,
    required this.aiLevel,
    required this.switchPolicy,
    required this.itemPolicy,
  });

  PsdkBattleAi createAi({
    List<PsdkBattleAiItemOption> itemOptions = const [],
  });
}

PsdkBattleAiPolicy psdkBattleAiPolicyForDifficulty(int? difficulty);
```

Mapping :

```text
null / 1..3 -> basic, level 1, switch never, items disabled
4..7        -> tactical, level 2, switch tactical, authored items only
8..10       -> advanced, level 3, switch tactical, authored items only
```

Un trainer ne peut jamais fuir. Une policy `authoredOptionsOnly` avec liste
vide garde `canUseItem == false`.

- [ ] **Step 4: Run GREEN**

```bash
dart test \
  test/psdk_ai_difficulty_policy_test.dart \
  test/psdk_ai_action_selection_test.dart \
  test/psdk_ai_move_scoring_test.dart
dart analyze
```

### Task 2: Injection dans le vrai runtime PSDK

**Files:**
- Modify: `packages/map_runtime/lib/src/presentation/flame/runtime_trainer_battle_overrides.dart`
- Modify: `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- Modify: `packages/map_runtime/lib/src/application/runtime_psdk_battle_session_adapter.dart`
- Create: `packages/map_runtime/test/runtime_trainer_psdk_ai_policy_test.dart`
- Modify: `packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart`

- [ ] **Step 1: Write failing runtime tests**

Construire deux trainers `difficulty: 2` et `difficulty: 9`, puis :

```dart
final basic = resolveRuntimeTrainerPsdkAi(...);
final advanced = resolveRuntimeTrainerPsdkAi(...);
expect(basic.level, 1);
expect(basic.canSwitch, isFalse);
expect(advanced.level, 3);
expect(advanced.canSwitch, isTrue);
expect(advanced.canUseItem, isFalse);
expect(advanced.canFlee, isFalse);
```

Le smoke Golden difficulté 4 doit vérifier :

```dart
final ai = resolveRuntimeTrainerPsdkAi(...);
expect(ai.level, 2);
expect(ai.canSwitch, isTrue);
```

- [ ] **Step 2: Run RED**

```bash
cd packages/map_runtime
flutter test \
  test/runtime_trainer_psdk_ai_policy_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart
```

- [ ] **Step 3: Implement and wire**

Ajouter :

```dart
PsdkBattleAi resolveRuntimeTrainerPsdkAi({
  required BattleStartRequest request,
  required ProjectManifest manifest,
  List<PsdkBattleAiItemOption> itemOptions = const [],
});
```

Dans `PlayableMapGame`, remplacer :

```dart
RuntimePsdkBattleSessionAdapter.fromSetup(psdkSetup!)
```

par :

```dart
RuntimePsdkBattleSessionAdapter.fromSetup(
  psdkSetup!,
  opponentAi: resolveRuntimeTrainerPsdkAi(
    request: request,
    manifest: _bundle.manifest,
  ),
)
```

L'adapter conserve la configuration injectée dans un getter
`opponentAi` afin que la preuve runtime puisse l'observer sans inspecter le
facade interne.

- [ ] **Step 4: Run GREEN**

```bash
cd packages/map_runtime
flutter test \
  test/runtime_trainer_psdk_ai_policy_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart \
  test/runtime_psdk_battle_session_adapter_test.dart
flutter analyze
```

### Task 3: Vérité visible dans l'Editor

**Files:**
- Modify: `packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart`
- Modify: `packages/map_editor/test/trainer_library_panel_test.dart`

- [ ] **Step 1: Write failing widget assertions**

Pour une difficulté explicite 2, 6 et 9, vérifier respectivement :

```text
Profil basique · choix simples · aucun switch tactique · aucun objet
Profil tactique · analyse dégâts/types · switch tactique · objets indisponibles
Profil avancé · analyse statuts/utilité · switch tactique · objets indisponibles
```

La valeur `null` doit annoncer le profil basique par défaut.

- [ ] **Step 2: Run RED**

```bash
cd packages/map_editor
flutter test test/trainer_library_panel_test.dart
```

- [ ] **Step 3: Render the exact policy summary**

Ajouter une fonction locale pure qui mappe `null/1..3`, `4..7`, `8..10` vers
les trois textes ci-dessus et l'utiliser sous le slider.

- [ ] **Step 4: Run GREEN**

```bash
flutter test test/trainer_library_panel_test.dart
flutter analyze
```

### Task 4: Gate et commit RM-021

**Files:**
- Create: `reports/gameplay/fg_086_140_trainer_difficulty_psdk_ai_v0.md`

- [ ] **Step 1: Run package gates**

```bash
cd packages/map_battle && dart test && dart analyze
cd packages/map_runtime && \
  flutter test test/phase_a_golden_battle_slice_smoke_test.dart && \
  flutter test && flutter analyze
cd packages/map_editor && flutter test && flutter analyze
```

- [ ] **Step 2: Write the Evidence Pack**

Inclure audit initial, rouges, cinq passes séparées, fichiers/diffs, commandes,
résultats, build non applicable par package, risques et statuts
`RM-021 DONE proposé`, `FG-086/FG-140 PARTIAL`.

- [ ] **Step 3: Commit only RM-021**

```bash
git add -- <fichiers RM-021 explicites>
git commit -m "feat(battle): map trainer difficulty to psdk ai"
```

## Self-review

- `battleDifficulty` affecte le chemin PSDK réel, plus seulement le legacy.
- Les switches sont activés seulement pour les profils tactique/avancé.
- Aucun objet invisible n'est inventé : sans inventaire auteuré, l'IA ne peut
  pas utiliser d'objet.
- Les trainers ne fuient jamais.
- L'Editor décrit exactement les trois profils sans dépendre de `map_battle`.
