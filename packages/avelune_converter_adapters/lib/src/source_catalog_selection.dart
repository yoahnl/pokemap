import 'package:avelune_converter_core/avelune_converter_core.dart';

({List<String> items, List<SourcePbsIdentity> trainers}) sourceCatalogSelection(
    NormalizedSourceProject source, Set<int> mapIds) {
  final items = <String>{};
  final trainers = <String, SourcePbsIdentity>{};
  for (final map
      in source.maps.where((entry) => mapIds.contains(entry.map.sourceMapId))) {
    for (final event in map.map.events) {
      for (final page in event.pages) {
        for (final command in page.commands) {
          String? text;
          if (command.code == 355 &&
              command.parameters.length == 1 &&
              command.parameters.single is String) {
            text = command.parameters.single as String;
          } else if (command.code == 111 &&
              command.parameters.length == 2 &&
              command.parameters.first == 12 &&
              command.parameters.last is String) {
            text = command.parameters.last as String;
          }
          if (text == null) continue;
          final call = _CatalogLiteralCall.read(text);
          if (call == null || call.arguments.isEmpty) continue;
          final first = call.arguments.first;
          if (first.$1 != 'symbol') continue;
          if ((call.name == 'pbItemBall' || call.name == 'pbReceiveItem') &&
              (call.arguments.length == 1 ||
                  (call.arguments.length == 2 &&
                      call.arguments[1].$1 == 'integer'))) {
            items.add(first.$2);
          } else if ((call.name == 'TrainerBattle.start' ||
                  (call.name == 'pbTrainerBattle' &&
                      call.arguments.length == 2)) &&
              call.arguments.length >= 2 &&
              call.arguments.length <= 3 &&
              call.arguments[1].$1 == 'string' &&
              (call.arguments.length == 2 ||
                  call.arguments[2].$1 == 'integer')) {
            final identity = SourcePbsIdentity(
                namespace: source.snapshot.logicalProjectNamespace,
                family: SourcePbsFamily.trainers,
                trainerType: first.$2,
                trainerName: call.arguments[1].$2,
                version: call.arguments.length == 3
                    ? int.parse(call.arguments[2].$2)
                    : 0);
            trainers[identity.key] = identity;
          }
        }
      }
    }
  }
  return (
    items: items.toList()..sort(),
    trainers: trainers.values.toList()..sort((a, b) => a.key.compareTo(b.key))
  );
}

final class _CatalogLiteralCall {
  const _CatalogLiteralCall(this.name, this.arguments);
  final String name;
  final List<(String, String)> arguments;

  static _CatalogLiteralCall? read(String text) {
    final match = RegExp(
            r'^(pbItemBall|pbReceiveItem|pbTrainerBattle|TrainerBattle\.start)\s*\((.*)\)$',
            dotAll: true)
        .firstMatch(text.trim());
    if (match == null) return null;
    final body = match[2]!;
    final arguments = <(String, String)>[];
    var offset = 0;
    void space() {
      while (offset < body.length && RegExp(r'\s').hasMatch(body[offset])) {
        offset++;
      }
    }

    while (offset < body.length) {
      space();
      if (offset == body.length) return null;
      final unit = body[offset];
      if (unit == ':') {
        offset++;
        final symbol = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*')
            .firstMatch(body.substring(offset));
        if (symbol == null) return null;
        arguments.add(('symbol', symbol[0]!));
        offset += symbol[0]!.length;
      } else if (unit == '"' || unit == "'") {
        offset++;
        final value = StringBuffer();
        var ended = false;
        while (offset < body.length) {
          final character = body[offset++];
          if (character == unit) {
            ended = true;
            break;
          }
          if (character == r'\') {
            return null;
          } else {
            value.write(character);
          }
        }
        final literal = value.toString();
        if (!ended ||
            (unit == '"' &&
                (literal.contains(r'#{') ||
                    literal.contains('#@') ||
                    literal.contains(r'#$')))) {
          return null;
        }
        arguments.add(('string', literal));
      } else {
        final integer =
            RegExp(r'^(0|[1-9][0-9]{0,9})').firstMatch(body.substring(offset));
        if (integer == null || int.parse(integer[0]!) > 2147483647) return null;
        arguments.add(('integer', integer[0]!));
        offset += integer[0]!.length;
      }
      space();
      if (offset == body.length) break;
      if (body[offset++] != ',') return null;
      space();
      if (offset == body.length || arguments.length >= 3) return null;
    }
    return _CatalogLiteralCall(match[1]!, List.unmodifiable(arguments));
  }
}
