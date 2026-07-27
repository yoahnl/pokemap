import 'dart:convert';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'game_package_format_exception.dart';
import 'game_package_manifest.dart';
import 'game_package_security_policy.dart';
import 'strict_json_structure_validator.dart';

/// Enforces the format-v1 data-only, secret, and reference policy.
final class GamePackageContentValidator {
  const GamePackageContentValidator(this.policy);

  final GamePackageSecurityPolicy policy;

  void validate(
    GamePackageFileEntry inventoryEntry,
    Uint8List bytes, {
    bool streamedTextValidated = false,
  }) {
    final path = inventoryEntry.path;
    GamePackageBinarySecretScanner(path).add(bytes);
    final lowerPath = path.toLowerCase();
    final extension = p.extension(lowerPath);
    if (_isExcludedAuthorArtifact(lowerPath)) {
      _fail(
        'executableContent',
        path,
        'Authoring, save, cache, or debug artifacts are not distributable.',
      );
    }
    if (_secretFile.hasMatch(lowerPath)) {
      _fail('probableSecret', path, 'Secret-bearing file name is forbidden.');
    }
    if (_hasExecutableMagic(bytes) ||
        _forbiddenExtensions.contains(extension) ||
        !_isAllowedExtension(lowerPath, extension)) {
      _fail(
        'executableContent',
        path,
        'Package entries must contain allowlisted data only.',
      );
    }

    final expectedMediaType = _expectedMediaTypes[extension];
    if (inventoryEntry.mediaType != null &&
        inventoryEntry.mediaType != expectedMediaType) {
      _fail(
        'executableContent',
        path,
        'Declared media type does not match the file extension.',
      );
    }

    if (extension == '.json') {
      _validateJson(path, bytes);
      return;
    }
    if (extension == '.txt' || extension == '.md' || extension == '.vtt') {
      if (!streamedTextValidated) {
        final text = _decodeText(path, bytes);
        _scanText(path, text);
        if (extension == '.vtt' && !text.startsWith('WEBVTT')) {
          _fail(
            'executableContent',
            path,
            'Caption files must use WebVTT.',
          );
        }
      } else if (extension == '.vtt' && !_asciiAt(bytes, 0, 'WEBVTT')) {
        _fail(
          'executableContent',
          path,
          'Caption files must use WebVTT.',
        );
      }
      return;
    }
    if (_imageExtensions.contains(extension)) {
      final headerLength = bytes.length < policy.maxMediaHeaderBytes
          ? bytes.length
          : policy.maxMediaHeaderBytes;
      final dimensions = _imageDimensions(
        extension,
        Uint8List.sublistView(bytes, 0, headerLength),
      );
      if (dimensions == null) {
        _fail(
          'executableContent',
          path,
          'Image signature is missing or malformed.',
        );
      }
      if (dimensions.width > policy.maxImageDimension ||
          dimensions.height > policy.maxImageDimension ||
          dimensions.width * dimensions.height > policy.maxImagePixels) {
        _fail(
          'decodedAssetQuotaExceeded',
          path,
          'Decoded image dimensions exceed policy.',
        );
      }
      return;
    }
    if (!_matchesMediaMagic(extension, bytes)) {
      _fail(
        'executableContent',
        path,
        'File signature does not match its allowlisted extension.',
      );
    }
  }

  void _validateJson(String path, Uint8List bytes) {
    if (bytes.length > policy.maxJsonBytes) {
      _fail('entryTooLarge', path, 'JSON file exceeds its dedicated quota.');
    }
    final text = _decodeText(path, bytes);
    _scanText(path, text);
    const StrictJsonStructureValidator().validate(
      text,
      path: path,
      maxDepth: policy.maxJsonDepth,
      maxNodes: policy.maxJsonNodes,
    );
    late final Object? value;
    try {
      value = jsonDecode(text);
    } on FormatException {
      _fail('executableContent', path, 'Malformed JSON payload.');
    }
    _scanJson(path, value);
  }

