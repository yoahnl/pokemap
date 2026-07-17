import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/infrastructure/repositories/journaled_file_promotion_repository.dart';
import 'package:map_editor/src/infrastructure/repositories/project_manifest_write_lock.dart';
import 'package:path/path.dart' as p;

import 'support/selbrume_event_v2_fixture.dart';

const _allowedDestinations = <String>{
  'selbrume/project.json',
  'selbrume/maps/map_port_brisants.json',
  'selbrume/maps/map_marais_salants.json',
  'selbrume/dialogues/lysa_port.yarn',
};

void main() {
  group('J5 journaled Selbrume promotion', () {
    test('resumes idempotently after every durable write boundary', () async {
      for (var interruptedBoundary = 0;
          interruptedBoundary <= 4;
          interruptedBoundary++) {
        final sandbox = await _PromotionSandbox.create();
        try {
          final interrupted = await sandbox.repository(
            faultInjector: (renamedFileCount) async {
              if (renamedFileCount == interruptedBoundary) {
                throw StateError('Injected boundary $interruptedBoundary');
              }
            },
          ).promote();
          expect(
            interrupted.status,
            JournaledFilePromotionStatus.recoveryRequired,
            reason: 'boundary $interruptedBoundary: ${interrupted.code}',
          );
          expect(await File(sandbox.journalPath).exists(), isTrue);
          expect(
            await Directory('${sandbox.journalPath}.checkpoint').exists(),
            isTrue,
          );

          final resumed = await sandbox.repository().promote();
          expect(
            resumed.status,
            JournaledFilePromotionStatus.promoted,
            reason: 'boundary $interruptedBoundary: ${resumed.code}',
          );
          await sandbox.expectAfterHashes();
          expect(await File(sandbox.journalPath).exists(), isFalse);
          expect(
            await Directory('${sandbox.journalPath}.checkpoint').exists(),
            isFalse,
          );

          final replayed = await sandbox.repository().promote();
          expect(replayed.status, JournaledFilePromotionStatus.noOp);
          await sandbox.expectAfterHashes();
        } finally {
          await sandbox.dispose();
        }
      }
    });

    test('rebuilds an interrupted checkpoint before any destination write',
        () async {
      for (var interruptedBoundary = 1;
          interruptedBoundary <= 4;
          interruptedBoundary++) {
        final sandbox = await _PromotionSandbox.create();
        try {
          final interrupted = await sandbox.repository(
            checkpointFaultInjector: (checkpointedFileCount) async {
              if (checkpointedFileCount == interruptedBoundary) {
                throw StateError(
                  'Injected checkpoint boundary $interruptedBoundary',
                );
              }
            },
          ).promote();
          expect(
            interrupted.status,
            JournaledFilePromotionStatus.recoveryRequired,
          );
          expect(await File(sandbox.journalPath).exists(), isTrue);
          await sandbox.expectBeforeHashes();

          final resumed = await sandbox.repository().promote();
          expect(resumed.status, JournaledFilePromotionStatus.promoted);
          await sandbox.expectAfterHashes();
        } finally {
          await sandbox.dispose();
        }
      }
    });

    test('restores the autonomous pre-promotion checkpoint exactly', () async {
      final sandbox = await _PromotionSandbox.create();
      addTearDown(sandbox.dispose);
      final interrupted = await sandbox.repository(
        faultInjector: (renamedFileCount) async {
          if (renamedFileCount == 2) throw StateError('restore probe');
        },
      ).promote();
      expect(
        interrupted.status,
        JournaledFilePromotionStatus.recoveryRequired,
      );

      final restored = await sandbox.repository().restoreCheckpoint();
      expect(restored.status, JournaledFilePromotionStatus.restored);
      await sandbox.expectBeforeHashes();
      expect(await File(sandbox.journalPath).exists(), isFalse);
    });

    test('preserves journal and bytes when ownership diverges', () async {
      final sandbox = await _PromotionSandbox.create();
      addTearDown(sandbox.dispose);
      final interrupted = await sandbox.repository(
        faultInjector: (renamedFileCount) async {
          if (renamedFileCount == 1) throw StateError('divergence probe');
        },
      ).promote();
      expect(
        interrupted.status,
        JournaledFilePromotionStatus.recoveryRequired,
      );
      final projectFile = File(
        p.join(sandbox.repositoryRoot.path, 'selbrume', 'project.json'),
      );
      await projectFile.writeAsString(
        '${await projectFile.readAsString()}\nexternal-change',
        flush: true,
      );
      final divergentBytes = await projectFile.readAsBytes();

      final refused = await sandbox.repository().promote();
      expect(refused.status, JournaledFilePromotionStatus.blocked);
      expect(refused.code, 'promotionOwnershipDiverged');
      expect(await projectFile.readAsBytes(), divergentBytes);
      expect(await File(sandbox.journalPath).exists(), isTrue);

      final restoreRefused = await sandbox.repository().restoreCheckpoint();
      expect(restoreRefused.status, JournaledFilePromotionStatus.blocked);
      expect(restoreRefused.code, 'promotionOwnershipDiverged');
      expect(await projectFile.readAsBytes(), divergentBytes);
    });

    test('refuses a fifth destination and destination symlinks', () async {
      final sandbox = await _PromotionSandbox.create();
      addTearDown(sandbox.dispose);
      final manifestRoot = _jsonObject(
        jsonDecode(await File(sandbox.manifestPath).readAsString()),
      );
      final ordered = List<Map<String, Object?>>.of(
        _jsonObjects(manifestRoot['orderedFiles']),
      );
      ordered.add(<String, Object?>{
        ...ordered.last,
        'order': 5,
        'destination': 'selbrume/maps/unreviewed.json',
      });
      manifestRoot['orderedFiles'] = ordered;
      final expandedManifest = File(
        p.join(sandbox.root.path, 'expanded-promotion-manifest.json'),
      );
      await expandedManifest.writeAsString(jsonEncode(manifestRoot));
      final expanded = JournaledFilePromotionRepository(
        repositoryRoot: sandbox.repositoryRoot.path,
        manifestPath: expandedManifest.path,
        allowedDestinations: _allowedDestinations,
        journalPath: sandbox.journalPath,
      );
      final scopeRefused = await expanded.promote();
      expect(scopeRefused.status, JournaledFilePromotionStatus.blocked);
      expect(scopeRefused.code, 'promotionScopeMismatch');

      final portPath = p.join(
        sandbox.repositoryRoot.path,
        'selbrume',
        'maps',
        'map_port_brisants.json',
      );
      await File(portPath).delete();
      await Link(portPath).create(
        p.join(
          sandbox.fixtureRoot.path,
          'promotion_checkpoint',
          'maps',
          'map_port_brisants.json',
        ),
      );
      final symlinkRefused = await sandbox.repository().promote();
      expect(symlinkRefused.status, JournaledFilePromotionStatus.blocked);
      expect(symlinkRefused.code, 'promotionSymlinkRefused');
    });

    test('holds the shared project lock across classification and rename',
        () async {
      final sandbox = await _PromotionSandbox.create();
      addTearDown(sandbox.dispose);
      final beforeReplaceReached = Completer<void>();
      final allowReplace = Completer<void>();
      var hookCalls = 0;
      final promotion = sandbox.repository(
        beforeReplaceHook: (_, __, ___) async {
          hookCalls++;
          if (hookCalls == 1) {
            beforeReplaceReached.complete();
            await allowReplace.future;
          }
        },
      ).promote();
      await beforeReplaceReached.future;

      var competingWriterEntered = false;
      final competingWrite = withProjectManifestWriteLock(
        p.join(sandbox.repositoryRoot.path, 'selbrume', 'project.json'),
        () async => competingWriterEntered = true,
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(competingWriterEntered, isFalse);

      allowReplace.complete();
      expect((await promotion).status, JournaledFilePromotionStatus.promoted);
      await competingWrite;
      expect(competingWriterEntered, isTrue);
    });

    test('refuses source or destination mutation immediately before rename',
        () async {
      for (final mutateSource in <bool>[true, false]) {
        final sandbox = await _PromotionSandbox.create();
        File? mutatedSourceFile;
        List<int>? originalSourceBytes;
        try {
          List<int>? divergentDestinationBytes;
          var mutated = false;
          final result = await sandbox.repository(
            beforeReplaceHook: (_, sourcePath, destinationPath) async {
              if (mutated) return;
              mutated = true;
              if (mutateSource) {
                final source = File(sourcePath);
                mutatedSourceFile = source;
                originalSourceBytes = await source.readAsBytes();
                await source.writeAsString(
                  '${await source.readAsString()}\nsource-race',
                  flush: true,
                );
              } else {
                final destination = File(destinationPath);
                divergentDestinationBytes = utf8.encode('destination-race');
                await destination.writeAsBytes(
                  divergentDestinationBytes!,
                  flush: true,
                );
              }
            },
          ).promote();

          expect(result.status, JournaledFilePromotionStatus.blocked);
          expect(
            result.code,
            mutateSource
                ? 'promotionSourceChangedBeforeWrite'
                : 'promotionDestinationChangedBeforeWrite',
          );
          expect(await File(sandbox.journalPath).exists(), isTrue);
          if (!mutateSource) {
            final projectFile = File(
              p.join(
                sandbox.repositoryRoot.path,
                'selbrume',
                'project.json',
              ),
            );
            expect(await projectFile.readAsBytes(), divergentDestinationBytes);
          }
        } finally {
          if (mutatedSourceFile != null && originalSourceBytes != null) {
            await mutatedSourceFile!.writeAsBytes(
              originalSourceBytes!,
              flush: true,
            );
          }
          await sandbox.dispose();
        }
      }
    });
  });
}

final class _PromotionSandbox {
  _PromotionSandbox._({
    required this.root,
    required this.repositoryRoot,
    required this.fixtureRoot,
    required this.manifestPath,
    required this.journalPath,
    required this.entries,
  });

  final Directory root;
  final Directory repositoryRoot;
  final Directory fixtureRoot;
  final String manifestPath;
  final String journalPath;
  final List<Map<String, Object?>> entries;

  static Future<_PromotionSandbox> create() async {
    final repoRoot = findPokemonProjectRoot();
    final fixtureRoot = Directory(
      p.join(
        repoRoot.path,
        'examples',
        'playable_runtime_host',
        'event_builder_v2_selbrume_slice',
      ),
    );
    final manifestPath = p.join(
      fixtureRoot.path,
      'promotion_manifest.json',
    );
    final manifest = _jsonObject(
      jsonDecode(await File(manifestPath).readAsString()),
    );
    final entries = _jsonObjects(manifest['orderedFiles']);
    expect(entries.map((entry) => entry['destination']).toSet(),
        _allowedDestinations);

    final root = await Directory.systemTemp.createTemp(
      'pokemap_phase_j_promotion_',
    );
    final repositoryRoot = Directory(p.join(root.path, 'repository'));
    await repositoryRoot.create(recursive: true);
    for (final entry in entries) {
      final destination = File(
        p.join(repositoryRoot.path, entry['destination']! as String),
      );
      if (entry['beforeExists'] == true) {
        final relative =
            (entry['destination']! as String).replaceFirst('selbrume/', '');
        final checkpoint = File(
          p.join(fixtureRoot.path, 'promotion_checkpoint', relative),
        );
        await destination.parent.create(recursive: true);
        await checkpoint.copy(destination.path);
        expect(
          narrativeEventBytesFingerprint(await destination.readAsBytes()),
          entry['beforeSha256'],
        );
      }
    }
    final journalPath = p.join(
      repositoryRoot.path,
      'selbrume',
      '.pokemap-event-v2-phase-j-promotion.json',
    );
    return _PromotionSandbox._(
      root: root,
      repositoryRoot: repositoryRoot,
      fixtureRoot: fixtureRoot,
      manifestPath: manifestPath,
      journalPath: journalPath,
      entries: entries,
    );
  }

  JournaledFilePromotionRepository repository({
    JournaledPromotionFaultInjector? faultInjector,
    JournaledPromotionBeforeReplaceHook? beforeReplaceHook,
    JournaledPromotionCheckpointFaultInjector? checkpointFaultInjector,
  }) {
    return JournaledFilePromotionRepository(
      repositoryRoot: repositoryRoot.path,
      manifestPath: manifestPath,
      allowedDestinations: _allowedDestinations,
      journalPath: journalPath,
      faultInjector: faultInjector,
      beforeReplaceHook: beforeReplaceHook,
      checkpointFaultInjector: checkpointFaultInjector,
    );
  }

  Future<void> expectBeforeHashes() async {
    for (final entry in entries) {
      final destination = File(
        p.join(repositoryRoot.path, entry['destination']! as String),
      );
      if (entry['beforeExists'] == true) {
        expect(await destination.exists(), isTrue);
        expect(
          narrativeEventBytesFingerprint(await destination.readAsBytes()),
          entry['beforeSha256'],
        );
      } else {
        expect(await destination.exists(), isFalse);
      }
    }
  }

  Future<void> expectAfterHashes() async {
    for (final entry in entries) {
      final destination = File(
        p.join(repositoryRoot.path, entry['destination']! as String),
      );
      expect(await destination.exists(), isTrue);
      expect(
        narrativeEventBytesFingerprint(await destination.readAsBytes()),
        entry['afterSha256'],
      );
    }
  }

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

Map<String, Object?> _jsonObject(Object? value) =>
    (value! as Map).cast<String, Object?>();

List<Map<String, Object?>> _jsonObjects(Object? value) => (value! as List)
    .map((entry) => (entry! as Map).cast<String, Object?>())
    .toList(growable: false);
