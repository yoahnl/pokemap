import 'package:map_core/map_core_domain.dart';

import 'project_metadata_merge.dart';
import 'resource_selection_merge.dart';

export 'project_metadata_merge.dart';
export 'resource_selection_merge.dart';

enum MapWorkspaceWorkshop {
  resources,
  regionalMap,
  story,
  pokemon,
  scene,
  progression,
  events,
  dialogue,
  cinematic,
  presentation,
  world,
  verification,
  gameExport;

  Set<String> get metadataFields => switch (this) {
    resources => const {'resourcePackInstallations', 'globalProperties'},
    regionalMap => const {'regionalMap'},
    pokemon => const {
      'pokemon',
      'trainers',
      'encounterTables',
      'shops',
      'badges',
    },
    progression => const {'storylines', 'facts', 'scenes', 'eventRegistry'},
    dialogue => const {
      'dialogues',
      'dialogueFolders',
      'facts',
      'scenes',
      'storylines',
      'characterStudioCatalog',
    },
    cinematic => const {
      'characterStudioCatalog',
      'cinematics',
      'cinematicLibraryCatalog',
      'dialogues',
      'cinematicMediaAssets',
      'scenes',
    },
    presentation => const {
      'presentationCinematics',
      'cinematicLibraryCatalog',
      'scenes',
      'cinematicMediaAssets',
      'presentationPresets',
    },
    scene => const {
      'scenes',
      'facts',
      'storylines',
      'dialogues',
      'cinematics',
      'presentationCinematics',
      'cinematicMediaAssets',
      'trainers',
      'encounterTables',
      'shops',
      'badges',
      'pokemon',
      'eventRegistry',
    },
    events => const {
      'facts',
      'storylines',
      'scenes',
      'dialogues',
      'cinematics',
      'presentationCinematics',
      'eventRegistry',
      'worldRules',
      'scenarios',
      'narrativeDiagnosticSuppressions',
      'cinematicMediaAssets',
      'encounterTables',
      'badges',
    },
    story || world || verification => const {
      'facts',
      'storylines',
      'scenes',
      'dialogues',
      'cinematics',
      'presentationCinematics',
      'eventRegistry',
      'worldRules',
      'scenarios',
      'narrativeDiagnosticSuppressions',
    },
    gameExport => const {},
  };

  ProjectManifest merge(ProjectManifest current, ProjectManifest loaded) {
    final metadata = mergeProjectMetadataSections(
      current,
      loaded,
      metadataFields,
    );
    return this == dialogue || this == cinematic
        ? combineResourceVisuals(metadata, loaded)
        : metadata;
  }
}

