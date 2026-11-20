import '../application/map_mutation_dispatcher.dart';
import '../contracts/artifact_ref.dart';
import '../contracts/authoring_receipt.dart';
import 'full_authoring_parity.dart';
import 'transport_certification_inputs.dart';
import 'transport_certification_scenario.dart';

final class VerifiedAuthoringTransportEvidence {
  VerifiedAuthoringTransportEvidence._(
    this.sourceRevision,
    this.sourceDigest,
    Iterable<AuthoringTransportExecutionReceipt> receipts,
  ) : receipts = List.unmodifiable(receipts);

  final String sourceRevision;
  final String sourceDigest;
  final List<AuthoringTransportExecutionReceipt> receipts;

  static VerifiedAuthoringTransportEvidence verify(
    Object? bundle, {
    required Object? recipes,
    required AuthoringTransportEvidenceInputs expected,
  }) {
    final envelope = transportEvidenceObject(bundle, 'evidence bundle');
    transportEvidenceFields(envelope, const {'bundleDigest', 'payload'});
    final payload =
        transportEvidenceObject(envelope['payload'], 'evidence payload');
    transportEvidenceFields(payload, const {
      'schemaVersion',
      'recipeDigest',
      'inputs',
      'results',
    });
    final digest = transportEvidenceDigest(payload);
    final recipeDigest = transportEvidenceDigest(recipes);
    if (envelope['bundleDigest'] != digest || payload['schemaVersion'] != 2) {
      throw const FormatException(
          'Transport evidence checksum or version differs.');
    }
    if (payload['recipeDigest'] != recipeDigest) {
      throw const FormatException('Transport evidence recipe digest differs.');
    }
    final boundInputs =
        transportEvidenceObject(payload['inputs'], 'input bindings');
    final expectedInputs = expected.toJson();
    transportEvidenceFields(boundInputs, expectedInputs.keys.toSet());
    final differentInputs = expectedInputs.keys.where((field) =>
        transportEvidenceDigest(boundInputs[field]) !=
        transportEvidenceDigest(expectedInputs[field]));
    if (differentInputs.isNotEmpty) {
      throw FormatException(
          'Transport input bindings differ: ${differentInputs.join(', ')}.');
    }

    final scenarios = {
      for (final scenario in AuthoringTransportScenario.parse(recipes))
        scenario.id: scenario,
    };
    final canonicalVersions = {
      for (final action in AuthoringMutationDispatcher.canonical().descriptors)
        action.id: action.version,
    };
    final receiptIds = <String>{};
    final trials = <(String, int), Map<AuthoringTransport, _VerifiedRow>>{};
    for (final element
        in transportEvidenceList(payload['results'], 'results')) {
      final json = transportEvidenceObject(element, 'evidence row');
      transportEvidenceFields(json, const {
        'scenario',
        'step',
        'transport',
        'receipt',
        'before',
        'after',
      }, optional: const {
        'stagedArtifacts',
        'beforeProjectDigest',
        'afterProjectDigest',
      });
      final scenario = scenarios[json['scenario']];
      final index = json['step'];
      if (scenario == null ||
          index is! int ||
          index < 0 ||
          index >= scenario.steps.length) {
        throw const FormatException(
            'Evidence refers to an unknown scenario step.');
      }
      final step = scenario.steps[index];
      final transport =
          AuthoringTransport.values.asNameMap()[json['transport']];
      final receipt = AuthoringReceipt.fromJson(
        transportEvidenceObject(json['receipt'], 'applied receipt'),
      );
      final status = step.planOnly
          ? AuthoringReceiptStatus.planned
          : AuthoringReceiptStatus.applied;
      if (transport == null ||
          canonicalVersions[step.actionId] != step.actionVersion ||
          receipt.actionId != step.actionId ||
          receipt.actionVersion != step.actionVersion ||
          receipt.requestId !=
              authoringTransportProofIdentity(
                scenario.id,
                index,
                transport,
                inputs: expected,
                recipeDigest: recipeDigest,
              ) ||
          receipt.status != status ||
          receipt.beforeRevision == null ||
          (!step.planOnly &&
              (receipt.afterRevision == null ||
                  receipt.beforeRevision == receipt.afterRevision)) ||
          receipt.diff.entries.isEmpty ||
          !receiptIds.add(receipt.receiptId)) {
        throw FormatException(
            'Invalid ${status.name} receipt for ${step.actionId}.');
      }
      if (step.planOnly) {
        final before = json['beforeProjectDigest'];
        if (!isTransportEvidenceDigest(before) ||
            before != json['afterProjectDigest']) {
          throw FormatException(
              'Planning did not preserve project bytes for ${step.actionId}.');
        }
      } else if (json.containsKey('beforeProjectDigest') ||
          json.containsKey('afterProjectDigest')) {
        throw FormatException(
            'Unexpected planning evidence for ${step.actionId}.');
      }
      final artifacts =
          expected.fixtureArtifacts['${scenario.id}/$index'] ?? const [];
      final staged = json.containsKey('stagedArtifacts')
          ? [
              for (final value in transportEvidenceList(
                  json['stagedArtifacts'], 'staged artifacts'))
                ContentArtifactRef.fromJson(
                    transportEvidenceObject(value, 'staged artifact')),
            ]
          : const <ContentArtifactRef>[];
      if (staged.length != artifacts.length ||
          staged.indexed.any((member) => artifacts[member.$1] != member.$2)) {
        throw FormatException(
            'The staged artifact differs from the fixture for ${step.actionId}.');
      }
      final before =
          transportEvidenceList(json['before'], 'before observations');
      final after = transportEvidenceList(json['after'], 'after observations');
      step.verify(before, after);
      final group = trials.putIfAbsent((scenario.id, index), () => {});
      if (group.containsKey(transport)) {
        throw FormatException(
            'Duplicate transport: ${scenario.id}/$index/$transport.');
      }
      group[transport] = _VerifiedRow(
        receipt,
        transportEvidenceDigest(before),
        transportEvidenceDigest(after),
        step.planOnly
            ? transportEvidenceDigest(_previewProjection(receipt.diff.toJson()))
            : null,
      );
    }

    final receipts = <AuthoringTransportExecutionReceipt>[];
    final selectedActions = <String>{};
    for (final entry in trials.entries) {
      final (scenarioId, index) = entry.key;
      final group = entry.value;
      if (group.length != AuthoringTransport.values.length ||
          (index > 0 && !trials.containsKey((scenarioId, index - 1))) ||
          group.values.map((row) => row.beforeDigest).toSet().length != 1 ||
          group.values.map((row) => row.afterDigest).toSet().length != 1 ||
          group.values.map((row) => row.planDigest).toSet().length != 1) {
        throw FormatException('Transport state differs: $scenarioId/$index.');
      }
      final scenario = scenarios[scenarioId]!;
      final step = scenario.steps[index];
      if (!selectedActions.add(step.actionId)) continue;
      for (final member in group.entries) {
        final transport = member.key;
        final observed = member.value;
        receipts.add(AuthoringTransportExecutionReceipt(
          receiptId: '${step.actionId}@${transport.name}',
          actionId: step.actionId,
          transport: transport,
          sourceRevision: expected.sourceRevision,
          evidenceRevision: digest,
          fixtureDigest: expected.fixtureDigests[scenarioId]!,
          executorDigest: expected.executorDigests[transport]!,
          observedReceiptSha256:
              transportEvidenceDigest(observed.receipt.toJson()),
          semanticStateDigest: observed.afterDigest,
          evidencePath: 'tools/pokemap_product_certification/bin/'
              'certify_authoring_transports.dart#$scenarioId/$index',
        ));
      }
    }
    return VerifiedAuthoringTransportEvidence._(
      expected.sourceRevision,
      expected.sourceDigest,
      receipts,
    );
  }
}

