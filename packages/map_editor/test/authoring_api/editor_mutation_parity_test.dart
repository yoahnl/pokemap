import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/encounter_table_persistence_gateway.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_session_lifecycle.dart';
import 'package:map_editor/src/application/authoring_api/editor_receipt_presenter.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/services/map_connection_editing_service.dart';
import 'package:map_editor/src/application/use_cases/map_connection_use_cases.dart';
import 'package:map_editor/src/application/use_cases/map_use_cases.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/features/personalization/application/project_presentation_preset_service.dart';
import 'package:path/path.dart' as p;

void main() {
  group('AuthoringMutationAdapter', () {
    test('editor connection intents consume all five catalogued actions', () {
      final service = MapConnectionEditingService(
        resolveMapConnectionTargetUseCase: ResolveMapConnectionTargetUseCase(),
      );
      const source = MapData(
        id: 'source',
        name: 'Source',
        size: GridSize(width: 8, height: 8),
      );
      final consumedActionIds = <String>{
        service
            .buildUpsertIntent(
              sourceMap: source,
              direction: MapConnectionDirection.east,
              targetMapId: 'target',
              offset: 0,
              reciprocal: false,
              exactReciprocalPairExists: false,
            )
            .actionId,
        service
            .buildUpsertIntent(
              sourceMap: source,
              direction: MapConnectionDirection.east,
              targetMapId: 'target',
              offset: 0,
              reciprocal: true,
              exactReciprocalPairExists: false,
            )
            .actionId,
        service
            .buildUpsertIntent(
              sourceMap: source,
              direction: MapConnectionDirection.east,
              targetMapId: 'target',
              offset: 0,
              reciprocal: true,
              exactReciprocalPairExists: true,
            )
            .actionId,
        service
            .buildDeleteIntent(
              sourceMap: source,
              direction: MapConnectionDirection.east,
              exactReciprocalPairExists: false,
            )
            .actionId,
        service
            .buildDeleteIntent(
              sourceMap: source,
              direction: MapConnectionDirection.east,
              exactReciprocalPairExists: true,
            )
            .actionId,
      };
      expect(consumedActionIds, const {
        'connection.upsert',
        'connection.delete',
        'connection.create_bidirectional_apply',
        'connection.update_bidirectional_apply',
        'connection.delete_bidirectional_apply',
      });

      final catalog = AuthoringFullParityCatalog.canonical();
      for (final actionId in consumedActionIds) {
        expect(
          catalog.requireMutationAction(actionId).adapterCapableTransports,
          contains(AuthoringTransport.editor),
          reason: actionId,
        );
      }
    });

    test('warm canonical map save rereads only the touched map payload',
        () async {
      final fixture = await _MutationFixture.create(enableSnapshotCache: true);
      addTearDown(fixture.dispose);
      await fixture.mutations.plan(
        fixture.root.path,
        actionId: 'map.save',
        parameters: {
          'map': fixture.map.copyWith(name: 'Warmup only').toJson(),
        },
        idempotencyKey: 'editor_fast_save_warmup',
      );
      final baseline =
          await FileMapRepository().loadMapDocument(fixture.mapPath);
      fixture.countingReader!.resetCounts();

      final result = await fixture.mutations.saveMap(
        fixture.map.copyWith(name: 'Fast save'),
        fixture.mapPath,
        expectedMapRevision: baseline.revision,
      );

      expect(result.receipt.status, AuthoringReceiptStatus.applied);
      expect(fixture.countingReader!.byteReads, 1);
    });

    test('saves presentation pause labels through the canonical action',
        () async {
      final fixture = await _MutationFixture.create();
      addTearDown(fixture.dispose);
      final projectFile = File(p.join(fixture.root.path, 'project.json'));
      final expectedProjectRevision = narrativeEventBytesFingerprint(
        await projectFile.readAsBytes(),
      );
      final profile = ProjectPresentationProfile(
        pause: ProjectPausePresentationProfile(
          actions: <ProjectPauseActionProfile>[
            for (final action in defaultProjectPauseActions)
              action.id == ProjectPauseActionId.pokedex
                  ? action.copyWith(label: 'Carnet')
                  : action,
          ],
        ),
        typography: const ProjectTypographyProfile(
          combat: ProjectTypographyRoleProfile(family: 'Battle Mono'),
        ),
        windows: legacyProjectPresentationWindows.copyWith(
          battleStyleId: 'default',
        ),
        layouts: suggestedProjectPresentationLayouts('standard'),
      );

      final result = await fixture.mutations.savePresentation(
        profile,
        fixture.root.path,
        expectedProjectRevision: expectedProjectRevision,
        operationId: 'editor_presentation_labels_01',
      );

      final durable = ProjectManifest.fromJson(
        jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>,
      );
      expect(result.receipt.actionId, 'presentation.update');
      expect(result.receipt.status, AuthoringReceiptStatus.applied);
      expect(
        durable.presentation?.pause?.actions
            ?.firstWhere((action) => action.id == ProjectPauseActionId.pokedex)
            .label,
        'Carnet',
      );
      expect(
        durable.presentation?.windows?.pauseMenuStyleId,
        'pause-menu',
      );
      expect(
        durable.presentation?.windows?.dialogueStyleId,
        'dialogue',
      );
      expect(durable.presentation?.windows?.battleStyleId, 'default');
      expect(
        durable.presentation?.layouts?.battle?.regular.slot,
        ProjectPresentationLayoutSlot.bottomCenter,
      );
      expect(durable.presentation?.typography?.combat?.family, 'Battle Mono');
    });

    test('exports, deletes, and reimports a shareable presentation preset',
        () async {
      final fixture = await _MutationFixture.create();
      addTearDown(fixture.dispose);
      final projectFile = File(p.join(fixture.root.path, 'project.json'));
      final revision = narrativeEventBytesFingerprint(
        await projectFile.readAsBytes(),
      );
      const profile = ProjectPresentationProfile(
        branding: ProjectBrandingProfile(accentColor: '#126E78'),
      );
      await fixture.mutations.savePresentation(
        profile,
        fixture.root.path,
        expectedProjectRevision: revision,
        operationId: 'editor_preset_profile_save',
      );
      final service = ProjectPresentationPresetService(
        mutations: fixture.mutations,
        queries: fixture.queries,
      );
      final pack = p.join(fixture.root.path, 'avelune.pokemapstyle');
      await File(pack).writeAsString('stale preset');

      await service.exportCurrent(
        projectRootPath: fixture.root.path,
        presetId: 'avelune',
        label: 'Avelune',
        description: 'Profil partageable de test.',
        destinationPath: pack,
      );
      var durable = ProjectManifest.fromJson(
        jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>,
      );
      expect(File(pack).lengthSync(), greaterThan(0));
      expect(durable.presentationPresets.single.id, 'avelune');

      await service.delete(
        projectRootPath: fixture.root.path,
        presetId: 'avelune',
      );
      durable = ProjectManifest.fromJson(
        jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>,
      );
      expect(durable.presentationPresets, isEmpty);

      await service.importAndApply(
        projectRootPath: fixture.root.path,
        sourcePath: pack,
      );
      durable = ProjectManifest.fromJson(
        jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>,
      );
      expect(durable.presentationPresets.single.id, 'avelune');
      expect(durable.presentation?.branding.accentColor, '#126E78');
    });

    test('catalogs project-owned presentation media before preset export',
        () async {
      final fixture = await _MutationFixture.create();
      addTearDown(fixture.dispose);
      final projectFile = File(p.join(fixture.root.path, 'project.json'));
      const iconPath = 'assets/presentation/icon.png';
      const licensePath = 'assets/presentation/LICENSE.txt';
      await File(p.join(fixture.root.path, iconPath))
          .create(recursive: true)
          .then((file) => file.writeAsBytes(<int>[
                0x89,
                0x50,
                0x4e,
                0x47,
                0x0d,
                0x0a,
                0x1a,
                0x0a,
              ]));
      await File(p.join(fixture.root.path, licensePath))
          .writeAsString('Redistribution allowed for this fixture.');
      await FileProjectRepository().saveProject(
        fixture.project.copyWith(
          presentation: const ProjectPresentationProfile(
            branding: ProjectBrandingProfile(iconPath: iconPath),
          ),
        ),
        projectFile.path,
      );
      final service = ProjectPresentationPresetService(
        mutations: fixture.mutations,
        queries: fixture.queries,
      );
      final pack = p.join(fixture.root.path, 'media.pokemapstyle');

      await service.exportCurrent(
        projectRootPath: fixture.root.path,
        presetId: 'media',
        label: 'Media',
        description: 'Profil avec media.',
        destinationPath: pack,
        licenses: const <String, String>{iconPath: licensePath},
      );

      final catalog = AssetCatalog.fromJson(
        jsonDecode(
          await File(
            p.join(fixture.root.path, 'assets/.pokemap-assets.json'),
          ).readAsString(),
        ) as Map<String, dynamic>,
      );
      expect(catalog.findByLogicalPath(iconPath), isNotNull);
      expect(catalog.findByLogicalPath(licensePath), isNotNull);
      expect(File(pack).lengthSync(), greaterThan(0));
    });

    test('applies one selected redistribution license to preset media',
        () async {
      final fixture = await _MutationFixture.create();
      addTearDown(fixture.dispose);
      final licenseRoot = await Directory.systemTemp.createTemp(
        'pokemap_preset_license_',
      );
      addTearDown(() => licenseRoot.delete(recursive: true));
      const iconPath = 'assets/presentation/icon.png';
      await File(p.join(fixture.root.path, iconPath))
          .create(recursive: true)
          .then((file) => file.writeAsBytes(<int>[
                0x89,
                0x50,
                0x4e,
                0x47,
                0x0d,
                0x0a,
                0x1a,
                0x0a,
              ]));
      final externalLicense = File(p.join(licenseRoot.path, 'LICENSE.txt'));
      await externalLicense.writeAsString(
        'Redistribution allowed for every media in this preset.',
      );
      await FileProjectRepository().saveProject(
        fixture.project.copyWith(
          presentation: const ProjectPresentationProfile(
            branding: ProjectBrandingProfile(iconPath: iconPath),
          ),
        ),
        p.join(fixture.root.path, 'project.json'),
      );
      final service = ProjectPresentationPresetService(
        mutations: fixture.mutations,
        queries: fixture.queries,
      );
      final pack = p.join(fixture.root.path, 'licensed.pokemapstyle');

      await service.exportCurrent(
        projectRootPath: fixture.root.path,
        presetId: 'licensed',
        label: 'Licensed',
        description: 'Profil avec licence guidée.',
        destinationPath: pack,
        redistributionLicenseSourcePath: externalLicense.path,
      );

      final durable = ProjectManifest.fromJson(
        jsonDecode(
          await File(p.join(fixture.root.path, 'project.json')).readAsString(),
        ) as Map<String, dynamic>,
      );
      final preset = durable.presentationPresets.single;
      expect(preset.assets.single.projectPath, iconPath);
      expect(
        preset.assets.single.licenseProjectPath,
        startsWith('assets/presentation/licenses/'),
      );
      expect(File(pack).lengthSync(), greaterThan(0));
    });

    test('rejects unlicensed preset media before catalog mutation', () async {
      final fixture = await _MutationFixture.create();
      addTearDown(fixture.dispose);
      const iconPath = 'assets/presentation/icon.png';
      await File(p.join(fixture.root.path, iconPath))
          .create(recursive: true)
          .then((file) => file.writeAsBytes(<int>[
                0x89,
                0x50,
                0x4e,
                0x47,
                0x0d,
                0x0a,
                0x1a,
                0x0a,
              ]));
      await FileProjectRepository().saveProject(
        fixture.project.copyWith(
          presentation: const ProjectPresentationProfile(
            branding: ProjectBrandingProfile(iconPath: iconPath),
          ),
        ),
        p.join(fixture.root.path, 'project.json'),
      );
      final service = ProjectPresentationPresetService(
        mutations: fixture.mutations,
        queries: fixture.queries,
      );
      final pack = p.join(fixture.root.path, 'unlicensed.pokemapstyle');

      await expectLater(
        service.exportCurrent(
          projectRootPath: fixture.root.path,
          presetId: 'unlicensed',
          label: 'Unlicensed',
          description: 'Profil incomplet.',
          destinationPath: pack,
        ),
        throwsA(
          isA<ProjectPresentationPresetExportException>().having(
            (error) => error.code,
            'code',
            'presentation.preset.license_required',
          ),
        ),
      );
      expect(
        File(
          p.join(fixture.root.path, 'assets/.pokemap-assets.json'),
        ).existsSync(),
        isFalse,
      );
      expect(File(pack).existsSync(), isFalse);
    });

    test('rejects a non-text redistribution license before catalog mutation',
        () async {
      final fixture = await _MutationFixture.create();
      addTearDown(fixture.dispose);
      final licenseRoot = await Directory.systemTemp.createTemp(
        'pokemap_invalid_preset_license_',
      );
      addTearDown(() => licenseRoot.delete(recursive: true));
      const iconPath = 'assets/presentation/icon.png';
      await File(p.join(fixture.root.path, iconPath))
          .create(recursive: true)
          .then((file) => file.writeAsBytes(<int>[
                0x89,
                0x50,
                0x4e,
                0x47,
                0x0d,
                0x0a,
                0x1a,
                0x0a,
              ]));
      final externalLicense = File(p.join(licenseRoot.path, 'LICENSE.txt'));
      await externalLicense.writeAsBytes(<int>[0xff, 0xfe, 0xfd]);
      await FileProjectRepository().saveProject(
        fixture.project.copyWith(
          presentation: const ProjectPresentationProfile(
            branding: ProjectBrandingProfile(iconPath: iconPath),
          ),
        ),
        p.join(fixture.root.path, 'project.json'),
      );
      final service = ProjectPresentationPresetService(
        mutations: fixture.mutations,
        queries: fixture.queries,
      );

      await expectLater(
        service.exportCurrent(
          projectRootPath: fixture.root.path,
          presetId: 'invalid-license',
          label: 'Invalid license',
          description: 'Profil incomplet.',
          destinationPath: p.join(fixture.root.path, 'invalid.pokemapstyle'),
          redistributionLicenseSourcePath: externalLicense.path,
        ),
        throwsA(
          isA<ProjectPresentationPresetExportException>().having(
            (error) => error.code,
            'code',
            'presentation.preset.license_invalid',
          ),
        ),
      );
      expect(
        File(
          p.join(fixture.root.path, 'assets/.pokemap-assets.json'),
        ).existsSync(),
        isFalse,
      );
    });

    test('rejects an empty redistribution license before catalog mutation',
        () async {
      final fixture = await _MutationFixture.create();
      addTearDown(fixture.dispose);
      final licenseRoot = await Directory.systemTemp.createTemp(
        'pokemap_empty_preset_license_',
      );
      addTearDown(() => licenseRoot.delete(recursive: true));
      const iconPath = 'assets/presentation/icon.png';
      await File(p.join(fixture.root.path, iconPath))
          .create(recursive: true)
          .then((file) => file.writeAsBytes(<int>[
                0x89,
                0x50,
                0x4e,
                0x47,
                0x0d,
                0x0a,
                0x1a,
                0x0a,
              ]));
      final externalLicense = File(p.join(licenseRoot.path, 'LICENSE.txt'));
      await externalLicense.writeAsString('   \n');
      await FileProjectRepository().saveProject(
        fixture.project.copyWith(
          presentation: const ProjectPresentationProfile(
            branding: ProjectBrandingProfile(iconPath: iconPath),
          ),
        ),
        p.join(fixture.root.path, 'project.json'),
      );
      final service = ProjectPresentationPresetService(
        mutations: fixture.mutations,
        queries: fixture.queries,
      );

      await expectLater(
        service.exportCurrent(
          projectRootPath: fixture.root.path,
          presetId: 'empty-license',
          label: 'Empty license',
          description: 'Profil incomplet.',
          destinationPath: p.join(fixture.root.path, 'invalid.pokemapstyle'),
          redistributionLicenseSourcePath: externalLicense.path,
        ),
        throwsA(
          isA<ProjectPresentationPresetExportException>().having(
            (error) => error.code,
            'code',
            'presentation.preset.license_invalid',
          ),
        ),
      );
      expect(
        File(
          p.join(fixture.root.path, 'assets/.pokemap-assets.json'),
        ).existsSync(),
        isFalse,
      );
    });

    test('persists encounter tables through canonical campaign actions',
        () async {
      final fixture = await _MutationFixture.create();
      addTearDown(fixture.dispose);
      final gateway = CanonicalEncounterTablePersistenceGateway(
        mutations: fixture.mutations,
        queries: fixture.queries,
      );
      const table = ProjectEncounterTable(
        id: 'grass_patch',
        name: 'Grass Patch',
        encounterKind: EncounterKind.walk,
        chancePerStep: 0.12,
        entries: <ProjectEncounterEntry>[
          ProjectEncounterEntry(
            speciesId: 'bulbasaur',
            minLevel: 2,
            maxLevel: 4,
            weight: 3,
          ),
          ProjectEncounterEntry(
            speciesId: 'pikachu',
            minLevel: 3,
            maxLevel: 5,
            weight: 1,
          ),
        ],
        tags: <String>['route', 'early-game'],
      );

      final created = await gateway.upsert(
        projectRootPath: fixture.root.path,
        expectedProject: fixture.project,
        table: table,
      );

      expect(
        fixture.mutations.lastAppliedReceipt?.actionId,
        'campaign.encounter_table.upsert',
      );
      expect(created.encounterTables, <ProjectEncounterTable>[table]);
      expect(
        (await FileProjectRepository().loadProject(
          p.join(fixture.root.path, 'project.json'),
        ))
            .encounterTables
            .single,
        table,
      );

      final deleted = await gateway.remove(
        projectRootPath: fixture.root.path,
        expectedProject: created,
        tableId: table.id,
      );

      expect(
        fixture.mutations.lastAppliedReceipt?.actionId,
        'campaign.encounter_table.delete',
      );
      expect(deleted.encounterTables, isEmpty);
      expect(
        (await FileProjectRepository().loadProject(
          p.join(fixture.root.path, 'project.json'),
        ))
            .encounterTables,
        isEmpty,
      );
    });

    test('rejects a stale encounter project without overwriting disk',
        () async {
      final fixture = await _MutationFixture.create();
      addTearDown(fixture.dispose);
      final gateway = CanonicalEncounterTablePersistenceGateway(
        mutations: fixture.mutations,
        queries: fixture.queries,
      );
      const table = ProjectEncounterTable(
        id: 'grass_patch',
        name: 'Grass Patch',
        encounterKind: EncounterKind.walk,
      );
      final created = await gateway.upsert(
        projectRootPath: fixture.root.path,
        expectedProject: fixture.project,
        table: table,
      );
      final projectPath = p.join(fixture.root.path, 'project.json');
      final external = created.copyWith(name: 'External edit');
      await FileProjectRepository().saveProject(external, projectPath);

      await expectLater(
        gateway.upsert(
          projectRootPath: fixture.root.path,
          expectedProject: created,
          table: table.copyWith(name: 'Overwritten'),
        ),
        throwsA(isA<EditorConflictException>()),
      );

      final durable = await FileProjectRepository().loadProject(projectPath);
      expect(durable.name, 'External edit');
      expect(durable.encounterTables.single.name, 'Grass Patch');
    });

    test('plans without writing, applies once, and replays idempotently',
        () async {
      final fixture = await _MutationFixture.create();
      addTearDown(fixture.dispose);
      final before = await File(fixture.mapPath).readAsBytes();
      final updated = fixture.map.copyWith(name: 'Edited through Authoring');

      final plan = await fixture.mutations.plan(
        fixture.root.path,
        actionId: 'map.save',
        parameters: {'map': updated.toJson()},
        idempotencyKey: 'editor_save_plan_01',
      );

      expect(await File(fixture.mapPath).readAsBytes(), before);
      expect(plan.receipt.status, AuthoringReceiptStatus.planned);
      expect(plan.receipt.actionId, 'map.save');

      final applied = await fixture.mutations.apply(
        plan,
        operationId: 'editor_save_apply_01',
      );
      final replay = await fixture.mutations.apply(
        plan,
        operationId: 'editor_save_apply_01',
      );

      expect(replay.receipt.toJson(), applied.receipt.toJson());
      expect(applied.receipt.status, AuthoringReceiptStatus.applied);
      expect((await FileMapRepository().loadMap(fixture.mapPath)).name,
          'Edited through Authoring');
    });

    test('applies Event V2 mode and raw asset repair canonically', () async {
      final fixture = await _MutationFixture.create();
      addTearDown(fixture.dispose);

      final modePlan = await fixture.mutations.plan(
        fixture.root.path,
        actionId: 'event_v2.registry_mode.set',
        parameters: const {'mode': 'dualRead'},
        idempotencyKey: 'editor_event_v2_mode',
      );
      await fixture.mutations.apply(
        modePlan,
        operationId: 'editor_event_v2_mode',
      );
      final persistedProject = await FileProjectRepository().loadProject(
        p.join(fixture.root.path, 'project.json'),
      );
      expect(
        persistedProject.eventRegistry?.mode,
        EventSystemMode.dualRead,
      );

      final rawAsset = File(
        p.join(fixture.root.path, 'assets', 'audio', 'pikachu.ogg'),
      );
      final replacementSource = File(
        p.join(fixture.root.path, 'replacement.ogg'),
      );
      await rawAsset.parent.create(recursive: true);
      final beforeBytes = <int>[0x4f, 0x67, 0x67, 0x53, 0x00, 0x01];
      final afterBytes = <int>[0x4f, 0x67, 0x67, 0x53, 0x00, 0x02];
      await rawAsset.writeAsBytes(beforeBytes);
      await replacementSource.writeAsBytes(afterBytes);
      final expected = await fixture.mutations.stageArtifact(
        fixture.root.path,
        sourcePath: rawAsset.path,
        declaredMediaType: 'audio/ogg',
      );
      final replacement = await fixture.mutations.stageArtifact(
        fixture.root.path,
        sourcePath: replacementSource.path,
        declaredMediaType: 'audio/ogg',
      );
      final rawPlan = await fixture.mutations.plan(
        fixture.root.path,
        actionId: 'asset.raw.replace',
        parameters: {
          'logicalPath': 'assets/audio/pikachu.ogg',
          'expectedArtifactHandle': expected.reference.handle,
          'replacementArtifactHandle': replacement.reference.handle,
        },
        idempotencyKey: 'editor_raw_asset_replace',
      );
      final rawResult = await fixture.mutations.apply(
        rawPlan,
        operationId: 'editor_raw_asset_replace',
      );

      expect(rawResult.receipt.actionId, 'asset.raw.replace');
      expect(await rawAsset.readAsBytes(), afterBytes);
    });

    test('normalizes and merges Smart Tile layers through the canonical API',
        () async {
      final fixture = await _MutationFixture.createSmartTiles();
      addTearDown(fixture.dispose);

      final normalizePlan = await fixture.mutations.plan(
        fixture.root.path,
        actionId: 'smart_tile.layer.normalize',
        parameters: const {
          'mapId': 'm01',
          'layerId': 'terrain',
        },
        idempotencyKey: 'editor_smart_tile_normalize',
      );
      final normalized = await fixture.mutations.apply(
        normalizePlan,
        operationId: 'editor_smart_tile_normalize',
      );
      final mergePlan = await fixture.mutations.plan(
        fixture.root.path,
        actionId: 'smart_tile.layer.merge',
        parameters: const {
          'mapId': 'm01',
          'sourceLayerIds': ['path_target', 'path_source'],
          'targetLayerId': 'path_target',
          'mode': 'union',
          'removeSources': true,
          'conflictPolicy': 'reject',
        },
        idempotencyKey: 'editor_smart_tile_merge',
      );
      final merged = await fixture.mutations.apply(
        mergePlan,
        operationId: 'editor_smart_tile_merge',
      );
      final map = await FileMapRepository().loadMap(fixture.mapPath);
      final target = map.layers[2] as SmartTileLayer;

      expect(normalized.receipt.actionId, 'smart_tile.layer.normalize');
      expect(merged.receipt.actionId, 'smart_tile.layer.merge');
      expect(map.layers.map((layer) => layer.id), [
        'base',
        'terrain',
        'path_target',
        'collisions',
      ]);
      expect(smartTileSemanticCells(target), [0, 1, 0, 1, 1, 1, 0, 1, 0]);
      expect(target.name, 'Target metadata');
      expect(target.isVisible, isFalse);
      expect(target.opacity, 0.5);
      expect(target.layerSeed, 17);
      expect(target.properties, {'keep': 'yes'});
    });

    test('creates updates and deletes reciprocal map connections canonically',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'pmcp_editor_connections_',
      );
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      const project = ProjectManifest(
        name: 'Connection editor parity',
        maps: [
          ProjectMapEntry(
            id: 'alpha',
            name: 'Alpha',
            relativePath: 'maps/alpha.json',
          ),
          ProjectMapEntry(
            id: 'beta',
            name: 'Beta',
            relativePath: 'maps/beta.json',
          ),
        ],
        tilesets: [],
      );
      const alpha = MapData(
        id: 'alpha',
        name: 'Alpha',
        size: GridSize(width: 8, height: 8),
      );
      const beta = MapData(
        id: 'beta',
        name: 'Beta',
        size: GridSize(width: 8, height: 8),
      );
      final projectRepository = FileProjectRepository();
      final mapRepository = FileMapRepository();
      await projectRepository.saveProject(
        project,
        p.join(root.path, 'project.json'),
      );
      await mapRepository.saveMap(
        alpha,
        p.join(root.path, 'maps', 'alpha.json'),
        projectDialogueContext: project,
      );
      await mapRepository.saveMap(
        beta,
        p.join(root.path, 'maps', 'beta.json'),
        projectDialogueContext: project,
      );
      const reader = EditorProjectFileReader();
      final queries = AuthoringQueryAdapter(fileReader: reader);
      final mutations = AuthoringMutationAdapter(
        fileReader: reader,
        queries: queries,
        projectRoots: reader,
      );
      addTearDown(mutations.closeAll);
      addTearDown(queries.closeAll);

      final create = await mutations.plan(
        root.path,
        actionId: 'connection.create_bidirectional_apply',
        parameters: const {
          'mapId': 'alpha',
          'direction': 'east',
          'targetMapId': 'beta',
          'offset': 0,
        },
        idempotencyKey: 'editor_connection_create',
      );
      final created = await mutations.apply(
        create,
        operationId: 'editor_connection_create',
      );

      expect(created.receipt.affectedResources, hasLength(2));
      expect(
        (await mapRepository.loadMap(
          p.join(root.path, 'maps', 'alpha.json'),
        ))
            .connections
            .single,
        const MapConnection(
          direction: MapConnectionDirection.east,
          targetMapId: 'beta',
          offset: 0,
        ),
      );
      expect(
        (await mapRepository.loadMap(
          p.join(root.path, 'maps', 'beta.json'),
        ))
            .connections
            .single,
        const MapConnection(
          direction: MapConnectionDirection.west,
          targetMapId: 'alpha',
          offset: 0,
        ),
      );

      final update = await mutations.plan(
        root.path,
        actionId: 'connection.update_bidirectional_apply',
        parameters: const {
          'mapId': 'alpha',
          'direction': 'east',
          'targetMapId': 'beta',
          'offset': 2,
        },
        idempotencyKey: 'editor_connection_update',
      );
      await mutations.apply(
        update,
        operationId: 'editor_connection_update',
      );
      expect(
        (await mapRepository.loadMap(
          p.join(root.path, 'maps', 'beta.json'),
        ))
            .connections
            .single
            .offset,
        -2,
      );

      final deletion = await mutations.plan(
        root.path,
        actionId: 'connection.delete_bidirectional_apply',
        parameters: const {
          'mapId': 'alpha',
          'direction': 'east',
        },
        idempotencyKey: 'editor_connection_delete',
      );
      final confirmation = await mutations.confirm(deletion);
      await mutations.apply(
        deletion,
        operationId: 'editor_connection_delete',
        confirmationToken: confirmation,
      );
      expect(
        (await mapRepository.loadMap(
          p.join(root.path, 'maps', 'alpha.json'),
        ))
            .connections,
        isEmpty,
      );
      expect(
        (await mapRepository.loadMap(
          p.join(root.path, 'maps', 'beta.json'),
        ))
            .connections,
        isEmpty,
      );
    });

    test('upserts and queries Smart Tile animations through the editor adapter',
        () async {
      final fixture = await _MutationFixture.createSmartTiles();
      addTearDown(fixture.dispose);
      const animation = ProjectSmartTileAnimation(
        id: 'wind',
        name: 'Wind',
        frames: <ProjectSmartTileAnimationFrame>[
          ProjectSmartTileAnimationFrame(
            frame: SmartTileFrameRef(
              atlasId: 'atlas',
              column: 0,
              row: 0,
            ),
            durationMs: 120,
          ),
        ],
      );

      final normalizationPlan = await fixture.mutations.plan(
        fixture.root.path,
        actionId: 'smart_tile.layer.normalize',
        parameters: const <String, Object?>{
          'mapId': 'm01',
          'layerId': 'terrain',
        },
        idempotencyKey: 'editor_smart_tile_animation_preflight',
      );
      await fixture.mutations.apply(
        normalizationPlan,
        operationId: 'editor_smart_tile_animation_preflight',
      );

      final plan = await fixture.mutations.plan(
        fixture.root.path,
        actionId: 'smart_tile.animation.upsert',
        parameters: <String, Object?>{
          'animation': animation.toJson(),
        },
        idempotencyKey: 'editor_smart_tile_animation',
      );
      final applied = await fixture.mutations.apply(
        plan,
        operationId: 'editor_smart_tile_animation',
      );
      final session = await fixture.queries.open(fixture.root.path);
      final queried = session.query(
        AuthoringQueryRequest(
          resourceKind: 'smartTileAnimation',
          operation: AuthoringQueryOperation.list,
        ),
      );
      final items = queried['items']! as List<Object?>;

      expect(applied.receipt.actionId, 'smart_tile.animation.upsert');
      expect(applied.receipt.status, AuthoringReceiptStatus.applied);
      expect(items, hasLength(1));
      expect((items.single! as Map<String, Object?>)['id'], 'wind');
    });

    test('retainOnly retires old mutation plans and preserves the active root',
        () async {
      final first = await _MutationFixture.create();
      final second = await _MutationFixture.create();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      final firstPlan = await first.mutations.plan(
        first.root.path,
        actionId: 'map.save',
        parameters: {
          'map': first.map.copyWith(name: 'Retired plan').toJson(),
        },
        idempotencyKey: 'retired_root_plan',
      );
      final secondPlan = await first.mutations.plan(
        second.root.path,
        actionId: 'map.save',
        parameters: {
          'map': second.map.copyWith(name: 'Retained plan').toJson(),
        },
        idempotencyKey: 'retained_root_plan',
      );
      final activeRoot = await const EditorProjectFileReader()
          .canonicalizeDirectory(second.root.path);

      await first.mutations.retainOnly(activeRoot);

      expect(first.mutations.diagnostics.retainedRoot, activeRoot);
      expect(first.mutations.diagnostics.liveSessions, 1);
      expect(first.mutations.diagnostics.openingSessions, 0);
      expect(first.mutations.diagnostics.retiringSessions, 0);
      expect(first.mutations.diagnostics.activeOperations, 0);
      expect(first.mutations.diagnostics.closeCount, 1);
      await expectLater(
        () => first.mutations.confirm(firstPlan),
        throwsA(isA<EditorAuthoringMutationFailure>()),
      );
      await expectLater(
        () => first.mutations.plan(
          first.root.path,
          actionId: 'map.save',
          parameters: {
            'map': first.map.copyWith(name: 'Forbidden reopen').toJson(),
          },
          idempotencyKey: 'forbidden_reopen',
        ),
        throwsA(
          isA<EditorAuthoringMutationFailure>().having(
            (failure) => failure.original,
            'original',
            isA<EditorAuthoringStaleSessionException>(),
          ),
        ),
      );
      final applied = await first.mutations.apply(
        secondPlan,
        operationId: 'retained_root_apply',
      );
      expect(applied.receipt.status, AuthoringReceiptStatus.applied);
      expect(
        (await FileMapRepository().loadMap(second.mapPath)).name,
        'Retained plan',
      );
    });

    test('retirement waits for an in-flight mutation workflow', () async {
      final fixture = await _MutationFixture.create();
      final retained = await _MutationFixture.create();
      addTearDown(fixture.dispose);
      addTearDown(retained.dispose);
      final reader = _BlockingProjectReader();
      final queries = AuthoringQueryAdapter(fileReader: reader);
      final mutations = AuthoringMutationAdapter(
        fileReader: reader,
        queries: queries,
        projectRoots: reader,
      );
      addTearDown(mutations.closeAll);
      addTearDown(queries.closeAll);
      await mutations.plan(
        fixture.root.path,
        actionId: 'map.save',
        parameters: {
          'map': fixture.map.copyWith(name: 'Lease warmup').toJson(),
        },
        idempotencyKey: 'lease_warmup',
      );
      reader.arm();

      final planning = mutations.plan(
        fixture.root.path,
        actionId: 'map.save',
        parameters: {
          'map': fixture.map.copyWith(name: 'Lease in flight').toJson(),
        },
        idempotencyKey: 'lease_in_flight',
      );
      await reader.entered.future;
      final retainedRoot = await reader.canonicalizeDirectory(
        retained.root.path,
      );
      var retired = false;
      final retiring = mutations.retainOnly(retainedRoot).whenComplete(() {
        retired = true;
      });
      await Future<void>.delayed(Duration.zero);

      expect(retired, isFalse);
      expect(mutations.diagnostics.activeOperations, 1);
      expect(mutations.diagnostics.retiringSessions, 1);

      reader.release();
      await planning;
      await retiring;

      expect(retired, isTrue);
      expect(mutations.diagnostics.activeOperations, 0);
      expect(mutations.diagnostics.retiringSessions, 0);
      expect(mutations.diagnostics.liveSessions, 0);
      expect(mutations.diagnostics.closeCount, 1);
    });

    test('product SaveMapUseCase returns Authoring receipt parity', () async {
      final direct = await _MutationFixture.create();
      final product = await _MutationFixture.create();
      addTearDown(direct.dispose);
      addTearDown(product.dispose);
      final directMap = direct.map.copyWith(name: 'Receipt parity');
      final productMap = product.map.copyWith(name: 'Receipt parity');

      final directPlan = await direct.mutations.plan(
        direct.root.path,
        actionId: 'map.save',
        parameters: {'map': directMap.toJson()},
        idempotencyKey: 'direct_receipt_parity',
      );
      final directResult = await direct.mutations.apply(
        directPlan,
        operationId: 'direct_receipt_parity',
      );

      final legacyDocument =
          await FileMapRepository().loadMapDocument(product.mapPath);
      final useCase = SaveMapUseCase(
        FileMapRepository(),
        authoringMutations: product.mutations,
      );
      final productRevision = await useCase.executeRevisioned(
        productMap,
        product.mapPath,
        expectedRevision: legacyDocument.revision,
        projectDialogueContext: product.project,
      );
      final productReceipt = product.mutations.lastAppliedReceipt;

      expect(productRevision, isNotNull);
      expect(productReceipt, isNotNull);
      expect(
        _stableReceipt(productReceipt!),
        _stableReceipt(directResult.receipt),
      );
    });

    test('saveMap accepts gameplay zones with nested geometry', () async {
      final fixture = await _MutationFixture.create();
      addTearDown(fixture.dispose);
      const zone = MapGameplayZone(
        id: 'zone_port_entry',
        name: 'zone_port_entry',
        kind: GameplayZoneKind.special,
        area: MapRect(
          pos: GridPos(x: 1, y: 0),
          size: GridSize(width: 1, height: 2),
        ),
        special: SpecialZonePayload(
          properties: <String, String>{
            'contractRole': 'navigation_anchor',
            'inert': 'true',
          },
        ),
      );
      final updated = fixture.map.copyWith(
        gameplayZones: const <MapGameplayZone>[zone],
      );
      final baseline =
          await FileMapRepository().loadMapDocument(fixture.mapPath);

      final result = await fixture.mutations.saveMap(
        updated,
        fixture.mapPath,
        expectedMapRevision: baseline.revision,
      );

      expect(result.resourceRevision, isNotNull);
      expect(
        (await FileMapRepository().loadMap(fixture.mapPath)).gameplayZones,
        const <MapGameplayZone>[zone],
      );
    });

    test('saveMap reopens an expired Authoring workspace', () async {
      final clock = _MutableClock(DateTime.utc(2026, 8, 8, 12));
      final fixture = await _MutationFixture.create(
        workspaceHandles: () => WorkspaceHandleStore(
          clock: () => clock.value,
          ttl: const Duration(minutes: 5),
        ),
      );
      addTearDown(fixture.dispose);
      await fixture.mutations.plan(
        fixture.root.path,
        actionId: 'map.save',
        parameters: {
          'map': fixture.map.copyWith(name: 'Warm workspace').toJson(),
        },
        idempotencyKey: 'editor_expired_workspace_warmup',
      );
      final baseline =
          await FileMapRepository().loadMapDocument(fixture.mapPath);
      clock.value = clock.value.add(const Duration(minutes: 6));

      final result = await fixture.mutations.saveMap(
        fixture.map.copyWith(name: 'Saved after expiry'),
        fixture.mapPath,
        expectedMapRevision: baseline.revision,
      );

      expect(result.receipt.status, AuthoringReceiptStatus.applied);
      expect(
        (await FileMapRepository().loadMap(fixture.mapPath)).name,
        'Saved after expiry',
      );
      expect(fixture.mutations.diagnostics.liveSessions, 1);
      expect(fixture.mutations.diagnostics.closeCount, 1);
    });

    test('stale external bytes are visible and never overwritten', () async {
      final fixture = await _MutationFixture.create();
      addTearDown(fixture.dispose);
      final baseline =
          await FileMapRepository().loadMapDocument(fixture.mapPath);
      final local = fixture.map.copyWith(name: 'Local edit');
      await FileMapRepository().saveMap(
        fixture.map.copyWith(name: 'External edit'),
        fixture.mapPath,
        projectDialogueContext: fixture.project,
      );
      final useCase = SaveMapUseCase(
        FileMapRepository(),
        authoringMutations: fixture.mutations,
      );

      await expectLater(
        () => useCase.executeRevisioned(
          local,
          fixture.mapPath,
          expectedRevision: baseline.revision,
          projectDialogueContext: fixture.project,
        ),
        throwsA(isA<EditorConflictException>()),
      );
      expect((await FileMapRepository().loadMap(fixture.mapPath)).name,
          'External edit');
    });

    test('undo is a forward history receipt and restores exact map semantics',
        () async {
      final fixture = await _MutationFixture.create();
      addTearDown(fixture.dispose);
      final plan = await fixture.mutations.plan(
        fixture.root.path,
        actionId: 'map.save',
        parameters: {
          'map': fixture.map.copyWith(name: 'Undo me').toJson(),
        },
        idempotencyKey: 'editor_history_apply_01',
      );
      final applied = await fixture.mutations.apply(
        plan,
        operationId: 'editor_history_apply_01',
      );

      final undone = await fixture.mutations.undo(
        fixture.root.path,
        entryId: applied.receipt.receiptId,
        idempotencyKey: 'editor_history_undo_01',
      );

      expect(undone.receipt.actionId, 'history.undo');
      expect((await FileMapRepository().loadMap(fixture.mapPath)).toJson(),
          fixture.map.toJson());
    });

    test('receipt presenter keeps domain codes and confirmations actionable',
        () {
      const presenter = EditorReceiptPresenter();
      final conflict = presenter.failure(
        const EditorAuthoringMutationFailure(
          code: 'transaction.revision_conflict',
          message: 'The project changed.',
          remediation: ['Reload the project.'],
        ),
      );
      final confirmation = presenter.failure(
        const EditorAuthoringMutationFailure(
          code: 'confirmation.required',
          message: 'Confirmation required.',
        ),
      );

      expect(conflict.code, 'transaction.revision_conflict');
      expect(conflict.isConflict, isTrue);
      expect(conflict.message.toLowerCase(), contains('recharg'));
      expect(confirmation.requiresConfirmation, isTrue);
    });
  });
}
Map<String, Object?> _stableReceipt(AuthoringReceipt receipt) => {
      'actionId': receipt.actionId,
      'actionVersion': receipt.actionVersion,
      'status': receipt.status.wireName,
      'diff': receipt.diff.toJson(),
      'affectedResources': [
        for (final resource in receipt.affectedResources)
          {'kind': resource.kind, 'id': resource.id},
      ],
    };

