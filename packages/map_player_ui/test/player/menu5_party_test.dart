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

  for (final size in [
    const Size(390, 844),
    const Size(844, 390),
    const Size(1440, 900),
  ]) {
    testWidgets('party footer exposes one aligned action group at $size',
        (tester) async {
      final navigation = RuntimePlayerPartyNavigation();
      addTearDown(navigation.dispose);
      await _pump(tester, [_member('first', held: true), _member('second')],
          navigation: navigation,
          onCommand: (_) {},
          canReorder: true,
          size: size);
      final bounds = <Rect>[];
      for (final id in [
        'runtime-player-party-summary-pokemon.first',
        'runtime-player-held-manage-pokemon.first',
        'party-swap',
        'pause-frame-return',
      ]) {
        final button = find.byKey(ValueKey('$id-surface'));
        expect(button.hitTestable(), findsOneWidget, reason: id);
        final rect = tester.getRect(button);
        expect(rect.left, greaterThanOrEqualTo(0), reason: id);
        expect(rect.right, lessThanOrEqualTo(size.width), reason: id);
        expect(rect.bottom, lessThanOrEqualTo(size.height), reason: id);
        expect(rect.height, greaterThanOrEqualTo(48), reason: id);
        bounds.add(rect);
      }
      for (final rect in bounds.skip(1)) {
        expect(rect.width, closeTo(bounds.first.width, .1));
      }
      for (var i = 1; i < bounds.length; i++) {
        expect(bounds[i].top, closeTo(bounds.first.top, .1));
        expect(bounds[i].left - bounds[i - 1].right, closeTo(8, .1));
      }
      expect((bounds.first.left + bounds.last.right) / 2,
          closeTo(size.width / 2, .1));
      if (size.width < 600) {
        expect(bounds.first.height, lessThanOrEqualTo(72));
        final summary = find.byKey(
            const ValueKey('runtime-player-party-summary-pokemon.first'));
        final icon = find.descendant(of: summary, matching: find.byType(Icon));
        final label =
            find.descendant(of: summary, matching: find.text('Résumé'));
        expect(
            tester.getRect(icon).bottom, lessThan(tester.getRect(label).top));
      }
      expect(tester.takeException(), isNull);
    });
  }

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

  testWidgets('moving at 1440x900 keeps the sixth destination visible',
      (tester) async {
    final navigation = RuntimePlayerPartyNavigation();
    addTearDown(navigation.dispose);
    final commands = <RuntimePlayerPauseCommand>[];
    await _pump(tester,
        List.generate(6, (i) => _member('member$i', nickname: 'Pokémon $i')),
        size: const Size(1440, 900),
        navigation: navigation,
        onCommand: commands.add,
        canReorder: true);
    final sixth = find.byKey(const ValueKey('party-member-member5'));
    final before = tester.getRect(sixth);
    await _tap(tester, 'party-swap');
    expect(tester.getRect(sixth), before);
    expect(sixth.hitTestable(), findsOneWidget);
    final viewport =
        tester.getRect(find.byKey(const ValueKey('party-list-scroll')));
    expect(tester.getRect(sixth).bottom, lessThanOrEqualTo(viewport.bottom));
    final hint = find.text('Choisissez la nouvelle position');
    expect(tester.getTopLeft(hint).dx, greaterThan(viewport.right));
    final cancel = find.byKey(const ValueKey('party-swap-cancel'));
    expect(cancel.hitTestable(), findsOneWidget);
    expect(tester.getSize(cancel).width, lessThan(240));
    await tester.tap(sixth);
    await tester.pumpAndSettle();
    expect(commands.single.partyTargetId, 'pokemon.member0');
    expect(commands.single.secondPartyTargetId, 'pokemon.member5');
    expect(_row(tester, 'member0').focusNode!.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('party health gauges keep equal widths with or without gender',
      (tester) async {
    final navigation = RuntimePlayerPartyNavigation();
    addTearDown(navigation.dispose);
    await _pump(
        tester,
        [
          _member('female', nickname: 'Carapuce', gender: 'Femelle', hp: 0),
          _member('male', nickname: 'Salamèche', gender: 'Mâle'),
          _member('unknown', nickname: 'Germignon', gender: null),
          _member('status',
              nickname: 'Pikachu', gender: null, status: 'Brûlure'),
        ],
        size: const Size(1440, 900),
        navigation: navigation);
    double? expectedWidth;
    for (final id in ['female', 'male', 'unknown', 'status']) {
      final row = find.byKey(ValueKey('party-member-$id'));
      final gauge =
          find.descendant(of: row, matching: find.byType(PlayerMenuGauge));
      final width = tester.getSize(gauge).width;
      expectedWidth ??= width;
      expect(width, closeTo(expectedWidth, .01));
      expect(tester.getSize(row).height, 94);
    }
    for (final gender in [('female', Icons.female), ('male', Icons.male)]) {
      final row = find.byKey(ValueKey('party-member-${gender.$1}'));
      final symbol = find.descendant(of: row, matching: find.byIcon(gender.$2));
      expect(tester.getRect(row).right - tester.getRect(symbol).right,
          lessThanOrEqualTo(16));
    }
    final fainted = find.byKey(const ValueKey('party-member-female'));
    final status = find.byKey(const ValueKey('party-member-status'));
    expect(find.descendant(of: fainted, matching: find.text('KO')),
        findsOneWidget);
    expect(find.descendant(of: status, matching: find.text('Brûlure')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final gender in [('Femelle', Icons.female), ('Mâle', Icons.male)]) {
    testWidgets('selected ${gender.$1} symbol keeps its label and row contrast',
        (tester) async {
      await _pump(tester, [_member('first', gender: gender.$1)]);
      final row = find.byKey(const ValueKey('party-member-first'));
      final symbol = find.descendant(of: row, matching: find.byIcon(gender.$2));
      final icon = tester.widget<Icon>(symbol);
      final element = tester.element(symbol);
      expect(icon.size, 20);
      expect(icon.semanticLabel, gender.$1);
      expect(icon.color ?? IconTheme.of(element).color,
          DefaultTextStyle.of(element).style.color);
      expect(tester.getSemantics(row).getSemanticsData().value,
          contains(gender.$1));
      expect(find.descendant(of: row, matching: find.text(gender.$1)),
          findsNothing);
    });
  }

  testWidgets('genderless label remains explicit', (tester) async {
    await _pump(tester, [_member('first', gender: 'Asexué')]);
    final row = find.byKey(const ValueKey('party-member-first'));
    expect(find.descendant(of: row, matching: find.text('Asexué')),
        findsOneWidget);
    expect(find.descendant(of: row, matching: find.byIcon(Icons.male)),
        findsNothing);
    expect(find.descendant(of: row, matching: find.byIcon(Icons.female)),
        findsNothing);
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
    expect(find.text('Déplacer'), findsOneWidget);
    await _tap(tester, 'party-swap');
    expect(find.text('Choisissez la nouvelle position'), findsOneWidget);
    expect(
        find.text('Les deux Pokémon échangeront leur place.'), findsOneWidget);
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
    expect(_row(tester, 'second').focusNode!.hasFocus, isTrue);

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

  testWidgets(
      'controller selects the destination and cancels back to its source',
      (tester) async {
    final commands = <RuntimePlayerPauseCommand>[];
    await _pump(tester, [_member('first'), _member('second'), _member('third')],
        onCommand: commands.add, canReorder: true);
    await _focus(tester, 'second');
    await _tap(tester, 'party-swap');
    Actions.invoke(
        FocusManager.instance.primaryFocus!.context!,
        const RuntimePlayerLogicalIntent(PlayerInputAction.down,
            source: PlayerInputSource.controller));
    await tester.pumpAndSettle();
    expect(_row(tester, 'third').focusNode!.hasFocus, isTrue);
    Actions.invoke(
        FocusManager.instance.primaryFocus!.context!,
        const RuntimePlayerLogicalIntent(PlayerInputAction.back,
            source: PlayerInputSource.controller));
    await tester.pumpAndSettle();
    expect(_row(tester, 'second').focusNode!.hasFocus, isTrue);
    expect(commands, isEmpty);

    await _tap(tester, 'party-swap');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(commands.single.partyTargetId, 'pokemon.second');
    expect(commands.single.secondPartyTargetId, 'pokemon.first');
    expect(_row(tester, 'second').focusNode!.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rejected move keeps its source and accepts a later retry',
      (tester) async {
    const reason = 'Cette destination n’est plus disponible.';
    final commands = <RuntimePlayerPauseCommand>[];
    final pending = Completer<void>();
    await _pump(tester, [_member('first'), _member('second'), _member('third')],
        canReorder: true, onCommand: (command) {
      commands.add(command);
      return pending.future;
    });
    await _tap(tester, 'party-swap');
    await _tap(tester, 'party-member-third');
    await _tap(tester, 'party-member-second');
    expect(commands, hasLength(1));
    expect(_row(tester, 'first').busy, isTrue);
    expect(find.byKey(const ValueKey('party-swap-source')), findsNothing);
    pending.completeError(const RuntimePlayerPartyCommandFailure(reason));
    await tester.pumpAndSettle();
    expect(find.text(reason), findsOneWidget);
    expect(find.byKey(const ValueKey('party-swap-source')), findsOneWidget);
    expect(_row(tester, 'first').focusNode!.hasFocus, isTrue);

    await _pump(tester, [_member('first'), _member('second'), _member('third')],
        canReorder: true, onCommand: commands.add);
    await _tap(tester, 'party-member-second');
    expect(commands, hasLength(2));
    expect(commands.last.partyTargetId, 'pokemon.first');
    expect(commands.last.secondPartyTargetId, 'pokemon.second');
    expect(find.byKey(const ValueKey('party-swap-source')), findsNothing);
    expect(find.text(reason), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'controller confirms cancel without moving to the selected target',
      (tester) async {
    final commands = <RuntimePlayerPauseCommand>[];
    await _pump(tester, [_member('first'), _member('second')],
        canReorder: true, onCommand: commands.add);
    await _tap(tester, 'party-swap');
    await _focus(tester, 'second');
    final cancel = find.byKey(const ValueKey('party-swap-cancel'));
    final icon =
        find.descendant(of: cancel, matching: find.byIcon(Icons.close));
    Focus.of(tester.element(icon)).requestFocus();
    await tester.pumpAndSettle();
    Actions.invoke(
        FocusManager.instance.primaryFocus!.context!,
        const RuntimePlayerLogicalIntent(PlayerInputAction.confirm,
            source: PlayerInputSource.controller));
    await tester.pumpAndSettle();
    expect(commands, isEmpty);
    expect(find.byKey(const ValueKey('party-swap-source')), findsNothing);
    expect(_row(tester, 'first').focusNode!.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'dragging a party member dispatches the canonical reorder command',
      (tester) async {
    final commands = <RuntimePlayerPauseCommand>[];
    await _pump(tester, [_member('first'), _member('second'), _member('third')],
        canReorder: true, onCommand: commands.add);
    final source = find.byKey(const ValueKey('party-member-first'));
    final destination = find.byKey(const ValueKey('party-member-third'));
    final gesture = await tester.startGesture(tester.getCenter(source));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(tester.getCenter(destination));
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(commands, hasLength(1));
    expect(
        commands.single.kind, RuntimePlayerPauseCommandKind.reorderPartyMember);
    expect(commands.single.partyTargetId, 'pokemon.first');
    expect(commands.single.secondPartyTargetId, 'pokemon.third');
    expect(_row(tester, 'first').focusNode!.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swap is absent when the runtime does not authorize it',
      (tester) async {
    await _pump(tester, [_member('first'), _member('second')],
        onCommand: (_) {});
    expect(find.byKey(const ValueKey('party-swap')), findsNothing);
    expect(find.byType(LongPressDraggable<String>), findsNothing);
  });

  testWidgets('compact large text keeps placement instructions scrollable',
      (tester) async {
    final navigation = RuntimePlayerPartyNavigation();
    addTearDown(navigation.dispose);
    final commands = <RuntimePlayerPauseCommand>[];
    await _pump(tester, [_member('first'), _member('second')],
        size: const Size(844, 390),
        scale: 2,
        navigation: navigation,
        canReorder: true,
        onCommand: commands.add);
    await _tap(tester, 'party-swap');
    expect(tester.takeException(), isNull);
    final instruction = find.text('Choisissez la nouvelle position');
    expect(find.ancestor(of: instruction, matching: find.byType(Scrollable)),
        findsOneWidget);
    expect(_row(tester, 'first').focusNode!.hasFocus, isTrue,
        reason: FocusManager.instance.primaryFocus.toString());
    Actions.invoke(
        FocusManager.instance.primaryFocus!.context!,
        const RuntimePlayerLogicalIntent(PlayerInputAction.down,
            source: PlayerInputSource.controller));
    await tester.pumpAndSettle();
    expect(_row(tester, 'second').focusNode!.hasFocus, isTrue,
        reason: FocusManager.instance.primaryFocus.toString());
    expect(find.byKey(const ValueKey('party-member-second')).hitTestable(),
        findsOneWidget,
        reason:
            '${tester.getRect(find.byKey(const ValueKey('party-member-second')))} / ${tester.getRect(find.byKey(const ValueKey('party-compact-scroll')))}');
    expect(navigation.back(), isTrue);
    await tester.pumpAndSettle();
    expect(commands, isEmpty);
    expect(_row(tester, 'first').focusNode!.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
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
          detailFooterBuilder: (context, returnAction) => ListenableBuilder(
            listenable: navigation,
            builder: (context, _) =>
                navigation.buildActions(context, returnAction: returnAction),
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
    String? gender = 'Femelle',
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
    genderLabel: gender,
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
