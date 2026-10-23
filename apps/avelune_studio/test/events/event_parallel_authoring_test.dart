import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/presentation/features/events/event_options_panel.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/event_backend_fixture.dart';

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
  test('parallel draft cadence survives rename save and cold reopen', () async {
    final fixture = await EventBackendFixture.create();
    addTearDown(fixture.dispose);
    final controller = fixture.attach();
    expect(await controller.prepare(), isTrue);
    final draft = controller.create(
      'Parallel draft',
      source: NarrativeEventSourceRef.mapEnter(
        controller.project.maps.first.id,
      ),
    )!;
    expect(
      controller.setReuse(draft.id, NarrativeEventReusePolicy.reusable),
      isTrue,
    );
    expect(
      controller.setParallel(
        draft.id,
        NarrativeEventParallelPolicy(cadenceMs: 350),
      ),
      isTrue,
      reason: controller.error,
    );
    expect(controller.rename(draft.id, 'Parallel renamed'), isTrue);
    expect(controller.record(draft.id)!.parallelPolicy!.cadenceMs, 350);
    expect(await controller.save(), isTrue, reason: controller.error);
    final fresh = await fixture.readFresh();
    expect(
      fresh.eventRegistry!.records
          .singleWhere((record) => record.id == draft.id)
          .parallelPolicy!
          .cadenceMs,
      350,
    );
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
