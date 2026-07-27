import 'dart:convert';
import 'dart:typed_data';

import 'package:map_core/map_core.dart'
    show
        projectIntroVideoMaxBitrateKbps,
        projectIntroVideoMaxDurationMilliseconds,
        projectIntroVideoMaxHeight,
        projectIntroVideoMaxSizeBytes,
        projectIntroVideoMaxWidth;
import 'package:pub_semver/pub_semver.dart';

import 'canonical_json.dart';
import 'content_tree_hasher.dart';
import 'game_package_format_exception.dart';
import 'game_package_manifest.dart';
import 'package_path_policy.dart';
import 'strict_json_structure_validator.dart';

final class GamePackageManifestCodec {
  const GamePackageManifestCodec();

  GamePackageManifest decodeUtf8(List<int> bytes) {
    late final String source;
    try {
      source = utf8.decode(bytes, allowMalformed: false);
    } on FormatException catch (error) {
      throw GamePackageFormatException(
        code: 'invalidUtf8',
        path: r'$',
        message: error.message,
      );
    }
    late final Object? decoded;
    try {
      const StrictJsonStructureValidator().validate(
        source,
        path: r'$',
        maxDepth: 32,
        maxNodes: 200000,
        duplicateCode: 'nonCanonicalManifest',
      );
      decoded = jsonDecode(source);
    } on GamePackageFormatException {
      rethrow;
    } on FormatException catch (error) {
      throw GamePackageFormatException(
        code: 'invalidJson',
        path: r'$',
        message: error.message,
      );
    }
    final manifest = decodeJson(decoded);
    if (source != CanonicalJson.encode(manifest.toJson())) {
      _fail(
        'nonCanonicalManifest',
        r'$',
        'Manifest bytes must use the canonical JSON representation.',
      );
    }
    return manifest;
  }

  GamePackageManifest decodeJson(Object? value) {
    final json = _object(
      value,
      r'$',
      required: const <String>{
        'packageFormat',
        'gameId',
        'gameVersion',
        'title',
        'author',
        'compatibility',
        'locales',
        'content',
      },
      optional: const <String>{
        'description',
        'publisher',
        'branding',
        'presentation',
        'signature',
      },
    );
    final packageFormat = _integer(json['packageFormat'], r'$.packageFormat');
    if (packageFormat != 1) {
      _fail(
        'packageFormatUnsupported',
        r'$.packageFormat',
        'Only packageFormat 1 is supported.',
      );
    }
    final gameId = _string(json['gameId'], r'$.gameId');
    if (!_gameId.hasMatch(gameId) || utf8.encode(gameId).length > 128) {
      _fail('invalidGameId', r'$.gameId', 'Invalid stable gameId.');
    }
    final gameVersion = _version(json['gameVersion'], r'$.gameVersion');
    final title = _boundedString(json['title'], r'$.title', 1, 120);
    final description = json.containsKey('description')
        ? _boundedString(json['description'], r'$.description', 0, 4000)
        : null;
    final author = _party(json['author'], r'$.author');
    final publisher = json.containsKey('publisher')
        ? _party(json['publisher'], r'$.publisher')
        : null;
    final compatibility = _compatibility(json['compatibility']);
    final locales = _locales(json['locales']);
    final legacyBranding =
        json.containsKey('branding') ? _branding(json['branding']) : null;
    final presentation = json.containsKey('presentation')
        ? _presentation(json['presentation'])
        : null;
    if (legacyBranding != null && presentation != null) {
      _fail(
        'conflictingPresentationContract',
        r'$.presentation',
        'Use either presentation or legacy branding, not both.',
      );
    }
    final branding = presentation?.branding ?? legacyBranding;
    final brandingPath =
        presentation == null ? r'$.branding' : r'$.presentation.branding';
    final content = _content(json['content']);
    final signature =
        json.containsKey('signature') ? _signature(json['signature']) : null;

    final contentPaths = content.files.map((file) => file.path).toSet();
    for (final reference in <({String field, String? value, String prefix})>[
      (field: 'icon', value: branding?.icon, prefix: 'presentation/'),
      (field: 'cover', value: branding?.cover, prefix: 'presentation/'),
      (field: 'hero', value: branding?.hero, prefix: 'presentation/'),
      (
        field: 'titleMusic',
        value: branding?.titleMusic,
        prefix: 'project/assets/',
      ),
    ]) {
      final value = reference.value;
      if (value != null && !value.startsWith(reference.prefix)) {
        _fail(
          'invalidBrandingReference',
          '$brandingPath.${reference.field}',
          'Branding reference has an invalid package root.',
        );
      }
      if (value != null && !contentPaths.contains(value)) {
        _fail(
          'brandingReferenceMissing',
          '$brandingPath.${reference.field}',
          'Branding reference is not present in content.files.',
        );
      }
    }
    final intro = presentation?.intro;
    for (final reference in <({String field, String? value})>[
      (field: 'video', value: intro?.video),
      (field: 'poster', value: intro?.poster),
      (field: 'captions', value: intro?.captions),
    ]) {
      final value = reference.value;
      if (value == null) continue;
      if (!value.startsWith('presentation/intro/')) {
        _fail(
          'invalidIntroVideoReference',
          '\$.presentation.intro.${reference.field}',
          'Intro assets must use the presentation/intro package root.',
        );
      }
      if (!contentPaths.contains(value)) {
        _fail(
          'introVideoReferenceMissing',
          '\$.presentation.intro.${reference.field}',
          'Intro reference is not present in content.files.',
        );
      }
    }

    return GamePackageManifest(
      packageFormat: packageFormat,
      gameId: gameId,
      gameVersion: gameVersion,
      title: title,
      description: description,
      author: author,
      publisher: publisher,
      compatibility: compatibility,
      locales: locales,
      branding: legacyBranding,
      presentation: presentation,
      content: content,
      signature: signature,
    );
  }

