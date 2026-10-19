import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
      'publication beginning during capture invalidates the assembled snapshot',
      () async {
    final handles = WorkspaceHandleStore();
    var pending = false;
    final bytes = utf8.encode(jsonEncode(
        const ProjectManifest(name: 'Guarded', maps: [], tilesets: [])
            .toJson()));
    final registered = handles.registerProject(
        projectName: 'Guarded',
        initialFingerprint: 'initial',
        readBytes: (path) async {
          if (path != 'project.json') {
            throw const WorkspaceAccessException(
                'workspace.file_unavailable', 'Missing');
          }
          pending = true;
          return bytes;
        },
        requireReadableProject: () async {
          if (pending) throw StateError('publication pending');
        });
    await expectLater(
        ProjectSnapshotLoader(handles: handles).load(registered.projectHandle),
        throwsA(isA<StateError>()));
  });

  for (final presentation in [false, true]) {
    test(
        'a pending publication blocks ${presentation ? 'presentation' : 'cached project'} before reading content',
        () async {
      final handles = WorkspaceHandleStore();
      var pending = false;
      var reads = 0;
      final bytes = utf8.encode(jsonEncode(
          const ProjectManifest(name: 'Guarded', maps: [], tilesets: [])
              .toJson()));
      final registered = handles.registerProject(
        projectName: 'Guarded',
        initialFingerprint: 'initial',
        canReuseSnapshots: true,
        readIdentity: (path) async => path == 'project.json'
            ? ProjectResourceIdentity(
                scope: 'guarded',
                relativePath: path,
                byteLength: bytes.length,
                modifiedAtMicros: 1)
            : null,
        probeResource: (path) async => const ProjectResourceProbe.missing(),
        readBytes: (path) async {
          reads++;
          if (path == 'project.json') return bytes;
          throw const WorkspaceAccessException(
              'workspace.file_unavailable', 'Missing');
        },
        requireReadableProject: () async {
          if (pending) throw StateError('publication pending');
        },
      );
      final loader = ProjectSnapshotLoader(handles: handles);
      if (!presentation) await loader.load(registered.projectHandle);
      final before = reads;
      pending = true;
      await expectLater(
          presentation
              ? loader.loadPresentationDraft(registered.projectHandle)
              : loader.load(registered.projectHandle,
                  cacheValidation: ProjectSnapshotCacheValidation.session),
          throwsA(isA<StateError>().having(
              (error) => error.message, 'message', 'publication pending')));
      expect(reads, before);
      pending = false;
      final snapshot = await loader.load(registered.projectHandle);
      expect(snapshot.manifest.name, 'Guarded');
    });
  }
}
