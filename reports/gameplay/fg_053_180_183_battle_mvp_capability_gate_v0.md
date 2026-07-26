# RM-026 — Battle MVP Capability Gate

## Résumé exécutif

**Lot exact :** `RM-026 — Battle MVP Capability Gate`

**Liens canoniques :** `FG-053`, `FG-180`, `FG-183`

**Verdict proposé :** `DONE`

Le cutline combat MVP possède maintenant une matrice canonique fail-closed,
générée en JSON et Markdown. Dix capacités sont promues : difficulté trainer,
move, switch volontaire, remplacement forcé, fuite, soin HP, guérison de
statut, rappel, récompenses trainer et lifecycle trainer. Chaque ligne promue
doit référencer un contrôle, un contrat, un consommateur runtime, une surface
joueur, une preuve positive et une preuve négative ; le test résout aussi le
fichier et le marqueur précis de chaque preuve.

Les objets tenus restent utilisables grâce à RM-024 mais sont explicitement
étiquetés comme extension avancée hors cutline MVP. Nature/IV/EV et Struggle
restent différés vers RM-028/RM-029 puis promouvables uniquement par RM-053.

## Confirmation du scope

### Inclus

- catalogue canonique de 13 capacités, dont 10 MVP et 3 extensions ;
- évaluation par la Capability Truth Gate RM-004 ;
- artefacts déterministes JSON/Markdown et commande `--check` ;
- vérification path + proof marker pour les 60 références promues ;
- signalétique editor honnête pour l’objet tenu hors cutline ;
- preuves Golden existantes rejouées pour IA, décisions, objets, rewards et lifecycle.

### Volontairement hors scope

- promouvoir les objets tenus dans le cutline MVP ;
- implémenter nature/IV/EV, réservé à RM-028 ;
- remplacer `noLegalChoice` par Struggle, réservé à RM-029 ;
- modifier la roadmap canonique ou promouvoir `FG-185` ;
- réimplémenter les comportements déjà livrés par RM-021 à RM-027.

## Audit initial

### Contrats et surfaces existants

- `ProjectCapabilityTruthReport` fournissait déjà un contrat fail-closed à six références, réutilisé au lieu d’être dupliqué.
- `map_battle` exposait déjà le contrat typé `BattleDecision`, les policies IA, les objets génériques et leurs tests positifs/négatifs.
- `map_runtime` consommait déjà les décisions, rewards et lifecycle trainer, avec smoke battle et preuve Selbrume save/reload.
- le Trainer Studio exposait l’objet tenu livré par RM-024 sans préciser qu’il se trouvait hors cutline MVP.
- aucun artefact canonique n’agrégeait ces preuves ni ne séparait le cutline MVP de la gate complète RM-053.

### Risques identifiés

- créer une deuxième notion de capability gate divergente de RM-004 ;
- promouvoir une capacité sur la seule existence d’un fichier de test ;
- faire passer held items pour bloquants MVP alors que RM-053 les possède ;
- rendre nature/IV/EV ou Struggle implicitement disponibles ;
- générer des artefacts non reproductibles avec timestamp ou chemin machine ;
- mélanger une défaillance de budget performance des bordures avec le scope battle.

### Interprétation prudente

Le champ générique `authoringControl` de RM-004 représente, pour une décision
live du joueur, son contrôle producteur dans `BattleOverlayComponent`. Ce choix
est déclaré explicitement dans le code : aucune donnée projet n’est inventée.
Les extensions complètes font partie du set canonique attendu mais restent
`deferred`, avec une raison RM-053 obligatoire.

## Verdict des cinq passes obligatoires

| Passe | Verdict | Signal principal |
|---|---|---|
| Audit / Architecture | PASS | RM-004 réutilisé ; frontières core/editor respectées |
| Implémentation | PASS | gate canonique, générateur et disclosure editor reliés |
| Tests | PASS avec incident externe documenté | preuves ciblées vertes ; deux budgets performance border échouent sous suite concurrente puis passent isolément |
| Build / Validation | PASS | analyses core/battle/runtime/editor vertes ; générateur compilé ; smoke battle vert |
| Critique finale | PASS avec limites | aucune capacité RM-028/RM-029 surpromue ; contrôle held item honnête |

Ces passes ont été réalisées séparément dans le même agent, conformément au
fallback autorisé par `codex_rule.md` lorsque de vrais sub-agents ne sont pas
utilisés pour ce lot.

## Inventaire exhaustif

### Fichiers modifiés

| Fichier | Zone | Raison et impact |
|---|---|---|
| `packages/map_core/lib/map_core.dart` | barrel read models | export public du gate battle |
| `packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart` | description Objet tenu | indique hors cutline MVP et RM-053 sans désactiver RM-024 |
| `packages/map_editor/test/trainer_library_panel_test.dart` | scénario création équipe | non-régression de la disclosure publique |

### Fichiers créés

| Fichier | Rôle |
|---|---|
| `packages/map_core/lib/src/read_models/battle_mvp_capability_gate.dart` | catalogue, cutline, sérialisation et Markdown canoniques |
| `packages/map_core/test/battle_mvp_capability_gate_test.dart` | set exact, fail-closed, déterminisme, fraîcheur et résolution des preuves |
| `packages/map_core/tool/generate_battle_mvp_capability_gate.dart` | génération `--write` et validation `--check` |
| `reports/gameplay/generated/battle_mvp_capability_gate_v0.json` | artefact machine-readable |
| `reports/gameplay/generated/battle_mvp_capability_gate_v0.md` | vue humaine générée |
| `docs/superpowers/plans/2026-07-27-rm-026-battle-mvp-capability-gate.md` | plan d’exécution |
| `reports/gameplay/fg_053_180_183_battle_mvp_capability_gate_v0.md` | présent Evidence Pack |

Le présent rapport n’est pas reproduit dans lui-même afin d’éviter une
récursion infinie. Tous les autres fichiers créés sont reproduits
intégralement en annexe.

## Découpage précis des modifications

### Core

- ajout des IDs stables, du set canonique et des chemins d’artefacts ;
- `BattleMvpCapabilityDefinition` sépare cutline MVP et extension complète ;
- `BattleMvpCapabilityGate.canonical()` trie puis évalue les 13 lignes via RM-004 ;
- `toJson()` est déterministe et sans timestamp ;
- `agentMarkdown` expose cutline, statut, scope, preuves et raisons de report ;
- les proof markers sont normalisés puis recherchés dans le contenu réel.

