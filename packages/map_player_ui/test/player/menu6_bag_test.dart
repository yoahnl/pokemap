import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/player/runtime_player_bag.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  setUpAll(() async {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader(
      'packages/map_player_ui/PokeMapSplashDMSans',
    )..addFont(rootBundle.load('assets/fonts/DMSans-Variable.ttf'))).load();
  });

  for (final size in [
    const Size(1440, 900),
    const Size(1024, 768),
    const Size(390, 844),
    const Size(768, 1024),
    const Size(844, 390),
    const Size(496, 432),
  ]) {
    testWidgets('six bag items remain visible together at $size', (
      tester,
    ) async {
      await _pump(
        tester,
        _detail(List.generate(6, (i) => _item('item$i'))),
        size: size,
        safeInsets: size == const Size(844, 390)
            ? const EdgeInsets.fromLTRB(44, 12, 44, 20)
            : EdgeInsets.zero,
      );
      final bounds = tester.getRect(
        find.byKey(const ValueKey('runtime-player-detail-bag')),
      );
      for (var i = 0; i < 6; i++) {
        final row = find.byKey(ValueKey('bag-item-item$i'));
        expect(row.hitTestable(), findsOneWidget);
        expect(
          tester.getRect(row).bottom,
          lessThanOrEqualTo(bounds.bottom + .1),
        );
        expect(
          find.byKey(ValueKey('bag-info-item$i')).hitTestable(),
          findsOneWidget,
        );
      }
      expect(find.byKey(const ValueKey('player-page-next')), findsNothing);
      expect(find.byType(Scrollable), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('touch information inspects any item without using it', (
    tester,
  ) async {
    final commands = <RuntimePlayerPauseCommand>[];
    await _pump(
      tester,
      _detail([_item('a'), _item('b')]),
      onCommand: commands.add,
    );
    final info = find.byKey(const ValueKey('bag-info-b'));
    expect(tester.getSize(info).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(info).height, greaterThanOrEqualTo(48));
    await tester.tap(info);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('bag-detail-b')), findsOneWidget);
    expect(commands, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('landscape bag shows several items without a permanent preview', (
    tester,
  ) async {
    await _pump(
      tester,
      _detail(List.generate(18, (i) => _item('item$i'))),
      size: const Size(844, 390),
    );
    expect(
      find.byKey(const ValueKey('bag-item-item0')).hitTestable(),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('bag-item-item1')).hitTestable(),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('bag-item-item3')).hitTestable(),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('bag-detail-item0')), findsNothing);
    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('portrait pocket tabs keep their complete labels visible', (
    tester,
  ) async {
    await _pump(tester, _detail([_item('potion')]), size: const Size(390, 844));
    for (final pocket in ['medicine', 'balls', 'key']) {
      final tab = find.byKey(ValueKey('bag-pocket-$pocket'));
      expect(tab.hitTestable(), findsOneWidget);
      for (final element
          in find
              .descendant(of: tab, matching: find.byType(RichText))
              .evaluate()) {
        expect(
          (element.renderObject! as RenderParagraph).didExceedMaxLines,
          isFalse,
        );
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Thor bag shows four items with separate information targets', (
    tester,
  ) async {
    await _pump(
      tester,
      _detail(List.generate(18, (i) => _item('item$i'))),
      size: const Size(496, 432),
    );
    for (var i = 0; i < 4; i++) {
      final row = find.byKey(ValueKey('bag-item-item$i'));
      final info = find.byKey(ValueKey('bag-info-item$i'));
      expect(row.hitTestable(), findsOneWidget);
      expect(info.hitTestable(), findsOneWidget);
      expect(
        tester.getRect(info).left - tester.getRect(row).right,
        greaterThanOrEqualTo(8),
      );
      expect(tester.getSize(info).width, greaterThanOrEqualTo(48));
    }
    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'one eligible target uses its real identity directly from the row',
    (tester) async {
      final commands = <RuntimePlayerPauseCommand>[];
      await _pump(
        tester,
        _detail([_item('potion', requiresConfirmation: false)]),
        onCommand: commands.add,
      );
      await tester.tap(find.byKey(const ValueKey('bag-item-potion')));
      await tester.pumpAndSettle();
      expect(commands, hasLength(1));
      expect(commands.single.itemTargetId, 'potion');
      expect(commands.single.partyTargetId, 'pokemon.a');
      expect(find.byType(Dialog), findsNothing);
    },
  );

  testWidgets('bag paginates items and pockets without a scroll surface', (
    tester,
  ) async {
    await _pump(
      tester,
      _detail(List.generate(18, (index) => _item('item$index'))),
      size: const Size(390, 844),
    );
    final bag = find.byKey(const ValueKey('runtime-player-detail-bag'));
    expect(
      find.descendant(of: bag, matching: find.byType(Scrollable)),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('player-page-next')), findsOneWidget);
  });

  for (final size in [const Size(390, 844), const Size(844, 390)]) {
    testWidgets('bag footer exposes every action without scrolling at $size', (
      tester,
    ) async {
      final favorites = <String>[];
      await _pump(
        tester,
        _detail([_item('potion')]),
        size: size,
        onFavorite: (id, _) async => favorites.add(id),
      );
      expect(
        find.byKey(const ValueKey('runtime-player-bag-use-potion')),
        findsNothing,
      );
      await _inspect(tester, 'potion');
      final bounds = <Rect>[];
      for (final id in [
        'runtime-player-bag-use-potion',
        'bag-favorite-potion',
        'pause-frame-return',
      ]) {
        final button = find.byKey(ValueKey('$id-surface'));
        expect(button.hitTestable(), findsOneWidget, reason: id);
        final rect = tester.getRect(button);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
        expect(rect.height, greaterThanOrEqualTo(48));
        bounds.add(rect);
      }
      expect(bounds[0].width, closeTo(bounds[1].width, .1));
      expect(bounds[0].width, closeTo(bounds[2].width, .1));
      await tester.tap(find.byKey(const ValueKey('bag-favorite-potion')));
      await tester.pumpAndSettle();
      expect(favorites, ['potion']);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'favorite quantity uses a real icon without unsupported text glyphs',
    (tester) async {
      for (final size in [const Size(390, 844), const Size(844, 390)]) {
        await _pump(
          tester,
          _detail([_item('a', quantity: 8)]),
          size: size,
          favorites: {'a'},
        );
        final quantity = find.byKey(const ValueKey('bag-quantity-a'));
        final icon = find.byKey(const ValueKey('bag-favorite-marker-a'));
        expect(icon, findsOneWidget);
        expect(tester.widget<Icon>(icon).icon, Icons.star_rounded);
        expect(tester.getSize(icon), const Size(12, 12));
        expect(
          find.descendant(of: quantity, matching: find.text('× 8')),
          findsOneWidget,
        );
        expect(find.textContaining('★'), findsNothing);
        expect(
          tester.getRect(icon).right,
          lessThan(tester.getRect(quantity).right),
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('item pages retain quantity, row size and anchored pockets', (
    tester,
  ) async {
    await _pump(
      tester,
      _detail(List.generate(14, (i) => _item('item$i'))),
      size: const Size(390, 844),
    );
    final first = tester.getRect(find.byKey(const ValueKey('bag-item-item0')));
    final quantity = tester.getRect(
      find.byKey(const ValueKey('bag-quantity-item0')),
    );
    expect(first.height, closeTo(76, .01));
    expect(quantity.width, 40);
    final pockets = tester.getRect(find.byKey(const ValueKey('bag-pockets')));
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('bag-list-medicine')),
        matching: find.byKey(const ValueKey('player-page-next')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('bag-item-item0')), findsNothing);
    for (
      var page = 0;
      page < 14 &&
          find.byKey(const ValueKey('bag-item-item13')).evaluate().isEmpty;
      page++
    ) {
      final next = find.descendant(
        of: find.byKey(const ValueKey('bag-list-medicine')),
        matching: find.byKey(const ValueKey('player-page-next')),
      );
      expect(tester.widget<IconButton>(next).onPressed, isNotNull);
      await tester.tap(next);
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const ValueKey('bag-item-item13')), findsOneWidget);
    expect(tester.getRect(find.byKey(const ValueKey('bag-pockets'))), pockets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('information returns to the same item page and selection', (
    tester,
  ) async {
    final nav = RuntimePlayerBagNavigation();
    addTearDown(nav.dispose);
    await _pump(
      tester,
      _detail(List.generate(14, (index) => _item('item$index'))),
      size: const Size(390, 844),
      navigation: nav,
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('bag-list-medicine')),
        matching: find.byKey(const ValueKey('player-page-next')),
      ),
    );
    await tester.pumpAndSettle();
    final visible = tester
        .widgetList<PlayerMenuSelectableRow>(
          find.byWidgetPredicate(
            (widget) =>
                widget is PlayerMenuSelectableRow &&
                widget.id.startsWith('bag-item-'),
          ),
        )
        .last;
    final id = visible.id.substring('bag-item-'.length);
    await _inspect(tester, id);
    expect(nav.back(), isTrue);
    await tester.pumpAndSettle();
    final row = find.byKey(ValueKey('bag-item-$id'));
    expect(row.hitTestable(), findsOneWidget);
    expect(tester.widget<PlayerMenuSelectableRow>(row).selected, isTrue);
  });

  testWidgets('landscape bag detail keeps its title and description visible', (
    tester,
  ) async {
    const description = 'Restaure 20 PV à un Pokémon.';
    await _pump(
      tester,
      _detail([_item('potion', name: 'Potion', description: description)]),
      size: const Size(844, 390),
      safeInsets: const EdgeInsets.fromLTRB(59, 0, 59, 21),
    );
    await _tap(tester, 'bag-info-potion');
    final detail = find.byKey(const ValueKey('bag-detail-potion'));
    final viewport = tester.getRect(detail);
    for (final value in ['Potion', description]) {
      final text = find.descendant(of: detail, matching: find.text(value));
      expect(text.hitTestable(), findsOneWidget, reason: value);
      final bounds = tester.getRect(text);
      expect(bounds.top, greaterThanOrEqualTo(viewport.top));
      expect(bounds.bottom, lessThanOrEqualTo(viewport.bottom));
    }
    expect(
      find.descendant(of: detail, matching: find.byType(Scrollable)),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'real surface router supplies the bag money theme without an outer scope',
    (tester) async {
      final detail = _detail([_item('a')]);
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapPlayerTheme.dark(),
          localizationsDelegates:
              PokeMapPlayerLocalizations.localizationsDelegates,
          supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
          home: RuntimePlayerSurfaceRouter(
            snapshot: RuntimePlayerSnapshot(
              revision: 1,
              phase: RuntimePlayerPhase.paused,
              gameTitle: 'Le train de 17h42',
              pauseSection: RuntimePlayerPauseSection.bag,
              pauseDetails: {RuntimePlayerPauseSection.bag: detail},
              actions: const [
                RuntimePlayerActionAvailability.enabled(
                  RuntimePlayerAction.openBag,
                ),
              ],
            ),
            titlePresentation: const RuntimePlayerTitlePresentation(
              author: 'Train',
            ),
            pausePresentation: const PlayerPausePresentation(
              style: ProjectPauseMenuStyle.nightIllustrated,
            ),
            gameSceneBuilder: (_) => const SizedBox.expand(),
            onAction: (_) async => const RuntimePlayerCommandResult(
              status: RuntimePlayerCommandStatus.accepted,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('bag-money')), findsOneWidget);
      expect(find.text('Money : 3,200'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'pockets restore selected item and empty pockets remain available',
    (tester) async {
      final detail = _detail([
        _item('a'),
        _item('b'),
        _item('ball', pocket: 'balls'),
      ]);
      final navigation = RuntimePlayerBagNavigation();
      addTearDown(navigation.dispose);
      await _pump(tester, detail, navigation: navigation);
      await _inspect(tester, 'b');
      expect(navigation.back(), isTrue);
      await tester.pumpAndSettle();
      await _tap(tester, 'bag-pocket-balls');
      expect(
        tester
            .widget<PlayerMenuSelectableRow>(
              find.byKey(const ValueKey('bag-item-ball')),
            )
            .selected,
        isTrue,
      );
      await _tap(tester, 'bag-pocket-medicine');
      expect(
        tester
            .widget<PlayerMenuSelectableRow>(
              find.byKey(const ValueKey('bag-item-b')),
            )
            .selected,
        isTrue,
      );
      await _tap(tester, 'bag-pocket-key');
      expect(find.byKey(const ValueKey('bag-pocket-empty')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'last unit removed selects nearest item and keeps canonical quantity',
    (tester) async {
      await _pump(tester, _detail([_item('a'), _item('b'), _item('c')]));
      await _inspect(tester, 'b');
      await _pump(tester, _detail([_item('a'), _item('c', quantity: 7)]));
      expect(find.byKey(const ValueKey('bag-detail-c')), findsOneWidget);
      expect(find.byKey(const ValueKey('bag-item-b')), findsNothing);
      expect(find.text('× 7'), findsOneWidget);
    },
  );

  for (final size in [
    const Size(1440, 900),
    const Size(1024, 768),
    const Size(768, 1024),
    const Size(844, 390),
    const Size(390, 844),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('bag list and detail readable at $size text $scale', (
        tester,
      ) async {
        final nav = RuntimePlayerBagNavigation();
        addTearDown(nav.dispose);
        await _pump(
          tester,
          _detail([
            _item('potion', name: 'Potion supérieure au nom très long'),
          ]),
          size: size,
          scale: scale,
          navigation: nav,
        );
        await _inspect(tester, 'potion');
        expect(find.byKey(const ValueKey('bag-detail-potion')), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _tap(tester, 'runtime-player-bag-use-potion');
        expect(find.byKey(const ValueKey('bag-use-confirm')), findsNothing);
        expect(find.byType(Dialog), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets('world item resolves without a target or confirmation', (
    tester,
  ) async {
    final commands = <RuntimePlayerPauseCommand>[];
    await _pump(
      tester,
      _detail([_item('repel', kind: RuntimePlayerBagUseTargetKind.world)]),
      onCommand: commands.add,
    );
    await tester.tap(find.byKey(const ValueKey('bag-item-repel')));
    await tester.pumpAndSettle();
    expect(commands, hasLength(1));
    expect(commands.single.partyTargetId, isEmpty);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('information does not use an item', (tester) async {
    final commands = <RuntimePlayerPauseCommand>[];
    await _pump(
      tester,
      _detail([_item('potion')]),
      onCommand: commands.add,
      size: const Size(390, 844),
    );
    await _tap(tester, 'bag-info-potion');
    expect(find.byKey(const ValueKey('bag-detail-potion')), findsOneWidget);
    expect(commands, isEmpty);
  });

  testWidgets('no eligible target refuses without a command', (tester) async {
    final commands = <RuntimePlayerPauseCommand>[];
    await _pump(
      tester,
      _detail([_item('potion', eligibleTargets: {})]),
      onCommand: commands.add,
    );
    await tester.tap(find.byKey(const ValueKey('bag-item-potion')));
    await tester.pumpAndSettle();
    expect(commands, isEmpty);
    expect(
      find.text('Aucun compagnon ne peut recevoir cet objet.'),
      findsOneWidget,
    );
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('single eligibility excludes refused companions', (tester) async {
    final commands = <RuntimePlayerPauseCommand>[];
    await _pump(
      tester,
      _detail(
        [
          _item(
            'potion',
            eligibleTargets: {'pokemon.a', 'pokemon.b'},
            unavailableTargets: {'pokemon.a': 'PV complets'},
          ),
        ],
        targets: [
          RuntimePlayerBagPartyTargetSnapshot(
            targetId: 'pokemon.a',
            label: 'A',
          ),
          RuntimePlayerBagPartyTargetSnapshot(
            targetId: 'pokemon.b',
            label: 'B',
          ),
          RuntimePlayerBagPartyTargetSnapshot(
            targetId: 'pokemon.c',
            label: 'C',
          ),
        ],
      ),
      onCommand: commands.add,
    );
    await tester.tap(find.byKey(const ValueKey('bag-item-potion')));
    await tester.pumpAndSettle();
    expect(commands.single.partyTargetId, 'pokemon.b');
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('several eligible targets choose once and return directly', (
    tester,
  ) async {
    final commands = <RuntimePlayerPauseCommand>[];
    await _pump(
      tester,
      _detail(
        [_item('potion')],
        targets: [
          RuntimePlayerBagPartyTargetSnapshot(
            targetId: 'pokemon.a',
            label: 'A',
          ),
          RuntimePlayerBagPartyTargetSnapshot(
            targetId: 'pokemon.b',
            label: 'B',
          ),
        ],
      ),
      onCommand: commands.add,
    );
    await tester.tap(find.byKey(const ValueKey('bag-item-potion')));
    await tester.pumpAndSettle();
    expect(commands, isEmpty);
    await _tap(tester, 'runtime-player-bag-target-pokemon.b');
    expect(commands.single.partyTargetId, 'pokemon.b');
    expect(find.byKey(const ValueKey('bag-use-confirm')), findsNothing);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets(
    'six target choices paginate without scrolling and cancel safely',
    (tester) async {
      final commands = <RuntimePlayerPauseCommand>[];
      await _pump(
        tester,
        _detail(
          [_item('potion')],
          targets: List.generate(
            6,
            (index) => RuntimePlayerBagPartyTargetSnapshot(
              targetId: 'pokemon.$index',
              label: 'Compagnon numéro $index',
              subtitle: 'PV 12/38',
            ),
          ),
        ),
        onCommand: commands.add,
        size: const Size(844, 390),
        scale: 2,
      );
      await tester.tap(find.byKey(const ValueKey('bag-item-potion')));
      await tester.pumpAndSettle();
      final dialog = find.byType(Dialog);
      expect(
        find.descendant(of: dialog, matching: find.byType(Scrollable)),
        findsNothing,
      );
      expect(
        find.descendant(
          of: dialog,
          matching: find.byKey(const ValueKey('player-page-next')),
        ),
        findsOneWidget,
      );
      await _tap(tester, 'runtime-player-bag-target-close');
      expect(commands, isEmpty);
      expect(find.byType(Dialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final kind in [
    RuntimePlayerBagUseTargetKind.partyMember,
    RuntimePlayerBagUseTargetKind.partyMoveReplacement,
  ]) {
    testWidgets('$kind preserves its explicit critical confirmation', (
      tester,
    ) async {
      final commands = <RuntimePlayerPauseCommand>[];
      await _pump(
        tester,
        _detail([_item('critical', kind: kind, requiresConfirmation: true)]),
        onCommand: commands.add,
      );
      await tester.tap(find.byKey(const ValueKey('bag-item-critical')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('runtime-player-bag-target-pokemon.a')),
        findsNothing,
      );
      if (kind == RuntimePlayerBagUseTargetKind.partyMoveReplacement) {
        await _tap(tester, 'runtime-player-bag-target-pokemon.a-move1');
        expect(find.textContaining('oublier'), findsOneWidget);
      }
      expect(commands, isEmpty);
      await _tap(tester, 'bag-use-confirm');
      expect(commands, hasLength(1));
      expect(commands.single.partyTargetId, 'pokemon.a');
      expect(
        commands.single.moveTargetId,
        kind == RuntimePlayerBagUseTargetKind.partyMoveReplacement
            ? 'move1'
            : null,
      );
    });
  }

  testWidgets('cancel critical replacement keeps the bag unchanged', (
    tester,
  ) async {
    final commands = <RuntimePlayerPauseCommand>[];
    await _pump(
      tester,
      _detail([
        _item(
          'tm',
          kind: RuntimePlayerBagUseTargetKind.partyMoveReplacement,
          requiresConfirmation: true,
        ),
      ]),
      onCommand: commands.add,
    );
    await _tap(tester, 'runtime-player-bag-use-tm');
    await _tap(tester, 'runtime-player-bag-target-pokemon.a-move1');
    for (var depth = 0; depth < 3; depth++) {
      await _tap(tester, 'runtime-player-bag-target-close');
    }
    expect(commands, isEmpty);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('PP restore keeps move choice without a redundant confirmation', (
    tester,
  ) async {
    final commands = <RuntimePlayerPauseCommand>[];
    await _pump(
      tester,
      _detail([_item('ether', kind: RuntimePlayerBagUseTargetKind.partyMove)]),
      onCommand: commands.add,
    );
    await _tap(tester, 'runtime-player-bag-use-ether');
    await _tap(tester, 'runtime-player-bag-target-pokemon.a-move1');
    expect(commands.single.moveTargetId, 'move1');
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('pending direct use ignores immediate duplicate activation', (
    tester,
  ) async {
    final commands = <RuntimePlayerPauseCommand>[];
    final pending = Completer<void>();
    await _pump(
      tester,
      _detail([_item('potion')]),
      onCommand: (command) {
        commands.add(command);
        return pending.future;
      },
    );
    final row = tester.widget<PlayerMenuSelectableRow>(
      find.byKey(const ValueKey('bag-item-potion')),
    );
    row.onPressed!();
    row.onPressed!();
    await tester.pump();
    expect(commands, hasLength(1));
    pending.complete();
    await tester.pumpAndSettle();
  });

  for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.space]) {
    testWidgets('held ${key.keyLabel} never repeats a direct item use', (
      tester,
    ) async {
      final commands = <RuntimePlayerPauseCommand>[];
      await _pump(tester, _detail([_item('potion')]), onCommand: commands.add);
      final row = tester.widget<PlayerMenuSelectableRow>(
        find.byKey(const ValueKey('bag-item-potion')),
      );
      row.focusNode!.requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(key);
      try {
        await tester.pumpAndSettle();
        for (var repeat = 0; repeat < 4; repeat++) {
          await tester.sendKeyRepeatEvent(key);
          await tester.pumpAndSettle();
        }
        expect(commands, hasLength(1));
      } finally {
        await tester.sendKeyUpEvent(key);
      }
    });
  }

  testWidgets('long description uses explicit pages without scrolling', (
    tester,
  ) async {
    await _pump(
      tester,
      _detail([
        _item('a', description: List.filled(80, 'Description.').join(' ')),
      ]),
      size: const Size(390, 844),
    );
    await _inspect(tester, 'a');
    final detail = find.byKey(const ValueKey('bag-detail-a'));
    expect(
      find.descendant(of: detail, matching: find.byType(Scrollable)),
      findsNothing,
    );
    await tester.tap(
      find.descendant(
        of: detail,
        matching: find.byKey(const ValueKey('player-page-next')),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('bag-description-chunk-0')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'logical controller reaches offscreen pockets and restores selection',
    (tester) async {
      await _pump(
        tester,
        _detail([
          _item('a'),
          for (var i = 0; i < 5; i++) _item('extra$i', pocket: 'extra$i'),
          _item('b', pocket: 'destination'),
        ]),
        size: const Size(390, 844),
      );
      expect(find.byKey(const ValueKey('bag-pockets-next')), findsOneWidget);
      final first = tester.widget<PlayerMenuSelectableRow>(
        find.byKey(const ValueKey('bag-pocket-medicine')),
      );
      first.focusNode!.requestFocus();
      await tester.pumpAndSettle();
      for (var i = 0; i < 8; i++) {
        Actions.invoke(
          FocusManager.instance.primaryFocus!.context!,
          const RuntimePlayerLogicalIntent(
            PlayerInputAction.right,
            source: PlayerInputSource.controller,
          ),
        );
        await tester.pumpAndSettle();
      }
      final last = tester.widget<PlayerMenuSelectableRow>(
        find.byKey(const ValueKey('bag-pocket-destination')),
      );
      expect(last.focusNode!.hasFocus, isTrue);
      expect(last.selected, isTrue);
      expect(
        find.byKey(const ValueKey('bag-pocket-destination')).hitTestable(),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('bag-item-b')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('keyboard pocket pagination reaches both edges', (tester) async {
    await _pump(
      tester,
      _detail([
        _item('a'),
        for (var i = 0; i < 5; i++) _item('extra$i', pocket: 'extra$i'),
        _item('b', pocket: 'destination'),
      ]),
      size: const Size(390, 844),
    );
    final first = tester.widget<PlayerMenuSelectableRow>(
      find.byKey(const ValueKey('bag-pocket-medicine')),
    );
    first.focusNode!.requestFocus();
    await tester.pumpAndSettle();
    for (var step = 0; step < 8; step++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const ValueKey('bag-pockets-next')), findsNothing);
    expect(
      tester
          .widget<PlayerMenuSelectableRow>(
            find.byKey(const ValueKey('bag-pocket-destination')),
          )
          .focusNode!
          .hasFocus,
      isTrue,
    );
    for (var step = 0; step < 8; step++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const ValueKey('bag-pockets-previous')), findsNothing);
    expect(
      tester
          .widget<PlayerMenuSelectableRow>(
            find.byKey(const ValueKey('bag-pocket-medicine')),
          )
          .focusNode!
          .hasFocus,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('pocket pagination selects and focuses a visible pocket', (
    tester,
  ) async {
    await _pump(
      tester,
      _detail([
        _item('a'),
        for (var i = 0; i < 7; i++) _item('extra$i', pocket: 'extra$i'),
      ]),
      size: const Size(390, 844),
    );
    final arrow = find.byKey(const ValueKey('bag-pockets-next'));
    await tester.tap(arrow);
    await tester.pumpAndSettle();
    final firstVisible = tester
        .widgetList<PlayerMenuSelectableRow>(
          find.byWidgetPredicate(
            (widget) =>
                widget is PlayerMenuSelectableRow &&
                widget.id.startsWith('bag-pocket-'),
          ),
        )
        .first;
    expect(firstVisible.selected, isTrue);
    expect(firstVisible.focusNode!.hasFocus, isTrue);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('runtime-player-detail-bag')),
        matching: find.byType(Scrollable),
      ),
      findsNothing,
    );
  });

  testWidgets(
    'eight canonical pocket icons are centered and keep their labels',
    (tester) async {
      final semantics = tester.ensureSemantics();
      const pockets = [
        RuntimePlayerBagPocketSnapshot(id: 'medicine', label: 'Soins'),
        RuntimePlayerBagPocketSnapshot(id: 'items', label: 'Objets'),
        RuntimePlayerBagPocketSnapshot(id: 'balls', label: 'Balls'),
        RuntimePlayerBagPocketSnapshot(id: 'held-items', label: 'Objets tenus'),
        RuntimePlayerBagPocketSnapshot(
          id: 'evolution-items',
          label: 'Évolution',
        ),
        RuntimePlayerBagPocketSnapshot(id: 'machines', label: 'CT/CS'),
        RuntimePlayerBagPocketSnapshot(id: 'key-items', label: 'Objets clés'),
        RuntimePlayerBagPocketSnapshot(id: 'battle-items', label: 'Combat'),
      ];
      const icons = [
        Icons.medication_rounded,
        Icons.inventory_2_rounded,
        Icons.catching_pokemon,
        Icons.diamond_outlined,
        Icons.auto_awesome_rounded,
        Icons.album_rounded,
        Icons.vpn_key_rounded,
        Icons.shield_rounded,
      ];
      await _pump(
        tester,
        _detail([_item('a')], pockets: pockets),
        size: const Size(844, 390),
      );
      expect(find.byKey(const ValueKey('bag-pockets-next')), findsNothing);
      expect(find.byKey(const ValueKey('bag-pockets-previous')), findsNothing);
      for (var index = 0; index < pockets.length; index++) {
        final row = find.byKey(ValueKey('bag-pocket-${pockets[index].id}'));
        final icon = find.descendant(
          of: row,
          matching: find.byIcon(icons[index]),
        );
        final rowBounds = tester.getRect(row);
        expect(rowBounds.width, greaterThanOrEqualTo(48));
        expect(rowBounds.height, greaterThanOrEqualTo(48));
        expect(
          (tester.getCenter(icon) - rowBounds.center).distance,
          lessThanOrEqualTo(2.01),
        );
        expect(row.hitTestable(), findsOneWidget);
        expect(
          tester.getSemantics(row).getSemanticsData().label,
          contains(pockets[index].label),
        );
        expect(
          tester
              .widget<Tooltip>(
                find.ancestor(of: row, matching: find.byType(Tooltip)).first,
              )
              .message,
          pockets[index].label,
        );
      }
      final first = tester.widget<PlayerMenuSelectableRow>(
        find.byKey(const ValueKey('bag-pocket-medicine')),
      );
      final marker = find.byKey(
        const ValueKey('bag-pocket-medicine-focus-marker'),
      );
      expect(first.selected, isTrue);
      expect(marker, findsNothing);
      first.focusNode!.requestFocus();
      await tester.pumpAndSettle();
      expect(marker, findsOneWidget);
      final item = tester.widget<PlayerMenuSelectableRow>(
        find.byKey(const ValueKey('bag-item-a')),
      );
      item.focusNode!.requestFocus();
      await tester.pumpAndSettle();
      expect(first.selected, isTrue);
      expect(marker, findsNothing);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets(
    'favorite waits for persistence, filter updates and errors stay safe',
    (tester) async {
      final pending = Completer<void>();
      final detail = _detail([_item('a'), _item('b')]);
      await _pump(tester, detail, onFavorite: (_, _) => pending.future);
      await _tap(tester, 'bag-favorite-a');
      expect(find.text('Retirer des favoris'), findsNothing);
      pending.complete();
      await tester.pumpAndSettle();
      await _pump(
        tester,
        detail,
        favorites: {'a'},
        onFavorite: (_, _) async {},
      );
      await _tap(tester, 'bag-pocket-@favorites');
      expect(find.byKey(const ValueKey('bag-item-a')), findsOneWidget);
      expect(find.byKey(const ValueKey('bag-item-b')), findsNothing);
      await _pump(
        tester,
        detail,
        favorites: {'a'},
        onFavorite: (_, _) async {
          throw StateError('/private/secret');
        },
      );
      await _tap(tester, 'bag-favorite-a');
      expect(find.textContaining('/private/secret'), findsNothing);
      expect(
        find.byKey(const ValueKey('runtime-player-bag-message')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'late failed command after leaving bag does not mutate disposed UI',
    (tester) async {
      final pending = Completer<void>();
      await _pump(
        tester,
        _detail([_item('a')]),
        onCommand: (_) => pending.future,
      );
      await _tap(tester, 'runtime-player-bag-use-a');
      await tester.pumpWidget(const SizedBox.shrink());
      pending.completeError(StateError('stale'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('logical controller uses the focused item directly', (
    tester,
  ) async {
    final commands = <RuntimePlayerPauseCommand>[];
    await _pump(
      tester,
      _detail([_item('a'), _item('b')]),
      onCommand: commands.add,
      size: const Size(390, 844),
    );
    final row = tester.widget<PlayerMenuSelectableRow>(
      find.byKey(const ValueKey('bag-item-b')),
    );
    row.focusNode!.requestFocus();
    await tester.pumpAndSettle();
    Actions.invoke(
      FocusManager.instance.primaryFocus!.context!,
      const RuntimePlayerLogicalIntent(
        PlayerInputAction.confirm,
        source: PlayerInputSource.controller,
      ),
    );
    await tester.pumpAndSettle();
    expect(commands.single.itemTargetId, 'b');
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('captures bag reference and compact layouts when requested', (
    tester,
  ) async {
    const directory = String.fromEnvironment('MENU6_CAPTURE_DIR');
    for (final size in [
      const Size(1440, 900),
      const Size(844, 390),
      const Size(390, 844),
    ]) {
      await _pump(
        tester,
        _detail(
          List.generate(
            9,
            (i) => _item(
              'item$i',
              name: [
                'Potion',
                'Super Potion',
                'Rappel',
                'Antidote',
                'Anti-Para',
                'Guérison',
                'Pierre Feu',
                'Pierre Eau',
                'Hyper Potion',
              ][i],
            ),
          ),
        ),
        size: size,
      );
      await tester.pump(const Duration(milliseconds: 300));
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('bag-capture')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '$directory/menu6-${size.width.toInt()}x${size.height.toInt()}.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  }, skip: const String.fromEnvironment('MENU6_CAPTURE_DIR').isEmpty);
}

RuntimePlayerDetailEntrySnapshot _item(
  String id, {
  String? name,
  String pocket = 'medicine',
  String description =
      'Restaure les PV d’un Pokémon selon le catalogue du jeu.',
  int quantity = 12,
  bool requiresConfirmation = false,
  Set<String>? eligibleTargets,
  Map<String, String> unavailableTargets = const {},
  RuntimePlayerBagUseTargetKind kind =
      RuntimePlayerBagUseTargetKind.partyMember,
}) => RuntimePlayerDetailEntrySnapshot(
  id: 'bag.$id',
  title: name ?? id,
  bagItem: RuntimePlayerBagItemSnapshot(
    itemId: id,
    quantity: quantity,
    sortOrder: 0,
    pocketId: pocket,
    description: description,
  ),
  bagAction: RuntimePlayerBagItemActionSnapshot(
    itemTargetId: id,
    targetKind: kind,
    requiresConfirmation: requiresConfirmation,
    eligiblePartyTargetIds: eligibleTargets,
    unavailablePartyTargetReasons: unavailableTargets,
    usability: ItemUsabilityState.usable,
    isEnabled: true,
    learnedMoveLabel: 'Surf',
  ),
);

RuntimePlayerPauseDetailSnapshot _detail(
  List<RuntimePlayerDetailEntrySnapshot> entries, {
  int moves = 4,
  List<RuntimePlayerBagPartyTargetSnapshot>? targets,
  List<RuntimePlayerBagPocketSnapshot> pockets = const [
    RuntimePlayerBagPocketSnapshot(id: 'medicine', label: 'Soins'),
    RuntimePlayerBagPocketSnapshot(id: 'balls', label: 'Balls'),
    RuntimePlayerBagPocketSnapshot(id: 'key', label: 'Objets clés'),
  ],
}) => RuntimePlayerPauseDetailSnapshot(
  section: RuntimePlayerPauseSection.bag,
  title: 'Sac',
  entries: entries,
  bagMoney: 3200,
  bagPockets: pockets,
  bagTargets:
      targets ??
      [
        RuntimePlayerBagPartyTargetSnapshot(
          targetId: 'pokemon.a',
          requiresMoveReplacement: moves >= 4,
          label: 'Bulbizarre',
          subtitle: 'PV 12/38',
          moves: List.generate(
            moves,
            (i) => RuntimePlayerBagMoveTargetSnapshot(
              targetId: 'move$i',
              label: 'Capacité $i',
              subtitle: 'PP 0/10',
            ),
          ),
        ),
      ],
);

Future<void> _inspect(WidgetTester tester, String id) async {
  final row = tester.widget<PlayerMenuSelectableRow>(
    find.byKey(ValueKey('bag-item-$id')),
  );
  row.focusNode!.requestFocus();
  await tester.pumpAndSettle();
  await _tap(tester, 'bag-info-$id');
}

Future<void> _tap(WidgetTester tester, String key) async {
  if (key.startsWith('runtime-player-bag-use-') &&
      find.byKey(ValueKey(key)).evaluate().isEmpty) {
    await _inspect(tester, key.substring('runtime-player-bag-use-'.length));
  }
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _pump(
  WidgetTester tester,
  RuntimePlayerPauseDetailSnapshot detail, {
  Size size = const Size(1440, 900),
  double scale = 1,
  EdgeInsets safeInsets = EdgeInsets.zero,
  RuntimePlayerBagNavigation? navigation,
  FutureOr<void> Function(RuntimePlayerPauseCommand)? onCommand,
  Set<String> favorites = const {},
  Future<void> Function(String, bool)? onFavorite,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  final nav = navigation ?? RuntimePlayerBagNavigation();
  if (navigation == null) addTearDown(nav.dispose);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          padding: safeInsets,
          viewPadding: safeInsets,
        ),
        child: child!,
      ),
      home: PlayerMenuThemeScope(
        role: ProjectPresentationSurfaceRole.bag,
        child: Scaffold(
          body: RepaintBoundary(
            key: const ValueKey('bag-capture'),
            child: RuntimePlayerPauseShell(
              gameTitle: 'Le train de 17h42',
              pauseSection: RuntimePlayerPauseSection.bag,
              actions: {
                for (final action in PlayerPauseAction.values)
                  action: PlayerActionAvailability.enabled,
              },
              onSelected: (_) {},
              onBackToRoot: nav.back,
              presentation: const PlayerPausePresentation(
                style: ProjectPauseMenuStyle.nightIllustrated,
              ),
              detailHeaderSecondary: Text('${detail.bagMoney ?? 0}'),
              detailOwnsScroll: true,
              detailActions: ListenableBuilder(
                listenable: nav,
                builder: (context, _) => nav.buildActions(context),
              ),
              detailFooterBuilder: (context, returnAction) => ListenableBuilder(
                listenable: nav,
                builder: (context, _) =>
                    nav.buildActions(context, returnAction: returnAction),
              ),
              detail: RuntimePlayerBag(
                detail: detail,
                navigation: nav,
                onCommand: onCommand ?? (_) {},
                favoriteItemIds: favorites,
                onFavoriteChanged: onFavorite,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
