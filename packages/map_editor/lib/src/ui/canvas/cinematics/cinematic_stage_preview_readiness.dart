import 'package:map_core/map_core.dart';

enum CinematicStagePreviewReadinessKind {
  sandboxOnly,
  incomplete,
  blocked,
  ready,
}

enum CinematicStagePreviewReadinessItemKind {
  ok,
  incomplete,
  blocking,
  upcoming,
}

final class CinematicStagePreviewReadiness {
  const CinematicStagePreviewReadiness({
    required this.kind,
    required this.statusLabel,
    required this.libraryStatusLabel,
    required this.summary,
    required this.items,
    required this.diagnostics,
  });

  final CinematicStagePreviewReadinessKind kind;
  final String statusLabel;
  final String libraryStatusLabel;
  final String summary;
  final List<CinematicStagePreviewReadinessItem> items;
  final List<CinematicStagePreviewReadinessDiagnostic> diagnostics;
}

final class CinematicStagePreviewReadinessItem {
  const CinematicStagePreviewReadinessItem({
    required this.label,
    required this.kind,
    required this.statusLabel,
    required this.message,
  });

  final String label;
  final CinematicStagePreviewReadinessItemKind kind;
  final String statusLabel;
  final String message;

  String get displayLine => '$label — $statusLabel : $message';
}

final class CinematicStagePreviewReadinessDiagnostic {
  const CinematicStagePreviewReadinessDiagnostic({
    required this.code,
    required this.message,
    required this.severity,
  });

  final String code;
  final String message;
  final CinematicsLibraryDiagnosticSeverity severity;
}

CinematicStagePreviewReadiness buildCinematicStagePreviewReadiness({
  required CinematicAsset asset,
  required CinematicsLibraryEntry entry,
  required List<ProjectMapEntry> maps,
}) {
  final stageContext = asset.stageContext;
  final effectiveContext = stageContext ?? CinematicStageContext();
  final diagnostics = _stageDiagnostics(entry)
      .map(
        (diagnostic) => CinematicStagePreviewReadinessDiagnostic(
          code: diagnostic.code,
          message: _humanStageDiagnosticMessage(diagnostic, asset),
          severity: diagnostic.severity,
        ),
      )
      .toList(growable: false);
  final items = <CinematicStagePreviewReadinessItem>[
    _mapItem(asset, maps),
    _backdropItem(asset, effectiveContext, maps),
    _actorBindingsItem(asset, effectiveContext),
    _initialPlacementsItem(asset, effectiveContext),
    _movementTargetsItem(asset, effectiveContext),
    _mapAwareSourcesItem(asset, effectiveContext),
  ];

  final hasBlocking = diagnostics.any(
        (diagnostic) =>
            diagnostic.severity == CinematicsLibraryDiagnosticSeverity.error,
      ) ||
      items.any((item) =>
          item.kind == CinematicStagePreviewReadinessItemKind.blocking);
  final hasIncomplete = items.any(
    (item) => item.kind == CinematicStagePreviewReadinessItemKind.incomplete,
  );

  if (stageContext == null) {
    return CinematicStagePreviewReadiness(
      kind: CinematicStagePreviewReadinessKind.sandboxOnly,
      statusLabel: 'Sandbox uniquement',
      libraryStatusLabel: 'sandbox uniquement',
      summary:
          'Ajoute un contexte de scène pour préparer une future preview. La preview réelle arrivera plus tard.',
      items: items,
      diagnostics: diagnostics,
    );
  }
  if (hasBlocking) {
    return CinematicStagePreviewReadiness(
      kind: CinematicStagePreviewReadinessKind.blocked,
      statusLabel: 'À corriger avant preview',
      libraryStatusLabel: 'à corriger avant preview',
      summary:
          'Corrige les éléments bloquants avant une future preview. La preview réelle arrivera plus tard.',
      items: items,
      diagnostics: diagnostics,
    );
  }
  if (hasIncomplete || diagnostics.isNotEmpty) {
    return CinematicStagePreviewReadiness(
      kind: CinematicStagePreviewReadinessKind.incomplete,
      statusLabel: 'Contexte incomplet',
      libraryStatusLabel: 'contexte incomplet',
      summary:
          'Complète les éléments de préparation avant une future preview. La preview réelle arrivera plus tard.',
      items: items,
      diagnostics: diagnostics,
    );
  }
  return CinematicStagePreviewReadiness(
    kind: CinematicStagePreviewReadinessKind.ready,
    statusLabel: 'Prêt pour future preview',
    libraryStatusLabel: 'prêt pour future preview',
    summary:
        'Le contexte est prêt pour une future preview. La preview réelle arrivera plus tard.',
    items: items,
    diagnostics: diagnostics,
  );
}

