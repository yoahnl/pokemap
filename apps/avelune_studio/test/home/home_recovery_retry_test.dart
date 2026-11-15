import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_studio_app.dart';

final class _RecoveryFailingPort implements ProjectSessionPort {
  final requests = <String>[];

  @override
  Future<ProjectSession> open(
    String directoryPath, {
    void Function(ProjectOpeningPhase phase)? onPhase,
  }) async {
    requests.add(directoryPath);
    throw const ProjectOpenFailure(ProjectOpenProblem.recoveryFailed);
  }

  @override
  Future<void> close(ProjectSession session) async {}
}

void main() {
  test('the blocking recovery message exists in French', () {
    final fr = lookupAppLocalizations(const Locale('fr'));
    expect(fr.openProblemRecoveryFailed, contains('enregistrement interrompu'));
    expect(fr.openProblemRetry, 'Réessayer');
  });

  testWidgets('an unfinished save that cannot resume offers a retry', (
    tester,
  ) async {
    final port = _RecoveryFailingPort();
    await tester.pumpWidget(
      TestStudioApp(
        createSession: () => ProjectSessionController(port),
        chooseDirectory: () async => '/projects/interrupted',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('studio-home-retry-open')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('studio-home-import')));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byKey(const ValueKey('studio-home'))),
    );
    expect(find.text(l10n.openProblemRecoveryFailed), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);
    final retry = find.byKey(const ValueKey('studio-home-retry-open'));
    expect(retry, findsOneWidget);
    expect(find.text(l10n.openProblemRetry), findsOneWidget);

    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(port.requests, ['/projects/interrupted', '/projects/interrupted']);
    expect(retry, findsOneWidget);
  });
}
