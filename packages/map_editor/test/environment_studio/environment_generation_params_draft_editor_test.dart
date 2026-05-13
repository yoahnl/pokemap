import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/environment_studio/environment_studio_panel.dart';

void main() {
  group('EnvironmentStudioPanel — params génération brouillon (Lot 15)', () {
    testWidgets('affichage initial : titres et valeurs standard',
        (tester) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('environment-studio-draft-params-editor')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('environment-studio-draft-params-section-title')),
        findsOneWidget,
      );
      expect(find.text('Paramètres par défaut'), findsOneWidget);
      expect(
        (tester.widget<CupertinoTextField>(find
                .byKey(const Key('environment-studio-draft-params-density'))))
            .controller
            ?.text,
        '0.5',
      );
      expect(
        (tester.widget<CupertinoTextField>(find
                .byKey(const Key('environment-studio-draft-params-variation'))))
            .controller
            ?.text,
        '0.5',
      );
      expect(
        (tester.widget<CupertinoTextField>(find.byKey(
                const Key('environment-studio-draft-params-edge-density'))))
            .controller
            ?.text,
        '0.5',
      );
      expect(
        (tester.widget<CupertinoTextField>(find.byKey(
                const Key('environment-studio-draft-params-min-spacing'))))
            .controller
            ?.text,
        '0',
      );
    });

    testWidgets('densité 0.75 OK puis 1.5 → Densité invalide', (tester) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      final d =
          find.byKey(const Key('environment-studio-draft-params-density'));
      await tester.enterText(d, '0.75');
      await tester.pumpAndSettle();
      expect(
        _validationHas(tester, 'Densité invalide'),
        isFalse,
      );

      await tester.enterText(d, '1.5');
      await tester.pumpAndSettle();
      expect(
        _validationHas(tester, 'Densité invalide'),
        isTrue,
      );
    });

    testWidgets('variation 0.25 OK puis -0.1 → Variation invalide', (
      tester,
    ) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      final f =
          find.byKey(const Key('environment-studio-draft-params-variation'));
      await tester.enterText(f, '0.25');
      await tester.pumpAndSettle();
      expect(
        _validationHas(tester, 'Variation invalide'),
        isFalse,
      );

      await tester.enterText(f, '-0.1');
      await tester.pumpAndSettle();
      expect(
        _validationHas(tester, 'Variation invalide'),
        isTrue,
      );
    });

    testWidgets('densité des bords 0.6 OK puis 2 → Densité des bords invalide',
        (tester) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      final f =
          find.byKey(const Key('environment-studio-draft-params-edge-density'));
      await tester.enterText(f, '0.6');
      await tester.pumpAndSettle();
      expect(
        _validationHas(tester, 'Densité des bords invalide'),
        isFalse,
      );

      await tester.enterText(f, '2');
      await tester.pumpAndSettle();
      expect(
        _validationHas(tester, 'Densité des bords invalide'),
        isTrue,
      );
    });

    testWidgets('espacement 3 OK puis -1 → Espacement invalide',
        (tester) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      final f =
          find.byKey(const Key('environment-studio-draft-params-min-spacing'));
      await tester.enterText(f, '3');
      await tester.pumpAndSettle();
      expect(
        _validationHas(tester, 'Espacement invalide'),
        isFalse,
      );

      await tester.enterText(f, '-1');
      await tester.pumpAndSettle();
      expect(
        _validationHas(tester, 'Espacement invalide'),
        isTrue,
      );
    });

    testWidgets('saisie non parseable : champ affiché, draft inchangé', (
      tester,
    ) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      final d =
          find.byKey(const Key('environment-studio-draft-params-density'));
      await tester.enterText(d, 'abc');
      await tester.pumpAndSettle();
      expect((tester.widget<CupertinoTextField>(d)).controller?.text, 'abc');
      expect(
        _validationHas(tester, 'Densité invalide'),
        isFalse,
      );

      final m =
          find.byKey(const Key('environment-studio-draft-params-min-spacing'));
      await tester.enterText(m, 'xyz');
      await tester.pumpAndSettle();
      expect((tester.widget<CupertinoTextField>(m)).controller?.text, 'xyz');
      expect(
        _validationHas(tester, 'Espacement invalide'),
        isFalse,
      );
    });

    testWidgets('Réinitialiser brouillon remet les params standard', (
      tester,
    ) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-params-density')),
        '0.25',
      );
      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-params-min-spacing')),
        '7',
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('environment-studio-draft-reset')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('environment-studio-draft-reset')));
      await tester.pumpAndSettle();

      expect(
        (tester.widget<CupertinoTextField>(find
                .byKey(const Key('environment-studio-draft-params-density'))))
            .controller
            ?.text,
        '0.5',
      );
      expect(
        (tester.widget<CupertinoTextField>(find.byKey(
                const Key('environment-studio-draft-params-min-spacing'))))
            .controller
            ?.text,
        '0',
      );
    });

    testWidgets(
        'modifier params puis retour browser : manifest.environmentPresets inchangé',
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

      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-params-density')),
        '0.2',
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
  return find
      .descendant(
        of: find.byKey(const Key('environment-studio-draft-validation-root')),
        matching: find.textContaining(substring),
      )
      .evaluate()
      .isNotEmpty;
}

Future<void> _pump(WidgetTester tester, ProjectManifest manifest) async {
  tester.view.physicalSize = const Size(900, 2400);
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
    name: 'gen-params-draft-test',
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
