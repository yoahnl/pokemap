import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('design-system guardrails', () {
    test('editor UI does not add direct color references outside tokens', () {
      final regressions = _directColorReferenceRegressions();

      expect(
        regressions,
        isEmpty,
        reason: [
          'Feature UI must use design-system/theme colors only.',
          'Move new colors to PokeMapColorTokens or a semantic helper.',
          'Reduce _legacyDirectColorReferenceBaseline as files migrate.',
          ...regressions,
        ].join('\n'),
      );
    });

    test('new editor UI files do not depend on legacy chrome widgets', () {
      final regressions = _legacyChromeImportRegressions();

      expect(
        regressions,
        isEmpty,
        reason: [
          'New editor UI must use the PokeMap design system.',
          'Extend a design-system primitive before importing legacy chrome.',
          'Reduce _legacyChromeImportBaseline as files migrate.',
          ...regressions,
        ].join('\n'),
      );
    });

    test('Narrative Studio keeps the strict palette ratchet', () {
      final regressions = _narrativeStudioPaletteRegressions();

      expect(
        regressions,
        isEmpty,
        reason: [
          'Narrative Studio is the palette pilot and must stay calm.',
          'Use PokeMap design-system widgets and semantic color tokens.',
          'Allowed temporary debt: 0 legacy imports and 0 CupertinoColors refs.',
          ...regressions,
        ].join('\n'),
      );
    });

    test('desktop interaction primitives keep the strict source ratchet', () {
      final regressions = _desktopInteractionPrimitiveRegressions();

      expect(
        regressions,
        isEmpty,
        reason: [
          'Desktop design-system primitives must stay token-only and generic.',
          'Do not couple layout, split buttons, or context menus to editor state.',
          ...regressions,
        ].join('\n'),
      );
    });

    test('Gate 5 world-map paths keep a strict zero-baseline ratchet', () {
      final regressions = _gate5WorldMapRegressions();

      expect(
        regressions,
        isEmpty,
        reason: [
          'Gate 5 paths must use semantic tokens and PokeMap primitives.',
          'No historical baseline is accepted for these recomposed surfaces.',
          ...regressions,
        ].join('\n'),
      );
    });

    test('desktop source ratchet rejects imports from the editor perimeter',
        () {
      const syntheticPath =
          'lib/src/ui/design_system/pokemap_synthetic_primitive.dart';
      final source = <String>[
        "import '../../features/editor/application/world_map_tool_activation.dart';",
        "import '../../application/project_loader.dart';",
        "import '../../domain/map_document.dart';",
        "import '../panels/map_inspector_panel.dart';",
        "import '../shared/top_toolbar.dart';",
        "import 'package:map_editor/src/app/providers/project_provider.dart';",
        "import 'package:map_editor/src/ui/canvas/map_canvas.dart';",
        "import '../../theme/theme.dart';",
        "import 'editor_local_helper.dart';",
        "import 'pokemap_panel.dart';",
        "import 'dart:math';",
        "import 'package:flutter/material.dart';",
        "import 'package:collection/collection.dart';",
      ].join('\n');

      expect(
        _desktopInteractionSourceRegressions(
          relativePath: syntheticPath,
          source: source,
        ),
        const <String>[
          '$syntheticPath:1: internal import outside design system/theme',
          '$syntheticPath:2: internal import outside design system/theme',
          '$syntheticPath:3: internal import outside design system/theme',
          '$syntheticPath:4: internal import outside design system/theme',
          '$syntheticPath:5: internal import outside design system/theme',
          '$syntheticPath:6: internal import outside design system/theme',
          '$syntheticPath:7: internal import outside design system/theme',
        ],
      );
    });

    group('desktop source scanner synthetic regressions', () {
      const syntheticPath =
          'lib/src/ui/design_system/pokemap_synthetic_primitive.dart';

      test('rejects named hard-coded Color constructors', () {
        const source = '''
final argb = Color.fromARGB(255, 1, 2, 3);
final rgbo = Color.fromRGBO(1, 2, 3, 0.5);
''';

        expect(
          _desktopInteractionSourceRegressions(
            relativePath: syntheticPath,
            source: source,
          ),
          const <String>[
            '$syntheticPath:1: hard-coded Color.fromARGB constructor',
            '$syntheticPath:2: hard-coded Color.fromRGBO constructor',
          ],
        );
      });

      test('extracts a multiline import directive', () {
        const source = '''
import
  '../../application/project_loader.dart'
  show ProjectLoader;
''';

        expect(
          _desktopInteractionSourceRegressions(
            relativePath: syntheticPath,
            source: source,
          ),
          const <String>[
            '$syntheticPath:2: internal import outside design system/theme',
          ],
        );
      });

      test('extracts every conditional import URI', () {
        const source = '''
import 'package:flutter/material.dart'
    if (dart.library.io) '../../application/project_loader.dart'
    if (dart.library.html) '../panels/map_inspector_panel.dart'
    if (dart.library.js_interop) 'package:collection/collection.dart';
''';

        expect(
          _desktopInteractionSourceRegressions(
            relativePath: syntheticPath,
            source: source,
          ),
          const <String>[
            '$syntheticPath:2: internal import outside design system/theme',
            '$syntheticPath:3: internal import outside design system/theme',
          ],
        );
      });

      test('ignores comments and strings that resemble guarded source', () {
        const source = r'''
// Color(0xFF010203);
// import '../../application/project_loader.dart';
/*
Color.fromARGB(255, 1, 2, 3);
import '../panels/map_inspector_panel.dart';
*/
const example = """
Color.fromRGBO(1, 2, 3, 0.5);
import '../../domain/map_document.dart';
""";
''';

        expect(
          _desktopInteractionSourceRegressions(
            relativePath: syntheticPath,
            source: source,
          ),
          isEmpty,
        );
      });

      test('scans executable code inside a string interpolation', () {
        const source = r'''
final label = 'literal Color(0xFF999999) '
    '${Color(0xFF010203)}';
''';

        expect(
          _desktopInteractionSourceRegressions(
            relativePath: syntheticPath,
            source: source,
          ),
          const <String>[
            '$syntheticPath:2: hard-coded Color literal',
          ],
        );
      });

      test('detects a hard-coded Color constructor across lines', () {
        const source = '''
final untouched = 0;
final color = Color(
  0xFF010203,
);
''';

        expect(
          _desktopInteractionSourceRegressions(
            relativePath: syntheticPath,
            source: source,
          ),
          const <String>[
            '$syntheticPath:2: hard-coded Color literal',
          ],
        );
      });
    });
  });
}

