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
  List<ProjectCharacterEntry> characters = const <ProjectCharacterEntry>[],
  CinematicStageMapSourceCatalog? stageMapSourceCatalog,
  int? mapWidth,
  int? mapHeight,
}) {
  final stageContext = asset.stageContext;
  final effectiveContext = stageContext ?? CinematicStageContext();
  final diagnostics = _stageDiagnostics(entry, asset, mapWidth, mapHeight)
      .map(
        (diagnostic) => CinematicStagePreviewReadinessDiagnostic(
          code: diagnostic.code,
          message: _humanStageDiagnosticMessage(diagnostic, asset),
          severity: diagnostic.severity,
        ),
      )
      .toList(growable: false);
  final actorAppearances = _actorAppearancesItem(
    asset,
    effectiveContext,
    characters,
  );
  final items = <CinematicStagePreviewReadinessItem>[
    _mapItem(asset, maps),
    _backdropItem(asset, effectiveContext, maps),
    _actorBindingsItem(asset, effectiveContext, stageMapSourceCatalog),
    actorAppearances,
    _initialPlacementsItem(asset, effectiveContext, stageMapSourceCatalog),
    _movementTargetsItem(asset, effectiveContext, stageMapSourceCatalog),
    _mapAwareSourcesItem(asset, effectiveContext, stageMapSourceCatalog),
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
      statusLabel: 'Aperçu uniquement',
      libraryStatusLabel: 'aperçu uniquement',
      summary:
          'Ajoute un contexte de scène pour préparer une future preview. La preview réelle arrivera plus tard.',
      items: items,
      diagnostics: diagnostics,
    );
  }
  if (hasBlocking) {
    return CinematicStagePreviewReadiness(
      kind: CinematicStagePreviewReadinessKind.blocked,
      statusLabel: 'À corriger',
      libraryStatusLabel: actorAppearances.kind ==
              CinematicStagePreviewReadinessItemKind.blocking
          ? 'apparence à corriger'
          : 'à corriger',
      summary:
          'Corrige les éléments bloquants avant une future preview. La preview réelle arrivera plus tard.',
      items: items,
      diagnostics: diagnostics,
    );
  }
  if (hasIncomplete || diagnostics.isNotEmpty) {
    return CinematicStagePreviewReadiness(
      kind: CinematicStagePreviewReadinessKind.incomplete,
      statusLabel: 'Incomplet',
      libraryStatusLabel: actorAppearances.kind ==
              CinematicStagePreviewReadinessItemKind.incomplete
          ? 'apparence à compléter'
          : 'incomplet',
      summary:
          'Complète les éléments de préparation avant une future preview. La preview réelle arrivera plus tard.',
      items: items,
      diagnostics: diagnostics,
    );
  }
  return CinematicStagePreviewReadiness(
    kind: CinematicStagePreviewReadinessKind.ready,
    statusLabel: 'Prêt',
    libraryStatusLabel: 'prêt',
    summary:
        'Le contexte est prêt pour une future preview. La preview réelle arrivera plus tard.',
    items: items,
    diagnostics: diagnostics,
  );
}

