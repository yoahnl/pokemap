import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_api.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_map_editing/application/pending_border_save_guard.dart';
import 'package:map_editor/src/features/editor/application/map_activation_coordinator.dart';
import 'package:map_editor/src/features/editor/presentation/map_activation_guard.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('clean activation does not open a decision dialog', (
    tester,
  ) async {
    final decisions = <DirtyMapActivationDecision?>[];
    MapActivationOutcome? result;

    await tester.pumpWidget(
      _GuardHarness(
        onResult: (value) => result = value,
        activate: (decision) async {
          decisions.add(decision);
          return MapActivationOutcome.activated;
        },
        save: () async => ActiveMapSaveOutcome.saved,
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(result, MapActivationOutcome.activated);
    expect(decisions, <DirtyMapActivationDecision?>[null]);
    expect(find.byKey(pokeMapConfirmationDialogKey), findsNothing);
  });

  testWidgets('dirty activation offers cancel, discard, and save', (
    tester,
  ) async {
    await tester.pumpWidget(
      _GuardHarness(
        activate: (_) async => MapActivationOutcome.requiresDecision,
        save: () async => ActiveMapSaveOutcome.saved,
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.byKey(pokeMapConfirmationDialogKey), findsOneWidget);
    expect(find.text('Modifications non enregistrées'), findsOneWidget);
    expect(find.text('Rester ici'), findsOneWidget);
    expect(find.text('Ignorer les modifications'), findsOneWidget);
    expect(find.text('Enregistrer et ouvrir'), findsOneWidget);
  });

  testWidgets('discard forwards the explicit discard decision', (tester) async {
    final decisions = <DirtyMapActivationDecision?>[];
    MapActivationOutcome? result;

    await tester.pumpWidget(
      _GuardHarness(
        onResult: (value) => result = value,
        activate: (decision) async {
          decisions.add(decision);
          return decision == null
              ? MapActivationOutcome.requiresDecision
              : MapActivationOutcome.activated;
        },
        save: () async => ActiveMapSaveOutcome.saved,
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ignorer les modifications'));
    await tester.pumpAndSettle();

    expect(decisions, <DirtyMapActivationDecision?>[
      null,
      DirtyMapActivationDecision.discard,
    ]);
    expect(result, MapActivationOutcome.activated);
  });

  testWidgets('cancel keeps navigation on the current document', (
    tester,
  ) async {
    final decisions = <DirtyMapActivationDecision?>[];
    MapActivationOutcome? result;

    await tester.pumpWidget(
      _GuardHarness(
        onResult: (value) => result = value,
        activate: (decision) async {
          decisions.add(decision);
          return decision == null
              ? MapActivationOutcome.requiresDecision
              : MapActivationOutcome.cancelled;
        },
        save: () async => ActiveMapSaveOutcome.saved,
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rester ici'));
    await tester.pumpAndSettle();

    expect(decisions, <DirtyMapActivationDecision?>[
      null,
      DirtyMapActivationDecision.cancel,
    ]);
    expect(result, MapActivationOutcome.cancelled);
  });

  testWidgets('save persists first, then activates without a second prompt', (
    tester,
  ) async {
    final calls = <String>[];
    MapActivationOutcome? result;

    await tester.pumpWidget(
      _GuardHarness(
        onResult: (value) => result = value,
        activate: (decision) async {
          calls.add('activate:${decision?.name ?? 'check'}');
          return decision == null
              ? MapActivationOutcome.requiresDecision
              : MapActivationOutcome.activated;
        },
        save: () async {
          calls.add('save');
          return ActiveMapSaveOutcome.saved;
        },
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer et ouvrir'));
    await tester.pumpAndSettle();

    expect(calls, <String>['activate:check', 'save', 'activate:save']);
    expect(result, MapActivationOutcome.activated);
  });

  testWidgets('failed save keeps navigation blocked', (tester) async {
    var activationCount = 0;
    MapActivationOutcome? result;

    await tester.pumpWidget(
      _GuardHarness(
        onResult: (value) => result = value,
        activate: (_) async {
          activationCount += 1;
          return MapActivationOutcome.requiresDecision;
        },
        save: () async => ActiveMapSaveOutcome.failed,
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer et ouvrir'));
    await tester.pumpAndSettle();

    expect(activationCount, 2);
    expect(result, MapActivationOutcome.saveBlocked);
  });

  testWidgets('missing Pokemon ruleset offers repair before retrying open', (
    tester,
  ) async {
    final gateway = _RulesetBootstrapGateway();
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Builder(
          builder: (context) => Center(
            child: PokeMapButton(
              onPressed: () async {
                result = await requestProjectRulesetBootstrapRepair(
                  context: context,
                  manifestPath: '/allowed/project/project.json',
                  gateway: gateway,
                );
              },
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Configuration Pokémon manquante'), findsOneWidget);
    expect(find.text('Réparer et ouvrir'), findsOneWidget);
    expect(gateway.repairCalls, 0);

    await tester.tap(find.text('Réparer et ouvrir'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(gateway.repairCalls, 1);
    expect(gateway.expectedRevision, 'sha256:${List.filled(64, 'a').join()}');
  });

  testWidgets('cancelling Pokemon ruleset repair does not write', (
    tester,
  ) async {
    final gateway = _RulesetBootstrapGateway();
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Builder(
          builder: (context) => PokeMapButton(
            onPressed: () async {
              result = await requestProjectRulesetBootstrapRepair(
                context: context,
                manifestPath: '/allowed/project/project.json',
                gateway: gateway,
              );
            },
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
    expect(gateway.repairCalls, 0);
  });
}

typedef _Activate =
    Future<MapActivationOutcome> Function(DirtyMapActivationDecision? decision);

final class _GuardHarness extends StatelessWidget {
  const _GuardHarness({
    required this.activate,
    required this.save,
    this.onResult,
  });

  final _Activate activate;
  final Future<ActiveMapSaveOutcome> Function() save;
  final ValueChanged<MapActivationOutcome>? onResult;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Builder(
        builder: (context) => Center(
          child: PokeMapButton(
            onPressed: () async {
              final result = await requestGuardedMapActivation(
                context: context,
                activate: activate,
                save: save,
              );
              onResult?.call(result);
            },
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    );
  }
}

final class _RulesetBootstrapGateway
    implements EditorProjectRulesetBootstrapGateway {
  int repairCalls = 0;
  String? expectedRevision;

  @override
  Future<ProjectPokemonRulesetBootstrapPreview> inspect(
    String projectRoot,
  ) async {
    return ProjectPokemonRulesetBootstrapPreview(
      projectName: 'Le train de 17h42',
      currentRevision: 'sha256:${List.filled(64, 'a').join()}',
      repairRequired: true,
      ruleset: PokemonRulesetProfile.pokeMapBetaV1,
    );
  }

  @override
  Future<void> repair({
    required String projectRoot,
    required String expectedRevision,
  }) async {
    repairCalls += 1;
    this.expectedRevision = expectedRevision;
  }
}
