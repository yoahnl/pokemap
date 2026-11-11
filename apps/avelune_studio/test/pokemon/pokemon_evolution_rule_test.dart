import 'package:avelune_studio/features/pokemon/application/pokemon_document_editing.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_controller.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_port.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_evolution_rule.dart';
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

    test('day and night friendship rules expose their actual conditions', () {
      for (final (method, text) in [
        ('friendship_day', 'de jour, de 4 h à 19 h 59'),
        ('friendship_night', 'de nuit, de 20 h à 3 h 59'),
      ]) {
        final entry = {'method': method, 'minFriendship': 220};
        final value = rule(entry);
        expect(value.kind, PokemonEvolutionRuleKind.friendship);
        expect(value.executable, isTrue);
        expect(value.sentence, contains('amitié d’au moins 220'));
        expect(value.sentence, contains(text));
        expect(pokemonEvolutionShowsField(entry, 'minFriendship'), isTrue);
        expect(rule({'method': method}).executable, isFalse);
      }
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
    Map<String, dynamic> evolution,
  ) async {
    final controller = PokemonWorkspaceController(
      _EvolutionPort(evolution),
      changed: () {},
    );
    addTearDown(controller.dispose);
    await controller.load();
    await controller.selectSpecies('pichu');
    return controller;
  }

  test(
    'the executed rule and the free description remain independent',
    () async {
      final controller = await open({
        'method': 'level_up',
        'minLevel': 16,
        'conditionText': {'fr': 'Évolue au niveau 16'},
      });
      final sentence = pokemonEvolutionRule(_entry(controller)).sentence;
      expect(
        sentence,
        'Le jeu le fait évoluer en montant au niveau 16 ou plus.',
      );
      controller.edit(
        PokemonDocumentFamily.evolution,
        (json) => PokemonDocumentEditing.editEvolutionCondition(
          json,
          0,
          'fr',
          'Description libre',
        ),
      );
      expect(_entry(controller)['conditionText'], {'fr': 'Description libre'});
      expect(pokemonEvolutionRule(_entry(controller)).sentence, sentence);
      expect(
        pokemonEvolutionShowsField(_entry(controller), 'minFriendship'),
        isFalse,
      );
      expect(pokemonEvolutionShowsField(_entry(controller), 'itemId'), isFalse);
      expect(
        pokemonEvolutionShowsField(_entry(controller), 'requiredMoveId'),
        isFalse,
      );
    },
  );

  test('guided choices only list supported methods', () async {
    final controller = await open({'method': 'level_up', 'minLevel': 16});
    expect(pokemonEvolutionMethodOptions(_entry(controller)).keys, [
      'level_up',
      'friendship',
      'friendship_day',
      'friendship_night',
      'known_move',
      'use_item',
    ]);
  });

  test('an unsupported method remains flagged and unchanged until explicitly replaced', () async {
    final controller = await open({
      'method': 'level-up-night',
      'minLevel': 10,
      'conditionText': {'fr': 'La nuit'},
    });
    final entry = _entry(controller);
    expect(
      pokemonEvolutionRule(entry).sentence,
      'Méthode non prise en charge par le jeu : « level-up-night ». Elle ne s’exécute pas et reste conservée sans changement.',
    );
    expect(
      pokemonEvolutionMethodOptions(entry)['level-up-night'],
      'Non prise en charge · level-up-night',
    );
    expect(entry['method'], 'level-up-night');
    controller.edit(
      PokemonDocumentFamily.evolution,
      (json) =>
          PokemonDocumentEditing.editEvolution(json, 0, 'method', 'level_up'),
    );
    expect(_entry(controller)['method'], 'level_up');
    expect(_entry(controller)['minLevel'], 10);
    expect(_entry(controller)['conditionText'], {'fr': 'La nuit'});
    expect(entry['method'], 'level-up-night');
  });

  test('trade rules are explained and their guided method is locked', () async {
    final controller = await open({
      'method': 'trade',
      'tradeRequirements': <String, dynamic>{},
    });
    final entry = _entry(controller);
    expect(pokemonEvolutionGuidedMethodLocked(entry), isTrue);
    expect(pokemonEvolutionRule(entry).sentence, contains('lors d’un échange'));
    expect(pokemonEvolutionShowsField(entry, 'minLevel'), isFalse);
  });

  test(
    'data outside the selected rule remains discoverable and preserved',
    () async {
      final controller = await open({
        'method': 'level_up',
        'minLevel': 16,
        'itemId': 'foudre',
      });
      expect(pokemonEvolutionShowsField(_entry(controller), 'itemId'), isTrue);
      expect(_entry(controller)['itemId'], 'foudre');
      expect(
        pokemonEvolutionRuleKind(_entry(controller)),
        PokemonEvolutionRuleKind.level,
      );
    },
  );

  test(
    'raw method editing preserves the exact identifier and supports undo',
    () async {
      final controller = await open({'method': 'level_up', 'minLevel': 16});
      controller.edit(
        PokemonDocumentFamily.evolution,
        (json) => PokemonDocumentEditing.editEvolution(
          json,
          0,
          'method',
          'level-up-night',
        ),
      );
      expect(_entry(controller)['method'], 'level-up-night');
      expect(_entry(controller)['minLevel'], 16);
      expect(pokemonEvolutionRule(_entry(controller)).executable, isFalse);
      controller.undo();
      expect(_entry(controller)['method'], 'level_up');
    },
  );
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
