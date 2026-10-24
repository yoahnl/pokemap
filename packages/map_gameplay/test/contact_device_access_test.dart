import 'package:map_core/map_core.dart';
import 'package:map_gameplay/src/contact_device_access.dart';
import 'package:test/test.dart';

void main() {
  final config = ProjectContactDeviceConfig(
      id: 'device',
      label: 'Carnet',
      acquiredFactId: 'owned',
      emptyMessage: 'Personne.',
      contacts: [
        ProjectContactEntryConfig(
            id: 'mentor',
            label: 'Mentor',
            registeredFactId: 'known',
            availableFactId: 'ready',
            sceneId: 'call',
            unavailableSceneId: 'busy')
      ]);
  final project = ProjectManifest(
      name: 'Travel',
      maps: [],
      tilesets: [],
      contactDevice: config,
      facts: [
        for (final id in ['owned', 'known', 'ready'])
          NarrativeFactDefinition(id: id, label: id)
      ]);
  GameState state(Map<String, bool> facts) => GameState(
      saveId: 'save',
      narrativeFactRuntimeState:
          NarrativeFactRuntimeState(overridesByFactId: facts));

  test('device cannot be opened or called before acquisition', () {
    final access = ContactDeviceAccess.resolve(
        project: project, state: state({'known': true, 'ready': true}));
    expect(access.isAcquired, isFalse);
    expect(access.contacts, isEmpty);
    expect(() => access.sceneForContact('mentor'), throwsStateError);
  });

  test('registration and availability select only authored conversation scenes',
      () {
    final unavailable = ContactDeviceAccess.resolve(
        project: project, state: state({'owned': true, 'known': true}));
    expect(unavailable.contacts.map((c) => c.id), ['mentor']);
    expect(unavailable.sceneForContact('mentor'), 'busy');
    final available = ContactDeviceAccess.resolve(
        project: project,
        state: state({'owned': true, 'known': true, 'ready': true}));
    expect(available.sceneForContact('mentor'), 'call');
    expect(() => available.sceneForContact('unknown'), throwsStateError);
  });

  test('save round trip retains acquisition and one registered contact', () {
    final saved = state({'owned': true, 'known': true, 'ready': true});
    final restored = GameState.fromJson(saved.toJson());
    final access =
        ContactDeviceAccess.resolve(project: project, state: restored);
    expect(access.isAcquired, isTrue);
    expect(access.contacts.length, 1);
    expect(access.sceneForContact('mentor'), 'call');
  });
}
