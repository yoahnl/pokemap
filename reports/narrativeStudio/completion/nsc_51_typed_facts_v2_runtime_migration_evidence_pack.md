# NSC-51 — Facts typés V2 et migration runtime — Evidence Pack

## Résumé exécutif

Le lot NSC-51 ajoute un contrat fermé `NarrativeValue` (`bool`, `int`, `string`) et l’emploie de bout en bout dans le registre de Facts, New Game, Event V2, Scene, World Rules, Storyline `emitFact`, sauvegardes et runtime. Les projets booléens historiques conservent leur wire V1 et leur sémantique ; les nouveaux payloads mixtes utilisent un schéma V2 explicite. L’authoring editor reste no-code.

**Verdict proposé : DONE.**

## Scope et audit initial

- État Git initial : branche `main`, HEAD `f391e0476 feat(narrative): secure facts registry lifecycle`, arbre propre après NSC-50.
- Contrats inspectés : `NarrativeFactDefinition`, `NarrativeFactRuntimeState`, `ProjectNewGameConfig`, conditions Event/Scene/WorldRule, conséquences Scene, effets Storyline, `SaveData`, `NarrativeDependencyIndex`.
- Risques identifiés : coercion bool implicite, rupture du JSON historique, opérateurs invalides, changement de type sans preview, `existingPartyFactId` non bool, divergence editor/runtime et fusion accidentelle avec `ScriptCondition.variable*`.
- Limites maintenues : `ScriptCondition.variable*` et les flags Storyline restent un contrat legacy distinct ; aucune migration automatique de ces usages n’est introduite avant NSC-72.

## Passes locales équivalentes aux sub-agents

Les sub-agents sont interdits par le mode de collaboration actif ; les cinq passes exigées par `codex_rule.md` ont donc été exécutées localement et séparément.

| Passe | Verdict |
|---|---|
| Audit / Architecture | PASS — le modèle fermé et la compatibilité V1/V2 respectent les frontières map_core/map_gameplay/map_runtime/map_editor. |
| Implémentation | PASS — les consommateurs applicables écrivent/lisent des `NarrativeValue` sans JSON libre. |
| Tests | PASS ciblé — 341 tests core, 10 gameplay, 40 runtime et 12 tests editor pertinents sont verts. |
| Build / Validation | PASS avec réserve documentée — analyzers core/gameplay/runtime sans erreur ; editor conserve 11 warnings préexistants dans Dialogue Studio. |
| Critique finale | PASS — churn generated non pertinent retiré, golden intentionnel actualisé, aucune palette/ad hoc UI ajoutée. |

## Inventaire complet des fichiers modifiés

