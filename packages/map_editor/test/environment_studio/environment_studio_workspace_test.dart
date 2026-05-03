import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/environment_studio/environment_studio_panel.dart';

void main() {
  group('EnvironmentStudioPanel', () {
    testWidgets('affiche titre, description, état vide et diagnostics', (
      tester,
    ) async {
      final manifest = _manifest();
      final report = diagnoseProjectEnvironmentAuthoring(
        manifest,
        maps: const [],
      );
      final expectedDiag =
          '${report.summary.errorCount} erreur(s) · ${report.summary.warningCount} avertissement(s)';

      await _pumpPanel(tester, manifest);

      expect(find.byKey(const Key('environment-studio-title')), findsOneWidget);
      expect(find.text('Environment Studio'), findsOneWidget);
      expect(
        find.byKey(const Key('environment-studio-description')),
        findsOneWidget,
      );
      expect(
        find.textContaining('forêts, bosquets, prairies'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('environment-studio-empty-presets')),
          findsOneWidget);
      expect(find.text('0 presets'), findsOneWidget);
      expect(find.text(expectedDiag), findsOneWidget);
      expect(
        find.byKey(const Key('environment-studio-soon-bullets')),
        findsOneWidget,
      );
      expect(find.textContaining('génération organique'), findsOneWidget);
    });

    testWidgets('affiche le nombre de presets quand le manifest en définit',
        (tester) async {
      await _pumpPanel(
        tester,
        _manifest(
          environmentPresets: [
            _preset(id: 'a'),
            _preset(id: 'b'),
          ],
        ),
      );

      expect(find.text('2 presets'), findsOneWidget);
      expect(
        find.byKey(const Key('environment-studio-empty-presets')),
        findsNothing,
      );
    });

    testWidgets('ne propose aucun bouton d’action actif', (tester) async {
      await _pumpPanel(tester, _manifest());

      final panel = find.byType(EnvironmentStudioPanel);
      expect(
        find.descendant(of: panel, matching: find.byType(CupertinoButton)),
        findsNothing,
      );
    });
  });
}

Future<void> _pumpPanel(WidgetTester tester, ProjectManifest manifest) async {
  await tester.pumpWidget(
    MacosApp(
      home: CupertinoPageScaffold(
        child: EnvironmentStudioPanel(manifest: manifest),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ProjectManifest _manifest({
  List<EnvironmentPreset> environmentPresets = const [],
}) {
  return ProjectManifest(
    name: 'env-shell-test',
    maps: const [],
    tilesets: const [],
    environmentPresets: environmentPresets,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

EnvironmentPreset _preset({required String id}) {
  return EnvironmentPreset(
    id: id,
    name: 'Preset $id',
    templateId: 'tpl',
    palette: [
      EnvironmentPaletteItem(elementId: 'elm', weight: 1),
    ],
    defaultParams: EnvironmentGenerationParams.standard(),
    sortOrder: 0,
  );
}
