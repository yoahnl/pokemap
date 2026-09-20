import 'dart:convert';
import 'dart:math';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/map_authoring.dart'
    show AuthoringTransactionFaultInjector;
import 'package:map_core/map_core.dart';
import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../project_session/domain/project_session.dart';
import '../../resources/domain/resource_port.dart';
import '../domain/scene_port.dart';

class LocalSceneAdapter implements ScenePort {
  const LocalSceneAdapter({
    required this.session,
    required this.mapAdapter,
    this.faultInjector,
  });
  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  final AuthoringTransactionFaultInjector? faultInjector;

  @override
  Future<ScenePublicationReceipt> publishScene({
    required SceneAsset? base,
    required SceneAsset current,
  }) => mapAdapter.withResourceMutation(() async {
    try {
      if (base != null && base.id != current.id) {
        throw const SceneFailure('L’identité de la scène a changé.');
      }
      final baseline = await mapAdapter.resourceBaseline(session);
      final existing = baseline.manifest.scenes
          .where((scene) => scene.id == current.id)
          .firstOrNull;
      if (existing != base) {
        throw const SceneFailure(
          'Cette scène a changé depuis son ouverture. Votre brouillon est conservé ; rouvrez sa version enregistrée avant de réappliquer vos changements.',
        );
      }
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
          throw const SceneFailure(
            'Le projet a changé sur le disque. Le brouillon reste ouvert.',
          );
        }
        final operation =
            'scene_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
        final planned = await api.planMutation(
          opened.projectHandle,
          AuthoringRequest(
            requestId: operation,
            actionId: 'scene.upsert',
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: operation,
            parameters:
                jsonDecode(jsonEncode({'scene': current.toJson()}))
                    as Map<String, dynamic>,
          ),
        );
        final changes = planned.plan.changeSet.changes;
        if (changes.any((change) => change.storageKey != 'project.json')) {
          throw const SceneFailure(
            'La publication de scène a une portée inattendue.',
          );
        }
        final projectBytes =
            changes
                .where((change) => change.storageKey == 'project.json')
                .firstOrNull
                ?.afterBytes ??
            snapshot.resourceBytes('project');
        final manifest = ProjectManifest.fromJson(
          jsonDecode(utf8.decode(projectBytes)) as Map<String, dynamic>,
        );
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
              throw SceneFailure(
                'Publication interrompue. Journal $operation conservé, brouillon ouvert : $failure',
              );
            }
          }
        }
        final actual = await reader.readBytes(
          projectRoot: session.directoryPath,
          relativePath: 'project.json',
        );
        if (narrativeEventBytesFingerprint(actual) !=
            narrativeEventBytesFingerprint(projectBytes)) {
          throw const SceneFailure(
            'Le reçu ne correspond pas au projet écrit. Votre brouillon reste ouvert.',
          );
        }
        final receipt = ResourceMutationReceipt(
          before: baseline.manifest,
          manifest: manifest,
          beforeRevision: baseline.revision,
          revision: narrativeEventBytesFingerprint(projectBytes),
          changedPaths: changes.map((change) => change.storageKey).toList(),
        );
        await mapAdapter.acceptResourceMutation(session, receipt);
        return ScenePublicationReceipt(
          catalog: receipt,
          scene: manifest.scenes.singleWhere((scene) => scene.id == current.id),
        );
      } finally {
        if (attached) await api.detachWorkspace(opened.workspaceHandle);
        handles.closeWorkspace(opened.workspaceHandle);
      }
    } on SceneFailure {
      rethrow;
    } on Object catch (failure) {
      throw SceneFailure(
        'La scène n’a pas été enregistrée. Le brouillon reste ouvert. Vérifiez ses connexions et références : $failure',
      );
    }
  });
}
