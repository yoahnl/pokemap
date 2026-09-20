import 'dart:convert';
import 'dart:math';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/map_authoring.dart'
    show AuthoringTransactionFaultInjector;
import 'package:map_core/map_core.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../project_session/domain/project_session.dart';
import '../../resources/domain/resource_port.dart';
import '../domain/dialogue_port.dart';

class LocalDialogueTransaction {
  const LocalDialogueTransaction({
    required this.session,
    required this.mapAdapter,
    this.faultInjector,
  });

  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  final AuthoringTransactionFaultInjector? faultInjector;

  Future<DialoguePublicationReceipt> run({
    required String id,
    required DialogueSourceSnapshot? base,
    required ProjectDialogueEntry? entry,
    required String? source,
  }) async {
    final baseline = await mapAdapter.resourceBaseline(
      session,
      refreshCatalog: true,
    );
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
        throw const DialogueFailure(
          'Le projet a changé pendant la publication.',
        );
      }
      final actual = snapshot.manifest.dialogues
          .where((e) => e.id == id)
          .firstOrNull;
      if (actual != base?.entry ||
          (base != null &&
              narrativeEventBytesFingerprint(
                    snapshot.resourceBytes('dialogueSource:$id'),
                  ) !=
                  base.revision)) {
        throw const DialogueFailure(
          'Ce dialogue a changé sur le disque. Le brouillon reste ouvert ; rechargez pour reprendre la version actuelle.',
        );
      }
      final action = entry == null
          ? 'dialogue.delete'
          : base == null
          ? 'dialogue.create'
          : entry == base.entry
          ? 'dialogue.source_update'
          : 'dialogue.update';
      final operation =
          'dialogue_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
      final planned = await api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
          requestId: operation,
          actionId: action,
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision: snapshot.revision,
          idempotencyKey: operation,
          parameters: {
            if (action == 'dialogue.delete' ||
                action == 'dialogue.source_update')
              'dialogueId': id
            else
              'entry': entry!.toJson(),
            'source': ?source,
          },
        ),
      );
      final changes = planned.plan.changeSet.changes;
      final path = entry?.relativePath ?? base!.entry.relativePath;
      if (changes.any(
        (c) => c.storageKey != 'project.json' && c.storageKey != path,
      )) {
        throw const DialogueFailure(
          'La publication dépasse le dialogue sélectionné.',
        );
      }
      final projectBytes =
          changes
              .where((c) => c.storageKey == 'project.json')
              .firstOrNull
              ?.afterBytes ??
          snapshot.resourceBytes('project');
      final manifest = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(projectBytes)) as Map<String, dynamic>,
      );
      if (changes.isNotEmpty) {
        final confirmation = action == 'dialogue.delete'
            ? await api.confirmMutation(
                opened.projectHandle,
                planId: planned.planId,
              )
            : null;
        try {
          await api.applyMutation(
            opened.projectHandle,
            planId: planned.planId,
            operationId: operation,
            confirmationToken: confirmation?.confirmationToken,
          );
        } on Object catch (failure) {
          try {
            await api.recoverMutation(
              opened.projectHandle,
              operationId: operation,
            );
          } on Object {
            throw DialogueFailure(
              'Publication interrompue. Journal $operation conservé, brouillon ouvert : $failure',
            );
          }
        }
      }
      for (final expected in {
        'project.json': projectBytes,
        if (source != null) path: utf8.encode(source),
      }.entries) {
        final written = await reader.readBytes(
          projectRoot: session.directoryPath,
          relativePath: expected.key,
        );
        if (narrativeEventBytesFingerprint(written) !=
            narrativeEventBytesFingerprint(expected.value)) {
          throw const DialogueFailure(
            'Le reçu ne correspond pas aux fichiers. Le brouillon reste ouvert.',
          );
        }
      }
      if (source == null) {
        final probe = await reader.probeResource(
          projectRoot: session.directoryPath,
          relativePath: path,
        );
        if (probe.status != ProjectResourceProbeStatus.missing) {
          throw const DialogueFailure(
            'La suppression de la source n’est pas confirmée.',
          );
        }
      }
      final resources = ResourceMutationReceipt(
        before: baseline.manifest,
        manifest: manifest,
        beforeRevision: baseline.revision,
        revision: narrativeEventBytesFingerprint(projectBytes),
        changedPaths: changes.map((c) => c.storageKey).toList(),
      );
      await mapAdapter.acceptResourceMutation(session, resources);
      return DialoguePublicationReceipt(
        resources: resources,
        snapshot: entry == null
            ? null
            : DialogueSourceSnapshot(
                entry: entry,
                source: source!,
                revision: narrativeEventBytesFingerprint(utf8.encode(source)),
              ),
      );
    } finally {
      if (attached) await api.detachWorkspace(opened.workspaceHandle);
      handles.closeWorkspace(opened.workspaceHandle);
    }
  }
}
