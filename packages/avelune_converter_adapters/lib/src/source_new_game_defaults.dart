import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';

import 'native_project_writer.dart';

final class SourceNewGameDefaults {
  SourceNewGameDefaults._({
    required this.playerName,
    required this.money,
    required this.avatarHeaderId,
    required this.outfit,
    required this.facing,
    required this.pcItems,
    required this.evidence,
  });

  final String playerName;
  final int money;
  final int avatarHeaderId;
  final int outfit;
  final EntityFacing facing;
  final List<String> pcItems;
  final Map<String, Object?> evidence;
}

final class SourceNewGameDefaultsReader {
  const SourceNewGameDefaultsReader();

  Future<SourceNewGameDefaults?> read({
    required NormalizedSourceProject source,
    required SourceFilePort files,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) async {
    final cancel = cancellation ?? ScanCancellation();
    cancel.check();
    limits.validate();
    if (source.snapshot.state != SourceScanState.complete) {
      return null;
    }
    final inputs = _DefaultsInputs(source, files, limits, cancel);
    final scriptBytes = await inputs.read('Data/Scripts.rxdata');
    if (scriptBytes == null) {
      return null;
    }
    final sections = <({String name, String text})>[];
    final engineCatalog = <String>[];
    try {
      final document = inputs.decode(scriptBytes, 'Data/Scripts.rxdata');
      final root = document.node(document.rootId);
      if (root.kind != MarshalKind.array || root.elements.length > 4096) {
        return null;
      }
      for (final id in root.elements) {
        cancel.check();
        final row = document.node(id);
        if (row.kind != MarshalKind.array || row.elements.length != 3) {
          return null;
        }
        final name = document.node(row.elements[1]);
        final body = document.node(row.elements[2]);
        if (name.kind != MarshalKind.string ||
            body.kind != MarshalKind.string) {
          return null;
        }
        final text = inputs.inflate(body.bytes!, 'Data/Scripts.rxdata');
        final sectionName = name.text().text;
        if (sectionName == null) {
          return null;
        }
        sections.add((name: sectionName, text: utf8.decode(text)));
        engineCatalog
            .add(jsonEncode([sectionName, sha256.convert(text).toString()]));
      }
    } on BinaryDecodeError {
      return null;
    } on FormatException {
      return null;
    }
    if (!_sameCatalog(engineCatalog, _knownEngineLibraries)) {
      return null;
    }
    final witnesses = <Map<String, Object?>>[];
    for (final witness in _defaultWitnesses) {
      final matching = <Map<String, Object?>>[];
      for (final section in sections.where((s) => s.name == witness.$1)) {
        final lines = const LineSplitter().convert(section.text);
        var start = 0;
        var end = lines.length - 1;
        if (witness.$2 != null) {
          final starts = [
            for (var i = 0; i < lines.length; i++)
              if (lines[i] == witness.$2) i
          ];
          if (starts.length <= witness.$3) {
            continue;
          }
          start = starts[witness.$3];
          final indent = witness.$2!.length - witness.$2!.trimLeft().length;
          final closing = '${' ' * indent}end';
          end = lines.indexOf(closing, start + 1);
          if (end < 0) {
            continue;
          }
        }
        final hash = sha256
            .convert(utf8.encode(lines.sublist(start, end + 1).join('\n')))
            .toString();
        if (hash != witness.$4) {
          continue;
        }
        matching.add({
          'library': witness.$1,
          'declaration': witness.$2,
          'occurrence': witness.$3,
          'line': start + 1,
          'endLine': end + 1,
          'sha256': hash
        });
      }
      if (matching.length != 1) {
        return null;
      }
      witnesses.add(matching.single);
    }
    final pluginBytes = await inputs.read('Data/PluginScripts.rxdata');
    if (pluginBytes == null) {
      return null;
    }
    final pluginCatalog = <String>[];
    final pluginNames = <String>[];
    final pluginBindings = <(String, String)>[];
    try {
      final document = inputs.decode(pluginBytes, 'Data/PluginScripts.rxdata');
      final root = document.node(document.rootId);
      if (root.kind != MarshalKind.array || root.elements.length > 256) {
        return null;
      }
      for (final id in root.elements) {
        cancel.check();
        final plugin = document.node(id);
        if (plugin.kind != MarshalKind.array || plugin.elements.length != 3) {
          return null;
        }
        final name = document.node(plugin.elements[0]).text().text;
        if (name == null || pluginNames.contains(name)) {
          return null;
        }
        pluginNames.add(name);
        final scripts = document.node(plugin.elements[2]);
        if (scripts.kind != MarshalKind.array) {
          return null;
        }
        for (final scriptId in scripts.elements) {
          cancel.check();
          final row = document.node(scriptId);
          if (row.kind != MarshalKind.array || row.elements.length != 2) {
            return null;
          }
          final path = document.node(row.elements[0]).text().text;
          final compressed = document.node(row.elements[1]);
          if (path == null || compressed.kind != MarshalKind.string) {
            return null;
          }
          final bytes =
              inputs.inflate(compressed.bytes!, 'Data/PluginScripts.rxdata');
          final hash = sha256.convert(bytes).toString();
          pluginCatalog.add(jsonEncode([name, path, hash]));
          pluginBindings.add((path, hash));
        }
      }
    } on BinaryDecodeError {
      return null;
    } on FormatException {
      return null;
    } on StateError {
      return null;
    }
    if (!_sameCatalog(pluginNames, _knownPluginNames) ||
        !_sameCatalog(pluginCatalog, _knownPluginLibraries)) {
      return null;
    }
    final pluginSources = source.snapshot.entries.where((entry) {
      final path = sourcePathCollisionKey(entry.relativePath);
      return entry.kind == SourceNodeKind.file &&
          path.startsWith('plugins/') &&
          path.endsWith('.rb') &&
          !path.startsWith('plugins/disabled plugins/');
    }).toList();
    if (pluginSources.isNotEmpty) {
      final matched = <ConverterId>{};
      for (final binding in pluginBindings) {
        cancel.check();
        final suffix = '/${sourcePathCollisionKey(binding.$1)}';
        final matches = pluginSources
            .where((entry) =>
                sourcePathCollisionKey(entry.relativePath).endsWith(suffix) &&
                entry.sha256?.value == binding.$2)
            .toList();
        if (matches.length != 1 || !matched.add(matches.single.fileId)) {
          return null;
        }
        if (await inputs.read(matches.single.relativePath) == null) {
          return null;
        }
      }
      if (matched.length != pluginSources.length) {
        return null;
      }
    }
    final values = <String, Object?>{};
    for (final path in [
      'Data/metadata.dat',
      'Data/player_metadata.dat',
      'Data/trainer_types.dat'
    ]) {
      final bytes = await inputs.read(path);
      if (bytes == null) {
        return null;
      }
      try {
        final document = inputs.decode(bytes, path);
        values[path] = _MetadataGraph(document, limits, cancel, path)
            .read(document.rootId);
      } on BinaryDecodeError {
        throw _metadataFailure();
      }
    }
    final metadata =
        _record(values['Data/metadata.dat'], 0, 'GameData::Metadata');
    final players = values['Data/player_metadata.dat'];
    if (players is! Map || players.containsKey(0)) {
      throw _metadataFailure();
    }
    final player = _record(players, 1, 'GameData::PlayerMetadata');
    final trainerType = player['@trainer_type'];
    if (trainerType is! String) {
      throw _metadataFailure();
    }
    final trainerTypes = values['Data/trainer_types.dat'];
    final trainer = _record(trainerTypes, trainerType, 'GameData::TrainerType');
    if ((trainerTypes as Map).keys.first != trainerType) {
      throw _metadataFailure();
    }
    final money = metadata['@start_money'];
    final items = metadata['@start_item_storage'];
    if (money is! int ||
        money < 0 ||
        items is! List ||
        items.any((item) =>
            item is! String || !RegExp(r'^[A-Z][A-Z0-9_]*$').hasMatch(item))) {
      throw _metadataFailure();
    }
    final pbsBytes = await inputs.read('PBS/metadata.txt');
    if (pbsBytes == null) {
      return null;
    }
    final pbs = _readPbs(pbsBytes, limits, cancel);
    final globalPbs = pbs[0];
    final playerPbs = pbs[1];
    if (globalPbs == null ||
        playerPbs == null ||
        int.tryParse(globalPbs['StartMoney'] ?? '') != money ||
        playerPbs['TrainerType'] != trainerType) {
      throw _metadataFailure();
    }
    final pbsItems = (globalPbs['StartItemStorage'] ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (jsonEncode(pbsItems) != jsonEncode(items)) {
      throw _metadataFailure();
    }
    for (final field in const {
      'WalkCharset': '@walk_charset',
      'RunCharset': '@run_charset',
      'CycleCharset': '@cycle_charset',
      'SurfCharset': '@surf_charset',
      'DiveCharset': '@dive_charset',
      'FishCharset': '@fish_charset',
      'SurfFishCharset': '@surf_fish_charset',
      'SpinCharset': '@spin_charset',
    }.entries) {
      if (playerPbs[field.key] != player[field.value]) {
        throw _metadataFailure();
      }
    }
    if (player['@walk_charset'] is! String ||
        (player['@walk_charset'] as String).isEmpty) {
      throw _metadataFailure();
    }
    cancel.check();
    final evidence = <String, Object?>{
      'kind': 'sourceNewGameDefaults',
      'version': 1,
      'sourceSnapshotHash': source.snapshot.canonicalHash.value,
      'engineLibraryProfile': 'closedEssentialsLibraryDefaultsV1',
      'engineLibraryCount': engineCatalog.length,
      'pluginLibraryCount': pluginCatalog.length,
      'pluginSourceFileCount': pluginSources.length,
      'pluginSourcePolicy': pluginSources.isEmpty
          ? 'compiledCacheOnly'
          : 'exactCompiledAndSourceLibraries',
      'engineLibraryInventoryHash': sha256
          .convert(utf8.encode(jsonEncode(engineCatalog..sort())))
          .toString(),
      'pluginLibraryInventoryHash': sha256
          .convert(utf8.encode(jsonEncode(pluginCatalog..sort())))
          .toString(),
      'libraryWitnesses': witnesses,
      'files': inputs.witnesses,
      'playerName': 'Unnamed',
      'money': money,
      'avatarHeaderId': 1,
      'sourceCharacterId': 0,
      'avatarSelection': 'knownPlayerMetadataGetFallback',
      'trainerType': trainerType,
      'sourceGender': trainer['@gender'],
      'outfit': 0,
      'facing': 'south',
      'party': 'empty',
      'bag': 'empty',
      'pokemonStorage': 'empty',
      'sourceSwitchesDefault': false,
      'sourceVariablesDefault': 0,
      'sourceSelfSwitchesDefault': false,
      'recoveryPointInferred': false,
      'sourceStartupHooksQualified': true,
      'freshColdStartOnly': true,
      'sourceScriptsExecuted': 0,
      'pcItems': items,
      'pcItemsMaterialization': 'lazyPcItemStorageConstructor',
      'pcItemsImportedIntoBag': false,
      'diagnostics': [
        if (items.isNotEmpty)
          {
            'code': 'source.new_game.pc_items_not_bag',
            'message':
                'Source item storage defaults belong to lazy PC storage and do not grant bag items.',
            'sourceSymbols': items,
          }
      ],
    };
    canonicalJsonOf(evidence, limits: limits.jsonLimits);
    return SourceNewGameDefaults._(
      playerName: 'Unnamed',
      money: money,
      avatarHeaderId: 1,
      outfit: 0,
      facing: EntityFacing.south,
      pcItems: List<String>.unmodifiable(items),
      evidence: _freeze(evidence) as Map<String, Object?>,
    );
  }
}

bool _sameCatalog(List<String> actual, List<String> known) {
  if (actual.length != known.length) {
    return false;
  }
  final left = actual.toList()..sort();
  final right = known.toList()..sort();
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) {
      return false;
    }
  }
  return true;
}

ContractError _metadataFailure() => ContractError(
    'source.new_game.metadata_mismatch',
    r'$',
    'Compiled and declared source new-game metadata must agree.');

Map _record(Object? root, Object id, String type) {
  if (root is! Map || root[id] is! Map) {
    throw _metadataFailure();
  }
  final record = root[id] as Map;
  if (record['__class__'] != type || record['@id'] != id) {
    throw _metadataFailure();
  }
  return record;
}

final class _MetadataGraph {
  _MetadataGraph(this.document, this.limits, this.cancellation, this.path);
  final MarshalDocument document;
  final NativeWriteLimits limits;
  final ScanCancellation cancellation;
  final String path;
  final _active = <int>{};
  final _memo = <int, Object?>{};
  var _visits = 0;

  Object? read(int id) {
    cancellation.check();
    if (++_visits > limits.jsonLimits.maxNodes) {
      throw ContractError('source.new_game.quota', path,
          'Compiled metadata exceeds its bounded traversal quota.');
    }
    if (_memo.containsKey(id)) return _memo[id];
    if (_active.length >= limits.jsonLimits.maxDepth || !_active.add(id)) {
      throw _metadataFailure();
    }
    try {
      return _memo[id] = _value(id);
    } finally {
      _active.remove(id);
    }
  }

