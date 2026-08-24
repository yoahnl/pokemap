import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/post_battle_scene_plan_builder.dart';

// BETA-BAT-017 — le plan de fin de combat, segment par segment. Retours de
// recette de Yoahn du 2026-08-24 : le jingle de niveau (« un ding »), le
// sprite du dresseur vaincu avec fallback en message seul, et la barre d'XP
// qui reflète chaque combat.

RuntimePostBattleMessage _message(
  RuntimePostBattleMessageKind kind,
  String text, {
  int? partySlot,
}) =>
    RuntimePostBattleMessage(kind: kind, text: text, partySlot: partySlot);

void main() {
  test(
      'le jingle de niveau précède chaque message de montée du Pokémon '
      'affiché', () {
    final segment = buildPostBattleScenePlanSegment(
      messages: <RuntimePostBattleMessage>[
        _message(RuntimePostBattleMessageKind.victory, 'Victoire !'),
        _message(
          RuntimePostBattleMessageKind.experience,
          'sproutle a gagné 400 points Exp. !',
          partySlot: 0,
        ),
        _message(
          RuntimePostBattleMessageKind.levelUp,
          'sproutle monte au N. 11 !',
          partySlot: 0,
        ),
      ],
      activePartySlot: 0,
      fromXpProgress: 0.6,
      targetXpProgress: 0.17,
    );

    final steps = segment.plan.steps;
    final dingIndex =
        steps.indexWhere((s) => s is PlaySeStep && s.seName == 'level_up');
    final levelUpIndex = steps.indexWhere(
      (s) => s is ShowMessageStep && s.message.contains('monte au N. 11'),
    );
    expect(dingIndex, isNot(-1), reason: 'la référence joue level_up_me');
    expect(
      dingIndex,
      lessThan(levelUpIndex),
      reason: 'le ding part quand la barre est pleine, avec le message',
    );

    final tweens = steps.whereType<HudXpTweenStep>().toList();
    expect(
      tweens.map((t) => (t.fromProgress, t.toProgress)),
      <(double, double)>[(0.6, 1.0), (1.0, 0.0), (0.0, 0.17)],
      reason: 'remplir au plein, remettre à zéro, finir au reliquat exact',
    );
    expect(segment.endXpProgress, 0.17);
  });

  test('sans montée de niveau, la barre va droit au reliquat, sans jingle', () {
    final segment = buildPostBattleScenePlanSegment(
      messages: <RuntimePostBattleMessage>[
        _message(
          RuntimePostBattleMessageKind.experience,
          'sproutle a gagné 21 points Exp. !',
          partySlot: 0,
        ),
      ],
      activePartySlot: 0,
      fromXpProgress: 0.25,
      targetXpProgress: 0.4,
    );

    expect(segment.plan.steps.whereType<PlaySeStep>(), isEmpty);
    final tween = segment.plan.steps.whereType<HudXpTweenStep>().single;
    expect(tween.fromProgress, 0.25);
    expect(tween.toProgress, 0.4);
  });

  test(
      'le sprite du dresseur vaincu s’ancre sur « Vous avez battu X ! », '
      'et sans image le message seul fait l’annonce', () {
    final messages = <RuntimePostBattleMessage>[
      _message(
        RuntimePostBattleMessageKind.trainerDefeated,
        'Vous avez battu Gamin Chuk !',
      ),
      _message(RuntimePostBattleMessageKind.money, 'Vous remportez 80 ₽ !'),
    ];

    final withSprite = buildPostBattleScenePlanSegment(
      messages: messages,
      activePartySlot: 0,
      fromXpProgress: 0,
      targetXpProgress: null,
      showDefeatedTrainerVisual: true,
    ).plan.steps;
    final spriteIndex =
        withSprite.indexWhere((s) => s is ShowDefeatedTrainerStep);
    final defeatedIndex = withSprite.indexWhere(
      (s) => s is ShowMessageStep && s.message.contains('Vous avez battu'),
    );
    expect(spriteIndex, isNot(-1));
    expect(
      spriteIndex,
      lessThan(defeatedIndex),
      reason: 'le dresseur réapparaît AVANT que son message s’affiche',
    );

    final withoutSprite = buildPostBattleScenePlanSegment(
      messages: messages,
      activePartySlot: 0,
      fromXpProgress: 0,
      targetXpProgress: null,
    ).plan.steps;
    expect(
      withoutSprite.whereType<ShowDefeatedTrainerStep>(),
      isEmpty,
      reason: 'fallback demandé : pas d’image, pas de step — le message seul',
    );
  });

  test('les gains d’un Pokémon non affiché restent des messages sans tween',
      () {
    final segment = buildPostBattleScenePlanSegment(
      messages: <RuntimePostBattleMessage>[
        _message(
          RuntimePostBattleMessageKind.experience,
          'réserve a gagné 100 points Exp. !',
          partySlot: 2,
        ),
        _message(
          RuntimePostBattleMessageKind.levelUp,
          'réserve monte au N. 7 !',
          partySlot: 2,
        ),
      ],
      activePartySlot: 0,
      fromXpProgress: 0.5,
      targetXpProgress: 0.9,
    );

    expect(segment.plan.steps.whereType<HudXpTweenStep>(), isEmpty);
    expect(segment.plan.steps.whereType<PlaySeStep>(), isEmpty);
    expect(segment.endXpProgress, 0.5);
  });
}
