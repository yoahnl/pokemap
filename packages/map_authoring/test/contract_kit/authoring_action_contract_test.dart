import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import 'authoring_action_contract.dart';

void main() {
  group('FakeAuthoringActionRepository', () {
    test('dry-run returns a plan without mutating state', () {
      final repository = FakeAuthoringActionRepository();
      final request = _request(
        requestId: 'req-plan',
        idempotencyKey: 'idem-plan',
        dryRun: true,
      );

      final result = repository.execute(request);

      AuthoringActionContractKit.expectWellFormed(
        request: request,
        result: result,
      );
      expect(repository.value, 0);
      expect(repository.applyCount, 0);
      expect(result.receipt?.status, AuthoringReceiptStatus.planned);
    });

    test('apply mutates exactly once and returns an applied receipt', () {
      final repository = FakeAuthoringActionRepository();
      final request = _request(
        requestId: 'req-apply',
        idempotencyKey: 'idem-apply',
        dryRun: false,
      );

      final result = repository.execute(request);

      AuthoringActionContractKit.expectWellFormed(
        request: request,
        result: result,
      );
      expect(repository.value, 1);
      expect(repository.applyCount, 1);
      expect(result.receipt?.status, AuthoringReceiptStatus.applied);
    });

    test('retry with the same idempotency key reuses the first result', () {
      final repository = FakeAuthoringActionRepository();
      final firstRequest = _request(
        requestId: 'req-first',
        idempotencyKey: 'idem-shared',
        dryRun: false,
      );
      final retryRequest = _request(
        requestId: 'req-retry',
        idempotencyKey: 'idem-shared',
        dryRun: false,
      );

      final first = repository.execute(firstRequest);
      final retry = repository.execute(retryRequest);

      expect(retry.toJson(), first.toJson());
      expect(repository.value, 1);
      expect(repository.applyCount, 1);
    });
  });
}

AuthoringRequest _request({
  required String requestId,
  required String idempotencyKey,
  required bool dryRun,
}) {
  return AuthoringRequest(
    requestId: requestId,
    actionId: 'fixture.increment',
    actionVersion: 1,
    workspaceHandle: 'workspace:fixture',
    parameters: const {'amount': 1},
    expectedRevision: 'rev-0',
    idempotencyKey: idempotencyKey,
    dryRun: dryRun,
  );
}
