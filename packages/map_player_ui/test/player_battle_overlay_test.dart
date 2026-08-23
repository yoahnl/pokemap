import 'package:flutter/material.dart';
import 'dart:ui' show Tristate;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_layout.dart';

import 'fixtures/personalization_studio_v2_fixture.dart';

void main() {
  testWidgets(
    'runtime battle overlay consumes the canonical geometry at captured viewports',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));

      for (final viewport in const <Size>[
        Size(1069, 652),
        Size(508, 379),
        Size(436, 697),
      ]) {
        for (final textScaler in const <TextScaler>[
          TextScaler.noScaling,
          TextScaler.linear(2),
        ]) {
          await tester.binding.setSurfaceSize(viewport);
          final layout = BattleSceneLayout.forViewport(viewportSize: viewport);
          BattlePresentationCommand? command;

          await _pumpOverlay(
            tester,
            snapshot: _rootSnapshot(
              viewportSize: viewport,
              panelRect: layout.commandPanelRect,
              enemyHudRect: layout.enemyHudRect,
              playerHudRect: layout.playerHudRect,
              narrationLines: const <String>[
                'Un Roucool sauvage apparaît !',
                'Vas-y, Brindibou !',
              ],
            ),
            onCommand: (value) => command = value,
            textScaler: textScaler,
          );

          final panelRect = tester.getRect(
            find.byKey(const ValueKey<String>('battle-command-panel')),
          );
          final dialogueRect = tester.getRect(
            find.byKey(const ValueKey<String>('battle-dialogue-panel')),
          );
          final actionsRect = tester.getRect(
            find.byKey(const ValueKey<String>('battle-actions-panel')),
          );
          expect(
            find.byKey(const ValueKey<String>('battle-panel-commands-grid')),
            findsOneWidget,
          );
          _expectRectClose(panelRect, layout.commandPanelRect);
          final compactPortrait =
              viewport.width < 480 && viewport.height > viewport.width;
          expect(
            panelRect.inflate(0.5).contains(dialogueRect.topLeft) &&
                panelRect.inflate(0.5).contains(dialogueRect.bottomRight),
            isTrue,
          );
          expect(
            panelRect.inflate(0.5).contains(actionsRect.topLeft) &&
                panelRect.inflate(0.5).contains(actionsRect.bottomRight),
            isTrue,
          );
          if (compactPortrait) {
            expect(dialogueRect.left, closeTo(actionsRect.left, 0.5));
            expect(dialogueRect.right, closeTo(actionsRect.right, 0.5));
            expect(
                actionsRect.top - dialogueRect.bottom, inInclusiveRange(1, 16));
            expect(dialogueRect.bottom, lessThan(actionsRect.top));
          } else {
            expect(dialogueRect.top, closeTo(actionsRect.top, 0.5));
            expect(dialogueRect.bottom, closeTo(actionsRect.bottom, 0.5));
            expect(
                actionsRect.left - dialogueRect.right, inInclusiveRange(1, 12));
            expect(actionsRect.width, greaterThan(dialogueRect.width));
          }
          expect(
            dialogueRect.contains(
              tester.getCenter(
                find.byKey(
                  const ValueKey<String>('battle-dialogue-prompt'),
                ),
              ),
            ),
            isTrue,
          );
          expect(find.text('COMMANDES'), findsNothing);
          _expectRectClose(
            tester.getRect(
              find.byKey(const ValueKey<String>('battle-hud-target-enemy')),
            ),
            layout.enemyHudRect,
          );
          _expectRectClose(
            tester.getRect(
              find.byKey(const ValueKey<String>('battle-hud-target-player')),
            ),
            layout.playerHudRect,
          );
          expect(
            find.byKey(const ValueKey<String>('battle-owner-enemy')),
            findsNothing,
          );
          expect(
            find.byKey(const ValueKey<String>('battle-owner-player')),
            findsNothing,
          );
          expect(
            tester
                .getRect(
                  find.byKey(
                    const ValueKey<String>('battle-species-enemy'),
                  ),
                )
                .left,
            greaterThanOrEqualTo(layout.enemyHudRect.left + 4),
          );
          for (var index = 0; index < 4; index++) {
            final entryRect = tester.getRect(
              find.byKey(ValueKey<String>('battle-entry-$index')),
            );
            expect(
              actionsRect.inflate(0.5).contains(entryRect.topLeft) &&
                  actionsRect.inflate(0.5).contains(entryRect.bottomRight),
              isTrue,
              reason: 'root command $index must remain inside the actions '
                  'window at '
                  '$viewport with $textScaler',
            );
          }
          expect(panelRect.overlaps(layout.enemyCombatantBoundsRect), isFalse);
          expect(panelRect.overlaps(layout.playerCombatantBoundsRect), isFalse);
          expect(find.text('FUITE'), findsOneWidget);
          await tester.tap(find.text('FUITE'));
          expect(
            command,
            isA<BattleSelectEntryCommand>().having(
              (value) => value.entryIndex,
              'runtime index',
              3,
            ),
            reason: 'FUITE must remain activatable at $viewport '
                'with $textScaler',
          );
          expect(
            tester.takeException(),
            isNull,
            reason: 'no layout exception is allowed at $viewport '
                'with $textScaler',
          );
        }
      }
    },
  );

  testWidgets(
    'fight submenu keeps its prompt and back action in the dialogue strip',
    (tester) async {
      const viewport = Size(508, 379);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(viewport);
      BattlePresentationCommand? command;

      await _pumpOverlay(
        tester,
        snapshot: _snapshot(viewportSize: viewport),
        onCommand: (value) => command = value,
      );

      final dialogueRect = tester.getRect(
        find.byKey(const ValueKey<String>('battle-dialogue-panel')),
      );
      expect(
        dialogueRect.contains(
          tester.getCenter(
            find.byKey(const ValueKey<String>('battle-dialogue-prompt')),
          ),
        ),
        isTrue,
      );
      expect(find.text('CAPACITÉS'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('battle-dialogue-panel')),
          matching: find.byKey(const ValueKey<String>('battle-back')),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey<String>('battle-back')));
      expect(command, isA<BattleBackCommand>());
      final exception = tester.takeException();
      expect(
        exception,
        isNull,
        reason: exception is FlutterError
            ? exception.toStringDeep()
            : exception?.toString(),
      );
    },
  );

  testWidgets(
    'move cards show localized types, live PP and the combatant gender',
    (tester) async {
      const viewport = Size(436, 697);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(viewport);

      await _pumpOverlay(
        tester,
        snapshot: _snapshot(
          viewportSize: viewport,
          enemyGender: '♀',
          playerGender: '♂',
          entries: _richMoveEntries,
        ),
        onCommand: (_) {},
      );

      Material entryMaterial(int index) {
        final semantics = tester.widget<Semantics>(
          find.byKey(ValueKey<String>('battle-entry-$index')),
        );
        return (semantics.child! as Tooltip).child! as Material;
      }

      final dockPanel = tester.widget<PlayerPanel>(
        find.byKey(const ValueKey<String>('battle-command-panel')),
      );
      expect(find.text('NORMAL'), findsOneWidget);
      expect(find.text('EAU · SPÉCIAL'), findsOneWidget);
      expect(find.text('ÉLECTRIK'), findsOneWidget);
      expect(find.text('FEU'), findsOneWidget);
      expect(find.text('PP 35/35'), findsOneWidget);
      expect(find.text('PP 17/25'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('battle-gender-enemy')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('battle-gender-player')),
        findsOneWidget,
      );
      expect(entryMaterial(0).shape, isA<BeveledRectangleBorder>());
      expect(entryMaterial(0).color, isNot(entryMaterial(1).color));
      expect(
        entryMaterial(1).elevation,
        greaterThan(entryMaterial(0).elevation),
      );
      expect(dockPanel.surfaceColorOverride, const Color(0xFF111916));
      expect(dockPanel.textColorOverride, const Color(0xFFF3ECD9));
      final exception = tester.takeException();
      expect(
        exception,
        isNull,
        reason: exception is FlutterError
            ? exception.toStringDeep()
            : exception?.toString(),
      );
    },
  );

  // Recette 2026-08-23 (vidéo 22-57-18, macOS) : la barre animait pendant que
  // le nombre affichait l'état FINAL — « 15/15 → 9/15 » en une frame, la
  // barre en 600 ms. Le nombre et la barre partagent désormais le même tween.
  testWidgets(
    'le nombre de PV suit la barre pendant le drain, pas l’état final',
    (tester) async {
      const viewport = Size(436, 697);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(viewport);

      await _pumpOverlay(
        tester,
        snapshot: _snapshot(
          viewportSize: viewport,
          playerHp: 9,
          playerDisplayedHp: 61,
          playerTargetDisplayedHp: 9,
          playerHpTweenDurationMs: 600,
          playerHpTweenRevision: 3,
        ),
        onCommand: (_) {},
      );
      await tester.pump(const Duration(milliseconds: 60));

      String readPlayerHp() {
        final text = tester.widget<Text>(
          find.byKey(const ValueKey<String>('battle-exact-hp-player')),
        );
        return text.data ?? '';
      }

      final early = readPlayerHp();
      expect(
        early,
        isNot(contains('9/72')),
        reason: 'au début du drain, le nombre ne montre pas l’état final '
            '(il affichait $early)',
      );

      await tester.pump(const Duration(milliseconds: 700));
      expect(
        readPlayerHp(),
        contains('9/72'),
        reason: 'une fois le drain joué, le nombre atteint la valeur finale',
      );
    },
  );

  testWidgets(
    'la barre d’XP se remplit pendant le message de gain, pas d’un coup',
    (tester) async {
      const viewport = Size(436, 697);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(viewport);

      await _pumpOverlay(
        tester,
        snapshot: _snapshot(
          viewportSize: viewport,
          playerExperienceProgress: 0.25,
          playerExperienceProgressTarget: 0.8,
          playerXpTweenDurationMs: 600,
          playerXpTweenRevision: 1,
        ),
        onCommand: (_) {},
      );
      await tester.pump(const Duration(milliseconds: 60));

      double readXpValue() {
        final bar = find.byKey(const ValueKey<String>('battle-xp-player'));
        final progress = tester.widget<LinearProgressIndicator>(
          find.descendant(
            of: bar,
            matching: find.byType(LinearProgressIndicator),
          ),
        );
        return progress.value ?? 0;
      }

      final early = readXpValue();
      expect(
        early,
        lessThan(0.8),
        reason: 'BETA-BAT-017 : au début du gain, la barre n’affiche pas '
            'déjà la cible (elle affichait $early)',
      );

      await tester.pump(const Duration(milliseconds: 700));
      expect(
        readXpValue(),
        moreOrLessEquals(0.8, epsilon: 0.001),
        reason: 'une fois le remplissage joué, la barre atteint la cible',
      );
    },
  );

  testWidgets(
    'default battle HUDs keep exact HP player-only and use compact rails',
    (tester) async {
      const viewport = Size(436, 697);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(viewport);

      await _pumpOverlay(
        tester,
        snapshot: _snapshot(
          viewportSize: viewport,
          playerExperienceProgress: 0.64,
        ),
        onCommand: (_) {},
      );

      expect(
        find.byKey(const ValueKey<String>('battle-status-badge-enemy')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('battle-exact-hp-enemy')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('battle-exact-hp-player')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('battle-xp-player')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('battle-xp-enemy')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('battle-hp-rounded-enemy')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('battle-hp-rounded-player')),
        findsOneWidget,
      );
      expect(find.text('XP'), findsOneWidget);
      final playerHudPanel = tester.widget<PlayerPanel>(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('battle-hud-target-player'),
          ),
          matching: find.byType(PlayerPanel),
        ),
      );
      expect(
        playerHudPanel.windowStyleOverride?.shape,
        ProjectWindowShape.cutCorner,
      );
      expect(tester.takeException(), isNull);

      await _pumpOverlay(
        tester,
        snapshot: _snapshot(
          viewportSize: viewport,
          playerExperienceProgress: 0.64,
        ),
        onCommand: (_) {},
        textScaler: const TextScaler.linear(2),
      );

      expect(
        find.byKey(const ValueKey<String>('battle-xp-player')),
        findsNothing,
      );
      expect(
        tester
            .getSemantics(
              find.byKey(
                const ValueKey<String>('battle-hud-semantics-player'),
              ),
            )
            .label,
        contains('64 %'),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'selected dark field manual design uses one dock and contextual move data',
    (tester) async {
      const viewport = Size(436, 697);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(viewport);

      await _pumpOverlay(
        tester,
        snapshot: _snapshot(
          viewportSize: viewport,
          enemyGender: '♀',
          playerGender: '♂',
          playerExperienceProgress: 0.64,
          entries: _richMoveEntries,
        ),
        onCommand: (_) {},
        theme: PokeMapPlayerTheme.light(reducedMotion: true),
      );

      final dock = tester.widget<PlayerPanel>(
        find.byKey(const ValueKey<String>('battle-command-panel')),
      );
      expect(dock.surfaceColorOverride, const Color(0xFF111916));
      expect(dock.textColorOverride, const Color(0xFFF3ECD9));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('battle-command-panel')),
          matching: find.byType(PlayerPanel),
        ),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('battle-selection-cursor-1')),
        findsOneWidget,
      );
      expect(find.text('EAU · SPÉCIAL'), findsOneWidget);
      expect(find.text('XP'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('golden rich move dock matches the portrait direction', (
    tester,
  ) async {
    const viewport = Size(436, 697);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(viewport);

    await _pumpOverlay(
      tester,
      snapshot: _snapshot(
        viewportSize: viewport,
        enemyGender: '♀',
        playerGender: '♂',
        playerExperienceProgress: 0.64,
        entries: _richMoveEntries,
      ),
      onCommand: (_) {},
      theme: PokeMapPlayerTheme.light(reducedMotion: true),
    );

    await expectLater(
      find.byType(PlayerBattleSurface),
      matchesGoldenFile('goldens/battle/rich_move_surface_436x697.png'),
    );
  });

  testWidgets(
    'battle bag renders rich item cards with project thumbnails',
    (tester) async {
      const viewport = Size(436, 697);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(viewport);

      await _pumpOverlay(
        tester,
        snapshot: _snapshot(
          viewportSize: viewport,
          mode: BattleCommandOverlayMode.bag,
          title: 'SAC',
          entries: _richBagEntries,
        ),
        onCommand: (_) {},
        itemIconBuilder: (path) => ColoredBox(
          key: ValueKey<String>('project-item-thumbnail-$path'),
          color: Colors.transparent,
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('battle-panel-target-bag-grid')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('project-item-thumbnail-/items/potion.png'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'project-item-thumbnail-/items/poke-ball.png',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('SOIN'), findsWidgets);
      expect(find.text('CAPTURE'), findsWidgets);
      expect(find.text('x4'), findsOneWidget);
      expect(find.text('OK'), findsNothing);
      final firstItemMaterial = tester.widget<Material>(
        find.descendant(
          of: find.byKey(const ValueKey<String>('battle-entry-0')),
          matching: find.byType(Material),
        ),
      );
      expect(firstItemMaterial.shape, isA<BeveledRectangleBorder>());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('battle bag loads the resolved thumbnail by default', (
    tester,
  ) async {
    await _pumpOverlay(
      tester,
      snapshot: _snapshot(
        mode: BattleCommandOverlayMode.bag,
        title: 'SAC',
        entries: _richBagEntries.take(2).toList(growable: false),
      ),
      onCommand: (_) {},
    );

    expect(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == 'BattleMobileItemIcon',
      ),
      findsNWidgets(2),
    );
  });

  testWidgets('battle bag remains usable across captured viewport classes', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final viewport in const <Size>[
      Size(436, 697),
      Size(508, 379),
      Size(1069, 652),
    ]) {
      for (final textScaler in const <TextScaler>[
        TextScaler.noScaling,
        TextScaler.linear(2),
      ]) {
        await tester.binding.setSurfaceSize(viewport);
        await _pumpOverlay(
          tester,
          snapshot: _snapshot(
            viewportSize: viewport,
            mode: BattleCommandOverlayMode.bag,
            title: 'SAC',
            entries: _richBagEntries,
          ),
          onCommand: (_) {},
          textScaler: textScaler,
          itemIconBuilder: (path) => const Icon(Icons.medication_rounded),
        );

        expect(
          find.byKey(const ValueKey<String>('battle-bag-items')),
          findsOneWidget,
        );
        expect(find.text('x4'), findsOneWidget);
        final exception = tester.takeException();
        expect(
          exception,
          isNull,
          reason: exception is FlutterError
              ? exception.toStringDeep()
              : 'bag at $viewport with $textScaler: $exception',
        );
      }
    }
  });

  testWidgets('golden rich battle bag matches the portrait direction', (
    tester,
  ) async {
    const viewport = Size(436, 697);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(viewport);

    await _pumpOverlay(
      tester,
      snapshot: _snapshot(
        viewportSize: viewport,
        mode: BattleCommandOverlayMode.bag,
        title: 'SAC',
        entries: _richBagEntries,
      ),
      onCommand: (_) {},
      theme: PokeMapPlayerTheme.light(reducedMotion: true),
      itemIconBuilder: (path) => Icon(
        path.contains('ball')
            ? Icons.catching_pokemon_rounded
            : Icons.medication_rounded,
      ),
    );

    await expectLater(
      find.byType(PlayerBattleSurface),
      matchesGoldenFile('goldens/battle/rich_bag_surface_436x697.png'),
    );
  });

  testWidgets('golden separated command dock matches the 508x379 reference', (
    tester,
  ) async {
    const viewport = Size(508, 379);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(viewport);

    await _pumpOverlay(
      tester,
      snapshot: _rootSnapshot(viewportSize: viewport),
      onCommand: (_) {},
      theme: PokeMapPlayerTheme.light(reducedMotion: true),
    );

    await expectLater(
      find.byKey(const ValueKey<String>('battle-command-panel')),
      matchesGoldenFile(
        'goldens/battle/separated_command_dock_508x379.png',
      ),
    );
  });

  testWidgets('runtime battle overlay waits for the matching resize snapshot', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(436, 697));

    await _pumpOverlay(
      tester,
      snapshot: _rootSnapshot(viewportSize: const Size(1069, 652)),
      onCommand: (_) {},
    );

    expect(
      find.byKey(const ValueKey<String>('battle-command-panel')),
      findsNothing,
    );

    await _pumpOverlay(
      tester,
      snapshot: _rootSnapshot(viewportSize: const Size(436, 697)),
      onCommand: (_) {},
    );

    expect(
      find.byKey(const ValueKey<String>('battle-command-panel')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'field manual HUD stays dark when a legacy project only has a light battle palette',
    (tester) async {
      final semantic = PokeMapPlayerSemanticTheme.tryFromHex(
        primary: '#2563EB',
        onPrimary: '#FFFFFF',
        background: '#E9E6DA',
        surface: '#E9E6DA',
        surfaceElevated: '#E9E6DA',
        textPrimary: '#1B242C',
        textSecondary: '#4F5860',
        outline: '#66717A',
        success: '#16794B',
        warning: '#8A5100',
        danger: '#B4233C',
        titleSurface: '#E9E6DA',
        dialogueSurface: '#E9E6DA',
        menuSurface: '#E9E6DA',
        overworldHudSurface: '#E9E6DA',
        battleHudSurface: '#E9E6DA',
      )!;
      final theme = PokeMapPlayerTheme.withSurfacePalettes(
        PokeMapPlayerTheme.withSemanticTheme(
          PokeMapPlayerTheme.dark(),
          semantic,
        ),
        const ProjectPresentationSurfacePalettesProfile(
          battle: ProjectSurfacePaletteProfile(surface: '#E9E6DA'),
        ),
      );

      await _pumpOverlay(
        tester,
        snapshot: _rootSnapshot(),
        onCommand: (_) {},
        theme: theme,
      );

      final species = tester.widget<Text>(
        find.byKey(const ValueKey<String>('battle-species-enemy')),
      );
      final exactHp = tester.widget<Text>(
        find.byKey(const ValueKey<String>('battle-exact-hp-player')),
      );
      const chrome = PokeMapPlayerBattleChrome.darkFieldManual;
      expect(species.style?.color, chrome.textPrimary);
      expect(exactHp.style?.color, chrome.textPrimary);
      expect(
        find.byKey(const ValueKey<String>('battle-hud-divider-enemy')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('battle-hud-divider-player')),
        findsOneWidget,
      );
      final enemyMaterial = tester.widget<Material>(
        find
            .descendant(
              of: find.byKey(
                const ValueKey<String>('battle-hud-target-enemy'),
              ),
              matching: find.byType(Material),
            )
            .first,
      );
      final playerMaterial = tester.widget<Material>(
        find
            .descendant(
              of: find.byKey(
                const ValueKey<String>('battle-hud-target-player'),
              ),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(enemyMaterial.color, chrome.surface);
      expect(playerMaterial.color, chrome.surface);
      final enemyShape = enemyMaterial.shape! as BeveledRectangleBorder;
      final playerShape = playerMaterial.shape! as BeveledRectangleBorder;
      expect(enemyShape.side.color, chrome.outline);
      expect(enemyShape.side.width, 2);
      expect(playerShape.side.color, chrome.outline);
      expect(playerShape.side.width, 2);
    },
  );

  testWidgets(
    'field manual HUD remains dark when V10 includes a light shared battle palette',
    (tester) async {
      final semantic = PokeMapPlayerSemanticTheme.tryFromHex(
        primary: '#2563EB',
        onPrimary: '#FFFFFF',
        background: '#E9E6DA',
        surface: '#E9E6DA',
        surfaceElevated: '#E9E6DA',
        textPrimary: '#1B242C',
        textSecondary: '#4F5860',
        outline: '#66717A',
        success: '#16794B',
        warning: '#8A5100',
        danger: '#B4233C',
        titleSurface: '#E9E6DA',
        dialogueSurface: '#E9E6DA',
        menuSurface: '#E9E6DA',
        overworldHudSurface: '#E9E6DA',
        battleHudSurface: '#E9E6DA',
      )!;
      final theme = PokeMapPlayerTheme.withBattleProfile(
        PokeMapPlayerTheme.withSurfacePalettes(
          PokeMapPlayerTheme.withSemanticTheme(
            PokeMapPlayerTheme.dark(),
            semantic,
          ),
          const ProjectPresentationSurfacePalettesProfile(
            battle: ProjectSurfacePaletteProfile(
              surface: '#E9E6DA',
              border: '#66717A',
              text: '#1B242C',
            ),
          ),
        ),
        const ProjectBattlePresentationProfile(),
      );

      await _pumpOverlay(
        tester,
        snapshot: _rootSnapshot(),
        onCommand: (_) {},
        theme: theme,
      );

      final species = tester.widget<Text>(
        find.byKey(const ValueKey<String>('battle-species-enemy')),
      );
      final enemyMaterial = tester.widget<Material>(
        find
            .descendant(
              of: find.byKey(
                const ValueKey<String>('battle-hud-target-enemy'),
              ),
              matching: find.byType(Material),
            )
            .first,
      );
      const chrome = PokeMapPlayerBattleChrome.darkFieldManual;
      expect(species.style?.color, chrome.textPrimary);
      expect(enemyMaterial.color, chrome.surface);
    },
  );

  testWidgets(
    'battle surface keeps one dark field manual hierarchy across commands',
    (tester) async {
      const viewport = Size(508, 379);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(viewport);
      final semantic = PokeMapPlayerSemanticTheme.tryFromHex(
        primary: '#23323B',
        onPrimary: '#FFFFFF',
        background: '#E3DFD7',
        surface: '#E9E6DA',
        surfaceElevated: '#DADEDA',
        textPrimary: '#1B242C',
        textSecondary: '#4F5860',
        outline: '#657078',
        success: '#16794B',
        warning: '#8A5100',
        danger: '#B4233C',
        titleSurface: '#E3DFD7',
        dialogueSurface: '#FFFFFF',
        menuSurface: '#E9E6DA',
        overworldHudSurface: '#FFFFFF',
        battleHudSurface: '#F8F8F8',
      )!;
      final theme = PokeMapPlayerTheme.withSurfacePalettes(
        PokeMapPlayerTheme.withSemanticTheme(
          PokeMapPlayerTheme.light(),
          semantic,
        ),
        const ProjectPresentationSurfacePalettesProfile(
          battle: ProjectSurfacePaletteProfile(
            surface: '#F8F8F8',
            border: '#484848',
            text: '#303030',
            accent: '#B83B54',
            selection: '#305FD9',
          ),
        ),
      );
      await _pumpOverlay(
        tester,
        snapshot: _rootSnapshot(viewportSize: viewport),
        onCommand: (_) {},
        theme: theme,
      );

      Material entryMaterial(int index) {
        final semantics = tester.widget<Semantics>(
          find.byKey(ValueKey<String>('battle-entry-$index')),
        );
        final tooltip = semantics.child! as Tooltip;
        return tooltip.child! as Material;
      }

      expect(entryMaterial(0).color, const Color(0xFF173229));
      expect(entryMaterial(1).color, const Color(0xFF1E2A25));
      expect(entryMaterial(2).color, const Color(0xFF1E2A25));
      expect(entryMaterial(3).color, const Color(0xFF1E2A25));
    },
  );

  testWidgets(
    'French labels remain stable on the coherent dark battle chrome',
    (tester) async {
      const semantic = PokeMapPlayerSemanticTheme(
        primary: Color(0xFFB83B54),
        onPrimary: Color(0xFFFFFFFF),
        background: Color(0xFFE0E0DF),
        surface: Color(0xFFF8F8F8),
        surfaceElevated: Color(0xFFF8F8F8),
        textPrimary: Color(0xFF303030),
        textSecondary: Color(0xFF5A5A5A),
        outline: Color(0xFF484848),
        success: Color(0xFF16794B),
        warning: Color(0xFF8A5100),
        danger: Color(0xFFB4233C),
        titleSurface: Color(0xFFE0E0DF),
        dialogueSurface: Color(0xFFF8F8F8),
        menuSurface: Color(0xFFF8F8F8),
        overworldHudSurface: Color(0xFFF8F8F8),
        battleHudSurface: Color(0xFFF8F8F8),
      );
      final theme = PokeMapPlayerTheme.withSurfacePalettes(
        PokeMapPlayerTheme.withSemanticTheme(
          PokeMapPlayerTheme.light(),
          semantic,
        ),
        const ProjectPresentationSurfacePalettesProfile(
          battle: ProjectSurfacePaletteProfile(
            surface: '#F8F8F8',
            border: '#484848',
            text: '#303030',
          ),
        ),
      );
      await _pumpOverlay(
        tester,
        snapshot: _snapshot(
          title: 'MOVES',
          entries: const <BattleCommandOverlayEntry>[
            BattleCommandOverlayEntry(
              index: 0,
              kind: BattleCommandOverlayEntryKind.move,
              primaryLabel: 'Rugissement',
              secondaryLabel: '',
              enabled: true,
              selected: false,
              tone: BattleCommandOverlayEntryTone.support,
            ),
            BattleCommandOverlayEntry(
              index: 1,
              kind: BattleCommandOverlayEntryKind.move,
              primaryLabel: "Écras'Face",
              secondaryLabel: '',
              enabled: true,
              selected: false,
              tone: BattleCommandOverlayEntryTone.attack,
            ),
            BattleCommandOverlayEntry(
              index: 2,
              kind: BattleCommandOverlayEntryKind.move,
              primaryLabel: 'Écume',
              secondaryLabel: '',
              enabled: true,
              selected: false,
              tone: BattleCommandOverlayEntryTone.special,
            ),
          ],
        ),
        onCommand: (_) {},
        theme: theme,
      );

      Material entryMaterial(int index) {
        final semantics = tester.widget<Semantics>(
          find.byKey(ValueKey<String>('battle-entry-$index')),
        );
        return (semantics.child! as Tooltip).child! as Material;
      }

      expect(find.text('CAPACITÉS'), findsNothing);
      expect(find.text('MOVES'), findsNothing);
      expect(entryMaterial(0).color, const Color(0xFF1E2A25));
      expect(entryMaterial(1).color, const Color(0xFF1E2A25));
      expect(entryMaterial(2).color, const Color(0xFF1E2A25));
    },
  );

  testWidgets(
    'V10 reorders and relabels root commands without changing runtime indices',
    (tester) async {
      BattlePresentationCommand? command;
      const profile = ProjectBattlePresentationProfile(
        commands: <ProjectBattleCommandProfile>[
          ProjectBattleCommandProfile(
            id: ProjectBattleCommandId.run,
            label: 'Retraite',
          ),
          ProjectBattleCommandProfile(
            id: ProjectBattleCommandId.fight,
            label: 'Techniques',
          ),
          ProjectBattleCommandProfile(
            id: ProjectBattleCommandId.party,
            label: 'Alliés',
          ),
          ProjectBattleCommandProfile(
            id: ProjectBattleCommandId.bag,
            label: 'Inventaire',
          ),
        ],
      );
      await _pumpOverlay(
        tester,
        snapshot: _rootSnapshot(),
        onCommand: (value) => command = value,
        theme: PokeMapPlayerTheme.withBattleProfile(
          PokeMapPlayerTheme.dark(),
          profile,
        ),
      );

      expect(find.text('Retraite'), findsOneWidget);
      expect(find.text('Techniques'), findsOneWidget);
      expect(find.text('Alliés'), findsOneWidget);
      expect(find.text('Inventaire'), findsOneWidget);

      await tester.tap(find.text('Retraite'));

      expect(
        command,
        isA<BattleSelectEntryCommand>()
            .having((value) => value.entryIndex, 'runtime index', 3)
            .having(
              (value) => value.expectedMode,
              'mode',
              BattleCommandOverlayMode.root,
            ),
      );
    },
  );

  testWidgets('V10 renders radial commands and falls back in compact portrait',
      (
    tester,
  ) async {
    const profile = ProjectBattlePresentationProfile(
      commandLayout: ProjectBattleCommandLayout.radial,
    );
    final theme = PokeMapPlayerTheme.withBattleProfile(
      PokeMapPlayerTheme.dark(),
      profile,
    );
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpOverlay(
      tester,
      snapshot: _rootSnapshot(),
      onCommand: (_) {},
      theme: theme,
    );

    expect(
      find.byKey(const ValueKey<String>('battle-panel-commands-radial')),
      findsOneWidget,
    );
    final top = tester.getCenter(
      find.byKey(const ValueKey<String>('battle-entry-0')),
    );
    final right = tester.getCenter(
      find.byKey(const ValueKey<String>('battle-entry-1')),
    );
    final bottom = tester.getCenter(
      find.byKey(const ValueKey<String>('battle-entry-2')),
    );
    expect(top.dy, lessThan(right.dy));
    expect(bottom.dy, greaterThan(right.dy));
    expect(right.dx, greaterThan(top.dx));

    await tester.binding.setSurfaceSize(const Size(390, 760));
    await _pumpOverlay(
      tester,
      snapshot: _rootSnapshot(),
      onCommand: (_) {},
      theme: theme,
    );

    expect(
      find.byKey(const ValueKey<String>('battle-panel-commands-grid')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  for (final size in const <Size>[
    Size(960, 540),
    Size(800, 480),
    Size(700, 420),
    Size(600, 380),
    Size(460, 300),
    Size(400, 280),
  ]) {
    testWidgets(
        'BETA-BAT-009 keeps the four commands whole at '
        '${size.width.toInt()}x${size.height.toInt()}', (tester) async {
      const profile = ProjectBattlePresentationProfile(
        commandLayout: ProjectBattleCommandLayout.radial,
      );
      final theme = PokeMapPlayerTheme.withBattleProfile(
        PokeMapPlayerTheme.dark(),
        profile,
      );
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpOverlay(
        tester,
        snapshot: _rootSnapshot(),
        onCommand: (_) {},
        theme: theme,
      );

      // The criterion itself, not the mechanism: every command must be whole
      // inside its panel. A radial arrangement in a dock too narrow to host a
      // card left, right and centred pushed the bottom one past the border.
      final panelFinder = find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>)
                .value
                .startsWith('battle-panel-commands-'),
      );
      expect(panelFinder, findsOneWidget);
      final panel = tester.getRect(panelFinder);
      for (var index = 0; index < 4; index += 1) {
        final entry = find.byKey(ValueKey<String>('battle-entry-$index'));
        expect(entry, findsOneWidget, reason: 'entry $index must be mounted');
        final rect = tester.getRect(entry);
        expect(
          rect.left >= panel.left - 0.5 &&
              rect.right <= panel.right + 0.5 &&
              rect.top >= panel.top - 0.5 &&
              rect.bottom <= panel.bottom + 0.5,
          isTrue,
          reason: 'command $index leaves its panel at $size: '
              '$rect against $panel',
        );
      }
      // Where radial cannot fit, the panel must SAY it fell back: keying it
      // by the authored layout let a grid masquerade as a radial dock.
      final panelKey =
          (tester.widget(panelFinder).key! as ValueKey<String>).value;
      if (size.width < 420) {
        expect(
          panelKey,
          'battle-panel-commands-grid',
          reason: 'a narrow dock renders the grid, and names it',
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('V10 styles HUD, HP and each battle panel independently', (
    tester,
  ) async {
    const profile = ProjectBattlePresentationProfile(
      commandLayout: ProjectBattleCommandLayout.list,
      commandColumns: 1,
      commandShape: ProjectWindowShape.cutCorner,
      commandPadding: 20,
      commandSurfaceColor: '#102030',
      commandBorderColor: '#FFAA00',
      commandTextColor: '#FFFFFF',
      commandSelectionColor: '#00CCAA',
      hudShape: ProjectWindowShape.rectangle,
      enemyHudPosition: ProjectBattleHudPosition.topEnd,
      playerHudPosition: ProjectBattleHudPosition.bottomStart,
      showOwnerLabel: false,
      showLevel: false,
      showExactHp: false,
      hpBarShape: ProjectBattleHpBarShape.segmented,
      hpHealthyColor: '#00AA55',
      hpWarningColor: '#FFAA00',
      hpDangerColor: '#CC2244',
      statusColor: '#8844FF',
      moves: ProjectBattlePanelPresentationProfile(
        layout: ProjectBattleCommandLayout.grid,
        columns: 2,
        shape: ProjectWindowShape.rounded,
        padding: 16,
        surfaceColor: '#334455',
      ),
    );
    await _pumpOverlay(
      tester,
      snapshot: _snapshot(),
      onCommand: (_) {},
      theme: PokeMapPlayerTheme.withBattleProfile(
        PokeMapPlayerTheme.dark(),
        profile,
      ),
    );

    expect(
        find.byKey(const ValueKey<String>('battle-owner-enemy')), findsNothing);
    expect(
        find.byKey(const ValueKey<String>('battle-level-enemy')), findsNothing);
    expect(find.byKey(const ValueKey<String>('battle-exact-hp-enemy')),
        findsNothing);
    expect(find.byKey(const ValueKey<String>('battle-hp-segmented-enemy')),
        findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('battle-hud-position-enemy-topEnd')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('battle-hud-position-player-bottomStart'),
      ),
      findsOneWidget,
    );

    final panel = find.byKey(const ValueKey<String>('battle-command-panel'));
    final material = tester.widget<Material>(
      find.descendant(of: panel, matching: find.byType(Material)).first,
    );
    expect(material.color, const Color(0xFF334455));
    expect(material.shape, isA<RoundedRectangleBorder>());
  });

  testWidgets('V10 colors the runtime-owned HP thresholds at zero and max', (
    tester,
  ) async {
    const profile = ProjectBattlePresentationProfile(
      hpBarShape: ProjectBattleHpBarShape.flat,
      hpHealthyColor: '#00AA55',
      hpWarningColor: '#FFAA00',
      hpDangerColor: '#CC2244',
      statusColor: '#8844FF',
    );
    final theme = PokeMapPlayerTheme.withBattleProfile(
      PokeMapPlayerTheme.dark(),
      profile,
    );

    for (final state in <({int hp, Color color})>[
      (hp: 0, color: const Color(0xFFCC2244)),
      (hp: 40, color: const Color(0xFFFFAA00)),
      (hp: 100, color: const Color(0xFF00AA55)),
    ]) {
      await _pumpOverlay(
        tester,
        snapshot: _snapshot(
          enemyHp: state.hp,
          enemyMaxHp: 100,
          enemyStatus: 'PARALYSIE PROLONGÉE',
        ),
        onCommand: (_) {},
        theme: theme,
      );

      final progress = tester.widget<LinearProgressIndicator>(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('battle-hp-flat-enemy'),
          ),
          matching: find.byType(LinearProgressIndicator),
        ),
      );
      expect(progress.color, state.color);
      expect(find.text('PARALYSIE PROLONGÉE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('renders canonical battle data and emits a versioned command',
      (tester) async {
    BattlePresentationCommand? command;
    await _pumpOverlay(
      tester,
      snapshot: _snapshot(),
      onCommand: (value) => command = value,
    );

    expect(find.text('Tonnerre'), findsOneWidget);
    expect(find.byType(PlayerBattleScene), findsOneWidget);
    expect(find.text('ÉLECTRIK · SPÉCIAL'), findsOneWidget);
    expect(find.text('PP 12/15'), findsOneWidget);
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey<String>('battle-entry-1')),
          )
          .hint,
      'ÉLECTRIK, ÉLECTRIK · Spécial · Puissance 90, PP 12/15, Super efficace',
    );
    expect(find.text('PAR'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('battle-entry-1')));
    expect(
      command,
      isA<BattleSelectEntryCommand>()
          .having((value) => value.snapshotRevision, 'revision', 9)
          .having(
            (value) => value.expectedMode,
            'mode',
            BattleCommandOverlayMode.fight,
          )
          .having((value) => value.entryIndex, 'index', 1),
    );
  });

  testWidgets('disables unavailable entries and exposes the reason',
      (tester) async {
    var commandCount = 0;
    await _pumpOverlay(
      tester,
      snapshot: _snapshot(),
      onCommand: (_) => commandCount += 1,
    );

    await tester.tap(find.byKey(const ValueKey<String>('battle-entry-0')));
    expect(commandCount, 0);
    final semantics = tester.getSemantics(
      find.byKey(const ValueKey<String>('battle-entry-0')),
    );
    expect(semantics.label, contains('Vive-Attaque'));
    expect(semantics.hint, contains('PP 0/30'));
  });

  group('BETA-BAT-009 every root command states why it is unavailable', () {
    const reasons = <int, ({String label, String reason})>{
      0: (label: 'ATTAQUER', reason: 'Plus aucune capacité utilisable'),
      1: (label: 'SAC', reason: 'Le Sac est verrouillé en combat de dresseur'),
      2: (label: 'ÉQUIPE', reason: 'Aucun autre Pokémon en état de combattre'),
      3: (label: 'FUITE', reason: 'Impossible de fuir un combat de dresseur'),
    };

    List<BattleCommandOverlayEntry> disabledRoots({bool withReason = true}) =>
        <BattleCommandOverlayEntry>[
          for (final entry in reasons.entries)
            BattleCommandOverlayEntry(
              index: entry.key,
              kind: BattleCommandOverlayEntryKind.root,
              primaryLabel: entry.value.label,
              secondaryLabel: 'Indisponible',
              statusLabel: withReason ? entry.value.reason : null,
              enabled: false,
              selected: entry.key == 0,
              tone: BattleCommandOverlayEntryTone.neutral,
            ),
        ];

    testWidgets('each of the four exposes its own reason and refuses the tap',
        (tester) async {
      var commandCount = 0;
      await _pumpOverlay(
        tester,
        snapshot: _rootSnapshot(entries: disabledRoots()),
        onCommand: (_) => commandCount += 1,
      );

      for (final entry in reasons.entries) {
        final finder = find.byKey(
          ValueKey<String>('battle-entry-${entry.key}'),
        );
        expect(finder, findsOneWidget, reason: entry.value.label);
        final semantics = tester.getSemantics(finder);
        expect(semantics.label, contains(entry.value.label));
        expect(
          semantics.flagsCollection.isEnabled,
          Tristate.isFalse,
          reason: 'a screen reader must be told ${entry.value.label} is '
              'explicitly disabled, not merely left without an enabled state',
        );
        expect(
          semantics.hint,
          contains(entry.value.reason),
          reason: '${entry.value.label} must say why it cannot be used, not '
              'just look greyed out',
        );
        await tester.tap(finder, warnIfMissed: false);
        await tester.pump();
      }

      expect(
        commandCount,
        0,
        reason: 'a disabled root command never reaches the runtime',
      );
    });

    testWidgets('a root command without an authored reason still says so',
        (tester) async {
      await _pumpOverlay(
        tester,
        snapshot: _rootSnapshot(entries: disabledRoots(withReason: false)),
        onCommand: (_) {},
      );

      for (final entry in reasons.entries) {
        final semantics = tester.getSemantics(
          find.byKey(ValueKey<String>('battle-entry-${entry.key}')),
        );
        expect(
          semantics.hint.trim(),
          isNotEmpty,
          reason: '${entry.value.label} falls back to the generic '
              'unavailable wording rather than an empty hint',
        );
      }
    });
  });

  testWidgets('forced replacement has no dismiss action and survives scaling',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpOverlay(
      tester,
      snapshot: _snapshot(
        viewportSize: const Size(320, 568),
        phase: BattlePresentationPhase.forcedReplacement,
        mode: BattleCommandOverlayMode.pokemon,
        canGoBack: false,
      ),
      textScaler: const TextScaler.linear(1.8),
      onCommand: (_) {},
    );

    expect(find.text('Remplacement obligatoire'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('battle-back')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('battle style and combat typography stay scoped to combat', (
    tester,
  ) async {
    const typography = PokeMapPlayerTypography(
      bodyFamily: 'Studio Body',
      dialogueFamily: 'Studio Dialogue',
      combatFamily: 'Studio Combat',
    );
    const windows = ProjectPresentationWindowsProfile(
      styles: <ProjectWindowStyleProfile>[
        ProjectWindowStyleProfile(
          id: 'default',
          fillToken: 'surface',
          borderToken: 'outline',
          borderWidth: 1,
          cornerRadius: 16,
          contentPadding: 24,
          shadowElevation: 8,
        ),
        ProjectWindowStyleProfile(
          id: 'battle',
          fillToken: 'battleHudSurface',
          borderToken: 'primary',
          borderWidth: 3,
          cornerRadius: 5,
          contentPadding: 8,
          shadowElevation: 2,
        ),
      ],
      defaultStyleId: 'default',
      pauseMenuStyleId: 'default',
      dialogueStyleId: 'default',
      battleStyleId: 'battle',
      pauseBackdropOpacity: .7,
    );
    final theme = PokeMapPlayerTheme.withWindowProfile(
      PokeMapPlayerTheme.withTypography(
        PokeMapPlayerTheme.dark(),
        typography,
      ),
      windows,
    );

    await _pumpOverlay(
      tester,
      snapshot: _snapshot(),
      onCommand: (_) {},
      theme: theme,
    );

    final panel = find.byKey(
      const ValueKey<String>('battle-command-panel'),
    );
    final material = tester.widget<Material>(
      find.descendant(of: panel, matching: find.byType(Material)).first,
    );
    final shape = material.shape! as BeveledRectangleBorder;
    expect(material.color, const Color(0xFF111916));
    expect(shape.borderRadius, BorderRadius.circular(12));
    expect(shape.side.width, 2);
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey<String>('battle-dialogue-prompt')),
          )
          .style
          ?.fontFamily,
      'Studio Combat',
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
        localizationsDelegates:
            PokeMapPlayerLocalizations.localizationsDelegates,
        theme: theme,
        home: PlayerDialogueSurface(
          data: PersonalizationStudioV2Fixture.dialogue,
          onAction: (_) {},
        ),
      ),
    );
    expect(
      tester
          .widget<Text>(
            find.text(
              'Le monde est peuplé de créatures extraordinaires.',
            ),
          )
          .style
          ?.fontFamily,
      'Studio Dialogue',
    );
  });
}

Future<void> _pumpOverlay(
  WidgetTester tester, {
  required BattleCommandOverlaySnapshot snapshot,
  required ValueChanged<BattlePresentationCommand> onCommand,
  Widget Function(String assetPath)? itemIconBuilder,
  TextScaler textScaler = TextScaler.noScaling,
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: theme ?? PokeMapPlayerTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: Scaffold(
          body: PlayerBattleOverlay(
            snapshot: snapshot,
            onCommand: onCommand,
            itemIconBuilder: itemIconBuilder,
          ),
        ),
      ),
    ),
  );
  expect(find.byType(PlayerBattleSurface), findsOneWidget);
}

const _richMoveEntries = <BattleCommandOverlayEntry>[
  BattleCommandOverlayEntry(
    index: 0,
    kind: BattleCommandOverlayEntryKind.move,
    primaryLabel: 'Écras’Face',
    secondaryLabel: 'normal',
    tertiaryLabel: 'NORMAL · Physical · Power 40',
    trailingLabel: 'PP 35/35',
    enabled: true,
    selected: false,
    tone: BattleCommandOverlayEntryTone.attack,
  ),
  BattleCommandOverlayEntry(
    index: 1,
    kind: BattleCommandOverlayEntryKind.move,
    primaryLabel: 'Pistolet à O',
    secondaryLabel: 'water',
    tertiaryLabel: 'WATER · Special · Power 40',
    trailingLabel: 'PP 17/25',
    enabled: true,
    selected: true,
    tone: BattleCommandOverlayEntryTone.attack,
  ),
  BattleCommandOverlayEntry(
    index: 2,
    kind: BattleCommandOverlayEntryKind.move,
    primaryLabel: 'Éclair',
    secondaryLabel: 'electric',
    tertiaryLabel: 'ELECTRIC · Special · Power 40',
    trailingLabel: 'PP 24/30',
    enabled: true,
    selected: false,
    tone: BattleCommandOverlayEntryTone.attack,
  ),
  BattleCommandOverlayEntry(
    index: 3,
    kind: BattleCommandOverlayEntryKind.move,
    primaryLabel: 'Flammèche',
    secondaryLabel: 'fire',
    tertiaryLabel: 'FIRE · Special · Power 40',
    trailingLabel: 'PP 22/25',
    enabled: true,
    selected: false,
    tone: BattleCommandOverlayEntryTone.attack,
  ),
];

const _richBagEntries = <BattleCommandOverlayEntry>[
  BattleCommandOverlayEntry(
    index: 0,
    kind: BattleCommandOverlayEntryKind.bag,
    primaryLabel: 'Potion',
    secondaryLabel: 'Medicine',
    trailingLabel: 'x4',
    statusLabel: 'OK',
    enabled: true,
    selected: true,
    tone: BattleCommandOverlayEntryTone.medicine,
    iconAssetPath: '/items/potion.png',
  ),
  BattleCommandOverlayEntry(
    index: 1,
    kind: BattleCommandOverlayEntryKind.bag,
    primaryLabel: 'Poké Ball',
    secondaryLabel: 'Capture',
    trailingLabel: 'x7',
    statusLabel: 'OK',
    enabled: true,
    selected: false,
    tone: BattleCommandOverlayEntryTone.capture,
    iconAssetPath: '/items/poke-ball.png',
  ),
  BattleCommandOverlayEntry(
    index: 2,
    kind: BattleCommandOverlayEntryKind.bag,
    primaryLabel: 'Super Potion',
    secondaryLabel: 'Medicine',
    trailingLabel: 'x2',
    statusLabel: 'OK',
    enabled: true,
    selected: false,
    tone: BattleCommandOverlayEntryTone.medicine,
    iconAssetPath: '/items/super-potion.png',
  ),
  BattleCommandOverlayEntry(
    index: 3,
    kind: BattleCommandOverlayEntryKind.bag,
    primaryLabel: 'Hyper Ball',
    secondaryLabel: 'Capture',
    trailingLabel: 'x3',
    statusLabel: 'OK',
    enabled: true,
    selected: false,
    tone: BattleCommandOverlayEntryTone.capture,
    iconAssetPath: '/items/ultra-ball.png',
  ),
  BattleCommandOverlayEntry(
    index: 4,
    kind: BattleCommandOverlayEntryKind.bag,
    primaryLabel: 'Rappel',
    secondaryLabel: 'Medicine',
    trailingLabel: 'x1',
    statusLabel: 'Trainer only',
    enabled: false,
    selected: false,
    tone: BattleCommandOverlayEntryTone.disabled,
    iconAssetPath: '/items/revive.png',
  ),
  BattleCommandOverlayEntry(
    index: 5,
    kind: BattleCommandOverlayEntryKind.bag,
    primaryLabel: 'Baie Oran',
    secondaryLabel: 'Passive',
    trailingLabel: 'x5',
    statusLabel: 'Unsupported',
    enabled: false,
    selected: false,
    tone: BattleCommandOverlayEntryTone.disabled,
    iconAssetPath: '/items/oran-berry.png',
  ),
];

BattleCommandOverlaySnapshot _snapshot({
  Size viewportSize = const Size(800, 600),
  BattlePresentationPhase phase = BattlePresentationPhase.choosingCommand,
  BattleCommandOverlayMode mode = BattleCommandOverlayMode.fight,
  bool canGoBack = true,
  int enemyHp = 23,
  int enemyMaxHp = 80,
  String? enemyStatus = 'PAR',
  String? title,
  List<BattleCommandOverlayEntry>? entries,
  String? enemyGender,
  String? playerGender,
  double? playerExperienceProgress,
  double? playerExperienceProgressTarget,
  int? playerXpTweenDurationMs,
  int playerXpTweenRevision = 0,
  int? playerHp,
  int? playerDisplayedHp,
  int? playerTargetDisplayedHp,
  int? playerHpTweenDurationMs,
  int playerHpTweenRevision = 0,
}) {
  final layout = BattleSceneLayout.forViewport(viewportSize: viewportSize);
  return BattleCommandOverlaySnapshot(
    revision: 9,
    phase: phase,
    forcedReplacement: phase == BattlePresentationPhase.forcedReplacement,
    mode: mode,
    viewportSize: viewportSize,
    panelRect: layout.commandPanelRect,
    enemyHud: _hud(
      rect: layout.enemyHudRect,
      owner: 'ENNEMI',
      species: 'Roucarnage',
      hp: enemyHp,
      maxHp: enemyMaxHp,
      status: enemyStatus,
      gender: enemyGender,
    ),
    playerHud: _hud(
      rect: layout.playerHudRect,
      owner: 'JOUEUR',
      species: 'Pikachu',
      hp: playerHp ?? 61,
      maxHp: 72,
      gender: playerGender,
      experienceProgress: playerExperienceProgress,
      experienceProgressTarget: playerExperienceProgressTarget,
      xpTweenDurationMs: playerXpTweenDurationMs,
      xpTweenRevision: playerXpTweenRevision,
      displayedHp: playerDisplayedHp,
      targetDisplayedHp: playerTargetDisplayedHp,
      hpTweenDurationMs: playerHpTweenDurationMs,
      hpTweenRevision: playerHpTweenRevision,
    ),
    battleLabel: 'COMBAT DE DRESSEUR',
    title: title ??
        (mode == BattleCommandOverlayMode.pokemon ? 'ÉQUIPE' : 'CAPACITÉS'),
    prompt: phase == BattlePresentationPhase.forcedReplacement
        ? 'Choisissez un remplaçant.'
        : 'Choisissez une capacité.',
    narrationLines: const <String>[],
    entries: entries ??
        const <BattleCommandOverlayEntry>[
          BattleCommandOverlayEntry(
            index: 0,
            kind: BattleCommandOverlayEntryKind.move,
            primaryLabel: 'Vive-Attaque',
            secondaryLabel: 'normal',
            tertiaryLabel: 'NORMAL · Physique · Puissance 40',
            trailingLabel: 'PP 0/30',
            enabled: false,
            selected: false,
            tone: BattleCommandOverlayEntryTone.disabled,
          ),
          BattleCommandOverlayEntry(
            index: 1,
            kind: BattleCommandOverlayEntryKind.move,
            primaryLabel: 'Tonnerre',
            secondaryLabel: 'electric',
            tertiaryLabel: 'ÉLECTRIK · Spécial · Puissance 90',
            trailingLabel: 'PP 12/15',
            statusLabel: 'Super efficace',
            enabled: true,
            selected: true,
            tone: BattleCommandOverlayEntryTone.special,
          ),
        ],
    interactionsEnabled: true,
    canGoBack: canGoBack,
  );
}

BattleCommandOverlaySnapshot _rootSnapshot({
  Size viewportSize = const Size(800, 600),
  Rect? panelRect,
  Rect? enemyHudRect,
  Rect? playerHudRect,
  List<String> narrationLines = const <String>[],
  List<BattleCommandOverlayEntry>? entries,
}) {
  final layout = BattleSceneLayout.forViewport(viewportSize: viewportSize);
  return BattleCommandOverlaySnapshot(
    revision: 12,
    mode: BattleCommandOverlayMode.root,
    viewportSize: viewportSize,
    panelRect: panelRect ?? layout.commandPanelRect,
    enemyHud: _hud(
      rect: enemyHudRect ?? layout.enemyHudRect,
      owner: 'ENNEMI',
      species: 'Roucool',
      hp: 20,
      maxHp: 20,
    ),
    playerHud: _hud(
      rect: playerHudRect ?? layout.playerHudRect,
      owner: 'JOUEUR',
      species: 'Brindibou',
      hp: 24,
      maxHp: 30,
    ),
    battleLabel: 'COMBAT SAUVAGE',
    title: 'COMMANDES',
    prompt: 'Choisissez une action.',
    narrationLines: narrationLines,
    entries: entries ??
        const <BattleCommandOverlayEntry>[
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
}

BattleCommandOverlayHudSnapshot _hud({
  Rect rect = const Rect.fromLTWH(12, 12, 160, 64),
  required String owner,
  required String species,
  required int hp,
  required int maxHp,
  String? status,
  String? gender,
  double? experienceProgress,
  double? experienceProgressTarget,
  int? xpTweenDurationMs,
  int xpTweenRevision = 0,
  int? displayedHp,
  int? targetDisplayedHp,
  int? hpTweenDurationMs,
  int hpTweenRevision = 0,
}) {
  return BattleCommandOverlayHudSnapshot(
    rect: rect,
    ownerLabel: owner,
    speciesLabel: species,
    level: 32,
    currentHp: hp,
    maxHp: maxHp,
    statusLabel: status,
    genderSymbol: gender,
    experienceProgress: experienceProgress,
    experienceProgressTarget: experienceProgressTarget,
    xpTweenDurationMs: xpTweenDurationMs,
    xpTweenRevision: xpTweenRevision,
    isPlayerSide: owner == 'JOUEUR',
    displayedHp: displayedHp,
    targetDisplayedHp: targetDisplayedHp,
    hpTweenDurationMs: hpTweenDurationMs,
    hpTweenRevision: hpTweenRevision,
  );
}

void _expectRectClose(Rect actual, Rect expected) {
  expect(actual.left, closeTo(expected.left, 0.5));
  expect(actual.top, closeTo(expected.top, 0.5));
  expect(actual.width, closeTo(expected.width, 0.5));
  expect(actual.height, closeTo(expected.height, 0.5));
}
