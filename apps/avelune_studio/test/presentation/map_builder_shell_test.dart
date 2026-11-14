import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/app/di/map_workspace_providers.dart';
import 'package:avelune_studio/app/di/project_session_providers.dart';
import 'package:avelune_studio/presentation/shell/studio_root.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/controlled_project_session_port.dart';
import 'map_builder_shell_harness.dart';

void main() {
  testWidgets('home offers only the project import and opens the map builder', (
    tester,
  ) async {
    await openShell(tester);

    expect(picked, 1);
    expect(sessions.requests, [exampleA.directoryPath]);
    expect(find.byKey(const ValueKey('map-builder')), findsOneWidget);
    expect(find.byKey(const ValueKey('studio-rail')), findsOneWidget);
    expect(find.byKey(const ValueKey('map-library')), findsOneWidget);
    expect(find.byKey(const ValueKey('map-inspector')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('studio-top-bar')),
        matching: find.text('Clairière'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('map-canvas')), findsOneWidget);
    for (final label in ['Construction', 'Jeu', 'Scénario', 'Ambiance']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('a home without a chosen folder stays on the import page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final port = ControlledProjectSessionPort();
    final scope = ProviderContainer(
      overrides: [
        projectSessionPortProvider.overrideWithValue(port),
        projectDirectoryPickerProvider.overrideWithValue(() async => null),
      ],
    );
    addTearDown(scope.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: scope,
        child: MaterialApp(theme: studioTheme(), home: const StudioRoot()),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('studio-home-import')));
    await tester.pump();

    expect(port.requests, isEmpty);
    expect(find.byKey(const ValueKey('studio-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('map-builder')), findsNothing);
  });

  testWidgets('the map list and the top bar switch the active map', (
    tester,
  ) async {
    await openShell(tester);
    await tester.tap(find.byKey(const ValueKey('map-library-tab-Cartes')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('map-library-map-b')));
    await settle(tester);

    expect(
      container
          .read(mapWorkspaceControllerProvider(exampleA))
          .active
          ?.base
          .mapId,
      'b',
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('studio-top-bar')),
        matching: find.text('Jardin'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('map-inspector')),
        matching: find.text('Jardin'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('undo, save state and save follow the active map document', (
    tester,
  ) async {
    await openShell(tester);
    final controller = container.read(mapWorkspaceControllerProvider(exampleA));

    expect(barIcon(tester, 'Annuler la modification').onPressed, isNull);
    expect(find.text('Enregistré'), findsOneWidget);
    final saveButton = find.byKey(const ValueKey('studio-save'));
    expect(tester.widget<StudioButton>(saveButton).onPressed, isNull);

    final document = controller.active!;
    document.commit(document.current.copyWith(name: 'Clairière modifiée'));
    controller.notify();
    await tester.pump();

    expect(find.text('Non enregistré'), findsOneWidget);
    expect(barIcon(tester, 'Annuler la modification').onPressed, isNotNull);
    await tester.tap(saveButton);
    await settle(tester);

    expect(maps.writes, 1);
    expect(find.text('Enregistré'), findsOneWidget);

    await tester.tap(find.byTooltip('Annuler la modification'));
    await tester.pump();
    expect(controller.active!.current.name, isNot('Clairière modifiée'));
    expect(find.text('Non enregistré'), findsOneWidget);
  });

  testWidgets('the visuals follow the active map', (tester) async {
    await openShell(tester);
    expect(visuals.activatedMaps, ['a']);

    await tester.tap(find.byKey(const ValueKey('map-library-tab-Cartes')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('map-library-map-b')));
    await settle(tester);

    expect(visuals.activatedMaps.last, 'b');
  });

  testWidgets('only a refused save shows the save failure', (tester) async {
    await openShell(tester);
    final controller = container.read(mapWorkspaceControllerProvider(exampleA));
    final document = controller.active!;

    document.error = 'Aperçu indisponible';
    controller.notify();
    await tester.pump();
    expect(find.text('Enregistré'), findsOneWidget);

    document.commit(document.current.copyWith(name: 'Clairière modifiée'));
    maps.failSave = true;
    controller.notify();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('studio-save')));
    await settle(tester);
    expect(find.text('Échec de l’enregistrement'), findsOneWidget);
    expect(maps.writes, 0);

    maps.failSave = false;
    await tester.tap(find.byKey(const ValueKey('studio-save')));
    await settle(tester);
    expect(find.text('Enregistré'), findsOneWidget);
    expect(maps.writes, 1);
  });

  testWidgets('space tabs, tools and the inspector toggle respond', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await openShell(tester);
    final view = find.byKey(const ValueKey('map-space-gameplay'));

    expect(tester.getSemantics(view), isNot(isSemantics(isSelected: true)));
    await tester.tap(view);
    await tester.pump();
    expect(tester.getSemantics(view), isSemantics(isSelected: true));

    await tester.tap(find.byKey(const ValueKey('map-tool-pan')));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('map-status-tool'))).data,
      'Déplacer la vue',
    );

    await tester.tap(find.byKey(const ValueKey('map-inspector-toggle')));
    await tester.pump();
    expect(find.byKey(const ValueKey('map-inspector')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('map-inspector-toggle')));
    await tester.pump();
    expect(find.byKey(const ValueKey('map-inspector')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the game, story and ambiance spaces open their own panels', (
    tester,
  ) async {
    await openShell(tester);
    expect(find.byKey(const ValueKey('map-library')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('map-space-gameplay')));
    await tester.pump();
    for (final rubric in [
      'connections',
      'movement',
      'encounters',
      'spawns',
      'fieldObjects',
    ]) {
      expect(find.byKey(ValueKey('map-space-rubric-$rubric')), findsOneWidget);
    }
    expect(find.text('Bientôt'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('map-space-story')));
    await tester.pump();
    expect(find.byKey(const ValueKey('map-library')), findsNothing);
    expect(find.byKey(const ValueKey('map-story-search')), findsOneWidget);
    expect(
      find.text('Pas encore disponible dans le nouveau Studio'),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('map-space-inspector')),
        matching: find.text('ÉVÉNEMENT'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('map-space-ambiance')));
    await tester.pump();
    expect(find.byKey(const ValueKey('map-space-panel')), findsOneWidget);
    expect(
      tester
          .widget<StudioChoice>(
            find.byKey(const ValueKey('map-space-rubric-music')),
          )
          .onTap,
      isNotNull,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('map-ambiance-inspector')),
        matching: find.text('AMBIANCE DE LA CARTE'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('map-space-construction')));
    await tester.pump();
    expect(find.byKey(const ValueKey('map-library')), findsOneWidget);
    expect(find.byKey(const ValueKey('map-space-inspector')), findsNothing);
  });

  testWidgets('the home rail entry closes the project and frees its visuals', (
    tester,
  ) async {
    await openShell(tester);
    await tester.tap(find.byTooltip('Accueil du projet'));
    await settle(tester);

    expect(sessions.released, [exampleA]);
    expect(find.byKey(const ValueKey('studio-home')), findsOneWidget);
    expect(visuals.disposed, isTrue);
  });
}
