import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../test/support/game_export_fixture.dart';
import '../../test/support/m3_story_fixture.dart';

const _qa =
    '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109';
const _threeDSource =
    '/Users/karim/Project/avelune project/HGSS 3D Pack/reconstruction-bourg-geon-20261022/doors-wind-20261022/story-prototype-ui';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'prepares and validates the current 2D M3 witness without export',
    () async {
      final root = await Directory('$_qa/current-witnesses')
          .create(recursive: true);
      final sourceParent = await Directory('${root.path}/source-twoD').create();
      final source = await M3StoryFixture.create(parent: sourceParent);
      await prepareGameExportFixture(source);
      await _prepare('twoD', source.directory, root);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'copies and validates the current 3D source without modifying it',
    () async {
      final root = await Directory('$_qa/current-witnesses')
          .create(recursive: true);
      await _prepare('threeD', Directory(_threeDSource), root);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

Future<void> _prepare(String profile, Directory source, Directory root) async {
  final destination = Directory('${root.path}/$profile');
  if (await destination.exists()) {
    throw StateError('An owned witness already exists: ${destination.path}');
  }
  final before = await fingerprintCurrentWitness(source);
  final record = <String, Object?>{
    'schemaVersion': 1,
    'profile': profile,
    'temporalMeaning': 'CURRENT AFTER partial T01 extractions; never AVANT',
    'source': source.path,
    'copy': destination.path,
    'startedAtUtc': DateTime.now().toUtc().toIso8601String(),
    'originalBefore': before,
    'copyPolicy': 'Regular files only; excludes the exact .pokemap history directory, retains asset catalogs and .pokemap-store blobs.',
    'nativeRender': 'not run',
    'export': 'not run',
    'player': 'not run',
    'saveResume': 'not run',
    'mutationAppliedToThreeD': false,
  };
  try {
    await destination.create();
    for (final entry in before['files']! as List<Map<String, Object?>>) {
      final relative = entry['path']! as String;
      final target = File(p.join(destination.path, relative));
      await target.parent.create(recursive: true);
      await File(p.join(source.path, relative)).copy(target.path);
    }
    record['copyBeforeReader'] = await fingerprintCurrentWitness(destination);
    try {
      record['reader'] = await readCurrentWitness(destination);
    } on Object catch (error, stack) {
      record['reader'] = {
        'status': 'refused',
        'type': error.runtimeType.toString(),
        'error': error.toString(),
        'stack': stack.toString(),
      };
    }
  } finally {
    record['originalAfter'] = await fingerprintCurrentWitness(source);
    record['copyAfterReader'] = await fingerprintCurrentWitness(destination);
    record['endedAtUtc'] = DateTime.now().toUtc().toIso8601String();
    record['originalUnchanged'] =
        _tree(record['originalBefore']) == _tree(record['originalAfter']);
    record['copyMatchesOriginalBeforeReader'] =
        _tree(record['originalBefore']) == _tree(record['copyBeforeReader']);
    record['readerDidNotChangeCopy'] =
        _tree(record['copyBeforeReader']) == _tree(record['copyAfterReader']);
    await File('$_qa/t00-current-$profile-preparation.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(record),
      flush: true,
    );
  }
  expect(record['originalUnchanged'], isTrue);
  expect(record['copyMatchesOriginalBeforeReader'], isTrue);
  expect(record['readerDidNotChangeCopy'], isTrue);
  final read = record['reader']! as Map;
  expect(read['status'], 'read', reason: '${read['error']}');
  expect((read['validation']! as Map)['valid'], isTrue);
}

String? _tree(Object? value) =>
    value is Map ? value['treeSha256'] as String? : null;

Future<Map<String, Object?>> fingerprintCurrentWitness(
  Directory directory,
) async {
  final files = <Map<String, Object?>>[];
  if (await directory.exists()) {
    await for (final file in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      final relative = p.relative(file.path, from: directory.path);
      if (p.split(relative).contains('.pokemap')) continue;
      if (file is Link) {
        throw StateError('Symlink in witness input: ${file.path}');
      }
      if (file is! File) continue;
      final bytes = await file.readAsBytes();
      files.add({
        'path': relative,
        'bytes': bytes.length,
        'sha256': sha256.convert(bytes).toString(),
      });
    }
  }
  files.sort((a, b) => (a['path']! as String).compareTo(b['path']! as String));
  return {
    'fileCount': files.length,
    'bytes': files.fold<int>(0, (sum, file) => sum + (file['bytes']! as int)),
    'treeSha256': sha256.convert(utf8.encode(jsonEncode(files))).toString(),
    'files': files,
  };
}

Future<Map<String, Object?>> readCurrentWitness(Directory directory) async {
  const reader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
    allowedRootPaths: [directory.path],
    fileReader: reader,
  );
  final handles = WorkspaceHandleStore();
  final loader = ProjectSnapshotLoader(handles: handles);
  final opener = ProjectOpenService(
    policy: policy,
    fileReader: reader,
    handles: handles,
    initializeSceneOwners: false,
  );
  final api = AuthoringReadApi(openService: opener, snapshotLoader: loader);
  final opened = await api.openProject(directory.path);
  try {
    final snapshot = await loader.load(opened.projectHandle);
    final validation = await api.validateProject(opened.projectHandle);
    if (!validation.valid) {
      throw StateError(
        'Canonical project validation refused: ${jsonEncode(validation.toJson())}',
      );
    }
    ProjectValidator.validate(snapshot.manifest, maps: snapshot.maps);
    for (final map in snapshot.maps) {
      MapValidator.validate(map, projectDialogueContext: snapshot.manifest);
    }
    return {
      'status': 'read',
      'revision': snapshot.revision,
      'validation': validation.toJson(),
      'loadDiagnostics': [
        for (final diagnostic in snapshot.loadDiagnostics) diagnostic.toJson(),
      ],
      'assetClosure': await _assets(directory, snapshot.manifest),
      'maps': [
        for (final map in snapshot.maps)
          {
            'id': map.id,
            'size': map.size.toJson(),
            'warps': [for (final warp in map.warps) warp.toJson()],
            'layers': [
              for (final layer in map.layers)
                {'id': layer.id, 'kind': layer.runtimeType.toString()},
            ],
            'spatialScene': map.spatialScene?.toJson(),
            if (map.spatialScene != null)
              'integrity': _integrity(snapshot.manifest, map),
          },
      ],
      'sceneIds': snapshot.manifest.scenes.map((scene) => scene.id).toList(),
      'newGame': snapshot.manifest.newGame.toJson(),
    };
  } finally {
    opener.closeWorkspace(opened.workspaceHandle);
  }
}

Map<String, Object?> _integrity(ProjectManifest project, MapData map) {
  final report = inspectSpatialMapIntegrity(manifest: project, map: map);
  return {
    'exposedCellCount': report.exposedCellCount,
    'unprovenCellCount': report.unprovenCellCount,
    'groundGaps': [for (final gap in report.groundGaps) gap.toJson()],
    'borderObjectOverlaps': [
      for (final overlap in report.borderObjectOverlaps) overlap.toJson(),
    ],
  };
}

Future<Map<String, Object?>> _assets(
  Directory root,
  ProjectManifest project,
) async {
  final catalogFile = File(p.join(root.path, assetCatalogStorageKey));
  var records = 0;
  if (await catalogFile.exists()) {
    final catalog = AssetCatalog.fromJson(
      jsonDecode(await catalogFile.readAsString()) as Map<String, dynamic>,
    );
    for (final record in catalog.records) {
      final logical = await File(p.join(root.path, record.logicalPath))
          .readAsBytes();
      final blob = await File(
        p.join(root.path, assetBlobStorageKey(record.artifact)),
      ).readAsBytes();
      if (ContentArtifactRef.fromBytes(
                logical,
                mediaType: record.artifact.mediaType,
              ) !=
              record.artifact ||
          ContentArtifactRef.fromBytes(
                blob,
                mediaType: record.artifact.mediaType,
              ) !=
              record.artifact) {
        throw StateError('Artifact mismatch: ${record.id}');
      }
      records++;
    }
  }
  final glbs = <Map<String, Object?>>[];
  for (final model in project.models3d) {
    final bytes = await File(p.join(root.path, model.relativePath))
        .readAsBytes();
    final inspection = const GlbModel3dInspector().inspect(bytes);
    glbs.add({
      'id': model.id,
      'bytes': bytes.length,
      'meshCount': inspection.meshCount,
      'triangleCount': inspection.triangleCount,
    });
  }
  final images = <Map<String, Object?>>[];
  for (final tileset in project.tilesets) {
    final bytes = await File(p.join(root.path, tileset.relativePath))
        .readAsBytes();
    final decoded = image.decodeImage(bytes);
    if (decoded == null) throw StateError('Undecodable atlas: ${tileset.id}');
    images.add({
      'id': tileset.id,
      'bytes': bytes.length,
      'width': decoded.width,
      'height': decoded.height,
    });
  }
  return {
    'verifiedArtifactRecords': records,
    'glbs': glbs,
    'decodedAtlases': images,
    'nativeRendering': false,
  };
}
