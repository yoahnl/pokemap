import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/application/project_resource_library.dart';
import 'package:avelune_studio/presentation/features/resources/library/resource_library_view.dart';
import 'package:avelune_studio/presentation/features/resources/library/resource_library_view_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import 'map_builder_selection_harness.dart';

void main() {
  for (final fail in [false, true]) {
    testWidgets(
      'an asset opens its real map and preserves the draft, fail=$fail',
      (tester) async {
        final port = _UsageWorkspace()..failedMap = fail ? 'b' : null;
        final host = await openSelectionHost(tester, workspace: port);
        final original = host.maps.active!;
        final originalMap = original.base.mapId;
        original.commit(original.current.copyWith(name: 'Carte en cours'));
        final reference = host.maps.project!.maps.first.name;

        await tester.tap(_keyed('studio-rail-resources'));
        await host.settle();
        await tester.tap(_keyed('library-scope-used'));
        await tester.enterText(_search, 'moulin');
        await host.settle();
        await tester.tap(_keyed('library-item-model3d:windmill'));
        await host.settle();
        final mapLink = _keyed('library-map-b');
        await tester.ensureVisible(mapLink);
        await tester.tap(mapLink);
        await host.settle();

        if (fail) {
          expect(host.maps.active, same(original));
          expect(find.text('Impossible d’ouvrir cette carte.'), findsOneWidget);
        } else {
          expect(host.maps.active?.base.mapId, 'b');
          expect(_search, findsNothing);
          await tester.tap(_keyed('studio-rail-resources'));
          await host.settle();
        }
        expect(tester.widget<TextField>(_search).controller?.text, 'moulin');
        expect(
          find.text('Ressources utilisées sur $reference.'),
          findsOneWidget,
        );
        expect(host.maps.documents[originalMap], same(original));
        expect(original.current.name, 'Carte en cours');
        expect(original.dirty, isTrue);
        expect(port.writes, 0);
        if (!fail) {
          final originalLink = _keyed('library-map-a');
          await tester.ensureVisible(originalLink);
          await tester.tap(originalLink);
          await host.settle();
          expect(host.maps.active, same(original));
          expect(original.current.name, 'Carte en cours');
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('map links arrive in an already open narrow detail panel', (
    tester,
  ) async {
    final usages = Completer<Map<String, Set<String>>?>();
    final port = _UsageWorkspace(mapUsages: usages.future);
    final host = await openSelectionHost(tester, workspace: port);
    tester.view.physicalSize = const Size(850, 1080);
    await tester.tap(_keyed('studio-rail-resources'));
    await host.settle();
    await tester.enterText(_search, 'moulin');
    await host.settle();
    await tester.tap(_keyed('library-item-model3d:windmill'));
    await tester.pumpAndSettle();
    expect(_keyed('library-detail-model3d:windmill'), findsOneWidget);
    expect(_keyed('library-map-b'), findsNothing);

    usages.complete(_UsageWorkspace.linkedMaps);
    await tester.pumpAndSettle();
    final mapLink = _keyed('library-map-b');
    expect(mapLink, findsOneWidget);
    await tester.ensureVisible(mapLink);
    await tester.tap(mapLink);
    await tester.pumpAndSettle();

    expect(host.maps.active?.base.mapId, 'b');
    expect(_keyed('library-detail-model3d:windmill'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalogue relations load for the inspected card only', (
    tester,
  ) async {
    final loading = Completer<ProjectLibraryRelations?>();
    final port = _UsageWorkspace(
      relations: (identity) async {
        return identity == 'model3d:oak'
            ? loading.future
            : (sources: {'model3d:oak'}, consumers: null);
      },
    );
    final host = await openSelectionHost(tester, workspace: port);
    await tester.tap(_keyed('studio-rail-resources'));
    await host.settle();
    expect(port.relationReads, isEmpty);
    await tester.enterText(_search, 'chene');
    await host.settle();
    await tester.tap(_keyed('library-item-model3d:oak'));
    await host.settle();
    expect(port.relationReads, ['model3d:oak']);
    expect(find.text('Recherche des ressources liées…'), findsOneWidget);

    loading.complete((
      sources: <String>{},
      consumers: {'environmentPreset:woodland'},
    ));
    await host.settle();
    final consumer = _keyed('library-source-environmentPreset:woodland');
    await tester.ensureVisible(consumer);
    await tester.tap(consumer);
    await host.settle();
    expect(_keyed('library-detail-environmentPreset:woodland'), findsOneWidget);
    expect(port.relationReads, ['model3d:oak', 'environmentPreset:woodland']);
    expect(_keyed('library-source-model3d:oak'), findsOneWidget);
    expect(
      find.text('L’index des usages entre ressources n’est pas préparé.'),
      findsOneWidget,
    );
    expect(tester.widget<TextField>(_search).controller?.text, 'chene');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'the related card is inspected without changing library filters',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: const Scaffold(
            body: ResourceLibraryView(
              maps: {},
              showRoles: true,
              items: [
                ResourceLibraryItemView(
                  id: 'model3d:oak',
                  name: 'Chêne source',
                  category: ResourceLibraryCategory.models,
                  type: 'Modèle 3D',
                  dimension: ResourceLibraryDimension.threeDimensional,
                  role: ResourceLibraryRole.component,
                ),
                ResourceLibraryItemView(
                  id: 'borderBlueprint:hedge',
                  name: 'Haie montée',
                  category: ResourceLibraryCategory.relief,
                  type: 'Bordure',
                  dimension: ResourceLibraryDimension.threeDimensional,
                  sourceId: 'model3d:oak',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(_keyed('library-role-component'));
      await tester.enterText(_search, 'chene');
      await tester.pumpAndSettle();
      await tester.tap(_keyed('library-item-model3d:oak'));
      await tester.pumpAndSettle();
      final consumer = _keyed('library-source-borderBlueprint:hedge');
      await tester.ensureVisible(consumer);
      await tester.tap(consumer);
      await tester.pumpAndSettle();

      expect(_keyed('library-detail-borderBlueprint:hedge'), findsOneWidget);
      expect(_keyed('library-item-borderBlueprint:hedge'), findsNothing);
      expect(_keyed('library-item-model3d:oak'), findsOneWidget);
      expect(tester.widget<TextField>(_search).controller?.text, 'chene');
      await tester.tap(find.byTooltip('Retour à la fiche précédente'));
      await tester.pumpAndSettle();
      expect(_keyed('library-detail-model3d:oak'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Finder _keyed(String value) => find.byKey(ValueKey(value));

Finder get _search => find.descendant(
  of: _keyed('library-search'),
  matching: find.byType(TextField),
);

final class _UsageWorkspace extends WorkspaceMemoryPort
    implements
        ProjectResourceLibraryPort,
        ProjectResourceLibraryMapUsagesPort,
        ProjectResourceLibraryRelationsPort {
  _UsageWorkspace({this.mapUsages, this.relations})
    : super(manifest: selectionProject());

  static const linkedMaps = {
    'model3d:windmill': {'a', 'b'},
  };
  final Future<Map<String, Set<String>>?>? mapUsages;
  final Future<ProjectLibraryRelations?> Function(String)? relations;
  final relationReads = <String>[];

  @override
  Future<ProjectResourceLibrary> readResourceLibrary(
    ProjectSession session,
  ) async {
    final library = ProjectResourceLibrary.fromManifest(manifest);
    return ProjectResourceLibrary(
      library.catalog,
      library.items,
      revision: 'catalogue',
    );
  }

  @override
  Future<Map<String, Set<String>>?> readResourceLibraryMapUsages(
    ProjectSession session, {
    required String revision,
    required Iterable<String> identities,
  }) async => mapUsages ?? linkedMaps;

  @override
  Future<ProjectLibraryRelations?> readResourceLibraryRelations(
    ProjectSession session,
    String kind,
    String id, {
    required String revision,
  }) async {
    final identity = '$kind:$id';
    relationReads.add(identity);
    expect(revision, 'catalogue');
    return relations == null
        ? (sources: <String>{}, consumers: <String>{})
        : relations!(identity);
  }
}
