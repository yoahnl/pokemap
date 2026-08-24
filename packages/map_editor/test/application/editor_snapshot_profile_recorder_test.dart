import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/services/editor_snapshot_profile_recorder.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';

void main() {
  group('EditorSnapshotProfileRecorder', () {
    test('stays inert when no destination is configured', () {
      final recorder = EditorSnapshotProfileRecorder.resolve(
        environment: const <String, String>{},
      );

      expect(recorder, isNull);
    });

    test('appends one JSON line per snapshot load', () async {
      final directory = await Directory.systemTemp.createTemp('profile-sink-');
      addTearDown(() => directory.delete(recursive: true));
      final destination = '${directory.path}/profile.jsonl';
      final recorder = EditorSnapshotProfileRecorder.resolve(
        environment: <String, String>{
          EditorSnapshotProfileRecorder.destinationVariable: destination,
        },
      );

      expect(recorder, isNotNull);
      recorder!.sinkFor('read')(_profile);

      await recorder.flush();
      final lines = await File(destination).readAsLines();
      expect(lines, hasLength(1));
      final entry = jsonDecode(lines.single) as Map<String, Object?>;
      expect(entry['event'], 'snapshot.load');
      expect(entry['session'], 'read');
      expect(entry['totalUs'], 15000);
      expect(entry['projectionUs'], 5000);
      expect(entry['resourceCount'], 441);
      expect(entry['assetBlobVerifications'], 393);
      expect(entry['revisionHashedBytes'], 31311);
      expect(entry['cacheHit'], false);
    });

    test('falls back to a writable directory when the destination is refused',
        () async {
      final fallback = await Directory.systemTemp.createTemp('profile-fb-');
      addTearDown(() => fallback.delete(recursive: true));
      final announcements = <String>[];

      final recorder = EditorSnapshotProfileRecorder.resolve(
        environment: <String, String>{
          // A path under an existing file can never be created.
          EditorSnapshotProfileRecorder.destinationVariable:
              '/etc/hosts/refused/profile.jsonl',
        },
        fallbackDirectory: fallback,
        announce: announcements.add,
      );

      expect(recorder, isNotNull);
      expect(recorder!.destinationPath, startsWith(fallback.path));
      expect(announcements, hasLength(1));
      expect(announcements.single, contains(recorder.destinationPath));

      recorder.sinkFor('read')(_profile);
      await recorder.flush();

      expect(await File(recorder.destinationPath).readAsLines(), hasLength(1));
    });

    test('a real project open through the query adapter records a load',
        () async {
      final directory = await Directory.systemTemp.createTemp('profile-wire-');
      addTearDown(() => directory.delete(recursive: true));
      await File('${directory.path}/project.json').writeAsString(
        jsonEncode(
          const ProjectManifest(
            name: 'Profile Wiring',
            version: ProjectVersion.v6,
            maps: <ProjectMapEntry>[],
            tilesets: <ProjectTilesetEntry>[],
          ).toJson(),
        ),
        flush: true,
      );
      final destination = '${directory.path}/profile.jsonl';
      final recorder = EditorSnapshotProfileRecorder.resolve(
        environment: <String, String>{
          EditorSnapshotProfileRecorder.destinationVariable: destination,
        },
      );
      final adapter = AuthoringQueryAdapter(
        fileReader: const EditorProjectFileReader(),
        profileRecorder: recorder,
      );
      addTearDown(adapter.closeAll);

      await adapter.open(directory.path);

      await recorder!.flush();
      final lines = await File(destination).readAsLines();
      expect(lines, isNotEmpty);
      final entry = jsonDecode(lines.first) as Map<String, Object?>;
      expect(entry['event'], 'snapshot.load');
      expect(entry['session'], 'read');
      expect(entry['totalUs'], isA<int>());
      expect(entry['resourceCount'], greaterThan(0));
    });
  });
}

const _profile = ProjectSnapshotLoadProfile(
  initialReadMicroseconds: 1000,
  decodeModelMicroseconds: 2000,
  secondObservationMicroseconds: 3000,
  fingerprintMicroseconds: 4000,
  projectionMicroseconds: 5000,
  totalMicroseconds: 15000,
  resourceCount: 441,
  resourceBytes: 78800000,
  cacheHit: false,
  assetBlobVerifications: 393,
  revisionHashedBytes: 31311,
);
