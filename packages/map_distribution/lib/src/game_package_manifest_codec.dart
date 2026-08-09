import 'dart:convert';
import 'dart:typed_data';

import 'package:map_core/map_core.dart'
    show
        ProjectPresentationProfile,
        ProjectPresentationWindowsProfile,
        ProjectSemanticThemeProfile,
        ProjectWindowStyleProfile,
        projectIntroVideoMaxBitrateKbps,
        projectIntroVideoMaxDurationMilliseconds,
        projectIntroVideoMaxHeight,
        projectIntroVideoMaxSizeBytes,
        projectIntroVideoMaxWidth,
        projectTitleLoopMaxDurationMilliseconds,
        projectTitleLoopMaxSizeBytes,
        projectTitleMotionMaxSizeBytes,
        validateProjectPresentationProfile,
        validateProjectSemanticTheme;
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
    void validateVideoReferences(
      GamePackageResponsiveVideo? media, {
      required String path,
      required String packageRoot,
      bool legacyIntro = false,
    }) {
      if (media == null) return;
      final variants = <String, GamePackageVideoVariant>{
        'landscape': media.landscape,
        if (media.portrait != null) 'portrait': media.portrait!,
      };
      for (final variant in variants.entries) {
        for (final reference in <({String field, String? value})>[
          (field: 'video', value: variant.value.video),
          (field: 'poster', value: variant.value.poster),
          (field: 'captions', value: variant.value.captions),
        ]) {
          final value = reference.value;
          if (value == null) continue;
          final referencePath = legacyIntro
              ? '$path.${reference.field}'
              : '$path.${variant.key}.${reference.field}';
          if (!value.startsWith(packageRoot)) {
            _fail(
              legacyIntro
                  ? 'invalidIntroVideoReference'
                  : 'invalidPresentationVideoReference',
              referencePath,
              'Video assets must use their presentation package root.',
            );
          }
          if (!contentPaths.contains(value)) {
            _fail(
              legacyIntro
                  ? 'introVideoReferenceMissing'
                  : 'presentationVideoReferenceMissing',
              referencePath,
              'Video reference is not present in content.files.',
            );
          }
        }
      }
    }

    validateVideoReferences(
      intro?.responsiveMedia,
      path: presentation?.schemaVersion == 1
          ? r'$.presentation.intro'
          : r'$.presentation.intro.media',
      packageRoot: 'presentation/intro/',
      legacyIntro: presentation?.schemaVersion == 1,
    );
    validateVideoReferences(
      presentation?.titleMotion?.promptLoop,
      path: r'$.presentation.titleMotion.promptLoop',
      packageRoot: 'presentation/title/prompt/',
    );
    validateVideoReferences(
      presentation?.titleMotion?.menuLoop,
      path: r'$.presentation.titleMotion.menuLoop',
      packageRoot: 'presentation/title/menu/',
    );
    final typography = presentation?.typography;
    final fontRoles = <String, GamePackageFontRole?>{
      'display': typography?.display,
      'body': typography?.body,
      'dialogue': typography?.dialogue,
      'numbers': typography?.numbers,
    };
    for (final role in fontRoles.entries) {
      for (final reference in <({String field, String? value})>[
        (field: 'font', value: role.value?.font),
        (field: 'license', value: role.value?.license),
      ]) {
        final value = reference.value;
        if (value == null) continue;
        if (!value.startsWith('presentation/fonts/')) {
          _fail(
            'invalidTypographyReference',
            '\$.presentation.typography.${role.key}.${reference.field}',
            'Typography assets must use the presentation/fonts package root.',
          );
        }
        if (!contentPaths.contains(value)) {
          _fail(
            'typographyReferenceMissing',
            '\$.presentation.typography.${role.key}.${reference.field}',
            'Typography reference is not present in content.files.',
          );
        }
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
      optional: const <String>{
        'intro',
        'titleMotion',
        'typography',
        'theme',
        'menuLabels',
        'windows',
      },
    );
    final schemaVersion =
        _integer(json['schemaVersion'], '$path.schemaVersion');
    if (schemaVersion != 1 && schemaVersion != 2 && schemaVersion != 3) {
      _fail(
        'presentationVersionUnsupported',
        '$path.schemaVersion',
        'Only presentation schema versions 1, 2 and 3 are supported.',
      );
    }
    if (schemaVersion == 1 && json.containsKey('titleMotion')) {
      _fail(
        'presentationVersionUnsupported',
        '$path.titleMotion',
        'Title motion requires presentation schema version 2.',
      );
    }
    if (schemaVersion == 1 && json.containsKey('menuLabels')) {
      _fail(
        'presentationVersionUnsupported',
        '$path.menuLabels',
        'Menu label overrides require presentation schema version 2.',
      );
    }
    if (schemaVersion < 3 && json.containsKey('windows')) {
      _fail(
        'presentationVersionUnsupported',
        '$path.windows',
        'Window styles require presentation schema version 3.',
      );
    }
    return GamePackagePresentation(
      schemaVersion: schemaVersion,
      branding: _branding(
        json['branding'],
        path: '$path.branding',
      ),
      intro: json.containsKey('intro')
          ? _intro(
              json['intro'],
              path: '$path.intro',
              schemaVersion: schemaVersion,
            )
          : null,
      titleMotion: json.containsKey('titleMotion')
          ? _titleMotion(json['titleMotion'], path: '$path.titleMotion')
          : null,
      typography: json.containsKey('typography')
          ? _typography(json['typography'], path: '$path.typography')
          : null,
      theme: json.containsKey('theme')
          ? _semanticTheme(json['theme'], path: '$path.theme')
          : null,
      menuLabels: json.containsKey('menuLabels')
          ? _menuLabels(json['menuLabels'], path: '$path.menuLabels')
          : null,
      windows: json.containsKey('windows')
          ? _windows(json['windows'], path: '$path.windows')
          : null,
    );
  }

  GamePackagePresentationWindows _windows(
    Object? value, {
    required String path,
  }) {
    final json = _object(
      value,
      path,
      required: const <String>{
        'styles',
        'defaultStyleId',
        'pauseMenuStyleId',
        'dialogueStyleId',
        'pauseBackdropOpacityPermille',
      },
      optional: const <String>{},
    );
    final styles = <GamePackageWindowStyle>[];
    final projectStyles = <ProjectWindowStyleProfile>[];
    final rawStyles = _list(json['styles'], '$path.styles');
    for (var index = 0; index < rawStyles.length; index++) {
      final stylePath = '$path.styles[$index]';
      final styleJson = _object(
        rawStyles[index],
        stylePath,
        required: const <String>{
          'id',
          'fillToken',
          'borderToken',
          'borderWidth',
          'cornerRadius',
          'contentPadding',
          'shadowElevation',
        },
        optional: const <String>{},
      );
      final style = GamePackageWindowStyle(
        id: _string(styleJson['id'], '$stylePath.id'),
        fillToken: _string(
          styleJson['fillToken'],
          '$stylePath.fillToken',
        ),
        borderToken: _string(
          styleJson['borderToken'],
          '$stylePath.borderToken',
        ),
        borderWidth: _integer(
          styleJson['borderWidth'],
          '$stylePath.borderWidth',
        ),
        cornerRadius: _integer(
          styleJson['cornerRadius'],
          '$stylePath.cornerRadius',
        ),
        contentPadding: _integer(
          styleJson['contentPadding'],
          '$stylePath.contentPadding',
        ),
        shadowElevation: _integer(
          styleJson['shadowElevation'],
          '$stylePath.shadowElevation',
        ),
      );
      styles.add(style);
      projectStyles.add(
        ProjectWindowStyleProfile(
          id: style.id,
          fillToken: style.fillToken,
          borderToken: style.borderToken,
          borderWidth: style.borderWidth,
          cornerRadius: style.cornerRadius,
          contentPadding: style.contentPadding,
          shadowElevation: style.shadowElevation,
        ),
      );
    }
    final defaultStyleId = _string(
      json['defaultStyleId'],
      '$path.defaultStyleId',
    );
    final pauseMenuStyleId = _string(
      json['pauseMenuStyleId'],
      '$path.pauseMenuStyleId',
    );
    final dialogueStyleId = _string(
      json['dialogueStyleId'],
      '$path.dialogueStyleId',
    );
    final pauseBackdropOpacity = _integer(
          json['pauseBackdropOpacityPermille'],
          '$path.pauseBackdropOpacityPermille',
        ) /
        1000;
    final projectWindows = ProjectPresentationWindowsProfile(
      styles: projectStyles,
      defaultStyleId: defaultStyleId,
      pauseMenuStyleId: pauseMenuStyleId,
      dialogueStyleId: dialogueStyleId,
      pauseBackdropOpacity: pauseBackdropOpacity,
    );
    final diagnostic = validateProjectPresentationProfile(
      ProjectPresentationProfile(windows: projectWindows),
    ).firstOrNull;
    if (diagnostic != null) {
      _fail(
        'invalidWindowStyle',
        diagnostic.path.replaceFirst(r'$.presentation.windows', path),
        diagnostic.message,
      );
    }
    return GamePackagePresentationWindows(
      styles: styles,
      defaultStyleId: defaultStyleId,
      pauseMenuStyleId: pauseMenuStyleId,
      dialogueStyleId: dialogueStyleId,
      pauseBackdropOpacity: pauseBackdropOpacity,
    );
  }

  GamePackageMenuLabels _menuLabels(
    Object? value, {
    required String path,
  }) {
    const fields = <String>{
      'pauseTitle',
      'resume',
      'party',
      'bag',
      'pokedex',
      'map',
      'save',
      'options',
      'returnToTitle',
    };
    final json = _object(
      value,
      path,
      required: const <String>{},
      optional: fields,
    );
    String? label(String field) {
      if (!json.containsKey(field)) return null;
      final label = _string(json[field], '$path.$field');
      if (label.trim().isEmpty ||
          label.runes.length > 32 ||
          RegExp(r'[\u0000-\u001F\u007F]').hasMatch(label)) {
        _fail(
          'invalidMenuLabel',
          '$path.$field',
          'Menu labels must use one to 32 readable characters.',
        );
      }
      return label;
    }

    return GamePackageMenuLabels(
      pauseTitle: label('pauseTitle'),
      resume: label('resume'),
      party: label('party'),
      bag: label('bag'),
      pokedex: label('pokedex'),
      map: label('map'),
      save: label('save'),
      options: label('options'),
      returnToTitle: label('returnToTitle'),
    );
  }

  GamePackageIntroVideo _intro(
    Object? value, {
    required String path,
    required int schemaVersion,
  }) {
    if (schemaVersion >= 2) {
      final json = _object(
        value,
        path,
        required: const <String>{
          'media',
          'reducedMotionBehavior',
          'allowReplay',
        },
        optional: const <String>{},
      );
      final reducedMotion = _string(
        json['reducedMotionBehavior'],
        '$path.reducedMotionBehavior',
      );
      if (!const <String>{'poster', 'skip'}.contains(reducedMotion)) {
        _fail(
          'invalidIntroVideoMetadata',
          path,
          'Unsupported reduced-motion behavior.',
        );
      }
      return GamePackageIntroVideo(
        media: _responsiveVideo(
          json['media'],
          path: '$path.media',
          titleLoop: false,
        ),
        reducedMotionBehavior: reducedMotion,
        allowReplay: _boolean(json['allowReplay'], '$path.allowReplay'),
      );
    }
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

  GamePackageTitleMotion _titleMotion(
    Object? value, {
    required String path,
  }) {
    final json = _object(
      value,
      path,
      required: const <String>{},
      optional: const <String>{'promptLoop', 'menuLoop'},
    );
    if (json.isEmpty) {
      _fail(
        'invalidTitleMotion',
        path,
        'Title motion must configure at least one loop.',
      );
    }
    final prompt = json.containsKey('promptLoop')
        ? _responsiveVideo(
            json['promptLoop'],
            path: '$path.promptLoop',
            titleLoop: true,
          )
        : null;
    final menu = json.containsKey('menuLoop')
        ? _responsiveVideo(
            json['menuLoop'],
            path: '$path.menuLoop',
            titleLoop: true,
          )
        : null;
    final combinedSize = <GamePackageResponsiveVideo?>[prompt, menu]
        .whereType<GamePackageResponsiveVideo>()
        .expand((media) => media.variants)
        .fold<int>(0, (total, variant) => total + variant.sizeBytes);
    if (combinedSize > projectTitleMotionMaxSizeBytes) {
      _fail(
        'invalidTitleMotion',
        path,
        'Combined title motion exceeds the package size budget.',
      );
    }
    return GamePackageTitleMotion(promptLoop: prompt, menuLoop: menu);
  }

  GamePackageResponsiveVideo _responsiveVideo(
    Object? value, {
    required String path,
    required bool titleLoop,
  }) {
    final json = _object(
      value,
      path,
      required: const <String>{'landscape'},
      optional: const <String>{'portrait'},
    );
    return GamePackageResponsiveVideo(
      landscape: _videoVariant(
        json['landscape'],
        path: '$path.landscape',
        titleLoop: titleLoop,
      ),
      portrait: json.containsKey('portrait')
          ? _videoVariant(
              json['portrait'],
              path: '$path.portrait',
              titleLoop: titleLoop,
            )
          : null,
    );
  }

  GamePackageVideoVariant _videoVariant(
    Object? value, {
    required String path,
    required bool titleLoop,
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
        'focalXPermille',
        'focalYPermille',
      },
      optional: const <String>{'captions'},
    );
    String packagePath(String field) {
      final result = _boundedString(json[field], '$path.$field', 1, 512);
      PackagePathPolicy.validate(result, errorPath: '$path.$field');
      return result;
    }

    final variant = GamePackageVideoVariant(
      video: packagePath('video'),
      poster: packagePath('poster'),
      captions: json.containsKey('captions') ? packagePath('captions') : null,
      durationMilliseconds: _integer(
        json['durationMilliseconds'],
        '$path.durationMilliseconds',
      ),
      width: _integer(json['width'], '$path.width'),
      height: _integer(json['height'], '$path.height'),
      bitrateKbps: _integer(json['bitrateKbps'], '$path.bitrateKbps'),
      sizeBytes: _integer(json['sizeBytes'], '$path.sizeBytes'),
      videoCodec: _string(json['videoCodec'], '$path.videoCodec'),
      audioCodec: _string(json['audioCodec'], '$path.audioCodec'),
      focalX: _integer(
            json['focalXPermille'],
            '$path.focalXPermille',
          ) /
          1000,
      focalY: _integer(
            json['focalYPermille'],
            '$path.focalYPermille',
          ) /
          1000,
    );
    final longestEdge =
        variant.width > variant.height ? variant.width : variant.height;
    final shortestEdge =
        variant.width < variant.height ? variant.width : variant.height;
    final maxDuration = titleLoop
        ? projectTitleLoopMaxDurationMilliseconds
        : projectIntroVideoMaxDurationMilliseconds;
    final maxSize = titleLoop
        ? projectTitleLoopMaxSizeBytes
        : projectIntroVideoMaxSizeBytes;
    if (!variant.video.toLowerCase().endsWith('.mp4') ||
        !const <String>['.png', '.jpg', '.jpeg', '.webp']
            .any(variant.poster.toLowerCase().endsWith) ||
        (variant.captions != null &&
            !variant.captions!.toLowerCase().endsWith('.vtt')) ||
        variant.durationMilliseconds <= 0 ||
        variant.durationMilliseconds > maxDuration ||
        longestEdge > projectIntroVideoMaxWidth ||
        shortestEdge > projectIntroVideoMaxHeight ||
        variant.bitrateKbps <= 0 ||
        variant.bitrateKbps > projectIntroVideoMaxBitrateKbps ||
        variant.sizeBytes <= 0 ||
        variant.sizeBytes > maxSize ||
        variant.videoCodec != 'h264' ||
        (titleLoop
            ? variant.audioCodec != 'none'
            : !const <String>{'aac', 'none'}.contains(variant.audioCodec)) ||
        variant.focalX < 0 ||
        variant.focalX > 1 ||
        variant.focalY < 0 ||
        variant.focalY > 1) {
      _fail(
        titleLoop ? 'invalidTitleMotion' : 'invalidIntroVideoMetadata',
        path,
        'Video metadata exceeds the supported playback contract.',
      );
    }
    return variant;
  }

  GamePackageTypography _typography(
    Object? value, {
    required String path,
  }) {
    final json = _object(
      value,
      path,
      required: const <String>{'display', 'body', 'dialogue', 'numbers'},
      optional: const <String>{},
    );
    return GamePackageTypography(
      display: _fontRole(json['display'], path: '$path.display'),
      body: _fontRole(json['body'], path: '$path.body'),
      dialogue: _fontRole(json['dialogue'], path: '$path.dialogue'),
      numbers: _fontRole(json['numbers'], path: '$path.numbers'),
    );
  }

  GamePackageFontRole _fontRole(
    Object? value, {
    required String path,
  }) {
    final json = _object(
      value,
      path,
      required: const <String>{'fallbackFamilies'},
      optional: const <String>{'font', 'family', 'license'},
    );
    final rawFallbacks =
        _list(json['fallbackFamilies'], '$path.fallbackFamilies');
    final fallbacks = <String>[
      for (var index = 0; index < rawFallbacks.length; index++)
        _boundedString(
          rawFallbacks[index],
          '$path.fallbackFamilies[$index]',
          1,
          128,
        ),
    ];
    if (fallbacks.isEmpty || fallbacks.toSet().length != fallbacks.length) {
      _fail(
        'invalidTypographyFallback',
        '$path.fallbackFamilies',
        'Typography requires unique explicit system fallbacks.',
      );
    }
    final font = json.containsKey('font')
        ? _boundedString(json['font'], '$path.font', 1, 512)
        : null;
    final family = json.containsKey('family')
        ? _boundedString(json['family'], '$path.family', 1, 128)
        : null;
    final license = json.containsKey('license')
        ? _boundedString(json['license'], '$path.license', 1, 512)
        : null;
    final customFieldCount =
        <Object?>[font, family, license].where((value) => value != null).length;
    if (customFieldCount != 0 && customFieldCount != 3) {
      _fail(
        'incompleteTypographyRole',
        path,
        'Embedded typography requires font, family, and license.',
      );
    }
    if (font != null) {
      PackagePathPolicy.validate(font, errorPath: '$path.font');
      PackagePathPolicy.validate(license!, errorPath: '$path.license');
      if (!const <String>['.ttf', '.otf'].any(font.toLowerCase().endsWith) ||
          !const <String>['.txt', '.md'].any(license.toLowerCase().endsWith)) {
        _fail(
          'invalidTypographyAsset',
          path,
          'Typography must package a TTF/OTF font and text license.',
        );
      }
    }
    return GamePackageFontRole(
      font: font,
      family: family,
      license: license,
      fallbackFamilies: fallbacks,
    );
  }

  GamePackageSemanticTheme _semanticTheme(
    Object? value, {
    required String path,
  }) {
    const fields = <String>{
      'primary',
      'onPrimary',
      'background',
      'surface',
      'surfaceElevated',
      'textPrimary',
      'textSecondary',
      'outline',
      'success',
      'warning',
      'danger',
      'titleSurface',
      'dialogueSurface',
      'menuSurface',
      'overworldHudSurface',
      'battleHudSurface',
    };
    final json = _object(
      value,
      path,
      required: fields,
      optional: const <String>{},
    );
    String color(String field) =>
        _boundedString(json[field], '$path.$field', 7, 7);

    final projectTheme = ProjectSemanticThemeProfile(
      primary: color('primary'),
      onPrimary: color('onPrimary'),
      background: color('background'),
      surface: color('surface'),
      surfaceElevated: color('surfaceElevated'),
      textPrimary: color('textPrimary'),
      textSecondary: color('textSecondary'),
      outline: color('outline'),
      success: color('success'),
      warning: color('warning'),
      danger: color('danger'),
      titleSurface: color('titleSurface'),
      dialogueSurface: color('dialogueSurface'),
      menuSurface: color('menuSurface'),
      overworldHudSurface: color('overworldHudSurface'),
      battleHudSurface: color('battleHudSurface'),
    );
    if (validateProjectSemanticTheme(projectTheme).isNotEmpty) {
      _fail(
        'invalidSemanticTheme',
        path,
        'Semantic theme colors must be valid and meet contrast requirements.',
      );
    }
    return GamePackageSemanticTheme(
      primary: projectTheme.primary,
      onPrimary: projectTheme.onPrimary,
      background: projectTheme.background,
      surface: projectTheme.surface,
      surfaceElevated: projectTheme.surfaceElevated,
      textPrimary: projectTheme.textPrimary,
      textSecondary: projectTheme.textSecondary,
      outline: projectTheme.outline,
      success: projectTheme.success,
      warning: projectTheme.warning,
      danger: projectTheme.danger,
      titleSurface: projectTheme.titleSurface,
      dialogueSurface: projectTheme.dialogueSurface,
      menuSurface: projectTheme.menuSurface,
      overworldHudSurface: projectTheme.overworldHudSurface,
      battleHudSurface: projectTheme.battleHudSurface,
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
