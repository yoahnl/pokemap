import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_metadata_documents.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_narrative_event_documents.dart';
import 'package:map_core/map_core.dart';

Future<void> main(List<String> arguments) async {
  final root = await Directory(arguments.first).create(recursive: true);
  final store = await CatalogStorageStore.open(projectRoot: root.path);
  if (arguments.contains('--inspect-context')) {
    final snapshot = (await store.openRoot((await store.readHead())!)).snapshot;
    stdout.writeln(jsonEncode({
      'metadataRevision': await store.requireMetadataContextAdmission(snapshot),
    }));
    return;
  }
  const project =
      ProjectManifest(name: 'Metadata context', maps: [], tilesets: []);
  final missingWindow = arguments.contains('--verify-no-window-api');
  final missingV3 = arguments.contains('--verify-unprepared-v3-api');
  final v3Race = arguments.contains('--verify-v3-race-api');
  if (missingV3 || v3Race) {
    final publication = PortableCatalogPublication.encodeProject(project);
    final units = CatalogSnapshot.readAllSync(
            root: publication.storage.root,
            readObject: (reference) =>
                publication.storage.objects[reference.sha256]!,
            limits: store.limits)
        .units;
    await store.publish(
        CatalogStorageBuilder(limits: store.limits).build([
          ...units,
          ...CatalogMetadataDocuments.initialize(units).where(
              (unit) => unit.key != CatalogNarrativeEventDocuments.indexKey),
        ]),
        expectedRootRevision: null);
    await store.gateway.withExclusiveWriteLock(() =>
        CatalogGenerationRetention(store: store)
            .bindProjectUnderLock('metadata-context'));
    await File('${root.path}/project.json').writeAsString(jsonEncode(
        WorkingProjectCatalogDescriptor(projectId: 'metadata-context')
            .toJson()));
    final history = await FileAuthoringHistoryStore.open(
        projectRoot: root.path, incrementalWrites: true);
    await history.ensureRetentionWindowIfEmpty('metadata-context');
  } else {
    await WorkingProjectCatalog.create(
        store: store, projectId: 'metadata-context', project: project);
  }
  if (!arguments.contains('--verify-api') &&
      !missingWindow &&
      !missingV3 &&
      !v3Race) {
    return;
  }
  const reader = LocalProjectFileReader();
  final handles = WorkspaceHandleStore();
  final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path], fileReader: reader);
  final opened = await ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
      catalogMetadataFields: {}).openProject(root.path);
  final catalogReader = _HeadProbeReader();
  final api = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: ProjectSnapshotLoader(handles: handles),
      catalogFileReader: catalogReader);
  await api.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle);
  try {
    final originalRoot = await store.readHead();
    if (v3Race) {
      await api.prepareWorkshopCatalog(opened.projectHandle);
      final stableHead =
          await File('${root.path}/catalog/HEAD.json').readAsBytes();
      final tree = jsonDecode(await _projectTree(root)) as Map<String, dynamic>;
      final admissions = await _projectAdmissions(root.path);
      final injectedHead = CatalogStorageStore.encodeHead(originalRoot!);
      final expectedTree = canonicalAuthoringJson({
        ...tree,
        '/catalog/HEAD.json': base64.encode(injectedHead),
      });
      for (var attempt = 0; attempt < 2; attempt++) {
        var probes = 0;
        catalogReader.beforeHeadProbe = () async {
          if (++probes == 2) {
            await File('${root.path}/catalog/HEAD.json')
                .writeAsBytes(injectedHead);
          }
        };
        Object? failure;
        try {
          await api.prepareWorkshopDocument(opened.projectHandle,
              scope: 'metadataContext');
        } on Object catch (error) {
          failure = error;
        } finally {
          catalogReader.beforeHeadProbe = null;
        }
        if (failure is! CatalogStorageException ||
            failure.code != 'catalog.preparation_required' ||
            probes != 2 ||
            expectedTree != await _projectTree(root) ||
            admissions != await _projectAdmissions(root.path)) {
          throw StateError(jsonEncode({
            'expected': 'catalog.preparation_required',
            'actual': failure.toString(),
            'headProbes': probes,
            'onlyInjectedHeadChanged': expectedTree == await _projectTree(root),
            'admissionsPreserved':
                admissions == await _projectAdmissions(root.path)
          }));
        }
        await File('${root.path}/catalog/HEAD.json').writeAsBytes(stableHead);
      }
    }
    if (missingWindow || missingV3) {
      final windowType = await FileSystemEntity.type(
          '${root.path}/.pokemap/authoring/history-retention.json',
          followLinks: false);
      if (missingWindow && windowType != FileSystemEntityType.notFound ||
          missingV3 && windowType != FileSystemEntityType.file) {
        throw StateError('Invalid prerequisite fixture');
      }
      final snapshot = (await store.openRoot(originalRoot!)).snapshot;
      if (missingV3 && await store.metadataIndexPrepared(snapshot)) {
        throw StateError('The legacy fixture unexpectedly has a v3 admission');
      }
      final expectedCode = missingWindow
          ? 'history.preparation_required'
          : 'catalog.preparation_required';
      final tree = await _projectTree(root);
      final admissions = await _projectAdmissions(root.path);
      for (var attempt = 0; attempt < 2; attempt++) {
        Object? failure;
        try {
          await api.prepareWorkshopDocument(opened.projectHandle,
              scope: 'metadataContext');
        } on Object catch (error) {
          failure = error;
        }
        final code = switch (failure) {
          CatalogStorageException error => error.code,
          AuthoringHistoryException error => error.code,
          _ => failure?.toString(),
        };
        final treePreserved = tree == await _projectTree(root);
        final admissionsPreserved =
            admissions == await _projectAdmissions(root.path);
        if (code != expectedCode || !treePreserved || !admissionsPreserved) {
          throw StateError(jsonEncode({
            'expected': expectedCode,
            'actual': code,
            'treePreserved': treePreserved,
            'admissionsPreserved': admissionsPreserved,
            'headPreserved': await store.readHead() == originalRoot
          }));
        }
      }
    }
    await api.prepareWorkshopCatalog(opened.projectHandle);
    if (missingV3 && await store.readHead() == originalRoot) {
      throw StateError(
          'Explicit default preparation did not normalize the legacy fixture');
    }
    final snapshot = (await store.openRoot((await store.readHead())!)).snapshot;
    if (await store.metadataContextRevision(snapshot) != null) {
      throw StateError('Default preparation activated metadata context');
    }
    final before = await File('${root.path}/catalog/HEAD.json').readAsBytes();
    final result = await api.prepareWorkshopDocument(opened.projectHandle,
        scope: 'metadataContext');
    if (result['scope'] != 'explicitCatalogMetadataContext' ||
        result['contextVersion'] != 1 ||
        result['metadataRevision'] !=
            await store.requireMetadataContextAdmission(snapshot) ||
        base64.encode(
                await File('${root.path}/catalog/HEAD.json').readAsBytes()) !=
            base64.encode(before)) {
      throw StateError('The explicit metadata context contract differs');
    }
    final tree = await _projectTree(root);
    final admissions = await _projectAdmissions(root.path);
    final repeated = await api.prepareWorkshopDocument(opened.projectHandle,
        scope: 'metadataContext');
    if (canonicalAuthoringJson(repeated) != canonicalAuthoringJson(result) ||
        tree != await _projectTree(root) ||
        admissions != await _projectAdmissions(root.path)) {
      throw StateError('Repeated context preparation changed durable state');
    }
    stdout.writeln(jsonEncode(result));
  } finally {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
  }
}

