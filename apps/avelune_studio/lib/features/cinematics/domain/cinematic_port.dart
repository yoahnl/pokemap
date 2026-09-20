import 'package:map_core/map_core_domain.dart';

import '../../resources/domain/resource_port.dart';

abstract interface class CinematicPort {
  Future<CinematicSourceSnapshot> load(String id);

  Future<CinematicPublicationReceipt> publish({
    required String id,
    required CinematicSourceSnapshot? base,
    required CinematicAsset asset,
    String? folderId,
  });

  Future<CinematicPublicationReceipt> delete({
    required CinematicSourceSnapshot base,
  });

  Future<CinematicPublicationReceipt> setArchived({
    required CinematicSourceSnapshot base,
    required bool archived,
  });
}

class CinematicSourceSnapshot {
  const CinematicSourceSnapshot({
    required this.asset,
    required this.revision,
    this.entry,
  });

  final CinematicAsset asset;
  final String revision;
  final CinematicLibraryEntry? entry;
}

class CinematicPublicationReceipt {
  const CinematicPublicationReceipt({
    required this.resources,
    required this.snapshot,
  });

  final ResourceMutationReceipt resources;
  final CinematicSourceSnapshot? snapshot;
}

class CinematicFailure implements Exception {
  const CinematicFailure(this.message, {this.details = const {}});

  final String message;
  final Map<String, Object?> details;

  @override
  String toString() => message;
}
