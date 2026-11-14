import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';

import 'narrative_title_fixture.dart';

Future<void> main(List<String> arguments) async {
  final root = Directory(arguments.single);
  final fixture = await NarrativeTitleFixture.create(
      at: root, project: narrativeTitleProject(unrelated: 1));
  await fixture.close(delete: false);
  final map = File('${root.path}/maps/map_0.json');
  await map.parent.create(recursive: true);
  await map.writeAsString(jsonEncode(const MapData(
    id: 'map_0',
    name: 'Map 0',
    size: GridSize(width: 6, height: 6),
    entities: [
      MapEntity(
          id: 'tree',
          name: 'Tree',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 1, y: 1),
          npc: MapEntityNpcData(displayName: 'Tree')),
    ],
  ).toJson()));
}
