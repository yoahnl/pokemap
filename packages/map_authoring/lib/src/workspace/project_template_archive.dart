import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../contracts/artifact_ref.dart';
import '../domains/assets/asset_store.dart';
import 'project_creation_contracts.dart';
import 'project_creation_kit.dart';
import 'project_template_catalog.dart';

ProjectCreationKit prepareTemplateCreationKit(List<int> bytes,
    ProjectCreationRequest request, ProjectTemplateDescriptor descriptor) {
  request.validate();
  final archive = ZipDecoder().decodeBytes(bytes, verify: true);
  final files = <String, List<int>>{};
  String? prefix;
  var total = 0;
  if (archive.length > 500) {
    throw const FormatException('Too many template files');
  }
  for (final file in archive) {
    final parts = file.name.split('/');
    if (file.isSymbolicLink ||
        (file.mode & 0xf000) == 0xa000 ||
        file.name.contains('\\') ||
        file.name.contains(':') ||
        file.name.contains('\u0000') ||
        parts.any((part) => part == '..' || part == '.') ||
        parts.first.isEmpty) {
      throw const FormatException('Unsafe template entry');
    }
    prefix ??= parts.first;
    if (prefix != parts.first) {
      throw const FormatException('Mixed template roots');
    }
    if (!file.isFile) continue;
    final path = parts.skip(1).join('/');
    if (path.isEmpty || parts.skip(1).any((part) => part.isEmpty)) {
      throw const FormatException('Invalid template path');
    }
    if (!descriptor.projectPaths.any((allowed) =>
        allowed.endsWith('/') ? path.startsWith(allowed) : path == allowed)) {
      continue;
    }
    total += file.size;
    if (total > 64 * 1024 * 1024 || files.containsKey(path)) {
      throw const FormatException('Invalid template file inventory');
    }
    files[path] = file.content;
  }
  for (final declared in descriptor.projectPaths) {
    if (!files.keys.any((path) => declared.endsWith('/')
        ? path.startsWith(declared)
        : path == declared)) {
      throw FormatException('Missing declared template path: $declared');
    }
  }
  Map<String, dynamic> document(String path) =>
      jsonDecode(utf8.decode(files[path] ??
              (throw FormatException('Missing template document: $path'))))
          as Map<String, dynamic>;
  final manifest = ProjectManifest.fromJson(document('project.json'))
      .copyWith(name: request.name.trim());
  if (manifest.settings.dimension != request.dimension ||
      manifest.settings.tileWidth != request.tileSize ||
      manifest.settings.tileHeight != request.tileSize) {
    throw const FormatException('Template grid does not match its descriptor');
  }
  final maps = [
    for (final entry in manifest.maps)
      MapData.fromJson(document(_path(entry.relativePath))),
  ];
  final initial =
      maps.where((map) => map.id == manifest.newGame.startMapId).toList();
  if (initial.length != 1 ||
      initial.single.size.width != request.mapWidth ||
      initial.single.size.height != request.mapHeight) {
    throw const FormatException(
        'Template start map does not match its descriptor');
  }
  ProjectValidator.validate(manifest, maps: maps);
  for (final map in maps) {
    MapValidator.validate(map, projectDialogueContext: manifest);
  }
  for (final reference in [
    ...manifest.tilesets.map((entry) => entry.relativePath),
    ...manifest.dialogues.map((entry) => entry.relativePath),
  ]) {
    if (!files.containsKey(_path(reference))) {
      throw FormatException('Missing template resource: $reference');
    }
  }
  if (!files.containsKey(assetCatalogStorageKey) &&
      files.keys.any((path) => path.startsWith('assets/'))) {
    throw const FormatException(
        'Template asset files require their canonical inventory.');
  }
  final catalog = files.containsKey(assetCatalogStorageKey)
      ? AssetCatalog.fromJson(document(assetCatalogStorageKey))
      : null;
  for (final asset in catalog?.records ?? const <AssetRecord>[]) {
    for (final path in [
      asset.logicalPath,
      assetBlobStorageKey(asset.artifact)
    ]) {
      final content = files[_path(path)];
      if (content == null ||
          ContentArtifactRef.fromBytes(content,
                  mediaType: asset.artifact.mediaType) !=
              asset.artifact) {
        throw FormatException('Invalid template asset: ${asset.id}');
      }
    }
  }
  files['project.json'] = utf8
      .encode(const JsonEncoder.withIndent('  ').convert(manifest.toJson()));
  return ProjectCreationKit(manifest, files);
}

String _path(String value) {
  if (p.posix.isAbsolute(value) ||
      value.contains('\\') ||
      value.contains(':') ||
      value.contains('\u0000') ||
      value.split('/').contains('..')) {
    throw const FormatException('Invalid template reference');
  }
  return value;
}
