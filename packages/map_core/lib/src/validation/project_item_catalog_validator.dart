import '../models/items/project_item_capabilities.dart';
import '../models/items/project_item_catalog.dart';
import '../models/items/project_item_effect_definition.dart';
import '../read_models/item_capability_truth.dart';
import '../serialization/project_item_catalog_codec.dart';

enum ProjectItemCatalogDiagnosticSeverity { error, warning }

enum ProjectItemCatalogDiagnosticCode {
  duplicateItemId,
  unsupportedSchemaVersion,
  unknownKind,
  invalidDefinition,
  invalidRatio,
  incompatibleTarget,
  unknownHeldEffect,
  missingMoveId,
  unknownSemanticAction,
  unsupportedCapability,
  passiveWithoutPrice,
  emptyPocketFallback,
  unconsumedExternalField,
}

final class ProjectItemCatalogDiagnostic {
  const ProjectItemCatalogDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    required this.path,
    this.entryIndex,
    this.itemId,
  });

  final ProjectItemCatalogDiagnosticCode code;
  final ProjectItemCatalogDiagnosticSeverity severity;
  final String message;
  final String path;
  final int? entryIndex;
  final String? itemId;

  bool get isBlocking => severity == ProjectItemCatalogDiagnosticSeverity.error;
}

final class ProjectItemCatalogValidationReport {
  ProjectItemCatalogValidationReport({
    required this.catalog,
    required List<ProjectItemCatalogDiagnostic> diagnostics,
    required List<ItemCapabilityAssessment> assessments,
  }) : diagnostics = List.unmodifiable(diagnostics),
       assessments = List.unmodifiable(assessments);

  final ProjectItemCatalog? catalog;
  final List<ProjectItemCatalogDiagnostic> diagnostics;
  final List<ItemCapabilityAssessment> assessments;

  bool get hasBlockingDiagnostics =>
      diagnostics.any((diagnostic) => diagnostic.isBlocking);

  ItemCapabilityAssessment? assessmentFor(String itemId) {
    final normalizedItemId = itemId.trim();
    for (final assessment in assessments.reversed) {
      if (assessment.itemId == normalizedItemId) {
        return assessment;
      }
    }
    return null;
  }
}

