import 'package:flutter_test/flutter_test.dart';

import 'dart_dependency_graph.dart';

void main() {
  final root = Uri.parse('file:///fixture/');

  DartDependencyGraph graph(Map<String, String> sources) =>
      DartDependencyGraph.fromPackageConfig(
        configUri: root.resolve('.dart_tool/package_config.json'),
        config: {
          'packages': [
            {'name': 'example', 'rootUri': '../vendor', 'packageUri': 'lib/'},
          ],
        },
        readSource: (uri) => sources[uri.toString()]!,
      );

  List<DartDependency> ioLeaks(DartDependencyGraph graph, String entry) => graph
      .walk([root.resolve(entry)], stopAt: (_) => false)
      .where((edge) => edge.specifier == 'dart:io')
      .toList();

  test('detecte I/O derriere un import relatif et un export', () {
    final dependencies = graph({
      '${root}app.dart': "import 'public.dart';",
      '${root}public.dart': "export 'private.dart';",
      '${root}private.dart': "import 'dart:io';",
    });
    final leaks = ioLeaks(dependencies, 'app.dart');
    expect(leaks, hasLength(1));
    expect(leaks.single.chain, [
      root.resolve('app.dart'),
      root.resolve('public.dart'),
      root.resolve('private.dart'),
    ]);
  });

  test('detecte I/O derriere un barrel package public', () {
    final dependencies = graph({
      '${root}app.dart': "import 'package:example/api.dart';",
      '${root}vendor/lib/api.dart': "export 'src/read.dart';",
      '${root}vendor/lib/src/read.dart': "import 'dart:io';",
    });
    final leaks = ioLeaks(dependencies, 'app.dart');
    expect(leaks, hasLength(1));
    expect(leaks.single.source, root.resolve('vendor/lib/src/read.dart'));
  });

  test('inspecte aussi les branches conditionnelles des exports', () {
    final dependencies = graph({
      '${root}app.dart':
          "export 'empty.dart' if (dart.library.io) 'native.dart';",
      '${root}empty.dart': '',
      '${root}native.dart': "import 'dart:io';",
    });
    expect(ioLeaks(dependencies, 'app.dart'), hasLength(1));
  });

  test('termine sur un cycle et accepte les SDK purs', () {
    final dependencies = graph({
      '${root}app.dart': "import 'other.dart';\nimport 'dart:async';",
      '${root}other.dart': "export 'app.dart';\nimport 'dart:collection';",
    });
    expect(ioLeaks(dependencies, 'app.dart'), isEmpty);
    expect(
      dependencies.walk([root.resolve('app.dart')], stopAt: (_) => false),
      hasLength(4),
    );
  });

  test('un package inconnu echoue au lieu de masquer une dependance', () {
    final dependencies = graph({
      '${root}app.dart': "import 'package:missing/api.dart';",
    });
    expect(() => ioLeaks(dependencies, 'app.dart'), throwsStateError);
  });
}
