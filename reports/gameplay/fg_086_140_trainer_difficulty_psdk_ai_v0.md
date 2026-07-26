# RM-021 — Trainer Difficulty to PSDK AI V0 — Evidence Pack

Date : 2026-07-26
Lots concernés : `RM-021`, `FG-086`, `FG-140`
Branche : `main`
Verdict proposé : `RM-021 DONE`, `FG-086 PARTIAL`, `FG-140 PARTIAL`

## 1. Résultat

`ProjectTrainerEntry.battleDifficulty` pilote désormais le chemin de combat
PSDK réellement utilisé par le runtime. Les difficultés `1..3`, `4..7` et
`8..10` sélectionnent respectivement les profils `basic`, `tactical` et
`advanced`, avec des niveaux IA, comportements de switch et droits d'objets
explicitement définis.

Le lot ne fabrique aucun inventaire caché : les profils tactique et avancé ne
peuvent utiliser un objet que si le runtime leur fournit des options auteurées.
Comme l'Editor ne possède pas encore ce contrôle, son texte annonce
honnêtement « objets indisponibles ».

## 2. Audit initial

### Constat

- `ProjectTrainerEntry.battleDifficulty` existait déjà avec une plage validée
  `1..10`.
- L'Editor proposait déjà un curseur de difficulté, sans expliquer son effet
  moteur.
- Le chemin legacy appliquait `resolveRuntimeTrainerOpponentPolicy`.
- Le chemin PSDK normal construisait toujours
  `RuntimePsdkBattleSessionAdapter.fromSetup(psdkSetup!)`, donc conservait le
  `PsdkBattleAi(level: 2)` par défaut et ignorait la difficulté auteurée.
- `PsdkBattleAi` supportait déjà le niveau, le switch, les objets et la fuite.
- Aucun inventaire d'objets de combat n'est actuellement auteuré sur un
  trainer.

### Risque confirmé

Le curseur donnait une impression de contrôle sans effet sur le moteur de
combat principal. Un trainer difficulté 2 et un trainer difficulté 9 recevaient
la même IA PSDK.

## 3. Décision d'architecture

La policy pure appartient à `map_battle`; la résolution du trainer et
l'injection appartiennent à `map_runtime`; l'explication no-code appartient à
`map_editor`.

| Difficulté | Profil | Niveau PSDK | Switch | Objets | Fuite |
|---|---|---:|---|---|---|
| `null`, `1..3` | `basic` | 1 | jamais | désactivés | jamais |
| `4..7` | `tactical` | 2 | tactique | options auteurées uniquement | jamais |
| `8..10` | `advanced` | 3 | tactique | options auteurées uniquement | jamais |

Les valeurs externes à `1..10` sont bornées défensivement. Les combats
sauvages conservent le comportement historique neutre de niveau 2.

## 4. Passes de travail

Le mode multi-agent était indisponible pour ce lot sans demande explicite de
l'utilisateur. Les verdicts requis ont donc été produits par cinq passes
séparées du même agent.

### Passe Audit / Architecture

Verdict : **GO**, à condition de ne pas inventer d'inventaire trainer et de
prouver l'injection sur le vrai chemin PSDK.

### Passe Implémentation

Verdict : **CONFORME**.

- policy pure exportée par `map_battle`;
- resolver runtime séparé du widget Flame;
- adapter observable sans exposer le facade interne;
- texte Editor aligné sur les capacités réellement disponibles.

### Passe Tests

Verdict : **VERT**.

- TDD RED sur la policy pure;
- TDD RED sur le resolver runtime;
- TDD RED sur la vérité visible dans l'Editor;
- tests ciblés puis suites complètes des trois packages.

### Passe Build / Validation

Verdict : **VERT**.

- analyses statiques propres;
- smoke Golden inclus;
- application macOS Editor construite en debug.

### Passe Critique finale

Verdict : **ACCEPTABLE POUR RM-021**.

