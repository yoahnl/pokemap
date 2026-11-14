import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../tool/create_example_project.dart';
import 'border_profile_loading_sources.dart';

final class BorderFixture {
  BorderFixture(this.root, this.sessions, this.session);

  final Directory root;
  final LocalProjectSessionAdapter sessions;
  ProjectSession session;
  late LocalMapWorkspaceAdapter maps;
  late MapWorkspaceController workspace;
  late LocalResourceAdapter resources;
  bool _open = false;

  static Future<BorderFixture> create({required int unrelated}) async {
    final root = await Directory.systemTemp.createTemp(
      'studio_border_profiles_',
    );
    await writeExampleProject(root);
    for (final id in ['jardin', 'clairiere']) {
      final mapFile = File('${root.path}/maps/$id.json');
      final map = MapData.fromJson(
        jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>,
      );
      await mapFile.writeAsString(
        jsonEncode(
          MapData(
            id: map.id,
            name: map.name,
            version: ProjectVersion.v9,
            size: const GridSize(width: 8, height: 6),
            spatialScene: MapSpatialScene(
              width: 8,
              depth: 6,
              heightLevels: List.filled(48, 0),
            ),
          ).toJson(),
        ),
      );
    }
    final file = File('${root.path}/project.json');
    final original = ProjectManifest.fromJson(
      jsonDecode(await file.readAsString()) as Map<String, dynamic>,
    );
    final names = [
      'target',
      'other',
      for (var index = 0; index < unrelated; index++)
        'u${index.toString().padLeft(4, '0')}',
    ];
    await file.delete();
    await WorkingProjectCatalog.create(
      store: await CatalogStorageStore.open(projectRoot: root.path),
      projectId: 'studio-border-profiles-test',
      project: original.copyWith(
        version: ProjectVersion.v9,
        settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile(),
        ),
        models3d: [
          for (final name in names) ...[
            borderModel('piece_${name}_a'),
            borderModel('piece_${name}_b'),
          ],
        ],
        borderCatalog: ProjectBorderCatalog(
          formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
          records: [
            for (final name in names)
              borderBlueprint('cliff_$name', [
                'piece_${name}_a',
                'piece_${name}_b',
              ]),
          ],
        ),
        resourceLibraryCatalog: ResourceLibraryCatalog(
          families: [ResourceFamily(id: 'family_cliffs', name: 'Falaises')],
          entries: [
            ResourceLibraryEntry(
              resourceKind: 'borderBlueprint',
              resourceId: 'cliff_target',
              familyId: 'family_cliffs',
            ),
          ],
        ),
      ),
    );
    final sessions = LocalProjectSessionAdapter();
    final session = await sessions.open(await root.resolveSymbolicLinks());
    expect(session.storage, ProjectSessionStorage.workingCatalog);
    return BorderFixture(root, sessions, session);
  }

  Future<void> openWorkspace() async {
    maps = LocalMapWorkspaceAdapter();
    workspace = MapWorkspaceController(session, maps);
    await workspace.initialize();
    expect(workspace.error, isNull);
    resources = LocalResourceAdapter(session: session, mapAdapter: maps);
    _open = true;
  }

  Map<String, File> blockedPieceFiles() {
    final blocked = <String, File>{};
    for (final file in root.listSync(recursive: true).whereType<File>()) {
      if (!file.path.contains('/catalog/objects/')) continue;
      final raw = jsonDecode(file.readAsStringSync());
      if (raw is! Map || raw['type'] != 'leaf' || raw['entries'] is! List) {
        continue;
      }
      final entries = raw['entries'] as List;
      if (entries.isNotEmpty &&
          entries.every((entry) {
            final id = '${entry['key']['id']}';
            return id.startsWith('piece_u') || id.startsWith('piece_other');
          })) {
        blocked[file.path] = file;
      }
    }
    return blocked;
  }

  Future<int> guarded(
    Map<String, File> blocked,
    Future<void> Function() body,
  ) async {
    final attempts = <String>[];
    var reads = 0;
    final outside = Zone.current;
    await IOOverrides.runZoned(
      body,
      createFile: (path) {
        if (path.contains('/catalog/objects/') &&
            !const {
              'leaf',
              'branch',
            }.contains(outside.run(() => storedObjectType(File(path))))) {
          reads++;
        }
        final original = blocked[path];
        return original == null
            ? outside.run(() => File(path))
            : _UnreadableFile(original, attempts);
      },
    );
    expect(attempts, isEmpty);
    return reads;
  }

  Future<void> mutate(String action, Map<String, Object?> parameters) async {
    final revision = await resources.captureResourceRevision();
    final preparation = await resources.prepareOperation(
      action,
      parameters,
      expectedSnapshotRevision: revision,
    );
    final receipt = await resources.applyPrepared(preparation);
    workspace.acceptResources(receipt.before, receipt.manifest);
  }

  Future<void> reopen() async {
    await _close();
    await sessions.close(session);
    session = await sessions.open(await root.resolveSymbolicLinks());
    await openWorkspace();
  }

  Future<void> _close() async {
    if (!_open) return;
    _open = false;
    await resources.dispose();
    workspace.dispose();
  }

  Future<void> dispose() async {
    await _close();
    await sessions.close(session);
    await root.delete(recursive: true);
  }
}

class _UnreadableFile implements File {
  _UnreadableFile(this.delegate, this.attempts);
  final File delegate;
  final List<String> attempts;
  Never deny() {
    attempts.add(path);
    throw StateError('Unrelated border piece read: $path');
  }

  @override
  String get path => delegate.path;
  @override
  Uri get uri => delegate.uri;
  @override
  bool get isAbsolute => delegate.isAbsolute;
  @override
  File get absolute => delegate.absolute;
  @override
  Directory get parent => delegate.parent;
  @override
  Future<Uint8List> readAsBytes() async => deny();
  @override
  Future<String> readAsString({Encoding encoding = utf8}) async => deny();
  @override
  Stream<List<int>> openRead([int? start, int? end]) => deny();
  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) async =>
      deny();
  @override
  Future<bool> exists() => delegate.exists();
  @override
  Future<FileStat> stat() => delegate.stat();
  @override
  Future<String> resolveSymbolicLinks() => delegate.resolveSymbolicLinks();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
