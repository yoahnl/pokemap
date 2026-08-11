import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../support/authoring_fingerprint.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../../workspace/project_snapshot.dart';

final class ItemCatalogAuthoringException implements Exception {
  const ItemCatalogAuthoringException(
    this.code,
    this.message, {
    this.details = const <String, Object?>{},
  });

  final String code;
  final String message;
  final Map<String, Object?> details;

  @override
  String toString() => 'ItemCatalogAuthoringException($code): $message';
}

final class ItemCatalogActions {
  const ItemCatalogActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable(
    <AuthoringActionDescriptor>[
      for (final action in const <(String, String)>[
        ('item.create', 'Create a canonical project item'),
        ('item.update', 'Replace one canonical project item definition'),
        ('item.clone', 'Clone a canonical project item'),
        ('item.delete_apply', 'Delete an unreferenced project item'),
        ('item.set_overworld_effect', 'Set an item overworld use'),
        ('item.set_battle_effect', 'Set an item battle use'),
        ('item.set_held_effect', 'Set an item held effect'),
        ('item.set_capture_effect', 'Set an item capture capability'),
        ('item.set_tm_hm_move', 'Set an item move-machine capability'),
      ])
        _descriptor(action.$1, action.$2),
    ],
  );

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final catalog = context.snapshot.itemCatalog;
    if (catalog == null) {
      throw const ItemCatalogAuthoringException(
        'item.catalog_missing',
        'The canonical item catalog is unavailable.',
      );
    }
    final parameters = context.request.parameters;
    final after = switch (context.request.actionId) {
      'item.create' => _create(catalog, parameters),
      'item.update' => _update(catalog, parameters),
      'item.clone' => _clone(catalog, parameters),
      'item.delete_apply' => _delete(context, catalog, parameters),
      'item.set_overworld_effect' => _setUse(
          catalog,
          parameters,
          ProjectItemUseContext.overworld,
        ),
      'item.set_battle_effect' => _setUse(
          catalog,
          parameters,
          ProjectItemUseContext.battle,
        ),
      'item.set_held_effect' => _setHeldEffect(catalog, parameters),
      'item.set_capture_effect' => _setCapture(catalog, parameters),
      'item.set_tm_hm_move' => _setMachine(catalog, parameters),
      _ => throw ItemCatalogAuthoringException(
          'item.action_unsupported',
          'The requested item action is unsupported.',
          details: <String, Object?>{'actionId': context.request.actionId},
        ),
    };
    return _draft(context, catalog, after);
  }
}

ProjectItemCatalog _create(
  ProjectItemCatalog catalog,
  Map<String, Object?> parameters,
) {
  _requireKeys(parameters, const <String>{'definition'});
  final definition = _definition(parameters['definition']);
  if (catalog.entries.any((entry) => entry.id == definition.id)) {
    throw ItemCatalogAuthoringException(
      'item.id_duplicate',
      'The item identity already exists.',
      details: <String, Object?>{'itemId': definition.id},
    );
  }
  return catalog.copyWith(
    entries: <ProjectItemDefinition>[...catalog.entries, definition],
  ).normalized();
}

ProjectItemCatalog _update(
  ProjectItemCatalog catalog,
  Map<String, Object?> parameters,
) {
  _requireKeys(parameters, const <String>{'itemId', 'definition'});
  final itemId = _itemId(parameters);
  final definition = _definition(parameters['definition']);
  if (definition.id != itemId) {
    throw const ItemCatalogAuthoringException(
      'item.identity_change_forbidden',
      'Updating an item cannot change its identity.',
    );
  }
  final index = _definitionIndex(catalog, itemId);
  final entries = catalog.entries.toList(growable: false);
  entries[index] = definition;
  return catalog.copyWith(entries: entries).normalized();
}

ProjectItemCatalog _clone(
  ProjectItemCatalog catalog,
  Map<String, Object?> parameters,
) {
  _requireKeys(
    parameters,
    const <String>{'sourceItemId', 'newItemId'},
    optional: const <String>{'displayName'},
  );
  final sourceItemId = _requiredString(parameters, 'sourceItemId');
  final newItemId = _requiredString(parameters, 'newItemId');
  if (catalog.entries.any((entry) => entry.id == newItemId)) {
    throw ItemCatalogAuthoringException(
      'item.id_duplicate',
      'The cloned item identity already exists.',
      details: <String, Object?>{'itemId': newItemId},
    );
  }
  final source = catalog.entries[_definitionIndex(catalog, sourceItemId)];
  final displayName = parameters['displayName'] == null
      ? '${source.displayName} Copy'
      : _requiredString(parameters, 'displayName');
  return catalog.copyWith(
    entries: <ProjectItemDefinition>[
      ...catalog.entries,
      source.copyWith(id: newItemId, displayName: displayName).normalized(),
    ],
  ).normalized();
}

