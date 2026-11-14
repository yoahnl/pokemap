import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'studio_mcp_project_coordination_fakes.dart';
import 'studio_mcp_project_coordination_steps.dart';

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
        final (:entries, :project) = await seedCoordinationProject(
          root,
          foreignCount: foreignCount,
          storage: scenario.storage,
        );
        final session = ProjectSession(
          sessionId: 'coordination',
          name: project.name,
          directoryPath: root.path,
          storage: scenario.storage,
        );
        final reader = CoordinationReader();
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
          await applyExternalMutation(
            api,
            opened,
            'external-$i',
            parameters,
            snapshot.revision,
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
        await applyExternalMutation(
          api,
          opened,
          'external-chunk',
          chunkParameters,
          chunkSnapshot.revision,
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
        final roleResources = await applyExternalChange(
          api,
          opened,
          'external-role',
          roleParameters,
          roleSnapshot.revision,
        );
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
          final surf = await local.loadSurf(session);
          final savedSurf = await local.saveSurf(
            session,
            const ProjectSurfSettings(),
            surf.revision,
          );
          controller.acceptSurfConfiguration(savedSurf.configuration);
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
          final surfResources = await applyExternalChange(
            api,
            opened,
            'external-surf',
            surfParameters,
            surfSnapshot.revision,
            actionId: 'surf.configure',
          );
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
        await applyExternalMutation(
          api,
          opened,
          'external-conflict',
          parameters,
          snapshot.revision,
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
}