| Fichier | Zone, raison et impact |
|---|---|
| `packages/map_core/lib/map_core.dart` | Export public du nouveau contrat NarrativeValue. |
| `packages/map_core/lib/src/authoring/narrative_event_configuration_operations.dart` | Conditions Event V2 typées, dispatch/simulation canonique et validation sans coercition. |
| `packages/map_core/lib/src/authoring/narrative_event_configuration_validation.dart` | Conditions Event V2 typées, dispatch/simulation canonique et validation sans coercition. |
| `packages/map_core/lib/src/authoring/narrative_fact_authoring_operations.dart` | Définition/authoring/preview de changement de type et tests de non-régression bool. |
| `packages/map_core/lib/src/authoring/scene_authoring_operations.dart` | Conditions et conséquences Scene typées, authoring guidé, diagnostic et consommation runtime. |
| `packages/map_core/lib/src/authoring/storyline_authoring_operations.dart` | Effets emitFact typés et garde-fou empêchant la fusion avec les flags ScriptCondition legacy. |
| `packages/map_core/lib/src/authoring/storyline_progression_operations.dart` | Effets emitFact typés et garde-fou empêchant la fusion avec les flags ScriptCondition legacy. |
| `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart` | Conditions et conséquences Scene typées, authoring guidé, diagnostic et consommation runtime. |
| `packages/map_core/lib/src/diagnostics/world_rule_diagnostics.dart` | Prédicats World Rule typés, projection et diagnostics de compatibilité. |
| `packages/map_core/lib/src/models/narrative_event_definition.dart` | Conditions Event V2 typées, dispatch/simulation canonique et validation sans coercition. |
| `packages/map_core/lib/src/models/narrative_fact.dart` | Définition/authoring/preview de changement de type et tests de non-régression bool. |
| `packages/map_core/lib/src/models/narrative_fact_runtime_state.dart` | Migration de l’état, du resolver/writer et des preuves save/runtime vers des valeurs typées, avec compatibilité V1. |
| `packages/map_core/lib/src/models/project_new_game_config.dart` | Initial Facts V2 typés et restriction existingPartyFactId aux Facts bool. |
| `packages/map_core/lib/src/models/scene_asset.dart` | Conditions et conséquences Scene typées, authoring guidé, diagnostic et consommation runtime. |
| `packages/map_core/lib/src/models/scene_consequence.dart` | Conditions et conséquences Scene typées, authoring guidé, diagnostic et consommation runtime. |
| `packages/map_core/lib/src/models/storyline_asset.dart` | Effets emitFact typés et garde-fou empêchant la fusion avec les flags ScriptCondition legacy. |
| `packages/map_core/lib/src/models/world_rule.dart` | Prédicats World Rule typés, projection et diagnostics de compatibilité. |
| `packages/map_core/lib/src/operations/build_narrative_event_project_catalog.dart` | Conditions Event V2 typées, dispatch/simulation canonique et validation sans coercition. |
| `packages/map_core/lib/src/operations/narrative_event_dispatch_authority.dart` | Conditions Event V2 typées, dispatch/simulation canonique et validation sans coercition. |
| `packages/map_core/lib/src/operations/narrative_fact_runtime.dart` | Migration de l’état, du resolver/writer et des preuves save/runtime vers des valeurs typées, avec compatibilité V1. |
| `packages/map_core/lib/src/operations/narrative_project_validator.dart` | Validation projet/type et lecture fail-closed. |
| `packages/map_core/lib/src/projection/world_rule_projection.dart` | Prédicats World Rule typés, projection et diagnostics de compatibilité. |
| `packages/map_core/lib/src/read_models/facts_world_rules_manager_read_model.dart` | Prédicats World Rule typés, projection et diagnostics de compatibilité. |
| `packages/map_core/lib/src/read_models/narrative_dependency_index.dart` | Index des consommateurs conservé pour preview/blocage de changement de type. |
| `packages/map_core/lib/src/read_models/narrative_event_builder_project_read_model.dart` | Conditions Event V2 typées, dispatch/simulation canonique et validation sans coercition. |
| `packages/map_core/lib/src/read_models/narrative_event_validation_read_model.dart` | Conditions Event V2 typées, dispatch/simulation canonique et validation sans coercition. |
| `packages/map_core/lib/src/read_models/narrative_map_events_read_model.dart` | Adaptation ciblée au contrat Facts typés V2 et test associé. |
| `packages/map_core/lib/src/validation/validators.dart` | Validation projet/type et lecture fail-closed. |
| `packages/map_core/test/narrative_event_definition_test.dart` | Conditions Event V2 typées, dispatch/simulation canonique et validation sans coercition. |
| `packages/map_core/test/narrative_fact_authoring_operations_test.dart` | Définition/authoring/preview de changement de type et tests de non-régression bool. |
| `packages/map_core/test/narrative_fact_runtime_resolver_test.dart` | Migration de l’état, du resolver/writer et des preuves save/runtime vers des valeurs typées, avec compatibilité V1. |
| `packages/map_core/test/narrative_fact_runtime_state_test.dart` | Migration de l’état, du resolver/writer et des preuves save/runtime vers des valeurs typées, avec compatibilité V1. |
| `packages/map_core/test/narrative_fact_runtime_writer_test.dart` | Migration de l’état, du resolver/writer et des preuves save/runtime vers des valeurs typées, avec compatibilité V1. |
| `packages/map_core/test/narrative_fact_test.dart` | Définition/authoring/preview de changement de type et tests de non-régression bool. |
| `packages/map_core/test/project_manifest_narrative_canonical_json_test.dart` | Adaptation ciblée au contrat Facts typés V2 et test associé. |
| `packages/map_core/test/project_new_game_config_test.dart` | Initial Facts V2 typés et restriction existingPartyFactId aux Facts bool. |
| `packages/map_core/test/save_data_test.dart` | Preuve de round-trip SaveData des overrides typés. |
| `packages/map_core/test/scene_asset_json_test.dart` | Conditions et conséquences Scene typées, authoring guidé, diagnostic et consommation runtime. |
| `packages/map_core/test/scene_authoring_operations_test.dart` | Conditions et conséquences Scene typées, authoring guidé, diagnostic et consommation runtime. |
| `packages/map_core/test/scene_consequence_model_test.dart` | Conditions et conséquences Scene typées, authoring guidé, diagnostic et consommation runtime. |
| `packages/map_core/test/storyline_authoring_operations_test.dart` | Effets emitFact typés et garde-fou empêchant la fusion avec les flags ScriptCondition legacy. |
| `packages/map_core/test/storyline_progression_operations_test.dart` | Effets emitFact typés et garde-fou empêchant la fusion avec les flags ScriptCondition legacy. |
| `packages/map_core/test/support/f1_runtime_catalog_fixture.dart` | Fixture adaptée à l’évaluation typée sans changer le scénario bool historique. |
| `packages/map_core/test/world_rule_projection_test.dart` | Prédicats World Rule typés, projection et diagnostics de compatibilité. |
| `packages/map_core/test/world_rule_test.dart` | Prédicats World Rule typés, projection et diagnostics de compatibilité. |
| `packages/map_editor/lib/src/application/services/narrative_event_validation_coordinator.dart` | Conditions Event V2 typées, dispatch/simulation canonique et validation sans coercition. |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_authoring_sheets.dart` | Adaptation ciblée au contrat Facts typés V2 et test associé. |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_simulation_sheet.dart` | Adaptation ciblée au contrat Facts typés V2 et test associé. |
| `packages/map_editor/lib/src/ui/canvas/facts_world_rules/facts_world_rules_workspace.dart` | Prédicats World Rule typés, projection et diagnostics de compatibilité. |
| `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` | Branchement des callbacks typés dans le workspace. |
| `packages/map_editor/lib/src/ui/canvas/new_game/project_new_game_configuration_sheet.dart` | Initial Facts V2 typés et restriction existingPartyFactId aux Facts bool. |
| `packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart` | Conditions et conséquences Scene typées, authoring guidé, diagnostic et consommation runtime. |
| `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart` | Conditions et conséquences Scene typées, authoring guidé, diagnostic et consommation runtime. |
| `packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart` | Effets emitFact typés et garde-fou empêchant la fusion avec les flags ScriptCondition legacy. |
| `packages/map_editor/test/facts_world_rules_manager_test.dart` | Prédicats World Rule typés, projection et diagnostics de compatibilité. |
| `packages/map_gameplay/lib/src/new_game_state_builder.dart` | Initial Facts V2 typés et restriction existingPartyFactId aux Facts bool. |
| `packages/map_gameplay/test/narrative_event_condition_eligibility_test.dart` | Conditions Event V2 typées, dispatch/simulation canonique et validation sans coercition. |
| `packages/map_gameplay/test/project_new_game_state_builder_test.dart` | Initial Facts V2 typés et restriction existingPartyFactId aux Facts bool. |
| `packages/map_gameplay/test/support/f1_runtime_catalog_fixture.dart` | Fixture adaptée à l’évaluation typée sans changer le scénario bool historique. |
| `packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_write_result.dart` | Conditions et conséquences Scene typées, authoring guidé, diagnostic et consommation runtime. |
| `packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart` | Conditions et conséquences Scene typées, authoring guidé, diagnostic et consommation runtime. |
| `packages/map_runtime/lib/src/application/scene_runtime/scene_fact_condition_runtime_resolver.dart` | Conditions et conséquences Scene typées, authoring guidé, diagnostic et consommation runtime. |
| `packages/map_runtime/test/narrative_fact_runtime_cross_consumer_test.dart` | Migration de l’état, du resolver/writer et des preuves save/runtime vers des valeurs typées, avec compatibilité V1. |
| `packages/map_runtime/test/narrative_fact_runtime_save_load_test.dart` | Migration de l’état, du resolver/writer et des preuves save/runtime vers des valeurs typées, avec compatibilité V1. |
| `packages/map_runtime/test/scene_consequence_runtime_writer_test.dart` | Conditions et conséquences Scene typées, authoring guidé, diagnostic et consommation runtime. |
| `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_35_facts_world_rules_manager_ui_v0.png` | Conditions et conséquences Scene typées, authoring guidé, diagnostic et consommation runtime. |
| `packages/map_core/lib/src/models/narrative_value.dart` | Nouveau type fermé bool/int/string, opérateurs compatibles et bornes JSON exactes. |
| `packages/map_core/test/narrative_value_test.dart` | Adaptation ciblée au contrat Facts typés V2 et test associé. |
| `packages/map_editor/test/narrative_typed_fact_authoring_test.dart` | Tests widget no-code pour Fact int et condition Event typée. |