CinematicStagePreviewReadinessItem _mapItem(
  CinematicAsset asset,
  List<ProjectMapEntry> maps,
) {
  final mapId = asset.mapId;
  if (mapId == null || mapId.trim().isEmpty) {
    return _item(
      'Map de scène',
      CinematicStagePreviewReadinessItemKind.incomplete,
      'Choisis une map de scène',
    );
  }
  final map = _stageMapForId(maps, mapId);
  if (map == null) {
    return _item(
      'Map de scène',
      CinematicStagePreviewReadinessItemKind.blocking,
      'La map de scène n’existe plus dans le projet',
    );
  }
  return _item(
      'Map de scène', CinematicStagePreviewReadinessItemKind.ok, map.name);
}

CinematicStagePreviewReadinessItem _backdropItem(
  CinematicAsset asset,
  CinematicStageContext context,
  List<ProjectMapEntry> maps,
) {
  return switch (context.backdropMode) {
    CinematicStageBackdropMode.none => _item(
        'Décor',
        CinematicStagePreviewReadinessItemKind.ok,
        'aucun décor',
      ),
    CinematicStageBackdropMode.projectMap =>
      asset.mapId == null || _stageMapForId(maps, asset.mapId) == null
          ? _item(
              'Décor',
              CinematicStagePreviewReadinessItemKind.blocking,
              'choisis une map avant d’utiliser un décor de map',
            )
          : _item(
              'Décor',
              CinematicStagePreviewReadinessItemKind.ok,
              'décor depuis la map',
            ),
  };
}

CinematicStagePreviewReadinessItem _actorBindingsItem(
  CinematicAsset asset,
  CinematicStageContext context,
) {
  if (asset.requiredActors.isEmpty) {
    return _item(
      'Acteurs liés',
      CinematicStagePreviewReadinessItemKind.ok,
      'aucun acteur requis',
    );
  }
  final duplicatePlayer = context.actorBindings
          .where((binding) => binding.kind == CinematicActorBindingKind.player)
          .length >
      1;
  if (duplicatePlayer) {
    return _item(
      'Acteurs liés',
      CinematicStagePreviewReadinessItemKind.blocking,
      'un seul acteur peut représenter le joueur',
    );
  }
  for (final actor in asset.requiredActors) {
    final binding = _actorBindingFor(context, actor.actorId);
    if (binding == null || binding.kind == CinematicActorBindingKind.unbound) {
      return _item(
        'Acteurs liés',
        CinematicStagePreviewReadinessItemKind.incomplete,
        '${_actorDisplayLabel(actor)} est non lié',
      );
    }
    if (binding.kind == CinematicActorBindingKind.mapEntity &&
        binding.mapEntityId == null) {
      return _item(
        'Acteurs liés',
        CinematicStagePreviewReadinessItemKind.upcoming,
        'Sélection d’entités prévue dans un lot suivant.',
      );
    }
  }
  return _item(
    'Acteurs liés',
    CinematicStagePreviewReadinessItemKind.ok,
    'acteurs prêts pour une future preview',
  );
}

CinematicStagePreviewReadinessItem _initialPlacementsItem(
  CinematicAsset asset,
  CinematicStageContext context,
) {
  if (asset.requiredActors.isEmpty) {
    return _item(
      'Positions initiales',
      CinematicStagePreviewReadinessItemKind.ok,
      'aucun acteur à placer',
    );
  }
  for (final actor in asset.requiredActors) {
    final placement = _initialPlacementFor(context, actor.actorId);
    if (placement == null ||
        placement.kind == CinematicActorInitialPlacementKind.unset) {
      return _item(
        'Positions initiales',
        CinematicStagePreviewReadinessItemKind.incomplete,
        '${_actorDisplayLabel(actor)} n’a pas d’entrée de scène',
      );
    }
    if (placement.kind ==
            CinematicActorInitialPlacementKind.fromMovementTarget &&
        !_hasMovementTarget(asset, placement.targetId)) {
      return _item(
        'Positions initiales',
        CinematicStagePreviewReadinessItemKind.blocking,
        'une entrée de scène pointe vers une cible absente',
      );
    }
    if (placement.kind == CinematicActorInitialPlacementKind.fromMapEntity) {
      final binding = _actorBindingFor(context, actor.actorId);
      if (binding?.kind != CinematicActorBindingKind.mapEntity ||
          binding?.mapEntityId == null) {
        return _item(
          'Positions initiales',
          CinematicStagePreviewReadinessItemKind.incomplete,
          '${_actorDisplayLabel(actor)} doit être lié à une entité de map',
        );
      }
    }
  }
  return _item(
    'Positions initiales',
    CinematicStagePreviewReadinessItemKind.ok,
    'entrées de scène définies',
  );
}

