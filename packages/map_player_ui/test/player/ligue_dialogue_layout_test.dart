import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  for (final dark in [false, true]) {
    for (final mode in [
      (
        name: 'landscape-touch',
        size: const Size(844, 390),
        padding: const EdgeInsets.fromLTRB(44, 12, 44, 20),
        source: PlayerInputSource.touch,
      ),
      (
        name: 'landscape-controller',
        size: const Size(844, 390),
        padding: const EdgeInsets.fromLTRB(44, 12, 44, 20),
        source: PlayerInputSource.controller,
      ),
      (
        name: 'portrait-touch',
        size: const Size(390, 844),
        padding: const EdgeInsets.fromLTRB(0, 32, 0, 24),
        source: PlayerInputSource.touch,
      ),
      (
        name: 'portrait-controller',
        size: const Size(390, 844),
        padding: const EdgeInsets.fromLTRB(0, 32, 0, 24),
        source: PlayerInputSource.controller,
      ),
      (
        name: 'thor-primary',
        size: const Size(768, 432),
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
              data: MediaQueryData(size: mode.size, padding: mode.padding),
              child: PlayerInputScope(
                activeInputSource: mode.source,
                child: PlayerDialogueSurface(
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
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final panel = find.byKey(const ValueKey('player-dialogue-ligue-panel'));
        final rect = tester.getRect(panel);
        final landscape = mode.size.width > mode.size.height;
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
        expect(find.byType(Scrollable), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
