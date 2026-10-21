import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/narrative/application/overview/narrative_overview_read_model.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/narrative_overview_workspace.dart';
import 'package:map_editor/src/ui/canvas/new_game/project_defeat_recovery_configuration_sheet.dart';

void main() {
  ProjectManifest project({ProjectDefeatRecoveryConfig? config}) =>
      ProjectManifest(
        name: 'Retour',
        maps: const [],
        tilesets: const [],
        defeatRecovery: config,
        facts: [
          NarrativeFactDefinition(
            id: 'home-return',
            label: 'Accueil à la maison',
          ),
          NarrativeFactDefinition(
            id: 'count',
            label: 'Compteur',
            initialValue: NarrativeValue.integer(0),
          ),
        ],
      );
  Future<void> pump(
    WidgetTester tester,
    ProjectManifest value,
    Future<bool> Function(ProjectDefeatRecoveryConfig?) save,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: ProjectDefeatRecoveryConfigurationForm(
            project: value,
            onSave: save,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('opens recovery authoring from the narrative overview', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: NarrativeOverviewWorkspace(
          readModel: buildNarrativeOverviewReadModel(project: project()),
        ),
      ),
    );
    expect(find.byKey(projectDefeatRecoveryLauncherKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('guided boolean picker authors native canonical configuration', (
    tester,
  ) async {
    final original = project();
    ProjectManifest? saved;
    await pump(tester, original, (config) async {
      saved = const CampaignContentActions().updateDefeatRecovery(
        original,
        config,
      );
      return true;
    });
    await tester.tap(find.byKey(const ValueKey('defeat-recovery-fact-picker')));
    await tester.pumpAndSettle();
    expect(find.text('Compteur'), findsNothing);
    await tester.tap(find.text('Accueil à la maison').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('defeat-recovery-save')));
    await tester.pumpAndSettle();
    expect(
      saved!.defeatRecovery,
      const ProjectDefeatRecoveryConfig(recoveredFactId: 'home-return'),
    );
    expect(saved!.newGame, original.newGame);
    expect(find.text('Retour après défaite sauvegardé.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('restored configuration can be explicitly cleared', (
    tester,
  ) async {
    ProjectDefeatRecoveryConfig? saved = const ProjectDefeatRecoveryConfig(
      recoveredFactId: 'home-return',
    );
    await pump(tester, project(config: saved), (config) async {
      saved = config;
      return true;
    });
    expect(find.text('Accueil à la maison'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('defeat-recovery-fact-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aucun indicateur').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('defeat-recovery-save')));
    await tester.pumpAndSettle();
    expect(saved, isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('failed persistence never displays successful save', (
    tester,
  ) async {
    await pump(
      tester,
      project(),
      (config) async => throw StateError('Projet modifié'),
    );
    await tester.tap(find.byKey(const ValueKey('defeat-recovery-save')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Projet modifié'), findsOneWidget);
    expect(find.text('Retour après défaite sauvegardé.'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
