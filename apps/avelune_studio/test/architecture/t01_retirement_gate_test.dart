import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tools/t01_dart_lexing.dart';
import '../../tools/t01_dependency_graph.dart';
import '../../tools/t01_retirement_gate.dart';

void main() {
  final root = Uri.parse('file:///fixture/');
  const app = 'apps/avelune_studio/lib/';
  const old = '${app}presentation/old.dart';

  T01DependencyGraph graph(Map<String, String> files) => T01DependencyGraph(
    repository: root,
    packageRoots: {
      'avelune_studio': root.resolve(app),
      'shared': root.resolve('packages/shared/lib/'),
    },
    readSource: (uri) => files[uri.path.substring(root.path.length)]!,
    exists: (uri) => files.containsKey(uri.path.substring(root.path.length)),
  );

  Map<String, Object?> inventory({String path = old}) => {
    'schemaVersion': 1,
    'entries': [
      {
        'path': path,
        'category': 'studio_presentation',
        'widgetClasses': ['OldPanel'],
      },
    ],
  };

  Map<String, Object?> run(
    Map<String, String> files, {
    Map<String, Object?>? allowlist,
    List<String>? roots,
  }) =>
      T01RetirementGate(
        graph: graph(files),
        inventory: inventory(),
        allowlist: allowlist ?? {'schemaVersion': 1, 'exceptions': []},
      ).inspect(
        roots: roots ?? ['${app}main.dart'],
        studioSources: files.keys.where((path) => path.startsWith(app)),
      );

  List<Object?> violations(Map<String, Object?> result, String kind) =>
      (result['violations']! as List<Object?>)
          .where((value) => (value! as Map)['kind'] == kind)
          .toList();

  test('lexes comments, raw strings, nested comments and deferred imports', () {
    final source = """
// import 'ignored.dart';
/* outer /* import 'nested.dart'; */ still comment */
import /* gap */ 'real.dart' deferred as real;
export 'empty.dart' if (dart.library.io) 'native.dart';
part 'piece.dart';
part of 'parent.dart';
final message = r"import 'also_ignored.dart';";
final multiline = '''import 'multiline.dart';''';
""";
    expect(t01Directives(source), [
      'real.dart',
      'empty.dart',
      'native.dart',
      'piece.dart',
    ]);
    expect(() => t01Tokens('/* unfinished'), throwsFormatException);
    expect(() => t01Tokens("import 'unfinished"), throwsFormatException);
  });

  test(
    'follows packages, exports, parts and cycles with an explicit chain',
    () {
      final files = {
        '${app}main.dart': "import 'package:shared/public.dart';",
        'packages/shared/lib/public.dart': "export 'piece.dart';",
        'packages/shared/lib/piece.dart': "part 'end.dart';",
        'packages/shared/lib/end.dart': "import 'public.dart';",
      };
      final result = graph(files).walk(['${app}main.dart']);
      expect(result.errors, isEmpty);
      expect(result.chains['packages/shared/lib/end.dart'], [
        '${app}main.dart',
        'packages/shared/lib/public.dart',
        'packages/shared/lib/piece.dart',
        'packages/shared/lib/end.dart',
      ]);
      expect(result.chains, hasLength(4));
    },
  );

  test('ignores interpolation strings and ordinary part variables', () {
    expect(
      t01Directives(r'''
import 'real.dart';
final part = 'not_a_directive.dart';
final value = "${call("nested 'import ignored.dart'")}";
final other = "${{'key': 'quoted'}}";
'''),
      ['real.dart'],
    );
  });

  test('normalizes package roots without a trailing slash', () {
    final files = {
      '${root}app.dart': "export 'package:example/public.dart';",
      '${root}vendor/lib/public.dart': '',
    };
    final dependencies = T01DependencyGraph.fromConfig(
      repository: root,
      configUri: root.resolve('.dart_tool/package_config.json'),
      config: {
        'packages': [
          {'name': 'example', 'rootUri': '../vendor', 'packageUri': 'lib/'},
        ],
      },
      exists: (uri) => files.containsKey(uri.toString()),
      readSource: (uri) => files[uri.toString()]!,
    );
    final result = dependencies.walk(['app.dart']);
    expect(result.errors, isEmpty);
    expect(result.chains.keys, contains('vendor/lib/public.dart'));
  });

  test('rejects an unlisted shared design system barrel', () {
    final result = run({
      '${app}main.dart':
          "import '../../../packages/avelune_design_system/lib/api.dart';",
      'packages/avelune_design_system/lib/api.dart': 'class SharedPanel {}',
    });
    expect(violations(result, 'reachability'), hasLength(1));
    expect(violations(result, 'physical'), isEmpty);
  });

  test('fails closed on unknown packages and missing conditional branches', () {
    final result = run({
      '${app}main.dart':
          "import 'package:unknown/api.dart'; "
          "export 'present.dart' if (dart.library.io) 'absent.dart';",
      '${app}present.dart': '',
    });
    expect(result['passed'], isFalse);
    expect(violations(result, 'resolution'), hasLength(2));
    expect((violations(result, 'resolution').first! as Map)['chain'], [
      '${app}main.dart',
    ]);
  });

  test('physical absence is independent from entrypoint reachability', () {
    final result = run({
      '${app}main.dart': 'void main() {}',
      old: 'class OldPanel {}',
    });
    expect(violations(result, 'physical'), hasLength(1));
    expect(violations(result, 'reachability'), isEmpty);
    expect(result['passed'], isFalse);
  });

  test('detects a historical composition through barrels and parts', () {
    final result = run({
      '${app}main.dart': "import 'barrel.dart';",
      '${app}barrel.dart': "export 'presentation/old.dart';",
      old: "part 'old_part.dart'; class OldPanel {}",
      '${app}presentation/old_part.dart': 'part of "old.dart";',
    });
    final violation = violations(result, 'reachability').first! as Map;
    expect(violation['chain'], ['${app}main.dart', '${app}barrel.dart', old]);
  });

  test('finds relocated historical symbols outside presentation', () {
    final result = run({
      '${app}main.dart': 'void main() {}',
      '${app}platform/hidden.dart': 'class OldPanel {}',
    });
    expect(violations(result, 'historical_symbol'), hasLength(1));
  });

  test('scans every retained entrypoint including design gallery', () {
    final result = run(
      {
        '${app}main.dart': 'void main() {}',
        '${app}design_gallery.dart': "import 'presentation/old.dart';",
        old: 'class OldPanel {}',
      },
      roots: ['${app}main.dart', '${app}design_gallery.dart'],
    );
    expect(violations(result, 'reachability'), hasLength(1));
  });

  test('permits only exact reviewed symbols and source fingerprint', () {
    const source = 'class OldPanel extends InheritedWidget {}';
    final allowlist = {
      'schemaVersion': 1,
      'exceptions': [
        {
          'path': old,
          'symbols': ['OldPanel'],
          'sha256': sha256.convert(utf8.encode(source)).toString(),
          'kind': 'non_visual',
          'reason': 'Technical visibility scope without editor chrome',
          'approvedBy': 'independent-reviewer',
        },
      ],
    };
    final files = {
      '${app}main.dart': "import 'presentation/old.dart';",
      old: source,
    };
    expect(run(files, allowlist: allowlist)['passed'], isTrue);
    files[old] = '$source class HiddenPanel {}';
    final result = run(files, allowlist: allowlist);
    expect(result['passed'], isFalse);
    expect(violations(result, 'exception'), isNotEmpty);
    expect(violations(result, 'physical'), isNotEmpty);
  });

  test('accepts only reviewed viewport kinds and rejects a legacy UI kind', () {
    const source = 'class OldPanel extends StatelessWidget {}';
    final files = {
      '${app}main.dart': "import 'presentation/old.dart';",
      old: source,
    };
    Map<String, Object?> allowlist(String kind) => {
      'schemaVersion': 1,
      'exceptions': [
        {
          'path': old,
          'symbols': ['OldPanel'],
          'sha256': sha256.convert(utf8.encode(source)).toString(),
          'kind': kind,
          'reason': 'Reviewed technical surface without chrome',
          'approvedBy': 'independent-reviewer',
        },
      ],
    };
    for (final kind in ['neutral_host', 'player_surface', 'render_surface']) {
      expect(run(files, allowlist: allowlist(kind))['passed'], isTrue);
    }
    final rejected = run(files, allowlist: allowlist('legacy_ui'));
    expect(rejected['passed'], isFalse);
    expect(violations(rejected, 'exception'), isNotEmpty);
  });

  test('rejects directory exceptions and shared historical UI', () {
    final result = run(
      {
        '${app}main.dart':
            "import '../../../packages/map_editor/lib/src/ui/panel.dart';",
        'packages/map_editor/lib/src/ui/panel.dart': 'class EditorPanel {}',
      },
      allowlist: {
        'schemaVersion': 1,
        'exceptions': [
          {
            'path': '${app}presentation/*',
            'symbols': ['*'],
          },
        ],
      },
    );
    expect(violations(result, 'exception'), isNotEmpty);
    expect(violations(result, 'reachability'), isNotEmpty);
  });

  test(
    'allows a clean host and leaves external shared consumers untouched',
    () {
      final result = run({
        '${app}main.dart': 'void main() {}',
        'packages/map_editor/lib/src/ui/panel.dart': 'class EditorPanel {}',
      });
      expect(result['passed'], isTrue);
      expect(result['schemaVersion'], 1);
      expect(result['gate'], 'G0');
      expect(result['proofTier'], 'static_retirement');
    },
  );
}
