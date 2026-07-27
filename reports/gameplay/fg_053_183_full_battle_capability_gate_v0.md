# RM-053 — Full Battle Capability Gate — Evidence Pack

**Statut proposé : `DONE` pour RM-053.**

## Résumé exécutif

La gate combat complète `battle.full.v0` passe avec treize capacités promues.
Elle réutilise les dix preuves du cutline MVP et promeut séparément :

- `battle.item.held` : activation et write-back explicite des objets tenus ;
- `battle.stats.nature-iv-ev` : nature non neutre et IV/EV persistés consommés
  par les statistiques runtime ;
- `battle.decision.struggle` : PP épuisés ou moves entièrement bloqués résolus
  par Struggle sans mutation des PP ni du moveset.

La gate historique `battle.mvp.v0` reste inchangée : dix capacités bloquantes,
trois extensions différées et artefacts byte-for-byte identiques. La gate
complète déclare `mvpReleaseBlocking: false` et possède son propre générateur ;
elle ne peut donc pas élargir indirectement la cutline `FG-185`.

## Identification du lot

| Champ | Valeur |
|---|---|
| Lot | `RM-053 — Full Battle Capability Gate` |
| Liens canoniques | `FG-053`, `FG-183` |
| Dépendances | `RM-024`, `RM-026`, `RM-028`, `RM-029` |
| Gate MVP préservée | `battle.mvp.v0` |
| Nouvelle gate | `battle.full.v0` |
| Effet sur FG-185 | aucun, gate explicitement non bloquante |

## Confirmation et interprétation du scope

### Inclus

- matrice complète de treize capacités ;
- six références résolubles par capacité : contrôle, contrat, runtime, surface
  joueur, preuve positive et preuve négative ;
- preuve exacte que le cutline MVP reste à dix capacités ;
- sérialisation déterministe JSON et Markdown ;
- générateur `--write|--check` autonome pour la gate complète ;
- tests fail-closed, fraîcheur des artefacts et résolution `path#marker` ;
- revalidation ciblée des trois comportements promus.

### Hors scope conservé

- aucune nouvelle mécanique battle ;
- aucune modification des objets tenus, du calcul nature/IV/EV ou de Struggle ;
- aucune UI avancée nature/IV/EV, toujours différée dans `FG-206` ;
- aucun écran joueur pour équiper ou retirer un objet tenu ;
- aucune modification de la roadmap canonique ;
- aucune promotion de RM-053 dans les dépendances de `FG-185`.

### Remise en cause utile du libellé

Le livrable demandait « étendre la gate MVP ». Une extension en place aurait
fait de la fraîcheur des trois preuves complètes une condition potentielle de
la gate MVP, en contradiction avec « sans rendre ces lots bloquants pour
FG-185 ». L’interprétation retenue est donc :

1. conserver `BattleMvpCapabilityGate` et son générateur ;
2. ajouter une gate sœur `BattleFullCapabilityGate` ;
3. réutiliser les dix définitions MVP sans les recopier ;
4. substituer uniquement les trois attestations complètes ;
5. publier des artefacts et un exécutable séparés.

## Audit initial

### Contrats existants

- `BattleMvpCapabilityGate` déclarait déjà treize IDs : dix capacités promues
  dans le cutline et trois extensions différées ;
- `ProjectCapabilityTruthReport` vérifiait le set exact, les doublons, les
  raisons de report et les six couches obligatoires d’une capacité promue ;
- l’outil MVP produisait deux artefacts déterministes et échouait fermé ;
- RM-024, RM-028 et RM-029 avaient déjà livré les comportements et leurs tests.

### Fichiers et preuves examinés

- gate, tests, générateur et artefacts de RM-026 ;
- Evidence Packs RM-024, RM-028 et RM-029 ;
- authoring objet tenu dans le Trainer Studio ;
- contrats `ProjectTrainerPokemonEntry` et `PlayerPokemon` ;
- seed builder et write-back runtime ;
- `PokemonStatCalculator` et ses profils adverses ;
- décision, adapter et menu Struggle ;
- tests positifs et négatifs des trois extensions.

### Risques identifiés

- élargir silencieusement le cutline MVP ;
- faire dépendre l’outil MVP de la fraîcheur de l’artefact complet ;
- recopier les dix preuves MVP et créer deux vérités divergentes ;
- promouvoir une simple présence de champ sans consommation runtime ;
- utiliser une référence de test inexistante ou trop vague ;
- confondre contrôle persisté et UI d’authoring avancée pour nature/IV/EV.

## État Git initial

Base du lot : `e970a8e1c feat(battle): resolve exhausted pp with struggle`.

Le worktree contenait uniquement sept modifications utilisateur préexistantes,
explicitement exclues du lot :

```text
 M apps/pokemap_hub/lib/src/ui/hub_app.dart
 M apps/pokemap_hub/lib/src/ui/hub_shell.dart
 M apps/pokemap_hub/test/ui/hub_app_player_navigation_test.dart
 M apps/pokemap_hub/test/ui/hub_preferences_store_test.dart
 M apps/pokemap_hub/test/ui/hub_shell_test.dart
 M packages/map_player_ui/lib/src/localization/player_localizations.dart
 M packages/map_player_ui/lib/src/preferences/player_preferences.dart
```

## Verdict des cinq passes obligatoires

Les contraintes d’exécution interdisaient de déléguer ce lot à de nouveaux
agents. Les cinq revues ont donc été conduites comme cinq passes séparées et
nommées, conformément au fallback autorisé par `codex_rule.md`.

| Passe | Verdict | Signal principal |
|---|---|---|
| Audit / Architecture | PASS | deux gates indépendantes, source MVP unique |
| Implémentation | PASS | 13 capacités promues, trois extensions substituées |
| Tests | PASS après investigation d’un flake core | ciblés verts, suite core finale `success: true` |
| Build / Validation | PASS | deux exécutables compilés et checks à jour |
| Critique finale | PASS avec limites déclarées | couplage initial des générateurs détecté puis supprimé |

## Implémentation et zones précises

### Fichier modifié

