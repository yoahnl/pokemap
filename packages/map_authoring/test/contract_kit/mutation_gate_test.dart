import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  group('AuthoringMutationRegistry', () {
    test('rejects every missing mandatory contract proof', () {
      const core = {
        MutationContractProof.plan,
        MutationContractProof.dryRun,
        MutationContractProof.staleCas,
        MutationContractProof.idempotency,
        MutationContractProof.recovery,
        MutationContractProof.authorization,
        MutationContractProof.receipt,
      };
      for (final missing in core) {
        final registry = AuthoringMutationRegistry();
        expect(
          () => registry.register(
            descriptor: _descriptor('fixture.${missing.name}'),
            evidence: MutationContractEvidence(
              proofs: {
                ...core.where((proof) => proof != missing),
                MutationContractProof.undo,
              },
            ),
          ),
          _throwsGate('mutation.contract_incomplete'),
        );
      }
    });

    test('requires either undo proof or an explicit non-undoable policy', () {
      final registry = AuthoringMutationRegistry();
      expect(
        () => registry.register(
          descriptor: _descriptor('fixture.noUndoPolicy'),
          evidence: MutationContractEvidence(
            proofs: MutationContractEvidence.mandatoryCore,
          ),
        ),
        _throwsGate('mutation.undo_policy_missing'),
      );

      registry.register(
        descriptor: _descriptor('fixture.undoable'),
        evidence: MutationContractEvidence(
          proofs: {
            ...MutationContractEvidence.mandatoryCore,
            MutationContractProof.undo,
          },
        ),
      );
      registry.register(
        descriptor: _descriptor('fixture.explicitlyNonUndoable'),
        evidence: MutationContractEvidence(
          proofs: {
            ...MutationContractEvidence.mandatoryCore,
            MutationContractProof.nonUndoablePolicy,
          },
          nonUndoableReason: 'history.external_side_effect',
        ),
      );
      expect(
        registry.actions.map((action) => action.id),
        ['fixture.explicitlyNonUndoable', 'fixture.undoable'],
      );
    });

    test('dispatcher refuses a handler that did not pass admission', () {
      expect(
        () => MapMutationDispatcher([
          MapMutationActionRegistration(
            descriptor: _descriptor('fixture.dispatchWithoutUndo'),
            build: (_) => AuthoringMutationDraft(
              changeSet: _changeSet('dispatcher', 0, 1),
            ),
          ),
        ]),
        _throwsGate('mutation.undo_policy_missing'),
      );
    });
  });

  group('AuthoringBatchExecutor', () {
    test('combines non-overlapping changes deterministically', () {
      const executor = AuthoringBatchExecutor();
      final a = _changeSet('a', 0, 1);
      final b = _changeSet('b', 5, 6);

      expect(
        jsonEncode(executor.combine([a, b]).toJson()),
        jsonEncode(executor.combine([b, a]).toJson()),
      );
      expect(executor.combine([a, b]).changes, hasLength(2));
    });

    test('deduplicates identical overlap and rejects incompatible overlap', () {
      const executor = AuthoringBatchExecutor();
      final original = _changeSet('same', 0, 1);
      final identical = _changeSet('same', 0, 1);
      final conflict = _changeSet('same', 0, 2);
      final semanticConflict = AuthoringChangeSet(
        changes: original.changes,
        diff: AuthoringDiff([
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.replace,
            resource: original.changes.single.resource,
            path: r'$.otherValue',
            before: 0,
            after: 1,
          ),
        ]),
      );

      expect(executor.combine([original, identical]).changes, hasLength(1));
      expect(
        () => executor.combine([original, conflict]),
        throwsA(
          isA<AuthoringBatchException>().having(
            (error) => error.code,
            'code',
            'batch.overlap_conflict',
          ),
        ),
      );
      expect(
        () => executor.combine([original, semanticConflict]),
        throwsA(
          isA<AuthoringBatchException>().having(
            (error) => error.code,
            'code',
            'batch.overlap_conflict',
          ),
        ),
      );
    });
  });
}

AuthoringActionDescriptor _descriptor(String id) => AuthoringActionDescriptor(
      id: id,
      version: 1,
      summary: 'Mutation gate fixture',
      inputSchemaId: 'schema.fixture.input.v1',
      outputSchemaId: 'schema.fixture.output.v1',
      riskLevel: AuthoringRiskLevel.medium,
      requiredPermissions: const [AuthoringPermission.projectWrite],
      guarantees: const [
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.revisionChecked,
      ],
    );

AuthoringChangeSet _changeSet(String id, int before, int after) {
  final resource = AuthoringResourceRef(kind: 'fixture', id: id);
  return AuthoringChangeSet(
    changes: [
      AuthoringResourceChange(
        resource: resource,
        storageKey: 'data/$id.json',
        beforeBytes: utf8.encode('{"value":$before}'),
        afterBytes: utf8.encode('{"value":$after}'),
      ),
    ],
    diff: AuthoringDiff([
      AuthoringDiffEntry(
        operation: AuthoringDiffOperation.replace,
        resource: resource,
        path: r'$.value',
        before: before,
        after: after,
      ),
    ]),
  );
}

Matcher _throwsGate(String code) => throwsA(
      isA<MutationRegistryException>().having(
        (error) => error.code,
        'code',
        code,
      ),
    );
