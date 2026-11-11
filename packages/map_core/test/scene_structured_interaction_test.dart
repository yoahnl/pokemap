import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Scene structured interaction contracts', () {
    test('text request preserves the proposed name through JSON', () {
      final json = <String, dynamic>{
        'kind': 'text',
        'requestId': 'rival-name',
        'revision': 1,
        'prompt': {
          'localizationKey': 'story.rivalName',
          'fallbackText': 'Comment s’appelle ce garçon ?',
        },
        'constraints': {'minGraphemes': 1, 'maxGraphemes': 12},
        'initialValue': 'Silver',
      };

      final request = SceneInteractionRequest.fromJson(json);

      expect(request.toJson(), json);
      expect(
        request,
        isNot(
          SceneInteractionRequest.fromJson({...json, 'initialValue': 'Gold'}),
        ),
      );
    });

    test('all request and result kinds round-trip through JSON', () {
      final prompt = SceneInteractionPrompt(
        localizationKey: 'intro.playerName',
        fallbackText: 'Ton nom ?',
        arguments: const {'region': 'Avelune'},
      );
      final options = [
        SceneInteractionOption(
          id: 'sprout',
          label: SceneInteractionPrompt(
            localizationKey: 'starter.sprout',
            fallbackText: 'Poussifeu',
          ),
        ),
        SceneInteractionOption(
          id: 'wave',
          label: SceneInteractionPrompt(
            localizationKey: 'starter.wave',
            fallbackText: 'Vaguelin',
          ),
        ),
      ];
      final requests = <SceneInteractionRequest>[
        SceneInteractionRequest.message(
          requestId: 'message',
          revision: 1,
          prompt: prompt,
        ),
        SceneInteractionRequest.choice(
          requestId: 'choice',
          revision: 2,
          prompt: prompt,
          options: options,
        ),
        SceneInteractionRequest.text(
          requestId: 'text',
          revision: 3,
          prompt: prompt,
          constraints: SceneTextInputConstraints(
            minGraphemes: 1,
            maxGraphemes: 12,
          ),
        ),
        SceneInteractionRequest.confirmation(
          requestId: 'confirmation',
          revision: 4,
          prompt: prompt,
        ),
        SceneInteractionRequest.selection(
          requestId: 'selection',
          revision: 5,
          prompt: prompt,
          options: options,
          constraints: SceneSelectionConstraints(
            minSelections: 1,
            maxSelections: 2,
          ),
        ),
      ];
      final results = <SceneInteractionResult>[
        SceneInteractionResult.acknowledged(requestId: 'message', revision: 1),
        SceneInteractionResult.choiceSelected(
          requestId: 'choice',
          revision: 2,
          selectedOptionId: 'sprout',
        ),
        SceneInteractionResult.textSubmitted(
          requestId: 'text',
          revision: 3,
          value: 'Yoahn',
        ),
        SceneInteractionResult.confirmed(
          requestId: 'confirmation',
          revision: 4,
          value: true,
        ),
        SceneInteractionResult.selectionSubmitted(
          requestId: 'selection',
          revision: 5,
          selectedOptionIds: const ['sprout', 'wave'],
        ),
        SceneInteractionResult.cancelled(
          requestId: 'text',
          revision: 6,
          reason: SceneInteractionCancellationReason.user,
        ),
      ];

      for (final request in requests) {
        expect(SceneInteractionRequest.fromJson(request.toJson()), request);
      }
      for (final result in results) {
        expect(SceneInteractionResult.fromJson(result.toJson()), result);
      }
    });

    test('text validation counts Unicode grapheme clusters', () {
      final request = SceneInteractionRequest.text(
        requestId: 'name',
        revision: 1,
        prompt: SceneInteractionPrompt(
          localizationKey: 'intro.playerName',
          fallbackText: 'Ton nom ?',
        ),
        constraints: SceneTextInputConstraints(
          minGraphemes: 1,
          maxGraphemes: 2,
        ),
      );

      expect(
        request.validateResult(
          SceneInteractionResult.textSubmitted(
            requestId: 'name',
            revision: 1,
            value: 'e\u0301👨‍👩‍👧‍👦',
          ),
        ),
        isEmpty,
      );
      final issues = request.validateResult(
        SceneInteractionResult.textSubmitted(
          requestId: 'name',
          revision: 1,
          value: 'e\u0301👨‍👩‍👧‍👦x',
        ),
      );
      expect(issues, hasLength(1));
      expect(
        issues.single.code,
        SceneInteractionValidationIssueCode.textTooLong,
      );
      expect(
        SceneInteractionValidationIssue.fromJson(issues.single.toJson()),
        issues.single,
      );
      expect(issues.single.localizationKey, isNotEmpty);
      expect(issues.single.arguments['actual'], '3');
    });

    test('choice and selection validation reject invalid option payloads', () {
      final options = [
        SceneInteractionOption(
          id: 'enabled',
          label: SceneInteractionPrompt(
            localizationKey: 'option.enabled',
            fallbackText: 'Disponible',
          ),
        ),
        SceneInteractionOption(
          id: 'disabled',
          label: SceneInteractionPrompt(
            localizationKey: 'option.disabled',
            fallbackText: 'Indisponible',
          ),
          enabled: false,
        ),
      ];
      final choice = SceneInteractionRequest.choice(
        requestId: 'choice',
        revision: 1,
        prompt: SceneInteractionPrompt(
          localizationKey: 'choice.prompt',
          fallbackText: 'Choisis',
        ),
        options: options,
      );
      final selection = SceneInteractionRequest.selection(
        requestId: 'selection',
        revision: 1,
        prompt: SceneInteractionPrompt(
          localizationKey: 'selection.prompt',
          fallbackText: 'Sélectionne',
        ),
        options: options,
        constraints: SceneSelectionConstraints(
          minSelections: 1,
          maxSelections: 1,
        ),
      );

      expect(
        choice
            .validateResult(
              SceneInteractionResult.choiceSelected(
                requestId: 'choice',
                revision: 1,
                selectedOptionId: 'disabled',
              ),
            )
            .single
            .code,
        SceneInteractionValidationIssueCode.optionDisabled,
      );
      expect(
        selection
            .validateResult(
              SceneInteractionResult.selectionSubmitted(
                requestId: 'selection',
                revision: 1,
                selectedOptionIds: const ['enabled', 'enabled'],
              ),
            )
            .map((issue) => issue.code),
        contains(SceneInteractionValidationIssueCode.duplicateSelection),
      );
    });

    test('invalid constraints fail closed with domain argument errors', () {
      expect(
        () => SceneTextInputConstraints(minGraphemes: -1),
        throwsArgumentError,
      );
      expect(
        () => SceneTextInputConstraints(minGraphemes: 3, maxGraphemes: 2),
        throwsArgumentError,
      );
      expect(
        () => SceneSelectionConstraints(minSelections: 2, maxSelections: 1),
        throwsArgumentError,
      );
    });

    test('timeouts reject precision that cannot survive JSON', () {
      expect(
        () => SceneInteractionRequest.message(
          requestId: 'message',
          revision: 1,
          prompt: _prompt('message'),
          timeout: const Duration(microseconds: 500),
        ),
        throwsArgumentError,
      );
    });
  });

}

SceneInteractionPrompt _prompt(String id) =>
    SceneInteractionPrompt(localizationKey: '$id.prompt', fallbackText: id);

