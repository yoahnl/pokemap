import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/support/authoring_performance_observer.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_metadata_documents.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory qaDirectory;
  var createdQaDirectory = false;

  setUpAll(() async {
    final supplied = Platform.environment['AVELUNE_QA_ROOT'];
    final home = Platform.environment['HOME'];
    if (supplied != null && supplied.isNotEmpty) {
      if (!p.isAbsolute(supplied)) {
        throw ArgumentError('AVELUNE_QA_ROOT must be an absolute directory.');
      }
      qaDirectory = Directory(supplied);
      if (!await qaDirectory.exists()) {
        throw ArgumentError('AVELUNE_QA_ROOT must already exist.');
      }
    } else if (Platform.isMacOS) {
      if (home == null || home.isEmpty) {
        throw StateError(
            'HOME is required to locate the Avelune QA directory.');
      }
      qaDirectory = Directory(p.join(
        home,
        'Library',
        'Caches',
        'AveluneQA',
        'pokemon-media-scoped-tests',
      ));
      if (!await qaDirectory.exists()) {
        await qaDirectory.create(recursive: true);
        createdQaDirectory = true;
      }
    } else {
      qaDirectory = Directory.systemTemp;
    }
    if (Platform.isMacOS) {
      if (home == null || home.isEmpty) {
        throw StateError(
            'HOME is required to locate the Avelune QA directory.');
      }
      final root =
          await Directory(p.join(home, 'Library', 'Caches', 'AveluneQA'))
              .resolveSymbolicLinks();
      final selected = await qaDirectory.resolveSymbolicLinks();
      if (!p.isWithin(root, selected)) {
        throw ArgumentError('AVELUNE_QA_ROOT must be inside AveluneQA.');
      }
    }
  });

  tearDownAll(() async {
    if (createdQaDirectory) {
      try {
        await qaDirectory.delete();
      } on FileSystemException {
        return;
      }
    }
  });

  for (final projectChange in ['none', 'moved', 'missing', 'redo']) {
    test(
        projectChange == 'none'
            ? 'writes native Pokemon media locally and rejects a stale preimage'
            : 'rejects native media history after project change: $projectChange',
        () async {
      final root = await qaDirectory.createTemp('pokemon-media-scoped-');
      addTearDown(() => root.delete(recursive: true));
      await File('${root.path}/project.json').writeAsString(jsonEncode(
        const ProjectManifest(name: 'Media fixture', maps: [], tilesets: [])
            .toJson(),
      ));
      const path = 'data/pokemon/media/oshawott.json';
      final file = File('${root.path}/$path');
      await file.parent.create(recursive: true);
      final original = {
        'schemaVersion': 2,
        'speciesId': 'oshawott',
        'defaultFormId': 'base',
        'variants': {
          'base': {
            'frontAnimated': 'assets/front.gif',
            'unknownVariantField': {'value': 7},
            'animations': {
              'idle': {
                'sheet': 'assets/sheet.png',
                'animationId': 'idle',
                'unknownAnimationField': true,
              },
            },
          },
        },
        'vendorExtension': {'preserve': true},
      };
      final before = utf8.encode(jsonEncode(original));
      await file.writeAsBytes(before);
      final unrelated =
          File('${root.path}/data/pokemon/species/unrelated.json');
      await unrelated.parent.create(recursive: true);
      await unrelated.writeAsString('{invalid unrelated document');

      final reader = _CountingReader();
      final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path],
        fileReader: reader,
      );
      final handles = WorkspaceHandleStore();
      final snapshots = ProjectSnapshotLoader(handles: handles);
      final opener = ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
        workshopScope: true,
        initializeSceneOwners: false,
      );
      var opened = await opener.openProject(root.path);
      final mutations = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: snapshots,
        catalogFileReader: reader,
      );
      await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      addTearDown(() async {
        await mutations.detachWorkspace(opened.workspaceHandle);
        opener.closeWorkspace(opened.workspaceHandle);
      });

      final snapshot = await mutations.readWorkshopSnapshot(
        opened.projectHandle,
        actionId: 'pokemon.media.write',
        parameters: {
          'relativePath': path,
          'document': {'speciesId': 'oshawott'},
        },
      );
      expect(snapshot.resourceBytes(pokemonMediaResourceIdentity('oshawott')),
          before);
      expect(snapshot.resourceStorageKeys.values, contains(path));
      expect(snapshot.resourceStorageKeys.values,
          isNot(contains('data/pokemon/species/unrelated.json')));
      expect(await file.readAsBytes(), before);

      final edited = {
        ...original,
        'variants': {
          'base': {
            ...(original['variants'] as Map)['base'] as Map,
            'frontStatic': 'assets/front.png',
          },
        },
      };
      final parameters = {
        'relativePath': path,
        'document': edited,
        'beforeBytesBase64': base64Encode(before),
      };
      await expectLater(
        mutations.planMutation(
          opened.projectHandle,
          AuthoringRequest(
            requestId: 'media-unprepared',
            actionId: 'pokemon.media.write',
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: 'media-unprepared',
            parameters: parameters,
            extensions: {'workshopScope': true},
          ),
        ),
        throwsA(isA<TransactionFileGatewayException>().having(
          (error) => error.code,
          'code',
          'transaction.pending_index_preparation_required',
        )),
      );
      expect(await file.readAsBytes(), before);
      await mutations.prepareWorkshopCatalog(opened.projectHandle);
      for (var i = 0; i < 50; i++) {
        final unrelatedJournal = File(
          '${root.path}/.pokemap/authoring/transactions/old-$i/journal.json',
        );
        await unrelatedJournal.parent.create(recursive: true);
        await unrelatedJournal.writeAsString('{unrelated retained journal');
      }
      reader.reads.clear();
      final planned = await mutations.planMutation(
        opened.projectHandle,
        AuthoringRequest(
          requestId: 'media-first',
          actionId: 'pokemon.media.write',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision: snapshot.revision,
          idempotencyKey: 'media-first',
          parameters: parameters,
          extensions: {'workshopScope': true},
        ),
      );
      final gateway =
          await LocalTransactionFileGateway.open(projectRoot: root.path);
      await gateway.writeJournal(_pendingJournal(path));
      await expectLater(
        mutations.applyMutation(
          opened.projectHandle,
          planId: planned.planId,
          operationId: 'media-first',
        ),
        throwsA(isA<AuthoringRecoveryException>().having(
          (error) => error.code,
          'code',
          'resource_pack.recovery_required',
        )),
      );
      expect(await file.readAsBytes(), before);
      await gateway.deleteTransaction('pending-media');
      final applied = await mutations.applyMutation(
        opened.projectHandle,
        planId: planned.planId,
        operationId: 'media-first',
      );
      final actual = jsonDecode(await file.readAsString()) as Map;
      expect(actual['vendorExtension'], original['vendorExtension']);
      final variant = (actual['variants'] as Map)['base'] as Map;
      expect(variant['frontAnimated'], 'assets/front.gif');
      expect(variant['frontStatic'], 'assets/front.png');
      expect(variant['unknownVariantField'], {'value': 7});
      expect((variant['animations'] as Map)['idle']['unknownAnimationField'],
          isTrue);
      expect(actual['defaultFormId'], 'base');
      expect(
          reader.reads, isNot(contains('data/pokemon/species/unrelated.json')));

      final afterBytes = await file.readAsBytes();
      await mutations.detachWorkspace(opened.workspaceHandle);
      opener.closeWorkspace(opened.workspaceHandle);
      opened = await opener.openProject(root.path);
      await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      reader.reads.clear();
      await gateway.writeJournal(_pendingJournal(path));
      await expectLater(
        mutations.undoMutation(
          opened.projectHandle,
          entryId: applied.receipt.receiptId,
          idempotencyKey: 'undo-pending-media',
        ),
        throwsA(isA<AuthoringRecoveryException>().having(
          (error) => error.code,
          'code',
          'resource_pack.recovery_required',
        )),
      );
      expect(await file.readAsBytes(), afterBytes);
      await gateway.deleteTransaction('pending-media');
      final index = File(
          '${root.path}/.pokemap/authoring/transactions/pending-journals.json');
      final heldIndex = await index.rename('${index.path}.held');
      await expectLater(
        mutations.undoMutation(
          opened.projectHandle,
          entryId: applied.receipt.receiptId,
          idempotencyKey: 'undo-unprepared-media',
        ),
        throwsA(isA<TransactionFileGatewayException>().having(
          (error) => error.code,
          'code',
          'transaction.pending_index_preparation_required',
        )),
      );
      expect(await file.readAsBytes(), afterBytes);
      await heldIndex.rename(index.path);
      final projectFile = File('${root.path}/project.json');
      final projectBytes = await projectFile.readAsBytes();
      final movedProject = Map<String, dynamic>.from(
          jsonDecode(utf8.decode(projectBytes)) as Map);
      movedProject['pokemon'] = {
        ...Map<String, dynamic>.from(movedProject['pokemon'] as Map),
        'mediaDir': 'data/pokemon/other-media',
      };
      if (projectChange == 'moved' || projectChange == 'missing') {
        if (projectChange == 'missing') {
          await projectFile.delete();
        } else {
          await projectFile.writeAsString(jsonEncode(movedProject));
        }
        await expectLater(
          mutations.undoMutation(
            opened.projectHandle,
            entryId: applied.receipt.receiptId,
            idempotencyKey: 'undo-media-project-$projectChange',
          ),
          throwsA(isA<AuthoringHistoryException>().having(
            (error) => error.code,
            'code',
            'history.pokemon_media_path_changed',
          )),
        );
        expect(await file.readAsBytes(), afterBytes);
        await projectFile.writeAsBytes(projectBytes);
      }
      await mutations.undoMutation(
        opened.projectHandle,
        entryId: applied.receipt.receiptId,
        idempotencyKey: 'undo-media-first',
      );
      expect(await file.readAsBytes(), before);
      final concurrentUndo = utf8.encode(
          jsonEncode({...original, 'vendorExtension': 'concurrent-undo'}));
      await file.writeAsBytes(concurrentUndo);
      await expectLater(
        mutations.redoMutation(
          opened.projectHandle,
          entryId: applied.receipt.receiptId,
          idempotencyKey: 'redo-stale-media',
        ),
        throwsA(isA<AuthoringHistoryException>().having(
          (error) => error.code,
          'code',
          'history.resource_changed',
        )),
      );
      expect(await file.readAsBytes(), concurrentUndo);
      await file.writeAsBytes(before);
      if (projectChange == 'redo') {
        await projectFile.writeAsString(jsonEncode(movedProject));
        await expectLater(
          mutations.redoMutation(
            opened.projectHandle,
            entryId: applied.receipt.receiptId,
            idempotencyKey: 'redo-media-project-moved',
          ),
          throwsA(isA<AuthoringHistoryException>().having(
            (error) => error.code,
            'code',
            'history.pokemon_media_path_changed',
          )),
        );
        expect(await file.readAsBytes(), before);
        await projectFile.writeAsBytes(projectBytes);
      }
      await mutations.redoMutation(
        opened.projectHandle,
        entryId: applied.receipt.receiptId,
        idempotencyKey: 'redo-media-first',
      );
      expect(await file.readAsBytes(), afterBytes);
      expect(reader.reads, isNot(contains('project.json')));

      final nextBefore = await file.readAsBytes();
      final nextParameters = {
        'relativePath': path,
        'document': original,
        'beforeBytesBase64': base64Encode(nextBefore),
      };
      final nextSnapshot = await mutations.readWorkshopSnapshot(
        opened.projectHandle,
        actionId: 'pokemon.media.write',
        parameters: nextParameters,
      );
      final stalePlan = await mutations.planMutation(
        opened.projectHandle,
        AuthoringRequest(
          requestId: 'media-stale',
          actionId: 'pokemon.media.write',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision: nextSnapshot.revision,
          idempotencyKey: 'media-stale',
          parameters: nextParameters,
          extensions: {'workshopScope': true},
        ),
      );
      final concurrent = utf8.encode(
          '${jsonEncode({...original, 'vendorExtension': 'concurrent'})}\n');
      await file.writeAsBytes(concurrent);
      await expectLater(
        mutations.applyMutation(
          opened.projectHandle,
          planId: stalePlan.planId,
          operationId: 'media-stale',
        ),
        throwsA(anyOf(
          isA<AuthoringPlanException>()
              .having((error) => error.code, 'code', 'plan.stale'),
          isA<AuthoringRevisionConflict>(),
        )),
      );
      expect(await file.readAsBytes(), concurrent);
    });
  }

  for (final interruption in [
    'none',
    'reservation',
    'catalog/HEAD.json',
    'catalog/IDENTITY.json',
    'project.json',
    'changed-before-recovery',
  ]) {
    test('explicit partition preserves native Pokemon media: $interruption',
        () async {
      final root = await qaDirectory.createTemp('pokemon-media-partition-');
      addTearDown(() => root.delete(recursive: true));
      const mediaDirectory = 'data/custom/pokemon-media';
      final project = ProjectManifest(
        name: 'Pokemon media partition',
        maps: const [],
        tilesets: const [],
        pokemon: const ProjectPokemonConfig(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
          mediaDir: mediaDirectory,
        ),
      );
      final originalProject = utf8.encode(jsonEncode(project.toJson()));
      final projectFile = File('${root.path}/project.json');
      await projectFile.writeAsBytes(originalProject);
      final mediaFile = File('${root.path}/$mediaDirectory/oshawott.json');
      await mediaFile.parent.create(recursive: true);
      final originalMedia = utf8.encode(jsonEncode({
        'schemaVersion': 2,
        'speciesId': 'oshawott',
        'defaultFormId': 'base',
        'variants': {
          'base': {
            'frontAnimated': 'assets/oshawott-front.gif',
            'unknownVariantField': {'preserve': true},
          },
        },
        'vendorExtension': {'preserve': true},
      }));
      await mediaFile.writeAsBytes(originalMedia);
      final saveFile = File('${root.path}/saves/existing.json');
      await saveFile.parent.create(recursive: true);
      final originalSave = await File('../map_core/test/fixtures/compatibility/'
              'avelune_studio_0_3_31_331/active-2d-save.json')
          .readAsBytes();
      const saveCodec = SaveEnvelopeCodec();
      expect(
          saveCodec.verifyChecksum(saveCodec.decodeUtf8(originalSave)), isTrue);
      await saveFile.writeAsBytes(originalSave);
      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path],
        fileReader: reader,
      );
      final handles = WorkspaceHandleStore();
      final loader = ProjectSnapshotLoader(handles: handles);
      final api = AuthoringReadApi(
        openService: ProjectOpenService(
          policy: policy,
          fileReader: reader,
          handles: handles,
          initializeSceneOwners: false,
        ),
        snapshotLoader: loader,
      );
      var crashed = false;
      final mutations = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: loader,
        faultInjector: (context) {
          final expectedPath = interruption == 'changed-before-recovery'
              ? 'catalog/HEAD.json'
              : interruption;
          final reached = interruption == 'reservation'
              ? context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterReservation
              : context.checkpoint ==
                      AuthoringTransactionCheckpoint.afterResourcePromoted &&
                  context.storageKey == expectedPath;
          if (!crashed && interruption != 'none' && reached) {
            crashed = true;
            throw const AuthoringTransactionSimulatedCrash();
          }
        },
      );
      var opened = await api.openProject(root.path);
      await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      addTearDown(() async {
        await mutations.detachWorkspace(opened.workspaceHandle);
        await api.closeWorkspace(opened.workspaceHandle);
      });
      final snapshot = await loader.load(opened.projectHandle);
      final plan = await mutations.planMutation(
        opened.projectHandle,
        AuthoringRequest(
          requestId: 'pokemon-media-partition',
          actionId: 'project.catalog.partition',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision: snapshot.revision,
          idempotencyKey: 'pokemon-media-partition',
        ),
      );
      expect(await projectFile.readAsBytes(), originalProject);
      if (interruption == 'none') {
        await mutations.applyMutation(
          opened.projectHandle,
          planId: plan.planId,
          operationId: 'pokemon-media-partition',
        );
      } else {
        await expectLater(
          mutations.applyMutation(
            opened.projectHandle,
            planId: plan.planId,
            operationId: 'pokemon-media-partition',
          ),
          throwsA(isA<AuthoringTransactionSimulatedCrash>()),
        );
        expect(crashed, isTrue);
        await mutations.detachWorkspace(opened.workspaceHandle);
        await api.closeWorkspace(opened.workspaceHandle);
        opened = await api.openProject(root.path);
        expect(opened.recoveryRequired, isTrue);
        await mutations.attachProject(
          projectRootPath: root.path,
          workspaceHandle: opened.workspaceHandle,
          projectHandle: opened.projectHandle,
        );
        if (interruption == 'changed-before-recovery') {
          final changedProject = Map<String, dynamic>.from(
              jsonDecode(utf8.decode(originalProject)) as Map);
          changedProject['pokemon'] = {
            ...Map<String, dynamic>.from(changedProject['pokemon'] as Map),
            'mediaDir': 'data/custom/moved-media',
          };
          final changedBytes = utf8.encode(jsonEncode(changedProject));
          await projectFile.writeAsBytes(changedBytes);
          await expectLater(
            mutations.recoverMutation(
              opened.projectHandle,
              operationId: 'pokemon-media-partition',
            ),
            throwsA(isA<AuthoringRecoveryException>().having(
              (error) => error.code,
              'code',
              'recovery.revision_conflict',
            )),
          );
          expect(await projectFile.readAsBytes(), changedBytes);
          expect(await mediaFile.readAsBytes(), originalMedia);
          expect(await saveFile.readAsBytes(), originalSave);
          await projectFile.writeAsBytes(originalProject);
        }
        await mutations.recoverMutation(
          opened.projectHandle,
          operationId: 'pokemon-media-partition',
        );
      }
      await mutations.detachWorkspace(opened.workspaceHandle);
      await api.closeWorkspace(opened.workspaceHandle);
      opened = await api.openProject(root.path);
      await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      final restored = await loader.load(opened.projectHandle);
      expect(restored.manifest.pokemon.toJson(), project.pokemon.toJson());
      expect(await mediaFile.readAsBytes(), originalMedia);
      expect(await saveFile.readAsBytes(), originalSave);
      expect(
          saveCodec.verifyChecksum(
              saveCodec.decodeUtf8(await saveFile.readAsBytes())),
          isTrue);
      final history =
          await mutations.listMutationHistory(opened.projectHandle, limit: 20);
      final change = history.page.entries.single.changes
          .singleWhere((change) => change.storageKey == 'project.json');
      final blobs =
          await FileAuthoringContentBlobStore.open(projectRoot: root.path);
      final original = await blobs.get(change.beforeBlobId!);
      expect(original, isNotNull);
      try {
        expect(await original!.readBytes(), originalProject);
      } finally {
        await original?.release();
      }
    });
  }

  for (final operation in ['write', 'undo', 'redo']) {
    for (final boundary in ['before-promotion', 'after-promotion']) {
      for (final projectChange in ['unchanged', 'moved', 'missing']) {
        test(
            'recovers native media $operation $boundary with project $projectChange',
            () async {
          final root = await qaDirectory.createTemp('pokemon-media-recovery-');
          addTearDown(() => root.delete(recursive: true));
          final projectFile = File('${root.path}/project.json');
          await projectFile.writeAsString(jsonEncode(
            const ProjectManifest(name: 'Media fixture', maps: [], tilesets: [])
                .toJson(),
          ));
          const path = 'data/pokemon/media/oshawott.json';
          final file = File('${root.path}/$path');
          await file.parent.create(recursive: true);
          final original = {
            'schemaVersion': 2,
            'speciesId': 'oshawott',
            'defaultFormId': 'base',
            'variants': {
              'base': {'frontAnimated': 'assets/front.gif'}
            },
          };
          final before = utf8.encode(jsonEncode(original));
          await file.writeAsBytes(before);
          final edited = {
            ...original,
            'variants': {
              'base': {
                'frontAnimated': 'assets/front.gif',
                'frontStatic': 'assets/front.png',
              }
            },
          };
          final parameters = {
            'relativePath': path,
            'document': edited,
            'beforeBytesBase64': base64Encode(before),
          };
          final reader = _CountingReader();
          final policy = await WorkspacePolicy.create(
            allowedRootPaths: [root.path],
            fileReader: reader,
          );
          final handles = WorkspaceHandleStore();
          final opener = ProjectOpenService(
            policy: policy,
            fileReader: reader,
            handles: handles,
            workshopScope: true,
            initializeSceneOwners: false,
          );
          final opened = await opener.openProject(root.path);
          var injectCrash = false;
          String? interruptedOperationId;
          final mutations = LocalMapAuthoringMutationApi(
            policy: policy,
            snapshotLoader: ProjectSnapshotLoader(handles: handles),
            faultInjector: (context) {
              final reached = boundary == 'before-promotion'
                  ? context.checkpoint ==
                      AuthoringTransactionCheckpoint.afterReservation
                  : context.checkpoint ==
                          AuthoringTransactionCheckpoint
                              .afterResourcePromoted &&
                      context.storageKey == path;
              if (injectCrash && reached) {
                injectCrash = false;
                interruptedOperationId = context.operationId;
                throw const AuthoringTransactionSimulatedCrash();
              }
            },
          );
          await mutations.attachProject(
            projectRootPath: root.path,
            workspaceHandle: opened.workspaceHandle,
            projectHandle: opened.projectHandle,
          );
          addTearDown(() async {
            await mutations.detachWorkspace(opened.workspaceHandle);
            opener.closeWorkspace(opened.workspaceHandle);
          });
          await mutations.prepareWorkshopCatalog(opened.projectHandle);
          final snapshot = await mutations.readWorkshopSnapshot(
            opened.projectHandle,
            actionId: 'pokemon.media.write',
            parameters: parameters,
          );
          final plan = await mutations.planMutation(
            opened.projectHandle,
            AuthoringRequest(
              requestId: 'native-recovery-write',
              actionId: 'pokemon.media.write',
              actionVersion: 1,
              workspaceHandle: opened.workspaceHandle.value,
              expectedRevision: snapshot.revision,
              idempotencyKey: 'native-recovery-write',
              parameters: parameters,
              extensions: {'workshopScope': true},
            ),
          );
          AuthoringMutationResult? applied;
          if (operation != 'write') {
            applied = await mutations.applyMutation(
              opened.projectHandle,
              planId: plan.planId,
              operationId: 'native-recovery-write',
            );
          }
          final after = operation == 'write' ? null : await file.readAsBytes();
          if (operation == 'redo') {
            await mutations.undoMutation(
              opened.projectHandle,
              entryId: applied!.receipt.receiptId,
              idempotencyKey: 'native-recovery-prior-undo',
            );
            expect(await file.readAsBytes(), before);
          }
          injectCrash = true;
          await expectLater(
            operation == 'write'
                ? mutations.applyMutation(
                    opened.projectHandle,
                    planId: plan.planId,
                    operationId: 'native-recovery-write',
                  )
                : operation == 'undo'
                    ? mutations.undoMutation(
                        opened.projectHandle,
                        entryId: applied!.receipt.receiptId,
                        idempotencyKey: 'native-recovery-undo',
                      )
                    : mutations.redoMutation(
                        opened.projectHandle,
                        entryId: applied!.receipt.receiptId,
                        idempotencyKey: 'native-recovery-redo',
                      ),
            throwsA(isA<AuthoringTransactionSimulatedCrash>()),
          );
          expect(interruptedOperationId, isNotNull);
          final interrupted = await file.readAsBytes();
          if (boundary == 'before-promotion') {
            expect(interrupted, operation == 'undo' ? after : before);
          } else if (operation == 'undo') {
            expect(interrupted, before);
          } else if (operation == 'redo') {
            expect(interrupted, after);
          } else {
            expect(
                (jsonDecode(utf8.decode(interrupted)) as Map)['variants']
                    ['base']['frontStatic'],
                'assets/front.png');
          }
          final projectBytes = await projectFile.readAsBytes();
          if (projectChange == 'moved') {
            final project = Map<String, dynamic>.from(
                jsonDecode(utf8.decode(projectBytes)) as Map);
            project['pokemon'] = {
              ...Map<String, dynamic>.from(project['pokemon'] as Map),
              'mediaDir': 'data/pokemon/other-media',
            };
            await projectFile.writeAsString(jsonEncode(project));
          } else if (projectChange == 'missing') {
            await projectFile.delete();
          }
          final gateway =
              await LocalTransactionFileGateway.open(projectRoot: root.path);
          expect(await gateway.readJournal(interruptedOperationId!), isNotNull);
          if (projectChange == 'unchanged') {
            await mutations.recoverMutation(
              opened.projectHandle,
              operationId: interruptedOperationId!,
            );
            if (operation == 'undo') {
              expect(await file.readAsBytes(), before);
            } else {
              expect(
                  (jsonDecode(await file.readAsString()) as Map)['variants']
                      ['base']['frontStatic'],
                  'assets/front.png');
            }
          } else {
            await expectLater(
              mutations.recoverMutation(
                opened.projectHandle,
                operationId: interruptedOperationId!,
              ),
              throwsA(anyOf(
                isA<AuthoringRecoveryException>().having(
                  (error) => error.code,
                  'code',
                  anyOf('recovery.dependency_changed',
                      'recovery.dependency_unavailable'),
                ),
                isA<AuthoringHistoryException>().having(
                  (error) => error.code,
                  'code',
                  'history.pokemon_media_path_changed',
                ),
              )),
            );
            expect(await file.readAsBytes(), interrupted);
            expect(
                await gateway.readJournal(interruptedOperationId!), isNotNull);
            await projectFile.writeAsBytes(projectBytes);
            await mutations.recoverMutation(
              opened.projectHandle,
              operationId: interruptedOperationId!,
            );
            if (operation == 'undo') {
              expect(await file.readAsBytes(), before);
            } else {
              expect(
                  (jsonDecode(await file.readAsString()) as Map)['variants']
                      ['base']['frontStatic'],
                  'assets/front.png');
            }
          }
        });
      }
    }
  }

  test('rechecks pending transactions under the lock before a media write',
      () async {
    final root = await qaDirectory.createTemp('pokemon-media-race-');
    addTearDown(() => root.delete(recursive: true));
    await File('${root.path}/project.json').writeAsString(jsonEncode(
      const ProjectManifest(name: 'Media fixture', maps: [], tilesets: [])
          .toJson(),
    ));
    const path = 'data/pokemon/media/oshawott.json';
    final file = File('${root.path}/$path');
    await file.parent.create(recursive: true);
    final before = utf8.encode(jsonEncode({
      'schemaVersion': 2,
      'speciesId': 'oshawott',
      'defaultFormId': 'base',
      'variants': {
        'base': {'frontAnimated': 'assets/front.gif'}
      },
    }));
    await file.writeAsBytes(before);
    final reader = _CountingReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final opener = ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
      workshopScope: true,
      initializeSceneOwners: false,
    );
    final opened = await opener.openProject(root.path);
    final observer = _BoundaryObserver();
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: ProjectSnapshotLoader(handles: handles),
      catalogFileReader: reader,
      performanceObserver: observer,
    );
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    addTearDown(() async {
      await mutations.detachWorkspace(opened.workspaceHandle);
      opener.closeWorkspace(opened.workspaceHandle);
    });
    await mutations.prepareWorkshopCatalog(opened.projectHandle);
    final parameters = {
      'relativePath': path,
      'document': {
        'schemaVersion': 2,
        'speciesId': 'oshawott',
        'defaultFormId': 'base',
        'variants': {
          'base': {
            'frontAnimated': 'assets/front.gif',
            'frontStatic': 'assets/front.png',
          }
        },
      },
      'beforeBytesBase64': base64Encode(before),
    };
    final snapshot = await mutations.readWorkshopSnapshot(
      opened.projectHandle,
      actionId: 'pokemon.media.write',
      parameters: parameters,
    );
    final plan = await mutations.planMutation(
      opened.projectHandle,
      AuthoringRequest(
        requestId: 'media-race',
        actionId: 'pokemon.media.write',
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle.value,
        expectedRevision: snapshot.revision,
        idempotencyKey: 'media-race',
        parameters: parameters,
        extensions: {'workshopScope': true},
      ),
    );
    var injected = false;
    observer.onApply = () {
      injected = true;
      final transactions = '${root.path}/.pokemap/authoring/transactions';
      final journal = File('$transactions/pending-media/journal.json');
      journal.parent.createSync(recursive: true);
      journal.writeAsStringSync(jsonEncode(_pendingJournal(path).toJson()));
      final index = File('$transactions/pending-journals.json');
      final data = Map<String, dynamic>.from(
          jsonDecode(index.readAsStringSync()) as Map);
      data['operationIds'] = [...data['operationIds'] as List, 'pending-media'];
      index.writeAsStringSync(jsonEncode(data));
    };
    await expectLater(
      mutations.applyMutation(
        opened.projectHandle,
        planId: plan.planId,
        operationId: 'media-race',
      ),
      throwsA(isA<AuthoringRecoveryException>().having(
        (error) => error.code,
        'code',
        'resource_pack.recovery_required',
      )),
    );
    expect(injected, isTrue);
    expect(await file.readAsBytes(), before);
    final gateway =
        await LocalTransactionFileGateway.open(projectRoot: root.path);
    expect(await gateway.readJournal('media-race'), isNull);
    await gateway.deleteTransaction('pending-media');
    await mutations.applyMutation(
      opened.projectHandle,
      planId: plan.planId,
      operationId: 'media-race',
    );
    expect(await file.readAsBytes(), isNot(before));
  });

  test('catalog media operations ignore unrelated trainer definitions',
      () async {
    final samples = <int,
        List<
            ({
              int readerReads,
              int readerBytes,
              Map<String, int> counters,
              int trainerReads
            })>>{};
    for (final trainerCount in [0, 100]) {
      final root = await qaDirectory.createTemp('pokemon-media-trainers-');
      addTearDown(() => root.delete(recursive: true));
      final reader = _CountingReader();
      final observer = _BoundaryObserver();
      final store = CatalogStorageStore(
        projectRoot: root.path,
        reader: reader,
        gateway: await LocalTransactionFileGateway.open(
          projectRoot: root.path,
          performanceObserver: observer,
        ),
      );
      await WorkingProjectCatalog.create(
        store: store,
        projectId: 'media-trainer-cost',
        project: ProjectManifest(
          name: 'Media trainer cost',
          maps: const [],
          tilesets: const [],
          trainers: [
            for (var i = 0; i < trainerCount; i++)
              ProjectTrainerEntry(
                id: 'trainer-$i',
                name: 'Trainer $i',
                trainerClass: 'Trainer',
              ),
          ],
        ),
      );
      final catalog =
          (await store.openRoot((await store.readHead())!)).snapshot;
      final trainerPaths = <String>{};
      for (var i = 0; i < trainerCount; i++) {
        final entry = await catalog
            .indexEntry(CatalogMetadataDocuments.definitionKey('trainers', i));
        expect(entry, isNotNull);
        trainerPaths.add('catalog/objects/${entry!.reference.sha256}.json');
      }
      const path = 'data/pokemon/media/oshawott.json';
      final file = File('${root.path}/$path');
      await file.parent.create(recursive: true);
      final initial = {
        'schemaVersion': 2,
        'speciesId': 'oshawott',
        'defaultFormId': 'base',
        'variants': {
          'base': {'frontAnimated': 'assets/front.gif'}
        },
      };
      await file.writeAsString(jsonEncode(initial));
      final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path],
        fileReader: reader,
      );
      final handles = WorkspaceHandleStore();
      final opener = ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
        catalogMetadataFields: {},
        workshopScope: true,
        initializeSceneOwners: false,
      );
      final opened = await opener.openProject(root.path);
      final mutations = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: ProjectSnapshotLoader(handles: handles),
        catalogFileReader: reader,
        performanceObserver: observer,
      );
      await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      addTearDown(() async {
        await mutations.detachWorkspace(opened.workspaceHandle);
        opener.closeWorkspace(opened.workspaceHandle);
      });
      await mutations.prepareWorkshopCatalog(opened.projectHandle);
      final observations = <({
        int readerReads,
        int readerBytes,
        Map<String, int> counters,
        int trainerReads
      })>[];
      AuthoringReceipt? lastReceipt;
      for (var index = 0; index < 2; index++) {
        final before = await file.readAsBytes();
        final parameters = {
          'relativePath': path,
          'document': {
            ...initial,
            'variants': {
              'base': {
                'frontAnimated': 'assets/front.gif',
                'frontStatic': 'assets/front-$index.png'
              }
            },
          },
          'beforeBytesBase64': base64Encode(before),
        };
        reader.reset();
        observer.counters.clear();
        final snapshot = await mutations.readWorkshopSnapshot(
          opened.projectHandle,
          actionId: 'pokemon.media.write',
          parameters: parameters,
        );
        final plan = await mutations.planMutation(
          opened.projectHandle,
          AuthoringRequest(
            requestId: 'media-cost-$index',
            actionId: 'pokemon.media.write',
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: 'media-cost-$index',
            parameters: parameters,
            extensions: {'workshopScope': true},
          ),
        );
        final applied = await mutations.applyMutation(opened.projectHandle,
            planId: plan.planId, operationId: 'media-cost-$index');
        lastReceipt = applied.receipt;
        observations.add((
          readerReads: reader.reads.length,
          readerBytes: reader.bytesRead,
          counters: Map.of(observer.counters),
          trainerReads: reader.reads.where(trainerPaths.contains).length,
        ));
      }
      for (final redo in [false, true]) {
        reader.reset();
        observer.counters.clear();
        if (redo) {
          await mutations.redoMutation(opened.projectHandle,
              entryId: lastReceipt!.receiptId,
              idempotencyKey: 'media-cost-redo');
        } else {
          await mutations.undoMutation(opened.projectHandle,
              entryId: lastReceipt!.receiptId,
              idempotencyKey: 'media-cost-undo');
        }
        observations.add((
          readerReads: reader.reads.length,
          readerBytes: reader.bytesRead,
          counters: Map.of(observer.counters),
          trainerReads: reader.reads.where(trainerPaths.contains).length,
        ));
      }
      samples[trainerCount] = observations;
    }
    expect(
      samples[100]!.map((sample) => sample.trainerReads).toList(),
      [0, 0, 0, 0],
      reason:
          'baseline: ${samples[0]}; with unrelated trainers: ${samples[100]}',
    );
    for (var i = 0; i < 4; i++) {
      final baseline = samples[0]![i];
      final withTrainers = samples[100]![i];
      expect(withTrainers.readerReads, baseline.readerReads);
      for (final key in [
        'filesystem.read',
        'filesystem.write',
        'json.decode',
        'io.gateway.resource.readBytes',
        'io.gateway.verification.readBytes'
      ]) {
        expect(withTrainers.counters[key] ?? 0, baseline.counters[key] ?? 0,
            reason: '$key changed with unrelated trainers during edit $i');
      }
    }
  });

  for (final projectChange in [
    'none',
    'missing',
    'different',
    'oversized',
    'equivalent',
    'moved',
    'late-missing',
    'late-oversized',
    'redo-missing',
    'redo-moved',
    'undo-pending',
    'redo-pending',
    'late-pending',
    'recover-missing',
    'recover-same',
    'recover-different',
    'recover-pending',
    'recover-redo-missing',
    'recover-redo-same',
    'recover-write-missing',
    'recover-write-same',
    'recover-write-changed-dependency',
    'recover-write-after-promotion-same',
    'recover-write-after-promotion-changed-dependency',
    'recover-write-no-dependency',
    'recover-write-create-same',
    'recover-write-create-changed-dependency',
    'recover-undo-changed-dependency',
    'recover-redo-changed-dependency',
    'recover-undo-after-promotion-changed-dependency',
    'recover-redo-after-promotion-changed-dependency',
    'recover-undo-dependency-same',
    'recover-redo-dependency-same',
    'recover-undo-dependency-prior',
    'recover-redo-dependency-prior',
    'completed-write-changed-dependency',
    'completed-undo-changed-dependency',
    'completed-redo-changed-dependency',
    'completed-write-missing-descriptor',
    'completed-write-mismatched-receipt',
  ]) {
    test(
        projectChange == 'none'
            ? 'writes catalog Pokemon media without losing v2 fields'
            : 'checks catalog media history after project change: $projectChange',
        () async {
      final root = await qaDirectory.createTemp('pokemon-media-catalog-');
      addTearDown(() => root.delete(recursive: true));
      final store = await CatalogStorageStore.open(projectRoot: root.path);
      await WorkingProjectCatalog.create(
        store: store,
        projectId: 'pokemon-media-catalog',
        project: ProjectManifest(
          name: 'Media fixture',
          maps: [
            for (var i = 0; i < 50; i++)
              ProjectMapEntry(
                id: 'unrelated-$i',
                name: 'Unrelated $i',
                relativePath: 'maps/unrelated-$i.json',
              ),
          ],
          tilesets: const [],
        ),
      );
      final unrelated = File('${root.path}/maps/unrelated-0.json');
      await unrelated.parent.create(recursive: true);
      await unrelated.writeAsString('{invalid unrelated map');
      const path = 'data/pokemon/media/oshawott.json';
      final file = File('${root.path}/$path');
      await file.parent.create(recursive: true);
      final original = {
        'schemaVersion': 2,
        'speciesId': 'oshawott',
        'defaultFormId': 'base',
        'variants': {
          'base': {'frontAnimated': 'assets/front.gif', 'extra': 4}
        },
        'vendorExtension': true,
      };
      final before = utf8.encode(jsonEncode(original));
      final createMedia = projectChange.startsWith('recover-write-create-');
      if (!createMedia) await file.writeAsBytes(before);
      final reader = _CountingReader();
      addTearDown(() {
        expect(reader.reads.where((path) => path.startsWith('maps/')), isEmpty);
      });
      final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path],
        fileReader: reader,
      );
      final handles = WorkspaceHandleStore();
      final snapshots = ProjectSnapshotLoader(handles: handles);
      final opener = ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
        catalogMetadataFields: {},
        workshopScope: true,
        initializeSceneOwners: false,
      );
      final opened = await opener.openProject(root.path);
      var crashUndo = false;
      var undoCrashed = false;
      var crashAfterMediaPromotion = false;
      var captureFinalJournal = false;
      AuthoringTransactionJournal? retainedJournal;
      final retainedPayloads =
          <({String path, TransactionPayloadKind kind, List<int>? bytes})>[];
      final mutations = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: snapshots,
        catalogFileReader: reader,
        faultInjector: (context) async {
          if (captureFinalJournal &&
              context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterJournalCommitted) {
            retainedJournal =
                await store.gateway.readJournal(context.operationId);
            for (final entry in retainedJournal!.entries) {
              for (final kind in TransactionPayloadKind.values) {
                final staged = await store.gateway.readStagedPayload(
                    operationId: context.operationId,
                    storageKey: entry.storageKey,
                    kind: kind);
                final payload = staged.payload;
                try {
                  retainedPayloads.add((
                    path: entry.storageKey,
                    kind: kind,
                    bytes: await payload?.readBytes(),
                  ));
                } finally {
                  await payload?.release();
                }
              }
            }
            captureFinalJournal = false;
          }
          final checkpointReached = crashAfterMediaPromotion
              ? context.checkpoint ==
                      AuthoringTransactionCheckpoint.afterResourcePromoted &&
                  context.storageKey == 'data/pokemon/media/oshawott.json'
              : context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterReservation;
          if (crashUndo && checkpointReached) {
            crashUndo = false;
            undoCrashed = true;
            throw const AuthoringTransactionSimulatedCrash();
          }
        },
      );
      await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      addTearDown(() async {
        await mutations.detachWorkspace(opened.workspaceHandle);
        opener.closeWorkspace(opened.workspaceHandle);
      });
      await mutations.prepareWorkshopCatalog(opened.projectHandle);
      final edited = {
        ...original,
        'variants': {
          'base': {
            'frontAnimated': 'assets/front.gif',
            'frontStatic': 'assets/front.png',
            'extra': 4
          },
        },
      };
      final parameters = {
        'relativePath': path,
        'document': edited,
        if (!createMedia) 'beforeBytesBase64': base64Encode(before),
      };
      const speciesPath = 'data/pokemon/species/oshawott.json';
      final speciesFile = File('${root.path}/$speciesPath');
      final dependencies = (projectChange.startsWith('completed-') ||
              projectChange.startsWith('recover-') &&
                  projectChange != 'recover-write-no-dependency' &&
                  (projectChange.startsWith('recover-write-') ||
                      projectChange.contains('dependency')))
          ? {pokemonSpeciesResourceIdentity('oshawott'): speciesPath}
          : <String, String>{};
      if (dependencies.isNotEmpty) {
        await speciesFile.parent.create(recursive: true);
        await speciesFile
            .writeAsString('{"id":"oshawott","refs":{"media":"oshawott"}}');
      }
      final snapshot = await mutations.readWorkshopSnapshot(
        opened.projectHandle,
        actionId: 'pokemon.media.write',
        parameters: parameters,
        readDependencies: dependencies,
      );
      final plan = await mutations.planMutation(
        opened.projectHandle,
        AuthoringRequest(
          requestId: 'catalog-media',
          actionId: 'pokemon.media.write',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision: snapshot.revision,
          idempotencyKey: 'catalog-media',
          parameters: parameters,
          extensions: {
            'workshopScope': true,
            if (dependencies.isNotEmpty)
              'workshopReadDependencies': dependencies,
          },
        ),
      );
      await store.gateway.writeJournal(_pendingJournal(path));
      await expectLater(
        mutations.applyMutation(
          opened.projectHandle,
          planId: plan.planId,
          operationId: 'catalog-media',
        ),
        throwsA(isA<AuthoringRecoveryException>().having(
          (error) => error.code,
          'code',
          'resource_pack.recovery_required',
        )),
      );
      if (createMedia) {
        expect(await file.exists(), isFalse);
      } else {
        expect(await file.readAsBytes(), before);
      }
      await store.gateway.deleteTransaction('pending-media');
      if (projectChange.startsWith('recover-write-')) {
        crashAfterMediaPromotion = projectChange.contains('after-promotion');
        crashUndo = true;
        await expectLater(
          mutations.applyMutation(
            opened.projectHandle,
            planId: plan.planId,
            operationId: 'catalog-media',
          ),
          throwsA(isA<AuthoringTransactionSimulatedCrash>()),
        );
        expect(undoCrashed, isTrue);
        final interruptedBytes =
            await file.exists() ? await file.readAsBytes() : null;
        if (crashAfterMediaPromotion) {
          expect(
              (jsonDecode(utf8.decode(interruptedBytes!)) as Map)['variants']
                  ['base']['frontStatic'],
              'assets/front.png');
        } else {
          expect(interruptedBytes, createMedia ? isNull : before);
        }
        if (projectChange == 'recover-write-missing') {
          await File('${root.path}/project.json').delete();
          await expectLater(
            mutations.recoverMutation(
              opened.projectHandle,
              operationId: 'catalog-media',
            ),
            throwsA(isA<CatalogStorageException>().having((error) => error.code,
                'code', 'catalog.project_descriptor_changed')),
          );
          expect(await file.readAsBytes(), before);
          expect(await store.gateway.readJournal('catalog-media'), isNotNull);
        } else if (projectChange.endsWith('changed-dependency')) {
          await speciesFile
              .writeAsString('{"id":"oshawott","refs":{"media":"different"}}');
          await expectLater(
            mutations.recoverMutation(
              opened.projectHandle,
              operationId: 'catalog-media',
            ),
            throwsA(isA<AuthoringRecoveryException>().having(
                (error) => error.code, 'code', 'recovery.dependency_changed')),
          );
          expect(await file.exists() ? await file.readAsBytes() : null,
              interruptedBytes);
          expect(await store.gateway.readJournal('catalog-media'), isNotNull);
        } else {
          await mutations.recoverMutation(
            opened.projectHandle,
            operationId: 'catalog-media',
          );
          final recovered = jsonDecode(await file.readAsString()) as Map;
          expect(recovered['variants']['base']['frontAnimated'],
              'assets/front.gif');
          expect(
              recovered['variants']['base']['frontStatic'], 'assets/front.png');
        }
        return;
      }
      captureFinalJournal = projectChange.startsWith('completed-write-');
      final applied = await mutations.applyMutation(
        opened.projectHandle,
        planId: plan.planId,
        operationId: 'catalog-media',
      );
      final after = jsonDecode(await file.readAsString()) as Map;
      expect(after['vendorExtension'], true);
      final variant = (after['variants'] as Map)['base'] as Map;
      expect(variant['frontAnimated'], 'assets/front.gif');
      expect(variant['frontStatic'], 'assets/front.png');
      expect(variant['extra'], 4);
      final afterBytes = await file.readAsBytes();
      final descriptorFile = File('${root.path}/project.json');
      if (projectChange.startsWith('completed-')) {
        final undo = projectChange.startsWith('completed-undo-');
        final redo = projectChange.startsWith('completed-redo-');
        var receipt = applied.receipt;
        var operationId = 'catalog-media';
        var expectedBytes = afterBytes;
        if (undo || redo) {
          if (redo) {
            await mutations.undoMutation(opened.projectHandle,
                entryId: applied.receipt.receiptId,
                idempotencyKey: 'undo-before-completed-redo');
          }
          captureFinalJournal = true;
          operationId = redo ? 'completed-redo' : 'completed-undo';
          final result = redo
              ? await mutations.redoMutation(opened.projectHandle,
                  entryId: applied.receipt.receiptId,
                  idempotencyKey: operationId)
              : await mutations.undoMutation(opened.projectHandle,
                  entryId: applied.receipt.receiptId,
                  idempotencyKey: operationId);
          receipt = result.receipt;
          expectedBytes = redo ? afterBytes : before;
        }
        expect(retainedJournal, isNotNull);
        expect(retainedJournal!.status, AuthoringTransactionStatus.committed);
        for (final payload in retainedPayloads) {
          await store.gateway.stagePayload(
            operationId: operationId,
            storageKey: payload.path,
            kind: payload.kind,
            bytes: payload.bytes,
          );
        }
        final journal = projectChange == 'completed-write-mismatched-receipt'
            ? retainedJournal!.copyWith(
                finalReceipt: AuthoringReceipt.fromJson({
                  ...retainedJournal!.finalReceipt!.toJson(),
                  'createdAtUtc': '2025-01-01T00:00:00.000Z',
                }),
              )
            : retainedJournal!;
        await store.gateway.writeJournal(journal);
        if (projectChange == 'completed-write-mismatched-receipt') {
          await expectLater(
            mutations.recoverMutation(
              opened.projectHandle,
              operationId: operationId,
            ),
            throwsA(isA<AuthoringRecoveryException>().having(
                (error) => error.code,
                'code',
                'recovery.journal_inconsistent')),
          );
          expect(await file.readAsBytes(), expectedBytes);
          expect((await store.gateway.readJournal(operationId))!.toJson(),
              journal.toJson());
          return;
        }
        if (projectChange.endsWith('missing-descriptor')) {
          await descriptorFile.delete();
        } else {
          await speciesFile
              .writeAsString('{"id":"oshawott","refs":{"media":"different"}}');
        }
        final replay = await mutations.recoverMutation(
          opened.projectHandle,
          operationId: operationId,
        );
        expect(replay.receipt.toJson(), receipt.toJson());
        expect(await file.readAsBytes(), expectedBytes);
        return;
      }
      if (projectChange.startsWith('recover-')) {
        final redo = projectChange.startsWith('recover-redo-');
        crashAfterMediaPromotion = projectChange.contains('after-promotion');
        if (projectChange.endsWith('dependency-prior')) {
          await speciesFile.writeAsString(
              '{"id":"oshawott","refs":{"media":"oshawott"},"name":"updated"}');
        }
        if (redo) {
          await mutations.undoMutation(
            opened.projectHandle,
            entryId: applied.receipt.receiptId,
            idempotencyKey: 'undo-before-crashed-redo',
          );
          expect(await file.readAsBytes(), before);
        }
        final operationId =
            redo ? 'recover-catalog-redo' : 'recover-catalog-undo';
        final unchanged = redo ? before : afterBytes;
        final recovered = redo ? afterBytes : before;
        crashUndo = true;
        await expectLater(
          redo
              ? mutations.redoMutation(opened.projectHandle,
                  entryId: applied.receipt.receiptId,
                  idempotencyKey: operationId)
              : mutations.undoMutation(opened.projectHandle,
                  entryId: applied.receipt.receiptId,
                  idempotencyKey: operationId),
          throwsA(isA<AuthoringTransactionSimulatedCrash>()),
        );
        expect(undoCrashed, isTrue);
        final interruptedBytes = await file.readAsBytes();
        expect(
            interruptedBytes, crashAfterMediaPromotion ? recovered : unchanged);
        if (projectChange.endsWith('-missing') ||
            projectChange == 'recover-different') {
          if (projectChange.endsWith('-missing')) {
            await descriptorFile.delete();
          } else {
            final descriptor =
                jsonDecode(await descriptorFile.readAsString()) as Map;
            descriptor['projectId'] = 'different-project';
            await descriptorFile.writeAsString(jsonEncode(descriptor));
          }
          await expectLater(
            mutations.recoverMutation(
              opened.projectHandle,
              operationId: operationId,
            ),
            throwsA(isA<CatalogStorageException>().having((error) => error.code,
                'code', 'catalog.project_descriptor_changed')),
          );
          expect(await file.readAsBytes(), interruptedBytes);
          expect(await store.gateway.readJournal(operationId), isNotNull);
        } else if (projectChange.endsWith('changed-dependency')) {
          await speciesFile
              .writeAsString('{"id":"oshawott","refs":{"media":"different"}}');
          await expectLater(
            mutations.recoverMutation(
              opened.projectHandle,
              operationId: operationId,
            ),
            throwsA(isA<AuthoringRecoveryException>().having(
                (error) => error.code, 'code', 'recovery.dependency_changed')),
          );
          expect(await file.readAsBytes(), interruptedBytes);
          expect(await store.gateway.readJournal(operationId), isNotNull);
        } else {
          if (projectChange == 'recover-pending') {
            await store.gateway.writeJournal(_pendingJournal(path));
            await expectLater(
              mutations.recoverMutation(
                opened.projectHandle,
                operationId: operationId,
              ),
              throwsA(isA<AuthoringRecoveryException>().having(
                  (error) => error.code,
                  'code',
                  'resource_pack.recovery_required')),
            );
            expect(await file.readAsBytes(), unchanged);
            await store.gateway.deleteTransaction('pending-media');
          }
          await mutations.recoverMutation(
            opened.projectHandle,
            operationId: operationId,
          );
          expect(await file.readAsBytes(), recovered);
        }
        return;
      }
      if (projectChange == 'missing' ||
          projectChange == 'different' ||
          projectChange == 'oversized') {
        if (projectChange == 'missing') {
          await descriptorFile.delete();
        } else if (projectChange == 'oversized') {
          final descriptor = await descriptorFile.readAsString();
          await descriptorFile.writeAsString('${' ' * (1 << 20)}$descriptor');
          reader.reads.clear();
        } else {
          final descriptor =
              jsonDecode(await descriptorFile.readAsString()) as Map;
          descriptor['projectId'] = 'different-project';
          await descriptorFile.writeAsString(jsonEncode(descriptor));
        }
        await expectLater(
          mutations.undoMutation(
            opened.projectHandle,
            entryId: applied.receipt.receiptId,
            idempotencyKey: 'undo-catalog-$projectChange-project',
          ),
          throwsA(isA<CatalogStorageException>().having((error) => error.code,
              'code', 'catalog.project_descriptor_changed')),
        );
        expect(await file.readAsBytes(), afterBytes);
        if (projectChange == 'oversized') {
          expect(reader.reads.where((path) => path == 'project.json'), isEmpty);
        }
        return;
      }
      if (projectChange == 'equivalent') {
        final descriptor = jsonDecode(await descriptorFile.readAsString());
        await descriptorFile.writeAsString(
            const JsonEncoder.withIndent('  ').convert(descriptor));
      }
      if (projectChange == 'late-missing' ||
          projectChange == 'late-oversized') {
        var descriptorReads = 0;
        reader.afterRead = (path) async {
          if (path != 'project.json') return;
          descriptorReads++;
          if (descriptorReads == 4) {
            reader.afterRead = null;
            if (projectChange == 'late-missing') {
              await descriptorFile.delete();
            } else {
              final descriptor = await descriptorFile.readAsString();
              await descriptorFile
                  .writeAsString('${' ' * (1 << 20)}$descriptor');
            }
          }
        };
        await expectLater(
          mutations.undoMutation(
            opened.projectHandle,
            entryId: applied.receipt.receiptId,
            idempotencyKey: 'undo-catalog-late-missing',
          ),
          throwsA(isA<CatalogStorageException>().having((error) => error.code,
              'code', 'catalog.project_descriptor_changed')),
        );
        expect(descriptorReads, 4);
        expect(await file.readAsBytes(), afterBytes);
        expect(await store.gateway.readJournal('undo-catalog-late-missing'),
            isNull);
        return;
      }
      if (projectChange == 'undo-pending' || projectChange == 'late-pending') {
        var descriptorReads = 0;
        if (projectChange == 'undo-pending') {
          await store.gateway.writeJournal(_pendingJournal(path));
        } else {
          reader.afterRead = (readPath) async {
            if (readPath != 'project.json') return;
            descriptorReads++;
            if (descriptorReads == 4) {
              reader.afterRead = null;
              await store.gateway.writeJournal(_pendingJournal(path));
            }
          };
        }
        await expectLater(
          mutations.undoMutation(
            opened.projectHandle,
            entryId: applied.receipt.receiptId,
            idempotencyKey: 'undo-catalog-$projectChange',
          ),
          throwsA(isA<AuthoringRecoveryException>().having(
              (error) => error.code,
              'code',
              'resource_pack.recovery_required')),
        );
        if (projectChange == 'late-pending') expect(descriptorReads, 4);
        expect(await file.readAsBytes(), afterBytes);
        expect(await store.gateway.readJournal('undo-catalog-$projectChange'),
            isNull);
        await store.gateway.deleteTransaction('pending-media');
      }
      if (projectChange == 'moved') {
        await _moveCatalogMediaDirectory(store);
        await expectLater(
          mutations.undoMutation(
            opened.projectHandle,
            entryId: applied.receipt.receiptId,
            idempotencyKey: 'undo-catalog-moved-project',
          ),
          throwsA(isA<AuthoringHistoryException>().having((error) => error.code,
              'code', 'history.pokemon_media_path_changed')),
        );
        expect(await file.readAsBytes(), afterBytes);
        return;
      }
      await mutations.undoMutation(
        opened.projectHandle,
        entryId: applied.receipt.receiptId,
        idempotencyKey: 'undo-catalog-media',
      );
      expect(await file.readAsBytes(), before);
      if (projectChange == 'redo-pending') {
        await store.gateway.writeJournal(_pendingJournal(path));
        await expectLater(
          mutations.redoMutation(
            opened.projectHandle,
            entryId: applied.receipt.receiptId,
            idempotencyKey: 'redo-catalog-pending',
          ),
          throwsA(isA<AuthoringRecoveryException>().having(
              (error) => error.code,
              'code',
              'resource_pack.recovery_required')),
        );
        expect(await file.readAsBytes(), before);
        await store.gateway.deleteTransaction('pending-media');
      }
      if (projectChange == 'redo-missing' || projectChange == 'redo-moved') {
        if (projectChange == 'redo-missing') {
          await descriptorFile.delete();
        } else {
          await _moveCatalogMediaDirectory(store);
        }
        await expectLater(
          mutations.redoMutation(
            opened.projectHandle,
            entryId: applied.receipt.receiptId,
            idempotencyKey: 'redo-catalog-$projectChange',
          ),
          throwsA(projectChange == 'redo-missing'
              ? isA<CatalogStorageException>().having((error) => error.code,
                  'code', 'catalog.project_descriptor_changed')
              : isA<AuthoringHistoryException>().having((error) => error.code,
                  'code', 'history.pokemon_media_path_changed')),
        );
        expect(await file.readAsBytes(), before);
        return;
      }
      await mutations.redoMutation(
        opened.projectHandle,
        entryId: applied.receipt.receiptId,
        idempotencyKey: 'redo-catalog-media',
      );
      expect(await file.readAsBytes(), afterBytes);
    });
  }

  for (final mediaDir in ['', '.', 'data/pokemon/media']) {
    for (final catalog in [false, true]) {
      test(
          'writes scoped Pokemon media for directory "$mediaDir" and catalog $catalog',
          () async {
        final root = await qaDirectory.createTemp('pokemon-media-root-');
        addTearDown(() => root.delete(recursive: true));
        const initial =
            ProjectManifest(name: 'Media fixture', maps: [], tilesets: []);
        final project = initial.copyWith(
            pokemon: initial.pokemon.copyWith(mediaDir: mediaDir));
        if (catalog) {
          final store = await CatalogStorageStore.open(projectRoot: root.path);
          await WorkingProjectCatalog.create(
            store: store,
            projectId: 'pokemon-media-root',
            project: project,
          );
        } else {
          await File('${root.path}/project.json')
              .writeAsString(jsonEncode(project.toJson()));
        }
        final isRoot = mediaDir.isEmpty || mediaDir == '.';
        final path = isRoot ? 'oshawott.json' : '$mediaDir/oshawott.json';
        final file = File('${root.path}/$path');
        await file.parent.create(recursive: true);
        final original = {
          'schemaVersion': 2,
          'speciesId': 'oshawott',
          'defaultFormId': 'base',
          'variants': {
            'base': {'frontAnimated': 'assets/front.gif'}
          },
        };
        final before = utf8.encode(jsonEncode(original));
        await file.writeAsBytes(before);
        final reader = _CountingReader();
        final policy = await WorkspacePolicy.create(
            allowedRootPaths: [root.path], fileReader: reader);
        final handles = WorkspaceHandleStore();
        final opener = ProjectOpenService(
          policy: policy,
          fileReader: reader,
          handles: handles,
          catalogMetadataFields: {},
          workshopScope: true,
          initializeSceneOwners: false,
        );
        final opened = await opener.openProject(root.path);
        final mutations = LocalMapAuthoringMutationApi(
          policy: policy,
          snapshotLoader: ProjectSnapshotLoader(handles: handles),
          catalogFileReader: reader,
        );
        await mutations.attachProject(
          projectRootPath: root.path,
          workspaceHandle: opened.workspaceHandle,
          projectHandle: opened.projectHandle,
        );
        addTearDown(() async {
          await mutations.detachWorkspace(opened.workspaceHandle);
          opener.closeWorkspace(opened.workspaceHandle);
        });
        await mutations.prepareWorkshopCatalog(opened.projectHandle);
        final parameters = {
          'relativePath': path,
          'document': {
            ...original,
            'variants': {
              'base': {
                'frontAnimated': 'assets/front.gif',
                'frontStatic': 'assets/front.png'
              }
            },
          },
          'beforeBytesBase64': base64Encode(before),
        };
        final snapshot = await mutations.readWorkshopSnapshot(
          opened.projectHandle,
          actionId: 'pokemon.media.write',
          parameters: parameters,
        );
        final plan = await mutations.planMutation(
          opened.projectHandle,
          AuthoringRequest(
            requestId: 'root-media',
            actionId: 'pokemon.media.write',
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: 'root-media',
            parameters: parameters,
            extensions: {'workshopScope': true},
          ),
        );
        await mutations.applyMutation(opened.projectHandle,
            planId: plan.planId, operationId: 'root-media');
        final afterBytes = await file.readAsBytes();
        final after = jsonDecode(utf8.decode(afterBytes)) as Map;
        expect((after['variants'] as Map)['base']['frontAnimated'],
            'assets/front.gif');
        expect((after['variants'] as Map)['base']['frontStatic'],
            'assets/front.png');

        final projectFile = File('${root.path}/project.json');
        final projectBytes =
            await projectFile.exists() ? await projectFile.readAsBytes() : null;
        final prefix = isRoot ? '' : '$mediaDir/';
        final invalidPaths = [
          'project.json',
          'PROJECT.JSON',
          '${prefix}other.json',
          '${prefix}nested/media.json',
          '${prefix}nested\\media.json',
          '../outside.json',
        ];
        for (final (index, invalidPath) in invalidPaths.indexed) {
          final invalidParameters = {
            'relativePath': invalidPath,
            'document': original
          };
          await expectLater(() async {
            final invalidSnapshot = await mutations.readWorkshopSnapshot(
              opened.projectHandle,
              actionId: 'pokemon.media.write',
              parameters: invalidParameters,
            );
            await mutations.planMutation(
              opened.projectHandle,
              AuthoringRequest(
                requestId: 'invalid-$index',
                actionId: 'pokemon.media.write',
                actionVersion: 1,
                workspaceHandle: opened.workspaceHandle.value,
                expectedRevision: invalidSnapshot.revision,
                idempotencyKey: 'invalid-$index',
                parameters: invalidParameters,
                extensions: {'workshopScope': true},
              ),
            );
          },
              throwsA(anyOf(
                isA<ProjectSnapshotException>().having((error) => error.code,
                    'code', 'project.workshop_dependency_invalid'),
                isA<ArgumentError>()
                    .having((error) => error.name, 'name', 'relativePath'),
                isA<WorkspaceAccessException>().having(
                    (error) => error.code, 'code', 'workspace.path_traversal'),
                isA<TransactionFileGatewayException>().having(
                    (error) => error.code,
                    'code',
                    'transaction.storage_key_invalid'),
              )));
        }
        expect(await file.readAsBytes(), afterBytes);
        expect(await projectFile.exists(), projectBytes != null);
        if (projectBytes != null) {
          expect(await projectFile.readAsBytes(), projectBytes);
        }
      });
    }
  }
}

