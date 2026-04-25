import 'dart:io';

final _classLinePattern = RegExp(
  r'^\s*class\s+([A-Za-z_][A-Za-z0-9_:]*)(?:\s*<\s*([A-Za-z0-9_:]+))?',
);
final _hookLinePattern = RegExp(r'^\s*def\s+(on_[A-Za-z0-9_!?=]+)');
final _blockStartPattern = RegExp(
  r'^\s*(module|def|if|unless|case|begin|for|while|until)\b|'
  r'\bdo\s*(?:\|[^|]*\|)?\s*$',
);

Future<void> main(List<String> args) async {
  if (args.length != 2) {
    stderr.writeln(
      'Usage: dart run tool/extract_psdk_effect_matrix.dart '
      '<psdk-5-battle-dir> <output-md>',
    );
    exitCode = 64;
    return;
  }

  final root = Directory(args[0]);
  if (!root.existsSync()) {
    stderr.writeln('PSDK battle folder not found: ${root.path}');
    exitCode = 66;
    return;
  }

  final rows = await _extractRows(root);
  await _writeTextFile(args[1], _renderEffectMatrix(root, rows));
}

Future<List<_EffectMatrixRow>> _extractRows(Directory root) async {
  final effectRoot = _childDir(root, '06 Effects') ?? root;
  final rows = <_EffectMatrixRow>[];
  for (final file in _rubyFiles(effectRoot)) {
    final content = await file.readAsString();
    final relativePath = _relativePath(root, file);
    final parsedClasses = _parseRubyClasses(content);
    for (final parsedClass in parsedClasses) {
      if (_isGenericContainerClass(parsedClass.name, parsedClasses)) {
        continue;
      }
      rows.add(
        _EffectMatrixRow(
          effectName: parsedClass.name,
          rubyBaseClass: parsedClass.baseClass,
          family: _effectFamily(relativePath),
          hooks: parsedClass.sortedHooks,
          rubyPath: relativePath,
          dartTargetPath: _dartTargetPath(parsedClass.name, relativePath),
          status: _statusFor(parsedClass.name),
          notes: _notesFor(parsedClass.name),
        ),
      );
    }
  }
  rows.sort((left, right) {
    final byName = left.effectName.compareTo(right.effectName);
    if (byName != 0) {
      return byName;
    }
    return left.rubyPath.compareTo(right.rubyPath);
  });
  return rows;
}

bool _isGenericContainerClass(
  String effectName,
  List<_ParsedRubyClass> parsedClasses,
) {
  // PSDK groups concrete nested effects under container classes such as
  // `Battle::Effects::Ability` and `Battle::Effects::Item`. If a file contains
  // nested concrete classes, reporting the container as its own effect creates a
  // noisy and misleading migration matrix.
  const genericContainers = <String>{
    'Ability',
    'FieldTerrain',
    'Item',
    'Status',
    'Weather',
  };
  return genericContainers.contains(effectName) && parsedClasses.length > 1;
}

List<_ParsedRubyClass> _parseRubyClasses(String content) {
  final classes = <_ParsedRubyClass>[];
  final blockStack = <_RubyBlock>[];
  for (final line in content.split('\n')) {
    final classMatch = _classLinePattern.firstMatch(line);
    if (classMatch != null) {
      final index = classes.length;
      classes.add(
        _ParsedRubyClass(
          name: classMatch.group(1)!,
          baseClass: classMatch.group(2) ?? '',
        ),
      );
      blockStack.add(_RubyBlock.classBlock(index));
      continue;
    }

    final hookMatch = _hookLinePattern.firstMatch(line);
    if (hookMatch != null) {
      final classIndex = _currentClassIndex(blockStack);
      if (classIndex != null) {
        classes[classIndex].hooks.add(hookMatch.group(1)!);
      }
      blockStack.add(const _RubyBlock.other());
      continue;
    }

    if (_startsRubyBlock(line)) {
      blockStack.add(const _RubyBlock.other());
      continue;
    }

    if (RegExp(r'^\s*end\b').hasMatch(line) && blockStack.isNotEmpty) {
      blockStack.removeLast();
    }
  }
  return classes;
}

bool _startsRubyBlock(String line) {
  if (RegExp(r'^\s*(return|next|break)\s+(if|unless)\b').hasMatch(line)) {
    return false;
  }
  return _blockStartPattern.hasMatch(line);
}

int? _currentClassIndex(List<_RubyBlock> blockStack) {
  for (var index = blockStack.length - 1; index >= 0; index--) {
    final block = blockStack[index];
    if (block.classIndex != null) {
      return block.classIndex;
    }
  }
  return null;
}

