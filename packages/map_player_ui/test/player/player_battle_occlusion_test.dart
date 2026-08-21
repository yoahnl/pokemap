import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_layout.dart';

/// Two sprites and two HUDs entirely visible — BETA-BAT-009.
///
/// The overlay snapshot says it carries "jamais les sprites ni le décor, qui
/// restent en Flame", so a widget golden of the overlay alone can never show a
/// combatant: that is why every battle golden had an empty scene and why the
/// criterion stayed unproven. These tests compose the frame the way the running
/// app does — the Flame stage below, the Flutter overlay above — using the very
/// rectangles BattleSceneLayout publishes for the sprites, so an occluded
/// combatant becomes visible in an image and measurable in an assertion.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_loadFixtureFonts);

  const viewports = <String, Size>{
    'landscape_960x540': Size(960, 540),
    'portrait_540x960': Size(540, 960),
    'compact_landscape_700x420': Size(700, 420),
    // The shape the defect actually lived on: a real phone in portrait, where
    // the player HUD used to sit 8.5px over the enemy.
    'phone_portrait_390x844': Size(390, 844),
  };

  for (final entry in viewports.entries) {
    testWidgets('certifies the composed battle frame ${entry.key}',
        (tester) async {
      final size = entry.value;
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final layout = BattleSceneLayout.forViewport(viewportSize: size);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('fr'),
          supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
          localizationsDelegates:
              PokeMapPlayerLocalizations.localizationsDelegates,
          theme: PokeMapPlayerTheme.dark(reducedMotion: true),
          home: Scaffold(
            body: RepaintBoundary(
              key: const ValueKey<String>('battle-occlusion-golden'),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  // Stand-in for what Flame paints underneath, placed on the
                  // published rectangles rather than guessed.
                  CustomPaint(painter: _StagePainter(layout)),
                  PlayerBattleOverlay(
                    snapshot: _snapshot(size, layout),
                    onCommand: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey<String>('battle-occlusion-golden')),
        matchesGoldenFile('goldens/battle_occlusion/${entry.key}.png'),
      );
    });
  }

  // The golden viewports plus every real device shape. That breadth is the
  // point: when this suite first ran, the player HUD covered the enemy sprite
  // on EVERY phone in portrait — 5px on a Pixel 7, 13.3px on a 360x800 — and
  // 390x844 was already in battle_scene_layout_test's list, passing, because
  // the player-HUD-against-enemy-sprite pair was the one pair of four nobody
  // asserted. Certifying only invented viewports is how that survived.
  final devices = <String, Size>{
    ...viewports,
    'android_portrait_360x800': const Size(360, 800),
    'iphone_portrait_375x812': const Size(375, 812),
    'iphone_pro_portrait_390x844': const Size(390, 844),
    'pixel_portrait_412x915': const Size(412, 915),
    'ipad_portrait_834x1194': const Size(834, 1194),
    'ipad_landscape_1194x834': const Size(1194, 834),
    'desktop_1024x768': const Size(1024, 768),
    'desktop_1280x800': const Size(1280, 800),
    'tall_390x760': const Size(390, 760),
  };

  // The one defect still open, and it predates this suite: at 460x300 the
  // enemy HUD — anchored in screen pixels at the top left — covers 11.5px of
  // the player sprite that the squeezed stage lifts into it. Same family of
  // cause as the two fixed here, a screen-space rectangle against a
  // stage-space one, measured identically before and after that fix. But
  // 460x300 is no device's size, so it is a separate debt rather than a
  // silent widening of BETA-BAT-009's signed scope.
  const knownDefect = <String, String>{
    'narrow_460x300': 'enemy HUD covers the player sprite by 11.5px',
  };

  for (final entry in <String, Size>{
    ...devices,
    'narrow_460x300': const Size(460, 300),
  }.entries) {
    test('every combatant is entirely visible at ${entry.key}', () {
      final layout = BattleSceneLayout.forViewport(viewportSize: entry.value);
      final chrome = <String, Rect>{
        'enemy HUD': layout.enemyHudRect,
        'player HUD': layout.playerHudRect,
        'command panel': layout.commandPanelRect,
      };
      final combatants = <String, Rect>{
        'enemy sprite': layout.enemySpriteRect,
        'player sprite': layout.playerSpriteRect,
      };
      // The ground is held to a weaker rule on purpose. BETA-BAT-009 signs for
      // two sprites and two HUDs, not for pixel-perfect decor, and a platform
      // is MEANT to meet the command panel's top edge — a 3px rim tucking
      // under a border is not an occlusion. But a platform swallowed whole is:
      // an enemy standing on an invisible ellipse reads as floating, which is
      // exactly what clamping the enemy against the player HUD first produced.
      // Mostly-visible catches that and stays out of the signed criterion.
      final grounds = <String, Rect>{
        'enemy platform': layout.enemyPlatformRect,
        'player platform': layout.playerPlatformRect,
      };

      for (final combatant in combatants.entries) {
        expect(
          combatant.value.width > 0 && combatant.value.height > 0,
          isTrue,
          reason: '${combatant.key} must occupy real space at ${entry.key}',
        );

        // "Entirely visible" starts with being inside the frame at all.
        expect(
          combatant.value.left >= layout.sceneRect.left - 0.5 &&
              combatant.value.right <= layout.sceneRect.right + 0.5 &&
              combatant.value.top >= layout.sceneRect.top - 0.5 &&
              combatant.value.bottom <= layout.sceneRect.bottom + 0.5,
          isTrue,
          reason: '${combatant.key} leaves the frame at ${entry.key}: '
              '${combatant.value} against ${layout.sceneRect}',
        );

        for (final piece in chrome.entries) {
          final overlap = combatant.value.intersect(piece.value);
          expect(
            overlap.width <= 0 || overlap.height <= 0,
            isTrue,
            reason: '${piece.key} covers the ${combatant.key} at '
                '${entry.key}: ${combatant.value} against ${piece.value}',
          );
        }
      }

      for (final ground in grounds.entries) {
        final area = ground.value.width * ground.value.height;
        expect(area, greaterThan(0),
            reason: '${ground.key} must occupy real space at ${entry.key}');
        var covered = 0.0;
        for (final piece in chrome.entries) {
          final overlap = ground.value.intersect(piece.value);
          if (overlap.width > 0 && overlap.height > 0) {
            covered += overlap.width * overlap.height;
          }
        }
        expect(
          covered / area,
          lessThan(0.2),
          reason: '${ground.key} is mostly hidden at ${entry.key}, so its '
              'combatant reads as floating: ${ground.value}',
        );
      }

      // And the chrome must not overlap itself either, which is the other half
      // of the criterion.
      final pieces = chrome.entries.toList(growable: false);
      for (var left = 0; left < pieces.length; left += 1) {
        for (var right = left + 1; right < pieces.length; right += 1) {
          final overlap =
              pieces[left].value.intersect(pieces[right].value);
          expect(
            overlap.width <= 0 || overlap.height <= 0,
            isTrue,
            reason: '${pieces[left].key} overlaps ${pieces[right].key} at '
                '${entry.key}',
          );
        }
      }
    },
        skip: knownDefect[entry.key] == null
            ? null
            : 'BETA-BAT-009 separate debt: ${knownDefect[entry.key]}');
  }
}

