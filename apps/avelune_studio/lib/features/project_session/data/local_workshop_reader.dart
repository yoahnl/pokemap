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
      workshopScope: true,
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
          ? await run(_nativeProjection(descriptor, metadataFields))
          : await catalog.read((catalog) => run(catalog.projectMetadata));
    } finally {
      opener.closeWorkspace(opened.workspaceHandle);
    }
  }
}

ProjectManifest _nativeProjection(
  List<int> descriptor,
  Set<String> metadataFields,
) {
  final decoded = jsonDecode(utf8.decode(descriptor)) as Map<String, dynamic>;
  return ProjectManifest.fromJson({
    'name': decoded['name'],
    'version': decoded['version'] ?? 'v8',
    'maps': const [],
    'tilesets': const [],
    if (decoded.containsKey('settings')) 'settings': decoded['settings'],
    'pokemon': decoded['pokemon'] is Map
        ? {'ruleset': (decoded['pokemon'] as Map)['ruleset']}
        : decoded['pokemon'],
    for (final field in metadataFields)
      if (decoded.containsKey(field)) field: decoded[field],
  });
}
