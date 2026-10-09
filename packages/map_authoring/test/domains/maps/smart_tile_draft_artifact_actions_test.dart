import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('discovers a bounded atomic native draft artifact contract', () {
    final descriptor = SmartTileCatalogActions.descriptors
        .singleWhere((value) => value.id == 'smart_tile.preset.draft.import');
    expect(descriptor.version, 1);
    expect(descriptor.extensions['maximumArtifactByteLength'], 8 * 1024 * 1024);
    expect(descriptor.guarantees, contains(AuthoringGuarantee.atomic));
    expect(descriptor.guarantees, contains(AuthoringGuarantee.undoable));
    expect(descriptor.requiredPermissions,
        contains(AuthoringPermission.importRun));
    expect((descriptor.extensions['inputSchema'] as Map)['required'],
        ['draftId', 'artifactHandle']);
  });

  test(
      'direct API imports and publishes every rule and coverage scenario with bounded diffs',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final draft = _draft(count: 2800);
    final bytes = utf8.encode(jsonEncode(draft.toJson()));
    expect(bytes.length, greaterThan(1024 * 1024));
    final staged = await fixture.mutations.artifacts
        .put(bytes, declaredMediaType: 'application/json');
    final planned = await fixture.plan('smart_tile.preset.draft.import',
        {'draftId': draft.id, 'artifactHandle': staged.reference.handle});
    expect(
        utf8.encode(jsonEncode(planned.toJson())).length, lessThan(64 * 1024));
    expect(planned.plan.changeSet.changes.single.resource.kind, 'project');
    expect(planned.plan.artifacts.single.sha256, staged.reference.hexDigest);
    await fixture.apply(planned, 'large-import');
    expect((await fixture.snapshot()).manifest.smartTileCatalog.drafts.single,
        draft);
    expect(
        fixture.mutations.artifacts.inspect(staged.reference.handle), isNull);
    final published =
        await fixture.plan('smart_tile.preset.publish', {'draftId': draft.id});
    expect(utf8.encode(jsonEncode(published.toJson())).length,
        lessThan(64 * 1024));
    await fixture.apply(published, 'large-publish');
    final catalog = (await fixture.snapshot()).manifest.smartTileCatalog;
    expect(catalog.drafts, isEmpty);
    expect(catalog.materials, draft.materials);
    expect(catalog.presets.single.rules, draft.rules);
    expect(catalog.presets.single.coverageProfile, draft.coverageProfile);
    expect(catalog.presets.single.allowedMaterialIds, draft.allowedMaterialIds);
    expect(catalog.atlases, draft.atlases);
  }, timeout: const Timeout(Duration(minutes: 3)));

  test(
      'rejects malformed documents, unknown handles, media type and identity mismatches before writing',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final before = await fixture.projectFile.readAsBytes();
    final cases = <(List<int>, String, String, String)>[
      (
        utf8.encode('[]'),
        'application/json',
        'draft',
        'smart_tile.draft.artifact_invalid'
      ),
      (
        [0xff, 0xfe],
        'application/json',
        'draft',
        'smart_tile.draft.artifact_invalid'
      ),
      (
        utf8.encode('plain text'),
        'text/plain',
        'draft',
        'smart_tile.draft.artifact_media_type'
      ),
      (
        utf8.encode(jsonEncode(_draft().toJson())),
        'application/json',
        'different',
        'smart_tile.draft.identity_mismatch'
      ),
      (
        utf8.encode('{}'),
        'application/json',
        'draft',
        'smart_tile.request_invalid'
      ),
    ];
    for (final item in cases) {
      final staged = await fixture.mutations.artifacts
          .put(item.$1, declaredMediaType: item.$2);
      await expectLater(
          fixture.plan('smart_tile.preset.draft.import',
              {'draftId': item.$3, 'artifactHandle': staged.reference.handle}),
          throwsA(_code(item.$4)));
      expect(await fixture.projectFile.readAsBytes(), before);
    }
    await expectLater(
        fixture.plan('smart_tile.preset.draft.import',
            {'draftId': 'draft', 'artifactHandle': 'missing'}),
        throwsA(_code('smart_tile.draft.artifact_unavailable')));
    await expectLater(
        fixture.plan('smart_tile.preset.draft.import',
            {'draftId': 'draft', 'artifactHandle': 'missing', 'replace': true}),
        throwsA(_code('map.request_invalid')));
    expect(await fixture.projectFile.readAsBytes(), before);
  });

  test(
      'layer binding keeps the manifest byte-identical through interrupted apply and recovery',
      () async {
    final fixture = await _Fixture.create(failLayerPromotion: true);
    addTearDown(fixture.dispose);
    final draft = _draft();
    await fixture.importDraft(draft, 'layer-draft');
    await fixture.apply(
        await fixture.plan('smart_tile.preset.publish', {'draftId': draft.id}),
        'layer-publish');
    await fixture.apply(
        await fixture.plan('map.create',
            {'mapId': 'map', 'name': 'Map', 'width': 2, 'height': 2}),
        'layer-map');
    final before = await fixture.projectFile.readAsBytes();
    final planned = await fixture.plan('smart_tile.layer.create', {
      'mapId': 'map',
      'presetId': draft.targetPresetId,
      'layerId': 'terrain',
      'name': 'Terrain'
    });
    expect(planned.plan.changeSet.changes.map((value) => value.resource.kind),
        ['map']);
    expect(
        utf8.encode(jsonEncode(planned.toJson())).length, lessThan(64 * 1024));
    await expectLater(
        fixture.apply(planned, 'layer-interrupted'), throwsA(isA<Exception>()));
    expect(await fixture.projectFile.readAsBytes(), before);
    final recovered = await fixture.mutations
        .recoverMutation(fixture.project, operationId: 'layer-interrupted');
    final replay = await fixture.mutations
        .recoverMutation(fixture.project, operationId: 'layer-interrupted');
    expect(replay.receipt.receiptId, recovered.receipt.receiptId);
    final snapshot = await fixture.snapshot();
    final layer = snapshot.maps.single.layers.single as SmartTileLayer;
    expect(layer.id, 'terrain');
    expect(layer.presetId, draft.targetPresetId);
    expect(
        snapshot.manifest.smartTileCatalog.presets.single.rules, draft.rules);
    expect(await fixture.projectFile.readAsBytes(), before);
  });

  test(
      'checks the 8 MiB byte budget before reading and detects changed staged bytes',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final bytes = utf8.encode(jsonEncode(_draft().toJson()));
    final real =
        ContentArtifactRef.fromBytes(bytes, mediaType: 'application/json');
    final budget = _ProbeStore(
        ContentArtifactRef(
            digest: real.digest,
            mediaType: real.mediaType,
            byteLength: 8 * 1024 * 1024 + 1),
        bytes);
    final context = await fixture
        .context({'draftId': 'draft', 'artifactHandle': real.handle});
    await expectLater(
        SmartTileCatalogActions(artifactStore: budget).importDraft(context),
        throwsA(_code('smart_tile.draft.artifact_too_large')));
    expect(budget.reads, 0);
    final changed = _ProbeStore(real, [...bytes, 32]);
    await expectLater(
        SmartTileCatalogActions(artifactStore: changed).importDraft(context),
        throwsA(_code('smart_tile.draft.artifact_changed')));
    expect(changed.reads, 1);
  });

  test(
      'import refuses replacing an existing different draft and duplicate native identities',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final initial = _draft();
    await fixture.importDraft(initial, 'original');
    final before = await fixture.projectFile.readAsBytes();
    final changed = await fixture.stage(initial.copyWith(name: 'Replacement'));
    await expectLater(
        fixture.plan('smart_tile.preset.draft.import',
            {'draftId': initial.id, 'artifactHandle': changed}),
        throwsA(_code('smart_tile.draft.identity_conflict')));
    final duplicate = initial.copyWith(
        id: 'duplicate',
        targetPresetId: 'duplicate',
        materials: [...initial.materials, initial.materials.single]);
    final duplicateHandle = await fixture.stage(duplicate);
    await expectLater(
        fixture.plan('smart_tile.preset.draft.import',
            {'draftId': duplicate.id, 'artifactHandle': duplicateHandle}),
        throwsA(isA<MapAuthoringException>()));
    expect(await fixture.projectFile.readAsBytes(), before);
  });

  test('dry run writes nothing and releases its staged lease', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final before = await fixture.projectFile.readAsBytes();
    final handle = await fixture.stage(_draft());
    final planned = await fixture.plan('smart_tile.preset.draft.import',
        {'draftId': 'draft', 'artifactHandle': handle},
        dryRun: true);
    expect(planned.applicable, isFalse);
    expect(await fixture.projectFile.readAsBytes(), before);
    expect(fixture.mutations.artifacts.inspect(handle), isNull);
  });

  test(
      'summary bounds long Unicode names while preserving the entire native document',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final draft = _draft().copyWith(name: List.filled(100000, '🏞️').join());
    final planned = await fixture.plan('smart_tile.preset.draft.import',
        {'draftId': draft.id, 'artifactHandle': await fixture.stage(draft)});
    final summary = (planned.plan.changeSet.diff.entries.single.after
        as Map)['documentSummary'] as Map;
    expect((summary['name'] as String).runes.length, 256);
    expect(summary['truncatedFields'], ['name']);
    expect(summary['fingerprintDomain'], 'smart-tile-document.json');
    expect(summary['fingerprint'], startsWith('sha256:'));
    expect(
        utf8.encode(jsonEncode(planned.toJson())).length, lessThan(64 * 1024));
    await fixture.apply(planned, 'unicode-name');
    expect(
        (await fixture.snapshot()).manifest.smartTileCatalog.drafts.single.name,
        draft.name);
  });

  test('draft identity bounds count Unicode characters as the descriptor does',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final validId = List.filled(128, '🌿').join();
    final draft = _draft().copyWith(id: validId);
    await fixture.importDraft(draft, 'unicode-id');
    expect(
        (await fixture.snapshot()).manifest.smartTileCatalog.drafts.single.id,
        validId);
    await expectLater(
        fixture.plan('smart_tile.preset.draft.import',
            {'draftId': '$validId🌿', 'artifactHandle': 'missing'}),
        throwsA(_code('smart_tile.draft.identity_invalid')));
  });

  test('import protects published targets and global dependency identities',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final original = _draft();
    await fixture.importDraft(original, 'original');
    await fixture.apply(
        await fixture
            .plan('smart_tile.preset.publish', {'draftId': original.id}),
        'publish');
    final before = await fixture.projectFile.readAsBytes();
    for (final (draft, code) in [
      (
        original.copyWith(sourcePresetId: original.targetPresetId),
        'smart_tile.draft.target_conflict'
      ),
      (
        original.copyWith(
            id: 'copy',
            targetPresetId: 'copy',
            materials: [original.materials.single.copyWith(name: 'Changed')]),
        'smart_tile.draft.dependency_identity_conflict'
      ),
    ]) {
      final handle = await fixture.stage(draft);
      await expectLater(
          fixture.plan('smart_tile.preset.draft.import',
              {'draftId': draft.id, 'artifactHandle': handle}),
          throwsA(_code(code)));
      expect(await fixture.projectFile.readAsBytes(), before);
    }
  });

  test(
      'apply and recovery replay preserve another lease while frozen bytes remain recoverable',
      () async {
    for (final interrupted in [false, true]) {
      final fixture = await _Fixture.create(failAfterPromotion: interrupted);
      addTearDown(fixture.dispose);
      final draft = _draft();
      final handle = await fixture.stage(draft);
      final planned = await fixture.plan('smart_tile.preset.draft.import',
          {'draftId': draft.id, 'artifactHandle': handle});
      final otherLease = await fixture.stage(draft);
      if (interrupted) {
        await expectLater(
            fixture.apply(planned, 'apply'), throwsA(isA<Exception>()));
        await fixture.mutations
            .recoverMutation(fixture.project, operationId: 'apply');
        await fixture.mutations
            .recoverMutation(fixture.project, operationId: 'apply');
      } else {
        await fixture.apply(planned, 'apply');
        await fixture.apply(planned, 'apply');
      }
      expect(fixture.mutations.artifacts.inspect(otherLease), isNotNull);
      await fixture.mutations.artifacts.release(otherLease);
      expect(fixture.mutations.artifacts.list(), isEmpty);
      expect((await fixture.snapshot()).manifest.smartTileCatalog.drafts.single,
          draft);
    }
  });

  test(
      'real JSONL CLI imports a draft larger than the request budget and supports undo and reopen',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final draft = _draft(count: 2800);
    final source = File('${fixture.root.path}/draft.json');
    await source.writeAsString(jsonEncode(draft.toJson()));
    expect(
        await source.length(), greaterThan(defaultAuthoringJsonlMaxInputBytes));
    final before = await fixture.projectFile.readAsBytes();
    final process = await Process.start(
        'dart', ['bin/pokemap_authoring.dart', '--root', fixture.root.path]);
    final lines = StreamIterator<String>(
        process.stdout.transform(utf8.decoder).transform(const LineSplitter()));
    final errors = process.stderr.transform(utf8.decoder).join();
    addTearDown(() async {
      await process.stdin.close();
      await process.exitCode.timeout(const Duration(seconds: 5), onTimeout: () {
        process.kill();
        return process.exitCode;
      });
      await lines.cancel();
    });
    var sequence = 0;
    Future<AuthoringResult> send(String command,
        [Map<String, Object?> args = const {}]) async {
      process.stdin.writeln(jsonEncode(
          {'id': 'draft-${sequence++}', 'command': command, 'args': args}));
      await process.stdin.flush();
      expect(await lines.moveNext(), isTrue);
      final result = AuthoringResult.fromJson(
          jsonDecode(lines.current) as Map<String, dynamic>);
      expect(result.status, AuthoringResultStatus.success,
          reason: jsonEncode(result.toJson()));
      return result;
    }

    final described = await send('describe');
    expect(
        (described.data['mutationActions'] as List).where(
            (action) => action['id'] == 'smart_tile.preset.draft.import'),
        hasLength(1));
    final opened = await send('open', {'projectRoot': fixture.root.path});
    final staged = await send('stage_artifact',
        {'sourcePath': source.path, 'declaredMediaType': 'application/json'});
    final planned = await send('plan', {
      'projectHandle': opened.data['projectHandle'],
      'request': AuthoringRequest(
          requestId: 'cli-draft',
          actionId: 'smart_tile.preset.draft.import',
          actionVersion: 1,
          workspaceHandle: opened.data['workspaceHandle'] as String,
          expectedRevision: (await fixture.snapshot()).revision,
          idempotencyKey: 'cli-draft',
          parameters: {
            'draftId': draft.id,
            'artifactHandle': staged.data['artifactHandle']
          }).toJson()
    });
    await send('apply', {
      'projectHandle': opened.data['projectHandle'],
      'planId': planned.data['planId'],
      'operationId': 'cli-draft'
    });
    expect((await fixture.snapshot()).manifest.smartTileCatalog.drafts.single,
        draft);
    final history = await send('history',
        {'projectHandle': opened.data['projectHandle'], 'limit': 10});
    final entry = (history.data['entries'] as List).cast<Map>().singleWhere(
        (entry) =>
            (entry['receipt'] as Map)['actionId'] ==
            'smart_tile.preset.draft.import');
    await send('undo', {
      'projectHandle': opened.data['projectHandle'],
      'entryId': entry['entryId'],
      'idempotencyKey': 'undo-draft'
    });
    expect(await fixture.projectFile.readAsBytes(), before);
    await send('close', {'workspaceHandle': opened.data['workspaceHandle']});
    await send('open', {'projectRoot': fixture.root.path});
    expect(
        (await fixture.snapshot()).manifest.smartTileCatalog.drafts, isEmpty);
    await process.stdin.close();
    expect(await process.exitCode, 0);
    expect(await errors, isEmpty);
  }, timeout: const Timeout(Duration(minutes: 2)));
}

