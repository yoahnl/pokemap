# NSC-43 — Expressions de conditions et politiques de réarmement Event

Date : 2026-07-20

Verdict : **DONE proposé pour NSC-43**

Roadmap : phase 4 Narrative Studio, quatrième lot sur six

## Résumé exécutif

Le contrat Event n'est plus limité à un tableau AND implicite. Le même arbre borné `all/any/not/leaf` est maintenant sérialisé, authoré, expliqué et évalué par l'autorité de dispatch. Les anciens tableaux `conditions` sont lus comme `all(leaves)` sans changer leur sens ni imposer une migration destructive.

Les Events one-shot disposent de trois politiques déterministes : jamais, à la vraie réentrée de map et à la réception d'un outcome pleinement qualifié. Le réarmement est appliqué dans la même transaction que la planification et la Scene ; une annulation ou une erreur restaure donc aussi l'état de reset. Les activations/outbox déjà traitées sont dédupliquées par token persisté et borné.

L'Event Builder expose Toutes/Au moins une/NON et le réarmement avec des sélecteurs guidés. Aucun ID brut n'est demandé dans le parcours normal.

## Scope confirmé et écarts justifiés

- Inclus : expression booléenne bornée, compatibilité AND historique, reset `never`, `onMapReentry`, `onOutcomeReceived`, persistance, idempotence, dépendance qualifiée, runtime map/outcome et UI no-code.
- Exclus : `NarrativeValue` typées, groupes arbitraires imbriqués dans l'UI, Map Events View et fermeture legacy. Ces sujets restent respectivement NSC-51, une amélioration post-v1, NSC-44 et NSC-45.
- `narrative_event_wire.dart` et `narrative_event_registry_codec.dart` n'ont pas nécessité de changement : le wire Event est porté par `NarrativeEventDefinition.toJson/fromJson` et le codec registre délègue déjà strictement à ce modèle.
- `narrative_event_migration_planner_impl.dart` reste volontairement dans NSC-45 : le lecteur courant effectue déjà la migration AND sans perte, tandis que la promotion de projet et son recovery appartiennent au lot d'intégrité.
- `narrative_event_state_transactions.dart` n'a pas été étendu : le point transactionnel correct est le `beforePlan` du coordinator existant, ce qui couvre planification, Scene, commit et rollback sans créer une seconde autorité.
- Aucune mutation de phase 5 n'est incluse.

## Audit initial

- `NarrativeEventDefinition` persistait une liste plate et `NarrativeEventDispatchAuthority` appliquait implicitement AND.
- `NarrativeEventProgress` persistait consommation/in-flight/outbox mais aucune mémoire de map ni token de réarmement.
- Les bridges map et outcome possédaient déjà une identité d'activation/livraison et une transaction adaptée ; ils étaient donc les points de branchement fiables.
- L'Event Builder savait modifier les feuilles mais présentait honnêtement la limite AND-only issue de NSC-42.
- `NarrativeDependencyIndex` ne connaissait pas encore un outcome utilisé comme règle de reset.

Risques audités : changer le sens des anciens Events, compter un restore comme réentrée, réarmer deux fois une livraison, accepter une collision d'outcome par label, committer le reset avant une Scene échouée, ou afficher une capacité UI non exécutée par le runtime.

## État Git initial

- Branche : `main`.
- HEAD : `986146f66 feat(narrative): simulate canonical event dispatch`.
- Arbre au redémarrage : uniquement le brouillon NSC-43 déjà entamé dans `narrative_event_definition.dart`, puis les fichiers du présent lot au fil de la reprise.
- Aucun fichier étranger n'a été absorbé.

## Inventaire complet et zones modifiées