Future<String> _projectTree(Directory root) async => canonicalAuthoringJson({
      await for (final entity in root.list(recursive: true, followLinks: false))
        entity.path.substring(root.path.length): entity is File
            ? base64.encode(await entity.readAsBytes())
            : entity is Directory
                ? 'directory'
                : 'link',
    });

Future<String> _projectAdmissions(String projectRoot) async {
  final home =
      Platform.environment[Platform.isWindows ? 'LOCALAPPDATA' : 'HOME'];
  final directory = Directory('$home/.avelune/authoring/catalog-admissions');
  if (!await directory.exists()) return '{}';
  final records = <String, String>{};
  await for (final entity in directory.list()) {
    if (entity is! File || !entity.path.endsWith('.json')) continue;
    final String source;
    try {
      source = await entity.readAsString();
    } on PathNotFoundException {
      continue;
    }
    final value = jsonDecode(source) as Map;
    if (value['projectRoot'] == projectRoot ||
        (value['admission'] as Map?)?['projectRoot'] == projectRoot) {
      records[entity.path] = source;
    }
  }
  return canonicalAuthoringJson(records);
}

final class _HeadProbeReader
    implements
        ProjectFileReader,
        ProjectResourceProbeReader,
        ProjectResourceStreamReader {
  final _delegate = const LocalProjectFileReader();
  Future<void> Function()? beforeHeadProbe;

  @override
  Future<String> canonicalizeDirectory(String path) =>
      _delegate.canonicalizeDirectory(path);

  @override
  Future<List<int>> readBytes(
          {required String projectRoot, required String relativePath}) =>
      _delegate.readBytes(projectRoot: projectRoot, relativePath: relativePath);

  @override
  Future<ProjectResourceProbe> probeResource(
      {required String projectRoot, required String relativePath}) async {
    if (relativePath == CatalogStorageStore.headStorageKey) {
      await beforeHeadProbe?.call();
    }
    return _delegate.probeResource(
        projectRoot: projectRoot, relativePath: relativePath);
  }

  @override
  bool get supportsStreamingResources => true;

  @override
  Stream<List<int>> openRead(
          {required String projectRoot, required String relativePath}) =>
      _delegate.openRead(projectRoot: projectRoot, relativePath: relativePath);
}
