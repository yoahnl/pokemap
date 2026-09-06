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
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    await (FontLoader('packages/map_player_ui/PokeMapSplashDMSans')
          ..addFont(rootBundle.load('assets/fonts/DMSans-Variable.ttf')))
        .load();
  });

  testWidgets('nine rows fit reference list with fixed pockets and footer',
      (tester) async {
    await _pump(tester, _detail(List.generate(14, (i) => _item('item$i'))));
    final first = tester.getRect(find.byKey(const ValueKey('bag-item-item0')));
    final ninth = tester.getRect(find.byKey(const ValueKey('bag-item-item8')));
    expect(first.height, closeTo(52, .01));
    final quantity =
        tester.getRect(find.byKey(const ValueKey('bag-quantity-item0')));
    expect(quantity.width, 72);
    expect(first.right - quantity.right, closeTo(13.5, .01));
    expect(ninth.bottom - first.top, closeTo(532, .01));
    expect(find.byKey(const ValueKey('bag-item-item8')).hitTestable(),
        findsOneWidget);
    final pockets = tester.getRect(find.byKey(const ValueKey('bag-pockets')));
    await tester.drag(
        find.byKey(const ValueKey('bag-list-medicine')), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const ValueKey('bag-pockets'))), pockets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'real surface router supplies the bag money theme without an outer scope',
      (tester) async {
    final detail = _detail([_item('a')]);
    await tester.pumpWidget(MaterialApp(
      theme: PokeMapPlayerTheme.dark(),
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      home: RuntimePlayerSurfaceRouter(
        snapshot: RuntimePlayerSnapshot(
            revision: 1,
            phase: RuntimePlayerPhase.paused,
            gameTitle: 'Le train de 17h42',
            pauseSection: RuntimePlayerPauseSection.bag,
            pauseDetails: {
              RuntimePlayerPauseSection.bag: detail
            },
            actions: const [
              RuntimePlayerActionAvailability.enabled(
                  RuntimePlayerAction.openBag)
            ]),
        titlePresentation:
            const RuntimePlayerTitlePresentation(author: 'Train'),
        pausePresentation: const PlayerPausePresentation(
            style: ProjectPauseMenuStyle.nightIllustrated),
        gameSceneBuilder: (_) => const SizedBox.expand(),
        onAction: (_) async => const RuntimePlayerCommandResult(
            status: RuntimePlayerCommandStatus.accepted),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('bag-money')), findsOneWidget);
    expect(find.text('Money : 3,200'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'pockets restore selected item and empty pockets remain available',
      (tester) async {
    final detail =
        _detail([_item('a'), _item('b'), _item('ball', pocket: 'balls')]);
    await _pump(tester, detail);
    await _tap(tester, 'bag-item-b');
    await _tap(tester, 'bag-pocket-balls');
    expect(find.byKey(const ValueKey('bag-detail-ball')), findsOneWidget);
    await _tap(tester, 'bag-pocket-medicine');
    expect(find.byKey(const ValueKey('bag-detail-b')), findsOneWidget);
    await _tap(tester, 'bag-pocket-key');
    expect(find.byKey(const ValueKey('bag-pocket-empty')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'last unit removed selects nearest item and keeps canonical quantity',
      (tester) async {
    await _pump(tester, _detail([_item('a'), _item('b'), _item('c')]));
    await _tap(tester, 'bag-item-b');
    await _pump(tester, _detail([_item('a'), _item('c', quantity: 7)]));
    expect(find.byKey(const ValueKey('bag-detail-c')), findsOneWidget);
    expect(find.byKey(const ValueKey('bag-item-b')), findsNothing);
    expect(find.text('× 7'), findsOneWidget);
  });

  for (final size in [
    const Size(1440, 900),
    const Size(844, 390),
    const Size(390, 844)
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('bag list and detail readable at $size text $scale',
          (tester) async {
        final nav = RuntimePlayerBagNavigation();
        addTearDown(nav.dispose);
        await _pump(
            tester,
            _detail(
                [_item('potion', name: 'Potion supérieure au nom très long')]),
            size: size,
            scale: scale,
            navigation: nav);
        await _tap(tester, 'bag-item-potion');
        expect(find.byKey(const ValueKey('bag-detail-potion')), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _tap(tester, 'runtime-player-bag-use-potion');
        await _tap(tester, 'runtime-player-bag-target-pokemon.a');
        expect(find.byKey(const ValueKey('bag-use-confirm')), findsOneWidget);
        await _tap(tester, 'runtime-player-bag-target-close');
        await _tap(tester, 'runtime-player-bag-target-close');
        expect(find.byType(Dialog), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  for (final kind in RuntimePlayerBagUseTargetKind.values) {
    for (final count
        in kind == RuntimePlayerBagUseTargetKind.partyMoveReplacement
            ? [2, 4]
            : [4]) {
      testWidgets(
          '$kind with $count moves requires confirmation and emits once',
          (tester) async {
        final commands = <RuntimePlayerPauseCommand>[];
        final pending = Completer<void>();
        await _pump(tester, _detail([_item('use', kind: kind)], moves: count),
            onCommand: (command) {
          commands.add(command);
          return pending.future;
        });
        await _tap(tester, 'runtime-player-bag-use-use');
        await _tap(tester, 'runtime-player-bag-target-pokemon.a');
        if (kind == RuntimePlayerBagUseTargetKind.partyMove ||
            kind == RuntimePlayerBagUseTargetKind.partyMoveReplacement &&
                count == 4) {
          await _tap(tester, 'runtime-player-bag-target-pokemon.a-move0');
        }
        expect(commands, isEmpty);
        if (kind == RuntimePlayerBagUseTargetKind.partyMoveReplacement) {
          expect(find.textContaining('Surf'), findsOneWidget);
          if (count == 4) {
            expect(find.textContaining('Capacité 0'), findsOneWidget);
          }
        }
        await _tap(tester, 'bag-use-confirm');
        expect(commands, hasLength(1));
        expect(commands.single.itemTargetId, 'use');
        expect(commands.single.partyTargetId, 'pokemon.a');
        expect(
            commands.single.moveTargetId,
            kind == RuntimePlayerBagUseTargetKind.partyMember || count == 2
                ? null
                : 'move0');
        await _tap(tester, 'runtime-player-bag-use-use');
        expect(find.byType(Dialog), findsNothing);
        expect(commands, hasLength(1));
        pending.complete();
        await tester.pumpAndSettle();
      });
    }
  }

  testWidgets('replacement back cancels each depth without teaching',
      (tester) async {
    final commands = <RuntimePlayerPauseCommand>[];
    await _pump(
        tester,
        _detail([
          _item('tm', kind: RuntimePlayerBagUseTargetKind.partyMoveReplacement)
        ]),
        onCommand: commands.add);
    await _tap(tester, 'runtime-player-bag-use-tm');
    await _tap(tester, 'runtime-player-bag-target-pokemon.a');
    await _tap(tester, 'runtime-player-bag-target-pokemon.a-move1');
    for (var i = 0; i < 3; i++) {
      await _tap(tester, 'runtime-player-bag-target-close');
    }
    expect(commands, isEmpty);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('two immediate use activations open only one target dialog',
      (tester) async {
    await _pump(tester, _detail([_item('a')]));
    final use = tester.widget<PlayerMenuSelectableRow>(
        find.byKey(const ValueKey('runtime-player-bag-use-a')));
    use.onPressed!();
    use.onPressed!();
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    await _tap(tester, 'runtime-player-bag-target-close');
    expect(find.byType(Dialog), findsNothing);
  });

  for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.space]) {
    final keyName = key == LogicalKeyboardKey.enter ? 'Enter' : 'Space';
    testWidgets('held $keyName cannot advance bag target stages',
        (tester) async {
      final commands = <RuntimePlayerPauseCommand>[];
      await _pump(tester, _detail([_item('a')]),
          onCommand: commands.add, size: const Size(390, 844));
      await _tap(tester, 'bag-item-a');
      await tester.sendKeyDownEvent(key);
      try {
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsOneWidget);
        expect(find.byKey(const ValueKey('bag-use-confirm')), findsNothing);
        await tester.sendKeyRepeatEvent(key);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('bag-use-confirm')), findsNothing);
        expect(commands, isEmpty);
      } finally {
        await tester.sendKeyUpEvent(key);
      }
      await tester.sendKeyDownEvent(key);
      try {
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('bag-use-confirm')), findsOneWidget);
        await tester.sendKeyRepeatEvent(key);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('bag-use-confirm')), findsOneWidget);
        expect(commands, isEmpty);
      } finally {
        await tester.sendKeyUpEvent(key);
      }
      await _tap(tester, 'runtime-player-bag-target-close');
      await _tap(tester, 'runtime-player-bag-target-close');
      expect(commands, isEmpty);
    });

    testWidgets('held $keyName cannot reopen bag use after completion',
        (tester) async {
      final commands = <RuntimePlayerPauseCommand>[];
      await _pump(tester, _detail([_item('a')]),
          onCommand: commands.add, size: const Size(390, 844));
      await _tap(tester, 'bag-item-a');
      await _tap(tester, 'runtime-player-bag-use-a');
      await _tap(tester, 'runtime-player-bag-target-pokemon.a');
      await tester.sendKeyDownEvent(key);
      try {
        await tester.pumpAndSettle();
        expect(commands, hasLength(1));
        expect(find.byType(Dialog), findsNothing);
        for (var repeat = 0; repeat < 4; repeat++) {
          await tester.sendKeyRepeatEvent(key);
          await tester.pumpAndSettle();
        }
        expect(commands, hasLength(1));
        expect(find.byType(Dialog), findsNothing);
      } finally {
        await tester.sendKeyUpEvent(key);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'controller confirms every replacement stage without pointer input',
      (tester) async {
    final commands = <RuntimePlayerPauseCommand>[];
    await _pump(
        tester,
        _detail([
          _item('tm', kind: RuntimePlayerBagUseTargetKind.partyMoveReplacement)
        ]),
        onCommand: commands.add);
    final use = tester.widget<PlayerMenuSelectableRow>(
        find.byKey(const ValueKey('runtime-player-bag-use-tm')));
    use.focusNode!.requestFocus();
    await tester.pumpAndSettle();
    for (var stage = 0; stage < 4; stage++) {
      Actions.invoke(
          FocusManager.instance.primaryFocus!.context!,
          const RuntimePlayerLogicalIntent(PlayerInputAction.confirm,
              source: PlayerInputSource.controller));
      await tester.pumpAndSettle();
      if (stage < 3) expect(commands, isEmpty);
    }
    expect(commands, hasLength(1));
    expect(commands.single.moveTargetId, 'move0');
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('long description scrolls with logical controller and keyboard',
      (tester) async {
    await _pump(
        tester,
        _detail([
          _item('a', description: List.filled(80, 'Description.').join(' '))
        ]),
        size: const Size(390, 844));
    await _tap(tester, 'bag-item-a');
    final detail = find.byKey(const ValueKey('bag-detail-a'));
    final focus = tester
        .widgetList<Focus>(
            find.ancestor(of: detail, matching: find.byType(Focus)))
        .firstWhere(
            (widget) => widget.focusNode?.debugLabel == 'Bag description');
    focus.focusNode!.requestFocus();
    await tester.pumpAndSettle();
    final scroll = tester.widget<SingleChildScrollView>(detail).controller!;
    final start = scroll.offset;
    Actions.invoke(
        FocusManager.instance.primaryFocus!.context!,
        const RuntimePlayerLogicalIntent(PlayerInputAction.down,
            source: PlayerInputSource.controller));
    await tester.pumpAndSettle();
    expect(scroll.offset, greaterThan(start));
    final afterController = scroll.offset;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(scroll.offset, greaterThan(afterController));
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact target cancellation restores visible use focus',
      (tester) async {
    await _pump(tester, _detail([_item('a')]), size: const Size(390, 844));
    await _tap(tester, 'bag-item-a');
    await _tap(tester, 'runtime-player-bag-use-a');
    await _tap(tester, 'runtime-player-bag-target-close');
    final use = tester.widget<PlayerMenuSelectableRow>(
        find.byKey(const ValueKey('runtime-player-bag-use-a')));
    expect(use.focusNode!.hasFocus, isTrue);
  });

  testWidgets(
      'logical controller reaches offscreen pockets and restores selection',
      (tester) async {
    await _pump(tester, _detail([_item('a'), _item('b', pocket: 'key')]),
        size: const Size(390, 844));
    expect(find.byKey(const ValueKey('bag-pockets-next')), findsOneWidget);
    final first = tester.widget<PlayerMenuSelectableRow>(
        find.byKey(const ValueKey('bag-pocket-medicine')));
    first.focusNode!.requestFocus();
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      Actions.invoke(
          FocusManager.instance.primaryFocus!.context!,
          const RuntimePlayerLogicalIntent(PlayerInputAction.right,
              source: PlayerInputSource.controller));
      await tester.pumpAndSettle();
    }
    final last = tester.widget<PlayerMenuSelectableRow>(
        find.byKey(const ValueKey('bag-pocket-key')));
    expect(last.focusNode!.hasFocus, isTrue);
    expect(last.selected, isTrue);
    expect(find.byKey(const ValueKey('bag-pocket-key')).hitTestable(),
        findsOneWidget);
    expect(find.byKey(const ValueKey('bag-item-b')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'favorite waits for persistence, filter updates and errors stay safe',
      (tester) async {
    final pending = Completer<void>();
    final detail = _detail([_item('a'), _item('b')]);
    await _pump(tester, detail, onFavorite: (_, __) => pending.future);
    await _tap(tester, 'bag-favorite-a');
    expect(find.text('Retirer des favoris'), findsNothing);
    pending.complete();
    await tester.pumpAndSettle();
    await _pump(tester, detail, favorites: {'a'}, onFavorite: (_, __) async {});
    await _tap(tester, 'bag-pocket-@favorites');
    expect(find.byKey(const ValueKey('bag-item-a')), findsOneWidget);
    expect(find.byKey(const ValueKey('bag-item-b')), findsNothing);
    await _pump(tester, detail, favorites: {'a'}, onFavorite: (_, __) async {
      throw StateError('/private/secret');
    });
    await _tap(tester, 'bag-favorite-a');
    expect(find.textContaining('/private/secret'), findsNothing);
    expect(find.byKey(const ValueKey('runtime-player-bag-message')),
        findsOneWidget);
  });

  testWidgets(
      'late failed command after leaving bag does not mutate disposed UI',
      (tester) async {
    final pending = Completer<void>();
    await _pump(tester, _detail([_item('a')]),
        onCommand: (_) => pending.future);
    await _tap(tester, 'runtime-player-bag-use-a');
    await _tap(tester, 'runtime-player-bag-target-pokemon.a');
    await _tap(tester, 'bag-use-confirm');
    await tester.pumpWidget(const SizedBox.shrink());
    pending.completeError(StateError('stale'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'logical controller selection opens compact detail and back restores list',
      (tester) async {
    final nav = RuntimePlayerBagNavigation();
    addTearDown(nav.dispose);
    await _pump(tester, _detail([_item('a'), _item('b')]),
        navigation: nav, size: const Size(390, 844));
    final row = tester.widget<PlayerMenuSelectableRow>(
        find.byKey(const ValueKey('bag-item-b')));
    row.focusNode!.requestFocus();
    await tester.pumpAndSettle();
    Actions.invoke(
        FocusManager.instance.primaryFocus!.context!,
        const RuntimePlayerLogicalIntent(PlayerInputAction.confirm,
            source: PlayerInputSource.controller));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('bag-detail-b')), findsOneWidget);
    expect(nav.back(), isTrue);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('bag-item-b')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('captures bag reference and compact layouts when requested',
      (tester) async {
    const directory = String.fromEnvironment('MENU6_CAPTURE_DIR');
    for (final size in [
      const Size(1440, 900),
      const Size(844, 390),
      const Size(390, 844)
    ]) {
      await _pump(
          tester,
          _detail(List.generate(
              9,
              (i) => _item('item$i',
                  name: [
                    'Potion',
                    'Super Potion',
                    'Rappel',
                    'Antidote',
                    'Anti-Para',
                    'Guérison',
                    'Pierre Feu',
                    'Pierre Eau',
                    'Hyper Potion'
                  ][i]))),
          size: size);
      await tester.pump(const Duration(milliseconds: 300));
      final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('bag-capture')));
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
                '$directory/menu6-${size.width.toInt()}x${size.height.toInt()}.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  }, skip: const String.fromEnvironment('MENU6_CAPTURE_DIR').isEmpty);
}

RuntimePlayerDetailEntrySnapshot _item(String id,
        {String? name,
        String pocket = 'medicine',
        String description =
            'Restaure les PV d’un Pokémon selon le catalogue du jeu.',
        int quantity = 12,
        RuntimePlayerBagUseTargetKind kind =
            RuntimePlayerBagUseTargetKind.partyMember}) =>
    RuntimePlayerDetailEntrySnapshot(
        id: 'bag.$id',
        title: name ?? id,
        bagItem: RuntimePlayerBagItemSnapshot(
            itemId: id,
            quantity: quantity,
            sortOrder: 0,
            pocketId: pocket,
            description: description),
        bagAction: RuntimePlayerBagItemActionSnapshot(
            itemTargetId: id,
            targetKind: kind,
            usability: ItemUsabilityState.usable,
            isEnabled: true,
            learnedMoveLabel: 'Surf'));

RuntimePlayerPauseDetailSnapshot _detail(
        List<RuntimePlayerDetailEntrySnapshot> entries,
        {int moves = 4}) =>
    RuntimePlayerPauseDetailSnapshot(
        section: RuntimePlayerPauseSection.bag,
        title: 'Sac',
        entries: entries,
        bagMoney: 3200,
        bagPockets: const [
          RuntimePlayerBagPocketSnapshot(id: 'medicine', label: 'Soins'),
          RuntimePlayerBagPocketSnapshot(id: 'balls', label: 'Balls'),
          RuntimePlayerBagPocketSnapshot(id: 'key', label: 'Objets clés')
        ],
        bagTargets: [
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
                      subtitle: 'PP 0/10')))
        ]);

Future<void> _tap(WidgetTester tester, String key) async {
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
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('fr'),
    supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
    localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
    theme: PokeMapPlayerTheme.dark(),
    builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!),
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
                    action: PlayerActionAvailability.enabled
                },
                onSelected: (_) {},
                onBackToRoot: nav.back,
                presentation: const PlayerPausePresentation(
                    style: ProjectPauseMenuStyle.nightIllustrated),
                detailHeaderSecondary: Text('${detail.bagMoney ?? 0}'),
                detailOwnsScroll: true,
                detailActions: ListenableBuilder(
                    listenable: nav,
                    builder: (context, _) => nav.buildActions(context)),
                detail: RuntimePlayerBag(
                    detail: detail,
                    navigation: nav,
                    onCommand: onCommand ?? (_) {},
                    favoriteItemIds: favorites,
                    onFavoriteChanged: onFavorite),
              )),
        )),
  ));
  await tester.pumpAndSettle();
}
