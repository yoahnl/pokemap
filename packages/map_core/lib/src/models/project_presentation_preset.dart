import 'project_presentation_profile.dart';
import 'project_presentation_layout_profile.dart';

enum ProjectPresentationPresetScope {
  complete,
  globalStyle,
  title,
  intro,
  pause,
  dialogue,
  battle,
}

Set<String> projectPresentationPresetSectionsForScope(
  ProjectPresentationPresetScope scope,
) => switch (scope) {
  ProjectPresentationPresetScope.complete => const <String>{},
  ProjectPresentationPresetScope.globalStyle => const <String>{
    'theme',
    'surfacePalettes',
    'typography',
    'windows',
  },
  ProjectPresentationPresetScope.title => const <String>{
    'branding',
    'title',
    'titleMotion',
    'layouts.title',
  },
  ProjectPresentationPresetScope.intro => const <String>{'intro'},
  ProjectPresentationPresetScope.pause => const <String>{
    'pause',
    'menuLabels',
    'layouts.pauseMenu',
  },
  ProjectPresentationPresetScope.dialogue => const <String>{
    'dialogue',
    'layouts.dialogue',
  },
  ProjectPresentationPresetScope.battle => const <String>{
    'battle',
    'layouts.battle',
  },
};

Set<String> projectPresentationPresetConfiguredSections(
  ProjectPresentationProfile profile,
  ProjectPresentationPresetScope scope,
) => switch (scope) {
  ProjectPresentationPresetScope.complete => const <String>{},
  ProjectPresentationPresetScope.globalStyle => <String>{
    if (profile.theme != null) 'theme',
    if (profile.surfacePalettes != null) 'surfacePalettes',
    if (profile.typography != null) 'typography',
    if (profile.windows != null) 'windows',
  },
  ProjectPresentationPresetScope.title => <String>{
    if (profile.branding != const ProjectBrandingProfile()) 'branding',
    if (profile.title != null) 'title',
    if (profile.titleMotion != null) 'titleMotion',
    if (profile.layouts != null) 'layouts.title',
  },
  ProjectPresentationPresetScope.intro => <String>{
    if (profile.intro != null) 'intro',
  },
  ProjectPresentationPresetScope.pause => <String>{
    if (profile.pause != null) 'pause',
    if (profile.menuLabels != null) 'menuLabels',
    if (profile.layouts != null) 'layouts.pauseMenu',
  },
  ProjectPresentationPresetScope.dialogue => <String>{
    if (profile.dialogue != null) 'dialogue',
    if (profile.layouts != null) 'layouts.dialogue',
  },
  ProjectPresentationPresetScope.battle => <String>{
    if (profile.battle != null) 'battle',
    if (profile.layouts?.battle != null) 'layouts.battle',
  },
};

bool projectPresentationPresetSectionsAreValid({
  required ProjectPresentationProfile profile,
  required ProjectPresentationPresetScope scope,
  required Iterable<String> sections,
}) {
  if (scope == ProjectPresentationPresetScope.complete) return true;
  final declared = sections.toSet();
  final allowed = projectPresentationPresetSectionsForScope(scope);
  final configured = projectPresentationPresetConfiguredSections(
    profile,
    scope,
  );
  return declared.isNotEmpty &&
      allowed.containsAll(declared) &&
      declared.containsAll(configured);
}

bool projectPresentationPresetScopeHasContent(
  ProjectPresentationProfile profile,
  ProjectPresentationPresetScope scope,
) => switch (scope) {
  ProjectPresentationPresetScope.complete => true,
  ProjectPresentationPresetScope.globalStyle =>
    profile.theme != null ||
        profile.surfacePalettes != null ||
        profile.typography != null ||
        profile.windows != null,
  ProjectPresentationPresetScope.title =>
    profile.title != null ||
        profile.titleMotion != null ||
        profile.branding != const ProjectBrandingProfile() ||
        profile.layouts != null,
  ProjectPresentationPresetScope.intro => profile.intro != null,
  ProjectPresentationPresetScope.pause =>
    profile.pause != null ||
        profile.menuLabels != null ||
        profile.layouts != null,
  ProjectPresentationPresetScope.dialogue =>
    profile.dialogue != null || profile.layouts != null,
  ProjectPresentationPresetScope.battle =>
    profile.battle != null || profile.layouts?.battle != null,
};

