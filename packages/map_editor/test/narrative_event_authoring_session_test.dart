import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_registry_persistence_use_cases.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_registry_persistence.dart';
import 'package:path/path.dart' as p;
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';

import 'support/event_registry_persistence_fixtures.dart';

void main() {
  test('narrative and durable readers retain transformed geometry', () async {
    final fixture = await createPersistenceFixture();
    addTearDown(fixture.dispose);
    final manifest =
        ProjectManifest.fromJson(
          jsonDecode(await File(fixture.projectPath).readAsString())
              as Map<String, dynamic>,
        ).copyWith(
          elements: const [
            ProjectElementEntry(
              id: 'prop',
              name: 'Prop',
              tilesetId: 'tiles',
              categoryId: 'decor',
              frames: [
                TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
              ],
            ),
          ],
          tilesets: const [
            ProjectTilesetEntry(
              id: 'tiles',
              name: 'Tiles',
              relativePath: 'tiles.png',
            ),
          ],
          elementCategories: const [
            ProjectElementCategory(id: 'decor', name: 'Decor'),
          ],
        );
    await File(
      fixture.projectPath,
    ).writeAsString(jsonEncode(manifest.toJson()));
    final map = MapData(
      id: 'map_a',
      name: 'Map',
      size: const GridSize(width: 4, height: 4),
      layers: [
        MapLayer.tile(id: 'decor', name: 'Decor', cells: List.filled(16, 0)),
      ],
      placedElements: const [
        MapPlacedElement(
          id: 'placed',
          elementId: 'prop',
          layerId: 'decor',
          pos: GridPos(x: 1, y: 1),
          pixelOffset: PixelOffset(x: 15, y: 2),
          pixelSize: PixelSize(width: 5, height: 7),
          quarterTurns: 1,
          properties: {
            pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored,
          },
        ),
      ],
    );
    final path = p.join(fixture.root.path, 'maps', 'map_a.json');
    await File(path).writeAsString(jsonEncode(map.toJson()));
    final bytes = await File(path).readAsBytes();
    final session = await NarrativeEventAuthoringSession.prepare(
      fixture.projectPath,
    );
    expect(session.mapPaths.keys, contains('map_a'));
    final document = await FileMapRepository().loadDurableMapDocument(path);
    expect(document.map, map);
    expect(await File(path).readAsBytes(), bytes);
    final diskMap = map.copyWith(placedElements: [map.placedElements.single.copyWith(pixelOffset: const PixelOffset(x: 1, y: 2))]);
    await File(path).writeAsString(jsonEncode(diskMap.toJson()));
    final diskBytes = await File(path).readAsBytes();
    final draftJson = map.toJson();
    final settingsDraftUseCase = UpdateProjectSettingsUseCase(FileProjectRepository(), FileMapRepository());
    final unchangedProjectBytes = await File(fixture.projectPath).readAsBytes();
    await expectLater(settingsDraftUseCase.execute(ProjectFileSystem(fixture.root.path), manifest,
      name: manifest.name, settings: manifest.settings.copyWith(tileWidth: 8), activeMap: map),
      throwsA(isA<ValidationException>()));
    expect(await File(fixture.projectPath).readAsBytes(), unchangedProjectBytes);
    expect(await File(path).readAsBytes(), diskBytes);
    expect(map.toJson(), draftJson);
    await File(path).writeAsBytes(bytes);
    final projectBytes = await File(fixture.projectPath).readAsBytes();
    final settingsUseCase = UpdateProjectSettingsUseCase(FileProjectRepository(), FileMapRepository());
    final workspace = ProjectFileSystem(fixture.root.path);
    await expectLater(settingsUseCase.execute(workspace, manifest, name: manifest.name,
      settings: manifest.settings.copyWith(tileWidth: 8)),
      throwsA(isA<ValidationException>().having((e) => e.message, 'map and decor', allOf(contains('map_a'), contains('placed')))));
    expect(await File(fixture.projectPath).readAsBytes(), projectBytes);
    expect(await File(path).readAsBytes(), bytes);
    final changed = await settingsUseCase.execute(workspace, manifest, name: manifest.name,
      settings: manifest.settings.copyWith(tileHeight: 8));
    expect(changed.settings.tileHeight, 8);
    expect(await File(path).readAsBytes(), bytes);
    final displayOnly = await settingsUseCase.execute(workspace, changed, name: changed.name,
      settings: changed.settings.copyWith(displayScale: 2));
    expect(displayOnly.settings.displayScale, 2);
    expect(await File(path).readAsBytes(), bytes);
  });
  group('NS-EVENT-V2 Phase E-bis-A authoring session', () {
    test(
      'attests an absent registry and every map from exact disk bytes',
      () async {
        final fixture = await createPersistenceFixture();
        addTearDown(fixture.dispose);

        final session =
            await const PrepareNarrativeEventAuthoringSessionUseCase()(
              fixture.projectPath,
            );
        final mapPath = p.join(fixture.root.path, 'maps', 'map_a.json');
        final mapBytes = await File(mapPath).readAsBytes();

        expect(
          session.projectPath,
          await File(fixture.projectPath).resolveSymbolicLinks(),
        );
        expect(session.projectRevision, fixture.revision);
        expect(session.context.registryOrNull, isNull);
        expect(session.mapManifestPaths, {
          'map_a': p.join(p.dirname(session.projectPath), 'maps', 'map_a.json'),
        });
        expect(session.mapPaths, {
          'map_a': await File(mapPath).resolveSymbolicLinks(),
        });
        expect(session.mapByteHashes, {
          'map_a': narrativeEventBytesFingerprint(mapBytes),
        });
        expect(session.manifestSemanticHash, session.context.manifestHash);
        expect(session.catalogFingerprint, startsWith('sha256:'));
        expect(session.sourceIndexFingerprint, startsWith('sha256:'));
      },
    );

    test(
      'attests an existing registry and exposes immutable collections',
      () async {
        final registry = persistenceRegistry();
        final fixture = await createPersistenceFixture(registry: registry);
        addTearDown(fixture.dispose);

        final session = await NarrativeEventAuthoringSession.prepare(
          fixture.projectPath,
        );

        expect(session.context.registryOrNull, registry);
        expect(
          () => session.mapManifestPaths['forged'] = fixture.projectPath,
          throwsUnsupportedError,
        );
        expect(
          () => session.mapPaths['forged'] = fixture.projectPath,
          throwsUnsupportedError,
        );
        expect(
          () => session.mapByteHashes['map_a'] = 'sha256:forged',
          throwsUnsupportedError,
        );
      },
    );

    test('rejects a missing map before producing a session', () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      await File(p.join(fixture.root.path, 'maps', 'map_a.json')).delete();

      await expectLater(
        NarrativeEventAuthoringSession.prepare(fixture.projectPath),
        throwsA(isA<NarrativeEventAuthoringSessionException>()),
      );
    });

    test('rejects an invalid map before producing a session', () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      await File(
        p.join(fixture.root.path, 'maps', 'map_a.json'),
      ).writeAsString('{"invalid":true}', flush: true);

      await expectLater(
        NarrativeEventAuthoringSession.prepare(fixture.projectPath),
        throwsA(isA<NarrativeEventAuthoringSessionException>()),
      );
    });

    test('rejects duplicate manifest map identities', () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      final root = await fixture.readRoot();
      root['maps'] = [
        ...(root['maps']! as List),
        {
          'id': 'map_a',
          'name': 'Map A duplicate',
          'relativePath': 'maps/map_a.json',
          'role': 'exterior',
          'sortOrder': 1,
        },
      ];
      await File(fixture.projectPath).writeAsString(
        const JsonEncoder.withIndent('  ').convert(root),
        flush: true,
      );

      await expectLater(
        NarrativeEventAuthoringSession.prepare(fixture.projectPath),
        throwsA(isA<NarrativeEventAuthoringSessionException>()),
      );
    });

    test('rejects an invalid manifest and an unsupported registry', () async {
      final invalid = await createPersistenceFixture();
      addTearDown(invalid.dispose);
      await File(invalid.projectPath).writeAsString('[]', flush: true);
      await expectLater(
        NarrativeEventAuthoringSession.prepare(invalid.projectPath),
        throwsA(isA<NarrativeEventAuthoringSessionException>()),
      );

      final unsupported = await createPersistenceFixture();
      addTearDown(unsupported.dispose);
      final root = await unsupported.readRoot();
      root['eventRegistry'] = {
        'schemaVersion': 99,
        'mode': 'legacyOnly',
        'records': <Object?>[],
        'legacyClaims': <Object?>[],
      };
      await File(unsupported.projectPath).writeAsString(
        const JsonEncoder.withIndent('  ').convert(root),
        flush: true,
      );
      await expectLater(
        NarrativeEventAuthoringSession.prepare(unsupported.projectPath),
        throwsA(isA<NarrativeEventAuthoringSessionException>()),
      );
    });

    test(
      'builds a persistence request only from the attested session',
      () async {
        final fixture = await createPersistenceFixture();
        addTearDown(fixture.dispose);
        final session = await NarrativeEventAuthoringSession.prepare(
          fixture.projectPath,
        );
        final next = persistenceRegistry();
        final result = persistenceAuthoringResult(
          previousRegistry: null,
          nextRegistry: next,
          expectedRevision: session.projectRevision,
          context: session.context,
        );

        final request = NarrativeEventRegistryWriteRequest.fromAuthoringSession(
          session: session,
          operationId: 'e_bis_attested',
          result: result,
        );

        expect(request.session, same(session));
        expect(request.projectPath, session.projectPath);
        expect(request.expectedProjectRevision, session.projectRevision);
      },
    );

    test('rejects a result built from a caller-forged catalog', () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      final session = await NarrativeEventAuthoringSession.prepare(
        fixture.projectPath,
      );
      final realCatalog = session.context.catalog;
      final forgedSource = NarrativeEventSourceRef.entityInteract(
        'map_a',
        'forged_entity',
      );
      final forgedCatalog = NarrativeEventProjectCatalog(
        manifestHash: realCatalog.manifestHash,
        mapHashes: realCatalog.mapHashes,
        spatialSources: NarrativeSpatialEventSourceCatalog(
          options: [
            NarrativeSpatialEventSourceOption(
              source: forgedSource,
              humanLabel: 'Entité forgée',
              humanDescription: 'Entité forgée',
              mapId: 'map_a',
              mapLabel: 'Map A',
              sourceTypeLabel: 'Interaction',
              availability: NarrativeSpatialEventSourceAvailability.selectable,
              origin: NarrativeSpatialEventSourceOrigin.canonical,
              debugTechnicalLabel: 'entityInteract:map_a:forged_entity',
              geometry:
                  const NarrativeSpatialSourceGeometrySummary.unavailable(),
              ownerKind: NarrativeSpatialEventSourceOwnerKind.entity,
              ownerId: 'forged_entity',
            ),
          ],
          diagnostics: const [],
        ),
        outcomeSources: realCatalog.outcomeSources,
        scenes: realCatalog.scenes,
        facts: realCatalog.facts,
        events: realCatalog.events,
        diagnostics: realCatalog.diagnostics,
      );
      final forgedContext = NarrativeEventAuthoringContext(
        registryState: EventRegistryDecodeResult.absent(),
        revision: session.projectRevision,
        catalog: forgedCatalog,
        sourceIndex: buildNarrativeEventSourceIndex(const []),
        manifestHash: forgedCatalog.manifestHash,
        mapHashes: forgedCatalog.mapHashes,
      );
      final forgedResult = createNarrativeEventDraft(
        context: forgedContext,
        expectedRevision: session.projectRevision,
        name: 'Forged',
        initialSource: forgedSource,
        idGenerator: NarrativeEventIdGenerator(
          rawUuidFactory: () => persistenceEventA.substring(4),
        ),
      );

      expect(
        () => NarrativeEventRegistryWriteRequest.fromAuthoringSession(
          session: session,
          operationId: 'e_bis_forged',
          result: forgedResult,
        ),
        throwsArgumentError,
      );
    });

    test('rejects an authoring context with a forged source index', () async {
      final current = persistenceRegistry(
        records: [persistenceConfigured(enabled: true)],
      );
      final fixture = await createPersistenceFixture(registry: current);
      addTearDown(fixture.dispose);
      final session = fixture.session;
      final forgedContext = NarrativeEventAuthoringContext(
        registryState: EventRegistryDecodeResult.decoded(current),
        revision: session.projectRevision,
        catalog: session.context.catalog,
        sourceIndex: buildNarrativeEventSourceIndex(const []),
        manifestHash: session.context.manifestHash,
        mapHashes: session.context.mapHashes,
      );

      final result = renameNarrativeEvent(
        context: forgedContext,
        expectedRevision: session.projectRevision,
        eventId: persistenceEventA,
        name: 'Forged source index',
      );

      expect(result.status, NarrativeEventAuthoringStatus.rejected);
      expect(result.diagnostics.single.code, 'staleCatalog');
      expect(
        () => NarrativeEventRegistryWriteRequest.fromAuthoringSession(
          session: session,
          operationId: 'e_bis_forged_source_index',
          result: result,
        ),
        throwsArgumentError,
      );
    });

    test(
      'fresh disk replay rejects a stale session without artifacts',
      () async {
        final fixture = await createPersistenceFixture();
        addTearDown(fixture.dispose);
        final request = persistenceRequest(
          fixture: fixture,
          operationId: 'e_bis_fresh_replay',
          previousRegistry: null,
          nextRegistry: persistenceRegistry(),
        );
        final mapPath = fixture.session.mapPaths['map_a']!;
        final map = decodeValidatedNarrativeEventAuthoringMap(
          await File(mapPath).readAsBytes(),
          mapPath,
        );
        await File(
          mapPath,
        ).writeAsString(jsonEncode(map.toJson()), flush: true);

        final result = await NarrativeEventRegistryPersistence().write(request);

        expect(
          result.status,
          NarrativeEventRegistryPersistenceStatus.staleAuthoringSnapshot,
        );
        expect(result.code, 'staleMapRevision');
        expect(
          await File(
            narrativeEventRegistryJournalPath(
              fixture.projectPath,
              'e_bis_fresh_replay',
            ),
          ).exists(),
          isFalse,
        );
        final artifactNames = await fixture.root
            .list()
            .map((entry) => p.basename(entry.path))
            .where((name) => name.contains('e_bis_fresh_replay'))
            .toList();
        expect(artifactNames, isEmpty);
      },
    );
  });
}
