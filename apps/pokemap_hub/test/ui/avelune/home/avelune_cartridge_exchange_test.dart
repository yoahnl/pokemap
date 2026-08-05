import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/src/ui/avelune/appearance/avelune_appearance_preferences.dart';
import 'package:pokemap_hub/src/ui/avelune/avelune_cartridge.dart';
import 'package:pokemap_hub/src/ui/avelune/avelune_theme.dart';
import 'package:pokemap_hub/src/ui/avelune/home/avelune_home_screen.dart';
import 'package:pokemap_hub/src/ui/avelune/home/avelune_home_view_data.dart';
import 'package:pokemap_hub/src/ui/avelune/motion/avelune_feedback.dart';

void main() {
  testWidgets('exchange uses measured anchors and commits at midpoint',
      (tester) async {
    final commits = <String>[];
    final feedback = _RecordingFeedback();
    await _pumpHome(
      tester,
      onGameSelected: (game) => commits.add(game.id),
      feedback: feedback,
    );

    final heroBefore = tester.getRect(
      find.byKey(const ValueKey<String>('avelune-room-hero-cartridge')),
    );
    final targetItem = find.byKey(
      const ValueKey<String>('avelune-game-shelf-item-games.exchange.1'),
    );
    final targetBefore = tester.getRect(
      find.descendant(
        of: targetItem,
        matching: find.byType(AveluneCartridge),
      ),
    );

    await tester.tap(targetItem);
    await tester.pump();

    final overlay = find.byKey(
      const ValueKey<String>('avelune-cartridge-exchange-overlay'),
    );
    expect(overlay, findsOneWidget);
    expect(
      tester.getRect(
        find.byKey(const ValueKey<String>('avelune-exchange-old-cartridge')),
      ),
      heroBefore,
    );
    expect(
      tester.getRect(
        find.byKey(const ValueKey<String>('avelune-exchange-new-cartridge')),
      ),
      targetBefore,
    );
    expect(commits, isEmpty);

    await tester.pump(const Duration(milliseconds: 220));
    expect(commits, <String>['games.exchange.1']);
    expect(feedback.cues, <AveluneFeedbackCue>[
      AveluneFeedbackCue.selection,
    ]);
    final connectorOpacities = tester
        .widgetList<Opacity>(
          find.descendant(
            of: overlay,
            matching: find.byKey(
              const ValueKey<String>(
                'avelune-cartridge-connectors-opacity',
              ),
            ),
          ),
        )
        .map((widget) => widget.opacity);
    expect(connectorOpacities, everyElement(0));

    await tester.pump(const Duration(milliseconds: 220));
    await tester.pumpAndSettle();
    expect(overlay, findsNothing);
    expect(
      _heroCartridge(tester).gameId,
      'games.exchange.1',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion cross-fades in 120 ms without moving',
      (tester) async {
    final commits = <String>[];
    await _pumpHome(
      tester,
      disableAnimations: true,
      onGameSelected: (game) => commits.add(game.id),
      feedback: _RecordingFeedback(),
    );
    final heroRect = tester.getRect(
      find.byKey(const ValueKey<String>('avelune-room-hero-cartridge')),
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('avelune-game-shelf-item-games.exchange.1'),
      ),
    );
    await tester.pump();
    expect(
      tester.getRect(
        find.byKey(const ValueKey<String>('avelune-exchange-old-cartridge')),
      ),
      heroRect,
    );
    expect(
      tester.getRect(
        find.byKey(const ValueKey<String>('avelune-exchange-new-cartridge')),
      ),
      heroRect,
    );

    await tester.pump(const Duration(milliseconds: 60));
    expect(commits, <String>['games.exchange.1']);
    expect(
      find.byKey(const ValueKey<String>('avelune-cartridge-exchange-overlay')),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('avelune-cartridge-exchange-overlay')),
      findsNothing,
    );
  });

  testWidgets('rapid taps retain only the latest requested cartridge',
      (tester) async {
    final commits = <String>[];
    final feedback = _RecordingFeedback();
    await _pumpHome(
      tester,
      onGameSelected: (game) => commits.add(game.id),
      feedback: feedback,
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('avelune-game-shelf-item-games.exchange.1'),
      ),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(
        const ValueKey<String>('avelune-game-shelf-item-games.exchange.2'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 440));
    await tester.pump();

    expect(commits, <String>['games.exchange.2']);
    expect(_heroCartridge(tester).gameId, 'games.exchange.2');
    expect(
      feedback.cues.where((cue) => cue == AveluneFeedbackCue.selection),
      hasLength(1),
    );
  });

  testWidgets('dispose during exchange does not commit or throw',
      (tester) async {
    final commits = <String>[];
    await _pumpHome(
      tester,
      onGameSelected: (game) => commits.add(game.id),
      feedback: _RecordingFeedback(),
    );
    await tester.tap(
      find.byKey(
        const ValueKey<String>('avelune-game-shelf-item-games.exchange.1'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 80));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));

    expect(commits, isEmpty);
    expect(tester.takeException(), isNull);
  });
}

AveluneCartridge _heroCartridge(WidgetTester tester) =>
    tester.widget<AveluneCartridge>(
      find.byKey(const ValueKey<String>('avelune-room-hero-cartridge')),
    );

Future<void> _pumpHome(
  WidgetTester tester, {
  required ValueChanged<AveluneGameViewData> onGameSelected,
  required AveluneFeedback feedback,
  bool disableAnimations = false,
}) async {
  const size = Size(390, 844);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final theme = AveluneThemeData.standard.applyTo(ThemeData.dark());

  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: MediaQuery(
        data: const MediaQueryData(
          size: size,
          padding: EdgeInsets.only(top: 47, bottom: 34),
        ).copyWith(disableAnimations: disableAnimations),
        child: AveluneHomeScreen(
          viewData: _viewData(reducedMotion: disableAnimations),
          appearance: const AveluneAppearancePreferences(),
          feedback: feedback,
          onGameSelected: onGameSelected,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

AveluneHomeViewData _viewData({required bool reducedMotion}) {
  final games = List<AveluneGameViewData>.generate(3, _game);
  return AveluneHomeViewData(
    status: AveluneHomeStatus.ready,
    games: games,
    selectedGameId: games.first.id,
    recentActivity: const <AveluneRecentActivityViewData>[],
    import: const AveluneImportViewData.idle(canStart: true),
    safeErrorMessage: null,
    reducedMotion: reducedMotion,
  );
}

AveluneGameViewData _game(int index) => AveluneGameViewData(
      id: 'games.exchange.$index',
      title: 'Jeu $index',
      subtitle: 'Studio Avelune',
      authorName: 'Studio Avelune',
      artwork: const AveluneArtworkViewData(
        kind: AveluneArtworkKind.fallback,
      ),
      shellColor:
          index.isEven ? const Color(0xFF633C88) : const Color(0xFF126E78),
      validity: AveluneGameValidity.available,
      primaryAction: AvelunePrimaryAction.play,
      isSelected: index == 0,
      lastSaveAt: null,
      playTimeSeconds: 0,
    );

final class _RecordingFeedback implements AveluneFeedback {
  final List<AveluneFeedbackCue> cues = <AveluneFeedbackCue>[];

  @override
  void emit(AveluneFeedbackCue cue) => cues.add(cue);
}
