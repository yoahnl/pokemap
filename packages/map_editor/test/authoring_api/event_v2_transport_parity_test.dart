import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/editor_receipt_presenter.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';

void main() {
  test(
    'Editor adapter executes the shared nine-action Event V2 contract',
    () async {
      final data =
          jsonDecode(
                File(
                  '../map_authoring/test/fixtures/event_v2_transport_parity.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final root = await Directory.systemTemp.createTemp(
        'editor-event-v2-parity-',
      );
      final manifest = File('${root.path}/project.json');
      await manifest.writeAsString(jsonEncode(data['project']));
      for (final map in (data['maps'] as List).cast<Map>()) {
        final file = File('${root.path}/${map['relativePath']}');
        await file.parent.create(recursive: true);
        await file.writeAsString(jsonEncode(map['content']));
      }
      final map = File('${root.path}/maps/port.json');
      final mapBefore = await map.readAsBytes();
      final initial = ProjectManifest.fromJson(
        data['project'] as Map<String, dynamic>,
      );
      const reader = EditorProjectFileReader();
      var queries = AuthoringQueryAdapter(fileReader: reader);
      var mutations = AuthoringMutationAdapter(
        fileReader: reader,
        queries: queries,
        projectRoots: reader,
      );
      addTearDown(() async {
        await mutations.closeAll();
        await queries.closeAll();
        await root.delete(recursive: true);
      });
      var sequence = 0;
      Future<EditorAuthoringMutationPlan> plan(Map operation) => mutations.plan(
        root.path,
        actionId: operation['actionId'] as String,
        parameters: Map<String, Object?>.from(operation['parameters'] as Map),
        idempotencyKey: 'event-v2-plan-${sequence++}',
      );

      Future<void> refuses(Future<Object?> Function() run, String code) async {
        await expectLater(
          run(),
          throwsA(
            isA<EditorAuthoringMutationFailure>().having(
              (error) => error.code,
              'code',
              code,
            ),
          ),
        );
      }

      Future<void> verify(Map registry) async {
        final current = ProjectManifest.fromJson(
          jsonDecode(await manifest.readAsString()) as Map<String, dynamic>,
        );
        expect(current.eventRegistry!.toJson(), registry);
        expect(current.copyWith(eventRegistry: initial.eventRegistry), initial);
        expect(await map.readAsBytes(), mapBefore);
        final session = await queries.open(root.path);
        final result = await session.queryAsync(
          AuthoringQueryRequest(
            resourceKind: 'eventV2',
            operation: AuthoringQueryOperation.list,
            view: AuthoringQueryView.detail,
          ),
        );
        expect(
          {
            for (final raw in (result['items'] as List).cast<Map>())
              raw['id']: {
                'state': raw['state'],
                if (raw['state'] == 'draft')
                  'draft': raw['draft']
                else ...{
                  'definition': raw['definition'],
                  'enabled': raw['enabled'],
                  if (raw.containsKey('activeInLegacyMode'))
                    'activeInLegacyMode': raw['activeInLegacyMode'],
                },
              },
          },
          {
            for (final raw in (registry['records'] as List).cast<Map>())
              ((raw['definition'] ?? raw['draft']) as Map)['id']: raw,
          },
        );
      }

      Future<void> refusals(String after) async {
        for (final invalid in (data['refusals'] as List).cast<Map>().where(
          (entry) => entry['afterOperation'] == after,
        )) {
          final before = await manifest.readAsBytes();
          await refuses(() => plan(invalid), invalid['domainCode'] as String);
          expect(
            await manifest.readAsBytes(),
            before,
            reason: invalid['id'] as String,
          );
          expect(await map.readAsBytes(), mapBefore);
        }
      }

      final beforeBound = await manifest.readAsBytes();
      final accepted = await plan({
        'actionId': 'event_v2.record_upsert_batch',
        'parameters': {'records': data['acceptedBatch']},
      });
      expect(accepted.preview['recordIds'], hasLength(128));
      expect(await manifest.readAsBytes(), beforeBound);
      await refusals('initial');
      for (final operation in (data['operations'] as List).cast<Map>()) {
        final before = await manifest.readAsBytes();
        final beforeRegistry =
            (jsonDecode(utf8.decode(before)) as Map)['eventRegistry'] as Map;
        final planned = await plan(operation);
        expect(await manifest.readAsBytes(), before);
        final stale = operation['id'] == 'batch' ? await plan(operation) : null;
        String? confirmation;
        if (operation['confirmation'] == true) {
          await refuses(
            () => mutations.apply(
              planned,
              operationId: 'unconfirmed-${sequence++}',
            ),
            data['confirmationDomainCode'] as String,
          );
          expect(await manifest.readAsBytes(), before);
          confirmation = await mutations.confirm(planned);
        }
        final operationId = 'event-v2-apply-${sequence++}';
        final applied = await mutations.apply(
          planned,
          operationId: operationId,
          confirmationToken: confirmation,
        );
        final committed = await manifest.readAsBytes();
        final replay = await mutations.apply(
          planned,
          operationId: operationId,
          confirmationToken: confirmation,
        );
        expect(replay.receipt.toJson(), applied.receipt.toJson());
        expect(await manifest.readAsBytes(), committed);
        await verify(operation['expectedRegistry'] as Map);
        if (stale != null) {
          await refuses(
            () => mutations.apply(stale, operationId: 'stale-${sequence++}'),
            data['staleDomainCode'] as String,
          );
          expect(await manifest.readAsBytes(), committed);
        }
        if (operation['id'] == 'batch' || operation['id'] == 'delete') {
          expect(applied.receipt.actionId, operation['actionId']);
          await mutations.undo(
            root.path,
            entryId: applied.receipt.receiptId,
            idempotencyKey: 'undo-${sequence++}',
          );
          expect(await manifest.readAsBytes(), before);
          await verify(beforeRegistry);
          final restored = await plan(operation);
          await mutations.apply(
            restored,
            operationId: 'restored-${sequence++}',
            confirmationToken: operation['confirmation'] == true
                ? await mutations.confirm(restored)
                : null,
          );
          await verify(operation['expectedRegistry'] as Map);
        }
        await refusals(operation['id'] as String);
      }
      await mutations.closeAll();
      await queries.closeAll();
      queries = AuthoringQueryAdapter(fileReader: reader);
      mutations = AuthoringMutationAdapter(
        fileReader: reader,
        queries: queries,
        projectRoots: reader,
      );
      await verify(
        ((data['operations'] as List).last as Map)['expectedRegistry'] as Map,
      );
    },
  );
}