## Découpage précis des modifications

- Modèles : nouveau `NarrativeValue`, valeur initiale typée, codecs V1/V2 stricts, opérateurs par type.
- Authoring : add/update/duplicate typés, preview obligatoire et blocage des consommateurs incompatibles.
- Runtime : resolution et écriture atomiques, dispatch Event, conditions Scene, conséquences Scene, save/load.
- Projections/diagnostics : World Rules et Scene valident les types et échouent fermement sur les références invalides.
- Editor : pickers type/valeur/opérateur dans Facts, Rules, Event, Scene, New Game et simulateur Event ; `existingPartyFactId` ne propose que des bool.
- Storyline : `emitFact` transporte une valeur typée ; les conditions de Step restent volontairement des flags legacy bool.

## Tests créés ou modifiés

Couverture positive : bool/int/string, Unicode, bornes int, authoring UI, projection et runtime.
Couverture négative : opérateur incompatible, type mismatch, Fact inconnu/ambigu, int hors plage JSON, suppression/changement de type bloqué.
Non-régression : JSON bool V1 inchangé, simulateur Event bool historique inchangé, SaveData legacy sans subtree, flags Storyline non fusionnés.

## Commandes et résultats exacts

### Core ciblé

```text
cd packages/map_core
/opt/homebrew/bin/dart test test/narrative_value_test.dart test/narrative_fact_test.dart test/narrative_fact_runtime_state_test.dart test/narrative_fact_runtime_resolver_test.dart test/narrative_fact_runtime_writer_test.dart test/narrative_fact_authoring_operations_test.dart test/narrative_event_definition_test.dart test/narrative_event_registry_codec_test.dart test/narrative_event_dispatch_authority_test.dart test/scene_asset_json_test.dart test/scene_consequence_model_test.dart test/scene_authoring_operations_test.dart test/scene_diagnostics_test.dart test/storyline_authoring_operations_test.dart test/storyline_progression_operations_test.dart test/world_rule_test.dart test/world_rule_projection_test.dart test/world_rule_diagnostics_test.dart test/project_new_game_config_test.dart test/save_data_test.dart test/narrative_dependency_index_test.dart test/project_manifest_narrative_canonical_json_test.dart
All tests passed! (+341)
```

