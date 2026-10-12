import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/src/native_project_publication.dart';
import 'package:avelune_converter_adapters/src/native_project_writer.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import 'support/native_writer_fixture.dart';

Future<void> main() async {
  if (Platform.environment['AC15_PUBLICATION_CHILD'] case final String mode) {
    await _crashChild(mode);
    return;
  }
  late Directory root;
  late NativeWriterFixture fixture;
  late NativePublicationPolicy policy;
  NativePublicationJob? job;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('ac15-publication-');
    final output = await Directory('${root.path}/output').create();
    fixture = await NativeWriterFixture.create(output.path,
        sourceRootPath: '${root.path}/source');
    policy = NativePublicationPolicy(
        allowedParentRoots: [output.path],
        sourceRoots: [fixture.sourceRootPath]);
  });

  tearDown(() async {
    await job?.close();
    job = null;
    await root.delete(recursive: true);
  });

  Future<NativeWriteReceipt> write(NativePublicationJob active) =>
      NativeProjectWriter(
              stagingFactory: active.createStaging,
              checkpoint: active.recordWriteCheckpoint)
          .write(fixture.plan, fixture.context, fixture.draft);

  Future<void> verifySource() async {
    for (final entry in fixture.sourceBytes.entries) {
      expect(await File('${fixture.sourceRootPath}/${entry.key}').readAsBytes(),
          entry.value);
    }
  }

  Future<NativePublicationJob> begin(
      {NativePublicationCheckpoint? checkpoint,
      NativePublicationLimits limits = const NativePublicationLimits()}) async {
    final active = await NativeProjectPublication(checkpoint: checkpoint).begin(
        fixture.plan, fixture.context, fixture.draft,
        policy: policy, limits: limits);
    job = active;
    return active;
  }

  test('AC15 publishes actual writer output and reconciles durable receipt',
      () async {
    final active = await begin();
    final staged = await write(active);
    final receipt = await active.publish(
        stagedReceipt: staged,
        readCurrentContext: () async => fixture.context,
        verifySourceUnchanged: verifySource);
    expect(receipt.published, isTrue);
    expect(receipt.projectPath,
        '${await Directory(fixture.draft.parentPath).resolveSymbolicLinks()}/${fixture.draft.folderName}');
    expect(await Directory(staged.projectPath).exists(), isFalse);
    expect(await File('${receipt.projectPath}/project.json').exists(), isTrue);
    expect(receipt.nativeRevision, staged.nativeRevision);
    await active.close();
    final recovered = await const NativeProjectPublication()
        .reconcile(journalPath: receipt.journalPath, policy: policy);
    expect(recovered.state, NativePublicationRecoveryState.published);
    expect(recovered.receipt?.inventoryHash, receipt.inventoryHash);
    await verifySource();
  });

  test('AC15 concurrent destination is never overwritten by promotion',
      () async {
    final active = await begin();
    final staged = await write(active);
    final target = await Directory(active.destinationPath).create();
    final sentinel = File('${target.path}/foreign.bin');
    await sentinel.writeAsBytes([3, 9, 17], flush: true);
    await expectLater(
        active.publish(
            stagedReceipt: staged,
            readCurrentContext: () async => fixture.context,
            verifySourceUnchanged: verifySource),
        throwsA(_failure('publication.destination.exists')));
    expect(await sentinel.readAsBytes(), [3, 9, 17]);
    expect(await Directory(staged.projectPath).exists(), isTrue);
    await verifySource();
  });

  test('AC15 source failure prevents promotion after canonical write',
      () async {
    final active = await begin();
    final staged = await write(active);
    await expectLater(
        active.publish(
            stagedReceipt: staged,
            readCurrentContext: () async => fixture.context,
            verifySourceUnchanged: () async =>
                throw StateError('source changed')),
        throwsA(isA<NativePublicationException>()));
    expect(await Directory(active.destinationPath).exists(), isFalse);
    expect(await Directory(staged.projectPath).exists(), isTrue);
  });

  test('AC15 approval context is read fresh and admission refuses stale source',
      () async {
    final active = await begin();
    final staged = await write(active);
    final context = fixture.context;
    final stale = PlanContext(
        logicalProjectNamespace: context.logicalProjectNamespace,
        sourceSnapshotHash: Sha256Hash('f' * 64),
        sessionId: context.sessionId,
        targetCapabilities: context.targetCapabilities,
        rulesHash: context.rulesHash,
        decisions: context.decisions,
        candidates: context.candidates,
        converterVersion: context.converterVersion,
        approvedPlanHash: context.approvedPlanHash,
        sourceMapIds: context.sourceMapIds,
        sourceEntityIds: context.sourceEntityIds,
        targetEntityIds: context.targetEntityIds,
        actionCapabilities: context.actionCapabilities,
        approvedCandidateHashes: context.approvedCandidateHashes);
    await expectLater(
        active.publish(
            stagedReceipt: staged,
            readCurrentContext: () async => stale,
            verifySourceUnchanged: verifySource),
        throwsA(_failure('publication.admission')));
    expect(await Directory(active.destinationPath).exists(), isFalse);
  });

  test('AC15 changed native map invalidates writer receipt before promotion',
      () async {
    final active = await begin();
    final staged = await write(active);
    final maps = await Directory('${staged.projectPath}/maps').list().toList();
    final map = maps.whereType<File>().first;
    await map.writeAsString('{}', flush: true);
    await expectLater(
        active.publish(
            stagedReceipt: staged,
            readCurrentContext: () async => fixture.context,
            verifySourceUnchanged: verifySource),
        throwsA(isA<NativePublicationException>()));
    expect(await Directory(active.destinationPath).exists(), isFalse);
  });

  test('AC15 sealed auxiliary file cannot change during publication intent',
      () async {
    NativeWriteReceipt? staged;
    final active = await begin(checkpoint: (stage) async {
      if (stage == NativePublicationStage.publishIntentDurable) {
        await File('${staged!.projectPath}/auxiliary.dat')
            .writeAsBytes([8, 8, 8], flush: true);
      }
    });
    staged = await write(active);
    await File('${staged.projectPath}/auxiliary.dat').writeAsBytes([1, 2, 3]);
    await expectLater(
        active.publish(
            stagedReceipt: staged,
            readCurrentContext: () async => fixture.context,
            verifySourceUnchanged: verifySource),
        throwsA(_failure('publication.native.changed')));
    expect(await Directory(active.destinationPath).exists(), isFalse);
  });

  test('AC15 retained asset blob changed after writer cannot be newly sealed',
      () async {
    final active = await begin();
    final staged = await write(active);
    final catalog = AssetCatalog.fromJson(jsonDecode(
        await File('${staged.projectPath}/$assetCatalogStorageKey')
            .readAsString()) as Map<String, dynamic>);
    final record = catalog.require(staged.assetHashes.keys.first);
    final blob =
        File('${staged.projectPath}/${assetBlobStorageKey(record.artifact)}');
    final bytes = await blob.readAsBytes();
    bytes[0] ^= 0xff;
    await blob.writeAsBytes(bytes, flush: true);
    await expectLater(
        active.publish(
            stagedReceipt: staged,
            readCurrentContext: () async => fixture.context,
            verifySourceUnchanged: verifySource),
        throwsA(_failure('publication.native.changed')));
    expect(await Directory(active.destinationPath).exists(), isFalse);
  });

  test('AC15 protected and source-overlapping parents refuse before journaling',
      () async {
    final before = await Directory(fixture.draft.parentPath).list().toList();
    await expectLater(
        const NativeProjectPublication().begin(
            fixture.plan, fixture.context, fixture.draft,
            policy: NativePublicationPolicy(
                allowedParentRoots: [fixture.draft.parentPath],
                sourceRoots: [fixture.sourceRootPath],
                protectedRoots: [fixture.draft.parentPath])),
        throwsA(_failure('publication.destination.protected')));
    await expectLater(
        const NativeProjectPublication().begin(
            fixture.plan, fixture.context, fixture.draft,
            policy: NativePublicationPolicy(
                allowedParentRoots: [fixture.draft.parentPath],
                sourceRoots: [root.path])),
        throwsA(_failure('publication.source.overlap')));
    expect(
        (await Directory(fixture.draft.parentPath).list().toList())
            .map((entry) => entry.path)
            .toList(),
        before.map((entry) => entry.path).toList());
  });

  test('AC15 quota refusal never promotes staging', () async {
    final active =
        await begin(limits: const NativePublicationLimits(maxFiles: 1));
    final staged = await write(active);
    await expectLater(
        active.publish(
            stagedReceipt: staged,
            readCurrentContext: () async => fixture.context,
            verifySourceUnchanged: verifySource),
        throwsA(_failure('publication.quota.inventory')));
    expect(await Directory(active.destinationPath).exists(), isFalse);
  });

  test('AC15 observed free space is checked before journal reservation',
      () async {
    final restricted = NativePublicationPolicy(
        allowedParentRoots: policy.allowedParentRoots,
        sourceRoots: policy.sourceRoots,
        minimumFreeBytes: 9007199254740991);
    await expectLater(
        const NativeProjectPublication().begin(
            fixture.plan, fixture.context, fixture.draft,
            policy: restricted),
        throwsA(_failure('publication.space.insufficient')));
    expect(await Directory(fixture.draft.parentPath).list().toList(), isEmpty);
    await verifySource();
  });

  test('AC15 contradictory policy cannot journal inside the declared source',
      () async {
    final foreign = await Directory('${root.path}/foreign-root').create();
    final draft = copyNativeFixtureDraft(fixture.draft,
        parentPath: fixture.sourceRootPath);
    final approval = approveNativeFixtureDraft(draft);
    final before = (await Directory(fixture.sourceRootPath)
            .list(recursive: true, followLinks: false)
            .toList())
        .map((entry) => entry.path)
        .toList()
      ..sort();
    await expectLater(
        const NativeProjectPublication().begin(
            approval.plan, approval.context, draft,
            policy: NativePublicationPolicy(
                allowedParentRoots: [fixture.sourceRootPath],
                sourceRoots: [foreign.path])),
        throwsA(_failure('publication.source.overlap')));
    final after = (await Directory(fixture.sourceRootPath)
            .list(recursive: true, followLinks: false)
            .toList())
        .map((entry) => entry.path)
        .toList()
      ..sort();
    expect(after, before);
    await verifySource();
  });

  test('AC15 torn post-promotion journal tail repairs only the owned journal',
      () async {
    final active = await begin(checkpoint: (stage) {
      if (stage == NativePublicationStage.promotedBeforeReceipt) {
        throw StateError('receipt interrupted');
      }
    });
    final staged = await write(active);
    await expectLater(
        active.publish(
            stagedReceipt: staged,
            readCurrentContext: () async => fixture.context,
            verifySourceUnchanged: verifySource),
        throwsA(isA<NativePublicationException>().having(
            (error) => error.promotionMayHaveOccurred, 'promoted', isTrue)));
    await active.close();
    await File(active.journalPath)
        .writeAsString('{"torn":', mode: FileMode.append, flush: true);
    final recovered = await const NativeProjectPublication()
        .reconcile(journalPath: active.journalPath, policy: policy);
    expect(recovered.state, NativePublicationRecoveryState.published);
    final records = await File(active.journalPath).readAsLines();
    expect((jsonDecode(records.last) as Map)['state'], 'published');
    expect(
        await File('${active.destinationPath}/project.json').exists(), isTrue);
    await verifySource();
  });

  test('AC15 destination symlink refuses promotion and preserves the source',
      () async {
    final active = await begin(checkpoint: (stage) async {
      if (stage == NativePublicationStage.publishIntentDurable) {
        await Link('${fixture.draft.parentPath}/${fixture.draft.folderName}')
            .create(fixture.sourceRootPath);
      }
    });
    final staged = await write(active);
    await expectLater(
        active.publish(
            stagedReceipt: staged,
            readCurrentContext: () async => fixture.context,
            verifySourceUnchanged: verifySource),
        throwsA(_failure('publication.destination.exists')));
    expect(await Link(active.destinationPath).target(), fixture.sourceRootPath);
    await verifySource();
  });

  test(
      'AC15 reservation callback exposes durable journal before first checkpoint',
      () async {
    String? observed;
    final active = await NativeProjectPublication(
        reservationCheckpoint: (journalPath, destinationPath) async {
      observed = journalPath;
      expect(await File(journalPath).exists(), isTrue);
      expect(await Directory(destinationPath).exists(), isFalse);
    }, checkpoint: (stage) {
      if (stage == NativePublicationStage.journalCreated) {
        expect(observed, isNotNull);
      }
    }).begin(fixture.plan, fixture.context, fixture.draft, policy: policy);
    job = active;
    expect(observed, active.journalPath);
  });

  test(
      'AC15 prepared recovery revalidates auxiliary bytes and refuses tampering',
      () async {
    final active = await begin(checkpoint: (stage) {
      if (stage == NativePublicationStage.nativeSealed) {
        throw StateError('interrupt');
      }
    });
    final staged = await write(active);
    await File('${staged.projectPath}/auxiliary.dat').writeAsBytes([1, 2, 3]);
    await expectLater(
        active.publish(
            stagedReceipt: staged,
            readCurrentContext: () async => fixture.context,
            verifySourceUnchanged: verifySource),
        throwsA(isA<NativePublicationException>()));
    await active.close();
    final prepared = await const NativeProjectPublication()
        .reconcile(journalPath: active.journalPath, policy: policy);
    expect(prepared.state, NativePublicationRecoveryState.prepared);
    await File('${staged.projectPath}/auxiliary.dat').writeAsBytes([8, 8, 8]);
    final changed = await const NativeProjectPublication()
        .reconcile(journalPath: active.journalPath, policy: policy);
    expect(changed.state, NativePublicationRecoveryState.corrupt);
    expect(await Directory(active.destinationPath).exists(), isFalse);
  });

  test(
      'AC15 target created at final intent reaches exclusive rename without overwrite',
      () async {
    final active = await begin(checkpoint: (stage) async {
      if (stage == NativePublicationStage.publishIntentDurable) {
        final foreign = await Directory(
                '${await Directory(fixture.draft.parentPath).resolveSymbolicLinks()}/${fixture.draft.folderName}')
            .create();
        await File('${foreign.path}/sentinel').writeAsBytes([42], flush: true);
      }
    });
    final staged = await write(active);
    await expectLater(
        active.publish(
            stagedReceipt: staged,
            readCurrentContext: () async => fixture.context,
            verifySourceUnchanged: verifySource),
        throwsA(_failure('publication.destination.exists')));
    expect(
        await File('${active.destinationPath}/sentinel').readAsBytes(), [42]);
    expect(await Directory(staged.projectPath).exists(), isTrue);
  });

  for (final stage in [
    NativePublicationStage.beforeStage,
    NativePublicationStage.beforeBootstrap,
    NativePublicationStage.publishIntentDurable,
    NativePublicationStage.promotedBeforeReceipt
  ]) {
    test('AC15 subprocess crash at ${stage.name} reconciles without replay',
        () async {
      final childRoot = await Directory('${root.path}/crash').create();
      final result = await Process.run(Platform.resolvedExecutable,
          ['test/native_project_publication_test.dart'],
          workingDirectory: Directory.current.path,
          environment: {
            'AC15_PUBLICATION_CHILD': stage.name,
            'AC15_PUBLICATION_ROOT': childRoot.path
          });
      expect(result.exitCode, isNot(0),
          reason: '${result.stdout} ${result.stderr}');
      final descriptor = jsonDecode(
              await File('${childRoot.path}/descriptor.json').readAsString())
          as Map;
      final recovery = await const NativeProjectPublication().reconcile(
          journalPath: descriptor['journalPath'] as String,
          policy: NativePublicationPolicy(
              allowedParentRoots: ['${childRoot.path}/output'],
              sourceRoots: ['${childRoot.path}/source']));
      expect(
          recovery.state,
          switch (stage) {
            NativePublicationStage.promotedBeforeReceipt =>
              NativePublicationRecoveryState.published,
            NativePublicationStage.publishIntentDurable =>
              NativePublicationRecoveryState.prepared,
            _ => NativePublicationRecoveryState.incomplete,
          });
      expect(await Directory(descriptor['destinationPath'] as String).exists(),
          stage == NativePublicationStage.promotedBeforeReceipt);
      for (final entry in (descriptor['sourceHashes'] as Map).entries) {
        expect(
            nativeFixtureHash(
                    await File('${childRoot.path}/source/${entry.key}')
                        .readAsBytes())
                .value,
            entry.value);
      }
    }, timeout: const Timeout(Duration(seconds: 45)));
  }
}