final class _BlockingProjectReader
    implements ProjectFileReader, EditorProjectRootLocator {
  static const _delegate = EditorProjectFileReader();
  Completer<void>? _entered;
  Completer<void>? _release;
  var _armed = false;

  Completer<void> get entered => _entered!;

  void arm() {
    _armed = true;
    _entered = Completer<void>();
    _release = Completer<void>();
  }

  void release() => _release!.complete();

  @override
  Future<String> canonicalizeDirectory(String path) =>
      _delegate.canonicalizeDirectory(path);

  @override
  Future<String> locateForResource(String resourcePath) =>
      _delegate.locateForResource(resourcePath);

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) async {
    if (_armed) {
      _armed = false;
      _entered!.complete();
      await _release!.future;
    }
    return _delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }
}

final class _CountingEditorReader
    implements
        ProjectFileReader,
        ProjectResourceIdentityReader,
        ProjectSnapshotCacheIdentityReader,
        EditorProjectRootLocator {
  static const _files = LocalProjectFileReader();
  static const _roots = EditorProjectFileReader();
  var byteReads = 0;

  void resetCounts() => byteReads = 0;

  @override
  Future<String> canonicalizeDirectory(String path) =>
      _files.canonicalizeDirectory(path);

  @override
  Future<ProjectResourceIdentity?> readIdentity({
    required String projectRoot,
    required String relativePath,
  }) =>
      _files.readIdentity(
        projectRoot: projectRoot,
        relativePath: relativePath,
      );

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) {
    byteReads += 1;
    return _files.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }

  @override
  Future<String> locateForResource(String resourcePath) =>
      _roots.locateForResource(resourcePath);
}

