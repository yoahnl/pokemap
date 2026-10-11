part of '../avelune_converter_core.dart';

enum MarshalKind {
  nil,
  boolean,
  integer,
  bigInteger,
  floating,
  string,
  symbol,
  array,
  hash,
  object,
  userDefined,
  userMarshal,
  classReference,
  moduleReference,
  regexp,
  struct,
  data,
}

final class BinaryDecodeLocation {
  const BinaryDecodeLocation({
    required this.sourcePath,
    required this.byteOffset,
    this.graphPath = r'$',
    this.tag,
  });

  final String sourcePath;
  final int byteOffset;
  final String graphPath;
  final int? tag;
}

final class BinaryDecodeError implements Exception {
  const BinaryDecodeError(this.code, this.message, this.location);

  final String code;
  final String message;
  final BinaryDecodeLocation location;

  @override
  String toString() =>
      'BinaryDecodeError($code at ${location.sourcePath}:${location.byteOffset}, ${location.graphPath}): $message';
}

final class MarshalDecodeLimits {
  const MarshalDecodeLimits({
    this.maxInputBytes = 67108864,
    this.maxDepth = 128,
    this.maxNodes = 2000000,
    this.maxObjects = 1000000,
    this.maxSymbols = 100000,
    this.maxContainerEntries = 500000,
    this.maxTotalEntries = 2000000,
    this.maxStringBytes = 33554432,
    this.maxTotalStringBytes = 67108864,
    this.maxBigIntegerWords = 4096,
    this.maxTableCells = 16777216,
    this.maxTotalLocationCodeUnits = 8388608,
  });

  final int maxInputBytes;
  final int maxDepth;
  final int maxNodes;
  final int maxObjects;
  final int maxSymbols;
  final int maxContainerEntries;
  final int maxTotalEntries;
  final int maxStringBytes;
  final int maxTotalStringBytes;
  final int maxBigIntegerWords;
  final int maxTableCells;
  final int maxTotalLocationCodeUnits;

  void _validate(BinaryDecodeLocation location) {
    final limits = [
      (maxInputBytes, 268435456),
      (maxDepth, 512),
      (maxNodes, 5000000),
      (maxObjects, 5000000),
      (maxSymbols, 1000000),
      (maxContainerEntries, 5000000),
      (maxTotalEntries, 10000000),
      (maxStringBytes, 134217728),
      (maxTotalStringBytes, 268435456),
      (maxBigIntegerWords, 65536),
      (maxTableCells, 67108864),
      (maxTotalLocationCodeUnits, 67108864),
    ];
    if (limits.any((limit) => limit.$1 <= 0 || limit.$1 > limit.$2)) {
      throw BinaryDecodeError(
        'marshal.invalid_limits',
        'Decoder limits must be positive and bounded.',
        location,
      );
    }
  }
}

final class MarshalPair {
  const MarshalPair(this.key, this.value);

  final int key;
  final int value;
}

final class MarshalText {
  MarshalText._(this.bytes, this.encoding, this.text, this.diagnosticCode);

  final List<int> bytes;
  final String? encoding;
  final String? text;
  final String? diagnosticCode;

  static MarshalText _decode(List<int> bytes, String? encoding) {
    final canonical = encoding?.toUpperCase().replaceAll('_', '-');
    String? text;
    String? diagnostic;
    try {
      switch (canonical) {
        case null:
        case 'UTF-8':
        case 'UTF8':
          text = utf8.decode(bytes, allowMalformed: false);
        case 'US-ASCII':
        case 'ASCII':
          text = ascii.decode(bytes, allowInvalid: false);
        case 'ISO-8859-1':
        case 'ISO8859-1':
        case 'LATIN1':
          text = latin1.decode(bytes, allowInvalid: false);
        case 'ASCII-8BIT':
        case 'BINARY':
          if (bytes.every((byte) => byte < 128)) {
            text = ascii.decode(bytes);
          } else {
            diagnostic = 'marshal.binary_text';
          }
        default:
          diagnostic = 'marshal.unsupported_encoding';
      }
    } on FormatException {
      diagnostic = 'marshal.invalid_text';
    }
    return MarshalText._(bytes, encoding, text, diagnostic);
  }
}

