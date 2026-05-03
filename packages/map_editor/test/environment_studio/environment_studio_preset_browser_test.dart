import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/environment_studio/environment_studio_panel.dart';

void main() {
  group('EnvironmentStudioPanel — browser read-only', () {
    testWidgets('détail : id, nom, template, catégorie, tri, params, palette',
        (tester) async {
      await _pump(
        tester,
        _manifest(
          environmentPresets: [
            EnvironmentPreset(
              id: 'p1',
              name: 'Forêt test',
              templateId: 'forest_dense',
              categoryId: 'bio',
              palette: [
                EnvironmentPaletteItem(
                  elementId: 'oak',
                  weight: 5,
                  collisionMode: EnvironmentCollisionMode.forceEnabled,
                  tags: {'tree', 'canopy'},
                ),
              ],
              defaultParams: EnvironmentGenerationParams(
                density: 0.25,
                variation: 0.75,
                edgeDensity: 0.1,
                minSpacingCells: 2,
              ),
              sortOrder: 3,
            ),
          ],
          elements: [_element(id: 'oak')],
        ),
      );

      expect(find.byKey(const Key('environment-studio-detail-id')),
          findsOneWidget);
      expect(find.text('p1'), findsWidgets);
      expect(find.text('Forêt test'), findsWidgets);
      expect(find.text('forest_dense'), findsWidgets);
      expect(find.text('bio'), findsWidgets);
      expect(find.text('3'), findsWidgets);
      expect(find.text('0.25'), findsOneWidget);
      expect(find.text('0.75'), findsOneWidget);
      expect(find.text('0.10'), findsOneWidget);
      expect(find.text('2'), findsWidgets);
      expect(find.byKey(const Key('environment-studio-palette-item-oak')),
          findsOneWidget);
      expect(
        find.byKey(const Key('environment-studio-palette-item-meta-oak')),
        findsOneWidget,
      );
      expect(
        find.textContaining('Poids 5'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Collision forcée'),
        findsOneWidget,
      );
      expect(
        find.textContaining('canopy'),
        findsOneWidget,
      );
    });

    testWidgets('catégorie absente : affiche —', (tester) async {
      await _pump(
        tester,
        _manifest(
          environmentPresets: [
            EnvironmentPreset(
              id: 'solo',
              name: 'Solo',
              templateId: 'tpl',
              palette: [
                EnvironmentPaletteItem(elementId: 'e1', weight: 1),
              ],
              defaultParams: EnvironmentGenerationParams.standard(),
              sortOrder: 0,
            ),
          ],
          elements: [_element(id: 'e1')],
        ),
      );

      expect(
        (tester.widget<Text>(
                find.byKey(const Key('environment-studio-detail-category'))))
            .data,
        '—',
      );
    });

    testWidgets('diagnostics preset vides : message dédié', (tester) async {
      await _pump(
        tester,
        _manifest(
          environmentPresets: [
            EnvironmentPreset(
              id: 'ok',
              name: 'OK',
              templateId: 'tpl',
              palette: [
                EnvironmentPaletteItem(elementId: 'e1', weight: 1),
              ],
              defaultParams: EnvironmentGenerationParams.standard(),
              sortOrder: 0,
            ),
          ],
          elements: [_element(id: 'e1')],
        ),
      );

      expect(
        find.byKey(const Key('environment-studio-preset-diagnostics-empty')),
        findsOneWidget,
      );
      expect(find.text('Aucun diagnostic pour ce preset.'), findsOneWidget);
    });

    testWidgets('diagnostic erreur élément palette manquant', (tester) async {
      await _pump(
        tester,
        _manifest(
          environmentPresets: [
            EnvironmentPreset(
              id: 'bad',
              name: 'Bad',
              templateId: 'tpl',
              palette: [
                EnvironmentPaletteItem(elementId: 'missing_tree', weight: 1),
              ],
              defaultParams: EnvironmentGenerationParams.standard(),
              sortOrder: 0,
            ),
          ],
          elements: const [],
        ),
      );

      expect(
        find.byKey(const Key('environment-studio-preset-diagnostics-empty')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('environment-studio-preset-diagnostics-summary')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('environment-studio-preset-diag-line-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('environment-studio-preset-row-diag-bad')),
        findsOneWidget,
      );
    });

    testWidgets('read-only : pas de libellés Create / Edit / Delete / Generate',
        (tester) async {
      await _pump(
        tester,
        _manifest(
          environmentPresets: [
            EnvironmentPreset(
              id: 'x',
              name: 'X',
              templateId: 'tpl',
              palette: [
                EnvironmentPaletteItem(elementId: 'e1', weight: 1),
              ],
              defaultParams: EnvironmentGenerationParams.standard(),
              sortOrder: 0,
            ),
          ],
          elements: [_element(id: 'e1')],
        ),
      );

      expect(find.textContaining('Create'), findsNothing);
      expect(find.textContaining('Edit'), findsNothing);
      expect(find.textContaining('Delete'), findsNothing);
      expect(find.textContaining('Generate'), findsNothing);
    });
  });
}

Future<void> _pump(WidgetTester tester, ProjectManifest manifest) async {
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
  required List<EnvironmentPreset> environmentPresets,
  List<ProjectElementEntry> elements = const [],
}) {
  return ProjectManifest(
    name: 'browser-test',
    maps: const [],
    tilesets: const [],
    environmentPresets: environmentPresets,
    elements: elements,
    surfaceCatalog: ProjectSurfaceCatalog(),
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
