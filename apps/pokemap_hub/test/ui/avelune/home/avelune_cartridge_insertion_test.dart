import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/src/ui/avelune/appearance/avelune_appearance_preferences.dart';
import 'package:pokemap_hub/src/ui/avelune/avelune_cartridge.dart';
import 'package:pokemap_hub/src/ui/avelune/avelune_console.dart';
import 'package:pokemap_hub/src/ui/avelune/avelune_theme.dart';
import 'package:pokemap_hub/src/ui/avelune/home/avelune_home_screen.dart';
import 'package:pokemap_hub/src/ui/avelune/home/avelune_home_view_data.dart';
import 'package:pokemap_hub/src/ui/avelune/home/avelune_room_scene.dart';
import 'package:pokemap_hub/src/ui/avelune/motion/avelune_feedback.dart';

// Phase lengths come from the tokens rather than being copied here: the
// insertion was re-paced to let the console's LED sequence read, and hardcoded
// durations silently rotted when it changed.
const _standard = AveluneMotionTokens.standard;
const _reduced = AveluneMotionTokens.reduced;

void main() {
  testWidgets('continue launches only after physical latch', (tester) async {
    final feedback = _RecordingFeedback();
    var continueCalls = 0;
    var newGameCalls = 0;
    await _pumpHome(
      tester,
      game: _game(action: AvelunePrimaryAction.continueGame),
      feedback: feedback,
      onContinue: (_) => continueCalls++,
      onNewGame: (_) => newGameCalls++,
    );

    final semantics = tester.getSemantics(_hero);
    expect(semantics.label, contains('Continue Jeu test'));

    await tester.tap(_hero);
    await tester.pump();
    await tester.pump();
    expect(_insertionOverlay, findsOneWidget);
    expect(continueCalls, 0);

    await tester.pump(_standard.insertionAlign);
    await tester.pump();
    expect(continueCalls, 0);
    await tester.pump(_standard.insertionDescend);
    await tester.pump();
    expect(continueCalls, 0);
    expect(feedback.cues, contains(AveluneFeedbackCue.latch));
    expect(
      tester.widget<AveluneConsole>(find.byType(AveluneConsole)).state,
      AveluneConsoleState.latched,
    );

    await tester.pump(_standard.insertionLatch);
    await tester.pump();
    // Swallowed by the slot only once the cartridge is seated.
    expect(
      tester
          .widget<AveluneCartridge>(
            find.descendant(
              of: _insertionOverlay,
              matching: find.byType(AveluneCartridge),
            ),
          )
          .connectorsOpacity,
      0,
    );
    expect(continueCalls, 0);

    await tester.pump(_standard.insertionLaunchDelay - _oneFrame);
    expect(
      continueCalls,
      0,
      reason: 'The console still has to finish booting before the game starts.',
    );
    await tester.pump(_oneFrame);
    await tester.pump();
    expect(continueCalls, 1);
    expect(newGameCalls, 0);
    expect(
      feedback.cues,
      <AveluneFeedbackCue>[
        AveluneFeedbackCue.align,
        AveluneFeedbackCue.latch,
      ],
    );
  });

  testWidgets('play uses new-game flow and double tap launches once',
      (tester) async {
    var continueCalls = 0;
    var newGameCalls = 0;
    await _pumpHome(
      tester,
      game: _game(action: AvelunePrimaryAction.play),
      feedback: _RecordingFeedback(),
      onContinue: (_) => continueCalls++,
      onNewGame: (_) => newGameCalls++,
    );

    await tester.tap(_hero);
    await tester.tap(_hero);
    await _completeInsertion(tester);

    expect(continueCalls, 0);
    expect(newGameCalls, 1);
  });

  testWidgets('invalid import disabled and missing actions block insertion',
      (tester) async {
    var launches = 0;

    await _pumpHome(
      tester,
      game: _game(
        action: AvelunePrimaryAction.continueGame,
        validity: AveluneGameValidity.invalid,
      ),
      feedback: _RecordingFeedback(),
      onContinue: (_) => launches++,
    );
    expect(_heroWidget(tester).onPressed, isNull);

    await _pumpHome(
      tester,
      game: _game(action: AvelunePrimaryAction.continueGame),
      importing: true,
      feedback: _RecordingFeedback(),
      onContinue: (_) => launches++,
    );
    expect(_heroWidget(tester).onPressed, isNull);

    await _pumpHome(
      tester,
      game: _game(action: AvelunePrimaryAction.disabled),
      feedback: _RecordingFeedback(),
      onContinue: (_) => launches++,
      onNewGame: (_) => launches++,
    );
    expect(_heroWidget(tester).onPressed, isNull);

    await _pumpHome(
      tester,
      game: _game(action: AvelunePrimaryAction.play),
      feedback: _RecordingFeedback(),
    );
    expect(_heroWidget(tester).onPressed, isNull);
    expect(launches, 0);
    expect(_insertionOverlay, findsNothing);
  });

  testWidgets('launch error preserves selection and permits retry',
      (tester) async {
    var attempts = 0;
    final errors = <Object>[];
    await _pumpHome(
      tester,
      game: _game(action: AvelunePrimaryAction.continueGame),
      feedback: _RecordingFeedback(),
      onContinue: (_) {
        attempts++;
        if (attempts == 1) throw StateError('invalid save');
      },
      onLaunchError: (_, error) => errors.add(error),
    );

    await tester.tap(_hero);
    await _completeInsertion(tester);
    // A failed launch recovers after one selection beat before the hero is
    // pressable again.
    await tester.pump(_standard.selection);
    await tester.pump();
    expect(attempts, 1);
    expect(errors.single, isA<StateError>());
    expect(
      find.byKey(const ValueKey<String>('avelune-launch-error-notice')),
      findsOneWidget,
    );
    expect(_heroWidget(tester).gameId, 'games.insertion.test');

    await tester.tap(_hero);
    await _completeInsertion(tester);
    expect(attempts, 2);
    expect(errors, hasLength(1));
    expect(
      find.byKey(const ValueKey<String>('avelune-launch-error-notice')),
      findsNothing,
    );
    expect(_heroWidget(tester).gameId, 'games.insertion.test');
  });

  testWidgets('the descending cartridge is swallowed by the slot mouth',
      (tester) async {
    await _pumpHome(
      tester,
      game: _game(action: AvelunePrimaryAction.play),
      feedback: _RecordingFeedback(),
      onNewGame: (_) {},
    );

    await tester.tap(_hero);
    await tester.pump();
    await tester.pump();
    await tester.pump(_standard.insertionAlign);
    await tester.pump();

    final scene = tester.widget<AveluneRoomScene>(
      find.byType(AveluneRoomScene),
    );
    final clip = tester.widget<ClipRect>(
      find.byKey(const ValueKey<String>('avelune-slot-mouth-clip')),
    );
    final overlay = find.descendant(
      of: find.byKey(const ValueKey<String>('avelune-slot-mouth-clip')),
      matching: _insertionOverlay,
    );

    expect(
      overlay,
      findsOneWidget,
      reason: 'The cartridge has to be painted over the console and clipped, '
          'not tucked behind the whole hardware where it vanishes at the top '
          'silhouette instead of at the opening.',
    );
    final mouth = clip.clipper!.getClip(const Size(390, 844)).bottom;
    expect(mouth, closeTo(scene.geometry.consoleSlotMouthY, 0.01));
    expect(
      mouth,
      greaterThan(scene.geometry.consoleRect.top),
      reason: 'The mouth sits inside the console, on its top deck.',
    );

    // Drain the sequence so no timer outlives the tree.
    await tester.pump(_standard.insertionDescend);
    await tester.pump(_standard.insertionLatch);
    await tester.pump(_standard.insertionLaunchDelay);
    await tester.pump();
  });

  testWidgets('reduced motion latches and launches in 120 ms', (tester) async {
    var launches = 0;
    await _pumpHome(
      tester,
      game: _game(action: AvelunePrimaryAction.play),
      feedback: _RecordingFeedback(),
      disableAnimations: true,
      onNewGame: (_) => launches++,
    );

    await tester.tap(_hero);
    await tester.pump();
    await tester.pump();
    await tester.pump(_reduced.insertionDescend - _oneFrame);
    expect(launches, 0);
    await tester.pump(_oneFrame);
    await tester.pump();
    expect(launches, 1);
  });

  testWidgets('route replacement and dispose do not cause a late launch',
      (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    var launches = 0;
    await _pumpHome(
      tester,
      game: _game(action: AvelunePrimaryAction.play),
      feedback: _RecordingFeedback(),
      navigatorKey: navigatorKey,
      onNewGame: (_) {
        launches++;
        unawaited(
          navigatorKey.currentState!.pushReplacement<void, void>(
            MaterialPageRoute<void>(
              builder: (_) => const SizedBox(key: ValueKey('runtime-route')),
            ),
          ),
        );
      },
    );

    await tester.tap(_hero);
    await _completeInsertion(tester);
    expect(launches, 1);
    expect(find.byKey(const ValueKey<String>('runtime-route')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _pumpHome(
      tester,
      game: _game(action: AvelunePrimaryAction.play),
      feedback: _RecordingFeedback(),
      onNewGame: (_) => launches++,
    );
    await tester.tap(_hero);
    await tester.pump(_standard.insertionAlign);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    expect(launches, 1);
    expect(tester.takeException(), isNull);
  });
}

final _hero = find.byKey(
  const ValueKey<String>('avelune-room-hero-cartridge'),
);
final _insertionOverlay = find.byKey(
  const ValueKey<String>('avelune-cartridge-insertion-overlay'),
);

AveluneCartridge _heroWidget(WidgetTester tester) =>
    tester.widget<AveluneCartridge>(_hero);

Future<void> _pumpHome(
  WidgetTester tester, {
  required AveluneGameViewData game,
  required AveluneFeedback feedback,
  AveluneGameLaunchCallback? onContinue,
  AveluneGameLaunchCallback? onNewGame,
  AveluneLaunchErrorCallback? onLaunchError,
  GlobalKey<NavigatorState>? navigatorKey,
  bool importing = false,
  bool disableAnimations = false,
}) async {
  const size = Size(390, 844);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final theme = AveluneThemeData.standard.applyTo(ThemeData.dark());

  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigatorKey,
      theme: theme,
      home: MediaQuery(
        data: const MediaQueryData(
          size: size,
          padding: EdgeInsets.only(top: 47, bottom: 34),
        ).copyWith(disableAnimations: disableAnimations),
        child: AveluneHomeScreen(
          viewData: _viewData(
            game,
            importing: importing,
            reducedMotion: disableAnimations,
          ),
          appearance: const AveluneAppearancePreferences(),
          feedback: feedback,
          onContinue: onContinue,
          onNewGame: onNewGame,
          onLaunchError: onLaunchError,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

AveluneHomeViewData _viewData(
  AveluneGameViewData game, {
  required bool importing,
  required bool reducedMotion,
}) =>
    AveluneHomeViewData(
      status: importing ? AveluneHomeStatus.importing : AveluneHomeStatus.ready,
      games: <AveluneGameViewData>[game],
      selectedGameId: game.id,
      recentActivity: const <AveluneRecentActivityViewData>[],
      import: importing
          ? const AveluneImportViewData(
              isImporting: true,
              canStart: false,
              completedFiles: 1,
              totalFiles: 2,
              cancellable: false,
            )
          : const AveluneImportViewData.idle(canStart: true),
      safeErrorMessage: null,
      reducedMotion: reducedMotion,
    );

AveluneGameViewData _game({
  required AvelunePrimaryAction action,
  AveluneGameValidity validity = AveluneGameValidity.available,
}) =>
    AveluneGameViewData(
      id: 'games.insertion.test',
      title: 'Jeu test',
      subtitle: 'Studio Avelune',
      authorName: 'Studio Avelune',
      artwork: const AveluneArtworkViewData(
        kind: AveluneArtworkKind.fallback,
      ),
      shellColor: const Color(0xFF633C88),
      validity: validity,
      primaryAction: action,
      isSelected: true,
      lastSaveAt: action == AvelunePrimaryAction.continueGame
          ? DateTime(2026, 8, 5, 9)
          : null,
      playTimeSeconds: 120,
    );

final class _RecordingFeedback implements AveluneFeedback {
  final List<AveluneFeedbackCue> cues = <AveluneFeedbackCue>[];

  @override
  void emit(AveluneFeedbackCue cue) => cues.add(cue);
}

const _oneFrame = Duration(milliseconds: 1);

/// Walks the whole insertion sequence.
///
/// `pumpAndSettle` cannot be used for this: the controller waits on
/// `Future.delayed` between phases, and a pending timer schedules no frame, so
/// settling returns in the middle of the sequence and the launch never happens.
Future<void> _completeInsertion(
  WidgetTester tester, {
  AveluneMotionTokens motion = _standard,
}) async {
  // The screen awaits `endOfFrame` before starting the controller, so the
  // sequence only begins once a frame has been produced.
  await tester.pump();
  await tester.pump();
  for (final phase in <Duration>[
    motion.insertionAlign,
    motion.insertionDescend,
    motion.insertionLatch,
    motion.insertionLaunchDelay,
  ]) {
    await tester.pump(phase);
    await tester.pump();
  }
  await tester.pump();
}
