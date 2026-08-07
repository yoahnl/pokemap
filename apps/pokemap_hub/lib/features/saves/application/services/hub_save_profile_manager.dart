import 'package:map_core/map_core.dart';

import 'package:pokemap_hub/features/saves/domain/entities/save_profile.dart';
import 'package:pokemap_hub/features/saves/domain/entities/save_slot_metadata.dart';
import 'package:pokemap_hub/features/saves/domain/entities/save_storage_diagnostic.dart';
import 'package:pokemap_hub/features/saves/domain/repositories/save_repository_interface.dart';

final class HubManagedSaveSlot {
  const HubManagedSaveSlot({
    required this.metadata,
    this.summary,
  });

  final SaveSlotMetadata metadata;
  final SaveSlotSummary? summary;

  bool get isEmpty => summary?.updatedAt == null;
}

final class HubManagedSaveProfile {
  const HubManagedSaveProfile({
    required this.profile,
    required this.slots,
  });

  final SaveProfile profile;
  final List<HubManagedSaveSlot> slots;
}

final class HubSaveSelection {
  const HubSaveSelection({
    required this.profileId,
    required this.slotId,
  });

  final String profileId;
  final String slotId;
}

abstract interface class HubSaveProfilesController {
  Future<List<HubManagedSaveProfile>> load();

  Future<SaveProfile> createProfile(String displayName);

  Future<SaveProfile> renameProfile(
    SaveProfile profile,
    String displayName,
  );

  Future<void> deleteProfile(String profileId);

  Future<SaveSlotMetadata> createSlot({
    required String profileId,
    required String displayName,
  });

  Future<void> deleteSlot({
    required String profileId,
    required String slotId,
  });
}

/// No-code profile/slot operations over one game-scoped save store.
final class HubSaveProfileManager implements HubSaveProfilesController {
  HubSaveProfileManager({
    required this.store,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final SaveRepositoryInterface store;
  final DateTime Function() _now;

  @override
  Future<List<HubManagedSaveProfile>> load() async {
    final profiles = await store.listProfiles();
    final result = <HubManagedSaveProfile>[];
    for (final profile in profiles) {
      final metadata = await store.listSlotMetadata(
        profileId: profile.profileId,
      );
      final summaries = await store.listSlots(profileId: profile.profileId);
      final summariesById = <String, SaveSlotSummary>{
        for (final summary in summaries) summary.address.slotId: summary,
      };
      final metadataById = <String, SaveSlotMetadata>{
        for (final slot in metadata) slot.slotId: slot,
      };
      for (final summary in summaries) {
        metadataById.putIfAbsent(
          summary.address.slotId,
          () => SaveSlotMetadata(
            slotId: summary.address.slotId,
            displayName: _legacySlotName(summary.address.slotId),
            createdAt: summary.updatedAt ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          ),
        );
      }
      final slots = metadataById.values
          .map(
            (slot) => HubManagedSaveSlot(
              metadata: slot,
              summary: summariesById[slot.slotId],
            ),
          )
          .toList(growable: false)
        ..sort((left, right) {
          final leftDate = left.summary?.updatedAt ?? left.metadata.createdAt;
          final rightDate =
              right.summary?.updatedAt ?? right.metadata.createdAt;
          final byRecency = rightDate.compareTo(leftDate);
          return byRecency != 0
              ? byRecency
              : left.metadata.slotId.compareTo(right.metadata.slotId);
        });
      result.add(
        HubManagedSaveProfile(
          profile: profile,
          slots: List<HubManagedSaveSlot>.unmodifiable(slots),
        ),
      );
    }
    return List<HubManagedSaveProfile>.unmodifiable(result);
  }

  @override
  Future<SaveProfile> createProfile(String displayName) async {
    final profiles = await store.listProfiles();
    final used = profiles.map((profile) => profile.profileId).toSet();
    final profile = SaveProfile(
      profileId: _nextId('profile', used),
      displayName: displayName.trim(),
    );
    await store.saveProfile(profile);
    return profile;
  }

  @override
  Future<SaveProfile> renameProfile(
    SaveProfile profile,
    String displayName,
  ) async {
    final renamed = SaveProfile(
      profileId: profile.profileId,
      displayName: displayName.trim(),
    );
    await store.saveProfile(renamed);
    return renamed;
  }

  @override
  Future<void> deleteProfile(String profileId) =>
      store.deleteProfile(profileId);

  @override
  Future<SaveSlotMetadata> createSlot({
    required String profileId,
    required String displayName,
  }) async {
    final existing = await store.listSlotMetadata(profileId: profileId);
    final summaries = await store.listSlots(profileId: profileId);
    final used = <String>{
      ...existing.map((slot) => slot.slotId),
      ...summaries.map((slot) => slot.address.slotId),
    };
    final metadata = SaveSlotMetadata(
      slotId: _nextId('slot', used),
      displayName: displayName.trim(),
      createdAt: _now().toUtc(),
    );
    await store.saveSlotMetadata(
      profileId: profileId,
      metadata: metadata,
    );
    return metadata;
  }

  @override
  Future<void> deleteSlot({
    required String profileId,
    required String slotId,
  }) {
    return store.deleteSlot(
      SaveSlotAddress(
        gameId: store.identity.gameId,
        profileId: profileId,
        slotId: slotId,
      ),
    );
  }

  Future<HubSaveSelection> ensureDefaultSelection({
    String defaultProfileDisplayName = 'Player',
    String defaultSlotDisplayName = 'Slot 1',
  }) async {
    var profiles = await load();
    if (profiles.isEmpty) {
      await store.saveProfile(
        SaveProfile(
          profileId: 'default',
          displayName: defaultProfileDisplayName,
        ),
      );
      profiles = await load();
    }
    var selected = profiles.first;
    if (selected.slots.isEmpty) {
      await store.saveSlotMetadata(
        profileId: selected.profile.profileId,
        metadata: SaveSlotMetadata(
          slotId: 'slot-1',
          displayName: defaultSlotDisplayName,
          createdAt: _now().toUtc(),
        ),
      );
      selected = (await load()).firstWhere(
          (entry) => entry.profile.profileId == selected.profile.profileId);
    }
    final slot = selected.slots.first;
    return HubSaveSelection(
      profileId: selected.profile.profileId,
      slotId: slot.metadata.slotId,
    );
  }

  String _nextId(String prefix, Set<String> used) {
    var serial = 1;
    while (used.contains('$prefix-$serial')) {
      serial++;
    }
    return '$prefix-$serial';
  }

  String _legacySlotName(String slotId) {
    final suffix = slotId.split(RegExp('[-_]')).last;
    return 'Slot $suffix';
  }
}
