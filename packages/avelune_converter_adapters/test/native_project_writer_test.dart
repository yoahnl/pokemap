import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/native_writer_fixture.dart';
import 'support/original_asset_fixture.dart';

Matcher get _nativeFailure => isA<NativeWriteException>()
    .having((error) => error.code, 'code', startsWith('native.'));

void main() {
  test('AC-08 canonical JSON artifact retains immutable exact content', () {
    final json = canonicalJsonOf({
      'kind': 'approvedAssetLibraryProvenance',
      'version': 1,
      'candidateHash': 'a' * 64,
    });
    final bytes = utf8.encode(json);
    final artifact = NativeArtifact(
        bytes: bytes,
        mediaType: 'application/json',
        expectedSha256: nativeFixtureHash(bytes));
    bytes[0] = 0;
    expect(artifact.reference.mediaType, 'application/json');
    expect(utf8.decode(artifact.bytes), json);
    expect(artifact.rawSha256, nativeFixtureHash(utf8.encode(json)));
    expect(() => artifact.bytes[0] = 0, throwsUnsupportedError);
  });

  test('AC-08 native artifact media types are closed', () {
    expect(
        () => NativeArtifact(bytes: const [1, 2], mediaType: 'text/plain'),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'native.artifact.media')));
  });

  test('AC-08 JSON artifacts reject noncanonical and nonobject payloads', () {
    for (final payload in [
      '{"z":1,"a":2}',
      '{"a":1,"a":2}',
      '{ "a":1}',
      '[1,2]',
      '{"value":1e999}',
      '{"value":',
    ]) {
      expect(
          () => NativeArtifact(
              bytes: utf8.encode(payload), mediaType: 'application/json'),
          throwsA(_nativeFailure),
          reason: payload);
    }
    expect(
        () => NativeArtifact(
            bytes: const [0xc3, 0x28], mediaType: 'application/json'),
        throwsA(_nativeFailure));
  });

  test('AC-08 JSON preflight rejects excessive nesting and values', () {
    expect(
        () => NativeArtifact(
            bytes: utf8.encode('{"a":{"b":{"c":1}}}'),
            mediaType: 'application/json',
            limits: const NativeWriteLimits(
                jsonLimits: ContractLimits(maxDepth: 2))),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'native.artifact.json')));
    expect(
        () => NativeArtifact(
            bytes: utf8.encode('{"a":[1,2,3]}'),
            mediaType: 'application/json',
            limits: const NativeWriteLimits(
                jsonLimits: ContractLimits(maxNodes: 4))),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'native.artifact.json')));
  });

  test('AC-08 companion JSON has an independent byte cap before copying', () {
    expect(
        () => NativeArtifact(
            bytes: List<int>.filled(1048577, 32),
            mediaType: 'application/json'),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'native.quota.artifact')));
  });

  late Directory root;
  late Directory output;
  late NativeWriterFixture fixture;
  late List<String> sourceShape;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('ac05-native-writer-');
    output = await Directory('${root.path}/output').create();
    fixture = await NativeWriterFixture.create(output.path,
        sourceRootPath: '${root.path}/original-source');
    sourceShape = await _treeShape(fixture.sourceRootPath);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  Future<void> sourceUnchanged() async {
    final actual = await _treeBytes(fixture.sourceRootPath);
    expect(actual, fixture.sourceBytes);
    expect(await _treeShape(fixture.sourceRootPath), sourceShape);
  }

  Future<void> refuseBeforeStage(NativeProjectDraft draft,
      {NativeFixtureApproval? approval,
      Matcher? failureMatcher,
      NativeWriteLimits limits = const NativeWriteLimits(),
      ScanCancellation? cancellation}) async {
    final stages = <NativeWriteStage>[];
    final creation = _RecordingCreation();
    final writer = NativeProjectWriter(
        creation: creation, checkpoint: (stage, _, __) => stages.add(stage));
    final checked = approval ?? approveNativeFixtureDraft(draft);
    final before = await _treeBytes(output.path);
    final beforeShape = await _treeShape(output.path);
    await expectLater(
        writer.write(checked.plan, checked.context, draft,
            limits: limits, cancellation: cancellation),
        throwsA(failureMatcher ?? anyOf(_nativeFailure, isA<ContractError>())));
    expect(creation.requests, isEmpty);
    expect(stages, isNot(contains(NativeWriteStage.stageCreated)));
    expect(await _treeBytes(output.path), before);
    expect(await _treeShape(output.path), beforeShape);
    await sourceUnchanged();
  }

  NativeProjectDraft withSourceArtifacts(List<NativeArtifact> witnesses,
          {NativeWriteLimits limits = const NativeWriteLimits()}) =>
      NativeProjectDraft(
          source: fixture.draft.source,
          projectName: fixture.draft.projectName,
          parentPath: fixture.draft.parentPath,
          folderName: fixture.draft.folderName,
          sourceRootPath: fixture.draft.sourceRootPath,
          mapIds: fixture.draft.mapIds,
          artifacts: fixture.draft.artifacts,
          sourceArtifacts: witnesses,
          mutations: fixture.draft.mutations,
          compositionEvidence: fixture.draft.compositionEvidence,
          limits: limits);

  test('source checkpoint import actions cannot bootstrap a fresh project', () async {
    final draft = fixture.draft;
    final changed = NativeProjectDraft(source: draft.source,
        projectName: draft.projectName, parentPath: draft.parentPath,
        folderName: draft.folderName, mapIds: draft.mapIds,
        artifacts: draft.artifacts, sourceArtifacts: draft.sourceArtifacts,
        compositionEvidence: draft.compositionEvidence,
        mutations: [...draft.mutations, NativeMutation(
          operationId: ConverterId('unsupported-source-checkpoint'), actionId: 'game_save.load',
          sourceEntityIds: draft.mutations.first.sourceEntityIds,
          targetEntityIds: draft.mutations.first.targetEntityIds, parameters: {})]);
    await refuseBeforeStage(changed);
  });

  test('AC-08 source PNG witnesses alter approval binding and are immutable',
      () {
    final witnesses = [NativeArtifact(bytes: fixture.atlasBytes)];
    final draft = withSourceArtifacts(witnesses);
    expect(draft.canonicalHash, isNot(fixture.draft.canonicalHash));
    witnesses.clear();
    expect(draft.sourceArtifacts, hasLength(1));
    expect(() => draft.sourceArtifacts.clear(), throwsUnsupportedError);
  });

  test('AC-08 source witnesses consume aggregate artifact counts and bytes',
      () {
    final witnesses = [NativeArtifact(bytes: fixture.atlasBytes)];
    expect(
        () => withSourceArtifacts(witnesses,
            limits: const NativeWriteLimits(maxArtifacts: 1)),
        throwsA(_nativeFailure));
    expect(
        () => withSourceArtifacts(witnesses,
            limits: NativeWriteLimits(
                maxTotalArtifactBytes: fixture.atlasBytes.length)),
        throwsA(_nativeFailure));
  });

  test(
      'AC-08 source witnesses without a bound library are refused before stage',
      () async {
    await refuseBeforeStage(
        withSourceArtifacts([NativeArtifact(bytes: fixture.atlasBytes)]));
  });

  Future<
          (
            OriginalAssetFixture,
            ApprovedAssetLibraryComposition,
            NativeProjectDraft,
            NativeFixtureApproval
          )>
      assetLibraryFixture(
          {AssetOutputMode mode = AssetOutputMode.standaloneObjects,
          bool includeTerrain = false}) async {
    final original = await OriginalAssetFixture.create(
        sourceRootPath: '${root.path}/asset-source');
    final literal = await original.compose(parentPath: output.path);
    final candidates = [
      original.treeCandidate(outputMode: mode),
      if (mode == AssetOutputMode.standaloneObjects)
        original.houseCandidate(outputMode: mode),
      if (includeTerrain) original.terrainCandidate(outputMode: mode),
    ].map(_approvedLibraryCandidate).toList();
    final decisions = _libraryDecisions(original, candidates);
    final library = await const ApprovedAssetLibraryComposer().compose(
        source: original.literalFixture.source,
        files: original.literalFixture.files,
        candidates: candidates,
        approvedCandidateHashes: {
          for (final candidate in candidates)
            candidate.candidateId: candidate.canonicalHash,
        },
        decisions: decisions,
        outputMode: mode);
    expect(library.canExport, isTrue);
    final base = literal.draft!;
    final artifacts = {
      for (final artifact in [...base.artifacts, ...library.artifacts])
        artifact.handle: artifact,
    };
    final draft = _copyLibraryDraft(base,
        artifacts: artifacts.values.toList(),
        sourceArtifacts: library.sourceArtifacts,
        mutations: [
          ...base.mutations,
          ...library.mutations
        ],
        evidence: {
          ...base.compositionEvidence,
          'assetLibrary': library.evidence
        });
    return (
      original,
      library,
      draft,
      _approveLibraryDraft(draft, candidates, decisions)
    );
  }

  test('approved terrain is published and survives strict native reopening',
      () async {
    final (_, library, draft, approval) =
        await assetLibraryFixture(includeTerrain: true);
    final receipt = await NativeProjectWriter()
        .write(approval.plan, approval.context, draft);
    final opened = await _NativeProject.open(receipt.projectPath);
    try {
      final snapshot = await opened.load();
      final catalog = snapshot.manifest.smartTileCatalog;
      expect(catalog.atlases, hasLength(1));
      expect(catalog.materials, hasLength(1));
      expect(catalog.presets, hasLength(1));
      final preset = catalog.presets.single;
      expect(preset.status, SmartTilePresetStatus.published);
      expect(preset.usage, SmartTileUsage.path);
      expect(preset.rules, hasLength(16));
      expect(preset.coveragePolicy, SmartTileCoveragePolicy.sparse);
      final expected = library.mutations
          .singleWhere(
              (mutation) => mutation.actionId == 'smart_tile.preset.publish')
          .parameters['preset'];
      expect(preset.toJson(), expected);
      for (final mutation
          in draft.mutations.where((entry) => entry.actionId == 'map.save')) {
        final map = mutation.parameters['map'] as Map;
        expect(snapshot.mapById(map['id'] as String)!.toJson(), map);
      }
      expect(receipt.verified, isTrue);
    } finally {
      await opened.close();
    }
  });

  test('a reapproved tampered terrain preset is refused before staging',
      () async {
    final (_, _, draft, approval) =
        await assetLibraryFixture(includeTerrain: true);
    final changed = _copyLibraryDraft(draft, mutations: [
      for (final mutation in draft.mutations)
        if (mutation.actionId == 'smart_tile.preset.publish')
          NativeMutation(
              operationId: mutation.operationId,
              actionId: mutation.actionId,
              sourceEntityIds: mutation.sourceEntityIds,
              targetEntityIds: mutation.targetEntityIds,
              parameters: {
                'preset': {
                  ...(mutation.parameters['preset'] as Map),
                  'rules': <Object?>[]
                }
              })
        else
          mutation
    ]);
    await refuseBeforeStage(changed,
        failureMatcher: isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'native.library.mutation'),
        approval: _approveLibraryDraft(
            changed, approval.context.candidates, approval.context.decisions));
  });

  test(
      'AC-08 approved library persists native resources and exact literal maps',
      () async {
    final (original, library, draft, approval) = await assetLibraryFixture();
    final before = await _treeBytes(original.literalFixture.sourceRootPath!);
    final receipt = await NativeProjectWriter()
        .write(approval.plan, approval.context, draft);
    final opened = await _NativeProject.open(receipt.projectPath);
    try {
      final snapshot = await opened.load();
      expect(snapshot.manifest.elements, hasLength(2));
      expect(snapshot.manifest.elementCategories, hasLength(2));
      expect(snapshot.manifest.tilesets, hasLength(3));
      for (final binding in library.candidateBindings) {
        final element = snapshot.manifest.elements
            .singleWhere((entry) => entry.id == binding.nativeElementId);
        expect(element.collisionProfile, isNull);
        expect(element.frames, hasLength(1));
        expect(element.frames.single.durationMs, isNull);
        final companion = library.artifacts.singleWhere(
            (artifact) => artifact.handle == binding.companionArtifactHandle);
        expect(
            await opened.handles
                .resolveProject(opened.project)
                .readBytes(binding.record['companionLogicalPath'] as String),
            companion.bytes);
        expect(
            await opened.snapshots
                .readRetainedAssetBlob(opened.project, companion.reference),
            companion.bytes);
      }
      for (final mutation
          in draft.mutations.where((value) => value.actionId == 'map.save')) {
        final raw = mutation.parameters['map'] as Map;
        expect(snapshot.mapById(raw['id'] as String)!.toJson(), raw);
      }
      expect(receipt.verified, isTrue);
      expect(receipt.published, isFalse);
      expect(receipt.assetHashes, hasLength(5));
    } finally {
      await opened.close();
    }
    expect(await _treeBytes(original.literalFixture.sourceRootPath!), before);
  });

  test('AC-08 shared library retains original atlas and literal maps',
      () async {
    final (_, library, draft, approval) =
        await assetLibraryFixture(mode: AssetOutputMode.sharedAtlas);
    final binding = library.candidateBindings.single;
    final png = library.artifacts.singleWhere(
        (artifact) => artifact.handle == binding.pngArtifactHandle);
    expect(png.bytes, draft.sourceArtifacts.single.bytes);
    final receipt = await const NativeProjectWriter()
        .write(approval.plan, approval.context, draft);
    final opened = await _NativeProject.open(receipt.projectPath);
    try {
      final snapshot = await opened.load();
      expect(snapshot.manifest.elements, hasLength(1));
      expect(snapshot.manifest.tilesets, hasLength(2));
      expect(
          snapshot.resourceBytes('assetLogical:${binding.nativeImageAssetId}'),
          png.bytes);
      for (final mutation
          in draft.mutations.where((value) => value.actionId == 'map.save')) {
        final raw = mutation.parameters['map'] as Map;
        expect(snapshot.mapById(raw['id'] as String)!.toJson(), raw);
      }
    } finally {
      await opened.close();
    }
  });

  test('AC-08 missing and foreign source witnesses fail before staging',
      () async {
    final (_, _, draft, approval) = await assetLibraryFixture();
    for (final witnesses in [
      <NativeArtifact>[],
      [NativeArtifact(bytes: fixture.atlasBytes)],
      [...draft.sourceArtifacts, NativeArtifact(bytes: fixture.atlasBytes)],
    ]) {
      final changed = _copyLibraryDraft(draft, sourceArtifacts: witnesses);
      await refuseBeforeStage(changed,
          approval: _approveLibraryDraft(changed, approval.context.candidates,
              approval.context.decisions));
    }
  });

  test('AC-08 rehashed library metadata contradictions fail before staging',
      () async {
    final (_, _, draft, approval) = await assetLibraryFixture();
    for (final field in [
      'canvasSize',
      'anchor',
      'parts',
      'sourceHashes',
      'nativeSourceRect',
      'padding',
      'nativeElementId',
      'pixelPolicy'
    ]) {
      final evidence = jsonDecode(canonicalJsonOf(draft.compositionEvidence))
          as Map<String, dynamic>;
      final library = evidence['assetLibrary'] as Map;
      final record = library['record'] as Map;
      final binding = (record['candidates'] as List).first as Map;
      binding[field] = field == 'nativeElementId' ? 'forged_element' : null;
      library['compositionHash'] = canonicalHashOf(record).value;
      final changed = _copyLibraryDraft(draft, evidence: evidence);
      await refuseBeforeStage(changed,
          approval: _approveLibraryDraft(changed, approval.context.candidates,
              approval.context.decisions));
    }
  });

  test('AC-08 rehashed and reapproved false PNG fails real source reraster',
      () async {
    final (_, library, draft, approval) = await assetLibraryFixture();
    final binding = library.candidateBindings.first;
    final oldPng = library.artifacts.singleWhere(
        (artifact) => artifact.handle == binding.pngArtifactHandle);
    final pixels = image.decodePng(Uint8List.fromList(oldPng.bytes))!;
    pixels.setPixelRgba(0, 0, 199, 17, 83, 255);
    final forged = _replaceLibraryPng(draft, binding, image.encodePng(pixels));
    expect(forged.canonicalHash, isNot(draft.canonicalHash));
    await refuseBeforeStage(forged,
        approval: _approveLibraryDraft(
            forged, approval.context.candidates, approval.context.decisions));
  });

  test('AC-08 witnesses and logical copies share bounded preflight budgets',
      () async {
    final (_, _, draft, approval) = await assetLibraryFixture();
    await refuseBeforeStage(draft,
        approval: approval,
        limits: const NativeWriteLimits(maxImagePixels: 90000));
    await refuseBeforeStage(draft,
        approval: approval,
        limits: NativeWriteLimits(
            maxTotalArtifactBytes: draft.artifacts
                .fold<int>(0, (sum, artifact) => sum + artifact.bytes.length)));
    await refuseBeforeStage(draft,
        approval: approval,
        limits: NativeWriteLimits(maxArtifacts: draft.artifacts.length));
  });

  test('AC-08 real reraster cancellation has no staging effects', () async {
    final (_, _, draft, approval) = await assetLibraryFixture();
    final cancellation = ScanCancellation();
    Timer.run(cancellation.cancel);
    final stages = <NativeWriteStage>[];
    await expectLater(
        NativeProjectWriter(checkpoint: (stage, _, __) => stages.add(stage))
            .write(approval.plan, approval.context, draft,
                cancellation: cancellation),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'native.cancelled')));
    expect(stages, isEmpty);
    expect(await _treeShape(output.path), isEmpty);
  });

  test(
      'AC-08 unbound library actions and wrong candidate consumers fail preflight',
      () async {
    final (_, library, draft, approval) = await assetLibraryFixture();
    final first = library.mutations.first;
    final wrong = NativeMutation(
        operationId: first.operationId,
        actionId: first.actionId,
        sourceEntityIds: [fixture.draft.mutations.first.sourceEntityIds.first],
        targetEntityIds: first.targetEntityIds,
        parameters: first.parameters);
    final unbound = NativeMutation(
        operationId: ConverterId('unbound:element'),
        actionId: 'element.upsert',
        sourceEntityIds: first.sourceEntityIds,
        targetEntityIds: [
          ConverterId('unbound_element')
        ],
        parameters: {
          'element': {
            ...(library.mutations
                .firstWhere((mutation) => mutation.actionId == 'element.upsert')
                .parameters['element'] as Map),
            'id': 'unbound_element'
          }
        });
    for (final mutations in [
      [
        for (final mutation in draft.mutations)
          if (mutation.operationId == first.operationId) wrong else mutation
      ],
      [...draft.mutations, unbound],
      [...draft.mutations.reversed],
    ]) {
      final changed = _copyLibraryDraft(draft, mutations: mutations);
      await refuseBeforeStage(changed,
          approval: _approveLibraryDraft(changed, approval.context.candidates,
              approval.context.decisions));
    }
  });

  test(
      'AC-08 library candidates cannot consume unbound atlas timeline mutations',
      () async {
    final (_, library, draft, approval) = await assetLibraryFixture();
    final binding = library.candidateBindings.first;
    final atlasImport = library.mutations
        .firstWhere((mutation) => mutation.actionId == 'tileset.import_image');
    final size = binding.record['paddedSize'] as Map;
    final timeline = NativeMutation(
        operationId: ConverterId('unbound_library_timeline'),
        actionId: 'tileset.upsert',
        sourceEntityIds: atlasImport.sourceEntityIds,
        targetEntityIds: [
          ConverterId(binding.nativeTilesetId)
        ],
        parameters: {
          'tileset': ProjectTilesetEntry(
              id: binding.nativeTilesetId,
              name: atlasImport.parameters['name'] as String,
              relativePath: 'assets/studio/${binding.nativeTilesetId}.png',
              source: ProjectRegularAtlasTilesetSource(
                  assetId: binding.nativeImageAssetId,
                  pixelWidth: size['width'] as int,
                  pixelHeight: size['height'] as int,
                  tileWidth: 32,
                  tileHeight: 32,
                  tileAnimations: const [
                    ProjectRegularAtlasTileAnimation(tileId: 0, frames: [
                      ProjectImageCollectionAnimationFrame(
                          tileId: 0, durationMs: 250),
                      ProjectImageCollectionAnimationFrame(
                          tileId: 1, durationMs: 250)
                    ])
                  ])).toJson()
        });
    final ids =
        library.mutations.map((mutation) => mutation.operationId).toSet();
    final literal = draft.mutations
        .where((mutation) => !ids.contains(mutation.operationId));
    final changed = _copyLibraryDraft(draft, mutations: [
      ...literal.where((mutation) => mutation.actionId.startsWith('tileset.')),
      ...library.mutations,
      timeline,
      ...literal.where((mutation) => !mutation.actionId.startsWith('tileset.')),
    ]);
    await refuseBeforeStage(changed,
        approval: _approveLibraryDraft(
            changed, approval.context.candidates, approval.context.decisions));
  });

  for (final corruption in [
    'companion',
    'companion blob',
    'catalog',
    'element',
    'category'
  ]) {
    test('AC-08 fresh native verification rejects altered $corruption',
        () async {
      final (_, library, draft, approval) = await assetLibraryFixture();
      final binding = library.candidateBindings.first;
      var verified = false;
      await expectLater(
          NativeProjectWriter(checkpoint: (stage, _, projectPath) async {
            if (stage == NativeWriteStage.afterNativeVerify) verified = true;
            if (stage != NativeWriteStage.beforeNativeVerify) return;
            if (corruption == 'companion' || corruption == 'companion blob') {
              final artifact = library.artifacts.singleWhere(
                  (entry) => entry.handle == binding.companionArtifactHandle);
              final relative = corruption == 'companion'
                  ? binding.record['companionLogicalPath'] as String
                  : assetBlobStorageKey(artifact.reference);
              await File('$projectPath/$relative').writeAsString('{}');
            } else if (corruption == 'catalog') {
              final file = File('$projectPath/$assetCatalogStorageKey');
              final raw = jsonDecode(await file.readAsString()) as Map;
              for (final row in raw['records'] as List) {
                if ((row as Map)['id'] == binding.companionAssetId) {
                  row['tags'] = ['forged'];
                }
              }
              await file.writeAsString(jsonEncode(raw));
            } else {
              final file = File('$projectPath/project.json');
              final raw = jsonDecode(await file.readAsString()) as Map;
              final rows = raw[corruption == 'element'
                  ? 'elements'
                  : 'elementCategories'] as List;
              (rows.first as Map)['name'] = 'Forged native library';
              await file.writeAsString(jsonEncode(raw));
            }
          }).write(approval.plan, approval.context, draft),
          throwsA(_nativeFailure));
      expect(verified, isFalse);
    });
  }

  test('AC-08 logical companion drift after verification prevents success',
      () async {
    final (_, library, draft, approval) = await assetLibraryFixture();
    final binding = library.candidateBindings.first;
    var verified = false;
    await expectLater(
        NativeProjectWriter(checkpoint: (stage, _, projectPath) async {
          if (stage != NativeWriteStage.afterNativeVerify) return;
          verified = true;
          await File('$projectPath/${binding.record['companionLogicalPath']}')
              .writeAsString('{}');
        }).write(approval.plan, approval.context, draft),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'native.verify.changed')));
    expect(verified, isTrue);
  });

  test('controlled source and admission are valid before the native writer',
      () {
    expect(fixture.source.canPlan, isTrue);
    expect(fixture.source.maps.single.map.width, 3);
    expect(fixture.source.maps.single.map.height, 3);
    expect(fixture.source.maps.single.map.tileWidth, 32);
    expect(fixture.source.maps.single.map.layers.first.cells,
        [384, 385, 0, 385, 384, 385, 0, 385, 384]);
    expect(admitPlan(fixture.plan, fixture.context).plan, same(fixture.plan));
    expect(fixture.plan.exampleOnly, isFalse);
    expect(
        fixture.plan.operations.every((operation) =>
            operation.evidenceRefs.contains(fixture.draft.bindingEvidence)),
        isTrue);
  });

  NativeProjectDraft animatedDraft({ProjectTilesetEntry? replacement}) {
    final entry = replacement ??
        ProjectTilesetEntry(
          id: 'fixture_atlas',
          name: 'Original two tiles',
          relativePath: 'assets/studio/fixture_atlas.png',
          source: const ProjectRegularAtlasTilesetSource(
            assetId: 'image_fixture_atlas',
            pixelWidth: 64,
            pixelHeight: 32,
            tileWidth: 32,
            tileHeight: 32,
            tileAnimations: [
              ProjectRegularAtlasTileAnimation(tileId: 0, frames: [
                ProjectImageCollectionAnimationFrame(
                    tileId: 0, durationMs: 100),
                ProjectImageCollectionAnimationFrame(
                    tileId: 1, durationMs: 150),
                ProjectImageCollectionAnimationFrame(
                    tileId: 0, durationMs: 250),
              ]),
            ],
          ),
        );
    return copyNativeFixtureDraft(fixture.draft, mutations: [
      fixture.draft.mutations.first,
      NativeMutation(
        operationId: ConverterId('fixture-animation'),
        actionId: 'tileset.upsert',
        sourceEntityIds: fixture.draft.mutations.first.sourceEntityIds,
        targetEntityIds: [ConverterId('fixture_atlas')],
        parameters: {'tileset': entry.toJson()},
      ),
      ...fixture.draft.mutations.skip(1),
    ]);
  }

  test('AC-07 native upsert preserves the exact three frame timeline on reopen',
      () async {
    final draft = animatedDraft();
    final approval = approveNativeFixtureDraft(draft);
    final receipt = await NativeProjectWriter()
        .write(approval.plan, approval.context, draft);
    final opened = await _NativeProject.open(receipt.projectPath);
    try {
      final snapshot = await opened.load();
      final expected = draft.mutations[1].parameters['tileset'];
      expect(snapshot.manifest.tilesets.single.toJson(), expected);
      expect(receipt.verified, isTrue);
      expect(receipt.published, isFalse);
    } finally {
      await opened.close();
    }
    await sourceUnchanged();
  });

  test('AC-07 animation upsert cannot change the imported atlas geometry',
      () async {
    await refuseBeforeStage(animatedDraft(
      replacement: const ProjectTilesetEntry(
        id: 'fixture_atlas',
        name: 'Original two tiles',
        relativePath: 'assets/studio/fixture_atlas.png',
        source: ProjectRegularAtlasTilesetSource(
          assetId: 'image_fixture_atlas',
          pixelWidth: 96,
          pixelHeight: 32,
          tileWidth: 32,
          tileHeight: 32,
        ),
      ),
    ));
  });

  test('AC-07 removed timeline fails strict post-mutation verification',
      () async {
    final draft = animatedDraft();
    final approval = approveNativeFixtureDraft(draft);
    var tampered = false;
    await expectLater(
      NativeProjectWriter(checkpoint: (stage, _, projectPath) async {
        if (stage != NativeWriteStage.beforeNativeVerify) return;
        final file = File('$projectPath/project.json');
        final manifest = jsonDecode(await file.readAsString()) as Map;
        final tileset = (manifest['tilesets'] as List).single as Map;
        (tileset['source'] as Map).remove('tileAnimations');
        await file.writeAsString(jsonEncode(manifest), flush: true);
        tampered = true;
      }).write(approval.plan, approval.context, draft),
      throwsA(isA<NativeWriteException>()
          .having((error) => error.code, 'code', 'native.verify.manifest')),
    );
    expect(tampered, isTrue);
    await sourceUnchanged();
  });

  test(
      'NAT-01 bootstraps empty twoD32 and strict native loader reads map and image',
      () async {
    final creation = _RecordingCreation();
    var bootstrapChecked = false;
    final receipt = await NativeProjectWriter(
      creation: creation,
      checkpoint: (stage, _, projectPath) async {
        if (stage == NativeWriteStage.afterBootstrap) {
          final opened = await _NativeProject.open(projectPath!);
          try {
            final snapshot = await opened.load();
            expect(snapshot.manifest.maps, isEmpty);
            expect(snapshot.manifest.tilesets, isEmpty);
            expect(snapshot.manifest.characters, isEmpty);
            expect(snapshot.manifest.newGame.enabled, isFalse);
            bootstrapChecked = true;
          } finally {
            await opened.close();
          }
        }
      },
    ).write(fixture.plan, fixture.context, fixture.draft);
    expect(bootstrapChecked, isTrue);
    expect(creation.requests, hasLength(1));
    expect(creation.requests.single.template, ProjectCreationTemplate.empty);
    expect(creation.requests.single.dimension, ProjectDimension.twoD);
    expect(creation.requests.single.tileSize, 32);
    expect(receipt.verified, isTrue);
    expect(receipt.published, isFalse);
    expect(receipt.draftHash, fixture.draft.canonicalHash);
    expect(await Directory(receipt.stagingRoot).exists(), isTrue);
    expect(receipt.projectPath.startsWith('${receipt.stagingRoot}/'), isTrue);
    expect(
        await Directory('${output.path}/${fixture.draft.folderName}').exists(),
        isFalse);
    final opened = await _NativeProject.open(receipt.projectPath);
    try {
      final snapshot = await opened.load();
      expect(snapshot.loadDiagnostics, isEmpty);
      expect(snapshot.maps.single, fixture.expectedMap);
      expect(snapshot.manifest.settings.tileWidth, 32);
      expect(snapshot.manifest.settings.tileHeight, 32);
      expect(snapshot.manifest.settings.dimension, ProjectDimension.twoD);
      expect(snapshot.manifest.maps.single.id, fixture.expectedMap.id);
      final source = snapshot.manifest.tilesets.single.source!
          as ProjectRegularAtlasTilesetSource;
      expect(source.assetId, 'image_fixture_atlas');
      expect((source.pixelWidth, source.pixelHeight), (64, 32));
      expect((source.tileWidth, source.tileHeight), (32, 32));
      final catalog = AssetCatalog.fromJson(jsonDecode(
              utf8.decode(snapshot.resourceBytes(assetCatalogResourceIdentity)))
          as Map<String, dynamic>);
      final asset = catalog.require(source.assetId);
      final logical = await File('${receipt.projectPath}/${asset.logicalPath}')
          .readAsBytes();
      final blob = await File(
              '${receipt.projectPath}/${assetBlobStorageKey(asset.artifact)}')
          .readAsBytes();
      expect(logical, fixture.atlasBytes);
      expect(blob, fixture.atlasBytes);
      expect(
          await opened.snapshots
              .readRetainedAssetBlob(opened.project, asset.artifact),
          fixture.atlasBytes);
      final raster = image.decodePng(logical)!;
      expect((raster.width, raster.height), (64, 32));
      expect(raster.getPixel(16, 16).r, 191);
      expect(raster.getPixel(48, 16).g, 173);
      expect(raster.getPixel(0, 0).a, 0);
      final entry = snapshot.manifest.maps.single;
      expect(
          receipt.mapHashes[entry.id],
          nativeFixtureHash(
              await File('${receipt.projectPath}/${entry.relativePath}')
                  .readAsBytes()));
      expect(receipt.assetHashes[asset.id], nativeFixtureHash(logical));
      expect(receipt.nativeRevision, snapshot.revision);
    } finally {
      await opened.close();
    }
    await sourceUnchanged();
  });

  test('NAT-02 native map save survives fresh open and exact disk reload',
      () async {
    final receipt = await const NativeProjectWriter()
        .write(fixture.plan, fixture.context, fixture.draft);
    final opened = await _NativeProject.open(receipt.projectPath);
    late MapData edited;
    late List<int> savedBytes;
    late String mapPath;
    try {
      final snapshot = await opened.load();
      final layer = snapshot.maps.single.layers.single as TileLayer;
      edited = snapshot.maps.single.copyWith(
        name: 'Native edit preserved',
        layers: [
          layer.copyWith(cells: [2, ...layer.cells.skip(1)])
        ],
      );
      mapPath = snapshot.manifest.maps.single.relativePath;
      await opened.save(edited, snapshot.revision);
      savedBytes = await File('${receipt.projectPath}/$mapPath').readAsBytes();
      expect(
          MapData.fromJson(
              jsonDecode(utf8.decode(savedBytes)) as Map<String, dynamic>),
          edited);
    } finally {
      await opened.close();
    }
    final fresh = await _NativeProject.open(receipt.projectPath);
    try {
      final reloaded = await fresh.load();
      expect(reloaded.maps.single, edited);
      expect(reloaded.maps.single.name, 'Native edit preserved');
      expect((reloaded.maps.single.layers.single as TileLayer).cells.first, 2);
      expect(await File('${receipt.projectPath}/$mapPath').readAsBytes(),
          savedBytes);
    } finally {
      await fresh.close();
    }
    await sourceUnchanged();
  });

  test('NAT-03 native codecs keep canonical palette cells and tileset source',
      () async {
    final receipt = await const NativeProjectWriter()
        .write(fixture.plan, fixture.context, fixture.draft);
    final opened = await _NativeProject.open(receipt.projectPath);
    try {
      final snapshot = await opened.load();
      final manifestJson = jsonDecode(
              await File('${receipt.projectPath}/project.json').readAsString())
          as Map<String, dynamic>;
      final mapJson = jsonDecode(await File(
              '${receipt.projectPath}/${snapshot.manifest.maps.single.relativePath}')
          .readAsString()) as Map<String, dynamic>;
      expect(manifestJson.containsKey('surfaceCatalog'), isFalse);
      expect(mapJson['version'], 'v8');
      expect(mapJson.containsKey('spatialScene'), isFalse);
      final layerJson = (mapJson['layers'] as List).single as Map;
      expect(layerJson.containsKey('tiles'), isFalse);
      expect(layerJson.containsKey('tilesetId'), isFalse);
      expect(layerJson['cells'], [1, 2, 0, 2, 1, 2, 0, 2, 1]);
      expect(layerJson['palette'], hasLength(2));
      final map = MapData.fromJson(mapJson);
      final manifest = ProjectManifest.fromJson(manifestJson);
      expect(map, fixture.expectedMap);
      expect(
          manifest.tilesets.single.source!.toJson()['kind'], 'regular_atlas');
      ProjectValidator.validate(manifest, maps: [map]);
      MapValidator.validate(map, projectDialogueContext: manifest);
      final source = manifest.tilesets.single.source!;
      expect(
          ProjectTilesetSource.fromJson(
                  Map<String, dynamic>.from(source.toJson()))
              .toJson(),
          source.toJson());
    } finally {
      await opened.close();
    }
  });

  test('NAT-04 offline success never asks HTTP or template to read', () async {
    final network = _NetworkTrap();
    final templateCalls = <Uri>[];
    final creation = LocalProjectCreationService(
      clairbois: ClairboisProjectTemplate(read: (uri) async {
        templateCalls.add(uri);
        throw StateError('Template network trap');
      }),
    );
    final receipt = await HttpOverrides.runZoned(
        () => NativeProjectWriter(creation: creation)
            .write(fixture.plan, fixture.context, fixture.draft),
        createHttpClient: network.create);
    expect(receipt.verified, isTrue);
    expect(network.calls, 0);
    expect(templateCalls, isEmpty);
    await sourceUnchanged();
  });

  test('NAT-04 refused admission never asks HTTP or template to read',
      () async {
    final network = _NetworkTrap();
    final templateCalls = <Uri>[];
    final approval = approveNativeFixtureDraft(fixture.draft,
        bindingEvidence: 'native-draft-sha256:${'0' * 64}');
    final creation = LocalProjectCreationService(
      clairbois: ClairboisProjectTemplate(read: (uri) async {
        templateCalls.add(uri);
        throw StateError('Template network trap');
      }),
    );
    await expectLater(
        HttpOverrides.runZoned(
            () => NativeProjectWriter(creation: creation)
                .write(approval.plan, approval.context, fixture.draft),
            createHttpClient: network.create),
        throwsA(_nativeFailure));
    expect(network.calls, 0);
    expect(templateCalls, isEmpty);
    expect(await _treeShape(output.path), isEmpty);
    await sourceUnchanged();
  });

  for (final policy in ['draft', 'unapproved', 'example', 'online']) {
    test('rejects $policy plan before filesystem effects', () async {
      if (policy == 'unapproved') {
        expect(
            () => approveNativeFixtureDraft(fixture.draft, approved: false),
            throwsA(isA<ContractError>()
                .having((error) => error.code, 'code', 'shape.const')
                .having((error) => error.path, 'path', r'$.approvedByHuman')));
        expect(await _treeShape(output.path), isEmpty);
        await sourceUnchanged();
        return;
      }
      final approval = approveNativeFixtureDraft(fixture.draft,
          state: policy == 'draft' ? 'draft' : 'ready',
          approved: policy != 'unapproved',
          exampleOnly: policy == 'example',
          offline: policy != 'online');
      await refuseBeforeStage(fixture.draft, approval: approval);
    });
  }

  test('rejects stale approval and draft evidence before filesystem effects',
      () async {
    final changed = copyNativeFixtureDraft(fixture.draft,
        projectName: 'Changed after review');
    await refuseBeforeStage(changed,
        approval: NativeFixtureApproval(fixture.plan, fixture.context));
    await refuseBeforeStage(fixture.draft,
        approval: approveNativeFixtureDraft(fixture.draft,
            bindingEvidence: 'native-draft-sha256:${'0' * 64}'));
  });

  for (final mutation in [
    'params',
    'order',
    'bytes',
    'action',
    'version',
    'source',
    'target'
  ]) {
    test('rejects $mutation changed after exact draft approval', () async {
      final original = fixture.draft;
      final operations = original.mutations.toList();
      var artifacts = original.artifacts;
      switch (mutation) {
        case 'params':
          operations[1] = copyNativeFixtureMutation(operations[1],
              parameters: {...operations[1].parameters, 'name': 'Changed'});
        case 'order':
          operations.replaceRange(0, 2, [operations[1], operations[0]]);
        case 'bytes':
          artifacts = [
            NativeArtifact(bytes: [...fixture.atlasBytes, 0])
          ];
        case 'action':
          operations[1] = copyNativeFixtureMutation(operations[1],
              actionId: 'map.delete_apply');
        case 'version':
          operations[1] =
              copyNativeFixtureMutation(operations[1], actionVersion: 2);
        case 'source':
          operations[1] = copyNativeFixtureMutation(operations[1],
              sourceEntityIds: [ConverterId('unknown-source')]);
        case 'target':
          operations[1] = copyNativeFixtureMutation(operations[1],
              targetEntityIds: [ConverterId('unknown-target')]);
      }
      final changed = copyNativeFixtureDraft(original,
          mutations: operations, artifacts: artifacts);
      await refuseBeforeStage(changed,
          approval: NativeFixtureApproval(fixture.plan, fixture.context));
    });
  }

  test('rejects admitted map bindings that do not match source and native ids',
      () async {
    for (final changed in [
      copyNativeFixtureDraft(fixture.draft,
          mapIds: {8: fixture.expectedMap.id}),
      copyNativeFixtureDraft(fixture.draft, mapIds: {1: 'different-map'}),
      copyNativeFixtureDraft(fixture.draft,
          mutations: fixture.draft.mutations.skip(1).toList()),
      copyNativeFixtureDraft(fixture.draft,
          mutations: fixture.draft.mutations
              .where((value) => value.actionId != 'map.save')
              .toList()),
    ]) {
      await refuseBeforeStage(changed);
    }
  });

  test('rejects separately admitted wrong action version and foreign source id',
      () async {
    for (final operation in [
      copyNativeFixtureMutation(fixture.draft.mutations[1], actionVersion: 2),
      copyNativeFixtureMutation(fixture.draft.mutations[1],
          sourceEntityIds: [ConverterId('foreign-source')]),
      copyNativeFixtureMutation(fixture.draft.mutations[1],
          targetEntityIds: [ConverterId('foreign-target')]),
    ]) {
      await refuseBeforeStage(copyNativeFixtureDraft(fixture.draft, mutations: [
        fixture.draft.mutations[0],
        operation,
        fixture.draft.mutations[2]
      ]));
    }
  });

  test('rejects output parent equal to or inside the source before effects',
      () async {
    for (final parent in [
      fixture.sourceRootPath,
      '${fixture.sourceRootPath}/nested-output'
    ]) {
      final changed = copyNativeFixtureDraft(fixture.draft, parentPath: parent);
      await refuseBeforeStage(changed);
    }
  });

  test('source containment preflight resolves a symlinked output parent',
      () async {
    final alias = Link('${root.path}/source-parent-alias');
    await alias.create(fixture.sourceRootPath);
    await refuseBeforeStage(
        copyNativeFixtureDraft(fixture.draft, parentPath: alias.path));
    expect(await alias.target(), fixture.sourceRootPath);
  });

  test('incomplete normalization cannot enter native staging even if admitted',
      () async {
    final blocked = await const RmxpSourceNormalizer().normalize(
      snapshot: fixture.source.snapshot,
      files:
          _OnDiskSourceFiles(fixture.source.snapshot, fixture.sourceRootPath),
      selectedMapIds: {8},
    );
    expect(blocked.canPlan, isFalse);
    expect(() => copyNativeFixtureDraft(fixture.draft, source: blocked),
        throwsA(_nativeFailure));
    expect(await _treeShape(output.path), isEmpty);
    await sourceUnchanged();
  });

  test('existing destination sentinel is never touched', () async {
    final destination =
        await Directory('${output.path}/${fixture.draft.folderName}').create();
    await File('${destination.path}/sentinel.bin').writeAsBytes([7, 1, 9]);
    await refuseBeforeStage(fixture.draft);
    expect(await File('${destination.path}/sentinel.bin').readAsBytes(),
        [7, 1, 9]);
    expect(await _treeBytes(destination.path), {
      'sentinel.bin': [7, 1, 9]
    });
  });

  test('late destination collision is preserved and never publishes staging',
      () async {
    String? stagePath;
    final destination = Directory('${output.path}/${fixture.draft.folderName}');
    await expectLater(
        NativeProjectWriter(checkpoint: (stage, stagingRoot, _) async {
          stagePath ??= stagingRoot;
          if (stage == NativeWriteStage.afterMutations) {
            await destination.create();
            await File('${destination.path}/external.bin').writeAsBytes([3, 8]);
          }
        }).write(fixture.plan, fixture.context, fixture.draft),
        throwsA(_nativeFailure));
    expect(await _treeBytes(destination.path), {
      'external.bin': [3, 8]
    });
    expect(stagePath, isNotNull);
    expect(await Directory(stagePath!).exists(), isTrue);
    await sourceUnchanged();
  });

  test(
      'substituted child project symlink cannot mutate an external native project',
      () async {
    final external = await const LocalProjectCreationService().create(
      ProjectCreationRequest(
        name: 'External native fixture',
        folderName: 'external-native',
        parentPath: root.path,
        template: ProjectCreationTemplate.empty,
        dimension: ProjectDimension.twoD,
        tileSize: 32,
        mapWidth: 3,
        mapHeight: 3,
      ),
    );
    await File('${external.projectPath}/external-sentinel.bin')
        .writeAsBytes([4, 9, 1]);
    final before = await _treeBytes(external.projectPath);
    final beforeShape = await _treeShape(external.projectPath);
    String? observedStage;
    NativeWriteException? failure;
    final stages = <NativeWriteStage>[];
    try {
      await NativeProjectWriter(
          checkpoint: (stage, stagingRoot, projectPath) async {
        stages.add(stage);
        if (stage == NativeWriteStage.afterBootstrap) {
          observedStage = stagingRoot;
          await Directory(projectPath!)
              .rename('$stagingRoot/owned-project-backup');
          await Link(projectPath).create(external.projectPath);
        }
      }).write(fixture.plan, fixture.context, fixture.draft);
      fail('Writer accepted an external project through a substituted symlink');
    } on NativeWriteException catch (error) {
      failure = error;
    }
    expect(failure, _nativeFailure);
    expect(failure.code, 'native.project.changed');
    expect(failure.stagingPath, observedStage);
    expect(observedStage, isNotNull);
    expect(stages, isNot(contains(NativeWriteStage.afterMutation)));
    expect(await _treeBytes(external.projectPath), before);
    expect(await _treeShape(external.projectPath), beforeShape);
    expect(
        await Directory('${output.path}/${fixture.draft.folderName}').exists(),
        isFalse);
    await sourceUnchanged();
  });

  for (final point in [
    NativeWriteStage.stageCreated,
    NativeWriteStage.afterBootstrap,
    NativeWriteStage.afterMutation,
    NativeWriteStage.beforeNativeVerify
  ]) {
    test('failure at ${point.name} keeps staging and source without success',
        () async {
      String? observed;
      NativeWriteException? failure;
      try {
        await NativeProjectWriter(checkpoint: (stage, stagingRoot, _) {
          if (stage == point) {
            observed = stagingRoot;
            throw const FileSystemException('Controlled native writer fault');
          }
        }).write(fixture.plan, fixture.context, fixture.draft);
        fail('Writer returned success after an injected failure');
      } on NativeWriteException catch (error) {
        failure = error;
      }
      expect(observed, isNotNull);
      expect(failure.stagingPath, observed);
      expect(await Directory(observed!).exists(), isTrue);
      expect(
          await Directory('${output.path}/${fixture.draft.folderName}')
              .exists(),
          isFalse);
      await sourceUnchanged();
    });
  }

  test('pre-cancelled write has no filesystem effects', () async {
    await refuseBeforeStage(fixture.draft,
        cancellation: ScanCancellation()..cancel());
  });

  test('cancellation after bootstrap retains staging and never verifies',
      () async {
    final cancellation = ScanCancellation();
    String? stagePath;
    final stages = <NativeWriteStage>[];
    await expectLater(
        NativeProjectWriter(checkpoint: (stage, stagingRoot, _) {
          stages.add(stage);
          if (stage == NativeWriteStage.afterBootstrap) {
            stagePath = stagingRoot;
            cancellation.cancel();
          }
        }).write(fixture.plan, fixture.context, fixture.draft,
            cancellation: cancellation),
        throwsA(anyOf(_nativeFailure, isA<ContractError>())));
    expect(stagePath, isNotNull);
    expect(await Directory(stagePath!).exists(), isTrue);
    expect(stages, isNot(contains(NativeWriteStage.afterNativeVerify)));
    expect(
        await Directory('${output.path}/${fixture.draft.folderName}').exists(),
        isFalse);
    await sourceUnchanged();
  });

  for (final corruption in [
    'map',
    'logical PNG',
    'blob PNG',
    'missing image'
  ]) {
    test('native verification refuses $corruption introduced in staging',
        () async {
      String? stagePath;
      await expectLater(
          NativeProjectWriter(
              checkpoint: (stage, stagingRoot, projectPath) async {
            stagePath ??= stagingRoot;
            if (stage == NativeWriteStage.beforeNativeVerify) {
              if (corruption == 'map') {
                await File('$projectPath/maps/fixture_map.json')
                    .writeAsString('{"version":"v9"}');
              } else {
                final catalog = AssetCatalog.fromJson(jsonDecode(
                    await File('$projectPath/$assetCatalogStorageKey')
                        .readAsString()) as Map<String, dynamic>);
                final record = catalog.records.single;
                final file = File(
                    '$projectPath/${corruption == 'blob PNG' ? assetBlobStorageKey(record.artifact) : record.logicalPath}');
                if (corruption == 'missing image') {
                  await file.delete();
                } else {
                  await file.writeAsBytes([137, 80, 78, 71, 0]);
                }
              }
            }
          }).write(fixture.plan, fixture.context, fixture.draft),
          throwsA(_nativeFailure));
      expect(stagePath, isNotNull);
      expect(await Directory(stagePath!).exists(), isTrue);
      expect(
          await Directory('${output.path}/${fixture.draft.folderName}')
              .exists(),
          isFalse);
      await sourceUnchanged();
    });
  }

  test('missing and unreferenced artifacts are rejected before staging',
      () async {
    await refuseBeforeStage(
        copyNativeFixtureDraft(fixture.draft, artifacts: []));
    final raster = image.Image(width: 32, height: 32);
    final extra = NativeArtifact(bytes: image.encodePng(raster));
    await refuseBeforeStage(copyNativeFixtureDraft(fixture.draft,
        artifacts: [...fixture.draft.artifacts, extra]));
  });

  test('aggregate pixel quota precedes decoding of a malformed second PNG',
      () async {
    final malformed = NativeArtifact(
        bytes: nativeFixturePngWithIdat(fixture.atlasBytes, [0]));
    final firstImport = fixture.draft.mutations.first;
    final secondImport = copyNativeFixtureMutation(
      firstImport,
      operationId: ConverterId('fixture-second-image'),
      targetEntityIds: [
        ConverterId('fixture_second'),
        ConverterId('image_fixture_second')
      ],
      parameters: {
        ...firstImport.parameters,
        'artifactHandle': malformed.handle,
        'tilesetId': 'fixture_second'
      },
    );
    final create = copyNativeFixtureMutation(fixture.draft.mutations[1],
        parameters: {
          ...fixture.draft.mutations[1].parameters,
          'tilesetId': 'fixture_atlas'
        });
    final draft = copyNativeFixtureDraft(
      fixture.draft,
      artifacts: [...fixture.draft.artifacts, malformed],
      mutations: [
        firstImport,
        secondImport,
        create,
        fixture.draft.mutations.last
      ],
    );
    final approval = approveNativeFixtureDraft(draft);
    final creation = _RecordingCreation();
    await expectLater(
        NativeProjectWriter(creation: creation).write(
            approval.plan, approval.context, draft,
            limits: const NativeWriteLimits(maxImagePixels: 2048)),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'native.quota.image')));
    expect(creation.requests, isEmpty);
    expect(await _treeShape(output.path), isEmpty);
    await sourceUnchanged();
  });

  test('one approved artifact cannot bypass output budgets through two imports',
      () async {
    final firstImport = fixture.draft.mutations.first;
    final secondImport = copyNativeFixtureMutation(
      firstImport,
      operationId: ConverterId('fixture-duplicate-artifact'),
      targetEntityIds: [
        ConverterId('fixture_second'),
        ConverterId('image_fixture_second')
      ],
      parameters: {...firstImport.parameters, 'tilesetId': 'fixture_second'},
    );
    final create = copyNativeFixtureMutation(fixture.draft.mutations[1],
        parameters: {
          ...fixture.draft.mutations[1].parameters,
          'tilesetId': 'fixture_atlas'
        });
    final draft = copyNativeFixtureDraft(
      fixture.draft,
      mutations: [
        firstImport,
        secondImport,
        create,
        fixture.draft.mutations.last
      ],
    );
    await refuseBeforeStage(draft,
        limits: NativeWriteLimits(
            maxTotalArtifactBytes: fixture.atlasBytes.length));
  });

  test('malformed PNG and invalid palette map cannot return verified success',
      () async {
    final malformed = NativeArtifact(bytes: [137, 80, 78, 71, 13, 10, 26, 10]);
    final import = copyNativeFixtureMutation(fixture.draft.mutations.first,
        parameters: {
          ...fixture.draft.mutations.first.parameters,
          'artifactHandle': malformed.handle
        });
    final badImage = copyNativeFixtureDraft(fixture.draft,
        artifacts: [malformed],
        mutations: [import, ...fixture.draft.mutations.skip(1)]);
    final approval = approveNativeFixtureDraft(badImage);
    await expectLater(
        const NativeProjectWriter()
            .write(approval.plan, approval.context, badImage),
        throwsA(_nativeFailure));
    final map = fixture.expectedMap.toJson();
    ((map['layers'] as List).single as Map)['cells'] = List<int>.filled(9, 3);
    final badSave = copyNativeFixtureMutation(fixture.draft.mutations.last,
        parameters: {'map': map});
    final badMap = copyNativeFixtureDraft(fixture.draft,
        mutations: [...fixture.draft.mutations.take(2), badSave]);
    final second = approveNativeFixtureDraft(badMap);
    await expectLater(
        const NativeProjectWriter().write(second.plan, second.context, badMap),
        throwsA(_nativeFailure));
    expect(
        await Directory('${output.path}/${fixture.draft.folderName}').exists(),
        isFalse);
    await sourceUnchanged();
  });

  for (final limit in [
    const NativeWriteLimits(maxMutations: 2),
    const NativeWriteLimits(maxArtifactBytes: 8),
    const NativeWriteLimits(maxTotalArtifactBytes: 8),
    const NativeWriteLimits(maxImagePixels: 2047),
    const NativeWriteLimits(maxMapCells: 8),
  ]) {
    test(
        'effective writer quota preflights before filesystem allocation ${[
          limit.maxMutations,
          limit.maxArtifactBytes,
          limit.maxTotalArtifactBytes,
          limit.maxImagePixels,
          limit.maxMapCells
        ]}', () async {
      await refuseBeforeStage(fixture.draft, limits: limit);
    });
  }

  test('draft inputs and nested collections are immutable after approval', () {
    final bytes = fixture.atlasBytes.toList();
    final artifact = NativeArtifact(bytes: bytes);
    final parameters = <String, Object?>{
      'nested': [
        1,
        {'value': 'before'}
      ]
    };
    final sourceIds = [ConverterId('a')];
    final mutation = NativeMutation(
        operationId: ConverterId('immutable'),
        actionId: 'map.create',
        sourceEntityIds: sourceIds,
        targetEntityIds: [ConverterId('b')],
        parameters: parameters);
    bytes[0] = 0;
    sourceIds.clear();
    (parameters['nested'] as List).clear();
    expect(artifact.bytes, fixture.atlasBytes);
    expect(mutation.sourceEntityIds, [ConverterId('a')]);
    expect(mutation.parameters['nested'], [
      1,
      {'value': 'before'}
    ]);
    expect(() => artifact.bytes[0] = 0, throwsUnsupportedError);
    expect(() => mutation.parameters['new'] = true, throwsUnsupportedError);
    expect(() => (mutation.parameters['nested'] as List).clear(),
        throwsUnsupportedError);
    expect(() => fixture.draft.mapIds[8] = 'other', throwsUnsupportedError);
    expect(() => fixture.draft.mutations.clear(), throwsUnsupportedError);
    expect(
        () => NativeArtifact(
            bytes: fixture.atlasBytes, expectedSha256: Sha256Hash('0' * 64)),
        throwsA(_nativeFailure));
  });
}