List<String> _gate5WorldMapRegressions() {
  const paths = <String>[
    'lib/src/features/editor/presentation/world_map/world_map_workspace.dart',
    'lib/src/features/editor/presentation/world_map/world_map_toolbelt.dart',
    'lib/src/features/editor/presentation/world_map/adaptive_map_inspector.dart',
    'lib/src/ui/panels/tileset_palette/widgets/palette/map_layer_asset_palette.dart',
    'lib/src/ui/canvas/map_canvas/map_canvas_navigation_controls.dart',
    'lib/src/ui/design_system/pokemap_asset_card.dart',
    'lib/src/ui/design_system/pokemap_button.dart',
    'lib/src/ui/design_system/pokemap_icon_button.dart',
    'lib/src/ui/design_system/pokemap_split_button.dart',
    'lib/src/ui/design_system/pokemap_context_menu.dart',
    'lib/src/ui/design_system/pokemap_desktop_layout.dart',
  ];
  final forbidden = <RegExp, String>{
    RegExp(r'\bColor\s*\(\s*0x'): 'hard-coded Color literal',
    RegExp(r'\bColors\.'): 'Material Colors reference',
    RegExp(r'\bCupertinoColors\b'): 'CupertinoColors reference',
    RegExp(r'\bshowMacosEditorContextMenu\b'):
        'legacy macOS context-menu helper',
    RegExp(
      r'\b(?:MacosButton|PushButton|ElevatedButton|TextButton|OutlinedButton|IconButton)\b',
    ): 'legacy/ad-hoc interactive primitive',
  };
  final regressions = <String>[];
  for (final relativePath in paths) {
    final file = File(p.join(Directory.current.path, relativePath));
    if (!file.existsSync()) {
      regressions.add('$relativePath is missing');
      continue;
    }
    final code = _scanDartSource(file.readAsStringSync()).code;
    for (final entry in forbidden.entries) {
      for (final match in entry.key.allMatches(code)) {
        regressions.add(
          '$relativePath:${_lineNumberAt(code, match.start)}: ${entry.value}',
        );
      }
    }
  }
  return regressions;
}

List<String> _desktopInteractionPrimitiveRegressions() {
  const primitivePaths = <String>[
    'lib/src/ui/design_system/pokemap_desktop_layout.dart',
    'lib/src/ui/design_system/pokemap_context_menu.dart',
    'lib/src/ui/design_system/pokemap_split_button.dart',
  ];
  final regressions = <String>[];

  for (final relativePath in primitivePaths) {
    final file = File(p.join(Directory.current.path, relativePath));
    if (!file.existsSync()) {
      regressions.add('$relativePath is missing');
      continue;
    }
    regressions.addAll(
      _desktopInteractionSourceRegressions(
        relativePath: relativePath,
        source: file.readAsStringSync(),
      ),
    );
  }
  return regressions;
}

