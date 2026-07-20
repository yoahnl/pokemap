# NSC-53 — Simulateur d’état du monde — Evidence Pack

## Résumé exécutif

NSC-53 ajoute une simulation pure, immuable et sérialisable de l’état narratif du monde. Elle explique les World Rules applicables, leur ordre, la règle gagnante et les effets visibles sur les entités, dialogues, Map Events legacy et Events V2. Le workspace World Rules expose cette simulation dans une troisième colonne no-code avec overrides de Facts typés, presets avant/après Step et hypothèses victoire/défaite, sans modifier le projet. Une fixture runtime prouve la parité avec le hook de projection réellement utilisé en jeu.

**Verdict proposé : DONE.**

## Scope et audit initial

- État Git initial : branche `main`, HEAD `e6a21655b feat(narrative): make world rules project wide`, arbre propre après NSC-52.
- Contrats inspectés : `GameState`, `NarrativeFactRuntimeState`, `WorldRuleProjection`, diagnostics World Rules, hook runtime et workspace Facts/World Rules.
- Risques identifiés : simulation qui muterait le projet, ordre de priorité divergent du runtime, cible supprimée silencieuse, confusion Event legacy/V2, snapshot non reproductible et UI hors design system.
- Non-objectifs : le preset d’outcome ne déclenche pas artificiellement de World Rule, car le modèle de source World Rule ne consomme pas directement un outcome ; l’hypothèse reste néanmoins sérialisée et visible pour reproduction.

## Passes locales équivalentes aux sub-agents

Les sub-agents sont interdits par le mode de collaboration actif ; les passes demandées par `codex_rule.md` ont donc été réalisées localement et séparément.

| Passe | Verdict |
|---|---|
| Audit / Architecture | PASS — calcul et snapshot dans map_core, UI dans map_editor, parité prouvée contre map_runtime sans dépendance inverse. |
| Implémentation | PASS — aucun appel d’écriture ; toutes les collections exposées sont immuables et les namespaces Event sont explicites. |
| Tests | PASS — 21 tests core, 17 runtime et 7 editor pertinents sont verts. |
| Build / Validation | PASS avec réserve connue — core/runtime sans issue ; editor conserve uniquement 11 warnings préexistants dans Dialogue Studio. |
| Critique finale | PASS — golden régénéré puis inspecté ; la troisième colonne reste lisible à 1440×900 et suit le design system. |

## Inventaire complet des fichiers modifiés

| Fichier | Zone précise et impact |
|---|---|
| `packages/map_core/lib/map_core.dart` | Export public du simulateur. |
| `packages/map_core/lib/src/read_models/narrative_world_state_simulation.dart` | Snapshot JSON immuable, traces, états projetés, diagnostics, ordre et winners. |
| `packages/map_core/test/narrative_world_state_simulation_test.dart` | Round-trip, immutabilité, defaults absents, conflits, priorité et cible supprimée. |
| `packages/map_editor/lib/src/ui/canvas/facts_world_rules/world_state_simulator_panel.dart` | Nouveau panneau no-code local pour Facts typés, Steps, outcomes, états et explications. |
| `packages/map_editor/lib/src/ui/canvas/facts_world_rules/facts_world_rules_workspace.dart` | Intégration du simulateur comme troisième colonne World Rules avec le snapshot multi-map. |
| `packages/map_editor/test/world_state_simulator_panel_test.dart` | Interaction Fact/Step/outcome et preuve de non-mutation du manifeste. |
| `packages/map_runtime/test/narrative_world_state_simulation_parity_test.dart` | Parité du rapport pur avec le hook runtime sur entité, Map Event et Event V2. |
| `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_35_facts_world_rules_manager_ui_v0.png` | Golden actualisé et inspecté pour la colonne simulateur. |
| `docs/superpowers/plans/2026-07-20-nsc-53-world-state-simulator.md` | Micro-plan TDD et gate du lot. |
| `reports/narrativeStudio/completion/nsc_53_world_state_simulator_evidence_pack.md` | Présent rapport de clôture. |

## Décisions et zones modifiées

- Le snapshot contient un `GameState` complet et les outcomes hypothétiques, avec codec JSON et égalité structurelle.
- La projection réutilise `projectWorldRuleEffects` : elle ne réimplémente ni les prédicats ni le tri runtime.
- Le winner est le dernier effet après tri canonique ; une trace explique règle désactivée, source non satisfaite, règle remplacée, winner ou diagnostic bloquant.
- Les entités montrent visibilité et dialogue effectif ; les Events montrent actif/désactivé/caché, avec legacy et V2 séparés.
- Les Facts bool se modifient par toggle ; int/string par champ tokenisé. Les Steps et outcomes sont des presets locaux.
- Tous les composants structurants viennent du design system PokeMap et toutes les couleurs viennent du thème.

## Tests créés ou modifiés

- Positifs : round-trip snapshot, priorité supérieure gagnante, contributeurs, presets Fact/Step/outcome, parité runtime.
- Négatifs : Fact absent, effets opposés de même priorité, target supprimée.
- Non-régression : Map Events legacy et Events V2 conservent leurs identités distinctes.
- Visuel : golden régénéré avec `--update-goldens`, ouvert et contrôlé manuellement.

## Commandes et résultats exacts

### Core

```text
cd packages/map_core
/opt/homebrew/bin/dart test test/narrative_world_state_simulation_test.dart test/world_rule_projection_test.dart test/world_rule_diagnostics_test.dart
All tests passed! (+21)
/opt/homebrew/bin/dart analyze
No issues found!
```

### Runtime

```text
cd packages/map_runtime
/opt/homebrew/bin/flutter test test/narrative_world_state_simulation_parity_test.dart test/world_rules_runtime_projection_hook_test.dart
All tests passed! (+17)
/opt/homebrew/bin/flutter analyze
No issues found! (ran in 5.1s)
```

### Editor

```text
cd packages/map_editor
/opt/homebrew/bin/flutter test test/world_state_simulator_panel_test.dart test/facts_world_rules_manager_test.dart
All tests passed! (+7)
/opt/homebrew/bin/flutter analyze
11 issues found — 11 warnings préexistants, tous dans lib/src/ui/canvas/dialogue_studio/dialogs/dialogue_studio_dialogs.dart ; aucune issue NSC-53.
```

### Golden et hygiène

```text
cd packages/map_editor
/opt/homebrew/bin/flutter test --update-goldens test/facts_world_rules_manager_test.dart
All tests passed! (+6)
/opt/homebrew/bin/flutter test test/facts_world_rules_manager_test.dart test/world_state_simulator_panel_test.dart
All tests passed! (+7)

git diff --check
aucune sortie
```

Le premier lancement du test widget a échoué comme prévu en phase rouge car le panneau n’existait pas. Un premier appel de `dart format` depuis le sous-dossier editor a signalé des chemins inexistants sans modifier de fichier ; le formatage ciblé correct a ensuite été exécuté depuis la racine.

## État Git final avant commit