  String encodeCanonicalJson(GamePackageManifest manifest) =>
      CanonicalJson.encode(_validatedJson(manifest));

  Uint8List encodeCanonicalUtf8(GamePackageManifest manifest) =>
      CanonicalJson.encodeUtf8(_validatedJson(manifest));

  Uint8List signaturePreimageUtf8(GamePackageManifest manifest) {
    final json = _validatedJson(manifest)..remove('signature');
    return CanonicalJson.encodeUtf8(json);
  }

  Map<String, Object?> _validatedJson(GamePackageManifest manifest) =>
      decodeJson(manifest.toJson()).toJson();

  GamePackageParty _party(Object? value, String path) {
    final json = _object(
      value,
      path,
      required: const <String>{'name'},
      optional: const <String>{'url'},
    );
    final name = _boundedString(json['name'], '$path.name', 1, 120);
    Uri? url;
    if (json.containsKey('url')) {
      final source = _boundedString(json['url'], '$path.url', 1, 2048);
      url = Uri.tryParse(source);
      if (url == null ||
          !url.hasScheme ||
          (url.scheme != 'https' && url.scheme != 'http') ||
          !url.hasAuthority ||
          url.host.isEmpty ||
          url.userInfo.isNotEmpty) {
        _fail(
          'invalidUri',
          '$path.url',
          'Expected an HTTP(S) URI without embedded credentials.',
        );
      }
    }
    return GamePackageParty(name: name, url: url);
  }

  GamePackageCompatibility _compatibility(Object? value) {
    const path = r'$.compatibility';
    final json = _object(
      value,
      path,
      required: const <String>{
        'minHubVersion',
        'runtimeApi',
        'projectFormat',
        'saveFormat',
        'compatibilityId',
        'requiredCapabilities',
      },
      optional: const <String>{},
    );
    final minHubVersion =
        _version(json['minHubVersion'], '$path.minHubVersion');
    final runtimeApiExpression =
        _boundedString(json['runtimeApi'], '$path.runtimeApi', 1, 128);
    try {
      VersionConstraint.parse(runtimeApiExpression);
    } on FormatException {
      _fail(
        'invalidVersionConstraint',
        '$path.runtimeApi',
        'Invalid runtime API version constraint.',
      );
    }
    final projectFormat = _string(json['projectFormat'], '$path.projectFormat');
    if (!_projectFormat.hasMatch(projectFormat)) {
      _fail(
        'invalidProjectFormat',
        '$path.projectFormat',
        'projectFormat must use the vN token form.',
      );
    }
    final saveFormat = _integer(json['saveFormat'], '$path.saveFormat');
    if (saveFormat < 1 || saveFormat > CanonicalJson.maxSafeInteger) {
      _fail(
        'invalidSaveFormat',
        '$path.saveFormat',
        'saveFormat must be a positive interoperable JSON integer.',
      );
    }
    final compatibilityId = _boundedString(
      json['compatibilityId'],
      '$path.compatibilityId',
      1,
      128,
    );
    if (!_compatibilityId.hasMatch(compatibilityId)) {
      _fail(
        'invalidCompatibilityId',
        '$path.compatibilityId',
        'Invalid compatibilityId.',
      );
    }
    final capabilityValues =
        _list(json['requiredCapabilities'], '$path.requiredCapabilities');
    if (capabilityValues.length > 128) {
      _fail(
        'tooManyCapabilities',
        '$path.requiredCapabilities',
        'At most 128 capabilities are allowed.',
      );
    }
    final capabilities = <String>[];
    final seen = <String>{};
    for (var index = 0; index < capabilityValues.length; index++) {
      final capability = _boundedString(
        capabilityValues[index],
        '$path.requiredCapabilities[$index]',
        3,
        128,
      );
      if (!_capability.hasMatch(capability)) {
        _fail(
          'invalidCapability',
          '$path.requiredCapabilities[$index]',
          'Invalid required capability.',
        );
      }
      if (!seen.add(capability)) {
        _fail(
          'duplicateCapability',
          '$path.requiredCapabilities',
          'Capabilities must be unique.',
        );
      }
      capabilities.add(capability);
    }
    return GamePackageCompatibility(
      minHubVersion: minHubVersion,
      runtimeApiExpression: runtimeApiExpression,
      projectFormat: projectFormat,
      saveFormat: saveFormat,
      compatibilityId: compatibilityId,
      requiredCapabilities: capabilities,
    );
  }

