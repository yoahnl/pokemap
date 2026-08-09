import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('PMCP-085 full authoring parity', () {
    test('exposes no legacy terrain, path, or surface action', () {
      final legacyActionIds = AuthoringMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id)
          .where(
            (id) =>
                id.startsWith('terrain.') ||
                id.startsWith('path.') ||
                id.startsWith('surface.'),
          )
          .toSet();

      expect(legacyActionIds, isEmpty);
    });

    test('registers every approved semantic resource without hidden gaps', () {
      final catalog = AuthoringFullParityCatalog.canonical();

      expect(
        catalog.resources.map((resource) => resource.resourceKind).toSet(),
        _approvedResourceKinds,
      );
      expect(catalog.blockedOrMissingCells, isEmpty);
      for (final resource in catalog.resources) {
        expect(
          resource.cells.keys.toSet(),
          AuthoringParityCapability.values.toSet(),
          reason: resource.resourceKind,
        );
        expect(resource.canonicalOwnerKind, isNotEmpty);
        for (final cell in resource.cells.values) {
          if (cell.status == AuthoringParityStatus.notApplicable) {
            expect(cell.justification, isNotEmpty,
                reason: resource.resourceKind);
          } else {
            expect(cell.status, AuthoringParityStatus.supported,
                reason: '${resource.resourceKind}/${cell.capability.name}');
            expect(cell.evidence, isNotEmpty,
                reason: '${resource.resourceKind}/${cell.capability.name}');
          }
        }
      }
    });

    test('fails parity when a required direct read kind is not published', () {
      final queryableKinds = canonicalQueryableResourceKindIds.toSet()
        ..remove('mapConnection');
      final catalog = AuthoringFullParityCatalog.canonical(
        queryableResourceKinds: queryableKinds,
      );
      final connection = catalog.resources.singleWhere(
        (resource) => resource.resourceKind == 'mapConnection',
      );

      expect(connection.canonicalOwnerKind, 'mapConnection');
      expect(
        connection.cells[AuthoringParityCapability.read]!.status,
        AuthoringParityStatus.missing,
      );
      expect(catalog.blockedOrMissingCells, isNotEmpty);
      expect(
          catalog.toJson()['summary'], containsPair('catalogComplete', false));
    });

    test('separates declared, adapter, contract, and end-to-end evidence', () {
      final catalog = AuthoringFullParityCatalog.canonical();
      final descriptors = AuthoringMutationDispatcher.canonical().descriptors;
      final allTransports = AuthoringTransport.values
          .map((transport) => transport.name)
          .toList()
        ..sort();

      expect(
        catalog.mutationActions.map((action) => action.actionId).toSet(),
        descriptors.map((descriptor) => descriptor.id).toSet(),
      );
      for (final descriptor in descriptors) {
        final evidence = catalog.requireMutationAction(descriptor.id);
        final json = evidence.toJson();
        expect(
          json['declaredTransports'],
          allTransports,
          reason: descriptor.id,
        );
        expect(json['adapterCapableTransports'], allTransports,
            reason: descriptor.id);
        expect(json, isNot(contains('transports')), reason: descriptor.id);
        for (final path in (json['adapterEvidence']! as Map).values) {
          expect(File(path as String).existsSync(), isTrue,
              reason: '${descriptor.id}: $path');
        }
        for (final path in (json['endToEndEvidence']! as Map).values) {
          expect(File(path as String).existsSync(), isTrue,
              reason: '${descriptor.id}: $path');
        }
        expect(File(evidence.contractTestPath).existsSync(), isTrue,
            reason: descriptor.id);
        expect(descriptor.requiredPermissions, isNotEmpty,
            reason: descriptor.id);
        expect(
          descriptor.guarantees,
          containsAll({
            AuthoringGuarantee.dryRun,
            AuthoringGuarantee.idempotent,
            AuthoringGuarantee.revisionChecked,
            AuthoringGuarantee.undoable,
          }),
          reason: descriptor.id,
        );
      }

      expect(
        catalog.requireMutationAction('map.create').toJson(),
        containsPair(
          'endToEndVerifiedTransports',
          ['cli', 'directApi', 'mcp'],
        ),
      );
      expect(
        catalog.requireMutationAction('presentation.update').toJson(),
        containsPair(
          'endToEndVerifiedTransports',
          ['cli', 'directApi', 'mcp'],
        ),
      );
      expect(
        catalog
            .requireMutationAction('smart_tile.layer.change_preset')
            .toJson(),
        containsPair(
          'endToEndVerifiedTransports',
          <String>['cli', 'directApi'],
        ),
      );
      expect(
        catalog.requireMutationAction('asset.delete').toJson(),
        containsPair('endToEndVerifiedTransports', isEmpty),
      );
      expect(
        catalog.toJson()['summary'],
        containsPair('transportCertificationComplete', false),
      );
    });

    test('matches runtime and editor consumer inventories automatically', () {
      final catalog = AuthoringFullParityCatalog.canonical();
      final repositoryRoot = Directory.current.parent.parent;
      final renderWorker = File(
        '${repositoryRoot.path}/packages/map_runtime/bin/pokemap_render.dart',
      ).readAsStringSync();
      final playtestWorker = File(
        '${repositoryRoot.path}/examples/playable_runtime_host/lib/src/'
        'evaluation/driver/evaluation_playtest_adapter.dart',
      ).readAsStringSync();
      final editorAdapter = File(
        '${repositoryRoot.path}/packages/map_editor/lib/src/application/'
        'authoring_api/authoring_mutation_adapter.dart',
      ).readAsStringSync();

      for (final command in catalog.runtimeCommands) {
        final source = command == 'render' ? renderWorker : playtestWorker;
        expect(source, contains(command), reason: command);
      }
      expect(
          editorAdapter, contains('Future<EditorAuthoringMutationPlan> plan('));
      expect(editorAdapter,
          contains('Future<EditorAuthoringMutationResult> apply('));

      final editorActionIds = <String>{};
      final editorLib = Directory(
        '${repositoryRoot.path}/packages/map_editor/lib/src',
      );
      for (final entity in editorLib.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }
        final source = entity.readAsStringSync();
        for (final match in RegExp(
          r"(?:^|[^A-Za-z0-9_])actionId:\s*'([^']+)'",
          multiLine: true,
        ).allMatches(source)) {
          editorActionIds.add(match.group(1)!);
        }
      }
      expect(editorActionIds, isNotEmpty);
      expect(
        editorActionIds.difference(
          catalog.mutationActions.map((action) => action.actionId).toSet(),
        ),
        isEmpty,
        reason: 'Every editor-authored action must exist in the canonical API',
      );
    });

    test('direct API and JSONL CLI produce the same golden receipt', () async {
      final expected = jsonDecode(
        File('test/fixtures/pmcp085_golden_receipt.json').readAsStringSync(),
      );
      final direct = await _GoldenHarness.create('direct');
      final cli = await _GoldenHarness.create('cli');
      addTearDown(direct.dispose);
      addTearDown(cli.dispose);

      expect(await direct.applyDirect(), expected);
      expect(await cli.applyThroughJsonl(), expected);
    });

    test('presentation.update has direct API and JSONL CLI parity', () async {
      final direct = await _GoldenHarness.create('presentation-direct');
      final cli = await _GoldenHarness.create('presentation-cli');
      addTearDown(direct.dispose);
      addTearDown(cli.dispose);

      final directEvidence = await direct.applyPresentationDirect();
      final cliEvidence = await cli.applyPresentationThroughJsonl();

      expect(directEvidence, cliEvidence);
      expect(directEvidence['accentColor'], '#126E78');
      expect(directEvidence['schemaVersion'], 2);
      expect(
        directEvidence['introLandscape'],
        'presentation/intro-landscape.mp4',
      );
      expect(
        directEvidence['promptPortrait'],
        'presentation/prompt-portrait.mp4',
      );
    });

    test('projectPresentationProfile is a first-class query resource', () {
      const profile = ProjectPresentationProfile(
        branding: ProjectBrandingProfile(accentColor: '#126E78'),
      );
      final snapshot = ProjectSnapshot(
        projectHandle: const ProjectHandle('prj_presentation_query'),
        revision: 'sha256:${List.filled(64, 'a').join()}',
        manifest: const ProjectManifest(
          name: 'Presentation query',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          presentation: profile,
        ),
        maps: const <MapData>[],
        resourceFingerprints: <String, String>{
          'project': 'sha256:'
              '1111111111111111111111111111111111111111111111111111111111111111',
        },
      );

      expect(
        canonicalQueryableResourceKindIds,
        contains('projectPresentationProfile'),
      );
      final page = const ProjectQueryService().query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'projectPresentationProfile',
          operation: AuthoringQueryOperation.list,
          view: AuthoringQueryView.detail,
        ),
      );
      expect(page.totalAvailable, 1);
      expect(page.items.single['id'], 'project-presentation');
      expect(page.items.single['profile'], profile.toJson());
    });
  });
}

