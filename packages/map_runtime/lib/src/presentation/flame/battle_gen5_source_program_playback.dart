import 'package:map_core/map_core.dart' show BattleMoveAnimationRecipe;

enum BattleGen5SourceTaskCategory {
  camera,
  particles,
  mcss,
  palette,
  stageFieldPalette,
  background,
  backgroundWave,
  window,
  otherVisual,
  audio,
}

enum BattleGen5SourceDispatchResult { completed, particleLoadPending }

enum BattleGen5SourcePlaybackStatus {
  ready,
  running,
  finished,
  cancelled,
  failed,
}

final class BattleGen5SourceInstruction {
  BattleGen5SourceInstruction._({
    required this.op,
    required this.args,
    required this.source,
  });

  final String op;
  final Map<String, dynamic> args;
  final Map<String, dynamic> source;
}

final class BattleGen5SourceProgramPlayback {
  BattleGen5SourceProgramPlayback({
    required Map<String, dynamic> program,
    required String variant,
    required String? Function(BattleGen5SourceInstruction) admit,
    required this.dispatch,
    required this.isBusy,
    required this.isParticleLoading,
    this.onTerminated,
  }) {
    final boundedProgram = _SourceProgramFreeze().freezeMap(program);
    if (boundedProgram['kind'] != 'gen5SourceProgram' ||
        boundedProgram['timebaseHz'] != 60 ||
        boundedProgram['conversion'] != 'supported' ||
        boundedProgram['variant'] != variant ||
        variant.isEmpty) {
      throw const FormatException('Invalid or unsupported source program');
    }
    final variants = boundedProgram['variants'];
    final labels = boundedProgram['labels'];
    final entry = boundedProgram['entryIndex'];
    final rawInstructions = boundedProgram['instructions'];
    if (variants is! List ||
        variants.isEmpty ||
        variants.length > 32 ||
        labels is! List ||
        labels.isEmpty ||
        labels.length > 1024 ||
        entry is! int ||
        rawInstructions is! List ||
        rawInstructions.isEmpty ||
        rawInstructions.length > 1024 ||
        entry < 0 ||
        entry >= rawInstructions.length) {
      throw const FormatException('Invalid source program variant or entry');
    }
    final variantNames = <String>{};
    for (final name in variants) {
      if (name is! String || name.isEmpty || !variantNames.add(name)) {
        throw const FormatException('Invalid or duplicate source variant');
      }
    }
    if (!variantNames.contains(variant)) {
      throw const FormatException('Unknown source variant');
    }
    final labelNames = <String>{};
    final variantEntries = <String, int>{};
    final variantIndices = <int>{};
    var lastLabelIndex = -1;
    var variantEnd = rawInstructions.length;
    for (final label in labels) {
      if (label is! Map ||
          label['name'] is! String ||
          (label['name'] as String).isEmpty ||
          label['instructionIndex'] is! int) {
        throw const FormatException('Invalid source label');
      }
      final name = label['name'] as String;
      final index = label['instructionIndex'] as int;
      if (!labelNames.add(name) ||
          index < lastLabelIndex ||
          index < 0 ||
          index > rawInstructions.length) {
        throw const FormatException('Duplicate or unordered source label');
      }
      lastLabelIndex = index;
      if (variantNames.contains(name)) {
        if (index >= rawInstructions.length || !variantIndices.add(index)) {
          throw const FormatException('Invalid or duplicate variant entry');
        }
        variantEntries[name] = index;
        if (index > entry && index < variantEnd) variantEnd = index;
      }
    }
    if (variantEntries.length != variantNames.length ||
        variantEntries[variant] != entry) {
      throw const FormatException('Invalid source variant entry');
    }
    final parsed = <BattleGen5SourceInstruction>[];
    for (var index = 0; index < rawInstructions.length; index++) {
      final value = rawInstructions[index];
      if (value is! Map ||
          value['op'] is! String ||
          value['args'] is! Map ||
          value['source'] is! Map) {
        throw FormatException('Invalid source instruction $index');
      }
      parsed.add(
        BattleGen5SourceInstruction._(
          op: value['op'] as String,
          args: value['args'] as Map<String, dynamic>,
          source: value['source'] as Map<String, dynamic>,
        ),
      );
    }
    var endExclusive = -1;
    var sourceYield = true;
    var synchronousInstructions = 0;
    for (var index = entry; index < variantEnd; index++) {
      final instruction = parsed[index];
      if (!_operations.contains(instruction.op)) {
        throw FormatException(
          'Unsupported source operation ${instruction.op} at $index',
        );
      }
      synchronousInstructions++;
      if (synchronousInstructions > maxInstructionsPerTick) {
        throw FormatException(
          'Source call exceeds $maxInstructionsPerTick instructions at $index',
        );
      }
      var endsCall = sourceYield;
      final args = instruction.args;
      switch (instruction.op) {
        case 'waitTasks':
          if (!_waitKinds.contains(args['what'])) {
            throw FormatException('Unsupported wait category at $index');
          }
          sourceYield = true;
          endsCall = true;
        case 'waitFrames':
          final frames = args['frames'];
          if (frames is! int || frames < 0 || frames > 60000) {
            throw FormatException('Invalid wait frames at $index');
          }
          sourceYield = true;
          endsCall = true;
        case 'setYield':
          if (args['value'] is! bool) {
            throw FormatException('Invalid yield value at $index');
          }
          sourceYield = args['value'] as bool;
          endsCall = sourceYield;
        case 'loadParticle':
          final particle = args['particle'];
          if (particle is! int || particle < 0 || particle > 65535) {
            throw FormatException('Invalid particle reference at $index');
          }
          endsCall = true;
        case 'deleteParticle':
          final particle = args['particle'];
          if (particle is! int || particle < 0 || particle > 65535) {
            throw FormatException('Invalid particle reference at $index');
          }
        case 'setAnimationState':
          final mode = args['mode'];
          if (mode is! int || (mode != 0 && mode != 1)) {
            throw FormatException('Unsupported animation mode at $index');
          }
        case 'end':
          if (args.isNotEmpty) {
            throw FormatException('Invalid end arguments at $index');
          }
      }
      if (!_controlOperations.contains(instruction.op)) {
        final reason = admit(instruction);
        if (reason != null) {
          throw FormatException(
            'Unsupported ${instruction.op} at $index: $reason',
          );
        }
      }
      if (endsCall) synchronousInstructions = 0;
      if (instruction.op == 'end') {
        endExclusive = index + 1;
        break;
      }
    }
    if (endExclusive < 0) {
      throw const FormatException('Source variant has no end');
    }
    _instructions = List.unmodifiable(parsed);
    _selectedInstructions = List.unmodifiable(
      parsed.getRange(entry, endExclusive),
    );
    _instructionIndex = entry;
  }

