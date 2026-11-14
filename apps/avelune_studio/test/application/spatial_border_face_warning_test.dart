import 'package:avelune_studio/features/map_workspace/application/map_border_editing_commands.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_border_fixture.dart';
import 'spatial_border_commands_fixtures.dart';

const _buried = 'border.spatial.face_base_mismatch';

void main() {
  test(
    'a relief traced on flat ground is placed and reports its buried face',
    () {
      final project = _hangingCliffProject();
      final map = _flatMap(level: 1);
      final document = borderDocument(map);

      MapBorderEditingCommands(
        document,
        project,
      ).finish(borderDraft(map, project));

      expect(document.current.layers.whereType<BorderLayer>(), hasLength(1));
      expect(document.borderWarnings, {_buried});
      expect(document.error, isNull);

      document.restore(redo: false);
      expect(document.current, map);
      expect(document.borderWarnings, isEmpty);
    },
  );

  test('a relief whose foot meets the lower ground reports nothing', () {
    final project = _hangingCliffProject();
    final map = _stepMap();
    final document = borderDocument(map);

    MapBorderEditingCommands(
      document,
      project,
    ).finish(borderDraft(map, project));

    expect(document.current.layers.whereType<BorderLayer>(), hasLength(1));
    expect(document.borderWarnings, isEmpty);
  });

  test('the next edit clears the previous trace warnings', () {
    final project = _hangingCliffProject();
    final map = _flatMap(level: 1);
    final document = borderDocument(map);
    MapBorderEditingCommands(
      document,
      project,
    ).finish(borderDraft(map, project));
    expect(document.borderWarnings, isNotEmpty);

    document.commit(document.current.copyWith(name: 'Renommée'));

    expect(document.borderWarnings, isEmpty);
  });
}

MapData _flatMap({required int level}) {
  final map = spatialBorderMap();
  return map.copyWith(
    spatialScene: map.spatialScene!.copyWith(
      heightLevels: List.filled(map.size.width * map.size.height, level),
    ),
  );
}

MapData _stepMap() {
  final map = spatialBorderMap();
  return map.copyWith(
    spatialScene: map.spatialScene!.copyWith(
      heightLevels: [
        for (var z = 0; z < map.size.height; z++)
          for (var x = 0; x < map.size.width; x++) x < 5 && z >= 5 ? 1 : 0,
      ],
    ),
  );
}

ProjectManifest _hangingCliffProject() {
  final base = spatialBorderProject();
  final raw = encodeBorderBlueprintRecordJson(
    base.borderCatalog.records.single,
    formatVersion: base.borderCatalog.formatVersion,
  );
  for (final key in ['draft', 'latestPublished']) {
    final definition = (raw[key] as Map)['definition'] as Map;
    definition['followContourDirection'] = true;
    final primitives = definition['primitives'] as List;
    for (final primitive in primitives.cast<Map>()) {
      primitive['anchorWorld'] = {'x': 0.0, 'y': 0.0, 'z': 0.0};
    }
    final corner = Map<String, Object?>.from(
      primitives.singleWhere((p) => p['role'] == 'lineCorner') as Map,
    );
    primitives.removeWhere((p) => p['role'] == 'lineCorner');
    primitives.add({...corner, 'id': 'corner-right', 'cornerTurn': 'right'});
    primitives.add({...corner, 'id': 'corner-left', 'cornerTurn': 'left'});
  }
  return base.copyWith(
    models3d: [
      for (final model in base.models3d)
        model.id == 'oak'
            ? ProjectModel3dEntry(
                id: model.id,
                name: model.name,
                sourceAssetId: model.sourceAssetId,
                relativePath: model.relativePath,
                inspection: Model3dInspection(
                  bounds: Model3dBounds(
                    min: Model3dVector3(x: -.2, y: -1, z: -.2),
                    max: Model3dVector3(x: .2, y: 0, z: .2),
                  ),
                  meshCount: 1,
                  triangleCount: 1,
                ),
              )
            : model,
    ],
    borderCatalog: ProjectBorderCatalog(
      formatVersion: base.borderCatalog.formatVersion,
      records: [
        decodeBorderBlueprintRecordJson(
          raw,
          formatVersion: base.borderCatalog.formatVersion,
        ),
      ],
    ),
  );
}
