import 'package:meta/meta.dart' show immutable;

import '../models/cinematic_asset.dart';
import '../models/enums.dart';
import '../models/map_data.dart';
import '../models/map_event_definition.dart';
import '../models/project_manifest.dart';
import '../models/project_trainer.dart';
import 'cinematic_stage_map_source_catalog.dart';

enum CinematicActorDisplayPreviewStatus {
  ready,
  incomplete,
  blocked,
  noActors,
}

enum CinematicActorDisplayBindingStatus {
  player,
  mapEntity,
  cinematicOnly,
  unbound,
  missing,
}

enum CinematicActorPreviewPositionStatus {
  resolved,
  missingInitialPlacement,
  missingSource,
  abstractOnly,
  outOfMapBounds,
  unbound,
}

enum CinematicActorPreviewPositionSourceKind {
  none,
  mapEntity,
  mapEvent,
  movementTarget,
  stagePoint,
}

enum CinematicActorPreviewAppearanceStatus {
  spriteReady,
  placeholderOnly,
  missingCharacter,
  missingTileset,
  missingIdleAnimation,
  notRequired,
  unsupported,
}

enum CinematicActorPreviewRenderHint {
  sprite,
  placeholder,
  hidden,
  missing,
}

enum CinematicActorPreviewDirection {
  north,
  south,
  east,
  west,
  unknown,
}

enum CinematicActorPreviewDirectionSource {
  actorFace,
  mapEntityFacing,
  fallback,
}

enum CinematicActorDisplayPreviewDiagnosticSeverity {
  info,
  warning,
  error,
}

enum CinematicActorDisplayPreviewDiagnosticCode {
  actorDisplayNoActors,
  actorDisplayUnknownActor,
  actorDisplayMissingBinding,
  actorDisplayUnboundActor,
  actorDisplayMissingInitialPlacement,
  actorDisplayMissingMapEntity,
  actorDisplayMissingMovementTarget,
  actorDisplayAbstractTargetOnly,
  actorDisplayOutOfMapBounds,
  actorDisplayMissingAppearance,
  actorDisplayUnknownCharacter,
  actorDisplayCharacterMissingTileset,
  actorDisplayCharacterMissingIdleAnimation,
  actorDisplaySpriteUnavailable,
  actorDisplayRuntimeUnsupported,
  actorDisplayDirectionFallback,
  actorDisplayDuplicateActor,
  actorDisplayDuplicateBinding,
  actorDisplayDuplicatePlacement,
  actorDisplayDuplicateAppearance,
  actorDisplayDuplicateMovementTargetBinding,
  actorDisplayOrphanBinding,
  actorDisplayOrphanAppearance,
  actorDisplayOrphanPlacement,
  actorDisplayOrphanMovementTargetBinding,
  actorDisplayMissingStagePoint,
}

@immutable
final class CinematicActorDisplayPreviewDiagnostic {
  const CinematicActorDisplayPreviewDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    this.actorId,
    this.sourceId,
  });

  final CinematicActorDisplayPreviewDiagnosticCode code;
  final CinematicActorDisplayPreviewDiagnosticSeverity severity;
  final String message;
  final String? actorId;
  final String? sourceId;

  bool get isBlocking =>
      severity == CinematicActorDisplayPreviewDiagnosticSeverity.error;
}

@immutable
final class CinematicActorPreviewPosition {
  const CinematicActorPreviewPosition({
    required this.status,
    required this.sourceKind,
    this.x,
    this.y,
    this.sourceId,
    this.sourceLabel,
  });

  final CinematicActorPreviewPositionStatus status;
  final CinematicActorPreviewPositionSourceKind sourceKind;
  final int? x;
  final int? y;
  final String? sourceId;
  final String? sourceLabel;

  bool get isResolved => status == CinematicActorPreviewPositionStatus.resolved;
}

@immutable
final class CinematicActorPreviewAppearance {
  const CinematicActorPreviewAppearance({
    required this.status,
    this.characterId,
    this.characterLabel,
    this.tilesetId,
    this.sourceLabel,
  });

  final CinematicActorPreviewAppearanceStatus status;
  final String? characterId;
  final String? characterLabel;
  final String? tilesetId;
  final String? sourceLabel;

  bool get isSpriteReady =>
      status == CinematicActorPreviewAppearanceStatus.spriteReady;
}

@immutable
final class CinematicActorDisplayPreviewActor {
  CinematicActorDisplayPreviewActor({
    required this.actorId,
    required this.label,
    required this.role,
    required this.bindingStatus,
    required this.bindingKind,
    required this.bindingSourceId,
    required this.bindingSourceLabel,
    required this.position,
    required this.appearance,
    required this.direction,
    required this.directionSource,
    required this.renderHint,
    required List<CinematicActorDisplayPreviewDiagnostic> diagnostics,
  }) : diagnostics = List<CinematicActorDisplayPreviewDiagnostic>.unmodifiable(
          diagnostics,
        );

  final String actorId;
  final String label;
  final String? role;
  final CinematicActorDisplayBindingStatus bindingStatus;
  final CinematicActorBindingKind? bindingKind;
  final String? bindingSourceId;
  final String? bindingSourceLabel;
  final CinematicActorPreviewPosition position;
  final CinematicActorPreviewAppearance appearance;
  final CinematicActorPreviewDirection direction;
  final CinematicActorPreviewDirectionSource directionSource;
  final CinematicActorPreviewRenderHint renderHint;
  final List<CinematicActorDisplayPreviewDiagnostic> diagnostics;

  bool get isRenderable {
    if (!position.isResolved) {
      return false;
    }
    return renderHint == CinematicActorPreviewRenderHint.sprite ||
        renderHint == CinematicActorPreviewRenderHint.placeholder;
  }
}

