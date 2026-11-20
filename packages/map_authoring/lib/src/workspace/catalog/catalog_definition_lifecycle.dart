part of 'catalog_authoring_session.dart';

typedef _LibraryDefinitionPatch = ({
  List<CatalogDefinitionUnit> upserts,
  List<CatalogDefinitionKey> removals,
});

extension _CatalogDefinitionLifecycle on CatalogAuthoringSession {
  Future<AuthoringMutationPlanResult> _planLibraryDefinition(
      AuthoringRequest request) async {
    if (request.actionVersion != 1 || request.idempotencyKey == null) {
      throw const FormatException(
          'Library definition actions require version 1 and an idempotency key.');
    }
    final duplicate =
        request.actionId == catalogDefinitionDuplicateDescriptor.id;
    final descriptor = duplicate
        ? catalogDefinitionDuplicateDescriptor
        : catalogDefinitionDeleteDescriptor;
    final args = Map<String, dynamic>.from(request.parameters);
    rejectUnknownContractKeys(args, {
      'resourceKind',
      'id',
      if (duplicate) ...['targetId', 'name']
    });
    final kind = requireContractString(args['resourceKind'], 'resourceKind');
    if (kind == 'resourceLibraryEntry' ||
        !descriptor.resourceKinds.contains(kind)) {
      throw const FormatException('This library resource kind is unsupported.');
    }
    final key = CatalogDefinitionKey(
        catalogResourceKinds[kind]!, requireContractString(args['id'], 'id'));
    final current = (await CatalogProjectReader.open(
        store: reader.store,
        descriptor: reader.descriptor,
        metadataFields: {}))!;
    if (current.revision != request.expectedRevision) throw _libraryPlanStale();
    final patch = await current.read((catalog) async {
      final source = await catalog.lookup(key);
      if (source == null) {
        throw AuthoringPlanException(
            code: 'catalog.definition_missing',
            message: 'The library definition no longer exists.');
      }
      final classificationKey = CatalogDefinitionKey(
          CatalogDefinitionKind.resourceLibraryEntry, '$kind:${key.id}');
      final classification = await catalog.lookup(classificationKey);
      return duplicate
          ? _copyLibraryDefinition(catalog, source, classification, args)
          : _removeLibraryDefinition(catalog, source, classification, kind);
    });
    final editing = await _editing();
    if (editing.snapshot.root != current.catalog.snapshot.root) {
      throw _libraryPlanStale();
    }
    final planned = await editing.planPatch(
        upserts: patch.upserts,
        removals: patch.removals,
        idempotencyKey: request.idempotencyKey!,
        request: request);
    final plan = planned.plan;
    _plans[plan.planId] = planned;
    final receipt = plan.toPlannedReceipt();
    return AuthoringMutationPlanResult(
        plan: plan,
        snapshotRevision: current.revision,
        receipt: receipt,
        publicProjection: await projections?.preparePlan(
            plan: plan, receipt: receipt, snapshotRevision: current.revision));
  }
}

AuthoringPlanException _libraryPlanStale() => AuthoringPlanException(
    code: 'plan.stale', message: 'The catalog changed before planning.');

Future<_LibraryDefinitionPatch> _copyLibraryDefinition(
  PortableProjectCatalog catalog,
  CatalogDefinitionUnit source,
  CatalogDefinitionUnit? classification,
  Map<String, dynamic> args,
) async {
  final id = requireContractString(args['targetId'], 'targetId');
  final name = requireContractString(args['name'], 'name');
  if (!RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(id) || name.length > 256) {
    throw const FormatException('The new identity or name is invalid.');
  }
  final key = CatalogDefinitionKey(source.key.kind, id);
  if (await catalog.lookup(key) != null) {
    throw AuthoringPlanException(
        code: 'catalog.definition_exists',
        message: 'The new library identity already exists.');
  }
  final position =
      await CatalogResourcePositions.read(catalog.snapshot, key.kind);
  final template = CatalogDefinitionUnit(
      key: key,
      payload: {...source.payload, 'id': id, 'position': position},
      references: source.references);
  final copy = catalog.replaceDefinitionValue(template, {
    ...Map<String, Object?>.from(source.payload['value'] as Map),
    'id': id,
    'name': name,
  });
  return (
    upserts: [
      copy,
      if (classification != null)
        catalog.createResourceLibraryEntryUnit(
            ResourceLibraryEntry.fromJson({
              ...Map<String, dynamic>.from(
                  classification.payload['value'] as Map),
              'resourceId': id,
            }),
            position: await CatalogResourcePositions.read(
                catalog.snapshot, CatalogDefinitionKind.resourceLibraryEntry)),
    ],
    removals: const <CatalogDefinitionKey>[],
  );
}

Future<_LibraryDefinitionPatch> _removeLibraryDefinition(
  PortableProjectCatalog catalog,
  CatalogDefinitionUnit source,
  CatalogDefinitionUnit? classification,
  String kind,
) async {
  if (kind == 'borderBlueprint' &&
      (catalog.definitionValue(source) as BorderBlueprintRecord)
              .latestPublished !=
          null) {
    throw MapAuthoringException(
        code: 'border.blueprint.delete_published_forbidden',
        message: 'A published border must be deprecated in its workshop.');
  }
  final snapshot = catalog.snapshot;
  await _requireUnusedLibraryDefinition(
      snapshot, source.key, kind, classification?.key);
  final removed = [source, if (classification != null) classification];
  final upserts = <CatalogDefinitionUnit>[];
  for (final unit in removed) {
    final kind = unit.key.kind;
    final position = unit.payload['position'];
    final count = await CatalogResourcePositions.read(snapshot, kind);
    if (position is! int || position < 0 || position >= count) {
      throw const FormatException(
          'catalog.resource_positions.invalid_position');
    }
    if (position != count - 1) {
      final last =
          await CatalogResourcePositions.readSlot(snapshot, kind, count - 1);
      final mover = await catalog.lookup(CatalogDefinitionKey(kind, last));
      if (mover == null || mover.payload['position'] != count - 1) {
        throw const FormatException('catalog.resource_positions.slots_stale');
      }
      upserts.add(CatalogDefinitionUnit(
          key: mover.key,
          payload: {...mover.payload, 'position': position},
          references: mover.references));
    }
  }
  return (
    upserts: upserts,
    removals: removed.map((unit) => unit.key).toList(),
  );
}

Future<void> _requireUnusedLibraryDefinition(
    CatalogSnapshot snapshot, CatalogDefinitionKey key, String kind,
    CatalogDefinitionKey? classification) async {
  await CatalogResourceUsageIndex.requirePrepared(snapshot);
  if (!await CatalogReverseReferences.prepared(snapshot)) {
    throw const CatalogStorageException(
        'catalog.resource_usage.preparation_required',
        'Prepare the library reference indexes before changing the resource.');
  }
  final owners = await CatalogResourceUsageIndex.libraryConsumerOwners(
      snapshot, kind, key.id);
  final definitions = await CatalogReverseReferences.consumers(snapshot, key);
  final linkedDefinitions = definitions
      .where((dependency) => dependency != classification && dependency != key)
      .toList();
  if (owners.isNotEmpty || linkedDefinitions.isNotEmpty) {
    throw MapAuthoringException(
        code: 'catalog.definition_in_use',
        message: 'The resource has references in the project.',
        details: {
          'owners': owners.toList()..sort(),
          'definitions':
              linkedDefinitions.map((item) => item.toJson()).toList(),
        });
  }
}
