# Evidence Pack — RM-020 Battle Parity Target V1

Date : 2026-07-26
Lot d'exécution : `RM-020 — Battle Parity Target`
Lot canonique lié : `FG-053 — Battle Engine Hardening / Parity`
Roadmap source :
`reports/gameplay/fg_000_remediation_and_personalization_roadmap.md`

## 1. Résumé exécutif et verdict

**`RM-020` : `DONE` proposé. `FG-053` global : reste `PARTIAL`.**

PokeMap possède maintenant une cible de règles combat V1 versionnée et lisible
par machine :

```text
pokemap-mainline-hybrid-v1
```

Elle fixe six axes :

- dégâts Gen 9 modernes : `partial` ;
- égalités de vitesse Gen 9 avec tirage seedé : `gap` ;
- statuts majeurs Gen 9 : `partial` ;
- critiques Gen 9 : `aligned` ;
- EXP simple PokeMap V1 : `intentionalVariant` ;
- capture MVP PokeMap V1 : `intentionalVariant`.

L'audit PSDK transporte désormais cette cible dans ses sorties JSON et
Markdown. Il déclare explicitement que ses compteurs mesurent la convergence du
moteur, pas la parité joueur. Toute promotion exige encore les preuves
`runtimeBridge`, `playerSurface` et `goldenE2E`.

## 2. Confirmation du scope

### Inclus

- contrat de cible immuable dans `map_battle` ;
- six décisions de règles et leur alignement actuel ;
- policy machine sur la sémantique des compteurs PSDK ;
- intégration JSON/Markdown dans l'audit existant ;
- documentation de décision ;
- tests positifs, négatifs et de non-régression ;
- plan d'implémentation RM-020.

### Explicitement hors scope

- correction de l'égalité de vitesse ;
- changement des formules EXP/capture ;
- unification des deux moteurs battle ;
- décisions joueur, items, rewards, held items ou Struggle ;
- promotion globale de `FG-053`.

## 3. Audit initial

### 3.1 Contrats et preuves trouvés

| Zone | Preuve existante | Verdict initial |
|---|---|---|
| dégâts | `battle_move_damage_calculator.dart` | formule moderne réelle, cible non déclarée |
| critiques | `battle_move_critical_resolver.dart` | chances 1/16, 1/8, 1/2, garanti et ×1,5 |
| vitesse | `battle_action_ordering.dart` | tie-break déterministe par banque, non mainline |
| statuts | moteur PSDK + tests lifecycle | support important mais parité globale non prouvée |
| EXP | `battle_progression_service.dart` | règle simple et multiplicateur trainer 1,5 |
| capture | `capture_formula.dart` | règle MVP explicitement non générationnelle |
| compteurs | `psdk_fight_parity_audit.dart` | attacks/methods/effects + bridge, sans profil de règles |
| docs | `battle-canonical-state-v3.1.md` | photographie ancienne et partiellement obsolète |

### 3.2 Risques identifiés

1. choisir « Gen 9 partout » aurait rendu mensongères les règles EXP/capture ;
2. marquer les compteurs PSDK comme parité complète aurait contredit le bridge
   et les surfaces joueur ;
3. corriger les gaps dans RM-020 aurait mélangé les scopes RM-021/RM-022 ;
4. les nouveaux documents sous `docs/` sont ignorés par `.gitignore` et doivent
   être ajoutés explicitement avec `git add -f`.

### 3.3 État Git initial

Les sept fichiers suivants étaient déjà modifiés et appartiennent à
l'utilisateur :

```text
 M apps/pokemap_hub/lib/src/ui/hub_app.dart
 M apps/pokemap_hub/lib/src/ui/hub_shell.dart
 M apps/pokemap_hub/test/ui/hub_app_player_navigation_test.dart
 M apps/pokemap_hub/test/ui/hub_preferences_store_test.dart
 M apps/pokemap_hub/test/ui/hub_shell_test.dart
 M packages/map_player_ui/lib/src/localization/player_localizations.dart
 M packages/map_player_ui/lib/src/preferences/player_preferences.dart
```

Ils restent hors du périmètre RM-020.

## 4. Passes séparées exigées par `codex_rule.md`

L'instruction de coordination active interdit le lancement de sub-agents sans
demande explicite. Les rôles obligatoires ont donc été exécutés comme cinq
passes séparées :

