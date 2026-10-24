import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
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
    final mutableBytes = Uint8List.fromList(bytes);
    fixture.files.overrides[entry.relativePath] = mutableBytes;
    final recording = SourceSemanticWitnessFiles(fixture.source.snapshot,
        fixture.files, const NativeWriteLimits(), null);
    final retained = await recording.read(entry.fileId);
    expect(retained, isA<Uint8List>());
    expect(retained, bytes);
    expect(() => retained[0] = 23, throwsUnsupportedError);
    mutableBytes[0] ^= 1;
    expect(retained, bytes);
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
    expect(await recording.read(entry.fileId), same(retained));
    expect(fixture.files.reads.where((id) => id == entry.fileId), hasLength(1));
  });

  test('semantic witnesses reject out of range bytes before compact storage',
      () async {
    for (final invalid in [-1, 256]) {
      final fixture = await LiteralTileFixture.create(
          scriptsBytes: [invalid & 255, 7, 11]);
      final entry = fixture.source.snapshot.entries
          .singleWhere((entry) => entry.relativePath == 'Data/Scripts.rxdata');
      fixture.files.overrides[entry.relativePath] = [invalid, 7, 11];
      final recording = SourceSemanticWitnessFiles(fixture.source.snapshot,
          fixture.files, const NativeWriteLimits(), null);
      await expectLater(
          recording.read(entry.fileId),
          throwsA(isA<NativeWriteException>().having(
              (error) => error.code, 'code', 'semantics.witness.changed')));
      expect(recording.evidence, isEmpty);
      expect(recording.artifacts, isEmpty);
    }
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
  test('intermediate source maps do not consume the final draft JSON budget',
      () async {
    final fixture = await LiteralTileFixture.create(interpretationProfile: fixtureSourceInterpretationProfile,

        scriptsBytes: await File(scriptsPath!).readAsBytes(),
        extraFiles: {
          'PBS/metadata.txt':
              utf8.encode('[1]\nWalkCharset = OriginalPlayer\n'),
          'Graphics/Characters/OriginalPlayer.png': image
              .encodePng(image.Image(width: 128, height: 192, numChannels: 4)),
        },
        maps: [
          LiteralFixtureMap(id: 98, width: 128, height: 128, layers: [
            [
              for (var cell = 0; cell < 128 * 128; cell++)
                384 + ((cell * 1103515245 + (cell ~/ 9) * 12345) % 16)
            ],
            List.filled(128 * 128, 0),
            List.filled(128 * 128, 0),
          ])
        ]);
    final base = await const LiteralTileComposer().compose(
        source: fixture.source,
        files: fixture.files,
        selectedSourceMapIds: [98],
        projectName: 'Exact final JSON budget',
        parentPath: '/private/tmp',
        folderName: 'never-written-context-budget');
    final composer = const SourceSemanticStudyComposer();
    final full = (await composer.compose(
        source: fixture.source, base: base, files: fixture.files))!;
    final exact =
        NativeWriteLimits(maxTotalDraftJsonBytes: full.validatedJsonByteLength);
    final bounded = (await composer.compose(
        source: fixture.source,
        base: base,
        files: fixture.files,
        limits: exact))!;
    expect(bounded.validatedJsonByteLength, full.validatedJsonByteLength);
    expect(bounded.canonicalHash, full.canonicalHash);
    await expectLater(
        composer.compose(
            source: fixture.source,
            base: base,
            files: fixture.files,
            limits: NativeWriteLimits(
                maxTotalDraftJsonBytes: full.validatedJsonByteLength - 1)),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'native.quota.draft_json')));
  }, skip: scriptsPath == null);

  test('player authoring finishes before native atlas imports', () async {
    final scripts = await File(scriptsPath!).readAsBytes();
    expect(literalFixtureHash(scripts).value,
        fixtureSourceInterpretationProfile.scriptsArchiveHash.value);
    final atlas = image.Image(width: 256, height: 64, numChannels: 4);
    for (var y = 0; y < 32; y++) {
      for (var x = 0; x < 32; x++) {
        atlas.setPixelRgba(x, y, 31, 41, 59, 255);
      }
    }
    for (var part = 0; part < 3; part++) {
      for (var y = 48; y < 64; y++) {
        for (var x = 32 * part; x < 32 * (part + 1); x++) {
          atlas.setPixelRgba(x, y, 73 + part * 20, x, y, 255);
        }
      }
    }
    final middle = List<int>.filled(25, 0)
      ..[11] = 392
      ..[12] = 393
      ..[13] = 394;
    final fixture =
        await LiteralTileFixture.create(interpretationProfile: fixtureSourceInterpretationProfile,
scriptsBytes: scripts, extraFiles: {
      'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = OriginalPlayer\n'
          'RunCharset = OriginalRun\nCycleCharset = OriginalCycle\n'),
      'Graphics/Characters/OriginalPlayer.png':
          image.encodePng(image.Image(width: 128, height: 192, numChannels: 4)),
      'Graphics/Characters/OriginalRun.png': image.encodePng(
          image.Image(width: 128, height: 192, numChannels: 4)
            ..setPixelRgba(0, 0, 1, 2, 3, 255)),
      'Graphics/Characters/OriginalCycle.png': image.encodePng(
          image.Image(width: 192, height: 192, numChannels: 4)
            ..setPixelRgba(0, 0, 4, 5, 6, 255)),
    }, maps: [
      LiteralFixtureMap(id: 154, width: 1, height: 1, layers: [
        [384],
        [0],
        [0]
      ]),
      LiteralFixtureMap(
          id: 98,
          width: 5,
          height: 5,
          layers: [List.filled(25, 384), middle, List.filled(25, 0)])
    ], tilesets: [
      LiteralFixtureTileset(
          id: 1,
          png: image.encodePng(atlas),
          passages: {392: 7, 393: 7, 394: 7},
          terrainTags: {392: 1, 393: 1, 394: 1})
    ]);
    final output = await Directory.systemTemp.createTemp('ac12-player-order-');
    try {
      final base = await const LiteralTileComposer().compose(
          source: fixture.source,
          files: fixture.files,
          selectedSourceMapIds: [98, 154],
          projectName: 'Original player order',
          parentPath: output.path,
          folderName: 'original-player-order');
      final draft = (await const SourceSemanticStudyComposer()
          .compose(source: fixture.source, base: base, files: fixture.files))!;
      expect(draft.mutations.any((m) => m.actionId == 'element.batch_upsert'),
          isTrue);
      final playerMutations = draft.mutations
          .where((mutation) =>
              mutation.operationId.value.startsWith('ac12-player-'))
          .toList();
      expect(playerMutations.map((mutation) => mutation.actionId), [
        ...List.filled(3, 'tileset.import_image'),
        'characterStudio.character.create',
        ...List.filled(20, 'characterStudio.animationClip.upsert'),
        'characterStudio.character.setDefault'
      ]);
      final nativeImports = base.draft!.mutations
          .where((mutation) => !mutation.actionId.startsWith('map.'))
          .toList();
      final nativeImportIds =
          nativeImports.map((mutation) => mutation.operationId).toSet();
      for (final original in nativeImports) {
        expect(
            draft.mutations.singleWhere(
                (mutation) => mutation.operationId == original.operationId),
            same(original));
      }
      expect(
          draft.mutations
              .where(
                  (mutation) => nativeImportIds.contains(mutation.operationId))
              .map((mutation) => mutation.toJson(0)),
          nativeImports.map((mutation) => mutation.toJson(0)));
      expect(draft.mapIds, base.draft!.mapIds);
      expect(
          draft.mutations
              .where((mutation) => mutation.actionId == 'map.create')
              .map((mutation) => mutation.toJson(0)),
          base.draft!.mutations
              .where((mutation) => mutation.actionId == 'map.create')
              .map((mutation) => mutation.toJson(0)));
      final semantic = draft.compositionEvidence['sourceSemantics'] as Map;
      expect(semantic['directedJumps']['importedJumpCount'], 3);
      final sheets = semantic['player']['animationSheets'] as List;
      final playerAssetIds =
          sheets.map((sheet) => 'image_${sheet['tilesetId']}').toList()..sort();
      final firstClip = draft.mutations.indexWhere((mutation) =>
          mutation.actionId == 'characterStudio.animationClip.upsert');
      var mutationIndex = 0;
      List<String>? firstClipAssetIds;
      final approval = approveNativeFixtureDraft(draft);
      final receipt = await NativeProjectWriter(
          checkpoint: (stage, stagingRoot, projectPath) async {
        if (stage != NativeWriteStage.afterCreation ||
            mutationIndex++ != firstClip) {
          return;
        }
        const reader = LocalProjectFileReader();
        final handles = WorkspaceHandleStore();
        final policy = await WorkspacePolicy.create(
            allowedRootPaths: [stagingRoot!], fileReader: reader);
        final opener = ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles);
        final opened = await opener.openProject(projectPath!);
        try {
          final native = await ProjectSnapshotLoader(handles: handles).load(
              opened.projectHandle,
              policy: ProjectSnapshotLoadPolicy.strict);
          expect(native.loadDiagnostics, isEmpty);
          final catalog = AssetCatalog.fromJson(jsonDecode(utf8
                  .decode(native.resourceBytes(assetCatalogResourceIdentity)))
              as Map<String, dynamic>);
          firstClipAssetIds =
              catalog.records.map((record) => record.id).toList();
        } finally {
          opener.closeWorkspace(opened.workspaceHandle);
        }
      }).write(approval.plan, approval.context, draft);
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
        expect(native.manifest.characters.single.sortOrder, 0);
        expect(native.manifest.characters.single.animations, hasLength(20));
        expect(native.manifest.settings.defaultPlayerCharacterId,
            native.manifest.characters.single.id);
        expect(
            native.manifest.borderCatalog.records.expand(
                (record) => record.latestPublished!.definition.primitives),
            hasLength(3));
        final ledgeMap =
            native.maps.singleWhere((map) => map.id == draft.mapIds[98]);
        final placements = ledgeMap.layers
            .whereType<BorderLayer>()
            .single
            .content
            .features
            .expand((feature) => feature.materialization!.placements);
        expect(placements, hasLength(3));
        expect(placements.map((placement) => placement.topLeftWorldPx), [
          const BorderPixelPos(x: 32, y: 64),
          const BorderPixelPos(x: 64, y: 64),
          const BorderPixelPos(x: 96, y: 64),
        ]);
        final batchRows = {
          for (final row in semantic['mutationBatches'] as List)
            row['operationId'] as String: row['components'] as List
        };
        final originalEvidence =
            jsonDecode(jsonEncode(draft.compositionEvidence)) as Map;
        final originalSemantic = originalEvidence['sourceSemantics'] as Map;
        originalSemantic['operationIds'] = [
          for (final id in semantic['operationIds'] as List)
            if (batchRows.containsKey(id))
              for (final component in batchRows[id]!) component['operationId']
            else
              id
        ];
        originalSemantic.remove('mutationBatches');
        final unchangedDraftHash = canonicalHashOf({
          'mapIds': {
            for (final entry in draft.mapIds.entries)
              entry.key.toString(): entry.value
          },
          'artifacts': [
            for (final artifact in [
              ...draft.artifacts,
              ...draft.sourceArtifacts
            ])
              {
                'handle': artifact.handle,
                'rawSha256': artifact.rawSha256.value,
                'byteLength': artifact.bytes.length
              }
          ],
          'playerMutations': [
            for (final mutation in playerMutations) mutation.toJson(0)
          ],
          'remainingMutations': [
            for (final mutation in draft.mutations)
              if (!playerMutations.contains(mutation))
                if (batchRows.containsKey(mutation.operationId.value))
                  for (final component
                      in batchRows[mutation.operationId.value]!)
                    {
                      ...Map<String, Object?>.from(component as Map),
                      'ordinal': 0
                    }
                else
                  mutation.toJson(0)
          ],
          'compositionEvidence': originalEvidence
        }).value;
        final nativeHash = canonicalHashOf(jsonDecode(jsonEncode({
          'manifest': native.manifest.toJson(),
          'maps': native.maps.map((map) => map.toJson()).toList(),
          'resources': native.resourceFingerprints,
          'mapHashes':
              receipt.mapHashes.map((id, hash) => MapEntry(id, hash.value)),
          'assetHashes':
              receipt.assetHashes.map((id, hash) => MapEntry(id, hash.value))
        }))).value;
        expect(unchangedDraftHash,
            '36157de779fdd2985f370a2a7581b3c1bc9869f43685a84447c24e20a8a5ef1a',
            reason: 'Mutation contents, internal order, artifacts and evidence '
                'match the explicit interpretation, compact atlas and grouped ledge fixture');
        expect(nativeHash,
            'fa5aa1bb3bf8031441e877e52518fa3d8f9e5bc8892ec1bbda269c6eff624894',
            reason: 'Strictly reopened native resources match the packed atlas '
                'and grouped ledge fixture');
        expect(draft.mutations.length, lessThan(51));
        expect(
            draft.mutations.length +
                batchRows.values
                    .fold<int>(0, (sum, entries) => sum + entries.length - 1),
            51);
      } finally {
        opener.closeWorkspace(opened.workspaceHandle);
      }
      expect(firstClipAssetIds, playerAssetIds);
      expect(draft.mutations.take(playerMutations.length), playerMutations);
    } finally {
      await output.delete(recursive: true);
    }
  }, skip: scriptsPath == null || !Platform.isMacOS);

  test('qualified native output is automatic and refuses coherent tampering',
      () async {
    final scripts = await File(scriptsPath!).readAsBytes();
    expect(literalFixtureHash(scripts).value,
        fixtureSourceInterpretationProfile.scriptsArchiveHash.value);
    final fixture =
        await LiteralTileFixture.create(interpretationProfile: fixtureSourceInterpretationProfile,
scriptsBytes: scripts, autotilePngs: {
      'OriginalWater':
          image.encodePng(image.Image(width: 96, height: 128, numChannels: 4))
    }, extraFiles: {
      'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = OriginalPlayer\n'
          'RunCharset = OriginalRun\nCycleCharset = OriginalCycle\n'),
      'Graphics/Characters/OriginalPlayer.png':
          image.encodePng(image.Image(width: 128, height: 192, numChannels: 4)),
      'Graphics/Characters/OriginalRun.png': image.encodePng(
          image.Image(width: 128, height: 192, numChannels: 4)
            ..setPixelRgba(0, 0, 1, 2, 3, 255)),
      'Graphics/Characters/OriginalCycle.png': image.encodePng(
          image.Image(width: 192, height: 192, numChannels: 4)
            ..setPixelRgba(0, 0, 4, 5, 6, 255)),
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
      final verifiedInputs = SourceSemanticWitnessFiles(
          fixture.snapshot, fixture.files, const NativeWriteLimits(), null);
      expect(
          await base.verifyForReuse(
              source: fixture.source, files: verifiedInputs),
          same(base));
      expect(
          verifiedInputs.evidence.map((entry) => entry['relativePath']),
          unorderedEquals([
            'Graphics/Tilesets/OriginalAtlas1.png',
            'Graphics/Autotiles/OriginalWater.png',
            'Data/Scripts.rxdata'
          ]));
      final draft = (await const SourceSemanticStudyComposer()
          .compose(source: fixture.source, base: base, files: fixture.files))!;
      final again = (await const SourceSemanticStudyComposer()
          .compose(source: fixture.source, base: base, files: fixture.files))!;
      expect(draft.canonicalHash, again.canonicalHash);
      final replayed = (await const SourceSemanticStudyComposer().compose(
          source: fixture.source,
          base: base,
          files: fixture.files,
          limits: const NativeWriteLimits(maxArtifacts: 31)))!;
      expect(replayed.canonicalHash, draft.canonicalHash);
      expect(replayed.compositionEvidence, draft.compositionEvidence);
      expect(replayed.sourceArtifacts.map((artifact) => artifact.rawSha256),
          draft.sourceArtifacts.map((artifact) => artifact.rawSha256));
      final originalImport = base.draft!.mutations
          .firstWhere((mutation) => !mutation.actionId.startsWith('map.'));
      expect(
          draft.mutations.singleWhere(
              (mutation) => mutation.operationId == originalImport.operationId),
          same(originalImport));
      expect(
          replayed.mutations.singleWhere(
              (mutation) => mutation.operationId == originalImport.operationId),
          isNot(same(originalImport)));
      fixture.files.reads.clear();
      await expectLater(
          const SourceSemanticStudyComposer().compose(
              source: fixture.source,
              base: base,
              files: fixture.files,
              limits: const NativeWriteLimits(maxMapCells: 35)),
          throwsA(isA<NativeWriteException>()
              .having((error) => error.code, 'code', 'literal.quota.cells')));
      expect(fixture.files.reads, isEmpty);
      for (final path in [
        'Graphics/Tilesets/OriginalAtlas1.png',
        'Graphics/Autotiles/OriginalWater.png',
        'Data/Scripts.rxdata'
      ]) {
        final changed = fixture.sourceBytes[path]!.toList();
        changed[0] ^= 1;
        fixture.files.overrides[path] = changed;
        await expectLater(
            const SourceSemanticStudyComposer().compose(
                source: fixture.source, base: base, files: fixture.files),
            throwsA(isA<NativeWriteException>().having(
                (error) => error.code, 'code', 'semantics.witness.changed')));
        fixture.files.overrides.remove(path);
      }
      expect(draft.compositionEvidence['sourceSemantics'], isA<Map>());
      expect(draft.sourceArtifacts, isNotEmpty);
      final witnesses = (draft.compositionEvidence['sourceSemantics']
          as Map)['witnesses'] as List;
      final sourceSheets = (draft.compositionEvidence['sourceSemantics']
          as Map)['player']['animationSheets'] as List;
      expect(sourceSheets, hasLength(3));
      expect(
          draft.mutations.where((mutation) =>
              mutation.actionId == 'characterStudio.animationClip.upsert' &&
              mutation.parameters['state'] == 'bicycle_idle'),
          hasLength(4));
      for (final name in ['OriginalPlayer', 'OriginalRun', 'OriginalCycle']) {
        final witness = witnesses.singleWhere(
            (row) => row['relativePath'] == 'Graphics/Characters/$name.png');
        expect(witness['encoding'], 'png');
        expect(draft.sourceArtifacts.map((artifact) => artifact.handle),
            contains(witness['artifactHandle']));
      }
      for (final sheet in sourceSheets) {
        expect(
            draft.mutations.where((mutation) =>
                mutation.actionId == 'tileset.import_image' &&
                mutation.parameters['tilesetId'] == sheet['tilesetId']),
            hasLength(1));
      }
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
        expect(native.manifest.characters.single.animations, hasLength(20));
        for (final sheet in sourceSheets) {
          expect(native.manifest.tilesets.map((entry) => entry.id),
              contains(sheet['tilesetId']));
        }
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
      final forgedClips = draft.mutations.map((mutation) {
        if (mutation.actionId != 'characterStudio.animationClip.upsert' ||
            mutation.parameters['state'] != 'bicycle') {
          return mutation;
        }
        return NativeMutation(
            operationId: mutation.operationId,
            actionId: mutation.actionId,
            sourceEntityIds: mutation.sourceEntityIds,
            targetEntityIds: mutation.targetEntityIds,
            parameters: {
              ...mutation.parameters,
              'sourceAssetId': _nativePlayerAsset(draft),
            });
      }).toList();
      final forgedAnimation = NativeProjectDraft(
          source: draft.source,
          projectName: draft.projectName,
          parentPath: draft.parentPath,
          folderName: draft.folderName,
          mapIds: draft.mapIds,
          artifacts: draft.artifacts,
          sourceArtifacts: draft.sourceArtifacts,
          mutations: forgedClips,
          compositionEvidence: draft.compositionEvidence);
      final animationApproval = approveNativeFixtureDraft(forgedAnimation);
      await expectLater(
          NativeProjectWriter().write(animationApproval.plan,
              animationApproval.context, forgedAnimation),
          throwsA(isA<NativeWriteException>().having(
              (error) => error.code, 'code', 'native.semantics.regeneration')));
      final cycle = sourceSheets.singleWhere(
          (sheet) => sheet['declaration'] == 'CycleCharset') as Map;
      final cycleImport = draft.mutations.singleWhere((mutation) =>
          mutation.actionId == 'tileset.import_image' &&
          mutation.parameters['tilesetId'] == cycle['tilesetId']);
      final originalHandle = cycleImport.parameters['artifactHandle'];
      final originalArtifact = draft.artifacts
          .singleWhere((artifact) => artifact.handle == originalHandle);
      final changedPixels = image
          .decodePng(Uint8List.fromList(originalArtifact.bytes))!
        ..setPixelRgba(8, 16, 255, 0, 0, 255);
      final changedArtifact =
          NativeArtifact(bytes: image.encodePng(changedPixels));
      final semantics =
          draft.compositionEvidence['sourceSemantics'] as Map<String, Object?>;
      final player = semantics['player'] as Map;
      final forgedPixels = NativeProjectDraft(
          source: draft.source,
          projectName: draft.projectName,
          parentPath: draft.parentPath,
          folderName: draft.folderName,
          mapIds: draft.mapIds,
          artifacts: [
            for (final artifact in draft.artifacts)
              if (artifact.handle == originalHandle)
                changedArtifact
              else
                artifact,
          ],
          sourceArtifacts: draft.sourceArtifacts,
          mutations: [
            for (final mutation in draft.mutations)
              if (mutation.operationId == cycleImport.operationId)
                NativeMutation(
                    operationId: mutation.operationId,
                    actionId: mutation.actionId,
                    sourceEntityIds: mutation.sourceEntityIds,
                    targetEntityIds: mutation.targetEntityIds,
                    parameters: {
                      ...mutation.parameters,
                      'artifactHandle': changedArtifact.handle,
                    })
              else
                mutation,
          ],
          compositionEvidence: {
            ...draft.compositionEvidence,
            'sourceSemantics': {
              ...semantics,
              'player': {
                ...player,
                'animationSheets': [
                  for (final sheet in sourceSheets)
                    if (sheet['declaration'] == 'CycleCharset')
                      {
                        ...sheet as Map,
                        'nativeOutput': {
                          ...sheet['nativeOutput'] as Map,
                          'rawSha256': changedArtifact.rawSha256.value,
                          'byteLength': changedArtifact.bytes.length,
                        },
                      }
                    else
                      sheet,
                ],
              },
            },
          });
      final pixelsApproval = approveNativeFixtureDraft(forgedPixels);
      await expectLater(
          NativeProjectWriter()
              .write(pixelsApproval.plan, pixelsApproval.context, forgedPixels),
          throwsA(isA<NativeWriteException>().having(
              (error) => error.code, 'code', 'native.semantics.regeneration')));
    } finally {
      await output.delete(recursive: true);
    }
  }, skip: scriptsPath == null || !Platform.isMacOS);
}

String _nativePlayerAsset(NativeProjectDraft draft) => draft.mutations
    .firstWhere((mutation) =>
        mutation.actionId == 'characterStudio.animationClip.upsert' &&
        mutation.parameters['state'] == 'walk')
    .parameters['sourceAssetId'] as String;