@immutable
final class CinematicActorDisplayPreviewModel {
  CinematicActorDisplayPreviewModel({
    required this.status,
    required this.summary,
    required List<CinematicActorDisplayPreviewActor> actors,
    required List<CinematicActorDisplayPreviewDiagnostic> diagnostics,
  })  : actors = List<CinematicActorDisplayPreviewActor>.unmodifiable(actors),
        diagnostics = List<CinematicActorDisplayPreviewDiagnostic>.unmodifiable(
          diagnostics,
        );

  final CinematicActorDisplayPreviewStatus status;
  final String summary;
  final List<CinematicActorDisplayPreviewActor> actors;
  final List<CinematicActorDisplayPreviewDiagnostic> diagnostics;

  bool get isReady => status == CinematicActorDisplayPreviewStatus.ready;

  int get renderableActorCount =>
      actors.where((actor) => actor.isRenderable).length;

  CinematicActorDisplayPreviewActor? actorById(String actorId) {
    final normalizedId = actorId.trim();
    for (final actor in actors) {
      if (actor.actorId == normalizedId) {
        return actor;
      }
    }
    return null;
  }
}

CinematicActorDisplayPreviewModel buildCinematicActorDisplayPreviewModel({
  required CinematicAsset cinematic,
  required ProjectManifest project,
  required ProjectMapEntry? stageMap,
  required MapData? mapData,
  CinematicStageMapSourceCatalog? stageMapSourceCatalog,
}) {
  final sourceCatalog = stageMapSourceCatalog ??
      buildCinematicStageMapSourceCatalog(
        stageMap: stageMap,
        mapData: mapData,
      );
  final canUseMapData = sourceCatalog.isAvailable &&
      _canUseMapData(stageMap: stageMap, mapData: mapData);
  final context = cinematic.stageContext ?? CinematicStageContext();
  final diagnostics = <CinematicActorDisplayPreviewDiagnostic>[];
  final requiredActors = <CinematicActorRef>[];
  final requiredActorIds = <String>{};

  for (final actor in cinematic.requiredActors) {
    final actorId = actor.actorId.trim();
    if (requiredActorIds.add(actorId)) {
      requiredActors.add(actor);
    } else {
      diagnostics.add(
        CinematicActorDisplayPreviewDiagnostic(
          code: CinematicActorDisplayPreviewDiagnosticCode
              .actorDisplayDuplicateActor,
          severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
          message: 'Acteur requis en doublon ignore: $actorId.',
          actorId: actorId,
        ),
      );
    }
  }

  if (requiredActors.isEmpty) {
    return CinematicActorDisplayPreviewModel(
      status: CinematicActorDisplayPreviewStatus.noActors,
      summary: 'Aucun acteur requis.',
      actors: const [],
      diagnostics: const [
        CinematicActorDisplayPreviewDiagnostic(
          code: CinematicActorDisplayPreviewDiagnosticCode.actorDisplayNoActors,
          severity: CinematicActorDisplayPreviewDiagnosticSeverity.info,
          message: 'La cinematique ne declare aucun acteur requis.',
        ),
      ],
    );
  }

  final actorBindings = _firstByActorId<CinematicActorBinding>(
    context.actorBindings,
    actorIdOf: (binding) => binding.actorId,
    duplicateCode:
        CinematicActorDisplayPreviewDiagnosticCode.actorDisplayDuplicateBinding,
    requiredActorIds: requiredActorIds,
    diagnostics: diagnostics,
    duplicateMessage: 'Binding acteur en doublon ignore.',
    orphanCode:
        CinematicActorDisplayPreviewDiagnosticCode.actorDisplayOrphanBinding,
    orphanMessage: 'Binding acteur orphelin ignore.',
  );
  final appearanceBindings = _firstByActorId<CinematicActorAppearanceBinding>(
    context.actorAppearanceBindings,
    actorIdOf: (binding) => binding.actorId,
    duplicateCode: CinematicActorDisplayPreviewDiagnosticCode
        .actorDisplayDuplicateAppearance,
    requiredActorIds: requiredActorIds,
    diagnostics: diagnostics,
    duplicateMessage: 'Binding apparence en doublon ignore.',
    orphanCode:
        CinematicActorDisplayPreviewDiagnosticCode.actorDisplayOrphanAppearance,
    orphanMessage: 'Binding apparence orphelin ignore.',
  );
  final placements = _firstByActorId<CinematicActorInitialPlacement>(
    context.initialPlacements,
    actorIdOf: (placement) => placement.actorId,
    duplicateCode: CinematicActorDisplayPreviewDiagnosticCode
        .actorDisplayDuplicatePlacement,
    requiredActorIds: requiredActorIds,
    diagnostics: diagnostics,
    duplicateMessage: 'Placement initial en doublon ignore.',
    orphanCode:
        CinematicActorDisplayPreviewDiagnosticCode.actorDisplayOrphanPlacement,
    orphanMessage: 'Placement initial orphelin ignore.',
  );
  final movementTargets = <String>{};
  for (final target in cinematic.movementTargets) {
    movementTargets.add(target.targetId.trim());
  }
  final movementTargetBindings =
      _firstByMovementTargetId<CinematicMovementTargetBinding>(
    context.movementTargetBindings,
    targetIdOf: (binding) => binding.targetId,
    duplicateCode: CinematicActorDisplayPreviewDiagnosticCode
        .actorDisplayDuplicateMovementTargetBinding,
    knownTargetIds: movementTargets,
    diagnostics: diagnostics,
  );

  final actors = <CinematicActorDisplayPreviewActor>[];
  for (final actorRef in requiredActors) {
    final actorId = actorRef.actorId.trim();
    final actorDiagnostics = <CinematicActorDisplayPreviewDiagnostic>[];
    final binding = actorBindings[actorId];
    final bindingStatus = _bindingStatusOf(binding);
    final bindingEntity = _resolveBindingEntity(
      binding: binding,
      mapData: canUseMapData ? mapData : null,
    );
    final position = _resolvePosition(
      actorId: actorId,
      binding: binding,
      bindingEntity: bindingEntity,
      placement: placements[actorId],
      movementTargetIds: movementTargets,
      movementTargetBindings: movementTargetBindings,
      stagePoints: context.stagePoints,
      mapData: canUseMapData ? mapData : null,
      diagnostics: actorDiagnostics,
    );
    final directionResolution = _resolveDirection(
      cinematic: cinematic,
      actorId: actorId,
      bindingEntity: bindingEntity,
      diagnostics: actorDiagnostics,
    );
    final appearance = _resolveAppearance(
      actorId: actorId,
      binding: binding,
      bindingEntity: bindingEntity,
      appearanceBinding: appearanceBindings[actorId],
      project: project,
      direction: directionResolution.direction,
      diagnostics: actorDiagnostics,
    );
    final renderHint = _renderHintFor(
      bindingStatus: bindingStatus,
      position: position,
      appearance: appearance,
    );
    final bindingSourceId = binding?.mapEntityId?.trim();
    actors.add(
      CinematicActorDisplayPreviewActor(
        actorId: actorId,
        label: _labelOrId(actorRef.label, actorId),
        role: actorRef.role,
        bindingStatus: bindingStatus,
        bindingKind: binding?.kind,
        bindingSourceId: bindingSourceId,
        bindingSourceLabel: bindingEntity == null
            ? bindingSourceId
            : _entityLabel(bindingEntity),
        position: position,
        appearance: appearance,
        direction: directionResolution.direction,
        directionSource: directionResolution.source,
        renderHint: renderHint,
        diagnostics: actorDiagnostics,
      ),
    );
    diagnostics.addAll(actorDiagnostics);
  }

  final status = _modelStatusFor(actors, diagnostics);
  final summary =
      '${actors.length} acteur(s), ${actors.where((actor) => actor.isRenderable).length} projetable(s).';

  return CinematicActorDisplayPreviewModel(
    status: status,
    summary: summary,
    actors: actors,
    diagnostics: diagnostics,
  );
}

