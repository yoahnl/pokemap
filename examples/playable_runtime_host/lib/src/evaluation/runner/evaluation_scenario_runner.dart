import 'dart:async';

import '../contracts/evaluation_event.dart';
import '../contracts/evaluation_policy.dart';
import '../contracts/evaluation_receipt.dart';
import '../contracts/evaluation_scenario.dart';
import '../contracts/evaluation_state_snapshot.dart';
import '../driver/evaluation_driver.dart';
import '../scenario/evaluation_command_catalog.dart';
import '../scenario/evaluation_policy_validator.dart';
import 'evaluation_assertion_evaluator.dart';
import 'evaluation_command_dispatcher.dart';
import 'evaluation_run_control.dart';
import 'evaluation_state_diff.dart';

typedef EvaluationEventSink = void Function(EvaluationEvent event);
typedef EvaluationEvidenceCapture = Future<void> Function({
  required String stepId,
  String? name,
});

final class EvaluationScenarioRunResult {
  EvaluationScenarioRunResult({
    required this.runId,
    required this.status,
    required this.evidenceLevel,
    required this.initialState,
    required this.finalState,
    required this.diff,
    required List<EvaluationStepResult> stepResults,
    required List<EvaluationProductCriterionResult> productCriteria,
    required List<EvaluationEvent> events,
    required List<String> shortcutsUsed,
    this.error,
  })  : stepResults = List<EvaluationStepResult>.unmodifiable(stepResults),
        productCriteria = List<EvaluationProductCriterionResult>.unmodifiable(
          productCriteria,
        ),
        events = List<EvaluationEvent>.unmodifiable(events),
        shortcutsUsed = List<String>.unmodifiable(shortcutsUsed);

  final String runId;
  final EvaluationRunStatus status;
  final EvaluationEvidenceLevel evidenceLevel;
  final EvaluationStateSnapshot initialState;
  final EvaluationStateSnapshot finalState;
  final EvaluationStateDiff diff;
  final List<EvaluationStepResult> stepResults;
  final List<EvaluationProductCriterionResult> productCriteria;
  final List<EvaluationEvent> events;
  final List<String> shortcutsUsed;
  final Map<String, Object?>? error;
}

final class EvaluationScenarioRunner {
  EvaluationScenarioRunner({
    required this.driver,
    this.eventSink,
    EvaluationAssertionEvaluator assertionEvaluator =
        const EvaluationAssertionEvaluator(),
    EvaluationPolicyValidator policyValidator =
        const EvaluationPolicyValidator(),
    EvaluationStateDiffer stateDiffer = const EvaluationStateDiffer(),
    String Function()? runIdFactory,
    this.checkpointProvenance,
    this.runControl,
    this.evidenceCapture,
  })  : _assertionEvaluator = assertionEvaluator,
        _policyValidator = policyValidator,
        _stateDiffer = stateDiffer,
        _runIdFactory = runIdFactory ?? _defaultRunId;

  final EvaluationDriver driver;
  final EvaluationEventSink? eventSink;
  final EvaluationAssertionEvaluator _assertionEvaluator;
  final EvaluationPolicyValidator _policyValidator;
  final EvaluationStateDiffer _stateDiffer;
  final String Function() _runIdFactory;
  final Map<String, Object?>? checkpointProvenance;
  final EvaluationRunControl? runControl;
  final EvaluationEvidenceCapture? evidenceCapture;

