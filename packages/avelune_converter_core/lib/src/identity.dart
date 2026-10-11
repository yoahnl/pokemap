part of '../avelune_converter_core.dart';

final class ContractError extends FormatException {
  ContractError(this.code, this.path, String message) : super(message);
  final String code;
  final String path;
  @override
  String toString() => '$code at $path: $message';
}

final class ConverterId {
  ConverterId(this.value) {
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_.:-]{0,191}$').hasMatch(value)) {
      throw ContractError('identity.invalid', r'$', 'Invalid converter ID');
    }
  }
  final String value;
  @override
  bool operator ==(Object other) =>
      other is ConverterId && value == other.value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}

final class Sha256Hash {
  Sha256Hash(this.value) {
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(value)) {
      throw ContractError(
          'hash.invalid', r'$', 'Expected a SHA-256 hex digest');
    }
  }
  final String value;
  @override
  bool operator ==(Object other) => other is Sha256Hash && value == other.value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}

final class ContractLimits {
  const ContractLimits(
      {this.maxDepth = 64,
      this.maxNodes = 1000000,
      this.maxStringCodeUnits = 1048576,
      this.maxTextCodeUnits = 4194304});
  final int maxDepth;
  final int maxNodes;
  final int maxStringCodeUnits;
  final int maxTextCodeUnits;
}
