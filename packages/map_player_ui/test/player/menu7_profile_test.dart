import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/player/runtime_player_profile.dart';
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

  testWidgets('reference layout reserves identity and progression columns',
      (tester) async {
    await _pump(tester, _profile());
    final body = tester
        .getRect(find.byKey(const ValueKey('runtime-player-detail-profile')));
    final identity =
        tester.getRect(find.byKey(const ValueKey('profile-identity')));
    final progression =
        tester.getRect(find.byKey(const ValueKey('profile-progression')));
    expect(body.size, const Size(1296, 644));
    expect(identity.width, 416);
    expect(progression.width, 856);
    expect(progression.left - identity.right, 24);
    expect(tester.getSize(find.byKey(const ValueKey('profile-portrait'))),
        const Size(256, 288));
    expect(tester.getSize(find.byKey(const ValueKey('profile-badge-boulder'))),
        const Size(80, 80));
    expect(
        tester
            .getSize(find.byKey(const ValueKey('profile-badge-image-boulder'))),
        const Size(64, 64));
    final firstBadge =
        tester.getRect(find.byKey(const ValueKey('profile-badge-boulder')));
    final secondBadge =
        tester.getRect(find.byKey(const ValueKey('profile-badge-cascade')));
    expect(secondBadge.left - firstBadge.right, 16);
    expect(tester.takeException(), isNull);
  });

  testWidgets('statistics use public session values and localized numbers',
      (tester) async {
    await _pump(tester, _profile());
    expect(find.text('Yoahn'), findsOneWidget);
    expect(find.text('Village d’Hanazuki'), findsOneWidget);
    expect(find.text('27:09'), findsOneWidget);
    final context = tester.element(find.byType(RuntimePlayerProfile));
    expect(Localizations.localeOf(context).languageCode, 'fr');
    expect(find.text('1\u202f234\u202f567 Pokédollars'), findsOneWidget);
    expect(find.text('132'), findsOneWidget);
    expect(find.text('71'), findsOneWidget);
    expect(find.text('151'), findsOneWidget);
    expect(find.text('2 / 8'), findsOneWidget);
    expect(find.textContaining('map_hanazuki'), findsNothing);
    expect(find.textContaining('avatar_yoahn'), findsNothing);
    expect(find.textContaining('%'), findsNothing);
    expect(find.textContaining('Compte'), findsNothing);
  });

  testWidgets('partial profile keeps a safe silhouette and no invented fields',
      (tester) async {
    await _pump(
        tester,
        RuntimePlayerProfileSnapshot(
            playerName: 'Aline', currentMapId: 'private_map_id', money: 0));
    expect(find.byKey(const ValueKey('profile-portrait-fallback')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('profile-location')), findsNothing);
    expect(find.byKey(const ValueKey('profile-stat-playtime')), findsNothing);
    expect(
        find.byKey(const ValueKey('profile-stat-pokedex-seen')), findsNothing);
    expect(find.byKey(const ValueKey('profile-earned-badges')), findsNothing);
    expect(find.text('Badges obtenus'), findsNothing);
    expect(find.text('private_map_id'), findsNothing);
    expect(find.textContaining(' / '), findsNothing);
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'badges are labelled read only images without hidden placeholders',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, _profile());
    final badge = tester
        .getSemantics(find.byKey(const ValueKey('profile-badge-boulder')));
    expect(badge.label, 'Badge Roche');
    expect(badge.flagsCollection.isButton, isFalse);
    expect(badge.getSemanticsData().hasAction(ui.SemanticsAction.tap), isFalse);
    expect(find.byKey(const ValueKey('profile-badge-unearned')), findsNothing);
    expect(find.text('boulder'), findsNothing);
    expect(find.text('cascade'), findsNothing);
    semantics.dispose();
  });

  testWidgets('long names and large playtime preserve public values',
      (tester) async {
    const name = 'Alexandrine-Éléonore de la Grande Vallée';
    await _pump(tester, _profile(name: name, seconds: 9999 * 3600 + 59 * 60));
    expect(find.text(name), findsOneWidget);
    expect(find.text('9999:59'), findsOneWidget);
    final title =
        tester.widget<Text>(find.byKey(const ValueKey('profile-name')));
    expect(title.maxLines, 2);
    expect(title.style?.fontSize, 26);
    expect(title.style?.height, 32 / 26);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(1440, 900),
    const Size(844, 390),
    const Size(390, 844)
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('profile remains readable at $size text $scale',
          (tester) async {
        await _pump(tester, _profile(), size: size, scale: scale);
        final footer = find.byKey(const ValueKey('pause-frame-return-surface'));
        final footerRect = tester.getRect(footer);
        await tester.drag(find.byKey(const ValueKey('profile-body-scroll')),
            const Offset(0, -1600));
        await tester.pumpAndSettle();
        expect(tester.getRect(footer), footerRect);
        expect(footer.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (size.width < 1024 || scale == 2) {
          expect(tester.getSize(find.byKey(const ValueKey('profile-portrait'))),
              const Size(144, 144));
          final identity =
              tester.getRect(find.byKey(const ValueKey('profile-identity')));
          final progression =
              tester.getRect(find.byKey(const ValueKey('profile-progression')));
          expect(progression.top - identity.bottom, 24);
        }
      });
    }
  }

  testWidgets('keyboard and logical actions scroll before returning to shell',
      (tester) async {
    var backCount = 0;
    await _pump(tester, _profile(),
        size: const Size(390, 844), onBack: () => backCount++);
    final scrollable = tester.state<ScrollableState>(find.descendant(
        of: find.byKey(const ValueKey('profile-body-scroll')),
        matching: find.byType(Scrollable)));
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'Player profile');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, greaterThan(0));
    final beforeLogical = scrollable.position.pixels;
    Actions.invoke(
        FocusManager.instance.primaryFocus!.context!,
        const RuntimePlayerLogicalIntent(PlayerInputAction.down,
            source: PlayerInputSource.controller));
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, greaterThan(beforeLogical));
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, scrollable.position.maxScrollExtent);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(
        FocusManager.instance.primaryFocus?.debugLabel, 'Pause detail return');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(backCount, 1);
  });

  testWidgets('save replacement removes old portrait and badge identities',
      (tester) async {
    await _pump(
        tester,
        _profile(
            portrait: '/missing/old-player.png',
            badgeIcon: '/missing/old-badge.png'));
    final oldImage = tester.widget<Image>(find.byKey(const ValueKey(
        'profile-portrait-source-avatar_yoahn:/missing/old-player.png')));
    expect((oldImage.image as FileImage).file.path, '/missing/old-player.png');
    await _pump(
        tester,
        RuntimePlayerProfileSnapshot(
          playerName: 'Aline',
          currentMapId: 'new_map',
          avatarCharacterId: 'avatar_aline',
          portraitFilePath: '/missing/new-player.png',
          money: 42,
          badgeIds: const ['thunder'],
          badges: const [
            RuntimePlayerProfileBadgeSnapshot(
                id: 'thunder',
                label: 'Badge Foudre',
                iconFilePath: '/missing/new-badge.png')
          ],
        ));
    expect(find.text('Yoahn'), findsNothing);
    expect(find.byKey(const ValueKey('profile-badge-boulder')), findsNothing);
    expect(find.byKey(const ValueKey('profile-badge-cascade')), findsNothing);
    expect(
        find.byKey(const ValueKey(
            'profile-badge-source-boulder:/missing/old-badge.png')),
        findsNothing);
    expect(
        find.byKey(const ValueKey(
            'profile-badge-source-thunder:/missing/new-badge.png')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('profile-badge-thunder')), findsOneWidget);
    expect(
        find.byKey(const ValueKey(
            'profile-portrait-source-avatar_yoahn:/missing/old-player.png')),
        findsNothing);
    final newImage = tester.widget<Image>(find.byKey(const ValueKey(
        'profile-portrait-source-avatar_aline:/missing/new-player.png')));
    expect((newImage.image as FileImage).file.path, '/missing/new-player.png');
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile capture fixtures', (tester) async {
    const directory = String.fromEnvironment('MENU7_PROFILE_CAPTURE_DIR');
    await tester.runAsync(() => Directory(directory).create(recursive: true));
    const portrait = String.fromEnvironment('MENU7_PROFILE_PORTRAIT_PATH');
    if (portrait.isNotEmpty) {
      await _pump(tester, _profile());
      await tester.runAsync(() => precacheImage(FileImage(File(portrait)),
          tester.element(find.byType(RuntimePlayerProfile))));
    }
    for (final size in [
      const Size(1440, 900),
      const Size(844, 390),
      const Size(390, 844)
    ]) {
      const badgeIcon = String.fromEnvironment('MENU7_PROFILE_BADGE_PATH');
      await _pump(
          tester,
          _profile(
              portrait: portrait.isEmpty ? null : portrait,
              badgeIcon: badgeIcon.isEmpty ? null : badgeIcon),
          size: size);
      if (portrait.isNotEmpty) {
        expect(find.byKey(const ValueKey('profile-portrait-fallback')),
            findsNothing);
      }
      await _capture(tester, directory, size);
      expect(tester.takeException(), isNull);
    }
  }, skip: const String.fromEnvironment('MENU7_PROFILE_CAPTURE_DIR').isEmpty);
}

