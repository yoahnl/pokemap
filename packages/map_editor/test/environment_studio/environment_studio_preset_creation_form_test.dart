import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/environment_studio/authoring/environment_preset_draft.dart';
import 'package:map_editor/src/features/environment_studio/environment_preset_memory_write_kind.dart';
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
      expect(
        environmentPresetDraftIssueKindLabel(
          EnvironmentPresetDraftIssueKind.mixedPaletteTilesets,
        ),
        'Tilesets mélangés',
      );
    });
  });

  group('EnvironmentStudioPanel — création tileset-first (3C)', () {
    testWidgets(
        'Nouveau preset ouvre un wizard et bloque Continuer sans tileset',
        (tester) async {
      await _pump(
        tester,
        _manifest(
          environmentPresets: [_preset(id: 'forest')],
          tilesets: [_tileset(id: 'grass')],
          elements: [_element(id: 'grass_a', tilesetId: 'grass')],
        ),
      );

      await _openWizard(tester);

      expect(
        find.byKey(const Key('environment-studio-creation-wizard')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('environment-creation-stepper')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('environment-creation-tileset-step')),
        findsOneWidget,
      );
      expect(find.text('Nouveau preset d’environnement'), findsOneWidget);
      expect(find.text('Brouillon local non sauvegardé'), findsOneWidget);
      expect(find.text('Étape 1 sur 2 — Choisir le tileset source'),
          findsOneWidget);
      expect(
        find.text(
          'Choisissez le tileset contenant les éléments que ce preset pourra utiliser.',
        ),
        findsOneWidget,
      );

      final continueButton = tester.widget<CupertinoButton>(
        find.byKey(const Key('environment-studio-creation-continue')),
      );
      expect(continueButton.onPressed, isNull);
      expect(find.textContaining('shell read-only'), findsNothing);
      expect(find.textContaining('génération sur carte arrive bientôt'),
          findsNothing);
      expect(find.text('Generate'), findsNothing);
      expect(find.text('Peindre le masque'), findsNothing);
    });

    testWidgets('sélectionner un tileset active l’étape éléments compatibles',
        (tester) async {
      final tilesetImage = _testTilesetPng();
      await _pump(
        tester,
        _manifest(
          environmentPresets: [_preset(id: 'forest')],
          settings: const ProjectSettings(tileWidth: 1, tileHeight: 1),
          tilesets: [
            _tileset(id: 'grass', name: 'Herbes'),
            _tileset(id: 'rocks', name: 'Rochers'),
          ],
          elements: [
            _element(id: 'grass_a', name: 'Herbe A', tilesetId: 'grass'),
            _element(id: 'rock_a', name: 'Rocher A', tilesetId: 'rocks'),
            _element(id: 'unknown_a', name: 'Sans source', tilesetId: ''),
          ],
        ),
        resolveTilesetPathById: (tilesetId) =>
            tilesetId == 'grass' ? tilesetImage.path : null,
      );

      await _openWizard(tester);
      await tester.tap(
        find.byKey(const Key('environment-studio-creation-tileset-grass')),
      );
      await tester.pumpAndSettle();

      final continueButton = tester.widget<CupertinoButton>(
        find.byKey(const Key('environment-studio-creation-continue')),
      );
      expect(continueButton.onPressed, isNotNull);

      await tester.tap(
        find.byKey(const Key('environment-studio-creation-continue')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Étape 2 sur 2 — Choisir les éléments du preset'),
          findsOneWidget);
      expect(
        find.byKey(const Key('environment-creation-elements-step')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('environment-creation-tileset-summary')),
        findsOneWidget,
      );
      expect(find.text('Tileset source : grass'), findsOneWidget);
      expect(find.text('1 éléments compatibles'), findsOneWidget);
      expect(find.text('Changer de tileset'), findsOneWidget);
      expect(find.byKey(const Key('environment-studio-creation-identity-grid')),
          findsOneWidget);
      expect(
        find.byKey(const Key('environment-compatible-elements-panel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('environment-selected-palette-panel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('environment-creation-action-bar')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('environment-creation-final-submit')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('environment-creation-empty-palette')),
        findsOneWidget,
      );
      expect(
        find.text(
          'Aucun élément sélectionné. Ajoutez au moins un élément compatible pour créer le preset.',
        ),
        findsOneWidget,
      );
      expect(find.text('Herbe A'), findsOneWidget);
      expect(find.text('Rocher A'), findsNothing);
      expect(find.text('Sans source'), findsNothing);
      expect(
        find.byKey(
          const Key('environment-studio-creation-compatible-element-grass_a'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('environment-creation-element-preview-grass_a')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('environment-element-preview-grass_a')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('environment-element-preview-fallback-grass_a')),
        findsNothing,
      );
    });

    testWidgets('prévisualise le fallback si le tileset image est introuvable',
        (tester) async {
      await _pump(
        tester,
        _manifest(
          environmentPresets: [_preset(id: 'forest')],
          tilesets: [_tileset(id: 'grass', name: 'Herbes')],
          elements: [
            _element(id: 'grass_a', name: 'Herbe A', tilesetId: 'grass'),
          ],
        ),
        resolveTilesetPathById: (_) => null,
      );

      await _openWizard(tester);
      await _selectTilesetAndContinue(tester, 'grass');

      expect(
        find.byKey(const Key('environment-element-preview-fallback-grass_a')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('environment-element-preview-grass_a')),
        findsNothing,
      );
    });

    testWidgets(
        'ajout, retrait et création mémoire restent guidés par le tileset',
        (tester) async {
      final tilesetImage = _testTilesetPng();
      ProjectManifest? receivedManifest;
      EnvironmentPreset? receivedPreset;
      EnvironmentPresetMemoryWriteKind? receivedKind;

      await _pump(
        tester,
        _manifest(
          environmentPresets: [_preset(id: 'forest')],
          settings: const ProjectSettings(tileWidth: 1, tileHeight: 1),
          tilesets: [_tileset(id: 'grass', name: 'Herbes')],
          elements: [
            _element(id: 'grass_a', name: 'Herbe A', tilesetId: 'grass')
          ],
        ),
        onSaved: (manifest, preset, kind) {
          receivedManifest = manifest;
          receivedPreset = preset;
          receivedKind = kind;
        },
        resolveTilesetPathById: (tilesetId) =>
            tilesetId == 'grass' ? tilesetImage.path : null,
      );

      await _openWizard(tester);
      await _selectTilesetAndContinue(tester, 'grass');

      final emptySaveButton = tester.widget<CupertinoButton>(
        find.byKey(const Key('environment-studio-draft-save-project')),
      );
      expect(emptySaveButton.onPressed, isNull);
      expect(find.textContaining('Palette vide'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const Key('environment-studio-creation-add-element-grass_a'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('environment-studio-palette-draft-item-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('environment-selected-palette-preview-grass_a')),
        findsOneWidget,
      );
      expect(find.text('Ajouté à la palette'), findsOneWidget);
      expect(find.text('Herbe A'), findsWidgets);

      await tester.tap(
        find.byKey(const Key('environment-studio-palette-draft-remove-0')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('environment-studio-palette-draft-item-0')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(
          const Key('environment-studio-creation-add-element-grass_a'),
        ),
      );
      await tester.pumpAndSettle();

      final saveButton = tester.widget<CupertinoButton>(
        find.byKey(const Key('environment-studio-draft-save-project')),
      );
      expect(saveButton.onPressed, isNotNull);

      await tester.tap(
        find.byKey(const Key('environment-studio-draft-save-project')),
      );
      await tester.pumpAndSettle();

      expect(receivedKind, EnvironmentPresetMemoryWriteKind.create);
      expect(receivedPreset, isNotNull);
      expect(receivedPreset!.palette.single.elementId, 'grass_a');
      expect(receivedManifest!.environmentPresets.map((preset) => preset.id),
          contains(receivedPreset!.id));
    });

    testWidgets('changer de tileset vide la palette du brouillon',
        (tester) async {
      await _pump(
        tester,
        _manifest(
          environmentPresets: [_preset(id: 'forest')],
          tilesets: [
            _tileset(id: 'grass'),
            _tileset(id: 'rocks'),
          ],
          elements: [
            _element(id: 'grass_a', tilesetId: 'grass'),
            _element(id: 'rock_a', name: 'Rocher A', tilesetId: 'rocks'),
          ],
        ),
      );

      await _openWizard(tester);
      await _selectTilesetAndContinue(tester, 'grass');
      await tester.tap(
        find.byKey(
          const Key('environment-studio-creation-add-element-grass_a'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('environment-studio-palette-draft-item-0')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('environment-studio-creation-back-to-tilesets')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('environment-studio-creation-tileset-rocks')),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Le changement de tileset a vidé la palette du brouillon pour éviter tout mélange.',
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const Key('environment-studio-creation-continue')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('environment-studio-palette-draft-item-0')),
        findsNothing,
      );
      expect(find.text('Rocher A'), findsOneWidget);
      expect(find.text('Herbe A'), findsNothing);
    });

    testWidgets('un élément forcé hors tileset source bloque la création',
        (tester) async {
      await _pump(
        tester,
        _manifest(
          environmentPresets: [_preset(id: 'forest')],
          tilesets: [
            _tileset(id: 'grass'),
            _tileset(id: 'rocks'),
          ],
          elements: [
            _element(id: 'grass_a', tilesetId: 'grass'),
            _element(id: 'rock_a', tilesetId: 'rocks'),
          ],
        ),
      );

      await _openWizard(tester);
      await _selectTilesetAndContinue(tester, 'grass');
      await tester.tap(
        find.byKey(
          const Key('environment-studio-creation-add-element-grass_a'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('environment-studio-palette-draft-element-0')),
        'rock_a',
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Élément incompatible avec le tileset source'),
        findsOneWidget,
      );
      final saveButton = tester.widget<CupertinoButton>(
        find.byKey(const Key('environment-studio-draft-save-project')),
      );
      expect(saveButton.onPressed, isNull);
    });

    testWidgets('catégorie optionnelle : champ compact vide', (tester) async {
      await _pump(
        tester,
        _manifest(
          environmentPresets: [_preset(id: 'forest')],
          tilesets: [_tileset(id: 'grass')],
          elements: [_element(id: 'grass_a', tilesetId: 'grass')],
        ),
      );

      await _openWizard(tester);
      await _selectTilesetAndContinue(tester, 'grass');

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

Future<void> _pump(
  WidgetTester tester,
  ProjectManifest manifest, {
  void Function(
    ProjectManifest,
    EnvironmentPreset,
    EnvironmentPresetMemoryWriteKind,
  )? onSaved,
  String? Function(String tilesetId)? resolveTilesetPathById,
}) async {
  tester.view.physicalSize = const Size(1100, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MacosApp(
      home: CupertinoPageScaffold(
        child: EnvironmentStudioPanel(
          manifest: manifest,
          resolveTilesetPathById: resolveTilesetPathById,
          onEnvironmentPresetSaved: onSaved ?? (_, __, ___) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openWizard(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
  await tester.pumpAndSettle();
}

Future<void> _selectTilesetAndContinue(
  WidgetTester tester,
  String tilesetId,
) async {
  await tester.tap(
    find.byKey(Key('environment-studio-creation-tileset-$tilesetId')),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const Key('environment-studio-creation-continue')),
  );
  await tester.pumpAndSettle();
}

ProjectManifest _manifest({
  List<EnvironmentPreset> environmentPresets = const [],
  List<ProjectTilesetEntry> tilesets = const [],
  List<ProjectElementEntry> elements = const [],
  ProjectSettings settings = const ProjectSettings(),
}) {
  return ProjectManifest(
    name: 'form-shell-test',
    maps: const [],
    tilesets: tilesets,
    environmentPresets: environmentPresets,
    elements: elements,
    settings: settings,
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
}

ProjectTilesetEntry _tileset({
  required String id,
  String? name,
  String? relativePath,
}) {
  return ProjectTilesetEntry(
    id: id,
    name: name ?? id,
    relativePath: relativePath ?? 'tilesets/$id.png',
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

File _testTilesetPng() {
  return File(
    '${Directory.current.path}/macos/Runner/Assets.xcassets/AppIcon.appiconset/16.png',
  );
}

ProjectElementEntry _element({
  required String id,
  String? name,
  String tilesetId = 'ts',
}) {
  return ProjectElementEntry(
    id: id,
    name: name ?? 'El $id',
    tilesetId: tilesetId,
    categoryId: 'cat',
    frames: [
      TilesetVisualFrame(
        tilesetId: tilesetId,
        source: const TilesetSourceRect(x: 0, y: 0),
      ),
    ],
  );
}
