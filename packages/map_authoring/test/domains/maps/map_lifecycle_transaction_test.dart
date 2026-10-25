import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'map_catalog_fixture.dart';

void main() {
  group('LocalMapAuthoringMutationApi lifecycle', () {
    test('delete then recreate the same identity does not inherit editor locks',
        () async {
      final setup = await _Setup.create(
          maps: [catalogMap('source')], enableSnapshotCache: true);
      addTearDown(setup.dispose);
      final source = File('${setup.root.path}/maps/source.editor.json');
      await source.writeAsString(jsonEncode(MapEditorDocument(
          mapId: 'source',
          state: MapEditorState(lockedElements: {'layer:base'})).toJson()));
      final deletion = await setup.mutations.plan(
          setup.projectHandle,
          await setup.requestAsync(
              actionId: 'map.delete_apply', parameters: {'mapId': 'source'}));
      final confirmation = await setup.mutations
          .confirm(setup.projectHandle, planId: deletion['planId']! as String);
      await setup.mutations.apply(setup.projectHandle,
          planId: deletion['planId']! as String,
          operationId: 'delete_editor',
          confirmationToken: confirmation['confirmationToken']! as String);
      expect(await source.exists(), isFalse);
      final creation = await setup.mutations.plan(
          setup.projectHandle,
          await setup.requestAsync(
              actionId: 'map.create',
              parameters: {'mapId': 'source', 'width': 3, 'height': 3}));
      await setup.mutations.apply(setup.projectHandle,
          planId: creation['planId']! as String,
          operationId: 'recreate_editor');
      final reopened = await setup.mutations
          .inspectMapEditor(projectRoot: setup.root.path, mapId: 'source');
      expect(reopened.state, MapEditorState());
      expect(await source.exists(), isFalse);
    });
    test(
        'create preserves an orphan future editor document and refuses its identity',
        () async {
      final setup = await _Setup.create();
      addTearDown(setup.dispose);
      final orphan = File('${setup.root.path}/maps/orphan.editor.json');
      await orphan.parent.create(recursive: true);
      await orphan
          .writeAsString('{"schemaVersion":2,"mapId":"orphan","future":true}');
      final before = await orphan.readAsBytes();
      await expectLater(
          setup.mutations.plan(
              setup.projectHandle,
              await setup.requestAsync(
                  actionId: 'map.create',
                  parameters: {'mapId': 'orphan', 'width': 3, 'height': 3})),
          throwsA(isA<MapAuthoringException>()));
      expect(await orphan.readAsBytes(), before);
      expect(
          await File('${setup.root.path}/maps/orphan.json').exists(), isFalse);
    });
    for (final initiallyPresent in [false, true]) {
      test(
          'duplicate guards editor source when initially present=$initiallyPresent',
          () async {
        final setup = await _Setup.create(
            maps: [catalogMap('source')], enableSnapshotCache: true);
        addTearDown(setup.dispose);
        final source = File('${setup.root.path}/maps/source.editor.json');
        if (initiallyPresent) {
          await source.writeAsString(jsonEncode(
              MapEditorDocument(mapId: 'source', state: MapEditorState())
                  .toJson()));
        }
        final plan = await setup.mutations.plan(
            setup.projectHandle,
            await setup.requestAsync(actionId: 'map.duplicate', parameters: {
              'sourceMapId': 'source',
              'targetMapId': 'target'
            }));
        await source.writeAsString(jsonEncode(MapEditorDocument(
            mapId: 'source',
            state: MapEditorState(lockedFamilies: {'model'})).toJson()));
        final changed = await source.readAsBytes();
        await expectLater(
            setup.mutations.apply(setup.projectHandle,
                planId: plan['planId']! as String,
                operationId: 'editor_source_race'),
            throwsA(isA<MapAuthoringException>()));
        expect(await source.readAsBytes(), changed);
        expect(await File('${setup.root.path}/maps/target.json').exists(),
            isFalse);
        expect(
            await File('${setup.root.path}/maps/target.editor.json').exists(),
            isFalse);
      });
    }
    for (final action in ['map.duplicate', 'map.rename', 'map.delete_apply']) {
      test('$action carries editor in the same transaction and undo', () async {
        final setup = await _Setup.create(
            maps: [catalogMap('source')], enableSnapshotCache: true);
        addTearDown(setup.dispose);
        final source = File('${setup.root.path}/maps/source.editor.json');
        final settings = MapEditorState(
            lockedElements: {'layer:base'}, lockedFamilies: {'model'});
        await source.writeAsString(jsonEncode(
            MapEditorDocument(mapId: 'source', state: settings).toJson()));
        final before = await source.readAsBytes();
        final parameters = <String, Object?>{
          if (action == 'map.duplicate') ...{
            'sourceMapId': 'source',
            'targetMapId': 'target'
          } else ...{
            'mapId': 'source'
          },
          if (action == 'map.rename') 'newMapId': 'target',
        };
        final plan = await setup.mutations.plan(setup.projectHandle,
            await setup.requestAsync(actionId: action, parameters: parameters));
        final confirmation = action == 'map.delete_apply'
            ? await setup.mutations
                .confirm(setup.projectHandle, planId: plan['planId']! as String)
            : null;
        final applied = await setup.mutations.apply(setup.projectHandle,
            planId: plan['planId']! as String,
            operationId: 'editor_lifecycle',
            confirmationToken: confirmation?['confirmationToken'] as String?);
        if (action != 'map.delete_apply') {
          final target = File('${setup.root.path}/maps/target.editor.json');
          expect(await target.exists(), isTrue);
          final document = MapEditorDocument.fromJson(
              jsonDecode(await target.readAsString()));
          expect(document.mapId, 'target');
          expect(document.state, settings);
        }
        expect(await source.exists(), action == 'map.duplicate');
        final receipt = applied['receipt']! as Map<String, Object?>;
        await setup.mutations.undo(setup.projectHandle,
            entryId: receipt['receiptId']! as String,
            idempotencyKey: 'undo_editor_lifecycle');
        expect(await source.readAsBytes(), before);
        expect(
            await File('${setup.root.path}/maps/target.editor.json').exists(),
            isFalse);
      });
    }
    for (final action in ['map.duplicate', 'map.rename', 'map.delete_apply']) {
      test('$action carries atmosphere in the same transaction and undo',
          () async {
        final setup = await _Setup.create(
            maps: [catalogMap('source')], enableSnapshotCache: true);
        addTearDown(setup.dispose);
        final source = File('${setup.root.path}/maps/source.atmosphere.json');
        final settings = SpatialAtmosphereSettings(
            waterAnimated: true,
            windowsLit: true,
            fireflies: true,
            windowStrength: .7);
        await source.writeAsString(jsonEncode(
            SpatialAtmosphereDocument(mapId: 'source', settings: settings)
                .toJson()));
        final before = await source.readAsBytes();
        final parameters = <String, Object?>{
          if (action == 'map.duplicate') ...{
            'sourceMapId': 'source',
            'targetMapId': 'target'
          } else ...{
            'mapId': 'source'
          },
          if (action == 'map.rename') 'newMapId': 'target',
        };
        final plan = await setup.mutations.plan(setup.projectHandle,
            await setup.requestAsync(actionId: action, parameters: parameters));
        final confirmation = action == 'map.delete_apply'
            ? await setup.mutations
                .confirm(setup.projectHandle, planId: plan['planId']! as String)
            : null;
        final applied = await setup.mutations.apply(setup.projectHandle,
            planId: plan['planId']! as String,
            operationId: 'atmosphere_lifecycle',
            confirmationToken: confirmation?['confirmationToken'] as String?);
        if (action != 'map.delete_apply') {
          final target = File('${setup.root.path}/maps/target.atmosphere.json');
          expect(await target.exists(), isTrue);
          final document = SpatialAtmosphereDocument.fromJson(
              jsonDecode(await target.readAsString()));
          expect(document.mapId, 'target');
          expect(document.settings, settings);
        }
        expect(await source.exists(), action == 'map.duplicate');
        final receipt = applied['receipt']! as Map<String, Object?>;
        await setup.mutations.undo(setup.projectHandle,
            entryId: receipt['receiptId']! as String,
            idempotencyKey: 'undo_atmosphere_lifecycle');
        expect(await source.readAsBytes(), before);
        expect(
            await File('${setup.root.path}/maps/target.atmosphere.json')
                .exists(),
            isFalse);
      });
    }
    for (final action in ['map.duplicate', 'map.rename', 'map.delete_apply']) {
      test(
          '$action refuses a concurrent atmosphere edit without changing either map',
          () async {
        final setup = await _Setup.create(
            maps: [catalogMap('source')], enableSnapshotCache: true);
        addTearDown(setup.dispose);
        final source = File('${setup.root.path}/maps/source.atmosphere.json');
        await source.writeAsString(jsonEncode(SpatialAtmosphereDocument(
                mapId: 'source',
                settings: SpatialAtmosphereSettings(fireflies: true))
            .toJson()));
        final parameters = <String, Object?>{
          if (action == 'map.duplicate') ...{
            'sourceMapId': 'source',
            'targetMapId': 'target'
          } else ...{
            'mapId': 'source'
          },
          if (action == 'map.rename') 'newMapId': 'target',
        };
        final plan = await setup.mutations.plan(setup.projectHandle,
            await setup.requestAsync(actionId: action, parameters: parameters));
        final confirmation = action == 'map.delete_apply'
            ? await setup.mutations
                .confirm(setup.projectHandle, planId: plan['planId']! as String)
            : null;
        await source.writeAsString(jsonEncode(SpatialAtmosphereDocument(
                mapId: 'source',
                settings: SpatialAtmosphereSettings(waterAnimated: true))
            .toJson()));
        final changed = await source.readAsBytes();
        await expectLater(
            setup.mutations.apply(setup.projectHandle,
                planId: plan['planId']! as String,
                operationId: 'atmosphere_present_race',
                confirmationToken:
                    confirmation?['confirmationToken'] as String?),
            throwsA(action == 'map.duplicate'
                ? isA<MapAuthoringException>()
                : isA<AuthoringRevisionConflict>()));
        expect(await source.readAsBytes(), changed);
        expect(
            await File('${setup.root.path}/maps/source.json').exists(), isTrue);
        expect(await File('${setup.root.path}/maps/target.json').exists(),
            isFalse);
      });
    }
    test('create refuses an orphan atmosphere without touching it', () async {
      final setup = await _Setup.create();
      addTearDown(setup.dispose);
      final orphan = File('${setup.root.path}/maps/orphan.atmosphere.json');
      await orphan.parent.create(recursive: true);
      await orphan.writeAsString('retained orphan');
      await expectLater(
          setup.mutations.plan(
              setup.projectHandle,
              await setup.requestAsync(
                  actionId: 'map.create',
                  parameters: {'mapId': 'orphan', 'width': 3, 'height': 3})),
          throwsA(isA<MapAuthoringException>()));
      expect(await orphan.readAsString(), 'retained orphan');
      expect(
          await File('${setup.root.path}/maps/orphan.json').exists(), isFalse);
    });
    test('duplicate refuses a newly created source atmosphere before promotion',
        () async {
      final setup = await _Setup.create(
          maps: [catalogMap('source')], enableSnapshotCache: true);
      addTearDown(setup.dispose);
      final plan = await setup.mutations.plan(
          setup.projectHandle,
          await setup.requestAsync(
              actionId: 'map.duplicate',
              parameters: {'sourceMapId': 'source', 'targetMapId': 'target'}));
      final source = File('${setup.root.path}/maps/source.atmosphere.json');
      await source.writeAsString(jsonEncode(SpatialAtmosphereDocument(
              mapId: 'source',
              settings: SpatialAtmosphereSettings(fireflies: true))
          .toJson()));
      await expectLater(
          setup.mutations.apply(setup.projectHandle,
              planId: plan['planId']! as String,
              operationId: 'atmosphere_source_race'),
          throwsA(isA<MapAuthoringException>()));
      expect(
          await File('${setup.root.path}/maps/target.json').exists(), isFalse);
    });
    test(
        'duplicate recovers its map and atmosphere after interrupted promotion',
        () async {
      var crash = true;
      final setup = await _Setup.create(
          maps: [catalogMap('source')],
          faultInjector: (context) {
            if (crash &&
                context.checkpoint ==
                    AuthoringTransactionCheckpoint.afterResourcePromoted &&
                context.promotionIndex == 0) {
              throw const AuthoringTransactionSimulatedCrash();
            }
          });
      addTearDown(setup.dispose);
      final settings = SpatialAtmosphereSettings(fireflies: true);
      await File('${setup.root.path}/maps/source.atmosphere.json')
          .writeAsString(jsonEncode(
              SpatialAtmosphereDocument(mapId: 'source', settings: settings)
                  .toJson()));
      final plan = await setup.mutations.plan(
          setup.projectHandle,
          await setup.requestAsync(
              actionId: 'map.duplicate',
              parameters: {'sourceMapId': 'source', 'targetMapId': 'target'}));
      await expectLater(
          setup.mutations.apply(setup.projectHandle,
              planId: plan['planId']! as String,
              operationId: 'atmosphere_crash'),
          throwsA(isA<AuthoringTransactionSimulatedCrash>()));
      crash = false;
      await setup.mutations
          .recover(setup.projectHandle, operationId: 'atmosphere_crash');
      expect(
          SpatialAtmosphereDocument.fromJson(jsonDecode(
                  await File('${setup.root.path}/maps/target.atmosphere.json')
                      .readAsString()))
              .settings,
          settings);
    });
    test('recovery protects an absent source atmosphere under the writer lock',
        () async {
      var crash = true;
      final setup = await _Setup.create(
          maps: [catalogMap('source')],
          faultInjector: (context) {
            if (crash &&
                context.checkpoint ==
                    AuthoringTransactionCheckpoint.afterResourcePromoted &&
                context.promotionIndex == 0) {
              throw const AuthoringTransactionSimulatedCrash();
            }
          });
      addTearDown(setup.dispose);
      final plan = await setup.mutations.plan(
          setup.projectHandle,
          await setup.requestAsync(
              actionId: 'map.duplicate',
              parameters: {'sourceMapId': 'source', 'targetMapId': 'target'}));
      await expectLater(
          setup.mutations.apply(setup.projectHandle,
              planId: plan['planId']! as String,
              operationId: 'atmosphere_crash_race'),
          throwsA(isA<AuthoringTransactionSimulatedCrash>()));
      crash = false;
      final source = File('${setup.root.path}/maps/source.atmosphere.json');
      await source.writeAsString(jsonEncode(SpatialAtmosphereDocument(
              mapId: 'source',
              settings: SpatialAtmosphereSettings(fireflies: true))
          .toJson()));
      final before = await source.readAsBytes();
      await expectLater(
          setup.mutations.recover(setup.projectHandle,
              operationId: 'atmosphere_crash_race'),
          throwsA(isA<MapAuthoringException>()));
      expect(await source.readAsBytes(), before);
      expect(
          await File('${setup.root.path}/maps/target.atmosphere.json').exists(),
          isFalse);
    });

    test('resize plan refuses a new closed-map reference before application',
        () async {
      final target = catalogMap('target', width: 5, height: 4);
      final owner = catalogMap('owner', width: 5, height: 4);
      final setup = await _Setup.create(maps: [target, owner]);
      addTearDown(setup.dispose);
      final before =
          await File('${setup.root.path}/maps/target.json').readAsBytes();
      final request = await setup.requestAsync(
          actionId: 'map.resize_apply',
          parameters: {'mapId': 'target', 'width': 4, 'height': 4});
      final plan = await setup.mutations.plan(setup.projectHandle, request);
      final changedOwner = owner.copyWith(warps: const [
        MapWarp(
            id: 'new_entry',
            pos: GridPos(x: 0, y: 0),
            targetMapId: 'target',
            targetPos: GridPos(x: 4, y: 0))
      ]);
      await File('${setup.root.path}/maps/owner.json')
          .writeAsBytes(encodeMapAuthoringDocument(changedOwner), flush: true);
      await expectLater(
          setup.mutations.apply(setup.projectHandle,
              planId: plan['planId']! as String, operationId: 'resize_stale'),
          throwsA(isA<AuthoringPlanException>()));
      expect(await File('${setup.root.path}/maps/target.json').readAsBytes(),
          before);
      expect(
          (await setup.snapshots.load(setup.projectHandle))
              .mapById('owner')!
              .warps
              .single
              .id,
          'new_entry');
    });

    test('duplicate is independently editable and never publishes its source',
        () async {
      final source = catalogMap('source', width: 5, height: 4);
      final setup = await _Setup.create(maps: [source]);
      addTearDown(setup.dispose);
      final sourceFile = File('${setup.root.path}/maps/source.json');
      final before = await sourceFile.readAsBytes();
      final request = await setup.requestAsync(
          actionId: 'map.duplicate', parameters: {'sourceMapId': 'source'});
      final plan = await setup.mutations.plan(setup.projectHandle, request);
      await setup.mutations.apply(setup.projectHandle,
          planId: plan['planId']! as String, operationId: 'duplicate_source');
      final independent = await setup.snapshots.load(setup.projectHandle);
      final copy = independent.mapById('source_copy')!;
      final save = await setup.requestAsync(
          actionId: 'map.save',
          parameters: {'map': copy.copyWith(name: 'Edited copy').toJson()});
      final savePlan = await setup.mutations.plan(setup.projectHandle, save);
      await setup.mutations.apply(setup.projectHandle,
          planId: savePlan['planId']! as String, operationId: 'save_copy');
      expect(await sourceFile.readAsBytes(), before);
      expect(
          (await setup.snapshots.load(setup.projectHandle))
              .mapById('source_copy')!
              .name,
          'Edited copy');
    });

    test('map save verifies only its touched payload without a full reload',
        () async {
      final original = _map('town');
      final performanceObserver = _PerformanceObserver();
      final setup = await _Setup.create(
        maps: [original],
        enableSnapshotCache: true,
        performanceObserver: performanceObserver,
      );
      addTearDown(setup.dispose);
      final request = await setup.requestAsync(
        actionId: 'map.save',
        parameters: {
          'map': original.copyWith(name: 'Town Updated').toJson(),
        },
      );
      setup.reader.resetCounts();

      final planned = await setup.mutations.plan(setup.projectHandle, request);
      final applied = await setup.mutations.apply(
        setup.projectHandle,
        planId: planned['planId']! as String,
        operationId: 'operation_save_town_fast',
      );

      expect(applied['snapshotRevision'], startsWith('sha256:'));
      expect(setup.reader.byteReads, 1);
      expect(
        performanceObserver.started,
        containsAll(<String>[
          'snapshot',
          'plan',
          'apply',
          'save.encode',
          'save.queue',
        ]),
      );
      expect(
        performanceObserver.finished,
        containsAll(<String>[
          'snapshot',
          'plan',
          'apply',
          'save.encode',
          'save.queue',
        ]),
      );
      expect(performanceObserver.counters['filesystem.write'], greaterThan(0));
      expect(performanceObserver.counters['json.encode'], greaterThan(0));
      expect(
          (await setup.snapshots.load(setup.projectHandle))
              .mapById('town')!
              .name,
          'Town Updated');
    });

    test('plans, applies, records, and undoes map creation', () async {
      final setup = await _Setup.create();
      addTearDown(setup.dispose);
      final request = await setup.requestAsync(
        actionId: 'map.create',
        parameters: const {
          'mapId': 'route_01',
          'name': 'Route 01',
          'width': 3,
          'height': 2,
        },
      );

      final planned = await setup.mutations.plan(setup.projectHandle, request);
      expect(planned['plan'], isA<Map<String, Object?>>());
      expect(
        (planned['receipt']! as Map<String, Object?>)['status'],
        'planned',
      );
      expect(
        await File('${setup.root.path}/maps/route_01.json').exists(),
        isFalse,
      );

      final applied = await setup.mutations.apply(
        setup.projectHandle,
        planId: planned['planId']! as String,
        operationId: 'operation_create_route_01',
      );
      final receipt = applied['receipt']! as Map<String, Object?>;
      expect(receipt['status'], 'applied');
      expect(applied['snapshotRevision'], startsWith('sha256:'));
      final mapFile = File('${setup.root.path}/maps/route_01.json');
      expect(await mapFile.exists(), isTrue);
      expect(
        MapData.fromJson(
          jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>,
        ).name,
        'Route 01',
      );
      expect(
        ProjectManifest.fromJson(
          jsonDecode(
            await File('${setup.root.path}/project.json').readAsString(),
          ) as Map<String, dynamic>,
        ).maps.single.id,
        'route_01',
      );

      final undone = await setup.mutations.undo(
        setup.projectHandle,
        entryId: receipt['receiptId']! as String,
        idempotencyKey: 'idem_undo_route_01',
      );
      expect(
        (undone['receipt']! as Map<String, Object?>)['actionId'],
        'history.undo',
      );
      expect(await mapFile.exists(), isFalse);
      expect(
        ProjectManifest.fromJson(
          jsonDecode(
            await File('${setup.root.path}/project.json').readAsString(),
          ) as Map<String, dynamic>,
        ).maps,
        isEmpty,
      );
    });

    test('marks dry-run plans non-applicable before confirm or apply',
        () async {
      final setup = await _Setup.create();
      addTearDown(setup.dispose);
      final request = await setup.requestAsync(
        actionId: 'map.create',
        parameters: const {
          'mapId': 'dry_run_map',
          'width': 2,
          'height': 2,
        },
        dryRun: true,
      );

      final planned = await setup.mutations.plan(setup.projectHandle, request);
      expect(planned['applicable'], isFalse);
      expect(
        (planned['plan']! as Map<String, Object?>)['applicable'],
        isFalse,
      );
      expect(
        (planned['plan']! as Map<String, Object?>)['nonApplicableReason'],
        'dry_run',
      );

      for (final attempt in <Future<Object?> Function()>[
        () => setup.mutations.confirm(
              setup.projectHandle,
              planId: planned['planId']! as String,
            ),
        () => setup.mutations.apply(
              setup.projectHandle,
              planId: planned['planId']! as String,
              operationId: 'operation_dry_run_must_not_apply',
            ),
      ]) {
        await expectLater(
          attempt,
          throwsA(
            isA<AuthoringPlanException>().having(
              (error) => error.code,
              'code',
              'plan.dry_run_not_applicable',
            ),
          ),
        );
      }
      expect(
        await File('${setup.root.path}/maps/dry_run_map.json').exists(),
        isFalse,
      );
    });

    test('requires one-use confirmation for destructive deletion', () async {
      final setup = await _Setup.create(
        maps: [_map('town')],
      );
      addTearDown(setup.dispose);
      final request = await setup.requestAsync(
        actionId: 'map.delete_apply',
        parameters: const {'mapId': 'town'},
      );
      final planned = await setup.mutations.plan(setup.projectHandle, request);

      await expectLater(
        () => setup.mutations.apply(
          setup.projectHandle,
          planId: planned['planId']! as String,
          operationId: 'operation_delete_town_denied',
        ),
        throwsA(
          isA<AuthoringAuthorizationException>().having(
            (error) => error.code,
            'code',
            'confirmation.required',
          ),
        ),
      );
      final confirmation = await setup.mutations.confirm(
        setup.projectHandle,
        planId: planned['planId']! as String,
      );
      final token = confirmation['confirmationToken']! as String;
      final applied = await setup.mutations.apply(
        setup.projectHandle,
        planId: planned['planId']! as String,
        operationId: 'operation_delete_town',
        confirmationToken: token,
      );
      expect(
        (applied['receipt']! as Map<String, Object?>)['status'],
        'applied',
      );
      expect(await File('${setup.root.path}/maps/town.json').exists(), isFalse);

      final replayed = await setup.mutations.apply(
        setup.projectHandle,
        planId: planned['planId']! as String,
        operationId: 'operation_delete_town_reuse',
        confirmationToken: token,
      );
      expect(replayed['receipt'], applied['receipt']);
      expect(await File('${setup.root.path}/maps/town.json').exists(), isFalse);
      final audit = await FileAuthoringAuditLog.open(
        projectRoot: setup.root.path,
      );
      final successful = (await audit.readAll())
          .where(
            (record) => record.decision == AuthoringAuditDecision.succeeded,
          )
          .toList(growable: false);
      expect(successful, hasLength(2));
      expect(successful.first.details['confirmationConsumed'], isTrue);
      expect(successful.last.details['confirmationConsumed'], isFalse);
      expect(successful.last.details['idempotentReplay'], isTrue);
    });

    test('recovers manifest plus map after a crash between promotions',
        () async {
      var crash = true;
      final setup = await _Setup.create(
        faultInjector: (context) {
          if (crash &&
              context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterResourcePromoted &&
              context.promotionIndex == 0) {
            throw const AuthoringTransactionSimulatedCrash();
          }
        },
      );
      addTearDown(setup.dispose);
      final request = await setup.requestAsync(
        actionId: 'map.create',
        parameters: const {
          'mapId': 'recovered_map',
          'width': 2,
          'height': 2,
        },
      );
      final planned = await setup.mutations.plan(setup.projectHandle, request);

      await expectLater(
        () => setup.mutations.apply(
          setup.projectHandle,
          planId: planned['planId']! as String,
          operationId: 'operation_recovered_map',
        ),
        throwsA(isA<AuthoringTransactionSimulatedCrash>()),
      );
      expect(
        await File('${setup.root.path}/maps/recovered_map.json').exists(),
        isTrue,
      );
      expect(
        ProjectManifest.fromJson(
          jsonDecode(
            await File('${setup.root.path}/project.json').readAsString(),
          ) as Map<String, dynamic>,
        ).maps,
        isEmpty,
      );

      crash = false;
      final recovered = await setup.mutations.recover(
        setup.projectHandle,
        operationId: 'operation_recovered_map',
      );
      expect(
        (recovered['receipt']! as Map<String, Object?>)['status'],
        'recovered',
      );
      expect(
        ProjectManifest.fromJson(
          jsonDecode(
            await File('${setup.root.path}/project.json').readAsString(),
          ) as Map<String, dynamic>,
        ).maps.single.id,
        'recovered_map',
      );
      final audit = await FileAuthoringAuditLog.open(
        projectRoot: setup.root.path,
      );
      final recoveryRecords = (await audit.readAll())
          .where(
            (record) => record.operation == AuthoringSecurityOperation.recover,
          )
          .toList(growable: false);
      expect(recoveryRecords, hasLength(1));
      expect(
        recoveryRecords.single.decision,
        AuthoringAuditDecision.succeeded,
      );
      expect(
        recoveryRecords.single.receiptId,
        (recovered['receipt']! as Map<String, Object?>)['receiptId'],
      );
    });

    test('rejects history after the project handle expires', () async {
      var now = DateTime.utc(2026, 8, 8, 12);
      final setup = await _Setup.create(
        clock: () => now,
        handleTtl: const Duration(minutes: 1),
      );
      addTearDown(setup.dispose);

      now = now.add(const Duration(minutes: 1));

      await expectLater(
        () => setup.mutations.history(setup.projectHandle, limit: 10),
        throwsA(
          isA<WorkspaceHandleException>().having(
            (error) => error.code,
            'code',
            'workspace.handle_expired',
          ),
        ),
      );
    });

    test('rejects recovery without promoting after the handle expires',
        () async {
      var now = DateTime.utc(2026, 8, 8, 12);
      var crash = true;
      final setup = await _Setup.create(
        clock: () => now,
        handleTtl: const Duration(minutes: 1),
        faultInjector: (context) {
          if (crash &&
              context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterResourcePromoted &&
              context.promotionIndex == 0) {
            throw const AuthoringTransactionSimulatedCrash();
          }
        },
      );
      addTearDown(setup.dispose);
      final request = await setup.requestAsync(
        actionId: 'map.create',
        parameters: const {
          'mapId': 'expired_recovery_map',
          'width': 2,
          'height': 2,
        },
      );
      final planned = await setup.mutations.plan(setup.projectHandle, request);

      await expectLater(
        () => setup.mutations.apply(
          setup.projectHandle,
          planId: planned['planId']! as String,
          operationId: 'operation_expired_recovery',
        ),
        throwsA(isA<AuthoringTransactionSimulatedCrash>()),
      );
      final manifestFile = File('${setup.root.path}/project.json');
      final manifestBeforeRecovery = await manifestFile.readAsBytes();
      crash = false;
      now = now.add(const Duration(minutes: 1));

      await expectLater(
        () => setup.mutations.recover(
          setup.projectHandle,
          operationId: 'operation_expired_recovery',
        ),
        throwsA(
          isA<WorkspaceHandleException>().having(
            (error) => error.code,
            'code',
            'workspace.handle_expired',
          ),
        ),
      );
      expect(await manifestFile.readAsBytes(), manifestBeforeRecovery);
    });

    test('audits denied and failed recovery attempts', () async {
      final deniedSetup = await _Setup.create(
        actor: AuthoringActor(
          actorId: 'recovery_denied_actor',
          permissions: const [
            AuthoringPermissionScope.projectRead,
            AuthoringPermissionScope.projectWrite,
          ],
        ),
      );
      addTearDown(deniedSetup.dispose);
      await expectLater(
        () => deniedSetup.mutations.recover(
          deniedSetup.projectHandle,
          operationId: 'operation_denied_recovery',
        ),
        throwsA(
          isA<AuthoringAuthorizationException>().having(
            (error) => error.code,
            'code',
            'authorization.permission_denied',
          ),
        ),
      );
      final deniedAudit = await FileAuthoringAuditLog.open(
        projectRoot: deniedSetup.root.path,
      );
      expect(
        (await deniedAudit.readAll()).single.decision,
        AuthoringAuditDecision.denied,
      );

      final failedSetup = await _Setup.create();
      addTearDown(failedSetup.dispose);
      await expectLater(
        () => failedSetup.mutations.recover(
          failedSetup.projectHandle,
          operationId: 'operation_missing_recovery',
        ),
        throwsA(
          isA<AuthoringRecoveryException>().having(
            (error) => error.code,
            'code',
            'recovery.journal_missing',
          ),
        ),
      );
      final failedAudit = await FileAuthoringAuditLog.open(
        projectRoot: failedSetup.root.path,
      );
      expect(
        (await failedAudit.readAll()).single.decision,
        AuthoringAuditDecision.failed,
      );
    });
  });
}

