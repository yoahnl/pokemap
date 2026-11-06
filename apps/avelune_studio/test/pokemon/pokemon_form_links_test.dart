import 'dart:typed_data';

import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_controller.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_port.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_species_forms.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<PokemonWorkspaceController> open(
    WidgetTester tester, {
    ValueNotifier<bool>? visible,
  }) async {
    final tick = ValueNotifier(0);
    final shown = visible ?? ValueNotifier(true);
    final controller = PokemonWorkspaceController(
      _FormsPort(),
      changed: () => tick.value++,
    );
    await tester.runAsync(controller.load);
    await tester.runAsync(() => controller.selectSpecies('raichu'));
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: ValueListenableBuilder<bool>(
            valueListenable: shown,
            builder: (_, show, child) => show ? child! : const SizedBox(),
            child: SingleChildScrollView(
              key: const PageStorageKey('pokemon-detail-test'),
              child: ValueListenableBuilder<bool>(
                valueListenable: shown,
                builder: (_, show, _) => show
                    ? ValueListenableBuilder<int>(
                        valueListenable: tick,
                        builder: (_, _, _) =>
                            PokemonSpeciesFormsEditor(controller: controller),
                      )
                    : const SizedBox(height: 10),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return controller;
  }

  List<String> otherForms(PokemonWorkspaceController controller) =>
      List<String>.from(
        (controller.selectedDraft!.document(
                  PokemonDocumentFamily.species,
                )!['forms']
                as Map)['otherForms']
            as List,
      );

  testWidgets('linked forms are named, previewed and unresolved ones stay', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1400);
    addTearDown(tester.view.reset);
    final controller = await open(tester);
    expect(
      find.text('Identifiants liés · séparés par une virgule'),
      findsNothing,
    );
    expect(find.text('Raichu d’Alola'), findsOneWidget);
    expect(find.text('Forme introuvable · gmax-inconnue'), findsOneWidget);
    expect(find.text('Référence conservée telle quelle.'), findsOneWidget);
    expect(find.text('Non résolue'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('species-form-link-preview:raichu-alola')),
      findsOneWidget,
    );
    expect(otherForms(controller), ['alola', 'gmax-inconnue']);
    controller.dispose();
  });

  testWidgets('search offers only forms of the same base species', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1400);
    addTearDown(tester.view.reset);
    final controller = await open(tester);
    final search = find.byKey(const ValueKey('species-form-link-search'));
    expect(
      find.byKey(const ValueKey('species-form-candidate:raichu-mega')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('species-form-candidate:raichu-alola')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('species-form-candidate:pikachu')),
      findsNothing,
    );
    await tester.enterText(search, 'pika');
    await tester.pump();
    expect(
      find.byKey(const ValueKey('species-form-candidate:raichu-mega')),
      findsNothing,
    );
    expect(find.text('Aucune forme ne correspond à « pika ».'), findsOneWidget);
    await tester.enterText(search, 'MÉGA');
    await tester.pump();
    final candidate = find.byKey(
      const ValueKey('species-form-candidate:raichu-mega'),
    );
    await tester.ensureVisible(candidate);
    await tester.tap(candidate);
    await tester.pump();
    expect(otherForms(controller), ['alola', 'gmax-inconnue', 'mega']);
    expect(find.text('Méga-Raichu'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('removing a link is explicit and keeps the others untouched', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1400);
    addTearDown(tester.view.reset);
    final controller = await open(tester);
    await tester.tap(find.byTooltip('Retirer le lien vers Raichu d’Alola'));
    await tester.pump();
    expect(otherForms(controller), ['gmax-inconnue']);
    expect(
      find.byKey(const ValueKey('species-form-candidate:raichu-alola')),
      findsOneWidget,
    );
    controller.dispose();
  });

  testWidgets('raw identifiers remain available as an advanced option', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1400);
    addTearDown(tester.view.reset);
    final controller = await open(tester);
    final advanced = find.text('Identifiants avancés');
    await tester.ensureVisible(advanced);
    await tester.tap(advanced);
    await tester.pumpAndSettle();
    final field = find.byKey(const ValueKey('species-forms.otherForms'));
    expect(
      find.descendant(of: field, matching: find.text('alola, gmax-inconnue')),
      findsOneWidget,
    );
    controller.dispose();
  });

  testWidgets('typing raw identifiers keeps the advanced field focused', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1400);
    addTearDown(tester.view.reset);
    final controller = await open(tester);
    final advanced = find.text('Identifiants avancés');
    await tester.ensureVisible(advanced);
    await tester.tap(advanced);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('species-forms.otherForms')),
      'alola',
    );
    await tester.pump();
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'alola, mega',
        selection: TextSelection.collapsed(offset: 11),
      ),
    );
    await tester.pump();
    expect(otherForms(controller), ['alola', 'mega']);
    expect(find.text('Méga-Raichu'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('an expanded advanced section survives leaving the tab', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1400);
    addTearDown(tester.view.reset);
    final visible = ValueNotifier(true);
    final controller = await open(tester, visible: visible);
    final advanced = find.text('Identifiants avancés');
    await tester.ensureVisible(advanced);
    await tester.tap(advanced);
    await tester.pumpAndSettle();
    visible.value = false;
    await tester.pumpAndSettle();
    visible.value = true;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Autres formes associées'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('species-forms.otherForms')),
      findsOneWidget,
    );
    controller.dispose();
  });
}

final class _FormsPort implements PokemonWorkspacePort {
  @override
  Future<PokemonWorkspaceIndex> loadIndex() async => PokemonWorkspaceIndex(
    enabled: true,
    entries: [
      _summary('pikachu', 'Pikachu', formId: 'base'),
      _summary(
        'raichu',
        'Raichu',
        formId: 'base',
        otherForms: ['alola', 'gmax-inconnue'],
      ),
      _summary(
        'raichu-alola',
        'Raichu d’Alola',
        formId: 'alola',
        baseFormId: 'raichu',
        otherForms: ['base'],
      ),
      _summary(
        'raichu-mega',
        'Méga-Raichu',
        formId: 'mega',
        baseFormId: 'raichu',
      ),
    ],
    moves: const PokemonMovesCatalogView(entries: [], relativePath: ''),
    types: [],
    items: {},
  );

  @override
  Future<PokemonSpeciesBundle> loadSpecies(PokemonSpeciesSummary entry) async =>
      PokemonSpeciesBundle(
        species: PokemonDocumentSource(
          family: PokemonDocumentFamily.species,
          relativePath: entry.relativePath,
          bytes: null,
          document: {
            'id': entry.id,
            'forms': {
              'baseFormId': entry.id,
              'formId': entry.formId,
              'isBaseForm': true,
              'otherForms': ['alola', 'gmax-inconnue'],
            },
          },
        ),
        learnset: null,
        evolution: null,
        media: null,
      );

  @override
  Future<Uint8List?> loadThumbnail(PokemonSpeciesSummary entry) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PokemonSpeciesSummary _summary(
  String id,
  String name, {
  required String formId,
  String? baseFormId,
  List<String> otherForms = const [],
}) => PokemonSpeciesSummary(
  id: id,
  name: name,
  nationalDex: 26,
  generation: 1,
  types: const [],
  formIds: [formId, ...otherForms],
  formId: formId,
  baseFormId: baseFormId ?? id,
  isBaseForm: baseFormId == null,
  mediaRelativePath: '',
  enabled: true,
  relativePath: '$id.json',
);
