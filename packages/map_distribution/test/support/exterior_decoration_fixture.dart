import 'dart:convert';
import 'package:map_core/map_core.dart';
import 'spatial_package_fixture.dart';
import '../../../map_core/test/support/spatial_border_ground_surface_fixture.dart';

Map<String, List<int>> exteriorDecorationPayload(
    {String modelId = 'model', bool withBorder = false}) {
  final files = spatialPayload();
  final sector = ExteriorDecorationSector(
    id: 'west',
    originX: -4,
    originZ: 0,
    scene: MapSpatialScene(width: 4, depth: 8, instances: [
      SpatialModelInstance(
          id: 'tree', modelId: modelId, position: Model3dVector3.zero),
    ]),
  );
  final definition = MapExteriorDecoration(
      mapId: 'map', playableWidth: 8, playableDepth: 8, west: 4);
  final bytes = utf8.encode(jsonEncode(sector.toJson()));
  files['project/maps/map.decoration/west.json'] = bytes;
  files['project/maps/map.decoration.json'] = utf8.encode(jsonEncode({
    'schemaVersion': 1,
    'definition': definition.toJson(),
    'sectors': [
      {
        'id': sector.id,
        'originX': sector.originX,
        'originZ': sector.originZ,
        'width': sector.scene.width,
        'depth': sector.scene.depth,
        'instances': sector.scene.instances.length,
        'resourceIds': sector.resourceReferenceIds.toList()..sort(),
        'revision': computeNarrativeProjectFingerprint([
          NarrativeProjectFingerprintEntry(
              relativePath: 'maps/map.decoration/west.json', bytes: bytes),
        ]),
      }
    ],
  }));
  if (withBorder) {
    final fixture = spatialBorderFixture();
    final project = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(files['project/project.json']!)));
    final projectJson = project.toJson();
    projectJson['borderCatalog'] = jsonDecode(
        jsonEncode(fixture.project.toJson()['borderCatalog'])
            .replaceAll('"unit"', '"model"'));
    final decoratedProject = ProjectManifest.fromJson(projectJson);
    files['project/project.json'] =
        utf8.encode(jsonEncode(decoratedProject.toJson()));
    final border = ExteriorDecorationBorder(
        id: 'fence',
        layerId: 'border',
        originX: -4,
        originZ: 0,
        width: 4,
        depth: 8,
        feature:
            (fixture.map.layers.single as BorderLayer).content.features.single);
    final full = MapExteriorDecoration(
        mapId: 'map',
        playableWidth: 8,
        playableDepth: 8,
        west: 4,
        sectors: [sector],
        borders: [border]);
    final result = resolveExteriorDecorationBorder(
        manifest: decoratedProject,
        decoration: full,
        border: border,
        playableMap: MapData.fromJson(
            jsonDecode(utf8.decode(files['project/maps/map.json']!))));
    final applied = applyExteriorDecorationBorderResolution(border, result);
    final borderBytes = utf8.encode(jsonEncode(applied.toJson()));
    final path = 'maps/map.decoration/borders/fence.json';
    files['project/$path'] = borderBytes;
    final index =
        jsonDecode(utf8.decode(files['project/maps/map.decoration.json']!))
            as Map<String, dynamic>;
    index['borders'] = [
      {
        'id': applied.id,
        'originX': applied.originX,
        'originZ': applied.originZ,
        'width': applied.width,
        'depth': applied.depth,
        'instances': applied.instances.length,
        'resourceIds': applied.resourceReferenceIds.toList()..sort(),
        'revision': computeNarrativeProjectFingerprint([
          NarrativeProjectFingerprintEntry(
              relativePath: path, bytes: borderBytes),
        ]),
      }
    ];
    files['project/maps/map.decoration.json'] = utf8.encode(jsonEncode(index));
  }
  return files;
}