List<String> _desktopInteractionSourceRegressions({
  required String relativePath,
  required String source,
}) {
  final forbiddenPatterns = <RegExp, String>{
    RegExp(r'\bColor\s*\(\s*0x'): 'hard-coded Color literal',
    RegExp(r'\bColor\s*\.\s*fromARGB\s*\('):
        'hard-coded Color.fromARGB constructor',
    RegExp(r'\bColor\s*\.\s*fromRGBO\s*\('):
        'hard-coded Color.fromRGBO constructor',
    RegExp(r'\bColors\.'): 'Material Colors reference',
    RegExp(r'\bCupertinoColors\b'): 'CupertinoColors reference',
    RegExp(r'\bPokeMapLegacyColors\b'): 'legacy PokeMap color reference',
    RegExp(r'\bEditorChrome\b'): 'legacy EditorChrome dependency',
    RegExp(r'\bEditorState\b'): 'EditorState dependency',
  };
  final scan = _scanDartSource(source);
  final regressions = <String>[];
  final sourceFindings = <_DartSourceFinding>[];

  for (final entry in forbiddenPatterns.entries) {
    for (final match in entry.key.allMatches(scan.code)) {
      sourceFindings.add(
        _DartSourceFinding(
          offset: match.start,
          line: _lineNumberAt(scan.code, match.start),
          message: entry.value,
        ),
      );
    }
  }
  sourceFindings.sort((left, right) => left.offset.compareTo(right.offset));
  regressions.addAll(
    sourceFindings.map(
      (finding) => '$relativePath:${finding.line}: ${finding.message}',
    ),
  );

  for (final importReference in scan.importReferences) {
    final importUri = importReference.uri.replaceAll(r'\', '/');
    if (importUri.contains('map_core')) {
      regressions.add(
        '$relativePath:${importReference.line}: map_core import',
      );
    }
    final resolvedImport = _resolveDesktopPrimitiveImport(
      relativePath: relativePath,
      importUri: importUri,
    );
    if (_isDisallowedDesktopPrimitiveImport(resolvedImport)) {
      regressions.add(
        '$relativePath:${importReference.line}: '
        'internal import outside design system/theme',
      );
    }
  }
  return regressions;
}

int _lineNumberAt(String source, int offset) {
  var line = 1;
  for (var index = 0; index < offset; index += 1) {
    if (source.codeUnitAt(index) == 10) line += 1;
  }
  return line;
}

_DartSourceScan _scanDartSource(String source) {
  final code = StringBuffer();
  final tokens = <_DartToken>[];
  var index = 0;
  var line = 1;

  void appendSourceThrough(int end) {
    while (index < end) {
      final character = source[index];
      code.write(character);
      if (character == '\n') {
        line += 1;
      }
      index += 1;
    }
  }

  void appendMaskedThrough(int end) {
    while (index < end) {
      final character = source[index];
      code.write(character == '\n' ? '\n' : ' ');
      if (character == '\n') {
        line += 1;
      }
      index += 1;
    }
  }

  void appendStringLiteral(_DartStringLiteral literal) {
    final masked = _maskStringLiteralCode(
      source: source,
      start: index,
      literal: literal,
    );
    code.write(masked);
    for (var offset = index; offset < literal.end; offset += 1) {
      if (source[offset] == '\n') line += 1;
    }
    index = literal.end;
  }

  while (index < source.length) {
    if (_startsWithAt(source, index, '//')) {
      var end = index + 2;
      while (end < source.length && source[end] != '\n') {
        end += 1;
      }
      appendMaskedThrough(end);
      continue;
    }

    if (_startsWithAt(source, index, '/*')) {
      var end = index + 2;
      var depth = 1;
      while (end < source.length && depth > 0) {
        if (_startsWithAt(source, end, '/*')) {
          depth += 1;
          end += 2;
        } else if (_startsWithAt(source, end, '*/')) {
          depth -= 1;
          end += 2;
        } else {
          end += 1;
        }
      }
      appendMaskedThrough(end);
      continue;
    }

    final stringLiteral = _stringLiteralAt(source, index);
    if (stringLiteral != null) {
      tokens.add(
        _DartToken(
          kind: _DartTokenKind.stringLiteral,
          lexeme: stringLiteral.value,
          line: line,
        ),
      );
      appendStringLiteral(stringLiteral);
      continue;
    }

    final character = source[index];
    if (_isDartIdentifierStart(character)) {
      var end = index + 1;
      while (end < source.length && _isDartIdentifierPart(source[end])) {
        end += 1;
      }
      tokens.add(
        _DartToken(
          kind: _DartTokenKind.identifier,
          lexeme: source.substring(index, end),
          line: line,
        ),
      );
      appendSourceThrough(end);
      continue;
    }

    if (!_isDartWhitespace(character)) {
      tokens.add(
        _DartToken(
          kind: _DartTokenKind.symbol,
          lexeme: character,
          line: line,
        ),
      );
    }
    appendSourceThrough(index + 1);
  }

  return _DartSourceScan(
    code: code.toString(),
    importReferences: _extractImportReferences(tokens),
  );
}

String _maskStringLiteralCode({
  required String source,
  required int start,
  required _DartStringLiteral literal,
}) {
  final segment = source.substring(start, literal.end);
  final masked = List<String>.generate(
    segment.length,
    (index) => segment[index] == '\n' ? '\n' : ' ',
  );
  if (literal.isRaw) return masked.join();

  var cursor = literal.valueStart;
  while (cursor + 1 < literal.valueEnd) {
    if (source[cursor] != r'$' ||
        source[cursor + 1] != '{' ||
        _isEscapedAt(source, cursor, literal.valueStart)) {
      cursor += 1;
      continue;
    }

    final expressionStart = cursor + 2;
    final expressionEnd = _findInterpolationEnd(
      source: source,
      start: expressionStart,
      limit: literal.valueEnd,
    );
    if (expressionEnd == null) break;

    final expressionCode =
        _scanDartSource(source.substring(expressionStart, expressionEnd)).code;
    final relativeStart = expressionStart - start;
    for (var index = 0; index < expressionCode.length; index += 1) {
      masked[relativeStart + index] = expressionCode[index];
    }
    cursor = expressionEnd + 1;
  }
  return masked.join();
}

int? _findInterpolationEnd({
  required String source,
  required int start,
  required int limit,
}) {
  var cursor = start;
  var depth = 1;

  while (cursor < limit) {
    if (_startsWithAt(source, cursor, '//')) {
      cursor += 2;
      while (cursor < limit && source[cursor] != '\n') {
        cursor += 1;
      }
      continue;
    }
    if (_startsWithAt(source, cursor, '/*')) {
      cursor += 2;
      var commentDepth = 1;
      while (cursor < limit && commentDepth > 0) {
        if (_startsWithAt(source, cursor, '/*')) {
          commentDepth += 1;
          cursor += 2;
        } else if (_startsWithAt(source, cursor, '*/')) {
          commentDepth -= 1;
          cursor += 2;
        } else {
          cursor += 1;
        }
      }
      continue;
    }

    final nestedString = _stringLiteralAt(source, cursor);
    if (nestedString != null && nestedString.end <= limit) {
      cursor = nestedString.end;
      continue;
    }

    if (source[cursor] == '{') {
      depth += 1;
    } else if (source[cursor] == '}') {
      depth -= 1;
      if (depth == 0) return cursor;
    }
    cursor += 1;
  }
  return null;
}

bool _isEscapedAt(String source, int index, int lowerBound) {
  var backslashCount = 0;
  for (var cursor = index - 1;
      cursor >= lowerBound && source[cursor] == r'\';
      cursor -= 1) {
    backslashCount += 1;
  }
  return backslashCount.isOdd;
}

List<_DartImportReference> _extractImportReferences(
  List<_DartToken> tokens,
) {
  final importReferences = <_DartImportReference>[];

  for (var index = 0; index < tokens.length; index += 1) {
    if (!_isIdentifierToken(tokens[index], 'import')) {
      continue;
    }

    var cursor = index + 1;
    while (cursor < tokens.length &&
        !_isSymbolToken(tokens[cursor], ';') &&
        tokens[cursor].kind != _DartTokenKind.stringLiteral) {
      cursor += 1;
    }
    if (cursor >= tokens.length ||
        tokens[cursor].kind != _DartTokenKind.stringLiteral) {
      continue;
    }

    importReferences.add(
      _DartImportReference(
        uri: tokens[cursor].lexeme,
        line: tokens[cursor].line,
      ),
    );
    cursor += 1;

    while (cursor < tokens.length && !_isSymbolToken(tokens[cursor], ';')) {
      if (!_isIdentifierToken(tokens[cursor], 'if')) {
        cursor += 1;
        continue;
      }

      cursor += 1;
      if (cursor < tokens.length && _isSymbolToken(tokens[cursor], '(')) {
        var depth = 0;
        do {
          if (_isSymbolToken(tokens[cursor], '(')) {
            depth += 1;
          } else if (_isSymbolToken(tokens[cursor], ')')) {
            depth -= 1;
          }
          cursor += 1;
        } while (cursor < tokens.length && depth > 0);
      }

      if (cursor < tokens.length &&
          tokens[cursor].kind == _DartTokenKind.stringLiteral) {
        importReferences.add(
          _DartImportReference(
            uri: tokens[cursor].lexeme,
            line: tokens[cursor].line,
          ),
        );
        cursor += 1;
      }
    }
    index = cursor;
  }

  return importReferences;
}

_DartStringLiteral? _stringLiteralAt(String source, int index) {
  var quoteIndex = index;
  var isRaw = false;
  if ((source[index] == 'r' || source[index] == 'R') &&
      index + 1 < source.length &&
      _isQuote(source[index + 1])) {
    isRaw = true;
    quoteIndex += 1;
  } else if (!_isQuote(source[index])) {
    return null;
  }

  final quote = source[quoteIndex];
  final isTriple = quoteIndex + 2 < source.length &&
      source[quoteIndex + 1] == quote &&
      source[quoteIndex + 2] == quote;
  final delimiterLength = isTriple ? 3 : 1;
  final valueStart = quoteIndex + delimiterLength;
  var cursor = valueStart;

  while (cursor < source.length) {
    if (!isRaw &&
        cursor + 1 < source.length &&
        source[cursor] == r'$' &&
        source[cursor + 1] == '{') {
      final interpolationEnd = _findInterpolationEnd(
        source: source,
        start: cursor + 2,
        limit: source.length,
      );
      if (interpolationEnd != null) {
        cursor = interpolationEnd + 1;
        continue;
      }
    }

    if (!isRaw && source[cursor] == '\\') {
      cursor += cursor + 1 < source.length ? 2 : 1;
      continue;
    }

    if (isTriple) {
      if (cursor + 2 < source.length &&
          source[cursor] == quote &&
          source[cursor + 1] == quote &&
          source[cursor + 2] == quote) {
        return _DartStringLiteral(
          value: source.substring(valueStart, cursor),
          valueStart: valueStart,
          valueEnd: cursor,
          end: cursor + delimiterLength,
          isRaw: isRaw,
        );
      }
    } else if (source[cursor] == quote) {
      return _DartStringLiteral(
        value: source.substring(valueStart, cursor),
        valueStart: valueStart,
        valueEnd: cursor,
        end: cursor + delimiterLength,
        isRaw: isRaw,
      );
    }
    cursor += 1;
  }

  return _DartStringLiteral(
    value: source.substring(valueStart),
    valueStart: valueStart,
    valueEnd: source.length,
    end: source.length,
    isRaw: isRaw,
  );
}

bool _startsWithAt(String source, int index, String pattern) {
  return index + pattern.length <= source.length &&
      source.startsWith(pattern, index);
}

bool _isQuote(String character) {
  return character == "'" || character == '"';
}

bool _isDartIdentifierStart(String character) {
  final codeUnit = character.codeUnitAt(0);
  return character == r'$' ||
      character == '_' ||
      codeUnit >= 65 && codeUnit <= 90 ||
      codeUnit >= 97 && codeUnit <= 122;
}

bool _isDartIdentifierPart(String character) {
  final codeUnit = character.codeUnitAt(0);
  return _isDartIdentifierStart(character) || codeUnit >= 48 && codeUnit <= 57;
}

bool _isDartWhitespace(String character) {
  return character == ' ' ||
      character == '\t' ||
      character == '\n' ||
      character == '\r' ||
      character == '\f';
}

bool _isIdentifierToken(_DartToken token, String lexeme) {
  return token.kind == _DartTokenKind.identifier && token.lexeme == lexeme;
}

bool _isSymbolToken(_DartToken token, String lexeme) {
  return token.kind == _DartTokenKind.symbol && token.lexeme == lexeme;
}

bool _isDisallowedDesktopPrimitiveImport(String resolvedImport) {
  if (!resolvedImport.startsWith('lib/src/')) return false;
  return !resolvedImport.startsWith('lib/src/theme/') &&
      !resolvedImport.startsWith('lib/src/ui/design_system/');
}

String _resolveDesktopPrimitiveImport({
  required String relativePath,
  required String importUri,
}) {
  const packagePrefix = 'package:map_editor/';
  if (importUri.startsWith(packagePrefix)) {
    return p
        .join('lib', importUri.substring(packagePrefix.length))
        .replaceAll(r'\', '/');
  }
  if (importUri.startsWith('package:') || importUri.startsWith('dart:')) {
    return importUri;
  }
  return p
      .normalize(p.join(p.dirname(relativePath), importUri))
      .replaceAll(r'\', '/');
}

List<String> _directColorReferenceRegressions() {
  final offendersByPath = <String, List<_Offender>>{};

  for (final sourceFile in _sourceFiles()) {
    final relativePath = sourceFile.relativePath;
    if (_isDesignTokenSource(relativePath)) {
      continue;
    }

    final lines = sourceFile.file.readAsLinesSync();
    for (var index = 0; index < lines.length; index += 1) {
      if (!_directColorReferencePattern.hasMatch(lines[index])) {
        continue;
      }
      offendersByPath.putIfAbsent(relativePath, () => <_Offender>[]).add(
            _Offender(
              path: relativePath,
              line: index + 1,
              snippet: lines[index].trim(),
            ),
          );
    }
  }

  final regressions = <String>[];
  for (final entry in offendersByPath.entries) {
    final allowed = _legacyDirectColorReferenceBaseline[entry.key] ?? 0;
    final extraCount = entry.value.length - allowed;
    if (extraCount <= 0) {
      continue;
    }
    regressions.add(
      '${entry.key}: ${entry.value.length} direct color refs '
      '(baseline $allowed, +$extraCount)',
    );
    regressions.addAll(
      entry.value.skip(allowed).map((offender) => '  ${offender.describe()}'),
    );
  }

  return regressions;
}

List<String> _legacyChromeImportRegressions() {
  final regressions = <String>[];

  for (final sourceFile in _sourceFiles()) {
    final relativePath = sourceFile.relativePath;
    final source = sourceFile.file.readAsStringSync();
    if (!_legacyChromeImportPattern.hasMatch(source)) {
      continue;
    }
    if (_legacyChromeImportBaseline.contains(relativePath)) {
      continue;
    }
    regressions.add(
      '$relativePath imports legacy cupertino_editor_widgets.dart',
    );
  }

  return regressions;
}

List<String> _narrativeStudioPaletteRegressions() {
  final regressions = <String>[];
  var legacyImportCount = 0;
  final cupertinoColorOffenders = <_Offender>[];

  for (final sourceFile in _sourceFiles()) {
    final relativePath = sourceFile.relativePath;
    if (!relativePath.startsWith('lib/src/ui/canvas/narrative_')) {
      continue;
    }

    final source = sourceFile.file.readAsStringSync();
    if (_legacyChromeImportPattern.hasMatch(source)) {
      legacyImportCount += 1;
    }

    final lines = source.split('\n');
    for (var index = 0; index < lines.length; index += 1) {
      final line = lines[index];
      if (_narrativeHardColorPattern.hasMatch(line)) {
        regressions.add(
          'Narrative hard color: ${_Offender(
            path: relativePath,
            line: index + 1,
            snippet: line.trim(),
          ).describe()}',
        );
      }
      if (_cupertinoColorPattern.hasMatch(line)) {
        cupertinoColorOffenders.add(
          _Offender(
            path: relativePath,
            line: index + 1,
            snippet: line.trim(),
          ),
        );
      }
    }
  }

  if (legacyImportCount > _narrativeLegacyImportBaseline) {
    regressions.add(
      'Narrative legacy imports: $legacyImportCount '
      '(baseline $_narrativeLegacyImportBaseline)',
    );
  }

  if (cupertinoColorOffenders.length > _narrativeCupertinoColorBaseline) {
    regressions.add(
      'Narrative CupertinoColors refs: ${cupertinoColorOffenders.length} '
      '(baseline $_narrativeCupertinoColorBaseline)',
    );
    regressions.addAll(
      cupertinoColorOffenders
          .skip(_narrativeCupertinoColorBaseline)
          .map((offender) => '  ${offender.describe()}'),
    );
  }

  return regressions;
}

List<_SourceFile> _sourceFiles() {
  final packageRoot = Directory.current;
  final sourceRoots = <Directory>[
    Directory(p.join(packageRoot.path, 'lib', 'src', 'ui')),
    Directory(p.join(packageRoot.path, 'lib', 'src', 'features')),
  ];
  final files = <_SourceFile>[];

  for (final root in sourceRoots.where((root) => root.existsSync())) {
    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      files.add(
        _SourceFile(
          file: entity,
          relativePath: p.relative(entity.path, from: packageRoot.path),
        ),
      );
    }
  }

  files.sort((left, right) => left.relativePath.compareTo(right.relativePath));
  return files;
}

