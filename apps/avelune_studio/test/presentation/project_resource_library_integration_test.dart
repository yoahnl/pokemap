import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/application/project_resource_library.dart';
import 'package:avelune_studio/features/resources/application/project_resource_preview.dart';
import 'package:avelune_studio/presentation/features/resources/project_library_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import '../support/scoped_map_workspace_port.dart';
import 'map_builder_selection_harness.dart';

void main() {
  Finder keyed(String value) => find.byKey(ValueKey(value));

  testWidgets('the grid reads an off-map preview once across map changes', (
    tester,
  ) async {
    final port = _LibraryPort();
    final maps = MapWorkspaceController(scopedMapSession, port);
    addTearDown(maps.dispose);
    await maps.initialize();
    final visuals = _LibraryVisuals();
    Widget library() => MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: ProjectLibraryPage(active: true, maps: maps, visuals: visuals),
      ),
    );

    await tester.pumpWidget(library());
    await tester.pumpAndSettle();

    expect(keyed('library-item-element:tree'), findsOneWidget);
    expect(keyed('preview-tree'), findsOneWidget);
    expect(port.previews, ['element:tree']);
    expect(maps.visualProject!.elements, isEmpty);

    await maps.activate(secondScopedMap);
    await tester.pumpWidget(library());
    await tester.pumpAndSettle();

    expect(maps.active!.base.mapId, secondScopedMap.id);
    expect(maps.visualProject!.elements, isEmpty);
    expect(keyed('preview-tree'), findsOneWidget);
    expect(port.previews, ['element:tree']);
  });

  testWidgets('map filters use the verified report and the open map', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final report = Completer<Map<String, Set<String>>?>();
    final port = _LibraryPort(mapReport: report.future);
    final maps = MapWorkspaceController(scopedMapSession, port);
    addTearDown(maps.dispose);
    await maps.initialize();
    await maps.activate(secondScopedMap);

    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: ProjectLibraryPage(active: true, maps: maps, visuals: null),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(keyed('library-item-element:tree'), findsOneWidget);
    expect(keyed('library-scope-exclusive'), findsNothing);
    expect(find.text('Calcul des usages par carte…'), findsOneWidget);

    report.complete({
      'element:tree': {firstScopedMap.id, secondScopedMap.id},
      'tileset:second': {secondScopedMap.id},
    });
    await tester.pumpAndSettle();
    await tester.tap(keyed('library-scope-exclusive'));
    await tester.pumpAndSettle();

    expect(find.text('Calcul des usages par carte…'), findsNothing);
    expect(keyed('library-item-element:tree'), findsNothing);
    expect(keyed('library-item-tileset:second'), findsOneWidget);
    expect(port.usageRevision, 'library-revision');
  });

  testWidgets('Studio surfaces catalogue names, families and technical roles', (
    tester,
  ) async {
    final project = selectionProject().copyWith(
      maps: [],
      tilesets: [
        ProjectTilesetEntry(
          id: 'wheel',
          name: 'Roue',
          relativePath: 'assets/roue.png',
        ),
      ],
      resourceLibraryCatalog: ResourceLibraryCatalog(
        families: [
          ResourceFamily(
            id: 'wheel-family',
            name: 'Roues',
            parentId: 'workshop',
          ),
          ResourceFamily(id: 'workshop', name: 'Atelier'),
        ],
        entries: [
          ResourceLibraryEntry(
            resourceKind: 'model3d',
            resourceId: 'windmill',
            familyId: 'workshop',
          ),
          ResourceLibraryEntry(
            resourceKind: 'tileset',
            resourceId: 'wheel',
            familyId: 'wheel-family',
            role: ResourceLibraryRole.component,
            description: 'Pièce détachée',
          ),
        ],
      ),
    );
    final host = await openSelectionHost(tester, manifest: project);
    Future<void> tap(String key) async {
      await tester.tap(keyed(key));
      await host.settle();
    }

    expect(keyed('library-search'), findsNothing);
    await tap('studio-rail-resources');
    expect(keyed('library-item-model3d:windmill'), findsOneWidget);
    expect(keyed('library-item-tileset:wheel'), findsNothing);
    expect(find.text('Pas encore utilisée'), findsNothing);

    await tap('library-role-component');
    expect(keyed('library-item-tileset:wheel'), findsOneWidget);
    expect(keyed('library-item-model3d:windmill'), findsNothing);
    final search = find.descendant(
      of: keyed('library-search'),
      matching: find.byType(TextField),
    );
    await tester.enterText(search, 'piece detachee');
    await host.settle();
    await tap('library-item-tileset:wheel');
    expect(find.text('Atelier › Roues'), findsWidgets);
    expect(find.text('Pièce détachée'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('returning from Resources retains the open map and its draft', (
    tester,
  ) async {
    final host = await openSelectionHost(tester);
    final active = host.maps.active!;
    active.commit(active.current.copyWith(name: 'Carte en cours'));

    await tester.tap(keyed('studio-rail-resources'));
    await host.settle();
    expect(keyed('library-search'), findsOneWidget);
    await tester.tap(keyed('studio-rail-map'));
    await host.settle();

    expect(host.maps.active, same(active));
    expect(active.current.name, 'Carte en cours');
    expect(active.dirty, isTrue);
  });

  testWidgets('a resource detail fits within a narrow Studio window', (
    tester,
  ) async {
    final project = selectionProject().copyWith(
      tilesets: [
        ProjectTilesetEntry(
          id: 'paving',
          name: 'Pavés',
          relativePath: 'assets/paving.png',
        ),
      ],
    );
    final host = await openSelectionHost(tester, manifest: project);
    const window = Size(1000, 720);
    tester.view.physicalSize = window;
    await host.settle();

    await tester.tap(keyed('studio-rail-resources'));
    await host.settle();
    await tester.enterText(
      find.descendant(
        of: keyed('library-search'),
        matching: find.byType(TextField),
      ),
      'Pavés',
    );
    await host.settle();
    await tester.tap(keyed('library-item-tileset:paving'));
    await host.settle();

    final detail = tester.getRect(keyed('library-detail-tileset:paving'));
    expect(detail.right, lessThanOrEqualTo(window.width));
    expect(find.text('Modifier'), findsNothing);
    expect(find.byTooltip('Autres actions'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _LibraryPort extends ScopedTestMapPort
    implements
        ProjectResourceLibraryPort,
        ProjectResourcePreviewPort,
        ProjectResourceLibraryMapUsagesPort {
  _LibraryPort({this.mapReport});

  final Future<Map<String, Set<String>>?>? mapReport;
  final previews = <String>[];
  String? usageRevision;

  @override
  Future<ProjectResourceLibrary> readResourceLibrary(
    ProjectSession session,
  ) async {
    final library = ProjectResourceLibrary.fromManifest(
      scopedMapMetadata.copyWith(
        elements: [workspaceElement],
        tilesets: mapReport == null ? [] : [scopedMapTilesets.last],
      ),
    );
    return ProjectResourceLibrary(
      library.catalog,
      library.items,
      revision: mapReport == null ? null : 'library-revision',
    );
  }

  @override
  Future<Map<String, Set<String>>?> readResourceLibraryMapUsages(
    ProjectSession session, {
    required String revision,
    required Iterable<String> identities,
  }) async {
    usageRevision = revision;
    return mapReport;
  }

  @override
  Future<ProjectManifest> readResourcePreview(
    ProjectSession session,
    String kind,
    String id,
  ) async {
    previews.add('$kind:$id');
    return workspaceProject.copyWith(maps: []);
  }
}

class _LibraryVisuals extends WorkspaceTestVisuals {
  @override
  Widget thumbnail(ProjectElementEntry element, {double size = 48}) =>
      SizedBox.square(key: ValueKey('preview-${element.id}'), dimension: size);
}