Map<String, Object?> buildAuthoringTransportEvidenceBundle({
  required Object? recipes,
  required AuthoringTransportEvidenceInputs inputs,
  required List<Map<String, Object?>> results,
}) {
  final payload = {
    'schemaVersion': 2,
    'recipeDigest': transportEvidenceDigest(recipes),
    'inputs': inputs.toJson(),
    'results': results,
  };
  return {'bundleDigest': transportEvidenceDigest(payload), 'payload': payload};
}

String authoringTransportProofIdentity(
  String scenarioId,
  int index,
  AuthoringTransport transport, {
  required AuthoringTransportEvidenceInputs inputs,
  required String recipeDigest,
}) {
  final binding = transportEvidenceDigest({
    'scenario': scenarioId,
    'step': index,
    'sourceRevision': inputs.sourceRevision,
    'sourceDigest': inputs.sourceDigest,
    'fixtureDigest': inputs.fixtureDigests[scenarioId],
    'executorDigest': inputs.executorDigests[transport],
    'recipeDigest': recipeDigest,
  });
  return 'pmcp085-$scenarioId-$index-${transport.name}-${binding.substring(7, 31)}';
}

final class _VerifiedRow {
  const _VerifiedRow(
      this.receipt, this.beforeDigest, this.afterDigest, this.planDigest);

  final AuthoringReceipt receipt;
  final String beforeDigest;
  final String afterDigest;
  final String? planDigest;
}

Object? _previewProjection(Object? value) => switch (value) {
      double number
          when number.abs() <= 9007199254740991 &&
              number == number.truncateToDouble() =>
        number.toInt(),
      List<Object?> values => [
          for (final item in values) _previewProjection(item)
        ],
      Map<String, Object?> values => {
          for (final entry in values.entries)
            entry.key: _previewProjection(entry.value),
        },
      _ => value,
    };