| Fichier | Zone | Raison et impact |
|---|---|---|
| `packages/map_core/lib/src/models/narrative_event_definition.dart` | expressions, reset policies, validation/JSON/égalité | Définit le contrat fermé, borné et rétrocompatible partagé par toutes les couches. |
| `packages/map_core/lib/src/models/narrative_event_progress.dart` | map active/visitées, tokens de reset, `copyWith` | Persiste la qualification de réentrée et l'idempotence après reload. |
| `packages/map_core/lib/src/operations/narrative_event_dispatch_authority.dart` | évaluation récursive et transforms de reset | Garde une seule autorité de décision et échoue fermé sur une feuille inconnue. |
| `packages/map_core/lib/src/authoring/narrative_event_authoring_contract.dart` | types de mutation | Journalise explicitement expression et reset. |
| `packages/map_core/lib/src/authoring/narrative_event_authoring_verification.dart` | replay des nouvelles mutations | Préserve recovery/undo sans réduction vers AND. |
| `packages/map_core/lib/src/authoring/narrative_event_configuration_operations.dart` | setters purs et validations | Authoring atomique de l'expression et du reset, avec garde reusable. |
| `packages/map_core/lib/src/authoring/narrative_event_publication_operations.dart` | projection/validation de publication | Empêche publication d'une combinaison sans effet ou d'un outcome indisponible. |
| `packages/map_core/lib/src/authoring/narrative_event_source_operations_v2.dart` | changement de source | Préserve les nouveaux champs et refuse une source incompatible avec le reset. |
| `packages/map_core/lib/src/authoring/scene_authoring_operations.dart` | copies de définition | Évite la perte silencieuse expression/reset lors d'une mutation Scene. |
| `packages/map_core/lib/src/operations/narrative_event_record_operations.dart` | rename/duplicate/copy | Préserve le contrat lors du lifecycle Event. |
| `packages/map_core/lib/src/read_models/narrative_dependency_index.dart` | outcome de reset | Indexe le producteur qualifié pour navigation/suppression sûre. |
| `packages/map_core/lib/src/read_models/narrative_event_builder_project_read_model.dart` | résumé conditions/lifecycle/debug | Expose un libellé honnête Toutes/Au moins une et la policy réelle. |
| `packages/map_gameplay/lib/src/narrative_event_execution_coordinator.dart` | transform `beforePlan` transactionnel | Applique le reset avant plan, puis commit/rollback avec la Scene. |
| `packages/map_gameplay/lib/src/narrative_outcome_outbox_processor.dart` | copie du progress | Préserve les nouveaux champs persistés pendant l'outbox. |
| `packages/map_runtime/lib/src/application/map_enter_production_dispatch_bridge.dart` | qualification vraie réentrée | Warp/connection seulement ; initial/restore/duplicate ne réarment pas. |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | reset outcome avant dispatch | Utilise la référence qualifiée et le delivery ID réel. |
| `packages/map_editor/lib/src/application/use_cases/narrative_event_builder_v2_use_case.dart` | getters/writers | Orchestration UI vers opérations core attestées. |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_authoring_sheets.dart` | side sheets Conditions/Comportement | Pickers Toutes/Au moins une/NON et reset sans ID manuel. |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_inspector.dart` | résumé comportement | Explique quand et pourquoi l'Event redevient disponible. |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart` | composition des mutations | Ordonne correctement reset/reuse pour ne jamais créer un état intermédiaire invalide. |
| `packages/map_core/test/narrative_event_definition_test.dart` | codec/limites/migration | AND legacy, OR/NOT, profondeur, groupes vides et combinaisons reset. |
| `packages/map_core/test/narrative_event_dispatch_authority_test.dart` | décision/reset/idempotence | ANY/NOT, vraie réentrée, restore, duplicate et collision de producteurs. |
| `packages/map_core/test/narrative_event_configuration_authoring_test.dart` | mutations | Expression/reset et rejet reusable + reset. |
| `packages/map_core/test/narrative_dependency_index_test.dart` | référence qualifiée | Producteur d'outcome utilisé par un reset. |
| `packages/map_core/test/narrative_event_builder_project_read_model_test.dart` | snapshot debug | Nouveau résumé expression sans masquer le wire. |
| `packages/map_runtime/test/narrative_event_progress_save_load_test.dart` | round-trip progress | Historique map et tokens survivent au save/load. |
| `packages/map_runtime/test/narrative_map_enter_production_dispatch_bridge_test.dart` | intégration map | Réentrée réelle, restore exclu, activation dupliquée et rollback. |
| `packages/map_editor/test/event_builder_v2_condition_expression_test.dart` | widgets | Authoring ANY/NON et disponibilité des reset policies one-shot. |
| `docs/superpowers/plans/2026-07-20-nsc-43-event-expressions-reset-policies.md` | micro-plan XL | Cadre le TDD, les frontières et le gate du lot. |

## TDD, commandes et résultats exacts

Le premier rouge portait sur les types `NarrativeEventConditionExpression`/`NarrativeEventResetPolicy` absents. Les étapes vertes ont ensuite révélé les copies de modèle qui perdaient les nouveaux champs, puis les cas transactionnels map/outcome ; chaque chemin a été couvert avant élargissement des suites.