### Tooling

- `--write` crée les deux artefacts canoniques ;
- `--check` échoue si un octet diffère ou si un artefact manque ;
- le générateur refuse d’écrire un gate déjà en échec ;
- aucune date ni aucun chemin local n’entre dans les sorties.

### Editor

- la description de l’objet tenu conserve le contrôle catalogue livré ;
- elle précise « hors cutline MVP » et renvoie la validation complète à RM-053 ;
- le widget test exige désormais cette information à l’écran.

## Tests créés ou modifiés

### Positifs

- matrice canonique complète et `status: pass` ;
- dix lignes MVP promues ;
- trois extensions exactement différées ;
- sérialisation identique entre deux constructions ;
- artefacts commités byte-for-byte identiques ;
- chaque path et chaque proof marker résolus ;
- disclosure held item visible dans l’éditeur.

### Négatifs et garde-fous

- suppression d’une capacité canonique => `missingExpectedCapability` ;
- suppression d’une référence runtime => `missingRuntimeConsumer` ;
- extensions sans promotion prématurée et raison contenant RM-053 ;
- cibles objet invalides/no-effect sans mutation ;
- fuite trainer refusée, switch illégal rejeté, remplacement forcé sans tour gratuit ;
- one-shot Lysa toujours consommé après save/reload.

## Commandes et résultats exacts

### RED initial

```bash
cd packages/map_core
dart test test/battle_mvp_capability_gate_test.dart
```

```text
Échec de compilation attendu : BattleMvpCapabilityGate et les constantes du gate étaient undefined.
```

```bash
cd packages/map_editor
flutter test test/trainer_library_panel_test.dart --plain-name 'creates a trainer and saves a complete team entry with assisted refs'
```

```text
+0 -1 : attendu 1 widget contenant « hors cutline MVP », trouvé 0.
```

### Générateur et core ciblé

```bash
cd packages/map_core
dart run tool/generate_battle_mvp_capability_gate.dart --write
dart run tool/generate_battle_mvp_capability_gate.dart --check
dart test test/battle_mvp_capability_gate_test.dart
dart analyze
```

```text
Wrote reports/gameplay/generated/battle_mvp_capability_gate_v0.json
Wrote reports/gameplay/generated/battle_mvp_capability_gate_v0.md
Battle MVP capability gate artifacts are up to date.
+7: All tests passed!
Analyzing map_core... No issues found!
```

### Preuves battle

```bash
cd packages/map_battle
dart test test/psdk_ai_difficulty_policy_test.dart test/unified_battle_decision_contract_test.dart test/generic_battle_items_v0_test.dart
dart test test/psdk_move_families/move_prevention_test.dart test/psdk_switch_action_test.dart
dart analyze
```

```text
+14: All tests passed!
+34: All tests passed!
Analyzing map_battle... No issues found!
```

### Preuves runtime et Golden Slice

```bash
cd packages/map_runtime
flutter test test/runtime_trainer_psdk_ai_policy_test.dart test/runtime_psdk_battle_decision_contract_test.dart test/runtime_generic_battle_items_v0_test.dart test/runtime_battle_reward_resolver_test.dart test/runtime_trainer_lifecycle_policy_test.dart test/phase_a_golden_battle_slice_smoke_test.dart
flutter test test/selbrume_event_v2_three_source_integration_test.dart --plain-name 'canonical Lysa one-shot stays consumed after a save reload'
flutter analyze
```

```text
+28: All tests passed!
+1: All tests passed!
Analyzing map_runtime... No issues found! (ran in 6.1s)
```

### Editor

```bash
cd packages/map_editor
flutter test test/trainer_library_panel_test.dart
flutter analyze
```

```text
+15: All tests passed!
Analyzing map_editor... No issues found! (ran in 5.9s)
```

### Suite complète core et diagnostic honnête

```bash
cd packages/map_core
dart test --concurrency=4
```

```text
+4474 -2: Some tests failed.
samples six variants within the 95 candidate bound deterministically:
Expected < 8.000000s, actual 10.619207s.
bounds seven rotated variants to four native planner candidates:
Expected < 12.000000s, actual 14.976943s.
```

Ces deux tests de budget performance `border` ne touchent aucun fichier du
lot. Ils ont été relancés exactement, isolément :

```bash
dart test test/border/stone_chain_line_border_resolver_test.dart --plain-name 'two-tier stone-chain RED contract samples six variants within the 95 candidate bound deterministically'
dart test test/border/stone_chain_line_border_resolver_test.dart --plain-name 'two-tier stone-chain RED contract bounds seven rotated variants to four native planner candidates'
```

```text
+1: All tests passed!
+1: All tests passed!
```

Le fichier initialement suspecté a aussi été rejoué :

```bash
dart test test/border/border_canonical_gallery_test.dart --reporter expanded
```

```text
+15: All tests passed!
```

La suite complète n’est donc pas déclarée verte. L’incident est classé
performance concurrente hors scope, avec reproduction et preuves isolées.

### Build

```bash
cd packages/map_core
tmp_dir=$(mktemp -d)
dart compile exe tool/generate_battle_mvp_capability_gate.dart -o "$tmp_dir/battle_mvp_gate"
```

```text
Generated: .../battle_mvp_gate
```

Le build pertinent de ce lot de tooling est la compilation AOT du générateur.
Aucun exécutable Flutter n’a été modifié ; les packages Flutter consommateurs
ont été validés par tests ciblés et analyse.

### Hygiène

```bash
git diff --check
```

```text
Succès, aucune erreur ni whitespace error.
```

## État Git initial

Après le commit RM-027, seuls les fichiers utilisateur protégés préexistaient :

```text
 M apps/pokemap_hub/lib/src/ui/hub_app.dart
 M apps/pokemap_hub/lib/src/ui/hub_shell.dart
 M apps/pokemap_hub/test/ui/hub_app_player_navigation_test.dart
 M apps/pokemap_hub/test/ui/hub_preferences_store_test.dart
 M apps/pokemap_hub/test/ui/hub_shell_test.dart
 M packages/map_player_ui/lib/src/localization/player_localizations.dart
 M packages/map_player_ui/lib/src/preferences/player_preferences.dart
```

Ces fichiers n’ont été ni modifiés par RM-026 ni stagés.