  Object? _value(int id) {
    final node = document.node(id);
    switch (node.kind) {
      case MarshalKind.nil:
        return null;
      case MarshalKind.boolean:
        return node.booleanValue;
      case MarshalKind.integer:
        if (node.integerValue!.bitLength > 53) {
          throw _metadataFailure();
        }
        return node.integerValue!.toInt();
      case MarshalKind.symbol:
        return node.name;
      case MarshalKind.string:
        final text = node.text().text;
        if (text == null) {
          throw _metadataFailure();
        }
        return text;
      case MarshalKind.array:
        return [for (final child in node.elements) read(child)];
      case MarshalKind.hash:
      case MarshalKind.object:
        final result = <Object?, Object?>{
          if (node.kind == MarshalKind.object) '__class__': node.className,
        };
        for (final pair in node.kind == MarshalKind.hash
            ? node.pairs
            : node.instanceVariables) {
          final key = read(pair.key);
          if (result.containsKey(key)) {
            throw _metadataFailure();
          }
          result[key] = read(pair.value);
        }
        return result;
      default:
        throw _metadataFailure();
    }
  }
}

Map<int, Map<String, String>> _readPbs(
    List<int> bytes, NativeWriteLimits limits, ScanCancellation cancellation) {
  late String text;
  try {
    text = utf8.decode(bytes);
  } on FormatException {
    throw _metadataFailure();
  }
  if (text.startsWith('\uFEFF')) text = text.substring(1);
  final result = <int, Map<String, String>>{};
  Map<String, String>? current;
  for (final raw in const LineSplitter().convert(text)) {
    cancellation.check();
    if (raw.length > limits.jsonLimits.maxStringCodeUnits) {
      throw ContractError('source.new_game.quota', 'PBS/metadata.txt',
          'Source metadata line exceeds its quota.');
    }
    final line = raw.split('#').first.trim();
    if (line.isEmpty) {
      continue;
    }
    final header = RegExp(r'^\[([0-9]{1,5})\]$').firstMatch(line);
    if (header != null) {
      final id = int.parse(header.group(1)!);
      if (result.containsKey(id)) {
        throw _metadataFailure();
      }
      current = result[id] = {};
      continue;
    }
    final separator = line.indexOf('=');
    if (current == null || separator < 1) {
      throw _metadataFailure();
    }
    final key = line.substring(0, separator).trim();
    if (current.containsKey(key)) {
      throw _metadataFailure();
    }
    final value = line.substring(separator + 1).trim();
    if (value.contains('"') || value.contains("'")) {
      throw _metadataFailure();
    }
    current[key] = value;
  }
  return result;
}

Object? _freeze(Object? value) => switch (value) {
      Map value => Map<String, Object?>.unmodifiable(
          value.map((key, value) => MapEntry(key as String, _freeze(value)))),
      List value => List<Object?>.unmodifiable(value.map(_freeze)),
      _ => value,
    };

final class _DefaultsInputs {
  _DefaultsInputs(this.source, this.files, this.limits, this.cancellation) {
    for (final entry in source.snapshot.entries) {
      final key = sourcePathCollisionKey(entry.relativePath);
      (_entriesByPath[key] ??= []).add(entry);
    }
  }
  final NormalizedSourceProject source;
  final SourceFilePort files;
  final NativeWriteLimits limits;
  final ScanCancellation cancellation;
  final _entriesByPath = <String, List<SourceFileEntry>>{};
  final witnesses = <Map<String, Object?>>[];
  var _bytes = 0;

  void charge(int count, String path) {
    if (count > limits.maxArtifactBytes ||
        count < 0 ||
        _bytes + count > limits.maxTotalArtifactBytes) {
      throw ContractError('source.new_game.quota', path,
          'Source new-game defaults exceed the bounded read quota.');
    }
    _bytes += count;
  }

  Future<List<int>?> read(String path) async {
    cancellation.check();
    final entries = _entriesByPath[sourcePathCollisionKey(path)] ?? const [];
    if (entries.length != 1) {
      return null;
    }
    final entry = entries.single;
    if (entry.kind != SourceNodeKind.file ||
        entry.sha256 == null ||
        source.sourceFiles[entry.fileId]?.isAdapted == true) {
      return null;
    }
    charge(entry.byteLength, path);
    final bytes = await files.read(entry.fileId);
    cancellation.check();
    if (bytes.length != entry.byteLength ||
        bytes.any((value) => value < 0 || value > 255) ||
        sha256.convert(bytes).toString() != entry.sha256!.value) {
      throw ContractError('source.snapshot_changed', path,
          'Source bytes changed after the recorded snapshot.');
    }
    witnesses.add(entry.toJson());
    return List<int>.unmodifiable(bytes);
  }

  MarshalDocument decode(List<int> bytes, String path) =>
      const MarshalDecoder().decode(bytes,
          sourcePath: path,
          limits: MarshalDecodeLimits(
            maxInputBytes: limits.maxArtifactBytes,
            maxStringBytes: limits.maxArtifactBytes,
            maxTotalStringBytes:
                limits.maxTotalArtifactBytes.clamp(1, 268435456),
          ));

  List<int> inflate(List<int> bytes, String path) {
    cancellation.check();
    final result = const BoundedZlibDecoder().decode(bytes,
        sourcePath: path,
        limits: ZlibDecodeLimits(
            maxInputBytes: limits.maxArtifactBytes,
            maxOutputBytes: limits.maxArtifactBytes));
    charge(result.length, path);
    return result;
  }
}

const _defaultWitnesses = <(String, String?, int, String)>[
  (
    "Game_SaveValues",
    null,
    0,
    "cf4c8ba5e4ec3a6008164bb037f07b46af93c3a9f24c30e19e6c2353678665af"
  ),
  (
    "StartGame",
    "  def self.start_new",
    0,
    "abf6310bb3347fe9d275d0ac080f94b7f5a94daae2ad7ae9654650a39a73f795"
  ),
  (
    "SaveData_Value",
    "  def self.load_new_game_values",
    0,
    "4dbe65b601ee8dcd0b4d2f399d4e04e6a740108b9418af31b7b7102c9a8cc8ac"
  ),
  (
    "Trainer",
    "  def initialize(name, trainer_type)",
    0,
    "ac3b516bdb095e94ed53a6a7d1a30a96560e967f3d234e0352183d7c559ba1cd"
  ),
  (
    "Player",
    "  def initialize(name, trainer_type)",
    0,
    "1254725833a0c231886cb8ea5d511c4c145c79ccc17d925e521b06deae45fd1f"
  ),
  (
    "Player",
    "  def trainer_type",
    0,
    "f4af1f4c080662f6f94d9773525eba0c22fda250a4a6076b69a662645e1f8bcc"
  ),
  (
    "PlayerMetadata",
    "    def self.get(player_id = 1)",
    0,
    "1b84e248c233cf65eb0d4d5fbfb201f9bfcf020bb1619e7f2e2a2b5b38507cd3"
  ),
  (
    "Game_Character",
    "  def initialize(map = nil)",
    0,
    "a3e6867017e9a2d2757c54878228972e70a872ba487fdcc37b2bb13d88ca9ea0"
  ),
  (
    "Game_Character",
    "  def moveto(x, y)",
    0,
    "466c9464cee29b6cceb8b8c26caa27cc9d5c46aaa44396d22810fedc41618260"
  ),
  (
    "Game_Player",
    "  def initialize(*arg)",
    0,
    "0ca42cb638dc7c81c0d8bd402fa0546742ef27a0cf470d94efd36f80e708910d"
  ),
  (
    "Game_Switches",
    null,
    0,
    "c1817bd2a382135418b35196f9ad04b5f9092027951fc18a9c2fbd763bf16303"
  ),
  (
    "Game_Variables",
    null,
    0,
    "246f359519104e20ac6b824934bfb2286b7d14db1d6d134ae7b2c71fe43377f3"
  ),
  (
    "Game_SelfSwitches",
    null,
    0,
    "bb4a493c6ce5ee4b896b5bfa4d44a898f78b539ccb9b1e851001f1d6d859cd58"
  ),
  (
    "PokemonBag",
    "  def initialize",
    0,
    "750c070a0bcab8e5c5e8848bdd7988596fdcd7f451e9cd9b698cea2188d4000b"
  ),
  (
    "PokemonBag",
    "  def initialize",
    1,
    "4ba4e172507c06b6a9d2f54ecc39b7cb1f5dbece8ee0eea6c00a27415a346032"
  ),
  (
    "PokemonStorage",
    "  def initialize(maxBoxes = Settings::NUM_STORAGE_BOXES, maxPokemon = PokemonBox::BOX_SIZE)",
    0,
    "c92ff1ddab9a9ba46fbc59efe9f0a79da2be57c79524f02a558a82739c5f3bd5"
  ),
  (
    "PokemonStorage",
    "  def initialize(name, maxPokemon = BOX_SIZE)",
    0,
    "cb0fcce5270b1f94bb7a3b078a5ca8fea93be315902769450108fe2aa7a1da65"
  ),
  (
    "Overworld_Metadata",
    "  def initialize",
    0,
    "3c152b0ce6c47fb9753e33a6cfea62a7fb0a70eee19a290002ffd858eef61c36"
  ),
  (
    "UI_PurifyChamber",
    "  def initialize(name, trainer_type)",
    0,
    "a81f49be1fcded101f54a53ba2bc912db4cf6dd934280a720bd29b1ec4581a7e"
  ),
];

