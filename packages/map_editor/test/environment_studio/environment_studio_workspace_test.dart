import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/environment_studio/environment_preset_memory_write_kind.dart';
import 'package:map_editor/src/features/environment_studio/environment_studio_panel.dart';

void main() {
  group('EnvironmentStudioPanel', () {
    testWidgets('état vide : titre, banner actuel, pas de liste ni détail',
        (tester) async {
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
          find.text('Presets d’environnements réutilisables'), findsOneWidget);
      expect(
        find.byKey(const Key('environment-studio-info-banner')),
        findsOneWidget,
      );
      expect(
        find.text(
          'Les presets se préparent ici. La peinture et la génération se font dans l’éditeur de carte.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Lecture seule'), findsNothing);
      expect(find.textContaining('arrivent dans les prochains lots'),
          findsNothing);
      expect(find.byKey(const Key('environment-studio-empty-presets')),
          findsOneWidget);
      expect(find.text('0 presets'), findsOneWidget);
      expect(find.text(expectedDiag), findsOneWidget);
      expect(find.byKey(const Key('environment-studio-soon-bullets')),
          findsNothing);
      expect(find.byKey(const Key('environment-studio-open-draft')),
          findsOneWidget);
      expect(find.text('Nouveau preset'), findsOneWidget);
      expect(find.byKey(const Key('environment-studio-preset-list')),
          findsNothing);
      expect(find.byKey(const Key('environment-studio-detail-root')),
          findsNothing);
    });

    testWidgets('liste presets et sélection du premier par défaut', (
      tester,
    ) async {
      await _pumpPanel(
        tester,
        _manifest(
          environmentPresets: [
            _preset(id: 'meadow', name: 'Prairie', sortOrder: 0),
            _preset(id: 'forest', name: 'Forêt', sortOrder: 1),
          ],
          elements: [_element(id: 'elm')],
        ),
      );

      expect(find.text('2 presets'), findsOneWidget);
      expect(find.byKey(const Key('environment-studio-preset-list')),
          findsOneWidget);
      expect(
        find.byKey(const Key('environment-studio-empty-presets')),
        findsNothing,
      );
      expect(find.byKey(const Key('environment-studio-detail-id')),
          findsOneWidget);
      expect(find.text('meadow'), findsWidgets);
    });

    testWidgets('tap sur un autre preset met à jour le détail', (tester) async {
      await _pumpPanel(
        tester,
        _manifest(
          environmentPresets: [
            _preset(id: 'meadow', name: 'Prairie', sortOrder: 0),
            _preset(id: 'forest', name: 'Forêt', sortOrder: 1),
          ],
          elements: [_element(id: 'elm')],
        ),
      );

      expect(
        (tester.widget<Text>(
                find.byKey(const Key('environment-studio-detail-id'))))
            .data,
        'meadow',
      );

      await tester
          .tap(find.byKey(const Key('environment-studio-preset-row-forest')));
      await tester.pumpAndSettle();

      expect(
        (tester.widget<Text>(
                find.byKey(const Key('environment-studio-detail-id'))))
            .data,
        'forest',
      );
    });

    testWidgets(
        'browser : « Nouveau preset » + « Modifier en brouillon » (détail)',
        (tester) async {
      await _pumpPanel(
        tester,
        _manifest(
          environmentPresets: [_preset(id: 'x')],
          elements: [_element(id: 'elm')],
        ),
        onEnvironmentPresetSaved: (_, __, ___) {},
      );

      expect(find.text('Nouveau preset'), findsOneWidget);
      expect(find.byKey(const Key('environment-studio-edit-as-draft')),
          findsOneWidget);
    });
  });
}

Future<void> _pumpPanel(
  WidgetTester tester,
  ProjectManifest manifest, {
  void Function(
    ProjectManifest,
    EnvironmentPreset,
    EnvironmentPresetMemoryWriteKind,
  )? onEnvironmentPresetSaved,
}) async {
  await tester.pumpWidget(
    MacosApp(
      home: CupertinoPageScaffold(
        child: EnvironmentStudioPanel(
          manifest: manifest,
          onEnvironmentPresetSaved: onEnvironmentPresetSaved,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ProjectManifest _manifest({
  List<EnvironmentPreset> environmentPresets = const [],
  List<ProjectElementEntry> elements = const [],
}) {
  return ProjectManifest(
    name: 'env-shell-test',
    maps: const [],
    tilesets: const [],
    environmentPresets: environmentPresets,
    elements: elements,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

EnvironmentPreset _preset({
  required String id,
  String? name,
  int sortOrder = 0,
}) {
  return EnvironmentPreset(
    id: id,
    name: name ?? 'Preset $id',
    templateId: 'tpl',
    palette: [
      EnvironmentPaletteItem(elementId: 'elm', weight: 1),
    ],
    defaultParams: EnvironmentGenerationParams.standard(),
    sortOrder: sortOrder,
  );
}

ProjectElementEntry _element({required String id}) {
  return ProjectElementEntry(
    id: id,
    name: 'El $id',
    tilesetId: 'ts',
    categoryId: 'cat',
    frames: const [
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0),
      ),
    ],
  );
}
