enum PresentationTemplateOrientation { landscape, portrait }

enum PresentationTemplateMediaKind { image, video, voice, soundEffect, music }

enum PresentationTemplateMediaVariantPolicy { responsiveFallback, shared }

enum PresentationCinematicTemplateErrorCode {
  unknownTemplate,
  unsupportedVersion,
}

final class PresentationCinematicTemplateException implements Exception {
  const PresentationCinematicTemplateException({
    required this.code,
    required this.message,
  });

  final PresentationCinematicTemplateErrorCode code;
  final String message;

  @override
  String toString() =>
      'PresentationCinematicTemplateException(${code.name}): $message';
}

final class PresentationTemplateComposition {
  PresentationTemplateComposition({
    required this.orientation,
    required this.aspectWidth,
    required this.aspectHeight,
  }) {
    if (aspectWidth < 1 || aspectHeight < 1) {
      throw ArgumentError.value(
        '$aspectWidth:$aspectHeight',
        'aspectRatio',
        'must be positive',
      );
    }
    final expected = switch (orientation) {
      PresentationTemplateOrientation.landscape => (16, 9),
      PresentationTemplateOrientation.portrait => (9, 16),
    };
    if (aspectWidth != expected.$1 || aspectHeight != expected.$2) {
      throw ArgumentError.value(
        '$aspectWidth:$aspectHeight',
        'aspectRatio',
        'must match the native ${orientation.name} composition',
      );
    }
  }

  factory PresentationTemplateComposition.fromJson(Map<String, Object?> json) {
    _rejectUnknownKeys(json, const <String>{
      'orientation',
      'aspectWidth',
      'aspectHeight',
    }, 'composition');
    return PresentationTemplateComposition(
      orientation: _enumByName(
        PresentationTemplateOrientation.values,
        json['orientation'],
        'composition.orientation',
      ),
      aspectWidth: _integer(json['aspectWidth'], 'composition.aspectWidth'),
      aspectHeight: _integer(json['aspectHeight'], 'composition.aspectHeight'),
    );
  }

  final PresentationTemplateOrientation orientation;
  final int aspectWidth;
  final int aspectHeight;

  Map<String, Object?> toJson() => <String, Object?>{
    'orientation': orientation.name,
    'aspectWidth': aspectWidth,
    'aspectHeight': aspectHeight,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationTemplateComposition &&
          other.orientation == orientation &&
          other.aspectWidth == aspectWidth &&
          other.aspectHeight == aspectHeight;

  @override
  int get hashCode => Object.hash(orientation, aspectWidth, aspectHeight);
}

final class PresentationTemplateMediaSlot {
  PresentationTemplateMediaSlot({
    required String id,
    required this.kind,
    required this.variantPolicy,
    this.required = false,
  }) : id = _stableId(id, 'mediaSlot.id') {
    if (kind == PresentationTemplateMediaKind.music &&
        variantPolicy != PresentationTemplateMediaVariantPolicy.shared) {
      throw ArgumentError.value(
        variantPolicy,
        'variantPolicy',
        'music must be shared by both compositions',
      );
    }
    if (kind != PresentationTemplateMediaKind.music &&
        variantPolicy !=
            PresentationTemplateMediaVariantPolicy.responsiveFallback) {
      throw ArgumentError.value(
        variantPolicy,
        'variantPolicy',
        'non-music media must support responsive fallback',
      );
    }
  }

  factory PresentationTemplateMediaSlot.fromJson(Map<String, Object?> json) {
    _rejectUnknownKeys(json, const <String>{
      'id',
      'kind',
      'variantPolicy',
      'required',
    }, 'mediaSlot');
    return PresentationTemplateMediaSlot(
      id: _string(json['id'], 'mediaSlot.id'),
      kind: _enumByName(
        PresentationTemplateMediaKind.values,
        json['kind'],
        'mediaSlot.kind',
      ),
      variantPolicy: _enumByName(
        PresentationTemplateMediaVariantPolicy.values,
        json['variantPolicy'],
        'mediaSlot.variantPolicy',
      ),
      required: _boolean(json['required'], 'mediaSlot.required'),
    );
  }