bool _isDesignTokenSource(String relativePath) {
  return relativePath.startsWith('lib/src/theme/') ||
      relativePath.startsWith('lib/src/ui/design_system/');
}

final _directColorReferencePattern = RegExp(
  r'\bColor\(0x[0-9A-Fa-f]+\)|\bColors\.|\bCupertinoColors\.|\bMacosColors\.',
);

final _legacyChromeImportPattern = RegExp(
  r"cupertino_editor_widgets\.dart",
);

final _narrativeHardColorPattern = RegExp(
  r'\bColor\(0x[0-9A-Fa-f]+\)|\bColors\.|\bMacosColors\.',
);

final _cupertinoColorPattern = RegExp(r'\bCupertinoColors\.');

const _narrativeLegacyImportBaseline = 0;
const _narrativeCupertinoColorBaseline = 0;

const _legacyDirectColorReferenceBaseline = <String, int>{
  'lib/src/features/environment_studio/environment_studio_panel.dart': 9,
  'lib/src/features/environment_studio/environment_studio_workspace.dart': 2,
  'lib/src/features/environment_studio/widgets/environment_element_thumbnail.dart':
      1,
  'lib/src/features/environment_studio/widgets/environment_generation_params_draft_editor.dart':
      1,
  'lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart':
      1,
  'lib/src/features/environment_studio/widgets/environment_palette_item_view.dart':
      1,
  'lib/src/features/environment_studio/widgets/environment_preset_creation_wizard.dart':
      18,
  'lib/src/features/environment_studio/widgets/environment_preset_detail.dart':
      6,
  'lib/src/features/environment_studio/widgets/environment_preset_diagnostics_view.dart':
      3,
  'lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart':
      5,
  'lib/src/features/environment_studio/widgets/environment_preset_draft_validation_view.dart':
      1,
  'lib/src/features/environment_studio/widgets/environment_preset_list.dart': 4,
  'lib/src/features/path_studio/path_studio_panel.dart': 6,
  'lib/src/features/path_studio/path_studio_saved_preset_detail.dart': 1,
  'lib/src/features/path_studio/path_studio_theme.dart': 19,
  'lib/src/features/path_studio/path_studio_tileset_image_picker.dart': 1,
  'lib/src/features/surface_painter/surface_layer_static_preview.dart': 1,
  'lib/src/ui/canvas/cutscene_studio/cutscene_studio_workbench.dart': 16,
  'lib/src/ui/canvas/cutscene_studio/cutscene_studio_workspace_support.dart':
      10,
  'lib/src/ui/canvas/cutscene_studio_workspace.dart': 2,
  'lib/src/ui/canvas/dialogue_studio/widgets/canvas/dialogue_canvas_cards.dart':
      4,
  'lib/src/ui/canvas/dialogue_studio/widgets/library/dialogue_library_tree.dart':
      4,
  'lib/src/ui/canvas/global_story_studio/global_story_studio_panels.dart': 5,
  'lib/src/ui/canvas/map_canvas.dart': 2,
  'lib/src/ui/canvas/pokedex_workspace/pokedex_common_widgets.dart': 1,
  'lib/src/ui/canvas/pokedex_workspace/pokedex_detail_panel.dart': 1,
  'lib/src/ui/canvas/pokedex_workspace/pokedex_empty_state.dart': 3,
  'lib/src/ui/canvas/pokedex_workspace/pokedex_external_batch_field.dart': 2,
  'lib/src/ui/canvas/pokedex_workspace/pokedex_external_search_field.dart': 3,
  'lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart': 3,
  'lib/src/ui/canvas/pokedex_workspace/pokedex_list_panel.dart': 2,
  'lib/src/ui/canvas/pokedex_workspace/pokedex_list_row.dart': 1,
  'lib/src/ui/canvas/pokemon_catalogs_workspace/items_catalog_workspace.dart':
      1,
  'lib/src/ui/canvas/pokemon_catalogs_workspace/moves_catalog_workspace.dart':
      1,
  'lib/src/ui/canvas/step_studio/step_studio_workspace_support.dart': 1,
  'lib/src/ui/canvas/step_studio_workspace.dart': 2,
  'lib/src/ui/canvas/tileset_editor_canvas.dart': 1,
  'lib/src/ui/editor_shell_page.dart': 7,
  'lib/src/ui/panels/encounter_tables_panel.dart': 4,
  'lib/src/ui/panels/encounter_tables_panel_entry_widgets.dart': 4,
  'lib/src/ui/panels/encounter_tables_panel_table_widgets.dart': 9,
  'lib/src/ui/panels/entity_properties/entity_properties_dialogue_bindings.dart':
      2,
  'lib/src/ui/panels/entity_properties/entity_properties_npc_runtime.dart': 2,
  'lib/src/ui/panels/entity_properties_panel.dart': 29,
  'lib/src/ui/panels/environment_layer_inspector_panel.dart': 5,
  'lib/src/ui/panels/event_properties_panel.dart': 12,
  'lib/src/ui/panels/gameplay_zone_properties_panel.dart': 11,
  'lib/src/ui/panels/layers_panel.dart': 1,
  'lib/src/ui/panels/map_connections_panel.dart': 13,
  'lib/src/ui/panels/map_properties_panel.dart': 3,
  'lib/src/ui/panels/narrative_inspector_panel.dart': 1,
  'lib/src/ui/panels/project_explorer/dialogs/import_tileset_dialog.dart': 1,
  'lib/src/ui/panels/project_explorer/dnd/tileset_library_drag_drop.dart': 2,
  'lib/src/ui/panels/project_explorer/widgets/sidebar_header_action.dart': 3,
  'lib/src/ui/panels/project_explorer/widgets/tree/tileset_tree_nodes.dart': 1,
  'lib/src/ui/panels/terrain_editor/widgets/terrain_mapping_workspace.dart': 4,
  'lib/src/ui/panels/terrain_editor_panel.dart': 27,
  'lib/src/ui/panels/terrain_map_panel.dart': 22,
  'lib/src/ui/panels/tile_layer_environment_inspector_section.dart': 5,
  'lib/src/ui/panels/tileset_palette/dialogs/element_frame_picker_dialog.dart':
      7,
  'lib/src/ui/panels/tileset_palette/widgets/animation/placed_element_animation_widgets.dart':
      11,
  'lib/src/ui/panels/tileset_palette/widgets/collision/element_collision_editor.dart':
      31,
  'lib/src/ui/panels/tileset_palette/widgets/collision/element_collision_profile_painter.dart':
      7,
  'lib/src/ui/panels/tileset_palette/widgets/library/tileset_palette_library_widgets.dart':
      2,
  'lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart':
      13,
  'lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_instances_section.dart':
      14,
  'lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart':
      17,
  'lib/src/ui/panels/tileset_palette_panel.dart': 21,
  'lib/src/ui/panels/trainer_library_panel.dart': 1,
  'lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart': 11,
  'lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart': 2,
  'lib/src/ui/panels/trainer_library_panel_workspace_widgets.dart': 3,
  'lib/src/ui/panels/trigger_properties_panel.dart': 11,
  'lib/src/ui/panels/warp_properties_panel.dart': 18,
  'lib/src/ui/shared/editor_paint_palette.dart': 25,
  'lib/src/ui/shared/editor_visual_tokens.dart': 8,
  'lib/src/ui/shared/inspector_embedded_widgets.dart': 7,
  'lib/src/ui/shared/pokemap_macos_ui_shim.dart': 10,
  'lib/src/ui/shared/top_toolbar/dialogs/top_toolbar_dialogs.dart': 2,
  'lib/src/ui/shared/top_toolbar/widgets/toolbar_brand.dart': 1,
  'lib/src/ui/widgets/element_collision_triple_mask_editor.dart': 27,
};