ProjectPresentationProfile applyProjectPresentationPresetScope({
  required ProjectPresentationProfile current,
  required ProjectPresentationProfile preset,
  required ProjectPresentationPresetScope scope,
}) => switch (scope) {
  ProjectPresentationPresetScope.complete => preset,
  ProjectPresentationPresetScope.globalStyle => current.copyWith(
    theme: preset.theme,
    surfacePalettes: preset.surfacePalettes,
    typography: preset.typography,
    windows: preset.windows,
  ),
  ProjectPresentationPresetScope.title => current.copyWith(
    branding: preset.branding,
    title: preset.title,
    titleMotion: preset.titleMotion,
    layouts: _replacePresetLayout(
      current.layouts,
      preset.layouts,
      ProjectPresentationPresetScope.title,
    ),
  ),
  ProjectPresentationPresetScope.intro => current.copyWith(intro: preset.intro),
  ProjectPresentationPresetScope.pause => current.copyWith(
    pause: preset.pause,
    menuLabels: preset.menuLabels,
    layouts: _replacePresetLayout(
      current.layouts,
      preset.layouts,
      ProjectPresentationPresetScope.pause,
    ),
  ),
  ProjectPresentationPresetScope.dialogue => current.copyWith(
    dialogue: preset.dialogue,
    layouts: _replacePresetLayout(
      current.layouts,
      preset.layouts,
      ProjectPresentationPresetScope.dialogue,
    ),
  ),
  ProjectPresentationPresetScope.battle => current.copyWith(
    battle: preset.battle,
    layouts: _replacePresetLayout(
      current.layouts,
      preset.layouts,
      ProjectPresentationPresetScope.battle,
    ),
  ),
};

ProjectPresentationProfile projectPresentationPresetProfileForScope({
  required ProjectPresentationProfile profile,
  required ProjectPresentationPresetScope scope,
}) => switch (scope) {
  ProjectPresentationPresetScope.complete => profile,
  ProjectPresentationPresetScope.globalStyle => ProjectPresentationProfile(
    theme: profile.theme,
    surfacePalettes: profile.surfacePalettes,
    typography: profile.typography,
    windows: profile.windows,
  ),
  ProjectPresentationPresetScope.title => ProjectPresentationProfile(
    branding: profile.branding,
    title: profile.title,
    titleMotion: profile.titleMotion,
    layouts: _projectPresetLayouts(profile, scope),
  ),
  ProjectPresentationPresetScope.intro => ProjectPresentationProfile(
    intro: profile.intro,
  ),
  ProjectPresentationPresetScope.pause => ProjectPresentationProfile(
    pause: profile.pause,
    menuLabels: profile.menuLabels,
    layouts: _projectPresetLayouts(profile, scope),
  ),
  ProjectPresentationPresetScope.dialogue => ProjectPresentationProfile(
    dialogue: profile.dialogue,
    layouts: _projectPresetLayouts(profile, scope),
  ),
  ProjectPresentationPresetScope.battle => ProjectPresentationProfile(
    battle: profile.battle,
    layouts: _projectPresetLayouts(profile, scope),
  ),
};

ProjectPresentationLayoutsProfile? _projectPresetLayouts(
  ProjectPresentationProfile profile,
  ProjectPresentationPresetScope scope,
) {
  final layouts = profile.layouts;
  if (layouts == null) return null;
  final base = suggestedProjectPresentationLayouts('standard');
  return switch (scope) {
    ProjectPresentationPresetScope.title => base.copyWith(title: layouts.title),
    ProjectPresentationPresetScope.pause => base.copyWith(
      pauseMenu: layouts.pauseMenu,
    ),
    ProjectPresentationPresetScope.dialogue => base.copyWith(
      dialogue: layouts.dialogue,
    ),
    ProjectPresentationPresetScope.battle => base.copyWith(
      battle: layouts.battle,
    ),
    _ => null,
  };
}

ProjectPresentationLayoutsProfile? _replacePresetLayout(
  ProjectPresentationLayoutsProfile? current,
  ProjectPresentationLayoutsProfile? preset,
  ProjectPresentationPresetScope scope,
) {
  if (preset == null) return current;
  final base = current ?? suggestedProjectPresentationLayouts('standard');
  return switch (scope) {
    ProjectPresentationPresetScope.title => base.copyWith(title: preset.title),
    ProjectPresentationPresetScope.pause => base.copyWith(
      pauseMenu: preset.pauseMenu,
    ),
    ProjectPresentationPresetScope.dialogue => base.copyWith(
      dialogue: preset.dialogue,
    ),
    ProjectPresentationPresetScope.battle => base.copyWith(
      battle: preset.battle,
    ),
    _ => base,
  };
}