final Set<String> _approvedResourceKinds = {
  'project',
  'projectSettings',
  'projectPokemonConfig',
  'projectNewGameConfig',
  'projectPresentationProfile',
  'mapGroup',
  'map',
  'mapLayer',
  'mapConnection',
  'mapWarp',
  'mapTrigger',
  'mapGameplayZone',
  'mapPlacedElement',
  'mapEntity',
  'mapEvent',
  'tilesetFolder',
  'tileset',
  'tilesetElementGroup',
  'tilesetPaletteEntry',
  'elementCategory',
  'element',
  'smartTileAtlas',
  'smartTileMaterial',
  'smartTilePattern',
  'smartTileAnimation',
  'smartTilePreset',
  'smartTileDraft',
  'smartTileLayer',
  'environmentPreset',
  'borderBlueprint',
  'borderFeature',
  'shadowPreset',
  'projectedBuildingShadowPreset',
  'encounterTable',
  'encounterEntry',
  'dialogueFolder',
  'dialogue',
  'script',
  'scenario',
  'narrativeEvent',
  'narrativeFact',
  'worldRule',
  'scene',
  'storyline',
  'cinematic',
  'cinematicMediaAsset',
  'shop',
  'badge',
  'trainer',
  'character',
  'pokemonSpecies',
  'pokemonForm',
  'pokemonLearnset',
  'pokemonEvolution',
  'pokemonMedia',
  'pokemonMove',
  'pokemonAbility',
  'pokemonItem',
  'pokemonType',
  'pokemonCatalog',
  'gameSave',
  'gamePackage',
};