| Fichier | Zone | Raison | Impact |
|---|---|---|---|
| `packages/map_core/lib/src/read_models/battle_mvp_capability_gate.dart` | constantes des sets et chemins | nommer séparément cutline MVP, extensions et set complet | invariant 10 + 3 explicite |
| même fichier | `BattleFullCapabilityGate` | sérialiser une gate complète non bloquante | JSON/Markdown déterministes |
| même fichier | `_canonicalBattleFullExtensions` | attester held item, nature/IV/EV et Struggle | six preuves résolubles par extension |
| même fichier | `_canonicalBattleFullCapabilities()` | réutiliser les dix définitions MVP et substituer trois extensions | aucune duplication de la vérité MVP |

### Découpage du diff du fichier modifié

```diff
+const battleFullCapabilityGateId = 'battle.full.v0';
+const battleMvpCutlineCapabilityIds = <String>{ /* 10 IDs */ };
+const battleFullExtensionCapabilityIds = <String>{ /* 3 IDs */ };
+const requiredBattleFullCapabilityIds = <String>{ /* 10 + 3 */ };
+const battleFullCapabilityJsonRelativePath = ...;
+const battleFullCapabilityMarkdownRelativePath = ...;
```

```diff
+final class BattleFullCapabilityGate {
+  factory BattleFullCapabilityGate.canonical() { ... }
+  bool get isMvpReleaseBlocking => false;
+  Map<String, Object?> toJson() => { ... };
+  String get agentMarkdown { ... }
+}
```

```diff
+const _canonicalBattleFullExtensions = <BattleMvpCapabilityDefinition>[
+  /* held item: authoring + contract + runtime + player + positive + negative */
+  /* nature/IV/EV: persisted control + calculator bridge + positive + negative */
+  /* Struggle: live control + typed decision + adapter/menu + proofs */
+];
+
+List<BattleMvpCapabilityDefinition> _canonicalBattleFullCapabilities() {
+  /* preserve the 10 MVP definitions and replace only the 3 extensions */
+}
```

Le générateur MVP et ses deux artefacts ont été contrôlés sans diff. Une
première implémentation faisait vérifier les deux gates par l’outil MVP ; la
passe critique l’a refusée et a conduit au générateur complet autonome.

## Fichiers créés

| Fichier | Rôle |
|---|---|
| `docs/superpowers/plans/2026-07-27-rm-053-full-battle-capability-gate.md` | plan exécuté |
| `packages/map_core/test/battle_full_capability_gate_test.dart` | positif, négatif, garde-fous, non-régression MVP |
| `packages/map_core/tool/generate_battle_full_capability_gate.dart` | génération et check autonomes |
| `reports/gameplay/generated/battle_full_capability_gate_v0.json` | artefact machine-readable |
| `reports/gameplay/generated/battle_full_capability_gate_v0.md` | vue humaine |
| `reports/gameplay/fg_053_183_full_battle_capability_gate_v0.md` | présent Evidence Pack |

Le présent rapport n’est pas reproduit dans lui-même afin d’éviter une
récursion infinie. Le contenu intégral des cinq autres fichiers créés figure en
annexe.

## Tests créés

`battle_full_capability_gate_test.dart` couvre :

- non-régression : gate MVP passante, dix IDs exacts et trois reports ;
- positif : treize capacités complètes promues ;
- frontière : `isMvpReleaseBlocking == false` et JSON correspondant ;
- négatif : suppression d’une preuve Struggle rejetée fail-closed ;
- déterminisme : deux sérialisations identiques ;
- fraîcheur : JSON et Markdown commités identiques au modèle ;
- garde-fou : chaque référence de chaque capacité résout un fichier et un
  marqueur réel.

## Commandes et résultats exacts

### Cycle TDD

```bash
cd packages/map_core
dart test test/battle_full_capability_gate_test.dart
```

```text
Failed to load test/battle_full_capability_gate_test.dart
Undefined name 'battleMvpCutlineCapabilityIds'
Undefined name 'BattleFullCapabilityGate'
Undefined name 'requiredBattleFullCapabilityIds'
Undefined name 'battleFullCapabilityGateId'
Undefined name 'battleFullCapabilityJsonRelativePath'
Undefined name 'battleFullCapabilityMarkdownRelativePath'
Some tests failed.
```

Après implémentation :

```bash
dart run tool/generate_battle_mvp_capability_gate.dart --check
dart run tool/generate_battle_full_capability_gate.dart --check
dart test test/battle_mvp_capability_gate_test.dart \
  test/battle_full_capability_gate_test.dart
dart analyze
```

```text
Battle MVP capability gate artifacts are up to date.
Battle full capability gate artifacts are up to date.
+13: All tests passed!
Analyzing map_core...
No issues found!
```

### Preuves fonctionnelles promues

```bash
cd packages/map_battle
dart test test/struggle_policy_v0_test.dart
dart analyze
```

```text
+7: All tests passed!
Analyzing map_battle...
No issues found!
```

```bash
cd packages/map_gameplay
dart test test/pokemon_stat_calculator_test.dart
dart analyze
```

```text
+7: All tests passed!
Analyzing map_gameplay...
No issues found!
```

```bash
cd packages/map_runtime
flutter test \
  test/runtime_held_item_bridge_v0_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/runtime_psdk_battle_decision_contract_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart
flutter analyze
```

```text
+32: All tests passed!
Analyzing map_runtime...
No issues found! (ran in 4.3s)
```

```bash
cd packages/map_editor
flutter test test/trainer_library_panel_test.dart \
  --plain-name 'creates a trainer and saves a complete team entry with assisted refs'
flutter test test/editor_notifier_trainer_update_test.dart \
  --plain-name 'updateTrainerPokemon leaves held item, form and gender untouched when only the level changes'
flutter analyze
```

```text
+1: All tests passed!
+1: All tests passed!
Analyzing map_editor...
No issues found! (ran in 5.8s)
```

### Suite complète `map_core` et investigation

Premier passage :

```bash
cd packages/map_core
dart test
```

```text
+4481 -1: Some tests failed.
```

