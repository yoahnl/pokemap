import 'package:PokeMap_Loader/src/runtime_demo_party_seed.dart';
import 'package:PokeMap_Loader/src/runtime_party_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets('adds a selected pokemon with level and suggested moves',
      (tester) async {
    final members = <RuntimeDemoPartyPokemonSeed>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
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
                      moveDiagnostics: {},
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
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
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
                  moveDiagnostics: {},
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

  testWidgets('shows filtered move diagnostics for the selected pokemon',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: Scaffold(
          body: SingleChildScrollView(
            child: RuntimePartyBuilderPanel(
              options: const <RuntimePartyBuilderPokemonOption>[
                RuntimePartyBuilderPokemonOption(
                  speciesId: 'mew',
                  displayName: 'Mew',
                  abilityId: 'synchronize',
                  gender: null,
                  availableMoveIds: <String>['mega_punch', 'swift'],
                  suggestedMoveIds: <String>['mega_punch', 'swift'],
                  moveDiagnostics: <String, RuntimeBattleMoveBridgeDiagnostics>{
                    'mega_punch': RuntimeBattleMoveBridgeDiagnostics(
                      moveId: 'mega_punch',
                      bridgeable: true,
                      reason: 'bridgeable',
                      engineSupportLevel:
                          PokemonMoveEngineSupportLevel.structuredSupported,
                      unsupportedReasons: <String>[],
                    ),
                    'baton_pass': RuntimeBattleMoveBridgeDiagnostics(
                      moveId: 'baton_pass',
                      bridgeable: false,
                      reason: 'unsupported_effect_kind:self_switch',
                      engineSupportLevel:
                          PokemonMoveEngineSupportLevel.structuredPartial,
                      unsupportedReasons: <String>[
                        'unsupported_effect_kind:self_switch',
                      ],
                      battleEngineMethod: 's_baton_pass',
                      psdkRegistryStatus: 'partial',
                    ),
                  },
                ),
              ],
              members: const <RuntimeDemoPartyPokemonSeed>[],
              enabled: true,
              onAdd: (_) {},
              onRemove: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('runtime-party-builder-species-field')),
      'Mew',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mew (mew)').last);
    await tester.pumpAndSettle();

    expect(find.text('Moves filtres'), findsOneWidget);
    expect(
      find.text('baton_pass - unsupported_effect_kind:self_switch'),
      findsOneWidget,
    );
    expect(find.text('mega_punch - bridgeable'), findsNothing);
  });
}
