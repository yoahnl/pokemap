import 'package:avelune_studio/presentation/features/events/event_options_panel.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';


void main() {
  testWidgets('parallel owner picker distinguishes an actual all page from every page', (tester) async {
    NarrativeEventParallelPolicy? changed;
    final record = NarrativeEventRecord.draft(NarrativeEventDraft(
      id: 'evt_00000000-0000-7000-8000-000000000001', name: 'Parallel',
      source: NarrativeEventSourceRef.entityAutorun('map', 'entity'), conditions: const [],
      reusePolicy: NarrativeEventReusePolicy.reusable, priority: 0, order: 0,
      parallelPolicy: NarrativeEventParallelPolicy(cadenceMs: 350, ownerVariantId: 'all')));
    await tester.pumpWidget(MaterialApp(theme: studioTheme(), home: Scaffold(body: EventOptionsPanel(
      record: record, mode: EventSystemMode.v2Only,
      outcomes: NarrativeOutcomeEventSourceCatalog(options: const [], diagnostics: const []),
      onReuse: (_) {}, onReset: (_) {}, onPriority: (_) {}, onOrder: (_) {},
      onConfigure: () {}, onEnabled: () {}, onMode: () {},
      ownerVariants: const {'all': 'Page 1'}, onParallel: (policy) => changed = policy))));
    final picker = find.widgetWithText(DropdownButtonFormField<String>, 'Page propriétaire');
    await tester.ensureVisible(picker);
    await tester.tap(picker);
    await tester.pumpAndSettle();
    expect(find.text('Toutes les pages actives'), findsOneWidget);
    await tester.tap(find.text('Toutes les pages actives'));
    await tester.pumpAndSettle();
    expect(changed!.ownerVariantId, isNull);
    await tester.tap(picker);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Page 1').last);
    await tester.pumpAndSettle();
    expect(changed!.ownerVariantId, 'all');
    await tester.pumpWidget(const SizedBox());
  });


  testWidgets('guided options expose execution mode and validated cadence', (
    tester,
  ) async {
    NarrativeEventParallelPolicy? changed;
    final record = NarrativeEventRecord.draft(
      NarrativeEventDraft(
        id: 'evt_00000000-0000-7000-8000-000000000001',
        name: 'Parallel',
        source: NarrativeEventSourceRef.mapEnter('map'),
        conditions: const [],
        reusePolicy: NarrativeEventReusePolicy.reusable,
        priority: 0,
        order: 0,
        parallelPolicy: NarrativeEventParallelPolicy(cadenceMs: 350),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: EventOptionsPanel(
            record: record,
            mode: EventSystemMode.v2Only,
            outcomes: NarrativeOutcomeEventSourceCatalog(
              options: const [],
              diagnostics: const [],
            ),
            onReuse: (_) {},
            onReset: (_) {},
            onPriority: (_) {},
            onOrder: (_) {},
            onConfigure: () {},
            onEnabled: () {},
            onMode: () {},
            onParallel: (policy) => changed = policy,
          ),
        ),
      ),
    );
    expect(find.text('Exécution'), findsOneWidget);
    expect(find.text('Parallèle'), findsOneWidget);
    final field = find.widgetWithText(TextField, 'Cadence (ms)');
    await tester.ensureVisible(field);
    await tester.enterText(field, '99');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(changed, isNull);
    await tester.enterText(field, '500');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(changed!.cadenceMs, 500);
    await tester.pumpWidget(const SizedBox());
  });
}
