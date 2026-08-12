import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_authoring_transaction.dart';
import 'package:map_editor/src/application/ports/narrative_authoring_persistence_gateway.dart';
import 'package:map_editor/src/application/services/narrative_document_session.dart';
import 'package:map_editor/src/application/services/narrative_undo_stack.dart';
import 'package:map_editor/src/infrastructure/repositories/file_narrative_document_recovery_store.dart';
import 'package:map_editor/src/infrastructure/repositories/project_manifest_narrative_document_gateway.dart';

void main() {
  group('FileNarrativeDocumentRecoveryStore', () {
    late Directory directory;
    late String journalPath;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('narrative-recovery-');
      journalPath = '${directory.path}/.pokemap/narrative-session.json';
    });

    tearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    test('round-trips the complete recovery envelope atomically', () async {
      final diagnostics = NarrativeRecoveryStoreDiagnostics();
      final store = FileNarrativeDocumentRecoveryStore<String>(
        journalPath: journalPath,
        encodeDocument: (document) => document,
        decodeDocument: (value) => value! as String,
        diagnostics: diagnostics,
      );
      const entry = NarrativeUndoEntry<String>(
        operationId: 'cinematic-title-1',
        label: 'Renommer la cinématique',
        before: 'avant',
        after: 'après',
      );
      const record = NarrativeDocumentRecoveryRecord<String>(
        documentId: 'cinematics',
        baseRevision: 'revision-A',
        baseline: 'avant',
        document: 'après',
        undoEntries: [entry],
        redoEntries: [entry],
      );

      await store.write(record);

      final restored = await store.read();
      expect(restored, isNotNull);
      expect(restored!.documentId, 'cinematics');
      expect(restored.baseRevision, 'revision-A');
      expect(restored.baseline, 'avant');
      expect(restored.document, 'après');
      expect(restored.undoEntries.single.operationId, 'cinematic-title-1');
      expect(restored.redoEntries.single.after, 'après');
      expect(await File('$journalPath.tmp').exists(), isFalse);
      expect(diagnostics.writeRequests, 1);
      expect(diagnostics.durableWrites, 1);
      expect(diagnostics.verificationReads, 1);
      expect(diagnostics.readRequests, 1);
      expect(diagnostics.bytesWritten, greaterThan(0));
      expect(diagnostics.bytesRead, greaterThan(0));

      await store.clear();
      expect(await File(journalPath).exists(), isFalse);
      expect(diagnostics.clearRequests, 1);
      expect(diagnostics.durableClears, 1);
    });

    test('reports malformed evidence without deleting it', () async {
      final journal = File(journalPath);
      await journal.parent.create(recursive: true);
      await journal.writeAsString('{not-json', flush: true);
      final store = FileNarrativeDocumentRecoveryStore<String>(
        journalPath: journalPath,
        encodeDocument: (document) => document,
        decodeDocument: (value) => value! as String,
      );

      await expectLater(store.read(), throwsFormatException);

      expect(await journal.exists(), isTrue);
      expect(await journal.readAsString(), '{not-json');
    });

    test(
      'serializes concurrent mutations and keeps the latest record',
      () async {
        final diagnostics = NarrativeRecoveryStoreDiagnostics();
        final store = FileNarrativeDocumentRecoveryStore<String>(
          journalPath: journalPath,
          encodeDocument: (document) => document,
          decodeDocument: (value) => value! as String,
          diagnostics: diagnostics,
        );
        final writes = List<Future<void>>.generate(20, (index) {
          return store.write(
            NarrativeDocumentRecoveryRecord<String>(
              documentId: 'personalization-studio',
              baseRevision: 'revision-A',
              baseline: 'baseline',
              document: '$index-${'x' * 65536}',
            ),
          );
        });

        await Future.wait(writes);

        final restored = await store.read();
        expect(restored?.document, startsWith('19-'));
        expect(await File('$journalPath.tmp').exists(), isFalse);
        expect(diagnostics.writeRequests, 20);
        expect(diagnostics.durableWrites, lessThan(20));
      },
    );
  });

  group('ProjectManifestNarrativeDocumentGateway', () {
    late Directory directory;
    late File projectFile;
    late ProjectManifest before;
    late CinematicAsset cinematic;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('narrative-gateway-');
      projectFile = File('${directory.path}/project.json');
      cinematic = _cinematic(title: 'Introduction');
      before = _project(cinematics: [cinematic]);
      await _writeManifest(projectFile, before);
    });

    tearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    test('refuses a manifest change outside the Cinematics pilot', () async {
      final persistence = _RecordingPersistence();
      final gateway = ProjectManifestNarrativeDocumentGateway(
        projectPath: projectFile.path,
        persistence: persistence,
      );
      final version = await gateway.read();
      final after = before.copyWith(name: 'Projet remplacé');

      final result = await gateway.save(
        expectedRevision: version.revision,
        before: before,
        after: after,
        operationId: 'rename-project',
      );

      expect(result, isA<NarrativeDocumentSaveFailed<ProjectManifest>>());
      expect(
        (result as NarrativeDocumentSaveFailed<ProjectManifest>).code,
        'unsupportedDocumentMutation',
      );
      expect(persistence.calls, 0);
    });

    test('refuses create, delete and multiple Cinematic changes', () async {
      final persistence = _RecordingPersistence();
      final gateway = ProjectManifestNarrativeDocumentGateway(
        projectPath: projectFile.path,
        persistence: persistence,
      );
      final version = await gateway.read();
      final second = _cinematic(id: 'cinematic_second', title: 'Seconde');
      final cases = <ProjectManifest>[
        before.copyWith(cinematics: [cinematic, second]),
        before.copyWith(cinematics: const []),
        before.copyWith(
          cinematics: [
            _cinematic(title: 'Introduction modifiée'),
            second,
          ],
        ),
      ];

      for (final after in cases) {
        final result = await gateway.save(
          expectedRevision: version.revision,
          before: before,
          after: after,
          operationId: 'unsupported-cinematic-shape',
        );
        expect(result, isA<NarrativeDocumentSaveFailed<ProjectManifest>>());
      }
      expect(persistence.calls, 0);
    });

    test(
      'maps stale persistence to a conflict with the external document',
      () async {
        final external = _project(
          cinematics: [_cinematic(title: 'Modification externe')],
        );
        final persistence = _RecordingPersistence(
          handler: (_) async {
            await _writeManifest(projectFile, external);
            return const NarrativeAuthoringPersistenceResult(
              status: NarrativeAuthoringPersistenceStatus.persistenceFailed,
              code: 'projectChangedBeforeCommit',
              message: 'Concurrent write.',
            );
          },
        );
        final gateway = ProjectManifestNarrativeDocumentGateway(
          projectPath: projectFile.path,
          persistence: persistence,
        );
        final version = await gateway.read();
        final after = before.copyWith(
          cinematics: [_cinematic(title: 'Modification locale')],
        );

        final result = await gateway.save(
          expectedRevision: version.revision,
          before: before,
          after: after,
          operationId: 'cinematic-title-local',
        );

        expect(result, isA<NarrativeDocumentSaveConflicted<ProjectManifest>>());
        final conflict =
            result as NarrativeDocumentSaveConflicted<ProjectManifest>;
        expect(conflict.code, 'projectChangedBeforeCommit');
        expect(conflict.external.document, external);
        expect(persistence.calls, 1);
      },
    );

    test(
      'returns the exact durable document and revision after commit',
      () async {
        late ProjectManifest after;
        final persistence = _RecordingPersistence(
          handler: (transaction) async {
            await _writeManifest(projectFile, transaction.after);
            return const NarrativeAuthoringPersistenceResult.committed();
          },
        );
        final gateway = ProjectManifestNarrativeDocumentGateway(
          projectPath: projectFile.path,
          persistence: persistence,
        );
        final version = await gateway.read();
        after = before.copyWith(
          cinematics: [_cinematic(title: 'Introduction enregistrée')],
        );

        final result = await gateway.save(
          expectedRevision: version.revision,
          before: before,
          after: after,
          operationId: 'cinematic-title-save',
        );

        expect(result, isA<NarrativeDocumentSaved<ProjectManifest>>());
        final saved = result as NarrativeDocumentSaved<ProjectManifest>;
        final durableBytes = await projectFile.readAsBytes();
        expect(saved.version.document, after);
        expect(
          saved.version.revision,
          narrativeEventBytesFingerprint(durableBytes),
        );
        expect(persistence.calls, 1);
        expect(
          persistence.lastTransaction!.mutation,
          isA<NarrativeAssetUpdated>(),
        );
      },
    );
  });
}

final class _RecordingPersistence
    implements NarrativeAuthoringPersistenceGateway {
  _RecordingPersistence({this.handler});

  final Future<NarrativeAuthoringPersistenceResult> Function(
    NarrativeAuthoringTransaction transaction,
  )?
  handler;
  int calls = 0;
  NarrativeAuthoringTransaction? lastTransaction;

  @override
  Future<NarrativeAuthoringPersistenceResult> persist(
    NarrativeAuthoringTransaction transaction,
  ) async {
    calls++;
    lastTransaction = transaction;
    if (handler case final callback?) {
      return callback(transaction);
    }
    return const NarrativeAuthoringPersistenceResult.committed();
  }
}

ProjectManifest _project({
  List<CinematicAsset> cinematics = const <CinematicAsset>[],
}) {
  return ProjectManifest(
    name: 'Narrative persistence test',
    maps: const [],
    tilesets: const [],
    cinematics: cinematics,
  );
}

CinematicAsset _cinematic({
  String id = 'cinematic_intro',
  required String title,
}) {
  return CinematicAsset(id: id, title: title, timeline: CinematicTimeline());
}

Future<void> _writeManifest(File file, ProjectManifest manifest) async {
  await file.parent.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
    flush: true,
  );
}