### Gameplay

```text
cd packages/map_gameplay
/opt/homebrew/bin/dart test test/narrative_event_condition_eligibility_test.dart test/project_new_game_state_builder_test.dart
All tests passed! (+10)
/opt/homebrew/bin/dart analyze
No issues found!
```

### Runtime

```text
cd packages/map_runtime
/opt/homebrew/bin/flutter test test/narrative_fact_runtime_cross_consumer_test.dart test/narrative_fact_runtime_save_load_test.dart test/scene_consequence_runtime_writer_test.dart
All tests passed! (+40)
/opt/homebrew/bin/flutter analyze
No issues found! (ran in 15.4s)
```

### Editor

```text
cd packages/map_editor
/opt/homebrew/bin/flutter test test/narrative_typed_fact_authoring_test.dart test/project_new_game_configuration_form_test.dart test/event_builder_v2_simulation_test.dart
All tests passed! (+6)
/opt/homebrew/bin/flutter test --update-goldens test/facts_world_rules_manager_test.dart
All tests passed! (+6)
/opt/homebrew/bin/flutter analyze
11 issues found — 11 warnings préexistants, tous dans lib/src/ui/canvas/dialogue_studio/dialogs/dialogue_studio_dialogs.dart ; aucune erreur et aucun warning dans les fichiers NSC-51.
```