- Seuls les fichiers NSC-53 listés ci-dessus sont modifiés ou créés.
- Aucun fichier de `test/failures`, `build/` ou `.dart_tool/` n’est inclus.
- `git diff --check` est propre.

## Limites conservées et risques

- Les outcomes victoire/défaite sont des hypothèses sérialisées destinées à la comparaison et à la reproduction. Ils n’affectent une projection que lorsqu’un futur contrat de source les consommera explicitement.
- La simulation couvre les effets World Rule aujourd’hui supportés ; elle ne prétend pas être le solveur de reachability corrélé de NSC-54.
- Le panneau est volontairement dense et scrollable ; le golden confirme la lisibilité du haut de la colonne à 1440×900.
- Les 11 warnings Dialogue Studio restent hors scope et préexistants.

## Auto-critique

Le rapport calcule les winners à partir de la projection canonique mais expose encore ses propres DTO de présentation ; les tests de parité réduisent le risque de divergence. Les presets int/string s’appliquent à la soumission plutôt qu’à chaque frappe, ce qui évite des snapshots invalides mais mérite une aide UI plus explicite à terme. L’issue hypothétique est honnêtement visible sans simuler un backend inexistant.

## Prochaine étape

NSC-54 — solveur symbolique narratif corrélé avec pass/fail/indeterminate, provenance et budget.

## Contenu complet des fichiers créés

Le présent rapport ne peut pas s’inclure récursivement ; tous les autres fichiers créés par le lot sont reproduits ci-dessous.

<details>
<summary>Contenu complet — docs/superpowers/plans/2026-07-20-nsc-53-world-state-simulator.md</summary>

```markdown
# NSC-53 — Simulateur d’état du monde

## Objectif

Prévisualiser, depuis un snapshot isolé et sérialisable, les effets combinés des Facts, Steps et World Rules sans lancer le runtime ni modifier le projet.

## Frontières

- La simulation pure et ses explications appartiennent à `map_core`.
- Le panneau editor ne conserve qu’un snapshot local éphémère.
- Les Events legacy et V2 restent des namespaces distincts.
- Les presets d’issue enregistrent une hypothèse reproductible ; ils ne prétendent pas produire un effet World Rule lorsqu’aucune source de règle ne consomme les outcomes.
- La parité porte sur la projection effectivement supportée par le hook runtime.

## Plan TDD

1. Prouver le round-trip et l’immutabilité du snapshot.
2. Tester règles applicables, ordre, gagnants et contributeurs.
3. Tester Fact absent, priorité concurrente et cible supprimée.
4. Comparer le rapport pur au hook runtime sur la même fixture.
5. Ajouter le panneau no-code Facts/Steps/issues et ses états expliqués.
6. Intégrer la troisième colonne au workspace World Rules.
7. Régénérer, inspecter puis verrouiller le golden et le gate multi-package.

## Gate

Le même snapshot produit un résultat explicable dans `map_core`, le panneau editor et la projection runtime, sans aucune écriture sur le projet.
```
</details>

<details>
<summary>Contenu complet — packages/map_core/lib/src/read_models/narrative_world_state_simulation.dart</summary>

