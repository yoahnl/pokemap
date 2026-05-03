import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/environment_studio/authoring/environment_preset_draft.dart';
import 'package:map_editor/src/features/environment_studio/environment_studio_panel.dart';
import 'package:map_editor/src/features/environment_studio/widgets/environment_preset_draft_presentation.dart';

void main() {
  group('environmentPresetDraftIssueKindLabel', () {
    test('libellés FR attendus (extrait)', () {
      expect(
        environmentPresetDraftIssueKindLabel(
          EnvironmentPresetDraftIssueKind.emptyId,
        ),
        'Id vide',
      );
      expect(
        environmentPresetDraftIssueKindLabel(
          EnvironmentPresetDraftIssueKind.emptyPalette,
        ),
        'Palette vide',
      );
    });
  });

  group('EnvironmentStudioPanel — formulaire brouillon', () {
    testWidgets('action Préparer un preset visible puis formulaire', (
      tester,
    ) async {
      await _pump(
        tester,
        _manifest(
          environmentPresets: [
            _preset(id: 'a'),
          ],
          elements: [_element(id: 'elm')],
        ),
      );

      expect(find.byKey(const Key('environment-studio-open-draft')),
          findsOneWidget);
      expect(find.text('Préparer un preset'), findsOneWidget);

      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('environment-studio-draft-form-title')),
        findsOneWidget,
      );
      expect(find.text('Nouveau preset d’environnement'), findsOneWidget);
      expect(
        find.byKey(const Key('environment-studio-draft-local-badge')),
        findsOneWidget,
      );
      expect(find.text('Brouillon local non sauvegardé'), findsOneWidget);
      expect(
        find.byKey(const Key('environment-studio-draft-form-intro')),
        findsOneWidget,
      );
    });

    testWidgets('champs initiaux vides et params standard', (tester) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      expect(
        (tester.widget<CupertinoTextField>(
                find.byKey(const Key('environment-studio-draft-field-id'))))
            .controller
            ?.text,
        '',
      );
      expect(
        (tester.widget<CupertinoTextField>(
                find.byKey(const Key('environment-studio-draft-field-name'))))
            .controller
            ?.text,
        '',
      );
      expect(
        (tester.widget<CupertinoTextField>(find
                .byKey(const Key('environment-studio-draft-field-template'))))
            .controller
            ?.text,
        '',
      );
      expect(
        (tester.widget<CupertinoTextField>(find
                .byKey(const Key('environment-studio-draft-field-category'))))
            .controller
            ?.text,
        '',
      );
      expect(
        (tester.widget<CupertinoTextField>(
                find.byKey(const Key('environment-studio-draft-field-sort'))))
            .controller
            ?.text,
        '0',
      );
      expect(
        find.byKey(const Key('environment-studio-draft-params-readonly')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('environment-studio-draft-palette-empty')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('environment-studio-draft-palette-note')),
        findsOneWidget,
      );
    });

    testWidgets('validation initiale : id, nom, template, palette', (
      tester,
    ) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('environment-studio-draft-validation-counts')),
        findsOneWidget,
      );
      expect(find.textContaining('erreur'), findsWidgets);
      expect(find.textContaining('Id vide'), findsOneWidget);
      expect(find.textContaining('Nom vide'), findsOneWidget);
      expect(find.textContaining('Template vide'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('environment-studio-draft-validation-root')),
          matching: find.textContaining('Palette vide'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('saisie met à jour le draft et la validation', (tester) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-id')),
        'new_id',
      );
      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-name')),
        'Nom',
      );
      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-template')),
        'tpl1',
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Id vide'), findsNothing);
      expect(find.textContaining('Nom vide'), findsNothing);
      expect(find.textContaining('Template vide'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const Key('environment-studio-draft-validation-root')),
          matching: find.textContaining('Palette vide'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('sortOrder : texte invalide conserve la valeur draft', (
      tester,
    ) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-sort')),
        'not_a_number',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-id')),
        'x',
      );
      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-name')),
        'N',
      );
      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-template')),
        't',
      );
      await tester.pumpAndSettle();

      expect(
        (tester.widget<CupertinoTextField>(
                find.byKey(const Key('environment-studio-draft-field-sort'))))
            .controller
            ?.text,
        'not_a_number',
      );
    });

    testWidgets('Réinitialiser brouillon remet les champs vides', (
      tester,
    ) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-id')),
        'tmp',
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('environment-studio-draft-reset')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('environment-studio-draft-reset')));
      await tester.pumpAndSettle();

      expect(
        (tester.widget<CupertinoTextField>(
                find.byKey(const Key('environment-studio-draft-field-id'))))
            .controller
            ?.text,
        '',
      );
      expect(
        (tester.widget<CupertinoTextField>(
                find.byKey(const Key('environment-studio-draft-field-sort'))))
            .controller
            ?.text,
        '0',
      );
    });

    testWidgets('Retour au browser restaure la liste sans modifier le manifest',
        (tester) async {
      final manifest = _manifest(
        environmentPresets: [
          _preset(id: 'keep'),
        ],
        elements: [_element(id: 'elm')],
      );
      final idsBefore =
          manifest.environmentPresets.map((p) => p.id).toList(growable: false);
      final n = idsBefore.length;

      await _pump(tester, manifest);
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-id')),
        'intruder',
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('environment-studio-draft-cancel')),
      );
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const Key('environment-studio-draft-cancel')));
      await tester.pumpAndSettle();

      expect(manifest.environmentPresets.length, n);
      expect(
        manifest.environmentPresets.map((p) => p.id).toList(growable: false),
        idsBefore,
      );
      expect(find.byKey(const Key('environment-studio-preset-list')),
          findsOneWidget);
      expect(find.text('keep'), findsWidgets);
    });

    testWidgets('aucun Save / Create / Generate dans l’UI', (tester) async {
      await _pump(
        tester,
        _manifest(
          environmentPresets: [_preset(id: 'z')],
          elements: [_element(id: 'elm')],
        ),
      );
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Save'), findsNothing);
      expect(find.textContaining('Create'), findsNothing);
      expect(find.textContaining('Generate'), findsNothing);
    });

    testWidgets('catégorie optionnelle : champ vide', (tester) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      expect(
        (tester.widget<CupertinoTextField>(find
                .byKey(const Key('environment-studio-draft-field-category'))))
            .controller
            ?.text,
        '',
      );
    });
  });
}

Future<void> _pump(WidgetTester tester, ProjectManifest manifest) async {
  tester.view.physicalSize = const Size(900, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
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
  List<ProjectElementEntry> elements = const [],
}) {
  return ProjectManifest(
    name: 'form-shell-test',
    maps: const [],
    tilesets: const [],
    environmentPresets: environmentPresets,
    elements: elements,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

EnvironmentPreset _preset({required String id}) {
  return EnvironmentPreset(
    id: id,
    name: 'P $id',
    templateId: 'tpl',
    palette: [
      EnvironmentPaletteItem(elementId: 'elm', weight: 1),
    ],
    defaultParams: EnvironmentGenerationParams.standard(),
    sortOrder: 0,
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