final class _GoldenHarness {
  _GoldenHarness({
    required this.root,
    required this.readApi,
    required this.mutations,
    required this.snapshots,
    required this.worker,
  });

  static Future<_GoldenHarness> create(String suffix) async {
    final root = await Directory.systemTemp.createTemp('pmcp085_$suffix');
    final manifest = ProjectManifest(
      name: 'PMCP-085 golden receipt',
      version: ProjectVersion.v6,
      maps: const [],
      tilesets: const [],
    );
    await File('${root.path}/project.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
      flush: true,
    );
    final assets = AssetCatalog(records: <AssetRecord>[
      _catalogAsset(
        'intro-landscape',
        'presentation/intro-landscape.mp4',
        'video/mp4',
        31,
      ),
      _catalogAsset(
        'intro-landscape-poster',
        'presentation/intro-landscape.png',
        'image/png',
        32,
      ),
      _catalogAsset(
        'prompt-portrait',
        'presentation/prompt-portrait.mp4',
        'video/mp4',
        33,
      ),
      _catalogAsset(
        'prompt-portrait-poster',
        'presentation/prompt-portrait.png',
        'image/png',
        34,
      ),
    ]);
    for (final asset in assets.records) {
      final blob = File(
        '${root.path}/${assetBlobStorageKey(asset.artifact)}',
      );
      await blob.create(recursive: true);
      await blob.writeAsBytes(
        <int>[
          switch (asset.id) {
            'intro-landscape' => 31,
            'intro-landscape-poster' => 32,
            'prompt-portrait' => 33,
            'prompt-portrait-poster' => 34,
            _ => throw StateError('Unexpected golden asset ${asset.id}.'),
          },
        ],
        flush: true,
      );
    }
    await File('${root.path}/$assetCatalogStorageKey').create(recursive: true);
    await File('${root.path}/$assetCatalogStorageKey').writeAsString(
      jsonEncode(assets.toJson()),
      flush: true,
    );
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final readApi = AuthoringReadApi(
      openService: ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ),
      snapshotLoader: snapshots,
    );
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
    );
    return _GoldenHarness(
      root: root,
      readApi: readApi,
      mutations: mutations,
      snapshots: snapshots,
      worker: JsonlWorker(api: readApi, mutations: mutations),
    );
  }

  final Directory root;
  final AuthoringReadApi readApi;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  final JsonlWorker worker;

  Future<Map<String, Object?>> applyDirect() async {
    final opened = await readApi.open(root.path);
    final workspace = WorkspaceHandle(opened['workspaceHandle']! as String);
    final project = ProjectHandle(opened['projectHandle']! as String);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: workspace,
      projectHandle: project,
    );
    final snapshot = await snapshots.load(project);
    final request = _request(workspace.value, snapshot.revision);
    final planned = await mutations.plan(project, request);
    final applied = await mutations.apply(
      project,
      planId: planned['planId']! as String,
      operationId: 'pmcp085-direct-apply',
    );
    return _stableReceipt(applied['receipt']);
  }

  Future<Map<String, Object?>> applyThroughJsonl() async {
    final opened = await _jsonl('open', {'projectRoot': root.path});
    final workspaceHandle = opened['workspaceHandle']! as String;
    final projectHandle = opened['projectHandle']! as String;
    final snapshot = await snapshots.load(ProjectHandle(projectHandle));
    final request = _request(workspaceHandle, snapshot.revision);
    final planned = await _jsonl('plan', {
      'projectHandle': projectHandle,
      'request': request.toJson(),
    });
    final applied = await _jsonl('apply', {
      'projectHandle': projectHandle,
      'planId': planned['planId'],
      'operationId': 'pmcp085-cli-apply',
    });
    return _stableReceipt(applied['receipt']);
  }

  Future<Map<String, Object?>> applyPresentationDirect() async {
    final opened = await readApi.open(root.path);
    final workspace = WorkspaceHandle(opened['workspaceHandle']! as String);
    final project = ProjectHandle(opened['projectHandle']! as String);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: workspace,
      projectHandle: project,
    );
    final snapshot = await snapshots.load(project);
    final planned = await mutations.plan(
      project,
      _presentationRequest(workspace.value, snapshot.revision),
    );
    final applied = await mutations.apply(
      project,
      planId: planned['planId']! as String,
      operationId: 'pmcp085-presentation-direct-apply',
    );
    return _presentationEvidence(applied['receipt']);
  }

  Future<Map<String, Object?>> applyPresentationThroughJsonl() async {
    final opened = await _jsonl('open', {'projectRoot': root.path});
    final workspaceHandle = opened['workspaceHandle']! as String;
    final projectHandle = opened['projectHandle']! as String;
    final snapshot = await snapshots.load(ProjectHandle(projectHandle));
    final planned = await _jsonl('plan', {
      'projectHandle': projectHandle,
      'request': _presentationRequest(
        workspaceHandle,
        snapshot.revision,
      ).toJson(),
    });
    final applied = await _jsonl('apply', {
      'projectHandle': projectHandle,
      'planId': planned['planId'],
      'operationId': 'pmcp085-presentation-cli-apply',
    });
    return _presentationEvidence(applied['receipt']);
  }

  AuthoringRequest _request(String workspaceHandle, String revision) =>
      AuthoringRequest(
        requestId: 'pmcp085-golden-request',
        actionId: 'map.create',
        actionVersion: 1,
        workspaceHandle: workspaceHandle,
        parameters: const {
          'mapId': 'pmcp085_golden_map',
          'width': 3,
          'height': 2,
        },
        expectedRevision: revision,
        idempotencyKey: 'pmcp085-golden-idempotency',
        dryRun: false,
      );

  AuthoringRequest _presentationRequest(
    String workspaceHandle,
    String revision,
  ) =>
      AuthoringRequest(
        requestId: 'pmcp085-presentation-request',
        actionId: 'presentation.update',
        actionVersion: 1,
        workspaceHandle: workspaceHandle,
        parameters: {
          'profile': _responsivePresentationProfile.toJson(),
        },
        expectedRevision: revision,
        idempotencyKey: 'pmcp085-presentation-idempotency',
        dryRun: false,
      );

  Future<Map<String, Object?>> _presentationEvidence(Object? receipt) async {
    final manifest = ProjectManifest.fromJson(
      jsonDecode(await File('${root.path}/project.json').readAsString())
          as Map<String, dynamic>,
    );
    return <String, Object?>{
      'receipt': _stableReceipt(receipt),
      'accentColor': manifest.presentation?.branding.accentColor,
      'schemaVersion': manifest.presentation?.schemaVersion,
      'introLandscape': manifest.presentation?.intro?.media.landscape.videoPath,
      'promptPortrait':
          manifest.presentation?.titleMotion?.promptLoop?.portrait?.videoPath,
    };
  }

  Future<Map<String, Object?>> _jsonl(
    String command,
    Map<String, Object?> args,
  ) async {
    final decoded = jsonDecode(
      await worker.processLine(
        jsonEncode({
          'id': 'pmcp085-$command',
          'command': command,
          'args': args,
        }),
      ),
    ) as Map<String, dynamic>;
    final result = AuthoringResult.fromJson(decoded);
    expect(
      result.status,
      AuthoringResultStatus.success,
      reason: result.error?.toJson().toString(),
    );
    return result.data;
  }

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

