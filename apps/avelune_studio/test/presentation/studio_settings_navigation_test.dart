import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'map_builder_shell_harness.dart';

void main() {
  testWidgets(
    'settings uses the editor rail and header without pushing a route',
    (tester) async {
      await openShell(tester);
      final settings = find.byKey(const ValueKey('studio-rail-settings'));
      final projectHome = find.byKey(const ValueKey('studio-project-home'));
      final map = find.byKey(const ValueKey('map-canvas'));
      final rail = find.byKey(const ValueKey('studio-rail'));
      final export = find.byKey(const ValueKey('studio-export-game'));
      final rootRoute = ModalRoute.of(tester.element(rail));
      final editorRail = tester.element(rail);

      expect(export, findsOneWidget);
      await tester.tap(settings);
      await tester.pumpAndSettle();
      expect(find.text('Réglages du Studio'), findsWidgets);
      expect(ModalRoute.of(tester.element(rail)), same(rootRoute));
      expect(tester.element(rail), same(editorRail));
      expect(export.hitTestable(), findsOneWidget);
      expect(map.hitTestable(), findsNothing);
      expect(find.byKey(const ValueKey('studio-settings-back')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('studio-rail-resources')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('studio-settings-language')),
        findsNothing,
      );
      expect(tester.element(rail), same(editorRail));
      await tester.tap(find.byKey(const ValueKey('studio-rail-map')));
      await tester.pumpAndSettle();
      expect(map, findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('studio-rail-home')));
      await settle(tester);
      expect(projectHome, findsOneWidget);
      expect(find.byKey(const ValueKey('home-export-game')), findsNothing);
      await tester.tap(settings);
      await tester.pumpAndSettle();
      expect(ModalRoute.of(tester.element(rail)), same(rootRoute));
      await tester.tap(find.byKey(const ValueKey('studio-rail-home')));
      await tester.pumpAndSettle();
      expect(projectHome, findsOneWidget);
      expect(sessions.requests, hasLength(1));
      expect(sessions.released, isEmpty);
      expect(visuals.disposed, isFalse);
    },
  );
}