const _knownEngineLibraries = <String>[
  "[\"Settings\",\"cc412c0b86e5ebbc121a91ca5efc2d7d6c7b398469cb0c7cd5be1b770531b06f\"]",
  "[\"BattleSettings\",\"a0315f665b0f0f9130aebaa30ec636f9ca555cc6782c671b7f914afccbce6237\"]",
  "[\"==================\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Technical ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"MKXP_Compatibility\",\"8bcce9a07f925140b1e705071d3c5ef9cc8f4aad3c8e0b6203c7120b65df377b\"]",
  "[\"RubyUtilities\",\"6af7da7222d433497604468aa740688c7356e3ba9f158cc641757c1b5ff2582c\"]",
  "[\"Intl_Messages\",\"a2c8e932246964516edd6cb4dd59367e168efb015680def3e38ff9b2b5ee1279\"]",
  "[\"Input\",\"992d39f78c7b0023d9dda603f5ae8d117fe2f91ca5326f9b0f63b5abadc4126f\"]",
  "[\"PluginManager\",\"d91af25b3a44b94fddff49e68f23e743a75bdc46e053ae7c72713f5b07335f77\"]",
  "[\"RPG_Sprite\",\"353bdd0648e9920f33ab44bf5ade2c13a27494f1d629768b5bcd8ad65849f83f\"]",
  "[\"\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Debugging ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"PBDebug\",\"8afaa73ea6544ad65eb0efb2d333775666ee808743d3317ebc3894424962b453\"]",
  "[\"DebugConsole\",\"a2e4cc070dd04c50d2bc643cf14f9f35913403f3f063cfea536c9702edd590f1\"]",
  "[\"Errors\",\"9e136ca9db0c40304e7bf239ee9269bc0eb886d85b3486460fb8b9e96408d1e7\"]",
  "[\"Validation\",\"ea7d5ed8dc8699c8d6a2b8528419918eaa4a0c71d160bc75e3bc7b3363cccad5\"]",
  "[\"Deprecation\",\"3773a02c25389bf4d07c74a2bfc87411654bfc55b244433f6662f4fb734a274b\"]",
  "[\"\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Files ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"FileTests\",\"ec5be8b9ee266b6d6b0f5dc5b8ffd2d51436a6e43902f57aefa6e77546cfe429\"]",
  "[\"FileMixins\",\"a6107477c39e3978c1f2188ddb4675cdeeb3b4f45033a951aefd84ee8f614d0b\"]",
  "[\"HTTP_Utilities\",\"14b96e16abd5bd0374c402b884f8af36bade96521bab1ded17cca5429121323e\"]",
  "[\"==================\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Save data ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"SaveData\",\"124d9c4633a7179cb75d79127f6517215941fdd7925a4b7c1ea254a1b837bc87\"]",
  "[\"SaveData_Value\",\"a3dd3dcf3d5f1c0e3d5110c06cc2dddb404d765a515ae27b27701c1b0c60bfcb\"]",
  "[\"SaveData_Conversion\",\"b57b9d7b8448358b9591dadb42a24ceff14040519db2d31960bac330c72b2688\"]",
  "[\"Game_SaveValues\",\"98028e2e69998ab0553e926bf6cda97a50844af18ef8c2f36738169c95aee754\"]",
  "[\"Game_SaveConversions\",\"2dc4c6f0e8aedcd16749dc6cfecd4ee2a432891cfb2f2c48c654c8596aaf73ab\"]",
  "[\"==================\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Game processing ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"StartGame\",\"679e0caac93de6eb7cd28d99cfcc47eb048b8db2317e7b640e3fe99d541e2d41\"]",
  "[\"Scene_Map\",\"2ddbb7198dd0445142cf76c44b32ae8f983c11ec1230c6179d46808854356fe1\"]",
  "[\"Interpreter\",\"b2f4c542a1542a5908d1208b87eae05d8b6f6ec0d26df1835871595842ed0355\"]",
  "[\"Interpreter_Commands\",\"ec927a007bee1889223dbc8b3de115f062a5308ab4410f87dab965eef3032561\"]",
  "[\"Event_Handlers\",\"3e19dd42257be1cb290e671b239263ece72b9813651b5d47e60a5d89280efe49\"]",
  "[\"Event_HandlerCollections\",\"4c083136b50c8c970314764049e0dbafc2f6682b6749145184547ae11d60b926\"]",
  "[\"==================\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Game classes ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"Game_Screen\",\"30a4141354d5580f777306d6d0ecdbb706c411ff445aec44afeb55f2c1f7dc0d\"]",
  "[\"Game_System\",\"38574a92d37fad43446237e6f429863507a46b9c7c4e7806a7251ee71a307bdb\"]",
  "[\"Game_Picture\",\"271a6a3cb8462de97bb0598a907e0f75d3c13ce4190a6893287b412dce103c61\"]",
  "[\"Game_Map\",\"2e31060a4dc0ac036fecc510735f8a70f8cb8c7f33291b572e489e89c4f5b7f9\"]",
  "[\"Game_MapFactory\",\"bba3deeae94afff918edfcde6d251748498f44f59655fc9ce32aa42f304d98c6\"]",
  "[\"Game_Character\",\"0cb6a5149f998c053055d3c7726d557fe1a1368fcabe14bb4a7c159f09a686b9\"]",
  "[\"Game_Event\",\"8c11fb7f170df5ca2aff17725e1dbed031c94deebabdbbae69dd926e24acafa7\"]",
  "[\"Game_Player\",\"7159cc172004da46b72a51b7d009df24de7a297bdb09599de31a4b5116dab373\"]",
  "[\"Game_CommonEvent\",\"f040cd70e23d2c1c4e098cbf52d1a2f7c05c3bc43800af940c0b8dde3fb092a9\"]",
  "[\"Game_Follower\",\"9fa9efeeb321a0ff33430275cef310cf94ff22d8539620c11428c4ad47848560\"]",
  "[\"Game_FollowerFactory\",\"622d045cd5a87f2365339ba48bc82842c946b57b39b9e9bf0db4168444cf2528\"]",
  "[\"Game_Stats\",\"e2abbd1d044c66164d532db20734c6c02f5e5f1182d191208d0fcbaaba6d53e6\"]",
  "[\"\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Switches and Variables ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"Game_Temp\",\"dc1a4067462d8674123e35de341d79b92d4566b236970e4eead2a7fb6d68e494\"]",
  "[\"Game_Switches\",\"0859c022f2f9a507b998fb8e2a9e4a677df68a4b493216c280b0d2df1e9504b7\"]",
  "[\"Game_Variables\",\"94d61f95de05effb31a464526f894f1a31882400e50f7b6e7a99629e0ae093ca\"]",
  "[\"Game_SelfSwitches\",\"5779bc1b1590c116b2c3e099345c0beed462749746cc2c3940b034653b6a5d30\"]",
  "[\"==================\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Sprites ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"Sprite_Picture\",\"785915a3de215515428b329a1dfff6ff4f6e38a67c21027ef19a4313dd89d6f7\"]",
  "[\"Sprite_Timer\",\"4d6d7be253e895b0534cdd67a10436dcf8bf02c1992f663d11cea9a56c04b0fc\"]",
  "[\"Sprite_Character\",\"f881cd0a474fd6357b8dde0cba826b9fd07666125bfcb90190eb62d2949db846\"]",
  "[\"Sprite_Reflection\",\"7fa150af970b9fe012713f251e2af747210e059ff0d71c2eccbccd0f5018faa9\"]",
  "[\"Sprite_SurfBase\",\"51f9bfb06a37018ef6ee75c1d0fdd91b9eefcf9cb958366b64e351bf3b5edbeb\"]",
  "[\"Spriteset_Global\",\"5757dd8c55d86ab16c43ceae27d6a2b481f5453f39890e90426705c41b2489e4\"]",
  "[\"Spriteset_Map\",\"f7345c848cf6983c793e6c2e76cfb5c412900f38942b05bbd9361f5bf503b1d9\"]",
  "[\"Sprite_AnimationSprite\",\"686c9e2f81a578cb8774e66c459e7fb637e49e275440849bc325c7b5506e3859\"]",
  "[\"Sprite_DynamicShadows\",\"9b19769bf5669be28bde096d56878ee253e0076b5241c8253b5f7c9ee43c4d95\"]",
  "[\"PictureEx\",\"0d0f6147f9795716a1458bf7d88eb76704393e37c76fb423adf110ba9a225ed6\"]",
  "[\"ScreenPosHelper\",\"2284a2842612caf4c349058c97129fc5f6942a82f02c3f4dd1157f0bdb0af5b0\"]",
  "[\"==================\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Map renderer ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"TilemapRenderer\",\"321f334b2eeee0f1fa45d16f52117feb7ea765e17643b88c09a69285ada4bdef\"]",
  "[\"TilesetWrapper\",\"6967b9b594e6faf53a2306fbf9d8fe8cd0060b4000d37404043ed130c47f70ec\"]",
  "[\"AutotileExpander\",\"c40587686d2176794b79aa926e0adc5fdb67db102dd6f14a7e54a1618635e597\"]",
  "[\"TileDrawingHelper\",\"2a94034ce77b68faeb8c7620e4a9cf2ceea81580992db7c86424cc3b63393bc7\"]",
  "[\"==================\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Objects and windows ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"RPG_Cache\",\"a4fb2f5c59d6a6eac373cf0463f0dfcc511bc3fc702d2bd2d8326d60c68e4223\"]",
  "[\"MessageConfig\",\"eacf78724bf5ab978b4b74d73149e3e556906d8f63d0ed380310bdddae7a6dad\"]",
  "[\"Window\",\"3e156a2b86239971f0ddb2b3f4363c2df3afb4ebaf4abb632880806b0a27728e\"]",
  "[\"SpriteWindow\",\"ad11ad11984db15eb17b1d8bf2b625c781c37f0ba8f98b3a439943f24c3349d0\"]",
  "[\"SpriteWindow_text\",\"d8656da9b9cf627757f5d85537361ed4b46a30f678d0b6f9759f6ee174cc6114\"]",
  "[\"SpriteWindow_pictures\",\"db9dd1b71827bb6e0d5e6bab6d4116b436593b54aaa63e5d86b2971c880bae0c\"]",
  "[\"BitmapSprite\",\"be0df504505358c7e58b25558c84c88dd89f285effd2257dd26624c604155c53\"]",
  "[\"AnimatedBitmap\",\"86aa678d6f4cd3f10789c682be97d1b249fed3fb14cd5199c2286104515bb6d9\"]",
  "[\"Planes\",\"01d42e0feff2e00944d5afe6f667bd6b50bb337f4b9582053c65383059715e2a\"]",
  "[\"DrawText\",\"c6053682189b093bd8ec8d7fa8f2ac074c301c311a5f452e6d178b0c7bc01bf7\"]",
  "[\"Messages\",\"82abdb33dfad9d735c4342ca63fa72483b1a34bb01bd2a1e034b03afa8207ec3\"]",
  "[\"TextEntry\",\"2a5e82a185ee656c35bf532a3a6ca71232ceaea3eab07c9452f0d36aed6fce38\"]",
  "[\"==================\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Audio ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"Audio\",\"2265ceff8c47f69a92a39ce26abbf0492eb92f34f79bee792474a1d56a64a185\"]",
  "[\"Audio_Play\",\"e21c2f9b086f99777b7421c850e4b04cb8e5db574876b3fbb9c0fd9932e1d1fb\"]",
  "[\"==================\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Scenes ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"Transitions\",\"3b9b844bc04b565686c9781eb079254141cbec9f4a1863c467c0bf1b8cf79c34\"]",
  "[\"EventScene\",\"74e6c80b67ade4888e764c2e8b29884b68b7db52ef57442358dd8207afa06874\"]",
  "[\"==================\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Data ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"GameData\",\"a7078f0f8165e1f8c1554643b201f54a60d3d33227c5c7f99745f0686886a3de\"]",
  "[\"\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Hardcoded data ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"GrowthRate\",\"4e02aeb08e9b381e47a186b79565484bac156c035f0976a3b6dddc15d857ffed\"]",
  "[\"GenderRatio\",\"ab185714fe03a54cb4b35e38065c6577c53c6656b05b86ac909f9344d5fc612f\"]",
  "[\"EggGroup\",\"92de07bbd0309fcec06411400b62a0c746b98e57218c8add2b55ce0acf3c5d2c\"]",
  "[\"BodyShape\",\"5b2d37ee68a39bc0bce3cb97c037acb9c607643bff0ecee5c48fad5f9a9013ac\"]",
  "[\"BodyColor\",\"8b9a040b8bfb97e8122427a265bd1bc8e4a5d0835f2466e22a36a3b801f1901d\"]",
  "[\"Habitat\",\"bca068375b979bd7743e386df48370d05611d1f8689cf653de941138999e52e4\"]",
  "[\"Evolution\",\"2bd8e50cabfca5ae40581a1a7122232535bf5237f7cfdd69a6d3b6d7209090c8\"]",
  "[\"Stat\",\"088757e266e5e87cd29917527af9b5bea09d0938d4d14c961e8c33c6fe572f52\"]",
  "[\"Nature\",\"10236b30150a4a8f64c0aa73af8fa1f7d587743b89f26fe5260630b4855638d3\"]",
  "[\"Status\",\"01b169a43a1758b5ab88a1386024e6d665a250a18777c82c501bb12261eeb6d6\"]",
  "[\"TerrainTag\",\"6bcfb146b4ec27576d2c616392e4aa14f1f9baa135db85ac02b33e0139e7382e\"]",
  "[\"Weather\",\"367d7dbdcbee9ca764390f64d08be3d57b5fedd908b3b2eff688fe7b2f6b0257\"]",
  "[\"EncounterType\",\"cefb9451c60e4b2fdebc168bdddf95e158e3ef9a0cfad8f442c4a37ee575a905\"]",
  "[\"Environment\",\"e09b2ba380c26fc32d852ba16951d5fab25f5118164ba995c0e4b5cb94186857\"]",
  "[\"BattleWeather\",\"6fa6d2ba045e1171bd2e90ab1ccf132b6814289616a6b6ba4dde51a9422ea6af\"]",
  "[\"BattleTerrain\",\"a7e99d198028cc71200d41da058b9ca8ebce5c8f7b6fc9c0b5047a2e44829006\"]",
  "[\"Target\",\"35ac0b408bc46481c968ce221567e6b58d0f201c02f18229211ee31f8c45fdcb\"]",
  "[\"\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ PBS data ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"MiscPBSData\",\"5067d61aa37509af4fdb7ac267fa2adf0df3934754b64486dff484cd6dc4a6ad\"]",
  "[\"TownMap\",\"d90e49b28b477f2b332a9d4943e730fc8f05f05d9a5dbd2c4e9ae01e2a205f13\"]",
  "[\"Type\",\"425d885803d30b4479ae53280ff3dfe73038af904b25d9ab77c5752c42306b87\"]",
  "[\"Ability\",\"e701a8acca1ca9cfc20d0bd3dfdf8b4b24e8e9a96bba021d0bdb779d92012d3d\"]",
  "[\"Move\",\"6b366d35518451445b706352daee8fd5304350dd8b405936e26190a5d616a29c\"]",
  "[\"Item\",\"b280015f15e892754c90728bdbf23a77c280ebb86413cb51c64793e0b997757a\"]",
  "[\"BerryPlant\",\"e4ca046c25f2fe7dbe990816370780b060623330a8a62bb65ce336594171703e\"]",
  "[\"Species\",\"182575a3e420dea614bec5cd3ee525ccbbef2f8538571885ab5ba93f59ee340c\"]",
  "[\"Species_files\",\"b0d4786a3b33dbb06a68aa395e813ed21be46d826dab69b5c9ab41a99ae7e0d3\"]",
  "[\"SpeciesMetrics\",\"3a953fdb70edbb40f3d17767d1628fbb5e38d9f9467197e051f2972eeac8431b\"]",
  "[\"ShadowPokemon\",\"6b297593d15854cc1d62f61cea88195695126a466d92a8c63fccfa415e14a35a\"]",
  "[\"Ribbon\",\"9e429a729bc4fa17bb4f6644b255f7ca2c508d8f251275211d2f53e16e829083\"]",
  "[\"Encounter\",\"f8b8aff585c37232c0577a9280dcfe157e05b12ca886f874efc72574d7f6e9ed\"]",
  "[\"TrainerType\",\"a4fa356b8b35bbe62696d361d18e14895cc693841c26b2a2713e7b01757b776d\"]",
  "[\"Trainer\",\"c2785e8640a28c9034d6ecb2356680891681f33d2356cbc0cff7b6d54ec12b67\"]",
  "[\"Metadata\",\"2f26223b65110fd144138a787421b412f8be88d69b2919812cd371ef4bd52a48\"]",
  "[\"PlayerMetadata\",\"aaa2ea85c04c281455e1c8b8301570257472926a034a95ce8c36c287364001d4\"]",
  "[\"MapMetadata\",\"ab6c429014c7c77b80aea5eadfa9d9f9cda47954ad6bb5fc1ec952a0be384bab\"]",
  "[\"DungeonTileset\",\"ab641a82604d176266d485b52e0e43cbb73c45116f5ef9b5aabe6d3a28c01d4b\"]",
  "[\"DungeonParameters\",\"21093e8436801d336c318f9c67ad4388c64f8e26b0a31ad8f160b7fd46492c47\"]",
  "[\"PhoneMessage\",\"5848aac73ad0515956d60f0c8c804ce5fba4ee82cb0e58c368a1ea14466e764b\"]",
  "[\"==================\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Battle ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Battle ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"Battle\",\"d61fd2ce22cc27e9d9682c14ced068dca544f39921af9b1acaa18c9022325c5b\"]",
  "[\"Battle_StartAndEnd\",\"187e81728ddae7a60c076fc3e21dbd68fe89c3eeea447cab77440da04787cfa0\"]",
  "[\"Battle_ExpAndMoveLearning\",\"74f2914dd1cd40c15d6f2dda8df2ca6e6f114b4930cd71d95af17a0eea7cf1e9\"]",
  "[\"Battle_ActionAttacksPriority\",\"9d7f0c34d43cda4d183548cf04482c60d01572fff7cc4f38bbe357f04d2771c4\"]",
  "[\"Battle_ActionSwitching\",\"ecb931ca7e20a535709ece13fcd6c5bb9c27956c7fda209ed54f2a4aec50873f\"]",
  "[\"Battle_ActionUseItem\",\"9c4247c0eaecea655be533b526c3f6d68c0a16782ae5b69a351b9982ac8089cb\"]",
  "[\"Battle_ActionRunning\",\"bf404e30aed2917ecda9370c7cee1ea4c7c043168a614652460ca6d3f4f50133\"]",
  "[\"Battle_ActionOther\",\"095d2818a612b135f22489155e7076cdcf7fc04a466c8d9cdeb9e451286771de\"]",
  "[\"Battle_CommandPhase\",\"2ade8fb3329ca189566a663b3633e787de7ce8f089d2f9a615117e7e356ca2bb\"]",
  "[\"Battle_AttackPhase\",\"f77e0bc43f790cf4c196add096222fc0c2bbc7cef1bd706ff54d343265d0c945\"]",
  "[\"Battle_EndOfRoundPhase\",\"b5f8e71a591b7a29a64e167166b6012d449e9fd0e44e02427a99ba1ed83e32f1\"]",
  "[\"\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Battler ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"Battle_Battler\",\"0c7f16152470646ab105632cb77c2d55c0346cc5a57fd642c4aa9e9687569445\"]",
  "[\"Battler_Initialize\",\"ecf901198a4d8dd6e022b11c6eea9dfee2cfdae23a1218d6f09ae5922391cf6b\"]",
  "[\"Battler_ChangeSelf\",\"3f22087e79ecaa46a433755b0af8638974402d7a5ff33ee22b45b131df2d5597\"]",
  "[\"Battler_Statuses\",\"1aa2abb7170f3519934491a354be806ff2fb76c1dc38e7e2da3bc094ed062709\"]",
  "[\"Battler_StatStages\",\"0172ed00e45aa6a50a5f57c71e2737617d912686fdbaa3e2689c8589947f8e9e\"]",
  "[\"Battler_AbilityAndItem\",\"b53259af5669c6e386dab1e785d4a2a52a8290283fee5c9d24621a534e77f8a8\"]",
  "[\"Battler_UseMove\",\"94dcce1c5c2c0091b9d54663aef6fd757616bc5ce7b933736343dba06d18fdd7\"]",
  "[\"Battler_UseMoveTargeting\",\"702d8c7f08ce6aa29a811a75b2422886e6bd5f8e0a3c5390a066bca22c320f3b\"]",
  "[\"Battler_UseMoveSuccessChecks\",\"5d317559394e56ccc766469ed7f9e4abbf11d2678789ee666d6b3a532637d046\"]",
  "[\"Battler_UseMoveTriggerEffects\",\"5830337dd0e198201e80874a917e50cc012a2478b52a82127f6337642d763d28\"]",
  "[\"\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Move ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"Battle_Move\",\"9491d693cc9f392c7c8c9ad41e058a768a420f5d36f27ae70be86a54f9368261\"]",
  "[\"Move_Usage\",\"03398b926ff2044de7d56447f8cb97b3ee9af1015590cc5f47c2be9c7114d09f\"]",
  "[\"Move_UsageCalculations\",\"5cffd3a53fb2f2f2a331857d6e77b249b27131413e7fa09bec9756b91da72a8b\"]",
  "[\"Move_BaseEffects\",\"9b317a836354d036395fd7067be5e2348280f94160de82ada6150dd0c30e1231\"]",
  "[\"MoveEffects_Misc\",\"ea895fbb3d798a0d03b1d339612846a203bda4bcfd13aa910e2efeb94cc1061b\"]",
  "[\"MoveEffects_BattlerStats\",\"95390f19fcc1debbe2f2bd917233995864afa38fbfbc5d29682237233c64e42b\"]",
  "[\"MoveEffects_BattlerOther\",\"241a142513787012eae1d3cd36bec72b2d9e246744313d292c28742744af830a\"]",
  "[\"MoveEffects_MoveAttributes\",\"ace8394350f240b9a754c0cb77002fd5492b7312bd6e1e5245abb7dfbc64a88f\"]",
  "[\"MoveEffects_MultiHit\",\"d8d72ea1fab478c1818d7bda04a1450cca4e299f0cc2126e1cfa42930fa8015e\"]",
  "[\"MoveEffects_Healing\",\"ac9c281b28a76ed2677f26f6852d36af71420e2df710082237fcf0e9b38a1ed8\"]",
  "[\"MoveEffects_Items\",\"c180895800f4793523b40d69e6c48fdf6c8652ccb681bbf110c3103f01a62b68\"]",
  "[\"MoveEffects_ChangeMoveEffect\",\"b2c9fea638524e0de1ac2f12ffb5422b1cba6bf18278b33af60f0de6139bfc70\"]",
  "[\"MoveEffects_SwitchingActing\",\"a8ec2d10441fd72ce1b06a6694292e11c17084823606f8072ae4371baabeaf68\"]",
  "[\"\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Scene ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"Battle_Scene\",\"425b6d06e5ca7d3d12eb83b3a098086788d6ba95837718d519dfc85f375ff72f\"]",
  "[\"Scene_Initialize\",\"00ddb126a297238a40562550d3684bfa3ae0916978e74bec9c11e45499632d5f\"]",
  "[\"Scene_ChooseCommands\",\"22a3a41effa3ef82d16b6d4d59148ee0f2c0e684764c012bf38afd8bcd688b67\"]",
  "[\"Scene_PlayAnimations\",\"1c38fe47dda2c9abda38aebebd99f5191bae5d1505cbfadf3bcad55f81109a23\"]",
  "[\"Battle_Scene_Menus\",\"361ae124e14dcc08ff5bd0c1d5e3d9c83ea1352b232964052a733396c073ca41\"]",
  "[\"Battle_Scene_Objects\",\"66189d62299bec341867dce8edf919e9cf9201ca9cc51526e57d05ba0a0d5746\"]",
  "[\"Battle_Scene_BaseAnimation\",\"26985b71449eca23faf2ff922b03378b8c06e80cce7558f8a91d48999b20dcad\"]",
  "[\"Battle_Scene_Animations\",\"89c1fc43cdda0816f51913f81e1a976f8ad6b95fc8b2ac17d966089e78220070\"]",
  "[\"Battle_DebugScene\",\"ac6fc8114246746472adb6732ca2c5e3598d237434d126710a41a9af5de053a1\"]",
  "[\"\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ AI ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"Battle_AI\",\"a3b74e606586bf4dc43e3fb1dd6f2b05b9d1d7b3af18a4f5e7c72275c9525442\"]",
  "[\"AI_Switch\",\"e3e30a7699b72898119facb019da56e0e31408e3ed47dae3c510fc6a9f49a05f\"]",
  "[\"AI_UseItem\",\"56c2a84900d0dd3b01e0b167c422baece4eb34f1225051dd54afbf92e1521ad3\"]",
  "[\"AI_MegaEvolve\",\"d8a4e2aa58dde1b9b40d1f1e10ee0b00767df7697f5402df96ad516f7ef7101e\"]",
  "[\"AI_ChooseMove\",\"a81f68669d5e9764b240631c600b2069bf346feb2a557338062740c91461d5c3\"]",
  "[\"AI_ChooseMove_GenericEffects\",\"04e3c20029c51597c5339e7b143b8d1a634816e4ec2800eb1a92e7e6593a8d11\"]",
  "[\"AI_ChooseMove_OtherScores\",\"c543ef8e8b0353ab38b93012ddc4e8520b64addf829436bc142894b3e965f3de\"]",
  "[\"AI_Utilities\",\"f2c91195d816b5ab3b9af3a92251230ea65d8eaba8e0a0d9f0f1bbc5b6f60fa4\"]",
  "[\"AITrainer\",\"d968879e7e9f691e6cd257ea98d89c7e0efef13872afcdb525bd3f959f0573b3\"]",
  "[\"AIBattler\",\"14db6b5ab47d9abe0c8b977c8c5815d611ae52d0f181b3d272f07715d9f66c3b\"]",
  "[\"AIMove\",\"5a5a46afee72e4b17a5b214eb939661803db149d3723b785edf857b62efd508f\"]",
  "[\"\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ AI MoveEffects ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"AI_MoveEffects_Misc\",\"8aed2cc6cbedbcd3cc6df4eb423212dd6234d24be832a19116153e7c8ddf7393\"]",
  "[\"AI_MoveEffects_BattlerStats\",\"2dac369a1cb0e926b7d7fb5e42c45bff933cbe98c69c47a3eac14db388c9e2ca\"]",
  "[\"AI_MoveEffects_BattlerOther\",\"d4a290b76325bc25d123e48a62d41f7b1d2c7105286f3cbae4c6040c894bd2a1\"]",
  "[\"AI_MoveEffects_MoveAttributes\",\"af45e0e795ba20a62124ef8ca2379970f3421567e71ebe04ea923b5405b31a10\"]",
  "[\"AI_MoveEffects_MultiHit\",\"8cf108c92f4faf2e18f06ba93cbde5f254d4600d14418b7159b889954c093cc2\"]",
  "[\"AI_MoveEffects_Healing\",\"d76a207092d28dbdc5bb1156372f839a1e7c108cffab829efa9a8885c9359842\"]",
  "[\"AI_MoveEffects_Items\",\"f7c1835eb54a2620c1402f8ac4163dbd107f440823b01ac47a63144bfacc0915\"]",
  "[\"AI_MoveEffects_ChangeMoveEffect\",\"e554f8cbd511ba92103174c1c802ee21e6ac3d45881107d27e08c083e7205cc9\"]",
  "[\"AI_MoveEffects_SwitchingActing\",\"38f36d9c960404c73863f32b1b4a81e31c393866c479eb39b29f38ecb0a2e94b\"]",
  "[\"\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Other battle code ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"PBEffects\",\"89d6f03c58c1b36bb503c423d91d5dc59b7b467450ae7b577f479f38c70cb14a\"]",
  "[\"Battle_ActiveField\",\"428a25fbc23f381a32daaaa0e8bd3ed5a6de3c3f53e750551f1ec2195814636d\"]",
  "[\"Battle_DamageState\",\"9e6353e15209c767d3ebaaa912355faba75445eec2a243758acde2704f8340db\"]",
  "[\"Battle_Peers\",\"0e56a6066d9fce2ac9167d6c1ab583cee7309bb0fcd9f2f7e61674aabc663799\"]",
  "[\"Battle_CatchAndStoreMixin\",\"8a478c131ddad3f9544cd3a07566225a4b774afcad2facc17fc1fec25e8b1b34\"]",
  "[\"Battle_Clauses\",\"328fde6f00396613bd1cc08637d84ff76a1a0e5e183a9f17288d7de0b11c4454\"]",
  "[\"BattleAnimationPlayer\",\"10477d2c855252f617058eab304d1dedd4610fbc31a6142175a8cf458e8b068b\"]",
  "[\"Battle_AbilityEffects\",\"7ec72487ba6a541cda9d09b87df8daf2737bd99cd122ab3ad16aef7c581369c6\"]",
  "[\"Battle_ItemEffects\",\"a64f775db1915049ba944d668266926ae437073176c32db36b8439749d98fac6\"]",
  "[\"Battle_PokeBallEffects\",\"b0c0e3253868c2aa14347bb0452fbcdf27bbc9d16398e239f5a942c26476ee39\"]",
  "[\"\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Other battle types ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"SafariBattle\",\"0256e548c4205ab4958124f9f056e4060c73dcf574397c31015b48ec72d4420d\"]",
  "[\"BugContestBattle\",\"980457d0802b0eba61dc25a7b5770e0064ad6f5b8d91ddf90f9c9e026b8a7988\"]",
  "[\"BattlePalaceBattle\",\"54cbc17da345fb905dc1347d31b10173db29397f8c49fcd396d0f9039f8c3995\"]",
  "[\"BattleArenaBattle\",\"2bf1fd154cc509766e3a6e49a7018c45eaf3474e0a42aa9e40c80bab620936d1\"]",
  "[\"RecordedBattle\",\"3634d266c9ad1f105b60bc6f9fb6910a70be0cfc7156e733cdc3108095b29f17\"]",
  "[\"==================\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Overworld ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"Overworld\",\"c96fe00962737e464754800079f8b1c43a9d2d88ea446c0357211e40383093b6\"]",
  "[\"Overworld_Metadata\",\"621556b63b01402ce0ff8fbdc0dfe9fc1798cd7c71c9aa1877eca6d5fc235cdc\"]",
  "[\"Overworld_Time\",\"727b1d21d8bcf678a8f31a22ef4366c9091dac724e4ef05ce0be70b3fde49cc4\"]",
  "[\"Overworld_FieldMoves\",\"059eda46398b762791c755e7a41fcb80a1e56fdbd951c3b74f1d676513084c4b\"]",
  "[\"Overworld_Fishing\",\"0c49fbc54451e9e3e503c33ead66010e93d1a398849a244f4b67cfb0a4490618\"]",
  "[\"Overworld_BerryPlants\",\"888486adc245e12e34fb0ff8a1f2962b46e633bb84c9acdcef95901ad5d44c3c\"]",
  "[\"Overworld_DayCare\",\"8652f1dbc282c6ac88324e95b9dab21ab30ea36b40631cfd40c7bb77759a25cb\"]",
  "[\"Overworld_RandomDungeons\",\"563ab4688696f10fe7f231e893cefbacd429eef138287302bb046e280e50ac0e\"]",
  "[\"\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Overworld visuals ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"Overworld_Weather\",\"f126613cf1116f76e8cf3fbec1c6480062d00bb6c3e3780454e3991777742940\"]",
  "[\"Overworld_Overlays\",\"b0598a52d69449bb7e20d91643e6df0c1396edb259c844003eb08caf660828ea\"]",
  "[\"Overworld_MapTransitionAnims\",\"33c94f0f652a4a57528201a6d8ca785bd7217f2befa476a27d2eaf4d58129072\"]",
  "[\"\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Battle triggering ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"Overworld_BattleStarting\",\"7a0e305aad2f7939254b9e322bb86ee592e2da338b114cdec2a74e4cb1ff4b04\"]",
  "[\"Overworld_BattleIntroAnim\",\"0e1232e183d485ac30c76dcf5eac3a542925b76a5855bbd9dd66f1939d92c3c3\"]",
  "[\"Overworld_WildEncounters\",\"1c407a629598616d211b50aea2b7561f17c90dbbd7c6175087fdaa60dc6650e6\"]",
  "[\"Overworld_EncounterModifiers\",\"44dd70841fb0e673fbd1ba7775234fd71ae503650783d9c19cb21bd62d4f4af6\"]",
  "[\"Overworld_RoamingPokemon\",\"e9cc4fe4fc73077d42ea6e0e4baf134c92dbe906563ad009d82aea13e092b37f\"]",
  "[\"==================\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Items ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"Item_Utilities\",\"b369790209eed0d6eba20e9e4e3fc4fdadbaa3b0822e5796926e59296ca6f429\"]",
  "[\"Item_Effects\",\"9f5bb1a5663c6ca9d34fc256f577a7918f5def7e76b2426a37116348af0bf1bc\"]",
  "[\"Item_BattleEffects\",\"879b6e08172529f2365100d01250c8318c26675c573c09addb53533d25e7e576\"]",
  "[\"Item_Phone\",\"83a7c15379786fead4e60633ca19fdc5a810a2200dcebe6e6a8fca5999f5d9f2\"]",
  "[\"Item_PokeRadar\",\"6a8850cb939fe1992988ee57eac03f882d4514c5550c6da16f3a4ac1dc75b33e\"]",
  "[\"Item_Mail\",\"ca2fca70a9939313dab674f8658e02e7f1088ce86fe63fa3d49cbec1fda53505\"]",
  "[\"Item_Sprites\",\"ef252d26156887442883cef15c91f95b42f632b6c8cf1cef1310c4a07bbd0311\"]",
  "[\"PokemonBag\",\"1ec9a83206e82546b286d5524b764942795119ac0b26e26049b9ac66dbbaf2aa\"]",
  "[\"==================\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Pokemon ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"Pokemon\",\"2cc5db14ec402faedd355afddca951743a7723d1dc0724c45d3f230c2cb116ec\"]",
  "[\"Pokemon_MegaEvolution\",\"4124cf030b592eed40f0df9a9b217a93652c036330da0e8723c42d59d569242d\"]",
  "[\"Pokemon_ShadowPokemon\",\"ae5a09d517617e247a37676068ba8de9383b437deec698151f54e36fc22de7ee\"]",
  "[\"Pokemon_Move\",\"3535a4b60536b374af0d617662c9502ec83219116b39b994573bc1b2786e0ee0\"]",
  "[\"Pokemon_Owner\",\"ea116ae241f5af84dbc57d8a65842ee26db4a1be70633c906a054eb235fb362e\"]",
  "[\"\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Pokemon-related ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"FormHandlers\",\"4b5642fc3daf0fba0302ad44d5b3c83a573ffbe1cf5e877b2bf5ffafe289f359\"]",
  "[\"ShadowPokemon_Other\",\"296ad501154ba33c46fdf0a72f4b6b7ab9dcc2c7a9a716b5431a8c3f9d118698\"]",
  "[\"Pokemon_Sprites\",\"6a766adbb52185149a91750e2bb807d33ffeab4495b6c96657590bd6c7aebe87\"]",
  "[\"PokemonStorage\",\"5121575a121cd71a6b671f319f4a2ab0a33da9f9d35618a43048c7d64f87401a\"]",
  "[\"==================\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Trainers and player ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"Trainer\",\"b2995a8b8b9fa8381b21f9a37042d217843f712f7fecd00bfd462d79e068c2a7\"]",
  "[\"Trainer_LoadAndNew\",\"d45e910ed84d76be500dc6b2116a6beba08b1b35ad92155750d45af86736c421\"]",
  "[\"Trainer_Sprites\",\"4d961553554d6a45233f1e11a3ea96e658c403f2d2311d12e154609cdfbbf08e\"]",
  "[\"Player\",\"8f9fa3355577b8b4e54ce32d5046ba03615f38aeab816a0944cfd2f0ffd160e0\"]",
  "[\"Player_Pokedex\",\"98892b18078f757431c6db5a27d1932380010275fd8929724d4d10f5fa979fc5\"]",
  "[\"==================\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ UI ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"UI_PauseMenu\",\"b17bb5219ce7cc643f69f417b5ce238527a27f262052b64c7f93b5243929c6aa\"]",
  "[\"UI_Pokedex_Menu\",\"b262d122900b26ccf922d6dcb83507756573dfbc58bc9461162f7e97663d8dc5\"]",
  "[\"UI_Pokedex_Main\",\"2774a392edbe3e57a0ec67965ffa71c9c2ac26779b5574cfb1c555eb74273eac\"]",
  "[\"UI_Pokedex_Entry\",\"af15207e894391c09dbe726a7a5ec5372195ed9f31b565d6202671347604e97b\"]",
  "[\"UI_Party\",\"241349e2889ca9c6d149df0f2a96b3f362975acfc12518bffa4f13554db64d5d\"]",
  "[\"UI_Summary\",\"aa8ad572399a2ebac2e3880295dde5a102cec9cf9afc8283481b0c19110cbf0d\"]",
  "[\"UI_Bag\",\"5867c7690465335e1177034ac6794b3f7dca763fd03141e5dd67d3643a62ca4f\"]",
  "[\"UI_Pokegear\",\"49c9f82f78a45aaee19eb74aca6418f64f4133d9e86ea0463709ab6bcdb4ad76\"]",
  "[\"UI_RegionMap\",\"67a4511fb1c48f2533a7a930a615f4d0dc9be8d8ed4a19fa67bece3968856c13\"]",
  "[\"UI_Phone\",\"54e60bff61b15ece07c32b4f0939a97c39440a6e2e8a9ca4a2eb2b4b80f60464\"]",
  "[\"UI_Jukebox\",\"4723c50ad91fa51734dc07255e1c4975a6797de16cd47f358239c12647f1166f\"]",
  "[\"UI_TrainerCard\",\"3bfe512b3c7c30dbccf4c182eb8b60ac23efad8fd50b73422421b2de27b88f70\"]",
  "[\"UI_Load\",\"2f86f030a38a50e641d61225f678d679865be89c325abe7f20e8134ac24b993f\"]",
  "[\"UI_Save\",\"2133ad67a13cfa99b88ec6a5b394629aa8ea9f25760517c34a88f6e3e3aaa186\"]",
  "[\"UI_Options\",\"3368adf8185258005fc0ee11bf97aeb4e54597b96404365bac5ef79a500dcfb3\"]",
  "[\"UI_ReadyMenu\",\"4ba3f38bdf159d177c8022712e37474eb639bdbac6c18e8d977c389407926608\"]",
  "[\"UI_PokemonStorage\",\"562f34aa8db3f2d903cf9462d07d5f20828c69061fecb4ebde5c290228c09c4f\"]",
  "[\"UI_ItemStorage\",\"3e38e7587b8a277eef5021c1e945690d7b0e7c86c29e5a7fbb970dc19321be20\"]",
  "[\"UI_PC\",\"16e00f91957ab68b5701864c5b53074d2c3e3488382374a2e28d22a789b800f6\"]",
  "[\"UI_PokeMart\",\"484315201c01010b3978bcac6968834b2a60c7a8d6b348abd83b4c1a4c234b53\"]",
  "[\"UI_BattlePointShop\",\"c3848f2ae9a8669b86cc2d6eff93c983fedb68d98f33ff5a05b143825441bc13\"]",
  "[\"UI_MoveRelearner\",\"f86909d5b942b531d7b0800bd24a0cb073e6f390bf8484f0793b7c6cdd8415bd\"]",
  "[\"UI_PurifyChamber\",\"39d444a35c10ea60c40c99fef28635d78135e5400eeb28c00280e0660c6014bd\"]",
  "[\"UI_MysteryGift\",\"164506efa6161c57c4475d8dddcf2383b63a8ea615970b644f3072a7e9016a5f\"]",
  "[\"UI_TextEntry\",\"eaed70af13ff1f6c21f6d10a78ac532fcec57d0e50350fbed33cdd228178a29d\"]",
  "[\"\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Non-interactive UI ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"UI_SplashesAndTitleScreen\",\"18b07f58ab743f6db17e316b0d77a9d729b4ad3a823e3b7742b1c55f1f23fe0f\"]",
  "[\"UI_Controls\",\"8a2eb1687ec25fd56dc229fa9e6aa513c1673aef6dc0ad671f613ca7efe15d33\"]",
  "[\"UI_EggHatching\",\"b8e5f98d6b6a5e3a5bd2f487780a27dd1cda1943094537945563a18f0d47e38e\"]",
  "[\"UI_Evolution\",\"654719fa9652157de7edfc7246e72ae286cf24bf87a04eb23765ffbf4badc86c\"]",
  "[\"UI_Trading\",\"d21968157e1745d5cfa5e252ee733637c60513fb77dbe22b9760a1e247a7e1e6\"]",
  "[\"UI_HallOfFame\",\"1e84df5ca2099b9d0311b4ba1844eff9867368cbf8cd22f823123fadfcf75d63\"]",
  "[\"UI_Credits\",\"6df0006bcfcf2dcdfc271003511c753fe565fbe79083285f563938ef06400d77\"]",
  "[\"==================\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Minigames ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"Minigame_Duel\",\"b77c9ba43d7fbb9517829a8d5241af5f03e84c3ea195ddeabc40ce1a3be05b42\"]",
  "[\"Minigame_TripleTriad\",\"dc1e55234000b74cdcbb04de8fece3a3325b0747ef4404a7f56197a179024190\"]",
  "[\"Minigame_SlotMachine\",\"8a9ea62073904f7200c51ee09de06f980b7d0e361affbb0834bb6d0444c10696\"]",
  "[\"Minigame_VoltorbFlip\",\"bd5ef91f8f730f11c38e5da76712f294a2d820ff56dc0aaec0469d7b3019e7f7\"]",
  "[\"Minigame_Lottery\",\"4fd4d6ff146428c836bf40479bc2a743ee6410e0940bc330288e9fa4bc2ae90c\"]",
  "[\"Minigame_Mining\",\"44d6148def9e6e9350b7ef3519ab0ea2160be54eb003afd3ac97cc56c56622ba\"]",
  "[\"Minigame_TilePuzzles\",\"a6b475060c69571e7393a4bba3ed5345a82bad88baa646bb0a0609d05340f97c\"]",
  "[\"==================\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Alternate battle modes ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"SafariZone\",\"dfdfa41aba83c9785008cec4f8f4d1a465516c1ae3ca730fe51a0ac654754295\"]",
  "[\"BugContest\",\"38b21386b4b430a5285d01dc8d646b1072f315cecf90cb5fd336438e1df4ce64\"]",
  "[\"\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Battle Frontier ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"Challenge_BattleChallenge\",\"2afc89754bcc6790a90a6d48d0a366e211669db4f4d382dd86a2cc4d62be526a\"]",
  "[\"Challenge_Data\",\"c5ebb0ca3aa3a2f0dc52e001c77358b1d7020b357ae849fb0675351e72a86832\"]",
  "[\"Challenge_ChooseFoes\",\"daec56dd1a7b8179e2b43ce5a884833fee02c825ff8d8c0cf5800d64237ded8e\"]",
  "[\"Challenge_Battles\",\"ef852fe9567aefa983a8f2ee33c2c57171058dd1d3e4c61b916f3f26fb439e90\"]",
  "[\"UI_BattleSwap\",\"435684d44c61bce19883c39badeb17b5ae7762b2794e7a4acf868f2483e12ec2\"]",
  "[\"\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Battle Frontier rules ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"Challenge_ChallengeRules\",\"8209d606b2d748cc45f815daac89236ae6f202701f0499eecdd07831c25b23ab\"]",
  "[\"Challenge_Rulesets\",\"8eed114daedd0de4794bbb3b7f721c5fd1abc786bf65c6d5237c7f4a636e5756\"]",
  "[\"Challenge_EntryRestrictions\",\"c6d1166cb863b9aa233d12f3d63a838c0e1ba0ced076745f906f280a3a1486b5\"]",
  "[\"Challenge_LevelAdjustment\",\"c1d8ac139818772968d2f49c2877d1c229dcc6773904c5693f9ffbd908f2d719\"]",
  "[\"Challenge_BattleRules\",\"7d7c081380393705ca17e50320696229abd91b879536911be1d1621792e05ed1\"]",
  "[\"\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Battle Frontier generator ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"ChallengeGenerator_Data\",\"d1879fc1dbd22800f7023e618151a3ccc6d10ac09c5fd7dde11cb853433e0642\"]",
  "[\"ChallengeGenerator_Pokemon\",\"1d7130671d8c135c26c516b3e63faaac6693d0ed0b87570379ba1d40fc9b3dab\"]",
  "[\"ChallengeGenerator_Trainers\",\"032348011307aa326a6692f434e435cc57f35305ac33340d8fa69b16969e2ef3\"]",
  "[\"ChallengeGenerator_BattleSim\",\"cb353f1dfc1cc0ec2c3f071b15954bf56ae51eb1f1b0697b0ea4f81b13482094\"]",
  "[\"==================\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Utilities ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"Utilities\",\"377ba5397ff74128812af4ef5089de7ae480f6ad7ff040adea91bb25b24671a4\"]",
  "[\"Utilities_Pokemon\",\"f94d2cb7fe5a5dea5aff34095642cacf4bd7d57b2a9251a39f735743348dc369\"]",
  "[\"Utilities_BattleAudio\",\"5026b55745c88a0991a1dfa2b5b3c1f394db5ad1c6ac6fe09d8aec6ec111be44\"]",
  "[\"==================\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Debug ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"Editor_Utilities\",\"99250fe82810f64390d6543b55ba832692cc59ffea1f8cc174a40ff613a1c88f\"]",
  "[\"Editor_DataTypes\",\"eb14dc42e54fe94e75cb9df9cefab9599e240045003a1f8e93fe0327324af143\"]",
  "[\"Editor_Listers\",\"79992af16b88a2ea81bb3fea26a4a76f98b36041dafa1cc7d185449c4569d8d9\"]",
  "[\"\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Editor screens ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"EditorScreens\",\"a824303fd62b292524ff284faeca4368f71b7526b8014b920c16c476f3cb3cb2\"]",
  "[\"EditorScreens_TerrainTags\",\"4e8606d74503a24257874ba13b628014eb8579f73554560e759d4e0e1de4487b\"]",
  "[\"EditorScreens_MapConnections\",\"3aef5b790222abcac17a4aff343633b5b4e963700feca78dcb0bb8c96a8127f9\"]",
  "[\"EditorScreens_SpritePositioning\",\"208a30119120a005aef7b301fddcbfe38bf011362662f46941882282afec8bc8\"]",
  "[\"\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Animation editor ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"AnimEditor_SceneElements\",\"3e937f282c16852c04e12673315b54db06bcec3131860a296848f460bb3d4ec8\"]",
  "[\"AnimEditor_ControlsButtons\",\"1f95f81e07ab04d2d0aed00096940a6a5544848e03d51560b9f02c92ca5b032f\"]",
  "[\"AnimEditor_Interpolation\",\"5ba96015be65e75c969012d04c22303ec8f45ff1d1191d150ada544c63f86bad\"]",
  "[\"AnimEditor_ExportImport\",\"908f0021fc37fd2aa04aff9d4b0008497418b3530ad0fa433a9d8f2f72ac2630\"]",
  "[\"AnimEditor_Functions\",\"abaffd65617f9a2c3580ac7f5a403a0b5210fa28cc2ac5c273abf13272db5882\"]",
  "[\"\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Debug menus ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"Debug_Menus\",\"60117cbe3a317c7ea095c130c1aa80accfb78f236e4d4a019b4b1688419473c1\"]",
  "[\"Debug_MenuCommands\",\"569d05b13ba2e723258a140da039401ace45a4554425523fb312ef80a58df29c\"]",
  "[\"Debug_MenuExtraCode\",\"138385f3af1eb16b61d90c8cbf6dac244fa0338ab2b9da84d5e5f4e67a48ac5e\"]",
  "[\"Debug_BattleCommands\",\"ed5980ddb2fab2344e0e4b2e77b37b19e96764ef8c634d4585138e5de9eb0444\"]",
  "[\"Debug_BattlePkmnCommands\",\"22aed2e35dbdd322cf2767117f91bb14f937f376becb2a116d5166ebf02e6360\"]",
  "[\"Debug_BattleExtraCode\",\"ec8f8d441921572550abe552fa62f9d678abbab7b598b007310263017e563da0\"]",
  "[\"Debug_PokemonCommands\",\"a39b559ba29743c7eb2cd7aa663c640f868e7332abc3805f9dbe5a61146777f5\"]",
  "[\"Debug_FilenameUpdater\",\"bda3598f348785db8e986ff432b39f3df4204fa4925008d40e9926d5a591b6e9\"]",
  "[\"==================\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Compiler ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"Compiler\",\"fd02018c63a2c8d56232b798e50bf790e85347e12ac3feaad2d224a91c0cf868\"]",
  "[\"Compiler_CompilePBS\",\"5430ace38cc5142e4b0cc66e34ee0ea9d5b0d4ba02dfdfec87015981daefbc96\"]",
  "[\"Compiler_WritePBS\",\"65a54ef75dc07f3a6efd710427f9cb768d3ee74f8bfda92ecb5099702d1b747e\"]",
  "[\"Compiler_MapsAndEvents\",\"b226f7a6994d9e7d01a558972e9aa9dc96090ca11fba7cc17d85d81679850e46\"]",
  "[\"==================\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"[[ Main ]]\",\"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\"]",
  "[\"Main\",\"2da0a2320563a78fcbfde1b2dbf72128006520fe02fdc369c0e133e9678e8466\"]",
];

