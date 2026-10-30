import '../contracts/map_edit_operation.dart';
import '../contracts/authoring_receipt.dart';
import '../security/authorization_policy.dart';
import '../transactions/plan_store.dart';
import '../transactions/journaled_transaction.dart';
import '../transactions/revision_set.dart';
import '../workspace/workspace_handle_store.dart';
import 'authoring_mutation_contracts.dart';

abstract interface class AuthoringMapEditPort {
  Future<Map<String, Object?>> mapEdit(
      ProjectHandle projectHandle, MapEditOperation operation,
      {bool Function()? isCancelled});
}

String mapEditReceiptDisposition(
    AuthoringReceipt receipt, MapEditBinding binding) {
  if (receipt.extensions['recoveryOutcome'] == 'compensated') {
    return 'compensated';
  }
  if (receipt.status == AuthoringReceiptStatus.planned ||
      receipt.status == AuthoringReceiptStatus.recovered &&
          receipt.extensions['recoveryOutcome'] != 'resumed') {
    return 'recovery_required';
  }
  return binding.unchanged ? 'unchanged' : 'applied';
}

final class MapEditExecution {
  MapEditExecution(
      {required this.inspect,
      required this.plan,
      required this.apply,
      required this.project,
      required this.discard,
      this.deadline = const Duration(seconds: 5),
      Future<void> Function(Duration)? delay})
      : _delay = delay ?? Future<void>.delayed;

  final Future<Map<String, Object?>?> Function(MapEditOperation) inspect;
  final Future<AuthoringMutationPlanResult> Function(MapEditOperation, int)
      plan;
  final Future<Map<String, Object?>> Function(
      AuthoringMutationPlanResult, void Function()) apply;
  final Future<Map<String, Object?>> Function(AuthoringMutationPlanResult)
      project;
  final Future<void> Function(AuthoringMutationPlanResult) discard;
  final Duration deadline;
  final Future<void> Function(Duration) _delay;

  Future<Map<String, Object?>> execute(MapEditOperation operation,
      {bool Function()? isCancelled}) async {
    final timer = Stopwatch()..start();
    void requireActive() {
      if (isCancelled?.call() == true || timer.elapsed >= deadline) {
        throw AuthoringPlanException(
            code: 'map_edit.cancelled',
            message:
                'The map edit was cancelled or its preparation deadline expired.');
      }
    }

    requireActive();
    final existing = await inspect(operation);
    if (existing != null && !operation.dryRun) return existing;
    for (var attempt = 0; attempt < 3; attempt++) {
      AuthoringMutationPlanResult? prepared;
      var preservePlan = false;
      try {
        requireActive();
        prepared = await plan(operation, attempt);
        requireActive();
        if (operation.dryRun) {
          return {
            'status': 'planned',
            'operationId': operation.operationId,
            'semanticFingerprint': operation.semanticFingerprint,
            ...await project(prepared)
          };
        }
        return await apply(prepared, requireActive);
      } on AuthoringAuthorizationException catch (error) {
        if (error.code != 'confirmation.required' || prepared == null) rethrow;
        preservePlan = true;
        return {
          'status': 'confirmation_required',
          'operationId': operation.operationId,
          'semanticFingerprint': operation.semanticFingerprint,
          ...await project(prepared)
        };
      } on Object catch (error) {
        final durable = await inspect(operation);
        if (durable != null) return durable;
        if (error is JournaledAuthoringTransactionException &&
            error.code == 'map_edit.overlapping_recovery_required') {
          return {
            'status': 'recovery_required',
            'operationId': operation.operationId,
            'code': error.code
          };
        }
        final stale = error is AuthoringRevisionConflict ||
            (error is AuthoringPlanException &&
                const {'plan.stale', 'plan.expired'}.contains(error.code));
        if (!stale) rethrow;
        final wait = Duration(milliseconds: attempt == 0 ? 100 : 250);
        if (attempt == 2 || timer.elapsed + wait >= deadline) {
          return {
            'status': 'busy',
            'operationId': operation.operationId,
            'code': 'map_edit.pre_reservation_contention',
            'attempts': attempt + 1,
            'deadlineMs': deadline.inMilliseconds
          };
        }
        await _delay(wait);
      } finally {
        if (prepared != null && !preservePlan) await discard(prepared);
      }
    }
    throw StateError('Unreachable map edit attempt.');
  }
}