  void _scanJson(String path, Object? root) {
    final pending = <({
      Object? value,
      String? key,
      bool referenceContext,
    })>[
      (value: root, key: null, referenceContext: false),
    ];
    while (pending.isNotEmpty) {
      final current = pending.removeLast();
      final key = current.key;
      if (key != null &&
          _secretKeys.contains(_normalizeKey(key)) &&
          _isNonEmpty(current.value)) {
        _fail('probableSecret', path, 'Explicit secret field is non-empty.');
      }
      final referenceContext =
          current.referenceContext || (key != null && _isReferenceKey(key));
      if (current.value case final String text) {
        _scanText(path, text);
        if (referenceContext && _escapesPackage(text)) {
          _fail(
            'referenceEscapesRoot',
            path,
            'Project reference escapes the installed package.',
          );
        }
      } else if (current.value case final List<Object?> values) {
        for (final child in values) {
          pending.add((
            value: child,
            key: key,
            referenceContext: referenceContext,
          ));
        }
      } else if (current.value case final Map values) {
        for (final entry in values.entries) {
          if (entry.key is String) {
            pending.add((
              value: entry.value,
              key: entry.key as String,
              referenceContext: referenceContext,
            ));
          }
        }
      }
    }
  }

  void _scanText(String path, String text) {
    if (_privatePem.hasMatch(text) || _knownToken.hasMatch(text)) {
      _fail('probableSecret', path, 'Probable credential material detected.');
    }
  }

  String _decodeText(String path, Uint8List bytes) {
    try {
      return utf8.decode(bytes, allowMalformed: false);
    } on FormatException {
      _fail('executableContent', path, 'Text data is not strict UTF-8.');
    }
  }

  bool _isAllowedExtension(String path, String extension) {
    if (path.startsWith('legal/')) {
      return extension == '.txt' || extension == '.md';
    }
    if (path.startsWith('presentation/')) {
      return _imageExtensions.contains(extension) ||
          _audioExtensions.contains(extension) ||
          _fontExtensions.contains(extension) ||
          _videoExtensions.contains(extension) ||
          _captionExtensions.contains(extension);
    }
    if (path.startsWith('project/assets/') ||
        path.startsWith('project/data/')) {
      final isMedia = _imageExtensions.contains(extension) ||
          _audioExtensions.contains(extension) ||
          _fontExtensions.contains(extension);
      if (isMedia) return true;
    }
    return path.startsWith('project/') && extension == '.json';
  }

  bool _isExcludedAuthorArtifact(String path) {
    final segments = path.split('/');
    final basename = segments.last;
    final stem = p.basenameWithoutExtension(basename);
    final normalizedStem = stem.replaceAll(RegExp(r'[-_]'), '');
    if (_excludedSegments.any(segments.contains) ||
        _excludedBasenames.contains(basename) ||
        _excludedStems.contains(stem) ||
        _excludedNormalizedStems.contains(normalizedStem)) {
      return true;
    }
    return basename.endsWith('.lock') ||
        basename.endsWith('.log') ||
        basename.endsWith('.tmp') ||
        basename.endsWith('.bak') ||
        basename.endsWith('~');
  }

  bool _hasExecutableMagic(Uint8List bytes) {
    if (_startsWith(bytes, <int>[0x4d, 0x5a]) ||
        _startsWith(bytes, <int>[0x7f, 0x45, 0x4c, 0x46]) ||
        _startsWith(bytes, <int>[0x00, 0x61, 0x73, 0x6d]) ||
        _startsWith(bytes, <int>[0x50, 0x4b, 0x03, 0x04]) ||
        _startsWith(bytes, <int>[0x23, 0x21])) {
      return true;
    }
    if (bytes.length < 4) return false;
    final word = ByteData.sublistView(bytes, 0, 4).getUint32(0);
    return const <int>{
      0xfeedface,
      0xfeedfacf,
      0xcefaedfe,
      0xcffaedfe,
      0xcafebabe,
      0xbebafeca,
    }.contains(word);
  }

  bool _matchesMediaMagic(String extension, Uint8List bytes) {
    return switch (extension) {
      '.ogg' => _asciiAt(bytes, 0, 'OggS'),
      '.wav' => _asciiAt(bytes, 0, 'RIFF') && _asciiAt(bytes, 8, 'WAVE'),
      '.flac' => _asciiAt(bytes, 0, 'fLaC'),
      '.mp3' => _asciiAt(bytes, 0, 'ID3') ||
          (bytes.length >= 2 && bytes[0] == 0xff && (bytes[1] & 0xe0) == 0xe0),
      '.m4a' => _asciiAt(bytes, 4, 'ftyp'),
      '.mp4' => _asciiAt(bytes, 4, 'ftyp'),
      '.ttf' =>
        _startsWith(bytes, <int>[0, 1, 0, 0]) || _asciiAt(bytes, 0, 'true'),
      '.otf' => _asciiAt(bytes, 0, 'OTTO'),
      '.woff2' => _asciiAt(bytes, 0, 'wOF2'),
      _ => false,
    };
  }

