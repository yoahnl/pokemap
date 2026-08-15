final class ProjectMediaKind {
  const ProjectMediaKind._(this.id);

  factory ProjectMediaKind(String id) =>
      ProjectMediaKind._(_stableIdentifier(id, 'kind'));

  static const image = ProjectMediaKind._('image');
  static const audio = ProjectMediaKind._('audio');
  static const video = ProjectMediaKind._('video');
  static const poster = ProjectMediaKind._('poster');
  static const captions = ProjectMediaKind._('captions');

  factory ProjectMediaKind.fromJson(Object? value) {
    if (value is! String) {
      throw const FormatException('media.kind must be a string');
    }
    try {
      return switch (value) {
        'image' => image,
        'audio' => audio,
        'video' => video,
        'poster' => poster,
        'captions' => captions,
        _ => ProjectMediaKind(value),
      };
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final String id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ProjectMediaKind && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

final class ProjectMediaTechnicalMetadata {
  ProjectMediaTechnicalMetadata({
    required String mediaType,
    required String container,
    required String codec,
    required this.sizeBytes,
    String? audioCodec,
    this.width,
    this.height,
    this.durationMilliseconds,
  }) : mediaType = _mediaType(mediaType),
       container = _technicalToken(container, 'container'),
       codec = _technicalToken(codec, 'codec'),
       audioCodec = audioCodec == null
           ? null
           : _technicalToken(audioCodec, 'audioCodec') {
    if (sizeBytes < 1) {
      throw ArgumentError.value(sizeBytes, 'sizeBytes', 'must be positive');
    }
    if ((width == null) != (height == null)) {
      throw ArgumentError.value(
        '$width x $height',
        'width/height',
        'must both be present or absent',
      );
    }
    if ((width != null && width! < 1) || (height != null && height! < 1)) {
      throw ArgumentError.value(
        '$width x $height',
        'width/height',
        'must be positive',
      );
    }
    if (durationMilliseconds != null && durationMilliseconds! < 1) {
      throw ArgumentError.value(
        durationMilliseconds,
        'durationMilliseconds',
        'must be positive',
      );
    }
  }

  factory ProjectMediaTechnicalMetadata.fromJson(Map<String, Object?> json) {
    _rejectUnknownKeys(json, const {
      'mediaType',
      'container',
      'codec',
      'audioCodec',
      'sizeBytes',
      'width',
      'height',
      'durationMilliseconds',
    }, 'media.technicalMetadata');
    try {
      return ProjectMediaTechnicalMetadata(
        mediaType: _readString(
          json['mediaType'],
          'media.technicalMetadata.mediaType',
        ),
        container: _readString(
          json['container'],
          'media.technicalMetadata.container',
        ),
        codec: _readString(json['codec'], 'media.technicalMetadata.codec'),
        audioCodec: _readOptionalString(
          json['audioCodec'],
          'media.technicalMetadata.audioCodec',
        ),
        sizeBytes: _readInt(
          json['sizeBytes'],
          'media.technicalMetadata.sizeBytes',
        ),
        width: _readOptionalInt(json['width'], 'media.technicalMetadata.width'),
        height: _readOptionalInt(
          json['height'],
          'media.technicalMetadata.height',
        ),
        durationMilliseconds: _readOptionalInt(
          json['durationMilliseconds'],
          'media.technicalMetadata.durationMilliseconds',
        ),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final String mediaType;
  final String container;
  final String codec;
  final String? audioCodec;
  final int sizeBytes;
  final int? width;
  final int? height;
  final int? durationMilliseconds;

  Map<String, Object?> toJson() => {
    'mediaType': mediaType,
    'container': container,
    'codec': codec,
    if (audioCodec != null) 'audioCodec': audioCodec,
    'sizeBytes': sizeBytes,
    if (width != null) 'width': width,
    if (height != null) 'height': height,
    if (durationMilliseconds != null)
      'durationMilliseconds': durationMilliseconds,
  };
}

final class ProjectMediaCaption {
  ProjectMediaCaption({required String locale, required String mediaId})
    : locale = _locale(locale),
      mediaId = _stableIdentifier(mediaId, 'mediaId');

  factory ProjectMediaCaption.fromJson(Map<String, Object?> json) {
    _rejectUnknownKeys(json, const {'locale', 'mediaId'}, 'media.caption');
    try {
      return ProjectMediaCaption(
        locale: _readString(json['locale'], 'media.caption.locale'),
        mediaId: _readString(json['mediaId'], 'media.caption.mediaId'),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final String locale;
  final String mediaId;

  Map<String, Object?> toJson() => {'locale': locale, 'mediaId': mediaId};
}

final class ProjectMediaProvenance {
  ProjectMediaProvenance({
    required String source,
    String? creator,
    String? sourceUrl,
  }) : source = _requiredString(source, 'source'),
       creator = _optionalString(creator),
       sourceUrl = _optionalHttpUrl(sourceUrl, 'sourceUrl');

  factory ProjectMediaProvenance.fromJson(Map<String, Object?> json) {
    _rejectUnknownKeys(json, const {
      'source',
      'creator',
      'sourceUrl',
    }, 'media.provenance');
    try {
      return ProjectMediaProvenance(
        source: _readString(json['source'], 'media.provenance.source'),
        creator: _readOptionalString(
          json['creator'],
          'media.provenance.creator',
        ),
        sourceUrl: _readOptionalString(
          json['sourceUrl'],
          'media.provenance.sourceUrl',
        ),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final String source;
  final String? creator;
  final String? sourceUrl;

  Map<String, Object?> toJson() => {
    'source': source,
    if (creator != null) 'creator': creator,
    if (sourceUrl != null) 'sourceUrl': sourceUrl,
  };
}

final class ProjectMediaLicense {
  ProjectMediaLicense({
    required String identifier,
    required String name,
    String? url,
    String? notice,
  }) : identifier = _requiredString(identifier, 'identifier'),
       name = _requiredString(name, 'name'),
       url = _optionalHttpUrl(url, 'url'),
       notice = _optionalString(notice);

  factory ProjectMediaLicense.fromJson(Map<String, Object?> json) {
    _rejectUnknownKeys(json, const {
      'identifier',
      'name',
      'url',
      'notice',
    }, 'media.license');
    try {
      return ProjectMediaLicense(
        identifier: _readString(json['identifier'], 'media.license.identifier'),
        name: _readString(json['name'], 'media.license.name'),
        url: _readOptionalString(json['url'], 'media.license.url'),
        notice: _readOptionalString(json['notice'], 'media.license.notice'),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final String identifier;
  final String name;
  final String? url;
  final String? notice;

  Map<String, Object?> toJson() => {
    'identifier': identifier,
    'name': name,
    if (url != null) 'url': url,
    if (notice != null) 'notice': notice,
  };
}

final class ProjectMediaAsset {
  ProjectMediaAsset({
    required String id,
    required String label,
    required this.kind,
    required String sourceAssetId,
    String? posterMediaId,
    Iterable<String> captionMediaIds = const [],
    Iterable<ProjectMediaCaption> captions = const [],
    String? fallbackMediaId,
    this.provenance,
    this.license,
    this.technicalMetadata,
  }) : id = _stableIdentifier(id, 'id'),
       label = _requiredString(label, 'label'),
       sourceAssetId = _stableIdentifier(sourceAssetId, 'sourceAssetId'),
       posterMediaId = _optionalStableIdentifier(
         posterMediaId,
         'posterMediaId',
       ),
       captionMediaIds = _stableIdentifiers(captionMediaIds, 'captionMediaIds'),
       captions = _validatedCaptions(captions),
       fallbackMediaId = _optionalStableIdentifier(
         fallbackMediaId,
         'fallbackMediaId',
       ) {
    final relations = <String?>[
      this.posterMediaId,
      ...this.captionMediaIds,
      ...this.captions.map((caption) => caption.mediaId),
      this.fallbackMediaId,
    ];
    if (relations.contains(this.id)) {
      throw ArgumentError.value(
        this.id,
        'id',
        'media relationships must not target their owner',
      );
    }
  }

  factory ProjectMediaAsset.fromJson(Map<String, Object?> json) {
    _rejectUnknownKeys(json, const {
      'id',
      'label',
      'kind',
      'sourceAssetId',
      'posterMediaId',
      'captionMediaIds',
      'captions',
      'fallbackMediaId',
      'provenance',
      'license',
      'technicalMetadata',
    }, 'media');
    try {
      return ProjectMediaAsset(
        id: _readString(json['id'], 'media.id'),
        label: _readString(json['label'], 'media.label'),
        kind: ProjectMediaKind.fromJson(json['kind']),
        sourceAssetId: _readString(
          json['sourceAssetId'],
          'media.sourceAssetId',
        ),
        posterMediaId: _readOptionalString(
          json['posterMediaId'],
          'media.posterMediaId',
        ),
        captionMediaIds: _readStringList(
          json['captionMediaIds'],
          'media.captionMediaIds',
        ),
        captions: _readCaptions(json['captions']),
        fallbackMediaId: _readOptionalString(
          json['fallbackMediaId'],
          'media.fallbackMediaId',
        ),
        provenance: _readProvenance(json['provenance']),
        license: _readLicense(json['license']),
        technicalMetadata: _readTechnicalMetadata(json['technicalMetadata']),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final String id;
  final String label;
  final ProjectMediaKind kind;
  final String sourceAssetId;
  final String? posterMediaId;
  final List<String> captionMediaIds;
  final List<ProjectMediaCaption> captions;
  final String? fallbackMediaId;
  final ProjectMediaProvenance? provenance;
  final ProjectMediaLicense? license;
  final ProjectMediaTechnicalMetadata? technicalMetadata;

  ProjectMediaCaption? resolveCaption({
    required String requestedLocale,
    required String projectDefaultLocale,
  }) {
    final requested = _locale(requestedLocale);
    final projectDefault = _locale(projectDefaultLocale);
    for (final caption in captions) {
      if (caption.locale == requested) return caption;
    }
    for (final caption in captions) {
      if (caption.locale == projectDefault) return caption;
    }
    return null;
  }

  ProjectMediaAsset replaceSource(String value) => ProjectMediaAsset(
    id: id,
    label: label,
    kind: kind,
    sourceAssetId: value,
    posterMediaId: posterMediaId,
    captionMediaIds: captionMediaIds,
    captions: captions,
    fallbackMediaId: fallbackMediaId,
    provenance: provenance,
    license: license,
    technicalMetadata: technicalMetadata,
  );

  ProjectMediaAsset configure({
    required String? posterMediaId,
    required Iterable<ProjectMediaCaption> captions,
    required String? fallbackMediaId,
    required ProjectMediaProvenance provenance,
    required ProjectMediaLicense license,
  }) => ProjectMediaAsset(
    id: id,
    label: label,
    kind: kind,
    sourceAssetId: sourceAssetId,
    posterMediaId: posterMediaId,
    captionMediaIds: captionMediaIds,
    captions: captions,
    fallbackMediaId: fallbackMediaId,
    provenance: provenance,
    license: license,
    technicalMetadata: technicalMetadata,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'kind': kind.id,
    'sourceAssetId': sourceAssetId,
    if (posterMediaId != null) 'posterMediaId': posterMediaId,
    if (captionMediaIds.isNotEmpty) 'captionMediaIds': captionMediaIds,
    if (captions.isNotEmpty)
      'captions': captions.map((caption) => caption.toJson()).toList(),
    if (fallbackMediaId != null) 'fallbackMediaId': fallbackMediaId,
    if (provenance != null) 'provenance': provenance!.toJson(),
    if (license != null) 'license': license!.toJson(),
    if (technicalMetadata != null)
      'technicalMetadata': technicalMetadata!.toJson(),
  };
}

final class ProjectMediaCatalog {
  ProjectMediaCatalog({Iterable<ProjectMediaAsset> entries = const []})
    : entries = _validatedEntries(entries) {
    _byId = Map.unmodifiable({
      for (final entry in this.entries) entry.id: entry,
    });
  }

  factory ProjectMediaCatalog.fromJson(Map<String, Object?> json) {
    _rejectUnknownKeys(json, const {'schemaVersion', 'entries'}, 'catalog');
    if (json['schemaVersion'] != schemaVersion) {
      throw FormatException(
        'Unsupported project media catalog schemaVersion: '
        '${json['schemaVersion']}',
      );
    }
    final rawEntries = json['entries'];
    if (rawEntries is! List) {
      throw const FormatException('catalog.entries must be a list');
    }
    try {
      return ProjectMediaCatalog(
        entries: rawEntries.map((raw) {
          if (raw is! Map || raw.keys.any((key) => key is! String)) {
            throw const FormatException('catalog.entries[] must be an object');
          }
          return ProjectMediaAsset.fromJson(Map<String, Object?>.from(raw));
        }),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  static const int schemaVersion = 1;

  final List<ProjectMediaAsset> entries;
  late final Map<String, ProjectMediaAsset> _byId;

  ProjectMediaAsset? find(String id) => _byId[id];

  ProjectMediaAsset require(String id) =>
      find(id) ?? (throw ArgumentError.value(id, 'mediaId', 'does not exist'));

  ProjectMediaCatalog replaceSource({
    required String mediaId,
    required String sourceAssetId,
  }) {
    final current = require(mediaId);
    return ProjectMediaCatalog(
      entries: [
        for (final entry in entries)
          if (entry.id == mediaId)
            current.replaceSource(sourceAssetId)
          else
            entry,
      ],
    );
  }

  ProjectMediaCatalog replace(ProjectMediaAsset media) {
    require(media.id);
    return ProjectMediaCatalog(
      entries: <ProjectMediaAsset>[
        for (final entry in entries)
          if (entry.id == media.id) media else entry,
      ],
    );
  }

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'entries': entries.map((entry) => entry.toJson()).toList(growable: false),
  };
}

List<ProjectMediaAsset> _validatedEntries(Iterable<ProjectMediaAsset> source) {
  final entries = source.toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  final ids = <String>{};
  for (final entry in entries) {
    if (!ids.add(entry.id)) {
      throw ArgumentError.value(entry.id, 'entries', 'contains a duplicate id');
    }
  }
  return List.unmodifiable(entries);
}

String _stableIdentifier(String value, String field) {
  if (value != value.trim() ||
      !RegExp(r'^[A-Za-z0-9][A-Za-z0-9_.-]*$').hasMatch(value)) {
    throw ArgumentError.value(value, field, 'must be a stable identity');
  }
  return value;
}

String? _optionalStableIdentifier(String? value, String field) =>
    value == null ? null : _stableIdentifier(value, field);

List<String> _stableIdentifiers(Iterable<String> source, String field) {
  final values = source.map((value) => _stableIdentifier(value, field)).toList()
    ..sort();
  if (values.toSet().length != values.length) {
    throw ArgumentError.value(values, field, 'must be unique');
  }
  return List.unmodifiable(values);
}

String _requiredString(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, 'must not be blank');
  }
  return normalized;
}

String? _optionalString(String? value) {
  if (value == null) return null;
  return _requiredString(value, 'value');
}

String? _optionalHttpUrl(String? value, String field) {
  final normalized = _optionalString(value);
  if (normalized == null) return null;
  final uri = Uri.tryParse(normalized);
  if (uri == null ||
      !uri.hasAuthority ||
      !const {'http', 'https'}.contains(uri.scheme)) {
    throw ArgumentError.value(value, field, 'must be an HTTP(S) URL');
  }
  return normalized;
}

String _locale(String value) {
  if (value != value.trim() ||
      !RegExp(
        r'^[a-z]{2,3}(?:-[A-Z][a-z]{3})?(?:-(?:[A-Z]{2}|[0-9]{3}))?(?:-[A-Za-z0-9]{5,8})*$',
      ).hasMatch(value)) {
    throw ArgumentError.value(value, 'locale', 'must be a canonical locale');
  }
  return value;
}

String _readString(Object? value, String field) {
  if (value is! String) throw FormatException('$field must be a string');
  return value;
}

String? _readOptionalString(Object? value, String field) {
  if (value == null) return null;
  return _readString(value, field);
}

int _readInt(Object? value, String field) {
  if (value is! int) throw FormatException('$field must be an integer');
  return value;
}

int? _readOptionalInt(Object? value, String field) {
  if (value == null) return null;
  return _readInt(value, field);
}

ProjectMediaTechnicalMetadata? _readTechnicalMetadata(Object? value) {
  if (value == null) return null;
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw const FormatException('media.technicalMetadata must be an object');
  }
  return ProjectMediaTechnicalMetadata.fromJson(
    Map<String, Object?>.from(value),
  );
}

List<ProjectMediaCaption> _readCaptions(Object? value) {
  if (value == null) return const [];
  if (value is! List) {
    throw const FormatException('media.captions must be a list');
  }
  return value
      .map((item) {
        if (item is! Map || item.keys.any((key) => key is! String)) {
          throw const FormatException('media.captions[] must be an object');
        }
        return ProjectMediaCaption.fromJson(Map<String, Object?>.from(item));
      })
      .toList(growable: false);
}

ProjectMediaProvenance? _readProvenance(Object? value) {
  if (value == null) return null;
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw const FormatException('media.provenance must be an object');
  }
  return ProjectMediaProvenance.fromJson(Map<String, Object?>.from(value));
}

ProjectMediaLicense? _readLicense(Object? value) {
  if (value == null) return null;
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw const FormatException('media.license must be an object');
  }
  return ProjectMediaLicense.fromJson(Map<String, Object?>.from(value));
}

List<ProjectMediaCaption> _validatedCaptions(
  Iterable<ProjectMediaCaption> source,
) {
  final captions = source.toList()
    ..sort((left, right) => left.locale.compareTo(right.locale));
  final locales = <String>{};
  for (final caption in captions) {
    if (!locales.add(caption.locale)) {
      throw ArgumentError.value(
        caption.locale,
        'captions',
        'contains a duplicate locale',
      );
    }
  }
  return List.unmodifiable(captions);
}

String _mediaType(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized != value ||
      !RegExp(
        r'^[a-z0-9][a-z0-9!#$&^_.+-]*/[a-z0-9][a-z0-9!#$&^_.+-]*$',
      ).hasMatch(normalized)) {
    throw ArgumentError.value(value, 'mediaType', 'must be a MIME type');
  }
  return normalized;
}

String _technicalToken(String value, String field) {
  final normalized = value.trim().toLowerCase();
  if (normalized != value ||
      !RegExp(r'^[a-z0-9][a-z0-9_.+-]*$').hasMatch(normalized)) {
    throw ArgumentError.value(value, field, 'must be a technical token');
  }
  return normalized;
}

List<String> _readStringList(Object? value, String field) {
  if (value == null) return const [];
  if (value is! List || value.any((item) => item is! String)) {
    throw FormatException('$field must be a string list');
  }
  return value.cast<String>();
}

void _rejectUnknownKeys(
  Map<String, Object?> json,
  Set<String> allowed,
  String field,
) {
  final unknown = json.keys.toSet().difference(allowed);
  if (unknown.isNotEmpty) {
    throw FormatException(
      '$field contains unknown fields: ${unknown.join(', ')}',
    );
  }
}
