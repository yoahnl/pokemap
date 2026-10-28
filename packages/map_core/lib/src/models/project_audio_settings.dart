enum ProjectSoundSource { builtin, silent, custom }

enum ProjectSoundCue {
  uiSelect('ui.select'),
  uiConfirm('ui.confirm'),
  uiCancel('ui.cancel'),
  uiError('ui.error'),
  dialogueAdvance('dialogue.advance'),
  notification('notification'),
  overworldStep('overworld.step'),
  overworldJump('overworld.jump'),
  doorOpen('door.open'),
  doorClose('door.close'),
  surfEnter('surf.enter'),
  surfExit('surf.exit'),
  fieldCut('field.cut'),
  fieldFly('field.fly'),
  fieldStrength('field.strength'),
  fieldFlash('field.flash'),
  fieldRockSmash('field.rock_smash'),
  fieldWaterfall('field.waterfall'),
  fieldWhirlpool('field.whirlpool'),
  fieldDive('field.dive'),
  fieldRockClimb('field.rock_climb'),
  fieldDefog('field.defog'),
  weatherRain('weather.rain'),
  weatherWind('weather.wind'),
  weatherThunder('weather.thunder'),
  fireCrackle('fire.crackle');

  const ProjectSoundCue(this.wireName);
  final String wireName;

  static ProjectSoundCue fromWireName(String value) => values.firstWhere(
    (cue) => cue.wireName == value,
    orElse: () => throw FormatException('Unknown sound cue "$value".'),
  );
}

final class ProjectSoundBinding {
  const ProjectSoundBinding({
    required this.source,
    this.mediaId,
    this.gain = 1,
  });

  final ProjectSoundSource source;
  final String? mediaId;
  final double gain;

  ProjectSoundBinding validated() {
    if (!gain.isFinite || gain < 0 || gain > 1) {
      throw const FormatException('Sound gain must be finite in 0..1.');
    }
    if (source == ProjectSoundSource.custom) {
      final id = mediaId;
      if (id == null ||
          id.isEmpty ||
          id.trim() != id ||
          !RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.-]*$').hasMatch(id)) {
        throw const FormatException('Custom sounds require a stable mediaId.');
      }
    } else if (mediaId != null) {
      throw const FormatException('Only custom sounds accept mediaId.');
    }
    return this;
  }

  factory ProjectSoundBinding.fromJson(Map<String, dynamic> json) {
    if (json.keys.any(
      (key) => !const {'source', 'mediaId', 'gain'}.contains(key),
    )) {
      throw const FormatException('Unknown sound binding field.');
    }
    final rawSource = json['source'];
    final sources = ProjectSoundSource.values.where(
      (source) => source.name == rawSource,
    );
    final rawGain = json.containsKey('gain') ? json['gain'] : 1;
    if (sources.isEmpty ||
        rawGain is! num ||
        json.containsKey('mediaId') && json['mediaId'] is! String) {
      throw const FormatException('Invalid sound binding.');
    }
    return ProjectSoundBinding(
      source: sources.single,
      mediaId: json['mediaId'] as String?,
      gain: rawGain.toDouble(),
    ).validated();
  }

  Map<String, dynamic> toJson() {
    validated();
    return {
      'source': source.name,
      if (mediaId != null) 'mediaId': mediaId,
      'gain': gain,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is ProjectSoundBinding &&
      source == other.source &&
      mediaId == other.mediaId &&
      gain == other.gain;
  @override
  int get hashCode => Object.hash(source, mediaId, gain);
}

final class ProjectAudioSettings {
  ProjectAudioSettings({
    Map<ProjectSoundCue, ProjectSoundBinding> cues = const {},
  }) : cues = Map.unmodifiable({
         for (final entry in cues.entries) entry.key: entry.value.validated(),
       });

  final Map<ProjectSoundCue, ProjectSoundBinding> cues;

  factory ProjectAudioSettings.fromJson(Map<String, dynamic> json) {
    if (json.keys.any((key) => key != 'cues')) {
      throw const FormatException('Unknown project audio setting.');
    }
    final raw = json.containsKey('cues') ? json['cues'] : const {};
    if (raw is! Map ||
        raw.keys.any((key) => key is! String) ||
        raw.values.any((value) => value is! Map)) {
      throw const FormatException('Sound cues must contain binding objects.');
    }
    return ProjectAudioSettings(
      cues: {
        for (final entry in raw.entries)
          ProjectSoundCue.fromWireName(
            entry.key as String,
          ): ProjectSoundBinding.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          ),
      },
    );
  }

  ProjectSoundBinding bindingFor(ProjectSoundCue cue) =>
      cues[cue] ??
      ProjectSoundBinding(
        source: ProjectSoundCueCatalog.forCue(cue).legacyBuiltin
            ? ProjectSoundSource.builtin
            : ProjectSoundSource.silent,
      );

  ProjectAudioSettings withCue(
    ProjectSoundCue cue,
    ProjectSoundBinding? binding,
  ) {
    final updated = {...cues}..remove(cue);
    if (binding != null) updated[cue] = binding;
    return ProjectAudioSettings(cues: updated);
  }

  Map<String, dynamic> toJson() => {
    'cues': {
      for (final cue in ProjectSoundCue.values)
        if (cues[cue] case final binding?) cue.wireName: binding.toJson(),
    },
  };

  @override
  bool operator ==(Object other) =>
      other is ProjectAudioSettings &&
      cues.length == other.cues.length &&
      cues.entries.every((entry) => other.cues[entry.key] == entry.value);
  @override
  int get hashCode =>
      Object.hashAll(ProjectSoundCue.values.map((cue) => cues[cue]));
}