## État Git final attendu après commit

Le commit isolé du lot doit laisser exactement les mêmes sept modifications
utilisateur protégées. Le statut réel a été vérifié immédiatement après le
commit et est rapporté dans le handoff de phase.

## Limites conservées

- held items : bridge livré, mais extension complète non promue ;
- nature/IV/EV : `deferred` jusqu’à RM-028 et RM-053 ;
- Struggle : `deferred`, `noLegalChoice` reste honnête jusqu’à RM-029 ;
- la gate référence des preuves mais ne remplace pas l’exécution des suites ;
- la gate MVP ne vaut pas encore gate combat complète.

## Auto-critique finale

### Points solides

- réutilisation du contrat générique au lieu d’un système parallèle ;
- artefacts reproductibles et testés byte-for-byte ;
- résolution des proof markers, pas seulement des fichiers ;
- séparation nette MVP/full-extension visible en JSON, Markdown et UI ;
- aucun changement de moteur battle dans un lot d’audit/tooling.

### Risques restants

- un test peut conserver son nom tout en affaiblissant ses assertions ; la gate
  garantit la traçabilité, pas l’analyse sémantique du corps du test ;
- les budgets performance border restent sensibles à la concurrence machine ;
- le champ RM-004 `authoringControl` est sémantiquement large pour les décisions
  live, même si le mapping vers le contrôle joueur est documenté ;
- RM-053 devra promouvoir les trois extensions seulement après preuves fraîches.

## Prochaines étapes proposées

1. RM-028 — appliquer nature/IV/EV sauvegardés aux stats runtime.
2. RM-029 — fournir la policy Struggle déterministe lorsque les PP sont épuisés.
3. RM-053 — promouvoir held items, nature/IV/EV et Struggle dans la gate complète.

## Annexes — contenu complet des fichiers créés

### `packages/map_core/lib/src/read_models/battle_mvp_capability_gate.dart`

