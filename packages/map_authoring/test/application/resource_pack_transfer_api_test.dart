import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:mirrors';
import 'dart:typed_data';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import '../domains/assets/resource_pack_import_fixture.dart';
import '../domains/assets/resource_pack_export_test.dart' as source;

void main() {
  test(
      'export acknowledgement belongs to its prepared effects and cannot bypass stale selection or revision',
      () async {
    final fixture = await NativeResourcePackImportFixture.create();
    await fixture.apply(await fixture.plan(await fixture.prepare()));
    final api = LocalResourcePackTransferApi(
        mutations: fixture.mutations, snapshotLoader: fixture.loader);
    final project = fixture.opened.projectHandle;
    Future<void> mutate(
        String id, String action, Map<String, Object?> values) async {
      final snapshot = await fixture.loader.load(project);
      final plan = await fixture.mutations.planMutation(
          project,
          AuthoringRequest(
              requestId: id,
              actionId: action,
              actionVersion: 1,
              workspaceHandle: fixture.opened.workspaceHandle.value,
              expectedRevision: snapshot.revision,
              idempotencyKey: id,
              parameters: values));
      await fixture.mutations
          .applyMutation(project, planId: plan.planId, operationId: id);
    }

    try {
      await mutate('private-map', 'map.create', {
        'mapId': 'private-map',
        'name': 'Private map',
        'width': 2,
        'height': 2
      });
      final element =
          (await fixture.loader.load(project)).manifest.elements.first;
      await mutate('make-private', 'resource.classify', {
        'resourceKind': 'element',
        'resourceId': element.id,
        'mapId': 'private-map'
      });
      final native = await api.transfer(project,
          verb: 'selection.create', input: {'mode': 'native'});
      var chosen = await api.transfer(project, verb: 'selection.patch', input: {
        'selectionHandle': native['selectionHandle'],
        'revision': native['revision'],
        'add': [
          {'kind': 'element', 'id': element.id}
        ]
      });
      Future<Map> prepare() async {
        final input = {
          'selectionHandle': chosen['selectionHandle'],
          'revision': chosen['revision'],
          'expectedRevision': native['sourceRevision'],
          'metadata': fixture.source.archive.inspection.manifest.pack.toJson(),
          'author': 'Publisher'
        };
        await expectLater(
            api.transfer(project,
                verb: 'prepare',
                input: {...input, 'acknowledgeOrganizationRemoval': true}),
            throwsFormatException);
        final done = await waitForJob(api, project,
            await api.transfer(project, verb: 'prepare', input: input));
        expect((done['snapshot'] as Map)['state'], 'succeeded',
            reason: done.toString());
        final prepared = done['result'] as Map;
        expect(prepared['requiresOrganizationAcknowledgement'], isTrue);
        expect((prepared['summary'] as Map)['promotionCount'], 1);
        return prepared;
      }

      final first = await prepare();
      final session = (_privateField(api, '_sessions') as Map).values.single;
      final jobs =
          _privateField(_privateField(session, 'jobs')!, '_jobs') as Map;
      final jobCount = jobs.length;
      for (final value in [null, 'true', 1]) {
        await expectLater(
            api.transfer(project, verb: 'export', input: {
              'preparedExportHandle': first['preparedExportHandle'],
              'acknowledgeOrganizationRemoval': value
            }),
            throwsA(isA<ResourcePackTransferException>().having(
                (error) => error.code, 'code', 'resource_pack.input_invalid')));
        expect(jobs, hasLength(jobCount));
      }
      for (final ack in [null, false]) {
        await expectLater(
            api.transfer(project, verb: 'export', input: {
              'preparedExportHandle': first['preparedExportHandle'],
              if (ack != null) 'acknowledgeOrganizationRemoval': ack
            }),
            throwsA(isA<ResourcePackTransferException>().having(
                (error) => error.code,
                'code',
                'resource_pack.organization_acknowledgement_required')));
      }
      chosen = await api.transfer(project, verb: 'selection.patch', input: {
        'selectionHandle': chosen['selectionHandle'],
        'revision': chosen['revision'],
        'add': []
      });
      await expectLater(
          api.transfer(project, verb: 'export', input: {
            'preparedExportHandle': first['preparedExportHandle'],
            'acknowledgeOrganizationRemoval': true
          }),
          throwsA(isA<ResourcePackTransferException>().having(
              (error) => error.code, 'code', 'resource_pack.selection_stale')));
      final current = await prepare();
      final exported = await waitForJob(
          api,
          project,
          await api.transfer(project, verb: 'export', input: {
            'preparedExportHandle': current['preparedExportHandle'],
            'acknowledgeOrganizationRemoval': true
          }));
      expect((exported['snapshot'] as Map)['state'], 'succeeded',
          reason: exported.toString());
      await api.transfer(project,
          verb: 'release',
          input: {'handle': (exported['result'] as Map)['artifactHandle']});
      await mutate('later-change', 'resource.family.create',
          {'familyId': 'later-change', 'name': 'Later change'});
      final stale = await waitForJob(
          api,
          project,
          await api.transfer(project, verb: 'export', input: {
            'preparedExportHandle': current['preparedExportHandle'],
            'acknowledgeOrganizationRemoval': true
          }));
      expect((stale['snapshot'] as Map)['errorCode'],
          'resource_pack.revision_changed');
      expect(stale['result'], isNull);
    } finally {
      await api.closeTransferWorkspace(fixture.opened.workspaceHandle);
      await fixture.dispose();
    }
  });

  test(
      'native inventory and prepared preview keep one captured revision and release their shared owner',
      () async {
    final fixture = await NativeResourcePackImportFixture.create();
    await fixture.apply(await fixture.plan(await fixture.prepare()));
    final api = LocalResourcePackTransferApi(
        mutations: fixture.mutations, snapshotLoader: fixture.loader);
    final project = fixture.opened.projectHandle;
    Future<void> addFamily(String id, String name) async {
      final snapshot = await fixture.loader.load(project);
      final plan = await fixture.mutations.planMutation(
          project,
          AuthoringRequest(
              requestId: id,
              actionId: 'resource.family.create',
              actionVersion: 1,
              workspaceHandle: fixture.opened.workspaceHandle.value,
              expectedRevision: snapshot.revision,
              idempotencyKey: id,
              parameters: {'familyId': id, 'name': name}));
      await fixture.mutations
          .applyMutation(project, planId: plan.planId, operationId: id);
    }

    try {
      await addFamily('captured-family', '🌲' * 2000);
      final native = await api.transfer(project,
          verb: 'selection.create', input: {'mode': 'native'});
      final selected = await api
          .transfer(project, verb: 'selection.select_filtered', input: {
        'selectionHandle': native['selectionHandle'],
        'revision': native['revision'],
        'filter': {}
      });
      final families = await api.transfer(project, verb: 'entries', input: {
        'selectionHandle': selected['selectionHandle'],
        'section': 'families'
      });
      expect(families['scope'], 'nativeInventory');
      expect(families['sourceRevision'], native['sourceRevision']);
      final family = (families['items'] as List)
          .cast<Map>()
          .singleWhere((row) => row['id'] == 'captured-family');
      expect(family['labelComplete'], isFalse);
      expect((family['label'] as String).runes.length, 160);
      for (final section in ['authors', 'sources']) {
        final page = await api.transfer(project, verb: 'entries', input: {
          'selectionHandle': selected['selectionHandle'],
          'section': section,
          'limit': 1
        });
        expect(page['scope'], 'nativeInventory');
      }
      Future<Map> prepare() async {
        final job = await api.transfer(project, verb: 'prepare', input: {
          'selectionHandle': selected['selectionHandle'],
          'revision': selected['revision'],
          'expectedRevision': native['sourceRevision'],
          'metadata': fixture.source.archive.inspection.manifest.pack.toJson(),
          'author': 'Preview author'
        });
        expect(((job['snapshot'] as Map)['request'] as Map)['projectRevision'],
            native['sourceRevision']);
        final done = await waitForJob(api, project, job);
        expect((done['snapshot'] as Map)['state'], 'succeeded',
            reason: done.toString());
        return done['result'] as Map;
      }

      final queriedSelection = await api.queryTransfer(
          project,
          AuthoringQueryRequest(
              resourceKind: 'resourcePackSelection',
              operation: AuthoringQueryOperation.get,
              ids: [selected['selectionHandle'] as String]));
      expect(queriedSelection['snapshotRevision'], native['sourceRevision']);
      final first = await prepare();
      final second = await prepare();
      expect(first['previewHandle'], isA<String>());
      expect(first['requiresOrganizationAcknowledgement'], isA<bool>());
      final firstPage = await api.transfer(project,
          verb: 'preview',
          input: {'previewHandle': first['previewHandle'], 'limit': 1});
      final rows = <Map>[];
      var page = firstPage;
      while (true) {
        rows.addAll((page['items'] as List).cast<Map>());
        expect(
            utf8
                .encode(jsonEncode({
                  'content': [
                    {'type': 'text', 'text': jsonEncode(page)}
                  ],
                  'structuredContent': page
                }))
                .length,
            lessThanOrEqualTo(256 * 1024));
        if (page['nextCursor'] == null) break;
        page = await api.transfer(project, verb: 'preview', input: {
          'previewHandle': first['previewHandle'],
          'limit': 1,
          'cursor': page['nextCursor']
        });
      }
      final kinds = rows
          .where((row) => row['kind'] == 'resource')
          .map((row) => row['resourceKind'])
          .toSet();
      expect(
          kinds,
          containsAll([
            'element',
            'model3d',
            'borderBlueprint',
            'smartTilePreset',
            'character',
            'tileset',
            'environmentPreset'
          ]));
      final border = rows.singleWhere((row) =>
          row['kind'] == 'publication' &&
          row['resourceKind'] == 'borderBlueprint');
      expect(border['label'], 'Original border');
      await addFamily('later-family', 'Later family');
      final repeated = await api.transfer(project,
          verb: 'preview',
          input: {'previewHandle': first['previewHandle'], 'limit': 1});
      expect(repeated['items'], firstPage['items']);
      expect(repeated['sourceRevision'], firstPage['sourceRevision']);
      final capturedFamilies = await api.transfer(project,
          verb: 'entries',
          input: {
            'selectionHandle': selected['selectionHandle'],
            'section': 'families'
          });
      expect(
          (capturedFamilies['items'] as List)
              .cast<Map>()
              .any((row) => row['id'] == 'later-family'),
          isFalse);
      await api.transfer(project,
          verb: 'release', input: {'handle': first['preparedExportHandle']});
      await expectLater(
          api.transfer(project,
              verb: 'preview',
              input: {'previewHandle': first['previewHandle']}),
          throwsA(isA<ResourcePackTransferException>()));
      await api.transfer(project,
          verb: 'preview', input: {'previewHandle': second['previewHandle']});
      await api.transfer(project,
          verb: 'release', input: {'handle': second['previewHandle']});
      await expectLater(
          api.transfer(project, verb: 'export', input: {
            'preparedExportHandle': second['preparedExportHandle'],
            'acknowledgeOrganizationRemoval': true
          }),
          throwsA(isA<ResourcePackTransferException>().having(
              (error) => error.code,
              'code',
              'resource_pack.preparation_unknown')));
    } finally {
      await api.closeTransferWorkspace(fixture.opened.workspaceHandle);
      await fixture.dispose();
    }
  });

  for (final verb in ['prepare', 'export']) {
    for (final close in [false, true]) {
      test(
          'late ${close ? 'close' : 'cancellation'} discards an undisclosed $verb result',
          () async {
        var now = DateTime.utc(2026, 10, 17);
        final fixture =
            await NativeResourcePackImportFixture.create(clock: () => now);
        await fixture.apply(await fixture.plan(await fixture.prepare()));
        final api = LocalResourcePackTransferApi(
            mutations: fixture.mutations, snapshotLoader: fixture.loader);
        final project = fixture.opened.projectHandle;
        final store = fixture.mutations.resourcePackPayloadStore(project);
        final baselineBytes = store.cachedBytes;
        try {
          final native = await api.transfer(project,
              verb: 'selection.create', input: {'mode': 'native'});
          final selected = await api
              .transfer(project, verb: 'selection.select_filtered', input: {
            'selectionHandle': native['selectionHandle'],
            'revision': native['revision'],
            'filter': {'kind': 'character'}
          });
          var input = <String, Object?>{
            'selectionHandle': selected['selectionHandle'],
            'revision': selected['revision'],
            'expectedRevision': selected['sourceRevision'],
            'metadata':
                fixture.source.archive.inspection.manifest.pack.toJson(),
            'author': 'Publisher',
          };
          String? sourcePreparation;
          if (verb == 'export') {
            final done = await waitForJob(api, project,
                await api.transfer(project, verb: 'prepare', input: input));
            expect((done['snapshot'] as Map)['state'], 'succeeded',
                reason: done.toString());
            sourcePreparation =
                (done['result'] as Map)['preparedExportHandle'] as String;
            input = {
              'acknowledgeOrganizationRemoval': true,
              'preparedExportHandle': sourcePreparation
            };
          }
          final session =
              (_privateField(api, '_sessions') as Map).values.single;
          final owners = _privateField(
                  session, verb == 'prepare' ? 'preparedExports' : 'artifacts')
              as Map;
          final jobs =
              _privateField(_privateField(session, 'jobs')!, '_jobs') as Map;
          final reached = Completer<void>();
          String? jobId;
          Future<void>? interruption;
          final caller = Zone.current;
          await runZoned(() async {
            final start = await api.transfer(project, verb: verb, input: input);
            jobId = start['jobId'] as String;
            if (sourcePreparation != null) {
              await api.transfer(project,
                  verb: 'release', input: {'handle': sourcePreparation});
            }
            await reached.future.timeout(const Duration(seconds: 10));
            await interruption;
          }, zoneSpecification: ZoneSpecification(
              scheduleMicrotask: (self, parent, zone, callback) {
            parent.scheduleMicrotask(zone, () {
              if (!reached.isCompleted && jobId != null && owners.isNotEmpty) {
                interruption = caller.run(() async {
                  if (close) {
                    await api
                        .closeTransferWorkspace(fixture.opened.workspaceHandle);
                  } else {
                    await api.transfer(project,
                        verb: 'cancel', input: {'jobId': jobId});
                  }
                });
                reached.complete();
              }
              callback();
            });
          }));
          expect(reached.isCompleted, isTrue);
          final job = jobs[jobId]!;
          await (_privateField(job, 'completion') as Future<void>);
          expect(_privateField(job, 'state'), AuthoringJobState.cancelled);
          expect(_privateField(job, 'result'), isNull);
          expect(owners, isEmpty);
          expect(_privateField(session, 'previews') as Map, isEmpty);
          expect(_privateField(session, 'cursors') as Map, isEmpty);
          now = now.add(const Duration(days: 2));
          await store.collectExpired();
          expect(store.cachedBytes, baselineBytes);
          expect(store.reservedBytes, 0);
        } finally {
          await api.closeTransferWorkspace(fixture.opened.workspaceHandle);
          await fixture.dispose();
        }
      });
    }
  }

  test(
      'licence handles preserve source authority, handle type, project scope and request bounds',
      () async {
    final fixture = await NativeResourcePackImportFixture.create();
    await fixture.apply(await fixture.plan(await fixture.prepare()));
    final api = LocalResourcePackTransferApi(
        mutations: fixture.mutations, snapshotLoader: fixture.loader);
    final store = fixture.mutations
        .resourcePackPayloadStore(fixture.opened.projectHandle);
    final file =
        await File('${fixture.source.directory.path}/private-license.txt')
            .writeAsString('Scoped original');
    OpenedProject? other;
    try {
      Future<Map> stage() async => waitForJob(
          api,
          fixture.opened.projectHandle,
          await api.transfer(fixture.opened.projectHandle,
              verb: 'stage_license', input: {'sourcePath': file.path}));
      final denied = await stage();
      expect((denied['snapshot'] as Map)['errorCode'],
          'resource_pack.source_outside_allowed_roots');
      await store.authorizeSourceFile(file.path);
      final done = await stage();
      final license = (done['result'] as Map)['licenseHandle'];
      var native = await api.transfer(fixture.opened.projectHandle,
          verb: 'selection.create', input: {'mode': 'native'});
      native = await api.transfer(fixture.opened.projectHandle,
          verb: 'selection.select_filtered',
          input: {
            'selectionHandle': native['selectionHandle'],
            'revision': native['revision'],
            'filter': {'kind': 'character'}
          });
      final input = {
        'selectionHandle': native['selectionHandle'],
        'revision': native['revision'],
        'expectedRevision': native['sourceRevision'],
        'metadata': fixture.source.archive.inspection.manifest.pack.toJson(),
        'author': 'Publisher',
        'licenseHandles': [license]
      };
      await expectLater(
          api.transfer(fixture.opened.projectHandle,
              verb: 'prepare', input: {...input, 'author': 'x' * 129}),
          throwsA(isA<ResourcePackTransferException>()));
      await expectLater(
          api.transfer(fixture.opened.projectHandle,
              verb: 'prepare',
              input: {...input, 'licenseHandles': List.filled(201, license)}),
          throwsA(isA<ResourcePackTransferException>()));
      final largeMetadata = {
        ...fixture.source.archive.inspection.manifest.pack.toJson(),
        'authors': List.filled(200, '🌲' * 64),
        'description': 'é' * 4096,
        'provenance': 'é' * 4096
      };
      expect(
          utf8.encode(jsonEncode({...input, 'metadata': largeMetadata})).length,
          greaterThan(64 * 1024));
      await expectLater(
          api.transfer(fixture.opened.projectHandle,
              verb: 'prepare', input: {...input, 'metadata': largeMetadata}),
          throwsA(isA<ResourcePackTransferException>().having(
              (error) => error.code, 'code', 'resource_pack.input_too_large')));
      other = await fixture.readApi.openProject(fixture.root.path);
      await fixture.mutations.attachProject(
          projectRootPath: fixture.root.path,
          workspaceHandle: other.workspaceHandle,
          projectHandle: other.projectHandle);
      var otherSelection = await api.transfer(other.projectHandle,
          verb: 'selection.create', input: {'mode': 'native'});
      otherSelection = await api.transfer(other.projectHandle,
          verb: 'selection.select_filtered',
          input: {
            'selectionHandle': otherSelection['selectionHandle'],
            'revision': otherSelection['revision'],
            'filter': {'kind': 'character'}
          });
      await expectLater(
          api.transfer(other.projectHandle, verb: 'prepare', input: {
            ...input,
            'selectionHandle': otherSelection['selectionHandle'],
            'revision': otherSelection['revision'],
            'expectedRevision': otherSelection['sourceRevision']
          }),
          throwsA(isA<ResourcePackTransferException>().having(
              (error) => error.code, 'code', 'resource_pack.license_unknown')));
      await expectLater(
          api.transfer(fixture.opened.projectHandle,
              verb: 'inspect', input: {'archiveHandle': license}),
          throwsA(isA<ResourcePackTransferException>().having(
              (error) => error.code, 'code', 'resource_pack.archive_unknown')));
    } finally {
      if (other != null) {
        await api.closeTransferWorkspace(other.workspaceHandle);
        await fixture.mutations.detachWorkspace(other.workspaceHandle);
        fixture.handles.closeWorkspace(other.workspaceHandle);
      }
      await api.closeTransferWorkspace(fixture.opened.workspaceHandle);
      await fixture.dispose();
    }
  });

  test(
      'prepare and export cancellation and workspace close release every licence pin',
      () async {
    for (final (cancel, export) in [
      (true, false),
      (false, false),
      (true, true),
      (false, true)
    ]) {
      var now = DateTime.utc(2026, 10, 17);
      final fixture =
          await NativeResourcePackImportFixture.create(clock: () => now);
      await fixture.apply(await fixture.plan(await fixture.prepare()));
      final api = LocalResourcePackTransferApi(
          mutations: fixture.mutations, snapshotLoader: fixture.loader);
      final store = fixture.mutations
          .resourcePackPayloadStore(fixture.opened.projectHandle);
      final baselineBytes = store.cachedBytes;
      try {
        final file =
            await File('${fixture.source.directory.path}/cancel-license.txt')
                .writeAsString('Cancel document');
        await store.authorizeSourceFile(file.path);
        final staged = await waitForJob(
            api,
            fixture.opened.projectHandle,
            await api.transfer(fixture.opened.projectHandle,
                verb: 'stage_license', input: {'sourcePath': file.path}));
        final handle = (staged['result'] as Map)['licenseHandle'];
        var native = await api.transfer(fixture.opened.projectHandle,
            verb: 'selection.create', input: {'mode': 'native'});
        native = await api.transfer(fixture.opened.projectHandle,
            verb: 'selection.select_filtered',
            input: {
              'selectionHandle': native['selectionHandle'],
              'revision': native['revision'],
              'filter': {'kind': 'character'}
            });
        var start = await api
            .transfer(fixture.opened.projectHandle, verb: 'prepare', input: {
          'selectionHandle': native['selectionHandle'],
          'revision': native['revision'],
          'expectedRevision': native['sourceRevision'],
          'metadata': fixture.source.archive.inspection.manifest.pack.toJson(),
          'author': 'Publisher',
          'licenseHandles': [handle, handle]
        });
        await api.transfer(fixture.opened.projectHandle,
            verb: 'release', input: {'handle': handle});
        if (export) {
          final done =
              await waitForJob(api, fixture.opened.projectHandle, start);
          expect((done['snapshot'] as Map)['state'], 'succeeded',
              reason: done.toString());
          final handle = (done['result'] as Map)['preparedExportHandle'];
          start = await api.transfer(fixture.opened.projectHandle,
              verb: 'export',
              input: {
                'acknowledgeOrganizationRemoval': true,
                'preparedExportHandle': handle
              });
          await api.transfer(fixture.opened.projectHandle,
              verb: 'release', input: {'handle': handle});
        }
        if (cancel) {
          final cancelled = await api.transfer(fixture.opened.projectHandle,
              verb: 'cancel', input: {'jobId': start['jobId']});
          expect(cancelled['state'], anyOf('cancelled', 'cancelling'));
          final settled =
              await waitForJob(api, fixture.opened.projectHandle, start);
          expect((settled['snapshot'] as Map)['state'], 'cancelled');
        }
        await api.closeTransferWorkspace(fixture.opened.workspaceHandle);
        now = now.add(const Duration(days: 2));
        await store.collectExpired();
        expect(store.cachedBytes, baselineBytes);
        expect(store.reservedBytes, 0);
      } finally {
        await api.closeTransferWorkspace(fixture.opened.workspaceHandle);
        await fixture.dispose();
      }
    }
  });

  test(
      'v2 stages scoped UTF8 licence handles and consumes a frozen native preparation',
      () async {
    final fixture = await NativeResourcePackImportFixture.create();
    await fixture.apply(await fixture.plan(await fixture.prepare()));
    final api = LocalResourcePackTransferApi(
        mutations: fixture.mutations, snapshotLoader: fixture.loader);
    Future<Map> job(String verb, Map<String, Object?> input) async {
      final start = await api.transfer(fixture.opened.projectHandle,
          verb: verb, input: input);
      final done = await waitForJob(api, fixture.opened.projectHandle, start);
      expect((done['snapshot'] as Map)['state'], 'succeeded',
          reason: done.toString());
      return done['result']! as Map;
    }

    try {
      expect(resourcePackTransferContract['schemaVersion'], 2);
      final handles = <String>[];
      for (final (index, text) in [
        'Licence locale é😀',
        'Licence locale é😀',
        'Second original document'
      ].indexed) {
        final file =
            await File('${fixture.source.directory.path}/license-$index.txt')
                .writeAsString(text);
        await fixture.mutations
            .resourcePackPayloadStore(fixture.opened.projectHandle)
            .authorizeSourceFile(file.path);
        final staged = await job('stage_license', {'sourcePath': file.path});
        handles.add(staged['licenseHandle'] as String);
        expect(staged['byteLength'], utf8.encode(text).length);
        await expectLater(
            api.transfer(fixture.opened.projectHandle,
                verb: 'inspect', input: {'archiveHandle': handles.last}),
            throwsA(isA<ResourcePackTransferException>()));
      }
      final native = await api.transfer(fixture.opened.projectHandle,
          verb: 'selection.create', input: {'mode': 'native'});
      final selected = await api.transfer(fixture.opened.projectHandle,
          verb: 'selection.select_filtered',
          input: {
            'selectionHandle': native['selectionHandle'],
            'revision': native['revision'],
            'filter': {'kind': 'character'}
          });
      final metadata = fixture.source.archive.inspection.manifest.pack.toJson();
      final input = <String, Object?>{
        'selectionHandle': selected['selectionHandle'],
        'revision': selected['revision'],
        'expectedRevision': native['sourceRevision'],
        'metadata': metadata,
        'author': 'Publisher',
        'licenseHandles': [...handles, handles.first],
      };
      final start = await api.transfer(fixture.opened.projectHandle,
          verb: 'prepare', input: input);
      metadata['name'] = 'Mutated after accepting preparation';
      (input['licenseHandles'] as List).clear();
      for (final handle in handles) {
        await api.transfer(fixture.opened.projectHandle,
            verb: 'release', input: {'handle': handle});
      }
      final done = await waitForJob(api, fixture.opened.projectHandle, start);
      expect((done['snapshot'] as Map)['state'], 'succeeded',
          reason: done.toString());
      final prepared = done['result']! as Map;
      expect(prepared['preparedExportHandle'], isA<String>());
      expect(prepared['projectionFingerprint'],
          matches(RegExp(r'^sha256:[0-9a-f]{64}$')));
      final exportStart = await api
          .transfer(fixture.opened.projectHandle, verb: 'export', input: {
        'acknowledgeOrganizationRemoval': true,
        'preparedExportHandle': prepared['preparedExportHandle']
      });
      await api.transfer(fixture.opened.projectHandle,
          verb: 'release', input: {'handle': prepared['preparedExportHandle']});
      final exported =
          await waitForJob(api, fixture.opened.projectHandle, exportStart);
      expect((exported['snapshot'] as Map)['state'], 'succeeded',
          reason: exported.toString());
      final artifact = exported['result']! as Map;
      final chunk = await api.transfer(fixture.opened.projectHandle,
          verb: 'read_payload',
          input: {
            'payloadRef': artifact['payloadRef'],
            'offset': 0,
            'length': 128 * 1024
          });
      final bytes = base64Decode(chunk['bytesBase64']! as String);
      final inspection =
          ResourcePackInspector().inspectSourceSync(_PackBytesSource(bytes));
      final local = inspection.catalog.provenance
          .singleWhere((origin) => origin.author == 'Publisher');
      expect(local.licenseIds, hasLength(2));
      expect(local.resources, isEmpty);
      expect(inspection.manifest.pack.name,
          isNot('Mutated after accepting preparation'));
      expect(inspection.catalog.characters, hasLength(1));
      expect(inspection.catalog.models3d, isEmpty);
      await expectLater(
          api.transfer(fixture.opened.projectHandle, verb: 'export', input: {
            'selectionHandle': selected['selectionHandle'],
            'revision': selected['revision'],
            'expectedRevision': native['sourceRevision'],
            'metadata': metadata,
            'author': 'Publisher',
            'licenseText': 'forbidden'
          }),
          throwsA(anything));
      await api.transfer(fixture.opened.projectHandle,
          verb: 'release', input: {'handle': artifact['artifactHandle']});
    } finally {
      await api.closeTransferWorkspace(fixture.opened.workspaceHandle);
      await fixture.dispose();
    }
  });

  test('prepared export rejects changed selection and current project revision',
      () async {
    final fixture = await NativeResourcePackImportFixture.create();
    await fixture.apply(await fixture.plan(await fixture.prepare()));
    final api = LocalResourcePackTransferApi(
        mutations: fixture.mutations, snapshotLoader: fixture.loader);
    try {
      final native = await api.transfer(fixture.opened.projectHandle,
          verb: 'selection.create', input: {'mode': 'native'});
      var selected = await api.transfer(fixture.opened.projectHandle,
          verb: 'selection.select_filtered',
          input: {
            'selectionHandle': native['selectionHandle'],
            'revision': native['revision'],
            'filter': {'kind': 'character'}
          });
      Future<Map> prepare() async {
        final start = await api
            .transfer(fixture.opened.projectHandle, verb: 'prepare', input: {
          'selectionHandle': selected['selectionHandle'],
          'revision': selected['revision'],
          'expectedRevision': native['sourceRevision'],
          'metadata': fixture.source.archive.inspection.manifest.pack.toJson(),
          'author': 'Publisher',
        });
        final done = await waitForJob(api, fixture.opened.projectHandle, start);
        expect((done['snapshot'] as Map)['state'], 'succeeded',
            reason: done.toString());
        return done['result'] as Map;
      }

      final staleSelection = await prepare();
      selected = await api.transfer(fixture.opened.projectHandle,
          verb: 'selection.select_filtered',
          input: {
            'selectionHandle': selected['selectionHandle'],
            'revision': selected['revision'],
            'filter': {'kind': 'model3d'}
          });
      await expectLater(
          api.transfer(fixture.opened.projectHandle, verb: 'export', input: {
            'acknowledgeOrganizationRemoval': true,
            'preparedExportHandle': staleSelection['preparedExportHandle']
          }),
          throwsA(isA<ResourcePackTransferException>().having(
              (error) => error.code, 'code', 'resource_pack.selection_stale')));
      final staleProject = await prepare();
      final snapshot = await fixture.loader.load(fixture.opened.projectHandle);
      final plan = await fixture.mutations.planMutation(
          fixture.opened.projectHandle,
          AuthoringRequest(
              requestId: 'change-project',
              actionId: 'resource.family.create',
              actionVersion: 1,
              workspaceHandle: fixture.opened.workspaceHandle.value,
              expectedRevision: snapshot.revision,
              idempotencyKey: 'change-project',
              parameters: {'familyId': 'local-added', 'name': 'Local added'}));
      await fixture.mutations.applyMutation(fixture.opened.projectHandle,
          planId: plan.planId, operationId: 'change-project');
      final done = await waitForJob(
          api,
          fixture.opened.projectHandle,
          await api
              .transfer(fixture.opened.projectHandle, verb: 'export', input: {
            'acknowledgeOrganizationRemoval': true,
            'preparedExportHandle': staleProject['preparedExportHandle']
          }));
      expect((done['snapshot'] as Map)['state'], 'failed');
      expect((done['snapshot'] as Map)['errorCode'],
          'resource_pack.revision_changed');
    } finally {
      await api.closeTransferWorkspace(fixture.opened.workspaceHandle);
      await fixture.dispose();
    }
  });

  test('licence staging rejects invalid UTF8 and scoped handle confusion',
      () async {
    final fixture = await NativeResourcePackImportFixture.create();
    final api = LocalResourcePackTransferApi(
        mutations: fixture.mutations, snapshotLoader: fixture.loader);
    try {
      for (final (index, bytes) in [
        [255],
        [0xf0, 0x9f],
        [0xc0, 0xaf]
      ].indexed) {
        final file =
            await File('${fixture.source.directory.path}/invalid-$index.txt')
                .writeAsBytes(bytes);
        await fixture.mutations
            .resourcePackPayloadStore(fixture.opened.projectHandle)
            .authorizeSourceFile(file.path);
        final start = await api.transfer(fixture.opened.projectHandle,
            verb: 'stage_license', input: {'sourcePath': file.path});
        final done = await waitForJob(api, fixture.opened.projectHandle, start);
        expect((done['snapshot'] as Map)['state'], 'failed');
        expect((done['snapshot'] as Map)['errorCode'],
            'resource_pack.license_invalid_utf8');
        expect(done['result'], isNull);
      }
    } finally {
      await api.closeTransferWorkspace(fixture.opened.workspaceHandle);
      await fixture.dispose();
    }
  });

  test(
      'families and all authors page within the escaped MCP envelope and bind cursors to their section',
      () async {
    final mixed = source.mixedFixture();
    final largeName = '🌲' * 256;
    expect(largeName.length, 512);
    expect(() => CatalogDefinitionSummary(name: '${largeName}x'),
        throwsFormatException);
    final authorNames = [for (var i = 0; i < 3000; i++) 'Auteur $i «"\\ ${'é' * 70}'];
    final original = source.metadata();
    final fixture = await NativeResourcePackImportFixture.create(
      sourceManifest: mixed.$1.copyWith(resourceLibraryCatalog: ResourceLibraryCatalog(families: [ResourceFamily(id: 'long-name', name: largeName)], entries: [ResourceLibraryEntry(resourceKind: 'element', resourceId: 'decor', familyId: 'long-name')])),
      metadata: ResourcePackMetadata(id: original.id, version: original.version, name: original.name, description: original.description, universeId: original.universeId, authors: authorNames, provenance: original.provenance),
    );
    final api = LocalResourcePackTransferApi(mutations: fixture.mutations, snapshotLoader: fixture.loader);
    try {
      final file = File('${fixture.source.directory.path}/attributions.aveluneassets');
      final sink = file.openWrite();
      await fixture.source.archive.withSource((source) => sink.addStream(sourceChunks(source)));
      await sink.close();
      await fixture.mutations.resourcePackPayloadStore(fixture.opened.projectHandle).authorizeSourceFile(file.path);
      Future<Map<String, Object?>> transfer(String verb, Map<String, Object?> input) => api.transfer(fixture.opened.projectHandle, verb: verb, input: input);
      final staged = (await waitForJob(api, fixture.opened.projectHandle, await transfer('stage', {'sourcePath': file.path})))['result']! as Map;
      final inspection = (await waitForJob(api, fixture.opened.projectHandle, await transfer('inspect', {'archiveHandle': staged['archiveHandle']})))['result']! as Map;
      expect(inspection['authorCount'], authorNames.length);
      expect((inspection['pack'] as Map).containsKey('authors'), isFalse);
      final owner = inspection['inspectionHandle'];
      final families = await transfer('entries', {'inspectionHandle': owner, 'section': 'families', 'limit': 50});
      final family = (families['items'] as List).cast<Map>().singleWhere((row) => row['labelComplete'] == false);
      expect(family['labelComplete'], isFalse);
      expect(family['labelLength'], 256);
      expect((family['label'] as String).runes.length, 160);
      final chosen = await transfer('selection.create', {'mode': 'archive', 'inspectionHandle': owner});
      final familySelection = await transfer('selection.select_filtered', {'selectionHandle': chosen['selectionHandle'], 'revision': chosen['revision'], 'filter': {'familyId': family['id']}});
      expect(familySelection['selectedCount'], 1);
      var page = await transfer('entries', {'inspectionHandle': owner, 'section': 'authors', 'limit': 200});
      final firstCursor = page['nextCursor'];
      final authors = <String>[];
      while (true) {
        final envelope = {'content': [{'type': 'text', 'text': jsonEncode({'data': page})}], 'structuredContent': {'data': page}};
        expect(utf8.encode(jsonEncode(envelope)).length, lessThanOrEqualTo(256 * 1024));
        expect((page['items'] as List).length, lessThanOrEqualTo(200));
        authors.addAll((page['items'] as List).map((row) => (row as Map)['label'] as String));
        if (page['nextCursor'] == null) break;
        page = await transfer('entries', {'inspectionHandle': owner, 'section': 'authors', 'limit': 200, 'cursor': page['nextCursor']});
      }
      expect(authors, authorNames);
      await expectLater(transfer('entries', {'inspectionHandle': owner, 'section': 'families', 'cursor': firstCursor}), throwsA(isA<ResourcePackTransferException>()));
    } finally { await api.closeTransferWorkspace(fixture.opened.workspaceHandle); await fixture.dispose(); }
  });
  test('release preview invalidates its cursor and preserves other previews and selection', () async {
    final fixture = await NativeResourcePackImportFixture.create();
    final api = LocalResourcePackTransferApi(
      mutations: fixture.mutations,
      snapshotLoader: fixture.loader,
    );
    try {
      final file = File(
        '${fixture.source.directory.path}/preview.aveluneassets',
      );
      final sink = file.openWrite();
      await fixture.source.archive.withSource(
        (source) => sink.addStream(sourceChunks(source)),
      );
      await sink.close();
      await fixture.mutations
          .resourcePackPayloadStore(fixture.opened.projectHandle)
          .authorizeSourceFile(file.path);
      Future<Map> job(String verb, Map<String, Object?> input) async =>
          (await waitForJob(
                api,
                fixture.opened.projectHandle,
                await api.transfer(
                  fixture.opened.projectHandle,
                  verb: verb,
                  input: input,
                ),
              ))['result']!
              as Map;
      final archive = await job('stage', {'sourcePath': file.path});
      final inspected = await job('inspect', {
        'archiveHandle': archive['archiveHandle'],
      });
      expect((inspected['pack'] as Map)['name'], isA<String>());
      expect(inspected['archiveBytes'], await file.length());
      expect(inspected['authorCount'], greaterThan(0));
      final authors = await api.transfer(fixture.opened.projectHandle, verb: 'entries', input: {'inspectionHandle': inspected['inspectionHandle'], 'section': 'authors', 'limit': 1});
      expect((authors['items'] as List).single, containsPair('kind', 'author'));
      final families = await api.transfer(fixture.opened.projectHandle, verb: 'entries', input: {'inspectionHandle': inspected['inspectionHandle'], 'section': 'families', 'limit': 1});
      expect((families['items'] as List).length, lessThanOrEqualTo(1));
      var selection = await api.transfer(
        fixture.opened.projectHandle,
        verb: 'selection.create',
        input: {
          'mode': 'archive',
          'inspectionHandle': inspected['inspectionHandle'],
        },
      );
      selection = await api.transfer(
        fixture.opened.projectHandle,
        verb: 'selection.select_filtered',
        input: {
          'selectionHandle': selection['selectionHandle'],
          'revision': selection['revision'],
          'filter': <String, Object?>{},
        },
      );
      final input = {
        'selectionHandle': selection['selectionHandle'],
        'revision': selection['revision'],
        'expectedRevision': (await fixture.loader.load(
          fixture.opened.projectHandle,
        )).revision,
      };
      final first = await job('prepare', input);
      final summary = first['summary'] as Map;
      expect(summary['selectedResourceCount'], selection['selectedCount']);
      expect(summary['sourceBytes'], greaterThan(0));
      expect(summary['writeBytes'], greaterThan(0));
      expect(summary['createdDefinitionCount'], summary['definitionCount']);
      expect(summary['copiedDefinitionCount'], 0);
      final second = await job('prepare', input);
      final page = await api.transfer(
        fixture.opened.projectHandle,
        verb: 'preview',
        input: {'previewHandle': first['previewHandle'], 'limit': 1},
      );
      expect(page['nextCursor'], isNotNull);
      expect(((page['items'] as List).first as Map)['label'], isA<String>());
      expect(((page['items'] as List).first as Map)['requiredByLabel'], isA<String>());
      expect(
        await api.transfer(
          fixture.opened.projectHandle,
          verb: 'release',
          input: {'handle': first['previewHandle']},
        ),
        {'released': true},
      );
      await expectLater(
        api.transfer(
          fixture.opened.projectHandle,
          verb: 'preview',
          input: {
            'previewHandle': first['previewHandle'],
            'cursor': page['nextCursor'],
          },
        ),
        throwsA(isA<ResourcePackTransferException>()),
      );
      await expectLater(
        api.queryTransfer(
          fixture.opened.projectHandle,
          AuthoringQueryRequest(
            operation: AuthoringQueryOperation.get,
            resourceKind: 'resourcePackPreview',
            ids: [first['previewHandle']! as String],
          ),
        ),
        throwsA(isA<ResourcePackTransferException>()),
      );
      final retainedPreview = await api.transfer(
        fixture.opened.projectHandle,
        verb: 'preview',
        input: {'previewHandle': second['previewHandle']},
      );
      final sourceCatalog = fixture.source.archive.inspection.catalog.toJson();
      final sourceBorder = ((sourceCatalog['borderCatalog'] as Map)['records']
              as List)
          .single as Map;
      expect(sourceBorder['draft'], isNull);
      final publishedName =
          ((sourceBorder['latestPublished'] as Map)['definition'] as Map)['name'];
      expect(publishedName, 'Original border');
      final borderRow = (retainedPreview['items'] as List).cast<Map>().singleWhere(
          (row) => row['kind'] == 'borderBlueprint');
      expect(borderRow['selected'], isTrue);
      expect(borderRow['label'], publishedName);
      expect(borderRow['requiredByLabel'], publishedName);
      expect(
        (await api.transfer(
          fixture.opened.projectHandle,
          verb: 'entries',
          input: {'selectionHandle': selection['selectionHandle']},
        ))['items'],
        isNotEmpty,
      );
    } finally {
      await api.closeTransferWorkspace(fixture.opened.workspaceHandle);
      await fixture.dispose();
    }
  });
  test('pack start_apply rejects an ordinary plan before writing while canonical ordinary apply remains available', () async {
    final fixture = await NativeResourcePackImportFixture.create(target: ProjectManifest(
        name: 'Ordinary budget', maps: [], tilesets: [], settings: ProjectSettings(tileWidth: 2, tileHeight: 2),
        resourceLibraryCatalog: ResourceLibraryCatalog(families: [ResourceFamily(id: 'existing', name: 'x' * 124000)])));
    final api = LocalResourcePackTransferApi(mutations: fixture.mutations, snapshotLoader: fixture.loader);
    try {
      final before = await File('${fixture.root.path}/project.json').readAsBytes();
      final snapshot = await fixture.loader.load(fixture.opened.projectHandle);
      final plan = await fixture.mutations.planMutation(fixture.opened.projectHandle,
          AuthoringRequest(requestId: 'ordinary-budget', actionId: 'resource.family.create', actionVersion: 1,
              workspaceHandle: fixture.opened.workspaceHandle.value, expectedRevision: snapshot.revision,
              idempotencyKey: 'ordinary-budget', parameters: {'familyId': 'new-family', 'name': 'Ordinary'}));
      final start = await api.transfer(fixture.opened.projectHandle, verb: 'start_apply',
          input: {'planId': plan.planId, 'operationId': 'ordinary-budget'});
      expect((start['snapshot'] as Map)['state'], 'queued');
      final refused = await waitForJob(api, fixture.opened.projectHandle, start);
      expect((refused['snapshot'] as Map)['state'], 'failed');
      expect((refused['snapshot'] as Map)['errorCode'], 'resource_pack.plan_kind_invalid');
      expect(refused['phase'], 'failed');
      expect(await File('${fixture.root.path}/project.json').readAsBytes(), before);
      expect((await fixture.loader.load(fixture.opened.projectHandle)).manifest.resourceLibraryCatalog.families
          .any((family) => family.id == 'new-family'), false);
      final ordinary = await fixture.mutations.applyMutation(fixture.opened.projectHandle,
          planId: plan.planId, operationId: 'ordinary-budget');
      expect(ordinary.receipt.status, AuthoringReceiptStatus.applied);
      expect((await fixture.loader.load(fixture.opened.projectHandle)).manifest.resourceLibraryCatalog.families
          .any((family) => family.id == 'new-family'), true);
    } finally {
      await api.closeTransferWorkspace(fixture.opened.workspaceHandle);
      await fixture.dispose();
    }
  });

  test(
    'stages on disk then inspects in the P04 worker while returning job IDs',
    () async {
      final fixture = await NativeResourcePackImportFixture.create();
      final port = ReceivePort();
      final observed = port.first;
      final api = LocalResourcePackTransferApi(
        mutations: fixture.mutations,
        snapshotLoader: fixture.loader,
        inspectSource: _observer(port.sendPort),
      );
      try {
        final path = '${fixture.source.directory.path}/source.aveluneassets';
        final sink = File(path).openWrite();
        await fixture.source.archive.withSource((source) async {
          await sink.addStream(sourceChunks(source));
        });
        await sink.close();
        final store = fixture.mutations.resourcePackPayloadStore(
          fixture.opened.projectHandle,
        );
        final rejected = await api.transfer(
          fixture.opened.projectHandle,
          verb: 'stage',
          input: {'sourcePath': path},
        );
        final denied = await waitForJob(
          api,
          fixture.opened.projectHandle,
          rejected,
        );
        expect(
          (denied['snapshot'] as Map)['errorCode'],
          'resource_pack.source_outside_allowed_roots',
        );
        await store.authorizeSourceFile(path);
        final start = await api.transfer(
          fixture.opened.projectHandle,
          verb: 'stage',
          input: {'sourcePath': path},
        );
        expect((start['snapshot'] as Map)['state'], 'queued');
        expect(
          ((start['snapshot'] as Map)['request'] as Map)['input'],
          isEmpty,
        );
        final staged = await waitForJob(
          api,
          fixture.opened.projectHandle,
          start,
        );
        expect((staged['snapshot'] as Map)['state'], 'succeeded');
        final inspect = await api.transfer(
          fixture.opened.projectHandle,
          verb: 'inspect',
          input: {'archiveHandle': (staged['result'] as Map)['archiveHandle']},
        );
        expect((inspect['snapshot'] as Map)['state'], 'queued');
        expect(await observed, isNot(Isolate.current.hashCode));
        final inspected = await waitForJob(
          api,
          fixture.opened.projectHandle,
          inspect,
        );
        expect((inspected['snapshot'] as Map)['state'], 'succeeded');
        expect((inspected['result'] as Map)['fileCount'], greaterThan(0));
        final result = inspected['result'] as Map;
        final selected = await api.transfer(
          fixture.opened.projectHandle,
          verb: 'selection.create',
          input: {
            'mode': 'archive',
            'inspectionHandle': result['inspectionHandle'],
          },
        );
        final chosen = await api.transfer(
          fixture.opened.projectHandle,
          verb: 'selection.select_filtered',
          input: {
            'selectionHandle': selected['selectionHandle'],
            'revision': selected['revision'],
            'filter': {'kind': 'element'},
          },
        );
        expect(chosen['selectedCount'], greaterThan(0));
        final hidden = await api.transfer(
          fixture.opened.projectHandle,
          verb: 'entries',
          input: {
            'selectionHandle': selected['selectionHandle'],
            'filter': {'kind': 'model3d'},
          },
        );
        expect(
          (hidden['items'] as List).every(
            (row) => (row as Map)['selected'] == false,
          ),
          isTrue,
        );
        final prepare = await api.transfer(
          fixture.opened.projectHandle,
          verb: 'prepare',
          input: {
            'selectionHandle': chosen['selectionHandle'],
            'revision': chosen['revision'],
            'expectedRevision': (await fixture.loader.load(
              fixture.opened.projectHandle,
            )).revision,
          },
        );
        final prepared = await waitForJob(
          api,
          fixture.opened.projectHandle,
          prepare,
        );
        expect(
          (prepared['snapshot'] as Map)['state'],
          'succeeded',
          reason: prepared.toString(),
        );
        final details = prepared['result'] as Map;
        final plan = await fixture.mutations.planMutation(
          fixture.opened.projectHandle,
          AuthoringRequest(
            requestId: 'p09-plan',
            actionId: 'resource_pack.import',
            actionVersion: 1,
            workspaceHandle: fixture.opened.workspaceHandle.value,
            expectedRevision: (await fixture.loader.load(
              fixture.opened.projectHandle,
            )).revision,
            idempotencyKey: 'p09-import',
            parameters: {
              'preparedImportHandle': details['preparedImportHandle'],
            },
          ),
        );
        final apply = await api.transfer(
          fixture.opened.projectHandle,
          verb: 'start_apply',
          input: {'planId': plan.planId, 'operationId': 'p09-operation'},
        );
        final applied = await waitForJob(
          api,
          fixture.opened.projectHandle,
          apply,
        );
        expect(
          (applied['snapshot'] as Map)['state'],
          'succeeded',
          reason: applied.toString(),
        );
        final receipt =
            ((applied['result'] as Map)['receipt'] as Map)['receiptId'];
        final undoStart = await api.transfer(
          fixture.opened.projectHandle,
          verb: 'start_history',
          input: {
            'operation': 'undo',
            'entryId': receipt,
            'operationId': 'p09-undo',
            'expectedRevision': (await fixture.loader.load(
              fixture.opened.projectHandle,
            )).revision,
          },
        );
        final undone = await waitForJob(
          api,
          fixture.opened.projectHandle,
          undoStart,
        );
        expect(
          (undone['snapshot'] as Map)['state'],
          'succeeded',
          reason: undone.toString(),
        );
        final redo = await api.transfer(
          fixture.opened.projectHandle,
          verb: 'start_history',
          input: {
            'operation': 'redo',
            'entryId': receipt,
            'operationId': 'p09-redo',
            'expectedRevision': (await fixture.loader.load(
              fixture.opened.projectHandle,
            )).revision,
          },
        );
        final redone = await waitForJob(
          api,
          fixture.opened.projectHandle,
          redo,
        );
        expect(
          (redone['snapshot'] as Map)['state'],
          'succeeded',
          reason: redone.toString(),
        );
        final native = await api.transfer(
          fixture.opened.projectHandle,
          verb: 'selection.create',
          input: {'mode': 'native'},
        );
        final nativeChosen = await api.transfer(
          fixture.opened.projectHandle,
          verb: 'selection.select_filtered',
          input: {
            'selectionHandle': native['selectionHandle'],
            'revision': native['revision'],
            'filter': {'kind': 'element'},
          },
        );
        final prepareExport = await api.transfer(
          fixture.opened.projectHandle,
          verb: 'prepare',
          input: {
            'selectionHandle': nativeChosen['selectionHandle'],
            'revision': nativeChosen['revision'],
            'expectedRevision': native['sourceRevision'],
            'metadata': fixture.source.archive.inspection.manifest.pack
                .toJson(),
            'author': 'Fixture',
          },
        );
        final preparedExport =
            await waitForJob(api, fixture.opened.projectHandle, prepareExport);
        final export = await api
            .transfer(fixture.opened.projectHandle, verb: 'export', input: {
          'acknowledgeOrganizationRemoval': true,
          'preparedExportHandle':
              (preparedExport['result'] as Map)['preparedExportHandle']
        });
        final exported = await waitForJob(
          api,
          fixture.opened.projectHandle,
          export,
        );
        expect(
          (exported['snapshot'] as Map)['state'],
          'succeeded',
          reason: exported.toString(),
        );
        final payload = (exported['result'] as Map)['payloadRef'];
        final chunk = await api.transfer(
          fixture.opened.projectHandle,
          verb: 'read_payload',
          input: {'payloadRef': payload, 'offset': 0, 'length': 128 * 1024},
        );
        expect(chunk['totalBytes'], greaterThan(0));
        final queried = await api.queryTransfer(
          fixture.opened.projectHandle,
          AuthoringQueryRequest(
            resourceKind: 'resourcePackInspection',
            operation: AuthoringQueryOperation.get,
            ids: [result['inspectionHandle'] as String],
          ),
        );
        expect((queried['items'] as List).length, 1);
        final reverted = await waitForJob(
          api,
          fixture.opened.projectHandle,
          await api.transfer(
            fixture.opened.projectHandle,
            verb: 'start_history',
            input: {
              'operation': 'revert',
              'entryId':
                  ((undone['result'] as Map)['receipt'] as Map)['receiptId'],
              'expectedHeadEntryId':
                  ((redone['result'] as Map)['receipt'] as Map)['receiptId'],
              'operationId': 'p09-revert',
              'expectedRevision': (await fixture.loader.load(
                fixture.opened.projectHandle,
              )).revision,
            },
          ),
        );
        expect(
          (reverted['snapshot'] as Map)['state'],
          'succeeded',
          reason: reverted.toString(),
        );
      } finally {
        port.close();
        await api.closeTransferWorkspace(fixture.opened.workspaceHandle);
        await fixture.dispose();
      }
    },
  );
}

