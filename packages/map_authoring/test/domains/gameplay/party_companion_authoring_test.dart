import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/domains/gameplay/party_companion_actions.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
      'canonical companion action validates species form and walking character before changing bytes',
      () async {
    final project = ProjectManifest(
        name: 'Companion',
        version: ProjectVersion.v9,
        maps: [],
        tilesets: [
          ProjectTilesetEntry.fromJson({
            'id': 'sheet',
            'name': 'Sheet',
            'relativePath': 'assets/sheet.png',
            'source': {
              'kind': 'regular_atlas',
              'assetId': 'sheet',
              'pixelWidth': 32,
              'pixelHeight': 32,
              'tileWidth': 32,
              'tileHeight': 32,
              'tileProperties': []
            }
          })
        ],
        settings: ProjectSettings(
            dimension: ProjectDimension.threeD,
            spatialCamera: SpatialCameraProfile()),
        pokemon: const ProjectPokemonConfig(
            enabled: true, ruleset: PokemonRulesetProfile.pokeMapBetaV1),
        characters: [
          ProjectCharacterEntry(
              id: 'guide',
              name: 'Guide',
              tilesetId: 'sheet',
              animations: [
                for (final facing in EntityFacing.values)
                  CharacterAnimation(
                      state: CharacterAnimationState.walk,
                      direction: facing,
                      frames: const [
                        CharacterAnimationFrame(
                            source: TilesetSourceRect(
                                x: 0, y: 0, width: 32, height: 32),
                            durationMs: 100)
                      ]),
              ])
        ]);
    final bytes = utf8.encode(jsonEncode(project.toJson()));
    final species = utf8.encode(jsonEncode({
      'schemaVersion': 1,
      'id': 'clockbird',
      'forms': {'formId': 'bronze'}
    }));
    final revision =
        computeAuthoringBytesFingerprint(bytes, logicalName: 'project.json');
    final snapshot = ProjectSnapshot(
        projectHandle: const ProjectHandle('companion'),
        revision: revision,
        manifest: project,
        maps: [],
        resourceFingerprints: {
          'project': revision,
          'pokemonSpecies:clockbird': computeAuthoringBytesFingerprint(species,
              logicalName: 'data/pokemon/species/clockbird.json')
        },
        resourceBytes: {
          'project': bytes,
          'pokemonSpecies:clockbird': species
        },
        resourceStorageKeys: {
          'project': 'project.json',
          'pokemonSpecies:clockbird': 'data/pokemon/species/clockbird.json'
        });
    Future<AuthoringMutationDraft> plan(Map<String, Object?> parameters) =>
        const PartyCompanionActions().build(AuthoringPlanningContext(
            snapshot: snapshot,
            request: AuthoringRequest(
                requestId: 'request',
                actionId: 'party_companion.configure',
                actionVersion: 1,
                workspaceHandle: 'workspace',
                expectedRevision: revision,
                parameters: parameters,
                idempotencyKey: 'request',
                dryRun: true),
            planId: 'plan',
            seed: 1));
    final parameters = {
      'enabled': true,
      'mappings': [
        {'speciesId': 'clockbird', 'formId': 'bronze', 'characterId': 'guide'}
      ]
    };
    final draft = await plan(parameters);
    expect(snapshot.resourceBytes('project'), bytes);
    final changed = ProjectManifest.fromJson(jsonDecode(utf8.decode(
            await draft.changeSet.changes.single.afterPayload!.readBytes()))
        as Map<String, dynamic>);
    expect(changed.partyCompanion.toJson(), parameters);
    expect(changed.characters, project.characters);
    final configuredSnapshot = ProjectSnapshot(
        projectHandle: snapshot.projectHandle,
        revision: revision,
        manifest: changed,
        maps: [],
        resourceFingerprints: snapshot.resourceFingerprints,
        resourceBytes: {'project': bytes, 'pokemonSpecies:clockbird': species},
        resourceStorageKeys: snapshot.resourceStorageKeys);
    expect(
        () => const PokemonCatalogActions().build(AuthoringPlanningContext(
            snapshot: configuredSnapshot,
            request: AuthoringRequest(
                requestId: 'delete-companion-species',
                actionId: 'pokemon.species.delete',
                actionVersion: 1,
                workspaceHandle: 'workspace',
                expectedRevision: revision,
                parameters: {
                  'relativePath': 'data/pokemon/species/clockbird.json',
                  'resourceId': 'clockbird',
                  'beforeBytesBase64': base64Encode(species)
                },
                idempotencyKey: 'delete-companion-species',
                dryRun: true),
            planId: 'delete-plan',
            seed: 1)),
        throwsFormatException);
    for (final invalid in [
      {
        'enabled': true,
        'mappings': [
          {'speciesId': 'missing', 'formId': 'bronze', 'characterId': 'guide'}
        ]
      },
      {
        'enabled': true,
        'mappings': [
          {'speciesId': 'clockbird', 'formId': 'wrong', 'characterId': 'guide'}
        ]
      },
      {
        'enabled': true,
        'mappings': [
          {
            'speciesId': 'clockbird',
            'formId': 'bronze',
            'characterId': 'missing'
          }
        ]
      },
    ]) {
      await expectLater(plan(invalid), throwsA(anything));
      expect(snapshot.resourceBytes('project'), bytes);
    }
  });

  test('companion action resource and transport contracts are discoverable',
      () {
    final action = MapMutationDispatcher.canonical()
        .descriptors
        .singleWhere((action) => action.id == 'party_companion.configure');
    expect(action.extensions['trailDistanceCells'], 1);
    expect(canonicalQueryableResourceKindIds,
        contains('partyCompanionConfiguration'));
    expect(
        AuthoringFullParityCatalog.canonical()
            .mutationActions
            .singleWhere((entry) => entry.actionId == action.id)
            .adapterCapableTransports,
        AuthoringTransport.values.toSet());
  });

  for (final jsonl in [false, true]) {
    test(
        '${jsonl ? 'JSONL' : 'direct API'} plans applies reopens and queries companion configuration',
        () async {
      final root =
          await Directory.systemTemp.createTemp('party-companion-authoring-');
      addTearDown(() => root.delete(recursive: true));
      final actor = ProjectCharacterEntry(
          id: 'guide',
          name: 'Guide',
          tilesetId: 'sheet',
          animations: [
            for (final facing in EntityFacing.values)
              CharacterAnimation(
                  state: CharacterAnimationState.walk,
                  direction: facing,
                  sourceAssetId: 'sheet',
                  frames: const [
                    CharacterAnimationFrame(
                        source: TilesetSourceRect(
                            x: 0, y: 0, width: 32, height: 32),
                        durationMs: 100)
                  ]),
          ]);
      await File('${root.path}/project.json')
          .writeAsString(jsonEncode(ProjectManifest(
              name: 'Companion configuration',
              maps: [],
              tilesets: [
                ProjectTilesetEntry.fromJson({
                  'id': 'sheet',
                  'name': 'Sheet',
                  'relativePath': 'assets/sheet.png',
                  'source': {
                    'kind': 'regular_atlas',
                    'assetId': 'sheet',
                    'pixelWidth': 32,
                    'pixelHeight': 32,
                    'tileWidth': 32,
                    'tileHeight': 32,
                    'tileProperties': []
                  }
                }),
              ],
              characters: [actor],
              partyCompanion: const ProjectPartyCompanionConfig(mappings: [
                PartyCompanionVisual(
                    speciesId: 'clockbird',
                    formId: 'base',
                    characterId: 'guide'),
              ])).toJson()));
      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
          allowedRootPaths: [root.path], fileReader: reader);
      final handles = WorkspaceHandleStore();
      final snapshots = ProjectSnapshotLoader(handles: handles);
      final api = AuthoringReadApi(
          openService: ProjectOpenService(
              policy: policy, fileReader: reader, handles: handles),
          snapshotLoader: snapshots);
      final mutations = LocalMapAuthoringMutationApi(
          policy: policy, snapshotLoader: snapshots);
      var opened = await api.openProject(root.path);
      addTearDown(() => api.closeWorkspace(opened.workspaceHandle));
      await mutations.attachProject(
          projectRootPath: root.path,
          workspaceHandle: opened.workspaceHandle,
          projectHandle: opened.projectHandle);
      final request = AuthoringRequest(
          requestId: 'configure',
          actionId: 'party_companion.configure',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          parameters: const {'enabled': false, 'mappings': []},
          expectedRevision:
              (await snapshots.load(opened.projectHandle)).revision,
          idempotencyKey: 'configure',
          dryRun: false);
      final worker = JsonlWorker(api: api, mutations: mutations);
      Future<Map<String, dynamic>> wire(
          String command, Map<String, Object?> args) async {
        final result = AuthoringResult.fromJson(jsonDecode(
                await worker.processLine(jsonEncode(
                    {'id': command, 'command': command, 'args': args})))
            as Map<String, dynamic>);
        expect(result.status, AuthoringResultStatus.success,
            reason: result.error?.message);
        return Map<String, dynamic>.from(result.data);
      }

      if (jsonl) {
        final plan = await wire('plan', {
          'projectHandle': opened.projectHandle.value,
          'request': request.toJson()
        });
        await wire('apply', {
          'projectHandle': opened.projectHandle.value,
          'planId': plan['planId'],
          'operationId': 'apply'
        });
      } else {
        final plan = await mutations.plan(opened.projectHandle, request);
        await mutations.apply(opened.projectHandle,
            planId: plan['planId'] as String, operationId: 'apply');
      }
      await api.closeWorkspace(opened.workspaceHandle);
      opened = await api.openProject(root.path);
      final query = AuthoringQueryRequest(
          resourceKind: 'partyCompanionConfiguration',
          operation: AuthoringQueryOperation.get,
          ids: ['project'],
          view: AuthoringQueryView.detail);
      final page = jsonl
          ? AuthoringQueryPage.fromJson(await wire('query', {
              'projectHandle': opened.projectHandle.value,
              'request': query.toJson()
            }))
          : await api.queryProject(opened.projectHandle, query);
      expect(page.items.single['enabled'], false);
      expect(page.items.single['mappings'], isEmpty);
    });
  }
}
