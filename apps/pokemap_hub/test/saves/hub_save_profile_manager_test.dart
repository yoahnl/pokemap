import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:pokemap_hub/pokemap_hub.dart';

void main() {
  late Directory root;
  late HubSaveStore store;
  late HubSaveProfileManager manager;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hub-profile-manager-');
    store = HubSaveStore(
      supportRoot: root,
      identity: GameIdentity(
        gameId: 'games.example.profiles',
        gameVersion: '1.0.0',
        projectFormat: ProjectFormat.v2,
        saveFormat: 1,
        compatibilityId: 'profiles-v1',
      ),
    );
    manager = HubSaveProfileManager(
      store: store,
      now: () => DateTime.utc(2026, 7, 27, 12),
    );
  });

  tearDown(() => root.delete(recursive: true));

  test('creates, renames and deletes profiles without caller-authored ids',
      () async {
    final profile = await manager.createProfile('Karim');
    expect(profile.profileId, 'profile-1');
    expect(profile.displayName, 'Karim');

    final renamed = await manager.renameProfile(profile, 'Karim — aventure 2');
    expect(renamed.profileId, profile.profileId);
    expect((await manager.load()).single.profile, renamed);

    await manager.deleteProfile(profile.profileId);
    expect(await manager.load(), isEmpty);
  });

  test('persists empty slot metadata and deletes only the selected slot',
      () async {
    final profile = await manager.createProfile('Karim');
    final first = await manager.createSlot(
      profileId: profile.profileId,
      displayName: 'Port des Brisants',
    );
    final second = await manager.createSlot(
      profileId: profile.profileId,
      displayName: 'Route alternative',
    );

    expect(first.slotId, 'slot-1');
    expect(second.slotId, 'slot-2');
    final reloaded = (await manager.load()).single;
    expect(
      reloaded.slots.map((slot) => slot.metadata.displayName),
      <String>['Port des Brisants', 'Route alternative'],
    );
    expect(reloaded.slots, everyElement(isA<HubManagedSaveSlot>()));
    expect(
        reloaded.slots,
        everyElement(predicate<HubManagedSaveSlot>(
          (slot) => slot.isEmpty,
        )));

    await manager.deleteSlot(
      profileId: profile.profileId,
      slotId: first.slotId,
    );
    expect(
      (await manager.load()).single.slots.single.metadata.slotId,
      second.slotId,
    );
  });

  test('default selection is stable across manager recreation', () async {
    final first = await manager.ensureDefaultSelection(
      defaultProfileDisplayName: 'Joueur',
    );
    final second = await HubSaveProfileManager(
      store: store,
      now: () => DateTime.utc(2026, 7, 28),
    ).ensureDefaultSelection();

    expect(first.profileId, 'default');
    expect(first.slotId, 'slot-1');
    expect(second.profileId, first.profileId);
    expect(second.slotId, first.slotId);
    expect((await manager.load()).single.profile.displayName, 'Joueur');
  });
}
