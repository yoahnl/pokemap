import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/src/domains/gameplay/pokemon_sprite_source_catalog.dart';
import 'package:map_authoring/src/ports/project_file_reader.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

const _families = [
  (
    id: 'pokemon-home',
    path: 'src/minisprites/pokemon/home',
    role: 'icon,party',
    sampling: 'linear',
    style: 'home-miniature',
  ),
  (
    id: 'pokemon-gen9',
    path: 'src/previews/gen9',
    role: 'portrait',
    sampling: 'linear',
    style: 'rendered-3d',
  ),
  (
    id: 'items',
    path: 'src/minisprites/items',
    role: 'item-image',
    sampling: 'nearest',
    style: 'pixel-art',
  ),
];

Future<void> main(List<String> arguments) async {
  try {
    if (arguments.length < 2 || arguments.first != '--source') {
      throw const FormatException(
          'Usage: menu_sprite_inventory --source <directory> '
          '[--project <directory>] [--output <file>] [--editor-catalog <file>]');
    }
    final options = <String, String>{};
    for (var index = 0; index < arguments.length; index += 2) {
      if (index + 1 >= arguments.length ||
          !const {'--source', '--project', '--output', '--editor-catalog'}
              .contains(arguments[index]) ||
          options.containsKey(arguments[index])) {
        throw const FormatException('Invalid or repeated option.');
      }
      options[arguments[index]] = arguments[index + 1];
    }
    final root = await Directory(options['--source']!).resolveSymbolicLinks();
    Future<List<int>> readSource(String path) async {
      final file = File(p.join(root, path));
      final resolved = await file.resolveSymbolicLinks();
      if (!p.isWithin(root, resolved)) {
        throw const FormatException('Source escapes its declared root.');
      }
      return file.readAsBytes();
    }

    final speciesBytes = await readSource('data/species.json');
    final readmeBytes = await readSource('README.md');
    final catalog = PokemonSpriteSourceCatalog.fromJson(
        jsonDecode(utf8.decode(speciesBytes)) as Map<String, dynamic>);
    final identities = {for (final entry in catalog.identities) entry.id};
    final assets = <Map<String, Object?>>[];
    for (final family in _families) {
      final files = await Directory(p.join(root, family.path))
          .list(followLinks: false)
          .where((entry) => entry is File && entry.path.endsWith('.png'))
          .cast<File>()
          .toList();
      files.sort((a, b) => a.path.compareTo(b.path));
      for (final file in files) {
        final relative =
            p.relative(file.path, from: root).split(p.separator).join('/');
        final bytes = await readSource(relative);
        final decoded = image.decodePng(Uint8List.fromList(bytes));
        if (decoded == null) throw FormatException('Invalid PNG: $relative');
        final filename = p.basenameWithoutExtension(file.path);
        final match = RegExp(r'^(s\d+)(.*)$').firstMatch(filename);
        final id = match?.group(1);
        assets.add({
          'path': relative,
          'sha256': sha256.convert(bytes).toString(),
          'bytes': bytes.length,
          'width': decoded.width,
          'height': decoded.height,
          'alphaChannel': decoded.hasAlpha,
          'transparent':
              decoded.any((pixel) => pixel.a < pixel.maxChannelValue),
          'family': family.id,
          'sourceId': id != null && identities.contains(id) ? id : null,
          'variantSuffix': match?.group(2),
          'roles': family.role.split(','),
          'sampling': family.sampling,
          'style': family.style,
        });
      }
    }
    final byPath = {for (final asset in assets) asset['path']: asset};
    final aliases = <Map<String, Object?>>[];
    for (final entry in catalog.identities) {
      final homeId = PokemonSpriteSourceCatalog.homeMediaIdentity(entry.id);
      if (homeId == entry.id) continue;
      final original = byPath['src/previews/gen9/${entry.id}.png'];
      final target = byPath['src/previews/gen9/$homeId.png'];
      if (original == null ||
          target == null ||
          original['sha256'] != target['sha256']) {
        throw FormatException('Unverified media alias: ${entry.id}');
      }
      aliases.add({
        'sourceId': entry.id,
        'homeSourceId': homeId,
        'reason': 'exact-gen9-bytes-and-explicit-source-form-table',
        'evidenceSha256': original['sha256'],
      });
    }
    List<Map<String, Object?>>? qualification;
    final qualificationInputSha256 = <String, String>{};
    final project = options['--project'];
    if (project != null) {
      final projectRoot = await Directory(project).resolveSymbolicLinks();
      final manifestFile = File(p.join(projectRoot, 'project.json'));
      qualificationInputSha256['project.json'] =
          sha256.convert(await manifestFile.readAsBytes()).toString();
      final manifest = ProjectManifest.fromJson(
          jsonDecode(await manifestFile.readAsString())
              as Map<String, dynamic>);
      Future<List<Map<String, dynamic>>> documents(String directory) async {
        validateProjectRelativePath(directory);
        final folder = Directory(p.join(projectRoot, directory));
        if (!await folder.exists()) return [];
        final result = <Map<String, dynamic>>[];
        await for (final entry in folder.list(followLinks: false)) {
          if (entry is! File || !entry.path.endsWith('.json')) continue;
          final resolved = await entry.resolveSymbolicLinks();
          if (!p.isWithin(projectRoot, resolved)) {
            throw const FormatException('Project document escapes its root.');
          }
          qualificationInputSha256[p
                  .relative(entry.path, from: projectRoot)
                  .split(p.separator)
                  .join('/')] =
              sha256.convert(await entry.readAsBytes()).toString();
          result.add(
              jsonDecode(await entry.readAsString()) as Map<String, dynamic>);
        }
        return result;
      }

      final species = (await documents(manifest.pokemon.speciesDir))
          .map(PokemonSpeciesFile.fromJson)
          .toList();
      final media = (await documents(manifest.pokemon.mediaDir))
          .map(PokemonMediaFile.fromJson)
          .toList();
      final byMediaId = {for (final entry in media) entry.speciesId: entry};
      qualification = catalog.qualify(
        species: species,
        media: {
          for (final entry in species)
            if (byMediaId[entry.refs.media] != null)
              entry.id: byMediaId[entry.refs.media]!,
        },
      );
    }
    final document = {
      'schemaVersion': 1,
      'sourcePack': 'pokemon-showdown-sprites',
      'speciesTableSha256': sha256.convert(speciesBytes).toString(),
      'readmeSha256': sha256.convert(readmeBytes).toString(),
      'provenance': {
        'upstream':
            'Smogon / Pokemon Showdown sprite repository (source README)',
        'sourceVersion': 'content-fingerprints-no-local-git-metadata',
        'imageRights':
            'Nintendo, Game Freak, The Pokemon Company and credited contributors; see source README',
        'codeLicense': 'MIT applies to source code, not a grant for all images',
        'redistribution':
            'Respect original rights and contributor terms; import explicitly into the selected game only',
      },
      'identities': catalog.identities.map((entry) => entry.toJson()).toList(),
      'mediaAliases': aliases,
      'assets': assets,
      'unsupportedMenuSlots': ['shiny-thumbnail', 'female-thumbnail'],
      if (qualification != null) 'qualification': qualification,
      if (qualification != null)
        'qualificationInputSha256': qualificationInputSha256,
      'summary': {
        'nationalSpecies':
            catalog.identities.map((entry) => entry.nationalDex).toSet().length,
        'sourceForms': catalog.identities.length,
        'assets': assets.length,
        if (qualification != null)
          'matchedForms': qualification
              .where((entry) => entry['decision'] == 'matched')
              .length,
        if (qualification != null)
          'unsupportedForms': qualification
              .where((entry) => entry['decision'] == 'unsupported')
              .length,
      },
    };
    final json = '${const JsonEncoder.withIndent('  ').convert(document)}\n';
    if (options['--editor-catalog'] case final String output) {
      final editorCatalog = {
        'schemaVersion': 1,
        'repository': 'https://github.com/smogon/sprites',
        'revision': 'ded9d487d0531f8eb749c2d495e54e6f4bd2d5bf',
        'species': jsonDecode(utf8.decode(speciesBytes)),
        'provenance': document['provenance'],
        'assets': {
          for (final asset in assets)
            if (asset['family'] != 'items' && asset['variantSuffix'] == '')
              asset['path']! as String: {
                'sha256': asset['sha256'],
                'bytes': asset['bytes'],
              },
        },
      };
      await File(output).parent.create(recursive: true);
      await File(output).writeAsString('${jsonEncode(editorCatalog)}\n');
    }
    if (options['--output'] case final String output) {
      await File(output).writeAsString(json);
      stdout.writeln(jsonEncode(document['summary']));
    } else {
      stdout.write(json);
    }
  } on Object catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  }
}
