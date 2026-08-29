import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'narrative_action_support.dart';

final class RailJourneyAuthoringException implements Exception {
  const RailJourneyAuthoringException(
    this.code,
    this.message, {
    this.details = const <String, Object?>{},
  });

  final String code;
  final String message;
  final Map<String, Object?> details;

  @override
  String toString() => 'RailJourneyAuthoringException($code): $message';
}

final class RailJourneyActions {
  const RailJourneyActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable(
    <AuthoringActionDescriptor>[
      narrativeActionDescriptor(
        'rail_journey.upsert',
        'Create or replace one RailJourney definition',
        resourceKinds: const <String>['project', 'railJourney'],
      ),
      narrativeActionDescriptor(
        'rail_journey.delete',
        'Delete one RailJourney definition',
        resourceKinds: const <String>['project', 'railJourney'],
        risk: AuthoringRiskLevel.high,
      ),
    ],
  );

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = context.request.parameters;
    switch (context.request.actionId) {
      case 'rail_journey.upsert':
        rejectUnknownNarrativeParameters(parameters, const {'journey'});
        final journey = _decodeJourney(
          narrativeObjectParameter(parameters, 'journey'),
        );
        final before = context.snapshot.manifest.railJourneyCatalog?.journeys
            .where((candidate) => candidate.id == journey.id)
            .firstOrNull;
        final projected = upsert(
          context.snapshot.manifest,
          journey: journey,
        );
        _validateProjected(context, projected);
        return _draft(
          context,
          projected,
          journeyId: journey.id,
          before: before?.toJson(),
          after: journey.toJson(),
        );
      case 'rail_journey.delete':
        rejectUnknownNarrativeParameters(parameters, const {'journeyId'});
        final journeyId = narrativeStringParameter(parameters, 'journeyId');
        final before = context.snapshot.manifest.railJourneyCatalog?.journeys
            .where((candidate) => candidate.id == journeyId)
            .firstOrNull;
        final projected = delete(
          context.snapshot.manifest,
          journeyId: journeyId,
        );
        _validateProjected(context, projected);
        return _draft(
          context,
          projected,
          journeyId: journeyId,
          before: before?.toJson(),
        );
      default:
        throw RailJourneyAuthoringException(
          'rail_journey.action_unsupported',
          'The requested RailJourney action is unsupported.',
          details: <String, Object?>{'actionId': context.request.actionId},
        );
    }
  }

  ProjectManifest upsert(
    ProjectManifest project, {
    required RailJourneyDefinition journey,
  }) {
    final normalized = _validateJourney(journey);
    final current =
        project.railJourneyCatalog?.journeys ?? const <RailJourneyDefinition>[];
    final journeys = <RailJourneyDefinition>[
      for (final candidate in current)
        if (candidate.id != normalized.id) candidate,
      normalized,
    ]..sort((left, right) => left.id.compareTo(right.id));
    return project.copyWith(
      railJourneyCatalog: RailJourneyCatalog(
        journeys: journeys,
      ).validated(),
    );
  }

  ProjectManifest delete(
    ProjectManifest project, {
    required String journeyId,
  }) {
    final normalizedId = journeyId.trim();
    if (normalizedId.isEmpty || normalizedId != journeyId) {
      throw const RailJourneyAuthoringException(
        'rail_journey.id_invalid',
        'The RailJourney identity must be nonblank and trimmed.',
      );
    }
    final catalog = project.railJourneyCatalog;
    if (catalog == null ||
        !catalog.journeys.any((journey) => journey.id == normalizedId)) {
      throw RailJourneyAuthoringException(
        'rail_journey.not_found',
        'The RailJourney definition does not exist.',
        details: <String, Object?>{'journeyId': normalizedId},
      );
    }
    final usages = buildNarrativeDependencyIndex(project: project)
        .usagesFor(NarrativeDependencyKey.railJourney(normalizedId))
        .toList()
      ..sort((left, right) => left.path.compareTo(right.path));
    if (usages.isNotEmpty) {
      throw RailJourneyAuthoringException(
        'rail_journey.referenced',
        'The RailJourney definition is still referenced by a Scene.',
        details: <String, Object?>{
          'journeyId': normalizedId,
          'consumerPaths':
              usages.map((usage) => usage.path).toList(growable: false),
        },
      );
    }
    final journeys = <RailJourneyDefinition>[
      for (final journey in catalog.journeys)
        if (journey.id != normalizedId) journey,
    ];
    return project.copyWith(
      railJourneyCatalog: journeys.isEmpty
          ? null
          : RailJourneyCatalog(
              schemaVersion: catalog.schemaVersion,
              journeys: journeys,
            ).validated(),
    );
  }
}

RailJourneyDefinition _decodeJourney(Map<String, dynamic> json) {
  try {
    return RailJourneyDefinition.fromJson(json);
  } on Object catch (error) {
    throw RailJourneyAuthoringException(
      'rail_journey.invalid',
      'The RailJourney definition cannot be decoded.',
      details: <String, Object?>{
        'validationType': error.runtimeType.toString(),
      },
    );
  }
}

RailJourneyDefinition _validateJourney(RailJourneyDefinition journey) {
  try {
    return journey.validated();
  } on Object catch (error) {
    throw RailJourneyAuthoringException(
      'rail_journey.invalid',
      'The RailJourney definition is invalid.',
      details: <String, Object?>{
        'journeyId': journey.id,
        'validationType': error.runtimeType.toString(),
      },
    );
  }
}

void _validateProjected(
  AuthoringPlanningContext context,
  ProjectManifest projected,
) {
  try {
    ProjectValidator.validate(
      projected,
      maps: context.snapshot.maps,
      itemCatalog: context.snapshot.itemCatalog,
    );
  } on ValidationException catch (error) {
    throw RailJourneyAuthoringException(
      error.code ?? 'rail_journey.project_invalid',
      error.message,
      details: error.details,
    );
  }
}

AuthoringMutationDraft _draft(
  AuthoringPlanningContext context,
  ProjectManifest projected, {
  required String journeyId,
  Object? before,
  Object? after,
}) {
  final catalog = projected.railJourneyCatalog;
  return narrativeProjectDraft(
    context.snapshot,
    projected,
    operation: context.request.actionId,
    path: '/railJourneyCatalog/journeys/$journeyId',
    before: before,
    after: after,
    preview: <String, Object?>{
      'resourceKind': 'railJourney',
      'journeyId': journeyId,
      'schemaVersion': catalog?.schemaVersion ?? railJourneySchemaVersion,
      'journeyCount': catalog?.journeys.length ?? 0,
    },
  );
}
