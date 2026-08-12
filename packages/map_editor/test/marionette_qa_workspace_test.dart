import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/debug/marionette_qa_workspace.dart';
import 'package:path/path.dart' as p;

void main() {
  test('prepares an exact disposable project copy under Documents', () {
    final sourceRoot = Directory.systemTemp.createTempSync(
      'pokemap_marionette_source_',
    );
    final documentsRoot = Directory.systemTemp.createTempSync(
      'pokemap_marionette_documents_',
    );
    addTearDown(() => sourceRoot.deleteSync(recursive: true));
    addTearDown(() => documentsRoot.deleteSync(recursive: true));
    _writeProject(sourceRoot);

    final sourceFingerprint = MarionetteQaWorkspace.fingerprint(
      sourceRoot.path,
    );
    final workspace = MarionetteQaWorkspace.prepare(
      sourceProjectPath: sourceRoot.path,
      documentsRootPath: documentsRoot.path,
      runId: 'phase-b1',
    );

    expect(
      workspace.projectRootPath,
      p.join(
        documentsRoot.resolveSymbolicLinksSync(),
        'PokeMapMarionetteQA',
        'phase-b1',
      ),
    );
    expect(workspace.sourceFingerprint, sourceFingerprint);
    expect(workspace.copyFingerprint, sourceFingerprint);
    expect(
      MarionetteQaWorkspace.fingerprint(sourceRoot.path),
      sourceFingerprint,
    );
    expect(
      File(
        p.join(workspace.projectRootPath, 'maps', 'start.json'),
      ).readAsStringSync(),
      '{"id":"start"}\n',
    );
  });

  test('refuses to replace an existing disposable run', () {
    final sourceRoot = Directory.systemTemp.createTempSync(
      'pokemap_marionette_source_',
    );
    final documentsRoot = Directory.systemTemp.createTempSync(
      'pokemap_marionette_documents_',
    );
    addTearDown(() => sourceRoot.deleteSync(recursive: true));
    addTearDown(() => documentsRoot.deleteSync(recursive: true));
    _writeProject(sourceRoot);

    MarionetteQaWorkspace.prepare(
      sourceProjectPath: sourceRoot.path,
      documentsRootPath: documentsRoot.path,
      runId: 'existing-run',
    );

    expect(
      () => MarionetteQaWorkspace.prepare(
        sourceProjectPath: sourceRoot.path,
        documentsRootPath: documentsRoot.path,
        runId: 'existing-run',
      ),
      throwsStateError,
    );
  });

  test('rejects unsafe run identifiers and project symlinks', () {
    final sourceRoot = Directory.systemTemp.createTempSync(
      'pokemap_marionette_source_',
    );
    final documentsRoot = Directory.systemTemp.createTempSync(
      'pokemap_marionette_documents_',
    );
    final sourceLink = Link('${sourceRoot.path}_link')
      ..createSync(sourceRoot.path);
    addTearDown(() => sourceLink.deleteSync());
    addTearDown(() => sourceRoot.deleteSync(recursive: true));
    addTearDown(() => documentsRoot.deleteSync(recursive: true));
    _writeProject(sourceRoot);

    expect(
      () => MarionetteQaWorkspace.prepare(
        sourceProjectPath: sourceRoot.path,
        documentsRootPath: documentsRoot.path,
        runId: '../escape',
      ),
      throwsArgumentError,
    );
    expect(
      () => MarionetteQaWorkspace.prepare(
        sourceProjectPath: sourceLink.path,
        documentsRootPath: documentsRoot.path,
        runId: 'linked-source',
      ),
      throwsStateError,
    );
  });

  test('builds the deterministic macOS debug launch command', () {
    final plan = MarionetteQaLaunchPlan(
      packageRootPath: '/repo/packages/map_editor',
      projectRootPath: '/container/Documents/PokeMapMarionetteQA/run-42',
    );

    expect(plan.executable, 'flutter');
    expect(plan.workingDirectory, '/repo/packages/map_editor');
    expect(plan.arguments, <String>[
      'run',
      '-t',
      'dev/marionette_main.dart',
      '-d',
      'macos',
      '--debug',
      '--dart-define=MARIONETTE_PROJECT_PATH='
          '/container/Documents/PokeMapMarionetteQA/run-42',
    ]);
  });
}

void _writeProject(Directory root) {
  final maps = Directory(p.join(root.path, 'maps'))..createSync();
  File(p.join(root.path, 'project.json')).writeAsStringSync(
    '{"name":"Desktop QA","version":"v6","maps":[],"tilesets":[]}',
  );
  File(p.join(maps.path, 'start.json')).writeAsStringSync('{"id":"start"}\n');
}