final class ProjectSoundCueDescriptor {
  const ProjectSoundCueDescriptor(
    this.cue,
    this.label,
    this.group, {
    this.loop = false,
    this.legacyBuiltin = false,
  });
  final ProjectSoundCue cue;
  final String label;
  final String group;
  final bool loop;
  final bool legacyBuiltin;
  Map<String, Object?> toJson() => {
    'id': cue.wireName,
    'label': label,
    'group': group,
    'loop': loop,
    'legacyBuiltin': legacyBuiltin,
  };
}

abstract final class ProjectSoundCueCatalog {
  static const entries = [
    ProjectSoundCueDescriptor(
      ProjectSoundCue.uiSelect,
      'Déplacement du curseur',
      'Interface',
    ),
    ProjectSoundCueDescriptor(
      ProjectSoundCue.uiConfirm,
      'Validation',
      'Interface',
    ),
    ProjectSoundCueDescriptor(
      ProjectSoundCue.uiCancel,
      'Retour / annulation',
      'Interface',
    ),
    ProjectSoundCueDescriptor(
      ProjectSoundCue.uiError,
      'Action refusée',
      'Interface',
    ),
    ProjectSoundCueDescriptor(
      ProjectSoundCue.dialogueAdvance,
      'Avancer un dialogue',
      'Interface',
    ),
    ProjectSoundCueDescriptor(
      ProjectSoundCue.notification,
      'Notification',
      'Interface',
    ),
    ProjectSoundCueDescriptor(
      ProjectSoundCue.overworldStep,
      'Pas du joueur',
      'Déplacements',
    ),
    ProjectSoundCueDescriptor(
      ProjectSoundCue.overworldJump,
      'Saut',
      'Déplacements',
      legacyBuiltin: true,
    ),
    ProjectSoundCueDescriptor(
      ProjectSoundCue.doorOpen,
      'Ouverture de porte',
      'Déplacements',
    ),
    ProjectSoundCueDescriptor(
      ProjectSoundCue.doorClose,
      'Fermeture de porte',
      'Déplacements',
    ),
    ProjectSoundCueDescriptor(
      ProjectSoundCue.surfEnter,
      'Entrée en Surf',
      'Déplacements',
    ),
    ProjectSoundCueDescriptor(
      ProjectSoundCue.surfExit,
      'Sortie de Surf',
      'Déplacements',
    ),
    ProjectSoundCueDescriptor(
      ProjectSoundCue.fieldCut,
      'Couper',
      'Déplacements',
    ),
    ProjectSoundCueDescriptor(ProjectSoundCue.fieldFly, 'Vol', 'CS'),
    ProjectSoundCueDescriptor(ProjectSoundCue.fieldStrength, 'Force', 'CS'),
    ProjectSoundCueDescriptor(ProjectSoundCue.fieldFlash, 'Flash', 'CS'),
    ProjectSoundCueDescriptor(ProjectSoundCue.fieldRockSmash, 'Éclate-Roc', 'CS'),
    ProjectSoundCueDescriptor(ProjectSoundCue.fieldWaterfall, 'Cascade', 'CS'),
    ProjectSoundCueDescriptor(ProjectSoundCue.fieldWhirlpool, 'Siphon', 'CS'),
    ProjectSoundCueDescriptor(ProjectSoundCue.fieldDive, 'Plongée', 'CS'),
    ProjectSoundCueDescriptor(ProjectSoundCue.fieldRockClimb, 'Escalade · mécanique à venir', 'CS'),
    ProjectSoundCueDescriptor(ProjectSoundCue.fieldDefog, 'Anti-Brume · mécanique à venir', 'CS'),
    ProjectSoundCueDescriptor(
      ProjectSoundCue.weatherRain,
      'Pluie',
      'Météo',
      loop: true,
      legacyBuiltin: true,
    ),
    ProjectSoundCueDescriptor(
      ProjectSoundCue.weatherWind,
      'Vent',
      'Météo',
      loop: true,
      legacyBuiltin: true,
    ),
    ProjectSoundCueDescriptor(
      ProjectSoundCue.weatherThunder,
      'Tonnerre',
      'Météo',
      legacyBuiltin: true,
    ),
    ProjectSoundCueDescriptor(
      ProjectSoundCue.fireCrackle,
      'Crépitement du feu',
      'Ambiance',
      loop: true,
      legacyBuiltin: true,
    ),
  ];
  static ProjectSoundCueDescriptor forCue(ProjectSoundCue cue) =>
      entries.firstWhere((entry) => entry.cue == cue);

  static ProjectSoundCue forFieldAbilityId(String id) => switch (id) {
    'surf' => ProjectSoundCue.surfEnter,
    'cut' => ProjectSoundCue.fieldCut,
    'fly' => ProjectSoundCue.fieldFly,
    'strength' => ProjectSoundCue.fieldStrength,
    'flash' => ProjectSoundCue.fieldFlash,
    'rock_smash' => ProjectSoundCue.fieldRockSmash,
    'waterfall' => ProjectSoundCue.fieldWaterfall,
    'whirlpool' => ProjectSoundCue.fieldWhirlpool,
    'dive' => ProjectSoundCue.fieldDive,
    'rock_climb' => ProjectSoundCue.fieldRockClimb,
    'defog' => ProjectSoundCue.fieldDefog,
    _ => throw ArgumentError.value(id, 'id', 'Unknown field ability.'),
  };
}

bool projectAudioSourceMimeMatches(
  String sourceMediaType,
  String audioMediaType,
) =>
    audioMediaType.startsWith('audio/') &&
    (sourceMediaType == audioMediaType ||
        sourceMediaType == 'application/octet-stream');
