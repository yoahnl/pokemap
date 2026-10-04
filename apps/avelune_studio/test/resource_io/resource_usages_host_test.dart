import 'dart:io';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_usage_results.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import '../support/m2_ui_fixture.dart';
import '../support/uwu_resource_host.dart';

void main() {
  testWidgets(
    'real usage request reads closed maps without writes and locates exact owner',
    (tester) async {
      final host = await UwUResourceHost.open(tester);
      await host.family(ResourceKind.images);
      final original = await tester.runAsync(
        () =>
            File('${host.fixture.directory.path}/project.json').readAsString(),
      );
      expect(
        host.fixture.controller.documents.containsKey('clairiere'),
        isFalse,
      );
      await host.action('images:atelier', 'Voir les usages dans le projet');
      expect(find.text('Non analysé'), findsOneWidget);
      expect(
        tester
            .widget<ResourceUsageResults>(find.byType(ResourceUsageResults))
            .report,
        isNull,
      );
      await host.tap('resource-usage-analyze');
      final results = tester.widget<ResourceUsageResults>(
        find.byType(ResourceUsageResults),
      );
      expect(results.report, isNotNull);
      expect(
        results.report!.entries.any((entry) => entry.mapId == 'clairiere'),
        isTrue,
      );
      expect(
        host.fixture.controller.documents.containsKey('clairiere'),
        isFalse,
      );
      expect(
        await tester.runAsync(
          () => File(
            '${host.fixture.directory.path}/project.json',
          ).readAsString(),
        ),
        original,
      );
      await host.fixture.capture(tester, 'uwu3-closed-map-usages');
      final entry = results.report!.entries.firstWhere(
        (entry) => entry.mapId == 'clairiere',
      );
      await host.openUsage(entry);
      expect(host.fixture.controller.active!.current.id, 'clairiere');
      await tester.tap(find.byTooltip('Ressources').first);
      await pumpIo(tester, frames: 6);
      expect(host.navigation.library.selectedIdentity, 'images:atelier');
    },
  );

  testWidgets(
    'unsaved map usage remains explicit and analysis never saves it',
    (tester) async {
      final host = await UwUResourceHost.open(tester);
      final document = host.fixture.controller.active!;
      final before = document.saved;
      MapEditingCommands(document, host.fixture.controller.project!).place(
        host.fixture.controller.project!.elements.first,
        const GridPos(x: 16, y: 10),
      );
      expect(document.dirty, isTrue);
      final undo = document.undoCount;
      await host.family(ResourceKind.images);
      await host.action('images:atelier', 'Voir les usages dans le projet');
      await host.tap('resource-usage-analyze');
      expect(find.text('Analyse incomplète'), findsOneWidget);
      expect(find.textContaining('Brouillons non analysés'), findsOneWidget);
      expect(document.saved, before);
      expect(document.dirty, isTrue);
      expect(document.undoCount, undo);
    },
  );

  testWidgets('changed owner revision becomes stale before navigation', (
    tester,
  ) async {
    final host = await UwUResourceHost.open(tester);
    await host.family(ResourceKind.images);
    await host.action('images:atelier', 'Voir les usages dans le projet');
    await host.tap('resource-usage-analyze');
    final result = tester.widget<ResourceUsageResults>(
      find.byType(ResourceUsageResults),
    );
    final entry = result.report!.entries.firstWhere(
      (entry) => entry.mapId == 'clairiere',
    );
    await tester.runAsync(
      () => File(
        '${host.fixture.directory.path}/maps/clairiere.json',
      ).writeAsString('{}'),
    );
    await host.openUsage(entry);
    expect(find.text('Résultat périmé · relancez l’analyse'), findsOneWidget);
    expect(host.fixture.controller.active!.current.id, 'jardin');
    expect(find.text('Ouvrir le propriétaire'), findsNothing);
  });
}
