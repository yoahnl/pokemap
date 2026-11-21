part of 'hub_prepared_narrative_index.dart';

Future<RuntimePreparedNarrativeCorpus> _decodeCorpus(
  Uint8List body,
  String gameId,
  String treeSha256,
  int version,
) => Isolate.run(() async {
  final output = BytesBuilder(copy: false);
  await for (final chunk in gzip.decoder.bind(Stream.value(body))) {
    if (output.length + chunk.length >
        HubPreparedNarrativeIndex._maximumBytes) {
      throw const PreparedNarrativeCacheUnavailable();
    }
    output.add(chunk);
  }
  final json = decodeNarrativeEventJsonStrict(utf8.decode(output.takeBytes()));
  final legacy = version == 1;
  if (json is! Map<String, Object?> ||
      json.length != (legacy ? 5 : 6) ||
      json['format'] != 'avelune.runtime-narrative' ||
      json['validatorVersion'] is! int ||
      json['validatorVersion'] != version ||
      json['gameId'] != gameId ||
      json['treeSha256'] != treeSha256 ||
      json['maps'] is! List<Object?>) {
    throw const FormatException('Prepared narrative index identity mismatch.');
  }
  return RuntimePreparedNarrativeCorpus(
    maps: [
      for (final map in json['maps']! as List<Object?>)
        NarrativeMapProjection.fromJson(map as Map<String, Object?>),
    ],
    visualDefinitions: legacy
        ? null
        : RuntimeNarrativeVisualDefinitions.fromJson(
            json['visualDefinitions'] as Map<String, Object?>,
          ),
  );
});

Future<List<int>> _encodeCorpus(
  RuntimePreparedNarrativeCorpus corpus,
  String gameId,
  String treeSha256,
) => Isolate.run(() {
  final bytes = utf8.encode(
    jsonEncode({
      'format': 'avelune.runtime-narrative',
      'validatorVersion': HubPreparedNarrativeIndex.validatorVersion,
      'gameId': gameId,
      'treeSha256': treeSha256,
      'maps': [for (final map in corpus.maps) map.toJson()],
      'visualDefinitions': corpus.visualDefinitions!.toJson(),
    }),
  );
  if (bytes.length > HubPreparedNarrativeIndex._maximumBytes) {
    throw const PreparedNarrativeCacheUnavailable();
  }
  return gzip.encode(bytes);
});