const _legacyChromeImportBaseline = <String>{
  'lib/src/features/environment_studio/environment_studio_panel.dart',
  'lib/src/features/environment_studio/widgets/environment_element_thumbnail.dart',
  'lib/src/features/environment_studio/widgets/environment_generation_params_draft_editor.dart',
  'lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart',
  'lib/src/features/environment_studio/widgets/environment_palette_item_view.dart',
  'lib/src/features/environment_studio/widgets/environment_preset_creation_wizard.dart',
  'lib/src/features/environment_studio/widgets/environment_preset_detail.dart',
  'lib/src/features/environment_studio/widgets/environment_preset_diagnostics_view.dart',
  'lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart',
  'lib/src/features/environment_studio/widgets/environment_preset_draft_validation_view.dart',
  'lib/src/features/environment_studio/widgets/environment_preset_list.dart',
  'lib/src/features/environment_studio/widgets/environment_preset_save_feedback.dart',
  'lib/src/features/surface_painter/surface_palette_panel.dart',
  'lib/src/ui/canvas/cutscene_studio/cutscene_studio_workbench.dart',
  'lib/src/ui/canvas/cutscene_studio_workspace.dart',
  'lib/src/ui/canvas/dialogue_studio_workspace.dart',
  'lib/src/ui/canvas/global_story_studio/global_story_studio_panels.dart',
  'lib/src/ui/canvas/global_story_studio/global_story_studio_shell.dart',
  'lib/src/ui/canvas/global_story_studio_workspace.dart',
  'lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart',
  'lib/src/ui/canvas/pokemon_catalogs_workspace/items_catalog_workspace.dart',
  'lib/src/ui/canvas/pokemon_catalogs_workspace/moves_catalog_workspace.dart',
  'lib/src/ui/canvas/step_studio/step_flow_canvas.dart',
  'lib/src/ui/canvas/step_studio/step_flow_palette.dart',
  'lib/src/ui/canvas/step_studio_workspace.dart',
  'lib/src/ui/canvas/tileset_editor_canvas.dart',
  'lib/src/ui/editor_shell_page.dart',
  'lib/src/ui/panels/element_collision_editor_sheet.dart',
  'lib/src/ui/panels/encounter_tables_panel.dart',
  'lib/src/ui/panels/entity_properties_panel.dart',
  'lib/src/ui/panels/environment_layer_inspector_panel.dart',
  'lib/src/ui/panels/event_properties_panel.dart',
  'lib/src/ui/panels/gameplay_zone_properties_panel.dart',
  'lib/src/ui/panels/layers_panel.dart',
  'lib/src/ui/panels/map_connections_panel.dart',
  'lib/src/ui/panels/map_inspector_panel.dart',
  'lib/src/ui/panels/map_properties_panel.dart',
  'lib/src/ui/panels/narrative_inspector_panel.dart',
  'lib/src/ui/panels/narrative_library_panel.dart',
  'lib/src/ui/panels/project_explorer/dialogs/import_tileset_dialog.dart',
  'lib/src/ui/panels/project_explorer/dialogs/tileset_library_dialogs.dart',
  'lib/src/ui/panels/project_explorer/dialogs/world_group_dialogs.dart',
  'lib/src/ui/panels/project_explorer/dnd/tileset_library_drag_drop.dart',
  'lib/src/ui/panels/project_explorer/widgets/sidebar_header_action.dart',
  'lib/src/ui/panels/project_explorer/widgets/tree/tileset_tree_nodes.dart',
  'lib/src/ui/panels/project_explorer/widgets/tree/world_tree_nodes.dart',
  'lib/src/ui/panels/project_explorer_panel.dart',
  'lib/src/ui/panels/terrain_editor_panel.dart',
  'lib/src/ui/panels/terrain_map_panel.dart',
  'lib/src/ui/panels/tile_layer_environment_inspector_section.dart',
  'lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart',
  'lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart',
  'lib/src/ui/panels/tileset_palette_panel.dart',
  'lib/src/ui/panels/trainer_library_panel.dart',
  'lib/src/ui/panels/trigger_properties_panel.dart',
  'lib/src/ui/panels/warp_properties_panel.dart',
  'lib/src/ui/shared/inspector_embedded_widgets.dart',
  'lib/src/ui/shared/inspector_section_card.dart',
  'lib/src/ui/shared/top_toolbar/dialogs/top_toolbar_dialogs.dart',
  'lib/src/ui/widgets/element_collision_triple_mask_editor.dart',
};

