import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'dart_dependency_graph.dart';

void main() {
  final appRoot = Directory.current;
  final lib = Directory('${appRoot.path}/lib');
  final sources = lib
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();
  final config = File('${appRoot.path}/.dart_tool/package_config.json');
  final graph = DartDependencyGraph.fromPackageConfig(
    config: jsonDecode(config.readAsStringSync()) as Map<String, Object?>,
    configUri: config.uri,
    readSource: (uri) => File.fromUri(uri).readAsStringSync(),
  );

  bool isFramework(DartDependency edge) =>
      edge.packageName == 'flutter' ||
      edge.packageName.startsWith('flutter_') ||
      edge.packageName.contains('riverpod') ||
      edge.packageName == 'flame' ||
      edge.packageName.startsWith('flame_');

  bool isInfrastructure(DartDependency edge) =>
      edge.target.pathSegments.contains('infrastructure') ||
      edge.target.pathSegments.contains('bootstrap');

  test('application et domaine restent purs dans leur graphe transitif', () {
    final entries = sources.where(
      (file) =>
          file.uri.pathSegments.contains('application') ||
          file.uri.pathSegments.contains('domain'),
    );
    expect(entries, isNotEmpty);
    final violations = graph
        .walk(entries.map((file) => file.uri), stopAt: isFramework)
        .where(
          (edge) =>
              isFramework(edge) ||
              isInfrastructure(edge) ||
              edge.specifier == 'dart:io' ||
              edge.specifier == 'dart:ui',
        );
    expect(violations.map((edge) => '$edge'), isEmpty);
  });

  test('presentation sans acces aux adaptateurs ou au filesystem', () {
    final entries = sources.where(
      (file) => file.uri.pathSegments.contains('presentation'),
    );
    expect(entries, isNotEmpty);
    bool isForbidden(DartDependency edge) =>
        isInfrastructure(edge) ||
        edge.specifier == 'dart:io' ||
        edge.packageName == 'file_picker' ||
        edge.packageName == 'file' ||
        edge.packageName == 'path_provider' ||
        edge.packageName.startsWith('path_provider_');
    final violations = graph
        .walk(
          entries.map((file) => file.uri),
          stopAt: (edge) => isFramework(edge) || isForbidden(edge),
        )
        .where(isForbidden);
    expect(violations.map((edge) => '$edge'), isEmpty);
  });

  test('aucun import prive inter-package dans les sources Studio', () {
    final violations = <String>[];
    for (final source in sources) {
      for (final specifier in graph.specifiers(source.uri)) {
        final uri = Uri.parse(specifier);
        if (uri.scheme == 'package' &&
            uri.pathSegments.first != 'avelune_studio' &&
            uri.pathSegments.contains('src')) {
          violations.add('${source.path}: $specifier');
        }
        final resolved = graph.resolve(source.uri, specifier);
        if (uri.scheme.isEmpty &&
            !resolved.toString().startsWith(lib.uri.toString())) {
          violations.add('${source.path}: sortie de lib via $specifier');
        }
      }
    }
    expect(violations, isEmpty);
  });

  test('aucune dependance vers ancien editeur', () {
    bool isForbidden(String name) => name == 'map_editor';
    final forbiddenPackages = graph.packageRoots.keys.where(isForbidden);
    expect(forbiddenPackages, isEmpty);
    final violations = graph
        .walk(
          sources.map((file) => file.uri),
          stopAt: (edge) =>
              isFramework(edge) || edge.packageName == 'map_runtime',
        )
        .where((edge) => isForbidden(edge.packageName));
    expect(violations.map((edge) => '$edge'), isEmpty);
  });

  test('fichiers Dart manuels limites a 300 lignes', () {
    final testSources = Directory('${appRoot.path}/test')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    final oversized = <String>[];
    for (final source in [...sources, ...testSources]) {
      final count = source.readAsLinesSync().length;
      if (count > 300) oversized.add('${source.path}: $count lignes');
    }
    expect(oversized, isEmpty);
  });
}
