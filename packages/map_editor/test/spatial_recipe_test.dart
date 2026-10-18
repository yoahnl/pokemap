import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../tool/verify_spatial_recipe.dart';

void main() {
  for (final id in ['terrace', 'observatory']) {
    test(
      'spatial QA reads the declared $id project without mutating it',
      () async {
        final root = await Directory.systemTemp.createTemp('spatial-recipe-');
        addTearDown(() => root.delete(recursive: true));
        final map = MapData(
          version: ProjectVersion.v9,
          id: id,
          name: id,
          size: const GridSize(width: 8, height: 8),
          spatialScene: MapSpatialScene(width: 8, depth: 8),
          layers: [],
        );
        final project = ProjectManifest(
          version: ProjectVersion.v9,
          settings: const ProjectSettings(dimension: ProjectDimension.threeD),
          name: id,
          maps: [
            ProjectMapEntry(id: id, name: id, relativePath: 'maps/$id.json'),
          ],
          tilesets: [],
        );
        await Directory('${root.path}/maps').create();
        final bytes = jsonEncode(project.toJson());
        final mapBytes = jsonEncode(map.toJson());
        await File('${root.path}/project.json').writeAsString(bytes);
        await File('${root.path}/maps/$id.json').writeAsString(mapBytes);
        final recipe = {
          'schemaVersion': 1,
          'id': id,
          'cases': [
            {
              'id': 'walk',
              'mapId': id,
              'initial': {
                'position': {'x': 3.5, 'z': 3.5},
              },
              'input': {'x': id == 'terrace' ? 1 : -1, 'z': 0},
              'frames': 10,
              'dt': 1 / 60,
              'expected': {
                'warpId': null,
                if (id == 'terrace')
                  'xGreaterThan': 3.5
                else
                  'xMaxExclusive': 3.5,
              },
            },
          ],
        };
        expect((await verifySpatialRecipe(root, recipe))['passed'], isTrue);
        expect(await File('${root.path}/project.json').readAsString(), bytes);
        expect(
          await File('${root.path}/maps/$id.json').readAsString(),
          mapBytes,
        );
        final check = (recipe['cases'] as List).single as Map;
        check['frames'] = 10001;
        await expectLater(
          verifySpatialRecipe(root, recipe),
          throwsFormatException,
        );
        expect(await File('${root.path}/project.json').readAsString(), bytes);
      },
    );
  }
}
