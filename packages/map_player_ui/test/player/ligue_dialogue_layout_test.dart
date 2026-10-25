import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  for (final dark in [false, true]) {
    for (final mode in [
      (
        scale: 1.0,
        companion: false,
        name: 'landscape-touch',
        size: const Size(844, 390),
        padding: const EdgeInsets.fromLTRB(44, 12, 44, 20),
        source: PlayerInputSource.touch,
      ),
      (
        scale: 1.0,
        companion: false,
        name: 'landscape-controller',
        size: const Size(844, 390),
        padding: const EdgeInsets.fromLTRB(44, 12, 44, 20),
        source: PlayerInputSource.controller,
      ),
      (
        scale: 1.0,
        companion: false,
        name: 'portrait-touch',
        size: const Size(390, 844),
        padding: const EdgeInsets.fromLTRB(0, 32, 0, 24),
        source: PlayerInputSource.touch,
      ),
      (
        scale: 1.0,
        companion: false,
        name: 'portrait-controller',
        size: const Size(390, 844),
        padding: const EdgeInsets.fromLTRB(0, 32, 0, 24),
        source: PlayerInputSource.controller,
      ),
      (
        scale: 1.0,
        companion: false,
        name: 'thor-primary',
        size: const Size(768, 432),
        padding: EdgeInsets.zero,
        source: PlayerInputSource.controller,
      ),
      (
        scale: 1.0,
        companion: true,
        name: 'thor-companion',
        size: const Size(496, 432),
        padding: EdgeInsets.zero,
        source: PlayerInputSource.controller,
      ),
      (
        scale: 2.0,
        companion: true,
        name: 'thor-companion-text2',
        size: const Size(496, 432),
        padding: EdgeInsets.zero,
        source: PlayerInputSource.controller,
      ),
    ]) {
      testWidgets('Ligue dialogue frame ${mode.name} dark=$dark', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(mode.size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            theme: dark
                ? PokeMapPlayerTheme.dark(reducedMotion: true)
                : PokeMapPlayerTheme.light(reducedMotion: true),
            home: MediaQuery(
              data: MediaQueryData(
                size: mode.size,
                padding: mode.padding,
                textScaler: TextScaler.linear(mode.scale),
              ),
              child: PlayerInputScope(
                activeInputSource: mode.source,
                child: Builder(
                  builder: (context) {
                    final dialogue = PlayerDialogueSurface(
                      data: const PlayerDialogueViewData(
                        revision: 1,
                        mode: PlayerDialogueMode.line,
                        speaker: 'Léa',
                        text: 'Prépare ton équipe avant de partir.',
                        fullText: 'Prépare ton équipe avant de partir.',
                        isCurrentLineFullyRevealed: true,
                        isLastContent: false,
                        choices: [],
                      ),
                      onAction: (_) {},
                    );
                    return mode.companion
                        ? PlayerCompanionScope(child: dialogue)
                        : dialogue;
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final panel = find.byKey(const ValueKey('player-dialogue-ligue-panel'));
        final rect = tester.getRect(panel);
        final landscape = mode.size.width > mode.size.height && !mode.companion;
        expect(rect.left, landscape ? 44 : 16);
        expect(rect.right, mode.size.width - (landscape ? 44 : 16));
        expect(
          rect.bottom,
          mode.size.height -
              (mode.padding.bottom > 0 ? mode.padding.bottom : 16),
        );
        final decoration =
            tester.widget<DecoratedBox>(panel).decoration as BoxDecoration;
        final border = decoration.border! as Border;
        final colors = PokeMapPlayerMenuTheme.resolve(
          tester.element(panel),
          opaque: true,
        );
        expect(decoration.color, colors.base);
        expect(border.left.color, colors.accent);
        expect(border.left.width, 5);
        expect(decoration.borderRadius, BorderRadius.circular(3));
        expect(decoration.boxShadow, isNull);
        final advance = tester.getRect(
          find.byKey(const ValueKey('player-dialogue-ligue-advance')),
        );
        expect(advance.height, greaterThanOrEqualTo(48));
        expect(advance.left, greaterThan(rect.left));
        expect(advance.right, lessThan(rect.right));
        if (mode.companion) {
          expect(rect.top, 16);
          expect(rect.height, 400);
          final counter = find.byKey(const ValueKey('dialogue-page-count'));
          if (counter.evaluate().isEmpty) {
            expect(advance.width, greaterThan(rect.width * .8));
          } else {
            final counterRect = tester.getRect(counter);
            expect(counterRect.right + 8, closeTo(advance.left, .5));
            expect(counterRect.width, lessThan(advance.width));
            expect(advance.width, greaterThanOrEqualTo(48));
            expect(
              advance.right - counterRect.left,
              greaterThan(rect.width * .8),
            );
          }
          final speaker = tester.getRect(find.text('Léa'));
          expect(
            (speaker.top + advance.bottom) / 2,
            closeTo(rect.center.dy, 12),
          );
        }
        expect(find.byType(Scrollable), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