### Build runner et analyse core

```text
cd packages/map_core
/opt/homebrew/bin/dart run build_runner build --delete-conflicting-outputs
Built with build_runner in 39s; wrote 33 outputs.
```

Inspection : deux fichiers generated suivis perdaient leurs méthodes JSON à cause du décalage SDK/analyzer signalé par le générateur. Ce churn destructif et hors scope a été retiré. Aucun generated diff n’est conservé.

```text
/opt/homebrew/bin/dart analyze
No issues found!
```

### Suite core complète

Une tentative de `dart test && dart analyze` sur tout map_core a été interrompue après 2 min 56 s : trois échecs sont apparus dans les très lourds tests de bordure/performance pendant que Flutter et build_runner tournaient en parallèle, hors périmètre narratif. La sortie PTY était tronquée avant les exceptions exactes ; le run n’est donc pas présenté comme vert. Tous les 22 fichiers de tests directement concernés ont ensuite été relancés isolément ensemble et sont verts (+341).

## État Git final avant commit

- Churn generated accidentel : retiré.
- Golden Facts/World Rules : modification intentionnelle.
- Aucun changement extérieur au lot détecté dans le diff final.
- Le présent Evidence Pack et le micro-plan font partie du commit NSC-51.

## Limites conservées et risques

- Pas de migration automatique des `ScriptCondition.variable*` ou flags Storyline vers les Facts typés.
- Le wire bool historique reste préféré tant qu’un état ne contient que des booléens.
- Les 11 warnings Dialogue Studio restent hors scope.
- Un futur changement de type d’un Fact référencé demeure conservativement bloqué plutôt que réécrit.

## Auto-critique

Le lot est large (schema + runtime + plusieurs surfaces UI), ce qui augmente le coût de review. La mitigation est une compatibilité bool testée, des codecs fermés, des erreurs atomiques, un golden révisé et une matrice cross-consumer. Le build runner local n’est pas aligné avec le SDK ; conserver ses suppressions aurait cassé les codecs JSON, d’où leur retrait explicite.

## Prochaine étape

NSC-52 — rendre les World Rules réellement projet-wide, avec snapshot multi-map, distinction `mapEvent` legacy / `narrativeEvent` V2 et projection runtime d’activation.

## Contenu complet des fichiers créés

Le présent rapport ne peut pas s’inclure récursivement ; tous les autres fichiers créés par le lot sont reproduits ci-dessous.

<details>
<summary>Contenu complet — docs/superpowers/plans/2026-07-20-nsc-51-typed-facts-v2-runtime-migration.md</summary>

