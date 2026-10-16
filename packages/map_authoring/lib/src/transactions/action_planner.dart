import 'local_authoring_payload.dart';
import 'dart:async';
import 'dart:math';

import '../contracts/authoring_request.dart';
import '../support/authoring_fingerprint.dart';
import '../workspace/project_snapshot.dart';
import 'authoring_plan.dart';
import 'plan_store.dart';
import 'change_set.dart';
import 'authoring_payload.dart';

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
    await _store.collectExpired();
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
    final owner = AuthoringPayloadOwner();
    final context = AuthoringPlanningContext(
        snapshot: snapshot.withPayloadOwner(owner),
        request: request,
        planId: planId,
        seed: seed);
    try {
      final draft = await build(context);
      for (final change in draft.changeSet.changes) {
        for (final payload in [change.beforePayload, change.afterPayload]) {
          if (payload != null && !payload.isInline) owner.own(payload);
        }
      }
      validateProjectedState?.call(snapshot, draft);
      final frozen = await _freezePayloads(draft.changeSet, owner);
      final plan = AuthoringPlan(
          planId: planId,
          receiptId: receiptId,
          request: request,
          baseRevision: snapshot.revision,
          seed: seed,
          createdAt: createdAt,
          expiresAt: createdAt.add(_store.ttl),
          changeSet: frozen,
          payloadOwner: owner,
          preview: draft.preview,
          referenceImpact: draft.referenceImpact,
          artifacts: draft.artifacts);
      _store.save(plan);
      return plan;
    } on Object {
      await owner.release();
      rethrow;
    }
  }

  Future<AuthoringChangeSet> _freezePayloads(
      AuthoringChangeSet changes, AuthoringPayloadOwner owner) async {
    if (changes.changes.isEmpty) return changes;
    final frozen = <AuthoringResourceChange>[];
    for (final change in changes.changes) {
      Future<AuthoringPayload?> freeze(AuthoringPayload? payload) async {
        if (payload == null ||
            !payload.isInline ||
            change.storageKey.endsWith('.json')) {
          return payload;
        }
        return owner.own(await captureAuthoringPayload(
            storageKey: change.storageKey,
            chunks: payload.openRead(),
            byteLength: payload.byteLength,
            resourceRevision: payload.resourceRevision));
      }

      frozen.add(AuthoringResourceChange.withPayloads(
          resource: change.resource,
          storageKey: change.storageKey,
          beforePayload: await freeze(change.beforePayload),
          afterPayload: await freeze(change.afterPayload)));
    }
    return AuthoringChangeSet(changes: frozen, diff: changes.diff);
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
