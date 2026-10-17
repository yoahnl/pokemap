import 'dart:convert';
import 'dart:io';

import '../domains/assets/resource_pack_import_fixture.dart';

Future<void> main(List<String> arguments) async {
  final root = Directory(arguments.single);
  await root.create(recursive: true);
  final fixture = await ResourcePackImportFixture.create();
  try {
    await Directory('${root.path}/target').create();
    await File('${root.path}/target/project.json')
        .writeAsString(jsonEncode(fixture.snapshot.manifest.toJson()));
    final sink = File('${root.path}/source.aveluneassets').openWrite();
    await fixture.archive.withSource(
      (source) => sink.addStream(sourceChunks(source)),
    );
    await sink.close();
    stdout.writeln(
      jsonEncode({
        'metadata': fixture.archive.inspection.manifest.pack.toJson(),
      }),
    );
  } finally {
    await fixture.dispose();
  }
}
