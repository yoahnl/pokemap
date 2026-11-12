import 'dart:io';

import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../dev/ui_atlas_main.dart';

void main() {
  test('only accepts the owned project directory beside captures', () async {
    final root = Directory(
      '/Users/karim/Library/Caches/AveluneQA/studio-ui-atlas-20261103',
    );
    await root.create(recursive: true);
    final fixture = await root.createTemp('project-guard-');
    addTearDown(() => fixture.delete(recursive: true));
    final project = await Directory(p.join(fixture.path, 'project')).create();
    final captures = await Directory(p.join(fixture.path, 'captures')).create();

    expect(await requireAtlasProject(project.path, captures), project.path);
    await expectLater(requireAtlasProject('', captures), throwsStateError);
    await expectLater(
      requireAtlasProject(p.join(fixture.path, 'other'), captures),
      throwsStateError,
    );
    await expectLater(
      requireAtlasProject(
        '${fixture.path}/../${p.basename(fixture.path)}/project',
        captures,
      ),
      throwsStateError,
    );
    await project.delete();
    final external = await Directory(p.join(fixture.path, 'external')).create();
    final alias = Link(project.path);
    await alias.create(external.path);
    await expectLater(
      requireAtlasProject(alias.path, captures),
      throwsStateError,
    );
  });
  test('preserves the underlying project-open error for diagnosis', () async {
    final root = Directory(
      '/Users/karim/Library/Caches/AveluneQA/studio-ui-atlas-20261103',
    );
    await root.create(recursive: true);
    final fixture = await root.createTemp('error-guard-');
    addTearDown(() => fixture.delete(recursive: true));
    final errorFile = File(p.join(fixture.path, 'startup-error.txt'));
    final port = AtlasProjectSessionPort(_FailingPort(), errorFile);

    await expectLater(port.open('project'), throwsStateError);
    expect(await errorFile.readAsString(), contains('original failure'));
  });
}

final class _FailingPort implements ProjectSessionPort {
  @override
  Future<ProjectSession> open(
    String directoryPath, {
    void Function(ProjectOpeningPhase phase)? onPhase,
  }) async => throw StateError('original failure');

  @override
  Future<void> close(ProjectSession session) async {}
}