  static const int maxInstructionsPerTick = 256;
  static const _operations = BattleMoveAnimationRecipe.gen5SourceOperations;
  static const _controlOperations = {
    'waitTasks',
    'waitFrames',
    'setYield',
    'end',
  };
  static const _waitKinds = {
    'ALL', 'PARTICLES', 'CAMERA', 'MCSS', 'BG', 'SE', 'SE_PLAYER_1', 'CRY',
    'STAGE_FIELD_FADE'
  };

  final BattleGen5SourceDispatchResult Function(BattleGen5SourceInstruction)
  dispatch;
  final bool Function(BattleGen5SourceTaskCategory) isBusy;
  final bool Function() isParticleLoading;
  final void Function(BattleGen5SourcePlaybackStatus)? onTerminated;
  late final List<BattleGen5SourceInstruction> _instructions;
  late final List<BattleGen5SourceInstruction> _selectedInstructions;
  late int _instructionIndex;
  BattleGen5SourcePlaybackStatus _status = BattleGen5SourcePlaybackStatus.ready;
  String? _diagnostic;
  int _tickCount = 0;
  bool _yield = true;
  bool _inTick = false;
  int? _frameWait;
  String? _taskWait;
  bool _particleLoadWait = false;

  BattleGen5SourcePlaybackStatus get status => _status;
  List<BattleGen5SourceInstruction> get selectedInstructions =>
      _selectedInstructions;
  int get instructionIndex => _instructionIndex;
  int get tickCount => _tickCount;
  String? get diagnostic => _diagnostic;

  void tick() {
    if (_isTerminal) return;
    if (_inTick) throw StateError('Source program tick is not reentrant');
    _inTick = true;
    _status = BattleGen5SourcePlaybackStatus.running;
    try {
      _tickCount++;
      if (_frameWait != null) {
        _frameWait = _frameWait! - 1;
        if (_frameWait! <= 0) _frameWait = null;
        return;
      }
      if (_taskWait != null) {
        if (!_isWaitingFor(_taskWait!)) _taskWait = null;
        return;
      }
      if (_particleLoadWait) {
        if (!isParticleLoading()) _particleLoadWait = false;
        return;
      }
      while (!_isTerminal) {
        final instruction = _instructions[_instructionIndex++];
        switch (instruction.op) {
          case 'waitFrames':
            _frameWait = instruction.args['frames'] as int;
            _yield = true;
            return;
          case 'waitTasks':
            _taskWait = instruction.args['what'] as String;
            _yield = true;
            return;
          case 'setYield':
            _yield = instruction.args['value'] as bool;
            if (_yield) return;
          case 'end':
            _finish(BattleGen5SourcePlaybackStatus.finished);
            return;
          default:
            final result = dispatch(instruction);
            if (_isTerminal) return;
            if (instruction.op == 'loadParticle') {
              _particleLoadWait =
                  result == BattleGen5SourceDispatchResult.particleLoadPending;
              return;
            }
            if (result != BattleGen5SourceDispatchResult.completed) {
              throw StateError(
                'Unexpected particle loading result for ${instruction.op}',
              );
            }
            if (_yield) return;
        }
      }
    } on Object catch (error) {
      if (!_isTerminal) {
        _diagnostic = error.toString();
        _finish(BattleGen5SourcePlaybackStatus.failed);
      } else {
        rethrow;
      }
    } finally {
      _inTick = false;
    }
  }

