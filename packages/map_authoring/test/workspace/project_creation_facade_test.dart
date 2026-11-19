import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:map_authoring/map_authoring_project_creation.dart';
import 'package:test/test.dart';

void main() {
  test('creation facade exposes the usable port without platform dependencies',
      () {
    const request = ProjectCreationRequest(
        name: 'Jeu', folderName: 'jeu', parentPath: '/chosen/parent');
    expect(request.validate, returnsNormally);
    final configFile = File('.dart_tool/package_config.json').absolute;
    final config = jsonDecode(configFile.readAsStringSync()) as Map;
    final roots = <String, Uri>{};
    for (final item in config['packages'] as List) {
      final package = item as Map;
      var root = configFile.uri.resolve(package['rootUri'] as String);
      if (!root.path.endsWith('/')) root = root.replace(path: '${root.path}/');
      roots[package['name'] as String] =
          root.resolve(package['packageUri'] as String);
    }
    final visited = <Uri>{};
    final pending = [
      File('lib/map_authoring_project_creation.dart').absolute.uri
    ];
    final directiveExamples = {
      "import r'dart:io';": ['dart:io'],
      "import /* platform */ 'dart:ffi';": ['dart:ffi'],
      "import 'primary.dart' if (dart.library.io) r'platform.dart';": [
        'primary.dart',
        'platform.dart',
      ],
      "part 'shared.dart';": ['shared.dart'],
      "part of 'owner.dart';": <String>[],
      "bool matches(String part) => part == '.' || part != part.trim();":
          <String>[],
    };
    for (final example in directiveExamples.entries) {
      expect(_imports(example.key), example.value, reason: example.key);
    }
    while (pending.isNotEmpty) {
      final source = pending.removeLast();
      if (!visited.add(source)) continue;
      final text = File.fromUri(source).readAsStringSync();
      for (final specifier in _imports(text)) {
        expect(
            specifier,
            isNot(anyOf(
                'dart:io',
                'dart:ffi',
                startsWith('package:flutter/'),
                startsWith('package:flame/'),
                startsWith('package:map_editor/'),
                startsWith('package:map_runtime/'))),
            reason: '$source -> $specifier');
        final uri = Uri.parse(specifier);
        if (uri.scheme == 'dart') continue;
        pending.add(uri.scheme == 'package'
            ? roots[uri.pathSegments.first]!
                .resolve(uri.pathSegments.skip(1).join('/'))
            : source.resolveUri(uri));
      }
    }
    expect(
        visited,
        containsAll([
          roots['map_core']!.resolve('map_core_project_creation.dart'),
          roots['map_core']!.resolve('src/models/project_manifest.dart'),
        ]));
  });

  test('the portable creation request compiles to JavaScript', () async {
    final directory = await Directory.systemTemp.createTemp('creation-web-');
    addTearDown(() => directory.delete(recursive: true));
    final entry = File.fromUri(directory.uri.resolve('entry.dart'));
    await entry.writeAsString('''
import 'package:map_authoring/map_authoring_project_creation.dart';

void main() {
  const request = ProjectCreationRequest(
    name: 'Johto', folderName: 'johto', parentPath: '/projects',
  );
  request.validate();
  print(request.name);
}
''');
    final result = await Process.run('dart', [
      'compile',
      'js',
      '--packages=${File('.dart_tool/package_config.json').absolute.path}',
      entry.path,
      '-o',
      File.fromUri(directory.uri.resolve('entry.js')).path,
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
  });
}

Iterable<String> _imports(String source) sync* {
  final unit = parseString(content: source, throwIfDiagnostics: false).unit;
  for (final directive in unit.directives.whereType<UriBasedDirective>()) {
    yield directive.uri.stringValue!;
    if (directive is NamespaceDirective) {
      for (final configuration in directive.configurations) {
        yield configuration.uri.stringValue!;
      }
    }
  }
}