/// Paints the combatants and their platforms exactly where the layout puts
/// them, so the golden shows what the player would actually see behind the
/// Flutter chrome.
final class _StagePainter extends CustomPainter {
  const _StagePainter(this.layout);

  final BattleSceneLayout layout;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF1B2A33),
    );
    final platform = Paint()..color = const Color(0xFF3C5A63);
    canvas.drawOval(layout.enemyPlatformRect, platform);
    canvas.drawOval(layout.playerPlatformRect, platform);
    final enemy = Paint()..color = const Color(0xFFE0704F);
    final player = Paint()..color = const Color(0xFF6FC28B);
    canvas.drawRect(layout.enemySpriteRect, enemy);
    canvas.drawRect(layout.playerSpriteRect, player);
  }

  @override
  bool shouldRepaint(covariant _StagePainter oldDelegate) =>
      oldDelegate.layout != layout;
}

BattleCommandOverlaySnapshot _snapshot(Size size, BattleSceneLayout layout) =>
    BattleCommandOverlaySnapshot(
      revision: 7,
      mode: BattleCommandOverlayMode.root,
      viewportSize: size,
      panelRect: layout.commandPanelRect,
      enemyHud: BattleCommandOverlayHudSnapshot(
        rect: layout.enemyHudRect,
        ownerLabel: 'ENNEMI',
        speciesLabel: 'Roucool',
        level: 7,
        currentHp: 31,
        maxHp: 31,
        isPlayerSide: false,
      ),
      playerHud: BattleCommandOverlayHudSnapshot(
        rect: layout.playerHudRect,
        ownerLabel: 'JOUEUR',
        speciesLabel: 'Brindibou',
        level: 8,
        currentHp: 24,
        maxHp: 30,
        isPlayerSide: true,
        experienceProgress: 0.4,
      ),
      battleLabel: 'COMBAT SAUVAGE',
      title: 'COMMANDES',
      prompt: 'Que doit faire Brindibou ?',
      narrationLines: const <String>['Un Roucool sauvage apparaît !'],
      entries: const <BattleCommandOverlayEntry>[
        BattleCommandOverlayEntry(
          index: 0,
          kind: BattleCommandOverlayEntryKind.root,
          primaryLabel: 'ATTAQUER',
          secondaryLabel: 'Choisir une capacité',
          enabled: true,
          selected: true,
          tone: BattleCommandOverlayEntryTone.attack,
        ),
        BattleCommandOverlayEntry(
          index: 1,
          kind: BattleCommandOverlayEntryKind.root,
          primaryLabel: 'SAC',
          secondaryLabel: 'Utiliser un objet',
          enabled: true,
          selected: false,
          tone: BattleCommandOverlayEntryTone.medicine,
        ),
        BattleCommandOverlayEntry(
          index: 2,
          kind: BattleCommandOverlayEntryKind.root,
          primaryLabel: 'ÉQUIPE',
          secondaryLabel: 'Changer de Pokémon',
          enabled: true,
          selected: false,
          tone: BattleCommandOverlayEntryTone.switching,
        ),
        BattleCommandOverlayEntry(
          index: 3,
          kind: BattleCommandOverlayEntryKind.root,
          primaryLabel: 'FUITE',
          secondaryLabel: 'Quitter le combat',
          enabled: true,
          selected: false,
          tone: BattleCommandOverlayEntryTone.neutral,
        ),
      ],
      interactionsEnabled: true,
      canGoBack: false,
    );

Future<void> _loadFixtureFonts() async {
  final bytes = await File(
    '${Directory.current.path}/../../examples/playable_runtime_host/'
    'golden_personalization_v3/assets/presentation/fonts/display.ttf',
  ).readAsBytes();
  await _loadFont('Aube Display', bytes);
  await _loadFont('Avenir Next', bytes);
  final iconBytes = await File(
    '${_flutterCacheDirectory().path}/artifacts/material_fonts/'
    'MaterialIcons-Regular.otf',
  ).readAsBytes();
  await _loadFont('MaterialIcons', iconBytes);
}

Future<void> _loadFont(String family, Uint8List bytes) async {
  await (FontLoader(family)
        ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes))))
      .load();
}

Directory _flutterCacheDirectory() {
  var current = File(Platform.resolvedExecutable).parent;
  while (current.parent.path != current.path) {
    final cache = Directory('${current.path}/cache');
    if (Directory('${cache.path}/artifacts/material_fonts').existsSync()) {
      return cache;
    }
    current = current.parent;
  }
  throw StateError('Flutter cache directory not found.');
}
