import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'support/ui11_workspace_harness.dart';
import 'ui11_presentation_widget_test.dart' show tapUi11;

void main() {
  testWidgets(
    'UI11 library visual ordering archives and restores the real asset',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final harness = (await tester.runAsync(
        () => Ui11WorkspaceHarness.create(tester),
      ))!;
      addTearDown(() => harness.shutdown(tester));
      await tester.pumpWidget(harness.app());
      await harness.settle(tester);
      final id = harness.controller.activeId!;
      final original = harness.controller.active!.asset;
      await tapUi11(tester, harness, find.text('Éléments'));
      await tapUi11(tester, harness, find.byTooltip('Devant : Illustration'));
      final moved = harness.controller.active!.asset;
      expect(
        moved.layers.firstWhere((l) => l.id == 'landscape').zIndex,
        greaterThan(moved.layers.firstWhere((l) => l.id == 'title').zIndex),
      );
      expect(moved.tracks, original.tracks);
      await tapUi11(tester, harness, find.byTooltip('Derrière : Illustration'));
      expect(
        harness.controller.active!.asset.layers,
        unorderedEquals(original.layers),
      );
      expect(harness.controller.active!.asset.tracks, original.tracks);
      await tapUi11(tester, harness, find.byTooltip('Annuler'));
      await tapUi11(tester, harness, find.byTooltip('Annuler'));
      expect(harness.controller.active!.asset, original);
      await tapUi11(tester, harness, find.text('Cinématiques').last);
      await tapUi11(
        tester,
        harness,
        find.byTooltip('Options de la présentation'),
      );
      await tapUi11(tester, harness, find.text('Archiver'));
      expect(harness.controller.error, isNull);
      expect(
        harness.controller.catalog
            .entryFor(CinematicLibraryFamily.presentation, id)!
            .isArchived,
        isTrue,
      );
      expect(find.byKey(ValueKey('presentation-entry-$id')), findsNothing);
      expect(
        find.text('Ouverte hors filtre : ${original.title}'),
        findsOneWidget,
      );
      await tapUi11(tester, harness, find.text('Archives'));
      expect(find.byKey(ValueKey('presentation-entry-$id')), findsOneWidget);
      await harness.capture(tester, 'ui11-07-library-archived');
      await tapUi11(tester, harness, find.text('Restaurer'));
      expect(
        harness.controller.catalog
            .entryFor(CinematicLibraryFamily.presentation, id)!
            .isArchived,
        isFalse,
      );
      final persisted = (await tester.runAsync(
        () => harness.port.delegate.load(id),
      ))!;
      expect(persisted.entry!.isArchived, isFalse);
      expect(persisted.asset, original);
      expect(tester.takeException(), isNull);
    },
  );
}