```dart
import 'project_capability_truth.dart';

/// Stable identity consumed by generated audit artifacts and release tooling.
const battleMvpCapabilityGateId = 'battle.mvp.v0';

const battleTrainerDifficultyCapabilityId = 'battle.ai.trainer-difficulty';
const battleMoveDecisionCapabilityId = 'battle.decision.move';
const battleSwitchDecisionCapabilityId = 'battle.decision.switch';
const battleForcedSwitchDecisionCapabilityId = 'battle.decision.forced-switch';
const battleFleeDecisionCapabilityId = 'battle.decision.flee';
const battleHpHealItemCapabilityId = 'battle.item.hp-heal';
const battleStatusCureItemCapabilityId = 'battle.item.status-cure';
const battleReviveItemCapabilityId = 'battle.item.revive';
const battleTrainerRewardCapabilityId = 'battle.trainer.reward';
const battleTrainerLifecycleCapabilityId = 'battle.trainer.lifecycle';
const battleHeldItemCapabilityId = 'battle.item.held';
const battleNatureIvEvCapabilityId = 'battle.stats.nature-iv-ev';
const battleStruggleCapabilityId = 'battle.decision.struggle';

const requiredBattleMvpCapabilityIds = <String>{
  battleTrainerDifficultyCapabilityId,
  battleMoveDecisionCapabilityId,
  battleSwitchDecisionCapabilityId,
  battleForcedSwitchDecisionCapabilityId,
  battleFleeDecisionCapabilityId,
  battleHpHealItemCapabilityId,
  battleStatusCureItemCapabilityId,
  battleReviveItemCapabilityId,
  battleTrainerRewardCapabilityId,
  battleTrainerLifecycleCapabilityId,
  battleHeldItemCapabilityId,
  battleNatureIvEvCapabilityId,
  battleStruggleCapabilityId,
};

const battleMvpCapabilityJsonRelativePath =
    'reports/gameplay/generated/battle_mvp_capability_gate_v0.json';
const battleMvpCapabilityMarkdownRelativePath =
    'reports/gameplay/generated/battle_mvp_capability_gate_v0.md';

final class BattleMvpCapabilityDefinition {
  const BattleMvpCapabilityDefinition({
    required this.record,
    required this.isMvpCutline,
    required this.scopeNote,
  });

  final ProjectCapabilityTruthRecord record;
  final bool isMvpCutline;
  final String scopeNote;

  String get capabilityId => record.capabilityId;

  /// Enumerates every repository proof that a promoted row must keep alive.
  ///
  /// Deferred extensions deliberately expose no proof references: RM-026 must
  /// not make RM-028, RM-029, or the RM-053 full gate look complete early.
  Iterable<String> get promotedReferences sync* {
    if (record.status != ProjectCapabilityTruthStatus.promoted) return;
    yield record.authoringControl!;
    yield record.contractField!;
    yield record.runtimeConsumer!;
    yield record.playerSurface!;
    yield record.positiveTest!;
    yield record.negativeTest!;
  }

  Map<String, Object?> toJson() => {
        'cutline': isMvpCutline ? 'mvp' : 'full-extension',
        'scopeNote': scopeNote,
        ...record.toJson(),
      };
}

final class BattleMvpCapabilityGate {
  BattleMvpCapabilityGate._({
    required List<BattleMvpCapabilityDefinition> definitions,
    required this.report,
  }) : definitions = List.unmodifiable(definitions);

  factory BattleMvpCapabilityGate.canonical() {
    // Sorting here makes both human and machine artifacts reproducible across
    // platforms, independently from declaration order.
    final definitions = List<BattleMvpCapabilityDefinition>.of(
      _canonicalBattleMvpCapabilities,
    )..sort(
        (left, right) => left.capabilityId.compareTo(right.capabilityId),
      );
    return BattleMvpCapabilityGate._(
      definitions: definitions,
      report: ProjectCapabilityTruthReport.evaluate(
        definitions.map((definition) => definition.record),
        requiredCapabilityIds: requiredBattleMvpCapabilityIds,
      ),
    );
  }

  final List<BattleMvpCapabilityDefinition> definitions;
  final ProjectCapabilityTruthReport report;

  Map<String, Object?> toJson() => {
        'schemaVersion': 1,
        'gateId': battleMvpCapabilityGateId,
        'status': report.isPassing ? 'pass' : 'fail',
        'mvpCutlineCapabilityIds': [
          for (final definition
              in definitions.where((definition) => definition.isMvpCutline))
            definition.capabilityId,
        ],
        'fullExtensionCapabilityIds': [
          for (final definition
              in definitions.where((definition) => !definition.isMvpCutline))
            definition.capabilityId,
        ],
        'capabilities': [
          for (final definition in definitions) definition.toJson(),
        ],
        'issues': [for (final issue in report.issues) issue.toJson()],
      };

  String get agentMarkdown {
    final buffer = StringBuffer()
      ..writeln('# Battle MVP Capability Gate V0')
      ..writeln()
      ..writeln(
        'Gate: `$battleMvpCapabilityGateId` · '
        'Status: `${report.isPassing ? 'pass' : 'fail'}`',
      )
      ..writeln()
      ..writeln(
        'The MVP cutline is promoted only when authoring/player control, '
        'contract, runtime, player surface, positive proof, and negative '
        'proof are all referenced. Full-gate extensions remain explicit '
        'and non-promoted until RM-053.',
      )
      ..writeln()
      ..writeln('| Capability | Cutline | Status | Scope |')
      ..writeln('|---|---|---|---|');
    for (final definition in definitions) {
      buffer.writeln(
        '| `${definition.capabilityId}` | '
        '`${definition.isMvpCutline ? 'mvp' : 'full-extension'}` | '
        '`${definition.record.status.name}` | '
        '${_battleMarkdownCell(definition.scopeNote)} |',
      );
    }
    buffer
      ..writeln()
      ..writeln('## Promoted evidence')
      ..writeln()
      ..writeln(
        '| Capability | Control | Contract | Runtime | Player | Positive | Negative |',
      )
      ..writeln('|---|---|---|---|---|---|---|');
    for (final definition in definitions.where(
      (definition) =>
          definition.record.status == ProjectCapabilityTruthStatus.promoted,
    )) {
      final record = definition.record;
      buffer.writeln(
        '| `${record.capabilityId}` | '
        '${_battleMarkdownCell(record.authoringControl)} | '
        '${_battleMarkdownCell(record.contractField)} | '
        '${_battleMarkdownCell(record.runtimeConsumer)} | '
        '${_battleMarkdownCell(record.playerSurface)} | '
        '${_battleMarkdownCell(record.positiveTest)} | '
        '${_battleMarkdownCell(record.negativeTest)} |',
      );
    }
    buffer
      ..writeln()
      ..writeln('## Deferred extensions');
    for (final definition in definitions.where(
      (definition) =>
          definition.record.status == ProjectCapabilityTruthStatus.deferred,
    )) {
      buffer.writeln(
        '- `${definition.capabilityId}` · ${definition.record.reason}',
      );
    }
    if (report.issues.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## Blocking issues');
      for (final issue in report.issues) {
        buffer.writeln(
          '- `${issue.code.name}` · `${issue.capabilityId}` · '
          '${issue.message}',
        );
      }
    }
    return buffer.toString().trimRight();
  }
}

const _canonicalBattleMvpCapabilities = <BattleMvpCapabilityDefinition>[
  // Player-live decisions use their runtime controls as the "authoring"
  // reference required by the generic Capability Truth contract. They are not
  // project-authored data, but they still need a concrete producer/control.
  BattleMvpCapabilityDefinition(
    isMvpCutline: true,
    scopeNote:
        'Authored trainer difficulty maps to bounded, distinct AI policies.',
    record: ProjectCapabilityTruthRecord.promoted(
      capabilityId: battleTrainerDifficultyCapabilityId,
      authoringControl:
          'packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart#trainer-library-edit-difficulty-slider',
      contractField:
          'packages/map_core/lib/src/models/project_trainer.dart#battleDifficulty',
      runtimeConsumer:
          'packages/map_runtime/lib/src/presentation/flame/runtime_trainer_battle_overrides.dart#resolveRuntimeTrainerPsdkAi',
      playerSurface:
          'packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart#PlayableMapGame',
      positiveTest:
          'packages/map_runtime/test/runtime_trainer_psdk_ai_policy_test.dart#maps-authored-low-and-high-difficulties',
      negativeTest:
          'packages/map_battle/test/psdk_ai_difficulty_policy_test.dart#keeps-default-and-out-of-range-inputs-bounded',
    ),
  ),
  BattleMvpCapabilityDefinition(
    isMvpCutline: true,
    scopeNote: 'The player can submit a legal move through the typed contract.',
    record: ProjectCapabilityTruthRecord.promoted(
      capabilityId: battleMoveDecisionCapabilityId,
      authoringControl:
          'packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent',
      contractField:
          'packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleFightDecision',
      runtimeConsumer:
          'packages/map_runtime/lib/src/application/runtime_psdk_battle_session_adapter.dart#submitDecision',
      playerSurface:
          'packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent',
      positiveTest:
          'packages/map_battle/test/psdk_move_families/move_prevention_test.dart#clean-request-excludes-taunt-blocked-status-moves',
      negativeTest:
          'packages/map_battle/test/psdk_move_families/move_prevention_test.dart#clean-request-excludes-disabled-moves',
    ),
  ),
  BattleMvpCapabilityDefinition(
    isMvpCutline: true,
    scopeNote: 'The player can switch voluntarily when the choice is legal.',
    record: ProjectCapabilityTruthRecord.promoted(
      capabilityId: battleSwitchDecisionCapabilityId,
      authoringControl:
          'packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent',
      contractField:
          'packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleSwitchDecision',
      runtimeConsumer:
          'packages/map_runtime/lib/src/application/runtime_psdk_battle_session_adapter.dart#submitDecision',
      playerSurface:
          'packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent',
      positiveTest:
          'packages/map_battle/test/psdk_switch_action_test.dart#decision-request-exposes-legal-reserve-switches',
      negativeTest:
          'packages/map_battle/test/psdk_switch_action_test.dart#rejects-illegal-switch-decisions-before-mutating-the-turn',
    ),
  ),
  BattleMvpCapabilityDefinition(
    isMvpCutline: true,
    scopeNote:
        'A knockout requests and consumes a forced replacement without a free turn.',
    record: ProjectCapabilityTruthRecord.promoted(
      capabilityId: battleForcedSwitchDecisionCapabilityId,
      authoringControl:
          'packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent',
      contractField:
          'packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleSwitchDecision',
      runtimeConsumer:
          'packages/map_runtime/lib/src/application/runtime_psdk_battle_session_adapter.dart#submitDecision',
      playerSurface:
          'packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent',
      positiveTest:
          'packages/map_battle/test/unified_battle_decision_contract_test.dart#fainted-active-produces-a-forced-replacement-request',
      negativeTest:
          'packages/map_battle/test/unified_battle_decision_contract_test.dart#forced-replacement-does-not-grant-the-opponent-another-action',
    ),
  ),
  BattleMvpCapabilityDefinition(
    isMvpCutline: true,
    scopeNote:
        'Wild flee acceptance and trainer-battle refusal share the typed decision path.',
    record: ProjectCapabilityTruthRecord.promoted(
      capabilityId: battleFleeDecisionCapabilityId,
      authoringControl:
          'packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent',
      contractField:
          'packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleFleeDecision',
      runtimeConsumer:
          'packages/map_runtime/lib/src/application/runtime_psdk_battle_session_adapter.dart#submitDecision',
      playerSurface:
          'packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent',
      positiveTest:
          'packages/map_battle/test/unified_battle_decision_contract_test.dart#wild-turn-exposes-flee-through-the-canonical-request',
      negativeTest:
          'packages/map_battle/test/unified_battle_decision_contract_test.dart#trainer-turn-rejects-flee-atomically',
    ),
  ),
  BattleMvpCapabilityDefinition(
    isMvpCutline: true,
    scopeNote: 'HP medicine validates target and amount before consumption.',
    record: ProjectCapabilityTruthRecord.promoted(
      capabilityId: battleHpHealItemCapabilityId,
      authoringControl:
          'packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent',
      contractField:
          'packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleItemDecision',
      runtimeConsumer:
          'packages/map_battle/lib/src/domain/action/battle_item_action_handler.dart#BattleItemActionHandler',
      playerSurface:
          'packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent',
      positiveTest:
          'packages/map_battle/test/generic_battle_items_v0_test.dart#heals-an-explicit-reserve-party-target',
      negativeTest:
          'packages/map_battle/test/generic_battle_items_v0_test.dart#rejects-a-no-effect-item-atomically',
    ),
  ),
  BattleMvpCapabilityDefinition(
    isMvpCutline: true,
    scopeNote: 'Status medicine cures only a compatible afflicted target.',
    record: ProjectCapabilityTruthRecord.promoted(
      capabilityId: battleStatusCureItemCapabilityId,
      authoringControl:
          'packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent',
      contractField:
          'packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleItemDecision',
      runtimeConsumer:
          'packages/map_battle/lib/src/domain/action/battle_item_action_handler.dart#BattleItemActionHandler',
      playerSurface:
          'packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent',
      positiveTest:
          'packages/map_battle/test/generic_battle_items_v0_test.dart#cures-a-compatible-major-status-on-an-explicit-target',
      negativeTest:
          'packages/map_battle/test/generic_battle_items_v0_test.dart#rejects-an-invalid-item-target-before-the-turn-mutates',
    ),
  ),
  BattleMvpCapabilityDefinition(
    isMvpCutline: true,
    scopeNote: 'Revive targets only a knocked-out party member.',
    record: ProjectCapabilityTruthRecord.promoted(
      capabilityId: battleReviveItemCapabilityId,
      authoringControl:
          'packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent',
      contractField:
          'packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleItemDecision',
      runtimeConsumer:
          'packages/map_battle/lib/src/domain/action/battle_item_action_handler.dart#BattleItemActionHandler',
      playerSurface:
          'packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent',
      positiveTest:
          'packages/map_runtime/test/runtime_generic_battle_items_v0_test.dart#revive-restores-a-fainted-reserve-and-writes-it-back',
      negativeTest:
          'packages/map_battle/test/generic_battle_items_v0_test.dart#rejects-a-no-effect-item-atomically',
    ),
  ),
  BattleMvpCapabilityDefinition(
    isMvpCutline: true,
    scopeNote:
        'Authored money, badge, field unlock, items, and creatures resolve after victory.',
    record: ProjectCapabilityTruthRecord.promoted(
      capabilityId: battleTrainerRewardCapabilityId,
      authoringControl:
          'packages/map_editor/lib/src/ui/panels/trainer_library_panel_reward_widgets.dart#_TrainerRewardEditor',
      contractField:
          'packages/map_core/lib/src/models/project_trainer.dart#moneyReward,rewardBadgeId,rewardFieldAbilityUnlock',
      runtimeConsumer:
          'packages/map_runtime/lib/src/application/runtime_battle_reward_resolver.dart#RuntimeBattleRewardResolver',
      playerSurface:
          'packages/map_player_ui/lib/src/player/player_post_battle_overlay.dart#PlayerPostBattleOverlay',
      positiveTest:
          'packages/map_runtime/test/runtime_battle_reward_resolver_test.dart#maps-exact-authored-trainer-rewards-but-defers-their-application',
      negativeTest:
          'packages/map_runtime/test/runtime_battle_reward_resolver_test.dart#fails-closed-when-the-authored-trainer-is-missing',
    ),
  ),
  BattleMvpCapabilityDefinition(
    isMvpCutline: true,
    scopeNote:
        'One-shot, reset, and rematch lifecycle policies survive save and reload.',
    record: ProjectCapabilityTruthRecord.promoted(
      capabilityId: battleTrainerLifecycleCapabilityId,
      authoringControl:
          'packages/map_editor/lib/src/ui/panels/trainer_library_panel_lifecycle_widgets.dart#_TrainerLifecycleEditor',
      contractField:
          'packages/map_core/lib/src/models/project_trainer.dart#rematchPolicy',
      runtimeConsumer:
          'packages/map_runtime/lib/src/application/runtime_trainer_lifecycle_policy.dart#resolveRuntimeTrainerInteractionPlan',
      playerSurface:
          'packages/map_player_ui/lib/src/player/player_dialogue_overlay.dart#PlayerDialogueOverlay',
      positiveTest:
          'packages/map_runtime/test/selbrume_event_v2_three_source_integration_test.dart#canonical-lysa-one-shot-stays-consumed-after-a-save-reload',
      negativeTest:
          'packages/map_runtime/test/runtime_trainer_lifecycle_policy_test.dart#one-shot-defeated-trainer-only-shows-victory-dialogue',
    ),
  ),
  BattleMvpCapabilityDefinition(
    // Held items are usable after RM-024, but intentionally remain outside
    // the blocking MVP cutline. RM-053 owns their complete parity proof.
    isMvpCutline: false,
    scopeNote:
        'Runtime bridge delivered by RM-024, intentionally outside the MVP cutline.',
    record: ProjectCapabilityTruthRecord.deferred(
      capabilityId: battleHeldItemCapabilityId,
      reason:
          'RM-024 delivers the runtime bridge, but held-item completeness remains outside the MVP cutline until the RM-053 full battle gate.',
    ),
  ),
  BattleMvpCapabilityDefinition(
    isMvpCutline: false,
    scopeNote: 'Nature, IV, and EV parity belongs to the full battle gate.',
    record: ProjectCapabilityTruthRecord.deferred(
      capabilityId: battleNatureIvEvCapabilityId,
      reason:
          'RM-028 must deliver deterministic nature, IV, and EV parity before the RM-053 full battle gate can promote this capability.',
    ),
  ),
  BattleMvpCapabilityDefinition(
    isMvpCutline: false,
    scopeNote:
        'The no-legal-choice Struggle fallback is a full-gate extension.',
    record: ProjectCapabilityTruthRecord.deferred(
      capabilityId: battleStruggleCapabilityId,
      reason:
          'RM-029 must deliver the deterministic Struggle fallback before the RM-053 full battle gate can promote this capability.',
    ),
  ),
];

String _battleMarkdownCell(String? value) =>
    (value == null || value.trim().isEmpty ? '—' : value)
        .replaceAll('|', r'\|')
        .replaceAll('\n', ' ');
```

