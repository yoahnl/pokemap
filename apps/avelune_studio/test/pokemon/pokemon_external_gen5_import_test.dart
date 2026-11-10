import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_controller.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_external_import_models.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_port.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../../../packages/map_distribution/test/support/spatial_feature_capabilities_fixture.dart';
import '../support/pokemon_external_source_fixture.dart';

final class _Gen5Transport implements PokemonBoundedExternalHttpTransport {
  int statusCode = 200;
  int calls = 0;
  bool invalid = false;
  int assetOffset = 0;

  @override
  Future<PokemonExternalHttpResponse> getBounded(
    Uri uri, {
    required Map<String, String> headers,
    required int maximumBytes,
    required Duration timeout,
  }) async {
    calls++;
    final assets = <String, Object?>{};
    for (var index = 0; index < gen5BattleBundleAssetNames.length; index++) {
      final bytes = Uint8List.fromList([index + 1 + assetOffset]);
      assets[gen5BattleBundleAssetNames[index]] = {
        'encoding': 'base64',
        'size': bytes.length,
        'sha256': invalid ? '0' * 64 : sha256.convert(bytes).toString(),
        'data': base64Encode(bytes),
      };
    }
    final data = utf8.encode(
      jsonEncode({
        'format': 'gen5-battle-source-v1',
        'game': 'black2-white2',
        'scope': 'default-form',
        'species': 'bulbasaur',
        'nationalDex': 1,
        'reconstruction': 'test',
        'source': {
          'repository': 'fuddlesworth/pokebw2',
          'revision': 'a' * 40,
          'directory': 'res/pokemon/bulbasaur',
          'redistributionStatus': 'test',
        },
        'assets': assets,
      }),
    );
    return PokemonExternalHttpResponse(
      statusCode: statusCode,
      headers: {'x-source-revision': 'a' * 40},
      body: '',
      bodyBytes: Uint8List.fromList(data),
    );
  }
}

final class _UncertainPort implements PokemonWorkspacePort {
  int reads = 0;

  @override
  Future<PokemonExternalImportResult> applyExternal(
    PokemonExternalImportPreview preview,
    PokemonExternalConflictPolicy policy,
  ) async => const PokemonExternalImportResult(
    speciesId: 'bulbasaur',
    created: 1,
    overwritten: 0,
    skipped: 0,
    warnings: ['Animation : état incertain.'],
    requiresReopen: true,
  );

  @override
  Future<PokemonWorkspaceIndex> loadIndex() async {
    reads++;
    throw StateError('catalogue indisponible');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('controller preserves a partial result and asks to reopen', () async {
    final port = _UncertainPort();
    final controller = PokemonWorkspaceController(port, changed: () {});
    controller.externalPreview = const PokemonExternalImportPreview(
      speciesId: 'bulbasaur',
      name: 'Bulbizarre',
      projectRevision: 'r',
      inventorySignature: '',
      documents: [],
      warnings: [],
    );
    expect(
      await controller.applyExternal(
        PokemonExternalConflictPolicy.failOnConflict,
      ),
      isTrue,
    );
    expect(port.reads, 0);
    expect(controller.externalResult?.created, 1);
    expect(controller.error, contains('rouvrez'));
    controller.dispose();
  });

  late Directory root;
  late LocalPokemonWorkspaceAdapter adapter;
  late _Gen5Transport transport;

  setUp(() async {
    final parent = Directory(
      Platform.environment['AVELUNE_QA_ROOT'] ?? '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109',
    );
    await parent.create(recursive: true);
    final temporary = await parent.createTemp('studio-gen5-import-');
    root = Directory(await temporary.resolveSymbolicLinks());
    final files = spatialFeaturePayload('companion');
    final manifest = ProjectManifest.fromJson(
      jsonDecode(utf8.decode(files['project/project.json']!))
          as Map<String, dynamic>,
    );
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    final working = await WorkingProjectCatalog.create(
      store: store,
      projectId: 'studio-gen5-import',
      project: manifest,
    );
    await working.close();
    for (final entry in files.entries) {
      if (entry.key == 'project/project.json') continue;
      final file = File(
        '${root.path}/${entry.key.substring('project/'.length)}',
      );
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value);
    }
    final session = ProjectSession(
      sessionId: 'studio-gen5-import',
      name: 'Studio Gen5 import',
      directoryPath: root.path,
      storage: ProjectSessionStorage.workingCatalog,
    );
    final maps = LocalMapWorkspaceAdapter();
    await maps.loadCatalog(session);
    transport = _Gen5Transport();
    adapter = LocalPokemonWorkspaceAdapter(
      session: session,
      mapAdapter: maps,
      externalSource: const PokemonExternalSourceFixture(),
      gen5Source: AveluneGen5BattleSource(client: transport, release: 'test'),
    );
  });

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