```markdown
# NSC-51 — Facts typés V2 et migration runtime

## Objectif

Introduire une valeur narrative fermée bool/int/string partagée par le wire, le save, Event, Scene, Storyline, New Game et WorldRule, tout en conservant le comportement et le JSON booléens historiques.

## Frontières

- Le bool V1 reste lisible et produit le même sens sans migration manuelle.
- Les variables `ScriptCondition.variable*` restent un contrat legacy distinct.
- Les comparaisons invalides échouent fermé avant runtime.
- `existingPartyFactId` ne peut cibler qu'un Fact booléen.
- Aucun chargement projet/WorldRule cross-map de NSC-52 dans ce commit.

## Plan TDD

1. Tester NarrativeValue, opérateurs, bornes int et Unicode.
2. Tester codecs Fact/runtime/New Game/Event/Scene/Storyline/WorldRule/Save et compatibilité bool.
3. Migrer le resolver/writer runtime puis les consumers Event, Scene et WorldRule.
4. Bloquer les changements de type dont les usages sont incompatibles via l'index canonique.
5. Ajouter les pickers no-code de type, opérateur et valeur dans les surfaces principales.
6. Ajouter une matrice cross-consumer runtime et save/load.
7. Exécuter codegen package-scoped, tests, analyses et builds.

## Gate

Les trois types effectuent un round-trip Editor/save/runtime, les opérateurs sont validés par type et les projets bool V1 gardent leur comportement.
```
</details>
+
<details>
<summary>Contenu complet — packages/map_core/test/narrative_value_test.dart</summary>

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('NarrativeValue', () {
    test('round-trips the closed bool int and Unicode string values', () {
      final values = [
        const NarrativeValue.boolean(false),
        NarrativeValue.integer(42),
        const NarrativeValue.string('Brume 🌫️'),
      ];

      for (final value in values) {
        expect(
          NarrativeValue.fromJson(value.toJson(), declaredKind: value.kind),
          value,
        );
      }
    });

    test('exposes only operators compatible with each type', () {
      expect(
        NarrativeValueKind.boolean.compatibleOperators,
        [NarrativeFactOperator.equals, NarrativeFactOperator.notEquals],
      );
      expect(
        NarrativeValueKind.integer.compatibleOperators,
        containsAll([
          NarrativeFactOperator.equals,
          NarrativeFactOperator.greaterThan,
          NarrativeFactOperator.lessThanOrEqual,
        ]),
      );
      expect(
        NarrativeValueKind.string.compatibleOperators,
        [NarrativeFactOperator.equals, NarrativeFactOperator.notEquals],
      );
    });

    test('evaluates compatible comparisons and rejects type mismatch', () {
      expect(
        NarrativeValue.integer(7).matches(
          NarrativeFactOperator.greaterThan,
          NarrativeValue.integer(3),
        ),
        isTrue,
      );
      expect(
        const NarrativeValue.string('port').matches(
          NarrativeFactOperator.notEquals,
          const NarrativeValue.string('phare'),
        ),
        isTrue,
      );
      expect(
        () => const NarrativeValue.boolean(true).matches(
          NarrativeFactOperator.equals,
          NarrativeValue.integer(1),
        ),
        throwsArgumentError,
      );
      expect(
        () => const NarrativeValue.string('a').matches(
          NarrativeFactOperator.greaterThan,
          const NarrativeValue.string('b'),
        ),
        throwsArgumentError,
      );
    });

    test('rejects integers outside the exact JSON interoperability range', () {
      expect(
        () => NarrativeValue.integer(9007199254740992),
        throwsArgumentError,
      );
      expect(
        () => NarrativeValue.integer(-9007199254740992),
        throwsArgumentError,
      );
    });
  });
}
```
</details>



<details>
<summary>Contenu complet — packages/map_core/lib/src/models/narrative_value.dart</summary>

```dart
import 'package:meta/meta.dart' show immutable;

enum NarrativeValueKind {
  boolean('bool'),
  integer('int'),
  string('string');

  const NarrativeValueKind(this.wireName);

  final String wireName;

  List<NarrativeFactOperator> get compatibleOperators => switch (this) {
        NarrativeValueKind.boolean || NarrativeValueKind.string => const [
            NarrativeFactOperator.equals,
            NarrativeFactOperator.notEquals,
          ],
        NarrativeValueKind.integer => NarrativeFactOperator.values,
      };