String _renderEffectMatrix(Directory root, List<_EffectMatrixRow> rows) {
  final counts = {
    for (final status in _PsdkPortStatus.values)
      status: rows.where((row) => row.status == status).length,
  };
  final buffer = StringBuffer()
    ..writeln('# PSDK Effect Porting Matrix')
    ..writeln()
    ..writeln('Source: `${_markdownEscape(root.path)}`')
    ..writeln()
    ..writeln('Total effect classes: ${rows.length}')
    ..writeln()
    ..writeln('| Status | Count |')
    ..writeln('| --- | ---: |');
  for (final status in _PsdkPortStatus.values) {
    buffer.writeln('| `${status.name}` | ${counts[status]} |');
  }
  buffer
    ..writeln()
    ..writeln(
      '| Effect | Ruby base | Family | Hooks | Ruby path | Dart target | Status | Notes |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- |');
  for (final row in rows) {
    buffer.writeln(
      '| `${_markdownEscape(row.effectName)}` '
      '| `${_markdownEscape(row.rubyBaseClass)}` '
      '| `${row.family}` '
      '| ${_renderHooks(row.hooks)} '
      '| `${_markdownEscape(row.rubyPath)}` '
      '| `${_markdownEscape(row.dartTargetPath)}` '
      '| `${row.status.name}` '
      '| ${row.notes.isEmpty ? '`-`' : _markdownEscape(row.notes)} |',
    );
  }
  return buffer.toString();
}

String _renderHooks(List<String> hooks) {
  if (hooks.isEmpty) {
    return '`-`';
  }
  return hooks.map((hook) => '`$hook`').join(', ');
}

String _dartTargetPath(String effectName, String rubyPath) {
  final family = _effectFamily(rubyPath);
  final fileName = '${_snakeCase(effectName)}_effect.dart';
  return 'lib/src/domain/effect/$family/$fileName';
}

String _notesFor(String effectName) {
  if (effectName == 'Protect') {
    return 'Minimal inline Protect bridge in static_basic_move_registry.dart + PsdkBattleEffectIds.protect; full effect object not ported yet.';
  }
  return '';
}

String _effectFamily(String rubyPath) {
  if (rubyPath.contains('04 Ability Effects')) {
    return 'ability';
  }
  if (rubyPath.contains('05 Item Effects')) {
    return 'item';
  }
  if (rubyPath.contains('03 Status Effects')) {
    return 'status';
  }
  if (rubyPath.contains('06 Weather Effects')) {
    return 'field';
  }
  if (rubyPath.contains('07 Field Terrain Effects')) {
    return 'field';
  }
  if (rubyPath.contains('02 Move Effects')) {
    return 'move';
  }
  return 'mechanics';
}

_PsdkPortStatus _statusFor(String effectName) {
  // Lot 14 has only a minimal Protect id/effect bridge, not the full generic
  // PSDK EffectBase hook object. Mark it partial and keep everything else
  // missing until the dedicated effect-system lots port them explicitly.
  return effectName == 'Protect'
      ? _PsdkPortStatus.partial
      : _PsdkPortStatus.missing;
}

String _snakeCase(String value) {
  return value
      .replaceAll('::', '_')
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (match) => '${match.group(1)}_${match.group(2)}',
      )
      .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '')
      .toLowerCase();
}

List<File> _rubyFiles(Directory root) {
  return root
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.rb'))
      .toList()
    ..sort((left, right) => left.path.compareTo(right.path));
}

Directory? _childDir(Directory root, String childName) {
  final child = Directory('${root.path}/$childName');
  return child.existsSync() ? child : null;
}

String _relativePath(Directory root, File file) {
  final rootPath = _withTrailingSeparator(root.absolute.path);
  final filePath = file.absolute.path;
  if (filePath.startsWith(rootPath)) {
    return filePath.substring(rootPath.length);
  }
  return filePath;
}

String _withTrailingSeparator(String path) {
  return path.endsWith(Platform.pathSeparator)
      ? path
      : '$path${Platform.pathSeparator}';
}

Future<void> _writeTextFile(String path, String content) async {
  final file = File(path);
  file.parent.createSync(recursive: true);
  await file.writeAsString(content);
}

String _markdownEscape(String value) => value.replaceAll('|', r'\|');

final class _EffectMatrixRow {
  const _EffectMatrixRow({
    required this.effectName,
    required this.rubyBaseClass,
    required this.family,
    required this.hooks,
    required this.rubyPath,
    required this.dartTargetPath,
    required this.status,
    required this.notes,
  });

  final String effectName;
  final String rubyBaseClass;
  final String family;
  final List<String> hooks;
  final String rubyPath;
  final String dartTargetPath;
  final _PsdkPortStatus status;
  final String notes;
}

enum _PsdkPortStatus {
  ported,
  partial,
  missing,
}

final class _ParsedRubyClass {
  _ParsedRubyClass({
    required this.name,
    required this.baseClass,
  });

  final String name;
  final String baseClass;
  final Set<String> hooks = <String>{};

  List<String> get sortedHooks => hooks.toList()..sort();
}

final class _RubyBlock {
  const _RubyBlock.other() : classIndex = null;

  const _RubyBlock.classBlock(this.classIndex);

  final int? classIndex;
}
