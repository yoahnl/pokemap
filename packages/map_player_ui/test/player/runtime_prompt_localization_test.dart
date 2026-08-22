import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';

/// BETA-CIN-086 — une invite produite par le runtime suit la langue du joueur.
///
/// `SceneInteractionPrompt` portait déjà `localizationKey` depuis le début, et
/// `promptResolver` était la couture prévue pour la résoudre. Aucun site de
/// production ne l'a jamais branchée, donc chaque invite du runtime s'affichait
/// dans la langue où elle avait été tapée — du français, sur un appareil
/// anglais, à côté d'un chrome anglais.
void main() {
  Future<void> pump(
    WidgetTester tester,
    SceneInteractionRequest request, {
    required Locale locale,
    SceneInteractionPromptResolver? promptResolver,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
        localizationsDelegates:
            PokeMapPlayerLocalizations.localizationsDelegates,
        theme: PokeMapPlayerTheme.dark(),
        // Le révélateur machine à écrire est désactivé : sans cela le texte
        // n'est complet qu'après des minuteurs, et un test qui s'achève sur un
        // minuteur pendant échoue de lui-même.
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: PlayerSceneInteractionSurface(
            request: request,
            onResult: (_) {},
            promptResolver: promptResolver,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  SceneInteractionRequest confirmation(
    String key, {
    Map<String, String> arguments = const <String, String>{},
    String? fallbackText,
  }) =>
      SceneInteractionRequest.confirmation(
        requestId: 'r',
        revision: 1,
        prompt: SceneInteractionPrompt(
          localizationKey: key,
          fallbackText: fallbackText,
          arguments: arguments,
        ),
      );

  group('les clés que le produit possède suivent la langue', () {
    testWidgets('la confirmation de remplacement, en français', (tester) async {
      await pump(
        tester,
        confirmation('player.new_game.confirm_overwrite'),
        locale: const Locale('fr'),
      );
      expect(
        find.text('Cette sauvegarde existe déjà. Voulez-vous la remplacer ?'),
        findsOneWidget,
      );
    });

    testWidgets('la même, en anglais', (tester) async {
      await pump(
        tester,
        confirmation('player.new_game.confirm_overwrite'),
        locale: const Locale('en'),
      );
      expect(
        find.text('This save already exists. Do you want to replace it?'),
        findsOneWidget,
      );
    });

    testWidgets('une invite localisée bat le fallbackText du runtime',
        (tester) async {
      // Le runtime fournit toujours son fallback en dur ; la clé doit gagner.
      await pump(
        tester,
        confirmation(
          'player.new_game.confirm_overwrite',
          fallbackText: 'Cette sauvegarde existe déjà. Voulez-vous la '
              'remplacer ?',
        ),
        locale: const Locale('en'),
      );
      expect(
        find.text('This save already exists. Do you want to replace it?'),
        findsOneWidget,
      );
    });
  });

  testWidgets('la phrase bilingue ne peut pas revenir en miroir',
      (tester) async {
    // BETA-CIN-086 avait produit « Cette sauvegarde ne peut pas être
    // poursuivie : This ending does not allow post-game continuation. » Le
    // miroir serait un gabarit anglais dans lequel on injecte la raison
    // française que le runtime a déjà rendue. `reasonCode` existe pour que la
    // couche d'affichage choisisse SA formulation.
    await pump(
      tester,
      confirmation(
        'player.new_game.confirm_overwrite_unusable',
        arguments: const <String, String>{
          'reason': 'Cette fin n’autorise pas de reprise après la fin du jeu.',
          'reasonCode': 'postGameContinuationRefused',
        },
      ),
      locale: const Locale('en'),
    );

    expect(
      find.text(
        'This save cannot be continued: This ending does not allow post-game '
        'continuation. Replacing it will permanently erase its progress.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('un code de raison inconnu retombe sur la formulation du runtime',
      (tester) async {
    // Une valeur ajoutée à l'énumération sans traduction ne doit pas afficher
    // un identifiant au joueur.
    await pump(
      tester,
      confirmation(
        'player.new_game.confirm_overwrite_unusable',
        arguments: const <String, String>{
          'reason': 'Une cause encore sans traduction.',
          'reasonCode': 'someFutureReason',
        },
      ),
      locale: const Locale('en'),
    );

    expect(
      find.text(
        'This save cannot be continued: Une cause encore sans traduction. '
        'Replacing it will permanently erase its progress.',
      ),
      findsOneWidget,
    );
  });

  group('le contenu authoré n’est jamais détourné', () {
    testWidgets('une réplique de dialogue reste celle de l’auteur',
        (tester) async {
      // `scene.pre_session.dialogue.line` est émise par le runtime, mais son
      // fallbackText est la réplique écrite par l'auteur. La « traduire »
      // remplacerait le dialogue du jeu par une phrase de PokeMap.
      for (final locale in const <Locale>[Locale('fr'), Locale('en')]) {
        await pump(
          tester,
          SceneInteractionRequest.message(
            requestId: 'r',
            revision: 1,
            prompt: SceneInteractionPrompt(
              localizationKey: 'scene.pre_session.dialogue.line',
              fallbackText: 'Le phare tourne depuis cent ans.',
            ),
          ),
          locale: locale,
        );
        expect(
          find.text('Le phare tourne depuis cent ans.'),
          findsOneWidget,
          reason: 'la réplique authorée doit survivre en ${locale.languageCode}',
        );
      }
    });

    testWidgets('une clé authorée n’est pas dans le registre', (tester) async {
      await pump(
        tester,
        confirmation(
          'nightWatch.playerName.confirm',
          fallbackText: 'Le registre dira donc Kaelis. C’est bien cela ?',
        ),
        locale: const Locale('en'),
      );
      expect(
        find.text('Le registre dira donc Kaelis. C’est bien cela ?'),
        findsOneWidget,
      );
    });

    test('le registre ne contient que des clés produit', () {
      expect(
        runtimeOwnedPromptKeys,
        isNot(contains('scene.pre_session.dialogue.line')),
        reason: 'cette clé porte du texte authoré, pas une chaîne produit',
      );
      for (final key in runtimeOwnedPromptKeys) {
        expect(
          key,
          anyOf(startsWith('player.'), startsWith('scene.pre_session.')),
          reason: 'une clé produit est préfixée, une clé authorée est libre',
        );
      }
    });
  });

  testWidgets('un résolveur injecté garde le dernier mot', (tester) async {
    // Le Studio prévisualise autrement ; la résolution intrinsèque ne doit pas
    // lui retirer cette possibilité.
    await pump(
      tester,
      confirmation('player.new_game.confirm_overwrite'),
      locale: const Locale('en'),
      promptResolver: (prompt) => 'Aperçu : ${prompt.localizationKey}',
    );
    expect(
      find.text('Aperçu : player.new_game.confirm_overwrite'),
      findsOneWidget,
    );
  });
}
