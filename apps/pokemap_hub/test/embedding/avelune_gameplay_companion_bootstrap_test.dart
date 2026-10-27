import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_hub/embedding/avelune_gameplay_companion.dart';
import 'package:pokemap_hub/embedding/avelune_gameplay_companion_app.dart';

void main() {
  testWidgets('a painted waiting surface bootstraps without cached gameplay', (
    tester,
  ) async {
    const channel = MethodChannel('com.avelune.runtime/companion');
    final messenger = tester.binding.defaultBinaryMessenger;
    final owner = AveluneGameplayCompanionOwner()..start('cold-session');
    final port = _WaitingPort();
    owner.bind(port);
    final readiness = <bool>[];
    final intents = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'companionReady':
          expect(port.reads, 0);
        case 'surfaceReady':
          final arguments = call.arguments as Map;
          final ready = arguments['ready'] as bool;
          readiness.add(ready);
          await owner.setCompanionAttached('cold-session', ready);
        case 'intent':
          final intent = Map<Object?, Object?>.from(call.arguments as Map);
          intents.add(intent['kind'] as String);
          await owner.applyIntent(intent);
      }
      return owner.value?.toPayload();
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(channel, null);
      owner.dispose();
    });

    await tester.pumpWidget(const AveluneGameplayCompanionApp());
    await tester.pumpAndSettle();

    expect(readiness, contains(true));
    expect(port.reads, 1);
    expect(owner.value!.mode, AveluneGameplayCompanionMode.waiting);
    expect(owner.value!.player, isNull);
    expect(owner.value!.narrativeReady, isFalse);
    expect(find.byType(PokeMapPlayerSessionView), findsNothing);
    expect(intents, isEmpty);

    port.ready.complete();
    await tester.pumpAndSettle();

    final view = tester.widget<PokeMapPlayerSessionView>(
      find.byType(PokeMapPlayerSessionView),
    );
    expect(view.controller.snapshot.phase, RuntimePlayerPhase.title);
    expect(owner.value!.mode, AveluneGameplayCompanionMode.menu);
    expect(intents, contains('narrativeReady'));
    expect(owner.value!.narrativeReady, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _WaitingPort implements AveluneGameplayCompanionOwnerPort {
  final ready = Completer<void>();
  int reads = 0;

  @override
  bool get isPaused => false;

  @override
  void releaseBattleInputs() {}

  @override
  Future<AveluneGameplayCompanionData> read() async {
    reads++;
    await ready.future;
    return AveluneGameplayCompanionData(
      mode: AveluneGameplayCompanionMode.menu,
      player: RuntimePlayerSnapshot(
        revision: 1,
        phase: RuntimePlayerPhase.title,
        gameTitle: 'Cold start',
      ),
      presentation: const {'startupRevision': 1},
    );
  }

  @override
  Future<void> execute(
    String kind,
    Map<String, Object?> payload,
    AveluneGameplayCompanionSnapshot expected,
  ) async {}
}
