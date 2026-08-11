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
          ['cli', 'directApi', 'editor', 'mcp'],
        ),
      );
      expect(
        AuthoringResourceKindRegistry.canonical()
            .resourceKinds
            .singleWhere(
              (descriptor) => descriptor.id == 'projectPresentationProfile',
            )
            .version,
        8,
      );
      expect(
        catalog.requireMutationAction('presentation.preset.export').toJson(),
        containsPair(
          'endToEndVerifiedTransports',
          ['cli', 'directApi', 'editor', 'mcp'],
        ),
      );
      expect(
        catalog
            .requireMutationAction('smart_tile.layer.change_preset')
            .toJson(),
        containsPair(
          'endToEndVerifiedTransports',
          <String>['cli', 'directApi', 'editor', 'mcp'],
        ),
      );
      expect(
        catalog
            .requireMutationAction(
              'smart_tile.layer.set_animation_activation',
            )
            .toJson(),
        containsPair(
          'endToEndVerifiedTransports',
          <String>['cli', 'directApi', 'editor', 'mcp'],
        ),
      );
      for (final actionId in <String>[
        'campaign.encounter_table.upsert',
        'campaign.encounter_table.delete',
      ]) {
        expect(
          catalog.requireMutationAction(actionId).toJson(),
          containsPair(
            'endToEndVerifiedTransports',
            <String>['cli', 'directApi', 'editor', 'mcp'],
          ),
          reason: actionId,
        );
      }
      for (final action in catalog.mutationActions.where(
        (action) => action.actionId.startsWith('item.'),
      )) {
        expect(
          action.toJson(),
          containsPair(
            'endToEndVerifiedTransports',
            <String>['cli', 'directApi', 'editor', 'mcp'],
          ),
          reason: action.actionId,
        );
      }
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
      expect(directEvidence['schemaVersion'], 8);
      expect(directEvidence['titleCopy'], 'Aube sur Hanazuki');
      expect(directEvidence['titleSubtitle'], 'Studio Brume');
      expect(directEvidence['titlePrompt'], 'Appuyez pour commencer');
      expect(directEvidence['titleActionOrder'], <String>[
        'newGame',
        'continueGame',
        'options',
      ]);
      expect(directEvidence['titleNewGameLabel'], 'Commencer');
      expect(directEvidence['titleOptionsVisible'], isFalse);
      expect(directEvidence['pauseTitle'], 'Escale');
      expect(directEvidence['pauseActionOrder'], <String>[
        'pokedex',
        'resume',
        'map',
      ]);
      expect(directEvidence['pausePokedexLabel'], 'Carnet de voyage');
      expect(directEvidence['pauseMapVisible'], isFalse);
      expect(directEvidence['pauseExpandedEntrySize'], 'large');
      expect(directEvidence['pauseExpandedShowDetail'], isFalse);
      expect(
        directEvidence['introLandscape'],
        'presentation/intro-landscape.mp4',
      );
      expect(
        directEvidence['promptPortrait'],
        'presentation/prompt-portrait.mp4',
      );
      expect(directEvidence['pauseWindowStyle'], 'pause-menu');
      expect(directEvidence['dialogueWindowStyle'], 'dialogue');
      expect(directEvidence['battleWindowStyle'], 'default');
      expect(directEvidence['pauseBackdropOpacity'], .7);
      expect(directEvidence['titleExpandedSlot'], 'bottomLeft');
      expect(directEvidence['battleExpandedSlot'], 'bottomCenter');
      expect(directEvidence['combatFontFamily'], 'Battle Mono');
      expect(directEvidence['combatSizeScale'], 1.1);
      expect(directEvidence['battlePaletteSurface'], '#102030');
      expect(directEvidence['pauseWindowShape'], 'cutCorner');
      expect(directEvidence['pauseWindowFillOpacity'], .8);
    });

    test('presentation preset export has direct API and JSONL CLI parity',
        () async {
      final direct = await _GoldenHarness.create('preset-direct');
      final cli = await _GoldenHarness.create('preset-cli');
      addTearDown(direct.dispose);
      addTearDown(cli.dispose);

      expect(
        await direct.exportPresentationPresetDirect(),
        await cli.exportPresentationPresetThroughJsonl(),
      );
    });

    test('encounter tables have direct API and JSONL CLI parity', () async {
      final direct = await _GoldenHarness.create('encounter-direct');
      final cli = await _GoldenHarness.create('encounter-cli');
      addTearDown(direct.dispose);
      addTearDown(cli.dispose);

      final directEvidence = await direct.applyEncounterDirect();
      final cliEvidence = await cli.applyEncounterThroughJsonl();

      expect(directEvidence, cliEvidence);
      expect(
        directEvidence['upsertActionId'],
        'campaign.encounter_table.upsert',
      );
      expect(
        directEvidence['deleteActionId'],
        'campaign.encounter_table.delete',
      );
      final table = directEvidence['table']! as Map<String, Object?>;
      expect(table['id'], 'route_one_grass');
      expect(table['entries'], hasLength(2));
      expect(directEvidence['remainingTableIds'], isEmpty);
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
  'projectPresentationPreset',
  'presentationPreviewContext',
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
  'characterStudioCatalog',
  'characterStudioCharacter',
  'characterStudioDependency',
  'characterStudioReadiness',
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
  'itemCatalog',
  'itemDefinition',
  'itemUsage',
  'itemReadiness',
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

  Future<Map<String, Object?>> exportPresentationPresetDirect() async {
    final opened = await readApi.open(root.path);
    final workspace = WorkspaceHandle(opened['workspaceHandle']! as String);
    final project = ProjectHandle(opened['projectHandle']! as String);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: workspace,
      projectHandle: project,
    );
    var snapshot = await snapshots.load(project);
    final presentation = await mutations.plan(
      project,
      _simplePresentationRequest(workspace.value, snapshot.revision),
    );
    await mutations.apply(
      project,
      planId: presentation['planId']! as String,
      operationId: 'preset-direct-presentation',
    );
    snapshot = await snapshots.load(project);
    final planned = await mutations.plan(
      project,
      _presetExportRequest(workspace.value, snapshot.revision),
    );
    final receipt = AuthoringReceipt.fromJson(
      Map<String, dynamic>.from(planned['receipt']! as Map),
    );
    await mutations.apply(
      project,
      planId: planned['planId']! as String,
      operationId: 'preset-direct-export',
    );
    return _presetEvidence(receipt);
  }

  Future<Map<String, Object?>> exportPresentationPresetThroughJsonl() async {
    final opened = await _jsonl('open', {'projectRoot': root.path});
    final workspaceHandle = opened['workspaceHandle']! as String;
    final projectHandle = opened['projectHandle']! as String;
    var snapshot = await snapshots.load(ProjectHandle(projectHandle));
    final presentation = await _jsonl('plan', {
      'projectHandle': projectHandle,
      'request': _simplePresentationRequest(
        workspaceHandle,
        snapshot.revision,
      ).toJson(),
    });
    await _jsonl('apply', {
      'projectHandle': projectHandle,
      'planId': presentation['planId'],
      'operationId': 'preset-cli-presentation',
    });
    snapshot = await snapshots.load(ProjectHandle(projectHandle));
    final planned = await _jsonl('plan', {
      'projectHandle': projectHandle,
      'request': _presetExportRequest(
        workspaceHandle,
        snapshot.revision,
      ).toJson(),
    });
    final receipt = AuthoringReceipt.fromJson(
      Map<String, dynamic>.from(planned['receipt']! as Map),
    );
    await _jsonl('apply', {
      'projectHandle': projectHandle,
      'planId': planned['planId'],
      'operationId': 'preset-cli-export',
    });
    return _presetEvidence(receipt);
  }

  Future<Map<String, Object?>> applyEncounterDirect() async {
    final opened = await readApi.open(root.path);
    final workspace = WorkspaceHandle(opened['workspaceHandle']! as String);
    final project = ProjectHandle(opened['projectHandle']! as String);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: workspace,
      projectHandle: project,
    );
    final snapshot = await snapshots.load(project);
    final upsertPlan = await mutations.plan(
      project,
      _encounterRequest(
        workspaceHandle: workspace.value,
        revision: snapshot.revision,
        actionId: 'campaign.encounter_table.upsert',
        parameters: <String, Object?>{'value': _encounterTable.toJson()},
        sequence: 'upsert',
      ),
    );
    final upsert = await mutations.apply(
      project,
      planId: upsertPlan['planId']! as String,
      operationId: 'pmcp085-encounter-direct-upsert',
    );
    final afterUpsert = await _readManifest();
    final upsertReceipt = upsert['receipt']! as Map<String, Object?>;
    final deletePlan = await mutations.plan(
      project,
      _encounterRequest(
        workspaceHandle: workspace.value,
        revision: upsert['snapshotRevision']! as String,
        actionId: 'campaign.encounter_table.delete',
        parameters: const <String, Object?>{'id': 'route_one_grass'},
        sequence: 'delete',
      ),
    );
    final confirmation = await mutations.confirm(
      project,
      planId: deletePlan['planId']! as String,
    );
    final deleted = await mutations.apply(
      project,
      planId: deletePlan['planId']! as String,
      operationId: 'pmcp085-encounter-direct-delete',
      confirmationToken: confirmation['confirmationToken']! as String,
    );
    return _encounterEvidence(
      upsertReceipt: upsertReceipt,
      deleteReceipt: deleted['receipt']! as Map<String, Object?>,
      afterUpsert: afterUpsert,
      afterDelete: await _readManifest(),
    );
  }

  Future<Map<String, Object?>> applyEncounterThroughJsonl() async {
    final opened = await _jsonl('open', {'projectRoot': root.path});
    final workspaceHandle = opened['workspaceHandle']! as String;
    final projectHandle = opened['projectHandle']! as String;
    final snapshot = await snapshots.load(ProjectHandle(projectHandle));
    final upsertPlan = await _jsonl('plan', <String, Object?>{
      'projectHandle': projectHandle,
      'request': _encounterRequest(
        workspaceHandle: workspaceHandle,
        revision: snapshot.revision,
        actionId: 'campaign.encounter_table.upsert',
        parameters: <String, Object?>{'value': _encounterTable.toJson()},
        sequence: 'upsert',
      ).toJson(),
    });
    final upsert = await _jsonl('apply', <String, Object?>{
      'projectHandle': projectHandle,
      'planId': upsertPlan['planId'],
      'operationId': 'pmcp085-encounter-cli-upsert',
    });
    final afterUpsert = await _readManifest();
    final upsertReceipt = upsert['receipt']! as Map<String, Object?>;
    final deletePlan = await _jsonl('plan', <String, Object?>{
      'projectHandle': projectHandle,
      'request': _encounterRequest(
        workspaceHandle: workspaceHandle,
        revision: upsert['snapshotRevision']! as String,
        actionId: 'campaign.encounter_table.delete',
        parameters: const <String, Object?>{'id': 'route_one_grass'},
        sequence: 'delete',
      ).toJson(),
    });
    final confirmation = await _jsonl('confirm', <String, Object?>{
      'projectHandle': projectHandle,
      'planId': deletePlan['planId'],
    });
    final deleted = await _jsonl('apply', <String, Object?>{
      'projectHandle': projectHandle,
      'planId': deletePlan['planId'],
      'operationId': 'pmcp085-encounter-cli-delete',
      'confirmationToken': confirmation['confirmationToken'],
    });
    return _encounterEvidence(
      upsertReceipt: upsertReceipt,
      deleteReceipt: deleted['receipt']! as Map<String, Object?>,
      afterUpsert: afterUpsert,
      afterDelete: await _readManifest(),
    );
  }

  AuthoringRequest _encounterRequest({
    required String workspaceHandle,
    required String revision,
    required String actionId,
    required Map<String, Object?> parameters,
    required String sequence,
  }) =>
      AuthoringRequest(
        requestId: 'pmcp085-encounter-$sequence',
        actionId: actionId,
        actionVersion: 1,
        workspaceHandle: workspaceHandle,
        parameters: parameters,
        expectedRevision: revision,
        idempotencyKey: 'pmcp085-encounter-$sequence',
        dryRun: false,
      );

  Future<ProjectManifest> _readManifest() async => ProjectManifest.fromJson(
        jsonDecode(await File('${root.path}/project.json').readAsString())
            as Map<String, dynamic>,
      );

  Map<String, Object?> _encounterEvidence({
    required Map<String, Object?> upsertReceipt,
    required Map<String, Object?> deleteReceipt,
    required ProjectManifest afterUpsert,
    required ProjectManifest afterDelete,
  }) =>
      <String, Object?>{
        'upsertActionId': upsertReceipt['actionId'],
        'deleteActionId': deleteReceipt['actionId'],
        'table': afterUpsert.encounterTables.single.toJson(),
        'remainingTableIds': <String>[
          for (final table in afterDelete.encounterTables) table.id,
        ],
      };

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

  AuthoringRequest _simplePresentationRequest(
    String workspaceHandle,
    String revision,
  ) =>
      AuthoringRequest(
        requestId: 'preset-presentation-request',
        actionId: 'presentation.update',
        actionVersion: 1,
        workspaceHandle: workspaceHandle,
        parameters: <String, Object?>{
          'profile': const ProjectPresentationProfile(
            branding: ProjectBrandingProfile(accentColor: '#126E78'),
          ).toJson(),
        },
        expectedRevision: revision,
        idempotencyKey: 'preset-presentation-idempotency',
        dryRun: false,
      );

  AuthoringRequest _presetExportRequest(
    String workspaceHandle,
    String revision,
  ) =>
      AuthoringRequest(
        requestId: 'preset-export-request',
        actionId: 'presentation.preset.export',
        actionVersion: 1,
        workspaceHandle: workspaceHandle,
        parameters: const <String, Object?>{
          'presetId': 'avelune-profile',
          'label': 'Avelune Profile',
          'description': 'Shareable authoring parity profile.',
          'licenses': <String, String>{},
        },
        expectedRevision: revision,
        idempotencyKey: 'preset-export-idempotency',
        dryRun: false,
      );

  Future<Map<String, Object?>> _presetEvidence(AuthoringReceipt receipt) async {
    final manifest = ProjectManifest.fromJson(
      jsonDecode(await File('${root.path}/project.json').readAsString())
          as Map<String, dynamic>,
    );
    final preset = manifest.presentationPresets.single;
    final artifact = receipt.artifacts.single;
    return <String, Object?>{
      'preset': preset.toJson(),
      'artifactMediaType': artifact.mediaType,
      'artifactBytes': artifact.byteLength,
      'artifactSha256': artifact.sha256,
    };
  }

  Future<Map<String, Object?>> _presentationEvidence(Object? receipt) async {
    final manifest = ProjectManifest.fromJson(
      jsonDecode(await File('${root.path}/project.json').readAsString())
          as Map<String, dynamic>,
    );
    return <String, Object?>{
      'receipt': _stableReceipt(receipt),
      'accentColor': manifest.presentation?.branding.accentColor,
      'schemaVersion': manifest.presentation?.schemaVersion,
      'titleCopy': manifest.presentation?.title?.title,
      'titleSubtitle': manifest.presentation?.title?.subtitle,
      'titlePrompt': manifest.presentation?.title?.prompt,
      'titleActionOrder': manifest.presentation?.title?.actions
          ?.map((action) => action.id.name)
          .toList(growable: false),
      'titleNewGameLabel': manifest.presentation?.title?.actions
          ?.firstWhere((action) => action.id == ProjectTitleActionId.newGame)
          .label,
      'titleOptionsVisible': manifest.presentation?.title?.actions
          ?.firstWhere((action) => action.id == ProjectTitleActionId.options)
          .visible,
      'introLandscape': manifest.presentation?.intro?.media.landscape.videoPath,
      'promptPortrait':
          manifest.presentation?.titleMotion?.promptLoop?.portrait?.videoPath,
      'pauseTitle': manifest.presentation?.pause?.title,
      'pauseActionOrder': manifest.presentation?.pause?.actions
          ?.map((action) => action.id.name)
          .toList(growable: false),
      'pausePokedexLabel': manifest.presentation?.pause?.actions
          ?.firstWhere((action) => action.id == ProjectPauseActionId.pokedex)
          .label,
      'pauseMapVisible': manifest.presentation?.pause?.actions
          ?.firstWhere((action) => action.id == ProjectPauseActionId.map)
          .visible,
      'pauseExpandedEntrySize':
          manifest.presentation?.pause?.composition?.expanded.entrySize.name,
      'pauseExpandedShowDetail': manifest
          .presentation?.pause?.composition?.expanded.showRootDetailPanel,
      'pauseWindowStyle': manifest.presentation?.windows?.pauseMenuStyleId,
      'dialogueWindowStyle': manifest.presentation?.windows?.dialogueStyleId,
      'battleWindowStyle': manifest.presentation?.windows?.battleStyleId,
      'pauseBackdropOpacity':
          manifest.presentation?.windows?.pauseBackdropOpacity,
      'titleExpandedSlot':
          manifest.presentation?.layouts?.title.expanded.slot.name,
      'battleExpandedSlot':
          manifest.presentation?.layouts?.battle?.expanded.slot.name,
      'combatFontFamily': manifest.presentation?.typography?.combat?.family,
      'combatSizeScale':
          manifest.presentation?.typography?.combat?.metrics?.sizeScale,
      'battlePaletteSurface':
          manifest.presentation?.surfacePalettes?.battle?.surface,
      'pauseWindowShape': manifest.presentation?.windows
          ?.resolve(ProjectWindowRole.pauseMenu)
          .shape
          .name,
      'pauseWindowFillOpacity': manifest.presentation?.windows
          ?.resolve(ProjectWindowRole.pauseMenu)
          .fillOpacity,
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

const ProjectEncounterTable _encounterTable = ProjectEncounterTable(
  id: 'route_one_grass',
  name: 'Route 1 — Hautes herbes',
  encounterKind: EncounterKind.walk,
  chancePerStep: 0.14,
  entries: <ProjectEncounterEntry>[
    ProjectEncounterEntry(
      speciesId: 'rattata',
      minLevel: 2,
      maxLevel: 4,
      weight: 3,
    ),
    ProjectEncounterEntry(
      speciesId: 'pidgey',
      minLevel: 3,
      maxLevel: 5,
      weight: 1,
    ),
  ],
  tags: <String>['route', 'early-game'],
);

final ProjectPresentationProfile _responsivePresentationProfile =
    ProjectPresentationProfile(
  branding: ProjectBrandingProfile(accentColor: '#126E78'),
  title: ProjectTitlePresentationProfile(
    title: 'Aube sur Hanazuki',
    subtitle: 'Studio Brume',
    prompt: 'Appuyez pour commencer',
    actions: <ProjectTitleActionProfile>[
      ProjectTitleActionProfile(
        id: ProjectTitleActionId.newGame,
        label: 'Commencer',
        icon: ProjectTitleActionIcon.sparkles,
      ),
      ProjectTitleActionProfile(
        id: ProjectTitleActionId.continueGame,
        label: 'Reprendre',
        icon: ProjectTitleActionIcon.play,
      ),
      ProjectTitleActionProfile(
        id: ProjectTitleActionId.options,
        visible: false,
      ),
    ],
  ),
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
  pause: ProjectPausePresentationProfile(
    title: 'Escale',
    actions: <ProjectPauseActionProfile>[
      ProjectPauseActionProfile(
        id: ProjectPauseActionId.pokedex,
        label: 'Carnet de voyage',
        icon: ProjectPauseActionIcon.book,
      ),
      ProjectPauseActionProfile(
        id: ProjectPauseActionId.resume,
        icon: ProjectPauseActionIcon.play,
      ),
      ProjectPauseActionProfile(
        id: ProjectPauseActionId.map,
        icon: ProjectPauseActionIcon.map,
        visible: false,
      ),
    ],
    composition: ProjectResponsivePauseCompositionProfile(
      expanded: ProjectPauseCompositionVariantProfile(
        entrySize: ProjectPauseEntrySize.large,
        entrySpacing: ProjectPauseEntrySpacing.airy,
        showRootDetailPanel: false,
      ),
    ),
  ),
  typography: ProjectTypographyProfile(
    combat: ProjectTypographyRoleProfile(
      family: 'Battle Mono',
      metrics: ProjectTypographyMetricsProfile(sizeScale: 1.1),
    ),
  ),
  surfacePalettes: ProjectPresentationSurfacePalettesProfile(
    battle: ProjectSurfacePaletteProfile(
      surface: '#102030',
      border: '#63E6FF',
      text: '#FFFFFF',
      accent: '#63E6FF',
    ),
  ),
  windows: legacyProjectPresentationWindows.copyWith(
    styles: <ProjectWindowStyleProfile>[
      for (final style in legacyProjectPresentationWindows.styles)
        if (style.id == 'pause-menu')
          style.copyWith(
            shape: ProjectWindowShape.cutCorner,
            fillOpacity: .8,
          )
        else
          style,
    ],
    battleStyleId: 'default',
  ),
  layouts: suggestedProjectPresentationLayouts('cinematic'),
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
