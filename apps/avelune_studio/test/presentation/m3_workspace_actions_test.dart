import 'dart:convert';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/workspace_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import '../infrastructure/local_regional_map_adapter_test.dart'
    show createRegionalFixture;
import '../application/regional_map_controller_test.dart'
    show MemoryRegionalMapPort;

import 'package:avelune_studio/features/regional_map/application/regional_map_controller.dart';

void main() {
  testWidgets(
    'regional drafts participate in close, editor flush and export publication',
    (tester) async {
      final maps = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      await maps.initialize();
      addTearDown(maps.dispose);
      final owner = RegionalMapController(
        MemoryRegionalMapPort(),
        changed: () {},
      );
      await owner.load();
      owner.createRegion('Kanto');
      late WorkspaceActions actions;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              actions = WorkspaceActions(
                controller: maps,
                context: () => context,
                mounted: () => true,
                changed: () {},
                resources: () => null,
                narrative: () => null,
                regionalMap: () => owner,
                runtimeBuilder: (_, _, _) => const SizedBox(),
              );
              return const Scaffold();
            },
          ),
        ),
      );
      expect(actions.hasCatalogDependencyDraft, isTrue);
      expect(actions.hasPendingChanges, isTrue);
      expect(await actions.flushEditors(), isFalse);
      expect(await actions.saveForExport(), isFalse);
      expect(owner.dirty, isTrue);
      owner.editRegion(imagePath: 'assets/region.png');
      expect(await actions.flushEditors(), isTrue);
      expect(await actions.saveForExport(), isTrue);
      expect(actions.hasPendingChanges, isFalse);
      expect(await actions.allowClose(), isTrue);
    },
  );

  for (final saveOnClose in [false, true]) {
    testWidgets(
      'global ${saveOnClose ? 'close' : 'export'} saves linked spawn map before its regional draft',
      (tester) async {
        await tester.runAsync(() async {
          final fixture = await createRegionalFixture();
          addTearDown(() => fixture.root.delete(recursive: true));
          final maps = MapWorkspaceController(
            fixture.port.session,
            fixture.port.mapAdapter,
          );
          await maps.initialize();
          addTearDown(maps.dispose);
          final owner = RegionalMapController(
            fixture.port,
            changed: () {},
            mapDraftProblem: (ids) =>
                maps.documents.values.any(
                  (document) =>
                      document.dirty && ids.contains(document.current.id),
                )
                ? 'Carte liée en brouillon.'
                : null,
            projectChanged: maps.acceptResources,
          );
          await owner.load();
          owner.createRegion('Kanto');
          owner.editRegion(imagePath: 'assets/region.png');
          owner.createPoint('Town', 'town');
          owner.editPoint(
            destination: ProjectRegionDestination(
              mapId: 'town',
              spawnId: 'arrival',
            ),
          );
          expect(await owner.saveAll(), isTrue, reason: owner.error);
          owner.editPoint(label: 'Town changed');
          final document = maps.active!;
          document.commit(
            document.current.copyWith(
              entities: [
                document.current.entities.single.copyWith(
                  pos: const GridPos(x: 5, y: 6),
                  spawn: const MapEntitySpawnData(facing: EntityFacing.west),
                ),
              ],
            ),
          );
          late WorkspaceActions actions;
          await tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (context) {
                  actions = WorkspaceActions(
                    controller: maps,
                    context: () => context,
                    mounted: () => true,
                    changed: () {},
                    resources: () => null,
                    narrative: () => null,
                    regionalMap: () => owner,
                    runtimeBuilder: (_, _, _) => const SizedBox(),
                  );
                  return const Scaffold();
                },
              ),
            ),
          );
          expect(actions.hasPendingChanges, isTrue);
          if (saveOnClose) {
            final close = actions.allowClose();
            await tester.pumpAndSettle();
            await tester.tap(find.text('Enregistrer'));
            await tester.pumpAndSettle();
            expect(await close, isTrue, reason: owner.error);
          } else {
            expect(await actions.flushEditors(), isTrue, reason: owner.error);
            expect(document.dirty, isTrue);
            expect(await actions.saveForExport(), isTrue, reason: owner.error);
          }
          final persisted = MapData.fromJson(
            jsonDecode(await fixture.map.readAsString())
                as Map<String, dynamic>,
          );
          expect(persisted.entities.single.pos, const GridPos(x: 5, y: 6));
          expect(persisted.entities.single.spawn!.facing, EntityFacing.west);
          expect(owner.source!.maps['town'], persisted);
          expect(owner.catalog.pointsOfInterest.single.label, 'Town changed');
          final reopened = await fixture.port.load();
          expect(
            reopened
                .project
                .regionalMap!
                .pointsOfInterest
                .single
                .destination!
                .spawnId,
            'arrival',
          );
          expect(owner.dirty, isFalse);
          expect(document.dirty, isFalse);
          expect(actions.hasPendingChanges, isFalse);
          expect(await actions.allowClose(), isTrue);
          expect(await actions.saveForExport(), isTrue);
        });
      },
    );
  }
  testWidgets(
    'global export keeps an invalid regional draft after saving deletion of its linked spawn',
    (tester) async {
      await tester.runAsync(() async {
        final fixture = await createRegionalFixture();
        addTearDown(() => fixture.root.delete(recursive: true));
        final maps = MapWorkspaceController(
          fixture.port.session,
          fixture.port.mapAdapter,
        );
        await maps.initialize();
        addTearDown(maps.dispose);
        final owner = RegionalMapController(
          fixture.port,
          changed: () {},
          projectChanged: maps.acceptResources,
        );
        await owner.load();
        owner.createRegion('Kanto');
        owner.editRegion(imagePath: 'assets/region.png');
        owner.createPoint('Town', 'town');
        owner.editPoint(
          destination: ProjectRegionDestination(
            mapId: 'town',
            spawnId: 'arrival',
          ),
        );
        maps.active!.commit(maps.active!.current.copyWith(entities: []));
        late WorkspaceActions actions;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                actions = WorkspaceActions(
                  controller: maps,
                  context: () => context,
                  mounted: () => true,
                  changed: () {},
                  resources: () => null,
                  narrative: () => null,
                  regionalMap: () => owner,
                  runtimeBuilder: (_, _, _) => const SizedBox(),
                );
                return const Scaffold();
              },
            ),
          ),
        );
        expect(await actions.flushEditors(), isFalse);
        expect(await actions.saveForExport(), isFalse);
        expect(maps.active!.dirty, isFalse);
        expect((await fixture.port.load()).maps['town']!.entities, isEmpty);
        expect(owner.source!.maps['town']!.entities, isEmpty);
        expect(owner.error, contains('arrivée'));
        expect(owner.dirty, isTrue);
        expect(actions.hasPendingChanges, isTrue);
        expect((await fixture.port.load()).project.regionalMap, isNull);
      });
    },
  );

  testWidgets(
    'failed narrative publication blocks runtime and saving close without losing either map',
    (tester) async {
      final maps = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      await maps.initialize();
      final first = maps.active!;
      first.commit(first.current.copyWith(name: 'Première carte modifiée'));
      await maps.activate(workspaceEntries.last);
      final second = maps.active!;
      second.commit(second.current.copyWith(name: 'Deuxième carte modifiée'));
      final failing = _FailingNarrativePort();
      final narrative = NarrativeWorkspaceController(
        maps,
        failing,
        () {},
        (_, _) async {},
      );
      narrative.addFact('À conserver');
      late WorkspaceActions actions;
      var launches = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              actions = WorkspaceActions(
                controller: maps,
                context: () => context,
                mounted: () => true,
                changed: () {},
                resources: () => null,
                narrative: () => narrative,
                runtimeBuilder: (_, _, _) {
                  launches++;
                  return const SizedBox();
                },
              );
              return const Scaffold(body: Text('Éditeur'));
            },
          ),
        ),
      );
      await actions.test();
      expect(launches, 0);
      expect(actions.testing, isFalse);
      expect(failing.attempts, 1);
      expect(first.dirty, isTrue);
      expect(second.dirty, isTrue);
      expect(narrative.pendingFacts, hasLength(1));
      final close = actions.allowClose();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(await close, isFalse);
      expect(actions.closing, isFalse);
      expect(failing.attempts, 2);
      expect(first.current.name, 'Première carte modifiée');
      expect(second.current.name, 'Deuxième carte modifiée');
      expect(first.dirty, isTrue);
      expect(second.dirty, isTrue);
      expect(narrative.pendingFacts, hasLength(1));
      expect(narrative.error, contains('Conflit externe'));
      await tester.pumpWidget(const SizedBox());
      maps.dispose();
    },
  );
}

class _FailingNarrativePort implements NarrativePort {
  var attempts = 0;
  @override
  Future<NarrativePublicationReceipt> publish(
    NarrativePublication publication,
  ) async {
    attempts++;
    throw const NarrativeFailure('Conflit externe simulé');
  }

  @override
  Future<NarrativeDialogueSource> readDialogue(ProjectDialogueEntry entry) =>
      throw UnimplementedError();
}
