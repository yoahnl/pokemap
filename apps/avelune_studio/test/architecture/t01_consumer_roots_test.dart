import 'package:flutter_test/flutter_test.dart';

import '../../tools/t01_consumer_entries.dart';
import '../../tools/t01_dependency_graph.dart';
import '../../tools/t01_retirement_gate.dart';

void main() {
  final root = Uri.parse('file:///fixture/');
  const main = 'apps/avelune_studio/lib/main.dart';
  const historical = 'apps/avelune_studio/lib/presentation/panel.dart';
  const hubEntry = 'apps/pokemap_hub/test/from_studio.dart';

  T01DependencyGraph graph(
    Map<String, String> sources, {
    Map<String, Uri> packages = const {},
  }) => T01DependencyGraph(
    repository: root,
    packageRoots: packages,
    exists: (uri) => sources.containsKey(uri.path.substring(root.path.length)),
    readSource: (uri) => sources[uri.path.substring(root.path.length)]!,
  );

  T01RetirementGate gate(Map<String, String> sources) => T01RetirementGate(
    graph: graph(sources),
    inventory: {
      'schemaVersion': 1,
      'entries': [
        {
          'path': historical,
          'category': 'studio_presentation',
          'widgetClasses': ['OldPanel'],
        },
      ],
    },
    allowlist: {'schemaVersion': 1, 'exceptions': <Object?>[]},
  );

  test(
    'discovers actual package and relative consumers without text matches',
    () {
      expect(
        t01StudioConsumerEntries({
          'actual.dart': "import 'package:avelune_studio/app/host.dart';",
          'relative.dart':
              "export '../avelune_studio/test/support/fixture.dart';",
          'comment.dart': "// import 'package:avelune_studio/old.dart';",
          'string.dart': 'final text = "package:avelune_studio/old.dart";',
          'similar.dart': "import 'package:another/avelune_studio.dart';",
        }),
        ['actual.dart', 'relative.dart'],
      );
    },
  );

  test('includes a test or native harness even when main is neutral', () {
    const harness = 'apps/avelune_studio/integration_test/native_test.dart';
    final sources = {
      main: 'void main() {}',
      harness: "import '../lib/presentation/panel.dart';",
      historical: 'class OldPanel {}',
    };
    final result = gate(sources)
        .inspect(roots: [main, harness], studioSources: sources.keys);
    final violations = (result['violations']! as List).cast<Map>();
    expect(
      violations
          .where((item) => item['kind'] == 'reachability')
          .single['chain'],
      [harness, historical],
    );
    expect(result['passed'], isFalse);
  });

  test('resolves external consumers with their own package configuration', () {
    final sources = {
      main: 'void main() {}',
      hubEntry: "import 'package:hub_only/bridge.dart';",
      'apps/pokemap_hub/lib/bridge.dart':
          "export 'package:avelune_studio/presentation/panel.dart';",
      historical: 'class OldPanel {}',
    };
    final result = gate(sources).inspect(
      roots: [main],
      studioSources: [main, hubEntry],
      consumerScopes: [
        T01ConsumerScope(
          'hub',
          graph(
            sources,
            packages: {
              'hub_only': root.resolve('apps/pokemap_hub/lib/'),
              'avelune_studio': root.resolve('apps/avelune_studio/lib/'),
            },
          ),
          [hubEntry],
        ),
      ],
    );
    final violations = (result['violations']! as List).cast<Map>();
    final reachable = violations
        .where((item) => item['kind'] == 'reachability')
        .single;
    expect(reachable['context'], 'hub');
    expect(reachable['chain'], [
      hubEntry,
      'apps/pokemap_hub/lib/bridge.dart',
      historical,
    ]);
    expect(violations.where((item) => item['kind'] == 'resolution'), isEmpty);
    expect((result['contexts']! as List), hasLength(2));
  });

  test('fails closed when an external consumer cannot resolve a package', () {
    final sources = {
      main: 'void main() {}',
      hubEntry: "import 'package:unknown/bridge.dart';",
    };
    final result = gate(sources).inspect(
      roots: [main],
      studioSources: sources.keys,
      consumerScopes: [
        T01ConsumerScope('hub', graph(sources), [hubEntry]),
      ],
    );
    final violations = (result['violations']! as List).cast<Map>();
    expect(violations.single['kind'], 'resolution');
    expect(violations.single['context'], 'hub');
    expect(result['passed'], isFalse);
  });

  test('ignores historical symbols in comments and diagnostic strings', () {
    final sources = {
      main: 'void main() {}',
      hubEntry: 'final diagnostic = "OldPanel is forbidden"; // OldPanel',
    };
    final result = gate(sources)
        .inspect(roots: [main], studioSources: sources.keys);
    expect(result['passed'], isTrue);
  });

  test(
    'discovers all Unys native entries independently of filename ordering',
    () {
      final names = [
        'thin_pilot_native_main.dart',
        'raster_support_native_main_20261016.dart',
        'raster_calibrated_native_main_20261016.dart',
        'main_project_calibrated_native_20261016.dart',
      ];
      final sources = {
        for (final name in names)
          'apps/unys_3d_sources/$name':
              "import '../avelune_studio/dev/marionette_main.dart';",
        'apps/unys_3d_sources/diagnostic.dart':
            'final message = "avelune_studio/dev/marionette_main.dart";',
      };
      expect(t01StudioConsumerEntries(sources), [
        for (final name in names) 'apps/unys_3d_sources/$name',
      ]);
    },
  );

  test('does not prohibit shared design system use by Converter outside Studio', () {
    final sources = {
      main: 'void main() {}',
      'apps/avelune_converter/lib/main.dart':
          "import 'package:avelune_design_system/avelune_design_system.dart';",
      'packages/avelune_design_system/lib/avelune_design_system.dart':
          'class SharedPanel {}',
    };
    final result = gate(sources).inspect(roots: [main], studioSources: [main]);
    expect(result['passed'], isTrue);
    expect((result['contexts']! as List).cast<Map>().single['name'], 'studio');
  });
}
