import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/player/player_world_loading_surface.dart';

void main() {
  for (final size in const [Size(390, 844), Size(844, 390), Size(496, 432)]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'session panels preserve content and actions at $size dark=$dark scale=$scale',
          (tester) async {
            var credits = 0;
            await _mount(
              tester,
              size,
              dark,
              scale,
              PlayerResultSurface(
                title: 'Aventure terminée',
                summary: 'La progression est conservée.',
                details: const ['Le phare a été rallumé.'],
                onShowCredits: () => credits++,
              ),
            );
            expect(find.byType(PlayerPanel), findsNothing);
            expect(find.byType(PlayerMenuPanel), findsOneWidget);
            await _activate(tester, 'Voir les crédits');
            expect(credits, 1);

            var title = 0;
            var hub = 0;
            await _mount(
              tester,
              size,
              dark,
              scale,
              PlayerCreditsSurface(
                title: 'Avelune',
                author: 'Studio Test',
                endingLabel: 'Merci !',
                contributors: const ['Contribution publiée'],
                licenses: const ['Licence publiée'],
                onReturnToTitle: () => title++,
                onReturnToHub: () => hub++,
              ),
            );
            final texts = await _allVisibleText(tester);
            expect(texts, contains('Contribution publiée'));
            expect(texts, contains('Licence publiée'));
            await _activate(tester, 'Retour au titre');
            await _activate(tester, 'Retour au Hub');
            expect((title, hub), (1, 1));

            final selected = <String>[];
            await _mount(
              tester,
              size,
              dark,
              scale,
              PlayerErrorSurface(
                title: 'Impossible de poursuivre',
                message: 'Les ressources sont indisponibles.',
                recommendation: 'Votre sauvegarde est conservée.',
                code: 'missing-resource',
                stage: 'Chargement',
                onRetry: () => selected.add('retry'),
                onCancel: () => selected.add('cancel'),
                onReturnToHub: () => selected.add('hub'),
                onShowDiagnostics: () => selected.add('diagnostics'),
              ),
            );
            final errorText = await _allVisibleText(tester);
            expect(errorText, contains('missing-resource'));
            expect(errorText, contains('Votre sauvegarde est conservée.'));
            for (final label in [
              'Réessayer',
              'Retour au Hub',
              'Fermer',
              'Diagnostics',
            ]) {
              await _activate(tester, label);
            }
            expect(selected, ['retry', 'hub', 'cancel', 'diagnostics']);
            expect(find.byType(PlayerPanel), findsNothing);
            expect(find.byType(Scrollable), findsNothing);
            expect(tester.takeException(), isNull);
            final recovered = <SaveRecoveryAction>[];
            await _mount(
              tester,
              size,
              dark,
              scale,
              Scaffold(
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: PlayerSaveRecoverySurface(
                    diagnostic: const SaveLoadDiagnostic(
                      code: SaveLoadFailureCode.unreadable,
                      expectedSchemaVersion: 1,
                      recommendedActions: [
                        SaveRecoveryAction.retry,
                        SaveRecoveryAction.deleteSave,
                      ],
                    ),
                    onAction: recovered.add,
                  ),
                ),
              ),
            );
            expect(find.byType(PlayerPanel), findsNothing);
            await tester.tap(
              find.byKey(
                PlayerSaveRecoverySurface.actionKey(
                  SaveRecoveryAction.deleteSave,
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(find.byType(AlertDialog), findsNothing);
            final accept = find.byKey(
              const ValueKey('player-save-recovery-delete-accept'),
              skipOffstage: false,
            );
            final label = tester.widget<PlayerActionButton>(accept).label;
            expect(recovered, isEmpty);
            await _activate(tester, label);
            expect(recovered, [SaveRecoveryAction.deleteSave]);
            expect(tester.takeException(), isNull);
          },
        );

        testWidgets(
          'loading uses authored title and themed progress at $size dark=$dark scale=$scale',
          (tester) async {
            var cancelled = 0;
            await _mount(
              tester,
              size,
              dark,
              scale,
              PlayerWorldLoadingSurface(
                gameTitle: 'Le phare',
                stage: 'Préparation du monde',
                progress: .42,
                reducedMotion: true,
                onCancel: () => cancelled++,
              ),
            );
            final text = await _allVisibleText(tester);
            expect(text, contains('Le phare'));
            final title = find.byKey(const ValueKey('player-session-title'));
            expect(tester.widget<Text>(title).textAlign, TextAlign.center);
            expect(
              tester.getRect(title).center.dx,
              closeTo(size.width / 2, .1),
            );
            expect(text, contains('42%'));
            expect(text, contains('Préparation du monde'));
            await _activate(tester, 'Annuler');
            expect(cancelled, 1);
            final progress = tester.widget<LinearProgressIndicator>(
              find.byKey(const ValueKey('runtime-player-loading-progress')),
            );
            final context = tester.element(
              find.byKey(const ValueKey('runtime-player-loading-progress')),
            );
            expect(progress.color, context.playerMenuTheme.accent);
            expect(progress.backgroundColor, context.playerMenuTheme.recessed);
            expect(progress.value, .42);
            expect(find.byType(PlayerPanel), findsNothing);
            expect(find.byType(Scrollable), findsNothing);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('long published license remains complete across bounded pages', (
    tester,
  ) async {
    final license = List.generate(100, (index) => 'Licence-$index').join(' ');
    await _mount(
      tester,
      const Size(496, 432),
      true,
      2,
      PlayerCreditsSurface(
        title: 'Avelune',
        author: 'Studio Test',
        licenses: [license],
        onReturnToTitle: () {},
        onReturnToHub: null,
      ),
    );
    final parts = <int, String>{};
    await _firstPage(tester);
    for (var i = 0; i < 100; i++) {
      for (final element
          in find
              .byWidgetPredicate(
                (widget) =>
                    widget is Text &&
                    widget.key.toString().contains('session-paragraph-1-'),
              )
              .evaluate()) {
        final text = element.widget as Text;
        final key = (text.key! as ValueKey<String>).value;
        parts[int.parse(key.split('-').last)] = text.data!;
      }
      if (!_hasNext(tester)) break;
      await tester.tap(find.byKey(const ValueKey('player-page-next')));
      await tester.pumpAndSettle();
    }
    expect(
      (parts.keys.toList()..sort()).map((key) => parts[key]).join(),
      license,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _mount(
  WidgetTester tester,
  Size size,
  bool dark,
  double scale,
  Widget child,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? PokeMapPlayerTheme.dark() : PokeMapPlayerTheme.light(),
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: child,
    ),
  );
  await tester.pumpAndSettle();
}

bool _hasNext(WidgetTester tester) =>
    find.byKey(const ValueKey('player-page-next')).evaluate().isNotEmpty &&
    tester
            .widget<IconButton>(find.byKey(const ValueKey('player-page-next')))
            .onPressed !=
        null;

Future<void> _firstPage(WidgetTester tester) async {
  for (var i = 0; i < 100; i++) {
    final previous = find.byKey(const ValueKey('player-page-previous'));
    if (previous.evaluate().isEmpty ||
        tester.widget<IconButton>(previous).onPressed == null) {
      break;
    }
    await tester.tap(previous);
    await tester.pumpAndSettle();
  }
}

Future<Set<String>> _allVisibleText(WidgetTester tester) async {
  await _firstPage(tester);
  final result = <String>{};
  for (var i = 0; i < 100; i++) {
    result.addAll(
      tester.widgetList<Text>(find.byType(Text)).map((text) => text.data ?? ''),
    );
    if (!_hasNext(tester)) break;
    await tester.tap(find.byKey(const ValueKey('player-page-next')));
    await tester.pumpAndSettle();
  }
  return result;
}

Future<void> _activate(WidgetTester tester, String label) async {
  await _firstPage(tester);
  for (
    var i = 0;
    i < 100 && find.text(label).evaluate().isEmpty && _hasNext(tester);
    i++
  ) {
    await tester.tap(find.byKey(const ValueKey('player-page-next')));
    await tester.pumpAndSettle();
  }
  final target = find.text(label);
  expect(target, findsOneWidget);
  final rect = tester.getRect(target);
  expect(rect.top, greaterThanOrEqualTo(0));
  expect(rect.bottom, lessThanOrEqualTo(tester.view.physicalSize.height));
  await tester.tap(target);
  await tester.pumpAndSettle();
}
