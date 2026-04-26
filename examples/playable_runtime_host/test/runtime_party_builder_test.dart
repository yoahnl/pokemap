import 'package:PokeMap_Loader/src/runtime_demo_party_seed.dart';
import 'package:PokeMap_Loader/src/runtime_party_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('adds a selected pokemon with level and suggested moves',
      (tester) async {
    final members = <RuntimeDemoPartyPokemonSeed>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) {
                return RuntimePartyBuilderPanel(
                  options: const <RuntimePartyBuilderPokemonOption>[
                    RuntimePartyBuilderPokemonOption(
                      speciesId: 'bulbasaur',
                      displayName: 'Bulbasaur',
                      abilityId: 'overgrow',
                      gender: 'male',
                      availableMoveIds: <String>[
                        'tackle',
                        'growl',
                        'vine_whip',
                      ],
                      suggestedMoveIds: <String>['tackle', 'growl'],
                    ),
                  ],
                  members: members,
                  enabled: true,
                  onAdd: (member) {
                    setState(() => members.add(member));
                  },
                  onRemove: (index) {
                    setState(() => members.removeAt(index));
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('runtime-party-builder-species-field')),
      'Bulb',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bulbasaur (bulbasaur)').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('runtime-party-builder-level-field')),
      '42',
    );
    await tester.tap(find.byKey(const Key('runtime-party-builder-add-button')));
    await tester.pumpAndSettle();

    expect(members, hasLength(1));
    expect(members.single.speciesId, equals('bulbasaur'));
    expect(members.single.level, equals(42));
    expect(members.single.abilityId, equals('overgrow'));
    expect(members.single.gender, equals('male'));
    expect(members.single.knownMoveIds, equals(<String>['tackle', 'growl']));
    expect(find.textContaining('Bulbasaur'), findsWidgets);
  });

  testWidgets('prevents adding more than six pokemon', (tester) async {
    const fullParty = <RuntimeDemoPartyPokemonSeed>[
      RuntimeDemoPartyPokemonSeed(
        speciesId: 'bulbasaur',
        abilityId: 'overgrow',
        gender: null,
        level: 5,
        currentHp: 10,
        knownMoveIds: <String>['tackle'],
      ),
      RuntimeDemoPartyPokemonSeed(
        speciesId: 'ivysaur',
        abilityId: 'overgrow',
        gender: null,
        level: 5,
        currentHp: 10,
        knownMoveIds: <String>['tackle'],
      ),
      RuntimeDemoPartyPokemonSeed(
        speciesId: 'venusaur',
        abilityId: 'overgrow',
        gender: null,
        level: 5,
        currentHp: 10,
        knownMoveIds: <String>['tackle'],
      ),
      RuntimeDemoPartyPokemonSeed(
        speciesId: 'charmander',
        abilityId: 'blaze',
        gender: null,
        level: 5,
        currentHp: 10,
        knownMoveIds: <String>['scratch'],
      ),
      RuntimeDemoPartyPokemonSeed(
        speciesId: 'squirtle',
        abilityId: 'torrent',
        gender: null,
        level: 5,
        currentHp: 10,
        knownMoveIds: <String>['tackle'],
      ),
      RuntimeDemoPartyPokemonSeed(
        speciesId: 'pikachu',
        abilityId: 'static',
        gender: null,
        level: 5,
        currentHp: 10,
        knownMoveIds: <String>['thunder_shock'],
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RuntimePartyBuilderPanel(
              options: const <RuntimePartyBuilderPokemonOption>[
                RuntimePartyBuilderPokemonOption(
                  speciesId: 'bulbasaur',
                  displayName: 'Bulbasaur',
                  abilityId: 'overgrow',
                  gender: null,
                  availableMoveIds: <String>['tackle'],
                  suggestedMoveIds: <String>['tackle'],
                ),
              ],
              members: fullParty,
              enabled: true,
              onAdd: (_) {},
              onRemove: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Equipe pleine (6/6)'), findsOneWidget);
    final addButton = tester.widget<FilledButton>(
      find.byKey(const Key('runtime-party-builder-add-button')),
    );
    expect(addButton.onPressed, isNull);
  });
}