CinematicStagePreviewReadinessItem _actorAppearancesItem(
  CinematicAsset asset,
  CinematicStageContext context,
  List<ProjectCharacterEntry> characters,
) {
  for (final appearance in context.actorAppearanceBindings) {
    final actor = _requiredActorFor(asset, appearance.actorId);
    if (actor == null) {
      return _item(
        'Apparences acteurs',
        CinematicStagePreviewReadinessItemKind.blocking,
        'Une apparence référence un acteur supprimé.',
      );
    }
    final binding = _actorBindingFor(context, appearance.actorId);
    if (binding?.kind != CinematicActorBindingKind.cinematicOnly) {
      return _item(
        'Apparences acteurs',
        CinematicStagePreviewReadinessItemKind.blocking,
        '${_actorDisplayLabel(actor)} n’est plus en Cinématique uniquement.',
      );
    }
  }
  if (asset.requiredActors.isEmpty) {
    return _item(
      'Apparences acteurs',
      CinematicStagePreviewReadinessItemKind.ok,
      'aucun acteur requis',
    );
  }
  final cinematicOnlyActors = asset.requiredActors.where((actor) {
    final binding = _actorBindingFor(context, actor.actorId);
    return binding?.kind == CinematicActorBindingKind.cinematicOnly;
  }).toList(growable: false);
  if (cinematicOnlyActors.isEmpty) {
    return _item(
      'Apparences acteurs',
      CinematicStagePreviewReadinessItemKind.ok,
      'aucune apparence dédiée requise',
    );
  }
  if (characters.isEmpty) {
    return _item(
      'Apparences acteurs',
      CinematicStagePreviewReadinessItemKind.incomplete,
      'La Character Library est vide.',
    );
  }
  for (final actor in cinematicOnlyActors) {
    final appearance = _actorAppearanceBindingFor(context, actor.actorId);
    if (appearance == null) {
      return _item(
        'Apparences acteurs',
        CinematicStagePreviewReadinessItemKind.incomplete,
        '${_actorDisplayLabel(actor)} n’a pas encore de personnage.',
      );
    }
    final character = _characterById(characters, appearance.characterId);
    if (character == null) {
      return _item(
        'Apparences acteurs',
        CinematicStagePreviewReadinessItemKind.blocking,
        '${_actorDisplayLabel(actor)} pointe vers un personnage absent.',
      );
    }
    if (character.tilesetId.trim().isEmpty) {
      return _item(
        'Apparences acteurs',
        CinematicStagePreviewReadinessItemKind.incomplete,
        '${character.name} utilise un personnage sans sprite preview.',
      );
    }
    if (character.frameWidth <= 0 || character.frameHeight <= 0) {
      return _item(
        'Apparences acteurs',
        CinematicStagePreviewReadinessItemKind.incomplete,
        '${character.name} a des dimensions de preview à compléter.',
      );
    }
    if (!_hasIdleAnimation(character)) {
      return _item(
        'Apparences acteurs',
        CinematicStagePreviewReadinessItemKind.incomplete,
        '${character.name} n’a pas encore d’animation idle pour la future preview.',
      );
    }
  }
  return _item(
    'Apparences acteurs',
    CinematicStagePreviewReadinessItemKind.ok,
    'personnages de cinématique prêts',
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
      'Choisissez une map de scène',
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
              'choisissez une map avant d’utiliser un décor de map',
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
  CinematicStageMapSourceCatalog? stageMapSourceCatalog,
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
        '${_actorDisplayLabel(actor)} n’est pas lié',
      );
    }
    if (binding.kind == CinematicActorBindingKind.mapEntity &&
        binding.mapEntityId == null) {
      return _item(
        'Acteurs liés',
        CinematicStagePreviewReadinessItemKind.incomplete,
        '${_actorDisplayLabel(actor)} doit être lié à un personnage de la map',
      );
    }
    if (binding.kind == CinematicActorBindingKind.mapEntity &&
        !_hasBindableMapEntitySource(
            stageMapSourceCatalog, binding.mapEntityId)) {
      return _item(
        'Acteurs liés',
        CinematicStagePreviewReadinessItemKind.blocking,
        '${_actorDisplayLabel(actor)} pointe vers un personnage ou objet absent de la map',
      );
    }
  }
  return _item(
    'Acteurs liés',
    CinematicStagePreviewReadinessItemKind.ok,
    'acteurs prêts',
  );
}

