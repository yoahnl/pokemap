import 'package:flutter_test/flutter_test.dart';

import '../../tools/t01_dependency_graph.dart';

void main() {
  final root = Uri.parse('file:///fixture/');
  const main = 'apps/avelune_studio/lib/main.dart';
  const source = 'packages/shared/lib/src/application/entry.dart';
  const target = 'packages/shared/lib/domain/api.dart';
  const outside = 'packages/shared/domain/api.dart';
  const byPackage = "import 'package:shared/src/application/entry.dart';";
  const byFile =
      "import '../../../packages/shared/lib/src/application/entry.dart';";

  T01DependencyGraph graph(Map<String, String> sources) => T01DependencyGraph(
    repository: root,
    packageRoots: {'shared': root.resolve('packages/shared/lib/')},
    exists: (uri) => sources.containsKey(uri.path.substring(root.path.length)),
    readSource: (uri) => sources[uri.path.substring(root.path.length)]!,
  );

  Map<String, String> sources(String entry) => {
    main: entry,
    source: "export '../../../domain/api.dart';",
    target: 'class Marker {}',
  };

  test('package relative parents clamp at the package library root like the compiler', () {
    final result = graph(sources(byPackage)).walk([main]);
    expect(result.errors, isEmpty);
    expect(result.chains[target], [main, source, target]);
    expect(result.chains, isNot(contains(outside)));
  });

  test(
    'the same source loaded through a file path retains a missing-source error',
    () {
      final result = graph(sources(byFile)).walk([main]);
      expect(result.errors, hasLength(1));
      expect(result.errors.single['path'], source);
      expect(
        result.errors.single['sourceUri'],
        root.resolve(source).toString(),
      );
      expect(result.chains, isNot(contains(target)));
    },
  );

  for (final packageFirst in [true, false]) {
    test(
      'package and file contexts of one physical source are both traversed packageFirst=$packageFirst',
      () {
        final result = graph(
          sources(packageFirst ? '$byPackage $byFile' : '$byFile $byPackage'),
        ).walk([main]);
        expect(result.errors, hasLength(1));
        expect(
          result.errors.single['sourceUri'],
          root.resolve(source).toString(),
        );
        expect(result.chains[target], [main, source, target]);
      },
    );
  }

  test(
    'a package import never falls back to a similarly named file outside lib',
    () {
      final fixture = sources(byPackage)..remove(target);
      fixture[outside] = 'class OutsideMarker {}';
      final result = graph(fixture).walk([main]);
      expect(result.errors, hasLength(1));
      expect(
        result.errors.single['sourceUri'],
        'package:shared/src/application/entry.dart',
      );
      expect(result.chains, isNot(contains(outside)));
    },
  );

  test('an explicit file URI preserves file semantics even beside a package import', () {
    final fileImport = "import '${root.resolve(source)}';";
    final result = graph(sources('$byPackage $fileImport')).walk([main]);
    expect(result.errors, hasLength(1));
    expect(result.errors.single['path'], source);
    expect(result.errors.single['sourceUri'], root.resolve(source).toString());
    expect(result.chains, contains(target));
  });
}
