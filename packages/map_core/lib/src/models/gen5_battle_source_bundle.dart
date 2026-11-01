import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'battle_recipe_json.dart';

const gen5BattleBundleAssetNames = <String>[
  'front.png',
  'back.png',
  'front_animations.nanr.lz11',
  'back_animations.nanr.lz11',
  'front_cells.ncer',
  'back_cells.ncer',
  'front_multi_cells.nmcr',
  'back_multi_cells.nmcr',
  'front_multi_animations.nmar',
  'back_multi_animations.nmar',
  'front_info.bin',
  'back_info.bin',
  'normal.pal',
  'shiny.pal',
];

const gen5BattleSourceBindingMaxBytes = 8192;
const gen5BattleSourceBundleMaxBytes = 20 * 1024 * 1024;

final class Gen5BattleSourceBundle {
  Gen5BattleSourceBundle._({
    required this.species,
    required this.nationalDex,
    required this.release,
    required this.sourceRepository,
    required this.sourceRevision,
    required this.sourceDirectory,
    required this.reconstruction,
    required this.redistributionStatus,
    required this.assets,
  });

  factory Gen5BattleSourceBundle({
    required String species,
    required int nationalDex,
    required String release,
    required String sourceRepository,
    required String sourceRevision,
    required String sourceDirectory,
    required String reconstruction,
    required String redistributionStatus,
    required Map<String, Uint8List> assets,
  }) {
    if (!_speciesPattern.hasMatch(species) ||
        nationalDex < 1 ||
        nationalDex > 649 ||
        !_releasePattern.hasMatch(release) ||
        sourceRepository != 'fuddlesworth/pokebw2' ||
        !_revisionPattern.hasMatch(sourceRevision) ||
        sourceDirectory != 'res/pokemon/${species.replaceAll('-', '_')}' ||
        reconstruction.isEmpty ||
        reconstruction.length > 100 ||
        redistributionStatus.isEmpty ||
        redistributionStatus.length > 100 ||
        assets.length != gen5BattleBundleAssetNames.length ||
        gen5BattleBundleAssetNames.any((name) => !assets.containsKey(name))) {
      throw const FormatException('Invalid Gen 5 battle bundle identity');
    }
    final copied = <String, Uint8List>{};
    for (final name in gen5BattleBundleAssetNames) {
      final value = assets[name]!;
      if (value.isEmpty || value.length > _maxAssetBytes) {
        throw FormatException('Invalid Gen 5 bundle asset: $name');
      }
      copied[name] = Uint8List.fromList(value).asUnmodifiableView();
    }
    return Gen5BattleSourceBundle._(
      species: species,
      nationalDex: nationalDex,
      release: release,
      sourceRepository: sourceRepository,
      sourceRevision: sourceRevision,
      sourceDirectory: sourceDirectory,
      reconstruction: reconstruction,
      redistributionStatus: redistributionStatus,
      assets: Map.unmodifiable(copied),
    );
  }

  static const _maxAssetBytes = 1024 * 1024;
  static final _speciesPattern = RegExp(r'^[a-z0-9][a-z0-9-]{0,99}$');
  static final _releasePattern = RegExp(r'^[a-z0-9][a-z0-9-]{0,127}$');
  static final _revisionPattern = RegExp(r'^[a-f0-9]{40}$');
  static final _shaPattern = RegExp(r'^[a-f0-9]{64}$');

  final String species;
  final int nationalDex;
  final String release;
  final String sourceRepository;
  final String sourceRevision;
  final String sourceDirectory;
  final String reconstruction;
  final String redistributionStatus;
  final Map<String, Uint8List> assets;

