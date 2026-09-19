import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avelune_studio/app/di/providers.dart';
import 'package:avelune_studio/app/studio_app.dart';
import 'package:avelune_studio/app/studio_bootstrap.dart';
import 'package:avelune_studio/features/project_session/application/project_session_state.dart';

void main() {
  testWidgets('bootstrap keeps its session until the root scope is removed', (
    tester,
  ) async {
    await tester.pumpWidget(StudioBootstrap());
    final container = ProviderScope.containerOf(
      tester.element(find.byType(StudioApp)),
      listen: false,
    );
    final session = container.read(projectSessionControllerProvider);
    expect(session.state.status, ProjectSessionStatus.idle);
    expect(find.text('Ouvrir un projet'), findsOneWidget);

    await tester.pumpWidget(StudioBootstrap());
    expect(container.read(projectSessionControllerProvider), same(session));
    expect(session.disposed, isFalse);

    await tester.pumpWidget(const SizedBox());
    expect(session.disposed, isTrue);

    await tester.pumpWidget(StudioBootstrap());
    final replacement = ProviderScope.containerOf(
      tester.element(find.byType(StudioApp)),
      listen: false,
    ).read(projectSessionControllerProvider);
    expect(replacement, isNot(same(session)));
    expect(replacement.disposed, isFalse);
    await tester.pumpWidget(const SizedBox());
    expect(replacement.disposed, isTrue);
  });
}
