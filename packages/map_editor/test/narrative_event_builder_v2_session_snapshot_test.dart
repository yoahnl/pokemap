import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';

import 'support/event_registry_persistence_fixtures.dart';

void main() {
  test('Phase H session exposes its exact project read-model snapshot',
      () async {
    final fixture = await createPersistenceFixture(
      registry: persistenceRegistry(mode: EventSystemMode.v2Only),
    );
    addTearDown(fixture.dispose);

    final session = await NarrativeEventAuthoringSession.prepare(
      fixture.projectPath,
    );
    final readModel = buildNarrativeEventBuilderProjectReadModel(
      project: session.manifest,
      maps: session.maps,
    );

    expect(session.manifest.name, 'Phase E fixture');
    expect(session.maps.map((map) => map.id), ['map_a']);
    expect(readModel.events.single.eventId, persistenceEventA);
    expect(() => session.maps.add(session.maps.single), throwsUnsupportedError);
  });
}
