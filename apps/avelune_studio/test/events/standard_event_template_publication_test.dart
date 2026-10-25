import 'dart:io';
import 'dart:convert';

import 'package:avelune_studio/features/events/data/local_event_adapter.dart';
import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_workshop.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart'
    show
        AuthoringPerformanceObserver,
        AuthoringPerformanceSpan,
        AuthoringPerformanceCounterName;
import 'package:map_core/map_core.dart';

import '../support/event_backend_fixture.dart';
import '../support/ui06_scene_fixture.dart';

void main() {
  late EventBackendFixture fixture;

  setUp(() async {
    fixture = await EventBackendFixture.create();
    final initial = fixture.source.manifest;
    final registry = initial.eventRegistry!;
    await File('${fixture.source.directory.path}/project.json').writeAsString(
      jsonEncode(
        initial
            .copyWith(
              eventRegistry: NarrativeEventRegistry(
                schemaVersion: registry.schemaVersion,
                mode: EventSystemMode.v2Only,
                records: registry.records,
                legacyClaims: registry.legacyClaims,
              ),
            )
            .toJson(),
      ),
    );
    final project = await fixture.source.maps.loadProject(
      fixture.source.session,
    );
    final base = await fixture.source.maps.loadMap(
      fixture.source.session,
      project.maps.first,
    );
    await fixture.source.maps.saveMap(
      fixture.source.session,
      base,
      base.map.copyWith(
        entities: [
          ...base.map.entities,
          const MapEntity(
            id: 'template_a',
            name: 'Premier guide',
            kind: MapEntityKind.custom,
            pos: GridPos(x: 1, y: 1),
          ),
          const MapEntity(
            id: 'template_b',
            name: 'Deuxième guide',
            kind: MapEntityKind.custom,
            pos: GridPos(x: 2, y: 1),
          ),
        ],
      ),
    );
  });
  tearDown(() => fixture.dispose());

  StandardEventTemplateSpec spec(
    ProjectManifest project, {
    String owner = 'template_a',
    String? alternate,
  }) => StandardEventTemplateSpec(
    kind: StandardEventTemplateKind.conditionalNpc,
    mapId: project.maps.first.id,
    entityId: owner,
    name: 'Guide $owner',
    parameters: {
      'factId': Ui06SceneFixture.passFactId,
      'characterId': project.characters.first.id,
      'dialogueId': 'station_welcome',
      'alternateDialogueId': alternate ?? 'station_agreement',
    },
  );

  test(
    'guided controller refreshes the open map and its linked event together',
    () async {
      final project = await fixture.source.maps.loadProject(
        fixture.source.session,
      );
      final base = await fixture.source.maps.loadMap(
        fixture.source.session,
        project.maps.first,
      );
      fixture.workspace.project = project;
      fixture.workspace.active!.acceptCatalogContent(base);
      final controller = fixture.attach();
      expect(await controller.prepare(), isTrue);
      expect(
        await controller.publishTemplate(spec(project)),
        isTrue,
        reason: controller.error,
      );
      expect(
        readStandardEventTemplate(
          project: fixture.workspace.project!,
          map: fixture.workspace.active!.current,
          entityId: 'template_a',
        ),
        isNotNull,
      );
      expect(fixture.workspace.active!.dirty, isFalse);
      expect(
        controller.active!.definitionOrNull!.source,
        NarrativeEventSourceRef.entityInteract(base.mapId, 'template_a'),
      );
      expect(controller.busy, isFalse);
    },
  );

  test(
    'guided controller refuses a dirty map without erasing its draft',
    () async {
      final project = await fixture.source.maps.loadProject(
        fixture.source.session,
      );
      final base = await fixture.source.maps.loadMap(
        fixture.source.session,
        project.maps.first,
      );
      fixture.workspace.project = project;
      final document = fixture.workspace.active!;
      document.acceptCatalogContent(base);
      final draft = document.current.copyWith(name: 'Saisie non enregistrée');
      document.commit(draft);
      final controller = fixture.attach();
      expect(await controller.prepare(), isTrue);
      expect(await controller.publishTemplate(spec(project)), isFalse);
      expect(document.current, draft);
      expect(document.dirty, isTrue);
      expect((await fixture.readFresh()).eventRegistry, project.eventRegistry);
      expect(controller.busy, isFalse);
    },
  );

  test(
    'guided scene forking preserves locks on the previously generated scene',
    () async {
      final project = await fixture.readFresh();
      final base = await fixture.source.maps.loadMap(
        fixture.source.session,
        project.maps.first,
      );
      fixture.workspace.project = project;
      fixture.workspace.active!.acceptCatalogContent(base);
      final controller = fixture.attach();
      expect(await controller.prepare(), isTrue);
      expect(await controller.publishTemplate(spec(project)), isTrue);
      final oldSceneId = controller.active!.definitionOrNull!.sceneId;
      fixture.narrative.sceneAccessProblem = (id) =>
          id == oldSceneId ? 'La scène précédente possède un brouillon.' : null;
      final before = fixture.workspace.active!.current;
      expect(
        await controller.publishTemplate(
          spec(fixture.workspace.project!, alternate: 'station_refusal'),
        ),
        isFalse,
      );
      expect(controller.error, contains('brouillon'));
      expect(fixture.workspace.active!.current, before);
    },
  );

  test('one semantic publication saves map, pages, scenes and cold reopens for editing', () async {
    var project = await fixture.readFresh();
    var base = await fixture.source.maps.loadMap(
      fixture.source.session,
      project.maps.first,
    );
    final first = await fixture.port.publishTemplate(
      base: base,
      spec: spec(project),
      project: project,
      maps: [base.map],
    );
    expect(
      first.changedPaths,
      containsAll(['project.json', project.maps.first.relativePath]),
    );
    final freshPort = LocalMapWorkspaceAdapter();
    project = await freshPort.loadProject(fixture.source.session);
    base = await freshPort.loadMap(fixture.source.session, project.maps.first);
    expect(
      readStandardEventTemplate(
        project: project,
        map: base.map,
        entityId: 'template_a',
      )!.parameters['alternateDialogueId'],
      'station_agreement',
    );
    final firstIds = first.manifest.eventRegistry!.records
        .map((record) => record.id)
        .toSet();
    final second = await fixture.port.publishTemplate(
      base: base,
      spec: spec(project, alternate: 'station_refusal'),
      project: project,
      maps: [base.map],
    );
    expect(
      second.manifest.eventRegistry!.records.map((record) => record.id).toSet(),
      firstIds,
    );
    expect(
      readStandardEventTemplate(
        project: second.manifest,
        map: second.savedMap,
        entityId: 'template_a',
      )!.parameters['alternateDialogueId'],
      'station_refusal',
    );
    expect(
      second.manifest.scenes
          .where((scene) => scene.id == Ui06SceneFixture.sceneId)
          .single,
      Ui06SceneFixture.buildScene(),
    );
  });

  for (final workingCatalog in [false, true]) {
    test(
      '${workingCatalog ? 'working' : 'native'} guided publication saves and edits without unrelated map files',
      () async {
        const unrelatedCount = int.fromEnvironment(
          'AVELUNE_GUIDED_UNRELATED_COUNT',
          defaultValue: 1,
        );
        final initial = await fixture.readFresh();
        final registry = initial.eventRegistry!;
        final project = initial.copyWith(
          settings: ProjectSettings.fromJson({
            ...initial.settings.toJson(),
            'defaultPlayerCharacterId': 'unrelated_hero',
          }),
          newGame: ProjectNewGameConfig(
            enabled: true,
            startMapId: initial.maps.first.id,
            playerAvatarCharacterIds: const ['unrelated_hero'],
            initialFactValues: {
              for (var index = 0; index < unrelatedCount; index++)
                'unrelated_fact_$index': const NarrativeValue.boolean(false),
            },
          ),
          characters: [
            ...initial.characters,
            const ProjectCharacterEntry(
              id: 'unrelated_hero',
              name: 'Unrelated hero',
              tilesetId: 'unrelated_hero_sheet',
            ),
          ],
          eventRegistry: NarrativeEventRegistry(
            schemaVersion: registry.schemaVersion,
            mode: registry.mode,
            legacyClaims: registry.legacyClaims,
            records: [
              ...registry.records,
              for (var index = 0; index < unrelatedCount; index++)
                NarrativeEventRecord.configuredStructurallyUnchecked(
                  NarrativeEventDefinition(
                    id: 'evt_00000000-0000-7000-8000-${(index + 100).toRadixString(16).padLeft(12, '0')}',
                    name: 'Unrelated producer $index',
                    source: NarrativeEventSourceRef.mapEnter(
                      'unrelated_$index',
                    ),
                    conditions: [],
                    sceneId: index == 0
                        ? initial.scenes.first.id
                        : 'unrelated_scene_$index',
                    reusePolicy: NarrativeEventReusePolicy.reusable,
                    priority: 0,
                    order: 0,
                  ),
                  enabled: true,
                ),
            ],
          ),
          maps: [
            ...initial.maps,
            for (var index = 0; index < unrelatedCount; index++)
              ProjectMapEntry(
                id: 'unrelated_$index',
                name: 'Unrelated $index',
                relativePath: 'maps/unrelated_$index.json',
              ),
          ],
          tilesets: [
            ...initial.tilesets,
            const ProjectTilesetEntry(
              id: 'unrelated_hero_sheet',
              name: 'Unrelated hero',
              relativePath: 'assets/unrelated_hero.png',
            ),
            for (var index = 0; index < unrelatedCount; index++)
              ProjectTilesetEntry(
                id: 'unrelated_$index',
                name: 'Unrelated $index',
                relativePath: 'assets/unrelated_$index.png',
              ),
          ],
          facts: [
            ...initial.facts,
            for (var index = 0; index < unrelatedCount; index++)
              NarrativeFactDefinition(
                id: 'unrelated_fact_$index',
                label: 'Unrelated $index',
              ),
          ],
        );
        if (workingCatalog) {
          final store = await CatalogStorageStore.open(
            projectRoot: fixture.source.directory.path,
          );
          await WorkingProjectCatalog.create(
            store: store,
            expectedProjectRevision: await store.gateway.readResourceRevision(
              'project.json',
            ),
            projectId: 'guided-scope',
            project: project,
          );
        } else {
          await File('${fixture.source.directory.path}/project.json')
              .writeAsString(jsonEncode(project.toJson()));
        }
        await FileIdempotencyStore(
          filePath:
              '${fixture.source.directory.path}/.pokemap/authoring/idempotency.jsonl',
        ).prepareIncrementalStorage();
        final session = ProjectSession(
          sessionId: 'guided-scope',
          name: project.name,
          directoryPath: fixture.source.directory.path,
          storage: workingCatalog
              ? ProjectSessionStorage.workingCatalog
              : ProjectSessionStorage.manifest,
        );
        final reader = _GuidedReadCounter();
        final observer = _GuidedPerformanceCounter();
        final maps = LocalMapWorkspaceAdapter(reader: reader);
        if (workingCatalog) {
          await maps.loadCatalog(session);
        } else {
          await maps.loadProject(session);
        }
        var base = await maps.loadMap(session, project.maps.first);
        final port = LocalEventAdapter(
          session: session,
          mapAdapter: maps,
          reader: reader,
          performanceObserver: observer,
        );
        reader.clear();
        observer.counters.clear();
        final first = await port.publishTemplate(
          base: base,
          spec: spec(project),
          project: project,
          maps: [base.map],
        );
        reader.expectTargeted(project.maps.first.relativePath);
        expect(
          observer.counters[AuthoringPerformanceCounterName.filesystemWrite],
          greaterThan(0),
        );
        if (unrelatedCount > 0) {
          final foreignMap = base.map.copyWith(id: 'unrelated_0', entities: []);
          await File('${session.directoryPath}/maps/unrelated_0.json')
              .writeAsString(jsonEncode(foreignMap.toJson()));
          final policy = await WorkspacePolicy.create(
            allowedRootPaths: [session.directoryPath],
            fileReader: reader,
          );
          final handles = WorkspaceHandleStore();
          final opened = await ProjectOpenService(
            policy: policy,
            fileReader: reader,
            handles: handles,
            catalogMetadataFields: const {},
          ).openProject(session.directoryPath);
          final api = LocalMapAuthoringMutationApi(
            policy: policy,
            snapshotLoader: ProjectSnapshotLoader(handles: handles),
            catalogFileReader: reader,
          );
          await api.attachProject(
            projectRootPath: session.directoryPath,
            workspaceHandle: opened.workspaceHandle,
            projectHandle: opened.projectHandle,
          );
          try {
            final selected = await api.readWorkshopSnapshot(
              opened.projectHandle,
              actionId: 'narrative.publish_document',
              parameters: {
                'map': first.savedMap.toJson(),
                'mapRevision': first.revision,
                'scenes': [
                  {
                    ...initial.scenes.first.toJson(),
                    'name': 'Shared scene updated',
                  },
                ],
              },
            );
            expect(selected.maps.map((map) => map.id).toSet(), {
              base.map.id,
              'unrelated_0',
            });
            final generatedSceneId = standardEventTemplateSceneIds(
              spec(project),
            ).first;
            final originalForeign = project.eventRegistry!.records.singleWhere(
              (record) =>
                  record.definitionOrNull?.source.toJson()['mapId'] ==
                  'unrelated_0',
            );
            final sharedRecord = NarrativeEventRecord.fromJson({
              ...originalForeign.toJson(),
              'definition': {
                ...originalForeign.definitionOrNull!.toJson(),
                'sceneId': generatedSceneId,
              },
            });
            final sharedParameters = <String, Object?>{
              'map': foreignMap.toJson(),
              'mapRevision': narrativeEventBytesFingerprint(
                utf8.encode(jsonEncode(foreignMap.toJson())),
              ),
              'events': [sharedRecord.toJson()],
            };
            final sharedSnapshot = await api.readWorkshopSnapshot(
              opened.projectHandle,
              actionId: 'narrative.publish_document',
              parameters: sharedParameters,
            );
            final sharedPlan = await api.planMutation(
              opened.projectHandle,
              AuthoringRequest(
                requestId: 'shared-consumer',
                actionId: 'narrative.publish_document',
                actionVersion: 1,
                workspaceHandle: opened.workspaceHandle.value,
                expectedRevision: sharedSnapshot.revision,
                idempotencyKey: 'shared-consumer',
                parameters: sharedParameters,
                extensions: const {'workshopScope': true},
              ),
            );
            await api.applyMutation(
              opened.projectHandle,
              planId: sharedPlan.planId,
              operationId: 'shared-consumer',
            );
            await File('${session.directoryPath}/maps/unrelated_0.json')
                .delete();
          } finally {
            await api.detachWorkspace(opened.workspaceHandle);
          }
        }
        final reopened = LocalMapWorkspaceAdapter(reader: reader);
        if (workingCatalog) {
          await reopened.loadCatalog(session);
        } else {
          await reopened.loadProject(session);
        }
        base = await reopened.loadMap(session, project.maps.first);
        if (workingCatalog) {
          await reopened.loadWorkshop(session, MapWorkspaceWorkshop.events);
        }
        final fresh = (await reopened.resourceBaseline(session)).manifest;
        reader.clear();
        observer.counters.clear();
        final second =
            await LocalEventAdapter(
              session: session,
              mapAdapter: reopened,
              reader: reader,
              performanceObserver: observer,
            ).publishTemplate(
              base: base,
              spec: spec(fresh, alternate: 'station_refusal'),
              project: fresh,
              maps: [base.map],
            );
        reader.expectTargeted(project.maps.first.relativePath);
        expect(
          observer.counters[AuthoringPerformanceCounterName.filesystemWrite],
          greaterThan(0),
        );
        expect(second.savedMap.id, base.mapId);
        expect(second.manifest.scenes, containsAll(first.manifest.scenes));
        expect(second.manifest.maps.length, project.maps.length);
        final finalReader = LocalMapWorkspaceAdapter();
        if (workingCatalog) {
          await finalReader.loadCatalog(session);
        } else {
          await finalReader.loadProject(session);
        }
        expect(
          (await finalReader.loadMap(session, project.maps.first)).map,
          second.savedMap,
        );
        final metadataPolicy = await WorkspacePolicy.create(
          allowedRootPaths: [session.directoryPath],
          fileReader: const LocalProjectFileReader(),
        );
        final metadataHandles = WorkspaceHandleStore();
        final metadataService = ProjectOpenService(
          policy: metadataPolicy,
          fileReader: const LocalProjectFileReader(),
          handles: metadataHandles,
          catalogMetadataFields: const {'settings', 'newGame'},
        );
        final metadataOpened = await metadataService.openProject(
          session.directoryPath,
        );
        try {
          final catalog = await metadataService.catalogProject(
            metadataOpened.projectHandle,
          );
          final persisted = catalog == null
              ? ProjectManifest.fromJson(
                  jsonDecode(
                    await File('${session.directoryPath}/project.json')
                        .readAsString(),
                  ) as Map<String, dynamic>,
                )
              : await catalog.readMetadata({'settings', 'newGame'});
          expect(persisted.newGame, project.newGame);
          expect(persisted.settings, project.settings);
        } finally {
          metadataService.closeWorkspace(metadataOpened.workspaceHandle);
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }

  test(
    'a second parameterized instance leaves the first generated assets intact',
    () async {
      var project = await fixture.readFresh();
      var base = await fixture.source.maps.loadMap(
        fixture.source.session,
        project.maps.first,
      );
      final first = await fixture.port.publishTemplate(
        base: base,
        spec: spec(project),
        project: project,
        maps: [base.map],
      );
      project = await fixture.readFresh();
      base = await fixture.source.maps.loadMap(
        fixture.source.session,
        project.maps.first,
      );
      final firstEntity = base.map.entities.singleWhere(
        (entity) => entity.id == 'template_a',
      );
      final second = await fixture.port.publishTemplate(
        base: base,
        spec: spec(project, owner: 'template_b', alternate: 'station_refusal'),
        project: project,
        maps: [base.map],
      );
      expect(
        second.savedMap.entities.singleWhere(
          (entity) => entity.id == 'template_a',
        ),
        firstEntity,
      );
      expect(second.manifest.scenes, containsAll(first.manifest.scenes));
      expect(
        second.manifest.eventRegistry!.records,
        containsAll(first.manifest.eventRegistry!.records),
      );
      expect(
        readStandardEventTemplate(
          project: second.manifest,
          map: second.savedMap,
          entityId: 'template_b',
        )!.parameters['alternateDialogueId'],
        'station_refusal',
      );
    },
  );

  test(
    'a stale map refuses the entire publication without a partial registry',
    () async {
      final project = await fixture.readFresh();
      final base = await fixture.source.maps.loadMap(
        fixture.source.session,
        project.maps.first,
      );
      await fixture.source.maps.saveMap(
        fixture.source.session,
        base,
        base.map.copyWith(name: 'Carte modifiée ailleurs'),
      );
      final file = File('${fixture.source.directory.path}/project.json');
      final before = await file.readAsBytes();
      await expectLater(
        fixture.port.publishTemplate(
          base: base,
          spec: spec(project),
          project: project,
          maps: [base.map],
        ),
        throwsA(anything),
      );
      expect(await file.readAsBytes(), before);
      expect((await fixture.readFresh()).eventRegistry, project.eventRegistry);
    },
  );

  for (final checkpoint in [
    AuthoringTransactionCheckpoint.beforeResourcePromotion,
    AuthoringTransactionCheckpoint.afterResourcePromoted,
  ]) {
    test(
      'atomic recovery after $checkpoint leaves a coherent editable event',
      () async {
        final project = await fixture.readFresh();
        final base = await fixture.source.maps.loadMap(
          fixture.source.session,
          project.maps.first,
        );
        var interrupted = false;
        final port = LocalEventAdapter(
          session: fixture.source.session,
          mapAdapter: fixture.source.maps,
          faultInjector: (context) {
            if (!interrupted &&
                context.checkpoint == checkpoint &&
                context.promotionIndex == 0) {
              interrupted = true;
              throw StateError('simulated interruption');
            }
          },
        );
        final receipt = await port.publishTemplate(
          base: base,
          spec: spec(project),
          project: project,
          maps: [base.map],
        );
        expect(interrupted, isTrue);
        final freshPort = LocalMapWorkspaceAdapter();
        final fresh = await freshPort.loadProject(fixture.source.session);
        final map = (await freshPort.loadMap(
          fixture.source.session,
          fresh.maps.first,
        )).map;
        expect(fresh, receipt.manifest);
        final actual = map.toJson();
        final reported = receipt.savedMap.toJson();
        expect(
          [
            for (final key in actual.keys)
              if (jsonEncode(actual[key]) != jsonEncode(reported[key])) key,
          ],
          isEmpty,
          reason: 'The receipt must describe the bytes actually written.',
        );
        expect(
          readStandardEventTemplate(
            project: fresh,
            map: map,
            entityId: 'template_a',
          ),
          isNotNull,
        );
      },
    );
  }
}

final class _GuidedReadCounter
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final paths = <String>[];
  var unrelatedUnits = 0;
  final _local = const LocalProjectFileReader();
  void clear() {
    paths.clear();
    unrelatedUnits = 0;
  }

  void expectTargeted(String mapPath) {
    expect(paths.where((path) => path.startsWith('maps/')).toSet(), {mapPath});
    expect(paths.where((path) => path.contains('unrelated_')), isEmpty);
    expect(paths.where((path) => path.endsWith('idempotency.jsonl')), isEmpty);
    expect(unrelatedUnits, 0);
  }

  void observe(String path, List<int> bytes) {
    paths.add(path);
    if (path.startsWith('catalog/objects/')) {
      final object = jsonDecode(utf8.decode(bytes));
      if (object is Map && object['type'] == 'unit') {
        final payload = Map<String, dynamic>.from(object['payload'] as Map);
        if (payload['section'] == r'$shell' && payload['value'] is Map) {
          payload['value'] = Map<String, dynamic>.from(payload['value'] as Map)
            ..remove('eventRegistry')
            ..remove('settings')
            ..remove('newGame');
        }
        if (jsonEncode(payload).contains('unrelated_')) {
          unrelatedUnits++;
        }
      }
    }
  }

  @override
  bool get supportsStreamingResources => true;
  @override
  Future<String> canonicalizeDirectory(String path) =>
      _local.canonicalizeDirectory(path);
  @override
  Future<ProjectResourceProbe> probeResource({
    required String projectRoot,
    required String relativePath,
  }) => _local.probeResource(
    projectRoot: projectRoot,
    relativePath: relativePath,
  );
  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) async {
    final bytes = await _local.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
    observe(relativePath, bytes);
    return bytes;
  }

  @override
  Stream<List<int>> openRead({
    required String projectRoot,
    required String relativePath,
  }) async* {
    final bytes = await _local.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
    observe(relativePath, bytes);
    yield bytes;
  }
}

final class _GuidedPerformanceCounter implements AuthoringPerformanceObserver {
  final counters = <String, int>{};
  @override
  AuthoringPerformanceSpan? startSpan(String name) => null;
  @override
  void incrementCounter(String name, {int by = 1}) =>
      counters.update(name, (count) => count + by, ifAbsent: () => by);
}
