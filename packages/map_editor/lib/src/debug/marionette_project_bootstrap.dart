import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../application/models/narrative_event_authoring_session.dart';
import '../features/editor/state/editor_state.dart';

/// Immutable, prevalidated project seed used only by the Marionette entrypoint.
///
/// Loading happens before `runApp`, so desktop QA never races the editor's
/// remembered-project restoration and never interacts with an uncertain root.
final class MarionetteProjectBootstrap {
  const MarionetteProjectBootstrap._({
    required this.projectRootPath,
    required this.manifest,
  });

  static const projectPathDefine = 'MARIONETTE_PROJECT_PATH';

  final String projectRootPath;
  final ProjectManifest manifest;

  /// Resolves and validates the required debug project root synchronously.
  ///
  /// Synchronous I/O is intentional here: any missing, unreadable, symlinked,
  /// or invalid project aborts before Flutter can render an interactive frame.
  static MarionetteProjectBootstrap load(String configuredProjectPath) {
    final trimmed = configuredProjectPath.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(
        configuredProjectPath,
        projectPathDefine,
        'A deterministic project root is required for desktop QA.',
      );
    }

    final requestedRoot = p.normalize(p.absolute(trimmed));
    final directory = Directory(requestedRoot);
    if (!directory.existsSync()) {
      throw StateError(
          'Marionette project root does not exist: $requestedRoot');
    }

    final resolvedRoot = p.normalize(directory.resolveSymbolicLinksSync());
    if (resolvedRoot != requestedRoot) {
      throw StateError(
        'Marionette project root resolved to a different path: '
        '$requestedRoot -> $resolvedRoot',
      );
    }

    final manifestFile = File(p.join(resolvedRoot, 'project.json'));
    if (!manifestFile.existsSync()) {
      throw StateError(
        'Marionette project manifest does not exist: ${manifestFile.path}',
      );
    }

    final decoded = decodeValidatedNarrativeEventAuthoringProject(
      manifestFile.readAsBytesSync(),
    );
    return MarionetteProjectBootstrap._(
      projectRootPath: resolvedRoot,
      manifest: decoded.manifest,
    );
  }

  /// Produces the exact editor state exposed to the real shell on first frame.
  ///
  /// A non-null project also makes production auto-restore exit immediately,
  /// preserving the debug bootstrap as the single project source of truth.
  EditorState createInitialState() {
    return EditorState(
      projectRootPath: projectRootPath,
      project: manifest,
      workspaceMode: EditorWorkspaceMode.map,
      statusMessage: 'Projet QA « ${manifest.name} » chargé',
    );
  }
}
