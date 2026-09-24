import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/pokemon/data/local_pokemon_workspace_adapter.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_host_fixture.dart';
import '../support/capture_m3_widget.dart';
import '../support/load_desktop_capture_fonts.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;

void main() {
  testWidgets(
    'language selection does not write fallbacks and focused edit keeps its key',
    (tester) async {
      await tester.runAsync(loadDesktopCaptureFonts);
      final captureKey = GlobalKey();
      final host = await MapHostFixture.open(
        tester,
        captureKey: captureKey,
        prepareSource: (fixture) async {
          final species =
              jsonDecode(await File(speciesPath).readAsString()) as Map;
          species['schemaVersion'] = 1;
          species['names'] = {'fr': 'Bulbizarre', 'en': 'Bulbasaur'};
          final file = File(
            '${fixture.directory.path}/data/pokemon/species/bulbasaur.json',
          );
          await file.parent.create(recursive: true);
          await file.writeAsString(jsonEncode(species));
        },
      );
      final file = File(
        '${host.source.directory.path}/data/pokemon/species/bulbasaur.json',
      );
      final before = (await tester.runAsync(file.readAsBytes))!;
      await host.go('Pokémon');
      await pumpIo(tester);
      await tester.tap(find.byKey(const ValueKey('species-bulbasaur')));
      await pumpIo(tester);
      final language = find.byWidgetPredicate(
        (widget) =>
            widget is StudioSelect && widget.label == 'Langue d’édition du nom',
      );
      await tester.tap(language);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Japonais (ja)').last);
      await pumpIo(tester);
      expect(find.textContaining('Aucune traduction pour ja'), findsOneWidget);
      await captureM3Widget(tester, captureKey, 'correction-08-langue-absente');
      expect((await tester.runAsync(file.readAsBytes))!, before);
      final field = find.byKey(const ValueKey('species-names.ja'));
      await tester.enterText(field, 'フシギダネ');
      await tester.pump();
      await tester.tap(language);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anglais (en)').last);
      await pumpIo(tester);
      expect(find.byKey(const ValueKey('species-names.en')), findsOneWidget);
      await tester.tap(find.text('Enregistrer').first);
      await pumpIo(tester);
      final adapter = LocalPokemonWorkspaceAdapter(
        session: host.source.session,
        mapAdapter: host.source.maps,
      );
      final entry = (await tester.runAsync(adapter.loadIndex))!.entries.single;
      final reopened = (await tester.runAsync(
        () => adapter.loadSpecies(entry),
      ))!;
      final names = reopened.species.document!['names'] as Map;
      expect(names['fr'], 'Bulbizarre');
      expect(names['en'], 'Bulbasaur');
      expect(names['ja'], 'フシギダネ');
      expect(tester.takeException(), isNull);
    },
  );
}

const speciesPath =
    '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10/species/0001-bulbasaur.json';