final class MarshalNode {
  MarshalNode._({
    required this.kind,
    required this.location,
    this.integerValue,
    this.booleanValue,
    this.floatValue,
    List<int>? bytes,
    this.name,
    this.className,
    Iterable<int> elements = const [],
    Iterable<MarshalPair> pairs = const [],
    Iterable<MarshalPair> instanceVariables = const [],
    Iterable<String> extensions = const [],
    this.userClass,
    this.defaultValue,
    this.regexpFlags,
    this.encoding,
    this.dataOffset,
  })  : bytes = bytes == null
            ? null
            : (bytes is Uint8List ? bytes : Uint8List.fromList(bytes))
                .asUnmodifiableView(),
        elements = List.unmodifiable(elements),
        pairs = List.unmodifiable(pairs),
        instanceVariables = List.unmodifiable(instanceVariables),
        extensions = List.unmodifiable(extensions);

  final MarshalKind kind;
  final BinaryDecodeLocation location;
  final BigInt? integerValue;
  final bool? booleanValue;
  final double? floatValue;
  final List<int>? bytes;
  final String? name;
  final String? className;
  final List<int> elements;
  final List<MarshalPair> pairs;
  final List<MarshalPair> instanceVariables;
  final List<String> extensions;
  final String? userClass;
  final int? defaultValue;
  final int? regexpFlags;
  final String? encoding;
  final int? dataOffset;

  MarshalText text() {
    final data = bytes;
    if (data == null) {
      throw StateError('This node has no byte sequence.');
    }
    return MarshalText._decode(data, encoding);
  }
}

final class MarshalDocument {
  MarshalDocument._({
    required this.rootId,
    required Iterable<MarshalNode> nodes,
    required this.objectCount,
    required this.symbolCount,
    required this.bytesRead,
  }) : nodes = List.unmodifiable(nodes);

  final int rootId;
  final List<MarshalNode> nodes;
  final int objectCount;
  final int symbolCount;
  final int bytesRead;

  MarshalNode node(int id) => nodes[id];
}

final class MarshalDecoder {
  const MarshalDecoder();

  MarshalDocument decode(
    List<int> bytes, {
    MarshalDecodeLimits limits = const MarshalDecodeLimits(),
    String sourcePath = '<memory>',
  }) {
    return _MarshalParser(bytes, limits, sourcePath).decode();
  }
}

final class SourceTable {
  SourceTable._({
    required this.dimensions,
    required this.xSize,
    required this.ySize,
    required this.zSize,
    required Int16List cells,
  }) : _cells = cells.asUnmodifiableView();

  final int dimensions;
  final int xSize;
  final int ySize;
  final int zSize;
  final Int16List _cells;

  int get cellCount => _cells.length;

  int valueAt(int x, int y, int z) {
    if (x < 0 || x >= xSize) throw RangeError.range(x, 0, xSize - 1, 'x');
    if (y < 0 || y >= ySize) throw RangeError.range(y, 0, ySize - 1, 'y');
    if (z < 0 || z >= zSize) throw RangeError.range(z, 0, zSize - 1, 'z');
    return _cells[x + y * xSize + z * xSize * ySize];
  }
}

final class TableDecoder {
  const TableDecoder();

