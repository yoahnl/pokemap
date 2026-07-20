import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/cinematics/builder/cinematic_media_picker.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('filters by media kind and exposes readable labels only',
      (tester) async {
    CinematicMediaAsset? selected;
    final sound = CinematicMediaAsset(
      id: 'snd_harbor_bell',
      label: 'Cloche du port',
      kind: CinematicMediaAssetKind.sound,
      relativePath: 'private/audio/harbor_bell.ogg',
    );
    final music = CinematicMediaAsset(
      id: 'music_mist',
      label: 'Brume matinale',
      kind: CinematicMediaAssetKind.music,
      relativePath: 'private/audio/mist.ogg',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: CinematicMediaPicker(
            label: 'Son',
            expectedKind: CinematicMediaAssetKind.sound,
            assets: [sound, music],
            value: sound.id,
            onChanged: (asset) => selected = asset,
          ),
        ),
      ),
    );

    final dropdown = tester.widget<PokeMapDropdownField<String>>(
      find.byType(PokeMapDropdownField<String>),
    );
    expect(dropdown.items.map((item) => item.label), ['Cloche du port']);
    expect(find.text('private/audio/harbor_bell.ogg'), findsNothing);
    expect(find.text('snd_harbor_bell'), findsNothing);
    dropdown.onChanged(sound.id);
    expect(selected, same(sound));
  });

  testWidgets('explains an empty typed library without a free-id field',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: CinematicMediaPicker(
            label: 'Musique',
            expectedKind: CinematicMediaAssetKind.music,
            assets: const [],
            value: null,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.textContaining('Aucun morceau'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}
