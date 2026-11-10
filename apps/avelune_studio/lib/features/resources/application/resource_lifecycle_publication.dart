import 'package:map_core/map_core_domain.dart';

class ResourceLifecyclePublicationResult {
  const ResourceLifecyclePublicationResult({
    required this.error,
    required this.publicationCommitted,
    this.project,
  });

  final String? error;
  final bool publicationCommitted;
  final ProjectManifest? project;
}