  ({int width, int height})? _imageDimensions(
    String extension,
    Uint8List bytes,
  ) =>
      switch (extension) {
        '.png' => _pngDimensions(bytes),
        '.jpg' || '.jpeg' => _jpegDimensions(bytes),
        '.webp' => _webpDimensions(bytes),
        _ => null,
      };

  ({int width, int height})? _pngDimensions(Uint8List bytes) {
    if (bytes.length < 24 ||
        !_startsWith(
          bytes,
          <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a],
        ) ||
        !_asciiAt(bytes, 12, 'IHDR')) {
      return null;
    }
    final data = ByteData.sublistView(bytes);
    final width = data.getUint32(16);
    final height = data.getUint32(20);
    return width > 0 && height > 0 ? (width: width, height: height) : null;
  }

  ({int width, int height})? _jpegDimensions(Uint8List bytes) {
    if (!_startsWith(bytes, <int>[0xff, 0xd8])) return null;
    var offset = 2;
    while (offset + 9 <= bytes.length) {
      if (bytes[offset] != 0xff) return null;
      while (offset < bytes.length && bytes[offset] == 0xff) {
        offset++;
      }
      if (offset >= bytes.length) return null;
      final marker = bytes[offset++];
      if (marker == 0xd9 || marker == 0xda) break;
      if (offset + 2 > bytes.length) return null;
      final length = (bytes[offset] << 8) | bytes[offset + 1];
      if (length < 2 || offset + length > bytes.length) return null;
      if (_jpegSofMarkers.contains(marker) && length >= 7) {
        final height = (bytes[offset + 3] << 8) | bytes[offset + 4];
        final width = (bytes[offset + 5] << 8) | bytes[offset + 6];
        return width > 0 && height > 0 ? (width: width, height: height) : null;
      }
      offset += length;
    }
    return null;
  }

  ({int width, int height})? _webpDimensions(Uint8List bytes) {
    if (bytes.length < 16 ||
        !_asciiAt(bytes, 0, 'RIFF') ||
        !_asciiAt(bytes, 8, 'WEBP')) {
      return null;
    }
    if (_asciiAt(bytes, 12, 'VP8X') && bytes.length >= 30) {
      return (
        width: 1 + _u24le(bytes, 24),
        height: 1 + _u24le(bytes, 27),
      );
    }
    if (_asciiAt(bytes, 12, 'VP8L') &&
        bytes.length >= 25 &&
        bytes[20] == 0x2f) {
      final width = 1 + bytes[21] + ((bytes[22] & 0x3f) << 8);
      final height =
          1 + (bytes[22] >> 6) + (bytes[23] << 2) + ((bytes[24] & 0x0f) << 10);
      return (width: width, height: height);
    }
    if (_asciiAt(bytes, 12, 'VP8 ') &&
        bytes.length >= 30 &&
        _startsWithAt(bytes, 23, <int>[0x9d, 0x01, 0x2a])) {
      final width = (bytes[26] | (bytes[27] << 8)) & 0x3fff;
      final height = (bytes[28] | (bytes[29] << 8)) & 0x3fff;
      return width > 0 && height > 0 ? (width: width, height: height) : null;
    }
    return null;
  }

  bool _escapesPackage(String source) {
    final value = source.trim();
    return value.startsWith('/') ||
        value.startsWith('\\') ||
        value.startsWith('//') ||
        _uriScheme.hasMatch(value) ||
        value.split(RegExp(r'[/\\]')).contains('..') ||
        value.contains('\u0000');
  }

  bool _isReferenceKey(String key) {
    final normalized = _normalizeKey(key);
    return _referenceKeys.contains(normalized) ||
        _camelCaseReferenceSuffix.hasMatch(key) ||
        _separatedReferenceSuffix.hasMatch(key);
  }

  bool _isNonEmpty(Object? value) => switch (value) {
        null => false,
        String() => value.isNotEmpty,
        List() => value.isNotEmpty,
        Map() => value.isNotEmpty,
        _ => true,
      };

  String _normalizeKey(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  bool _asciiAt(Uint8List bytes, int offset, String value) =>
      _startsWithAt(bytes, offset, ascii.encode(value));

  bool _startsWith(Uint8List bytes, List<int> prefix) =>
      _startsWithAt(bytes, 0, prefix);

  bool _startsWithAt(Uint8List bytes, int offset, List<int> prefix) {
    if (offset < 0 || offset + prefix.length > bytes.length) return false;
    for (var index = 0; index < prefix.length; index++) {
      if (bytes[offset + index] != prefix[index]) return false;
    }
    return true;
  }

  int _u24le(Uint8List bytes, int offset) =>
      bytes[offset] | (bytes[offset + 1] << 8) | (bytes[offset + 2] << 16);

  Never _fail(String code, String path, String message) {
    throw GamePackageFormatException(
      code: code,
      path: path,
      message: message,
    );
  }

  static const Set<String> _imageExtensions = <String>{
    '.png',
    '.jpg',
    '.jpeg',
    '.webp',
  };
  static const Set<String> _audioExtensions = <String>{
    '.ogg',
    '.wav',
    '.mp3',
    '.flac',
    '.m4a',
  };
  static const Set<String> _fontExtensions = <String>{
    '.ttf',
    '.otf',
    '.woff2',
  };
  static const Set<String> _videoExtensions = <String>{'.mp4'};
  static const Set<String> _captionExtensions = <String>{'.vtt'};
  static const Set<String> _forbiddenExtensions = <String>{
    '.dart',
    '.js',
    '.mjs',
    '.cjs',
    '.wasm',
    '.sh',
    '.bash',
    '.zsh',
    '.fish',
    '.ps1',
    '.bat',
    '.cmd',
    '.exe',
    '.dll',
    '.dylib',
    '.so',
    '.apk',
    '.ipa',
    '.zip',
    '.tar',
    '.gz',
    '.rar',
    '.7z',
    '.jar',
    '.lnk',
    '.docm',
    '.xlsm',
  };
  static const Set<String> _excludedSegments = <String>{
    '.dart_tool',
    '.idea',
    '.vscode',
    'backups',
    'build',
    'cache',
    'caches',
    'debug',
    'diagnostics',
    'fixtures',
    'logs',
    'saves',
    'seeds',
    'temp',
    'test',
    'tests',
    'tmp',
  };
  static const Set<String> _excludedBasenames = <String>{
    'runtime_host_launch_save.json',
  };
  static const Set<String> _excludedStems = <String>{
    'debug',
    'diagnostics',
    'editor-state',
    'logs',
    'runtime_host_launch_save',
    'saves',
    'seeds',
  };
  static const Set<String> _excludedNormalizedStems = <String>{
    'cache',
    'caches',
    'debug',
    'diagnostic',
    'diagnostics',
    'editorstate',
    'log',
    'logs',
    'runtimehostlaunchsave',
    'save',
    'saves',
    'seed',
    'seeds',
  };
  static const Map<String, String> _expectedMediaTypes = <String, String>{
    '.json': 'application/json',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.webp': 'image/webp',
    '.ogg': 'audio/ogg',
    '.wav': 'audio/wav',
    '.mp3': 'audio/mpeg',
    '.flac': 'audio/flac',
    '.m4a': 'audio/mp4',
    '.mp4': 'video/mp4',
    '.vtt': 'text/vtt',
    '.ttf': 'font/ttf',
    '.otf': 'font/otf',
    '.woff2': 'font/woff2',
    '.txt': 'text/plain',
    '.md': 'text/markdown',
  };
  static const Set<String> _secretKeys = <String>{
    'mistralapikey',
    'apikey',
    'accesstoken',
    'clientsecret',
    'privatekey',
    'password',
  };
  static const Set<String> _referenceKeys = <String>{
    'path',
    'paths',
    'uri',
    'uris',
    'url',
    'urls',
    'asset',
    'assets',
    'source',
    'sources',
    'file',
    'files',
    'dir',
    'directory',
    'root',
  };
  static const Set<int> _jpegSofMarkers = <int>{
    0xc0,
    0xc1,
    0xc2,
    0xc3,
    0xc5,
    0xc6,
    0xc7,
    0xc9,
    0xca,
    0xcb,
    0xcd,
    0xce,
    0xcf,
  };
  static final RegExp _secretFile = RegExp(
    r'(^|/)(?:'
    r'\.env(?:\.|$)|'
    r'(?:secrets?|credentials?|client[-_.]?secret|service[-_.]?account)'
    r'(?:\.[^/]*)?$|'
    r'.*\.(?:p12|pfx|jks|keystore|pem|key)$'
    r')',
    caseSensitive: false,
  );
  static final RegExp _camelCaseReferenceSuffix = RegExp(
    r'(?:Path|Paths|Uri|Uris|Url|Urls|Asset|Assets|Source|Sources|File|Files|'
    r'Dir|Directory|Root)$',
  );
  static final RegExp _separatedReferenceSuffix = RegExp(
    r'(?:^|[_-])(?:path|paths|uri|uris|url|urls|asset|assets|source|sources|'
    r'file|files|dir|directory|root)$',
    caseSensitive: false,
  );
  static final RegExp _privatePem =
      RegExp(r'-----BEGIN (?:[A-Z0-9 ]+ )?PRIVATE KEY-----');
  static final RegExp _knownToken = RegExp(
      r'(?:\bsk-[A-Za-z0-9_-]{16,}|\bghp_[A-Za-z0-9]{16,}|\bxox[baprs]-)');
  static final RegExp _uriScheme = RegExp(r'^[A-Za-z][A-Za-z0-9+.-]*:');
}