  Uint8List encode() {
    final document = <String, Object?>{
      'kind': 'avelune.gen5-battle-source-bundle',
      'schemaVersion': 1,
      'game': 'black2-white2',
      'scope': 'default-form',
      'species': species,
      'nationalDex': nationalDex,
      'release': release,
      'reconstruction': reconstruction,
      'source': {
        'repository': sourceRepository,
        'revision': sourceRevision,
        'directory': sourceDirectory,
        'redistributionStatus': redistributionStatus,
      },
      'assets': {
        for (final name in gen5BattleBundleAssetNames)
          name: {
            'encoding': 'base64',
            'size': assets[name]!.length,
            'sha256': sha256.convert(assets[name]!).toString(),
            'data': base64.encode(assets[name]!),
          },
      },
    };
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(document)));
    if (bytes.length > gen5BattleSourceBundleMaxBytes) {
      throw const FormatException('Gen 5 battle bundle exceeds limit');
    }
    return bytes;
  }

  static Gen5BattleSourceBundle decode(
    Uint8List bytes, {
    required String expectedSha256,
    required String expectedSpecies,
    required int expectedNationalDex,
    required String expectedRelease,
    required String expectedSourceRevision,
  }) {
    if (bytes.isEmpty ||
        bytes.length > gen5BattleSourceBundleMaxBytes ||
        !_shaPattern.hasMatch(expectedSha256) ||
        sha256.convert(bytes).toString() != expectedSha256) {
      throw const FormatException('Invalid Gen 5 battle bundle digest or size');
    }
    final raw = decodeBoundedBattleJson(
      bytes,
      maxDepth: 8,
      label: 'Gen 5 bundle',
    );
    if (raw is! Map ||
        !_keys(raw, const {
          'kind',
          'schemaVersion',
          'game',
          'scope',
          'species',
          'nationalDex',
          'release',
          'reconstruction',
          'source',
          'assets',
        }) ||
        raw['kind'] != 'avelune.gen5-battle-source-bundle' ||
        raw['schemaVersion'] is! int ||
        raw['schemaVersion'] != 1 ||
        raw['game'] != 'black2-white2' ||
        raw['scope'] != 'default-form' ||
        raw['species'] != expectedSpecies ||
        raw['nationalDex'] is! int ||
        raw['nationalDex'] != expectedNationalDex ||
        raw['release'] != expectedRelease ||
        raw['reconstruction'] is! String) {
      throw const FormatException('Invalid Gen 5 battle bundle document');
    }
    final source = raw['source'];
    final entries = raw['assets'];
    if (source is! Map ||
        !_keys(source, const {
          'repository',
          'revision',
          'directory',
          'redistributionStatus',
        }) ||
        source['repository'] is! String ||
        source['revision'] != expectedSourceRevision ||
        source['directory'] is! String ||
        source['redistributionStatus'] is! String ||
        entries is! Map ||
        entries.length != gen5BattleBundleAssetNames.length) {
      throw const FormatException(
        'Invalid Gen 5 battle bundle provenance or assets',
      );
    }
    final assets = <String, Uint8List>{};
    for (final name in gen5BattleBundleAssetNames) {
      final item = entries[name];
      if (item is! Map ||
          !_keys(item, const {'encoding', 'size', 'sha256', 'data'})) {
        throw FormatException('Invalid Gen 5 bundle asset: $name');
      }
      final size = item['size'];
      final digest = item['sha256'];
      final data = item['data'];
      if (item['encoding'] != 'base64' ||
          size is! int ||
          size < 1 ||
          size > _maxAssetBytes ||
          digest is! String ||
          !_shaPattern.hasMatch(digest) ||
          data is! String ||
          data.length != ((size + 2) ~/ 3) * 4) {
        throw FormatException('Invalid Gen 5 bundle asset metadata: $name');
      }
      final decoded = base64.decode(data);
      if (decoded.length != size ||
          base64.encode(decoded) != data ||
          sha256.convert(decoded).toString() != digest) {
        throw FormatException('Invalid Gen 5 bundle asset content: $name');
      }
      assets[name] = decoded;
    }
    return Gen5BattleSourceBundle(
      species: expectedSpecies,
      nationalDex: expectedNationalDex,
      release: expectedRelease,
      sourceRepository: source['repository'] as String,
      sourceRevision: expectedSourceRevision,
      sourceDirectory: source['directory'] as String,
      reconstruction: raw['reconstruction'] as String,
      redistributionStatus: source['redistributionStatus'] as String,
      assets: assets,
    );
  }

  static bool _keys(Map value, Set<String> keys) =>
      value.length == keys.length &&
      value.keys.every((key) => keys.contains(key));
}

final class Gen5BattleSourceBinding {
  const Gen5BattleSourceBinding._({
    required this.projectSpeciesId,
    required this.sourceSpecies,
    required this.nationalDex,
    required this.release,
    required this.sourceRevision,
    required this.bundleSha256,
  });

  factory Gen5BattleSourceBinding.fromBundle({
    required String projectSpeciesId,
    required int projectNationalDex,
    required Gen5BattleSourceBundle bundle,
  }) {
    _projectKey(projectSpeciesId);
    if (projectNationalDex != bundle.nationalDex) {
      throw const FormatException('Gen 5 project species number mismatch');
    }
    return Gen5BattleSourceBinding._(
      projectSpeciesId: projectSpeciesId,
      sourceSpecies: bundle.species,
      nationalDex: bundle.nationalDex,
      release: bundle.release,
      sourceRevision: bundle.sourceRevision,
      bundleSha256: sha256.convert(bundle.encode()).toString(),
    );
  }