Future<void> _moveCatalogMediaDirectory(CatalogStorageStore store) async {
  final snapshot = (await store.openRoot((await store.readHead())!)).snapshot;
  final key = CatalogDefinitionKey(
      CatalogDefinitionKind.catalogMetadata, 'publication-shell');
  final shell = (await snapshot.lookup(key))!;
  final payload = jsonDecode(jsonEncode(shell.payload)) as Map<String, dynamic>;
  final project = payload['value'] as Map;
  (project['pokemon'] as Map)['mediaDir'] = 'data/pokemon/other-media';
  final editing = await CatalogEditingSession.open(
    store: store,
    projectId: 'pokemon-media-catalog',
    actorId: 'external-editor',
    incrementalHistory: true,
  );
  try {
    final moved = await editing.planPatch(
      upserts: [
        CatalogDefinitionUnit(
            key: key, payload: payload, references: shell.references)
      ],
      idempotencyKey: 'change-media-directory',
    );
    await editing.apply(moved);
  } finally {
    await editing.close();
  }
}

final class _BoundaryObserver implements AuthoringPerformanceObserver {
  void Function()? onApply;
  final counters = <String, int>{};

  @override
  void incrementCounter(String name, {int by = 1}) {
    counters[name] = (counters[name] ?? 0) + by;
  }

