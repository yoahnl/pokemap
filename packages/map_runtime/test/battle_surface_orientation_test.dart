import 'dart:ui' show Size;

import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';

import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_command_panel_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_hud_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_layout.dart';

/// Portrait et paysage : les deux couches sont-elles d'accord ?
///
/// Critère d'acceptation de BETA-BAT-007 : « surfaces portrait et paysage
/// certifiées ». `battle_scene_layout_test` couvre déjà largement le MODÈLE de
/// composition, à 390x844, 844x390 et 1280x720. Ce qui n'était pas épinglé est la
/// jonction : le panneau de commandes possède SA PROPRE heuristique —
/// `largeur < 700 || rapport < 2.45` — et n'obéit au modèle de scène que parce
/// que l'overlay lui passe `layoutModeOverride`.
///
/// Retirer ce passage ne casserait rien de visible sur un viewport où les deux
/// règles tombent d'accord. Ces cas choisissent donc exprès un viewport où elles
/// se CONTREDISENT : c'est le seul endroit où l'obéissance se démontre.
///
/// PIÈGE DE HARNAIS, rencontré en écrivant ce fichier. `currentLayoutMode`
/// retombe sur `split` quand la disposition interne du panneau n'a pas encore
/// été calculée, et `onLoad()` sur l'overlay ne monte pas ses enfants. Une
/// première version lisait donc cette valeur par défaut sur TOUS les viewports
/// et ne mesurait rien : elle rapportait `split` à 390x844, où les deux règles
/// disent pourtant `stacked`. Il faut monter l'overlay dans un vrai `FlameGame`
/// pour que le panneau calcule sa disposition.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BETA-BAT-007 the command panel obeys the scene orientation', () {
    test('the panel obeys an override that contradicts its own rule', () async {
      // Le panneau d'un viewport portrait 800x1200 mesure 776x304 : largeur au
      // dessus de 700 ET rapport 2.55 au dessus de 2.45, donc sa propre règle
      // dirait `split`. C'est le seul endroit où l'obéissance se démontre : sur
      // un viewport où les deux règles s'accordent, retirer l'override ne
      // casserait rien de visible.
      final panelSize = Vector2(776, 304);
      expect(
        _panelOwnRuleWouldSplit(panelSize),
        isTrue,
        reason: 'the vector is pointless unless the two rules disagree here',
      );

      final panel = await _mountedPanel(
        panelSize,
        override: BattleCommandPanelLayoutMode.stacked,
      );

      expect(panel.currentLayoutMode, BattleCommandPanelLayoutMode.stacked);
    });

    test('without an override the panel falls back to its own rule', () async {
      // Contraste : sans lui, un panneau toujours stacked passerait le cas
      // précédent, et le repli ne serait pas décrit.
      final panel = await _mountedPanel(Vector2(776, 304));

      expect(panel.currentLayoutMode, BattleCommandPanelLayoutMode.split);
    });

    test('the width clause alone decides between 300 and 700', () async {
      // Vecteur qui ISOLE la clause de largeur : rapport 2.78, donc au dessus du
      // seuil de 2.45, et largeur 500. Seule la clause `< 700` peut décider ici.
      // Sans ce cas, abaisser ce seuil ne cassait rien.
      final panelSize = Vector2(500, 180);
      expect(panelSize.x / panelSize.y, greaterThan(2.45));

      final panel = await _mountedPanel(panelSize);

      expect(panel.currentLayoutMode, BattleCommandPanelLayoutMode.stacked);
    });

    test('a narrow panel stacks even without an override', () async {
      final panel = await _mountedPanel(Vector2(366, 280));

      expect(_panelOwnRuleWouldSplit(Vector2(366, 280)), isFalse);
      expect(panel.currentLayoutMode, BattleCommandPanelLayoutMode.stacked);
    });

    test('the overlay hands the scene decision down to its panel', () async {
      // La transmission elle-même : l'overlay passe
      // `layoutModeOverride: layout.commandPanelLayoutMode`. La retirer ne
      // casserait rien sur un viewport où les deux règles s'accordent, d'où le
      // 800x1200 où elles se contredisent.
      for (final viewport in const <Size>[
        Size(800, 1200),
        Size(1280, 720),
        Size(390, 844),
      ]) {
        final scene = _sceneLayoutFor(viewport);
        final panel = await _mountedOverlayPanel(viewport);

        expect(
          panel.currentLayoutMode,
          scene.commandPanelLayoutMode,
          reason: '$viewport',
        );
      }
    });

    test('the text scale grows the command labels', () async {
      // « Accessibilité texte » de BETA-BAT-007. `textScale` de
      // GameSessionAccessibilityOptions n'atteignait pas le runtime : rien sous
      // `presentation/` ne le lisait. Il traverse maintenant jusqu'aux tailles de
      // police décidées par la disposition du panneau.
      final normal = await _mountedPanel(Vector2(776, 304));
      final larger = await _mountedPanel(Vector2(776, 304), textScale: 1.5);

      expect(
        larger.currentPromptFontSize,
        greaterThan(normal.currentPromptFontSize),
      );
      expect(
        larger.currentCommandLabelFontSize,
        greaterThan(normal.currentCommandLabelFontSize),
      );
    });

    test('an absurd text scale is clamped instead of ruining the panel',
        () async {
      // Au-delà de la borne, l'ellipse du cache de peinture tronque les
      // libellés : ça échoue proprement mais n'aide personne. Borner vaut mieux
      // que laisser passer.
      final clamped = await _mountedPanel(Vector2(776, 304), textScale: 12);
      final atMax = await _mountedPanel(
        Vector2(776, 304),
        textScale: battleMaximumTextScale,
      );

      expect(clamped.currentPromptFontSize, atMax.currentPromptFontSize);
    });

    test('the overlay hands the text scale down to its panel', () async {
      // La transmission, distincte de l'application : construire le panneau en
      // direct ne prouve pas que l'overlay lui passe l'échelle. Sans ce cas,
      // retirer le passage laissait la suite verte.
      final normal = await _mountedOverlayPanel(const Size(1280, 720));
      final larger = await _mountedOverlayPanel(
        const Size(1280, 720),
        textScale: 1.5,
      );

      expect(
        larger.currentPromptFontSize,
        greaterThan(normal.currentPromptFontSize),
      );
    });

    test('the overlay hands the text scale down to its HUDs', () async {
      // Même distinction que pour le panneau, et le HUD a quatre points de
      // construction dans l'overlay au lieu d'un : en oublier un laisserait un
      // HUD sur deux au texte d'origine. Le viewport 1280x720 donne au HUD
      // joueur 244x74, une boîte qui accorde environ 1.21 sur les 1.5 demandés.
      final normal = await _mountedOverlayPlayerHud(const Size(1280, 720));
      final larger = await _mountedOverlayPlayerHud(
        const Size(1280, 720),
        textScale: 1.5,
      );

      expect(
        larger.currentLayout.nameFontSize,
        greaterThan(normal.currentLayout.nameFontSize),
      );
      expect(larger.currentLayout.effectiveTextScale, greaterThan(1.0));
    });

    test('the overlay hands it to the enemy HUD too, not only the player one',
        () async {
      // Le HUD ennemi se construit à deux endroits distincts du HUD joueur.
      final normal = await _mountedOverlayEnemyHud(const Size(1280, 720));
      final larger = await _mountedOverlayEnemyHud(
        const Size(1280, 720),
        textScale: 1.5,
      );

      expect(
        larger.currentLayout.nameFontSize,
        greaterThan(normal.currentLayout.nameFontSize),
      );
    });

    test('a text scale below the floor is clamped too', () async {
      final tiny = await _mountedPanel(Vector2(776, 304), textScale: 0.05);
      final atMin = await _mountedPanel(
        Vector2(776, 304),
        textScale: battleMinimumTextScale,
      );

      expect(tiny.currentPromptFontSize, atMin.currentPromptFontSize);
    });

    test('the panel mode follows the scene on every certified viewport', () {
      // Invariant plutôt que cas particuliers : quelle que soit la taille, le
      // mode que l'overlay transmet est celui du modèle de scène.
      for (final viewport in const <Size>[
        Size(390, 844),
        Size(844, 390),
        Size(768, 1024),
        Size(1024, 768),
        Size(1280, 720),
        Size(528, 467),
      ]) {
        final layout = _sceneLayoutFor(viewport);

        expect(
          layout.commandPanelLayoutMode,
          layout.isPortrait
              ? BattleCommandPanelLayoutMode.stacked
              : anyOf(
                  BattleCommandPanelLayoutMode.split,
                  BattleCommandPanelLayoutMode.stacked,
                ),
          reason: '$viewport',
        );
      }
    });

    test('a portrait viewport never gets a split panel', () {
      // Le sens qui compte : en portrait, un panneau en deux colonnes déborde.
      for (final viewport in const <Size>[
        Size(390, 844),
        Size(768, 1024),
        Size(800, 1200),
        Size(360, 640),
      ]) {
        final layout = _sceneLayoutFor(viewport);

        expect(layout.isPortrait, isTrue, reason: '$viewport');
        expect(
          layout.commandPanelLayoutMode,
          BattleCommandPanelLayoutMode.stacked,
          reason: '$viewport',
        );
      }
    });
  });
}