  final String projectSpeciesId;
  final String sourceSpecies;
  final int nationalDex;
  final String release;
  final String sourceRevision;
  final String bundleSha256;

  static String bindingPathFor(String projectSpeciesId) =>
      'data/pokemon/gen5_battle_sources/bindings/${_projectKey(projectSpeciesId)}.json';

  String get bindingPath => bindingPathFor(projectSpeciesId);

  String get bundlePath =>
      'data/pokemon/gen5_battle_sources/blobs/${_projectKey(projectSpeciesId)}/$bundleSha256.json';

  Uint8List encode() => Uint8List.fromList(
    utf8.encode(
      jsonEncode({
        'kind': 'avelune.gen5-battle-source-binding',
        'schemaVersion': 1,
        'projectSpeciesId': projectSpeciesId,
        'species': sourceSpecies,
        'nationalDex': nationalDex,
        'release': release,
        'sourceRevision': sourceRevision,
        'bundleSha256': bundleSha256,
      }),
    ),
  );

  static Gen5BattleSourceBinding decode(
    Uint8List bytes, {
    required String expectedSha256,
    required String expectedProjectSpeciesId,
    required int expectedProjectNationalDex,
  }) {
    _projectKey(expectedProjectSpeciesId);
    if (bytes.isEmpty ||
        bytes.length > gen5BattleSourceBindingMaxBytes ||
        !Gen5BattleSourceBundle._shaPattern.hasMatch(expectedSha256) ||
        sha256.convert(bytes).toString() != expectedSha256) {
      throw const FormatException(
        'Invalid Gen 5 source binding digest or size',
      );
    }
    final raw = decodeBoundedBattleJson(
      bytes,
      maxDepth: 4,
      label: 'Gen 5 binding',
    );
    if (raw is! Map ||
        !Gen5BattleSourceBundle._keys(raw, const {
          'kind',
          'schemaVersion',
          'projectSpeciesId',
          'species',
          'nationalDex',
          'release',
          'sourceRevision',
          'bundleSha256',
        }) ||
        raw['kind'] != 'avelune.gen5-battle-source-binding' ||
        raw['schemaVersion'] is! int ||
        raw['schemaVersion'] != 1 ||
        raw['projectSpeciesId'] != expectedProjectSpeciesId ||
        raw['species'] is! String ||
        !Gen5BattleSourceBundle._speciesPattern.hasMatch(
          raw['species'] as String,
        ) ||
        raw['nationalDex'] is! int ||
        (raw['nationalDex'] as int) < 1 ||
        (raw['nationalDex'] as int) > 649 ||
        raw['nationalDex'] != expectedProjectNationalDex ||
        raw['release'] is! String ||
        !Gen5BattleSourceBundle._releasePattern.hasMatch(
          raw['release'] as String,
        ) ||
        raw['sourceRevision'] is! String ||
        !Gen5BattleSourceBundle._revisionPattern.hasMatch(
          raw['sourceRevision'] as String,
        ) ||
        raw['bundleSha256'] is! String ||
        !Gen5BattleSourceBundle._shaPattern.hasMatch(
          raw['bundleSha256'] as String,
        )) {
      throw const FormatException('Invalid Gen 5 source binding');
    }
    return Gen5BattleSourceBinding._(
      projectSpeciesId: expectedProjectSpeciesId,
      sourceSpecies: raw['species'] as String,
      nationalDex: raw['nationalDex'] as int,
      release: raw['release'] as String,
      sourceRevision: raw['sourceRevision'] as String,
      bundleSha256: raw['bundleSha256'] as String,
    );
  }

  Gen5BattleSourceBundle resolve(
    Uint8List bytes, {
    required String expectedProjectSpeciesId,
    required int expectedProjectNationalDex,
  }) {
    if (projectSpeciesId != expectedProjectSpeciesId ||
        nationalDex != expectedProjectNationalDex) {
      throw const FormatException('Gen 5 binding project identity mismatch');
    }
    return Gen5BattleSourceBundle.decode(
      bytes,
      expectedSha256: bundleSha256,
      expectedSpecies: sourceSpecies,
      expectedNationalDex: nationalDex,
      expectedRelease: release,
      expectedSourceRevision: sourceRevision,
    );
  }

  static String _projectKey(String value) {
    if (value.isEmpty ||
        value.length > 512 ||
        value.trim() != value ||
        utf8.decode(utf8.encode(value)) != value) {
      throw const FormatException('Invalid project species identity');
    }
    return sha256.convert(utf8.encode(value)).toString();
  }
}
