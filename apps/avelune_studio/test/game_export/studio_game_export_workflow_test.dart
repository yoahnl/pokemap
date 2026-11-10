import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/game_export/application/studio_game_export_workflow.dart';
import 'package:avelune_studio/features/game_export/data/studio_game_export_controller.dart';
import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/game_export_fixture.dart';
import '../support/m3_story_fixture.dart';

const _metadata = StudioGameExportMetadata(
  gameId: 'games.avelune.workflow',
  title: 'Mon aventure',
  version: '1.0.0',
  author: 'Avelune',
  locale: 'fr',
  locales: 'fr',
);

void main() {
  late M3StoryFixture fixture;
  late StudioGameExportController owner;
  late Directory destination;
  late File output;

  setUp(() async {
    fixture = await M3StoryFixture.create();
    await prepareGameExportFixture(fixture);
    destination = await Directory.systemTemp.createTemp(
      'studio-export-workflow-',
    );
    output = File('${destination.path}/output.avelunegame');
    owner = StudioGameExportController(
      projectRoot: fixture.directory,
      projectName: fixture.session.name,
    );
    await owner.load();
  });

  tearDown(() async {
    owner.dispose();
    await fixture.directory.delete(recursive: true);
    await destination.delete(recursive: true);
  });

  StudioGameExportWorkflow workflow(
    PickGameExportFile picker, {
    bool Function()? isCurrent,
    Future<void> Function()? onPublished,
  }) => StudioGameExportWorkflow(
    controller: owner,
    pickFile: picker,
    prepare: () async => true,
    hasPendingChanges: () => false,
    isCurrentProject: isCurrent ?? () => true,
    isActive: () => true,
    onPublished: onPublished,
  );

  test(
    'cancelling a destination creates no package or prepared operation',
    () async {
      var suggested = '';
      final session = workflow((name) async {
        suggested = name;
        return null;
      });
      addTearDown(session.dispose);
      expect(
        await session.run(
          metadata: _metadata,
          confirmOverwrite: (_) async => true,
        ),
        isFalse,
      );
      expect(suggested, 'mon-aventure-1.0.0.avelunegame');
      expect(session.selectingDestination, isFalse);
      expect(await output.exists(), isFalse);
      expect(owner.operationActive, isFalse);
    },
  );

  test(
    'a pending destination blocks another chooser and another export',
    () async {
      final pending = Completer<StudioGameExportDestination?>();
      var calls = 0;
      final session = workflow((_) {
        calls++;
        return pending.future;
      });
      addTearDown(session.dispose);
      final first = session.run(
        metadata: _metadata,
        confirmOverwrite: (_) async => true,
      );
      expect(session.selectingDestination, isTrue);
      expect(await session.chooseDestination(_metadata), isNull);
      expect(
        await session.run(
          metadata: _metadata,
          confirmOverwrite: (_) async => true,
        ),
        isFalse,
      );
      pending.complete(null);
      expect(await first, isFalse);
      expect(calls, 1);
      expect(session.canStart, isTrue);
    },
  );

  test(
    'a failed chooser retains its error and allows explicit retry',
    () async {
      var calls = 0;
      final session = workflow((_) async {
        if (calls++ == 0) throw StateError('destination unavailable');
        return StudioGameExportDestination(output.path, exists: false);
      });
      addTearDown(session.dispose);
      expect(await session.chooseDestination(_metadata), isNull);
      expect(session.inputError, contains('destination unavailable'));
      expect((await session.chooseDestination(_metadata))?.path, output.path);
      expect(session.inputError, isNull);
      expect(await output.exists(), isFalse);
    },
  );

  test(
    'refusing overwrite preserves the existing file and releases its guard',
    () async {
      await output.writeAsBytes([1, 2, 3]);
      final session = workflow(
        (_) async => StudioGameExportDestination(output.path, exists: true),
      );
      addTearDown(session.dispose);
      expect(
        await session.run(
          metadata: _metadata,
          confirmOverwrite: (_) async => false,
        ),
        isFalse,
      );
      expect(await output.readAsBytes(), [1, 2, 3]);
      expect(owner.outputPath, isNull);
      expect(session.canStart, isTrue);
    },
  );

  test(
    'a changed project discards a late destination without exporting',
    () async {
      var current = true;
      final pending = Completer<StudioGameExportDestination?>();
      final session = workflow((_) => pending.future, isCurrent: () => current);
      addTearDown(session.dispose);
      final operation = session.run(
        metadata: _metadata,
        confirmOverwrite: (_) async => true,
      );
      current = false;
      pending.complete(StudioGameExportDestination(output.path, exists: false));
      expect(await operation, isFalse);
      expect(session.destination, isNull);
      expect(await output.exists(), isFalse);
    },
  );

  test('a closed host refuses a late picker response', () async {
    final pending = Completer<StudioGameExportDestination?>();
    final session = workflow((_) => pending.future);
    final operation = session.run(
      metadata: _metadata,
      confirmOverwrite: (_) async => true,
    );
    session.dispose();
    pending.complete(StudioGameExportDestination(output.path, exists: false));
    expect(await operation, isFalse);
    expect(await output.exists(), isFalse);
    expect(owner.operationActive, isFalse);
  });

  test('the workflow writes a real package and confirms only its successful destination', () async {
    var publications = 0;
    final session = workflow(
      (_) async => StudioGameExportDestination(output.path, exists: false),
      onPublished: () async {
        publications++;
      },
    );
    addTearDown(session.dispose);
    expect(
      await session.run(
        metadata: _metadata,
        confirmOverwrite: (_) async => true,
      ),
      isTrue,
      reason: owner.error,
    );
    expect(await output.length(), greaterThan(0));
    expect(owner.outputPath, output.path);
    expect(owner.packageSha256, isNotEmpty);
    expect(session.destination!.exists, isTrue);
    expect(publications, 1);
    expect(owner.operationActive, isFalse);
  });
}
