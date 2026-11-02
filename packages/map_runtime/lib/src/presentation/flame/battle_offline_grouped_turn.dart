import 'package:map_battle/map_battle.dart';

import 'battle_move_audio_scope.dart';
import 'battle_offline_move_recipe_loader.dart';
import 'battle_overlay_component.dart';
import 'battle_sfx_player.dart';

Future<List<BattleTurnAudioRequest>> prepareOfflineGroupedSplTurn({
  required BattleSession session,
  required BattleOfflineMoveRecipeLoader loader,
  required Map<String, BattleOfflineMoveRecipeResult> results,
  required BattleOverlayComponent overlay,
  required FlameAudioBattleSfxPlayer player,
  required bool Function() isCurrent,
}) async {
  final requests = <BattleTurnAudioRequest>[];
  var handedOff = false;
  try {
    final events =
        session.state.currentTurn?.timeline
            .whereType<BattleTurnExecutionEvent>() ??
        const <BattleTurnExecutionEvent>[];
    for (final event in events) {
      if (!isCurrent()) throw const BattleOfflineRecipeLoadCancelled();
      if (event.execution.targetSlot == null) continue;
      final moveId = event.execution.move.id;
      final previous = results[moveId];
      if (previous?.fallbackReason !=
              BattleRecipeFallbackReason.unavailableCapabilities ||
          !previous!.unavailableCapabilities.containsAll(const {
            'startParticle',
            'waitEffects',
            'splParticleV2',
            'sound',
            'audioSelectionV2',
          })) {
        continue;
      }
      final result = await loader.load(
        moveId,
        retainVerifiedMedia: true,
        isCurrent: isCurrent,
      );
      final media = result.verifiedMedia;
      if (media == null) continue;
      var transferred = false;
      try {
        if (!isCurrent()) throw const BattleOfflineRecipeLoadCancelled();
        if (media.bundle.recipe.toJson()['moveSourceId'] != 'flamethrower') {
          continue;
        }
        transferred = true;
        final request = await overlay.prepareGroupedSplTurn(
          event: event,
          media: media,
          player: player,
        );
        if (!isCurrent()) {
          if (request != null) overlay.discardGroupedSplTurn(request);
          throw const BattleOfflineRecipeLoadCancelled();
        }
        if (request != null) requests.add(request);
      } finally {
        if (!transferred) media.release();
      }
    }
    handedOff = true;
    return List.unmodifiable(requests);
  } finally {
    if (!handedOff) {
      for (final request in requests) {
        overlay.discardGroupedSplTurn(request);
      }
    }
  }
}
