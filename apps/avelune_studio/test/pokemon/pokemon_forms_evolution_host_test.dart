import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/pokemon/data/local_pokemon_workspace_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_host_fixture.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;

void main() {
  testWidgets('forms and evolution save together without losing old fields', (
    tester,
  ) async {
    final host = await MapHostFixture.open(
      tester,
      prepareSource: (fixture) async {
        for (final (folder, file) in [
          ('species', '0001-bulbasaur.json'),
          ('evolutions', 'bulbasaur.json'),
        ]) {
          final destination = File(
            '${fixture.directory.path}/data/pokemon/$folder/$file',
          );
          final json =
              jsonDecode(await File('$sourcePath/$folder/$file').readAsString())
                  as Map<String, dynamic>;
          json['schemaVersion'] = 1;
          await destination.parent.create(recursive: true);
          await destination.writeAsString(jsonEncode(json));
        }
      },
    );
    await host.go('Pokémon');
    await pumpIo(tester);
    await tester.tap(find.byKey(const ValueKey('species-bulbasaur')));
    await pumpIo(tester);
    await tester.tap(find.text('Formes').last);
    await pumpIo(tester);
    await tester.enterText(
      find.byKey(const ValueKey('species-forms.formName')),
      'Forme du Train',
    );
    await tester.tap(find.text('Évolutions').last);
    await pumpIo(tester);
    final level = find.byKey(const ValueKey('evolution-0-minLevel'));
    await tester.ensureVisible(level);
    await tester.enterText(level, '18');
    await tester.tap(find.text('Enregistrer').first);
    await pumpIo(tester);
    final bundle = (await tester.runAsync(() async {
      final adapter = LocalPokemonWorkspaceAdapter(
        session: host.source.session,
        mapAdapter: host.source.maps,
      );
      final entry = (await adapter.loadIndex()).entries.single;
      return adapter.loadSpecies(entry);
    }))!;
    final species = bundle.species.document!;
    final evolution = bundle.evolution!.document!;
    expect((species['forms'] as Map)['formName'], 'Forme du Train');
    expect((species['baseStats'] as Map)['hp'], 45);
    final target = (evolution['evolutions'] as List).single as Map;
    expect(target['minLevel'], 18);
    expect(target['method'], 'level_up');
    expect((target['conditionText'] as Map)['fr'], 'Evolue au niveau 16');
    expect(tester.takeException(), isNull);
  });
}

const sourcePath =
    '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10';
