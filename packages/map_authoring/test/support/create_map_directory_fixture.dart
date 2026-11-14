import 'dart:io';

import 'map_directory_fixture.dart';

Future<void> main(List<String> arguments) async {
  final fixture =
      await createMapDirectoryFixture(at: Directory(arguments.single));
  await fixture.close(delete: false);
}