Le reporter compact a tronqué le détail de l’unique erreur ; le premier état
`-1` est apparu pendant les tests lourds de bordure Selbrume, sans fichier
touché par RM-053. Le fichier suspect a été rejoué seul :

```bash
dart test test/border/selbrume_two_tier_stone_chain_v4_regression_test.dart \
  --reporter expanded
```

```text
+12: All tests passed!
```

Un essai de filtrage JSON strict a ensuite été invalidé par des lignes de log
non JSON et une fermeture de pipe ; il ne constitue pas un résultat de test.
Le rerun complet avec filtrage tolérant a terminé :

```bash
set -o pipefail
dart test --reporter json |
  jq -Rr 'fromjson? | select(.type == "error" or
    (.type == "testDone" and .result != "success") or .type == "done")'
```

```json
{
  "success": true,
  "type": "done",
  "time": 116918
}
```

Verdict : flake de charge non reproduit ; suite complète finale passante.

### Build

```bash
cd packages/map_core
rm053_build_dir=$(mktemp -d)
dart compile exe tool/generate_battle_full_capability_gate.dart \
  -o "$rm053_build_dir/battle_full_capability_gate"
"$rm053_build_dir/battle_full_capability_gate" --check
dart compile exe tool/generate_battle_mvp_capability_gate.dart \
  -o "$rm053_build_dir/battle_mvp_capability_gate"
"$rm053_build_dir/battle_mvp_capability_gate" --check
```

```text
Generated: .../battle_full_capability_gate
Battle full capability gate artifacts are up to date.
Generated: .../battle_mvp_capability_gate
Battle MVP capability gate artifacts are up to date.
```

Le package est une bibliothèque/outillage Dart ; la compilation des deux
exécutables est le build proportionné au lot.

### Format et hygiène

```bash
dart format \
  lib/src/read_models/battle_mvp_capability_gate.dart \
  test/battle_full_capability_gate_test.dart \
  tool/generate_battle_full_capability_gate.dart
git diff --check
```

```text
Formatted files conformes.
git diff --check: succès, aucune erreur de whitespace.
```

## État Git final attendu et isolation

Le commit RM-053 doit inclure uniquement le fichier modifié et les six fichiers
créés inventoriés ci-dessus. Les sept fichiers Hub/Player UI préexistants sont
exclus du staging.

Après commit, le worktree doit contenir exactement ces sept modifications
utilisateur. Le hash du commit et ce contrôle final sont consignés dans le
bilan de phase remis dans le chat.

## Statuts proposés

| ID | Statut proposé | Justification |
|---|---|---|
| `RM-053` | `DONE` | gate 13/13, artefacts, fail-closed, builds et preuves |
| `FG-053` | `DONE proposé` | cible RM-020 et preuves complètes RM-053 livrées |
| `FG-183` | reste `PARTIAL/TODO` | la full monorepo regression gate appartient à RM-070 |
| `FG-185` | inchangé | RM-053 reste explicitement hors cutline |
| `FG-206` | reste `DEFERRED` | aucun authoring avancé nature/IV/EV ajouté |

## Limites et risques restants

- les références `path#marker` prouvent la présence des points et tests ; elles
  ne remplacent pas l’exécution des suites, d’où leur revalidation séparée ;
- le contrôle nature/IV/EV est l’état persisté `PlayerPokemon`, pas une UI
  d’authoring compétitive ;
- le joueur ne dispose toujours pas d’un écran dédié pour gérer l’objet tenu ;
- le profil nature/IV/EV adverse reste le profil déterministe V0 de RM-028 ;
- les tests de bordure `map_core` sont coûteux et ont produit un flake initial
  non reproduit lors du rerun complet ;
- le type historique `BattleMvpCapabilityDefinition` est réutilisé par la gate
  complète pour éviter une migration API et une duplication hors scope.

## Auto-critique finale

- **Modification inutile recherchée :** aucune mécanique ou UI modifiée.
- **Effet de bord recherché :** artefacts et outil MVP sans diff.
- **Scope mélangé recherché :** aucune retouche de RM-024/028/029.
- **Commentaire manquant recherché :** séparation FG-185, contrôle persisté et
  décision live documentés dans le code.
- **Test insuffisant recherché :** positif, négatif, déterminisme, fraîcheur,
  marqueurs et non-régression MVP couverts.
- **Mensonge potentiel recherché :** `mvpReleaseBlocking: false` est corroboré
  par un générateur séparé ; les limites d’UI sont explicites.
- **Correction issue de la critique :** suppression du couplage initial entre
  le générateur MVP et la gate complète.

Verdict final : **PASS**, avec le flake core initial et les limites produit
ci-dessus explicitement conservés.

## Prochaines étapes proposées, non implémentées

1. démarrer `RM-030 — Wild Encounter Attribution V0`, premier lot de Phase 3 ;
2. garder l’outil full dans la future agrégation `RM-070`, sans l’ajouter aux
   dépendances FG-185 ;
3. traiter l’authoring nature/IV/EV uniquement dans `FG-206` ;
4. décider ultérieurement si un écran joueur d’équipement d’objet tenu rejoint
   la roadmap post-MVP.

## Annexe — contenu complet des fichiers créés

### `docs/superpowers/plans/2026-07-27-rm-053-full-battle-capability-gate.md`

~~~~markdown
# RM-053 Full Battle Capability Gate Implementation Plan

**Goal:** promouvoir dans une gate combat complète les objets tenus, la
fidélité nature/IV/EV et Struggle, sans modifier la cutline MVP de `RM-026`.

**Architecture:** `BattleMvpCapabilityGate` reste la source bloquante
`battle.mvp.v0` avec dix capacités promues et trois extensions différées.
`BattleFullCapabilityGate` réutilise les dix preuves MVP et remplace uniquement
les trois extensions par leurs attestations complètes. Le générateur publie des
artefacts déterministes séparés pour les deux gates.

**Lots concernés:** `RM-053`, `FG-053`, `FG-183`.

## Task 1: Caractériser les deux cutlines

