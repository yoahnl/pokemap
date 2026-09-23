import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/game_export/data/studio_game_export_controller.dart';
import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:path/path.dart' as p;

import '../support/game_export_fixture.dart';
import '../support/m3_story_fixture.dart';

void main() {
  late M3StoryFixture source;
  late Directory destination;
  late File output;
  final profile = GamePackageExportProfile(
    gameId: 'games.avelune.export-control',
    gameVersion: '0.1.0',
    title: 'Départ Avelune',
    authorName: 'Avelune',
    defaultLocale: 'fr',
    supportedLocales: const ['fr'],
  );

  setUp(() async {
    source = await M3StoryFixture.create();
    await prepareGameExportFixture(source);
    destination = await Directory.systemTemp.createTemp('as-exp-control-');
    output = File(p.join(destination.path, 'demo.avelunegame'));
  });
  tearDown(() async {
    await source.directory.delete(recursive: true);
    await destination.delete(recursive: true);
  });

  Future<bool> run(
    StudioGameExportController controller, {
    Future<bool> Function()? prepare,
    bool Function()? pending,
  }) => controller.export(
    metadata: StudioGameExportMetadata(
      gameId: profile.gameId,
      title: profile.title,
      version: profile.gameVersion,
      author: profile.authorName,
      locale: profile.defaultLocale,
      locales: profile.supportedLocales.join(', '),
    ),
    outputPath: output.path,
    overwriteConfirmed: false,
    publication: true,
    prepare: prepare ?? () async => true,
    hasPendingChanges: pending ?? () => false,
    isCurrentProject: () => true,
  );

  StudioGameExportController controller({
    BuildStudioGamePackage? build,
    WriteStudioGamePackage? write,
  }) => StudioGameExportController(
    projectRoot: source.directory,
    projectName: source.session.name,
    buildPackage: build,
    writePackage: write,
  );

  test(
    'invalid preparation preserves the draft and creates no package',
    () async {
      final owner = controller();
      addTearDown(owner.dispose);
      expect(await run(owner, prepare: () async => false), isFalse);
      expect(owner.stage, StudioExportStage.failed);
      expect(owner.error, contains('Enregistrement préalable refusé'));
      expect(await output.exists(), isFalse);
    },
  );

  test('an unreadable export profile is preserved and blocks export', () async {
    final profileFile = File(
      p.join(source.directory.path, '.pokemap', 'export-profile-v1.json'),
    );
    await profileFile.parent.create(recursive: true);
    await profileFile.writeAsString('{invalid', flush: true);
    final owner = controller();
    addTearDown(owner.dispose);
    await owner.load();
    expect(owner.canStart, isFalse);
    expect(owner.error, contains('Profil d’export illisible'));
    expect(await run(owner), isFalse);
    expect(await profileFile.readAsString(), '{invalid');
  });

  test('missing source resource prevents the package', () async {
    await File(p.join(source.directory.path, 'assets', 'atelier.png')).delete();
    final owner = controller();
    addTearDown(owner.dispose);
    expect(await run(owner), isFalse);
    expect(owner.stage, StudioExportStage.failed);
    expect(await output.exists(), isFalse);
  });

  test('cancelled build never writes a late result', () async {
    final gate = Completer<GamePackageExportArtifact>();
    final owner = controller(build: (_, _, _) => gate.future);
    addTearDown(owner.dispose);
    final pending = run(owner);
    while (owner.stage != StudioExportStage.building) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    owner.cancel();
    expect(owner.canStart, isFalse);
    gate.complete(
      await const CanonicalGamePackageExportService().build(
        projectRoot: source.directory,
        profile: profile,
      ),
    );
    expect(await pending, isFalse);
    expect(owner.canStart, isTrue);
    expect(owner.stage, StudioExportStage.cancelled);
    expect(await output.exists(), isFalse);
  });

  test('source change during construction refuses a mixed package', () async {
    final owner = controller(
      build: (root, profile, mode) async {
        final artifact = await const CanonicalGamePackageExportService().build(
          projectRoot: root,
          profile: profile,
          mode: mode,
        );
        final project = File(p.join(root.path, 'project.json'));
        await project.writeAsString(
          '${await project.readAsString()}\n',
          flush: true,
        );
        return artifact;
      },
    );
    addTearDown(owner.dispose);
    expect(await run(owner), isFalse);
    expect(owner.error, contains('changé pendant la construction'));
    expect(await output.exists(), isFalse);
  });

  test(
    'a destination created during construction is never overwritten',
    () async {
      final owner = controller(
        build: (root, profile, mode) async {
          final artifact = await const CanonicalGamePackageExportService()
              .build(projectRoot: root, profile: profile, mode: mode);
          await output.writeAsString('new existing file', flush: true);
          return artifact;
        },
      );
      addTearDown(owner.dispose);
      expect(await run(owner), isFalse);
      expect(owner.error, contains('existe désormais'));
      expect(await output.readAsString(), 'new existing file');
    },
  );

  test('write failure keeps output absent and a retry succeeds', () async {
    var attempts = 0;
    final owner = controller(
      write: (artifact, file) async {
        attempts++;
        if (attempts == 1) throw const FileSystemException('Write refused');
        await const CanonicalGamePackageExportService().writeArtifactToFile(
          artifact: artifact,
          outputFile: file,
        );
      },
    );
    addTearDown(owner.dispose);
    expect(await run(owner), isFalse);
    expect(await output.exists(), isFalse);
    expect(await run(owner), isTrue);
    expect(owner.stage, StudioExportStage.completed);
    expect(await output.exists(), isTrue);
  });

  test('a change during writing is excluded and announced', () async {
    final owner = controller(
      write: (artifact, file) async {
        final project = File(p.join(source.directory.path, 'project.json'));
        await project.writeAsString(
          '${await project.readAsString()}\n',
          flush: true,
        );
        await const CanonicalGamePackageExportService().writeArtifactToFile(
          artifact: artifact,
          outputFile: file,
        );
      },
    );
    addTearDown(owner.dispose);
    expect(await run(owner), isTrue);
    expect(owner.warning, contains('ne figurent pas'));
    expect(await output.exists(), isTrue);
  });

  test('canonical writer does not fall back over an existing file', () async {
    await output.writeAsString('old package', flush: true);
    final artifact = await const CanonicalGamePackageExportService().build(
      projectRoot: source.directory,
      profile: profile,
    );
    final service = CanonicalGamePackageExportService(
      atomicFileWriter:
          ({
            required outputFile,
            required packageBytes,
            required packageSha256,
          }) async {
            throw const FileSystemException('Atomic write refused');
          },
    );
    await expectLater(
      service.writeArtifactToFile(artifact: artifact, outputFile: output),
      throwsA(isA<GamePackageExportException>()),
    );
    expect(await output.readAsString(), 'old package');
  });
}
