import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/transport_certification.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

final class TransportCatalogFixturePreparation {
  final _startedAt = DateTime.now().subtract(const Duration(seconds: 1));
  final _projectRoots = <String>{};

  Future<void> prepare(
    Directory project,
    Directory trial,
    List<String> scopes,
  ) async {
    final root = await project.resolveSymbolicLinks();
    final trialRoot = await trial.resolveSymbolicLinks();
    if (root != project.path ||
        trialRoot != trial.path ||
        p.dirname(root) != trialRoot) {
      throw const FormatException('Catalog preparation requires a QA copy.');
    }
    final descriptor = File(p.join(root, 'project.json'));
    WorkingProjectCatalogDescriptor.fromJson(
      transportEvidenceObject(
        jsonDecode(await descriptor.readAsString()),
        'working catalog descriptor',
      ),
    );
    _projectRoots.add(root);

    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final opener = ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
      catalogMetadataFields: const {},
      initializeSceneOwners: false,
    );
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: ProjectSnapshotLoader(handles: handles),
    );
    final opened = await opener.openProject(root);
    try {
      await mutations.attachProject(
        projectRootPath: root,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      await mutations.prepareWorkshopCatalog(opened.projectHandle);
      for (final scope in scopes) {
        await mutations.prepareWorkshopCatalog(
          opened.projectHandle,
          scope: scope,
        );
      }
    } finally {
      try {
        await mutations.detachWorkspace(opened.workspaceHandle);
      } finally {
        opener.closeWorkspace(opened.workspaceHandle);
      }
    }
  }

  Future<void> removeAdmissions() async {
    if (_projectRoots.isEmpty) return;
    final userDirectory =
        Platform.environment[Platform.isWindows ? 'LOCALAPPDATA' : 'HOME'];
    if (userDirectory == null || userDirectory.isEmpty) return;
    await removeCatalogFixtureAdmissions(
      Directory(
        p.join(userDirectory, '.avelune', 'authoring', 'catalog-admissions'),
      ),
      ownedProjectRoots: _projectRoots,
      startedAt: _startedAt,
    );
  }
}

Future<void> removeCatalogFixtureAdmissions(
  Directory directory, {
  required Set<String> ownedProjectRoots,
  required DateTime startedAt,
}) async {
  if (ownedProjectRoots.isEmpty || !await directory.exists()) return;
  if (await directory.resolveSymbolicLinks() != directory.absolute.path) {
    throw const FormatException('Unsafe catalog admissions directory.');
  }
  final recordName = RegExp(r'^[a-f0-9]{64}\.json$');
  final maximumRecordBytes = CatalogStorageLimits().maxUnitBytes;
  await for (final entity in directory.list(followLinks: false)) {
    if (entity is! File || !recordName.hasMatch(p.basename(entity.path))) {
      continue;
    }
    final info = await entity.stat();
    if (info.type != FileSystemEntityType.file ||
        info.size > maximumRecordBytes ||
        info.modified.isBefore(startedAt)) {
      continue;
    }
    try {
      final content = jsonDecode(await entity.readAsString());
      final admission = content is Map ? content['admission'] ?? content : null;
      if (admission is Map &&
          ownedProjectRoots.contains(admission['projectRoot'])) {
        await entity.delete();
      }
    } on FormatException {
      continue;
    } on PathNotFoundException {
      continue;
    }
  }
}