Le mapping est volontairement limité à trois profils stables. Les objets
trainer restent désactivés dans le produit tant que `RM-023`, `RM-024` et le
futur authoring d'inventaire ne fournissent pas un contrat explicite. La
parité battle complète reste donc partielle.

## 5. TDD et commandes exactes

### RED — policy pure

```text
Error: Method not found: 'psdkBattleAiPolicyForDifficulty'.
Undefined name 'PsdkBattleAiSwitchPolicy'.
Undefined name 'PsdkBattleAiItemPolicy'.
+0 -1: Some tests failed.
```
Une première exécution RED contenait aussi une erreur de fixture
`currentHp` manquant; la fixture a été corrigée avant de retenir la preuve RED
fonctionnelle ci-dessus.

### GREEN — `map_battle` ciblé

```bash
cd packages/map_battle
dart test test/psdk_ai_difficulty_policy_test.dart test/psdk_ai_action_selection_test.dart test/psdk_ai_move_scoring_test.dart -r failures-only
dart analyze
```

```text
+13: All tests passed!
No issues found!
```

### RED — runtime PSDK

```text
Method not found: 'resolveRuntimeTrainerPsdkAi'
+0 -2: Some tests failed.
```

### GREEN — `map_runtime` ciblé

```bash
cd packages/map_runtime
flutter test test/runtime_trainer_psdk_ai_policy_test.dart test/phase_a_golden_battle_slice_smoke_test.dart test/runtime_psdk_battle_session_adapter_test.dart -r failures-only
flutter analyze
```

```text
+15: All tests passed!
No issues found! (ran in 5.1s)
```

### RED — Editor

```text
Expected exactly one "Profil tactique..."
Found 0
+3 -1 ... [E]
+12 -1: Some tests failed.
```

### GREEN — Editor ciblé

```bash
cd packages/map_editor
flutter test test/trainer_library_panel_test.dart -r failures-only
flutter analyze
```

```text
+13: All tests passed!
No issues found! (ran in 5.7s)
```

### Suites complètes

```bash
cd packages/map_battle
dart test
dart analyze
```

```text
+1747: All tests passed!
Analyzing map_battle...
No issues found!
```

```bash
cd packages/map_runtime
flutter test
flutter analyze
```

```text
+2183 ~1: 1 skipped test.
+2183 ~1: All other tests passed!
Analyzing map_runtime...
No issues found! (ran in 4.7s)
```

```bash
cd packages/map_editor
flutter test --concurrency=1 -r failures-only
flutter analyze
```

```text
+4151: All tests passed!
Analyzing map_editor...
No issues found! (ran in 6.2s)
```

### Build

```bash
cd packages/map_editor
flutter build macos --debug
```

```text
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## 6. Fichiers modifiés

| Fichier | Nature de la modification |
|---|---|
| `docs/superpowers/plans/2026-07-26-rm-021-trainer-difficulty-psdk-ai.md` | plan détaillé du lot |
| `packages/map_battle/lib/map_battle.dart` | export public de la policy |
| `packages/map_battle/lib/src/domain/ai/psdk_battle_ai_policy.dart` | mapping pur difficulté → IA |
| `packages/map_battle/test/psdk_ai_difficulty_policy_test.dart` | preuve des profils et décisions |
| `packages/map_runtime/lib/src/application/runtime_psdk_battle_session_adapter.dart` | conservation observable de l'IA injectée |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | injection dans la session PSDK de production |
| `packages/map_runtime/lib/src/presentation/flame/runtime_trainer_battle_overrides.dart` | résolution trainer → IA PSDK |
| `packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart` | preuve Golden difficulté 4 |
| `packages/map_runtime/test/runtime_trainer_psdk_ai_policy_test.dart` | preuve runtime low/high/wild/items |
| `packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart` | résumé visible des profils |
| `packages/map_editor/test/trainer_library_panel_test.dart` | preuve widget des trois profils |
| `reports/gameplay/fg_086_140_trainer_difficulty_psdk_ai_v0.md` | présent Evidence Pack |

## 7. Zones précises modifiées

- `map_battle.dart` : ajout d'un export public.
- `psdk_battle_ai_policy.dart` : deux enums, un value object et un resolver.
- `runtime_trainer_battle_overrides.dart` : ajout de
  `resolveRuntimeTrainerPsdkAi`.
- `playable_map_game.dart` : résolution puis passage de `opponentAi` à
  `RuntimePsdkBattleSessionAdapter.fromSetup`.
- `runtime_psdk_battle_session_adapter.dart` : stockage public immuable de
  l'IA effectivement injectée.
- `trainer_library_panel_trainer_widgets.dart` : résumé sous le curseur.
- tests : assertions de mapping, switch, objets, fuite, conservation wild et
  affichage.

## 8. État Git initial et isolation

État initial pertinent :

```text
 M apps/pokemap_hub/lib/src/ui/hub_app.dart
 M apps/pokemap_hub/lib/src/ui/hub_shell.dart
 M apps/pokemap_hub/test/ui/hub_app_player_navigation_test.dart
 M apps/pokemap_hub/test/ui/hub_preferences_store_test.dart
 M apps/pokemap_hub/test/ui/hub_shell_test.dart
 M packages/map_player_ui/lib/src/localization/player_localizations.dart
 M packages/map_player_ui/lib/src/preferences/player_preferences.dart