| Passe | Verdict |
|---|---|
| Audit / Architecture | PASS — cible hybride retenue pour ne pas mentir sur EXP/capture |
| Implémentation | PASS — contrat pur Dart et intégration audit uniquement |
| Tests | PASS — rouges observés, 12 ciblés verts, 1 743 complets verts |
| Build / Validation | PASS — analyse propre et outil d'audit compilé en AOT |
| Critique finale | PASS — aucun scope adjacent, aucun fichier utilisateur indexé |

## 5. Fichiers modifiés et zones précises

### 5.1 Fichiers créés

| Fichier | Responsabilité et impact |
|---|---|
| `docs/superpowers/plans/2026-07-26-rm-020-battle-parity-target.md` | plan TDD détaillé du lot |
| `docs/combat/battle-parity-target-v1.md` | décision humaine, axes, compteurs et consommateurs |
| `packages/map_battle/lib/src/data/battle_parity_target.dart` | enums, axes, policy compteurs et cible canonique V1 |
| `packages/map_battle/test/battle_parity_target_test.dart` | couverture positive, garde compteurs et lookup négatif |
| `reports/gameplay/fg_053_battle_parity_target_v1.md` | présent Evidence Pack |

Le contenu complet des quatre premiers fichiers figure en annexe A. Le présent
rapport constitue son propre contenu intégral.

### 5.2 Fichiers modifiés

#### `packages/map_battle/lib/map_battle.dart`

Zone :

```diff
+export 'src/data/battle_parity_target.dart';
```

Raison : rendre le contrat de cible disponible aux gates et consommateurs
externes sans importer une implémentation interne.

#### `packages/map_battle/lib/src/data/psdk_fight_parity_audit.dart`

Zones :

```diff
+import 'battle_parity_target.dart';
+this.parityTarget = BattleParityTarget.canonicalV1,
+final BattleParityTarget parityTarget;
+'parityTarget': parityTarget.toJson(),
```

Le renderer Markdown ajoute une table `Axis / Rule / Alignment` et
l'avertissement :

```text
PSDK counters do not prove player parity; runtime bridge, player surface and
golden E2E evidence remain mandatory.
```

Impact : chaque audit PSDK machine/humain transporte désormais la cible qui
donne un sens à ses compteurs.

#### `packages/map_battle/test/tool/psdk_fight_parity_audit_test.dart`

Zones :

- vérification de `parityTarget.profileId` ;
- vérification des six axes ;
- vérification `provesPlayerParity == false` ;
- non-régression du tableau Markdown et de l'avertissement.

## 6. Cycle TDD

### 6.1 Rouge contrat

```bash
cd packages/map_battle
dart test test/battle_parity_target_test.dart
```

Résultat attendu et observé :

```text
Error: Undefined name 'BattleParityTarget'.
Error: Undefined name 'BattleParityAxis'.
+0 -1: Some tests failed.
```

### 6.2 Vert contrat

```text
+3: All tests passed!
Analyzing map_battle...
No issues found!
```

### 6.3 Rouge audit

```bash
dart test test/tool/psdk_fight_parity_audit_test.dart -r failures-only
```

Résultat attendu et observé :

```text
+0 -1: PSDK fight parity audit counts attacks methods effects and renders machine output [E]
Null check operator used on a null value
test/tool/psdk_fight_parity_audit_test.dart 178:48
+4 -1: Some tests failed.
```

### 6.4 Vert ciblé

```bash
dart test \
  test/battle_parity_target_test.dart \
  test/tool/psdk_fight_parity_audit_test.dart \
  test/psdk_final_parity_gate_test.dart \
  -r failures-only
dart analyze
```

Résultat :

```text
+12: All tests passed!
Analyzing map_battle...
No issues found!
```

## 7. Gate complète et build

### 7.1 Tests complets

```bash
cd packages/map_battle
dart test -r failures-only
```

Résultat exact :

```text
+1743: All tests passed!
```

### 7.2 Analyse

```bash
dart analyze
```

Résultat exact :

```text
Analyzing map_battle...
No issues found!
```

### 7.3 Build

`map_battle` est un package Dart pur sans application autonome. La meilleure
validation de build applicable est la compilation AOT de son outil exécutable :

```bash
dart compile exe tool/psdk_fight_parity_audit.dart \
  -o /tmp/rm020_psdk_fight_parity_audit
```

Résultat exact :

```text
Generated: /tmp/rm020_psdk_fight_parity_audit
```

## 8. Critique finale

### Points vérifiés

