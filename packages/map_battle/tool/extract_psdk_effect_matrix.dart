import 'dart:io';

import 'package:map_battle/src/data/generated/psdk_move_registry_manifest.dart';
import 'package:map_battle/src/data/psdk_fight_parity_audit.dart';

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
          hookFamilies: _hookFamiliesFor(parsedClass.sortedHooks),
          rubyPath: relativePath,
          dartTargetPath: _dartTargetPath(parsedClass.name, relativePath),
          status: _statusFor(
            parsedClass.name,
            family: _effectFamily(relativePath),
            rubyPath: relativePath,
          ),
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
      '| Effect | Ruby base | Family | Hooks | Hook families | Ruby path | Dart target | Status | Notes |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- | --- |');
  for (final row in rows) {
    buffer.writeln(
      '| `${_markdownEscape(row.effectName)}` '
      '| `${_markdownEscape(row.rubyBaseClass)}` '
      '| `${row.family}` '
      '| ${_renderHooks(row.hooks)} '
      '| ${_renderHooks(row.hookFamilies)} '
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

List<String> _hookFamiliesFor(List<String> hooks) {
  final families = <String>{};
  for (final hook in hooks) {
    final family = _hookFamilyFor(hook);
    if (family != null) {
      families.add(family);
    }
  }
  return families.toList()..sort();
}

String? _hookFamilyFor(String hook) {
  if (hook == 'on_move_ability_immunity') {
    return 'ability_immunity';
  }
  if (hook == 'on_move_priority_change') {
    return 'action_order';
  }
  if (hook == 'on_move_type_change') {
    return 'move_type_change';
  }
  if (hook == 'on_pre_accuracy_check' || hook == 'on_post_accuracy_check') {
    return 'accuracy';
  }
  if (hook == 'on_two_turn_shortcut') {
    return 'two_turn_shortcut';
  }
  if (hook == 'on_move_disabled_check' ||
      hook == 'on_move_failure' ||
      hook.startsWith('on_move_prevention')) {
    return 'move_prevention';
  }
  if (hook == 'on_damage_prevention') {
    return 'damage_prevention';
  }
  if (hook == 'on_post_damage' || hook == 'on_post_damage_death') {
    return 'post_damage';
  }
  if (hook == 'on_drain_prevention' || hook == 'on_pre_drain') {
    return 'drain';
  }
  if (hook.contains('status')) {
    return 'status_prevention';
  }
  if (hook.contains('stat')) {
    return 'stat_change';
  }
  if (hook.contains('weather')) {
    return 'weather_change';
  }
  if (hook.contains('fterrain')) {
    return 'terrain_change';
  }
  if (hook.contains('item')) {
    return 'item_change';
  }
  if (hook.contains('ability_change')) {
    return 'ability_change';
  }
  if (hook.contains('switch') || hook.contains('flee')) {
    return 'switch';
  }
  if (hook == 'on_end_turn_event') {
    return 'end_turn';
  }
  if (hook == 'on_post_action_event') {
    return 'action_order';
  }
  if (hook == 'on_transform_event') {
    return 'transform';
  }
  if (hook == 'on_single_type_multiplier_overwrite') {
    return 'damage_change';
  }
  if (hook.startsWith('on_delete') ||
      hook == 'on_reset_states' ||
      hook == 'on_clear_message' ||
      hook == 'on_increase_message') {
    return 'lifecycle';
  }
  return null;
}

String _dartTargetPath(String effectName, String rubyPath) {
  final family = _effectFamily(rubyPath);
  final fileName = '${_snakeCase(effectName)}_effect.dart';
  return 'lib/src/domain/effect/$family/$fileName';
}

String _notesFor(String effectName) {
  return switch (effectName) {
    'AquaRing' =>
      'Object-backed AquaRingEffect heals at end turn, honors Big Root through item hooks and transfers through Baton Pass.',
    'ArenaTrap' =>
      'Object-backed ShadowTagEffect.arenaTrap prevents opposing grounded non-Ghost switch attempts through the switch-prevention hook; force-switch move exceptions and messaging remain future work.',
    'Attract' =>
      'Object-backed AttractEffect performs the PSDK 50% user-prevention roll against the attracting battler; gender immunity, Destiny Knot mirroring and delete messages remain future work.',
    'AuroraVeil' =>
      'StaticBasicMoveRegistry.s_reflect installs Aurora Veil only under active hail/snow, supports Light Clay duration, duplicate failure and screen damage reduction.',
    'BatonPass' =>
      'Object-backed BatonPassEffect marks switch transfer; the current handler transfers stat stages and transferable effects, while full party switch action remains future work.',
    'Bind' =>
      'Object-backed BindEffect prevents regular switch attempts, applies residual end-turn damage, honors Magic Guard, Grip Claw and Binding Band, stops when the origin fainted, and is Rapid Spin-cleanable.',
    'CantSwitch' =>
      'Object-backed CantSwitchEffect prevents regular switch attempts, transfers through Baton Pass and clears once the origin fainted; full switch-event cleanup and message parity remain future work.',
    'CenterOfAttention' =>
      'BattleTargetResolver redirects eligible single-target foe moves toward center_of_attention holders and respects prevent_targets_move; Rage Powder-specific Grass/Overcoat/Safety Goggles immunity remains future work.',
    'Confusion' =>
      'Object-backed ConfusionEffect runs the PSDK user-prevention lifecycle: countdown, last-turn cleanup, 50% self-hit roll and typeless 40-power self damage; PSDK move statuses can now apply CONFUSED as a volatile effect, while Own Tempo/Persim-style cures and battle messages remain future work.',
    'CraftyShield' =>
      'Object-backed CraftyShieldEffect blocks opposing status moves against the protected bank while allowing self-targeting and Curse.',
    'Curse' =>
      'Object-backed CurseEffect applies PSDK ghost-curse end-turn damage, honors Magic Guard and transfers through Baton Pass.',
    'Disable' =>
      'Object-backed DisableEffect blocks execution and selection of the disabled move for the PSDK four-turn lifecycle.',
    'Embargo' =>
      'Object-backed EmbargoEffect suppresses held-item effects, keeps the PSDK five-turn lifecycle and transfers through Baton Pass.',
    'Encore' =>
      'Object-backed EncoreEffect blocks execution and selection of moves other than the encored move for the PSDK three-turn lifecycle.',
    'Flinch' =>
      'Object-backed FlinchEffect blocks the target next action through the user-prevention hook and clears at end turn; messaging and Steadfast-style side effects remain future work.',
    'Gravity' =>
      'StaticBasicMoveRegistry field marker installs gravity with duration; grounding resolver and Gravity-sensitive move formulas observe the effect.',
    'HealBlock' =>
      'Object-backed HealBlockEffect blocks execution and selection of local healing battle methods for the PSDK five-turn lifecycle.',
    'Imprison' =>
      'Object-backed ImprisonEffect blocks execution and selection of shared imprisoned move ids while allowing the owner and Struggle.',
    'Ingrain' =>
      'Object-backed IngrainEffect heals at end turn, honors Big Root through item hooks, grounds the user, prevents regular switch-out and transfers through Baton Pass.',
    'LeechSeed' =>
      'Object-backed LeechSeedEffect drains at end turn, checks Grass/Substitute duplicate immunity in the move behavior, skips Magic Guard, punishes the source through Liquid Ooze, honors Big Root and transfers through Baton Pass.',
    'LightScreen' =>
      'StaticBasicMoveRegistry.s_reflect installs Light Screen, supports Light Clay duration, duplicate failure and special damage reduction with Infiltrator bypass.',
    'LuckyChant' =>
      'StaticBasicMoveRegistry.s_lucky_chant installs the bank-scoped Lucky Chant marker and critical-rate resolution observes it.',
    'MagnetPull' =>
      'Object-backed ShadowTagEffect.magnetPull prevents opposing Steel non-Ghost switch attempts through the switch-prevention hook; force-switch move exceptions and messaging remain future work.',
    'MagicRoom' =>
      'StaticBasicMoveRegistry field marker installs Magic Room and held-item effect resolution suppresses item hooks while it is active.',
    'MatBlock' =>
      'Object-backed MatBlockEffect blocks protectable damaging moves against the protected bank and lets status moves through.',
    'Mist' =>
      'StaticBasicMoveRegistry.s_mist installs the bank-scoped marker and stat-change prevention blocks opposing stat drops for the whole bank.',
    'MudSport' =>
      'StaticBasicMoveRegistry.s_thing_sport installs Mud Sport and damage calculation halves Electric move power while active.',
    'Nightmare' =>
      'Object-backed NightmareEffect applies PSDK one-quarter end-turn damage to sleeping or Comatose targets, honors Magic Guard and clears when the target is no longer asleep.',
    'PerishSong' =>
      'Object-backed PerishSongEffect counts down at end turn, transfers through Baton Pass and faints the holder when the counter resolves.',
    'Powder' =>
      'Object-backed PowderEffect prevents Fire move execution for its holder and applies one-quarter max HP damage.',
    'Protect' =>
      'Object-backed ProtectEffect ported for common target prevention; variants, success-rate decay and Unseen Fist bypass remain future work.',
    'QuickGuard' =>
      'Object-backed QuickGuardEffect blocks positive-priority protectable moves against the protected bank.',
    'Reflect' =>
      'StaticBasicMoveRegistry.s_reflect installs Reflect, supports Light Clay duration, duplicate failure and physical damage reduction with Infiltrator bypass.',
    'Safeguard' =>
      'StaticBasicMoveRegistry.s_safe_guard installs the bank-scoped marker; major and volatile status application honor it with Infiltrator bypass.',
    'SaltCure' =>
      'Object-backed SaltCureEffect applies end-turn residual damage with the Water/Steel divisor branch and honors Magic Guard.',
    'ShadowTag' =>
      'Object-backed ShadowTagEffect prevents opposing non-Ghost non-Shadow Tag switch attempts through the switch-prevention hook; force-switch move exceptions and messaging remain future work.',
    'SmackDown' =>
      'Object-backed SmackDownEffect forces grounded checks and removes Flying immunity for local Ground damage; flying-effect cleanup remains future work.',
    'Spikes' =>
      'StaticBasicMoveRegistry.s_spike installs and empowers Spikes layers; BattleSwitchHandler applies grounded entry damage.',
    'StealthRock' =>
      'StaticBasicMoveRegistry.s_stealth_rock installs Stealth Rock once; BattleSwitchHandler applies type-aware entry damage.',
    'StickyWeb' =>
      'StaticBasicMoveRegistry.s_sticky_web installs Sticky Web once; BattleSwitchHandler applies grounded Speed drops and preserves origin.',
    'SyrupBomb' =>
      'Object-backed SyrupBombEffect applies timed end-turn Speed drops and clears when its counter resolves.',
    'Tailwind' =>
      'StaticBasicMoveRegistry.s_tailwind installs the bank-scoped marker, rejects duplicate use and action ordering doubles that bank speed.',
    'Taunt' =>
      'Object-backed TauntEffect blocks execution and selection of status moves for the PSDK three-turn lifecycle.',
    'TarShot' =>
      'Object-backed TarShotEffect records the target fire-weakness marker; type-multiplier overwrite remains future work.',
    'ThroatChop' =>
      'Object-backed ThroatChopEffect blocks execution and selection of sound-flagged moves for the PSDK three-turn lifecycle.',
    'Torment' =>
      'Object-backed TormentEffect blocks execution and selection of the last successful non-Struggle move.',
    'ToxicSpikes' =>
      'StaticBasicMoveRegistry.s_toxic_spike installs and empowers Toxic Spikes layers; BattleSwitchHandler poisons grounded entrants or clears on Poison-type entry.',
    'TrickRoom' =>
      'Object-backed TrickRoomEffect toggles the field marker, ticks duration and action ordering observes reversed speed.',
    'WaterSport' =>
      'StaticBasicMoveRegistry.s_thing_sport installs Water Sport and damage calculation halves Fire move power while active.',
    'Wish' =>
      'Object-backed WishEffect stores the queued heal amount, ticks end-turn duration and heals the current position holder when it resolves.',
    'WideGuard' =>
      'Object-backed WideGuardEffect blocks protectable spread moves against the protected bank.',
    'WonderRoom' =>
      'StaticBasicMoveRegistry field marker installs Wonder Room with duration; Defense/Special Defense stat swapping remains future work.',
    _ => '',
  };
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

_PsdkPortStatus _statusFor(
  String effectName, {
  required String family,
  required String rubyPath,
}) {
  return switch (psdkEffectPortStatusFor(
    effectName: effectName,
    family: family,
    rubyPath: rubyPath,
  )) {
    PsdkPortStatus.ported => _PsdkPortStatus.ported,
    PsdkPortStatus.partial => _PsdkPortStatus.partial,
    PsdkPortStatus.missing => _PsdkPortStatus.missing,
  };
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
    required this.hookFamilies,
    required this.rubyPath,
    required this.dartTargetPath,
    required this.status,
    required this.notes,
  });

  final String effectName;
  final String rubyBaseClass;
  final String family;
  final List<String> hooks;
  final List<String> hookFamilies;
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