ProjectItemCatalogValidationReport validateProjectItemCatalog(
  ProjectItemCatalog catalog, {
  required ItemCapabilityTruth capabilityTruth,
  Map<String, Set<String>> unconsumedExternalFieldsByItemId = const {},
}) {
  final diagnostics = <ProjectItemCatalogDiagnostic>[];
  final blockingItemIds = <String>{};
  var hasGlobalBlocker = false;

  void addDiagnostic(
    ProjectItemCatalogDiagnosticCode code,
    ProjectItemCatalogDiagnosticSeverity severity,
    String message,
    String path, {
    int? entryIndex,
    String? itemId,
  }) {
    diagnostics.add(
      ProjectItemCatalogDiagnostic(
        code: code,
        severity: severity,
        message: message,
        path: path,
        entryIndex: entryIndex,
        itemId: itemId,
      ),
    );
    if (severity == ProjectItemCatalogDiagnosticSeverity.error) {
      if (itemId == null) {
        hasGlobalBlocker = true;
      } else {
        blockingItemIds.add(itemId);
      }
    }
  }

  if (catalog.schemaVersion != 1) {
    addDiagnostic(
      ProjectItemCatalogDiagnosticCode.unsupportedSchemaVersion,
      ProjectItemCatalogDiagnosticSeverity.error,
      'Unsupported project item catalog schemaVersion: ${catalog.schemaVersion}',
      r'$.schemaVersion',
    );
  }

  final firstIndexByItemId = <String, int>{};
  for (var index = 0; index < catalog.entries.length; index += 1) {
    final item = catalog.entries[index];
    final itemId = item.id.trim();
    final itemPath = '\$.entries[$index]';
    if (itemId.isEmpty) {
      addDiagnostic(
        ProjectItemCatalogDiagnosticCode.invalidDefinition,
        ProjectItemCatalogDiagnosticSeverity.error,
        'Item id must not be empty',
        '$itemPath.id',
        entryIndex: index,
        itemId: itemId,
      );
    }
    final firstIndex = firstIndexByItemId[itemId];
    if (firstIndex == null) {
      firstIndexByItemId[itemId] = index;
    } else {
      addDiagnostic(
        ProjectItemCatalogDiagnosticCode.duplicateItemId,
        ProjectItemCatalogDiagnosticSeverity.error,
        'Duplicate item id first declared at entry $firstIndex',
        '$itemPath.id',
        entryIndex: index,
        itemId: itemId,
      );
      blockingItemIds.add(itemId);
    }

    if (item.pocketId.trim().isEmpty) {
      addDiagnostic(
        ProjectItemCatalogDiagnosticCode.emptyPocketFallback,
        ProjectItemCatalogDiagnosticSeverity.warning,
        'Empty pocket uses the presentation fallback',
        '$itemPath.pocketId',
        entryIndex: index,
        itemId: itemId,
      );
    }

    final isPassive =
        item.uses.isEmpty &&
        item.capture == null &&
        item.machine == null &&
        item.heldEffectId == null;
    if (isPassive && item.buyPrice == null && item.sellPrice == null) {
      addDiagnostic(
        ProjectItemCatalogDiagnosticCode.passiveWithoutPrice,
        ProjectItemCatalogDiagnosticSeverity.warning,
        'Passive item has no default price',
        itemPath,
        entryIndex: index,
        itemId: itemId,
      );
    }

    final occupiedContexts = <ProjectItemUseContext>{};
    for (var useIndex = 0; useIndex < item.uses.length; useIndex += 1) {
      final use = item.uses[useIndex];
      final usePath = '$itemPath.uses[$useIndex]';
      if (use.contexts.isEmpty) {
        addDiagnostic(
          ProjectItemCatalogDiagnosticCode.invalidDefinition,
          ProjectItemCatalogDiagnosticSeverity.error,
          'Item use contexts must not be empty',
          '$usePath.contexts',
          entryIndex: index,
          itemId: itemId,
        );
      }
      if (occupiedContexts.intersection(use.contexts).isNotEmpty) {
        addDiagnostic(
          ProjectItemCatalogDiagnosticCode.invalidDefinition,
          ProjectItemCatalogDiagnosticSeverity.error,
          'Item use contexts must not overlap',
          '$usePath.contexts',
          entryIndex: index,
          itemId: itemId,
        );
      }
      occupiedContexts.addAll(use.contexts);
      final effectCapability = projectItemEffectCapabilityOf(use.effect);
      final unsupportedContexts = use.contexts
          .where(
            (context) =>
                !capabilityTruth.supportsUse(context, effectCapability),
          )
          .toList(growable: false);
      if (unsupportedContexts.isNotEmpty) {
        addDiagnostic(
          ProjectItemCatalogDiagnosticCode.unsupportedCapability,
          ProjectItemCatalogDiagnosticSeverity.error,
          'Item effect ${effectCapability.name} is not wired for '
              '${unsupportedContexts.map((context) => context.name).join(', ')}',
          '$usePath.effect.kind',
          entryIndex: index,
          itemId: itemId,
        );
      }
      _validateEffect(
        use,
        capabilityTruth,
        path: usePath,
        entryIndex: index,
        itemId: itemId,
        addDiagnostic: addDiagnostic,
      );
    }

    final capture = item.capture;
    if (capture != null) {
      if (capture.rateNumerator <= 0 || capture.rateDenominator <= 0) {
        addDiagnostic(
          ProjectItemCatalogDiagnosticCode.invalidRatio,
          ProjectItemCatalogDiagnosticSeverity.error,
          'Capture ratio must be strictly positive',
          '$itemPath.capture',
          entryIndex: index,
          itemId: itemId,
        );
      }
      if (capture.allowedEncounterKinds.isEmpty) {
        addDiagnostic(
          ProjectItemCatalogDiagnosticCode.invalidDefinition,
          ProjectItemCatalogDiagnosticSeverity.error,
          'Capture item must declare allowed encounter kinds',
          '$itemPath.capture.allowedEncounterKinds',
          entryIndex: index,
          itemId: itemId,
        );
      }
      if (!capabilityTruth.supportsCapture) {
        addDiagnostic(
          ProjectItemCatalogDiagnosticCode.unsupportedCapability,
          ProjectItemCatalogDiagnosticSeverity.error,
          'Capture items are not wired',
          '$itemPath.capture',
          entryIndex: index,
          itemId: itemId,
        );
      }
    }

    final machine = item.machine;
    if (machine != null) {
      if (machine.moveId.trim().isEmpty) {
        addDiagnostic(
          ProjectItemCatalogDiagnosticCode.missingMoveId,
          ProjectItemCatalogDiagnosticSeverity.error,
          'Move machine moveId must not be empty',
          '$itemPath.machine.moveId',
          entryIndex: index,
          itemId: itemId,
        );
      }
      if (machine.kind == ProjectMoveMachineKind.hm && machine.consumable) {
        addDiagnostic(
          ProjectItemCatalogDiagnosticCode.invalidDefinition,
          ProjectItemCatalogDiagnosticSeverity.error,
          'HM items must not be consumable',
          '$itemPath.machine.consumable',
          entryIndex: index,
          itemId: itemId,
        );
      }
      if (!capabilityTruth.supportsMoveMachines) {
        addDiagnostic(
          ProjectItemCatalogDiagnosticCode.unsupportedCapability,
          ProjectItemCatalogDiagnosticSeverity.error,
          'Move machines are not wired',
          '$itemPath.machine',
          entryIndex: index,
          itemId: itemId,
        );
      }
    }

    final heldEffectId = item.heldEffectId?.trim();
    if (heldEffectId != null &&
        (heldEffectId.isEmpty ||
            !capabilityTruth.supportsHeldEffect(heldEffectId))) {
      addDiagnostic(
        ProjectItemCatalogDiagnosticCode.unknownHeldEffect,
        ProjectItemCatalogDiagnosticSeverity.error,
        'Held effect is not declared by capability truth: $heldEffectId',
        '$itemPath.heldEffectId',
        entryIndex: index,
        itemId: itemId,
      );
    }
  }

  for (final entry in unconsumedExternalFieldsByItemId.entries) {
    final itemId = entry.key.trim();
    for (final field in entry.value) {
      final normalizedField = field.trim();
      if (normalizedField.isEmpty) {
        continue;
      }
      addDiagnostic(
        ProjectItemCatalogDiagnosticCode.unconsumedExternalField,
        ProjectItemCatalogDiagnosticSeverity.warning,
        'External field is not consumed by the canonical item system: $normalizedField',
        'external.$normalizedField',
        itemId: itemId,
      );
    }
  }

  final assessments = <ItemCapabilityAssessment>[];
  for (final item in catalog.entries) {
    final itemId = item.id.trim();
    final passive =
        item.uses.isEmpty &&
        item.capture == null &&
        item.machine == null &&
        item.heldEffectId == null;
    final readiness = hasGlobalBlocker || blockingItemIds.contains(itemId)
        ? ItemCapabilityReadiness.unsupported
        : passive
        ? ItemCapabilityReadiness.passive
        : ItemCapabilityReadiness.runtimeReady;
    assessments.add(
      ItemCapabilityAssessment(
        itemId: itemId,
        readiness: readiness,
        presentationPocketId: item.pocketId.trim().isEmpty
            ? capabilityTruth.presentationPocketFallback
            : item.pocketId.trim(),
      ),
    );
  }

  return ProjectItemCatalogValidationReport(
    catalog: catalog,
    diagnostics: diagnostics,
    assessments: assessments,
  );
}