CinematicActorDisplayPreviewStatus _modelStatusFor(
  List<CinematicActorDisplayPreviewActor> actors,
  List<CinematicActorDisplayPreviewDiagnostic> diagnostics,
) {
  if (diagnostics.any((diagnostic) => diagnostic.isBlocking)) {
    return CinematicActorDisplayPreviewStatus.blocked;
  }
  if (actors.every((actor) => actor.isRenderable) &&
      diagnostics.every((diagnostic) =>
          diagnostic.severity ==
          CinematicActorDisplayPreviewDiagnosticSeverity.info)) {
    return CinematicActorDisplayPreviewStatus.ready;
  }
  return CinematicActorDisplayPreviewStatus.incomplete;
}

Map<String, T> _firstByActorId<T>(
  Iterable<T> values, {
  required String Function(T value) actorIdOf,
  required CinematicActorDisplayPreviewDiagnosticCode duplicateCode,
  required Set<String> requiredActorIds,
  required List<CinematicActorDisplayPreviewDiagnostic> diagnostics,
  required String duplicateMessage,
  required CinematicActorDisplayPreviewDiagnosticCode orphanCode,
  required String orphanMessage,
}) {
  final byActorId = <String, T>{};
  for (final value in values) {
    final actorId = actorIdOf(value).trim();
    if (!requiredActorIds.contains(actorId)) {
      diagnostics.add(
        CinematicActorDisplayPreviewDiagnostic(
          code: orphanCode,
          severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
          message: '$orphanMessage ActorId: $actorId.',
          actorId: actorId,
        ),
      );
      continue;
    }
    if (byActorId.containsKey(actorId)) {
      diagnostics.add(
        CinematicActorDisplayPreviewDiagnostic(
          code: duplicateCode,
          severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
          message: '$duplicateMessage ActorId: $actorId.',
          actorId: actorId,
        ),
      );
      continue;
    }
    byActorId[actorId] = value;
  }
  return byActorId;
}

Map<String, T> _firstByMovementTargetId<T>(
  Iterable<T> values, {
  required String Function(T value) targetIdOf,
  required CinematicActorDisplayPreviewDiagnosticCode duplicateCode,
  required Set<String> knownTargetIds,
  required List<CinematicActorDisplayPreviewDiagnostic> diagnostics,
}) {
  final byTargetId = <String, T>{};
  for (final value in values) {
    final targetId = targetIdOf(value).trim();
    if (!knownTargetIds.contains(targetId)) {
      diagnostics.add(
        CinematicActorDisplayPreviewDiagnostic(
          code: CinematicActorDisplayPreviewDiagnosticCode
              .actorDisplayOrphanMovementTargetBinding,
          severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
          message: 'Binding de cible deplacement orphelin ignore: $targetId.',
          sourceId: targetId,
        ),
      );
      continue;
    }
    if (byTargetId.containsKey(targetId)) {
      diagnostics.add(
        CinematicActorDisplayPreviewDiagnostic(
          code: duplicateCode,
          severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
          message: 'Binding de cible deplacement en doublon ignore: $targetId.',
          sourceId: targetId,
        ),
      );
      continue;
    }
    byTargetId[targetId] = value;
  }
  return byTargetId;
}

CinematicActorDisplayBindingStatus _bindingStatusOf(
  CinematicActorBinding? binding,
) {
  if (binding == null) {
    return CinematicActorDisplayBindingStatus.missing;
  }
  return switch (binding.kind) {
    CinematicActorBindingKind.player =>
      CinematicActorDisplayBindingStatus.player,
    CinematicActorBindingKind.mapEntity =>
      CinematicActorDisplayBindingStatus.mapEntity,
    CinematicActorBindingKind.cinematicOnly =>
      CinematicActorDisplayBindingStatus.cinematicOnly,
    CinematicActorBindingKind.unbound =>
      CinematicActorDisplayBindingStatus.unbound,
  };
}