- [x] Prouver que la gate MVP conserve exactement 10 capacités bloquantes.
- [x] Prouver que la gate complète promeut exactement 13 capacités.
- [x] Prouver que la gate complète reste déclarée non bloquante pour FG-185.
- [x] Prouver le fail-closed si une extension complète perd une référence.

## Task 2: Attester les extensions

- [x] Relier l’authoring, le contrat, le runtime, la surface joueur et les
  preuves positive/négative des objets tenus.
- [x] Relier le contrat persisté, le calcul gameplay, le runtime et les preuves
  positive/négative nature/IV/EV.
- [x] Relier le contrôle joueur, la décision, l’adapter runtime, le menu et les
  preuves positive/négative Struggle.

## Task 3: Générer les artefacts

- [x] Ajouter les sorties JSON et Markdown `battle_full_capability_gate_v0`.
- [x] Étendre `--write` et `--check` sans modifier le contenu canonique MVP.
- [x] Vérifier la résolution de chaque `path#marker`.

## Task 4: Vérifier et clôturer

- [x] Exécuter le test ciblé et l’analyse `map_core`.
- [x] Exécuter les preuves ciblées dans battle, gameplay, runtime et editor.
- [x] Produire l’Evidence Pack avec les cinq passes nommées.
- [x] Vérifier le diff, isoler les sept fichiers utilisateur et committer RM-053.
~~~~

### `packages/map_core/test/battle_full_capability_gate_test.dart`

~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('RM-053 full battle capability gate', () {
    test('keeps the RM-026 MVP cutline exact and independently passing', () {
      final gate = BattleMvpCapabilityGate.canonical();
      final cutlineIds = gate.definitions
          .where((definition) => definition.isMvpCutline)
          .map((definition) => definition.capabilityId)
          .toSet();

      expect(gate.report.isPassing, isTrue, reason: gate.report.agentMarkdown);
      expect(cutlineIds, battleMvpCutlineCapabilityIds);
      expect(cutlineIds, hasLength(10));
      expect(
        gate.definitions.where((definition) => !definition.isMvpCutline).every(
              (definition) =>
                  definition.record.status ==
                  ProjectCapabilityTruthStatus.deferred,
            ),
        isTrue,
      );
    });

    test('promotes all 13 capabilities without blocking the MVP release', () {
      final gate = BattleFullCapabilityGate.canonical();

      expect(gate.report.isPassing, isTrue, reason: gate.report.agentMarkdown);
      expect(gate.isMvpReleaseBlocking, isFalse);
      expect(
        gate.definitions.map((definition) => definition.capabilityId),
        unorderedEquals(requiredBattleFullCapabilityIds),
      );
      expect(gate.definitions, hasLength(13));
      expect(
        gate.definitions.every(
          (definition) =>
              definition.record.status == ProjectCapabilityTruthStatus.promoted,
        ),
        isTrue,
      );
      expect(
        gate.definitions
            .where((definition) => !definition.isMvpCutline)
            .map((definition) => definition.capabilityId),
        unorderedEquals(const <String>{
          battleHeldItemCapabilityId,
          battleNatureIvEvCapabilityId,
          battleStruggleCapabilityId,
        }),
      );
    });

    test('fails closed when one full-gate extension loses a proof', () {
      final gate = BattleFullCapabilityGate.canonical();
      final records = gate.definitions
          .map((definition) => definition.record)
          .toList(growable: false);
      final targetIndex = records.indexWhere(
        (record) => record.capabilityId == battleStruggleCapabilityId,
      );
      final target = records[targetIndex];
      records[targetIndex] = ProjectCapabilityTruthRecord.promoted(
        capabilityId: target.capabilityId,
        authoringControl: target.authoringControl!,
        contractField: target.contractField!,
        runtimeConsumer: target.runtimeConsumer!,
        playerSurface: target.playerSurface!,
        positiveTest: target.positiveTest!,
        negativeTest: '',
      );

      final incomplete = ProjectCapabilityTruthReport.evaluate(
        records,
        requiredCapabilityIds: requiredBattleFullCapabilityIds,
      );

      expect(incomplete.isPassing, isFalse);
      expect(
        incomplete.issues.map((issue) => issue.code),
        contains(ProjectCapabilityTruthIssueCode.missingNegativeTest),
      );
    });

    test('serializes a deterministic non-blocking full gate', () {
      final gate = BattleFullCapabilityGate.canonical();
      final first = const JsonEncoder.withIndent('  ').convert(gate.toJson());
      final second = const JsonEncoder.withIndent('  ').convert(
        BattleFullCapabilityGate.canonical().toJson(),
      );

      expect(second, first);
      expect(gate.toJson()['gateId'], battleFullCapabilityGateId);
      expect(gate.toJson()['status'], 'pass');
      expect(gate.toJson()['mvpReleaseBlocking'], isFalse);
      expect(gate.agentMarkdown, contains('Battle Full Capability Gate V0'));
      expect(gate.agentMarkdown, contains('non-blocking'));
      expect(gate.agentMarkdown, isNot(contains('`deferred`')));
    });

    test('committed generated artifacts match the canonical full gate', () {
      final repositoryRoot = Directory.current.parent.parent.path;
      final gate = BattleFullCapabilityGate.canonical();
      final expectedJson =
          '${const JsonEncoder.withIndent('  ').convert(gate.toJson())}\n';
      final expectedMarkdown = '${gate.agentMarkdown}\n';

      expect(
        File(
          '$repositoryRoot/$battleFullCapabilityJsonRelativePath',
        ).readAsStringSync(),
        expectedJson,
      );
      expect(
        File(
          '$repositoryRoot/$battleFullCapabilityMarkdownRelativePath',
        ).readAsStringSync(),
        expectedMarkdown,
      );
    });

    test('every promoted full-gate reference resolves to a proof marker', () {
      final repositoryRoot = Directory.current.parent.parent.path;
      final gate = BattleFullCapabilityGate.canonical();

      for (final definition in gate.definitions) {
        for (final reference in definition.promotedReferences) {
          final parts = reference.split('#');
          expect(
            parts,
            hasLength(2),
            reason:
                '${definition.capabilityId} must reference path#proof-marker',
          );
          final relativePath = parts.first;
          final file = File('$repositoryRoot/$relativePath');
          expect(
            file.existsSync(),
            isTrue,
            reason:
                '${definition.capabilityId} references missing file $relativePath',
          );
          final normalizedContent = _normalizeProofMarker(
            file.readAsStringSync(),
          );
          for (final marker in parts.last.split(',')) {
            expect(
              normalizedContent,
              contains(_normalizeProofMarker(marker)),
              reason:
                  '${definition.capabilityId} references missing marker $marker '
                  'in $relativePath',
            );
          }
        }
      }
    });
  });
}

