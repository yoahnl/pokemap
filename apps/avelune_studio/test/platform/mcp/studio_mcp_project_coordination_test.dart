import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_atmosphere_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_exterior_decoration_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_atmosphere_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_exterior_decoration_port.dart';
import 'package:avelune_studio/features/project_visuals/application/project_visuals_controller.dart';
import 'package:avelune_studio/features/project_visuals/domain/project_visuals_port.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:avelune_studio/features/project_surf/application/project_surf_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editor_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_editor_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../../support/scoped_map_workspace_port.dart';

void main() {
  final workCounts = <int, List<int>>{};
  for (final scenario in [
    (foreignCount: 0, storage: ProjectSessionStorage.workingCatalog),
    (foreignCount: 80, storage: ProjectSessionStorage.workingCatalog),
    (foreignCount: 0, storage: ProjectSessionStorage.manifest),
  ]) {
    final foreignCount = scenario.foreignCount;
    test(
      '${scenario.storage.name} advances only targeted baselines with $foreignCount foreign maps',
      () async {
        final qa = Directory(
          '/Users/karim/Library/Caches/AveluneQA/mcp-studio-integration/i3',
        );
        await qa.create(recursive: true);
        final root = await qa.createTemp('coordination-');
        addTearDown(() => root.delete(recursive: true));
        await Directory('${root.path}/maps').create();
        final entries = [
          for (final id in [
            'a',
            'b',
            for (var i = 0; i < foreignCount; i++) 'foreign-$i',
          ])
            ProjectMapEntry(id: id, name: id, relativePath: 'maps/$id.json'),
        ];
        for (final entry in entries) {
          final map = MapData(
            id: entry.id,
            name: entry.name,
            version: ProjectVersion.v9,
            size: const GridSize(width: 4, height: 4),
            layers: const [],
            spatialScene: MapSpatialScene(width: 4, depth: 4),
          );
          await File('${root.path}/${entry.relativePath}')
              .writeAsString(jsonEncode(map.toJson()));
        }
        final project = ProjectManifest(
          name: 'Coordination',
          version: ProjectVersion.v9,
          settings: ProjectSettings(
            dimension: ProjectDimension.threeD,
            spatialCamera: SpatialCameraProfile(),
          ),
          maps: entries,
          tilesets: const [],
        );
        if (scenario.storage == ProjectSessionStorage.workingCatalog) {
          final store = await CatalogStorageStore.open(projectRoot: root.path);
          await WorkingProjectCatalog.create(
            store: store,
            projectId: 'coordination',
            project: project,
          );
        } else {
          await File('${root.path}/project.json')
              .writeAsString(jsonEncode(project.toJson()));
        }
        final session = ProjectSession(
          sessionId: 'coordination',
          name: project.name,
          directoryPath: root.path,
          storage: scenario.storage,
        );
        final reader = _Reader();
        var metadataEntriesRead = 0, metadataNodesCopied = 0;
        final local = LocalMapWorkspaceAdapter(
          reader: reader,
          onMapMetadataEntryRead: () => metadataEntriesRead++,
          onMapMetadataNodeCopied: () => metadataNodesCopied++,
        );
        await local.loadCatalog(session);
        await local.loadMapSelection(session, entries.first);
        final controller = MapWorkspaceController(session, local);
        addTearDown(controller.dispose);
        await controller.initialize();
        expect(controller.error, isNull);
        await controller.activate(entries[1]);
        final b = controller.active;
        final policy = await WorkspacePolicy.create(
          allowedRootPaths: [root.path],
          fileReader: const LocalProjectFileReader(),
        );
        final handles = WorkspaceHandleStore();
        final opener = ProjectOpenService(
          policy: policy,
          fileReader: const LocalProjectFileReader(),
          handles: handles,
        );
        final opened = await opener.openProject(root.path);
        final snapshotLoader = ProjectSnapshotLoader(handles: handles);
        final api = LocalMapAuthoringMutationApi(
          policy: policy,
          snapshotLoader: snapshotLoader,
        );
        Future<ProjectSnapshot> mapSnapshot(Map<String, Object?> parameters) =>
            scenario.storage == ProjectSessionStorage.manifest
            ? snapshotLoader.load(opened.projectHandle)
            : api.readWorkshopSnapshot(
                opened.projectHandle,
                actionId: 'map.update_metadata',
                parameters: parameters,
              );
        await api.attachProject(
          projectRootPath: root.path,
          workspaceHandle: opened.workspaceHandle,
          projectHandle: opened.projectHandle,
        );
        addTearDown(() async {
          await api.detachWorkspace(opened.workspaceHandle);
          opener.closeWorkspace(opened.workspaceHandle);
        });
        final history = File('${root.path}/.pokemap/authoring/history.jsonl');
        await history.parent.create(recursive: true);
        if (scenario.storage == ProjectSessionStorage.workingCatalog) {
          await history.writeAsString(
            'unrelated history must not be read\n' * (foreignCount + 1),
          );
        }
        workCounts[foreignCount] = [];
        for (var i = 0; i < 2; i++) {
          final parameters = <String, Object?>{
            'mapId': 'a',
            'name': 'External $i',
          };
          final snapshot = await mapSnapshot(parameters);
          final planned = await api.planMutation(
            opened.projectHandle,
            AuthoringRequest(
              requestId: 'external-$i',
              actionId: 'map.update_metadata',
              actionVersion: 1,
              workspaceHandle: opened.workspaceHandle.value,
              parameters: parameters,
              expectedRevision: snapshot.revision,
              idempotencyKey: 'external-$i',
            ),
          );
          await api.applyMutation(
            opened.projectHandle,
            planId: planned.planId,
            operationId: 'external-$i',
          );
          reader.paths.clear();
          metadataEntriesRead = 0;
          metadataNodesCopied = 0;
          await controller.acceptExternalMutation({
            (kind: 'map', id: 'a'),
            (kind: 'project', id: 'coordination'),
          });
          expect(controller.error, isNull);
          expect(controller.documents['a']!.current.name, 'External $i');
          expect(controller.documents['b'], same(b));
          expect(
            reader.paths.where(
              (path) =>
                  path.contains('foreign-') ||
                  path == 'maps/b.json' ||
                  path.contains('history'),
            ),
            isEmpty,
          );
          expect(reader.paths.length, lessThan(150));
          expect(metadataEntriesRead, lessThan(16));
          expect(metadataNodesCopied, lessThan(16));
          workCounts[foreignCount]!.add(reader.paths.length);
        }
        if (foreignCount == 80) {
          expect(
            workCounts[foreignCount]![0],
            lessThanOrEqualTo(workCounts[0]![0] + 20),
          );
          expect(workCounts[foreignCount]![0], workCounts[foreignCount]![1]);
          expect(workCounts[0]![0], workCounts[0]![1]);
        }
        final chunkParameters = <String, Object?>{
          'mapId': 'a',
          'name': 'External chunk',
        };
        final chunkSnapshot = await mapSnapshot(chunkParameters);
        final chunkPlan = await api.planMutation(
          opened.projectHandle,
          AuthoringRequest(
            requestId: 'external-chunk',
            actionId: 'map.update_metadata',
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            parameters: chunkParameters,
            expectedRevision: chunkSnapshot.revision,
            idempotencyKey: 'external-chunk',
          ),
        );
        await api.applyMutation(
          opened.projectHandle,
          planId: chunkPlan.planId,
          operationId: 'external-chunk',
        );
        metadataEntriesRead = 0;
        metadataNodesCopied = 0;
        await controller.acceptExternalMutation({(kind: 'map', id: 'a')});
        expect(controller.error, isNull);
        expect(controller.documents['a']!.current.name, 'External chunk');
        expect(
          (controller.project!.maps as ProjectMapEntries).lookup('a')!.name,
          'External chunk',
        );
        expect(controller.documents['b'], same(b));
        expect(metadataEntriesRead, lessThan(16));
        expect(metadataNodesCopied, lessThan(16));
        final mapBytes = await File('${root.path}/maps/a.json').readAsBytes();
        final roleParameters = <String, Object?>{
          'mapId': 'a',
          'role': 'basement',
        };
        final roleSnapshot = await mapSnapshot(roleParameters);
        final rolePlan = await api.planMutation(
          opened.projectHandle,
          AuthoringRequest(
            requestId: 'external-role',
            actionId: 'map.update_metadata',
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            parameters: roleParameters,
            expectedRevision: roleSnapshot.revision,
            idempotencyKey: 'external-role',
          ),
        );
        final roleResult = await api.apply(
          opened.projectHandle,
          planId: rolePlan.planId,
          operationId: 'external-role',
        );
        final roleNotification = roleResult['changeNotification'] as Map;
        final roleResources = {
          for (final ref in roleNotification['resources'] as List)
            (kind: (ref as Map)['kind'] as String, id: ref['id'] as String),
        };
        expect(roleResources, contains((kind: 'mapMetadata', id: 'a')));
        expect(roleResources, isNot(contains((kind: 'map', id: 'a'))));
        reader.paths.clear();
        metadataEntriesRead = 0;
        metadataNodesCopied = 0;
        final roleDocument = controller.documents['a'];
        await controller.acceptExternalMutation(roleResources);
        expect(controller.error, isNull);
        expect(
          (controller.project!.maps as ProjectMapEntries).lookup('a')!.role,
          MapRole.basement,
        );
        expect(controller.documents['a'], same(roleDocument));
        expect(reader.paths.where((path) => path.startsWith('maps/')), isEmpty);
        expect(metadataEntriesRead, lessThan(16));
        expect(metadataNodesCopied, lessThan(16));
        expect(await File('${root.path}/maps/a.json').readAsBytes(), mapBytes);
        if (foreignCount == 0) {
          final surfOwner = ProjectSurfController(
            session: session,
            port: local,
            dimension: ProjectDimension.threeD,
            onSaved: controller.acceptSurfConfiguration,
          );
          addTearDown(surfOwner.dispose);
          await surfOwner.open();
          surfOwner.change(enabled: true);
          expect(await surfOwner.save(), isTrue);
          expect(controller.project!.settings.surf!.enabled, isTrue);
          await api.detachWorkspace(opened.workspaceHandle);
          await api.attachProject(
            projectRootPath: root.path,
            workspaceHandle: opened.workspaceHandle,
            projectHandle: opened.projectHandle,
          );
          final surfParameters = <String, Object?>{
            'configuration': const ProjectSurfSettings(enabled: false).toJson(),
          };
          final surfSnapshot = await api.readWorkshopSnapshot(
            opened.projectHandle,
            actionId: 'surf.configure',
            parameters: surfParameters,
          );
          final surfPlan = await api.planMutation(
            opened.projectHandle,
            AuthoringRequest(
              requestId: 'external-surf',
              actionId: 'surf.configure',
              actionVersion: 1,
              workspaceHandle: opened.workspaceHandle.value,
              parameters: surfParameters,
              expectedRevision: surfSnapshot.revision,
              idempotencyKey: 'external-surf',
            ),
          );
          final surfResult = await api.apply(
            opened.projectHandle,
            planId: surfPlan.planId,
            operationId: 'external-surf',
          );
          final surfResources = {
            for (final ref
                in (surfResult['changeNotification'] as Map)['resources']
                    as List)
              (kind: (ref as Map)['kind'] as String, id: ref['id'] as String),
          };
          expect(
            surfResources,
            contains((kind: 'projectSettings', id: 'surf')),
          );
          await controller.acceptExternalMutation(surfResources);
          expect(controller.project!.settings.surf!.enabled, isFalse);
          await controller.activate(
            (controller.project!.maps as ProjectMapEntries).lookup('a')!,
          );
          expect(controller.project!.settings.surf!.enabled, isFalse);
          await controller.activate(entries[1]);
          expect(controller.project!.settings.surf!.enabled, isFalse);
          expect(surfOwner.preview.value.enabled, isTrue);
          expect(surfOwner.canUndo, isTrue);
        }
        final a = controller.documents['a']!;
        a.commit(a.current.copyWith(name: 'Human draft'));
        final undo = a.undoToken;
        final baseRevision = a.base.revision;
        final parameters = <String, Object?>{
          'mapId': 'a',
          'name': 'External conflict',
        };
        final snapshot = await mapSnapshot(parameters);
        final planned = await api.planMutation(
          opened.projectHandle,
          AuthoringRequest(
            requestId: 'external-conflict',
            actionId: 'map.update_metadata',
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            parameters: parameters,
            expectedRevision: snapshot.revision,
            idempotencyKey: 'external-conflict',
          ),
        );
        await api.applyMutation(
          opened.projectHandle,
          planId: planned.planId,
          operationId: 'external-conflict',
        );
        await controller.acceptExternalMutation({
          (kind: 'map', id: 'a'),
          (kind: 'project', id: 'coordination'),
        });
        expect(a.current.name, 'Human draft');
        expect(a.base.revision, baseRevision);
        expect(a.undoToken, same(undo));
        expect(await controller.save(a), isFalse);
        expect(a.error, contains('externe'));
        final reopened = LocalMapWorkspaceAdapter();
        await reopened.loadCatalog(session);
        expect(
          (await reopened.loadMapSelection(
            session,
            entries.first.copyWith(
              name: 'External conflict',
              role: MapRole.basement,
            ),
          )).document.map.name,
          'External conflict',
        );
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }

  for (final field in ['surf', 'fieldAbilities', 'audio']) {
    test(
      'external $field replaces only its accepted overlay across map activation',
      () async {
        final port = _Port();
        final controller = MapWorkspaceController(scopedMapSession, port);
        addTearDown(controller.dispose);
        await controller.initialize();
        const surf = ProjectSurfSettings(enabled: true);
        final abilities = ProjectFieldAbilitiesSettings.fromIds(['cut']);
        final audio = ProjectAudioSettings();
        controller.acceptSurfConfiguration(surf);
        controller.acceptFieldAbilities(abilities);
        controller.acceptAudio(audio);
        final a = controller.active!;
        a.commit(a.current.copyWith(name: 'Human draft'));
        final undo = a.undoToken;
        port.externalMetadata = scopedMapMetadata.copyWith(
          settings: ProjectSettings(
            surf: const ProjectSurfSettings(enabled: false),
            fieldAbilities: null,
            audio: null,
          ),
        );
        await controller.acceptExternalMutation({
          (kind: 'project', id: 'project'),
          (kind: 'projectSettings', id: field),
        });
        expect(controller.error, isNull);
        expect(controller.active, same(a));
        expect(a.undoToken, same(undo));
        expect(a.current.name, 'Human draft');
        await controller.activate(secondScopedMap);
        final settings = controller.project!.settings;
        expect(settings.surf?.enabled, field == 'surf' ? isFalse : isTrue);
        expect(
          settings.fieldAbilities,
          field == 'fieldAbilities' ? isNull : same(abilities),
        );
        expect(settings.audio, field == 'audio' ? isNull : same(audio));
      },
    );
  }

  test('mutation refreshes A without reading or invalidating B', () async {
    final port = _Port();
    final controller = MapWorkspaceController(scopedMapSession, port);
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.activate(secondScopedMap);
    final b = controller.active;
    final previewB = controller.previewMap(secondScopedMap.id);
    await previewB;
    port.selections.clear();
    port.revision = 'map-external';
    await controller.acceptExternalMutation({(kind: 'map', id: 'first')});
    expect(controller.documents['first']!.base.revision, 'map-external');
    expect(controller.documents['first']!.current.name, 'Externe');
    expect(controller.documents['second'], same(b));
    expect(controller.previewMap(secondScopedMap.id), same(previewB));
    expect(port.selections, ['first']);
    expect(port.fullReads, 0);
    expect(port.baselines, 1);
  });

  test(
    'a changed dependency refreshes only selections using that resource',
    () async {
      final port = _Port();
      final controller = MapWorkspaceController(scopedMapSession, port);
      addTearDown(controller.dispose);
      await controller.initialize();
      await controller.activate(secondScopedMap);
      final b = controller.active;
      port.selections.clear();
      await controller.acceptExternalMutation({(kind: 'tileset', id: 'first')});
      expect(port.selections, ['first']);
      expect(controller.documents['second'], same(b));
    },
  );

  test(
    'typing during a refresh retains the new draft and its original baseline',
    () async {
      final port = _Port();
      final controller = MapWorkspaceController(scopedMapSession, port);
      addTearDown(controller.dispose);
      await controller.initialize();
      final a = controller.active!;
      final started = Completer<void>();
      final release = Completer<void>();
      port.beforeLoad = () {
        started.complete();
        return release.future;
      };
      final refresh = controller.acceptExternalMutation({
        (kind: 'map', id: 'first'),
      });
      await started.future;
      a.commit(a.current.copyWith(name: 'New keystroke'));
      release.complete();
      await refresh;
      expect(controller.active, same(a));
      expect(a.current.name, 'New keystroke');
      expect(a.base.revision, 'map-1');
      expect(a.canUndo, isTrue);
      expect(a.error, contains('externe'));
    },
  );

  test('changed character invalidates its workshops without reading an unrelated workshop', () async {
    final port = _Port();
    final controller = MapWorkspaceController(scopedMapSession, port);
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.ensureWorkshop(MapWorkspaceWorkshop.dialogue);
    await controller.ensureWorkshop(MapWorkspaceWorkshop.regionalMap);
    await controller.acceptExternalMutation({
      (kind: 'character', id: 'changed'),
    });
    expect(controller.hasWorkshop(MapWorkspaceWorkshop.dialogue), isFalse);
    expect(controller.hasWorkshop(MapWorkspaceWorkshop.regionalMap), isTrue);
    expect(port.workshops, [
      MapWorkspaceWorkshop.dialogue,
      MapWorkspaceWorkshop.regionalMap,
    ]);
    expect(port.fullReads, 0);
  });

  for (final savedHistory in [false, true]) {
    test(
      'identical map replay preserves ${savedHistory ? 'saved history' : 'dirty geometry'} until bytes really change',
      () async {
        final port = _Port();
        final controller = MapWorkspaceController(scopedMapSession, port);
        addTearDown(controller.dispose);
        await controller.initialize();
        port.revision = 'accepted-publication';
        await controller.acceptExternalMutation({(kind: 'map', id: 'first')});
        final a = controller.active!;
        a.commit(a.current.copyWith(name: 'Human draft'));
        if (savedHistory) a.acceptSave(a.current, a.base.revision);
        final base = a.base;
        final undo = a.undoToken;
        final preview = controller.previewMap('first');
        await preview;
        port.selections.clear();
        await controller.acceptExternalMutation({(kind: 'map', id: 'first')});
        expect(controller.active, same(a));
        expect(a.current.name, 'Human draft');
        expect(a.base, same(base));
        expect(a.undoToken, same(undo));
        expect(a.error, isNull);
        expect(controller.error, isNull);
        expect(controller.previewMap('first'), same(preview));
        expect(port.selections, isEmpty);
        port.revision = 'new-durable-write';
        await controller.acceptExternalMutation({(kind: 'map', id: 'first')});
        expect(controller.active, same(a));
        expect(a.current.name, 'Human draft');
        expect(a.base, same(base));
        expect(a.undoToken, same(undo));
        expect(a.error, contains('externe'));
        expect(await controller.save(a), isFalse);
      },
    );
  }

  for (final operation in ['field', 'traversal', 'order']) {
    test(
      'an in-flight native map operation retains its owner on external change: $operation',
      () async {
        final port = _Port();
        final controller = MapWorkspaceController(scopedMapSession, port);
        addTearDown(controller.dispose);
        await controller.initialize();
        final a = controller.active!;
        switch (operation) {
          case 'field':
            a.spatialFieldObstacleSaving = true;
          case 'traversal':
            a.fieldTraversalSaving = true;
          case 'order':
            a.elementOrderSaving = true;
        }
        port.revision = 'new-durable-write';
        await controller.acceptExternalMutation({(kind: 'map', id: 'first')});
        expect(controller.active, same(a));
        expect(controller.documents['first'], same(a));
        expect(a.base.revision, 'map-1');
        expect(a.error, contains('externe'));
      },
    );
  }

  for (final global in [false, true]) {
    for (final dirtyOwner in [false, true]) {
      test(
        'visual file refresh preserves dirty geometry: global=$global dirtyOwner=$dirtyOwner',
        () async {
          final port = _VisualPort();
          final controller = MapWorkspaceController(scopedMapSession, port);
          addTearDown(controller.dispose);
          await controller.initialize();
          final a = controller.active!;
          final owner = ProjectVisualsController(
            session: scopedMapSession,
            port: port,
          );
          await owner.open(map: firstScopedMap);
          a.weatherVisuals = owner;
          if (dirtyOwner) {
            owner.edit(
              SpatialVisualPatch({SpatialVisualParameter.waterAnimated: true}),
            );
          }
          final preview = owner.preview.value;
          final saved = owner.saved;
          a.commit(a.current.copyWith(name: 'Geometry draft'));
          final base = a.base;
          final undo = a.undoToken;
          if (global) {
            port.projectState = ProjectVisualsState(
              profile: SpatialVisualPatch({
                SpatialVisualParameter.minuteOfDay: 960.0,
              }),
              revision: 'project-2',
            );
          } else {
            port.mapState = ProjectVisualsState(
              profile: SpatialVisualPatch({
                SpatialVisualParameter.depthOfFieldEnabled: true,
              }),
              revision: 'map-visual-2',
            );
          }
          await controller.acceptExternalMutation({
            (
              kind: 'visualSettings',
              id: global
                  ? SpatialVisualDocument.projectRelativePath
                  : SpatialVisualDocument.relativePathForMap('first'),
            ),
          });
          expect(controller.active, same(a));
          expect(a.current.name, 'Geometry draft');
          expect(a.base, same(base));
          expect(a.undoToken, same(undo));
          expect(a.error, isNull);
          expect(controller.error, isNull);
          expect(a.weatherVisuals, same(owner));
          if (global || dirtyOwner) {
            expect(owner.preview.value, same(preview));
            expect(owner.saved, same(saved));
          } else {
            expect(owner.preview.value, port.mapState.profile);
            expect(owner.saved!.revision, 'map-visual-2');
          }
          if (global) {
            expect(owner.error, isNull);
            expect(
              a.visualProfile.value(SpatialVisualParameter.minuteOfDay),
              960.0,
            );
          } else if (dirtyOwner) {
            expect(owner.error, contains('externe'));
          }
          controller.restore(redo: false);
          expect(a.current.name, firstScopedMap.name);
          expect(a.error, isNull);
          expect(await controller.save(a), global || !dirtyOwner);
        },
      );
    }
  }

  for (final global in [false, true]) {
    test(
      'settings visual owner conflicts only for its own scope: global=$global',
      () async {
        final port = _VisualPort();
        final controller = MapWorkspaceController(scopedMapSession, port);
        addTearDown(controller.dispose);
        await controller.initialize();
        final a = controller.active!;
        a.commit(a.current.copyWith(name: 'Geometry draft'));
        final owner = ProjectVisualsController(
          session: scopedMapSession,
          port: port,
        );
        addTearDown(owner.dispose);
        await owner.open();
        controller.settingsVisualsOwner = owner;
        owner.edit(
          SpatialVisualPatch({SpatialVisualParameter.waterAnimated: true}),
        );
        final preview = owner.preview.value;
        final saved = owner.saved;
        port.projectState = ProjectVisualsState(
          profile: SpatialVisualPatch({
            SpatialVisualParameter.minuteOfDay: 960.0,
          }),
          revision: 'project-2',
        );
        port.mapState = ProjectVisualsState(
          profile: SpatialVisualPatch({
            SpatialVisualParameter.depthOfFieldEnabled: true,
          }),
          revision: 'map-visual-2',
        );
        await controller.acceptExternalMutation({
          (
            kind: 'visualSettings',
            id: global
                ? SpatialVisualDocument.projectRelativePath
                : SpatialVisualDocument.relativePathForMap('first'),
          ),
        });
        expect(controller.active, same(a));
        expect(a.error, isNull);
        expect(owner.preview.value, same(preview));
        expect(owner.saved, same(saved));
        expect(owner.canUndo, isTrue);
        if (global) {
          expect(owner.error, contains('externe'));
        } else {
          expect(owner.error, isNull);
        }
        controller.restore(redo: false);
        expect(a.current.name, firstScopedMap.name);
        expect(await controller.save(a), isTrue);
      },
    );
  }

  for (final kind in ['mapAtmosphere', 'mapEditor', 'mapExteriorDecoration']) {
    for (final dirtyOwner in [false, true]) {
      test(
        'secondary file refresh preserves geometry and unrelated owners: $kind/$dirtyOwner',
        () async {
          final port = _OwnerPort();
          final controller = MapWorkspaceController(scopedMapSession, port);
          addTearDown(controller.dispose);
          await controller.initialize();
          final a = controller.active!;
          a.atmosphere ??= await MapAtmosphereController.open(
            scopedMapSession,
            'first',
            port,
          );
          a.exteriorDecoration ??= await MapExteriorDecorationController.open(
            scopedMapSession,
            a.current,
            port,
          );
          final atmosphere = a.atmosphere;
          final editor = a.editor;
          final exterior = a.exteriorDecoration;
          if (dirtyOwner) {
            switch (kind) {
              case 'mapAtmosphere':
                a.atmosphere!.edit(
                  SpatialAtmosphereSettings(waterAnimated: true),
                );
              case 'mapEditor':
                a.editor!.current = a.editor!.current.copyWith(
                  hiddenFamilies: {'decor'},
                );
              case 'mapExteriorDecoration':
                a.exteriorDecoration!.configureMargins(
                  west: 1,
                  east: 1,
                  north: 1,
                  south: 1,
                );
            }
          }
          final preview = switch (kind) {
            'mapAtmosphere' => a.atmosphere!.current,
            'mapEditor' => a.editor!.current,
            _ => a.exteriorDecoration!.current,
          };
          a.commit(a.current.copyWith(name: 'Geometry draft'));
          final undo = a.undoToken;
          final base = a.base;
          port.atmosphere = MapAtmosphereState(
            settings: SpatialAtmosphereSettings(windowsLit: true),
            revision: 'atmosphere-2',
          );
          port.editor = MapEditorWorkspaceState(
            state: MapEditorState(hiddenFamilies: {'model'}),
            revision: 'editor-2',
          );
          port.exterior = MapExteriorDecorationState(
            decoration: MapExteriorDecoration(
              mapId: 'first',
              playableWidth: 2,
              playableDepth: 2,
              west: 2,
              east: 2,
              north: 2,
              south: 2,
            ),
            revision: 'exterior-2',
          );
          await controller.acceptExternalMutation({(kind: kind, id: 'first')});
          expect(controller.active, same(a));
          expect(a.current.name, 'Geometry draft');
          expect(a.base, same(base));
          expect(a.undoToken, same(undo));
          expect(a.error, isNull);
          if (kind != 'mapAtmosphere') expect(a.atmosphere, same(atmosphere));
          if (kind != 'mapEditor') expect(a.editor, same(editor));
          if (kind != 'mapExteriorDecoration') {
            expect(a.exteriorDecoration, same(exterior));
          }
          final current = switch (kind) {
            'mapAtmosphere' => a.atmosphere!.current,
            'mapEditor' => a.editor!.current,
            _ => a.exteriorDecoration!.current,
          };
          final error = switch (kind) {
            'mapAtmosphere' => a.atmosphere!.error,
            'mapEditor' => a.editor!.error,
            _ => a.exteriorDecoration!.error,
          };
          if (dirtyOwner) {
            expect(current, same(preview));
            expect(error, contains('externe'));
          } else {
            expect(current, isNot(preview));
            expect(error, isNull);
          }
          controller.restore(redo: false);
          expect(a.current.name, firstScopedMap.name);
          expect(await controller.save(a), !dirtyOwner);
          expect(port.unexpectedWrites, 0);
        },
      );
    }
  }

  for (final savedHistory in [false, true]) {
    test(
      'dependency refresh preserves ${savedHistory ? 'saved history' : 'dirty draft'} without a conflict',
      () async {
        final port = _Port();
        final controller = MapWorkspaceController(scopedMapSession, port);
        addTearDown(controller.dispose);
        await controller.initialize();
        final a = controller.active!;
        a.commit(a.current.copyWith(name: 'Human edit'));
        if (savedHistory) a.acceptSave(a.current, a.base.revision);
        final undo = a.undoToken;
        final base = a.base;
        port.tilesetName = 'Updated tileset';
        await controller.acceptExternalMutation({
          (kind: 'tileset', id: 'first'),
        });
        expect(controller.active, same(a));
        expect(a.current.name, 'Human edit');
        expect(a.base, same(base));
        expect(a.undoToken, same(undo));
        expect(a.error, isNull);
        expect(controller.error, isNull);
        expect(
          controller.visualProject!.tilesets.single.name,
          'Updated tileset',
        );
        controller.restore(redo: false);
        expect(a.current.name, firstScopedMap.name);
        expect(a.error, isNull);
        expect(await controller.save(a), isTrue);
      },
    );
  }

  for (final renamed in [false, true]) {
    for (final dirty in [false, true]) {
      test(
        'external ${renamed ? 'rename' : 'delete'} closes a clean selection and preserves a dirty one: $dirty',
        () async {
          final port = _Port();
          final controller = MapWorkspaceController(scopedMapSession, port);
          addTearDown(controller.dispose);
          await controller.initialize();
          final a = controller.active!;
          if (dirty) a.commit(a.current.copyWith(name: 'Protected draft'));
          final undo = a.undoToken;
          final previewB = controller.previewMap(secondScopedMap.id);
          await previewB;
          port.externalMetadata = scopedMapMetadata.copyWith(
            maps: [
              if (renamed)
                firstScopedMap.copyWith(
                  id: 'renamed',
                  name: 'Renamed',
                  relativePath: 'renamed.json',
                ),
              secondScopedMap,
            ],
          );
          await controller.acceptExternalMutation({
            (kind: 'map', id: 'first'),
            (kind: 'project', id: 'project'),
            if (renamed) (kind: 'map', id: 'renamed'),
          });
          expect(
            controller.project!.maps.any((entry) => entry.id == 'first'),
            isFalse,
          );
          expect(
            controller.project!.maps.any((entry) => entry.id == 'renamed'),
            renamed,
          );
          expect(controller.previewMap(secondScopedMap.id), same(previewB));
          if (dirty) {
            expect(controller.active, same(a));
            expect(controller.documents['first'], same(a));
            expect(a.current.name, 'Protected draft');
            expect(a.undoToken, same(undo));
            expect(a.error, contains('externe'));
            expect(await controller.save(a), isFalse);
          } else {
            expect(controller.active, isNull);
            expect(controller.documents.containsKey('first'), isFalse);
            expect(controller.previewDefinitionsFor('first'), isNull);
            expect(
              controller.visualProject!.maps.any(
                (entry) => entry.id == 'first',
              ),
              isFalse,
            );
          }
        },
      );
    }
  }

  test(
    'dirty document and local undo survive with an explicit conflict',
    () async {
      final port = _Port();
      final controller = MapWorkspaceController(scopedMapSession, port);
      addTearDown(controller.dispose);
      await controller.initialize();
      final a = controller.active!;
      a.commit(a.current.copyWith(name: 'Brouillon'));
      final token = a.undoToken;
      port.revision = 'map-external';
      await controller.acceptExternalMutation({(kind: 'map', id: 'first')});
      expect(controller.active, same(a));
      expect(a.current.name, 'Brouillon');
      expect(a.base.revision, 'map-1');
      expect(a.undoToken, same(token));
      expect(a.error, contains('externe'));
      expect(await controller.save(a), isFalse);
      expect(a.current.name, 'Brouillon');
    },
  );

  test(
    'saved local history is retained and cannot undo an external publication',
    () async {
      final port = _Port();
      final controller = MapWorkspaceController(scopedMapSession, port);
      addTearDown(controller.dispose);
      await controller.initialize();
      final a = controller.active!;
      a.commit(a.current.copyWith(name: 'Previously saved'));
      a.acceptSave(a.current, 'map-1');
      final token = a.undoToken;
      port.revision = 'external-publication';
      await controller.acceptExternalMutation({(kind: 'map', id: 'first')});
      controller.restore(redo: false);
      expect(controller.active, same(a));
      expect(a.current.name, 'Previously saved');
      expect(a.undoToken, same(token));
      expect(a.error, contains('externe'));
    },
  );

  for (final owner in ['editor', 'atmosphere', 'exterior', 'weather']) {
    test('a dirty $owner owner protects the complete document', () async {
      final port = _Port();
      final controller = MapWorkspaceController(scopedMapSession, port);
      addTearDown(controller.dispose);
      await controller.initialize();
      final a = controller.active!;
      final secondary = _SecondaryPort();
      switch (owner) {
        case 'editor':
          final editor = MapEditorController(
            session: scopedMapSession,
            mapId: 'first',
            port: _EditorPort(),
            state: MapEditorWorkspaceState(
              state: MapEditorState(),
              revision: 'editor-1',
            ),
          );
          a.editor = editor;
          editor.current = editor.current.copyWith(hiddenFamilies: {'decor'});
        case 'atmosphere':
          a.atmosphere = await MapAtmosphereController.open(
            scopedMapSession,
            'first',
            secondary,
          );
          a.atmosphere!.edit(SpatialAtmosphereSettings(waterAnimated: true));
        case 'exterior':
          a.exteriorDecoration = await MapExteriorDecorationController.open(
            scopedMapSession,
            a.current,
            secondary,
          );
          a.exteriorDecoration!.configureMargins(
            west: 1,
            east: 1,
            north: 1,
            south: 1,
          );
        case 'weather':
          a.weatherVisuals = ProjectVisualsController(
            session: scopedMapSession,
            port: secondary,
          );
          await a.weatherVisuals!.open(map: firstScopedMap);
          a.weatherVisuals!.edit(
            SpatialVisualPatch({SpatialVisualParameter.waterAnimated: true}),
          );
      }
      port.revision = 'external-publication';
      await controller.acceptExternalMutation({(kind: 'map', id: 'first')});
      expect(controller.active, same(a));
      expect(switch (owner) {
        'editor' => a.editor!.dirty,
        'atmosphere' => a.atmosphere!.dirty,
        'exterior' => a.exteriorDecoration!.dirty,
        _ => a.weatherVisuals!.dirty,
      }, isTrue);
      expect(a.error, contains('externe'));
    });
  }
}

class _Port extends ScopedTestMapPort
    implements MapWorkspaceExternalMutationPort {
  String revision = 'map-1';
  String? tilesetName;
  ProjectManifest? externalMetadata;
  Future<void> Function()? beforeLoad;
  int baselines = 0;
  @override
  Future<String?> readExternalMapRevision(
    ProjectSession session,
    String mapId,
  ) async =>
      (externalMetadata ?? metadata).maps.any((entry) => entry.id == mapId)
      ? revision
      : null;

  @override
  Future<MapWorkspaceCatalog> refreshExternalBaseline(
    ProjectSession session, {
    required Set<({String kind, String id})> resources,
  }) async {
    baselines++;
    return MapWorkspaceCatalog(
      metadata: externalMetadata ?? metadata,
      revision: 'catalog-external',
    );
  }

  @override
  Future<MapWorkspaceSelection> loadMapSelection(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    final selection = await super.loadMapSelection(session, entry);
    return MapWorkspaceSelection(
      document: selection.document,
      definitions: selection.definitions.copyWith(
        tilesets: [
          for (final tileset in selection.definitions.tilesets)
            tilesetName == null
                ? tileset
                : tileset.copyWith(name: tilesetName!),
        ],
      ),
      catalogRevision: selection.catalogRevision,
      snapshotRevision: selection.snapshotRevision,
    );
  }

  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    await beforeLoad?.call();
    final value = await super.loadMap(session, entry);
    return MapWorkspaceDocument(
      map: value.map.copyWith(
        name: revision == 'map-1' ? entry.name : 'Externe',
      ),
      revision: revision,
      mapId: entry.id,
    );
  }

  @override
  Future<String> saveMap(
    ProjectSession session,
    MapWorkspaceDocument base,
    MapData current,
  ) async {
    if (base.revision != revision) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'Modification externe.',
      );
    }
    return revision;
  }
}

