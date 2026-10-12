import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../tool/source_semantics_study.dart' as studytool;
import 'support/literal_tile_fixture.dart';
import 'support/native_writer_fixture.dart';

void main() {
  test('unqualified source stays literal without reading player resources',
      () async {
    final fixture = await LiteralTileFixture.create();
    final base = await const LiteralTileComposer().compose(
        source: fixture.source,
        files: fixture.files,
        selectedSourceMapIds: [1],
        projectName: 'Original study',
        parentPath: '/private/tmp',
        folderName: 'unused-ac12-study');
    final reads = fixture.files.reads.length;
    final semantic = await const SourceSemanticStudyComposer()
        .compose(source: fixture.source, base: base, files: fixture.files);
    expect(semantic, isNull);
    expect(fixture.files.reads.length, reads);
    expect(base.nativeMaps[1]!.placedElements, isEmpty);
  });

  test('large source archive is retained as bounded ordered inert witnesses',
      () async {
    final bytes = List<int>.generate(1080290, (index) => index % 251);
    final fixture = await LiteralTileFixture.create(scriptsBytes: bytes);
    final entry = fixture.source.snapshot.entries
        .singleWhere((entry) => entry.relativePath == 'Data/Scripts.rxdata');
    final recording = SourceSemanticWitnessFiles(fixture.source.snapshot,
        fixture.files, const NativeWriteLimits(), null);
    expect(await recording.read(entry.fileId), bytes);
    final row = recording.evidence.single;
    expect(row['encoding'], 'canonicalJsonBase64Chunks');
    final chunks = row['chunks'] as List;
    expect(chunks, hasLength(5));
    final restored = <int>[];
    for (final chunk in chunks) {
      final artifact = recording.artifacts[chunk['artifactHandle']]!;
      expect(artifact.bytes.length, lessThanOrEqualTo(1048576));
      final payload = jsonDecode(utf8.decode(artifact.bytes)) as Map;
      expect(payload['kind'], 'sourceSemanticByteChunk');
      expect(payload['offset'], restored.length);
      final decoded = base64Decode(payload['bytesBase64'] as String);
      expect(decoded.length, chunk['byteLength']);
      restored.addAll(decoded);
    }
    expect(restored, bytes);
    expect(literalFixtureHash(restored), entry.sha256);
    expect(await recording.read(entry.fileId), bytes);
    expect(fixture.files.reads.where((id) => id == entry.fileId), hasLength(1));
  });

  test('chunk artifact budget is checked before reading a large source',
      () async {
    final fixture =
        await LiteralTileFixture.create(scriptsBytes: List.filled(1080290, 0));
    final entry = fixture.source.snapshot.entries
        .singleWhere((entry) => entry.relativePath == 'Data/Scripts.rxdata');
    final recording = SourceSemanticWitnessFiles(fixture.source.snapshot,
        fixture.files, const NativeWriteLimits(maxArtifacts: 1), null);
    await expectLater(
        recording.read(entry.fileId),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'semantics.witness.quota')));
    expect(fixture.files.reads, isEmpty);
    expect(recording.artifacts, isEmpty);
  });

  test('study tool rejects symlink ancestors before writing in its source',
      () async {
    final temporary =
        await Directory.systemTemp.createTemp('ac12-tool-boundary-');
    try {
      final root = await temporary.resolveSymbolicLinks();
      final source = await Directory('$root/source').create();
      final alias = await Link('$root/alias').create(source.path);
      await expectLater(
          studytool.validateFreshStudyDirectories(
              source.path, '${alias.path}/destination', '$root/evidence'),
          throwsStateError);
      expect(await source.list().toList(), isEmpty);
      expect(await Directory('$root/evidence').exists(), isFalse);
      await expectLater(
          studytool.validateFreshStudyDirectories(
              source.path, '$root/output', '$root/output/evidence'),
          throwsStateError);
      expect(await Directory('$root/output').exists(), isFalse);
    } finally {
      await temporary.delete(recursive: true);
    }
  });

  final scriptsPath = Platform.environment['AVELUNE_AC12_SOURCE_SCRIPTS'];
  test('qualified native output is automatic and refuses coherent tampering',
      () async {
    final scripts = await File(scriptsPath!).readAsBytes();
    expect(literalFixtureHash(scripts).value,
        SourceSemanticProfile.kantoScriptsArchiveSha256);
    final fixture =
        await LiteralTileFixture.create(scriptsBytes: scripts, autotilePngs: {
      'OriginalWater':
          image.encodePng(image.Image(width: 96, height: 128, numChannels: 4))
    }, extraFiles: {
      'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = OriginalPlayer\n'),
      'Graphics/Characters/OriginalPlayer.png':
          image.encodePng(image.Image(width: 128, height: 192, numChannels: 4)),
    }, maps: [
      LiteralFixtureMap(id: 1, width: 3, height: 4, layers: [
        [48, ...List.filled(11, 384)],
        [0, 391, 0, 0, 0, 0, 0, 0, 0, 0, 0, 391],
        List.filled(12, 0),
      ])
    ], tilesets: [
      LiteralFixtureTileset(
          id: 1,
          autotileNames: ['OriginalWater'],
          priorities: {391: 1},
          passages: {391: 8, 392: 15})
    ]);
    final output =
        await Directory.systemTemp.createTemp('ac12-semantic-study-');
    try {
      final base = await const LiteralTileComposer().compose(
          source: fixture.source,
          files: fixture.files,
          selectedSourceMapIds: [1],
          projectName: 'Original semantic study',
          parentPath: output.path,
          folderName: 'original-semantic-study');
      final draft = (await const SourceSemanticStudyComposer()
          .compose(source: fixture.source, base: base, files: fixture.files))!;
      final again = (await const SourceSemanticStudyComposer()
          .compose(source: fixture.source, base: base, files: fixture.files))!;
      expect(draft.canonicalHash, again.canonicalHash);
      expect(draft.compositionEvidence['sourceSemantics'], isA<Map>());
      expect(draft.sourceArtifacts, isNotEmpty);
      final witnesses = (draft.compositionEvidence['sourceSemantics']
          as Map)['witnesses'] as List;
      expect(
          (witnesses.singleWhere((row) =>
              row['relativePath'] == 'Data/Scripts.rxdata')['chunks'] as List),
          hasLength(5));
      expect(
          draft.mutations.any((entry) =>
              entry.actionId == 'characterStudio.character.setDefault'),
          isTrue);
      final approval = approveNativeFixtureDraft(draft);
      final receipt = await NativeProjectWriter()
          .write(approval.plan, approval.context, draft);
      expect(receipt.verified, isTrue);
      expect(receipt.published, isFalse);
      const reader = LocalProjectFileReader();
      final handles = WorkspaceHandleStore();
      final policy = await WorkspacePolicy.create(
          allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
      final opener = ProjectOpenService(
          policy: policy, fileReader: reader, handles: handles);
      final opened = await opener.openProject(receipt.projectPath);
      try {
        final native = await ProjectSnapshotLoader(handles: handles).load(
            opened.projectHandle,
            policy: ProjectSnapshotLoadPolicy.strict);
        expect(native.loadDiagnostics, isEmpty);
        expect(native.manifest.characters.single.animations, hasLength(8));
        expect(native.manifest.settings.defaultPlayerCharacterId,
            native.manifest.characters.single.id);
        final map = native.maps.single;
        expect(map.mapMetadata.defaultSpawnId, isNotNull);
        expect(map.placedElements, isNotEmpty);
        expect(
            map.layers
                .whereType<TileLayer>()
                .singleWhere((layer) => layer.name == 'Source Z 1')
                .cells
                .where((cell) => cell != 0),
            isEmpty);
      } finally {
        opener.closeWorkspace(opened.workspaceHandle);
      }
      final saves = draft.mutations.map((mutation) {
        if (mutation.actionId != 'map.save') return mutation;
        final raw =
            Map<String, Object?>.from(mutation.parameters['map'] as Map);
        raw['name'] = 'Coherently forged';
        return NativeMutation(
            operationId: mutation.operationId,
            actionId: mutation.actionId,
            sourceEntityIds: mutation.sourceEntityIds,
            targetEntityIds: mutation.targetEntityIds,
            parameters: {'map': raw});
      }).toList();
      final forged = NativeProjectDraft(
          source: draft.source,
          projectName: draft.projectName,
          parentPath: draft.parentPath,
          folderName: draft.folderName,
          mapIds: draft.mapIds,
          artifacts: draft.artifacts,
          sourceArtifacts: draft.sourceArtifacts,
          mutations: saves,
          compositionEvidence: draft.compositionEvidence);
      final forgedApproval = approveNativeFixtureDraft(forged);
      final stages = <NativeWriteStage>[];
      await expectLater(
          NativeProjectWriter(checkpoint: (stage, _, __) => stages.add(stage))
              .write(forgedApproval.plan, forgedApproval.context, forged),
          throwsA(isA<NativeWriteException>().having(
              (error) => error.code, 'code', 'native.semantics.regeneration')));
      expect(stages, isEmpty);
    } finally {
      await output.delete(recursive: true);
    }
  }, skip: scriptsPath == null || !Platform.isMacOS);
}
