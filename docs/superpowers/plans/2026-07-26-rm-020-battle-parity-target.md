# RM-020 Battle Parity Target Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Définir une cible de règles combat versionnée et lisible par machine, puis relier les compteurs PSDK à cette cible sans les présenter comme une preuve de parité joueur bout-en-bout.

**Architecture:** Un contrat pur Dart dans `map_battle` décrit chaque axe de règles, sa cible, son état d'alignement actuel et la preuve attendue. L'audit PSDK embarque ce contrat dans ses sorties JSON/Markdown. Un document combat explique les décisions et distingue couverture moteur, bridge runtime et preuve joueur.

**Tech Stack:** Dart 3, `package:test`, modèles immuables manuels, JSON/Markdown d'audit.

---

### Task 1: Contrat versionné de cible de parité

**Files:**
- Create: `packages/map_battle/lib/src/data/battle_parity_target.dart`
- Modify: `packages/map_battle/lib/map_battle.dart`
- Test: `packages/map_battle/test/battle_parity_target_test.dart`

- [ ] **Step 1: Write the failing contract test**

Le test construit `BattleParityTarget.canonicalV1`, vérifie :

```dart
expect(target.version, 1);
expect(target.profileId, 'pokemap-mainline-hybrid-v1');
expect(target.axis(BattleParityAxis.damage).ruleId, 'mainline-gen9-damage');
expect(
  target.axis(BattleParityAxis.speedTies).alignment,
  BattleParityAlignment.gap,
);
expect(
  target.counterPolicy.provesPlayerParity,
  isFalse,
);
expect(target.toJson()['axes'], hasLength(6));
```

- [ ] **Step 2: Run test to verify RED**

Run:

```bash
cd packages/map_battle
dart test test/battle_parity_target_test.dart
```

Expected: compilation failure because `BattleParityTarget` does not exist.

- [ ] **Step 3: Implement the minimal immutable contract**

Créer :

```dart
enum BattleParityAxis {
  damage,
  speedTies,
  majorStatuses,
  criticalHits,
  experience,
  capture,
}

enum BattleParityAlignment { aligned, partial, gap, intentionalVariant }

final class BattleParityAxisTarget {
  const BattleParityAxisTarget({
    required this.axis,
    required this.ruleId,
    required this.summary,
    required this.alignment,
    required this.evidence,
  });

  final BattleParityAxis axis;
  final String ruleId;
  final String summary;
  final BattleParityAlignment alignment;
  final List<String> evidence;

  Map<String, Object?> toJson();
}

final class BattleParityCounterPolicy {
  const BattleParityCounterPolicy({
    required this.scope,
    required this.provesPlayerParity,
    required this.requiredCompanionProofs,
  });

  final String scope;
  final bool provesPlayerParity;
  final List<String> requiredCompanionProofs;

  Map<String, Object?> toJson();
}

final class BattleParityTarget {
  const BattleParityTarget({
    required this.version,
    required this.profileId,
    required this.axes,
    required this.counterPolicy,
  });

  static const canonicalV1 = BattleParityTarget(...);

  final int version;
  final String profileId;
  final List<BattleParityAxisTarget> axes;
  final BattleParityCounterPolicy counterPolicy;

  BattleParityAxisTarget axis(BattleParityAxis axis);
  Map<String, Object?> toJson();
}
```

Cible V1 :

```text
damage         mainline-gen9-damage         partial
speedTies      mainline-gen9-seeded-random  gap
majorStatuses  mainline-gen9-status-core    partial
criticalHits   mainline-gen9-critical       aligned
experience     pokemap-simple-exp-v1        intentionalVariant
capture        pokemap-capture-mvp-v1       intentionalVariant
```

La policy de compteurs doit exiger trois preuves compagnes :
`runtimeBridge`, `playerSurface`, `goldenE2E`.

- [ ] **Step 4: Export and verify GREEN**

Ajouter au barrel :

```dart
export 'src/data/battle_parity_target.dart';
```

Run:

```bash
cd packages/map_battle
dart test test/battle_parity_target_test.dart
dart analyze
```

