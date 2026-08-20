import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

/// L'interpolation typée et déterministe des textes narratifs —
/// BETA-CIN-071.
///
/// Un seul résolveur pur sert tous les consommateurs : mêmes octets partout,
/// namespaces explicites, politique de valeur absente visible et testée,
/// Unicode intact, échappement littéral, et un scope volontairement
/// insérialisable dont les diagnostics ne montrent jamais la saisie joueur.
void main() {
  PresentationInterpolationScope scope({int revision = 1}) =>
      PresentationInterpolationScope(
        revision: revision,
        draftValues: const {
          PresentationDraftInterpolationField.playerName: 'Zoé 🐉‍🔥',
          PresentationDraftInterpolationField.avatarName: 'Héroïne',
          PresentationDraftInterpolationField.starterName: 'Bulbizarre',
        },
        sceneValues: const {'rivalName': 'Silver'},
        executionValues: const {'locale': 'fr'},
      );

  group('BETA-CIN-071 namespaces and determinism', () {
    test('draft, scene and execution namespaces all resolve', () {
      final result = interpolatePresentationText(
        'Bonjour {{draft.playerName}}, {{scene.rivalName}} arrive '
        '({{execution.locale}}).',
        scope(),
      );
      expect(result.text, 'Bonjour Zoé 🐉‍🔥, Silver arrive (fr).');
      expect(result.missingReferences, isEmpty);
    });

    test('the same context renders the exact same bytes every time', () {
      const text = 'Ton starter {{draft.starterName}} et toi, '
          '{{draft.playerName}} !';
      final first = utf8.encode(interpolatePresentationText(text, scope()).text);
      final second =
          utf8.encode(interpolatePresentationText(text, scope()).text);
      expect(
        first,
        second,
        reason: 'preview and runtime share this exact pure function — the '
            'same scope must render the same bytes wherever it runs',
      );
    });

    test('unicode graphemes survive interpolation byte-intact', () {
      final result = interpolatePresentationText(
        'A{{draft.playerName}}B',
        scope(),
      );
      expect(result.text, 'AZoé 🐉‍🔥B');
      expect(
        utf8.encode(result.text),
        [
          ...utf8.encode('A'),
          ...utf8.encode('Zoé 🐉‍🔥'),
          ...utf8.encode('B'),
        ],
        reason: 'composed graphemes (ZWJ sequences, combining accents) must '
            'never be truncated or normalized by the resolver',
      );
    });

    test('whitespace inside braces is tolerated, identity preserved', () {
      expect(
        interpolatePresentationText('{{ draft.playerName }}', scope()).text,
        'Zoé 🐉‍🔥',
      );
    });
  });

  group('BETA-CIN-071 explicit policies', () {
    test('a missing known reference keeps the placeholder and reports it',
        () {
      final result = interpolatePresentationText(
        'Bonjour {{draft.playerName}} et {{scene.professorName}}.',
        PresentationInterpolationScope(revision: 0),
      );
      expect(
        result.text,
        'Bonjour {{draft.playerName}} et {{scene.professorName}}.',
        reason: 'a silently blank name is an authoring bug hidden from the '
            'author — the placeholder must stay visible',
      );
      expect(
        result.missingReferences,
        ['draft.playerName', 'scene.professorName'],
      );
    });

    test('unknown namespaces and malformed references stay literal', () {
      const text = 'Litteral {{unknown.thing}} et {{draft}} et {{x y}}.';
      final result = interpolatePresentationText(text, scope());
      expect(result.text, text);
      expect(result.missingReferences, isEmpty);
    });

    test('escaped braces render literally without the escape', () {
      final result = interpolatePresentationText(
        r'Syntaxe : \{{draft.playerName}} devient {{draft.playerName}}.',
        scope(),
      );
      expect(
        result.text,
        'Syntaxe : {{draft.playerName}} devient Zoé 🐉‍🔥.',
      );
    });

    test('scene and execution reference names are validated', () {
      expect(
        () => PresentationInterpolationScope(
          revision: 0,
          sceneValues: const {'bad name': 'x'},
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => PresentationInterpolationScope(revision: -1),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('BETA-CIN-071 privacy and staleness', () {
    test('the scope diagnostics never leak typed player input', () {
      final printed = scope().toString();
      expect(printed, isNot(contains('Zoé')));
      expect(printed, isNot(contains('Silver')));
      expect(printed, contains('<redacted>'));
      expect(printed, contains('revision: 1'));
    });

    test('the scope is deliberately unserializable', () {
      expect(
        // ignore: avoid_dynamic_calls
        () => (scope() as dynamic).toJson(),
        throwsNoSuchMethodError,
        reason: 'typed player input must never be written into project '
            'configuration, saves, logs or receipts through a casual toJson',
      );
    });

    test('the resolver source never touches the project config type', () {
      final source = File(
        'lib/src/models/presentation_text_interpolation.dart',
      ).readAsStringSync();
      expect(
        source,
        isNot(contains('ProjectNewGameConfig')),
        reason: 'interpolation reads a scope built from validated responses; '
            'it must never copy values into the project config',
      );
    });

    test('an older scope is stale relative to the current one', () {
      final before = scope(revision: 1);
      final after = scope(revision: 2);
      expect(before.isStaleRelativeTo(after), isTrue);
      expect(after.isStaleRelativeTo(before), isFalse);
      expect(after.isStaleRelativeTo(after), isFalse);
    });
  });

  group('BETA-CIN-071 structured request interpolation', () {
    test('prompts and option labels interpolate, identities stay intact', () {
      final request = SceneInteractionRequest.choice(
        requestId: 'run:choice:1',
        revision: 1,
        prompt: SceneInteractionPrompt(
          localizationKey: 'scene.confirm.name',
          fallbackText: 'On confirme, {{draft.playerName}} ?',
          arguments: const {'attempt': '2'},
        ),
        options: [
          SceneInteractionOption(
            id: 'confirmed',
            label: SceneInteractionPrompt(
              localizationKey: 'scene.confirm.yes',
              fallbackText: 'Oui, {{draft.playerName}} me va',
            ),
          ),
          SceneInteractionOption(
            id: 'declined',
            label: SceneInteractionPrompt(
              localizationKey: 'scene.confirm.no',
              fallbackText: 'Non',
            ),
            enabled: false,
          ),
        ],
      ) as SceneChoiceInteractionRequest;

      final interpolated = interpolateSceneInteractionRequest(
        request,
        scope(),
      ) as SceneChoiceInteractionRequest;

      expect(interpolated.requestId, 'run:choice:1');
      expect(interpolated.revision, 1);
      expect(interpolated.prompt.localizationKey, 'scene.confirm.name');
      expect(interpolated.prompt.arguments, const {'attempt': '2'});
      expect(interpolated.prompt.fallbackText, 'On confirme, Zoé 🐉‍🔥 ?');
      expect(
        interpolated.options.first.label.fallbackText,
        'Oui, Zoé 🐉‍🔥 me va',
      );
      expect(interpolated.options.last.label.fallbackText, 'Non');
      expect(interpolated.options.last.enabled, isFalse);
    });

    test('a text request keeps its constraints through interpolation', () {
      final request = SceneInteractionRequest.text(
        requestId: 'run:text:1',
        revision: 3,
        prompt: SceneInteractionPrompt(
          localizationKey: 'scene.rename',
          fallbackText: 'Nouveau nom pour {{draft.playerName}} ?',
        ),
        constraints: SceneTextInputConstraints(
          minGraphemes: 1,
          maxGraphemes: 24,
        ),
      ) as SceneTextInteractionRequest;

      final interpolated = interpolateSceneInteractionRequest(
        request,
        scope(),
      ) as SceneTextInteractionRequest;
      expect(interpolated.constraints.maxGraphemes, 24);
      expect(
        interpolated.prompt.fallbackText,
        'Nouveau nom pour Zoé 🐉‍🔥 ?',
      );
      expect(interpolated.revision, 3);
    });
  });
}
