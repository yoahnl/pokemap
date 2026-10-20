import 'dart:io';
import 'dart:convert';
import 'package:image/image.dart' as image;
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import 'support/native_writer_fixture.dart';
import 'support/literal_tile_fixture.dart';
import 'support/source_town_map_original_fixture.dart';

void main() {
  for (final regionCount in [1, 2]) {
    test('native writer accepts exact town map binding lists for $regionCount regions and refuses forged provenance', () async {
      final output = await Directory('/private/tmp').createTemp('ev09-town-map-list-');
      addTearDown(() => output.delete(recursive: true));
      const limits = NativeWriteLimits(maxArtifacts: 512, maxMutations: 2048);
      final events = await _syntheticTownMapList(output.path, regionCount, limits);
      final draft = events.draft;
      final evidence = draft.compositionEvidence['sourceEvents'] as Map;
      final bindings = evidence['townMap'] as List;
      expect(bindings, hasLength(regionCount), reason: jsonEncode(events.projection.semanticEvidence['events']));
      for (final mode in ['duplicate', 'invalid', 'wrongProvenance']) {
        final changedBindings = jsonDecode(jsonEncode(bindings)) as List;
        switch (mode) {
          case 'duplicate': changedBindings.add(changedBindings.first);
          case 'invalid': changedBindings.first['flyEnabled'] = true;
          case 'wrongProvenance': changedBindings.first['normalizationHash'] = 'f' * 64;
        }
        final forged = copyNativeFixtureDraft(draft, compositionEvidence: {
          ...draft.compositionEvidence, 'sourceEvents': {...evidence, 'townMap': changedBindings},
        });
        final approval = approveNativeFixtureDraft(forged);
        final stages = <NativeWriteStage>[];
        await expectLater(NativeProjectWriter(checkpoint: (stage, _, __) async { stages.add(stage); })
            .write(approval.plan, approval.context, forged, limits: limits), throwsA(isA<NativeWriteException>()));
        expect(stages, isEmpty);
      }
      final approval = approveNativeFixtureDraft(draft);
      final receipt = await const NativeProjectWriter().write(approval.plan, approval.context, draft, limits: limits);
      expect(receipt.verified, true);
      for (final binding in bindings) {
        final imageBinding = binding['image'] as Map;
        expect(receipt.assetHashes[imageBinding['assetId']]?.value, imageBinding['sha256']);
      }
    }, skip: !Platform.isMacOS);
  }

  final sourceRoot = Platform.environment['AVELUNE_KANTO_TOWN_MAP_SOURCE_ROOT'];
  final archivePath = Platform.environment['AVELUNE_KANTO_TOWN_MAP_ARCHIVE'];
  test(
      'original Town Map publishes exact regional data and rejects a reapproved forged point',
      () async {
    final limits = sourceCatalogStudyWriteLimitsFor(2);
    final retainedParent =
        Platform.environment['AVELUNE_KANTO_TOWN_MAP_OUTPUT_PARENT'];
    final parent = retainedParent == null
        ? Directory.systemTemp
        : await Directory(retainedParent).create(recursive: true);
    final output = await parent.createTemp('original-town-map-writer-');
    if (retainedParent == null) {
      addTearDown(() => output.delete(recursive: true));
    }
    final composition = await _composeNativeTownMapPublication(
        archivePath: archivePath!,
        sourceRoot: sourceRoot!,
        outputParentPath: output.path,
        limits: limits);
    final draft = composition.draft;
    stdout.writeln(jsonEncode({
      'phase': 'prepared',
      'sourceMapIds': draft.mapIds.keys.toList(),
      'mutations': draft.mutations.length,
      'artifacts': draft.artifacts.length,
      'sourceArtifacts': draft.sourceArtifacts.length,
      'totalArtifacts': draft.artifacts.length + draft.sourceArtifacts.length,
      'maxArtifacts': limits.maxArtifacts,
      'maxMutations': limits.maxMutations,
      'catalogDocuments': composition.projection.documents.length,
      'trainers': composition.projection.trainers.length,
      'catalogDiagnostics': composition.projection.diagnostics
          .map((entry) => entry.toJson())
          .toList()
    }));
    expect(draft.mapIds.keys.toSet(), {98, 102});
    final nativeBindings =
        composition.projection.evidence['nativeTrainerBindings'] as Map;
    expect(nativeBindings['nativeClosureComplete'], isTrue);
    expect(nativeBindings['movePolicy'], 'nativeAveluneDefaults');
    expect(
        composition.projection.trainers
            .every((trainer) => trainer.tags.contains('native-roster-bound')),
        isTrue);
    expect(
        composition.projection.encounterTables
            .every((table) => table.chancePerStep == 0),
        isTrue);
    expect(composition.projection.trainers, hasLength(9));
    for (final kind in [
      SourceCatalogDocumentKind.species,
      SourceCatalogDocumentKind.learnset,
      SourceCatalogDocumentKind.evolution,
      SourceCatalogDocumentKind.media
    ]) {
      expect(
          composition.projection.documents.where((entry) => entry.kind == kind),
          isNotEmpty);
    }
    final sourceEvents = draft.compositionEvidence['sourceEvents'] as Map;
    final townMap = (sourceEvents['townMap'] as List).single as Map;
    final image = townMap['image'] as Map;
    expect(townMap['pointCount'], 90);
    expect(townMap['flyEnabled'], isFalse);
    final nativeMapId = draft.mapIds[102]!;
    final linkedPointMutation = draft.mutations.singleWhere((mutation) =>
        mutation.actionId == 'regionalMap.poi.upsert' &&
        ((mutation.parameters['poi'] as Map)['mapIds'] as List)
            .contains(nativeMapId));
    final mapSaved = draft.mutations.indexWhere((mutation) =>
        mutation.actionId == 'map.save' &&
        (mutation.parameters['map'] as Map)['id'] == nativeMapId);
    expect(mapSaved, greaterThanOrEqualTo(0));
    expect(draft.mutations.indexOf(linkedPointMutation), greaterThan(mapSaved));
    final approval = approveNativeFixtureDraft(draft);
    final publicationPolicy = NativePublicationPolicy(
        allowedParentRoots: [output.path], sourceRoots: [sourceRoot]);
    final publication = await const NativeProjectPublication().begin(
        approval.plan, approval.context, draft,
        policy: publicationPolicy);
    addTearDown(publication.close);
    stdout.writeln(jsonEncode({
      'phase': 'writeNative',
      'mutations': draft.mutations.length,
      'artifacts': draft.artifacts.length,
      'sourceArtifacts': draft.sourceArtifacts.length,
      'totalArtifacts': draft.artifacts.length + draft.sourceArtifacts.length,
      'maxArtifacts': limits.maxArtifacts,
      'maxMutations': limits.maxMutations,
      'catalogDocuments': composition.projection.documents.length,
      'trainers': composition.projection.trainers.length
    }));
    final receipt = await NativeProjectWriter(
        stagingFactory: publication.createStaging,
        checkpoint: (stage, stagingRoot, projectPath) async {
          await publication.recordWriteCheckpoint(
              stage, stagingRoot, projectPath);
          if (stage == NativeWriteStage.afterCreation) {
            stdout.writeln(jsonEncode({
              'phase': 'writeNative',
              'publishedCreationTransactions': 1,
              'preparedLogicalOperations': draft.mutations.length
            }));
          }
        }).write(approval.plan, approval.context, draft, limits: limits);
    expect(receipt.verified, isTrue);
    expect(receipt.assetHashes[image['assetId']]?.value,
        'f19d2088161ba0a77adc4db085e7a7ff4362fff48ec7b335057253e857c4f033');
    expect(
        await File('${receipt.projectPath}/${image['logicalPath']}')
            .readAsBytes(),
        await File('$sourceRoot/Graphics/UI/Town Map/map_Kanto.png')
            .readAsBytes());
    final published = await publication.publish(
        stagedReceipt: receipt,
        readCurrentContext: () async => approval.context,
        verifySourceUnchanged: () => _verifyTownMapSource(draft, sourceRoot));
    expect(published.published, isTrue);
    expect(published.nativeRevision, receipt.nativeRevision);
    expect(await Directory(receipt.projectPath).exists(), isFalse);
    final projectPath = published.projectPath;
    await publication.close();
    final recovered = await const NativeProjectPublication().reconcile(
        journalPath: published.journalPath, policy: publicationPolicy);
    expect(recovered.state, NativePublicationRecoveryState.published);
    expect(recovered.receipt!.inventoryHash, published.inventoryHash);
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [projectPath], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles),
        snapshotLoader: snapshots);
    final opened = await api.openProject(projectPath);
    try {
      final loaded = await snapshots.load(opened.projectHandle,
          policy: ProjectSnapshotLoadPolicy.strict);
      expect(loaded.loadDiagnostics, isEmpty);
      final trainerIdsByFirstWrite = draft.mutations
          .where((mutation) => mutation.actionId == 'campaign.trainer.upsert')
          .map((mutation) => (mutation.parameters['value'] as Map)['id'] as String)
          .toSet()
          .toList();
      expect(loaded.manifest.trainers.map((trainer) => trainer.id).toList(),
          trainerIdsByFirstWrite);
      expect(
          {for (final trainer in loaded.manifest.trainers)
            trainer.id: trainer.toJson()},
          {for (final trainer in composition.projection.trainers)
            trainer.id: trainer.toJson()});
      final validation = await api.validateProject(opened.projectHandle);
      expect(validation.valid, isTrue, reason: jsonEncode(validation.toJson()));
      final catalog = loaded.manifest.regionalMap!;
      expect(catalog.regions, hasLength(1));
      expect(catalog.pointsOfInterest, hasLength(90));
      expect(
          catalog.pointsOfInterest.every((point) => point.destination == null),
          isTrue);
      final current = catalog.pointsOfInterest
          .singleWhere((point) => point.mapIds.contains(nativeMapId));
      expect(current.regionId, catalog.regions.single.id);
      expect(current.u, 296 / 480);
      expect(current.v, 72 / 320);
      expect(current.mapIds, [nativeMapId]);
      final actions = loaded.manifest.scenes
          .expand((scene) => scene.graph.nodes)
          .map((node) => node.payload)
          .whereType<SceneActionPayload>();
      expect(
          actions.where((payload) =>
              payload.interactiveCommand?.kind ==
              SceneInteractiveCommandKind.openRegionalMap),
          hasLength(1));
    } finally {
      await api.closeWorkspace(opened.workspaceHandle);
    }
    final point = draft.mutations.firstWhere(
        (mutation) => mutation.actionId == 'regionalMap.poi.upsert');
    final forgedPoint = copyNativeFixtureMutation(point, parameters: {
      'poi': {...point.parameters['poi'] as Map, 'label': 'Forged source town'},
    });
    final forged = NativeProjectDraft(
        source: draft.source,
        projectName: draft.projectName,
        parentPath: draft.parentPath,
        folderName: 'forged-town-map',
        sourceRootPath: draft.sourceRootPath,
        mapIds: draft.mapIds,
        artifacts: draft.artifacts,
        sourceArtifacts: draft.sourceArtifacts,
        compositionEvidence: draft.compositionEvidence,
        defaultMapWidth: draft.defaultMapWidth,
        defaultMapHeight: draft.defaultMapHeight,
        mutations: [
          for (final mutation in draft.mutations)
            mutation.operationId == point.operationId ? forgedPoint : mutation
        ],
        limits: limits);
    expect(forged.sourceArtifacts.map((artifact) => artifact.rawSha256),
        draft.sourceArtifacts.map((artifact) => artifact.rawSha256));
    expect(
        forged.mutations
            .where((mutation) => mutation.operationId != point.operationId)
            .map((mutation) => mutation.toJson(0)),
        draft.mutations
            .where((mutation) => mutation.operationId != point.operationId)
            .map((mutation) => mutation.toJson(0)));
    final reapproved = approveNativeFixtureDraft(forged);
    final stages = <NativeWriteStage>[];
    await expectLater(
        NativeProjectWriter(checkpoint: (stage, _, __) async {
          stages.add(stage);
        }).write(reapproved.plan, reapproved.context, forged, limits: limits),
        throwsA(isA<NativeWriteException>().having(
            (error) => error.code, 'code', 'native.semantics.regeneration')));
    expect(stages, isEmpty);
    expect(await Directory('${output.path}/forged-town-map').exists(), isFalse);
    await _verifyTownMapSource(draft, sourceRoot);
    final evidence = {
      'kind': 'nativeOriginalTownMapPublicationProof',
      'version': 1,
      'projectPath': projectPath,
      'published': published.published,
      'nativeRevision': published.nativeRevision,
      'draftHash': published.draftHash.value,
      'inventoryHash': published.inventoryHash.value,
      'journalPath': published.journalPath,
      'sourceSnapshotHash': draft.source.snapshot.canonicalHash.value,
      'sourceMapIds': draft.mapIds.keys.toList(),
      'mutations': draft.mutations.length,
      'artifacts': draft.artifacts.length,
      'sourceArtifacts': draft.sourceArtifacts.length,
      'totalArtifacts': draft.artifacts.length + draft.sourceArtifacts.length,
      'catalogDocuments': composition.projection.documents.length,
      'nativeTrainers': composition.projection.trainers.length,
      'catalogDiagnostics': composition.projection.diagnostics
          .map((entry) => entry.toJson())
          .toList(),
      'nativeClosureComplete': true,
      'wildEncountersEnabled': false,
      'maxArtifacts': limits.maxArtifacts,
      'maxMutations': limits.maxMutations,
      'regionCount': 1,
      'pointCount': 90,
      'flyEnabled': false,
      'strictLoadDiagnostics': 0,
      'validateProject': true,
      'reapprovedForgedPoiRefusedBeforeStaging': true,
      'imageSha256': receipt.assetHashes[image['assetId']]!.value,
    };
    if (retainedParent != null) {
      await File('${output.path}/town-map-publication-proof.json')
          .writeAsString(jsonEncode(evidence));
    }
    stdout.writeln(jsonEncode(evidence));
  },
      skip: sourceRoot == null || archivePath == null
          ? 'AVELUNE_KANTO_TOWN_MAP_SOURCE_ROOT and AVELUNE_KANTO_TOWN_MAP_ARCHIVE are required'
          : false,
      timeout: const Timeout(Duration(minutes: 25)));

  test('regional map native actions use the canonical project domain', () {
    for (final action in [
      'regionalMap.region.upsert',
      'regionalMap.poi.upsert'
    ]) {
      final mutation = NativeMutation(
          operationId: ConverterId('region'),
          actionId: action,
          sourceEntityIds: [ConverterId('source-map')],
          targetEntityIds: [ConverterId('native-region')],
          parameters: const {});
      expect(mutation.domain, OperationDomain.project);
    }
  });

  test('a region and PNG without source regeneration never reach staging',
      () async {
    final root =
        await Directory.systemTemp.createTemp('native-town-map-refusal-');
    addTearDown(() => root.delete(recursive: true));
    final output = await Directory('${root.path}/output').create();
    final fixture =
        await LiteralTileFixture.create(sourceRootPath: '${root.path}/source');
    final literal = await const LiteralTileComposer().compose(
        source: fixture.source,
        files: fixture.files,
        selectedSourceMapIds: [1],
        projectName: 'Town Map refusal',
        parentPath: output.path,
        folderName: 'forged-region');
    expect(literal.canWrite, isTrue);
    final original = literal.draft!;
    final sourceId = fixture.source.mapIdentity(1);
    final image = NativeArtifact(
        bytes: fixture.sourceBytes['Graphics/Tilesets/OriginalAtlas1.png']!);
    final region = ProjectRegionDefinition(
        id: 'region',
        label: 'Forged region',
        imagePath:
            'assets/regions/source_region_image_${image.rawSha256.value.substring(0, 24)}.png');
    final changed = copyNativeFixtureDraft(original,
        artifacts: original.artifacts,
        compositionEvidence: {
          ...original.compositionEvidence,
          'sourceEvents': {
            'kind': 'sourceEventStudy',
            'version': 1,
            'witnesses': [],
            'townMap': {
              'kind': 'sourceTownMapBinding',
              'version': 1,
              'sourceWallMap': true,
              'flyEnabled': false,
              'nativeRegionId': region.id,
            },
          },
        },
        mutations: [
          ...original.mutations,
          NativeMutation(
              operationId: ConverterId('region-image-import'),
              actionId: 'asset.import',
              sourceEntityIds: [
                sourceId
              ],
              targetEntityIds: [
                ConverterId('region-image')
              ],
              parameters: {
                'artifactHandle': image.handle,
                'assetId': 'region-image',
                'logicalPath': region.imagePath,
                'tags': ['source-town-map'],
                'usages': ['regional-map'],
              }),
          NativeMutation(
              operationId: ConverterId('region-upsert'),
              actionId: 'regionalMap.region.upsert',
              sourceEntityIds: [sourceId],
              targetEntityIds: [ConverterId(region.id)],
              parameters: {'region': region.toJson()}),
        ]);
    final approval = approveNativeFixtureDraft(changed);
    final stages = <NativeWriteStage>[];
    await expectLater(
        NativeProjectWriter(
                checkpoint: (stage, _, __) async => stages.add(stage))
            .write(approval.plan, approval.context, changed),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'native.events.binding')));
    expect(stages, isEmpty);
    expect(await output.list().toList(), isEmpty);
    for (final entry in fixture.sourceBytes.entries) {
      expect(await File('${fixture.sourceRootPath}/${entry.key}').readAsBytes(),
          entry.value);
    }
  });
}

