import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';

import '../support/pokemon_external_source_fixture.dart';

final class FormSourceFixture extends PokemonExternalSourceFixture {
  const FormSourceFixture();

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonPayload(String id) async => {
    ...await super.fetchPokeApiPokemonPayload(id),
    'name': 'bulbasaur-base',
  };
}

final class CryTransport implements PokemonBoundedExternalHttpTransport {
  CryTransport(this.wav, this.mp3, this.scenario);
  final Uint8List wav;
  final Uint8List mp3;
  final String scenario;
  bool offline = false;
  int calls = 0;

  @override
  Future<PokemonExternalHttpResponse> getBounded(
    Uri uri, {
    required Map<String, String> headers,
    required int maximumBytes,
    required Duration timeout,
  }) async {
    calls++;
    if (offline || scenario == 'offline') {
      throw const SocketException('offline');
    }
    final isList = uri.path.contains('/owners/pokemon/');
    final useMp3 = scenario == 'mp3';
    final sound = useMp3 ? mp3 : wav;
    final payload = isList
        ? Uint8List.fromList(
            utf8.encode(
              jsonEncode([
                {
                  'id': 'bulbasaur-cry-latest${useMp3 ? '' : '-wav'}',
                  'sha256': sha256.convert(sound).toString(),
                  'contentType': useMp3 ? 'audio/mpeg' : 'audio/wav',
                  'usage': 'cry',
                  'representation': 'audio',
                  'style': 'latest',
                  'metadata': {
                    'formId': scenario == 'form'
                        ? 'bulbasaur-base'
                        : 'bulbasaur',
                    'provenance': {
                      'source': useMp3 ? 'fixture' : 'avelune/cry-wav',
                    },
                  },
                },
              ]),
            ),
          )
        : scenario == 'corrupt'
        ? Uint8List.fromList([1, 2, 3])
        : sound;
    return PokemonExternalHttpResponse(
      statusCode: 200,
      headers: const {},
      body: isList ? utf8.decode(payload) : '',
      bodyBytes: payload,
    );
  }
}