final class _Setup {
  _Setup._({
    required this.root,
    required this.mutations,
    required this.workspaceHandle,
    required this.projectHandle,
    required this.snapshots,
    required this.reader,
  });

  static Future<_Setup> create({
    List<MapData> maps = const [],
    AuthoringTransactionFaultInjector? faultInjector,
    bool enableSnapshotCache = false,
    DateTime Function()? clock,
    Duration handleTtl = const Duration(minutes: 15),
    AuthoringActor? actor,
    AuthoringPerformanceObserver? performanceObserver,
  }) async {
    final root = await Directory.systemTemp.createTemp('map-lifecycle-');
    final manifest = ProjectManifest(
      name: 'Lifecycle Transaction Fixture',
      version: ProjectVersion.v8,
      maps: [
        for (final map in maps)
          ProjectMapEntry(
            id: map.id,
            name: map.name,
            relativePath: 'maps/${map.id}.json',
          ),
      ],
      tilesets: const [],
    );
    await File('${root.path}/project.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
      flush: true,
    );
    if (maps.isNotEmpty) {
      await Directory('${root.path}/maps').create();
      for (final map in maps) {
        await File('${root.path}/maps/${map.id}.json').writeAsBytes(
          encodeMapAuthoringDocument(map),
          flush: true,
        );
      }
    }
    final reader = _CountingLocalReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore(
      clock: clock,
      tokenFactory: (prefix) => '${prefix}fixture',
      ttl: handleTtl,
    );
    final open = ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    );
    final opened = await open.openProject(root.path);
    final snapshots = ProjectSnapshotLoader(
      handles: handles,
      snapshotCache: enableSnapshotCache ? ProjectSnapshotCache() : null,
    );
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
      clock: clock,
      faultInjector: faultInjector,
      actor: actor,
      performanceObserver: performanceObserver,
    );
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    return _Setup._(
      root: root,
      mutations: mutations,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
      snapshots: snapshots,
      reader: reader,
    );
  }

  final Directory root;
  final LocalMapAuthoringMutationApi mutations;
  final WorkspaceHandle workspaceHandle;
  final ProjectHandle projectHandle;
  final ProjectSnapshotLoader snapshots;
  final _CountingLocalReader reader;

  Future<AuthoringRequest> requestAsync({
    required String actionId,
    required Map<String, Object?> parameters,
    bool dryRun = false,
  }) async {
    final snapshot = await snapshots.load(projectHandle);
    return AuthoringRequest(
      requestId: 'request_${actionId.replaceAll('.', '_')}',
      actionId: actionId,
      actionVersion: 1,
      workspaceHandle: workspaceHandle.value,
      parameters: parameters,
      expectedRevision: snapshot.revision,
      idempotencyKey: 'idem_${actionId.replaceAll('.', '_')}',
      dryRun: dryRun,
    );
  }

  Future<void> dispose() async {
    await mutations.detachWorkspace(workspaceHandle);
    if (await root.exists()) await root.delete(recursive: true);
  }
}