CinematicStagePreviewReadinessItem _movementTargetsItem(
  CinematicAsset asset,
  CinematicStageContext context,
) {
  if (asset.movementTargets.isEmpty) {
    return _item(
      'Cibles de mouvement',
      CinematicStagePreviewReadinessItemKind.ok,
      'aucune cible de mouvement',
    );
  }
  for (final target in asset.movementTargets) {
    final binding = _movementTargetBindingFor(context, target.targetId);
    if (binding == null) {
      return _item(
        'Cibles de mouvement',
        CinematicStagePreviewReadinessItemKind.incomplete,
        '${target.label} n’a pas encore de source',
      );
    }
    if (binding.kind == CinematicMovementTargetBindingKind.abstractPoint) {
      continue;
    }
    if (binding.sourceId == null) {
      return _item(
        'Cibles de mouvement',
        CinematicStagePreviewReadinessItemKind.upcoming,
        '${target.label} attend une source map-aware',
      );
    }
  }
  return _item(
    'Cibles de mouvement',
    CinematicStagePreviewReadinessItemKind.ok,
    '${asset.movementTargets.first.label} reste un point abstrait',
  );
}

CinematicStagePreviewReadinessItem _mapAwareSourcesItem(
  CinematicAsset asset,
  CinematicStageContext context,
) {
  final hasMapAwareActor = context.actorBindings.any(
    (binding) => binding.kind == CinematicActorBindingKind.mapEntity,
  );
  final hasMapAwareTarget = context.movementTargetBindings.any(
    (binding) =>
        binding.kind == CinematicMovementTargetBindingKind.mapEntity ||
        binding.kind == CinematicMovementTargetBindingKind.mapEvent,
  );
  if (!hasMapAwareActor && !hasMapAwareTarget) {
    return _item(
      'Sources map-aware',
      CinematicStagePreviewReadinessItemKind.upcoming,
      'Sélection d’entités prévue dans un lot suivant. '
          'Sélection d’events prévue dans un lot suivant.',
    );
  }
  final hasMissingSource = context.actorBindings.any(
        (binding) =>
            binding.kind == CinematicActorBindingKind.mapEntity &&
            binding.mapEntityId == null,
      ) ||
      context.movementTargetBindings.any(
        (binding) =>
            (binding.kind == CinematicMovementTargetBindingKind.mapEntity ||
                binding.kind == CinematicMovementTargetBindingKind.mapEvent) &&
            binding.sourceId == null,
      );
  if (hasMissingSource) {
    return _item(
      'Sources map-aware',
      CinematicStagePreviewReadinessItemKind.upcoming,
      'Le Builder ne reçoit pas encore les entités/events de la map.',
    );
  }
  return _item(
    'Sources map-aware',
    CinematicStagePreviewReadinessItemKind.ok,
    'sources map-aware renseignées',
  );
}

CinematicStagePreviewReadinessItem _item(
  String label,
  CinematicStagePreviewReadinessItemKind kind,
  String message,
) {
  return CinematicStagePreviewReadinessItem(
    label: label,
    kind: kind,
    statusLabel: _itemStatusLabel(kind),
    message: message,
  );
}

String _itemStatusLabel(CinematicStagePreviewReadinessItemKind kind) {
  return switch (kind) {
    CinematicStagePreviewReadinessItemKind.ok => 'OK',
    CinematicStagePreviewReadinessItemKind.incomplete => 'À compléter',
    CinematicStagePreviewReadinessItemKind.blocking => 'Bloquant',
    CinematicStagePreviewReadinessItemKind.upcoming => 'À venir',
  };
}

ProjectMapEntry? _stageMapForId(List<ProjectMapEntry> maps, String? mapId) {
  if (mapId == null) {
    return null;
  }
  for (final map in maps) {
    if (map.id == mapId) {
      return map;
    }
  }
  return null;
}

CinematicActorBinding? _actorBindingFor(
  CinematicStageContext context,
  String actorId,
) {
  for (final binding in context.actorBindings) {
    if (binding.actorId == actorId) {
      return binding;
    }
  }
  return null;
}

