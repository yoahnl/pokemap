import '../models/items/project_item_catalog.dart';
import '../models/items/project_item_definition.dart';

enum ProjectItemCatalogCodecErrorCode {
  invalidRoot,
  unsupportedSchema,
  invalidValue,
  legacyField,
  unexpectedField,
  unsupportedKind,
}

class ProjectItemCatalogCodecException extends FormatException {
  ProjectItemCatalogCodecException({
    required this.code,
    required String message,
    required this.path,
    this.entryIndex,
    this.itemId,
  }) : super(message);

  final ProjectItemCatalogCodecErrorCode code;
  final String path;
  final int? entryIndex;
  final String? itemId;

  @override
  String toString() {
    final location = entryIndex == null
        ? path
        : '$path (entryIndex: $entryIndex, itemId: ${itemId ?? '<unknown>'})';
    return 'ProjectItemCatalogCodecException(${code.name}) at $location: $message';
  }
}

final class UnsupportedItemCatalogSchema
    extends ProjectItemCatalogCodecException {
  UnsupportedItemCatalogSchema(this.schemaVersion)
    : super(
        code: ProjectItemCatalogCodecErrorCode.unsupportedSchema,
        message: schemaVersion == null
            ? 'Project item catalog schemaVersion 1 is required'
            : 'Unsupported project item catalog schemaVersion: $schemaVersion',
        path: r'$.schemaVersion',
      );

  final Object? schemaVersion;
}

ProjectItemCatalog decodeProjectItemCatalog(Object? json) {
  final root = _requireObject(json, path: r'$');
  _requireAllowedFields(root, const {'schemaVersion', 'entries'}, path: r'$');

  final schemaVersion = root['schemaVersion'];
  if (schemaVersion is! int || schemaVersion != 1) {
    throw UnsupportedItemCatalogSchema(schemaVersion);
  }
  final rawEntries = root['entries'];
  if (rawEntries is! List) {
    throw ProjectItemCatalogCodecException(
      code: ProjectItemCatalogCodecErrorCode.invalidValue,
      message: 'Project item catalog entries must be a list',
      path: r'$.entries',
    );
  }

  final entries = <ProjectItemDefinition>[];
  for (var index = 0; index < rawEntries.length; index += 1) {
    entries.add(_decodeEntry(rawEntries[index], index));
  }
  return ProjectItemCatalog(
    schemaVersion: schemaVersion,
    entries: entries,
  ).normalized();
}

Map<String, Object?> encodeProjectItemCatalog(ProjectItemCatalog catalog) {
  if (catalog.schemaVersion != 1) {
    throw UnsupportedItemCatalogSchema(catalog.schemaVersion);
  }
  return Map<String, Object?>.from(catalog.normalized().toJson());
}

ProjectItemDefinition _decodeEntry(Object? rawEntry, int index) {
  final entryPath = '\$.entries[$index]';
  final entry = _requireObject(rawEntry, path: entryPath, entryIndex: index);
  final itemId = switch (entry['id']) {
    final String id when id.trim().isNotEmpty => id.trim(),
    _ => null,
  };
  _requireAllowedFields(
    entry,
    const {
      'id',
      'displayName',
      'aliases',
      'pocketId',
      'description',
      'buyPrice',
      'sellPrice',
      'tags',
      'uses',
      'capture',
      'machine',
      'heldEffectId',
    },
    legacyFields: const {
      'categoryId',
      'effectText',
      'shortEffectText',
      'shortEffect',
      'effect',
    },
    path: entryPath,
    entryIndex: index,
    itemId: itemId,
  );

  final rawUses = entry['uses'];
  if (rawUses != null) {
    if (rawUses is! List) {
      throw _entryError(
        ProjectItemCatalogCodecErrorCode.invalidValue,
        'Item uses must be a list',
        '$entryPath.uses',
        index,
        itemId,
      );
    }
    for (var useIndex = 0; useIndex < rawUses.length; useIndex += 1) {
      _validateUse(rawUses[useIndex], index, itemId, useIndex);
    }
  }

  final capture = entry['capture'];
  if (capture != null) {
    final capturePath = '$entryPath.capture';
    final captureObject = _requireObject(
      capture,
      path: capturePath,
      entryIndex: index,
      itemId: itemId,
    );
    _requireAllowedFields(
      captureObject,
      const {'rateNumerator', 'rateDenominator', 'allowedEncounterKinds'},
      path: capturePath,
      entryIndex: index,
      itemId: itemId,
    );
  }

  final machine = entry['machine'];
  if (machine != null) {
    final machinePath = '$entryPath.machine';
    final machineObject = _requireObject(
      machine,
      path: machinePath,
      entryIndex: index,
      itemId: itemId,
    );
    _requireAllowedFields(
      machineObject,
      const {'moveId', 'kind', 'consumable'},
      path: machinePath,
      entryIndex: index,
      itemId: itemId,
    );
  }

  try {
    return ProjectItemDefinition.fromJson(Map<String, dynamic>.from(entry));
  } on ProjectItemCatalogCodecException {
    rethrow;
  } catch (error) {
    throw _entryError(
      ProjectItemCatalogCodecErrorCode.invalidValue,
      'Invalid project item definition: $error',
      entryPath,
      index,
      itemId,
    );
  }
}