Future<void> _verifyTownMapSource(
    NativeProjectDraft draft, String sourceRoot) async {
  final root = await Directory(sourceRoot).resolveSymbolicLinks();
  final ids = {...draft.source.archive.files.keys.map((id) => id.value)};
  for (final evidence in draft.compositionEvidence.values.whereType<Map>()) {
    if (evidence['witnesses'] case final List witnesses) {
      for (final witness in witnesses.cast<Map>()) {
        ids.add(witness['fileId'] as String);
      }
    }
  }
  for (final entry in draft.source.snapshot.entries
      .where((entry) => ids.contains(entry.fileId.value))) {
    validateSourceRelativePath(entry.relativePath);
    final file = File('$root/${entry.relativePath}');
    expect(await file.resolveSymbolicLinks(), startsWith('$root/'));
    final bytes = await file.readAsBytes();
    expect(bytes.length, entry.byteLength, reason: entry.relativePath);
    expect(crypto.sha256.convert(bytes).toString(), entry.sha256!.value,
        reason: entry.relativePath);
  }
}

Future<SourceCatalogStudyComposition> _composeNativeTownMapPublication(
    {required String archivePath,
    required String sourceRoot,
    required String outputParentPath,
    required NativeWriteLimits limits}) async {
  const selected = [98, 102];
  final (initial, files) = await readOriginalTownMapSource(
      archivePath: archivePath, sourceRoot: sourceRoot);
  final source = await const RmxpSourceNormalizer().normalize(
      snapshot: initial.snapshot,
      files: files,
      selectedMapIds: selected.toSet(),
      includeEventSystem: true);
  Future<LiteralTileComposition> composeLiteral(
          List<LiteralDependencyDecision> decisions) =>
      const LiteralTileComposer().compose(
          source: source,
          files: files,
          selectedSourceMapIds: selected,
          projectName: 'Original Town Map native publication',
          parentPath: outputParentPath,
          folderName: 'native-town-map',
          sourceRootPath: sourceRoot,
          allowFirstFrameAutotiles: true,
          dependencyDecisions: decisions,
          limits: limits);
  var literal = await composeLiteral(const []);
  final decisions = [
    for (final dependency in literal.dependencies)
      if (dependency.kind == LiteralDependencyKind.staticTransfer &&
          dependency.targetSourceMapId != null &&
          !selected.contains(dependency.targetSourceMapId))
        LiteralDependencyDecision(
            sourceSnapshotHash: source.snapshot.canonicalHash,
            selectionHash: literalSelectionHash(source, selected),
            locator: dependency.locator,
            targetSourceMapId: dependency.targetSourceMapId!,
            decision: LiteralDependencyDisposition.excludeStudy)
  ];
  if (decisions.isNotEmpty) literal = await composeLiteral(decisions);
  if (literal.draft == null) {
    throw StateError(
        'Original publication literal refusal: ${literal.diagnostics.map((entry) => entry.toJson()).toList()}');
  }
  final semantic = await const SourceSemanticStudyComposer()
      .compose(source: source, base: literal, files: files, limits: limits);
  if (semantic == null) throw StateError('Original semantics refused.');
  final events = await const SourceEventStudyComposer()
      .compose(source: source, base: semantic, files: files, limits: limits);
  if (events == null) throw StateError('Original events refused.');
  final catalogs = await const SourceCatalogStudyComposer().compose(
      source: source, base: events.draft, files: files, limits: limits);
  if (catalogs == null) throw StateError('Original native catalogs refused.');
  return catalogs;
}