class _SourceFile {
  const _SourceFile({
    required this.file,
    required this.relativePath,
  });

  final File file;
  final String relativePath;
}

class _Offender {
  const _Offender({
    required this.path,
    required this.line,
    required this.snippet,
  });

  final String path;
  final int line;
  final String snippet;

  String describe() => '$path:$line: $snippet';
}

enum _DartTokenKind {
  identifier,
  stringLiteral,
  symbol,
}

class _DartToken {
  const _DartToken({
    required this.kind,
    required this.lexeme,
    required this.line,
  });

  final _DartTokenKind kind;
  final String lexeme;
  final int line;
}

class _DartStringLiteral {
  const _DartStringLiteral({
    required this.value,
    required this.valueStart,
    required this.valueEnd,
    required this.end,
    required this.isRaw,
  });

  final String value;
  final int valueStart;
  final int valueEnd;
  final int end;
  final bool isRaw;
}

class _DartSourceFinding {
  const _DartSourceFinding({
    required this.offset,
    required this.line,
    required this.message,
  });

  final int offset;
  final int line;
  final String message;
}

class _DartImportReference {
  const _DartImportReference({
    required this.uri,
    required this.line,
  });

  final String uri;
  final int line;
}

class _DartSourceScan {
  const _DartSourceScan({
    required this.code,
    required this.importReferences,
  });

  final String code;
  final List<_DartImportReference> importReferences;
}
