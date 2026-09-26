import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_library_navigator.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_library_row_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/m2_ui_fixture.dart';

void main() {
  testWidgets('folder creation and map move survive independent reopening', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = (await tester.runAsync(() => M2UiFixture.create(tester)))!;
    addTearDown(fixture.dispose);
    final source = File('${fixture.directory.path}/maps/jardin.json');
    final beforeMap = source.readAsBytesSync();
    final secondSource = File('${fixture.directory.path}/maps/clairiere.json');
    final beforeSecondMap = secondSource.readAsBytesSync();
    await tester.pumpWidget(fixture.app(tester));
    await pumpIo(tester);

    expect(find.byType(MapLibraryNavigator), findsOneWidget);
    expect(find.byKey(const ValueKey('map-library-jardin')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('Nouveau dossier')));
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nom du dossier'),
      'Jardins',
    );
    await tester.tap(find.text('Créer'));
    await pumpIo(tester);
    expect(find.text('Jardins'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('Nouveau dossier')));
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nom du dossier'),
      'Parc',
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jardins').last);
    await tester.pump();
    await tester.tap(find.text('Créer'));
    await pumpIo(tester);
    expect(fixture.controller.project!.groups.length, 2);

    await tester.tap(find.byKey(const ValueKey('Sélection multiple')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('map-library-jardin')));
    await tester.tap(find.byKey(const ValueKey('map-library-clairiere')));
    await tester.pump();
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Parc').last);
    await tester.pump();
    await tester.tap(find.text('Déplacer les cartes'));
    await pumpIo(tester);

    final groups = fixture.controller.project!.groups;
    expect(
      groups.singleWhere((group) => group.name == 'Parc').parentGroupId,
      groups.singleWhere((group) => group.name == 'Jardins').id,
    );
    expect(
      fixture.controller.project!.maps.every(
        (map) =>
            map.groupId ==
            groups.singleWhere((group) => group.name == 'Parc').id,
      ),
      isTrue,
    );
    expect(source.readAsBytesSync(), beforeMap);
    expect(secondSource.readAsBytesSync(), beforeSecondMap);
    await fixture.capture(tester, 'map-library-grouped-1536');
    final reopened = MapWorkspaceController(
      fixture.session,
      LocalMapWorkspaceAdapter(),
    );
    await tester.runAsync(reopened.initialize);
    expect(
      reopened.project!.maps.every(
        (map) =>
            map.groupId ==
            reopened.project!.groups
                .singleWhere((group) => group.name == 'Parc')
                .id,
      ),
      isTrue,
    );
    reopened.dispose();
    expect(tester.takeException(), isNull);
    expect(find.byType(MapLibraryRowTile), findsWidgets);

    tester.view.physicalSize = const Size(1024, 640);
    await tester.pumpWidget(fixture.app(tester, textScale: 1.5));
    await pumpIo(tester);
    expect(find.byType(MapLibraryNavigator), findsNothing);
    await fixture.capture(tester, 'map-library-compact-1024');
    await tester.tap(find.byKey(const ValueKey('Dossiers de cartes')));
    await tester.pumpAndSettle();
    expect(find.byType(MapLibraryNavigator), findsOneWidget);
    expect(find.byKey(const ValueKey('map-library-jardin')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
