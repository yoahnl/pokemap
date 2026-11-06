import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_controller.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_port.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_evolution_entry.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_evolution_rule.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('rule summary mirrors the runtime loader', () {
    PokemonEvolutionRule rule(Map<String, dynamic> entry) =>
        pokemonEvolutionRule(entry, itemName: (id) => 'Pierre $id');

    test('level up', () {
      final value = rule({'method': 'level_up', 'minLevel': 16});
      expect(value.kind, PokemonEvolutionRuleKind.level);
      expect(value.executable, isTrue);
      expect(
        value.sentence,
        'Le jeu le fait évoluer en montant au niveau 16 ou plus.',
      );
    });

    test('level up with friendship or move becomes that rule', () {
      expect(
        rule({'method': 'level_up', 'minFriendship': 220}).kind,
        PokemonEvolutionRuleKind.friendship,
      );
      expect(
        rule({
          'method': 'level_up',
          'minLevel': 20,
          'requiredMoveId': 'rollout',
        }).kind,
        PokemonEvolutionRuleKind.knownMove,
      );
    });

    test('item use keeps its alias and default level', () {
      final value = rule({'method': 'item', 'itemId': 'foudre'});
      expect(value.kind, PokemonEvolutionRuleKind.item);
      expect(
        value.sentence,
        'Le jeu le fait évoluer quand on utilise Pierre foudre sur lui, dès le niveau 1.',
      );
    });

    test('incomplete or out of range rules are refused', () {
      final missing = rule({'method': 'level_up'});
      expect(missing.executable, isFalse);
      expect(missing.sentence, startsWith('Règle incomplète'));
      final range = rule({'method': 'level_up', 'minLevel': 1});
      expect(range.executable, isFalse);
      expect(range.sentence, startsWith('Règle invalide'));
      expect(
        rule({'method': 'friendship', 'minFriendship': 0}).executable,
        isFalse,
      );
    });

    test('unknown methods are kept but never run', () {
      final value = rule({'method': 'level-up-night', 'minLevel': 10});
      expect(value.kind, PokemonEvolutionRuleKind.unsupported);
      expect(value.executable, isFalse);
      expect(
        value.sentence,
        'Méthode non prise en charge par le jeu : « level-up-night ». Elle ne s’exécute pas et reste conservée sans changement.',
      );
    });
  });

  Future<PokemonWorkspaceController> open(
    WidgetTester tester,
    Map<String, dynamic> evolution,
  ) async {
    final tick = ValueNotifier(0);
    final controller = PokemonWorkspaceController(
      _EvolutionPort(evolution),
      changed: () => tick.value++,
    );
    await tester.runAsync(controller.load);
    await tester.runAsync(() => controller.selectSpecies('pichu'));
    tester.view.physicalSize = const Size(1200, 2400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            key: const PageStorageKey('pokemon-detail-test'),
            child: ValueListenableBuilder<int>(
              valueListenable: tick,
              builder: (_, _, _) => PokemonEvolutionEntry(
                controller: controller,
                index: 0,
                value: _entry(controller),
                speciesOptions: const {'pikachu': 'Pikachu · pikachu'},
                onRemove: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return controller;
  }

  StudioSelect method(WidgetTester tester) => tester.widget<StudioSelect>(
    find.byWidgetPredicate(
      (widget) =>
          widget is StudioSelect && widget.label == 'Déclenchement en jeu',
    ),
  );

  testWidgets('the executed rule and the free description are separated', (
    tester,
  ) async {
    final controller = await open(tester, {
      'method': 'level_up',
      'minLevel': 16,
      'conditionText': {'fr': 'Évolue au niveau 16'},
    });
    expect(find.text('Règle exécutée par le jeu'), findsOneWidget);
    expect(method(tester).value, 'level_up');
    expect(
      find.text('Le jeu le fait évoluer en montant au niveau 16 ou plus.'),
      findsOneWidget,
    );
    expect(find.text('Description'), findsOneWidget);
    expect(find.textContaining('Le jeu ne lit pas ce texte'), findsOneWidget);
    expect(find.text('Description · fr'), findsOneWidget);
    expect(find.text('Amitié minimum'), findsNothing);
    expect(find.text('Objet requis'), findsNothing);
    expect(find.text('Attaque requise'), findsNothing);
    expect(
      tester.getTopLeft(find.text('Règle exécutée par le jeu')).dy,
      lessThan(tester.getTopLeft(find.text('Description')).dy),
    );
    controller.dispose();
  });

  testWidgets('guided choices only list supported methods', (tester) async {
    final controller = await open(tester, {
      'method': 'level_up',
      'minLevel': 16,
    });
    expect(method(tester).options.keys, [
      'level_up',
      'friendship',
      'known_move',
      'use_item',
    ]);
    controller.dispose();
  });

  testWidgets('an unsupported method is flagged and kept until replaced', (
    tester,
  ) async {
    final controller = await open(tester, {
      'method': 'level-up-night',
      'minLevel': 10,
      'conditionText': {'fr': 'La nuit'},
    });
    expect(
      find.text(
        'Méthode non prise en charge par le jeu : « level-up-night ». Elle ne s’exécute pas et reste conservée sans changement.',
      ),
      findsOneWidget,
    );
    expect(method(tester).value, 'level-up-night');
    expect(
      method(tester).options['level-up-night'],
      'Non prise en charge · level-up-night',
    );
    expect(_entry(controller)['method'], 'level-up-night');
    method(tester).onChanged!('level_up');
    await tester.pump();
    final entry = _entry(controller);
    expect(entry['method'], 'level_up');
    expect(entry['minLevel'], 10);
    expect(entry['conditionText'], {'fr': 'La nuit'});
    controller.dispose();
  });

  testWidgets('trade rules are explained and their method is locked', (
    tester,
  ) async {
    final controller = await open(tester, {
      'method': 'trade',
      'tradeRequirements': <String, dynamic>{},
    });
    expect(method(tester).onChanged, isNull);
    expect(find.textContaining('lors d’un échange'), findsOneWidget);
    expect(find.text('Niveau minimum'), findsNothing);
    controller.dispose();
  });

  testWidgets('data outside the chosen rule stays visible', (tester) async {
    final controller = await open(tester, {
      'method': 'level_up',
      'minLevel': 16,
      'itemId': 'foudre',
    });
    expect(find.text('Objet requis'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('the raw method identifier is an advanced option', (
    tester,
  ) async {
    final controller = await open(tester, {
      'method': 'level_up',
      'minLevel': 16,
    });
    expect(find.byKey(const ValueKey('evolution-0-method')), findsNothing);
    await tester.tap(find.text('Données techniques'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('evolution-0-method')), findsOneWidget);
    controller.dispose();
  });
}

Map<String, dynamic> _entry(PokemonWorkspaceController controller) =>
    ((controller.selectedDraft!.document(
                      PokemonDocumentFamily.evolution,
                    )!['evolutions']
                    as List)
                .first
            as Map)
        .cast<String, dynamic>();

final class _EvolutionPort implements PokemonWorkspacePort {
  _EvolutionPort(this.evolution);

  final Map<String, dynamic> evolution;

  @override
  Future<PokemonWorkspaceIndex> loadIndex() async => PokemonWorkspaceIndex(
    enabled: true,
    entries: [
      PokemonSpeciesSummary(
        id: 'pichu',
        name: 'Pichu',
        nationalDex: 172,
        generation: 2,
        types: const [],
        formIds: const ['base'],
        mediaRelativePath: '',
        enabled: true,
        relativePath: 'pichu.json',
      ),
    ],
    moves: const PokemonMovesCatalogView(entries: [], relativePath: ''),
    types: [],
    items: {'foudre': 'Pierre Foudre'},
  );

  @override
  Future<PokemonSpeciesBundle> loadSpecies(PokemonSpeciesSummary entry) async =>
      PokemonSpeciesBundle(
        species: PokemonDocumentSource(
          family: PokemonDocumentFamily.species,
          relativePath: entry.relativePath,
          bytes: null,
          document: {'id': entry.id},
        ),
        learnset: null,
        evolution: PokemonDocumentSource(
          family: PokemonDocumentFamily.evolution,
          relativePath: 'evolutions/pichu.json',
          bytes: null,
          document: {
            'speciesId': 'pichu',
            'evolutions': [
              {'targetSpeciesId': 'pikachu', ...evolution},
            ],
          },
        ),
        media: null,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
