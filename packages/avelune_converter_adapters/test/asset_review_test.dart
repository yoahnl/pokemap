import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

void main() {
  late AssetCandidate proposal;
  setUp(() {
    final json = jsonDecode(File(
            '../avelune_converter_core/test/fixtures/asset_candidate.example.json')
        .readAsStringSync()) as Map<String, Object?>;
    proposal = AssetCandidate.fromJson({...json, 'exampleOnly': false});
  });

  ConverterAssetReview review({
    Sha256Hash? hash,
    AssetCategory category = AssetCategory.nature,
    ReviewAction action = ReviewAction.approve,
    bool confirmed = true,
    String name = 'Arbre original',
  }) =>
      ConverterAssetReview(
          candidateId: proposal.candidateId,
          proposalHash: hash ?? proposal.canonicalHash,
          name: name,
          category: category,
          action: action,
          humanConfirmed: confirmed);

  test('review approves the exact proposal geometry and current revision', () {
    final approved = review().applyTo(proposal);
    expect(approved.name, 'Arbre original');
    expect(approved.category, AssetCategory.nature);
    expect(approved.state, CandidateState.approved);
    expect(approved.revision, proposal.revision + 1);
    expect(approved.approvedRevision, approved.revision);
    for (final key in [
      'sources',
      'parts',
      'canvasSize',
      'anchor',
      'integrationMode',
      'outputMode',
      'sourceSnapshotHash',
      'logicalProjectNamespace',
      'candidateId',
    ]) {
      expect(approved.toJson()[key], proposal.toJson()[key], reason: key);
    }
    expect(proposal.state, CandidateState.needsReview);
  });

  test('keep literal records the decision without approving a library asset',
      () {
    final kept = review(
            action: ReviewAction.keepLiteral,
            category: AssetCategory.unclassified)
        .applyTo(proposal);
    expect(kept.state, CandidateState.keepLiteral);
    expect(kept.approvedRevision, isNull);
    expect(kept.integrationMode, IntegrationMode.libraryOnly);
  });

  test('stale or foreign proposals cannot reuse a human decision', () {
    final stale = review(hash: Sha256Hash('0' * 64));
    expect(
        () => stale.applyTo(proposal),
        throwsA(isA<ConverterWorkflowFailure>().having(
            (value) => value.code, 'code', 'workflow.asset_review.stale')));
    final foreign = AssetCandidate.fromJson({
      ...proposal.toJson(),
      'candidateId': 'foreign-candidate',
    });
    expect(() => review().applyTo(foreign),
        throwsA(isA<ConverterWorkflowFailure>()));
  });

  test('review requires explicit confirmation and classification', () {
    expect(() => review(confirmed: false),
        throwsA(isA<ConverterWorkflowFailure>()));
    expect(() => review(category: AssetCategory.unclassified),
        throwsA(isA<ConverterWorkflowFailure>()));
    expect(() => review(name: '  '), throwsA(isA<ConverterWorkflowFailure>()));
    expect(() => review(action: ReviewAction.supersede),
        throwsA(isA<ConverterWorkflowFailure>()));
  });

  test('name and category changes produce a different reviewed hash', () {
    final tree = review().applyTo(proposal);
    final building = review(category: AssetCategory.building, name: 'Maison')
        .applyTo(proposal);
    expect(tree.canonicalHash, isNot(building.canonicalHash));
    expect(review().canonicalHash,
        isNot(review(category: AssetCategory.building).canonicalHash));
  });
}