final class ProjectPresentationPresetAssetReference {
  const ProjectPresentationPresetAssetReference({
    required this.projectPath,
    required this.mediaType,
    required this.sizeBytes,
    required this.sha256,
    required this.licenseProjectPath,
  });

  factory ProjectPresentationPresetAssetReference.fromJson(
    Map<String, dynamic> json,
  ) {
    _requireKeys(json, const <String>{
      'projectPath',
      'mediaType',
      'sizeBytes',
      'sha256',
      'licenseProjectPath',
    });
    final sizeBytes = json['sizeBytes'];
    if (sizeBytes is! int || sizeBytes < 1) {
      throw const FormatException('Invalid presentation preset asset size.');
    }
    final sha256 = _string(json['sha256'], 'sha256');
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(sha256)) {
      throw const FormatException(
        'Invalid presentation preset asset checksum.',
      );
    }
    return ProjectPresentationPresetAssetReference(
      projectPath: _projectPath(json['projectPath'], 'projectPath'),
      mediaType: _mediaType(json['mediaType']),
      sizeBytes: sizeBytes,
      sha256: sha256,
      licenseProjectPath: _projectPath(
        json['licenseProjectPath'],
        'licenseProjectPath',
      ),
    );
  }

  final String projectPath;
  final String mediaType;
  final int sizeBytes;
  final String sha256;
  final String licenseProjectPath;

  Map<String, Object?> toJson() => <String, Object?>{
    'projectPath': projectPath,
    'mediaType': mediaType,
    'sizeBytes': sizeBytes,
    'sha256': sha256,
    'licenseProjectPath': licenseProjectPath,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectPresentationPresetAssetReference &&
          other.projectPath == projectPath &&
          other.mediaType == mediaType &&
          other.sizeBytes == sizeBytes &&
          other.sha256 == sha256 &&
          other.licenseProjectPath == licenseProjectPath;

  @override
  int get hashCode => Object.hash(
    projectPath,
    mediaType,
    sizeBytes,
    sha256,
    licenseProjectPath,
  );
}

final class ProjectPresentationPresetRecord {
  const ProjectPresentationPresetRecord({
    required this.id,
    required this.label,
    required this.description,
    required this.profile,
    this.scope = ProjectPresentationPresetScope.complete,
    this.replacedSections = const <String>[],
    this.assets = const <ProjectPresentationPresetAssetReference>[],
  });

  factory ProjectPresentationPresetRecord.fromJson(Map<String, dynamic> json) {
    _requireKeys(
      json,
      const <String>{'id', 'label', 'description', 'profile', 'assets'},
      optional: const <String>{'scope', 'replacedSections'},
    );
    final id = _string(json['id'], 'id');
    final label = _string(json['label'], 'label');
    final description = _string(json['description'], 'description');
    final profile = json['profile'];
    final assets = json['assets'];
    final scope = _scope(json['scope']);
    final replacedSections = _sections(json['replacedSections']);
    if (!RegExp(r'^[a-z][a-z0-9-]{0,63}$').hasMatch(id) ||
        label.length > 64 ||
        description.length > 240 ||
        profile is! Map ||
        assets is! List) {
      throw const FormatException('Invalid presentation preset record.');
    }
    final decodedAssets = <ProjectPresentationPresetAssetReference>[];
    final projectPaths = <String>{};
    for (final raw in assets) {
      if (raw is! Map) {
        throw const FormatException('Invalid presentation preset asset.');
      }
      final asset = ProjectPresentationPresetAssetReference.fromJson(
        Map<String, dynamic>.from(raw),
      );
      if (!projectPaths.add(asset.projectPath)) {
        throw const FormatException(
          'Duplicate presentation preset asset path.',
        );
      }
      decodedAssets.add(asset);
    }
    decodedAssets.sort(
      (left, right) => left.projectPath.compareTo(right.projectPath),
    );
    final decodedProfile = ProjectPresentationProfile.fromJson(
      Map<String, dynamic>.from(profile),
    );
    if (!projectPresentationPresetScopeHasContent(decodedProfile, scope)) {
      throw const FormatException('Incomplete presentation preset scope.');
    }
    if (!projectPresentationPresetSectionsAreValid(
      profile: decodedProfile,
      scope: scope,
      sections: replacedSections,
    )) {
      throw const FormatException('Invalid presentation preset sections.');
    }
    return ProjectPresentationPresetRecord(
      id: id,
      label: label,
      description: description,
      profile: decodedProfile,
      scope: scope,
      replacedSections: replacedSections,
      assets: List<ProjectPresentationPresetAssetReference>.unmodifiable(
        decodedAssets,
      ),
    );
  }

