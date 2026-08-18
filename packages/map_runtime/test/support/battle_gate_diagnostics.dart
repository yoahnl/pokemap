import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/application/runtime_psdk_battle_session_adapter.dart';

/// Diagnostic attaché aux échecs de la gate de combat (BETA-BAT-008).
///
/// Le ticket exige qu'« un échec fournisse timeline et snapshot exploitables ».
/// Sans cela, une gate rouge en CI ne dit que « attendu victoire, obtenu
/// défaite » : il faut relancer en local, deviner la graine, et espérer
/// reproduire. Avec cela, le message porte de quoi rejouer et comprendre sans
/// rien relancer.
///
/// Rendu volontairement compact et déterministe : c'est un message d'échec, pas
/// un journal. Les graines viennent en premier parce qu'elles sont ce qui permet
/// de reproduire.
///
/// [initialSeeds] EST OBLIGATOIRE, et pour une raison trouvée en testant ce
/// rendu : les graines lues sur l'état final ont déjà avancé, chaque tirage les
/// ayant consommées. Les afficher seules donnait un diagnostic d'apparence
/// complète avec lequel PERSONNE NE POUVAIT REPRODUIRE le run. Les deux sont
/// donc rendues, l'initiale pour rejouer et la courante pour voir ce qui a été
/// consommé.
String describeBattleFailure({
  required RuntimePsdkBattleSessionAdapter session,
  required PsdkBattleRngSeeds initialSeeds,
  List<BattleEngineTurnResult> turns = const <BattleEngineTurnResult>[],
  String? note,
}) {
  final state = session.state;
  final seeds = state.rngSeeds;
  final player = state.battlerAt(psdkPlayerSlot);
  final enemy = state.battlerAt(psdkOpponentSlot);
  final lines = <String>[
    if (note != null && note.isNotEmpty) note,
    'seeds (initial, replay with these): '
        'moveDamage=${initialSeeds.moveDamage} '
        'moveCritical=${initialSeeds.moveCritical} '
        'moveAccuracy=${initialSeeds.moveAccuracy} '
        'generic=${initialSeeds.generic}',
    'seeds (now, already advanced): moveDamage=${seeds.moveDamage} '
        'moveCritical=${seeds.moveCritical} '
        'moveAccuracy=${seeds.moveAccuracy} generic=${seeds.generic}',
    'outcome: ${state.outcome?.kind.name ?? 'unfinished'} '
        '(finished=${state.isFinished})',
    'player: ${player.speciesId} hp=${player.currentHp}/${player.maxHp} '
        'status=${player.majorStatus?.name ?? 'none'}',
    'enemy: ${enemy.speciesId} hp=${enemy.currentHp}/${enemy.maxHp} '
        'status=${enemy.majorStatus?.name ?? 'none'}',
  ];
  for (var index = 0; index < turns.length; index += 1) {
    final kinds = turns[index]
        .timeline
        .psdkTimeline
        .events
        .map((event) => event.kind)
        .join(', ');
    lines.add('turn ${index + 1}: $kinds');
  }
  return lines.join('\n');
}