- aucun changement dans Core, Runtime, Gameplay, Editor ou UI ;
- aucune formule métier modifiée ;
- aucun compteur existant supprimé ou renommé ;
- constructeur d'audit rétrocompatible grâce à la valeur canonique par défaut ;
- JSON additif ;
- Markdown additif ;
- lookup absent échoue explicitement au lieu d'inventer une cible ;
- six axes présents exactement une fois ;
- commentaires de frontière présents ;
- aucun fichier utilisateur ajouté à l'index.

### Risques restants

1. `damage` et `majorStatuses` restent `partial` : le profil ne les transforme
   pas en support complet.
2. `speedTies` reste `gap` jusqu'au lot de décision canonique.
3. La cible V1 est codée en constante ; une future V2 exigera une migration de
   gate, pas une mutation silencieuse.
4. Les chemins d'evidence sont des références auditables, pas encore des liens
   validés automatiquement.
5. Le document `battle-canonical-state-v3.1.md` reste historique ; il n'est pas
   réécrit dans ce lot chirurgical.

## 9. État Git avant commit

Seuls les fichiers listés en section 5 doivent être ajoutés. Les documents
ignorés sont ajoutés avec `git add -f -- <chemins explicites>`. Les sept
modifications utilisateur de la section 3.3 doivent rester hors index.

## 10. Prochaine étape proposée

`RM-021 — Trainer Difficulty to PSDK AI` :

- relier la difficulté auteurée à une policy IA déterministe ;
- expliciter les policies de switch et d'items ;
- prouver au moins deux niveaux de difficulté produisant des décisions
  distinctes.

Cette étape n'est pas implémentée dans RM-020.

## Annexe A — contenu intégral des fichiers créés


### A.1 `docs/superpowers/plans/2026-07-26-rm-020-battle-parity-target.md`

```markdown
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
```

### A.2 `docs/combat/battle-parity-target-v1.md`

```markdown
# Battle Parity Target V1

Date : 2026-07-26
Profil : `pokemap-mainline-hybrid-v1`
Contrat machine :
`packages/map_battle/lib/src/data/battle_parity_target.dart`

## Décision

PokeMap vise les règles modernes de la neuvième génération pour les mécaniques
résolues au sein du moteur de combat : dégâts, égalités de vitesse, statuts
majeurs et critiques.

L'expérience et la capture conservent deux règles PokeMap V1 documentées.
Elles ne sont pas présentées comme une parité exacte avec une génération
mainline :

- EXP sauvage : `level × baseExperience / 7` ;
- EXP trainer : même base avec multiplicateur `1,5` ;
- capture : formule entière HP/catch-rate/statut, une Poké Ball canonique et
  consommation RNG déterministe.

Cette cible hybride évite deux erreurs :

1. prétendre que toutes les mécaniques actuelles appartiennent à une génération
   unique alors que l'EXP et la capture sont volontairement bornées ;
2. laisser chaque bridge ou UI choisir implicitement sa propre interprétation.

## Axes

| Axe | Règle cible | État au 2026-07-26 | Écart restant |
|---|---|---|---|
| dégâts | `mainline-gen9-damage` | `partial` | consolider la preuve bridge/runtime et les deux moteurs historiques |
| égalités de vitesse | `mainline-gen9-seeded-random` | `gap` | remplacer l'ordre déterministe par banque par un tirage seedé |
| statuts majeurs | `mainline-gen9-status-core` | `partial` | fermer la matrice immunités/lifecycle exposée au joueur |
| critiques | `mainline-gen9-critical` | `aligned` | maintenir la preuve 1/16, 1/8, 1/2, garanti et multiplicateur 1,5 |
| expérience | `pokemap-simple-exp-v1` | `intentionalVariant` | aucune revendication Gen 9 ; garder la règle versionnée |
| capture | `pokemap-capture-mvp-v1` | `intentionalVariant` | familles de Balls différées ; garder la règle versionnée |

## Sémantique des compteurs PSDK

Les compteurs `attacks`, `methods` et `effects` mesurent la convergence du
moteur PSDK :

- présence d'une méthode connue ;
- niveau de portage de son comportement ;
- inventaire des effets et hooks couverts.

Ils ne prouvent pas à eux seuls :

- que le bridge runtime transporte toutes les données nécessaires ;
- que le joueur peut sélectionner et résoudre la capacité ;
- que le write-back gameplay est atomique ;
- que l'Editor expose un réglage réellement consommé ;
- qu'un parcours Golden E2E passe.

Toute promotion joueur exige donc trois preuves compagnes :

```text
runtimeBridge
playerSurface
goldenE2E
```

Le statut PSDK `partiel` signifie « exécutable mais non strictement paritaire ».
Il ne peut jamais être transformé silencieusement en support produit complet.

## Consommateurs

| Consommateur | Usage |
|---|---|
| `PsdkFightParityAudit.toJson()` | cible lisible par machine et future capability gate |
| `PsdkFightParityAudit.toMarkdown()` | cible et limitations visibles dans les rapports |
| `RM-021` | difficulté trainer et policies IA alignées |
| `RM-022` | décisions et égalités de vitesse canoniques |
| `RM-026` | gate MVP combinant moteur, bridge, surface et goldens |
| `RM-053` | gate complète incluant objets tenus, stats et Struggle |

## Non-objectifs V1

- déclarer tous les mouvements PSDK strictement paritaires ;
- changer la formule d'EXP ou de capture dans RM-020 ;
- corriger l'égalité de vitesse dans le lot de décision ;
- supprimer immédiatement le moteur legacy ;
- ouvrir doubles, targeting riche ou toutes les familles de Balls.
```

