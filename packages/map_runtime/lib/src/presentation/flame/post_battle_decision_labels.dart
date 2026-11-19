import 'package:map_gameplay/map_gameplay.dart';

import '../runtime_battle_message.dart';

List<String> buildPostBattleDecisionLabels({
  required PendingBattleMoveLearning? pendingMove,
  required PendingBattleEvolution? pendingEvolution,
  required List<String> pendingPartyMoveIds,
  RuntimeBattleMessageRenderer? formatBattleMessage,
  String Function(String moveId)? resolveMoveDisplayName,
}) {
  if (pendingMove != null) {
    final decline = const RuntimeBattleMessage(
      RuntimeBattleMessageId.postBattleDeclineMove,
      'Ne pas apprendre',
    ).render(formatBattleMessage);
    if (pendingMove.phase == BattleMoveLearningPhase.awaitingDecision) {
      return [
        const RuntimeBattleMessage(
          RuntimeBattleMessageId.postBattleLearn,
          'Apprendre',
        ).render(formatBattleMessage),
        decline,
      ];
    }
    return [
      for (final moveId in pendingPartyMoveIds)
        resolveMoveDisplayName?.call(moveId) ?? _displayMoveId(moveId),
      decline,
    ];
  }
  if (pendingEvolution != null) {
    return [
      const RuntimeBattleMessage(
        RuntimeBattleMessageId.postBattleEvolve,
        'Évoluer',
      ).render(formatBattleMessage),
      const RuntimeBattleMessage(
        RuntimeBattleMessageId.postBattleDeclineEvolution,
        'Refuser',
      ).render(formatBattleMessage),
    ];
  }
  return const [];
}

String _displayMoveId(String id) {
  final words = id
      .trim()
      .split(RegExp(r'[-_:]+'))
      .where((word) => word.isNotEmpty)
      .toList(growable: false);
  if (words.isEmpty) return 'Pokémon';
  final text = words.join(' ');
  return '${text[0].toUpperCase()}${text.substring(1)}';
}
