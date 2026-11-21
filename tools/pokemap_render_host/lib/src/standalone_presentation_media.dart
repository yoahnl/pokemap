import 'package:map_player_ui/presentation_renderer.dart';

/// The standalone host's Presentation media façade — BETA-CIN-082.
///
/// The resolution itself is shared: BETA-CIN-080 moved it into map_player_ui so
/// the Studio preview reads a project directory through the very same rules the
/// host was certified on, instead of a second resolver free to drift.
typedef StandalonePresentationMedia = ProjectDirectoryPresentationMedia;
typedef StandalonePresentationMediaException =
    ProjectDirectoryPresentationMediaException;

Future<StandalonePresentationMedia?> loadStandalonePresentationMedia({
  required String projectRootDirectory,
}) =>
    loadProjectDirectoryPresentationMedia(
      projectRootDirectory: projectRootDirectory,
    );
