import 'package:map_core/map_core.dart';

export 'package:map_core/map_core.dart'
    show
        ElementAutoShadowBackfillEntry,
        ElementAutoShadowBackfillResult,
        ElementAutoShadowBackfillStatus,
        applyElementAutoShadowPolicyToProject;

ElementAutoShadowBackfillResult applyElementAutoShadowSuggestionsToProject(
  ProjectManifest project,
) {
  return applyElementAutoShadowPolicyToProject(project);
}
