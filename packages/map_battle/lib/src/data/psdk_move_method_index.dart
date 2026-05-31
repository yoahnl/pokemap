import 'generated/psdk_metronome_move_pool.dart';

/// Returns the PSDK battle engine method for a Studio move id.
///
/// The generated metronome pool already carries the imported Studio move data.
/// This small index lets runtime adapters reuse that canonical import instead
/// of maintaining another hand-written move-to-method table.
String? psdkBattleEngineMethodForMoveId(String moveId) {
  final normalizedId = _normalizePsdkMoveId(moveId);
  if (normalizedId.isEmpty) {
    return null;
  }

  final compactId = _compactPsdkMoveId(normalizedId);
  for (final move in psdkMetronomeMovePool) {
    final moveIds = <String>{
      _normalizePsdkMoveId(move.id),
      _normalizePsdkMoveId(move.dbSymbol),
    };
    if (moveIds.contains(normalizedId) ||
        moveIds.map(_compactPsdkMoveId).contains(compactId)) {
      return move.battleEngineMethod;
    }
  }
  return null;
}

String _normalizePsdkMoveId(String moveId) {
  return moveId.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
}

String _compactPsdkMoveId(String moveId) {
  return moveId.replaceAll('_', '');
}