```

Ces sept modifications préexistantes appartiennent à l'utilisateur. Elles ne
sont ni modifiées ni stageées par RM-021. Le commit du lot utilise une liste de
fichiers explicite.

## 9. Non-objectifs et limites

- pas d'authoring d'inventaire d'objets trainer;
- pas de nouvelle mécanique d'objet ou d'objet tenu;
- pas de modification de la formule de dégâts;
- pas de changement de l'IA des rencontres sauvages;
- pas de prétention de parité Pokémon/PSDK complète;
- pas de mise à jour du roadmap canonique sans demande explicite.

## 10. Auto-critique et risques

1. Le profil `advanced` améliore la surface de décision disponible, mais reste
   contraint par les heuristiques actuelles de `PsdkBattleAi`.
2. L'Editor décrit les objets comme indisponibles même si l'API pure accepte
   des options explicites; c'est volontairement conservateur jusqu'à un vrai
   authoring.
3. Le getter `opponentAi` de l'adapter est une surface publique ajoutée pour
   rendre la configuration runtime vérifiable; il faudra éviter qu'il devienne
   un second point de mutation.
4. Les profils sont des seuils produit, pas une échelle continue.
5. Les lots `RM-023`, `RM-024`, `RM-025`, `RM-027`, `RM-028`, `RM-029` et les
   capability gates restent nécessaires avant de proposer `FG-086` ou
   `FG-140` comme complets.

## 11. Proposition de statut

- `RM-021` : **DONE** — la difficulté auteurée atteint le chemin PSDK et
  produit des différences testées.
- `FG-086` : **PARTIAL** — ce lot ferme le wiring difficulté/IA, pas toute la
  fidélité des décisions battle.
- `FG-140` : **PARTIAL** — le trainer bénéficie de profils utiles, mais les
  rewards, objets, templates et lifecycle restent ouverts.

## 12. Contenu complet des fichiers créés

Les sections suivantes reproduisent les fichiers de production, test et plan
créés par le lot. Le présent rapport n'est pas reproduit récursivement.

### `docs/superpowers/plans/2026-07-26-rm-021-trainer-difficulty-psdk-ai.md`

```markdown
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
```

### `packages/map_battle/lib/src/domain/ai/psdk_battle_ai_policy.dart`

```dart
import 'psdk_battle_ai.dart';

/// Whether a trainer profile may consider a voluntary tactical switch.
enum PsdkBattleAiSwitchPolicy {
  never,
  tactical,
}

/// Whether a trainer profile may consume explicitly authored battle items.
enum PsdkBattleAiItemPolicy {
  disabled,
  authoredOptionsOnly,
}

