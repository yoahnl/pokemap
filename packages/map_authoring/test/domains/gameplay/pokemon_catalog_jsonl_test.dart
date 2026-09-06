import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Pokemon document transport parity', () {
    test(
        'adds catalog entries without resending or modifying existing definitions',
        () async {
      final harness = await _PokemonTransportHarness.create('catalog-add');
      addTearDown(harness.dispose);
      final manifestFile = File('${harness.root.path}/project.json');
      final manifest =
          jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
      (manifest['pokemon'] as Map)['enabled'] = true;
      await manifestFile.writeAsString(jsonEncode(manifest));
      final file =
          File('${harness.root.path}/data/pokemon/catalogs/moves.json');
      await file.parent.create(recursive: true);
      final original = {'id': 'tackle', 'power': 40};
      await file.writeAsString(jsonEncode(PokemonCatalogFile.fromJson({
        'schemaVersion': 1,
        'catalog': 'moves',
        'entries': [original]
      }).toJson()));
      final receipt = await harness.writeDirect({
        'addCatalogEntries': {
          'relativePath': 'data/pokemon/catalogs/moves.json',
          'entries': [
            {'id': 'ember', 'power': 40}
          ],
        }
      });
      expect(receipt['actionId'], 'pokemon.catalog.entries.add');
      final entries =
          (jsonDecode(await file.readAsString()) as Map)['entries'] as List;
      expect(entries, [
        original,
        {'id': 'ember', 'power': 40}
      ]);
    });

    test(
        'writes a typed document batch identically through direct API and JSONL',
        () async {
      final direct = await _PokemonTransportHarness.create('batch-direct');
      final jsonl = await _PokemonTransportHarness.create('batch-jsonl');
      addTearDown(direct.dispose);
      addTearDown(jsonl.dispose);
      final batch = _documentBatch();
      final receipt = await direct.writeDirect(batch);
      final wire = await jsonl.writeJsonl(batch);
      expect(receipt['actionId'], 'pokemon.documents.write');
      expect(wire['status'], 'applied');
      expect(await direct.speciesJson(), await jsonl.speciesJson());
      final directEvolution = await File(
              '${direct.root.path}/data/pokemon/evolutions/sproutle.json')
          .readAsString();
      final wireEvolution =
          await File('${jsonl.root.path}/data/pokemon/evolutions/sproutle.json')
              .readAsString();
      expect(directEvolution, wireEvolution);
      expect(((receipt['diff'] as Map)['entries'] as List), hasLength(2));
    });

    test('invalid or duplicate members reject the whole batch before any write',
        () async {
      for (final duplicate in [false, true]) {
        final harness =
            await _PokemonTransportHarness.create('batch-rejected-$duplicate');
        addTearDown(harness.dispose);
        final batch = _documentBatch();
        final members = batch['documents'] as List;
        if (duplicate) {
          members.add(members.first);
        } else {
          (members.last['parameters']['document'] as Map)['schemaVersion'] =
              currentPokemonDataSchemaVersion + 1;
        }
        final result = await harness.writeJsonlResult(batch);
        expect(result.status, AuthoringResultStatus.failure);
        expect(await harness.speciesExists(), isFalse);
        expect(
            await File(
                    '${harness.root.path}/data/pokemon/evolutions/sproutle.json')
                .exists(),
            isFalse);
      }
    });

    test('writes the shared species schema through direct API and JSONL',
        () async {
      final direct = await _PokemonTransportHarness.create('direct');
      final jsonl = await _PokemonTransportHarness.create('jsonl');
      addTearDown(direct.dispose);
      addTearDown(jsonl.dispose);

      final directReceipt = await direct.writeDirect(_speciesDocument());
      final jsonlReceipt = await jsonl.writeJsonl(_speciesDocument());

      expect(directReceipt['actionId'], 'pokemon.species.write');
      expect(jsonlReceipt['actionId'], 'pokemon.species.write');
      expect(directReceipt['status'], 'applied');
      expect(jsonlReceipt['status'], 'applied');
      expect(await direct.speciesJson(), await jsonl.speciesJson());
      expect(
        (await direct.speciesJson())['schemaVersion'],
        currentPokemonDataSchemaVersion,
      );
      expect(
        await direct.speciesJson(),
        PokemonSpeciesFile.fromJson(_speciesDocument()).toJson(),
      );
      expect(
        (await direct.speciesJson()).containsKey('vendorExtension'),
        isFalse,
      );
      expect(_receiptAfter(directReceipt), await direct.speciesJson());
      expect(_receiptAfter(jsonlReceipt), await jsonl.speciesJson());
    });

    test('rejects future species schemas through direct API and JSONL',
        () async {
      final direct = await _PokemonTransportHarness.create('future-direct');
      final jsonl = await _PokemonTransportHarness.create('future-jsonl');
      addTearDown(direct.dispose);
      addTearDown(jsonl.dispose);
      final futureDocument = _speciesDocument()
        ..['schemaVersion'] = currentPokemonDataSchemaVersion + 1;

      await expectLater(
        () => direct.writeDirect(futureDocument),
        throwsFormatException,
      );
      final jsonlResult = await jsonl.writeJsonlResult(futureDocument);

      expect(jsonlResult.status, AuthoringResultStatus.failure);
      expect(await direct.speciesExists(), isFalse);
      expect(await jsonl.speciesExists(), isFalse);
    });

    test('rejects missing species schemas before direct API and JSONL writes',
        () async {
      final direct = await _PokemonTransportHarness.create('missing-direct');
      final jsonl = await _PokemonTransportHarness.create('missing-jsonl');
      addTearDown(direct.dispose);
      addTearDown(jsonl.dispose);
      final missingDocument = _speciesDocument()..remove('schemaVersion');

      await expectLater(
        () => direct.writeDirect(missingDocument),
        throwsFormatException,
      );
      final jsonlResult = await jsonl.writeJsonlResult(missingDocument);

      expect(jsonlResult.status, AuthoringResultStatus.failure);
      expect(await direct.speciesExists(), isFalse);
      expect(await jsonl.speciesExists(), isFalse);
    });
  });
}

