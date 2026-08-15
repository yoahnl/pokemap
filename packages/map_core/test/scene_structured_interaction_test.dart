import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Scene structured interaction contracts', () {
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

  group('HeadlessSceneInteractionPort', () {
    test('publishes requests so adapters only render and resolve', () async {
      final port = HeadlessSceneInteractionPort();
      final request = _choiceRequest(revision: 1);
      final observed = expectLater(port.requests, emits(request));

      final future = port.request(request);

      await observed;
      port.resolve(
        SceneInteractionResult.choiceSelected(
          requestId: request.requestId,
          revision: request.revision,
          selectedOptionId: 'sprout',
        ),
      );
      await future;
      port.close();
    });

    test('resolves one terminal result exactly once', () async {
      final port = HeadlessSceneInteractionPort();
      final request = _choiceRequest(revision: 1);
      final future = port.request(request);

      expect(port.pendingRequests, [request]);
      expect(
        port
            .resolve(
              SceneInteractionResult.choiceSelected(
                requestId: request.requestId,
                revision: request.revision,
                selectedOptionId: 'sprout',
              ),
            )
            .status,
        SceneInteractionResolutionStatus.accepted,
      );
      expect(
        await future,
        SceneInteractionResult.choiceSelected(
          requestId: request.requestId,
          revision: request.revision,
          selectedOptionId: 'sprout',
        ),
      );
      expect(
        port
            .resolve(
              SceneInteractionResult.choiceSelected(
                requestId: request.requestId,
                revision: request.revision,
                selectedOptionId: 'wave',
              ),
            )
            .status,
        SceneInteractionResolutionStatus.alreadyTerminal,
      );
    });

    test(
      'cancel and late replies have deterministic terminal behavior',
      () async {
        final port = HeadlessSceneInteractionPort();
        final request = _choiceRequest(revision: 4);
        final future = port.request(request);

        expect(
          port
              .cancel(
                requestId: request.requestId,
                revision: request.revision,
                reason: SceneInteractionCancellationReason.user,
              )
              .status,
          SceneInteractionResolutionStatus.accepted,
        );
        expect(
          await future,
          SceneInteractionResult.cancelled(
            requestId: request.requestId,
            revision: request.revision,
            reason: SceneInteractionCancellationReason.user,
          ),
        );
        expect(
          port
              .resolve(
                SceneInteractionResult.choiceSelected(
                  requestId: request.requestId,
                  revision: request.revision,
                  selectedOptionId: 'sprout',
                ),
              )
              .status,
          SceneInteractionResolutionStatus.alreadyTerminal,
        );
      },
    );

    test('stale revisions never complete the active request', () async {
      final port = HeadlessSceneInteractionPort();
      final request = _choiceRequest(revision: 8);
      final future = port.request(request);

      expect(
        port
            .resolve(
              SceneInteractionResult.choiceSelected(
                requestId: request.requestId,
                revision: 7,
                selectedOptionId: 'sprout',
              ),
            )
            .status,
        SceneInteractionResolutionStatus.staleRevision,
      );
      expect(port.pendingRequests, [request]);

      port.resolve(
        SceneInteractionResult.choiceSelected(
          requestId: request.requestId,
          revision: 8,
          selectedOptionId: 'wave',
        ),
      );
      expect(
        await future,
        SceneInteractionResult.choiceSelected(
          requestId: request.requestId,
          revision: 8,
          selectedOptionId: 'wave',
        ),
      );
    });

    test('timeout cancels once and ignores a later adapter reply', () async {
      final port = HeadlessSceneInteractionPort();
      final request = SceneInteractionRequest.confirmation(
        requestId: 'confirm',
        revision: 1,
        prompt: SceneInteractionPrompt(
          localizationKey: 'confirm.prompt',
          fallbackText: 'Continuer ?',
        ),
        timeout: const Duration(milliseconds: 5),
      );

      final result = await port.request(request);

      expect(
        result,
        SceneInteractionResult.cancelled(
          requestId: 'confirm',
          revision: 1,
          reason: SceneInteractionCancellationReason.timeout,
        ),
      );
      expect(
        port
            .resolve(
              SceneInteractionResult.confirmed(
                requestId: 'confirm',
                revision: 1,
                value: true,
              ),
            )
            .status,
        SceneInteractionResolutionStatus.alreadyTerminal,
      );
    });

    test('fake headless adapter handles every kind without widgets', () async {
      final port = HeadlessSceneInteractionPort();
      final requests = <SceneInteractionRequest>[
        SceneInteractionRequest.message(
          requestId: 'message',
          revision: 1,
          prompt: _prompt('message'),
        ),
        _choiceRequest(revision: 1),
        SceneInteractionRequest.text(
          requestId: 'text',
          revision: 1,
          prompt: _prompt('text'),
        ),
        SceneInteractionRequest.confirmation(
          requestId: 'confirmation',
          revision: 1,
          prompt: _prompt('confirmation'),
        ),
        SceneInteractionRequest.selection(
          requestId: 'selection',
          revision: 1,
          prompt: _prompt('selection'),
          options: _options,
        ),
      ];
      final expected = <SceneInteractionResult>[
        SceneInteractionResult.acknowledged(requestId: 'message', revision: 1),
        SceneInteractionResult.choiceSelected(
          requestId: 'starter',
          revision: 1,
          selectedOptionId: 'sprout',
        ),
        SceneInteractionResult.textSubmitted(
          requestId: 'text',
          revision: 1,
          value: 'Yoahn',
        ),
        SceneInteractionResult.confirmed(
          requestId: 'confirmation',
          revision: 1,
          value: true,
        ),
        SceneInteractionResult.selectionSubmitted(
          requestId: 'selection',
          revision: 1,
          selectedOptionIds: const ['wave'],
        ),
      ];

      for (var index = 0; index < requests.length; index++) {
        final future = port.request(requests[index]);
        expect(port.resolve(expected[index]).isAccepted, isTrue);
        expect(await future, expected[index]);
      }
      expect(port.pendingRequests, isEmpty);
    });

    test(
      'invalid response remains non-terminal so the adapter can retry',
      () async {
        final port = HeadlessSceneInteractionPort();
        final request = _choiceRequest(revision: 1);
        final future = port.request(request);

        final rejected = port.resolve(
          SceneInteractionResult.choiceSelected(
            requestId: request.requestId,
            revision: request.revision,
            selectedOptionId: 'missing',
          ),
        );
        expect(rejected.status, SceneInteractionResolutionStatus.invalidResult);
        expect(rejected.validationIssues, isNotEmpty);
        expect(port.pendingRequests, [request]);

        port.resolve(
          SceneInteractionResult.choiceSelected(
            requestId: request.requestId,
            revision: request.revision,
            selectedOptionId: 'sprout',
          ),
        );
        expect((await future).kind, SceneInteractionResultKind.choiceSelected);
      },
    );

    test(
      'closing cancels pending requests once and rejects new work',
      () async {
        final port = HeadlessSceneInteractionPort();
        final request = _choiceRequest(revision: 1);
        final future = port.request(request);

        port.close();
        port.close();

        expect(
          await future,
          SceneInteractionResult.cancelled(
            requestId: request.requestId,
            revision: request.revision,
            reason: SceneInteractionCancellationReason.disposed,
          ),
        );
        expect(port.pendingRequests, isEmpty);
        await expectLater(
          port.request(_choiceRequest(revision: 2)),
          throwsA(
            isA<SceneInteractionPortException>().having(
              (error) => error.code,
              'code',
              SceneInteractionPortErrorCode.portClosed,
            ),
          ),
        );
      },
    );
  });
}

SceneInteractionRequest _choiceRequest({required int revision}) =>
    SceneInteractionRequest.choice(
      requestId: 'starter',
      revision: revision,
      prompt: _prompt('starter'),
      options: _options,
    );

SceneInteractionPrompt _prompt(String id) =>
    SceneInteractionPrompt(localizationKey: '$id.prompt', fallbackText: id);

final _options = <SceneInteractionOption>[
  SceneInteractionOption(id: 'sprout', label: _prompt('sprout')),
  SceneInteractionOption(id: 'wave', label: _prompt('wave')),
];
