import 'package:avelune_studio/features/project_surf/application/project_surf_controller.dart';
import 'package:avelune_studio/features/project_surf/domain/project_surf_port.dart';
import 'package:avelune_studio/presentation/features/project_settings/project_surf_panel.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_draft_field.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets(
    'Surf edits are instant drafts and references load only for conditions',
    (tester) async {
      final port = _Port();
      final owner = ProjectSurfController(
        session: workspaceSession,
        port: port,
        dimension: ProjectDimension.threeD,
      );
      addTearDown(owner.dispose);
      await owner.open();
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProjectSurfPanel(
                owner: owner,
                loadItems: () async => {'potion': 'Potion'},
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('surf-enabled')));
      await tester.pump();
      expect(owner.preview.value.enabled, isTrue);
      expect(owner.dirty, isTrue);
      expect(port.reads, 1);
      expect(port.writes, 0);
      expect(port.references, 0);
      tester
          .widget<StudioSelect>(find.byKey(const ValueKey('surf-access')))
          .onChanged!('condition');
      expect(owner.preview.value.accessMode, ProjectSurfAccessMode.condition);
      await tester.pumpAndSettle();
      expect(port.references, 1);
      tester
          .widget<StudioSelect>(
            find.byKey(const ValueKey('surf-condition-kind')),
          )
          .onChanged!('badge');
      await tester.pumpAndSettle();
      tester
          .widget<StudioSelect>(
            find.byKey(const ValueKey('surf-condition-reference')),
          )
          .onChanged!('cascade');
      await tester.pumpAndSettle();
      expect(
        owner.preview.value.condition,
        ScriptConditionFactory.badgeOwned('cascade'),
      );
      final save = find.byKey(const ValueKey('save-project-surf'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(port.writes, 1);
      expect(port.reads, 1);
      expect(owner.dirty, isFalse);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'editing a selected fact value stays local and invalid text survives panel reopening',
    (tester) async {
      final port = _Port();
      final owner = ProjectSurfController(
        session: workspaceSession,
        port: port,
        dimension: ProjectDimension.threeD,
      );
      addTearDown(owner.dispose);
      await owner.open();
      owner.change(
        accessMode: ProjectSurfAccessMode.condition,
        condition: ScriptConditionFactory.factEquals(
          'locks',
          NarrativeValue.integer(1),
        ),
      );
      Future<void> show() async {
        await tester.pumpWidget(
          MaterialApp(
            theme: studioTheme(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: ProjectSurfPanel(owner: owner),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await show();
      expect(port.factReads, 1);
      final field = find.widgetWithText(StudioDraftField, 'Valeur attendue');
      tester.widget<StudioDraftField>(field).onChanged('2');
      await tester.pumpAndSettle();
      tester.widget<StudioDraftField>(field).onChanged('3');
      await tester.pumpAndSettle();
      expect(port.factReads, 1);
      tester.widget<StudioDraftField>(field).onChanged('nope');
      await tester.pump();
      expect(await owner.save(), isFalse);
      expect(port.writes, 0);
      await tester.pumpWidget(const SizedBox());
      await show();
      expect(owner.conditionInput, 'nope');
      expect(tester.widget<StudioDraftField>(field).value, 'nope');
      owner.discard();
      await tester.pumpAndSettle();
      expect(owner.inputError, isNull);
      expect(owner.dirty, isFalse);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Surf speed stays in the draft and invalid text cannot be saved',
    (tester) async {
      final port = _Port();
      final owner = ProjectSurfController(
        session: workspaceSession,
        port: port,
        dimension: ProjectDimension.threeD,
      );
      addTearDown(owner.dispose);
      await owner.open();
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: SingleChildScrollView(child: ProjectSurfPanel(owner: owner)),
          ),
        ),
      );
      final field = find.widgetWithText(
        TextField,
        'Vitesse de Surf (cases par seconde)',
      );
      await tester.ensureVisible(field);
      await tester.enterText(field, '6.5');
      await tester.pump();
      expect(owner.preview.value.speedCellsPerSecond, 6.5);
      expect(port.writes, 0);
      expect(await owner.save(), isTrue);
      expect(owner.saved!.configuration!.speedCellsPerSecond, 6.5);
      expect(port.writes, 1);
      await tester.enterText(field, 'NaN');
      await tester.pump();
      expect(owner.preview.value.speedCellsPerSecond, 6.5);
      expect(await owner.save(), isFalse);
      expect(port.writes, 1);
      expect(tester.widget<TextField>(field).controller!.text, 'NaN');
      owner.discard();
      await tester.pump();
      expect(owner.dirty, isFalse);
      expect(tester.widget<TextField>(field).controller!.text, '6.5');
      await tester.pumpWidget(const SizedBox());
    },
  );
}

class _Port implements ProjectSurfPort {
  int reads = 0, writes = 0, references = 0, factReads = 0;
  @override
  Future<ProjectSurfState> loadSurf(session) async {
    reads++;
    return const ProjectSurfState(configuration: null, revision: '0');
  }

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
  Future<ProjectSurfReferences> loadSurfReferences(session) async {
    references++;
    return const ProjectSurfReferences(
      facts: {'locks': 'Écluses ouvertes'},
      badges: {'cascade': 'Badge Cascade'},
    );
  }

  @override
  Future<NarrativeFactDefinition> loadSurfFact(session, String id) async {
    factReads++;
    return NarrativeFactDefinition(
      id: id,
      label: 'Écluses ouvertes',
      initialValue: NarrativeValue.integer(1),
    );
  }
}
