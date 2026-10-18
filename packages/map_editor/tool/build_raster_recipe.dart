import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'package:map_editor/src/application/services/raster_asset_grid_normalizer.dart';
import 'package:map_editor/src/application/services/tileset_atlas_builder.dart';

Future<void> main(List<String> arguments) async {
  try {
    String option(String name) {
      final index = arguments.indexOf(name);
      if (index < 0 || index + 1 >= arguments.length) {
        throw FormatException('Required $name');
      }
      return arguments[index + 1];
    }

    final result = await buildRasterRecipe(
      recipeFile: File(option('--recipe')),
      sourceRoot: Directory(option('--source-root')),
      outputRoot: Directory(option('--output-root')),
    );
    stdout.writeln(jsonEncode(result));
  } on Object catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  }
}

Future<Map<String, Object?>> buildRasterRecipe({
  required File recipeFile,
  required Directory sourceRoot,
  required Directory outputRoot,
}) async {
  final recipe = _object(jsonDecode(await recipeFile.readAsString()));
  _keys(recipe, {
    'schemaVersion',
    'id',
    'provenance',
    'sources',
    'atlases',
    'copies',
  });
  if (recipe['schemaVersion'] != 1 || recipe['id'] is! String) {
    throw const FormatException('Unsupported raster recipe');
  }
  final root = Directory(await sourceRoot.resolveSymbolicLinks());
  final outputs = <String, Uint8List>{};
  final sources = <String, Uint8List>{};
  for (final raw in recipe['sources'] as List) {
    final source = _object(raw);
    _keys(source, {'id', 'path', 'sha256'});
    final id = source['id'] as String;
    if (sources.containsKey(id)) {
      throw const FormatException('Duplicate source');
    }
    final bytes = await _readSource(root, source['path'] as String);
    _hash(bytes, source['sha256'] as String);
    sources[id] = bytes;
  }
  void output(String path, Uint8List bytes, String hash) {
    _relative(path);
    if (outputs.containsKey(path)) {
      throw const FormatException('Duplicate output');
    }
    _hash(bytes, hash);
    outputs[path] = bytes;
  }

  for (final raw in recipe['copies'] as List? ?? []) {
    final copy = _object(raw);
    _keys(copy, {'sourceId', 'path', 'sha256'});
    final bytes = sources[copy['sourceId']];
    if (bytes == null) throw const FormatException('Unknown source');
    output(copy['path'] as String, bytes, copy['sha256'] as String);
  }
  for (final raw in recipe['atlases'] as List? ?? []) {
    final atlas = _object(raw);
    _keys(atlas, {
      'path',
      'sha256',
      'tileWidth',
      'tileHeight',
      'widthCells',
      'heightCells',
      'items',
    });
    final tileWidth = atlas['tileWidth'] as int;
    final tileHeight = atlas['tileHeight'] as int;
    final items = <TilesetAtlasItem>[];
    for (final rawItem in atlas['items'] as List) {
      final item = _object(rawItem);
      _keys(item, {
        'sourceId',
        'xCells',
        'yCells',
        'widthCells',
        'heightCells',
        'anchor',
        'normalizedSha256',
      });
      final bytes = sources[item['sourceId']];
      if (bytes == null) throw const FormatException('Unknown atlas source');
      final anchor = switch (item['anchor']) {
        'topLeft' => RasterAssetAnchor.topLeft,
        'bottomCenter' => RasterAssetAnchor.bottomCenter,
        'center' => RasterAssetAnchor.center,
        _ => throw const FormatException('Invalid raster anchor'),
      };
      final normalized = normalizeRasterAssetToGrid(
        RasterAssetGridNormalizationRequest(
          bytes: bytes,
          gridWidth: tileWidth,
          gridHeight: tileHeight,
          targetWidth: (item['widthCells'] as int) * tileWidth,
          targetHeight: (item['heightCells'] as int) * tileHeight,
          anchor: anchor,
          resizeMode: RasterAssetResizeMode.none,
        ),
      );
      _hash(normalized, item['normalizedSha256'] as String);
      items.add(
        TilesetAtlasItem(
          id: item['sourceId'] as String,
          bytes: normalized,
          xCells: item['xCells'] as int,
          yCells: item['yCells'] as int,
          widthCells: item['widthCells'] as int,
          heightCells: item['heightCells'] as int,
        ),
      );
    }
    output(
      atlas['path'] as String,
      buildTilesetAtlas(
        widthCells: atlas['widthCells'] as int,
        heightCells: atlas['heightCells'] as int,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
        items: items,
      ),
      atlas['sha256'] as String,
    );
  }
  if (outputs.isEmpty) throw const FormatException('Empty raster recipe');
  final outputPath = p.join(
    await outputRoot.parent.resolveSymbolicLinks(),
    p.basename(outputRoot.path),
  );
  if (p.equals(outputPath, root.path) || p.isWithin(root.path, outputPath)) {
    throw const FormatException('Output must be outside the source corpus');
  }
  if (FileSystemEntity.typeSync(outputPath, followLinks: false) !=
      FileSystemEntityType.notFound) {
    throw const FormatException('Output already exists');
  }
  final staging = await Directory(
    p.dirname(outputPath),
  ).createTemp('.raster-recipe-');
  try {
    for (final entry in outputs.entries) {
      final file = File(p.join(staging.path, entry.key));
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value, flush: true);
    }
    await staging.rename(outputPath);
  } finally {
    if (await staging.exists()) await staging.delete(recursive: true);
  }
  return {
    'schemaVersion': 1,
    'recipeId': recipe['id'],
    'provenance': recipe['provenance'],
    'outputRoot': outputPath,
    'outputs': {
      for (final entry in outputs.entries)
        entry.key: sha256.convert(entry.value).toString(),
    },
  };
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Expected object');
  }
  return value;
}

void _keys(Map<String, dynamic> value, Set<String> allowed) {
  if (value.keys.any((key) => !allowed.contains(key))) {
    throw const FormatException('Unknown raster recipe field');
  }
}

void _relative(String path) {
  if (path.isEmpty ||
      p.isAbsolute(path) ||
      path.contains('\\') ||
      path.contains(':') ||
      path
          .split('/')
          .any((part) => part.isEmpty || part == '.' || part == '..')) {
    throw const FormatException('Expected a confined relative path');
  }
}

Future<Uint8List> _readSource(Directory root, String path) async {
  _relative(path);
  var candidate = root.path;
  final parts = path.split('/');
  for (var index = 0; index < parts.length; index++) {
    candidate = p.join(candidate, parts[index]);
    final type = await FileSystemEntity.type(candidate, followLinks: false);
    if (type !=
        (index == parts.length - 1
            ? FileSystemEntityType.file
            : FileSystemEntityType.directory)) {
      throw const FormatException('Recipe inputs must be regular files');
    }
  }
  return File(candidate).readAsBytes();
}

void _hash(List<int> bytes, String expected) {
  if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(expected) ||
      sha256.convert(bytes).toString() != expected) {
    throw const FormatException('Raster recipe input or output hash mismatch');
  }
}
