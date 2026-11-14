import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/pokemon/domain/pokemon_external_import_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'pokemon_external_gen5_import_harness.dart';

void main() {
  setUp(setUpGen5Import);

  tearDown(() async {
    await adapter.close();
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('preview retains the animation for a retained species', () async {
    transport.statusCode = 404;
    final first = await adapter.previewExternal('bulbasaur');
    await adapter.applyExternal(
      first,
      PokemonExternalConflictPolicy.failOnConflict,
    );
    transport.statusCode = 200;
    final species = File('${root.path}/data/pokemon/species/bulbasaur.json');
    final before = await species.readAsBytes();
    final preview = await adapter.previewExternal('bulbasaur');
    final plan = preview.plan(PokemonExternalConflictPolicy.skipExisting);
    expect(plan.selected, isEmpty);
    expect(plan.kept, preview.documents.length);
    expect(preview.gen5Bundle, isNotNull);
    expect(await species.readAsBytes(), before);
  });

  test(
    'does not attach a base animation to a retained alternate form',
    () async {
      transport.statusCode = 404;
      final first = await adapter.previewExternal('bulbasaur');
      await adapter.applyExternal(
        first,
        PokemonExternalConflictPolicy.failOnConflict,
      );
      final speciesFile = File(
        '${root.path}/data/pokemon/species/bulbasaur.json',
      );
      final species = jsonDecode(await speciesFile.readAsString()) as Map;
      (species['forms'] as Map)['isBaseForm'] = false;
      await speciesFile.writeAsString(jsonEncode(species));
      final original = await speciesFile.readAsBytes();
      transport.statusCode = 200;
      final preview = await adapter.previewExternal('bulbasaur');
      final result = await adapter.applyExternal(
        preview,
        PokemonExternalConflictPolicy.skipExisting,
      );
      expect(result.gen5Imported, isFalse);
      expect(await speciesFile.readAsBytes(), original);
      expect(
        await File(
          '${root.path}/${Gen5BattleSourceBinding.bindingPathFor('bulbasaur')}',
        ).exists(),
        isFalse,
      );
    },
  );

  test(
    'does not attach a source to a retained species with a different dex',
    () async {
      transport.statusCode = 404;
      final first = await adapter.previewExternal('bulbasaur');
      await adapter.applyExternal(
        first,
        PokemonExternalConflictPolicy.failOnConflict,
      );
      final species = File('${root.path}/data/pokemon/species/bulbasaur.json');
      final document =
          jsonDecode(await species.readAsString()) as Map<String, dynamic>;
      document['nationalDex'] = 2;
      await species.writeAsString(jsonEncode(document));
      transport.statusCode = 200;
      final preview = await adapter.previewExternal('bulbasaur');
      final result = await adapter.applyExternal(
        preview,
        PokemonExternalConflictPolicy.skipExisting,
      );
      expect(result.gen5Imported, isFalse);
      expect(
        await File(
          '${root.path}/${Gen5BattleSourceBinding.bindingPathFor('bulbasaur')}',
        ).exists(),
        isFalse,
      );
      expect(jsonDecode(await species.readAsString())['nationalDex'], 2);
    },
  );

  test('rejects a stale preview before importing the animation', () async {
    final preview = await adapter.previewExternal('bulbasaur');
    final species = File('${root.path}/data/pokemon/species/bulbasaur.json');
    await species.parent.create(recursive: true);
    await species.writeAsString('{}');
    await expectLater(
      adapter.applyExternal(
        preview,
        PokemonExternalConflictPolicy.failOnConflict,
      ),
      throwsA(anything),
    );
    expect(
      await File(
        '${root.path}/${Gen5BattleSourceBinding.bindingPathFor('bulbasaur')}',
      ).exists(),
      isFalse,
    );
  });

  test(
    'allows replacement of existing documents with the same source',
    () async {
      final first = await adapter.previewExternal('bulbasaur');
      await adapter.applyExternal(
        first,
        PokemonExternalConflictPolicy.failOnConflict,
      );
      final preview = await adapter.previewExternal('bulbasaur');
      final result = await adapter.applyExternal(
        preview,
        PokemonExternalConflictPolicy.overwriteExisting,
      );
      expect(result.overwritten, greaterThan(0));
      expect(result.warnings.join(' '), contains('déjà présente'));
    },
  );

  test(
    'replaces one changed document while keeping identical companions',
    () async {
      final first = await adapter.previewExternal('bulbasaur');
      await adapter.applyExternal(
        first,
        PokemonExternalConflictPolicy.failOnConflict,
      );
      final species = File('${root.path}/data/pokemon/species/bulbasaur.json');
      final document =
          jsonDecode(await species.readAsString()) as Map<String, dynamic>;
      (document['names'] as Map<String, dynamic>)['fr'] = 'Ancien nom';
      await species.writeAsString(jsonEncode(document));
      final preview = await adapter.previewExternal('bulbasaur');
      final result = await adapter.applyExternal(
        preview,
        PokemonExternalConflictPolicy.overwriteExisting,
      );
      expect(result.requiresReopen, isFalse);
      expect(
        (jsonDecode(await species.readAsString())['names'] as Map)['fr'],
        isNot('Ancien nom'),
      );
    },
  );
}
