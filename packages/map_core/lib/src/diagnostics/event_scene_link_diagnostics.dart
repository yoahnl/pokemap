import '../models/map_data.dart';
import '../models/map_event_definition.dart';
import '../models/project_manifest.dart';
import '../runtime/scene_runtime_plan_builder.dart';
import 'scene_diagnostics.dart';

enum EventSceneLinkDiagnosticSeverity {
  error,
  warning,
  info,
}

enum EventSceneLinkDiagnosticCode {
  eventSceneTargetUnknown,
  eventSceneTargetEmpty,
  eventSceneTargetDisabledPage,
  eventSceneTargetSceneHasErrors,
  eventSceneTargetRuntimePlanNotBuildable,
  eventSceneTargetMixedLegacyContent,
}

final class EventSceneLinkDiagnostic {
  const EventSceneLinkDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    required this.mapId,
    required this.eventId,
    required this.pageNumber,
    required this.pageIndex,
    this.sceneId,
    this.suggestedFixLabel,
  });

  final EventSceneLinkDiagnosticCode code;
  final EventSceneLinkDiagnosticSeverity severity;
  final String message;
  final String mapId;
  final String eventId;
  final int pageNumber;
  final int pageIndex;
  final String? sceneId;
  final String? suggestedFixLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventSceneLinkDiagnostic &&
          other.code == code &&
          other.severity == severity &&
          other.message == message &&
          other.mapId == mapId &&
          other.eventId == eventId &&
          other.pageNumber == pageNumber &&
          other.pageIndex == pageIndex &&
          other.sceneId == sceneId &&
          other.suggestedFixLabel == suggestedFixLabel;

  @override
  int get hashCode => Object.hash(
        code,
        severity,
        message,
        mapId,
        eventId,
        pageNumber,
        pageIndex,
        sceneId,
        suggestedFixLabel,
      );
}

final class EventSceneLinkDiagnosticsReport {
  EventSceneLinkDiagnosticsReport({
    required List<EventSceneLinkDiagnostic> diagnostics,
  }) : _diagnostics = List<EventSceneLinkDiagnostic>.unmodifiable(diagnostics);

  final List<EventSceneLinkDiagnostic> _diagnostics;

  List<EventSceneLinkDiagnostic> get diagnostics => _diagnostics;

  int get count => _diagnostics.length;

  int get errorCount => _diagnostics
      .where((diagnostic) =>
          diagnostic.severity == EventSceneLinkDiagnosticSeverity.error)
      .length;

  int get warningCount => _diagnostics
      .where((diagnostic) =>
          diagnostic.severity == EventSceneLinkDiagnosticSeverity.warning)
      .length;

  int get infoCount => _diagnostics
      .where((diagnostic) =>
          diagnostic.severity == EventSceneLinkDiagnosticSeverity.info)
      .length;

  bool get hasDiagnostics => _diagnostics.isNotEmpty;

  bool get hasErrors => errorCount > 0;

  List<EventSceneLinkDiagnostic> byCode(
    EventSceneLinkDiagnosticCode code,
  ) {
    return List<EventSceneLinkDiagnostic>.unmodifiable(
      _diagnostics.where((diagnostic) => diagnostic.code == code),
    );
  }
}

