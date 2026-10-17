import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final jsonl in [false, true]) {
    test('exact duplicate deletion and byte-perfect undo ($jsonl)', () async {
      final h = await _PokemonTransportHarness.create('delete-$jsonl');
      addTearDown(h.dispose);
      final documents = await _seed(h);
      final canonical =
          File('${h.root.path}/data/pokemon/learnsets/alpha.json');
      await canonical.writeAsString('preserve canonical');
      final receipt = jsonl
          ? await h.writeJsonl({'documents': documents})
          : await h.writeDirect({'documents': documents});
      expect(receipt['actionId'], 'pokemon.documents.delete');
      expect(receipt['status'], 'applied');
      for (final document in documents) {
        expect(
            await File(
                    '${h.root.path}/${document['parameters']['relativePath']}')
                .exists(),
            isFalse);
      }
      expect(await canonical.readAsString(), 'preserve canonical');
      final historyLines =
          await File('${h.root.path}/.pokemap/authoring/history.jsonl')
              .readAsLines();
      final entry = historyLines
          .map((line) => jsonDecode(line) as Map)
          .firstWhere((line) => line['type'] == 'append')['payload']['entry'];
      final opened = await _wireRequest(h.worker, 'open',
          args: {'projectRoot': h.root.path});
      final undo = await _wireRequest(h.worker, 'undo', args: {
        'projectHandle': opened.data['projectHandle'],
        'entryId': receipt['receiptId'],
        'idempotencyKey': 'restore'
      });
      expect(undo.status, AuthoringResultStatus.success);
      expect(entry['changes'], hasLength(2));
      for (final document in documents) {
        expect(
            await File(
                    '${h.root.path}/${document['parameters']['relativePath']}')
                .readAsBytes(),
            base64Decode(
                document['parameters']['beforeBytesBase64'] as String));
      }
    });

    test('change after planning rejects the whole deletion ($jsonl)', () async {
      final h =
          await _PokemonTransportHarness.create('delete-after-plan-$jsonl');
      addTearDown(h.dispose);
      final documents = await _seed(h);
      final opened = await _wireRequest(h.worker, 'open',
          args: {'projectRoot': h.root.path});
      final project = opened.data['projectHandle']! as String;
      final snapshot = await h.snapshots.load(ProjectHandle(project));
      final plan = await _wireRequest(h.worker, 'plan', args: {
        'projectHandle': project,
        'request': h
            ._request(
                workspaceHandle: opened.data['workspaceHandle']! as String,
                revision: snapshot.revision,
                document: {'documents': documents},
                suffix: 'changed')
            .toJson()
      });
      expect(plan.status, AuthoringResultStatus.success);
      final confirmed = await _wireRequest(h.worker, 'confirm',
          args: {'projectHandle': project, 'planId': plan.data['planId']});
      final file = File(
          '${h.root.path}/${documents.last['parameters']['relativePath']}');
      await file.writeAsString('{"speciesId":"beta","changed":true}');
      final result = await _wireRequest(h.worker, 'apply', args: {
        'projectHandle': project,
        'planId': plan.data['planId'],
        'operationId': 'changed',
        'confirmationToken': confirmed.data['confirmationToken']
      });
      expect(result.status, AuthoringResultStatus.failure);
      expect(
          await File(
                  '${h.root.path}/${documents.first['parameters']['relativePath']}')
              .exists(),
          isTrue);
      expect(await file.readAsString(), contains('changed'));
    });

    test('invalid or stale member preserves every copy ($jsonl)', () async {
      for (final invalid in [
        'missing',
        'mixed',
        'duplicate',
        'empty',
        'oversized',
        'stale'
      ]) {
        final h =
            await _PokemonTransportHarness.create('delete-$invalid-$jsonl');
        addTearDown(h.dispose);
        final original = await _seed(h);
        final documents = [
          for (final member in original)
            {
              ...member,
              'parameters': {...member['parameters'] as Map}
            }
        ];
        switch (invalid) {
          case 'missing':
            (documents.last['parameters'] as Map).remove('beforeBytesBase64');
          case 'mixed':
            documents.last['actionId'] = 'pokemon.evolution.write';
          case 'duplicate':
            documents.add(documents.first);
          case 'empty':
            documents.clear();
          case 'oversized':
            documents.addAll(List.filled(200, documents.first));
          case 'stale':
            (documents.last['parameters'] as Map)['beforeBytesBase64'] =
                base64Encode(utf8.encode('{"speciesId":"beta","forged":true}'));
        }
        if (jsonl) {
          expect((await h.writeJsonlResult({'documents': documents})).status,
              AuthoringResultStatus.failure);
        } else {
          await expectLater(
              () => h.writeDirect({'documents': documents}), throwsA(anything));
        }
        for (final member in original) {
          expect(
              await File(
                      '${h.root.path}/${member['parameters']['relativePath']}')
                  .readAsBytes(),
              base64Decode(
                  member['parameters']['beforeBytesBase64'] as String));
        }
      }
    });
  }
}

Future<List<Map<String, dynamic>>> _seed(_PokemonTransportHarness h) async {
  final result = <Map<String, dynamic>>[];
  for (final item in [
    ('learnsets', 'learnset', 'alpha'),
    ('evolutions', 'evolution', 'beta')
  ]) {
    final path = 'data/pokemon/${item.$1}/${item.$3} 2.json';
    final bytes =
        utf8.encode('{"speciesId":"${item.$3}","invalidLegacyData":true}\n');
    final file = File('${h.root.path}/$path');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    result.add({
      'actionId': 'pokemon.${item.$2}.delete',
      'parameters': {
        'relativePath': path,
        'resourceId': item.$3,
        'beforeBytesBase64': base64Encode(bytes)
      }
    });
  }
  return result;
}

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
    final confirmation = await mutations.confirm(opened.projectHandle,
        planId: plan['planId']! as String);
    final applied = await mutations.apply(
      opened.projectHandle,
      planId: plan['planId']! as String,
      operationId: 'pokemon-species-direct',
      confirmationToken: confirmation['confirmationToken']! as String,
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
    final confirmed = await _wireRequest(worker, 'confirm',
        args: {'projectHandle': projectHandle, 'planId': plan.data['planId']});
    return _wireRequest(
      worker,
      'apply',
      args: <String, Object?>{
        'projectHandle': projectHandle,
        'planId': plan.data['planId'],
        'operationId': 'pokemon-species-jsonl',
        'confirmationToken': confirmed.data['confirmationToken'],
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
        actionId: document.containsKey('documents')
            ? 'pokemon.documents.delete'
            : document.containsKey('addCatalogEntries')
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
