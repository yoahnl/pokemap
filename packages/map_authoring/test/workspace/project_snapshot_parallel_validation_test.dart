import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/transactions/authoring_payload.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final changeDuringRead in [false, true]) {
    test(
      changeDuringRead
          ? 'bounded warm validation rejects a resource changed during its pass'
          : 'warm validation reads independent stored resources with bounded concurrency',
      () async {
        final directory =
            await Directory.systemTemp.createTemp('snapshot-validation-');
        addTearDown(() => directory.delete(recursive: true));
        final root = await directory.resolveSymbolicLinks();
        const manifest =
            ProjectManifest(name: 'Warm validation', maps: [], tilesets: []);
        final files = <String, List<int>>{
          'project.json': utf8.encode(jsonEncode(manifest.toJson())),
          for (var index = 0; index < 12; index++)
            'assets/source-$index.bin': List<int>.filled(1024, index),
        };
        final payloads = <String, AuthoringPayload>{};
        for (final entry in files.entries) {
          final file = File('$root/${entry.key}');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(entry.value);
          payloads[entry.key] =
              AuthoringPayload.inline(entry.value, storageKey: entry.key);
        }
        const reader = LocalProjectFileReader();
        final started = Completer<void>();
        final release = Completer<void>();
        var activeReads = 0;
        var maximumReads = 0;
        var totalReads = 0;
        Stream<List<int>> openRead(String path) async* {
          activeReads++;
          totalReads++;
          maximumReads = math.max(maximumReads, activeReads);
          if (!started.isCompleted) started.complete();
          try {
            await release.future;
            yield* reader.openRead(projectRoot: root, relativePath: path);
          } finally {
            activeReads--;
          }
        }

        final handles = WorkspaceHandleStore();
        final opened = handles.registerProject(
          projectName: manifest.name,
          initialFingerprint: 'warm-validation',
          readBytes: (path) =>
              reader.readBytes(projectRoot: root, relativePath: path),
          openRead: openRead,
          readIdentity: (path) =>
              reader.readIdentity(projectRoot: root, relativePath: path),
          canReuseSnapshots: true,
        );
        final resourcePaths = {
          'project': 'project.json',
          for (var index = 0; index < 12; index++)
            'asset:$index': 'assets/source-$index.bin',
        };
        final identities = {
          for (final path in [
            ...files.keys.where((path) => path != 'project.json'),
            'project.json'
          ])
            path: (await reader.readIdentity(
                projectRoot: root, relativePath: path))!,
        };
        final snapshot = ProjectSnapshot(
          projectHandle: opened.projectHandle,
          revision: computeNarrativeProjectFingerprint([
            for (final path in files.keys)
              NarrativeProjectFingerprintEntry(
                  relativePath: path,
                  bytes: utf8.encode(payloads[path]!.resourceRevision)),
          ]),
          manifest: manifest,
          maps: const [],
          resourceFingerprints: {
            for (final entry in resourcePaths.entries)
              entry.key: payloads[entry.value]!.resourceRevision,
          },
          resourceBytes: {'project': files['project.json']!},
          resourceStorageKeys: resourcePaths,
          storedResources: {
            for (final entry in resourcePaths.entries)
              if (entry.key != 'project')
                entry.key: ProjectStoredResource(
                  byteLength: payloads[entry.value]!.byteLength,
                  rawSha256: payloads[entry.value]!.rawSha256,
                  resourceRevision: payloads[entry.value]!.resourceRevision,
                ),
          },
        );
        final cache = ProjectSnapshotCache();
        expect(cache.store(snapshot: snapshot, identities: identities),
            ProjectSnapshotCacheAdmission.admitted);
        final pending = cache.lookup(
            handles.resolveProject(opened.projectHandle), opened.projectHandle);
        try {
          await started.future;
          await Future<void>.delayed(Duration.zero);
          expect(maximumReads, 8);
          if (changeDuringRead) {
            await File('$root/assets/source-11.bin')
                .writeAsBytes(List<int>.filled(1024, 99));
          }
          release.complete();
          final resolved = await pending;
          expect(resolved?.revision,
              changeDuringRead ? isNull : snapshot.revision);
          expect(maximumReads, lessThanOrEqualTo(8));
          expect(activeReads, 0);
          if (!changeDuringRead) expect(totalReads, 24);
        } finally {
          if (!release.isCompleted) release.complete();
          await pending;
          handles.closeWorkspace(opened.workspaceHandle);
        }
      },
    );
  }
}