CinematicStagePreviewReadinessItem _initialPlacementsItem(
  CinematicAsset asset,
  CinematicStageContext context,
  CinematicStageMapSourceCatalog? stageMapSourceCatalog,
) {
  if (asset.requiredActors.isEmpty) {
    return _item(
      'Départs de scène',
      CinematicStagePreviewReadinessItemKind.ok,
      'aucun acteur à placer',
    );
  }
  for (final actor in asset.requiredActors) {
    final placement = _initialPlacementFor(context, actor.actorId);
    if (placement == null ||
        placement.kind == CinematicActorInitialPlacementKind.unset) {
      return _item(
        'Départs de scène',
        CinematicStagePreviewReadinessItemKind.incomplete,
        '${_actorDisplayLabel(actor)} n’a pas de position de départ de scène',
      );
    }
    if (placement.kind ==
            CinematicActorInitialPlacementKind.fromMovementTarget &&
         !_hasMovementTarget(asset, placement.targetId)) {
      return _item(
        'Départs de scène',
        CinematicStagePreviewReadinessItemKind.blocking,
        'un départ de scène pointe vers une destination absente',
      );
    }
    if (placement.kind == CinematicActorInitialPlacementKind.stagePoint) {
      final pointId = placement.stagePointId;
      if (pointId == null || pointId.trim().isEmpty) {
        return _item(
          'Départs de scène',
          CinematicStagePreviewReadinessItemKind.incomplete,
          '${_actorDisplayLabel(actor)} attend la sélection d’un repère de scène',
        );
      }
      final hasPoint = context.stagePoints.any((p) => p.id == pointId);
      if (!hasPoint) {
        return _item(
          'Départs de scène',
          CinematicStagePreviewReadinessItemKind.blocking,
          '${_actorDisplayLabel(actor)} pointe vers un repère de scène inexistant',
        );
      }
    }
    if (placement.kind == CinematicActorInitialPlacementKind.fromMapEntity) {
      final binding = _actorBindingFor(context, actor.actorId);
      if (binding?.kind != CinematicActorBindingKind.mapEntity ||
          binding?.mapEntityId == null) {
        return _item(
          'Départs de scène',
          CinematicStagePreviewReadinessItemKind.incomplete,
          '${_actorDisplayLabel(actor)} doit être lié à un personnage ou objet de la map',
        );
      }
      if (!_hasMapEntitySource(stageMapSourceCatalog, binding!.mapEntityId)) {
        return _item(
          'Départs de scène',
          CinematicStagePreviewReadinessItemKind.blocking,
          '${_actorDisplayLabel(actor)} pointe vers un personnage ou objet absent de la map',
        );
      }
    }
  }
  return _item(
    'Départs de scène',
    CinematicStagePreviewReadinessItemKind.ok,
    'départs de scène définis',
  );
}

CinematicStagePreviewReadinessItem _movementTargetsItem(
  CinematicAsset asset,
  CinematicStageContext context,
  CinematicStageMapSourceCatalog? stageMapSourceCatalog,
) {
  if (asset.movementTargets.isEmpty) {
    return _item(
      'Destinations',
      CinematicStagePreviewReadinessItemKind.ok,
      'aucune destination',
    );
  }
  for (final target in asset.movementTargets) {
    final binding = _movementTargetBindingFor(context, target.targetId);
    if (binding == null) {
      return _item(
        'Destinations',
        CinematicStagePreviewReadinessItemKind.incomplete,
        '${target.label} n’a pas encore de source définie',
      );
    }
    if (binding.kind == CinematicMovementTargetBindingKind.abstractPoint) {
      continue;
    }
    if (binding.sourceId == null) {
      return _item(
        'Destinations',
        CinematicStagePreviewReadinessItemKind.incomplete,
        '${target.label} attend une liaison avec la map',
      );
    }
    final hasSource = switch (binding.kind) {
      CinematicMovementTargetBindingKind.abstractPoint => true,
      CinematicMovementTargetBindingKind.mapEntity =>
        _hasMapEntitySource(stageMapSourceCatalog, binding.sourceId),
      CinematicMovementTargetBindingKind.mapEvent =>
        _hasMapEventSource(stageMapSourceCatalog, binding.sourceId),
      CinematicMovementTargetBindingKind.stagePoint =>
        context.stagePoints
                .any((p) => p.id == binding.sourceId),
    };
    if (!hasSource) {
      return _item(
        'Destinations',
        CinematicStagePreviewReadinessItemKind.blocking,
        '${target.label} pointe vers un élément absent de la map',
      );
    }
  }
  return _item(
    'Destinations',
    CinematicStagePreviewReadinessItemKind.ok,
    '${asset.movementTargets.first.label} reste une position libre',
  );
}

