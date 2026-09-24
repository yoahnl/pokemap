import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/presentation/features/pokemon/pokemon_workspace_page.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_host_fixture.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;

void main() {
  testWidgets('disk revision conflict keeps the focused species draft', (
    tester,
  ) async {
    final host = await MapHostFixture.open(
      tester,
      prepareSource: (fixture) async {
        final file = File(
          '${fixture.directory.path}/data/pokemon/species/0001-bulbasaur.json',
        );
        final json =
            jsonDecode(await File(sourcePath).readAsString())
                as Map<String, dynamic>;
        json['schemaVersion'] = 1;
        await file.parent.create(recursive: true);
        await file.writeAsString(jsonEncode(json));
      },
    );
    final file = File(
      '${host.source.directory.path}/data/pokemon/species/0001-bulbasaur.json',
    );
    await host.go('Pokémon');
    await pumpIo(tester);
    await tester.tap(find.byKey(const ValueKey('species-bulbasaur')));
    await pumpIo(tester);
    await tester.enterText(
      find.byKey(const ValueKey('species-names.fr')),
      'Brouillon conservé',
    );
    await tester.pump();
    final changed = (await tester.runAsync(() async {
      final json = jsonDecode(await file.readAsString()) as Map;
      (json['names'] as Map)['fr'] = 'Modification externe';
      await file.writeAsString(jsonEncode(json));
      return file.readAsBytes();
    }))!;
    await tester.tap(find.text('Enregistrer').first);
    await pumpIo(tester);
    final controller = tester
        .widget<PokemonWorkspacePage>(find.byType(PokemonWorkspacePage))
        .controller!;
    expect(find.textContaining('Enregistrement refusé'), findsWidgets);
    expect(controller.selectedDraft?.dirty, isTrue);
    expect(
      (controller.selectedDraft!.document(
            PokemonDocumentFamily.species,
          )!['names']
          as Map)['fr'],
      'Brouillon conservé',
    );
    expect((await tester.runAsync(file.readAsBytes))!, changed);
    expect(tester.takeException(), isNull);
  });
}

const sourcePath =
    '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10/species/0001-bulbasaur.json';
