import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/environment_studio/environment_preset_memory_write_kind.dart';
import 'package:map_editor/src/features/environment_studio/environment_studio_panel.dart';

void main() {
  group('EnvironmentStudioPanel — visual shell layout (EnvironmentStudio-3A)',
      () {
    testWidgets('affiche le shell large, la bannière et le layout 2 colonnes',
        (tester) async {
      await _pumpWithSave(
        tester,
        _manifest(
          environmentPresets: [_preset(id: 'forest')],
          elements: [_element(id: 'elm')],
        ),
      );

      expect(find.byKey(const Key('environment-studio-shell')), findsOneWidget);
      expect(find.text('Environment Studio'), findsOneWidget);
      expect(
          find.text('Presets d’environnements réutilisables'), findsOneWidget);
      expect(
        find.text(
          'Les presets se préparent ici. La peinture et la génération se font dans l’éditeur de carte.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('environment-studio-main-layout')),
          findsOneWidget);
      expect(find.byKey(const Key('environment-studio-preset-column')),
          findsOneWidget);
      expect(find.byKey(const Key('environment-studio-editor-panel')),
          findsOneWidget);
      expect(find.text('Presets'), findsOneWidget);
      expect(find.text('Nouveau preset'), findsOneWidget);
      expect(find.text('Éditer le preset'), findsOneWidget);
    });

    testWidgets('structure les sections numérotées du preset sélectionné',
        (tester) async {
      await _pumpWithSave(
        tester,
        _manifest(
          environmentPresets: [_preset(id: 'forest')],
          elements: [_element(id: 'elm')],
        ),
      );

      expect(find.byKey(const Key('environment-studio-section-number-1')),
          findsOneWidget);
      expect(find.byKey(const Key('environment-studio-section-number-2')),
          findsOneWidget);
      expect(find.byKey(const Key('environment-studio-section-number-3')),
          findsOneWidget);
      expect(find.text('Identité'), findsOneWidget);
      expect(find.text('Paramètres par défaut'), findsWidgets);
      expect(find.text('Palette du preset'), findsOneWidget);
    });

    testWidgets('garde Studio limité aux presets sans commandes de map',
        (tester) async {
      await _pumpWithSave(
        tester,
        _manifest(
          environmentPresets: [_preset(id: 'forest')],
          elements: [_element(id: 'elm')],
        ),
      );

      expect(find.textContaining('shell read-only'), findsNothing);
      expect(find.textContaining('lecture seule'), findsNothing);
      expect(find.textContaining('génération sur carte arrive bientôt'),
          findsNothing);
      expect(find.text('Generate'), findsNothing);
      expect(find.text('Regenerate'), findsNothing);
      expect(find.text('Clear'), findsNothing);
      expect(find.text('Peindre le masque'), findsNothing);
    });
  });

  group('EnvironmentStudioPanel — palette table convergence (3B)', () {
    testWidgets('structure le panneau droit comme un studio compact',
        (tester) async {
      await _pumpWithSave(
        tester,
        _manifest(
          environmentPresets: [_preset(id: 'forest')],
          elements: [_element(id: 'elm')],
        ),
      );

      expect(find.byKey(const Key('environment-studio-editor-top-bar')),
          findsOneWidget);
      expect(find.byKey(const Key('environment-studio-tileset-source-card')),
          findsOneWidget);
      expect(find.byKey(const Key('environment-studio-identity-grid')),
          findsOneWidget);
      expect(find.byKey(const Key('environment-studio-default-param-grid')),
          findsOneWidget);
      expect(find.byKey(const Key('environment-studio-palette-table')),
          findsOneWidget);
      expect(find.byKey(const Key('environment-studio-palette-header-element')),
          findsOneWidget);
      expect(find.byKey(const Key('environment-studio-palette-header-weight')),
          findsOneWidget);
      expect(
          find.byKey(const Key('environment-studio-palette-header-collision')),
          findsOneWidget);
      expect(find.byKey(const Key('environment-studio-palette-header-tags')),
          findsOneWidget);
      expect(find.byKey(const Key('environment-studio-palette-header-actions')),
          findsOneWidget);
      expect(
          find.byKey(const Key('environment-studio-project-diagnostics-card')),
          findsOneWidget);
      expect(find.text('Diagnostics projet'), findsOneWidget);
      expect(find.text('Voir le rapport complet'), findsOneWidget);
      expect(find.textContaining('shell read-only'), findsNothing);
      expect(find.textContaining('lecture seule'), findsNothing);
    });

    testWidgets('le mode palette garde les actions dans une table éditable',
        (tester) async {
      await _pumpWithSave(
        tester,
        _manifest(
          environmentPresets: [_preset(id: 'forest')],
          elements: [
            _element(id: 'elm'),
            _element(id: 'elm_b'),
          ],
        ),
      );

      await tester
          .tap(find.byKey(const Key('environment-studio-edit-palette')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('environment-studio-palette-draft-toolbar')),
          findsOneWidget);
      expect(find.byKey(const Key('environment-studio-compatible-filter')),
          findsOneWidget);
      expect(find.byKey(const Key('environment-studio-palette-table')),
          findsOneWidget);
      expect(find.byKey(const Key('environment-studio-palette-header-element')),
          findsOneWidget);
      expect(find.byKey(const Key('environment-studio-palette-header-weight')),
          findsOneWidget);
      expect(
          find.byKey(const Key('environment-studio-palette-header-collision')),
          findsOneWidget);
      expect(find.byKey(const Key('environment-studio-palette-header-tags')),
          findsOneWidget);
      expect(find.byKey(const Key('environment-studio-palette-header-actions')),
          findsOneWidget);
      expect(find.text('Ajouter un élément'), findsOneWidget);
      expect(find.text('Enregistrer la palette'), findsOneWidget);
      expect(find.text('Annuler les changements'), findsOneWidget);
    });
  });

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

    testWidgets('picker bibliothèque remplit elementId', (tester) async {
      await _pump(tester, _manifest(elements: [_element(id: 'elm')]));
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(
            const Key('environment-studio-palette-draft-pick-element-0')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
            const Key('environment-studio-palette-draft-pick-element-0')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('elm — El elm'));
      await tester.pumpAndSettle();

      expect(
        (tester.widget<CupertinoTextField>(find.byKey(
                const Key('environment-studio-palette-draft-element-0'))))
            .controller
            ?.text,
        'elm',
      );
      expect(
        _validationHas(tester, 'Élément de palette vide'),
        isFalse,
      );
    });

    testWidgets('picker bibliothèque filtre les éléments du tileset source',
        (tester) async {
      await _pump(
        tester,
        _manifest(
          elements: [
            _element(id: 'grass_a', tilesetId: 'grass'),
            _element(id: 'grass_b', tilesetId: 'grass'),
            _element(id: 'rock_a', tilesetId: 'rocks'),
          ],
        ),
      );
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('environment-studio-palette-draft-element-0')),
        'grass_a',
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(
            const Key('environment-studio-palette-draft-pick-element-1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
            const Key('environment-studio-palette-draft-pick-element-1')),
      );
      await tester.pumpAndSettle();

      expect(find.text('grass_b — El grass_b'), findsOneWidget);
      expect(find.text('rock_a — El rock_a'), findsNothing);
    });

    testWidgets('saisie manuelle incompatible déclenche Tilesets mélangés',
        (tester) async {
      await _pump(
        tester,
        _manifest(
          elements: [
            _element(id: 'grass_a', tilesetId: 'grass'),
            _element(id: 'rock_a', tilesetId: 'rocks'),
          ],
        ),
      );
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('environment-studio-palette-draft-element-0')),
        'grass_a',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('environment-studio-palette-draft-element-1')),
        'rock_a',
      );
      await tester.pumpAndSettle();

      expect(
        _validationHas(tester, 'Tilesets mélangés'),
        isTrue,
      );
      expect(
        find.textContaining('mélange plusieurs tilesets'),
        findsOneWidget,
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

  group('EnvironmentStudioPanel — palette save flow (EnvironmentStudio-2)', () {
    testWidgets(
        'modifier palette affiche un brouillon sale puis annuler restaure',
        (tester) async {
      final manifest = _manifest(
        environmentPresets: [_preset(id: 'forest')],
        elements: [
          _element(id: 'elm'),
          _element(id: 'elm_b'),
        ],
      );

      await _pumpWithSave(tester, manifest);
      await tester
          .tap(find.byKey(const Key('environment-studio-edit-palette')));
      await tester.pumpAndSettle();

      expect(find.text('Brouillon non enregistré'), findsOneWidget);
      final saveBefore = tester.widget<CupertinoButton>(
        find.byKey(const Key('environment-studio-palette-save')),
      );
      final cancelBefore = tester.widget<CupertinoButton>(
        find.byKey(const Key('environment-studio-palette-cancel')),
      );
      expect(saveBefore.onPressed, isNull);
      expect(cancelBefore.onPressed, isNull);

      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('environment-studio-palette-draft-element-1')),
        'elm_b',
      );
      await tester.pumpAndSettle();

      expect(
          find.text('Palette modifiée — enregistrez pour appliquer au projet.'),
          findsOneWidget);
      final saveDirty = tester.widget<CupertinoButton>(
        find.byKey(const Key('environment-studio-palette-save')),
      );
      final cancelDirty = tester.widget<CupertinoButton>(
        find.byKey(const Key('environment-studio-palette-cancel')),
      );
      expect(saveDirty.onPressed, isNotNull);
      expect(cancelDirty.onPressed, isNotNull);

      await tester
          .tap(find.byKey(const Key('environment-studio-palette-cancel')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('environment-studio-palette-draft-item-1')),
          findsNothing);
      expect(
        find.byKey(const Key('environment-studio-palette-item-elm')),
        findsOneWidget,
      );
    });

    testWidgets('enregistrer la palette appelle le callback et garde le preset',
        (tester) async {
      ProjectManifest? receivedManifest;
      EnvironmentPreset? receivedPreset;
      EnvironmentPresetMemoryWriteKind? receivedKind;
      final manifest = _manifest(
        environmentPresets: [_preset(id: 'forest')],
        elements: [
          _element(id: 'elm'),
          _element(id: 'elm_b'),
        ],
      );

      await _pumpWithSave(
        tester,
        manifest,
        onSaved: (m, p, k) {
          receivedManifest = m;
          receivedPreset = p;
          receivedKind = k;
        },
      );
      await tester
          .tap(find.byKey(const Key('environment-studio-edit-palette')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('environment-studio-palette-draft-element-1')),
        'elm_b',
      );
      await tester.pumpAndSettle();

      await tester
          .tap(find.byKey(const Key('environment-studio-palette-save')));
      await tester.pumpAndSettle();

      expect(receivedManifest, isNotNull);
      expect(receivedPreset, isNotNull);
      expect(receivedKind, EnvironmentPresetMemoryWriteKind.update);
      expect(receivedPreset!.id, 'forest');
      expect(receivedPreset!.name, 'P forest');
      expect(receivedPreset!.templateId, 'tpl');
      expect(receivedPreset!.defaultParams,
          EnvironmentGenerationParams.standard());
      expect(receivedPreset!.palette.map((item) => item.elementId),
          ['elm', 'elm_b']);
      expect(
        findProjectEnvironmentPresetById(receivedManifest!, 'forest')!
            .palette
            .map((item) => item.elementId),
        ['elm', 'elm_b'],
      );
      expect(find.byKey(const Key('environment-studio-detail-id')),
          findsOneWidget);
      expect(
          find.textContaining('Palette enregistrée dans le projet en mémoire.'),
          findsOneWidget);
    });

    testWidgets('picker palette exclut un élément incompatible',
        (tester) async {
      await _pumpWithSave(
        tester,
        _manifest(
          environmentPresets: [
            _preset(id: 'forest', elementId: 'grass_a'),
          ],
          elements: [
            _element(id: 'grass_a', tilesetId: 'grass'),
            _element(id: 'grass_b', tilesetId: 'grass'),
            _element(id: 'rock_a', tilesetId: 'rocks'),
          ],
        ),
      );

      await tester
          .tap(find.byKey(const Key('environment-studio-edit-palette')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
            const Key('environment-studio-palette-draft-pick-element-1')),
      );
      await tester.pumpAndSettle();

      expect(find.text('grass_b — El grass_b'), findsOneWidget);
      expect(find.text('rock_a — El rock_a'), findsNothing);
    });

    testWidgets('preset mixte bloque save mais permet retirer incompatible',
        (tester) async {
      await _pumpWithSave(
        tester,
        _manifest(
          environmentPresets: [
            EnvironmentPreset(
              id: 'mixed',
              name: 'Mixed',
              templateId: 'tpl',
              palette: [
                EnvironmentPaletteItem(elementId: 'grass_a', weight: 1),
                EnvironmentPaletteItem(elementId: 'rock_a', weight: 1),
              ],
              defaultParams: EnvironmentGenerationParams.standard(),
              sortOrder: 0,
            ),
          ],
          elements: [
            _element(id: 'grass_a', tilesetId: 'grass'),
            _element(id: 'rock_a', tilesetId: 'rocks'),
          ],
        ),
      );
      await tester
          .tap(find.byKey(const Key('environment-studio-edit-palette')));
      await tester.pumpAndSettle();

      expect(find.textContaining('mélange plusieurs tilesets'), findsOneWidget);
      final saveMixed = tester.widget<CupertinoButton>(
        find.byKey(const Key('environment-studio-palette-save')),
      );
      expect(saveMixed.onPressed, isNull);

      await tester.tap(
        find.byKey(const Key('environment-studio-palette-draft-remove-1')),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('mélange plusieurs tilesets'), findsNothing);
      final saveAfterCleanup = tester.widget<CupertinoButton>(
        find.byKey(const Key('environment-studio-palette-save')),
      );
      expect(saveAfterCleanup.onPressed, isNotNull);
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

Future<void> _pumpWithSave(
  WidgetTester tester,
  ProjectManifest manifest, {
  void Function(
    ProjectManifest nextManifest,
    EnvironmentPreset savedPreset,
    EnvironmentPresetMemoryWriteKind kind,
  )? onSaved,
}) async {
  tester.view.physicalSize = const Size(900, 2200);
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
          onEnvironmentPresetSaved: onSaved ?? (_, __, ___) {},
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
    name: 'palette-draft-test',
    maps: const [],
    tilesets: const [],
    environmentPresets: environmentPresets,
    elements: elements,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

EnvironmentPreset _preset({
  required String id,
  String elementId = 'elm',
}) {
  return EnvironmentPreset(
    id: id,
    name: 'P $id',
    templateId: 'tpl',
    palette: [
      EnvironmentPaletteItem(elementId: elementId, weight: 1),
    ],
    defaultParams: EnvironmentGenerationParams.standard(),
    sortOrder: 0,
  );
}

ProjectElementEntry _element({
  required String id,
  String tilesetId = 'ts',
}) {
  return ProjectElementEntry(
    id: id,
    name: 'El $id',
    tilesetId: tilesetId,
    categoryId: 'cat',
    frames: const [
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0),
      ),
    ],
  );
}