MapEntity? _resolveBindingEntity({
  required CinematicActorBinding? binding,
  required MapData? mapData,
}) {
  if (binding?.kind != CinematicActorBindingKind.mapEntity || mapData == null) {
    return null;
  }
  final entityId = binding?.mapEntityId?.trim();
  if (entityId == null || entityId.isEmpty) {
    return null;
  }
  return _entityById(mapData, entityId);
}

CinematicActorPreviewPosition _resolvePosition({
  required String actorId,
  required CinematicActorBinding? binding,
  required MapEntity? bindingEntity,
  required CinematicActorInitialPlacement? placement,
  required Set<String> movementTargetIds,
  required Map<String, CinematicMovementTargetBinding> movementTargetBindings,
  required List<CinematicStagePoint> stagePoints,
  required MapData? mapData,
  required List<CinematicActorDisplayPreviewDiagnostic> diagnostics,
}) {
  if (binding == null) {
    diagnostics.add(
      CinematicActorDisplayPreviewDiagnostic(
        code: CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayMissingBinding,
        severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
        message: 'Aucun binding de scene pour cet acteur.',
        actorId: actorId,
      ),
    );
    return const CinematicActorPreviewPosition(
      status: CinematicActorPreviewPositionStatus.missingInitialPlacement,
      sourceKind: CinematicActorPreviewPositionSourceKind.none,
    );
  }
  if (binding.kind == CinematicActorBindingKind.unbound) {
    diagnostics.add(
      CinematicActorDisplayPreviewDiagnostic(
        code:
            CinematicActorDisplayPreviewDiagnosticCode.actorDisplayUnboundActor,
        severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
        message: 'Acteur non lie volontairement, aucun rendu recommande.',
        actorId: actorId,
      ),
    );
    return const CinematicActorPreviewPosition(
      status: CinematicActorPreviewPositionStatus.unbound,
      sourceKind: CinematicActorPreviewPositionSourceKind.none,
    );
  }
  if (placement == null ||
      placement.kind == CinematicActorInitialPlacementKind.unset) {
    diagnostics.add(
      CinematicActorDisplayPreviewDiagnostic(
        code: CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayMissingInitialPlacement,
        severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
        message: 'Aucun placement initial explicite pour cet acteur.',
        actorId: actorId,
      ),
    );
    return const CinematicActorPreviewPosition(
      status: CinematicActorPreviewPositionStatus.missingInitialPlacement,
      sourceKind: CinematicActorPreviewPositionSourceKind.none,
    );
  }

  return switch (placement.kind) {
    CinematicActorInitialPlacementKind.unset =>
      const CinematicActorPreviewPosition(
        status: CinematicActorPreviewPositionStatus.missingInitialPlacement,
        sourceKind: CinematicActorPreviewPositionSourceKind.none,
      ),
    CinematicActorInitialPlacementKind.fromMapEntity => _positionFromMapEntity(
        actorId: actorId,
        binding: binding,
        entity: bindingEntity,
        mapData: mapData,
        diagnostics: diagnostics,
      ),
    CinematicActorInitialPlacementKind.fromMovementTarget =>
      _positionFromMovementTarget(
        actorId: actorId,
        targetId: placement.targetId,
        movementTargetIds: movementTargetIds,
        movementTargetBindings: movementTargetBindings,
        mapData: mapData,
        diagnostics: diagnostics,
      ),
    CinematicActorInitialPlacementKind.stagePoint => _positionFromStagePoint(
        actorId: actorId,
        stagePointId: placement.stagePointId,
        stagePoints: stagePoints,
        mapData: mapData,
        diagnostics: diagnostics,
      ),
  };
}

CinematicActorPreviewPosition _positionFromStagePoint({
  required String actorId,
  required String? stagePointId,
  required List<CinematicStagePoint> stagePoints,
  required MapData? mapData,
  required List<CinematicActorDisplayPreviewDiagnostic> diagnostics,
}) {
  final normalizedPointId = stagePointId?.trim();
  if (normalizedPointId == null || normalizedPointId.isEmpty) {
    diagnostics.add(
      CinematicActorDisplayPreviewDiagnostic(
        code: CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayMissingInitialPlacement,
        severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
        message: 'Le placement initial de l’acteur n’a pas de Stage Point valide.',
        actorId: actorId,
      ),
    );
    return const CinematicActorPreviewPosition(
      status: CinematicActorPreviewPositionStatus.missingSource,
      sourceKind: CinematicActorPreviewPositionSourceKind.stagePoint,
    );
  }

  CinematicStagePoint? point;
  for (final p in stagePoints) {
    if (p.id == normalizedPointId) {
      point = p;
      break;
    }
  }

  if (point == null) {
    diagnostics.add(
      CinematicActorDisplayPreviewDiagnostic(
        code: CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayMissingStagePoint,
        severity: CinematicActorDisplayPreviewDiagnosticSeverity.error,
        message: 'Le Stage Point de placement initial "$normalizedPointId" est introuvable.',
        actorId: actorId,
        sourceId: normalizedPointId,
      ),
    );
    return CinematicActorPreviewPosition(
      status: CinematicActorPreviewPositionStatus.missingSource,
      sourceKind: CinematicActorPreviewPositionSourceKind.stagePoint,
      sourceId: normalizedPointId,
    );
  }

  final x = point.x.round();
  final y = point.y.round();
  final status = (mapData == null || _pointInBounds(x: x, y: y, mapData: mapData))
      ? CinematicActorPreviewPositionStatus.resolved
      : CinematicActorPreviewPositionStatus.outOfMapBounds;

  if (status == CinematicActorPreviewPositionStatus.outOfMapBounds) {
    diagnostics.add(
      CinematicActorDisplayPreviewDiagnostic(
        code: CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayOutOfMapBounds,
        severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
        message: 'Position du Stage Point "$normalizedPointId" hors limites de map.',
        actorId: actorId,
        sourceId: normalizedPointId,
      ),
    );
  }

  return CinematicActorPreviewPosition(
    status: status,
    sourceKind: CinematicActorPreviewPositionSourceKind.stagePoint,
    x: x,
    y: y,
    sourceId: point.id,
    sourceLabel: point.label,
  );
}