const _knownPluginNames = <String>[
  "v21.1 Hotfixes",
  "Generation 9 Pack",
  "Modular UI Scenes",
  "[MUI] Improved Field Skills",
  "Bag Screen w/int. Party",
  "[MUI] Enhanced Pokemon UI",
  "Deluxe Battle Kit",
  "[MUI] Improved Mementos",
  "[DBK] Animated Trainer Intros",
  "[DBK] Dynamax",
  "[DBK] Improved Item AI",
  "[DBK] Terastallization",
  "Tileset Rearranger",
  "SpinTiles",
  "Regicode",
  "[DBK] Animated Pokémon System",
  "Following Pokemon EX",
  "Delta Speed Up",
  "[DBK] Enhanced Battle UI",
];

const _knownPluginLibraries = <String>[
  "[\"v21.1 Hotfixes\",\"Battle bug fixes.rb\",\"5e6ce4dea53248b200f2eea562a83ca525de9544fb2e56e5ad6f4ecdff0a1e7d\"]",
  "[\"v21.1 Hotfixes\",\"Compiler bug fixes.rb\",\"cf46fefffdcab6cd95e7311f2845b565a171c64d72670e1a3f494b3172fa5824\"]",
  "[\"v21.1 Hotfixes\",\"Misc bug fixes.rb\",\"2b30fc86ac3e21d4a24d2866cfded75ffc8bb63aaa4503dbd184c81956260622\"]",
  "[\"Generation 9 Pack\",\"Settings.rb\",\"aa1a630546e377353542bc102a6af76b6bc2809a7c391a402cf5e128a6c13fc8\"]",
  "[\"Generation 9 Pack\",\"[000] General/[000] Pokemon.rb\",\"1f16e6749c963039b99e27258c37fc4f0e1f19efac8f8efa9cc0a781fd77da7a\"]",
  "[\"Generation 9 Pack\",\"[000] General/[001] Summary.rb\",\"fb8e44b4b455ef9900429d544625c4322ffc373c8e9cfacca824554e822df86c\"]",
  "[\"Generation 9 Pack\",\"[000] General/[002] Debug.rb\",\"24215e7138a41805558f622c60c9d1a832a4dca44fe71cd56a61fbf3fd030d99\"]",
  "[\"Generation 9 Pack\",\"[000] General/[003] PBS Updater.rb\",\"921518c635ff7e61fd4f504c64cadf050a8c73795d65b18900813fb549e4e82a\"]",
  "[\"Generation 9 Pack\",\"[000] General/[004] Pokemon Sprites.rb\",\"138da43aa0345e55f9642ccaa5c56ed73d13769b3e5e76277d7498bc12425307\"]",
  "[\"Generation 9 Pack\",\"[001] Battle/[000] PBEffects.rb\",\"55567225fcae505468edd021a28a75726d4aaa64fd265095832ba0b780449548\"]",
  "[\"Generation 9 Pack\",\"[001] Battle/[001] Battle.rb\",\"0c55b6bccf6bd7305c2e0972073983af38fbc623e7cb18d3c6e6f4814b0f260a\"]",
  "[\"Generation 9 Pack\",\"[001] Battle/[002] Battle_Battler.rb\",\"7bc569cbb313bc1acf20509ade8ae207a73d3b6c86ee2ae6cc1f3ba5d0f2d01f\"]",
  "[\"Generation 9 Pack\",\"[001] Battle/[003] Weather and Status.rb\",\"9a92902e64851983c0ffc510a19a58c95282a974174d696c9105f3e0a91fb5f9\"]",
  "[\"Generation 9 Pack\",\"[001] Battle/[004] Legend Plate Functions.rb\",\"aedea792bfc1f02c146f2425636ea92512e015c992ee6b13d9a543f20dc53c40\"]",
  "[\"Generation 9 Pack\",\"[002] Battle_AI/[000] Battle_AI.rb\",\"6b457674f35369d8a59dbc3da0a71fcc415eacfbd5e5802921e32fb8827e6f98\"]",
  "[\"Generation 9 Pack\",\"[002] Battle_AI/[001] AI Move Rankings.rb\",\"5eeb6838a0edd87fd22763dc5fcb00485f016c1d59467113696a9f3303641994\"]",
  "[\"Generation 9 Pack\",\"[002] Battle_AI/[002] AI New Move Rankings.rb\",\"3425b7c085875ad620d973640708640ef1094654fe47d34c60d325191ff39a6a\"]",
  "[\"Generation 9 Pack\",\"[002] Battle_AI/[003] AI Ability Rankings.rb\",\"dad11ee05ca2d745be2ce48fde410744e43952adb3b9bb9954042323652ee60d\"]",
  "[\"Generation 9 Pack\",\"[002] Battle_AI/[004] AI Item Rankings.rb\",\"d9119df81b945d17fddc9e76e5ea2b81b509bf6f5550e72cc304ad504c7ba876\"]",
  "[\"Generation 9 Pack\",\"[003] Moves/[000] Move Functions.rb\",\"e750bba32e547b4dc4e4f15b83f6c8d71a072404b494b789137896a12a17e088\"]",
  "[\"Generation 9 Pack\",\"[003] Moves/[001] New Move Functions.rb\",\"877e773d11628b1762b0c272b08635b4ce37f31de4c06a196f50af23623f5974\"]",
  "[\"Generation 9 Pack\",\"[003] Moves/[002] DLC Moves.rb\",\"6b2960e59994414537b113c6233711b161eee9386dbc323f44446bd29e337ccf\"]",
  "[\"Generation 9 Pack\",\"[004] Abilities/[000] Ability Handlers.rb\",\"c239399ad9f352ef470ced6e4db497df8d763435c0c0999fb4e3322e7434a34c\"]",
  "[\"Generation 9 Pack\",\"[004] Abilities/[001] New Ability Handlers.rb\",\"fd19e9c35e6c1864e5fe8affc6d1fdccc5df42da23bf321e1804d6f1e07c0d36\"]",
  "[\"Generation 9 Pack\",\"[004] Abilities/[002] DLC Abilities.rb\",\"9218575d71e827060e107948ab32883ec9f36a963c60bfaa95434a1394856c1d\"]",
  "[\"Generation 9 Pack\",\"[005] Items/[000] Item Handlers.rb\",\"bbfeb1b9fdf3b611d43c75483e67f80fd8208e09733526b5d544b974d47e2f19\"]",
  "[\"Generation 9 Pack\",\"[005] Items/[001] New Item Handlers.rb\",\"f4ca26622b5640a75580051435ba00cc08ff0593c98469054016295e8a9e8539\"]",
  "[\"Generation 9 Pack\",\"[005] Items/[002] DLC Items.rb\",\"709f6695ee4e926c29d0b0cbd6894c26816fe65252d3c8d1f447fbc1f60274a7\"]",
  "[\"Modular UI Scenes\",\"[000] General/UI Module.rb\",\"a555534900a013016c14dac219995255dd8145aaabf6c18bdb6dc6a0f50d6340\"]",
  "[\"Modular UI Scenes\",\"[000] General/UI Party Commands.rb\",\"d9a262a1262166b63f7654bf5bf69f4d117a61b19b21e69cd051064206899f18\"]",
  "[\"Modular UI Scenes\",\"[001] Summary UI/[000] Summary Settings.rb\",\"e7ef894164b59006809bec62ef718969b8487c2e269ffcd566ebdeb8f9eb2637\"]",
  "[\"Modular UI Scenes\",\"[001] Summary UI/[001] Summary Handlers.rb\",\"5dce45d8fe4acbd503fc56e652fa783680ebfef584abf9f1ee316c3a6e6ede0a\"]",
  "[\"Modular UI Scenes\",\"[001] Summary UI/[002] Summary Utilities.rb\",\"a09485174190f6fd17decbf781b7ef5c44e7261ef5f0142e0dc32aeb7cbfc5f2\"]",
  "[\"Modular UI Scenes\",\"[001] Summary UI/[003] Summary Rewrites.rb\",\"c2c4d8c9e500526e8e9418f92168c150b923b41974a83b86a8b41182d642b017\"]",
  "[\"Modular UI Scenes\",\"[002] Pokedex UI/[000] Pokedex Settings.rb\",\"49b93055eb7d937fc6b9fb47204646aa3c0c69cae13f2a8efd6586135abf978a\"]",
  "[\"Modular UI Scenes\",\"[002] Pokedex UI/[001] Pokedex Handlers.rb\",\"bd338d59e909b1b72e0e77f56a017fbb593c500fd6280d345bde0be5e7679656\"]",
  "[\"Modular UI Scenes\",\"[002] Pokedex UI/[002] Pokedex Rewrites.rb\",\"9c5c368096bda8b8c4bb761dbbc0055975997f2c1b3abc16859ca95ece4dffb1\"]",
  "[\"[MUI] Improved Field Skills\",\"[000] Settings.rb\",\"189e4521ecd0f9c75a89ec4ae1c3a012120a26d0f7f60ba1da1415dd0e875e06\"]",
  "[\"[MUI] Improved Field Skills\",\"[001] Field Skills.rb\",\"b8dbf0690bec823666762111fc3463d7ddaf1f4158ef05c39706d802ea73e082\"]",
  "[\"[MUI] Improved Field Skills\",\"[002] Party Skills.rb\",\"5e51ca0335e72bf8a69b251e7932f6ffa957458edc22fd5c205fd94cf5252be4\"]",
  "[\"Bag Screen w/int. Party\",\"Script.rb\",\"fcb331acf701e27a94795af6d22ba51167114badd603acef422e144e727703f3\"]",
  "[\"Bag Screen w/int. Party\",\"Settings.rb\",\"25ee5073bc4d0739e08ba2f2ef50b6cf9c9dea0dbf91490f12d29b2082f9e64f\"]",
  "[\"[MUI] Enhanced Pokemon UI\",\"[000] Settings.rb\",\"1cb7a7a18627b0dc07e4e77cdbd529a8a547aaafc3a6b08a77c28ba611758788\"]",
  "[\"[MUI] Enhanced Pokemon UI\",\"[001] Utilities.rb\",\"9ff6f911f871b08650c2315326ef01e941a5093abf29f6ea3d1f88071a5e0045\"]",
  "[\"[MUI] Enhanced Pokemon UI\",\"[002] Legacy Data.rb\",\"e0601b4309df136380f17091847e11600b3e3b39a380fc87fa8dbff42396149f\"]",
  "[\"[MUI] Enhanced Pokemon UI\",\"[003] Party UI.rb\",\"02fd716cbb8fe6443124dad8c9e62cee8136ee6034c9de23c6d9e0ab556c8335\"]",
  "[\"[MUI] Enhanced Pokemon UI\",\"[004] Storage UI.rb\",\"e95d9179d3d1af03ebbc3bbe7b0809b0546bac9921a2196a3e40380373657e5e\"]",
  "[\"[MUI] Enhanced Pokemon UI\",\"[005] Summary UI.rb\",\"226a882c449507d42d21e855d5aed9bd7f27c6e3ec32ece3fe09a3daeba0fb98\"]",
  "[\"Deluxe Battle Kit\",\"Settings.rb\",\"fa3574a22bd06e127d886c9616d26bf2d99ec3265ea6531e0cdebeb38c79ee73\"]",
  "[\"Deluxe Battle Kit\",\"[000] Essentials Patches/[000] Compiler.rb\",\"4c0f8b0f6fa92b2324d481d6f8f893842c2529c19782116d0c4c4288374689f1\"]",
  "[\"Deluxe Battle Kit\",\"[000] Essentials Patches/[001] Trainer Editor Refactor.rb\",\"8bcfb3253ce4ac6a0252a43e255a06b18f2fce1060ec7419b1ee2e6352b28e70\"]",
  "[\"Deluxe Battle Kit\",\"[000] Essentials Patches/[002] Damage Calc Refactor.rb\",\"e5569f6bb6a43a8186a60ba64e0dc02feae699141ae07297970d18f2d69d65a4\"]",
  "[\"Deluxe Battle Kit\",\"[000] Essentials Patches/[003] Command Menu Refactor.rb\",\"4c681a7dd040cd68be4989f47707888ac682517a2fe45816d533155183ce3fbe\"]",
  "[\"Deluxe Battle Kit\",\"[000] Essentials Patches/[004] Plugin Placholders.rb\",\"33c8e054ff55646123b55381964552725683651aba51a5f6181ab51d5dbbbbb9\"]",
  "[\"Deluxe Battle Kit\",\"[000] Essentials Patches/[005] Updated Effects.rb\",\"ef1d632533c6a62c2ed7555713e1954afc9a6c4cbafed9602a8db3dd5192dd72\"]",
  "[\"Deluxe Battle Kit\",\"[000] Essentials Patches/[006] Updated AI Effects.rb\",\"6b3bae9575717848c0e685ce1aac8e505f9b20aa19d8d76f4a7f759421a91143\"]",
  "[\"Deluxe Battle Kit\",\"[000] Essentials Patches/[007] Debug.rb\",\"b15391f0058468dfbf6a85756962fe50f3c941513871b2b368864693c285c19c\"]",
  "[\"Deluxe Battle Kit\",\"[001] Deluxe Utilities/[000] PBEffects Hash.rb\",\"6605bba406ddc5a88259769d4216be456a4fd84960ae2e5842b4622896d75fcd\"]",
  "[\"Deluxe Battle Kit\",\"[001] Deluxe Utilities/[001] Animation Utilities.rb\",\"2bdda2ca881db09ebd9a1ecab58cba4418e014892afd8a88b715c84dd5a2261d\"]",
  "[\"Deluxe Battle Kit\",\"[001] Deluxe Utilities/[002] Misc Utilities.rb\",\"00757781f7f542a2eba59ff523ec7d41742c4412e728cfebf77d27fd7a4f692d\"]",
  "[\"Deluxe Battle Kit\",\"[001] Deluxe Utilities/[003] Deluxe Battle Rules.rb\",\"2830e519fd63882a2f8d8985996791811952211f75b295b5aebcc9b7244ee8b8\"]",
  "[\"Deluxe Battle Kit\",\"[001] Deluxe Utilities/[004] Wild Boss Attributes.rb\",\"cd0d8c477b6695637accbea4c0da2645a470f9c5f1be2c4fa1245edf9e3f77ea\"]",
  "[\"Deluxe Battle Kit\",\"[001] Deluxe Utilities/[005] Mega Evolution.rb\",\"9c84264d281e3a82579e61094274030235639e3fad9df7cf5a8879235c47aff8\"]",
  "[\"Deluxe Battle Kit\",\"[001] Deluxe Utilities/[006] Primal Reversion.rb\",\"0adbce70d63561a3f9d969be3a3e83019e4e3812d6c702252de312e6d1d15f1c\"]",
  "[\"Deluxe Battle Kit\",\"[001] Deluxe Utilities/[007] Shadow Pokemon.rb\",\"aac939185d3965bf926872288e86dbf1ffe8c64aeedc6bc48f9bfc16e10b60b5\"]",
  "[\"Deluxe Battle Kit\",\"[001] Deluxe Utilities/[008] Databox Styles.rb\",\"8be532cd9bab765c508264950fcc632783bdfb45261efcd8ce7825c14e284baf\"]",
  "[\"Deluxe Battle Kit\",\"[002] Midbattle Scripting/[000] Midbattle Animations.rb\",\"e89f129a4da26f2bda1779f7310147d4d3e5eda0165c154c4ac1f5ce7e177a26\"]",
  "[\"Deluxe Battle Kit\",\"[002] Midbattle Scripting/[001] Midbattle Overwrites.rb\",\"5c984821e7ae18cbf32f414b441127e6f8e6a5d12fe3e3ac49ccb4a3f5e39938\"]",
  "[\"Deluxe Battle Kit\",\"[002] Midbattle Scripting/[002] Midbattle Triggers.rb\",\"1043d1b378d8ea82ab659cef8925a2968094dd467dc79804fd8a3e0bda388731\"]",
  "[\"Deluxe Battle Kit\",\"[002] Midbattle Scripting/[003] MidbattleScripts Module.rb\",\"8e080eba16b45289921c582d5b3bccad8d8c632b732762f5161819e2e9bc6f46\"]",
  "[\"Deluxe Battle Kit\",\"[002] Midbattle Scripting/[004] MidbattleHandlers Scripts.rb\",\"9836257e602f64d5c88b780314ff72e4ed51a131335516f75f1d268bb9e993c2\"]",
  "[\"[MUI] Improved Mementos\",\"[000] Settings.rb\",\"4897e80f3e07a5aaf56f29b083462a63c2c78384402bc32779f7ea2d3c8e1d73\"]",
  "[\"[MUI] Improved Mementos\",\"[001] PBS Files.rb\",\"50fc6776cc18c2b99614be72d65d72337bb7ce76f059a382ba107a6eb46c91f1\"]",
  "[\"[MUI] Improved Mementos\",\"[002] Debug.rb\",\"d1418e67069d0a949841df8be83367160726009a11187ebd009257b68c72fca8\"]",
  "[\"[MUI] Improved Mementos\",\"[003] Data.rb\",\"b221e2c193d22540f375ac86c44d09cfe0a84022ec390f0b0de09a4c5ab76411\"]",
  "[\"[MUI] Improved Mementos\",\"[004] Summary.rb\",\"12d1329a2e506b8e50210e3523fc8929a0badbf074e46ae606c0d6da22f5f689\"]",
  "[\"[MUI] Improved Mementos\",\"[005] Battle.rb\",\"8e4722fc7d53789b372b81807bffacbc70a74b9f225483c1fd9eb9a01a1b9882\"]",
  "[\"[MUI] Improved Mementos\",\"[006] Marks.rb\",\"faeaacb7cdab508e299a66c5a4a49bf8706a5cbb7488c7b6ff51c1aa8d1c4fdd\"]",
  "[\"[DBK] Animated Trainer Intros\",\"[000] Settings.rb\",\"5b77e946794ed71675d17c6055e550cc43c7574f4cf938918a4c1be6598b5a16\"]",
  "[\"[DBK] Animated Trainer Intros\",\"[001] Sprite Editor.rb\",\"6b67880f5838ecc3c4fe851b3d1dcde66affbcffc62f313f419f7f47481a1b91\"]",
  "[\"[DBK] Animated Trainer Intros\",\"[002] Trainer UI.rb\",\"c15a310a22cd15f9c5f9cac8cf3bbb02f9b286abb458eab29f69d39d89ebb3b4\"]",
  "[\"[DBK] Animated Trainer Intros\",\"[003] Game Data.rb\",\"1b1056bb487b16e0359567e4dd801502acf987c6b3e03c89b99594a34735d465\"]",
  "[\"[DBK] Animated Trainer Intros\",\"[004] Trainer Sprite.rb\",\"3a9ef1baaf93da17fc41c1659271216851e86bc3705c46eb1e661dee5c301c20\"]",
  "[\"[DBK] Animated Trainer Intros\",\"[005] Deluxe Bitmap.rb\",\"7be4ad545c636c70b0f25201171bee89ef427387ab60759188a36f1742aaa447\"]",
  "[\"[DBK] Animated Trainer Intros\",\"[006] Battle Scene.rb\",\"b71f88d258a2d4df64064191a73efec2f8a492aaf48200d085928c709f4b9ed1\"]",
  "[\"[DBK] Animated Trainer Intros\",\"[007] Battle Transitions.rb\",\"581cd54a6d35feb972b3785d77231658160f40fff83c1d111a7cb1c94a8373ce\"]",
  "[\"[DBK] Dynamax\",\"[000] Settings.rb\",\"ddbbd1cac589d81dbfcc97b3980485738326f016968b183ba258c0200c44345a\"]",
  "[\"[DBK] Dynamax\",\"[001] Debug.rb\",\"1a6ad3f6554b07db2cf5dc703993ebc75a83977def67a6c32d3b82179358dc6a\"]",
  "[\"[DBK] Dynamax\",\"[002] Editors.rb\",\"eb0fca18c30bc0a95c61d7b46ba485d3d285f116a8d5b1f4c45c3fa5272fdabc\"]",
  "[\"[DBK] Dynamax\",\"[003] UI.rb\",\"957f0a359456efdf42ce17489c8a00b1fcb147c763b4ebd824a5dfd09a1d61d1\"]",
  "[\"[DBK] Dynamax\",\"[004] Item Handlers.rb\",\"72170e300a702f9f1174985fb0eaa254e81131684acb3021cf125740b575a7b2\"]",
  "[\"[DBK] Dynamax\",\"[005] Species.rb\",\"0f9446d4bcf9fdf905aa2091de57a1a4f11531ee95971902c3238933fe599466\"]",
  "[\"[DBK] Dynamax\",\"[006] Pokemon.rb\",\"4ee98fc1d4f4124121451a2583c490df084b82b754275bb000bda8e150244ebb\"]",
  "[\"[DBK] Dynamax\",\"[007] Dynamax Mechanics.rb\",\"2f9933aba8595958571741aefeba8acd2e2a06b3d364ff3a41fc4fdfa52136a8\"]",
  "[\"[DBK] Dynamax\",\"[008] Dynamax Animations.rb\",\"dfe9e43ca86281d0ec7cef35be805862a9a4664031225a865a41076d0066d6a1\"]",
  "[\"[DBK] Dynamax\",\"[009] Updated Effects.rb\",\"94b4f897f8e70e17d9d32bc7cc0fa2488e9ea7e6bb518a1cc601485dbd47bbc7\"]",
  "[\"[DBK] Dynamax\",\"[010] Updated AI Effects.rb\",\"6b50e341b1aaf446e0190876c901f672fceea2bc94d0354be7b06ba6e2032541\"]",
  "[\"[DBK] Dynamax\",\"[011] Battle.rb\",\"8f424946b0dc83965209d04569d5757e3ca296bf3a52a7620ed660903125a02d\"]",
  "[\"[DBK] Dynamax\",\"[012] Battle_Battler.rb\",\"b090552639ec762dc9db7e2767f536421550a0d429201a7b3d3c94300106b1d6\"]",
  "[\"[DBK] Dynamax\",\"[013] Battle_Move.rb\",\"5c343d135e56e2e66cd6e3fdefc132db1c5169703ac323d5049434492d7aa1d9\"]",
  "[\"[DBK] Dynamax\",\"[014] MoveEffects.rb\",\"c7cd5941d5376a4b987103e8a7dcbeea6d9d681ff9014b52b07eb2fea6dd5105\"]",
  "[\"[DBK] Dynamax\",\"[015] MoveEffects_Gmax.rb\",\"a3bd6bfaf41a65e79cc41ad03d2aa56e6431490d20e63ead596328542275602f\"]",
  "[\"[DBK] Dynamax\",\"[016] Battle_AI.rb\",\"8f396248b271c123d237032cac5b7ea5834f1715db1184ec48ec0fec79814dc4\"]",
  "[\"[DBK] Dynamax\",\"[017] AI_MoveEffects.rb\",\"b1d6b885315ca6886ceb9347387abd891162104db99dd5cc2a0a8bb1635c25d0\"]",
  "[\"[DBK] Improved Item AI\",\"[000] Battle.rb\",\"124fa1f5ada7396e8df3cabe417b7e042922a729631f4d71187099ce6148766a\"]",
  "[\"[DBK] Improved Item AI\",\"[001] Battle_AI.rb\",\"96a179498ca0b6fec7a7b0a00b6eaab1f238e5d15a6bb3df25829128aab02935\"]",
  "[\"[DBK] Improved Item AI\",\"[002] OnPokemon Handlers.rb\",\"e33ee55d2545a6b3809e58701c1675e2f0ed137a7080f3a137bf284d0793e987\"]",
  "[\"[DBK] Improved Item AI\",\"[003] OnBattler Handlers.rb\",\"37e4acc0071f961d2b19812fd181292f2d28530cf195b4e735fef449830ae368\"]",
  "[\"[DBK] Improved Item AI\",\"[004] Direct Handlers.rb\",\"00cc067cd10e63cb8413a45ab2b1087a643d9411616ca86d65a6c7b93edfc03e\"]",
  "[\"[DBK] Terastallization\",\"[000] Settings.rb\",\"8cdef56187c2ccf233912ab49b2f445107260695ec613f96d2a354af2e9021ad\"]",
  "[\"[DBK] Terastallization\",\"[001] Debug.rb\",\"9bf35e3d5ff1f547dd2130c03547c9dddb9ac5e6b6829454bc18cad654262074\"]",
  "[\"[DBK] Terastallization\",\"[002] UI.rb\",\"63e8b0d50fb5d45d0b9e5f320113c6f15bc91fc498556cd401ce8753c1a19ad8\"]",
  "[\"[DBK] Terastallization\",\"[003] Item Handlers.rb\",\"3461b9c88594610854f0812501b7322f5407e712d16daa9bd559cac68780d0df\"]",
  "[\"[DBK] Terastallization\",\"[004] Deluxe Additions.rb\",\"295928b6f936f3020826f4f939fe18a00ffd84b9c8d338526b448f5f46ac04fb\"]",
  "[\"[DBK] Terastallization\",\"[005] Pokemon.rb\",\"6b04d33ff98dc6e78249fa419f335ec99f0b94163ec6fb2051dc1a2fcd33ca86\"]",
  "[\"[DBK] Terastallization\",\"[006] Battle.rb\",\"cc1c37bce96c0d76b610439ab324c3218ec4b07f97f1f1c6481c356da8d54ef3\"]",
  "[\"[DBK] Terastallization\",\"[007] Battle_Battler.rb\",\"56cca7459ccbc1c6c07e16b1295c003cfe0f231fa7829dc03d9c4d48e51c1a41\"]",
  "[\"[DBK] Terastallization\",\"[008] Battle_Move.rb\",\"354decd729530e6070321356e698f5e28790bc2c3fe90fbf18df42d43cf8c6d2\"]",
  "[\"[DBK] Terastallization\",\"[009] Battle_AI.rb\",\"8a44ae84a7c4fdf60e98e31028c81357cc8387ee9b2a60473e6f6529cbde8257\"]",
  "[\"[DBK] Terastallization\",\"[010] Battle_Scene.rb\",\"6f702875e3ebfd112816831a48489138770e8fea9fea5abd0f3f8c8f0b0b3842\"]",
  "[\"[DBK] Terastallization\",\"[011] Animations.rb\",\"5be2018f0ba724410cc3b18fd5c1a29d1203858fb6248cd7d4881d4eac23d965\"]",
  "[\"Tileset Rearranger\",\"TilesetRearranger_draw.rb\",\"1dd9b6a95d38545f95de763bf025a88b231c5b4fe5f9c4ddf4ca8d794b285b31\"]",
  "[\"Tileset Rearranger\",\"TilesetRearranger_help.rb\",\"835b914bd42a8e53c04ab7f37d75a45ace5708cc7ec9fb7f6df8528c16a1593f\"]",
  "[\"Tileset Rearranger\",\"TilesetRearranger_input.rb\",\"10f890f22c13c64cdabc535fab8d02bca052ea49ea72726c3c5a2c6652074d56\"]",
  "[\"Tileset Rearranger\",\"TilesetRearranger_load_and_save.rb\",\"cfc7d9c525506a5037f9475efc9cd46a876cdfb2a5eecd010f4d9431b8d1e1e3\"]",
  "[\"Tileset Rearranger\",\"TilesetRearranger_main.rb\",\"0f85e5a84131822ca686b20555eb7d86300c9391e1efda70a9b6401812e49abf\"]",
  "[\"Tileset Rearranger\",\"TilesetRearranger_menus.rb\",\"9594d95dd87fa52b8ffb594b443945a7fe5da54327fea36b61a0808acd9a8a29\"]",
  "[\"Tileset Rearranger\",\"TilesetRearranger_utilities.rb\",\"92539862b7ab03bd1b5bcefed1c64673bf6bb0768d043023096d67458648dc4d\"]",
  "[\"SpinTiles\",\"script.rb\",\"8c028d3c42798acdff0e0382ba20ee96c5e412d22c00af8f2f2e3db2fa740be2\"]",
  "[\"Regicode\",\"RegiCode.rb\",\"c1b92b29fdf2e946786dd6cd1c570c89602fccab1d07c0872e7764c18a9d8516\"]",
  "[\"[DBK] Animated Pokémon System\",\"[000] Settings.rb\",\"02e25f13389a8e5068a67fc3581dbc9bef41985ac8457f4a78836b11d28cab1c\"]",
  "[\"[DBK] Animated Pokémon System\",\"[001] Compiler.rb\",\"39b5b4043b271ac3b4e91d4e856beed4fb702414d3cc4c2aea63e9b513299087\"]",
  "[\"[DBK] Animated Pokémon System\",\"[002] Sprite Editor.rb\",\"10b7fd53cbaec6043ad0ab715f5a66e6cc193f5feea23a6cb6812fc63377a558\"]",
  "[\"[DBK] Animated Pokémon System\",\"[003] Pokemon UI.rb\",\"6c54116103306d489ba3600590f3000d5afca9f764b696ad1f8c713244a29977\"]",
  "[\"[DBK] Animated Pokémon System\",\"[004] Game Data.rb\",\"da1c9d44413514041b5f9cb5e26b97486a4b6c75a6bb25256ede3a8ec2f03fa7\"]",
  "[\"[DBK] Animated Pokémon System\",\"[005] Pokemon Sprites.rb\",\"51f95953b7e021f274ee9ecef5388ae46b435d0089c1e9557e8ceb9639927ad8\"]",
  "[\"[DBK] Animated Pokémon System\",\"[006] Battler Sprites.rb\",\"e8cbc58ecd2cd7e789e8c3be1367ff355bff8573146db80c22ed5311b7c63413\"]",
  "[\"[DBK] Animated Pokémon System\",\"[007] Substitute Doll.rb\",\"24e9b7eb3b726257712d48ddf12ae3195f85df19a29bbe773f188af86c6abc09\"]",
  "[\"[DBK] Animated Pokémon System\",\"[008] Deluxe Bitmap.rb\",\"c0d70ca1dad14a6f92307029d5c813094d4c91bd3a7dc72e9fd53218ca2e35a5\"]",
  "[\"[DBK] Animated Pokémon System\",\"[009] Deluxe Additions.rb\",\"c0e23b1995e2c58310073d66d6838fc44d049faaa299f001d065f0288d66d13c\"]",
  "[\"[DBK] Animated Pokémon System\",\"[010] Spinda Spots.rb\",\"73f45ab4a8c49d271b92bc60a6e47c1ef57f8ac9ff64386b772722f0d7cb6eb3\"]",
  "[\"Following Pokemon EX\",\"Configuration/000_Config.rb\",\"b057e3ed113ff9ea5bd52d123c8efcbbe4533e07c0f940919fb6db0057a595c0\"]",
  "[\"Following Pokemon EX\",\"Configuration/001_Dialogue_Item.rb\",\"288f5c5b0b77e3e9215de18a3832f9b60d525bcb3c826b98c77c07e181b4cb4a\"]",
  "[\"Following Pokemon EX\",\"Configuration/002_Dialogue_Specific.rb\",\"11cbc1f896f744e86ffdc0cf8e1aec0c5743b1d67ff3574c3adfc25efe5e2d4f\"]",
  "[\"Following Pokemon EX\",\"Configuration/003_Dialogue_Generic.rb\",\"55618047edb2eb157afe0dd632687931317462f1140c8327faeb87cfc560f303\"]",
  "[\"Following Pokemon EX\",\"Configuration/004_Disappearing.rb\",\"d33021e9cda1c5b347b38255ba5baa978589b247121321f3577f6eb6c4eb2c5a\"]",
  "[\"Following Pokemon EX\",\"Main Module/Event_Sprite Commands.rb\",\"331f83d20167b860462f95cb5905f17de2a623ccdfb3db7a5c31a41568e3b2bd\"]",
  "[\"Following Pokemon EX\",\"Main Module/Internal Commands.rb\",\"821a0e1843aba0a0dcac76decf2a7325dc853d5dd0c74ad2cda9a34653b747fa\"]",
  "[\"Following Pokemon EX\",\"Main Module/User Commands.rb\",\"c2221a93a3905b433b8915d920185c4afc74354697bc9077fbef5e7859658874\"]",
  "[\"Following Pokemon EX\",\"New Event Type/Event Sprite.rb\",\"0702ce3a1490e56c28d561ff8777b2de4cbd7639b1c463a3bf797b57acff0a7b\"]",
  "[\"Following Pokemon EX\",\"New Event Type/Following Event.rb\",\"81fdd03119b94e0d77a8221bda57968086da2987aea6f8289caad11b322d3ba8\"]",
  "[\"Following Pokemon EX\",\"New Event Type/Misc.rb\",\"ecde056f5c9523b3406d858ef0020a70c874ff56aa05768a3c75834d6d3d8855\"]",
  "[\"Following Pokemon EX\",\"Script Additions/Animations.rb\",\"71e6957457a0759352dbb014eb2cb5eec9b894ce016521bd92a7778bc9e137cd\"]",
  "[\"Following Pokemon EX\",\"Script Additions/Compatibility.rb\",\"a6747206719e109d36740ef50322cb0b172b13d73f8ce5c4dc414184750bf94e\"]",
  "[\"Following Pokemon EX\",\"Script Additions/Field Moves.rb\",\"198f8daad58b18afd5a0475b4fc7d884387210704ca28ec21bb71c5128eceb71\"]",
  "[\"Following Pokemon EX\",\"Script Additions/Map Transfer.rb\",\"bf1d0e6b78d94a063521f5556faa3bb383219ffdb1736d1a1174764fb31a6042\"]",
  "[\"Following Pokemon EX\",\"Script Additions/Refresh.rb\",\"2d90a302fcbeb96831105948279eeac52be9300dabe47e52c2eb92579d8717a3\"]",
  "[\"Following Pokemon EX\",\"Script Additions/SuperShinyOverride.rb\",\"05e64f0272eb1a077a3602c4f9847f1ccbb8c10b89a60f8a10bb3490b0b5b333\"]",
  "[\"Delta Speed Up\",\"_Main_Script.rb\",\"b068447ba3b2e3545cc1deda7e0adc55ca965dc734be62244eb6af7c4fa2ed8e\"]",
  "[\"[DBK] Enhanced Battle UI\",\"[000] Main.rb\",\"1b13242030a70edb58353c6941a5711313ba2e140d4ac6f01a47e6c8c9c5d4ef\"]",
  "[\"[DBK] Enhanced Battle UI\",\"[001] Outline Utilities.rb\",\"f20180d2cdf034061020bd8350c9e287cdd37390f2cbbad9cd6c373670f0d824\"]",
  "[\"[DBK] Enhanced Battle UI\",\"[002] Selection Menu.rb\",\"9fa6dfff4cdd04cbad946f1d52939724d910e12a803fbffda7ec28bcc407197d\"]",
  "[\"[DBK] Enhanced Battle UI\",\"[003] Battler Info UI.rb\",\"cbf6e763735e2cddd34f84621e73aa9a9b1bc8476db69912497025a2e7456cd7\"]",
  "[\"[DBK] Enhanced Battle UI\",\"[004] Move Info UI.rb\",\"ac27d2648457c5be5dc82e44a145758826338761c8b1b4ee671febf794e91e30\"]",
  "[\"[DBK] Enhanced Battle UI\",\"[005] Poke Ball UI.rb\",\"ba12ffc3d2ee7c4f0aec0714aa53594a888d08f6d6387bdb11effaf0ec353cc5\"]",
];