  SourceTable decode(
    MarshalNode node, {
    MarshalDecodeLimits limits = const MarshalDecodeLimits(),
  }) {
    limits._validate(node.location);
    final bytes = node.bytes;
    if (node.kind != MarshalKind.userDefined ||
        node.className != 'Table' ||
        bytes == null) {
      throw BinaryDecodeError(
        'table.invalid_type',
        'Expected an inert Table payload.',
        node.location,
      );
    }
    final dataOffset = node.dataOffset ?? node.location.byteOffset;
    Never fail(String code, String message, int relativeOffset) {
      throw BinaryDecodeError(
        code,
        message,
        BinaryDecodeLocation(
          sourcePath: node.location.sourcePath,
          byteOffset: dataOffset + relativeOffset,
          graphPath: node.location.graphPath,
          tag: node.location.tag,
        ),
      );
    }

    if (bytes.length < 20) {
      fail('table.header', 'Table header is truncated.', bytes.length);
    }
    final data = ByteData.sublistView(bytes as Uint8List);
    final dimensions = data.getInt32(0, Endian.little);
    final sizes = [
      data.getInt32(4, Endian.little),
      data.getInt32(8, Endian.little),
      data.getInt32(12, Endian.little),
    ];
    final cellCount = data.getInt32(16, Endian.little);
    if (dimensions < 1 || dimensions > 3) {
      fail('table.dimensions', 'Table dimension must be 1, 2 or 3.', 0);
    }
    for (var i = 0; i < sizes.length; i++) {
      if (sizes[i] < 0 || (i >= dimensions && sizes[i] != 1)) {
        fail('table.dimensions', 'Table axis size is invalid.', 4 + i * 4);
      }
      if (sizes[i] > limits.maxTableCells) {
        fail('table.quota', 'Table axis exceeds the cell quota.', 4 + i * 4);
      }
    }
    if (cellCount < 0) {
      fail('table.length', 'Cell count cannot be negative.', 16);
    }
    if (cellCount > limits.maxTableCells) {
      fail('table.quota', 'Table cell count exceeds its quota.', 16);
    }
    var expected = sizes.contains(0) ? 0 : 1;
    if (expected != 0) {
      for (final size in sizes) {
        if (expected > limits.maxTableCells ~/ size) {
          fail('table.quota', 'Table axis product exceeds its quota.', 16);
        }
        expected *= size;
      }
    }
    if (cellCount != expected || bytes.length != 20 + cellCount * 2) {
      fail('table.length', 'Table dimensions, count and payload disagree.', 16);
    }
    final cells = Int16List(cellCount);
    for (var i = 0; i < cellCount; i++) {
      cells[i] = data.getInt16(20 + i * 2, Endian.little);
    }
    return SourceTable._(
      dimensions: dimensions,
      xSize: sizes[0],
      ySize: sizes[1],
      zSize: sizes[2],
      cells: cells,
    );
  }
}

final class SourceColor {
  const SourceColor(this.red, this.green, this.blue, this.alpha);
  final double red;
  final double green;
  final double blue;
  final double alpha;
}

final class SourceTone {
  const SourceTone(this.red, this.green, this.blue, this.gray);
  final double red;
  final double green;
  final double blue;
  final double gray;
}

final class RgssColorDecoder {
  const RgssColorDecoder();
  SourceColor decode(MarshalNode node) {
    final values = _rgbaPayload(node, 'Color');
    return SourceColor(values[0], values[1], values[2], values[3]);
  }
}

final class RgssToneDecoder {
  const RgssToneDecoder();
  SourceTone decode(MarshalNode node) {
    final values = _rgbaPayload(node, 'Tone');
    return SourceTone(values[0], values[1], values[2], values[3]);
  }
}

final class _MarshalNodeBuilder {
  _MarshalNodeBuilder(this.kind, this.location);
  final MarshalKind kind;
  final BinaryDecodeLocation location;
  BigInt? integerValue;
  bool? booleanValue;
  double? floatValue;
  Uint8List? bytes;
  String? name;
  String? className;
  final List<int> elements = [];
  final List<MarshalPair> pairs = [];
  final List<MarshalPair> instanceVariables = [];
  final List<String> extensions = [];
  String? userClass;
  int? defaultValue;
  int? regexpFlags;
  String? encoding;
  int? dataOffset;

  MarshalNode freeze() => MarshalNode._(
        kind: kind,
        location: location,
        integerValue: integerValue,
        booleanValue: booleanValue,
        floatValue: floatValue,
        bytes: bytes,
        name: kind == MarshalKind.symbol
            ? MarshalText._decode(bytes!, encoding).text
            : name,
        className: className,
        elements: elements,
        pairs: pairs,
        instanceVariables: instanceVariables,
        extensions: extensions,
        userClass: userClass,
        defaultValue: defaultValue,
        regexpFlags: regexpFlags,
        encoding: encoding,
        dataOffset: dataOffset,
      );
}

final class _MarshalParser {
  _MarshalParser(this.input, this.limits, this.sourcePath);
  final List<int> input;
  final MarshalDecodeLimits limits;
  final String sourcePath;
  final List<_MarshalNodeBuilder> nodes = [];
  final List<int> objects = [];
  final List<int> symbols = [];
  int offset = 0;
  int totalEntries = 0;
  int totalStringBytes = 0;
  int objectSlots = 0;
  int totalLocationUnits = 0;
  String path = r'$';
  int? tag;