CinematicActorPreviewPosition _positionFromMapEntity({
  required String actorId,
  required CinematicActorBinding binding,
  required MapEntity? entity,
  required MapData? mapData,
  required List<CinematicActorDisplayPreviewDiagnostic> diagnostics,
}) {
  if (binding.kind != CinematicActorBindingKind.mapEntity ||
      binding.mapEntityId == null ||
      entity == null ||
      mapData == null) {
    diagnostics.add(
      CinematicActorDisplayPreviewDiagnostic(
        code: CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayMissingMapEntity,
        severity: CinematicActorDisplayPreviewDiagnosticSeverity.error,
        message: 'Le binding mapEntity ne pointe vers aucune entite valide.',
        actorId: actorId,
        sourceId: binding.mapEntityId,
      ),
    );
    return const CinematicActorPreviewPosition(
      status: CinematicActorPreviewPositionStatus.missingSource,
      sourceKind: CinematicActorPreviewPositionSourceKind.mapEntity,
    );
  }
  return _positionForEntity(
    actorId: actorId,
    entity: entity,
    mapData: mapData,
    diagnostics: diagnostics,
  );
}

CinematicActorPreviewPosition _positionFromMovementTarget({
  required String actorId,
  required String? targetId,
  required Set<String> movementTargetIds,
  required Map<String, CinematicMovementTargetBinding> movementTargetBindings,
  required MapData? mapData,
  required List<CinematicActorDisplayPreviewDiagnostic> diagnostics,
}) {
  final normalizedTargetId = targetId?.trim();
  if (normalizedTargetId == null ||
      normalizedTargetId.isEmpty ||
      !movementTargetIds.contains(normalizedTargetId)) {
    diagnostics.add(
      CinematicActorDisplayPreviewDiagnostic(
        code: CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayMissingMovementTarget,
        severity: CinematicActorDisplayPreviewDiagnosticSeverity.error,
        message: 'La cible de placement initial est inconnue.',
        actorId: actorId,
        sourceId: normalizedTargetId,
      ),
    );
    return const CinematicActorPreviewPosition(
      status: CinematicActorPreviewPositionStatus.missingSource,
      sourceKind: CinematicActorPreviewPositionSourceKind.movementTarget,
    );
  }
  final binding = movementTargetBindings[normalizedTargetId];
  if (binding == null) {
    diagnostics.add(
      CinematicActorDisplayPreviewDiagnostic(
        code: CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayMissingMovementTarget,
        severity: CinematicActorDisplayPreviewDiagnosticSeverity.error,
        message: 'La cible de placement initial n a pas de binding.',
        actorId: actorId,
        sourceId: normalizedTargetId,
      ),
    );
    return const CinematicActorPreviewPosition(
      status: CinematicActorPreviewPositionStatus.missingSource,
      sourceKind: CinematicActorPreviewPositionSourceKind.movementTarget,
    );
  }
  if (binding.kind == CinematicMovementTargetBindingKind.abstractPoint) {
    diagnostics.add(
      CinematicActorDisplayPreviewDiagnostic(
        code: CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayAbstractTargetOnly,
        severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
        message: 'La cible de placement est abstraite et sans coordonnees.',
        actorId: actorId,
        sourceId: normalizedTargetId,
      ),
    );
    return CinematicActorPreviewPosition(
      status: CinematicActorPreviewPositionStatus.abstractOnly,
      sourceKind: CinematicActorPreviewPositionSourceKind.movementTarget,
      sourceId: normalizedTargetId,
    );
  }
  final sourceId = binding.sourceId?.trim();
  if (sourceId == null || sourceId.isEmpty || mapData == null) {
    diagnostics.add(
      CinematicActorDisplayPreviewDiagnostic(
        code: CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayMissingMovementTarget,
        severity: CinematicActorDisplayPreviewDiagnosticSeverity.error,
        message: 'La cible de placement n a pas de source de map valide.',
        actorId: actorId,
        sourceId: normalizedTargetId,
      ),
    );
    return CinematicActorPreviewPosition(
      status: CinematicActorPreviewPositionStatus.missingSource,
      sourceKind: CinematicActorPreviewPositionSourceKind.movementTarget,
      sourceId: normalizedTargetId,
    );
  }
  return switch (binding.kind) {
    CinematicMovementTargetBindingKind.abstractPoint =>
      CinematicActorPreviewPosition(
        status: CinematicActorPreviewPositionStatus.abstractOnly,
        sourceKind: CinematicActorPreviewPositionSourceKind.movementTarget,
        sourceId: normalizedTargetId,
      ),
    CinematicMovementTargetBindingKind.mapEntity => _positionForEntity(
        actorId: actorId,
        entity: _entityById(mapData, sourceId),
        mapData: mapData,
        diagnostics: diagnostics,
        targetId: normalizedTargetId,
      ),
    CinematicMovementTargetBindingKind.mapEvent => _positionForEvent(
        actorId: actorId,
        event: _eventById(mapData, sourceId),
        mapData: mapData,
        diagnostics: diagnostics,
        targetId: normalizedTargetId,
      ),
  };
}

