import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'support/ui11_workspace_harness.dart';
import 'ui11_presentation_widget_test.dart' show tapUi11;

void main() {
  testWidgets(
    'UI11 invalid focused duration blocks save and switching until corrected',
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
      await tapUi11(
        tester,
        harness,
        find.byKey(const ValueKey('presentation-canvas')),
      );
      final controller = harness.controller;
      final asset = controller.active!.asset;
      final view = harness.views.forAsset(asset);
      final duration = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Durée (s)',
      );
      await tester.ensureVisible(duration);
      await tester.enterText(duration, '-2');
      await tapUi11(tester, harness, find.text('Enregistrer'));
      expect(view.invalidFields, isNotEmpty);
      expect(controller.active!.asset, asset);
      expect(harness.port.writes, 0);
      await tapUi11(tester, harness, find.text('Enregistrer'));
      expect(harness.port.writes, 0);
      await tapUi11(tester, harness, find.text('Éléments'));
      expect(view.elements, isFalse);
      expect(view.selectedId, 'title.clip');
      await tester.ensureVisible(duration);
      await tester.enterText(duration, '8');
      await tapUi11(tester, harness, find.text('Enregistrer'));
      expect(view.invalidFields, isEmpty);
      expect(controller.error, isNull);
      expect(harness.port.writes, 1);
      final text = controller.active!.asset.tracks
          .expand((t) => t.clips)
          .whereType<PresentationTextClip>()
          .single;
      expect(text.durationUs, 8000000);
      expect(controller.active!.dirty, isFalse);
      await tapUi11(tester, harness, find.text('Éléments'));
      expect(view.elements, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
