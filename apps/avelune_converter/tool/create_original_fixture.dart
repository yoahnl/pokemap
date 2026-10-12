import 'dart:convert';
import 'dart:io';

import '../../../packages/avelune_converter_adapters/test/support/literal_tile_fixture.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 1 || !arguments.single.startsWith('/')) {
    stderr.writeln(
      'Usage: create_original_fixture.dart NEW_ABSOLUTE_DIRECTORY',
    );
    exitCode = 2;
    return;
  }
  final destination = arguments.single;
  if (await FileSystemEntity.type(destination, followLinks: false) !=
      FileSystemEntityType.notFound) {
    throw FileSystemException(
      'The fixture directory must be new.',
      destination,
    );
  }
  final parent = await Directory(destination).parent.resolveSymbolicLinks();
  if (parent == '/') {
    throw FileSystemException(
      'A local working directory is required.',
      destination,
    );
  }
  final ground = List<int>.generate(
    64,
    (cell) => cell % 8 == 3 || cell % 8 == 4 ? 391 : 384,
  );
  final overlay = List<int>.generate(
    64,
    (cell) => cell ~/ 8 == 2 && cell % 8 >= 5 ? 392 : 0,
  );
  final fixture = await LiteralTileFixture.create(
    namespace: 'avelune-original-offline-fixture',
    sourceRootPath: destination,
    maps: [
      LiteralFixtureMap(
        id: 1,
        name: 'Original fixture — local conversion',
        width: 8,
        height: 8,
        layers: [ground, overlay, List<int>.filled(64, 0)],
      ),
      LiteralFixtureMap(
        id: 8,
        name: 'Original fixture — second map',
        width: 8,
        height: 8,
        layers: [
          ground.reversed.toList(),
          List<int>.filled(64, 0),
          List<int>.filled(64, 0),
        ],
      ),
    ],
  );
  await File('$destination/FIXTURE_LICENSE.txt').writeAsString(
    'Original synthetic fixture created for Avelune Converter qualification.\n'
    'The images are generated colored rectangles, not Pokemon media.\n'
    'The Ruby Marshal data is inert; no Ruby script is included or executed.\n'
    'This is conversion study data, not a certified playable game.\n',
    flush: true,
  );
  stdout.writeln(
    jsonEncode({
      'kind': 'originalOfflineFixture',
      'version': 1,
      'directory': destination,
      'sourceScriptsExecuted': 0,
      'aiCalls': 0,
      'files': {
        for (final entry in fixture.sourceBytes.entries)
          entry.key: literalFixtureHash(entry.value).value,
      },
    }),
  );
}