  final String id;
  final String label;
  final String description;
  final ProjectPresentationProfile profile;
  final ProjectPresentationPresetScope scope;
  final List<String> replacedSections;
  final List<ProjectPresentationPresetAssetReference> assets;

  ProjectPresentationProfile applyTo(ProjectPresentationProfile current) =>
      applyProjectPresentationPresetScope(
        current: current,
        preset: profile,
        scope: scope,
      );

  List<ProjectPresentationCategory> get configuredCategories =>
      List<ProjectPresentationCategory>.unmodifiable(
        profile.configuredCategories.toList()
          ..sort((left, right) => left.index.compareTo(right.index)),
      );

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'label': label,
    'description': description,
    'profile': profile.toJson(),
    if (scope != ProjectPresentationPresetScope.complete) 'scope': scope.name,
    if (replacedSections.isNotEmpty) 'replacedSections': replacedSections,
    'assets': <Object?>[for (final asset in assets) asset.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectPresentationPresetRecord &&
          other.id == id &&
          other.label == label &&
          other.description == description &&
          other.profile == profile &&
          other.scope == scope &&
          _listEquals(other.replacedSections, replacedSections) &&
          _listEquals(other.assets, assets);

  @override
  int get hashCode => Object.hash(
    id,
    label,
    description,
    profile,
    scope,
    Object.hashAll(replacedSections),
    Object.hashAll(assets),
  );
}

void _requireKeys(
  Map<String, dynamic> json,
  Set<String> expected, {
  Set<String> optional = const <String>{},
}) {
  if (json.keys.toSet().difference(<String>{
        ...expected,
        ...optional,
      }).isNotEmpty ||
      expected.difference(json.keys.toSet()).isNotEmpty) {
    throw const FormatException('Invalid presentation preset keys.');
  }
}

ProjectPresentationPresetScope _scope(Object? value) {
  if (value == null) return ProjectPresentationPresetScope.complete;
  if (value is! String) {
    throw const FormatException('Invalid presentation preset scope.');
  }
  return ProjectPresentationPresetScope.values.firstWhere(
    (scope) => scope.name == value,
    orElse: () =>
        throw const FormatException('Invalid presentation preset scope.'),
  );
}

List<String> _sections(Object? value) {
  if (value == null) return const <String>[];
  if (value is! List || value.any((section) => section is! String)) {
    throw const FormatException('Invalid presentation preset sections.');
  }
  final sections = value.cast<String>();
  if (sections.isEmpty ||
      sections.any(
        (section) => section.trim().isEmpty || section != section.trim(),
      ) ||
      sections.toSet().length != sections.length) {
    throw const FormatException('Invalid presentation preset sections.');
  }
  return List<String>.unmodifiable(sections);
}

String _string(Object? value, String field) {
  if (value is! String || value.trim().isEmpty || value != value.trim()) {
    throw FormatException('Invalid presentation preset $field.');
  }
  return value;
}

String _projectPath(Object? value, String field) {
  final path = _string(value, field);
  final segments = path.split('/');
  if (!path.startsWith('assets/') ||
      path.contains(r'\') ||
      segments.any(
        (segment) =>
            segment.isEmpty ||
            segment == '.' ||
            segment == '..' ||
            segment.startsWith('.'),
      )) {
    throw FormatException('Invalid presentation preset $field.');
  }
  return path;
}

String _mediaType(Object? value) {
  final mediaType = _string(value, 'mediaType');
  if (!RegExp(
    r'^[a-z0-9][a-z0-9!#$&^_.+-]*/[a-z0-9][a-z0-9!#$&^_.+-]*$',
  ).hasMatch(mediaType)) {
    throw const FormatException('Invalid presentation preset mediaType.');
  }
  return mediaType;
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
