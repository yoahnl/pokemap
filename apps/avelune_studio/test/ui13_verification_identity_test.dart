import 'package:avelune_studio/features/verification/application/verification_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'support/ui13_verification_harness.dart';

List<NarrativeDependencyKey> named(
  VerificationReport report,
  NarrativeDependencyTargetKind kind,
  String id,
) => [
  for (final definition in report.dependencies.definitions)
    if (definition.key.kind == kind && definition.key.id == id) definition.key,
];

NarrativeProjectDiagnostic synthetic({
  required NarrativeProjectDiagnosticDomain domain,
  required NarrativeProjectDiagnosticDestination destination,
  String? factId,
  String? stepId,
}) => NarrativeProjectDiagnostic(
  code: 'identiteSynthetique',
  severity: NarrativeProjectDiagnosticSeverity.error,
  domain: domain,
  message: 'Cas d’identité.',
  path: 'identite',
  destination: destination,
  factId: factId,
  stepId: stepId,
);

/// The same report plus one diagnostic, so a synthetic identity case can be
/// selected exactly like a real one.
VerificationReport withExtra(
  VerificationReport report,
  NarrativeProjectDiagnostic extra,
) => VerificationReport(
  requestId: report.requestId,
  savedRevision: report.savedRevision,
  generatedAt: report.generatedAt,
  validatorVersion: report.validatorVersion,
  inputFingerprint: report.inputFingerprint,
  freshnessKey: report.freshnessKey,
  isolateName: report.isolateName,
  project: NarrativeProjectValidationReport(
    diagnostics: [...report.diagnostics, extra],
    mapEventViews: const [],
  ),
  dependencies: report.dependencies,
  dimensions: report.dimensions,
  runtime: report.runtime,
  scope: report.scope,
  limitations: report.limitations,
  blockers: report.blockers,
  exclusions: report.exclusions,
  labels: report.labels,
  drafted: report.drafted,
);

Future<VerificationReport> analysed(Ui13VerificationHarness h) async {
  expect(await h.verification.run(), isTrue, reason: h.verification.error);
  return h.verification.report!;
}

void main() {
  test('two entities sharing an identifier stay two documents', () async {
    final h = await Ui13VerificationHarness.create(homonyms: true);
    addTearDown(h.dispose);
    final report = await analysed(h);

    final twins = named(
      report,
      NarrativeDependencyTargetKind.sourceMap,
      'depart',
    );
    expect(
      twins,
      hasLength(2),
      reason: 'the two maps each carry an entity called depart',
    );
    expect(
      twins.map((key) => key.id).toSet(),
      hasLength(1),
      reason: 'their text identifier alone cannot tell them apart',
    );
    expect(
      twins.map(verificationKeyId).toSet(),
      hasLength(2),
      reason: 'the full canonical identity does',
    );
    expect(twins.map((key) => key.parentId).toSet(), hasLength(2));
    for (final key in twins) {
      expect(report.labels, contains(verificationKeyId(key)));
    }
  });

  test('an identifier answered by several documents is not guessed', () async {
    final h = await Ui13VerificationHarness.create(homonyms: true);
    addTearDown(h.dispose);
    final report = await analysed(h);

    final steps = named(
      report,
      NarrativeDependencyTargetKind.step,
      Ui13VerificationHarness.twinStepId,
    );
    expect(
      steps,
      hasLength(2),
      reason: 'two stories declare a step with the same local id',
    );
    expect(
      steps.map(verificationKeyId).toSet(),
      hasLength(1),
      reason: 'the index gives these two no parent, so nothing separates them',
    );

    final blind = synthetic(
      domain: NarrativeProjectDiagnosticDomain.storyline,
      destination: NarrativeProjectDiagnosticDestination.storyline,
      stepId: Ui13VerificationHarness.twinStepId,
    );
    final resolved = verificationResolve(report.dependencies, blind);
    expect(resolved.key, isNull);
    expect(
      resolved.ambiguous,
      isTrue,
      reason: 'an ambiguous target is never replaced by the first match',
    );
    expect(report.labelFor(blind), contains('plusieurs documents'));

    h.verification
      ..report = withExtra(report, blind)
      ..select(blind.stableKey);
    expect(
      h.verification.graph.title,
      contains('Cible ambiguë'),
      reason: 'the drawing says it cannot choose instead of choosing',
    );
  });

  test('a fact never resolves to an entity of the same name', () async {
    final h = await Ui13VerificationHarness.create(homonyms: true);
    addTearDown(h.dispose);
    final report = await analysed(h);
    expect(
      named(report, NarrativeDependencyTargetKind.sourceMap, 'depart'),
      isNotEmpty,
      reason: 'something called depart does exist, under another kind',
    );

    final crossed = synthetic(
      domain: NarrativeProjectDiagnosticDomain.fact,
      destination: NarrativeProjectDiagnosticDestination.fact,
      factId: 'depart',
    );
    final resolved = verificationResolve(report.dependencies, crossed);
    expect(
      resolved.key,
      isNull,
      reason: 'a missing fact stays missing next to an entity homonym',
    );
    expect(resolved.ambiguous, isFalse);
    expect(report.labelFor(crossed), 'depart');

    h.verification
      ..report = withExtra(report, crossed)
      ..select(crossed.stableKey);
    final graph = h.verification.graph;
    expect(graph.title, contains('Référence introuvable'));
    expect(
      graph.nodes.single.key.kind,
      NarrativeDependencyTargetKind.fact,
      reason: 'the missing node keeps the kind that was looked for',
    );
    expect(graph.nodes.single.missing, isTrue);
  });

  test('every identity carries its kind, scope and parent', () async {
    final h = await Ui13VerificationHarness.create(homonyms: true);
    addTearDown(h.dispose);
    final report = await analysed(h);
    for (final definition in report.dependencies.definitions) {
      final key = definition.key;
      final composite = verificationKeyId(key);
      expect(composite, startsWith(key.kind.name));
      expect(composite, contains(key.id));
      if (key.scope case final scope?) expect(composite, contains(scope));
      if (key.parentId case final parent?) expect(composite, contains(parent));
    }
  });

  test('a real diagnostic still finds its own document', () async {
    final h = await Ui13VerificationHarness.create(homonyms: true);
    addTearDown(h.dispose);
    final report = await analysed(h);
    final rule = report.diagnostics.firstWhere(
      (item) => item.worldRuleId == Ui13VerificationHarness.orphanRuleId,
    );
    final resolved = verificationResolve(report.dependencies, rule);
    expect(resolved.key?.kind, NarrativeDependencyTargetKind.worldRule);
    expect(resolved.key?.id, Ui13VerificationHarness.orphanRuleId);
    expect(report.labelFor(rule), 'Masquer le conducteur');

    h.verification.select(rule.stableKey);
    final graph = h.verification.graph;
    expect(graph.focusId, verificationKeyId(resolved.key!));
    expect(
      graph.nodes.map((node) => node.id).toSet(),
      hasLength(graph.nodes.length),
      reason: 'nodes are deduplicated by identity, not by text id',
    );
  });
}
