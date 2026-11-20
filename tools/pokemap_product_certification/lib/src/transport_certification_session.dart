import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/transport_certification.dart';
import 'package:map_editor/authoring_transport.dart';
import 'package:path/path.dart' as p;

part 'transport_certification_wire_session.dart';

typedef TransportCertificationSession = ({
  Future<AppliedTransportStep> Function(AuthoringTransportStep, String) apply,
  Future<void> Function() close,
});

typedef AppliedTransportStep = ({
  AuthoringReceipt receipt,
  List<ContentArtifactRef> stagedArtifacts,
});

Future<TransportCertificationSession> openTransportCertificationSession(
  AuthoringTransport transport,
  Directory project,
  Directory repository,
  String dart, {
  required bool measurePlanPreimage,
}) => switch (transport) {
  AuthoringTransport.directApi => _openDirect(project),
  AuthoringTransport.editor => _openEditor(project, measurePlanPreimage),
  AuthoringTransport.cli || AuthoringTransport.mcp => _WireSession.open(
    transport,
    project,
    repository,
    dart,
  ),
};

const _unscopedCodes = {
  'project.workshop_scope_required',
  'project.field_traversal_scope_required',
};

Future<TransportCertificationSession> _openDirect(Directory project) async {
  const reader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
    allowedRootPaths: [project.path],
    fileReader: reader,
  );
  final handles = WorkspaceHandleStore();
  final snapshots = ProjectSnapshotLoader(handles: handles);
  final read = AuthoringReadApi(
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
    artifactStore: LocalArtifactStore(
      allowedSourceRoots: [project.path],
      maximumArtifactBytes: maximumAuthoringArtifactBytesV1,
    ),
  );
  final opened = await read.openProject(project.path);
  Future<void> close() async {
    try {
      await mutations.detachWorkspace(opened.workspaceHandle);
    } finally {
      await read.closeWorkspace(opened.workspaceHandle);
    }
  }

  try {
    await mutations.attachProject(
      projectRootPath: project.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
  } on Object {
    await close();
    rethrow;
  }
  return (
    close: close,
    apply: (step, identity) async {
      final bound = await _boundParameters(project, step, (path, media) async {
        final staged = await mutations.stageArtifactFile(
          sourcePath: path,
          declaredMediaType: media,
        );
        return staged.reference;
      });
      final parameters = bound.parameters;
      String? workshopRevision;
      if (step.revisionScope == AuthoringTransportRevisionScope.auto) {
        try {
          workshopRevision = (await mutations.readWorkshopSnapshot(
            opened.projectHandle,
            actionId: step.actionId,
            parameters: parameters,
          )).revision;
        } on ProjectSnapshotException catch (error) {
          if (!_unscopedCodes.contains(error.code)) rethrow;
        }
      }
      final revision =
          workshopRevision ??
          await read.readCatalogRevision(opened.projectHandle) ??
          (await snapshots.load(opened.projectHandle)).revision;
      final plan = await mutations.plan(
        opened.projectHandle,
        _request(
          step,
          identity,
          opened.workspaceHandle.value,
          revision,
          parameters,
          workshopRevision != null ? const {'workshopScope': true} : const {},
        ),
      );
      if (step.planOnly) {
        return (
          receipt: _receipt(plan),
          stagedArtifacts: bound.stagedArtifacts,
        );
      }
      final planId = plan['planId']! as String;
      final confirmation = step.confirm
          ? (await mutations.confirm(
                  opened.projectHandle,
                  planId: planId,
                ))['confirmationToken']!
                as String
          : null;
      final result = await mutations.apply(
        opened.projectHandle,
        planId: planId,
        operationId: identity,
        confirmationToken: confirmation,
      );
      return (
        receipt: _receipt(result),
        stagedArtifacts: bound.stagedArtifacts,
      );
    },
  );
}

Future<TransportCertificationSession> _openEditor(
  Directory project,
  bool measurePlanPreimage,
) async {
  const reader = LocalProjectFileReader();
  final queries = AuthoringQueryAdapter(fileReader: reader);
  final mutations = AuthoringMutationAdapter(
    fileReader: reader,
    queries: queries,
    projectRoots: _ProjectRoot(project.path),
  );
  Future<void> close() async {
    try {
      await mutations.closeAll();
    } finally {
      await queries.closeAll();
    }
  }

  if (measurePlanPreimage) {
    try {
      await mutations.readRevision(project.path);
    } on Object {
      await close();
      rethrow;
    }
  }
  return (
    close: close,
    apply: (step, identity) async {
      final bound = await _boundParameters(project, step, (path, media) async {
        final staged = await mutations.stageArtifact(
          project.path,
          sourcePath: path,
          declaredMediaType: media,
        );
        return staged.reference;
      });
      final expectedRevision =
          step.revisionScope == AuthoringTransportRevisionScope.project
          ? await mutations.readRevision(project.path)
          : null;
      final plan = await mutations.plan(
        project.path,
        actionId: step.actionId,
        parameters: bound.parameters,
        idempotencyKey: identity,
        requestId: identity,
        expectedRevision: expectedRevision,
        dryRun: step.planOnly,
      );
      if (plan.receipt.actionVersion != step.actionVersion) {
        throw StateError('The Editor selected another action version.');
      }
      if (step.planOnly) {
        return (receipt: plan.receipt, stagedArtifacts: bound.stagedArtifacts);
      }
      final confirmation = step.confirm ? await mutations.confirm(plan) : null;
      final result = await mutations.apply(
        plan,
        operationId: identity,
        confirmationToken: confirmation,
      );
      return (receipt: result.receipt, stagedArtifacts: bound.stagedArtifacts);
    },
  );
}

final class _ProjectRoot implements EditorProjectRootLocator {
  const _ProjectRoot(this.path);

  final String path;

  @override
  Future<String> locateForResource(String resourcePath) async => path;
}

AuthoringReceipt _receipt(Map<String, Object?> result) =>
    AuthoringReceipt.fromJson(
      transportEvidenceObject(result['receipt'], 'receipt'),
    );

AuthoringRequest _request(
  AuthoringTransportStep step,
  String identity,
  String workspace,
  String revision,
  Map<String, Object?> parameters,
  Map<String, Object?> extensions,
) => AuthoringRequest(
  requestId: identity,
  actionId: step.actionId,
  actionVersion: step.actionVersion,
  workspaceHandle: workspace,
  parameters: parameters,
  expectedRevision: revision,
  idempotencyKey: identity,
  dryRun: step.planOnly,
  extensions: extensions,
);

Future<
  ({Map<String, Object?> parameters, List<ContentArtifactRef> stagedArtifacts})
>
_boundParameters(
  Directory project,
  AuthoringTransportStep step,
  Future<ContentArtifactRef> Function(String path, String mediaType) stage,
) async {
  final stagedArtifacts = <ContentArtifactRef>[];
  for (final artifact in step.artifacts) {
    final source = await resolveAuthoringArtifact(project, artifact);
    final staged = await stage(source.file.path, artifact.mediaType);
    if (staged != source.reference) {
      throw FormatException(
        'Staged bytes differ from the fixture: ${artifact.path}.',
      );
    }
    stagedArtifacts.add(staged);
  }
  return (
    parameters: step.bindArtifactHandles([
      for (final artifact in stagedArtifacts) artifact.handle,
    ]),
    stagedArtifacts: stagedArtifacts,
  );
}