Matcher _code(String code) =>
    isA<MapAuthoringException>().having((value) => value.code, 'code', code);

ProjectSmartTileAuthoringDraft _draft({int count = 1}) =>
    ProjectSmartTileAuthoringDraft(
      id: 'draft',
      targetPresetId: 'ground',
      name: 'Ground',
      usage: SmartTileUsage.terrain,
      lastStage: SmartTileAuthoringStage.publish,
      atlases: const [
        ProjectSmartTileAtlas(
            id: 'atlas',
            name: 'Ground',
            tilesetId: 'ground-image',
            cellWidth: 1,
            cellHeight: 1,
            columns: 1,
            rows: 1)
      ],
      primaryAtlasId: 'atlas',
      sourceTilesetIds: const ['ground-image'],
      materials: [
        for (var i = 0; i < count; i++)
          ProjectSmartTileMaterial(
              id: 'material-$i',
              name: 'Material $i',
              connectionGroupId: 'ground')
      ],
      defaultMaterialId: 'material-0',
      allowedMaterialIds: [for (var i = 0; i < count; i++) 'material-$i'],
      coverageProfile: SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.explicit,
          requiredScenarios: [
            for (var i = 0; i < count; i++)
              SmartTileCoverageScenario(
                  id: 'scenario-$i', centerMaterialId: 'material-$i')
          ]),
      rules: [
        for (var i = 0; i < count; i++)
          SmartTileRule(
              id: 'rule-$i',
              centerMatch: SmartTileSlotMatch.material('material-$i'),
              candidates: [
                SmartTileCandidate(
                    id: 'candidate-$i',
                    label: 'Variant $i',
                    parts: const [
                      SmartTileVisualPart(
                          source: SmartTileVisualSource.frame(
                              frame: SmartTileFrameRef(
                                  atlasId: 'atlas', column: 0, row: 0)))
                    ])
              ])
      ],
    );