Future<Map<String, List<int>>> _treeBytes(String path) async {
  final directory = Directory(path);
  if (!await directory.exists()) return {};
  final result = <String, List<int>>{};
  await for (final entry
      in directory.list(recursive: true, followLinks: false)) {
    if (entry is File) {
      result[entry.path.substring(path.length + 1)] = await entry.readAsBytes();
    }
  }
  return result;
}

Future<List<String>> _treeShape(String path) async {
  final directory = Directory(path);
  if (!await directory.exists()) return [];
  final result = <String>[];
  await for (final entry
      in directory.list(recursive: true, followLinks: false)) {
    final relative = entry.path.substring(path.length + 1);
    result.add(switch (entry) {
      File() => 'file:$relative',
      Directory() => 'directory:$relative',
      Link() => 'link:$relative:${await entry.target()}',
      _ => 'special:$relative',
    });
  }
  return result..sort();
}

AssetCandidate _approvedLibraryCandidate(AssetCandidate candidate) =>
    AssetCandidate.fromJson({
      ...candidate.toJson(),
      'state': 'approved',
      'approvedRevision': candidate.revision,
    });

ReviewDecisions _libraryDecisions(
        OriginalAssetFixture fixture, List<AssetCandidate> candidates) =>
    ReviewDecisions.fromJson({
      'schemaVersion': '1.0',
      'kind': 'reviewDecisions',
      'exampleOnly': false,
      'sessionId': 'original-writer-library-session',
      'sourceSnapshotHash': fixture.literalFixture.snapshot.canonicalHash.value,
      'revision': 1,
      'decisions': [
        for (final candidate in candidates)
          {
            'decisionId': 'approve:${candidate.candidateId.value}',
            'candidateId': candidate.candidateId.value,
            'candidateRevision': candidate.revision,
            'action': 'approve',
            'humanConfirmed': true,
            'replacementCandidateIds': <String>[],
            'note': 'Controlled original fixture test approval only',
          }
      ],
    });