```dart
import '../diagnostics/world_rule_diagnostics.dart';
import '../models/game_state.dart';
import '../models/map_data.dart';
import '../models/narrative_event_definition.dart';
import '../models/narrative_event_source_ref.dart';
import '../models/project_manifest.dart';
import '../models/world_rule.dart';
import '../projection/world_rule_projection.dart';

/// Serializable, immutable input used to reproduce a world-state preview.
final class NarrativeWorldStateSimulationInput {
  NarrativeWorldStateSimulationInput({
    required this.gameState,
    List<NarrativeOutcomeRef> hypotheticalOutcomes =
        const <NarrativeOutcomeRef>[],
  }) : hypotheticalOutcomes = List.unmodifiable(hypotheticalOutcomes);

  factory NarrativeWorldStateSimulationInput.fromJson(
    Map<String, dynamic> json,
  ) {
    final gameState = json['gameState'];
    final outcomes = json['hypotheticalOutcomes'];
    if (gameState is! Map) {
      throw const FormatException('Simulation input requires gameState.');
    }
    if (outcomes is! List) {
      throw const FormatException(
        'Simulation input requires hypotheticalOutcomes.',
      );
    }
    return NarrativeWorldStateSimulationInput(
      gameState: GameState.fromJson(Map<String, dynamic>.from(gameState)),
      hypotheticalOutcomes: [
        for (final outcome in outcomes) NarrativeOutcomeRef.fromJson(outcome),
      ],
    );
  }

  final GameState gameState;
  final List<NarrativeOutcomeRef> hypotheticalOutcomes;

  Map<String, dynamic> toJson() => {
        'gameState': gameState.toJson(),
        'hypotheticalOutcomes': [
          for (final outcome in hypotheticalOutcomes) outcome.toJson(),
        ],
      };

  NarrativeWorldStateSimulationInput copyWith({
    GameState? gameState,
    List<NarrativeOutcomeRef>? hypotheticalOutcomes,
  }) =>
      NarrativeWorldStateSimulationInput(
        gameState: gameState ?? this.gameState,
        hypotheticalOutcomes: hypotheticalOutcomes ?? this.hypotheticalOutcomes,
      );

  NarrativeWorldStateSimulationInput withStepCompletion(
    String stepId, {
    required bool completed,
  }) {
    final normalized = stepId.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(stepId, 'stepId', 'must not be empty');
    }
    final completedIds = gameState.progression.completedStepIds.toSet();
    if (completed) {
      completedIds.add(normalized);
    } else {
      completedIds.remove(normalized);
    }
    final ordered = completedIds.toList()..sort();
    return copyWith(
      gameState: gameState.copyWith(
        progression: gameState.progression.copyWith(
          completedStepIds: ordered,
        ),
      ),
    );
  }

  NarrativeWorldStateSimulationInput withOutcome(NarrativeOutcomeRef outcome) {
    return copyWith(
      hypotheticalOutcomes: [...hypotheticalOutcomes, outcome],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeWorldStateSimulationInput &&
          other.gameState == gameState &&
          _listEquals(other.hypotheticalOutcomes, hypotheticalOutcomes);

  @override
  int get hashCode => Object.hash(
        gameState,
        Object.hashAll(hypotheticalOutcomes),
      );
}

final class NarrativeWorldRuleSimulationTrace {
  const NarrativeWorldRuleSimulationTrace({
    required this.ruleId,
    required this.label,
    required this.priority,
    required this.targetKey,
    required this.effectKind,
    required this.applicable,
    required this.winner,
    required this.explanation,
  });

  final String ruleId;
  final String label;
  final int priority;
  final String targetKey;
  final WorldRuleEffectKind effectKind;
  final bool applicable;
  final bool winner;
  final String explanation;
}

final class NarrativeWorldEntitySimulationState {
  NarrativeWorldEntitySimulationState({
    required this.mapId,
    required this.entityId,
    required this.label,
    required this.visible,
    required this.dialogueId,
    required List<String> contributorRuleIds,
  }) : contributorRuleIds = List.unmodifiable(contributorRuleIds);

  final String mapId;
  final String entityId;
  final String label;
  final bool visible;
  final String? dialogueId;
  final List<String> contributorRuleIds;
}

final class NarrativeWorldMapEventSimulationState {
  NarrativeWorldMapEventSimulationState({
    required this.mapId,
    required this.eventId,
    required this.label,
    required this.active,
    required this.hidden,
    required List<String> contributorRuleIds,
  }) : contributorRuleIds = List.unmodifiable(contributorRuleIds);

  final String mapId;
  final String eventId;
  final String label;
  final bool active;
  final bool hidden;
  final List<String> contributorRuleIds;
}

final class NarrativeWorldEventV2SimulationState {
  NarrativeWorldEventV2SimulationState({
    required this.eventId,
    required this.label,
    required this.mapId,
    required this.configured,
    required this.active,
    required this.hidden,
    required List<String> contributorRuleIds,
  }) : contributorRuleIds = List.unmodifiable(contributorRuleIds);

  final String eventId;
  final String label;
  final String? mapId;
  final bool configured;
  final bool active;
  final bool hidden;
  final List<String> contributorRuleIds;
}

final class NarrativeWorldStateSimulationReport {
  NarrativeWorldStateSimulationReport({
    required this.input,
    required List<NarrativeWorldRuleSimulationTrace> rules,
    required List<NarrativeWorldEntitySimulationState> entityStates,
    required List<NarrativeWorldMapEventSimulationState> mapEventStates,
    required List<NarrativeWorldEventV2SimulationState> narrativeEventStates,
    required List<WorldRuleDiagnostic> diagnostics,
  })  : rules = List.unmodifiable(rules),
        entityStates = List.unmodifiable(entityStates),
        mapEventStates = List.unmodifiable(mapEventStates),
        narrativeEventStates = List.unmodifiable(narrativeEventStates),
        diagnostics = List.unmodifiable(diagnostics);

  final NarrativeWorldStateSimulationInput input;
  final List<NarrativeWorldRuleSimulationTrace> rules;
  final List<NarrativeWorldEntitySimulationState> entityStates;
  final List<NarrativeWorldMapEventSimulationState> mapEventStates;
  final List<NarrativeWorldEventV2SimulationState> narrativeEventStates;
  final List<WorldRuleDiagnostic> diagnostics;

  List<NarrativeWorldRuleSimulationTrace> get applicableRules =>
      List.unmodifiable(rules.where((rule) => rule.applicable));

  List<NarrativeWorldRuleSimulationTrace> get winnerRules =>
      List.unmodifiable(rules.where((rule) => rule.winner));
}

NarrativeWorldStateSimulationReport simulateNarrativeWorldState({
  required ProjectManifest project,
  required List<MapData> maps,
  required NarrativeWorldStateSimulationInput input,
}) {
  final diagnostics = diagnoseWorldRules(project, maps: maps).diagnostics;
  final diagnosticsByRuleId = <String, List<WorldRuleDiagnostic>>{};
  for (final diagnostic in diagnostics) {
    diagnosticsByRuleId
        .putIfAbsent(diagnostic.ruleId, () => <WorldRuleDiagnostic>[])
        .add(diagnostic);
  }
  final effects = projectWorldRuleEffects(
    project,
    input.gameState,
    maps: maps,
  );
  final effectsByTarget = <String, List<WorldRuleResolvedEffect>>{};
  for (final effect in effects) {
    effectsByTarget
        .putIfAbsent(
            _targetKey(effect.target), () => <WorldRuleResolvedEffect>[])
        .add(effect);
  }
  final winnerRuleIds = <String>{
    for (final effects in effectsByTarget.values)
      if (effects.isNotEmpty) effects.last.ruleId,
  };
  final applicableRuleIds = effects.map((effect) => effect.ruleId).toSet();
  final orderedRules = project.worldRules.toList()
    ..sort((left, right) {
      final priority = left.priority.compareTo(right.priority);
      return priority != 0 ? priority : left.id.compareTo(right.id);
    });
  final traces = <NarrativeWorldRuleSimulationTrace>[
    for (final rule in orderedRules)
      NarrativeWorldRuleSimulationTrace(
        ruleId: rule.id,
        label: rule.label,
        priority: rule.priority,
        targetKey: _targetKey(rule.target),
        effectKind: rule.effect.kind,
        applicable: applicableRuleIds.contains(rule.id),
        winner: winnerRuleIds.contains(rule.id),
        explanation: _ruleExplanation(
          rule,
          applicable: applicableRuleIds.contains(rule.id),
          winner: winnerRuleIds.contains(rule.id),
          diagnostics: diagnosticsByRuleId[rule.id] ?? const [],
        ),
      ),
  ];

  final entityStates = <NarrativeWorldEntitySimulationState>[];
  final mapEventStates = <NarrativeWorldMapEventSimulationState>[];
  for (final map in maps) {
    for (final entity in map.entities) {
      final entityEffects = effectsByTarget[_targetKey(
            WorldRuleTarget(
              kind: WorldRuleTargetKind.mapEntity,
              mapId: map.id,
              entityId: entity.id,
            ),
          )] ??
          const <WorldRuleResolvedEffect>[];
      final dialogueEffects = effectsByTarget[_targetKey(
            WorldRuleTarget(
              kind: WorldRuleTargetKind.npcDialogue,
              mapId: map.id,
              entityId: entity.id,
            ),
          )] ??
          const <WorldRuleResolvedEffect>[];
      final entityWinner = entityEffects.lastOrNull;
      final dialogueWinner = dialogueEffects.lastOrNull;
      final visible = switch (entityWinner?.effect.kind) {
        WorldRuleEffectKind.entityHidden => false,
        WorldRuleEffectKind.entityVisible => true,
        _ => true,
      };
      final dialogueId =
          dialogueWinner?.effect.dialogueId ?? entity.npc?.dialogue?.dialogueId;
      entityStates.add(
        NarrativeWorldEntitySimulationState(
          mapId: map.id,
          entityId: entity.id,
          label: entity.name.trim().isEmpty ? entity.id : entity.name,
          visible: visible,
          dialogueId: dialogueId,
          contributorRuleIds: {
            for (final effect in entityEffects) effect.ruleId,
            for (final effect in dialogueEffects) effect.ruleId,
          }.toList()
            ..sort(),
        ),
      );
    }
    for (final event in map.events) {
      final eventEffects = effectsByTarget[_targetKey(
            WorldRuleTarget(
              kind: WorldRuleTargetKind.mapEvent,
              mapId: map.id,
              eventId: event.id,
            ),
          )] ??
          const <WorldRuleResolvedEffect>[];
      final state = _eventState(
        enabled: true,
        effect: eventEffects.lastOrNull?.effect.kind,
      );
      mapEventStates.add(
        NarrativeWorldMapEventSimulationState(
          mapId: map.id,
          eventId: event.id,
          label: event.title.trim().isEmpty ? event.id : event.title,
          active: state.active,
          hidden: state.hidden,
          contributorRuleIds: [
            for (final effect in eventEffects) effect.ruleId,
          ],
        ),
      );
    }
  }

  final narrativeEventStates = <NarrativeWorldEventV2SimulationState>[];
  for (final record
      in project.eventRegistry?.records ?? const <NarrativeEventRecord>[]) {
    final eventEffects = effectsByTarget[_targetKey(
          WorldRuleTarget(
            kind: WorldRuleTargetKind.narrativeEvent,
            mapId: '',
            eventId: record.id,
          ),
        )] ??
        const <WorldRuleResolvedEffect>[];
    record.when(
      draft: (draft) {
        narrativeEventStates.add(
          NarrativeWorldEventV2SimulationState(
            eventId: draft.id,
            label: draft.name,
            mapId: _sourceMapId(draft.source),
            configured: false,
            active: false,
            hidden: false,
            contributorRuleIds: const [],
          ),
        );
      },
      configured: (definition, enabled) {
        final state = _eventState(
          enabled: enabled,
          effect: eventEffects.lastOrNull?.effect.kind,
        );
        narrativeEventStates.add(
          NarrativeWorldEventV2SimulationState(
            eventId: definition.id,
            label: definition.name,
            mapId: _sourceMapId(definition.source),
            configured: true,
            active: state.active,
            hidden: state.hidden,
            contributorRuleIds: [
              for (final effect in eventEffects) effect.ruleId,
            ],
          ),
        );
      },
    );
  }

  return NarrativeWorldStateSimulationReport(
    input: input,
    rules: traces,
    entityStates: entityStates,
    mapEventStates: mapEventStates,
    narrativeEventStates: narrativeEventStates,
    diagnostics: diagnostics,
  );
}

String _ruleExplanation(
  WorldRuleDefinition rule, {
  required bool applicable,
  required bool winner,
  required List<WorldRuleDiagnostic> diagnostics,
}) {
  if (!rule.enabled) return 'Règle désactivée.';
  final blocking = diagnostics.where(
    (diagnostic) => diagnostic.severity == WorldRuleDiagnosticSeverity.error,
  );
  if (blocking.isNotEmpty) return blocking.first.message;
  if (!applicable) return 'La source ne correspond pas au snapshot.';
  if (!winner) return 'Applicable, remplacée par une priorité supérieure.';
  return 'Applicable et gagnante pour cette cible.';
}

String _targetKey(WorldRuleTarget target) => switch (target.kind) {
      WorldRuleTargetKind.mapEntity =>
        '${target.mapId}:entity:${target.entityId ?? ''}',
      WorldRuleTargetKind.npcDialogue =>
        '${target.mapId}:npcDialogue:${target.entityId ?? ''}',
      WorldRuleTargetKind.mapEvent =>
        '${target.mapId}:mapEvent:${target.eventId ?? ''}',
      WorldRuleTargetKind.narrativeEvent =>
        'narrativeEvent:${target.eventId ?? ''}',
    };

({bool active, bool hidden}) _eventState({
  required bool enabled,
  required WorldRuleEffectKind? effect,
}) =>
    switch (effect) {
      WorldRuleEffectKind.eventEnabled => (active: true, hidden: false),
      WorldRuleEffectKind.eventDisabled => (active: false, hidden: false),
      WorldRuleEffectKind.eventHidden => (active: false, hidden: true),
      _ => (active: enabled, hidden: false),
    };

String? _sourceMapId(NarrativeEventSourceRef? source) => source?.when(
      entityInteract: (mapId, _) => mapId,
      triggerEnter: (mapId, _) => mapId,
      mapEnter: (mapId) => mapId,
      outcomeReceived: (_) => null,
    );

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
```
</details>