String _normalizeProofMarker(String value) =>
    value.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
~~~~

### `packages/map_core/tool/generate_battle_full_capability_gate.dart`

~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';

void main(List<String> arguments) {
  final mode = switch (arguments) {
    ['--write'] => _GeneratorMode.write,
    ['--check'] => _GeneratorMode.check,
    _ => null,
  };
  if (mode == null) {
    stderr.writeln(
      'Usage: dart run tool/generate_battle_full_capability_gate.dart '
      '--write|--check',
    );
    exitCode = 64;
    return;
  }

  final gate = BattleFullCapabilityGate.canonical();
  // This executable is deliberately separate from the MVP generator. A stale
  // RM-053 artifact must fail the full audit without expanding the FG-185
  // release cutline owned by battle.mvp.v0.
  if (!gate.report.isPassing) {
    stderr.writeln(gate.agentMarkdown);
    exitCode = 1;
    return;
  }

  final repositoryRoot = Directory.current.parent.parent;
  // No timestamp or machine path is emitted: identical source truth must
  // produce byte-identical committed artifacts.
  final expected = <String, String>{
    battleFullCapabilityJsonRelativePath:
        '${const JsonEncoder.withIndent('  ').convert(gate.toJson())}\n',
    battleFullCapabilityMarkdownRelativePath: '${gate.agentMarkdown}\n',
  };

  switch (mode) {
    case _GeneratorMode.write:
      for (final entry in expected.entries) {
        final file = File('${repositoryRoot.path}/${entry.key}');
        file.parent.createSync(recursive: true);
        file.writeAsStringSync(entry.value);
        stdout.writeln('Wrote ${entry.key}');
      }
    case _GeneratorMode.check:
      var isCurrent = true;
      for (final entry in expected.entries) {
        final file = File('${repositoryRoot.path}/${entry.key}');
        if (!file.existsSync() || file.readAsStringSync() != entry.value) {
          stderr.writeln('Stale generated artifact: ${entry.key}');
          isCurrent = false;
        }
      }
      if (!isCurrent) {
        exitCode = 1;
        return;
      }
      stdout.writeln('Battle full capability gate artifacts are up to date.');
  }
}

enum _GeneratorMode { write, check }
~~~~

### `reports/gameplay/generated/battle_full_capability_gate_v0.json`