ProjectItemCatalogValidationReport validateProjectItemCatalogJson(
  Object? json, {
  required ItemCapabilityTruth capabilityTruth,
}) {
  try {
    return validateProjectItemCatalog(
      decodeProjectItemCatalog(json),
      capabilityTruth: capabilityTruth,
    );
  } on UnsupportedItemCatalogSchema catch (error) {
    return _codecFailureReport(
      ProjectItemCatalogDiagnosticCode.unsupportedSchemaVersion,
      error,
    );
  } on ProjectItemCatalogCodecException catch (error) {
    return _codecFailureReport(
      error.code == ProjectItemCatalogCodecErrorCode.unsupportedKind
          ? ProjectItemCatalogDiagnosticCode.unknownKind
          : ProjectItemCatalogDiagnosticCode.invalidDefinition,
      error,
    );
  }
}

void _validateEffect(
  ProjectItemUseDefinition use,
  ItemCapabilityTruth capabilityTruth, {
  required String path,
  required int entryIndex,
  required String itemId,
  required void Function(
    ProjectItemCatalogDiagnosticCode,
    ProjectItemCatalogDiagnosticSeverity,
    String,
    String, {
    int? entryIndex,
    String? itemId,
  })
  addDiagnostic,
}) {
  final effect = use.effect;
  final targetIsCompatible = switch (effect) {
    ProjectItemHealHpEffectDefinition() ||
    ProjectItemCureStatusEffectDefinition() ||
    ProjectItemReviveEffectDefinition() =>
      use.target == ProjectItemTargetKind.partyMember,
    ProjectItemRestorePpEffectDefinition() =>
      use.target == ProjectItemTargetKind.partyMove,
    ProjectItemRepelEffectDefinition() =>
      use.target == ProjectItemTargetKind.world,
    ProjectItemSemanticActionEffectDefinition() =>
      use.target == ProjectItemTargetKind.world ||
          use.target == ProjectItemTargetKind.none,
    _ => false,
  };
  if (!targetIsCompatible) {
    addDiagnostic(
      ProjectItemCatalogDiagnosticCode.incompatibleTarget,
      ProjectItemCatalogDiagnosticSeverity.error,
      'Item target is incompatible with its effect',
      '$path.target',
      entryIndex: entryIndex,
      itemId: itemId,
    );
  }

  switch (effect) {
    case ProjectItemHealHpEffectDefinition(:final mode, :final amount):
    case ProjectItemRestorePpEffectDefinition(:final mode, :final amount):
      if ((mode == ProjectItemAmountMode.flat &&
              (amount == null || amount <= 0)) ||
          (mode == ProjectItemAmountMode.full && amount != null)) {
        addDiagnostic(
          ProjectItemCatalogDiagnosticCode.invalidDefinition,
          ProjectItemCatalogDiagnosticSeverity.error,
          'Item amount does not match its mode',
          '$path.effect.amount',
          entryIndex: entryIndex,
          itemId: itemId,
        );
      }
    case ProjectItemCureStatusEffectDefinition(:final mode, :final statusIds):
      if ((mode == ProjectItemStatusCureMode.listed && statusIds.isEmpty) ||
          (mode == ProjectItemStatusCureMode.all && statusIds.isNotEmpty)) {
        addDiagnostic(
          ProjectItemCatalogDiagnosticCode.invalidDefinition,
          ProjectItemCatalogDiagnosticSeverity.error,
          'Status ids do not match the cure mode',
          '$path.effect.statusIds',
          entryIndex: entryIndex,
          itemId: itemId,
        );
      }
    case ProjectItemReviveEffectDefinition(
      :final rateNumerator,
      :final rateDenominator,
    ):
      if (rateNumerator <= 0 || rateDenominator <= 0) {
        addDiagnostic(
          ProjectItemCatalogDiagnosticCode.invalidRatio,
          ProjectItemCatalogDiagnosticSeverity.error,
          'Revive ratio must be strictly positive',
          '$path.effect',
          entryIndex: entryIndex,
          itemId: itemId,
        );
      }
    case ProjectItemRepelEffectDefinition(:final steps):
      if (steps <= 0) {
        addDiagnostic(
          ProjectItemCatalogDiagnosticCode.invalidDefinition,
          ProjectItemCatalogDiagnosticSeverity.error,
          'Repel steps must be strictly positive',
          '$path.effect.steps',
          entryIndex: entryIndex,
          itemId: itemId,
        );
      }
    case ProjectItemSemanticActionEffectDefinition(:final actionId):
      final normalizedActionId = actionId.trim();
      if (normalizedActionId.isEmpty ||
          !capabilityTruth.supportsSemanticAction(normalizedActionId)) {
        addDiagnostic(
          ProjectItemCatalogDiagnosticCode.unknownSemanticAction,
          ProjectItemCatalogDiagnosticSeverity.error,
          'Semantic action is not declared by capability truth: $normalizedActionId',
          '$path.effect.actionId',
          entryIndex: entryIndex,
          itemId: itemId,
        );
      }
    default:
      addDiagnostic(
        ProjectItemCatalogDiagnosticCode.unknownKind,
        ProjectItemCatalogDiagnosticSeverity.error,
        'Unknown project item effect kind',
        '$path.effect.kind',
        entryIndex: entryIndex,
        itemId: itemId,
      );
  }
}

ProjectItemCatalogValidationReport _codecFailureReport(
  ProjectItemCatalogDiagnosticCode code,
  ProjectItemCatalogCodecException error,
) {
  return ProjectItemCatalogValidationReport(
    catalog: null,
    diagnostics: [
      ProjectItemCatalogDiagnostic(
        code: code,
        severity: ProjectItemCatalogDiagnosticSeverity.error,
        message: error.message,
        path: error.path,
        entryIndex: error.entryIndex,
        itemId: error.itemId,
      ),
    ],
    assessments: const [],
  );
}