<details>
<summary>Contenu complet — packages/map_core/test/narrative_world_state_simulation_test.dart</summary>

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _eventV2 = 'evt_019abcde-5300-7000-8000-000000000001';

void main() {
  group('Narrative world state simulation', () {
    test('round-trips an immutable reproducible input snapshot', () {
      final input = NarrativeWorldStateSimulationInput(
        gameState: GameState(
          saveId: 'simulation',
          narrativeFactRuntimeState: NarrativeFactRuntimeState(
            overridesByFactId: {'fact_gate': true},
          ),
          progression: const PlayerProgression(
            completedStepIds: ['step_port'],
          ),
        ),
        hypotheticalOutcomes: [
          NarrativeOutcomeRef(
            producerKind: NarrativeOutcomeProducerKind.battle,
            producerId: 'battle_rival',
            outcomeId: 'victory',
          ),
        ],
      );

      final decoded = NarrativeWorldStateSimulationInput.fromJson(
        input.toJson(),
      );

      expect(decoded, input);
      expect(
        () => decoded.hypotheticalOutcomes.clear(),
        throwsUnsupportedError,
      );
      expect(
        input
            .withStepCompletion('step_port', completed: false)
            .gameState
            .progression
            .completedStepIds,
        isNot(contains('step_port')),
      );
      expect(
        input
            .withOutcome(
              NarrativeOutcomeRef(
                producerKind: NarrativeOutcomeProducerKind.battle,
                producerId: 'battle_rival',
                outcomeId: 'defeat',
              ),
            )
            .hypotheticalOutcomes
            .last
            .outcomeId,
        'defeat',
      );
    });

    test('explains applicable rules, contributors and priority winners', () {
      final project = _project(
        worldRules: [
          _entityRule(
            id: 'rule_hide_low',
            effect: WorldRuleEffectKind.entityHidden,
            priority: 1,
          ),
          _entityRule(
            id: 'rule_show_high',
            effect: WorldRuleEffectKind.entityVisible,
            priority: 9,
          ),
          _mapEventRule(),
          _eventV2Rule(),
          _dialogueRule(),
        ],
      );
      final map = _map();
      final projectBefore = project.toJson();
      final mapBefore = map.toJson();

      final report = simulateNarrativeWorldState(
        project: project,
        maps: [map],
        input: _activeInput(),
      );

      final entity = report.entityStates.single;
      expect(entity.visible, isTrue);
      expect(entity.dialogueId, 'dialogue_after');
      expect(entity.contributorRuleIds,
          containsAll(['rule_hide_low', 'rule_show_high', 'rule_dialogue']));
      expect(report.mapEventStates.single.active, isFalse);
      expect(report.mapEventStates.single.hidden, isTrue);
      expect(report.narrativeEventStates.single.active, isFalse);
      expect(report.narrativeEventStates.single.hidden, isFalse);
      expect(
        report.rules
            .singleWhere((rule) => rule.ruleId == 'rule_show_high')
            .winner,
        isTrue,
      );
      expect(
        report.rules
            .singleWhere((rule) => rule.ruleId == 'rule_hide_low')
            .winner,
        isFalse,
      );
      expect(
        report.diagnostics.where(
          (diagnostic) =>
              diagnostic.severity == WorldRuleDiagnosticSeverity.error,
        ),
        isEmpty,
      );
      expect(project.toJson(), projectBefore);
      expect(map.toJson(), mapBefore);
    });

    test('keeps defaults when a Fact is absent', () {
      final report = simulateNarrativeWorldState(
        project: _project(
          facts: const [],
          worldRules: [
            _entityRule(
              id: 'rule_missing_fact',
              effect: WorldRuleEffectKind.entityHidden,
              priority: 0,
            ),
          ],
        ),
        maps: [_map()],
        input: NarrativeWorldStateSimulationInput(
          gameState: const GameState(saveId: 'absent'),
        ),
      );

      expect(report.entityStates.single.visible, isTrue);
      expect(report.applicableRules, isEmpty);
      expect(
        report.diagnostics.map((diagnostic) => diagnostic.code),
        contains(WorldRuleDiagnosticCode.worldRuleSourceUnknown),
      );
    });

    test('reports equal-priority conflicts and deleted targets', () {
      final project = _project(
        worldRules: [
          _entityRule(
            id: 'rule_visible',
            effect: WorldRuleEffectKind.entityVisible,
            priority: 4,
          ),
          _entityRule(
            id: 'rule_hidden',
            effect: WorldRuleEffectKind.entityHidden,
            priority: 4,
          ),
          WorldRuleDefinition(
            id: 'rule_deleted_target',
            label: 'Deleted target',
            source: _factSource(),
            target: const WorldRuleTarget(
              kind: WorldRuleTargetKind.mapEntity,
              mapId: 'map_port',
              entityId: 'npc_deleted',
            ),
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.entityHidden,
            ),
          ),
        ],
      );

      final report = simulateNarrativeWorldState(
        project: project,
        maps: [_map()],
        input: _activeInput(),
      );

      expect(
        report.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll([
          WorldRuleDiagnosticCode.worldRuleConflict,
          WorldRuleDiagnosticCode.worldRuleTargetUnknown,
        ]),
      );
      expect(report.applicableRules, isEmpty);
      expect(report.entityStates.single.visible, isTrue);
    });
  });
}

