import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _localId = 'evt_019abcde-0029-7000-8000-000000000001';
const _remoteId = 'evt_019abcde-0029-7000-8000-000000000002';
const _localPath = 'maps/port.json';
const _remotePath = 'maps/remote.json';

void main() {
  for (final wire in [false, true]) {
    test(
      '${wire ? 'JSONL' : 'direct API'} scopes event publication to A while preserving independent B without global validation',
      () async {
        final qa = Directory(
          '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109/event-scoped-transport',
        );
        await qa.create(recursive: true);
        final root = await qa.createTemp('two-map-');
        addTearDown(() => root.delete(recursive: true));
        final shared = jsonDecode(
          await File('test/fixtures/event_v2_transport_parity.json')
              .readAsString(),
        ) as Map<String, dynamic>;
        final original = ProjectManifest.fromJson(
          shared['project'] as Map<String, dynamic>,
        );
        final map = MapData.fromJson(
          ((shared['maps'] as List).single as Map)['content']
              as Map<String, dynamic>,
        );
        final local = _record(_localId, 'Port entry', 'port');
        final remote = _record(_remoteId, 'Independent remote entry', 'remote');
        final registry = NarrativeEventRegistry(
          schemaVersion: original.eventRegistry!.schemaVersion,
          mode: EventSystemMode.v2Only,
          records: [local, remote],
          legacyClaims: original.eventRegistry!.legacyClaims,
        );
        final project = original.copyWith(
          maps: [
            ...original.maps,
            const ProjectMapEntry(
              id: 'remote',
              name: 'Remote',
              relativePath: _remotePath,
            ),
          ],
          eventRegistry: registry,
        );
        final manifest = File('${root.path}/project.json');
        final localFile = File('${root.path}/$_localPath');
        final remoteFile = File('${root.path}/$_remotePath');
        await localFile.parent.create(recursive: true);
        await manifest.writeAsString(jsonEncode(project.toJson()));
        await localFile.writeAsString(jsonEncode(map.toJson()));
        await remoteFile.writeAsString(
          jsonEncode(map.copyWith(id: 'remote', name: 'Remote').toJson()),
        );
        final beforeProject = await manifest.readAsBytes();
        final beforeLocal = await localFile.readAsBytes();
        final beforeRemote = await remoteFile.readAsBytes();
        final reader = _CountingReader();
        final policy = await WorkspacePolicy.create(
          allowedRootPaths: [root.path],
          fileReader: reader,
        );
        final handles = WorkspaceHandleStore();
        final snapshots = ProjectSnapshotLoader(handles: handles);
        final api = AuthoringReadApi(
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
        final worker = JsonlWorker(api: api, mutations: mutations);
        var sequence = 0;
        Future<Map<String, Object?>> command(
          String name,
          Map<String, Object?> args,
        ) async {
          final result = AuthoringResult.fromJson(
            jsonDecode(
              await worker.processLine(jsonEncode({
                'id': 'scoped-${++sequence}',
                'command': name,
                'args': args,
              })),
            ) as Map<String, dynamic>,
          );
          expect(result.status, AuthoringResultStatus.success,
              reason: jsonEncode(result.toJson()));
          return result.data;
        }

        final opened = wire
            ? await command('open', {'projectRoot': root.path})
            : await api.open(root.path);
        final workspace = WorkspaceHandle(opened['workspaceHandle'] as String);
        final handle = ProjectHandle(opened['projectHandle'] as String);
        if (!wire) {
          await mutations.attachProject(
            projectRootPath: root.path,
            workspaceHandle: workspace,
            projectHandle: handle,
          );
        }
        addTearDown(() async {
          if (wire) {
            await worker.close();
          } else {
            await mutations.detachWorkspace(workspace);
            await api.close(workspace);
          }
        });
        expect(reader.paths, isNot(contains(_remotePath)));
        final updated = _record(
          _localId,
          'Guide interaction on A',
          'port',
          source: NarrativeEventSourceRef.entityInteract('port', 'guide'),
        );
        final parameters = <String, Object?>{'record': updated.toJson()};
        final selected = wire
            ? await command('workshop_snapshot', {
                'projectHandle': handle.value,
                'actionId': 'event_v2.record_upsert',
                'parameters': parameters,
              })
            : await mutations.readWorkshopDocument(
                handle,
                actionId: 'event_v2.record_upsert',
                parameters: parameters,
              );
        expect(
          (selected['maps'] as List).cast<Map>().map((map) => map['id']),
          ['port'],
        );
        expect(reader.paths, contains(_localPath));
        expect(reader.paths, isNot(contains(_remotePath)));
        expect(await manifest.readAsBytes(), beforeProject);
        final request = AuthoringRequest(
          requestId: 'scoped-event',
          actionId: 'event_v2.record_upsert',
          actionVersion: 1,
          workspaceHandle: workspace.value,
          expectedRevision: selected['snapshotRevision'] as String,
          idempotencyKey: 'scoped-event',
          extensions: Map<String, Object?>.from(
            selected['planExtensions'] as Map,
          ),
          parameters: parameters,
        );
        final planned = wire
            ? await command('plan', {
                'projectHandle': handle.value,
                'request': request.toJson(),
              })
            : await mutations.plan(handle, request);
        expect(reader.paths, isNot(contains(_remotePath)));
        expect(await manifest.readAsBytes(), beforeProject);
        expect(await localFile.readAsBytes(), beforeLocal);
        expect(await remoteFile.readAsBytes(), beforeRemote);
        final applied = wire
            ? await command('apply', {
                'projectHandle': handle.value,
                'planId': planned['planId'],
                'operationId': 'scoped-event-apply',
              })
            : await mutations.apply(
                handle,
                planId: planned['planId'] as String,
                operationId: 'scoped-event-apply',
              );
        expect((applied['receipt'] as Map)['status'], 'applied');
        expect(reader.paths, isNot(contains(_remotePath)));
        expect(await localFile.readAsBytes(), beforeLocal);
        expect(await remoteFile.readAsBytes(), beforeRemote);
        final saved = ProjectManifest.fromJson(
          jsonDecode(await manifest.readAsString()) as Map<String, dynamic>,
        );
        expect(saved.eventRegistry!.records, [updated, remote]);
        expect(saved.eventRegistry!.toJson(), {
          ...registry.toJson(),
          'records': [updated.toJson(), remote.toJson()],
        });
        expect(saved.copyWith(eventRegistry: registry), project);
      },
    );
  }
}

NarrativeEventRecord _record(
  String id,
  String name,
  String mapId, {
  NarrativeEventSourceRef? source,
}) =>
    NarrativeEventRecord.configuredStructurallyUnchecked(
      NarrativeEventDefinition(
        id: id,
        name: name,
        source: source ?? NarrativeEventSourceRef.mapEnter(mapId),
        conditions: const [],
        sceneId: 'hello',
        reusePolicy: NarrativeEventReusePolicy.reusable,
        priority: 0,
        order: 0,
      ),
      enabled: false,
    );

final class _CountingReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
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

  @override
  bool get supportsStreamingResources => true;

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

  @override
  Future<ProjectResourceProbe> probeResource({
    required String projectRoot,
    required String relativePath,
  }) =>
      delegate.probeResource(
        projectRoot: projectRoot,
        relativePath: relativePath,
      );
}
