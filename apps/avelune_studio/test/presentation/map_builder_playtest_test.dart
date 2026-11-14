import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/app/di/map_workspace_providers.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/features/playtest/contracts/studio_playtest_controls.dart';
import 'package:avelune_studio/presentation/features/map_builder/studio_playtest_performance.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_playtest_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/controlled_project_session_port.dart';
import '../support/map_workspace_fixture.dart';
import 'map_builder_playtest_harness.dart';

void main() {
  testWidgets('testing a changed map saves it then plays the saved revision', (
    tester,
  ) async {
    await openShell(tester);
    final controller = container.read(mapWorkspaceControllerProvider(exampleA));
    final document = controller.active!;
    document.commit(document.current.copyWith(name: 'Clairière modifiée'));
    controller.notify();
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('studio-test-map')));
    await settle(tester);

    expect(maps.writes, 1);
    expect(launches, hasLength(1));
    expect(launches.single.entry.id, 'a');
    expect(launches.single.revision, document.base.revision);
    expect(launches.single.revision, 'r1');
    expect(find.byKey(const ValueKey('fake-game')), findsOneWidget);
    await transition(tester);
    expect(find.text('Test de ${launches.single.entry.name}'), findsOneWidget);
    expect(find.byKey(const ValueKey('map-builder')), findsNothing);
  });

  testWidgets('a refused save keeps the author in the editor', (tester) async {
    await openShell(tester);
    final controller = container.read(mapWorkspaceControllerProvider(exampleA));
    final document = controller.active!;
    document.commit(document.current.copyWith(name: 'Clairière modifiée'));
    maps.failSave = true;
    controller.notify();
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('studio-test-map')));
    await settle(tester);

    expect(launches, isEmpty);
    expect(find.byKey(const ValueKey('map-playtest')), findsNothing);
    expect(find.text('Échec de l’enregistrement'), findsOneWidget);
    expect(button(tester, 'studio-test-map').onPressed, isNotNull);
  });

  testWidgets('an unchanged map plays without saving', (tester) async {
    await openShell(tester);

    await tester.tap(find.byKey(const ValueKey('studio-test-map')));
    await settle(tester);

    expect(maps.writes, 0);
    expect(launches.single.revision, 'r0');
  });

  testWidgets('the test bar follows the game and returns to the map', (
    tester,
  ) async {
    await openShell(tester);
    await tester.tap(find.byKey(const ValueKey('studio-test-map')));
    await transition(tester);

    for (final key in [
      'map-playtest-new-game',
      'map-playtest-save',
      'map-playtest-resume',
    ]) {
      expect(button(tester, key).onPressed, isNull);
    }
    expect(find.byKey(const ValueKey('map-playtest-speed-1')), findsNothing);

    publish(tester, const StudioPlaytestStatus(ready: true));
    await tester.pump();
    expect(button(tester, 'map-playtest-resume').onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('map-playtest-speed-5')));
    await tester.tap(find.byKey(const ValueKey('map-playtest-save')));
    await tester.tap(find.byKey(const ValueKey('map-playtest-new-game')));
    await tester.pump();
    expect(calls, ['speed:5', 'save', 'new']);
    expect(button(tester, 'map-playtest-speed-5').onPressed, isNull);
    expect(find.byKey(const ValueKey('map-playtest-pause')), findsNothing);

    publish(
      tester,
      const StudioPlaytestStatus(
        ready: true,
        hasSave: true,
        spatial: true,
        paused: true,
        message: 'Test enregistré en mémoire pour cette session.',
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('map-playtest-speed-1')), findsNothing);
    expect(find.text('Continuer'), findsOneWidget);
    expect(find.text('Activer les diagonales'), findsOneWidget);
    expect(
      find.text('Test enregistré en mémoire pour cette session.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('map-playtest-resume')));
    await tester.tap(find.byKey(const ValueKey('map-playtest-pause')));
    await tester.tap(find.byKey(const ValueKey('map-playtest-diagonal')));
    await tester.pump();
    expect(calls.skip(3), ['resume', 'pause', 'diagonal']);

    await tester.tap(find.byKey(const ValueKey('map-playtest-back')));
    await transition(tester);
    expect(find.byKey(const ValueKey('map-playtest')), findsNothing);
    expect(find.byKey(const ValueKey('map-builder')), findsOneWidget);
    expect(button(tester, 'studio-test-map').onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('studio-test-map')));
    await transition(tester);
    expect(launches, hasLength(2));
    expect(runtimes, 1);
  });

  testWidgets('the test bar shows the measured frame rate', (tester) async {
    final performance = PlaytestPerformance();
    addTearDown(performance.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MapBuilderPlaytestPage(
          entry: workspaceProject.maps.first,
          revision: 'r0',
          performance: performance,
          runtime: (entry, revision, controls, close) =>
              const SizedBox(key: ValueKey('fake-game')),
          onClose: () {},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('map-playtest-performance')),
      findsNothing,
    );
    performance.publish(
      const StudioPlaytestPerformanceSample(
        fps: 59.6,
        buildMs: 2.04,
        rasterMs: 6.27,
      ),
    );
    await tester.pump();
    expect(find.text('60 FPS · UI 2.0 ms · rendu 6.3 ms'), findsOneWidget);
  });
}
