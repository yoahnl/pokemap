import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'support/ui11_workspace_harness.dart';

void main() {
  testWidgets('UI11 real shared renderer early composition', (tester) async {
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
    expect(find.byKey(const ValueKey('presentation-canvas')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('presentation-canvas')));
    await harness.settle(tester);
    expect(
      harness.views.forAsset(harness.controller.active!.asset).selectedId,
      'title.clip',
    );
    await harness.capture(tester, 'ui11-01-early-composition');
    expect(harness.visuals.diagnostic, isNull);
    expect(harness.port.writes, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'UI11 blank to image text canvas timeline save and reopen via controls',
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
      await tapUi11(tester, harness, find.text('Nouvelle cinématique'));
      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == 'Nom',
        ),
        'Présentation de test',
      );
      await tapUi11(tester, harness, find.text('Créer'));
      await tapUi11(tester, harness, find.text('Composition vide'));
      final controller = harness.controller;
      final id = controller.activeId!;
      expect(controller.active!.asset.tracks, isEmpty);
      await tapUi11(tester, harness, find.text('Image').last);
      await tapUi11(tester, harness, find.text('Horizon Avelune').last);
      expect(
        controller.active!.asset.tracks,
        hasLength(1),
        reason: controller.error,
      );
      await tapUi11(tester, harness, find.text('Texte').last);
      expect(
        controller.active!.asset.tracks,
        hasLength(2),
        reason: controller.error,
      );
      final textId = controller.active!.asset.tracks
          .expand((t) => t.clips)
          .whereType<PresentationTextClip>()
          .single
          .id;
      final duration = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Durée (s)',
      );
      await tester.ensureVisible(duration);
      await tester.enterText(duration, '8');
      final content = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Contenu du texte',
      );
      await tester.ensureVisible(content);
      await tester.enterText(content, 'Été au port — こんにちは');
      await tapUi11(tester, harness, find.text('Enregistrer'));
      expect(controller.error, isNull);
      expect(controller.active!.dirty, isFalse);
      expect(harness.port.writes, 1);
      PresentationTextClip textClip() => controller.active!.asset.tracks
          .expand((t) => t.clips)
          .whereType<PresentationTextClip>()
          .single;
      expect(textClip().text, 'Été au port — こんにちは');
      expect(textClip().durationUs, 8000000);
      await tester.tap(find.byKey(const ValueKey('presentation-canvas')));
      await harness.settle(tester);
      expect(
        harness.views.forAsset(controller.active!.asset).selectedId,
        textId,
      );
      final bar = find.byKey(ValueKey('clip-$textId'));
      final gesture = await tester.startGesture(tester.getCenter(bar));
      await gesture.moveBy(const Offset(48, 0));
      await tester.pump();
      final editing = harness.views.forAsset(controller.active!.asset).editing;
      expect(editing.hasActiveDrag, isTrue);
      await gesture.moveBy(const Offset(60, 0));
      expect(editing.previewClip(textId).startUs, greaterThan(0));
      await gesture.up();
      await harness.settle(tester);
      expect(
        textClip().startUs,
        greaterThan(0),
        reason:
            '${controller.error}; ${harness.views.forAsset(controller.active!.asset).actionError}; bar ${tester.getRect(bar)}',
      );
      expect(textClip().durationUs, 8000000);
      await tapUi11(tester, harness, find.text('Enregistrer'));
      expect(controller.active!.dirty, isFalse, reason: controller.error);
      final saved = controller.active!.asset;
      final reopened = (await tester.runAsync(
        () => harness.port.delegate.load(id),
      ))!;
      expect(reopened.asset, saved);
      await tapUi11(
        tester,
        harness,
        find.byKey(ValueKey('presentation-entry-${harness.fixture.asset.id}')),
      );
      await tapUi11(
        tester,
        harness,
        find.byKey(ValueKey('presentation-entry-$id')),
      );
      expect(controller.active!.asset, saved);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> tapUi11(
  WidgetTester tester,
  Ui11WorkspaceHarness harness,
  Finder finder,
) async {
  await tester.pump();
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await harness.settle(tester);
}