/// Streaming ASCII scanner for explicit credential patterns in any payload.
final class GamePackageBinarySecretScanner {
  GamePackageBinarySecretScanner(this.path);

  final String path;
  Uint8List _tail = Uint8List(0);
  int _uriState = 0;
  bool _uriAuthorityHasContent = false;

  void add(List<int> bytes) {
    if (bytes.isEmpty) return;
    // Keep regular-expression work bounded even for large homogeneous binary
    // or text payloads. Stateful URI scanning and the overlap preserve
    // cross-window matches.
    const scanChunkBytes = 16 * 1024;
    for (var offset = 0; offset < bytes.length; offset += scanChunkBytes) {
      final end = offset + scanChunkBytes < bytes.length
          ? offset + scanChunkBytes
          : bytes.length;
      _scanCredentialUris(bytes, offset, end);
      _scanChunk(bytes, offset, end);
    }
  }

  void _scanCredentialUris(List<int> bytes, int start, int end) {
    for (var index = start; index < end; index++) {
      final byte = bytes[index];
      switch (_uriState) {
        case 0:
          if (_isAsciiLetter(byte)) _uriState = 1;
        case 1:
          if (_isUriSchemeByte(byte)) {
            continue;
          }
          _uriState = byte == 0x3a ? 2 : (_isAsciiLetter(byte) ? 1 : 0);
        case 2:
          _uriState = byte == 0x2f ? 3 : 0;
        case 3:
          if (byte == 0x2f) {
            _uriState = 4;
            _uriAuthorityHasContent = false;
          } else {
            _uriState = 0;
          }
        case 4:
          if (byte == 0x40 && _uriAuthorityHasContent) {
            throw GamePackageFormatException(
              code: 'probableSecret',
              path: path,
              message: 'Probable credential material detected.',
            );
          } else if (_endsUriAuthority(byte) ||
              !_isAsciiUriAuthorityByte(byte)) {
            _uriState = 0;
            _uriAuthorityHasContent = false;
          } else {
            _uriAuthorityHasContent = true;
          }
      }
    }
  }

