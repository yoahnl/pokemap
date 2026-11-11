import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_resource_placement.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_workflow.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_session_open_controller.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/presentation/features/resources/resource_workspace_pane.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'environment_scope_test.dart' show EnvironmentScopeFixture;

Future<({EnvironmentScopeFixture scope, List<bool> uses})> _open(
  WidgetTester tester,
  Size size,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final view = MapWorkspaceEditingState();
  final uses = <bool>[];
  late EnvironmentScopeFixture scope;
  scope = (await tester.runAsync(
    () => EnvironmentScopeFixture.create(
      withZones: false,
      onUse: (item) {
        useMapEnvironment(
          workspace: scope.workspace,
          resources: scope.navigation,
          preset: item.environment!,
          view: () => view,
          isActive: () => true,
          chooseMap: (_) async => null,
        ).then(uses.add);
      },
    ),
  ))!;
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(scope.dispose);
  });
  scope.navigation.library
    ..query = scope.preset.name
    ..select(scope.item)
    ..marked.add(scope.item.identity);
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: AnimatedBuilder(
          animation: scope.navigation,
          builder: (context, _) => ResourceWorkspacePane(
            navigation: scope.navigation,
            picker: () async => null,
            onBack: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (scope: scope, uses: uses);
}

Future<void> _use(WidgetTester tester, EnvironmentScopeFixture scope) async {
  await tester.tap(
    find.byKey(ValueKey('resource-card-${scope.item.identity}')),
  );
  await tester.pumpAndSettle();
  expect(find.text('Ouvrir l’atelier'), findsNothing);
  expect(
    find.byKey(const ValueKey('resource-environment-workshop-unavailable')),
    findsOneWidget,
  );
  await tester.tap(find.byKey(const ValueKey('resource-use')));
  await tester.pumpAndSettle();
}

void main() {
  for (final size in [const Size(1536, 1024), const Size(760, 620)]) {
    testWidgets(
      'retired environment routes preserve invalid drafts selection and native dirty refusal at $size',
      (tester) async {
        final host = await _open(tester, size);
        final scope = host.scope;
        final n = scope.navigation;
        final beforeFiles = await tester.runAsync(scope.files);
        final beforeProject = scope.workspace.project!.toJson();
        final history = scope.workspace.active!.undoCount;
        await _use(tester, scope);
        expect(host.uses, [true]);
        expect(scope.workspace.active!.undoCount, history + 1);
        final armedMap = scope.workspace.active!.current;
        final armedHistory = scope.workspace.active!.undoCount;
        n.openEnvironment(scope.preset);
        final draft = n.environment!..name = 'Saisie à conserver';
        draft.setWeightInput('tree', 'non');
        draft.setSpacingInput('-2');
        draft.setOffsetInput('tree', 'x', 'NaN');
        await tester.runAsync(() async {
          await expectLater(n.saveEnvironment(), throwsFormatException);
        });
        final error = n.error;
        expect(error, isNotNull);
        await tester.pumpAndSettle();
        expect(
          find.byKey(
            const ValueKey('resource-environment-workshop-unavailable-state'),
          ),
          findsOneWidget,
        );
        expect(find.text('Enregistrer l’environnement'), findsNothing);
        expect(
          find.textContaining('duplication et la suppression'),
          findsOneWidget,
        );
        final selected = n.library.selectedIdentity;
        final marked = {...n.library.marked};
        final query = n.library.query;
        await tester.tap(
          find.byKey(const ValueKey('resource-environment-return-to-catalog')),
        );
        await tester.pumpAndSettle();
        expect(n.page, ResourcePage.library);
        expect(n.library.atelierVisible, isFalse);
        expect(n.library.selectedIdentity, selected);
        expect(n.library.marked, marked);
        expect(n.library.query, query);
        expect(n.environment, same(draft));
        expect(n.environments[draft.id], same(draft));
        expect(n.error, error);
        expect(draft.name, 'Saisie à conserver');
        expect(draft.weightInput('tree'), 'non');
        expect(draft.spacingInput, '-2');
        expect(draft.offsetInput('tree', 'x'), 'NaN');
        expect(draft.build, throwsFormatException);
        expect(
          find.byKey(const ValueKey('resource-environment-draft-preserved')),
          findsOneWidget,
        );
        expect(find.text('Reprendre l’environnement'), findsNothing);

        n.library.selectFamily(ResourceLibraryFamily.environments);
        n.showLibrary();
        await tester.pumpAndSettle();
        expect(
          find.byKey(
            const ValueKey('resource-environment-library-unavailable-state'),
          ),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(
            const ValueKey('resource-environment-library-return-to-catalog'),
          ),
        );
        await tester.pumpAndSettle();
        expect(n.library.atelierVisible, isFalse);
        expect(n.environments[draft.id], same(draft));
        expect(n.error, error);
        await _use(tester, scope);
        expect(host.uses, [true, false]);
        expect(n.error, contains('Enregistrez ou annulez'));
        expect(scope.workspace.active!.current, armedMap);
        expect(scope.workspace.active!.undoCount, armedHistory);
        expect(await tester.runAsync(n.saveDrafts), isFalse);
        expect(n.environments[draft.id], same(draft));
        expect(scope.workspace.project!.toJson(), beforeProject);
        expect(await tester.runAsync(scope.files), beforeFiles);
        expect(tester.takeException(), isNull);
      },
    );
  }

  test(
    'invalid environment close refuses save retains cancel and only explicit discard permits a clean disk reopen',
    () async {
      final scope = await EnvironmentScopeFixture.create(withZones: false);
      addTearDown(scope.dispose);
      final sessions = ProjectSessionController(LocalProjectSessionAdapter());
      addTearDown(sessions.dispose);
      final root = scope.fixture.root.path;
      await sessions.open(root);
      final session = sessions.state.project!;
      final adapter = LocalMapWorkspaceAdapter();
      final workspace = MapWorkspaceController(session, adapter);
      addTearDown(() {
        if (!workspace.isDisposed) workspace.dispose();
      });
      await workspace.initialize();
      await workspace.materializeProject();
      final port = LocalResourceAdapter(session: session, mapAdapter: adapter);
      addTearDown(port.dispose);
      final navigation = ResourceNavigation(
        workspace: workspace,
        port: port,
        visuals: scope.visuals,
        onUse: (_) {},
      );
      addTearDown(() {
        if (!navigation.isDisposed) navigation.dispose();
      });
      var choice = WorkspaceCloseChoice.save;
      final decisions = <WorkspaceCloseChoice>[];
      final workflow = WorkspaceWorkflow(
        controller: workspace,
        isActive: () => !workspace.isDisposed,
        changed: () {},
        resources: () => navigation,
        narrative: () => null,
        confirmClose: () async {
          decisions.add(choice);
          return choice;
        },
        flushFocus: () {},
        launchMap: (_, _) async => fail('Closing must not launch the Player'),
      );
      final opening = ProjectSessionOpenController(
        session: sessions,
        chooseDirectory: () async => root,
        allowSwitch: () async =>
            sessions.state.project == null || await workflow.allowClose(),
      );
      addTearDown(opening.dispose);
      final beforeFiles = await scope.files();
      final beforeProject = workspace.project!.toJson();
      final beforeMap = workspace.active!.current;
      navigation.openEnvironment(scope.preset);
      final draft = navigation.environment!..name = 'Ne jamais publier';
      draft.setWeightInput('tree', 'invalide');
      expect(draft.build, throwsFormatException);
      expect(workflow.hasPendingChanges, isTrue);

      expect(await opening.close(), isFalse);
      expect(decisions, [WorkspaceCloseChoice.save]);
      expect(sessions.state.project, same(session));
      expect(navigation.environment, same(draft));
      expect(navigation.environments[draft.id], same(draft));
      expect(draft.weightInput('tree'), 'invalide');
      expect(navigation.dirty, isTrue);
      expect(navigation.busy, isFalse);
      final error = navigation.error;
      expect(error, isNotNull);
      expect(workspace.project!.toJson(), beforeProject);
      expect(workspace.active!.current, beforeMap);
      expect(await scope.files(), beforeFiles);

      choice = WorkspaceCloseChoice.cancel;
      expect(await opening.close(), isFalse);
      expect(sessions.state.project, same(session));
      expect(navigation.environment, same(draft));
      expect(navigation.environments[draft.id], same(draft));
      expect(draft.name, 'Ne jamais publier');
      expect(draft.weightInput('tree'), 'invalide');
      expect(navigation.error, error);
      expect(navigation.dirty, isTrue);
      expect(await scope.files(), beforeFiles);

      choice = WorkspaceCloseChoice.discard;
      expect(await opening.close(), isTrue);
      expect(decisions, [
        WorkspaceCloseChoice.save,
        WorkspaceCloseChoice.cancel,
        WorkspaceCloseChoice.discard,
      ]);
      expect(sessions.state.project, isNull);
      expect(navigation.environments[draft.id], same(draft));
      expect(draft.weightInput('tree'), 'invalide');
      expect(await scope.files(), beforeFiles);
      navigation.dispose();
      workspace.dispose();
      await port.dispose();

      expect(await opening.open(directoryPath: root), isTrue);
      final reopenedSession = sessions.state.project!;
      expect(reopenedSession.sessionId, isNot(session.sessionId));
      final reopenedAdapter = LocalMapWorkspaceAdapter();
      final reopened = MapWorkspaceController(reopenedSession, reopenedAdapter);
      addTearDown(reopened.dispose);
      await reopened.initialize();
      await reopened.materializeProject();
      final reopenedPort = LocalResourceAdapter(
        session: reopenedSession,
        mapAdapter: reopenedAdapter,
      );
      addTearDown(reopenedPort.dispose);
      final reopenedNavigation = ResourceNavigation(
        workspace: reopened,
        port: reopenedPort,
        visuals: scope.visuals,
        onUse: (_) {},
      );
      addTearDown(reopenedNavigation.dispose);
      expect(reopenedNavigation.environment, isNull);
      expect(reopenedNavigation.environments, isEmpty);
      expect(reopenedNavigation.dirty, isFalse);
      expect(reopenedNavigation.error, isNull);
      expect(reopened.project!.environmentPresets, [scope.preset]);
      expect(reopened.project!.toJson(), beforeProject);
      expect(reopened.active!.current, beforeMap);
      expect(await scope.files(), beforeFiles);
    },
  );

  testWidgets(
    'returning from copied and new environment routes retains both independent owners without publishing',
    (tester) async {
      final host = await _open(tester, const Size(1536, 1024));
      final scope = host.scope;
      final n = scope.navigation;
      final beforeFiles = await tester.runAsync(scope.files);
      n.duplicateEnvironment(scope.preset);
      final copied = n.environment!;
      final copyValue = copied.build();
      expect(copied.original, isNull);
      expect(copied.id, isNot(scope.preset.id));
      expect(copyValue.palette, scope.preset.palette);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('resource-environment-return-to-catalog')),
      );
      await tester.pumpAndSettle();
      n.openEnvironment();
      final empty = n.environment!;
      expect(empty.id, isNot(copied.id));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('resource-environment-return-to-catalog')),
      );
      await tester.pumpAndSettle();
      expect(n.environments, hasLength(2));
      expect(n.environments[copied.id], same(copied));
      expect(copied.build(), copyValue);
      expect(n.environments[empty.id], same(empty));
      expect(empty.build, throwsFormatException);
      expect(n.environment, same(empty));
      expect(n.library.atelierVisible, isFalse);
      expect(scope.workspace.project!.environmentPresets, [scope.preset]);
      expect(await tester.runAsync(scope.files), beforeFiles);
      expect(tester.takeException(), isNull);
    },
  );
}
