import 'dart:convert';

import 'package:avelune_studio/features/events/application/event_legacy_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/event_legacy_fixture.dart';

void main() {
  test(
    'canonical historical projections preserve pages, scenario and registry',
    () {
      final before = jsonEncode([
        historicalProject.toJson(),
        historicalMap.toJson(),
      ]);
      final catalog = EventLegacyCatalog(historicalProject, [historicalMap]);
      expect(catalog.matches(historicalProject, [historicalMap]), isTrue);
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
      expect(
        jsonEncode([historicalProject.toJson(), historicalMap.toJson()]),
        before,
      );
      expect(historicalProject.eventRegistry, isNull);
      final changed = historicalMap.copyWith(name: 'Gare modifiée');
      expect(catalog.matches(historicalProject, [changed]), isFalse);
    },
  );
}
