import 'dart:convert';
import 'dart:typed_data';

import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_port.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_species_thumbnail.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

final class _ThumbnailPort implements PokemonWorkspacePort {
  @override
  Future<Uint8List?> loadThumbnail(PokemonSpeciesSummary entry) async =>
      _pixel;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('species thumbnails keep pixel art sharp (R11)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: PokemonSpeciesThumbnail(
            entry: const PokemonSpeciesSummary(
              id: 'pikachu',
              name: 'Pikachu',
              nationalDex: 25,
              generation: 1,
              types: ['electric'],
              formIds: [],
              mediaRelativePath: 'pokemon/pikachu.png',
              enabled: true,
              relativePath: '',
            ),
            port: _ThumbnailPort(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.filterQuality, FilterQuality.none);
  });
}
