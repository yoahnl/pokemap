import 'package:flutter/material.dart';
import 'package:map_player_ui/personalization_preview.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

void main() {
  MarionetteBinding.ensureInitialized();
  const stateName = String.fromEnvironment(
    'OW_PREVIEW_STATE',
    defaultValue: 'interaction',
  );
  const backdropName = String.fromEnvironment(
    'OW_PREVIEW_BACKDROP',
    defaultValue: 'busy',
  );
  const scale = String.fromEnvironment(
    'OW_PREVIEW_TEXT_SCALE',
    defaultValue: '1',
  );
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PlayerOverworldPrimitivesGallery(
        state: PlayerOverworldGalleryState.values.firstWhere(
          (value) => value.name == stateName,
          orElse: () => PlayerOverworldGalleryState.interaction,
        ),
        backdrop: PlayerOverworldGalleryBackdrop.values.firstWhere(
          (value) => value.name == backdropName,
          orElse: () => PlayerOverworldGalleryBackdrop.busy,
        ),
        actionLabel: 'Parler',
        textScale: double.tryParse(scale) ?? 1,
        opaque: const bool.fromEnvironment('OW_PREVIEW_OPAQUE'),
        reducedMotion: const bool.fromEnvironment('OW_PREVIEW_REDUCED_MOTION'),
      ),
    ),
  );
}