  GamePackageLocales _locales(Object? value) {
    const path = r'$.locales';
    final json = _object(
      value,
      path,
      required: const <String>{'default', 'supported'},
      optional: const <String>{},
    );
    final defaultLocale =
        _boundedString(json['default'], '$path.default', 2, 35);
    final values = _list(json['supported'], '$path.supported');
    if (values.isEmpty || values.length > 64) {
      _fail(
        'invalidLocaleCount',
        '$path.supported',
        'Between 1 and 64 locales are required.',
      );
    }
    final supported = <String>[];
    final seen = <String>{};
    for (var index = 0; index < values.length; index++) {
      final locale =
          _boundedString(values[index], '$path.supported[$index]', 2, 35);
      if (!_locale.hasMatch(locale)) {
        _fail(
          'invalidLocale',
          '$path.supported[$index]',
          'Invalid locale tag.',
        );
      }
      if (!seen.add(locale)) {
        _fail(
          'duplicateLocale',
          '$path.supported',
          'Supported locales must be unique.',
        );
      }
      supported.add(locale);
    }
    if (!_locale.hasMatch(defaultLocale)) {
      _fail('invalidLocale', '$path.default', 'Invalid default locale.');
    }
    if (!seen.contains(defaultLocale)) {
      _fail(
        'defaultLocaleNotSupported',
        '$path.default',
        'Default locale must be present in supported locales.',
      );
    }
    return GamePackageLocales(
      defaultLocale: defaultLocale,
      supported: supported,
    );
  }

  GamePackagePresentation _presentation(Object? value) {
    const path = r'$.presentation';
    final json = _object(
      value,
      path,
      required: const <String>{'schemaVersion', 'branding'},
      optional: const <String>{'intro'},
    );
    final schemaVersion =
        _integer(json['schemaVersion'], '$path.schemaVersion');
    if (schemaVersion != 1) {
      _fail(
        'presentationVersionUnsupported',
        '$path.schemaVersion',
        'Only presentation schema version 1 is supported.',
      );
    }
    return GamePackagePresentation(
      schemaVersion: schemaVersion,
      branding: _branding(
        json['branding'],
        path: '$path.branding',
      ),
      intro: json.containsKey('intro')
          ? _intro(json['intro'], path: '$path.intro')
          : null,
    );
  }