Map<String, Object?> _receiptAfter(Map<String, Object?> receipt) {
  final diff = Map<String, Object?>.from(receipt['diff']! as Map);
  final entries = List<Object?>.from(diff['entries']! as List);
  final entry = Map<String, Object?>.from(entries.single! as Map);
  return Map<String, Object?>.from(entry['after']! as Map);
}

Map<String, dynamic> _speciesDocument() => <String, dynamic>{
      'schemaVersion': currentPokemonDataSchemaVersion,
      'id': 'sproutle',
      'typing': <String, Object?>{
        'types': <String>['grass'],
      },
      'baseStats': <String, Object?>{
        'hp': 45,
        'atk': 49,
        'def': 49,
        'spa': 65,
        'spd': 65,
        'spe': 45,
      },
      'abilities': <String, Object?>{'primary': 'overgrow'},
      'progression': <String, Object?>{
        'growthRateId': 'medium_slow',
        'baseExp': 64,
        'catchRate': 45,
      },
      'refs': <String, Object?>{'learnset': 'sproutle'},
      'vendorExtension': true,
    };

Map<String, dynamic> _documentBatch() => {
      'documents': [
        {
          'actionId': 'pokemon.species.write',
          'parameters': {
            'relativePath': 'data/pokemon/species/sproutle.json',
            'document': _speciesDocument(),
          }
        },
        {
          'actionId': 'pokemon.evolution.write',
          'parameters': {
            'relativePath': 'data/pokemon/evolutions/sproutle.json',
            'document': {
              'schemaVersion': 1,
              'speciesId': 'sproutle',
              'evolutions': []
            },
          }
        },
      ],
    };

final class _PokemonTransportHarness {
  _PokemonTransportHarness({
    required this.root,
    required this.readApi,
    required this.mutations,
    required this.snapshots,
    required this.worker,
  });

  final Directory root;
  final AuthoringReadApi readApi;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  final JsonlWorker worker;

