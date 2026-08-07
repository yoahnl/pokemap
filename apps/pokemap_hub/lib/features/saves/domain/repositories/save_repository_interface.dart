import 'package:map_core/map_core.dart';

import 'package:pokemap_hub/features/saves/domain/entities/save_migration.dart';
import 'package:pokemap_hub/features/saves/domain/entities/save_profile.dart';
import 'package:pokemap_hub/features/saves/domain/entities/save_storage_diagnostic.dart';
import 'package:pokemap_hub/features/saves/domain/entities/save_slot_metadata.dart';

/// Durable, crash-safe save storage scoped to a single installed game.
abstract interface class SaveRepositoryInterface {
  /// Game this store is scoped to. Every address is validated against it.
  GameIdentity get identity;

  Future<void> write(SaveEnvelope envelope);

  Future<SaveEnvelope> writeVerified(SaveEnvelope envelope);

  Future<SaveSlotRead> read(
    SaveSlotAddress address, {
    bool migrationChainAvailable = false,
  });

  Future<SaveSlotRead?> findContinue({String? profileId});

  Future<void> deleteSlot(SaveSlotAddress address);

  Future<void> saveProfile(SaveProfile profile);

  Future<List<SaveProfile>> listProfiles();

  Future<void> deleteProfile(String profileId);

  Future<void> saveSlotMetadata({
    required String profileId,
    required SaveSlotMetadata metadata,
  });

  Future<List<SaveSlotMetadata>> listSlotMetadata({required String profileId});

  Future<List<SaveSlotSummary>> listSlots({required String profileId});

  Future<SaveMigrationResult> migrate({
    required SaveSlotAddress address,
    required SaveMigrationEngine engine,
    required String newSaveId,
    required DateTime updatedAt,
  });

  Future<void> restoreMigrationSnapshot(SaveMigrationSnapshot snapshot);
}
