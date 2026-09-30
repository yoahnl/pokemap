import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../contracts/artifact_ref.dart';
import '../domains/assets/asset_store.dart';
import 'project_creation_contracts.dart';
import 'project_creation_kit.dart';

ProjectCreationKit prepareClairboisCreationKit(
    List<int> bytes, ProjectCreationRequest request) {
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
    if (path != 'project.json' &&
        path != 'asset-provenance.json' &&
        !path.startsWith('assets/') &&
        !path.startsWith('maps/') &&
        !path.startsWith('dialogues/')) {
      continue;
    }
    total += file.size;
    if (total > 64 * 1024 * 1024 || files.containsKey(path)) {
      throw const FormatException('Invalid template file inventory');
    }
    files[path] = file.content;
  }
  Map<String, dynamic> document(String path) =>
      jsonDecode(utf8.decode(files[path] ??
              (throw FormatException('Missing template document: $path'))))
          as Map<String, dynamic>;
  final manifest = ProjectManifest.fromJson(document('project.json'))
      .copyWith(name: request.name.trim());
  if (manifest.settings.tileWidth != 32 || manifest.settings.tileHeight != 32) {
    throw const FormatException('Invalid Clairbois grid');
  }
  final maps = [
    for (final entry in manifest.maps)
      MapData.fromJson(document(_path(entry.relativePath))),
  ];
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
  final catalog = AssetCatalog.fromJson(document(assetCatalogStorageKey));
  for (final asset in catalog.records) {
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
