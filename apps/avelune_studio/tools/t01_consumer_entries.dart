import 't01_dart_lexing.dart';

List<String> t01StudioConsumerEntries(Map<String, String> sources) => [
  for (final source in sources.entries)
    if (t01Directives(source.value).any((specifier) {
      final uri = Uri.parse(specifier);
      return uri.pathSegments.contains('avelune_studio');
    }))
      source.key,
];