CinematicActorPreviewPosition _positionForEntity({
  required String actorId,
  required MapEntity? entity,
  required MapData mapData,
  required List<CinematicActorDisplayPreviewDiagnostic> diagnostics,
  String? targetId,
}) {
  if (entity == null) {
    diagnostics.add(
      CinematicActorDisplayPreviewDiagnostic(
        code: CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayMissingMapEntity,
        severity: CinematicActorDisplayPreviewDiagnosticSeverity.error,
        message: 'Entite source introuvable pour l acteur.',
        actorId: actorId,
        sourceId: targetId,
      ),
    );
    return CinematicActorPreviewPosition(
      status: CinematicActorPreviewPositionStatus.missingSource,
      sourceKind: CinematicActorPreviewPositionSourceKind.mapEntity,
      sourceId: targetId,
    );
  }
  final status = _entityInBounds(entity, mapData)
      ? CinematicActorPreviewPositionStatus.resolved
      : CinematicActorPreviewPositionStatus.outOfMapBounds;
  if (status == CinematicActorPreviewPositionStatus.outOfMapBounds) {
    diagnostics.add(
      CinematicActorDisplayPreviewDiagnostic(
        code: CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayOutOfMapBounds,
        severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
        message: 'Position acteur hors limites de map.',
        actorId: actorId,
        sourceId: entity.id,
      ),
    );
  }
  return CinematicActorPreviewPosition(
    status: status,
    sourceKind: CinematicActorPreviewPositionSourceKind.mapEntity,
    x: entity.pos.x,
    y: entity.pos.y,
    sourceId: entity.id.trim(),
    sourceLabel: _entityLabel(entity),
  );
}

CinematicActorPreviewPosition _positionForEvent({
  required String actorId,
  required MapEventDefinition? event,
  required MapData mapData,
  required List<CinematicActorDisplayPreviewDiagnostic> diagnostics,
  String? targetId,
}) {
  if (event == null) {
    diagnostics.add(
      CinematicActorDisplayPreviewDiagnostic(
        code: CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayMissingMovementTarget,
        severity: CinematicActorDisplayPreviewDiagnosticSeverity.error,
        message: 'Event source introuvable pour la cible de placement.',
        actorId: actorId,
        sourceId: targetId,
      ),
    );
    return CinematicActorPreviewPosition(
      status: CinematicActorPreviewPositionStatus.missingSource,
      sourceKind: CinematicActorPreviewPositionSourceKind.mapEvent,
      sourceId: targetId,
    );
  }
  final x = event.position.x;
  final y = event.position.y;
  final status = _pointInBounds(x: x, y: y, mapData: mapData)
      ? CinematicActorPreviewPositionStatus.resolved
      : CinematicActorPreviewPositionStatus.outOfMapBounds;
  if (status == CinematicActorPreviewPositionStatus.outOfMapBounds) {
    diagnostics.add(
      CinematicActorDisplayPreviewDiagnostic(
        code: CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayOutOfMapBounds,
        severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
        message: 'Position event hors limites de map.',
        actorId: actorId,
        sourceId: event.id,
      ),
    );
  }
  return CinematicActorPreviewPosition(
    status: status,
    sourceKind: CinematicActorPreviewPositionSourceKind.mapEvent,
    x: x,
    y: y,
    sourceId: event.id.trim(),
    sourceLabel: _labelOrId(event.title, event.id),
  );
}

_DirectionResolution _resolveDirection({
  required CinematicAsset cinematic,
  required String actorId,
  required MapEntity? bindingEntity,
  required List<CinematicActorDisplayPreviewDiagnostic> diagnostics,
}) {
  for (final step in cinematic.timeline.steps) {
    if (step.kind != CinematicTimelineStepKind.actorFace ||
        step.actorId?.trim() != actorId) {
      continue;
    }
    final direction = _directionFromActorFaceMetadata(step.metadata);
    if (direction != null) {
      return _DirectionResolution(
        direction: direction,
        source: CinematicActorPreviewDirectionSource.actorFace,
      );
    }
  }

  final facing = bindingEntity?.npc?.facing;
  if (facing != null) {
    return _DirectionResolution(
      direction: _directionFromEntityFacing(facing),
      source: CinematicActorPreviewDirectionSource.mapEntityFacing,
    );
  }

  diagnostics.add(
    CinematicActorDisplayPreviewDiagnostic(
      code: CinematicActorDisplayPreviewDiagnosticCode
          .actorDisplayDirectionFallback,
      severity: CinematicActorDisplayPreviewDiagnosticSeverity.info,
      message: 'Direction statique absente, fallback south.',
      actorId: actorId,
    ),
  );
  return const _DirectionResolution(
    direction: CinematicActorPreviewDirection.south,
    source: CinematicActorPreviewDirectionSource.fallback,
  );
}

