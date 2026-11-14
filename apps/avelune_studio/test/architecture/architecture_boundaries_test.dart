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

  bool isLocal(DartDependency edge) =>
      edge.target.toString().startsWith(lib.uri.toString());

  bool isComposition(DartDependency edge) =>
      isLocal(edge) && edge.target.pathSegments.contains('app');

  bool isInfrastructure(DartDependency edge) =>
      edge.target.pathSegments.contains('infrastructure') ||
      edge.target.pathSegments.contains('bootstrap') ||
      (isLocal(edge) &&
          (edge.target.pathSegments.contains('data') ||
              edge.target.pathSegments.contains('platform') ||
              (isComposition(edge) &&
                  !edge.target.pathSegments.contains('di'))));

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
              isComposition(edge) ||
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

  test('theme et widgets partages independants des features et de la DI', () {
    final entries = sources.where(
      (file) =>
          file.path.contains('/presentation/theme/') ||
          file.path.contains('/presentation/shared/widgets/'),
    );
    expect(entries, isNotEmpty);
    bool forbidden(DartDependency edge) =>
        isInfrastructure(edge) ||
        isComposition(edge) ||
        (isLocal(edge) && edge.target.pathSegments.contains('features'));
    final violations = graph
        .walk(
          entries.map((file) => file.uri),
          stopAt: (edge) => isFramework(edge) || forbidden(edge),
        )
        .where(forbidden);
    expect(violations.map((edge) => '$edge'), isEmpty);
  });

  test('presentation centralisee et barrel DI limite aux exports', () {
    expect(sources.where((file) => file.path.contains('/lib/src/')), isEmpty);
    expect(
      sources.where(
        (file) =>
            file.path.contains('/features/') &&
            file.path.contains('/presentation/') &&
            !file.path.contains('/lib/presentation/features/'),
      ),
      isEmpty,
    );
    final barrel = File('${lib.path}/app/di/providers.dart');
    expect(barrel.existsSync(), isTrue);
    final lines = barrel.readAsLinesSync().where(
      (line) => line.trim().isNotEmpty,
    );
    expect(lines.every((line) => line.startsWith('export ')), isTrue);
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

  test('constructeur de carte sans port ni action de scene', () {
    final builder = sources.where(
      (file) => file.path.contains('/lib/presentation/features/map_builder/'),
    );
    expect(builder, isNotEmpty);
    final scenePorts = '${lib.uri}features/scenes/domain/';
    final sceneAction = RegExp('[\'"]scene\\.');
    final violations = <String>[];
    for (final source in builder) {
      for (final specifier in graph.specifiers(source.uri)) {
        final target = graph.resolve(source.uri, specifier).toString();
        if (target.startsWith(scenePorts) && target.endsWith('_port.dart')) {
          violations.add('${source.path}: $specifier');
        }
      }
      if (sceneAction.hasMatch(source.readAsStringSync())) {
        violations.add('${source.path}: action scene.*');
      }
    }
    expect(violations, isEmpty);
  });

  final l10n = {
    for (final line in File('${appRoot.path}/l10n.yaml').readAsLinesSync())
      if (line.indexOf(':') case final index when index > 0)
        line.substring(0, index).trim(): line.substring(index + 1).trim(),
  };
  final generatedOutput = File(
    '${appRoot.path}/${l10n['output-dir'] ?? l10n['arb-dir']}/'
    '${l10n['output-localization-file']}',
  );
  final generatedLocalizations = {
    generatedOutput.path,
    for (final specifier in graph.specifiers(generatedOutput.uri))
      if (Uri.parse(specifier).scheme.isEmpty)
        File.fromUri(graph.resolve(generatedOutput.uri, specifier)).path,
  };

  test('fichiers generes par gen-l10n reconnus', () {
    final arbFiles = Directory('${appRoot.path}/${l10n['arb-dir']}')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.arb'));
    expect(generatedLocalizations, hasLength(arbFiles.length + 1));
    for (final path in generatedLocalizations) {
      expect(
        File(path).readAsStringSync(),
        contains('ignore_for_file: type=lint'),
      );
    }
  });

  test('fichiers Dart manuels limites a 350 lignes', () {
    final testSources = Directory('${appRoot.path}/test')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    final oversized = <String>[];
    for (final source in [
      ...sources.where((file) => !generatedLocalizations.contains(file.path)),
      ...testSources,
    ]) {
      final count = source.readAsLinesSync().length;
      if (count > 350) oversized.add('${source.path}: $count lignes');
    }
    expect(oversized, isEmpty);
  });
}
