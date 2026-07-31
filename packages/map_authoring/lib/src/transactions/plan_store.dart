import 'authoring_plan.dart';

typedef AuthoringPlanClock = DateTime Function();

final class AuthoringPlanException implements Exception {
  AuthoringPlanException({
    required this.code,
    required this.message,
    Iterable<String> remediation = const [],
  }) : remediation = List.unmodifiable(remediation);

  final String code;
  final String message;
  final List<String> remediation;

  @override
  String toString() => 'AuthoringPlanException($code): $message';
}

/// In-memory store for opaque, short-lived plans.
///
/// Persistence starts only once a write journal is prepared. Keeping preview
/// plans ephemeral ensures an expired client proposal cannot become a latent
/// write intent after the project has changed.
final class AuthoringPlanStore {
  AuthoringPlanStore({
    AuthoringPlanClock? clock,
    this.ttl = const Duration(minutes: 10),
  }) : _clock = clock ?? _systemClock {
    if (ttl <= Duration.zero) {
      throw ArgumentError.value(ttl, 'ttl', 'must be positive');
    }
  }

  final AuthoringPlanClock _clock;
  final Duration ttl;
  final Map<String, AuthoringPlan> _plans = {};

  int get length => _plans.length;
  DateTime get now => _clock().toUtc();

  bool contains(String planId) => _plans.containsKey(planId);

  void save(AuthoringPlan plan) {
    if (_plans.containsKey(plan.planId)) {
      throw ArgumentError.value(
        plan.planId,
        'plan',
        'plan identity already exists',
      );
    }
    if (!plan.expiresAt.isAfter(now)) {
      throw ArgumentError.value(
        plan.expiresAt,
        'plan',
        'cannot save an expired plan',
      );
    }
    _plans[plan.planId] = plan;
  }

  AuthoringPlan resolve(
    String planId, {
    required String currentProjectRevision,
  }) {
    final plan = _plans[planId];
    if (plan == null) {
      throw AuthoringPlanException(
        code: 'plan.unknown',
        message: 'The requested authoring plan is unknown.',
        remediation: const ['Create a new plan before applying the mutation.'],
      );
    }
    if (!now.isBefore(plan.expiresAt)) {
      throw AuthoringPlanException(
        code: 'plan.expired',
        message: 'The requested authoring plan has expired.',
        remediation: const [
          'Create a new plan before applying the mutation.',
        ],
      );
    }
    if (currentProjectRevision != plan.baseRevision) {
      throw AuthoringPlanException(
        code: 'plan.stale',
        message: 'The project changed after this plan was created.',
        remediation: const [
          'Create a new plan from the latest project revision.',
        ],
      );
    }
    return plan;
  }

  bool discard(String planId) => _plans.remove(planId) != null;
}

DateTime _systemClock() => DateTime.now().toUtc();