class _EditorPort implements MapEditorPort {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Reader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  @override
  bool get supportsStreamingResources => true;
  @override
  Future<ProjectResourceProbe> probeResource({
    required String projectRoot,
    required String relativePath,
  }) => delegate.probeResource(
    projectRoot: projectRoot,
    relativePath: relativePath,
  );
  @override
  Stream<List<int>> openRead({
    required String projectRoot,
    required String relativePath,
  }) {
    paths.add(relativePath);
    return delegate.openRead(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }

  final paths = <String>[];
  final delegate = const LocalProjectFileReader();
  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);
  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) {
    paths.add(relativePath);
    return delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }
}

class _SecondaryPort
    implements
        MapAtmospherePort,
        MapExteriorDecorationPort,
        ProjectVisualsPort {
  @override
  Future<MapAtmosphereState> loadAtmosphere(
    ProjectSession session,
    String mapId,
  ) async => MapAtmosphereState(
    settings: SpatialAtmosphereSettings(),
    revision: 'atmosphere-1',
  );
  @override
  Future<MapExteriorDecorationState> loadExteriorDecoration(
    ProjectSession session,
    String mapId,
  ) async => const MapExteriorDecorationState(
    decoration: null,
    revision: 'exterior-1',
  );
  @override
  Future<ProjectVisualsState> loadVisuals(
    ProjectSession session, {
    ProjectMapEntry? map,
  }) async =>
      ProjectVisualsState(profile: SpatialVisualPatch(), revision: 'weather-1');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _VisualPort extends _Port implements ProjectVisualsPort {
  ProjectVisualsState projectState = ProjectVisualsState(
    profile: SpatialVisualPatch(),
    revision: 'project-1',
  );
  ProjectVisualsState mapState = ProjectVisualsState(
    profile: SpatialVisualPatch(),
    revision: 'map-visual-1',
  );
  @override
  Future<ProjectVisualsState> loadVisuals(
    ProjectSession session, {
    ProjectMapEntry? map,
  }) async => map == null ? projectState : mapState;
  @override
  Future<ProjectVisualsState> saveVisuals(
    ProjectSession session,
    SpatialVisualPatch profile,
    String expectedRevision, {
    ProjectMapEntry? map,
  }) async {
    final before = map == null ? projectState : mapState;
    if (before.revision != expectedRevision) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'Visual conflict',
      );
    }
    final result = ProjectVisualsState(
      profile: profile,
      revision: '${before.revision}-saved',
    );
    if (map == null) {
      projectState = result;
    } else {
      mapState = result;
    }
    return result;
  }

  @override
  Future<ProjectVisualsState> undoVisuals(
    ProjectSession session,
    String receiptId,
    String expectedRevision, {
    ProjectMapEntry? map,
  }) => throw UnsupportedError('Not used');
}

