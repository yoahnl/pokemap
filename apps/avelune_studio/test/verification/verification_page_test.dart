import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../game_behaviours/game_behaviour_fakes.dart';
import '../presentation/story_memory_harness.dart';
import '../storyline/storyline_widget_support.dart';
import 'verification_fakes.dart';

FakeVerificationPort _port() => FakeVerificationPort(
  diagnostics: [
    verificationDiagnostic(
      'milestone',
      NarrativeProjectDiagnosticDestination.storyline,
      stepId: 'meet',
    ),
    verificationDiagnostic(
      'fact',
      NarrativeProjectDiagnosticDestination.fact,
      severity: NarrativeProjectDiagnosticSeverity.warning,
      factId: 'met',
    ),
    verificationDiagnostic(
      'behaviour',
      NarrativeProjectDiagnosticDestination.event,
      eventId: behaviourId(1),
    ),
    verificationDiagnostic(
      'overview',
      NarrativeProjectDiagnosticDestination.overview,
    ),
  ],
);

Future<void> _verify(WidgetTester tester, FakeVerificationPort port) async {
  await openTrameStudio(tester, verification: port);
  await tester.tap(find.byKey(const ValueKey('story-tab-verify')));
  await settleMemory(tester);
  expect(port.analyses, 0);
  await tester.tap(find.byKey(const ValueKey('verification-start')));
  await settleMemory(tester);
}

void main() {
  testWidgets('a verification lists problems and opens each place', (
    tester,
  ) async {
    final port = _port();
    await _verify(tester, port);

    expect(port.analyses, 1);
    expect(find.byKey(const ValueKey('verification-summary')), findsOneWidget);
    expect(find.text('Problème milestone'), findsOneWidget);
    expect(find.byKey(const ValueKey('verification-open-2')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('verification-open-0')));
    await settleMemory(tester);
    expect(
      find.byKey(const ValueKey('trame-milestone-detail-meet')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('story-tab-verify')));
    await settleMemory(tester);
    await tester.tap(find.byKey(const ValueKey('verification-open-3')));
    await settleMemory(tester);
    expect(
      find.byKey(const ValueKey('memory-fact-detail-met')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('story-tab-verify')));
    await settleMemory(tester);
    await tester.tap(find.byKey(const ValueKey('verification-open-1')));
    await settleMemory(tester);
    expect(
      find.byKey(const ValueKey('map-story-inspector-entity:guide')),
      findsOneWidget,
    );
  });

  testWidgets('editing never starts a verification', (tester) async {
    final port = _port();
    await openTrameStudio(tester, verification: port);
    await tester.tap(find.byKey(const ValueKey('trame-storyline-main')));
    await settleMemory(tester);
    await tester.tap(find.byKey(const ValueKey('trame-chapter-add')));
    await settleMemory(tester);

    expect(port.analyses, 0);
    await tester.tap(find.byKey(const ValueKey('story-tab-verify')));
    await settleMemory(tester);
    expect(find.byKey(const ValueKey('verification-unsaved')), findsOneWidget);
    expect(find.text('Le projet n’a pas encore été vérifié'), findsOneWidget);
  });
}
