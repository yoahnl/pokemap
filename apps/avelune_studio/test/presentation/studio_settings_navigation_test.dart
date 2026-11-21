import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'map_builder_shell_harness.dart';

void main() {
  testWidgets(
    'settings returns to the open project home without reopening it',
    (tester) async {
      await openShell(tester);
      final settings = find.byKey(const ValueKey('studio-rail-settings'));
      final back = find.byKey(const ValueKey('studio-settings-back'));
      final projectHome = find.byKey(const ValueKey('studio-project-home'));
      final map = find.byKey(const ValueKey('map-canvas'));

      expect(find.byKey(const ValueKey('studio-export-game')), findsOneWidget);
      await tester.tap(settings);
      await tester.pumpAndSettle();
      expect(find.text('Réglages du Studio'), findsWidgets);
      expect(map, findsNothing);
      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(map, findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('studio-rail-home')));
      await settle(tester);
      expect(projectHome, findsOneWidget);
      expect(find.byKey(const ValueKey('home-export-game')), findsNothing);
      await tester.tap(settings);
      await tester.pumpAndSettle();
      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(projectHome, findsOneWidget);
      expect(sessions.requests, hasLength(1));
      expect(sessions.released, isEmpty);
      expect(visuals.disposed, isFalse);
    },
  );
}
