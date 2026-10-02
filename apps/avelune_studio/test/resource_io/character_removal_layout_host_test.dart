import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/uwu5_character_host.dart';

void main() {
  for (final size in const [
    Size(1536, 1024),
    Size(1280, 800),
    Size(1024, 640),
  ]) {
    testWidgets('character removal keeps actions accessible at ${size.width}', (
      tester,
    ) async {
      final host = await openUwU5CharacterHost(
        tester,
        size: size,
        textScale: size.width == 1024 ? 1.5 : 1,
      );
      await host.fixture.capture(
        tester,
        'uwu5-host-character-library-${size.width.toInt()}',
      );
      expect(
        find.byKey(const ValueKey('character-studio-libre')),
        findsOneWidget,
      );
      await host.tap('character-studio-remove');
      await host.fixture.capture(
        tester,
        'uwu5-host-character-removal-${size.width.toInt()}',
      );
      expect(
        find.byKey(const ValueKey('resource-management-save')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('resource-management-cancel')),
        findsOneWidget,
      );
      await host.tap('resource-management-cancel');
      expect(tester.takeException(), isNull);
    });
  }
}