  BinaryDecodeLocation get location => BinaryDecodeLocation(
        sourcePath: sourcePath,
        byteOffset: offset,
        graphPath: path,
        tag: tag,
      );

  Never fail(String code, String message, {int? at}) {
    throw BinaryDecodeError(
      code,
      message,
      BinaryDecodeLocation(
        sourcePath: sourcePath,
        byteOffset: at ?? offset,
        graphPath: path,
        tag: tag,
      ),
    );
  }

  int byte() {
    if (offset >= input.length) {
      fail('marshal.truncated', 'Expected another byte.');
    }
    final value = input[offset++];
    if (value < 0 || value > 255) {
      fail('marshal.invalid_byte', 'Input must contain bytes.', at: offset - 1);
    }
    return value;
  }

  int packedInteger() {
    final first = byte();
    final count = first >= 128 ? first - 256 : first;
    if (count == 0) return 0;
    if (count > 4) return count - 5;
    if (count < -4) return count + 5;
    var value = count < 0 ? -1 : 0;
    for (var index = 0; index < count.abs(); index++) {
      final shift = index * 8;
      value = (value & ~(255 << shift)) | (byte() << shift);
    }
    return value;
  }

  int count(int maximum, String code, {int minimumBytes = 1}) {
    final start = offset;
    final value = packedInteger();
    if (value < 0) {
      fail('marshal.invalid_length', 'A length cannot be negative.', at: start);
    }
    if (value > maximum) {
      fail(code, 'Declared length exceeds its quota.', at: start);
    }
    if (minimumBytes > 0 && value > (input.length - offset) ~/ minimumBytes) {
      fail('marshal.truncated', 'Declared content exceeds remaining bytes.',
          at: start);
    }
    return value;
  }

  Uint8List sequence(_MarshalNodeBuilder node, {int? maximum}) {
    final length = count(
      maximum == null || maximum > limits.maxStringBytes
          ? limits.maxStringBytes
          : maximum,
      'marshal.quota.string',
    );
    if (length > limits.maxTotalStringBytes - totalStringBytes) {
      fail('marshal.quota.total_string',
          'Byte sequences exceed their cumulative quota.');
    }
    totalStringBytes += length;
    node.dataOffset = offset;
    final result = Uint8List(length);
    for (var i = 0; i < length; i++) {
      result[i] = byte();
    }
    return result;
  }

  int allocate(MarshalKind kind, int start) {
    if (nodes.length >= limits.maxNodes) {
      fail('marshal.quota.nodes', 'Node count exceeds its quota.', at: start);
    }
    if (path.length > 8192 ||
        path.length > limits.maxTotalLocationCodeUnits - totalLocationUnits) {
      fail('marshal.quota.locations', 'Graph locations exceed their quota.',
          at: start);
    }
    totalLocationUnits += path.length;
    final id = nodes.length;
    nodes.add(_MarshalNodeBuilder(
      kind,
      BinaryDecodeLocation(
        sourcePath: sourcePath,
        byteOffset: start,
        graphPath: path,
        tag: tag,
      ),
    ));
    return id;
  }

  void register(int id) {
    objects.add(id);
  }

  int entries({bool pairs = false}) {
    final value = count(
      limits.maxContainerEntries,
      'marshal.quota.container',
      minimumBytes: pairs ? 2 : 1,
    );
    final edges = value * (pairs ? 2 : 1);
    if (edges > limits.maxTotalEntries - totalEntries) {
      fail('marshal.quota.total_entries',
          'Container edges exceed their cumulative quota.');
    }
    totalEntries += edges;
    return value;
  }

  String symbolName(int depth, String childPath) {
    final result = read(depth, childPath);
    final node = nodes[result.$1];
    if (node.kind != MarshalKind.symbol) {
      fail('marshal.invalid_symbol', 'Expected a symbol.');
    }
    final text = MarshalText._decode(node.bytes!, node.encoding);
    if (text.text == null) {
      fail(
          'marshal.invalid_encoding', 'Symbol name cannot be decoded exactly.');
    }
    return text.text!;
  }

