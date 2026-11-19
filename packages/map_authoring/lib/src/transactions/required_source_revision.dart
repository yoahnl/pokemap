import '../contracts/resource_ref.dart';
import '../ports/transaction_file_gateway.dart';
import 'revision_set.dart';

Map<String, Object?> requiredSourceRevision({
  required String targetRevision,
  required String sourcePath,
  required String sourceRevision,
}) =>
    {
      'requiredSource': {
        'targetRevision': targetRevision,
        'sourcePath': sourcePath,
        'sourceRevision': sourceRevision,
      },
    };

Future<void> requireMatchingSources(
  TransactionFileGateway gateway,
  Iterable<(AuthoringResourceRef, String?)> targets,
) async {
  for (final (resource, target) in targets) {
    final guard = resource.extensions['requiredSource'];
    if (guard == null) continue;
    if (guard
        case {
          'targetRevision': final String targetRevision,
          'sourcePath': final String path,
          'sourceRevision': final String revision,
        }) {
      if (targetRevision != target) continue;
      final current = await gateway.readResourceRevision(path);
      if (current != revision) {
        throw AuthoringRevisionConflict([
          AuthoringRevisionConflictEntry(
            resource: resource,
            expectedKnown: true,
            expectedRevision: revision,
            currentKnown: true,
            currentRevision: current,
          ),
        ]);
      }
    } else {
      throw const FormatException('Invalid required source revision.');
    }
  }
}
