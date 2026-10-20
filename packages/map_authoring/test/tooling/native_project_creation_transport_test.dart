import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/workspace/project_creation_kit.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory root, outside;
  late NativeProjectCreationTransport transport;
  late JsonlWorker worker;
  late Map<String, dynamic> source;
  late NativeProjectCreationInput input;
  late File descriptor, blob;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('native-transport-');
    root = Directory(await root.resolveSymbolicLinks());
    outside = await Directory.systemTemp.createTemp('native-outside-');
    outside = Directory(await outside.resolveSymbolicLinks());
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path],
        fileReader: const LocalProjectFileReader());
    transport = NativeProjectCreationTransport(policy: policy);
    final handles = WorkspaceHandleStore();
    worker = JsonlWorker(
        api: AuthoringReadApi(
            openService: ProjectOpenService(
                policy: policy,
                fileReader: const LocalProjectFileReader(),
                handles: handles),
            snapshotLoader: ProjectSnapshotLoader(handles: handles)),
        nativeProjectCreation: transport);
    final kit = buildProjectCreationKit(ProjectCreationRequest(
        name: 'Native transport',
        folderName: 'target',
        parentPath: root.path,
        template: ProjectCreationTemplate.playable));
    final catalog = AssetCatalog.fromJson(
        jsonDecode(utf8.decode(kit.files['assets/.pokemap-assets.json']!))
            as Map<String, dynamic>);
    final ref = catalog.records.single.artifact;
    final bytes = kit.files['assets/starter.png']!;
    input = NativeProjectCreationInput(
        manifest: kit.manifest,
        maps: [
          MapData.fromJson(
              jsonDecode(utf8.decode(kit.files['maps/first-map.json']!))
                  as Map<String, dynamic>)
        ],
        assetCatalog: catalog,
        artifacts: [
          NativeProjectCreationArtifact(reference: ref, bytes: bytes)
        ]);
    blob = File(p.join(root.path, 'atlas.png'));
    await blob.writeAsBytes(bytes);
    descriptor = File(p.join(root.path, 'native-source.json'));
    await descriptor.writeAsString(jsonEncode({
      'kind': 'nativeProjectCreationSource',
      'schemaVersion': 1,
      'input': {
        ...input.toJson(),
        'artifacts': [
          {
            'reference': ref.toJson(),
            'source': {
              'relativePath': 'atlas.png',
              'sha256': crypto.sha256.convert(bytes).toString(),
              'byteLength': bytes.length
            }
          }
        ]
      },
    }));
    final descriptorBytes = await descriptor.readAsBytes();
    source = {
      'descriptorPath': descriptor.path,
      'sha256': crypto.sha256.convert(descriptorBytes).toString(),
      'byteLength': descriptorBytes.length
    };
  });
  tearDown(() async {
    await worker.close();
    await root.delete(recursive: true);
    await outside.delete(recursive: true);
  });

  Future<Map<String, Object?>> plan(Map<String, Object?> prepared,
          {String folder = 'target', String? parent}) =>
      transport.plan({
        'preparedHandle': prepared['preparedHandle'],
        'expectedInventoryFingerprint': prepared['inventoryFingerprint'],
        'parentPath': parent ?? root.path,
        'folderName': folder,
      });
  Future<Map<String, Object?>> publish(Map<String, Object?> planned) =>
      transport.publish({
        'planHandle': planned['planHandle'],
        'expectedInventoryFingerprint': planned['inventoryFingerprint'],
      });
  Matcher refused(String code) => throwsA(isA<ProjectCreationException>()
      .having((error) => error.code, 'code', 'native_creation.$code'));

  test('direct API and JSONL publish identical prepared native inventories',
      () async {
    final service = NativeProjectCreationService();
    final direct = await service.prepare(input);
    final prepared = await transport.prepare(source);
    expect(prepared['inventoryFingerprint'], direct.inventoryFingerprint);
    expect(Directory(p.join(root.path, 'target')).existsSync(), isFalse);
    final planned = await plan(prepared);
    final result = await publish(planned);
    expect(result['inventoryFingerprint'], direct.inventoryFingerprint);
    final receipt = result['transactionReceipt'] as Map;
    expect(receipt['beforeRevision'], planned['beforeRevision']);
    expect(receipt['afterRevision'], planned['afterRevision']);
    expect((receipt['extensions'] as Map)['planId'], planned['planId']);
    expect(planned['diff'], isA<Map>());
    expect(
        File(p.join(result['projectPath'] as String, 'assets/starter.png'))
            .readAsBytesSync(),
        await blob.readAsBytes());
    final opener = ProjectOpenService(
        policy: await WorkspacePolicy.create(
            allowedRootPaths: [root.path],
            fileReader: const LocalProjectFileReader()),
        fileReader: const LocalProjectFileReader(),
        handles: WorkspaceHandleStore());
    final opened = await opener.openProject(result['projectPath'] as String);
    expect(opened.projectName, input.manifest.name);
    opener.closeWorkspace(opened.workspaceHandle);
  });
  test(
      'JSONL discovers and executes the same witnessed prepare plan publish contract',
      () async {
    var id = 0;
    Future<Map<String, dynamic>> call(
        String command, Map<String, Object?> args) async {
      final result = jsonDecode(await worker.processLine(jsonEncode({
        'id': 'native-${id++}',
        'command': command,
        'args': args,
      }))) as Map<String, dynamic>;
      expect(result['status'], 'success', reason: jsonEncode(result));
      return Map<String, dynamic>.from(result['data'] as Map);
    }

    final catalog = await call('describe', {});
    expect(
        (catalog['commands'] as List).where((row) =>
            (row as Map)['actionId'] == 'project.create_prepared_native'),
        hasLength(4));
    expect(jsonEncode(source).length, lessThan(512));
    final prepared = await call('project_native_prepare', {'source': source});
    final planned = await call('project_native_plan', {
      'preparedHandle': prepared['preparedHandle'],
      'expectedInventoryFingerprint': prepared['inventoryFingerprint'],
      'parentPath': root.path,
      'folderName': 'jsonl',
    });
    final receipt = await call('project_native_publish', {
      'planHandle': planned['planHandle'],
      'expectedInventoryFingerprint': planned['inventoryFingerprint'],
    });
    expect(receipt['inventoryFingerprint'], prepared['inventoryFingerprint']);
    expect(receipt['transactionReceipt'], isA<Map>());
    expect(File(p.join(root.path, 'jsonl', 'maps/first-map.json')).existsSync(),
        isTrue);
  });
  for (final stage in ['plan', 'publish']) {
    for (final target in ['descriptor', 'blob']) {
      test('changed $target is refused at $stage without a destination',
          () async {
        final prepared = await transport.prepare(source);
        final planned = stage == 'publish' ? await plan(prepared) : null;
        final file = target == 'descriptor' ? descriptor : blob;
        final bytes = await file.readAsBytes();
        bytes[bytes.length - 1] ^= 1;
        await file.writeAsBytes(bytes);
        await expectLater(stage == 'plan' ? plan(prepared) : publish(planned!),
            refused('source_changed'));
        expect(Directory(p.join(root.path, 'target')).existsSync(), isFalse);
      });
    }
  }
  test('cross-root descriptor and cross-root destination are rejected',
      () async {
    final copied = File(p.join(outside.path, 'source.json'));
    await copied.writeAsBytes(await descriptor.readAsBytes());
    await expectLater(
        transport.prepare({...source, 'descriptorPath': copied.path}),
        throwsA(isA<WorkspaceAccessException>()));
    final prepared = await transport.prepare(source);
    await expectLater(plan(prepared, parent: outside.path),
        throwsA(isA<WorkspaceAccessException>()));
  });
  test('symlink blob to another root and relative traversal are rejected',
      () async {
    final copied = File(p.join(outside.path, 'atlas.png'));
    await copied.writeAsBytes(await blob.readAsBytes());
    await blob.delete();
    await Link(blob.path).create(copied.path);
    await expectLater(transport.prepare(source), refused('source_path'));
  });
  test('descriptor witness mismatch is rejected before native preparation',
      () async {
    await expectLater(transport.prepare({...source, 'sha256': '0' * 64}),
        refused('source_changed'));
  });
  test('oversized cumulative source inventory is rejected before reading blobs',
      () async {
    final json =
        jsonDecode(await descriptor.readAsString()) as Map<String, dynamic>;
    final row = ((json['input'] as Map)['artifacts'] as List).single as Map;
    (row['source'] as Map)['byteLength'] = nativeProjectCreationMaxBytes;
    final ref = row['reference'] as Map;
    ref['byteLength'] = nativeProjectCreationMaxBytes;
    await descriptor.writeAsString(jsonEncode(json));
    final bytes = await descriptor.readAsBytes();
    await blob.delete();
    await expectLater(
        transport.prepare({
          ...source,
          'byteLength': bytes.length,
          'sha256': crypto.sha256.convert(bytes).toString()
        }),
        refused('source_budget'));
  });
  test('relative traversal and arbitrary output fields are refused', () async {
    final json =
        jsonDecode(await descriptor.readAsString()) as Map<String, dynamic>;
    final row = ((json['input'] as Map)['artifacts'] as List).single as Map;
    (row['source'] as Map)['relativePath'] = '../outside/atlas.png';
    await descriptor.writeAsString(jsonEncode(json));
    var bytes = await descriptor.readAsBytes();
    await expectLater(
        transport.prepare({
          ...source,
          'byteLength': bytes.length,
          'sha256': crypto.sha256.convert(bytes).toString()
        }),
        refused('source_path'));
    (row['source'] as Map)['relativePath'] = 'atlas.png';
    (json['input'] as Map)['arbitraryOutputs'] = {
      'escape.json': {'value': true}
    };
    await descriptor.writeAsString(jsonEncode(json));
    bytes = await descriptor.readAsBytes();
    await expectLater(
        transport.prepare({
          ...source,
          'byteLength': bytes.length,
          'sha256': crypto.sha256.convert(bytes).toString()
        }),
        throwsFormatException);
    expect(Directory(p.join(root.path, 'target')).existsSync(), isFalse);
  });
  test('source blob cannot impersonate a different content reference',
      () async {
    final json =
        jsonDecode(await descriptor.readAsString()) as Map<String, dynamic>;
    final row = ((json['input'] as Map)['artifacts'] as List).single as Map;
    final changed = await blob.readAsBytes();
    changed[changed.length - 1] ^= 1;
    await blob.writeAsBytes(changed);
    (row['source'] as Map)['sha256'] =
        crypto.sha256.convert(changed).toString();
    await descriptor.writeAsString(jsonEncode(json));
    final bytes = await descriptor.readAsBytes();
    await expectLater(
        transport.prepare({
          ...source,
          'byteLength': bytes.length,
          'sha256': crypto.sha256.convert(bytes).toString()
        }),
        throwsFormatException);
  });
  test('canonical replay returns its receipt and rejects changed output bytes',
      () async {
    final prepared = await transport.prepare(source);
    final planned = await plan(prepared);
    final first = await publish(planned);
    final replay = await publish(planned);
    expect(replay['transactionReceipt'], first['transactionReceipt']);
    await File(p.join(root.path, 'target', 'assets', 'starter.png'))
        .writeAsBytes([1, 2, 3]);
    await expectLater(
        publish(planned),
        throwsA(isA<ProjectCreationException>()
            .having((error) => error.code, 'code', 'project.replay_changed')));
  });
  test(
      'cancellation before publication writes nothing and keeps the plan usable',
      () async {
    final prepared = await transport.prepare(source);
    final planned = await plan(prepared);
    await expectLater(
        transport.publish({
          'planHandle': planned['planHandle'],
          'expectedInventoryFingerprint': planned['inventoryFingerprint']
        }, isCancelled: () => true),
        throwsA(isA<ProjectCreationCancelled>()));
    expect(Directory(p.join(root.path, 'target')).existsSync(), isFalse);
    await publish(planned);
  });
  test('session budgets and release keep preparation handles bounded',
      () async {
    final first = await transport.prepare(source);
    await transport.prepare(source);
    await expectLater(transport.prepare(source), refused('session_budget'));
    transport.release(first['preparedHandle'] as String);
    await transport.prepare(source);
  });
  test('session handles cannot be reconstructed in another transport',
      () async {
    final prepared = await transport.prepare(source);
    final other = NativeProjectCreationTransport(
        policy: await WorkspacePolicy.create(
            allowedRootPaths: [root.path],
            fileReader: const LocalProjectFileReader()));
    try {
      await expectLater(
          other.plan({
            'preparedHandle': prepared['preparedHandle'],
            'expectedInventoryFingerprint': prepared['inventoryFingerprint'],
            'parentPath': root.path,
            'folderName': 'other'
          }),
          refused('prepared_unknown'));
    } finally {
      other.close();
    }
  });
  test('fingerprint change release and existing destination cannot publish',
      () async {
    final prepared = await transport.prepare(source);
    await expectLater(
        transport.plan({
          'preparedHandle': prepared['preparedHandle'],
          'expectedInventoryFingerprint': 'forged',
          'parentPath': root.path,
          'folderName': 'target'
        }),
        refused('inventory_changed'));
    final planned = await plan(prepared);
    await Directory(p.join(root.path, 'target')).create();
    await File(p.join(root.path, 'target', 'keep')).writeAsString('keep');
    await expectLater(
        publish(planned), throwsA(isA<ProjectCreationException>()));
    expect(
        File(p.join(root.path, 'target', 'keep')).readAsStringSync(), 'keep');
    transport.release(prepared['preparedHandle'] as String);
    await expectLater(plan(prepared), refused('prepared_unknown'));
  });
}
