import 'package:avelune_studio/presentation/features/events/event_summary.dart';
import 'package:avelune_studio/presentation/features/events/event_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

String _id(int number) =>
    'evt_00000000-0000-7000-8000-${number.toString().padLeft(12, '0')}';

final _arrival = NarrativeEventSourceRef.mapEnter('town');

NarrativeEventRecord _configured(
  int number,
  String name, {
  NarrativeEventSourceRef? source,
  int priority = 0,
  int order = 0,
  bool enabled = true,
  bool legacy = false,
  NarrativeEventParallelPolicy? parallel,
  NarrativeEventReusePolicy reuse = NarrativeEventReusePolicy.oneShot,
  NarrativeEventResetPolicy reset = const NarrativeEventResetPolicy.never(),
}) => NarrativeEventRecord.configuredStructurallyUnchecked(
  NarrativeEventDefinition(
    id: _id(number),
    name: name,
    source: source ?? _arrival,
    conditions: const [],
    sceneId: 'scene_$number',
    reusePolicy: reuse,
    priority: priority,
    order: order,
    resetPolicy: reset,
    parallelPolicy: parallel,
  ),
  enabled: enabled,
  activeInLegacyMode: legacy,
);

NarrativeEventRegistry _registry(
  List<NarrativeEventRecord> records, {
  EventSystemMode mode = EventSystemMode.v2Only,
}) => NarrativeEventRegistry(
  schemaVersion: 1,
  mode: mode,
  records: records,
  legacyClaims: const [],
);

void main() {
  final welcome = _configured(1, 'Accueil', priority: 10);
  final rain = _configured(3, 'Pluie', order: 2, enabled: false);

  testWidgets('the summary states the order and the repeat effect', (
    tester,
  ) async {
    final visit = _configured(
      2,
      'Rival',
      order: 1,
      reset: const NarrativeEventResetPolicy.onMapReentry(),
    );
    final tabs = <EventTab>[];
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: EventSummary(
            record: visit,
            project: ProjectManifest(
              name: 'Ordre',
              maps: const [],
              tilesets: const [],
              eventRegistry: _registry([welcome, visit, rain]),
            ),
            outcomes: NarrativeOutcomeEventSourceCatalog(
              options: const [],
              diagnostics: const [],
            ),
            onTab: tabs.add,
            onScene: null,
            sceneDirty: false,
          ),
        ),
      ),
    );

    final order = find.byKey(const ValueKey('event-execution-order'));
    expect(
      find.descendant(
        of: order,
        matching: find.textContaining('Examiné en 2e sur 3'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('event-repeat-effect')),
        matching: find.text(
          'Une fois par visite : se rejoue après avoir quitté puis retrouvé sa carte.',
        ),
      ),
      findsOneWidget,
    );
    await tester.tap(order);
    expect(tabs, [EventTab.options]);
    expect(tester.takeException(), isNull);
  });
}