  bool _isWaitingFor(String kind) => switch (kind) {
    'ALL' =>
      BattleGen5SourceTaskCategory.values
          .where((category) => category != BattleGen5SourceTaskCategory.audio)
          .any(isBusy),
    'PARTICLES' => isBusy(BattleGen5SourceTaskCategory.particles),
    'CAMERA' => isBusy(BattleGen5SourceTaskCategory.camera),
    'MCSS' => isBusy(BattleGen5SourceTaskCategory.mcss),
    'BG' => isBusy(BattleGen5SourceTaskCategory.background),
    'SE' || 'SE_PLAYER_1' || 'CRY' => isBusy(BattleGen5SourceTaskCategory.audio),
    'STAGE_FIELD_FADE' =>
      isBusy(BattleGen5SourceTaskCategory.stageFieldPalette),
    _ => throw StateError('Unknown source wait category'),
  };

  bool get _isTerminal => switch (_status) {
    BattleGen5SourcePlaybackStatus.finished ||
    BattleGen5SourcePlaybackStatus.cancelled ||
    BattleGen5SourcePlaybackStatus.failed => true,
    _ => false,
  };

  void cancel() {
    if (!_isTerminal) _finish(BattleGen5SourcePlaybackStatus.cancelled);
  }

  void _finish(BattleGen5SourcePlaybackStatus next) {
    if (_isTerminal) return;
    _status = next;
    onTerminated?.call(next);
  }
}

final class _SourceProgramFreeze {
  static const _maxDepth = 16;
  static const _maxValues = 65536;
  static const _maxContainerEntries = 4096;
  static const _maxStringUnits = 4096;
  static const _maxTotalStringUnits = 262144;

  final Set<Object> _active = Set.identity();
  int _values = 0;
  int _stringUnits = 0;

  Map<String, dynamic> freezeMap(Map value) =>
      _freeze(value, 0) as Map<String, dynamic>;

  Object? _freeze(Object? value, int depth) {
    if (depth > _maxDepth) {
      throw const FormatException('Source program depth limit exceeded');
    }
    _takeValue();
    if (value is String) {
      _takeString(value);
      return value;
    }
    if (value is Map) {
      if (value.length > _maxContainerEntries ||
          value.length > (_maxValues - _values) ~/ 2) {
        throw const FormatException('Source program map limit exceeded');
      }
      if (!_active.add(value)) {
        throw const FormatException('Cyclic source program');
      }
      try {
        final result = <String, dynamic>{};
        for (final entry in value.entries) {
          if (entry.key is! String) {
            throw const FormatException('Invalid source program key');
          }
          final key = entry.key as String;
          _takeValue();
          _takeString(key);
          result[key] = _freeze(entry.value, depth + 1);
        }
        return Map<String, dynamic>.unmodifiable(result);
      } finally {
        _active.remove(value);
      }
    }
    if (value is List) {
      if (value.length > _maxContainerEntries ||
          value.length > _maxValues - _values) {
        throw const FormatException('Source program list limit exceeded');
      }
      if (!_active.add(value)) {
        throw const FormatException('Cyclic source program');
      }
      try {
        final result = <Object?>[];
        for (final element in value) {
          result.add(_freeze(element, depth + 1));
        }
        return List<Object?>.unmodifiable(result);
      } finally {
        _active.remove(value);
      }
    }
    if (value == null || value is bool || value is int) return value;
    throw const FormatException('Invalid source program value');
  }

  void _takeValue() {
    _values++;
    if (_values > _maxValues) {
      throw const FormatException('Source program value limit exceeded');
    }
  }

  void _takeString(String value) {
    if (value.length > _maxStringUnits ||
        value.length > _maxTotalStringUnits - _stringUnits) {
      throw const FormatException('Source program string limit exceeded');
    }
    _stringUnits += value.length;
  }
}
