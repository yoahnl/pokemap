import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'uwu5_source_removal_dialog_support.dart';

void main() {
  const source = 'resource-removal-source';
  const confirm = 'resource-removal-confirm';
  const submit = 'resource-management-save';

  testWidgets('source off on off invalidates plans and confirms only off', (
    tester,
  ) async {
    final host = RemovalDialogHarness();
    await host.open(tester);
    expect(host.analyses.single.removeSource, isFalse);
    expect(host.checkbox(tester, source).value, isFalse);
    await host.ready(tester);
    await host.tap(tester, confirm);
    expect(host.canSubmit(tester), isTrue);
    await host.tap(tester, source);
    expect(host.checkbox(tester, source).value, isTrue);
    expect(host.checkbox(tester, source).onChanged, isNull);
    expect(host.checkbox(tester, confirm).value, isFalse);
    expect(host.canSubmit(tester), isFalse);
    await host.ready(tester);
    expect(host.checkbox(tester, source).onChanged, isNotNull);
    expect(find.textContaining('son fichier seront retirés'), findsOneWidget);
    await host.tap(tester, confirm);
    await host.tap(tester, source);
    expect(host.checkbox(tester, source).value, isFalse);
    expect(host.checkbox(tester, confirm).value, isFalse);
    expect(host.canSubmit(tester), isFalse);
    await host.ready(tester);
    expect(find.textContaining('La source reste conservée'), findsOneWidget);
    await host.tap(tester, confirm);
    await host.tap(tester, submit);
    expect(host.analyses.map((a) => a.removeSource), [false, true, false]);
    expect(host.applied.single.parameters['removeSource'], isFalse);
    expect(host.applied.single.changedPaths, ['project.json']);
  });

  testWidgets('confirmed source removal applies the exact analyzed plan', (
    tester,
  ) async {
    final host = RemovalDialogHarness();
    await host.open(tester);
    await host.ready(tester);
    await host.tap(tester, source);
    final current = host.analyses.last;
    final plan = host.preparation(current);
    current.result.complete(plan);
    await tester.pumpAndSettle();
    expect(host.canSubmit(tester), isFalse);
    expect(
      find.textContaining('source logique et son fichier'),
      findsOneWidget,
    );
    expect(find.textContaining('Le blob est conservé'), findsOneWidget);
    await host.tap(tester, confirm);
    await host.tap(tester, submit);
    expect(host.applied.single, same(plan));
    expect(host.applied.single.parameters['removeSource'], isTrue);
    expect(host.applied.single.changedPaths, contains('assets/planche.png'));
  });

  for (final mode in ['erreur', 'capacité perdue']) {
    testWidgets('$mode disarms removal and allows explicit source retention', (
      tester,
    ) async {
      final host = RemovalDialogHarness();
      await host.open(tester);
      await host.ready(tester);
      await host.tap(tester, source);
      if (mode == 'erreur') {
        host.analyses.last.result.completeError(StateError('source partagée'));
        await tester.pumpAndSettle();
      } else {
        await host.ready(
          tester,
          capability: false,
          sourceRemoved: false,
          reason: 'La source est devenue partagée.',
        );
      }
      expect(host.checkbox(tester, source).value, isTrue);
      expect(host.checkbox(tester, source).onChanged, isNotNull);
      expect(host.canSubmit(tester), isFalse);
      expect(host.checkbox(tester, confirm).value, isFalse);
      expect(host.checkbox(tester, confirm).onChanged, isNull);
      await host.tap(tester, source);
      await host.ready(tester, capability: false, sourceRemoved: false);
      expect(host.checkbox(tester, source).value, isFalse);
      await host.tap(tester, confirm);
      await host.tap(tester, submit);
      expect(host.applied.single.parameters['removeSource'], isFalse);
    });
  }

  testWidgets('cancel accepts no mutation and ignores a late analysis', (
    tester,
  ) async {
    final host = RemovalDialogHarness();
    await host.open(tester);
    await host.ready(tester);
    await host.tap(tester, source);
    final delayed = host.analyses.last;
    await host.tap(tester, 'resource-management-cancel');
    delayed.result.complete(host.preparation(delayed));
    await tester.pumpAndSettle();
    expect(host.applied, isEmpty);
    expect(find.byKey(const ValueKey(source)), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final capacity in [false, null]) {
    testWidgets('capacity $capacity never permits choosing a source removal', (
      tester,
    ) async {
      final host = RemovalDialogHarness();
      await host.open(tester);
      await host.ready(tester, capability: capacity, sourceRemoved: false);
      expect(host.checkbox(tester, source).value, isFalse);
      expect(host.checkbox(tester, source).onChanged, isNull);
      expect(find.text('Le fichier source restera intact.'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(host.applied, isEmpty);
      expect(find.byKey(const ValueKey(source)), findsNothing);
    });
  }

  testWidgets('content-addressed source removal explicitly retains blob file', (
    tester,
  ) async {
    final host = RemovalDialogHarness();
    await host.open(tester);
    await host.ready(tester);
    await host.tap(tester, source);
    await host.ready(tester, logicalFileRemoved: false);
    expect(
      find.textContaining('adressé par contenu est conservé'),
      findsOneWidget,
    );
    await host.tap(tester, confirm);
    await host.tap(tester, submit);
    expect(host.applied.single.impact['sourceRemoved'], isTrue);
    expect(
      host.applied.single.changedPaths,
      isNot(contains('assets/planche.png')),
    );
  });

  for (final size in [
    const Size(1536, 1024),
    const Size(1280, 800),
    const Size(1024, 640),
  ]) {
    testWidgets('source removal controls remain reachable at $size', (
      tester,
    ) async {
      final host = RemovalDialogHarness();
      await host.open(tester, size: size, scale: size.width == 1024 ? 1.5 : 1);
      await host.ready(tester);
      await host.tap(tester, source);
      await host.ready(tester);
      await host.tap(tester, confirm);
      expect(host.canSubmit(tester), isTrue);
      await host.capture(tester, 'uwu5-source-removal-${size.width.toInt()}');
      await host.tap(tester, submit);
      expect(host.applied.single.parameters['removeSource'], isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}