CinematicActorPreviewAppearance _resolveAppearance({
  required String actorId,
  required CinematicActorBinding? binding,
  required MapEntity? bindingEntity,
  required CinematicActorAppearanceBinding? appearanceBinding,
  required ProjectManifest project,
  required CinematicActorPreviewDirection direction,
  required List<CinematicActorDisplayPreviewDiagnostic> diagnostics,
}) {
  if (binding == null) {
    return const CinematicActorPreviewAppearance(
      status: CinematicActorPreviewAppearanceStatus.unsupported,
    );
  }
  switch (binding.kind) {
    case CinematicActorBindingKind.unbound:
      return const CinematicActorPreviewAppearance(
        status: CinematicActorPreviewAppearanceStatus.notRequired,
      );
    case CinematicActorBindingKind.player:
      final characterId = project.settings.defaultPlayerCharacterId?.trim();
      if (characterId == null || characterId.isEmpty) {
        diagnostics.add(
          CinematicActorDisplayPreviewDiagnostic(
            code: CinematicActorDisplayPreviewDiagnosticCode
                .actorDisplayMissingAppearance,
            severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
            message: 'Aucun character par defaut pour le joueur.',
            actorId: actorId,
          ),
        );
        return const CinematicActorPreviewAppearance(
          status: CinematicActorPreviewAppearanceStatus.placeholderOnly,
          sourceLabel: 'Joueur',
        );
      }
      return _appearanceFromCharacterId(
        actorId: actorId,
        characterId: characterId,
        project: project,
        direction: direction,
        diagnostics: diagnostics,
        sourceLabel: 'Joueur',
      );
    case CinematicActorBindingKind.cinematicOnly:
      final characterId = appearanceBinding?.characterId.trim();
      if (characterId == null || characterId.isEmpty) {
        diagnostics.add(
          CinematicActorDisplayPreviewDiagnostic(
            code: CinematicActorDisplayPreviewDiagnosticCode
                .actorDisplayMissingAppearance,
            severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
            message: 'Aucun character lie a cet acteur cinematicOnly.',
            actorId: actorId,
          ),
        );
        return const CinematicActorPreviewAppearance(
          status: CinematicActorPreviewAppearanceStatus.placeholderOnly,
          sourceLabel: 'Cinematic only',
        );
      }
      return _appearanceFromCharacterId(
        actorId: actorId,
        characterId: characterId,
        project: project,
        direction: direction,
        diagnostics: diagnostics,
        sourceLabel: 'Character Library',
      );
    case CinematicActorBindingKind.mapEntity:
      if (bindingEntity == null) {
        return const CinematicActorPreviewAppearance(
          status: CinematicActorPreviewAppearanceStatus.unsupported,
          sourceLabel: 'Map entity',
        );
      }
      final directCharacterId = bindingEntity.npc?.characterId?.trim();
      if (directCharacterId != null && directCharacterId.isNotEmpty) {
        return _appearanceFromCharacterId(
          actorId: actorId,
          characterId: directCharacterId,
          project: project,
          direction: direction,
          diagnostics: diagnostics,
          sourceLabel: 'Map entity NPC',
        );
      }
      final trainerId = bindingEntity.npc?.trainerId?.trim();
      if (trainerId != null && trainerId.isNotEmpty) {
        final trainer = _trainerById(project, trainerId);
        final trainerCharacterId = trainer?.characterId?.trim();
        if (trainerCharacterId != null && trainerCharacterId.isNotEmpty) {
          return _appearanceFromCharacterId(
            actorId: actorId,
            characterId: trainerCharacterId,
            project: project,
            direction: direction,
            diagnostics: diagnostics,
            sourceLabel: 'Trainer',
          );
        }
      }
      if ((bindingEntity.npc?.visualElementId.trim() ?? '').isNotEmpty ||
          bindingEntity.resolvedProjectElementIdForEditor != null) {
        return CinematicActorPreviewAppearance(
          status: CinematicActorPreviewAppearanceStatus.placeholderOnly,
          sourceLabel: _entityLabel(bindingEntity),
        );
      }
      diagnostics.add(
        CinematicActorDisplayPreviewDiagnostic(
          code: CinematicActorDisplayPreviewDiagnosticCode
              .actorDisplayMissingAppearance,
          severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
          message: 'La mapEntity n expose aucun character exploitable.',
          actorId: actorId,
          sourceId: bindingEntity.id,
        ),
      );
      return CinematicActorPreviewAppearance(
        status: CinematicActorPreviewAppearanceStatus.placeholderOnly,
        sourceLabel: _entityLabel(bindingEntity),
      );
  }
}

CinematicActorPreviewAppearance _appearanceFromCharacterId({
  required String actorId,
  required String characterId,
  required ProjectManifest project,
  required CinematicActorPreviewDirection direction,
  required List<CinematicActorDisplayPreviewDiagnostic> diagnostics,
  required String sourceLabel,
}) {
  final character = _characterById(project, characterId);
  if (character == null) {
    diagnostics.add(
      CinematicActorDisplayPreviewDiagnostic(
        code: CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayUnknownCharacter,
        severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
        message: 'Character introuvable pour l acteur.',
        actorId: actorId,
        sourceId: characterId,
      ),
    );
    return CinematicActorPreviewAppearance(
      status: CinematicActorPreviewAppearanceStatus.missingCharacter,
      characterId: characterId,
      sourceLabel: sourceLabel,
    );
  }
  final tilesetId = character.tilesetId.trim();
  if (tilesetId.isEmpty || !_projectHasTileset(project, tilesetId)) {
    diagnostics.add(
      CinematicActorDisplayPreviewDiagnostic(
        code: CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayCharacterMissingTileset,
        severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
        message: 'Character sans tileset exploitable.',
        actorId: actorId,
        sourceId: characterId,
      ),
    );
    return CinematicActorPreviewAppearance(
      status: CinematicActorPreviewAppearanceStatus.missingTileset,
      characterId: character.id,
      characterLabel: character.name,
      sourceLabel: sourceLabel,
    );
  }
  if (!_hasIdleAnimation(character, direction)) {
    diagnostics.add(
      CinematicActorDisplayPreviewDiagnostic(
        code: CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayCharacterMissingIdleAnimation,
        severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
        message: 'Character sans animation idle exploitable.',
        actorId: actorId,
        sourceId: characterId,
      ),
    );
    return CinematicActorPreviewAppearance(
      status: CinematicActorPreviewAppearanceStatus.missingIdleAnimation,
      characterId: character.id,
      characterLabel: character.name,
      tilesetId: tilesetId,
      sourceLabel: sourceLabel,
    );
  }
  return CinematicActorPreviewAppearance(
    status: CinematicActorPreviewAppearanceStatus.spriteReady,
    characterId: character.id,
    characterLabel: character.name,
    tilesetId: tilesetId,
    sourceLabel: sourceLabel,
  );
}

