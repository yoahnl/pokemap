import 'package:avelune_studio/features/events/application/event_legacy_catalog.dart';
import 'package:avelune_studio/features/events/application/event_library_filter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/event_legacy_fixture.dart';

void main() {
  test('partial historical inventory is explicit and search includes scenario', () {
    final partial = EventLegacyCatalog(historicalProject, const []);
    final complete = EventLegacyCatalog(historicalProject, const [historicalMap]);
    List<String> keys(EventLegacyCatalog catalog, String search) => [
      for (final entry in filterEventLegacyEntries(
        historicalProject,
        catalog.entries,
        search: search,
        onMapOnly: false,
      ))
        entry.key,
    ];

    expect(keys(partial, 'Arrivée ancienne'), [
      'scenario:old_arrival:entry',
    ]);
    expect(
      keys(complete, ''),
      containsAll(['scenario:old_arrival:entry', 'map:old_station:old_greeting']),
    );
    expect(
      keys(complete, 'Arrivée ancienne'),
      isNot(contains('map:old_station:old_greeting')),
    );
    expect(
      keys(complete, '  ANCIENNE GARE '),
      contains('map:old_station:old_greeting'),
    );
    expect(keys(complete, 'absent de partout'), isEmpty);
    List<String> onMap(String? mapId) => [
      for (final entry in filterEventLegacyEntries(
        historicalProject,
        complete.entries,
        search: '',
        onMapOnly: true,
        filterMapId: mapId,
      ))
        entry.key,
    ];
    expect(onMap('old_station'), contains('map:old_station:old_greeting'));
    expect(onMap('elsewhere'), isEmpty);
    expect(onMap(null), isEmpty);
  });

  test('event search covers name, id, kind, target and map, restricted to the current map', () {
    NarrativeEventRecord record(String id, String name, NarrativeEventSourceRef? source) =>
        NarrativeEventRecord.draft(
          NarrativeEventDraft(
            id: id,
            name: name,
            source: source,
            conditions: const [],
            priority: 0,
            order: 0,
          ),
        );
    final project = historicalProject.copyWith(
      maps: const [
        ProjectMapEntry(id: 'station', name: 'Gare', relativePath: 'maps/station.json'),
        ProjectMapEntry(id: 'garden', name: 'Jardin', relativePath: 'maps/garden.json'),
      ],
    );
    final records = [
      record(
        'evt_00000000-0000-7000-8000-000000000001',
        'Accueil',
        NarrativeEventSourceRef.entityInteract('station', 'chief'),
      ),
      record(
        'evt_00000000-0000-7000-8000-000000000002',
        'Floraison',
        NarrativeEventSourceRef.triggerEnter('garden', 'bed'),
      ),
      record('evt_00000000-0000-7000-8000-000000000003', 'Sans source', null),
    ];
    List<String> names(String search, {bool onMapOnly = false, String? mapId}) => [
      for (final value in filterEventRecords(
        project,
        records,
        search: search,
        onMapOnly: onMapOnly,
        filterMapId: mapId,
      ))
        value.draftOrNull!.name,
    ];

    expect(names(''), ['Accueil', 'Floraison', 'Sans source']);
    expect(names('ACCUEIL'), ['Accueil']);
    expect(names('000000000002'), ['Floraison']);
    expect(names('entrée de zone'), ['Floraison']);
    expect(names('chief'), ['Accueil']);
    expect(names('jardin'), ['Floraison']);
    expect(names('', onMapOnly: true, mapId: 'station'), ['Accueil']);
    expect(names('', onMapOnly: true), isEmpty);
    expect(names('Floraison', onMapOnly: true, mapId: 'station'), isEmpty);
  });
}
