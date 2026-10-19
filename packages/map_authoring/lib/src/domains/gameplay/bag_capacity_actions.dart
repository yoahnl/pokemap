import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../../workspace/project_snapshot.dart';
import '../maps/map_lifecycle_adapter.dart';

final class BagCapacityAuthoringException implements Exception {
  const BagCapacityAuthoringException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'BagCapacityAuthoringException($code): $message';
}

final class BagCapacityActions {
  const BagCapacityActions();

  static final descriptors = <AuthoringActionDescriptor>[
    AuthoringActionDescriptor(
      id: 'bag.capacity.set',
      version: 1,
      summary: 'Replace optional per-pocket bag capacity; empty pockets resets unlimited',
      inputSchemaId: 'pokemap.authoring/bag.capacity.set.input.v1',
      outputSchemaId: 'pokemap.authoring/bag.capacity.set.output.v1',
      riskLevel: AuthoringRiskLevel.medium,
      resourceKinds: const ['project', 'bagCapacity'],
      capabilityIds: const ['authoring.gameData.pokemon'],
      requiredPermissions: const [AuthoringPermission.projectWrite],
      guarantees: const [
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.atomic,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable,
      ],
      extensions: const {
        'inputSchema': {
          'type': 'object',
          'additionalProperties': false,
          'required': ['pockets'],
          'properties': {
            'pockets': {
              'type': 'object',
              'additionalProperties': {
                'type': 'object',
                'additionalProperties': false,
                'properties': {
                  'maxDistinctItems': {
                    'type': ['integer', 'null'],
                    'minimum': 1,
                    'maximum': maximumBagEntryQuantity,
                  },
                  'maxQuantityPerItem': {
                    'type': ['integer', 'null'],
                    'minimum': 1,
                    'maximum': maximumBagEntryQuantity,
                  },
                },
              },
            },
          },
        },
      },
    ),
  ];

  Future<AuthoringMutationDraft> build(AuthoringPlanningContext context) async {
    final parameters = context.request.parameters;
    if (parameters.length != 1 || !parameters.containsKey('pockets')) {
      throw const BagCapacityAuthoringException(
        'bag.capacity.parameters_invalid',
        'Only the complete pockets map is required.',
      );
    }
    late final ProjectBagCapacity capacity;
    try {
      capacity = ProjectBagCapacity.fromJson({
        'pockets': parameters['pockets'],
      });
    } on FormatException catch (error) {
      throw BagCapacityAuthoringException(
        'bag.capacity.profile_invalid',
        error.message,
      );
    }
    final snapshot = context.snapshot;
    final before = snapshot.manifest.bagCapacity;
    if (before == capacity) {
      throw const BagCapacityAuthoringException(
        'bag.capacity.no_change',
        'Bag capacity is already current.',
      );
    }
    final projected = snapshot.manifest.copyWith(bagCapacity: capacity);
    ProjectValidator.validate(projected);
    final catalog = snapshot.itemCatalog ?? await _catalog(snapshot, capacity);
    final issues = validateBagCapacity(
      bag: Bag(entries: projected.newGame.initialBag),
      capacity: capacity,
      itemCatalog: catalog,
      path: r'$.newGame.initialBag',
    );
    if (issues.isNotEmpty) {
      throw BagCapacityAuthoringException(
        issues.first.code,
        issues.first.message,
      );
    }
    final project = AuthoringResourceRef(
      kind: 'project',
      id: 'project',
      revision: snapshot.resourceFingerprints['project'],
    );
    return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet(
        changes: [
          AuthoringResourceChange(
            resource: project,
            storageKey: 'project.json',
            beforeBytes: snapshot.resourceBytes('project'),
            afterBytes: encodeProjectAuthoringDocument(snapshot, projected),
          ),
        ],
        diff: AuthoringDiff([
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.replace,
            resource: project,
            path: '/bagCapacity',
            before: before.toJson(),
            after: capacity.toJson(),
          ),
        ]),
      ),
      preview: capacity.toJson(),
    );
  }

  Future<ProjectItemCatalog?> _catalog(
    ProjectSnapshot snapshot,
    ProjectBagCapacity capacity,
  ) async {
    if (capacity.isUnlimited || snapshot.manifest.newGame.initialBag.isEmpty) {
      return null;
    }
    final bytes = await snapshot.readResourceBytes(itemCatalogResourceIdentity);
    if (bytes == null) return null;
    try {
      return decodeProjectItemCatalog(jsonDecode(utf8.decode(bytes)));
    } on FormatException {
      throw const BagCapacityAuthoringException(
        'bag.capacity.item_catalog_invalid',
        'The item catalog cannot validate the initial bag.',
      );
    }
  }
}