  GamePackageIntroVideo _intro(
    Object? value, {
    required String path,
  }) {
    final json = _object(
      value,
      path,
      required: const <String>{
        'video',
        'poster',
        'durationMilliseconds',
        'width',
        'height',
        'bitrateKbps',
        'sizeBytes',
        'videoCodec',
        'audioCodec',
        'reducedMotionBehavior',
        'allowReplay',
      },
      optional: const <String>{'captions'},
    );
    String packagePath(String field) {
      final result = _boundedString(json[field], '$path.$field', 1, 512);
      PackagePathPolicy.validate(result, errorPath: '$path.$field');
      return result;
    }

    final video = packagePath('video');
    final poster = packagePath('poster');
    final captions =
        json.containsKey('captions') ? packagePath('captions') : null;
    final duration =
        _integer(json['durationMilliseconds'], '$path.durationMilliseconds');
    final width = _integer(json['width'], '$path.width');
    final height = _integer(json['height'], '$path.height');
    final bitrate = _integer(json['bitrateKbps'], '$path.bitrateKbps');
    final size = _integer(json['sizeBytes'], '$path.sizeBytes');
    final videoCodec = _string(json['videoCodec'], '$path.videoCodec');
    final audioCodec = _string(json['audioCodec'], '$path.audioCodec');
    final reducedMotion =
        _string(json['reducedMotionBehavior'], '$path.reducedMotionBehavior');
    final allowReplay = _boolean(json['allowReplay'], '$path.allowReplay');
    if (!video.toLowerCase().endsWith('.mp4') ||
        !const <String>['.png', '.jpg', '.jpeg', '.webp']
            .any(poster.toLowerCase().endsWith) ||
        (captions != null && !captions.toLowerCase().endsWith('.vtt')) ||
        duration <= 0 ||
        duration > projectIntroVideoMaxDurationMilliseconds ||
        width <= 0 ||
        width > projectIntroVideoMaxWidth ||
        height <= 0 ||
        height > projectIntroVideoMaxHeight ||
        bitrate <= 0 ||
        bitrate > projectIntroVideoMaxBitrateKbps ||
        size <= 0 ||
        size > projectIntroVideoMaxSizeBytes ||
        videoCodec != 'h264' ||
        !const <String>{'aac', 'none'}.contains(audioCodec) ||
        !const <String>{'poster', 'skip'}.contains(reducedMotion)) {
      _fail(
        'invalidIntroVideoMetadata',
        path,
        'Intro video metadata exceeds the supported playback contract.',
      );
    }
    return GamePackageIntroVideo(
      video: video,
      poster: poster,
      captions: captions,
      durationMilliseconds: duration,
      width: width,
      height: height,
      bitrateKbps: bitrate,
      sizeBytes: size,
      videoCodec: videoCodec,
      audioCodec: audioCodec,
      reducedMotionBehavior: reducedMotion,
      allowReplay: allowReplay,
    );
  }

  GamePackageBranding _branding(
    Object? value, {
    String path = r'$.branding',
  }) {
    final json = _object(
      value,
      path,
      required: const <String>{},
      optional: const <String>{
        'icon',
        'cover',
        'hero',
        'accentColor',
        'titleMusic',
        'layoutVariant',
      },
    );
    String? packagePath(String field) {
      if (!json.containsKey(field)) return null;
      final result = _boundedString(json[field], '$path.$field', 1, 512);
      PackagePathPolicy.validate(result, errorPath: '$path.$field');
      return result;
    }

    final accentColor = json.containsKey('accentColor')
        ? _boundedString(
            json['accentColor'],
            '$path.accentColor',
            7,
            9,
          )
        : null;
    if (accentColor != null && !_accentColor.hasMatch(accentColor)) {
      _fail(
        'invalidAccentColor',
        '$path.accentColor',
        'Expected #RRGGBB or #RRGGBBAA.',
      );
    }
    final layoutVariant = json.containsKey('layoutVariant')
        ? _string(json['layoutVariant'], '$path.layoutVariant')
        : null;
    if (layoutVariant != null &&
        !const <String>{'standard', 'centered', 'cinematic'}
            .contains(layoutVariant)) {
      _fail(
        'invalidLayoutVariant',
        '$path.layoutVariant',
        'Unsupported title layout variant.',
      );
    }
    return GamePackageBranding(
      icon: packagePath('icon'),
      cover: packagePath('cover'),
      hero: packagePath('hero'),
      accentColor: accentColor,
      titleMusic: packagePath('titleMusic'),
      layoutVariant: layoutVariant,
    );
  }

