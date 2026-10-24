import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/player/contact_device_pause.dart';

void main() {
  final project = ProjectManifest(
    name: 'Travel',
    maps: [],
    tilesets: [],
    facts: [
      for (final id in ['owned', 'known'])
        NarrativeFactDefinition(id: id, label: id),
    ],
    contactDevice: ProjectContactDeviceConfig(
      id: 'device',
      label: 'Carnet',
      acquiredFactId: 'owned',
      emptyMessage: 'Aucun contact.',
      contacts: [
        ProjectContactEntryConfig(
          id: 'mentor',
          label: 'Mentor',
          registeredFactId: 'known',
          sceneId: 'call',
          unavailableSceneId: 'busy',
        ),
      ],
    ),
  );
  test('unacquired contact device is absent from pause data', () {
    expect(
      buildContactDevicePauseDetail(
        project: project,
        state: const GameState(saveId: 'save'),
      ),
      isNull,
    );
  });
  test('acquired device shows authored empty text and registered contacts', () {
    final state = GameState(
      saveId: 'save',
      narrativeFactRuntimeState: NarrativeFactRuntimeState(
        overridesByFactId: {'owned': true},
      ),
    );
    final empty = buildContactDevicePauseDetail(
      project: project,
      state: state,
    )!;
    expect(empty.section, RuntimePlayerPauseSection.contacts);
    expect(empty.title, 'Carnet');
    expect(empty.entries, isEmpty);
    expect(empty.emptyMessage, 'Aucun contact.');
    final populated = buildContactDevicePauseDetail(
      project: project,
      state: state.copyWith(
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: {'owned': true, 'known': true},
        ),
      ),
    )!;
    expect(populated.entries.single.id, 'mentor');
    expect(populated.entries.single.title, 'Mentor');
  });
}