/// Ce que l'heuristique propre du panneau dirait, pour montrer qu'elle est bien
/// contredite. Transcrite depuis `_BattleCommandPanelLayout.forSize`.
bool _panelOwnRuleWouldSplit(Vector2 panelSize) {
  final aspect = panelSize.x / (panelSize.y <= 0 ? 1 : panelSize.y);
  return panelSize.x >= 700 && aspect >= 2.45;
}

/// Panneau d'un overlay réellement monté au viewport donné.
///
/// Le `onGameResize` est indispensable et c'est ce qui m'a manqué longtemps :
/// sans taille de jeu, l'overlay ne construit pas son panneau du tout et la
/// recherche rend une liste vide.
Future<BattleCommandPanelComponent> _mountedOverlayPanel(
  Size viewport, {
  double textScale = 1.0,
}) async {
  final overlay = BattleOverlayComponent(
    textScale: textScale,
    session: createBattleSession(
      BattleSetup.pokeMapBetaV1ForTest(
        playerPokemon: _combatant('charmander', 0),
        enemyPokemon: _combatant('squirtle', 0),
        isTrainerBattle: false,
        trainerId: null,
      ),
    ),
    viewportSize: Vector2(viewport.width, viewport.height),
    onPlayerChoice: (_) {},
  );
  final game = FlameGame();
  game.onGameResize(Vector2(viewport.width, viewport.height));
  await game.add(overlay);
  await game.ready();
  return overlay.children.whereType<BattleCommandPanelComponent>().single;
}

