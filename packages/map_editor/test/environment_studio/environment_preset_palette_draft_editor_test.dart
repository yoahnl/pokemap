import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/environment_studio/environment_studio_panel.dart';

void main() {
  group('EnvironmentStudioPanel — palette brouillon (Lot 14)', () {
    testWidgets(
        'ajouter un item : emptyPalette disparaît, emptyPaletteElementId',
        (tester) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      expect(
        _validationHas(tester, 'Palette vide'),
        isTrue,
      );

      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();

      expect(
        _validationHas(tester, 'Palette vide'),
        isFalse,
      );
      expect(
        _validationHas(tester, 'Élément de palette vide'),
        isTrue,
      );
      expect(
        find.byKey(const Key('environment-studio-palette-draft-item-0')),
        findsOneWidget,
      );
    });

    testWidgets(
        'elementId connu : plus d’emptyPaletteElementId ni missingPaletteElement',
        (tester) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('environment-studio-palette-draft-element-0')),
        'elm',
      );
      await tester.pumpAndSettle();

      expect(
        _validationHas(tester, 'Élément de palette vide'),
        isFalse,
      );
      expect(
        _validationHas(tester, 'Élément introuvable'),
        isFalse,
      );
    });

    testWidgets('elementId absent : Élément introuvable', (tester) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('environment-studio-palette-draft-element-0')),
        'inconnu_xyz',
      );
      await tester.pumpAndSettle();

      expect(
        _validationHas(tester, 'Élément introuvable'),
        isTrue,
      );
    });

    testWidgets(
        'poids 3 valide, poids 0 invalide, texte non numérique inchangé',
        (tester) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();

      final w =
          find.byKey(const Key('environment-studio-palette-draft-weight-0'));

      await tester.enterText(w, '3');
      await tester.pumpAndSettle();
      expect(
        _validationHas(tester, 'Poids invalide'),
        isFalse,
      );

      await tester.enterText(w, '0');
      await tester.pumpAndSettle();
      expect(
        _validationHas(tester, 'Poids invalide'),
        isTrue,
      );

      await tester.enterText(w, '5');
      await tester.pumpAndSettle();
      expect(
        _validationHas(tester, 'Poids invalide'),
        isFalse,
      );

      await tester.enterText(w, 'not_int');
      await tester.pumpAndSettle();
      expect(
        (tester.widget<CupertinoTextField>(w)).controller?.text,
        'not_int',
      );
      expect(
        _validationHas(tester, 'Poids invalide'),
        isFalse,
      );
    });

    testWidgets(
        'collision : bascule Collision forcée puis Collision désactivée',
        (tester) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Défaut élément'), findsWidgets);

      await tester.tap(find.text('Collision forcée').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Collision désactivée').last);
      await tester.pumpAndSettle();
    });

    testWidgets('tags : tree, canopy OK ; tree, , canopy → Tag vide', (
      tester,
    ) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();

      final tags =
          find.byKey(const Key('environment-studio-palette-draft-tags-0'));

      await tester.enterText(tags, 'tree, canopy');
      await tester.pumpAndSettle();
      expect(
        _validationHas(tester, 'Tag vide'),
        isFalse,
      );

      await tester.enterText(tags, 'tree, , canopy');
      await tester.pumpAndSettle();
      expect(
        _validationHas(tester, 'Tag vide'),
        isTrue,
      );
    });

    testWidgets('Retirer : palette vide, emptyPalette revient', (tester) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();

      expect(
        _validationHas(tester, 'Palette vide'),
        isFalse,
      );

      await tester.ensureVisible(
        find.byKey(const Key('environment-studio-palette-draft-remove-0')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('environment-studio-palette-draft-remove-0')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('environment-studio-draft-palette-no-items')),
        findsOneWidget,
      );
      expect(
        _validationHas(tester, 'Palette vide'),
        isTrue,
      );
    });

    testWidgets('deux items même elementId : Élément dupliqué', (tester) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('environment-studio-palette-draft-element-0')),
        'elm',
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('environment-studio-palette-draft-element-1')),
        'elm',
      );
      await tester.pumpAndSettle();

      expect(
        _validationHas(tester, 'Élément dupliqué'),
        isTrue,
      );
    });

    testWidgets(
        'édition palette + retour browser : manifest.environmentPresets inchangé',
        (tester) async {
      final manifest = _manifest(
        environmentPresets: [
          _preset(id: 'keep'),
        ],
        elements: [_element(id: 'elm')],
      );
      final idsBefore =
          manifest.environmentPresets.map((p) => p.id).toList(growable: false);

      await _pump(tester, manifest);
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('environment-studio-palette-draft-element-0')),
        'elm',
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('environment-studio-draft-cancel')),
      );
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const Key('environment-studio-draft-cancel')));
      await tester.pumpAndSettle();

      expect(
        manifest.environmentPresets.map((p) => p.id).toList(growable: false),
        idsBefore,
      );
      expect(manifest.environmentPresets.length, 1);
    });
  });
}

bool _validationHas(WidgetTester tester, String substring) {
  final matches = find.descendant(
    of: find.byKey(const Key('environment-studio-draft-validation-root')),
    matching: find.textContaining(substring),
  );
  return matches.evaluate().isNotEmpty;
}

Future<void> _pump(WidgetTester tester, ProjectManifest manifest) async {
  tester.view.physicalSize = const Size(900, 2200);
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
    name: 'palette-draft-test',
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