NativeFixtureApproval _approveLibraryDraft(NativeProjectDraft draft,
    List<AssetCandidate> candidates, ReviewDecisions decisions) {
  final base = approveNativeFixtureDraft(draft);
  final plan = ConversionPlan.fromJson({
    ...base.plan.toJson(),
    'decisionsHash': decisions.canonicalHash.value,
    'decisionRevision': decisions.revision,
    'outputPolicy': {
      ...(base.plan.toJson()['outputPolicy'] as Map),
      'assetOutputMode': candidates.first.outputMode.name,
    },
    'operations': [
      for (final raw in base.plan.toJson()['operations'] as List)
        {
          ...(raw as Map),
          'domain': (raw['targetActionId'] as String).startsWith('map.')
              ? 'maps'
              : 'assets',
        }
    ],
  });
  return NativeFixtureApproval(
      plan,
      PlanContext(
          logicalProjectNamespace: base.context.logicalProjectNamespace,
          sourceSnapshotHash: base.context.sourceSnapshotHash,
          sessionId: decisions.sessionId,
          targetCapabilities: base.context.targetCapabilities,
          rulesHash: base.context.rulesHash,
          decisions: decisions,
          candidates: candidates,
          converterVersion: base.context.converterVersion,
          approvedPlanHash: plan.canonicalHash,
          sourceMapIds: base.context.sourceMapIds,
          sourceEntityIds: base.context.sourceEntityIds,
          targetEntityIds: base.context.targetEntityIds,
          actionCapabilities: base.context.actionCapabilities,
          approvedCandidateHashes: {
            for (final candidate in candidates)
              candidate.candidateId: candidate.canonicalHash,
          }));
}