  static NarrativeValueKind fromWireName(String value) => switch (value) {
        'bool' => NarrativeValueKind.boolean,
        'int' => NarrativeValueKind.integer,
        'string' => NarrativeValueKind.string,
        _ => throw FormatException('Unknown NarrativeValue kind "$value".'),
      };
}

enum NarrativeFactOperator {
  equals,
  notEquals,
  greaterThan,
  greaterThanOrEqual,
  lessThan,
  lessThanOrEqual,
}

@immutable
final class NarrativeValue {
  const NarrativeValue.boolean(bool value)
      : kind = NarrativeValueKind.boolean,
        _value = value;

  factory NarrativeValue.integer(int value) {
    const maxExactJsonInteger = 9007199254740991;
    if (value < -maxExactJsonInteger || value > maxExactJsonInteger) {
      throw ArgumentError.value(
        value,
        'value',
        'must remain within the exact interoperable JSON integer range',
      );
    }
    return NarrativeValue._(NarrativeValueKind.integer, value);
  }

  const NarrativeValue.string(String value)
      : kind = NarrativeValueKind.string,
        _value = value;

  const NarrativeValue._(this.kind, this._value);

  factory NarrativeValue.fromJson(
    Object? value, {
    NarrativeValueKind? declaredKind,
  }) {
    final inferredKind = switch (value) {
      bool _ => NarrativeValueKind.boolean,
      int _ => NarrativeValueKind.integer,
      String _ => NarrativeValueKind.string,
      _ => throw FormatException(
          'NarrativeValue must be a bool, exact integer or string.',
        ),
    };
    if (declaredKind != null && declaredKind != inferredKind) {
      throw FormatException(
        'NarrativeValue kind ${declaredKind.wireName} does not match '
        '${inferredKind.wireName}.',
      );
    }
    return switch (inferredKind) {
      NarrativeValueKind.boolean => NarrativeValue.boolean(value as bool),
      NarrativeValueKind.integer => NarrativeValue.integer(value as int),
      NarrativeValueKind.string => NarrativeValue.string(value as String),
    };
  }

  final NarrativeValueKind kind;
  final Object _value;

  Object toJson() => _value;

  bool get boolValue => kind == NarrativeValueKind.boolean
      ? _value as bool
      : throw StateError('NarrativeValue is ${kind.wireName}, not bool.');

  int get intValue => kind == NarrativeValueKind.integer
      ? _value as int
      : throw StateError('NarrativeValue is ${kind.wireName}, not int.');

  String get stringValue => kind == NarrativeValueKind.string
      ? _value as String
      : throw StateError('NarrativeValue is ${kind.wireName}, not string.');