### `packages/map_core/test/battle_mvp_capability_gate_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Battle MVP capability gate', () {
    test('canonical matrix passes with the exact fail-closed capability set',
        () {
      final gate = BattleMvpCapabilityGate.canonical();

      expect(gate.report.isPassing, isTrue, reason: gate.report.agentMarkdown);
      expect(
        gate.definitions.map((definition) => definition.capabilityId),
        unorderedEquals(requiredBattleMvpCapabilityIds),
      );
      expect(
        gate.definitions.where((definition) => definition.isMvpCutline).every(
            (definition) =>
                definition.record.status ==
                ProjectCapabilityTruthStatus.promoted),
        isTrue,
      );
    });

    test('keeps full-gate extensions explicitly deferred from the MVP cutline',
        () {
      final gate = BattleMvpCapabilityGate.canonical();
      final extensions = gate.definitions
          .where((definition) => !definition.isMvpCutline)
          .toList(growable: false);

      expect(
        extensions.map((definition) => definition.capabilityId),
        unorderedEquals(const <String>{
          battleHeldItemCapabilityId,
          battleNatureIvEvCapabilityId,
          battleStruggleCapabilityId,
        }),
      );
      expect(
        extensions.every(
          (definition) =>
              definition.record.status ==
                  ProjectCapabilityTruthStatus.deferred &&
              definition.record.reason!.contains('RM-053'),
        ),
        isTrue,
      );
    });

    test('fails closed when one canonical capability disappears', () {
      final gate = BattleMvpCapabilityGate.canonical();
      final incomplete = ProjectCapabilityTruthReport.evaluate(
        gate.definitions.skip(1).map((definition) => definition.record),
        requiredCapabilityIds: requiredBattleMvpCapabilityIds,
      );

      expect(incomplete.isPassing, isFalse);
      expect(
        incomplete.issues.map((issue) => issue.code),
        contains(ProjectCapabilityTruthIssueCode.missingExpectedCapability),
      );
    });

    test('fails closed when a promoted capability loses a layer proof', () {
      final gate = BattleMvpCapabilityGate.canonical();
      final records = gate.definitions
          .map((definition) => definition.record)
          .toList(growable: false);
      final targetIndex = records.indexWhere(
        (record) => record.capabilityId == battleTrainerDifficultyCapabilityId,
      );
      records[targetIndex] = const ProjectCapabilityTruthRecord.promoted(
        capabilityId: battleTrainerDifficultyCapabilityId,
        authoringControl: 'editor',
        contractField: 'contract',
        runtimeConsumer: '',
        playerSurface: 'player',
        positiveTest: 'positive',
        negativeTest: 'negative',
      );

      final incomplete = ProjectCapabilityTruthReport.evaluate(
        records,
        requiredCapabilityIds: requiredBattleMvpCapabilityIds,
      );

      expect(incomplete.isPassing, isFalse);
      expect(
        incomplete.issues.map((issue) => issue.code),
        contains(ProjectCapabilityTruthIssueCode.missingRuntimeConsumer),
      );
    });

    test('serializes a deterministic machine-readable cutline', () {
      final gate = BattleMvpCapabilityGate.canonical();
      final first = const JsonEncoder.withIndent('  ').convert(gate.toJson());
      final second = const JsonEncoder.withIndent('  ').convert(
        BattleMvpCapabilityGate.canonical().toJson(),
      );

      expect(second, first);
      expect(gate.toJson()['gateId'], battleMvpCapabilityGateId);
      expect(gate.toJson()['status'], 'pass');
      expect(gate.agentMarkdown, contains('Battle MVP Capability Gate V0'));
      expect(gate.agentMarkdown, contains('`deferred`'));
    });

    test('committed generated artifacts match the canonical gate', () {
      final repositoryRoot = Directory.current.parent.parent.path;
      final gate = BattleMvpCapabilityGate.canonical();
      final expectedJson =
          '${const JsonEncoder.withIndent('  ').convert(gate.toJson())}\n';
      final expectedMarkdown = '${gate.agentMarkdown}\n';

      expect(
        File(
          '$repositoryRoot/$battleMvpCapabilityJsonRelativePath',
        ).readAsStringSync(),
        expectedJson,
      );
      expect(
        File(
          '$repositoryRoot/$battleMvpCapabilityMarkdownRelativePath',
        ).readAsStringSync(),
        expectedMarkdown,
      );
    });

    test('every promoted reference resolves to a repository proof marker', () {
      final repositoryRoot = Directory.current.parent.parent.path;
      final gate = BattleMvpCapabilityGate.canonical();

      for (final definition in gate.definitions.where(
        (definition) =>
            definition.record.status == ProjectCapabilityTruthStatus.promoted,
      )) {
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
```

### `packages/map_core/tool/generate_battle_mvp_capability_gate.dart`

```dart
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
      'Usage: dart run tool/generate_battle_mvp_capability_gate.dart '
      '--write|--check',
    );
    exitCode = 64;
    return;
  }

  final gate = BattleMvpCapabilityGate.canonical();
  // Never publish a pleasant-looking artifact for a gate that already knows
  // it is incomplete. The failing markdown is more useful to CI operators.
  if (!gate.report.isPassing) {
    stderr.writeln(gate.agentMarkdown);
    exitCode = 1;
    return;
  }

  final repositoryRoot = Directory.current.parent.parent;
  // No timestamp or machine path is emitted: identical source truth must
  // produce byte-identical committed artifacts.
  final expected = <String, String>{
    battleMvpCapabilityJsonRelativePath:
        '${const JsonEncoder.withIndent('  ').convert(gate.toJson())}\n',
    battleMvpCapabilityMarkdownRelativePath: '${gate.agentMarkdown}\n',
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
      stdout.writeln('Battle MVP capability gate artifacts are up to date.');
  }
}

