import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_core/map_core.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('packages/map_player_ui/PokeMapSplashDMSans')
          ..addFont(rootBundle.load('assets/fonts/DMSans-Variable.ttf')))
        .load();
  });
  Widget host(Widget child, {bool opaque = false}) => MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home:
            PlayerMenuThemeScope(opaque: opaque, child: Scaffold(body: child)),
      );

  testWidgets(
      'focus is independent from selection and does not change geometry',
      (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    var activations = 0;
    await tester.pumpWidget(host(Column(children: [
      PlayerMenuSelectableRow(
          id: 'selected', label: 'Selected', selected: true, onPressed: () {}),
      PlayerMenuSelectableRow(
          id: 'focused',
          label: 'Focused',
          focusNode: node,
          onPressed: () => activations++),
    ])));
    final before = tester.getSize(find.byType(PlayerMenuSelectableRow).last);
    node.requestFocus();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('focused-focus-marker')), findsOneWidget);
    expect(find.byKey(const ValueKey('selected-focus-marker')), findsNothing);
    expect(tester.getSize(find.byType(PlayerMenuSelectableRow).last), before);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(activations, 1);
    final selected = tester
        .getSemantics(find.byType(PlayerMenuSelectableRow).first)
        .getSemanticsData();
    final focused = tester
        .getSemantics(find.byType(PlayerMenuSelectableRow).last)
        .getSemanticsData();
    expect(selected.flagsCollection.isSelected, Tristate.isTrue);
    expect(selected.flagsCollection.isFocused, Tristate.isFalse);
    expect(focused.flagsCollection.isSelected, Tristate.isFalse);
    expect(focused.flagsCollection.isFocused, Tristate.isTrue);
  });

  testWidgets(
      'disabled reason is visible and blocks pointer keyboard and semantics activation',
      (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    var activations = 0;
    await tester.pumpWidget(host(PlayerMenuSelectableRow(
        id: 'blocked',
        label: 'Sauvegarder',
        disabledReason: 'Indisponible pendant un combat',
        focusNode: node,
        onPressed: () => activations++)));
    expect(find.text('Indisponible pendant un combat'), findsOneWidget);
    await tester.tap(find.text('Sauvegarder'));
    node.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(activations, 0);
    final data = tester
        .getSemantics(find.byType(PlayerMenuSelectableRow))
        .getSemanticsData();
    expect(data.hint, 'Indisponible pendant un combat');
    expect(data.flagsCollection.isEnabled, Tristate.isFalse);
    expect(data.hasAction(SemanticsAction.tap), isFalse);
  });

  testWidgets('busy row prevents duplicate execution without an animation loop',
      (tester) async {
    var activations = 0;
    await tester.pumpWidget(host(PlayerMenuSelectableRow(
        id: 'busy',
        label: 'Sauvegarde',
        busy: true,
        onPressed: () => activations++)));
    await tester.tap(find.text('Sauvegarde'));
    await tester.pumpAndSettle();
    expect(activations, 0);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
  });

  testWidgets(
      'row semantic node stays stable across hover selection and rebuild',
      (tester) async {
    await tester.pumpWidget(host(PlayerMenuSelectableRow(
        id: 'stable', label: 'Équipe', onPressed: () {})));
    final first = tester.getSemantics(find.byType(PlayerMenuSelectableRow)).id;
    await tester.pumpWidget(host(PlayerMenuSelectableRow(
        id: 'stable',
        label: 'Équipe',
        selected: true,
        hovered: true,
        onPressed: () {})));
    await tester.pumpAndSettle();
    expect(tester.getSemantics(find.byType(PlayerMenuSelectableRow)).id, first);
  });

  testWidgets(
      'gauge clamps only graphic fraction and retains values and status',
      (tester) async {
    for (final entry in <double, double>{
      0: 0,
      1: .01,
      50: .5,
      100: 1,
      140: 1,
      -5: 0
    }.entries) {
      await tester.pumpWidget(host(PlayerMenuGauge(
          value: entry.key, maximum: 100, label: 'PV', status: 'Empoisonné')));
      expect(
          tester
              .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
              .widthFactor,
          entry.value);
      expect(find.text('${entry.key.toInt()} / 100'), findsOneWidget);
      expect(find.text('Empoisonné'), findsOneWidget);
      expect(
          tester
              .widget<Text>(find.text('${entry.key.toInt()} / 100'))
              .style!
              .fontFeatures,
          contains(const FontFeature.tabularFigures()));
    }
    await tester.pumpWidget(
        host(const PlayerMenuGauge(value: 20, maximum: 0, label: 'PV')));
    expect(
        tester
            .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
            .widthFactor,
        0);
    expect(find.text('20 / 0'), findsOneWidget);
  });

  testWidgets(
      'opaque fallback removes only backdrop blur and retains geometry and commands',
      (tester) async {
    const frame = PlayerMenuFrame(
      header: PlayerMenuHeader(icon: Icons.backpack_outlined, title: 'Sac'),
      footer: PlayerMenuFooter(
          hints: [PlayerMenuKeyHint(glyph: 'Échap', label: 'Retour')]),
      child: Text('Contenu'),
    );
    await tester.pumpWidget(host(frame));
    await tester.pumpAndSettle();
    final before = tester.getRect(find.byType(PlayerMenuPanel));
    expect(find.byType(BackdropFilter), findsOneWidget);
    await tester.pumpWidget(host(frame, opaque: true));
    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsNothing);
    expect(tester.getRect(find.byType(PlayerMenuPanel)), before);
    expect(find.text('Retour'), findsOneWidget);
  });

  testWidgets(
      'type and status badges expose their meaning independently of color',
      (tester) async {
    await tester.pumpWidget(host(const Column(children: [
      PlayerMenuBadge(label: 'Eau', kind: PlayerMenuBadgeKind.type),
      PlayerMenuBadge(label: 'Brûlé', kind: PlayerMenuBadgeKind.status),
    ])));
    expect(find.bySemanticsLabel('Type : Eau'), findsOneWidget);
    expect(find.bySemanticsLabel('Statut : Brûlé'), findsOneWidget);
  });

  testWidgets(
      'receipt has one stable live region with action outside its announcement',
      (tester) async {
    Widget feedback() => host(PlayerMenuFeedback(
        id: 'receipt-save',
        title: 'Sauvegarde terminée',
        message: 'Votre aventure est conservée.',
        kind: PlayerMenuFeedbackKind.receipt,
        action: PlayerMenuSelectableRow(
            id: 'continue', label: 'Continuer', onPressed: () {})));
    await tester.pumpWidget(feedback());
    final finder = find
        .bySemanticsLabel('Sauvegarde terminée. Votre aventure est conservée.');
    final node = tester.getSemantics(finder);
    expect(node.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
    await tester.pumpWidget(feedback());
    expect(tester.getSemantics(finder).id, node.id);
    expect(find.bySemanticsLabel('Continuer'), findsOneWidget);
  });
  testWidgets(
      'menu opening and closing consume timed fade translation and exclude hidden actions',
      (tester) async {
    Widget transition(bool visible) => host(PlayerMenuTransition(
        visible: visible,
        child: PlayerMenuSelectableRow(
            id: 'close', label: 'Retour', onPressed: () {})));
    await tester.pumpWidget(transition(true));
    final transform = find.descendant(
        of: find.byType(PlayerMenuTransition),
        matching: find.byType(Transform));
    final opacity = find.descendant(
        of: find.byType(PlayerMenuTransition), matching: find.byType(Opacity));
    expect(tester.widget<Transform>(transform).transform.getTranslation().y, 8);
    await tester.pump(const Duration(milliseconds: 110));
    expect(tester.widget<Opacity>(opacity).opacity,
        closeTo(Curves.easeOutCubic.transform(.5), .01));
    await tester.pump(const Duration(milliseconds: 110));
    expect(tester.widget<Transform>(transform).transform.getTranslation().y, 0);
    await tester.pumpWidget(transition(false));
    final semanticsDumps = <String>[];
    void collectSemantics(PipelineOwner owner) {
      final root = owner.semanticsOwner?.rootSemanticsNode;
      if (root != null) semanticsDumps.add(root.toStringDeep());
      owner.visitChildren(collectSemantics);
    }

    collectSemantics(tester.binding.rootPipelineOwner);
    expect(semanticsDumps, isNotEmpty);
    expect(semanticsDumps.join(), isNot(contains('Retour')));
    expect(
        tester
            .widget<IgnorePointer>(find
                .descendant(
                    of: find.byType(PlayerMenuTransition),
                    matching: find.byType(IgnorePointer))
                .first)
            .ignoring,
        isTrue);
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.widget<Opacity>(opacity).opacity,
        closeTo(Curves.easeOutCubic.transform(.5), .01));
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.widget<Opacity>(opacity).opacity, 0);
  });

  testWidgets(
      'reduced motion opens without translation and detail changes fade by explicit key',
      (tester) async {
    Widget transition(String text) => MaterialApp(
          theme: PokeMapPlayerTheme.dark(reducedMotion: true),
          home: PlayerMenuThemeScope(
              child: PlayerMenuTransition(
                  child: PlayerMenuDetailTransition(
                      contentKey: ValueKey(text), child: Text(text)))),
        );
    await tester.pumpWidget(transition('Premier'));
    final transform = find.descendant(
        of: find.byType(PlayerMenuTransition),
        matching: find.byType(Transform));
    expect(tester.widget<Transform>(transform).transform.getTranslation().y, 0);
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pumpWidget(transition('Suivant'));
    expect(find.text('Premier'), findsOneWidget);
    expect(find.text('Suivant'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 81));
    await tester.pump();
    expect(find.text('Premier'), findsNothing);
    expect(tester.widget<Transform>(transform).transform.getTranslation().y, 0);
  });

  testWidgets('opaque row removes glow and composes fills while press darkens',
      (tester) async {
    Widget row({bool selected = false, bool pressed = false}) => host(
        PlayerMenuSelectableRow(
            id: 'effect',
            label: 'Équipe',
            selected: selected,
            pressed: pressed,
            onPressed: () {}),
        opaque: true);
    await tester.pumpWidget(row());
    BoxDecoration decoration() => tester
        .widget<Container>(find.byKey(const ValueKey('effect-surface')))
        .decoration! as BoxDecoration;
    final resting = (decoration().gradient! as LinearGradient).colors.first;
    expect(resting.a, 1);
    await tester.pumpWidget(row(pressed: true));
    await tester.pumpAndSettle();
    expect((decoration().gradient! as LinearGradient).colors.first.a, 1);
    expect(
        (decoration().gradient! as LinearGradient)
            .colors
            .first
            .computeLuminance(),
        lessThan(resting.computeLuminance()));
    await tester.pumpWidget(row(selected: true));
    await tester.pumpAndSettle();
    expect(decoration().boxShadow, isNull);
  });
  testWidgets('closing a focused menu also blocks keyboard activation',
      (tester) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    var activations = 0;
    Widget transition(bool visible) => host(PlayerMenuTransition(
        visible: visible,
        child: PlayerMenuSelectableRow(
            id: 'keyboard',
            label: 'Continuer',
            focusNode: focus,
            onPressed: () => activations++)));
    await tester.pumpWidget(transition(true));
    await tester.pumpAndSettle();
    focus.requestFocus();
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    await tester.pumpWidget(transition(false));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(activations, 0);
    expect(focus.hasFocus, isFalse);
  });
  testWidgets(
      'long title remains inside its header viewport with text 2 and safe insets',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    const title = 'Un titre particulièrement long pour l’aventure';
    for (final size in [const Size(390, 844), const Size(844, 390)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: Builder(
            builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                      textScaler: const TextScaler.linear(2),
                      padding: const EdgeInsets.only(top: 24, bottom: 16)),
                  child: PlayerMenuThemeScope(
                      child: PlayerMenuFrame(
                    header: const PlayerMenuHeader(
                        icon: Icons.backpack_outlined,
                        title: title,
                        secondary: Text('Aventure · 125:48')),
                    footer: PlayerMenuFooter(
                        hints: const [],
                        returnAction: SizedBox(
                            width: 180,
                            child: PlayerMenuSelectableRow(
                                id: 'return',
                                label: 'Retour',
                                onPressed: () {}))),
                    child: const Text('Contenu'),
                  )),
                )),
      ));
      await tester.pumpAndSettle();
      final paragraph = tester.renderObject<RenderParagraph>(find.text(title));
      final titleRect = paragraph.localToGlobal(Offset.zero) & paragraph.size;
      final viewport = tester.getRect(find
          .ancestor(
              of: find.byType(PlayerMenuHeader),
              matching: find.byType(SingleChildScrollView))
          .first);
      expect(titleRect.top, greaterThanOrEqualTo(viewport.top));
      expect(titleRect.bottom, lessThanOrEqualTo(viewport.bottom));
      expect(titleRect.left, greaterThanOrEqualTo(viewport.left));
      expect(titleRect.right, lessThanOrEqualTo(viewport.right));
      expect(find.text('Retour').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets(
      'outgoing detail loses pointer keyboard and semantics during fade',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      var oldActivations = 0;
      Widget detail(bool current) => host(SizedBox(
          width: 320,
          child: PlayerMenuDetailTransition(
            contentKey: ValueKey(current),
            child: current
                ? const Text('Nouveau détail')
                : PlayerMenuSelectableRow(
                    id: 'outgoing',
                    label: 'Ancienne action',
                    focusNode: focus,
                    onPressed: () => oldActivations++),
          )));
      await tester.pumpWidget(detail(false));
      focus.requestFocus();
      await tester.pump();
      expect(focus.hasFocus, isTrue);
      await tester.pumpWidget(detail(true));
      expect(find.text('Ancienne action'), findsOneWidget);
      expect(focus.hasFocus, isFalse);
      await tester.tapAt(tester.getCenter(find.text('Ancienne action')));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(oldActivations, 0);
      await tester.pump(const Duration(milliseconds: 1));
      expect(focus.hasFocus, isFalse);
      expect(oldActivations, 0);
      final semanticsDumps = <String>[];
      void collectSemantics(PipelineOwner owner) {
        final root = owner.semanticsOwner?.rootSemanticsNode;
        if (root != null) semanticsDumps.add(root.toStringDeep());
        owner.visitChildren(collectSemantics);
      }

      collectSemantics(tester.binding.rootPipelineOwner);
      expect(semanticsDumps, isNotEmpty);
      expect(semanticsDumps.join(), isNot(contains('Ancienne action')));
      await tester.pumpAndSettle();
      expect(find.text('Ancienne action'), findsNothing);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
      'authored intermediate selections keep AA contrast throughout state shading',
      (tester) async {
    for (final entry in [('pressed', '#808080'), ('hovered', '#777777')]) {
      final base = PokeMapPlayerTheme.dark();
      final theme = base.copyWith(extensions: [
        ...base.extensions.values,
        PokeMapPlayerSurfacePaletteTheme(
            ProjectPresentationSurfacePalettesProfile(
                pauseMenu: ProjectSurfacePaletteProfile(selection: entry.$2))),
      ]);
      Widget row(bool active) => MaterialApp(
          theme: theme,
          home: PlayerMenuThemeScope(
              child: Scaffold(
                  body: PlayerMenuSelectableRow(
            id: 'contrast',
            label: 'Sélection',
            selected: true,
            pressed: active && entry.$1 == 'pressed',
            hovered: active && entry.$1 == 'hovered',
            onPressed: () {},
          ))));
      await tester.pumpWidget(row(false));
      await tester.pumpAndSettle();
      final foreground = tester
          .widget<DefaultTextStyle>(find
              .ancestor(
                  of: find.text('Sélection'),
                  matching: find.byType(DefaultTextStyle))
              .first)
          .style
          .color!;
      await tester.pumpWidget(row(true));
      for (var step = 0; step <= 12; step++) {
        final decorated = tester.widget<DecoratedBox>(find
            .descendant(
                of: find.byKey(const ValueKey('contrast-surface')),
                matching: find.byType(DecoratedBox))
            .first);
        final gradient =
            (decorated.decoration as BoxDecoration).gradient! as LinearGradient;
        for (final color in gradient.colors) {
          final a = foreground.computeLuminance();
          final b = color.computeLuminance();
          final contrast =
              (a > b ? a + .05 : b + .05) / (a > b ? b + .05 : a + .05);
          expect(contrast, greaterThanOrEqualTo(4.5),
              reason: '${entry.$1}, frame $step');
        }
        await tester.pump(const Duration(milliseconds: 10));
      }
    }
  });
  testWidgets(
      'selection toggles retain actual label subtitle and focus contrast on every frame',
      (tester) async {
    for (final opaque in [false, true]) {
      for (final authored in [null, '#808080', '#777777']) {
        final base = PokeMapPlayerTheme.dark();
        final theme = base.copyWith(extensions: [
          ...base.extensions.values,
          if (authored != null)
            PokeMapPlayerSurfacePaletteTheme(
                ProjectPresentationSurfacePalettesProfile(
                    pauseMenu:
                        ProjectSurfacePaletteProfile(selection: authored))),
        ]);
        Widget row(bool selected) => MaterialApp(
            theme: theme,
            home: PlayerMenuThemeScope(
              opaque: opaque,
              child: Builder(
                  builder: (context) => ColoredBox(
                      color: context.playerMenuTheme.backdropLight,
                      child: PlayerMenuPanel(
                          child: PlayerMenuSelectableRow(
                              id: 'toggle',
                              label: 'Équipe',
                              subtitle: 'Six partenaires',
                              selected: selected,
                              focused: true,
                              onPressed: () {})))),
            ));
        await tester.pumpWidget(row(false));
        await tester.pumpAndSettle();
        final rowSize = tester.getSize(find.byType(PlayerMenuSelectableRow));
        for (final selected in [true, false]) {
          await tester.pumpWidget(row(selected));
          final animation = tester.widget<TweenAnimationBuilder<Decoration>>(
              find.byType(TweenAnimationBuilder<Decoration>));
          expect(animation.duration, const Duration(milliseconds: 140));
          for (var frame = 0; frame <= 28; frame++) {
            final painted = tester
                .widget<DecoratedBox>(find
                    .descendant(
                        of: find.byKey(const ValueKey('toggle-surface')),
                        matching: find.byType(DecoratedBox))
                    .first)
                .decoration as BoxDecoration;
            final gradient = painted.gradient! as LinearGradient;
            final label = tester
                .renderObject<RenderParagraph>(find.text('Équipe'))
                .text
                .style!
                .color!;
            final subtitle = tester
                .renderObject<RenderParagraph>(find.text('Six partenaires'))
                .text
                .style!
                .color!;
            final marker = (tester
                    .widget<DecoratedBox>(
                        find.byKey(const ValueKey('toggle-focus-marker')))
                    .decoration as BoxDecoration)
                .color!;
            for (final stop in gradient.colors) {
              if (opaque) expect(stop.a, 1);
              final composedPanel = Color.alphaBlend(
                  const PokeMapPlayerMenuTheme().panel.withValues(alpha: .96),
                  const PokeMapPlayerMenuTheme().backdropLight);
              final composedRow = Color.alphaBlend(
                  stop,
                  painted.color == null
                      ? composedPanel
                      : Color.alphaBlend(painted.color!, composedPanel));
              for (final foreground in [label, subtitle, marker]) {
                final a = Color.alphaBlend(foreground, composedRow)
                    .computeLuminance();
                final b = composedRow.computeLuminance();
                final ratio =
                    (a > b ? a + .05 : b + .05) / (a > b ? b + .05 : a + .05);
                expect(ratio, greaterThanOrEqualTo(4.5),
                    reason:
                        'opaque=$opaque author=$authored selected=$selected frame=$frame');
              }
            }
            expect(
                tester.getSize(find.byType(PlayerMenuSelectableRow)), rowSize);
            await tester.pump(const Duration(milliseconds: 5));
          }
        }
      }
    }
  });
}