  Future<EvaluationScenarioRunResult> run(EvaluationScenario scenario) async {
    final runId = _runIdFactory();
    final events = <EvaluationEvent>[];
    final stepResults = <EvaluationStepResult>[];
    final shortcutsUsed = <String>[];
    var sequence = 0;

    void emit(String type, Map<String, Object?> payload) {
      final event = EvaluationEvent(
        runId: runId,
        sequence: sequence += 1,
        type: type,
        payload: payload,
      );
      events.add(event);
      eventSink?.call(event);
    }

    StreamSubscription<EvaluationRunControlTransition>? controlSubscription;
    if (runControl case final control?) {
      controlSubscription = control.transitions.listen((transition) {
        emit(transition.eventType, <String, Object?>{
          'state': transition.state.name,
          'previousState': transition.previousState.name,
        });
      });
    }

    final initialState = driver.snapshot();
    var status = EvaluationRunStatus.succeeded;
    Map<String, Object?>? error;
    EvaluationEvidenceLevel maximumEvidenceLevel =
        EvaluationEvidenceLevel.diagnosticOnly;

    try {
      maximumEvidenceLevel = _policyValidator.maximumEvidenceLevelFor(scenario);
    } on EvaluationPolicyViolation catch (failure) {
      status = EvaluationRunStatus.policyViolation;
      error = <String, Object?>{
        'kind': 'policyViolation',
        'stepId': failure.stepId,
        'operation': failure.operation,
        'message': failure.reason,
      };
    }

    emit('run.started', <String, Object?>{
      'scenarioId': scenario.id,
      'policy': scenario.policy.name,
      'initialState': initialState.toJson(),
      if (checkpointProvenance != null)
        'checkpointProvenance': checkpointProvenance,
    });
    if (runControl case final control?
        when control.state != EvaluationControlState.running) {
      emit(
        switch (control.state) {
          EvaluationControlState.paused => 'run.paused',
          EvaluationControlState.cancelled => 'run.cancelled',
          EvaluationControlState.running => 'run.resumed',
        },
        <String, Object?>{
          'state': control.state.name,
          'previousState': null,
        },
      );
    }

    if (status == EvaluationRunStatus.succeeded) {
      try {
        await switch (scenario.start) {
          EvaluationNewGameStart() => driver.startNewGame(),
          EvaluationCheckpointStart(:final checkpointId) =>
            driver.probeLoadCheckpoint(checkpointId),
        };
      } catch (failure) {
        status = EvaluationRunStatus.failed;
        error = _failureJson(failure);
      }
    }

    if (status == EvaluationRunStatus.succeeded) {
      for (var index = 0; index < scenario.steps.length; index += 1) {
        try {
          await runControl?.beforeStep();
        } on EvaluationRunCancelled catch (failure) {
          status = EvaluationRunStatus.cancelled;
          error = <String, Object?>{
            'kind': 'cancelled',
            'message': failure.toString(),
          };
          break;
        }
        final step = scenario.steps[index];
        emit('step.started', <String, Object?>{
          'index': index,
          'stepId': step.id,
          'kind': step is EvaluationCommandStep ? 'command' : 'assertion',
        });

        EvaluationStepResult result;
        var stop = false;
        try {
          result = switch (step) {
            EvaluationCommandStep() => await _executeCommand(
                step: step,
                index: index,
                shortcutsUsed: shortcutsUsed,
                emit: emit,
              ),
            EvaluationAssertionStep() => _executeAssertion(
                step: step,
                index: index,
              ),
          };
          if (!result.passed) {
            status = EvaluationRunStatus.failed;
            stop = scenario.policy == EvaluationPolicy.certify;
          }
        } on EvaluationAssertionDefinitionError catch (failure) {
          status = EvaluationRunStatus.invalidScenario;
          error = <String, Object?>{
            'kind': 'invalidAssertion',
            'stepId': step.id,
            'message': failure.message,
          };
          result = EvaluationStepResult(
            index: index,
            stepId: step.id,
            passed: false,
            details: error,
          );
          stop = true;
        } on EvaluationScenarioExecutionError catch (failure) {
          status = EvaluationRunStatus.invalidScenario;
          error = <String, Object?>{
            'kind': 'invalidCommand',
            'stepId': step.id,
            'message': failure.message,
          };
          result = EvaluationStepResult(
            index: index,
            stepId: step.id,
            passed: false,
            details: error,
          );
          stop = true;
        } catch (failure) {
          status = EvaluationRunStatus.failed;
          error = _failureJson(failure);
          result = EvaluationStepResult(
            index: index,
            stepId: step.id,
            passed: false,
            details: error,
          );
          stop = true;
        }
        if (runControl?.state == EvaluationControlState.cancelled) {
          status = EvaluationRunStatus.cancelled;
          error = <String, Object?>{
            'kind': 'cancelled',
            'message': const EvaluationRunCancelled().toString(),
          };
          stop = true;
        }
        stepResults.add(result);
        emit('step.finished', <String, Object?>{
          ...result.toJson(),
          'status': status.name,
        });
        if (stop) break;
      }
    }

    final finalState = driver.snapshot();
    final diff = _stateDiffer.compare(initialState, finalState);
    final productCriteria = _calculateCriteria(
      scenario.criteria,
      stepResults,
    );
    final evidenceLevel = _effectiveEvidenceLevel(
      maximum: maximumEvidenceLevel,
      status: status,
      criteria: productCriteria,
      declaredCriterionCount: scenario.criteria.length,
      shortcutsUsed: shortcutsUsed,
    );
    await controlSubscription?.cancel();
    emit('run.finished', <String, Object?>{
      'status': status.name,
      'evidenceLevel': evidenceLevel.name,
      'diff': diff.toJson(),
      'productCriteria':
          productCriteria.map((criterion) => criterion.toJson()).toList(),
      if (error != null) 'error': error,
    });

    return EvaluationScenarioRunResult(
      runId: runId,
      status: status,
      evidenceLevel: evidenceLevel,
      initialState: initialState,
      finalState: finalState,
      diff: diff,
      stepResults: stepResults,
      productCriteria: productCriteria,
      events: events,
      shortcutsUsed: shortcutsUsed,
      error: error,
    );
  }