class _OwnerPort extends _VisualPort
    implements MapAtmospherePort, MapEditorPort, MapExteriorDecorationPort {
  MapAtmosphereState atmosphere = MapAtmosphereState(
    settings: SpatialAtmosphereSettings(),
    revision: 'atmosphere-1',
  );
  MapEditorWorkspaceState editor = MapEditorWorkspaceState(
    state: MapEditorState(),
    revision: 'editor-1',
  );
  MapExteriorDecorationState exterior = const MapExteriorDecorationState(
    decoration: null,
    revision: 'exterior-1',
  );
  int unexpectedWrites = 0;
  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    final value = await super.loadMap(session, entry);
    return MapWorkspaceDocument(
      map: value.map.copyWith(
        version: ProjectVersion.v9,
        spatialScene: MapSpatialScene(width: 2, depth: 2),
      ),
      revision: value.revision,
      mapId: value.mapId,
    );
  }

  @override
  Future<MapAtmosphereState> loadAtmosphere(
    ProjectSession session,
    String mapId,
  ) async => atmosphere;
  @override
  Future<MapEditorWorkspaceState> loadEditorState(
    ProjectSession session,
    String mapId,
  ) async => editor;
  @override
  Future<MapExteriorDecorationState> loadExteriorDecoration(
    ProjectSession session,
    String mapId,
  ) async => exterior;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    unexpectedWrites++;
    return super.noSuchMethod(invocation);
  }
}