  bool matches(NarrativeFactOperator operator, NarrativeValue expected) {
    if (kind != expected.kind) {
      throw ArgumentError(
        'Cannot compare ${kind.wireName} with ${expected.kind.wireName}.',
      );
    }
    if (!kind.compatibleOperators.contains(operator)) {
      throw ArgumentError.value(
        operator,
        'operator',
        'is not compatible with ${kind.wireName}',
      );
    }
    final comparison = kind == NarrativeValueKind.integer
        ? intValue.compareTo(expected.intValue)
        : 0;
    return switch (operator) {
      NarrativeFactOperator.equals => this == expected,
      NarrativeFactOperator.notEquals => this != expected,
      NarrativeFactOperator.greaterThan => comparison > 0,
      NarrativeFactOperator.greaterThanOrEqual => comparison >= 0,
      NarrativeFactOperator.lessThan => comparison < 0,
      NarrativeFactOperator.lessThanOrEqual => comparison <= 0,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeValue && other.kind == kind && other._value == _value;

  @override
  int get hashCode => Object.hash(kind, _value);

  @override
  String toString() => 'NarrativeValue.${kind.wireName}($_value)';
}
```
</details>


<details>
<summary>Contenu complet — packages/map_editor/test/narrative_typed_fact_authoring_test.dart</summary>

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_builder_v2_use_case.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/events_v2/event_builder_v2_authoring_sheets.dart';
import 'package:map_editor/src/ui/canvas/facts_world_rules/facts_world_rules_workspace.dart';

const _eventId = 'evt_019abcde-5100-7000-8000-000000000001';

void main() {
  testWidgets('Facts manager authors an integer without raw JSON',
      (tester) async {
    NarrativeValue? savedValue;
    final project = ProjectManifest(
      name: 'Typed Facts UI',
      maps: const [],
      tilesets: const [],
      facts: [
        NarrativeFactDefinition(
          id: 'fact_reputation',
          label: 'Réputation',
          initialValue: NarrativeValue.integer(3),
        ),
      ],
    );
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: FactsWorldRulesWorkspace(
            project: project,
            activeMap: null,
            initialMode: FactsWorldRulesWorkspaceMode.facts,
            onCreateFact: ({required label}) async => null,
            onDuplicateFact: ({required factId}) async => null,
            onUpdateFact: ({
              required factId,
              required label,
              required description,
              required category,
              required initialValue,
            }) async {
              savedValue = initialValue;
              return true;
            },
            onRemoveFact: ({required factId}) async => false,
            onCreateWorldRule: ({
              required label,
              required description,
              required enabled,
              required source,
              required target,
              required effect,
              required priority,
            }) async =>
                null,
            onUpdateWorldRule: ({
              required ruleId,
              required label,
              required description,
              required enabled,
              required source,
              required target,
              required effect,
              required priority,
            }) async =>
                false,
            onRemoveWorldRule: ({required ruleId}) async => false,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('fact-list-fact_reputation')));
    await tester.pump();
    expect(
        find.byKey(const ValueKey('fact-editor-type-picker')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('fact-editor-value-field')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('fact-editor-value-field')),
      '8',
    );
    await tester.tap(find.byKey(const ValueKey('fact-editor-save')));
    await tester.pump();

    expect(savedValue, NarrativeValue.integer(8));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Event sheet authors a typed comparison without manual IDs',
      (tester) async {
    NarrativeEventConditionExpression? saved;
    await tester.binding.setSurfaceSize(const Size(540, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: EventBuilderV2ConditionsSheet(
            snapshot: _snapshot(),
            onSubmit: (expression) async {
              saved = expression;
              return 'keep-open';
            },
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('event-builder-v2-fact-operator')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('event-builder-v2-fact-value')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('event-builder-v2-fact-operator')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('est supérieur ou égal à').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('event-builder-v2-fact-value')),
      '5',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('event-builder-v2-add-condition')).first,
    );
    await tester.tap(
      find.byKey(const ValueKey('event-builder-v2-add-condition')).first,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('event-builder-v2-save-conditions')).first,
    );
    await tester.tap(
      find.byKey(const ValueKey('event-builder-v2-save-conditions')).first,
    );
    await tester.pump();

    final condition = saved!.leaves.single;
    expect(
        condition.comparisonOperator, NarrativeFactOperator.greaterThanOrEqual);
    expect(condition.expectedNarrativeValue, NarrativeValue.integer(5));
    expect(tester.takeException(), isNull);
  });
}

NarrativeEventBuilderV2EditorSnapshot _snapshot() {
  final record = NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: _eventId,
      name: 'Typed Event',
      source: NarrativeEventSourceRef.mapEnter('map_port'),
      conditions: const [],
      sceneId: 'scene_port',
      reusePolicy: NarrativeEventReusePolicy.reusable,
      priority: 0,
      order: 0,
    ),
    enabled: false,
  );
  return NarrativeEventBuilderV2EditorSnapshot(
    projectRevision: 'typed-revision',
    record: record,
    spatialSources: const [],
    outcomeSources: const [],
    scenes: const [],
    facts: [
      NarrativeEventProjectFactEntry(
        NarrativeFactDefinition(
          id: 'fact_reputation',
          label: 'Réputation',
          initialValue: NarrativeValue.integer(0),
        ),
      ),
    ],
    events: [
      NarrativeEventProjectEventEntry(
        record: record,
        proposed: false,
        inDependencyCycle: false,
        contextuallyValid: true,
      ),
    ],
  );
}
```
</details>
