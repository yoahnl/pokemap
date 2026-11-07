import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('reading and saving a profile each compute the context once', () async {
    final root = await _workingProject(unrelatedGroups: 1);
    addTearDown(() => root.delete(recursive: true));
    final store = GamePackageExportProfileStore(projectRoot: root);
    final reads = await _ContextReads.open(root);

    final read = await IOOverrides.runWithIOOverrides(store.read, reads);
    expect(reads.hashes('maps/start.json'), 1);
    expect(reads.decodes('maps/start.json'), 1);
    expect(reads.hashes('project.json'), 1);
    expect(reads.touches('maps/other.json'), 0);
    final readObjects = reads.objects;
    final readHeads = reads.touches('catalog/HEAD.json');

    reads.reset();
    final saved = await IOOverrides.runWithIOOverrides(
        () => store.save(_profile('Saved'),
            expectedProfileRevision: read.profileRevision,
            expectedContextRevision: read.contextRevision),
        reads);
    expect(reads.hashes('maps/start.json'), 1);
    expect(reads.decodes('maps/start.json'), 1);
    expect(reads.hashes('project.json'), 1);
    expect(reads.touches('maps/other.json'), 0);
    expect(reads.objects, readObjects);
    expect(reads.touches('catalog/HEAD.json'), readHeads);
    expect(saved.contextRevision, read.contextRevision);
    expect((await store.read()).profile, _profile('Saved'));
  });

  test('context work reads index pages, not unrelated project metadata',
      () async {
    Future<int> objectReads(int unrelatedGroups) async {
      final root = await _workingProject(unrelatedGroups: unrelatedGroups);
      try {
        final reads = await _ContextReads.open(root);
        await IOOverrides.runWithIOOverrides(
            GamePackageExportProfileStore(projectRoot: root).read, reads);
        return reads.objects;
      } finally {
        await root.delete(recursive: true);
      }
    }

    const unrelated = 400;
    expect(await objectReads(1), lessThan(unrelated ~/ 20));
    expect(await objectReads(unrelated), lessThan(unrelated ~/ 20));
  });

  test('a stale context is still refused right before the profile rename',
      () async {
    final root = await _workingProject(unrelatedGroups: 1);
    addTearDown(() => root.delete(recursive: true));
    final store = GamePackageExportProfileStore(projectRoot: root);
    final read = await store.read();
    await File('${root.path}/maps/start.json').writeAsString(
        jsonEncode(_map('start').copyWith(name: 'Changed start').toJson()));
    await expectLater(
        store.save(_profile('Stale'),
            expectedProfileRevision: read.profileRevision,
            expectedContextRevision: read.contextRevision),
        throwsA(isA<GamePackageExportException>()
            .having((e) => e.code, 'code', 'exportProfileStale')));
    expect(await store.profileFile.exists(), isFalse);
    expect(
        (await store.profileFile.parent.list().toList())
            .whereType<Directory>()
            .where((entry) =>
                entry.path.split('/').last.startsWith('export-profile-')),
        isEmpty);
  });
}

Future<Directory> _workingProject({required int unrelatedGroups}) async {
  final root = await Directory.systemTemp.createTemp('export-profile-cost-');
  await Directory('${root.path}/maps').create();
  for (final id in ['start', 'other']) {
    await File('${root.path}/maps/$id.json')
        .writeAsString(jsonEncode(_map(id).toJson()));
  }
  final project = ProjectManifest(
    name: 'Profile cost',
    version: ProjectVersion.v9,
    maps: const [
      ProjectMapEntry(
          id: 'start', name: 'Start', relativePath: 'maps/start.json'),
      ProjectMapEntry(
          id: 'other', name: 'Other', relativePath: 'maps/other.json'),
    ],
    tilesets: const [],
    groups: [
      for (var i = 0; i < unrelatedGroups; i++)
        ProjectMapGroup(
            id: 'group-$i', name: 'Unrelated $i', type: MapGroupType.route),
    ],
    settings: const ProjectSettings(dimension: ProjectDimension.threeD),
    newGame: const ProjectNewGameConfig(enabled: true, startMapId: 'start'),
  );
  final projectFile = File('${root.path}/project.json');
  await projectFile.writeAsString(jsonEncode(project.toJson()));
  final store = await CatalogStorageStore.open(projectRoot: root.path);
  await WorkingProjectCatalog.create(
      store: store,
      projectId: 'profile-cost',
      project: project,
      expectedProjectRevision:
          await store.gateway.readResourceRevision('project.json'));
  return root;
}

MapData _map(String id) => MapData(
    id: id,
    name: id,
    version: ProjectVersion.v9,
    size: const GridSize(width: 4, height: 4),
    spatialScene: MapSpatialScene(width: 4, depth: 4));

GamePackageExportProfile _profile(String title) => GamePackageExportProfile(
      gameId: 'games.example.cost',
      gameVersion: '1.0.0',
      title: title,
      authorName: 'Yoahn',
      defaultLocale: 'fr',
      supportedLocales: ['fr'],
    );

final class _ContextReads extends IOOverrides {
  _ContextReads._(this._roots);

  static Future<_ContextReads> open(Directory root) async =>
      _ContextReads._({root.path, await root.resolveSymbolicLinks()});

  final Set<String> _roots;
  final _hashes = <String, int>{};
  final _decodes = <String, int>{};
  final _touches = <String, int>{};
  var objects = 0;

  int hashes(String path) => _hashes[path] ?? 0;
  int decodes(String path) => _decodes[path] ?? 0;
  int touches(String path) => _touches[path] ?? 0;

  void reset() {
    _hashes.clear();
    _decodes.clear();
    _touches.clear();
    objects = 0;
  }

  String? _relative(String path) {
    for (final root in _roots) {
      if (path.startsWith('$root/')) return path.substring(root.length + 1);
    }
    return null;
  }

  @override
  File createFile(String path) {
    final file = super.createFile(path);
    final relative = _relative(path);
    if (relative == null ||
        !(relative == 'project.json' ||
            relative.startsWith('maps/') ||
            relative.startsWith('catalog/'))) {
      return file;
    }
    return _CountedFile(file, relative, this);
  }

  void _read(String relative, Map<String, int> counter) {
    _touches[relative] = touches(relative) + 1;
    counter[relative] = (counter[relative] ?? 0) + 1;
    if (relative.startsWith('catalog/objects/')) objects++;
  }
}

final class _CountedFile implements File {
  _CountedFile(this._delegate, this._relative, this._reads);

  final File _delegate;
  final String _relative;
  final _ContextReads _reads;

  @override
  String get path => _delegate.path;

  @override
  bool get isAbsolute => _delegate.isAbsolute;

  @override
  File get absolute => _delegate.absolute;

  @override
  Directory get parent => _delegate.parent;

  @override
  Uri get uri => _delegate.uri;

  @override
  Future<bool> exists() => _delegate.exists();

  @override
  Future<FileStat> stat() => _delegate.stat();

  @override
  Future<int> length() => _delegate.length();

  @override
  Future<String> resolveSymbolicLinks() => _delegate.resolveSymbolicLinks();

  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) =>
      _delegate.open(mode: mode);

  @override
  Stream<List<int>> openRead([int? start, int? end]) {
    _reads._read(_relative, _reads._hashes);
    return _delegate.openRead(start, end);
  }

  @override
  Future<Uint8List> readAsBytes() {
    _reads._read(_relative, _reads._decodes);
    return _delegate.readAsBytes();
  }

  @override
  Future<String> readAsString({Encoding encoding = utf8}) {
    _reads._read(_relative, _reads._decodes);
    return _delegate.readAsString(encoding: encoding);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
