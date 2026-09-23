import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/game_export/data/studio_game_export_controller.dart';
import 'package:avelune_studio/features/game_export/data/studio_export_revision.dart';
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
    bool overwriteConfirmed = false,
    bool Function()? isCurrentProject,
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
    overwriteConfirmed: overwriteConfirmed,
    publication: true,
    prepare: prepare ?? () async => true,
    hasPendingChanges: pending ?? () => false,
    isCurrentProject: isCurrentProject ?? () => true,
  );

  StudioGameExportController controller({
    BuildStudioGamePackage? build,
    WriteStudioGamePackage? write,
    ReadStudioSourceFingerprints? readFingerprints,
    CheckStudioExportDestination? destinationExists,
  }) => StudioGameExportController(
    projectRoot: source.directory,
    projectName: source.session.name,
    buildPackage: build,
    writePackage: write,
    readFingerprints: readFingerprints,
    destinationExists: destinationExists,
  );

  Future<GamePackageExportArtifact> build(
    Directory root,
    GamePackageExportProfile profile,
    GamePackageExportMode mode,
  ) => const CanonicalGamePackageExportService().build(
    projectRoot: root,
    profile: profile,
    mode: mode,
  );

  test(
    'cancel during the final source read prevents writing and allows retry',
    () async {
      final reading = Completer<void>();
      final release = Completer<void>();
      var reads = 0;
      var writes = 0;
      final owner = controller(
        build: build,
        readFingerprints: (root) async {
          if (++reads == 2) {
            reading.complete();
            await release.future;
          }
          return sourceFingerprints(root);
        },
        write: (artifact, file) async {
          writes++;
          await const CanonicalGamePackageExportService().writeArtifactToFile(
            artifact: artifact,
            outputFile: file,
          );
        },
      );
      addTearDown(owner.dispose);
      final first = run(owner);
      await reading.future;
      expect(owner.canCancel, isTrue);
      owner.cancel();
      expect(owner.canStart, isFalse);
      expect(owner.operationActive, isTrue);
      expect(await run(owner), isFalse);
      release.complete();
      expect(await first, isFalse);
      expect(writes, 0);
      expect(await output.exists(), isFalse);
      expect(
        await File(
          p.join(source.directory.path, '.pokemap', 'export-profile-v1.json'),
        ).exists(),
        isFalse,
      );
      expect(owner.outputPath, isNull);
      expect(owner.packageSha256, isNull);
      expect(owner.operationActive, isFalse);
      expect(await run(owner), isTrue);
      expect(writes, 1);
      expect(await output.exists(), isTrue);
    },
  );

  test(
    'cancel before confirmed replacement preserves existing bytes',
    () async {
      final original = <int>[0, 1, 2, 253, 254, 255];
      await output.writeAsBytes(original, flush: true);
      final reading = Completer<void>();
      final release = Completer<void>();
      var reads = 0;
      var writes = 0;
      final owner = controller(
        build: build,
        readFingerprints: (root) async {
          if (++reads == 2) {
            reading.complete();
            await release.future;
          }
          return sourceFingerprints(root);
        },
        write: (artifact, file) async {
          writes++;
          await const CanonicalGamePackageExportService().writeArtifactToFile(
            artifact: artifact,
            outputFile: file,
          );
        },
      );
      addTearDown(owner.dispose);
      final pending = run(owner, overwriteConfirmed: true);
      await reading.future;
      owner.cancel();
      release.complete();
      expect(await pending, isFalse);
      expect(writes, 0);
      expect(await output.readAsBytes(), original);
      expect(owner.packageSha256, isNull);
    },
  );

  test('cancel during destination existence check prevents writing', () async {
    final checking = Completer<void>();
    final release = Completer<void>();
    var writes = 0;
    final owner = controller(
      build: build,
      destinationExists: (file) async {
        checking.complete();
        await release.future;
        return file.exists();
      },
      write: (artifact, file) async {
        writes++;
        await const CanonicalGamePackageExportService().writeArtifactToFile(
          artifact: artifact,
          outputFile: file,
        );
      },
    );
    addTearDown(owner.dispose);
    final pending = run(owner);
    await checking.future;
    owner.cancel();
    release.complete();
    expect(await pending, isFalse);
    expect(writes, 0);
    expect(await output.exists(), isFalse);
  });

  test(
    'project invalidation before writing produces no late success',
    () async {
      final reading = Completer<void>();
      final release = Completer<void>();
      var reads = 0;
      var current = true;
      var writes = 0;
      final owner = controller(
        build: build,
        readFingerprints: (root) async {
          if (++reads == 2) {
            reading.complete();
            await release.future;
          }
          return sourceFingerprints(root);
        },
        write: (artifact, file) async => writes++,
      );
      addTearDown(owner.dispose);
      final pending = run(owner, isCurrentProject: () => current);
      await reading.future;
      current = false;
      release.complete();
      expect(await pending, isFalse);
      expect(writes, 0);
      expect(await output.exists(), isFalse);
      expect(owner.stage, isNot(StudioExportStage.completed));
      expect(owner.packageSha256, isNull);
    },
  );

  test(
    'late post-write source read cannot publish success for another project',
    () async {
      final reading = Completer<void>();
      final release = Completer<void>();
      var reads = 0;
      var current = true;
      final owner = controller(
        build: build,
        readFingerprints: (root) async {
          if (++reads == 3) {
            reading.complete();
            await release.future;
          }
          return sourceFingerprints(root);
        },
        write: (artifact, file) => const CanonicalGamePackageExportService()
            .writeArtifactToFile(artifact: artifact, outputFile: file),
      );
      addTearDown(owner.dispose);
      final pending = run(owner, isCurrentProject: () => current);
      await reading.future;
      expect(owner.canCancel, isFalse);
      current = false;
      release.complete();
      expect(await pending, isFalse);
      expect(await output.exists(), isTrue);
      expect(owner.stage, isNot(StudioExportStage.completed));
      expect(owner.packageSha256, isNull);
    },
  );

  test(
    'writing stays visible and cannot be cancelled after it starts',
    () async {
      final writing = Completer<void>();
      final release = Completer<void>();
      final owner = controller(
        write: (artifact, file) async {
          writing.complete();
          await release.future;
          await const CanonicalGamePackageExportService().writeArtifactToFile(
            artifact: artifact,
            outputFile: file,
          );
        },
      );
      addTearDown(owner.dispose);
      final pending = run(owner);
      await writing.future;
      expect(owner.stage, StudioExportStage.writing);
      expect(owner.operationActive, isTrue);
      expect(owner.canCancel, isFalse);
      owner.cancel();
      expect(owner.stage, StudioExportStage.writing);
      expect(owner.operationActive, isTrue);
      release.complete();
      expect(await pending, isTrue);
      expect(owner.stage, StudioExportStage.completed);
      expect(await output.exists(), isTrue);
    },
  );
}
