import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/debug/marionette_project_bootstrap.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:path/path.dart' as p;

void main() {
  test('loads a validated project into the deterministic initial state', () {
    final root = _writeProject();
    addTearDown(() => root.deleteSync(recursive: true));

    final canonicalRoot = root.resolveSymbolicLinksSync();
    final bootstrap = MarionetteProjectBootstrap.load(canonicalRoot);
    final state = bootstrap.createInitialState();

    expect(bootstrap.projectRootPath, canonicalRoot);
    expect(bootstrap.manifest.name, 'Desktop QA');
    expect(state.projectRootPath, bootstrap.projectRootPath);
    expect(state.project, same(bootstrap.manifest));
    expect(state.workspaceMode, EditorWorkspaceMode.map);
  });

  test('rejects an empty project define before rendering', () {
    expect(
      () => MarionetteProjectBootstrap.load('   '),
      throwsArgumentError,
    );
  });

  test('rejects a project root without project.json', () {
    final root = Directory.systemTemp.createTempSync('pokemap_qa_missing_');
    addTearDown(() => root.deleteSync(recursive: true));

    expect(
      () => MarionetteProjectBootstrap.load(root.path),
      throwsA(isA<StateError>()),
    );
  });

  test('rejects a symlink whose requested and resolved roots differ', () {
    final root = _writeProject();
    final link = Link('${root.path}_link')..createSync(root.path);
    addTearDown(() {
      if (link.existsSync()) link.deleteSync();
      root.deleteSync(recursive: true);
    });

    expect(
      () => MarionetteProjectBootstrap.load(link.path),
      throwsA(isA<StateError>()),
    );
  });
}

Directory _writeProject() {
  final root = Directory.systemTemp.createTempSync('pokemap_qa_project_');
  const manifest = ProjectManifest(
    name: 'Desktop QA',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
  );
  File(p.join(root.path, 'project.json')).writeAsStringSync(
    jsonEncode(manifest.toJson()),
  );
  return root;
}
