import 'package:map_authoring/map_authoring.dart';

/// Stable editor-side failure envelope that retains the Authoring domain code.
///
/// The original exception is optional and never serialized into UI state. The
/// code, message, and remediation remain lossless so a panel can offer reload,
/// confirmation, or retry without reverse-engineering exception text.
final class EditorAuthoringMutationFailure implements Exception {
  const EditorAuthoringMutationFailure({
    required this.code,
    required this.message,
    this.remediation = const [],
    this.original,
  });

  factory EditorAuthoringMutationFailure.capture(Object error) {
    if (error is EditorAuthoringMutationFailure) return error;
    String code = 'authoring.unexpected_failure';
    String message = error.toString();
    List<String> remediation = const [];
    // Authoring exceptions deliberately share `code` and `message` semantics
    // without a common base class. Read those public fields dynamically at
    // this one adapter boundary so new domain failures keep their exact code.
    final dynamic domain = error;
    final rawCode = _readDomainField(() => domain.code);
    if (rawCode is String && rawCode.trim().isNotEmpty) code = rawCode;
    final rawMessage = _readDomainField(() => domain.message);
    if (rawMessage is String && rawMessage.trim().isNotEmpty) {
      message = rawMessage;
    }
    final rawRemediation = _readDomainField(() => domain.remediation);
    if (rawRemediation is Iterable) {
      remediation = rawRemediation
          .whereType<String>()
          .where((item) => item.trim().isNotEmpty)
          .toList(growable: false);
    }
    return EditorAuthoringMutationFailure(
      code: code,
      message: message,
      remediation: remediation,
      original: error,
    );
  }

  final String code;
  final String message;
  final List<String> remediation;
  final Object? original;

  @override
  String toString() => 'EditorAuthoringMutationFailure($code): $message';
}

Object? _readDomainField(Object? Function() read) {
  try {
    return read();
  } on Object {
    return null;
  }
}

final class EditorReceiptPresentation {
  const EditorReceiptPresentation({
    required this.code,
    required this.message,
    required this.isSuccess,
    this.isConflict = false,
    this.requiresConfirmation = false,
    this.remediation = const [],
  });

  final String code;
  final String message;
  final bool isSuccess;
  final bool isConflict;
  final bool requiresConfirmation;
  final List<String> remediation;
}

/// Converts protocol-neutral receipts/failures into no-code editor feedback.
final class EditorReceiptPresenter {
  const EditorReceiptPresenter();

  EditorReceiptPresentation receipt(AuthoringReceipt receipt) {
    final affected = receipt.affectedResources.length;
    final verb = switch (receipt.status) {
      AuthoringReceiptStatus.planned => 'préparée',
      AuthoringReceiptStatus.applied => 'appliquée',
      AuthoringReceiptStatus.recovered => 'récupérée',
    };
    return EditorReceiptPresentation(
      code: 'receipt.${receipt.status.wireName}',
      message: 'Modification $verb : $affected ressource(s) concernée(s).',
      isSuccess: true,
    );
  }

  EditorReceiptPresentation failure(EditorAuthoringMutationFailure failure) {
    final code = failure.code;
    final isConflict =
        code.contains('conflict') ||
        code.contains('stale') ||
        code.contains('revision');
    final confirmation = code.startsWith('confirmation.');
    final message = isConflict
        ? 'Le projet a changé en dehors de cet éditeur. Rechargez le projet '
              'avant de réessayer. ${failure.message}'
        : confirmation
        ? 'Cette modification demande une confirmation explicite. '
              '${failure.message}'
        : failure.message;
    return EditorReceiptPresentation(
      code: code,
      message: message,
      isSuccess: false,
      isConflict: isConflict,
      requiresConfirmation: confirmation,
      remediation: failure.remediation,
    );
  }
}