### A.3 `packages/map_battle/lib/src/data/battle_parity_target.dart`

```dart
/// Battle-rule axes that must have an explicit target before PokeMap can claim
/// trainer and player-facing parity.
enum BattleParityAxis {
  damage,
  speedTies,
  majorStatuses,
  criticalHits,
  experience,
  capture,
}

/// Current implementation alignment against one selected rule target.
enum BattleParityAlignment {
  aligned,
  partial,
  gap,
  intentionalVariant,
}

/// One auditable battle-rule decision.
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

  Map<String, Object?> toJson() => <String, Object?>{
        'axis': axis.name,
        'ruleId': ruleId,
        'summary': summary,
        'alignment': alignment.name,
        'evidence': evidence,
      };
}

/// Meaning and limitations of the PSDK coverage counters.
final class BattleParityCounterPolicy {
  const BattleParityCounterPolicy({
    required this.scope,
    required this.provesPlayerParity,
    required this.requiredCompanionProofs,
  });

  final String scope;
  final bool provesPlayerParity;
  final List<String> requiredCompanionProofs;

  Map<String, Object?> toJson() => <String, Object?>{
        'scope': scope,
        'provesPlayerParity': provesPlayerParity,
        'requiredCompanionProofs': requiredCompanionProofs,
      };
}

/// Versioned source of truth for PokeMap battle-rule targets.
final class BattleParityTarget {
  const BattleParityTarget({
    required this.version,
    required this.profileId,
    required this.axes,
    required this.counterPolicy,
  });

  /// PokeMap deliberately uses a hybrid target.
  ///
  /// Resolution rules follow modern mainline behavior where the engine owns
  /// the mechanic. Experience and capture retain their documented PokeMap V1
  /// formulas rather than falsely claiming generation-specific parity.
  static const canonicalV1 = BattleParityTarget(
    version: 1,
    profileId: 'pokemap-mainline-hybrid-v1',
    axes: <BattleParityAxisTarget>[
      BattleParityAxisTarget(
        axis: BattleParityAxis.damage,
        ruleId: 'mainline-gen9-damage',
        summary:
            'Modern level/power/stat damage pipeline with 85–100 roll, STAB, '
            'type effectiveness, burn, weather, terrain, items and abilities.',
        alignment: BattleParityAlignment.partial,
        evidence: <String>[
          'lib/src/domain/move/battle_move_damage_calculator.dart',
          'test/psdk_damage_formula_parity_test.dart',
        ],
      ),
      BattleParityAxisTarget(
        axis: BattleParityAxis.speedTies,
        ruleId: 'mainline-gen9-seeded-random',
        summary:
            'Equal-priority and equal-speed actions use a reproducible seeded '
            'random tie break.',
        alignment: BattleParityAlignment.gap,
        evidence: <String>[
          'lib/src/domain/action/battle_action_ordering.dart',
          'test/psdk_action_queue_test.dart',
        ],
      ),
      BattleParityAxisTarget(
        axis: BattleParityAxis.majorStatuses,
        ruleId: 'mainline-gen9-status-core',
        summary:
            'Major-status action gates, stat modifiers, residual damage, '
            'immunities and cure lifecycle follow modern mainline rules.',
        alignment: BattleParityAlignment.partial,
        evidence: <String>[
          'lib/src/domain/status',
          'test/psdk_status_lifecycle_test.dart',
        ],
      ),
      BattleParityAxisTarget(
        axis: BattleParityAxis.criticalHits,
        ruleId: 'mainline-gen9-critical',
        summary:
            'Critical stages use 1/16, 1/8, 1/2 and guaranteed chances with a '
            '1.5 damage multiplier.',
        alignment: BattleParityAlignment.aligned,
        evidence: <String>[
          'lib/src/domain/move/battle_move_critical_resolver.dart',
          'test/psdk_damage_formula_parity_test.dart',
        ],
      ),
      BattleParityAxisTarget(
        axis: BattleParityAxis.experience,
        ruleId: 'pokemap-simple-exp-v1',
        summary:
            'Wild EXP is level × baseExperience / 7; trainer EXP applies the '
            'documented 1.5 multiplier before deterministic party sharing.',
        alignment: BattleParityAlignment.intentionalVariant,
        evidence: <String>[
          '../map_gameplay/lib/src/battle_progression_service.dart',
          '../map_gameplay/test/battle_progression_service_test.dart',
        ],
      ),
      BattleParityAxisTarget(
        axis: BattleParityAxis.capture,
        ruleId: 'pokemap-capture-mvp-v1',
        summary:
            'Integer HP/catch-rate/status formula with one canonical Poké Ball '
            'and deterministic RNG consumption.',
        alignment: BattleParityAlignment.intentionalVariant,
        evidence: <String>[
          'lib/src/capture_formula.dart',
          'test/battle_capture_formula_test.dart',
        ],
      ),
    ],
    counterPolicy: BattleParityCounterPolicy(
      scope:
          'PSDK counters measure engine attack, method and effect convergence.',
      provesPlayerParity: false,
      requiredCompanionProofs: <String>[
        'runtimeBridge',
        'playerSurface',
        'goldenE2E',
      ],
    ),
  );

  final int version;
  final String profileId;
  final List<BattleParityAxisTarget> axes;
  final BattleParityCounterPolicy counterPolicy;

  BattleParityAxisTarget axis(BattleParityAxis axis) =>
      axes.singleWhere((target) => target.axis == axis);

  Map<String, Object?> toJson() => <String, Object?>{
        'version': version,
        'profileId': profileId,
        'axes': axes.map((axis) => axis.toJson()).toList(growable: false),
        'counterPolicy': counterPolicy.toJson(),
      };
}
```

