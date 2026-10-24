import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/player/player_pokemon_image.dart';
import 'package:map_player_ui/src/player/runtime_player_party.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  setUpAll(() async {
    await (FontLoader(
      'packages/map_player_ui/PokeMapSplashDMSans',
    )..addFont(rootBundle.load('assets/fonts/DMSans-Variable.ttf'))).load();
  });

  for (final size in [
    const Size(1440, 900),
    const Size(1024, 768),
    const Size(768, 1024),
    const Size(844, 390),
    const Size(390, 844),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('party opens the real tabbed sheet at $size text $scale', (
        tester,
      ) async {
        final navigation = RuntimePlayerPartyNavigation();
        addTearDown(navigation.dispose);
        await _pump(
          tester,
          List.generate(6, (index) => _member('member$index')),
          navigation: navigation,
          size: size,
          scale: scale,
        );
        final surface = find.byKey(
          const ValueKey('runtime-player-detail-party'),
        );
        expect(
          find.descendant(of: surface, matching: find.byType(Scrollable)),
          findsNothing,
        );
        final first = tester.getRect(
          find.byKey(const ValueKey('party-member-member0')),
        );
        final second = tester.getRect(
          find.byKey(const ValueKey('party-member-member1')),
        );
        if (size.width >= 440) {
          expect(second.top, closeTo(first.top, .1));
          expect(second.left, greaterThan(first.right));
        } else {
          expect(second.top, greaterThan(first.bottom));
        }
        await _tap(tester, 'party-member-member1');
        expect(_detail(tester).summary.individualId, 'member1');
        expect(find.byType(Dialog), findsNothing);
        for (final tab in ['summary', 'moves', 'stats', 'actions']) {
          await _tap(tester, 'pokemon-summary-tab-$tab');
          expect(find.byType(Scrollable), findsNothing);
        }
        final footer = find.byKey(const ValueKey('pause-frame-return-surface'));
        expect(footer.hitTestable(), findsOneWidget);
        expect(
          find.byKey(
            const ValueKey('runtime-player-party-summary-pokemon.member1'),
          ),
          findsNothing,
        );
        await _tap(tester, 'pause-frame-return-surface');
        expect(find.byType(PlayerPokemonSummarySheet), findsNothing);
        expect(
          find.byKey(const ValueKey('party-member-member1')).hitTestable(),
          findsOneWidget,
        );
        expect(_row(tester, 'member1').focusNode?.hasFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(_detail(tester).summary.individualId, 'member1');
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final count in [0, 1, 3, 6]) {
    testWidgets('party shows exactly $count real identities', (tester) async {
      await _pump(
        tester,
        List.generate(count, (index) => _member('member$index')),
      );
      final members = find.byWidgetPredicate(
        (widget) =>
            widget is PlayerMenuSelectableRow &&
            widget.id.startsWith('party-member-'),
        skipOffstage: false,
      );
      expect(members, findsNWidgets(count));
      expect(find.byKey(const ValueKey('party-empty-slot-5')), findsNothing);
      if (count == 0) {
        expect(find.text('Votre équipe est vide'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'snapshot refresh keeps the selected identity and native fields',
    (tester) async {
      final first = _member('first');
      await _pump(tester, [first, _member('second', hp: 19), _member('third')]);
      await _tap(tester, 'party-member-second');
      expect(_detail(tester).summary.currentHp, 19);
      final changed = _member('second', hp: 0, status: 'Paralysie');
      await _pump(tester, [changed, first, _member('third')]);
      expect(_detail(tester).summary, same(changed.pokemonSummary));
      expect(_detail(tester).summary.individualId, 'second');
      expect(_detail(tester).summary.currentHp, 0);
      expect(_detail(tester).summary.experience, 2468);
      expect(_detail(tester).summary.natureLabel, 'Modeste');
      final image = tester
          .widgetList<PlayerPokemonImage>(find.byType(PlayerPokemonImage))
          .single;
      expect(image.summary, same(changed.pokemonSummary));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(_row(tester, 'second').selected, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('disappearing selection chooses the nearest surviving identity', (
    tester,
  ) async {
    await _pump(tester, [
      _member('first'),
      _member('second'),
      _member('third'),
    ]);
    await _tap(tester, 'party-member-second');
    await _pump(tester, [_member('first'), _member('third')]);
    expect(_detail(tester).summary.individualId, 'third');
    await _pump(tester, []);
    expect(find.text('Votre équipe est vide'), findsOneWidget);
    expect(find.byType(PlayerPokemonSummarySheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'swap cancel emits nothing and reorder follows the source identity',
    (tester) async {
      final commands = <RuntimePlayerPauseCommand>[];
      final entries = [_member('first'), _member('second'), _member('third')];
      await _pump(tester, entries, onCommand: commands.add, canReorder: true);
      await _focus(tester, 'second');
      await _tap(tester, 'party-swap');
      await _tap(tester, 'party-swap-cancel');
      expect(commands, isEmpty);
      expect(_row(tester, 'second').selected, isTrue);
      await _tap(tester, 'party-swap');
      await _tap(tester, 'party-member-third');
      expect(commands, hasLength(1));
      expect(
        commands.single.kind,
        RuntimePlayerPauseCommandKind.reorderPartyMember,
      );
      expect(commands.single.partyTargetId, 'pokemon.second');
      expect(commands.single.secondPartyTargetId, 'pokemon.third');
      await _pump(
        tester,
        [entries[0], entries[2], entries[1]],
        onCommand: commands.add,
        canReorder: true,
      );
      expect(_row(tester, 'second').selected, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('rejected reorder keeps the source and accepts a later retry', (
    tester,
  ) async {
    const reason = 'Cette destination n’est plus disponible.';
    final pending = Completer<void>();
    final commands = <RuntimePlayerPauseCommand>[];
    final entries = [_member('first'), _member('second'), _member('third')];
    await _pump(
      tester,
      entries,
      canReorder: true,
      onCommand: (command) {
        commands.add(command);
        return pending.future;
      },
    );
    await _tap(tester, 'party-swap');
    await _tap(tester, 'party-member-third');
    await _tap(tester, 'party-member-second');
    expect(commands, hasLength(1));
    expect(_row(tester, 'first').busy, isTrue);
    pending.completeError(const RuntimePlayerPartyCommandFailure(reason));
    await tester.pumpAndSettle();
    expect(find.text(reason), findsOneWidget);
    expect(find.byKey(const ValueKey('party-swap-source')), findsOneWidget);
    await _pump(tester, entries, canReorder: true, onCommand: commands.add);
    await _tap(tester, 'party-member-second');
    expect(commands, hasLength(2));
    expect(commands.last.partyTargetId, 'pokemon.first');
    expect(commands.last.secondPartyTargetId, 'pokemon.second');
    expect(find.text(reason), findsNothing);
  });

  testWidgets('drag reorder uses the same canonical command', (tester) async {
    final commands = <RuntimePlayerPauseCommand>[];
    await _pump(
      tester,
      [_member('first'), _member('second'), _member('third')],
      canReorder: true,
      onCommand: commands.add,
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('party-member-first'))),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    await gesture.moveTo(
      tester.getCenter(find.byKey(const ValueKey('party-member-third'))),
    );
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(
      commands.single.kind,
      RuntimePlayerPauseCommandKind.reorderPartyMember,
    );
    expect(commands.single.partyTargetId, 'pokemon.first');
    expect(commands.single.secondPartyTargetId, 'pokemon.third');
  });

  testWidgets('reorder remains unavailable without runtime authorization', (
    tester,
  ) async {
    await _pump(tester, [
      _member('first'),
      _member('second'),
    ], onCommand: (_) {});
    await _tap(tester, 'party-member-first');
    await _tap(tester, 'pokemon-summary-tab-actions');
    expect(find.byKey(const ValueKey('party-swap')), findsNothing);
    expect(find.byType(LongPressDraggable<String>), findsNothing);
  });

  for (final remove in [false, true]) {
    testWidgets(
      'held ${remove ? 'removal' : 'replacement'} targets the chosen member',
      (tester) async {
        final commands = <RuntimePlayerPauseCommand>[];
        await _pump(tester, [
          _member('first'),
          _member('second', held: true),
        ], onCommand: commands.add);
        await _tap(tester, 'runtime-player-held-manage-pokemon.second');
        await _tap(
          tester,
          remove
              ? 'runtime-player-held-take-pokemon.second'
              : 'runtime-player-held-option-pokemon.second-leftovers',
        );
        expect(commands.single.partyTargetId, 'pokemon.second');
        expect(
          commands.single.kind,
          remove
              ? RuntimePlayerPauseCommandKind.unequipHeldItem
              : RuntimePlayerPauseCommandKind.equipHeldItem,
        );
        if (!remove) expect(commands.single.itemTargetId, 'leftovers');
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'held cancellation has no mutation and preserves the selected sheet',
    (tester) async {
      final commands = <RuntimePlayerPauseCommand>[];
      await _pump(tester, [
        _member('first', held: true),
      ], onCommand: commands.add);
      await _tap(tester, 'runtime-player-held-manage-pokemon.first');
      await _tap(tester, 'runtime-player-held-close');
      expect(commands, isEmpty);
      expect(_detail(tester).summary.individualId, 'first');
    },
  );

  testWidgets(
    'held pending writes block duplicate changes and safe failures recover',
    (tester) async {
      const reason = 'Cet objet n’est plus présent dans le sac.';
      final pending = Completer<void>();
      final commands = <RuntimePlayerPauseCommand>[];
      await _pump(
        tester,
        [_member('first', held: true), _member('second')],
        canReorder: true,
        onCommand: (command) {
          commands.add(command);
          return pending.future;
        },
      );
      await _tap(tester, 'runtime-player-held-manage-pokemon.first');
      await _tap(tester, 'runtime-player-held-option-pokemon.first-leftovers');
      expect(commands, hasLength(1));
      expect(
        tester
            .widget<PlayerActionButton>(
              find.byKey(
                const ValueKey('runtime-player-held-manage-pokemon.first'),
              ),
            )
            .onPressed,
        isNull,
      );
      pending.completeError(const RuntimePlayerPartyCommandFailure(reason));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text(reason), findsOneWidget);
      expect(
        find.textContaining('RuntimePlayerPartyCommandFailure'),
        findsNothing,
      );
      expect(_row(tester, 'first').busy, isFalse);
    },
  );

  testWidgets('raw held failures never expose implementation details', (
    tester,
  ) async {
    await _pump(
      tester,
      [_member('first', held: true)],
      onCommand: (_) async {
        throw StateError('private transaction internals');
      },
    );
    await _tap(tester, 'runtime-player-held-manage-pokemon.first');
    await _tap(tester, 'runtime-player-held-take-pokemon.first');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.textContaining('private transaction internals'), findsNothing);
    expect(find.byKey(const ValueKey('party-command-message')), findsOneWidget);
  });

  testWidgets('a late command completion after disposal stays harmless', (
    tester,
  ) async {
    final pending = Completer<void>();
    await _pump(tester, [
      _member('first', held: true),
    ], onCommand: (_) => pending.future);
    await _tap(tester, 'runtime-player-held-manage-pokemon.first');
    await _tap(tester, 'runtime-player-held-option-pokemon.first-leftovers');
    await tester.pumpWidget(const SizedBox.shrink());
    pending.completeError(StateError('stale'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing images keep the selected native identity', (
    tester,
  ) async {
    await _pump(tester, [_member('first'), _member('second')]);
    await _focus(tester, 'second');
    await _focus(tester, 'first');
    await _tap(tester, 'party-member-second');
    final illustration = tester
        .widgetList<PlayerPokemonImage>(find.byType(PlayerPokemonImage))
        .single;
    expect(illustration.summary.targetId, 'pokemon.second');
    expect(
      find.byKey(const ValueKey('pokemon-image-missing-pokemon.second')),
      findsOneWidget,
    );
    expect(_detail(tester).summary.nickname, 'Compagnon second');
  });

  testWidgets('late image completion cannot replace the selected member', (
    tester,
  ) async {
    const path = '/virtual-menu5/late-first.png';
    final pending = Completer<ImageInfo>();
    final provider = FileImage(File(path));
    final cache = PaintingBinding.instance.imageCache;
    cache.putIfAbsent(
      provider,
      () => OneFrameImageStreamCompleter(pending.future),
    );
    addTearDown(() => cache.evict(provider));
    const media = RuntimePokemonSummaryMediaSnapshot(
      thumbnail: RuntimePokemonLocalImageSnapshot(
        absoluteFilePath: path,
        sampling: ProjectMenuImageSampling.pixelArt,
      ),
      illustration: RuntimePokemonLocalImageSnapshot(
        absoluteFilePath: path,
        sampling: ProjectMenuImageSampling.pixelArt,
      ),
    );
    await _pump(tester, [_member('first', media: media), _member('second')]);
    await _tap(tester, 'party-member-second');
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawColor(const Color(0xFFFF0000), BlendMode.src);
    final picture = recorder.endRecording();
    final image = picture.toImageSync(1, 1);
    picture.dispose();
    pending.complete(ImageInfo(image: image));
    await tester.pumpAndSettle();
    final sheet = find.byType(PlayerPokemonSummarySheet);
    expect(_detail(tester).summary.individualId, 'second');
    expect(
      find.descendant(of: sheet, matching: find.byType(RawImage)),
      findsNothing,
    );
    expect(
      find.descendant(
        of: sheet,
        matching: find.byKey(
          const ValueKey('pokemon-image-missing-pokemon.second'),
        ),
      ),
      findsOneWidget,
    );
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
              action: PlayerActionAvailability.enabled,
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
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
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
    ),
  );
  await tester.pumpAndSettle();
}

PlayerMenuSelectableRow _row(WidgetTester tester, String id) => tester
    .widget<PlayerMenuSelectableRow>(find.byKey(ValueKey('party-member-$id')));

PlayerPokemonSummarySheet _detail(WidgetTester tester) => tester
    .widget<PlayerPokemonSummarySheet>(find.byType(PlayerPokemonSummarySheet));

Future<void> _focus(WidgetTester tester, String id) async {
  _row(tester, id).focusNode!.requestFocus();
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String key) async {
  if ((key == 'party-swap' || key.startsWith('runtime-player-held-manage-')) &&
      find.byKey(ValueKey(key)).evaluate().isEmpty) {
    if (find.byType(PlayerPokemonSummarySheet).evaluate().isEmpty) {
      final id = key.startsWith('runtime-player-held-manage-pokemon.')
          ? key.substring('runtime-player-held-manage-pokemon.'.length)
          : tester
                .widgetList<PlayerMenuSelectableRow>(
                  find.byWidgetPredicate(
                    (widget) =>
                        widget is PlayerMenuSelectableRow &&
                        widget.id.startsWith('party-member-') &&
                        widget.selected,
                  ),
                )
                .first
                .id
                .substring('party-member-'.length);
      await _tap(tester, 'party-member-$id');
    }
    await _tap(tester, 'pokemon-summary-tab-actions');
  }
  final finder = find.byKey(ValueKey(key));
  if (key.startsWith('party-member-') &&
      finder.evaluate().isEmpty &&
      find.byType(PlayerPokemonSummarySheet).evaluate().isNotEmpty) {
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
  }
  for (var page = 0; finder.evaluate().isEmpty && page < 20; page++) {
    final next = find.byKey(const ValueKey('player-page-next'));
    if (next.evaluate().isEmpty) break;
    final enabled = next
        .evaluate()
        .where((element) => (element.widget as IconButton).onPressed != null)
        .firstOrNull;
    if (enabled == null) break;
    await tester.tap(
      find.byElementPredicate((element) => identical(element, enabled)),
    );
    await tester.pumpAndSettle();
  }
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

RuntimePlayerDetailEntrySnapshot _member(
  String id, {
  int hp = 30,
  String? gender = 'Femelle',
  String? status,
  bool held = false,
  bool longName = false,
  String? nickname,
  int moveCount = 2,
  RuntimePokemonSummaryMediaSnapshot media =
      const RuntimePokemonSummaryMediaSnapshot(),
}) {
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
      speed: 19,
    ),
    moves: const [
      RuntimePokemonMoveSummarySnapshot(
        moveId: 'vine-whip',
        label: 'Fouet Lianes',
        typeId: 'grass',
        currentPp: 7,
        maxPp: 25,
      ),
      RuntimePokemonMoveSummarySnapshot(
        moveId: 'growl',
        label: 'Rugissement',
        typeId: 'normal',
        currentPp: 18,
        maxPp: 40,
      ),
      RuntimePokemonMoveSummarySnapshot(
        moveId: 'quick-attack',
        label: 'Vive-Attaque',
        typeId: 'normal',
        currentPp: 12,
        maxPp: 30,
      ),
      RuntimePokemonMoveSummarySnapshot(
        moveId: 'tackle',
        label: 'Charge',
        typeId: 'normal',
        currentPp: 20,
        maxPp: 35,
      ),
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
                itemTargetId: 'leftovers',
                label: 'Restes',
              ),
            ],
          )
        : null,
  );
}
