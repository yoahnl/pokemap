import 'dart:convert';
import 'dart:io';
import 'support/literal_tile_fixture.dart';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart'
    hide PixelSize;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';
import 'source_directed_jump_study_composer_test.dart' show jumpFixture;
import 'support/native_writer_fixture.dart';

void main() {
  test(
      'event composition preserves post-save Border ordering and exact materialization',
      () async {
    final f = await jumpFixture(includeEventSystem: true, events: const [
      LiteralFixtureEvent(
          id: 1,
          x: 0,
          y: 0,
          name: 'HiddenItem Original',
          pages: [
            LiteralFixtureEventPage(commands: [
              LiteralFixtureEventCommand(101, ['Original greeting'])
            ])
          ]),
      LiteralFixtureEvent(id: 2, x: 0, y: 4, pages: [
        LiteralFixtureEventPage(commands: [
          LiteralFixtureEventCommand(355, ['unknown()'])
        ])
      ]),
    ]);
    final base = (await const SourceSemanticStudyComposer().compose(
        source: f.base.draft!.source, base: f.base, files: f.fixture.files))!;
    final events = (await const SourceEventStudyComposer()
        .compose(source: base.source, base: base, files: f.fixture.files))!;
    final ids = events.draft.mutations.map((m) => m.actionId).toList();
    expect(ids.indexOf('border_layer.feature_create'),
        greaterThan(ids.lastIndexOf('map.save')));
    expect(ids.indexOf('border_layer.materialize_apply'),
        lessThan(ids.indexOf('event_v2.record_upsert')));
    expect(
        events.projection.nativeMaps[98]!.layers
            .whereType<BorderLayer>()
            .single
            .content
            .features
            .expand((feature) => feature.materialization!.placements),
        hasLength(3));
  }, skip: Platform.environment['AVELUNE_AC12_SOURCE_SCRIPTS'] == null);
  test(
      'writer rejects an exact-source feature changed to another valid glyph blueprint',
      () async {
    final f = await jumpFixture();
    final draft = (await const SourceSemanticStudyComposer().compose(
        source: f.base.draft!.source, base: f.base, files: f.fixture.files))!;
    final features = draft.mutations
        .where((m) => m.actionId == 'border_layer.feature_create')
        .toList();
    final changed = features.first;
    final tampered = NativeProjectDraft(
        source: draft.source,
        projectName: draft.projectName,
        parentPath: draft.parentPath,
        folderName: draft.folderName,
        mapIds: draft.mapIds,
        artifacts: draft.artifacts,
        sourceArtifacts: draft.sourceArtifacts,
        compositionEvidence: draft.compositionEvidence,
        mutations: [
          for (final m in draft.mutations)
            if (m == changed)
              NativeMutation(
                  operationId: m.operationId,
                  actionId: m.actionId,
                  sourceEntityIds: m.sourceEntityIds,
                  targetEntityIds: m.targetEntityIds,
                  parameters: {
                    ...m.parameters,
                    'blueprintId': features.last.parameters['blueprintId']
                  })
            else
              m
        ],
        defaultMapWidth: draft.defaultMapWidth,
        defaultMapHeight: draft.defaultMapHeight);
    final approval = approveNativeFixtureDraft(tampered);
    await expectLater(
        NativeProjectWriter().write(approval.plan, approval.context, tampered),
        throwsA(isA<NativeWriteException>()
            .having((e) => e.code, 'code', 'native.semantics.regeneration')));
  }, skip: Platform.environment['AVELUNE_AC12_SOURCE_SCRIPTS'] == null);
  test(
      'automatic source Borders survive canonical writer and strict disk reload',
      () async {
    final f = await jumpFixture(useExternalScripts: false);
    final draft = (await const SourceSemanticStudyComposer().compose(
        source: f.base.draft!.source, base: f.base, files: f.fixture.files))!;
    final semantic = draft.compositionEvidence['sourceSemantics'] as Map;
    expect((semantic['directedJumps'] as Map)['importedJumpCount'], 3);
    expect(
        draft.mutations
            .indexWhere((m) => m.actionId == 'border_layer.feature_create'),
        greaterThan(
            draft.mutations.lastIndexWhere((m) => m.actionId == 'map.save')));
    final output =
        await Directory.systemTemp.createTemp('source-border-writer-');
    final rebound = NativeProjectDraft(
        source: draft.source,
        projectName: draft.projectName,
        parentPath: output.path,
        folderName: 'original-borders',
        mapIds: draft.mapIds,
        artifacts: draft.artifacts,
        sourceArtifacts: draft.sourceArtifacts,
        mutations: draft.mutations,
        compositionEvidence: draft.compositionEvidence,
        defaultMapWidth: draft.defaultMapWidth,
        defaultMapHeight: draft.defaultMapHeight);
    final approval = approveNativeFixtureDraft(rebound);
    NativeWriteReceipt? receipt;
    try {
      receipt = await NativeProjectWriter()
          .write(approval.plan, approval.context, rebound);
      expect(receipt.verified, isTrue);
      final handles = WorkspaceHandleStore();
      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
          allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
      final opener = ProjectOpenService(
          policy: policy, fileReader: reader, handles: handles);
      final opened = await opener.openProject(receipt.projectPath);
      try {
        final native = await ProjectSnapshotLoader(handles: handles).load(
            opened.projectHandle,
            policy: ProjectSnapshotLoadPolicy.strict);
        final map = native.maps.single;
        expect(
            map.layers
                .whereType<BorderLayer>()
                .single
                .content
                .features
                .expand((feature) => feature.materialization!.placements),
            hasLength(3));
        expect(native.manifest.borderCatalog.visualSnapshots, hasLength(3));
        final catalog = AssetCatalog.fromJson(jsonDecode(
                utf8.decode(native.resourceBytes(assetCatalogResourceIdentity)))
            as Map<String, dynamic>);
        expect(
            catalog.records.where((record) =>
                record.logicalPath.startsWith('assets/borders/snapshots/')),
            hasLength(3));
        for (final mutation in rebound.mutations
            .where((entry) => entry.actionId == 'tileset.import_image')) {
          final artifact = rebound.artifacts.singleWhere(
              (entry) => entry.handle == mutation.parameters['artifactHandle']);
          final record =
              catalog.require('image_${mutation.parameters['tilesetId']}');
          expect(record.artifact, artifact.reference);
          expect(
              await File('${receipt.projectPath}/${record.logicalPath}')
                  .readAsBytes(),
              artifact.bytes);
          expect(
              await File(
                      '${receipt.projectPath}/${assetBlobStorageKey(record.artifact)}')
                  .readAsBytes(),
              artifact.bytes);
        }

        for (final snapshot in native.manifest.borderCatalog.visualSnapshots) {
          final path = snapshot.frames.single.relativeAssetPath;
          final record = catalog.findByLogicalPath(path)!;
          final bytes =
              await File('${receipt.projectPath}/$path').readAsBytes();
          expect(ContentArtifactRef.fromBytes(bytes, mediaType: 'image/png'),
              record.artifact);
          expect(rebound.artifacts.any((artifact) => artifact.handle == record.artifact.handle),
              isFalse);
          expect(
              await File(
                      '${receipt.projectPath}/${assetBlobStorageKey(record.artifact)}')
                  .readAsBytes(),
              bytes);
        }
        final world = GameplayWorldState.initial(
            map: map,
            project: native.manifest,
            playerPos: const GridPos(x: 2, y: 1),
            tileWidth: 32,
            tileHeight: 32);
        expect(
            stepGameplayWorld(
                world, const MoveIntent(Direction.south, pixelsPerStep: 32)),
            isA<Jumped>());
      } finally {
        opener.closeWorkspace(opened.workspaceHandle);
      }
    } finally {
      if (receipt != null) {
        await Directory(receipt.stagingRoot).delete(recursive: true);
      }
      await output.delete(recursive: true);
    }
  });
  test(
      'Border publication seals distinct snapshot files and recovers published bytes',
      () async {
    final f = await _borderPublication();
    try {
      final receipt = await f.job.publish(
          stagedReceipt: f.staged,
          readCurrentContext: () async => f.approval.context,
          verifySourceUnchanged: f.verifySource);
      final records = (await File(receipt.journalPath).readAsLines())
          .map((line) => jsonDecode(line) as Map)
          .toList();
      expect(records.every((record) => record['version'] == 2), isTrue);
      final seal = records.singleWhere(
          (record) => record['state'] == 'sealed')['payload'] as Map;
      final snapshots = seal['borderSnapshotFiles'] as Map;
      expect(snapshots, hasLength(3));
      final assets = seal['assetHashes'] as Map;
      expect(snapshots.keys.any(assets.containsKey), isFalse);
      for (final entry in snapshots.entries) {
        final bytes =
            await File('${receipt.projectPath}/${entry.key}').readAsBytes();
        expect(entry.value, {
          'byteLength': bytes.length,
          'sha256': nativeFixtureHash(bytes).value
        });
      }
      await f.job.close();
      final recovered = await const NativeProjectPublication()
          .reconcile(journalPath: receipt.journalPath, policy: f.policy);
      expect(recovered.state, NativePublicationRecoveryState.published);
      expect(recovered.receipt!.inventoryHash, receipt.inventoryHash);
      final png = File('${receipt.projectPath}/${snapshots.keys.first}');
      final bytes = await png.readAsBytes();
      bytes[bytes.length - 1] ^= 1;
      await png.writeAsBytes(bytes, flush: true);
      final changed = await const NativeProjectPublication()
          .reconcile(journalPath: receipt.journalPath, policy: f.policy);
      expect(changed.state, NativePublicationRecoveryState.corrupt);
      await f.verifySource();
    } finally {
      await f.job.close();
      await f.root.delete(recursive: true);
    }
  }, skip: Platform.environment['AVELUNE_AC12_SOURCE_SCRIPTS'] == null);
  test(
      'Border prepared recovery refuses a missing snapshot receipt and changed PNG',
      () async {
    final f = await _borderPublication(checkpoint: (stage) {
      if (stage == NativePublicationStage.nativeSealed) {
        throw StateError('owned interruption');
      }
    });
    try {
      await expectLater(
          f.job.publish(
              stagedReceipt: f.staged,
              readCurrentContext: () async => f.approval.context,
              verifySourceUnchanged: f.verifySource),
          throwsA(isA<NativePublicationException>()));
      await f.job.close();
      final prepared = await const NativeProjectPublication()
          .reconcile(journalPath: f.job.journalPath, policy: f.policy);
      expect(prepared.state, NativePublicationRecoveryState.prepared);
      final journal = File(f.job.journalPath);
      final original = await journal.readAsString();
      final records = (await journal.readAsLines())
          .map((line) => jsonDecode(line) as Map<String, dynamic>)
          .toList();
      await _rewriteJournal(journal, records);
      expect(
          (await const NativeProjectPublication()
                  .reconcile(journalPath: journal.path, policy: f.policy))
              .state,
          NativePublicationRecoveryState.prepared);
      final seal = records.singleWhere(
          (record) => record['state'] == 'sealed')['payload'] as Map;
      seal['borderSnapshotFiles'] = <String, Object?>{};
      await _rewriteJournal(journal, records);
      expect(
          (await const NativeProjectPublication()
                  .reconcile(journalPath: journal.path, policy: f.policy))
              .state,
          NativePublicationRecoveryState.corrupt);
      await journal.writeAsString(original, flush: true);
      final validRecords = (await journal.readAsLines())
          .map((line) => jsonDecode(line) as Map<String, dynamic>)
          .toList();
      final validSeal = validRecords.singleWhere(
          (record) => record['state'] == 'sealed')['payload'] as Map;
      final validSnapshots =
          Map<String, dynamic>.from(validSeal['borderSnapshotFiles'] as Map);
      final selectedPath = validSnapshots.keys.first;
      final selected = validSnapshots[selectedPath] as Map;
      for (final bad in [
        {'byteLength': 0, 'sha256': selected['sha256']},
        {'byteLength': 67108865, 'sha256': selected['sha256']},
        {'byteLength': selected['byteLength'], 'sha256': 'f' * 64},
        {...selected, 'extra': false}
      ]) {
        validSeal['borderSnapshotFiles'] = {
          ...validSnapshots,
          selectedPath: bad
        };
        await _rewriteJournal(journal, validRecords);
        expect(
            (await const NativeProjectPublication()
                    .reconcile(journalPath: journal.path, policy: f.policy))
                .state,
            NativePublicationRecoveryState.corrupt,
            reason: '$bad');
      }
      validSeal['borderSnapshotFiles'] = {
        for (final entry in validSnapshots.entries)
          if (entry.key == selectedPath)
            '../outside.png': entry.value
          else
            entry.key: entry.value
      };
      await _rewriteJournal(journal, validRecords);
      expect(
          (await const NativeProjectPublication()
                  .reconcile(journalPath: journal.path, policy: f.policy))
              .state,
          NativePublicationRecoveryState.corrupt);
      validSeal['borderSnapshotFiles'] = validSnapshots;
      for (final record in validRecords) {
        record['version'] = 1;
      }
      await _rewriteJournal(journal, validRecords);
      expect(
          (await const NativeProjectPublication()
                  .reconcile(journalPath: journal.path, policy: f.policy))
              .state,
          NativePublicationRecoveryState.corrupt);
      await journal.writeAsString(original, flush: true);
      final originalSeal = (jsonDecode(
              original.split('\n').where((line) => line.isNotEmpty).last)
          as Map)['payload'] as Map;
      final png = File(
          '${f.staged.projectPath}/${(originalSeal['borderSnapshotFiles'] as Map).keys.first}');
      final bytes = await png.readAsBytes();
      bytes[bytes.length - 1] ^= 1;
      await png.writeAsBytes(bytes, flush: true);
      expect(
          (await const NativeProjectPublication()
                  .reconcile(journalPath: journal.path, policy: f.policy))
              .state,
          NativePublicationRecoveryState.corrupt);
      expect(await Directory(f.job.destinationPath).exists(), isFalse);
      await f.verifySource();
    } finally {
      await f.job.close();
      await f.root.delete(recursive: true);
    }
  }, skip: Platform.environment['AVELUNE_AC12_SOURCE_SCRIPTS'] == null);
  test(
      'Border snapshot tampering after seal reaches intent and refuses promotion',
      () async {
    NativeWriteReceipt? staged;
    var reachedIntent = false;
    final f = await _borderPublication(checkpoint: (stage) async {
      if (stage != NativePublicationStage.publishIntentDurable) return;
      reachedIntent = true;
      final pngs = await Directory('${staged!.projectPath}/assets/borders')
          .list(recursive: true)
          .where((entry) => entry is File && entry.path.endsWith('.png'))
          .toList();
      final png = File(pngs.first.path);
      final bytes = await png.readAsBytes();
      bytes[bytes.length - 1] ^= 1;
      await png.writeAsBytes(bytes, flush: true);
    });
    staged = f.staged;
    try {
      await expectLater(
          f.job.publish(
              stagedReceipt: staged,
              readCurrentContext: () async => f.approval.context,
              verifySourceUnchanged: f.verifySource),
          throwsA(isA<NativePublicationException>()
              .having((e) => e.code, 'code', 'publication.native.changed')));
      expect(reachedIntent, isTrue);
      expect(await Directory(f.job.destinationPath).exists(), isFalse);
      expect(await Directory(staged.projectPath).exists(), isTrue);
      await f.verifySource();
    } finally {
      await f.job.close();
      await f.root.delete(recursive: true);
    }
  }, skip: Platform.environment['AVELUNE_AC12_SOURCE_SCRIPTS'] == null);
  test('strict writer reopening refuses a changed retained Border blob',
      () async {
    final f = await jumpFixture();
    final draft = (await const SourceSemanticStudyComposer().compose(
        source: f.base.draft!.source, base: f.base, files: f.fixture.files))!;
    final output = await Directory.systemTemp.createTemp('source-border-blob-');
    final rebound = NativeProjectDraft(
        source: draft.source,
        projectName: draft.projectName,
        parentPath: output.path,
        folderName: 'border-blob',
        mapIds: draft.mapIds,
        artifacts: draft.artifacts,
        sourceArtifacts: draft.sourceArtifacts,
        mutations: draft.mutations,
        compositionEvidence: draft.compositionEvidence,
        defaultMapWidth: draft.defaultMapWidth,
        defaultMapHeight: draft.defaultMapHeight);
    final approval = approveNativeFixtureDraft(rebound);
    String? stagingRoot;
    try {
      await expectLater(
          NativeProjectWriter(checkpoint: (stage, staging, projectPath) async {
            stagingRoot = staging;
            if (stage != NativeWriteStage.afterNativeVerify) return;
            final catalog = AssetCatalog.fromJson(jsonDecode(
                await File('$projectPath/$assetCatalogStorageKey')
                    .readAsString()) as Map<String, dynamic>);
            final record = catalog.records.firstWhere((entry) =>
                entry.logicalPath.startsWith('assets/borders/snapshots/'));
            final blob =
                File('$projectPath/${assetBlobStorageKey(record.artifact)}');
            final bytes = await blob.readAsBytes();
            bytes[bytes.length - 1] ^= 1;
            await blob.writeAsBytes(bytes, flush: true);
          }).write(approval.plan, approval.context, rebound),
          throwsA(isA<NativeWriteException>().having((error) => error.message,
              'message', contains('project.asset_blob_mismatch'))));
    } finally {
      if (stagingRoot != null) {
        await Directory(stagingRoot!).delete(recursive: true);
      }
      await output.delete(recursive: true);
    }
  }, skip: Platform.environment['AVELUNE_AC12_SOURCE_SCRIPTS'] == null);
}

