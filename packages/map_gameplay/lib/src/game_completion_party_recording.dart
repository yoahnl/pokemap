import 'package:map_core/map_core.dart';

GameState recordGameCompletionParty({
  required GameState gameState,
  required String endingId,
  required int completedAtEpochMs,
  GameCompletionPartyRecord? preparedRecord,
}) {
  final journal = gameState.completionPartyJournal;
  if (journal.records.any((record) => record.endingId == endingId)) {
    return gameState;
  }
  if (preparedRecord != null &&
      (preparedRecord.endingId != endingId ||
          preparedRecord.completedAtEpochMs != completedAtEpochMs)) {
    throw const FormatException(
        'The prepared completion record does not match its ending and timestamp.');
  }
  final record = preparedRecord ??
      GameCompletionPartyRecord.snapshot(
        endingId: endingId,
        completedAtEpochMs: completedAtEpochMs,
        mapId: gameState.currentMapId,
        trainerName: gameState.trainerProfile.name,
        party: gameState.party,
      );
  return gameState.copyWith(completionPartyJournal: journal.record(record));
}
