import 'dart:async';

import 'package:avelune_studio/features/project_surf/application/project_surf_controller.dart';
import 'package:avelune_studio/features/project_surf/domain/project_surf_port.dart';
import 'package:avelune_studio/presentation/features/project_settings/project_surf_panel.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_draft_field.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets(
    'choosing an empty condition source cannot save the previous condition',
    (tester) async {
      final port = _Port();
      final owner = await _open(tester, port);
      addTearDown(owner.dispose);
      tester
          .widget<StudioSelect>(
            find.byKey(const ValueKey('surf-condition-kind')),
          )
          .onChanged!('badge');
      await tester.pump();
      expect(owner.inputError, isNotNull);
      expect(owner.dirty, isTrue);
      expect(
        tester
            .widget<StudioButton>(
              find.byKey(const ValueKey('save-project-surf')),
            )
            .onPressed,
        isNull,
      );
      expect(await owner.save(), isFalse);
      expect(port.writes, 0);
      expect(owner.preview.value.condition, port.initial.condition);
      owner.discard();
      await tester.pump();
      expect(owner.dirty, isFalse);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('a non interoperable integer is a preserved draft error', (
    tester,
  ) async {
    final port = _Port();
    final owner = await _open(tester, port);
    addTearDown(owner.dispose);
    tester
        .widget<StudioDraftField>(
          find.widgetWithText(StudioDraftField, 'Valeur attendue'),
        )
        .onChanged('9007199254740992');
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(owner.conditionInput, '9007199254740992');
    expect(owner.inputError, isNotNull);
    expect(await owner.save(), isFalse);
    expect(owner.preview.value.condition, port.initial.condition);
    expect(port.writes, 0);
    await tester.pumpWidget(const SizedBox());
  });
  for (final cancellation in ['discard', 'undo', 'always']) {
    testWidgets(
      'a late fact read cannot reapply a condition after $cancellation',
      (tester) async {
        final port = _Port();
        final owner = await _open(tester, port);
        addTearDown(owner.dispose);
        tester
            .widget<StudioSelect>(
              find.byKey(const ValueKey('surf-condition-reference')),
            )
            .onChanged!('other');
        expect(owner.inputError, isNotNull);
        expect(await owner.save(), isFalse);
        if (cancellation == 'discard') owner.discard();
        if (cancellation == 'undo') owner.undo();
        if (cancellation == 'always') {
          tester
              .widget<StudioSelect>(find.byKey(const ValueKey('surf-access')))
              .onChanged!('always');
        }
        port.pending.complete(
          NarrativeFactDefinition(id: 'other', label: 'Autre état'),
        );
        await tester.pumpAndSettle();
        expect(owner.preview.value.condition, port.initial.condition);
        expect(
          owner.preview.value.accessMode,
          cancellation == 'always'
              ? ProjectSurfAccessMode.always
              : ProjectSurfAccessMode.condition,
        );
        expect(owner.inputError, isNull);
        expect(owner.dirty, cancellation == 'always');
        expect(port.writes, 0);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}

Future<ProjectSurfController> _open(WidgetTester tester, _Port port) async {
  final owner = ProjectSurfController(
    session: workspaceSession,
    port: port,
    dimension: ProjectDimension.threeD,
  );
  await owner.open();
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: SingleChildScrollView(child: ProjectSurfPanel(owner: owner)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return owner;
}

class _Port implements ProjectSurfPort {
  final pending = Completer<NarrativeFactDefinition>();
  final initial = ProjectSurfSettings(
    accessMode: ProjectSurfAccessMode.condition,
    condition: ScriptConditionFactory.factEquals(
      'locks',
      NarrativeValue.integer(1),
    ),
  );
  int writes = 0;
  @override
  Future<ProjectSurfState> loadSurf(session) async =>
      ProjectSurfState(configuration: initial, revision: '0');
  @override
  Future<ProjectSurfState> saveSurf(
    session,
    ProjectSurfSettings? configuration,
    String revision,
  ) async {
    writes++;
    return ProjectSurfState(configuration: configuration, revision: '$writes');
  }

  @override
  Future<ProjectSurfReferences> loadSurfReferences(session) async =>
      const ProjectSurfReferences(
        facts: {'locks': 'Écluses ouvertes', 'other': 'Autre état'},
      );
  @override
  Future<NarrativeFactDefinition> loadSurfFact(session, String id) async =>
      id == 'other'
      ? pending.future
      : NarrativeFactDefinition(
          id: 'locks',
          label: 'Écluses ouvertes',
          initialValue: NarrativeValue.integer(1),
        );
}
