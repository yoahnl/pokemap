import 'dart:typed_data';

import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_controller.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_port.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_species_media.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<(PokemonWorkspaceController, _MediaPort)> open(
    WidgetTester tester,
  ) async {
    final port = _MediaPort();
    final tick = ValueNotifier(0);
    final controller = PokemonWorkspaceController(
      port,
      changed: () => tick.value++,
    );
    await tester.runAsync(controller.load);
    await tester.runAsync(() => controller.selectSpecies('bulbasaur'));
    tester.view.physicalSize = const Size(1600, 2400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ValueListenableBuilder<int>(
              valueListenable: tick,
              builder: (_, _, _) => PokemonSpeciesMediaEditor(
                controller: controller,
                pickPng: () async => '/tmp/picked.png',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return (controller, port);
  }

  Finder roleCard(String role) => find.byKey(ValueKey('media-role-$role'));

  testWidgets('role cards report the checked file state, not a promise', (
    tester,
  ) async {
    final (controller, port) = await open(tester);
    expect(
      find.descendant(
        of: roleCard('icon'),
        matching: find.text('Fichier présent'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: roleCard('party'),
        matching: find.text('Fichier introuvable'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: roleCard('portrait'),
        matching: find.text('Non associé'),
      ),
      findsOneWidget,
    );
    expect(find.text('Référence associée'), findsNothing);
    expect(port.probed, {'a/icon.png', 'a/party.png', 'a/front.png'});
    controller.dispose();
  });

  testWidgets('an associated role never offers a replacement it cannot do', (
    tester,
  ) async {
    final (controller, _) = await open(tester);
    expect(find.textContaining('Importer PNG'), findsNothing);
    expect(find.textContaining('Ajouter un PNG ·'), findsNothing);
    expect(find.text('Remplacer'), findsNothing);
    expect(
      find.textContaining('Remplacer n’est pas disponible'),
      findsOneWidget,
    );
    controller.dispose();
  });

  testWidgets('a referenced but missing file is named as such', (tester) async {
    final (controller, _) = await open(tester);
    await tester.tap(roleCard('party'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Image d’équipe'), findsWidgets);
    expect(
      find.textContaining('aucun fichier n’existe à cet emplacement'),
      findsOneWidget,
    );
    controller.dispose();
  });

  testWidgets('an empty role is added with a localized label', (tester) async {
    final (controller, _) = await open(tester);
    await tester.tap(roleCard('portrait'));
    await tester.pump();
    expect(find.text('Ajouter un PNG · Portrait'), findsOneWidget);
    expect(find.textContaining('· icon'), findsNothing);
    expect(find.textContaining('· party'), findsNothing);
    controller.dispose();
  });

  testWidgets('typing a first path keeps the same field focused', (
    tester,
  ) async {
    final (controller, _) = await open(tester);
    await tester.tap(roleCard('portrait'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('media-variants.base.portrait')),
      'a',
    );
    await tester.pump();
    await tester.pump();
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'ab',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    await tester.pump();
    await tester.pump();
    final variants =
        controller.selectedDraft!.document(
              PokemonDocumentFamily.media,
            )!['variants']
            as Map;
    expect((variants['base'] as Map)['portrait'], 'ab');
    expect(find.textContaining('Ajouter un PNG ·'), findsNothing);
    controller.dispose();
  });

  test('role labels are localized for every supported role', () {
    for (final role in ['icon', 'party', 'portrait']) {
      expect(pokemonMediaRoleLabel(role), isNot(role));
    }
    expect(pokemonMediaRoleLabel('icon'), 'Icône');
    expect(pokemonMediaRoleLabel('party'), 'Image d’équipe');
  });
}

final class _MediaPort implements PokemonWorkspacePort {
  final probed = <String>{};

  @override
  Future<PokemonWorkspaceIndex> loadIndex() async => PokemonWorkspaceIndex(
    enabled: true,
    entries: const [
      PokemonSpeciesSummary(
        id: 'bulbasaur',
        name: 'Bulbizarre',
        nationalDex: 1,
        generation: 1,
        types: [],
        formIds: ['base'],
        formId: 'base',
        mediaRelativePath: 'media/bulbasaur.json',
        enabled: true,
        relativePath: 'bulbasaur.json',
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
            'refs': {'media': 'bulbasaur'},
          },
        ),
        learnset: null,
        evolution: null,
        media: PokemonDocumentSource(
          family: PokemonDocumentFamily.media,
          relativePath: 'media/bulbasaur.json',
          bytes: null,
          document: {
            'speciesId': 'bulbasaur',
            'defaultFormId': 'base',
            'variants': {
              'base': {
                'icon': 'a/icon.png',
                'party': 'a/party.png',
                'frontStatic': 'a/front.png',
              },
            },
          },
        ),
      );

  @override
  Future<PokemonMediaFileStatus> probeMedia(String relativePath) async {
    probed.add(relativePath);
    return relativePath == 'a/party.png'
        ? PokemonMediaFileStatus.missing
        : PokemonMediaFileStatus.present;
  }

  @override
  Future<Uint8List?> loadImage(String relativePath) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