Future<Map<String, Object?>> waitForJob(
  LocalResourcePackTransferApi api,
  ProjectHandle project,
  Map<String, Object?> start,
) async {
  final deadline = DateTime.now().add(Duration(seconds: 20));
  while (DateTime.now().isBefore(deadline)) {
    final state = await api.transfer(
      project,
      verb: 'get',
      input: {'jobId': start['jobId']},
    );
    if (const [
      'succeeded',
      'failed',
      'cancelled',
    ].contains((state['snapshot'] as Map)['state'])) {
      return state;
    }
    await Future<void>.delayed(Duration(milliseconds: 1));
  }
  throw StateError('Job did not finish.');
}

ResourcePackInspection Function(RandomAccessPackageSource) _observer(
  SendPort port,
) =>
    (source) {
      port.send(Isolate.current.hashCode);
      return const ResourcePackInspector().inspectSourceSync(source);
    };

final class _PackBytesSource implements RandomAccessPackageSource {
  _PackBytesSource(this.bytes);
  final Uint8List bytes;
  @override
  int get length => bytes.length;
  @override
  Uint8List readAtSync(int offset, int length) =>
      Uint8List.sublistView(bytes, offset, offset + length);
}

Object? _privateField(Object value, String name) {
  final mirror = reflect(value);
  return mirror
      .getField(
          MirrorSystem.getSymbol(name, mirror.type.owner as LibraryMirror))
      .reflectee;
}