NarrativeWorldStateSimulationInput _activeInput() =>
    NarrativeWorldStateSimulationInput(
      gameState: GameState(
        saveId: 'active',
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: {'fact_gate': true},
        ),
      ),
    );

ProjectManifest _project({
  List<NarrativeFactDefinition>? facts,
  List<WorldRuleDefinition> worldRules = const [],
}) {
  return ProjectManifest(
    name: 'World simulation',
    maps: const [
      ProjectMapEntry(
        id: 'map_port',
        name: 'Port',
        relativePath: 'maps/port.json',
      ),
    ],
    tilesets: const [],
    facts: facts ??
        [NarrativeFactDefinition(id: 'fact_gate', label: 'Gate state')],
    dialogues: const [
      ProjectDialogueEntry(
        id: 'dialogue_after',
        name: 'After',
        relativePath: 'dialogues/after.yarn',
      ),
    ],
    scenes: [_scene()],
    worldRules: worldRules,
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: [
        NarrativeEventRecord.configuredStructurallyUnchecked(
          NarrativeEventDefinition(
            id: _eventV2,
            name: 'Port V2',
            source: NarrativeEventSourceRef.mapEnter('map_port'),
            conditions: const [],
            sceneId: 'scene_port',
            reusePolicy: NarrativeEventReusePolicy.reusable,
            priority: 0,
            order: 0,
          ),
          enabled: true,
        ),
      ],
      legacyClaims: const [],
    ),
  );
}

SceneAsset _scene() => SceneAsset(
      id: 'scene_port',
      name: 'Port',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [SceneNode(id: 'start', kind: SceneNodeKind.start)],
        edges: const [],
      ),
    );

MapData _map() => const MapData(
      id: 'map_port',
      name: 'Port',
      size: GridSize(width: 8, height: 8),
      entities: [
        MapEntity(
          id: 'npc_guard',
          name: 'Guard',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 2, y: 2),
          npc: MapEntityNpcData(
            displayName: 'Guard',
            dialogue: DialogueRef(dialogueId: 'dialogue_before'),
          ),
        ),
      ],
      events: [
        MapEventDefinition(
          id: 'event_gate',
          title: 'Gate',
          pages: [MapEventPage(pageNumber: 0)],
          position: EventPosition(layerId: 'events', x: 3, y: 3),
        ),
      ],
    );

WorldRuleSource _factSource() => const WorldRuleSource(
      kind: WorldRuleSourceKind.fact,
      sourceId: 'fact_gate',
      predicate: WorldRuleSourcePredicate.isTrue,
    );

WorldRuleDefinition _entityRule({
  required String id,
  required WorldRuleEffectKind effect,
  required int priority,
}) =>
    WorldRuleDefinition(
      id: id,
      label: id,
      source: _factSource(),
      target: const WorldRuleTarget(
        kind: WorldRuleTargetKind.mapEntity,
        mapId: 'map_port',
        entityId: 'npc_guard',
      ),
      effect: WorldRuleEffect(kind: effect),
      priority: priority,
    );

WorldRuleDefinition _dialogueRule() => WorldRuleDefinition(
      id: 'rule_dialogue',
      label: 'Dialogue',
      source: _factSource(),
      target: const WorldRuleTarget(
        kind: WorldRuleTargetKind.npcDialogue,
        mapId: 'map_port',
        entityId: 'npc_guard',
      ),
      effect: const WorldRuleEffect(
        kind: WorldRuleEffectKind.npcDialogueOverride,
        dialogueId: 'dialogue_after',
      ),
    );

WorldRuleDefinition _mapEventRule() => WorldRuleDefinition(
      id: 'rule_map_event',
      label: 'Map Event',
      source: _factSource(),
      target: const WorldRuleTarget(
        kind: WorldRuleTargetKind.mapEvent,
        mapId: 'map_port',
        eventId: 'event_gate',
      ),
      effect: const WorldRuleEffect(kind: WorldRuleEffectKind.eventHidden),
    );

WorldRuleDefinition _eventV2Rule() => WorldRuleDefinition(
      id: 'rule_event_v2',
      label: 'Event V2',
      source: _factSource(),
      target: const WorldRuleTarget(
        kind: WorldRuleTargetKind.narrativeEvent,
        mapId: 'map_port',
        eventId: _eventV2,
      ),
      effect: const WorldRuleEffect(kind: WorldRuleEffectKind.eventDisabled),
    );