typedef _BorderPublication = ({
  Directory root,
  NativePublicationPolicy policy,
  NativePublicationJob job,
  NativeWriteReceipt staged,
  NativeFixtureApproval approval,
  Future<void> Function() verifySource
});

Future<_BorderPublication> _borderPublication(
    {NativePublicationCheckpoint? checkpoint}) async {
  final f = await jumpFixture();
  final draft = (await const SourceSemanticStudyComposer().compose(
      source: f.base.draft!.source, base: f.base, files: f.fixture.files))!;
  final root =
      await Directory.systemTemp.createTemp('source-border-publication-');
  final output = await Directory('${root.path}/output').create();
  final source = await Directory('${root.path}/source').create();
  for (final entry in f.fixture.sourceBytes.entries) {
    final file = File('${source.path}/${entry.key}');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(entry.value, flush: true);
  }
  final rebound = NativeProjectDraft(
      source: draft.source,
      sourceRootPath: source.path,
      projectName: draft.projectName,
      parentPath: output.path,
      folderName: 'original-borders',
      mapIds: draft.mapIds,
      artifacts: draft.artifacts,
      sourceArtifacts: draft.sourceArtifacts,
      mutations: draft.mutations,
      compositionEvidence: draft.compositionEvidence,
      defaultMapWidth: draft.defaultMapWidth,
      defaultMapHeight: draft.defaultMapHeight);
  final approval = approveNativeFixtureDraft(rebound);
  final policy = NativePublicationPolicy(
      allowedParentRoots: [output.path], sourceRoots: [source.path]);
  NativePublicationJob? job;
  try {
    job = await NativeProjectPublication(checkpoint: checkpoint)
        .begin(approval.plan, approval.context, rebound, policy: policy);
    final staged = await NativeProjectWriter(
            stagingFactory: job.createStaging,
            checkpoint: job.recordWriteCheckpoint)
        .write(approval.plan, approval.context, rebound);
    return (
      root: root,
      policy: policy,
      job: job,
      staged: staged,
      approval: approval,
      verifySource: () async {
        for (final entry in f.fixture.sourceBytes.entries) {
          expect(await File('${source.path}/${entry.key}').readAsBytes(),
              entry.value);
        }
      }
    );
  } catch (_) {
    await job?.close();
    await root.delete(recursive: true);
    rethrow;
  }
}

Future<void> _rewriteJournal(
    File file, List<Map<String, dynamic>> records) async {
  var previous = '0' * 64;
  final lines = <String>[];
  for (final record in records) {
    record['previousHash'] = previous;
    final line = canonicalJsonOf(record);
    lines.add(line);
    previous = nativeFixtureHash(utf8.encode(line)).value;
  }
  await file.writeAsString('${lines.join('\n')}\n', flush: true);
}