  @override
  AuthoringPerformanceSpan? startSpan(String name) {
    if (name == AuthoringPerformanceSpanName.apply && onApply != null) {
      final callback = onApply!;
      onApply = null;
      callback();
    }
    return null;
  }
}

final class _CountingReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final reads = <String>[];
  final delegate = const LocalProjectFileReader();
  Future<void> Function(String path)? afterRead;
  int bytesRead = 0;

  void reset() {
    reads.clear();
    bytesRead = 0;
  }

  @override
  bool get supportsStreamingResources => true;

  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);

  @override
  Future<List<int>> readBytes(
      {required String projectRoot, required String relativePath}) async {
    reads.add(relativePath);
    final bytes = await delegate.readBytes(
        projectRoot: projectRoot, relativePath: relativePath);
    bytesRead += bytes.length;
    await afterRead?.call(relativePath);
    return bytes;
  }

  @override
  Stream<List<int>> openRead(
      {required String projectRoot, required String relativePath}) async* {
    reads.add(relativePath);
    await for (final chunk in delegate.openRead(
        projectRoot: projectRoot, relativePath: relativePath)) {
      bytesRead += chunk.length;
      yield chunk;
    }
    await afterRead?.call(relativePath);
  }

  @override
  Future<ProjectResourceProbe> probeResource(
          {required String projectRoot, required String relativePath}) =>
      delegate.probeResource(
          projectRoot: projectRoot, relativePath: relativePath);
}

