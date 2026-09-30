import 'dart:convert';
import 'dart:io';

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
    final directives = RegExp(r'^\s*(?:import|export|part(?!\s+of))\s+([^;]+);',
        multiLine: true);
    final strings = RegExp("['\"]([^'\"]+)['\"]");
    while (pending.isNotEmpty) {
      final source = pending.removeLast();
      if (!visited.add(source)) continue;
      final text = File.fromUri(source).readAsStringSync();
      for (final match in directives.allMatches(text)) {
        for (final literal in strings.allMatches(match.group(1)!)) {
          final specifier = literal.group(1)!;
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
    }
    expect(
        visited, contains(roots['map_core']!.resolve('map_core_domain.dart')));
  });
}
