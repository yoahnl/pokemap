import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/transport_certification.dart';
import 'package:path/path.dart' as p;

import 'studio_transport_session.dart';

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
  String dart,
) => switch (transport) {
  AuthoringTransport.directApi => _openDirect(project),
  AuthoringTransport.editor => _openStudio(project),
  AuthoringTransport.cli || AuthoringTransport.mcp => _WireSession.open(
    transport,
    project,
    repository,
    dart,
  ),
};

Future<TransportCertificationSession> _openStudio(Directory project) async {
  final studio = await StudioTransportSession.open(project);
  return (
    close: studio.close,
    apply: (step, identity) async {
      final bound = await _boundParameters(project, step, studio.stage);
      final receipt = await studio.run(
        actionId: step.actionId,
        actionVersion: step.actionVersion,
        parameters: bound.parameters,
        operationId: identity,
        preferWorkshop:
            step.revisionScope == AuthoringTransportRevisionScope.auto,
        planOnly: step.planOnly,
        confirm: step.confirm,
      );
      return (receipt: receipt, stagedArtifacts: bound.stagedArtifacts);
    },
  );
}

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
