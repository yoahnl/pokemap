import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/m2_ui_fixture.dart';
import '../support/uwu5_border_host.dart';

void main() {
  for (final size in const [
    Size(1536, 1024),
    Size(1280, 800),
    Size(1024, 640),
  ]) {
    testWidgets('border management stays usable at ${size.width}', (
      tester,
    ) async {
      final host = await openUwU5BorderHost(
        tester,
        size: size,
        textScale: size.width == 1024 ? 1.5 : 1,
      );
      await host.fixture.capture(
        tester,
        'uwu5-host-border-library-${size.width.toInt()}',
      );
      expect(
        find.byKey(const ValueKey('resource-card-decors:tree')),
        findsOneWidget,
      );
      if (find
          .byKey(const ValueKey('resource-border-library'))
          .evaluate()
          .isNotEmpty) {
        await host.tap('resource-border-library');
      }
      expect(find.text('Brouillons'), findsOneWidget);
      expect(find.text('Publiées'), findsOneWidget);
      expect(find.text('Dépréciées'), findsOneWidget);
      await tester.tap(find.text('Publiées'));
      await pumpIo(tester);
      await host.tap('border-resource-actions-garden-fence');
      await tester.tap(find.text('Déprécier…'));
      await pumpIo(tester);
      await host.fixture.capture(
        tester,
        'uwu5-host-border-deprecate-${size.width.toInt()}',
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