final class _ProbeStore implements ArtifactStore {
  _ProbeStore(this.reference, this.bytes);
  final ContentArtifactRef reference;
  final List<int> bytes;
  int reads = 0;
  @override
  ContentArtifactRef? inspect(String handle) => reference;
  @override
  Future<List<int>> read(String handle) async {
    reads++;
    return bytes;
  }

  @override
  List<ContentArtifactRef> list() => [reference];
  @override
  Future<StoredArtifact> put(List<int> bytes, {String? declaredMediaType}) =>
      throw UnsupportedError('Read probe');
  @override
  Future<bool> release(String handle) async => true;
}

final class _Fixture {
  _Fixture(
      this.root, this.loader, this.project, this.workspace, this.mutations);
  final Directory root;
  final ProjectSnapshotLoader loader;
  final ProjectHandle project;
  final WorkspaceHandle workspace;
  final LocalMapAuthoringMutationApi mutations;
  int sequence = 0;
  File get projectFile => File('${root.path}/project.json');
  Future<ProjectSnapshot> snapshot() => loader.load(project);
  static Future<_Fixture> create(
      {bool failAfterPromotion = false,
      bool failLayerPromotion = false}) async {
    final root =
        await Directory.systemTemp.createTemp('smart-tile-draft-artifact-');
    await File('${root.path}/project.json').writeAsString(jsonEncode(
        ProjectManifest(name: 'Draft', maps: [], tilesets: []).toJson()));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final loader = ProjectSnapshotLoader(handles: handles);
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    var failed = false;
    var armed = false;
    final mutations = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: loader,
        artifactStore: LocalArtifactStore(
            allowedSourceRoots: [root.path],
            maximumArtifactBytes: 8 * 1024 * 1024),
        faultInjector: failAfterPromotion || failLayerPromotion
            ? (context) {
                if (armed &&
                    !failed &&
                    (!failLayerPromotion ||
                        context.operationId == 'layer-interrupted') &&
                    context.checkpoint ==
                        AuthoringTransactionCheckpoint.afterResourcePromoted) {
                  failed = true;
                  throw const FileSystemException(
                      'Interrupted draft publication');
                }
              }
            : null);
    final opened = await opener.openProject(root.path);
    await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    final fixture = _Fixture(
        root, loader, opened.projectHandle, opened.workspaceHandle, mutations);
    await fixture.importImage();
    armed = true;
    return fixture;
  }

  Future<AuthoringPlanningContext> context(
          Map<String, Object?> parameters) async =>
      AuthoringPlanningContext(
          snapshot: await snapshot(),
          request: AuthoringRequest(
              requestId: 'draft-context',
              actionId: 'smart_tile.preset.draft.import',
              actionVersion: 1,
              workspaceHandle: workspace.value,
              parameters: parameters),
          planId: 'draft-plan',
          seed: 1);
  Future<AuthoringMutationPlanResult> plan(
          String actionId, Map<String, Object?> parameters,
          {bool dryRun = false}) async =>
      mutations.planMutation(
          project,
          AuthoringRequest(
              requestId: 'draft-${sequence++}',
              actionId: actionId,
              actionVersion: 1,
              workspaceHandle: workspace.value,
              parameters: parameters,
              expectedRevision: (await snapshot()).revision,
              idempotencyKey: 'draft-${sequence++}',
              dryRun: dryRun));
  Future<AuthoringMutationResult> apply(
          AuthoringMutationPlanResult planned, String operationId) =>
      mutations.applyMutation(project,
          planId: planned.planId, operationId: operationId);
  Future<String> stage(ProjectSmartTileAuthoringDraft draft) async =>
      (await mutations.artifacts.put(utf8.encode(jsonEncode(draft.toJson())),
              declaredMediaType: 'application/json'))
          .reference
          .handle;
  Future<void> importDraft(
      ProjectSmartTileAuthoringDraft draft, String operation) async {
    await apply(
        await plan('smart_tile.preset.draft.import',
            {'draftId': draft.id, 'artifactHandle': await stage(draft)}),
        operation);
  }

  Future<void> importImage() async {
    final png = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=');
    final staged =
        await mutations.artifacts.put(png, declaredMediaType: 'image/png');
    await apply(
        await plan('tileset.import_image', {
          'artifactHandle': staged.reference.handle,
          'tilesetId': 'ground-image',
          'name': 'Ground',
          'tileWidth': 1,
          'tileHeight': 1
        }),
        'image');
    await mutations.artifacts.release(staged.reference.handle);
  }

  Future<void> dispose() => root.delete(recursive: true);
}