  Future<EvaluationStepResult> _executeCommand({
    required EvaluationCommandStep step,
    required int index,
    required List<String> shortcutsUsed,
    required void Function(String, Map<String, Object?>) emit,
  }) async {
    final before = driver.snapshot();
    await const EvaluationCommandDispatcher().execute(
      driver: driver,
      commandId: step.id,
      operation: step.operation,
      arguments: step.arguments,
      evidenceCapture: evidenceCapture,
    );
    if (evaluationCommandCatalog[step.operation]?.probeOnly ?? false) {
      shortcutsUsed.add(step.operation);
    }
    final after = driver.snapshot();
    if (before.digestSha256 != after.digestSha256) {
      emit('state.changed', <String, Object?>{
        'stepId': step.id,
        'beforeDigest': before.digestSha256,
        'afterDigest': after.digestSha256,
        'diff': _stateDiffer.compare(before, after).toJson(),
      });
    }
    return EvaluationStepResult(
      index: index,
      stepId: step.id,
      passed: true,
      details: <String, Object?>{
        'kind': 'command',
        'operation': step.operation,
        'beforeDigest': before.digestSha256,
        'afterDigest': after.digestSha256,
      },
    );
  }

  EvaluationStepResult _executeAssertion({
    required EvaluationAssertionStep step,
    required int index,
  }) {
    final assertion = _assertionEvaluator.evaluate(step, driver.snapshot());
    return EvaluationStepResult(
      index: index,
      stepId: step.id,
      passed: assertion.passed,
      details: <String, Object?>{
        'kind': 'assertion',
        ...assertion.toJson(),
      },
    );
  }
}

List<EvaluationProductCriterionResult> _calculateCriteria(
  List<EvaluationCriterionDefinition> definitions,
  List<EvaluationStepResult> results,
) {
  return definitions.map((definition) {
    final matches = <String, List<EvaluationStepResult>>{};
    for (final result in results) {
      matches
          .putIfAbsent(result.stepId, () => <EvaluationStepResult>[])
          .add(result);
    }
    final passed = definition.stepIds.every((stepId) {
      final stepMatches = matches[stepId] ?? const <EvaluationStepResult>[];
      return stepMatches.length == 1 && stepMatches.single.passed;
    });
    return EvaluationProductCriterionResult(
      id: definition.id,
      summary: passed
          ? 'All referenced scenario steps completed successfully.'
          : 'At least one referenced scenario step was missing, skipped, '
              'duplicated, or failed.',
      passed: passed,
    );
  }).toList(growable: false);
}

EvaluationEvidenceLevel _effectiveEvidenceLevel({
  required EvaluationEvidenceLevel maximum,
  required EvaluationRunStatus status,
  required List<EvaluationProductCriterionResult> criteria,
  required int declaredCriterionCount,
  required List<String> shortcutsUsed,
}) {
  if (status != EvaluationRunStatus.succeeded || shortcutsUsed.isNotEmpty) {
    return EvaluationEvidenceLevel.diagnosticOnly;
  }
  if (maximum == EvaluationEvidenceLevel.releaseEvidence &&
      (declaredCriterionCount == 0 ||
          criteria.length != declaredCriterionCount ||
          criteria.any((criterion) => !criterion.passed))) {
    return EvaluationEvidenceLevel.segmentEvidence;
  }
  return maximum;
}

Map<String, Object?> _failureJson(Object failure) {
  if (failure
      case EvaluationDriverFailure(
        :final operation,
        :final message,
        :final snapshot,
      )) {
    return <String, Object?>{
      'kind': 'driverFailure',
      'operation': operation,
      'message': message,
      'snapshot': snapshot.toJson(),
    };
  }
  return <String, Object?>{
    'kind': 'executionFailure',
    'message': failure.toString(),
  };
}

String _defaultRunId() {
  return 'run-${DateTime.now().toUtc().microsecondsSinceEpoch}';
}