  void variables(_MarshalNodeBuilder node, int depth, {bool members = false}) {
    final size = entries(pairs: true);
    for (var i = 0; i < size; i++) {
      final key = read(depth + 1, '${node.location.graphPath}.ivar[$i].key').$1;
      if (nodes[key].kind != MarshalKind.symbol) {
        fail('marshal.invalid_symbol', 'Attribute names must be symbols.');
      }
      final value =
          read(depth + 1, '${node.location.graphPath}.ivar[$i].value').$1;
      (members ? node.pairs : node.instanceVariables)
          .add(MarshalPair(key, value));
      final name =
          MarshalText._decode(nodes[key].bytes!, nodes[key].encoding).text;
      if ({
            MarshalKind.string,
            MarshalKind.symbol,
            MarshalKind.regexp,
            MarshalKind.userDefined
          }.contains(node.kind) &&
          name == 'E') {
        final boolean = nodes[value].booleanValue;
        if (nodes[value].kind != MarshalKind.boolean || boolean == null) {
          fail('marshal.invalid_encoding', 'Encoding flag must be boolean.');
        }
        if (node.encoding != null) {
          fail('marshal.invalid_encoding',
              'Encoding is declared more than once.');
        }
        node.encoding = boolean ? 'UTF-8' : 'US-ASCII';
      } else if ({
            MarshalKind.string,
            MarshalKind.symbol,
            MarshalKind.regexp,
            MarshalKind.userDefined
          }.contains(node.kind) &&
          name == 'encoding') {
        final encoded = nodes[value];
        if (encoded.kind != MarshalKind.string) {
          fail('marshal.invalid_encoding', 'Encoding name must be a string.');
        }
        final encoding =
            MarshalText._decode(encoded.bytes!, encoded.encoding).text;
        if (encoding == null || encoding.isEmpty || node.encoding != null) {
          fail('marshal.invalid_encoding', 'Encoding declaration is invalid.');
        }
        node.encoding = encoding;
      }
    }
  }