Matcher _failure(String code) => isA<NativePublicationException>()
    .having((error) => error.code, 'code', code);

Future<void> _crashChild(String mode) async {
  final root = Platform.environment['AC15_PUBLICATION_ROOT']!;
  final output = await Directory('$root/output').create();
  final fixture = await NativeWriterFixture.create(output.path,
      sourceRootPath: '$root/source');
  late NativePublicationJob job;
  final publication = NativeProjectPublication(checkpoint: (stage) async {
    if (stage.name != mode) return;
    await File('$root/descriptor.json').writeAsString(
        jsonEncode({
          'journalPath': job.journalPath,
          'destinationPath': job.destinationPath,
          'childPid': pid,
          'sourceHashes': {
            for (final entry in fixture.sourceBytes.entries)
              entry.key: nativeFixtureHash(entry.value).value
          },
        }),
        flush: true);
    Process.killPid(pid, ProcessSignal.sigkill);
    await Future<void>.delayed(const Duration(seconds: 30));
  });
  job = await publication.begin(fixture.plan, fixture.context, fixture.draft,
      policy: NativePublicationPolicy(
          allowedParentRoots: [output.path],
          sourceRoots: [fixture.sourceRootPath]));
  final receipt = await NativeProjectWriter(
          stagingFactory: job.createStaging,
          checkpoint: job.recordWriteCheckpoint)
      .write(fixture.plan, fixture.context, fixture.draft);
  await job.publish(
      stagedReceipt: receipt,
      readCurrentContext: () async => fixture.context,
      verifySourceUnchanged: () async {
        for (final entry in fixture.sourceBytes.entries) {
          if (!const ListEquality().equals(
              await File('${fixture.sourceRootPath}/${entry.key}')
                  .readAsBytes(),
              entry.value)) {
            throw StateError('source changed');
          }
        }
      });
  throw StateError('Expected crash checkpoint was not reached');
}

final class ListEquality {
  const ListEquality();
  bool equals(List<int> left, List<int> right) =>
      left.length == right.length &&
      Iterable<int>.generate(left.length).every((i) => left[i] == right[i]);
}