  final String id;
  final PresentationTemplateMediaKind kind;
  final PresentationTemplateMediaVariantPolicy variantPolicy;
  final bool required;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'kind': kind.name,
    'variantPolicy': variantPolicy.name,
    'required': required,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationTemplateMediaSlot &&
          other.id == id &&
          other.kind == kind &&
          other.variantPolicy == variantPolicy &&
          other.required == required;

  @override
  int get hashCode => Object.hash(id, kind, variantPolicy, required);
}

final class PresentationCinematicTemplate {
  PresentationCinematicTemplate({
    required String id,
    required this.version,
    required this.order,
    required String nameKey,
    required String descriptionKey,
    required this.defaultDurationUs,
    required Iterable<PresentationTemplateComposition> compositions,
    Iterable<PresentationTemplateMediaSlot> mediaSlots = const [],
  }) : id = _stableId(id, 'template.id'),
       nameKey = _localizationKey(nameKey, 'template.nameKey'),
       descriptionKey = _localizationKey(
         descriptionKey,
         'template.descriptionKey',
       ),
       compositions = List.unmodifiable(compositions),
       mediaSlots = List.unmodifiable(mediaSlots) {
    if (version < 1) {
      throw ArgumentError.value(version, 'version', 'must be positive');
    }
    if (order < 0) {
      throw ArgumentError.value(order, 'order', 'must not be negative');
    }
    if (defaultDurationUs < 1) {
      throw ArgumentError.value(
        defaultDurationUs,
        'defaultDurationUs',
        'must be positive',
      );
    }
    final orientations = this.compositions
        .map((composition) => composition.orientation)
        .toSet();
    if (this.compositions.length != 2 ||
        !orientations.containsAll(PresentationTemplateOrientation.values)) {
      throw ArgumentError.value(
        this.compositions,
        'compositions',
        'must contain one landscape and one portrait composition',
      );
    }
    if (this.mediaSlots.any((slot) => slot.required)) {
      throw ArgumentError.value(
        this.mediaSlots,
        'mediaSlots',
        'canonical Presentation templates cannot require media',
      );
    }
    _requireUnique(this.mediaSlots.map((slot) => slot.id), 'mediaSlots');
  }

  factory PresentationCinematicTemplate.fromJson(Map<String, Object?> json) {
    _rejectUnknownKeys(json, const <String>{
      'id',
      'version',
      'order',
      'nameKey',
      'descriptionKey',
      'defaultDurationUs',
      'compositions',
      'mediaSlots',
    }, 'template');
    return PresentationCinematicTemplate(
      id: _string(json['id'], 'template.id'),
      version: _integer(json['version'], 'template.version'),
      order: _integer(json['order'], 'template.order'),
      nameKey: _string(json['nameKey'], 'template.nameKey'),
      descriptionKey: _string(
        json['descriptionKey'],
        'template.descriptionKey',
      ),
      defaultDurationUs: _integer(
        json['defaultDurationUs'],
        'template.defaultDurationUs',
      ),
      compositions: _objects(
        json['compositions'],
        'template.compositions',
      ).map(PresentationTemplateComposition.fromJson),
      mediaSlots: _objects(
        json['mediaSlots'],
        'template.mediaSlots',
      ).map(PresentationTemplateMediaSlot.fromJson),
    );
  }

  final String id;
  final int version;
  final int order;
  final String nameKey;
  final String descriptionKey;
  final int defaultDurationUs;
  final List<PresentationTemplateComposition> compositions;
  final List<PresentationTemplateMediaSlot> mediaSlots;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'version': version,
    'order': order,
    'nameKey': nameKey,
    'descriptionKey': descriptionKey,
    'defaultDurationUs': defaultDurationUs,
    'compositions': compositions
        .map((composition) => composition.toJson())
        .toList(growable: false),
    'mediaSlots': mediaSlots
        .map((slot) => slot.toJson())
        .toList(growable: false),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationCinematicTemplate &&
          other.id == id &&
          other.version == version &&
          other.order == order &&
          other.nameKey == nameKey &&
          other.descriptionKey == descriptionKey &&
          other.defaultDurationUs == defaultDurationUs &&
          _listEquals(other.compositions, compositions) &&
          _listEquals(other.mediaSlots, mediaSlots);