Expected: tests et analyse passent.

### Task 2: Relier la cible à l'audit PSDK

**Files:**
- Modify: `packages/map_battle/lib/src/data/psdk_fight_parity_audit.dart`
- Modify: `packages/map_battle/test/tool/psdk_fight_parity_audit_test.dart`

- [ ] **Step 1: Write the failing audit test**

Étendre le test existant :

```dart
final json = audit.toJson();
expect(
  (json['parityTarget'] as Map<String, Object?>)['profileId'],
  'pokemap-mainline-hybrid-v1',
);
expect(
  audit.toMarkdown(),
  contains('PSDK counters do not prove player parity'),
);
```

- [ ] **Step 2: Run test to verify RED**

Run:

```bash
cd packages/map_battle
dart test test/tool/psdk_fight_parity_audit_test.dart
```

Expected: `parityTarget` absent et texte Markdown absent.

- [ ] **Step 3: Add target output**

Ajouter à `PsdkFightParityAudit` :

```dart
this.parityTarget = BattleParityTarget.canonicalV1,
```

Puis :

```dart
'parityTarget': parityTarget.toJson(),
```

Le Markdown doit afficher le profil, les six axes, leur alignement et :

```text
PSDK counters do not prove player parity; runtime bridge, player surface and golden E2E evidence remain mandatory.
```

- [ ] **Step 4: Run targeted regression**

Run:

```bash
cd packages/map_battle
dart test \
  test/battle_parity_target_test.dart \
  test/tool/psdk_fight_parity_audit_test.dart \
  test/psdk_final_parity_gate_test.dart
dart analyze
```

Expected: tests et analyse passent.

### Task 3: Documenter, valider et committer RM-020

**Files:**
- Create: `docs/combat/battle-parity-target-v1.md`
- Create: `reports/gameplay/fg_053_battle_parity_target_v1.md`

- [ ] **Step 1: Write the decision document**

Le document doit contenir :

```text
- cible moderne Gen 9 pour dégâts, égalités de vitesse, statuts et critiques ;
- variantes PokeMap V1 explicites pour EXP et capture ;
- inventaire current/aligned/partial/gap ;
- les compteurs PSDK mesurent la convergence moteur uniquement ;
- les preuves bridge, surface joueur et Golden E2E restent obligatoires.
```

- [ ] **Step 2: Run the full package gate**

Run:

```bash
cd packages/map_battle
dart test
dart analyze
```

Expected: exit `0` pour les deux commandes.

- [ ] **Step 3: Write the Evidence Pack**

Le rapport `FG-053` doit inclure l'état Git initial, le rouge TDD, les fichiers,
les diffs précis, les commandes/résultats exacts, l'auto-critique et le verdict
`RM-020 DONE proposé`, tandis que `FG-053` global reste `PARTIAL`.

- [ ] **Step 4: Commit only RM-020 files**

```bash
git add -- \
  docs/superpowers/plans/2026-07-26-rm-020-battle-parity-target.md \
  docs/combat/battle-parity-target-v1.md \
  packages/map_battle/lib/map_battle.dart \
  packages/map_battle/lib/src/data/battle_parity_target.dart \
  packages/map_battle/lib/src/data/psdk_fight_parity_audit.dart \
  packages/map_battle/test/battle_parity_target_test.dart \
  packages/map_battle/test/tool/psdk_fight_parity_audit_test.dart \
  reports/gameplay/fg_053_battle_parity_target_v1.md
git commit -m "feat(battle): define parity target v1"
```

Expected: un commit contenant uniquement le lot RM-020.

## Self-review

- Couverture spec : les six axes demandés et la sémantique des compteurs PSDK
  sont couverts.
- Aucun placeholder : les types, valeurs, tests et commandes sont nommés.
- Cohérence des types : `BattleParityTarget.canonicalV1` est utilisé dans le
  test de contrat et comme valeur par défaut de l'audit.
- Non-objectifs respectés : ce lot ne corrige pas encore les gaps de vitesse,
  statut ou décision ; il rend leur vérité exécutable et auditable.
