import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Pokemon document transport parity', () {
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
        actionId: 'pokemon.species.write',
        actionVersion: 1,
        workspaceHandle: workspaceHandle,
        parameters: <String, Object?>{
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
