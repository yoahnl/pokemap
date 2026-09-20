import 'dart:convert';
import 'package:avelune_studio/presentation/features/events/event_legacy_catalog.dart';
import 'package:avelune_studio/presentation/features/events/event_library.dart';
import 'package:avelune_studio/presentation/features/events/event_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  test(
    'canonical historical projections preserve pages, scenario and registry',
    () {
      final before = jsonEncode([_project.toJson(), _map.toJson()]);
      final catalog = EventLegacyCatalog(_project, [_map]);
      expect(catalog.matches(_project, [_map]), isTrue);
      expect(catalog.entries, hasLength(2));
      final mapDetail = catalog.entries.first.detail();
      expect(mapDetail.lines, contains('Bienvenue dans la gare historique.'));
      expect(mapDetail.lines, contains('2 pages conservées'));
      expect(
        mapDetail.source,
        NarrativeEventSourceRef.entityInteract('old_station', 'chief'),
      );
      final scenarioDetail = catalog.entries.last.detail();
      expect(
        scenarioDetail.source,
        NarrativeEventSourceRef.mapEnter('old_station'),
      );
      expect(scenarioDetail.diagnostics, isNotEmpty);
      expect(jsonEncode([_project.toJson(), _map.toJson()]), before);
      expect(_project.eventRegistry, isNull);
      final changed = _map.copyWith(name: 'Gare modifiée');
      expect(catalog.matches(_project, [changed]), isFalse);
    },
  );

  testWidgets(
    'historical library opens read-only detail without modern selection',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final view = EventViewState();
      addTearDown(view.dispose);
      final before = jsonEncode([_project.toJson(), _map.toJson()]);
      var opened = 0;
      var created = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: SizedBox(
              width: 370,
              height: 720,
              child: EventLibrary(
                project: _project,
                records: [],
                activeId: null,
                dirtyIds: {},
                view: view,
                maps: [_map],
                mapsComplete: true,
                onChanged: () {},
                onOpen: (_) => opened++,
                onCreate: () => created++,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Historique · 2'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('event-legacy:map:old_station:old_greeting')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bienvenue dans la gare historique.'), findsOneWidget);
      expect(
        find.textContaining('Aucune conversion ni activation automatique'),
        findsOneWidget,
      );
      expect(find.text('Enregistrer'), findsNothing);
      await tester.tap(find.text('Fermer la consultation'));
      await tester.pumpAndSettle();
      expect(opened, 0);
      expect(created, 0);
      expect(jsonEncode([_project.toJson(), _map.toJson()]), before);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'partial historical inventory is explicit and search includes scenario',
    (tester) async {
      final view = EventViewState();
      addTearDown(view.dispose);
      view.search.text = 'Arrivée ancienne';
      var loads = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 560,
              child: EventLibrary(
                project: _project,
                records: [],
                activeId: null,
                dirtyIds: {},
                view: view,
                maps: [],
                mapsComplete: false,
                onLoadHistory: () => loads++,
                onChanged: () {},
                onOpen: (_) {},
                onCreate: () {},
              ),
            ),
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('event-legacy:scenario:old_arrival:entry')),
        findsOneWidget,
      );
      expect(
        find.textContaining('Historique des cartes chargées'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('event-legacy:map:old_station:old_greeting')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      expect(loads, 0);
      await tester.tap(find.text('Charger l’historique des autres cartes'));
      await tester.pump();
      expect(loads, 1);
    },
  );
}

const _project = ProjectManifest(
  name: 'Historique intact',
  maps: [
    ProjectMapEntry(
      id: 'old_station',
      name: 'Ancienne gare',
      relativePath: 'maps/station.json',
    ),
  ],
  tilesets: [],
  scenarios: [
    ScenarioAsset(
      id: 'old_arrival',
      name: 'Arrivée ancienne',
      entryNodeId: 'entry',
      nodes: [
        ScenarioNode(
          id: 'entry',
          type: ScenarioNodeType.reference,
          title: 'Entrée en gare',
          binding: ScenarioNodeBinding(mapId: 'old_station'),
          payload: ScenarioNodePayload(actionKind: 'sourceMapEnter'),
        ),
      ],
    ),
  ],
);

const _map = MapData(
  id: 'old_station',
  name: 'Ancienne gare',
  size: GridSize(width: 10, height: 10),
  layers: [MapLayer.object(id: 'events', name: 'Événements')],
  entities: [
    MapEntity(
      id: 'chief',
      name: 'Chef',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 2, y: 3),
    ),
  ],
  events: [
    MapEventDefinition(
      id: 'old_greeting',
      title: 'Ancien accueil',
      position: EventPosition(layerId: 'events', x: 2, y: 3),
      metadata: {LegacyMapEventCompatibilityMetadataKeys.entityId: 'chief'},
      pages: [
        MapEventPage(
          pageNumber: 0,
          message: 'Bienvenue dans la gare historique.',
        ),
        MapEventPage(pageNumber: 1, message: 'Le train est arrivé.'),
      ],
    ),
  ],
);
