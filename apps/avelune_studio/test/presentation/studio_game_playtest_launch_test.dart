import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/map_workspace/workspace_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/ui06_scene_fixture.dart';

void main() {
  testWidgets('full project launch and map launch retain separate routes', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(Ui06SceneFixture.create))!;
    addTearDown(fixture.dispose);
    final maps = MapWorkspaceController(fixture.session, fixture.maps);
    addTearDown(maps.dispose);
    await tester.runAsync(maps.initialize);
    late WorkspaceActions actions;
    var mapLaunches = 0;
    var projectLaunches = 0;
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
              runtimeBuilder: (_, _, close) {
                mapLaunches++;
                return Scaffold(
                  body: TextButton(
                    onPressed: close,
                    child: const Text('Fermer la carte'),
                  ),
                );
              },
              projectRuntimeBuilder: (close) {
                projectLaunches++;
                return Scaffold(
                  body: TextButton(
                    onPressed: close,
                    child: const Text('Fermer le jeu'),
                  ),
                );
              },
            );
            return const Scaffold(body: Text('Studio'));
          },
        ),
      ),
    );
    for (final fullProject in [true, false]) {
      late Future<void> running;
      final label = fullProject ? 'Fermer le jeu' : 'Fermer la carte';
      await tester.runAsync(() async {
        running = actions.test(fullProject: fullProject);
        for (var attempts = 0; attempts < 100 && !actions.testing; attempts++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      for (
        var attempts = 0;
        attempts < 100 && find.text(label).evaluate().isEmpty;
        attempts++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      expect(find.text(label), findsOneWidget);
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      await tester.runAsync(() => running);
    }
    expect(projectLaunches, 1);
    expect(mapLaunches, 1);
    expect(actions.testing, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