RuntimePlayerProfileSnapshot _profile(
        {String name = 'Yoahn',
        int? seconds,
        String? portrait,
        String? badgeIcon}) =>
    RuntimePlayerProfileSnapshot(
      playerName: name,
      currentMapId: 'map_hanazuki',
      locationName: 'Village d’Hanazuki',
      avatarCharacterId: 'avatar_yoahn',
      portraitFilePath: portrait,
      money: 1234567,
      currencyLabel: 'Pokédollars',
      playtimeSeconds: seconds ?? 27 * 3600 + 9 * 60,
      badgeIds: const ['boulder', 'cascade'],
      badgeTotal: 8,
      badges: [
        RuntimePlayerProfileBadgeSnapshot(
            id: 'boulder', label: 'Badge Roche', iconFilePath: badgeIcon),
        RuntimePlayerProfileBadgeSnapshot(
            id: 'cascade', label: 'Badge Cascade', iconFilePath: badgeIcon),
      ],
      pokedex: const RuntimePlayerPokedexProgressSnapshot(
          seen: 132, caught: 71, total: 151),
    );

Future<void> _pump(WidgetTester tester, RuntimePlayerProfileSnapshot profile,
    {Size size = const Size(1440, 900),
    double scale = 1,
    VoidCallback? onBack}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
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
        child: Scaffold(
            body: RepaintBoundary(
                key: const ValueKey('profile-capture'),
                child: RuntimePlayerPauseShell(
                    gameTitle: 'Le train de 17h42',
                    pauseSection: RuntimePlayerPauseSection.profile,
                    actions: {
                      for (final action in PlayerPauseAction.values)
                        action: PlayerActionAvailability.enabled,
                    },
                    onSelected: (_) {},
                    onBackToRoot: onBack ?? () {},
                    presentation: const PlayerPausePresentation(
                        style: ProjectPauseMenuStyle.nightIllustrated),
                    detailOwnsScroll: true,
                    detail: RuntimePlayerProfile(profile: profile))))),
  ));
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, String directory, Size size) async {
  await tester.pump(const Duration(milliseconds: 300));
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('profile-capture')));
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(
            '$directory/menu7-profile-${size.width.toInt()}x${size.height.toInt()}.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
