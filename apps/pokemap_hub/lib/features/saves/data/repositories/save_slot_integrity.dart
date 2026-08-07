import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;


/// Slot-level integrity primitives shared by reads, writes and migrations.
///
/// Decoding a candidate, deciding whether a file is still valid, restoring the
/// last good copy and quarantining a corrupt one are used by all three paths,
/// so they live here rather than in any one of them.
final class SaveSlotIntegrity {
  const SaveSlotIntegrity({
    required this.supportRoot,
    required this.identity,
    required this.codec,
    required this.compatibilityEvaluator,
  });

  final Directory supportRoot;
  final GameIdentity identity;
  final SaveEnvelopeCodec codec;
  final SaveCompatibilityEvaluator compatibilityEvaluator;


  Future<SaveEnvelope> decodeCandidate(
    File file,
    SaveSlotAddress address,
  ) async {
    final content = await file.readAsString();
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic> || decoded['saveFormat'] is! int) {
      throw const FormatException('Invalid save candidate.');
    }
    final format = decoded['saveFormat']! as int;
    final envelope = codec.decodeJson(
      decoded,
      acceptedSaveFormats: <int>{format},
    );
    if (envelope.profileId != address.profileId ||
        envelope.slotId != address.slotId) {
      throw const SaveContractException(
        SaveContractErrorCode.addressMismatch,
        'Save profile/slot does not match its storage address.',
      );
    }
    return envelope;
  }

  Future<void> restoreAnyValidCurrent({
    required Directory slot,
    required SaveSlotAddress address,
    required File temporary,
  }) async {
    final current = File(p.join(slot.path, 'save.json'));
    if (await isValid(current, address)) return;
    for (final source in <File>[
      File(p.join(slot.path, 'save.backup.json.next')),
      File(p.join(slot.path, 'save.backup.json')),
    ]) {
      if (await isValid(source, address)) {
        if (await current.exists()) await quarantine(slot, current);
        await source.copy(current.path);
        return;
      }
    }
    if (await isValid(temporary, address)) {
      if (await current.exists()) await quarantine(slot, current);
      await temporary.copy(current.path);
    }
  }

  Future<bool> isValid(File file, SaveSlotAddress address) async {
    if (!await file.exists()) return false;
    try {
      await decodeCandidate(file, address);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> quarantine(Directory slot, File file) async {
    if (!await file.exists()) return;
    final quarantine = Directory(p.join(slot.path, 'quarantine'));
    await quarantine.create(recursive: true);
    final name =
        '${p.basename(file.path)}.${DateTime.now().toUtc().microsecondsSinceEpoch}'
        '.corrupt';
    await file.rename(p.join(quarantine.path, name));
  }
}
