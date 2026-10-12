import 'dart:convert';
import 'dart:io';

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

  AssetReviewSession seed() => AssetReviewSession.create(
      sessionId: ConverterId('exact-asset-review'),
      logicalProjectNamespace: proposal.logicalProjectNamespace,
      sourceSnapshotHash: proposal.sourceSnapshotHash,
      selectedSourceMapIds: [1],
      outputMode: proposal.outputMode,
      proposalGenerationHash: Sha256Hash('c' * 64),
      candidates: [proposal]);

  AssetReviewSession review({
    Sha256Hash? hash,
    AssetCategory category = AssetCategory.nature,
    ReviewAction action = ReviewAction.approve,
    bool confirmed = true,
    String name = 'Arbre original',
  }) {
    final initial = seed();
    final named = initial.editMetadata(
        candidateId: proposal.candidateId,
        expectedCandidateHash: hash ?? proposal.canonicalHash,
        expectedSessionHash: initial.canonicalHash,
        name: name,
        category: category);
    final current = named.activeCandidates.single;
    return named.decide(
        candidateId: current.candidateId,
        expectedCandidateHash: current.canonicalHash,
        expectedSessionHash: named.canonicalHash,
        action: action,
        humanConfirmed: confirmed);
  }

  test('review approves exact geometry and records its current revision', () {
    final session = review();
    final approved = session.activeCandidates.single;
    expect(approved.name, 'Arbre original');
    expect(approved.category, AssetCategory.nature);
    expect(approved.state, CandidateState.approved);
    expect(approved.revision, proposal.revision + 2);
    expect(approved.approvedRevision, approved.revision);
    expect(session.approvedCandidateHashes,
        {approved.candidateId: approved.canonicalHash});
    expect(
        session.activeDecisions.decisions.single.action, ReviewAction.approve);
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
    final session = review(
        action: ReviewAction.keepLiteral, category: AssetCategory.unclassified);
    final kept = session.activeCandidates.single;
    expect(kept.state, CandidateState.keepLiteral);
    expect(kept.approvedRevision, isNull);
    expect(kept.integrationMode, IntegrationMode.libraryOnly);
    expect(session.approvedCandidateHashes, isEmpty);
    expect(session.activeDecisions.decisions.single.action,
        ReviewAction.keepLiteral);
  });

  test('stale or foreign proposals cannot reuse a human decision', () {
    expect(() => review(hash: Sha256Hash('0' * 64)),
        throwsA(isA<ContractError>()));
    final initial = seed();
    expect(
        () => initial.decide(
            candidateId: ConverterId('foreign-candidate'),
            expectedCandidateHash: proposal.canonicalHash,
            expectedSessionHash: initial.canonicalHash,
            action: ReviewAction.approve,
            humanConfirmed: true),
        throwsA(isA<ContractError>()));
    expect(
        () => initial.decide(
            candidateId: proposal.candidateId,
            expectedCandidateHash: proposal.canonicalHash,
            expectedSessionHash: Sha256Hash('0' * 64),
            action: ReviewAction.approve,
            humanConfirmed: true),
        throwsA(isA<ContractError>()));
  });

  test('review requires explicit confirmation and classification', () {
    expect(() => review(confirmed: false), throwsA(isA<ContractError>()));
    expect(() => review(category: AssetCategory.unclassified),
        throwsA(isA<ContractError>()));
    expect(() => review(name: '  '), throwsA(isA<ContractError>()));
    expect(() => review(action: ReviewAction.supersede),
        throwsA(isA<ContractError>()));
  });

  test(
      'name and category changes produce different candidate and session hashes',
      () {
    final tree = review();
    final building = review(category: AssetCategory.building, name: 'Maison');
    expect(tree.activeCandidates.single.canonicalHash,
        isNot(building.activeCandidates.single.canonicalHash));
    expect(tree.canonicalHash, isNot(building.canonicalHash));
    expect(tree.activeDecisions.canonicalHash,
        isNot(building.activeDecisions.canonicalHash));
  });
}