enum _GeneratorMode { write, check }
```

### `reports/gameplay/generated/battle_mvp_capability_gate_v0.json`

```json
{
  "schemaVersion": 1,
  "gateId": "battle.mvp.v0",
  "status": "pass",
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
      "scopeNote": "The no-legal-choice Struggle fallback is a full-gate extension.",
      "capabilityId": "battle.decision.struggle",
      "authoringControl": null,
      "contractField": null,
      "runtimeConsumer": null,
      "playerSurface": null,
      "positiveTest": null,
      "negativeTest": null,
      "status": "deferred",
      "reason": "RM-029 must deliver the deterministic Struggle fallback before the RM-053 full battle gate can promote this capability."
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
      "scopeNote": "Runtime bridge delivered by RM-024, intentionally outside the MVP cutline.",
      "capabilityId": "battle.item.held",
      "authoringControl": null,
      "contractField": null,
      "runtimeConsumer": null,
      "playerSurface": null,
      "positiveTest": null,
      "negativeTest": null,
      "status": "deferred",
      "reason": "RM-024 delivers the runtime bridge, but held-item completeness remains outside the MVP cutline until the RM-053 full battle gate."
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
      "scopeNote": "Nature, IV, and EV parity belongs to the full battle gate.",
      "capabilityId": "battle.stats.nature-iv-ev",
      "authoringControl": null,
      "contractField": null,
      "runtimeConsumer": null,
      "playerSurface": null,
      "positiveTest": null,
      "negativeTest": null,
      "status": "deferred",
      "reason": "RM-028 must deliver deterministic nature, IV, and EV parity before the RM-053 full battle gate can promote this capability."
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
```

### `reports/gameplay/generated/battle_mvp_capability_gate_v0.md`

```markdown
# Battle MVP Capability Gate V0

Gate: `battle.mvp.v0` · Status: `pass`

The MVP cutline is promoted only when authoring/player control, contract, runtime, player surface, positive proof, and negative proof are all referenced. Full-gate extensions remain explicit and non-promoted until RM-053.

| Capability | Cutline | Status | Scope |
|---|---|---|---|
| `battle.ai.trainer-difficulty` | `mvp` | `promoted` | Authored trainer difficulty maps to bounded, distinct AI policies. |
| `battle.decision.flee` | `mvp` | `promoted` | Wild flee acceptance and trainer-battle refusal share the typed decision path. |
| `battle.decision.forced-switch` | `mvp` | `promoted` | A knockout requests and consumes a forced replacement without a free turn. |
| `battle.decision.move` | `mvp` | `promoted` | The player can submit a legal move through the typed contract. |
| `battle.decision.struggle` | `full-extension` | `deferred` | The no-legal-choice Struggle fallback is a full-gate extension. |
| `battle.decision.switch` | `mvp` | `promoted` | The player can switch voluntarily when the choice is legal. |
| `battle.item.held` | `full-extension` | `deferred` | Runtime bridge delivered by RM-024, intentionally outside the MVP cutline. |
| `battle.item.hp-heal` | `mvp` | `promoted` | HP medicine validates target and amount before consumption. |
| `battle.item.revive` | `mvp` | `promoted` | Revive targets only a knocked-out party member. |
| `battle.item.status-cure` | `mvp` | `promoted` | Status medicine cures only a compatible afflicted target. |
| `battle.stats.nature-iv-ev` | `full-extension` | `deferred` | Nature, IV, and EV parity belongs to the full battle gate. |
| `battle.trainer.lifecycle` | `mvp` | `promoted` | One-shot, reset, and rematch lifecycle policies survive save and reload. |
| `battle.trainer.reward` | `mvp` | `promoted` | Authored money, badge, field unlock, items, and creatures resolve after victory. |

## Promoted evidence

| Capability | Control | Contract | Runtime | Player | Positive | Negative |
|---|---|---|---|---|---|---|
| `battle.ai.trainer-difficulty` | packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart#trainer-library-edit-difficulty-slider | packages/map_core/lib/src/models/project_trainer.dart#battleDifficulty | packages/map_runtime/lib/src/presentation/flame/runtime_trainer_battle_overrides.dart#resolveRuntimeTrainerPsdkAi | packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart#PlayableMapGame | packages/map_runtime/test/runtime_trainer_psdk_ai_policy_test.dart#maps-authored-low-and-high-difficulties | packages/map_battle/test/psdk_ai_difficulty_policy_test.dart#keeps-default-and-out-of-range-inputs-bounded |
| `battle.decision.flee` | packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent | packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleFleeDecision | packages/map_runtime/lib/src/application/runtime_psdk_battle_session_adapter.dart#submitDecision | packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent | packages/map_battle/test/unified_battle_decision_contract_test.dart#wild-turn-exposes-flee-through-the-canonical-request | packages/map_battle/test/unified_battle_decision_contract_test.dart#trainer-turn-rejects-flee-atomically |
| `battle.decision.forced-switch` | packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent | packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleSwitchDecision | packages/map_runtime/lib/src/application/runtime_psdk_battle_session_adapter.dart#submitDecision | packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent | packages/map_battle/test/unified_battle_decision_contract_test.dart#fainted-active-produces-a-forced-replacement-request | packages/map_battle/test/unified_battle_decision_contract_test.dart#forced-replacement-does-not-grant-the-opponent-another-action |
| `battle.decision.move` | packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent | packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleFightDecision | packages/map_runtime/lib/src/application/runtime_psdk_battle_session_adapter.dart#submitDecision | packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent | packages/map_battle/test/psdk_move_families/move_prevention_test.dart#clean-request-excludes-taunt-blocked-status-moves | packages/map_battle/test/psdk_move_families/move_prevention_test.dart#clean-request-excludes-disabled-moves |
| `battle.decision.switch` | packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent | packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleSwitchDecision | packages/map_runtime/lib/src/application/runtime_psdk_battle_session_adapter.dart#submitDecision | packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent | packages/map_battle/test/psdk_switch_action_test.dart#decision-request-exposes-legal-reserve-switches | packages/map_battle/test/psdk_switch_action_test.dart#rejects-illegal-switch-decisions-before-mutating-the-turn |
| `battle.item.hp-heal` | packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent | packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleItemDecision | packages/map_battle/lib/src/domain/action/battle_item_action_handler.dart#BattleItemActionHandler | packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent | packages/map_battle/test/generic_battle_items_v0_test.dart#heals-an-explicit-reserve-party-target | packages/map_battle/test/generic_battle_items_v0_test.dart#rejects-a-no-effect-item-atomically |
| `battle.item.revive` | packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent | packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleItemDecision | packages/map_battle/lib/src/domain/action/battle_item_action_handler.dart#BattleItemActionHandler | packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent | packages/map_runtime/test/runtime_generic_battle_items_v0_test.dart#revive-restores-a-fainted-reserve-and-writes-it-back | packages/map_battle/test/generic_battle_items_v0_test.dart#rejects-a-no-effect-item-atomically |
| `battle.item.status-cure` | packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent | packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleItemDecision | packages/map_battle/lib/src/domain/action/battle_item_action_handler.dart#BattleItemActionHandler | packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent | packages/map_battle/test/generic_battle_items_v0_test.dart#cures-a-compatible-major-status-on-an-explicit-target | packages/map_battle/test/generic_battle_items_v0_test.dart#rejects-an-invalid-item-target-before-the-turn-mutates |
| `battle.trainer.lifecycle` | packages/map_editor/lib/src/ui/panels/trainer_library_panel_lifecycle_widgets.dart#_TrainerLifecycleEditor | packages/map_core/lib/src/models/project_trainer.dart#rematchPolicy | packages/map_runtime/lib/src/application/runtime_trainer_lifecycle_policy.dart#resolveRuntimeTrainerInteractionPlan | packages/map_player_ui/lib/src/player/player_dialogue_overlay.dart#PlayerDialogueOverlay | packages/map_runtime/test/selbrume_event_v2_three_source_integration_test.dart#canonical-lysa-one-shot-stays-consumed-after-a-save-reload | packages/map_runtime/test/runtime_trainer_lifecycle_policy_test.dart#one-shot-defeated-trainer-only-shows-victory-dialogue |
| `battle.trainer.reward` | packages/map_editor/lib/src/ui/panels/trainer_library_panel_reward_widgets.dart#_TrainerRewardEditor | packages/map_core/lib/src/models/project_trainer.dart#moneyReward,rewardBadgeId,rewardFieldAbilityUnlock | packages/map_runtime/lib/src/application/runtime_battle_reward_resolver.dart#RuntimeBattleRewardResolver | packages/map_player_ui/lib/src/player/player_post_battle_overlay.dart#PlayerPostBattleOverlay | packages/map_runtime/test/runtime_battle_reward_resolver_test.dart#maps-exact-authored-trainer-rewards-but-defers-their-application | packages/map_runtime/test/runtime_battle_reward_resolver_test.dart#fails-closed-when-the-authored-trainer-is-missing |

## Deferred extensions
- `battle.decision.struggle` · RM-029 must deliver the deterministic Struggle fallback before the RM-053 full battle gate can promote this capability.
- `battle.item.held` · RM-024 delivers the runtime bridge, but held-item completeness remains outside the MVP cutline until the RM-053 full battle gate.
- `battle.stats.nature-iv-ev` · RM-028 must deliver deterministic nature, IV, and EV parity before the RM-053 full battle gate can promote this capability.
```

### `docs/superpowers/plans/2026-07-27-rm-026-battle-mvp-capability-gate.md`

```markdown
# RM-026 Battle MVP Capability Gate Implementation Plan

**Goal:** produire une matrice battle lisible par machine qui échoue fermée si
une capacité du cutline MVP perd son contrat, son consommateur, sa surface ou
ses preuves, et déclarer explicitement les extensions hors cutline.

**Architecture:** `map_core` étend la Capability Truth Gate RM-004 avec un
catalogue battle canonique. Un outil déterministe génère JSON et Markdown puis
vérifie leur fraîcheur en mode `--check`. L’éditeur signale l’objet tenu comme
fonction avancée hors cutline MVP, sans nier le bridge livré par RM-024.

**Non-goals:** promouvoir `FG-185`, réimplémenter les lots RM-021–RM-027,
inclure objets tenus/nature-IV-EV/Struggle dans le cutline MVP, modifier la
roadmap canonique.

### Task 1: Gate core fail-closed

- [x] Définir les capacités MVP et extensions attendues.
- [x] Relier chaque capacité promue aux six références RM-004.
- [x] Rejeter matrice partielle, référence vide et dérive du set canonique.

### Task 2: Génération déterministe

- [x] Générer un JSON machine-readable et un Markdown humain.
- [x] Ajouter `--check` pour détecter tout artefact stale.
- [x] Vérifier que toutes les références de fichiers promues existent.

### Task 3: Vérité des surfaces hors cutline

- [x] Marquer held items comme extension avancée hors cutline MVP.
- [x] Déclarer nature/IV/EV et Struggle différés jusqu’à RM-028/RM-029.
- [x] Conserver `noLegalChoice` honnête tant que Struggle n’est pas livré.

### Task 4: Validation et clôture

- [x] Tests ciblés core/editor et générateur `--check`.
- [x] Analyses package-scoped et smoke battle.
- [x] Evidence Pack FG-053/180/183.
- [x] Commit isolé et état Git final.
```
