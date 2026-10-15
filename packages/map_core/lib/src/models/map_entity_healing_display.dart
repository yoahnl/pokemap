import 'package:meta/meta.dart';

@immutable
final class MapEntityHealingDisplayData {
  MapEntityHealingDisplayData({required List<String> variantElementIds})
    : variantElementIds = List<String>.unmodifiable(variantElementIds) {
    if (this.variantElementIds.length != 6 ||
        this.variantElementIds.toSet().length != 6 ||
        this.variantElementIds.any((id) => id.isEmpty || id.trim() != id)) {
      throw const FormatException(
        'A healing display requires six unique native element references.',
      );
    }
  }

  final List<String> variantElementIds;

  String? elementIdForMemberCount(int count) {
    if (count < 0 || count > 6) {
      throw RangeError.range(count, 0, 6, 'count');
    }
    return count == 0 ? null : variantElementIds[count - 1];
  }

  factory MapEntityHealingDisplayData.fromJson(Map<String, dynamic> json) {
    final values = json['variantElementIds'];
    if (json.length != 1 ||
        values is! List ||
        values.any((id) => id is! String)) {
      throw const FormatException('Unsupported healing display contract.');
    }
    return MapEntityHealingDisplayData(
      variantElementIds: values.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {'variantElementIds': variantElementIds};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapEntityHealingDisplayData &&
          variantElementIds.length == other.variantElementIds.length &&
          Iterable<int>.generate(
            variantElementIds.length,
          ).every((i) => variantElementIds[i] == other.variantElementIds[i]);

  @override
  int get hashCode => Object.hashAll(variantElementIds);
}
