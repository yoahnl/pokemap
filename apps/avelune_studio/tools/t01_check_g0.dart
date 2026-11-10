import 'dart:convert';
import 'dart:io';

import 't01_consumer_entries.dart';
import 't01_dependency_graph.dart';
import 't01_retirement_gate.dart';

void main(List<String> arguments) {
  try {
    final options = <String, String>{};
    for (var index = 0; index < arguments.length; index += 2) {
      if (index + 1 >= arguments.length ||
          !{
            '--root',
            '--inventory',
            '--allowlist',
          }.contains(arguments[index])) {
        throw const FormatException(
          'Usage: dart run tools/t01_check_g0.dart '
          '[--root repository] [--inventory JSON] [--allowlist JSON]',
        );
      }
      options[arguments[index]] = arguments[index + 1];
    }
    final root = Directory(
      Directory(options['--root'] ?? '../..').resolveSymbolicLinksSync(),
    ).uri;
    Map<String, Object?> readJson(Uri uri) =>
        jsonDecode(File.fromUri(uri).readAsStringSync())
            as Map<String, Object?>;
    final config = root.resolve(
      'apps/avelune_studio/.dart_tool/package_config.json',
    );
    final inventory = root.resolve(
      options['--inventory'] ??
          'documentation/reports/avelune_studio/plans/'
              '2026-11-09-constructeur-cartes/ui-retirement-inventory.json',
    );
    final app = root.resolve('apps/avelune_studio/lib/');
    final graph = T01DependencyGraph.fromConfig(
      repository: root,
      configUri: config,
      config: readJson(config),
      readSource: (uri) => File.fromUri(uri).readAsStringSync(),
      exists: (uri) => File.fromUri(uri).existsSync(),
    );
    List<File> dartSources(String directory, {bool recursive = true}) {
      final folder = Directory.fromUri(root.resolve(directory));
      if (!folder.existsSync()) return [];
      return folder
          .listSync(recursive: recursive)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();
    }

    final sources = dartSources('apps/avelune_studio/lib/');
    final harnesses = [
      ...dartSources('apps/avelune_studio/test/'),
      ...dartSources('apps/avelune_studio/dev/'),
      ...dartSources('apps/avelune_studio/integration_test/'),
    ];
    final hubSources = {
      for (final file in dartSources('apps/pokemap_hub/test/'))
        graph.relative(file.absolute.uri): file.readAsStringSync(),
    };
    final hubRoots = t01StudioConsumerEntries(hubSources);
    final unysRoots = t01StudioConsumerEntries({
      for (final file in dartSources('apps/unys_3d_sources/', recursive: false))
        graph.relative(file.absolute.uri): file.readAsStringSync(),
    });
    final hubConfig = root.resolve(
      'apps/pokemap_hub/.dart_tool/package_config.json',
    );
    final consumerScopes = <T01ConsumerScope>[
      if (hubRoots.isNotEmpty)
        T01ConsumerScope(
          'pokemap_hub',
          T01DependencyGraph.fromConfig(
            repository: root,
            configUri: hubConfig,
            config: readJson(hubConfig),
            readSource: (uri) => File.fromUri(uri).readAsStringSync(),
            exists: (uri) => File.fromUri(uri).existsSync(),
          ),
          hubRoots,
          resolverConfig: graph.relative(hubConfig),
        ),
      if (unysRoots.isNotEmpty)
        T01ConsumerScope(
          'unys_3d_sources',
          T01DependencyGraph.fromConfig(
            repository: root,
            configUri: config,
            config: readJson(config),
            readSource: (uri) => File.fromUri(uri).readAsStringSync(),
            exists: (uri) => File.fromUri(uri).existsSync(),
          ),
          unysRoots,
          resolverConfig: graph.relative(config),
        ),
    ];
    final gallery = app.resolve('design_gallery.dart');
    final result =
        T01RetirementGate(
          graph: graph,
          inventory: readJson(inventory),
          allowlist: options['--allowlist'] == null
              ? {'schemaVersion': 1, 'exceptions': <Object?>[]}
              : readJson(root.resolve(options['--allowlist']!)),
        ).inspect(
          roots: [
            graph.relative(app.resolve('main.dart')),
            if (File.fromUri(gallery).existsSync()) graph.relative(gallery),
            for (final file in harnesses) graph.relative(file.absolute.uri),
          ],
          studioSources: [
            for (final file in [...sources, ...harnesses])
              graph.relative(file.absolute.uri),
            ...hubRoots,
            ...unysRoots,
          ],
          consumerScopes: consumerScopes,
        );
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(result));
    exitCode = result['passed'] == true ? 0 : 1;
  } catch (error) {
    stdout.writeln(
      jsonEncode({
        'schemaVersion': 1,
        'gate': 'G0',
        'proofTier': 'static_retirement',
        'passed': false,
        'violations': [
          {'kind': 'configuration', 'message': '$error', 'chain': <String>[]},
        ],
      }),
    );
    exitCode = 2;
  }
}
