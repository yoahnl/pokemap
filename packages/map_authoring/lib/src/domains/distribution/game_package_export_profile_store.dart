import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;

import '../../ports/project_file_reader.dart';
import '../../ports/game_package_export_profile_api_port.dart';
import '../../support/authoring_fingerprint.dart';
import '../../catalog_storage/catalog_storage_store.dart';
import '../../workspace/catalog/catalog_project_reader.dart';

final class GamePackageExportProfileStore {
  const GamePackageExportProfileStore({required this.projectRoot});

  final Directory projectRoot;
  static final Map<String, Future<void>> _writers = {};

  File get profileFile =>
      File(p.join(projectRoot.path, '.pokemap', 'export-profile-v1.json'));

  Future<GamePackageExportProfile?> load() async {
    await _checkSidecar();
    return await profileFile.exists()
        ? GamePackageExportProfile.decodeUtf8(await profileFile.readAsBytes())
        : null;
  }

  Future<GamePackageExportProfileSnapshot> read() async {
    await _checkSidecar();
    final bytes =
        await profileFile.exists() ? await profileFile.readAsBytes() : null;
    final profile =
        bytes == null ? null : GamePackageExportProfile.decodeUtf8(bytes);
    return GamePackageExportProfileSnapshot(
        profile: profile,
        profileRevision: _profileRevision(bytes),
        contextRevision: await _contextRevision(profile));
  }

  Future<GamePackageExportProfileSnapshot> validate(
      GamePackageExportProfile profile) async {
    await _checkSidecar();
    final bytes =
        await profileFile.exists() ? await profileFile.readAsBytes() : null;
    return GamePackageExportProfileSnapshot(
        profile: profile,
        profileRevision: _profileRevision(bytes),
        contextRevision: await _contextRevision(profile));
  }

  Future<GamePackageExportProfileSnapshot> save(
    GamePackageExportProfile profile, {
    String? expectedProfileRevision,
    String? expectedContextRevision,
  }) async {
    final baseline = await validate(profile);
    final profileRevision = expectedProfileRevision ?? baseline.profileRevision;
    final contextRevision = expectedContextRevision ?? baseline.contextRevision;
    return _withWriteLock(() async {
      final current = await validate(profile);
      _requireRevisions(current, profileRevision, contextRevision);
      await _checkSidecar();
      await profileFile.parent.create();
      final temporaryDirectory =
          await profileFile.parent.createTemp('export-profile-');
      final temporary = File(p.join(temporaryDirectory.path, 'profile.json'));
      final encoded = CanonicalJson.encodeUtf8(profile.toJson());
      try {
        await temporary.writeAsBytes(encoded, flush: true);
        if (GamePackageExportProfile.decodeUtf8(
                await temporary.readAsBytes()) !=
            profile) {
          throw const GamePackageExportException(
              code: 'exportProfileWriteFailed',
              message: 'The export profile changed during persistence.');
        }
        _requireRevisions(
            await validate(profile), profileRevision, contextRevision);
        await temporary.rename(profileFile.path);
        return GamePackageExportProfileSnapshot(
            profile: profile,
            profileRevision: _profileRevision(encoded),
            contextRevision: contextRevision);
      } finally {
        await temporaryDirectory.delete(recursive: true);
      }
    });
  }

  Future<T> _withWriteLock<T>(Future<T> Function() operation) async {
    final root = await projectRoot.resolveSymbolicLinks();
    final previous = _writers[root] ?? Future<void>.value();
    final release = Completer<void>();
    _writers[root] = release.future;
    await previous;
    try {
      await _checkSidecar();
      await profileFile.parent.create();
      final lock =
          await File('${profileFile.path}.lock').open(mode: FileMode.append);
      var acquired = false;
      try {
        await lock.lock(FileLock.exclusive);
        acquired = true;
        return await operation();
      } finally {
        try {
          if (acquired) await lock.unlock();
        } finally {
          await lock.close();
        }
      }
    } finally {
      release.complete();
      if (identical(_writers[root], release.future)) _writers.remove(root);
    }
  }

