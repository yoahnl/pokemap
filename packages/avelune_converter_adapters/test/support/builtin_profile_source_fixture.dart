import 'dart:convert';

import 'literal_tile_fixture.dart';

Future<LiteralTileFixture> builtinProfileSourceFixture({
  required List<int> scriptsBytes,
  required String sourceRootPath,
}) =>
    LiteralTileFixture.create(
        sourceRootPath: sourceRootPath,
        scriptsBytes: scriptsBytes,
        includeEventSystem: true,
        extraFiles: {
          'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = Player\n'),
          'Data/map_metadata.dat': literalFixtureMarshal({}),
          'Data/map_connections.dat': literalFixtureMarshal([]),
          'Graphics/Characters/Player.png': literalFixtureAtlas(),
          'Graphics/Characters/Guide.png': literalFixtureAtlas(),
        },
        maps: [
          LiteralFixtureMap(id: 1, events: [
            const LiteralFixtureEvent(id: 1, x: 1, y: 0, pages: [
              LiteralFixtureEventPage(characterName: 'Guide', commands: [
                LiteralFixtureEventCommand(101, ['A source dialogue.']),
                LiteralFixtureEventCommand(0, []),
              ]),
            ]),
          ]),
        ]);
