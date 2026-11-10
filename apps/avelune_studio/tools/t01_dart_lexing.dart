class T01Token {
  const T01Token(this.value, {this.string = false});

  final String value;
  final bool string;
}

List<T01Token> t01Tokens(String source) {
  final tokens = <T01Token>[];
  var index = 0;
  bool rawString() =>
      index + 1 < source.length &&
      source[index] == 'r' &&
      (source[index + 1] == "'" || source[index + 1] == '"');
  bool quote() =>
      index < source.length &&
      (source[index] == "'" || source[index] == '"' || rawString());
  void skipComment() {
    if (source.startsWith('//', index)) {
      final end = source.indexOf('\n', index);
      index = end < 0 ? source.length : end + 1;
      return;
    }
    var depth = 1;
    index += 2;
    while (index < source.length && depth > 0) {
      if (source.startsWith('/*', index)) {
        depth++;
        index += 2;
      } else if (source.startsWith('*/', index)) {
        depth--;
        index += 2;
      } else {
        index++;
      }
    }
    if (depth != 0) throw const FormatException('Unterminated comment');
  }

  late String Function() readString;
  void skipInterpolation() {
    var depth = 1;
    index += 2;
    while (index < source.length && depth > 0) {
      if (quote()) {
        readString();
      } else if (source.startsWith('//', index) ||
          source.startsWith('/*', index)) {
        skipComment();
      } else {
        if (source[index] == '{') depth++;
        if (source[index] == '}') depth--;
        index++;
      }
    }
    if (depth != 0) throw const FormatException('Unterminated interpolation');
  }

  readString = () {
    final raw = rawString();
    if (raw) index++;
    final quote = source[index];
    final delimiter = source.startsWith(quote * 3, index) ? quote * 3 : quote;
    index += delimiter.length;
    final start = index;
    while (index < source.length) {
      if (!raw && source[index] == r'\') {
        index += 2;
      } else if (!raw && source.startsWith(r'${', index)) {
        skipInterpolation();
      } else if (source.startsWith(delimiter, index)) {
        final value = source.substring(start, index);
        index += delimiter.length;
        return value;
      } else {
        index++;
      }
    }
    throw const FormatException('Unterminated string');
  };
  while (index < source.length) {
    final char = source[index];
    if (char.trim().isEmpty) {
      index++;
      continue;
    }
    if (source.startsWith('//', index) || source.startsWith('/*', index)) {
      skipComment();
      continue;
    }
    if (quote()) {
      tokens.add(T01Token(readString(), string: true));
      continue;
    }
    if (RegExp(r'[A-Za-z_$]').hasMatch(char)) {
      final start = index++;
      while (index < source.length &&
          RegExp(r'[A-Za-z0-9_$]').hasMatch(source[index])) {
        index++;
      }
      tokens.add(T01Token(source.substring(start, index)));
    } else {
      tokens.add(T01Token(char));
      index++;
    }
  }
  return tokens;
}

List<String> t01Directives(String source) {
  final tokens = t01Tokens(source);
  final directives = <String>[];
  var depth = 0;
  for (var index = 0; index < tokens.length; index++) {
    final token = tokens[index];
    if (token.string) continue;
    if (token.value == '{') depth++;
    if (token.value == '}') depth--;
    if (depth != 0 ||
        (index > 0 && tokens[index - 1].value != ';') ||
        !{'import', 'export', 'part'}.contains(token.value)) {
      continue;
    }
    if (index + 1 >= tokens.length) {
      throw const FormatException('Incomplete directive');
    }
    if (token.value == 'part' && tokens[index + 1].value == 'of') continue;
    if (!tokens[index + 1].string) {
      throw const FormatException('Expected directive URI');
    }
    var terminated = false;
    while (++index < tokens.length) {
      final item = tokens[index];
      if (!item.string && item.value == ';') {
        terminated = true;
        break;
      }
      if (item.string) {
        if (item.value.contains(r'\') || item.value.contains(r'$')) {
          throw const FormatException('Escaped or interpolated directive URI');
        }
        directives.add(item.value);
      }
    }
    if (!terminated) throw const FormatException('Unterminated directive');
  }
  return directives;
}

Set<String> t01Declarations(String source) {
  final tokens = t01Tokens(source);
  final declarations = <String>{};
  for (var index = 0; index + 1 < tokens.length; index++) {
    if (!tokens[index].string &&
        {
          'class',
          'enum',
          'mixin',
          'typedef',
          'extension',
        }.contains(tokens[index].value) &&
        !tokens[index + 1].string) {
      declarations.add(tokens[index + 1].value);
    }
  }
  return declarations;
}