  void _requireRevisions(GamePackageExportProfileSnapshot current,
      String profileRevision, String contextRevision) {
    if (current.profileRevision != profileRevision ||
        current.contextRevision != contextRevision) {
      throw const GamePackageExportException(
          code: 'exportProfileStale',
          message:
              'The export profile or its declared context changed. Read and validate again.');
    }
  }

  String _profileRevision(List<int>? bytes) => bytes == null
      ? 'absent'
      : computeAuthoringBytesFingerprint(bytes,
          logicalName: 'export-profile-v1.json');

  Future<void> _checkSidecar() async {
    for (final entry in [
      Directory(p.join(projectRoot.path, '.pokemap')),
      profileFile,
      File('${profileFile.path}.lock')
    ]) {
      final type = await FileSystemEntity.type(entry.path, followLinks: false);
      if (type != FileSystemEntityType.notFound &&
          type !=
              (entry is Directory
                  ? FileSystemEntityType.directory
                  : FileSystemEntityType.file)) {
        throw const GamePackageExportException(
            code: 'exportProfilePathUnsafe',
            message:
                'The export profile must use its exact project-local regular sidecar.');
      }
    }
  }

  Future<String> _contextRevision(GamePackageExportProfile? profile) async {
    final paths = <String>{'project.json'};
    final projectFile = await _safeReference('project.json');
    final descriptor = (jsonDecode(await projectFile.readAsString()) as Map)
        .cast<String, Object?>();
    final catalog = await CatalogProjectReader.open(
      store: await CatalogStorageStore.open(projectRoot: projectRoot.path),
      descriptor: descriptor,
    );
    final manifest = catalog == null
        ? ProjectManifest.fromJson(descriptor)
        : await catalog.read((value) async => value.projectMetadata);
    if (descriptor['format'] == 'avelune.working-catalog') {
      paths.add(CatalogStorageStore.headStorageKey);
    }
    if (manifest.newGame.enabled) {
      final maps = manifest.maps
          .where((entry) => entry.id == manifest.newGame.startMapId)
          .toList();
      if (maps.length != 1) {
        throw const GamePackageExportException(
            code: 'exportProfileReferenceInvalid',
            message: 'The project needs one valid configured start map.');
      }
      final mapFile = await _safeReference(maps.single.relativePath);
      final map = MapData.fromJson(
          (jsonDecode(await mapFile.readAsString()) as Map)
              .cast<String, dynamic>());
      if (map.id != maps.single.id) {
        throw const GamePackageExportException(
            code: 'exportProfileReferenceInvalid',
            message:
                'The configured start map must match its declared identity.');
      }
      paths.add(maps.single.relativePath);
    }
    if (profile != null) {
      paths.addAll([
        profile.iconPath,
        profile.coverPath,
        profile.heroPath,
        profile.titleMusicPath,
        profile.licensePath,
        profile.creditsPath
      ].whereType<String>());
    }
    final ordered = paths.toList()..sort();
    final fingerprint = NarrativeProjectFingerprintBuilder();
    for (final path in ordered) {
      final file = await _safeReference(path);
      fingerprint.startEntry(
          relativePath: path, byteLength: await file.length());
      await for (final bytes in file.openRead()) {
        fingerprint.addBytes(bytes);
      }
      fingerprint.endEntry();
    }
    final revision = fingerprint.close();
    await catalog?.read((_) async {});
    return revision;
  }

  Future<File> _safeReference(String path) async {
    final segments = validateProjectRelativePath(path);
    if (segments.join('/') != path || segments.first.startsWith('.')) {
      throw GamePackageExportException(
          code: 'exportProfileReferenceInvalid',
          path: path,
          message:
              'Profile references must be canonical project-relative asset paths.');
    }
    var current = projectRoot.path;
    for (var i = 0; i < segments.length; i++) {
      current = p.join(current, segments[i]);
      final type = await FileSystemEntity.type(current, followLinks: false);
      if (type !=
          (i == segments.length - 1
              ? FileSystemEntityType.file
              : FileSystemEntityType.directory)) {
        throw GamePackageExportException(
            code: type == FileSystemEntityType.notFound
                ? 'missingProjectFile'
                : 'exportProfileReferenceInvalid',
            path: path,
            message:
                'A declared export profile reference is missing or unsafe.');
      }
    }
    return File(current);
  }
}
