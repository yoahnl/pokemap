import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../domain/project_session.dart';
import 'studio_project_document_revision.dart';

final class LocalWorkshopReader {
  const LocalWorkshopReader(
    this.session, {
    this.reader = const LocalProjectFileReader(),
  });

  final ProjectSession session;
  final ProjectFileReader reader;

  Future<T> read<T>({
    required Set<String> metadataFields,
    required Future<T> Function(
      ProjectManifest project,
      ProjectWorkspaceAccess access,
      String revision,
    )
    operation,
  }) async {
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final opener = ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
      catalogMetadataFields: metadataFields,
    );
    final opened = await opener.openProject(session.directoryPath);
    try {
      final access = handles.resolveProject(opened.projectHandle);
      final descriptor = await access.readBytes('project.json');
      final catalog = await opener.catalogProject(opened.projectHandle);
      final head = catalog != null && !catalog.readOnly
          ? await access.readBytes(CatalogStorageStore.headStorageKey)
          : null;
      final revision = studioProjectDocumentRevision(
        descriptorBytes: descriptor,
        headBytes: head,
      );
      Future<T> run(ProjectManifest project) async {
        final result = await operation(project, access, revision);
        if (studioProjectDocumentRevision(
              descriptorBytes: await access.readBytes('project.json'),
              headBytes: head == null
                  ? null
                  : await access.readBytes(CatalogStorageStore.headStorageKey),
            ) !=
            revision) {
          throw StateError(
            'Le projet a changé pendant la lecture de l’atelier. Rechargez-le.',
          );
        }
        return result;
      }

      return catalog == null
          ? await run(
              ProjectManifest.fromJson(
                jsonDecode(utf8.decode(descriptor)) as Map<String, dynamic>,
              ),
            )
          : await catalog.read((catalog) => run(catalog.projectMetadata));
    } finally {
      opener.closeWorkspace(opened.workspaceHandle);
    }
  }
}