void _validateUse(
  Object? rawUse,
  int entryIndex,
  String? itemId,
  int useIndex,
) {
  final path = '\$.entries[$entryIndex].uses[$useIndex]';
  final use = _requireObject(
    rawUse,
    path: path,
    entryIndex: entryIndex,
    itemId: itemId,
  );
  _requireAllowedFields(
    use,
    const {'contexts', 'target', 'consumption', 'effect'},
    path: path,
    entryIndex: entryIndex,
    itemId: itemId,
  );
  final effectPath = '$path.effect';
  final rawEffect = use['effect'];
  if (rawEffect is String) {
    throw _entryError(
      ProjectItemCatalogCodecErrorCode.legacyField,
      'Free-text item effects are not supported',
      effectPath,
      entryIndex,
      itemId,
    );
  }
  final effect = _requireObject(
    rawEffect,
    path: effectPath,
    entryIndex: entryIndex,
    itemId: itemId,
  );
  final kind = effect['kind'];
  final allowedFields = switch (kind) {
    'heal_hp' || 'restore_pp' => const {'kind', 'mode', 'amount'},
    'cure_status' => const {'kind', 'mode', 'statusIds'},
    'revive' => const {'kind', 'rateNumerator', 'rateDenominator'},
    'repel' => const {'kind', 'steps'},
    'semantic_action' => const {'kind', 'actionId'},
    _ => null,
  };
  if (allowedFields == null) {
    throw _entryError(
      ProjectItemCatalogCodecErrorCode.unsupportedKind,
      'Unsupported project item effect kind: $kind',
      '$effectPath.kind',
      entryIndex,
      itemId,
    );
  }
  _requireAllowedFields(
    effect,
    allowedFields,
    path: effectPath,
    entryIndex: entryIndex,
    itemId: itemId,
  );
}

Map<String, Object?> _requireObject(
  Object? value, {
  required String path,
  int? entryIndex,
  String? itemId,
}) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw ProjectItemCatalogCodecException(
      code: ProjectItemCatalogCodecErrorCode.invalidRoot,
      message: 'Expected a JSON object',
      path: path,
      entryIndex: entryIndex,
      itemId: itemId,
    );
  }
  return value.cast<String, Object?>();
}

void _requireAllowedFields(
  Map<String, Object?> value,
  Set<String> allowedFields, {
  required String path,
  Set<String> legacyFields = const {},
  int? entryIndex,
  String? itemId,
}) {
  for (final field in value.keys) {
    if (legacyFields.contains(field)) {
      throw ProjectItemCatalogCodecException(
        code: ProjectItemCatalogCodecErrorCode.legacyField,
        message: 'Legacy item catalog field is not supported: $field',
        path: '$path.$field',
        entryIndex: entryIndex,
        itemId: itemId,
      );
    }
    if (!allowedFields.contains(field)) {
      throw ProjectItemCatalogCodecException(
        code: ProjectItemCatalogCodecErrorCode.unexpectedField,
        message: 'Unexpected item catalog field: $field',
        path: '$path.$field',
        entryIndex: entryIndex,
        itemId: itemId,
      );
    }
  }
}

ProjectItemCatalogCodecException _entryError(
  ProjectItemCatalogCodecErrorCode code,
  String message,
  String path,
  int entryIndex,
  String? itemId,
) {
  return ProjectItemCatalogCodecException(
    code: code,
    message: message,
    path: path,
    entryIndex: entryIndex,
    itemId: itemId,
  );
}
