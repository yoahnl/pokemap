import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_project_reader.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
      'project opening and scope extension read bounded metadata on one snapshot',
      () async {
    final root = await Directory.systemTemp.createTemp('metadata-scope-');
    addTearDown(() => root.delete(recursive: true));
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    final project = ProjectManifest(
        name: 'Scoped open',
        maps: const [],
        tilesets: const [],
        groups: const [
          ProjectMapGroup(
              id: 'selected', name: 'Selected', type: MapGroupType.city)
        ],
        dialogueFolders: [
          for (var index = 0; index < 600; index++)
            ProjectDialogueFolder(id: 'folder-$index', name: 'Folder $index')
        ],
        globalProperties: {
          'unrelated': 'x' * 200000
        });
    await WorkingProjectCatalog.create(
        store: store, projectId: 'metadata-scope', project: project);
    final reader = _CountingReader();
    final handles = WorkspaceHandleStore();
    final opener = ProjectOpenService(
        policy: await WorkspacePolicy.create(
            allowedRootPaths: [root.path], fileReader: reader),
        fileReader: reader,
        handles: handles,
        catalogMetadataFields: {});
    final opened = await opener.openProject(root.path);
    addTearDown(() => opener.closeWorkspace(opened.workspaceHandle));
    expect(reader.sections, [r'$shell']);
    reader.sections.clear();
    final catalog = (await opener.catalogProject(opened.projectHandle))!;
    expect(reader.sections, [r'$shell']);
    reader.sections.clear();
    final expanded = await catalog.withMetadataFields({'groups'});
    expect(expanded.catalog.projectMetadata.groups, project.groups);
    expect(expanded.catalog.projectMetadata.dialogueFolders, isEmpty);
    expect(expanded.catalog.projectMetadata.globalProperties, isEmpty);
    expect(
        identical(expanded.catalog.snapshot, catalog.catalog.snapshot), isTrue);
    expect(reader.sections, [r'$shell', r'$projectDefinition']);
    reader.sections.clear();
    expect(await expanded.readMetadata({'groups'}),
        expanded.catalog.projectMetadata);
    expect(reader.sections, isEmpty);
    final replacement = PortableCatalogPublication.encodeProject(
        project.copyWith(name: 'Changed'));
    await store.publish(replacement.storage,
        expectedRootRevision: expanded.catalog.snapshot.root.sha256);
    await expectLater(
        expanded.readMetadata({'groups'}),
        throwsA(isA<CatalogStorageException>().having(
            (error) => error.code, 'code', 'catalog.revision_conflict')));
  });

  test('working scope extension checks generation again after reading units',
      () async {
    final root = await Directory.systemTemp.createTemp('metadata-conflict-');
    addTearDown(() => root.delete(recursive: true));
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    final project = ProjectManifest(
        name: 'Generation',
        maps: const [],
        tilesets: const [],
        groups: const [
          ProjectMapGroup(
              id: 'selected', name: 'Selected', type: MapGroupType.city)
        ]);
    final working = await WorkingProjectCatalog.create(
        store: store, projectId: 'generation', project: project);
    final reader = _CountingReader();
    final guardedStore = CatalogStorageStore(
        projectRoot: root.path, reader: reader, gateway: store.gateway);
    final catalog = (await CatalogProjectReader.open(
        store: guardedStore,
        descriptor: working.descriptor.toJson(),
        metadataFields: {}))!;
    final replacement = PortableCatalogPublication.encodeProject(
        project.copyWith(name: 'Replacement'));
    reader.onDefinition = () async {
      reader.onDefinition = null;
      await store.publish(replacement.storage,
          expectedRootRevision: working.root.sha256);
    };
    await expectLater(
        catalog.withMetadataFields({'groups'}),
        throwsA(isA<CatalogStorageException>().having(
            (error) => error.code, 'code', 'catalog.revision_conflict')));
  });
}

final class _CountingReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final sections = <String>[];
  Future<void> Function()? onDefinition;
  final _local = const LocalProjectFileReader();

  @override
  bool get supportsStreamingResources => true;

  @override
  Future<String> canonicalizeDirectory(String path) =>
      _local.canonicalizeDirectory(path);

  @override
  Future<ProjectResourceProbe> probeResource(
          {required String projectRoot, required String relativePath}) =>
      _local.probeResource(
          projectRoot: projectRoot, relativePath: relativePath);

  @override
  Future<List<int>> readBytes(
          {required String projectRoot, required String relativePath}) =>
      _local.readBytes(projectRoot: projectRoot, relativePath: relativePath);

  @override
  Stream<List<int>> openRead(
      {required String projectRoot, required String relativePath}) async* {
    final bytes = await _local
        .openRead(projectRoot: projectRoot, relativePath: relativePath)
        .expand((chunk) => chunk)
        .toList();
    if (relativePath.startsWith('catalog/objects/')) {
      final object = jsonDecode(utf8.decode(bytes)) as Map;
      if (object['type'] == 'unit') {
        final section = (object['payload'] as Map)['section'] as String;
        sections.add(section);
        if (section == r'$projectDefinition') await onDefinition?.call();
      }
    }
    yield bytes;
  }
}