CinematicActorPreviewRenderHint _renderHintFor({
  required CinematicActorDisplayBindingStatus bindingStatus,
  required CinematicActorPreviewPosition position,
  required CinematicActorPreviewAppearance appearance,
}) {
  if (bindingStatus == CinematicActorDisplayBindingStatus.unbound ||
      appearance.status == CinematicActorPreviewAppearanceStatus.notRequired) {
    return CinematicActorPreviewRenderHint.hidden;
  }
  if (bindingStatus == CinematicActorDisplayBindingStatus.missing) {
    return CinematicActorPreviewRenderHint.missing;
  }
  if (appearance.status == CinematicActorPreviewAppearanceStatus.spriteReady) {
    return position.isResolved
        ? CinematicActorPreviewRenderHint.sprite
        : CinematicActorPreviewRenderHint.missing;
  }
  if (appearance.status ==
      CinematicActorPreviewAppearanceStatus.placeholderOnly) {
    return position.isResolved
        ? CinematicActorPreviewRenderHint.placeholder
        : CinematicActorPreviewRenderHint.missing;
  }
  return CinematicActorPreviewRenderHint.missing;
}

bool _canUseMapData({
  required ProjectMapEntry? stageMap,
  required MapData? mapData,
}) {
  if (stageMap == null || mapData == null) {
    return false;
  }
  return stageMap.id.trim() == mapData.id.trim();
}

MapEntity? _entityById(MapData mapData, String entityId) {
  final normalizedId = entityId.trim();
  for (final entity in mapData.entities) {
    if (entity.id.trim() == normalizedId) {
      return entity;
    }
  }
  return null;
}

MapEventDefinition? _eventById(MapData mapData, String eventId) {
  final normalizedId = eventId.trim();
  for (final event in mapData.events) {
    if (event.id.trim() == normalizedId) {
      return event;
    }
  }
  return null;
}

ProjectCharacterEntry? _characterById(
  ProjectManifest project,
  String characterId,
) {
  final normalizedId = characterId.trim();
  for (final character in project.characters) {
    if (character.id.trim() == normalizedId) {
      return character;
    }
  }
  return null;
}

ProjectTrainerEntry? _trainerById(ProjectManifest project, String trainerId) {
  final normalizedId = trainerId.trim();
  for (final trainer in project.trainers) {
    if (trainer.id.trim() == normalizedId) {
      return trainer;
    }
  }
  return null;
}

bool _projectHasTileset(ProjectManifest project, String tilesetId) {
  final normalizedId = tilesetId.trim();
  for (final tileset in project.tilesets) {
    if (tileset.id.trim() == normalizedId) {
      return true;
    }
  }
  return false;
}

bool _hasIdleAnimation(
  ProjectCharacterEntry character,
  CinematicActorPreviewDirection direction,
) {
  final preferredFacing = _entityFacingFromPreviewDirection(direction);
  var hasAnyIdle = false;
  for (final animation in character.animations) {
    if (animation.state != CharacterAnimationState.idle ||
        animation.frames.isEmpty) {
      continue;
    }
    hasAnyIdle = true;
    if (preferredFacing == null || animation.direction == preferredFacing) {
      return true;
    }
  }
  return hasAnyIdle;
}

bool _entityInBounds(MapEntity entity, MapData mapData) {
  return entity.pos.x >= 0 &&
      entity.pos.y >= 0 &&
      entity.pos.x + entity.size.width <= mapData.size.width &&
      entity.pos.y + entity.size.height <= mapData.size.height;
}

bool _pointInBounds({
  required int x,
  required int y,
  required MapData mapData,
}) {
  return x >= 0 && y >= 0 && x < mapData.size.width && y < mapData.size.height;
}

CinematicActorPreviewDirection? _directionFromActorFaceMetadata(
  Map<String, String> metadata,
) {
  return switch (metadata['actor.direction']) {
    'up' => CinematicActorPreviewDirection.north,
    'down' => CinematicActorPreviewDirection.south,
    'left' => CinematicActorPreviewDirection.west,
    'right' => CinematicActorPreviewDirection.east,
    _ => null,
  };
}

CinematicActorPreviewDirection _directionFromEntityFacing(
  EntityFacing facing,
) {
  return switch (facing) {
    EntityFacing.north => CinematicActorPreviewDirection.north,
    EntityFacing.south => CinematicActorPreviewDirection.south,
    EntityFacing.east => CinematicActorPreviewDirection.east,
    EntityFacing.west => CinematicActorPreviewDirection.west,
  };
}

EntityFacing? _entityFacingFromPreviewDirection(
  CinematicActorPreviewDirection direction,
) {
  return switch (direction) {
    CinematicActorPreviewDirection.north => EntityFacing.north,
    CinematicActorPreviewDirection.south => EntityFacing.south,
    CinematicActorPreviewDirection.east => EntityFacing.east,
    CinematicActorPreviewDirection.west => EntityFacing.west,
    CinematicActorPreviewDirection.unknown => null,
  };
}

String _labelOrId(String? label, String id) {
  final trimmed = label?.trim();
  if (trimmed != null && trimmed.isNotEmpty) {
    return trimmed;
  }
  return id.trim();
}

String _entityLabel(MapEntity entity) {
  final headline = entity.inspectorHeadline.trim();
  return headline.isNotEmpty ? headline : entity.id.trim();
}

@immutable
final class _DirectionResolution {
  const _DirectionResolution({
    required this.direction,
    required this.source,
  });

  final CinematicActorPreviewDirection direction;
  final CinematicActorPreviewDirectionSource source;
}