/// Deterministic PSDK AI configuration selected from product difficulty.
///
/// This policy deliberately does not manufacture trainer items. Even a high
/// difficulty trainer receives item actions only when a caller provides an
/// explicit authored option list.
final class PsdkBattleAiPolicy {
  const PsdkBattleAiPolicy({
    required this.profileId,
    required this.productDifficulty,
    required this.aiLevel,
    required this.switchPolicy,
    required this.itemPolicy,
  });

  final String profileId;
  final int? productDifficulty;
  final int aiLevel;
  final PsdkBattleAiSwitchPolicy switchPolicy;
  final PsdkBattleAiItemPolicy itemPolicy;

  PsdkBattleAi createAi({
    List<PsdkBattleAiItemOption> itemOptions =
        const <PsdkBattleAiItemOption>[],
  }) {
    final authoredItemsEnabled =
        itemPolicy == PsdkBattleAiItemPolicy.authoredOptionsOnly &&
            itemOptions.isNotEmpty;
    return PsdkBattleAi(
      level: aiLevel,
      canSwitch: switchPolicy == PsdkBattleAiSwitchPolicy.tactical,
      canUseItem: authoredItemsEnabled,
      // A trainer battle never exposes flee as an opponent policy.
      canFlee: false,
      itemOptions: authoredItemsEnabled
          ? List<PsdkBattleAiItemOption>.unmodifiable(itemOptions)
          : const <PsdkBattleAiItemOption>[],
    );
  }
}

/// Maps the authored `1..10` value to three stable product profiles.
///
/// `null` preserves the historical basic trainer behavior. Values outside the
/// validated product range are clamped defensively because this pure engine
/// boundary may also be called by tests or imported legacy data.
PsdkBattleAiPolicy psdkBattleAiPolicyForDifficulty(int? difficulty) {
  final normalized = difficulty?.clamp(1, 10).toInt();
  if (normalized == null || normalized <= 3) {
    return PsdkBattleAiPolicy(
      profileId: 'basic',
      productDifficulty: normalized,
      aiLevel: 1,
      switchPolicy: PsdkBattleAiSwitchPolicy.never,
      itemPolicy: PsdkBattleAiItemPolicy.disabled,
    );
  }
  if (normalized <= 7) {
    return PsdkBattleAiPolicy(
      profileId: 'tactical',
      productDifficulty: normalized,
      aiLevel: 2,
      switchPolicy: PsdkBattleAiSwitchPolicy.tactical,
      itemPolicy: PsdkBattleAiItemPolicy.authoredOptionsOnly,
    );
  }
  return PsdkBattleAiPolicy(
    profileId: 'advanced',
    productDifficulty: normalized,
    aiLevel: 3,
    switchPolicy: PsdkBattleAiSwitchPolicy.tactical,
    itemPolicy: PsdkBattleAiItemPolicy.authoredOptionsOnly,
  );
}
```

### `packages/map_battle/test/psdk_ai_difficulty_policy_test.dart`

```dart
import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK trainer difficulty policy', () {
    test('maps product difficulty to three explicit deterministic profiles',
        () {
      final basic = psdkBattleAiPolicyForDifficulty(2);
      final tactical = psdkBattleAiPolicyForDifficulty(6);
      final advanced = psdkBattleAiPolicyForDifficulty(9);

      expect(basic.profileId, 'basic');
      expect(basic.aiLevel, 1);
      expect(basic.switchPolicy, PsdkBattleAiSwitchPolicy.never);
      expect(basic.itemPolicy, PsdkBattleAiItemPolicy.disabled);

      expect(tactical.profileId, 'tactical');
      expect(tactical.aiLevel, 2);
      expect(tactical.switchPolicy, PsdkBattleAiSwitchPolicy.tactical);
      expect(
        tactical.itemPolicy,
        PsdkBattleAiItemPolicy.authoredOptionsOnly,
      );

      expect(advanced.profileId, 'advanced');
      expect(advanced.aiLevel, 3);
      expect(advanced.switchPolicy, PsdkBattleAiSwitchPolicy.tactical);
      expect(
        advanced.itemPolicy,
        PsdkBattleAiItemPolicy.authoredOptionsOnly,
      );
    });

    test('keeps default and out-of-range inputs bounded', () {
      expect(psdkBattleAiPolicyForDifficulty(null).productDifficulty, isNull);
      expect(psdkBattleAiPolicyForDifficulty(null).profileId, 'basic');
      expect(psdkBattleAiPolicyForDifficulty(-1).productDifficulty, 1);
      expect(psdkBattleAiPolicyForDifficulty(99).productDifficulty, 10);
    });

    test('allows only explicitly provided trainer item options', () {
      final advanced = psdkBattleAiPolicyForDifficulty(9);

      expect(advanced.createAi().canUseItem, isFalse);
      expect(
        advanced
            .createAi(
              itemOptions: const <PsdkBattleAiItemOption>[
                PsdkBattleAiItemOption.hpHeal(
                  itemId: 'potion',
                  amount: 20,
                ),
              ],
            )
            .canUseItem,
        isTrue,
      );
      expect(
        psdkBattleAiPolicyForDifficulty(2)
            .createAi(
              itemOptions: const <PsdkBattleAiItemOption>[
                PsdkBattleAiItemOption.hpHeal(
                  itemId: 'potion',
                  amount: 20,
                ),
              ],
            )
            .canUseItem,
        isFalse,
      );
    });

    test('basic and advanced profiles produce distinct switch decisions', () {
      final state = _switchPressureState();
      final basic = psdkBattleAiPolicyForDifficulty(2).createAi();
      final advanced = psdkBattleAiPolicyForDifficulty(9).createAi();

      final basicDecision = basic.chooseDecision(
        state: state,
        user: psdkOpponentSlot,
        target: psdkPlayerSlot,
      );
      final advancedDecision = advanced.chooseDecision(
        state: state,
        user: psdkOpponentSlot,
        target: psdkPlayerSlot,
      );

      expect(basicDecision, isA<BattleFightDecision>());
      expect(advancedDecision, isA<BattleSwitchDecision>());
      expect((advancedDecision as BattleSwitchDecision).partyIndex, 1);
      expect(
        advanced.chooseDecision(
          state: state,
          user: psdkOpponentSlot,
          target: psdkPlayerSlot,
        ),
        isA<BattleSwitchDecision>().having(
          (decision) => decision.partyIndex,
          'partyIndex',
          1,
        ),
      );
    });
  });
}