~~~~json
{
  "schemaVersion": 1,
  "gateId": "battle.full.v0",
  "status": "pass",
  "mvpReleaseBlocking": false,
  "mvpCutlineGateId": "battle.mvp.v0",
  "mvpCutlineCapabilityIds": [
    "battle.ai.trainer-difficulty",
    "battle.decision.flee",
    "battle.decision.forced-switch",
    "battle.decision.move",
    "battle.decision.switch",
    "battle.item.hp-heal",
    "battle.item.revive",
    "battle.item.status-cure",
    "battle.trainer.lifecycle",
    "battle.trainer.reward"
  ],
  "fullExtensionCapabilityIds": [
    "battle.decision.struggle",
    "battle.item.held",
    "battle.stats.nature-iv-ev"
  ],
  "capabilities": [
    {
      "cutline": "mvp",
      "scopeNote": "Authored trainer difficulty maps to bounded, distinct AI policies.",
      "capabilityId": "battle.ai.trainer-difficulty",
      "authoringControl": "packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart#trainer-library-edit-difficulty-slider",
      "contractField": "packages/map_core/lib/src/models/project_trainer.dart#battleDifficulty",
      "runtimeConsumer": "packages/map_runtime/lib/src/presentation/flame/runtime_trainer_battle_overrides.dart#resolveRuntimeTrainerPsdkAi",
      "playerSurface": "packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart#PlayableMapGame",
      "positiveTest": "packages/map_runtime/test/runtime_trainer_psdk_ai_policy_test.dart#maps-authored-low-and-high-difficulties",
      "negativeTest": "packages/map_battle/test/psdk_ai_difficulty_policy_test.dart#keeps-default-and-out-of-range-inputs-bounded",
      "status": "promoted",
      "reason": null
    },
    {
      "cutline": "mvp",
      "scopeNote": "Wild flee acceptance and trainer-battle refusal share the typed decision path.",
      "capabilityId": "battle.decision.flee",
      "authoringControl": "packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent",
      "contractField": "packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleFleeDecision",
      "runtimeConsumer": "packages/map_runtime/lib/src/application/runtime_psdk_battle_session_adapter.dart#submitDecision",
      "playerSurface": "packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent",
      "positiveTest": "packages/map_battle/test/unified_battle_decision_contract_test.dart#wild-turn-exposes-flee-through-the-canonical-request",
      "negativeTest": "packages/map_battle/test/unified_battle_decision_contract_test.dart#trainer-turn-rejects-flee-atomically",
      "status": "promoted",
      "reason": null
    },
    {
      "cutline": "mvp",
      "scopeNote": "A knockout requests and consumes a forced replacement without a free turn.",
      "capabilityId": "battle.decision.forced-switch",
      "authoringControl": "packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent",
      "contractField": "packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleSwitchDecision",
      "runtimeConsumer": "packages/map_runtime/lib/src/application/runtime_psdk_battle_session_adapter.dart#submitDecision",
      "playerSurface": "packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent",
      "positiveTest": "packages/map_battle/test/unified_battle_decision_contract_test.dart#fainted-active-produces-a-forced-replacement-request",
      "negativeTest": "packages/map_battle/test/unified_battle_decision_contract_test.dart#forced-replacement-does-not-grant-the-opponent-another-action",
      "status": "promoted",
      "reason": null
    },
    {
      "cutline": "mvp",
      "scopeNote": "The player can submit a legal move through the typed contract.",
      "capabilityId": "battle.decision.move",
      "authoringControl": "packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent",
      "contractField": "packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleFightDecision",
      "runtimeConsumer": "packages/map_runtime/lib/src/application/runtime_psdk_battle_session_adapter.dart#submitDecision",
      "playerSurface": "packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent",
      "positiveTest": "packages/map_battle/test/psdk_move_families/move_prevention_test.dart#clean-request-excludes-taunt-blocked-status-moves",
      "negativeTest": "packages/map_battle/test/psdk_move_families/move_prevention_test.dart#clean-request-excludes-disabled-moves",
      "status": "promoted",
      "reason": null
    },
    {
      "cutline": "full-extension",
      "scopeNote": "Exhausted or fully prevented moves expose canonical Struggle without PP write-back.",
      "capabilityId": "battle.decision.struggle",
      "authoringControl": "packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent",
      "contractField": "packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleDecision.struggle,canStruggle",
      "runtimeConsumer": "packages/map_runtime/lib/src/application/runtime_psdk_battle_session_adapter.dart#RuntimePsdkBattleSessionAdapter",
      "playerSurface": "packages/map_runtime/lib/src/presentation/flame/battle_command_menu_model.dart#BattleCommandMenuModel",
      "positiveTest": "packages/map_runtime/test/runtime_psdk_battle_decision_contract_test.dart#exhausted-PP-exposes-and-executes-Struggle-through-the-player-menu",
      "negativeTest": "packages/map_battle/test/struggle_policy_v0_test.dart#a-usable-move-keeps-Struggle-unavailable-and-rejection-atomic",
      "status": "promoted",
      "reason": null
    },
    {
      "cutline": "mvp",
      "scopeNote": "The player can switch voluntarily when the choice is legal.",
      "capabilityId": "battle.decision.switch",
      "authoringControl": "packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent",
      "contractField": "packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleSwitchDecision",
      "runtimeConsumer": "packages/map_runtime/lib/src/application/runtime_psdk_battle_session_adapter.dart#submitDecision",
      "playerSurface": "packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent",
      "positiveTest": "packages/map_battle/test/psdk_switch_action_test.dart#decision-request-exposes-legal-reserve-switches",
      "negativeTest": "packages/map_battle/test/psdk_switch_action_test.dart#rejects-illegal-switch-decisions-before-mutating-the-turn",
      "status": "promoted",
      "reason": null
    },
    {
      "cutline": "full-extension",
      "scopeNote": "Authored held items activate in battle and reconcile explicitly after battle.",
      "capabilityId": "battle.item.held",
      "authoringControl": "packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart#trainer-library-pokemon-item",
      "contractField": "packages/map_core/lib/src/models/project_trainer.dart#ProjectTrainerPokemonEntry,heldItemId",
      "runtimeConsumer": "packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart#_resolvePsdkHeldItemId",
      "playerSurface": "packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart#writePlayerPsdkHeldItemsBackToPartySlots",
      "positiveTest": "packages/map_runtime/test/runtime_held_item_bridge_v0_test.dart#a-runtime-seed-hydrates-and-executes-its-held-item-effect,writes-unchanged-consumed-removed-and-received-items-explicitly",
      "negativeTest": "packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart#rejects-a-held-item-whose-PSDK-effect-is-not-ported",
      "status": "promoted",
      "reason": null
    },
    {
      "cutline": "mvp",
      "scopeNote": "HP medicine validates target and amount before consumption.",
      "capabilityId": "battle.item.hp-heal",
      "authoringControl": "packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent",
      "contractField": "packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleItemDecision",
      "runtimeConsumer": "packages/map_battle/lib/src/domain/action/battle_item_action_handler.dart#BattleItemActionHandler",
      "playerSurface": "packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent",
      "positiveTest": "packages/map_battle/test/generic_battle_items_v0_test.dart#heals-an-explicit-reserve-party-target",
      "negativeTest": "packages/map_battle/test/generic_battle_items_v0_test.dart#rejects-a-no-effect-item-atomically",
      "status": "promoted",
      "reason": null
    },
    {
      "cutline": "mvp",
      "scopeNote": "Revive targets only a knocked-out party member.",
      "capabilityId": "battle.item.revive",
      "authoringControl": "packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent",
      "contractField": "packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleItemDecision",
      "runtimeConsumer": "packages/map_battle/lib/src/domain/action/battle_item_action_handler.dart#BattleItemActionHandler",
      "playerSurface": "packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent",
      "positiveTest": "packages/map_runtime/test/runtime_generic_battle_items_v0_test.dart#revive-restores-a-fainted-reserve-and-writes-it-back",
      "negativeTest": "packages/map_battle/test/generic_battle_items_v0_test.dart#rejects-a-no-effect-item-atomically",
      "status": "promoted",
      "reason": null
    },
    {
      "cutline": "mvp",
      "scopeNote": "Status medicine cures only a compatible afflicted target.",
      "capabilityId": "battle.item.status-cure",
      "authoringControl": "packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent",
      "contractField": "packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleItemDecision",
      "runtimeConsumer": "packages/map_battle/lib/src/domain/action/battle_item_action_handler.dart#BattleItemActionHandler",
      "playerSurface": "packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent",
      "positiveTest": "packages/map_battle/test/generic_battle_items_v0_test.dart#cures-a-compatible-major-status-on-an-explicit-target",
      "negativeTest": "packages/map_battle/test/generic_battle_items_v0_test.dart#rejects-an-invalid-item-target-before-the-turn-mutates",
      "status": "promoted",
      "reason": null
    },
    {
      "cutline": "full-extension",
      "scopeNote": "Persisted nature, IV, and EV values deterministically alter runtime battle stats.",
      "capabilityId": "battle.stats.nature-iv-ev",
      "authoringControl": "packages/map_core/lib/src/models/save_data.dart#PlayerPokemon",
      "contractField": "packages/map_core/lib/src/models/save_data.dart#natureId,ivs,evs",
      "runtimeConsumer": "packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart#RuntimeBattleCombatantSeedBuilder",
      "playerSurface": "packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart#PlayableMapGame",
      "positiveTest": "packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart#builds-a-player-combatant-seed-from-explicit-knownMoveIds",
      "negativeTest": "packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart#rejects-an-unknown-saved-nature-instead-of-neutralizing-it",
      "status": "promoted",
      "reason": null
    },
    {
      "cutline": "mvp",
      "scopeNote": "One-shot, reset, and rematch lifecycle policies survive save and reload.",
      "capabilityId": "battle.trainer.lifecycle",
      "authoringControl": "packages/map_editor/lib/src/ui/panels/trainer_library_panel_lifecycle_widgets.dart#_TrainerLifecycleEditor",
      "contractField": "packages/map_core/lib/src/models/project_trainer.dart#rematchPolicy",
      "runtimeConsumer": "packages/map_runtime/lib/src/application/runtime_trainer_lifecycle_policy.dart#resolveRuntimeTrainerInteractionPlan",
      "playerSurface": "packages/map_player_ui/lib/src/player/player_dialogue_overlay.dart#PlayerDialogueOverlay",
      "positiveTest": "packages/map_runtime/test/selbrume_event_v2_three_source_integration_test.dart#canonical-lysa-one-shot-stays-consumed-after-a-save-reload",
      "negativeTest": "packages/map_runtime/test/runtime_trainer_lifecycle_policy_test.dart#one-shot-defeated-trainer-only-shows-victory-dialogue",
      "status": "promoted",
      "reason": null
    },
    {
      "cutline": "mvp",
      "scopeNote": "Authored money, badge, field unlock, items, and creatures resolve after victory.",
      "capabilityId": "battle.trainer.reward",
      "authoringControl": "packages/map_editor/lib/src/ui/panels/trainer_library_panel_reward_widgets.dart#_TrainerRewardEditor",
      "contractField": "packages/map_core/lib/src/models/project_trainer.dart#moneyReward,rewardBadgeId,rewardFieldAbilityUnlock",
      "runtimeConsumer": "packages/map_runtime/lib/src/application/runtime_battle_reward_resolver.dart#RuntimeBattleRewardResolver",
      "playerSurface": "packages/map_player_ui/lib/src/player/player_post_battle_overlay.dart#PlayerPostBattleOverlay",
      "positiveTest": "packages/map_runtime/test/runtime_battle_reward_resolver_test.dart#maps-exact-authored-trainer-rewards-but-defers-their-application",
      "negativeTest": "packages/map_runtime/test/runtime_battle_reward_resolver_test.dart#fails-closed-when-the-authored-trainer-is-missing",
      "status": "promoted",
      "reason": null
    }
  ],
  "issues": []
}
~~~~

