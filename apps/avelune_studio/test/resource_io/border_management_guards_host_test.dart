import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/resources/resource_navigation.dart';
import 'package:avelune_studio/presentation/features/resources/resource_usage_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/m2_ui_fixture.dart';
import '../support/uwu5_border_host.dart';

void main() {
  testWidgets(
    'dirty border editor blocks withdrawal without losing focused input',
    (tester) async {
      final host = await openUwU5BorderHost(tester);
      final before = await host.reopen();
      await tester.tap(find.text('Reprendre « Préparation des essais »'));
      await pumpIo(tester);
      await host.enter('border-name', 'Mon brouillon focalisé');
      await expectLater(
        host.navigation.prepareOperation('border.blueprint.delete', {
          'blueprintId': 'unfinished-fence',
        }),
        throwsA(
          isA<ResourceFailure>().having(
            (failure) => failure.message,
            'owner',
            contains('Préparation des essais'),
          ),
        ),
      );
      await tester.tap(find.text('Fermer').last);
      await pumpIo(tester);
      await tester.tap(find.text('Conserver'));
      await pumpIo(tester);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('border-name')))
            .controller!
            .text,
        'Mon brouillon focalisé',
      );
      expect((await host.reopen()).borderCatalog, before.borderCatalog);
      await tester.tap(find.text('Fermer').last);
      await pumpIo(tester);
      await tester.tap(find.text('Abandonner'));
      await pumpIo(tester);
      expect(host.navigation.borderEditorOwners, isEmpty);
    },
  );

  testWidgets('stale border confirmation refuses and preserves publication', (
    tester,
  ) async {
    final host = await openUwU5BorderHost(tester);
    final before = (await host.reopen()).borderCatalog.records.first;
    await host.tap('border-resource-actions-garden-fence');
    await tester.tap(find.text('Déprécier…'));
    await pumpIo(tester);
    await WidgetResourcePort.serial(
      tester,
      () => host.fixture.resources.createBorder(
        const BorderCreationRequest(
          blueprintId: 'concurrent-preparation',
          name: 'Travail concurrent',
          publish: false,
        ),
      ),
    );
    await host.tap('resource-border-confirm');
    await host.tap('resource-management-save');
    expect(
      find.byKey(const ValueKey('resource-management-error')),
      findsOneWidget,
    );
    expect(
      (await host.reopen()).borderCatalog.records.singleWhere(
        (record) => record.id == 'garden-fence',
      ),
      before,
    );
    expect((await host.reopen()).borderCatalog.records, hasLength(3));
  });

  testWidgets(
    'border usage inspection targets the actual blueprint and does not write',
    (tester) async {
      final host = await openUwU5BorderHost(tester);
      final before = await host.reopen();
      await host.tap('border-resource-actions-garden-fence');
      await tester.tap(find.text('Voir les usages dans le projet').last);
      await pumpIo(tester);
      expect(find.text('Non analysé'), findsOneWidget);
      await host.tap('resource-usage-analyze');
      final target = tester
          .widget<ResourceUsageDialog>(find.byType(ResourceUsageDialog))
          .resolvedTarget;
      expect(target.family, 'borders');
      expect(target.id, 'garden-fence');
      expect(find.text('Complet pour la révision identifiée'), findsOneWidget);
      expect((await host.reopen()).borderCatalog, before.borderCatalog);
    },
  );
}
