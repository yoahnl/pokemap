part of 'catalog_workshop_selection.dart';

bool _onlyReplacesTerrainFrames(Object? existing, Object? candidate) {
  if (existing is! Map || candidate is! Map) return false;
  final before =
      ProjectSmartTilePreset.fromJson(Map<String, Object?>.from(existing));
  final after =
      ProjectSmartTilePreset.fromJson(Map<String, Object?>.from(candidate));
  if (before.status != SmartTilePresetStatus.published ||
      before.rules.length != after.rules.length ||
      before.copyWith(rules: after.rules) != after) {
    return false;
  }

  for (var index = 0; index < before.rules.length; index++) {
    final previous = before.rules[index];
    final replacement = after.rules[index];
    if (previous != replacement &&
        !_onlyReassignsFrame(previous, replacement)) {
      return false;
    }
  }
  return true;
}

bool _onlyReassignsFrame(SmartTileRule before, SmartTileRule after) {
  if (before.candidates.length != 1 || after.candidates.length != 1) {
    return false;
  }
  final previous = before.candidates.single;
  final replacement = after.candidates.single;
  if (previous.parts.length != 1 || replacement.parts.length != 1) return false;
  final part = previous.parts.single;
  final oldSource = part.source;
  final newSource = replacement.parts.single.source;
  if (oldSource is! SmartTileFrameSource ||
      newSource is! SmartTileFrameSource ||
      part.frameSampling != SmartTileFrameSampling.fullFrame) {
    return false;
  }
  final frame = oldSource.frame;
  final next = newSource.frame;
  return frame.columnSpan == 1 &&
      frame.rowSpan == 1 &&
      frame.copyWith(column: next.column, row: next.row) == next &&
      before.copyWith(candidates: [
            previous.copyWith(parts: [part.copyWith(source: newSource)]),
          ]) ==
          after;
}
