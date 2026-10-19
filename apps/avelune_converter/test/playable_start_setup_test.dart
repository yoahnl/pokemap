import 'dart:async';

import 'package:avelune_converter/playable_start_setup.dart';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('requires a named spawn and two explicit native starters', (
    tester,
  ) async {
    final calls = <List<Object>>[];
    await _pump(
      tester,
      onApply:
          ({
            required mapId,
            required spawnId,
            required starterSpeciesIds,
            required starterLevel,
          }) async {
            calls.add([mapId, spawnId, starterSpeciesIds, starterLevel]);
          },
    );
    expect(
      find.text(
        'Départ Avelune adapté, ne reproduit pas l’introduction source',
      ),
      findsOneWidget,
    );
    expect(find.text('Avatar importé : Camille'), findsOneWidget);
    expect(_apply(tester).onPressed, isNull);
    await _selectVisible(tester, 'playable-start-map', 'Bourg Palette');
    expect(_apply(tester).onPressed, isNull);
    await _selectVisible(tester, 'playable-start-spawn', 'Place du village');
    await _starter(tester, 'species-a');
    expect(_apply(tester).onPressed, isNull);
    await _starter(tester, 'species-c');
    expect(_apply(tester).onPressed, isNotNull);
    await tester.ensureVisible(
      find.byKey(const ValueKey('apply-playable-start')),
    );
    await tester.tap(find.byKey(const ValueKey('apply-playable-start')));
    await tester.pumpAndSettle();
    expect(calls, [
      [
        'town',
        'square',
        ['species-a', 'species-c'],
        5,
      ],
    ]);
    expect(
      find.text(
        'Départ adapté appliqué. Le parcours reste à tester dans le Player.',
      ),
      findsOneWidget,
    );
    expect(_apply(tester).onPressed, isNull);
    expect(find.textContaining('prêt à jouer'), findsNothing);
  });

  testWidgets(
    'map changes clear the spawn and invalid levels block application',
    (tester) async {
      await _pump(tester);
      await _choose(tester);
      _select(tester, 'playable-start-map', 'forest');
      await tester.pump();
      expect(
        tester
            .widget<StudioSelect>(
              find.byKey(const ValueKey('playable-start-spawn')),
            )
            .value,
        isNull,
      );
      expect(_apply(tester).onPressed, isNull);
      _select(tester, 'playable-start-spawn', 'clearing');
      await tester.pump();
      final level = find.descendant(
        of: find.byKey(const ValueKey('playable-start-level')),
        matching: find.byType(TextField),
      );
      await tester.enterText(level, '0');
      await tester.pump();
      expect(_apply(tester).onPressed, isNull);
      expect(
        find.text('Choisissez un niveau entier entre 1 et 100.'),
        findsOneWidget,
      );
      await tester.enterText(level, '12');
      await tester.pump();
      expect(_apply(tester).onPressed, isNotNull);
    },
  );

  testWidgets(
    'pending application prevents duplicates and failure allows retry',
    (tester) async {
      final pending = Completer<void>();
      var calls = 0;
      await _pump(
        tester,
        onApply:
            ({
              required mapId,
              required spawnId,
              required starterSpeciesIds,
              required starterLevel,
            }) async {
              calls++;
              await pending.future;
            },
      );
      await _choose(tester);
      await tester.ensureVisible(
        find.byKey(const ValueKey('apply-playable-start')),
      );
      await tester.tap(find.byKey(const ValueKey('apply-playable-start')));
      await tester.pump();
      expect(calls, 1);
      expect(_apply(tester).onPressed, isNull);
      expect(
        tester
            .widget<StudioSelect>(
              find.byKey(const ValueKey('playable-start-map')),
            )
            .onChanged,
        isNull,
      );
      pending.completeError(StateError('private internal ids'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Le départ adapté n’a pas pu être appliqué. Vérifiez le projet puis réessayez.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('private internal ids'), findsNothing);
      expect(_apply(tester).onPressed, isNotNull);
    },
  );

  testWidgets(
    'search preserves explicit choices and only supplied species are offered',
    (tester) async {
      await _pump(tester);
      await _starter(tester, 'species-a');
      final search = find.descendant(
        of: find.byKey(const ValueKey('playable-start-species-search')),
        matching: find.byType(TextField),
      );
      await tester.enterText(search, 'Cara');
      await tester.pump();
      expect(
        find.byKey(const ValueKey('playable-starter-species-a')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('playable-starter-species-c')),
        findsOneWidget,
      );
      await _starter(tester, 'species-c');
      await tester.enterText(search, '');
      await tester.pump();
      expect(
        tester
            .widget<StudioToggleRow>(
              find.byKey(const ValueKey('playable-starter-species-a')),
            )
            .value,
        isTrue,
      );
      expect(find.text('2 starters sélectionnés'), findsOneWidget);
      expect(find.text('Bulbizarre, Carapuce'), findsOneWidget);
      expect(find.text('species-a'), findsNothing);
    },
  );

  testWidgets(
    'insufficient native choices and configured projects have truthful states',
    (tester) async {
      await _pump(
        tester,
        species: const [
          ConverterPlayableStartSpecies(id: 'species-a', name: 'Bulbizarre'),
        ],
      );
      expect(
        find.text(
          'Deux espèces natives disponibles au minimum sont nécessaires.',
        ),
        findsOneWidget,
      );
      expect(_apply(tester).onPressed, isNull);
      await _pump(tester, configured: true);
      expect(
        find.text(
          'Un départ adapté est déjà configuré. Le parcours reste à tester dans le Player.',
        ),
        findsOneWidget,
      );
      expect(_apply(tester).onPressed, isNull);
    },
  );

  testWidgets(
    'a fresh revision discards previous choices and a stale pending success',
    (tester) async {
      final pending = Completer<void>();
      await _pump(
        tester,
        onApply: ({
          required mapId,
          required spawnId,
          required starterSpeciesIds,
          required starterLevel,
        }) => pending.future,
      );
      await _choose(tester);
      await tester.ensureVisible(
        find.byKey(const ValueKey('apply-playable-start')),
      );
      await tester.tap(find.byKey(const ValueKey('apply-playable-start')));
      await tester.pump();
      await _pump(tester, revision: 'revision-two');
      pending.complete();
      await tester.pumpAndSettle();
      expect(_apply(tester).onPressed, isNull);
      expect(find.text('0 starters sélectionnés'), findsOneWidget);
      expect(
        find.text(
          'Départ adapté appliqué. Le parcours reste à tester dans le Player.',
        ),
        findsNothing,
      );
      expect(
        tester
            .widget<StudioSelect>(
              find.byKey(const ValueKey('playable-start-map')),
            )
            .value,
        isNull,
      );
    },
  );

  testWidgets(
    'six selected starters prevent extra selection until one is removed',
    (tester) async {
      await _pump(
        tester,
        species: List.generate(
          7,
          (index) => ConverterPlayableStartSpecies(
            id: 'species-$index',
            name: 'Espèce ${index + 1}',
          ),
        ),
      );
      for (var index = 0; index < 6; index++) {
        await _starter(tester, 'species-$index');
      }
      final seventh = find.byKey(const ValueKey('playable-starter-species-6'));
      expect(tester.widget<StudioToggleRow>(seventh).onChanged, isNull);
      await _starter(tester, 'species-0');
      expect(tester.widget<StudioToggleRow>(seventh).onChanged, isNotNull);
    },
  );
}