final class _MutationFixture {
  _MutationFixture({
    required this.root,
    required this.project,
    required this.map,
    required this.queries,
    required this.mutations,
    required this.countingReader,
  });

  static Future<_MutationFixture> create({
    WorkspaceHandleStore Function()? workspaceHandles,
    bool enableSnapshotCache = false,
  }) async {
    final root = await Directory.systemTemp.createTemp('pmcp081_editor_');
    const project = ProjectManifest(
      name: 'PMCP-081 editor fixture',
      maps: [
        ProjectMapEntry(
          id: 'alpha',
          name: 'Alpha',
          relativePath: 'maps/alpha.json',
        ),
      ],
      tilesets: [],
    );
    const map = MapData(
      id: 'alpha',
      name: 'Alpha',
      size: GridSize(width: 2, height: 2),
      version: ProjectVersion.v6,
      visualStack: MapVisualStackConfig.canonicalV1,
      layers: [
        MapLayer.tile(
          id: 'l_base',
          name: 'Base',
          cells: [0, 0, 0, 0],
        ),
        MapLayer.collision(
          id: 'l_collisions',
          name: 'Collisions',
          collisions: [false, false, false, false],
        ),
      ],
    );
    await FileProjectRepository()
        .saveProject(project, p.join(root.path, 'project.json'));
    await FileMapRepository().saveMap(
      map,
      p.join(root.path, 'maps', 'alpha.json'),
      projectDialogueContext: project,
    );
    final countingReader = enableSnapshotCache ? _CountingEditorReader() : null;
    late final ProjectFileReader reader;
    late final EditorProjectRootLocator roots;
    if (countingReader == null) {
      reader = const EditorProjectFileReader();
      roots = const EditorProjectFileReader();
    } else {
      reader = countingReader;
      roots = countingReader;
    }
    final fingerprintCache = ProjectSnapshotFingerprintCache();
    final snapshotCache = ProjectSnapshotCache();
    final queries = AuthoringQueryAdapter(
      fileReader: reader,
      fingerprintCache: fingerprintCache,
      snapshotCache: snapshotCache,
    );
    final mutations = AuthoringMutationAdapter(
      fileReader: reader,
      queries: queries,
      projectRoots: roots,
      workspaceHandles: workspaceHandles,
      fingerprintCache: fingerprintCache,
      snapshotCache: snapshotCache,
    );
    return _MutationFixture(
      root: root,
      project: project,
      map: map,
      queries: queries,
      mutations: mutations,
      countingReader: countingReader,
    );
  }

