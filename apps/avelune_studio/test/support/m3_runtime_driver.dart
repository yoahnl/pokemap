import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

class M3RuntimeDriver {
  M3RuntimeDriver(this.tester);
  final WidgetTester tester;
  late PlayableMapGame game;
  Future<void> Function(DialoguePresentationSnapshot)? onPresentation;

  Future<void> ready({PlayableMapGame? previous}) => until(() {
    final finder = find.byType(GameWidget<PlayableMapGame>);
    if (finder.evaluate().isEmpty) return false;
    game = tester.widget<GameWidget<PlayableMapGame>>(finder).game!;
    return game != previous &&
        game.isLoaded &&
        !game.debugIsMapActivationDispatchInFlight;
  });

  Future<void> until(bool Function() done) async {
    for (var i = 0; i < 400; i++) {
      if (done()) return;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 32));
      expect(tester.takeException(), isNull);
    }
    fail('Runtime condition timed out');
  }

  void press(RuntimeInputControl input) {
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(input));
    game.handleRuntimeInputEvent(RuntimeInputEvent.release(input));
  }

  Future<void> walk(RuntimeInputControl input, [int count = 1]) async {
    for (var i = 0; i < count; i++) {
      game.handleRuntimeInputEvent(RuntimeInputEvent.press(input));
      game.update(.016);
      game.handleRuntimeInputEvent(RuntimeInputEvent.release(input));
      game.update(.3);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
    }
  }

  Future<List<String>> talk({int choice = 0}) {
    press(RuntimeInputControl.primary);
    return finishTalk(choice: choice);
  }

  Future<List<String>> finishTalk({int choice = 0}) async {
    final lines = <String>[];
    var chosen = false;
    await until(() => game.dialoguePresentationListenable.value != null);
    for (var i = 0; i < 100; i++) {
      final snapshot = game.dialoguePresentationListenable.value;
      if (snapshot != null) {
        await onPresentation?.call(snapshot);
        if (snapshot.fullText.isNotEmpty &&
            !lines.contains(snapshot.fullText)) {
          lines.add(snapshot.fullText);
        }
        if (snapshot.choices.isNotEmpty && !chosen) {
          for (var index = 0; index < choice; index++) {
            press(RuntimeInputControl.down);
          }
          chosen = true;
        }
        press(RuntimeInputControl.primary);
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      if (game.debugFlowPhaseName == 'overworld' &&
          !game.debugIsNarrativeSpatialDispatchInFlight &&
          !game.debugIsNarrativeOutcomeWorkInFlight) {
        return lines;
      }
    }
    fail(
      'Conversation did not finish: $lines phase=${game.debugFlowPhaseName}',
    );
  }
}