  @override
  int get hashCode => Object.hash(
    id,
    version,
    order,
    nameKey,
    descriptionKey,
    defaultDurationUs,
    Object.hashAll(compositions),
    Object.hashAll(mediaSlots),
  );
}

final class PresentationCinematicTemplateCatalog {
  PresentationCinematicTemplateCatalog({
    required this.schemaVersion,
    required Iterable<PresentationCinematicTemplate> templates,
  }) : templates = List.unmodifiable(
         templates.toList()
           ..sort((left, right) => left.order.compareTo(right.order)),
       ) {
    if (schemaVersion < 1) {
      throw ArgumentError.value(
        schemaVersion,
        'schemaVersion',
        'must be positive',
      );
    }
    _requireUnique(
      this.templates.map((template) => template.id),
      'templates.id',
    );
    _requireUnique(
      this.templates.map((template) => template.order),
      'templates.order',
    );
  }

  factory PresentationCinematicTemplateCatalog.fromJson(
    Map<String, Object?> json,
  ) {
    _rejectUnknownKeys(json, const <String>{
      'schemaVersion',
      'templates',
    }, 'catalog');
    final schemaVersion = _integer(json['schemaVersion'], 'schemaVersion');
    if (schemaVersion != currentSchemaVersion) {
      throw FormatException(
        'Unsupported Presentation template catalog schemaVersion: '
        '$schemaVersion',
      );
    }
    return PresentationCinematicTemplateCatalog(
      schemaVersion: schemaVersion,
      templates: _objects(
        json['templates'],
        'templates',
      ).map(PresentationCinematicTemplate.fromJson),
    );
  }

  factory PresentationCinematicTemplateCatalog.canonical() =>
      PresentationCinematicTemplateCatalog(
        schemaVersion: currentSchemaVersion,
        templates: _canonicalTemplates,
      );

  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final List<PresentationCinematicTemplate> templates;

