import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart' show RuntimePlayerMenuEffects;

Widget host(Widget child,
        {MediaQueryData media = const MediaQueryData(),
        ThemeData? theme,
        RuntimePlayerMenuEffects effects = RuntimePlayerMenuEffects.full}) =>
    MaterialApp(
        theme: theme ?? PokeMapPlayerTheme.dark(),
        home: MediaQuery(
            data: media,
            child: PlayerMenuEffectsScope(
                effects: effects, child: Scaffold(body: child))));

void main() {
  testWidgets('layout keeps menu safe and wraps long action at text scale two',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(host(
        PlayerOverworldControlsLayout(
            menuButton:
                PlayerOverworldMenuButton(label: 'Menu', onPressed: () {}),
            actionCapsule: PlayerOverworldActionCapsule(
                label: 'Examiner attentivement cette mystérieuse inscription',
                icon: Icons.search,
                onPressed: () {})),
        media: const MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.only(right: 12, bottom: 34),
            textScaler: TextScaler.linear(2))));
    await tester.pumpAndSettle();
    final menu = tester.getRect(find.byType(PlayerOverworldMenuButton));
    final action = tester.getRect(find.byType(PlayerOverworldActionCapsule));
    expect(menu.right, 362);
    expect(menu.bottom, 794);
    expect(menu.size, const Size(52, 52));
    expect(menu.top - action.bottom, PokeMapPlayerOverworldTheme.actionGap);
    expect(action.left, greaterThanOrEqualTo(16));
    expect(action.height, greaterThan(48));
    final text = tester.widget<Text>(
        find.text('Examiner attentivement cette mystérieuse inscription'));
    expect(text.maxLines, isNull);
    expect(text.overflow, isNot(TextOverflow.ellipsis));
    expect(tester.takeException(), isNull);
  });
  testWidgets('hiding during press removes focus and pending action',
      (tester) async {
    var visible = true;
    var calls = 0;
    late StateSetter update;
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(host(StatefulBuilder(builder: (context, setState) {
      update = setState;
      return Center(
          child: PlayerOverworldActionCapsule(
              label: 'Parler',
              icon: Icons.chat_bubble_outline,
              visible: visible,
              focusNode: focus,
              onPressed: () => calls++));
    })));
    await tester.pumpAndSettle();
    focus.requestFocus();
    await tester.pump();
    final gesture =
        await tester.startGesture(tester.getCenter(find.text('Parler')));
    await tester.pump();
    update(() => visible = false);
    await tester.pump();
    await gesture.up();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(calls, 0);
    expect(find.text('Parler'), findsNothing);
    expect(focus.hasFocus, isFalse);
    expect(tester.binding.transientCallbackCount, 0);
  });
  testWidgets('disabled stays visible and cannot activate', (tester) async {
    var calls = 0;
    await tester.pumpWidget(host(Center(
        child: PlayerOverworldActionCapsule(
            label: 'Entrer',
            icon: Icons.login,
            enabled: false,
            autofocus: true,
            onPressed: () => calls++))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrer'));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(find.text('Entrer'), findsOneWidget);
    expect(calls, 0);
  });
  testWidgets('keyboard activation ignores key repeats and fires once',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(host(Center(
        child: PlayerOverworldMenuButton(
            label: 'Menu', autofocus: true, onPressed: () => calls++))));
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    expect(calls, 1);
  });
  testWidgets('HUD uses authored overworld surface instead of menu surface',
      (tester) async {
    final base = PokeMapPlayerTheme.dark();
    final semantic = base.extension<PokeMapPlayerSemanticTheme>()!.copyWith(
        overworldHudSurface: const Color(0xFF123456),
        menuSurface: const Color(0xFFAA2211));
    late PokeMapPlayerOverworldTheme resolved;
    await tester.pumpWidget(host(Builder(builder: (context) {
      resolved = PokeMapPlayerOverworldTheme.resolve(context);
      return const SizedBox();
    }),
        theme: base.copyWith(extensions: [
          ...base.extensions.values,
          PokeMapPlayerAuthoredSemanticTheme(semantic)
        ])));
    expect(resolved.surface, const Color(0xFF123456));
  });
  testWidgets('opaque effects remove translucency and motion', (tester) async {
    late PokeMapPlayerOverworldTheme resolved;
    await tester.pumpWidget(host(Builder(builder: (context) {
      resolved = PokeMapPlayerOverworldTheme.resolve(context);
      return PlayerOverworldMenuButton(label: 'Menu', onPressed: () {});
    }), effects: RuntimePlayerMenuEffects.opaque));
    expect(resolved.opaque, isTrue);
    expect(resolved.pressDuration, Duration.zero);
    expect(resolved.appearanceDuration, Duration.zero);
    expect(resolved.surfaceDecoration().color!.a, 1);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(tester.binding.transientCallbackCount, 0);
  });
  testWidgets(
      'joystick uses supplied anchor and displacement without taking input',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(Stack(children: [
      Positioned.fill(
          child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => taps++,
              child: const SizedBox())),
      const PlayerOverworldJoystickVisual(
          anchor: Offset(150, 200), displacement: Offset(1, 0), running: true)
    ])));
    await tester.pumpAndSettle();
    final base = tester
        .getRect(find.byKey(const ValueKey('player-overworld-joystick-base')));
    final knob = tester
        .getRect(find.byKey(const ValueKey('player-overworld-joystick-knob')));
    expect(base.center, const Offset(150, 200));
    expect(knob.center.dx, greaterThan(base.center.dx));
    await tester.tapAt(base.center);
    expect(taps, 1);
  });
  testWidgets('synthetic key down cannot activate a control', (tester) async {
    var calls = 0;
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(host(Center(
        child: PlayerOverworldMenuButton(
            label: 'Menu',
            focusNode: focusNode,
            autofocus: true,
            onPressed: () => calls++))));
    await tester.pumpAndSettle();
    final focus = tester
        .widgetList<Focus>(find.byType(Focus))
        .firstWhere((widget) => widget.focusNode == focusNode);
    focus.onKeyEvent!(
        focusNode,
        const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.enter,
            logicalKey: LogicalKeyboardKey.enter,
            timeStamp: Duration.zero,
            synthesized: true));
    expect(calls, 0);
  });
  testWidgets('long gamepad fallback and label remain readable at scale two',
      (tester) async {
    await tester.pumpWidget(host(
        Center(
            child: SizedBox(
                width: 320,
                child: PlayerOverworldActionCapsule(
                    label: 'Examiner cette mystérieuse inscription',
                    icon: Icons.search,
                    glyph: 'Bouton ouest',
                    onPressed: () {}))),
        media: const MediaQueryData(textScaler: TextScaler.linear(2))));
    await tester.pumpAndSettle();
    expect(find.text('Bouton ouest'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'surface palette overrides HUD author values and honors typography',
      (tester) async {
    final source = PokeMapPlayerTheme.dark();
    final semantic = source
        .extension<PokeMapPlayerSemanticTheme>()!
        .copyWith(overworldHudSurface: const Color(0xFF112233));
    final theme = source.copyWith(extensions: [
      ...source.extensions.values,
      PokeMapPlayerAuthoredSemanticTheme(semantic),
      const PokeMapPlayerTypography(bodyFamily: 'Author Body'),
      const PokeMapPlayerSurfacePaletteTheme(
          ProjectPresentationSurfacePalettesProfile(
              pauseMenu: ProjectSurfacePaletteProfile(
                  surface: '#314159', text: '#FFF2D1', accent: '#ABCDFF'))),
    ]);
    late PokeMapPlayerOverworldTheme resolved;
    await tester.pumpWidget(host(
        PlayerSurfacePaletteScope(
            role: ProjectPresentationSurfaceRole.pauseMenu,
            child: Builder(builder: (context) {
              resolved = context.playerOverworldTheme;
              return const SizedBox();
            })),
        theme: theme));
    expect(resolved.surface, const Color(0xFF314159));
    expect(resolved.text, const Color(0xFFFFF2D1));
    expect(resolved.accent, const Color(0xFFABCDFF));
    expect(resolved.label.fontFamily, 'Author Body');
  });
  for (final media in [
    const MediaQueryData(disableAnimations: true),
    const MediaQueryData(accessibleNavigation: true)
  ]) {
    testWidgets('media preferences stop appearance and press animations $media',
        (tester) async {
      await tester.pumpWidget(host(
          Center(
              child: PlayerOverworldActionCapsule(
                  label: 'Lire',
                  icon: Icons.search,
                  pressed: true,
                  onPressed: () {})),
          media: media));
      final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(scale.duration, Duration.zero);
      expect(scale.scale, .97);
      expect(tester.binding.transientCallbackCount, 0);
    });
  }
  testWidgets('wide layout uses 24 pixels plus safe areas', (tester) async {
    await tester.pumpWidget(host(
        PlayerOverworldControlsLayout(
            menuButton:
                PlayerOverworldMenuButton(label: 'Menu', onPressed: () {})),
        media: const MediaQueryData(
            padding: EdgeInsets.only(right: 32, bottom: 20))));
    await tester.pumpAndSettle();
    final menu = tester.getRect(find.byType(PlayerOverworldMenuButton));
    expect(menu.right, 800 - 32 - 24);
    expect(menu.bottom, 600 - 20 - 24);
  });
  testWidgets('glyph is supplied only by parent and high contrast stays opaque',
      (tester) async {
    late PokeMapPlayerOverworldTheme resolved;
    await tester.pumpWidget(host(Builder(builder: (context) {
      resolved = context.playerOverworldTheme;
      return Center(
          child: PlayerOverworldActionCapsule(
              label: 'Lire',
              icon: Icons.search,
              glyph: 'Y',
              focused: true,
              onPressed: () {}));
    }), media: const MediaQueryData(highContrast: true)));
    await tester.pumpAndSettle();
    expect(find.text('Y'), findsOneWidget);
    expect(find.text('A'), findsNothing);
    expect(find.text('E'), findsNothing);
    expect(resolved.opaque, isTrue);
    expect(resolved.surfaceDecoration(focused: true).border!.top.width, 3);
    expect(resolved.surfaceDecoration().color!.a, 1);
  });
  testWidgets('landscape large text keeps action readable above anchored menu',
      (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(host(
        PlayerOverworldControlsLayout(
            menuButton:
                PlayerOverworldMenuButton(label: 'Menu', onPressed: () {}),
            actionCapsule: PlayerOverworldActionCapsule(
                label: 'Examiner attentivement cette mystérieuse inscription',
                glyph: 'Bouton ouest',
                icon: Icons.search,
                onPressed: () {})),
        media: const MediaQueryData(
            size: Size(844, 390),
            padding: EdgeInsets.fromLTRB(24, 44, 24, 34),
            textScaler: TextScaler.linear(2))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final menu = tester.getRect(find.byType(PlayerOverworldMenuButton));
    final action = tester.getRect(find.byType(PlayerOverworldActionCapsule));
    expect(menu.right, 844 - 24 - 24);
    expect(menu.bottom, 390 - 34 - 24);
    expect(action.top, greaterThanOrEqualTo(44 + 24));
    expect(menu.top - action.bottom, PokeMapPlayerOverworldTheme.actionGap);
  });
  testWidgets('narrow action places long fallback below full width label',
      (tester) async {
    await tester.pumpWidget(host(
        Center(
            child: SizedBox(
                width: 320,
                child: PlayerOverworldActionCapsule(
                    label: 'Lire le panneau',
                    icon: Icons.search,
                    glyph: 'Bouton ouest',
                    onPressed: () {}))),
        media: const MediaQueryData(textScaler: TextScaler.linear(2))));
    await tester.pumpAndSettle();
    final label = tester.getRect(find.text('Lire le panneau'));
    final glyph = tester.getRect(find.text('Bouton ouest'));
    expect(glyph.top, greaterThanOrEqualTo(label.bottom));
    expect(label.width, greaterThan(220));
    expect(tester.takeException(), isNull);
  });
}