```text
cd packages/map_core
dart test && dart analyze
+4189: All tests passed!
Analyzing map_core...
No issues found!

cd packages/map_gameplay
dart test && dart analyze
+289: All tests passed!
Analyzing map_gameplay...
No issues found!

cd packages/map_runtime
flutter test test/narrative_event_progress_save_load_test.dart test/narrative_map_enter_production_dispatch_bridge_test.dart && flutter analyze
+18: All tests passed!
Analyzing map_runtime...
No issues found! (ran in 11.4s)

cd packages/map_editor
flutter test test/event_builder_v2_condition_expression_test.dart test/narrative_event_builder_v2_use_case_test.dart test/ui/canvas/event_builder_v2_creation_flow_test.dart
+19: All tests passed!

flutter analyze lib/src/application/use_cases/narrative_event_builder_v2_use_case.dart lib/src/ui/canvas/events_v2/event_builder_v2_authoring_sheets.dart lib/src/ui/canvas/events_v2/event_builder_v2_inspector.dart lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart test/event_builder_v2_condition_expression_test.dart
Analyzing 5 items...
No issues found! (ran in 5.2s)

flutter build macos --debug
✓ Built build/macos/Build/Products/Debug/map_editor.app

git diff --check
<aucune sortie>

audit couleurs brutes des trois fichiers UI modifiés
<aucune sortie>
```

## Passes locales nommées

| Passe | Verdict |
|---|---|
| Audit / Architecture | PASS : le wire reste dans core, la décision dans l'autorité et les resets dans la transaction gameplay. |
| Implémentation | PASS : aucun deuxième evaluator, aucun reset dans un widget, copies exhaustives des nouveaux champs. |
| Tests | PASS : suites complètes core/gameplay, ciblées runtime/editor, positif/négatif/garde-fou/non-régression. |
| Build / Validation | PASS : analyses touchées propres et build macOS réussi. |
| Critique finale | PASS avec limites explicites : UI v1 n'autorise qu'un niveau de groupe, mais le wire borné accepte les arbres futurs sans migration. |

## Fichiers créés — contenu intégral

### `docs/superpowers/plans/2026-07-20-nsc-43-event-expressions-reset-policies.md`

```markdown
# NSC-43 — Expressions de conditions et politiques de réarmement Event

## Objectif

Remplacer la limite historique AND-only par un contrat borné `all/any/not/leaf`, puis partager trois politiques de réarmement déterministes entre le wire, l’authoring, la simulation, le runtime et la sauvegarde.

## Frontières

- Conserver uniquement les feuilles booléennes Fact et Event consommé ; les valeurs typées restent NSC-51.
- Conserver la lecture des anciens tableaux `conditions` comme `all(leaves)`.
- Autoriser le réarmement uniquement pour les Events one-shot.
- Compter comme réentrée uniquement une transition warp/connection vers une map déjà visitée après observation d’une autre map.
- Ne pas commencer NSC-44 ou NSC-45 dans ce commit.

## Plan d’implémentation

1. Ajouter le schema d’expression borné et les reset policies qualifiées au modèle Event.
2. Préserver expression/reset dans chaque opération de copie, publication, source et Scene.
3. Évaluer l’expression dans l’autorité de dispatch et appliquer le reset dans la transaction avant planification.
4. Persister historique de map et tokens d’idempotence dans `NarrativeEventProgress`.
5. Câbler map activation et outcome outbox réels sans double dispatch.
6. Indexer la dépendance du résultat qualifié et rejeter les combinaisons impossibles.
7. Exposer Toutes/Au moins une/NON et Réarmement dans les side sheets et l’inspecteur.
8. Prouver migration AND, OR/NOT, contraintes, vraie réentrée, restore, duplication, collision qualifiée et save/load.

## Gate

L’UI, l’autorité de dispatch, le progress save et le runtime consomment les mêmes objets `NarrativeEventConditionExpression` et `NarrativeEventResetPolicy`, avec tests ciblés verts et build macOS réussi.
```

### `packages/map_editor/test/event_builder_v2_condition_expression_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_builder_v2_use_case.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/events_v2/event_builder_v2_authoring_sheets.dart';

const _eventId = 'evt_019abcde-0000-7000-8000-000000000001';

