import 'dart:convert';
import 'dart:math';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/map_authoring.dart'
    show AuthoringTransactionFaultInjector;
import 'package:map_core/map_core.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../project_session/domain/project_session.dart';
import '../../resources/domain/resource_port.dart';
import '../domain/narrative_port.dart';

class LocalNarrativeAdapter implements NarrativePort {
  const LocalNarrativeAdapter({
    required this.session,
    required this.mapAdapter,
    this.faultInjector,
  });
  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  final AuthoringTransactionFaultInjector? faultInjector;

  @override
  Future<NarrativeDialogueSource> readDialogue(
    ProjectDialogueEntry entry,
  ) async {
    final baseline = await mapAdapter.resourceBaseline(session);
    if (!baseline.manifest.dialogues.contains(entry)) {
      throw const NarrativeFailure(
        'Ce dialogue ne figure plus dans le projet.',
      );
    }
    final bytes = await const LocalProjectFileReader().readBytes(
      projectRoot: session.directoryPath,
      relativePath: entry.relativePath,
    );
    return NarrativeDialogueSource(
      entry: entry,
      source: utf8.decode(bytes),
      revision: narrativeEventBytesFingerprint(bytes),
    );
  }

  @override
  Future<NarrativePublicationReceipt> publish(
    NarrativePublication publication,
  ) => mapAdapter.withResourceMutation(() async {
    try {
      if (publication.base.mapId != publication.current.id) {
        throw const NarrativeFailure('La carte de publication a changé.');
      }
      final baseline = await mapAdapter.resourceBaseline(session);
      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
        allowedRootPaths: [session.directoryPath],
        fileReader: reader,
      );
      final handles = WorkspaceHandleStore();
      final opened = await ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ).openProject(session.directoryPath);
      final snapshots = ProjectSnapshotLoader(handles: handles);
      final api = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: snapshots,
        faultInjector: faultInjector,
      );
      var attached = false;
      try {
        await api.attachProject(
          projectRootPath: session.directoryPath,
          workspaceHandle: opened.workspaceHandle,
          projectHandle: opened.projectHandle,
        );
        attached = true;
        final snapshot = await snapshots.load(opened.projectHandle);
        if (narrativeEventBytesFingerprint(snapshot.resourceBytes('project')) !=
            baseline.revision) {
          throw const NarrativeFailure('Le projet a changé sur le disque.');
        }
        final operation =
            'narrative_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
        final planned = await api.planMutation(
          opened.projectHandle,
          AuthoringRequest(
            requestId: operation,
            actionId: 'narrative.publish_document',
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: operation,
            parameters:
                jsonDecode(
                      jsonEncode({
                        'map': publication.current.toJson(),
                        'mapRevision': publication.base.revision,
                        'dialogues': [
                          for (final source in publication.dialogues)
                            {
                              'entry': source.entry.toJson(),
                              'source': source.source,
                              'revision': source.revision,
                            },
                        ],
                        'scenes': [
                          for (final value in publication.scenes)
                            value.toJson(),
                        ],
                        'cinematics': [
                          for (final value in publication.cinematics)
                            value.toJson(),
                        ],
                        'facts': [
                          for (final value in publication.facts) value.toJson(),
                        ],
                        'storylines': [
                          for (final value in publication.storylines)
                            value.toJson(),
                        ],
                        'events': [
                          for (final value in publication.events)
                            value.toJson(),
                        ],
                      }),
                    )
                    as Map<String, dynamic>,
          ),
        );
        final changes = planned.plan.changeSet.changes;
        final projectBytes =
            changes
                .where((e) => e.storageKey == 'project.json')
                .firstOrNull
                ?.afterBytes ??
            snapshot.resourceBytes('project');
        final manifest = ProjectManifest.fromJson(
          jsonDecode(utf8.decode(projectBytes)) as Map<String, dynamic>,
        );
        final mapEntry = manifest.maps.singleWhere(
          (e) => e.id == publication.current.id,
        );
        final mapBytes =
            changes
                .where((e) => e.storageKey == mapEntry.relativePath)
                .firstOrNull
                ?.afterBytes ??
            snapshot.resourceBytes('map:${mapEntry.id}');
        if (changes.isNotEmpty) {
          try {
            await api.applyMutation(
              opened.projectHandle,
              planId: planned.planId,
              operationId: operation,
            );
          } on Object catch (failure) {
            try {
              await api.recoverMutation(
                opened.projectHandle,
                operationId: operation,
              );
            } on Object {
              throw NarrativeFailure(
                'Publication interrompue. Le journal $operation est conservé et le brouillon reste ouvert : $failure',
              );
            }
          }
        }
        final paths = <String, List<int>>{
          'project.json': projectBytes,
          mapEntry.relativePath: mapBytes,
          for (final source in publication.dialogues)
            source.entry.relativePath: utf8.encode(source.source),
        };
        for (final expected in paths.entries) {
          final actual = await reader.readBytes(
            projectRoot: session.directoryPath,
            relativePath: expected.key,
          );
          if (narrativeEventBytesFingerprint(actual) !=
              narrativeEventBytesFingerprint(expected.value)) {
            throw const NarrativeFailure(
              'Le reçu de publication ne correspond pas aux fichiers. Le brouillon est conservé.',
            );
          }
        }
        await mapAdapter.acceptResourceMutation(
          session,
          ResourceMutationReceipt(
            before: baseline.manifest,
            manifest: manifest,
            beforeRevision: baseline.revision,
            revision: narrativeEventBytesFingerprint(projectBytes),
            changedPaths: changes.map((e) => e.storageKey).toList(),
          ),
        );
        return NarrativePublicationReceipt(
          beforeManifest: baseline.manifest,
          manifest: manifest,
          savedMap: publication.current,
          revision: narrativeEventBytesFingerprint(mapBytes),
          sourceRevisions: {
            for (final source in publication.dialogues)
              source.entry.id: narrativeEventBytesFingerprint(
                utf8.encode(source.source),
              ),
          },
          changedPaths: changes.map((e) => e.storageKey).toList(),
        );
      } finally {
        if (attached) await api.detachWorkspace(opened.workspaceHandle);
        handles.closeWorkspace(opened.workspaceHandle);
      }
    } on NarrativeFailure {
      rethrow;
    } on Object catch (error) {
      throw NarrativeFailure(
        'L’histoire n’a pas été enregistrée. Votre travail reste ouvert : $error',
      );
    }
  });
}
