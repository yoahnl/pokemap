import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/workspace/project_creation_kit.dart';
import 'package:test/test.dart';

void main() {
  test('a native creation receipt replays from a legacy unprepared ledger',
      () async {
    final parent = await Directory.systemTemp.createTemp('native-ledger-');
    addTearDown(() => parent.delete(recursive: true));
    final kit = buildProjectCreationKit(ProjectCreationRequest(
        name: 'Native',
        folderName: 'native',
        parentPath: parent.path,
        template: ProjectCreationTemplate.empty));
    final service = NativeProjectCreationService();
    final prepared = await service.prepare(NativeProjectCreationInput(
        manifest: kit.manifest,
        maps: const [],
        assetCatalog: AssetCatalog(records: const [])));
    final plan = await service.plan(
        prepared: prepared, parentPath: parent.path, folderName: 'native');
    final created = await service.publish(plan);
    final records = Directory('${created.projectPath}/.pokemap/authoring');
    final path = '${records.path}/idempotency.jsonl';
    final store = FileIdempotencyStore(filePath: path, incrementalWrites: true);
    final lookup = await store.lookupOperation(
        actorId: 'project-creator',
        projectId: 'project-${plan.operationId}',
        operationId: plan.operationId,
        now: DateTime.now().toUtc());
    final completed = lookup!.completed!;
    expect(completed.receipt!.toJson(), created.transactionReceipt.toJson());

    await records.rename('${parent.path}/scoped-records');
    await records.create();
    final legacy = FileIdempotencyStore(filePath: path);
    await legacy.reserve(AuthoringIdempotencyRecord(
        scope: completed.scope,
        payloadFingerprint: completed.payloadFingerprint,
        operationId: completed.operationId,
        status: AuthoringIdempotencyStatus.pending,
        createdAt: completed.createdAt));
    await legacy.complete(completed);
    final bytes = await File(path).readAsBytes();
    final replay = await service.publish(plan);
    expect(replay.transactionReceipt.toJson(),
        created.transactionReceipt.toJson());
    expect(await File(path).readAsBytes(), bytes);
    expect(await File('$path.incremental').exists(), isFalse);
  });
}
