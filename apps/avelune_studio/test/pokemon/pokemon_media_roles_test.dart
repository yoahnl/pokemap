import 'dart:async';
import 'dart:typed_data';

import 'package:avelune_studio/features/pokemon/application/pokemon_media_editing_session.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_controller.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';

Future<(PokemonWorkspaceController, _MediaPort)> _open() async {
  final port = _MediaPort();
  final controller = PokemonWorkspaceController(port, changed: () {});
  addTearDown(controller.dispose);
  await controller.load();
  expect(await controller.selectSpecies('bulbasaur'), isTrue);
  return (controller, port);
}

PokemonMediaEditingSession _session(
  PokemonWorkspaceController? Function() current,
) {
  final session = PokemonMediaEditingSession(current: current);
  addTearDown(session.dispose);
  return session;
}

void main() {
  test(
    'media roles preserve checked file states without inventing association',
    () async {
      final (controller, port) = await _open();
      final session = _session(() => controller);
      for (final role in PokemonMediaEditingSession.roles) {
        final probe = session.probeRole(role);
        if (role == 'icon' || role == 'frontStatic') {
          expect(await probe, PokemonMediaFileStatus.present);
        } else if (role == 'party') {
          expect(await probe, PokemonMediaFileStatus.missing);
        } else {
          expect(probe, isNull);
        }
      }
      expect(PokemonMediaEditingSession.roles, contains('overworldShiny'));
      expect(
        pokemonMediaRoleLabel('overworldShiny'),
        'Monde extérieur chromatique',
      );
      expect(port.probed, {'a/icon.png', 'a/party.png', 'a/front.png'});
    },
  );

  test('an associated role cannot start a replacement picker', () async {
    final (controller, _) = await _open();
    final session = _session(() => controller);
    expect(session.path, 'a/icon.png');
    expect(session.canImportPng, isFalse);
    var picks = 0;
    expect(
      await session.choosePng(() async {
        picks++;
        return '/source/icon.png';
      }),
      isFalse,
    );
    expect(picks, 0);
    expect(session.path, 'a/icon.png');
    expect(controller.hasPendingChanges, isFalse);
  });

  test(
    'a missing file retains its association and cannot be overwritten',
    () async {
      final (controller, _) = await _open();
      final session = _session(() => controller);
      expect(session.selectRole('party'), isTrue);
      expect(session.path, 'a/party.png');
      expect(await session.probeRole('party'), PokemonMediaFileStatus.missing);
      expect(session.associated, isTrue);
      expect(session.canImportPng, isFalse);
      expect(pokemonMediaRoleLabel(session.role), 'Image d’équipe');
    },
  );

  test(
    'an empty supported role remains importable with its localized label',
    () async {
      final (controller, _) = await _open();
      final session = _session(() => controller);
      expect(session.selectRole('portrait'), isTrue);
      expect(session.associated, isFalse);
      expect(session.canImportPng, isTrue);
      expect(pokemonMediaRoleLabel(session.role), 'Portrait');
      expect(session.selectRole('frontStatic'), isTrue);
      expect(session.canImportPng, isFalse);
    },
  );

  test(
    'successive path edits remain in the same selected role and support undo',
    () async {
      final (controller, _) = await _open();
      final session = _session(() => controller);
      session.selectRole('portrait');
      session.setPath('a');
      expect(session.role, 'portrait');
      expect(session.path, 'a');
      session.setPath('ab');
      expect(session.path, 'ab');
      expect(session.canImportPng, isFalse);
      controller.undo();
      expect(session.path, 'a');
      controller.redo();
      expect(session.path, 'ab');
    },
  );

  test('role labels are localized for every supported role', () {
    for (final role in PokemonMediaEditingSession.roles) {
      expect(pokemonMediaRoleLabel(role), isNot(role));
    }
    expect(pokemonMediaRoleLabel('icon'), 'Icône');
    expect(pokemonMediaRoleLabel('party'), 'Image d’équipe');
  });

  test(
    'forms combine species and media keys with a deterministic fallback',
    () async {
      final (controller, _) = await _open();
      controller.edit(PokemonDocumentFamily.media, (json) {
        (json['variants'] as Map)['alternate'] = <String, dynamic>{};
      });
      final session = _session(() => controller);
      expect(session.formIds, ['base', 'alternate']);
      expect(session.formId, 'base');
      session.setDefaultForm('alternate');
      expect(session.formId, 'alternate');
      expect(session.selectForm('base'), isTrue);
      expect(session.formId, 'base');
      expect(session.selectForm('unknown'), isFalse);
      expect(session.formId, 'base');
      expect(session.selectRole('unknown'), isFalse);
      expect(session.role, 'icon');
      expect(() => session.formIds.add('another'), throwsUnsupportedError);
    },
  );

  test(
    'probes are cached per owner and lookup failures stay explicit',
    () async {
      final (controller, port) = await _open();
      final (nextController, nextPort) = await _open();
      var current = controller;
      final session = _session(() => current);
      final first = session.probeRole('icon');
      expect(session.probeRole('icon'), same(first));
      expect(await first, PokemonMediaFileStatus.present);
      session.selectRole('portrait');
      current = nextController;
      nextPort.failProbe = true;
      expect(session.role, 'icon');
      final next = session.probeRole('icon');
      expect(next, isNot(same(first)));
      expect(await next, PokemonMediaFileStatus.inaccessible);
      expect(port.probed, {'a/icon.png'});
      expect(nextPort.probed, {'a/icon.png'});
    },
  );

  test('a picker cannot publish after its selected role changes or the session closes', () async {
    final (controller, _) = await _open();
    final session = _session(() => controller);
    session.selectRole('portrait');
    final picker = Completer<String?>();
    final choosing = session.choosePng(() => picker.future);
    expect(session.busy, isTrue);
    session.selectRole('icon');
    picker.complete('/source/portrait.png');
    expect(await choosing, isFalse);
    expect(session.path, 'a/icon.png');
    session.selectRole('portrait');
    final latePicker = Completer<String?>();
    final lateChoosing = session.choosePng(() => latePicker.future);
    session.dispose();
    latePicker.complete('/source/portrait.png');
    expect(await lateChoosing, isFalse);
    expect(session.probeRole('portrait'), isNull);
    expect(session.canImportPng, isFalse);
    expect(controller.hasPendingChanges, isFalse);
  });

  test(
    'image and thumbnail reads reuse a slot until their dependency changes',
    () async {
      final (controller, port) = await _open();
      final (_, nextPort) = await _open();
      final slot = PokemonMediaReadSlot();
      final image = slot.image(port, 'a/icon.png');
      expect(slot.image(port, 'a/icon.png'), same(image));
      await image;
      await slot.image(port, 'a/portrait.png');
      await slot.image(nextPort, 'a/portrait.png');
      expect(port.images, ['a/icon.png', 'a/portrait.png']);
      expect(nextPort.images, ['a/portrait.png']);
      final entry = controller.index!.entries.single;
      final thumbnail = slot.thumbnail(port: port, entry: entry);
      expect(slot.thumbnail(port: port, entry: entry), same(thumbnail));
      await thumbnail;
      await slot.thumbnail(port: port, entry: entry, mediaRevision: 1);
      await slot.thumbnail(port: nextPort, entry: entry, mediaRevision: 1);
      expect(port.thumbnails, ['bulbasaur', 'bulbasaur']);
      expect(nextPort.thumbnails, ['bulbasaur']);
    },
  );
}

