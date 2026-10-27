import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'hub_save_codec_executor.dart';

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
    this.codecExecutor = const HubSaveCodecExecutor(),
  });

  final Directory supportRoot;
  final GameIdentity identity;
  final SaveEnvelopeCodec codec;
  final SaveCompatibilityEvaluator compatibilityEvaluator;
  final HubSaveCodecExecutor codecExecutor;

  static bool isUnsupportedContract(Object error) =>
      error is SaveContractException &&
      (error.code == SaveContractErrorCode.unsupportedSchema ||
          error.code == SaveContractErrorCode.unsupportedSaveFormat);

  Future<SaveEnvelope> decodeCandidate(
    File file,
    SaveSlotAddress address,
  ) async {
    final content = await file.readAsString();
    return codecExecutor.decodeCandidate(
      codec: codec,
      source: content,
      address: address,
      currentSaveFormat: identity.saveFormat,
    );
  }

  Future<void> restoreAnyValidCurrent({
    required Directory slot,
    required SaveSlotAddress address,
    required File temporary,
  }) async {
    final current = File(p.join(slot.path, 'save.json'));
    if (await current.exists()) {
      try {
        await decodeCandidate(current, address);
        return;
      } on HubSaveCodecExecutionException {
        rethrow;
      } catch (error) {
        if (isUnsupportedContract(error)) return;
      }
    }
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
    } on HubSaveCodecExecutionException {
      rethrow;
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
