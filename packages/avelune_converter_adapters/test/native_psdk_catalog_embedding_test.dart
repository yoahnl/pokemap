import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  for (final invalid in ['hash', 'schema', 'path']) {
    test('catalog embedding rejects invalid $invalid before creating output',
        () async {
      final directory =
          await Directory.systemTemp.createTemp('catalog-embedding-');
      addTearDown(() => directory.delete(recursive: true));
      final hash = invalid == 'path' ? '../escape' : '0' * 64;
      final manifest = File('${directory.path}/manifest.json');
      await manifest.writeAsString(jsonEncode({
        'kind': 'nativePsdkCatalogManifest',
        'version': invalid == 'schema' ? 2 : 1,
        'shards': [hash],
      }));
      await File('${directory.path}/${'0' * 64}.json').writeAsString('{}');
      final output = '${directory.path}/generated.dart';
      final result = await Process.run('dart', [
        'run',
        'tool/build_native_psdk_trainer_bundle.dart',
        '--embed-catalog',
        manifest.path,
        directory.path,
        output,
      ]);
      expect(result.exitCode, isNot(0),
          reason: '${result.stdout}\n${result.stderr}');
      expect(await File(output).exists(), isFalse);
    }, timeout: const Timeout(Duration(minutes: 2)));
  }
}
