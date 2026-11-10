import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

final class _Transport implements PokemonBoundedExternalHttpTransport {
  Uint8List bytes =
      Uint8List.fromList(image.encodePng(image.Image(width: 128, height: 128)));
  bool corrupt = false;
  bool ambiguous = false;
  bool lowerPriorityConflict = false;
  bool gbaOnly = false;
  bool homeOnly = false;

  @override
  Future<PokemonExternalHttpResponse> getBounded(
    Uri uri, {
    required Map<String, String> headers,
    required int maximumBytes,
    required Duration timeout,
  }) async {
    final isList = uri.path.contains('/owners/pokemon/');
    Map<String, Object?> entry(String id, String usage, String style,
            Map<String, Object?> extra) =>
        {
          'id': id,
          'sha256': sha256.convert(bytes).toString(),
          'contentType': 'image/png',
          'usage': usage,
          'representation': 'sprite2d',
          'style': style,
          'metadata': {'formId': 'bulbasaur', ...extra},
        };
    final data = isList
        ? Uint8List.fromList(utf8.encode(jsonEncode([
            if (lowerPriorityConflict || gbaOnly) ...[
              {
                ...entry('front-gba-animated', 'battle', 'gba-emerald', {
                  'view': 'front',
                  'animationFormat': 'apng',
                }),
                'sha256': 'f' * 64,
              },
              entry('front-gba-static', 'battle', 'gba-emerald',
                  {'view': 'front'}),
            ],
            if (lowerPriorityConflict) ...[
              entry('front-gba-conflict-a', 'battle', 'gba-ruby-sapphire',
                  {'view': 'front'}),
              {
                ...entry('front-gba-conflict-b', 'battle', 'gba-ruby-sapphire',
                    {'view': 'front'}),
                'sha256': 'e' * 64,
              },
            ],
            if (!gbaOnly)
              entry('front-gen5', 'battle', 'gen5', {'view': 'front'}),
            if (!gbaOnly)
              entry('front-default', 'battle', 'pokeapi-default',
                  {'view': 'front'}),
            entry(
                'back-default', 'battle', 'pokeapi-default', {'view': 'back'}),
            entry('shiny-front', 'battle', 'gen5',
                {'view': 'front', 'shiny': true}),
            if (!homeOnly) entry('icon-gen5', 'menu', 'gen5', {}),
            if (homeOnly) ...[
              {
                ...entry('icon-home-shiny', 'menu', 'pokemon-home',
                    {'view': 'front', 'shiny': true}),
                'sha256': 'f' * 64,
              },
              entry('icon-home-normal', 'menu', 'pokemon-home',
                  {'view': 'front'}),
            ],
            entry('other-form', 'menu', 'gen5', {'formId': 'bulbasaur-other'}),
            entry('atlas', 'overworld', 'hgss-inspired', {
              'variant': 'regular',
              'atlas': {
                'rows': 4,
                'columns': 4,
                'tileWidth': 32,
                'tileHeight': 32
              },
            }),
            if (ambiguous)
              {
                ...entry(
                    'front-duplicate', 'battle', 'gen5', {'view': 'front'}),
                'sha256': 'f' * 64,
              },
          ])))
        : corrupt
            ? Uint8List.fromList([1, 2, 3])
            : bytes;
    return PokemonExternalHttpResponse(
      statusCode: 200,
      headers: const {},
      body: isList ? utf8.decode(data) : '',
      bodyBytes: data,
    );
  }
}

void main() {
  test('selects matching local PNGs and prefers Gen 5 with a fallback',
      () async {
    final transport = _Transport();
    final source = AvelunePokemonPngSource(
      media: AvelunePokemonMediaSource(client: transport, release: 'test'),
    );
    final result =
        await source.fetch(speciesId: 'bulbasaur', formId: 'bulbasaur');
    expect(
        result.media.keys,
        containsAll([
          PokemonPngRole.frontStatic,
          PokemonPngRole.backStatic,
          PokemonPngRole.frontShinyStatic,
          PokemonPngRole.icon,
          PokemonPngRole.overworld,
        ]));
    expect(result.media[PokemonPngRole.frontStatic]!.id, 'front-gen5');
    expect(result.media[PokemonPngRole.backStatic]!.id, 'back-default');
    expect(result.media[PokemonPngRole.icon]!.id, 'icon-gen5');
    expect(result.media[PokemonPngRole.overworld]!.bytes, transport.bytes);
    expect(result.media.containsKey(PokemonPngRole.backShinyStatic), isFalse);
  });

  test('ignores animated PNGs and conflicts in unused lower priority styles',
      () async {
    final transport = _Transport()..lowerPriorityConflict = true;
    final source = AvelunePokemonPngSource(
      media: AvelunePokemonMediaSource(client: transport, release: 'test'),
    );
    final result =
        await source.fetch(speciesId: 'bulbasaur', formId: 'bulbasaur');
    expect(result.media[PokemonPngRole.frontStatic]!.id, 'front-gen5');
  });

  test('uses the static GBA PNG when no preferred style exists', () async {
    final transport = _Transport()..gbaOnly = true;
    final source = AvelunePokemonPngSource(
      media: AvelunePokemonMediaSource(client: transport, release: 'test'),
    );
    final result =
        await source.fetch(speciesId: 'bulbasaur', formId: 'bulbasaur');
    expect(result.media[PokemonPngRole.frontStatic]!.id, 'front-gba-static');
  });

  test('uses the normal Home icon as a fallback when other icons are absent',
      () async {
    final transport = _Transport()..homeOnly = true;
    final source = AvelunePokemonPngSource(
      media: AvelunePokemonMediaSource(client: transport, release: 'test'),
    );
    final result =
        await source.fetch(speciesId: 'bulbasaur', formId: 'bulbasaur');
    expect(result.media[PokemonPngRole.icon]!.id, 'icon-home-normal');
  });

  test('rejects an animated PNG even when the API omits animation metadata',
      () async {
    final animated = image.Image(width: 128, height: 128);
    animated.addFrame(image.Image(width: 128, height: 128));
    final transport = _Transport()..bytes = image.encodePng(animated);
    final source = AvelunePokemonPngSource(
      media: AvelunePokemonMediaSource(client: transport, release: 'test'),
    );
    await expectLater(source.fetch(speciesId: 'bulbasaur', formId: 'bulbasaur'),
        throwsFormatException);
  });

  test('rejects corrupt and ambiguous media', () async {
    for (final scenario in ['corrupt', 'ambiguous']) {
      final transport = _Transport()
        ..corrupt = scenario == 'corrupt'
        ..ambiguous = scenario == 'ambiguous';
      final source = AvelunePokemonPngSource(
        media: AvelunePokemonMediaSource(client: transport, release: 'test'),
      );
      await expectLater(
          source.fetch(speciesId: 'bulbasaur', formId: 'bulbasaur'),
          throwsFormatException);
    }
  });
}
