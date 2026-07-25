import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/game_export.dart';
import 'package:path/path.dart' as p;

import 'game_export_test_fixture.dart';

void main() {
  test('projects a clean data-only runtime tree without mutating the author',
      () async {
    final root = await createAuthorProject();
    addTearDown(() => root.delete(recursive: true));

    final result = await const RuntimeProjectProjectionBuilder().build(
      projectRoot: root,
      profile: neutralExportProfile(),
    );

    expect(result.payloadFiles, contains('project/project.json'));
    expect(
      result.payloadFiles,
      contains('project/dialogues/dialogue.intro.json'),
    );
    expect(
      result.payloadFiles,
      contains('project/data/pokemon/media/creature.png'),
    );
    expect(result.payloadFiles, contains('presentation/icon.png'));
    expect(result.payloadFiles, contains('presentation/cover.png'));
    expect(result.payloadFiles, contains('legal/LICENSE.txt'));
    expect(result.payloadFiles, contains('legal/CREDITS.txt'));
    expect(
      result.payloadFiles.keys,
      isNot(contains('project/dialogues/intro.yarn')),
    );
    expect(
      result.payloadFiles.keys,
      isNot(contains('project/runtime_host_launch_save.json')),
    );
    expect(
      result.payloadFiles.keys.any((path) => path.contains('/saves/')),
      isFalse,
    );
    expect(result.compiledDialogueCount, 1);
    expect(result.scrubbedSecretFieldCount, 2);

    final projectedProject = jsonDecode(
      utf8.decode(result.payloadFiles['project/project.json']!),
    ) as Map<String, dynamic>;
    expect(
      projectedProject['settings'] as Map<String, dynamic>,
      isNot(contains('mistralApiKey')),
    );
    expect(
      projectedProject['globalProperties'] as Map<String, dynamic>,
      isNot(contains('apiKey')),
    );
    expect(
      (projectedProject['dialogues'] as List).single['relativePath'],
      'dialogues/dialogue.intro.json',
    );

    final projectedMap = jsonDecode(
      utf8.decode(result.payloadFiles['project/maps/start.json']!),
    ) as Map<String, dynamic>;
    expect(
      (projectedMap['dialogue'] as Map<String, dynamic>)['scriptPathRelative'],
      '',
    );
    final compiled = const RuntimeDialogueDocumentCodec().decodeUtf8(
      result.payloadFiles['project/dialogues/dialogue.intro.json']!,
    );
    expect(compiled.nodes.single.title, 'Start');

    final authorProject =
        await File(p.join(root.path, 'project.json')).readAsString();
    expect(
      authorProject,
      contains('fixture-secret-that-must-not-ship'),
    );
    expect(
      await File(p.join(root.path, 'dialogues', 'intro.yarn')).exists(),
      isTrue,
    );
  });

  test('rejects symlinks and branding paths outside the project root',
      () async {
    final root = await createAuthorProject(withDialogue: false);
    addTearDown(() => root.delete(recursive: true));
    final outside = await File(
      p.join(root.parent.path, 'pokemap-export-outside.png'),
    ).writeAsBytes(onePixelPng);
    addTearDown(() async {
      if (await outside.exists()) await outside.delete();
    });
    final link = Link(p.join(root.path, 'assets', 'linked.png'));
    await link.create(outside.path);

    expect(
      () => const RuntimeProjectProjectionBuilder().build(
        projectRoot: root,
        profile: neutralExportProfile(),
      ),
      throwsA(isA<GamePackageExportException>()),
    );
    expect(
      () => const RuntimeProjectProjectionBuilder().build(
        projectRoot: root,
        profile: neutralExportProfile().copyWith(iconPath: '../outside.png'),
      ),
      throwsA(isA<GamePackageExportException>()),
    );
  });

  test('enforces filesystem and file-size budgets before materializing bytes',
      () async {
    final root = await createAuthorProject(withDialogue: false);
    addTearDown(() => root.delete(recursive: true));

    expect(
      () => const RuntimeProjectProjectionBuilder(
        maxWorkspaceEntries: 1,
      ).build(
        projectRoot: root,
        profile: neutralExportProfile(),
      ),
      throwsA(
        isA<GamePackageExportException>().having(
          (error) => error.code,
          'code',
          'workspaceEntryQuotaExceeded',
        ),
      ),
    );
    await File(p.join(root.path, 'assets', 'oversized.png')).writeAsBytes(
      List<int>.filled(4097, 0),
      flush: true,
    );
    expect(
      () => const RuntimeProjectProjectionBuilder(
        maxFileBytes: 4096,
      ).build(
        projectRoot: root,
        profile: neutralExportProfile(),
      ),
      throwsA(
        isA<GamePackageExportException>().having(
          (error) => error.code,
          'code',
          'authoringFileTooLarge',
        ),
      ),
    );
  });
}
