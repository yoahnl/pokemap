import 'package:map_core/map_core_domain.dart';

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
    story || events || world || verification => const {
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

ProjectManifest mergeProjectMetadataSections(
  ProjectManifest current,
  ProjectManifest loaded,
  Set<String> fields, {
  Map<String, Set<String>>? documentIds,
}) {
  List<T> documents<T>(
    String field,
    List<T> before,
    List<T> after,
    String Function(T) id,
  ) {
    final selected = documentIds?[field];
    if (selected == null) return after;
    final replacements = {for (final value in after) id(value): value};
    return [
      for (final value in before)
        if (!selected.contains(id(value)))
          value
        else
          ?replacements.remove(id(value)),
      ...replacements.values,
    ];
  }

  NarrativeEventRegistry? registry() {
    final next = loaded.eventRegistry;
    if (documentIds?['eventRegistry'] == null || next == null) return next;
    return NarrativeEventRegistry(schemaVersion: next.schemaVersion, mode: next.mode,
        records: documents('eventRegistry', current.eventRegistry?.records ?? const [],
            next.records, (value) => value.id),
        legacyClaims: current.eventRegistry?.legacyClaims ?? next.legacyClaims);
  }

  return current.copyWith(
    maps: fields.contains('maps')
        ? documents('maps', current.maps, loaded.maps, (value) => value.id)
        : current.maps,
    groups: fields.contains('groups')
        ? documents(
            'groups',
            current.groups,
            loaded.groups,
            (value) => value.id,
          )
        : current.groups,
    encounterTables: fields.contains('encounterTables')
        ? documents(
            'encounterTables',
            current.encounterTables,
            loaded.encounterTables,
            (value) => value.id,
          )
        : current.encounterTables,
    characterStudioCatalog: fields.contains('characterStudioCatalog')
        ? loaded.characterStudioCatalog
        : current.characterStudioCatalog,
    dialogueFolders: fields.contains('dialogueFolders')
        ? documents(
            'dialogueFolders',
            current.dialogueFolders,
            loaded.dialogueFolders,
            (value) => value.id,
          )
        : current.dialogueFolders,
    dialogues: fields.contains('dialogues')
        ? documents(
            'dialogues',
            current.dialogues,
            loaded.dialogues,
            (value) => value.id,
          )
        : current.dialogues,
    scripts: fields.contains('scripts')
        ? documents(
            'scripts',
            current.scripts,
            loaded.scripts,
            (value) => value.id,
          )
        : current.scripts,
    scenarios: fields.contains('scenarios')
        ? documents(
            'scenarios',
            current.scenarios,
            loaded.scenarios,
            (value) => value.id,
          )
        : current.scenarios,
    cinematics: fields.contains('cinematics')
        ? documents(
            'cinematics',
            current.cinematics,
            loaded.cinematics,
            (value) => value.id,
          )
        : current.cinematics,
    cinematicLibraryCatalog: fields.contains('cinematicLibraryCatalog')
        ? loaded.cinematicLibraryCatalog
        : current.cinematicLibraryCatalog,
    presentationCinematics: fields.contains('presentationCinematics')
        ? documents(
            'presentationCinematics',
            current.presentationCinematics,
            loaded.presentationCinematics,
            (value) => value.id,
          )
        : current.presentationCinematics,
    cinematicMediaAssets: fields.contains('cinematicMediaAssets')
        ? documents(
            'cinematicMediaAssets',
            current.cinematicMediaAssets,
            loaded.cinematicMediaAssets,
            (value) => value.id,
          )
        : current.cinematicMediaAssets,
    facts: fields.contains('facts')
        ? documents('facts', current.facts, loaded.facts, (value) => value.id)
        : current.facts,
    worldRules: fields.contains('worldRules')
        ? documents(
            'worldRules',
            current.worldRules,
            loaded.worldRules,
            (value) => value.id,
          )
        : current.worldRules,
    narrativeDiagnosticSuppressions:
        fields.contains('narrativeDiagnosticSuppressions')
        ? documents(
            'narrativeDiagnosticSuppressions',
            current.narrativeDiagnosticSuppressions,
            loaded.narrativeDiagnosticSuppressions,
            (value) => value.diagnosticId,
          )
        : current.narrativeDiagnosticSuppressions,
    runtimeSmokeProfile: fields.contains('runtimeSmokeProfile')
        ? loaded.runtimeSmokeProfile
        : current.runtimeSmokeProfile,
    eventRegistry: fields.contains('eventRegistry') ? registry() : current.eventRegistry,
    scenes: fields.contains('scenes')
        ? documents(
            'scenes',
            current.scenes,
            loaded.scenes,
            (value) => value.id,
          )
        : current.scenes,
    storylines: fields.contains('storylines')
        ? documents(
            'storylines',
            current.storylines,
            loaded.storylines,
            (value) => value.id,
          )
        : current.storylines,
    railJourneyCatalog: fields.contains('railJourneyCatalog')
        ? loaded.railJourneyCatalog
        : current.railJourneyCatalog,
    shops: fields.contains('shops')
        ? documents('shops', current.shops, loaded.shops, (value) => value.id)
        : current.shops,
    badges: fields.contains('badges')
        ? documents(
            'badges',
            current.badges,
            loaded.badges,
            (value) => value.id,
          )
        : current.badges,
    trainers: fields.contains('trainers')
        ? documents(
            'trainers',
            current.trainers,
            loaded.trainers,
            (value) => value.id,
          )
        : current.trainers,
    settings: fields.contains('settings') ? loaded.settings : current.settings,
    battleAudio: fields.contains('battleAudio')
        ? loaded.battleAudio
        : current.battleAudio,
    battleTransitions: fields.contains('battleTransitions')
        ? loaded.battleTransitions
        : current.battleTransitions,
    pokemon: fields.contains('pokemon') ? loaded.pokemon : current.pokemon,
    partyCompanion: fields.contains('partyCompanion')
        ? loaded.partyCompanion
        : current.partyCompanion,
    contactDevice: fields.contains('contactDevice')
        ? loaded.contactDevice
        : current.contactDevice,
    newGame: fields.contains('newGame') ? loaded.newGame : current.newGame,
    defeatRecovery: fields.contains('defeatRecovery')
        ? loaded.defeatRecovery
        : current.defeatRecovery,
    battleSavings: fields.contains('battleSavings') ? loaded.battleSavings : current.battleSavings,
    bagCapacity: fields.contains('bagCapacity')
        ? loaded.bagCapacity
        : current.bagCapacity,
    presentation: fields.contains('presentation')
        ? loaded.presentation
        : current.presentation,
    regionalMap: fields.contains('regionalMap')
        ? loaded.regionalMap
        : current.regionalMap,
    presentationPresets: fields.contains('presentationPresets')
        ? documents(
            'presentationPresets',
            current.presentationPresets,
            loaded.presentationPresets,
            (value) => value.id,
          )
        : current.presentationPresets,
    resourcePackInstallations: fields.contains('resourcePackInstallations')
        ? loaded.resourcePackInstallations
        : current.resourcePackInstallations,
    globalProperties: fields.contains('globalProperties')
        ? loaded.globalProperties
        : current.globalProperties,
  );
}

ProjectManifest mergeResourceSelection(
  ProjectManifest current,
  ProjectManifest loaded,
) => current.copyWith(
  tilesets: loaded.tilesets,
  elements: loaded.elements,
  models3d: loaded.models3d,
  characters: loaded.characters,
  environmentPresets: loaded.environmentPresets,
  smartTileCatalog: loaded.smartTileCatalog,
  borderCatalog: loaded.borderCatalog,
  elementCategories: loaded.elementCategories,
  tilesetFolders: loaded.tilesetFolders,
  characterStudioCatalog: loaded.characterStudioCatalog,
  resourceLibraryCatalog: loaded.resourceLibraryCatalog,
);

ProjectManifest combineResourceVisuals(
  ProjectManifest map,
  ProjectManifest family,
) {
  List<T> union<T>(List<T> before, List<T> after, String Function(T) key) => {
    for (final value in before) key(value): value,
    for (final value in after) key(value): value,
  }.values.toList();
  return map.copyWith(
    tilesets: union(map.tilesets, family.tilesets, (value) => value.id),
    elements: union(map.elements, family.elements, (value) => value.id),
    models3d: union(map.models3d, family.models3d, (value) => value.id),
    characters: union(map.characters, family.characters, (value) => value.id),
    environmentPresets: union(
      map.environmentPresets,
      family.environmentPresets,
      (value) => value.id,
    ),
    smartTileCatalog: ProjectSmartTileCatalog(
      categories: union(
        map.smartTileCatalog.categories,
        family.smartTileCatalog.categories,
        (value) => value.id,
      ),
      atlases: union(
        map.smartTileCatalog.atlases,
        family.smartTileCatalog.atlases,
        (value) => value.id,
      ),
      materials: union(
        map.smartTileCatalog.materials,
        family.smartTileCatalog.materials,
        (value) => value.id,
      ),
      animations: union(
        map.smartTileCatalog.animations,
        family.smartTileCatalog.animations,
        (value) => value.id,
      ),
      presets: union(
        map.smartTileCatalog.presets,
        family.smartTileCatalog.presets,
        (value) => value.id,
      ),
      patterns: union(
        map.smartTileCatalog.patterns,
        family.smartTileCatalog.patterns,
        (value) => value.id,
      ),
      drafts: union(
        map.smartTileCatalog.drafts,
        family.smartTileCatalog.drafts,
        (value) => value.id,
      ),
    ),
    borderCatalog: ProjectBorderCatalog(
      formatVersion:
          map.borderCatalog.formatVersion > family.borderCatalog.formatVersion
          ? map.borderCatalog.formatVersion
          : family.borderCatalog.formatVersion,
      records: union(
        map.borderCatalog.records,
        family.borderCatalog.records,
        (value) => value.id,
      ),
      visualSnapshots: union(
        map.borderCatalog.visualSnapshots,
        family.borderCatalog.visualSnapshots,
        (value) => value.id,
      ),
    ),
  );
}