Future<BattleSceneHudComponent> _mountedOverlayPlayerHud(
  Size viewport, {
  double textScale = 1.0,
}) async {
  return _mountedOverlayHuds(viewport, textScale: textScale)
      .then((huds) => huds.singleWhere((hud) => hud.isPlayerSide));
}

Future<BattleSceneHudComponent> _mountedOverlayEnemyHud(
  Size viewport, {
  double textScale = 1.0,
}) async {
  return _mountedOverlayHuds(viewport, textScale: textScale)
      .then((huds) => huds.singleWhere((hud) => !hud.isPlayerSide));
}

Future<List<BattleSceneHudComponent>> _mountedOverlayHuds(
  Size viewport, {
  double textScale = 1.0,
}) async {
  final overlay = BattleOverlayComponent(
    textScale: textScale,
    session: createBattleSession(
      BattleSetup.pokeMapBetaV1ForTest(
        playerPokemon: _combatant('charmander', 0),
        enemyPokemon: _combatant('squirtle', 0),
        isTrainerBattle: false,
        trainerId: null,
      ),
    ),
    viewportSize: Vector2(viewport.width, viewport.height),
    onPlayerChoice: (_) {},
  );
  final game = FlameGame();
  game.onGameResize(Vector2(viewport.width, viewport.height));
  await game.add(overlay);
  await game.ready();
  return overlay.children.whereType<BattleSceneHudComponent>().toList();
}

BattleCombatantData _combatant(String speciesId, int lineupIndex) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: 20,
    maxHp: 40,
    stats: const BattleStatsSnapshot(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    moves: const <BattleMoveData>[
      BattleMoveData(
        id: 'scratch',
        name: 'Scratch',
        power: 40,
        category: BattleMoveCategory.physical,
        target: BattleMoveTarget.opponent,
        accuracy: BattleMoveAccuracy.alwaysHits(),
      ),
    ],
  );
}

BattleSceneLayout _sceneLayoutFor(Size viewport) {
  return BattleSceneLayout.forViewport(viewportSize: viewport);
}

/// Monte un panneau de commandes seul, à la taille et au mode voulus.
///
/// Le panneau est l'unité qui DÉCIDE la disposition ; le tester seul isole cette
/// décision de tout le reste de l'overlay.
///
/// Il faut vraiment le monter : `currentLayoutMode` retombe silencieusement sur
/// `split` tant que la disposition interne n'a pas été calculée, et une première
/// version de ce fichier lisait cette valeur par défaut partout — elle
/// rapportait `split` à 366x280, où la règle du panneau dit pourtant `stacked`.
Future<BattleCommandPanelComponent> _mountedPanel(
  Vector2 panelSize, {
  BattleCommandPanelLayoutMode? override,
  double textScale = 1.0,
}) async {
  final panel = BattleCommandPanelComponent(
    position: Vector2.zero(),
    size: panelSize,
    onChoiceSelected: (_) {},
    onRootActionSelected: (_) {},
    onPartyEntrySelected: (_) {},
    layoutModeOverride: override,
    textScale: textScale,
  );
  final game = FlameGame();
  // Sans taille de jeu, le composant ne charge JAMAIS : onLoad ne tourne pas, la
  // disposition interne reste nulle, et currentLayoutMode rend son defaut
  // `split`. Mesure a l appui : isLoaded=false sans ce resize, true avec.
  game.onGameResize(Vector2(1024, 768));
  await game.add(panel);
  await game.ready();
  return panel;
}
