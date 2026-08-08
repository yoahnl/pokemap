import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/features/appearance/domain/entities/avelune_appearance_preferences.dart';
import 'package:pokemap_hub/presentation/features/home/widgets/avelune_cartridge.dart';
import 'package:pokemap_hub/presentation/theme/avelune_theme.dart';
import 'package:pokemap_hub/presentation/features/home/pages/avelune_home_screen.dart';
import 'package:pokemap_hub/presentation/features/home/state/avelune_home_view_data.dart';
import 'package:pokemap_hub/presentation/design_system/motion/avelune_feedback.dart';

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
    expect(
      find.byKey(
        const ValueKey<String>(
          'avelune-game-shelf-item-games.exchange.0',
        ),
      ),
      findsNothing,
      reason: 'The hero game must not have a second physical cartridge.',
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
    final oldCartridge = find.byKey(
      const ValueKey<String>('avelune-exchange-old-cartridge'),
    );
    final newCartridge = find.byKey(
      const ValueKey<String>('avelune-exchange-new-cartridge'),
    );
    expect(
      tester
          .widget<Opacity>(
            find
                .ancestor(of: oldCartridge, matching: find.byType(Opacity))
                .first,
          )
          .opacity,
      1,
      reason: 'A physical cartridge must not dissolve during the swap.',
    );
    expect(
      tester
          .widget<Opacity>(
            find
                .ancestor(of: newCartridge, matching: find.byType(Opacity))
                .first,
          )
          .opacity,
      1,
      reason: 'The incoming cartridge must remain tangible during the swap.',
    );
    expect(
      tester.getRect(oldCartridge).overlaps(tester.getRect(newCartridge)),
      isFalse,
      reason: 'The cartridges need separate arcs instead of merging halfway.',
    );
    final oldProgress =
        (tester.getRect(oldCartridge).center - heroBefore.center).distance /
            (targetBefore.center - heroBefore.center).distance;
    final newProgress =
        (tester.getRect(newCartridge).center - targetBefore.center).distance /
            (heroBefore.center - targetBefore.center).distance;
    expect(
      oldProgress,
      inInclusiveRange(0.35, 0.7),
      reason: 'Half the duration must read as half the physical trip.',
    );
    expect(newProgress, inInclusiveRange(0.35, 0.7));
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
    expect(
      connectorOpacities,
      everyElement(1),
      reason: 'The canonical cartridge stays physically complete in flight.',
    );

    await tester.pump(const Duration(milliseconds: 220));
    await tester.pumpAndSettle();
    expect(overlay, findsNothing);
    expect(
      _heroCartridge(tester).gameId,
      'games.exchange.1',
    );
    expect(
      find.byKey(
        const ValueKey<String>(
          'avelune-game-shelf-item-games.exchange.1',
        ),
      ),
      findsNothing,
      reason: 'The new hero must leave its shelf slot completely.',
    );
    final returnedSource = find.descendant(
      of: find.byKey(
        const ValueKey<String>(
          'avelune-game-shelf-item-games.exchange.0',
        ),
      ),
      matching: find.byType(AveluneCartridge),
    );
    expect(returnedSource, findsOneWidget);
    expect(
      tester.getRect(returnedSource),
      targetBefore,
      reason: 'The outgoing hero must occupy the chosen cartridge slot.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('hero copy enters from the right in staggered paragraphs',
      (tester) async {
    await _pumpHome(
      tester,
      onGameSelected: (_) {},
      feedback: _RecordingFeedback(),
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('avelune-game-shelf-item-games.exchange.1'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 440));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 120));

    final title = find.byKey(
      const ValueKey<String>('avelune-hero-details-reveal-title'),
    );
    final subtitle = find.byKey(
      const ValueKey<String>('avelune-hero-details-reveal-subtitle'),
    );
    final author = find.byKey(
      const ValueKey<String>('avelune-hero-details-reveal-author'),
    );
    expect(title, findsOneWidget);
    expect(subtitle, findsOneWidget);
    expect(author, findsOneWidget);

    final titleOpacity = _revealOpacity(tester, title);
    final subtitleOpacity = _revealOpacity(tester, subtitle);
    final authorOpacity = _revealOpacity(tester, author);
    expect(titleOpacity, greaterThan(subtitleOpacity));
    expect(subtitleOpacity, greaterThan(authorOpacity));
    expect(_revealOffset(tester, title).dx, lessThan(0.08));
    expect(_revealOffset(tester, author).dx, greaterThan(0.08));

    await tester.pumpAndSettle();
    expect(_revealOpacity(tester, title), 1);
    expect(_revealOpacity(tester, subtitle), 1);
    expect(_revealOpacity(tester, author), 1);
    expect(_revealOffset(tester, author), Offset.zero);
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

double _revealOpacity(WidgetTester tester, Finder reveal) => tester
    .widget<FadeTransition>(
      find.descendant(of: reveal, matching: find.byType(FadeTransition)),
    )
    .opacity
    .value;

Offset _revealOffset(WidgetTester tester, Finder reveal) =>
    tester.widget<SlideTransition>(reveal).position.value;

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
