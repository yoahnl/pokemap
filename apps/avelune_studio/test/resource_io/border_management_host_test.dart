import 'package:flutter_test/flutter_test.dart';
import '../support/uwu5_border_host.dart';
import '../support/m2_ui_fixture.dart';

void main() {
  testWidgets(
    'unpublished border withdrawal preserves publication and pixels',
    (tester) async {
      final host = await openUwU5BorderHost(tester);
      final before = await host.reopen();
      await host.tap('border-resource-actions-unfinished-fence');
      await tester.tap(find.text('Retirer la préparation…'));
      await pumpIo(tester);
      await host.tap('resource-border-confirm');
      await host.tap('resource-management-save');
      final after = await host.reopen();
      expect(after.borderCatalog.records, hasLength(1));
      expect(
        after.borderCatalog.records.single,
        before.borderCatalog.records.first,
      );
      expect(after.tilesets, before.tilesets);
      expect(after.elements, before.elements);
    },
  );

  testWidgets('deprecation and reactivation preserve immutable publication', (
    tester,
  ) async {
    final host = await openUwU5BorderHost(tester);
    final before = (await host.reopen()).borderCatalog.records.first;
    await tester.tap(find.text('Publiées'));
    await pumpIo(tester);
    await host.tap('border-resource-actions-garden-fence');
    expect(find.text('Retirer la préparation…'), findsNothing);
    await tester.tap(find.text('Déprécier…'));
    await pumpIo(tester);
    await host.tap('resource-border-confirm');
    await host.tap('resource-management-save');
    final deprecated = (await host.reopen()).borderCatalog.records.first;
    expect(deprecated.isDeprecated, isTrue);
    expect(deprecated.draft, before.draft);
    expect(deprecated.latestPublished, before.latestPublished);
    await tester.tap(find.text('Dépréciées'));
    await pumpIo(tester);
    await host.tap('border-resource-actions-garden-fence');
    await tester.tap(find.text('Réactiver…'));
    await pumpIo(tester);
    await host.tap('resource-border-confirm');
    await host.tap('resource-management-save');
    expect((await host.reopen()).borderCatalog.records.first, before);
  });
}