  static Future<_PokemonTransportHarness> create(String suffix) async {
    final root = await Directory.systemTemp.createTemp(
      'pokemon-authoring-$suffix-',
    );
    await File('${root.path}/project.json').writeAsString(
      jsonEncode(
        const ProjectManifest(
          name: 'Pokemon transport fixture',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
        ).toJson(),
      ),
    );
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: <String>[root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final readApi = AuthoringReadApi(
      openService: ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ),
      snapshotLoader: snapshots,
    );
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
    );
    return _PokemonTransportHarness(
      root: root,
      readApi: readApi,
      mutations: mutations,
      snapshots: snapshots,
      worker: JsonlWorker(api: readApi, mutations: mutations),
    );
  }

  Future<Map<String, Object?>> writeDirect(
    Map<String, dynamic> document,
  ) async {
    final opened = await readApi.openProject(root.path);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    final snapshot = await snapshots.load(opened.projectHandle);
    final plan = await mutations.plan(
      opened.projectHandle,
      _request(
        workspaceHandle: opened.workspaceHandle.value,
        revision: snapshot.revision,
        document: document,
        suffix: 'direct',
      ),
    );
    final applied = await mutations.apply(
      opened.projectHandle,
      planId: plan['planId']! as String,
      operationId: 'pokemon-species-direct',
    );
    return Map<String, Object?>.from(applied['receipt']! as Map);
  }

  Future<Map<String, Object?>> writeJsonl(
    Map<String, dynamic> document,
  ) async {
    final result = await writeJsonlResult(document);
    expect(result.status, AuthoringResultStatus.success);
    return Map<String, Object?>.from(result.data['receipt']! as Map);
  }

  Future<AuthoringResult> writeJsonlResult(
    Map<String, dynamic> document,
  ) async {
    final opened = await _wireRequest(
      worker,
      'open',
      args: <String, Object?>{'projectRoot': root.path},
    );
    final projectHandle = opened.data['projectHandle']! as String;
    final workspaceHandle = opened.data['workspaceHandle']! as String;
    final snapshot = await snapshots.load(ProjectHandle(projectHandle));
    final plan = await _wireRequest(
      worker,
      'plan',
      args: <String, Object?>{
        'projectHandle': projectHandle,
        'request': _request(
          workspaceHandle: workspaceHandle,
          revision: snapshot.revision,
          document: document,
          suffix: 'jsonl',
        ).toJson(),
      },
    );
    if (plan.status == AuthoringResultStatus.failure) return plan;
    return _wireRequest(
      worker,
      'apply',
      args: <String, Object?>{
        'projectHandle': projectHandle,
        'planId': plan.data['planId'],
        'operationId': 'pokemon-species-jsonl',
      },
    );
  }

  AuthoringRequest _request({
    required String workspaceHandle,
    required String revision,
    required Map<String, dynamic> document,
    required String suffix,
  }) =>
      AuthoringRequest(
        requestId: 'pokemon-species-$suffix',
        actionId: document.containsKey('addCatalogEntries')
            ? 'pokemon.catalog.entries.add'
            : document.containsKey('documents')
                ? 'pokemon.documents.write'
                : 'pokemon.species.write',
        actionVersion: 1,
        workspaceHandle: workspaceHandle,
        parameters: document.containsKey('addCatalogEntries')
            ? Map<String, Object?>.from(document['addCatalogEntries'] as Map)
            : document.containsKey('documents')
                ? document
                : <String, Object?>{
                    'relativePath': 'data/pokemon/species/sproutle.json',
                    'document': document,
                  },
        expectedRevision: revision,
        idempotencyKey: 'pokemon-species-$suffix',
        dryRun: false,
      );

  File get _speciesFile =>
      File('${root.path}/data/pokemon/species/sproutle.json');

  Future<bool> speciesExists() => _speciesFile.exists();

  Future<Map<String, dynamic>> speciesJson() async =>
      jsonDecode(await _speciesFile.readAsString()) as Map<String, dynamic>;

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

Future<AuthoringResult> _wireRequest(
  JsonlWorker worker,
  String command, {
  Map<String, Object?> args = const <String, Object?>{},
}) async {
  final response = await worker.processLine(
    jsonEncode(<String, Object?>{
      'id': 'pokemon-$command',
      'command': command,
      'args': args,
    }),
  );
  return AuthoringResult.fromJson(
    jsonDecode(response) as Map<String, dynamic>,
  );
}
