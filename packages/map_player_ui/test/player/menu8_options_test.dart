import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/player/runtime_player_options.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets(
      'title options keep neighbour names complete at width$width text2',
      (tester) async {
        await _loadFonts(tester);
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 844);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
            localizationsDelegates:
                PokeMapPlayerLocalizations.localizationsDelegates,
            theme: PokeMapPlayerTheme.dark(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: PlayerTitleOptionsSurface(
              snapshot: RuntimePlayerSnapshot(
                revision: 1,
                phase: RuntimePlayerPhase.title,
                gameTitle: 'Aube',
                pauseSection: RuntimePlayerPauseSection.options,
                preferences: _preferences,
                actions: const [
                  RuntimePlayerActionAvailability.enabled(
                    RuntimePlayerAction.openOptions,
                  ),
                  RuntimePlayerActionAvailability.enabled(
                    RuntimePlayerAction.updatePreferences,
                  ),
                  RuntimePlayerActionAvailability.enabled(
                    RuntimePlayerAction.returnToTitle,
                  ),
                ],
              ),
              onReturnToTitle: () {},
              onPreferencesChanged: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final id in ['previous', 'next']) {
          final button = find.byKey(ValueKey('options-category-$id'));
          expect(button.hitTestable(), findsOneWidget);
          expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
          expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
          for (final element
              in find
                  .descendant(of: button, matching: find.byType(RichText))
                  .evaluate()) {
            expect(
              (element.renderObject! as RenderParagraph).didExceedMaxLines,
              isFalse,
              reason: '$id at $width',
            );
          }
        }
        expect(find.text('Accessibilité'), findsOneWidget);
        expect(find.text('Affichage'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'cancelled dropdown returns keyboard focus to its invoking choice',
    (tester) async {
      final changes = <PlayerPreferencesSnapshot>[];
      await _pump(tester, size: const Size(390, 844), onChanged: changes.add);
      final choice = find.byKey(const ValueKey('options-text-speed-choice'));
      await _tap(tester, 'options-text-speed-choice');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(changes, isEmpty);
      expect(
        tester
            .widget<PlayerMenuSelectableRow>(choice)
            .focusNode!
            .hasPrimaryFocus,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('options-menu-effects-choice')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'portrait dropdown keeps four choices readable at double text scale',
    (tester) async {
      await _pump(tester, size: const Size(390, 844), scale: 2);
      await _tap(tester, 'options-text-speed-choice');
      final dialog = find.byType(Dialog);
      final panel = find.descendant(
        of: dialog,
        matching: find.byType(PlayerMenuPanel),
      );
      expect(tester.getSize(panel).height, lessThanOrEqualTo(812));
      for (final id in ['slow', 'normal', 'fast', 'instant']) {
        final row = find.byKey(ValueKey('options-choice-$id'));
        expect(row.hitTestable(), findsOneWidget);
        expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
        for (final element
            in find
                .descendant(of: row, matching: find.byType(RichText))
                .evaluate()) {
          expect(
            (element.renderObject! as RenderParagraph).didExceedMaxLines,
            isFalse,
          );
        }
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'portrait dropdown sizes its four choices without an empty lower panel',
    (tester) async {
      await _pump(
        tester,
        size: const Size(390, 844),
        activeInputSource: PlayerInputSource.touch,
      );
      await _tap(tester, 'options-text-speed-choice');
      final dialog = find.byType(Dialog);
      final panel = find.descendant(
        of: dialog,
        matching: find.byType(PlayerMenuPanel),
      );
      expect(panel, findsOneWidget);
      expect(tester.getSize(panel).height, lessThanOrEqualTo(380));
      final lastChoice = find.byKey(const ValueKey('options-choice-instant'));
      final back = find.byKey(const ValueKey('options-choice-back'));
      expect(lastChoice.hitTestable(), findsOneWidget);
      expect(back.hitTestable(), findsOneWidget);
      expect(
        tester.getRect(back).top - tester.getRect(lastChoice).bottom,
        lessThanOrEqualTo(24),
      );
      expect(
        find.descendant(
          of: dialog,
          matching: find.byKey(const ValueKey('player-page-next')),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(390, 844),
    const Size(844, 390),
    const Size(496, 432),
  ]) {
    testWidgets(
      'integrated category neighbours stay visible and navigate at $size',
      (tester) async {
        await _pumpIntegrated(tester, size, input: PlayerInputSource.touch);
        final previous = find.byKey(
          const ValueKey('options-category-previous'),
        );
        final next = find.byKey(const ValueKey('options-category-next'));
        expect(previous.hitTestable(), findsOneWidget);
        expect(next.hitTestable(), findsOneWidget);
        for (final target in [previous, next]) {
          expect(tester.getSize(target).width, greaterThanOrEqualTo(48));
          expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
        }
        expect(
          find.descendant(of: previous, matching: find.text('Accessibilité')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: next, matching: find.text('Affichage')),
          findsOneWidget,
        );
        await tester.tap(next);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('options-menu-effects-choice')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: previous, matching: find.text('Général')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: next, matching: find.text('Son')),
          findsOneWidget,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('options-text-speed-choice')),
          findsOneWidget,
        );
        expect(find.byType(Scrollable), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'dropdown opens published choices before changing the preference',
    (tester) async {
      final changes = <PlayerPreferencesSnapshot>[];
      await _pump(
        tester,
        size: const Size(390, 844),
        activeInputSource: PlayerInputSource.touch,
        onChanged: changes.add,
      );
      await _tap(tester, 'options-text-speed-choice');
      expect(changes, isEmpty);
      expect(find.byType(Dialog), findsOneWidget);
      expect(
        find.byKey(const ValueKey('options-choice-normal')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('options-choice-instant')),
        findsOneWidget,
      );
      await _tap(tester, 'options-choice-instant');
      expect(
        changes.single.dialogueTextSpeed,
        RuntimeDialogueTextSpeed.instant,
      );
      expect(find.byType(Dialog), findsNothing);
      await _tap(tester, 'options-text-speed-choice');
      await _tap(tester, 'options-choice-back');
      expect(changes, hasLength(1));
      expect(find.text('Instantanée'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(390, 844),
    const Size(844, 390),
    const Size(496, 432),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('long published choice stays complete at $size text$scale', (
        tester,
      ) async {
        await _pumpIntegrated(
          tester,
          size,
          scale: scale,
          preferences: _preferences.copyWith(
            dialogueTextSpeed: RuntimeDialogueTextSpeed.instant,
          ),
        );
        final choice = find.byKey(const ValueKey('options-text-speed-choice'));
        expect(choice.hitTestable(), findsOneWidget);
        final bounds = tester.getRect(choice);
        expect(bounds.height, greaterThanOrEqualTo(48));
        final text = find.descendant(
          of: choice,
          matching: find.text('Instantanée'),
        );
        expect(text, findsOneWidget);
        final textBounds = tester.getRect(text);
        expect(textBounds.left, greaterThanOrEqualTo(bounds.left));
        expect(textBounds.right, lessThanOrEqualTo(bounds.right));
        expect(textBounds.bottom, lessThanOrEqualTo(bounds.bottom));
        for (final paragraph
            in find
                .descendant(of: choice, matching: find.byType(RichText))
                .evaluate()) {
          expect(
            (paragraph.renderObject! as RenderParagraph).didExceedMaxLines,
            isFalse,
          );
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final size in [const Size(844, 390), const Size(496, 432)]) {
    testWidgets('general choice text fits its 48px target at $size', (
      tester,
    ) async {
      await _pumpIntegrated(tester, size, input: PlayerInputSource.touch);
      final choice = find.byKey(const ValueKey('options-text-speed-choice'));
      expect(choice.hitTestable(), findsOneWidget);
      expect(tester.getSize(choice).height, greaterThanOrEqualTo(48));
      final text = find.descendant(of: choice, matching: find.text('Normale'));
      expect(text, findsOneWidget);
      final element = tester.element(text);
      final widget = tester.widget<Text>(text);
      final rect = tester.getRect(text);
      final painter = TextPainter(
        text: TextSpan(
          text: widget.data,
          style: DefaultTextStyle.of(element).style.merge(widget.style),
        ),
        textDirection: Directionality.of(element),
        textScaler: MediaQuery.textScalerOf(element),
        maxLines: 1,
      )..layout(maxWidth: rect.width);
      expect(painter.didExceedMaxLines, isFalse);
      expect(rect.height, closeTo(painter.height, .1));
      painter.dispose();
      final back = find.byKey(const ValueKey('pause-frame-return-surface'));
      expect(back.hitTestable(), findsOneWidget);
      final label = find.descendant(of: back, matching: find.text('Retour'));
      expect(label, findsOneWidget);
      expect(tester.getSize(label).height, greaterThan(0));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('landscape audio presents all three sliders together', (
    tester,
  ) async {
    await _pump(tester, size: const Size(844, 390));
    await _category(tester, 'audio');
    for (final key in [
      'options-master-slider',
      'options-music-slider',
      'options-effects-slider',
    ]) {
      final slider = find.byKey(ValueKey(key));
      expect(slider.hitTestable(), findsOneWidget);
      expect(tester.getRect(slider).height, greaterThanOrEqualTo(48));
    }
    for (final category in _categories) {
      final tab = find.byKey(ValueKey('options-category-$category'));
      expect(tab.hitTestable(), findsOneWidget);
      expect(tester.getSize(tab).height, greaterThanOrEqualTo(48));
      for (final text
          in find
              .descendant(of: tab, matching: find.byType(RichText))
              .evaluate()) {
        expect(
          (text.renderObject! as RenderParagraph).didExceedMaxLines,
          isFalse,
          reason: category,
        );
      }
    }
    expect(find.byKey(const ValueKey('options-categories')), findsNothing);
    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('companion audio separates text and thumbs inside 48px targets', (
    tester,
  ) async {
    await _pumpIntegrated(tester, const Size(496, 432));
    await _category(tester, 'audio');
    final body = tester.getRect(find.byKey(const ValueKey('options-settings')));
    final targets = <Rect>[];
    for (final channel in ['master', 'music', 'effects']) {
      final slider = find.byKey(ValueKey('options-$channel-slider'));
      final setting = find.byKey(ValueKey('options-$channel-slider-setting'));
      expect(slider.hitTestable(), findsOneWidget, reason: '$channel in $body');
      final target = tester.getRect(slider);
      final bounds = tester.getRect(setting);
      targets.add(target);
      expect(target.height, 48);
      expect(bounds.height, 64);
      expect(target.top, greaterThanOrEqualTo(bounds.top));
      expect(target.bottom, lessThanOrEqualTo(bounds.bottom + .1));
      final thumb = SliderTheme.of(tester.element(slider)).thumbShape!
          .getPreferredSize(true, true);
      final thumbTop = target.center.dy - thumb.height / 2;
      final texts = find.descendant(of: setting, matching: find.byType(Text));
      expect(texts, findsNWidgets(2));
      for (final element in texts.evaluate()) {
        final text = element.widget as Text;
        final finder = find.byElementPredicate(
          (candidate) => identical(candidate, element),
        );
        final rect = tester.getRect(finder);
        final painter = TextPainter(
          text: TextSpan(
            text: text.data,
            style: DefaultTextStyle.of(element).style.merge(text.style),
          ),
          textDirection: Directionality.of(element),
          textScaler: MediaQuery.textScalerOf(element),
          maxLines: text.maxLines,
        )..layout(maxWidth: rect.width);
        expect(painter.height, lessThanOrEqualTo(rect.height + .1));
        expect(painter.didExceedMaxLines, isFalse);
        expect(rect.bottom, lessThanOrEqualTo(thumbTop - 4));
        painter.dispose();
      }
    }
    for (var index = 1; index < targets.length; index++) {
      expect(
        targets[index].top - targets[index - 1].bottom,
        greaterThanOrEqualTo(8),
      );
    }
    final reset = tester.getRect(
      find.byKey(const ValueKey('options-defaults')),
    );
    expect(reset.top - targets.last.bottom, greaterThanOrEqualTo(8));
    expect(reset.bottom, lessThanOrEqualTo(body.bottom + .1));
    expect(find.byKey(const ValueKey('player-page-next')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('landscape touch controls show the four preferences together', (
    tester,
  ) async {
    await _pumpIntegrated(
      tester,
      const Size(844, 390),
      input: PlayerInputSource.touch,
    );
    await _category(tester, 'controls');
    for (final key in [
      'options-touch-run-mode-choice',
      'runtime-player-left-handed-touch-toggle',
      'runtime-player-input-hints-toggle',
      'touch-controls-opacity-slider',
    ]) {
      expect(find.byKey(ValueKey(key)).hitTestable(), findsOneWidget);
    }
    expect(
      find.byKey(const ValueKey('player-page-next')).hitTestable(),
      findsNothing,
    );
    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(844, 390), const Size(496, 432)]) {
    testWidgets(
      'integrated options keep audio and controller bindings dense at $size',
      (tester) async {
        await _pumpIntegrated(tester, size);
        await _category(tester, 'audio');
        for (final channel in ['master', 'music', 'effects']) {
          final slider = find.byKey(ValueKey('options-$channel-slider'));
          expect(slider.hitTestable(), findsOneWidget);
          expect(tester.getSize(slider).height, greaterThanOrEqualTo(48));
        }
        expect(
          find.byKey(const ValueKey('player-page-next')).hitTestable(),
          findsNothing,
        );
        await _category(tester, 'controls');
        final visible = RuntimeInputControl.values
            .map(
              (control) => find.byKey(
                ValueKey('options-binding-${control.name}-choice'),
              ),
            )
            .where((finder) => finder.hitTestable().evaluate().isNotEmpty)
            .toList();
        expect(visible.length, greaterThanOrEqualTo(4));
        for (final binding in visible) {
          expect(tester.getSize(binding).height, greaterThanOrEqualTo(48));
          for (final element
              in find
                  .descendant(of: binding, matching: find.byType(RichText))
                  .evaluate()) {
            expect(
              (element.renderObject! as RenderParagraph).didExceedMaxLines,
              isFalse,
            );
          }
        }
        expect(
          find.byKey(const ValueKey('options-touch-run-mode-choice')),
          findsNothing,
        );
        await tester.tap(
          find.byKey(const ValueKey('options-control-device-switch')),
        );
        await tester.pumpAndSettle();
        expect(
          find
              .byKey(const ValueKey('options-touch-run-mode-choice'))
              .hitTestable(),
          findsOneWidget,
        );
        expect(find.byType(Scrollable), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'selected choices persist and reset through explicit confirmation',
    (tester) async {
      final changes = <PlayerPreferencesSnapshot>[];
      await _pump(tester, onChanged: changes.add);
      expect(
        tester
            .widget<PlayerMenuSelectableRow>(
              find.byKey(const ValueKey('options-defaults')),
            )
            .onPressed,
        isNull,
      );
      await _tap(tester, 'options-text-speed-choice');
      await _tap(tester, 'options-choice-fast');
      expect(changes.single.dialogueTextSpeed, RuntimeDialogueTextSpeed.fast);
      expect(find.byType(Dialog), findsNothing);
      expect(
        tester
            .widget<PlayerMenuSelectableRow>(
              find.byKey(const ValueKey('options-defaults')),
            )
            .onPressed,
        isNotNull,
      );
      await _tap(tester, 'options-defaults');
      await _tap(tester, 'options-reset-cancel');
      expect(changes, hasLength(1));
      await _tap(tester, 'options-defaults');
      await _tap(tester, 'options-reset-confirm');
      expect(changes.last.dialogueTextSpeed, RuntimeDialogueTextSpeed.normal);
      expect(
        tester
            .widget<PlayerMenuSelectableRow>(
              find.byKey(const ValueKey('options-defaults')),
            )
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets('failed selected choice preserves the confirmed preference', (
    tester,
  ) async {
    await _pump(
      tester,
      onChanged: (_) =>
          throw const RuntimePlayerOptionsFailure('Écriture indisponible.'),
    );
    await _tap(tester, 'options-text-speed-choice');
    await _tap(tester, 'options-choice-fast');
    expect(find.text('Écriture indisponible.'), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(
      tester
          .widget<PlayerMenuSelectableRow>(
            find.byKey(const ValueKey('options-defaults')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets(
    'choice selection rejects duplicate activation until persistence completes',
    (tester) async {
      final completion = Completer<void>();
      var writes = 0;
      await _pump(
        tester,
        onChanged: (_) {
          writes++;
          return completion.future;
        },
      );
      final row = tester.widget<PlayerMenuSelectableRow>(
        find.byKey(const ValueKey('options-text-speed-choice')),
      );
      row.onPressed!();
      row.onPressed!();
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(writes, 0);
      await tester.tap(find.byKey(const ValueKey('options-choice-fast')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(writes, 1);
      expect(find.byType(Dialog), findsNothing);
      final pendingChoice = find.byKey(
        const ValueKey('options-text-speed-choice'),
      );
      expect(
        tester.widget<PlayerMenuSelectableRow>(pendingChoice).onPressed,
        isNull,
      );
      await tester.tap(pendingChoice);
      await tester.pump();
      expect(writes, 1);
      completion.complete();
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(tester.takeException(), isNull);
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
      testWidgets(
        'all categories and critical return fit $size text $scale without content scrolling',
        (tester) async {
          await _pump(tester, size: size, scale: scale);
          for (final category in _categories) {
            await _category(tester, category);
            expect(tester.takeException(), isNull, reason: category);
            expect(find.byType(Scrollable), findsNothing);
            if (size.height == 390 && scale == 2) {
              final seen = <String>{};
              const controls = {
                'options-touch-run-mode-choice',
                'runtime-player-left-handed-touch-toggle',
                'runtime-player-input-hints-toggle',
                'touch-controls-opacity-slider',
                'options-binding-primary-choice',
              };
              var pages = 0;
              var readTouchSettings = false;
              while (true) {
                for (final key in controls) {
                  if (find
                      .byKey(ValueKey(key))
                      .hitTestable()
                      .evaluate()
                      .isNotEmpty) {
                    seen.add(key);
                  }
                }
                expect(
                  tester.takeException(),
                  isNull,
                  reason: '$category page $pages',
                );
                expect(find.byType(Scrollable), findsNothing);
                final next = find.descendant(
                  of: find.byKey(const ValueKey('options-settings')),
                  matching: find.byKey(const ValueKey('player-page-next')),
                );
                if (next.evaluate().isEmpty ||
                    tester.widget<IconButton>(next).onPressed == null) {
                  if (category == 'controls' && !readTouchSettings) {
                    readTouchSettings = true;
                    await tester.tap(
                      find.byKey(
                        const ValueKey('options-control-device-switch'),
                      ),
                    );
                    await tester.pumpAndSettle();
                    continue;
                  }
                  break;
                }
                expect(pages++, lessThan(40), reason: category);
                await tester.tap(next);
                await tester.pumpAndSettle();
              }
              if (category == 'controls') expect(seen, controls);
            }
            expect(
              find
                  .byKey(const ValueKey('pause-frame-return-surface'))
                  .hitTestable(),
              findsOneWidget,
            );
          }
        },
      );
    }
  }

  testWidgets('reset confirmation retains local text scale and remapped back', (
    tester,
  ) async {
    final profile = PlayerControlProfile.standard
        .rebind(
          device: PlayerControlDevice.keyboard,
          control: RuntimeInputControl.secondary,
          inputId: 'keyW',
        )
        .profile;
    final changes = <PlayerPreferencesSnapshot>[];
    await _pump(
      tester,
      localScale: 1.6,
      profile: profile,
      onChanged: changes.add,
    );
    await _tap(tester, 'options-text-speed-choice');
    await _tap(tester, 'options-choice-fast');
    await _tap(tester, 'options-defaults');
    expect(
      MediaQuery.textScalerOf(
        tester.element(find.byKey(const ValueKey('options-reset-cancel'))),
      ).scale(1),
      1.6,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.keyW);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(changes, hasLength(1));
  });

  testWidgets(
    'touch options omit removed bindings and retain gesture settings',
    (tester) async {
      final changes = <PlayerControlProfile>[];
      await _pump(
        tester,
        activeInputSource: PlayerInputSource.touch,
        onControlChanged: changes.add,
      );
      await _category(tester, 'controls');
      for (final control in RuntimeInputControl.values) {
        expect(
          find.byKey(ValueKey('options-binding-${control.name}-choice')),
          findsNothing,
        );
      }
      expect(
        find.byKey(const ValueKey('options-controls-touch-swap')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('options-controls-reset')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('options-touch-run-mode-choice')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('runtime-player-left-handed-touch-toggle')),
        findsOneWidget,
      );
      expect(changes, isEmpty);
    },
  );

  testWidgets('touch running alternatives save and reset through controls', (
    tester,
  ) async {
    final changes = <PlayerPreferencesSnapshot>[];
    await _pump(
      tester,
      onChanged: changes.add,
      activeInputSource: PlayerInputSource.touch,
    );
    await _category(tester, 'controls');
    expect(tester.takeException(), isNull, reason: 'controls initial layout');
    await _tap(tester, 'options-touch-run-mode-choice');
    await _tap(tester, 'options-choice-walkOnly');
    expect(changes.single.touchRunMode, RuntimePlayerTouchRunMode.walkOnly);
    expect(tester.takeException(), isNull, reason: 'walk-only persisted');
    await _tap(tester, 'options-touch-run-mode-choice');
    await _tap(tester, 'options-choice-automatic');
    expect(changes.last.touchRunMode, RuntimePlayerTouchRunMode.automatic);
    expect(tester.takeException(), isNull, reason: 'automatic persisted');
    await _tap(tester, 'options-defaults');
    await _tap(tester, 'options-reset-confirm');
    expect(changes.last.touchRunMode, RuntimePlayerTouchRunMode.gesture);
    expect(changes.last.audioMix, _preferences.audioMix);
    expect(tester.takeException(), isNull);
  });

  testWidgets('touch side setting persists and resets with controls', (
    tester,
  ) async {
    final changes = <PlayerPreferencesSnapshot>[];
    await _pump(
      tester,
      onChanged: changes.add,
      activeInputSource: PlayerInputSource.touch,
    );
    await _category(tester, 'controls');
    await _tap(tester, 'runtime-player-left-handed-touch-toggle');
    expect(changes.single.leftHandedTouchControls, isTrue);
    expect(changes.single.audioMix, _preferences.audioMix);
    await _tap(tester, 'options-defaults');
    await _tap(tester, 'options-reset-confirm');
    expect(changes.last.leftHandedTouchControls, isFalse);
    expect(changes.last.audioMix, _preferences.audioMix);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'audio sliders persist their channels without changing category',
    (tester) async {
      final changes = <PlayerPreferencesSnapshot>[];
      await _pump(tester, onChanged: changes.add);
      await _category(tester, 'audio');
      for (final channel in ['master', 'music', 'effects']) {
        final slider = tester.widget<Slider>(
          find.byKey(ValueKey('options-$channel-slider')),
        );
        expect(slider.divisions, 20);
        slider.onChanged!(.35);
        slider.onChangeEnd!(.35);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('options-master-slider')),
          findsOneWidget,
        );
      }
      expect(changes.last.audioMix.masterVolume, .35);
      expect(changes.last.audioMix.musicVolume, .35);
      expect(changes.last.audioMix.effectsVolume, .35);
      expect(changes.last.locale, 'fr');
    },
  );

  testWidgets('failed persistence restores slider and keeps a visible error', (
    tester,
  ) async {
    final completion = Completer<void>();
    await _pump(tester, onChanged: (_) => completion.future);
    await _category(tester, 'audio');
    var slider = tester.widget<Slider>(
      find.byKey(const ValueKey('options-master-slider')),
    );
    slider.onChanged!(.2);
    slider.onChangeEnd!(.2);
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('options-saving')), findsOneWidget);
    slider = tester.widget<Slider>(
      find.byKey(const ValueKey('options-master-slider')),
    );
    expect(slider.onChanged, isNull);
    expect(
      tester
          .widget<PlayerMenuSelectableRow>(
            find.byKey(const ValueKey('options-defaults')),
          )
          .onPressed,
      isNull,
    );
    completion.completeError(StateError('secret_path_should_not_leak'));
    await tester.pumpAndSettle();
    slider = tester.widget<Slider>(
      find.byKey(const ValueKey('options-master-slider')),
    );
    expect(slider.value, 1);
    expect(find.byKey(const ValueKey('options-save-error')), findsOneWidget);
    expect(find.textContaining('secret_path'), findsNothing);
    await _category(tester, 'display');
    expect(find.byKey(const ValueKey('options-save-error')), findsOneWidget);
  });

  testWidgets('cancelled category reset never writes preferences', (
    tester,
  ) async {
    final changes = <PlayerPreferencesSnapshot>[];
    await _pump(tester, onChanged: changes.add);
    await _category(tester, 'general');
    await _tap(tester, 'options-text-speed-choice');
    await _tap(tester, 'options-choice-fast');
    changes.clear();
    await _tap(tester, 'options-defaults');
    expect(find.byKey(const ValueKey('options-reset-cancel')), findsOneWidget);
    await _tap(tester, 'options-reset-cancel');
    expect(changes, isEmpty);
  });

  testWidgets('confirmed reset only restores current category', (tester) async {
    final changes = <PlayerPreferencesSnapshot>[];
    await _pump(
      tester,
      preferences: _preferences.copyWith(
        audioMix: const RuntimeAudioMix(
          masterVolume: .2,
          musicVolume: .3,
          effectsVolume: .4,
        ),
        highContrast: true,
        showInputHints: false,
      ),
      onChanged: changes.add,
    );
    await _category(tester, 'audio');
    await _tap(tester, 'options-defaults');
    await _tap(tester, 'options-reset-confirm');
    expect(changes.single.audioMix, const RuntimeAudioMix());
    expect(changes.single.highContrast, isTrue);
    expect(changes.single.showInputHints, isFalse);
  });

  testWidgets('interface language keeps selected category after reload', (
    tester,
  ) async {
    final current = ValueNotifier(_preferences);
    addTearDown(current.dispose);
    await _pump(
      tester,
      notifier: current,
      onChanged: (value) => current.value = value,
    );
    await _category(tester, 'language');
    await _tap(tester, 'options-locale-choice');
    await _tap(tester, 'options-choice-en');
    expect(current.value.locale, 'en');
    expect(find.text('Interface language'), findsOneWidget);
    expect(find.byKey(const ValueKey('options-locale-choice')), findsOneWidget);
  });

  testWidgets('category reset restores the host defaults', (tester) async {
    final changes = <PlayerPreferencesSnapshot>[];
    const defaults = PlayerPreferencesSnapshot(
      locale: 'en',
      accessibility: GameSessionAccessibilityOptions(),
      audioMix: RuntimeAudioMix(musicVolume: .8, effectsVolume: .8),
    );
    await _pump(tester, defaultPreferences: defaults, onChanged: changes.add);
    await _category(tester, 'language');
    await _tap(tester, 'options-defaults');
    await _tap(tester, 'options-reset-confirm');
    expect(changes.single.locale, 'en');
    await _category(tester, 'audio');
    await _tap(tester, 'options-defaults');
    await _tap(tester, 'options-reset-confirm');
    expect(changes.last.audioMix, defaults.audioMix);
    expect(changes.last.locale, 'en');
  });

  testWidgets('return to title delegates to existing confirmation flow', (
    tester,
  ) async {
    var exits = 0;
    await _pump(tester, onReturnToTitle: () => exits++);
    await _tap(tester, 'options-return-title');
    expect(exits, 1);
  });

  testWidgets('desktop accessibility omits unsupported vibrations', (
    tester,
  ) async {
    await _pump(tester);
    await _category(tester, 'accessibility');
    expect(
      find.byKey(const ValueKey('runtime-player-haptics-toggle')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('runtime-player-reduced-motion-toggle')),
      findsOneWidget,
    );
  });

  testWidgets(
    'keyboard and controller adjust the focused audio slider by five percent',
    (tester) async {
      final changes = <PlayerPreferencesSnapshot>[];
      await _pump(tester, onChanged: changes.add);
      await _category(tester, 'audio');
      final slider = find.byKey(const ValueKey('options-master-slider'));
      await tester.tap(slider);
      await tester.pumpAndSettle();
      expect(
        tester.widget<Slider>(slider).focusNode!.hasFocus,
        isTrue,
        reason: 'A quick tap retains the slider as the owner after saving.',
      );
      changes.clear();
      final before = tester.widget<Slider>(slider).value;
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(changes.last.audioMix.masterVolume, closeTo(before - .05, .001));
      Actions.invoke(
        FocusManager.instance.primaryFocus!.context!,
        const RuntimePlayerLogicalIntent(
          PlayerInputAction.right,
          source: PlayerInputSource.controller,
        ),
      );
      await tester.pumpAndSettle();
      expect(changes.last.audioMix.masterVolume, closeTo(before, .001));
    },
  );

  testWidgets('control binding conflict never writes the profile', (
    tester,
  ) async {
    final changes = <PlayerControlProfile>[];
    await _pump(tester, onControlChanged: changes.add);
    await _category(tester, 'controls');
    await _tap(tester, 'options-binding-primary-choice');
    await _tap(tester, 'options-choice-escape');
    expect(changes, isEmpty);
    expect(find.text('Cette entrée est déjà utilisée.'), findsOneWidget);
  });

  testWidgets(
    'control persistence waits and restores the confirmed binding on failure',
    (tester) async {
      final completion = Completer<void>();
      await _pump(tester, onControlChanged: (_) => completion.future);
      await _category(tester, 'controls');
      await _tap(tester, 'options-binding-primary-choice');
      await _tap(tester, 'options-choice-space');
      expect(
        tester
            .widget<PlayerMenuSelectableRow>(
              find.byKey(const ValueKey('options-binding-primary-choice')),
            )
            .semanticValue,
        'E',
      );
      expect(find.byKey(const ValueKey('options-saving')), findsOneWidget);
      completion.completeError(
        const RuntimePlayerOptionsFailure('Le stockage est indisponible.'),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PlayerMenuSelectableRow>(
              find.byKey(const ValueKey('options-binding-primary-choice')),
            )
            .semanticValue,
        'E',
      );
      expect(find.text('Le stockage est indisponible.'), findsOneWidget);
    },
  );

  testWidgets(
    'device binding reset requires confirmation and preserves other devices',
    (tester) async {
      final changes = <PlayerControlProfile>[];
      final profile = PlayerControlProfile.standard
          .rebind(
            device: PlayerControlDevice.keyboard,
            control: RuntimeInputControl.primary,
            inputId: 'space',
          )
          .profile;
      await _pump(tester, profile: profile, onControlChanged: changes.add);
      await _category(tester, 'controls');
      await _tap(tester, 'options-controls-reset');
      await _tap(tester, 'options-reset-cancel');
      expect(changes, isEmpty);
      await _tap(tester, 'options-controls-reset');
      await _tap(tester, 'options-reset-confirm');
      expect(changes.single.keyboard, PlayerControlProfile.standard.keyboard);
      expect(changes.single.gamepad, profile.gamepad);
      expect(changes.single.touch, profile.touch);
    },
  );
}

const _categories = [
  'general',
  'display',
  'audio',
  'controls',
  'language',
  'accessibility',
];
const _preferences = PlayerPreferencesSnapshot(
  locale: 'fr',
  accessibility: GameSessionAccessibilityOptions(),
);

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  Finder scope = find.byKey(const ValueKey('options-settings'));
  if (key.startsWith('options-category-')) {
    scope = find.byKey(const ValueKey('options-categories'));
  }
  if (key.startsWith('options-choice-')) scope = find.byType(Dialog);
  for (var i = 0; finder.hitTestable().evaluate().isEmpty && i < 30; i++) {
    final next = find
        .descendant(
          of: scope,
          matching: find.byKey(const ValueKey('player-page-next')),
        )
        .hitTestable();
    final enabled = next
        .evaluate()
        .where((e) => (e.widget as IconButton).onPressed != null)
        .toList();
    if (enabled.isEmpty) {
      final previous = find
          .descendant(
            of: scope,
            matching: find.byKey(const ValueKey('player-page-previous')),
          )
          .hitTestable();
      final backs = previous
          .evaluate()
          .where((e) => (e.widget as IconButton).onPressed != null)
          .toList();
      if (backs.isEmpty) break;
      while (backs.isNotEmpty) {
        await tester.tap(find.byWidget(backs.first.widget));
        await tester.pumpAndSettle();
        backs.clear();
        backs.addAll(
          previous.evaluate().where(
            (e) => (e.widget as IconButton).onPressed != null,
          ),
        );
      }
    } else {
      await tester.tap(find.byWidget(enabled.first.widget));
      await tester.pumpAndSettle();
    }
  }
  expect(finder.hitTestable(), findsOneWidget, reason: key);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _category(WidgetTester tester, String category) async {
  if (find.byKey(ValueKey('options-category-$category')).evaluate().isEmpty &&
      find
          .byKey(const ValueKey('options-category-picker'))
          .evaluate()
          .isNotEmpty) {
    await _tap(tester, 'options-category-picker');
  }
  await _tap(tester, 'options-category-$category');
}

Future<void> _pump(
  WidgetTester tester, {
  PlayerPreferencesSnapshot preferences = _preferences,
  PlayerPreferencesSnapshot defaultPreferences = _preferences,
  ValueNotifier<PlayerPreferencesSnapshot>? notifier,
  FutureOr<void> Function(PlayerPreferencesSnapshot)? onChanged,
  FutureOr<void> Function(PlayerControlProfile)? onControlChanged,
  PlayerControlProfile? profile,
  PlayerInputSource activeInputSource = PlayerInputSource.keyboard,
  VoidCallback? onReturnToTitle,
  Size size = const Size(1440, 900),
  double scale = 1,
  double? localScale,
}) async {
  await _loadFonts(tester);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  Widget build(PlayerPreferencesSnapshot current) => MaterialApp(
    locale: Locale(current.locale),
    localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
    supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
    theme: PokeMapPlayerTheme.dark().copyWith(platform: TargetPlatform.macOS),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: PlayerMenuThemeScope(
      child: Scaffold(
        body: RuntimePlayerPauseShell(
          gameTitle: 'Le train de 17h42',
          pauseSection: RuntimePlayerPauseSection.options,
          actions: {
            for (final action in PlayerPauseAction.values)
              action: PlayerActionAvailability.enabled,
          },
          onSelected: (_) {},
          onBackToRoot: () {},
          presentation: const PlayerPausePresentation(
            style: ProjectPauseMenuStyle.nightIllustrated,
          ),
          detailOwnsScroll: true,
          detail: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: localScale == null
                    ? MediaQuery.textScalerOf(context)
                    : TextScaler.linear(localScale),
              ),
              child: RuntimePlayerDetailRouter(
                snapshot: RuntimePlayerSnapshot(
                  revision: 1,
                  phase: RuntimePlayerPhase.paused,
                  gameTitle: 'Voyage',
                  pauseSection: RuntimePlayerPauseSection.options,
                  preferences: current,
                  defaultPreferences: defaultPreferences,
                  actions: const [
                    RuntimePlayerActionAvailability.enabled(
                      RuntimePlayerAction.openOptions,
                    ),
                    RuntimePlayerActionAvailability.enabled(
                      RuntimePlayerAction.updatePreferences,
                    ),
                  ],
                ),
                onPreferencesChanged: onChanged ?? (_) {},
                onReturnToTitle: onReturnToTitle,
                controlProfile: profile,
                activeInputSource: activeInputSource,
                onControlProfileChanged: onControlChanged,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpWidget(
    notifier == null
        ? build(preferences)
        : ValueListenableBuilder<PlayerPreferencesSnapshot>(
            valueListenable: notifier,
            builder: (context, value, child) => build(value),
          ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpIntegrated(
  WidgetTester tester,
  Size size, {
  PlayerInputSource input = PlayerInputSource.controller,
  double scale = 1,
  PlayerPreferencesSnapshot preferences = _preferences,
}) async {
  await _loadFonts(tester);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  final insets = size.width > 600
      ? const EdgeInsets.fromLTRB(59, 0, 59, 21)
      : EdgeInsets.zero;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: insets,
          viewPadding: insets,
          textScaler: TextScaler.linear(scale),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            final router = RuntimePlayerSurfaceRouter(
              snapshot: RuntimePlayerSnapshot(
                revision: 1,
                phase: RuntimePlayerPhase.paused,
                gameTitle: 'Aube',
                pauseSection: RuntimePlayerPauseSection.options,
                preferences: preferences,
                actions: [
                  RuntimePlayerActionAvailability.enabled(
                    RuntimePlayerAction.openOptions,
                  ),
                  RuntimePlayerActionAvailability.enabled(
                    RuntimePlayerAction.updatePreferences,
                  ),
                ],
              ),
              titlePresentation: const RuntimePlayerTitlePresentation(
                author: 'MENU8',
              ),
              pausePresentation: const PlayerPausePresentation(
                style: ProjectPauseMenuStyle.nightIllustrated,
              ),
              activeInputSource: input,
              hardwareGamepadEnabled: true,
              gameSceneBuilder: (_) => const SizedBox.expand(),
              onAction: (_) async => const RuntimePlayerCommandResult(
                status: RuntimePlayerCommandStatus.accepted,
              ),
              onPreferencesChanged: (_) {},
              onControlProfileChanged: (_) {},
            );
            return size.width == 496
                ? PlayerCompanionScope(child: router)
                : router;
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

bool _fontsLoaded = false;

Future<void> _loadFonts(WidgetTester tester) async {
  if (_fontsLoaded) return;
  final loaded = await tester.runAsync(() async {
    await (FontLoader(
      'packages/map_player_ui/PokeMapSplashDMSans',
    )..addFont(rootBundle.load('assets/fonts/DMSans-Variable.ttf'))).load();
    return true;
  });
  expect(loaded, isTrue);
  _fontsLoaded = true;
}
