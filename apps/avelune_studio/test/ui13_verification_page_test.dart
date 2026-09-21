import 'package:avelune_studio/features/verification/application/verification_workspace_controller.dart';
import 'package:avelune_studio/features/world/application/world_workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'support/m2_ui_fixture.dart';
import 'support/ui13_page_harness.dart';
import 'support/ui13_verification_harness.dart';

Future<void> activate(WidgetTester tester, Finder finder) async {
  await tester.pump(const Duration(milliseconds: 350));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await pumpIo(tester, frames: 10);
}

Future<Ui13PageHarness> open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final h = (await tester.runAsync(() => Ui13PageHarness.create(tester)))!;
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(h.dispose);
  });
  await tester.pumpWidget(h.app());
  await pumpIo(tester, frames: 6);
  return h;
}

void main() {
  testWidgets('the page states that nothing was checked before a launch', (
    tester,
  ) async {
    final h = await open(tester);
    expect(find.text('Vérification narrative'), findsOneWidget);
    expect(
      find.textContaining('Aucun contrôle lancé'),
      findsWidgets,
      reason: 'an unchecked project must never read as zero error',
    );
    expect(h.port.runs, 0, reason: 'opening the page runs no control');
    await h.capture(tester, 'ui13-00-avant-controle');

    await activate(tester, find.text('Lancer la vérification').first);
    for (var i = 0; i < 40 && h.controller.report == null; i++) {
      await pumpIo(tester, frames: 3);
    }
    expect(h.controller.report, isNotNull, reason: h.controller.error);
    expect(h.port.runs, 1);
    expect(find.textContaining('Contrôle du'), findsOneWidget);
    expect(find.text('Structure'), findsOneWidget);
    expect(find.text('En échec'), findsOneWidget);
    expect(find.text('Non exécuté'), findsOneWidget);
    await h.capture(tester, 'ui13-01-rapport');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a diagnostic shows its context, its target and its editor', (
    tester,
  ) async {
    final h = await open(tester);
    await activate(tester, find.text('Lancer la vérification').first);
    for (var i = 0; i < 40 && h.controller.report == null; i++) {
      await pumpIo(tester, frames: 3);
    }
    final rule = h.controller.report!.diagnostics.firstWhere(
      (item) => item.worldRuleId == Ui13VerificationHarness.orphanRuleId,
    );
    h.controller.select(rule.stableKey);
    await pumpIo(tester, frames: 8);

    expect(find.text('Masquer le conducteur'), findsWidgets);
    expect(
      find.textContaining('Contexte de Masquer le conducteur'),
      findsOneWidget,
      reason: 'the graph follows the selection instead of staying global',
    );
    expect(find.text('Ouvrir dans l’éditeur'), findsOneWidget);
    await h.capture(tester, 'ui13-02-diagnostic');

    final orphan = h.controller.report!.diagnostics.firstWhere(
      (item) => item.factId == 'fact_inexistant',
    );
    h.controller.select(orphan.stableKey);
    await pumpIo(tester, frames: 8);
    expect(
      find.textContaining('Référence introuvable'),
      findsOneWidget,
      reason: 'a missing reference is drawn as missing, never replaced',
    );
    h.controller.select(rule.stableKey);
    await pumpIo(tester, frames: 8);

    await activate(tester, find.text('Ouvrir dans l’éditeur'));
    expect(h.opened.single.stableKey, rule.stableKey);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty filter is the filter’s zero, not the project’s', (
    tester,
  ) async {
    final h = await open(tester);
    await activate(tester, find.text('Lancer la vérification').first);
    for (var i = 0; i < 40 && h.controller.report == null; i++) {
      await pumpIo(tester, frames: 3);
    }
    final chosen = h.controller.report!.diagnostics.first;
    h.controller.select(chosen.stableKey);
    await tester.enterText(find.byType(TextField).last, 'zzz introuvable zzz');
    await pumpIo(tester, frames: 8);

    expect(find.text('Aucun résultat pour ce filtre'), findsOneWidget);
    expect(
      find.textContaining('Ce zéro est celui du filtre'),
      findsOneWidget,
      reason: 'a filtered list never certifies the project',
    );
    expect(find.textContaining('Sélection hors filtre'), findsOneWidget);
    expect(h.controller.selected?.stableKey, chosen.stableKey);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the report announces that the work moved under it', (
    tester,
  ) async {
    final h = await open(tester);
    await activate(tester, find.text('Lancer la vérification').first);
    for (var i = 0; i < 40 && h.controller.report == null; i++) {
      await pumpIo(tester, frames: 3);
    }
    expect(find.textContaining('Modifications depuis'), findsNothing);
    final stamp = h.controller.report!.generatedAt;

    await tester.runAsync(h.project.world.initialize);
    final fact = h.project.world.fact(Ui13VerificationHarness.knownFactId)!;
    h.project.world.editFact(
      NarrativeFactDefinition(
        id: fact.id,
        label: fact.label,
        description: 'Corrigé pendant la consultation du rapport.',
        initialValue: fact.initialValue,
      ),
    );
    await pumpIo(tester, frames: 6);

    expect(
      find.textContaining('Modifications depuis la vérification'),
      findsOneWidget,
    );
    expect(
      h.controller.report!.generatedAt,
      stamp,
      reason: 'an old report keeps its own date, never the date of a filter',
    );
    await h.capture(tester, 'ui13-03-perime');
    expect(tester.takeException(), isNull);
  });
}
