import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tools/t01_dependency_graph.dart';
import '../../tools/t01_retirement_gate.dart';

void main() {
  final root = Uri.parse('file:///fixture/');
  const main = 'apps/avelune_studio/lib/main.dart';
  const added = 'apps/avelune_studio/lib/presentation/new_settings.dart';
  const old = 'apps/avelune_studio/lib/presentation/retired.dart';

  Map<String, Object?> inspect(
    Map<String, String> sources, {
    List<String>? scanned,
    List<Object?> exceptions = const [],
  }) => T01RetirementGate(
    graph: T01DependencyGraph(
      repository: root,
      packageRoots: const {},
      exists: (uri) =>
          sources.containsKey(uri.path.substring(root.path.length)),
      readSource: (uri) => sources[uri.path.substring(root.path.length)]!,
    ),
    inventory: {
      'schemaVersion': 1,
      'entries': [
        {
          'path': old,
          'category': 'studio_presentation',
          'widgetClasses': ['OldPanel'],
        },
      ],
    },
    allowlist: {'schemaVersion': 1, 'exceptions': exceptions},
  ).inspect(roots: [main], studioSources: scanned ?? sources.keys);

  List<Map> drift(Map<String, Object?> report) =>
      (report['violations']! as List)
          .cast<Map>()
          .where((value) => value['kind'] == 'unclassified_presentation')
          .toList();

  Map<String, Object?> reviewed(String source) => {
    'path': added,
    'symbols': ['TechnicalState'],
    'sha256': sha256.convert(utf8.encode(source)).toString(),
    'kind': 'non_visual',
    'reason': 'Reviewed technical data only',
    'approvedBy': 'independent-reviewer',
  };

  test('unreachable new settings UI cannot escape the frozen inventory', () {
    final report = inspect({
      main: 'void main() {}',
      added: 'class NewlyAddedSettings extends StatelessWidget {}',
    });
    expect(report['passed'], isFalse);
    expect(drift(report).single['path'], added);
    expect(drift(report).single['chain'], isEmpty);
  });

  test(
    'a new presentation utility still requires an explicit classification',
    () {
      final report = inspect({
        main: 'void main() {}',
        added: 'int value() => 1;',
      });
      expect(report['passed'], isFalse);
      expect(drift(report), hasLength(1));
    },
  );

  test('an exact reviewed nonvisual exception classifies a new file', () {
    const source = 'class TechnicalState {}';
    final report = inspect(
      {main: 'void main() {}', added: source},
      exceptions: [reviewed(source)],
    );
    expect(report['passed'], isTrue);
    expect(drift(report), isEmpty);
  });

  test('a source change invalidates classification of a newly added file', () {
    const source = 'class TechnicalState {}';
    final report = inspect(
      {main: 'void main() {}', added: '$source class NewChrome {}'},
      exceptions: [reviewed(source)],
    );
    expect(report['passed'], isFalse);
    expect(drift(report), hasLength(1));
    expect(
      (report['violations']! as List).cast<Map>().where(
        (item) => item['kind'] == 'exception',
      ),
      isNotEmpty,
    );
  });

  test(
    'reachable new UI is caught even when omitted from the physical listing',
    () {
      final report = inspect(
        {
          main: "import 'presentation/new_settings.dart';",
          added: 'class NewChrome {}',
        },
        scanned: [main],
      );
      expect(report['passed'], isFalse);
      expect(drift(report).single['chain'], [main, added]);
    },
  );

  test('known historical sources retain their physical retirement check', () {
    final report = inspect({main: 'void main() {}', old: 'class OldPanel {}'});
    expect(drift(report), isEmpty);
    expect(
      (report['violations']! as List).cast<Map>().where(
        (item) => item['kind'] == 'physical',
      ),
      hasLength(1),
    );
  });

  test('unclassified presentation outside Studio is not prohibited', () {
    final report = inspect({
      main: 'void main() {}',
      'apps/avelune_converter/lib/presentation/new_settings.dart':
          'class OtherChrome {}',
    });
    expect(report['passed'], isTrue);
    expect(drift(report), isEmpty);
  });
}