```
</details>

<details>
<summary>Contenu complet — packages/map_editor/lib/src/ui/canvas/facts_world_rules/world_state_simulator_panel.dart</summary>

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

/// Read-only project preview driven by an isolated, reproducible game snapshot.
class WorldStateSimulatorPanel extends StatefulWidget {
  const WorldStateSimulatorPanel({
    super.key,
    required this.project,
    required this.maps,
  });

  final ProjectManifest project;
  final List<MapData> maps;

  @override
  State<WorldStateSimulatorPanel> createState() =>
      _WorldStateSimulatorPanelState();
}

class _WorldStateSimulatorPanelState extends State<WorldStateSimulatorPanel> {
  late NarrativeWorldStateSimulationInput _input = _initialInput();
  String? _selectedStepId;
  final Map<String, String> _factInputErrors = {};

  @override
  void initState() {
    super.initState();
    _selectedStepId = _steps.firstOrNull?.id;
  }

  @override
  void didUpdateWidget(covariant WorldStateSimulatorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project != widget.project || oldWidget.maps != widget.maps) {
      _input = _initialInput();
      _selectedStepId = _steps.firstOrNull?.id;
      _factInputErrors.clear();
    }
  }

  NarrativeWorldStateSimulationInput _initialInput() =>
      NarrativeWorldStateSimulationInput(
        gameState: const GameState(saveId: 'narrative-world-simulator'),
      );

  List<StorylineStep> get _steps => [
        for (final storyline in widget.project.storylines)
          for (final chapter in storyline.chapters) ...chapter.steps,
      ];

  @override
  Widget build(BuildContext context) {
    final report = simulateNarrativeWorldState(
      project: widget.project,
      maps: widget.maps,
      input: _input,
    );
    final selectedStep =
        _steps.where((step) => step.id == _selectedStepId).firstOrNull;

    return PokeMapPanel(
      key: const ValueKey('world-state-simulator-panel'),
      expandChild: true,
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PokeMapSectionHeader(
              title: 'Simulateur du monde',
              description:
                  'Prévisualisation locale : le projet n’est jamais modifié.',
              trailing: PokeMapBadge(
                label: '${report.winnerRules.length} effet(s)',
                variant: PokeMapBadgeVariant.info,
              ),
            ),
            const SizedBox(height: 8),
            _buildFacts(context),
            const SizedBox(height: 12),
            _buildPresets(context, selectedStep),
            const SizedBox(height: 12),
            _buildSummary(report),
            const SizedBox(height: 12),
            _buildEntities(report),
            const SizedBox(height: 12),
            _buildEvents(report),
            const SizedBox(height: 12),
            _buildRules(report),
            if (report.diagnostics.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDiagnostics(report),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFacts(BuildContext context) {
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PokeMapSectionHeader(
            title: 'Facts hypothétiques',
            description: 'Remplacez une valeur uniquement dans ce snapshot.',
          ),
          if (widget.project.facts.isEmpty)
            const _SimulatorHint('Aucun Fact défini dans le projet.')
          else
            for (final fact in widget.project.facts) ...[
              _buildFactControl(fact),
              if (fact != widget.project.facts.last) const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  Widget _buildFactControl(NarrativeFactDefinition fact) {
    final current =
        _input.gameState.narrativeFactRuntimeState.valueFor(fact.id) ??
            fact.initialValue;
    if (fact.valueKind == NarrativeValueKind.boolean) {
      return KeyedSubtree(
        key: ValueKey('world-state-fact-toggle-${fact.id}'),
        child: PokeMapToggleTile(
          label: fact.label,
          description: 'Bool · ${current.boolValue ? 'vrai' : 'faux'}',
          value: current.boolValue,
          onChanged: (value) {
            _setFactValue(fact.id, NarrativeValue.boolean(value));
          },
        ),
      );
    }

    return PokeMapTextField(
      label: '${fact.label} · ${fact.valueKind.wireName}',
      placeholder: _valueLabel(current),
      fieldKey: ValueKey('world-state-fact-value-${fact.id}'),
      keyboardType: fact.valueKind == NarrativeValueKind.integer
          ? TextInputType.number
          : TextInputType.text,
      errorText: _factInputErrors[fact.id],
      onSubmitted: (raw) => _submitFactValue(fact, raw),
    );
  }

  Widget _buildPresets(
    BuildContext context,
    StorylineStep? selectedStep,
  ) {
    final steps = _steps;
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PokeMapSectionHeader(
            title: 'Presets narratifs',
            description: 'Comparez rapidement un avant et un après.',
          ),
          if (steps.isNotEmpty) ...[
            PokeMapDropdownField<String>(
              label: 'Étape',
              value: selectedStep?.id ?? steps.first.id,
              items: [
                for (final step in steps)
                  PokeMapDropdownItem(value: step.id, label: step.title),
              ],
              onChanged: (stepId) => setState(() {
                _selectedStepId = stepId;
              }),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: PokeMapButton(
                    key: const ValueKey('world-state-before-step'),
                    variant: PokeMapButtonVariant.secondary,
                    size: PokeMapButtonSize.small,
                    onPressed: selectedStep == null
                        ? null
                        : () => _setStep(selectedStep.id, completed: false),
                    child: const Text('Avant'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PokeMapButton(
                    key: const ValueKey('world-state-after-step'),
                    variant: PokeMapButtonVariant.secondary,
                    size: PokeMapButtonSize.small,
                    onPressed: selectedStep == null
                        ? null
                        : () => _setStep(selectedStep.id, completed: true),
                    child: const Text('Après'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: PokeMapButton(
                  key: const ValueKey('world-state-victory-preset'),
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  leading: const Icon(CupertinoIcons.rosette),
                  onPressed: () => _setOutcome('victory'),
                  child: const Text('Victoire'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PokeMapButton(
                  key: const ValueKey('world-state-defeat-preset'),
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  leading: const Icon(CupertinoIcons.xmark_circle),
                  onPressed: () => _setOutcome('defeat'),
                  child: const Text('Défaite'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(NarrativeWorldStateSimulationReport report) {
    final outcome = _input.hypotheticalOutcomes.lastOrNull?.outcomeId;
    return PokeMapCard(
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          PokeMapBadge(
            label: 'Règles applicables : ${report.applicableRules.length}',
            variant: PokeMapBadgeVariant.info,
          ),
          PokeMapBadge(
            label:
                'Étapes terminées : ${_input.gameState.progression.completedStepIds.length}',
            variant: PokeMapBadgeVariant.narrative,
          ),
          PokeMapBadge(
            label: 'Issue hypothétique : ${_outcomeLabel(outcome)}',
            variant: outcome == null
                ? PokeMapBadgeVariant.neutral
                : PokeMapBadgeVariant.success,
          ),
          PokeMapBadge(
            label: 'Diagnostics : ${report.diagnostics.length}',
            variant: report.diagnostics.isEmpty
                ? PokeMapBadgeVariant.success
                : PokeMapBadgeVariant.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildEntities(NarrativeWorldStateSimulationReport report) {
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PokeMapSectionHeader(
            title: 'Entités et dialogues',
            description: 'État final et règles contributrices.',
          ),
          if (report.entityStates.isEmpty)
            const _SimulatorHint('Aucune entité dans le snapshot.')
          else
            for (final entity in report.entityStates)
              _SimulatorStateRow(
                title: entity.label,
                detail: entity.dialogueId == null
                    ? entity.mapId
                    : '${entity.mapId} · dialogue ${entity.dialogueId}',
                stateLabel: entity.visible ? 'Visible' : 'Cachée',
                variant: entity.visible
                    ? PokeMapBadgeVariant.success
                    : PokeMapBadgeVariant.warning,
                contributors: entity.contributorRuleIds,
              ),
        ],
      ),
    );
  }

  Widget _buildEvents(NarrativeWorldStateSimulationReport report) {
    final eventCount =
        report.mapEventStates.length + report.narrativeEventStates.length;
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PokeMapSectionHeader(
            title: 'Events',
            description: '$eventCount Event(s) projetés, legacy et V2 séparés.',
          ),
          if (eventCount == 0)
            const _SimulatorHint('Aucun Event dans le snapshot.'),
          for (final event in report.mapEventStates)
            _SimulatorStateRow(
              title: event.label,
              detail: '${event.mapId} · Event legacy',
              stateLabel: _eventStateLabel(event.active, event.hidden),
              variant: _eventVariant(event.active, event.hidden),
              contributors: event.contributorRuleIds,
            ),
          for (final event in report.narrativeEventStates)
            _SimulatorStateRow(
              title: event.label,
              detail: '${event.mapId ?? 'global'} · Event V2',
              stateLabel: event.configured
                  ? _eventStateLabel(event.active, event.hidden)
                  : 'Brouillon',
              variant: event.configured
                  ? _eventVariant(event.active, event.hidden)
                  : PokeMapBadgeVariant.neutral,
              contributors: event.contributorRuleIds,
            ),
        ],
      ),
    );
  }

  Widget _buildRules(NarrativeWorldStateSimulationReport report) {
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PokeMapSectionHeader(
            title: 'Explication des règles',
            description: 'Ordre croissant de priorité, puis gagnante finale.',
          ),
          if (report.rules.isEmpty)
            const _SimulatorHint('Aucune règle du monde.')
          else
            for (final rule in report.rules)
              _SimulatorStateRow(
                title: rule.label,
                detail: 'Priorité ${rule.priority} · ${rule.explanation}',
                stateLabel: rule.winner
                    ? 'Gagnante'
                    : rule.applicable
                        ? 'Remplacée'
                        : 'Inactive',
                variant: rule.winner
                    ? PokeMapBadgeVariant.success
                    : rule.applicable
                        ? PokeMapBadgeVariant.warning
                        : PokeMapBadgeVariant.neutral,
              ),
        ],
      ),
    );
  }

  Widget _buildDiagnostics(NarrativeWorldStateSimulationReport report) {
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PokeMapSectionHeader(
            title: 'Diagnostics',
            description: 'Les erreurs restent visibles dans la simulation.',
          ),
          for (final diagnostic in report.diagnostics)
            _SimulatorStateRow(
              title: diagnostic.ruleId,
              detail: diagnostic.message,
              stateLabel: _diagnosticLabel(diagnostic.severity),
              variant: _diagnosticVariant(diagnostic.severity),
            ),
        ],
      ),
    );
  }

  void _setFactValue(String factId, NarrativeValue value) {
    final current = _input.gameState.narrativeFactRuntimeState.valuesByFactId;
    setState(() {
      _factInputErrors.remove(factId);
      _input = _input.copyWith(
        gameState: _input.gameState.copyWith(
          narrativeFactRuntimeState: NarrativeFactRuntimeState.typed(
            valuesByFactId: {...current, factId: value},
          ),
        ),
      );
    });
  }

  void _submitFactValue(NarrativeFactDefinition fact, String raw) {
    if (fact.valueKind == NarrativeValueKind.integer) {
      final parsed = int.tryParse(raw.trim());
      if (parsed == null) {
        setState(() => _factInputErrors[fact.id] = 'Entier attendu.');
        return;
      }
      _setFactValue(fact.id, NarrativeValue.integer(parsed));
      return;
    }
    _setFactValue(fact.id, NarrativeValue.string(raw));
  }

  void _setStep(String stepId, {required bool completed}) {
    setState(() {
      _input = _input.withStepCompletion(stepId, completed: completed);
    });
  }

  void _setOutcome(String outcomeId) {
    setState(() {
      _input = _input.copyWith(
        hypotheticalOutcomes: [
          NarrativeOutcomeRef(
            producerKind: NarrativeOutcomeProducerKind.legacyScenario,
            producerId: 'world_state_simulator',
            outcomeId: outcomeId,
          ),
        ],
      );
    });
  }
}

class _SimulatorStateRow extends StatelessWidget {
  const _SimulatorStateRow({
    required this.title,
    required this.detail,
    required this.stateLabel,
    required this.variant,
    this.contributors = const <String>[],
  });

  final String title;
  final String detail;
  final String stateLabel;
  final PokeMapBadgeVariant variant;
  final List<String> contributors;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  contributors.isEmpty
                      ? detail
                      : '$detail · via ${contributors.join(', ')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                        fontSize: 10,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PokeMapBadge(label: stateLabel, variant: variant),
        ],
      ),
    );
  }
}

class _SimulatorHint extends StatelessWidget {
  const _SimulatorHint(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Text(
      message,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.textMuted,
          ),
    );
  }
}

String _valueLabel(NarrativeValue value) => switch (value.kind) {
      NarrativeValueKind.boolean => value.boolValue ? 'vrai' : 'faux',
      NarrativeValueKind.integer => '${value.intValue}',
      NarrativeValueKind.string => value.stringValue,
    };

String _outcomeLabel(String? outcome) => switch (outcome) {
      'victory' => 'victoire',
      'defeat' => 'défaite',
      _ => 'aucune',
    };

String _eventStateLabel(bool active, bool hidden) => hidden
    ? 'Caché'
    : active
        ? 'Actif'
        : 'Désactivé';

PokeMapBadgeVariant _eventVariant(bool active, bool hidden) => hidden
    ? PokeMapBadgeVariant.warning
    : active
        ? PokeMapBadgeVariant.success
        : PokeMapBadgeVariant.neutral;

String _diagnosticLabel(WorldRuleDiagnosticSeverity severity) =>
    switch (severity) {
      WorldRuleDiagnosticSeverity.error => 'Erreur',
      WorldRuleDiagnosticSeverity.warning => 'Attention',
      WorldRuleDiagnosticSeverity.info => 'Info',
    };

PokeMapBadgeVariant _diagnosticVariant(WorldRuleDiagnosticSeverity severity) =>
    switch (severity) {
      WorldRuleDiagnosticSeverity.error => PokeMapBadgeVariant.error,
      WorldRuleDiagnosticSeverity.warning => PokeMapBadgeVariant.warning,
      WorldRuleDiagnosticSeverity.info => PokeMapBadgeVariant.info,
    };
```
</details>

