import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  for (final viewport in const [Size(390, 844), Size(844, 390)]) {
    for (final variant in [
      PlayerTitleLayoutVariant.standard,
      PlayerTitleLayoutVariant.runtimeStartup,
      PlayerTitleLayoutVariant.runtimeStartupCinematic,
    ]) {
      testWidgets(
        'title actions remain available without sliding at $viewport in ${variant.name}',
        (tester) async {
          final selected = <PlayerTitleMenuAction>[];
          await _pump(
            tester,
            viewport,
            PlayerTitleSurface(
              data: PlayerTitleSurfaceData(
                gameTitle: 'Une aventure',
                author: 'Studio',
                layoutVariant: variant,
                actions: {
                  for (final action in PlayerTitleMenuAction.values)
                    action: PlayerActionAvailability.enabled,
                },
              ),
              onSelected: selected.add,
            ),
          );
          expect(find.byType(SingleChildScrollView), findsNothing);
          expect(find.byType(Scrollbar), findsNothing);
          for (
            var attempt = 0;
            attempt < 16 && find.text('Retour au Hub').evaluate().isEmpty;
            attempt++
          ) {
            await tester.tap(find.byKey(const ValueKey('player-page-next')));
            await tester.pumpAndSettle();
          }
          await tester.tap(find.text('Retour au Hub'));
          expect(selected.single, PlayerTitleMenuAction.returnToHub);
          expect(tester.takeException(), isNull);
        },
      );
    }
    testWidgets('credits keep both return actions on screen at $viewport', (
      tester,
    ) async {
      var title = 0;
      var hub = 0;
      await _pump(
        tester,
        viewport,
        PlayerCreditsSurface(
          title: 'Une aventure',
          author: 'Le studio et les contributeurs',
          endingLabel: 'Merci d’avoir joué.',
          onReturnToTitle: () => title++,
          onReturnToHub: () => hub++,
        ),
      );
      expect(find.byType(SingleChildScrollView), findsNothing);
      await tester.tap(find.text('Retour au titre'));
      await tester.tap(find.text('Retour au Hub'));
      expect(title, 1);
      expect(hub, 1);
      expect(tester.takeException(), isNull);
    });
    testWidgets(
      'authored choices paginate with their exact request identity at $viewport',
      (tester) async {
        final results = <SceneInteractionResult>[];
        await _pump(
          tester,
          viewport,
          PlayerSceneInteractionSurface(
            request: SceneInteractionRequest.choice(
              requestId: 'choice-list',
              revision: 13,
              prompt: SceneInteractionPrompt(
                fallbackText: 'Quelle destination ?',
                localizationKey: 'destination',
              ),
              options: [
                for (var index = 0; index < 14; index++)
                  SceneInteractionOption(
                    id: 'option-$index',
                    label: SceneInteractionPrompt(
                      fallbackText: 'Destination ${index + 1}',
                      localizationKey: 'destination-$index',
                    ),
                  ),
              ],
            ),
            onResult: results.add,
          ),
        );
        expect(find.byType(SingleChildScrollView), findsNothing);
        for (
          var attempt = 0;
          attempt < 20 && find.text('Destination 14').evaluate().isEmpty;
          attempt++
        ) {
          await tester.tap(find.byKey(const ValueKey('player-page-next')));
          await tester.pumpAndSettle();
        }
        expect(results, isEmpty);
        await tester.tap(find.text('Destination 14'));
        expect(
          results.single,
          isA<SceneChoiceSelectedInteractionResult>()
              .having(
                (value) => value.selectedOptionId,
                'identity',
                'option-13',
              )
              .having((value) => value.revision, 'revision', 13),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Future<void> _pump(WidgetTester tester, Size viewport, Widget surface) async {
  await tester.binding.setSurfaceSize(viewport);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
      home: surface,
    ),
  );
  await tester.pumpAndSettle();
}