NativeProjectDraft _copyLibraryDraft(NativeProjectDraft draft,
        {List<NativeArtifact>? artifacts,
        List<NativeArtifact>? sourceArtifacts,
        List<NativeMutation>? mutations,
        Map<String, Object?>? evidence}) =>
    NativeProjectDraft(
        source: draft.source,
        projectName: draft.projectName,
        parentPath: draft.parentPath,
        folderName: draft.folderName,
        sourceRootPath: draft.sourceRootPath,
        mapIds: draft.mapIds,
        artifacts: artifacts ?? draft.artifacts,
        sourceArtifacts: sourceArtifacts ?? draft.sourceArtifacts,
        mutations: mutations ?? draft.mutations,
        compositionEvidence: evidence ?? draft.compositionEvidence,
        defaultMapWidth: draft.defaultMapWidth,
        defaultMapHeight: draft.defaultMapHeight);

NativeProjectDraft _replaceLibraryPng(NativeProjectDraft draft,
    ApprovedAssetCandidateBinding binding, List<int> bytes) {
  final png = NativeArtifact(bytes: bytes);
  final pixels = image.decodePng(Uint8List.fromList(bytes))!;
  final evidence = jsonDecode(canonicalJsonOf(draft.compositionEvidence))
      as Map<String, dynamic>;
  final library = evidence['assetLibrary'] as Map;
  final record = library['record'] as Map;
  final row = (record['candidates'] as List).cast<Map>().singleWhere(
      (entry) => entry['candidateId'] == binding.candidateId.value);
  row['pngArtifactHandle'] = png.handle;
  row['pngSha256'] = png.rawSha256.value;
  row['rgbaSha256'] =
      nativeFixtureHash(pixels.getBytes(order: image.ChannelOrder.rgba)).value;
  final companionRecord = Map<String, Object?>.from(row)
    ..remove('companionArtifactHandle')
    ..remove('companionSha256');
  final companion = NativeArtifact(
      bytes: utf8.encode(canonicalJsonOf({
        'type': 'approvedAssetLibraryEntry',
        'version': 1,
        ...companionRecord
      })),
      mediaType: 'application/json');
  row['companionArtifactHandle'] = companion.handle;
  row['companionSha256'] = companion.rawSha256.value;
  library['compositionHash'] = canonicalHashOf(record).value;
  return _copyLibraryDraft(draft,
      artifacts: [
        for (final artifact in draft.artifacts)
          if (artifact.handle == binding.pngArtifactHandle)
            png
          else if (artifact.handle == binding.companionArtifactHandle)
            companion
          else
            artifact
      ],
      mutations: [
        for (final mutation in draft.mutations)
          if (mutation.parameters['artifactHandle'] ==
                  binding.pngArtifactHandle ||
              mutation.parameters['artifactHandle'] ==
                  binding.companionArtifactHandle)
            NativeMutation(
                operationId: mutation.operationId,
                actionId: mutation.actionId,
                sourceEntityIds: mutation.sourceEntityIds,
                targetEntityIds: mutation.targetEntityIds,
                parameters: {
                  ...mutation.parameters,
                  'artifactHandle': mutation.parameters['artifactHandle'] ==
                          binding.pngArtifactHandle
                      ? png.handle
                      : companion.handle
                })
          else
            mutation
      ],
      evidence: evidence);
}