ProjectItemCatalog _delete(
  AuthoringPlanningContext context,
  ProjectItemCatalog catalog,
  Map<String, Object?> parameters,
) {
  _requireKeys(parameters, const <String>{'itemId'});
  final itemId = _itemId(parameters);
  _definitionIndex(catalog, itemId);
  final references = buildProjectItemReferenceIndex(
    project: context.snapshot.manifest,
    maps: context.snapshot.maps,
    itemCatalog: catalog,
    additionalReferences: context.snapshot.additionalItemReferences,
  ).blockingReferencesFor(itemId);
  if (references.isNotEmpty) {
    throw ItemCatalogAuthoringException(
      'item.delete_references_blocking',
      'The item is still referenced by editable project content.',
      details: <String, Object?>{
        'itemId': itemId,
        'references': <Object?>[
          for (final reference in references)
            <String, Object?>{
              'kind': reference.kind.name,
              'sourceKind': reference.sourceKind,
              'sourceId': reference.sourceId,
              'editablePath': reference.editablePath,
            },
        ],
      },
    );
  }
  return catalog.copyWith(
    entries: <ProjectItemDefinition>[
      for (final definition in catalog.entries)
        if (definition.id != itemId) definition,
    ],
  ).normalized();
}

ProjectItemCatalog _setUse(
  ProjectItemCatalog catalog,
  Map<String, Object?> parameters,
  ProjectItemUseContext context,
) {
  _requireKeys(parameters, const <String>{'itemId', 'use'});
  final itemId = _itemId(parameters);
  final use = _use(parameters['use']);
  if (use.contexts.length != 1 || !use.contexts.contains(context)) {
    throw ItemCatalogAuthoringException(
      'item.use_context_mismatch',
      'The item use must target exactly the action context.',
      details: <String, Object?>{'context': context.name},
    );
  }
  return _replaceDefinition(catalog, itemId, (definition) {
    return definition.copyWith(
      uses: <ProjectItemUseDefinition>[
        for (final current in definition.uses)
          if (!current.contexts.contains(context)) current,
        use,
      ],
    ).normalized();
  });
}

ProjectItemCatalog _setHeldEffect(
  ProjectItemCatalog catalog,
  Map<String, Object?> parameters,
) {
  _requireKeys(parameters, const <String>{'itemId', 'heldEffectId'});
  final itemId = _itemId(parameters);
  final raw = parameters['heldEffectId'];
  if (raw != null && raw is! String) {
    throw const ItemCatalogAuthoringException(
      'item.held_effect_invalid',
      'heldEffectId must be a string or null.',
    );
  }
  return _replaceDefinition(
    catalog,
    itemId,
    (definition) =>
        definition.copyWith(heldEffectId: raw as String?).normalized(),
  );
}

ProjectItemCatalog _setCapture(
  ProjectItemCatalog catalog,
  Map<String, Object?> parameters,
) {
  _requireKeys(parameters, const <String>{'itemId', 'capture'});
  final itemId = _itemId(parameters);
  final capture = parameters['capture'] == null
      ? null
      : ProjectCaptureItemDefinition.fromJson(
          _jsonObject(parameters['capture'], 'capture'),
        );
  return _replaceDefinition(
    catalog,
    itemId,
    (definition) => definition.copyWith(capture: capture).normalized(),
  );
}

ProjectItemCatalog _setMachine(
  ProjectItemCatalog catalog,
  Map<String, Object?> parameters,
) {
  _requireKeys(parameters, const <String>{'itemId', 'machine'});
  final itemId = _itemId(parameters);
  final machine = parameters['machine'] == null
      ? null
      : ProjectMoveMachineItemDefinition.fromJson(
          _jsonObject(parameters['machine'], 'machine'),
        );
  return _replaceDefinition(
    catalog,
    itemId,
    (definition) => definition.copyWith(machine: machine).normalized(),
  );
}

ProjectItemCatalog _replaceDefinition(
  ProjectItemCatalog catalog,
  String itemId,
  ProjectItemDefinition Function(ProjectItemDefinition definition) transform,
) {
  final index = _definitionIndex(catalog, itemId);
  final entries = catalog.entries.toList(growable: false);
  entries[index] = transform(entries[index]);
  return catalog.copyWith(entries: entries).normalized();
}