const ProjectPresentationProfile _responsivePresentationProfile =
    ProjectPresentationProfile(
  branding: ProjectBrandingProfile(accentColor: '#126E78'),
  intro: ProjectIntroVideoProfile(
    media: ProjectResponsiveVideoProfile(
      landscape: ProjectVideoVariantProfile(
        videoPath: 'presentation/intro-landscape.mp4',
        posterPath: 'presentation/intro-landscape.png',
        durationMilliseconds: 6000,
        width: 1920,
        height: 1080,
        bitrateKbps: 2500,
        sizeBytes: 4000000,
        videoCodec: 'h264',
        audioCodec: 'none',
      ),
    ),
  ),
  titleMotion: ProjectTitleMotionProfile(
    promptLoop: ProjectResponsiveVideoProfile(
      landscape: ProjectVideoVariantProfile(
        videoPath: 'presentation/intro-landscape.mp4',
        posterPath: 'presentation/intro-landscape.png',
        durationMilliseconds: 6000,
        width: 1920,
        height: 1080,
        bitrateKbps: 2500,
        sizeBytes: 4000000,
        videoCodec: 'h264',
        audioCodec: 'none',
      ),
      portrait: ProjectVideoVariantProfile(
        videoPath: 'presentation/prompt-portrait.mp4',
        posterPath: 'presentation/prompt-portrait.png',
        durationMilliseconds: 6000,
        width: 1080,
        height: 1920,
        bitrateKbps: 2500,
        sizeBytes: 4000000,
        videoCodec: 'h264',
        audioCodec: 'none',
      ),
    ),
  ),
);

AssetRecord _catalogAsset(
  String id,
  String logicalPath,
  String mediaType,
  int byte,
) =>
    AssetRecord(
      id: id,
      logicalPath: logicalPath,
      artifact: ContentArtifactRef.fromBytes(<int>[byte], mediaType: mediaType),
    );

Map<String, Object?> _stableReceipt(Object? raw) {
  final receipt = AuthoringReceipt.fromJson(
    Map<String, dynamic>.from(raw! as Map),
  );
  return {
    'actionId': receipt.actionId,
    'actionVersion': receipt.actionVersion,
    'status': receipt.status.wireName,
    'changes': [
      for (final entry in receipt.diff.entries)
        {
          'operation': entry.operation.wireName,
          'resource': {
            'kind': entry.resource.kind,
            'id': entry.resource.id,
          },
          'path': entry.path,
        },
    ],
  };
}
