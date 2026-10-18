import 'package:map_core/map_core.dart';

import 'battle_start_request.dart';

Map<int, String> resolveRuntimeTrainerBallItems({
  required BattleStartRequest request,
  required ProjectManifest manifest,
}) {
  if (request is! TrainerBattleStartRequest) return const {};
  final matches = manifest.trainers.where(
    (entry) => entry.id == request.trainerId,
  );
  if (matches.length != 1) return const {};
  final items = <int, String>{};
  for (final (index, member) in matches.single.team.indexed) {
    final itemId = member.ballItemId?.trim();
    if (itemId != null && itemId.isNotEmpty) items[index] = itemId;
  }
  return Map.unmodifiable(items);
}