AuthoringTransactionJournal _pendingJournal(String path) {
  final resource =
      AuthoringResourceRef(kind: 'pokemonDocument', id: 'media:oshawott');
  final before = 'sha256:${'0' * 64}';
  final after = 'sha256:${'1' * 64}';
  final receipt = AuthoringReceipt(
    receiptId: 'pending-receipt',
    requestId: 'pending-request',
    actionId: 'pokemon.media.write',
    actionVersion: 1,
    status: AuthoringReceiptStatus.applied,
    createdAtUtc: '2026-11-01T00:00:00.000Z',
    beforeRevision: AuthoringRevisionSet([
      AuthoringResourceRevision(resource: resource, revision: before),
    ]).fingerprint,
    afterRevision: AuthoringRevisionSet([
      AuthoringResourceRevision(resource: resource, revision: after),
    ]).fingerprint,
    diff: AuthoringDiff([
      AuthoringDiffEntry(
        operation: AuthoringDiffOperation.replace,
        resource: resource,
        path: '/',
        before: false,
        after: true,
      ),
    ]),
  );
  return AuthoringTransactionJournal(
    operationId: 'pending-media',
    planId: 'pending-plan',
    scope: AuthoringIdempotencyScope(
      actorId: 'actor',
      projectId: 'project',
      actionId: 'pokemon.media.write',
      actionVersion: 1,
      key: 'pending-media',
    ),
    status: AuthoringTransactionStatus.prepared,
    createdAt: DateTime.utc(2026, 11, 1),
    updatedAt: DateTime.utc(2026, 11, 1),
    entries: [
      AuthoringTransactionJournalEntry(
        resource: resource,
        storageKey: path,
        beforeRevision: before,
        afterRevision: after,
      ),
    ],
    intendedReceipt: receipt,
  );
}
