import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/design_system/pokemap_button.dart';

import '../shell_chrome_test_harness.dart';

void main() {
  testWidgets('canvas displays the current project profile in read-only mode',
      (tester) async {
    const profile = ProjectPresentationProfile(
      branding: ProjectBrandingProfile(accentColor: 'purple'),
    );
    final project = buildShellChromeProject(
      name: 'Personalized project',
    ).copyWith(presentation: profile);

    await pumpEditorCanvasHostHarness(
      tester,
      initialState: EditorState(
        projectRootPath: '/tmp/personalization-studio-project',
        project: project,
        workspaceMode: EditorWorkspaceMode.personalizationStudio,
      ),
      surfaceSize: const Size(1200, 800),
    );

    expect(
      find.byKey(const Key('personalization-studio-workspace')),
      findsOneWidget,
    );
    expect(find.byType(PersonalizationHubShell), findsOneWidget);
    expect(
      find.text('Use a hexadecimal color such as #6750A4.'),
      findsOneWidget,
    );

    final reset = tester.widget<PokeMapButton>(
      find.byKey(
        const ValueKey<String>('personalization-reset-branding'),
      ),
    );
    expect(reset.onPressed, isNull);
  });

  testWidgets('shows a dedicated state when no project is open',
      (tester) async {
    await pumpEditorCanvasHostHarness(
      tester,
      initialState: const EditorState(
        workspaceMode: EditorWorkspaceMode.personalizationStudio,
      ),
    );

    expect(
      find.byKey(const Key('personalization-studio-no-project')),
      findsOneWidget,
    );
    expect(find.text('Aucun projet ouvert'), findsOneWidget);
    expect(find.byType(PersonalizationHubShell), findsNothing);
  });

  testWidgets('shows a loading state while a project path is being restored',
      (tester) async {
    await pumpEditorCanvasHostHarness(
      tester,
      initialState: const EditorState(
        projectRootPath: '/tmp/project-being-restored',
        workspaceMode: EditorWorkspaceMode.personalizationStudio,
      ),
    );

    expect(
      find.byKey(const Key('personalization-studio-loading')),
      findsOneWidget,
    );
    expect(find.text('Chargement du projet…'), findsOneWidget);
    expect(find.byType(PersonalizationHubShell), findsNothing);
  });

  testWidgets('shows the project loading error instead of an empty hub',
      (tester) async {
    await pumpEditorCanvasHostHarness(
      tester,
      initialState: const EditorState(
        workspaceMode: EditorWorkspaceMode.personalizationStudio,
        errorMessage: 'Manifest illisible',
      ),
    );

    expect(
      find.byKey(const Key('personalization-studio-error')),
      findsOneWidget,
    );
    expect(find.text('Manifest illisible'), findsOneWidget);
    expect(find.byType(PersonalizationHubShell), findsNothing);
  });
}