CinematicStagePreviewReadinessItem _mapAwareSourcesItem(
  CinematicAsset asset,
  CinematicStageContext context,
  CinematicStageMapSourceCatalog? stageMapSourceCatalog,
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
      'Sources de la map',
      CinematicStagePreviewReadinessItemKind.ok,
      'aucune source de la map requise',
    );
  }
  final catalogStatus =
      _sourceCatalogReadinessMessage(asset, stageMapSourceCatalog);
  if (catalogStatus != null) {
    return _item(
      'Sources de la map',
      CinematicStagePreviewReadinessItemKind.blocking,
      catalogStatus,
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
      'Sources de la map',
      CinematicStagePreviewReadinessItemKind.incomplete,
      'Choisissez un personnage, objet ou déclencheur depuis la map de scène.',
    );
  }
  return _item(
    'Sources de la map',
    CinematicStagePreviewReadinessItemKind.ok,
    'sources de la map renseignées',
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
    CinematicStagePreviewReadinessItemKind.blocking => 'À corriger',
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

CinematicActorRef? _requiredActorFor(CinematicAsset asset, String actorId) {
  for (final actor in asset.requiredActors) {
    if (actor.actorId == actorId) {
      return actor;
    }
  }
  return null;
}

CinematicActorAppearanceBinding? _actorAppearanceBindingFor(
  CinematicStageContext context,
  String actorId,
) {
  for (final binding in context.actorAppearanceBindings) {
    if (binding.actorId == actorId) {
      return binding;
    }
  }
  return null;
}

bool _hasIdleAnimation(ProjectCharacterEntry character) {
  for (final animation in character.animations) {
    if (animation.state == CharacterAnimationState.idle &&
        animation.frames.isNotEmpty) {
      return true;
    }
  }
  return false;
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

ProjectCharacterEntry? _characterById(
  List<ProjectCharacterEntry> characters,
  String characterId,
) {
  for (final character in characters) {
    if (character.id == characterId) {
      return character;
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

bool _hasBindableMapEntitySource(
  CinematicStageMapSourceCatalog? catalog,
  String? sourceId,
) {
  final source = _mapEntitySource(catalog, sourceId);
  return source != null && source.canBindActor;
}

bool _hasMapEntitySource(
  CinematicStageMapSourceCatalog? catalog,
  String? sourceId,
) {
  return _mapEntitySource(catalog, sourceId) != null;
}

bool _hasMapEventSource(
  CinematicStageMapSourceCatalog? catalog,
  String? sourceId,
) {
  return _mapEventSource(catalog, sourceId) != null;
}

CinematicStageMapEntitySource? _mapEntitySource(
  CinematicStageMapSourceCatalog? catalog,
  String? sourceId,
) {
  if (sourceId == null ||
      catalog?.status != CinematicStageMapSourceCatalogStatus.available) {
    return null;
  }
  return catalog!.entityById(sourceId);
}

CinematicStageMapEventSource? _mapEventSource(
  CinematicStageMapSourceCatalog? catalog,
  String? sourceId,
) {
  if (sourceId == null ||
      catalog?.status != CinematicStageMapSourceCatalogStatus.available) {
    return null;
  }
  return catalog!.eventById(sourceId);
}

String? _sourceCatalogReadinessMessage(
  CinematicAsset asset,
  CinematicStageMapSourceCatalog? catalog,
) {
  if (asset.mapId == null) {
    return 'Choisissez d’abord une map de scène.';
  }
  if (catalog == null) {
    return 'Le catalogue des éléments de la map est en cours de chargement.';
  }
  if (catalog.stageMapId != asset.mapId) {
    return 'Le catalogue des éléments ne correspond pas à la map de scène.';
  }
  return switch (catalog.status) {
    CinematicStageMapSourceCatalogStatus.available => null,
    CinematicStageMapSourceCatalogStatus.missingStageMap =>
      'Choisissez d’abord une map de scène.',
    CinematicStageMapSourceCatalogStatus.mapDataUnavailable =>
      'Les données de la map de scène sont indisponibles.',
    CinematicStageMapSourceCatalogStatus.mapIdMismatch =>
      'Les données chargées ne correspondent pas à la map de scène.',
  };
}

List<CinematicsLibraryDiagnosticView> _stageDiagnostics(
  CinematicsLibraryEntry entry,
  CinematicAsset asset,
  int? mapWidth,
  int? mapHeight,
) {
  final entryDiagnostics = entry.diagnostics
      .where((diagnostic) => _stageDiagnosticCodes.contains(diagnostic.code))
      .toList();

  final report = diagnoseCinematicAsset(
    asset,
    mapWidth: mapWidth,
    mapHeight: mapHeight,
  );

  final assetDiagnostics = report.diagnostics
      .where((diagnostic) => _stageDiagnosticCodes.contains(diagnostic.code.name))
      .map((diagnostic) => CinematicsLibraryDiagnosticView(
            code: diagnostic.code.name,
            severity: switch (diagnostic.severity) {
              CinematicDiagnosticSeverity.error =>
                CinematicsLibraryDiagnosticSeverity.error,
              CinematicDiagnosticSeverity.warning =>
                CinematicsLibraryDiagnosticSeverity.warning,
              CinematicDiagnosticSeverity.info =>
                CinematicsLibraryDiagnosticSeverity.info,
            },
            message: diagnostic.message,
            sourceId: diagnostic.referenceId ?? diagnostic.stepId,
          ))
      .toList();

  final allDiagnostics = <String, CinematicsLibraryDiagnosticView>{};
  for (final d in entryDiagnostics) {
    allDiagnostics['${d.code}_${d.sourceId ?? ""}'] = d;
  }
  for (final d in assetDiagnostics) {
    allDiagnostics['${d.code}_${d.sourceId ?? ""}'] = d;
  }

  return allDiagnostics.values.toList(growable: false);
}

String _humanStageDiagnosticMessage(
  CinematicsLibraryDiagnosticView diagnostic,
  CinematicAsset asset,
) {
  final actorLabel = _actorLabelFor(asset, diagnostic.sourceId);
  final targetLabel = _targetLabelFor(asset, diagnostic.sourceId);
  return switch (diagnostic.code) {
    'stagePointDuplicateId' => 'Un repère de scène possède un identifiant en doublon.',
    'stagePointEmptyId' => 'Un repère de scène possède un identifiant vide.',
    'stagePointEmptyLabel' => 'Le nom du repère de scène ne doit pas être vide.',
    'stagePointInvalidCoordinate' => 'Les coordonnées du repère de scène doivent être des nombres valides.',
    'stagePointOutOfMap' => 'Le repère de scène est en dehors des limites de la carte.',
    'stagePointWithoutStageMap' => 'Des repères de scène sont placés mais aucune map n’est sélectionnée.',
    'stageMapUnknown' => 'La map de scène n’existe plus dans le projet.',
    'stageBackdropRequiresMap' =>
      'Choisissez une map avant d’utiliser un décor de map.',
    'actorBindingUnknownActor' =>
      'Un binding vise un acteur qui n’existe plus.',
    'actorBindingMissing' =>
      'Lie l’acteur ${actorLabel ?? 'requis'} avant une future preview.',
    'actorBindingDuplicatePlayer' =>
      'Un seul acteur peut représenter le joueur.',
    'actorBindingRequiresStageMap' =>
      'Choisissez une map avant de lier un acteur à un personnage ou objet.',
    'actorBindingMapEntityMissingSource' =>
      'Choisissez un personnage ou objet depuis les sources de la map.',
    'actorAppearanceBindingUnknownActor' =>
      'Une apparence vise un acteur qui n’existe plus.',
    'actorAppearanceBindingUnknownCharacter' =>
      'Le personnage choisi n’existe plus dans la Character Library.',
    'actorAppearanceBindingRequiresCinematicOnly' =>
      'Lie d’abord cet acteur en Cinématique uniquement pour choisir un personnage.',
    'cinematicOnlyCharacterMissing' =>
      'Choisissez un personnage Character Library pour ${actorLabel ?? 'cet acteur'}.',
    'characterLibraryUnavailable' =>
      'La Character Library ne contient aucun personnage disponible.',
    'characterAssetMissingSprite' =>
      'Le personnage choisi n’a pas encore de sprite exploitable.',
    'characterAssetMissingPreviewData' =>
      'Le personnage choisi a des données de preview à compléter.',
    'actorInitialPlacementUnknownActor' =>
      'Un départ de scène vise un acteur absent.',
    'actorInitialPlacementMissing' =>
      'Définissez un départ de scène pour ${actorLabel ?? 'cet acteur'}.',
    'actorInitialPlacementTargetUnknown' =>
      'Ce départ de scène pointe vers une destination absente.',
    'actorInitialPlacementRequiresBinding' =>
      'Lie l’acteur avant d’utiliser son personnage ou objet de map comme départ.',
    'actorInitialPlacementStagePointMissing' =>
      'Le placement initial de l’acteur "${actorLabel ?? diagnostic.sourceId}" référence un repère de scène inexistant.',
    'actorInitialPlacementStagePointWithoutStageMap' =>
      'Le placement initial de l’acteur "${actorLabel ?? diagnostic.sourceId}" référence un repère de scène alors qu’aucune map stage n’est définie.',
    'actorInitialPlacementStagePointOutOfMap' =>
      'Le placement initial de l’acteur "${actorLabel ?? diagnostic.sourceId}" référence un repère de scène en dehors des limites de la map.',
    'movementTargetBindingUnknownTarget' =>
      'Cette destination n’existe plus.',
    'movementTargetBindingRequiresStageMap' =>
      'Choisissez une map avant de lier une destination à un personnage, objet ou déclencheur.',
    'movementTargetBindingMissingSource' => targetLabel == null
        ? 'Choisissez un personnage, objet ou déclencheur depuis les sources de la map.'
        : '$targetLabel attend la sélection d’un personnage, objet ou déclencheur.',
    'movementTargetBindingStagePointMissing' => targetLabel == null
        ? 'La destination référence un repère de scène inexistant.'
        : 'La destination "$targetLabel" référence un repère de scène inexistant.',
    'movementTargetBindingStagePointWithoutStageMap' => targetLabel == null
        ? 'La destination référence un repère de scène alors qu’aucune map stage n’est définie.'
        : 'La destination "$targetLabel" référence un repère de scène alors qu’aucune map stage n’est définie.',
    'movementTargetBindingStagePointOutOfMap' => targetLabel == null
        ? 'La destination référence un repère de scène en dehors des limites de la map.'
        : 'La destination "$targetLabel" référence un repère de scène en dehors des limites de la map.',
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
  'actorAppearanceBindingUnknownActor',
  'actorAppearanceBindingUnknownCharacter',
  'actorAppearanceBindingRequiresCinematicOnly',
  'cinematicOnlyCharacterMissing',
  'characterLibraryUnavailable',
  'characterAssetMissingSprite',
  'characterAssetMissingPreviewData',
  'actorInitialPlacementUnknownActor',
  'actorInitialPlacementMissing',
  'actorInitialPlacementTargetUnknown',
  'actorInitialPlacementRequiresBinding',
  'movementTargetBindingUnknownTarget',
  'movementTargetBindingRequiresStageMap',
  'movementTargetBindingMissingSource',
  'movementTargetBindingStagePointMissing',
  'movementTargetBindingStagePointWithoutStageMap',
  'movementTargetBindingStagePointOutOfMap',
  'stagePointDuplicateId',
  'stagePointEmptyId',
  'stagePointEmptyLabel',
  'stagePointInvalidCoordinate',
  'stagePointOutOfMap',
  'stagePointWithoutStageMap',
  'actorInitialPlacementStagePointMissing',
  'actorInitialPlacementStagePointWithoutStageMap',
  'actorInitialPlacementStagePointOutOfMap',
};
