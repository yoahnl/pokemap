import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/pokemon/application/pokemon_combat_controller.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_combat_adapter.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_combat_table_detail.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/combat_project_fixture.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/m3_story_fixture.dart';
import '../support/ui_pokemon_combat_port.dart';

const _index = PokemonWorkspaceIndex(
  enabled: true,
  entries: [
    PokemonSpeciesSummary(
      id: 'bulbasaur',
      name: 'Bulbizarre',
      nationalDex: 1,
      generation: 1,
      types: ['grass'],
      formIds: [],
      mediaRelativePath: '',
      enabled: true,
      relativePath: 'data/pokemon/species/0001-bulbasaur.json',
    ),
  ],
  types: [],
  items: {},
  moves: PokemonMovesCatalogView(entries: [], relativePath: 'moves.json'),
);

void main() {
  testWidgets(
    'Studio saves and independently reopens two guided encounter variants',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final source = (await tester.runAsync(() async {
        final source = await M3StoryFixture.create();
        await seedCombatProject(source);
        final file = File('${source.directory.path}/project.json');
        final project = ProjectManifest.fromJson(
          jsonDecode(await file.readAsString()) as Map<String, dynamic>,
        );
        await file.writeAsString(
          jsonEncode(
            project
                .copyWith(
                  facts: [
                    ...project.facts,
                    NarrativeFactDefinition(
                      id: 'counter',
                      label: 'Compteur',
                      initialValue: NarrativeValue.integer(0),
                    ),
                    NarrativeFactDefinition(
                      id: 'edition',
                      label: 'Édition du jeu',
                      initialValue: const NarrativeValue.string('or'),
                    ),
                  ],
                )
                .toJson(),
          ),
        );
        return source;
      }))!;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(() => source.directory.delete(recursive: true));
      });
      final local = LocalPokemonCombatAdapter(
        session: source.session,
        mapAdapter: source.maps,
      );
      VoidCallback redraw = () {};
      final combat = PokemonCombatController(
        UiPokemonCombatPort(local, tester),
        changed: () => redraw(),
      );
      addTearDown(combat.dispose);
      await combat.load();
      combat.createTable('Prairie');
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                redraw = () => setState(() {});
                return PokemonCombatTableDetail(
                  combat: combat,
                  index: _index,
                  onDelete: () {},
                );
              },
            ),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('prairie:add-variant')), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('prairie:add-variant')));
      final first = combat.table!.current.variants.single.id;
      await _configure(tester, first, 'Édition Or · nuit', 'or', 20, 4);
      await _tap(
        tester,
        find.byKey(ValueKey('prairie:variant:$first:add-condition')),
      );
      await _select(
        tester,
        'prairie:variant:$first:condition:1:fact',
        'counter',
      );
      await _enter(
        tester,
        'prairie:variant:$first:condition:1:value',
        'incorrect',
      );
      expect(combat.fieldErrors, isNotEmpty);
      await _tap(
        tester,
        find.byKey(ValueKey('prairie:variant:$first:condition:1:remove')),
      );
      expect(combat.fieldErrors, isEmpty);

      await _tap(tester, find.byKey(const ValueKey('prairie:add-variant')));
      expect(combat.table!.current.variants, hasLength(2));
      final second = combat.table!.current.variants.last.id;
      await _configure(
        tester,
        second,
        'Édition Argent · jour',
        'argent',
        4,
        20,
      );
      await _enter(tester, 'prairie:variant:$first:priority', '3');
      await _enter(tester, 'prairie:variant:$second:priority', '4');
      final distinctEnd = tester.widget<StudioSelect>(
        find.byKey(ValueKey('prairie:variant:$first:window:0-end-hour')),
      );
      expect(distinctEnd.options, isNot(contains('20')));
      await _select(tester, 'prairie:variant:$second:window:0-end-hour', '24');
      final lastMinute = tester.widget<StudioSelect>(
        find.byKey(ValueKey('prairie:variant:$second:window:0-end-minute')),
      );
      expect(lastMinute.value, '0');
      expect(lastMinute.onChanged, isNull);
      await _tap(tester, find.text('Enregistrer'));
      await pumpIo(tester);
      expect(combat.error, isNull);
      expect(combat.dirty, isFalse);
      final reopened = (await tester.runAsync(local.load))!
          .project
          .encounterTables
          .singleWhere((table) => table.id == 'prairie');
      expect(reopened.entries, isEmpty);
      expect(reopened.variants.map((variant) => variant.priority), [3, 4]);
      expect(reopened.variants.map((variant) => variant.name), [
        'Édition Or · nuit',
        'Édition Argent · jour',
      ]);
      expect(reopened.variants.first.conditions, [
        ScriptConditionFactory.factEquals(
          'edition',
          const NarrativeValue.string('or'),
        ),
      ]);
      expect(reopened.variants.last.conditions, [
        ScriptConditionFactory.factEquals(
          'edition',
          const NarrativeValue.string('argent'),
        ),
      ]);
      expect(reopened.variants.first.timeWindows, [
        const LocalTimeWindow(startMinute: 1200, endMinute: 240),
      ]);
      expect(reopened.variants.last.timeWindows, [
        const LocalTimeWindow(startMinute: 240, endMinute: 1440),
      ]);
      expect(reopened.allEntries.map((entry) => entry.speciesId), [
        'bulbasaur',
        'bulbasaur',
      ]);
      combat.selectTable(reopened);
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(ValueKey('prairie:variant:$first:name')),
      );
      expect(
        _textField(tester, 'prairie:variant:$first:name').controller!.text,
        'Édition Or · nuit',
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _configure(
  WidgetTester tester,
  String id,
  String name,
  String value,
  int startHour,
  int endHour,
) async {
  final prefix = 'prairie:variant:$id';
  await _enter(tester, '$prefix:name', name);
  await _tap(tester, find.byKey(ValueKey('$prefix:add-condition')));
  await _select(tester, '$prefix:condition:0:fact', 'edition');
  await _enter(tester, '$prefix:condition:0:value', value);
  await _tap(tester, find.byKey(ValueKey('$prefix:add-time-window')));
  await _select(tester, '$prefix:window:0-end-hour', '$endHour');
  await _select(tester, '$prefix:window:0-start-hour', '$startHour');
  await _tap(tester, find.byKey(ValueKey('$prefix:add-species')));
  await _tap(tester, find.text('Bulbizarre').last);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await pumpIo(tester);
}

Future<void> _select(WidgetTester tester, String key, String value) async {
  final finder = find.byKey(ValueKey(key));
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  final widget = tester.widget<StudioSelect>(finder);
  expect(widget.options, contains(value));
  widget.onChanged!(value);
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String key, String value) async {
  final finder = find.descendant(
    of: find.byKey(ValueKey(key)),
    matching: find.byType(TextField),
  );
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.enterText(finder, value);
  await tester.pump();
}

TextField _textField(WidgetTester tester, String key) =>
    tester.widget<TextField>(
      find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(TextField),
      ),
    );