CinematicActorInitialPlacement? _initialPlacementFor(
  CinematicStageContext context,
  String actorId,
) {
  for (final placement in context.initialPlacements) {
    if (placement.actorId == actorId) {
      return placement;
    }
  }
  return null;
}

CinematicMovementTargetBinding? _movementTargetBindingFor(
  CinematicStageContext context,
  String targetId,
) {
  for (final binding in context.movementTargetBindings) {
    if (binding.targetId == targetId) {
      return binding;
    }
  }
  return null;
}

bool _hasMovementTarget(CinematicAsset asset, String? targetId) {
  if (targetId == null) {
    return false;
  }
  return asset.movementTargets.any((target) => target.targetId == targetId);
}

List<CinematicsLibraryDiagnosticView> _stageDiagnostics(
  CinematicsLibraryEntry entry,
) {
  return entry.diagnostics
      .where((diagnostic) => _stageDiagnosticCodes.contains(diagnostic.code))
      .toList(growable: false);
}

String _humanStageDiagnosticMessage(
  CinematicsLibraryDiagnosticView diagnostic,
  CinematicAsset asset,
) {
  final actorLabel = _actorLabelFor(asset, diagnostic.sourceId);
  final targetLabel = _targetLabelFor(asset, diagnostic.sourceId);
  return switch (diagnostic.code) {
    'stageMapUnknown' => 'La map de scène n’existe plus dans le projet.',
    'stageBackdropRequiresMap' =>
      'Choisis une map avant d’utiliser un décor de map.',
    'actorBindingUnknownActor' =>
      'Un binding vise un acteur qui n’existe plus.',
    'actorBindingMissing' =>
      'Lie l’acteur ${actorLabel ?? 'requis'} avant une future preview.',
    'actorBindingDuplicatePlayer' =>
      'Un seul acteur peut représenter le joueur.',
    'actorBindingRequiresStageMap' =>
      'Choisis une map avant de lier un acteur à une entité.',
    'actorBindingMapEntityMissingSource' =>
      'Sélection d’entités prévue dans un lot suivant.',
    'actorInitialPlacementUnknownActor' =>
      'Une entrée de scène vise un acteur absent.',
    'actorInitialPlacementMissing' =>
      'Définis une entrée de scène pour ${actorLabel ?? 'cet acteur'}.',
    'actorInitialPlacementTargetUnknown' =>
      'Cette entrée de scène pointe vers une cible absente.',
    'actorInitialPlacementRequiresBinding' =>
      'Lie l’acteur avant d’utiliser son entité de map comme entrée.',
    'movementTargetBindingUnknownTarget' =>
      'Cette cible de mouvement n’existe plus.',
    'movementTargetBindingRequiresStageMap' =>
      'Choisis une map avant de lier une cible à une entité ou un event.',
    'movementTargetBindingMissingSource' => targetLabel == null
        ? 'Sélection d’events prévue dans un lot suivant.'
        : '$targetLabel attend une sélection d’entité ou d’event.',
    _ => diagnostic.message,
  };
}

String? _actorLabelFor(CinematicAsset asset, String? actorId) {
  if (actorId == null) {
    return null;
  }
  for (final actor in asset.requiredActors) {
    if (actor.actorId == actorId) {
      return _actorDisplayLabel(actor);
    }
  }
  return actorId;
}

String _actorDisplayLabel(CinematicActorRef actor) {
  final label = actor.label?.trim();
  return label == null || label.isEmpty ? actor.actorId : label;
}

String? _targetLabelFor(CinematicAsset asset, String? targetId) {
  if (targetId == null) {
    return null;
  }
  for (final target in asset.movementTargets) {
    if (target.targetId == targetId) {
      return target.label;
    }
  }
  return targetId;
}

const _stageDiagnosticCodes = <String>{
  'stageMapUnknown',
  'stageBackdropRequiresMap',
  'actorBindingUnknownActor',
  'actorBindingMissing',
  'actorBindingDuplicatePlayer',
  'actorBindingRequiresStageMap',
  'actorBindingMapEntityMissingSource',
  'actorInitialPlacementUnknownActor',
  'actorInitialPlacementMissing',
  'actorInitialPlacementTargetUnknown',
  'actorInitialPlacementRequiresBinding',
  'movementTargetBindingUnknownTarget',
  'movementTargetBindingRequiresStageMap',
  'movementTargetBindingMissingSource',
};