void main() {
  testWidgets('authors ANY and NOT as one bounded expression', (tester) async {
    final condition = NarrativeEventCondition.fact('fact_open', true);
    final expression = NarrativeEventConditionExpression.any([
      NarrativeEventConditionExpression.leaf(condition),
    ]);
    NarrativeEventConditionExpression? saved;
    await tester.binding.setSurfaceSize(const Size(520, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: EventBuilderV2ConditionsSheet(
            snapshot: _snapshot(expression),
            onSubmit: (value) async {
              saved = value;
              return 'keep-open';
            },
          ),
        ),
      ),
    );

    expect(find.text('Au moins une doit être remplie'), findsOneWidget);
    expect(find.text('Port ouvert = Vrai'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('event-builder-v2-negate-condition-0')),
    );
    await tester.scrollUntilVisible(
      find.text('Enregistrer les conditions'),
      240,
    );
    await tester.tap(find.text('Enregistrer les conditions'));
    await tester.pump();

    expect(saved, isA<NarrativeEventConditionAny>());
    final any = saved! as NarrativeEventConditionAny;
    expect(any.children.single, isA<NarrativeEventConditionNot>());
    expect(tester.takeException(), isNull);
  });

  testWidgets('offers deterministic reset policies only for one-shot Events',
      (tester) async {
    final outcome = NarrativeOutcomeRef(
      producerKind: NarrativeOutcomeProducerKind.scene,
      producerId: 'scene_signal',
      outcomeId: 'completed',
    );
    await tester.binding.setSurfaceSize(const Size(520, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: EventBuilderV2BehaviorSheet(
            record: _snapshot(
              NarrativeEventConditionExpression.all(const []),
            ).record!,
            outcomeSources: [
              NarrativeOutcomeEventSourceOption(
                outcome: outcome,
                producerLabel: 'Signal de Scene',
                outcomeLabel: 'Terminé',
                humanSourceSentence: 'Quand la Scene est terminée.',
                status: NarrativeOutcomeReachabilityStatus.reachable,
                selectable: true,
                origin: NarrativeOutcomeSourceOrigin.scene,
                debugTechnicalLabel: 'scene_signal#completed',
              ),
            ],
            onSave: (_) async => 'keep-open',
            onPublish: () async => 'keep-open',
            onSetEnabled: (_) async => 'keep-open',
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('event-builder-v2-reset-policy')),
      findsOneWidget,
    );
    expect(find.text('Jamais'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

NarrativeEventBuilderV2EditorSnapshot _snapshot(
  NarrativeEventConditionExpression expression,
) {
  final conditions = expression.leaves;
  final record = NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: _eventId,
      name: 'Rencontre au port',
      source: NarrativeEventSourceRef.mapEnter('map_port'),
      conditions: conditions,
      conditionExpression: expression,
      sceneId: 'scene_port',
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: 0,
      order: 0,
    ),
    enabled: false,
  );
  return NarrativeEventBuilderV2EditorSnapshot(
    projectRevision: 'revision',
    record: record,
    spatialSources: const [],
    outcomeSources: const [],
    scenes: const [],
    facts: [
      NarrativeEventProjectFactEntry(
        NarrativeFactDefinition(id: 'fact_open', label: 'Port ouvert'),
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

Le présent Evidence Pack est lui-même le troisième fichier créé et contient son propre contenu intégral.

## Auto-critique, limites et risques

- Le wire accepte des groupes imbriqués jusqu'aux budgets documentés, mais l'UI de ce lot propose un mode racine et la négation des feuilles. Cette tranche ferme le besoin produit courant sans exposer un éditeur d'arbre complexe prématuré.
- Les tokens de reset sont bornés à 256. La déduplication durable de l'outbox reste portée par les receipts existants ; le token protège spécifiquement le réarmement avant plan.
- `onMapReentry` dépend de l'observation d'une autre map dans le même progress. Un ancien save sans historique démarre donc prudemment sans faux reset, puis apprend les transitions suivantes.
- Les validations complètes editor n'ont pas été utilisées comme gate car la baseline connue comporte onze avertissements historiques dans `dialogue_studio_dialogs.dart`, hors lot. L'analyse ciblée des cinq éléments NSC-43 est propre et le build complet réussit.
- Les migrations de format legacy et le dual-read ne sont pas revendiqués ici ; ils restent le cœur de NSC-45.

## État Git final attendu

- Un commit NSC-43 contient exclusivement les fichiers de l'inventaire, le micro-plan forcé et ce rapport.
- Aucun push n'est effectué.
- NSC-44 et NSC-45 restent non implémentés à la fin de ce commit.

## Prochaine étape non implémentée dans ce commit

`NSC-44 — Map Events View 2.0 comme sous-route Events` : construire une projection exhaustive par map et sa surface de navigation/focus sans dupliquer le Map Editor.