  static Future<_MutationFixture> createSmartTiles() async {
    final root = await Directory.systemTemp.createTemp('pmcp_smart_editor_');
    final project = ProjectManifest(
      name: 'Smart Tile editor fixture',
      version: ProjectVersion.v6,
      maps: const [
        ProjectMapEntry(
          id: 'm01',
          name: 'M01',
          relativePath: 'maps/m01.json',
        ),
      ],
      tilesets: const [
        ProjectTilesetEntry(
          id: 'tileset',
          name: 'Tileset',
          relativePath: 'assets/tileset.png',
        ),
      ],
      smartTileCatalog: ProjectSmartTileCatalog(
        atlases: const [
          ProjectSmartTileAtlas(
            id: 'atlas',
            name: 'Atlas',
            tilesetId: 'tileset',
            columns: 1,
            rows: 1,
          ),
        ],
        materials: const [
          ProjectSmartTileMaterial(
            id: 'grass',
            name: 'Grass',
            connectionGroupId: 'ground',
          ),
          ProjectSmartTileMaterial(
            id: 'smart_material_empty',
            name: 'Legacy empty',
            connectionGroupId: 'empty',
            isEmpty: true,
          ),
          ProjectSmartTileMaterial(
            id: 'dirt',
            name: 'Dirt',
            connectionGroupId: 'path',
          ),
        ],
        presets: const [
          ProjectSmartTilePreset(
            id: 'terrain',
            name: 'Terrain',
            usage: SmartTileUsage.terrain,
            topology: SmartTileTopology.cardinal4,
            templateHint: SmartTileTemplateHint.edge16,
            coveragePolicy: SmartTileCoveragePolicy.complete,
            coverageProfile: SmartTileCoverageProfile(
              mode: SmartTileCoverageMode.template,
            ),
            transformPolicy: SmartTileTransformPolicy(),
            defaultMaterialId: 'grass',
            allowedMaterialIds: ['grass'],
          ),
          ProjectSmartTilePreset(
            id: 'path',
            name: 'Path',
            usage: SmartTileUsage.path,
            topology: SmartTileTopology.cardinal4,
            templateHint: SmartTileTemplateHint.edge16,
            coveragePolicy: SmartTileCoveragePolicy.complete,
            coverageProfile: SmartTileCoverageProfile(
              mode: SmartTileCoverageMode.template,
            ),
            transformPolicy: SmartTileTransformPolicy(),
            defaultMaterialId: 'dirt',
            allowedMaterialIds: ['dirt'],
          ),
        ],
      ),
    );
    const map = MapData(
      id: 'm01',
      name: 'M01',
      size: GridSize(width: 3, height: 3),
      version: ProjectVersion.v6,
      visualStack: MapVisualStackConfig.canonicalV1,
      layers: [
        MapLayer.tile(
          id: 'base',
          name: 'Base',
          cells: [0, 0, 0, 0, 0, 0, 0, 0, 0],
        ),
        MapLayer.smartTile(
          id: 'terrain',
          name: 'Terrain',
          presetId: 'terrain',
          usage: SmartTileUsage.terrain,
          materialPalette: ['', 'grass', 'smart_material_empty'],
          field: SmartTileField.cell(
            semanticCells: [1, 1, 1, 1, 1, 1, 1, 1, 1],
          ),
        ),
        MapLayer.smartTile(
          id: 'path_target',
          name: 'Target metadata',
          isVisible: false,
          opacity: 0.5,
          presetId: 'path',
          usage: SmartTileUsage.path,
          materialPalette: ['', 'dirt'],
          field: SmartTileField.cell(
            semanticCells: [0, 0, 0, 1, 1, 1, 0, 0, 0],
          ),
          layerSeed: 17,
          properties: {'keep': 'yes'},
        ),
        MapLayer.smartTile(
          id: 'path_source',
          name: 'Source',
          presetId: 'path',
          usage: SmartTileUsage.path,
          materialPalette: ['', 'dirt'],
          field: SmartTileField.cell(
            semanticCells: [0, 1, 0, 0, 1, 0, 0, 1, 0],
          ),
        ),
        MapLayer.collision(
          id: 'collisions',
          name: 'Collisions',
          collisions: [
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false
          ],
        ),
      ],
    );
    await Directory(p.join(root.path, 'maps')).create(recursive: true);
    await File(p.join(root.path, 'project.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(project.toJson()),
      flush: true,
    );
    await File(p.join(root.path, 'maps', 'm01.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(map.toJson()),
      flush: true,
    );
    const reader = EditorProjectFileReader();
    final queries = AuthoringQueryAdapter(fileReader: reader);
    final mutations = AuthoringMutationAdapter(
      fileReader: reader,
      queries: queries,
      projectRoots: reader,
    );
    return _MutationFixture(
      root: root,
      project: project,
      map: map,
      queries: queries,
      mutations: mutations,
      countingReader: null,
    );
  }

  final Directory root;
  final ProjectManifest project;
  final MapData map;
  final AuthoringQueryAdapter queries;
  final AuthoringMutationAdapter mutations;
  final _CountingEditorReader? countingReader;

  String get mapPath => p.join(root.path, project.maps.single.relativePath);

  Future<void> dispose() async {
    await mutations.closeAll();
    await queries.closeAll();
    if (await root.exists()) await root.delete(recursive: true);
  }
}

final class _MutableClock {
  _MutableClock(this.value);

  DateTime value;
}