### `reports/gameplay/generated/battle_full_capability_gate_v0.md`

~~~~markdown
# Battle Full Capability Gate V0

Gate: `battle.full.v0` · Status: `pass` · MVP release: `non-blocking`

This RM-053 gate promotes the complete battle catalogue while leaving the independent `battle.mvp.v0` cutline unchanged for FG-185.

| Capability | Origin | Status | Scope |
|---|---|---|---|
| `battle.ai.trainer-difficulty` | `mvp-cutline` | `promoted` | Authored trainer difficulty maps to bounded, distinct AI policies. |
| `battle.decision.flee` | `mvp-cutline` | `promoted` | Wild flee acceptance and trainer-battle refusal share the typed decision path. |
| `battle.decision.forced-switch` | `mvp-cutline` | `promoted` | A knockout requests and consumes a forced replacement without a free turn. |
| `battle.decision.move` | `mvp-cutline` | `promoted` | The player can submit a legal move through the typed contract. |
| `battle.decision.struggle` | `full-extension` | `promoted` | Exhausted or fully prevented moves expose canonical Struggle without PP write-back. |
| `battle.decision.switch` | `mvp-cutline` | `promoted` | The player can switch voluntarily when the choice is legal. |
| `battle.item.held` | `full-extension` | `promoted` | Authored held items activate in battle and reconcile explicitly after battle. |
| `battle.item.hp-heal` | `mvp-cutline` | `promoted` | HP medicine validates target and amount before consumption. |
| `battle.item.revive` | `mvp-cutline` | `promoted` | Revive targets only a knocked-out party member. |
| `battle.item.status-cure` | `mvp-cutline` | `promoted` | Status medicine cures only a compatible afflicted target. |
| `battle.stats.nature-iv-ev` | `full-extension` | `promoted` | Persisted nature, IV, and EV values deterministically alter runtime battle stats. |
| `battle.trainer.lifecycle` | `mvp-cutline` | `promoted` | One-shot, reset, and rematch lifecycle policies survive save and reload. |
| `battle.trainer.reward` | `mvp-cutline` | `promoted` | Authored money, badge, field unlock, items, and creatures resolve after victory. |

## Promoted evidence