final class _RecordingCreation implements ProjectCreationPort {
  final requests = <ProjectCreationRequest>[];
  final delegate = const LocalProjectCreationService();

  @override
  Future<List<int>?> preview(ProjectCreationRequest request) =>
      delegate.preview(request);

  @override
  Future<String> validateDestination(ProjectCreationRequest request) =>
      delegate.validateDestination(request);

  @override
  Future<ProjectCreationReceipt> create(ProjectCreationRequest request,
      {void Function(ProjectCreationPhase)? onPhase,
      bool Function()? isCancelled,
      String? expectedDestination}) {
    requests.add(request);
    return delegate.create(request,
        onPhase: onPhase,
        isCancelled: isCancelled,
        expectedDestination: expectedDestination);
  }
}

final class _NetworkTrap {
  int calls = 0;
  HttpClient create(SecurityContext? context) {
    calls++;
    throw StateError('HTTP network trap');
  }
}

final class _OnDiskSourceFiles implements SourceFilePort {
  const _OnDiskSourceFiles(this.snapshot, this.rootPath);
  final SourceSnapshot snapshot;
  final String rootPath;

  @override
  Future<List<int>> read(ConverterId fileId) => File(
          '$rootPath/${snapshot.entries.singleWhere((entry) => entry.fileId == fileId).relativePath}')
      .readAsBytes();
}

final class _NativeProject {
  _NativeProject(this.opened, this.handles, this.snapshots, this.mutations);

  final OpenedProject opened;
  final WorkspaceHandleStore handles;
  final ProjectSnapshotLoader snapshots;
  final LocalMapAuthoringMutationApi mutations;
  ProjectHandle get project => opened.projectHandle;

  static Future<_NativeProject> open(String projectPath) async {
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [projectPath], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final opened = await ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles)
        .openProject(projectPath);
    final mutations =
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: snapshots);
    await mutations.attachProject(
        projectRootPath: projectPath,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    return _NativeProject(opened, handles, snapshots, mutations);
  }

  Future<ProjectSnapshot> load() => snapshots.load(project);

  Future<void> save(MapData map, String revision) async {
    final request = AuthoringRequest(
        requestId: 'native-test-edit',
        actionId: 'map.save',
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle.value,
        parameters: {'map': map.toJson()},
        expectedRevision: revision,
        idempotencyKey: 'native-test-edit');
    final planned = await mutations.plan(project, request);
    await mutations.apply(project,
        planId: planned['planId']! as String, operationId: 'native-test-edit');
  }

  Future<void> close() => mutations.detachWorkspace(opened.workspaceHandle);
}