final class _MediaPort implements PokemonWorkspacePort {
  final probed = <String>{};
  final images = <String>[];
  final thumbnails = <String>[];
  bool failProbe = false;

  @override
  Future<PokemonWorkspaceIndex> loadIndex() async => PokemonWorkspaceIndex(
    enabled: true,
    entries: const [
      PokemonSpeciesSummary(
        id: 'bulbasaur',
        name: 'Bulbizarre',
        nationalDex: 1,
        generation: 1,
        types: [],
        formIds: ['base'],
        formId: 'base',
        mediaRelativePath: 'media/bulbasaur.json',
        enabled: true,
        relativePath: 'bulbasaur.json',
      ),
    ],
    moves: const PokemonMovesCatalogView(entries: [], relativePath: ''),
    types: [],
    items: {},
  );

  @override
  Future<PokemonSpeciesBundle> loadSpecies(PokemonSpeciesSummary entry) async =>
      PokemonSpeciesBundle(
        species: PokemonDocumentSource(
          family: PokemonDocumentFamily.species,
          relativePath: entry.relativePath,
          bytes: null,
          document: {
            'id': entry.id,
            'refs': {'media': 'bulbasaur'},
          },
        ),
        learnset: null,
        evolution: null,
        media: PokemonDocumentSource(
          family: PokemonDocumentFamily.media,
          relativePath: 'media/bulbasaur.json',
          bytes: null,
          document: {
            'speciesId': 'bulbasaur',
            'defaultFormId': 'base',
            'variants': {
              'base': {
                'icon': 'a/icon.png',
                'party': 'a/party.png',
                'frontStatic': 'a/front.png',
              },
            },
          },
        ),
      );

  @override
  Future<PokemonMediaFileStatus> probeMedia(String relativePath) async {
    probed.add(relativePath);
    if (failProbe) throw StateError('inaccessible');
    return relativePath == 'a/party.png'
        ? PokemonMediaFileStatus.missing
        : PokemonMediaFileStatus.present;
  }

  @override
  Future<Uint8List?> loadImage(String relativePath) async {
    images.add(relativePath);
    return Uint8List.fromList([images.length]);
  }

  @override
  Future<Uint8List?> loadThumbnail(PokemonSpeciesSummary entry) async {
    thumbnails.add(entry.id);
    return Uint8List.fromList([thumbnails.length]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