Future<void> _pump(
  WidgetTester tester, {
  ConverterPlayableStartApply? onApply,
  List<ConverterPlayableStartSpecies>? species,
  bool configured = false,
  String revision = 'revision-one',
}) async {
  tester.view.physicalSize = const Size(1200, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: ConverterPlayableStartSetup(
            key: const ValueKey('playable-start-setup'),
            inspection: ConverterPlayableStartInspection(
              revision: revision,
              configured: configured,
              maps: [
                ConverterPlayableStartMap(
                  id: 'town',
                  name: 'Bourg Palette',
                  spawns: const [
                    ConverterPlayableStartSpawn(
                      id: 'square',
                      name: 'Place du village',
                    ),
                  ],
                ),
                ConverterPlayableStartMap(
                  id: 'forest',
                  name: 'Forêt',
                  spawns: const [
                    ConverterPlayableStartSpawn(
                      id: 'clearing',
                      name: 'Clairière',
                    ),
                  ],
                ),
              ],
              avatars: const [
                ConverterPlayableStartAvatar(id: 'avatar', name: 'Camille'),
              ],
              species:
                  species ??
                  const [
                    ConverterPlayableStartSpecies(
                      id: 'species-a',
                      name: 'Bulbizarre',
                    ),
                    ConverterPlayableStartSpecies(
                      id: 'species-b',
                      name: 'Salamèche',
                    ),
                    ConverterPlayableStartSpecies(
                      id: 'species-c',
                      name: 'Carapuce',
                    ),
                  ],
            ),
            onApply:
                onApply ??
                ({
                  required mapId,
                  required spawnId,
                  required starterSpeciesIds,
                  required starterLevel,
                }) async {},
          ),
        ),
      ),
    ),
  );
}

StudioButton _apply(WidgetTester tester) => tester.widget<StudioButton>(
  find.byKey(const ValueKey('apply-playable-start')),
);

void _select(WidgetTester tester, String key, String value) =>
    tester.widget<StudioSelect>(find.byKey(ValueKey(key))).onChanged!(value);

Future<void> _selectVisible(
  WidgetTester tester,
  String key,
  String label,
) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _starter(WidgetTester tester, String id) async {
  final target = find.byKey(ValueKey('playable-starter-$id'));
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester) async {
  _select(tester, 'playable-start-map', 'town');
  await tester.pump();
  _select(tester, 'playable-start-spawn', 'square');
  await tester.pump();
  await _starter(tester, 'species-a');
  await _starter(tester, 'species-c');
}
