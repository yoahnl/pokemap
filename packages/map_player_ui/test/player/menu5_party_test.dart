import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/player/player_party_pokemon_detail.dart';
import 'package:map_player_ui/src/player/player_pokemon_image.dart';
import 'package:map_player_ui/src/player/runtime_player_party.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('packages/map_player_ui/PokeMapSplashDMSans')
          ..addFont(rootBundle.load('assets/fonts/DMSans-Variable.ttf')))
        .load();
  });

  for (final summary in [true, false]) {
    testWidgets(
        'desktop actions hands keyboard focus to ${summary ? 'summary' : 'held item'} modal',
        (tester) async {
      final navigation = RuntimePlayerPartyNavigation();
      addTearDown(navigation.dispose);
      final commands = <RuntimePlayerPauseCommand>[];
      await _pump(tester, [_member('first'), _member('second', held: true)],
          navigation: navigation,
          onCommand: commands.add,
          size: const Size(1440, 900));
      await _focus(tester, 'second');
      Actions.invoke(
          FocusManager.instance.primaryFocus!.context!,
          const RuntimePlayerLogicalIntent(PlayerInputAction.confirm,
              source: PlayerInputSource.controller));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      final actionKey = summary
          ? 'runtime-player-party-summary-pokemon.second'
          : 'runtime-player-held-manage-pokemon.second';
      final action = find.descendant(
          of: find.byType(Dialog), matching: find.byKey(ValueKey(actionKey)));
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      if (summary) {
        expect(find.byType(PlayerPokemonSummarySheet), findsOneWidget);
      } else {
        expect(find.byKey(const ValueKey('party-held-dialog-scroll')),
            findsOneWidget);
      }
      expect(
          ModalRoute.of(FocusManager.instance.primaryFocus!.context!)
              ?.isCurrent,
          isTrue,
          reason:
              'Closing Actions must not focus a member behind the new modal.');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(
          ModalRoute.of(FocusManager.instance.primaryFocus!.context!)
              ?.isCurrent,
          isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(_row(tester, 'second').focusNode!.hasFocus, isTrue);
      expect(commands, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }

  testWidgets('six nominal rows fit completely in the 1296x644 reference body',
      (tester) async {
    final names = [
      'Bulbizarre',
      'Pikachu',
      'Évoli',
      'Roucool',
      'Goupix',
      'Abra'
    ];
    await _pump(tester,
        List.generate(6, (i) => _member('member$i', nickname: names[i])),
        size: const Size(1296, 644));

    Rect? previous;
    for (var i = 0; i < 6; i++) {
      final row = find.byKey(ValueKey('party-member-member$i'));
      final bounds = tester.getRect(row);
      expect(bounds.height, closeTo(94, .01));
      expect(bounds.top, greaterThanOrEqualTo(0));
      expect(bounds.bottom, lessThanOrEqualTo(644));
      expect(row.hitTestable(), findsOneWidget);
      if (previous != null) {
        expect(bounds.top - previous.bottom, closeTo(16, .01));
      }
      previous = bounds;
    }
    expect(previous!.bottom, closeTo(644, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'two logical confirms open compact detail then the focused summary',
      (tester) async {
    final navigation = RuntimePlayerPartyNavigation();
    addTearDown(navigation.dispose);
    await _pump(tester, [_member('first'), _member('second')],
        size: const Size(390, 844), navigation: navigation);
    await _focus(tester, 'second');
    const confirm = RuntimePlayerLogicalIntent(PlayerInputAction.confirm,
        source: PlayerInputSource.controller);

    Actions.invoke(FocusManager.instance.primaryFocus!.context!, confirm);
    await tester.pumpAndSettle();
    expect(_detail(tester).summary.individualId, 'second');
    expect(find.byType(PlayerPokemonSummarySheet), findsNothing);
    expect(tester.takeException(), isNull);

    Actions.invoke(FocusManager.instance.primaryFocus!.context!, confirm);
    await tester.pumpAndSettle();
    expect(find.byType(PlayerPokemonSummarySheet), findsOneWidget);
    expect(find.text('2468'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a portrait desktop window uses a readable list then detail',
      (tester) async {
    final navigation = RuntimePlayerPartyNavigation();
    addTearDown(navigation.dispose);
    await _pump(
        tester, [_member('first', nickname: 'Bulbizarre'), _member('second')],
        navigation: navigation, size: const Size(954, 1080));
    expect(find.byType(PlayerPartyPokemonDetail), findsNothing);
    expect(
        tester.getSize(find.byKey(const ValueKey('party-member-first'))).width,
        greaterThan(700));
    await _tap(tester, 'party-member-first');
    expect(_detail(tester).summary.displayLabel, 'Bulbizarre');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final style in ProjectPauseMenuStyle.values) {
    for (final size in [const Size(1440, 900), const Size(390, 844)]) {
      testWidgets('$style footer keeps party commands accessible at $size',
          (tester) async {
        final navigation = RuntimePlayerPartyNavigation();
        addTearDown(navigation.dispose);
        await _pump(tester,
            [_member('first', held: true), _member('second', held: true)],
            navigation: navigation,
            size: size,
            style: style,
            onCommand: (_) {},
            canReorder: true);
        await _focus(tester, 'second');
        for (final key in [
          'runtime-player-party-summary-pokemon.second',
          'runtime-player-held-manage-pokemon.second',
          'party-swap',
        ]) {
          final action = find.byKey(ValueKey(key));
          expect(action, findsOneWidget);
          expect(
              find.descendant(
                  of: find.byType(RuntimePlayerParty), matching: action),
              findsNothing);
          await tester.ensureVisible(action);
          await tester.pumpAndSettle();
          expect(action.hitTestable(), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        expect(navigation.back(), isFalse);
      });
    }
  }

  testWidgets(
      'wide illustrated party shows all four moves above its real footer',
      (tester) async {
    final navigation = RuntimePlayerPartyNavigation();
    addTearDown(navigation.dispose);
    await _pump(
        tester,
        [
          _member('first', nickname: 'Pikachu', held: true, moveCount: 4),
          _member('second')
        ],
        navigation: navigation,
        size: const Size(1440, 900),
        onCommand: (_) {},
        canReorder: true);
    final viewport =
        tester.getRect(find.byKey(const ValueKey('party-detail-scroll')));
    for (var index = 0; index < 4; index++) {
      final move = find.byKey(ValueKey('party-detail-move-slot-$index'));
      final bounds = tester.getRect(move);
      expect(bounds.top, greaterThanOrEqualTo(viewport.top));
      expect(bounds.bottom, lessThanOrEqualTo(viewport.bottom));
      expect(Scrollable.of(tester.element(move)).position.pixels, 0);
    }
    expect(find.text('Vive-Attaque'), findsOneWidget);
    expect(find.text('Charge'), findsOneWidget);
    final summary = find
        .byKey(const ValueKey('runtime-player-party-summary-pokemon.first'));
    expect(summary.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  for (final count in [0, 1, 3, 6]) {
    testWidgets('renders $count real members without duplicating empty slots',
        (tester) async {
      await _pump(tester, List.generate(count, (i) => _member('member$i')));

      expect(find.byType(PlayerMenuSelectableRow), findsNWidgets(count));
      if (count == 0) {
        expect(find.text('Votre équipe est vide'), findsOneWidget);
        expect(find.byType(PlayerPartyPokemonDetail), findsNothing);
      } else {
        for (var i = count; i < 6; i++) {
          final empty = find.byKey(ValueKey('party-empty-slot-$i'));
          expect(empty, findsOneWidget);
          expect(find.descendant(of: empty, matching: find.byType(Focus)),
              findsNothing);
        }
        expect(_detail(tester).summary.individualId, 'member0');
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'focus selects by identity and fresh snapshots replace the detail',
      (tester) async {
    final first = _member('first');
    final second = _member('second', hp: 19);
    await _pump(tester, [first, second, _member('third')]);
    await _focus(tester, 'second');
    expect(_detail(tester).summary.currentHp, 19);
    expect(_row(tester, 'second').selected, isTrue);

    final changed = _member('second', hp: 0, status: 'Paralysie');
    await _pump(tester, [changed, first, _member('third')]);

    expect(_detail(tester).summary.individualId, 'second');
    expect(_detail(tester).summary.currentHp, 0);
    expect(_row(tester, 'second').focusNode!.hasFocus, isTrue);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('party-member-second')),
            matching: find.text('KO')),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byType(PlayerPartyPokemonDetail),
            matching: find.text('KO')),
        findsOneWidget);
    final images = tester.widgetList<PlayerPokemonImage>(
      find.byType(PlayerPokemonImage),
    );
    expect(images.where((image) => !image.thumbnail).single.summary,
        same(changed.pokemonSummary));
    expect(
        images
            .where((image) =>
                image.thumbnail && image.summary.individualId == 'second')
            .single
            .summary,
        same(changed.pokemonSummary));
    expect(tester.takeException(), isNull);
  });

  testWidgets('disappearing selection chooses the nearest valid member',
      (tester) async {
    await _pump(
        tester, [_member('first'), _member('second'), _member('third')]);
    await _focus(tester, 'second');

    await _pump(tester, [_member('first'), _member('third')]);

    expect(_detail(tester).summary.individualId, 'third');
    expect(_row(tester, 'third').selected, isTrue);
    await _pump(tester, []);
    expect(find.text('Votre équipe est vide'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swap cancel emits nothing and confirmed swap follows its source',
      (tester) async {
    final commands = <RuntimePlayerPauseCommand>[];
    final entries = [_member('first'), _member('second'), _member('third')];
    await _pump(tester, entries, onCommand: commands.add, canReorder: true);
    await _focus(tester, 'second');
    await _tap(tester, 'party-swap');
    expect(find.byKey(const ValueKey('party-swap-source')), findsOneWidget);
    await _focus(tester, 'third');
    expect(_row(tester, 'third').selected, isTrue);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('party-member-second')),
            matching: find.byKey(const ValueKey('party-swap-source'))),
        findsOneWidget);
    await _tap(tester, 'party-swap-cancel');
    expect(commands, isEmpty);
    expect(find.byKey(const ValueKey('party-swap-source')), findsNothing);

    await _focus(tester, 'second');
    await _tap(tester, 'party-swap');
    await _tap(tester, 'party-member-third');
    expect(commands, hasLength(1));
    expect(
        commands.single.kind, RuntimePlayerPauseCommandKind.reorderPartyMember);
    expect(commands.single.partyTargetId, 'pokemon.second');
    expect(commands.single.secondPartyTargetId, 'pokemon.third');
    await _pump(tester, [entries[0], entries[2], entries[1]],
        onCommand: commands.add, canReorder: true);
    expect(_detail(tester).summary.individualId, 'second');
    expect(_row(tester, 'second').focusNode!.hasFocus, isTrue);
  });

  testWidgets('swap is absent when the runtime does not authorize it',
      (tester) async {
    await _pump(tester, [_member('first'), _member('second')],
        onCommand: (_) {});
    expect(find.byKey(const ValueKey('party-swap')), findsNothing);
  });

  testWidgets(
      'navigation back consumes compact detail and cancels swap locally',
      (tester) async {
    final navigation = RuntimePlayerPartyNavigation();
    addTearDown(navigation.dispose);
    final commands = <RuntimePlayerPauseCommand>[];
    var rootReturns = 0;
    await _pump(tester, [_member('first'), _member('second')],
        size: const Size(390, 844),
        navigation: navigation,
        onRootBack: () => rootReturns++,
        onCommand: commands.add,
        canReorder: true);
    expect(navigation.back(), isFalse);
    await _tap(tester, 'party-member-second');
    expect(_detail(tester).summary.individualId, 'second');

    await _tap(tester, 'pause-frame-return-surface');
    expect(find.byType(PlayerPartyPokemonDetail), findsNothing);
    expect(_row(tester, 'second').focusNode!.hasFocus, isTrue);
    expect(navigation.back(), isFalse);
    await _tap(tester, 'party-member-second');
    await _tap(tester, 'party-swap');
    expect(find.byKey(const ValueKey('party-swap-source')), findsOneWidget);

    await _tap(tester, 'pause-frame-return-surface');
    expect(find.byKey(const ValueKey('party-swap-source')), findsNothing);
    expect(_row(tester, 'second').focusNode!.hasFocus, isTrue);
    expect(navigation.back(), isFalse);
    expect(commands, isEmpty);
    expect(rootReturns, 0);
    await _tap(tester, 'pause-frame-return-surface');
    expect(rootReturns, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'real footer follows selection, settles, and detaches on disposal',
      (tester) async {
    final navigation = RuntimePlayerPartyNavigation();
    var notifications = 0;
    navigation.addListener(() => notifications++);
    await _pump(tester, [_member('first'), _member('second')],
        navigation: navigation, size: const Size(1440, 900));
    await _focus(tester, 'second');
    final summary = find
        .byKey(const ValueKey('runtime-player-party-summary-pokemon.second'));
    expect(summary, findsOneWidget);
    expect(find.ancestor(of: summary, matching: find.byType(PlayerMenuFooter)),
        findsOneWidget);
    expect(
        find.descendant(of: find.byType(RuntimePlayerParty), matching: summary),
        findsNothing);
    expect(
        find.byKey(
            const ValueKey('runtime-player-party-summary-pokemon.first')),
        findsNothing);
    expect(notifications, greaterThan(0));
    final settledNotifications = notifications;
    await tester.pump(const Duration(milliseconds: 500));
    expect(notifications, settledNotifications);
    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(navigation.back(), isFalse);
    expect(navigation.buildActions(tester.element(find.byType(SizedBox))),
        isA<SizedBox>());
    navigation.dispose();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'held modal at 568x320 and text 2 keeps return and removal reachable',
      (tester) async {
    final commands = <RuntimePlayerPauseCommand>[];
    await _pump(tester, [_member('first', held: true)],
        size: const Size(568, 320), scale: 2, onCommand: commands.add);
    await _tap(tester, 'party-member-first');
    await _tap(tester, 'runtime-player-held-manage-pokemon.first');
    final modal = find.byKey(const ValueKey('party-held-dialog-scroll'));
    expect(MediaQuery.textScalerOf(tester.element(modal)).scale(10), 20);
    expect(tester.takeException(), isNull);
    final close = find.byKey(const ValueKey('runtime-player-held-close'));
    await tester.ensureVisible(close);
    await tester.pumpAndSettle();
    expect(close.hitTestable(), findsOneWidget);
    await _tap(tester, 'runtime-player-held-close');
    expect(commands, isEmpty);
    expect(modal, findsNothing);

    await _tap(tester, 'runtime-player-held-manage-pokemon.first');
    final remove =
        find.byKey(const ValueKey('runtime-player-held-take-pokemon.first'));
    await tester.ensureVisible(remove);
    await tester.pumpAndSettle();
    expect(remove.hitTestable(), findsOneWidget);
    await _tap(tester, 'runtime-player-held-take-pokemon.first');
    expect(commands, hasLength(1));
    expect(commands.single.kind, RuntimePlayerPauseCommandKind.unequipHeldItem);
    expect(commands.single.partyTargetId, 'pokemon.first');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'typed command failure exposes its safe reason without raw exception',
      (tester) async {
    const reason = 'Cet objet n’est plus présent dans le sac.';
    await _pump(tester, [_member('first', held: true)], onCommand: (_) async {
      throw const RuntimePlayerPartyCommandFailure(reason);
    });
    await _tap(tester, 'runtime-player-held-manage-pokemon.first');
    await _tap(tester, 'runtime-player-held-option-pokemon.first-leftovers');

    expect(find.text(reason), findsOneWidget);
    expect(
        find.textContaining('RuntimePlayerPartyCommandFailure'), findsNothing);
    expect(find.textContaining('Instance of'), findsNothing);
    expect(_row(tester, 'first').busy, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'held command waits for completion and prevents another activation',
      (tester) async {
    final pending = Completer<void>();
    final commands = <RuntimePlayerPauseCommand>[];
    Future<void> dispatch(RuntimePlayerPauseCommand command) {
      commands.add(command);
      return pending.future;
    }

    await _pump(tester, [_member('first', held: true), _member('second')],
        onCommand: dispatch, canReorder: true);
    await _tap(tester, 'runtime-player-held-manage-pokemon.first');
    await _tap(tester, 'runtime-player-held-option-pokemon.first-leftovers');

    expect(commands, hasLength(1));
    expect(commands.single.kind, RuntimePlayerPauseCommandKind.equipHeldItem);
    expect(commands.single.itemTargetId, 'leftovers');
    expect(commands.single.partyTargetId, 'pokemon.first');
    expect(_row(tester, 'first').busy, isTrue);
    final manage = tester.widget<PlayerActionButton>(
        find.byKey(const ValueKey('runtime-player-held-manage-pokemon.first')));
    expect(manage.onPressed, isNull);
    expect(
        tester
            .widget<PlayerActionButton>(
                find.byKey(const ValueKey('party-swap')))
            .onPressed,
        isNull);
    await tester.tap(find.byKey(const ValueKey('party-member-second')));
    await tester.pump();
    expect(commands, hasLength(1));
    expect(_detail(tester).summary.individualId, 'first');

    pending.complete();
    await tester.pumpAndSettle();
    expect(_row(tester, 'first').busy, isFalse);
    expect(
        tester
            .widget<PlayerActionButton>(find.byKey(
                const ValueKey('runtime-player-held-manage-pokemon.first')))
            .onPressed,
        isNotNull);
  });

  testWidgets(
      'held item removal targets the member and command errors stay safe',
      (tester) async {
    final commands = <RuntimePlayerPauseCommand>[];
    await _pump(tester, [_member('first', held: true)],
        onCommand: (command) async {
      commands.add(command);
      throw StateError('private transaction internals');
    });
    await _tap(tester, 'runtime-player-held-manage-pokemon.first');
    await _tap(tester, 'runtime-player-held-take-pokemon.first');

    expect(commands.single.kind, RuntimePlayerPauseCommandKind.unequipHeldItem);
    expect(commands.single.partyTargetId, 'pokemon.first');
    expect(find.textContaining('private transaction internals'), findsNothing);
    expect(find.byKey(const ValueKey('party-command-message')), findsOneWidget);
    expect(_row(tester, 'first').busy, isFalse);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(390, 844), const Size(844, 390)]) {
    testWidgets('compact $size at text 2 keeps detail and return usable',
        (tester) async {
      await _pump(tester, [_member('long', longName: true)],
          size: size, scale: 2);
      expect(
          find.byKey(const ValueKey('party-compact-scroll')), findsOneWidget);
      await _tap(tester, 'party-member-long');
      expect(find.byType(PlayerPartyPokemonDetail), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _tap(tester, 'party-back-to-list');
      expect(find.byKey(const ValueKey('party-member-long')), findsOneWidget);
      expect(_row(tester, 'long').focusNode!.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'summary returns to the selected member without losing its fields',
      (tester) async {
    await _pump(tester, [_member('first'), _member('second')]);
    await _focus(tester, 'second');
    await _tap(tester, 'runtime-player-party-summary-pokemon.second');
    expect(find.text('Modeste'), findsWidgets);
    expect(find.text('2468'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(_detail(tester).summary.individualId, 'second');
    expect(_row(tester, 'second').focusNode!.hasFocus, isTrue);
  });

  testWidgets('missing images retain member labels through rapid focus changes',
      (tester) async {
    await _pump(tester, [_member('first'), _member('second')]);
    await _focus(tester, 'second');
    await _focus(tester, 'first');
    await _focus(tester, 'second');
    final illustration = tester
        .widgetList<PlayerPokemonImage>(find.byType(PlayerPokemonImage))
        .singleWhere((image) => !image.thumbnail);
    expect(illustration.summary.targetId, 'pokemon.second');
    expect(find.byKey(const ValueKey('pokemon-image-missing-pokemon.second')),
        findsNWidgets(2));
    expect(find.text('Compagnon second'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('late image completion cannot replace the newly selected member',
      (tester) async {
    const path = '/virtual-menu5/late-first.png';
    final pending = Completer<ImageInfo>();
    final provider = FileImage(File(path));
    final cache = PaintingBinding.instance.imageCache;
    cache.putIfAbsent(
        provider, () => OneFrameImageStreamCompleter(pending.future));
    addTearDown(() => cache.evict(provider));
    const media = RuntimePokemonSummaryMediaSnapshot(
      thumbnail: RuntimePokemonLocalImageSnapshot(
          absoluteFilePath: path, sampling: ProjectMenuImageSampling.pixelArt),
      illustration: RuntimePokemonLocalImageSnapshot(
          absoluteFilePath: path, sampling: ProjectMenuImageSampling.pixelArt),
    );
    await _pump(tester, [_member('first', media: media), _member('second')]);
    expect(find.byKey(const ValueKey('pokemon-image-missing-pokemon.first')),
        findsNWidgets(2));
    await _focus(tester, 'second');
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawColor(const Color(0xFFFF0000), BlendMode.src);
    final picture = recorder.endRecording();
    final image = picture.toImageSync(1, 1);
    picture.dispose();
    pending.complete(ImageInfo(image: image));
    await tester.pumpAndSettle();

    final detail = find.byType(PlayerPartyPokemonDetail);
    expect(_detail(tester).summary.individualId, 'second');
    expect(find.descendant(of: detail, matching: find.byType(RawImage)),
        findsNothing);
    expect(
        find.descendant(
            of: detail,
            matching: find
                .byKey(const ValueKey('pokemon-image-missing-pokemon.second'))),
        findsOneWidget);
    expect(find.text('Compagnon second'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester,
  List<RuntimePlayerDetailEntrySnapshot> entries, {
  FutureOr<void> Function(RuntimePlayerPauseCommand)? onCommand,
  bool canReorder = false,
  RuntimePlayerPartyNavigation? navigation,
  VoidCallback? onRootBack,
  ProjectPauseMenuStyle style = ProjectPauseMenuStyle.nightIllustrated,
  Size size = const Size(1440, 1100),
  double scale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final party = RuntimePlayerParty(
    detail: RuntimePlayerPauseDetailSnapshot(
      section: RuntimePlayerPauseSection.party,
      title: 'Équipe',
      entries: entries,
    ),
    onCommand: onCommand,
    canReorder: canReorder,
    navigation: navigation,
  );
  final content = navigation == null
      ? party
      : RuntimePlayerPauseShell(
          gameTitle: 'Voyage',
          pauseSection: RuntimePlayerPauseSection.party,
          actions: {
            for (final action in PlayerPauseAction.values)
              action: PlayerActionAvailability.enabled
          },
          onSelected: (_) {},
          onBackToRoot: () {
            if (!navigation.back()) onRootBack?.call();
          },
          detail: party,
          detailOwnsScroll: true,
          detailActions: ListenableBuilder(
            listenable: navigation,
            builder: (context, _) => navigation.buildActions(context),
          ),
          presentation: PlayerPausePresentation(style: style),
        );
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('fr'),
    supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
    localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
    theme: PokeMapPlayerTheme.dark(),
    builder: (context, child) => MediaQuery(
      data:
          MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: PlayerMenuThemeScope(
      role: ProjectPresentationSurfaceRole.party,
      child: Scaffold(
        body: RuntimePlayerActions(
          onBack: () {
            navigation?.back();
          },
          onMenu: () {},
          onInputSourceChanged: (_) {},
          child: content,
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

PlayerMenuSelectableRow _row(WidgetTester tester, String id) => tester
    .widget<PlayerMenuSelectableRow>(find.byKey(ValueKey('party-member-$id')));

PlayerPartyPokemonDetail _detail(WidgetTester tester) => tester
    .widget<PlayerPartyPokemonDetail>(find.byType(PlayerPartyPokemonDetail));

Future<void> _focus(WidgetTester tester, String id) async {
  _row(tester, id).focusNode!.requestFocus();
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

RuntimePlayerDetailEntrySnapshot _member(String id,
    {int hp = 30,
    String? status,
    bool held = false,
    bool longName = false,
    String? nickname,
    int moveCount = 2,
    RuntimePokemonSummaryMediaSnapshot media =
        const RuntimePokemonSummaryMediaSnapshot()}) {
  final summary = RuntimePokemonSummarySnapshot(
    targetId: 'pokemon.$id',
    individualId: id,
    speciesLabel: 'Espèce $id',
    nickname: longName
        ? 'Un surnom extrêmement long pour une créature très patiente'
        : nickname ?? 'Compagnon $id',
    level: 17,
    currentHp: hp,
    maxHp: 50,
    natureLabel: 'Modeste',
    abilityLabel: 'Engrais',
    friendship: 80,
    experience: 2468,
    genderLabel: 'Femelle',
    statusLabel: status,
    media: media,
    heldItemLabel: held ? 'Baie Oran' : null,
    typeIds: ['grass', 'poison'],
    stats: const RuntimePokemonStatsSummarySnapshot(
        attack: 21,
        defense: 24,
        specialAttack: 30,
        specialDefense: 26,
        speed: 19),
    moves: const [
      RuntimePokemonMoveSummarySnapshot(
          moveId: 'vine-whip',
          label: 'Fouet Lianes',
          typeId: 'grass',
          currentPp: 7,
          maxPp: 25),
      RuntimePokemonMoveSummarySnapshot(
          moveId: 'growl',
          label: 'Rugissement',
          typeId: 'normal',
          currentPp: 18,
          maxPp: 40),
      RuntimePokemonMoveSummarySnapshot(
          moveId: 'quick-attack',
          label: 'Vive-Attaque',
          typeId: 'normal',
          currentPp: 12,
          maxPp: 30),
      RuntimePokemonMoveSummarySnapshot(
          moveId: 'tackle',
          label: 'Charge',
          typeId: 'normal',
          currentPp: 20,
          maxPp: 35),
    ].take(moveCount).toList(growable: false),
  );
  return RuntimePlayerDetailEntrySnapshot(
    id: summary.targetId,
    title: summary.displayLabel,
    pokemonSummary: summary,
    heldItemAction: held
        ? RuntimePlayerHeldItemActionSnapshot(
            partyTargetId: summary.targetId,
            currentItemLabel: 'Baie Oran',
            options: const [
              RuntimePlayerHeldItemOptionSnapshot(
                  itemTargetId: 'leftovers', label: 'Restes')
            ],
          )
        : null,
  );
}