<details>
<summary>Contenu complet — packages/map_editor/test/world_state_simulator_panel_test.dart</summary>

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/facts_world_rules/world_state_simulator_panel.dart';

void main() {
  testWidgets(
      'simulates Facts, Steps and outcomes without mutating the project',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(520, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final project = _project();
    final projectBefore = project.toJson();

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        darkTheme: PokeMapTheme.dark(),
        themeMode: ThemeMode.dark,
        home: Scaffold(
          body: WorldStateSimulatorPanel(
            project: project,
            maps: const [_map],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('world-state-simulator-panel')),
      findsOneWidget,
    );
    expect(find.text('Règles applicables : 0'), findsOneWidget);
    expect(find.text('Visible'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('world-state-fact-toggle-fact_gate')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Règles applicables : 1'), findsOneWidget);
    expect(find.text('Cachée'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('world-state-after-step')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Étapes terminées : 1'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('world-state-before-step')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Étapes terminées : 0'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('world-state-victory-preset')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Issue hypothétique : victoire'), findsOneWidget);
    expect(project.toJson(), projectBefore);
  });
}

ProjectManifest _project() => ProjectManifest(
      name: 'Simulator UI',
      maps: const [
        ProjectMapEntry(
          id: 'map_port',
          name: 'Port',
          relativePath: 'maps/port.json',
        ),
      ],
      tilesets: const [],
      facts: [
        NarrativeFactDefinition(id: 'fact_gate', label: 'Gate closed'),
      ],
      storylines: [
        StorylineAsset(
          id: 'story_port',
          type: StorylineType.main,
          title: 'Port',
          chapters: [
            StorylineChapter(
              id: 'chapter_port',
              title: 'Port',
              order: 0,
              steps: [
                StorylineStep(
                  id: 'step_port',
                  title: 'Reach the port',
                  order: 0,
                ),
              ],
            ),
          ],
        ),
      ],
      worldRules: [
        WorldRuleDefinition(
          id: 'rule_hide_guard',
          label: 'Hide guard',
          source: const WorldRuleSource(
            kind: WorldRuleSourceKind.fact,
            sourceId: 'fact_gate',
            predicate: WorldRuleSourcePredicate.isTrue,
          ),
          target: const WorldRuleTarget(
            kind: WorldRuleTargetKind.mapEntity,
            mapId: 'map_port',
            entityId: 'npc_guard',
          ),
          effect: const WorldRuleEffect(
            kind: WorldRuleEffectKind.entityHidden,
          ),
        ),
      ],
    );

const _map = MapData(
  id: 'map_port',
  name: 'Port',
  size: GridSize(width: 6, height: 6),
  entities: [
    MapEntity(
      id: 'npc_guard',
      name: 'Guard',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 2, y: 2),
      npc: MapEntityNpcData(displayName: 'Guard'),
    ),
  ],
);
```
</details>

<details>
<summary>Contenu complet — packages/map_runtime/test/narrative_world_state_simulation_parity_test.dart</summary>

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

const _eventV2 = 'evt_019abcde-5300-7000-8000-000000000002';

void main() {
  test('pure world simulation matches the runtime projection hook', () {
    final fixture = _fixture();
    final input = NarrativeWorldStateSimulationInput(
      gameState: GameState(
        saveId: 'parity',
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {'fact_active': true},
        ),
      ),
    );

    final simulation = simulateNarrativeWorldState(
      project: fixture.project,
      maps: [fixture.map],
      input: input,
    );
    final runtime = const RuntimeWorldRuleProjectionHook().resolve(
      project: fixture.project,
      gameState: input.gameState,
      map: fixture.map,
    );

    expect(
      simulation.entityStates
          .where((state) => !state.visible)
          .map((state) => state.entityId)
          .toSet(),
      runtime.hiddenEntityIds,
    );
    expect(
      simulation.mapEventStates
          .where((state) => !state.active && !state.hidden)
          .map((state) => state.eventId)
          .toSet(),
      runtime.disabledEventIds,
    );
    expect(
      simulation.narrativeEventStates
          .where((state) => state.hidden)
          .map((state) => state.eventId)
          .toSet(),
      runtime.hiddenNarrativeEventIds,
    );
    expect(simulation.winnerRules, hasLength(3));
  });
}

({ProjectManifest project, MapData map}) _fixture() {
  const map = MapData(
    id: 'map_port',
    name: 'Port',
    size: GridSize(width: 5, height: 5),
    entities: [
      MapEntity(
        id: 'npc_guard',
        name: 'Guard',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 1, y: 1),
        npc: MapEntityNpcData(displayName: 'Guard'),
      ),
    ],
    events: [
      MapEventDefinition(
        id: 'event_gate',
        title: 'Gate',
        pages: [MapEventPage(pageNumber: 0)],
        position: EventPosition(layerId: 'events', x: 2, y: 2),
      ),
    ],
  );
  const source = WorldRuleSource(
    kind: WorldRuleSourceKind.fact,
    sourceId: 'fact_active',
    predicate: WorldRuleSourcePredicate.isTrue,
  );
  final project = ProjectManifest(
    name: 'Parity',
    maps: const [
      ProjectMapEntry(
        id: 'map_port',
        name: 'Port',
        relativePath: 'maps/port.json',
      ),
    ],
    tilesets: const [],
    facts: [NarrativeFactDefinition(id: 'fact_active', label: 'Active')],
    scenes: [
      SceneAsset(
        id: 'scene_port',
        name: 'Port',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [SceneNode(id: 'start', kind: SceneNodeKind.start)],
          edges: const [],
        ),
      ),
    ],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: [
        NarrativeEventRecord.configuredStructurallyUnchecked(
          NarrativeEventDefinition(
            id: _eventV2,
            name: 'V2',
            source: NarrativeEventSourceRef.mapEnter('map_port'),
            conditions: const [],
            sceneId: 'scene_port',
            reusePolicy: NarrativeEventReusePolicy.reusable,
            priority: 0,
            order: 0,
          ),
          enabled: true,
        ),
      ],
      legacyClaims: const [],
    ),
    worldRules: [
      WorldRuleDefinition(
        id: 'rule_hide_guard',
        label: 'Hide guard',
        source: source,
        target: const WorldRuleTarget(
          kind: WorldRuleTargetKind.mapEntity,
          mapId: 'map_port',
          entityId: 'npc_guard',
        ),
        effect: const WorldRuleEffect(
          kind: WorldRuleEffectKind.entityHidden,
        ),
      ),
      WorldRuleDefinition(
        id: 'rule_disable_gate',
        label: 'Disable gate',
        source: source,
        target: const WorldRuleTarget(
          kind: WorldRuleTargetKind.mapEvent,
          mapId: 'map_port',
          eventId: 'event_gate',
        ),
        effect: const WorldRuleEffect(
          kind: WorldRuleEffectKind.eventDisabled,
        ),
      ),
      WorldRuleDefinition(
        id: 'rule_hide_v2',
        label: 'Hide V2',
        source: source,
        target: const WorldRuleTarget(
          kind: WorldRuleTargetKind.narrativeEvent,
          mapId: 'map_port',
          eventId: _eventV2,
        ),
        effect: const WorldRuleEffect(
          kind: WorldRuleEffectKind.eventHidden,
        ),
      ),
    ],
  );
  return (project: project, map: map);
}
```
</details>