final class _PerformanceObserver implements AuthoringPerformanceObserver {
  final List<String> started = <String>[];
  final List<String> finished = <String>[];
  final Map<String, int> counters = <String, int>{};

  @override
  AuthoringPerformanceSpan startSpan(String name) {
    started.add(name);
    return _PerformanceSpan(name, finished);
  }

  @override
  void incrementCounter(String name, {int by = 1}) {
    counters.update(name, (value) => value + by, ifAbsent: () => by);
  }
}

final class _PerformanceSpan implements AuthoringPerformanceSpan {
  _PerformanceSpan(this.name, this.finished);

  final String name;
  final List<String> finished;

  @override
  void finish() => finished.add(name);
}

final class _CountingLocalReader
    implements
        ProjectFileReader,
        ProjectResourceIdentityReader,
        ProjectSnapshotCacheIdentityReader {
  final LocalProjectFileReader _delegate = const LocalProjectFileReader();
  var byteReads = 0;

  void resetCounts() => byteReads = 0;

  @override
  Future<String> canonicalizeDirectory(String path) =>
      _delegate.canonicalizeDirectory(path);

  @override
  Future<ProjectResourceIdentity?> readIdentity({
    required String projectRoot,
    required String relativePath,
  }) =>
      _delegate.readIdentity(
        projectRoot: projectRoot,
        relativePath: relativePath,
      );

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) {
    byteReads += 1;
    return _delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }
}

MapData _map(String id) => MapData(
      id: id,
      name: id,
      size: const GridSize(width: 2, height: 2),
      version: ProjectVersion.v8,
      visualStack: MapVisualStackConfig.canonicalV1,
      layers: [
        MapLayer.tile(
          id: 'l_base',
          name: 'Base',
          cells: List<int>.filled(4, 0),
        ),
        MapLayer.collision(
          id: 'l_collisions',
          name: 'Collisions',
          collisions: List<bool>.filled(4, false),
        ),
      ],
    );
