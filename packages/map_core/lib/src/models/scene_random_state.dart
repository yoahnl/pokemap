import 'package:meta/meta.dart' show immutable;

@immutable
final class SceneRandomState {
  const SceneRandomState.unseeded() : state = null;
  SceneRandomState(int value) : state = value {
    if (value < 0 || value > 4294967295)
      throw ArgumentError.value(value, 'state');
  }
  factory SceneRandomState.fromJson(Map<String, dynamic> json) {
    if (json.length != 1 || !json.containsKey('state'))
      throw const FormatException('Invalid Scene random state.');
    final value = json['state'];
    if (value == null) return const SceneRandomState.unseeded();
    if (value is! int || value < 0 || value > 4294967295)
      throw const FormatException('Invalid Scene random seed.');
    return SceneRandomState(value);
  }
  final int? state;
  Map<String, dynamic> toJson() => {'state': state};
  ({int value, SceneRandomState next}) draw({
    required String saveId,
    required int minimum,
    required int maximum,
  }) {
    final modulus = BigInt.from(4294967296);
    var seed = state == null ? BigInt.from(2166136261) : BigInt.from(state!);
    if (state == null) {
      for (final code in saveId.codeUnits) {
        seed = ((seed ^ BigInt.from(code)) * BigInt.from(16777619)) % modulus;
      }
    }
    final width = BigInt.from(maximum) - BigInt.from(minimum) + BigInt.one;
    if (width <= BigInt.zero || width > modulus)
      throw ArgumentError('Invalid random range.');
    final ceiling = modulus - modulus % width;
    do {
      seed = (seed * BigInt.from(1664525) + BigInt.from(1013904223)) % modulus;
    } while (seed >= ceiling);
    return (
      value: (BigInt.from(minimum) + seed % width).toInt(),
      next: SceneRandomState(seed.toInt()),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SceneRandomState && other.state == state;
  @override
  int get hashCode => state.hashCode;
}
