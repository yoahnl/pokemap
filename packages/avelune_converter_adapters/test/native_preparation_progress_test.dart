import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';
import 'support/native_writer_fixture.dart';

void main() {
  late Directory root;
  late Directory output;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('native-preparation-progress-');
    output = await Directory('${root.path}/output').create();
  });

  tearDown(() => root.delete(recursive: true));

  test('preparation stages are ordered and monotone without changing output',
      () async {
    final fixture = await NativeWriterFixture.create(output.path,
        sourceRootPath: '${root.path}/source');
    final observed = <(NativePreparationStage, JobProgress)>[];
    final receipt = await NativeProjectWriter(
        preparationCheckpoint: (stage, progress) {
      observed.add((stage, progress));
    }).write(fixture.plan, fixture.context, fixture.draft);
    final reference = await const NativeProjectWriter()
        .write(fixture.plan, fixture.context, fixture.draft);
    expect(receipt.draftHash, reference.draftHash);
    expect(receipt.mapHashes, reference.mapHashes);
    expect(receipt.assetHashes, reference.assetHashes);
    expect(await File('${receipt.projectPath}/project.json').readAsString(),
        await File('${reference.projectPath}/project.json').readAsString());
    expect(observed.map((entry) => entry.$1).toSet().toList(),
        NativePreparationStage.values);
    for (final stage in NativePreparationStage.values) {
      final updates = observed
          .where((entry) => entry.$1 == stage)
          .map((entry) => entry.$2)
          .toList();
      expect(updates.first.done, 0, reason: stage.name);
      for (var index = 1; index < updates.length; index++) {
        expect(updates[index].done, greaterThanOrEqualTo(updates[index - 1].done));
        expect(updates[index].unit, updates.first.unit);
        expect(updates[index].total, updates.first.total);
      }
      if (updates.last.total != null) {
        expect(updates.last.done, updates.last.total, reason: stage.name);
      }
    }
    final projection = observed
        .where((entry) => entry.$1 == NativePreparationStage.mutationProjection)
        .last.$2;
    expect(projection.done, fixture.draft.mutations.length);
    expect(projection.unit, JobUnit.operations);
  });

  for (final cancelledStage in [NativePreparationStage.bindings,
    NativePreparationStage.mutationProjection]) {
    test('Timer cancellation at ${cancelledStage.name} precedes staging',
        () async {
      final fixture = await NativeWriterFixture.create(output.path,
          sourceRootPath: '${root.path}/source');
      final cancellation = ScanCancellation();
      final stages = <NativeWriteStage>[];
      var timerDelivered = false;
      final writer = NativeProjectWriter(
          checkpoint: (stage, _, __) => stages.add(stage),
          preparationCheckpoint: (stage, progress) {
            if (stage == cancelledStage && progress.done == 0) {
              Timer.run(() {
                timerDelivered = true;
                cancellation.cancel();
              });
            }
          });
      await expectLater(
          writer.write(fixture.plan, fixture.context, fixture.draft,
              cancellation: cancellation),
          throwsA(isA<NativeWriteException>()
              .having((error) => error.code, 'code', 'native.cancelled')));
      expect(timerDelivered, isTrue);
      expect(stages, isEmpty);
      expect(await output.list().toList(), isEmpty);
    });
  }

  test('isolate cancellation reaches in-memory witness reads before staging',
      () async {
    const limits = NativeWriteLimits(maxArtifacts: 128, maxMutations: 512);
    final fixture = await LiteralTileFixture.create(
        sourceRootPath: '${root.path}/source',
        interpretationProfile: syntheticSourceInterpretationProfile,
        scriptsBytes: syntheticInterpretationArchive,
        maps: [for (var id = 1; id <= 33; id++)
          LiteralFixtureMap(id: id, tilesetId: id)],
        tilesets: [for (var id = 1; id <= 33; id++)
          LiteralFixtureTileset(id: id)],
        extraFiles: {
          'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = OriginalPlayer\n'),
          'Graphics/Characters/OriginalPlayer.png': image.encodePng(
              image.Image(width: 128, height: 192, numChannels: 4)),
        });
    final base = await const LiteralTileComposer().compose(
        source: fixture.source,
        files: fixture.files,
        selectedSourceMapIds: [for (var id = 1; id <= 33; id++) id],
        projectName: 'Cooperative witness reads',
        parentPath: output.path,
        folderName: 'cooperative-witness-reads',
        limits: limits);
    final draft = (await const SourceSemanticStudyComposer().compose(
        source: fixture.source, base: base, files: fixture.files,
        limits: limits))!;
    final approval = approveNativeFixtureDraft(draft);
    final cancellation = ScanCancellation();
    final control = ReceivePort();
    var sentAtRead = 0;
    var delivered = false;
    final subscription = control.listen((_) {
      delivered = true;
      cancellation.cancel();
    });
    try {
      await expectLater(
          NativeProjectWriter(
              checkpoint: (stage, _, __) {
                if (stage == NativeWriteStage.beforeStage) {
                  throw StateError('Cancellation must precede native staging');
                }
              },
              preparationCheckpoint: (stage, progress) async {
                if (stage == NativePreparationStage.literalTiles &&
                    progress.done >= 32 && sentAtRead == 0) {
                  sentAtRead = progress.done;
                  await Isolate.spawn(_sendPreparationCancellation,
                      control.sendPort);
                }
              }).write(approval.plan, approval.context, draft,
                  limits: limits, cancellation: cancellation),
          throwsA(isA<NativeWriteException>()
              .having((error) => error.code, 'code', 'native.cancelled')));
      expect(sentAtRead, 32);
      expect(delivered, isTrue);
      expect(await output.list().toList(), isEmpty);
    } finally {
      await subscription.cancel();
      control.close();
    }
  });

  test('semantic witness progress preserves exact witness rejection', () async {
    final fixture = await LiteralTileFixture.create(
        sourceRootPath: '${root.path}/source',
        interpretationProfile: syntheticSourceInterpretationProfile,
        scriptsBytes: syntheticInterpretationArchive,
        extraFiles: {
          'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = OriginalPlayer\n'),
          'Graphics/Characters/OriginalPlayer.png': image.encodePng(
              image.Image(width: 128, height: 192, numChannels: 4)),
        });
    final base = await const LiteralTileComposer().compose(
        source: fixture.source,
        files: fixture.files,
        selectedSourceMapIds: [1],
        projectName: 'Preparation witness',
        parentPath: output.path,
        folderName: 'preparation-witness');
    final draft = (await const SourceSemanticStudyComposer()
        .compose(source: fixture.source, base: base, files: fixture.files))!;
    final validApproval = approveNativeFixtureDraft(draft);
    final validProgress = <(NativePreparationStage, JobProgress)>[];
    final receipt = await NativeProjectWriter(
        preparationCheckpoint: (stage, progress) {
          validProgress.add((stage, progress));
        }).write(validApproval.plan, validApproval.context, draft);
    expect(receipt.verified, isTrue);
    expect(validProgress.map((entry) => entry.$1).toSet().toList(),
        NativePreparationStage.values);
    for (final stage in [NativePreparationStage.sourceWitnesses,
      NativePreparationStage.literalTiles, NativePreparationStage.traversal]) {
      final updates = validProgress.where((entry) => entry.$1 == stage).toList();
      expect(updates.first.$2.done, 0);
      expect(updates.last.$2.done, greaterThan(0));
      expect(updates.last.$2.total, isNull);
      expect(updates.last.$2.unit, JobUnit.operations);
    }
    final outputBefore = await output.list().map((entry) => entry.path).toList();
    final evidence = Map<String, Object?>.from(
        jsonDecode(jsonEncode(draft.compositionEvidence)) as Map);
    final raw = evidence['sourceSemantics'] as Map;
    ((raw['witnesses'] as List).last as Map)['rawSha256'] = '0' * 64;
    final tampered = NativeProjectDraft(
        source: draft.source,
        projectName: draft.projectName,
        parentPath: draft.parentPath,
        folderName: draft.folderName,
        sourceRootPath: draft.sourceRootPath,
        mapIds: draft.mapIds,
        artifacts: draft.artifacts,
        sourceArtifacts: draft.sourceArtifacts,
        mutations: draft.mutations,
        compositionEvidence: evidence,
        defaultMapWidth: draft.defaultMapWidth,
        defaultMapHeight: draft.defaultMapHeight);
    final approval = approveNativeFixtureDraft(tampered);
    final progress = <(NativePreparationStage, JobProgress)>[];
    final stages = <NativeWriteStage>[];
    await expectLater(
        NativeProjectWriter(
            checkpoint: (stage, _, __) => stages.add(stage),
            preparationCheckpoint: (stage, update) {
              progress.add((stage, update));
            }).write(approval.plan, approval.context, tampered),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'native.semantics.witness')));
    expect(progress.any((entry) =>
        entry.$1 == NativePreparationStage.sourceWitnesses), isTrue);
    expect(stages, isEmpty);
    expect(await output.list().map((entry) => entry.path).toList(), outputBefore);
  });
}

void _sendPreparationCancellation(SendPort port) => port.send(true);
