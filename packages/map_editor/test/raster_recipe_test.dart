import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../tool/build_raster_recipe.dart';

void main() {
  for (final grid in [4, 8]) {
    test(
      'a declared $grid-pixel recipe packs exact independent source pixels',
      () async {
        final fixture = await _Fixture.create(grid);
        addTearDown(() => fixture.root.delete(recursive: true));
        final result = await buildRasterRecipe(
          recipeFile: fixture.recipeFile,
          sourceRoot: fixture.input,
          outputRoot: fixture.output,
        );
        expect(result['recipeId'], 'synthetic-$grid');
        expect(
          await File('${fixture.output.path}/atlas.png').readAsBytes(),
          fixture.expectedAtlas,
        );
        expect(
          await File('${fixture.output.path}/source-copy.png').readAsBytes(),
          fixture.source,
        );
        expect(
          await File('${fixture.input.path}/sprite.png').readAsBytes(),
          fixture.source,
        );
        final decoded = img.decodePng(
          await File('${fixture.output.path}/atlas.png').readAsBytes(),
        )!;
        expect((decoded.width, decoded.height), (grid * 2, grid));
        expect(decoded.getPixel(grid + (grid - 2) ~/ 2, grid - 2).a, 127);
        expect(decoded.getPixel(0, 0).a, 0);
      },
    );
  }

  test(
    'a changed source refuses publication and preserves all input bytes',
    () async {
      final fixture = await _Fixture.create(4);
      addTearDown(() => fixture.root.delete(recursive: true));
      final source = File('${fixture.input.path}/sprite.png');
      await source.writeAsString('concurrent bytes');
      await expectLater(
        buildRasterRecipe(
          recipeFile: fixture.recipeFile,
          sourceRoot: fixture.input,
          outputRoot: fixture.output,
        ),
        throwsFormatException,
      );
      expect(fixture.output.existsSync(), isFalse);
      expect(await source.readAsString(), 'concurrent bytes');
    },
  );

  test(
    'invalid placement, output hash and paths never publish partial files',
    () async {
      for (final mutation in [
        'overlap',
        'outside',
        'hash',
        'traversal',
        'unknown',
      ]) {
        final fixture = await _Fixture.create(4);
        addTearDown(() => fixture.root.delete(recursive: true));
        final recipe =
            jsonDecode(jsonEncode(fixture.recipe)) as Map<String, dynamic>;
        final atlas = (recipe['atlases'] as List).single as Map;
        switch (mutation) {
          case 'overlap':
            (atlas['items'] as List).add(
              Map<String, dynamic>.from((atlas['items'] as List).single as Map),
            );
          case 'outside':
            ((atlas['items'] as List).single as Map)['xCells'] = 2;
          case 'hash':
            atlas['sha256'] = '0' * 64;
          case 'traversal':
            atlas['path'] = '../escape.png';
          case 'unknown':
            recipe['execute'] = 'anything';
        }
        await fixture.recipeFile.writeAsString(jsonEncode(recipe));
        await expectLater(
          buildRasterRecipe(
            recipeFile: fixture.recipeFile,
            sourceRoot: fixture.input,
            outputRoot: fixture.output,
          ),
          throwsA(anyOf(isA<FormatException>(), isA<ArgumentError>())),
        );
        expect(fixture.output.existsSync(), isFalse, reason: mutation);
        expect(
          await File('${fixture.input.path}/sprite.png').readAsBytes(),
          fixture.source,
        );
      }
    },
  );

  test(
    'occupied destinations and source symlinks are preserved and refused',
    () async {
      final fixture = await _Fixture.create(4);
      addTearDown(() => fixture.root.delete(recursive: true));
      await fixture.output.create();
      final marker = File('${fixture.output.path}/marker');
      await marker.writeAsString('owned by another writer');
      await expectLater(
        buildRasterRecipe(
          recipeFile: fixture.recipeFile,
          sourceRoot: fixture.input,
          outputRoot: fixture.output,
        ),
        throwsFormatException,
      );
      expect(await marker.readAsString(), 'owned by another writer');
      await Link('${fixture.input.path}/linked').create(fixture.input.path);
      final recipe =
          jsonDecode(jsonEncode(fixture.recipe)) as Map<String, dynamic>;
      ((recipe['sources'] as List).single as Map)['path'] = 'linked/sprite.png';
      await fixture.recipeFile.writeAsString(jsonEncode(recipe));
      await expectLater(
        buildRasterRecipe(
          recipeFile: fixture.recipeFile,
          sourceRoot: fixture.input,
          outputRoot: Directory('${fixture.root.path}/other'),
        ),
        throwsFormatException,
      );
      expect(Directory('${fixture.root.path}/other').existsSync(), isFalse);
    },
  );
}

class _Fixture {
  _Fixture(this.root, this.source, this.expectedAtlas, this.recipe);
  final Directory root;
  final Uint8List source, expectedAtlas;
  final Map<String, dynamic> recipe;
  Directory get input => Directory('${root.path}/input');
  Directory get output => Directory('${root.path}/output');
  File get recipeFile => File('${root.path}/recipe.json');

  static Future<_Fixture> create(int grid) async {
    final root = await Directory.systemTemp.createTemp('synthetic-raster-');
    final image = img.Image(width: 2, height: 2, numChannels: 4);
    for (var y = 0; y < 2; y++) {
      for (var x = 0; x < 2; x++) {
        image.setPixelRgba(x, y, 20 + x, 40 + y, 60, 127);
      }
    }
    final source = img.encodePng(image);
    final normalized = img.Image(width: grid, height: grid, numChannels: 4);
    final atlas = img.Image(width: grid * 2, height: grid, numChannels: 4);
    for (var y = 0; y < 2; y++) {
      for (var x = 0; x < 2; x++) {
        final px = (grid - 2) ~/ 2 + x, py = grid - 2 + y;
        normalized.setPixelRgba(px, py, 20 + x, 40 + y, 60, 127);
        atlas.setPixelRgba(grid + px, py, 20 + x, 40 + y, 60, 127);
      }
    }
    final expectedAtlas = img.encodePng(atlas);
    final recipe = <String, dynamic>{
      'schemaVersion': 1,
      'id': 'synthetic-$grid',
      'sources': [
        {
          'id': 'sprite',
          'path': 'sprite.png',
          'sha256': sha256.convert(source).toString(),
        },
      ],
      'copies': [
        {
          'sourceId': 'sprite',
          'path': 'source-copy.png',
          'sha256': sha256.convert(source).toString(),
        },
      ],
      'atlases': [
        {
          'path': 'atlas.png',
          'sha256': sha256.convert(expectedAtlas).toString(),
          'tileWidth': grid,
          'tileHeight': grid,
          'widthCells': 2,
          'heightCells': 1,
          'items': [
            {
              'sourceId': 'sprite',
              'xCells': 1,
              'yCells': 0,
              'widthCells': 1,
              'heightCells': 1,
              'anchor': 'bottomCenter',
              'normalizedSha256': sha256
                  .convert(img.encodePng(normalized))
                  .toString(),
            },
          ],
        },
      ],
    };
    final fixture = _Fixture(root, source, expectedAtlas, recipe);
    await fixture.input.create();
    await File('${fixture.input.path}/sprite.png').writeAsBytes(source);
    await fixture.recipeFile.writeAsString(jsonEncode(recipe));
    return fixture;
  }
}