### A.4 `packages/map_battle/test/battle_parity_target_test.dart`

```dart
import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('BattleParityTarget canonical V1', () {
    test('pins every authored battle-rules axis to an explicit target', () {
      const target = BattleParityTarget.canonicalV1;

      expect(target.version, 1);
      expect(target.profileId, 'pokemap-mainline-hybrid-v1');
      expect(target.axes, hasLength(BattleParityAxis.values.length));
      expect(
        target.axis(BattleParityAxis.damage).ruleId,
        'mainline-gen9-damage',
      );
      expect(
        target.axis(BattleParityAxis.speedTies),
        isA<BattleParityAxisTarget>()
            .having(
              (axis) => axis.ruleId,
              'ruleId',
              'mainline-gen9-seeded-random',
            )
            .having(
              (axis) => axis.alignment,
              'alignment',
              BattleParityAlignment.gap,
            ),
      );
      expect(
        target.axis(BattleParityAxis.experience).alignment,
        BattleParityAlignment.intentionalVariant,
      );
      expect(
        target.axis(BattleParityAxis.capture).alignment,
        BattleParityAlignment.intentionalVariant,
      );
    });

    test('does not promote PSDK counters as player parity evidence', () {
      const target = BattleParityTarget.canonicalV1;

      expect(target.counterPolicy.provesPlayerParity, isFalse);
      expect(
        target.counterPolicy.requiredCompanionProofs,
        <String>['runtimeBridge', 'playerSurface', 'goldenE2E'],
      );

      final json = target.toJson();
      expect(json['version'], 1);
      expect(json['profileId'], 'pokemap-mainline-hybrid-v1');
      expect(json['axes'], hasLength(6));
      expect(
        json['counterPolicy'],
        containsPair('provesPlayerParity', false),
      );
    });

    test('rejects an axis lookup missing from a custom target', () {
      const target = BattleParityTarget(
        version: 1,
        profileId: 'fixture',
        axes: <BattleParityAxisTarget>[],
        counterPolicy: BattleParityCounterPolicy(
          scope: 'fixture',
          provesPlayerParity: false,
          requiredCompanionProofs: <String>[],
        ),
      );

      expect(
        () => target.axis(BattleParityAxis.damage),
        throwsA(isA<StateError>()),
      );
    });
  });
}
```
