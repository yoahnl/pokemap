import 'dart:convert';
import 'dart:io';
import 'package:avelune_studio/features/pokemon/domain/pokemon_external_import_models.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'pokemon_external_gen5_import_harness.dart';

void main() {
  setUp(setUpGen5Import);

  tearDown(() async {
    await adapter.close();
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('previews without writes and imports one verified animation', () async {
    final bindingPath = Gen5BattleSourceBinding.bindingPathFor('bulbasaur');
    final bindingFile = File('${root.path}/$bindingPath');
    final speciesFile = File(
      '${root.path}/data/pokemon/species/bulbasaur.json',
    );
    final preview = await adapter.previewExternal('bulbasaur');
    expect(preview.gen5Bundle, isNotNull);
    expect(await speciesFile.exists(), isFalse);
    expect(await bindingFile.exists(), isFalse);
    expect(transport.calls, 1);

    final result = await adapter.applyExternal(
      preview,
      PokemonExternalConflictPolicy.failOnConflict,
    );
    expect(result.gen5Imported, isTrue);
    expect(transport.calls, 1);
    final bindingBytes = await bindingFile.readAsBytes();
    final binding = Gen5BattleSourceBinding.decode(
      bindingBytes,
      expectedSha256: sha256.convert(bindingBytes).toString(),
      expectedProjectSpeciesId: 'bulbasaur',
      expectedProjectNationalDex: 1,
    );
    expect(await File('${root.path}/${binding.bundlePath}').exists(), isTrue);
    expect(jsonDecode(await speciesFile.readAsString())['id'], 'bulbasaur');
  });

  test(
    'warns about a missing animation while preserving the species import',
    () async {
      transport.statusCode = 404;
      final preview = await adapter.previewExternal('bulbasaur');
      expect(preview.gen5Bundle, isNull);
      expect(preview.warnings.join(' '), contains('animation'));
      final result = await adapter.applyExternal(
        preview,
        PokemonExternalConflictPolicy.failOnConflict,
      );
      expect(result.gen5Imported, isFalse);
      expect(
        await File('${root.path}/data/pokemon/species/bulbasaur.json').exists(),
        isTrue,
      );
      expect(
        await File(
          '${root.path}/${Gen5BattleSourceBinding.bindingPathFor('bulbasaur')}',
        ).exists(),
        isFalse,
      );
    },
  );

  test(
    'rejects invalid animation data without preventing species import',
    () async {
      transport.invalid = true;
      final preview = await adapter.previewExternal('bulbasaur');
      expect(preview.gen5Bundle, isNull);
      expect(preview.warnings.join(' '), contains('invalide'));
      final result = await adapter.applyExternal(
        preview,
        PokemonExternalConflictPolicy.failOnConflict,
      );
      expect(result.gen5Imported, isFalse);
      expect(
        await File('${root.path}/data/pokemon/species/bulbasaur.json').exists(),
        isTrue,
      );
    },
  );

  test(
    'keeps a different existing animation and reports partial import',
    () async {
      final first = await adapter.previewExternal('bulbasaur');
      expect(
        (await adapter.applyExternal(
          first,
          PokemonExternalConflictPolicy.failOnConflict,
        )).gen5Imported,
        isTrue,
      );
      final bindingFile = File(
        '${root.path}/${Gen5BattleSourceBinding.bindingPathFor('bulbasaur')}',
      );
      final original = await bindingFile.readAsBytes();
      transport.assetOffset = 20;
      final preview = await adapter.previewExternal('bulbasaur');
      final result = await adapter.applyExternal(
        preview,
        PokemonExternalConflictPolicy.overwriteExisting,
      );
      expect(result.gen5Imported, isFalse);
      expect(result.warnings.join(' '), contains('incertain'));
      expect(await bindingFile.readAsBytes(), original);
    },
  );

  test(
    'keeps existing documents and an already imported animation when skipped',
    () async {
      final first = await adapter.previewExternal('bulbasaur');
      await adapter.applyExternal(
        first,
        PokemonExternalConflictPolicy.failOnConflict,
      );
      final speciesFile = File(
        '${root.path}/data/pokemon/species/bulbasaur.json',
      );
      final original = await speciesFile.readAsBytes();
      final preview = await adapter.previewExternal('bulbasaur');
      final result = await adapter.applyExternal(
        preview,
        PokemonExternalConflictPolicy.skipExisting,
      );
      expect(result.gen5Imported, isFalse);
      expect(result.warnings.join(' '), contains('déjà présente'));
      expect(await speciesFile.readAsBytes(), original);
    },
  );

  test(
    'adds a missing animation without replacing a retained species',
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
      (species['names'] as Map)['fr'] = 'Mon Bulbizarre';
      await speciesFile.writeAsString(jsonEncode(species));
      final original = await speciesFile.readAsBytes();
      transport.statusCode = 200;
      final preview = await adapter.previewExternal('bulbasaur');
      final result = await adapter.applyExternal(
        preview,
        PokemonExternalConflictPolicy.skipExisting,
      );
      expect(result.gen5Imported, isTrue);
      expect(result.noChange, isFalse);
      expect(await speciesFile.readAsBytes(), original);
      expect(
        await File(
          '${root.path}/${Gen5BattleSourceBinding.bindingPathFor('bulbasaur')}',
        ).exists(),
        isTrue,
      );
    },
  );
}
