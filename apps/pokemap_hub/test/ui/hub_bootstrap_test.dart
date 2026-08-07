import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/app/app_root.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokemap_hub/app/di/hub_composition.dart';
import 'package:pokemap_hub/app/di/hub_composition_provider.dart';

void main() {
  testWidgets('startup failure is responsive, diagnostic, and retryable',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    var attempts = 0;
    Future<HubAppComposition> createComposition() async {
      attempts += 1;
      if (attempts == 1) {
        throw StateError('support directory unavailable');
      }
      return const _ReadyComposition();
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hubCompositionProvider.overrideWith((ref) => createComposition()),
        ],
        child: PokeMapHubBootstrap(showTechnicalDetails: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Impossible d’ouvrir Avelune'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
    expect(find.textContaining('hub.bootstrap.failed'), findsOneWidget);
    expect(
      find.textContaining('support directory unavailable'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Hub prêt'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('release startup failure does not expose the raw exception',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hubCompositionProvider.overrideWith((ref) async {
          throw StateError('private absolute path');
          }),
        ],
        child: PokeMapHubBootstrap(showTechnicalDetails: false),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('hub.bootstrap.failed'), findsOneWidget);
    expect(find.textContaining('private absolute path'), findsNothing);
  });

  testWidgets('startup failure remains usable in mobile landscape',
      (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hubCompositionProvider.overrideWith((ref) async {
          throw StateError('landscape failure');
          }),
        ],
        child: PokeMapHubBootstrap(showTechnicalDetails: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Impossible d’ouvrir Avelune'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

final class _ReadyComposition implements HubAppComposition {
  const _ReadyComposition();

  @override
  Widget buildApp() => const MaterialApp(
        home: Scaffold(
          body: Text('Hub prêt'),
        ),
      );

  @override
  void dispose() {}
}
