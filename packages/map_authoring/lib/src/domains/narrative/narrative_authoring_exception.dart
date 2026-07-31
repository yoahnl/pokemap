import '../../contracts/json_contract_support.dart';

final class NarrativeAuthoringException implements Exception {
  NarrativeAuthoringException(
    this.code,
    this.message, {
    Map<String, Object?> details = const {},
  }) : details = freezeContractJsonObject(details, field: 'details');

  final String code;
  final String message;
  final Map<String, Object?> details;

  @override
  String toString() => 'NarrativeAuthoringException($code): $message';
}
