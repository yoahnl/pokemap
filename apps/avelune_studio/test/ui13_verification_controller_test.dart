import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/verification/application/verification_workspace_controller.dart';
import 'package:avelune_studio/features/world/application/world_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'support/ui13_verification_harness.dart';

Future<Map<String, int>> footprint(Directory directory) async {
  final sizes = <String, int>{};
  await for (final entity in directory.list(recursive: true)) {
    if (entity is File) {
      sizes[entity.path] = (await entity.readAsBytes()).fold(
        0,
        (sum, byte) => sum * 31 + byte & 0x7fffffff,
      );
    }
  }
  return sizes;
}

void main() {
  test('opening, filtering and selecting never run a control', () async {
    final h = await Ui13VerificationHarness.create();
    addTearDown(h.dispose);
    expect(h.verification.phase, VerificationPhase.idle);
    expect(h.verification.report, isNull);
    expect(h.verification.visible, isEmpty);
    h.verification
      ..setSearch('train')
      ..toggleSeverity(NarrativeProjectDiagnosticSeverity.error)
      ..select('rien');
    expect(
      h.verification.report,
      isNull,
      reason: 'no report must appear without an explicit launch',
    );
    expect(h.verification.phase, VerificationPhase.idle);
  });

  test('the report matches the canonical function on the same input', () async {
    final h = await Ui13VerificationHarness.create();
    addTearDown(h.dispose);
    expect(await h.verification.run(), isTrue, reason: h.verification.error);
    final report = h.verification.report!;
    final maps = await h.port.loadMaps();
    final canonical = validateNarrativeProject(
      h.narrative.project.copyWith(
        facts: h.narrative.facts,
        storylines: h.narrative.stories,
        worldRules: h.world.rules,
      ),
      maps: maps,
    );
    expect(
      report.diagnostics.map((item) => item.stableKey).toSet(),
      canonical.diagnostics.map((item) => item.stableKey).toSet(),
      reason: 'the page shows the canonical verdict, not its own rules',
    );
    expect(report.project.errorCount, canonical.errorCount);
  });

  test('the four dimensions stay distinct and none is invented', () async {
    final h = await Ui13VerificationHarness.create();
    addTearDown(h.dispose);
    expect(await h.verification.run(), isTrue, reason: h.verification.error);
    final dimensions = h.verification.report!.dimensions;
    expect(dimensions.structurallyValid.status, NarrativeValidationStatus.fail);
    expect(
      dimensions.runtimeSmokeVerified.status,
      NarrativeValidationStatus.notRun,
      reason: 'no receipt exists, so the runtime dimension is not a success',
    );
    expect(dimensions.isPlayable, isFalse);
    expect(dimensions.overallStatus, NarrativeValidationStatus.fail);
    expect(
      dimensions.runtimeSmokeVerified.limitations.single,
      contains('Aucune preuve d’exécution'),
    );
  });

  test('a second launch while one runs is ignored, not queued', () async {
    final h = await Ui13VerificationHarness.create();
    addTearDown(h.dispose);
    final first = h.verification.run();
    final second = h.verification.run();
    expect(await second, isFalse, reason: 'a double click starts one control');
    expect(await first, isTrue, reason: h.verification.error);
    expect(h.verification.report, isNotNull);
  });

  test('an incomplete rule draft is listed apart, never analysed', () async {
    final h = await Ui13VerificationHarness.create();
    addTearDown(h.dispose);
    await h.world.initialize();
    final ruleId = h.world.createRule(
      factId: Ui13VerificationHarness.knownFactId,
    );
    h.world.editRule(ruleId, (draft) => draft.label = 'Règle inachevée');
    expect(await h.verification.run(), isTrue, reason: h.verification.error);
    final report = h.verification.report!;
    expect(report.blockers.single.label, 'Règle inachevée');
    expect(report.blockers.single.missing, contains('la cible'));
    expect(
      report.diagnostics.any((item) => item.worldRuleId == ruleId),
      isFalse,
      reason: 'an unfinished draft is no definition and reaches no validator',
    );
    expect(h.world.pendingRules, contains(ruleId));
  });

  test('a change without new documents makes the report stale', () async {
    final h = await Ui13VerificationHarness.create();
    addTearDown(h.dispose);
    await h.world.initialize();
    expect(await h.verification.run(), isTrue, reason: h.verification.error);
    expect(h.verification.stale, isFalse);
    final fact = h.world.fact(Ui13VerificationHarness.knownFactId)!;
    h.world.editFact(
      NarrativeFactDefinition(
        id: fact.id,
        label: fact.label,
        description: 'Contenu modifié sans changer un seul identifiant.',
        initialValue: fact.initialValue,
      ),
    );
    expect(
      h.verification.stale,
      isTrue,
      reason: 'same count, same ids, different content: the report is old',
    );
  });

  test('a filter never turns a failing report into a valid project', () async {
    final h = await Ui13VerificationHarness.create();
    addTearDown(h.dispose);
    expect(await h.verification.run(), isTrue, reason: h.verification.error);
    h.verification.setSearch('aucune chaîne ne correspond à ceci');
    expect(h.verification.visible, isEmpty);
    expect(
      h.verification.report!.project.errorCount,
      greaterThan(0),
      reason: 'the empty list is the filter’s zero, not the project’s',
    );
    expect(h.verification.report!.project.isPlayable, isFalse);
  });

  test('a hidden selection is announced, and keeps its own target', () async {
    final h = await Ui13VerificationHarness.create();
    addTearDown(h.dispose);
    expect(await h.verification.run(), isTrue, reason: h.verification.error);
    final chosen = h.verification.report!.diagnostics.firstWhere(
      (item) => item.domain == NarrativeProjectDiagnosticDomain.worldRule,
    );
    h.verification.select(chosen.stableKey);
    expect(h.verification.selectionHidden, isFalse);
    h.verification.toggleDomain(NarrativeProjectDiagnosticDomain.storyline);
    expect(h.verification.selectionHidden, isTrue);
    expect(
      h.verification.selected?.stableKey,
      chosen.stableKey,
      reason: 'the action must keep aiming at the element it named',
    );
  });

  test('a full consultation writes nothing on disk', () async {
    final h = await Ui13VerificationHarness.create();
    addTearDown(h.dispose);
    final before = await footprint(h.directory);
    expect(await h.verification.run(), isTrue, reason: h.verification.error);
    for (final item in h.verification.report!.diagnostics) {
      h.verification.select(item.stableKey);
      h.verification.graph;
    }
    h.verification
      ..setSearch('train')
      ..toggleSeverity(NarrativeProjectDiagnosticSeverity.error)
      ..clearFilters();
    expect(await footprint(h.directory), before);
  });

  test('a correction made in its editor changes the next report', () async {
    final h = await Ui13VerificationHarness.create();
    addTearDown(h.dispose);
    await h.world.initialize();
    expect(await h.verification.run(), isTrue, reason: h.verification.error);
    bool orphanPresent() => h.verification.report!.diagnostics.any(
      (item) =>
          item.code == 'worldRuleSourceUnknown' &&
          item.worldRuleId == Ui13VerificationHarness.orphanRuleId,
    );
    expect(orphanPresent(), isTrue);

    final map = h.world.maps.firstWhere((item) => item.entities.isNotEmpty);
    final entity = map.entities.first;
    h.world.editRule(Ui13VerificationHarness.orphanRuleId, (draft) {
      draft.source = WorldRuleSource.factValue(
        factId: Ui13VerificationHarness.knownFactId,
        operator: NarrativeFactOperator.equals,
        expectedValue: const NarrativeValue.boolean(true),
      );
      draft.target = WorldRuleTarget(
        kind: WorldRuleTargetKind.mapEntity,
        mapId: map.id,
        entityId: entity.id,
        label: entity.id,
      );
    });
    expect(
      await h.world.saveRule(Ui13VerificationHarness.orphanRuleId),
      isTrue,
      reason: h.world.error ?? '',
    );
    expect(h.verification.stale, isTrue);
    expect(
      orphanPresent(),
      isTrue,
      reason: 'the old report is a snapshot, silently recomputing it would lie',
    );

    expect(await h.verification.run(), isTrue, reason: h.verification.error);
    expect(orphanPresent(), isFalse);

    final reopened = await Ui13VerificationHarness.open(h.directory);
    addTearDown(() => reopened.dispose(deleteDirectory: false));
    expect(
      reopened.world.project.worldRules
          .firstWhere((rule) => rule.id == Ui13VerificationHarness.orphanRuleId)
          .source
          .sourceId,
      Ui13VerificationHarness.knownFactId,
      reason: 'the correction was really written, not only shown',
    );
  });

  test('a report of another project never replaces the current one', () async {
    final first = await Ui13VerificationHarness.create();
    addTearDown(first.dispose);
    expect(await first.verification.run(), isTrue);
    final held = first.verification.report;
    final other = await Ui13VerificationHarness.create(seedProblems: false);
    addTearDown(other.dispose);
    expect(await other.verification.run(), isTrue);
    expect(
      other.verification.report!.inputFingerprint,
      isNot(held!.inputFingerprint),
    );
    expect(
      other.verification.report!.project.errorCount,
      0,
      reason: 'a clean project must not inherit the faults of another',
    );
  });

  test('the report carries its own identity and scope', () async {
    final h = await Ui13VerificationHarness.create();
    addTearDown(h.dispose);
    expect(await h.verification.run(), isTrue, reason: h.verification.error);
    final report = h.verification.report!;
    expect(report.validatorVersion, 'narrative-validator-v1');
    expect(report.inputFingerprint, startsWith('sha256:'));
    expect(report.generatedAt.isAfter(DateTime(2020)), isTrue);
    expect(report.scope, contains('2 carte(s) analysée(s)'));
    expect(
      report.limitations.any(
        (item) => item.contains('Catalogues Pokémon non contrôlés'),
      ),
      isTrue,
      reason: 'an unread catalogue is named, never replaced by an empty set',
    );
    expect(jsonEncode(report.dimensions.toJson()), contains('notRun'));
  });
}