PsdkBattleState _switchPressureState() {
  final active = PsdkBattleCombatant.fromSetup(
    _combatant(
      id: 'opponent-active',
      type: 'normal',
      moves: <PsdkBattleMoveData>[
        _move(id: 'tackle', type: 'normal', power: 80),
      ],
    ),
  );
  final reserve = PsdkBattleCombatant.fromSetup(
    _combatant(
      id: 'opponent-reserve',
      type: 'ghost',
      moves: <PsdkBattleMoveData>[
        _move(id: 'shadow-claw', type: 'ghost', power: 70),
      ],
    ),
  );
  final player = PsdkBattleCombatant.fromSetup(
    _combatant(id: 'player', type: 'ghost'),
  );
  return PsdkBattleState(
    combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
      psdkOpponentSlot: active,
      psdkPlayerSlot: player,
    },
    parties: <int, List<PsdkBattleCombatant>>{
      psdkOpponentSlot.bank: <PsdkBattleCombatant>[active, reserve],
      psdkPlayerSlot.bank: <PsdkBattleCombatant>[player],
    },
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required String type,
  List<PsdkBattleMoveData>? moves,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 50,
    maxHp: 100,
    currentHp: 100,
    types: PsdkBattleTypes(primary: type),
    stats: const PsdkBattleStats(
      attack: 100,
      defense: 100,
      specialAttack: 100,
      specialDefense: 100,
      speed: 100,
    ),
    moves: moves ??
        <PsdkBattleMoveData>[
          _move(id: 'wait', type: 'normal', power: 0),
        ],
  );
}