  (int, bool) read(int depth, String graphPath, {bool inIvar = false}) {
    if (depth > limits.maxDepth) {
      path = graphPath;
      fail('marshal.quota.depth', 'Graph depth exceeds its quota.');
    }
    final previousPath = path;
    final previousTag = tag;
    path = graphPath;
    final start = offset;
    tag = byte();
    try {
      final currentTag = tag!;
      if (currentTag == 64 || currentTag == 59) {
        final references = currentTag == 64 ? objects : symbols;
        final reference = packedInteger();
        if (reference < 0 || reference >= references.length) {
          fail(
              currentTag == 59
                  ? 'marshal.invalid_symbol'
                  : 'marshal.invalid_reference',
              'Reference is outside its table.',
              at: start);
        }
        return (references[reference], false);
      }
      if (currentTag == 73) {
        final result = read(depth + 1, graphPath, inIvar: true);
        if (!result.$2) {
          final wrapped = nodes[result.$1];
          if ({
            MarshalKind.nil,
            MarshalKind.boolean,
            MarshalKind.integer,
            MarshalKind.floating,
            MarshalKind.bigInteger,
            MarshalKind.classReference,
            MarshalKind.moduleReference
          }.contains(wrapped.kind)) {
            fail('marshal.invalid_ivar',
                'This node cannot carry instance variables.',
                at: start);
          }
          variables(wrapped, depth);
        }
        return (result.$1, false);
      }
      if (currentTag == 101 || currentTag == 67) {
        final name = symbolName(depth + 1, '$graphPath.wrapper');
        final result = read(depth + 1, graphPath, inIvar: inIvar);
        final node = nodes[result.$1];
        if (currentTag == 101) {
          node.extensions.insert(0, name);
        } else {
          if (!{
                MarshalKind.string,
                MarshalKind.regexp,
                MarshalKind.array,
                MarshalKind.hash,
              }.contains(node.kind) ||
              node.userClass != null) {
            fail('marshal.invalid_user_class', 'User class wrapper is invalid.',
                at: start);
          }
          node.userClass = name;
        }
        return result;
      }
      final kind = switch (currentTag) {
        48 => MarshalKind.nil,
        84 || 70 => MarshalKind.boolean,
        105 => MarshalKind.integer,
        108 => MarshalKind.bigInteger,
        102 => MarshalKind.floating,
        34 => MarshalKind.string,
        58 => MarshalKind.symbol,
        91 => MarshalKind.array,
        123 || 125 => MarshalKind.hash,
        111 => MarshalKind.object,
        117 => MarshalKind.userDefined,
        85 => MarshalKind.userMarshal,
        99 => MarshalKind.classReference,
        109 || 77 => MarshalKind.moduleReference,
        47 => MarshalKind.regexp,
        83 => MarshalKind.struct,
        100 => MarshalKind.data,
        _ => null,
      };
      if (kind == null) {
        fail('marshal.unsupported_tag', 'Unsupported Marshal tag.', at: start);
      }
      if (kind == MarshalKind.symbol) {
        if (symbols.length >= limits.maxSymbols) {
          fail('marshal.quota.symbols',
              'Symbol reference table exceeds its quota.',
              at: start);
        }
      } else if (!{
        MarshalKind.nil,
        MarshalKind.boolean,
        MarshalKind.integer,
      }.contains(kind)) {
        if (objectSlots >= limits.maxObjects) {
          fail('marshal.quota.objects',
              'Object reference table exceeds its quota.',
              at: start);
        }
        objectSlots++;
      }
      final id = allocate(kind, start);
      final node = nodes[id];
      switch (kind) {
        case MarshalKind.nil:
          break;
        case MarshalKind.boolean:
          node.booleanValue = currentTag == 84;
        case MarshalKind.integer:
          node.integerValue = BigInt.from(packedInteger());
        case MarshalKind.bigInteger:
          final sign = byte();
          if (sign != 43 && sign != 45) {
            fail('marshal.invalid_integer', 'Large integer sign is invalid.');
          }
          final words = count(
            limits.maxBigIntegerWords,
            'marshal.quota.big_integer',
            minimumBytes: 2,
          );
          var integer = BigInt.zero;
          for (var i = 0; i < words * 2; i++) {
            integer |= BigInt.from(byte()) << (i * 8);
          }
          node.integerValue = sign == 45 ? -integer : integer;
          register(id);
        case MarshalKind.floating:
          node.bytes = sequence(node, maximum: 128);
          node.floatValue = floatingValue(node.bytes!);
          if (node.floatValue == null) {
            fail('marshal.invalid_float', 'Float byte sequence is invalid.');
          }
          register(id);
        case MarshalKind.string:
        case MarshalKind.symbol:
        case MarshalKind.regexp:
          node.bytes = sequence(node);
          if (kind == MarshalKind.symbol) {
            symbols.add(id);
          } else {
            register(id);
          }
          if (kind == MarshalKind.regexp) node.regexpFlags = byte();
        case MarshalKind.array:
          register(id);
          final length = entries();
          for (var i = 0; i < length; i++) {
            node.elements.add(read(depth + 1, '$graphPath[$i]').$1);
          }
        case MarshalKind.hash:
          register(id);
          final length = entries(pairs: true);
          for (var i = 0; i < length; i++) {
            final key = read(depth + 1, '$graphPath.pair[$i].key').$1;
            final value = read(depth + 1, '$graphPath.pair[$i].value').$1;
            node.pairs.add(MarshalPair(key, value));
          }
          if (currentTag == 125) {
            if (totalEntries >= limits.maxTotalEntries) {
              fail('marshal.quota.total_entries',
                  'Container edges exceed their cumulative quota.');
            }
            totalEntries++;
            node.defaultValue = read(depth + 1, '$graphPath.default').$1;
          }
        case MarshalKind.object:
        case MarshalKind.struct:
          register(id);
          node.className = symbolName(depth + 1, '$graphPath.class');
          variables(node, depth, members: kind == MarshalKind.struct);
        case MarshalKind.userDefined:
          node.className = symbolName(depth + 1, '$graphPath.class');
          node.bytes = sequence(node);
          if (inIvar) variables(node, depth);
          register(id);
          return (id, inIvar);
        case MarshalKind.userMarshal:
        case MarshalKind.data:
          node.className = symbolName(depth + 1, '$graphPath.class');
          register(id);
          if (totalEntries >= limits.maxTotalEntries) {
            fail('marshal.quota.total_entries',
                'Container edges exceed their cumulative quota.');
          }
          totalEntries++;
          node.elements.add(read(depth + 1, '$graphPath.payload').$1);
        case MarshalKind.classReference:
        case MarshalKind.moduleReference:
          node.bytes = sequence(node);
          final name = MarshalText._decode(node.bytes!, 'UTF-8').text;
          if (name == null) {
            fail(
                'marshal.invalid_encoding', 'Class or module name is invalid.');
          }
          node.name = name;
          register(id);
      }
      return (id, false);
    } finally {
      path = previousPath;
      tag = previousTag;
    }
  }

