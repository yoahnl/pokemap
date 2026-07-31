import 'dart:async';
import 'dart:math';

import '../contracts/authoring_request.dart';
import '../support/authoring_fingerprint.dart';
import '../workspace/project_snapshot.dart';
import 'authoring_plan.dart';
import 'plan_store.dart';

typedef AuthoringPlanTokenFactory = String Function(String prefix);
typedef AuthoringPlanSeedFactory = int Function();
typedef AuthoringMutationBuilder = FutureOr<AuthoringMutationDraft> Function(
  AuthoringPlanningContext context,
);
typedef ProjectedStateValidator = void Function(
  ProjectSnapshot snapshot,
  AuthoringMutationDraft draft,
);

/// Deterministic ID allocation available only during the pure planning pass.
final class AuthoringPlanningContext {
  AuthoringPlanningContext({
    required this.snapshot,
    required this.request,
    required this.planId,
    required this.seed,
  });

  final ProjectSnapshot snapshot;
  final AuthoringRequest request;
  final String planId;
  final int seed;
  final Map<String, int> _nextIndexByNamespace = {};

  String generateId(String namespace) {
    final normalized = namespace.trim();
    if (!RegExp(r'^[a-z][a-zA-Z0-9_]*$').hasMatch(normalized)) {
      throw ArgumentError.value(
        namespace,
        'namespace',
        'must be a stable lower-camel identifier',
      );
    }
    final index = _nextIndexByNamespace.update(
      normalized,
      (value) => value + 1,
      ifAbsent: () => 0,
    );
    final fingerprint = computeAuthoringJsonFingerprint(
      {
        'planId': planId,
        'seed': seed,
        'namespace': normalized,
        'index': index,
      },
      logicalName: 'generated-id.json',
    );
    return '${normalized}_${fingerprint.substring(7, 23)}';
  }
}

/// Builds and validates a plan without receiving any filesystem write port.
final class AuthoringActionPlanner {
  AuthoringActionPlanner({
    required AuthoringPlanStore store,
    AuthoringPlanTokenFactory? tokenFactory,
    AuthoringPlanSeedFactory? seedFactory,
  })  : _store = store,
        _tokenFactory = tokenFactory ?? _secureToken,
        _seedFactory = seedFactory ?? _secureSeed;

  final AuthoringPlanStore _store;
  final AuthoringPlanTokenFactory _tokenFactory;
  final AuthoringPlanSeedFactory _seedFactory;

  Future<AuthoringPlan> plan({
    required AuthoringRequest request,
    required ProjectSnapshot snapshot,
    required AuthoringMutationBuilder build,
    ProjectedStateValidator? validateProjectedState,
  }) async {
    final expectedRevision = request.expectedRevision;
    if (expectedRevision == null) {
      throw AuthoringPlanException(
        code: 'plan.expected_revision_required',
        message: 'Mutation planning requires an expected project revision.',
        remediation: const [
          'Reload the project and plan against its current revision.',
        ],
      );
    }
    if (expectedRevision != snapshot.revision) {
      throw AuthoringPlanException(
        code: 'plan.stale',
        message: 'The requested revision is not the current project revision.',
        remediation: const [
          'Create a new plan from the latest project revision.',
        ],
      );
    }

    final planId = _nextUniquePlanId();
    final receiptId = _validatedToken('receipt_');
    final seed = _seedFactory();
    if (seed < 0) {
      throw ArgumentError.value(seed, 'seedFactory', 'must not be negative');
    }
    final createdAt = _store.now;
    final context = AuthoringPlanningContext(
      snapshot: snapshot,
      request: request,
      planId: planId,
      seed: seed,
    );
    final draft = await build(context);
    validateProjectedState?.call(snapshot, draft);
    final plan = AuthoringPlan(
      planId: planId,
      receiptId: receiptId,
      request: request,
      baseRevision: snapshot.revision,
      seed: seed,
      createdAt: createdAt,
      expiresAt: createdAt.add(_store.ttl),
      changeSet: draft.changeSet,
      preview: draft.preview,
      referenceImpact: draft.referenceImpact,
      artifacts: draft.artifacts,
    );
    _store.save(plan);
    return plan;
  }

  String _nextUniquePlanId() {
    for (var attempt = 0; attempt < 32; attempt++) {
      final planId = _validatedToken('plan_');
      if (!_store.contains(planId)) return planId;
    }
    throw StateError('Unable to allocate a unique authoring plan identity.');
  }

  String _validatedToken(String prefix) {
    final rawValue = _tokenFactory(prefix);
    final value = rawValue.trim();
    if (value != rawValue ||
        !value.startsWith(prefix) ||
        value.length <= prefix.length) {
      throw ArgumentError.value(
        value,
        'tokenFactory',
        'must return a nonblank token beginning with $prefix',
      );
    }
    return value;
  }
}

String _secureToken(String prefix) {
  final random = Random.secure();
  final body = List.generate(
    24,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  return '$prefix$body';
}

int _secureSeed() {
  final random = Random.secure();
  return random.nextInt(1 << 31);
}
