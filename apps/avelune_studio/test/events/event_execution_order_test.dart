import 'package:avelune_studio/features/events/application/event_execution_order.dart';
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
  final rival = _configured(2, 'Rival', order: 1);
  final rain = _configured(3, 'Pluie', order: 2, enabled: false);
  final ambience = _configured(
    4,
    'Ambiance',
    parallel: NarrativeEventParallelPolicy(cadenceMs: 1500),
    reuse: NarrativeEventReusePolicy.reusable,
  );
  final elsewhere = _configured(
    5,
    'Grotte',
    source: NarrativeEventSourceRef.mapEnter('cave'),
  );
  final draft = NarrativeEventRecord.draft(
    NarrativeEventDraft(
      id: _id(6),
      name: 'Idée',
      source: _arrival,
      conditions: const [],
      priority: 99,
      order: 0,
    ),
  );
  final registry = _registry([
    rain,
    rival,
    welcome,
    ambience,
    elsewhere,
    draft,
  ]);

  test('the execution order follows the runtime dispatch rule', () {
    expect(
      eventExecutionOrder(welcome, registry),
      startsWith('Examiné en 1er sur 3 pour ce déclencheur'),
    );
    expect(
      eventExecutionOrder(rival, registry),
      'Examiné en 2e sur 3 pour ce déclencheur : un seul événement est joué à '
      'chaque déclenchement, le premier dont les conditions sont remplies. '
      'Passent avant lui : « Accueil ».',
    );
    expect(
      eventExecutionOrder(rain, registry),
      endsWith(
        'Passent avant lui : « Accueil », « Rival ». Désactivé : il garde sa '
        'place mais le jeu le saute.',
      ),
    );
    expect(
      eventExecutionOrder(elsewhere, registry),
      'Seul événement de ce déclencheur : joué dès que ses conditions sont '
      'remplies.',
    );
    expect(
      eventExecutionOrder(ambience, registry),
      'En parallèle : repris toutes les 1,5 secondes, sans attendre les autres '
      'événements de ce déclencheur.',
    );
    expect(eventExecutionOrder(draft, registry), startsWith('Brouillon'));
  });

  test('the historical mode says when an event is not examined', () {
    final historical = _registry([
      welcome,
      _configured(7, 'Ancien', legacy: true),
    ], mode: EventSystemMode.legacyOnly);
    expect(
      eventExecutionOrder(welcome, historical),
      contains('mode historique'),
    );
    expect(
      eventExecutionOrder(historical.records.last, historical),
      startsWith('Seul événement de ce déclencheur'),
    );
  });

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
