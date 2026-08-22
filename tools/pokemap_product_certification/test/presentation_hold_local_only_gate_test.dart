import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// BETA-CIN-084 — the expensive run stays local and explicit.
///
/// The ticket's other named risk is "ajout accidentel d'une CI macOS coûteuse".
/// Fifty hold cycles in two orientations with real decoding is exactly the kind
/// of job that gets wired into a workflow by a well-meaning later change and
/// then costs money on every push. So the constraint is a test rather than a
/// convention: the journey and its CLI may appear nowhere in
/// `.github/workflows`, and this fails the moment someone schedules them.
///
/// AGENTS.md already states the CI cost discipline. This is the part that bites.
void main() {
  final repositoryRoot = _repositoryRoot();
  final workflows = Directory(p.join(repositoryRoot.path, '.github', 'workflows'));

  const localOnlyMarkers = <String>[
    'presentation_hold_performance_journey_test',
    'certify_presentation_hold_performance',
    'POKEMAP_CIN084_OUTPUT',
  ];

  test('the workflows directory is where it is expected', () {
    expect(
      workflows.existsSync(),
      isTrue,
      reason: 'a moved workflows directory would make this gate vacuous, '
          'which is worse than no gate at all',
    );
    expect(
      workflows.listSync().whereType<File>().where(
            (file) => const <String>{'.yml', '.yaml'}.contains(
              p.extension(file.path),
            ),
          ),
      isNotEmpty,
      reason: 'the gate must be reading real workflow files',
    );
  });

  test('no workflow schedules the interactive hold journey', () {
    final offenders = <String>[];
    for (final file in workflows.listSync().whereType<File>()) {
      if (!const <String>{'.yml', '.yaml'}.contains(p.extension(file.path))) {
        continue;
      }
      final contents = file.readAsStringSync();
      for (final marker in localOnlyMarkers) {
        if (contents.contains(marker)) {
          offenders.add('${p.basename(file.path)} references $marker');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'BETA-CIN-084 is a local, opt-in measurement: fifty hold cycles '
          'with real decoding in two orientations must not run on a hosted '
          'macOS runner on every push',
    );
  });

  test('the release workflow gains no certification dependency', () {
    final release = File(
      p.join(workflows.path, 'release_control_center.yml'),
    );
    expect(release.existsSync(), isTrue);
    final contents = release.readAsStringSync();
    for (final marker in localOnlyMarkers) {
      expect(
        contents,
        isNot(contains(marker)),
        reason: 'a release must not wait on a local profiling journey',
      );
    }
  });
}

Directory _repositoryRoot() {
  var current = Directory.current;
  while (true) {
    if (Directory(p.join(current.path, '.github')).existsSync() &&
        File(p.join(current.path, 'AGENTS.md')).existsSync()) {
      return current;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Repository root not found from ${Directory.current}');
    }
    current = parent;
  }
}