PsdkBattleMoveData _move({
  required String id,
  required String type,
  required int power,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: power <= 0
        ? PsdkBattleMoveCategory.status
        : PsdkBattleMoveCategory.physical,
    power: power,
    accuracy: 100,
    pp: 15,
    priority: 0,
    battleEngineMethod: power <= 0 ? 's_status' : 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}
```

### `packages/map_runtime/test/runtime_trainer_psdk_ai_policy_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/presentation/flame/runtime_trainer_battle_overrides.dart';

void main() {
  group('runtime trainer PSDK AI policy', () {
    test('maps authored low and high difficulties to distinct PSDK policies',
        () {
      final manifest = _manifest(
        trainers: const <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'basic',
            name: 'Basic',
            trainerClass: 'Rookie',
            battleDifficulty: 2,
          ),
          ProjectTrainerEntry(
            id: 'advanced',
            name: 'Advanced',
            trainerClass: 'Ace',
            battleDifficulty: 9,
          ),
        ],
      );

      final basic = resolveRuntimeTrainerPsdkAi(
        request: _trainerRequest('basic'),
        manifest: manifest,
      );
      final advanced = resolveRuntimeTrainerPsdkAi(
        request: _trainerRequest('advanced'),
        manifest: manifest,
      );

      expect(basic.level, 1);
      expect(basic.canSwitch, isFalse);
      expect(basic.canUseItem, isFalse);
      expect(basic.canFlee, isFalse);

      expect(advanced.level, 3);
      expect(advanced.canSwitch, isTrue);
      expect(advanced.canUseItem, isFalse);
      expect(advanced.canFlee, isFalse);
    });

    test('enables advanced items only when authored options are provided', () {
      final ai = resolveRuntimeTrainerPsdkAi(
        request: _trainerRequest('advanced'),
        manifest: _manifest(
          trainers: const <ProjectTrainerEntry>[
            ProjectTrainerEntry(
              id: 'advanced',
              name: 'Advanced',
              trainerClass: 'Ace',
              battleDifficulty: 10,
            ),
          ],
        ),
        itemOptions: const <PsdkBattleAiItemOption>[
          PsdkBattleAiItemOption.hpHeal(
            itemId: 'potion',
            amount: 20,
          ),
        ],
      );

      expect(ai.canUseItem, isTrue);
      expect(ai.itemOptions.single.itemId, 'potion');
    });

    test('keeps wild PSDK battles on their historical neutral AI', () {
      final ai = resolveRuntimeTrainerPsdkAi(
        request: const WildBattleStartRequest(
          requestId: 'wild',
          createdAtEpochMs: 1,
          returnContext: OverworldReturnContext(
            mapId: 'field',
            playerPos: GridPos(x: 1, y: 1),
            playerFacing: Direction.south,
          ),
          mapId: 'field',
          zoneId: 'grass',
          tableId: 'grass-table',
          encounterKind: EncounterKind.walk,
          speciesId: 'sproutle',
          level: 5,
          minLevel: 5,
          maxLevel: 5,
          weight: 1,
          playerPos: GridPos(x: 1, y: 1),
        ),
        manifest: _manifest(),
      );

      expect(ai.level, 2);
      expect(ai.canSwitch, isFalse);
      expect(ai.canUseItem, isFalse);
      expect(ai.canFlee, isFalse);
    });
  });
}

ProjectManifest _manifest({
  List<ProjectTrainerEntry> trainers = const <ProjectTrainerEntry>[],
}) {
  return ProjectManifest(
    name: 'runtime-ai-policy',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    trainers: trainers,
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
}

TrainerBattleStartRequest _trainerRequest(String trainerId) {
  return TrainerBattleStartRequest(
    requestId: 'trainer-$trainerId',
    createdAtEpochMs: 1,
    returnContext: const OverworldReturnContext(
      mapId: 'field',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    trainerId: trainerId,
    npcEntityId: 'npc-$trainerId',
    mapId: 'field',
    playerPos: const GridPos(x: 1, y: 1),
  );
}
```