Future<SourceEventStudyComposition> _syntheticTownMapList(String output,
    int regionCount, NativeWriteLimits limits) async {
  List<int> png(int width, int height, int color) {
    final raster = image.Image(width: width, height: height, numChannels: 4);
    raster.setPixelRgba(0, 0, color, 20, 30, 255);
    return image.encodePng(raster);
  }
  final fixture = await LiteralTileFixture.create(namespace: 'ev09-town-map-list-$regionCount',
      interpretationProfile: syntheticSourceInterpretationProfile,
      scriptsBytes: syntheticInterpretationArchive, includeEventSystem: true,
      tilesets: [LiteralFixtureTileset(id: 1, passages: const {391: 15})],
      maps: [for (var id = 1; id <= regionCount; id++) LiteralFixtureMap(id: id, layers: const [[384, 391, 384], [0, 0, 0], [0, 0, 0]], events: [
        const LiteralFixtureEvent(id: 1, x: 1, y: 0, pages: [LiteralFixtureEventPage(commands: [
          LiteralFixtureEventCommand(101, ['A regional map.']), LiteralFixtureEventCommand(355, ['pbShowMap']),
          LiteralFixtureEventCommand(0, []),
        ])]),
      ])],
      extraFiles: {
        'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = TestPlayer\n'),
        'Graphics/Characters/TestPlayer.png': png(128, 192, 1),
        'Data/map_metadata.dat': literalFixtureMarshal({
          for (var id = 1; id <= regionCount; id++) id: LiteralFixtureObject('GameData::MapMetadata', {
            '@id': id, '@town_map_size': null, '@town_map_position': [id, 1, 1],
          }),
        }),
        'Data/town_map.dat': literalFixtureMarshal({
          for (var id = 1; id <= regionCount; id++) id: LiteralFixtureObject('GameData::TownMap', {
            '@id': id, '@flags': <Object?>[], '@pbs_file_suffix': '', '@real_name': 'Region $id',
            '@filename': 'Region$id.png', '@point': [[1, 1, 'Town $id', null, null, null, null, null]],
          }),
        }),
        for (var id = 1; id <= regionCount; id++) 'Graphics/UI/Town Map/Region$id.png': png(32, 32, id),
      });
  final literal = await const LiteralTileComposer().compose(source: fixture.source,
      files: fixture.files, selectedSourceMapIds: [for (var id = 1; id <= regionCount; id++) id],
      projectName: 'Town Map lists', parentPath: output, folderName: 'native', limits: limits);
  if (literal.draft == null) throw StateError('Literal fixture refused: ${literal.diagnostics}');
  final semantic = await const SourceSemanticStudyComposer().compose(source: fixture.source,
      base: literal, files: fixture.files, limits: limits);
  if (semantic == null) throw StateError('Semantic fixture refused');
  final events = await const SourceEventStudyComposer().compose(source: fixture.source,
      base: semantic, files: fixture.files, limits: limits);
  if (events == null) throw StateError('Event fixture refused');
  return events;
}
