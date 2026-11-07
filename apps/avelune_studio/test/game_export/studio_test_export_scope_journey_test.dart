import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/project_settings/application/project_settings_session_controller.dart';
import 'package:avelune_studio/features/project_settings/application/project_verification_overview.dart';
import 'package:avelune_studio/features/verification/application/studio_failure_diagnosis.dart';
import 'package:avelune_studio/features/verification/application/test_launch_preflight.dart';
import 'package:avelune_studio/presentation/features/project_settings/project_verification_panel.dart';
import 'package:avelune_studio/presentation/features/verification/studio_failure_report.dart';
import 'package:avelune_studio/presentation/features/map_workspace/workspace_actions.dart';
import 'package:avelune_studio/presentation/features/verification/test_launch_dialog.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  test('the preflight separates saved drafts, blockers and the test scope', () {
    final map = TestLaunchPreflight(
      scope: TestLaunchScope.map,
      mapName: 'Bourg Geon',
      saves: const ['Carte « Bourg Geon »', 'Ambiance de la carte'],
      blockers: const [],
    );
    expect(map.canLaunch, isTrue);
    expect(map.title, 'Tester cette carte');
    expect(map.scopeNote, contains('en mémoire'));
    final game = TestLaunchPreflight(
      scope: TestLaunchScope.game,
      mapName: 'Bourg Geon',
      saves: const [],
      blockers: const [TestLaunchBlocker('Dialogues', 'Histoire › Dialogues')],
    );
    expect(game.canLaunch, isFalse);
    expect(game.title, 'Tester le jeu');
    expect(game.scopeNote, contains('joueurs ne sont pas touchées'));
  });

  testWidgets(
    'a blocking draft disables the launch and names where to resolve it',
    (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async => result = await showTestLaunchDialog(
                    context,
                    TestLaunchPreflight(
                      scope: TestLaunchScope.game,
                      mapName: 'Bourg Geon',
                      saves: const ['Scènes'],
                      blockers: const [
                        TestLaunchBlocker('Dialogues', 'Histoire › Dialogues'),
                      ],
                    ),
                  ),
                  child: const Text('ouvrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      expect(find.text('Tester le jeu'), findsOneWidget);
      expect(find.textContaining('Histoire › Dialogues'), findsOneWidget);
      expect(find.textContaining('Scènes'), findsOneWidget);
      final confirm = tester.widget<ButtonStyleButton>(
        find.descendant(
          of: find.byKey(const ValueKey('confirm-reviewed-plan')),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        ),
      );
      expect(confirm.onPressed, isNull);
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    },
  );

  testWidgets(
    'the map test saves its drafts only after confirmation and returns without reloading',
    (tester) async {
      final port = WorkspaceMemoryPort();
      final controller = MapWorkspaceController(workspaceSession, port);
      addTearDown(controller.dispose);
      await controller.initialize();
      final document = controller.active!;
      document.commit(document.current.copyWith(name: 'Clairière modifiée'));
      TestLaunchPreflight? reviewed;
      var confirm = false;
      var launches = 0;
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Builder(
            builder: (value) {
              context = value;
              return const Scaffold(body: SizedBox());
            },
          ),
        ),
      );
      final actions = WorkspaceActions(
        controller: controller,
        context: () => context,
        mounted: () => true,
        changed: () {},
        resources: () => null,
        narrative: () => null,
        confirmLaunch: (preflight) async {
          reviewed = preflight;
          return confirm;
        },
        runtimeBuilder: (entry, revision, close) {
          launches++;
          WidgetsBinding.instance.addPostFrameCallback((_) => close());
          return const SizedBox();
        },
      );
      await actions.test();
      expect(reviewed!.scope, TestLaunchScope.map);
      expect(reviewed!.saves, contains('Carte « Clairière »'));
      expect(port.writes, 0);
      expect(launches, 0);
      expect(document.dirty, isTrue);
      final catalogs = port.catalogs;
      confirm = true;
      final running = actions.test();
      await tester.pumpAndSettle();
      await running;
      expect(port.writes, 1);
      expect(launches, 1);
      expect(identical(controller.active, document), isTrue);
      expect(port.catalogs, catalogs);
      expect(actions.testing, isFalse);
    },
  );

  test('known export failures name their family and owner', () {
    StudioFailureDiagnosis of(String code, {String? path}) =>
        diagnoseExportFailure(code: code, summary: code, path: path);
    expect(of('invalidGameVersion').family, StudioCheckFamily.input);
    expect(of('invalidGameVersion').owner, StudioFailureOwner.general);
    expect(of('resource_library.invalid').family, StudioCheckFamily.resources);
    expect(
      of('regional_map.image_invalid').owner,
      StudioFailureOwner.regionalMap,
    );
    expect(
      of('runtime3d.publication_unsupported').family,
      StudioCheckFamily.runtimeCapabilities,
    );
    expect(
      of('runtime3d.publication_unsupported').owner,
      StudioFailureOwner.exportMode,
    );
    expect(of('exportWriteFailed').owner, StudioFailureOwner.exportDestination);
    expect(
      of('missingProjectFile', path: 'assets/a.png').owner,
      StudioFailureOwner.resources,
    );
    expect(of('missingProjectFile', path: 'scenes/a.json').owner, isNull);
    final readiness = diagnoseExportFailure(
      code: 'gameplayReadinessFailed',
      summary: 'Pas jouable',
      readinessCodes: const ['exportNewGameStartSpawnRequired'],
    );
    expect(readiness.family, StudioCheckFamily.launch);
    expect(readiness.owner, StudioFailureOwner.map);
    final mixed = diagnoseExportFailure(
      code: 'gameplayReadinessFailed',
      summary: 'Pas jouable',
      readinessCodes: const [
        'exportNewGameStartSpawnRequired',
        'exportStoryEndUnreachable',
      ],
    );
    expect(mixed.family, StudioCheckFamily.launch);
    expect(mixed.owner, isNull);
    final unknown = of('somethingNew');
    expect(unknown.determined, isFalse);
    expect(unknown.owner, isNull);
    expect(unknown.detail, 'somethingNew');
  });

  test('a launch failure is owned only when its cause is typed', () {
    final known = diagnoseLaunchFailure(
      const StudioLaunchProblem('Aucune case', owner: StudioFailureOwner.map),
    );
    expect(known.family, StudioCheckFamily.launch);
    expect(known.owner, StudioFailureOwner.map);
    final unknown = diagnoseLaunchFailure(StateError('moteur'));
    expect(unknown.determined, isFalse);
    expect(unknown.owner, isNull);
    expect(unknown.detail, contains('moteur'));
  });

  testWidgets('an undetermined cause offers no repair and keeps the detail', (
    tester,
  ) async {
    StudioFailureOwner? opened;
    Future<void> show(StudioFailureDiagnosis diagnosis) => tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: StudioFailureReport(
              diagnosis: diagnosis,
              onOpenOwner: (owner) => opened = owner,
            ),
          ),
        ),
      ),
    );
    await show(
      const StudioFailureDiagnosis(
        summary: 'Le test n’a pas pu démarrer.',
        detail: 'StateError: moteur',
      ),
    );
    expect(find.text('Cause non déterminée'), findsOneWidget);
    expect(find.textContaining('pas encore été déterminée'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('studio-failure-open-owner')),
      findsNothing,
    );
    await tester.tap(find.text('Afficher le détail technique'));
    await tester.pumpAndSettle();
    expect(find.text('StateError: moteur'), findsOneWidget);
    await show(
      const StudioFailureDiagnosis(
        family: StudioCheckFamily.resources,
        owner: StudioFailureOwner.resources,
        summary: 'Image absente.',
        detail: 'missingProjectFile · assets/a.png',
      ),
    );
    expect(find.text('Validation des ressources'), findsOneWidget);
    expect(find.text('À corriger dans : Ressources'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('studio-failure-open-owner')));
    expect(opened, StudioFailureOwner.resources);
  });

  test('the settings overview separates the five families honestly', () {
    final labels = {
      ProjectSettingsSection.general: 'Général',
      ProjectSettingsSection.image: 'Image et caméra',
      ProjectSettingsSection.sounds: 'Sons',
    };
    final rows = projectVerificationOverview(
      sectionLabels: labels,
      blocked: {ProjectSettingsSection.image},
      dirty: {ProjectSettingsSection.image, ProjectSettingsSection.sounds},
      newGame: const ProjectNewGameConfig(enabled: true, startMapId: 'gone'),
      mapNames: const {'bourg': 'Bourg Geon'},
      threeD: true,
    );
    expect([for (final row in rows) row.family], StudioCheckFamily.values);
    expect(rows[0].state, ProjectCheckState.problem);
    expect(rows[0].sections, [ProjectSettingsSection.image]);
    expect(rows[0].summary, contains('Image et caméra'));
    expect(rows[1].state, ProjectCheckState.notChecked);
    expect(rows[2].state, ProjectCheckState.limited);
    expect(rows[3].state, ProjectCheckState.problem);
    expect(rows[3].owner, StudioFailureOwner.map);
    expect(rows[3].summary, contains('introuvable'));
    expect(rows[4].state, ProjectCheckState.notChecked);
    final ready = projectVerificationOverview(
      sectionLabels: labels,
      blocked: const {},
      dirty: {ProjectSettingsSection.sounds},
      newGame: const ProjectNewGameConfig(enabled: true, startMapId: 'bourg'),
      mapNames: const {'bourg': 'Bourg Geon'},
      threeD: false,
    );
    expect(ready[0].state, ProjectCheckState.limited);
    expect(ready[0].summary, contains('Sons'));
    expect(ready[3].state, ProjectCheckState.clear);
    expect(ready[3].summary, contains('Bourg Geon'));
    final disabled = projectVerificationOverview(
      sectionLabels: labels,
      blocked: const {},
      dirty: const {},
      newGame: const ProjectNewGameConfig(),
      mapNames: const {},
      threeD: false,
    );
    expect(disabled[0].state, ProjectCheckState.clear);
    expect(disabled[3].summary, contains('désactivée'));
  });

  testWidgets('the settings overview opens an invalid section or its owner', (
    tester,
  ) async {
    ProjectSettingsSection? selected;
    StudioFailureOwner? opened;
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProjectVerificationPanel(
              rows: projectVerificationOverview(
                sectionLabels: const {
                  ProjectSettingsSection.image: 'Image et caméra',
                },
                blocked: {ProjectSettingsSection.image},
                dirty: const {},
                newGame: const ProjectNewGameConfig(enabled: true),
                mapNames: const {},
                threeD: false,
              ),
              onSelectSection: (section) => selected = section,
              onOpenOwner: (owner) => opened = owner,
            ),
          ),
        ),
      ),
    );
    expect(find.text('Erreur de saisie'), findsOneWidget);
    expect(find.text('Validation des ressources'), findsOneWidget);
    expect(find.text('Capacités du jeu'), findsOneWidget);
    expect(find.text('Lancement'), findsOneWidget);
    expect(find.text('Compatibilité des sauvegardes'), findsOneWidget);
    expect(find.text('Non vérifié ici'), findsNWidgets(3));
    await tester.tap(find.byKey(const ValueKey('project-check-open-image')));
    expect(selected, ProjectSettingsSection.image);
    await tester.tap(find.byKey(const ValueKey('project-check-owner-launch')));
    expect(opened, StudioFailureOwner.map);
  });
}
