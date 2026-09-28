import 'package:map_core/map_core_domain.dart';
import 'character_studio_draft.dart';

String? characterStudioFrameBoundsProblem(
  ProjectManifest project,
  CharacterStudioDraft draft,
) {
  final source = project.tilesets
      .where((entry) => entry.id == draft.saved.tilesetId)
      .firstOrNull
      ?.source;
  if (source is! ProjectRegularAtlasTilesetSource) return null;
  final preview = draft.previewCharacter;
  final width =
      preview.frameWidth.clamp(2, 1 << 20) * project.settings.tileWidth;
  final height =
      preview.frameHeight.clamp(2, 1 << 20) * project.settings.tileHeight;
  for (final clip in preview.animations) {
    if (clip.sourceAssetId != null) continue;
    for (final frame in clip.frames) {
      if ((frame.source.x + 1) * width > source.pixelWidth ||
          (frame.source.y + 1) * height > source.pixelHeight) {
        return 'Une pose sort de la planche avec cette grille. Ajustez la taille ou réattribuez la pose.';
      }
    }
  }
  return null;
}
