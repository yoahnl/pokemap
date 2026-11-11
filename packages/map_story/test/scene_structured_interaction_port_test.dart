import 'package:map_core/map_core.dart';
import 'package:map_story/map_story.dart';
import 'package:test/test.dart';

void main() {

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
