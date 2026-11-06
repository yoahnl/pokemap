import 'package:avelune_studio/features/home/application/home_next_steps.dart';
import 'package:avelune_studio/features/project_session/application/project_session_state.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/home/studio_home_screen.dart';
import 'package:avelune_studio/presentation/features/project_session/project_open_controls.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

const _bourg = ProjectMapEntry(
  id: 'bourg',
  name: 'Bourg Geon',
  relativePath: 'maps/bourg.json',
);

void main() {
  test('an empty project asks for a map and a start, verifies nothing', () {
    final steps = homeNextSteps(
      maps: const [],
      newGame: const ProjectNewGameConfig(),
      canTest: false,
    );
    expect([for (final step in steps) step.kind], HomeNextStepKind.values);
    expect(steps[0].status, HomeNextStepStatus.todo);
    expect(steps[0].destination, 'createMap');
    expect(steps[1].status, HomeNextStepStatus.todo);
    for (final step in steps.skip(2)) {
      expect(
        step.status,
        HomeNextStepStatus.unverified,
        reason: '${step.kind}',
      );
    }
  });

  test('map and start are done only when the manifest proves them', () {
    final steps = homeNextSteps(
      maps: const [(id: 'bourg', name: 'Bourg Geon')],
      newGame: const ProjectNewGameConfig(startMapId: 'bourg'),
      canTest: true,
    );
    expect(steps[0].status, HomeNextStepStatus.done);
    expect(steps[0].destination, 'map');
    expect(steps[1].status, HomeNextStepStatus.done);
    expect(steps[1].mapId, 'bourg');
    expect(steps[1].detail, contains('Bourg Geon'));
    expect(
      steps.where((step) => step.status == HomeNextStepStatus.done).length,
      2,
    );
    expect(steps.last.destination, 'testGame');
    expect(steps.last.unavailableReason, isNull);
  });

  test('a start pointing to a missing map is not reported as done', () {
    final steps = homeNextSteps(
      maps: const [(id: 'bourg', name: 'Bourg Geon')],
      newGame: const ProjectNewGameConfig(startMapId: 'route-perdue'),
      canTest: false,
    );
    expect(steps[1].status, HomeNextStepStatus.todo);
    expect(steps[1].detail, contains('introuvable'));
    expect(steps.last.unavailableReason, isNotNull);
  });

  test('without the project manifest the start stays unverified', () {
    final steps = homeNextSteps(
      maps: const [(id: 'bourg', name: 'Bourg Geon')],
      newGame: null,
      canTest: true,
    );
    expect(steps[0].status, HomeNextStepStatus.done);
    expect(steps[1].status, HomeNextStepStatus.unverified);
  });

  testWidgets('home shows next steps, keeps direct tools and can hide them', (
    tester,
  ) async {
    final opened = <String>[];
    await _mountHome(tester, onDestination: opened.add);
    expect(find.text('Prochaines étapes'), findsOneWidget);
    expect(find.text('Vos outils de création'), findsOneWidget);
    expect(find.text('Fait'), findsOneWidget);
    expect(find.text('Non vérifié'), findsNWidgets(3));
    await tester.ensureVisible(
      find.byKey(const ValueKey('home-next-step-start')),
    );
    await tester.tap(find.byKey(const ValueKey('home-next-step-start')));
    await tester.pump();
    expect(opened, ['map']);
    await tester.ensureVisible(
      find.byKey(const ValueKey('home-next-steps-hide')),
    );
    await tester.tap(find.byKey(const ValueKey('home-next-steps-hide')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-next-step-start')), findsNothing);
    expect(find.byKey(const ValueKey('home-next-steps-show')), findsOneWidget);
    expect(find.text('Vos outils de création'), findsOneWidget);
  });

  for (final storage in [
    ProjectSessionStorage.manifest,
    ProjectSessionStorage.workingCatalog,
  ]) {
    testWidgets('writable session $storage never claims read-only', (
      tester,
    ) async {
      await _mountControls(tester, storage);
      expect(find.textContaining('lecture seule'), findsNothing);
      expect(find.text('Projet ouvert'), findsOneWidget);
    });
  }

  testWidgets('published catalog names what is read-only and why', (
    tester,
  ) async {
    await _mountControls(tester, ProjectSessionStorage.portableCatalog);
    expect(find.textContaining('lecture seule'), findsOneWidget);
    expect(find.textContaining('projet publié'), findsOneWidget);
    expect(find.textContaining('projet de travail'), findsOneWidget);
  });
}

Future<void> _mountHome(
  WidgetTester tester, {
  required ValueChanged<String> onDestination,
}) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: StudioHomeScreen(
        projectName: 'Johto',
        onOpen: () {},
        onDestination: onDestination,
        onRecent: (_) {},
        onRemoveRecent: (_) {},
        maps: const [(id: 'bourg', name: 'Bourg Geon')],
        mapLibrary: const ProjectManifest(
          name: 'Johto',
          maps: [_bourg],
          tilesets: [],
        ),
        onMap: (_) {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _mountControls(
  WidgetTester tester,
  ProjectSessionStorage storage,
) async {
  final path = TextEditingController();
  addTearDown(path.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: ProjectOpenControls(
            path: path,
            state: ProjectSessionState(
              status: ProjectSessionStatus.ready,
              project: ProjectSession(
                sessionId: 's',
                name: 'Johto',
                directoryPath: '/tmp/johto',
                storage: storage,
              ),
            ),
            picking: false,
            onOpen: () {},
            onBrowse: () {},
            onCancel: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
