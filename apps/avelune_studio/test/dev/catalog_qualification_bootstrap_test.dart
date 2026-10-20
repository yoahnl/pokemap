import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../dev/catalog_qualification_main.dart';
import '../../tool/create_example_project.dart' show writeExampleProject;

void main() {
  late Directory workspace;

  setUp(() async {
    final temporary = await Directory.systemTemp.createTemp('catalog-qa-');
    workspace = Directory(await temporary.resolveSymbolicLinks());
  });

  tearDown(() async {
    await workspace.delete(recursive: true);
  });

  test('requires an explicit absolute project path', () async {
    await expectLater(openCatalogQualificationProject(''), throwsArgumentError);
    await expectLater(
      openCatalogQualificationProject('remembered-project'),
      throwsArgumentError,
    );
  });

  test('refuses a missing directory before bootstrapping the app', () async {
    await expectLater(
      openCatalogQualificationProject('${workspace.path}/missing'),
      throwsStateError,
    );
  });

  test('refuses an alias of the configured project', () async {
    final project = await Directory('${workspace.path}/project').create();
    final alias = await Link('${workspace.path}/alias').create(project.path);
    await expectLater(
      openCatalogQualificationProject(alias.path),
      throwsStateError,
    );
  });

  test('refuses an invalid project without rendering a shell', () async {
    await File('${workspace.path}/project.json').writeAsString('{}');
    await expectLater(
      openCatalogQualificationProject(workspace.path),
      throwsStateError,
    );
  });

  test('opens only the requested project through the real adapter', () async {
    await writeExampleProject(workspace);
    final session = await openCatalogQualificationProject(workspace.path);
    try {
      expect(session.state.project?.directoryPath, workspace.path);
      expect(session.state.project?.name, 'Avelune · Atelier des cartes');
      expect(session.state.problem, isNull);
    } finally {
      await session.dispose();
    }
  });
}