  GamePackageContent _content(Object? value) {
    const path = r'$.content';
    final json = _object(
      value,
      path,
      required: const <String>{
        'fileCount',
        'totalBytes',
        'treeSha256',
        'files',
      },
      optional: const <String>{},
    );
    final fileCount = _integer(json['fileCount'], '$path.fileCount');
    final totalBytes = _integer(json['totalBytes'], '$path.totalBytes');
    final treeSha256 =
        _boundedString(json['treeSha256'], '$path.treeSha256', 64, 64);
    if (!_sha256.hasMatch(treeSha256)) {
      _fail('invalidSha256', '$path.treeSha256', 'Invalid SHA-256 digest.');
    }
    final fileValues = _list(json['files'], '$path.files');
    if (fileValues.isEmpty || fileValues.length > 20000) {
      _fail(
        'invalidFileCount',
        '$path.files',
        'Between 1 and 20000 payload files are required.',
      );
    }
    final files = <GamePackageFileEntry>[];
    final seen = <String>{};
    final collisionKeys = <String>{};
    String? previousPath;
    for (var index = 0; index < fileValues.length; index++) {
      final filePath = '$path.files[$index]';
      final fileJson = _object(
        fileValues[index],
        filePath,
        required: const <String>{'path', 'size', 'sha256'},
        optional: const <String>{'mediaType'},
      );
      final name = _boundedString(fileJson['path'], '$filePath.path', 1, 512);
      PackagePathPolicy.validate(name, errorPath: '$filePath.path');
      if (!seen.add(name)) {
        _fail(
          'duplicateInventoryPath',
          '$filePath.path',
          'Inventory paths must be unique.',
        );
      }
      if (!collisionKeys.add(PackagePathPolicy.collisionKey(name))) {
        _fail(
          'pathCollision',
          '$filePath.path',
          'Inventory paths collide after normalization or case folding.',
        );
      }
      if (previousPath != null &&
          PackagePathPolicy.compareUtf8(previousPath, name) >= 0) {
        _fail(
          'inventoryNotSorted',
          '$filePath.path',
          'Inventory paths must be sorted by UTF-8 bytes.',
        );
      }
      previousPath = name;
      final size = _integer(fileJson['size'], '$filePath.size');
      if (size < 0 || size > 268435456) {
        _fail(
          'invalidFileSize',
          '$filePath.size',
          'Payload file size is outside policy.',
        );
      }
      final digest =
          _boundedString(fileJson['sha256'], '$filePath.sha256', 64, 64);
      if (!_sha256.hasMatch(digest)) {
        _fail('invalidSha256', '$filePath.sha256', 'Invalid SHA-256 digest.');
      }
      final mediaType = fileJson.containsKey('mediaType')
          ? _boundedString(
              fileJson['mediaType'],
              '$filePath.mediaType',
              1,
              127,
            )
          : null;
      if (mediaType != null && !_mediaType.hasMatch(mediaType)) {
        _fail(
          'invalidMediaType',
          '$filePath.mediaType',
          'Invalid media type.',
        );
      }
      files.add(
        GamePackageFileEntry(
          path: name,
          size: size,
          sha256: digest,
          mediaType: mediaType,
        ),
      );
    }
    if (!seen.contains('project/project.json')) {
      _fail(
        'projectManifestMissing',
        '$path.files',
        'project/project.json is required.',
      );
    }
    if (fileCount != files.length) {
      _fail(
        'fileCountMismatch',
        '$path.fileCount',
        'fileCount does not match files length.',
      );
    }
    final computedTotal =
        files.fold<int>(0, (total, file) => total + file.size);
    if (totalBytes != computedTotal) {
      _fail(
        'totalBytesMismatch',
        '$path.totalBytes',
        'totalBytes does not match file sizes.',
      );
    }
    if (totalBytes < 1 || totalBytes > 1073741824) {
      _fail(
        'invalidTotalBytes',
        '$path.totalBytes',
        'Payload total is outside policy.',
      );
    }
    final computedTreeHash = ContentTreeHasher.sha256Hex(files);
    if (treeSha256 != computedTreeHash) {
      _fail(
        'treeHashMismatch',
        '$path.treeSha256',
        'treeSha256 does not match the canonical inventory tree.',
      );
    }
    return GamePackageContent(
      fileCount: fileCount,
      totalBytes: totalBytes,
      treeSha256: treeSha256,
      files: files,
    );
  }

  GamePackageSignature _signature(Object? value) {
    const path = r'$.signature';
    final json = _object(
      value,
      path,
      required: const <String>{'algorithm', 'keyId', 'value'},
      optional: const <String>{},
    );
    final algorithm = _string(json['algorithm'], '$path.algorithm');
    if (algorithm != 'ed25519') {
      _fail(
        'unsupportedSignatureAlgorithm',
        '$path.algorithm',
        'Only Ed25519 signatures are supported.',
      );
    }
    final keyId = _boundedString(json['keyId'], '$path.keyId', 1, 128);
    if (!_keyId.hasMatch(keyId)) {
      _fail('invalidKeyId', '$path.keyId', 'Invalid publisher key ID.');
    }
    final encodedValue = _boundedString(json['value'], '$path.value', 88, 88);
    try {
      final decoded = base64Decode(encodedValue);
      if (decoded.length != 64 || base64Encode(decoded) != encodedValue) {
        throw const FormatException();
      }
    } on FormatException {
      _fail(
        'invalidSignature',
        '$path.value',
        'Expected a base64-encoded 64-byte Ed25519 signature.',
      );
    }
    return GamePackageSignature(
      algorithm: algorithm,
      keyId: keyId,
      value: encodedValue,
    );
  }