| Capability | Control | Contract | Runtime | Player | Positive | Negative |
|---|---|---|---|---|---|---|
| `battle.ai.trainer-difficulty` | packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart#trainer-library-edit-difficulty-slider | packages/map_core/lib/src/models/project_trainer.dart#battleDifficulty | packages/map_runtime/lib/src/presentation/flame/runtime_trainer_battle_overrides.dart#resolveRuntimeTrainerPsdkAi | packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart#PlayableMapGame | packages/map_runtime/test/runtime_trainer_psdk_ai_policy_test.dart#maps-authored-low-and-high-difficulties | packages/map_battle/test/psdk_ai_difficulty_policy_test.dart#keeps-default-and-out-of-range-inputs-bounded |
| `battle.decision.flee` | packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent | packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleFleeDecision | packages/map_runtime/lib/src/application/runtime_psdk_battle_session_adapter.dart#submitDecision | packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent | packages/map_battle/test/unified_battle_decision_contract_test.dart#wild-turn-exposes-flee-through-the-canonical-request | packages/map_battle/test/unified_battle_decision_contract_test.dart#trainer-turn-rejects-flee-atomically |
| `battle.decision.forced-switch` | packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent | packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleSwitchDecision | packages/map_runtime/lib/src/application/runtime_psdk_battle_session_adapter.dart#submitDecision | packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent | packages/map_battle/test/unified_battle_decision_contract_test.dart#fainted-active-produces-a-forced-replacement-request | packages/map_battle/test/unified_battle_decision_contract_test.dart#forced-replacement-does-not-grant-the-opponent-another-action |
| `battle.decision.move` | packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent | packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleFightDecision | packages/map_runtime/lib/src/application/runtime_psdk_battle_session_adapter.dart#submitDecision | packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent | packages/map_battle/test/psdk_move_families/move_prevention_test.dart#clean-request-excludes-taunt-blocked-status-moves | packages/map_battle/test/psdk_move_families/move_prevention_test.dart#clean-request-excludes-disabled-moves |
| `battle.decision.struggle` | packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent | packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleDecision.struggle,canStruggle | packages/map_runtime/lib/src/application/runtime_psdk_battle_session_adapter.dart#RuntimePsdkBattleSessionAdapter | packages/map_runtime/lib/src/presentation/flame/battle_command_menu_model.dart#BattleCommandMenuModel | packages/map_runtime/test/runtime_psdk_battle_decision_contract_test.dart#exhausted-PP-exposes-and-executes-Struggle-through-the-player-menu | packages/map_battle/test/struggle_policy_v0_test.dart#a-usable-move-keeps-Struggle-unavailable-and-rejection-atomic |
| `battle.decision.switch` | packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent | packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleSwitchDecision | packages/map_runtime/lib/src/application/runtime_psdk_battle_session_adapter.dart#submitDecision | packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent | packages/map_battle/test/psdk_switch_action_test.dart#decision-request-exposes-legal-reserve-switches | packages/map_battle/test/psdk_switch_action_test.dart#rejects-illegal-switch-decisions-before-mutating-the-turn |
| `battle.item.held` | packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart#trainer-library-pokemon-item | packages/map_core/lib/src/models/project_trainer.dart#ProjectTrainerPokemonEntry,heldItemId | packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart#_resolvePsdkHeldItemId | packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart#writePlayerPsdkHeldItemsBackToPartySlots | packages/map_runtime/test/runtime_held_item_bridge_v0_test.dart#a-runtime-seed-hydrates-and-executes-its-held-item-effect,writes-unchanged-consumed-removed-and-received-items-explicitly | packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart#rejects-a-held-item-whose-PSDK-effect-is-not-ported |
| `battle.item.hp-heal` | packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent | packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleItemDecision | packages/map_battle/lib/src/domain/action/battle_item_action_handler.dart#BattleItemActionHandler | packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent | packages/map_battle/test/generic_battle_items_v0_test.dart#heals-an-explicit-reserve-party-target | packages/map_battle/test/generic_battle_items_v0_test.dart#rejects-a-no-effect-item-atomically |
| `battle.item.revive` | packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent | packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleItemDecision | packages/map_battle/lib/src/domain/action/battle_item_action_handler.dart#BattleItemActionHandler | packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent | packages/map_runtime/test/runtime_generic_battle_items_v0_test.dart#revive-restores-a-fainted-reserve-and-writes-it-back | packages/map_battle/test/generic_battle_items_v0_test.dart#rejects-a-no-effect-item-atomically |
| `battle.item.status-cure` | packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent | packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleItemDecision | packages/map_battle/lib/src/domain/action/battle_item_action_handler.dart#BattleItemActionHandler | packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent | packages/map_battle/test/generic_battle_items_v0_test.dart#cures-a-compatible-major-status-on-an-explicit-target | packages/map_battle/test/generic_battle_items_v0_test.dart#rejects-an-invalid-item-target-before-the-turn-mutates |
| `battle.stats.nature-iv-ev` | packages/map_core/lib/src/models/save_data.dart#PlayerPokemon | packages/map_core/lib/src/models/save_data.dart#natureId,ivs,evs | packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart#RuntimeBattleCombatantSeedBuilder | packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart#PlayableMapGame | packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart#builds-a-player-combatant-seed-from-explicit-knownMoveIds | packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart#rejects-an-unknown-saved-nature-instead-of-neutralizing-it |
| `battle.trainer.lifecycle` | packages/map_editor/lib/src/ui/panels/trainer_library_panel_lifecycle_widgets.dart#_TrainerLifecycleEditor | packages/map_core/lib/src/models/project_trainer.dart#rematchPolicy | packages/map_runtime/lib/src/application/runtime_trainer_lifecycle_policy.dart#resolveRuntimeTrainerInteractionPlan | packages/map_player_ui/lib/src/player/player_dialogue_overlay.dart#PlayerDialogueOverlay | packages/map_runtime/test/selbrume_event_v2_three_source_integration_test.dart#canonical-lysa-one-shot-stays-consumed-after-a-save-reload | packages/map_runtime/test/runtime_trainer_lifecycle_policy_test.dart#one-shot-defeated-trainer-only-shows-victory-dialogue |
| `battle.trainer.reward` | packages/map_editor/lib/src/ui/panels/trainer_library_panel_reward_widgets.dart#_TrainerRewardEditor | packages/map_core/lib/src/models/project_trainer.dart#moneyReward,rewardBadgeId,rewardFieldAbilityUnlock | packages/map_runtime/lib/src/application/runtime_battle_reward_resolver.dart#RuntimeBattleRewardResolver | packages/map_player_ui/lib/src/player/player_post_battle_overlay.dart#PlayerPostBattleOverlay | packages/map_runtime/test/runtime_battle_reward_resolver_test.dart#maps-exact-authored-trainer-rewards-but-defers-their-application | packages/map_runtime/test/runtime_battle_reward_resolver_test.dart#fails-closed-when-the-authored-trainer-is-missing |
~~~~
