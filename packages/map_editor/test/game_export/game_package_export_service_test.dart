import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_editor/game_export.dart';
import 'package:path/path.dart' as p;

import 'game_export_test_fixture.dart';

void main() {
  test('persists stable metadata and rejects deriving identity implicitly',
      () async {
    final root = await createAuthorProject(withDialogue: false);
    addTearDown(() => root.delete(recursive: true));
    final store = GamePackageExportProfileStore(projectRoot: root);
    final profile = neutralExportProfile();

    await store.save(profile);
    expect(await store.load(), profile);
    expect(
      () => GamePackageExportProfile(
        gameId: '',
        gameVersion: '1.0.0',
        title: 'A title is not an identity',
        authorName: 'Author',
        defaultLocale: 'fr',
        supportedLocales: const <String>['fr'],
      ),
      throwsA(isA<GamePackageExportException>()),
    );
  });

  test('builds, reopens and writes a deterministic certified package',
      () async {
    final root = await createAuthorProject();
    addTearDown(() => root.delete(recursive: true));
    const service = GamePackageExportService();
    final profile = neutralExportProfile();

    final first = await service.build(
      projectRoot: root,
      profile: profile,
    );
    final second = await service.build(
      projectRoot: root,
      profile: profile,
    );

    expect(first.packageBytes, second.packageBytes);
    expect(first.certification.isCertified, isTrue);
    expect(first.manifest.gameId, profile.gameId);
    expect(first.manifest.title, profile.title);
    expect(first.inspection.manifest.content.treeSha256,
        first.manifest.content.treeSha256);
    expect(
      first.inspection.payloadPaths,
      contains('project/dialogues/dialogue.intro.json'),
    );
    expect(
      first.inspection.payloadPaths,
      isNot(contains('project/dialogues/intro.yarn')),
    );

    final output = File(p.join(root.parent.path, first.suggestedFileName));
    addTearDown(() async {
      if (await output.exists()) await output.delete();
    });
    final written = await service.exportToFile(
      projectRoot: root,
      profile: profile,
      outputFile: output,
    );
    expect(await output.readAsBytes(), written.packageBytes);
    expect(
      const GamePackageInspector().inspect(await output.readAsBytes()).manifest,
      isA<GamePackageManifest>(),
    );
  });

  test(
      'falls back to a verified direct write when macOS denies sibling staging',
      () async {
    final root = await createAuthorProject();
    addTearDown(() => root.delete(recursive: true));
    var atomicWriteAttempted = false;
    final service = GamePackageExportService(
      atomicFileWriter: ({
        required outputFile,
        required packageBytes,
        required packageSha256,
      }) async {
        atomicWriteAttempted = true;
        throw FileSystemException(
          'Operation not permitted',
          '${outputFile.path}.sandbox-stage.tmp',
          const OSError('Operation not permitted', 1),
        );
      },
    );
    final output = File(
      p.join(root.parent.path, 'sandbox-selected.pokemapgame'),
    );
    addTearDown(() async {
      if (await output.exists()) await output.delete();
    });

    final artifact = await service.exportToFile(
      projectRoot: root,
      profile: neutralExportProfile(),
      outputFile: output,
    );

    expect(atomicWriteAttempted, isTrue);
    expect(await output.readAsBytes(), artifact.packageBytes);
    expect(
      const GamePackageInspector().inspect(await output.readAsBytes()).manifest,
      isA<GamePackageManifest>(),
    );
    expect(await File('${output.path}.backup').exists(), isFalse);
  });

  test('refuses a required capability outside the Phase 0 host contract',
      () async {
    final root = await createAuthorProject(withDialogue: false);
    addTearDown(() => root.delete(recursive: true));
    final profile = neutralExportProfile().copyWith(
      requiredCapabilities: const <String>['engine.extension@1'],
    );

    await expectLater(
      const GamePackageExportService().build(
        projectRoot: root,
        profile: profile,
      ),
      throwsA(
        isA<GamePackageExportException>().having(
          (error) => error.code,
          'code',
          'capabilityUnsupported',
        ),
      ),
    );
  });
}
