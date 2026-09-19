import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

String stressAtlasId(int index) => 'stress-atlas-$index';

String stressIncidentId(int index) =>
    'stress-${switch (index % 3) {
      0 => 'missing',
      1 => 'decode',
      _ => 'path',
    }}-$index';

Future<void> writeStressExampleProject(
  Directory directory,
  ProjectManifest base,
  List<MapData> baseMaps, {
  int atlasCount = 132,
  int errorCount = 200,
}) async {
  if (atlasCount < 2 || errorCount < 0) {
    throw ArgumentError(
      'Au moins deux atlas et un nombre positif d’incidents.',
    );
  }
  final firstAtlas = stressAtlasId(0);
  final lateAtlas = stressAtlasId(atlasCount - 1);
  final elements = [
    for (var index = 0; index < atlasCount; index++)
      for (final element in base.elements)
        element.copyWith(
          id: '${element.id}-$index',
          name: '${element.name} · collection ${index + 1}',
          tilesetId: stressAtlasId(index),
          frames: [
            for (final frame in element.frames)
              frame.copyWith(tilesetId: stressAtlasId(index)),
          ],
        ),
    for (var index = 0; index < errorCount; index++)
      base.elements.first.copyWith(
        id: stressIncidentId(index),
        name:
            'Ressource de diagnostic ${index + 1} · '
            'un nom volontairement long pour vérifier la lisibilité du panneau',
        tilesetId: stressIncidentId(index),
        frames: [
          base.elements.first.frames.first.copyWith(
            tilesetId: stressIncidentId(index),
          ),
        ],
      ),
  ];
  final maps = [
    _map(baseMaps.first, 'stress-a', 'Jardin · atlas tardif', atlasCount - 1),
    _map(baseMaps.last, 'stress-b', 'Clairière · autre atlas', 0),
    _map(baseMaps.first, 'stress-errors', 'Atelier · diagnostics', 1).copyWith(
      placedElements: [
        for (var index = 0; index < errorCount; index++)
          MapPlacedElement(
            id: 'incident-$index',
            layerId: 'decor',
            elementId: stressIncidentId(index),
            pos: GridPos(x: 1 + index % 20, y: 1 + (index ~/ 20) % 12),
          ),
      ],
    ),
  ];
  final manifest = base.copyWith(
    name: 'Avelune · Atelier des ressources à la demande',
    maps: [
      for (final map in maps)
        ProjectMapEntry(
          id: map.id,
          name: map.name,
          relativePath: 'maps/${map.id}.json',
        ),
    ],
    tilesets: [
      for (var index = 0; index < atlasCount; index++)
        ProjectTilesetEntry(
          id: stressAtlasId(index),
          name: index == atlasCount - 1
              ? 'Jardin · atlas tardif ${index + 1}'
              : 'Atelier · collection ${index + 1}',
          relativePath: 'assets/atelier.png',
        ),
      for (var index = 0; index < errorCount; index++)
        ProjectTilesetEntry(
          id: stressIncidentId(index),
          name: elements[atlasCount * base.elements.length + index].name,
          relativePath: switch (index % 3) {
            0 => 'assets/absent-$index.png',
            1 => 'assets/invalid.png',
            _ => '../outside-fixture-$index.png',
          },
        ),
    ],
    elements: elements,
    characters: [
      for (final character in base.characters)
        character.copyWith(tilesetId: firstAtlas),
    ],
    globalProperties: {
      ...base.globalProperties,
      'studioStressAtlasCount': atlasCount,
      'studioStressErrorCount': errorCount,
      'studioStressLateAtlasId': lateAtlas,
    },
  );
  const encoder = JsonEncoder.withIndent('  ');
  for (final map in maps) {
    await File(
      p.join(directory.path, 'maps', '${map.id}.json'),
    ).writeAsString(encoder.convert(map.toJson()));
  }
  await File(
    p.join(directory.path, 'assets', 'invalid.png'),
  ).writeAsBytes(utf8.encode('This fixture deliberately is not a PNG.'));
  await File(
    p.join(directory.path, 'project.json'),
  ).writeAsString(encoder.convert(manifest.toJson()));
}

MapData _map(MapData base, String id, String name, int atlasIndex) {
  final atlasId = stressAtlasId(atlasIndex);
  return base.copyWith(
    id: id,
    name: name,
    tilesetId: atlasId,
    layers: [
      for (final layer in base.layers)
        if (layer is TileLayer)
          layer.copyWith(
            palette: [
              for (final entry in layer.palette)
                entry.copyWith(tilesetId: atlasId),
            ],
          )
        else
          layer,
    ],
    placedElements: [
      for (final element in base.placedElements)
        element.copyWith(
          id: '$id-${element.elementId}',
          elementId: '${element.elementId}-$atlasIndex',
          pos: element.elementId == 'caisse'
              ? const GridPos(x: 11, y: 5)
              : element.pos,
          visualOrder: element.elementId == 'caisse' ? 1 : 0,
        ),
    ],
  );
}
