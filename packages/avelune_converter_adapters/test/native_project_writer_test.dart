import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/native_writer_fixture.dart';

Matcher get _nativeFailure => isA<NativeWriteException>()
    .having((error) => error.code, 'code', startsWith('native.'));

void main() {
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
        throwsA(anyOf(_nativeFailure, isA<ContractError>())));
    expect(creation.requests, isEmpty);
    expect(stages, isNot(contains(NativeWriteStage.stageCreated)));
    expect(await _treeBytes(output.path), before);
    expect(await _treeShape(output.path), beforeShape);
    await sourceUnchanged();
  }

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
    await refuseBeforeStage(draft);
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
