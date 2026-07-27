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

  test('project presentation overrides legacy export-profile branding',
      () async {
    final root = await createAuthorProject(withDialogue: false);
    addTearDown(() => root.delete(recursive: true));
    final authoredIcon = File(p.join(root.path, 'assets', 'authored-icon.png'));
    await authoredIcon.writeAsBytes(<int>[1, 2, 3, 4], flush: true);
    final projectFile = File(p.join(root.path, 'project.json'));
    final project =
        jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>;
    project['presentation'] = <String, Object?>{
      'schemaVersion': 1,
      'branding': <String, Object?>{
        'iconPath': 'assets/authored-icon.png',
        'accentColor': '#123456',
        'layoutVariant': 'centered',
      },
    };
    await projectFile.writeAsString(jsonEncode(project), flush: true);

    final result = await const RuntimeProjectProjectionBuilder().build(
      projectRoot: root,
      profile: neutralExportProfile(),
    );

    expect(result.presentation.branding.iconPath, 'assets/authored-icon.png');
    expect(result.presentation.branding.accentColor, '#123456');
    expect(result.payloadFiles['presentation/icon.png'], <int>[1, 2, 3, 4]);
    final projectedProject = jsonDecode(
      utf8.decode(result.payloadFiles['project/project.json']!),
    ) as Map<String, dynamic>;
    expect(
      ((projectedProject['presentation'] as Map)['branding']
          as Map)['accentColor'],
      '#123456',
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

  test('rejects an image used as title music with a precise diagnostic',
      () async {
    final root = await createAuthorProject();
    addTearDown(() => root.delete(recursive: true));

    expect(
      () => const RuntimeProjectProjectionBuilder().build(
        projectRoot: root,
        profile: neutralExportProfile().copyWith(
          titleMusicPath: 'assets/icon.png',
        ),
      ),
      throwsA(
        isA<GamePackageExportException>()
            .having((error) => error.code, 'code', 'invalidTitleMusic')
            .having(
              (error) => error.path,
              'path',
              'assets/icon.png',
            ),
      ),
    );
  });

  test('normalizes decomposed macOS filenames and JSON references to NFC',
      () async {
    final root = await createAuthorProject(withDialogue: false);
    addTearDown(() => root.delete(recursive: true));
    const decomposedName = 'poke\u0301mon center.json';
    const composedName = 'pokémon center.json';
    final projectFile = File(p.join(root.path, 'project.json'));
    final project =
        jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>;
    (project['maps'] as List<Object?>)[0] = <String, Object?>{
      'id': 'map.start',
      'name': 'Centre Pokémon',
      'relativePath': 'maps/$decomposedName',
    };
    await projectFile.writeAsString(jsonEncode(project), flush: true);
    await File(p.join(root.path, 'maps', 'start.json')).rename(
      p.join(root.path, 'maps', decomposedName),
    );

    final result = await const RuntimeProjectProjectionBuilder().build(
      projectRoot: root,
      profile: neutralExportProfile(),
    );

    expect(
      result.payloadFiles,
      contains('project/maps/$composedName'),
    );
    expect(
      result.payloadFiles,
      isNot(contains('project/maps/$decomposedName')),
    );
    final projectedProject = jsonDecode(
      utf8.decode(result.payloadFiles['project/project.json']!),
    ) as Map<String, dynamic>;
    expect(
      (projectedProject['maps'] as List<Object?>)
          .cast<Map<String, dynamic>>()
          .single['relativePath'],
      'maps/$composedName',
    );
  });

  test('removes author-time remote asset URLs while keeping local assets',
      () async {
    final root = await createAuthorProject(withDialogue: false);
    addTearDown(() => root.delete(recursive: true));
    final catalog = File(p.join(root.path, 'data', 'items.json'));
    await catalog.writeAsString(
      jsonEncode(<String, Object?>{
        'entries': <Object?>[
          <String, Object?>{
            'id': 'potion',
            'spriteUrl': 'https://example.invalid/potion.png',
            'localSpritePath': 'assets/icon.png',
          },
        ],
      }),
      flush: true,
    );

    final result = await const RuntimeProjectProjectionBuilder().build(
      projectRoot: root,
      profile: neutralExportProfile(),
    );
    final projectedCatalog = jsonDecode(
      utf8.decode(result.payloadFiles['project/data/items.json']!),
    ) as Map<String, dynamic>;
    final item = (projectedCatalog['entries'] as List<Object?>)
        .cast<Map<String, dynamic>>()
        .single;

    expect(item, isNot(contains('spriteUrl')));
    expect(item['localSpritePath'], 'assets/icon.png');
  });
}
