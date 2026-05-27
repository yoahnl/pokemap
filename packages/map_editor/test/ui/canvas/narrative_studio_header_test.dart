import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/state/models/editor_workspace_mode.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio_header.dart';

void main() {
  testWidgets(
      'NarrativeStudioHeader renders overview context and honest actions',
      (tester) async {
    var overviewTapCount = 0;

    await _pumpHeader(
      tester,
      workspaceMode: EditorWorkspaceMode.narrativeOverview,
      onSelectOverview: () => overviewTapCount++,
    );

    expect(
        find.byKey(const ValueKey('narrative-studio-header')), findsOneWidget);
    expect(find.text('Narrative Studio'), findsOneWidget);
    expect(find.text('Section : Aperçu'), findsOneWidget);
    expect(find.text('Aperçu'), findsOneWidget);
    expect(find.text('Nouvelle storyline'), findsOneWidget);
    expect(find.text('Valider'), findsOneWidget);
    expect(find.text('Recherche'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Paramètres'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('narrative-studio-header-notifications-badge')),
      findsNothing,
    );

    for (final key in <String>[
      'narrative-studio-header-action-new-storyline',
      'narrative-studio-header-action-validate',
      'narrative-studio-header-action-search',
      'narrative-studio-header-action-notifications',
      'narrative-studio-header-action-settings',
    ]) {
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pump();
    }

    expect(overviewTapCount, 0);
  });

  testWidgets('NarrativeStudioHeader labels each narrative workspace mode',
      (tester) async {
    final expectations = <EditorWorkspaceMode, String>{
      EditorWorkspaceMode.narrativeOverview: 'Section : Aperçu',
      EditorWorkspaceMode.globalStory: 'Section : Storylines',
      EditorWorkspaceMode.step: 'Section : Scènes',
      EditorWorkspaceMode.cutscene: 'Section : Cinématiques',
      EditorWorkspaceMode.dialogue: 'Section : Dialogues',
    };

    for (final entry in expectations.entries) {
      await _pumpHeader(
        tester,
        workspaceMode: entry.key,
        onSelectOverview: () {},
      );
      expect(find.text('Narrative Studio'), findsOneWidget);
      expect(find.text(entry.value), findsOneWidget);
    }
  });

  testWidgets('NarrativeStudioHeader overview action returns to overview',
      (tester) async {
    var overviewTapCount = 0;

    await _pumpHeader(
      tester,
      workspaceMode: EditorWorkspaceMode.globalStory,
      onSelectOverview: () => overviewTapCount++,
    );

    await tester.tap(
      find.byKey(const ValueKey('narrative-studio-header-action-overview')),
    );
    await tester.pump();

    expect(overviewTapCount, 1);
  });
}

Future<void> _pumpHeader(
  WidgetTester tester, {
  required EditorWorkspaceMode workspaceMode,
  required VoidCallback onSelectOverview,
}) async {
  await tester.pumpWidget(
    CupertinoApp(
      home: CupertinoPageScaffold(
        child: Center(
          child: SizedBox(
            width: 1100,
            height: 180,
            child: NarrativeStudioHeader(
              workspaceMode: workspaceMode,
              onSelectOverview: onSelectOverview,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
