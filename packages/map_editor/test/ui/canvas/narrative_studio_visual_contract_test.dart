import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_navigation.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_workspace_page.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';

import '../../support/narrative_studio_visual_harness.dart';

void main() {
  late Directory projectRoot;

  setUp(() async {
    projectRoot = await Directory.systemTemp.createTemp(
      'map_editor_narrative_visual_contract_',
    );
  });

  tearDown(() async {
    if (await projectRoot.exists()) {
      await projectRoot.delete(recursive: true);
    }
  });

  for (final mode in narrativeStudioRealRouteModes) {
    testWidgets(
      '${mode.name} real route owns one product shell, rail and context bar',
      (tester) async {
        final project = buildNarrativeStudioVisualProject();
        final before = project.toJson();
        final container = await pumpNarrativeStudioRealRoute(
          tester,
          mode: mode,
          project: project,
          projectRootPath: projectRoot.path,
          activeMap: narrativeStudioVisualMap,
          isProjectDirty: true,
        );

        expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
        expect(find.byType(NarrativeStudioProductNavigation), findsOneWidget);
        expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
        expect(find.byType(ProjectExplorerPanel), findsNothing);
        expect(find.text('PokeMap'), findsOneWidget);
        expect(
          find.byKey(
            const ValueKey('narrative-studio-product-nav-validator'),
          ),
          findsOneWidget,
        );
        expect(
          container.read(editorNotifierProvider).project?.toJson(),
          before,
        );
        expect(
          container.read(editorNotifierProvider).activeMap,
          narrativeStudioVisualMap,
        );
        expect(container.read(editorNotifierProvider).isProjectDirty, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final mode in narrativeStudioRealRouteModes) {
    testWidgets(
      '${mode.name} no-project route keeps one honest workspace context',
      (tester) async {
        await pumpNarrativeStudioRealRoute(
          tester,
          mode: mode,
          project: null,
          surfaceSize: const Size(1280, 768),
        );

        expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
        expect(find.byType(NarrativeStudioProductNavigation), findsOneWidget);
        expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
        expect(find.text('Aucun projet chargé'), findsOneWidget);
        expect(find.byType(ProjectExplorerPanel), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
