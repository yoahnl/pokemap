import 'dart:io';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_usage_results.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import '../support/m2_ui_fixture.dart';
import '../support/uwu4_resource_host.dart';
import '../support/uwu_resource_host.dart';
import 'resource_fixture.dart';

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
      await host.action('tileset:atelier', 'Voir les usages dans le projet');
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
      expect(host.navigation.library.selectedIdentity, 'tileset:atelier');
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
      await host.action('tileset:atelier', 'Voir les usages dans le projet');
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
    await host.action('tileset:atelier', 'Voir les usages dans le projet');
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

  testWidgets(
    'a used decor removal is blocked with its usage count and leads to its usages',
    (tester) async {
      final host = await openUwU4ResourceHost(tester, placed: true);
      final before = await host.reopen();
      await host.action('element:tree', 'Supprimer la définition…');
      await pumpIo(tester, frames: 20);
      final refusal = tester
          .widget<Text>(find.byKey(const ValueKey('resource-removal-refusal')))
          .data!;
      expect(refusal, contains('Ce décor est encore utilisé dans le projet'));
      expect(refusal, contains('(1 usage)'));
      expect(refusal, contains('« Voir les usages dans le projet »'));
      expect(refusal, isNot(contains('VisualLibraryException')));
      expect(
        tester
            .widget<StudioButton>(
              find.byKey(const ValueKey('resource-management-save')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Voir les usages dans le projet').last);
      await pumpIo(tester, frames: 12);
      expect(find.text('Usages dans le projet'), findsOneWidget);
      expect(find.text('Non analysé'), findsOneWidget);
      await host.tap('resource-usage-analyze');
      final report = tester
          .widget<ResourceUsageResults>(find.byType(ResourceUsageResults))
          .report!;
      expect(report.target.id, 'tree');
      expect(
        report.entries.map((entry) => entry.entityId),
        contains('placed-tree'),
      );
      final after = await host.reopen();
      expect(after.elements, before.elements);
      expect(after.tilesets, before.tilesets);
    },
  );

  testWidgets('a planche used by a decor is blocked with the same guidance', (
    tester,
  ) async {
    final host = await openUwU4ResourceHost(tester);
    final before = await host.reopen();
    await host.family(ResourceKind.images);
    await host.action(
      'tileset:${before.tilesets.single.id}',
      'Supprimer la planche…',
    );
    await pumpIo(tester, frames: 20);
    final refusal = tester
        .widget<Text>(find.byKey(const ValueKey('resource-removal-refusal')))
        .data!;
    expect(
      refusal,
      contains('Cette planche est encore utilisée dans le projet'),
    );
    expect(refusal, contains('« Voir les usages dans le projet »'));
    await host.tap('resource-management-cancel');
    expect((await host.reopen()).tilesets, before.tilesets);
  });

  testWidgets('an unused decor removal stays available without refusal', (
    tester,
  ) async {
    final host = await openUwU4ResourceHost(tester);
    await host.action('element:tree', 'Supprimer la définition…');
    await pumpIo(tester, frames: 20);
    expect(
      find.byKey(const ValueKey('resource-removal-refusal')),
      findsNothing,
    );
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('resource-removal-confirm')),
          )
          .onChanged,
      isNotNull,
    );
    await host.tap('resource-management-cancel');
    expect((await host.reopen()).elements.single.id, 'tree');
  });

  testWidgets(
    'a removal analysed before the decor was placed is refused at confirmation',
    (tester) async {
      late ResourceFixture resources;
      final host = await openUwU4ResourceHost(
        tester,
        configure: (fixture) async => resources = fixture,
      );
      await host.action('element:tree', 'Supprimer la définition…');
      await pumpIo(tester, frames: 20);
      expect(find.textContaining('Révision : '), findsOneWidget);
      await tester.runAsync(() async {
        final document = await resources.loadMap();
        await resources.maps.saveMap(
          resources.session,
          document,
          document.map.copyWith(
            placedElements: const [
              MapPlacedElement(
                id: 'late-tree',
                layerId: 'ground',
                elementId: 'tree',
                pos: GridPos(x: 2, y: 2),
              ),
            ],
          ),
        );
      });
      final placed = await tester.runAsync(resources.mapFile.readAsBytes);
      await host.tap('resource-removal-confirm');
      await host.tap('resource-management-save');
      expect(
        find.byKey(const ValueKey('resource-management-error')),
        findsOneWidget,
      );
      final reopened = await host.reopen();
      expect(reopened.elements.single.id, 'tree');
      expect(await tester.runAsync(resources.mapFile.readAsBytes), placed);
    },
  );
}
