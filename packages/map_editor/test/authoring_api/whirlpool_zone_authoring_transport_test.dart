import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/editor_receipt_presenter.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';

void main() {
  test(
    'Editor canonical adapter queries, refuses, undoes and cold reopens the same Whirlpool fixture',
    () async {
      final root = await Directory.systemTemp.createTemp('editor-whirlpool-');
      addTearDown(() => root.delete(recursive: true));
      final zone = MapGameplayZone.fromJson(
        jsonDecode(
              File(
                '../map_core/test/fixtures/whirlpool_field_zone.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>,
      );
      final seed = zone.copyWith(
        fieldAction: const FieldActionZonePayload(
          actionKind: FieldActionZoneKind.darkness,
          darkness: DarknessZonePayload(opacity: .7),
        ),
      );
      final payload =
          jsonDecode(jsonEncode(zone.fieldAction!.toJson()))
              as Map<String, dynamic>;
      final route = payload['whirlpool'] as Map<String, dynamic>;
      final initial = MapData(
        id: 'whirls',
        name: 'Tourbillon',
        size: const GridSize(width: 8, height: 8),
        gameplayZones: [
          const MapGameplayZone(
            id: 'water',
            kind: GameplayZoneKind.movement,
            area: MapRect(
              pos: GridPos(x: 0, y: 0),
              size: GridSize(width: 8, height: 8),
            ),
            movement: MovementZonePayload(requiredMode: MovementMode.surf),
          ),
          seed,
        ],
      );
      final file = File('${root.path}/whirls.json');
      await file.writeAsString(jsonEncode(initial.toJson()));
      await File('${root.path}/project.json').writeAsString(
        jsonEncode(
          const ProjectManifest(
            name: 'Tourbillon',
            tilesets: [],
            maps: [
              ProjectMapEntry(
                id: 'whirls',
                name: 'Tourbillon',
                relativePath: 'whirls.json',
              ),
            ],
          ).toJson(),
        ),
      );
      const reader = EditorProjectFileReader();
      final queries = AuthoringQueryAdapter(fileReader: reader);
      final mutations = AuthoringMutationAdapter(
        fileReader: reader,
        queries: queries,
        projectRoots: reader,
      );
      addTearDown(mutations.closeAll);
      addTearDown(queries.closeAll);
      final revision = (await queries.open(root.path)).snapshotRevision;
      final before = await file.readAsBytes();
      final plan = await mutations.plan(
        root.path,
        actionId: 'gameplay_zone.set_field_action_payload',
        parameters: {'mapId': 'whirls', 'zoneId': zone.id, 'payload': payload},
        idempotencyKey: 'set-whirlpool',
        expectedRevision: revision,
      );
      expect(await file.readAsBytes(), before);
      final applied = await mutations.apply(plan, operationId: 'set-whirlpool');
      final expected = initial.copyWith(
        gameplayZones: [initial.gameplayZones.first, zone],
      );
      expect((await queries.open(root.path)).mapById('whirls'), expected);
      final stable = await file.readAsBytes();
      for (final invalidPayload in [
        {
          'actionKind': 'whirlpool',
          'whirlpool': {...route, 'requiresSurf': false},
        },
        {
          'actionKind': 'whirlpool',
          'whirlpool': {...route, 'path': []},
        },
      ]) {
        await expectLater(
          mutations.plan(
            root.path,
            actionId: 'gameplay_zone.set_field_action_payload',
            parameters: {
              'mapId': 'whirls',
              'zoneId': zone.id,
              'payload': invalidPayload,
            },
            idempotencyKey: 'invalid-${invalidPayload.hashCode}',
          ),
          throwsA(isA<EditorAuthoringMutationFailure>()),
        );
        expect(await file.readAsBytes(), stable);
      }
      await expectLater(
        mutations.plan(
          root.path,
          actionId: 'gameplay_zone.set_field_action_payload',
          parameters: {
            'mapId': 'whirls',
            'zoneId': zone.id,
            'payload': seed.fieldAction!.toJson(),
          },
          idempotencyKey: 'stale',
          expectedRevision: revision,
        ),
        throwsA(
          isA<EditorAuthoringMutationFailure>().having(
            (error) => error.code,
            'code',
            'plan.stale',
          ),
        ),
      );
      await mutations.undo(
        root.path,
        entryId: applied.receipt.receiptId,
        idempotencyKey: 'undo-whirlpool',
      );
      expect((await queries.open(root.path)).mapById('whirls'), initial);
      final restored = await mutations.plan(
        root.path,
        actionId: 'gameplay_zone.set_field_action_payload',
        parameters: {'mapId': 'whirls', 'zoneId': zone.id, 'payload': payload},
        idempotencyKey: 'restore',
      );
      await mutations.apply(restored, operationId: 'restore');
      await mutations.closeAll();
      await queries.closeAll();
      final cold = AuthoringQueryAdapter(fileReader: reader);
      addTearDown(cold.closeAll);
      expect((await cold.open(root.path)).mapById('whirls'), expected);
    },
  );
}
