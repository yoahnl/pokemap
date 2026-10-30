import '../support/authoring_fingerprint.dart';
import 'json_contract_support.dart';

final class MapEditOperation {
  MapEditOperation({
    required String operationId,
    required String mapId,
    required Iterable<Map<String, Object?>> operations,
    int seed = 0,
    Map<String, Object?> guards = const {},
    this.dryRun = false,
  })  : operationId = _identity(operationId),
        mapId = requireContractString(mapId, 'mapId'),
        seed = _seed(seed),
        operations = List.unmodifiable(operations.map(_operation)),
        guards = _guards(guards) {
    if (this.operations.isEmpty || this.operations.length > 64) {
      throw const FormatException('operations must contain 1 to 64 entries');
    }
  }

  factory MapEditOperation.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, const {
      'operationId',
      'mapId',
      'operations',
      'seed',
      'guards',
      'dryRun',
    });
    final operations = json['operations'];
    final guards =
        json.containsKey('guards') ? json['guards'] : const <String, Object?>{};
    final seed = json.containsKey('seed') ? json['seed'] : 0;
    final dryRun = json.containsKey('dryRun') ? json['dryRun'] : false;
    if (operations is! List ||
        guards is! Map ||
        seed is! int ||
        dryRun is! bool) {
      throw const FormatException('Invalid map edit operation fields');
    }
    return MapEditOperation(
      operationId: requireContractString(json['operationId'], 'operationId'),
      mapId: requireContractString(json['mapId'], 'mapId'),
      operations: operations.map((value) {
        if (value is! Map) throw const FormatException('Invalid operation');
        return Map<String, Object?>.from(value);
      }),
      guards: Map<String, Object?>.from(guards),
      seed: seed,
      dryRun: dryRun,
    );
  }

  static const contractVersion = 1;
  static const defaultGuards = <String, Object?>{
    'groundGaps': 'refuse',
    'borderObjectOverlaps': 'refuse',
    'staleBorders': 'rematerialize',
    'newBorderErrors': 'refuse',
    'newBorderWarnings': 'report',
  };
  final String operationId;
  final String mapId;
  final int seed;
  final bool dryRun;
  final List<Map<String, Object?>> operations;
  final Map<String, Object?> guards;

  String get semanticFingerprint => computeAuthoringJsonFingerprint({
        'contractVersion': contractVersion,
        ...toBatchParameters(),
      }, logicalName: 'map-edit-operation.json');

  Map<String, Object?> toBatchParameters() => {
        'mapId': mapId,
        'seed': seed,
        'operations': operations,
        'guards': guards,
      };

  Map<String, Object?> toJson() => {
        'operationId': operationId,
        ...toBatchParameters(),
        'dryRun': dryRun,
      };

  static String _identity(String value) {
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,119}$').hasMatch(value)) {
      throw const FormatException('Invalid operationId');
    }
    return value;
  }

  static int _seed(int value) {
    if (value < 0 || value > 0x7fffffff) {
      throw const FormatException('seed must be between 0 and 2147483647');
    }
    return value;
  }

  static Map<String, Object?> _operation(Map<String, Object?> value) {
    rejectUnknownContractKeys(
        value, const {'actionId', 'actionVersion', 'parameters'});
    final parameters = value['parameters'];
    if (parameters is! Map) {
      throw const FormatException('parameters must be an object');
    }
    return freezeContractJsonObject({
      'actionId': requireContractString(value['actionId'], 'actionId'),
      'actionVersion': requirePositiveContractVersion(
          value['actionVersion'], 'actionVersion'),
      'parameters': Map<String, Object?>.from(parameters),
    }, field: 'operation');
  }

  static Map<String, Object?> _guards(Map<String, Object?> value) {
    rejectUnknownContractKeys(value, defaultGuards.keys.toSet());
    final normalized = {...defaultGuards, ...value};
    for (final entry in normalized.entries) {
      final allowed = entry.key == 'staleBorders'
          ? const {'rematerialize', 'refuse', 'report'}
          : const {'refuse', 'report'};
      if (!allowed.contains(entry.value)) {
        throw FormatException('Invalid guard ${entry.key}');
      }
    }
    return freezeContractJsonObject(normalized, field: 'guards');
  }
}

final class MapEditBinding {
  MapEditBinding(
      {required this.operationId,
      required this.fingerprint,
      required this.mapId,
      required this.seed,
      required this.snapshotRevision,
      required this.unchanged});

  factory MapEditBinding.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, const {
      'contractVersion',
      'operationId',
      'fingerprint',
      'mapId',
      'seed',
      'snapshotRevision',
      'unchanged',
    });
    if (json['contractVersion'] != 1 ||
        json['seed'] is! int ||
        json['unchanged'] is! bool) {
      throw const FormatException('Invalid map edit binding');
    }
    final fingerprint =
        requireContractString(json['fingerprint'], 'fingerprint');
    if (!RegExp(r'^sha256:[a-f0-9]{64}$').hasMatch(fingerprint)) {
      throw const FormatException('Invalid map edit fingerprint');
    }
    return MapEditBinding(
        operationId: MapEditOperation._identity(
            requireContractString(json['operationId'], 'operationId')),
        fingerprint: fingerprint,
        mapId: requireContractString(json['mapId'], 'mapId'),
        seed: MapEditOperation._seed(json['seed'] as int),
        snapshotRevision:
            requireContractString(json['snapshotRevision'], 'snapshotRevision'),
        unchanged: json['unchanged'] as bool);
  }

  final String operationId;
  final String fingerprint;
  final String mapId;
  final int seed;
  final String snapshotRevision;
  final bool unchanged;
  Map<String, Object?> toJson() => {
        'contractVersion': 1,
        'operationId': operationId,
        'fingerprint': fingerprint,
        'mapId': mapId,
        'seed': seed,
        'snapshotRevision': snapshotRevision,
        'unchanged': unchanged,
      };
}
