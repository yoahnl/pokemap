import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/src/ports/project_file_reader.dart';
import 'package:map_authoring/src/workspace/project_open_service.dart';
import 'package:map_authoring/src/workspace/project_snapshot_loader.dart';
import 'package:map_authoring/src/workspace/workspace_handle_store.dart';
import 'package:map_authoring/src/workspace/workspace_policy.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('identical project bytes cannot bind a handle to a sibling root',
      () async {
    final sandbox =
        await Directory.systemTemp.createTemp('mutation-root-binding-');
    addTearDown(() => sandbox.delete(recursive: true));
    final canonical = await sandbox.resolveSymbolicLinks();
    final first = await Directory('$canonical/first').create();
    final second = await Directory('$canonical/second').create();
    final project = ProjectManifest(name: 'Same bytes', maps: [
      for (var i = 0; i < 900; i++)
        ProjectMapEntry(
            id: 'foreign_$i', name: 'Foreign', relativePath: 'missing/$i.json'),
    ], tilesets: const []);
    final bytes = utf8.encode(jsonEncode(project.toJson()));
    await File('${first.path}/project.json').writeAsBytes(bytes);
    await File('${second.path}/project.json').writeAsBytes(bytes);
    final reader = _CountingReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [canonical], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final opened = await ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles)
        .openProject(first.path);
    addTearDown(() => handles.closeWorkspace(opened.workspaceHandle));
    expect(reader.reads, ['project.json']);
    reader.reads.clear();
    final loader = ProjectSnapshotLoader(handles: handles);
    await loader.requireMutationRoot(opened.projectHandle, first.path);
    await expectLater(
        loader.requireMutationRoot(opened.projectHandle, second.path),
        throwsA(isA<WorkspaceHandleException>().having((error) => error.code,
            'code', 'workspace.mutation_binding_mismatch')));
    expect(reader.reads, isEmpty);
    expect(opened.toJson().toString(), isNot(contains(canonical)));
  });
  test('handles without a root authority fail without reading project data',
      () async {
    final handles = WorkspaceHandleStore();
    var reads = 0;
    final opened = handles.registerProject(
        projectName: 'Virtual',
        initialFingerprint: 'unused',
        readBytes: (_) async {
          reads++;
          return [];
        });
    addTearDown(() => handles.closeWorkspace(opened.workspaceHandle));
    await expectLater(
        ProjectSnapshotLoader(handles: handles)
            .requireMutationRoot(opened.projectHandle, '/unknown'),
        throwsA(isA<WorkspaceHandleException>().having((error) => error.code,
            'code', 'workspace.mutation_binding_unavailable')));
    expect(reads, 0);
  });
  test('root authority completion cannot revive a closed handle', () async {
    final handles = WorkspaceHandleStore();
    late RegisteredProjectHandles opened;
    opened = handles.registerProject(
        projectName: 'Closing',
        initialFingerprint: 'unused',
        readBytes: (_) async => [],
        requireMutationRoot: (_) async {
          handles.closeWorkspace(opened.workspaceHandle);
        });
    await expectLater(
        ProjectSnapshotLoader(handles: handles)
            .requireMutationRoot(opened.projectHandle, '/unused'),
        throwsA(isA<WorkspaceHandleException>().having(
            (error) => error.code, 'code', 'workspace.handle_unknown')));
  });
}

class _CountingReader implements ProjectFileReader {
  final reads = <String>[];
  final local = const LocalProjectFileReader();
  @override
  Future<String> canonicalizeDirectory(String path) =>
      local.canonicalizeDirectory(path);
  @override
  Future<List<int>> readBytes(
      {required String projectRoot, required String relativePath}) {
    reads.add(relativePath);
    return local.readBytes(
        projectRoot: projectRoot, relativePath: relativePath);
  }
}