  PresentationCinematicTemplate require(String id, {required int version}) {
    final matchingId = templates.where((template) => template.id == id);
    if (matchingId.isEmpty) {
      throw PresentationCinematicTemplateException(
        code: PresentationCinematicTemplateErrorCode.unknownTemplate,
        message: 'Unknown Presentation cinematic template: $id',
      );
    }
    for (final template in matchingId) {
      if (template.version == version) return template;
    }
    throw PresentationCinematicTemplateException(
      code: PresentationCinematicTemplateErrorCode.unsupportedVersion,
      message: 'Unsupported version $version for Presentation template $id',
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'templates': templates
        .map((template) => template.toJson())
        .toList(growable: false),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationCinematicTemplateCatalog &&
          other.schemaVersion == schemaVersion &&
          _listEquals(other.templates, templates);

  @override
  int get hashCode => Object.hash(schemaVersion, Object.hashAll(templates));
}

final List<PresentationCinematicTemplate>
_canonicalTemplates = <PresentationCinematicTemplate>[
  _template(id: 'blank', order: 0, durationUs: 12000000),
  _template(
    id: 'titleIdentity',
    order: 1,
    durationUs: 12000000,
    slots: <PresentationTemplateMediaSlot>[
      _responsiveSlot('background', PresentationTemplateMediaKind.image),
      _responsiveSlot('identity', PresentationTemplateMediaKind.image),
    ],
  ),
  _template(
    id: 'immersiveOpening',
    order: 2,
    durationUs: 18000000,
    slots: <PresentationTemplateMediaSlot>[
      _responsiveSlot('hero', PresentationTemplateMediaKind.image),
      _responsiveSlot('atmosphere', PresentationTemplateMediaKind.soundEffect),
      _responsiveSlot('voice', PresentationTemplateMediaKind.voice),
      _musicSlot(),
    ],
  ),
  _template(
    id: 'stagedStory',
    order: 3,
    durationUs: 30000000,
    slots: <PresentationTemplateMediaSlot>[
      _responsiveSlot('background', PresentationTemplateMediaKind.image),
      _responsiveSlot('foreground', PresentationTemplateMediaKind.image),
      _responsiveSlot('voice', PresentationTemplateMediaKind.voice),
      _musicSlot(),
    ],
  ),
  _template(
    id: 'interactivePath',
    order: 4,
    durationUs: 20000000,
    slots: <PresentationTemplateMediaSlot>[
      _responsiveSlot('background', PresentationTemplateMediaKind.image),
      _responsiveSlot('prompt', PresentationTemplateMediaKind.image),
      _responsiveSlot('voice', PresentationTemplateMediaKind.voice),
      _responsiveSlot('feedback', PresentationTemplateMediaKind.soundEffect),
      _musicSlot(),
    ],
  ),
  _template(
    id: 'adaptiveVideo',
    order: 5,
    durationUs: 15000000,
    slots: <PresentationTemplateMediaSlot>[
      _responsiveSlot('video', PresentationTemplateMediaKind.video),
      _responsiveSlot('poster', PresentationTemplateMediaKind.image),
      _musicSlot(),
    ],
  ),
];

PresentationCinematicTemplate _template({
  required String id,
  required int order,
  required int durationUs,
  List<PresentationTemplateMediaSlot> slots = const [],
}) => PresentationCinematicTemplate(
  id: id,
  version: 1,
  order: order,
  nameKey: 'cinematic.template.$id.name',
  descriptionKey: 'cinematic.template.$id.description',
  defaultDurationUs: durationUs,
  compositions: <PresentationTemplateComposition>[
    PresentationTemplateComposition(
      orientation: PresentationTemplateOrientation.landscape,
      aspectWidth: 16,
      aspectHeight: 9,
    ),
    PresentationTemplateComposition(
      orientation: PresentationTemplateOrientation.portrait,
      aspectWidth: 9,
      aspectHeight: 16,
    ),
  ],
  mediaSlots: slots,
);

PresentationTemplateMediaSlot _responsiveSlot(
  String id,
  PresentationTemplateMediaKind kind,
) => PresentationTemplateMediaSlot(
  id: id,
  kind: kind,
  variantPolicy: PresentationTemplateMediaVariantPolicy.responsiveFallback,
);

PresentationTemplateMediaSlot _musicSlot() => PresentationTemplateMediaSlot(
  id: 'music',
  kind: PresentationTemplateMediaKind.music,
  variantPolicy: PresentationTemplateMediaVariantPolicy.shared,
);

String _stableId(String value, String field) {
  if (value != value.trim() ||
      !RegExp(r'^[a-z][A-Za-z0-9]*$').hasMatch(value)) {
    throw ArgumentError.value(value, field, 'must be a stable identifier');
  }
  return value;
}

String _localizationKey(String value, String field) {
  if (value != value.trim() ||
      !RegExp(r'^[a-z][A-Za-z0-9]*(\.[a-z][A-Za-z0-9]*)+$').hasMatch(value)) {
    throw ArgumentError.value(value, field, 'must be a localization key');
  }
  return value;
}

String _string(Object? value, String path) {
  if (value is! String || value.isEmpty || value != value.trim()) {
    throw FormatException('$path must be a nonblank trimmed string');
  }
  return value;
}

int _integer(Object? value, String path) {
  if (value is! int) throw FormatException('$path must be an integer');
  return value;
}

bool _boolean(Object? value, String path) {
  if (value is! bool) throw FormatException('$path must be a boolean');
  return value;
}

T _enumByName<T extends Enum>(List<T> values, Object? value, String path) {
  final name = _string(value, path);
  for (final candidate in values) {
    if (candidate.name == name) return candidate;
  }
  throw FormatException('$path has an unknown value: $name');
}

List<Map<String, Object?>> _objects(Object? value, String path) {
  if (value is! List) throw FormatException('$path must be a list');
  return <Map<String, Object?>>[
    for (var index = 0; index < value.length; index += 1)
      if (value[index] case final Map<dynamic, dynamic> item
          when item.keys.every((key) => key is String))
        Map<String, Object?>.from(item)
      else
        throw FormatException('$path[$index] must be an object'),
  ];
}

void _rejectUnknownKeys(
  Map<String, Object?> json,
  Set<String> expected,
  String path,
) {
  final unknown = json.keys.toSet().difference(expected);
  if (unknown.isNotEmpty) {
    throw FormatException('$path contains unknown keys: ${unknown.join(', ')}');
  }
  final missing = expected.difference(json.keys.toSet());
  if (missing.isNotEmpty) {
    throw FormatException('$path is missing keys: ${missing.join(', ')}');
  }
}

void _requireUnique(Iterable<Object> values, String field) {
  final unique = <Object>{};
  for (final value in values) {
    if (!unique.add(value)) {
      throw ArgumentError.value(value, field, 'must be unique');
    }
  }
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