  void _scanChunk(List<int> bytes, int start, int end) {
    final combined = Uint8List(_tail.length + end - start)
      ..setAll(0, _tail)
      ..setRange(_tail.length, _tail.length + end - start, bytes, start);
    final text = String.fromCharCodes(combined);
    if (GamePackageContentValidator._privatePem.hasMatch(text) ||
        GamePackageContentValidator._knownToken.hasMatch(text)) {
      throw GamePackageFormatException(
        code: 'probableSecret',
        path: path,
        message: 'Probable credential material detected.',
      );
    }
    const overlapBytes = 128;
    final tailStart =
        combined.length > overlapBytes ? combined.length - overlapBytes : 0;
    _tail = Uint8List.sublistView(combined, tailStart);
  }

  static bool _isAsciiLetter(int byte) =>
      (byte >= 0x41 && byte <= 0x5a) || (byte >= 0x61 && byte <= 0x7a);

  static bool _isUriSchemeByte(int byte) =>
      _isAsciiLetter(byte) ||
      (byte >= 0x30 && byte <= 0x39) ||
      byte == 0x2b ||
      byte == 0x2d ||
      byte == 0x2e;

  static bool _endsUriAuthority(int byte) =>
      byte <= 0x20 ||
      byte == 0x2f ||
      byte == 0x5c ||
      byte == 0x3f ||
      byte == 0x23;

  static bool _isAsciiUriAuthorityByte(int byte) =>
      byte >= 0x21 && byte <= 0x7e;
}
