import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';

/// Nothing outlives an interactive hold — BETA-CIN-084.
///
/// The ticket's user value is that a long read does not turn the phone into a
/// radiator, and the resource that would do it is real: the message dialogue
/// runs a `Timer.periodic` to reveal text a grapheme at a time. A leaked
/// periodic timer is invisible to CIN-038, which counts decoders and media
/// handles, and it keeps calling setState forever.
///
/// This suite is executable and headless on purpose. `testWidgets` fails a test
/// that ends with a pending timer — "A Timer is still pending even after the
/// widget tree was disposed" — so the framework's own leak detector IS the
/// assertion for every exit below. No device, no profile run, no CI cost; the
/// timing half of CIN-084 needs a local device run and is not claimed here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app({
    required SceneInteractionRequest? request,
    required List<SceneInteractionResult> results,
    bool reduceMotion = false,
  }) =>
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: PokeMapPlayerTheme.dark(reducedMotion: reduceMotion),
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: Scaffold(
            body: request == null
                ? const SizedBox.shrink()
                : PlayerSceneInteractionSurface(
                    request: request,
                    onResult: results.add,
                  ),
          ),
        ),
      );

  // The dialogue confirms through its own tap zone, not a bare tap on the
  // surface: the first press completes the reveal, the second answers.
  Finder tapZone() =>
      find.byKey(const ValueKey<String>('dialogue-tap-zone')).first;

  SceneMessageInteractionRequest message(String id, String text) =>
      SceneMessageInteractionRequest(
        requestId: id,
        revision: 1,
        prompt: SceneInteractionPrompt(
          localizationKey: 'hold.$id',
          fallbackText: text,
        ),
      );

  group('the reveal timer does not survive the exit', () {
    testWidgets('route close: the surface leaves the tree mid-reveal',
        (tester) async {
      final results = <SceneInteractionResult>[];
      await tester.pumpWidget(
        app(request: message('m1', _longMessage), results: results),
      );
      // Let the typewriter start but NOT finish, so a live timer exists.
      await tester.pump(const Duration(milliseconds: 60));

      await tester.pumpWidget(app(request: null, results: results));
      await tester.pump();
      // If the timer outlived the unmount, testWidgets fails right here.
    });

    testWidgets('stop: the whole app is replaced mid-reveal', (tester) async {
      final results = <SceneInteractionResult>[];
      await tester.pumpWidget(
        app(request: message('m2', _longMessage), results: results),
      );
      await tester.pump(const Duration(milliseconds: 60));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('skip: a short message is replaced by a longer one mid-reveal',
        (tester) async {
      // The pair is short-THEN-long on purpose. The reveal timer captures the
      // outgoing message's grapheme count in its closure, so if didUpdateWidget
      // does not cancel it, it self-cancels at the SHORT length and the new,
      // longer message stays stranded half-revealed with nothing left to tick
      // it. Two messages of equal length hide that completely — which is how
      // this test was wrong the first time.
      final results = <SceneInteractionResult>[];
      await tester.pumpWidget(
        app(request: message('m3', 'Court.'), results: results),
      );
      await tester.pump(const Duration(milliseconds: 60));

      await tester.pumpWidget(
        app(request: message('m4', _longMessage), results: results),
      );
      await tester.pump(const Duration(seconds: 3));
      expect(
        find.text(_longMessage),
        findsOneWidget,
        reason: 'the longer message finished revealing, so a live timer '
            'carried it to the end',
      );

      await tester.pumpWidget(app(request: null, results: results));
      await tester.pump();
    });

    testWidgets('the reveal self-cancels once the text is whole',
        (tester) async {
      final results = <SceneInteractionResult>[];
      await tester.pumpWidget(
        app(request: message('m5', 'Court.'), results: results),
      );
      // Long enough for every grapheme plus slack: the timer must have
      // cancelled itself, not merely be idle.
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Court.'), findsOneWidget);
    });

    testWidgets('reduced motion never starts a timer at all', (tester) async {
      final results = <SceneInteractionResult>[];
      await tester.pumpWidget(
        app(
          request: message('m6', _longMessage),
          results: results,
          reduceMotion: true,
        ),
      );
      await tester.pump();
      expect(
        find.text(_longMessage),
        findsOneWidget,
        reason: 'the whole text is revealed immediately, so nothing needs to '
            'tick and nothing can leak',
      );
      await tester.pumpWidget(app(request: null, results: results));
      await tester.pump();
    });
  });

  group('fifty consecutive holds leave nothing behind', () {
    testWidgets('the cycle count is what makes a slow leak visible',
        (tester) async {
      // One leaked timer per cycle is easy to miss; fifty is not. This is the
      // headless half of the ticket's "50 cycles" requirement — the timing half
      // needs a device.
      final results = <SceneInteractionResult>[];
      for (var cycle = 0; cycle < 50; cycle += 1) {
        await tester.pumpWidget(
          app(request: message('cycle-$cycle', _longMessage), results: results),
        );
        await tester.pump(const Duration(milliseconds: 40));
        // Complete the reveal, then answer: a real hold ends on an answer.
        await tester.tap(tapZone());
        await tester.pump();
        await tester.tap(tapZone());
        await tester.pump();
      }
      await tester.pumpWidget(app(request: null, results: results));
      await tester.pump();

      expect(
        results.length,
        50,
        reason: 'every one of the fifty holds was really answered, not merely '
            'mounted and thrown away',
      );
    });
  });

  group('an error during a hold still releases the timer', () {
    testWidgets('a throwing result callback does not strand the reveal',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: PokeMapPlayerTheme.dark(),
          home: Scaffold(
            body: PlayerSceneInteractionSurface(
              request: message('boom', _longMessage),
              onResult: (_) => throw StateError('answer handler exploded'),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tap(tapZone());
      await tester.pump();
      await tester.tap(tapZone(), warnIfMissed: false);
      await tester.pump();
      // The handler threw; what matters is that unmounting still releases.
      tester.takeException();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  });
}

const String _longMessage =
    'Le phare tourne depuis cent ans, et cette nuit il est à toi : la lampe, '
    'le registre, la relève au petit matin.';