  double? floatingValue(List<int> bytes) {
    final marker = bytes.indexOf(0);
    final prefix = marker < 0 ? bytes : bytes.sublist(0, marker);
    final text = MarshalText._decode(prefix, 'US-ASCII').text;
    final value = switch (text) {
      'nan' => double.nan,
      'inf' => double.infinity,
      '-inf' => double.negativeInfinity,
      _ => text != null &&
              RegExp(r'^[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?$')
                  .hasMatch(text)
          ? double.tryParse(text)
          : null,
    };
    if (marker < 0 || value == null) return value;
    final suffix = bytes.sublist(marker + 1);
    if (!value.isFinite ||
        value == 0 ||
        suffix.isEmpty ||
        suffix.length > 2 ||
        suffix.last == 0) {
      return null;
    }
    final bits = ByteData(8)..setFloat64(0, value.abs(), Endian.little);
    final upper = bits.getUint32(4, Endian.little);
    final exponentBits = (upper >> 20) & 2047;
    final fraction =
        ((upper & 1048575) << 32) | bits.getUint32(0, Endian.little);
    final significand = exponentBits == 0 ? fraction : fraction | (1 << 52);
    final normalizedBits = significand.bitLength;
    final exponent =
        exponentBits == 0 ? normalizedBits - 1074 : exponentBits - 1022;
    final leading = normalizedBits >= 37
        ? significand >> (normalizedBits - 37)
        : significand << (37 - normalizedBits);
    var remainder = 0;
    for (final byte in suffix) {
      remainder = (remainder << 8) | byte;
    }
    final normalized =
        (leading + remainder / math.pow(2.0, suffix.length * 8)) /
            math.pow(2.0, 37);
    final restored = exponent == 1024
        ? (normalized * 2) * math.pow(2.0, 1023)
        : normalized * math.pow(2.0, exponent);
    return value.isNegative ? -restored : restored;
  }

  MarshalDocument decode() {
    limits._validate(location);
    if (input.length > limits.maxInputBytes) {
      fail('marshal.quota.input', 'Input exceeds its byte quota.');
    }
    if (byte() != 4 || byte() != 8) {
      fail('marshal.invalid_version', 'Only Marshal version 4.8 is supported.',
          at: 0);
    }
    final root = read(0, r'$').$1;
    if (offset != input.length) {
      fail('marshal.trailing_bytes', 'Bytes remain after the root value.');
    }
    return MarshalDocument._(
      rootId: root,
      nodes: nodes.map((node) => node.freeze()),
      objectCount: objects.length,
      symbolCount: symbols.length,
      bytesRead: offset,
    );
  }
}

List<double> _rgbaPayload(MarshalNode node, String className) {
  final bytes = node.bytes;
  if (node.kind != MarshalKind.userDefined ||
      node.className != className ||
      bytes == null) {
    throw BinaryDecodeError(
      'rgss.invalid_type',
      'Expected the requested inert RGSS payload.',
      node.location,
    );
  }
  if (bytes.length != 32) {
    throw BinaryDecodeError(
      'rgss.invalid_length',
      'RGSS color and tone payloads require four doubles.',
      node.location,
    );
  }
  final data = ByteData.sublistView(bytes as Uint8List);
  final values = List<double>.generate(
    4,
    (index) => data.getFloat64(index * 8, Endian.little),
  );
  if (values.any((value) => !value.isFinite)) {
    throw BinaryDecodeError(
      'rgss.non_finite',
      'RGSS color and tone components must be finite.',
      node.location,
    );
  }
  return values;
}
