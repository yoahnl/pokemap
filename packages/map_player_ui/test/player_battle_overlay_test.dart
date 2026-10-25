import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'dart:ui' show Tristate;
import 'dart:io';

import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_layout.dart';

import 'fixtures/personalization_studio_v2_fixture.dart';

void main() {
  for (final source in [PlayerInputSource.touch, PlayerInputSource.controller]) {
    testWidgets('portrait layout acknowledges the actual input source $source', (tester) async {
      const viewport = Size(390, 844);
      await tester.binding.setSurfaceSize(viewport);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final touch = source == PlayerInputSource.touch;
      final commands = <BattlePresentationCommand>[];
      await _pumpOverlay(
        tester,
        source: source,
        snapshot: _rootSnapshot(
          viewportSize: viewport,
          controllerLayout: true,
          portraitTouchLayout: !touch,
        ),
        onCommand: commands.add,
      );
      final request = commands.single as BattleSetCommandPanelPlacementCommand;
      expect(request.controllerLayout, isTrue);
      expect(request.portraitTouchLayout, touch);
      commands.clear();
      await _pumpOverlay(
        tester,
        source: source,
        snapshot: _rootSnapshot(
          viewportSize: viewport,
          controllerLayout: true,
          portraitTouchLayout: touch,
        ),
        onCommand: commands.add,
      );
      await tester.pumpAndSettle();
      expect(commands, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'portrait touch acknowledges compact commands without changing authored padding',
    (tester) async {
      const viewport = Size(390, 844);
      await tester.binding.setSurfaceSize(viewport);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final commands = <BattlePresentationCommand>[];
      await _pumpOverlay(
        tester,
        snapshot: _rootSnapshot(
          viewportSize: viewport,
          controllerLayout: false,
        ),
        onCommand: commands.add,
      );
      expect(commands, hasLength(1));
      final request = commands.single as BattleSetCommandPanelPlacementCommand;
      expect(request.controllerLayout, isTrue);
      expect(request.portraitTouchLayout, isTrue);
      expect(request.placement, BattleCommandPanelPlacement.bottom);
      commands.clear();
      await _pumpOverlay(
        tester,
        snapshot: _rootSnapshot(viewportSize: viewport, controllerLayout: true, portraitTouchLayout: true),
        onCommand: commands.add,
      );
      await tester.pumpAndSettle();
      expect(commands, isEmpty);
      for (var index = 0; index < 4; index++) {
        expect(
          tester.getSize(find.byKey(ValueKey('battle-entry-$index'))).height,
          inInclusiveRange(48, 64),
        );
      }
      expect(find.byType(Scrollable), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpOverlay(
        tester,
        snapshot: _rootSnapshot(
          viewportSize: viewport,
          controllerLayout: false,
        ),
        onCommand: commands.add,
        theme: PokeMapPlayerTheme.withBattleProfile(
          PokeMapPlayerTheme.dark(),
          const ProjectBattlePresentationProfile(commandPadding: 24),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        commands.whereType<BattleSetCommandPanelPlacementCommand>().every(
          (command) => !command.controllerLayout && !command.portraitTouchLayout,
        ),
        isTrue,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('battle-entry-0'))).height,
        greaterThanOrEqualTo(48),
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final format in [
    (340.0, EdgeInsets.zero, 1),
    (340.0, const EdgeInsets.symmetric(horizontal: 12), 1),
    (359.0, EdgeInsets.zero, 1),
    (360.0, EdgeInsets.zero, 2),
    (383.0, const EdgeInsets.symmetric(horizontal: 12), 1),
    (384.0, const EdgeInsets.symmetric(horizontal: 12), 2),
    (496.0, EdgeInsets.zero, 2),
  ]) {
    testWidgets('companion collection ACK equals painted columns at $format', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(format.$1, 432));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final commands = <BattlePresentationCommand>[];
      await _pumpOverlay(
        tester,
        display: PlayerBattleDisplay.commandsOnly,
        source: PlayerInputSource.controller,
        safePadding: format.$2,
        snapshot: _snapshot(
          viewportSize: const Size(768, 432),
          placement: BattleCommandPanelPlacement.detached,
          mode: BattleCommandOverlayMode.pokemon,
          acknowledgeCollectionColumns: false,
          entries: [
            for (var index = 0; index < 2; index++)
              BattleCommandOverlayEntry(
                index: index,
                kind: BattleCommandOverlayEntryKind.party,
                primaryLabel: String.fromCharCode(65 + index),
                secondaryLabel: '12/40 PV',
                enabled: true,
                selected: index == 0,
                tone: BattleCommandOverlayEntryTone.neutral,
              ),
          ],
        ),
        onCommand: commands.add,
      );
      final first = tester.getRect(
        find.byKey(const ValueKey('battle-entry-0')),
      );
      final second = tester.getRect(
        find.byKey(const ValueKey('battle-entry-1')),
      );
      final paintedColumns = (second.top - first.top).abs() < .1 ? 2 : 1;
      expect(paintedColumns, format.$3);
      final request = commands.single as BattleSetCommandPanelPlacementCommand;
      expect(request.collectionColumns, paintedColumns);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'collection columns ACK follows the painted width including companion and author fallback',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final format in [
        (
          const Size(844, 390),
          const Size(844, 390),
          PlayerBattleDisplay.full,
          BattleCommandOverlayMode.pokemon,
          2,
        ),
        (
          const Size(390, 844),
          const Size(390, 844),
          PlayerBattleDisplay.full,
          BattleCommandOverlayMode.pokemon,
          1,
        ),
        (
          const Size(390, 844),
          const Size(390, 844),
          PlayerBattleDisplay.full,
          BattleCommandOverlayMode.bag,
          2,
        ),
        (
          const Size(320, 568),
          const Size(320, 568),
          PlayerBattleDisplay.full,
          BattleCommandOverlayMode.bag,
          1,
        ),
        (
          const Size(335, 568),
          const Size(335, 568),
          PlayerBattleDisplay.full,
          BattleCommandOverlayMode.bag,
          1,
        ),
        (
          const Size(336, 568),
          const Size(336, 568),
          PlayerBattleDisplay.full,
          BattleCommandOverlayMode.bag,
          2,
        ),
        (
          const Size(496, 432),
          const Size(768, 432),
          PlayerBattleDisplay.commandsOnly,
          BattleCommandOverlayMode.pokemon,
          2,
        ),
        (
          const Size(538, 266),
          const Size(768, 432),
          PlayerBattleDisplay.commandsOnly,
          BattleCommandOverlayMode.bagMedicineTarget,
          2,
        ),
        (
          const Size(320, 432),
          const Size(768, 432),
          PlayerBattleDisplay.commandsOnly,
          BattleCommandOverlayMode.bag,
          1,
        ),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.binding.setSurfaceSize(format.$1);
        final commands = <BattlePresentationCommand>[];
        final placement = format.$3 == PlayerBattleDisplay.commandsOnly
            ? BattleCommandPanelPlacement.detached
            : format.$1.width > format.$1.height
            ? BattleCommandPanelPlacement.end
            : BattleCommandPanelPlacement.bottom;
        Future<void> pump({
          bool acknowledged = false,
          ThemeData? theme,
          PlayerBattleDisplay? display,
        }) => _pumpOverlay(
          tester,
          display: display ?? format.$3,
          theme: theme,
          source: PlayerInputSource.controller,
          snapshot: _snapshot(
            viewportSize: format.$2,
            placement: placement,
            controllerLayout: format.$3 == PlayerBattleDisplay.full,
            portraitTouchLayout: false,
            mode: format.$4,
            acknowledgeCollectionColumns: acknowledged,
            collectionColumns: acknowledged ? format.$5 : null,
            entries: [
              for (var index = 0; index < 6; index++)
                BattleCommandOverlayEntry(
                  index: index,
                  kind: format.$4 == BattleCommandOverlayMode.bag
                      ? BattleCommandOverlayEntryKind.bag
                      : BattleCommandOverlayEntryKind.party,
                  primaryLabel: String.fromCharCode(65 + index),
                  secondaryLabel: '12/40 PV',
                  trailingLabel: 'Nv.16',
                  enabled: true,
                  selected: index == 0,
                  tone: BattleCommandOverlayEntryTone.neutral,
                ),
            ],
          ),
          onCommand: commands.add,
        );
        await pump();
        final request =
            commands.single as BattleSetCommandPanelPlacementCommand;
        expect(request.collectionColumns, format.$5, reason: '$format');
        final first = tester.getRect(
          find.byKey(const ValueKey('battle-entry-0')),
        );
        final second = tester.getRect(
          find.byKey(const ValueKey('battle-entry-1')),
        );
        expect(second.top == first.top, format.$5 == 2, reason: '$format');
        await pump();
        expect(commands, hasLength(1));
        await pump(acknowledged: true);
        expect(commands, hasLength(1));
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.binding.setSurfaceSize(const Size(844, 390));
      final authorCommands = <BattlePresentationCommand>[];
      await _pumpOverlay(
        tester,
        source: PlayerInputSource.controller,
        theme: PokeMapPlayerTheme.withBattleProfile(
          PokeMapPlayerTheme.dark(),
          const ProjectBattlePresentationProfile(
            target: ProjectBattlePanelPresentationProfile(
              layout: ProjectBattleCommandLayout.list,
              columns: 1,
            ),
          ),
        ),
        snapshot: _snapshot(
          viewportSize: const Size(844, 390),
          placement: BattleCommandPanelPlacement.end,
          mode: BattleCommandOverlayMode.pokemon,
          acknowledgeCollectionColumns: false,
          entries: [
            for (var index = 0; index < 2; index++)
              BattleCommandOverlayEntry(
                index: index,
                kind: BattleCommandOverlayEntryKind.party,
                primaryLabel: 'Membre $index',
                secondaryLabel: '12/40 PV',
                enabled: true,
                selected: index == 0,
                tone: BattleCommandOverlayEntryTone.neutral,
              ),
          ],
        ),
        onCommand: authorCommands.add,
      );
      expect(authorCommands, isEmpty);
      final first = tester.getRect(
        find.byKey(const ValueKey('battle-entry-0')),
      );
      final second = tester.getRect(
        find.byKey(const ValueKey('battle-entry-1')),
      );
      expect(second.top, greaterThanOrEqualTo(first.bottom));
      expect(second.left, closeTo(first.left, .1));
    },
  );

  testWidgets(
    'occupied root narration uses its natural two-line budget during post-battle XP',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.runAsync(() async {
        final bytes = ByteData.sublistView(
          await File('assets/fonts/DMSans-Variable.ttf').readAsBytes(),
        );
        await (FontLoader(
          'packages/map_player_ui/PokeMapSplashDMSans',
        )..addFont(Future.value(bytes))).load();
      });
      const narration =
          'Brindibou gagne des points d’expérience.\nSon apprentissage se poursuit.';
      final snapshot = _rootSnapshot(
        phase: BattlePresentationPhase.presentingTurn,
        interactionsEnabled: false,
        narrationLines: const [narration],
      );
      expect(snapshot.panelRect, const Rect.fromLTRB(24, 480, 776, 588));
      await _pumpOverlay(tester, snapshot: snapshot, onCommand: (_) {});
      final text = find.byKey(const ValueKey('battle-dialogue-prompt'));
      final paragraph = tester.renderObject<RenderParagraph>(text);
      final panel = tester.getRect(
        find.byKey(const ValueKey('battle-dialogue-panel')),
      );
      expect(find.text(narration), findsOneWidget);
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(paragraph.size.height, greaterThan(36));
      expect(panel.height, greaterThanOrEqualTo(paragraph.size.height + 16));
      expect(panel.height, lessThanOrEqualTo(snapshot.panelRect.height));
      expect(find.byKey(const ValueKey('battle-entry-0')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compact collection text two pagination keeps every canonical index reachable',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final mode in [
        BattleCommandOverlayMode.pokemon,
        BattleCommandOverlayMode.bagMedicineTarget,
        BattleCommandOverlayMode.bag,
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        final commands = <BattlePresentationCommand>[];
        await _pumpOverlay(
          tester,
          source: PlayerInputSource.controller,
          textScaler: const TextScaler.linear(2),
          snapshot: _snapshot(
            viewportSize: const Size(320, 568),
            mode: mode,
            controllerLayout: true,
            portraitTouchLayout: false,
            entries: [
              for (var index = 0; index < 6; index++)
                BattleCommandOverlayEntry(
                  index: index,
                  kind: mode == BattleCommandOverlayMode.bag
                      ? BattleCommandOverlayEntryKind.bag
                      : BattleCommandOverlayEntryKind.party,
                  primaryLabel: String.fromCharCode(65 + index),
                  secondaryLabel: mode == BattleCommandOverlayMode.bag
                      ? 'Soin'
                      : '12/40 PV',
                  trailingLabel: mode == BattleCommandOverlayMode.bag
                      ? '×2'
                      : 'Nv. 16',
                  enabled: true,
                  selected: index == 5,
                  tone: BattleCommandOverlayEntryTone.neutral,
                ),
            ],
          ),
          onCommand: commands.add,
        );
        expect(
          find.byKey(const ValueKey('battle-page-previous')),
          findsOneWidget,
        );
        while (tester
                .widget<IconButton>(
                  find.byKey(const ValueKey('battle-page-previous')),
                )
                .onPressed !=
            null) {
          await tester.tap(find.byKey(const ValueKey('battle-page-previous')));
          await tester.pumpAndSettle();
        }
        final seen = <int>{};
        for (var page = 0; page < 6; page++) {
          for (var index = 0; index < 6; index++) {
            final entry = find.byKey(ValueKey('battle-entry-$index'));
            if (entry.evaluate().isNotEmpty) {
              expect(entry.hitTestable(), findsOneWidget);
              expect(tester.getSize(entry).height, greaterThanOrEqualTo(48));
              seen.add(index);
            }
          }
          final next = find.byKey(const ValueKey('battle-page-next'));
          if (tester.widget<IconButton>(next).onPressed == null) break;
          await tester.tap(next);
          await tester.pumpAndSettle();
        }
        expect(seen, {0, 1, 2, 3, 4, 5});
        expect(
          find.byKey(const ValueKey('battle-back')).hitTestable(),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('battle-entry-5')));
        expect(
          commands.whereType<BattleSelectEntryCommand>().single.entryIndex,
          5,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'root commands share Nintendo visual order in all five layouts and retain authored order',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final entries = [
        for (var index = 0; index < 4; index++)
          BattleCommandOverlayEntry(
            index: index,
            kind: BattleCommandOverlayEntryKind.root,
            primaryLabel: ['ATTAQUER', 'SAC', 'ÉQUIPE', 'FUITE'][index],
            secondaryLabel: '',
            enabled: true,
            selected: index == 1,
            tone: BattleCommandOverlayEntryTone.neutral,
          ),
      ];
      for (final authored in [false, true]) {
        await tester.pumpWidget(const SizedBox.shrink());
        final order = authored ? [3, 0, 1, 2] : [0, 2, 1, 3];
        final theme = authored
            ? PokeMapPlayerTheme.withBattleProfile(
                PokeMapPlayerTheme.dark(),
                const ProjectBattlePresentationProfile(
                  commands: [
                    ProjectBattleCommandProfile(id: ProjectBattleCommandId.run),
                    ProjectBattleCommandProfile(
                      id: ProjectBattleCommandId.fight,
                    ),
                    ProjectBattleCommandProfile(id: ProjectBattleCommandId.bag),
                    ProjectBattleCommandProfile(
                      id: ProjectBattleCommandId.party,
                    ),
                  ],
                ),
              )
            : PokeMapPlayerTheme.dark();
        for (final format in [
          (
            const Size(844, 390),
            PlayerInputSource.touch,
            PlayerBattleDisplay.full,
            BattleCommandPanelPlacement.bottom,
            false,
          ),
          (
            const Size(844, 390),
            PlayerInputSource.controller,
            PlayerBattleDisplay.full,
            BattleCommandPanelPlacement.end,
            true,
          ),
          (
            const Size(390, 844),
            PlayerInputSource.touch,
            PlayerBattleDisplay.full,
            BattleCommandPanelPlacement.bottom,
            false,
          ),
          (
            const Size(390, 844),
            PlayerInputSource.controller,
            PlayerBattleDisplay.full,
            BattleCommandPanelPlacement.bottom,
            true,
          ),
          (
            const Size(496, 432),
            PlayerInputSource.controller,
            PlayerBattleDisplay.commandsOnly,
            BattleCommandPanelPlacement.detached,
            false,
          ),
        ]) {
          await tester.binding.setSurfaceSize(format.$1);
          final commands = <BattlePresentationCommand>[];
          await _pumpOverlay(
            tester,
            theme: theme,
            source: format.$2,
            display: format.$3,
            snapshot: _rootSnapshot(
              viewportSize: format.$1,
              placement: format.$4,
              controllerLayout: format.$5 || format.$1.height > format.$1.width,
              portraitTouchLayout: format.$2 == PlayerInputSource.touch &&
                  format.$1.height > format.$1.width &&
                  format.$3 == PlayerBattleDisplay.full,
              rootCommandOrder: order,
              entries: entries,
            ),
            onCommand: commands.add,
          );
          final appliedProfile = Theme.of(
            tester.element(find.byType(PlayerBattleSurface)),
          ).extension<PokeMapPlayerBattleTheme>()?.profile;
          expect(
            appliedProfile?.commands?.map((entry) => entry.id).toList(),
            authored
                ? [
                    ProjectBattleCommandId.run,
                    ProjectBattleCommandId.fight,
                    ProjectBattleCommandId.bag,
                    ProjectBattleCommandId.party,
                  ]
                : isNull,
          );
          final rects = {
            for (var index = 0; index < 4; index++)
              index: tester.getRect(
                find.byKey(ValueKey('battle-entry-$index')),
              ),
          };
          final visual = rects.keys.toList()
            ..sort((a, b) {
              final vertical = rects[a]!.top.compareTo(rects[b]!.top);
              return vertical == 0
                  ? rects[a]!.left.compareTo(rects[b]!.left)
                  : vertical;
            });
          expect(visual, order, reason: '$format authored=$authored');
          expect(commands, isEmpty);
          await tester.tap(find.byKey(const ValueKey('battle-entry-1')));
          expect((commands.single as BattleSelectEntryCommand).entryIndex, 1);
          expect(tester.takeException(), isNull);
        }
      }
    },
  );

  testWidgets(
    'root order request deduplicates values and accepts the runtime ACK for full and companion owners',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(844, 390));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final display in [
        PlayerBattleDisplay.full,
        PlayerBattleDisplay.commandsOnly,
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        final commands = <BattlePresentationCommand>[];
        final placement = display == PlayerBattleDisplay.commandsOnly
            ? BattleCommandPanelPlacement.detached
            : BattleCommandPanelPlacement.bottom;
        Future<void> pump(List<int> order) => _pumpOverlay(
          tester,
          display: display,
          snapshot: _rootSnapshot(
            viewportSize: const Size(844, 390),
            placement: placement,
            rootCommandOrder: order,
          ),
          onCommand: commands.add,
        );
        await pump([0, 1, 2, 3]);
        final request =
            commands.single as BattleSetCommandPanelPlacementCommand;
        expect(request.rootCommandOrder, [0, 2, 1, 3]);
        expect(request.snapshotRevision, 12);
        await pump([0, 1, 2, 3]);
        expect(commands, hasLength(1));
        await pump(List<int>.of(request.rootCommandOrder));
        expect(commands, hasLength(1));
        await pump([0, 2, 1, 3]);
        expect(commands, hasLength(1));
      }
    },
  );

  testWidgets(
    'canonical structure with authored moves keeps its padding grid colors and complete labels',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(844, 390));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.runAsync(() async {
        final bytes = ByteData.sublistView(
          await File('assets/fonts/DMSans-Variable.ttf').readAsBytes(),
        );
        await (FontLoader(
          'packages/map_player_ui/PokeMapSplashDMSans',
        )..addFont(Future.value(bytes))).load();
      });
      final commands = <BattlePresentationCommand>[];
      final labels = ['Fouet Lianes', 'Charge', 'Vampigraine', 'Poudre Dodo'];
      await _pumpOverlay(
        tester,
        source: PlayerInputSource.controller,
        theme: PokeMapPlayerTheme.withBattleProfile(
          PokeMapPlayerTheme.dark(),
          const ProjectBattlePresentationProfile(
            moves: ProjectBattlePanelPresentationProfile(
              padding: 20,
              surfaceColor: '#F4EEDC',
              textColor: '#102B33',
              borderColor: '#102B33',
              selectionColor: '#E2B54A',
            ),
          ),
        ),
        snapshot: _snapshot(
          viewportSize: const Size(844, 390),
          placement: BattleCommandPanelPlacement.end,
          controllerLayout: false,
          entries: [
            for (var index = 0; index < 4; index++)
              BattleCommandOverlayEntry(
                index: index,
                kind: BattleCommandOverlayEntryKind.move,
                primaryLabel: labels[index],
                secondaryLabel: 'grass',
                trailingLabel: 'PP 22/25',
                enabled: true,
                selected: index == 0,
                tone: BattleCommandOverlayEntryTone.attack,
              ),
          ],
        ),
        onCommand: commands.add,
      );
      final panel = tester.widget<PlayerPanel>(
        find.byKey(const ValueKey('battle-command-panel')),
      );
      expect(panel.windowStyleOverride!.contentPadding, 20);
      expect(panel.surfaceColorOverride, const Color(0xFFF4EEDC));
      expect(commands, isEmpty);
      final first = tester.getRect(
        find.byKey(const ValueKey('battle-entry-0')),
      );
      final second = tester.getRect(
        find.byKey(const ValueKey('battle-entry-1')),
      );
      final third = tester.getRect(
        find.byKey(const ValueKey('battle-entry-2')),
      );
      final panelRect = tester.getRect(
        find.byKey(const ValueKey('battle-command-panel')),
      );
      expect(first.left - panelRect.left, closeTo(20, .01));
      expect(first.top - panelRect.top, closeTo(20, .01));
      expect(panelRect.right - second.right, closeTo(20, .01));
      expect(first.top, second.top);
      expect(third.top, greaterThan(first.bottom));
      expect(find.byKey(const ValueKey('battle-page-next')), findsNothing);
      for (var index = 0; index < 4; index++) {
        final entry = find.byKey(ValueKey('battle-entry-$index'));
        expect(tester.getSize(entry).height, greaterThanOrEqualTo(48));
        for (final label in [labels[index], 'PLANTE', 'PP 22/25']) {
          final finder = find.descendant(of: entry, matching: find.text(label));
          expect(finder, findsOneWidget);
          final paragraph = tester.renderObject<RenderParagraph>(finder);
          expect(paragraph.didExceedMaxLines, isFalse, reason: label);
          final labelRect = tester.getRect(finder);
          final entryRect = tester.getRect(entry);
          expect(labelRect.left, greaterThanOrEqualTo(entryRect.left));
          expect(labelRect.right, lessThanOrEqualTo(entryRect.right));
          expect(labelRect.top, greaterThanOrEqualTo(entryRect.top));
          expect(labelRect.bottom, lessThanOrEqualTo(entryRect.bottom));
        }
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'controller rotation preserves the published selection and leaves tab controls inert',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = PlayerBattlePresentationController();
      addTearDown(controller.dispose);
      final commands = <BattlePresentationCommand>[];
      final entries = [
        for (var index = 0; index < 4; index++)
          BattleCommandOverlayEntry(
            index: index,
            kind: BattleCommandOverlayEntryKind.root,
            primaryLabel: ['ATTAQUER', 'SAC', 'ÉQUIPE', 'FUITE'][index],
            secondaryLabel: '',
            enabled: true,
            selected: index == 2,
            tone: BattleCommandOverlayEntryTone.neutral,
          ),
      ];
      final semantics = tester.ensureSemantics();
      try {
        for (final viewport in [
          const Size(844, 390),
          const Size(390, 844),
          const Size(1280, 590),
          const Size(844, 390),
        ]) {
          await tester.binding.setSurfaceSize(viewport);
          await _pumpOverlay(
            tester,
            snapshot: _rootSnapshot(
              viewportSize: viewport,
              controllerLayout: true,
              portraitTouchLayout: false,
              placement: BattleCommandPanelPlacement.end,
              entries: entries,
            ),
            source: PlayerInputSource.controller,
            presentationController: controller,
            onCommand: commands.add,
          );
          await tester.pump(const Duration(milliseconds: 140));
          final selected = find.byKey(const ValueKey('battle-entry-2'));
          expect(selected.hitTestable(), findsOneWidget);
          expect(
            tester.getSemantics(selected).flagsCollection.isSelected,
            Tristate.isTrue,
          );
          expect(tester.getSize(selected).height, greaterThanOrEqualTo(48));
          expect(commands, isEmpty);
          for (final control in [
            RuntimeInputControl.previousTab,
            RuntimeInputControl.nextTab,
          ]) {
            expect(
              controller.handle(RuntimeInputEvent.press(control)),
              isFalse,
            );
            expect(
              controller.handle(
                RuntimeInputEvent.press(control, isRepeat: true),
              ),
              isFalse,
            );
            expect(
              controller.handle(RuntimeInputEvent.release(control)),
              isFalse,
            );
          }
          expect(commands, isEmpty);
          await tester.tap(selected);
          expect(
            commands.single,
            isA<BattleSelectEntryCommand>().having(
              (value) => value.entryIndex,
              'selected runtime index',
              2,
            ),
          );
          commands.clear();
          expect(tester.takeException(), isNull);
        }
      } finally {
        semantics.dispose();
      }
    },
  );

  setUpAll(() async {
    await (FontLoader(
      'packages/map_player_ui/PokeMapSplashDMSans',
    )..addFont(rootBundle.load('assets/fonts/DMSans-Variable.ttf'))).load();
    var cache = File(Platform.resolvedExecutable).parent;
    while (!cache.path.endsWith('${Platform.pathSeparator}cache')) {
      if (cache.parent.path == cache.path) {
        throw StateError('Flutter cache absent');
      }
      cache = cache.parent;
    }
    final icons = await File(
      '${cache.path}/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ).readAsBytes();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(Future.value(ByteData.sublistView(icons)))).load();
  });

  testWidgets(
    'logical move info owns its modal input and uses remapped glyphs',
    (tester) async {
      final controller = PlayerBattlePresentationController();
      addTearDown(controller.dispose);
      final commands = <BattlePresentationCommand>[];
      final standard = PlayerControlProfile.standard;
      final gamepad = Map<RuntimeInputControl, String>.of(standard.gamepad);
      gamepad[RuntimeInputControl.sprint] = 'x';
      gamepad[RuntimeInputControl.secondary] = 'y';
      final profile = PlayerControlProfile(
        keyboard: standard.keyboard,
        gamepad: gamepad,
        touch: standard.touch,
      );
      await _pumpOverlay(
        tester,
        snapshot: _snapshot(),
        onCommand: commands.add,
        source: PlayerInputSource.controller,
        presentationController: controller,
        controlProfile: profile,
        controllerFamily: PlayerControllerFamily.xbox,
      );
      expect(find.text('X'), findsOneWidget);
      expect(find.text('Y'), findsOneWidget);
      expect(
        controller.handle(
          const RuntimeInputEvent.press(RuntimeInputControl.sprint),
        ),
        isTrue,
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('battle-move-info-dialog')),
        findsOneWidget,
      );
      expect(
        controller.handle(
          const RuntimeInputEvent.release(RuntimeInputControl.sprint),
        ),
        isTrue,
      );
      expect(
        controller.handle(
          const RuntimeInputEvent.press(RuntimeInputControl.down),
        ),
        isTrue,
      );
      expect(commands.whereType<BattleSelectEntryCommand>(), isEmpty);
      expect(
        controller.handle(
          const RuntimeInputEvent.press(RuntimeInputControl.secondary),
        ),
        isTrue,
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('battle-move-info-dialog')),
        findsNothing,
      );
      for (final control in [
        RuntimeInputControl.down,
        RuntimeInputControl.secondary,
      ]) {
        expect(
          controller.handle(RuntimeInputEvent.press(control, isRepeat: true)),
          isTrue,
        );
        expect(controller.handle(RuntimeInputEvent.release(control)), isTrue);
      }
      expect(
        controller.handle(
          const RuntimeInputEvent.press(RuntimeInputControl.down),
        ),
        isFalse,
      );
      expect(
        controller.handle(
          const RuntimeInputEvent.release(RuntimeInputControl.down),
        ),
        isFalse,
      );
      expect(
        controller.handle(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        isFalse,
      );
      expect(commands.whereType<BattleSelectEntryCommand>(), isEmpty);
    },
  );

  testWidgets('portrait root keeps the complete published attack label', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpOverlay(
      tester,
      snapshot: _snapshot(
        viewportSize: const Size(390, 844),
        mode: BattleCommandOverlayMode.root,
        entries: [
          for (final (index, label) in [
            (0, 'ATTAQUER'),
            (1, 'SAC'),
            (2, 'POKÉMON'),
            (3, 'FUITE'),
          ])
            BattleCommandOverlayEntry(
              index: index,
              kind: BattleCommandOverlayEntryKind.root,
              primaryLabel: label,
              secondaryLabel: '',
              enabled: true,
              selected: index == 0,
              tone: BattleCommandOverlayEntryTone.neutral,
            ),
        ],
      ),
      onCommand: (_) {},
    );
    final label = find.text('ATTAQUER');
    expect(label, findsOneWidget);
    expect(
      tester.renderObject<RenderParagraph>(label).didExceedMaxLines,
      isFalse,
    );
    expect(
      find.ancestor(of: label, matching: find.byType(FittedBox)),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'touch info is locally owned and is dismissed when the battle mode changes',
    (tester) async {
      final controller = PlayerBattlePresentationController();
      addTearDown(controller.dispose);
      final commands = <BattlePresentationCommand>[];
      await _pumpOverlay(
        tester,
        snapshot: _snapshot(),
        onCommand: commands.add,
        presentationController: controller,
      );
      await tester.tap(find.byKey(const ValueKey('battle-move-info')));
      await tester.pumpAndSettle();
      expect(
        controller.handle(
          const RuntimeInputEvent.press(RuntimeInputControl.left),
        ),
        isTrue,
      );
      await _pumpOverlay(
        tester,
        snapshot: _rootSnapshot(),
        onCommand: commands.add,
        presentationController: controller,
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('battle-move-info-dialog')),
        findsNothing,
      );
      expect(find.byType(PlayerBattleOverlay), findsOneWidget);
      expect(
        controller.handle(
          const RuntimeInputEvent.press(RuntimeInputControl.sprint),
        ),
        isFalse,
      );
      await _pumpOverlay(
        tester,
        snapshot: _snapshot(),
        onCommand: commands.add,
        display: PlayerBattleDisplay.hudOnly,
        presentationController: controller,
      );
      expect(
        controller.handle(
          const RuntimeInputEvent.press(RuntimeInputControl.sprint),
        ),
        isFalse,
      );
      expect(
        find.byKey(const ValueKey('battle-move-info-dialog')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'collection placement acknowledgement settles after one end request',
    (tester) async {
      const viewport = Size(844, 390);
      await tester.binding.setSurfaceSize(viewport);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final commands = <BattlePresentationCommand>[];
      final current = _snapshot(
        viewportSize: viewport,
        mode: BattleCommandOverlayMode.bag,
        entries: _richBagEntries,
      );
      final transient = BattleCommandOverlaySnapshot(
        revision: current.revision,
        mode: current.mode,
        viewportSize: viewport,
        panelRect: current.panelRect,
        playerHud: current.playerHud,
        enemyHud: current.enemyHud,
        battleLabel: current.battleLabel,
        title: current.title,
        prompt: current.prompt,
        narrationLines: current.narrationLines,
        entries: current.entries,
        interactionsEnabled: true,
        canGoBack: true,
        commandPanelPlacement: BattleCommandPanelPlacement.bottom,
      );
      await _pumpOverlay(tester, snapshot: transient, onCommand: commands.add);
      expect(
        commands.single,
        isA<BattleSetCommandPanelPlacementCommand>()
            .having(
              (value) => value.placement,
              'collection placement',
              BattleCommandPanelPlacement.end,
            )
            .having(
              (value) => value.expectedMode,
              'published mode',
              BattleCommandOverlayMode.bag,
            ),
      );
      await _pumpOverlay(tester, snapshot: current, onCommand: commands.add);
      await tester.pump();
      expect(commands, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'changing collection mode discards the old card focus while preserving the published selection',
    (tester) async {
      const viewport = Size(390, 844);
      await tester.binding.setSurfaceSize(viewport);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      List<BattleCommandOverlayEntry> entries(BattleCommandOverlayMode mode) =>
          [
            for (var index = 0; index < 2; index++)
              BattleCommandOverlayEntry(
                index: index,
                kind: mode == BattleCommandOverlayMode.pokemon
                    ? BattleCommandOverlayEntryKind.party
                    : BattleCommandOverlayEntryKind.medicineTarget,
                primaryLabel: 'Compagnon $index',
                secondaryLabel: '32/48 PV',
                enabled: true,
                selected:
                    index == (mode == BattleCommandOverlayMode.pokemon ? 1 : 0),
                tone: BattleCommandOverlayEntryTone.switching,
              ),
          ];
      await _pumpOverlay(
        tester,
        snapshot: _snapshot(
          viewportSize: viewport,
          mode: BattleCommandOverlayMode.pokemon,
          entries: entries(BattleCommandOverlayMode.pokemon),
        ),
        onCommand: (_) {},
      );
      final oldInk = tester.widget<InkWell>(
        find.descendant(
          of: find.byKey(const ValueKey('battle-entry-1')),
          matching: find.byType(InkWell),
        ),
      );
      oldInk.focusNode!.requestFocus();
      await tester.pump();
      await _pumpOverlay(
        tester,
        snapshot: _snapshot(
          viewportSize: viewport,
          mode: BattleCommandOverlayMode.bagMedicineTarget,
          entries: entries(BattleCommandOverlayMode.bagMedicineTarget),
        ),
        onCommand: (_) {},
      );
      await tester.pumpAndSettle();
      final first = tester.widget<Material>(
        find.byKey(const ValueKey('battle-collection-surface-0')),
      );
      final second = tester.widget<Material>(
        find.byKey(const ValueKey('battle-collection-surface-1')),
      );
      expect(first.color, isNot(second.color));
      expect(
        second.color,
        PokeMapPlayerBattleChrome.darkFieldManual.moveSurface,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final layout in [
    (
      'landscape-touch',
      const Size(844, 390),
      PlayerInputSource.touch,
      PlayerBattleDisplay.full,
      BattleCommandPanelPlacement.bottom,
    ),
    (
      'landscape-controller',
      const Size(844, 390),
      PlayerInputSource.controller,
      PlayerBattleDisplay.full,
      BattleCommandPanelPlacement.end,
    ),
    (
      'portrait-touch',
      const Size(390, 844),
      PlayerInputSource.touch,
      PlayerBattleDisplay.full,
      BattleCommandPanelPlacement.bottom,
    ),
    (
      'portrait-controller',
      const Size(390, 844),
      PlayerInputSource.controller,
      PlayerBattleDisplay.full,
      BattleCommandPanelPlacement.bottom,
    ),
    (
      'thor-companion',
      const Size(496, 432),
      PlayerInputSource.controller,
      PlayerBattleDisplay.commandsOnly,
      BattleCommandPanelPlacement.detached,
    ),
  ]) {
    for (final dark in [false, true]) {
      testWidgets(
        'interactive continue keeps narration and the published action inside an opaque surface ${layout.$1} dark=$dark',
        (tester) async {
          await tester.binding.setSurfaceSize(layout.$2);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final commands = <BattlePresentationCommand>[];
          await _pumpOverlay(
            tester,
            snapshot: _snapshot(
              viewportSize: layout.$2,
              placement: layout.$5,
              portraitTouchLayout: layout.$3 == PlayerInputSource.touch &&
                  layout.$2.height > layout.$2.width &&
                  layout.$4 == PlayerBattleDisplay.full,
              controllerLayout:
                  layout.$3 == PlayerInputSource.controller ||
                  layout.$2.height > layout.$2.width,
              mode: BattleCommandOverlayMode.continueOnly,
              narrationLines: ['Victoire publiée.'],
              entries: const [
                BattleCommandOverlayEntry(
                  index: 17,
                  kind: BattleCommandOverlayEntryKind.continueAction,
                  primaryLabel: 'Suite',
                  secondaryLabel: '',
                  enabled: true,
                  selected: true,
                  tone: BattleCommandOverlayEntryTone.neutral,
                ),
              ],
              canGoBack: false,
            ),
            theme: dark
                ? PokeMapPlayerTheme.dark()
                : PokeMapPlayerTheme.light(),
            source: layout.$3,
            display: layout.$4,
            onCommand: commands.add,
          );
          final panel = find.byKey(const ValueKey('battle-dialogue-panel'));
          final material = tester.widget<Material>(panel);
          expect(material.color?.a, 1);
          final rect = tester.getRect(panel);
          final text = find.text('Victoire publiée.');
          expect(rect.contains(tester.getCenter(text)), isTrue);
          final button = find.byKey(const ValueKey('battle-entry-17'));
          expect(rect.contains(tester.getCenter(button)), isTrue);
          expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
          await tester.tap(button);
          expect(
            commands.single,
            isA<BattleSelectEntryCommand>()
                .having((value) => value.snapshotRevision, 'revision', 9)
                .having((value) => value.entryIndex, 'published index', 17)
                .having(
                  (value) => value.expectedMode,
                  'mode',
                  BattleCommandOverlayMode.continueOnly,
                ),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final dark in [false, true]) {
    testWidgets(
      'six party members fit the opaque collection panel with real font in landscape ${dark ? 'dark' : 'light'}',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(844, 390));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.runAsync(() async {
          final font = ByteData.sublistView(
            await File('assets/fonts/DMSans-Variable.ttf').readAsBytes(),
          );
          await (FontLoader(
            'packages/map_player_ui/PokeMapSplashDMSans',
          )..addFont(Future.value(font))).load();
        });
        final commands = <BattlePresentationCommand>[];
        await _pumpOverlay(
          tester,
          snapshot: _snapshot(
            viewportSize: const Size(844, 390),
            safePadding: const EdgeInsets.fromLTRB(44, 12, 44, 20),
            mode: BattleCommandOverlayMode.pokemon,
            entries: [
              for (var index = 0; index < 6; index++)
                BattleCommandOverlayEntry(
                  index: index * 9 + 2,
                  kind: BattleCommandOverlayEntryKind.party,
                  primaryLabel: 'Compagnon $index',
                  secondaryLabel: '32/48 PV',
                  trailingLabel: 'Nv. ${16 + index}',
                  statusLabel: index == 0 ? 'Au combat' : 'Prêt',
                  enabled: index != 0,
                  selected: index == 0,
                  tone: index == 0
                      ? BattleCommandOverlayEntryTone.disabled
                      : BattleCommandOverlayEntryTone.switching,
                ),
            ],
          ),
          safePadding: const EdgeInsets.fromLTRB(44, 12, 44, 20),
          theme: dark ? PokeMapPlayerTheme.dark() : PokeMapPlayerTheme.light(),
          onCommand: commands.add,
        );
        expect(find.text('Nv. 16'), findsOneWidget);
        expect(find.textContaining('32/48 PV'), findsNWidgets(6));
        expect(find.byKey(const ValueKey('battle-page-next')), findsNothing);
        final first = tester.getRect(
          find.byKey(const ValueKey('battle-entry-2')),
        );
        final lastRect = tester.getRect(
          find.byKey(const ValueKey('battle-entry-47')),
        );
        final panel = tester.getRect(
          find.byKey(const ValueKey('battle-collection-panel')),
        );
        expect(panel.width, inInclusiveRange(450, 460));
        expect(panel.left, greaterThanOrEqualTo(44));
        expect(panel.right, lessThanOrEqualTo(800));
        for (var index = 0; index < 6; index++) {
          final rect = tester.getRect(
            find.byKey(ValueKey('battle-entry-${index * 9 + 2}')),
          );
          expect(rect.left, greaterThanOrEqualTo(panel.left));
          expect(rect.right, lessThanOrEqualTo(panel.right));
          expect(rect.top, greaterThanOrEqualTo(panel.top));
          expect(rect.bottom, lessThanOrEqualTo(panel.bottom));
        }
        expect(
          tester.getSize(find.byKey(const ValueKey('battle-back'))).height,
          greaterThanOrEqualTo(48),
        );
        expect(first.height, greaterThanOrEqualTo(48));
        expect(lastRect.top, greaterThan(first.top));
        expect(lastRect.left, greaterThan(first.left));
        expect(commands, isEmpty);
        final last = find.byKey(const ValueKey('battle-entry-47'));
        expect(tester.getSize(last).height, greaterThanOrEqualTo(48));
        await tester.tap(last);
        expect(
          commands.single,
          isA<BattleSelectEntryCommand>()
              .having((value) => value.snapshotRevision, 'revision', 9)
              .having((value) => value.entryIndex, 'published index', 47)
              .having(
                (value) => value.expectedMode,
                'mode',
                BattleCommandOverlayMode.pokemon,
              ),
        );
        expect(find.byType(Scrollable), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final mode in const [
    (
      'landscape-touch',
      Size(844, 390),
      PlayerInputSource.touch,
      PlayerBattleDisplay.full,
      BattleCommandPanelPlacement.bottom,
    ),
    (
      'landscape-controller',
      Size(844, 390),
      PlayerInputSource.controller,
      PlayerBattleDisplay.full,
      BattleCommandPanelPlacement.end,
    ),
    (
      'portrait-touch',
      Size(390, 844),
      PlayerInputSource.touch,
      PlayerBattleDisplay.full,
      BattleCommandPanelPlacement.bottom,
    ),
    (
      'portrait-controller',
      Size(390, 844),
      PlayerInputSource.controller,
      PlayerBattleDisplay.full,
      BattleCommandPanelPlacement.bottom,
    ),
    (
      'thor-companion',
      Size(496, 432),
      PlayerInputSource.controller,
      PlayerBattleDisplay.commandsOnly,
      BattleCommandPanelPlacement.detached,
    ),
  ]) {
    for (final collection in const [
      (BattleCommandOverlayMode.bag, BattleCommandOverlayEntryKind.bag),
      (BattleCommandOverlayMode.pokemon, BattleCommandOverlayEntryKind.party),
      (
        BattleCommandOverlayMode.moveTarget,
        BattleCommandOverlayEntryKind.target,
      ),
      (
        BattleCommandOverlayMode.bagMedicineTarget,
        BattleCommandOverlayEntryKind.medicineTarget,
      ),
    ]) {
      testWidgets(
        'Ligue ${collection.$1.name} keeps published details and indices in ${mode.$1}',
        (tester) async {
          await tester.binding.setSurfaceSize(mode.$2);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final semantics = tester.ensureSemantics();
          try {
            final commands = <BattlePresentationCommand>[];
            final bag = collection.$1 == BattleCommandOverlayMode.bag;
            await _pumpOverlay(
              tester,
              snapshot: _snapshot(
                viewportSize: mode.$2,
                placement: mode.$5,
                portraitTouchLayout: mode.$3 == PlayerInputSource.touch &&
                    mode.$2.height > mode.$2.width &&
                    mode.$4 == PlayerBattleDisplay.full,
                controllerLayout:
                    (mode.$3 == PlayerInputSource.controller ||
                        mode.$2.height > mode.$2.width) &&
                    mode.$4 == PlayerBattleDisplay.full,
                mode: collection.$1,
                entries: [
                  BattleCommandOverlayEntry(
                    index: 7,
                    kind: collection.$2,
                    primaryLabel: bag ? 'Potion' : 'Compagnon publié',
                    secondaryLabel: bag ? 'Healing' : '32/48 PV',
                    trailingLabel: bag ? 'x4' : 'Nv. 24',
                    statusLabel: bag ? 'OK' : 'Prêt',
                    iconAssetPath: bag ? '/items/potion.png' : null,
                    enabled: true,
                    selected: true,
                    tone: bag
                        ? BattleCommandOverlayEntryTone.medicine
                        : BattleCommandOverlayEntryTone.switching,
                  ),
                  BattleCommandOverlayEntry(
                    index: 23,
                    kind: collection.$2,
                    primaryLabel: bag ? 'Objet indisponible' : 'Compagnon K.O.',
                    secondaryLabel: bag ? 'Healing' : '0/30 PV',
                    trailingLabel: bag ? 'x0' : 'Nv. 20',
                    statusLabel: 'Indisponible',
                    enabled: false,
                    selected: false,
                    tone: BattleCommandOverlayEntryTone.disabled,
                  ),
                ],
              ),
              display: mode.$4,
              source: mode.$3,
              onCommand: commands.add,
              itemIconBuilder: (path) =>
                  SizedBox(key: ValueKey('provided-art-$path')),
            );
            final entry = find.byKey(const ValueKey('battle-entry-7'));
            final material = tester.widget<Material>(
              find.byKey(const ValueKey('battle-collection-surface-7')),
            );
            expect(material.shape, isNot(isA<RoundedRectangleBorder>()));
            expect(material.elevation, 0);
            expect(tester.getSize(entry).height, greaterThanOrEqualTo(48));
            expect(tester.getSize(entry).height, lessThanOrEqualTo(100));
            if (bag) {
              expect(
                find.byKey(const ValueKey('provided-art-/items/potion.png')),
                findsOneWidget,
              );
              expect(find.text('x4'), findsOneWidget);
              expect(find.text('SOIN'), findsWidgets);
            } else {
              expect(find.text('Nv. 24'), findsOneWidget);
              expect(find.textContaining('32/48 PV'), findsOneWidget);
              expect(find.textContaining('Prêt'), findsOneWidget);
              expect(find.textContaining('Indisponible'), findsOneWidget);
              expect(tester.getSemantics(entry).hint, contains('32/48 PV'));
              expect(
                find.descendant(of: entry, matching: find.byType(Icon)),
                findsNothing,
              );
            }
            await tester.tap(find.byKey(const ValueKey('battle-entry-23')));
            expect(commands, isEmpty);
            await tester.tap(entry);
            expect(
              commands.single,
              isA<BattleSelectEntryCommand>()
                  .having((value) => value.snapshotRevision, 'revision', 9)
                  .having((value) => value.expectedMode, 'mode', collection.$1)
                  .having((value) => value.entryIndex, 'index', 7),
            );
            expect(find.byType(Scrollable), findsNothing);
            expect(tester.takeException(), isNull);
          } finally {
            semantics.dispose();
          }
        },
      );
    }

    for (final evolution in [false, true]) {
      testWidgets(
        'Ligue in-scene ${evolution ? 'evolution' : 'learning'} decision preserves prompt and versioned choices in ${mode.$1}',
        (tester) async {
          await tester.binding.setSurfaceSize(mode.$2);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final commands = <BattlePresentationCommand>[];
          final prompt = evolution
              ? 'Brindibou peut évoluer. Que faire ?'
              : 'Brindibou peut apprendre Vive-Attaque.';
          final snapshot = _decisionSnapshot(
            viewportSize: mode.$2,
            placement: mode.$5,
            portraitTouchLayout: mode.$3 == PlayerInputSource.touch &&
                mode.$2.height > mode.$2.width &&
                mode.$4 == PlayerBattleDisplay.full,
            controllerLayout:
                (mode.$3 == PlayerInputSource.controller ||
                    mode.$2.height > mode.$2.width) &&
                mode.$4 == PlayerBattleDisplay.full,
            prompt: prompt,
            labels: evolution
                ? const ['Évoluer', 'Refuser']
                : const ['Apprendre', 'Ne pas apprendre'],
            indices: const [3, 17],
          );
          await _pumpOverlay(
            tester,
            snapshot: snapshot,
            display: mode.$4,
            source: mode.$3,
            theme: evolution
                ? PokeMapPlayerTheme.dark()
                : PokeMapPlayerTheme.light(),
            textScaler: evolution
                ? const TextScaler.linear(2)
                : TextScaler.noScaling,
            onCommand: commands.add,
          );
          expect(commands, isEmpty);
          expect(
            find.byKey(const ValueKey('battle-decision-panel')),
            findsOneWidget,
          );
          expect(find.text(prompt), findsOneWidget);
          final choice = tester.widget<PlayerMenuSelectableRow>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is PlayerMenuSelectableRow &&
                  widget.label == (evolution ? 'Refuser' : 'Ne pas apprendre'),
            ),
          );
          expect(
            choice.labelStyle?.fontFamily,
            'packages/map_player_ui/PokeMapSplashDMSans',
          );
          expect(
            tester
                .renderObject<RenderParagraph>(
                  find.text(evolution ? 'Refuser' : 'Ne pas apprendre'),
                )
                .didExceedMaxLines,
            isFalse,
          );
          expect(find.byKey(const ValueKey('battle-root-grid')), findsNothing);
          expect(find.byKey(const ValueKey('battle-back')), findsNothing);
          expect(find.byType(Scrollable), findsNothing);
          for (final index in [3, 17]) {
            final rect = tester.getRect(
              find.byKey(ValueKey('battle-entry-$index')),
            );
            expect(rect.height, greaterThanOrEqualTo(48));
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(mode.$2.width));
            expect(rect.bottom, lessThanOrEqualTo(mode.$2.height));
          }
          if (mode.$4 == PlayerBattleDisplay.full) {
            expect(
              tester.getRect(
                find.byKey(const ValueKey('battle-decision-panel')),
              ),
              snapshot.panelRect,
            );
            expect(
              tester.getRect(
                find.byKey(const ValueKey('battle-hud-target-player')),
              ),
              snapshot.playerHud.rect,
            );
          }
          await tester.tap(find.byKey(const ValueKey('battle-entry-17')));
          expect(
            commands.single,
            isA<BattleSelectEntryCommand>()
                .having((value) => value.snapshotRevision, 'revision', 12)
                .having(
                  (value) => value.expectedMode,
                  'mode',
                  BattleCommandOverlayMode.decision,
                )
                .having((value) => value.entryIndex, 'runtime index', 17),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'authored target shape and padding retain their existing branch',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpOverlay(
        tester,
        snapshot: _snapshot(
          mode: BattleCommandOverlayMode.moveTarget,
          entries: const [
            BattleCommandOverlayEntry(
              index: 11,
              kind: BattleCommandOverlayEntryKind.target,
              primaryLabel: 'Cible publiée',
              secondaryLabel: '12/30 PV',
              enabled: true,
              selected: true,
              tone: BattleCommandOverlayEntryTone.neutral,
            ),
          ],
        ),
        onCommand: (_) {},
        theme: PokeMapPlayerTheme.withBattleProfile(
          PokeMapPlayerTheme.dark(),
          const ProjectBattlePresentationProfile(
            target: ProjectBattlePanelPresentationProfile(
              shape: ProjectWindowShape.capsule,
              padding: 16,
            ),
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('battle-collection-surface-11')),
        findsNothing,
      );
      final panel = tester.widget<PlayerPanel>(
        find.byKey(const ValueKey('battle-command-panel')),
      );
      expect(panel.windowStyleOverride?.shape, ProjectWindowShape.capsule);
      expect(panel.windowStyleOverride?.contentPadding, 16);
      expect(find.text('12/30 PV'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'five replacement choices remain directly reachable in the journey panel',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(844, 390));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final commands = <BattlePresentationCommand>[];
      await _pumpOverlay(
        tester,
        snapshot: _decisionSnapshot(
          viewportSize: const Size(844, 390),
          labels: const [
            'Fouet Lianes',
            'Charge',
            'Vampigraine',
            'Poudre Dodo',
            'Ne pas apprendre',
          ],
          indices: const [4, 9, 16, 25, 41],
        ),
        onCommand: commands.add,
      );
      expect(find.byKey(const ValueKey('battle-page-next')), findsNothing);
      for (final index in [4, 9, 16, 25, 41]) {
        final choice = find.byKey(ValueKey('battle-entry-$index'));
        expect(choice.hitTestable(), findsOneWidget);
        expect(tester.getSize(choice).height, greaterThanOrEqualTo(48));
      }
      expect(commands, isEmpty);
      final decline = find.byKey(const ValueKey('battle-entry-41'));
      expect(tester.getSize(decline).height, greaterThanOrEqualTo(48));
      await tester.tap(decline);
      expect(
        commands.single,
        isA<BattleSelectEntryCommand>().having(
          (value) => value.entryIndex,
          'index',
          41,
        ),
      );
      expect(find.byType(Scrollable), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('constrained decision pages every published replacement index', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final commands = <BattlePresentationCommand>[];
    await _pumpOverlay(
      tester,
      snapshot: _decisionSnapshot(
        viewportSize: const Size(844, 390),
        panelRect: const Rect.fromLTWH(400, 240, 400, 110),
        labels: const [
          'Fouet Lianes',
          'Charge',
          'Vampigraine',
          'Poudre Dodo',
          'Ne pas apprendre',
        ],
        indices: const [4, 9, 16, 25, 41],
      ),
      onCommand: commands.add,
    );
    final seen = <int>{};
    for (var page = 0; page < 5; page++) {
      for (final index in [4, 9, 16, 25, 41]) {
        final choice = find.byKey(ValueKey('battle-entry-$index'));
        if (choice.hitTestable().evaluate().isNotEmpty) {
          seen.add(index);
          expect(tester.getSize(choice).height, greaterThanOrEqualTo(48));
        }
      }
      if (seen.length == 5) break;
      await tester.tap(find.byKey(const ValueKey('battle-page-next')));
      await tester.pump();
    }
    expect(seen, {4, 9, 16, 25, 41});
    expect(commands, isEmpty);
    final decline = find.byKey(const ValueKey('battle-entry-41'));
    expect(tester.getSize(decline).height, greaterThanOrEqualTo(48));
    await tester.tap(decline);
    expect(
      commands.single,
      isA<BattleSelectEntryCommand>().having(
        (value) => value.entryIndex,
        'index',
        41,
      ),
    );
    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'input ownership requests canonical battle placement and companion does not configure the arena',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(844, 390));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final commands = <BattlePresentationCommand>[];
      await _pumpOverlay(
        tester,
        snapshot: _rootSnapshot(viewportSize: const Size(844, 390)),
        onCommand: commands.add,
        source: PlayerInputSource.controller,
      );
      expect(
        commands.single,
        isA<BattleSetCommandPanelPlacementCommand>()
            .having(
              (c) => c.placement,
              'controller',
              BattleCommandPanelPlacement.end,
            )
            .having((c) => c.snapshotRevision, 'revision', 12),
      );
      commands.clear();
      await _pumpOverlay(
        tester,
        snapshot: _rootSnapshot(
          viewportSize: const Size(844, 390),
          placement: BattleCommandPanelPlacement.end,
        ),
        onCommand: commands.add,
        source: PlayerInputSource.controller,
      );
      expect(commands, isEmpty);
      await _pumpOverlay(
        tester,
        snapshot: _rootSnapshot(
          viewportSize: const Size(844, 390),
          placement: BattleCommandPanelPlacement.end,
        ),
        onCommand: commands.add,
        source: PlayerInputSource.touch,
      );
      expect(
        commands.single,
        isA<BattleSetCommandPanelPlacementCommand>().having(
          (c) => c.placement,
          'touch',
          BattleCommandPanelPlacement.bottom,
        ),
      );
      commands.clear();
      await _pumpOverlay(
        tester,
        snapshot: _rootSnapshot(viewportSize: const Size(844, 390)),
        onCommand: commands.add,
        source: PlayerInputSource.controller,
        display: PlayerBattleDisplay.commandsOnly,
      );
      expect(commands, isEmpty);
      await _pumpOverlay(
        tester,
        snapshot: _rootSnapshot(viewportSize: const Size(844, 390)),
        onCommand: commands.add,
        source: PlayerInputSource.controller,
        display: PlayerBattleDisplay.hudOnly,
      );
      expect(
        commands.single,
        isA<BattleSetCommandPanelPlacementCommand>().having(
          (c) => c.placement,
          'primary',
          BattleCommandPanelPlacement.detached,
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'authored noncanonical battle compositions retain their own layout',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(844, 390));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final commands = <BattlePresentationCommand>[];
      await _pumpOverlay(
        tester,
        snapshot: _rootSnapshot(viewportSize: const Size(844, 390)),
        onCommand: commands.add,
        source: PlayerInputSource.controller,
        theme: PokeMapPlayerTheme.withBattleProfile(
          PokeMapPlayerTheme.dark(),
          const ProjectBattlePresentationProfile(
            commandLayout: ProjectBattleCommandLayout.radial,
          ),
        ),
      );
      expect(commands, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  for (final viewport in const [
    Size(390, 844),
    Size(640, 360),
    Size(698, 372),
    Size(844, 390),
    Size(1280, 720),
  ]) {
    for (final textScale in const [1.0, 1.6]) {
      testWidgets(
        'doubles Player renders four HUDs and forwards target authority at $viewport with text scale $textScale',
        (tester) async {
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.binding.setSurfaceSize(viewport);
          final layout = BattleSceneLayout.forViewport(viewportSize: viewport);
          BattleCommandOverlayHudSnapshot hud(
            String name,
            bool player,
            int row,
          ) {
            final slot = BattleSlotRef(
              side: player ? BattleSideId.player : BattleSideId.enemy,
              slotIndex: row,
            );
            return BattleCommandOverlayHudSnapshot(
              rect: layout.combatantGeometry(slot, doubles: true).hudRect,
              slot: slot,
              ownerLabel: player ? 'Joueur' : 'Dresseur',
              speciesLabel: name,
              combatantId: name,
              level: 20,
              currentHp: 30,
              maxHp: 40,
              isPlayerSide: player,
              experienceProgress: player ? .25 : null,
            );
          }

          final player = hud('Pico', true, 0);
          final enemy = hud('Roca', false, 0);
          final partner = hud('Mousse', true, 1);
          final enemyPartner = hud('Flamme', false, 1);
          final huds = [player, enemy, partner, enemyPartner];
          for (final pair in [
            [player, partner],
            [enemy, enemyPartner],
          ]) {
            expect(
              layout
                  .combatantGeometry(pair.first.effectiveSlot, doubles: true)
                  .footAnchor
                  .dy,
              lessThanOrEqualTo(
                layout
                    .combatantGeometry(pair.last.effectiveSlot, doubles: true)
                    .footAnchor
                    .dy,
              ),
            );
          }
          for (var index = 0; index < huds.length; index++) {
            final sprite = layout
                .combatantGeometry(huds[index].effectiveSlot, doubles: true)
                .spriteRect;
            expect(sprite.intersect(Offset.zero & viewport), sprite);
            expect(
              huds[index].rect.intersect(Offset.zero & viewport),
              huds[index].rect,
            );
            expect(
              huds[index].rect.bottom,
              lessThanOrEqualTo(layout.commandPanelRect.top),
            );
            for (var other = index + 1; other < huds.length; other++) {
              expect(huds[index].rect.overlaps(huds[other].rect), isFalse);
            }
            for (final combatant in huds) {
              expect(
                huds[index].rect.overlaps(
                  layout
                      .combatantGeometry(combatant.effectiveSlot, doubles: true)
                      .spriteRect,
                ),
                isFalse,
                reason:
                    '${huds[index].combatantId} HUD hides ${combatant.combatantId}',
              );
            }
          }
          final commands = <BattlePresentationCommand>[];
          await _pumpOverlay(
            tester,
            onCommand: commands.add,
            textScaler: TextScaler.linear(textScale),
            snapshot: BattleCommandOverlaySnapshot(
              revision: 32,
              controllerLayout: viewport.height > viewport.width,
              portraitTouchLayout: viewport.height > viewport.width,
              mode: BattleCommandOverlayMode.moveTarget,
              viewportSize: viewport,
              panelRect: layout.commandPanelRect,
              playerHud: player,
              enemyHud: enemy,
              additionalHuds: [partner, enemyPartner],
              battleLabel: 'Combat double',
              title: 'Cible',
              prompt: 'Choisis une cible pour Mousse.',
              narrationLines: const [],
              interactionsEnabled: true,
              canGoBack: true,
              entries: const [
                BattleCommandOverlayEntry(
                  index: 1,
                  kind: BattleCommandOverlayEntryKind.target,
                  primaryLabel: 'Flamme',
                  secondaryLabel: 'Nv. 20',
                  enabled: true,
                  selected: true,
                  tone: BattleCommandOverlayEntryTone.attack,
                ),
              ],
            ),
          );
          if (viewport.width > viewport.height) {
            expect(
              commands.single,
              isA<BattleSetCommandPanelPlacementCommand>()
                  .having(
                    (value) => value.snapshotRevision,
                    'transient revision',
                    32,
                  )
                  .having(
                    (value) => value.expectedMode,
                    'target mode',
                    BattleCommandOverlayMode.moveTarget,
                  )
                  .having(
                    (value) => value.placement,
                    'requested collection placement',
                    viewport.width > viewport.height
                        ? BattleCommandPanelPlacement.end
                        : BattleCommandPanelPlacement.bottom,
                  ),
            );
          } else {
            expect(commands, isEmpty);
          }
          commands.clear();
          expect(find.text('Pico'), findsOneWidget);
          expect(find.text('Mousse'), findsOneWidget);
          expect(find.text('Roca'), findsOneWidget);
          expect(find.text('Flamme'), findsNWidgets(2));
          expect(
            tester
                .getSemantics(
                  find.byKey(
                    const ValueKey<String>('battle-hud-semantics-player'),
                  ),
                )
                .label,
            contains('25 %'),
          );
          expect(
            tester
                .getSemantics(
                  find.byKey(
                    const ValueKey<String>(
                      'battle-hud-semantics-battle-hud-player-1-Mousse',
                    ),
                  ),
                )
                .label,
            contains('25 %'),
          );
          await tester.tap(
            find.byKey(const ValueKey<String>('battle-entry-1')),
          );
          expect(
            commands.single,
            isA<BattleSelectEntryCommand>()
                .having((command) => command.entryIndex, 'target index', 1)
                .having((command) => command.snapshotRevision, 'revision', 32)
                .having(
                  (command) => command.expectedMode,
                  'mode',
                  BattleCommandOverlayMode.moveTarget,
                ),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final viewport in const [Size(390, 844), Size(960, 540)]) {
    testWidgets(
      'PP move targeting keeps slots and disabled full moves at $viewport',
      (tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.binding.setSurfaceSize(viewport);
        final commands = <BattlePresentationCommand>[];
        await _pumpOverlay(
          tester,
          snapshot: _snapshot(
            viewportSize: viewport,
            mode: BattleCommandOverlayMode.bagMedicineMoveTarget,
            entries: const [
              BattleCommandOverlayEntry(
                index: 0,
                kind: BattleCommandOverlayEntryKind.move,
                primaryLabel: 'Charge',
                secondaryLabel: 'normal',
                trailingLabel: 'PP 35/35',
                enabled: false,
                selected: false,
                tone: BattleCommandOverlayEntryTone.disabled,
              ),
              BattleCommandOverlayEntry(
                index: 1,
                kind: BattleCommandOverlayEntryKind.move,
                primaryLabel: 'Charge',
                secondaryLabel: 'normal',
                trailingLabel: 'PP 0/5',
                enabled: true,
                selected: true,
                tone: BattleCommandOverlayEntryTone.medicine,
              ),
            ],
          ),
          onCommand: commands.add,
        );
        expect(find.text('35 / 35'), findsOneWidget);
        expect(find.text('0 / 5'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey<String>('battle-entry-0')));
        expect(commands, isEmpty);
        await tester.tap(find.byKey(const ValueKey<String>('battle-entry-1')));
        expect(
          commands.single,
          isA<BattleSelectEntryCommand>()
              .having((command) => command.entryIndex, 'slot', 1)
              .having(
                (command) => command.expectedMode,
                'mode',
                BattleCommandOverlayMode.bagMedicineMoveTarget,
              ),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('companion portrait keeps commands in two tactile rows', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(540, 620));
    final commands = <BattlePresentationCommand>[];
    await _pumpOverlay(
      tester,
      snapshot: _rootSnapshot(viewportSize: const Size(960, 540)),
      onCommand: commands.add,
      display: PlayerBattleDisplay.commandsOnly,
    );
    final fight = tester.getRect(
      find.byKey(const ValueKey<String>('battle-entry-0')),
    );
    final bag = tester.getRect(
      find.byKey(const ValueKey<String>('battle-entry-1')),
    );
    final run = tester.getRect(
      find.byKey(const ValueKey<String>('battle-entry-3')),
    );
    final party = tester.getRect(
      find.byKey(const ValueKey<String>('battle-entry-2')),
    );

    expect(fight.top, closeTo(party.top, .5));
    expect(fight.left, closeTo(bag.left, .5));
    expect(party.left, closeTo(run.left, .5));
    expect(fight.bottom, lessThan(bag.top));
    expect(fight.height, closeTo(bag.height, .5));
    expect(bag.top, closeTo(run.top, .5));
    expect(fight.width, closeTo(party.width, .5));
    expect(
      find.byKey(const ValueKey<String>('battle-dialogue-panel')),
      findsNothing,
    );

    for (final index in [0, 1, 3, 2]) {
      await tester.tap(find.byKey(ValueKey<String>('battle-entry-$index')));
      expect(
        commands.last,
        isA<BattleSelectEntryCommand>()
            .having((command) => command.entryIndex, 'runtime index', index)
            .having((command) => command.snapshotRevision, 'revision', 12)
            .having(
              (command) => command.expectedMode,
              'mode',
              BattleCommandOverlayMode.root,
            ),
      );
    }
    expect(commands, hasLength(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('companion moves retain four slots and an anchored back action', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(620, 540));
    final commands = <BattlePresentationCommand>[];
    await _pumpOverlay(
      tester,
      snapshot: _snapshot(entries: _richMoveEntries.take(3).toList()),
      onCommand: commands.add,
      display: PlayerBattleDisplay.commandsOnly,
    );
    final grid = tester.getRect(
      find.byKey(const ValueKey<String>('battle-panel-moves-grid')),
    );
    final first = tester.getRect(
      find.byKey(const ValueKey<String>('battle-entry-0')),
    );
    final second = tester.getRect(
      find.byKey(const ValueKey<String>('battle-entry-1')),
    );
    final third = tester.getRect(
      find.byKey(const ValueKey<String>('battle-entry-2')),
    );
    final cancel = tester.getRect(
      find.byKey(const ValueKey<String>('battle-back')),
    );

    expect(first.top, closeTo(grid.top, .5));
    expect(second.top, closeTo(first.top, .5));
    expect(first.left, closeTo(third.left, .5));
    expect(third.bottom, closeTo(grid.bottom, .5));
    expect(first.height, closeTo(third.height, .5));
    expect(first.width, closeTo(second.width, .5));
    expect(first.width, closeTo(third.width, .5));
    expect(first.bottom, lessThan(third.top));
    expect(cancel.top, greaterThanOrEqualTo(grid.bottom));
    expect(cancel.right, lessThanOrEqualTo(grid.right));
    expect(find.byTooltip('Retour'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('battle-entry-3')), findsNothing);
    await tester.tapAt(Offset(second.center.dx, third.center.dy));
    expect(commands, isEmpty);

    for (var index = 0; index < 3; index++) {
      await tester.tap(find.byKey(ValueKey<String>('battle-entry-$index')));
      expect(
        commands.last,
        isA<BattleSelectEntryCommand>().having(
          (command) => command.entryIndex,
          'runtime index',
          index,
        ),
      );
    }
    await tester.tap(find.byKey(const ValueKey<String>('battle-back')));
    expect(
      commands.last,
      isA<BattleBackCommand>()
          .having((command) => command.snapshotRevision, 'revision', 9)
          .having(
            (command) => command.expectedMode,
            'mode',
            BattleCommandOverlayMode.fight,
          ),
    );
    expect(commands, hasLength(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'detached primary HUD keeps battle narration without command controls',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const viewport = Size(800, 600);
      await tester.binding.setSurfaceSize(viewport);
      final commands = <BattlePresentationCommand>[];
      final layout = BattleSceneLayout.forViewport(
        viewportSize: viewport,
        commandPanelPlacement: BattleCommandPanelPlacement.detached,
        commandPanelMode: BattleCommandOverlayMode.continueOnly,
      );
      await _pumpOverlay(
        tester,
        snapshot: _snapshot(
          viewportSize: viewport,
          placement: BattleCommandPanelPlacement.detached,
          phase: BattlePresentationPhase.presentingTurn,
          mode: BattleCommandOverlayMode.continueOnly,
          narrationLines: const ['Pikachu utilise Tonnerre !'],
          entries: const [],
        ),
        onCommand: commands.add,
        display: PlayerBattleDisplay.hudOnly,
      );

      expect(find.text('Pikachu utilise Tonnerre !'), findsOneWidget);
      final dialogue = tester.getRect(
        find.byKey(const ValueKey<String>('battle-dialogue-panel')),
      );
      expect(layout.commandPanelRect, Rect.zero);
      expect(dialogue.height, greaterThanOrEqualTo(64));
      expect(dialogue.width, greaterThan(0));
      expect((Offset.zero & viewport).contains(dialogue.topLeft), isTrue);
      expect((Offset.zero & viewport).contains(dialogue.bottomRight), isTrue);
      expect(dialogue.overlaps(layout.enemyHudRect), isFalse);
      expect(dialogue.overlaps(layout.playerHudRect), isFalse);
      expect(dialogue.overlaps(layout.enemySpriteRect), isFalse);
      expect(dialogue.overlaps(layout.playerSpriteRect), isFalse);
      expect(
        find.byKey(const ValueKey<String>('battle-hud-target-enemy')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('battle-hud-target-player')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('battle-command-panel')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey<String>('battle-back')), findsNothing);
      expect(commands, isEmpty);
      await tester.tap(find.text('Pikachu utilise Tonnerre !'));
      expect(commands, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('companion command layouts fit small viewports and large text', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final viewport in const [Size(320, 240), Size(508, 379)]) {
      for (final textScaler in const [
        TextScaler.noScaling,
        TextScaler.linear(2),
      ]) {
        for (final root in [true, false]) {
          await tester.binding.setSurfaceSize(viewport);
          final commands = <BattlePresentationCommand>[];
          await _pumpOverlay(
            tester,
            snapshot: root ? _rootSnapshot() : _snapshot(),
            onCommand: commands.add,
            display: PlayerBattleDisplay.commandsOnly,
            textScaler: textScaler,
          );
          final panel = tester.getRect(
            find.byKey(const ValueKey<String>('battle-command-panel')),
          );
          expect(panel.left, greaterThanOrEqualTo(0));
          expect(panel.top, greaterThanOrEqualTo(0));
          expect(panel.right, lessThanOrEqualTo(viewport.width));
          expect(panel.bottom, lessThanOrEqualTo(viewport.height));
          for (final index in root ? [0, 1, 2, 3] : [0, 1]) {
            final entry = tester.getRect(
              find.byKey(ValueKey<String>('battle-entry-$index')),
            );
            expect(panel.inflate(.5).contains(entry.topLeft), isTrue);
            expect(panel.inflate(.5).contains(entry.bottomRight), isTrue);
          }
          if (root) {
            await tester.tap(
              find.byKey(const ValueKey<String>('battle-entry-3')),
            );
            expect(
              commands.single,
              isA<BattleSelectEntryCommand>().having(
                (command) => command.entryIndex,
                'runtime index',
                3,
              ),
            );
          } else {
            await tester.tap(
              find.byKey(const ValueKey<String>('battle-entry-0')),
            );
            expect(commands, isEmpty);
            await tester.tap(find.byKey(const ValueKey<String>('battle-back')));
            expect(commands.single, isA<BattleBackCommand>());
          }
          expect(
            tester.takeException(),
            isNull,
            reason: '$viewport with $textScaler in ${root ? 'root' : 'moves'}',
          );
        }
      }
    }
  });

  testWidgets(
    'companion commands use their own viewport without duplicating HUD',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(620, 540));
      BattlePresentationCommand? command;
      await _pumpOverlay(
        tester,
        snapshot: _rootSnapshot(viewportSize: const Size(960, 540)),
        onCommand: (value) => command = value,
        display: PlayerBattleDisplay.commandsOnly,
      );
      expect(
        find.byKey(const ValueKey<String>('battle-command-panel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('battle-hud-target-enemy')),
        findsNothing,
      );
      await tester.tap(find.text('ATTAQUER').first);
      expect(command, isA<BattleSelectEntryCommand>());
      expect(command!.snapshotRevision, 12);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'primary companion mode preserves HUD and removes command panel',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await _pumpOverlay(
        tester,
        snapshot: _rootSnapshot(
          placement: BattleCommandPanelPlacement.detached,
        ),
        onCommand: (_) {},
        display: PlayerBattleDisplay.hudOnly,
      );
      expect(
        find.byKey(const ValueKey<String>('battle-command-panel')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('battle-hud-target-enemy')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('battle-hud-target-player')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('battle-dialogue-panel')),
        findsNothing,
      );
      expect(find.text('Choisissez une action.'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
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
          final actionsRect = tester.getRect(
            find.byKey(const ValueKey<String>('battle-actions-panel')),
          );
          _expectRectClose(panelRect, layout.commandPanelRect);
          expect(panelRect.inflate(.5).contains(actionsRect.topLeft), isTrue);
          expect(
            panelRect.inflate(.5).contains(actionsRect.bottomRight),
            isTrue,
          );
          final dialogueFinder = find.byKey(
            const ValueKey<String>('battle-dialogue-panel'),
          );
          if (dialogueFinder.evaluate().isNotEmpty) {
            final dialogueRect = tester.getRect(dialogueFinder);
            expect(dialogueRect.bottom, lessThan(actionsRect.top));
            expect(
              panelRect.inflate(.5).contains(dialogueRect.topLeft),
              isTrue,
            );
          }
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
                  find.byKey(const ValueKey<String>('battle-species-enemy')),
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
              reason:
                  'root command $index must remain inside the actions '
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
            reason:
                'FUITE must remain activatable at $viewport '
                'with $textScaler',
          );
          expect(
            tester.takeException(),
            isNull,
            reason:
                'no layout exception is allowed at $viewport '
                'with $textScaler',
          );
        }
      }
    },
  );

  testWidgets(
    'compact fight submenu reserves a separate back and information rail',
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

      expect(find.byKey(const ValueKey('battle-dialogue-panel')), findsNothing);
      expect(find.byKey(const ValueKey('battle-move-info')), findsOneWidget);
      final back = tester.getRect(find.byKey(const ValueKey('battle-back')));
      final entry = tester.getRect(
        find.byKey(const ValueKey('battle-entry-1')),
      );
      expect(back.left - entry.right, greaterThanOrEqualTo(12));

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
        return tester.widget<Material>(
          find
              .descendant(
                of: find.byKey(ValueKey<String>('battle-entry-$index')),
                matching: find.byType(Material),
              )
              .first,
        );
      }

      final dockPanel = tester.widget<PlayerPanel>(
        find.byKey(const ValueKey<String>('battle-command-panel')),
      );
      expect(find.text('NORMAL'), findsOneWidget);
      expect(find.text('EAU'), findsOneWidget);
      expect(find.text('ÉLECTRIK'), findsOneWidget);
      expect(find.text('FEU'), findsOneWidget);
      expect(find.text('35 / 35'), findsOneWidget);
      expect(find.text('17 / 25'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('battle-gender-enemy')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('battle-gender-player')),
        findsOneWidget,
      );
      expect(entryMaterial(0).shape, isNot(isA<RoundedRectangleBorder>()));
      expect(entryMaterial(0).color, isNot(entryMaterial(1).color));
      expect(entryMaterial(1).elevation, 0);
      expect(
        dockPanel.surfaceColorOverride,
        PokeMapPlayerBattleChrome.darkFieldManual.dockSurface,
      );
      expect(
        dockPanel.textColorOverride,
        PokeMapPlayerBattleChrome.darkFieldManual.dockText,
      );
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
        isNot(contains('9 / 72')),
        reason:
            'au début du drain, le nombre ne montre pas l’état final '
            '(il affichait $early)',
      );

      await tester.pump(const Duration(milliseconds: 700));
      expect(
        readPlayerHp(),
        contains('9 / 72'),
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
        reason:
            'BETA-BAT-017 : au début du gain, la barre n’affiche pas '
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
      final playerHudMaterial = tester.widget<Material>(
        find
            .descendant(
              of: find.byKey(
                const ValueKey<String>('battle-hud-target-player'),
              ),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(playerHudMaterial.shape, isNot(isA<RoundedRectangleBorder>()));
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
        findsOneWidget,
      );
      expect(
        tester
            .getSemantics(
              find.byKey(const ValueKey<String>('battle-hud-semantics-player')),
            )
            .label,
        contains('64 %'),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'battle uses a transparent dock, beveled move cards and contextual move data',
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
      expect(
        dock.surfaceColorOverride,
        PokeMapPlayerBattleChrome.darkFieldManual.dockSurface,
      );
      expect(
        dock.textColorOverride,
        PokeMapPlayerBattleChrome.darkFieldManual.dockText,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('battle-command-panel')),
          matching: find.byType(PlayerPanel),
        ),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('battle-selection-cursor-1')),
        findsNothing,
      );
      expect(find.text('EAU'), findsOneWidget);
      expect(find.text('XP'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'portrait move information is available without selecting an attack',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final commands = <BattlePresentationCommand>[];
      await _pumpOverlay(
        tester,
        snapshot: _snapshot(
          viewportSize: const Size(390, 844),
          entries: _richMoveEntries,
        ),
        onCommand: commands.add,
      );
      final info = find.byKey(const ValueKey('battle-move-info'));
      expect(tester.getSize(info).shortestSide, greaterThanOrEqualTo(48));
      await tester.tap(info);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      final dialog = tester.widget<Dialog>(find.byType(Dialog));
      expect(
        (dialog.shape! as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(PokeMapPlayerMenuTheme.panelRadius),
      );
      expect(dialog.clipBehavior, Clip.antiAlias);
      expect(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(PlayerMenuPanel),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.textContaining('WATER · Special · Power 40'),
        ),
        findsOneWidget,
      );
      expect(commands, isEmpty);
      await tester.tap(find.byKey(const ValueKey('battle-move-info-close')));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
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

  testWidgets('battle bag renders rich item cards with project thumbnails', (
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
      itemIconBuilder: (path) => ColoredBox(
        key: ValueKey<String>('project-item-thumbnail-$path'),
        color: Colors.transparent,
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('battle-paged-target-bag')),
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
        const ValueKey<String>('project-item-thumbnail-/items/poke-ball.png'),
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
    expect(firstItemMaterial.shape, isNot(isA<RoundedRectangleBorder>()));
    expect(tester.takeException(), isNull);
  });

  testWidgets('battle bag routes resolved thumbnails through the image scope', (
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

    expect(find.byType(PlayerFileImage), findsNWidgets(2));
    expect(
      tester
          .widgetList<PlayerFileImage>(find.byType(PlayerFileImage))
          .map((image) => image.path),
      ['/items/potion.png', '/items/poke-ball.png'],
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
          find.byKey(const ValueKey<String>('battle-paged-target-bag')),
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

    expect(tester.getSize(find.byType(PlayerBattleSurface)), viewport);
    expect(
      tester.getRect(find.byKey(const ValueKey('battle-command-panel'))),
      const Rect.fromLTWH(24, 259, 460, 108),
    );
    await expectLater(
      find.byType(PlayerBattleSurface),
      matchesGoldenFile('goldens/battle/separated_command_dock_508x379.png'),
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
    'battle HUD retains readable dedicated tokens with a shared light palette',
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
      expect(species.style?.color, chrome.hudText);
      expect(exactHp.style?.color, chrome.hudText);
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
              of: find.byKey(const ValueKey<String>('battle-hud-target-enemy')),
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
      expect(enemyMaterial.color, chrome.hudSurface);
      expect(playerMaterial.color, chrome.hudSurface);
      expect(enemyMaterial.shape, isNot(isA<RoundedRectangleBorder>()));
      expect(playerMaterial.shape, isNot(isA<RoundedRectangleBorder>()));
    },
  );

  testWidgets(
    'battle HUD retains dedicated tokens with the default V10 profile',
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
              of: find.byKey(const ValueKey<String>('battle-hud-target-enemy')),
              matching: find.byType(Material),
            )
            .first,
      );
      const chrome = PokeMapPlayerBattleChrome.darkFieldManual;
      expect(species.style?.color, chrome.hudText);
      expect(enemyMaterial.color, chrome.hudSurface);
    },
  );

  testWidgets('battle root uses Ligue state colors across its four commands', (
    tester,
  ) async {
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
      return tester.widget<Material>(
        find
            .descendant(
              of: find.byKey(ValueKey<String>('battle-entry-$index')),
              matching: find.byType(Material),
            )
            .first,
      );
    }

    expect({
      for (var index = 0; index < 4; index++) entryMaterial(index).color,
    }, hasLength(2));
  });

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
        return tester.widget<Material>(
          find
              .descendant(
                of: find.byKey(ValueKey<String>('battle-entry-$index')),
                matching: find.byType(Material),
              )
              .first,
        );
      }

      expect(find.text('CAPACITÉS'), findsNothing);
      expect(find.text('MOVES'), findsNothing);
      expect(
        entryMaterial(0).color,
        PokeMapPlayerBattleChrome.darkFieldManual.moveSurface,
      );
      expect(
        entryMaterial(1).color,
        PokeMapPlayerBattleChrome.darkFieldManual.moveSurface,
      );
      expect(
        entryMaterial(2).color,
        PokeMapPlayerBattleChrome.darkFieldManual.moveSurface,
      );
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

  testWidgets(
    'recette 2026-08-24 : une décision post-combat échappe au remapping des '
    'commandes personnalisées',
    (tester) async {
      // Le même profil que le test du remapping : s'il s'appliquait à la
      // décision, « Apprendre » s'afficherait « Techniques » et « Ne pas
      // apprendre » deviendrait « Inventaire » — exactement le bug TestFlight
      // où le joueur lisait « Attaquer » / « Sac » à la place de ses choix.
      const profile = ProjectBattlePresentationProfile(
        commands: <ProjectBattleCommandProfile>[
          ProjectBattleCommandProfile(
            id: ProjectBattleCommandId.fight,
            label: 'Techniques',
          ),
          ProjectBattleCommandProfile(
            id: ProjectBattleCommandId.bag,
            label: 'Inventaire',
          ),
        ],
      );
      BattlePresentationCommand? command;
      await _pumpOverlay(
        tester,
        snapshot: _decisionSnapshot(),
        onCommand: (value) => command = value,
        theme: PokeMapPlayerTheme.withBattleProfile(
          PokeMapPlayerTheme.dark(),
          profile,
        ),
      );

      expect(find.text('Apprendre'), findsOneWidget);
      expect(find.text('Ne pas apprendre'), findsOneWidget);
      expect(find.text('Techniques'), findsNothing);
      expect(find.text('Inventaire'), findsNothing);

      await tester.tap(find.text('Ne pas apprendre'));
      expect(
        command,
        isA<BattleSelectEntryCommand>()
            .having((value) => value.entryIndex, 'index du choix', 1)
            .having(
              (value) => value.expectedMode,
              'mode',
              BattleCommandOverlayMode.decision,
            ),
      );
    },
  );

  testWidgets(
    'V10 renders radial commands and falls back in compact portrait',
    (tester) async {
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
      final rendered = tester
          .widget<PlayerBattleSurface>(find.byType(PlayerBattleSurface))
          .data
          .commands;
      Offset commandCenter(ProjectBattleCommandId id) {
        final entry = rendered.singleWhere((entry) => entry.commandId == id);
        return tester.getCenter(
          find.byKey(ValueKey<String>('battle-entry-${entry.index}')),
        );
      }

      final top = commandCenter(ProjectBattleCommandId.fight);
      final right = commandCenter(ProjectBattleCommandId.party);
      final bottom = commandCenter(ProjectBattleCommandId.bag);
      final left = commandCenter(ProjectBattleCommandId.run);
      expect(top.dy, lessThan(right.dy));
      expect(bottom.dy, greaterThan(right.dy));
      expect(right.dx, greaterThan(top.dx));
      expect(left.dx, lessThan(top.dx));
      expect(left.dy, closeTo(right.dy, .01));

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
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in const <Size>[
    Size(960, 540),
    Size(800, 480),
    Size(700, 420),
    Size(600, 380),
    Size(460, 300),
    Size(400, 280),
  ]) {
    testWidgets('BETA-BAT-009 keeps the four commands whole at '
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
            (widget.key! as ValueKey<String>).value.startsWith(
              'battle-panel-commands-',
            ),
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
          reason:
              'command $index leaves its panel at $size: '
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
      find.byKey(const ValueKey<String>('battle-owner-enemy')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('battle-level-enemy')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('battle-exact-hp-enemy')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('battle-hp-segmented-enemy')),
      findsOneWidget,
    );
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

    final authoredHud = tester.widget<Material>(
      find
          .descendant(
            of: find.byKey(const ValueKey<String>('battle-hud-target-enemy')),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(authoredHud.shape, isA<RoundedRectangleBorder>());
    expect(
      (authoredHud.shape! as RoundedRectangleBorder).borderRadius,
      BorderRadius.zero,
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
          of: find.byKey(const ValueKey<String>('battle-hp-flat-enemy')),
          matching: find.byType(LinearProgressIndicator),
        ),
      );
      expect(progress.color, state.color);
      expect(find.text('PARALYSIE PROLONGÉE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('renders canonical battle data and emits a versioned command', (
    tester,
  ) async {
    BattlePresentationCommand? command;
    await _pumpOverlay(
      tester,
      snapshot: _snapshot(),
      onCommand: (value) => command = value,
    );

    expect(find.text('Tonnerre'), findsOneWidget);
    expect(find.byType(PlayerBattleScene), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(const ValueKey('battle-entry-1'))).hint,
      contains('ÉLECTRIK'),
    );
    expect(find.text('12 / 15'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey<String>('battle-entry-1')))
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

  testWidgets('long press activates the battle command', (tester) async {
    BattlePresentationCommand? command;
    await _pumpOverlay(
      tester,
      snapshot: _rootSnapshot(),
      onCommand: (value) => command = value,
    );

    await tester.longPress(
      find.byKey(const ValueKey<String>('battle-entry-0')),
    );

    expect(
      command,
      isA<BattleSelectEntryCommand>()
          .having((value) => value.snapshotRevision, 'revision', 12)
          .having(
            (value) => value.expectedMode,
            'mode',
            BattleCommandOverlayMode.root,
          )
          .having((value) => value.entryIndex, 'index', 0),
    );
  });

  testWidgets('disables unavailable entries and exposes the reason', (
    tester,
  ) async {
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

    testWidgets('each of the four exposes its own reason and refuses the tap', (
      tester,
    ) async {
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
          reason:
              'a screen reader must be told ${entry.value.label} is '
              'explicitly disabled, not merely left without an enabled state',
        );
        expect(
          semantics.hint,
          contains(entry.value.reason),
          reason:
              '${entry.value.label} must say why it cannot be used, not '
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

    testWidgets('a root command without an authored reason still says so', (
      tester,
    ) async {
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
          reason:
              '${entry.value.label} falls back to the generic '
              'unavailable wording rather than an empty hint',
        );
      }
    });
  });

  testWidgets('forced replacement has no dismiss action and survives scaling', (
    tester,
  ) async {
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
      PokeMapPlayerTheme.withTypography(PokeMapPlayerTheme.dark(), typography),
      windows,
    );

    await _pumpOverlay(
      tester,
      snapshot: _snapshot(),
      onCommand: (_) {},
      theme: theme,
    );

    final panel = find.byKey(const ValueKey<String>('battle-command-panel'));
    final material = tester.widget<Material>(
      find.descendant(of: panel, matching: find.byType(Material)).first,
    );
    final shape = material.shape! as RoundedRectangleBorder;
    expect(
      material.color,
      PokeMapPlayerBattleChrome.darkFieldManual.dockSurface,
    );
    expect(shape.borderRadius, BorderRadius.circular(3));
    expect(shape.side.width, 0);
    expect(
      tester.widget<Text>(find.text('Vive-Attaque')).style?.fontFamily,
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
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('dialogue-page-text')))
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
  EdgeInsets safePadding = EdgeInsets.zero,
  TextScaler textScaler = TextScaler.noScaling,
  ThemeData? theme,
  PlayerBattleDisplay display = PlayerBattleDisplay.full,
  PlayerInputSource source = PlayerInputSource.touch,
  PlayerBattlePresentationController? presentationController,
  PlayerControlProfile? controlProfile,
  PlayerControllerFamily controllerFamily = PlayerControllerFamily.unknown,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: theme ?? PokeMapPlayerTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(
          textScaler: textScaler,
          padding: safePadding,
          viewPadding: safePadding,
        ),
        child: Scaffold(
          body: PlayerInputScope(
            activeInputSource: source,
            child: PlayerBattleOverlay(
              display: display,
              snapshot: snapshot,
              onCommand: onCommand,
              itemIconBuilder: itemIconBuilder,
              presentationController: presentationController,
              controlProfile: controlProfile,
              controllerFamily: controllerFamily,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 140));
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
  BattleCommandPanelPlacement placement = BattleCommandPanelPlacement.bottom,
  EdgeInsets safePadding = EdgeInsets.zero,
  bool? controllerLayout,
  bool? portraitTouchLayout,
  bool acknowledgeCollectionColumns = true,
  int? collectionColumns,
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
  List<String> narrationLines = const [],
}) {
  controllerLayout ??=
      viewportSize.width < 480 && viewportSize.height > viewportSize.width;
  portraitTouchLayout ??= controllerLayout &&
      viewportSize.height > viewportSize.width &&
      placement != BattleCommandPanelPlacement.detached;
  final layout = BattleSceneLayout.forViewport(
    viewportSize: viewportSize,
    safePadding: safePadding,
    commandPanelPlacement: placement,
    commandPanelMode: mode,
    controllerLayout: controllerLayout,
    portraitTouchLayout: portraitTouchLayout,
  );
  return BattleCommandOverlaySnapshot(
    revision: 9,
    commandPanelPlacement: layout.commandPanelPlacement,
    controllerLayout: controllerLayout,
    portraitTouchLayout: portraitTouchLayout,
    collectionColumns:
        collectionColumns ??
        (acknowledgeCollectionColumns &&
                [
                  BattleCommandOverlayMode.bag,
                  BattleCommandOverlayMode.pokemon,
                  BattleCommandOverlayMode.bagMedicineTarget,
                ].contains(mode)
            ? playerBattleCollectionColumns(
                portrait: viewportSize.height > viewportSize.width,
                companion: placement == BattleCommandPanelPlacement.detached,
                bag: mode == BattleCommandOverlayMode.bag,
                contentWidth:
                    (placement == BattleCommandPanelPlacement.detached
                        ? viewportSize.width -
                              playerBattleCompanionInsets(safePadding)
                                  .horizontal
                        : layout.commandPanelRect.width) -
                    playerBattleCollectionPadding(
                      portrait: viewportSize.height > viewportSize.width,
                      companion:
                          placement == BattleCommandPanelPlacement.detached,
                    ).horizontal,
              )
            : null),
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
    title:
        title ??
        (mode == BattleCommandOverlayMode.pokemon ? 'ÉQUIPE' : 'CAPACITÉS'),
    prompt: phase == BattlePresentationPhase.forcedReplacement
        ? 'Choisissez un remplaçant.'
        : 'Choisissez une capacité.',
    narrationLines: narrationLines,
    entries:
        entries ??
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

/// Recette du 2026-08-24 : la décision post-combat, publiée sous son mode
/// dédié — jamais `root`, que la personnalisation projet rhabille par index.
BattleCommandOverlaySnapshot _decisionSnapshot({
  Size viewportSize = const Size(800, 600),
  Rect? panelRect,
  BattleCommandPanelPlacement placement = BattleCommandPanelPlacement.bottom,
  bool controllerLayout = false,
  bool? portraitTouchLayout,
  String prompt = 'Brindibou peut apprendre Vive-Attaque.',
  List<String> labels = const ['Apprendre', 'Ne pas apprendre'],
  List<int>? indices,
}) {
  portraitTouchLayout ??= controllerLayout &&
      viewportSize.height > viewportSize.width &&
      placement != BattleCommandPanelPlacement.detached;
  final layout = BattleSceneLayout.forViewport(
    viewportSize: viewportSize,
    commandPanelPlacement: placement,
    commandPanelMode: BattleCommandOverlayMode.decision,
    controllerLayout: controllerLayout,
    portraitTouchLayout: portraitTouchLayout,
  );
  return BattleCommandOverlaySnapshot(
    revision: 12,
    mode: BattleCommandOverlayMode.decision,
    viewportSize: viewportSize,
    panelRect: panelRect ?? layout.commandPanelRect,
    commandPanelPlacement: layout.commandPanelPlacement,
    controllerLayout: controllerLayout,
    portraitTouchLayout: portraitTouchLayout,
    enemyHud: _hud(
      rect: layout.enemyHudRect,
      owner: 'ENNEMI',
      species: 'Roucool',
      hp: 20,
      maxHp: 20,
    ),
    playerHud: _hud(
      rect: layout.playerHudRect,
      owner: 'JOUEUR',
      species: 'Brindibou',
      hp: 24,
      maxHp: 30,
    ),
    battleLabel: 'COMBAT SAUVAGE',
    title: 'CHOIX',
    prompt: prompt,
    narrationLines: const <String>[],
    entries: <BattleCommandOverlayEntry>[
      for (var index = 0; index < labels.length; index++)
        BattleCommandOverlayEntry(
          index: indices?[index] ?? index,
          kind: BattleCommandOverlayEntryKind.decision,
          primaryLabel: labels[index],
          secondaryLabel: '',
          enabled: true,
          selected: index == 0,
          tone: BattleCommandOverlayEntryTone.neutral,
        ),
    ],
    interactionsEnabled: true,
    canGoBack: false,
  );
}

BattleCommandOverlaySnapshot _rootSnapshot({
  BattleCommandPanelPlacement placement = BattleCommandPanelPlacement.bottom,
  Size viewportSize = const Size(800, 600),
  bool? controllerLayout,
  bool? portraitTouchLayout,
  BattlePresentationPhase phase = BattlePresentationPhase.choosingCommand,
  bool interactionsEnabled = true,
  List<int> rootCommandOrder = const [0, 2, 1, 3],
  Rect? panelRect,
  Rect? enemyHudRect,
  Rect? playerHudRect,
  List<String> narrationLines = const <String>[],
  List<BattleCommandOverlayEntry>? entries,
}) {
  controllerLayout ??=
      viewportSize.width < 480 && viewportSize.height > viewportSize.width;
  portraitTouchLayout ??= controllerLayout &&
      viewportSize.height > viewportSize.width &&
      placement != BattleCommandPanelPlacement.detached;
  final layout = BattleSceneLayout.forViewport(
    viewportSize: viewportSize,
    commandPanelPlacement: placement,
    commandPanelMode: BattleCommandOverlayMode.root,
    controllerLayout: controllerLayout,
    portraitTouchLayout: portraitTouchLayout,
  );
  return BattleCommandOverlaySnapshot(
    revision: 12,
    commandPanelPlacement: layout.commandPanelPlacement,
    controllerLayout: controllerLayout,
    portraitTouchLayout: portraitTouchLayout,
    rootCommandOrder: rootCommandOrder,
    phase: phase,
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
    entries:
        entries ??
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
    interactionsEnabled: interactionsEnabled,
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