EventSceneLinkDiagnosticsReport diagnoseEventSceneLinks({
  required ProjectManifest project,
  required Iterable<MapData> maps,
}) {
  final sceneById = {
    for (final scene in project.scenes) scene.id: scene,
  };
  final diagnostics = <EventSceneLinkDiagnostic>[];

  for (final map in maps) {
    for (final event in map.events) {
      for (var pageIndex = 0; pageIndex < event.pages.length; pageIndex++) {
        final page = event.pages[pageIndex];
        final target = page.sceneTarget;
        if (target == null) {
          continue;
        }
        final sceneId = target.sceneId.trim();
        if (sceneId.isEmpty) {
          diagnostics.add(
            EventSceneLinkDiagnostic(
              code: EventSceneLinkDiagnosticCode.eventSceneTargetEmpty,
              severity: EventSceneLinkDiagnosticSeverity.error,
              message: 'La cible Scene V1 de la page d’event est vide.',
              mapId: map.id,
              eventId: event.id,
              pageNumber: page.pageNumber,
              pageIndex: pageIndex,
              suggestedFixLabel: 'Choisir une Scene V1 existante.',
            ),
          );
          continue;
        }

        final scene = sceneById[sceneId];
        if (scene == null) {
          diagnostics.add(
            EventSceneLinkDiagnostic(
              code: EventSceneLinkDiagnosticCode.eventSceneTargetUnknown,
              severity: EventSceneLinkDiagnosticSeverity.error,
              message:
                  'La page d’event cible une Scene V1 introuvable: $sceneId.',
              mapId: map.id,
              eventId: event.id,
              pageNumber: page.pageNumber,
              pageIndex: pageIndex,
              sceneId: sceneId,
              suggestedFixLabel: 'Choisir une Scene V1 existante.',
            ),
          );
          continue;
        }

        if (page.isDisabled) {
          diagnostics.add(
            EventSceneLinkDiagnostic(
              code: EventSceneLinkDiagnosticCode.eventSceneTargetDisabledPage,
              severity: EventSceneLinkDiagnosticSeverity.warning,
              message:
                  'La page d’event est désactivée mais cible une Scene V1.',
              mapId: map.id,
              eventId: event.id,
              pageNumber: page.pageNumber,
              pageIndex: pageIndex,
              sceneId: sceneId,
              suggestedFixLabel:
                  'Réactiver la page ou retirer la cible Scene V1.',
            ),
          );
        }

        if (_hasLegacyPageContent(page)) {
          diagnostics.add(
            EventSceneLinkDiagnostic(
              code: EventSceneLinkDiagnosticCode
                  .eventSceneTargetMixedLegacyContent,
              severity: EventSceneLinkDiagnosticSeverity.warning,
              message:
                  'La page combine une cible Scene V1 avec du contenu legacy.',
              mapId: map.id,
              eventId: event.id,
              pageNumber: page.pageNumber,
              pageIndex: pageIndex,
              sceneId: sceneId,
              suggestedFixLabel:
                  'Vérifier si message/script doivent rester avec la Scene.',
            ),
          );
        }

        if (diagnoseScene(scene).hasErrors) {
          diagnostics.add(
            EventSceneLinkDiagnostic(
              code: EventSceneLinkDiagnosticCode.eventSceneTargetSceneHasErrors,
              severity: EventSceneLinkDiagnosticSeverity.warning,
              message:
                  'La Scene V1 ciblée contient des erreurs de diagnostics.',
              mapId: map.id,
              eventId: event.id,
              pageNumber: page.pageNumber,
              pageIndex: pageIndex,
              sceneId: sceneId,
              suggestedFixLabel:
                  'Corriger la Scene avant tout branchement runtime.',
            ),
          );
        }

        final planResult = buildSceneRuntimePlan(scene);
        if (!planResult.canBuild) {
          diagnostics.add(
            EventSceneLinkDiagnostic(
              code: EventSceneLinkDiagnosticCode
                  .eventSceneTargetRuntimePlanNotBuildable,
              severity: EventSceneLinkDiagnosticSeverity.error,
              message:
                  'La Scene V1 ciblée ne peut pas produire de SceneRuntimePlan.',
              mapId: map.id,
              eventId: event.id,
              pageNumber: page.pageNumber,
              pageIndex: pageIndex,
              sceneId: sceneId,
              suggestedFixLabel:
                  'Corriger les erreurs ou retirer les nodes non supportés.',
            ),
          );
        }
      }
    }
  }

  return EventSceneLinkDiagnosticsReport(diagnostics: diagnostics);
}

bool _hasLegacyPageContent(MapEventPage page) {
  return (page.message?.trim().isNotEmpty ?? false) || page.script != null;
}