AuthoringMutationDraft _draft(
  AuthoringPlanningContext context,
  ProjectItemCatalog before,
  ProjectItemCatalog after,
) {
  final beforeBytes = context.snapshot.resourceBytes(
    itemCatalogResourceIdentity,
  );
  final storageKey =
      context.snapshot.resourceStorageKeys[itemCatalogResourceIdentity];
  if (storageKey == null) {
    throw const ItemCatalogAuthoringException(
      'item.catalog_storage_unavailable',
      'The item catalog storage identity is unavailable.',
    );
  }
  final afterBytes = utf8.encode(jsonEncode(encodeProjectItemCatalog(after)));
  final resource = AuthoringResourceRef(
    kind: 'itemCatalog',
    id: 'items',
    revision: computeAuthoringBytesFingerprint(
      beforeBytes,
      logicalName: storageKey,
    ),
  );
  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(
      changes: <AuthoringResourceChange>[
        AuthoringResourceChange(
          resource: resource,
          storageKey: storageKey,
          beforeBytes: beforeBytes,
          afterBytes: afterBytes,
        ),
      ],
      diff: AuthoringDiff(<AuthoringDiffEntry>[
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.replace,
          resource: resource,
          path: r'$.entries',
          before: <Object?>[
            for (final definition in before.entries) definition.toJson(),
          ],
          after: <Object?>[
            for (final definition in after.entries) definition.toJson(),
          ],
        ),
      ]),
    ),
    preview: <String, Object?>{
      'actionId': context.request.actionId,
      'definitionCountBefore': before.entries.length,
      'definitionCountAfter': after.entries.length,
    },
  );
}

ProjectItemDefinition _definition(Object? value) =>
    ProjectItemDefinition.fromJson(_jsonObject(value, 'definition'));

ProjectItemUseDefinition _use(Object? value) =>
    ProjectItemUseDefinition.fromJson(_jsonObject(value, 'use'));

String _itemId(Map<String, Object?> parameters) =>
    _requiredString(parameters, 'itemId');

String _requiredString(Map<String, Object?> parameters, String key) {
  final value = parameters[key];
  if (value is! String || value.trim().isEmpty || value != value.trim()) {
    throw ItemCatalogAuthoringException(
      'item.parameter_invalid',
      '$key must be a nonblank trimmed string.',
      details: <String, Object?>{'parameter': key},
    );
  }
  return value;
}

Map<String, dynamic> _jsonObject(Object? value, String key) {
  if (value is! Map || value.keys.any((entry) => entry is! String)) {
    throw ItemCatalogAuthoringException(
      'item.parameter_invalid',
      '$key must be a JSON object.',
      details: <String, Object?>{'parameter': key},
    );
  }
  return Map<String, dynamic>.from(value);
}

int _definitionIndex(ProjectItemCatalog catalog, String itemId) {
  final index = catalog.entries.indexWhere((entry) => entry.id == itemId);
  if (index < 0) {
    throw ItemCatalogAuthoringException(
      'item.definition_not_found',
      'The requested item definition does not exist.',
      details: <String, Object?>{'itemId': itemId},
    );
  }
  return index;
}

void _requireKeys(
  Map<String, Object?> parameters,
  Set<String> required, {
  Set<String> optional = const <String>{},
}) {
  final missing = required.difference(parameters.keys.toSet());
  final unknown = parameters.keys.toSet().difference(<String>{
    ...required,
    ...optional,
  });
  if (missing.isNotEmpty || unknown.isNotEmpty) {
    throw ItemCatalogAuthoringException(
      'item.parameters_invalid',
      'The item action parameters do not match the canonical contract.',
      details: <String, Object?>{
        'missing': missing.toList()..sort(),
        'unknown': unknown.toList()..sort(),
      },
    );
  }
}

AuthoringActionDescriptor _descriptor(String id, String summary) {
  return AuthoringActionDescriptor(
    id: id,
    version: 1,
    summary: summary,
    inputSchemaId: 'pokemap.authoring/$id.input.v1',
    outputSchemaId: 'pokemap.authoring/$id.output.v1',
    riskLevel: id == 'item.delete_apply'
        ? AuthoringRiskLevel.high
        : AuthoringRiskLevel.medium,
    resourceKinds: const <String>['itemCatalog', 'itemDefinition'],
    capabilityIds: const <String>['authoring.gameplay.items'],
    requiredPermissions: const <AuthoringPermission>[
      AuthoringPermission.projectWrite,
    ],
    guarantees: const <AuthoringGuarantee>[
      AuthoringGuarantee.dryRun,
      AuthoringGuarantee.idempotent,
      AuthoringGuarantee.atomic,
      AuthoringGuarantee.revisionChecked,
      AuthoringGuarantee.undoable,
    ],
  );
}
