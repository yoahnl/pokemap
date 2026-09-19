import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'example_project_assets.dart';
import 'stress_example_project.dart';

Future<void> main(List<String> arguments) async {
  final stress = arguments.contains('--stress');
  final paths = arguments.where((argument) => argument != '--stress').toList();
  if (paths.length > 1 || paths.any((path) => path.startsWith('--'))) {
    stderr.writeln(
      'Usage: dart run tool/create_example_project.dart [--stress] [dossier]',
    );
    exitCode = 64;
    return;
  }
  final Directory directory;
  if (paths.isEmpty) {
    directory = await Directory.systemTemp.createTemp(
      'avelune_studio_example_',
    );
  } else {
    final target = p.absolute(paths.single);
    if (await FileSystemEntity.type(target, followLinks: false) !=
        FileSystemEntityType.notFound) {
      stderr.writeln(
        'Le dossier de sortie existe déjà : aucun fichier modifié.',
      );
      exitCode = 73;
      return;
    }
    directory = await Directory(target).create();
  }
  await writeExampleProject(directory, stress: stress);
  stdout.writeln(await directory.resolveSymbolicLinks());
}

Future<void> writeExampleProject(
  Directory directory, {
  bool stress = false,
  int stressAtlasCount = 132,
  int stressErrorCount = 200,
}) async {
  await Directory(p.join(directory.path, 'maps')).create();
  await Directory(p.join(directory.path, 'assets')).create();
  await File(
    p.join(directory.path, 'assets', 'atelier.png'),
  ).writeAsBytes(exampleAtlasPng());
  final maps = [
    exampleMap('jardin', 'Jardin des essais'),
    exampleMap('clairiere', 'Clairière', alternate: true),
  ];
  final manifest = ProjectManifest(
    name: 'Avelune · Atelier des cartes',
    settings: const ProjectSettings(defaultPlayerCharacterId: 'guide'),
    maps: [
      for (final map in maps)
        ProjectMapEntry(
          id: map.id,
          name: map.name,
          relativePath: 'maps/${map.id}.json',
        ),
    ],
    tilesets: const [
      ProjectTilesetEntry(
        id: 'atelier',
        name: 'Atelier libre — formes originales',
        relativePath: 'assets/atelier.png',
      ),
    ],
    elementCategories: const [
      ProjectElementCategory(id: 'atelier', name: 'Atelier'),
    ],
    elements: [
      _element(
        'arbre',
        'Arbre du jardin',
        2,
        0,
        2,
        3,
        collision: const [GridPos(x: 0, y: 2), GridPos(x: 1, y: 2)],
      ),
      _element('rocher', 'Rocher bleu', 4, 0, 2, 2),
      _element('caisse', 'Caisse corail', 6, 0, 2, 2),
    ],
    characters: [
      ProjectCharacterEntry(
        id: 'guide',
        name: 'Guide de l’atelier',
        tilesetId: 'atelier',
        frameWidth: 2,
        frameHeight: 2,
        animations: [
          for (final state in [
            CharacterAnimationState.idle,
            CharacterAnimationState.walk,
          ])
            for (final direction in EntityFacing.values)
              CharacterAnimation(
                state: state,
                direction: direction,
                frames: const [
                  CharacterAnimationFrame(
                    source: TilesetSourceRect(x: 4, y: 0, width: 2, height: 2),
                  ),
                ],
              ),
        ],
      ),
    ],
  );
  const encoder = JsonEncoder.withIndent('  ');
  for (final map in maps) {
    await File(
      p.join(directory.path, 'maps', '${map.id}.json'),
    ).writeAsString(encoder.convert(map.toJson()));
  }
  await File(
    p.join(directory.path, 'project.json'),
  ).writeAsString(encoder.convert(manifest.toJson()));
  if (stress) {
    await writeStressExampleProject(
      directory,
      manifest,
      maps,
      atlasCount: stressAtlasCount,
      errorCount: stressErrorCount,
    );
  }
}

ProjectElementEntry _element(
  String id,
  String name,
  int x,
  int y,
  int width,
  int height, {
  List<GridPos> collision = const [],
}) => ProjectElementEntry(
  id: id,
  name: name,
  tilesetId: 'atelier',
  categoryId: 'atelier',
  recommendedLayerId: 'decor',
  frames: [
    TilesetVisualFrame(
      tilesetId: 'atelier',
      source: TilesetSourceRect(x: x, y: y, width: width, height: height),
    ),
  ],
  collisionProfile: collision.isEmpty
      ? null
      : ElementCollisionProfile(cells: collision),
);

MapData exampleMap(String id, String name, {bool alternate = false}) => MapData(
  id: id,
  name: name,
  size: const GridSize(width: 24, height: 16),
  tilesetId: 'atelier',
  layers: [
    TileLayer(
      id: 'ground',
      name: 'Sol',
      palette: const [
        TileLayerPaletteEntry(tilesetId: 'atelier', localTileId: 0),
        TileLayerPaletteEntry(tilesetId: 'atelier', localTileId: 1),
      ],
      cells: [
        for (var y = 0; y < 16; y++)
          for (var x = 0; x < 24; x++) y == 9 || (alternate && x == 12) ? 2 : 1,
      ],
    ),
    TileLayer(id: 'decor', name: 'Décors', cells: List.filled(24 * 16, 0)),
    CollisionLayer(
      id: 'collision',
      name: 'Limites',
      collisions: [
        for (var y = 0; y < 16; y++)
          for (var x = 0; x < 24; x++) x == 0 || y == 0 || x == 23 || y == 15,
      ],
    ),
  ],
  placedElements: [
    MapPlacedElement(
      id: '$id-arbre',
      layerId: 'decor',
      elementId: 'arbre',
      pos: GridPos(x: alternate ? 14 : 5, y: 4),
    ),
    MapPlacedElement(
      id: '$id-rocher',
      layerId: 'decor',
      elementId: 'rocher',
      pos: const GridPos(x: 11, y: 5),
    ),
    MapPlacedElement(
      id: '$id-caisse',
      layerId: 'decor',
      elementId: 'caisse',
      pos: const GridPos(x: 12, y: 6),
    ),
  ],
  entities: const [
    MapEntity(
      id: 'depart',
      name: 'Départ',
      kind: MapEntityKind.spawn,
      pos: GridPos(x: 8, y: 9),
      spawn: MapEntitySpawnData(),
      blocksMovement: false,
    ),
  ],
);
