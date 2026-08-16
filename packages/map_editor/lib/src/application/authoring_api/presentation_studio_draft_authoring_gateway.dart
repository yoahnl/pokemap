import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';

import 'authoring_query_adapter.dart';

abstract interface class PresentationStudioDraftAuthoringGateway {
  Future<PresentationCinematicDraft> open(
    String projectRootPath, {
    required ProjectManifest expectedProject,
  });
}

final class CanonicalPresentationStudioDraftAuthoringGateway
    implements PresentationStudioDraftAuthoringGateway {
  CanonicalPresentationStudioDraftAuthoringGateway({
    required AuthoringQueryAdapter queries,
  }) : _queries = queries;

  final AuthoringQueryAdapter _queries;

  @override
  Future<PresentationCinematicDraft> open(
    String projectRootPath, {
    required ProjectManifest expectedProject,
  }) async {
    await _queries.invalidate(projectRootPath);
    final session = await _queries.open(projectRootPath);
    return session.presentationCinematicDraft(
      expectedProject: expectedProject,
      allowProjectedProject: true,
    );
  }
}
