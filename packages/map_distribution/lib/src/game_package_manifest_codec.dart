import 'dart:convert';
import 'dart:typed_data';

import 'package:map_core/map_core.dart'
    show
        ProjectPresentationProfile,
        ProjectDialoguePresentationProfile,
        ProjectPauseActionIcon,
        ProjectPauseActionId,
        ProjectPauseActionProfile,
        ProjectPauseCompositionVariantProfile,
        ProjectPauseEntrySize,
        ProjectPauseEntrySpacing,
        ProjectPausePresentationProfile,
        ProjectResponsivePauseCompositionProfile,
        ProjectPresentationBreakpoint,
        ProjectPresentationContentWidth,
        ProjectPresentationLayoutSlot,
        ProjectPresentationLayoutsProfile,
        ProjectPresentationScreenMargin,
        ProjectPresentationSecondaryElement,
        ProjectPresentationSpacing,
        ProjectPresentationSurfacePalettesProfile,
        ProjectResponsiveSurfaceLayoutProfile,
        ProjectSurfacePaletteProfile,
        ProjectSurfaceLayoutVariant,
        ProjectPresentationWindowsProfile,
        ProjectSemanticThemeProfile,
        ProjectTypographyMetricsProfile,
        ProjectTypographyProfile,
        ProjectTypographyRoleProfile,
        ProjectTitlePresentationProfile,
        ProjectTitleActionIcon,
        ProjectTitleActionId,
        ProjectTitleActionProfile,
        ProjectWindowShape,
        ProjectWindowStyleProfile,
        safeProjectSemanticTheme,
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
    final minHubVersion = _version(
      json['minHubVersion'],
      '$path.minHubVersion',
    );
    final runtimeApiExpression = _boundedString(
      json['runtimeApi'],
      '$path.runtimeApi',
      1,
      128,
    );
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
    final capabilityValues = _list(
      json['requiredCapabilities'],
      '$path.requiredCapabilities',
    );
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
    final defaultLocale = _boundedString(
      json['default'],
      '$path.default',
      2,
      35,
    );
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
      final locale = _boundedString(
        values[index],
        '$path.supported[$index]',
        2,
        35,
      );
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
        'title',
        'titleMotion',
        'typography',
        'theme',
        'surfacePalettes',
        'pause',
        'dialogue',
        'menuLabels',
        'windows',
        'layouts',
      },
    );
    final schemaVersion = _integer(
      json['schemaVersion'],
      '$path.schemaVersion',
    );
    if (schemaVersion != 1 &&
        schemaVersion != 2 &&
        schemaVersion != 3 &&
        schemaVersion != 4 &&
        schemaVersion != 5 &&
        schemaVersion != 6 &&
        schemaVersion != 7 &&
        schemaVersion != 8 &&
        schemaVersion != 9) {
      _fail(
        'presentationVersionUnsupported',
        '$path.schemaVersion',
        'Only presentation schema versions 1 through 9 are supported.',
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
    if (schemaVersion < 4 && json.containsKey('layouts')) {
      _fail(
        'presentationVersionUnsupported',
        '$path.layouts',
        'Responsive layouts require presentation schema version 4.',
      );
    }
    if (schemaVersion < 5) {
      final windows = json['windows'];
      if (windows is Map && windows.containsKey('battleStyleId')) {
        _fail(
          'presentationVersionUnsupported',
          '$path.windows.battleStyleId',
          'Combat window styles require presentation schema version 5.',
        );
      }
      final layouts = json['layouts'];
      if (layouts is Map && layouts.containsKey('battle')) {
        _fail(
          'presentationVersionUnsupported',
          '$path.layouts.battle',
          'Combat layouts require presentation schema version 5.',
        );
      }
      final typography = json['typography'];
      if (typography is Map && typography.containsKey('combat')) {
        _fail(
          'presentationVersionUnsupported',
          '$path.typography.combat',
          'Combat typography requires presentation schema version 5.',
        );
      }
    }
    if (schemaVersion < 6) {
      if (json.containsKey('surfacePalettes')) {
        _fail(
          'presentationVersionUnsupported',
          '$path.surfacePalettes',
          'Contextual surface palettes require presentation schema version 6.',
        );
      }
      final typography = json['typography'];
      if (typography is Map) {
        for (final entry in typography.entries) {
          final role = entry.value;
          if (role is Map && role.containsKey('metrics')) {
            _fail(
              'presentationVersionUnsupported',
              '$path.typography.${entry.key}.metrics',
              'Typography metrics require presentation schema version 6.',
            );
          }
        }
      }
      final windows = json['windows'];
      if (windows is Map && windows['styles'] is List) {
        final styles = windows['styles']! as List;
        for (var index = 0; index < styles.length; index++) {
          final style = styles[index];
          if (style is Map &&
              (style.containsKey('shape') ||
                  style.containsKey('fillOpacityPermille'))) {
            _fail(
              'presentationVersionUnsupported',
              '$path.windows.styles[$index]',
              'Window shapes and fill opacity require presentation schema version 6.',
            );
          }
        }
      }
    }
    if (schemaVersion < 7 && json.containsKey('title')) {
      _fail(
        'presentationVersionUnsupported',
        '$path.title',
        'Title copy requires presentation schema version 7.',
      );
    }
    if (schemaVersion < 8 && json.containsKey('pause')) {
      _fail(
        'presentationVersionUnsupported',
        '$path.pause',
        'Pause actions require presentation schema version 8.',
      );
    }
    if (schemaVersion < 9 && json.containsKey('dialogue')) {
      _fail(
        'presentationVersionUnsupported',
        '$path.dialogue',
        'Dialogue presentation requires schema version 9.',
      );
    }
    final typography = json.containsKey('typography')
        ? _typography(
            json['typography'],
            path: '$path.typography',
            schemaVersion: schemaVersion,
          )
        : null;
    final theme = json.containsKey('theme')
        ? _semanticTheme(json['theme'], path: '$path.theme')
        : null;
    final surfacePalettes = json.containsKey('surfacePalettes')
        ? _surfacePalettes(
            json['surfacePalettes'],
            path: '$path.surfacePalettes',
            inheritedTheme: theme,
          )
        : null;
    return GamePackagePresentation(
      schemaVersion: schemaVersion,
      branding: _branding(json['branding'], path: '$path.branding'),
      title: json.containsKey('title')
          ? _titlePresentation(json['title'], path: '$path.title')
          : null,
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
      typography: typography,
      theme: theme,
      surfacePalettes: surfacePalettes,
      pause: json.containsKey('pause')
          ? _pausePresentation(json['pause'], path: '$path.pause')
          : null,
      dialogue: json.containsKey('dialogue')
          ? _dialoguePresentation(json['dialogue'], path: '$path.dialogue')
          : null,
      menuLabels: json.containsKey('menuLabels')
          ? _menuLabels(json['menuLabels'], path: '$path.menuLabels')
          : null,
      windows: json.containsKey('windows')
          ? _windows(
              json['windows'],
              path: '$path.windows',
              schemaVersion: schemaVersion,
            )
          : null,
      layouts: json.containsKey('layouts')
          ? _layouts(json['layouts'], path: '$path.layouts')
          : null,
    );
  }

  GamePackageTitlePresentation _titlePresentation(
    Object? value, {
    required String path,
  }) {
    final json = _object(
      value,
      path,
      required: const <String>{},
      optional: const <String>{'title', 'subtitle', 'prompt', 'actions'},
    );
    String? copy(String field) =>
        json.containsKey(field) ? _string(json[field], '$path.$field') : null;
    final title = copy('title');
    final subtitle = copy('subtitle');
    final prompt = copy('prompt');
    final actions = json.containsKey('actions')
        ? _titleActions(json['actions'], path: '$path.actions')
        : null;
    final diagnostic = validateProjectPresentationProfile(
      ProjectPresentationProfile(
        title: ProjectTitlePresentationProfile(
          title: title,
          subtitle: subtitle,
          prompt: prompt,
          actions: actions
              ?.map(
                (action) => ProjectTitleActionProfile(
                  id: ProjectTitleActionId.values.byName(action.id),
                  label: action.label,
                  icon: action.icon == null
                      ? null
                      : ProjectTitleActionIcon.values.byName(action.icon!),
                  visible: action.visible,
                ),
              )
              .toList(growable: false),
        ),
      ),
    ).firstOrNull;
    if (diagnostic != null) {
      _fail(
        'invalidTitleCopy',
        diagnostic.path.replaceFirst(r'$.presentation.title', path),
        diagnostic.message,
      );
    }
    return GamePackageTitlePresentation(
      title: title,
      subtitle: subtitle,
      prompt: prompt,
      actions: actions,
    );
  }

  List<GamePackageTitleAction> _titleActions(
    Object? value, {
    required String path,
  }) {
    final values = _list(value, path);
    return <GamePackageTitleAction>[
      for (var index = 0; index < values.length; index++)
        _titleAction(values[index], path: '$path[$index]'),
    ];
  }

  GamePackageTitleAction _titleAction(Object? value, {required String path}) {
    final json = _object(
      value,
      path,
      required: const <String>{'id'},
      optional: const <String>{'label', 'icon', 'visible'},
    );
    final id = _string(json['id'], '$path.id');
    final icon =
        json.containsKey('icon') ? _string(json['icon'], '$path.icon') : null;
    if (!ProjectTitleActionId.values.any((value) => value.name == id)) {
      _fail('invalidTitleAction', '$path.id', 'Unknown title action.');
    }
    if (icon != null &&
        !ProjectTitleActionIcon.values.any((value) => value.name == icon)) {
      _fail('invalidTitleAction', '$path.icon', 'Unknown title action icon.');
    }
    return GamePackageTitleAction(
      id: id,
      label: json.containsKey('label')
          ? _string(json['label'], '$path.label')
          : null,
      icon: icon,
      visible: json.containsKey('visible')
          ? _boolean(json['visible'], '$path.visible')
          : true,
    );
  }

  GamePackagePresentationLayouts _layouts(
    Object? value, {
    required String path,
  }) {
    final json = _object(
      value,
      path,
      required: const <String>{'title', 'pauseMenu', 'dialogue'},
      optional: const <String>{'battle'},
    );
    final title = _responsiveLayout(json['title'], path: '$path.title');
    final pauseMenu = _responsiveLayout(
      json['pauseMenu'],
      path: '$path.pauseMenu',
    );
    final dialogue = _responsiveLayout(
      json['dialogue'],
      path: '$path.dialogue',
    );
    final battle = json.containsKey('battle')
        ? _responsiveLayout(json['battle'], path: '$path.battle')
        : null;
    final projectLayouts = ProjectPresentationLayoutsProfile(
      title: _projectResponsiveLayout(title),
      pauseMenu: _projectResponsiveLayout(pauseMenu),
      dialogue: _projectResponsiveLayout(dialogue),
      battle: battle == null ? null : _projectResponsiveLayout(battle),
    );
    final diagnostic = validateProjectPresentationProfile(
      ProjectPresentationProfile(layouts: projectLayouts),
    ).firstOrNull;
    if (diagnostic != null) {
      _fail(
        'invalidPresentationLayout',
        diagnostic.path.replaceFirst(r'$.presentation.layouts', path),
        diagnostic.message,
      );
    }
    return GamePackagePresentationLayouts(
      title: title,
      pauseMenu: pauseMenu,
      dialogue: dialogue,
      battle: battle,
    );
  }

  GamePackageResponsiveSurfaceLayout _responsiveLayout(
    Object? value, {
    required String path,
  }) {
    final json = _object(
      value,
      path,
      required: const <String>{'compact', 'regular', 'expanded'},
      optional: const <String>{},
    );
    return GamePackageResponsiveSurfaceLayout(
      compact: _layoutVariant(json['compact'], path: '$path.compact'),
      regular: _layoutVariant(json['regular'], path: '$path.regular'),
      expanded: _layoutVariant(json['expanded'], path: '$path.expanded'),
    );
  }

  GamePackageSurfaceLayoutVariant _layoutVariant(
    Object? value, {
    required String path,
  }) {
    final json = _object(
      value,
      path,
      required: const <String>{
        'breakpoint',
        'slot',
        'width',
        'spacing',
        'screenMargin',
        'visibleSecondaryElements',
      },
      optional: const <String>{},
    );
    final secondary = _list(
      json['visibleSecondaryElements'],
      '$path.visibleSecondaryElements',
    );
    return GamePackageSurfaceLayoutVariant(
      breakpoint: _string(json['breakpoint'], '$path.breakpoint'),
      slot: _string(json['slot'], '$path.slot'),
      width: _string(json['width'], '$path.width'),
      spacing: _string(json['spacing'], '$path.spacing'),
      screenMargin: _string(json['screenMargin'], '$path.screenMargin'),
      visibleSecondaryElements: <String>[
        for (var index = 0; index < secondary.length; index++)
          _string(secondary[index], '$path.visibleSecondaryElements[$index]'),
      ],
    );
  }

  ProjectResponsiveSurfaceLayoutProfile _projectResponsiveLayout(
    GamePackageResponsiveSurfaceLayout layout,
  ) =>
      ProjectResponsiveSurfaceLayoutProfile(
        compact: _projectLayoutVariant(layout.compact),
        regular: _projectLayoutVariant(layout.regular),
        expanded: _projectLayoutVariant(layout.expanded),
      );

  ProjectSurfaceLayoutVariant _projectLayoutVariant(
    GamePackageSurfaceLayoutVariant variant,
  ) {
    T named<T extends Enum>(List<T> values, String value, String field) {
      for (final candidate in values) {
        if (candidate.name == value) return candidate;
      }
      _fail(
        'invalidPresentationLayout',
        r'$.presentation.layouts.' + field,
        'Unknown responsive layout value.',
      );
    }

    return ProjectSurfaceLayoutVariant(
      breakpoint: named(
        ProjectPresentationBreakpoint.values,
        variant.breakpoint,
        'breakpoint',
      ),
      slot: named(ProjectPresentationLayoutSlot.values, variant.slot, 'slot'),
      width: named(
        ProjectPresentationContentWidth.values,
        variant.width,
        'width',
      ),
      spacing: named(
        ProjectPresentationSpacing.values,
        variant.spacing,
        'spacing',
      ),
      screenMargin: named(
        ProjectPresentationScreenMargin.values,
        variant.screenMargin,
        'screenMargin',
      ),
      visibleSecondaryElements: <ProjectPresentationSecondaryElement>[
        for (final element in variant.visibleSecondaryElements)
          named(
            ProjectPresentationSecondaryElement.values,
            element,
            'visibleSecondaryElements',
          ),
      ],
    );
  }

  GamePackagePresentationWindows _windows(
    Object? value, {
    required String path,
    required int schemaVersion,
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
      optional: const <String>{'battleStyleId'},
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
        optional: schemaVersion >= 6
            ? const <String>{'shape', 'fillOpacityPermille'}
            : const <String>{},
      );
      final shape = styleJson.containsKey('shape')
          ? _string(styleJson['shape'], '$stylePath.shape')
          : 'rounded';
      final projectShape = ProjectWindowShape.values
          .where((candidate) => candidate.name == shape)
          .firstOrNull;
      if (projectShape == null) {
        _fail(
          'invalidWindowStyle',
          '$stylePath.shape',
          'Unknown window shape.',
        );
      }
      final fillOpacity = styleJson.containsKey('fillOpacityPermille')
          ? _integer(
                styleJson['fillOpacityPermille'],
                '$stylePath.fillOpacityPermille',
              ) /
              1000
          : 1.0;
      final style = GamePackageWindowStyle(
        id: _string(styleJson['id'], '$stylePath.id'),
        fillToken: _string(styleJson['fillToken'], '$stylePath.fillToken'),
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
        shape: shape,
        fillOpacity: fillOpacity,
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
          shape: projectShape,
          fillOpacity: style.fillOpacity,
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
    final battleStyleId = json.containsKey('battleStyleId')
        ? _string(json['battleStyleId'], '$path.battleStyleId')
        : null;
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
      battleStyleId: battleStyleId,
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
      battleStyleId: battleStyleId,
      pauseBackdropOpacity: pauseBackdropOpacity,
    );
  }

  GamePackageMenuLabels _menuLabels(Object? value, {required String path}) {
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

  GamePackagePausePresentation _pausePresentation(
    Object? value, {
    required String path,
  }) {
    final json = _object(
      value,
      path,
      required: const <String>{},
      optional: const <String>{'title', 'hint', 'actions', 'composition'},
    );
    String? copy(String field) =>
        json.containsKey(field) ? _string(json[field], '$path.$field') : null;
    final packagedActions = <GamePackagePauseAction>[];
    final projectActions = <ProjectPauseActionProfile>[];
    if (json.containsKey('actions')) {
      final values = _list(json['actions'], '$path.actions');
      for (var index = 0; index < values.length; index++) {
        final actionPath = '$path.actions[$index]';
        final action = _object(
          values[index],
          actionPath,
          required: const <String>{'id'},
          optional: const <String>{'label', 'icon', 'visible'},
        );
        final idName = _string(action['id'], '$actionPath.id');
        final iconName = action.containsKey('icon')
            ? _string(action['icon'], '$actionPath.icon')
            : null;
        final id = _pauseActionId(idName, '$actionPath.id');
        final icon = iconName == null
            ? null
            : _pauseActionIcon(iconName, '$actionPath.icon');
        final label = action.containsKey('label')
            ? _string(action['label'], '$actionPath.label')
            : null;
        final visible = action.containsKey('visible')
            ? _boolean(action['visible'], '$actionPath.visible')
            : true;
        projectActions.add(
          ProjectPauseActionProfile(
            id: id,
            label: label,
            icon: icon,
            visible: visible,
          ),
        );
        packagedActions.add(
          GamePackagePauseAction(
            id: idName,
            label: label,
            icon: iconName,
            visible: visible,
          ),
        );
      }
    }
    final title = copy('title');
    final hint = copy('hint');
    final composition = json.containsKey('composition')
        ? _pauseComposition(json['composition'], path: '$path.composition')
        : null;
    final diagnostic = validateProjectPresentationProfile(
      ProjectPresentationProfile(
        pause: ProjectPausePresentationProfile(
          title: title,
          hint: hint,
          actions: json.containsKey('actions') ? projectActions : null,
          composition: composition?.project,
        ),
      ),
    ).firstOrNull;
    if (diagnostic != null) {
      _fail(
        'invalidPausePresentation',
        diagnostic.path.replaceFirst(r'$.presentation.pause', path),
        diagnostic.message,
      );
    }
    return GamePackagePausePresentation(
      title: title,
      hint: hint,
      actions: json.containsKey('actions') ? packagedActions : null,
      composition: composition?.packaged,
    );
  }

  GamePackageDialoguePresentation _dialoguePresentation(
    Object? value, {
    required String path,
  }) {
    final json = _object(
      value,
      path,
      required: const <String>{
        'placement',
        'maxWidthFactor',
        'margin',
        'contentPadding',
        'shape',
        'cornerRadius',
        'borderWidth',
        'fillOpacity',
      },
      optional: const <String>{
        'surfaceColor',
        'borderColor',
        'textColor',
        'portraitSide',
        'portraitSize',
        'portraitShape',
        'portraitFrameWidth',
        'portraitFrameColor',
        'nameplateStyle',
        'nameplateBorderWidth',
        'nameplateSurfaceColor',
        'nameplateBorderColor',
        'nameplateTextColor',
        'choiceSpacing',
        'choiceShape',
        'choiceDisabledOpacity',
        'choiceSelectedColor',
        'progressIndicator',
        'progressIndicatorColor',
        'portraitTransition',
        'portraitTransitionMilliseconds',
      },
    );
    final profile = ProjectDialoguePresentationProfile.fromJson(
      Map<String, dynamic>.from(json),
    );
    final diagnostic = validateProjectPresentationProfile(
      ProjectPresentationProfile(dialogue: profile),
    ).firstOrNull;
    if (diagnostic != null) {
      _fail(
        'invalidDialoguePresentation',
        diagnostic.path.replaceFirst(r'$.presentation.dialogue', path),
        diagnostic.message,
      );
    }
    return GamePackageDialoguePresentation(
      placement: profile.placement.name,
      maxWidthFactor: profile.maxWidthFactor,
      margin: profile.margin,
      contentPadding: profile.contentPadding,
      shape: profile.shape.name,
      cornerRadius: profile.cornerRadius,
      borderWidth: profile.borderWidth,
      fillOpacity: profile.fillOpacity,
      surfaceColor: profile.surfaceColor,
      borderColor: profile.borderColor,
      textColor: profile.textColor,
      portraitSide: profile.portraitSide.name,
      portraitSize: profile.portraitSize,
      portraitShape: profile.portraitShape.name,
      portraitFrameWidth: profile.portraitFrameWidth,
      portraitFrameColor: profile.portraitFrameColor,
      nameplateStyle: profile.nameplateStyle.name,
      nameplateBorderWidth: profile.nameplateBorderWidth,
      nameplateSurfaceColor: profile.nameplateSurfaceColor,
      nameplateBorderColor: profile.nameplateBorderColor,
      nameplateTextColor: profile.nameplateTextColor,
      choiceSpacing: profile.choiceSpacing,
      choiceShape: profile.choiceShape.name,
      choiceDisabledOpacity: profile.choiceDisabledOpacity,
      choiceSelectedColor: profile.choiceSelectedColor,
      progressIndicator: profile.progressIndicator.name,
      progressIndicatorColor: profile.progressIndicatorColor,
      portraitTransition: profile.portraitTransition.name,
      portraitTransitionMilliseconds: profile.portraitTransitionMilliseconds,
    );
  }

  ({
    ProjectResponsivePauseCompositionProfile project,
    GamePackageResponsivePauseComposition packaged,
  }) _pauseComposition(Object? value, {required String path}) {
    final json = _object(
      value,
      path,
      required: const <String>{
        'compactPortrait',
        'compactLandscape',
        'expanded',
      },
      optional: const <String>{},
    );
    final compactPortrait = _pauseCompositionVariant(
      json['compactPortrait'],
      path: '$path.compactPortrait',
    );
    final compactLandscape = _pauseCompositionVariant(
      json['compactLandscape'],
      path: '$path.compactLandscape',
    );
    final expanded = _pauseCompositionVariant(
      json['expanded'],
      path: '$path.expanded',
    );
    return (
      project: ProjectResponsivePauseCompositionProfile(
        compactPortrait: compactPortrait.project,
        compactLandscape: compactLandscape.project,
        expanded: expanded.project,
      ),
      packaged: GamePackageResponsivePauseComposition(
        compactPortrait: compactPortrait.packaged,
        compactLandscape: compactLandscape.packaged,
        expanded: expanded.packaged,
      ),
    );
  }

  ({
    ProjectPauseCompositionVariantProfile project,
    GamePackagePauseCompositionVariant packaged,
  }) _pauseCompositionVariant(Object? value, {required String path}) {
    final json = _object(
      value,
      path,
      required: const <String>{
        'entrySize',
        'entrySpacing',
        'showTitle',
        'showHint',
        'showRootDetailPanel',
      },
      optional: const <String>{},
    );
    final sizeName = _string(json['entrySize'], '$path.entrySize');
    final spacingName = _string(json['entrySpacing'], '$path.entrySpacing');
    final entrySize = _pauseEntrySize(sizeName, '$path.entrySize');
    final entrySpacing = _pauseEntrySpacing(spacingName, '$path.entrySpacing');
    final showTitle = _boolean(json['showTitle'], '$path.showTitle');
    final showHint = _boolean(json['showHint'], '$path.showHint');
    final showRootDetailPanel = _boolean(
      json['showRootDetailPanel'],
      '$path.showRootDetailPanel',
    );
    return (
      project: ProjectPauseCompositionVariantProfile(
        entrySize: entrySize,
        entrySpacing: entrySpacing,
        showTitle: showTitle,
        showHint: showHint,
        showRootDetailPanel: showRootDetailPanel,
      ),
      packaged: GamePackagePauseCompositionVariant(
        entrySize: sizeName,
        entrySpacing: spacingName,
        showTitle: showTitle,
        showHint: showHint,
        showRootDetailPanel: showRootDetailPanel,
      ),
    );
  }

  ProjectPauseEntrySize _pauseEntrySize(String value, String path) {
    for (final size in ProjectPauseEntrySize.values) {
      if (size.name == value) return size;
    }
    _fail('invalidPausePresentation', path, 'Unknown pause entry size.');
  }

  ProjectPauseEntrySpacing _pauseEntrySpacing(String value, String path) {
    for (final spacing in ProjectPauseEntrySpacing.values) {
      if (spacing.name == value) return spacing;
    }
    _fail('invalidPausePresentation', path, 'Unknown pause entry spacing.');
  }

  ProjectPauseActionId _pauseActionId(String value, String path) {
    for (final id in ProjectPauseActionId.values) {
      if (id.name == value) return id;
    }
    _fail('invalidPausePresentation', path, 'Unknown pause action id.');
  }

  ProjectPauseActionIcon _pauseActionIcon(String value, String path) {
    for (final icon in ProjectPauseActionIcon.values) {
      if (icon.name == value) return icon;
    }
    _fail('invalidPausePresentation', path, 'Unknown pause action icon.');
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
    final duration = _integer(
      json['durationMilliseconds'],
      '$path.durationMilliseconds',
    );
    final width = _integer(json['width'], '$path.width');
    final height = _integer(json['height'], '$path.height');
    final bitrate = _integer(json['bitrateKbps'], '$path.bitrateKbps');
    final size = _integer(json['sizeBytes'], '$path.sizeBytes');
    final videoCodec = _string(json['videoCodec'], '$path.videoCodec');
    final audioCodec = _string(json['audioCodec'], '$path.audioCodec');
    final reducedMotion = _string(
      json['reducedMotionBehavior'],
      '$path.reducedMotionBehavior',
    );
    final allowReplay = _boolean(json['allowReplay'], '$path.allowReplay');
    if (!video.toLowerCase().endsWith('.mp4') ||
        !const <String>[
          '.png',
          '.jpg',
          '.jpeg',
          '.webp',
        ].any(poster.toLowerCase().endsWith) ||
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

  GamePackageTitleMotion _titleMotion(Object? value, {required String path}) {
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
      focalX: _integer(json['focalXPermille'], '$path.focalXPermille') / 1000,
      focalY: _integer(json['focalYPermille'], '$path.focalYPermille') / 1000,
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
        !const <String>[
          '.png',
          '.jpg',
          '.jpeg',
          '.webp',
        ].any(variant.poster.toLowerCase().endsWith) ||
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
    required int schemaVersion,
  }) {
    final json = _object(
      value,
      path,
      required: const <String>{'display', 'body', 'dialogue', 'numbers'},
      optional: const <String>{'combat'},
    );
    return GamePackageTypography(
      display: _fontRole(
        json['display'],
        path: '$path.display',
        allowMetrics: schemaVersion >= 6,
      ),
      body: _fontRole(
        json['body'],
        path: '$path.body',
        allowMetrics: schemaVersion >= 6,
      ),
      dialogue: _fontRole(
        json['dialogue'],
        path: '$path.dialogue',
        allowMetrics: schemaVersion >= 6,
      ),
      numbers: _fontRole(
        json['numbers'],
        path: '$path.numbers',
        allowMetrics: schemaVersion >= 6,
      ),
      combat: json.containsKey('combat')
          ? _fontRole(
              json['combat'],
              path: '$path.combat',
              allowMetrics: schemaVersion >= 6,
            )
          : null,
    );
  }

  GamePackageFontRole _fontRole(
    Object? value, {
    required String path,
    required bool allowMetrics,
  }) {
    final json = _object(
      value,
      path,
      required: const <String>{'fallbackFamilies'},
      optional: <String>{
        'font',
        'family',
        'license',
        if (allowMetrics) 'metrics',
      },
    );
    final rawFallbacks = _list(
      json['fallbackFamilies'],
      '$path.fallbackFamilies',
    );
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
    final customFieldCount = <Object?>[
      font,
      family,
      license,
    ].where((value) => value != null).length;
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
    final metrics = json.containsKey('metrics')
        ? _typographyMetrics(json['metrics'], path: '$path.metrics')
        : null;
    return GamePackageFontRole(
      font: font,
      family: family,
      license: license,
      fallbackFamilies: fallbacks,
      metrics: metrics,
    );
  }

  GamePackageTypographyMetrics _typographyMetrics(
    Object? value, {
    required String path,
  }) {
    final json = _object(
      value,
      path,
      required: const <String>{
        'sizeScalePermille',
        'weight',
        'lineHeightPermille',
        'letterSpacingMilli',
      },
      optional: const <String>{},
    );
    final metrics = GamePackageTypographyMetrics(
      sizeScale:
          _integer(json['sizeScalePermille'], '$path.sizeScalePermille') / 1000,
      weight: _integer(json['weight'], '$path.weight'),
      lineHeight:
          _integer(json['lineHeightPermille'], '$path.lineHeightPermille') /
              1000,
      letterSpacing:
          _integer(json['letterSpacingMilli'], '$path.letterSpacingMilli') /
              1000,
    );
    final profile = ProjectTypographyMetricsProfile(
      sizeScale: metrics.sizeScale,
      weight: metrics.weight,
      lineHeight: metrics.lineHeight,
      letterSpacing: metrics.letterSpacing,
    );
    final diagnostic = validateProjectPresentationProfile(
      ProjectPresentationProfile(
        typography: ProjectTypographyProfile(
          display: ProjectTypographyRoleProfile(metrics: profile),
        ),
      ),
    ).firstOrNull;
    if (diagnostic != null) {
      _fail('invalidTypographyMetrics', path, diagnostic.message);
    }
    return metrics;
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

  GamePackagePresentationSurfacePalettes _surfacePalettes(
    Object? value, {
    required String path,
    required GamePackageSemanticTheme? inheritedTheme,
  }) {
    final json = _object(
      value,
      path,
      required: const <String>{},
      optional: const <String>{'title', 'pauseMenu', 'dialogue', 'battle'},
    );
    final title = json.containsKey('title')
        ? _surfacePalette(json['title'], path: '$path.title')
        : null;
    final pauseMenu = json.containsKey('pauseMenu')
        ? _surfacePalette(json['pauseMenu'], path: '$path.pauseMenu')
        : null;
    final dialogue = json.containsKey('dialogue')
        ? _surfacePalette(json['dialogue'], path: '$path.dialogue')
        : null;
    final battle = json.containsKey('battle')
        ? _surfacePalette(json['battle'], path: '$path.battle')
        : null;
    final palettes = GamePackagePresentationSurfacePalettes(
      title: title,
      pauseMenu: pauseMenu,
      dialogue: dialogue,
      battle: battle,
    );
    final projectPalettes = ProjectPresentationSurfacePalettesProfile(
      title: _projectSurfacePalette(title),
      pauseMenu: _projectSurfacePalette(pauseMenu),
      dialogue: _projectSurfacePalette(dialogue),
      battle: _projectSurfacePalette(battle),
    );
    final diagnostic = validateProjectPresentationProfile(
      ProjectPresentationProfile(
        theme: inheritedTheme == null
            ? safeProjectSemanticTheme
            : _projectSemanticTheme(inheritedTheme),
        surfacePalettes: projectPalettes,
      ),
    ).firstOrNull;
    if (diagnostic != null) {
      _fail(
        'invalidSurfacePalette',
        diagnostic.path.replaceFirst(r'$.presentation.surfacePalettes', path),
        diagnostic.message,
      );
    }
    return palettes;
  }

  GamePackageSurfacePalette _surfacePalette(
    Object? value, {
    required String path,
  }) {
    final json = _object(
      value,
      path,
      required: const <String>{},
      optional: const <String>{
        'background',
        'surface',
        'border',
        'text',
        'accent',
        'selection',
      },
    );
    String? color(String key) =>
        json.containsKey(key) ? _string(json[key], '$path.$key') : null;
    return GamePackageSurfacePalette(
      background: color('background'),
      surface: color('surface'),
      border: color('border'),
      text: color('text'),
      accent: color('accent'),
      selection: color('selection'),
    );
  }

  ProjectSurfacePaletteProfile? _projectSurfacePalette(
    GamePackageSurfacePalette? source,
  ) =>
      source == null
          ? null
          : ProjectSurfacePaletteProfile(
              background: source.background,
              surface: source.surface,
              border: source.border,
              text: source.text,
              accent: source.accent,
              selection: source.selection,
            );

  ProjectSemanticThemeProfile _projectSemanticTheme(
    GamePackageSemanticTheme source,
  ) =>
      ProjectSemanticThemeProfile(
        primary: source.primary,
        onPrimary: source.onPrimary,
        background: source.background,
        surface: source.surface,
        surfaceElevated: source.surfaceElevated,
        textPrimary: source.textPrimary,
        textSecondary: source.textSecondary,
        outline: source.outline,
        success: source.success,
        warning: source.warning,
        danger: source.danger,
        titleSurface: source.titleSurface,
        dialogueSurface: source.dialogueSurface,
        menuSurface: source.menuSurface,
        overworldHudSurface: source.overworldHudSurface,
        battleHudSurface: source.battleHudSurface,
      );

  GamePackageBranding _branding(Object? value, {String path = r'$.branding'}) {
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
        ? _boundedString(json['accentColor'], '$path.accentColor', 7, 9)
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
        !const <String>{
          'standard',
          'centered',
          'cinematic',
        }.contains(layoutVariant)) {
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
    final treeSha256 = _boundedString(
      json['treeSha256'],
      '$path.treeSha256',
      64,
      64,
    );
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
      final digest = _boundedString(
        fileJson['sha256'],
        '$filePath.sha256',
        64,
        64,
      );
      if (!_sha256.hasMatch(digest)) {
        _fail('invalidSha256', '$filePath.sha256', 'Invalid SHA-256 digest.');
      }
      final mediaType = fileJson.containsKey('mediaType')
          ? _boundedString(fileJson['mediaType'], '$filePath.mediaType', 1, 127)
          : null;
      if (mediaType != null && !_mediaType.hasMatch(mediaType)) {
        _fail('invalidMediaType', '$filePath.mediaType', 'Invalid media type.');
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
    final computedTotal = files.fold<int>(
      0,
      (total, file) => total + file.size,
    );
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

  String _boundedString(Object? value, String path, int minimum, int maximum) {
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
    throw GamePackageFormatException(code: code, path: path, message: message);
  }

  static final RegExp _gameId = RegExp(
    r'^[a-z][a-z0-9-]*(\.[a-z][a-z0-9-]*){2,}$',
  );
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
  static final RegExp _locale = RegExp(
    r'^[A-Za-z]{2,3}(?:-[A-Za-z0-9]{2,8})*$',
  );
  static final RegExp _accentColor = RegExp(
    r'^#[0-9A-Fa-f]{6}(?:[0-9A-Fa-f]{2})?$',
  );
  static final RegExp _sha256 = RegExp(r'^[0-9a-f]{64}$');
  static final RegExp _mediaType = RegExp(
    r'^[a-z0-9!#$&^_.+-]+/[a-z0-9!#$&^_.+-]+$',
  );
  static final RegExp _keyId = RegExp(r'^[A-Za-z0-9._:-]+$');
}
