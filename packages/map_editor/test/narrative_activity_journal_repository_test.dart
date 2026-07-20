import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/services/narrative_activity_journal.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_activity_journal_repository.dart';

void main() {
  group('NarrativeActivityJournalRepository', () {
    late Directory projectRoot;

    setUp(() async {
      projectRoot = await Directory.systemTemp.createTemp(
        'pokemap-narrative-activity-',
      );
    });

    tearDown(() async {
      if (await projectRoot.exists()) {
        await projectRoot.delete(recursive: true);
      }
    });

    test('loads an empty journal when no durable file exists', () async {
      final repository = NarrativeActivityJournalRepository(
        projectRootPath: projectRoot.path,
      );

      final journal = await repository.load();

      expect(journal.entries, isEmpty);
      expect(await File(repository.journalPath).exists(), isFalse);
    });

    test('persists activity and reloads it in a new repository', () async {
      final repository = NarrativeActivityJournalRepository(
        projectRootPath: projectRoot.path,
      );
      final journal = const NarrativeActivityJournal.empty().append(
        NarrativeActivityEntry(
          id: 'activity-reload',
          occurredAtUtc: DateTime.utc(2026, 7, 20, 12),
          kind: NarrativeActivityKind.saved,
          label: 'Narration enregistrée',
          destination: NarrativeActivityDestination.storylines,
          assetId: 'story-main',
        ),
      );

      await repository.save(journal);
      final reloaded = await NarrativeActivityJournalRepository(
        projectRootPath: projectRoot.path,
      ).load();

      expect(reloaded.toJson(), journal.toJson());
      expect(await File('${repository.journalPath}.tmp').exists(), isFalse);
    });

    test('rejects invalid JSON without replacing the evidence', () async {
      final repository = NarrativeActivityJournalRepository(
        projectRootPath: projectRoot.path,
      );
      final file = File(repository.journalPath);
      await file.parent.create(recursive: true);
      await file.writeAsString('{invalid', flush: true);

      await expectLater(repository.load(), throwsFormatException);
      expect(await file.readAsString(), '{invalid');
    });

    test('propagates write failure and leaves no advertised journal', () async {
      final blockedRoot = File('${projectRoot.path}/blocked');
      await blockedRoot.writeAsString('not a directory');
      final repository = NarrativeActivityJournalRepository(
        projectRootPath: blockedRoot.path,
      );

      await expectLater(
        repository.save(const NarrativeActivityJournal.empty()),
        throwsA(isA<FileSystemException>()),
      );
      expect(await File(repository.journalPath).exists(), isFalse);
    });

    test('uses a strict versioned envelope', () async {
      final repository = NarrativeActivityJournalRepository(
        projectRootPath: projectRoot.path,
      );
      final file = File(repository.journalPath);
      await file.parent.create(recursive: true);
      await file.writeAsString(
        jsonEncode(<String, Object?>{
          'schemaVersion': 99,
          'maxEntries': 100,
          'entries': const <Object?>[],
        }),
      );

      await expectLater(repository.load(), throwsFormatException);
    });
  });
}