  Map<String, Object?> _object(
    Object? value,
    String path, {
    required Set<String> required,
    required Set<String> optional,
  }) {
    if (value is! Map) {
      _fail('invalidType', path, 'Expected a JSON object.');
    }
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        _fail('invalidType', path, 'JSON object keys must be strings.');
      }
      result[entry.key as String] = entry.value;
    }
    for (final field in required) {
      if (!result.containsKey(field)) {
        _fail('missingField', '$path.$field', 'Required field is missing.');
      }
    }
    final allowed = <String>{...required, ...optional};
    for (final field in result.keys) {
      if (!allowed.contains(field)) {
        _fail('unknownField', path, 'Unknown field "$field".');
      }
    }
    return result;
  }

  List<Object?> _list(Object? value, String path) {
    if (value is! List) {
      _fail('invalidType', path, 'Expected a JSON array.');
    }
    return List<Object?>.from(value);
  }

  int _integer(Object? value, String path) {
    if (value is! int) {
      _fail('invalidType', path, 'Expected an integer.');
    }
    return value;
  }

  bool _boolean(Object? value, String path) {
    if (value is! bool) {
      _fail('invalidType', path, 'Expected a boolean.');
    }
    return value;
  }

  String _string(Object? value, String path) {
    if (value is! String) {
      _fail('invalidType', path, 'Expected a string.');
    }
    return value;
  }

  String _boundedString(
    Object? value,
    String path,
    int minimum,
    int maximum,
  ) {
    final result = _string(value, path);
    final length = result.runes.length;
    if (length < minimum || length > maximum) {
      _fail(
        'invalidLength',
        path,
        'String length must be between $minimum and $maximum.',
      );
    }
    return result;
  }

  Version _version(Object? value, String path) {
    final source = _string(value, path);
    if (!_strictSemVer.hasMatch(source)) {
      _fail('invalidSemVer', path, 'Invalid strict SemVer value.');
    }
    try {
      return Version.parse(source);
    } on FormatException {
      _fail('invalidSemVer', path, 'Invalid strict SemVer value.');
    }
  }

  Never _fail(String code, String path, String message) {
    throw GamePackageFormatException(
      code: code,
      path: path,
      message: message,
    );
  }

  static final RegExp _gameId =
      RegExp(r'^[a-z][a-z0-9-]*(\.[a-z][a-z0-9-]*){2,}$');
  static final RegExp _strictSemVer = RegExp(
    r'^(0|[1-9][0-9]*)\.'
    r'(0|[1-9][0-9]*)\.'
    r'(0|[1-9][0-9]*)'
    r'(?:-((?:0|[1-9][0-9]*|[0-9]*[A-Za-z-][0-9A-Za-z-]*)'
    r'(?:\.(?:0|[1-9][0-9]*|[0-9]*[A-Za-z-][0-9A-Za-z-]*))*))?'
    r'(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?$',
  );
  static final RegExp _compatibilityId = RegExp(r'^[a-z0-9][a-z0-9._-]*$');
  static final RegExp _projectFormat = RegExp(r'^v[1-9][0-9]*$');
  static final RegExp _capability = RegExp(r'^[a-z][a-z0-9.-]*@[1-9][0-9]*$');
  static final RegExp _locale =
      RegExp(r'^[A-Za-z]{2,3}(?:-[A-Za-z0-9]{2,8})*$');
  static final RegExp _accentColor =
      RegExp(r'^#[0-9A-Fa-f]{6}(?:[0-9A-Fa-f]{2})?$');
  static final RegExp _sha256 = RegExp(r'^[0-9a-f]{64}$');
  static final RegExp _mediaType =
      RegExp(r'^[a-z0-9!#$&^_.+-]+/[a-z0-9!#$&^_.+-]+$');
  static final RegExp _keyId = RegExp(r'^[A-Za-z0-9._:-]+$');
}
